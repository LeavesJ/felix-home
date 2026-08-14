# Felix against the Ultron federation contract — gap analysis

Written 2026-08-13, reading `founder_autonomous_company_os_v3_ultron.pdf` (57pp)
against the tree at `671600b`. Every claim about Felix below was checked against
the code or a command, not recalled.

The v3.0 document is not a new direction for Felix. It is the first external
statement of what Felix was already being built toward, and it names Felix:
*"v3.0 • Felix as the Engineering OS reference implementation"*, and later,
*"Felix is the first reference implementation of the domain-OS pattern."*

That makes one sentence in it the most consequential thing anybody has written
about this project's backlog.

---

## 1. The sentence

Part VI, build order, item 1:

> Make Felix excellent as the Engineering OS reference implementation: state,
> policy, routing, evidence, receipts, host portability, and external interface.

Seven things. Felix has five. The two it does not have are the two that make it
a federation member rather than a very good local harness, and they are **step
one of the entire v3 plan** — everything else in the build order is downstream
of them.

## 2. The domain OS contract, checked item by item

The document lists seven things a domain OS must own (Part I, §3). Checked
against this tree:

| Contract requires | Felix | Evidence |
|---|---|---|
| Constitution / policy — durable rules, authority boundaries, risk tiers, approval conditions | **yes** | `projects/felix/CLAUDE.md`, `risk.tsv` with tier + `channel` + `confine`, `felix autonomy` |
| State + memory — current state, validated lessons, handoff state, historical outcomes | **yes** | `memory/lessons.md`, `SESSION_HANDOFF.md`, `HANDOFF.md`, `ledger.tsv`, `mistakes.log` |
| Capabilities — tools, MCPs, skills, brokers activatable by task | **yes, with one honest bound** | `stack.tsv`, `felix ready`, `felix toolbox`, `felix adopt`, `felix discover`. Cannot mount mid-session; writes config the next session boots with |
| Routines — scheduled and event-triggered maintenance, reconciliation, audits | **yes** | `maintenance.tsv`, `felix maintenance`. Note these were unreachable from birth until 2026-08-13 |
| Verification — deterministic checks or externally grounded evidence | **yes** | `felix gate`, receipts keyed on tree identity, `felix review` for surfaces no test judges |
| Receipts — **machine-readable** record of what changed, why, evidence, risk, result | **partial, and this is the weaker of the two gaps** | see §3 |
| External interface — stable request/event/response envelope used by Ultron and peer OSs | **absent** | see §4 |

Plus, from the build order, **host portability**: absent. Felix is bound to
Claude Code — `hooks.json`, the plugin cache, the session lifecycle, the
transcript. The v3 document is explicit that this separation should be kept
visible: *"The harness is the deterministic kernel; the host model is the
executive reasoning layer."* Felix's kernel is genuinely separable — the
enforcing path is bash and git with no network, key or model — but nothing has
ever run it under a second host, so portability is a property nobody has tested
rather than one the design lacks.

## 3. Receipts: Felix records, but does not emit

Felix writes a great deal down: `says.log`, `verification.log`, `routes.log`,
`ledger.tsv`, `mistakes.log`, gate receipts, review verdicts. All of it is
**internal exhaust in ad-hoc formats**, readable by Felix's own commands and by
`felix monitor`.

The contract asks for something different: a record of *what changed, why,
evidence, risk, and result*, machine-readable, that a peer can consume. And
Part V is explicit that Ultron *"should consume the smallest sufficient
representation of domain state rather than raw internal exhaust."*

Felix already computes every field. `felix classify` produces risk. `felix
evidence` produces what is owed. The gate produces the result. `felix next`
produces findings. None of it is emitted in a stable shape, and nothing versions
it. This gap is smaller than it looks: it is a serialiser over facts that
already exist, not new machinery.

## 4. External interface: the gap that answers an open question

`HANDOFF.md` §1 has carried this, unresolved, since 2026-08-13:

