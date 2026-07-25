#!/usr/bin/env python3
"""
main.py — Franchise Platform Orchestrator
-----------------------------------------
Always-running process that:
  • Loads governance documents (coding_min = STATUS+SCOPE only for xAI source tasks)
  • Accepts tasks (interactive CLI)
  • Routes to specialized agents + backend (ollama | xai)
  • Validates proposals; auto-rejects HARD BAN
  • Saves proposals; applies ONLY after /approve confirm
  • Optional overnight queue

Never auto-pushes. xAI is proposal only.
"""

from __future__ import annotations

import asyncio
import logging
import os
import sys
from pathlib import Path
from typing import Optional, Union

import typer
from rich.console import Console
from rich.markdown import Markdown
from rich.panel import Panel

from agent_router import prepare_task
from feedback import append_feedback
from ollama_client import OllamaClient
from proposal_store import (
    Proposal,
    apply_proposal,
    compute_metrics,
    list_by_status,
    list_recent,
    load_by_id,
    load_last,
    mark_status,
    save_proposal,
)
from proposal_validator import validate_proposal
from xai_client import XaiClient

PROJECT_ROOT = Path(os.getenv("PROJECT_ROOT", "/app"))
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://ollama:11434")

MODEL_MAP = {
    "orchestrator": os.getenv("MODEL_ORCHESTRATOR", "qwen2.5-coder:7b"),
    "backend": os.getenv("MODEL_BACKEND", "qwen2.5-coder:14b"),
    "web_frontend": os.getenv("MODEL_WEB", "qwen2.5-coder:14b"),
    "mobile_shared": os.getenv("MODEL_MOBILE", "qwen2.5-coder:14b"),
    "tester": os.getenv("MODEL_TESTER", "qwen2.5-coder:7b"),
    "reviewer": os.getenv("MODEL_REVIEWER", "qwen2.5-coder:7b"),
}

console = Console()
app = typer.Typer(add_completion=False, help="Franchise Platform Multi-Agent Orchestrator")
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(name)s] %(message)s")
logger = logging.getLogger("orchestrator")


def _edits_summary(prop: Proposal) -> str:
    edits = prop.file_edits() if hasattr(prop, "file_edits") else []
    if len(edits) > 1:
        paths = ", ".join(e.file_path for e in edits)
        return f"{len(edits)} files: {paths}"
    if prop.file_path:
        return prop.file_path
    return "unknown"


