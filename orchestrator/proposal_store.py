"""
proposal_store.py
-----------------
Persist the latest agent proposal and support gated local apply.

Safety:
  - Apply is LOCAL FILE WRITE only (under PROJECT_ROOT)
  - Never git push / never remote
  - Requires explicit /approve confirm
  - Path must stay inside allowed roots (same as file_reader)

Match strategy for BEFORE → AFTER:
  1. Exact substring
  2. Indent-flexible (line sequence equal after lstrip)
  3. Fuzzy difflib window (high threshold, unique winner)
"""

from __future__ import annotations

import json
import re
import uuid
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from difflib import SequenceMatcher
from pathlib import Path
from typing import List, Optional, Tuple

from file_reader import ALLOWED_ROOTS, _is_allowed


PROPOSALS_DIR_NAME = "orchestrator/proposals"
LAST_POINTER = "last_id.txt"

# Fuzzy match: require very high similarity and a clear margin over runner-up
FUZZY_MIN_RATIO = 0.90
FUZZY_MIN_MARGIN = 0.05


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


def _leading_ws(line: str) -> str:
    return line[: len(line) - len(line.lstrip(" \t"))]


def _flexible_span(
    original: str, before: str
) -> Optional[Tuple[int, int, str]]:
    """
    Find a unique span in `original` whose lines match `before` after lstrip().

    Returns (start_char, end_char, base_indent) or None if not found uniquely.
    """
    before_lines = [ln.rstrip("\r") for ln in before.strip("\n").splitlines()]
    while before_lines and before_lines[0].strip() == "":
        before_lines.pop(0)
    while before_lines and before_lines[-1].strip() == "":
        before_lines.pop()
    if not before_lines:
        return None

    before_stripped = [ln.strip() for ln in before_lines]
    orig_lines = original.splitlines(keepends=True)
    orig_stripped = [ln.rstrip("\r\n").strip() for ln in orig_lines]

    matches: List[Tuple[int, int]] = []
    n = len(before_stripped)
    for i in range(len(orig_stripped) - n + 1):
        if orig_stripped[i : i + n] == before_stripped:
            matches.append((i, i + n))

    if len(matches) != 1:
        return None

    start_line, end_line = matches[0]
    start_char = sum(len(orig_lines[k]) for k in range(start_line))
    end_char = sum(len(orig_lines[k]) for k in range(end_line))
    base_indent = _leading_ws(orig_lines[start_line].rstrip("\r\n"))
    return start_char, end_char, base_indent


