#!/usr/bin/env python3
# Source: teomach-skills harness/orient/orient.py —
# edit it there and re-run `scripts/wire-repo.py update`, never edit a copy.
"""Generate a repo's orientation text from its declarations.

Reads `.teomach.yml` and the `profiles/<type>.yml` it names, and writes the
orientation a SessionStart hook injects into every session in that repo. The
output is fixed prose with declared values slotted in: it points at skills and
references, it never restates them, and its length is a correctness property —
past a page it has started being a second copy of the doctrine, and every
session in the repo pays for that forever.

Stdlib only, on purpose. This runs at session start on any machine that clones
a wired repo, including one that has never had PyYAML installed, so it carries
its own reader for the subset the manifests use — the keys it reads are listed
in `harness/orient/README.md` in teomach-skills, the repo this file is copied
out of. The reader is strict: anything outside that subset is a refusal naming
file and line, never a quiet reinterpretation.

This file has two homes, and every comment in it must hold in both:
`harness/orient/orient.py` in the teomach-skills clone, and
`.claude/hooks/orient.py` in every wired repo, where `wire-repo.py` installs
it and `session-start-orient.sh` beside it runs it at session start. By hand,
`--repo` names the repo to orient (default: where you run it from):

    python3 .claude/hooks/orient.py                # a wired repo, at its root
    python3 harness/orient/orient.py --repo DIR    # from the method clone

Add `--profiles DIR` where the manifests live somewhere else.

Exit status: 0 with the orientation on stdout, or 2 with a refusal on stdout
naming the file at fault. A refusal is whole — never a half-orientation
assembled from defaults. A page whose *citations* have gone dark is neither of
those: it renders, and declares what is dark. Which citation failure gets which
answer is `harness/orient/README.md` §Citations survive being tidied; what the
degrading one costs and says is §What a dead link costs.
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

CONFIG_NAME = ".teomach.yml"

# Where the machine's install of the kernel is reachable from inside a repo —
# every bundle links `setup`. `_find_profiles` resolves it *physically*, and
# nothing prints it: printed citations go through METHOD_LINK below.
ANCHOR = ".claude/skills/setup"

# The pages every orientation cites, through the `.claude/method` link
# `wire-repo.py` keeps pointed at the physically-resolved method clone: one
# terminal symlink and no `..`, so each path is its own normalisation. Why no
# printed path may put `..` behind a symlink is stated once, in
# `harness/orient/README.md` §Citations survive being tidied — beside this
# file's first home, and reachable through this very link
# (`.claude/method/harness/orient/README.md`) from its second.
METHOD_LINK = ".claude/method"
MODELS_PAGE = f"{METHOD_LINK}/MODELS.md"
REFERENCES_DIR = f"{METHOD_LINK}/method/references"

TRACKERS = ("simple", "complex")
BRANCHINGS = ("main", "develop-master")
TIERS = (1, 2, 3)


class Refusal(Exception):
    """A missing or malformed input. Names the file at fault and the fix."""


# --------------------------------------------------------------------------
# The manifest reader — the YAML subset the schema uses, and nothing else.
#
# One place it departs from PyYAML, deliberately: a block scalar (`>` or `|`)
# ends without the trailing newline PyYAML appends. Every block scalar the
# schema has is a value rendered *inline* into a sentence — a type's `summary`
# into "**Its type** — `x`, tier 1. …", a hint's `when:` into a bullet — so a
# trailing newline would break the paragraph it sits in and cost a character
# against a page budget that has under 150 to spare on the largest type.
# Stripping is the right reading for a rendered field; matching PyYAML here
# would be matching it for its own sake. `test-orient.py` asserts both halves:
# that the reader strips, and that nothing *else* differs from PyYAML on any
# fixture or shipped manifest.
# --------------------------------------------------------------------------


def _strip_comment(line: str) -> str:
    """Drop a trailing `#` comment, respecting quotes."""
    quote = ""
    for i, ch in enumerate(line):
        if quote:
            if ch == quote:
                quote = ""
        elif ch in "'\"":
            quote = ch
        elif ch == "#" and (i == 0 or line[i - 1] in " \t"):
            return line[:i]
    return line


def _scalar(text: str, where: str, lineno: int):
    text = text.strip()
    if not text:
        return None
    if text[0] in "'\"":
        if len(text) < 2 or text[-1] != text[0]:
            raise Refusal(
                f"{where}:{lineno}: unterminated quoted value: {text}\n"
                f"Fix the quoting in {where}."
            )
        return text[1:-1]
    if text in ("null", "~"):
        return None
    if text in ("true", "True"):
        return True
    if text in ("false", "False"):
        return False
    try:
        return int(text)
    except ValueError:
        pass
    try:
        return float(text)
    except ValueError:
        pass
    return text


def _flow_seq(text: str, where: str, lineno: int) -> list:
    inner = text.strip()[1:-1].strip()
    if not inner:
        return []
    return [_scalar(part, where, lineno) for part in inner.split(",") if part.strip()]


def _lines(path: Path) -> list[tuple[int, int, str]]:
    """(lineno, indent, content) for every line that carries content.

    Comments are stripped here, except inside a block scalar, where YAML has
    no comments and a `#` is text. Tracking that region is what stops a `#` in
    a `summary` from being silently eaten.

    A blank line inside a block scalar is a paragraph break in YAML and this
    reader does not fold paragraphs, so it refuses rather than quietly turning
    the break into a space.
    """
    try:
        raw = path.read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        raise Refusal(f"{path}: cannot be read ({exc.strerror}).")
    out: list[tuple[int, int, str]] = []
    block_at: int | None = None
    blank_at: int | None = None
    for lineno, line in enumerate(raw, 1):
        indent = len(line) - len(line.lstrip())
        if "\t" in line[:indent]:
            raise Refusal(
                f"{path}:{lineno}: indented with a tab. YAML indents with "
                f"spaces; fix the indentation in {path}."
            )
        if block_at is not None and line.strip() and indent > block_at:
            if blank_at is not None:
                raise Refusal(
                    f"{path}:{blank_at}: blank line inside a block scalar. "
                    f"The schema's block scalars are single-paragraph values — "
                    f"a `summary`, a hint's `when:` — so write it as one "
                    f"paragraph, or give the second part its own key."
                )
            out.append((lineno, indent, line.strip()))
            continue
        if not line.strip():
            if block_at is not None and blank_at is None:
                blank_at = lineno
            continue
        block_at = None
        blank_at = None
        if line.strip().startswith("#"):
            continue
        content = _strip_comment(line).strip()
        if not content:
            continue
        out.append((lineno, indent, content))
        if content.rpartition(":")[2].strip() in (">", "|", ">-", "|-"):
            block_at = indent
    return out


def _block(rows: list, pos: int, indent: int, path: Path):
    """Parse one block at `indent`. Returns (value, next position)."""
    if pos >= len(rows) or rows[pos][1] < indent:
        return None, pos
    if rows[pos][2].startswith("- "):
        return _seq(rows, pos, indent, path)
    return _map(rows, pos, indent, path)


def _is_pair(text: str) -> bool:
    if text.startswith(("'", '"', "[")):
        return False
    key, sep, tail = text.partition(":")
    return bool(sep) and (not tail or tail.startswith(" ")) and " " not in key.strip()


def _seq(rows: list, pos: int, indent: int, path: Path):
    items = []
    while pos < len(rows) and rows[pos][1] == indent and rows[pos][2].startswith("- "):
        lineno, _, content = rows[pos]
        rest = content[2:].strip()
        pos += 1
        if _is_pair(rest):
            # A mapping item: its first key rides the dash, the rest sit two
            # columns in from it.
            child = indent + 2
            key, _, tail = rest.partition(":")
            value, pos = _value(rest, tail, rows, pos, child, path, lineno)
            item = {key.strip(): value}
            while (
                pos < len(rows)
                and rows[pos][1] == child
                and not rows[pos][2].startswith("- ")
            ):
                sub, pos = _map(rows, pos, child, path)
                item.update(sub)
            items.append(item)
        else:
            items.append(_scalar(rest, str(path), lineno))
    return items, pos


def _map(rows: list, pos: int, indent: int, path: Path):
    out: dict = {}
    while pos < len(rows) and rows[pos][1] == indent:
        lineno, _, content = rows[pos]
        if content.startswith("- "):
            break
        if ":" not in content:
            raise Refusal(
                f"{path}:{lineno}: not a `key: value` line: {content}\n"
                f"The manifest schema is keys and declared values only."
            )
        key, _, tail = content.partition(":")
        pos += 1
        out[key.strip()], pos = _value(content, tail, rows, pos, indent, path, lineno)
    return out, pos


def _value(content: str, tail: str, rows: list, pos: int, indent: int, path: Path, lineno: int = 0):
    tail = tail.strip()
    if tail.startswith("[") and tail.endswith("]"):
        return _flow_seq(tail, str(path), lineno), pos
    if tail in (">", "|", ">-", "|-"):
        # No trailing newline on the joined result — see the ruling at the top
        # of the reader. The value is rendered inline, so it ends where the
        # text ends.
        joiner = " " if tail[0] == ">" else "\n"
        parts = []
        while pos < len(rows) and rows[pos][1] > indent:
            parts.append(rows[pos][2])
            pos += 1
        return joiner.join(parts), pos
    if tail:
        return _scalar(tail, str(path), lineno), pos
    if pos < len(rows) and rows[pos][1] > indent:
        return _block(rows, pos, rows[pos][1], path)
    return None, pos


def read_yaml(path: Path) -> dict:
    """The manifest subset, or a refusal naming file and line."""
    if not path.is_file():
        raise Refusal(f"{path}: does not exist.")
    rows = _lines(path)
    if not rows:
        raise Refusal(f"{path}: is empty. It must declare the keys the schema fixes.")
    value, pos = _map(rows, 0, rows[0][1], path)
    if pos < len(rows):
        raise Refusal(
            f"{path}:{rows[pos][0]}: indentation does not line up with the block "
            f"above it: {rows[pos][2]}"
        )
    return value


# --------------------------------------------------------------------------
# Validation — every refusal names the file and says what to put there.
# --------------------------------------------------------------------------


def _require(data: dict, key: str, path: Path):
    if data.get(key) in (None, "", []):
        raise Refusal(f"{path}: `{key}` is missing. It is required.")
    return data[key]


def _one_of(value, allowed: tuple, key: str, path: Path):
    if value not in allowed:
        shown = " | ".join(str(a) for a in allowed)
        raise Refusal(f"{path}: `{key}: {value}` is not one of {shown}.")
    return value


def _as_list(value, key: str, path: Path) -> list:
    if value is None:
        return []
    if not isinstance(value, list):
        raise Refusal(f"{path}: `{key}` must be a list; found {type(value).__name__}.")
    return value


def load(repo: Path, profiles: Path | None) -> tuple[dict, dict, Path]:
    config_path = repo / CONFIG_NAME
    if not config_path.is_file():
        raise Refusal(
            f"{config_path}: does not exist, so this repo is not wired for the "
            f"method. Run `setup` to write it."
        )
    config = read_yaml(config_path)

    profile_type = config.get("type") or config.get("stack_profile")
    if not profile_type:
        raise Refusal(
            f"{config_path}: neither `type` nor `stack_profile` is set, so no "
            f"profile can be resolved. Set `type` to a name in the profiles "
            f"directory."
        )

    if profiles is None:
        profiles = _find_profiles(repo)
    if not profiles.is_dir():
        raise Refusal(
            f"{profiles}: the profiles directory does not exist. Pass "
            f"--profiles, or set TEOMACH_PROFILES."
        )

    manifest_path = profiles / f"{profile_type}.yml"
    if not manifest_path.is_file():
        present = sorted(p.stem for p in profiles.glob("*.yml"))
        listing = ", ".join(present) if present else "(none)"
        raise Refusal(
            f"{manifest_path}: no manifest for type `{profile_type}`. "
            f"Present in {profiles}: {listing}."
        )

    manifest = read_yaml(manifest_path)
    _validate(manifest, manifest_path, profile_type)
    _validate_overrides(config, config_path)
    return config, manifest, manifest_path


def _validate_overrides(config: dict, path: Path):
    """A repo may override the type's declarations; a wrong one refuses here
    rather than rendering a pathway nobody declared.

    `tracker_pathway`, not `tracker`: `.teomach.yml` already uses `tracker` for
    the tracker *system* (`github`), which is a different axis from the
    simple/complex pathway a manifest declares.

    `overlays` is not an override at all — it is the repo's own declaration,
    because a governance overlay follows the repo and never the type.
    """
    _as_list(config.get("overlays"), "overlays", path)
    if config.get("tracker_pathway") is not None:
        _one_of(config["tracker_pathway"], TRACKERS, "tracker_pathway", path)
    if config.get("branching") is not None:
        _one_of(config["branching"], BRANCHINGS, "branching", path)
    if config.get("tier") is not None:
        _one_of(config["tier"], TIERS, "tier", path)


def _find_profiles(repo: Path) -> Path:
    """Where the manifests live: the environment, else the method clone the
    repo's own kernel symlink points into, else `profiles/` beside the repo."""
    env = os.environ.get("TEOMACH_PROFILES")
    if env:
        return Path(env)
    anchor = repo / ANCHOR
    if anchor.is_symlink() or anchor.is_dir():
        # <clone>/method/setup -> up two is the clone root.
        return anchor.resolve().parent.parent / "profiles"
    return repo / "profiles"