async def run_task(
    client: Union[OllamaClient, XaiClient, None],
    task_text: str,
    preferred_agent: Optional[str] = None,
    *,
    return_proposal: bool = False,
    ollama: Optional[OllamaClient] = None,
    xai: Optional[XaiClient] = None,
) -> Optional[Proposal]:
    console.rule("[bold blue]Preparing task")

    result = prepare_task(
        project_root=PROJECT_ROOT,
        task_text=task_text,
        preferred_agent=preferred_agent,
        model_map=MODEL_MAP,
    )

    ollama_client = ollama or (client if isinstance(client, OllamaClient) else None)
    xai_client = xai if xai is not None else None

    console.print(Panel.fit(
        f"[bold]Agent[/bold]: {result.agent}\n"
        f"[bold]Backend[/bold]: {result.backend}\n"
        f"[bold]Context[/bold]: {getattr(result, 'context_mode', 'n/a')}\n"
        f"[bold]Model[/bold]: {result.model}\n"
        f"[bold]num_ctx[/bold]: {result.num_ctx if result.backend == 'ollama' else 'n/a (xAI)'}\n"
        f"[bold]temperature[/bold]: {result.temperature}\n"
        f"[bold]Human approval[/bold]: {'YES — ' + result.reason if result.requires_human_approval else 'No (still proposal-only)'}",
        title="Routing Decision",
        border_style="cyan",
    ))

    if result.requires_human_approval:
        console.print(
            "[bold yellow]⚠  Protected area — proposal only until you review.[/bold yellow]\n"
        )

    console.rule(f"[bold green]Calling {result.backend}:{result.model}")

    if result.backend == "xai":
        if xai_client is None:
            xai_client = XaiClient()
        if not xai_client.configured:
            console.print(
                "[bold red]XAI_API_KEY is not set. Cannot run backend: xai.\n"
                "Export XAI_API_KEY on the host/container, then retry.[/bold red]"
            )
            return None
        # Stable conv id per agent → prompt-cache affinity for shared SCOPE prefix
        conv_id = f"franchise-orch-{result.agent}-xai"
        with console.status(f"[bold]Thinking with xAI {result.model}…"):
            response = await xai_client.generate(
                system=result.system_prompt,
                prompt=result.user_prompt,
                model=result.model,
                temperature=result.temperature,
                conv_id=conv_id,
            )
    else:
        if ollama_client is None:
            console.print("[bold red]Ollama client not available.[/bold red]")
            return None
        with console.status(f"[bold]Thinking with {result.model}…"):
            response = await ollama_client.generate(
                model=result.model,
                system=result.system_prompt,
                prompt=result.user_prompt,
                temperature=result.temperature,
                num_ctx=result.num_ctx or 8192,
            )

    validation = validate_proposal(task_text, response, project_root=PROJECT_ROOT)

    if validation.has_warnings:
        for w in validation.warnings:
            style = "bold red" if w.startswith("HARD BAN:") else "bold yellow"
            console.print(f"[{style}]⚠ VALIDATION: {w}[/{style}]")

    auto_rejected = not validation.ok
    if auto_rejected:
        console.print(
            "[bold red]AUTO-REJECTED — HARD BAN / path allowlist / BEFORE-on-disk. "
            "Proposal saved as rejected; /approve confirm will refuse.[/bold red]\n"
        )
    elif validation.has_warnings:
        console.print(
            "[yellow]Soft warnings only — proposal shown below for human review.[/yellow]\n"
        )

    console.print(Panel(
        Markdown(response),
        title=f"Proposal from {result.agent} ({result.backend})",
        border_style="red" if auto_rejected else "green",
    ))

    prop = save_proposal(
        PROJECT_ROOT,
        task=task_text,
        agent=result.agent,
        model=f"{result.backend}:{result.model}",
        response=response,
        validation_warnings=validation.warnings,
    )

    if auto_rejected:
        mark_status(PROJECT_ROOT, prop, "rejected")
        prop.status = "rejected"
        try:
            append_feedback(
                PROJECT_ROOT,
                kind="auto_reject",
                proposal_id=prop.id,
                reason="; ".join(validation.warnings)[:500] or "validator.ok=False",
                extra={
                    "file_path": prop.file_path or "",
                    "agent": prop.agent,
                    "backend": result.backend,
                    "hard_bans": [w for w in validation.warnings if w.startswith("HARD BAN:")],
                },
            )
        except Exception as e:
            logger.warning("auto_reject feedback log failed: %s", e)
        console.print(
            f"[dim]Saved proposal [bold]{prop.id}[/bold] "
            f"(file={_edits_summary(prop)}, status=[bold red]rejected[/bold red]).\n"
            f"Not eligible for /approve confirm. Use /proposals to inspect.[/dim]\n"
        )
    elif prop.status == "no_change":
        console.print(
            f"[bold green]✓ No change needed[/bold green] — escape hatch used correctly.\n"
            f"[dim]Saved proposal [bold]{prop.id}[/bold] (status=no_change). "
            f"This is a success outcome, not pending work.\n"
            f"View: /proposals no_change[/dim]\n"
        )
        try:
            append_feedback(
                PROJECT_ROOT,
                kind="no_change",
                proposal_id=prop.id,
                reason="No change needed",
                extra={
                    "file_path": prop.file_path or "",
                    "agent": prop.agent,
                    "backend": result.backend,
                },
            )
        except Exception as e:
            logger.warning("no_change feedback log failed: %s", e)
    else:
        console.print(
            f"[dim]Saved proposal [bold]{prop.id}[/bold] "
            f"(targets={_edits_summary(prop)}, status={prop.status}, backend={result.backend}).\n"
            f"Review: /approve {prop.id}\n"
            f"Apply locally: /approve confirm {prop.id}\n"
            f"(never auto-pushes; multi-file applies all parsed FILE pairs)[/dim]\n"
        )

    if return_proposal:
        return prop
    return None


