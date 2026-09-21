#!/usr/bin/env python3
# Source: teomach-skills harness/hooks/_target.py —
# edit it there and re-run `scripts/wire-repo.py update`, never edit a copy.
"""Shared by the post-write guards: what this edit touched, and where it sits.

Imported, never run — `_payload.sh` is the shell guards' equivalent and this
is the Python one. Both post-write guards must answer the same three questions
before either can do its own job: which repo the session is in, whether the
path is a memory store, and what text this edit introduced. One copy of each
answer is the whole point — two guards that answer differently give a session
two verdicts on one write, and neither is visible from inside the other.

A guard importing this writes no bytecode beside itself — `.claude/hooks/` is
inside the repo it guards, and a `__pycache__` appearing there is a tree the
session dirtied by its own start. Each importer sets `sys.dont_write_bytecode`
before the import, and falls open in the house's own words when this file is
not beside it, naming the rewire that puts it there.
"""

from __future__ import annotations

import os
import subprocess
from pathlib import Path


def repo_root(cwd: str) -> Path:
    """The repo this session is in.

    `CLAUDE_PROJECT_DIR`, then the payload's `cwd` resolved to its git
    toplevel, then `cwd` as given. Why it resolves those three ways is
    `_payload.sh`'s `repo_root`, which answers it for the shell guards; this
    is the same answer in Python, so a session gets one whichever guard asks.
    """
    env = os.environ.get("CLAUDE_PROJECT_DIR")
    if env and Path(env).is_dir():
        return Path(env)
    try:
        top = subprocess.run(
            ["git", "-C", cwd or ".", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, timeout=5,
        )
        if top.returncode == 0 and top.stdout.strip():
            return Path(top.stdout.strip())
    except (OSError, subprocess.SubprocessError):
        pass
    return Path(cwd or ".")


def in_memory_store(target: Path, repo: Path) -> bool:
    """True when this path is a fact in a project's memory store.

    Two shapes, because the store sits in two places. The per-project store a
    session harness hands out lives under a `.claude/` tree — `memory/` with
    `.claude` somewhere above it — and a repo that keeps its own puts it at the
    root of the tree. A `memory/` anywhere else (a `src/memory/` of source
    files, say) is somebody's code and none of either guard's business.

    Both spellings of both sides are compared, because a machine whose /home is
    a symlink to /var/home would otherwise compare one directory with itself
    and disagree.
    """
    try:
        candidates = [target.absolute(), target.resolve()]
    except OSError:
        candidates = [target.absolute()]

    for here in candidates:
        parts = here.parts
        for i, part in enumerate(parts[:-1]):        # [:-1] — the file is not a dir
            if part != "memory":
                continue
            if ".claude" in parts[:i]:
                return True
        for base in (repo.absolute(), repo):
            try:
                base = base.resolve()
            except OSError:
                pass
            try:
                rel = here.relative_to(base)
            except ValueError:
                continue
            if rel.parts and rel.parts[0] == "memory" and len(rel.parts) > 1:
                return True
    return False


def introduced_text(tool_input: dict) -> str | None:
    """What this call put on the page, whichever edit shape carried it.

    Both guards report only what the edit introduced, because a file with the
    thing already in it would otherwise be scolded on every unrelated save.
    Write carries `content`, Edit carries `new_string`, MultiEdit carries a
    list of them.

    THE EMPTY STRING AND `None` ARE DIFFERENT ANSWERS, and collapsing them is
    a measured regression: `""` is a DELETION — the edit introduced nothing,
    so nothing in the file is this edit's and the guard stays silent — while
    `None` is a shape this cannot read, where the honest answer is to report
    the file whole rather than pass it in silence. Both callers therefore test
    `is not None`, never truthiness.
    """
    for key in ("content", "new_string"):
        value = tool_input.get(key)
        if isinstance(value, str):
            return value
    edits = tool_input.get("edits")
    if isinstance(edits, list):
        return "\n".join(
            e.get("new_string", "") for e in edits if isinstance(e, dict)
        )
    return None
