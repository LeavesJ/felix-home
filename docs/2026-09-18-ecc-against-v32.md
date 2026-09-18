# ECC against v3.2, read at source 2026-09-18

What ECC's best-known skills can and cannot do for the v3.2 state, measured
against `felix_v32_architecture_spec.md`, the conformance amendments and
`docs/2026-09-17-v32-distance.md`.

**How it was measured.** ECC 2.2.1 at `e04ea0b` (the sha in
`~/.claude/plugins/installed_plugins.json`; the cache has no `.git`), read by
four read-only agents, one per cluster, each forbidden to run any ECC script,
the suite or the gate, and each required to cite `path:line`. The
load-bearing claims below were then re-read by hand; those are marked
**checked**. Everything else is a reader's report and carries that weight.
ECC paths are relative to `~/.claude/plugins/cache/ecc/ecc/2.2.1`.

The memory entry of 2026-09-02 asked whether to mount ECC. That question is
closed: a person installed it on 2026-09-03. This document asks the next one.

## 1. The spec already gave ECC a job, and the engine has not hired it

v3.2 names ECC three times, and each time in the same role:

- §1, Discovery Workers "use host reasoning, **ECC**, setup skills, domain
  expertise, standards, or independent models to propose candidate
  obligations. They cannot write blocking state" (spec:59).
- §9, the Baseline Coverage Compiler's first listed source is "ECC /
  engineering methodology provider" (spec:346).
- §7, "Felix owns capability need, provider trust, installation, scope,
  activation, and revocation. It does not need to own ECC's or another
  provider's internal semantic procedure" (spec:302).

So ECC is a **content provider and a discovery worker**: it proposes, it never
decides. Now the engine's side. The one place a model proposes obligations is
`templates/commission/obligations_surveyed.md`, and its instruction is
"Propose engineering obligations this product owes that nobody named". It
names no source to consult. The row that carries it reads
`provider:felix:obligations`, and `docs/2026-09-16-discovery-baseline-design.md`
says why: the template is the worker's prompt, so the worker is `felix`
(:56-60), and corroboration is deferred by name (:33).

That is the gap. The compiler in spec §9 is `projection -> providers ->
candidates`. The engine built `projection -> host reasoning -> candidates`.
The host is the party that dropped rate limiting three times.

## 2. The canonical omission is in ECC's text — checked

`skills/security-review/SKILL.md` activates on "Creating new API endpoints"
(:16) and its checklist reads "Rate limiting on all API endpoints" (:303) and
"Stricter limits on expensive operations" (:304), repeated before deploy
(:484). `skills/deployment-patterns/SKILL.md:420`: "Rate limiting enabled on
public endpoints". All four lines **checked**.

Had that file been a named source when a public route appeared, a candidate
would have existed. Two limits, both the reader's and both matter:

- ECC never states the conjunction the north-star case turns on. "Paid"
  appears in neither file; the nearest is
  `skills/cost-aware-llm-pipeline/SKILL.md:170`, "Set explicit budget limits"
  (**checked**). ECC supplies the proposition. `applicability_predicate:
  public AND paid` and `failure_mode: uncontrolled_cost` are Felix's to write.
- The second corpus case, an RLS change after green auth tests, is not in ECC
  at all. It was never going to be: that is receipt invalidation, which is the
  Evidence Kernel's and already runs (amendments §5).

Coverage of the spec §14 corpus by ECC's text, from the reader:

| corpus item | ECC states it | shape |
|---|---|---|
| rate limit on public endpoint | yes, four places | checkable proposition |
| auth required or marked public | `skills/api-design/SKILL.md:519` | checkable |
| RLS on multi-tenant tables | `agents/database-reviewer.md:85` (**checked**) | checkable |
| RLS change reopens auth | no | — |
| migration has UP and DOWN | `skills/database-migrations/SKILL.md:32` | checkable, its cleanest section |
| health check proves dependencies | `skills/production-audit/SKILL.md:109` | a question, needs restating |
| rollback documented and tested | `skills/deployment-patterns/SKILL.md:425` (**checked**) | checkable |
| critical flow tested end to end | `skills/production-audit/SKILL.md:141` | "critical" undefined |
| webhook signature and idempotency | `skills/production-audit/SKILL.md:100` | checkable |

