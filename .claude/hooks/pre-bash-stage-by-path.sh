#!/usr/bin/env bash
# PreToolUse (Bash) — the lane's staging discipline, made mechanical: stage by
# path, never by sweep.
#
# Two refusals, and only two:
#
#   1. `git add -A` (or `--all`, or the `-a` misremembering of it) — a sweep
#      stages everything the tree holds: another session's work in a shared
#      checkout, build scratch, the lot. What you did not name, you did not
#      review;
#   2. `git commit -a` (or `--all`, or a bundled `-am`) — the same sweep at
#      commit time, limited to tracked files but reviewed by nobody all the
#      same.
#
# WHY A GUARD AND NOT JUST THE RULE. The Stop guard warns on uncommitted work,
# but it cannot catch what a sweep has already staged and committed — it sees
# a clean tree. The sweep has to be refused before the stage, which only a
# PreToolUse hook is positioned to do. The rule itself is the kernel's — the
# `implement` skill's build loop: stage by path, and read `git status` before
# the lane's first add. This file enforces the refusable half and points at
# the rest.
#
# HONEST LIMITS, stated rather than discovered later:
#
#   · A missing or non-executable hook script FAILS OPEN (measured, Claude Code
#     2.1.220). The SessionStart guard tests for it positively; that is the
#     only reason its silence means anything.
#   · It reads the command AS WRITTEN. A `bash -c` with a constructed string
#     is not seen. It closes the habitual path, which is the one that sweeps.
#   · Quoted spans are data and are stripped before matching, so a commit
#     message or an `echo` that merely mentions `git add -A` passes. A heredoc
#     body is NOT parsed as one — a body line that begins `git add -A` is
#     refused. Over-refusing a mention is a nuisance; the workaround the
#     refusal cannot name is the one you already have: quote it, or write the
#     file with the Write tool.
#   · `git add -u` is not refused. It cannot stage an untracked file, which is
#     what a sweep actually smuggles in; refusing it would catch deliberate
#     choices, not habits.
#
# WHY DENY RATHER THAN ASK. The model sees the stderr of an `exit 2` and acts
# on it, so a refusal naming the exact alternative gets repaired by the agent
# with no human in the loop.

set -uo pipefail
set -f      # someone else's command string is data: never glob it against our cwd
# shellcheck source=_payload.sh
. "$(dirname "${BASH_SOURCE[0]}")/_payload.sh"

payload_read
CMD="$(json_str tool_input.command)"
[ -n "$CMD" ] || exit 0

refuse() {   # refuse <headline> <what-to-do-instead...>
    local headline="$1"; shift
    {
        echo "BLOCKED: $headline"
        echo
        printf '%s\n' "$@"
        echo
        echo "The rule's home: the \`implement\` skill's build loop (the \`method\` kernel)."
    } >&2
    exit 2
}

refuse_add() {   # refuse_add <flag>
    refuse "this stages by sweep (\`git add $1\`), not by path" \
"A sweep stages everything the tree holds — another session's work, build" \
"scratch, the lot — and the Stop guard cannot catch what is already staged:" \
"it sees a clean tree. What you did not name, you did not review." \
"" \
"Do instead:" \
"  · read \`git status\` first — anything there you did not write is not" \
"    yours to stage" \
"  · stage each deliverable by path: \`git add <path> [<path>…]\` (a" \
"    directory path stages its deletions too — the flag buys nothing)"
}

refuse_commit() {   # refuse_commit <flag>
    refuse "this commits by sweep (\`git commit $1\`) — every tracked change, reviewed or not" \
"The \`-a\` stages whatever the tree has accumulated, including what another" \
"session or a build left in a shared checkout, and commits it unseen." \
"" \
"Do instead:" \
"  · read \`git status\` first — anything there you did not write is not" \
"    yours to commit" \
"  · stage by path, then commit what you staged:" \
"    \`git add <path> [<path>…] && git commit -m …\`"
}

# Quoted spans are data — a message that MENTIONS a sweep is not one.
STRIPPED=$(printf '%s\n' "$CMD" | sed -E "s/'[^']*'//g; s/\"[^\"]*\"//g")

# One segment per command: splitting on the separators puts the command word
# first, the same lookup shape as the pollution guard.
while IFS= read -r seg; do
    [ -n "${seg// /}" ] || continue
    # shellcheck disable=SC2206   # deliberate: split the segment into words
    words=($seg)
    while [ "${#words[@]}" -gt 0 ] && [[ "${words[0]}" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; do
        words=("${words[@]:1}")
    done
    [ "${#words[@]}" -gt 0 ] || continue
    [ "${words[0]}" = git ] || continue
    args=("${words[@]:1}")

    # Walk git's own global options to find the subcommand.
    sub=""; rest=(); i=0
    while [ "$i" -lt "${#args[@]}" ]; do
        a="${args[$i]}"
        case "$a" in
            -C|-c) i=$((i + 2)); continue ;;   # take a separate value
            -*)    i=$((i + 1)); continue ;;   # --git-dir=…, -P, and kin
            *)     sub="$a"; rest=("${args[@]:$((i + 1))}"); break ;;
        esac
    done

    case "$sub" in
      add)
        for a in ${rest[@]+"${rest[@]}"}; do
            case "$a" in
              --) break ;;                       # pathspecs from here on
              --all) refuse_add "--all" ;;
              -[A-Za-z]*)                        # a short flag or cluster
                case "$a" in
                  *A*|*a*) refuse_add "$a" ;;    # add has no other a/A option
                esac ;;
            esac
        done
        ;;
      commit)
        for a in ${rest[@]+"${rest[@]}"}; do
            case "$a" in
              --) break ;;
              --all) refuse_commit "--all" ;;
              --*) ;;                            # --amend and kin pass
              -[A-Za-z]*)
                case "$a" in
                  *a*) refuse_commit "$a" ;;     # -a alone or bundled (-am)
                esac ;;
            esac
        done
        ;;
    esac
done < <(printf '%s\n' "$STRIPPED" | awk '{ gsub(/&&|\|\||\||;/, "\n"); print }')

exit 0
