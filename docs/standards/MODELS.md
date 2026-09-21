<!-- Source: teomach-skills MODELS.md @ 172f26d —
     rendered at guard-set v16 by scripts/wire-repo.py; edit it at source and
     re-run `scripts/wire-repo.py update`, never edit this copy. -->

# Models — which tier runs which skill

Recommendations, not enforcement: the tier named here is the one a session
**running that skill** should reach for, judged by the hardest thing the skill
routinely does. Re-derive when a pack changes shape; a table like this rots
exactly the way `pack-shapes.md`'s counts do.

## The tiers, and what each is for

**A tier names a level of expertise, never a vendor** — the ruling (#423).
Which family serves a tier is the flight leader's call at
dispatch, made on the context in front of them — available Claude budget,
wanting a second frontier opinion from `astra`, wanting cheap TensorX
compute. The substitution rule is the leader's judgement, not a table
lookup: the tier is set by the work, the family by what the leader knows
about the job, the budget and what a second perspective is worth that day.

| Tier | Reach for it when | Default | Substitutable with |
|---|---|---|---|
| **Sonnet** | The skill is templated and well-guarded — scaffolding, filing, structured recording. The skill carries the judgement so the model doesn't have to. | Claude Sonnet | GLM 5.3 Flash, `terra` — when the work is tightly scoped and needn't be Claude-shaped |
| **Opus** | Real drafting and build work — most orchestrators that write artefacts a human will read or merge. The estate default. | Claude Opus | GLM 5.3, `sol` — mainline build the leader is confident needn't be Claude-shaped |
| **Fable** | A subtle miss is expensive — flight leading, repo-level audit work, forensic diagnosis, doctrine authoring, threat models, seam/architecture judgement, anything that reruns in every future session if wrong. | Claude Fable | `astra`, Kimi K3 |

*Flight leading* is the leader's own dispatch judgement, not a skill
session: a session running the `lead-flight` skill takes that skill's row
in the recommendations below.

**Each substitute is its family's rung at the same tier, named by rung
rather than by id** — the three family tables below are the id lookup
(codex, ruling #404; Gemini, ruling #406; TensorX, ruling #418), and a tier
here reads across to the same-tier row there: that is the whole peer
mapping. The substitute cells are the ruling's own list (#423): Gemini's
Opus and Sonnet rungs are peers by the same mapping and remain a lane
option — its own section below — but the ruling names them in no substitute
cell. And **Gemini has no Fable rung** — its family table below records the
ruling — so Gemini cannot serve the Fable tier: the seven audit
disciplines' cross-family runs go to `astra` or Kimi K3, never Gemini. The
judge's cross-model reviewer is a separate pin, recorded below, and is not
moved by this table.

**Constraints ride beside the tier, never inside it.** A constraint narrows
which family may serve a tier; it is not a level of expertise, so it is
written next to the tier in one shape — the Tier cell reads **Fable**,
cross-family — and never as a row of the tier table. The three the ruling
(#423) names:

- **cross-family** — the run must come from a different model family than
  the one that built the work, because a model auditing its own family's
  output is blind to its own tells. The seven audit disciplines in the
  recommendations below carry it, at the Fable tier.
- **ablated** — work a hosted model refuses or waters down runs on ablated
  Qwen (local, Lemonade) — a Sonnet-tier model reached by constraint, not a
  rung. No skill wants it as the primary today; it appears as an adjunct
  (attacker-path enumeration in `threat-model`).
- **supreme privacy** — material we do not trust Anthropic, OpenAI, Google
  or TensorX with runs on ablated Qwen too: ablated work and supreme privacy
  are the two jobs it is the only trusted model for. No recommendation row
  carries it; it is claimed at dispatch, when the material warrants it.

**The ids the tiers mean, and the reason to write them out.** Sonnet is
`claude-sonnet-5`, Opus is `claude-opus-5`, Fable is `claude-fable-5-1`, and the
cross-family reviewer is `moonshotai/kimi-k3` — the ruling (#418), with
`google/gemini-3.1-pro-preview` behind it as the named fallback. **Always the
full id, never the short alias** — probed on this box against Claude Code
2.1.212, `sonnet`
resolves to `claude-sonnet-5` but **`opus` resolves to `claude-opus-4-8`**, one
generation back, silently and with no warning. An alias is a promise the CLI
keeps on its own schedule; a pinned id is the one we chose.

**The reviewer's id is per runner, and the runner order is the cockpit's
ruling (teomach-cockpit#291).** The pin is **Kimi K3** (#418); its first
runner is **opencode**, where the id is `tensorx/moonshotai/kimi-k3` and the
`low` effort rides the provider config — the only route that lands it. Behind
it, the **`claude`** runtime against TensorX's Anthropic-compatible endpoint,
where the id carries no provider prefix, `moonshotai/kimi-k3`, and the effort
field is not read, so the model runs at its default maximum and a judge-sized
packet does not finish: the journal's 29 rows on that runner, all of
2026-09-18, read 17 NO-ANSWER, 5 PASS, 5 FAIL, 2 NOT-CHECKABLE. Behind that,
the Gemini pro rung. The base URL, the credential and how a dispatch chooses
between the three are teomach-cockpit's wiring; this page pins the id and its
spelling per runner, and stops there.

**Every measured independence figure on this page is the Gemini rung's, and
reading one as the current pin's is the mistake to avoid.** The flight journal
(`~/.local/state/teomach/flight-journal.tsv`) holds those runs: `cross_runner`
and `cross_model` read `opencode` and `google/gemini-3.1-pro-preview` on 595
rows from 2026-08-17 onward, the line each of those judge reports names in its
own cross-model row being `opencode run --model
google/gemini-3.1-pro-preview --variant high` — read on 2026-09-09 in this
repo's reports. Effort is a separate `--variant` flag on that runner rather
than part of the id. What the layer costs there is smaller than the figures
below: of the 230 runs journalled between 2026-09-06 and 2026-09-09, the 228
that recorded a cost read a median **$0.12**, range $0.03–$0.71. **Kimi K3's rows begin
2026-09-18**, and their counts and median cost are in §Effort per carrier
below — under the Gemini rung's median, where the published rates ($3.00/$15.00
per M against $2.00/$12.00) would have put it above. The journal holds no
token counts, so why is not established from it; the rows are different
packets on different days.

**`gemini-3.1-pro-low` is the `agy` fallback's spelling of the Gemini rung now
third in that order, and reaches no other runtime.** It is an **Antigravity
id**, model and reasoning effort fused into one string; it is not a Google API
model id and opencode has never heard of it. It is what
`FLIGHT_CROSS_RUNNER=agy` sends. That catalogue could not be re-read on
2026-09-09 — `agy models` (agy 1.1.28) answered
`Please sign in to view available models` — so what the fallback is served
today is **not established**.

**Effort, not family, is where the cost came out — and the reason is that the
cross-model reviewer was never the expensive half.** Measured across the flight
of 2026-08-02/03, independence cost **$0.27–$0.43 on every run** while the
coverage layer, then on Claude Sonnet, ran **$0.82–$5.78**. On the lane that
spent ~$26 over five runs, the cross-family reviewer was about **$1.90 of
it**. So the reviewer
is chosen for **judgement quality and reliability**, and only then for price: a
pro-tier model on the one job that exists to catch what the in-family checks
missed. On `agy`, effort was the axis that bought the saving — dropping
`gemini-3.1-pro-high` to `-low` also shortened the runs that were **timing
out**, three consecutive times on `-high`, at exit 124 with zero tokens in and
out after 299 seconds.

**The coverage layer** — `judge-doctrine.md`'s in-family checks — **runs
metered, on `z-ai/glm-5.3-flash`**, the ruling (#424), and it is **one judge
model for every lane rather than the delivering family's flash rung looked up
per lane**. The argument is that page's own: *"a control that cannot run must
be loud, because a control that fails silently is worse than one nobody
installed"*. A gate paid out of a subscription allowance stops when the
allowance does — on the busiest day, which is the day it was most worth
having, and with nothing to hear. Metered credit has no such day. What makes
the pin safe to take on something other than judgement is the same page's
ranking: *"fewer applicable checks per run is worth more than fewer runs, and
far more than the choice of model"* — following a checklist against a diff is
the one job where tier buys least. Price is then a supporting fact rather than
the argument: against the other candidate, the Gemini flash rung, GLM 5.3 Flash
is **3.75× cheaper on input and 7.5× on output** — both rate cards are in the
family tables below — and it reaches the `claude` runtime through TensorX's
Anthropic-compatible endpoint where the Gemini rung needs opencode. **Wiring it
is teomach-cockpit's**; this page pins the model and stops there.

**The coverage layer's cost has an instrument, and since 2026-08-30 it names
the family too:** the flight journal's **`coverage_usd`** column, beside
`independence_usd`, records the spend, and `coverage_runner` and
`coverage_model` beside it say who bought it — the per-family counts and
medians are in §Effort per carrier below; codex's rows carry an empty cost
column, because an OAuth session prints none. Rows before that date carry the
number and no family. On the
**902 rows that bought both layers** between 2026-08-01 and 2026-09-18,
coverage totals **$1,907.89** against independence's **$152.87**: **12.5× the
metered half**, and that like-for-like rate is the one to carry rather than any
single PR's. Journal-wide the gap is wider, because many runs buy no
independence at all — **$3,738.33 of coverage over 1,627 rows** against
**$159.50 over 955**. On a subscription row that figure is `claude -p`'s own
`total_cost_usd`, Anthropic's card applied to the tokens rather than money that
left an account: the column is recorded, and nothing bills it.
**Read those columns and not a lane's judge report**, whose running total is a
different quantity — both layers, and only since the lane's first commit — so
the two never reconcile and were never meant to.

**A reviewer that never dissents is as useless as one that never answers, and
the summary line separates them:** every judge
report names the independence layer's own outcome on its own line, and the
flight journal (`~/.local/state/teomach/flight-journal.tsv`) carries it as a
`cross_verdict` column, so the dissent rate is a `cut` away rather than a
reconstruction from merged PR bodies. **That column is the instrument that
judges the new pin, and against Kimi K3 it reads in §Effort per carrier below.** It carries a second
question now that the coverage layer is outside the delivering family too: a
dissent rate that *falls* would mean the two layers had been buying some of the
same decorrelation, and the reviewer's own pin wants re-arguing. The number to
beat is the Gemini rung's: on the flight of 2026-08-02/03 that reviewer
raised findings accepted on two PRs and one that a third PR rebutted with
evidence. So the first judge reports flown on Kimi *are* the measurement, and
the reading cuts both ways — several consecutive runs with no dissent is the
signal to move, and a run of findings nobody accepts is the same signal wearing
the other shirt. If price rather than judgement is what moves it, the cheaper
reviewer is Gemini's flash rung in the table below, at roughly a third of its
own pro rung's rates, trading tier for price rather than effort; **the TensorX
ladder's GLM flash is not a candidate**, because it is the coverage runner
above, and a reviewer on the coverage layer's own model asks that model whether
it was right — the one thing this layer exists not to do.

## The Gemini family — the same ladder on opencode

The tier a piece of work needs does not move with the runner; the id it
resolves to does. Gemini is the named fallback behind the judge's
independence-layer pin — the human's ruling, #418 — and an option for a lane;
opencode is the runtime that carries it in either job, so this mapping exists
to be pinned against. The ids and rates below were read
on **2026-09-09** from opencode 1.18.20's own model registry
(`~/.cache/opencode/models.json`, refetched that morning); what each row claims
about entitlement comes from probes against this box's credential the same day.

| Tier | opencode id | Basis |
|---|---|---|
| **Fable** | *(no rung ruled)* | The ruling (#406) maps two rungs and no third, and the registry lists nothing above `gemini-3.1-pro-preview` in the pro line — every newer google entry on 2026-09-09 is flash, image, speech or embedding. |
| **Opus** | `google/gemini-3.1-pro-preview` | Ruling (#406): the near-peer of Opus and of codex's `sol`. Served by this credential on 595 journalled judge runs since 2026-08-17. $2/M input, $12/M output, $0.20/M cached, doubling to $4/$18/$0.40 above 200k of context. |
| **Sonnet** | `google/gemini-3.8-flash` | Ruling (#406): the near-peer of Sonnet and of codex's `terra`. Served by this credential — probed 2026-09-09, answered and billed. $0.75/M input, $3.75/M output, $0.075/M cached, no context tiering. |
| *(no rung)* | `google/gemini-3.1-flash-lite` | Judgement: $0.25/$1.50, below the flash rung, and this ladder has nothing under Sonnet. Named so it is not mistaken for the bottom of three. |
| *(no rung)* | `google/gemini-3.7-flash`, `google/gemini-3.6-flash`, `google/gemini-3.5-flash` | Earlier flash generations. 3.7 and 3.6 price identically to the pinned rung and 3.5 at twice it, so a rung routed here would buy nothing. |
| *(no rung)* | `google/gemini-flash-latest` | An alias, not a pin: its own registry entry is stamped `release_date: 2026-08-13` where `gemini-3.8-flash` is stamped 2026-09-02, so what it resolves to is **not established** — the reason the Anthropic ids above are written out too. |

**The mapping is the human's role ruling (#406), not a benchmark claim.**
Nothing has ranked a Gemini rung against its Claude or codex near-peer on real
material: the pro rung has flown hundreds of times as the judge's reviewer and
the flash rung has flown none, and a reviewer's dissent rate measures the layer
rather than the model. What the ladder settles is which id a piece of work of a
given weight reaches for when Gemini is the runner. Displace a pin the day a
Gemini lane produces evidence either way. **Effort per use is the ruling
(#445), recorded in "How to apply a recommendation" below, not a per-rung
setting of this table.**

**The catalogue is not an entitlement, and only a run separates them.**
`opencode models` prints every provider's list rather than what this credential
is served: seventeen of its providers carried a `gemini-3.8` id on 2026-09-09.
What settles a rung is a run — `opencode run --format json --model <id>`
coming back with a text part and a `cost` field — and both pinned rungs
answered that way. The flash probe checks the rates as well as the entitlement:
11,719 input, 3 output and 39 reasoning tokens came back billed at
**$0.00894675**, exactly the registry's $0.75 and $3.75 per million applied to
those counts with reasoning billed as output.

**Effort rides the dispatch line as `--variant`, and it is visible on one rung
of the two.** The registry declares `effort` values `low, medium, high` for
both. On the **flash rung** the setting separates: one prompt run seven times
on 2026-09-09 returned **0 reasoning tokens at `low` on all three runs**, 24 at
`medium`, and 39, 76 and 105 at `high`. On the **pro rung** the same probe does
not separate — `low` returned 67 and 118 reasoning tokens against `high`'s 79
and 126 — so
that the flag lands there is **not established** by this instrument. **An
unrecognised value is accepted in silence**: `--variant nonsuch` on the flash
rung exited 0, answered, and spent 129 reasoning tokens, so a typo buys an
effort nobody chose rather than an error.

## The codex family — the same ladder, a different runtime

The tier a piece of work needs does not move with the runner; the id it
resolves to does. `codex exec` flies from the cockpit both as a lane runner and
as an option for the cross-model reviewer, and an invocation carrying no `-m`
takes a default nobody here chose — so this mapping exists to be pinned
against. The probe behind it is `docs/codex.md` (teomach-cockpit), against a
ChatGPT **Plus** credential; this page carries the mapping and cites rather
than restates the probe. The registry facts the mapping turns on were re-read
on **2026-09-09** — codex-cli 0.153.4, the same Plus credential, from a cache
stamped `fetched_at: 2026-09-08T23:19:03Z`.

| Tier | codex id | Basis |
|---|---|---|
| **Fable** | `gpt-6-astra` | Ruling (#404): detailed planning, where the highest quality matters — the registry's own priority-1 entry, "Our most capable model for complex, demanding work". Nothing has ranked it against `sol` on real material. |
| **Opus** | `gpt-5.6-sol` | Ruling (#404), and the default preference for new codex tasks on a metered credential — as Opus 5 is the Claude default; on the Plus credential lane work takes `astra` by tier (§Effort per carrier). The registry's "Reliable agentic workhorse for everyday tasks", at priority 6. |
| **Sonnet** | `gpt-5.6-terra` | Ruling (#404): well-defined, well-scoped, less complex or risky work — the registry's "Balanced agentic coding model for everyday work", at priority 7. |
| *(no rung)* | `gpt-5.6-luna` | Judgement: cheaper and faster than `terra`, and this ladder has nothing under Sonnet, so nothing routes to it. Named so it is not mistaken for the middle of three. |
| *(no rung)* | `gpt-5.5` | The previous generation, under everything already pinned. Named so every listed slug is accounted for. |

**The mapping is the human's role ruling (#404), not a re-measurement — and
both instruments that settled the Gemini pin are still missing here.** There is
no price to compare: the credential is an OAuth ChatGPT session rather than an
API key, so a run prints no cost field at all and the flight journal's
`independence_usd` is empty on every codex row. And nothing has ranked these
against each other on real material — the probe was synthetic throughout, and
the runs against real material were all pinned to `gpt-5.6-sol`. The registry's
own measured descriptions support the ruling rather than settle it: read from
`~/.codex/models_cache.json` and quoted as at 2026-09-09, `gpt-6-astra` is "Our
most capable model for complex, demanding work", `gpt-5.6-sol` a "Reliable
agentic workhorse for everyday tasks", `gpt-5.6-terra` a "Balanced agentic
coding model for everyday work", `gpt-5.6-luna` a "Fast and affordable agentic
coding model", and `gpt-5.5` a "Proven previous-generation model for coding and
general work". The registry's `priority` field orders them the same way —
`astra` 1, `sol` 6, `terra` 7, `luna` 8, `gpt-5.5` 12. Default effort is the one
signal that does *not* separate them: `astra` and `sol` both ship `low`,
`terra` and `luna` both `medium`. The ruling maps codex's roles onto the tiers,
not particular version strings. Displace a pin the day a codex lane produces
evidence either way. **Effort per use is the ruling (#445), recorded in "How
to apply a recommendation" below — codex's `high` there is a dispatch
setting, not a rung of this table.**

**The Fable row now has a runner, not a finding of absence.** `gpt-6-astra`
answers this credential and has flown a lane to a merged PR (teomach-cockpit's
`docs/codex.md`); the ruling (#404) enters it on the strength of that and the
registry's priority-1 ranking, not because a pro-tier entry appeared. The
forensic skills that want the Fable rung — `diagnose`,
`reverse-engineer`, `threat-model`, `new-pack` — can now fly codex on the tier
they ask for, rather than routing elsewhere or dropping a rung down quietly;
the caveat above still stands, since nothing has run forensic material through
`astra` yet.

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
`--variant`, which accepts nonsense in silence. **What
the setting does above `high` is not established.** `low` and `high` separate
cleanly on reasoning-token count; `high` and `xhigh` do not; and `ultra` is
advertised by the client, absent from the server's enum, and accepted without
complaint by something that maps it before dispatch. Pin `high` and read the top
of that ladder as unknown here; what it spends is measured externally — on the
DeepSWE board astra's `max` row carries 61k output tokens to `high`'s 27k for
the same pass rate (§Effort per carrier).

**The subscription's economics are not established either, and that is why no
codex tier here can be defended on price** — §Effort per carrier below reads the
codex column on output tokens for that reason, and names the token-to-quota
rate as its unmeasured half. Quota is the only axis, it is
reported at one-percentage-point resolution and only into the on-disk
transcript, and what exhaustion looks like was never measured. The cost
arithmetic this page does for the Gemini pin cannot be repeated for codex.

**None of this settles which runner the judge stands on.** The human ruled the
cross-model pin (#418) to the Kimi K3 rung in the TensorX table below, with
the Gemini pro rung behind it; codex is wired as a third alternative and has
22 journal rows on `gpt-5.6-sol` by 2026-09-21 — 13 FAIL, 7 NOT-CHECKABLE, 2
ERROR, no PASS. Counts, not a judgement of the findings: the argument that
would take a pin is the dissent-rate one above, and it wants dispositions
rather than counts.

## The TensorX family — the same ladder, pinned on two runtimes

The tier a piece of work needs does not move with the runner; the id it
resolves to does. TensorX is a hosted provider of open-weights models, and it
serves them behind two endpoints at once — an OpenAI-compatible
`https://api.tensorx.ai/v1`, which is what opencode's `tensorx` provider
speaks, and an Anthropic-compatible `https://api.tensorx.ai`, which the
`claude` runtime speaks. All three rungs fly the `claude` runtime against the
second of those, so the ids below are written bare, as that runtime takes them;
opencode takes the same id behind a `tensorx/` prefix. That is what makes this
family, alone of the three here, worth pinning on two runners rather than one.
The mapping and the rates are the ruling's own (#418, measured 2026-09-18); the
registry facts below were re-read on **2026-09-18** from opencode 1.18.30's
cache (`~/.cache/opencode/models.json`), and the two GLM rows' rates come from
**tensorx.ai/models as at 2026-09-18**, which is where they are published.

| Tier | TensorX id | Basis |
|---|---|---|
| **Fable** | `moonshotai/kimi-k3` | Ruling (#418): the forensic rung, and the judge's cross-model reviewer. Carried by the registry — $3.00/M input, $15.00/M output, $0.75/M cached, 1,048,576 of context and 131,072 of output, reasoning and tool calls both declared. |
| **Opus** | `z-ai/glm-5.3` | Ruling (#418): build work, the near-peer of the estate's Opus default and of codex's `sol`. $1.75/M input, $4.50/M output, $0.44/M cached, 1M context — tensorx.ai/models as at 2026-09-18. **Absent from opencode's `tensorx` block**, which tops out at `z-ai/glm-5.2`. |
| **Sonnet** | `z-ai/glm-5.3-flash` | Ruling (#418): templated, well-guarded work — the near-peer of Sonnet and of codex's `terra`. $0.20/M input, $0.50/M output, $0.05/M cached, 1M context — tensorx.ai/models as at 2026-09-18. Absent from the same block. |
| *(no rung)* | `z-ai/glm-5.2`, `moonshotai/kimi-k2.6`, and the other 23 | The generations under the pins, and this provider's other vendors — Qwen, DeepSeek, MiniMax, Nemotron, `openai/gpt-oss-120b`. Twenty-six ids in the provider on 2026-09-18; named so the three pinned rungs are not mistaken for the whole catalogue. |

**The mapping is the human's role ruling (#418), not a benchmark claim**, and
deliberately so — the precedent is the human's two earlier rulings, #404 for
codex and #406 for Gemini. Nothing has ranked a TensorX rung against its
Claude, Gemini or codex near-peer on real material, and no lane has flown one:
there is no dissent rate, no cost record and no forensic run to cite, because
the ruling is what comes first and the flying is the measurement. What the
ladder settles is which id a piece of work of a given weight reaches for when
TensorX is the provider. Displace a pin the day a TensorX lane produces
evidence either way. **Effort per use is the ruling (#445), recorded in "How
to apply a recommendation" below, not a per-rung setting of this table.**

**The GLM rungs are missing from opencode's `tensorx` block, and the gap is
that block's rather than the registry's.** Read 2026-09-18: `moonshotai/kimi-k3`
is there, `z-ai/glm-5.3` and `z-ai/glm-5.3-flash` are not, and the newest z-ai
entry under `tensorx` is `z-ai/glm-5.2`. The registry itself is neither stale
nor ignorant of the model — its newest entry anywhere is stamped 2026-09-17,
and **113 of its providers carry a `glm-5.3` id**; z-ai's own first-party
blocks are behind too, `zai` at `glm-5.1` and `zhipuai` at `glm-5.2`. So this
is a catalogue lagging a vendor, not a model that does not exist, and it binds
opencode alone: the `claude` runtime takes the id from the dispatch line and
asks TensorX, so nothing here stands between it and a GLM lane. Whether that
endpoint serves these two under these spellings is the cockpit's to settle,
and is **not established** on this page.

**Effort is declared per model, and on the Fable rung opencode declares none.**
The registry's `reasoning_options` for `moonshotai/kimi-k3` is a bare
`{"type": "toggle"}` with no effort enum, where `z-ai/glm-5.2` — the nearest
entry the registry has to the GLM rungs — declares `none, minimal, low,
medium, high, xhigh, max`. The ruling records Kimi K3 as always-thinking with a
`reasoning_effort` of low/high/max defaulting to max, and GLM 5.3 with the same
three levels, at the API. **Whether opencode's `--variant` reaches either is
not established**: on the Fable rung the registry gives the flag nothing to
send, on the GLM rungs there is no entry at all, and the Gemini section above
records that an unrecognised `--variant` is accepted in silence on this runner
— so a probe that appears to work proves nothing on its own.

## How to apply a recommendation

**Per-use model and effort are the ruling (#445), and the table is the
lookup rather than a derivation** — every number in it cites a cockpit
issue and is not re-measured here.

| Use | Model | Carrier | Effort | Basis |
|---|---|---|---|---|
| PR judge / packet reviewer | Kimi K3 | opencode | **low** | the only level that finishes a one-shot judge packet (79 s at low, never at high/max — teomach-cockpit#283); dissents correctly on real PRs |
| In-line (coverage) judge | GLM 5.3 Flash | Claude Code | the model's default (max) | 90 tool-driven turns, none at the cap, $0.10–0.30 a round (teomach-cockpit#297); opencode-at-low parked with a trigger |
| Lanes on Kimi K3 / GLM 5.3 / GLM 5.3 Flash | as tiered (#418) | Claude Code | the model's default (max) | the full harness and the model at its best for build work; no lane-cost measurement bought (teomach-cockpit#294) |
| Leader | Fable | Claude Code | medium | as run |
| Fallback reviewers | Gemini 3.1 Pro (agy/opencode), GPT sol (codex) | as wired | agy: low (fused in the id); codex: high | unchanged |

**Claude and codex lanes are not rows of that table; their model and effort
per tier are §Effort per carrier below.**

**Effort levels are not a scale shared across vendors, so an effort setting
only compares within one family's ladder.** Kimi's `low` spends ~500–2,000
reasoning tokens on a judge packet where GLM 5.3's `low` spends ~13,000 — a
stepped-pair rule (an advisor one effort below the builder) is meaningful
only within one vendor.

**On the `claude` runtime the effort field is not spent at all.** TensorX's
Anthropic-compatible endpoint ignores the effort field Claude Code sends for
every model (teomach-cockpit#288), so on Claude Code a TensorX model always
runs at its default, which is max — the reason the GLM rows above read "the
model's default".

**When the GLMs get lane work is also the ruling (#445): by the tier's role
and the ticket's shape, not by feel.** Flash for tickets whose definition of
done is mechanical — docs syncs, test additions, a well-specified fix with a
suite that proves it, throwaway probes where a miss costs a cheap round
rather than a design; GLM 5.3 for Opus-shaped build tickets once Flash lanes
have merged with round counts comparable to Claude's, the journal being the
instrument; Claude and codex keep the judgement-heavy work the Fable rows
above already name. Kimi K3 stands as the third frontier voice beside Fable
and `astra` for the hardest collaborative work.

**What the ruling does not settle, named so it is not mistaken for
settled:** whether Flash's in-line judge reads are as sharp as Sonnet's, and
what a GLM lane costs end to end — both read off the next flight's journal,
and neither measured for #445.

- **In a session:** pick the model before invoking the skill (`/model`, or the
  launch flag). The tier table above is the lookup.
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
  reaches it no other way — no `/model`, no frontmatter. The codex table above
  is the lookup; unpinned, the lane flies the box's `config.toml` model where
  it names one and the client's own default otherwise — neither of them a
  choice this page made.
- **On an opencode runner:** the tier is `--model <id>` on the `opencode run`
  line and the effort a separate `--variant <v>` beside it; the Gemini table
  above is the lookup. Unpinned, a lane takes opencode's own stored state,
  which is invisible in the command you typed — measured in
  `docs/cross-model.md` (teomach-cockpit).
- **On a TensorX id:** the `claude` runtime takes the id as the TensorX table
  above writes it — `--model moonshotai/kimi-k3` — pointed at the endpoint by
  the cockpit's wiring. opencode takes the same id behind a `tensorx/` prefix,
  with effort a separate `--variant` beside it as in the bullet above.

## Effort per carrier — potency per unit of allowance

**Two of the four carriers are subscriptions, and on a subscription the
dollar column is the wrong one.** Claude runs on a Max 20× plan and codex on
ChatGPT Plus: the marginal dollar is zero until the plan's window closes, so
what a task costs there is the allowance it draws, and the only proxies an
external board offers for that are its output tokens and its steps. TensorX
and Gemini are metered, and there the dollar column applies. **How much
allowance one output token draws is not established on either plan, and it
may differ by model** — the token column ranks models on a subscription only
if the plan meters tokens model-blind, and nothing on this page has measured
that; input and cached tokens, retries and the window's reset are outside the
proxy altogether. Every subscription cell below is a decision taken on that
proxy under that uncertainty, and the one measurement that would settle it is
the same task run once per model on each plan with the plan's own usage
readout taken before and after.

**The external instrument is the DeepSWE leaderboard** — Datacurve,
`https://deepswe.datacurve.ai/`, v1.1, 113 tasks, updated 2026-09-03, read
2026-09-21, every model run on mini-swe-agent: long-horizon software-engineering
tasks scored pass@1 with a confidence interval, beside average API-list cost,
output tokens and agent steps per task. The transcription this page cites is
on teomach-skills#472. **It measures one shape of work — a lane building
against a coding task — and none of the others this page routes**: doctrine
authoring, the audit disciplines, prose, the judge's packet read and the
leader's dispatch judgement are not on it, and a cell below that names one of
those reads "not measured" rather than borrowing a coding row. **Two rows
whose intervals overlap or touch are not ranked by this board** — it
establishes neither that one is better nor that they are equal — so where a
cell prefers one of such a pair it is choosing on tokens or on the tier's
margin under uncertainty, and says which. The board's Fable row is `claude-fable-5`, not the
`claude-fable-5-1` this page pins; its Gemini pro row is the only effort it
carries for that model; nothing local is on it.

**The estate's journal is the second instrument, and it measures the judge's
two layers, never the lane's builder.** `~/.local/state/teomach/flight-journal.tsv`
names the reviewer on every row and the coverage model since 2026-08-30, and
carries no column for the model that built the diff, for its effort, or for
token counts. So the reviewer and coverage cells below are journal-measured on
our own material and the journal wins where the two instruments disagree; the
lane cells rest on the board alone, and say so.

**The tier stays the level of expertise the work needs (#423); this table
says which rung and effort serve it on each carrier.** It binds lane work — the
shape the board measures. A seat that is not a lane (a critic, a reviewer, a
prose draft) takes its tier from the recommendations and its effort from the
carrier's own rows in "How to apply a recommendation".

| Tier | Claude — Max 20×, by allowance | codex — Plus, by allowance | TensorX — metered | Gemini — metered |
|---|---|---|---|---|
| **Fable** | Claude Fable at **`high`** for a build-shaped lane, `xhigh` where the leader wants the margin; `max` not on the strength of this board. The tier's own work — doctrine, audit, forensics — not measured, and the box's default effort stands there | `gpt-6-astra` at **`high`** for a build-shaped lane; other Fable-tier work not measured | Kimi K3 at the model's default (#445) | *(no rung — #406)* |
| **Opus** | Claude Opus at **`high`**, dispatched `-m claude-opus-5`; `medium` is the same-token swap for a tight window | `gpt-6-astra` at **`medium`** | GLM 5.3 at the model's default (#445) | Gemini 3.1 Pro flies as a measurement lane, not a default, until a lane here has measured it (#406 keeps it a lane option) |
| **Sonnet** | Claude Sonnet at the box's default effort for the templated work the tier names — not measured, no change; a build-shaped Sonnet-tier ticket goes to Opus at **`low`**, or to GLM 5.3 Flash metered | `gpt-6-astra` at **`low`** for a build-shaped ticket; templated work not measured | GLM 5.3 Flash at the model's default (#445) | Gemini 3.8 Flash at `medium` — the board's cheapest route into its top band, `high` for the margin; unflown here |

**Claude — the knee is `high` on both upper rungs.** Opus: `max` 74% ±4 at
118k output tokens, `xhigh` 73% ±3 at 92k, `high` 73% ±2 at 64k, `medium` 69%
±1 at 37k, `low` 58% ±2 at 20k. The three rows down to `high` overlap, so `high`
is the lowest effort the board does not separate from `max`, at 54% of `max`'s
tokens; `medium` spends 37k against `high`'s 64k for a pass rate the board
does separate from `high`'s, 68–70 against 71–75. Fable-5: `max` 70% ±4 at 119k, `xhigh` 70% ±3 at 80k, `high` 69% ±1 at
57k, `medium` 65% ±4 at 40k, `low` 60% ±3 at 25k — `max` is half again
`xhigh`'s tokens for a pass rate the board does not separate, `high` is
inside `xhigh`'s interval at 71% of its tokens, and `medium` (61–69) touches
`high` (68–70), so the Fable cell's `high` over `medium` is the tier's margin
rather than a separation the board makes. **No Fable-5 row passes more
than Opus `high`, and every Fable-5 row that spends fewer tokens than Opus
`high` — `high` at 57k, `medium` at 40k, `low` at 25k — also passes less**:
69% ±1, 65% ±4, 60% ±3 against 73% ±2. So on this board a build-shaped lane
has no row that rewards running Fable, and the Fable tier keeps its cell for
the work the tier names — doctrine, audit, forensics — which the board does not
measure and which the pinned `claude-fable-5-1` is not on it for at all. What
this changes on the box: a Claude lane dispatched without `-m` takes the box's
default, `claude-fable-5-1[1m]` at effort `medium` in `~/.claude/settings.json`
as read 2026-09-21, which the Fable-5 `medium` row prices at 65% ±4 for 40k
where Opus `medium` reads 69% ±1 for 37k. An Opus-tier lane is therefore
dispatched `-m claude-opus-5` at `high`, and a Fable-tier lane names its
effort on the dispatch line rather than inheriting the box's — an operational
change, and a decision under the proxy rather than a measured finding.

Sonnet: `max` 54% ±4 at 214k, `xhigh` 50% ±3 at 121k, `high` 48% ±5 at 87k,
`medium` 40% ±3 at 57k, `low` 31% ±1 at 36k. Opus at `low`, 58% ±2 at 20k, is
separated from every Sonnet row but `max`, whose 50–58 touches its 56–60, and
Sonnet `max` spends 214k for it — on a subscription the smaller model is the
dearer one for this shape of work, by the token proxy, at every effort. The tier's own work is not on the board, so the Sonnet cell stands for
it, and the routing of mechanical tickets to GLM 5.3 Flash (#445) is
supported: 63% ±4 at $0.24 metered against Sonnet `max`'s 54% ±4. **The
Opus-at-`low` cell is a decision under the proxy, and the number the
allowance measurement has to return to unseat it is a weighting above 1.8× —
36k against 20k** — and even that is a break-even on tokens per attempt, which
undervalues a route passing 58% against 31%: the re-read is on completed work
per unit of allowance, not on tokens alone.

**codex — one model for lane work, with effort carrying the tier's weight.**
astra: `xhigh` 74% ±3 at 30k, `high` 73% ±3 at 27k, `max` 73% ±1 at 61k,
`medium` 73% ±3 at 20k, `low` 67% ±1 at 11k. sol: `max` 73% ±3 at 60k, `xhigh`
71% ±1 at 41k, `high` 69% ±1 at 28k, `medium` 61% ±2 at 18k, `low` 45% ±2 at
11k. terra: `max` 70% ±3 at 72k, `xhigh` 60% ±2 at 40k, `high` 54% ±4 at 22k,
`medium` 35% ±3 at 12k, `low` 24% ±1 at 8.6k. luna: `max` 67% ±4 at 73k,
`xhigh` 57% ±2 at 45k, `high` 44% ±3 at 26k. On a Plus carrier there is no row
where sol, terra or luna beats astra at a lower effort on both columns: astra
`medium` is inside sol `max`'s interval at a third of its tokens, and astra
`low` is inside terra `max`'s and luna `max`'s at a sixth of theirs. So **on
Plus a codex lane at any tier runs `gpt-6-astra`, and the effort carries the
tier's weight**: `low` for a Sonnet-shaped ticket, `medium` for an Opus-shaped
one, `high` for a Fable-shaped one — the last by the tier's own margin rather
than by measurement, since the board does not separate `medium`, `high` and
`xhigh` (20k, 27k, 30k), and choosing the lower of them is choosing fewer
tokens under that uncertainty. `max` spends 61k for a pass rate the board does
not separate from `medium`'s at 20k; `low` is a separated drop; and astra's
shipped default is `low`, so the effort rides the dispatch line as
`-c model_reasoning_effort=<v>` on every codex lane. That moves the codex
default for new tasks (#404) from sol to astra at `medium` for lane work;
sol and terra stand as the rungs a metered codex credential would reach for by
tier, and codex work the board does not measure — a critic seat, prose — is
not moved by it. luna earns no rung: its only edge is API-list price, which
Plus does not meter, and its tokens equal terra's. The fallback reviewer on sol
at `high` (#445) is a packet job the board does not measure. **Whether Plus
meters astra's tokens at the same rate as terra's is the unmeasured half of
every cell in this column.**

**Metered — the dollar column, and where the board challenges a pin.** TensorX
rows: Kimi K3 `max` 69% ±5 at $4.65, GLM 5.3 `max` 69% ±3 at $3.99, GLM 5.3
Flash `max` 63% ±4 at $0.24. Gemini rows: 3.8 Flash `high` 74% ±1 at $2.36 and
`medium` 71% ±2 at $1.97, 3.1 Pro `high` 12% ±1 at $2.14. The Flash cell is
supported: of the rows passing 60% or better, none passes more per list dollar
— the rows that do, luna `high` at 44% ±3 for $0.16 and luna `medium` at 11% ±1
for $0.04, are under the floor a lane can be dispatched at. The Opus cell is
challenged: Gemini 3.8 Flash at `high` shares the board's top band (74%, with
astra `xhigh` and Opus `max`, none separated) and its `medium` row (69–73)
touches that band at $1.97, 49% of GLM 5.3's $3.99, so a metered Opus-tier
lane has a cheaper candidate than its ruled rung (#418), and neither has flown
a lane here — the first lanes on each settle it, and at 125k–143k tokens and
147–166 steps a task the Gemini rows are the longer tab. Gemini 3.1 Pro's 12% is the board's measurement of it as a lane
runner and the only one this page has; as the reviewer it is journal-measured
on a different job, below, and its place in the reviewer order (#418) stands.

**The reviewer and coverage cells are journal-measured, and the counts are
counts — the journal records verdicts, not whether a finding was right.** Kimi
K3 on opencode after the `low` effort landed (teomach-cockpit#283, merged
2026-09-18T22:30Z; the journal carries no effort column, so the assignment is
the merge's, not the row's): 62 rows to 2026-09-21T10:52Z — 35 PASS, 18 FAIL,
8 NOT-CHECKABLE, 1 ERROR, no NO-ANSWER — at a median independence cost of
$0.09, range $0.05–0.60. The Gemini pro rung over its 777 opencode rows: 398
PASS, 237 FAIL, 129 NOT-CHECKABLE, 12 NO-ANSWER, 1 ERROR, median $0.13. FAIL over rows
reads 29% against 30%; **whether either rung's findings were accepted is a
disposition the journal does not hold, and comparative review quality is not
established by it.** Coverage on GLM 5.3 Flash: 102 rows, median $0.063, mean
$0.086 — the population since the pin, where the $0.10–0.30 in the ruling's
table above is teomach-cockpit#297's one measured run; on Claude Sonnet before it, 901 rows, median $1.82, mean $2.17 — the
allowance the pin (#424) stopped spending, at the list rate the journal
records for a subscription row. Whether the Flash read is as sharp as Sonnet's
is **not established**: the two populations judged different diffs.

**The leader's effort is `medium`, as run, and not measured.** The board's
Fable-5 rows put `high` four points over `medium` on a build task, 69% ±1 at
57k tokens against 65% ±4 at 40k; the leader's output is prompts and triage
rather than a build, so the row is not the leader's, and the setting stands
until an instrument shaped like the leader's work exists.

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
