# Does this diff do what it claims, at the bar for its kind?

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

The check every repo starts with, and often the only one it needs.

**The standard is the PR's own stated intent.** What a verdict means, what a
finding does and why the judge filters rather than approves are in
`docs/standards/judge-doctrine.md` — read it there, do not re-derive it here.

Judge three things:

- **Claim against diff, both ways.** Every claim in the intent visible in the
  diff; every hunk in the diff covered by the intent.
- **Finished at the bar for its kind** — what this kind of change needs to be
  safe to merge, not what an ideal version would contain. Where the kind is
  executable — a script, a hook, an installer — that bar is five things: it
  fails loud rather than swallowing the error, it stays inside the tree it was
  pointed at, it installs nothing globally on the machine that runs it, a
  second run changes nothing the first did not, and it says what it skipped. A
  silent skip reads as success.
- **Would the next reader be misled?** Names that do not match what they name,
  comments describing behaviour that has gone, examples that would not run.

Where the repo is wired (`.teomach.yml` present), one more: **the fit line
travelled.** The orientation demands one line — the hardest act, the tier it
needs, the cut — carried in a commit body on the branch. The tier comes from
the model table, which a wired machine carries at
`~/.local/share/teomach/models.md` and no repo vendors, so the line names the
version that page states at its head: a judgement that cannot say which table
it read is one nobody can re-run. Judge its presence, not its wisdom: no fit
line anywhere in the branch's messages means the session defaulted silently,
and that is a finding; choosing the tier was never the judge's to do. A line
saying the page is not on this machine has answered the demand — that is the
honest reading, not a finding.

Where the repo also names a Group Captain — a `group_captain` key in
`.teomach.yml` — one more: **the Group Captain record holds.** The record is
the file at the repo root that `docs/standards/ranks.md` names, one entry
per decision, each with an ID and the paths it governs. For each entry whose
governed paths the diff touches, does the diff conflict with the decision as
written? A conflict is a finding naming the entry's ID and quoting the
decision beside the line that contradicts it. Touching a governed path
without contradicting the decision is not a finding. A diff that changes the
record or the `group_captain` key is a clash by definition: a finding naming
which, whatever the change says. A clash does not stop the PR opening; it
holds the merge for the Group Captain, so the finding also says whether the
PR body names the entry IDs and asks for the `group-captain` label. A repo
with no key has no record to hold, and this item does not apply.

Pass unless you can quote the line at fault.
