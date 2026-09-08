#!/usr/bin/env bash
# Source: teomach-skills harness/orient/session-start.sh —
# edit it there and re-run `scripts/wire-repo.py update`, never edit a copy.
# SessionStart hook: print the repo's orientation, and nothing else.
#
# stdout is what the session reads, so this relays the generator verbatim —
# the orientation when the repo is wired, the refusal naming the file at fault
# when it is not, and, ahead of either, what `--heal` repaired. Nothing else
# is printed on stdout, ever.
#
# `--heal` is why this hook may now write. Where the repo is otherwise wired
# and only the generated layer — `.claude/skills/`, `.claude/method`, both
# gitignored and so absent from every fresh clone — is missing, the generator
# runs `wire-repo.py update --links-only` first and reports what it changed
# (ruled at teomach-cockpit#226). The reasons it lives on this side of the two
# SessionStart hooks rather than in the wiring guard, and why it cannot dirty
# a tracked file, are `harness/orient/README.md` §The self-heal's, cited here
# and not restated.
#
# It exits 0 in both cases on purpose. A non-zero SessionStart hook risks the
# session never seeing the text, and the refusal is the one message that most
# needs to arrive. Blocking an unwired session is the wiring guard's job, not
# this one's. A real failure — no generator, no python3 — goes to stderr and
# still exits 0, because a broken orientation must not stop the human working.
set -uo pipefail

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Which repo this is is `_payload.sh`'s `repo_root`, not a second answer to the
# same question: without it the two SessionStart hooks can disagree about the
# tree they are in, and a rule written twice drifts. The helper sits beside
# this file once installed and one directory over in the clone.
# shellcheck source=../hooks/_payload.sh
for payload in "$here/_payload.sh" "$here/../hooks/_payload.sh"; do
	if [[ -f "$payload" ]]; then . "$payload"; break; fi
done
if ! declare -F repo_root >/dev/null; then
	echo "orient: _payload.sh is not beside this hook; no orientation generated." >&2
	exit 0
fi
# The payload's `cwd` is the second half of that same answer, and the guard
# beside this hook has always passed it. Passing nothing left the two to agree
# only through `CLAUDE_PROJECT_DIR`, which Claude Code sets and the codex
# bridge does not — so on that bridge this hook fell back to its own `$PWD`
# while the guard read the payload. That is now a tree this hook may WRITE in,
# which is what makes an agreement worth having rather than assuming.
#
# Read only when there is a payload to read: `payload_read` is a `cat`, and
# the wiring guard's own remedy tells a human to run this script from a
# terminal to see the orientation without restarting. A `-t 0` test is what
# keeps that instruction from hanging on stdin.
if [[ -t 0 ]]; then
	repo="$(repo_root "")"
else
	payload_read
	repo="$(repo_root "$(json_str cwd)")"
fi

if ! command -v python3 >/dev/null 2>&1; then
	echo "orient: python3 not on PATH; no orientation generated." >&2
	exit 0
fi

if [[ ! -f "$here/orient.py" ]]; then
	echo "orient: $here/orient.py is missing; no orientation generated." >&2
	exit 0
fi

python3 "$here/orient.py" --repo "$repo" --heal
exit 0
