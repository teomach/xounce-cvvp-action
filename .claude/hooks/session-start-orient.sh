#!/usr/bin/env bash
# SessionStart hook: print the repo's orientation, and nothing else.
#
# stdout is what the session reads, so this relays the generator verbatim —
# the orientation when the repo is wired, the refusal naming the file at fault
# when it is not. Nothing else is printed on stdout, ever.
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
repo="$(repo_root "")"

if ! command -v python3 >/dev/null 2>&1; then
	echo "orient: python3 not on PATH; no orientation generated." >&2
	exit 0
fi

if [[ ! -f "$here/orient.py" ]]; then
	echo "orient: $here/orient.py is missing; no orientation generated." >&2
	exit 0
fi

python3 "$here/orient.py" --repo "$repo"
exit 0
