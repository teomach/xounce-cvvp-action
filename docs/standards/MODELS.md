<!-- Source: teomach-skills MODELS.md @ 081f321 —
     rendered at guard-set v12 by scripts/wire-repo.py; edit it at source and
     re-run `scripts/wire-repo.py update`, never edit this copy. -->

# Models — which tier runs which skill

Recommendations, not enforcement: the tier named here is the one a session
**running that skill** should reach for, judged by the hardest thing the skill
routinely does. Re-derive when a pack changes shape; a table like this rots
exactly the way `pack-shapes.md`'s counts do.

## The tiers, and what each is for

| Tier | Reach for it when |
|---|---|
| **Sonnet** | The skill is templated and well-guarded — scaffolding, filing, structured recording. The skill carries the judgement so the model doesn't have to. |
| **Opus** | Real drafting and build work — most orchestrators that write artefacts a human will read or merge. The estate default. |
| **Fable** | A subtle miss is expensive — forensic diagnosis, doctrine authoring, threat models, seam/architecture judgement, anything that reruns in every future session if wrong. |
| **Gemini Pro** | A cold read from a **different model family** — the review disciplines name this as the runner, because a model auditing its own family's output is blind to its own tells. |
| **ablated Qwen** | Local (Lemonade), for work a hosted model refuses or waters down. No skill wants it as the primary today; it appears as an adjunct (attacker-path enumeration in `threat-model`). |

**The ids the tiers mean, and the reason to write them out.** Sonnet is
`claude-sonnet-5`, Opus is `claude-opus-5`, Fable is `claude-fable-5`, and the
cross-family reviewer is `gemini-3.1-pro-low`. **Always the full id, never the
short alias** — probed on this box against Claude Code 2.1.212, `sonnet`
resolves to `claude-sonnet-5` but **`opus` resolves to `claude-opus-4-8`**, one
generation back, silently and with no warning. An alias is a promise the CLI
keeps on its own schedule; a pinned id is the one we chose.

**`gemini-3.1-pro-low` is right for the runtime we use it on and nowhere
else.** It is an **Antigravity id**, model and reasoning effort fused into one
string, and `agy models` lists it — so the pin is valid today, because `agy` is
what the cross-model reviewer runs on. It is not a Google API model id and it
does not exist in opencode, whose list carries `google/gemini-3.1-pro-preview`
with effort as a separate `--variant low` flag (both lists measured 2026-08-03).
The pin therefore becomes invalid the moment the reviewer moves off `agy`, and
that move is already sequenced.

**Effort, not family, is where the cost came out — and the reason is that the
cross-model reviewer was never the expensive half.** Measured across the flight
of 2026-08-02/03, independence cost **$0.27–$0.43 on every run** while the
in-family Sonnet coverage ran **$0.82–$5.78**. On the lane that spent ~$26 over
five runs, the cross-family reviewer was about **$1.90 of it**. So the pin is
chosen for **judgement quality and reliability**, and only then for price:
dropping `gemini-3.1-pro-high` to `-low` keeps a pro-tier model on the one job
where the reviewer exists to catch what the in-family checks missed, and lower
effort also shortens the runs that were **timing out** — three consecutive
times on `-high`, at exit 124 with zero tokens in and out after 299 seconds.

**Where the money actually is, so this pin is not mistaken for the fix:** the
in-family half runs on a Claude subscription, so it spends the allowance without
ever printing a bill. That is the harder cost to see and the bigger one, and it
is tracked as its own work rather than solved here.

**A reviewer that never dissents is as useless as one that never answers, and
both used to read the same in the summary line.** They no longer do: every judge
report names the independence layer's own outcome on its own line, and the
flight journal (`~/.local/state/teomach/flight-journal.tsv`) carries it as a
`cross_verdict` column, so the dissent rate is a `cut` away rather than a
reconstruction from merged PR bodies. The baseline for judging this pin: on
that flight the cross-model reviewer raised findings accepted on two PRs and one
that a third PR rebutted with evidence. If several consecutive runs pass with no
dissent, move. `gemini-3.6-flash-high` is the cheaper fallback — the 3.6 family
is **flash-only**, `agy models` lists no 3.6 pro, so it trades tier for price
rather than effort, and its rates were read on 2026-08-03 as **$1.50/M input,
$7.50/M output, $0.15/M cached, with no 200k tiering**.

## The codex family — the same ladder, a different runtime