def _validate(manifest: dict, path: Path, profile_type: str):
    name = _require(manifest, "name", path)
    if name != profile_type:
        raise Refusal(
            f"{path}: declares `name: {name}` but is the manifest for type "
            f"`{profile_type}`. The name must match the file."
        )
    _require(manifest, "summary", path)
    _one_of(_require(manifest, "tracker", path), TRACKERS, "tracker", path)
    _one_of(_require(manifest, "branching", path), BRANCHINGS, "branching", path)
    _one_of(_require(manifest, "tier_default", path), TIERS, "tier_default", path)
    for key in ("packs", "living_docs", "checks", "skills_hint"):
        _as_list(manifest.get(key), key, path)
    hints = manifest.get("skills_hint") or []
    for i, hint in enumerate(hints, 1):
        if not isinstance(hint, dict) or "skill" not in hint or "when" not in hint:
            raise Refusal(
                f"{path}: `skills_hint` entry {i} is not `- skill: <name>` with "
                f"a `when:` beside it."
            )
    if len(hints) > 6:
        raise Refusal(
            f"{path}: `skills_hint` has {len(hints)} entries. It is the handful "
            f"orientation names, capped at six; past that the type is being "
            f"described rather than routed."
        )


# --------------------------------------------------------------------------
# The orientation itself.
# --------------------------------------------------------------------------

