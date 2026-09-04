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
