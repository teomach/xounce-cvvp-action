#!/usr/bin/env python3
# Source: teomach-skills harness/hooks/_ranks.py —
# edit it there and re-run `scripts/wire-repo.py update`, never edit a copy.
"""Shared by everything that reads a repo's Group Captain record and key.

Three readers, one parse. `pre-edit-group-captain.py` warns a Wing Commander
at an edit to a governed path; `pre-bash-merge-hold.sh` refuses a Wing
Commander's merge of a clash, and runs this file for its verdict (`merge`,
below); `scripts/rank-audit.py` finds a merge made round the hold afterwards.
Each asks the same questions — which login the repo names, what the record's
entries govern, whether a diff changed the key — and three answers that
differ would give a session three verdicts on one change, none visible from
inside the others. So the answers live here, once. The ranks themselves are
`method/references/ranks.md` (teomach-skills); this file restates none of it.

THE RECORD'S ONE SYNTAX, which `scripts/wire-repo.py`'s `RECORD_SEED` states
for every repo it creates a record in:

    ## GC-<n> — <a few words>

    - **Decision:** <the position that holds>
    - **What it governs:** `<path or glob>`, `<path or glob>`
    - **Where it was ruled:** <owner/repo#n>, the comment "<heading>"

An entry is a heading beginning `GC-<n>`; its governed paths are the
backticked spans of its "What it governs" field, which may run over several
lines until the next field or heading. The parse is lenient about the
spelling round that — any heading level, a bullet or none, bold or not,
"Governs" for short — and strict about the two things that matter: the ID in
a heading, and the paths in backticks. A backticked span with no `/`, `.` or
glob character is a named rule, which a path cannot match. A fenced block is
an example, never an entry.

Imported by the edit guard and the audit, and run by the merge guard. A guard
importing it writes no bytecode beside itself — `.claude/hooks/` is inside the
repo it guards — so every importer sets `sys.dont_write_bytecode` first.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from urllib.parse import quote, urlparse

RECORD_NAME = "GROUP-CAPTAIN.md"
CONFIG_NAME = ".teomach.yml"
KEY = "group_captain"
LABEL = "group-captain"

# GitHub's own shape for a login — orient.py's, so the orientation and the
# guards agree on what counts as one.
LOGIN = re.compile(r"[A-Za-z0-9](?:[A-Za-z0-9]|-(?=[A-Za-z0-9])){0,38}")

# A diff line that adds or removes the key. A change to the key is a clash by
# definition, whatever it changes it to.
KEY_LINE = re.compile(r"^[+-]\s*" + KEY + r"\s*:")

# The key as a line of `.teomach.yml`: top level, a scalar, quotes and a
# trailing comment allowed. The installer writes it bare.
KEY_VALUE = re.compile(r"^" + KEY + r"\s*:\s*(.*?)\s*(?:#.*)?$")


def read_key(text: str) -> str | None:
    """The login `.teomach.yml` text names as Group Captain, or None where it
    names none. A value that is not a login is returned as written, so a caller
    can refuse it rather than read it as no key."""
    for line in text.splitlines():
        m = KEY_VALUE.match(line)
        if m:
            value = m.group(1).strip().strip("'\"")
            return value or None
    return None


def repo_key(repo: Path) -> str | None:
    """`read_key` of the working tree's `.teomach.yml`, None where there is none."""
    try:
        return read_key((repo / CONFIG_NAME).read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError):
        return None


# --------------------------------------------------------------------------
# The record
# --------------------------------------------------------------------------

HEADING = re.compile(r"^#{1,6}\s*\**(GC-\d+)\b")
FIELD_START = re.compile(
    r"^\s*(?:[-*+]\s+)?[*_]*(the decision|decision|what it governs|governs|where it was ruled|ruled)[*_]*\s*[:：]",
    re.IGNORECASE,
)
GOVERNS = re.compile(r"^\s*(?:[-*+]\s+)?[*_]*(?:what it )?governs[*_]*\s*[:：]", re.IGNORECASE)
SPAN = re.compile(r"`([^`\n]+)`")
PATHLIKE = re.compile(r"^[^\s]*[/.*?][^\s]*$")
FENCE = re.compile(r"^\s*(```|~~~)")


