#!/usr/bin/env bash
# Source: teomach-skills harness/hooks/pre-bash-no-pollution.sh —
# edit it there and re-run `scripts/wire-repo.py update`, never edit a copy.
# PreToolUse (Bash) — the environment ladder's floor, made mechanical.
#
# Three refusals, and only three:
#
#   1. a global package install — the ladder's kept hygiene, "no global package
#      installs, ever". Language-level (`npm -g`, `pip install`, `cargo
#      install`) and system-level (`dnf install`, `brew install`) alike;
#   2. an elevation — `sudo`, `doas`, `pkexec`, whatever follows it. Broader
#      than an install by design: the ladder's hygiene says system packages
#      arrive by declared state, and elevation is how a session mutates the
#      machine at all rather than only how it installs;
#   3. a write to an absolute path outside this repo — the same hygiene from the
#      other side, since what a job's failure leaks into is the question the
#      ladder asks when choosing a rung.
#
# WHAT IS NOT "OUTSIDE", and why refusing it would be refusing the work:
#
#   · the temp roots, which are this guard's OWN alternative to a write outside
#     the tree ("scratch work that is not a deliverable — /tmp", in the refusal
#     below) and where a session harness that hands out a scratchpad directory
#     puts it — so a lane prompt or a PR body drafted for `gh --body-file`
#     lands there;
#   · the leader-to-leader notes folder of
#     `method/references/cross-flight-notes.md`, whose transport IS "a plain
#     shared folder outside every repo".
#
# `inside()` names both.
#
# THE FLOOR, NOT THE LADDER. The ladder chooses a rung per job, weighs what a
# failure would leak into, and knows when a `podman` world is worth spinning up.
# None of that is decidable from a command string, and a guard that guessed at
# it would refuse real work. So this enforces only what is wrong at every rung,
# and the refusal points at the ladder for the judgement it cannot make.
# `method/references/environment-ladder.md` holds the rule; this file does not
# restate it.
#
# HONEST LIMITS, stated rather than discovered later:
#
#   · A missing or non-executable hook script FAILS OPEN (measured, Claude Code
#     2.1.220) — so this is a discipline with teeth, not a boundary. The
#     SessionStart guard tests for it positively, which is the only reason its
#     silence means anything.
#   · It reads the command AS WRITTEN. A `bash -c` with a constructed string, or
#     a path arriving through a variable, is not seen. It closes the habitual
#     path, which is the one that actually leaks.
#   · Relative paths are treated as inside the tree, because the payload's `cwd`
#     is the SESSION's directory and not where the command will run (measured):
#     a `cd` in an earlier tool call leaves no evidence at all. A `cd` to an
#     outside absolute path in THIS command is caught, being the one case there
#     is evidence for.
#   · Quoting is read, but only as far as a balanced command goes. An operator
#     inside a quoted argument is masked (see the block above the scans), so a
#     `>` in a sentence is a `>`; an UNBALANCED quote leaves the walker in a
#     quoted state to the end of the string and masks the rest of it. Bash
#     will not run such a command either, so the string was never a write.
#   · A heredoc's body is data and not command text, so it is stripped before
#     the scans read it — the block above them says why. The cost is real and
#     runs the other way: a multi-line `<<` that is a shift rather than a
#     heredoc takes the lines after it with it, and those lines go unscanned.
#
# WHY DENY RATHER THAN ASK. The model sees the stderr of an `exit 2` and acts on
# it, so a refusal naming the exact alternative gets repaired by the agent with
# no human in the loop. `ask` would put a prompt in front of a person for
# something the agent can correct itself.

set -uo pipefail
set -f      # someone else's command string is data: never glob it against our cwd
# shellcheck source=_payload.sh
. "$(dirname "${BASH_SOURCE[0]}")/_payload.sh"

payload_read
CMD="$(json_str tool_input.command)"
[ -n "$CMD" ] || exit 0
REPO="$(repo_root "$(json_str cwd)")"

refuse() {   # refuse <headline> <what-to-do-instead...>
    local headline="$1"; shift
    {
        echo "BLOCKED: $headline"
        echo
        printf '%s\n' "$@"
        echo
        echo "The rule, with the judgement this guard cannot make:"
        echo "  method/references/environment-ladder.md (the \`method\` kernel)"
    } >&2
    exit 2
}

