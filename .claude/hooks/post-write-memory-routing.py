#!/usr/bin/env python3
# Source: teomach-skills harness/hooks/post-write-memory-routing.py —
# edit it there and re-run `scripts/wire-repo.py update`, never edit a copy.
"""PostToolUse (Write|Edit) — a memory saved is a routing decision, asked at the save.

THE ROUTING RULE IS method/references/memory-routing.md — read it there. What
this guard prints is that page rendered where it applies, because a guard runs
on machines the method clone may not be reachable from and a citation nobody
can open routes nothing; the advisory cites the page only when the routing
question fired, and carries the claim clause whole — the page states that
clause too, and this file is where it is rendered. What this docstring covers
is only what is this file's own: when it fires, when it goes quiet, and what it counts as a memory.

WHAT IT ADDS over the page is the moment. Routing a fact into a channel must
not depend on anyone remembering to do it, so the question is asked at the
save, while the writer is still holding the sentence.

ADVISORY, ALWAYS. A session must always be able to save what it learned, so
nothing here blocks and nothing is undone — the write has already happened when
this runs. Exit 2 rather than a silent note only because that is what puts the
stderr into the model's context, where it can be acted on; a note nobody reads
routes nothing.

IT FALLS SILENT ONCE OBEYED. A memory already carrying its pointer — an issue
URL, or `owner/repo#123` — has been routed, and asking again is nagging. That
is also why the nudge asks for the tracker to be named: a bare `#123` says
which number but not which repo, so it cannot be told from any other number in
the file.

A CLAIM OF A HUMAN DECISION IS ASKED FOR ITS ARTEFACT, BESIDE THE CLAIM. A
memory saying the human approved, ruled, agreed, signed off or authorised is
asked to cite, within WINDOW characters of the claim, the artefact carrying
that decision. This clause outranks the silence above: a routed memory is
exempt from the routing question, never from this one, because a memory store
can otherwise record an approval no human made and the next session has no
context to doubt it with. It reads only what this edit introduced, so a claim
already in the file is not re-asked on every unrelated save.

SCOPE. Markdown under a project's `memory/` directory: the per-project store
under a `.claude/` tree, and a `memory/` at the root of the repo the session is
in. The index (`MEMORY.md`) is out of scope for the routing question — it
carries one line per fact and the fact's own file is where that question
belongs, so firing on both would ask the same question twice per memory. The
claim clause does read the index: an index line is a second copy of whatever
its fact claims, and an uncited approval there is the same false record.

AND IT CARRIES THE SWEEP'S BOOTSTRAP. Why the sweep needs one is the page's,
under §The sweep; what is this file's own is the moment: when the advisory
fires and the store's index carries no `_Swept` stamp, or one over a quarter
old, one extra note says so and routes there. The nudge rides the advisory
and never fires alone — a memory already routed stays silent whatever the
index says, because a guard firing about the index on every save would be
the nagging this guard is built not to do.

It fails open on anything it cannot do: bad payload, unreadable file, a path it
cannot resolve.
"""

from __future__ import annotations

import json
import os
import re
import sys
from datetime import date, timedelta
from pathlib import Path

# The index, not a fact. One line per memory, written beside the file this
# guard does fire on.
INDEX_NAME = "MEMORY.md"

# §The sweep's stamp (method/references/memory-routing.md), the one thing this
# guard reads from the index: `_Swept YYYY-MM-DD …`. The date is all it needs.
SWEPT = re.compile(r"_Swept (\d{4}-\d{2}-\d{2})")

# A quarter, in whole days — the cadence the stamp itself names.
QUARTER = timedelta(days=91)

# A pointer names its tracker: a GitHub issue URL, `owner/repo#123`, or
# `repo#123`. A bare `#123` is deliberately not enough — it is the one form
# that cannot be resolved by a reader who is not in this session.
POINTER = re.compile(
    r"https?://\S*/issues/\d+"
    r"|\b[A-Za-z][A-Za-z0-9._-]*(?:/[A-Za-z0-9._-]+)?#\d+\b"
)

