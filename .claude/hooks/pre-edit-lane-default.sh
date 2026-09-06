#!/usr/bin/env bash
# PreToolUse (Write|Edit) — build work in a cockpit session routes to a lane,
# or says in one line why it is staying in these hands.
#
# THE BOUNDARY THIS NAMES. The lane default has two escape routes and the v6
# set guarded only one: pre-agent-lane-dispatch.sh stops a lane leaving as a
# subagent, but a session building substantive work with its own Edit/Write
# hands passed unremarked. The observed shape (two independent specimens, one
# with no deadline at all): work arrives in conversation, no issue exists, so
# the lane default's trigger never fires and building starts by momentum —
# the deviation feels like responsiveness. The method has to speak at the
# moment of choice, and for this route nothing did.
#
# WHAT IT ASKS IS A DECLARATION, NEVER PERMISSION. The refusal prints two
# forms and either unblocks the session immediately — an overnight leader
# declares and continues, no human in the loop:
#
#     git config teomach.<session_id>.route "LANE: #<issue>"
#     git config teomach.<session_id>.route "STRAIGHT_THROUGH: <one sentence>"
#
# LANE says the work is routed properly — an issue exists and a wingman will
# carry it, and edits here are the leader's closeout around that. It rides in
# git config keyed by session id, so it is scoped to this repo and this
# conversation (a restarted leader re-declares — its session id is new),
# costs one transcript-visible command, and needs no guard to write anything
# (a guard only reads and refuses). Keys of dead sessions linger in
# .git/config; they are one line each and match nothing again.
#
# WHERE IT STAYS SILENT, deliberately — every check is a cheap read:
#
#   · Outside the build surface. The lane default is the cockpit's whatever
#     the repo is working on (ruled 2026-09-06), so with no `build_paths:`
#     in .teomach.yml the whole tree is the surface; the key NARROWS it,
#     for a type that knows its low-noise signal (board-games: targets/,
#     components/). The shared shape is _payload.sh's build_paths_read /
#     in_build_surface.
#   · No $ZELLIJ — a bare terminal session is not the cockpit, and the lane
#     default is a cockpit discipline. An Alt-t tab inside a flight counts as
#     the cockpit, which is the right reading: it shares the board.
#   · A linked worktree — that is a wingman's lane, whose whole job is build
#     edits. Main checkout only: the leader's seat.
#   · The edit lands outside every build path, or inside one but below the
#     signal: no new-to-git file, fewer than LANE_THRESHOLD (_payload.sh;
#     TEOMACH_LANE_THRESHOLD overrides, default 3) distinct build files
#     dirty. Small closeout passes without a word — the leeway is the
#     point; the declaration prices only the file that reaches the
#     threshold.
#
# HONEST LIMITS: a missing hook FAILS OPEN (measured on this set's siblings);
# session-start-wired.sh tests for this guard positively. Paths are prefix
# text — a build reached through a symlink or a rename is not seen. And the
# declaration's sentence is read for length, not quality: the judge and the
# stop tally, not this guard, keep a stretched declaration honest.
#
# WHY EXIT 2: the model sees the stderr and acts on it, so the session
# declares (or dispatches the lane) and continues with no human in the loop.

set -uo pipefail
# shellcheck source=_payload.sh
. "$(dirname "${BASH_SOURCE[0]}")/_payload.sh"

# Not a cockpit session — not this guard's ground.
[ -n "${ZELLIJ:-}" ] || exit 0

payload_read
file="$(json_str tool_input.file_path)"
[ -n "$file" ] || exit 0

REPO="$(repo_root "$(json_str cwd)")"
[ -f "$REPO/.teomach.yml" ] || exit 0
build_paths_read "$REPO"

git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# A linked worktree is a lane; only the main checkout is the leader's seat.
gitdir=$(git -C "$REPO" rev-parse --absolute-git-dir 2>/dev/null)
common=$(git -C "$REPO" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
[ -n "$gitdir" ] && [ "$gitdir" = "$common" ] || exit 0

# The edited file, relative to the repo — outside it, or outside the build
# surface, is not build work.
case "$file" in
    "$REPO"/*) rel="${file#"$REPO"/}" ;;
    /*)        exit 0 ;;
    *)         rel="$file" ;;
esac
in_build_surface "$rel" || exit 0

# A routing already declared for this session settles it — if it parses.
# route_settled is the guard pair's one shape (_payload.sh); a declared-but-
# malformed route falls through to the refusal, which shows the forms.
sid="$(json_str session_id)"
route=""
[ -n "$sid" ] && route=$(git -C "$REPO" config --get "teomach.$sid.route" 2>/dev/null)
[ -n "$route" ] && route_settled "$route" && exit 0

# The signal: a file git has never recorded under a build path, or the
# distinct dirty build files reaching the threshold. Below both, closeout
# passes in silence.
signal=""
if ! git -C "$REPO" ls-files --error-unmatch -- "$rel" >/dev/null 2>&1; then
    signal="a new file under a build path ($rel) — closeout rarely creates one"
else
    dirty=0
    while IFS= read -r line; do
        f="${line:3}"; f="${f#\"}"
        in_build_surface "$f" && dirty=$((dirty + 1))
    done < <(git -C "$REPO" status --porcelain 2>/dev/null)
    [ "$dirty" -ge "$LANE_THRESHOLD" ] &&
        signal="$dirty distinct build files already changed this session — the first edit or two is closeout; this is a build"
fi
[ -n "$signal" ] || exit 0

{
    echo "BLOCKED: this edit is build work in the cockpit with no routing declared —"
    echo "$signal."
    echo
    echo "Build work flies as a lane by default. Declare this piece's routing and"
    echo "continue — one command, nothing here waits on the human:"
    echo
    echo "  the work has (or now gets) an issue and a wingman carries it:"
    echo "      git config teomach.$sid.route \"LANE: #<issue>\""
    echo
    echo "  or it is genuinely this session's to build, said in a sentence you"
    echo "  would defend on the board ($ROUTE_REASON_MIN characters or more):"
    echo "      git config teomach.$sid.route \"STRAIGHT_THROUGH: <why this piece stays in-hand>\""
    echo
    echo "A declaration names one piece of work; when a later, separate piece"
    echo "arrives, re-declare (same command, new sentence) rather than letting the"
    echo "old line stretch — the observed failure is exactly one declaration"
    echo "becoming a day-wide exemption. This guard cannot tell the pieces apart;"
    echo "the turn-end tally and the judge are what keep the stretch visible."
    echo
    echo "— pre-edit-lane-default.sh, this repo's resident guard"
} >&2
exit 2
