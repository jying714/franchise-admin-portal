#!/usr/bin/env python3
"""
queue_runner.py
---------------
Drain orchestrator/queue/inbox sequentially (overnight-safe).

Behavior:
  - Pick oldest *.task.txt only (skip README.md and other non-task files)
  - Parse optional headers: # id: # agent: # priority: # backend:
  - Call the same run_task path as interactive CLI (ollama or xai)
  - Move file to done/ with a .meta.json sidecar
  - NEVER apply, NEVER git push, NEVER Firestore
"""

from __future__ import annotations

import argparse
import asyncio
import json
import logging
import os
import re
import shutil
import sys
import traceback
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional, Tuple

from rich.console import Console

_HERE = Path(__file__).resolve().parent
if str(_HERE) not in sys.path:
    sys.path.insert(0, str(_HERE))

from ollama_client import OllamaClient  # noqa: E402
from xai_client import XaiClient  # noqa: E402
from main import PROJECT_ROOT, run_task  # noqa: E402

console = Console()
logger = logging.getLogger("orchestrator.queue")
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(name)s] %(message)s")

QUEUE_ROOT = PROJECT_ROOT / "orchestrator" / "queue"
INBOX = QUEUE_ROOT / "inbox"
RUNNING = QUEUE_ROOT / "running"
DONE = QUEUE_ROOT / "done"
RUN_LOG = QUEUE_ROOT / "run_log.md"

DEFAULT_SLEEP_SEC = 15


def _ensure_dirs() -> None:
    for d in (INBOX, RUNNING, DONE):
        d.mkdir(parents=True, exist_ok=True)


def _list_inbox() -> list[Path]:
    """Oldest first. Only *.task.txt — never README or random md."""
    files = [
        p
        for p in INBOX.iterdir()
        if p.is_file()
        and not p.name.startswith(".")
        and p.name != ".gitkeep"
        and p.name.endswith(".task.txt")
    ]
    return sorted(files, key=lambda p: p.stat().st_mtime)


def parse_task_file(path: Path) -> Tuple[str, Optional[str], int, str]:
    """
    Returns (task_body, preferred_agent, priority, task_id_slug).
    Headers (optional):
      # id: my-slug
      # agent: backend
      # priority: 10
      # backend: xai
    Body may also contain `backend: xai` for agent_router.
    """
    text = path.read_text(encoding="utf-8")
    agent: Optional[str] = None
    priority = 100
    slug = path.stem
    backend_header: Optional[str] = None
    body_lines: list[str] = []
    header_mode = True

    for line in text.splitlines():
        if header_mode:
            m = re.match(r"^#\s*(\w+)\s*:\s*(.+?)\s*$", line)
            if m:
                key, val = m.group(1).lower(), m.group(2).strip()
                if key == "agent":
                    agent = val
                elif key == "priority":
                    try:
                        priority = int(val)
                    except ValueError:
                        pass
                elif key == "id":
                    slug = val
                elif key == "backend":
                    backend_header = val.lower()
                continue
            if line.strip() == "" or line.startswith("#"):
                continue
            header_mode = False
            body_lines.append(line)
        else:
            body_lines.append(line)

    body = "\n".join(body_lines).strip()
    if not body:
        body = text.strip()
    # Inject backend into body if only in # header and not already in body
    if backend_header and not re.search(r"(?i)\bbackend\s*:\s*(xai|ollama)\b", body):
        body = f"backend: {backend_header}\n\n{body}"
    return body, agent, priority, slug


def _append_run_log(
    task_file: str,
    proposal_id: str,
    ok: bool,
    detail: str = "",
) -> None:
    QUEUE_ROOT.mkdir(parents=True, exist_ok=True)
    if not RUN_LOG.exists():
        RUN_LOG.write_text(
            "# Queue run log\n\n| timestamp (UTC) | task_file | proposal_id | result | detail |\n|---|---|---|---|---|\n",
            encoding="utf-8",
        )
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    result = "ok" if ok else "fail"
    detail_safe = detail.replace("|", "/").replace("\n", " ")[:120]
    with RUN_LOG.open("a", encoding="utf-8") as f:
        f.write(f"| {ts} | `{task_file}` | `{proposal_id}` | {result} | {detail_safe} |\n")


def _write_meta(done_path: Path, meta: dict) -> None:
    meta_path = done_path.with_suffix(done_path.suffix + ".meta.json")
    meta_path.write_text(json.dumps(meta, indent=2), encoding="utf-8")


