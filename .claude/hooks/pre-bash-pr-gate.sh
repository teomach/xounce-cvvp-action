#!/usr/bin/env bash
# PreToolUse (Bash) — no pull request opens without a judge report standing for
# exactly what is about to be shipped.
#
# THE TRAVELLING HALF OF THE GATE (criterion 15, the wiring spec). The
# machine-level flight-pr-gate.sh (teomach-cockpit, machine-config) fires in
# every session on a machine the cockpit was installed on — and nowhere else,
# so a wired repo cloned anywhere else opened PRs unjudged. This guard rides in
# the repo's own resident set, dispatched by .claude/settings.json, and the
# refusal holds for anyone who clones a wired repo. The judge RUNNER stays the
# cockpit's; this is the gate, not the runner.
#
# WHAT IT CHECKS, exactly and only: that a judge report exists for the worktree
# the PR will be opened from, and that it names this branch at this HEAD. The
# report is where `wingman-judge` writes it — ${XDG_RUNTIME_DIR:-/tmp}/flight/
# judge-<worktree-basename>.md, with `<!-- flight-judge branch=… sha=… -->` in
# its header. That path and that header line are the contract with the runner;
# this guard reads them and writes nothing.
#
# THREE DECISIONS, all deliberate. The first two are the machine hook's,
# preserved exactly; the third is this guard's own ruling on a question the
# machine hook never had to answer out loud:
#
#   · A report full of FAILs still opens a PR. Dissent is a legitimate route —
#     a finding you disagree with is recorded with its evidence in the PR body,
#     not silently overridden and not silently obeyed. A gate that blocked on
#     FAIL would make the honest route the expensive one, and the dishonest
#     route is already free.
#   · Staleness is measured against the commit, not the diff. The report names
#     the branch and SHA it judged, so this is an identity check: an --amend or
#     a rebase invalidates it because the SHA moves, not because a timestamp
#     sorts the right way. A report with no `flight-judge` line falls back to
#     mtime against HEAD's commit time — the best available answer for a file
#     that never recorded what it looked at.
#   · Verdict content is never read. A report that is all NOT-CHECKABLE, or
#     whose cross-model layer reports DID NOT RUN, passes this gate — for the
#     same reason a FAIL does. NOT-CHECKABLE is the honest verdict when a
#     check cannot be settled, and a gate that punished it would teach judges
#     to guess PASS instead. What this gate makes unavoidable is "the judge
#     ran, and its report is in front of the human"; what the report BOUGHT is
#     weighed by the human at merge, with the report pasted in the PR body
#     where its emptiness is loud. This gate certifies attendance, not
#     independence — a run of empty reports is triage's to notice, not a
#     per-PR block.
#
# WHERE THE RUNNER IS ABSENT, THE GATE STILL STANDS — and says so. On a
# machine with no cockpit install there is no `wingman-judge` to run, and the
# tempting failure is to pass by omission. A control that cannot run must be
# loud: the refusal names the missing runner, where it comes from, and the
# stated-bypass route. Closed and loud, never open and silent.
#
# HONEST LIMITS — the machine hook's, measured, plus this layer's own:
#
#   · A missing or non-executable hook script FAILS OPEN (measured, Claude
#     Code 2.1.212 and 2.1.220). session-start-wired.sh tests for this guard
#     positively at session start; that is the only reason its silence means
#     anything.
#   · It matches the command AS WRITTEN. A `bash -c` with a constructed
#     string gets past it; quoting `gh` is enough. The matcher refuses to
#     look inside quotes ON PURPOSE — see below.
#   · Only Claude Code runs it. An agent on opencode or agy is unguarded, and
#     so is a human in their own terminal — hooks fire for tool calls, not
#     for shells.
#   · The payload's `cwd` is the SESSION's directory, not where the command
#     runs (measured 2026-08-02). A leading `cd` in THIS command is read out
#     of the command string — the only evidence of where `gh` will actually
#     be. A `cd` in an earlier tool call leaves no evidence at all, and the
#     refusal says so rather than guessing.
#   · On the cockpit's own machine this and the machine-level hook both fire
#     on the same command. They read the same report and reach the same
#     answer; a doubled refusal is accepted noise, and each names itself.
#
# THE HATCH: FLIGHT_PR_UNJUDGED='<why>' gh pr create …  A reason is
# compulsory, and it is read out of the command string rather than the
# environment, so it cannot be exported once and forgotten: every bypass is
# typed into the transcript, and belongs restated in the PR body. It counts
# only as a real assignment word — a VAR=value prefix ahead of the `gh` word,
# or an `export FLIGHT_PR_UNJUDGED=…` typed in the same command string — never
# as the name appearing inside a quoted argument, which is data like any
# other. A --title or --body that merely mentions the variable neither opens
# the hatch nor trips the reason check. UNLIKE the
# machine hook, this guard keeps no bypass log. The resident guard set only
# reads and refuses — no guard writes outside the repo — an acceptance
# criterion of the wiring spec (§10), because this file is work-product
# executable policy running on every reviewer's machine. On a cockpit machine
# the machine hook still counts bypasses exactly as before.
#
# THE MATCHER IS THE MACHINE HOOK'S, PORTED WHOLE, and its false-positive
# history is earned: an unanchored regex refused PR COMMENTS that merely
# mentioned `gh pr create` — once in a comment body, once in a heredoc
# writing that text to a file. So it walks the string as a shell would and
# asks a structural question: does any SIMPLE COMMAND begin — after any
# VAR=value assignments — with the three bare words `gh` `pr` `create`?
# Command boundaries are `; & | && || newline ( ) { }`; quoted spans and
# heredoc bodies are read as data, redirection targets as filenames. It
# refuses to look inside quotes DELIBERATELY: `"gh" pr create` really does
# invoke gh and is not seen — nobody writes that except to evade, evasion is
# already conceded above, and not reasoning about quoted text is precisely
# what makes the false-positive class impossible. A fix to either copy of
# the matcher belongs in both.