TRACKER_PROSE = {
    "simple": (
        "Simple pathway — a spec in `specs/`, with `IMPROVEMENTS.md` for what is "
        "wrong with the thing and `ROADMAP.md` for what is queued, cut into "
        "GitHub issues when work starts. No upstream tracker."
    ),
    "complex": (
        "Complex pathway — work is held upstream and **called down** into a "
        "GitHub issue when picked up; the issue is the unit of execution."
    ),
}

BRANCH_PROSE = {
    "main": "Straight `main`; every change lands by PR.",
    "develop-master": (
        "`develop` integrates, `master` deploys; every change lands by PR."
    ),
}

REFERENCES = ("history-in-git.md", "environment-ladder.md", "judge-doctrine.md")

# What a citation to a page that does not open here is marked with, wherever
# it is printed. One mark, so the notice at the top can name it and a reader
# can find every one of them by eye.
MISSING_MARK = " (missing)"

# A `..` path segment, and not an ellipsis: `...` never matches.
_DOTDOT = re.compile(r"(?<!\.)\.\./|/\.\.(?!\.)")


def _cited_pages() -> tuple[str, ...]:
    """Every page the orientation prints a path to, in the order it prints them."""
    return (MODELS_PAGE, *(f"{REFERENCES_DIR}/{name}" for name in REFERENCES))