async def _run_one(
    path: Path,
    *,
    ollama: OllamaClient,
    xai: XaiClient,
) -> bool:
    body, agent, priority, slug = parse_task_file(path)
    console.rule(f"[bold]Queue task: {path.name}")
    console.print(f"[dim]slug={slug} agent={agent or '(auto)'} priority={priority}[/dim]")

    running_path = RUNNING / path.name
    try:
        shutil.move(str(path), str(running_path))
    except Exception as e:
        console.print(f"[red]Could not move to running/: {e}[/red]")
        return False

    proposal_id = ""
    ok = False
    detail = ""
    try:
        prop = await run_task(
            ollama,
            body,
            preferred_agent=agent,
            return_proposal=True,
            ollama=ollama,
            xai=xai,
        )
        if prop is not None:
            proposal_id = prop.id
            ok = True
            detail = f"status={prop.status}"
        else:
            detail = "run_task returned no proposal"
    except Exception as e:
        detail = f"{type(e).__name__}: {e}"
        console.print(f"[red]Task failed: {detail}[/red]")
        logger.error(traceback.format_exc())
        ok = False

    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    dest_name = f"{stamp}_{path.name}"
    done_path = DONE / dest_name
    try:
        shutil.move(str(running_path), str(done_path))
    except Exception:
        done_path = running_path

    _write_meta(
        done_path,
        {
            "task_file": path.name,
            "slug": slug,
            "proposal_id": proposal_id,
            "ok": ok,
            "detail": detail,
            "finished_at": datetime.now(timezone.utc).isoformat(),
            "agent": agent,
        },
    )
    _append_run_log(path.name, proposal_id or "-", ok, detail)
    console.print(
        f"[{'green' if ok else 'red'}]Queue result: {path.name} → "
        f"proposal={proposal_id or 'none'} ok={ok}[/{'green' if ok else 'red'}]"
    )
    return ok


async def drain(
    *,
    once: bool = False,
    sleep_sec: int = DEFAULT_SLEEP_SEC,
    ollama: Optional[OllamaClient] = None,
    xai: Optional[XaiClient] = None,
) -> None:
    _ensure_dirs()
    own_ollama = ollama is None
    own_xai = xai is None
    if ollama is None:
        ollama = OllamaClient(os.getenv("OLLAMA_HOST", "http://ollama:11434"))
    if xai is None:
        xai = XaiClient()

    try:
        try:
            models = await ollama.list_models()
            console.print(f"[green]Ollama OK — {len(models)} models[/green]")
        except Exception as e:
            console.print(f"[yellow]Ollama unreachable: {e}[/yellow]")
        if xai.configured:
            console.print("[green]xAI key present[/green]")
        else:
            console.print("[dim]XAI_API_KEY not set — backend: xai tasks will fail[/dim]")

        processed = 0
        while True:
            inbox = _list_inbox()
            if not inbox:
                if processed == 0:
                    console.print("[dim]Inbox empty (only *.task.txt are processed).[/dim]")
                else:
                    console.print(f"[green]Inbox drained ({processed} task(s)).[/green]")
                break

            def sort_key(p: Path):
                try:
                    _, _, pri, _ = parse_task_file(p)
                except Exception:
                    pri = 100
                return (pri, p.stat().st_mtime)

            inbox = sorted(inbox, key=sort_key)
            await _run_one(inbox[0], ollama=ollama, xai=xai)
            processed += 1

            if once:
                break
            if sleep_sec > 0 and _list_inbox():
                console.print(f"[dim]Sleeping {sleep_sec}s before next task…[/dim]")
                await asyncio.sleep(sleep_sec)
    finally:
        if own_ollama:
            await ollama.close()
        if own_xai:
            await xai.close()


def status() -> None:
    _ensure_dirs()
    inbox = _list_inbox()
    running = [p for p in RUNNING.iterdir() if p.is_file() and p.name != ".gitkeep"]
    done = [p for p in DONE.iterdir() if p.is_file() and p.suffix != ".json" and p.name != ".gitkeep"]
    console.print(f"inbox   : {len(inbox)} (*.task.txt only)")
    for p in inbox[:10]:
        console.print(f"  • {p.name}")
    console.print(f"running : {len(running)}")
    for p in running[:5]:
        console.print(f"  • {p.name}")
    console.print(f"done    : {len(done)} (showing last 5)")
    for p in sorted(done, key=lambda x: x.stat().st_mtime, reverse=True)[:5]:
        console.print(f"  • {p.name}")
    if RUN_LOG.exists():
        console.print(f"run_log : {RUN_LOG}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Orchestrator queue runner")
    parser.add_argument("--drain", action="store_true", help="Process all inbox tasks")
    parser.add_argument("--once", action="store_true", help="Process one inbox task then exit")
    parser.add_argument("--status", action="store_true", help="Show queue counts")
    parser.add_argument(
        "--sleep",
        type=int,
        default=DEFAULT_SLEEP_SEC,
        help=f"Seconds between tasks (default {DEFAULT_SLEEP_SEC})",
    )
    args = parser.parse_args()

    if args.status or (not args.drain and not args.once):
        status()
        if not args.drain and not args.once:
            return

    if args.once:
        asyncio.run(drain(once=True, sleep_sec=args.sleep))
    elif args.drain:
        asyncio.run(drain(once=False, sleep_sec=args.sleep))


if __name__ == "__main__":
    main()
