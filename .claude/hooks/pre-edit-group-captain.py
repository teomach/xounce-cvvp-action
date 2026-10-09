#!/usr/bin/env python3
# Source: teomach-skills harness/hooks/pre-edit-group-captain.py —
# edit it there and re-run `scripts/wire-repo.py update`, never edit a copy.
"""PreToolUse (Write|Edit) — a Wing Commander editing a path the Group Captain
record governs is shown the entry before the edit lands.

WHAT IT DOES, exactly: where the repo's `.teomach.yml` names a Group Captain
and the edit's path is one an entry of `GROUP-CAPTAIN.md` governs, it prints
each such entry as written — ID, decision, where it was ruled — and lets the
edit through. The record itself, and `.teomach.yml` when the edit's text
touches the `group_captain` key, are warned on the same way: a change to
either is a clash by definition. The ranks and the clash are
`method/references/ranks.md` (teomach-skills); the record's syntax and its
parse are `_ranks.py`'s, beside this file, shared with the merge guard and
`scripts/rank-audit.py`.

IT WARNS AND NEVER BLOCKS. Touching a governed file is not itself a clash;
whether the change conflicts with the decision is the judge's reading
(`docs/checks/universal.md`). So the entry reaches the model as
`additionalContext` on an exit 0 — measured on Claude Code 2.1.289: the text
arrives and the edit goes ahead — and the operator sees it as a
`systemMessage`. An exit 2 here would refuse the edit, which is the one thing
this guard must not do.

WHO IS AT THE CONTROLS, read without the network. This runs on every Write and
Edit in every wired repo, so it cannot afford the `gh api user` round trip the
orientation and the merge guard make. It asks gh's own configuration for the
active account (`gh config get user`, 34 ms on the reference box) — and only
after an entry has matched, so an edit to an ungoverned path costs nothing
past the reads of two small files. A token in the environment overrides that
account and nothing local says whose it is, so then the login is unread.
Every way of not knowing resolves downward: the operator is a Wing Commander
and is warned. The Group Captain at the controls is told nothing.

WHERE IT STAYS SILENT: no `group_captain` key (no Group Captain, nothing to
warn about); a path outside the repo; a record that is missing or governs
nothing this path matches. A record it cannot parse is not its concern — the
orientation names a missing record, and `rank-audit.py` reports an unparsed
entry.

HONEST LIMITS: a missing hook FAILS OPEN; session-start-wired.sh tests for it
positively. Paths are matched as text against the record's globs — an edit
reached through a symlink, or a file moved onto a governed path by a shell
command, is not seen; the judge and the audit read the diff, and see it.
NotebookEdit is not matched.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

sys.dont_write_bytecode = True      # no __pycache__ inside the repo it guards
sys.path.insert(0, str(Path(__file__).resolve().parent))
try:
    from _ranks import (CONFIG_NAME, KEY, RECORD_NAME, configured_login,
                        parse_record, read_key, repo_key, same_login)
    from _target import repo_root
except ImportError as exc:
    print(
        "group-captain edit guard SKIPPED, not passed: a shared helper is not beside it "
        f"({exc}). Re-run `scripts/wire-repo.py update` from a teomach-skills clone.",
        file=sys.stderr,
    )
    sys.exit(0)


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, UnicodeDecodeError):
        return 0
    tool_input = payload.get("tool_input") or {}
    file_path = tool_input.get("file_path")
    if not isinstance(file_path, str) or not file_path:
        return 0

    repo = repo_root(payload.get("cwd") or "")
    captain = repo_key(repo)
    if not captain:
        return 0

    target = Path(file_path)
    if not target.is_absolute():
        target = repo / target
    rel = None
    for base in (repo, repo.resolve()):
        for t in (target, target.resolve()):
            try:
                rel = t.relative_to(base).as_posix()
                break
            except ValueError:
                continue
        if rel is not None:
            break
    if rel is None:
        return 0

    notes: list[str] = []
    if rel == RECORD_NAME:
        notes.append(
            f"`{RECORD_NAME}` is the Group Captain record. Any change to it is a clash, "
            "and it changes only through a PR the Group Captain merges."
        )
    elif rel == CONFIG_NAME:
        content = tool_input.get("content")
        if isinstance(content, str):            # Write: the whole file
            changes_key = read_key(content) != captain
        else:                                   # Edit: the text replaced, and its replacement
            old = tool_input.get("old_string") or ""
            new = tool_input.get("new_string") or ""
            changes_key = (KEY in old or KEY in new) and read_key(old) != read_key(new)
        if changes_key:
            notes.append(
                f"This edit changes the `{KEY}` key. Any change to it is a clash, and it "
                "changes only through a PR the Group Captain merges."
            )
    try:
        record = (repo / RECORD_NAME).read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        record = ""
    entries = [e for e in parse_record(record)[0] if e.governs(rel)]
    if not notes and not entries:
        return 0

    login, why = configured_login()
    if same_login(login, captain):
        return 0

    who = f"`{login}`" if login else f"login unread ({why})"
    lines = [
        f"GROUP CAPTAIN RECORD — `{rel}` is governed. At the controls: {who}, a Wing "
        f"Commander; the Group Captain here is `{captain}`.",
        *notes,
    ]
    for e in entries:
        lines += ["", e.text()]
    lines += [
        "",
        "This is a warning, not a refusal: the edit goes ahead. Whether the change "
        "conflicts with a decision is the judge's reading. A PR that clashes is "
        "labelled `group-captain`, names the entry IDs in its body, and is left for "
        "the Group Captain to merge (method/references/ranks.md, teomach-skills).",
        "— pre-edit-group-captain.py, this repo's resident guard",
    ]
    text = "\n".join(lines)
    print(json.dumps({
        "hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": text},
        "systemMessage": text,
    }))
    return 0


if __name__ == "__main__":
    sys.exit(main())
