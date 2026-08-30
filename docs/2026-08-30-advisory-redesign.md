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

### Decision A — the router stops speaking per-turn and starts speaking per-phase

**What Felix stops being able to do:** interject a mandate into an arbitrary
turn on a keyword match. The per-turn channel's measured precision does not
survive contact with any of #29's five causes, four of which are structural
properties of keyword tables (topic-vs-task, quoted material, phase blindness,
recording-shape) that no table revision fixes.

**What Felix does instead:** speaks at the three moments whose precision is
structurally high, because they are defined by state rather than by parsing
prose:

1. **Session start** — the briefing it already gives: constitution, handoff,
   lessons, and the play for the session's *declared* work. Already built.
2. **The finish line** — the Stop hook, on tree state and the play's unused
   steps, once, with the ack channel. Rebuilt tonight.
3. **Phase transitions the transcript proves** — a play step comes due when
   the previous one's use is *in the transcript* (`felix_route_due` already
   reads this). The play advances on evidence, never on keywords.

The keyword table survives only as the *initial* play selection at session
start, where the founder's own prompt names the work — the one place the blind
study found it right. The per-turn `UserPromptSubmit` mandate path is retired.

Evidence this direction is right rather than merely smaller: #29's sharpest
finding is asymmetric — *"the wrong first step costs the right last step"* — a
session told to brainstorm a filed issue reads the whole play as noise and
skips the review step it actually needed. Fewer, better-placed words recover
the steps that matter.

**Cost:** Felix stops catching the mid-session pivot (a debugging session that
becomes a shipping session). The recording (`routes.log`) keeps observing
those; if the data later shows pivots are common and costly, that is a new
design question answered with data the ack channel is already collecting.

### Decision B — the deliberation layer, entered through the recording door

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

| decision | yes means | no means |
|---|---|---|
| **A** — per-phase voice | the per-turn mandate path is removed; Felix speaks at session start, proven phase transitions, and the finish line | the channel keeps firing per-turn while its five causes await five designs |
| **B** — deliberation via recording, 20 sessions | enforcement is decided later, from ack-rate data | the closure states are built now, unmeasured (your original architecture, sooner and blinder) |
| **C** — populate the funnel from manifests | doctor-derived capabilities, manifest-fact matching, reconciler proposals from reach-vs-need | the funnel stays empty and tooling stays hand-arranged |

A yes to all three is one coherent system: Felix arranges the toolbox between
sessions (C), names the play at moments it can defend (A), and records every
decision about capability use until the record says whether recording is
enough (B).