def _fuzzy_span(
    original: str, before: str
) -> Optional[Tuple[int, int, str, float]]:
    """
    Find a unique high-similarity window in `original` for `before`.

    Compares stripped line sequences with difflib.SequenceMatcher over
    sliding windows sized around the BEFORE line count. Requires ratio
    >= FUZZY_MIN_RATIO and a clear margin over the second-best hit.

    Returns (start_char, end_char, base_indent, ratio) or None.
    """
    before_lines = [ln.rstrip("\r") for ln in before.strip("\n").splitlines()]
    while before_lines and before_lines[0].strip() == "":
        before_lines.pop(0)
    while before_lines and before_lines[-1].strip() == "":
        before_lines.pop()
    if not before_lines:
        return None

    before_stripped = [ln.strip() for ln in before_lines if ln.strip() != "" or True]
    # Keep structure but normalize for comparison
    before_norm = "\n".join(ln.strip() for ln in before_lines)
    n = len(before_lines)
    if n < 1:
        return None

    orig_lines = original.splitlines(keepends=True)
    if not orig_lines:
        return None

    # Window sizes: exact n, and ±1/±2 for collapsed/expanded line breaks
    window_sizes = sorted({max(1, n + d) for d in (-2, -1, 0, 1, 2, 3)})

    scored: List[Tuple[float, int, int]] = []  # (ratio, start_line, end_line)

    for win in window_sizes:
        if win > len(orig_lines):
            continue
        for i in range(len(orig_lines) - win + 1):
            window_text = "".join(orig_lines[i : i + win])
            window_norm = "\n".join(
                ln.rstrip("\r\n").strip() for ln in orig_lines[i : i + win]
            )
            ratio = SequenceMatcher(None, before_norm, window_norm).ratio()
            if ratio >= FUZZY_MIN_RATIO - 0.02:  # collect near-misses for margin check
                scored.append((ratio, i, i + win))

    if not scored:
        return None

    scored.sort(key=lambda t: t[0], reverse=True)
    best_ratio, start_line, end_line = scored[0]

    if best_ratio < FUZZY_MIN_RATIO:
        return None

    # Unique winner: runner-up must be clearly worse (or non-overlapping same region)
    second = 0.0
    for ratio, s, e in scored[1:]:
        # Ignore overlapping windows of the same region
        if not (s < end_line and e > start_line):
            second = max(second, ratio)

    if second >= best_ratio - FUZZY_MIN_MARGIN and second >= FUZZY_MIN_RATIO:
        return None  # ambiguous

    start_char = sum(len(orig_lines[k]) for k in range(start_line))
    end_char = sum(len(orig_lines[k]) for k in range(end_line))
    base_indent = _leading_ws(orig_lines[start_line].rstrip("\r\n"))
    return start_char, end_char, base_indent, best_ratio


def _reindent_block(block: str, base_indent: str) -> str:
    """
    Re-indent `block` so its first non-empty line uses `base_indent`, and
    relative indentation between lines is preserved.
    """
    lines = block.strip("\n").splitlines()
    if not lines:
        return block

    non_empty = [ln for ln in lines if ln.strip()]
    if not non_empty:
        return block
    min_pad = min(len(_leading_ws(ln)) for ln in non_empty)

    out: List[str] = []
    for ln in lines:
        if not ln.strip():
            out.append("")
            continue
        pad = _leading_ws(ln)
        rel = pad[min_pad:] if len(pad) >= min_pad else ""
        content = ln.lstrip(" \t")
        out.append(base_indent + rel + content)
    return "\n".join(out)


def _write_span(
    original: str,
    start_char: int,
    end_char: int,
    after: str,
    base_indent: str,
) -> str:
    reindented_after = _reindent_block(after, base_indent)
    # Preserve trailing newline if the replaced span had one
    if original[start_char:end_char].endswith("\n") and not reindented_after.endswith(
        "\n"
    ):
        reindented_after += "\n"
    return original[:start_char] + reindented_after + original[end_char:]


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

    # 1) Exact match (preferred)
    if before in original:
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

    # 2) Flexible indent match: line sequence equal after lstrip()
    span = _flexible_span(original, before)
    if span is not None:
        start_char, end_char, base_indent = span
        updated = _write_span(original, start_char, end_char, after, base_indent)
        full.write_text(updated, encoding="utf-8")
        mark_status(project_root, prop, "applied")
        return (
            True,
            f"Applied to {prop.file_path} via indent-flexible match "
            f"(local only — not committed, not pushed).",
        )

    # 3) Fuzzy match: model slightly rewrote BEFORE / collapsed lines
    fuzzy = _fuzzy_span(original, before)
    if fuzzy is not None:
        start_char, end_char, base_indent, ratio = fuzzy
        updated = _write_span(original, start_char, end_char, after, base_indent)
        full.write_text(updated, encoding="utf-8")
        mark_status(project_root, prop, "applied")
        return (
            True,
            f"Applied to {prop.file_path} via fuzzy match (ratio={ratio:.2f}) "
            f"(local only — not committed, not pushed).",
        )

    return (
        False,
        "BEFORE text not found in the file (exact, indent-flexible, and fuzzy match failed). "
        "Refusing apply to avoid corrupting source. Apply manually.",
    )
