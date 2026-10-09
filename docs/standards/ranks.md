<!-- Source: teomach-skills method/references/ranks.md @ b1830fa —
     rendered at guard-set v25 by scripts/wire-repo.py; edit it at source and
     re-run `scripts/wire-repo.py update`, never edit this copy. -->

# Ranks — the Wing Commander at the controls, the Group Captain above

**A session asks one person for its decisions, and this page says who.** Two
ranks, and the precedence between them. Every other page names a rank and
cites this one; none restates it.

## At the controls

**The signed-in GitHub account is the test of rank.** Whoever operates the
cockpit a session runs in is *at the controls*, identified by the login
`gh api user --jq .login` returns. A login that cannot be read resolves
downward: the operator is a Wing Commander, and no path resolves an
unidentified operator upward.

## The two ranks

- **Wing Commander** — whoever is at the controls, and the default rank. A
  session that grills, asks for confirmation or seeks a merge decision asks
  the Wing Commander and records the decision as theirs.
- **Group Captain** — the person the repo's configuration names: the
  `group_captain` key of `.teomach.yml`, a GitHub login. When that person is
  at the controls, the session addresses them as the Group Captain and
  records their decisions as the Group Captain's.

**A repo that names no Group Captain has none.** Every operator there is a
Wing Commander, no Group Captain record is expected, and nothing on this page
about a clash applies.

## Precedence

**The Group Captain can overturn any Wing Commander's decision.** It needs no
machinery: the Group Captain decides on the artefact that carries the Wing
Commander's decision, and the newer decision stands.

**A Wing Commander cannot overturn a decision on the repo's Group Captain
record.** The route is a PR left for the Group Captain — §A clash.

## The Group Captain record

**`GROUP-CAPTAIN.md` at the repo root holds the Group Captain's decisions
that bind later changes** — each entry a stable ID (`GC-<n>`), the decision
as the position that holds, what it governs, and the artefact carrying it.
The record and the `group_captain` key change only through a PR the Group
Captain merges.

**Entries are explicit.** A decision goes on the record only when the Group
Captain asks for that; nothing is inferred from who was at the controls. With
the Group Captain at the controls, a session may offer to put a decision just
made on the record, and the Group Captain says yes or no. A session adds no
entry unasked, and makes the offer to nobody else.

## A clash

**A clash is a change that conflicts with an entry on the Group Captain
record, or that changes the record or the `group_captain` key.** Touching a
file an entry governs is not itself a clash; whether a change conflicts with
the decision as written is the judge's reading, not the session's own.

A Wing Commander's session may open a clashing PR. It applies the label
`group-captain` and names the entry IDs in the PR body, so the Group Captain
finds it. Its merge is `the-gate.md`'s.

## A recorded decision says whose it was

Where a skill records a decision — a Briefing, a decision on an issue, a
refusal noted on a lane — the record names the rank and the GitHub login
beside it: "the Wing Commander (`<login>`)" or "the Group Captain
(`<login>`)". It sits beside `memory-routing.md`'s claim clause.

## The Briefing

**What the operator tells a session in an interview, as recorded, is a Wing
Commander's Briefing** — `grill`'s output above all. It is a **Group
Captain's Briefing** when the Group Captain gave it, so a reader sees from
its name whose intent it carries.

## The jobs that keep their names

**Intent-holder** — the person a `grill` interviews — and **domain oracle** —
the person who knows what a system really does — are jobs a Wing Commander
holds, not ranks. A page that means the job names the job.