def _resolve_proposal(proposal_id: Optional[str] = None):
    if proposal_id:
        prop = load_by_id(PROJECT_ROOT, proposal_id)
        if not prop:
            console.print(f"[red]No proposal with id: {proposal_id}[/red]")
            console.print("[dim]Use /proposals to list ids.[/dim]")
            return None
        return prop
    prop = load_last(PROJECT_ROOT)
    if not prop:
        console.print("[yellow]No saved proposal.[/yellow]")
        return None
    return prop


def _show_proposal(prop, *, full: bool = False) -> None:
    status_style = {
        "no_change": "bold green",
        "applied": "green",
        "rejected": "red",
        "pending": "yellow",
    }.get(prop.status, "cyan")

    edits = prop.file_edits() if hasattr(prop, "file_edits") else []
    edits_line = f"[bold]edits[/bold]: {len(edits)} file(s)" if edits else (
        f"[bold]file[/bold]: {prop.file_path or '(not detected)'}"
    )

    console.print(Panel.fit(
        f"[bold]id[/bold]: {prop.id}\n"
        f"[bold]status[/bold]: [{status_style}]{prop.status}[/{status_style}]\n"
        f"[bold]created[/bold]: {prop.created_at}\n"
        f"[bold]agent[/bold]: {prop.agent} / {prop.model}\n"
        f"{edits_line}\n"
        f"[bold]warnings[/bold]: {len(prop.validation_warnings)}\n"
        f"[bold]before parsed[/bold]: {'yes' if prop.before else 'no'}\n"
        f"[bold]after parsed[/bold]: {'yes' if prop.after else 'no'}",
        title="Proposal",
        border_style="cyan",
    ))
    if prop.validation_warnings:
        for w in prop.validation_warnings:
            console.print(f"  [yellow]• {w}[/yellow]")

    if full:
        console.print("\n[bold]FULL TASK[/bold]")
        console.print(Panel(prop.task, border_style="blue"))
        console.print("[bold]FULL RESPONSE[/bold]")
        console.print(Panel(Markdown(prop.response), border_style="green"))
        if edits:
            for i, e in enumerate(edits, 1):
                console.print(f"[bold]FILE {i}/{len(edits)}[/bold] {e.file_path}")
                console.print("[bold]BEFORE (parsed)[/bold]")
                console.print(Panel(e.before, border_style="red"))
                console.print("[bold]AFTER (parsed)[/bold]")
                console.print(Panel(e.after, border_style="green"))
        elif prop.before and prop.after:
            console.print("[bold]BEFORE (parsed)[/bold]")
            console.print(Panel(prop.before, border_style="red"))
            console.print("[bold]AFTER (parsed)[/bold]")
            console.print(Panel(prop.after, border_style="green"))
        return

    console.print(f"[bold]task[/bold]: {prop.task[:120]}{'…' if len(prop.task) > 120 else ''}")
    if prop.status == "no_change":
        console.print("[bold green]No change needed — escape hatch used.[/bold green]")
        return
    if edits:
        for i, e in enumerate(edits, 1):
            console.print(f"\n[bold]FILE {i}/{len(edits)}[/bold] {e.file_path}")
            console.print("[bold]BEFORE (parsed)[/bold]")
            console.print(Panel(e.before, border_style="red"))
            console.print("[bold]AFTER (parsed)[/bold]")
            console.print(Panel(e.after, border_style="green"))
    elif prop.before and prop.after:
        console.print("\n[bold]BEFORE (parsed)[/bold]")
        console.print(Panel(prop.before, border_style="red"))
        console.print("[bold]AFTER (parsed)[/bold]")
        console.print(Panel(prop.after, border_style="green"))
    else:
        console.print(
            "\n[dim]Could not parse before/after blocks — full response below.[/dim]"
        )
        console.print(Panel(Markdown(prop.response), border_style="dim"))


