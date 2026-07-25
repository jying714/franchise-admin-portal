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

before_matches_on_disk (2026-07-24):
  Same three strategies, read-only — used by proposal_validator to
  HARD BAN proposals that would fail apply.

list_by_status (2026-07-24):
  Filter proposals by status (pending | applied | rejected | no_change)
  for /proposals pending and full dump of un-accepted work.

no_change status (2026-07-24):
  Exact phrase "No change needed" is a first-class success outcome.
  Saved with status=no_change so it is visible, countable, and not
  treated as ordinary pending work.

Multi-file apply (2026-07-25):
  Parse repeated FILE: path + BEFORE/AFTER pairs into Proposal.edits.
  apply_proposal applies each pair; reports per-file success/failure.
  Single-file proposals remain fully backward compatible.
"""

from __future__ import annotations

import json
import re
import uuid
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from difflib import SequenceMatcher
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

from file_reader import ALLOWED_ROOTS, _is_allowed


PROPOSALS_DIR_NAME = "orchestrator/proposals"
LAST_POINTER = "last_id.txt"

FUZZY_MIN_RATIO = 0.90
FUZZY_MIN_MARGIN = 0.05

# Exact escape-hatch phrase (case-insensitive).
NO_CHANGE_PATTERN = re.compile(
    r"^\s*no\s+change\s+needed\.?\s*$",
    re.IGNORECASE | re.MULTILINE,
)
NO_CHANGE_LOOSE = re.compile(
    r"\bno\s+change\s+needed\b",
    re.IGNORECASE,
)

PATH_RE = re.compile(
    r"((?:packages|mobile_app|web-app|functions|docs|tasks|orchestrator|prompts)"
    r"/[\w./\-]+\.(?:dart|ts|js|tsx|jsx|md|yaml|yml|json|txt|py))",
    re.IGNORECASE,
)

FILE_HEADER_RE = re.compile(
    r"(?:^|\n)\s*(?:FILE|File|file)\s*:\s*"
    r"((?:packages|mobile_app|web-app|functions|docs|tasks|orchestrator|prompts)"
    r"/[\w./\-]+\.(?:dart|ts|js|tsx|jsx|md|yaml|yml|json|txt|py))",
    re.IGNORECASE,
)


@dataclass
class FileEdit:
    file_path: str
    before: str
    after: str


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
    status: str = "pending"  # pending | approved | applied | rejected | no_change
    # Multi-file support (2026-07-25). Empty on legacy single-file JSON.
    edits: List[Dict[str, str]] = field(default_factory=list)

    def file_edits(self) -> List[FileEdit]:
        """Normalized list of edits (multi or single)."""
        out: List[FileEdit] = []
        for e in self.edits or []:
            fp = (e.get("file_path") or "").strip()
            b = e.get("before") or ""
            a = e.get("after") or ""
            if fp and b.strip() and a.strip():
                out.append(FileEdit(file_path=fp, before=b, after=a))
        if out:
            return out
        if self.file_path and self.before and self.after:
            return [
                FileEdit(
                    file_path=self.file_path,
                    before=self.before,
                    after=self.after,
                )
            ]
        return []


def is_no_change_needed(response: str) -> bool:
    """
    True when the agent correctly used the escape hatch.

    Accepts:
      - response that is essentially only "No change needed"
      - response that contains the phrase and has no usable differing BEFORE/AFTER
    """
    if not response or not response.strip():
        return False
    text = response.strip()
    if NO_CHANGE_PATTERN.search(text):
        return True
    if NO_CHANGE_LOOSE.search(text):
        edits = extract_file_edits(text, task="")
        if not edits:
            before, after = _extract_before_after(text)
            if not before and not after:
                return True
            if before and after and _normalize_for_compare(before) != _normalize_for_compare(after):
                return False
            return True
        # Multi-file with real diffs → not no_change
        for e in edits:
            if _normalize_for_compare(e.before) != _normalize_for_compare(e.after):
                return False
        return True
    return False


def _normalize_for_compare(text: str) -> str:
    t = text.strip()
    t = re.sub(r"^```[\w]*\n?", "", t)
    t = re.sub(r"\n?```$", "", t)
    t = re.sub(r"\s+", " ", t).strip()
    return t


def _proposals_dir(project_root: Path) -> Path:
    d = project_root / "orchestrator" / "proposals"
    d.mkdir(parents=True, exist_ok=True)
    return d


def _extract_file_path(task: str, response: str) -> Optional[str]:
    for text in (task, response):
        m = PATH_RE.search(text or "")
        if m:
            return m.group(1).replace("\\", "/")
    return None


def _extract_all_paths(task: str, response: str) -> List[str]:
    seen: set[str] = set()
    out: List[str] = []
    for text in (task, response):
        for m in PATH_RE.finditer(text or ""):
            p = m.group(1).replace("\\", "/")
            if p not in seen:
                seen.add(p)
                out.append(p)
    return out


def _extract_before_after(response: str) -> Tuple[Optional[str], Optional[str]]:
    before = _code_after_heading(
        response,
        [
            "before",
            "exact before",
            "before lines",
            "current",
            "before \\(parsed\\)",
        ],
    )
    after = _code_after_heading(
        response,
        [
            "after",
            "exact after",
            "after lines",
            "proposed",
            "after \\(parsed\\)",
        ],
    )
    return before, after


def _code_after_heading(text: str, headings: List[str]) -> Optional[str]:
    for h in headings:
        pat = (
            rf"(?:^|\n)#{{0,3}}\s*\d*\.?\s*{h}\b[^\n]*\n"
            rf"(?:[^`]*?)```(?:dart|swift|python|py|js|ts|yaml|yml|json|text)?\s*\n"
            rf"(.*?)```"
        )
        m = re.search(pat, text, re.IGNORECASE | re.DOTALL)
        if m:
            return m.group(1).strip("\n")

        pat2 = (
            rf"(?:^|\n)#{{0,3}}\s*\d*\.?\s*{h}\b[^\n]*\n"
            rf"(.*?)(?=\n#{{1,3}}\s|\n##\s|\n\s*FILE\s*:|\n\s*File\s*:|\Z)"
        )
        m2 = re.search(pat2, text, re.IGNORECASE | re.DOTALL)
        if m2:
            block = m2.group(1).strip()
            block = re.sub(r"^```\w*\s*\n|\n```\s*$", "", block).strip()
            if block and (
                "class " in block
                or "///" in block
                or "// " in block
                or "final " in block
                or "static " in block
                or "void " in block
                or "return " in block
                or "Icon(" in block
                or "Widget " in block
                or "appBar:" in block
                or "Text(" in block
                or "import " in block
                or "const " in block
            ):
                return block
    return None


def _section_before_after(section: str) -> Tuple[Optional[str], Optional[str]]:
    """Extract BEFORE/AFTER from a single FILE: segment."""
    return _extract_before_after(section)


def extract_file_edits(response: str, task: str = "") -> List[FileEdit]:
    """
    Parse multi-file or single-file BEFORE/AFTER pairs.

    Preferred multi-file shape:
      FILE: web-app/lib/foo.dart
      ## BEFORE
      ...
      ## AFTER
      ...
      FILE: web-app/lib/bar.dart
      ...

    Fallback: first path from task/response + first BEFORE/AFTER pair.
    """
    if not response or not response.strip():
        return []

    headers = list(FILE_HEADER_RE.finditer(response))
    edits: List[FileEdit] = []

    if len(headers) >= 1:
        for i, m in enumerate(headers):
            path = m.group(1).replace("\\", "/")
            start = m.end()
            end = headers[i + 1].start() if i + 1 < len(headers) else len(response)
            section = response[start:end]
            before, after = _section_before_after(section)
            if before and after and before.strip() and after.strip():
                if _normalize_for_compare(before) != _normalize_for_compare(after):
                    edits.append(FileEdit(file_path=path, before=before, after=after))
                else:
                    # Still record if task expects a change? Skip identical.
                    pass
        if edits:
            return edits
        # Headers present but no pairs — fall through

    # Single-pair fallback
    before, after = _extract_before_after(response)
    if not before or not after:
        return []
    if _normalize_for_compare(before) == _normalize_for_compare(after):
        return []

    paths = _extract_all_paths(task, response)
    path = paths[0] if paths else _extract_file_path(task, response)
    if not path:
        return []
    return [FileEdit(file_path=path, before=before, after=after)]


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

    file_edits = extract_file_edits(response, task=task)
    edits_payload = [
        {"file_path": e.file_path, "before": e.before, "after": e.after}
        for e in file_edits
    ]

    if file_edits:
        file_path = file_edits[0].file_path
        before = file_edits[0].before
        after = file_edits[0].after
    else:
        file_path = _extract_file_path(task, response)
        before, after = _extract_before_after(response)

    initial_status = "no_change" if is_no_change_needed(response) else "pending"

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
        status=initial_status,
        edits=edits_payload,
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
    # Legacy JSON may lack edits
    if "edits" not in data:
        data["edits"] = []
    return Proposal(**data)


def list_recent(project_root: Path, limit: int = 10) -> List[Proposal]:
    d = _proposals_dir(project_root)
    files = sorted(d.glob("*.json"), reverse=True)
    out: List[Proposal] = []
    for f in files[:limit]:
        try:
            data = json.loads(f.read_text(encoding="utf-8"))
            if "edits" not in data:
                data["edits"] = []
            out.append(Proposal(**data))
        except Exception:
            continue
    return out


def list_by_status(
    project_root: Path,
    status: str,
    limit: int = 50,
) -> List[Proposal]:
    """Return proposals matching the given status, newest first."""
    d = _proposals_dir(project_root)
    files = sorted(d.glob("*.json"), reverse=True)
    out: List[Proposal] = []
    status = status.strip().lower()
    for f in files:
        if len(out) >= limit:
            break
        try:
            data = json.loads(f.read_text(encoding="utf-8"))
            if "edits" not in data:
                data["edits"] = []
            p = Proposal(**data)
            if p.status == status:
                out.append(p)
        except Exception:
            continue
    return out


def mark_status(project_root: Path, prop: Proposal, status: str) -> Proposal:
    prop.status = status
    path = _proposals_dir(project_root) / f"{prop.id}.json"
    path.write_text(json.dumps(asdict(prop), indent=2), encoding="utf-8")
    return prop


def compute_metrics(project_root: Path, limit: int = 50) -> Dict[str, float | int | str]:
    """
    Lightweight training metrics over the most recent `limit` proposals.
    """
    items = list_recent(project_root, limit=limit)
    n = len(items)
    if n == 0:
        return {"total": 0, "note": "No proposals found"}

    no_change = sum(1 for p in items if p.status == "no_change")
    applied = sum(1 for p in items if p.status == "applied")
    rejected = sum(1 for p in items if p.status == "rejected")
    pending = sum(1 for p in items if p.status == "pending")

    hard_ban = 0
    real_diff = 0
    quote_signals = 0

    for p in items:
        if any(w.startswith("HARD BAN:") for w in (p.validation_warnings or [])):
            hard_ban += 1

        edits = p.file_edits()
        if edits:
            for e in edits:
                if _normalize_for_compare(e.before) != _normalize_for_compare(e.after):
                    real_diff += 1
                    break
        elif p.before and p.after:
            if _normalize_for_compare(p.before) != _normalize_for_compare(p.after):
                real_diff += 1

        resp = (p.response or "").lower()
        if (
            "quote the exact first" in resp
            or "first 10" in resp
            or "first 12" in resp
            or "first 8" in resp
            or re.search(r"^\s*1\.\s*quote", resp, re.M)
            or ("```" in resp and ("import " in resp or "class " in resp))
        ):
            quote_signals += 1

    def pct(count: int) -> float:
        return round(100.0 * count / n, 1)

    return {
        "total": n,
        "no_change": no_change,
        "no_change_pct": pct(no_change),
        "real_diff": real_diff,
        "real_diff_pct": pct(real_diff),
        "hard_ban": hard_ban,
        "hard_ban_pct": pct(hard_ban),
        "quote_signal": quote_signals,
        "quote_signal_pct": pct(quote_signals),
        "applied": applied,
        "applied_pct": pct(applied),
        "rejected": rejected,
        "rejected_pct": pct(rejected),
        "pending": pending,
        "pending_pct": pct(pending),
    }


def _leading_ws(line: str) -> str:
    return line[: len(line) - len(line.lstrip(" \t"))]


def _flexible_span(
    original: str, before: str
) -> Optional[Tuple[int, int, str]]:
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
    before_lines = [ln.rstrip("\r") for ln in before.strip("\n").splitlines()]
    while before_lines and before_lines[0].strip() == "":
        before_lines.pop(0)
    while before_lines and before_lines[-1].strip() == "":
        before_lines.pop()
    if not before_lines:
        return None

    before_norm = "\n".join(ln.strip() for ln in before_lines)
    n = len(before_lines)
    if n < 1:
        return None

    orig_lines = original.splitlines(keepends=True)
    if not orig_lines:
        return None

    window_sizes = sorted({max(1, n + d) for d in (-2, -1, 0, 1, 2, 3)})

    scored: List[Tuple[float, int, int]] = []

    for win in window_sizes:
        if win > len(orig_lines):
            continue
        for i in range(len(orig_lines) - win + 1):
            window_norm = "\n".join(
                ln.rstrip("\r\n").strip() for ln in orig_lines[i : i + win]
            )
            ratio = SequenceMatcher(None, before_norm, window_norm).ratio()
            if ratio >= FUZZY_MIN_RATIO - 0.02:
                scored.append((ratio, i, i + win))

    if not scored:
        return None

    scored.sort(key=lambda t: t[0], reverse=True)
    best_ratio, start_line, end_line = scored[0]

    if best_ratio < FUZZY_MIN_RATIO:
        return None

    second = 0.0
    for ratio, s, e in scored[1:]:
        if not (s < end_line and e > start_line):
            second = max(second, ratio)

    if second >= best_ratio - FUZZY_MIN_MARGIN and second >= FUZZY_MIN_RATIO:
        return None

    start_char = sum(len(orig_lines[k]) for k in range(start_line))
    end_char = sum(len(orig_lines[k]) for k in range(end_line))
    base_indent = _leading_ws(orig_lines[start_line].rstrip("\r\n"))
    return start_char, end_char, base_indent, best_ratio


def before_matches_on_disk(
    project_root: Path,
    file_path: str,
    before: str,
) -> Tuple[bool, str]:
    """
    Return (ok, detail) using the same match strategy as apply_proposal.
    ok=True means apply would find a unique span (exact, flexible, or fuzzy).
    """
    if not file_path or not before or not before.strip():
        return False, "missing file_path or before text"

    if not _is_allowed(file_path):
        return False, f"path not allowed: {file_path}"

    full = project_root / file_path
    if not full.exists():
        return False, f"file does not exist: {file_path}"

    try:
        original = full.read_text(encoding="utf-8")
    except Exception as e:
        return False, f"could not read {file_path}: {e}"

    b = before.strip("\n")
    if b in original:
        if original.count(b) > 1:
            return False, "BEFORE matches multiple places (ambiguous)"
        return True, "exact"

    if _flexible_span(original, b) is not None:
        return True, "indent-flexible"

    if _fuzzy_span(original, b) is not None:
        return True, "fuzzy"

    return False, "BEFORE not found (exact/flexible/fuzzy all failed)"


def _reindent_block(block: str, base_indent: str) -> str:
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
    if original[start_char:end_char].endswith("\n") and not reindented_after.endswith(
        "\n"
    ):
        reindented_after += "\n"
    return original[:start_char] + reindented_after + original[end_char:]


def _apply_one_edit(
    project_root: Path,
    edit: FileEdit,
) -> Tuple[bool, str]:
    """Apply a single FileEdit. Does not change proposal status."""
    if not _is_allowed(edit.file_path):
        return False, f"Path not allowed: {edit.file_path}"

    full = project_root / edit.file_path
    if not full.exists():
        return False, f"File does not exist: {edit.file_path}"

    original = full.read_text(encoding="utf-8")
    before = edit.before.strip("\n")
    after = edit.after.strip("\n")

    if before in original:
        if original.count(before) > 1:
            return (
                False,
                f"{edit.file_path}: BEFORE matches multiple places (ambiguous)",
            )
        updated = original.replace(before, after, 1)
        full.write_text(updated, encoding="utf-8")
        return True, f"Applied to {edit.file_path} (exact)"

    span = _flexible_span(original, before)
    if span is not None:
        start_char, end_char, base_indent = span
        updated = _write_span(original, start_char, end_char, after, base_indent)
        full.write_text(updated, encoding="utf-8")
        return True, f"Applied to {edit.file_path} (indent-flexible)"

    fuzzy = _fuzzy_span(original, before)
    if fuzzy is not None:
        start_char, end_char, base_indent, ratio = fuzzy
        updated = _write_span(original, start_char, end_char, after, base_indent)
        full.write_text(updated, encoding="utf-8")
        return True, f"Applied to {edit.file_path} (fuzzy ratio={ratio:.2f})"

    return (
        False,
        f"{edit.file_path}: BEFORE not found (exact/flexible/fuzzy failed)",
    )


def apply_proposal(project_root: Path, prop: Proposal) -> Tuple[bool, str]:
    if prop.status == "applied":
        return False, "Proposal already applied."

    if prop.status == "no_change":
        return False, "Proposal is 'No change needed' — nothing to apply."

    edits = prop.file_edits()
    if not edits:
        return (
            False,
            "Could not parse clear before/after code blocks from the proposal. "
            "Apply manually or re-run the task with fenced before/after blocks.",
        )

    successes: List[str] = []
    failures: List[str] = []

    for edit in edits:
        ok, msg = _apply_one_edit(project_root, edit)
        if ok:
            successes.append(msg)
        else:
            failures.append(msg)

    if successes and not failures:
        mark_status(project_root, prop, "applied")
        n = len(successes)
        detail = "; ".join(successes)
        return (
            True,
            f"Applied {n} file(s) (local only — not committed, not pushed). {detail}",
        )

    if successes and failures:
        # Partial: mark applied so we don't double-apply successes; report failures
        mark_status(project_root, prop, "applied")
        return (
            True,
            f"Partial apply ({len(successes)} ok, {len(failures)} failed). "
            f"OK: {'; '.join(successes)}. FAILED: {'; '.join(failures)}. "
            f"Finish remaining files manually.",
        )

    return False, "Apply failed: " + "; ".join(failures)