# A path this repo's work may write to. Anything else absolute is outside.
inside() {
    local p="$1" notes
    p="${p%\"}"; p="${p#\"}"; p="${p%\'}"; p="${p#\'}"
    # The patterns below are literal text in someone else's command string, not
    # paths for this shell to expand — hence the quoting shellcheck warns about.
    # shellcheck disable=SC2088,SC2016
    case "$p" in
        "~/"*)     p="$HOME/${p#\~/}" ;;
        '$HOME/'*) p="$HOME/${p#\$HOME/}" ;;
        '${HOME}/'*) p="$HOME/${p#\$\{HOME\}/}" ;;
        /*)        : ;;
        *)         return 0 ;;   # relative — inside, by the limit stated above
    esac
    case "$p" in
        /dev/null|/dev/stdout|/dev/stderr|/dev/tty|/dev/fd/*|/proc/self/fd/*) return 0 ;;
        /tmp|/tmp/*|/var/tmp|/var/tmp/*) return 0 ;;
        "$REPO"|"$REPO"/*) return 0 ;;
    esac
    if [ -n "${TMPDIR:-}" ]; then
        case "$p" in "${TMPDIR%/}"|"${TMPDIR%/}"/*) return 0 ;; esac
    fi
    # The cross-flight notes folder. Its reference makes "a plain shared folder
    # outside every repo" the whole transport, so the guard has to know the
    # name: `~/Code/flight-notes/` as that page gives it, with
    # $TEOMACH_FLIGHT_NOTES for a machine that puts it elsewhere.
    notes="${TEOMACH_FLIGHT_NOTES:-$HOME/Code/flight-notes}"
    case "$p" in "${notes%/}"|"${notes%/}"/*) return 0 ;; esac
    return 1
}

# The five masked operators back to the characters they stand for. A refusal
# names the path the way the command wrote it, sentinels and all being this
# guard's own bookkeeping and no business of the message.
demask() {
    local s="$1"
    s="${s//$'\001'/>}"; s="${s//$'\002'/<}"; s="${s//$'\003'/;}"
    s="${s//$'\004'/|}"; s="${s//$'\005'/&}"
    printf '%s' "$s"
}

# 0 when any command word in <text> hands a string to another shell, which is
# what switches the masking off. The list is the runners a session actually
# reaches for, plus the elevations — `sudo bash -c` must keep reaching the
# elevation refusal below whatever its argument is quoted like. A word is
# taken at a command position only: the segment's first, after the leading
# `VAR=value` assignments the split leaves in front of it, and basenamed so
# that `/usr/bin/bash` is `bash`.
shell_runner() {
    local seg w
    while IFS= read -r seg; do
        # shellcheck disable=SC2206   # deliberate: split the segment into words
        local ws=($seg)
        while [ "${#ws[@]}" -gt 0 ] && [[ "${ws[0]}" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; do
            ws=("${ws[@]:1}")
        done
        w="${ws[0]:-}"; w="${w##*/}"
        w="${w%\"}"; w="${w#\"}"; w="${w%\'}"; w="${w#\'}"
        case "$w" in
          sh|bash|dash|zsh|ksh|fish|eval|exec|source|.|env|nohup|timeout|watch|xargs|\
          ssh|su|sudo|doas|pkexec|podman|docker|nsenter|chroot|flatpak-spawn|\
          toolbox|distrobox)
            return 0 ;;
        esac
    done < <(printf '%s\n' "$1" | awk '{ gsub(/&&|\|\||\||;/, "\n"); print }')
    return 1
}

outside_write() {   # outside_write <path> <verb>
    inside "$1" && return 0
    refuse "this writes outside the working tree — \`$2\` targeting $(demask "$1")" \
"A session's deliverables are the repo it is in. Nothing it produces should" \
"land where the next clone of this repo cannot see it, and nothing it needs" \
"should be installed where the next job inherits it." \
"" \
"Do one of these instead:" \
"  · keep the file in the repo — a path under $REPO" \
"  · scratch work that is not a deliverable — /tmp" \
"  · a service, a pinned runtime or a destructive test beside the job —" \
"    an ephemeral \`podman compose\` world, torn down after"
}

