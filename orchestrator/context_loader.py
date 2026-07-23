"""
context_loader.py
-----------------
Loads the mandatory reference documents required by every agent
(see AGENT_SYSTEM.md "Mandatory Reference Rules").

Two modes:
  - full   : STATUS + personality + excerpts of all mandatory docs
             (used for status / planning / review tasks)
  - minimal: short role + short STATUS excerpt + hard rules only
             (used when real source files are injected so the task
              and code dominate the context window)
"""

from __future__ import annotations

import logging
from pathlib import Path
from typing import Dict, List

from rich.console import Console

console = Console()
logger = logging.getLogger("orchestrator.context")

MANDATORY_FILES: List[str] = [
    "STATUS.md",
    "AGENT_SYSTEM.md",
    "ROADMAP.md",
    "ARCHITECTURE.md",
    "HANDOFF.md",
    "docs/architecture/firestore-per-franchise-config.md",
    "docs/DASHBOARDS.md",
    "docs/MOBILE_DYNAMIC.md",
    "docs/DECISIONS.md",
    "docs/CONTRIBUTING.md",
    "README.md",
    "packages/shared_core/README.md",
    "mobile_app/README.md",
    "web-app/README.md",
    "tasks/README.md",
    "tasks/Phase0.md",
    "tasks/Phase1.md",
]

FULL_LOAD_FILES = {"STATUS.md"}

# How many lines of STATUS.md to keep in minimal (coding) mode
MINIMAL_STATUS_LINES = 35

PROMPT_DIR = Path("prompts")
AGENT_PROMPTS = {
    "orchestrator": "orchestrator.md",
    "backend": "backend.md",
    "web_frontend": "web_frontend.md",
    "mobile_shared": "mobile_shared.md",
    "tester": "tester.md",
    "reviewer": "reviewer.md",
}


def _safe_read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        msg = f"[MISSING] {path} — this file is required by AGENT_SYSTEM.md"
        logger.warning(msg)
        return msg
    except Exception as e:
        msg = f"[ERROR reading {path}] {e}"
        logger.error(msg)
        return msg


def _short_status(full_status: str, max_lines: int = MINIMAL_STATUS_LINES) -> str:
    """Return the first max_lines of STATUS.md for minimal coding context."""
    lines = full_status.splitlines()
    if len(lines) <= max_lines:
        return full_status
    excerpt = "\n".join(lines[:max_lines])
    return excerpt + "\n\n...[STATUS truncated for coding-task context — full STATUS used only for status/planning tasks]"


def load_mandatory_context(project_root: Path) -> Dict[str, str]:
    context: Dict[str, str] = {}
    console.print("\n[bold cyan]Loading mandatory reference documents...[/bold cyan]")

    for rel_path in MANDATORY_FILES:
        full = project_root / rel_path
        content = _safe_read(full)
        context[rel_path] = content
        status = "✓" if not content.startswith("[") else "✗"
        full_marker = " (full)" if rel_path in FULL_LOAD_FILES else ""
        console.print(f"  {status} {rel_path}{full_marker}")

    console.print(f"[green]Loaded {len(context)} mandatory documents.[/green]\n")
    return context


def load_agent_prompt(project_root: Path, agent_name: str) -> str:
    if agent_name not in AGENT_PROMPTS:
        raise ValueError(f"Unknown agent: {agent_name}. Valid: {list(AGENT_PROMPTS)}")
    prompt_path = project_root / PROMPT_DIR / AGENT_PROMPTS[agent_name]
    return _safe_read(prompt_path)


def build_system_prompt(
    project_root: Path,
    agent_name: str,
    mandatory_context: Dict[str, str],
    *,
    minimal: bool = False,
) -> str:
    personality = load_agent_prompt(project_root, agent_name)

    status_block = ""
    if "STATUS.md" in mandatory_context:
        status_block = mandatory_context["STATUS.md"]

    # A1: docstring/comment-only edits are explicitly SAFE and expected
    hard_rules = """
## HARD RULES (never break these)
- Propose only. Never write files, never push, never touch Firestore.
- When RELEVANT SOURCE FILES are provided, they are the ONLY ground truth.
- NEVER invent fields, methods, imports, or file structure not in the provided source.
- NEVER add new class fields, change Firestore mapping, or change business logic unless the task explicitly asks for that (and even then, propose only).

## SAFE EDITS (always allowed when the task asks for them)
- Adding or improving a class-level docstring (/// ...) is SAFE. Do it when asked.
- Adding or improving a short comment above an existing member is SAFE when asked.
- These documentation-only changes do NOT require refusal. Propose them with exact before/after.

## WHEN TO STOP
- Stop only if the required source file is missing/blocked, or the task asks for schema/security/payment changes without human-approval context.
- Do not refuse a pure docstring or comment improvement.
"""

    if minimal:
        console.print("[dim]Context mode: MINIMAL (source-file task — short STATUS + hard rules only)[/dim]")
        short_role = personality[:600].strip()
        if len(personality) > 600:
            short_role += "\n...[role truncated for edit mode]"

        short_status = _short_status(status_block)

        return f"""{short_role}

---
# LIVE STATUS (authoritative, truncated for coding task)
{short_status}

{hard_rules}
"""

    summary_parts = []
    for name, content in mandatory_context.items():
        if name == "STATUS.md":
            continue
        excerpt = content[:800].strip()
        if len(content) > 800:
            excerpt += "\n...[truncated]"
        summary_parts.append(f"### {name}\n{excerpt}")

    context_block = "\n\n".join(summary_parts)

    non_negotiables = """
## NON-NEGOTIABLE RULES (enforced by Orchestrator)
- STATUS.md is the live source of truth for current project state.
- All work MUST stay inside the current phase acceptance criteria.
- shared_core is the single source of truth.
- All customer data lives under franchises/{franchiseId}/...
- Hybrid single/multi-location logic must be respected.
- Dynamic config / branding / UI is mandatory.
- NEVER perform direct Firestore writes or production changes.
- Propose changes only → human reviews → merge via PR.
- Flag any potential scope creep immediately.
- Human review is mandatory for: architecture, config, schema, payments, security, design/branding.

## SOURCE-CODE RULES
- When source files are provided under "RELEVANT SOURCE FILES", treat them as the only ground truth.
- NEVER invent fields, methods, imports, or file structure that is not present in the provided source.
- Adding a class-level docstring or improving a comment is SAFE and expected when the task asks for it.
- If a file you need is missing from the context, explicitly say so and stop.
- When proposing an edit, always show the exact current lines (before) and the exact new lines (after).
"""

    return f"""{personality}

---
# LIVE PROJECT STATUS (always authoritative)
### STATUS.md
{status_block}

---
# MANDATORY PROJECT CONTEXT (excerpts)
{context_block}

{non_negotiables}
"""