def _check_citations(repo: Path) -> list[str]:
    """The cited pages that do not open from this repo — a list, not a raise.

    The check's two halves part company: normalisation raises, and a page that
    does not open is returned for the caller to declare. `is_file` alone would
    let the first half through, because it resolves `..` the way the kernel
    does and so passes a citation that works only copied verbatim.

    Why the halves differ, and why normalisation is the one that raises:
    `README.md` §Citations survive being tidied. What the returned half then
    costs and says: §What a dead link costs.
    """
    missing = []
    for rel in _cited_pages():
        if os.path.normpath(rel) != rel:
            raise Refusal(
                f"orientation citation `{rel}` does not survive normalisation — "
                f"a reader who tidies it holds `{os.path.normpath(rel)}`. Cite "
                f"through `{METHOD_LINK}` with no `.` or `..` segments."
            )
        if not (repo / rel).is_file():
            missing.append(rel)
    return missing


# --------------------------------------------------------------------------
# The repair line — an instruction that can be followed from where it is read.
#
# What it answers is `_repair`'s docstring, below. *Why* those are the answers
# — what naming no clone was measured to cost, and why a worktree is told not
# to rewire — is stated once, in `harness/orient/README.md` §What a dead link
# costs, the same place and for the same reason the citation rule is (see
# METHOD_LINK above).
# --------------------------------------------------------------------------


def _is_clone(path: Path) -> bool:
    """Does this directory hold the installer and the manifests it reads?

    Both, because either alone is satisfied by something else: `profiles/`
    exists in a fixture, and a stray copy of the installer is not a clone.
    """
    return (path / "scripts" / "wire-repo.py").is_file() and (path / "profiles").is_dir()


def _clone_above(anchor: Path) -> Path | None:
    """The clone a `setup` link sits inside: `<clone>/method/setup`, up two.

    One function because two anchors take the same walk — the repo's own
    kernel link and the machine install's — and a walk written twice is one
    that can come to disagree about where the method is.
    """
    if not (anchor.is_symlink() or anchor.is_dir()):
        return None
    try:
        return anchor.resolve().parent.parent
    except OSError:
        return None


def _install_dir() -> Path:
    """The machine's skills install, by the rule `session-start-wired.sh`
    already resolves its recovery command with: `$TEOMACH_SKILLS_DIR`, else
    `~/.claude/skills`. Stated twice because one caller is shell and the other
    is this file; if either moves, both move — the guard's own
    `install_dir` line is the other half.
    """
    return Path(os.environ.get("TEOMACH_SKILLS_DIR") or (Path.home() / ".claude" / "skills"))


def _resolve_clone(repo: Path) -> Path | None:
    """A teomach-skills clone this repo can name, or None to ask the human.

    The same order `_find_profiles` resolves the manifests in, for the same
    reason — the kernel symlink already says where the method is, so nothing
    has to be configured — then the machine's own install, then the repo
    itself, because a repo that carries the installer can run its own.

    The machine install is what answers the case the repo's kernel link cannot:
    a fresh clone or a post-merge checkout has no `.claude/skills/` to resolve
    *through*, and that is exactly the state the self-heal below exists for. It
    is the anchor the wiring guard has always used for the same question.
    """
    candidates: list[Path] = []
    env = os.environ.get("TEOMACH_PROFILES")
    if env:
        candidates.append(Path(env).parent)
    for anchor in (repo / ANCHOR, _install_dir() / "setup"):
        found = _clone_above(anchor)
        if found is not None:
            candidates.append(found)
    candidates.append(repo)
    for candidate in candidates:
        try:
            resolved = candidate.resolve()
        except OSError:
            continue
        if _is_clone(resolved):
            return resolved
    return None


