<!-- Source: teomach-skills method/references/judge-doctrine.md @ 0eab023 —
     rendered at guard-set v24 by scripts/wire-repo.py; edit it at source and
     re-run `scripts/wire-repo.py update`, never edit this copy. -->

# The judge — lean core

The judge is `review`'s per-PR mode run unattended before a PR opens: one
headless session per check, each given the diff, its single check, and the
verdict contract, and none permitted to change what it judges (§What a check may
touch). It buys **coverage** — every obligation provably
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

## What a check may touch

- **The reviewed source is read, never written** — the original tree under
  judgement and the Git metadata it shares with every other worktree: objects,
  refs, hooks and configuration.
- **Builds, generated files and test runs happen in a declared disposable
  copy or fixture**, against the repo's declared test services. What the
  declaration names is `environment-ladder.md`'s.
- **No delivery and no production.** A check commits, pushes, opens or updates
  no PR and deploys nothing; it reaches no production system or credential.
- **Outside its declared environment, a check is NOT-CHECKABLE** — naming
  what deciding would need — never a pass, and never a reason to reach further.

These are permissions, not a claim that anything prevents a breach: each
boundary is labelled at its actual strength (`environment-ladder.md` §The
kept hygiene), and the runner that applies them, and on which runtimes, is the
cockpit's. **The source baseline detects a change; it does not prevent one.**
A check records the reviewed tree's baseline before and after its run. A path
that changed is attributed to a lane only by per-change evidence — that
lane's commit or recorded edit of the path — or by a baseline taken while its
owner was serialized or isolated. Owner activity in the window does not by
itself explain a change: a path without such evidence is reported
unattributed, neither assigned to the check nor excused by the overlap.

## Declared state must be reached

Tracing each hunk to its obligation is necessary, not sufficient. A diff can
pass every per-hunk check while nothing it declares ever takes effect: a
config written that nothing reads, a service configured that never starts, a
gate whose condition no target meets. So a judge also asks whether the state
the diff declares is **reached** — holding where it is declared to hold — and
not only whether each hunk that touches it is correct. Three mechanism
classes carry the question:

- **Written state has a reader.** Anything written for something else to
  consume — a config file, an environment file, a variable, a fact — names its
  consumer, and that consumer exists in the tree. A file nothing reads
  enforces nothing.
- **Declared long-running state is shown running.** A daemon, sidecar,
  server or scheduled unit the diff adds or changes is read back running
  against what was declared, and the run fails when it is not. Asking a
  module to start it is the request, not the evidence.
- **A gate reaches where it is declared to hold.** A condition or flag that
  gates declared state is set on every target the repo's registers name as
  carrying it; a default that no named target overrides gates the state into
  nowhere.

The same reading tightens any "nothing silently dropped" check: an obligation
the diff claims is reached, not merely touched — a hunk that writes part of it
is part of it. The one alternative to reaching declared state is naming the
gap as deferred in the PR; doing neither is a finding. Where the tree cannot
show whether state is reached — the target's truths live off the tree — the
verdict is NOT-CHECKABLE naming what would show it, never a pass.

These are classes, not rules. A repo turns them into concrete checks in its
own `docs/checks/` pages — naming its registers, and what a readback is in
its tooling — citing this section rather than restating it.

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
