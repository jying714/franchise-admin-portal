"""
context_loader.py
-----------------
Loads reference documents for agent prompts.

Modes (system prompt packing):
  - full        : STATUS + personality + excerpts of all mandatory docs
  - minimal     : short role + short STATUS + SCOPE_CARD + hard rules (Ollama source)
  - smart       : same compact pack as minimal + xAI proposal-only note
  - coding_min  : alias of smart packing; **disk load** only STATUS + SCOPE_CARD

Task header (optional):
  # context: coding_min | coding_std | full | source_only

Default for backend:xai + source files → coding_min (token-efficient, task stays clear).
"""

from __future__ import annotations

import logging
import re
from pathlib import Path
from typing import Dict, List, Optional

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

SCOPE_CARD_PATH = "orchestrator/SCOPE_CARD.md"

# coding_min / smart / minimal: only these governance files hit the prompt
CODING_MIN_FILES: List[str] = [
    "STATUS.md",
    SCOPE_CARD_PATH,
]

FULL_LOAD_FILES = {"STATUS.md"}

MINIMAL_STATUS_LINES = 28

PROMPT_DIR = Path("prompts")
AGENT_PROMPTS = {
    "orchestrator": "orchestrator.md",
    "backend": "backend.md",
    "web_frontend": "web_frontend.md",
    "mobile_shared": "mobile_shared.md",
    "tester": "tester.md",
    "reviewer": "reviewer.md",
}

CONTEXT_HEADER_RE = re.compile(
    r"(?:^|\n)\s*#\s*context\s*:\s*([\w_]+)",
    re.IGNORECASE,
)

VALID_CONTEXT_MODES = {
    "coding_min",
    "coding_std",
    "smart",
    "minimal",
    "full",
    "source_only",
}


def parse_context_mode(task_text: str) -> Optional[str]:
    """Return explicit # context: value from task header, or None."""
    m = CONTEXT_HEADER_RE.search(task_text or "")
    if not m:
        return None
    mode = m.group(1).strip().lower()
    if mode in VALID_CONTEXT_MODES:
        return mode
    logger.warning("Unknown # context: %s — ignoring", mode)
    return None


def _safe_read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        msg = f"[MISSING] {path} — required governance file"
        logger.warning(msg)
        return msg
    except Exception as e:
        msg = f"[ERROR reading {path}] {e}"
        logger.error(msg)
        return msg


def _short_status(full_status: str, max_lines: int = MINIMAL_STATUS_LINES) -> str:
    lines = full_status.splitlines()
    if len(lines) <= max_lines:
        return full_status

    # Prefer open + ground-truth sections when present
    preferred_markers = (
        "Still open",
        "Ground truth",
        "Progress tracking",
        "Current Phase",
        "Agent mode",
        "xAI",
    )
    picked: List[str] = []
    # Always keep header lines
    picked.extend(lines[:12])
    for i, line in enumerate(lines):
        if any(m in line for m in preferred_markers):
            # take from marker through next ~15 lines
            chunk = lines[i : i + 16]
            for c in chunk:
                if c not in picked:
                    picked.append(c)
            if len(picked) >= max_lines:
                break
    if len(picked) < 16:
        picked = lines[:max_lines]
    else:
        picked = picked[:max_lines]
    return (
        "\n".join(picked)
        + "\n\n...[STATUS truncated for coding_min — open items + ground truth retained]"
    )