# A claim of a human decision — the words a lane can write on a human's
# behalf. Advisory like everything here, so the list stays high-recall and a
# false hit costs one stderr read.
CLAIM = re.compile(
    r"\b(?:approved|ruled|agreed|signed[ -]off|authori[sz]ed)\b",
    re.IGNORECASE,
)

# What can carry a decision: the pointer forms above, plus a pull-request URL
# — an approval often lives on a PR review, which POINTER (issues only) does
# not reach.
ARTEFACT = re.compile(POINTER.pattern + r"|https?://\S*/pull/\d+")

# How far from the claim its artefact may stand, in characters either side.
# 160 is the figure teomach-skills#376 sets for both halves of its fix, so one
# sentence written to satisfy this guard satisfies the cockpit's PR gate too.
WINDOW = 160


def uncited_claims(text: str, introduced: str) -> list[tuple[int, str]]:
    """Claims of a human decision with no artefact within WINDOW characters.

    Proximity is the substance: a whole-file pointer test was measured letting
    a false approval through on the strength of pointers that had nothing to
    do with it, so the citation only counts beside the claim. The
    introduced-only scoping is the module docstring's.
    """
    hits = []
    for m in CLAIM.finditer(text):
        if introduced and m.group(0) not in introduced:
            continue
        window = text[max(0, m.start() - WINDOW): m.end() + WINDOW]
        if ARTEFACT.search(window):
            continue
        hits.append((text[: m.start()].count("\n") + 1, m.group(0)))
    return hits


def repo_root(cwd: str) -> Path:
    env = os.environ.get("CLAUDE_PROJECT_DIR")
    if env and Path(env).is_dir():
        return Path(env)
    return Path(cwd or ".")


