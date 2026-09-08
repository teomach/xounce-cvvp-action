#!/usr/bin/env python3
# Source: teomach-skills harness/hooks/post-write-narration.py —
# edit it there and re-run `scripts/wire-repo.py update`, never edit a copy.
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

**Standing artefacts only.** The rule binds what a later session loads, so two
places nothing is carried forward from are out of scope: the scratchpad
directory a session harness hands out under a temp root, where a lane prompt or
a PR body is staged for `gh --body-file`, and the cross-flight notes folder,
which `method/references/cross-flight-notes.md` says can be deleted without
loss. An issue number in either is functional — it is what the file is for.

**The memory store is the routing guard's room.** On every save there,
`post-write-memory-routing.py` mandates that a routed memory be rewritten as a
pointer to its owning-repo issue — the functional-pointer kind
`history-in-git.md` sanctions — and that pointer is exactly the shape the
narration pattern reads as history. One guard mandating what the other scolds
is what teaches a session to skim both, so this guard says nothing in that
store and leaves every question a memory raises to the guard that owns it.

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

# Where a session's scratch lands, and where a harness that hands out a
# scratchpad directory puts it. A repo cloned into /tmp sits here too, which is
# why a temp root alone is not the test.
TMP_ROOTS = ("/tmp", "/var/tmp")


def is_ephemeral(target: Path, session_id: str) -> bool:
    """True when nothing on this path is carried forward into a later session.

    The rule guards artefacts that persist: the position that holds now, read
    again by everyone who loads the file. Two places hold nothing forward, and
    an issue number in either is functional rather than narrated — so a guard
    that fired there would be nagging about the one thing that has to be in the
    file.

    · **The session scratchpad** — the directory a session harness hands out
      under a temp root, where a lane prompt, an issue body or a PR body is
      staged for `gh --body-file`. Recognised, never hard-coded: a temp root
      carrying a `scratchpad` component or this payload's own session id. A
      temp root alone is not the test — a repo cloned into /tmp is a standing
      artefact like any other.
    · **The cross-flight notes folder** — `method/references/cross-flight-notes.md`
      makes it a folder outside every repo, holds it to one file per note, and
      says outright that it can be deleted without loss.
    """
    notes = os.environ.get("TEOMACH_FLIGHT_NOTES") or str(Path.home() / "Code" / "flight-notes")

    def under(root: str) -> bool:
        # Both spellings of both sides, because a machine whose /home is a
        # symlink to /var/home would otherwise compare one directory with
        # itself and disagree.
        for here in candidates:
            for base in (Path(root), Path(root).resolve()):
                stem = str(base).rstrip("/")
                if str(here) == stem or str(here).startswith(stem + "/"):
                    return True
        return False

    try:
        candidates = [target.absolute(), target.resolve()]
    except OSError:
        candidates = [target.absolute()]

    if under(notes):
        return True
    roots = [*TMP_ROOTS, os.environ.get("TMPDIR") or "/tmp"]
    if not any(under(root) for root in roots):
        return False
    parts = set().union(*(set(c.parts) for c in candidates))
    return "scratchpad" in parts or bool(session_id and session_id in parts)


def in_memory_store(target: Path, repo: Path) -> bool:
    """True when this path is in a project's memory store — the routing
    guard's room, where this guard stays out (see the docstring).

    Same two shapes as that guard's `in_memory_dir()`: `memory/` with
    `.claude` somewhere above it, or `memory/` at the root of the repo.
    Duplicated rather than imported because each guard ships standalone into
    a wired repo's `.claude/hooks/`; the shared-module dedupe is filed and
    rides its own seal.

    Both spellings of both sides are compared, because a machine whose /home
    is a symlink to /var/home would otherwise compare one directory with
    itself and disagree.
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
    if is_ephemeral(target, payload.get("session_id") or ""):
        sys.exit(0)
    if not target.is_file():
        sys.exit(0)

    repo = repo_root(payload.get("cwd") or "")
    try:
        if in_memory_store(target, repo):
            sys.exit(0)
    except OSError:
        pass
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
        "  · the one recipe for getting it there: draft the body with the Write",
        "    tool into this session's scratchpad directory — or anywhere under",
        "    /tmp, which is what the pollution guard offers for work that is not",
        "    a deliverable — then `gh pr create --body-file <that file>`. Both",
        "    guards leave that file alone, so a body may carry as many issue and",
        "    PR references as the work needs and none of it has to survive shell",
        "    quoting on the way;",
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
