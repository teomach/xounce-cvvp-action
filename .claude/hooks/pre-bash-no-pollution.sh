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
# HOW IT READS A COMMAND. A shell lexer (the awk program in `lex`, below)
# walks the string the way bash tokenises it — quotes, backslashes,
# backslash-newline, comments, `;`/`&`/`|`/newline as separators, control
# words, `( )` and `{ }`, redirections, heredocs — and yields one record per
# SIMPLE COMMAND with its words quote-removed, one per redirection with its
# target, and one per scope opened or closed. Text a shell will run is
# followed into: a `$( )`, `<( )`, `>( )` or backtick substitution; the body
# a shell is handed by `-c`, by `eval`, by a pipe or by a heredoc; the command
# `find -exec` runs; the words `xargs` passes on. A `find` command's own
# starting-point paths are read as writes when `-delete` is present, the same
# reading `rm` and its kin get below — not text followed into another shell.
# The scans below read only those records, so "at a command position" is a
# lookup and never a regex, and a `>` in a quoted sentence is a character.
# `--lex` on the command line prints the records for a payload instead of
# judging them — the way to see what the guard saw.
#
# HONEST LIMITS, stated rather than discovered later:
#
#   · A missing or non-executable hook script FAILS OPEN (measured, Claude Code
#     2.1.220) — so this is a discipline with teeth, not a boundary. The
#     SessionStart guard tests for it positively, which is the only reason its
#     silence means anything.
#   · It reads what is LITERAL. A path or a command arriving through a
#     variable (`touch "$f"`, `bash -c "$cmd"`), an alias or a function
#     defined in an earlier call, is not seen; a variable-led path counts as
#     relative, so it is treated as inside. It closes the habitual path, which
#     is the one that actually leaks.
#   · It reads what is IN THE STRING. A script file a shell is given
#     (`bash setup.sh`, `source x`, `. x`) is not opened; a path `xargs`
#     reads from stdin is not seen; a heredoc or pipe into an interpreter
#     that is not a shell (`python3 <<EOF`) is data to this guard, whatever
#     that interpreter does with it; a pipe reaches a bare shell only from
#     the command directly before it. A runner that leaves the machine
#     (`ssh`, `podman exec`) is not followed.
#   · Relative paths are treated as inside the tree, because the payload's `cwd`
#     is the SESSION's directory and not where the command will run (measured):
#     a `cd` in an earlier tool call leaves no evidence at all. A `cd` to an
#     outside absolute path in THIS command is caught, being the one case there
#     is evidence for, and is scoped to the subshell, substitution or runner
#     it ran in — a `{ }` group and `eval` run in the same shell and keep it.
#   · An UNBALANCED quote or substitution runs to the end of the string and
#     the words it holds are judged as they stand. Bash will not run such a
#     command either, so a refusal there costs nothing.
#   · A function's body is read where it is defined, not where it is called:
#     `f() { touch /etc/motd; }` is refused at the definition.
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
# The word arrives quote-removed from the lexer, so `'/etc/motd'` is
# `/etc/motd` here and a refusal names it as the command wrote it.
inside() {
    local p="$1" notes
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

outside_write() {   # outside_write <path> <verb>
    inside "$1" && return 0
    refuse "this writes outside the working tree — \`$2\` targeting $1" \
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

# THE LEXER. One record per line, fields separated by the unit separator
# (\037), which no command string carries:
#
#   C <word> <word> …   a simple command, words quote-removed, leading
#                       assignments and wrappers already stepped over, so
#                       the first field is the verb (`time`, `exec`, `env`,
#                       `nice`, `timeout`, `xargs` and their kin hand their
#                       arguments to a command rather than being one, and
#                       their own flags and a duration or niceness go with
#                       them). A verb spelled absolutely is basenamed, so
#                       `/usr/bin/pip` is `pip`; a relative spelling is left
#                       whole, because `.venv/bin/pip` is the project-local
#                       environment the pip refusal points the reader at.
#   R <op> <target>     a redirection; `>`, `>>`, `>|`, `&>`, `&>>`, `<>` and
#                       `>&` with a path are writes, the rest are reads.
#   O sub | O grp       a scope opens — a subshell, substitution, runner body
#                       or `find -exec` (`sub`), or a `{ }` group (`grp`).
#   X sub | X grp       that scope closes.
#
# Records come in the order the shell would reach them: a substitution's
# commands before the command whose word holds it, a heredoc's body after the
# line that opened it, a runner's body right after the runner's own record.
# The reader below keeps the scope depth for the one piece of state that
# crosses records, a `cd` out of the tree.
lex() {   # lex <command text> — records on stdout
    printf '%s\n' "$1" | awk '
    BEGIN {
        SQ = sprintf("%c", 39); DQ = sprintf("%c", 34); BQ = sprintf("%c", 96)
        US = sprintf("%c", 31)
        M_NONE = 0; M_TEST = 1; M_FOR = 2; M_CASEIN = 3; M_CASEPAT = 4; M_FUNC = 5
        split("sh bash dash zsh ksh", a, " "); for (k in a) SHELL[a[k]] = 1
        split("time exec command builtin nohup env nice timeout stdbuf setsid ionice xargs", a, " ")
        for (k in a) WRAPPER[a[k]] = 1
        # a wrapper flag whose value is the NEXT word, so `xargs -I {} cp` and
        # `env -u FOO touch` reach the verb after the value and not the value
        split("xargs:-I xargs:-i xargs:-L xargs:-n xargs:-P xargs:-s xargs:-d xargs:-E xargs:-a " \
              "env:-u env:-C env:-S timeout:-k timeout:-s nice:-n ionice:-c ionice:-n ionice:-p " \
              "stdbuf:-i stdbuf:-o stdbuf:-e exec:-a", a, " ")
        for (k in a) VALFLAG[a[k]] = 1
        split("-exec -execdir -ok -okdir", a, " "); for (k in a) FINDEXEC[a[k]] = 1
        nhd = 0; ncmd = 0; prev_pipe = 0; prev_id = 0
    }
    { src = src $0 "\n" }
    END { lex(src, 1, "", st) }

    function emit(rec) { gsub(/\n/, " ", rec); print rec }

    # --- words -------------------------------------------------------------
    function reset(st) { st["w"] = ""; st["wq"] = 0; st["have"] = 0 }
    function app(st, t, q) { st["w"] = st["w"] t; st["have"] = 1; if (q) st["wq"] = 1 }

    # A word is complete. Where it goes depends on what stands before it.
    function endword(st,    w, q) {
        if (!st["have"]) return
        w = st["w"]; q = st["wq"]; reset(st)
        if (st["redir"] != "") { emit("R" US st["redir"] US w); st["redir"] = ""; return }
        if (st["hdwait"]) {
            nhd++; hd_delim[nhd] = w; hd_quoted[nhd] = q; hd_dash[nhd] = st["hddash"]
            if (!st["id"]) st["id"] = ++ncmd
            hd_cmd[nhd] = st["id"]; st["hdwait"] = 0
            return
        }
        if (st["mode"] == M_FOR || st["mode"] == M_CASEPAT) return
        if (st["mode"] == M_CASEIN) { if (!q && w == "in") st["mode"] = M_CASEPAT; return }
        if (st["mode"] == M_FUNC) { st["mode"] = M_NONE; return }
        if (st["mode"] == M_TEST) {
            if (!q && w == "]]") st["mode"] = M_NONE
            st[++st["nw"]] = w; return
        }
        if (!q && w == "}") { endcmd(st); emit("X" US "grp"); return }
        if (st["nw"] == 0 && !q) {          # a reserved word at a command position
            if (w ~ /^(if|then|else|elif|do|while|until|!|coproc)$/) return
            if (w == "{") { emit("O" US "grp"); return }
            if (w ~ /^(fi|done)$/) return
            if (w == "esac") { if (st["casedepth"] > 0) st["casedepth"]--; return }
            if (w == "for" || w == "select") { st["mode"] = M_FOR; return }
            if (w == "case") { st["mode"] = M_CASEIN; st["casedepth"]++; return }
            if (w == "function") { st["mode"] = M_FUNC; return }
            if (w == "[[") st["mode"] = M_TEST
        }
        st[++st["nw"]] = w
    }

    # A separator: the simple command so far is done.
    function endcmd(st,    n, k) {
        n = st["nw"]
        if (st["mode"] == M_FOR) st["mode"] = M_NONE
        if (n > 0) {
            if (!st["id"]) st["id"] = ++ncmd
            for (k = 1; k <= n; k++) cw[k] = st[k]
            command(cw, n, st["id"])
        }
        st["nw"] = 0; st["id"] = 0
    }

    # --- a simple command ----------------------------------------------------
    # Assignments and wrappers stepped over, the verb basenamed where it is
    # absolute, the record emitted, and whatever the command hands to another
    # shell followed into.
    function command(w, n, id,    k, m, v, out, cflag, body, sst, cnt, j) {
        k = 1
        while (k <= n) {
            v = w[k]
            if (v ~ /^[A-Za-z_][A-Za-z0-9_]*(\[[^]]*\])?\+?=/) { k++; continue }
            if (v ~ /^(\/|~\/|\$HOME\/|\$\{HOME\}\/)/) { sub(/.*\//, "", v) }
            if (v in WRAPPER) {
                k++
                while (k <= n && (w[k] ~ /^-/ || w[k] ~ /^[0-9]+([.][0-9]+)?[smhd]?$/))
                    k += ((v ":" w[k]) in VALFLAG) ? 2 : 1
                continue
            }
            break
        }
        if (k > n) return
        w[k] = v
        out = "C"
        for (m = k; m <= n; m++) out = out US w[m]
        emit(out)
        cmd_verb[id] = v
        if (v in SHELL) {
            cflag = 0
            for (m = k + 1; m <= n; m++) {
                if (w[m] == "--") { m++; break }
                if (w[m] ~ /^--/) continue
                if (w[m] == "-o") { m++; continue }
                if (w[m] ~ /^-/) { if (w[m] ~ /c/) cflag = 1; continue }
                break
            }
            if (cflag && m <= n) {
                emit("O" US "sub"); lex(w[m], 1, "", sst); emit("X" US "sub")
            } else if (m > n && prev_pipe && prev_id) {
                # a bare shell fed by the command before the pipe: that
                # command`s literal words are its source
                hd_shell[prev_id] = 1
                for (j = 1; j <= prev_nargs[prev_id]; j++) {
                    emit("O" US "sub"); lex(prev_args[prev_id, j], 1, "", sst); emit("X" US "sub")
                }
            }
        } else if (v == "eval") {
            body = ""
            for (m = k + 1; m <= n; m++) body = body (m > k + 1 ? " " : "") w[m]
            if (body != "") lex(body, 1, "", sst)      # eval runs in this shell
        } else if (v == "find") {
            for (m = k + 1; m <= n; m++) {
                if (!(w[m] in FINDEXEC)) continue
                cnt = 0
                for (j = m + 1; j <= n && w[j] != ";" && w[j] != "+"; j++) sst[++cnt] = w[j]
                if (cnt) { emit("O" US "sub"); command(sst, cnt, ++ncmd); emit("X" US "sub") }
                m = j
            }
        }
        prev_id = id; prev_nargs[id] = n - k
        for (m = k + 1; m <= n; m++) prev_args[id, m - k] = w[m]
    }

    # --- heredocs -----------------------------------------------------------
    # Bodies are consumed at the newline that ends the line they opened on.
    # What each body IS depends on who reads it: shell source when the
    # consumer is a shell or pipes on to one; live where the delimiter is
    # unquoted, so a substitution in it runs; data otherwise.
    function heredocs(s, i, base,    k, L, line, j, body, d, sst) {
        L = length(s)
        for (k = base + 1; k <= nhd; k++) {
            body = ""
            while (i <= L) {
                j = index(substr(s, i), "\n")
                if (j == 0) { line = substr(s, i); i = L + 1 } else { line = substr(s, i, j - 1); i += j }
                d = line; if (hd_dash[k]) sub(/^\t+/, "", d)
                if (d == hd_delim[k]) break
                body = body line "\n"
            }
            if (cmd_verb[hd_cmd[k]] in SHELL || hd_shell[hd_cmd[k]]) {
                emit("O" US "sub"); lex(body, 1, "", sst); emit("X" US "sub")
            } else if (!hd_quoted[k]) {
                dq(body, 1, sst, "")
            }
        }
        nhd = base
        return i
    }

    # --- substitutions --------------------------------------------------------
    function subst(s, i, st,    j, sst) {     # at "$(": lex to ")", word keeps the text
        emit("O" US "sub"); j = lex(s, i + 2, ")", sst); emit("X" US "sub")
        app(st, substr(s, i, j - i), 0)
        return j
    }
    function procsub(s, i, st,    j, sst) {   # at "<(" or ">("
        emit("O" US "sub"); j = lex(s, i + 2, ")", sst); emit("X" US "sub")
        app(st, substr(s, i, j - i), 0)
        return j
    }
    function backtick(s, i, st,    j, L, c, body, sst) {
        L = length(s); j = i + 1; body = ""
        while (j <= L) {
            c = substr(s, j, 1)
            if (c == "\\" && substr(s, j + 1, 1) ~ /[\\`$]/) { body = body substr(s, j + 1, 1); j += 2; continue }
            if (c == BQ) break
            body = body c; j++
        }
        emit("O" US "sub"); lex(body, 1, "", sst); emit("X" US "sub")
        app(st, substr(s, i, j - i + 1), 0)
        return j + 1
    }
    function arith(s, i,    L, depth) {       # at the char after "((": index after "))"
        L = length(s); depth = 0
        while (i <= L) {
            if (substr(s, i, 1) == "(") depth++
            else if (substr(s, i, 1) == ")") {
                if (depth == 0 && substr(s, i + 1, 1) == ")") return i + 2
                if (depth > 0) depth--
            }
            i++
        }
        return i
    }
    # Double-quoted text, to the closing quote (or the end, for a heredoc
    # body): only `\`, `$(`, `$((` and a backtick are special.
    function dq(s, i, st, term,    L, c, n, j) {
        L = length(s)
        while (i <= L) {
            c = substr(s, i, 1)
            if (term != "" && c == term) return i + 1
            if (c == "\\") {
                n = substr(s, i + 1, 1)
                if (n == "\n") { i += 2; continue }
                if (n ~ /[$`"\\]/) { app(st, n, 1); i += 2; continue }
                app(st, c, 1); i++; continue
            }
            if (c == "$" && substr(s, i + 1, 2) == "((") { j = arith(s, i + 3); app(st, substr(s, i, j - i), 0); i = j; continue }
            if (c == "$" && substr(s, i + 1, 1) == "(") { i = subst(s, i, st); continue }
            if (c == BQ) { i = backtick(s, i, st); continue }
            app(st, c, 1); i++
        }
        return i
    }

    # --- the walk ---------------------------------------------------------------
    # Over s from i; stops after the terminator `term` (")" for a substitution
    # or subshell, "" for the end of the string). Returns the index after it.
    function lex(s, i, term, st,    L, c, n, j, base, sst) {
        L = length(s); base = nhd
        st["nw"] = 0; reset(st); st["redir"] = ""; st["mode"] = M_NONE; st["id"] = 0
        st["hdwait"] = 0; st["hddash"] = 0; st["casedepth"] = 0
        while (i <= L) {
            c = substr(s, i, 1)
            if (c == " " || c == "\t" || c == "\r") { endword(st); i++; continue }
            if (c == "\n") {
                endword(st); endcmd(st); i++
                if (nhd > base) i = heredocs(s, i, base)
                prev_pipe = 0
                continue
            }
            if (c == "\\") {
                n = substr(s, i + 1, 1)
                if (n == "\n") { i += 2; continue }        # a continuation joins
                if (n == "") { i++; continue }
                app(st, n, 1); i += 2; continue
            }
            if (c == SQ) {
                j = index(substr(s, i + 1), SQ)
                if (j == 0) { app(st, substr(s, i + 1), 1); i = L + 1 }
                else { app(st, substr(s, i + 1, j - 1), 1); i += j + 1 }
                continue
            }
            if (c == DQ) { app(st, "", 1); i = dq(s, i + 1, st, DQ); continue }
            if (c == "$") {
                n = substr(s, i + 1, 1)
                if (n == SQ || n == DQ) { i++; continue }         # a $-prefixed quote quotes as the plain one does
                if (substr(s, i + 1, 2) == "((") { j = arith(s, i + 3); app(st, substr(s, i, j - i), 0); i = j; continue }
                if (n == "(") { i = subst(s, i, st); continue }
                app(st, c, 0); i++; continue
            }
            if (c == BQ) { i = backtick(s, i, st); continue }
            if (st["mode"] == M_TEST) { app(st, c, 0); i++; continue }   # inside [[ ]] `>` compares
            if (c == "#" && !st["have"]) {
                j = index(substr(s, i), "\n"); i = (j ? i + j - 1 : L + 1); continue
            }
            if (c == ";") {
                endword(st); endcmd(st); prev_pipe = 0
                if (substr(s, i, 2) == ";;" || substr(s, i, 2) == ";&") {
                    if (st["casedepth"] > 0) st["mode"] = M_CASEPAT
                    i += (substr(s, i, 3) == ";;&" ? 3 : 2)
                } else i++
                continue
            }
            if (c == "&") {
                if (substr(s, i + 1, 1) == ">") {                 # &> and &>>
                    endword(st)
                    if (substr(s, i + 2, 1) == ">") { st["redir"] = "&>>"; i += 3 } else { st["redir"] = "&>"; i += 2 }
                    continue
                }
                endword(st); endcmd(st); prev_pipe = 0
                i += (substr(s, i + 1, 1) == "&" ? 2 : 1)
                continue
            }
            if (c == "|") {
                if (st["mode"] == M_CASEPAT) { endword(st); i++; continue }
                endword(st); endcmd(st)
                n = substr(s, i + 1, 1)
                if (n == "|") { prev_pipe = 0; i += 2 } else { prev_pipe = 1; i += (n == "&" ? 2 : 1) }
                continue
            }
            if (c == "<" || c == ">") {
                if (substr(s, i + 1, 1) == "(" && !st["have"]) { i = procsub(s, i, st); continue }
                # a leading fd number is part of the operator, not a word
                if (st["have"] && !st["wq"] && st["w"] ~ /^[0-9]+$/) reset(st); else endword(st)
                if (c == "<") {
                    if (substr(s, i, 3) == "<<<") { st["redir"] = "<<<"; i += 3; continue }
                    if (substr(s, i, 2) == "<<") {
                        st["hdwait"] = 1; st["hddash"] = (substr(s, i + 2, 1) == "-")
                        i += 2 + st["hddash"]; continue
                    }
                    if (substr(s, i, 2) == "<&") { st["redir"] = "<&"; i += 2; continue }
                    if (substr(s, i, 2) == "<>") { st["redir"] = "<>"; i += 2; continue }
                    st["redir"] = "<"; i++; continue
                }
                if (substr(s, i, 2) == ">>") { st["redir"] = ">>"; i += 2; continue }
                if (substr(s, i, 2) == ">|") { st["redir"] = ">|"; i += 2; continue }
                if (substr(s, i, 2) == ">&") { st["redir"] = ">&"; i += 2; continue }
                st["redir"] = ">"; i++; continue
            }
            if (c == "(") {
                if (st["mode"] == M_CASEPAT) { endword(st); i++; continue }
                if (st["have"]) {           # `f()` or `arr=( )`: the word is not a command
                    emit("O" US "sub"); i = lex(s, i + 1, ")", sst); emit("X" US "sub")
                    reset(st); if (st["mode"] == M_FUNC) st["mode"] = M_NONE
                    continue
                }
                if (substr(s, i + 1, 1) == "(" && st["nw"] == 0) { i = arith(s, i + 2); continue }
                endcmd(st)
                emit("O" US "sub"); i = lex(s, i + 1, ")", sst); emit("X" US "sub")
                continue
            }
            if (c == ")") {
                if (st["mode"] == M_CASEPAT) { endword(st); st["mode"] = M_NONE; i++; continue }
                endword(st); endcmd(st)
                if (term == ")") { if (nhd > base) heredocs(s, L + 1, base); return i + 1 }
                i++; continue                              # unmatched: a separator
            }
            app(st, c, 0); i++
        }
        endword(st); endcmd(st)
        if (nhd > base) heredocs(s, L + 1, base)
        return i
    }
    '
}

if [ "${1:-}" = "--lex" ]; then lex "$CMD"; exit 0; fi

# A `cd` out of the tree belongs to the shell that ran it. A subshell,
# substitution or runner body ends and the parent never moved; a `{ }` group
# and `eval` are the same shell, so theirs carries. Hence the depth of `sub`
# scopes standing open, and the depth the `cd` was seen at.
cd_outside=""; cd_scope=0; sub_depth=0
while IFS=$'\037' read -r -a rec; do
    [ "${#rec[@]}" -gt 0 ] || continue
    case "${rec[0]}" in
      O) [ "${rec[1]:-}" = sub ] && sub_depth=$((sub_depth + 1)); continue ;;
      X) if [ "${rec[1]:-}" = sub ]; then
             sub_depth=$((sub_depth - 1))
             [ -n "$cd_outside" ] && [ "$sub_depth" -lt "$cd_scope" ] && cd_outside=""
         fi
         continue ;;
      R) case "${rec[1]:-}" in
           '>'|'>>'|'>|'|'&>'|'&>>'|'<>') outside_write "${rec[2]:-}" "redirection" ;;
           '>&') case "${rec[2]:-}" in ''|-|[0-9]*) ;; *) outside_write "${rec[2]}" "redirection" ;; esac ;;
         esac
         continue ;;
      C) ;;
      *) continue ;;
    esac

    WORDS=("${rec[@]:1}")
    [ "${#WORDS[@]}" -gt 0 ] || continue
    verb="${WORDS[0]}"
    args=("${WORDS[@]:1}")
    bare=()
    for a in ${args[@]+"${args[@]}"}; do
        case "$a" in -*) ;; *) bare+=("$a") ;; esac
    done

    case "$verb" in
      sudo|doas|pkexec|su|run0)
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
        if [ -n "${bare[0]:-}" ] && ! inside "${bare[0]}"; then
            cd_outside="${bare[0]}"; cd_scope="$sub_depth"
        fi
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

      find)
        # `-delete` turns `find` into a write: every match under a starting
        # point outside the tree is one. The starting points are the
        # leading operands, past `find`'s own global options (`-H`, `-L`,
        # `-P`, `-D debugopts`, `-Olevel`, which precede paths in valid
        # `find` syntax and are not the expression) and ended by the first
        # word that opens the expression (`-name`, `-delete` itself, `(`,
        # `!`, …) — read from `args`, not `bare`, because `bare` has already
        # dropped every flag and with it the boundary that separates a
        # starting point from a primary's own argument (the `x` of `-name x`).
        has_delete=""
        for a in ${args[@]+"${args[@]}"}; do
            [ "$a" = "-delete" ] && has_delete=1
        done
        if [ -n "$has_delete" ]; then
            find_skip_next=""
            for a in ${args[@]+"${args[@]}"}; do
                if [ -n "$find_skip_next" ]; then find_skip_next=""; continue; fi
                case "$a" in
                  -H|-L|-P|-O0|-O1|-O2|-O3) continue ;;
                  -D) find_skip_next=1; continue ;;
                  -*) break ;;
                  *) outside_write "$a" "find -delete" ;;
                esac
            done
        fi
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
            refuse "this changes directory to $cd_outside and then writes (\`$verb\`)" \
"Everything after that \`cd\` lands outside this repo, whether or not the paths" \
"look relative." \
"" \
"Do instead:" \
"  · work on paths under $REPO" \
"  · scratch work that is not a deliverable — /tmp"
            ;;
        esac
    fi
done < <(lex "$CMD")

exit 0