**ECC's text is not machine-addressable, and that decides the design.** 243
of 286 skills carry a `## When to Activate` or `## When to Use` heading and 31
carry `- [ ]` checklists (both counts **checked**). The "when" bullets are
activities ("Creating new API endpoints"), not topology facts. Nothing in ECC
maps a predicate Felix can observe to a sentence that must hold. The only
machine-readable predicate in the plugin is the `paths:` glob on 111 `rules/`
files. So the mapping from grounded predicate to provider text is a table
Felix owns, which is what the constitution says an extension point is.

## 3. The flagship skills, one verdict each

"Produces" means a machine-readable artifact bound to a git tree. A model
typing PASS is MODEL_CLAIM (spec:432) and can discharge nothing.

| skill | what it is | produces | for v3.2 |
|---|---|---|---|
| `verification-loop` | prose; a report the model fills in | nothing. Its commands pipe to `tail` (:26, :57, **checked**), which discards the exit status — the trap this constitution's Delivery section exists for | nothing. The gate is already the measured version of it |
| `eval-harness` | prose; the directory holds one file (**checked**); "Evaluate" is a placeholder and pass@k is typed by the model | nothing | vocabulary only. The spec §14 corpus needs a runner and this is not one |
| `tdd-workflow` | prose, but it prescribes a RED commit then a GREEN commit (:72-84, **checked**) | the one tree-bound artifact in the flagship set | a replayable witness: see §5.3 |
| `continuous-learning-v2` | hooks capture every tool call; a disabled background Haiku would distil "instincts" | see §4: it is capturing now and nothing reads it | its data model, not its mechanism: §5.4 |
| `strategic-compact` | a counter hook that injects a suggestion at 50 tool calls | chat | nothing, and it breaks stealth in the middle |
| `security-review` | checklists | text | the best content source in the plugin: §2 |
| `security-scan` | wraps AgentShield through a bare `npx ecc-agentshield`; the scanner is not in the plugin | terminal, JSON, a grade; exit 2 on critical, per its README | a raise-only reader is feasible and is T3 until vendored and pinned. It needs network and runs third-party code, so it waits on the same grant Docker does |
| `santa-method`, `council` | separate subagent contexts, one model, one shared rubric; the reviewers see the artifact | chat | an independent challenge for B2/B3. Not a blind author: nothing is derived without sight of the thing judged. `commands/santa-loop.md` pushes on the model's verdict, which invariant 6 forbids |
| `canary-watch` | an eight-item checklist; no script, no tool | chat | the list is good content for the post-deploy probe Felix has to write itself (step 4, ABSENT) |
| `skill-comply` | the one real runner: drives `claude -p` in a scratch directory and records the tool-call trace | a markdown report, no exit code; the spec and the labels are model-written, three scenarios, one run | the right shape for spec §7 step 5, "provider smoke/eval", and not reproducible enough to be a receipt |
| `spec-miner` (agent) | mines `Requirement` blocks with `enforced:` and `test:` anchors | `openspec/specs/*/spec.md` | it cannot find an omission ("If the code enforces something, it goes in the spec", :84, **checked**). It is the *enforced* side of a relation whose *expected* side is §2's content |
| reviewer agents | prompts run in a fresh context | chat | measured last session: `silent-failure-hunter` and `code-reviewer` found defects the blind assertions could not. Reached twice, named by no route |

The pattern is one sentence. **ECC's mechanisms are prose that asks a model to
grade itself, and ECC's content is what two people and a model keep
forgetting.** v3.2 has no use for the first and a named slot for the second.

## 4. What ECC's runtime does beside Felix, in every session

