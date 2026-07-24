"""
file_reader.py
--------------
Safe, bounded reading of source files from the monorepo so agents
receive real code instead of inventing it.

Rules:
  - Only paths under allowed roots are readable
  - Path traversal (`..`) is blocked
  - Very large files are truncated with a clear marker
  - Missing files return a clear error string (never raise)

Region injection (2026-07-24):
  When 2+ source paths are named in a coding task, each file is injected as:
    - HEAD: first HEAD_LINES lines (quote material)
    - optional REGION: ±REGION_RADIUS lines around task keywords for the
      primary edit target (first path), so multi-file prompts stay focused
  Single-file tasks still get full (bounded) content.
"""

from __future__ import annotations

import logging
import re
from pathlib import Path
from typing import List, Optional, Tuple

from rich.console import Console

console = Console()
logger = logging.getLogger("orchestrator.file_reader")

ALLOWED_ROOTS = [
    "packages/",
    "mobile_app/",
    "web-app/",
    "functions/",
    "docs/",
    "tasks/",
    "orchestrator/",
    "prompts/",
]

ALLOWED_ROOT_FILES = {
    "STATUS.md",
    "AGENT_SYSTEM.md",
    "ROADMAP.md",
    "ARCHITECTURE.md",
    "HANDOFF.md",
    "README.md",
    "docker-compose.yml",
}

MAX_CHARS_PER_FILE = 24_000
HEAD_LINES = 12
REGION_RADIUS = 45
# When multi-file, still allow a modest full read if file is small
SMALL_FILE_FULL_CHARS = 4_000

PATH_PATTERN = re.compile(
    r"(?:^|[\s`\"'(])"
    r"((?:packages|mobile_app|web-app|functions|docs|tasks|orchestrator|prompts)"
    r"/[\w./\-]+\.(?:dart|ts|js|tsx|jsx|md|yaml|yml|json|txt|py))"
    r"(?=[\s`\"')\].,;:!?]|$)",
    re.IGNORECASE,
)

# Tokens pulled from task text to center the region window
KEYWORD_PATTERN = re.compile(
    r"\b("
    r"AppBar|QuickLinksPanel|_QuickLinkTile|MultiBrandOverviewPanel|"
    r"FutureFeaturePlaceholderPanel|OnboardingProgress|Live Branding|"
    r"_AlertEmpty|_AlertItem|AlertsCard|LinearProgressIndicator|"
    r"setFranchiseProvider|primaryColor|secondaryColor|currentAppName|"
    r"currentLogoUrl|getFoundationProgress|isStepComplete|"
    r"DesignTokens|FranchiseProvider|OwnerHQDashboard|"
    r"class\s+\w+|"
    r"[A-Z][a-zA-Z0-9_]{3,}"
    r")\b"
)


def _is_allowed(rel_path: str) -> bool:
    normalized = rel_path.replace("\\", "/").lstrip("./")
    if normalized in ALLOWED_ROOT_FILES:
        return True
    return any(normalized.startswith(root) for root in ALLOWED_ROOTS)


def read_source_file(project_root: Path, rel_path: str) -> Tuple[str, bool]:
    cleaned = rel_path.replace("\\", "/").lstrip("./")
    if ".." in cleaned.split("/"):
        return f"[BLOCKED] Path traversal not allowed: {rel_path}", False

    if not _is_allowed(cleaned):
        return (
            f"[BLOCKED] Path not in allowed roots: {rel_path}\n"
            f"Allowed roots: {', '.join(ALLOWED_ROOTS)}",
            False,
        )

    full = project_root / cleaned
    try:
        text = full.read_text(encoding="utf-8")
    except FileNotFoundError:
        return f"[MISSING] File does not exist: {cleaned}", False
    except Exception as e:
        return f"[ERROR] Could not read {cleaned}: {e}", False

    if len(text) > MAX_CHARS_PER_FILE:
        text = (
            text[:MAX_CHARS_PER_FILE]
            + f"\n\n...[TRUNCATED — file is longer; showing first {MAX_CHARS_PER_FILE} chars]"
        )

    return text, True


def extract_mentioned_paths(task_text: str) -> List[str]:
    found = PATH_PATTERN.findall(task_text)
    seen = set()
    unique = []
    for p in found:
        norm = p.replace("\\", "/")
        if norm not in seen:
            seen.add(norm)
            unique.append(norm)
    return unique


