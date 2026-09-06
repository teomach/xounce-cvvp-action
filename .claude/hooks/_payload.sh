#!/usr/bin/env bash
# Shared by the shell guards: read the hook payload once, and get fields out of
# it without assuming which JSON reader a machine has.
#
# Sourced, never run. `jq` first because it is an order of magnitude cheaper
# than a Python start (5 ms against 33 ms on the reference box) and the Bash
# guard runs on every Bash call; `python3` second because a virgin machine is
# likelier to have it. With neither, the shell guards fail open in silence —
# which is exactly the state the SessionStart guard exists to announce, so it
# checks for a reader and says so.

payload_read() { PAYLOAD=$(cat); }

json_reader() {
    if command -v jq >/dev/null 2>&1; then echo jq
    elif command -v python3 >/dev/null 2>&1; then echo python3
    else echo ""; fi
}

# json_str <dotted.path> — the string at that path, or nothing.
json_str() {
    case "$(json_reader)" in
        jq)  printf '%s' "$PAYLOAD" |
                 jq -r --arg p "$1" 'getpath($p | split(".")) // empty' 2>/dev/null ;;
        python3) printf '%s' "$PAYLOAD" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for k in sys.argv[1].split("."):
    d = d.get(k) if isinstance(d, dict) else None
print(d if isinstance(d, str) else "")
' "$1" 2>/dev/null ;;
        *)   : ;;
    esac
}

# The repo the session is in. CLAUDE_PROJECT_DIR is what Claude Code sets for
# hooks and is the project root outright; the payload's `cwd` is the session's
# directory, which is the same thing in a worktree and a fair fallback.
repo_root() {
    local cwd="$1" top
    if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "$CLAUDE_PROJECT_DIR" ]; then
        printf '%s' "$CLAUDE_PROJECT_DIR"
        return
    fi
    top=$(git -C "${cwd:-$PWD}" rev-parse --show-toplevel 2>/dev/null)
    printf '%s' "${top:-${cwd:-$PWD}}"
}

# The routing declaration's one shape, shared by the lane-default guard pair
# (pre-edit-lane-default.sh asks for it, stop-lane-tally.sh is silenced by
# it) so the two floors cannot drift: LANE naming an issue, or
# STRAIGHT_THROUGH whose reason carries ROUTE_REASON_MIN characters — the
# FLIGHT_LANE_BY_AGENT hatch's threshold, for that hatch's reason: enough to
# stop a bare token becoming the shape everyone learns.
ROUTE_REASON_MIN=12
# The build-file count where closeout stops being credible — the pre-edit
# guard's refusal point, and the tally's bar for a declared route riding
# more files than one piece should.
LANE_THRESHOLD="${TEOMACH_LANE_THRESHOLD:-3}"

# The build surface, shared by the lane-default pair. The lane default is
# the cockpit's, whatever the repo is working on (ruled 2026-09-06): with no
# `build_paths:` in .teomach.yml the WHOLE TREE is the surface. The key
# NARROWS it to the declared prefixes, for a type that knows its low-noise
# signal (board-games: targets/, components/).
build_paths_read() {   # build_paths_read <repo> — sets BUILD_PATHS; empty = whole tree
    local line
    line=$(sed -n 's/^[[:space:]]*build_paths:[[:space:]]*\[\(.*\)\].*/\1/p' \
               "$1/.teomach.yml" 2>/dev/null | head -n1)
    BUILD_PATHS=()
    [ -n "$line" ] && IFS=',' read -ra BUILD_PATHS <<<"$line"
}
in_build_surface() {   # in_build_surface <relpath> — 0 when the path is surface
    [ "${#BUILD_PATHS[@]}" -eq 0 ] && return 0
    local p
    for p in "${BUILD_PATHS[@]}"; do
        p=$(printf '%s' "$p" | sed -e 's/^[[:space:]"'\'']*//' -e 's/[[:space:]"'\''\/]*$//')
        [ -n "$p" ] || continue
        case "$1" in "$p"/*) return 0 ;; esac
    done
    return 1
}
route_settled() {   # route_settled <route> — 0 when the declaration parses
    case "$1" in
        "LANE: #"[0-9]*) return 0 ;;
        "STRAIGHT_THROUGH: "*)
            local reason="${1#STRAIGHT_THROUGH: }"
            [ "${#reason}" -ge "$ROUTE_REASON_MIN" ] && return 0 ;;
    esac
    return 1
}