> *Autonomous initiation* is blocked on a design question nobody has answered —
> what may wake Felix, and on whose authority. ... the first will not unblock on
> its own.

**The v3 document answers both halves.** What may wake Felix: a typed `request`
from Ultron, or a domain event. On whose authority: Part II §7, hierarchical
authority — *"Higher-level intent grants purpose, not unrestricted
capability."* Ultron may narrow what Felix is allowed to do; it may never widen
it, and it may not bypass Felix's local gates. The document even uses Felix as
its worked example: *"FELIX: approval does not authorize bypassing CI or branch
protection."*

So the item that "will not unblock on its own" has unblocked, from outside. That
should be recorded as answered rather than left as an open design question,
which is the whole reason this file exists.

## 5. Where Felix already agrees, arrived at independently

Worth writing down because convergence is evidence the design is right, and
because it means less work than it appears.

- **Authority may narrow, never widen.** v3 §7. Felix's second invariant says a
  model *"may propose, never widen"*, and the `reviewed` escape clause is
  precisely what v3 calls *"an explicit, auditable policy mechanism"* for the
  exception — bounded to one channel, keyed to an exact tree, cleared only by a
  passing verdict.
- **Prefer instruments over standing adviser LLMs.** v3 §6. Felix's `discover`
  and `stack` machinery is built around installing instruments, and its charter
  already refuses to let a model be the final authority.
- **The founder surface is an exception router, not an activity feed.** v3 §12.
  Felix's charter calls this *stealth in the middle*, and says *"a report nobody
  asked for is the same defect as a decision nobody needed to make."*
- **Six message types Felix already computes internally.** `exception` is the
  escape channel escalating; `receipt` is the gate receipt; `finding` is a
  `felix next` row or a `classify` verdict; `decision` is a `felix review`
  verdict or an `autonomy` grant. Only `request` and `commitment` have no
  analogue — and `request` is the external interface gap.

## 6. Where v3 corrects Felix, and this one matters

Felix's declared objective is **founder interruptions per session**. v3 §19
states the same metric with a qualifier Felix does not have:

> Founder decisions requested per week — lower is better **only if decision
> quality remains high**.

Felix's version has no quality term. It is therefore gameable in exactly the way
the project already worried about for gate pass rate: escalate less and the
number improves. `HANDOFF.md` explicitly rejected gate pass rate for this reason
and then adopted an objective with the same shape.

v3 also supplies the missing paired metrics: **unnecessary escalation rate and
missed-escalation rate**, and **decision-packet acceptance / override rate**. A
missed escalation is the failure mode Felix's objective currently rewards.

This is a real correction to Felix's own charter and it is not a scope question.
It should be taken.

## 7. What this does not authorise

Felix's constitution says *"Phase 1 of the guidebook and nothing past it."*
Reading v3 does not change that on its own, and this document does not propose
building Ultron, a second OS, an event bus, or a workflow engine. All of those
are explicitly downstream in v3's own build order — item 4 says stand up Ultron
*"only after two domain OSs can communicate."*

The narrow question it does raise: **is the external interface Phase 1 work?**

The argument that it is: v3 puts it in build-order item 1, inside "make Felix
excellent". Felix's own charter already says *"design its surfaces so something
other than a human can drive them"* — which is standing direction to build for
machine drivability, and an interface nothing can call is that direction
unfinished.

The argument that it is not: nothing exists to call it. There is no Ultron, no
second OS, no bus. An interface with no consumer is a design exercise, and this
project has a written lesson about building the compensating mechanism before
establishing it is reachable.

**Recommendation, for the founder to accept or refuse.** Do the receipt half and
not the request half. Emitting a typed, versioned receipt is (a) pure
serialisation of facts Felix already computes, (b) immediately useful to a human
and to `felix monitor` with no Ultron in existence, (c) the thing that makes a
second OS cheap to build later, and (d) testable today. Accepting inbound
requests is the half that needs a consumer, a transport, an authentication story
and probably a long-running process — and it should wait until there is
something to talk to.

