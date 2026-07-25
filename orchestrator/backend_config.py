"""
backend_config.py
-----------------
Load orchestrator/config/backends.yaml and detect backend from task text.
"""

from __future__ import annotations

import os
import re
from pathlib import Path
from typing import Any, Dict, Optional

try:
    import yaml
except ImportError:  # pragma: no cover
    yaml = None  # type: ignore

BACKEND_LINE_RE = re.compile(
    r"(?:^|\n)\s*(?:#\s*)?backend\s*:\s*(xai|ollama)\b",
    re.IGNORECASE,
)

_DEFAULTS: Dict[str, Any] = {
    "xai": {
        "model": os.getenv("XAI_MODEL", "grok-4.5"),
        "base_url": os.getenv("XAI_BASE_URL", "https://api.x.ai/v1"),
        "temperature": 0.1,
        "max_context_chars": 120000,
    },
    "ollama": {
        "models": {
            "orchestrator": "qwen2.5-coder:7b",
            "backend": "qwen2.5-coder:14b",
            "web_frontend": "qwen2.5-coder:14b",
            "mobile_shared": "qwen2.5-coder:14b",
            "tester": "qwen2.5-coder:7b",
            "reviewer": "qwen2.5-coder:7b",
        }
    },
    "routing": {
        "default": "ollama",
        "prefer_xai_if_product_keywords": True,
        "product_keywords": [
            "markstepcomplete",
            "onboardingmenuitems",
            "strip action",
            "fix now",
            "hq shell",
            "publish",
            "multi-file",
            "dual-file",
        ],
    },
}


def load_backends_config(project_root: Path) -> Dict[str, Any]:
    path = project_root / "orchestrator" / "config" / "backends.yaml"
    if yaml is None or not path.is_file():
        return dict(_DEFAULTS)
    try:
        data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
        # shallow merge over defaults
        out = dict(_DEFAULTS)
        for k, v in data.items():
            if isinstance(v, dict) and isinstance(out.get(k), dict):
                merged = dict(out[k])
                merged.update(v)
                out[k] = merged
            else:
                out[k] = v
        return out
    except Exception:
        return dict(_DEFAULTS)


def detect_backend(task_text: str, config: Optional[Dict[str, Any]] = None) -> str:
    """
    Explicit `backend: xai` or `backend: ollama` (or # backend: in headers) wins.
    Else optional product-keyword prefer_xai, else routing.default.
    """
    m = BACKEND_LINE_RE.search(task_text)
    if m:
        return m.group(1).strip().lower()

    cfg = config or _DEFAULTS
    routing = cfg.get("routing") or {}
    default = str(routing.get("default") or "ollama").lower()
    if not routing.get("prefer_xai_if_product_keywords"):
        return default

    lower = task_text.lower()
    for kw in routing.get("product_keywords") or []:
        if str(kw).lower() in lower:
            return "xai"
    return default