The tier a piece of work needs does not move with the runner; the id it
resolves to does. `codex exec` flies from the cockpit both as a lane runner and
as an option for the cross-model reviewer, and an invocation carrying no `-m`
takes codex's own default — so this mapping exists to be pinned against. Every
measurement behind it is `docs/codex.md` (teomach-cockpit), probed on
codex-cli 0.149.1 against a ChatGPT **Plus** credential; this page carries the
mapping and cites rather than restates the probe.

| Tier | codex id | Basis |
|---|---|---|
| **Fable** | *nothing this credential serves* | Measured: `gpt-5.6-pro`, `gpt-5-pro` and `o3-pro` are each refused. |
| **Opus** | `gpt-5.6-sol` | Judgement: the family's frontier model, and codex's own `exec` default. |
| **Sonnet** | `gpt-5.6-terra` | Judgement: the everyday model, one rung under the frontier. |
| *(no rung)* | `gpt-5.6-luna` | Judgement: cheaper and faster than `terra`, and this ladder has nothing under Sonnet, so nothing routes to it. Named so it is not mistaken for the middle of three. |

**The ranking is judgement because both instruments that settled the Gemini pin
are missing here.** There is no price to compare: the credential is an OAuth
ChatGPT session rather than an API key, so a run prints no cost field at all and
the flight journal's `independence_usd` is empty on every codex row. And nothing
has ranked these three against each other — the probe was synthetic throughout,
and the runs against real material were all pinned to `gpt-5.6-sol`. What
the ranking rests on is codex's own registry, read from
`~/.codex/models_cache.json`, where `sol` is the frontier model, `terra` the
balanced everyday one and `luna` the fast and affordable one, and the default
effort each ships with says the same (`sol` low, the other two medium).
Displace it the day a codex lane produces evidence either way.

**The empty Fable row is a finding, not a gap in the table.** No pro-tier id is
offered to this credential, so the rung has no runner here at all, and the
forensic skills that want one — `diagnose`, `reverse-engineer`, `threat-model`,
`new-pack` — cannot fly codex on the tier they ask for. Route them elsewhere
rather than one rung down quietly.

**Dispatch spells the choice `-m <id>`** on `codex exec`'s own command line, so
a cockpit extending its `-m` flag to codex lanes has ids to cite from here.
Unpinned, a lane flies `gpt-5.6-sol` — the Opus rung by codex's default rather
than by anyone's choice. The trap here is not the Anthropic aliases' quiet
downgrade but a loud refusal that says nothing useful: **an unentitled id and a
misspelt one come back in the same sentence**, differing only in the quoted
name, so a pin that rots reads exactly like a typo. The check is a registry read
before dispatch, and the registry is fetched per account — it answers for this
credential, not for the family. Four of the eight slugs it lists are not tier
candidates: `gpt-5.4` and `gpt-5.4-mini` carry retirement notices, and
`gpt-reserve` and `codex-auto-review` are marked `hide`.

**Effort is a second setting, spelled `-c model_reasoning_effort=<v>`, and it
lands.** A run carrying it records `reasoning_effort` in codex's own thread
store where a run without it records nothing, and an unrecognised value is
refused outright with the server naming its enum — the opposite of opencode's
`--variant`, which accepts nonsense and degrades the reviewer in silence. **What
the setting does above `high` is not established.** `low` and `high` separate
cleanly on reasoning-token count; `high` and `xhigh` do not; and `ultra` is
advertised by the client, absent from the server's enum, and accepted without
complaint by something that maps it before dispatch. Pin `high` and read the top
of that ladder as unknown.

**The subscription's economics are not established either, and that is why no
codex tier here can be defended on price.** Quota is the only axis, it is
reported at one-percentage-point resolution and only into the on-disk
transcript, and what exhaustion looks like was never measured. The cost
arithmetic this page does for the Gemini pin cannot be repeated for codex.

**None of this settles which runner the judge stands on.** The cross-model pin
is still `gemini-3.1-pro-low`; codex is wired as an alternative and has flown
three times on `gpt-5.6-sol`, answering on every one and returning a FAIL of its
own each time. Three runs is a promising start and not a case for moving a pin —
the argument that moves it is the dissent-rate one above, and it wants more runs
than three.

## How to apply a recommendation

- **In a session:** pick the model before invoking the skill (`/model`, or the
  launch flag). This table is the lookup.
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
  is the lookup; unpinned, the lane flies `gpt-5.6-sol`.
