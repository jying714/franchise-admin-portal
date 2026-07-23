"""
proposal_validator.py
---------------------
A3: lightweight post-generation checks for scope drift.

When the task clearly forbids new fields / logic, flag proposals that
look like they introduce new members anyway.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import List


# Task language that means "docs only / no new API surface"
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

# Heuristics in the proposal body
NEW_FIELD_PATTERNS = [
    r"\bfinal\s+(?:bool|String|int|double|List|Map|DateTime|dynamic)\??\s+\w+",
    r"\b(?:bool|String|int|double)\??\s+\w+\s*;",  # non-final fields
]

NEW_METHOD_PATTERNS = [
    r"\b(?:void|Future|String|bool|int|dynamic)\s+\w+\s*\([^)]*\)\s*(?:async\s*)?\{",
    r"\bfactory\s+\w+",
    r"\bstatic\s+\w+\s+\w+\s*\(",
]


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


def _count_matches(text: str, patterns: List[str]) -> int:
    n = 0
    for p in patterns:
        n += len(re.findall(p, text))
    return n

def validate_proposal(task_text: str, proposal_text: str) -> ValidationResult:
    """
    Return warnings when the proposal likely violates task constraints.
    Does not block display — only flags for the human.
    """
    warnings: List[str] = []

    if not task_forbids_new_fields(task_text):
        return ValidationResult(ok=True, warnings=warnings)

    # Prefer comparing AFTER vs BEFORE sections when present
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

    # Docstring-only tasks: many /// on members can be scope drift
    if re.search(r"\bonly\b.*\b(class[- ]level\s+)?docstring\b", task_text, re.I):
        doc_lines = len(re.findall(r"^\s*///", target, re.M))
        if doc_lines > 3:
            warnings.append(
                f"Many doc-comment lines ({doc_lines}) for a class-level-docstring-only task — possible scope drift."
            )

    return ValidationResult(ok=len(warnings) == 0, warnings=warnings)


def _extract_section(text: str, headings: List[str]) -> str:
    """Best-effort extract of a markdown section by heading keywords."""
    lower = text.lower()
    for h in headings:
        # match ### 2. Exact after  or **After** etc.
        pattern = rf"(?:^|\n)#{{1,3}}\s*\d*\.?\s*{re.escape(h)}[^\n]*\n(.*?)(?=\n#{{1,3}}\s|\Z)"
        m = re.search(pattern, text, re.IGNORECASE | re.DOTALL)
        if m:
            return m.group(1)
        # fallback: line starting with After:
        pattern2 = rf"(?:^|\n)\*?\*?{re.escape(h)}\*?\*?\s*:?\s*\n(.*?)(?=\n\*?\*?(?:before|after|next steps)|\Z)"
        m2 = re.search(pattern2, text, re.IGNORECASE | re.DOTALL)
        if m2:
            return m2.group(1)
    return ""
