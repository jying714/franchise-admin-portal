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
"""

from __future__ import annotations

import logging
import re
from pathlib import Path
from typing import List, Optional, Tuple

logger = logging.getLogger("orchestrator.file_reader")

# Roots the agent is allowed to read from (relative to PROJECT_ROOT)
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

# Also allow a few root-level files
ALLOWED_ROOT_FILES = {
    "STATUS.md",
    "AGENT_SYSTEM.md",
    "ROADMAP.md",
    "ARCHITECTURE.md",
    "HANDOFF.md",
    "README.md",
    "docker-compose.yml",
}

# Max characters we inject per file (keeps context windows sane)
MAX_CHARS_PER_FILE = 24_000

# Regex that catches common project paths mentioned in a task
PATH_PATTERN = re.compile(
    r"(?:^|[\s`\"'(])"                          # start or whitespace/quote
    r"((?:packages|mobile_app|web-app|functions|docs|tasks|orchestrator|prompts)"
    r"/[\w./\-]+\.(?:dart|ts|js|tsx|jsx|md|yaml|yml|json|txt|py))"
    r"(?:$|[\s`\"')])",                         # end or whitespace/quote
    re.IGNORECASE,
)


def _is_allowed(rel_path: str) -> bool:
    """Return True if the relative path is inside an allowed root."""
    normalized = rel_path.replace("\\", "/").lstrip("./")
    if normalized in ALLOWED_ROOT_FILES:
        return True
    return any(normalized.startswith(root) for root in ALLOWED_ROOTS)


def read_source_file(project_root: Path, rel_path: str) -> Tuple[str, bool]:
    """
    Safely read a source file.

    Returns (content_or_error_message, success).
    Never raises.
    """
    # Normalize and block traversal
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
            + f"\n\n...[TRUNCATED — file is {len(text)} chars; showing first {MAX_CHARS_PER_FILE}]"
        )

    return text, True


def extract_mentioned_paths(task_text: str) -> List[str]:
    """Find all project-relative file paths mentioned in the task."""
    found = PATH_PATTERN.findall(task_text)
    # Deduplicate while preserving order
    seen = set()
    unique = []
    for p in found:
        norm = p.replace("\\", "/")
        if norm not in seen:
            seen.add(norm)
            unique.append(norm)
    return unique


def load_mentioned_files(
    project_root: Path,
    task_text: str,
    max_files: int = 4,
) -> str:
    """
    Detect paths in the task, read them, and return a ready-to-inject
    markdown block. If no paths are found, returns an empty string.
    """
    paths = extract_mentioned_paths(task_text)[:max_files]
    if not paths:
        return ""

    blocks = []
    for rel in paths:
        content, ok = read_source_file(project_root, rel)
        status = "OK" if ok else "FAILED"
        blocks.append(
            f"### FILE: `{rel}`  [{status}]\n"
            f"```\n{content}\n```"
        )

    header = (
        "## RELEVANT SOURCE FILES (real contents from the monorepo)\n"
        "You MUST base any proposal on the real content below. "
        "If a file is marked MISSING or BLOCKED, say so and do not invent it.\n"
    )
    return header + "\n\n".join(blocks)