@dataclass
class Entry:
    id: str
    paths: list[str] = field(default_factory=list)  # repo-relative paths or globs
    rules: list[str] = field(default_factory=list)  # named rules, not matchable by path
    has_governs: bool = False
    lines: list[str] = field(default_factory=list)  # the entry as written, heading first

    def governs(self, rel: str) -> bool:
        return any(glob_regex(p).match(rel) for p in self.paths)

    def text(self) -> str:
        return "\n".join(self.lines).strip()


def parse_record(text: str) -> tuple[list[Entry], list[str]]:
    """The record's entries, and what in it could not be parsed."""
    entries: list[Entry] = []
    unread: list[str] = []
    current: Entry | None = None
    in_governs = False
    in_fence = False
    visible: list[str] = []
    for line in text.splitlines():
        if FENCE.match(line):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        visible.append(line)
        m = HEADING.match(line)
        if m:
            current = Entry(m.group(1), lines=[line])
            entries.append(current)
            in_governs = False
            continue
        if line.startswith("#"):
            current = None  # any other heading ends the entry above it
        if current is None:
            continue
        current.lines.append(line)
        if GOVERNS.match(line):
            current.has_governs = True
            in_governs = True
        elif FIELD_START.match(line):
            in_governs = False
        if in_governs:
            for span in SPAN.findall(line):
                span = span.strip()
                (current.paths if PATHLIKE.match(span) else current.rules).append(span)
    seen = {e.id for e in entries}
    mentioned = set(re.findall(r"\bGC-\d+\b", "\n".join(visible)))
    for gid in sorted(mentioned - seen, key=lambda s: int(s[3:])):
        unread.append(f"{RECORD_NAME} mentions {gid} but no entry headed {gid} was parsed")
    for e in entries:
        if not e.has_governs:
            unread.append(f"{RECORD_NAME} {e.id} has no \"What it governs\" field, so it cannot be matched")
    return entries, unread


def glob_regex(pattern: str) -> re.Pattern:
    """A repo-relative path or glob as a regex. `**` crosses `/`, `*` and `?`
    do not, and a pattern also covers everything beneath it as a directory."""
    pat = pattern.strip()
    while pat.startswith("./"):
        pat = pat[2:]
    pat = pat.lstrip("/")
    if pat.endswith("/"):
        pat += "**"
    out, i = [], 0
    while i < len(pat):
        if pat.startswith("**/", i):
            out.append("(?:.*/)?")
            i += 3
        elif pat.startswith("**", i):
            out.append(".*")
            i += 2
        elif pat[i] == "*":
            out.append("[^/]*")
            i += 1
        elif pat[i] == "?":
            out.append("[^/]")
            i += 1
        else:
            out.append(re.escape(pat[i]))
            i += 1
    return re.compile("".join(out) + r"(?:/.*)?\Z")


# --------------------------------------------------------------------------
# Who is at the controls
#
# Two reads of one answer, because the two guards can afford different
# things. The merge guard runs only on `gh pr merge` and asks GitHub, as the
# orientation does (`gh api user`). The edit guard runs on every Write and
# Edit in every wired repo, so it asks gh's own configuration for the active
# account instead — `gh config get user`, measured at 34 ms on the reference
# box and no network. Both resolve every way of not knowing downward: no
# path makes an unidentified operator the Group Captain.
# --------------------------------------------------------------------------

GH_TIMEOUT = 6


def _gh(*args: str, cwd: str | None = None, timeout: int = GH_TIMEOUT) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["gh", *args], cwd=cwd, capture_output=True, text=True,
        timeout=timeout, stdin=subprocess.DEVNULL,
    )


def configured_login() -> tuple[str | None, str]:
    """The login gh's configuration names as active, read without the network.

    A token in the environment (`GH_TOKEN`, `GITHUB_TOKEN`) overrides that
    account for every `gh` call, and nothing local says whose token it is —
    so with one set, the login is unread rather than guessed."""
    for var in ("GH_TOKEN", "GITHUB_TOKEN"):
        if os.environ.get(var):
            return None, f"`{var}` is set, so the configured account may not be the one at the controls"
    try:
        done = _gh("config", "get", "user", "-h", "github.com", timeout=2)
    except FileNotFoundError:
        return None, "no `gh` on this machine"
    except subprocess.TimeoutExpired:
        return None, "`gh` did not answer in 2 s"
    except OSError as exc:
        return None, f"`gh` would not run ({exc.__class__.__name__})"
    login = done.stdout.strip()
    if done.returncode != 0 or not LOGIN.fullmatch(login):
        return None, "`gh` names no signed-in account"
    return login, ""


