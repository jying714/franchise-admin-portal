"""
agent_router.py
---------------
Decides which specialized agent should handle a task and
builds the final prompt that is sent to Ollama or xAI.

When real source files are loaded, switches to minimal/smart context
so the task + source dominate and the model stops inventing fields.

A1: docstring/comment-only edits are explicitly allowed (no over-refusal).

2026-07-25: Honor explicit Role: line; backend: xai|ollama; SMART context for xAI.
2026-07-25 evening: APPLY SAFETY (import keep, max regions, empty AFTER for deletes).
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Optional

from backend_config import detect_backend, load_backends_config
from context_loader import build_system_prompt, load_mandatory_context
from file_reader import load_mentioned_files


ROUTING_RULES = [
    (r"\b(firestore|schema|config|provider|shared_core|backend|stripe|webhook|security.?rule)\b", "backend"),
    (r"\b(web.?app|dashboard|hq.?owner|design.?branding|flutter.?web|ui.?component)\b", "web_frontend"),
    (r"\b(mobile|android|ios|dynamic.?ui|restaurant.?type|offline|shared.?core)\b", "mobile_shared"),
    (r"\b(test|qa|analyze|regression|coverage)\b", "tester"),
    (r"\b(review|architecture|pr|quality|docs?)\b", "reviewer"),
]

VALID_AGENTS = {
    "backend",
    "web_frontend",
    "mobile_shared",
    "tester",
    "reviewer",
    "orchestrator",
}

STATUS_TASK_PATTERNS = [
    r"\b(status\.?md|project status|phase status|what.?is.?left|acceptance.?criteria)\b",
    r"\b(summarize|summary)\b.*\b(phase|status|progress|remaining)\b",
    r"\b(remaining|open)\b.*\b(phase|acceptance|STATUS)\b",
    r"\bphase.?\d+.?status\b",
]

ROLE_LINE_RE = re.compile(
    r"(?:^|\n)\s*Role\s*:\s*([\w_]+)",
    re.IGNORECASE,
)


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
    backend: str = "ollama"  # ollama | xai


def is_status_task(task_text: str) -> bool:
    lower = task_text.lower()
    return any(re.search(p, lower, re.IGNORECASE) for p in STATUS_TASK_PATTERNS)


def detect_agent(task_text: str) -> str:
    m = ROLE_LINE_RE.search(task_text)
    if m:
        role = m.group(1).strip().lower()
        if role in VALID_AGENTS:
            return role
        aliases = {
            "web": "web_frontend",
            "frontend": "web_frontend",
            "mobile": "mobile_shared",
            "qa": "tester",
            "test": "tester",
        }
        if role in aliases:
            return aliases[role]

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
    cfg = load_backends_config(project_root)
    backend = detect_backend(task_text, cfg)

    mandatory = load_mandatory_context(project_root)

    status = is_status_task(task_text)
    agent = preferred_agent or detect_agent(task_text)

    source_block = load_mentioned_files(project_root, task_text)
    has_source = bool(source_block)

    use_status_prompt = status and not has_source

    if use_status_prompt:
        context_mode = "full"
    elif has_source and backend == "xai":
        context_mode = "smart"
    elif has_source:
        context_mode = "minimal"
    else:
        context_mode = "full"

    system = build_system_prompt(
        project_root,
        agent,
        mandatory,
        minimal=(context_mode == "minimal"),
        smart=(context_mode == "smart"),
        backend=backend,
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
    ollama_cfg = (cfg.get("ollama") or {}).get("models") or {}
    for k, v in ollama_cfg.items():
        models[k] = v

    num_ctx = 8192
    temperature = 0.05 if has_source else 0.15

    if backend == "xai":
        xai_cfg = cfg.get("xai") or {}
        model = str(xai_cfg.get("model") or "grok-4.5")
        temperature = float(xai_cfg.get("temperature", 0.1))
        num_ctx = 0
    elif use_status_prompt:
        model = "qwen2.5-coder:14b"
    else:
        model = models.get(agent, "qwen2.5-coder:14b")

    apply_safety = """
## APPLY SAFETY (mandatory — broken apply is a failed proposal)
- Prefer **one** BEFORE/AFTER region per file. Maximum **two** regions per file unless the task explicitly allows more.
- **Never remove an import** unless every symbol from that import is unused in the file **after** your edit.
- If the file uses `OnboardingSections`, you **must keep**
  `import '.../onboarding_navigation_utils.dart';`
- Deleting a method: BEFORE = the full method; AFTER fence body must be **completely empty** (zero lines inside the fence). Do **not** put only `}` in AFTER.
- Do not use import cleanup as a side quest.
- Multi-region on the same path: each BEFORE must still match the file **after** prior regions would apply (order top-to-bottom).
"""

    if use_status_prompt:
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
        user_prompt = f"""## TASK
{task_text}

## BACKEND
{backend} (proposal only — human applies via /approve confirm; never auto-push)

## WHAT IS ALLOWED
- Class-level docstrings (/// ...) above an existing class — SAFE. Propose them when asked.
- Improving an existing comment — SAFE when asked.
- Documentation-only changes must be proposed with exact before/after from the real source.
- Surgical product fixes on named files only.

## WHAT IS FORBIDDEN
- Do NOT add new fields, getters, methods, or change Firestore mapping unless the task explicitly requires it.
- Do NOT invent code that is not in the source below.
- Do NOT change business logic unless the task explicitly requests it.
- Do NOT use static FranchiseProvider.current* — instance only.
- Do NOT reintroduce Admin onboarding paths (admin/dashboard/onboarding is deleted).
- Do NOT use top-level onboarding_progress/{{id}} — progress lives under franchises/{{id}}/onboarding_progress/progress.
{apply_safety}
## HOW TO RESPOND (format is mandatory — apply will fail otherwise)
A) If the named file(s) already satisfy the task → reply with a single line only:
No change needed
Do NOT emit full-class BEFORE/AFTER for verify-only tasks.

B) Else:
1. Quote the exact first 8–12 lines of the loaded file (copy from the source block).
2. Prefer **one** FILE block with one BEFORE/AFTER. If you must use two regions, stop at two.
3. Show the change using EXACTLY these headings and fenced blocks:

FILE: path/to/file.dart

## BEFORE
```dart
<paste the exact current lines you will replace — contiguous region from source>
```

## AFTER
```dart
<paste the exact new lines for that same region only; empty fence body = delete region>
```

4. CRITICAL for apply: In BEFORE, copy indentation and line breaks from the RELEVANT SOURCE FILES block byte-for-byte.
5. Only include the region you change. Do not dump the whole file.
6. Short "Next steps for human" only if something remains out of scope.

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
- If already correct → reply only: No change needed
- Else quote exact before/after using ## BEFORE / ## AFTER fenced blocks.
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
        backend=backend,
    )
