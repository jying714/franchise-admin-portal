#!/usr/bin/env python3
"""
main.py — Franchise Platform Orchestrator
-----------------------------------------
Always-running process that:
  • Loads the mandatory governance documents
  • Accepts tasks (interactive CLI)
  • Routes them to specialized agents
  • Calls Ollama and returns a proposal
  • Validates proposals for scope drift (A3)
  • Saves proposals; applies ONLY after explicit /approve confirm

Commands:
  /approve          show last proposal + require /approve confirm to apply
  /approve confirm  apply last proposal locally (no git push)
  /reject           mark last proposal rejected
  /proposals        list recent proposals
  /quit /models /agent /help
"""

from __future__ import annotations

import asyncio
import logging
import os
import sys
from pathlib import Path
from typing import Optional

import typer
from rich.console import Console
from rich.markdown import Markdown
from rich.panel import Panel
from rich.prompt import Prompt

from agent_router import prepare_task
from ollama_client import OllamaClient
from proposal_store import apply_proposal, list_recent, load_last, mark_status, save_proposal
from proposal_validator import validate_proposal

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


async def run_task(
    client: OllamaClient,
    task_text: str,
    preferred_agent: Optional[str] = None,
) -> None:
    console.rule("[bold blue]Preparing task")

    result = prepare_task(
        project_root=PROJECT_ROOT,
        task_text=task_text,
        preferred_agent=preferred_agent,
        model_map=MODEL_MAP,
    )

    console.print(Panel.fit(
        f"[bold]Agent[/bold]: {result.agent}\n"
        f"[bold]Model[/bold]: {result.model}\n"
        f"[bold]num_ctx[/bold]: {result.num_ctx}\n"
        f"[bold]temperature[/bold]: {result.temperature}\n"
        f"[bold]Human approval[/bold]: {'YES — ' + result.reason if result.requires_human_approval else 'No (still proposal-only)'}",
        title="Routing Decision",
        border_style="cyan",
    ))

    if result.requires_human_approval:
        console.print(
            "[bold yellow]⚠  Protected area — proposal only until you review.[/bold yellow]\n"
        )

    console.rule(f"[bold green]Calling {result.model}")
    with console.status(f"[bold]Thinking with {result.model}…"):
        response = await client.generate(
            model=result.model,
            system=result.system_prompt,
            prompt=result.user_prompt,
            temperature=result.temperature,
            num_ctx=result.num_ctx,
        )

    # A3 — scope drift check
    validation = validate_proposal(task_text, response)
    if validation.has_warnings:
        for w in validation.warnings:
            console.print(f"[bold yellow]⚠ VALIDATION: {w}[/bold yellow]")
        console.print(
            "[yellow]Proposal shown below — review carefully before /approve.[/yellow]\n"
        )

    console.print(Panel(Markdown(response), title=f"Proposal from {result.agent}", border_style="green"))

    prop = save_proposal(
        PROJECT_ROOT,
        task=task_text,
        agent=result.agent,
        model=result.model,
        response=response,
        validation_warnings=validation.warnings,
    )
    console.print(
        f"[dim]Saved proposal {prop.id} "
        f"(file={prop.file_path or 'unknown'}, status={prop.status}). "
        f"Review, then /approve confirm to apply locally — never auto-pushes.[/dim]\n"
    )


def _cmd_approve(confirm: bool = False) -> None:
    prop = load_last(PROJECT_ROOT)
    if not prop:
        console.print("[yellow]No saved proposal.[/yellow]")
        return

    console.print(Panel.fit(
        f"[bold]id[/bold]: {prop.id}\n"
        f"[bold]status[/bold]: {prop.status}\n"
        f"[bold]agent[/bold]: {prop.agent} / {prop.model}\n"
        f"[bold]file[/bold]: {prop.file_path or '(not detected)'}\n"
        f"[bold]warnings[/bold]: {len(prop.validation_warnings)}\n"
        f"[bold]before parsed[/bold]: {'yes' if prop.before else 'no'}\n"
        f"[bold]after parsed[/bold]: {'yes' if prop.after else 'no'}",
        title="Last proposal",
        border_style="cyan",
    ))
    if prop.validation_warnings:
        for w in prop.validation_warnings:
            console.print(f"  [yellow]• {w}[/yellow]")

    if not confirm:
        console.print(
            "\n[bold]Review the proposal above in history.[/bold]\n"
            "To apply [underline]locally only[/underline] (no git push): type [green]/approve confirm[/green]\n"
            "To discard: [red]/reject[/red]\n"
        )
        return

    if prop.status == "rejected":
        console.print("[red]Proposal was rejected — not applying.[/red]")
        return

    ok, msg = apply_proposal(PROJECT_ROOT, prop)
    if ok:
        console.print(f"[green]{msg}[/green]")
        console.print("[dim]Commit and push remain your responsibility (or a future second gate).[/dim]")
    else:
        console.print(f"[red]Apply failed: {msg}[/red]")


