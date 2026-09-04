# Does this diff do what it claims, at the bar for its kind?

The check every repo starts with, and often the only one it needs.

**The standard is the PR's own stated intent.** What a verdict means, what a
finding does and why the judge filters rather than approves are in
`.claude/skills/setup/../references/judge-doctrine.md` — read it there, do not re-derive it here.

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
needs per `MODELS.md`, the cut — carried in a commit body on the branch.
Judge its presence, not its wisdom: no fit line anywhere in the branch's
messages means the session defaulted silently, and that is a finding;
choosing the tier was never the judge's to do.

Pass unless you can quote the line at fault.