def _is_worktree_pointer(text: str) -> bool:
    """Is this the body of a worktree's `.git` file?

    `git worktree add` writes `gitdir: <clone>/.git/worktrees/<name>`. A
    submodule's `.git` file has the same key and no `worktrees` segment, so
    the segment is what is read, not the key.

    Both separators, because the file is git's and not this platform's: a
    wired repo is read on whatever machine cloned it, and `os.sep` would make
    the answer depend on where the question is asked rather than on what git
    wrote.
    """
    for line in text.splitlines():
        key, sep, value = line.partition(":")
        if sep and key.strip() == "gitdir":
            return "/worktrees/" in value.strip().replace("\\", "/")
    return False


def _is_worktree(repo: Path) -> bool:
    dot_git = repo / ".git"
    if not dot_git.is_file():
        return False
    try:
        return _is_worktree_pointer(dot_git.read_text(encoding="utf-8"))
    except OSError:
        return False


def _repair(repo: Path) -> str:
    """What to do about the dead link, said to whoever is reading this tree.

    Two axes, and both are read from the tree rather than assumed: *who acts*
    (a worktree's answer is not the session in it) and *whether a clone can be
    named* (if not, that is said, not left as a search).
    """
    where = repo.resolve()
    clone = _resolve_clone(repo)
    command = (
        f"`python3 {clone if clone is not None else '<clone>'}"
        f"/scripts/wire-repo.py update --repo {where}`"
    )
    if _is_worktree(repo):
        who = (
            "**Do not rewire this tree.** It is a git worktree, and "
            "`wire-repo.py update` re-applies the whole resident set — "
            "`.claude/hooks/`, `.claude/settings.json` and `CLAUDE.md`'s "
            "managed block, all tracked — so whatever of it is behind the "
            "current standard lands in this branch's diff, mid-flight. Work "
            "without the pages, say where you report that you did, and leave "
            "the fix to the human: "
        )
    else:
        who = "Restore it with "
    if clone is None:
        return (
            f"{who}{command} — no teomach-skills clone resolves from here, so "
            f"the human supplies `<clone>`; do not go looking for one."
        )
    return f"{who}{command}."


def _link_state(repo: Path) -> str:
    """Why the cited pages do not open, in the words a human can act on."""
    link = repo / METHOD_LINK
    if link.exists():
        return "resolves, but the clone behind it does not hold them"
    if link.is_symlink():
        # The *resolved* target, never `os.readlink`: a relative link body can
        # carry `..`, and no `..` segment may reach the page (`_check_normal`).
        return f"points at `{Path(os.path.realpath(link))}`, which is not there"
    return "does not exist"


def _degraded_notice(repo: Path, missing: list[str]) -> str:
    """The first thing a degraded page says: what is dark, and what to do.

    The standing rules collapse to their directory when all of them are gone,
    which is the common case — the whole link is dead — and keeps the notice
    to two names rather than four.
    """
    refs = [f"{REFERENCES_DIR}/{name}" for name in REFERENCES]
    shown = [rel for rel in missing if rel not in refs]
    if all(rel in missing for rel in refs):
        shown.append(f"{REFERENCES_DIR}/")
    else:
        shown += [rel for rel in refs if rel in missing]
    return (
        f"**Degraded.** {'These pages' if len(shown) > 1 else 'This page'} the "
        f"orientation cites {'do' if len(shown) > 1 else 'does'} not open here: "
        + ", ".join(f"`{rel}`" for rel in shown)
        + f". `{METHOD_LINK}` — the link to the method clone — {_link_state(repo)}. "
        + _repair(repo)
        + f"\n\nEverything else below stands. Do not reconstruct a page marked "
        f"{MISSING_MARK.strip()} from memory: work without it, and say so where "
        f"you report."
    )


def _check_normal(text: str) -> str:
    """No `..` path segment reaches the page, whichever input supplied it."""
    for line in text.splitlines():
        if _DOTDOT.search(line):
            raise Refusal(
                f"the orientation would print a path with a `..` segment: "
                f"`{line.strip()}`. That resolves only when copied verbatim; "
                f"rewrite the citation to open through `{METHOD_LINK}`, or as "
                f"a path with no `..` segments."
            )
    return text


