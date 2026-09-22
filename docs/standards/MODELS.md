<!-- Source: teomach-skills MODELS.md @ 9e780ff —
     rendered at guard-set v18 by scripts/wire-repo.py; edit it at source and
     re-run `scripts/wire-repo.py update`, never edit this copy. -->

# Models — which tier runs which skill

Recommendations, not enforcement: the tier named here is the one a session
**running that skill** should reach for, judged by the hardest thing the skill
routinely does. Re-derive when a pack changes shape; a table like this rots
exactly the way `pack-shapes.md`'s counts do.

## The tiers, and what each is for

**A tier names a level of expertise, never a vendor** — the ruling (#423).
Which family serves a tier is the flight leader's call at dispatch, taken
inside the ruled table below (teomach/teomach-skills#476): the tier is set by
the work, the default family by the table's row for the job, and the backup
column by the subscription stance recorded under §The ruled table.

| Tier | Reach for it when | Default family | Default and backup, per job |
|---|---|---|---|
| **Sonnet** | The skill is templated and well-guarded — scaffolding, filing, structured recording. The skill carries the judgement so the model doesn't have to. | Claude Sonnet | §The ruled table, *Templated work* and *Coverage judge* |
| **Opus** | Real drafting and build work — most orchestrators that write artefacts a human will read or merge. The estate default. | Claude Opus | §The ruled table, *Mainstream building* |
| **Fable** | A subtle miss is expensive — flight leading, repo-level audit work, forensic diagnosis, doctrine authoring, threat models, seam/architecture judgement, anything that reruns in every future session if wrong. | Claude Fable | §The ruled table, *Flight or squadron leader*, *Complex building* and *Whole-repo audit* |

*Flight leading* is the leader's own dispatch judgement, not a skill
session: a session running the `lead-flight` skill takes that skill's row
in the recommendations below; the leader seat itself is the ruled table's
first row.

**A name in a cell resolves to an id in the family tables below** — codex
(ruling #404), Gemini (ruling #406), TensorX (ruling #418): the ruled table
says who flies a job, the family tables say what to type on the dispatch
line. **Gemini has no Fable rung** — its family table records the ruling
(#406) — and the ruled table asks none of it: Gemini's rows are the
independence reviewer, templated work, and the backup behind the critics.

## The ruled table — job, default, backup

**The human ruled the whole table, recorded as the comment "Ruling — the
model table, settled" on teomach/teomach-skills#476; that comment is the
artefact and this page records it, cell for cell.** It supersedes the runner
defaults in #418, #424 and #445 where they differ. Nothing in the table is
measured further on purpose.

| Job | Default | Backup |
|---|---|---|
| Flight or squadron leader | Claude Fable at `high` | GPT Astra at `high` — needs a runtime flag on `flight`/`squadron` that the cockpit does not have; asked for as teomach-cockpit#324 |
| Mainstream building | Claude Opus at `high` | Astra at `medium`; Kimi K3 at `max` on the `claude` runtime, situational on cost |
| Complex building — doctrine, audits, forensics | Fable at `high` | Astra at `high` |
| Templated work | Claude Sonnet at `high` | Terra at `high`; Gemini 3.8 Flash at `high` on opencode — use the free credits |
| Coverage judge (in-family checklist) | Sonnet at `medium` | Terra at `medium`, then Kimi K3 at `low` |
| Independence reviewer (cross-family packet) | Gemini 3.8 Flash at `high` | Kimi K3 at `low` on opencode |
| Formation critics | Astra at `high` + Kimi K3 at `max` on the `claude` runtime as third voice (#476) | Gemini 3.8 Flash at `high` |
| Whole-repo audit / review (the seven cross-family disciplines) | Astra at `high`, Kimi K3 at `max` on the `claude` runtime (#476) | Gemini 3.8 Flash at `high` |
| **Deprecated from every row** | GLM 5.3, GLM 5.3 Flash, Gemini 3.1 Pro | — |

**The reasons, one line each, as the ruling gives them (#476):** Kimi at
`low` is the only effort that finishes a judge packet (teomach-cockpit#283)
and `max` is where its build reasoning pays; Gemini 3.8 Flash's effort lever
is measured to separate and it rides free credits, and its first PRs as the
reviewer are its measurement; Sonnet answered on the large-diff round the
metered coverage pin lost five times (#472); GLM's fail-loudly argument
(#424) has not met its day on Max 20 and its timeouts have; the board
(DeepSWE, transcribed on #472) governs the builder rows only.

**A deprecated rung stays named in its family table so it is not re-picked**:
the id, its rates and what was measured on it are kept as the record, and the
row says it holds no job.

**Where each subscription and the metered line stand** — the ruling's body
(#476), which that issue records as the artefact:

- **Claude Max 20 is the main driver.** Lanes, leaders and everything with
  volume fly on it by default. A lane leaves it only when the human wants
  another family on the task, or the allowance is exhausted (#476).
- **The ChatGPT plan is the formation partner** — the second family in a
  formation, the cross-family voice for whole-repo reviews and audits (the
  kernel's independence rule for audit mode), and Astra/Sol lanes flown
  deliberately to use the weekly allowance, especially where its reset falls
  elsewhere in the week than Claude's. Plus versus Max 5 is decided by
  measurement: fly one formation on Plus and read the meter. Not measured
  yet; the answer is not established.
- **TensorX is confined to the judge's two layers** — Sonnet holds coverage,
  so TensorX's seat there is Kimi K3 at `low` as the third fallback, and
  Kimi K3 at `low` on opencode is the independence backup — at 15–30 cents a
  PR, and to **Kimi K3 as a situational third voice** in a formation beside
  Fable and Astra, dispatched as a critic on the `claude` runtime (#476) —
  §The TensorX family below carries the reason. The Mainstream-building
  row's backup names Kimi K3 at `max` on the same runtime, situational on
  cost: read it with §The TensorX family's per-lane figure in hand, as the
  leader's deliberate exception and not a default.

**Constraints ride beside the tier, never inside it.** A constraint narrows
which family may serve a tier; it is not a level of expertise, so it is
written next to the tier in one shape — the Tier cell reads **Fable**,
cross-family — and never as a row of the tier table. The three the ruling
(#423) names:

- **cross-family** — the run must come from a different model family than
  the one that built the work, because a model auditing its own family's
  output is blind to its own tells. The seven audit disciplines in the
  recommendations below carry it, at the Fable tier; the ruled table's
  Whole-repo audit row names who flies them — Astra at `high` and Kimi K3 at
  `max`, Gemini 3.8 Flash at `high` behind them.
- **ablated** — work a hosted model refuses or waters down runs on ablated
  Qwen (local, Lemonade) — a Sonnet-tier model reached by constraint, not a
  rung. No skill wants it as the primary today; it appears as an adjunct
  (attacker-path enumeration in `threat-model`).
- **supreme privacy** — material we do not trust Anthropic, OpenAI, Google
  or TensorX with runs on ablated Qwen too: ablated work and supreme privacy
  are the two jobs it is the only trusted model for. No recommendation row
  carries it; it is claimed at dispatch, when the material warrants it.

**The ids the tiers mean, and the reason to write them out.** Sonnet is
`claude-sonnet-5`, Opus is `claude-opus-5`, Fable is `claude-fable-5-1`; the
independence reviewer is `google/gemini-3.8-flash` on opencode at `--variant
high`, with `tensorx/moonshotai/kimi-k3` at `low` on opencode behind it
(#476). **Always the full id, never the short alias** — probed on this box
against Claude Code 2.1.212, `sonnet` resolves to `claude-sonnet-5` but
**`opus` resolves to `claude-opus-4-8`**, one generation back, silently and
with no warning. An alias is a promise the CLI keeps on its own schedule; a
pinned id is the one we chose.

## The judge's two layers

**Coverage — `judge-doctrine.md`'s in-family checks — runs on Claude Sonnet at
`medium`, one judge model for every lane rather than the delivering family's
rung looked up per lane** (#476); behind it `gpt-5.6-terra` at `medium` on
codex, then Kimi K3 at `low` on opencode. Following a checklist against a
diff is the one job where tier buys least — that page's own ranking, *"fewer
applicable checks per run is worth more than fewer runs, and far more than
the choice of model"* — and Sonnet answered on the large-diff round the
metered pin lost five times (#472). On a subscription row the journal's
`coverage_usd` is `claude -p`'s own `total_cost_usd`, Anthropic's card
applied to the tokens rather than money that left an account: the column is
recorded, and nothing bills it. **Wiring it is teomach-cockpit's**
(teomach-cockpit#325); this page pins the model and stops there.

**Independence — the cross-family packet — runs on Gemini 3.8 Flash at
`high`, on opencode:** `opencode run --model google/gemini-3.8-flash
--variant high`, effort a separate `--variant` flag on that runner rather
than part of the id, and measured to separate on this rung (§The Gemini
family). Behind it, **Kimi K3 at `low` on opencode**, id
`tensorx/moonshotai/kimi-k3`, the `low` riding the provider config — the only
route that lands it (teomach-cockpit#283). The `claude` runtime against
TensorX's Anthropic-compatible endpoint takes the same model as bare
`moonshotai/kimi-k3` and does not read the effort field (teomach-cockpit#288),
so the model runs at its default maximum and a judge-sized packet does not
finish: the journal's 29 rows on that runner, all of 2026-09-18, read 17
NO-ANSWER, 5 PASS, 5 FAIL, 2 NOT-CHECKABLE — the reason Kimi's seat is
opencode's. Two routes are outside the ruled order: **`agy`**, whose only
spellings are `gemini-3.1-pro-low` and `-high` — Antigravity ids, model and
effort fused, reaching only the deprecated pro rung and no other runtime, so
`FLIGHT_CROSS_RUNNER=agy` sends a rung the table names in no row; and
**codex**, whose 22 rows on `gpt-5.6-sol` by 2026-09-21 read 13 FAIL, 7
NOT-CHECKABLE, 2 ERROR and no PASS — counts, not a judgement of the findings.
The base URL, the credential and how a dispatch chooses between the runners
are teomach-cockpit's wiring; this page pins the id and its spelling per
runner.

**The journal is the instrument, and it measures the reviewer and the coverage
model, never the lane's builder.** `~/.local/state/teomach/flight-journal.tsv`
names `cross_runner` and `cross_model` on every row, `coverage_runner` and
`coverage_model` beside `coverage_usd` since 2026-08-30 (codex's rows carry an
empty cost column, because an OAuth session prints none), and a
`cross_verdict` column so the dissent rate is a `cut` away. It carries no
column for the model that built the diff, for effort, or for token counts.
**Read those columns and not a lane's judge report**, whose running total is a
different quantity — both layers, and only since the lane's first commit — so
the two never reconcile and were never meant to.

**What the journal holds on the pins, read 2026-09-21T15:13Z, and the counts
are counts — it records verdicts, not whether a finding was right.** Gemini
3.8 Flash as the reviewer: **23 rows**, all from the guard set v16 roll of
2026-09-21, 21 PASS and 2 NOT-CHECKABLE, median independence cost **$0.11**,
range $0.05–$0.29, coverage on Sonnet beside it at $0.67–$4.63 list rate — one
flight, one day, one shape of diff, so a population and not yet a reading.
The deprecated and backup rungs' figures, kept so they are not mistaken for
the pin's: the Gemini pro rung over its 777 opencode rows, 398 PASS, 237 FAIL,
129 NOT-CHECKABLE, 12 NO-ANSWER, 1 ERROR, median $0.13; Kimi K3 on opencode
at `low` (teomach-cockpit#283; the journal carries no effort column, so
the assignment is that issue's merge time, 2026-09-18T22:30Z), 62 rows to
2026-09-21T10:52Z, 35 PASS, 18 FAIL, 8
NOT-CHECKABLE, 1 ERROR, median $0.09, range $0.05–$0.60; coverage on GLM 5.3
Flash, 102 rows, median $0.063; coverage on Sonnet before the metered pin, 901
rows, median $1.82. **Whether any rung's findings were accepted is a
disposition the journal does not hold, and comparative review quality is not
established by it.**

**A reviewer that never dissents is as useless as one that never answers, and
`cross_verdict` separates them.** Every judge report names the independence
layer's own outcome on its own line, and the journal carries it, so the
reading on the pin cuts both ways: several consecutive runs with no dissent is
the signal to look, and a run of findings nobody accepts is the same signal
wearing the other shirt. The number to beat is the deprecated pro rung's: on
the flight of 2026-08-02/03 that reviewer raised findings accepted on two PRs
and one that a third PR rebutted with evidence. The reviewer must not share a
family with the coverage layer — a reviewer on the coverage model asks that
model whether it was right, the one thing this layer exists not to do — and
the ruled order keeps them apart: Claude on coverage, Gemini then TensorX on
independence.

## The Gemini family — the same ladder on opencode

The tier a piece of work needs does not move with the runner; the id it
resolves to does. Gemini's flash rung is the judge's independence reviewer
and the backup behind templated work and the critics (#476); opencode is the
runtime that carries it in every job, so this mapping exists to be pinned
against. The ids and rates below were read on **2026-09-09** from opencode
1.18.20's own model registry (`~/.cache/opencode/models.json`, refetched
that morning); what each row claims about entitlement comes from probes
against this box's credential the same day.

| Tier | opencode id | Basis |
|---|---|---|
| **Fable** | *(no rung ruled)* | The ruling (#406) maps two rungs and no third, and the registry lists nothing above `gemini-3.1-pro-preview` in the pro line — every newer google entry on 2026-09-09 is flash, image, speech or embedding. |
| **Opus** | `google/gemini-3.1-pro-preview` — **deprecated from every row (#476)** | Ruling (#406) mapped it as the near-peer of Opus and of codex's `sol`; the ruling (#476) gives it no job. Kept as the record: served by this credential on 777 journalled judge runs from 2026-08-17; $2/M input, $12/M output, $0.20/M cached, doubling to $4/$18/$0.40 above 200k of context; 12% ±1 pass@1 as a lane runner on the DeepSWE board (#472). |
| **Sonnet** | `google/gemini-3.8-flash` | Ruling (#406): the near-peer of Sonnet and of codex's `terra`. Ruling (#476): the independence reviewer at `high`; templated-work backup at `high`; the backup critic and audit voice at `high`. Served by this credential — probed 2026-09-09, answered and billed. $0.75/M input, $3.75/M output, $0.075/M cached, no context tiering; the free credits are the reason it holds the reviewer seat. |
| *(no rung)* | `google/gemini-3.1-flash-lite` | Judgement: $0.25/$1.50, below the flash rung, and this ladder has nothing under Sonnet. Named so it is not mistaken for the bottom of three. |
| *(no rung)* | `google/gemini-3.7-flash`, `google/gemini-3.6-flash`, `google/gemini-3.5-flash` | Earlier flash generations. 3.7 and 3.6 price identically to the pinned rung and 3.5 at twice it, so a rung routed here would buy nothing. |
| *(no rung)* | `google/gemini-flash-latest` | An alias, not a pin: its own registry entry is stamped `release_date: 2026-08-13` where `gemini-3.8-flash` is stamped 2026-09-02, so what it resolves to is **not established** — the reason the Anthropic ids above are written out too. |

**The mapping is the human's role ruling (#406), not a benchmark claim.**
Nothing has ranked a Gemini rung against its Claude or codex near-peer on real
material: the reviewer's dissent rate measures the layer rather than the
model, and no Gemini lane has flown here. What the ladder settles is which id
a piece of work of a given weight reaches for when Gemini is the runner; the
ruling (#476) settles which jobs that is, and closes the measurement.

**The catalogue is not an entitlement, and only a run separates them.**
`opencode models` prints every provider's list rather than what this credential
is served: seventeen of its providers carried a `gemini-3.8` id on 2026-09-09.
What settles a rung is a run — `opencode run --format json --model <id>`
coming back with a text part and a `cost` field — and both rungs answered that
way. The flash probe checks the rates as well as the entitlement: 11,719
input, 3 output and 39 reasoning tokens came back billed at **$0.00894675**,
exactly the registry's $0.75 and $3.75 per million applied to those counts
with reasoning billed as output.

**Effort rides the dispatch line as `--variant`, and on the flash rung it
lands.** The registry declares `effort` values `low, medium, high` for both
rungs. On the **flash rung** the setting separates: one prompt run seven times
on 2026-09-09 returned **0 reasoning tokens at `low` on all three runs**, 24 at
`medium`, and 39, 76 and 105 at `high` — the measurement behind the ruling's
"effort lever measured to separate" (#476). On the deprecated **pro rung** the
same probe did not separate — `low` returned 67 and 118 reasoning tokens
against `high`'s 79 and 126. **An unrecognised value is accepted in silence**:
`--variant nonsuch` on the flash rung exited 0, answered, and spent 129
reasoning tokens, so a typo buys an effort nobody chose rather than an error.

## The codex family — the same ladder, a different runtime

The tier a piece of work needs does not move with the runner; the id it
resolves to does. `codex exec` flies from the cockpit as a lane runner, a
critic and the backup leader, and an invocation carrying no `-m` takes a
default nobody here chose — so this mapping exists to be pinned against. The
probe behind it is `docs/codex.md` (teomach-cockpit), against a ChatGPT
**Plus** credential; this page carries the mapping and cites rather than
restates the probe. The registry facts the mapping turns on were re-read on
**2026-09-09** — codex-cli 0.153.4, the same Plus credential, from a cache
stamped `fetched_at: 2026-09-08T23:19:03Z`.

| Tier | codex id | Basis |
|---|---|---|
| **Fable** | `gpt-6-astra` | Ruling (#404): detailed planning, where the highest quality matters — the registry's own priority-1 entry, "Our most capable model for complex, demanding work". Ruling (#476): the backup leader at `high` (runtime flag asked, teomach-cockpit#324); complex-building backup at `high`; mainstream-building backup at `medium`; the first formation critic and the whole-repo audit voice at `high`. Nothing has ranked it against `sol` on real material. |
| **Opus** | `gpt-5.6-sol` | Ruling (#404): the near-peer of Opus, the registry's "Reliable agentic workhorse for everyday tasks", at priority 6. **No ruled row names it** (#476): on the ChatGPT plan every Opus-shaped job takes `astra` at `medium`, and `sol` stands as the rung a metered codex credential would reach for by tier. |
| **Sonnet** | `gpt-5.6-terra` | Ruling (#404): well-defined, well-scoped, less complex or risky work — the registry's "Balanced agentic coding model for everyday work", at priority 7. Ruling (#476): templated-work backup at `high`; coverage-judge backup at `medium`. |
| *(no rung)* | `gpt-5.6-luna` | Judgement: cheaper and faster than `terra`, and this ladder has nothing under Sonnet, so nothing routes to it. Named so it is not mistaken for the middle of three. |
| *(no rung)* | `gpt-5.5` | The previous generation, under everything already pinned. Named so every listed slug is accounted for. |

**The mapping is the human's role ruling (#404), not a re-measurement.** There
is no price to compare: the credential is an OAuth ChatGPT session rather than
an API key, so a run prints no cost field at all and the flight journal's
`independence_usd` is empty on every codex row. Nothing has ranked these
against each other on real material — the probe was synthetic throughout. The
registry's own descriptions support the ruling rather than settle it: read
from `~/.codex/models_cache.json` and quoted as at 2026-09-09, `gpt-6-astra`
is "Our most capable model for complex, demanding work", `gpt-5.6-sol` a
"Reliable agentic workhorse for everyday tasks", `gpt-5.6-terra` a "Balanced
agentic coding model for everyday work", `gpt-5.6-luna` a "Fast and affordable
agentic coding model", and `gpt-5.5` a "Proven previous-generation model for
coding and general work". The registry's `priority` field orders them the
same way — `astra` 1, `sol` 6, `terra` 7, `luna` 8, `gpt-5.5` 12. Default
effort is the one signal that does *not* separate them: `astra` and `sol`
both ship `low`, `terra` and `luna` both `medium`. The ruling maps codex's
roles onto the tiers, not particular version strings.

**`gpt-6-astra` answers this credential and has flown a lane to a merged PR**
(teomach-cockpit's `docs/codex.md`); the ruling (#404) enters it on the
strength of that and the registry's priority-1 ranking. The forensic skills
that want the Fable rung — `diagnose`, `reverse-engineer`, `threat-model`,
`new-pack` — fly codex on the tier they ask for; nothing has run forensic
material through `astra` yet, so that it holds the tier on real material is
not established.

**Dispatch spells the choice `-m <id>`** on `codex exec`'s own command line, so
a cockpit extending its `-m` flag to codex lanes has ids to cite from here.
**Unpinned, a lane takes whichever default answers first** — the box's
`config.toml` model where it names one, the client's own default where it does
not — and both are live: a clean `CODEX_HOME` records `gpt-6-astra`, while this
box's `config.toml` opens with `model = "gpt-5.6-terra"` and an unpinned
dispatch here takes that. The trap is not the Anthropic aliases' quiet downgrade
but a loud refusal that says nothing useful: **an unentitled id and a misspelt
one come back in the same sentence**, differing only in the quoted name, so a
pin that rots reads exactly like a typo. The check is a registry read before
dispatch — `docs/codex.md` (teomach-cockpit) carries the command, and the
caveat that the cache is only as fresh as the last `codex` run, so read
`.fetched_at` alongside it. The registry is fetched per account: it answers for
this credential, not for the family. Of the seven entries it served on
2026-09-09, two are not tier candidates — `gpt-reserve` and `codex-auto-review`
are marked `hide`. None carried a retirement notice: a notice is an `upgrade`
block, and every entry's was null.

**Effort is a second setting, spelled `-c model_reasoning_effort=<v>`, and it
lands.** A run carrying it records `reasoning_effort` in codex's own thread
store where a run without it records nothing, and an unrecognised value is
refused outright with the server naming its enum — the opposite of opencode's
`--variant`, which accepts nonsense in silence. **What the setting does above
`high` is not established.** `low` and `high` separate cleanly on
reasoning-token count; `high` and `xhigh` do not; and `ultra` is advertised
by the client, absent from the server's enum, and accepted without complaint
by something that maps it before dispatch. The ruled efforts (`high` for the
leader, complex building, critics and audit; `medium` for mainstream
building) sit inside the range that separates; the top of the ladder stays
unknown here, and what it spends is measured externally — on the DeepSWE
board astra's `max` row carries 61k output tokens to `high`'s 27k for the
same pass rate (§Effort per carrier).

**The subscription's economics are not established, and that is why no codex
cell can be defended on price.** Quota is the only axis, it is reported at
one-percentage-point resolution and only into the on-disk transcript, and what
exhaustion looks like was never measured; the cost arithmetic this page does
for the metered families cannot be repeated for codex. The allowance one
token draws is the open item in `IMPROVEMENTS.md`, "The allowance one token
draws is unmeasured on both subscriptions"; the ruling's "fly one formation on
Plus and read the meter" (#476) is the same measurement from the other end.

## The TensorX family — the same ladder, pinned on two runtimes

The tier a piece of work needs does not move with the runner; the id it
resolves to does. TensorX is a hosted provider of open-weights models, and it
serves them behind two endpoints at once — an OpenAI-compatible
`https://api.tensorx.ai/v1`, which is what opencode's `tensorx` provider
speaks, and an Anthropic-compatible `https://api.tensorx.ai`, which the
`claude` runtime speaks. The ids below are written bare, as the `claude`
runtime takes them; opencode takes the same id behind a `tensorx/` prefix.
**The ruling (#476) confines TensorX to the judge's two layers and to Kimi K3
as a situational third voice; the judge seat is opencode's** — the runtime
where the provider config's effort holds. The critic seat rides the `claude`
runtime instead, where the effort field is not read (teomach-cockpit#288) and
the model reasons at maximum with no lever (cockpit B75) — a critic's value
is its full reasoning, so the missing lever costs nothing there (the ruling
"Kimi K3 as a critic rides Claude Code" on teomach/teomach-skills#476). The
mapping and the rates are the ruling's own (#418,
measured 2026-09-18); the registry facts below were re-read on **2026-09-18**
from opencode 1.18.30's cache (`~/.cache/opencode/models.json`), and the two
GLM rows' rates come from **tensorx.ai/models as at 2026-09-18**, which is
where they are published.

| Tier | TensorX id | Basis |
|---|---|---|
| **Fable** | `moonshotai/kimi-k3` | Ruling (#418): the forensic rung. Ruling (#476): the independence backup at `low` on opencode; the coverage judge's third fallback at `low`; a mainstream-building backup at `max` on the `claude` runtime, situational on cost; the third-family formation critic and whole-repo audit voice at `max`, also on the `claude` runtime. Carried by the registry — $3.00/M input, $15.00/M output, $0.75/M cached, 1,048,576 of context and 131,072 of output, reasoning and tool calls both declared. |
| **Opus** | `z-ai/glm-5.3` — **deprecated from every row (#476)** | Ruling (#418) mapped it as the near-peer of the estate's Opus default and of codex's `sol`; the ruling (#476) gives it no job. Kept as the record: $1.75/M input, $4.50/M output, $0.44/M cached, 1M context — tensorx.ai/models as at 2026-09-18. Absent from opencode's `tensorx` block, which tops out at `z-ai/glm-5.2`. |
| **Sonnet** | `z-ai/glm-5.3-flash` — **deprecated from every row (#476)** | Ruling (#418) mapped it as the near-peer of Sonnet and of codex's `terra`, and #424 pinned it as the coverage judge; the ruling (#476) gives it no job, for the reason §The ruled table records. Kept as the record: $0.20/M input, $0.50/M output, $0.05/M cached, 1M context — tensorx.ai/models as at 2026-09-18; 102 coverage rows at a median $0.063; one lane over $15. Absent from the same block. |
| *(no rung)* | `z-ai/glm-5.2`, `moonshotai/kimi-k2.6`, and the other 23 | The generations under the pins, and this provider's other vendors — Qwen, DeepSeek, MiniMax, Nemotron, `openai/gpt-oss-120b`. Twenty-six ids in the provider on 2026-09-18; named so the pinned rung is not mistaken for the whole catalogue. |

**A TensorX rate is cheap per judge run and dear per lane, and the per-lane
figure is the one to read beside the rate card.** The measurement is the
ruling's body (#476): TensorX billed about **$70** between 2026-09-18 and
2026-09-21; the cockpit's own records account for roughly $50 of it at
published rates, and the judge's two layers were about **$20** of that — the
layers price at **15–30 cents a PR**. The rest was **lanes** flown on
`tensorx/` models — a Claude Code lane runs 300–750 turns at ~100k tokens
each, TensorX's GLM endpoint hit cache about 48% of the time (the ruling's
own figure, #476; the request counts behind it are the cockpit's records), and
**one Flash lane alone cost over $15**, on the rung with the cheapest rate
card in this table. So "cheap" reads as cheap per judge run and not per lane, and a lane
here is the leader's deliberate exception, priced before dispatch. The
instrument that would show the next such bill on the board before the invoice
is delivered: a lane's metered spend is read at teardown from the runtime's
own records (teomach-cockpit#340).

**The mapping is the human's role ruling (#418), not a benchmark claim** —
the precedent is #404 for codex and #406 for Gemini. Nothing has ranked a
TensorX rung against its Claude, Gemini or codex near-peer on real material,
and the ruling (#476) closes the measurement rather than opening one: the
journal reads passively.

**The GLM rungs are missing from opencode's `tensorx` block** — read
2026-09-18: `moonshotai/kimi-k3` is there, `z-ai/glm-5.3` and
`z-ai/glm-5.3-flash` are not, while 113 of the registry's providers carry a
`glm-5.3` id. With both GLM rungs deprecated the gap binds nothing this page
routes; it is named so a catalogue read is not mistaken for a model that does
not exist.

**Effort is declared per model, and on the Fable rung opencode declares
none.** The registry's `reasoning_options` for `moonshotai/kimi-k3` is a bare
`{"type": "toggle"}` with no effort enum. The ruling (#418) records Kimi K3
as always-thinking with a `reasoning_effort` of low/high/max defaulting to
max at the API, and the `low` that finishes a judge packet reaches it through
opencode's provider config rather than `--variant` (teomach-cockpit#283) —
the Gemini section above records that an unrecognised `--variant` is accepted
in silence on this runner, so a probe that appears to work proves nothing on
its own. On the `claude` runtime no effort reaches it at all
(teomach-cockpit#288).

## How to apply a recommendation

**The model, effort and backup per job are §The ruled table (#476), one
copy, cited from here; what this table adds is the spelling each runner
takes on its dispatch line**, measured on this box and cited to the cockpit
where the wiring is its.

| Ruled row (#476) | Runner | Dispatch spelling |
|---|---|---|
| Leader | Claude Code | the `flight`/`squadron` leader tab, on the box's model and effort; the codex backup seat waits on the runtime flag, teomach-cockpit#324 |
| Lanes on Claude — mainstream, complex, templated | Claude Code | `wingman -m <full id>` — `claude-opus-5`, `claude-fable-5-1`, `claude-sonnet-5` by row; effort per the Claude Code bullet below |
| Lanes and critics on codex | codex | `-m gpt-6-astra` (or `gpt-5.6-terra`) with `-c model_reasoning_effort=<v>` on `codex exec`; through `wingman -x -m <id>` the effort setting has no flag, not established otherwise |
| Reviewer, templated backup and backup critic on Gemini | opencode | `--model google/gemini-3.8-flash --variant high` |
| Kimi K3's judge seat | opencode | `--model tensorx/moonshotai/kimi-k3`, `low` in the provider config — teomach-cockpit#283 |
| Kimi K3 as builder backup or critic | `claude` runtime | `--model moonshotai/kimi-k3`, bare, pointed at TensorX by the cockpit's wiring; no effort setting reaches it, so a critic runs at its default maximum (teomach-cockpit#288, #476) |
| The judge's two layers | `wingman-judge` | until teomach-cockpit#325 wires the defaults: `FLIGHT_JUDGE_RUNNER=claude FLIGHT_JUDGE_MODEL=claude-sonnet-5 FLIGHT_CROSS_RUNNER=opencode FLIGHT_CROSS_MODEL_OPENCODE=google/gemini-3.8-flash FLIGHT_CROSS_VARIANT=high` on the command line |

**Effort levels are not a scale shared across vendors, so an effort setting
only compares within one family's ladder.** Kimi's `low` spends ~500–2,000
reasoning tokens on a judge packet where GLM 5.3's `low` spends ~13,000 — a
stepped-pair rule (an advisor one effort below the builder) is meaningful
only within one vendor.

**On the `claude` runtime the effort field is not spent at all.** TensorX's
Anthropic-compatible endpoint ignores the effort field Claude Code sends for
every model (teomach-cockpit#288), so on Claude Code a TensorX model always
runs at its default, which is max — the reason Kimi's judge seat is
opencode's, and the reason its `claude`-runtime seats (builder backup and
critic) run at `max` with no lever.

**What the ruling leaves open, named so it is not mistaken for settled:**
whether Gemini 3.8 Flash's findings as the reviewer are accepted at the rate
the deprecated rung's were (the `cross_verdict` reading above, one flight
old); Plus versus Max 5 on the ChatGPT plan (one formation on Plus, meter
read); and the allowance one token draws on either subscription, the
`IMPROVEMENTS.md` item — none of them measured on purpose, all read
passively off the journal.

- **In a session:** pick the model before invoking the skill (`/model`, or the
  launch flag). The tier table above is the lookup.
- **On a Claude Code lane:** the model is `wingman -m <full-model-id>` —
  the dispatch verb refuses an alias. Effort
  is Claude Code's own `--effort <level>`, and `wingman` carries no flag for
  it as at 2026-09-21 (its usage line has `-m` and nothing for effort), so a `wingman` lane's effort is the
  box's `~/.claude/settings.json` value; the ruled defaults for the verb
  (Opus at `high` for an unpinned `wingman`) are teomach-cockpit#325's to
  wire.
- **Pinning:** `model:`/`effort:` frontmatter can hold a Claude tier per skill;
  the three `device-hardening` reviews are the only pins today —
  `claude-opus-5` in each frontmatter, the in-family fallback the kernel's
  `review-independence.md` requires of an audit-grade review. **Deliberately
  not applied wholesale**: the estate's routing doctrine
  (`notes/ai-strategy.md`, and the orchestrator spec's "no router in v1") is
  evidence-first — pin a skill when a session on the wrong tier has actually
  cost something, not in advance.
- **At the orchestrator's trigger:** the dispatch (n8n event type, GitHub
  label) knows the task class — map it to the tier there, and reach for
  `effort` before model tier.
- **On a codex runner:** the tier is a `-m <id>` on the `codex exec` line and
  the effort `-c model_reasoning_effort=<v>` beside it; the codex table above
  is the lookup. Unpinned, the lane flies the box's `config.toml` model where
  it names one and the client's own default otherwise — neither of them a
  choice this page made.
- **On an opencode runner:** the tier is `--model <id>` on the `opencode run`
  line and the effort a separate `--variant <v>` beside it; the Gemini table
  above is the lookup. Unpinned, a lane takes opencode's own stored state,
  which is invisible in the command you typed — measured in
  `docs/cross-model.md` (teomach-cockpit).
- **On a TensorX id:** opencode takes it behind a `tensorx/` prefix —
  `--model tensorx/moonshotai/kimi-k3` — with Kimi's effort in the provider
  config; that is the runner for Kimi's judge seat alone. The `claude`
  runtime takes the bare id, `--model moonshotai/kimi-k3`, pointed at the
  endpoint by the cockpit's wiring, and spends no effort setting.

## Effort per carrier — potency per unit of allowance

**Two of the four carriers are subscriptions, and on a subscription the
dollar column is the wrong one.** Claude runs on a Max 20× plan and codex on
ChatGPT Plus: the marginal dollar is zero until the plan's window closes, so
what a task costs there is the allowance it draws, and the only proxies an
external board offers for that are its output tokens and its steps. TensorX
and Gemini are metered, and there the dollar column applies. **How much
allowance one output token draws is not established on either plan, and it
may differ by model** — the open item in `IMPROVEMENTS.md`, "The allowance one
token draws is unmeasured on both subscriptions", holds the measurement that
would settle it; this page does not resolve it, and every subscription cell
in the ruled table stands as a decision taken under that uncertainty.

**The external instrument is the DeepSWE leaderboard** — Datacurve,
`https://deepswe.datacurve.ai/`, v1.1, 113 tasks, updated 2026-09-03, read
2026-09-21, every model run on mini-swe-agent: long-horizon
software-engineering tasks scored pass@1 with a confidence interval, beside
average API-list cost, output tokens and agent steps per task; the
transcription this page cites is on teomach-skills#472. **It governs the
builder rows only** (#476) — it measures a lane building against a coding
task and none of the other shapes this page routes — and two rows whose
intervals overlap or touch are not ranked by it. Its reading, in one
paragraph: on Claude the knee is `high` on both upper rungs — Opus `high`
73% ±2 at 64k output tokens is the lowest effort the board does not separate
from `max` (74% ±4 at 118k), and no Fable-5 row passes more than Opus `high`
(Fable-5 `high` 69% ±1 at 57k), so a build-shaped lane runs Opus and Fable
keeps the work the tier names, which the board does not measure; the board's
Fable row is `claude-fable-5`, not the `claude-fable-5-1` this page pins. On
codex, astra at `medium` (73% ±3 at 20k) sits inside sol `max`'s interval at
a third of its tokens and astra `low` (67% ±1 at 11k) inside terra `max`'s at
a sixth, so on Plus one model carries every tier and effort carries the
tier's weight — the ruled `medium` for mainstream building and `high` for
complex work. Metered: Gemini 3.8 Flash `high` 74% ±1 at $2.36 shares the
board's top band; GLM 5.3 Flash `max` 63% ±4 at $0.24 and GLM 5.3 `max` 69%
±3 at $3.99 are the deprecated rungs' rows; Gemini 3.1 Pro `high` reads 12%
±1 at $2.14; Kimi K3 `max` 69% ±5 at $4.65. The leader's, the judge's and the
audit disciplines' work is not on the board, and those cells are the ruling's
alone.

**The table itself is §The ruled table above** — one copy, cited from here
rather than restated.

## Beyond Claude Code — where the other surfaces sit

The session-tier tool assignments, settled 2026-07-25 (reasoning in
`notes/ai-strategy.md`): **Claude Code** for repo work; **Projects** for
documents that accrete; **Gemini and NotebookLM** for search, corpora and
multimodal; **ablated Qwen** (Lemonade) for work a hosted model declines;
**Gemma 4 E4B on the NPU** as the offline fallback. Cowork stays parked —
Code plus Projects already covers it. The standing tier (the 24/7 executor)
is specified in the orchestrator spec in teomach-cockpit
(`specs/orchestrator-spec.md` there); local hardware is internal
only, since a workstation fails the customer-facing test before capability
is reached.

## The recommendations

## method

| Skill | Tier | Why |
|---|---|---|
| `setup` | **Sonnet** | Templated fixture creation — one short interview writes tier, domain, tracker and paths into `.teomach.yml` and `CLAUDE.md`; the skill leaves almost no open judgement. |
| `grill` | **Opus** | Sustained interviewing judgement — facts-vs-decisions routing, concrete forks, the confirmation gate — at the method's commonest failure point. |
| `to-questionnaire` | **Opus** | Interviewing the send and drafting a reader-facing document a professional answers async — grill's judgement plus prose that ships. |
| `to-spec` | **Opus** | Synthesis of the gate artefact where the named danger is a plausible spec built on guesses; strong drafting with honest thin-brief refusal. |
| `to-tickets` | **Opus** | Tracer-bullet decomposition, sequencing, and blocking-edge graphs are real architectural judgement. |
| `implement` | **Opus** | The default build orchestrator writing real artefacts against a domain profile; red-green-refactor with entropy resistance. |
| `bake-off` | **Opus** | Evidence-led selection with criteria agreed before candidates; prototype slices are creative build work, and the human selector is the check. |
| `lead-flight` | **Opus** | The flight leader drafts lane prompts and triage filings a human approves the same evening — artefacts that do not rerun; the judgement that reruns every session is the skill itself, written once. |
| `review` | **Fable**, cross-family | Audit mode requires a different model family by the kernel's own independence rule; the per-PR self-check simply runs in whatever model built the diff, while the unattended judge's coverage layer takes the pin above rather than the lane's family. |
| `verify` | **Sonnet** | Run-the-thing-and-quote-the-output discipline — the skill carries the rigour; the hard judgement lives in the work being verified. |
| `diagnose` | **Fable** | Forensic root-cause work (incident mode included); a subtle miss ships a symptom fix wearing a different shirt. |
| `research` | **Opus** | Judging source authority and following every claim to its primary owner; a guess is the skill's named failure mode. |
| `docs` | **Sonnet** | Docs derived mechanically from diff + ticket + spec under a strict same-PR rule; the hard judgement lives in review and the spec. |
| `handoff` | **Sonnet** | Structured compaction under the honesty rule — a guarded template, little open reasoning. |
| `threat-model` | **Fable** | Design-time security reasoning where a quiet miss becomes an incident; ablated Qwen adjunct when attacker-path enumeration needs unwatered depth. |
| `reverse-engineer` | **Fable** | Forensic archaeology where missing a load-bearing accident is the costliest miss in the kernel; discovered behaviour is evidence, not requirement. |
| `prose` | **Opus** | Drafting real prose to the register — strong general drafting under a lodestar, with the hard MT checks greppable and mechanical. |
| `new-skill` | **Opus** | Template- and linter-guarded, but axis placement and trigger prose need real drafting judgement. |
| `method-review` | **Fable**, cross-family | The method's reflexive audit wants a cold read by a different model family; a forensic audit of our own method needs an outside validator as the runner. |

## digital-services

| Skill | Tier | Why |
|---|---|---|
| `process-definition` | **Opus** | Modelling a real human process into schema-valid stages, routing, and validation criteria — schema-guarded but judgement-heavy. |
| `service-health` | **Opus** | Evidence-led entropy sweep with design judgement; the deep forensic passes are explicitly delegated to kernel `review` audit mode. |
| `strangler-fig-migration` | **Fable** | Cutover and backfill sequencing where a subtle miss is data loss or an untested fallback in production. |
| `validate-with-users` | **Sonnet** | Templated session planning and verbatim recording with explicit status states; the skill carries the discipline. |
| `django-service` | **Opus** | Strong build work under heavy, explicit guardrails — the profile pre-decides most architecture; kernel `review` supplies the cross-family cold read separately. |
| `n8n-service` | **Sonnet** | Pure-workflow wiring against an agreed process definition — templated, well-guarded work. |
| `bespoke-service` | **Fable** | Instantiating a stack profile authors the rulebook every later session obeys — bake-offs, carve-out mapping, scanner-set design for an arbitrary ecosystem. |
| `platform-service` | **Fable** | Seam and trust-boundary architecture, contract design, and seam-ledger judgement on inherited systems — exactly where a subtle miss is expensive. |

## board-games

| Skill | Tier | Why |
|---|---|---|
| `setup-game` | **Sonnet** | Templated scaffolding from provided assets; a short configuration interview with hard fixtures — little judgement left open. |
| `capture-design` | **Opus** | Extracting unarticulated design intent via concrete forks, and knowing facts-vs-decisions and when capture is done, is real interviewing judgement. |
| `implement-target` | **Opus** | Real build work across the target stacks, conformance-test-first; the target profiles ride as references. |
| `design-review` | **Fable**, cross-family | The skill itself demands audit mode run in a different model family, cold; per-change/per-build self-checks run inline in the building session's own tier. |
| `playtest` | **Sonnet** | Format-driven session planning and logging with explicit quarantine rules; findings route onward through `capture-design` for the hard thinking. |
| `diagnose-balance` | **Fable** | The table's trigger for kernel `diagnose` — forensic reproduce-minimise-hypothesise work where a subtle miss wastes the method's scarcest resource (a table session). |

## productions

| Skill | Tier | Why |
|---|---|---|
| `capture-premise` | **Opus** | High-judgement structured interviewing and PRD authorship, but the producer is in the loop answering every fork; strong drafting, not forensics. |
| `premise-bakeoff` | **Opus** | Generating and punch-up-surgering comedy premises is real creative build work; the producer scores, so selection risk is held by the human. |
| `write-draft` | **Fable** | The pack's hardest routine work: three-dial register held at line level, the plant/payoff grounding graph, and the detachable-unit invariant. |
| `build-output` | **Opus** | Mostly derivation from the script, but the pitch and bible are public-facing prose under the machine tells, and the festival cut needs the no-orphaned-plant check. |
| `tech-breakdown` | **Opus** | Constraint-satisfaction planning against the actual kit and crew; the shootability call needs solid practical reasoning, not doctrine depth. |
| `diagnose-scene` | **Fable** | Forensic craft diagnosis (which dial, which line, which ungrounded concept) where a wrong diagnosis triggers rewrites that lose what the last read proved. |

## marketing-sites

| Skill | Tier | Why |
|---|---|---|
| `capture-brief` | **Opus** | Interview-led spec authoring: wedge extraction, claims discipline, and knowing what's missing are real drafting judgement. |
| `marketing-site` | **Opus** | The Build stage — real pages, standalone design direction, copy in a set voice under the PRD guard; the pack's default builder. |
| `teomach-brand` | **Opus** | Named profile loaded into the build session; the three-non-colour-differences branch test is genuine design judgement, not token copying. |

## compliance

| Skill | Tier | Why |
|---|---|---|
| `cyber-essentials` | **Opus** | Real drafting with audit consequences, but heavily guarded — answers generated from the estate's controls and the single-copy mapping; scope judgement routes to the certifying body. |
| `cloud-security-principles` | **Opus** | Per-engagement drafting against a client's procurement team; allocation and IDs come from references. |
| `dpia` | **Fable** | Legal-adjacent reasoning the ICO may read — necessity/proportionality testing, likelihood-times-severity from the individual's perspective, Art 36 escalation judgement. |
| `continuity-plans` | **Opus** | Real operational drafting — per-activity dependency-failure reasoning, a named continuity strategy, the restore runbook and the contact tree — but the position is supplied by the merged policy, anything it doesn't commit is a gap finding rather than a call made here, and the exercise validates the plan, not the session. |
| `ai-audit` | **Fable** | Cross-repo forensic audit where a confidently wrong verdict ships a false compliance claim — entitlement read from live principals against moving vendor terms, unattended reality against the policy's tiers; its own doctrine sends the depth pass to the strongest tier at dispatch. |

## device-hardening

| Skill | Tier | Why |
|---|---|---|
| `device-hardening` | **Sonnet** | The router — doctrine and routing consulted, no side effects; the judgement lives in the registers and skills it routes to. |
| `onboard-offboard` | **Opus** | Real side effects on real people's access — identity grants, same-day offboarding choreography — under explicit ordered steps and the inventory-PR gate. |
| `estate-review` | **Fable**, cross-family | Audit mode wants a different model family by the kernel's independence rule; the frontmatter's `claude-opus-5` is the in-family fallback that fires on model invocation. |
| `software-review` | **Fable**, cross-family | Same shape as `estate-review`: cross-family for the audit-grade run, the frontmatter Opus pin as the in-family fallback. |
| `ai-review` | **Fable**, cross-family | A review of our own AI approach is the clearest case for an outside family; the frontmatter Opus pin is the in-family fallback, and half the register is settled by running commands, not by tier. |

## company-docs

| Skill | Tier | Why |
|---|---|---|
| `draft-policy` | **Opus** | Real drafting of policy wording, but the legal position is supplied by the references and the fact-guard plus the pre-issue legal read flag bound the judgement. |
| `standard-agreements` | **Opus** | Binding-document drafting with the highest exposure in the pack, but always behind the pack's pre-issue legal read before the document is issued. |
| `handbook` | **Sonnet** | Assemble-don't-rewrite view of merged policies with mechanical gap- and sign-off-flagging against the register — templated work by design. |
| `set-review` | **Fable** | The expert-panel whole-set audit: each lane reads as a named professional with legal currency checked live, and the synthesis is cross-document judgement whose misses recur in every issued document — the skill's own doctrine sends the depth lanes to the strongest tier at dispatch. |

## statutory-records

| Skill | Tier | Why |
|---|---|---|
| `statutory-registers` | **Opus** | Edits the record that is legal proof of ownership and routes central-record divergences to filings. |
| `share-transaction` | **Opus** | Multi-record legal choreography — allotment vs transfer, pre-emption, authority checks — real drafting where sequence errors misstate ownership. |
| `board-and-resolutions` | **Opus** | Drafting corporate authority with the right decision-maker and threshold; a wrong ordinary/special call makes the action defective. |

## tenders

| Skill | Tier | Why |
|---|---|---|
| `tender-response` | **Opus** | The pack's build orchestrator: persuasive drafting under a hard fact-guard; validation routes to kernel `review` in a different model before the gate. |

## internal-services

| Skill | Tier | Why |
|---|---|---|
| `internal-services` | **Fable** | The overlay's routine hard act is declaring reach — credential scopes as enforced, blast-radius calls, exception design — where a quiet miss changes what an agent may touch. |

## skill-authoring

| Skill | Tier | Why |
|---|---|---|
| `new-pack` | **Fable** | Cutting a domain into skills and naming its substitution is doctrine authoring — a subtle miss reruns in every future session. |
| `pack-review` | **Fable**, cross-family | The skill's own doctrine demands a cold read by a different model family; a forensic audit of our own method wants an outside validator as the runner. |
