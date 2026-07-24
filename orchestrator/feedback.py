"""
feedback.py
-----------
Append-only learning signals from human approve / reject.

Does NOT fine-tune models. Humans (or a later script) read rejects.jsonl
to update SCOPE_CARD.md / hard bans / task templates.
"""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Optional


def _feedback_dir(project_root: Path) -> Path:
    d = project_root / "orchestrator" / "feedback"
    d.mkdir(parents=True, exist_ok=True)
    return d


def append_feedback(
    project_root: Path,
    *,
    kind: str,
    proposal_id: str,
    reason: str = "",
    extra: Optional[dict[str, Any]] = None,
) -> Path:
    """
    Append one JSON line to rejects.jsonl or approves.jsonl.

    kind: "reject" | "approve" | "apply"
    """
    d = _feedback_dir(project_root)
    if kind == "reject":
        path = d / "rejects.jsonl"
    elif kind in ("approve", "apply"):
        path = d / "approves.jsonl"
    else:
        path = d / f"{kind}.jsonl"

    record = {
        "ts": datetime.now(timezone.utc).isoformat(),
        "kind": kind,
        "proposal_id": proposal_id,
        "reason": reason or "",
    }
    if extra:
        record.update(extra)

    with path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(record, ensure_ascii=False) + "\n")
    return path
