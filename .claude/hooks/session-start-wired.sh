#!/usr/bin/env bash
# SessionStart — is this repo wired, and is its guard set the current one?
#
# WHY THIS EXISTS. A PreToolUse hook whose script is missing or not executable
# FAILS OPEN: the tool call proceeds and nothing is printed (measured against
# Claude Code 2.1.220, three separate canaries). So the silence of a guard is
# never evidence that it ran, and a repo can carry a settings.json full of
# hooks that enforce nothing. This one runs once, at the start, and tests for
# presence POSITIVELY — every guard named, opened and found executable, every
# guard declared in the settings that dispatch it, and the version they carry
# matched against the version the repo says it was wired with.
#
# It also announces itself on the way through. One line of context naming the
# guard-set version is what makes the whole set falsifiable: ask a session
# whether its guards are live and it answers from evidence rather than from the
# absence of complaint.
#
# WHY IT DOES NOT EXIT 2. SessionStart cannot block a session, and an exit 2
# there reaches the user's terminal but not the model. The refusal has to land
# in the model's context to change what the session does next, so the guard
# exits 0 and writes it to `hookSpecificOutput.additionalContext`, with a
# `systemMessage` for the human beside it.

set -uo pipefail
# shellcheck source=_payload.sh
. "$(dirname "${BASH_SOURCE[0]}")/_payload.sh"

HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARDS=(session-start-wired.sh pre-bash-no-pollution.sh pre-bash-stage-by-path.sh pre-bash-pr-gate.sh pre-agent-lane-dispatch.sh pre-edit-lane-default.sh post-write-narration.py stop-uncommitted.sh stop-lane-tally.sh)

payload_read
REPO="$(repo_root "$(json_str cwd)")"

problems=()
add() { problems+=("$1"); }

# --- wired at all, and at which version -------------------------------------
declared=""
if [ ! -f "$REPO/.teomach.yml" ]; then
    add "no .teomach.yml — this repo is not wired, but it is running the guards."
else
    declared=$(sed -n 's/^[[:space:]]*guard_set:[[:space:]]*\([^[:space:]#]*\).*/\1/p' \
                   "$REPO/.teomach.yml" | head -n1)
    [ -n "$declared" ] || add ".teomach.yml has no 'guard_set:' — nothing records which guards this repo expects."
fi

installed=""
if [ -f "$HOOKS_DIR/VERSION" ]; then
    installed=$(tr -d '[:space:]' <"$HOOKS_DIR/VERSION")
else
    add "no VERSION beside the guard scripts — the installed set cannot be identified."
fi

if [ -n "$declared" ] && [ -n "$installed" ] && [ "$declared" != "$installed" ]; then
    add "guard set is STALE: .teomach.yml says '$declared', the installed scripts are '$installed'."
fi

# --- every guard present, executable, and dispatched ------------------------
for g in "${GUARDS[@]}"; do
    if   [ ! -f "$HOOKS_DIR/$g" ]; then add "guard missing: .claude/hooks/$g (a missing hook fails open — it enforces nothing)."
    elif [ ! -x "$HOOKS_DIR/$g" ]; then add "guard not executable: .claude/hooks/$g (fails open exactly as a missing one does)."
    fi
done
[ -f "$HOOKS_DIR/_payload.sh" ] || add "shared helper missing: .claude/hooks/_payload.sh (the shell guards cannot read their payload without it)."

SETTINGS="$REPO/.claude/settings.json"
if [ ! -f "$SETTINGS" ]; then
    add "no .claude/settings.json — the guards are installed but nothing dispatches them."
else
    for g in "${GUARDS[@]}"; do
        grep -qF "$g" "$SETTINGS" || add "guard installed but never dispatched: $g is absent from .claude/settings.json."
    done
    for e in SessionStart PreToolUse PostToolUse Stop; do
        grep -qF "\"$e\"" "$SETTINGS" || add "no $e hook declared in .claude/settings.json."
    done
fi

# --- the rest of the resident set the guards depend on ----------------------
[ -f "$REPO/CLAUDE.md" ]              || add "no CLAUDE.md — the repo does not say what it is."
[ -f "$REPO/docs/checks/universal.md" ] || add "no docs/checks/universal.md — the gate would derive nothing to judge this repo by."

