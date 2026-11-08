# Felix trust-plane design (draft 5, final)

2026-11-07. **Final: the founder accepted this draft's direction on 11-07** ("v5's directions can be final"). It replaces draft 4. Drafts 2 to 4 stay in the memory root, under `designs/2026-11-06-trust-plane-revisit/`, as history. Direction row 50 records it as the trust plane's design, and row 51 places it first in §5. It is written for the founder and the external reviewer.

**Scope.** This is a redesign of the trust plane only. The capability plane gets its own design later (row 42). Nothing here is built. A figure with no named source is a target, not a measurement.

## 0. What this serves

The product is already written down in direction §1. The pitch of 10-27 (tag `pitch/2026-10-27`) also describes it, wherever the pitch still agrees with direction. Where the two disagree, direction governs (row 47).

> The same AI model can vibe-code a demo or engineer a product. Felix sits on top of your coding agents and makes them do the second.

| # | The product's promise (pitch, 10-27) | The trust plane's part | Left to the capability design |
|---|---|---|---|
| 1 | It keeps a list of what each project needs, including what nobody asked for | Verdicts are relative to the admitted list, not to "the tests". The list's denominator and its known gaps are printed (§4.6) | How needs are found, and how complete the list is |
| 2 | Each need gets a test written by an agent other than the one that did the work | Independence is recorded in three parts and checked against the need's minimum (§4.5) | Who writes each test, and under what lease |
| 3 | The test has to catch a planted bug before it counts | A checker counts only while it holds a qualification bound to its exact content (§4.4) | Which checkers to build or acquire |
| 4 | Code, not a model, decides when the work is done; only a passing test crosses something off | The acceptance rule (§4.6), applied by the authority (§4.8) | |
| 5 | Every bug that slips through becomes a new test | An escape reopens its need and suspends the checker that missed it (§4.4) | Turning an escape into new needs |
| 6 | Felix works out what engineering the work takes and hands it to agents in short sessions with only the tools each one needs | | Dispatch and leases |
| 7 | CI runs your existing tests; Felix decides which tests the work needs and who writes them, whatever model wrote the code | CI counts as evidence only when its instrument is the authorized one (§4.4) | Choosing the tests |
| 8 | The number driven down is how often a person has to step in | Every part of the trust plane | Every part of the capability plane |

**What changed since draft 4.** The reviewer accepted draft 4's direction and found three gaps in its specification:
- A newly discovered need had no way to bind the change that prompted it.
- The acceptance rule mixed landing obligations with release obligations, which could deadlock a need about a deployment.
- The applicability table left one combination undefined.

The reviewer also found three implementation hazards:
- A checker could change without its workflow file changing.
- Side effects outside the repository cannot be observed from inside it.
- A suspended checker had no defined scope or repair path.

Draft 5 changes four things. A need is checked at the transition whose subject it is about (§4.6). A new need binds through an admission transaction that lands before the implementation (§4.2). Every applicability combination is defined (§4.3). An instrument is everything its check executes (§4.4).

Draft 4's own base stays: Felix already enforces most of the state model in `lib/obligations.sh`, `lib/exceptions.sh` and `lib/escape.sh`, and this design builds on that.

## 1. Open questions stay open, and closed types fail closed

The rule from row 46 still holds. An example is written as an example, a count says what it counted, and a question outside this draft's scope is recorded as open, with where it belongs. No acceptance test or headline number rests on one instance of an open set.

There is one place where closing a set is right: a type that Felix itself defines. The states and reason codes in §4.2 are decisions, not facts about the world, so they are closed by design. Any value outside them reads as UNKNOWN, and UNKNOWN blocks. The open-set rule is about the world. A type of Felix's own is closed, and anything it does not cover fails closed.

## 2. The directions, as budgets

The directions are an open list.

