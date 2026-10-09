# Did the documents this change affects move with it?

**Read the tree; never operate on it.** This check is a session whose working
directory is the worktree it judges, and the repository behind that worktree
is shared: other worktrees are open on it, and the stash list is one list for
all of them. So every git verb this check reaches for is a reading one —
`git log`, `git diff`, `git show`, `git status`, `git ls-files`,
`git stash list`. Never `git stash pop`, `git stash apply`, `git checkout`,
`git restore`, `git reset`, `git clean`, `git commit`, `git merge`,
`git rebase`: a write here can take up work parked by a lane this check is
not judging, and a file left conflicted can stop the lane's own hooks
parsing, which costs it every command it runs afterwards. Build, test and
lint commands are the point of the grant and stay welcome. Where deciding
would need the tree to be different, the verdict is NOT-CHECKABLE naming what
changing it would take; no mutation buys a verdict.

The kernel's living-documents check, judged beside universal in every wired
repo. The obligation is the `docs` skill's same-PR rule, and `implement`'s
definition of done carries it; this file enforces them and restates neither.
What a verdict means and what a finding does are
`docs/standards/judge-doctrine.md`.

**By effect, not by file type.** The check binds a diff whose effect changes
behaviour, structure, an interface, a procedure someone follows, or an agreed
requirement — whichever files carry it. A Markdown-only diff that changes how
a thing is reviewed, operated or played is inside it. A diff with none of
those effects — wording, links, formatting, a dated receipt or handoff, tests
of unchanged behaviour — owes only the block's `none` line.

**The surfaces, named generically.** A change can move seven, and the same
seven in any medium — a game's rulebook and a service's runbook are both
*operating guidance*:

1. specification and stories;
2. the agreed design;
3. the current implementation or operating view — how the thing is built or
   run today;
4. tests and examples;
5. risk and evidence status;
6. operating and support guidance — runbook, rulebook, player aid, help text;
7. older guidance the change contradicts.

**Which page carries each surface** is the repo's document-authority map
where one exists — the page `setup` seeds under `docs/architecture/`, saying
which document is current authority for a surface and which is dated
evidence. Where none exists, judge from the README and `docs/` as found, and
say so in the verdict: a missing map is a limit on the reading, not a
finding of this check.

Judge three things:

- **The PR names its documentation impact — every PR.** The body carries a
  block with one line per surface, `updated` with what changed and how it was
  verified, or `not affected` with the reason; or the single line
  `documentation impact: none — editorial only`. A PR with no block is a
  finding whatever its diff, and so is a surface left blank. A `none` line
  under a diff that has one of the effects above is a finding: quote the hunk
  and name the surface it moves.

- **Each disposition matches the diff and the item's own acceptance.** A hunk
  that changes an interface, a state, a trust boundary, a rule or a procedure
  with the matching document marked `not affected` is a finding; quote the
  hunk and name the document. Requirement text in a story or the
  specification changed without the gate's amendment is a finding; its
  evidence, status or trace links moving with the requirement unchanged is
  not. A changed diagram that was not rendered is a finding. A design
  question closed by its merged agreed design is correct; a release gate, or
  a risk whose acceptance needs operating or runtime evidence, marked closed
  because code merged is a finding.

- **Dated evidence keeps its stamps.** An as-is record, a receipt, a closed
  attempt, a handoff, and any page the authority map classes as evidence are
  not rewritten to agree with new code. The expected move for a still-current
  page the change would otherwise contradict is a redirect to the page that
  now governs; a factual correction to a dated page names the ruling that
  permitted it.

What this check is not: a demand to touch every document on every PR, a
periodic drift review (the `docs` skill's catch-up audit is that), or an
approval step. One PR, the documents its own change affects, with the reason
where it affects none.

Pass unless you can quote the hunk and name the document it leaves wrong, or
name the block that is absent.