def render(config: dict, manifest: dict, repo: Path) -> str:
    missing = _check_citations(repo)

    def cite(rel: str) -> str:
        """A cited path, marked where it does not open from this repo."""
        return f"`{rel}`" + (MISSING_MARK if rel in missing else "")

    def cite_name(name: str) -> str:
        """A standing rule by bare name, marked the same way."""
        return f"`{name}`" + (
            MISSING_MARK if f"{REFERENCES_DIR}/{name}" in missing else ""
        )

    tier = config.get("tier", manifest.get("tier_default"))
    hints = manifest.get("skills_hint") or []
    overlays = config.get("overlays") or []
    living = manifest.get("living_docs") or []
    checks = manifest.get("checks") or []
    mechanical = config.get("mechanical") or manifest.get("mechanical")
    tracker = config.get("tracker_pathway") or manifest["tracker"]
    branching = config.get("branching") or manifest["branching"]

    out = ["# Orientation — the method you are working inside", ""]

    # Before anything a session might act on, and only when there is something
    # to say: a whole page never carries a word about degradation.
    if missing:
        out.append(_degraded_notice(repo, missing))
        out.append("")

    repo_line = config.get("summary") or config.get("description")
    if repo_line:
        out.append(f"**This repo.** {repo_line}")
    # The overlay rides the type line rather than taking a paragraph: it is
    # part of what this repo *is*, and where its obligations are written is
    # already answered two paragraphs down, for every skill at once.
    also = "".join(f" + `{o}`" for o in overlays)
    out.append(
        f"**Its type** — `{manifest['name']}`{also}, tier {tier}. "
        f"{manifest['summary']}"
    )
    out.append("")

    out.append(
        "**The method.** One kernel runs the same lifecycle for every kind of "
        "work — **grill → to-spec → to-tickets → implement → review → docs → "
        "handoff** — with the standing disciplines (`diagnose`, `verify` and "
        "their kin, each in the skill listing) callable the moment they apply. "
        "Domain packs hold only what differs. **The gate:** a merged artefact "
        "is the agreed one and its merge SHA is its version; the build skills "
        "refuse to run ahead of it, and the human merges — always."
    )
    out.append("")
    out.append(
        "**Reaching a skill.** Some are typed by the human (`/grill`, "
        "`/to-spec`, `/implement`) and you cannot invoke them yourself: when "
        "one is the right next move, say so, then read and follow "
        "`.claude/skills/<name>/SKILL.md` while the human decides. Do not hunt "
        "with `find` — the entries are symlinks `find` will not follow."
    )
    out.append("")

    if hints:
        out.append("**The skills this repo uses**, and the moment each is for:")
        out.append("")
        for hint in hints:
            out.append(f"- `{hint['skill']}` — {hint['when']}")
        out.append("")

    out.append(f"**Tracker.** {TRACKER_PROSE[tracker]}")
    if living:
        out.append(
            "**Living documents** kept current with the work: "
            + ", ".join(f"`{d}`" for d in living)
            + "."
        )
    out.append(f"**Branches.** {BRANCH_PROSE[branching]}")
    if mechanical:
        out.append(
            f"**Before the judge spends tokens** the mechanical gate runs: "
            f"`{mechanical}`."
        )
    if checks:
        named = ", ".join(f"`docs/checks/{c}.md`" for c in checks)
        out.append(f"**The judge derives from** {named}.")
    out.append("")

    out.append(
        "**Build work flies as a lane by default.** A flight (`/lead-flight`) "
        "earns its overhead only with several file-disjoint tickets, but one "
        "go-ticket is still one `wingman` tab, dispatched once its agreed "
        "prompt lands on its issue (conversational asks included) — not "
        "the leader's own hands, and the Agent tool never dispatches a "
        "lane. Straight through only for small closeout work — a docs "
        "line, a rebase — declared before starting."
    )
    out.append("")

    out.append("**No leader chooses these for you:**")
    out.append(
        f"**Fit** — one line before substantive work, carried in a commit "
        f"body (the judge looks for it): the hardest act, the tier it needs "
        f"per {cite(MODELS_PAGE)}, whether your model fits — only the "
        f"human can switch — and the cut that fits the context window with "
        f"room for judge rounds."
    )
    out.append(
        "**Environment** — the ladder's rung chosen per job — the guard "
        "refusing a global install is a floor, not a choice."
    )
    out.append(
        '**Done** — carries fresh evidence or the mark "not verified"; '
        "`verify` is the condition as a skill, run before claiming."
    )
    out.append("")

    # Each rule marked on its own name, never the directory holding them: one
    # dark page does not make the other two unreadable, and a mark on the
    # directory would tell a reader to skip pages that open.
    out.append(
        f"**Standing rules** in `{REFERENCES_DIR}/` — "
        + ", ".join(cite_name(name) for name in REFERENCES)
        + ": read the page, do not reconstruct it."
    )
    out.append("")
    out.append("Depth lives in the skills. This is the map, not the method.")
    return _check_normal("\n".join(out) + "\n")