| | Budget |
|---|---|
| **Speed** | Developer sessions do not wait on checking: they hand off and leave. Felix's added time to done and to landed is a measured objective, reported as P50 and P95 per kind of change, with queue delay and cost, and set once step 5 has measured it. Its lower bound is T ≥ max(W/P, L): total checking work over parallel capacity, or the longest serial path, whichever is larger |
| **Accuracy** | The trust plane makes two claims, kept apart. First, the declared contract ran completely on the exact combined revision with qualified checkers. Second, how complete the contract is, which stays the capability plane's open question. Outside text says a change was checked within a stated fault model, over a printed number of cases, with the residual listed (row 36) |
| **Efficiency** | These are measured scaling objectives, not invariants. Evidence is reused while every input it recorded is unchanged, and rerun when any input changes or when its inputs are not known. Measured: authority work per change against the change's size and the suite's size, and reruns per PR (2.4 today) |
| **Security** | The authority runs hosted, under its own identity. A change never supplies its own judge (§4.1). An irreversible transition needs its evidence first (§4.8). The deny floor holds on every platform Felix supports |
| **Autonomy** | Founder interruptions per session fall, from 31% of turns in the September pilot and 36-50% in the second batch, depending on the counting rule. A person is asked only for an identity, authority or irreversible call. Every false block counts as a potential interruption and is measured (§9) |
| **Commercial viability** | The customer's cost with Felix plus Felix's fee is below their cost without it, counted on equal outcomes. Felix's tokens on the customer's key are reported, and hosted compute is measured as Felix's cost of goods |

**When budgets conflict:**
- The declared contract is never run in part and then called green.
- A budget is not exceeded silently.
- Latency is what gives: the change waits, with a status that names what holds it.
- If that happens often, fix the check or split the change.

## 3. What the trust plane owes the capability plane

**This redesign does not design the capability plane.** It leaves room for it in three ways:
- The verdict unit is the admitted need.
- The shared record (§5) carries what the capability side will read back.
- The residual review (§4.7) is not discovery, and the receipt says it saw only its packet.

**Admission is the trust plane's.** Its states and permitted transitions are specified here (§4.2), because the authority to make a need binding lives on this side.

**Open, for the capability design:**
- how needs are found and how complete the list is;
- who supplies and writes each checker;
- leases and dispatch;
- discovery beyond what is already known;
- turning escapes into new needs.

## 4. The trust plane

### 4.1 The judged change never supplies its own judge

The authority takes one thing from the candidate change: the subject, meaning the revision. It takes everything that judges that subject from the authorized policy version, which is the authority's own copy at the target branch's landed state. That includes:
- the admitted needs, with their `applies` and evidence commands;
- their classes and pathways;
- exceptions;
- the qualified checker versions;
- CI workflow definitions;
- the gate and the suite's manifest;
- any other input the authority turns out to read. This list is enumerated from what the authority actually reads, not written down in advance.

A change that touches any of these inputs is a policy change. It is judged under the policy it would replace, and by the policy-change rule:
- Tightening lands on green.
- Loosening an escape table goes to a person (`lib/escape.sh`).
- Changes to the judge's own artifacts wait for the founder until roadmap step 15 pins the judge outside every change it judges (row 38).

Felix already works this way in places:
- exceptions are read from the remote-tracking main;
- loosened table rows escape;
- a branch's `gate.sh` binds only after it lands.

This design makes it the rule for every input. Reviewer issues B, C and D, and part of A, come down to this one invariant.

### 4.2 States, and who may move them

These are the states Felix holds today in `lib/obligations.sh` and v3.2 §3, kept separate, never collapsed into one status:

| Axis | States | How it moves |
|---|---|---|
| **Lifecycle** | CANDIDATE, ADMITTED, REJECTED, SUPERSEDED | **CANDIDATE to ADMITTED:** by v3.2's pathways: deterministic policy, witness-backed, or corroborated discovery. A single probabilistic finding stays advisory and cannot take a blocking class. A critical unknown holds on authority. Rows 27 and 40 bound derived and shadow-admitted rows.<br>**ADMITTED to SUPERSEDED:** only by a person, since removing a row escapes. Loosening a row in place escapes. Tightening lands |
| **Applicability** | ACTIVE, DORMANT, UNKNOWN | Derived on every run and never stored (amendments §1.4). A crash, exit 126 or exit 127 reads UNKNOWN |
| **Discharge** | SATISFIED, UNSATISFIED, UNKNOWN | Derived from evidence valid for the subject (§4.4). Exit 2 ("cannot examine") reads UNKNOWN |
| **Exception** | present, absent | Present only for TASK_BLOCKING, from the remote-tracking main, unexpired and keyed to the row's content hash. An expired, malformed or moved grant reads as absent |

