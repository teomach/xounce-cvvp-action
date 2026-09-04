#!/usr/bin/env bash
# Stop — a turn ended with work that is not in a commit.
#
# WHY THIS EXISTS. The probe this harness answers held four hours of work and
# made zero commits. Nothing in the session was wrong at any single moment; the
# omission only existed in aggregate, which is exactly the shape a human never
# notices and a hook always can.
#
# WARN, NEVER BLOCK. Uncommitted work is not an error — it is the normal state
# of a turn in the middle of something. The only reading that would justify
# blocking is "the session is over", and Stop cannot tell that from "the model
# finished a sentence". So this reports and gets out of the way.
#
# IT MEASURES UNRECORDED TIME, NOT DIRTINESS. Stop fires at the end of every
# turn, and a warning on every dirty tree would be noise within minutes — the
# guard would be switched off, and the thing it exists for is not dirtiness
# anyway. It is the gap since the last commit, which is what four hours and
# zero commits actually were. So the tree must be dirty AND the last commit
# older than QUIET_FOR before this speaks; a commit silences it outright.
#
# That reading is also what keeps the guard writing nothing at all. A stamp
# file would have to live somewhere, and in a worktree — this repo's own
# pattern for concurrent sessions — the git directory is physically inside a
# sibling clone, which is exactly the "no guard writes outside the repo"
# criterion. Deriving the answer from git leaves nothing to put anywhere.

set -uo pipefail
# shellcheck source=_payload.sh
. "$(dirname "${BASH_SOURCE[0]}")/_payload.sh"

QUIET_FOR="${TEOMACH_UNCOMMITTED_AFTER:-1200}"   # seconds since the last commit

payload_read
REPO="$(repo_root "$(json_str cwd)")"

git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
status=$(git -C "$REPO" status --porcelain 2>/dev/null) || exit 0
[ -n "$status" ] || exit 0

tracked=$(printf '%s\n' "$status" | grep -vc '^??' || true)
untracked=$(printf '%s\n' "$status" | grep -c '^??' || true)
[ "$tracked" -gt 0 ] || [ "$untracked" -gt 0 ] || exit 0

# How long this work has been unrecorded. A repo with no commit at all has been
# unrecorded since it existed, which is the probe's exact state.
last=$(git -C "$REPO" log -1 --format=%ct 2>/dev/null)
if [ -n "$last" ]; then
    idle=$(( $(date +%s) - last ))
    [ "$idle" -ge "$QUIET_FOR" ] || exit 0
    since="$(( idle / 60 )) minutes since the last commit"
else
    since="no commit in this repo yet"
fi

sample=$(printf '%s\n' "$status" | head -n5 | sed 's/^/    /')
more=$(printf '%s\n' "$status" | wc -l)

msg="Uncommitted work in $(basename "$REPO"): $tracked tracked file(s) changed"
[ "$untracked" -gt 0 ] && msg="$msg, $untracked untracked"
msg="$msg, $since. Commit on a branch — an unrecorded four hours is the failure this guard exists for."

{
    echo "$msg"
    echo "$sample"
    [ "$more" -gt 5 ] && echo "    … and $(( more - 5 )) more"
} >&2

esc() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr -d '\n'; }
printf '{"systemMessage":"%s"}\n' "$(esc "$msg")"
exit 0
