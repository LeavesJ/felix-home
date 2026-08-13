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

## 8. Open, pending research

The transport is undecided and deliberately not guessed at here. Two candidates
are under investigation as of writing:

- the MCP revision dated 2026-07-28, and Cloudflare's implementer account of it
- the A2A (Agent2Agent) protocol, as a possible carrier for the inter-domain
  envelope, its six message types, and the saga lifecycle

The question that decides it is narrow: **can either carry a verified receipt,
a bounded authority claim, and a human approval that resumes a waiting
workflow — without requiring Felix to run a network service?** The last clause
is the constraint that matters, because Felix's enforcing path must work with no
network, no key and no model, and a harness that only functions while a daemon
is up is a different product.

Fill this section in when that research lands. Do not decide it from the names.