# A heredoc's body is data, not command text: everything from the `<<DELIM`
# line to the delimiter line. It is removed before either scan below reads
# $CMD, because left in, the first `>` in a line of prose opens a redirection
# target — a document mentioning `~/.claude/projects/<key>/*.jsonl` was refused
# as a write to `/*.jsonl`, and `cat > file <<'MD'` is how a session writes a
# document at all. It is the same distinction the `sed` case makes further
# down between a script and a file operand: what a token IS beats what it
# looks like.
#
# What survives the strip, deliberately: the operator line itself, so
# `cat > /etc/motd <<'MD'` still refuses; every line after the delimiter,
# so a second command in the same string is still read; and `<<<`, which is a
# here-string carrying its word on that line and no body at all. Several
# heredocs on one line take their bodies in order, hence a queue of pending
# delimiters, and `<<-` lets the line that ends it be indented with tabs.
CMD="$(printf '%s\n' "$CMD" | awk '
    BEGIN {
        q  = sprintf("%c", 39)
        RE = "<<-?[ \t]*(\\\\?[A-Za-z_][A-Za-z0-9_]*|\"[^\"]*\"|" q "[^" q "]*" q ")"
    }
    function delim_of(tok,   d, c) {
        d = tok
        sub(/^<<-?[ \t]*/, "", d)
        c = substr(d, 1, 1)
        if (c == "\\") return substr(d, 2)
        if (c == "\"" || c == q) return substr(d, 2, length(d) - 2)
        return d
    }
    {
        if (pending > 0) {                      # inside a body: drop it
            line = $0
            if (dash[1]) sub(/^\t+/, "", line)
            if (line == delim[1]) {
                for (i = 1; i < pending; i++) { delim[i] = delim[i+1]; dash[i] = dash[i+1] }
                pending--
            }
            next
        }
        rest = $0
        while (match(rest, RE)) {
            tok  = substr(rest, RSTART, RLENGTH)
            pre  = substr(rest, 1, RSTART - 1)
            rest = substr(rest, RSTART + RLENGTH)
            if (pre ~ /<$/) continue          # `<<<word` — a here-string
            pending++
            delim[pending] = delim_of(tok)
            dash[pending]  = (tok ~ /^<<-/)
        }
        print
    }
')"

# A quoted argument is DATA, not command text. The guard reads the command AS
# WRITTEN, so an operator inside a quoted string reads as the operator it looks
# like unless something stops it. Three measured shapes, each a
# `gh issue create --body '…'` describing this guard's own refusal back to it:
#
#   · `ran `cat > ~/Code/flight-logs/x.md` and it failed` — a redirection;
#   · `offered /tmp -> ~/Code/flight-logs/x.md instead` — the `>` of an arrow,
#     so the backticks are incidental: prose alone is enough;
#   · `it failed; mkdir ~/Code/flight-logs was next` — the `;` splits the body
#     and `mkdir` becomes the second command's verb.
#
# The third is the segment splitter and not the redirection scan, which is why
# the masking has to serve both.
#
# So `> < ; | &` inside a single- or double-quoted region is replaced by a
# sentinel before either scan reads $CMD. The five are kept distinct and put
# back by `demask` for a refusal message, so a path that genuinely carries one
# is still named the way it was written.
#
# WHAT IS NOT MASKED, and why refusing to mask it is the point: text a shell
# will actually run. A backtick or `$(…)` substitution is live, and so is
# every quoted string in a command that hands one to another shell —
# `bash -c 'cat > /etc/motd'` is command text that merely looks quoted. There
# is no reading the argument that tells them apart, so the masking is switched
# off for the WHOLE command the moment any command word in it is a runner.
# Over-refusing inside a `bash -c` is the nuisance that stays; under-refusing
# a write is still the failure worth having. It is the same distinction the
# `sed` case makes below: what a token IS beats what it looks like.
MASKED="$(printf '%s\n' "$CMD" | awk '
    BEGIN {
        SQ = sprintf("%c", 39); DQ = sprintf("%c", 34); BQ = sprintf("%c", 96)
        OPS = ">" "<" ";" "|" "&"
        for (i = 1; i <= 5; i++) SENT[substr(OPS, i, 1)] = sprintf("%c", i)
        depth = 0            # st[1..depth]: the quoting contexts still open
    }
    {
        out = ""; i = 1; L = length($0)
        while (i <= L) {
            c = substr($0, i, 1)
            top = (depth ? st[depth] : "OUT")
            if (top == "SQ") {                       # nothing is special but the close
                if (c == SQ) { depth--; out = out c }
                else if (c in SENT) out = out SENT[c]
                else out = out c
                i++; continue
            }
            if (top == "DQ") {
                if (c == "\\") { out = out substr($0, i, 2); i += 2; continue }
                if (c == DQ)   { depth--; out = out c; i++; continue }
                if (c == BQ)   { st[++depth] = "BQ"; out = out c; i++; continue }
                if (c == "$" && substr($0, i + 1, 1) == "(") {
                    st[++depth] = "SUB"; out = out "$("; i += 2; continue }
                if (c in SENT) { out = out SENT[c]; i++; continue }
                out = out c; i++; continue
            }
            # live — OUT, or inside a substitution, where operators are real
            if (c == "\\") { out = out substr($0, i, 2); i += 2; continue }
            if (c == SQ)   { st[++depth] = "SQ"; out = out c; i++; continue }
            if (c == DQ)   { st[++depth] = "DQ"; out = out c; i++; continue }
            if (c == BQ)   { if (top == "BQ") depth--; else st[++depth] = "BQ"
                             out = out c; i++; continue }
            if (c == "$" && substr($0, i + 1, 1) == "(") {
                st[++depth] = "SUB"; out = out "$("; i += 2; continue }
            if (c == ")" && top == "SUB") { depth--; out = out c; i++; continue }
            out = out c; i++
        }
        print out
    }
