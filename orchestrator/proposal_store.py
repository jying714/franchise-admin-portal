"""
proposal_store.py
-----------------
Persist the latest agent proposal and support gated local apply.

Safety:
  - Apply is LOCAL FILE WRITE only (under PROJECT_ROOT)
  - Never git push / never remote
  - Requires explicit /approve confirm
  - Path must stay inside allowed roots (same as file_reader)
"""

from __future__ import annotations

import json
import re
import uuid
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Optional, Tuple

from file_reader import ALLOWED_ROOTS, _is_allowed


PROPOSALS_DIR_NAME = "orchestrator/proposals"
LAST_POINTER = "last_id.txt"


@dataclass
class Proposal:
    id: str
    created_at: str
    task: str
    agent: str
    model: str
    response: str
    file_path: Optional[str] = None
    before: Optional[str] = None
    after: Optional[str] = None
    validation_warnings: List[str] = field(default_factory=list)
    status: str = "pending"  # pending | approved | applied | rejected


def _proposals_dir(project_root: Path) -> Path:
    d = project_root / "orchestrator" / "proposals"
    d.mkdir(parents=True, exist_ok=True)
    return d


def _extract_file_path(task: str, response: str) -> Optional[str]:
    pattern = re.compile(
        r"((?:packages|mobile_app|web-app|functions|docs|tasks|orchestrator|prompts)"
        r"/[\w./\-]+\.(?:dart|ts|js|tsx|jsx|md|yaml|yml|json|txt|py))",
        re.IGNORECASE,
    )
    for text in (task, response):
        m = pattern.search(text)
        if m:
            return m.group(1).replace("\\", "/")
    return None


def _extract_before_after(response: str) -> Tuple[Optional[str], Optional[str]]:
    """Pull code from fenced blocks under before/after headings when possible."""
    before = _code_after_heading(
        response,
        [
            "before",
            "exact before",
            "before lines",
            "current",
            "before \(parsed\)",
        ],
    )
    after = _code_after_heading(
        response,
        [
            "after",
            "exact after",
            "after lines",
            "proposed",
            "after \(parsed\)",
        ],
    )
    return before, after


def _code_after_heading(text: str, headings: List[str]) -> Optional[str]:
    """
    Find a fenced code block that follows a before/after-style heading.

    Accepts:
      ## BEFORE
      ### Before Lines
      BEFORE
      Before Lines (Class-level docstring):
    followed by ```dart ... ``` or ``` ... ```.
    """
    for h in headings:
        # Preferred: markdown heading then fenced block
        pat = (
            rf"(?:^|\n)#{{0,3}}\s*\d*\.?\s*{h}\b[^\n]*\n"
            rf"(?:[^`]*?)```(?:dart|swift|python|py|js|ts|yaml|yml|json|text)?\s*\n"
            rf"(.*?)```"
        )
        m = re.search(pat, text, re.IGNORECASE | re.DOTALL)
        if m:
            return m.group(1).strip("\n")

        # Fallback: heading then indented/plain lines until next heading or fence end
        pat2 = (
            rf"(?:^|\n)#{{0,3}}\s*\d*\.?\s*{h}\b[^\n]*\n"
            rf"(.*?)(?=\n#{{1,3}}\s|\n##\s|\Z)"
        )
        m2 = re.search(pat2, text, re.IGNORECASE | re.DOTALL)
        if m2:
            block = m2.group(1).strip()
            block = re.sub(r"^```\w*\s*\n|\n```\s*$", "", block).strip()
            # Only accept if it looks like code/docstring, not pure prose
            if block and (
                "class " in block
                or "///" in block
                or "// " in block
                or "final " in block
                or "static " in block
                or "void " in block
                or "return " in block
            ):
                return block
    return None


def save_proposal(
    project_root: Path,
    *,
    task: str,
    agent: str,
    model: str,
    response: str,
    validation_warnings: Optional[List[str]] = None,
) -> Proposal:
    pid = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-" + uuid.uuid4().hex[:8]
    file_path = _extract_file_path(task, response)
    before, after = _extract_before_after(response)

    prop = Proposal(
        id=pid,
        created_at=datetime.now(timezone.utc).isoformat(),
        task=task,
        agent=agent,
        model=model,
        response=response,
        file_path=file_path,
        before=before,
        after=after,
        validation_warnings=list(validation_warnings or []),
        status="pending",
    )

    d = _proposals_dir(project_root)
    path = d / f"{pid}.json"
    path.write_text(json.dumps(asdict(prop), indent=2), encoding="utf-8")
    (d / LAST_POINTER).write_text(pid, encoding="utf-8")
    return prop


def load_last(project_root: Path) -> Optional[Proposal]:
    d = _proposals_dir(project_root)
    pointer = d / LAST_POINTER
    if not pointer.exists():
        return None
    pid = pointer.read_text(encoding="utf-8").strip()
    return load_by_id(project_root, pid)


def load_by_id(project_root: Path, pid: str) -> Optional[Proposal]:
    path = _proposals_dir(project_root) / f"{pid}.json"
    if not path.exists():
        return None
    data = json.loads(path.read_text(encoding="utf-8"))
    return Proposal(**data)


def list_recent(project_root: Path, limit: int = 10) -> List[Proposal]:
    d = _proposals_dir(project_root)
    files = sorted(d.glob("*.json"), reverse=True)
    out: List[Proposal] = []
    for f in files[:limit]:
        try:
            out.append(Proposal(**json.loads(f.read_text(encoding="utf-8"))))
        except Exception:
            continue
    return out


def mark_status(project_root: Path, prop: Proposal, status: str) -> Proposal:
    prop.status = status
    path = _proposals_dir(project_root) / f"{prop.id}.json"
    path.write_text(json.dumps(asdict(prop), indent=2), encoding="utf-8")
    return prop


def apply_proposal(project_root: Path, prop: Proposal) -> Tuple[bool, str]:
    """
    Apply before→after replacement in the target file.
    Returns (success, message).
    Does NOT git commit or push.
    """
    if prop.status == "applied":
        return False, "Proposal already applied."

    if not prop.file_path:
        return False, "No file path detected in proposal — cannot apply automatically."

    if not _is_allowed(prop.file_path):
        return False, f"Path not allowed: {prop.file_path}"

    if not prop.before or not prop.after:
        return (
            False,
            "Could not parse clear before/after code blocks from the proposal. "
            "Apply manually or re-run the task with fenced before/after blocks.",
        )

    full = project_root / prop.file_path
    if not full.exists():
        return False, f"File does not exist: {prop.file_path}"

    original = full.read_text(encoding="utf-8")
    before = prop.before.strip("\n")
    after = prop.after.strip("\n")

    if before not in original:
        return (
            False,
            "BEFORE text not found exactly in the file. "
            "Refusing apply to avoid corrupting source. Apply manually.",
        )

    if original.count(before) > 1:
        return (
            False,
            "BEFORE text matches multiple places in the file. "
            "Refusing apply to avoid ambiguous edits.",
        )

    updated = original.replace(before, after, 1)
    full.write_text(updated, encoding="utf-8")
    mark_status(project_root, prop, "applied")
    return True, f"Applied to {prop.file_path} (local only — not committed, not pushed)."