def _cmd_approve(confirm: bool = False, proposal_id: Optional[str] = None) -> None:
    prop = _resolve_proposal(proposal_id)
    if not prop:
        return

    _show_proposal(prop)

    if not confirm:
        if prop.status == "no_change":
            console.print(
                "\n[dim]This is a No change needed success. Nothing to apply.[/dim]\n"
            )
            return
        console.print(
            f"\nTo apply [underline]locally only[/underline] (no git push):\n"
            f"  [green]/approve confirm {prop.id}[/green]\n"
            f"To discard:\n"
            f"  [red]/reject {prop.id} reason=...[/red]\n"
        )
        return

    if prop.status == "rejected":
        console.print("[red]Proposal was rejected (manual or auto) — not applying.[/red]")
        return
    if prop.status == "applied":
        console.print("[yellow]Proposal already applied.[/yellow]")
        return
    if prop.status == "no_change":
        console.print("[yellow]No change needed — nothing to apply.[/yellow]")
        return

    ok, msg = apply_proposal(PROJECT_ROOT, prop)
    if ok:
        console.print(f"[green]{msg}[/green]")
        console.print("[dim]Commit and push remain your responsibility.[/dim]")
        try:
            append_feedback(
                PROJECT_ROOT,
                kind="apply",
                proposal_id=prop.id,
                reason="applied",
                extra={
                    "file_path": prop.file_path or "",
                    "agent": prop.agent,
                    "edits": _edits_summary(prop),
                },
            )
        except Exception as e:
            logger.warning("feedback log failed: %s", e)
    else:
        console.print(f"[red]Apply failed: {msg}[/red]")


def _cmd_reject(proposal_id: Optional[str] = None, reason: str = "") -> None:
    prop = _resolve_proposal(proposal_id)
    if not prop:
        return
    mark_status(PROJECT_ROOT, prop, "rejected")
    try:
        append_feedback(
            PROJECT_ROOT,
            kind="reject",
            proposal_id=prop.id,
            reason=reason or "(no reason given)",
            extra={
                "file_path": prop.file_path or "",
                "agent": prop.agent,
                "task_preview": prop.task[:200],
            },
        )
    except Exception as e:
        logger.warning("feedback log failed: %s", e)
    console.print(f"[red]Proposal {prop.id} marked rejected.[/red]")
    if reason:
        console.print(f"[dim]reason: {reason}[/dim]")


def _cmd_proposals(status_filter: Optional[str] = None, full: bool = False) -> None:
    if full:
        items = list_by_status(PROJECT_ROOT, "pending", limit=100)
        if not items:
            console.print("[dim]No pending (un-accepted) proposals.[/dim]")
            return
        console.print(
            f"[bold green]Pending proposals — full dump ({len(items)})[/bold green]\n"
            "[dim]These have not been accepted or rejected yet.[/dim]\n"
        )
        for i, p in enumerate(items, 1):
            console.rule(f"[bold]{i}/{len(items)}  {p.id}")
            _show_proposal(p, full=True)
            console.print()
        return

    if status_filter:
        items = list_by_status(PROJECT_ROOT, status_filter, limit=50)
        label = status_filter
    else:
        items = list_recent(PROJECT_ROOT, limit=20)
        label = "recent (all statuses)"

    if not items:
        console.print(f"[dim]No {label} proposals.[/dim]")
        return

    console.print(
        f"[bold]Proposals — {label}[/bold]  "
        f"(use /approve <id> | /approve confirm <id> | /proposals full | /metrics)"
    )
    for p in items:
        warn = f" warnings={len(p.validation_warnings)}" if p.validation_warnings else ""
        status_col = {
            "no_change": "green",
            "applied": "green",
            "rejected": "red",
            "pending": "yellow",
        }.get(p.status, "white")
        edits = p.file_edits() if hasattr(p, "file_edits") else []
        target = (
            f"{len(edits)} files"
            if len(edits) > 1
            else (p.file_path or "-")
        )
        console.print(
            f"  [cyan]{p.id}[/cyan]  [{status_col}]{p.status}[/{status_col}]  "
            f"{p.agent}  {target}{warn}"
        )


