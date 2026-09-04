#!/usr/bin/env bash
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
#   · `>` inside a quoted string reads as a redirection. Over-refusing an `echo`
#     is a nuisance; under-refusing a write is the failure worth having.
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
    local p="$1"
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
        for a in ${args[@]+"${args[@]}"}; do
            case "$a" in -i|-i*|--in-place*)
                for b in ${bare[@]+"${bare[@]}"}; do outside_write "$b" "sed -i"; done
                break ;;
            esac
        done
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
done < <(printf '%s\n' "$CMD" | awk '{ gsub(/&&|\|\||\||;/, "\n"); print }')

exit 0
