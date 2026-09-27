#!/usr/bin/env bash
# Source: teomach-skills harness/hooks/pre-bash-pr-gate.sh —
# edit it there and re-run `scripts/wire-repo.py update`, never edit a copy.
# PreToolUse (Bash) — no pull request opens without a judge report standing for
# exactly what is about to be shipped.
#
# THE TRAVELLING HALF OF THE GATE. The machine-level flight-pr-gate.sh
# (teomach-cockpit, machine-config) fires in every session on a machine the
# cockpit was installed on — and nowhere else, so a wired repo cloned anywhere
# else opens PRs unjudged. This guard rides in the repo's own resident set,
# dispatched by .claude/settings.json, and the refusal holds for anyone who
# clones a wired repo. The judge RUNNER stays the cockpit's; this is the gate,
# not the runner.
#
# WHAT IT CHECKS, exactly and only: that a judge report exists for the worktree
# the PR will be opened from, and that it names this branch at this HEAD. The
# report is where `wingman-judge` writes it — $FLIGHT_STATE/judge-<worktree-
# basename>.md, with `<!-- flight-judge branch=… sha=… -->` in its header. That
# path and that header line are the contract with the runner; this guard reads
# them and writes nothing.
#
# WHERE THE REPORT IS, in three steps and for one reason each. The cockpit
# keeps two directories and draws the line at what a reboot ought to destroy;
# a report is something somebody paid for, so it lives in the DURABLE one,
# ${XDG_STATE_HOME:-$HOME/.local/state}/teomach/flight. This guard reads
# $FLIGHT_STATE when the environment carries one — flight.sh defaults that
# variable with `:=`, so a value already set is the runner's own answer and
# not something to override — else that durable default, and then, only when
# no report for this worktree stands there, the PER-BOOT
# ${XDG_RUNTIME_DIR:-/tmp}/flight, so a box whose cockpit predates the split
# still opens its PRs. A gate reading any one of the three alone refuses
# lanes whose judge has run clean, and a refused lane teaches itself the
# workaround the next paragraph is about.
#
# IT RESOLVES THE REPORT ITSELF RATHER THAN ASKING ANYONE TO MOVE
# $FLIGHT_STATE. The lane's dispatch record (`.cli-<worktree>`) lives beside
# the report, so repointing that variable to satisfy a gate takes the judge's
# coverage derivation and the lane's flight association with it: the run
# cannot find the dispatch record, falls back to a default runner, and the
# report quoted in the PR is the degraded one — bought at full price and
# silently worth less. Copying a report between the two directories is the
# same mistake in a different hand. Where this gate is wrong, the route is
# the hatch below, with the reason typed into the transcript.
#
# THREE DECISIONS, all deliberate:
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
# HONEST LIMITS, measured rather than assumed:
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
#     runs (measured 2026-08-02). A `cd` in THIS command is read out of the
#     command string — the only evidence of where `gh` will actually be. A
#     `cd` in an earlier tool call leaves no evidence at all, and the refusal
#     says so rather than guessing.
#   · Each create is judged where the shell stands WHEN IT RUNS: the `cd`s
#     typed before it, in order, relative ones resolving from the one before,
#     `cd -` returning to it, and a `cd` inside `( … )` or `$( … )` undone
#     when it closes. A `cd` AFTER a create moves nothing it is judged
#     against, or `cd <repo> && gh pr create && cd /` would be judged at `/`,
#     which is no repo, and pass unjudged. Every create in the command is
#     judged, and one refusal refuses the command. This is ordering, not a shell:
#     control flow is not modelled — `cd x || gh pr create`, a loop, a
#     function — and a directory change spelled any other way (`pushd`,
#     `builtin cd`, `command cd`) is not followed, so the create is judged
#     where the walk last knew the shell to be. That is the same concession
#     as quoting `gh`: nobody writes those in front of a PR but to evade, and
#     evasion is already conceded above.
#   · The `cd` operand is read as TEXT, so the shell's expansions have not
#     happened to it. Two are done here, and only two: a leading `~` and a
#     leading `$HOME` become this process's $HOME, because a leader driving
#     a second repo writes `cd ~/Code/<repo>` and nothing else a shell would
#     expand is that common. Left unexpanded, either spelling is no
#     directory this guard can see, and the fallback below takes the
#     session's — whose report then judges another repo's PR. Any other
#     expansion — `${HOME}`, `~user`, a variable — is not attempted, and
#     every refusal prints the directory the command was resolved to, so a
#     miss is read rather than inferred.
#   · On the cockpit's own machine this and the machine-level hook both fire
#     on the same command, and agree wherever the report is in the durable
#     directory — which is where the runner writes it; a doubled refusal is
#     accepted noise, and each names itself. On a report that is ONLY in the
#     per-boot directory they part, measured: this guard's fallback accepts
#     it, the machine hook reads the durable path alone and refuses. The
#     stricter answer is the one that stands, because either refusal blocks
#     the command — so the fallback buys a PR on a machine with no cockpit
#     install, and not on one that has it.
#
# THE HATCH: FLIGHT_PR_UNJUDGED='<why>' gh pr create …  A reason is
# compulsory, and it is read out of the command string rather than the
# environment, so it cannot be exported once and forgotten: every bypass is
# typed into the transcript, and belongs restated in the PR body. It counts
# only as a real assignment word — a VAR=value prefix ahead of the `gh` word,
# or an `export FLIGHT_PR_UNJUDGED=…` typed EARLIER in the same command
# string, since an export after a create has not happened when it runs — never
# as the name appearing inside a quoted argument, which is data like any
# other. A --title or --body that merely mentions the variable neither opens
# the hatch nor trips the reason check. UNLIKE the machine hook, this guard
# keeps no bypass log. The resident guard set only reads and refuses — no
# guard writes outside the repo — because this file is work-product executable
# policy running on every reviewer's machine. On a cockpit machine the machine
# hook still counts bypasses.
#
# THE MATCHER IS SHARED WITH THE MACHINE HOOK — the walk, and what it records
# for each create: its directory and its hatch. It is structural
# rather than a regex for a reason: an unanchored pattern refuses commands that
# merely MENTION `gh pr create` — inside a comment or `--body` argument,
# inside a heredoc writing that text to a file. So it walks the string as a
# shell would and asks a structural question: does any SIMPLE COMMAND begin —
# after any VAR=value assignments — with the three bare words `gh` `pr`
# `create`? Command boundaries are `; & | && || newline ( ) { }`; quoted spans
# and heredoc bodies are read as data, redirection targets as filenames. It
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
# It also records, FOR EACH CREATE, the directory the shell will be in when
# that create runs, because this walk is the only place that information
# exists. A `cd` moves the walk's directory from the point it is typed on; a
# create takes the directory in effect AT ITS OWN POSITION, so a `cd` after
# it moves nothing it is judged against — see _cd_to. The hatch is
# read here too, and by the same structural rule as everything else the walk
# answers: FLIGHT_PR_UNJUDGED counts only as a real assignment word, never as
# text inside a quoted argument — and it too is bound to the creates it
# precedes, never to one already behind it. See the hatch block below.
#
# The walk's state, one frame of it: where the shell is, the `cd` operand
# that put it there as typed (for the refusal), whether the last `cd` could
# not be followed, the directory before it (for `cd -`), and an exported
# hatch. A subshell — `(` … `)`, which is
# also `$(` … `)` — pushes a frame on entry and pops it on exit, because a
# `cd` or an `export` inside one does not survive it.
DIR="${cwd:-.}"; DIR_CD=""; DIR_UNRES=0; DIR_OLD=""; EXP_HATCH=0; EXP_REASON=""
FRAMES=()
# One entry per create, in the order they appear.
CREATE_DIR=(); CREATE_CD=(); CREATE_UNRES=(); CREATE_HATCH=(); CREATE_REASON=()

