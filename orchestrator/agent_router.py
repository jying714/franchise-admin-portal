"""
agent_router.py
---------------
Decides which specialized agent should handle a task and
builds the final prompt that is sent to Ollama.

Status / summary / progress tasks are specially handled:
  - Forced to the reviewer agent
  - Prefer the stronger 14b model (with automatic 7b fallback)
  - Lower num_ctx (8192) to stay within memory limits
  - Extra hard rules that make STATUS.md authoritative

Source-file awareness:
  - Any path mentioned in the task is auto-loaded via file_reader
  - Real file contents are injected so agents stop inventing code
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Optional

from context_loader import build_system_prompt, load_mandatory_context
from file_reader import load_mentioned_files


# Simple keyword-based routing (good enough for Phase 0)
ROUTING_RULES = [
    (r"\b(firestore|schema|config|provider|shared_core|backend|stripe|webhook|security.?rule)\b", "backend"),
    (r"\b(web.?app|dashboard|hq.?owner|design.?branding|flutter.?web|ui.?component)\b", "web_frontend"),
    (r"\b(mobile|android|ios|dynamic.?ui|restaurant.?type|offline|shared.?core)\b", "mobile_shared"),
    (r"\b(test|qa|analyze|regression|device)\b", "tester"),
    (r"\b(review|architecture|pr|quality|docs?)\b", "reviewer"),
]

# Patterns that indicate a status / summary / progress task
STATUS_TASK_PATTERNS = [
    r"\b(status|summarize|summary|progress|remaining|acceptance.?criteria|what.?is.?left|phase.?\d+.?status)\b",
]


@dataclass
class TaskResult:
    agent: str
    model: str
    system_prompt: str
    user_prompt: str
    requires_human_approval: bool
    reason: str
    num_ctx: int = 8192


def is_status_task(task_text: str) -> bool:
    """Return True if this looks like a status / summary / progress query."""
    lower = task_text.lower()
    return any(re.search(p, lower, re.IGNORECASE) for p in STATUS_TASK_PATTERNS)


def detect_agent(task_text: str) -> str:
    """Return the best agent name for the given task description."""
    if is_status_task(task_text):
        return "reviewer"
    lower = task_text.lower()
    for pattern, agent in ROUTING_RULES:
        if re.search(pattern, lower, re.IGNORECASE):
            return agent
    return "orchestrator"


def needs_human_approval(task_text: str, agent: str) -> tuple[bool, str]:
    """
    Enforce the human-approval gates defined in AGENT_SYSTEM.md.
    Returns (requires_approval, reason).
    """
    lower = task_text.lower()

    high_risk_keywords = [
        "firestore schema", "security rule", "stripe", "payment", "webhook",
        "config migration", "branding", "design token", "ui_config",
        "architecture", "refactor", "breaking change", "production",
    ]

    for kw in high_risk_keywords:
        if kw in lower:
            return True, f"High-risk keyword detected: '{kw}' — human review mandatory"

    if agent in ("backend", "web_frontend") and any(
        w in lower for w in ["config", "schema", "provider", "branding"]
    ):
        return True, "Config / schema / branding work requires human approval"

    return False, "Low-risk task — still propose only, never auto-apply"


def prepare_task(
    project_root: Path,
    task_text: str,
    preferred_agent: Optional[str] = None,
    model_map: Optional[Dict[str, str]] = None,
) -> TaskResult:
    """
    Full preparation pipeline:
      1. Load mandatory context
      2. Choose agent (status tasks forced to reviewer)
      3. Build system prompt
      4. Auto-load any source files mentioned in the task
      5. Choose model + num_ctx
      6. Decide human-approval flag
      7. Build user prompt with extra status rules when needed
    """
    mandatory = load_mandatory_context(project_root)

    status = is_status_task(task_text)
    agent = preferred_agent or detect_agent(task_text)
    system = build_system_prompt(project_root, agent, mandatory)

    # --- Real source files (the key fix for hallucinations) ---
    source_block = load_mentioned_files(project_root, task_text)

    requires_approval, reason = needs_human_approval(task_text, agent)

    # Default model mapping
    default_models = {
        "orchestrator": "qwen2.5-coder:7b",
        "backend": "qwen2.5-coder:14b",
        "web_frontend": "qwen2.5-coder:14b",
        "mobile_shared": "qwen2.5-coder:14b",
        "tester": "qwen2.5-coder:7b",
        "reviewer": "qwen2.5-coder:7b",
    }
    models = model_map or default_models

    # Status tasks prefer the stronger 14b (client will fall back to 7b on 500)
    # and use a safer context window.
    if status:
        model = "qwen2.5-coder:14b"
        num_ctx = 8192
    else:
        model = models.get(agent, "qwen2.5-coder:14b")
        # Give coding tasks a bit more room when source files are present
        num_ctx = 16384 if source_block else 8192

    # Base instructions — strengthened anti-hallucination rules
    base_instructions = """- Stay strictly inside the current phase (Phase 0 right now).
- Propose concrete, small, reviewable changes only.
- NEVER invent file paths, class fields, or method signatures that are not present in the provided source.
- If a required source file is missing from the context (or marked MISSING/BLOCKED), say so clearly and stop. Do not invent its contents.
- When proposing a code change, quote the exact current lines you are modifying (before) and the exact new lines (after).
- Flag any potential scope creep immediately.
- End your response with a short "Next steps for human" section."""

    # Extra hard rules for status / summary tasks
    status_rules = """
## STATUS-TASK RULES (mandatory — follow exactly)
- STATUS.md is the single live source of truth for what is already done.
- Prefer STATUS.md over any older language found in other documents.
- Only mark an item as incomplete if STATUS.md (or the current phase task file) still lists it as open.
- Do NOT re-open or re-list items that are already checked off in STATUS.md.
- Do NOT invent missing work.
- Produce a clean checklist of what is done vs what is still open.
- Then list only the real remaining items that agents can safely propose under human review.
- Keep the tone factual and concise.
"""

    source_section = f"\n{source_block}\n" if source_block else ""

    if status:
        user_prompt = f"""## TASK
{task_text}

## INSTRUCTIONS
{base_instructions}
{status_rules}
{source_section}
"""
    else:
        user_prompt = f"""## TASK
{task_text}

## INSTRUCTIONS
{base_instructions}
{source_section}
"""

    return TaskResult(
        agent=agent,
        model=model,
        system_prompt=system,
        user_prompt=user_prompt,
        requires_human_approval=requires_approval,
        reason=reason,
        num_ctx=num_ctx,
    )
