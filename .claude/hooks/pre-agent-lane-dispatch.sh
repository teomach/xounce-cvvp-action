#!/usr/bin/env bash
# PreToolUse (Agent) — no lane leaves this session as a subagent.
#
# THE BOUNDARY THIS NAMES. The harness's Agent tool can do everything a lane
# needs — a worktree of its own, an issue-shaped brief, a background run — and
# nothing a lane owes: a subagent has no board row, no attachable session, no
# judge verbs in its shell, and no dispatch-line pins (full model id, retry
# watchdog). Approved lanes fly as `wingman` tabs from the cockpit; the Agent
# tool is for searches and analyses that stay inside this session. The
# harness makes the wrong choice the native one — the tool sits in every
# session, does everything a lane needs, and asks nothing — so the method
# has to speak at exactly the moment of choice. This guard is that sentence.
#
# MEASURED (Claude Code 2.1.224, 2026-08-18, capture hook on a live session):
# the PreToolUse payload for a subagent call carries `tool_name: "Agent"` —
# that is the matcher's contract — and `tool_input` passes the call through
# verbatim: `description`, `prompt`, `subagent_type`, and, only when the
# caller gave them, `run_in_background` and `isolation` (the literal string
# "worktree"). A call without isolation has no `isolation` key at all, so an
# empty read here means "not requested", not "unknown".
#
# TWO SIGNALS, EITHER BLOCKS — both deliberate:
#
#   · `isolation: "worktree"`, on its own. A private worktree is build work
#     running in parallel with this session, and that is the shape the method
#     routes through `wingman` regardless of how the brief is phrased. This
#     side catches a lane whose prompt says nothing a regex would recognise.
#   · An issue-shaped brief: a reference to an issue or ticket AND the
#     language of shipping it (opening a PR, the judge, a definition of
#     done). The CONJUNCTION is the precision: "summarise issue #12" is an
#     analysis and passes; "work issue #12 through to the PR" is a lane
#     brief whichever agent type carries it.
#
# `subagent_type` is read for the refusal's wording but never for the
# decision: Explore and Plan pass because their calls carry neither signal,
# not because their names are trusted — a lane brief handed to any agent type
# is still a lane.
#
# THE HATCH: a line in the prompt itself —
#     FLIGHT_LANE_BY_AGENT: <one sentence: why this must be a subagent>
# — the set's shape (a stated reason, typed fresh each time, never a flag),
# carried where an Agent call's only writable surface is. It exists because
# the boundary has real exceptions: a wired repo on a machine with no cockpit
# has no `wingman` verb to refuse toward, and a human may deliberately direct
# a subagent at issue-shaped work. The reason lands in the transcript AND in
# the subagent's own brief, which is the point. Known limit, unlike the Bash
# hatch: a prompt has no quoted-vs-invoked distinction, so any occurrence of
# the token opens it — nobody writes that token by accident, and the reason
# check still makes a bare mention refuse.
#
# HONEST LIMITS, stated rather than discovered later:
#
#   · A missing or non-executable hook script FAILS OPEN (measured on this
#     set's siblings, Claude Code 2.1.212 and 2.1.220). session-start-wired.sh
#     tests for this guard positively; that is the only reason its silence
#     means anything.
#   · Only Claude Code's Agent tool is seen. A lane started from Bash
#     (`claude -p` in a worktree), the Workflow tool's agents, opencode and
#     agy all pass unguarded — the Bash route is at least visible to the
#     transcript, and the habitual path this guard closes is the one the
#     measured miss actually took.
#   · The brief is read as text. A lane phrased without an issue number and
#     without shipping words, and dispatched without a worktree, is not seen.
#     Evasion is conceded, as everywhere in this set; the guard closes the
#     shape that occurs.
#
# WHY EXIT 2: the model sees the stderr of an exit 2 and acts on it, so the
# refusal names the wingman route and the session re-dispatches correctly
# with no human in the loop.

set -uo pipefail
# shellcheck source=_payload.sh
. "$(dirname "${BASH_SOURCE[0]}")/_payload.sh"

payload_read
prompt="$(json_str tool_input.prompt)"
description="$(json_str tool_input.description)"
isolation="$(json_str tool_input.isolation)"
agent_type="$(json_str tool_input.subagent_type)"
[ -n "$prompt$description" ] || exit 0

brief="$prompt
$description"

# ── The hatch, checked first so a stated reason costs nothing. ──────────────
if [[ "$brief" == *FLIGHT_LANE_BY_AGENT* ]]; then
    reason=$(printf '%s\n' "$brief" |
             sed -n 's/.*FLIGHT_LANE_BY_AGENT[:= ][[:space:]]*//p' | head -n1)
    # The sibling gate's threshold, for the sibling's reason: not a quality
    # bar, only enough to stop a bare token becoming the shape everyone
    # learns.
    if (( ${#reason} < 12 )); then
        {
            echo "BLOCKED: FLIGHT_LANE_BY_AGENT needs a reason, not a token."
            echo
            echo "It rides in the transcript and in the subagent's own brief, so write"
            echo "the sentence you would defend on the board:"
            echo "    FLIGHT_LANE_BY_AGENT: this machine has no cockpit install to dispatch from"
            echo
            echo "— pre-agent-lane-dispatch.sh, this repo's resident guard"
        } >&2
        exit 2
    fi
    exit 0
fi

# ── Is this call shaped like a lane dispatch? ───────────────────────────────
signal=""
if [ "$isolation" = "worktree" ]; then
    signal='isolation: "worktree" — build work in a private worktree, running beside this session'
elif printf '%s' "$brief" | grep -Eiq '(^|[^[:alnum:]])(issues?|tickets?)[[:space:]]*#?[0-9]+|gh issue view' &&
     printf '%s' "$brief" | grep -Eiq 'gh pr create|wingman|\bjudge\b|definition of done|(open|create|raise|land|through to)[^.]{0,60}(pull[- ]?request|\bPRs?\b)'; then
    signal="an issue worked through to a PR — the shape of a lane brief"
fi
[ -n "$signal" ] || exit 0

{
    echo "BLOCKED: this Agent call${agent_type:+ (subagent_type: $agent_type)} is shaped like a lane dispatch —"
    echo "$signal."
    echo
    echo "Approved lanes fly as \`wingman\` tabs, never as subagents. A subagent has"
    echo "no board row, no attachable session, no judge verbs in its shell and no"
    echo "dispatch-line pins (full model id, retry watchdog) — the method loses"
    echo "sight of the work at exactly the moment it starts."
    echo
    echo "Do instead:"
    echo "  · a lane — land the agreed prompt on its issue, then dispatch a"
    echo "    \`wingman\` tab from the cockpit (teomach-cockpit's verb; the board"
    echo "    shows the lane the moment it exists)"
    echo "  · a search or analysis that stays inside this session — call the Agent"
    echo "    tool without a worktree and without a work-this-issue brief; that"
    echo "    use is never blocked"
    echo "  · genuinely a subagent's job — no cockpit on this machine, or the"
    echo "    human said so — state it in the prompt itself:"
    echo "        FLIGHT_LANE_BY_AGENT: <one sentence: why this must be a subagent>"
    echo "    The reason rides in the transcript and in the subagent's brief."
    echo
    echo "— pre-agent-lane-dispatch.sh, this repo's resident guard"
} >&2
exit 2