# Bash checks each logical component as it walks, then applies `..` to the
# logical path. A missing component before `..` fails; link/.. names the
# link's logical parent when the link is a directory.
_logical_path() {
    local rest=$1 part path=/
    while [[ -n $rest ]]; do
        part=${rest%%/*}
        if [[ $rest == */* ]]; then rest=${rest#*/}; else rest=""; fi
        case $part in
            ''|.) ;;
            ..) if [[ $path != / ]]; then path=${path%/*}; path=${path:-/}; fi ;;
            *) path="${path%/}/$part"; [[ -d $path ]] || return 1 ;;
        esac
    done
    REPLY=$path
}

# _cd_to <operand as typed> <L|P> — resolve only literal paths. A failed cd
# leaves both PWD and OLDPWD where Bash left them.
_cd_to() {
    local t=$1 d=$1 mode=$2 next
    # The patterns are literal text from someone else's command string, not
    # paths for this shell to expand — hence the quoting shellcheck warns about.
    # shellcheck disable=SC2088,SC2016
    case "$d" in
        "~"|'$HOME')        d="$HOME" ;;
        "~/"*)              d="$HOME/${d#\~/}" ;;
        '$HOME/'*)          d="$HOME/${d#\$HOME/}" ;;
    esac
    # `cd -` is the directory before the last `cd` — unknown before any.
    [[ "$d" == - ]] && d=${DIR_OLD:-"$DIR/-"}
    [[ "$d" == /* ]] || d="$DIR/$d"
    DIR_CD=$t
    if [[ $mode == P ]]; then
        # Bash's physical cd follows links before processing `..`.
        next=$(cd -P -- "$d" 2>/dev/null && pwd -P) || { DIR_UNRES=1; return; }
    else
        _logical_path "$d" || { DIR_UNRES=1; return; }
        next=$REPLY
    fi
    if [[ -d $next ]]; then DIR_OLD=$DIR; DIR=$next; DIR_UNRES=0; else DIR_UNRES=1; fi
}

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
        return 0
    }

    # A simple command is read ONCE, when it ends — a `cd` moves the walk's
    # directory, so it must be applied exactly once and only once it is
    # whole.
    _end_cmd() {
        local -a w=("${cw[@]}") l=("${cl[@]}")
        cw=(); cl=()
        local hatch=""
        while (( ${#w[@]} )) && [[ ${w[0]} =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; do
            [[ ${w[0]} == FLIGHT_PR_UNJUDGED=* ]] && hatch=${l[0]}
            w=("${w[@]:1}"); l=("${l[@]:1}")
        done
        if [[ ${w[0]:-} == cd ]]; then
            # `cd -P dir`, `cd -- dir`: the operand is the first word past
            # the options. A bare `cd` goes home.
            local j=1 mode=L opts
            while (( j < ${#w[@]} )) && [[ ${l[j]} =~ ^-[LPe@]+$ ]]; do
                opts=${l[j]#-}
                while [[ -n $opts ]]; do
                    case ${opts:0:1} in L|P) mode=${opts:0:1} ;; esac
                    opts=${opts:1}
                done
                ((j++))
            done
            (( j < ${#w[@]} )) && [[ ${l[j]} == -- ]] && ((j++))
            if (( j < ${#w[@]} )); then
                [[ -n ${l[j]} ]] && _cd_to "${l[j]}" "$mode"
            else
                _cd_to "~" "$mode"
            fi
        fi
        # `export FLIGHT_PR_UNJUDGED=…` is a real assignment too — the word
        # after `export` is checked keyword-safe like every other, so a quoted
        # name still does not count. The reason is typed in this transcript
        # either way, which is what the hatch's design requires.
        if [[ ${w[0]:-} == export ]]; then
            local k
            for k in "${!w[@]}"; do
                [[ ${w[k]} == FLIGHT_PR_UNJUDGED=* ]] || continue
                EXP_HATCH=1; EXP_REASON=${l[k]#FLIGHT_PR_UNJUDGED=}
            done
        fi
        (( ${#w[@]} >= 3 )) || return 0
        if [[ ${w[0]} == gh && ${w[1]} == pr && ${w[2]} == create ]]; then
            hit=0
            CREATE_DIR+=("$DIR"); CREATE_CD+=("$DIR_CD"); CREATE_UNRES+=("$DIR_UNRES")
            # A prefix assignment opens the hatch only on THIS simple command
            # — the one that invokes gh — which is also bash's own scope for
            # a VAR=value prefix. Failing that, an export already typed in
            # this frame; an export typed later has not happened yet.
            if [[ -n $hatch ]]; then
                CREATE_HATCH+=(1); CREATE_REASON+=("${hatch#FLIGHT_PR_UNJUDGED=}")
            else
                CREATE_HATCH+=("$EXP_HATCH"); CREATE_REASON+=("$EXP_REASON")
            fi
        fi
        return 0
    }

    while (( i < n )); do
        c=${s:i:1}

        # Inside a heredoc body: skip whole lines until the delimiter line.
        if [[ -n $hd_delim && $c == $'\n' ]]; then
            _emit; _end_cmd; ((i++))
            while (( i < n )); do
                rest=${s:i}
                raw=${rest%%$'\n'*}
                line=$raw
                (( hd_tabs )) && line=${line#"${line%%[!$'\t']*}"}
                i=$(( i + ${#raw} ))
                (( i < n )) && ((i++))
                if [[ $line == "$hd_delim" ]]; then hd_delim=""; break; fi
            done
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
            '(')
                _emit; _end_cmd; ((i++))
                FRAMES+=("$DIR" "$DIR_CD" "$DIR_UNRES" "$DIR_OLD" "$EXP_HATCH" "$EXP_REASON")
                continue ;;
            ')')
                _emit; _end_cmd; ((i++))
                # An unbalanced `)` — a `case` pattern — has no frame to pop.
                if (( ${#FRAMES[@]} >= 6 )); then
                    local f=$(( ${#FRAMES[@]} - 6 ))
                    DIR=${FRAMES[f]}; DIR_CD=${FRAMES[f+1]}; DIR_UNRES=${FRAMES[f+2]}
                    DIR_OLD=${FRAMES[f+3]}; EXP_HATCH=${FRAMES[f+4]}; EXP_REASON=${FRAMES[f+5]}
                    FRAMES=("${FRAMES[@]:0:f}")
                fi
                continue ;;
            ';'|'&'|'|'|$'\n'|'{'|'}')
                _emit; _end_cmd; ((i++)); continue ;;
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
    _emit; _end_cmd
    return $hit
}

# Creating a PR only. `gh pr view`, `gh pr list`, `gh pr merge`, a comment
# that quotes the phrase and a heredoc that writes it all pass untouched — a
# gate that interrupts reads is a gate people delete.
_gh_pr_create_invoked "$cmd" || exit 0

# WHERE EACH CREATE WILL RUN, which is not necessarily where the session is.
# A leader session sits in the main checkout and drives worktrees, so this is
# a normal shape rather than an exotic one. The walk above has already
# answered it, once per create — see _cd_to.
#
# The first thing every refusal says after its BLOCKED line: where the create
# was resolved to. A refusal that names only a report leaves the reader to
# infer the directory from the report's name, and a report named for the
# session's repo reads like a verdict on the repo the `cd` named.
resolved_to() {
    echo "Resolved to: $run_dir"
    if (( cd_unresolved )); then
        echo "  (the command's \`cd $cd_target\` is not a directory this guard can"
        echo "  see, so the create was judged where the shell stood before it —"
        echo "  only a leading ~ or \$HOME is expanded)"
    elif [[ -z $cd_target ]]; then
        echo "  (no \`cd\` in effect where the create runs, so the session's directory)"
    fi
    (( ${#CREATE_DIR[@]} > 1 )) &&
        echo "  (create $((n_create + 1)) of ${#CREATE_DIR[@]} in this command; each is judged where it runs)"
    return 0
}

# The durable directory, honoured from the environment when the runner set it,
# and the per-boot one kept as a fallback — the header says why each step is
# there and why neither is ever "fixed" by moving a file.
FLIGHT_STATE="${FLIGHT_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/teomach/flight}"
FLIGHT_STATE_PERBOOT="${XDG_RUNTIME_DIR:-/tmp}/flight"
RUNNER_HOME="$HOME/.bashrc.d/flight.sh"

runner_present() {
    command -v wingman-judge >/dev/null 2>&1 && return 0
    [[ -r "$RUNNER_HOME" ]]
}

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

# ── One create, judged where it runs. ───────────────────────────────────────
# Returns 2 with its refusal on stderr, or 0. Every create in the command is
# put through it, and the command is refused if ANY is: a create that passes
# never erases one that did not, whichever order they are typed in.
judge_create() {
    # ── The hatch, checked before the gate so a stated reason costs nothing. ──
    #
    # HATCH_SET is the walk's answer, held to the walk's own rule: the hatch
    # counts only as an assignment word seen in command position — a VAR=value
    # prefix on the invoking command, or an `export` typed before it — and
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
            return 2
        fi
        # The reason is in the transcript; this guard keeps no log — see header.
        return 0
    fi

    # Not a git worktree: nothing to key a report on, and `gh` will give a better
    # error than this hook can.
    root=$(git -C "$run_dir" rev-parse --show-toplevel 2>/dev/null) || return 0
    [[ -n "$root" ]] || return 0

    # One report per WORKTREE, named for it — `wingman-judge` keys on
    # `basename "$wt"`. The branch is not in the file NAME, so the name alone
    # cannot tell a report for this branch from one the previous branch left in
    # the same worktree; it is in the report's own header, which the identity
    # check below reads.
    report="$FLIGHT_STATE/judge-$(basename "$root").md"
    # The per-boot location is read only when the durable one holds no report for
    # THIS worktree, so a leftover there can never shadow a current report.
    # Whichever one is found then faces the same identity check below: a fallback
    # that relaxed staleness would buy a PR with a report for another commit.
    perboot_report="$FLIGHT_STATE_PERBOOT/judge-$(basename "$root").md"
    if [[ ! -f "$report" && -f "$perboot_report" ]]; then report="$perboot_report"; fi
    branch=$(git -C "$root" branch --show-current 2>/dev/null)
    topic="${branch:-<topic>}"

    head_sha=$(git -C "$root" rev-parse HEAD 2>/dev/null)
    head_time=$(git -C "$root" log -1 --format=%ct 2>/dev/null)
    [[ "$head_time" =~ ^[0-9]+$ ]] || return 0   # no commits yet; nothing to judge

    if [[ ! -f "$report" ]]; then
        {
            echo "BLOCKED: no judge report for this worktree, so this PR would carry"
            echo "no independence layer at all."
            echo
            resolved_to
            # BOTH PATHS IT LOOKED AT, in the order it looked. `report` is still
            # the durable one here: the fallback only replaces it when a report
            # is actually there, so reaching this block means neither existed.
            echo "Looked for: $report"
            [[ "$perboot_report" != "$report" ]] &&
                echo "      then: $perboot_report (per-boot)"
            # SAY WHAT DOES EXIST, AND SAY WHICH DIRECTORY EACH ONE IS IN. When
            # the gate resolves the wrong worktree a refusal that names one absent
            # path is unreadable — the report just run may be sitting beside it
            # under another name. A leader driving several lanes hits this first.
            # The headings carry the other half: an undifferentiated list drawn
            # from two directories reads as one set, so a lane takes the per-boot
            # leftovers for the canon and its own clean report for the odd one
            # out.
            dirs=("$FLIGHT_STATE")
            [[ "$FLIGHT_STATE_PERBOOT" != "$FLIGHT_STATE" ]] && dirs+=("$FLIGHT_STATE_PERBOOT")
            listed=0; listed_perboot=0
            for d in "${dirs[@]}"; do
                compgen -G "$d/judge-*.md" >/dev/null 2>&1 || continue
                (( listed )) || { echo; echo "Reports that DO exist:"; }
                listed=1
                [[ "$d" == "$FLIGHT_STATE_PERBOOT" && "$d" != "$FLIGHT_STATE" ]] && listed_perboot=1
                echo "  in $d:"
                for f in "$d"/judge-*.md; do echo "    $(basename "$f")"; done
            done
            if (( listed )); then
                if (( listed_perboot )); then
                    echo
                    echo "The ones under $FLIGHT_STATE_PERBOOT are in"
                    echo "the per-boot directory, which the cockpit does not write"
                    echo "reports to: their presence says nothing about where yours"
                    echo "should be."
                fi
                echo
                echo "If you are driving another worktree from a leader session, put"
                echo "the 'cd' in this same command — the hook is told the session's"
                echo "directory, not the shell's, so a 'cd' in an earlier call is"
                echo "invisible to it:"
                echo "    cd <worktree> && gh pr create ..."
            fi
        explain
        } >&2
        return 2
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
                resolved_to
                echo "Report:  $report"
                echo "  judged ${rbranch:-?} at ${rsha:0:12}"
                echo "  HEAD is ${branch:-detached} at ${head_sha:0:12} — $(git -C "$root" log -1 --format='%s' 2>/dev/null)"
            explain
            } >&2
            return 2
        fi
    else
        report_time=$(stat -c %Y "$report" 2>/dev/null) ||
            report_time=$(stat -f %m "$report" 2>/dev/null)
        if [[ ! "$report_time" =~ ^[0-9]+$ ]]; then
            {
                echo "BLOCKED: cannot read the legacy judge report's timestamp."
                resolved_to
                echo "Report:  $report"
            explain
            } >&2
            return 2
        fi
        if (( report_time < head_time )); then
            {
                echo "BLOCKED: the judge report is older than HEAD, so it judged a diff"
                echo "you have since committed over."
                echo
                resolved_to
                echo "Report:  $report (Unix time $report_time)"
                echo "HEAD:    $(git -C "$root" log -1 --format='%h %s' 2>/dev/null) (Unix time $head_time)"
                echo
                echo "(This report predates the header that names its branch and SHA,"
                echo "so the check is recency rather than identity. Re-run the judge"
                echo "and it will carry both.)"
            explain
            } >&2
            return 2
        fi
    fi
    return 0
}

status=0
JUDGED_DIR=(); JUDGED_HATCH=(); JUDGED_REASON=()
for n_create in "${!CREATE_DIR[@]}"; do
    run_dir=${CREATE_DIR[n_create]}
    cd_target=${CREATE_CD[n_create]}
    cd_unresolved=${CREATE_UNRES[n_create]}
    HATCH_SET=${CREATE_HATCH[n_create]}
    HATCH_REASON=${CREATE_REASON[n_create]}
    # Two creates that would be judged identically are judged once, so one
    # missing report is not refused twice over.
    duplicate=0
    for prior in "${!JUDGED_DIR[@]}"; do
        if [[ ${JUDGED_DIR[prior]} == "$run_dir" &&
              ${JUDGED_HATCH[prior]} == "$HATCH_SET" &&
              ${JUDGED_REASON[prior]} == "$HATCH_REASON" ]]; then
            duplicate=1
            break
        fi
    done
    (( duplicate )) && continue
    JUDGED_DIR+=("$run_dir"); JUDGED_HATCH+=("$HATCH_SET")
    JUDGED_REASON+=("$HATCH_REASON")
    judge_create || status=2
done
exit $status