That splits step 1 into a part with a payoff now and a part with a payoff later,
and only commits to the first.

### 7a. Accepted and built, 2026-08-13

The founder took the split. `felix receipt` ships in **0.47.11**, emitting
`felix.receipt/1`: subject, changed, risk, verification, evidence, authority,
confidence. It discovers nothing — every field was already computed by
`classify`, `evidence`, the gate, or `escape`, and was only ever rendered as
prose for a person.

Two fields are shaped by §8 rather than by the contract. `authority` is carried
in the document because **no transport carries it**, so a receipt that did not
state it would be leaving the claim nowhere. `verification` is its own object
with three states — `none`, `stale`, `current` — because **neither protocol
models verification as distinct from completion**, and that distinction is the
thing Felix has that they lack. Run against the change that built it, it
reported `stale`: a green gate receipt belonging to a different tree. Correct,
and the distinction earning its place on the first day.

**The rule it keeps, which matters more than the shape.** A receipt may not
claim more than it knows. Any input that could not be read puts its own name in
`unknown` and forces `status` to `indeterminate`. An absent gate receipt is
`none`, never green; an unresolvable base is `changed.known: false`, never an
empty changeset; an unreadable risk table is tier `unknown`, never `green` —
which this project shipped once already. That is the self-report constraint from
§7 made mechanical, and it is asserted rather than intended.

**The request half is still not built, deliberately.** Nothing has changed about
the argument: it needs a consumer, a transport, an authentication story and
probably a long-running process, and §8.3 establishes that the A2A shape would
make Felix a server. Revisit when something exists to talk to.

## 8. Transport: researched 2026-08-13, and the answer is "neither, yet"

The question was narrow: **can MCP or A2A carry a verified receipt, a bounded
authority claim, and a human approval that resumes a waiting workflow — without
Felix running a network service?**

Answered against MCP revision `2026-07-28` (shipped, final), Cloudflare's
implementer account of it, and A2A `v1.0.1` (2026-05-28, Linux Foundation,
eight-company TSC). Scored per requirement:

| Ultron needs | MCP 2026-07-28 | A2A 1.0.1 |
|---|---|---|
| Human approval that **resumes** the same workflow | Tasks extension: `input_required`, `tasks/update`, task ids survive client restart | **Yes, first-class.** `TASK_STATE_INPUT_REQUIRED` is non-terminal; client resumes with the same `taskId` |
| Verified receipt | structured output + `outputSchema`; no signature over results | `Artifact` is the right shape; **no signature over task output** — only AgentCards get JWS |
| Bounded authority claim | **none.** No actor claim, no on-behalf-of, no delegation depth | **none.** Payloads carry no identity; authority is transport-layer OAuth only |
| Verification distinct from completion | not modelled | **not modelled** — no state between `WORKING` and `COMPLETED` |
| Compensation | not modelled | **not modelled**, and terminal state is immutable, which actively fights it |
| Runtime discovery of a peer | **no** — see §8.1 | **yes**, signed `AgentCard` at a well-known URI. A2A's clearest advantage |
| Works without Felix running a daemon | yes (Felix as client) | **no** (Felix as server) — see §8.3 |

### 8.1 MCP does not unblock mid-session mounting, and the reason moved

Felix's standing limitation — *cannot mount an MCP server mid-session* — is
**not** lifted by this revision. There is no way for a client to discover, add
or mount a server it did not already know about. `server/discover` describes
only the server already being addressed. The MCP Registry is a REST preview
service its own docs say is not for direct host consumption. Server Cards
(SEP-2127) would give pre-connection discovery and is **in review, not landed**.

But the shape of the obstacle changed, and this project has a written lesson
about establishing who set a limit before reporting it as one:

- The revision **deletes the handshake and the session**. Every request is
  self-contained. So the *cost* of attaching a server mid-session has collapsed
  to nearly nothing; what is missing is only the mechanism to learn one exists.
