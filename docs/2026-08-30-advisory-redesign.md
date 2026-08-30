# The advisory redesign — evidence, the night's work, and three decisions

Written overnight 2026-08-30 on the founder's directive: *"full sweep in all
relevant docs, build toward the large redesign we had last time… every
suggestion lands wrong, governance layer is broken, not to mention autonomous
engineering via skill/plugin/mcp manipulations."* Dynamic skills were named out
of scope, and nothing here touches them.

Every number below was produced by a command tonight. The records this anchors
on, so nothing is re-derived: HANDOFF §0z (the deliberation-layer architecture
and its gate), §0c (the charter correction), #58 and its comment (the registry
verdict), #29 and its five causes, `docs/2026-08-14-earned-autonomy-decision.md`
(the authority kernel), `docs/2026-08-13-ultron-federation-gap.md` §6 (the
metric correction), and the 2026-08-09 slice designs.

---

## 1. The diagnosis, measured per layer

The founder named three broken things. The sweep says they are three different
kinds of broken, and one of them is not broken at all.

### 1a. "Every suggestion lands wrong" — confirmed, and now quantified

First derivation of the follow-through baseline against the fixed instrument
(#54, deployed 0.49.7, 2026-08-25 — every earlier figure was measured against
suggestions nobody was shown and is void):

| measure | value |
|---|---|
| mandates rendered, 5 days | **11**, across 5 sessions |
| followed | **2** (≈18%) |
| declined out loud as misroutes | 2 |
| ignored silently | 7 |
| live-audited mandates that were right for their turn | **0 of 3** |
| blind-study precision (n=158, two strict judges) | ≈2% |
| recorded failure causes on #29 | **5**, sharing no fix |

The equilibrium is the worst available: when Felix asks, sessions follow ~1 in
5 — and the audited mandates were wrong, so the low follow-through is
substantially *correct* non-compliance. The channel trains sessions to ignore
it, and the occasional right mandate inherits the credibility of the wrong
ones. The old mandate language ("This is a requirement, not a suggestion") was
calibrated for a channel that is nearly always right.

