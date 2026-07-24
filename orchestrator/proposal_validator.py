"""
proposal_validator.py
---------------------
A3: lightweight post-generation checks for scope drift.

Path allowlist, BEFORE/AFTER required, no-op BEFORE≈AFTER, hard bans,
and (when project_root is provided) BEFORE-must-exist-on-disk.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Optional, Set


FORBIDDEN_FIELD_TASK_PATTERNS = [
    r"\bdo not add fields?\b",
    r"\bdon't add fields?\b",
    r"\bno new fields?\b",
    r"\bonly\b.*\bdocstring\b",
    r"\bdocstring only\b",
    r"\bonly\b.*\bcomment\b",
    r"\bdo not (add|change|touch).*(getter|method|logic|firestore|mapping)\b",
    r"\bwithout changing (any )?logic\b",
]

NEW_FIELD_PATTERNS = [
    r"\bfinal\s+(?:bool|String|int|double|List|Map|DateTime|dynamic)\??\s+\w+",
    r"\b(?:bool|String|int|double)\??\s+\w+\s*;",
]

NEW_METHOD_PATTERNS = [
    r"\b(?:void|Future|String|bool|int|dynamic)\s+\w+\s*\([^)]*\)\s*(?:async\s*)?\{",
    r"\bfactory\s+\w+",
    r"\bstatic\s+\w+\s+\w+\s*\(",
]

HARD_BAN_PATTERNS = [
    (r"FranchiseProvider\s*\(\s*\)", "FranchiseProvider() zero-arg constructor is forbidden"),
    (r"ChangeNotifierProvider\s*\(\s*create:\s*\(_\)\s*=>\s*FranchiseProvider",
     "Invented FranchiseProvider construction inside ChangeNotifierProvider is forbidden"),
    (r"FirestoreService\.collection\b", "FirestoreService.collection is not a real API — forbidden"),
    (r"\.collection\s*\(\s*['\"]franchises['\"]", "Do not invent franchise collection access in proposals"),
    (r"DesignTokens\.onPrimary\b", "DesignTokens.onPrimary does not exist — invented getter"),
    (r"DesignTokens\.onSecondary\b", "DesignTokens.onSecondary does not exist — invented getter"),
    (r"DesignTokens\.onSurface(?:Color)?\b",
     "DesignTokens.onSurface / onSurfaceColor does not exist — invented getter"),
    (r"DesignTokens\.on(?:Primary|Secondary|Surface|Background|Error)(?:Color)?\b",
     "Invented DesignTokens.on* color getter — use real tokens or Theme.of(context).colorScheme"),
    (r"primaryColor:\s*Colors\.blue\b", "Hard-coded Colors.blue theme placeholder is forbidden for live branding tasks"),
    (r"Color\(0xFF2196F3\)", "Hard-coded Material blue placeholder is forbidden for live branding tasks"),
]

PATH_PATTERN = re.compile(
    r"(?:^|[\s`\"'(])"
    r"((?:packages|mobile_app|web-app|functions|docs|tasks|orchestrator|prompts)"
    r"/[\w./\-]+\.(?:dart|ts|js|tsx|jsx|md|yaml|yml|json|txt|py))"
    r"(?=[\s`\"')\].,;:!?]|$)",
    re.IGNORECASE,
)

BEFORE_MARKER = re.compile(
    r"(?:^|\n)\s*(?:#+\s*)?(?:\d+\.?\s*)?(?:\*\*)?(?:exact\s+)?before(?:\*\*)?\b",
    re.IGNORECASE,
)
AFTER_MARKER = re.compile(
    r"(?:^|\n)\s*(?:#+\s*)?(?:\d+\.?\s*)?(?:\*\*)?(?:exact\s+)?after(?:\*\*)?\b",
    re.IGNORECASE,
)


@dataclass
class ValidationResult:
    ok: bool
    warnings: List[str] = field(default_factory=list)

    @property
    def has_warnings(self) -> bool:
        return len(self.warnings) > 0


def task_forbids_new_fields(task_text: str) -> bool:
    lower = task_text.lower()
    return any(re.search(p, lower, re.IGNORECASE) for p in FORBIDDEN_FIELD_TASK_PATTERNS)


def extract_paths(text: str) -> List[str]:
    found = PATH_PATTERN.findall(text)
    seen: Set[str] = set()
    unique: List[str] = []
    for p in found:
        norm = p.replace("\\", "/")
        if norm not in seen:
            seen.add(norm)
            unique.append(norm)
    return unique


def _count_matches(text: str, patterns: List[str]) -> int:
    n = 0
    for p in patterns:
        n += len(re.findall(p, text))
    return n


def _normalize_code(text: str) -> str:
    t = text.strip()
    t = re.sub(r"^```[\w]*\n?", "", t)
    t = re.sub(r"\n?```$", "", t)
    t = re.sub(r"\s+", " ", t).strip()
    return t


def _check_hard_bans(proposal_text: str) -> List[str]:
    hits: List[str] = []
    for pattern, message in HARD_BAN_PATTERNS:
        if re.search(pattern, proposal_text, re.IGNORECASE):
            hits.append(f"HARD BAN: {message}")
    return hits


def _check_path_allowlist(task_text: str, proposal_text: str) -> List[str]:
    allowed = set(extract_paths(task_text))
    if not allowed:
        return []

    proposed = extract_paths(proposal_text)
    if not proposed:
        return []

    violations = [p for p in proposed if p not in allowed]
    if not violations:
        return []

    allowed_str = ", ".join(sorted(allowed))
    bad_str = ", ".join(sorted(set(violations)))
    return [
        f"HARD BAN: path allowlist violation — proposal targets [{bad_str}] "
        f"but task only allowed [{allowed_str}]. Edit only the named file(s)."
    ]


def _check_before_after_required(task_text: str, proposal_text: str) -> List[str]:
    if not extract_paths(task_text):
        return []

    lower_task = task_text.lower()
    if re.search(r"\b(status only|planning only|no code change|read-?only)\b", lower_task):
        return []

    has_before = bool(BEFORE_MARKER.search(proposal_text))
    has_after = bool(AFTER_MARKER.search(proposal_text))

    before_body = _extract_section(proposal_text, ["before", "exact before", "current"])
    after_body = _extract_section(proposal_text, ["after", "exact after", "proposed"])
    if before_body.strip():
        has_before = True
    if after_body.strip():
        has_after = True

    if has_before and has_after:
        return []

    missing = []
    if not has_before:
        missing.append("BEFORE")
    if not has_after:
        missing.append("AFTER")
    return [
        f"HARD BAN: coding proposal missing {' and '.join(missing)} region(s). "
        f"Prose-only / essay responses are not valid. Provide surgical BEFORE and AFTER."
    ]


def _check_noop_before_after(task_text: str, proposal_text: str) -> List[str]:
    if not extract_paths(task_text):
        return []

    lower_task = task_text.lower()
    if re.search(r"\b(status only|planning only|no code change|read-?only)\b", lower_task):
        return []

    before_body = _extract_section(proposal_text, ["before", "exact before", "current"])
    after_body = _extract_section(proposal_text, ["after", "exact after", "proposed"])
    if not before_body.strip() or not after_body.strip():
        return []

    if _normalize_code(before_body) == _normalize_code(after_body):
        return [
            "HARD BAN: BEFORE and AFTER are identical (no-op proposal). "
            "Provide a real surgical change or FAILED TO LOAD."
        ]
    return []


def _check_before_on_disk(
    task_text: str,
    proposal_text: str,
    project_root: Optional[Path],
) -> List[str]:
    """HARD BAN if BEFORE cannot be located in the real target file."""
    if project_root is None:
        return []

    if not extract_paths(task_text):
        return []

    lower_task = task_text.lower()
    if re.search(r"\b(status only|planning only|no code change|read-?only)\b", lower_task):
        return []

    before_body = _extract_section(proposal_text, ["before", "exact before", "current"])
    if not before_body.strip():
        return []  # missing BEFORE handled elsewhere

    paths = extract_paths(task_text)
    if not paths:
        return []

    # Primary edit target = first path named in the task (matches Stage-C convention)
    file_path = paths[0]

    try:
        from proposal_store import before_matches_on_disk

        ok, detail = before_matches_on_disk(project_root, file_path, before_body)
    except Exception as e:
        return [f"HARD BAN: BEFORE on-disk check failed ({e})"]

    if ok:
        return []

    return [
        f"HARD BAN: BEFORE text not found in {file_path} ({detail}). "
        f"Proposal would fail apply — copy a contiguous region from the injected source."
    ]


def validate_proposal(
    task_text: str,
    proposal_text: str,
    project_root: Optional[Path] = None,
) -> ValidationResult:
    warnings: List[str] = []

    warnings.extend(_check_hard_bans(proposal_text))
    warnings.extend(_check_path_allowlist(task_text, proposal_text))
    warnings.extend(_check_before_after_required(task_text, proposal_text))
    warnings.extend(_check_noop_before_after(task_text, proposal_text))
    warnings.extend(_check_before_on_disk(task_text, proposal_text, project_root))

    if task_forbids_new_fields(task_text):
        after = _extract_section(proposal_text, ["after", "exact after", "proposed"])
        before = _extract_section(proposal_text, ["before", "exact before", "current"])

        target = after if after else proposal_text
        baseline = before if before else ""

        field_after = _count_matches(target, NEW_FIELD_PATTERNS)
        field_before = _count_matches(baseline, NEW_FIELD_PATTERNS) if baseline else 0

        if field_after > field_before:
            warnings.append(
                f"Possible new field(s) in proposal "
                f"(heuristic count after={field_after}, before={field_before}). "
                f"Task asked not to add fields."
            )

        method_after = _count_matches(target, NEW_METHOD_PATTERNS)
        method_before = _count_matches(baseline, NEW_METHOD_PATTERNS) if baseline else 0
        if method_after > method_before:
            warnings.append(
                f"Possible new method(s) in proposal "
                f"(after={method_after}, before={method_before}). "
                f"Task may have forbidden logic/API changes."
            )

        if re.search(r"\bonly\b.*\b(class[- ]level\s+)?docstring\b", task_text, re.I):
            doc_lines = len(re.findall(r"^\s*///", target, re.M))
            if doc_lines > 3:
                warnings.append(
                    f"Many doc-comment lines ({doc_lines}) for a class-level-docstring-only task — possible scope drift."
                )

    hard = [w for w in warnings if w.startswith("HARD BAN:")]
    ok = len(hard) == 0
    return ValidationResult(ok=ok, warnings=warnings)


def _extract_section(text: str, headings: List[str]) -> str:
    for h in headings:
        pattern = rf"(?:^|\n)#{{1,3}}\s*\d*\.?\s*{re.escape(h)}[^\n]*\n(.*?)(?=\n#{{1,3}}\s|\Z)"
        m = re.search(pattern, text, re.IGNORECASE | re.DOTALL)
        if m:
            return m.group(1)
        pattern2 = rf"(?:^|\n)\*?\*?{re.escape(h)}\*?\*?\s*:?\s*\n(.*?)(?=\n\*?\*?(?:before|after|next steps)|\Z)"
        m2 = re.search(pattern2, text, re.IGNORECASE | re.DOTALL)
        if m2:
            return m2.group(1)
    return ""