# --------------------------------------------------------------------------
# The self-heal
#
# RULED, not decided here: teomach-cockpit#226, leader comment of 2026-09-08,
# built as teomach-skills#377. What the rule is — the precondition, what
# happens when it holds and what happens when it does not — and why it is in
# this hook rather than the wiring guard, why the run it makes cannot dirty a
# tracked file, and what it deliberately leaves to the guard, are stated once,
# in `harness/orient/README.md` §The self-heal — beside this
# file's first home, and reachable through
# `.claude/method/harness/orient/README.md` from its second, the citation
# METHOD_LINK above makes for the same reason. What is here is the mechanism.
# --------------------------------------------------------------------------

# The hook's own budget is 15 s (`harness/settings.template.json`). The repair
# gets less than that, so a repair that hangs costs the session its repair and
# not its orientation.
HEAL_TIMEOUT = 10


def _installed_version(here: Path) -> str | None:
    """The guard-set version stamped beside this file.

    Two places for the same reason `session-start.sh` looks in two for
    `_payload.sh`: installed, the stamp sits in `.claude/hooks/` beside this
    file; in the clone it is one directory over, in `harness/hooks/`.
    """
    for candidate in (here / "VERSION", here.parent / "hooks" / "VERSION"):
        try:
            return candidate.read_text(encoding="utf-8").strip()
        except OSError:
            continue
    return None


def _generated_layer_faults(repo: Path) -> list[str]:
    """What of the generated layer is missing — the layer a rewire restores.

    Absence only: a skill link that *dangles* is not a fault of this layer and
    is not repaired here, for the reason §The self-heal gives.
    """
    faults = []
    if not (repo / METHOD_LINK).exists():
        faults.append(f"`{METHOD_LINK}` {_link_state(repo)}")
    skills = repo / ".claude" / "skills"
    try:
        if not skills.is_dir():
            faults.append("`.claude/skills/` does not exist")
        elif not any(skills.iterdir()):
            faults.append("`.claude/skills/` is empty")
    except OSError as exc:
        faults.append(f"`.claude/skills/` cannot be read ({exc})")
    return faults


def _heal_blocked(repo: Path, here: Path) -> str | None:
    """Why the ruling's precondition does not hold, or None when it does.

    Read from files, never from a claim in prose. A repo that fails any of
    these is not "otherwise wired", and its answer is the guard's refusal.
    """
    try:
        config = read_yaml(repo / CONFIG_NAME)
    except (Refusal, OSError) as exc:
        return f"{CONFIG_NAME} does not read here ({exc})"
    declared = config.get("guard_set")
    if declared is None:
        return f"{CONFIG_NAME} declares no `guard_set`, so nothing says which set this repo expects"
    installed = _installed_version(here)
    if installed is None:
        return "no VERSION beside this hook, so the installed set cannot be identified"
    if str(declared).strip() != installed:
        return (
            f"the guard set is stale — {CONFIG_NAME} says {declared} and the "
            f"installed scripts are {installed}"
        )
    return None