def load_mandatory_context(
    project_root: Path,
    *,
    context_mode: str = "full",
) -> Dict[str, str]:
    """
    Load governance docs from disk.

    coding_min / smart / minimal / source_only → STATUS + SCOPE only.
    full / coding_std → full MANDATORY_FILES + SCOPE.
    """
    context: Dict[str, str] = {}
    mode = (context_mode or "full").lower()

    if mode in ("coding_min", "smart", "minimal", "source_only"):
        rels = list(CODING_MIN_FILES)
        console.print(
            f"\n[bold cyan]Loading coding context ({mode}) — STATUS + SCOPE_CARD only...[/bold cyan]"
        )
    else:
        rels = list(MANDATORY_FILES) + [SCOPE_CARD_PATH]
        console.print("\n[bold cyan]Loading mandatory reference documents (full)...[/bold cyan]")

    for rel_path in rels:
        if rel_path in context:
            continue
        full = project_root / rel_path
        content = _safe_read(full)
        context[rel_path] = content
        status = "✓" if not content.startswith("[") else "✗"
        full_marker = " (full)" if rel_path in FULL_LOAD_FILES else ""
        always = " (always-on)" if rel_path == SCOPE_CARD_PATH else ""
        console.print(f"  {status} {rel_path}{full_marker}{always}")

    # Ensure SCOPE always present
    if SCOPE_CARD_PATH not in context:
        scope_content = _safe_read(project_root / SCOPE_CARD_PATH)
        context[SCOPE_CARD_PATH] = scope_content

    console.print(f"[green]Loaded {len(context)} document(s) for mode={mode}.[/green]\n")
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
    smart: bool = False,
    backend: Optional[str] = None,
    context_mode: Optional[str] = None,
) -> str:
    personality = load_agent_prompt(project_root, agent_name)

    status_block = mandatory_context.get("STATUS.md", "")
    scope_card = mandatory_context.get(SCOPE_CARD_PATH, "")

    hard_rules = """
## HARD RULES
- Propose only. Never write files, never push, never touch Firestore.
- RELEVANT SOURCE FILES are the only ground truth for edits.
- Never invent fields/methods/imports not in provided source.
- Docstring/comment-only edits are SAFE when asked.
- Stop if required source is missing; else propose exact BEFORE/AFTER.
"""

    api_truth = """
## API TRUTHS (do not invent alternatives)
- Menu delete: `deleteMenuItem(String id)` then usually `persistChanges()` — not removeMenuItem.
- Progress marks: `Provider.of<shared.OnboardingProgressProvider>(context, listen: false)`.
- Listenable progress in shell: `ChangeNotifierProvider<OnboardingProgressProviderImpl>` + ProxyProvider to abstract — never ChangeNotifierProvider of abstract.
- One FILE path once per proposal; prefer multi-line BEFORE; fences only.
"""

    backend_note = ""
    if backend == "xai":
        backend_note = (
            "\n## BACKEND: xAI\n"
            "- Output is a **proposal** only. Human /approve confirm applies.\n"
        )

    # Compact modes share the same system packing
    use_compact = minimal or smart or (context_mode in ("coding_min", "source_only", "minimal", "smart"))

    if use_compact:
        label = context_mode or ("smart" if smart else "minimal")
        console.print(f"[dim]Context mode: {label} (SCOPE_CARD + short STATUS)[/dim]")
        short_role = personality[:500].strip()
        if len(personality) > 500:
            short_role += "\n...[role truncated]"

        short_status = _short_status(status_block)

        return f"""{short_role}

---
# LIVE STATUS (truncated)
{short_status}

---
# SCOPE CARD (obey)
{scope_card}
{backend_note}
{api_truth}
{hard_rules}
"""

    # Full / coding_std
    summary_parts = []
    for name, content in mandatory_context.items():
        if name == "STATUS.md" or name == SCOPE_CARD_PATH:
            continue
        excerpt = content[:800].strip()
        if len(content) > 800:
            excerpt += "\n...[truncated]"
        summary_parts.append(f"### {name}\n{excerpt}")

    context_block = "\n\n".join(summary_parts)

    non_negotiables = """
## NON-NEGOTIABLE RULES
- STATUS.md is live truth for phase state.
- shared_core is single source of domain models.
- Propose only; human merge gate.
- When RELEVANT SOURCE FILES provided, never invent symbols not in them.
"""

    return f"""{personality}

---
# LIVE PROJECT STATUS
### STATUS.md
{status_block}

---
# SCOPE CARD
{scope_card}

---
# MANDATORY PROJECT CONTEXT (excerpts)
{context_block}

{api_truth}
{non_negotiables}
"""