def _cmd_metrics(limit: int = 50) -> None:
    m = compute_metrics(PROJECT_ROOT, limit=limit)
    if m.get("total", 0) == 0:
        console.print("[dim]No proposals found for metrics.[/dim]")
        return

    console.print(Panel.fit(
        f"[bold]Training metrics[/bold] (last {m['total']} proposals)\n\n"
        f"[green]No change needed[/green]     {m['no_change']:3}  ({m['no_change_pct']}%)\n"
        f"Real differing BEFORE/AFTER {m['real_diff']:3}  ({m['real_diff_pct']}%)\n"
        f"Quote-first signal          {m['quote_signal']:3}  ({m['quote_signal_pct']}%)\n"
        f"[red]HARD BAN hits[/red]            {m['hard_ban']:3}  ({m['hard_ban_pct']}%)\n"
        f"Applied                     {m['applied']:3}  ({m['applied_pct']}%)\n"
        f"Rejected                    {m['rejected']:3}  ({m['rejected_pct']}%)\n"
        f"Still pending               {m['pending']:3}  ({m['pending_pct']}%)",
        title="/metrics",
        border_style="cyan",
    ))


def _parse_approve_cmd(cmd: str) -> tuple[bool, Optional[str]]:
    parts = cmd.split()
    if len(parts) == 1:
        return False, None
    if parts[1] == "confirm":
        pid = parts[2] if len(parts) >= 3 else None
        return True, pid
    return False, parts[1]


def _parse_reject_cmd(cmd: str) -> tuple[Optional[str], str]:
    parts = cmd.split(maxsplit=2)
    if len(parts) == 1:
        return None, ""
    if parts[1].startswith("reason="):
        return None, parts[1][len("reason="):] + ((" " + parts[2]) if len(parts) > 2 else "")
    pid = parts[1]
    reason = ""
    if len(parts) >= 3:
        rest = parts[2]
        if rest.startswith("reason="):
            reason = rest[len("reason="):]
        else:
            reason = rest
    return pid, reason


async def _interactive_loop(preferred_agent: Optional[str] = None):
    xai_set = bool(os.getenv("XAI_API_KEY", "").strip())
    console.print(Panel.fit(
        "[bold]Franchise Platform Orchestrator[/bold]\n"
        f"Project root : {PROJECT_ROOT}\n"
        f"Ollama       : {OLLAMA_HOST}\n"
        f"xAI API key  : {'set' if xai_set else 'NOT SET (backend: xai will fail)'}\n"
        "Paste multi-line task, then END.\n"
        "backend: xai | # context: coding_min (default for xAI+source)\n"
        "Commands: /quit /models /agent /help /proposals /metrics\n"
        "          /approve [id]   /approve confirm [id]\n"
        "          /reject [id] reason=...\n"
        "          /queue status | /queue run | /queue run --once",
        title="Ready",
        border_style="blue",
    ))

    ollama = OllamaClient(OLLAMA_HOST)
    xai = XaiClient()
    try:
        models = await ollama.list_models()
        console.print(f"[green]Ollama reachable — {len(models)} models available[/green]")
    except Exception as e:
        console.print(f"[yellow]Ollama not reachable at {OLLAMA_HOST}: {e}[/yellow]")

    if xai.configured:
        console.print("[green]xAI API key present — backend: xai enabled[/green]\n")
    else:
        console.print("[dim]xAI: set XAI_API_KEY to enable backend: xai[/dim]\n")

    current_agent: Optional[str] = preferred_agent

    while True:
        try:
            console.print("\n[bold cyan]Task[/bold cyan] (paste multi-line, then type END on its own line):")
            lines = []
            while True:
                try:
                    line = console.input("[dim]…[/dim] ")
                except (EOFError, KeyboardInterrupt):
                    if not lines:
                        raise
                    break
                if line.strip().upper() == "END":
                    break
                lines.append(line)
            task = "\n".join(lines).strip()
        except (KeyboardInterrupt, EOFError):
            console.print("\nBye.")
            break

        if not task:
            continue

        cmd = task.strip()
        if cmd in ("/quit", "/exit", "quit", "exit"):
            break
        if cmd == "/models":
            try:
                models = await ollama.list_models()
                for m in models:
                    console.print(f"  • ollama:{m}")
            except Exception as e:
                console.print(f"[red]Ollama list failed: {e}[/red]")
            console.print(f"  • xai:{os.getenv('XAI_MODEL', 'grok-4.5')} (if key set)")
            continue
        if cmd.startswith("/agent "):
            current_agent = cmd.split(maxsplit=1)[1]
            console.print(f"Forced agent → {current_agent}")
            continue
        if cmd == "/help":
            console.print("backend: xai | ollama")
            console.print("# context: coding_min | coding_std | full | source_only")
            console.print("Default: coding_min for backend:xai + source files (STATUS+SCOPE only).")
            console.print("/proposals [pending|no_change|rejected|applied|full]")
            console.print("/metrics | /approve confirm [id] | /reject [id] reason=...")
            console.print("/queue status | run | run --once")
            continue
        if cmd == "/metrics" or cmd.startswith("/metrics "):
            _cmd_metrics()
            continue
        if cmd == "/proposals" or cmd.startswith("/proposals "):
            parts = cmd.split()
            status_filter = None
            full = False
            if len(parts) >= 2:
                arg = parts[1].lower()
                if arg == "full":
                    full = True
                elif arg in ("pending", "rejected", "applied", "approved", "no_change"):
                    status_filter = arg
                else:
                    console.print("[yellow]Usage: /proposals [pending|no_change|rejected|applied|full][/yellow]")
                    continue
            _cmd_proposals(status_filter=status_filter, full=full)
            continue
        if cmd == "/approve" or cmd.startswith("/approve "):
            confirm, pid = _parse_approve_cmd(cmd)
            _cmd_approve(confirm=confirm, proposal_id=pid)
            continue
        if cmd == "/reject" or cmd.startswith("/reject "):
            pid, reason = _parse_reject_cmd(cmd)
            _cmd_reject(pid, reason=reason)
            continue
        if cmd == "/queue" or cmd.startswith("/queue "):
            rest = cmd[len("/queue"):].strip()
            try:
                if not rest or rest == "status":
                    from queue_runner import status as queue_status
                    queue_status()
                elif rest.startswith("run"):
                    once = "--once" in rest or rest.endswith(" once")
                    from queue_runner import drain
                    await drain(once=once, ollama=ollama, xai=xai)
                else:
                    console.print("[yellow]Usage: /queue status | /queue run | /queue run --once[/yellow]")
            except Exception as e:
                console.print(f"[red]Queue error: {e}[/red]")
            continue

        await run_task(
            ollama,
            task,
            preferred_agent=current_agent,
            ollama=ollama,
            xai=xai,
        )

    await ollama.close()
    await xai.close()


