"""
agent_router.py
---------------
Decides which specialized agent should handle a task and
builds the final prompt that is sent to Ollama.

When real source files are loaded, switches to minimal-context mode
so the task + source dominate and the model stops inventing fields.

A1: docstring/comment-only edits are explicitly allowed (no over-refusal).
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Optional

from context_loader import build_system_prompt, load_mandatory_context
from file_reader import load_mentioned_files


ROUTING_RULES = [
    (r"\b(firestore|schema|config|provider|shared_core|backend|stripe|webhook|security.?rule)\b", "backend"),
    (r"\b(web.?app|dashboard|hq.?owner|design.?branding|flutter.?web|ui.?component)\b", "web_frontend"),
    (r"\b(mobile|android|ios|dynamic.?ui|restaurant.?type|offline|shared.?core)\b", "mobile_shared"),
    (r"\b(test|qa|analyze|regression|coverage)\b", "tester"),
    (r"\b(review|architecture|pr|quality|docs?)\b", "reviewer"),
]

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
    temperature: float = 0.15


def is_status_task(task_text: str) -> bool:
    lower = task_text.lower()
    return any(re.search(p, lower, re.IGNORECASE) for p in STATUS_TASK_PATTERNS)


def detect_agent(task_text: str) -> str:
    if is_status_task(task_text):
        return "reviewer"
    lower = task_text.lower()
    for pattern, agent in ROUTING_RULES:
        if re.search(pattern, lower, re.IGNORECASE):
            return agent
    return "orchestrator"


def needs_human_approval(task_text: str, agent: str) -> tuple[bool, str]:
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
    mandatory = load_mandatory_context(project_root)

    status = is_status_task(task_text)
    agent = preferred_agent or detect_agent(task_text)

    source_block = load_mentioned_files(project_root, task_text)
    has_source = bool(source_block)

    system = build_system_prompt(
        project_root, agent, mandatory, minimal=has_source and not status
    )

    requires_approval, reason = needs_human_approval(task_text, agent)

    default_models = {
        "orchestrator": "qwen2.5-coder:7b",
        "backend": "qwen2.5-coder:14b",
        "web_frontend": "qwen2.5-coder:14b",
        "mobile_shared": "qwen2.5-coder:14b",
        "tester": "qwen2.5-coder:7b",
        "reviewer": "qwen2.5-coder:7b",
    }
    models = model_map or default_models

    num_ctx = 8192
    temperature = 0.05 if has_source else 0.15

    if status:
        model = "qwen2.5-coder:14b"
    else:
        model = models.get(agent, "qwen2.5-coder:14b")

    if status:
        user_prompt = f"""## TASK
{task_text}

## INSTRUCTIONS
- STATUS.md is the single live source of truth.
- Prefer STATUS.md over older documents.
- Only mark items incomplete if STATUS.md still lists them open.
- Do not invent missing work.
- Produce a clean done vs open checklist, then list only real remaining agent-safe items.
- End with "Next steps for human".
"""
    elif has_source:
        # A1: allow docstring/comment edits; forbid field invention; no over-refusal
        # Strict BEFORE/AFTER fences are required so /approve confirm can apply locally.
        user_prompt = f"""## TASK
{task_text}

## WHAT IS ALLOWED
- Class-level docstrings (/// ...) above an existing class — SAFE. Propose them when asked.
- Improving an existing comment — SAFE when asked.
- Documentation-only changes must be proposed with exact before/after from the real source.

## WHAT IS FORBIDDEN
- Do NOT add new fields, getters, methods, or change Firestore mapping.
- Do NOT invent code that is not in the source below.
- Do NOT change business logic unless the task explicitly requests it.

## HOW TO RESPOND (format is mandatory — apply will fail otherwise)
1. Quote the exact first 8–12 lines of the loaded file (copy from the source block).
2. Show the change using EXACTLY these two headings and fenced blocks:

## BEFORE
```dart
<paste the exact current lines you will replace — copy whitespace from the source>
```

## AFTER
```dart
<paste the exact new lines for that same region only>
```

3. Only include the region you change (usually the docstring or comment lines). Do not dump the whole file.
4. Short "Next steps for human".

Only stop if the source file is missing/blocked. Do not refuse a pure docstring or comment improvement.

{source_block}
"""
    else:
        user_prompt = f"""## TASK
{task_text}

## INSTRUCTIONS
- Stay inside the current phase.
- Propose concrete, small, reviewable changes only.
- NEVER invent file paths or code not present in context.
- If source is missing, say so and stop.
- Quote exact before/after using ## BEFORE / ## AFTER fenced blocks.
- End with "Next steps for human".
"""

    return TaskResult(
        agent=agent,
        model=model,
        system_prompt=system,
        user_prompt=user_prompt,
        requires_human_approval=requires_approval,
        reason=reason,
        num_ctx=num_ctx,
        temperature=temperature,
    )