def _extract_task_keywords(task_text: str, limit: int = 12) -> List[str]:
    found = KEYWORD_PATTERN.findall(task_text)
    seen = set()
    out: List[str] = []
    for k in found:
        if k.startswith("class "):
            continue
        if k not in seen and len(k) > 2:
            seen.add(k)
            out.append(k)
        if len(out) >= limit:
            break
    return out


def _find_region_center(lines: List[str], keywords: List[str]) -> Optional[int]:
    if not keywords:
        return None
    lower_keys = [k.lower() for k in keywords]
    for i, line in enumerate(lines):
        low = line.lower()
        for k in lower_keys:
            if k.lower() in low:
                return i
    return None


def _build_region_view(
    full_text: str,
    *,
    keywords: List[str],
    is_primary: bool,
    multi_file: bool,
) -> str:
    """
    For multi-file tasks: HEAD + optional centered REGION for primary file.
    For single-file or small files: return full (already bounded) text.
    """
    if not multi_file or len(full_text) <= SMALL_FILE_FULL_CHARS:
        return full_text

    lines = full_text.splitlines()
    head_n = min(HEAD_LINES, len(lines))
    head = "\n".join(lines[:head_n])

    parts = [
        f"// --- HEAD (first {head_n} lines — use for quote-first) ---",
        head,
    ]

    if is_primary and keywords:
        center = _find_region_center(lines, keywords)
        if center is not None:
            start = max(0, center - REGION_RADIUS)
            end = min(len(lines), center + REGION_RADIUS + 1)
            # Avoid duplicating pure head overlap when region starts at 0
            region_lines = lines[start:end]
            parts.append(
                f"\n// --- REGION lines {start + 1}-{end} "
                f"(keyword window — primary edit target) ---"
            )
            parts.append("\n".join(region_lines))
        else:
            # Fallback: mid-file sample so primary file still has body context
            mid = len(lines) // 2
            start = max(head_n, mid - REGION_RADIUS)
            end = min(len(lines), mid + REGION_RADIUS)
            parts.append(
                f"\n// --- REGION lines {start + 1}-{end} (mid-file fallback) ---"
            )
            parts.append("\n".join(lines[start:end]))
    else:
        parts.append(
            "\n// --- (quote-only companion file: HEAD only; "
            "do not invent body not shown) ---"
        )

    return "\n".join(parts)


def load_mentioned_files(
    project_root: Path,
    task_text: str,
    max_files: int = 4,
) -> str:
    """
    Detect paths in the task, read them, and return a ready-to-inject
    markdown block. Multi-file coding tasks use region injection.
    """
    paths = extract_mentioned_paths(task_text)[:max_files]
    if not paths:
        console.print("[yellow]No source-file paths detected in task text.[/yellow]")
        return ""

    keywords = _extract_task_keywords(task_text)
    multi_file = len(paths) >= 2

    console.print(
        f"[bold cyan]Loading {len(paths)} mentioned source file(s)"
        f"{' [region mode]' if multi_file else ''}...[/bold cyan]"
    )
    blocks = []
    for idx, rel in enumerate(paths):
        content, ok = read_source_file(project_root, rel)
        status = "OK" if ok else "FAILED"
        marker = "✓" if ok else "✗"
        if ok:
            content = _build_region_view(
                content,
                keywords=keywords,
                is_primary=(idx == 0),
                multi_file=multi_file,
            )
        console.print(f"  {marker} {rel}  [{status}]  ({len(content)} chars)")
        blocks.append(
            f"### FILE: `{rel}`  [{status}]\n"
            f"```\n{content}\n```"
        )

    mode_note = ""
    if multi_file:
        mode_note = (
            "\nMulti-file mode: primary path includes HEAD + keyword REGION; "
            "companion paths are HEAD (quote-only) unless small. "
            "Do not invent code outside the shown regions.\n"
        )

    header = (
        "## RELEVANT SOURCE FILES (real contents from the monorepo)\n"
        "You MUST base any proposal on the real content below. "
        "If a file is marked MISSING or BLOCKED, say so and do not invent it.\n"
        f"{mode_note}"
    )
    return header + "\n\n".join(blocks)