def _cmd_reject() -> None:
    prop = load_last(PROJECT_ROOT)
    if not prop:
        console.print("[yellow]No saved proposal.[/yellow]")
        return
    mark_status(PROJECT_ROOT, prop, "rejected")
    console.print(f"[red]Proposal {prop.id} marked rejected.[/red]")


def _cmd_proposals() -> None:
    items = list_recent(PROJECT_ROOT, limit=10)
    if not items:
        console.print("[dim]No proposals yet.[/dim]")
        return
    for p in items:
        warn = f" warnings={len(p.validation_warnings)}" if p.validation_warnings else ""
        console.print(
            f"  {p.id}  [{p.status}]  {p.agent}  {p.file_path or '-'}{warn}"
        )


async def _interactive_loop(preferred_agent: Optional[str] = None):
    console.print(Panel.fit(
        "[bold]Franchise Platform Orchestrator[/bold]\n"
        f"Project root : {PROJECT_ROOT}\n"
        f"Ollama       : {OLLAMA_HOST}\n"
        "Type a task and press Enter.\n"
        "Commands: /quit /models /agent /help\n"
        "          /approve  /approve confirm  /reject  /proposals",
        title="Ready",
        border_style="blue",
    ))

    client = OllamaClient(OLLAMA_HOST)
    try:
        models = await client.list_models()
        console.print(f"[green]Ollama reachable — {len(models)} models available[/green]\n")
    except Exception as e:
        console.print(f"[bold red]Cannot reach Ollama at {OLLAMA_HOST}: {e}[/bold red]")
        return

    current_agent: Optional[str] = preferred_agent

    while True:
        try:
            task = Prompt.ask("\n[bold cyan]Task[/bold cyan]")
        except (KeyboardInterrupt, EOFError):
            console.print("\nBye.")
            break

        if not task.strip():
            continue

        cmd = task.strip()
        if cmd in ("/quit", "/exit", "quit", "exit"):
            break
        if cmd == "/models":
            models = await client.list_models()
            for m in models:
                console.print(f"  • {m}")
            continue
        if cmd.startswith("/agent "):
            current_agent = cmd.split(maxsplit=1)[1]
            console.print(f"Forced agent → {current_agent}")
            continue
        if cmd == "/help":
            console.print("Tasks: natural language with file paths when editing code.")
            console.print("/approve          — show last proposal")
            console.print("/approve confirm — apply last proposal locally (no push)")
            console.print("/reject            — discard last proposal")
            console.print("/proposals         — list recent")
            continue
        if cmd == "/approve":
            _cmd_approve(confirm=False)
            continue
        if cmd == "/approve confirm":
            _cmd_approve(confirm=True)
            continue
        if cmd == "/reject":
            _cmd_reject()
            continue
        if cmd == "/proposals":
            _cmd_proposals()
            continue

        await run_task(client, task, preferred_agent=current_agent)

    await client.close()


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
    client = OllamaClient(OLLAMA_HOST)
    try:
        await run_task(client, text, preferred_agent=agent)
    finally:
        await client.close()


@app.command()
def status():
    asyncio.run(_status())


async def _status():
    console.print(f"PROJECT_ROOT = {PROJECT_ROOT}")
    console.print(f"OLLAMA_HOST  = {OLLAMA_HOST}")
    for k, v in MODEL_MAP.items():
        console.print(f"  {k:15} → {v}")
    client = OllamaClient(OLLAMA_HOST)
    try:
        models = await client.list_models()
        console.print("[green]Ollama OK[/green]")
        for m in models:
            console.print(f"  • {m}")
    except Exception as e:
        console.print(f"[red]Ollama unreachable: {e}[/red]")
    finally:
        await client.close()


if __name__ == "__main__":
    if len(sys.argv) == 1:
        asyncio.run(_interactive_loop(None))
    else:
        app()