set -o pipefail
# shellcheck source=_payload.sh
. "$(dirname "${BASH_SOURCE[0]}")/_payload.sh"

payload_read
cmd="$(json_str tool_input.command)"
cwd="$(json_str cwd)"
[ -n "$cmd" ] || exit 0

# ── Is `gh pr create` INVOKED here, or merely MENTIONED? ────────────────────
# It also records the target of a leading `cd`, because this walk is the only
# place that information exists — see _effective_dir. The hatch is read here
# too, and by the same structural rule as everything else the walk answers:
# FLIGHT_PR_UNJUDGED counts only as a real assignment word, never as text
# inside a quoted argument — see the hatch block below.
CD_TARGET=""
HATCH_SET=0
HATCH_REASON=""
_gh_pr_create_invoked() {
    local s=$1
    local n=${#s} i=0
    local c d
    local word="" lit="" wq=0
    local -a cw=() cl=()
    local hd_delim="" hd_tabs=0
    local hit=1
    local rest raw line

    # `word` is keyword-safe: every quoted or escaped span collapses to \x01,
    # so a quoted word can never equal `gh`. `lit` keeps the real text, which
    # is what a `cd` target needs.
    _emit() {
        [[ -n "$word" || $wq -eq 1 ]] || return 0
        cw+=("$word"); cl+=("$lit")
        word=""; lit=""; wq=0
        local -a w=("${cw[@]}") l=("${cl[@]}")
        local hatch=""
        while (( ${#w[@]} )) && [[ ${w[0]} =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; do
            [[ ${w[0]} == FLIGHT_PR_UNJUDGED=* ]] && hatch=${l[0]}
            w=("${w[@]:1}"); l=("${l[@]:1}")
        done
        if (( ${#w[@]} >= 2 )) && [[ ${w[0]} == cd && -n ${l[1]} ]]; then
            CD_TARGET=${l[1]}
        fi
        # `export FLIGHT_PR_UNJUDGED=…` is a real assignment too — the word
        # after `export` is checked keyword-safe like every other, so a quoted
        # name still does not count. The reason is typed in this transcript
        # either way, which is what the hatch's design requires.
        if [[ ${w[0]:-} == export ]]; then
            local k
            for k in "${!w[@]}"; do
                [[ ${w[k]} == FLIGHT_PR_UNJUDGED=* ]] || continue
                HATCH_SET=1; HATCH_REASON=${l[k]#FLIGHT_PR_UNJUDGED=}
            done
        fi
        (( ${#w[@]} >= 3 )) || return 0
        if [[ ${w[0]} == gh && ${w[1]} == pr && ${w[2]} == create ]]; then
            hit=0
            # A prefix assignment opens the hatch only on THIS simple command
            # — the one that invokes gh — which is also bash's own scope for
            # a VAR=value prefix.
            [[ -n $hatch ]] && { HATCH_SET=1; HATCH_REASON=${hatch#FLIGHT_PR_UNJUDGED=}; }
        fi
        return 0
    }

    while (( i < n )); do
        c=${s:i:1}

        # Inside a heredoc body: skip whole lines until the delimiter line.
        if [[ -n $hd_delim && $c == $'\n' ]]; then
            ((i++))
            while (( i < n )); do
                rest=${s:i}
                raw=${rest%%$'\n'*}
                line=$raw
                (( hd_tabs )) && line=${line#"${line%%[!$'\t']*}"}
                i=$(( i + ${#raw} ))
                (( i < n )) && ((i++))
                if [[ $line == "$hd_delim" ]]; then hd_delim=""; break; fi
            done
            cw=(); cl=()
            continue
        fi

        case $c in
            $'\\') # A line continuation produces nothing; any other escape
                  # makes that character quoted.
                  if [[ ${s:i+1:1} == $'\n' ]]; then i=$((i + 2)); continue; fi
                  word+=$'\x01'; lit+=${s:i+1:1}; wq=1; i=$((i + 2)); continue ;;
            "'")  ((i++))
                  while (( i < n )) && [[ ${s:i:1} != "'" ]]; do
                      lit+=${s:i:1}; ((i++))
                  done
                  ((i++)); word+=$'\x01'; wq=1; continue ;;
            '"')  ((i++))
                  while (( i < n )) && [[ ${s:i:1} != '"' ]]; do
                      [[ ${s:i:1} == $'\\' ]] && ((i++))
                      lit+=${s:i:1}; ((i++))
                  done
                  ((i++)); word+=$'\x01'; wq=1; continue ;;
            ' '|$'\t') _emit; ((i++)); continue ;;
        esac

        # Heredoc operator: take the delimiter, then keep reading this line —
        # the body does not start until the newline, and a `| gh pr create`
        # after the operator is still an invocation.
        if [[ ${s:i:2} == '<<' && ${s:i:3} != '<<<' ]]; then
            _emit; i=$((i + 2))
            hd_tabs=0
            [[ ${s:i:1} == '-' ]] && { hd_tabs=1; ((i++)); }
            while (( i < n )) && [[ ${s:i:1} == ' ' || ${s:i:1} == $'\t' ]]; do ((i++)); done
            hd_delim=""
            while (( i < n )); do
                d=${s:i:1}
                case $d in
                    ' '|$'\t'|$'\n'|';'|'&'|'|'|'>'|'<') break ;;
                    "'"|'"'|$'\\') ((i++)); continue ;;
                esac
                hd_delim+=$d; ((i++))
            done
            continue
        fi

        case $c in
            ';'|'&'|'|'|$'\n'|'('|')'|'{'|'}')
                _emit; cw=(); cl=(); ((i++)); continue ;;
            '<'|'>')
                # A redirection ends the word, and its target is a filename
                # rather than the start of a command.
                _emit; ((i++))
                while (( i < n )) && [[ ${s:i:1} == '>' || ${s:i:1} == '&' ]]; do ((i++)); done
                while (( i < n )) && [[ ${s:i:1} == ' ' ]]; do ((i++)); done
                while (( i < n )); do
                    d=${s:i:1}
                    case $d in ' '|$'\t'|$'\n'|';'|'&'|'|') break ;; esac
                    ((i++))
                done
                continue ;;
        esac

        word+=$c; lit+=$c; ((i++))
    done
    _emit
    return $hit
}

# Creating a PR only. `gh pr view`, `gh pr list`, `gh pr merge`, a comment
# that quotes the phrase and a heredoc that writes it all pass untouched — a
# gate that interrupts reads is a gate people delete.
_gh_pr_create_invoked "$cmd" || exit 0

# WHERE THE COMMAND WILL RUN, which is not necessarily where the session is.
# A leader session sits in the main checkout and drives worktrees, so this is
# a normal shape rather than an exotic one. A relative target resolves against
# the session's `cwd`, which is what a shell would do.
_effective_dir() {
    local d=${CD_TARGET:-}
    if [[ -z "$d" ]]; then printf '%s' "${cwd:-.}"; return; fi
    [[ "$d" == /* ]] || d="${cwd:-.}/$d"
    printf '%s' "$d"
}
run_dir=$(_effective_dir)
[[ -d "$run_dir" ]] || run_dir="${cwd:-.}"

FLIGHT_STATE="${XDG_RUNTIME_DIR:-/tmp}/flight"
RUNNER_HOME="$HOME/.bashrc.d/flight.sh"

runner_present() {
    command -v wingman-judge >/dev/null 2>&1 && return 0
    [[ -r "$RUNNER_HOME" ]]
}

# ── The hatch, checked before the gate so a stated reason costs nothing. ──
#
# HATCH_SET is the walk's answer, held to the walk's own rule: the hatch
# counts only as an assignment word seen in command position — a VAR=value
# prefix on the invoking command, or an `export` in the same string — and
# the variable's name inside a quoted argument is data, opening nothing and
# tripping nothing. The walk's `lit` hands the value over with its quotes
# already stripped, so there is no second parse here to disagree with the
# first.
if (( HATCH_SET )); then
    reason="$HATCH_REASON"
    # A reason short enough to be reflex is not a reason. The threshold is not
    # a quality bar — nothing here can judge prose — it is only enough to stop
    # `FLIGHT_PR_UNJUDGED=1` becoming the shape everyone learns.
    if (( ${#reason} < 12 )); then
        {
            echo "BLOCKED: FLIGHT_PR_UNJUDGED needs a reason, not a value."
            echo
            echo "It stays in the transcript and belongs in the PR body, so write the"
            echo "sentence you would have written there:"
            echo "    FLIGHT_PR_UNJUDGED='judge derives no checks from a docs-only diff' gh pr create ..."
            echo
            echo "— pre-bash-pr-gate.sh, this repo's resident guard"
        } >&2
        exit 2
    fi
    # The reason is in the transcript; this guard keeps no log — see header.
    exit 0
fi

# Not a git worktree: nothing to key a report on, and `gh` will give a better
# error than this hook can.
root=$(git -C "$run_dir" rev-parse --show-toplevel 2>/dev/null) || exit 0
[[ -n "$root" ]] || exit 0

# One report per WORKTREE, named for it — `wingman-judge` keys on
# `basename "$wt"`. The branch is not in the file NAME, so the name alone
# cannot tell a report for this branch from one the previous branch left in
# the same worktree; it is in the report's own header, which the identity
# check below reads.
report="$FLIGHT_STATE/judge-$(basename "$root").md"
branch=$(git -C "$root" branch --show-current 2>/dev/null)
topic="${branch:-<topic>}"

head_sha=$(git -C "$root" rev-parse HEAD 2>/dev/null)
head_time=$(git -C "$root" log -1 --format=%ct 2>/dev/null)
[[ "$head_time" =~ ^[0-9]+$ ]] || exit 0   # no commits yet; nothing to judge

explain() {
    echo
    if runner_present; then
        echo "Run it, then open the PR:"
        echo "    wingman-judge $topic"
    else
        echo "THIS MACHINE HAS NO JUDGE RUNNER — \`wingman-judge\` is not on PATH"
        echo "and $RUNNER_HOME does not exist. The runner is the"
        echo "cockpit's, not this repo's: install teomach-cockpit's machine-config"
        echo "to get it, run \`wingman-judge $topic\`, then open the PR."
    fi
    echo
    echo "The report goes in the PR body — every NOT-CHECKABLE and any dissent"
    echo "included. A finding you disagree with is recorded with its evidence,"
    echo "not overridden in silence and not obeyed in silence."
    echo
    echo "If the judge genuinely cannot run on this diff — or cannot run on this"
    echo "machine — say so rather than working round it:"
    echo "    FLIGHT_PR_UNJUDGED='<one sentence: why not>' gh pr create ..."
    echo "The reason stays in the transcript; restate it in the PR body."
    echo
    echo "— pre-bash-pr-gate.sh, this repo's resident guard"
}

if [[ ! -f "$report" ]]; then
    {
        echo "BLOCKED: no judge report for this worktree, so this PR would carry"
        echo "no independence layer at all."
        echo
        echo "Looked for: $report"
        echo "Which is:   $run_dir"
        # SAY WHAT DOES EXIST. When the gate resolves the wrong worktree a
        # refusal that names one absent path is unreadable — the report just
        # run may be sitting beside it under another name. A leader driving
        # several lanes hits this first.
        if compgen -G "$FLIGHT_STATE/judge-*.md" >/dev/null 2>&1; then
            echo
            echo "Reports that DO exist:"
            for f in "$FLIGHT_STATE"/judge-*.md; do echo "    $f"; done
            echo
            echo "If you are driving another worktree from a leader session, put"
            echo "the 'cd' in this same command — the hook is told the session's"
            echo "directory, not the shell's, so a 'cd' in an earlier call is"
            echo "invisible to it:"
            echo "    cd <worktree> && gh pr create ..."
        fi
    explain
    } >&2
    exit 2
fi

# ── Does the report stand for THIS branch at THIS commit? ───────────────────
rid=$(grep -m1 '^<!-- flight-judge ' "$report" 2>/dev/null)
if [[ -n "$rid" ]]; then
    rbranch=""; rsha=""
    [[ "$rid" =~ branch=([^[:space:]]+) ]] && rbranch="${BASH_REMATCH[1]}"
    [[ "$rid" =~ sha=([^[:space:]]+) ]] && rsha="${BASH_REMATCH[1]}"
    if [[ "$rsha" != "$head_sha" || ( -n "$branch" && "$rbranch" != "$branch" ) ]]; then
        {
            if [[ -n "$branch" && "$rbranch" != "$branch" ]]; then
                echo "BLOCKED: that judge report is for a different branch. It is the"
                echo "one the last branch in this worktree left behind."
            else
                echo "BLOCKED: the judge report names a different commit, so it judged"
                echo "a diff you have since committed over."
            fi
            echo
            echo "Report:  $report"
            echo "  judged ${rbranch:-?} at ${rsha:0:12}"
            echo "  HEAD is ${branch:-detached} at ${head_sha:0:12} — $(git -C "$root" log -1 --format='%s' 2>/dev/null)"
        explain
        } >&2
        exit 2
    fi
else
    report_time=$(stat -c %Y "$report" 2>/dev/null)
    if [[ "$report_time" =~ ^[0-9]+$ ]] && (( report_time < head_time )); then
        {
            echo "BLOCKED: the judge report is older than HEAD, so it judged a diff"
            echo "you have since committed over."
            echo
            echo "Report:  $report ($(date -d "@$report_time" -Is 2>/dev/null))"
            echo "HEAD:    $(git -C "$root" log -1 --format='%h %s' 2>/dev/null) ($(date -d "@$head_time" -Is 2>/dev/null))"
            echo
            echo "(This report predates the header that names its branch and SHA,"
            echo "so the check is recency rather than identity. Re-run the judge"
            echo "and it will carry both.)"
        explain
        } >&2
        exit 2
    fi
fi

exit 0