What the evidence does **not** support: "Felix has no routing role." The blind
study found a real role roughly an order of magnitude smaller than Felix's
speaking volume, and half its misses were capabilities absent from the table —
both since added (#60). The role exists; the mechanism is mis-aimed.

### 1b. "Governance layer is broken" — split, because half of it is the strongest thing Felix has

The **mechanical** layer — gate, receipts keyed on tree identity, escape
channels, the Stop hold, CI at the merge boundary — is where every save this
month came from. Tonight alone it caught three things correctly: the Stop hook
refused an unverified tree, the independence check refused an engine comment
naming a governed project, and secret-scan refused a key-shaped test fixture.
Two of those three guards were hardened *this same night*, and they fired on
their own author. Nothing in this redesign touches the mechanical layer.

The **advisory** layer — the voices — was broken in the precise sense this
project keeps finding: signals claiming more than their mechanism established.
Measured over the same 5 days:

| voice | share of everything Felix said | defect |
|---|---|---|
| `subagent-unverified` | **48 of 136 (35%)** | false for every read-only subagent after a parent commit (#97) |
| `brief` mandates | 11 rendered | 2/11 followed, 0/3 audited correct |
| `skipped` at finish | 2 | misnamed the play (#98); unanswerable, so fired every close |
| `held` (Stop refusals) | 17 | **the working part** — every one audited was correct |

The loudest voice was the wrongest one. That is not a routing bug; it is the
§8 family — emptiness and over-claim read as signal — in the channel that
talks.

### 1c. "Autonomous engineering via skill/plugin/MCP" — empty by construction, verdict already in

#58, measured: **0 of 34 installed plugins receive any capability**; the
selection stage has never contributed one row to `routes.tsv`; `catalog.tsv`
is 16 hand-written rows; MCP appears in the engine in exactly one role — being
refused. The funnel's two stages are each fatal alone: ten of twelve capability
rules are discarded because the project declares two capabilities, and the two
survivors match on plugin *names* against hand-guessed keywords, so nothing
matches anyway.

The 14-agent adversarial review already ruled on the obvious fix: **no
registry, no runtime retrieval** — the host enumerates and retrieves better
than Felix can (every skill description is in the session prompt; `ToolSearch`
covers MCP). What survived is the between-sessions configuration path, whose
inputs are simply empty. The work is populating, not building.

---

## 2. What tonight already changed (PR #103, merged on green)

The floor the redesign stands on — advisory honesty plus the measurement
instrument:

- Every advisory voice now claims exactly what its mechanism established, once
  per session, not per event. The subagent message states the checkout's
  condition, not the subagent's conduct; the finish-line message names the
  play, not just the miss.
- The mandate speaks with its measured accuracy and states its provenance.
- **`felix route --ack "<reason>"`** — the answer channel. A decline lands in
  `decisions.log` (durable, per project) and quiets exactly one finish-line
  complaint. This is the recording-only carve-out §0z names: with `named` and
  `reached` already in the ledger, `declined-with-reason` completes the
  observable set the deliberation layer needs — **while enforcing nothing**.
  The gate on the deliberation architecture stays closed until §3's decision B.

What the instrument yields from day one: every wrong route becomes a labeled
example written by the session that declined it. The table has never had
training data; now every miss generates some.

---

## 3. The redesign — three decisions, each a yes/no

Framed as what changes about Felix, because that is the register decisions are
made in.

### Decision A′ — Felix stops guessing content; the model selects; Felix forces the decision

*Revised 2026-08-30 after the founder asked the question the first draft left
open: "what serves the purpose of autonomously and smartly utilizing different
skills dynamically mid-session if we use per-phase voice?" The answer changes
the proposal's shape, not its evidence.*

**What the first draft got right:** the per-turn keyword mandate is dead.
Five recorded causes, ~2% precision, 2-of-11 follow-through. Nothing revives a
grep that must tell topic from task.

**What it left unowned:** opportunity recognition — noticing mid-session that
*this* subgoal is capability-shaped. Per-phase voice follows the arranged play;
it does not notice the unarranged opportunity. That gap is exactly the middle
stage the founder's own §0z architecture names: opportunity recognition →
action selection → execution commitment.

**The evidence triangulates to a division of labour, not a retreat:**

| component | can read meaning mid-turn | holds the inventory | measured verdict |
|---|---|---|---|
| the keyword table | no | no — 23 slots, hand-typed | 5 causes, ~2% precision |
| a per-turn model call | yes | yes | dead: 4.9–8.6s latency, process startup, measured twice |
| the host model, in-session | **yes** | **yes — every skill description is in its context** | skips the consider-step; acts on habit |

The only component qualified to select capabilities mid-session is the model
doing the work. What it lacks is not information but a **forced consider-step**
— which is deliberation forcing, the founder's proposal, verbatim: *"not 'use
tool X' but 'you may not silently skip the action-selection step here'."*

**So mid-session dynamism changes owner, not existence:**

- **Felix owns the moments.** Session start (the brief), proven play
  transitions (transcript evidence — already dynamic, already built), the
  finish line (built), and — once B's data supports enforcement — the forced
  decision points: before fan-out, before implementation begins, at review.
  Moments are state, not prose; Felix can read state at ~100% precision.
- **The model owns the selection.** At a forced moment it emits its capability
  decision — which skill, or NONE — from the inventory it already holds,
  scoped by the toolbox Felix arranged (C). Felix hardcodes the procedure; the
  model supplies the semantics. That is the cleanest resolution of the
  invariant-2 tension, stated in §0z, and it stays inside the invariant: a
  forced decision step neither narrows nor widens what is allowed.
- **The record owns the judgement.** Every decision lands in `decisions.log`
  beside `named` and `reached`. Whether the model selects well when asked
  explicitly is an empirical question, and B is its measurement phase.

Why this cannot fail the way the mandate channel failed: a forced *decision*
contains no tool name Felix guessed, so it cannot be wrong about content —
only present or absent. The failure mode shifts from "wrong mandate teaches
sessions to skim" (fatal, observed) to "one more prompt at a phase boundary"
(annoying, measurable, and the ack rate will say so).

**The ladder to the full vision, so the far end stays connected.** The Ultron
document's Felix owns *"which MCP, which plugin, which skill, in which order"*
— and the platform still refuses mid-session mounting (a host feature flag,
verified in the binary, likely to move on its own; HANDOFF §2). The rungs:

1. honest voice, once per moment — **shipped (#103)**
2. recorded decisions, declines as labeled data — **shipped (#103), B approved**
3. forced decisions at Felix-owned moments — **gated on B's 20-session review**
4. per-session arrangement from reach-vs-need — **C, agreed**
5. mid-session mounting — **blocked by the host flag; re-check, do not build around**

"Dynamic skills" in the founder's sense sits at rung 5 and stays out of scope
by their instruction. Rungs 1–4 are what "autonomously and smartly utilize
skills mid-session" means on today's platform: the model selecting, at forced
moments, from a toolbox Felix arranged, on the record.

**Alternatives considered and rejected for this revision, so they are not
re-proposed:** a bigger keyword table (five causes are structural, not rows);
a per-turn model router (measured dead, twice); a semantic veto layer
(suppress-only is invariant-legal but fixes false positives, not opportunity
recognition — and the recognition gap is the one that matters).

**Status: APPROVED by the founder, 2026-08-30** ("a looks fine"). The
mechanical translation — first-prompt naming plus transcript-proven advances,
no mid-session keyword re-mandates — is the next engine change.

**The selector's model, asked and answered the same day.** The capability
decision at a forced moment is made by the session's own model — whatever the
founder set the session to — by construction rather than preference. The
alternatives are each already refuted: a router model in the prompt path is
measured dead (4.9–8.6s, ~2s of it CLI startup; the intent-router design
killed it twice), a direct API sidecar puts a standing credential in every
governed session's environment against invariant 2's "no network, no key",
and — fatal even with those solved — a side model does not hold the session:
shipping it the transcript, tree and history per decision costs more than the
decision, and not shipping it rebuilds the keyword table's blindness with
better grammar. Same vantage finding that killed the registry. So the
deliberation moment is text in a hook, answered in-band: zero latency added,
zero cost, zero keys, offline, and selection quality scales with the session
model automatically. Felix does not pin the session model; that is the host's
surface and the founder's per-session call.

A second model enters only later and off the enforcing path: the unattended
repair loop's `claude -p` (no session model exists in CI until one is
invoked — a real cost/capability choice when that loop turns on), an advisory
judge over `decisions.log` at the 20-session review (proposal-only under
invariant 2, batch, cheap tier fine), and per-worker model choice when Felix
eventually owns dispatch.

### Decision B — the deliberation layer, entered through the recording door

**APPROVED by the founder, 2026-08-30**, with a condition: the tracker and
ack-rate data must survive the build weeks that start today. Discharged three
ways, none of them new machinery: `decisions.log` lives in the memory root
outside every checkout (invariant 6), the gate's `memory` check fails if it is
ever tracked into the repository, and the iCloud backup carries it —
restore-verified. `felix decisions` (0.49.30) makes the record legible on
demand: mandates rendered, declines recorded, answer rate, windowed to the day
the answer channel shipped. **The 20-session clock started 2026-08-30.**

§0z holds your architecture: deliberation forcing ("you may not silently skip
the action-selection step here") plus decision-action closure (every actionable
decision terminates in an observable state — EXECUTED, BLOCKED_BY_POLICY,
FAILED, SUPERSEDED, ABSTAINED — never DECIDED_BUT_DID_NOT_ACT). You gated it on
repeated confirmation that Felix has no routing role. The evidence resolved the
gate differently: the role exists, smaller, phase-keyed — which is what
Decision A implements. The measurement floor §0z identified is now built
(`decisions.log`, tonight).

**The proposal:** hold enforcement until the recording has run for **20
sessions** (the same threshold the exploration-arm decision already uses).
Then decide from data: if sessions record their capability decisions when
asked — the ack rate on wrong routes is the proxy — enforcement is
unnecessary and the layer is complete as instrumentation. If they do not, the
closure states become the Stop hook's vocabulary, and that is the enforcement
decision made once, on evidence, rather than tonight on instinct.

**What this deliberately refuses:** building the closure-state machine now.
Five of its states have no data (the same argument that held the autonomy
ledger's empty dimensions absent rather than zero-filled).

### Decision C — the capability funnel gets populated by reading manifests, not by guessing names

**AGREED by the founder, 2026-08-30.** Build order: with the founder building
today, C's three steps are the next engine work after this memo lands.

Per #58's own prescription, between sessions, no retrieval layer, no model in
any enforcing path:

1. **Capability declaration derives from evidence.** `felix doctor` already
   probes a checkout's surfaces; its findings become proposed rows in
   `capabilities` (proposed — a person commits them). A project declaring 2 of
   12 capabilities is the funnel's first fatality and it costs one command.
2. **Matching reads what a plugin ships, not what it is called.**
   `felix_discover_inspect` already opens every candidate's directory to score
   risk; the same read yields its skills list, hook events, and MCP transport.
   Matching manifest facts against declared capabilities replaces name-vs-
   keyword guessing. This is the discovery design's own "read three files"
   step, pointed at selection instead of only risk.
3. **MCP stops being only refused.** Felix records which `mcp__*` servers were
   *reached* (the ledger already does) beside which were needed (the play).
   The reconciler — the built, empty, between-sessions path — proposes mounts
   and unmounts at session boundaries from that record. No enumeration of
   remote tools, no execution of third-party code: the host retrieves; Felix
   decides what is worth having mounted.

**Explicitly out:** dynamic skills, runtime registries, semantic routing.

---

## 4. The autonomous-quality training process, standing from tonight

The founder asked for *"a process to train the autonomous quality in the mean
time."* Tonight ran it end to end; this section is what it is, so the next
session inherits a process rather than a description of one night.

**Per session (the drill, unchanged, now written down):** declare tier → read
the handoff and constitution → verify claims by command before acting on them →
reverse-test every fix at its call site → gate in the tree that can deploy →
ship on green CI → record lessons where they will be re-read → back up memory
and verify the backup by restoring it.

**Per decline (new):** a session that judges a route wrong records why with
`felix route --ack`. The reason is the training datum. Silence is the only
wrong answer.

**Per week (new, one command each):** `felix route --promote` for the misses;
`decisions.log` for the declines. Table revisions cite both. This is the loop
that makes the table earn its rows — the same earned-autonomy shape as
auto-merge, applied to advice.

**The metric correction, adopted from v3 §19:** founder interruptions per
session stays the objective, now paired — a missed escalation counts against
Felix, and the ack rate measures whether the advisory channel is worth
having. An interruption number that improves by advising less is the gamed
version; the pair is what makes it honest.

---

## 5. What was deliberately not done tonight

- No enforcement anywhere. The deliberation gate stays closed pending §3B.
- No table surgery beyond what #103's honesty fixes required — Decision A
  retires the per-turn channel and rewriting rows for a channel being retired
  is waste.
- No registry, no semantic routing, no dynamic skills.
- No thesis-level change. All three decisions above are reversible
  configurations of existing machinery; each names its cost; none is taken
  until you take it.

## 6. The morning's yes/no list

| decision | status |
|---|---|
| **A′** — Felix owns moments, the model selects, the record judges | **APPROVED 2026-08-30**; selector = the session's own model, by construction |
| **B** — deliberation via recording, 20 sessions | **APPROVED 2026-08-30**; clock running; tracker is `felix decisions` |
| **C** — populate the funnel from manifests | **AGREED 2026-08-30**; next engine work |

The coherent system, restated under A′: Felix arranges the toolbox between
sessions (C), forces the capability decision at moments it owns (A′), and the
record says whether the model decides well enough that recording is all the
enforcement needed (B).