')"
shell_runner "$MASKED" || CMD="$MASKED"

# Every redirection target in the command, whatever segment it sits in.
while read -r t; do
    [ -n "$t" ] || continue
    outside_write "$t" "redirection"
done < <(printf '%s\n' "$CMD" |
         grep -oE '>>?[[:space:]]*[^[:space:]<>|&;()]+' |
         sed -E 's/^>>?[[:space:]]*//')

# One segment per command: splitting on the separators puts the command word
# first, which is what makes "at a command position" a lookup rather than a
# regex nobody can read.
cd_outside=""
while IFS= read -r seg; do
    [ -n "${seg// /}" ] || continue
    # shellcheck disable=SC2206   # deliberate: split the segment into words
    words=($seg)
    while [ "${#words[@]}" -gt 0 ] && [[ "${words[0]}" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; do
        words=("${words[@]:1}")
    done
    [ "${#words[@]}" -gt 0 ] || continue
    verb="${words[0]}"
    args=("${words[@]:1}")
    bare=()
    for a in ${args[@]+"${args[@]}"}; do
        case "$a" in -*) ;; *) bare+=("$a") ;; esac
    done

    case "$verb" in
      sudo|doas|pkexec)
        refuse "this asks for elevation (\`$verb\`), which changes the machine rather than the work" \
"Nothing a session needs should outlive it on this machine. System packages" \
"arrive by declared state, not by hand from inside a session." \
"" \
"Do instead:" \
"  · a runtime or service the job needs — an ephemeral \`podman compose\` world" \
"  · a change the machine genuinely needs — raise it as declared state, in the" \
"    repo that owns the estate, and let the human apply it"
        ;;

      npm|pnpm|bun)
        for a in ${args[@]+"${args[@]}"}; do
            case "$a" in
              -g|--global|--location=global)
                refuse "this installs a package globally (the \`$a\` flag on \`$verb\`)" \
"A global package serves every job on the machine and is owned by none, so it" \
"drifts out from under the next one." \
"" \
"Do instead:" \
"  · drop the flag — a project-local install writes to ./node_modules" \
"  · run a one-off tool without installing it — \`npx <tool>\`"
                ;;
            esac
        done
        ;;

      yarn)
        [ "${bare[0]:-}" = global ] &&
            refuse "this installs a package globally (\`yarn global\`)" \
"A global package serves every job on the machine and is owned by none." \
"" \
"Do instead: \`yarn add <pkg>\` in the project, which writes to ./node_modules"
        ;;

      pip|pip3)
        [ "${bare[0]:-}" = install ] &&
            refuse "this installs into the interpreter rather than into a project (\`$verb install\`)" \
"Python dependencies live in a project-local environment, so that a second" \
"project cannot be broken by this one's pins." \
"" \
"Do instead:" \
"  · \`uv add <pkg>\` — records the dependency and installs it into the venv" \
"  · \`uv pip install <pkg>\` — the same install, when there is no manifest yet"
        ;;

      python|python3|python2|python3.*|python2.*)
        if [ "${args[0]:-}" = "-m" ] && [ "${args[1]:-}" = "pip" ] && [ "${args[2]:-}" = "install" ]; then
            refuse "this installs into the interpreter rather than into a project (\`$verb -m pip install\`)" \
"Python dependencies live in a project-local environment." \
"" \
"Do instead: \`uv add <pkg>\`, or \`uv pip install <pkg>\` when there is no manifest yet"
        fi
        ;;

      gem|cargo|go)
        [ "${bare[0]:-}" = install ] &&
            refuse "this installs a binary onto the machine (\`$verb install\`)" \