Twenty-three hook entries across seven events (**checked** against
`hooks/hooks.json`). The reader's full table is in the session transcript;
these are the rows that touch v3.2.

**GateGuard reads nothing.** It is sold as a fact-forcing gate. On the first
touch of a file it writes the key and denies; the retry passes because the key
is now present (`scripts/hooks/gateguard-fact-force.js:1217-1228`,
**checked**). No message, transcript or counter is consulted, so a bare retry
with no facts passes too. Felix's Stop hook refuses to read narration because
a gate a model can talk past is not a gate (amendments §5); this one does not
need talking to. Subagent edits skip it entirely (`isSubagentInvocation`,
:1146-1154, **checked**), so it gates the main session and nobody else. The
one-in-three denial in parallel batches is, by the reader's inference and not
by reproduction, an unlocked read-merge-rename in `saveState` (:831-856)
losing a sibling's key. It had refused five calls in this session by the time
this file was written, this file among them. Its destructive-verb match scans
command text, prose included, which is the same defect §0bl recorded against
Felix's own deny rows.

**Five blocking points sit outside obligation state.** GateGuard,
`block-no-verify`, `config-protection`, `mcp-health-check` (which probes over
HTTP on every tool call and can refuse any of them) and `plan-canvas-pending`
(which can block a Stop). v3.2 computes a hold from obligations and receipts.
These are holds with no obligation, no receipt and no record Felix can read.

**One hook rewrites the tree at Stop.** `stop-format-typecheck.js` runs the
formatter with `--write` over edited files (:82-84, **checked**). Inert in a
bash engine. In a TypeScript product it changes the tree after the gate judged
it, and every receipt is keyed to the tree. Hook order across plugins is not
something Felix controls.

**Capture with no reader.** Observation is live: 17 MB under
`~/.local/share/ecc-homunculus`, up to 5000 characters of each tool input and
output (`skills/continuous-learning-v2/hooks/observe.sh:238-243`,
**checked**), 4.1 MB for this project alone by the reader's count. The
observer that would read it ships disabled; there are zero instincts.
`~/.claude/bash-commands.log` and `cost-tracker.log` are 13.9 and 14.4 MB
(**checked**), unrotated, and the reader found nothing that reads them.
`session-end.js` copies the first 200 characters of each user message into
`~/.claude/session-data/` and may call Haiku.

**The switch exists and is clean.** `ECC_HOOKS_ENABLED=false` turns off every
hook (`scripts/lib/hook-flags.js:65-73`, **checked**) and touches no skill,
agent or command, because those are not hooks. Nothing sets it today. It is a
line in the founder's own user settings, so it is the founder's to set; a
narrower list of hook ids is in the reader's report if some should stay.

## 5. What this says to build, in the spec's build order

Each item is bash and git on the enforcing path. The model only ever writes an
answer file, which is the one legal surface (invariant 2).

### 5.1 The coverage table — step 6 and 7, and admission pathway 3

The highest-leverage change, and the one the north-star eval needs first.

- A per-project `coverage.tsv`, seeded by a template: `predicate <TAB>
  provider <TAB> path`. "When this grounded predicate is found, this provider
  text is the baseline to read." ECC's rows are data: a public route reads
  `security-review`, `deployment-patterns` and `api-design`; a paid model path
  reads `cost-aware-llm-pipeline`; Postgres reads `database-reviewer` and
  `database-migrations`. ECC is a row, never a name in the engine.
- The request gains a sources section: for each predicate a probe found, the
  provider files resolved in the plugin cache, with the registry's
  version and sha and a content digest of each file taken at request time.
  ECC changes weekly and only 30 of its 286 skills carry a version of their
  own, so the digest is the only honest identity for a sentence.
- The answer row gains a source field: provider, path, line and the quoted
  words. **The engine verifies it offline**: the file is at that digest and
  the line holds those words. That turns "ECC says so", a MODEL_CLAIM, into a
  reference bash can check, which is what makes it corroboration and not
  decoration.