- **Gemini Pro and ablated Qwen** are not frontmatter-expressible — they are
  "run the skill there" choices: `package-for-chat.py` output for Gemini, the
  Lemonade endpoint for Qwen.

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
| `review` | **Gemini Pro** | Audit mode requires a different model family by the kernel's own independence rule; the per-PR self-check simply runs in whatever model built the diff. |
| `verify` | **Sonnet** | Run-the-thing-and-quote-the-output discipline — the skill carries the rigour; the hard judgement lives in the work being verified. |
| `diagnose` | **Fable** | Forensic root-cause work (incident mode included); a subtle miss ships a symptom fix wearing a different shirt. |
| `research` | **Opus** | Judging source authority and following every claim to its primary owner; a guess is the skill's named failure mode. |
| `docs` | **Sonnet** | Docs derived mechanically from diff + ticket + spec under a strict same-PR rule; the hard judgement lives in review and the spec. |
| `handoff` | **Sonnet** | Structured compaction under the honesty rule — a guarded template, little open reasoning. |
| `threat-model` | **Fable** | Design-time security reasoning where a quiet miss becomes an incident; ablated Qwen adjunct when attacker-path enumeration needs unwatered depth. |
| `reverse-engineer` | **Fable** | Forensic archaeology where missing a load-bearing accident is the costliest miss in the kernel; discovered behaviour is evidence, not requirement. |
| `prose` | **Opus** | Drafting real prose to the register — strong general drafting under a lodestar, with the hard MT checks greppable and mechanical. |
| `new-skill` | **Opus** | Template- and linter-guarded, but axis placement and trigger prose need real drafting judgement. |
| `method-review` | **Gemini Pro** | The method's reflexive audit wants a cold read by a different model family; a forensic audit of our own method needs an outside validator as the runner. |

## digital-services

| Skill | Tier | Why |
|---|---|---|
| `process-definition` | **Opus** | Modelling a real human process into schema-valid stages, routing, and validation criteria — schema-guarded but judgement-heavy. |
| `service-health` | **Opus** | Evidence-led entropy sweep with design judgement; the deep forensic passes are explicitly delegated to kernel `review` audit mode. |
| `strangler-fig-migration` | **Fable** | Cutover and backfill sequencing where a subtle miss is data loss or an untested fallback in production. |
| `validate-with-users` | **Sonnet** | Templated session planning and verbatim recording with explicit status states; the skill carries the discipline. |
| `django-service` | **Opus** | Strong build work under heavy, explicit guardrails — the profile pre-decides most architecture; kernel `review` supplies the Gemini Pro cold read separately. |
| `n8n-service` | **Sonnet** | Pure-workflow wiring against an agreed process definition — templated, well-guarded work. |
| `bespoke-service` | **Fable** | Instantiating a stack profile authors the rulebook every later session obeys — bake-offs, carve-out mapping, scanner-set design for an arbitrary ecosystem. |
| `platform-service` | **Fable** | Seam and trust-boundary architecture, contract design, and seam-ledger judgement on inherited systems — exactly where a subtle miss is expensive. |

## board-games

| Skill | Tier | Why |
|---|---|---|
| `setup-game` | **Sonnet** | Templated scaffolding from provided assets; a short configuration interview with hard fixtures — little judgement left open. |
| `capture-design` | **Opus** | Extracting unarticulated design intent via concrete forks, and knowing facts-vs-decisions and when capture is done, is real interviewing judgement. |
| `implement-target` | **Opus** | Real build work across the target stacks, conformance-test-first; the target profiles ride as references. |
| `design-review` | **Gemini Pro** | The skill itself demands audit mode run in a different model family, cold; per-change/per-build self-checks run inline in the building session's own tier. |
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
| `estate-review` | **Gemini Pro** | Audit mode wants a different model family by the kernel's independence rule; the frontmatter's `claude-opus-5` is the in-family fallback that fires on model invocation. |
| `software-review` | **Gemini Pro** | Same shape as `estate-review`: cross-family for the audit-grade run, the frontmatter Opus pin as the in-family fallback. |
| `ai-review` | **Gemini Pro** | A review of our own AI approach is the clearest case for an outside family; the frontmatter Opus pin is the in-family fallback, and half the register is settled by running commands, not by tier. |

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
| `pack-review` | **Gemini Pro** | The skill's own doctrine demands a cold read by a different model family; a forensic audit of our own method wants an outside validator as the runner. |