Receipts keep these apart with a reason code, so a failed checker never reads as an unrun one. The reason codes so far are:
- `failed`: the checker ran and said no.
- `could_not_examine`
- `not_run_for_subject`: no valid evidence exists for this revision.
- `applicability_unknown`
- `dormant_both_sides` (§4.3)
- `subject_removed` (§4.3)
- `excepted`
- `exception_expired`
- `admission_pending`: the task opened a proposal that could become blocking, and it is not resolved (§4.2).
- `checker_suspended`: the checker's qualification is suspended for this scope (§4.4).
- `instrument_changed`: the candidate changed part of an instrument's closure, so its own result is not evidence (§4.4).

The set is closed by design (§1).

**Admission before acceptance.** A new need can bind the change that prompted it, without letting that change approve itself.

Take a change that adds money transfers, where the work shows that a retry must never duplicate a transfer. The current policy P says nothing about that. Admitting the need and accepting the implementation are separate events, taken in this order:
1. **Proposal.** The capability side proposes the need, together with a checker for it. If the proposal's pathway could make it blocking, the task holds, and its implementation cannot land until the proposal is resolved (`admission_pending`). A single probabilistic finding stays advisory and does not hold the task.
2. **Admission.** The need and its checker go through the trust side as their own policy change, judged under P. Adding a need tightens policy, so it lands under the admission rules (rows 27 and 40). The authority runs the checker's qualification itself, against seeded violations, and never takes the candidate's word for it.
3. **Acceptance.** The implementation is then judged under P′, which is P plus the admitted need.

Both events can serve one user objective, but neither approves the other. This is also how any new checker or stricter rule takes effect: it lands as a policy change, judged by the policy before it, and binds from then on.

### 4.3 Applicability is judged on both the base and the candidate

Dormancy is real. It is derived between landed states, and it keeps the ledger from growing forever. What it may not do is let a change make its own needs dormant.

So when a change c is judged against its base b, applicability is read on both sides, each time with the policy's own `applies` command. Every combination has a defined result:

| Base \\ Candidate | ACTIVE | DORMANT | UNKNOWN |
|---|---|---|---|
| **ACTIVE** | ACTIVE | ACTIVE, `subject_removed` | UNKNOWN |
| **DORMANT** | ACTIVE | DORMANT | UNKNOWN |
| **UNKNOWN** | ACTIVE, with the unknown base listed | UNKNOWN | UNKNOWN |

The precedence:
- If the candidate reads UNKNOWN, the result is UNKNOWN.
- If the candidate reads ACTIVE, the result is ACTIVE. An unknown base is listed, and it changes nothing about what the candidate has to show.
- If the candidate reads DORMANT, the base decides: ACTIVE gives `subject_removed`, UNKNOWN gives UNKNOWN, and DORMANT gives DORMANT.

**UNKNOWN applicability blocks on its own.** No evidence result can override it, because a checker cannot answer whether a need applies here (§4.6, clause 1).

**How `subject_removed` is cleared.** Either the need's evidence still holds on c, or the removal is authorized:
- For TASK_BLOCKING and RELEASE_BLOCKING needs, the task's admitted intent, admitted before the work began, names the removal.
- For AUTHORITY_BLOCKING needs, the founder authorizes it (row 48).

Once the change lands with that authorization, the need goes dormant in the normal way.

**The reviewer's example.** A reroute hides an endpoint from discovery. Its authentication need was ACTIVE on the base, so it stays ACTIVE for this change. Its evidence then cannot find the endpoint, which reads `could_not_examine`, and the change blocks.

**An `applies` command is a checker too.** It is read from policy and bound to its version. It is qualified on seeded cases where the subject still exists but has moved or been renamed.

### 4.4 Evidence, and when it counts

