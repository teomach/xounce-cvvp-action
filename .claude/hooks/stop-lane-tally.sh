#!/usr/bin/env bash
# Source: teomach-skills harness/hooks/stop-lane-tally.sh —
# edit it there and re-run `scripts/wire-repo.py update`, never edit a copy.
# Stop — uncommitted build-path work in a cockpit session, tallied for the
# human at turn end.
#
# WHY THIS EXISTS. The specimens behind the lane-default guard were noticed
# only because the human asked "why are you not flying wingmen?" — twice.
# This puts that question's evidence in the transcript before it has to be
# asked: one line, at the end of a turn, when a cockpit session in a repo's
# main checkout holds uncommitted changes on the build surface (the whole
# tree, unless `build_paths` narrows it — _payload.sh).
#
# WARN, NEVER BLOCK — the stop-uncommitted.sh reading: a turn ending
# mid-work is normal, and Stop cannot tell "done" from "paused". It speaks as
# `systemMessage` (to the human, not the model's context): the model already
# met the pre-edit guard at the moment of choice; this line is for the eyes
# the guard exists to spare.
#
# WHAT SILENCES IT: committing (porcelain goes quiet — the same act that
# silences stop-uncommitted), or a parsed routing declaration riding no
# more build files than one piece should (LANE_THRESHOLD, _payload.sh).
# Undeclared, it speaks from the first file — one or two undeclared build
# files are exactly the quiet drift a tally is for. Declared, it speaks
# only past the threshold, quoting the declaration — that is the
# stretched-declaration watch the pre-edit guard names this tally as the
# backstop for, and the observed failure it exists to surface: one
# declaration quietly becoming a day-wide exemption. Either way it nags a
# state, not a history: only while the files sit uncommitted.
#
# It derives everything from git and the payload, and writes nothing — the
# stop-uncommitted.sh criterion, kept.

set -uo pipefail
# shellcheck source=_payload.sh
. "$(dirname "${BASH_SOURCE[0]}")/_payload.sh"

[ -n "${ZELLIJ:-}" ] || exit 0

payload_read
REPO="$(repo_root "$(json_str cwd)")"
[ -f "$REPO/.teomach.yml" ] || exit 0
# The surface is the pair's shared shape (_payload.sh): whole tree unless
# build_paths narrows it.
build_paths_read "$REPO"

git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
gitdir=$(git -C "$REPO" rev-parse --absolute-git-dir 2>/dev/null)
common=$(git -C "$REPO" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
[ -n "$gitdir" ] && [ "$gitdir" = "$common" ] || exit 0

# The session's declared routing, if any — route_settled is the guard
# pair's one shape (_payload.sh). A settled route changes what the tally
# watches for (stretch past the threshold), never whether it can watch.
sid="$(json_str session_id)"
route=""
if [ -n "$sid" ]; then
    route=$(git -C "$REPO" config --get "teomach.$sid.route" 2>/dev/null)
    route_settled "${route:-}" || route=""
fi

# The count and its sample are the pair's one loop (_payload.sh), so this
# tally and the pre-edit refusal are reading the same tree the same way.
dirty_build_files "$REPO"
[ "$DIRTY_COUNT" -gt 0 ] || exit 0

# The arms differ in two clauses and nothing else — what the state is, and
# what to do about it. The sentence around them is built once, below, so the
# count, the repo name, the sample and its "…" cannot come to differ between
# a declared turn and an undeclared one.
if [ -n "$route" ]; then
    # Declared: quiet within one piece's worth, loud when the ride grows.
    [ "$DIRTY_COUNT" -gt "$LANE_THRESHOLD" ] || exit 0
    state="riding under one declaration — \"$route\""
    advice="A declaration names one piece of work; if this is a second, it re-declares or flies as a lane."
else
    state="with no lane and no routing declaration"
    advice="More than closeout wants an issue and a wingman."
fi

msg="Cockpit tally: $DIRTY_COUNT uncommitted build-path file(s) in $(basename "$REPO") $state ($DIRTY_SAMPLE"
[ "$DIRTY_COUNT" -gt "$DIRTY_SAMPLE_MAX" ] && msg="$msg, …"
msg="$msg). $advice"

esc() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr -d '\n'; }
printf '{"systemMessage":"%s"}\n' "$(esc "$msg")"
exit 0