- **Claude Code 2.1.226 already contains a complete 2026-07-28 client** —
  verified on this machine, not taken on report: the binary carries
  `server/discover`, `subscriptions/listen`, `inputRequests`, `Mcp-Method` and
  the version string. It is **switched off**. The gates read
  `nt("tengu_mcp_protocol_negotiation_http", !1)` — server-side flags defaulting
  to false, falling back to `{mode:"legacy"}`. Observed wire traffic is
  `2025-11-25` with the old `initialize` handshake.

So the limitation is now **a feature flag in the host, not a gap in the
protocol**. That is still a ceiling Felix cannot reach past, but it is somebody
else's ceiling with a known name, and it is likely to move on its own. Restate
it that way rather than as a protocol fact.

### 8.2 The gap neither protocol fills, which is the real finding

Both protocols model **one caller, one callee, one unit of work**. Ultron models
**a workflow owned by nobody that must survive both parties restarting**. That
is a workflow engine, not a message protocol — which v3.0 says itself when it
calls for *"durable orchestration with explicit state, retries, waits,
compensation, and verification"*.

Concretely, against §9 and §10 of the v3 document:

- **`commitment` and `decision` have no home in either.** A2A's `SUBMITTED`
  means "acknowledged", not "promised": no deadline, no `expected_delay`, no
  scope agreement. A standing decision that binds *future* work has nowhere to
  live in a protocol where nothing exists outside a task.
- **`exception` half-fits.** A2A models "I refuse" (`REJECTED`) and "I broke"
  (`FAILED`). Neither models *a human other than you must decide*. There is no
  escalation-to-third-party, no approval token, no way to address a founder.
  Felix's escape channel is exactly this type, and it is the one the objective
  counts.
- **The race-condition rule is unenforceable in both.** v3 requires that a
  downstream domain must not treat intention as completion. A2A puts dependency
  ordering entirely on the client, and `WORKING` with a status message *is*
  another domain's intention on the wire. `SendMessage` idempotency is only
  `MAY`, and nothing advertises whether a callee deduplicates — so *"retries
  bounded and side-effect-safe"* is not a property either protocol can supply.
- **Neither carries authority.** This is the sharpest convergence. A2A's spec
  says payloads carry no client identity; MCP has no actor or on-behalf-of
  claim. The identity work is A2A's most contested area — several proposals
  with hundreds of comments between them, **zero merged**.

There is an accidental win worth naming: because neither protocol carries
authority, **Ultron structurally cannot widen Felix's authority over the wire.**
Felix's second invariant is satisfied for free. But it is satisfied by *silence*,
and silence is unauditable — nothing in either protocol records what authority a
request was made under, so a receipt cannot prove a request was in scope. v3's
own evaluation asks *"Did any higher layer widen lower-layer authority without a
sanctioned mechanism?"* Neither wire format can answer that question.

### 8.3 Being an A2A server costs a daemon, and that is the deciding fact

Felix as an A2A **client** is `curl`: build a `SendMessage` body, POST it, poll
`GetTask`. No server, no daemon, compatible with the bash-and-git enforcing path.
It also does not make Felix drivable by Ultron, which was the point.

Felix as an A2A **server** requires: an HTTPS endpoint, `SendMessage`, `GetTask`,
`CancelTask` and `ListTasks` (which has no capability flag, so it is not
optional), server-generated task ids, a task store whose state outlives the
request *and the session*, and a credential on the box. Streaming and webhooks
are genuinely optional; the daemon is not. `AgentInterface.url` is required and
must be an absolute HTTPS URL in production.

**That is a different product.** Felix today is a harness that exists while a
human is in a session. An agent with a listening port, a TLS certificate, a
credential and an uptime property is not the same thing, and adopting it would
be the largest change to what Felix *is* that anyone has proposed.

