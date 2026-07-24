"""
proposal_validator.py
---------------------
A3: lightweight post-generation checks for scope drift.

When the task clearly forbids new fields / logic, flag proposals that
look like they introduce new members anyway.

Also applies a hard ban list for recurring inventions (FranchiseProvider()
zero-arg, invented DesignTokens getters, FirestoreService.collection, etc.).

Path allowlist (2026-07-24):
  If the task names one or more project file paths, the proposal's edit
  target must be one of those paths. Any other path is a HARD BAN and
  sets ok=False so the caller can auto-reject.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import List, Set


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

# Hard ban list — recurring inventions that should never appear in proposals
# for Phase 1 Workstream B micro-tasks. On hit → ok=False (auto-reject by caller).
HARD_BAN_PATTERNS = [
    # Zero-arg or invented FranchiseProvider construction
    (r"FranchiseProvider\s*\(\s*\)", "FranchiseProvider() zero-arg constructor is forbidden"),
    (r"ChangeNotifierProvider\s*\(\s*create:\s*\(_\)\s*=>\s*FranchiseProvider",
     "Invented FranchiseProvider construction inside ChangeNotifierProvider is forbidden"),
    # Invented Firestore APIs
    (r"FirestoreService\.collection\b", "FirestoreService.collection is not a real API — forbidden"),
    (r"\.collection\s*\(\s*['\"]franchises['\"]", "Do not invent franchise collection access in proposals"),
    # Invented DesignTokens surface
    (r"DesignTokens\.onPrimary\b", "DesignTokens.onPrimary does not exist — invented getter"),
    (r"DesignTokens\.onSecondary\b", "DesignTokens.onSecondary does not exist — invented getter"),
    (r"DesignTokens\.onSurface(?:Color)?\b",
     "DesignTokens.onSurface / onSurfaceColor does not exist — invented getter"),
    (r"DesignTokens\.on(?:Primary|Secondary|Surface|Background|Error)(?:Color)?\b",
     "Invented DesignTokens.on* color getter — use real tokens or Theme.of(context).colorScheme"),
    # Hard-coded theme placeholders when live path is required
    (r"primaryColor:\s*Colors\.blue\b", "Hard-coded Colors.blue theme placeholder is forbidden for live branding tasks"),
    (r"Color\(0xFF2196F3\)", "Hard-coded Material blue placeholder is forbidden for live branding tasks"),
]

# Same family as file_reader.PATH_PATTERN — project-relative source paths
PATH_PATTERN = re.compile(
    r"(?:^|[\s`\"'(])"
    r"((?:packages|mobile_app|web-app|functions|docs|tasks|orchestrator|prompts)"
    r"/[\w./\-]+\.(?:dart|ts|js|tsx|jsx|md|yaml|yml|json|txt|py))"
    r"(?=[\s`\"')\].,;:!?]|$)",
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
    """Return unique project-relative paths found in text (order preserved)."""
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


def _check_hard_bans(proposal_text: str) -> List[str]:
    """Return warning messages for any hard-ban pattern hits."""
    hits: List[str] = []
    for pattern, message in HARD_BAN_PATTERNS:
        if re.search(pattern, proposal_text, re.IGNORECASE):
            hits.append(f"HARD BAN: {message}")
    return hits


def _check_path_allowlist(task_text: str, proposal_text: str) -> List[str]:
    """
    If the task names specific file paths, the proposal may only target
    those paths. Any other path mentioned as an edit target is a HARD BAN.

    Soft rule: if the task names no paths, skip (status/docs tasks).
    """
    allowed = set(extract_paths(task_text))
    if not allowed:
        return []

    # Paths that appear in the proposal (often in "FILE:" headers or code fences)
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


def validate_proposal(task_text: str, proposal_text: str) -> ValidationResult:
    """
    Return warnings when the proposal likely violates task constraints
    or hits a hard ban / path allowlist.

    ok=False means the caller SHOULD auto-reject (status=rejected, no apply).
    """
    warnings: List[str] = []

    # Always run hard bans (independent of task wording)
    warnings.extend(_check_hard_bans(proposal_text))

    # Path allowlist — only when the task named specific files
    warnings.extend(_check_path_allowlist(task_text, proposal_text))

    # Field/method heuristics only when the task forbids new surface
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

        # Docstring-only tasks: many /// on members can be scope drift
        if re.search(r"\bonly\b.*\b(class[- ]level\s+)?docstring\b", task_text, re.I):
            doc_lines = len(re.findall(r"^\s*///", target, re.M))
            if doc_lines > 3:
                warnings.append(
                    f"Many doc-comment lines ({doc_lines}) for a class-level-docstring-only task — possible scope drift."
                )

    # Any HARD BAN makes ok=False; soft heuristic warnings alone leave ok=True
    hard = [w for w in warnings if w.startswith("HARD BAN:")]
    ok = len(hard) == 0
    return ValidationResult(ok=ok, warnings=warnings)


def _extract_section(text: str, headings: List[str]) -> str:
    """Best-effort extract of a markdown section by heading keywords."""
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
