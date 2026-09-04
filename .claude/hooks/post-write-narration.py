#!/usr/bin/env python3
"""PostToolUse (Write|Edit) — decision narration in markdown, caught at the edit.

The rule is `method/references/history-in-git.md`: a standing artefact carries
the position that holds now, never the story of how it came to be. This guard
does not restate it and holds no opinion of its own — it *calls* the heuristic
`scripts/lint-skills.py` already carries, so there is one pattern in the method
and not a second that drifts from it.

**What it adds over the lint** is the moment. The lint runs before a PR, over
one repo, on skill files only; this runs on the edit that introduces the line,
in whatever repo the method has been installed into, so the writer is still
holding the sentence when they hear about it.

**Only the lines this edit introduced are reported.** A file with narration
already in it would otherwise nag on every unrelated edit, and a guard that
nags is a guard that gets removed.

**Exit 2 rather than a silent note**: the model sees the stderr of an exit 2 and
can act on it. Nothing is blocked — the write has already happened, and by
design: the heuristic is high-precision but it is still a heuristic, and two of
its hits are sanctioned lines the writer should keep.

**When it cannot find the lint it says so and passes.** A skipped check that
prints nothing reads as a clean one.
"""

from __future__ import annotations

import importlib.util
import json
import os
import subprocess
import sys
from pathlib import Path

# Files whose job IS history, per history-in-git.md §Where history does belong.
EXEMPT_NAMES = {"README.md", "CHANGELOG.md", "IMPROVEMENTS.md", "ROADMAP.md"}
EXEMPT_DIRS = {"adr", "notes", ".github"}


def repo_root(cwd: str) -> Path:
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


def find_lint(repo: Path) -> Path | None:
    """Locate the one copy of the heuristic.

    A wired repo declares its packs and links them; it does not vendor them. So
    the machine's skills clone is reachable by resolving any of those links and
    walking up to the clone root — the same fact the SessionStart guard checks,
    which is why this resolution can be relied on when that guard is quiet.
    """
    env = os.environ.get("TEOMACH_SKILLS")
    if env:
        cand = Path(env) / "scripts" / "lint-skills.py"
        if cand.is_file():
            return cand

    cand = repo / "scripts" / "lint-skills.py"        # the skills repo itself
    if cand.is_file():
        return cand

    for skills_dir in (repo / ".claude" / "skills", Path.home() / ".claude" / "skills"):
        if not skills_dir.is_dir():
            continue
        for entry in sorted(skills_dir.iterdir()):
            try:
                here = entry.resolve(strict=True)
            except OSError:
                continue
            for parent in list(here.parents)[:6]:
                cand = parent / "scripts" / "lint-skills.py"
                if cand.is_file():
                    return cand
    return None


def load_lint(path: Path):
    # A guard writes nothing outside the repo it is guarding, and the lint lives
    # in the skills clone — so no __pycache__ beside it.
    sys.dont_write_bytecode = True
    spec = importlib.util.spec_from_file_location("teomach_lint_skills", path)
    if spec is None or spec.loader is None:
        return None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def skip(why: str) -> None:
    print(f"narration guard SKIPPED, not passed: {why}", file=sys.stderr)
    sys.exit(0)


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        sys.exit(0)

    tool_input = payload.get("tool_input") or {}
    raw_path = tool_input.get("file_path") or ""
    if not raw_path:
        sys.exit(0)

    target = Path(raw_path)
    if target.suffix.lower() not in (".md", ".markdown"):
        sys.exit(0)
    if target.name in EXEMPT_NAMES or EXEMPT_DIRS.intersection(target.parts):
        sys.exit(0)
    if not target.is_file():
        sys.exit(0)

    repo = repo_root(payload.get("cwd") or "")
    lint_path = find_lint(repo)
    if lint_path is None:
        skip(
            "scripts/lint-skills.py is not reachable from this repo, so the "
            "narration pattern could not be loaded. Looked at $TEOMACH_SKILLS, "
            f"{repo}/scripts/, and the clone behind .claude/skills/."
        )

    try:
        lint = load_lint(lint_path)
        narration = lint.NARRATION
        mask = lint.mask_fenced_blocks
    except (AttributeError, OSError, SyntaxError, ImportError) as exc:
        skip(f"{lint_path} would not load its narration pattern ({exc}).")

    try:
        text = target.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as exc:
        skip(f"{target} could not be read ({exc}).")

    # What this edit put on the page. Anything already in the file was somebody
    # else's decision and is the lint's business, not this edit's.
    introduced = tool_input.get("content")
    if introduced is None:
        introduced = tool_input.get("new_string")
    if introduced is None:
        edits = tool_input.get("edits")
        if isinstance(edits, list):
            introduced = "\n".join(
                e.get("new_string", "") for e in edits if isinstance(e, dict)
            )

    masked = mask(text)
    hits = []
    for match in narration.finditer(masked):
        phrase = match.group(0)
        if introduced is not None and phrase not in introduced:
            continue
        hits.append((masked[: match.start()].count("\n") + 1, phrase))
    if not hits:
        sys.exit(0)

    try:
        shown = target.relative_to(repo)
    except ValueError:
        shown = target

    lines = text.split("\n")
    out = [f"This edit wrote decision narration into {shown}:", ""]
    for line_no, phrase in hits[:10]:
        source = lines[line_no - 1].strip() if line_no <= len(lines) else ""
        out.append(f"  {shown}:{line_no}  `{phrase}`")
        if source:
            out.append(f"      {source[:110]}")
    if len(hits) > 10:
        out.append(f"  … and {len(hits) - 10} more")
    out += [
        "",
        "A standing artefact carries the position that holds now. The story of",
        "how it got there is already recorded in git, the PR body and the ADR,",
        "each written once by whoever did the work; a copy here pays context in",
        "every session that loads it and rots on the next change.",
        "",
        "Do instead:",
        "  · state the position as it stands, with no reference to what it",
        "    replaced, and put the reasoning in the PR body where the reviewer",
        "    is actually reading;",
        "  · keep the line only if it is one of the two sanctioned kinds — an",
        "    as-at or [FLUX] stamp on an external fact, or a functional pointer",
        "    into history a procedure genuinely routes through. The test is",
        "    whether the running session uses the line.",
        "",
        f"The rule: method/references/history-in-git.md; the pattern: {lint_path}",
    ]
    print("\n".join(out), file=sys.stderr)
    sys.exit(2)


if __name__ == "__main__":
    main()