- A row whose grounds are a found predicate and whose source verifies is
  stamped `corroborated` by the engine, never by the model. Spec §4 pathway 3
  makes that task-blocking by default. Admission stays a person's commit.
  A citation that does not verify is refused with a reason, not downgraded,
  which is the rule `candidates.sh` already keeps.
- The fixture writes itself: a project with a public route and a paid model
  predicate, a provider text naming rate limiting, and three assertions —
  the request names the file, a cited candidate is accepted as corroborated,
  a miscited one is refused.

### 5.2 Trust is per surface, not per plugin — step 5

`felix toolbox` holds ECC as one row: risk high, capability `ci`, reachable by
no route. That row is right about the hooks and wrong about everything else,
and it is why no route could name `ecc:silent-failure-hunter`, which is a
prompt. ECC is four things: text (T1 once pinned by digest, because reading is
the whole interaction), agents (prompts in a subagent context), hooks
(executable in every session: SOURCE_INSPECTED, and a person's grant), and an
MCP server fetched through `npx` at latest (T3). The distance table's step 5
row says the registry has "no per-provider record of tier, scope or activation
state". The record it needs is per provider **and surface**. ECC is the
instance; any plugin that ships both prose and hooks is the class.

### 5.3 A red and green pair as accepted evidence — step 3

`tdd-workflow` has the host leave a commit where a named test fails and a
later one where it passes. `tests/red` (#255) already runs a suite at a base
ref in a detached worktree. Replaying one test at two shas is the same
machinery and yields LOCAL_MEASUREMENT: violation and restoration, controls 1
and 2 of amendments §2.1, for free on every fix. It is one `accepted_evidence`
alternative, which is the field the distance table says evidence contracts
lack. The host owns the method; Felix owns the replay.

### 5.4 Lessons get a count — step 7's "historical miss rate"

Spec §10 makes discovery depth a function of historical miss rate, and Felix
has no such number. Last session wrote two lessons that already existed and
annotated three by hand as "recurring". The instinct record has the fields:
an evidence count, a last-seen date, demotion on contradiction, idle decay,
and promotion from project to global only when the same entry appears in two
projects. Those are columns. The observer, the background model and the
capture are not needed for any of them.

### 5.5 Challengers as rows — step 7's budget classes

B2 is "one independent or domain-specific challenge" and B3 is "multiple
independent angles". The reviewers are the angles; a table says which one a
situation gets, off the tier `felix_classify_tier` already computes. A
challenger answers in the candidates shape and nothing else. The stop rule
then has data: the last allocated pass added no row at ADVISORY or above.

## 6. The wider point about the skill base

The ledger, read today: superpowers named 463 times across 99 sessions and
reached for 24. ECC named 0 times and reached for twice, in the one session
where a person said to use it. Naming a skill in a session's context is the
weakest thing Felix does with one, and the ledger has said so since it began
counting.

The provider protocol is the strong thing. A request names a skill, states the
shape of the answer, and the engine reads the answer offline and refuses what
does not fit. Both commissioning provider rows were answered. A skill that
matters to v3.2 should stop being a name a route mentions and become a row
with an answer shape: **routes advise, requests get answered.** That is how
the skill base is used, ECC's and everyone else's.

## 7. Not to adopt

`verification-loop`, `eval-harness`, `santa-loop`, `delivery-gate`,
`quality-gate` and `agent-self-evaluation` as mechanisms. The last scores the
words "tests pass" as tests passing and starts every axis at five out of five
(`skills/agent-self-evaluation/scripts/evaluate.py:51,55`, **checked**). Each
is a verdict without a measurement, and v3.2 exists to keep those off the
release path.

## 8. What this does not establish

Nothing here was executed: no ECC script ran, and AgentShield, `skill-comply`
and the external `agent-eval` were read about, not read. The race in
`saveState` is inferred from source. Whether Claude Code loads all 82 KB of
ECC's skill descriptions into every session was not determined. The coverage
table is a design in five bullets and has had no refuter; §0bl's method says
it gets three before it is built.