@app.command()
def interactive(
    agent: Optional[str] = typer.Option(None, help="Force a specific agent"),
):
    preferred = agent if isinstance(agent, str) else None
    asyncio.run(_interactive_loop(preferred))


@app.command()
def task(
    text: str = typer.Argument(..., help="The task description"),
    agent: Optional[str] = typer.Option(None, help="Force a specific agent"),
):
    preferred = agent if isinstance(agent, str) else None
    asyncio.run(_one_shot(text, preferred))


async def _one_shot(text: str, agent: Optional[str]):
    ollama = OllamaClient(OLLAMA_HOST)
    xai = XaiClient()
    try:
        await run_task(ollama, text, preferred_agent=agent, ollama=ollama, xai=xai)
    finally:
        await ollama.close()
        await xai.close()


@app.command()
def status():
    asyncio.run(_status())


async def _status():
    console.print(f"PROJECT_ROOT = {PROJECT_ROOT}")
    console.print(f"OLLAMA_HOST  = {OLLAMA_HOST}")
    console.print(f"XAI_API_KEY  = {'set' if os.getenv('XAI_API_KEY') else 'NOT SET'}")
    console.print(f"XAI_MODEL    = {os.getenv('XAI_MODEL', 'grok-4.5')}")
    for k, v in MODEL_MAP.items():
        console.print(f"  ollama {k:15} → {v}")
    ollama = OllamaClient(OLLAMA_HOST)
    try:
        models = await ollama.list_models()
        console.print("[green]Ollama OK[/green]")
        for m in models:
            console.print(f"  • {m}")
    except Exception as e:
        console.print(f"[red]Ollama unreachable: {e}[/red]")
    finally:
        await ollama.close()


if __name__ == "__main__":
    if len(sys.argv) == 1:
        asyncio.run(_interactive_loop(None))
    else:
        app()