"A tool installed this way outlives the job that wanted it and is pinned by" \
"nobody." \
"" \
"Do instead:" \
"  · a build dependency — declare it in the project's manifest and build locally" \
"  · a one-off tool — run it inside an ephemeral \`podman\` container"
        ;;

      apt|apt-get|dnf|yum|pacman|apk|zypper|brew)
        case "${bare[0]:-}" in
          install|add|upgrade|-S)
            refuse "this installs a system package (\`$verb ${bare[0]}\`)" \
"System packages arrive by declared state in the repo that owns the estate," \
"never by hand from inside a session — otherwise the machine and its" \
"description diverge and nobody knows which is true." \
"" \
"Do instead:" \
"  · the job needs a runtime beside it — an ephemeral \`podman compose\` world" \
"  · the machine genuinely needs it — raise it as declared state for the human"
            ;;
        esac
        ;;

      cd)
        [ -n "${bare[0]:-}" ] && ! inside "${bare[0]}" && cd_outside="${bare[0]}"
        ;;

      cp|mv|install|rsync|ln)
        [ "${#bare[@]}" -gt 1 ] && outside_write "${bare[$(( ${#bare[@]} - 1 ))]}" "$verb"
        ;;

      rm|rmdir|mkdir|touch|truncate|unlink|tee|chmod|chown|chgrp)
        for a in ${bare[@]+"${bare[@]}"}; do outside_write "$a" "$verb"; done
        ;;

      dd)
        for a in ${args[@]+"${args[@]}"}; do
            case "$a" in of=*) outside_write "${a#of=}" "dd" ;; esac
        done
        ;;

      sed)
        # Only the FILE operands are paths. sed's operands are a script — but
        # only when no `-e`/`-f` already supplied one — followed by the files it
        # edits. Read every non-flag word as a path and the `/^x/d` of `sed -i
        # '/^x/d' notes.md` is a write to `/`: an address is a script, not a
        # directory. `-e`/`-f` take a value, attached or as the next word;
        # `-i`'s value is a suffix and is always attached.
        sed_in_place=""; sed_script=""; sed_skip=""; sed_operands=""
        sed_files=()
        for a in ${args[@]+"${args[@]}"}; do
            if [ -n "$sed_skip" ]; then sed_skip=""; continue; fi
            if [ -z "$sed_operands" ]; then
                case "$a" in
                  --)                     sed_operands=1; continue ;;
                  --in-place|--in-place=*) sed_in_place=1; continue ;;
                  --expression|--file)    sed_script=1; sed_skip=1; continue ;;
                  --expression=*|--file=*) sed_script=1; continue ;;
                  --*)                    continue ;;
                  -?*)
                    rest="${a#-}"
                    while [ -n "$rest" ]; do
                        c="${rest%"${rest#?}"}"; rest="${rest#?}"
                        case "$c" in
                          e|f) sed_script=1
                               if [ -n "$rest" ]; then rest=""; else sed_skip=1; fi ;;
                          i)   sed_in_place=1; rest="" ;;   # the rest is the suffix
                        esac
                    done
                    continue ;;
                esac
            fi
            if [ -z "$sed_script" ]; then sed_script=1; continue; fi   # the script
            sed_files+=("$a")
        done
        if [ -n "$sed_in_place" ]; then
            for b in ${sed_files[@]+"${sed_files[@]}"}; do outside_write "$b" "sed -i"; done
        fi
        ;;
    esac

    # A `cd` out of the tree earlier in this same command makes the relative
    # paths after it relative to somewhere else. This is the only case there is
    # evidence for; see the limits at the top.
    if [ -n "$cd_outside" ]; then
        case "$verb" in
          cp|mv|install|rsync|ln|rm|rmdir|mkdir|touch|truncate|unlink|tee|dd|chmod|chown|chgrp)
            refuse "this changes directory to $(demask "$cd_outside") and then writes (\`$verb\`)" \
"Everything after that \`cd\` lands outside this repo, whether or not the paths" \
"look relative." \
"" \
"Do instead:" \
"  · work on paths under $REPO" \
"  · scratch work that is not a deliverable — /tmp"
            ;;
        esac
    fi
done < <(printf '%s\n' "$CMD" | awk '{ gsub(/&&|\|\||\||;/, "\n"); print }')

exit 0