**An evidence record holds at least these fields** (the reviewer's set, open to more):
- subject;
- instrument, meaning the checker with its version and its closure;
- policy epoch;
- execution provenance;
- environment;
- the inputs it read;
- independence (§4.5);
- result, cases and residual.

**An instrument is everything its check executes, not the file that names it.** A workflow can stay byte-identical while the check it runs changes. Suppose it runs `npm test`, and the candidate rewrites the test script to always succeed. The judge has changed and the workflow has not.

So an instrument's closure includes:
- the scripts it runs;
- test discovery and its configuration;
- the dependencies it executes;
- the toolchain versions it needs.

That closure comes from policy (§4.1). It is recorded from what the check actually read and ran, through the I/O gateway, not from a list.

**Instrument and subject stay apart.** The authority has to read and run the candidate's code, because that code is the subject under test. Doing so never makes it part of the judge: the check runs the policy's instrument closure over the candidate's subject.

Some files mix the two. A package manifest, for example, holds both dependencies and the test script. A change to such a file is treated as a policy change to its instrument parts, and the policy's version of those parts is the one that runs. How each ecosystem's mixed files split is open, and is worked out per ecosystem.

**A record counts for a decision when all of the following hold:**
- Its subject is the decision's subject.
- Its instrument closure matches a qualified version that policy authorizes.
- Its policy epoch is the current one.
- Its provenance is one the worker cannot forge: the authority's own run, or a provider run the authority read directly.
- None of its recorded inputs has changed.
- Its independence meets the need's minimum.

**Customer CI.** A CI result counts when the run executed the authorized instrument closure on the exact subject.
- If the candidate changed any part of that closure, its own result is not evidence (`instrument_changed`).
- In that case the authority runs the authorized closure instead, and the change goes through the policy-change rule.
- A green status check alone does not show which checks ran.

**Qualification is bound to the closure's content.** A checker that was edited, or whose closure changed, starts unqualified.

**An escape suspends what it demonstrates, and no more.** When a defect slips through, the evidence that passed it is marked as having missed a real defect. The need stays UNSATISFIED until a requalified checker catches the escape. What else is suspended depends on what the escape shows:

| The escape shows | What is suspended |
|---|---|
| One evidence record was wrong, for example a run on stale inputs | That record |
| The checker version misses this fault class | That version, for that class (the default) |
| The checker is wrong wherever it is used | Every use of that checker |
| The qualification method passed a checker that does not discriminate | The method, for that class, and the checkers it qualified |

**Repair is independent.**
- The authority qualifies a replacement or repaired checker, with the escape itself among its seeded violations, and the checker must still catch the old ones. A broken checker never certifies its replacement.
- The repair lands as a policy change (§4.2). The fix for the defect waits only for that repair, and is then judged by the requalified checker.
- Other changes whose needs relied on the suspended scope block until the repair lands, and how long requalification takes is measured.

### 4.5 Independence, in three parts

| Part | What it records |
|---|---|
| **Identity** | A different agent wrote the checker than the producer |
| **Context** | What the checker's author saw: the requirement alone (blind), or the implementation as well |
| **Authority** | Who can change the checker or its qualification; never the worker being judged |

Felix's checker-trust rules carry over unchanged (0ak; amendments §2):
- decoupled violation and decoupled satisfaction;
- a coverage report naming what was examined;
- mutations authored by something that has not seen the checker.

**The minimum is a property of the need**, set by its class and stakes, never by how simple the change looks (row 44). The proposed default: blocking needs at B3 and above require context separation, and every other need requires identity separation.

### 4.6 Transitions, and the acceptance rule

A need's class says how hard it holds. Its subject says when it is checked. Each need names the subject its evidence is about, using §5's typed subjects. Each transition requires every applicable blocking need about the subject it creates or changes. This removes the deadlock: a need about a deployed service is never required before the merge that the deployment depends on.

| Transition | Its subject |
|---|---|
| A task completes | The implementation revision |
| A merge that reaches no external effect | The combined revision |
| An artifact is built or released | The artifact |
| A deployment | The deployed artifact |
| Continued operation | The operational outcome |

The class decides the rest. Only a TASK_BLOCKING need can carry an exception, and only before release (amendments §3). For an AUTHORITY_BLOCKING need, the founder is the one who clears a wrong hold.

**The rule at one transition.** Let T be a transition with subject s, under policy epoch P, from base b. T may proceed when all of the following hold:
1. **Applicability is known.** No blocking need about s has an effective applicability of UNKNOWN (§4.3). This condition stands on its own: no evidence result can override it.
2. **Required needs are met.** Every blocking need about s whose effective applicability is ACTIVE is SATISFIED by evidence valid for s (§4.4). A TASK_BLOCKING need before release may carry a valid exception instead.
3. **No authority hold applies.** No need with pathway `unknown` applies. An exception does not clear one.
4. **No admission is pending.** Every admission the task opened is resolved (§4.2).
5. **Every input came from P.** If T's change touches any of P's inputs, the policy-change rule (§4.1) has passed.
6. **Residual limits are answered.** The residual limits of the satisfied evidence are listed. At B3 and above, each has the founder's answer (row 39, 10-31 decision 5).
7. **Every reachable effect is within T's authority** (§4.8). A merge that reaches a deployment is a deployment transition, and the deployment's rule governs it.

**Until the release subsystem exists,** every release or deployment transition fails closed, including a merge that reaches one. The one way through is a founder-controlled release path, on which he authorizes that release by name (decided 11-07). Release authorization is never taken from ordinary merge authorization.

Every receipt prints each need's state and reason code, together with the list's denominator: what was examined, out of what.

Today's blocking filter, `felix_obligations_blocking`, implements clauses 2 and 3 at the task and release moments. The authority lifts that filter and adds subject typing, two-sided applicability, clause 1 as a separate condition, clause 4, evidence validity, and clauses 5 to 7.


### 4.7 The worker side, before submission (advisory)

**Class rules go in the brief.** Each rule carries its evidence record:
- fault class;
- enforcement;
- coverage;
- counterexamples;
- discrimination;
- residual.

Instance assertions become a rule's seeded violations, and they retire only on that evidence (decision 6).

**Checks run against a fault model stated in tiers.** The list of tiers is open, and none of them is exhaustive. So far:
- a fault at each site, with sites enumerated from what the change actually runs;
- a crash between each pair of durable writes;
- concurrency on shared protocols, checked at the protocol level;
- contract tests that hold the boundary fakes to the real tools.

**Mutation targets the change's own lines.** When it samples, it discloses the population, the sample, the survivors and the untested remainder.

**One residual model review** covers a small packet.

**A wrong skip here can only delay a change.** Only the authority lands, so a missed check here cannot land anything the declared contract catches.

### 4.8 The authority, and reversibility

**The authority is hosted, with its own GitHub App identity.** Workers hold tokens that cannot push to main. The authority runs once, on the combined revision in the queue, one change at a time per branch.

**Reversibility belongs to the transition and everything it reaches, not to the commit.** A merge is a deployment transition if it does any of these:
- triggers a deployment;
- publishes a package;
- runs a workflow with production credentials;
- writes to an outside system.

That holds however much a revert could undo.

**What the authority can observe, and what it cannot:**
- **Observed.** The authority can read the repository's own automation definitions: its on-merge workflows, with the environments and secrets they use. It can also read branch protection, and every surface the provider's API lets its identity read. These are enumerated from what is readable.
- **Not observable from the repository.** External webhooks, installed apps, cloud deployment integrations and organization-level automation can respond to a merge without being defined in the repository. Effects from these are declared in policy by whoever controls them, and authorized separately.
- **Anything else.** A surface that is neither observed nor declared counts as an unknown effect. An unknown effect counts as irreversible, and §4.6's interim rule fails the merge closed.

This will cause false blocks at first. They are measured, and declarations reduce them. Incomplete observation is never turned into a claim that a merge is reversible.

**Merge authorization and deployment authorization stay separate decisions** inside the one authority.

**Still open (direction §6):** whether landing and releasing are separate steps when a merge reaches no effect.

## 5. The shared record

**What it is.** A minimal typed contract for provenance and dependencies, written from v3.2's types. It is not a shared computation graph: worker-side caching stays private and advisory.

**What it holds:**
- needs, with their states from §4.2;
- checkers, with their content hash, independence and qualification;
- evidence, with the §4.4 fields;
- decisions, with their epoch: subject, topology, policy and release target;
- escapes, each recorded against the receipt that let it through.

**Properties:**
- **The schema is versioned.**
- **Records are append-only.** A correction is a new record that points to the old one, and provenance is never rewritten.
- **Every record names its inputs.** Each kind of record states its invalidation rule, so the question "does this still apply" is answered by a lookup.
- **Each field has one writer.** The capability side proposes needs, supplies checkers and leases, and records cost. The trust side admits needs, qualifies checkers, records evidence and decides transitions.

**Evidence subjects are typed.** So far: an implementation revision, a built artifact, a deployed artifact, and an operational outcome. Evidence about one subject never discharges a need about another. Code that passes does not show the deploy succeeded, and a successful deploy does not show the workflow still works. The later release and operations subsystem uses this same need-based model across those subjects and introduces no separate notion of success.

**The edges:**
- Hooks are thin adapters for sessions Felix did not start, PowerShell included.
- The plugin is the install channel.
- The queue is provider-neutral, and hands the final merge to GitHub's merge queue once felix-home is in an org.

## 6. How Felix builds itself

felix-home is customer zero.
- Its 90-minute bash suite is its own CI, not a cost the product adds for a customer.
- Slice 0's 21.5 hours are what the method cost when it ran as serial rounds, which is why slice 0 is the benchmark.

§4.1 applies here first. Felix already reads exceptions from the remote main and binds a branch's `gate.sh` only after it lands. Other inputs the gate and CI read, such as the workflow definitions and the suite's parts, still come from the candidate tree. Step 3 enumerates them from what the gate actually reads.

**The fixes:**
- The queue owns landing, taking CI runs per PR from 2.4 toward 1.
- The suite is sharded once its parts can run alone.
- The suite shrinks only as class rules are qualified and needs go dormant.

**The language.** Direction row 6 keeps the engine in bash. A Rust kernel would amend that row, which is the founder's call, after the spike.

## 7. Budgets and the governor

The user sets the budgets: model tokens a week, runner minutes, local CPU and agents at once.

The load governor (#487) spends the trust plane's share in this order:
1. the declared contract and class rules, which are never cut;
2. the fault tiers and mutants;
3. the residual review.

When a budget is short, nothing is skipped silently. The unchecked parts are listed in the receipt, and at B3 and above they go to the founder. Running an authorized workflow in place of a changed one (§4.4) draws on runner minutes, and that is reported.

## 8. Slice 0, read correctly

**Time.** 1,156 agent-minutes in total, split as follows:

| Stage | Agent-minutes |
|---|---|
| Review | 380 |
| Blind assertions | 321 |
| Fixes | 296 |
| Red checks | 138 |
| Final part checks | 21 |

Adding the 135 minutes when no agent was running gives 21.5 hours of wall time. The build itself took 2.9 hours.

**Findings.** Slice 0 had 46 findings. Eight properties cover 42 of them; the other 4 are hygiene and wording. Of the 46:
- 43 had a mechanical detector, though 7 of those still needed a lead decision;
- 3 were found only by a model or the lead.

These figures are Felix's own classification and have not been independently replicated. They are also retrospective. Naming a detector after a failure is known does not show that the detector would have been designed, chosen or run before the failure. They describe one feature, in one language, on one project.

The per-property reading from draft 3 stands as a proposal for step 1 to test.

## 9. Order, and what each step measures

1. **Replay slice 0 against two sets.**
   - The **held-out set** decides whether the method advances. It contains violations and omissions the method was not built against, authored blind, not drawn from slice 0, and from more than one ecosystem. Its bar is fixed before it runs, and it reports what it spans and how much a small set can show.
   - The **historical set** measures regression coverage and cost.
   - Both track **false positives**, since every false block can become a founder interruption, and **implementation effort**.
   - Passing on a small held-out set advances the method to a prospective trial on new features (row 39). It does not settle the method.
2. **Write the specification:**
   - the record contract (§5), with versioning, append-only provenance and explicit invalidation rules;
   - the state machine and the admission transaction (§4.2), and the full applicability table (§4.3);
   - evidence validity, instrument closure, and the scope and repair of suspensions (§4.4);
   - transitions, subject typing and the acceptance rule (§4.6);
   - the observability boundary (§4.8).

   Then map today's files onto it. `lib/obligations.sh` and `lib/exceptions.sh` are its first implementation.
3. **Separate the authority.** Enumerate every input it reads and move each one to the policy source (§4.1). Measure whether a worker can still land around it, or change the instrument that judges it.
4. **The queue owns landing.** Measures CI runs per PR and session idle time.
5. **Shard felix-home's suite.** Measures W, P and L, and sets the speed objective.
6. **Build the class-rule catalogue,** each rule with its evidence record. Measures pass rate, false blocks and checking time per feature.
7. **Run the Rust spike,** then ask the founder the language question.
8. **Add incremental reuse at the authority, then batching,** each behind its own gate. Reuse depends on §4.4's recorded inputs being complete. Where they are not, evidence reruns.
9. **Release and operations,** on §5's typed subjects.

The capability lane continues as decided on 10-19. The capability plane's own design comes after this one (row 42).

## 10. Kept, changed, dropped

| From draft 4 | Verdict |
|---|---|
| The acceptance rule over classes | **Changed.** A need is required at the transition whose subject it is about. Its class says how hard it holds (§4.6) |
| Release "built later" | **Changed.** Until the release subsystem exists, a release fails closed or takes a founder-controlled release path |
| The applicability table | **Changed.** Every combination is defined, and unknown applicability blocks on its own |
| New needs | **Added.** An admission transaction lands before the implementation, so a discovered need binds the change that prompted it (§4.2) |
| The CI instrument as its workflow file | **Changed.** The instrument is its whole closure, recorded from what the check actually ran |
| Side effects read from repository definitions | **Changed.** Each effect is observed, declared or unknown, and an unknown effect blocks |
| Suspending a checker after an escape | **Changed.** The suspension is scoped to what the escape shows, and repair is independent |
| `subject_removed` authorization | **Decided** (row 48) |
| Everything else in draft 4 | **Kept** |

## 11. Open risks

These are the risks seen so far. More will come.
- **Two-sided applicability may hold legitimate removals.** Authorization from the task's intent keeps most of them away from a person. The founder interruptions it does cause are measured.
- **Running the authorized workflow** in place of a changed one costs runner minutes.
- **The reason codes** may need new members. Each one is added by design, and anything they do not cover reads UNKNOWN.
- **Enumerating every input the authority reads** is itself work that can miss something. An input found later moves to the policy source when it is found.
- **Unknown side effects block.** Treating unknown effects as irreversible may block merges on repositories with complex automation.
- **Small held-out set.** The held-out set will be small, so its result is a signal, not a verdict.
- **Earlier open risks remain:** the residual review's narrow packet, sharding, a full run per change, the floor on Windows, and the size of a Rust port.
- **Every need must name its subject.** Older rows that name none are read as being about the implementation revision, and this reading is listed in the receipt.
- **Admission holds can slow a task** when proposals pile up. The time a task spends held is measured.
- **The closure is only as good as the gateway.** Recording an instrument's closure depends on the I/O gateway seeing everything a check executes. Anything it misses is a gap in the judge.
- **Mixed files** need a split for each ecosystem, and that split is open.
- **Declared external effects** are only as current as the people who keep them.
- **Self-review.** This draft can still settle something it should not. §1's check is the guard.

## 12. The founder's calls

| Call | State |
|---|---|
| The same machine rigor for every change | Confirmed (row 44) |
| Felix becomes infrastructure, and the authority is hosted | Decided (row 43) |
| The capability plane's own design | Later (row 42) |
| Who may authorize a `subject_removed` need: the task's admitted intent for TASK_BLOCKING and RELEASE_BLOCKING needs, the founder for AUTHORITY_BLOCKING ones | Decided 11-07, row 48 ("Task intent; you for top") |
| How a release or deployment proceeds before the release subsystem exists: it fails closed unless the founder authorizes it by name | Decided 11-07 ("Yes, as proposed") |
| Whether landing and releasing are separate steps when a merge reaches no side effect | Open: to be tried natively |
| How Felix is sold: a lower cost per change, or more reliable delivery at a similar cost | Open: positioning |
| The language (row 6) | After step 7's evidence |