def in_memory_dir(target: Path, repo: Path) -> bool:
    """True when this path is a fact in a project's memory store.

    Two shapes, because the store sits in two places. The per-project store a
    session harness hands out lives under a `.claude/` tree — `memory/` with
    `.claude` somewhere above it — and a repo that keeps its own puts it at the
    root of the tree. A `memory/` anywhere else (a `src/memory/` of source
    files, say) is somebody's code and none of this guard's business.

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


def sweep_nudge(target: Path) -> list[str]:
    """Extra advisory lines when the store's index says no sweep is current.

    The store's index is the `MEMORY.md` in the `memory/` directory the fact
    sits under. No index yet is the bootstrap case outright — nothing exists
    to push the first sweep. Anything else this cannot read or parse adds
    nothing: the nudge is an extra, and this guard fails open.
    """
    index = target.parent / INDEX_NAME
    for parent in target.absolute().parents:
        if parent.name == "memory":
            index = parent / INDEX_NAME
            break
    try:
        text = index.read_text(encoding="utf-8")
    except FileNotFoundError:
        text = ""    # no index at all: never swept, and nothing to push it
    except (OSError, UnicodeDecodeError):
        return []
    stamps = SWEPT.findall(text)
    if not stamps:
        return [
            "Also due: this store's index carries no _Swept stamp — this",
            "machine's memory has never been swept, and an unstamped index",
            "cannot push its own absence. Run §The sweep in",
            "method/references/memory-routing.md; a run stamps what it reads.",
        ]
    try:
        last = max(date.fromisoformat(s) for s in stamps)
    except ValueError:
        return []
    if date.today() - last > QUARTER:
        return [
            f"Also due: this machine's memory was last swept {last}, over a",
            "quarter ago. Run §The sweep in method/references/memory-routing.md.",
        ]
    return []


def introduced_text(tool_input: dict) -> str:
    """What this call put on the page, whichever edit shape carried it."""
    for key in ("content", "new_string"):
        value = tool_input.get(key)
        if isinstance(value, str):
            return value
    edits = tool_input.get("edits")
    if isinstance(edits, list):
        return "\n".join(
            e.get("new_string", "") for e in edits if isinstance(e, dict)
        )
    return ""


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        sys.exit(0)
    if not isinstance(payload, dict):
        sys.exit(0)

    tool_input = payload.get("tool_input") or {}
    raw_path = tool_input.get("file_path") or ""
    if not raw_path:
        sys.exit(0)

    target = Path(raw_path)
    if target.suffix.lower() not in (".md", ".markdown"):
        sys.exit(0)

    repo = repo_root(payload.get("cwd") or "")
    try:
        if not in_memory_dir(target, repo):
            sys.exit(0)
    except OSError:
        sys.exit(0)

    # The file as it now stands, so an edit to a memory that is already a
    # pointer stays quiet. The text this call introduced is the fallback for a
    # file that cannot be read back.
    try:
        text = target.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        text = introduced_text(tool_input)

    # The two questions this guard asks, each with its own silence. The
    # routing question skips the index and falls silent once any pointer is in
    # the file; the claim question does neither — an artefact only cites the
    # claim it stands beside, and the index line is a second copy of the claim.
    claims = uncited_claims(text, introduced_text(tool_input))
    routing_due = target.name != INDEX_NAME and not POINTER.search(text)
    if not routing_due and not claims:
        sys.exit(0)

    message = [f"A memory was saved: {target.name}"]
    if routing_due:
        message += routing_lines()
    if claims:
        message += claim_lines(target, text, claims)
    message += [
        "",
        "Advisory: the memory is saved and nothing is blocked. This guard is",
        "silent on a memory that carries its pointer and cites its claims",
        "beside them.",
    ]
    if routing_due:
        nudge = sweep_nudge(target)
        if nudge:
            message += [""] + nudge
        message += ["", "The rule: method/references/memory-routing.md"]
    print("\n".join(message), file=sys.stderr)
    sys.exit(2)


def routing_lines() -> list[str]:
    return [
        "",
        "Route it before moving on. Is this fact about the method, the",
        "machinery or the estate — something every other repo would otherwise",
        "pay to learn for itself?",
        "",
        "  · the method (a skill, a check, the standard)  → teomach-skills",
        "  · the machinery (guards, wiring, cockpit, judge, the flight system)",
        "                                                 → teomach-cockpit",
        "  · the estate (a service, a device, a supplier) → teomach-estate",
        "",
        "  File an issue on the owning repo, then rewrite this memory as a",
        "  pointer to it — the issue URL, or `owner/repo#123`. Name the",
        "  tracker: a bare `#123` does not say whose. That pointer is the",
        "  functional-pointer kind method/references/history-in-git.md",
        "  sanctions, so keep it.",
        "",
        "  A fact that is only true here — a machine quirk, a preference, the",
        "  state of work in flight — stays a fact. Nothing to file.",
        "",
        "  Lifecycle: a routed memory's pointer is deleted, index line first,",
        "  only once that moment is covered by a channel that PUSHES — a guard",
        "  that fires, an orientation line, a seed — or after a clean",
        "  cold-flight run. A pull-only channel (a cheatsheet, a references",
        "  page) keeps its pointer, which is the route back to it.",
    ]


def claim_lines(target: Path, text: str, claims: list[tuple[int, str]]) -> list[str]:
    lines = text.split("\n")
    out = [
        "",
        "This write claims a human decision without naming where it was made:",
        "",
    ]
    for line_no, phrase in claims[:5]:
        source = lines[line_no - 1].strip() if line_no <= len(lines) else ""
        out.append(f"  {target.name}:{line_no}  `{phrase}`")
        if source:
            out.append(f"      {source[:110]}")
    if len(claims) > 5:
        out.append(f"  … and {len(claims) - 5} more")
    out += [
        "",
        "  A claim that a human approved, ruled, agreed, signed off or",
        "  authorised names the artefact carrying that decision beside the",
        "  claim — the issue comment, the PR review, `owner/repo#123` — not",
        "  merely somewhere in the file. A pointer that is not beside the",
        "  claim does not point at it.",
        "",
        "  A ruling made in conversation is not an artefact yet: post it to",
        "  the issue first, then cite that comment. And a call that was this",
        "  session's own is recorded as its own — a lane's judgement, named",
        "  as one, needs no pointer.",
    ]
    return out


if __name__ == "__main__":
    main()
