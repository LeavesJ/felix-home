# Speedrun and YC application brief, November 2026

Facts for the founder's own session to write the a16z speedrun SR008 application from. This is not the application text. Every number below is sourced in this repository or in the market brief; where two sources disagree, the brief says which holds and why.

Prepared 2026-10-27 from `docs/direction.md` (as of 10-19), `README.md`, the 2026-10-18 capability plane thesis, `docs/handoff/0cw.md`, the four outside reports on `salvage/home-reports-2026-10-03`, investor deck v3, and the October market brief (kept in the founder's claude.ai felix-strategy channel files, `felix-strategy/market-brief-2026-10.md`).

## Deadlines

| Program | Closes | Terms | Source |
|---|---|---|---|
| a16z speedrun SR008 | 2026-11-01 | Up to $1M: $500k for 10% on a SAFE, plus $500k into the next round within 18 months | a16z.com, read 10-27 |
| YC Winter 2027 | 2026-11-02, 8:00 PM PT | Decisions by Dec 11; batch January to March in San Francisco; late applications still considered | ycombinator.com/apply, read 10-27 |

The same facts serve both. YC's batch runs through M2 and the February pilot, so weigh the time cost before applying there.

## Settle before submitting

1. **Entity.** Settled by the founder on 10-27: Felix is under his own name, not Veldra, Inc. and not Elenchus Labs. The speedrun team says incorporation before applying "is definitely better", and that some companies "were incorporated upon acceptance" (speedrun.substack.com, top 71 questions, 2025-05-14). If Felix later moves into Veldra, Inc. (an existing Delaware C corp) or a new entity, assign the IP cleanly first: the Riyan handover docs record that whether Elenchus Labs' CIIAA reaches Felix "is genuinely unclear", and an investor's counsel will ask.
2. **The headline number.** Use 206, stated as below. Do not use the deck's "363 unverified stops blocked". Reconciliation:
    - **206** (README): across 43 of the founder's sessions, Aug 10 to Sep 21, 2026, counted from transcripts and Felix's logs, Felix held an agent's attempt to stop 206 times. 135 because the gate had last run on a different tree, 39 because it had never run in that checkout, 29 because it had failed on the exact tree. Sent back, the agent reran the gate about 130 times and at least 15 of those runs failed. Six weeks, a cause for every hold, and public.
    - **363** (outside 48 hour report, Sep 22 to 24, page 4 and appendix): 363 holds in 51 sessions where no current passing gate result existed for the tree. Of those, 113 coincided with stop after edit turns, 38 followed scratch, config or memory edits, and 212 followed turns with no new edit. So "363 unverified stops blocked" overstates it: most of the 363 were holds after no new edit.
    - **371** (second report, Sep 30): another 48 hour window, 45 sessions, 64 after counted edits. The report itself warns the two scans are not comparable.
    - **35.7%** (deck slide 8): 55 of 154 parent session edit stops in the Sep 22 to 24 sample lacked fresh recognized verification. It excludes subagents (53% of token traffic) and the Sep 30 rescan found 46 of 88 (52.3%) under a different instrument. If used, say "in one 48 hour sample of parent sessions".
    - Fix the deck to match before anyone outside sees both.

## One line

Felix is the autonomous engineering control plane that decides what counts as done. Bring any agent: Felix decides what your project owes, who does each piece, what proves it on the exact revision, and when to ask you, measured in verified progress per unit of your attention.

## Category

An autonomous engineering control plane turns intent into shipped software through rented agents and decides what counts as done: what the work owes, who supplies each piece under what authority, what proves it on the exact revision, and when a person must be asked. Direction §1: two planes. The trust plane decides what may land and what a green verdict means. The capability plane decides what a project owes and who supplies each item, under what lease, checked by whom. The split: the founder owns what gets built; Felix owns how.

Felix is not a better agent (ruling D1: the host picks its model; Felix never builds a model minimizer) and not a firewall. Deck v3: "Do not make the AI deterministic. Make the boundaries deterministic."

## Problem

- The failure is self certification, not capability (deck slide 8). The party paid to finish grades its own work.
- Passing is not merging: METR found roughly half of SWE-bench Verified PRs that pass the automated grader would not be merged by maintainers, the grader running about 24 points above maintainers (metr.org, 2026-03-10).
- The founding case (README): a deployment shipped with green tests and no rate limiting, because nobody had thought to ask for one. A gate can only hold an agent to checks someone wrote. The missing obligation is the harder half.
- 96% of developers do not fully trust AI code and only 48% always check it before committing (Sonar, 2026-01-08).

## Why now

- Labor is cheap and plural: Claude Code passed a $2.5B run rate in February 2026; SpaceX closed its acquisition of Cursor at about $60B on 2026-08-14; Cognition raised at $26B in May. Teams run more than one agent vendor, which is why GitHub built Agent HQ.
- Every vendor is shipping self verification inside its own product (Claude Code Review, Copilot validation tools, Bugbot, Devin Review). Independence is the open slot.
- Gartner's first Market Guide for Guardian Agents (2026-02-25) expects enterprise owned, independent control layers across platforms. Its 2026 Magic Quadrant for enterprise AI coding agents calls the purchase "an operating model decision".
- Agent incidents are authority failures: Replit's production database deletion (2025-07), the Kiro related AWS outage (2026-02), a Cursor and Claude agent deleting a production volume and backups (2026-04).

## Why Felix, from the market map

Mapped across ten layers (intake, obligations, coordination, composition, labor, authority, evidence, release, learning, neutrality), the field covers labor, coordination and authority well and intake increasingly. Nobody found holds:
- a standing obligations ledger with a denominator and residual, surviving sessions and vendors;
- evidence bound to the exact tree that goes stale when the code moves;
- a verifier the authoring vendor does not control and the user cannot skip;
- interruptions per task as a measured metric.

Those are Felix's owned layers. Signed, SHA bound receipts alone are not novel (AI-SDLC, JFrog's Agentic Process Evidence Protocol of 2026-10-12, agentmarshal), so do not lead with receipts. Lead with done being computed by something other than the party paid to finish.