def github_login(host: str = "github.com", cwd: str | None = None) -> tuple[str | None, str]:
    """The login GitHub says the token belongs to — the orientation's read."""
    try:
        done = _gh("api", "--hostname", host, "user", "--jq", ".login", cwd=cwd)
    except FileNotFoundError:
        return None, "no `gh` on this machine"
    except subprocess.TimeoutExpired:
        return None, f"`gh` did not answer in {GH_TIMEOUT} s"
    except OSError as exc:
        return None, f"`gh` would not run ({exc.__class__.__name__})"
    login = done.stdout.strip()
    if done.returncode != 0 or not LOGIN.fullmatch(login):
        return None, "`gh` gave no login"
    return login, ""


def same_login(a: str | None, b: str | None) -> bool:
    return bool(a and b and a.casefold() == b.casefold())


# --------------------------------------------------------------------------
# The merge verdict — `pre-bash-merge-hold.sh` runs this once per
# `gh pr merge` its walk found, with the directory that merge runs in and the
# words typed after `merge`. Exit 0 passes; exit 2 refuses, on stderr.
# --------------------------------------------------------------------------

# `gh pr merge`'s flags that take a value, so a value is never read as the
# PR. Taken from `gh pr merge --help` at gh 2.102.0.
VALUE_FLAGS = {"-R", "--repo", "-b", "--body", "-F", "--body-file", "-t", "--subject",
               "-A", "--author-email", "--match-head-commit"}


class Unread(Exception):
    """The PR, or the part of it the verdict turns on, could not be read."""


def parse_merge_args(args: list[str]) -> tuple[str | None, str | None, bool]:
    """The PR as typed (None: the current branch's), the `-R` repo, and
    whether this invocation merges at all (`--disable-auto` and `--help` do
    not)."""
    selector = repo = None
    merges = True
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--":
            if i + 1 < len(args) and selector is None:
                selector = args[i + 1]
            break
        if a in ("--disable-auto", "--help", "-h"):
            merges = False
        name, eq, value = a.partition("=")
        if a.startswith("--") and eq and name in VALUE_FLAGS:
            if name == "--repo":
                repo = value
        elif a in VALUE_FLAGS:
            if a in ("-R", "--repo") and i + 1 < len(args):
                repo = args[i + 1]
            i += 1
        elif a.startswith("-R") and len(a) > 2:
            repo = a[2:]
        elif a.startswith("-") and a != "-":
            pass
        elif selector is None:
            selector = a
        i += 1
    return selector, repo, merges


def _call(what: str, *args: str, cwd: str) -> str:
    try:
        done = _gh(*args, cwd=cwd)
    except FileNotFoundError:
        raise Unread("there is no `gh` on this machine to read it with")
    except subprocess.TimeoutExpired:
        raise Unread(f"`gh` did not answer in {GH_TIMEOUT} s while reading {what}")
    except OSError as exc:
        raise Unread(f"`gh` would not run ({exc.__class__.__name__})")
    if done.returncode != 0:
        detail = (done.stderr.strip() or done.stdout.strip() or f"exit {done.returncode}").splitlines()[0]
        raise Unread(f"`gh` could not read {what}: {detail}")
    return done.stdout


