#!/usr/bin/env bash
# Source: teomach-skills harness/hooks/_walk.sh —
# edit it there and re-run `scripts/wire-repo.py update`, never edit a copy.
# Shared by the Bash guards that act on one `gh pr` verb — pre-bash-pr-gate.sh
# on `create`, pre-bash-merge-hold.sh on `merge`. Sourced, never run.
#
# IS `gh pr <verb>` INVOKED, or merely MENTIONED? The walk reads the command
# string as a shell would and asks a structural question: does any SIMPLE
# COMMAND begin — after any VAR=value assignments — with the three bare words
# `gh` `pr` `<verb>`? Why it is structural rather than a regex, and what it
# concedes (quoted `gh`, `bash -c`, control flow), is pre-bash-pr-gate.sh's
# header.
#
# It also records, FOR EACH HIT, the directory the shell will be in when that
# command runs, because this walk is the only place that information exists.
# A `cd` moves the walk's directory from the point it is typed on; a hit takes
# the directory in effect AT ITS OWN POSITION, so a `cd` after it moves
# nothing it is judged against — see _cd_to. A guard with a hatch names its
# variable, and the hatch is read by the same structural rule as everything
# else the walk answers: it counts only as a real assignment word, never as
# text inside a quoted argument — and it too is bound to the hits it
# precedes, never to one already behind it.
#
# The walk's state, one frame of it: where the shell is, the `cd` operand
# that put it there as typed (for the refusal), whether the last `cd` could
# not be followed, the directory before it (for `cd -`), and an exported
# hatch. A subshell — `(` … `)`, which is also `$(` … `)` — pushes a frame on
# entry and pops it on exit, because a `cd` or an `export` inside one does
# not survive it.
#
# gh_pr_walk <verb> <hatch variable, or ""> <command string> <start directory>
# returns 0 when the verb is invoked at least once, and sets one array entry
# per hit, in the order they appear: HIT_DIR, HIT_CD, HIT_UNRES, HIT_HATCH,
# HIT_REASON, and HIT_ARGS — the words typed after the verb, quote-removed
# and joined with \x1f, so a caller can read the PR they name.

gh_pr_walk() {
    DIR="${4:-.}"; DIR_CD=""; DIR_UNRES=0; DIR_OLD=""; EXP_HATCH=0; EXP_REASON=""
    FRAMES=()
    HIT_DIR=(); HIT_CD=(); HIT_UNRES=(); HIT_HATCH=(); HIT_REASON=(); HIT_ARGS=()
    _gh_pr_walk "$1" "$2" "$3"
}

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

_gh_pr_walk() {
    local verb=$1 hv=$2 s=$3
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
            [[ -n $hv && ${w[0]} == "$hv"=* ]] && hatch=${l[0]}
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
                [[ -n $hv && ${w[k]} == "$hv"=* ]] || continue
                EXP_HATCH=1; EXP_REASON=${l[k]#"$hv"=}
            done
        fi
        (( ${#w[@]} >= 3 )) || return 0
        if [[ ${w[0]} == gh && ${w[1]} == pr && ${w[2]} == "$verb" ]]; then
            hit=0
            HIT_DIR+=("$DIR"); HIT_CD+=("$DIR_CD"); HIT_UNRES+=("$DIR_UNRES")
            local joined
            printf -v joined '%s\x1f' "${l[@]:3}"
            HIT_ARGS+=("${joined%$'\x1f'}")
            # A prefix assignment opens the hatch only on THIS simple command
            # — the one that invokes gh — which is also bash's own scope for
            # a VAR=value prefix. Failing that, an export already typed in
            # this frame; an export typed later has not happened yet.
            if [[ -n $hatch ]]; then
                HIT_HATCH+=(1); HIT_REASON+=("${hatch#"$hv"=}")
            else
                HIT_HATCH+=("$EXP_HATCH"); HIT_REASON+=("$EXP_REASON")
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
