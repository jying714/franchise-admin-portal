"""
context_loader.py
-----------------
Loads the mandatory reference documents required by every agent
(see AGENT_SYSTEM.md "Mandatory Reference Rules").

These files form the "constitution" that is prepended to every LLM call.

STATUS.md is always injected in full (never truncated) so agents always
see an accurate live snapshot of the project.
"""

from __future__ import annotations

import logging
from pathlib import Path
from typing import Dict, List

from rich.console import Console

console = Console()
logger = logging.getLogger("orchestrator.context")

# Exact list from AGENT_SYSTEM.md + STATUS.md (keep in sync)
MANDATORY_FILES: List[str] = [
    "STATUS.md",                                          # always full — live truth
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
]

# Files that must be injected in full (no truncation)
FULL_LOAD_FILES = {"STATUS.md"}

# Agent personality prompts
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
    """Read a file; return a clear error message if missing."""
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


def load_mandatory_context(project_root: Path) -> Dict[str, str]:
    """
    Load every mandatory document relative to the monorepo root.
    Returns a dict: filename → content
    """
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
    """Load the personality prompt for a specialized agent."""
    if agent_name not in AGENT_PROMPTS:
        raise ValueError(f"Unknown agent: {agent_name}. Valid: {list(AGENT_PROMPTS)}")

    prompt_path = project_root / PROMPT_DIR / AGENT_PROMPTS[agent_name]
    return _safe_read(prompt_path)


def build_system_prompt(
    project_root: Path,
    agent_name: str,
    mandatory_context: Dict[str, str],
) -> str:
    """
    Construct the full system prompt that is sent to Ollama.
    Order:
      1. Agent personality (from prompts/*.md)
      2. STATUS.md in full (live truth)
      3. Condensed excerpts of the other mandatory docs
      4. Explicit non-negotiable rules
    """
    personality = load_agent_prompt(project_root, agent_name)

    # --- STATUS.md always goes in full and first ---
    status_block = ""
    if "STATUS.md" in mandatory_context:
        status_block = f"### STATUS.md (live project snapshot — always authoritative)\n{mandatory_context['STATUS.md']}"

    # --- Remaining docs: short excerpts ---
    summary_parts = []
    for name, content in mandatory_context.items():
        if name == "STATUS.md":
            continue  # already handled
        excerpt = content[:800].strip()
        if len(content) > 800:
            excerpt += "\n...[truncated — full document available in repo]"
        summary_parts.append(f"### {name}\n{excerpt}")

    context_block = "\n\n".join(summary_parts)

    non_negotiables = """
## NON-NEGOTIABLE RULES (enforced by Orchestrator)
- STATUS.md is the live source of truth for current project state. Prefer it over older documents when they conflict.
- All work MUST stay inside the current phase acceptance criteria (see ROADMAP.md + tasks/PhaseX.md).
- shared_core is the single source of truth.
- All customer data lives under franchises/{franchiseId}/...
- Hybrid single/multi-location logic must be respected.
- Dynamic config / branding / UI is mandatory (see firestore-per-franchise-config.md).
- NEVER perform direct Firestore writes or production changes.
- Propose changes only → human reviews → merge via PR.
- Flag any potential scope creep immediately.
- Human review is mandatory for: architecture, config, schema, payments, security, design/branding.

## SOURCE-CODE RULES (critical — prevents hallucinations)
- When source files are provided under "RELEVANT SOURCE FILES", treat them as the only ground truth.
- NEVER invent fields, methods, imports, or file structure that is not present in the provided source.
- If a file you need is missing from the context, explicitly say "I do not have the real contents of <path>" and stop.
- When proposing an edit, always show the exact current lines (before) and the exact new lines (after).
"""

    full = f"""{personality}

---
# LIVE PROJECT STATUS (always authoritative)
{status_block}

---
# MANDATORY PROJECT CONTEXT (excerpts)
{context_block}

{non_negotiables}
"""
    return full
