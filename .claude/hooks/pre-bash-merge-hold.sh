#!/usr/bin/env bash
# Source: teomach-skills harness/hooks/pre-bash-merge-hold.sh —
# edit it there and re-run `scripts/wire-repo.py update`, never edit a copy.
# PreToolUse (Bash) — a Wing Commander does not merge a PR held for the Group
# Captain.
#
# WHAT IT REFUSES, exactly and only. Where the PR's repo names a Group Captain
# (`group_captain` in `.teomach.yml`) and the operator is not that login, a
# `gh pr merge` of a PR that
#
#   · carries the `group-captain` label, or
#   · whose diff changes `GROUP-CAPTAIN.md`, or
#   · whose diff changes the `group_captain` key,
#
# is refused, naming which. Every other PR passes; the Group Captain at the
# controls passes all of them; a repo with no key passes everything. The ranks
# and the clash are `method/references/ranks.md` (teomach-skills), and the
# merge itself is `method/references/the-gate.md`'s. A clash the judge found
# in a governed path is held by the label the session applies, which is the
# first case; the other two are clashes by definition and need no judgement,
# so they are matched by path and a stripped label does not hide them.
#
# A PR IT CANNOT READ IS REFUSED, and the refusal says why: no `gh`, `gh` not
# answering, a list of changed files GitHub cut short, no diff for
# `.teomach.yml`. Passing a merge it could not read would make the hold a
# matter of network weather. The Group Captain's own merge needs the PR read
# too — their login is read from GitHub, and an unreadable login resolves
# downward to Wing Commander, never up.
#
# WHERE THE KEY IS READ: from the PR's BASE BRANCH on GitHub, never the
# working tree. The tree a merge is typed in is often the PR's own branch,
# and a branch that deletes the key would otherwise wave itself through. So
# every `gh pr merge` in a wired repo pays three or four GitHub reads, keyed
# or not — affordable on a merge, which is rare, and never paid by any other
# command: the walk below exits before Python starts for everything that is
# not a merge.
#
# THERE IS NO HATCH, unlike the PR gate. A stated reason is the right release
# for a gate that cannot run; this guard holds a decision that belongs to
# someone else, and the person it belongs to passes it by being at the
# controls.
#
# HOW IT READS THE COMMAND: `_walk.sh`, shared with pre-bash-pr-gate.sh — a
# structural walk for `gh pr merge` in command position, with the directory
# each one runs in and the words after it. `gh pr merge` with no PR merges
# the current branch's, so it is read with `gh pr view` in that directory and
# no PR named; `-R` is passed through. The verdict is `_ranks.py merge`,
# beside this file, which shares its parse of the record and the key with
# the edit guard and `scripts/rank-audit.py`.
#
# HONEST LIMITS: a missing hook FAILS OPEN; session-start-wired.sh tests for
# it positively. The walk concedes what the PR gate's concedes — a quoted
# `gh`, a `bash -c` string, an alias. Only Claude Code runs it, and the
# GitHub UI's merge button is not a tool call: a merge made there is found
# afterwards by `scripts/rank-audit.py` (teomach-skills).

set -uo pipefail
HERE="$(dirname "${BASH_SOURCE[0]}")"
# shellcheck source=_payload.sh
. "$HERE/_payload.sh"
# shellcheck source=_walk.sh
. "$HERE/_walk.sh"

payload_read
cmd="$(json_str tool_input.command)"
cwd="$(json_str cwd)"
[ -n "$cmd" ] || exit 0

gh_pr_walk merge "" "$cmd" "${cwd:-.}" || exit 0

if ! command -v python3 >/dev/null 2>&1 || [ ! -r "$HERE/_ranks.py" ]; then
    {
        echo "BLOCKED: \`gh pr merge\` — this guard cannot tell whether the PR is held"
        echo "for the Group Captain: it needs python3 and _ranks.py beside it, and"
        echo "has $(command -v python3 >/dev/null 2>&1 && echo "no _ranks.py" || echo "no python3")."
        echo "Re-run \`scripts/wire-repo.py update\` from a teomach-skills clone."
        echo
        echo "— pre-bash-merge-hold.sh, this repo's resident guard"
    } >&2
    exit 2
fi

status=0
for n in "${!HIT_DIR[@]}"; do
    args=()
    [ -n "${HIT_ARGS[n]}" ] && IFS=$'\x1f' read -r -a args <<<"${HIT_ARGS[n]}"
    PYTHONDONTWRITEBYTECODE=1 python3 "$HERE/_ranks.py" merge "${HIT_DIR[n]}" "${args[@]}" || status=2
done
exit $status