One escape hatch is worth watching and not planning on: **A2A issue #1074**, an
LSP-style stdio transport, labelled `TSC Review`, open since 2025-09-16 and last
touched 2026-08-11. If it lands, Felix could be an A2A agent spawned as a
subprocess — no socket, no certificate — which is exactly Felix's existing shape.
That single issue is the difference between "compatible with what Felix is" and
"incompatible". Check it before building anything.

### 8.4 What this changes about §7's recommendation

Nothing, and that is the useful result. The recommendation was to emit receipts
now and defer inbound requests. Both protocols independently confirm the split
is the right one: the receipt half needs no transport and no daemon, and the
request half needs a transport that does not yet carry what v3's authority model
requires.

Two refinements the research does add:

1. **Shape the receipt so it can become an A2A `Artifact` later** — an id, a
   name, typed parts, and a `metadata` map keyed by one Felix extension URI.
   Costs nothing now and preserves the option.
2. **Write the mapping table while designing the envelope, with no code behind
   it.** `domain` → `AgentCard.name`; `workflow_id` → `contextId`; a step →
   `taskId`; payload → `Artifact.parts[].data`; everything unmappable →
   `metadata` under one extension URI.

The reason for (2) is the strongest argument *against* deferring, and it should
be recorded rather than waved away: deferring risks designing an envelope A2A
cannot carry, discovered at integration time when it is most expensive to
change. The concrete example is terminal immutability — if Felix's envelope
assumes one identifier moves COMPLETE → COMPENSATING → RECOVERED, and A2A
forces every compensation into a *new* task linked only by a hint-grade
`referenceTaskIds`, then the envelope's identity model is wrong and every
consumer is rewritten. Writing the mapping now is how that gets found while it
is still free.

This project also has a written lesson against building a compensating mechanism
before establishing it is reachable, and "adopt the envelope, defer the
transport" is close enough to that shape to deserve the challenge. The
distinction: the envelope **has** a consumer today — a person, and
`felix monitor` — and the transport does not.

### 8.5 For the Research OS specifically

Recorded here because it was asked and because it will be someone's step 1:

- **MCP has no content addressing.** No etag, no hash, no revision or version
  field on a resource, and cache freshness is TTL-only with the spec stating
  plainly that a server MAY change data before expiry. A `resources/read` at T2
  may differ silently from T1 **with no protocol-level way to detect it.** For a
  system whose core value is re-verification of a cited claim, that is the
  load-bearing gap, and it must be closed in the harness — hash the bytes, store
  them, define your own `_meta` keys under your own reverse-DNS prefix.
- **Pagination has no cross-page consistency guarantee.** A literature sweep can
  observe duplicates or gaps if the underlying data changes mid-sweep; a
  consistent snapshot requires restarting from the beginning. That is a
  correctness constraint on any evidence-gathering routine.
- **Long research work is forced into the Tasks extension.** Transport-level
  resumability was *deleted* this revision — no `Last-Event-ID`, no redelivery —
  so a broken stream loses the in-flight request. Tasks survive client restart;
  ordinary long requests no longer do.
- **Two things genuinely help.** `_meta` is now a first-class namespaced
  metadata channel on requests *and* results, so provenance keys travel with the
  payload; and OpenTelemetry `traceparent` / `tracestate` are documented reserved
  `_meta` keys (SEP-414), which is a standardised audit spine — the same
  correlation-id requirement v3 puts on cross-domain workflows, already specified.

### 8.6 Confidence, and what was not established

Both protocol revisions were read from primary sources with per-claim citation,
and the Claude Code finding was re-verified on this machine rather than taken on
report. Not established: no source states an A2A 1.1 or 2.0 exists or is
scheduled; `a2a-protocol.org` advertises 1.0.0 while GitHub tags 1.0.1, a patch
level disagreement only. One paper on governance gaps in interoperability
protocols could not be read in full and was excluded from every load-bearing
claim here — a summary of it asserted that A2A "enables agents to delegate
authority", which contradicts the primary specification, so treat second-hand
accounts of this area with suspicion.
