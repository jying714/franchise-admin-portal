"""
agent_router.py
---------------
Decides which specialized agent should handle a task and
builds the final prompt that is sent to Ollama.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Optional

from context_loader import build_system_prompt, load_mandatory_context


# Simple keyword-based routing (good enough for Phase 0)
# Later we can replace this with a small LLM classification step.
ROUTING_RULES = [
    (r"\b(firestore|schema|config|provider|shared_core|backend|stripe|webhook|security.?rule)\b", "backend"),
    (r"\b(web.?app|dashboard|hq.?owner|design.?branding|flutter.?web|ui.?component)\b", "web_frontend"),
    (r"\b(mobile|android|ios|dynamic.?ui|restaurant.?type|offline|shared.?core)\b", "mobile_shared"),
    (r"\b(test|qa|analyze|regression|device)\b", "tester"),
    (r"\b(review|architecture|pr|quality|docs?)\b", "reviewer"),
]


@dataclass
class TaskResult:
    agent: str
    model: str
    system_prompt: str
    user_prompt: str
    requires_human_approval: bool
    reason: str


def detect_agent(task_text: str) -> str:
    """Return the best agent name for the given task description."""
    lower = task_text.lower()
    for pattern, agent in ROUTING_RULES:
        if re.search(pattern, lower, re.IGNORECASE):
            return agent
    # Default: orchestrator itself (planning / clarification)
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
      1. Load mandatory context (once per process is enough, but safe to re-call)
      2. Choose agent
      3. Build system prompt
      4. Decide human-approval flag
    """
    mandatory = load_mandatory_context(project_root)

    agent = preferred_agent or detect_agent(task_text)
    system = build_system_prompt(project_root, agent, mandatory)

    requires_approval, reason = needs_human_approval(task_text, agent)

    # Default model mapping (can be overridden by env or config)
    default_models = {
        "orchestrator": "qwen2.5-coder:7b",      # light & always loaded
        "backend": "qwen2.5-coder:14b",
        "web_frontend": "qwen2.5-coder:14b",
        "mobile_shared": "qwen2.5-coder:14b",
        "tester": "qwen2.5-coder:7b",
        "reviewer": "qwen2.5-coder:7b",
    }
    models = model_map or default_models
    model = models.get(agent, "qwen2.5-coder:14b")

    user_prompt = f"""## TASK
{task_text}

## INSTRUCTIONS
- Stay strictly inside the current phase (Phase 0 right now).
- Propose concrete, small, reviewable changes only.
- Never invent file paths that do not exist.
- If the task is out of scope, say so clearly and stop.
- End your response with a short "Next steps for human" section.
"""

    return TaskResult(
        agent=agent,
        model=model,
        system_prompt=system,
        user_prompt=user_prompt,
        requires_human_approval=requires_approval,
        reason=reason,
    )
