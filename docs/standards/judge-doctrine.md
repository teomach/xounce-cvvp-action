<!-- Source: teomach-skills method/references/judge-doctrine.md @ 172f26d —
     rendered at guard-set v16 by scripts/wire-repo.py; edit it at source and
     re-run `scripts/wire-repo.py update`, never edit this copy. -->

# The judge — lean core

The judge is `review`'s per-PR mode run unattended before a PR opens: one
headless, read-only session per check, each given the diff, its single check,
and the verdict contract. It buys **coverage** — every obligation provably
visited — not independence. The runner, its flags, and the measured operating
history are the cockpit's (teomach-cockpit); this page is what a check is and
what findings mean, and it is deliberately generic.

## Three layers

| Layer | Asks | Whose blind spot it covers |
|---|---|---|
| Judge | Was every obligation actually checked? | The author's — things quietly skipped |
| Cross-model | Is this right, judged from outside? | The model family's — its own tells (`review-independence.md`) |
| Human (the gate) | Should we ship it? | Everything about intent and taste |

The judge filters; it never approves. A clean judge report means the diff is
worth a human's time, nothing more.

## Checks are derived, not authored — and efficiency is a design constraint

- **Derived from what already binds the diff**: the profile's definition of
  done, the review axes, and repo-local extras — small per-domain check files
  in the repo (one file per check, each citing where its obligation lives).
  Per-domain checks are data; a check file that restates the rule it cites
  will drift from it. Point, don't copy.
- **Derived from the diff, never from the repo.** Each run derives only the
  checks the touched surface can move; a check that must return "this diff
  touches nothing I cover" was money spent on a politeness.
- **The mechanical layer runs first.** A check a script could decide is a
  check written in the wrong medium; a red exit ends the run before a token.
- **The cost is context.** Measured on the estate's runner
  (teomach-cockpit, which keeps the numbers), nearly all of a run's spend is
  pushing the same diff into N cold processes — so *fewer applicable checks
  per run* is worth more than fewer runs, and far more than the choice of
  model.
- **The gate must never derive nothing.** An empty check list is fail-open in
  the other shoe; where genuinely nothing derives, the runner refuses out loud
  and judges nothing, rather than passing by omission.

## The verdict contract

```
VERDICT: PASS — <one clause>
VERDICT: FAIL — <file:line evidence, one clause each>
VERDICT: NOT-CHECKABLE — <what deciding would need>
```

- **NOT-CHECKABLE is an honest verdict, not a soft pass**: a check that needs
  staging, CI, or a human lands in the PR body as the list of what nobody has
  checked yet.
- **A check that did not run is an error, not a verdict.** A session that
  crashed or never started has read nothing; scoring it like a judgement is
  how a judge fails open — precisely when the diff is big enough to need it.
  A run with an unexplained silence must exit non-zero and say which check is
  missing. The general rule: **a control that cannot run must be loud, because
  a control that fails silently is worse than one nobody installed.**

## What findings do

A FAIL blocks opening the PR — fix it, or, where the finding is wrong, open
anyway with the finding and your dissent both in the PR body. Findings are
unmediated: a judge whose FAIL the judged agent can quietly summarise away is
not a filter.

## The stopping rule

> Stop at the first run where the in-family checks pass — **or where the only
> FAILs left are ones you have written a dissent for in the PR body.**

The second clause is what makes the rule obeyable: a FAIL you believe wrong
already has a sanctioned route — record it with its evidence and open anyway —
where another run costs a full set of packets and may simply produce a
different finding. Verdicts rotate; a clean report is weak evidence in both
directions. The teeth are on the decision, not on a count.