# --- the declared skills actually resolve on THIS machine -------------------
# The resident set declares packs and links them; it does not vendor them. So a
# machine without the skills clone gets dangling links, and the whole method is
# quietly absent. Say so, with the command that fixes it.
if [ ! -d "$REPO/.claude/skills" ]; then
    add "no .claude/skills/ — this session has the kernel and this repo's packs nowhere."
else
    dangling=()
    for e in "$REPO"/.claude/skills/*; do
        [ -e "$e" ] && continue          # -e follows the link: a dangling one is false
        [ -L "$e" ] || continue          # the glob itself not matching leaves the literal
        dangling+=("$(basename "$e")")
    done
    if [ "${#dangling[@]}" -gt 0 ]; then
        add "${#dangling[@]} skill link(s) point at nothing on this machine (${dangling[*]}) — run scripts/install-skills.sh from a teomach-skills clone."
    elif [ -z "$(ls -A "$REPO/.claude/skills" 2>/dev/null)" ]; then
        add ".claude/skills/ is empty — no kernel, no packs, no method."
    fi
fi

# --- can the shell guards read their own payload? ---------------------------
[ -n "$(json_reader)" ] || add "neither jq nor python3 is on PATH — the Bash and Stop guards will fail open silently."

# --- emit -------------------------------------------------------------------
# JSON assembled by hand so that a machine missing every optional tool still
# gets the refusal rather than a broken hook.
esc() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | awk '{printf "%s\\n", $0}'; }

if [ "${#problems[@]}" -eq 0 ]; then
    ctx="Teòmach guards v$installed are installed, dispatched and current in this repo: Bash calls are checked for global installs, writes outside the tree, and sweep staging (\`git add -A\`/\`git commit -a\` — stage by path), \`gh pr create\` for a judge report standing for this branch at HEAD, Agent calls for lane-shaped dispatches (lanes fly as \`wingman\` tabs), cockpit edits under the repo's declared build paths for a routing declaration (build work flies as a lane; straight-through is declared, not asked), markdown edits for decision narration, and the end of each turn for uncommitted work and untallied build-path changes."
    printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$(esc "$ctx")"
    exit 0
fi

# --- the single command that fixes it ---------------------------------------
# A fresh clone or a post-merge checkout is unwired BY DESIGN: .claude/skills/
# is generated into the machine's install and gitignored, so it never travels.
# The spec's answer (2026-08-06-repo-wiring.md §5) is that this guard prints
# the single command that rewires the repo — told, not silently degraded, and
# never self-healed: a guard only reads and refuses (§10). The machine's own
# install anchors the method clone: `setup` is the kernel skill every bundle
# links, and resolving it physically walks into the clone that carries the
# installer.
install_dir="${TEOMACH_SKILLS_DIR:-$HOME/.claude/skills}"
clone="$(cd -P "$install_dir/setup/../.." 2>/dev/null && pwd)"
if [ -n "$clone" ] && [ -f "$clone/scripts/wire-repo.py" ]; then
    remedy="  1. Tell the human what is listed above.
  2. Run the one command that rewires this repo:

       python3 \"$clone/scripts/wire-repo.py\" update --repo \"$REPO\"

     It re-links the skills a clone or a merge never carries (.claude/skills/
     is generated, never committed), reinstalls missing or stale guards, and
     reports everything it changed.
  3. Read this repo's orientation without restarting:
       \"$REPO/.claude/hooks/session-start-orient.sh\"
     The skill listing itself refreshes at the next session start."
else
    remedy="  1. Tell the human: this machine has no teomach-skills install to rewire
     from ($install_dir/setup does not resolve), so the method cannot
     bootstrap here.
  2. Get one: clone teomach-skills and run its scripts/install-skills.sh.
  3. Then run:

       python3 <teomach-skills clone>/scripts/wire-repo.py update --repo \"$REPO\""
fi

body="STOP — the Teòmach guards in this repo are broken. Do not treat this session as guarded.

"
for p in "${problems[@]}"; do body="$body  · $p
"; done
body="$body
What to do, before any other work:

$remedy

Until then the guards named above enforce nothing, and their silence is not
evidence that they ran. If problems remain after the fix, the next run of
this guard will say so."

printf '{"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' \
    "$(esc "Teòmach guards: ${#problems[@]} problem(s) — this repo is not properly wired.")" \
    "$(esc "$body")"
exit 0
