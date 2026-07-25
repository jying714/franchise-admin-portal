"""
agent_router.py
---------------
Routes tasks and builds prompts for Ollama or xAI.

Context modes:
  - coding_min (default for backend:xai + source): STATUS+SCOPE only, compact system
  - full: all mandatory docs (status/planning)
  - explicit via task header: # context: coding_min|coding_std|full|source_only
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Optional

from backend_config import detect_backend, load_backends_config
from context_loader import (
    build_system_prompt,
    load_mandatory_context,
    parse_context_mode,
)
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
    context_mode: str = "full"


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


def resolve_context_mode(
    task_text: str,
    *,
    backend: str,
    has_source: bool,
    is_status: bool,
) -> str:
    """Explicit header wins; else defaults that preserve task clarity at lower token cost."""
    explicit = parse_context_mode(task_text)
    if explicit:
        return explicit
    if is_status and not has_source:
        return "full"
    if has_source and backend == "xai":
        return "coding_min"
    if has_source:
        return "minimal"
    return "full"


def prepare_task(
    project_root: Path,
    task_text: str,
    preferred_agent: Optional[str] = None,
    model_map: Optional[Dict[str, str]] = None,
) -> TaskResult:
    cfg = load_backends_config(project_root)
    backend = detect_backend(task_text, cfg)

    status = is_status_task(task_text)
    agent = preferred_agent or detect_agent(task_text)

    source_block = load_mentioned_files(project_root, task_text)
    has_source = bool(source_block)

    context_mode = resolve_context_mode(
        task_text,
        backend=backend,
        has_source=has_source,
        is_status=status,
    )

    mandatory = load_mandatory_context(project_root, context_mode=context_mode)

    use_status_prompt = status and not has_source
    use_compact = context_mode in ("coding_min", "smart", "minimal", "source_only")

    system = build_system_prompt(
        project_root,
        agent,
        mandatory,
        minimal=(context_mode == "minimal"),
        smart=(context_mode in ("smart", "coding_min", "source_only")),
        backend=backend,
        context_mode=context_mode,
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

    # Slim apply-safety for source tasks (full detail lives in SCOPE_CARD)
    apply_safety = """
## APPLY SAFETY
- Prefer one BEFORE/AFTER region (max two unless task allows more).
- Never remove imports still needed after your edit.
- Keep OnboardingSections import if UI still references it.
- Method delete: AFTER fence body empty (not only `}`).
- Progress: shared.OnboardingProgressProvider only; deleteMenuItem(id) for menu delete.
- One FILE path once. Multi-line BEFORE. Fences only — no truncation prose.
"""

    if use_status_prompt:
        user_prompt = f"""## TASK
{task_text}

## INSTRUCTIONS
- STATUS.md is the single live source of truth.
- Only mark items incomplete if STATUS still lists them open.
- Clean done vs open checklist; real remaining items only.
- End with "Next steps for human".
"""
    elif has_source:
        user_prompt = f"""## TASK
{task_text}

## BACKEND
{backend} — proposal only (human /approve confirm)

## CONTEXT
mode={context_mode} (SCOPE_CARD + STATUS in system; source below is edit ground truth)

## RESPONSE FORMAT (mandatory)
A) Already satisfied → single line: No change needed
B) Else:
1. Quote first 8–12 lines of the loaded file from source.
2. One FILE block preferred:

FILE: path/to/file.dart

## BEFORE
```dart
<exact contiguous region from source>
```

## AFTER
```dart
<exact replacement; empty body = delete region>
```

3. Copy indentation from RELEVANT SOURCE FILES byte-for-byte.
4. Only the changed region — not the whole file.
{apply_safety}
{source_block}
"""
    else:
        user_prompt = f"""## TASK
{task_text}

## INSTRUCTIONS
- Stay in current phase. Propose small reviewable changes only.
- Never invent paths/code not in context.
- If already correct → No change needed
- Else ## BEFORE / ## AFTER fences.
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
        context_mode=context_mode,
    )