## Evidence that exists today (honest)

- Founder usage behind the design: 87,137 API turns, 18.1B tokens over 73 days (deck v3, from the 09-21 outside report).
- Holds: 206 across 43 sessions, Aug 10 to Sep 21 (above).
- Engine: about 29,500 lines of bash plus a 6,700 line CLI, 193 test parts and 13,818 assertions; version 0.49.307 on 10-23. Engine public under Apache 2.0 at LeavesJ/Felix.
- Running with nobody present: the Stop hold, the gate, deny rows, receipts bound to the tree, the merge boundary, session start context (direction §2).
- Land on green live since 10-18: 0 lander merges of 24 ledger rows at the 10-19 snapshot, 2 later that day.
- Founder leakage measured at 31% of founder turns in the episode pilot and 36 to 50% in batch 2 (the binding metric's baseline).
- Prior founder record: Elenchus, 200+ Berkeley users and a 1,282 test offline suite (deck v3).
- `felix audit`: reads existing Claude Code transcripts, installs nothing, no network, counts stops after edits no check ran on.

Not yet true, and do not claim: independent acceptance (the 0cw claims ruling, direction row 17, bars the phrase in outside text until #350 and the judge pin; #350 has landed, the pin has not), any admitted derived obligation (0 of 22 admitted), multi user use, egress control, a second host, any customer.

## Roadmap (docs/handoff/0cw.md, dates as estimates)

| Milestone | What | Target, P80 |
|---|---|---|
| M0 | Console v0: inventory, stuck PR page, lost work page | landed 10-23 |
| M1 attended loop | One objective end to end: obligations, attended dispatch tick on a dollar cap, independent verification, attended landing, one measured routing decision | late Nov, early Jan |
| M2 full MVP | Judge pinned, qualified judge, post deploy check and rollback, stale receipts, a second ecosystem, the seeded omission corpus against plain Claude Code | late Jan, mid Feb |
| M3 | Second provider, customer keys, schedules | not before March |

Proposed and awaiting the founder (draft PR on `claude/direction-row-10-commercial`): a narrow commercial track now, and the second host (Factory Droid, then Codex) moved forward beside the judge pin.

## The February pilot, as it really stands

- Approved in principle only (direction §6), with egress control first.
- Users: software engineers at a TSMC subcontractor in supply chain and materials, building a semiconductor supply chain system. It is a family connected company. Say so plainly if asked; present it as a design partner, not as independent validation.
- Not yet written: scope, success criteria, data terms, contract, a signer.
- What it is meant to measure: interruptions per session before and after, maintainer acceptance of agent PRs, seeded omission recall against plain Claude Code with Claude Code Review.
- Why it is a good first test anyway: semiconductor suppliers carry real liability for supervising what leaves their environment (Taiwan's National Security Act lists key gas, chemical and equipment technologies among core key technologies; Tokyo Electron Taiwan was convicted on 2026-07-30 for failing to supervise in the 2nm leak case). Evidence and supervision are the product there.

## Business model (hypothesis, not decided)

- Self hosted: the engine runs in the customer's environment on the customer's own model key (M3 "customer keys"), so no code reaches a Felix server. Felix cannot take a token markup; it charges for the verdict.
- Draft price: a platform fee plus active committers, about $1,000 a month plus $40 per active committer per month, roughly $24k a year at 25 committers. Comparable assurance tools: Endor Labs about $35k ACV (Sacra estimate), Snyk median $45k (Vendr), CodeRabbit median about $65k.
- First buyer: head of platform or VP Engineering at a 50 to 500 engineer, SOC 2 bound team running two or more agent vendors; the CISO co-signs.
- Paid pilot: about $15k for February and March, credited to an annual contract.

## Landscape, without "vs"

- Agent platforms selling labor plus coordination: Factory ($200M at $5B, 2026-09-15), Cognition, Cursor (SpaceX), OpenAI Codex, GitHub Copilot and Agent HQ, Claude Code, Augment Intent (free bring your own agent orchestration on Claude Code or Codex), Kiro.
- Agent security selling authority controls: Zenity, Endor Labs AURI, Noma. Review and verification: CodeRabbit ($1.5B), Qodo, Axiom (Lean proofs, $1.6B).
- Felix's place: the layer that decides done across all of them. It can use any of them as labor or as a candidate source, and none as its judge.
- Exits in the space: security platforms bought agent control layers for $200M to $700M in 2025 to 2026 (Palo Alto with Protect AI, Check Point with Lakera, SentinelOne with Prompt Security, Cato with Aim); Atlassian bought DX (engineering productivity measurement) for about $1B.

## Likely questions and honest answers

- **Why won't Anthropic or GitHub just build this?** They are building self verification; the conflict is structural, since a vendor's report on its own blind spots is worth nothing and no vendor ranks itself against a competitor on a customer's repository. Felix's verdict never reads which model did the work. Honest gap: today Felix runs only on Claude Code; the second host is proposed for this winter.
- **Isn't this just an eval or code review tool?** Review gives an opinion on a diff. Felix decides what the work owes before any check runs, binds proof to the revision, reopens it when the code moves, and gates release.
- **What is the moat if the engine is Apache 2.0?** Not the mechanism. The accumulated per project evidence: qualified checkers with mutation records, obligation classes with blind fixtures, attributed outcomes. Honest gap: that accumulation has not started (0 of 22 obligations admitted).
- **Who pays?** Engineering leadership, from the non authoring share of AI tooling budget (DX: about $1,000 per developer per year, 15 to 20% non authoring). Honest gap: no customer, no price tested.
- **Why you?** He used agents hard enough to find the failures autonomy creates and turned them into architecture (deck slide 18), with the usage record above. Shipped Elenchus to 200+ users before this.
- **Traction?** Pre traction. Speedrun says it takes companies "both pre and post traction" and "no startup is too early" (same FAQ).
- **What happens in the next 12 weeks?** M1 attended loop, M2 MVP with the seeded omission corpus result, a paid February pilot, and two unrelated design partners.

## Weak spots to frame honestly

- **Full time.** The founder is a first year Berkeley EECS student. Speedrun says "We prefer all co-founders to be full time" (same FAQ). Say what is true about time commitment; do not overstate.
- **Solo founder, agents doing most engineering.** One maintainer; nothing on file about a second human.
- **Single user, single host.** The README says it was built for one person; team concurrency is deferred past March.
- **The capability plane is unmeasured.** The seeded omission corpus has a settled protocol and has not run (waiting on its spending ceiling, $96 to $349).
- **The pilot is family connected and egress blocked**, with nothing in writing yet.
- **Entity and IP**: under the founder's name today; clean assignment needed before any incorporation into Veldra, Inc.

## Unverified, do not state as fact

Factory, Cursor, Devin and Claude Code enterprise contract sizes; who owns the budget line for coding agent assurance; TSMC's current AI policy; whether the subcontractor's engineers already use Claude Code on an approved endpoint; Cognition's ARR after May 2026.