def _git_status(repo: Path) -> list[str] | None:
    """Every line `git status --porcelain` prints, or None where it could not
    be asked — which is not the same as a clean tree and is never reported as
    one."""
    try:
        done = subprocess.run(
            ["git", "-C", str(repo), "status", "--porcelain"],
            capture_output=True, text=True, timeout=HEAL_TIMEOUT,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if done.returncode != 0:
        return None
    return [line for line in done.stdout.splitlines() if line.strip()]


def _confinement(before: list[str] | None, after: list[str] | None) -> str:
    """What the run did to what git can see, said in one paragraph."""
    if before is None or after is None:
        return (
            "**Tracked files: not established.** `git status` could not be read "
            "here, so this run's confinement rests on `--links-only` alone — it "
            "plans the generated layer and reaches no planner that writes a "
            "tracked file."
        )
    new = [line for line in after if line not in before]
    if not new:
        return (
            "**No tracked file changed.** `--links-only` reaches no planner that "
            "writes one, and `git status` read either side of the run is "
            "unchanged."
        )
    listed = "\n".join(f"        {line}" for line in new)
    return (
        "**This repair left changes git can see** — which it should not, and "
        "nothing here committed them:\n\n"
        f"{listed}\n\n"
        "    Review them before doing any work. If they are the generated links "
        "themselves, this repo's `.gitignore` is missing the entries a full "
        "`wire-repo.py update` writes."
    )


def heal(repo: Path, here: Path, out=None) -> None:
    """Restore the generated layer where the ruling's precondition holds.

    Prints what it did — or why it did nothing — and returns. It never raises
    and never blocks: whatever happens here, the page still renders after it.
    """
    out = out or sys.stdout
    faults = _generated_layer_faults(repo)
    if not faults:
        return
    what = "; ".join(faults)

    blocked = _heal_blocked(repo, here)
    clone = _resolve_clone(repo)
    if blocked is None and clone is None:
        blocked = "no teomach-skills clone resolves from here, so there is nothing to rewire from"
    if blocked is not None:
        out.write(
            f"**Self-heal not run.** The generated layer is incomplete "
            f"({what}) and this session did not repair it: {blocked}. Nothing "
            f"was written.\n\n"
        )
        return

    command = [
        sys.executable, str(clone / "scripts" / "wire-repo.py"),
        "update", "--repo", str(repo), "--links-only",
    ]
    shown = "    " + " ".join(command)
    before = _git_status(repo)
    try:
        done = subprocess.run(
            command, capture_output=True, text=True, timeout=HEAL_TIMEOUT
        )
    except subprocess.TimeoutExpired:
        out.write(
            f"**Self-heal timed out** after {HEAL_TIMEOUT}s and was killed. The "
            f"generated layer may be half restored; run it yourself and read "
            f"what it says:\n\n{shown}\n\n"
        )
        return
    except OSError as exc:
        out.write(f"**Self-heal could not run** ({exc}):\n\n{shown}\n\n")
        return
    after = _git_status(repo)

    output = (done.stdout + done.stderr).strip()
    quoted = "\n".join(f"    {line}" for line in output.splitlines())
    if done.returncode != 0:
        # One cause is worth naming rather than leaving as an argparse dump,
        # because it is the ordinary state during a roll and reads as a bug:
        # the repair runs the installer in the clone THIS MACHINE installs
        # from, and a repo can be wired at a version that clone does not carry
        # yet. `test-orient.py` seeds an installer that refuses the flag.
        cause = ""
        if "--links-only" in output and "unrecognized arguments" in output:
            cause = (
                f"\n\nThat clone is older than this repo's wiring: it has no "
                f"`--links-only`. The repair runs the installer where the "
                f"machine's skills are installed from, so update that clone "
                f"(`git pull` in {clone}, then its `scripts/install-skills.sh`) "
                f"and the next session start repairs itself."
            )
        out.write(
            f"**Self-heal refused** (exit {done.returncode}). The generated "
            f"layer is still incomplete ({what}), and what the installer said "
            f"is the whole of why:\n\n{quoted}{cause}\n\n"
            f"{_confinement(before, after)}\n\n"
        )
        return

    remaining = _generated_layer_faults(repo)
    headline = (
        "**Self-healed at session start.**" if not remaining
        else "**Self-heal ran and did not finish the job.**"
    )
    out.write(
        f"{headline} This repo is wired and its guard set is current, and its "
        f"generated layer — `.claude/skills/` and `{METHOD_LINK}`, materialised "
        f"against this machine's install and gitignored, so neither travels in a "
        f"clone — was incomplete: {what}. This hook therefore ran the repair "
        f"itself rather than printing the command for someone to run "
        f"(teomach-cockpit#226):\n\n{shown}\n\n{quoted}\n\n"
        f"{_confinement(before, after)}\n\n"
    )
    if remaining:
        out.write(
            f"**Still incomplete after the repair:** {'; '.join(remaining)}. Tell "
            f"the human; the orientation below is what this state renders.\n\n"
        )
        return
    out.write(
        "The page below is the repaired repo's. The skill **listing** this "
        "session already loaded is not: a skill linked a moment ago is readable "
        f"at `.claude/skills/<name>/SKILL.md` and followable from there, and "
        "becomes invocable at the next session start.\n\n"
    )


def refusal_text(message: str) -> str:
    return (
        "# Orientation unavailable — this repo cannot be oriented\n\n"
        f"{message}\n\n"
        "No orientation was generated. Tell the human what is wrong above "
        "before doing any work that assumes the method is wired.\n"
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--repo", default=".", help="the repo root to orient (default: .)")
    parser.add_argument("--profiles", default=None, help="directory holding <type>.yml")
    parser.add_argument(
        "--heal", action="store_true",
        help="restore the generated layer first where this repo is otherwise "
             "wired, and report what changed (the SessionStart hook passes it)",
    )
    args = parser.parse_args(argv)

    profiles = Path(args.profiles) if args.profiles else None
    if args.heal:
        # Before `load`, not after: with no `.claude/skills/` there is no
        # anchor to resolve the manifests through, so an unrepaired fresh clone
        # refuses here and gets no page at all. Repairing first is what turns
        # that refusal into an orientation.
        #
        # Broad, and deliberately: a repair that raises must cost this session
        # its repair, never its page. The message says which happened, because
        # a page rendered over a crash nobody was told about is the silence
        # this whole path exists to end.
        try:
            heal(Path(args.repo), Path(__file__).resolve().parent)
        except Exception as exc:  # noqa: BLE001 — see above
            sys.stdout.write(
                f"**Self-heal errored** ({exc.__class__.__name__}: {exc}) and "
                f"wrote nothing further. What follows is the unrepaired repo's "
                f"orientation.\n\n"
            )
    try:
        config, manifest, _ = load(Path(args.repo), profiles)
        sys.stdout.write(render(config, manifest, Path(args.repo)))
        return 0
    except Refusal as exc:
        sys.stdout.write(refusal_text(str(exc)))
        return 2


if __name__ == "__main__":
    sys.exit(main())
