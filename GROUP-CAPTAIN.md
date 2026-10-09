# Group Captain record

The decisions the Group Captain has put on this repo's record. Each stands
against any later change until the Group Captain intervenes. The ranks, and
what a clash is, are defined in `method/references/ranks.md` in
teomach-skills — in this repo, `.claude/method/method/references/ranks.md`.

One entry per decision, in exactly this shape:

```markdown
## GC-<n> — <a few words>

- **Decision:** <the position that holds, in one or two sentences>
- **What it governs:** `<repo-relative path or glob>`, `<another>`
- **Where it was ruled:** <owner/repo#n>, the comment "<its heading>"
```

The ID is `GC-` and a number, never reused. A governed path or glob goes in
backticks — `**` crosses directories, `*` does not, and a directory covers
what is beneath it; a backticked name with no `/`, `.` or `*` is a named rule,
which no path matches. The record changes only through a PR the Group Captain
merges, and states the present: a struck entry is removed.

_No entries._
