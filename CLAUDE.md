# xounce-cvvp-action — repo notes

<!-- Per-repo, and yours: what this repo is, and which skills conspicuously do
     NOT apply here and why. A profile says what applies; only the repo knows
     what does not. -->

<!-- teomach:wired — managed by scripts/wire-repo.py; edit outside this block -->
## The method, as this repo carries it

Wired for the Teòmach method — but **a fresh clone or a post-merge checkout is
unwired until rewired**: `.claude/skills/` is generated into this machine's
install and never committed, so it does not travel. Run
`scripts/wire-repo.py update --repo .` from a teomach-skills clone; the same
verb re-applies the current standard any other day, reporting what it changes.
Start a session without it and the SessionStart guard says so loudly and
prints that command with its paths resolved.

`.teomach.yml` records the type, tier and guard-set version; `.claude/skills/`
links the kernel and this type's packs into the machine's install;
`.claude/hooks/` holds the guards that `.claude/settings.json` dispatches. A
SessionStart hook prints the full orientation — what this repo is, which
skills matter here and when. Read it rather than reconstructing the method
from this file.

- **The gate** — `the-gate.md` (teomach-skills).
- **The judge derives from** `docs/checks/`.
- **Standing rules, cited not restated** — `history-in-git.md`,
  `environment-ladder.md`, `judge-doctrine.md` (teomach-skills).
<!-- /teomach:wired -->