def merge_verdict(run_dir: str, args: list[str]) -> tuple[int, str]:
    """0 and nothing to say, or 2 and the refusal."""
    selector, repo, merges = parse_merge_args(args)
    if not merges:
        return 0, ""
    typed = "gh pr merge" + (f" {selector}" if selector else "") + (f" -R {repo}" if repo else "")
    try:
        view = ["pr", "view", *([selector] if selector else []), *(["-R", repo] if repo else []),
                "--json", "number,url,labels,baseRefName,changedFiles"]
        try:
            pr = json.loads(_call("the PR", *view, cwd=run_dir))
        except json.JSONDecodeError as exc:
            raise Unread(f"`gh pr view` returned something that is not JSON ({exc})")
        url = urlparse(pr.get("url", ""))
        parts = url.path.strip("/").split("/")
        if not url.hostname or len(parts) < 4 or parts[2] != "pull":
            raise Unread(f"`gh pr view` gave no PR address it could use ({pr.get('url')!r})")
        host, slug, number = url.hostname, f"{parts[0]}/{parts[1]}", pr.get("number")
        base = pr.get("baseRefName") or ""

        # The key as the BASE branch holds it on GitHub — never the working
        # tree's, which may be the very branch that deletes the key.
        try:
            config = _call(
                f"{slug}'s {CONFIG_NAME} on {base}",
                "api", "--hostname", host, "-H", "Accept: application/vnd.github.raw",
                f"repos/{slug}/contents/{CONFIG_NAME}?ref={quote(base, safe='')}", cwd=run_dir,
            )
        except Unread as exc:
            if "404" in str(exc):
                return 0, ""  # not a wired repo: no key, so no Group Captain
            raise
        captain = read_key(config)
        if captain is None:
            return 0, ""
        if not LOGIN.fullmatch(captain):
            raise Unread(f"{slug}'s `{KEY}: {captain}` is not a GitHub login, so whose merge this is cannot be settled")

        login, why = github_login(host, cwd=run_dir)
        if same_login(login, captain):
            return 0, ""

        reasons = []
        if LABEL in [lab.get("name") for lab in pr.get("labels", [])]:
            reasons.append(f"it carries the `{LABEL}` label")
        out = _call(
            f"#{number}'s changed files", "api", "--hostname", host, "--paginate",
            f"repos/{slug}/pulls/{number}/files",
            "--jq", ".[] | {filename, previous: .previous_filename, patch}", cwd=run_dir,
        )
        try:
            files = [json.loads(ln) for ln in out.splitlines() if ln.strip()]
        except json.JSONDecodeError as exc:
            raise Unread(f"#{number}'s changed files came back as something that is not JSON ({exc})")
        expected = pr.get("changedFiles")
        if isinstance(expected, int) and len(files) < expected:
            raise Unread(f"GitHub lists {expected} changed files on #{number} and returned {len(files)}")
        for f in files:
            names = [n for n in (f.get("filename"), f.get("previous")) if n]
            if RECORD_NAME in names:
                reasons.append(f"its diff changes `{RECORD_NAME}`")
            if CONFIG_NAME in names:
                patch = f.get("patch")
                if patch is None:
                    raise Unread(f"GitHub gave no diff for {CONFIG_NAME} on #{number}, so a change to the `{KEY}` key cannot be ruled out")
                if any(KEY_LINE.match(ln) for ln in patch.splitlines()):
                    reasons.append(f"its diff changes the `{KEY}` key")
    except Unread as exc:
        return 2, _refusal_unread(typed, str(exc))
    if not reasons:
        return 0, ""
    who = f"`{login}`" if login else f"an operator whose login could not be read ({why})"
    return 2, _refusal_held(f"{slug}#{number}", captain, who, list(dict.fromkeys(reasons)))


def _refusal_held(pr: str, captain: str, who: str, reasons: list[str]) -> str:
    return "\n".join([
        f"BLOCKED: {pr} is held for the Group Captain (`{captain}`) — " + "; ".join(reasons) + ".",
        "",
        f"At the controls: {who}, a Wing Commander. A change to the Group Captain",
        f"record or the `{KEY}` key, and a PR labelled `{LABEL}`, is a clash, and",
        "a clash's merge is the Group Captain's. Decline the instruction to merge",
        "once, naming why, and leave the PR for them: the label is their queue.",
        "The ranks and the clash are `method/references/ranks.md`, and the merge",
        "is `method/references/the-gate.md` (teomach-skills).",
        "",
        "There is no hatch. The Group Captain at the controls merges it.",
        "",
        "— pre-bash-merge-hold.sh, this repo's resident guard",
    ])


def _refusal_unread(typed: str, why: str) -> str:
    return "\n".join([
        f"BLOCKED: `{typed}` — this guard could not read the PR, so it cannot tell",
        "whether the merge is held for the Group Captain.",
        "",
        f"Why: {why}.",
        "",
        "A merge it cannot read is refused rather than passed. Fix what is named",
        "above and run the merge again; nothing here needs bypassing.",
        "",
        "— pre-bash-merge-hold.sh, this repo's resident guard",
    ])


def main(argv: list[str]) -> int:
    if len(argv) < 2 or argv[0] != "merge":
        print("usage: _ranks.py merge <dir the merge runs in> [words after `gh pr merge` ...]", file=sys.stderr)
        return 2
    code, message = merge_verdict(argv[1], argv[2:])
    if message:
        print(message, file=sys.stderr)
    return code


if __name__ == "__main__":
    sys.dont_write_bytecode = True
    sys.exit(main(sys.argv[1:]))
