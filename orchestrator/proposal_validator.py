"""
proposal_validator.py
---------------------
A3: lightweight post-generation checks for scope drift.

Path allowlist (2026-07-25 fix):
  Only FILE: headers in the proposal are edit targets.
  Paths that appear only inside quoted source / comments (e.g. docs/slices/*.md)
  are NOT treated as proposed edit targets — that was causing false HARD BANs
  on branding tasks that quoted the class dartdoc.

Empty-file (2026-07-25):
  When the task allows full-file AFTER only (empty/near-empty source),
  missing BEFORE is not a HARD BAN.

"No change needed" escape hatch skips structural checks.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Optional, Set, Tuple


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

HARD_BAN_PATTERNS: List[Tuple[str, str, bool]] = [
    (r"FranchiseProvider\s*\(\s*\)", "FranchiseProvider() zero-arg constructor is forbidden", True),
    (r"ChangeNotifierProvider\s*\(\s*create:\s*\(_\)\s*=>\s*FranchiseProvider",
     "Invented FranchiseProvider construction inside ChangeNotifierProvider is forbidden", True),
    (r"FirestoreService\.collection\b", "FirestoreService.collection is not a real API — forbidden", True),
    (r"\.collection\s*\(\s*['\"]franchises['\"]",
     "Do not invent franchise collection access in proposals", True),
    (r"FranchiseProvider\.(currentPrimaryColorHex|currentSecondaryColorHex|currentAppName|currentLogoUrl)\b",
     "Static FranchiseProvider.current* access is forbidden — use instance from Provider.of / franchiseProvider", True),
    (r"DesignTokens\.onPrimary\b", "DesignTokens.onPrimary does not exist — invented getter", True),
    (r"DesignTokens\.onSecondary\b", "DesignTokens.onSecondary does not exist — invented getter", True),
    (r"DesignTokens\.onSurface(?:Color)?\b",
     "DesignTokens.onSurface / onSurfaceColor does not exist — invented getter", True),
    (r"DesignTokens\.on(?:Primary|Secondary|Surface|Background|Error)(?:Color)?\b",
     "Invented DesignTokens.on* color getter — use real tokens or Theme.of(context).colorScheme", True),
    (r"DesignTokens\.currentPrimaryColor\b",
     "DesignTokens.currentPrimaryColor does not exist — use DesignTokens.primaryColor (Color getter)", True),
    (r"DesignTokens\.currentSecondaryColor\b",
     "DesignTokens.currentSecondaryColor does not exist — use DesignTokens.secondaryColor (Color getter)", True),
    (r"DesignTokens\.current(?:Primary|Secondary|Accent|Error|Warning)Color\b",
     "Invented DesignTokens.current*Color — real Color getters are primaryColor / secondaryColor / errorColor (no current* prefix)", True),
    (r"UiConfig\.currentPrimaryColor\b",
     "UiConfig.currentPrimaryColor does not exist — use UiConfig.primaryColor", True),
    (r"UiConfig\.currentSecondaryColor\b",
     "UiConfig.currentSecondaryColor does not exist — use UiConfig.secondaryColor", True),
    (r"primaryColor:\s*Colors\.blue\b",
     "Hard-coded Colors.blue theme placeholder is forbidden for live branding tasks", False),
    (r"Color\(0xFF2196F3\)",
     "Hard-coded Material blue placeholder is forbidden for live branding tasks", False),
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

NO_CHANGE_RE = re.compile(r"\bno\s+change\s+needed\b", re.IGNORECASE)

FILE_LINE_RE = re.compile(
    r"(?:^|\n)\s*FILE\s*:\s*(\S+)",
    re.IGNORECASE,
)

FENCED_AFTER_RE = re.compile(
    r"(?:^|\n)\s*(?:#+\s*)?(?:\d+\.?\s*)?(?:\*\*)?(?:exact\s+)?after(?:\*\*)?[^\n]*\n"
    r"\s*```(?:dart|ts|js)?\s*\n(.*?)\n\s*```",
    re.IGNORECASE | re.DOTALL,
)

EMPTY_FILE_TASK_RE = re.compile(
    r"\b(empty[- ]file|near-empty|full-file\s+after|file may be empty|"
    r"no empty before|emit full-file after|bom-only)\b",
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


def extract_file_header_paths(proposal_text: str) -> List[str]:
    """Paths that appear on FILE: lines — the only declared edit targets."""
    seen: Set[str] = set()
    out: List[str] = []
    for m in FILE_LINE_RE.finditer(proposal_text or ""):
        p = m.group(1).replace("\\", "/").rstrip("`)'\"")
        if p and p not in seen:
            seen.add(p)
            out.append(p)
    return out


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


def _strip_dart_comments(text: str) -> str:
    out_lines: List[str] = []
    for line in text.splitlines():
        stripped = line.lstrip()
        if stripped.startswith("///") or stripped.startswith("//"):
            continue
        if "//" in line:
            code, _, _ = line.partition("//")
            out_lines.append(code)
        else:
            out_lines.append(line)
    return "\n".join(out_lines)


def _is_no_change_response(proposal_text: str) -> bool:
    if not proposal_text:
        return False
    if not NO_CHANGE_RE.search(proposal_text):
        return False
    before = _extract_section(proposal_text, ["before", "exact before", "current"])
    after = _extract_section(proposal_text, ["after", "exact after", "proposed"])
    if before.strip() and after.strip() and _normalize_code(before) != _normalize_code(after):
        return False
    return True


def _task_allows_empty_file_after_only(task_text: str) -> bool:
    return bool(EMPTY_FILE_TASK_RE.search(task_text or ""))


def _check_hard_bans(proposal_text: str) -> List[str]:
    if _is_no_change_response(proposal_text):
        return []

    before = _extract_section(proposal_text, ["before", "exact before", "current"])
    after = _extract_section(proposal_text, ["after", "exact after", "proposed"])
    has_fences = bool(before.strip() and after.strip())

    target_raw = after if has_fences else proposal_text
    baseline_raw = before if has_fences else ""

    target = _strip_dart_comments(target_raw)
    baseline = _strip_dart_comments(baseline_raw) if baseline_raw else ""

    hits: List[str] = []
    for pattern, message, net_new_only in HARD_BAN_PATTERNS:
        if not re.search(pattern, target, re.IGNORECASE):
            continue
        if net_new_only and baseline and re.search(pattern, baseline, re.IGNORECASE):
            continue
        hits.append(f"HARD BAN: {message}")
    return hits


def _check_path_allowlist(task_text: str, proposal_text: str) -> List[str]:
    """
    Compare task-named paths to proposal FILE: targets only.

    Do NOT scan the whole proposal for paths — quoted source often mentions
    docs/*.md or other files that are not edit targets.
    """
    if _is_no_change_response(proposal_text):
        return []

    allowed = set(extract_paths(task_text))
    if not allowed:
        # No path-like tokens in task → cannot enforce allowlist
        return []

    proposed = extract_file_header_paths(proposal_text)
    if not proposed:
        # No FILE: header — cannot claim a path violation from prose alone
        return []

    violations = [p for p in proposed if p not in allowed]
    if not violations:
        return []

    # Soften: if proposal FILE path is a suffix/normalization of an allowed path
    still_bad: List[str] = []
    for p in violations:
        if any(p == a or p.endswith("/" + a.split("/")[-1]) or a.endswith(p) for a in allowed):
            continue
        still_bad.append(p)
    if not still_bad:
        return []

    allowed_str = ", ".join(sorted(allowed))
    bad_str = ", ".join(sorted(set(still_bad)))
    return [
        f"HARD BAN: path allowlist violation — proposal FILE targets [{bad_str}] "
        f"but task only allowed [{allowed_str}]. Edit only the named file(s)."
    ]


def _check_before_after_required(task_text: str, proposal_text: str) -> List[str]:
    if not extract_paths(task_text):
        return []

    if _is_no_change_response(proposal_text):
        return []

    lower_task = task_text.lower()
    if re.search(r"\b(status only|planning only|no code change|read-?only)\b", lower_task):
        return []

    # Empty-file full replace: AFTER required, BEFORE optional
    if _task_allows_empty_file_after_only(task_text):
        after_body = _extract_section(proposal_text, ["after", "exact after", "proposed"])
        has_after = bool(after_body.strip()) or bool(AFTER_MARKER.search(proposal_text))
        if has_after:
            return []
        return [
            "HARD BAN: empty-file task requires a full-file AFTER region "
            "(or reply only: No change needed)."
        ]

    has_before = bool(BEFORE_MARKER.search(proposal_text))
    has_after = bool(AFTER_MARKER.search(proposal_text))

    before_body = _extract_section(proposal_text, ["before", "exact before", "current"])
    after_body = _extract_section(proposal_text, ["after", "exact after", "proposed"])
    if before_body.strip():
        has_before = True
    if after_body.strip():
        has_after = True

    if has_before and (has_after or AFTER_MARKER.search(proposal_text)):
        return []

    if has_before and has_after:
        return []

    missing = []
    if not has_before:
        missing.append("BEFORE")
    if not has_after and not AFTER_MARKER.search(proposal_text):
        missing.append("AFTER")
    if not missing:
        return []
    return [
        f"HARD BAN: coding proposal missing {' and '.join(missing)} region(s). "
        f"Prose-only / essay responses are not valid. Provide surgical BEFORE and AFTER "
        f"or reply only: No change needed."
    ]


def _check_noop_before_after(task_text: str, proposal_text: str) -> List[str]:
    if not extract_paths(task_text):
        return []

    if _is_no_change_response(proposal_text):
        return []

    lower_task = task_text.lower()
    if re.search(r"\b(status only|planning only|no code change|read-?only)\b", lower_task):
        return []

    before_body = _extract_section(proposal_text, ["before", "exact before", "current"])
    after_body = _extract_section(proposal_text, ["after", "exact after", "proposed"])
    if not before_body.strip():
        return []
    if not after_body.strip():
        return []

    if _normalize_code(before_body) == _normalize_code(after_body):
        return [
            "HARD BAN: BEFORE and AFTER are identical (no-op proposal). "
            "Provide a real surgical change or reply only: No change needed."
        ]
    return []


def _check_brace_only_after(proposal_text: str) -> List[str]:
    if _is_no_change_response(proposal_text):
        return []

    hits: List[str] = []
    for m in FENCED_AFTER_RE.finditer(proposal_text):
        body = m.group(1).strip()
        if re.fullmatch(r"[}\]\);]+", body):
            hits.append(
                "HARD BAN: AFTER region is brace/paren-only (e.g. only `}`). "
                "For method deletes use an **empty** AFTER fence body, or one coherent "
                "region that removes the method without a lone closing brace."
            )
    return hits


def _check_multi_region_same_file(proposal_text: str) -> List[str]:
    if _is_no_change_response(proposal_text):
        return []

    counts: dict[str, int] = {}
    for m in FILE_LINE_RE.finditer(proposal_text):
        p = m.group(1).replace("\\", "/").rstrip("`)")
        counts[p] = counts.get(p, 0) + 1

    warns: List[str] = []
    for path, n in counts.items():
        if n > 2:
            warns.append(
                f"APPLY RISK: {path} appears in {n} FILE blocks (prefer ≤2 regions). "
                f"Multi-hunk same-file apply often breaks imports or class structure."
            )
    return warns


def _check_onboarding_sections_import(proposal_text: str) -> List[str]:
    if _is_no_change_response(proposal_text):
        return []

    uses_sections = bool(re.search(r"\bOnboardingSections\.", proposal_text))
    if not uses_sections:
        return []

    for m in FENCED_AFTER_RE.finditer(proposal_text):
        body = m.group(1)
        if "import " not in body and "package:" not in body:
            continue
        if "OnboardingSections" in body:
            continue
        if "onboarding_navigation_utils" in body:
            continue
        if re.search(r"^\s*import\s+", body, re.M) and "onboarding_navigation_utils" not in body:
            if re.search(r"OnboardingSections\.", proposal_text):
                return [
                    "HARD BAN: import AFTER drops onboarding_navigation_utils while "
                    "OnboardingSections is still required — keep that import."
                ]
    return []


def _check_before_on_disk(
    task_text: str,
    proposal_text: str,
    project_root: Optional[Path],
) -> List[str]:
    if project_root is None:
        return []

    if not extract_paths(task_text):
        return []

    if _is_no_change_response(proposal_text):
        return []

    if _task_allows_empty_file_after_only(task_text):
        return []

    lower_task = task_text.lower()
    if re.search(r"\b(status only|planning only|no code change|read-?only)\b", lower_task):
        return []

    before_body = _extract_section(proposal_text, ["before", "exact before", "current"])
    if not before_body.strip():
        return []

    paths = extract_paths(task_text)
    if not paths:
        return []

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
    warnings.extend(_check_brace_only_after(proposal_text))
    warnings.extend(_check_multi_region_same_file(proposal_text))
    warnings.extend(_check_onboarding_sections_import(proposal_text))
    warnings.extend(_check_before_on_disk(task_text, proposal_text, project_root))

    if task_forbids_new_fields(task_text) and not _is_no_change_response(proposal_text):
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
