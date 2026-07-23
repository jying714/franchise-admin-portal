#!/usr/bin/env python3
"""
main.py — Franchise Platform Orchestrator
-----------------------------------------
Always-running process that:
  • Loads the mandatory governance documents
  • Accepts tasks (interactive CLI or file drop)
  • Routes them to the correct specialized agent
  • Calls Ollama and returns a proposal
  • Enforces human-approval gates

Usage inside the container:
  python main.py                  # interactive mode
  python main.py task "..."       # one-shot
  python main.py status           # environment check
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

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

PROJECT_ROOT = Path(os.getenv("PROJECT_ROOT", "/app"))
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://ollama:11434")

# Model overrides (can be set via env)
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


# ---------------------------------------------------------------------------
# Core execution
# ---------------------------------------------------------------------------

async def run_task(
    client: OllamaClient,
    task_text: str,
    preferred_agent: Optional[str] = None,
) -> None:
    """Prepare → call Ollama → pretty-print the proposal."""
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
        f"[bold]Human approval[/bold]: {'YES — ' + result.reason if result.requires_human_approval else 'No (still proposal-only)'}",
        title="Routing Decision",
        border_style="cyan",
    ))

    if result.requires_human_approval:
        console.print(
            "[bold yellow]⚠  This task touches a protected area. "
            "The agent will only produce a proposal. "
            "Do NOT apply anything until you have reviewed it.[/bold yellow]\n"
        )

    console.rule(f"[bold green]Calling {result.model}")
    with console.status(f"[bold]Thinking with {result.model}…"):
        response = await client.generate(
            model=result.model,
            system=result.system_prompt,
            prompt=result.user_prompt,
            temperature=0.15,
        )

    console.print(Panel(Markdown(response), title=f"Proposal from {result.agent}", border_style="green"))
    console.print("\n[dim]Remember: this is a proposal only. Human review is required before any code is changed.[/dim]\n")


# ---------------------------------------------------------------------------
# Interactive loop (shared)
# ---------------------------------------------------------------------------

async def _interactive_loop(preferred_agent: Optional[str] = None):
    console.print(Panel.fit(
        "[bold]Franchise Platform Orchestrator[/bold]\n"
        f"Project root : {PROJECT_ROOT}\n"
        f"Ollama       : {OLLAMA_HOST}\n"
        "Type a task description and press Enter.\n"
        "Commands: /quit  /models  /agent <name>  /help",
        title="Ready",
        border_style="blue",
    ))

    client = OllamaClient(OLLAMA_HOST)
    try:
        models = await client.list_models()
        console.print(f"[green]Ollama reachable — {len(models)} models available[/green]\n")
    except Exception as e:
        console.print(f"[bold red]Cannot reach Ollama at {OLLAMA_HOST}: {e}[/bold red]")
        console.print("Make sure the ollama service is healthy: docker compose ps")
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

        if task.strip() in ("/quit", "/exit", "quit", "exit"):
            break
        if task.strip() == "/models":
            models = await client.list_models()
            console.print("Available models:")
            for m in models:
                console.print(f"  • {m}")
            continue
        if task.strip().startswith("/agent "):
            current_agent = task.strip().split(maxsplit=1)[1]
            console.print(f"Forced agent → {current_agent}")
            continue
        if task.strip() == "/help":
            console.print("Just type a natural-language task. Examples:")
            console.print('  "Summarize current Phase 0 status against the acceptance criteria"')
            console.print('  "Propose a tiny safe cleanup in shared_core that improves a comment"')
            console.print('  "Review the firestore-per-franchise-config.md for any gaps"')
            continue

        await run_task(client, task, preferred_agent=current_agent)

    await client.close()


# ---------------------------------------------------------------------------
# CLI commands
# ---------------------------------------------------------------------------

@app.command()
def interactive(
    agent: Optional[str] = typer.Option(None, help="Force a specific agent"),
):
    """Interactive REPL mode."""
    # Typer may pass OptionInfo when called incorrectly; coerce to None
    preferred = agent if isinstance(agent, str) else None
    asyncio.run(_interactive_loop(preferred))


@app.command()
def task(
    text: str = typer.Argument(..., help="The task description"),
    agent: Optional[str] = typer.Option(None, help="Force a specific agent"),
):
    """One-shot task execution."""
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
    """Print environment & model status."""
    asyncio.run(_status())


async def _status():
    console.print(f"PROJECT_ROOT = {PROJECT_ROOT}")
    console.print(f"OLLAMA_HOST  = {OLLAMA_HOST}")
    console.print("Model mapping:")
    for k, v in MODEL_MAP.items():
        console.print(f"  {k:15} → {v}")

    client = OllamaClient(OLLAMA_HOST)
    try:
        models = await client.list_models()
        console.print(f"\n[green]Ollama OK — models:[/green]")
        for m in models:
            console.print(f"  • {m}")
    except Exception as e:
        console.print(f"[red]Ollama unreachable: {e}[/red]")
    finally:
        await client.close()


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    # No arguments → start interactive mode cleanly
    if len(sys.argv) == 1:
        asyncio.run(_interactive_loop(None))
    else:
        app()
