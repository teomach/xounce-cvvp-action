#!/usr/bin/env python3
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
naming the file at fault. There is no third outcome — never a half-orientation.
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

CONFIG_NAME = ".teomach.yml"

# The kernel's references are reachable from any installed kernel skill, because
# `.claude/skills/<skill>` is a symlink into the method clone and `..` walks the
# real tree. `setup` is the anchor: every bundle links the kernel.
ANCHOR = ".claude/skills/setup"

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


def render(config: dict, manifest: dict) -> str:
    tier = config.get("tier", manifest.get("tier_default"))
    hints = manifest.get("skills_hint") or []
    overlays = config.get("overlays") or []
    living = manifest.get("living_docs") or []
    checks = manifest.get("checks") or []
    mechanical = config.get("mechanical") or manifest.get("mechanical")
    tracker = config.get("tracker_pathway") or manifest["tracker"]
    branching = config.get("branching") or manifest["branching"]

    out = ["# Orientation — the method you are working inside", ""]

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
        f"per `{ANCHOR}/../../MODELS.md`, whether your model fits — only the "
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

    out.append(
        f"**Standing rules** in `{ANCHOR}/../references/` — "
        + ", ".join(f"`{f}`" for f in REFERENCES)
        + ": read the page, do not reconstruct it."
    )
    out.append("")
    out.append("Depth lives in the skills. This is the map, not the method.")
    return "\n".join(out) + "\n"


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
    args = parser.parse_args(argv)

    profiles = Path(args.profiles) if args.profiles else None
    try:
        config, manifest, _ = load(Path(args.repo), profiles)
        sys.stdout.write(render(config, manifest))
        return 0
    except Refusal as exc:
        sys.stdout.write(refusal_text(str(exc)))
        return 2


if __name__ == "__main__":
    sys.exit(main())
