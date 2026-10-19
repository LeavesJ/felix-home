# How Felix turns a vague idea into a production-ready build, and keeps getting better

Design, 2026-10-19. Written at the founder's request of that day: how Felix can
decide deterministically what to build, why, what to watch for, how the work
separates, and how it adapts and improves itself, when all a person gives is a
few sentences of grand scope.

**Standing.** This is a design on file, not a build target. `docs/direction.md`
§7 lists it. Every part below still needs the founder until it has run
unattended, once, on two ecosystems. Only its first slice (§9) is proposed for
the capability lane, as need-side intake, and the founder's decisions in §11
come first. "Production-ready" in the title is the founder's question, not a
claim: §8 says why Felix never prints it.

How it was made: four inventories of what is built and specified, three blind
designs (compiler, adaptation and recursion, adversary), one refuter for each,
and a synthesis. Every engine line it cites was re-read against the tree
before it went on file.

Status key used throughout: **built** means it exists in the engine at 655606cf (0.49.299). **Specified** means it is written in v3.2, the amendments, the 10-18 thesis or the 0cw handoff, and is not built. **New** means it is proposed here for the first time. Nothing in sections 2 to 9 runs today unless it is marked built.

## 1. The answer

Felix is deterministic about the frame and leaves the content to models. The frame is everything that decides:
- which facts count;
- which product and risk questions are owed;
- what each surface obliges;
- which proposed architectures are admissible;
- which units of work exist, in what order and with what isolation;
- what holds a release;
- which changes to Felix's own tables may land without a person.

Each of these is a pure function of recorded inputs, and a stranger can replay it offline from the repository plus a receipt bundle. The content is everything that needs judgement:
- the reading of the person's sentences;
- candidate obligations;
- alternative architectures;
- code;
- checkers, written under a different lease from the code;
- drafts of new rows for Felix's own tables.

Rented models write all of it as typed answer files through the provider protocol (built, `lib/commission-provider.sh`). The engine validates those files and classes their contents as INFERRED.

A model's output may add obligations and holds. It may never ground a blocking row by itself, and it may never lower anything. Grounding comes only from two sources: what the person DECLARED through a channel a session cannot write, and what probes OBSERVED.

The person decides three kinds of thing:
- **taste:** product shape where readings conflict, and feature order;
- **authority:** channels, credentials, accounts, money, and any lowering of assurance;
- **irreversible commitments.**

So "Felix stays deterministic" is true of every deciding step, which is what constitution invariant 2 actually requires: no model on the enforcing path. "Felix designs architectures" is also true, in the sense v3.2 invariant 4 allows. Felix owns what an architecture must make true and which designs qualify. The host owns how, inside the admissible set.

Recursive improvement is the same frame turned on Felix's own tables:
- An outside miss is classified mechanically to the table that lacked a row.
- A model drafts a class-level row.
- Blind fixtures and the base engine test that the row would have prevented the miss.
- The row enters with no force.
- Only additions to tables whose additions narrow may ever land without the founder.
- The rules of the loop itself are never earnable.

## 2. The pipeline

| # | Stage | Intermediate record | Who decides | Deterministic check | v3.2 home | Status |
|---|---|---|---|---|---|---|
| 0 | Bind | `projects/<p>/project.json` (name, remote, gate, maturity), seeded tables, `.felix` | Person at a TTY. The engine writes the files. | Maturity comes only from a TTY or `FELIX_MATURITY`. No subcommand writes it (`felix:1189-1192`). | §8 step 1 | built (binds an existing directory only; creates no repository) |
| 1 | Capture scope | `projects/<p>/decisions.tsv`: typed person decisions (scope sentences, envelope values, product forks, reserved choices). Session prompts go to a memory-root provenance log that nothing on a widening path reads. | Person | The writer reads only a TTY, as maturity does. Every change to `decisions.tsv` escapes at merge. It is in the commission table set, so it moves `policy_version` and the epoch. | Reality Projector, DECLARED (§2) | new |
| 2 | Interpret | Answer file of INFERRED rows (feature, non-goal, axis lower bound, planned surface), each citing the decision row and the exact words it reads | A model proposes; the engine classes | Cited words must appear in the cited row. Values come from the axis vocabulary. Readers that disagree make the axis UNKNOWN. An answer keyed to an old decisions hash reads stale. | Discovery Workers propose; Admission Kernel classes (§1, §4) | new, on the built protocol |
| 3 | Materiality and questions | For each axis or product fork: immaterial, material (question owed), or decided. Plus the set of held units. | Engine computes; person answers | Environment predicates use only `>=`. An axis is material iff the blocking obligation set at its inferred lower bound differs from the set at its top. A fork between proposals is material iff the two blocking sets cannot be ordered by containment and the difference traces to one decision row. When an evaluation touched an UNKNOWN class, the result prints "materiality undecidable". | §4 "asks only when ... materially changes the engineering contract"; §14 idea-stage eval | new |
| 4 | Project topology | Facts: OBSERVED from probes, DECLARED planned surfaces from `decisions.tsv` only, and relation facts for declared minus observed | Engine | Probe states and witnesses as built. If the detector does not name a capability, it reads **could not look**, never absent. Absence must be witnessed by a probe that grounds the capability and reads empty with a witness. | Reality Projector, Situation Engine (§2) | probes, facts, epoch built; DECLARED surfaces and the absence rule new |
| 5 | Situation compile | Each class ACTIVE, DORMANT or UNKNOWN with grounds; candidate needs; a residual of could-not-look, unbound predicates, cells with no row, and members no role maps | Engine | `templates/situations.tsv` uses a restricted, monotone predicate grammar, never shell. The strictest row per cell wins. Each row cites a provider text by digest (`coverage.tsv`) or an outside miss by hash. The residual is printed beside every count. | Situation Engine (§1), Baseline Coverage Compiler (§9) | coverage.tsv specified (docs/2026-09-18-ecc-against-v32.md §5.1); situations.tsv new |
| 6 | Open-world discovery | Candidates, stamped probabilistic | Models propose; the engine validates | Built rules in `lib/candidates.sh:79-131`: a candidate is refused if it is blocking, ungrounded, or has no evidence. Corroboration means an offline-verified citation or a failing witness that the engine itself runs, never model agreement. | §9 open world, §10 budgets and stop rule | single pass built; budgets and stop rule specified, not before March (direction §5) |
| 7 | Admit | Rows in `obligations.tsv`, with derived applicability | Person's commit today | A probabilistic row never blocks. UNKNOWN blocks. Shrinking the ledger escapes. Dormancy is derived (`lib/obligations.sh:133-253`). | Admission Kernel (§4), Obligation Ledger (§3) | ledger built; pathways 1-3 as code specified |
| 8 | Supply | Supply state per blocking row: a qualified instrument, an instrument unit, or a person route | Engine computes; models author checkers and mutations | Controls 1-6 (`lib/qualify.sh:73`); control 7 is absent. A row with no supply prints as unsupplied, never silently. | Capability Manager (§7), amendments §2, thesis I2 | partly built (felix project only); binding specified |
| 9 | Architecture | k proposals in a fixed schema, plus the attribute table the engine computes for each | Host proposes and chooses within the admissible front; person decides irreversible differences and reserved kinds | Admissibility (section 5) and a Pareto filter over computed attributes. The choice is recorded with deltas against the alternatives. | Host (invariant 4); Policy (§1); §7 reuse first | new |
| 10 | Units, order, isolation | Unit set recomputed on read from the committed plan and the need ledger; never stored as authority | Engine | Coverage both ways: every blocking need maps to a unit, and every unit cites an intent or a need. Then topological order, then isolation rules (section 4). | Execution Coordinator (§1, §13 step 8; thesis R1) | `lib/shape.sh` partition built; the rest new |
| 11 | Dispatch | Leases | Engine computes the lease; host enforces it | Lease no wider than the need; the floor is advisory and only raises; no verdict reads a model id | Capability Manager leases (thesis I3-I5) | specified; trust-gated (direction row 25) |
| 12 | Execute and reconcile | Diff, receipts, re-projected facts | Host decides method; engine decides acceptance | Gate, probes, obligations, the escape boundary, and the Stop hold that ignores narration (built). Writes must fall inside the unit's declared paths (new; catches paths only). | Evidence Kernel (§5) | built, except the scope check |
| 13 | Release | READY/HOLD/ESCALATE, SHIP, post-deploy verify, then COMMIT or ROLLBACK/ESCALATE; a headline with residual | Engine; person for irreversible acts | READY only when every ACTIVE blocking row has a valid receipt for this target. UNKNOWN never reads green. | Release state machine (§11) | specified; tree receipts built |
| 14 | Outcomes | Outcome rows keyed by unit id, or by merge commit plus PR number | Engine only | Labels come from mechanical joins only (section 7) and need a lag. Quiet is never a label. | §12, §14; thesis I6; 0cw item 6 | specified (provider side); demand side new |
| 15 | Improve Felix's tables | Miss record, gap kind, drafted row, blind fixtures, replay receipt | Engine validates; the founder owns every loosening and every promotion before the judge pin | Section 7 | §12 "explicit update path" | new |
| 16 | Triggers | Trigger log, including checks that fired nothing | Engine computes; a person's tick fires them until a schedule grant exists | Enumerated list (section 6) | Thesis I7; amendments §1.3 | specified |

## 3. One worked example, end to end

The sentences: "A site where students review courses anonymously. Students should see reviews for courses they are considering. Later, an AI summary of each course's reviews."

1. **Bind.** `felix new -d <dir>` (built) asks maturity at the TTY. The founder answers public-beta, so maturity is DECLARED from the first minute and needs no question later. Creating the repository is the first substrate unit. Making it public is a disclose act, so it is the founder's.
2. **Capture.** The founder runs `felix scope` at a TTY. The three sentences become decision rows d1, d2 and d3; d3 is tagged for a second increment ("later").
3. **Interpret.** Two readers answer an `intent_interpreted` request. They agree on F1 (post a review), F2 (read reviews by course), user content as free text, and a public audience. All of these are INFERRED. They disagree on who may post: anyone, or signed-in students shown without a name. That fork is UNKNOWN.
4. **Materiality.**
    - The traffic band leaves the same blocking set at every value at public-beta, so it is not asked.
    - "Who may post" yields two blocking sets that cannot be ordered by containment. Anyone: an abuse ceiling on anonymous writes, a takedown path, spam control. Students: write requires identity, the reviewer link is never exposed, identity retention is bounded. So exactly one question goes out, batched at session end and phrased as outcomes: "Anyone with the link: Felix builds abuse limits and a takedown path and keeps no identities. Only signed-in students: Felix adds university sign-in and guarantees no review can be traced to its author, including through logs and backups."
    - Units whose trace contains this fork are held. The skeleton, the course schema and the read routes proceed.
    - The founder picks students, and it becomes a decision row.
5. **Situation compile.**
    - Two classes go ACTIVE on DECLARED grounds before any code exists: authenticated public write, and identity linked to user content.
    - public_http stays a DECLARED planned surface until a route probe reads found.
    - A provider citation (for example ECC security-review's rate-limit lines, by digest) corroborates the write ceiling.
    - Residual: takedown requests and accessibility have no citing source, so they print as cells with no row.
    - Under section 1's rule these are candidates until admitted. The blocking ones go to the founder as one admission batch, so the founder approves rows rather than writing them.
6. **Discovery.**
    - One pass proposes small-cohort re-identification: in a three-person seminar, a review identifies its author. It stays ADVISORY. A second model agreeing would not change that.
    - It becomes corroborated only with a verified citation, or with a constructed witness the engine runs: a fixture course with three reviewers whose author can be inferred.
    - If the founder admits it, the method of satisfying it (hold reviews until k reviewers, or publish aggregates only) is a product fork that cannot be ordered, so it is a second question. It is not a Felix default.
7. **Architecture.**
    - Proposal C adds the AI summary now. That unit cites d3, which belongs to increment 2, so C is refused for increment 1.
    - Proposals A (framework, Postgres, university OIDC) and B (TypeScript, a managed database with row-level security, a vendor auth service) are both admissible.
    - B keeps accounts at a vendor whose export is partial, which is an irreversible commitment. So the choice goes back to the founder, phrased as what each option commits to. Otherwise the host's pick within the front would be recorded as a default the founder can overturn.
8. **Units.** U0 is the skeleton: the release target's verification instrument (CI calling the gate, the gate shown failing, a preview deploy with a health read). Then, in order:
    - checkers written before the code;
    - the schema;
    - sign-in;
    - the write route with its ceiling;
    - read routes;
    - the log scrub;
    - a qualify unit;
    - release.
    Sign-in and the write route share the auth middleware, so they run in one context.
9. **Release headline** (specified): "live URL; 3 decisions you made; 2 defaults you can overturn; 9 of 10 owed obligations have receipts valid for their explicit claims on revision r; 1 UNKNOWN holding; residual: 2 cells with no source." The word "proven" is not used, because amendments §6 still applies: one authority writes both the work and the judgement of it.
10. **Adaptation.**
    - The founder moves d3 into the current increment by a decision commit, which moves the epoch.
    - The tree gains a model SDK, so the observed money floor rises to paid-upstream with no question.
    - The paid-inference class goes ACTIVE: spend ceiling, request ceiling, and containment of review text sent to the vendor.
    - Sending users' text to a vendor is an external-side-effect fork, and its strict reading contradicts the feature, so it is a question.
11. **Recursion.**
    - After launch, someone re-identifies a reviewer from precise timestamps. The founder records it as an incident through the person channel, and it becomes a miss against "reviewer link never exposed", which read SATISFIED.
    - Triage: the probe saw the route, the row existed, and the checker passed on the miss tree. That makes it an instrument gap.
    - The incident becomes a qualification mutation the checker must fail. Every receipt built on that checker goes stale.
    - Separately, a model drafts a class-level row: public fields or ordering that link content to a small cohort. It must pass the blind fixtures in section 7 before it enters, and it enters at ADVISORY.

**Rust distributed system.** "A membership service where nodes gossip and serve a client API."
- Today `felix_detect` reports `rust` but not `api`. The api pattern at `lib/detect.sh:78` names only Python and JS frameworks, so axum is invisible to it.
- Under the absence rule, the client-HTTP classes read **could not look** and are printed in the residual. They do not read DORMANT. They go ACTIVE only after a founder-authored probe grounds the client listener.
- The classes that matter are peer versus client listener, replicated state, durable log, and wire-protocol and on-disk-format versioning. None exists yet. Seeding them is a precondition (section 8).
- The skeleton is the release target's verification instrument: a remote soak node read as a remote probe. A health URL is not enough.
- Irreversible commitments are format and protocol changes, which are catalog classes, not path channels.

**The bash harness.** "Make the gate faster."
- The enforcing-path-change class fires on the verifier channel. It owes qualification, and CPU rather than wall-time measurement.
- The release target is the engine deploy, already covered by the admitted `engine_deployed` obligation and `bin/deploy-check` (built).
- The residual prints "no manifest: dependency surface could not be read", never "0 owed".
- The harness cannot be the only bash reference, because classes mined from Felix would then be validated on Felix. A second, unrelated bash project is required (section 7).

## 4. Separation of tasks

Units are derived from the architecture and the obligations. A model writes none of them.

**Two planning levels.**
- The **component plan** is selected once. It covers components, interfaces, reserved choices, and the assignment of each owed row to a component.
- The **unit plan** is drawn only for the next slice, and only after the previous slice's topology is observed. The model does not have to claim every feature at unit granularity up front.
- A slice is the smallest dependency-closed prefix that meets three conditions:
    - it delivers one declared feature, or one owed obligation, end to end;
    - every blocking row in it has a supply state;
    - it needs no open reserved choice.
- If no such prefix exists, the first return is a typed authority grant, not unverifiable work.

**Fields.**
- Each unit has an id: the hash of its kind, its component, and the ids of the obligations and decision rows it serves. Utterance spans are excluded from the id, so a re-reading does not change it.
- The model writes:
    - writes (path globs, taken from the realization after the skeleton exists);
    - provides and consumes (named interfaces);
    - discharges, with evidence kinds;
    - external effects.
- The engine computes:
    - **Consequence class:** the maximum of the `risk.tsv` tier and channel over the writes, the enforcement class of what the unit discharges, and the class's budget. It may only rise.
    - **Assurance:** at B2 and above the checker author is a different lease from the builder; B3 adds a blind mutation author and a constructed witness. Blindness is read from lease records once leases exist. Until then readings are marked same-context and capped at ADVISORY.
    - **Owner:** Felix, or the person for channel acts and reserved choices. Person acts are batched into one return.

**Order.**
1. Fixed phases: substrate, instruments, implementation, qualification, release.
2. Within a phase, a topological sort over consumes-after-provides and component edges.
3. Ties break on higher consequence first, then on id.

The host may propose a split, merge or reorder of units as a typed answer. The engine accepts it if coverage between obligations and discharge units still holds and no lease widens.

**Isolation.**
- Units that share a write are one context (the transitive union in `lib/shape.sh`, built).
- Units that share a coupling surface are one context. Coupling surfaces are per-ecosystem adapter rows: a manifest, migrations or an env template for a web app; a Cargo workspace, `build.rs`, feature flags or proto files for Rust; a shared sourced library for bash.
- An interface between two units with no fixed contract gets an interface unit inserted before both sides.
- Evidence units never share the implementing unit's context.

**Reconcile.** A diff outside the declared writes task-blocks the unit until a re-plan. This catches paths only. A route added inside an allowed file is caught later, as a relation between the declared provides and the observed members, and only once an adapter exists for that stack.

**Re-planning** is a diff, never a regeneration:
- newly ACTIVE needs append units;
- needs that went DORMANT cancel unstarted units and mark started ones "no longer owed";
- in-flight leases may only be raised.

**Grand scope.**
- Subsystems are cut along trust-boundary edges, and each cut edge becomes an interface obligation on both sides.
- Each increment is a release target, so it carries its own epoch through the `release_target` component (`lib/epoch.sh:154`, built).
- A scope that spans several repositories has no representation today; the epoch subject is one checkout. This is a stated gap.

## 5. How "best" is chosen

"Best" is not a score a model assigns. It has three layers, all computed.

**1. Admissibility** (a hard filter run by the engine). A proposal is refused, with the gap named, if any of these fails:
- (a) Every current-increment decision row is cited by a unit that carries an acceptance check. This reverse coverage means an intent cannot quietly vanish.
- (b) Every ACTIVE or UNKNOWN blocking need has a discharge path naming an evidence kind the Evidence Kernel accepts.
- (c) Every unit traces to a decision row or an obligation, and none implements a non-goal.
- (d) Every channel act and irreversible commitment is listed, and none falls on a channel the envelope does not declare.
- (e) The plan is acyclic and schema-valid.

**2. Attributes** (computed, never read from the proposal):
1. Unauthorised irreversible commitments: identity export, data residency, wire or storage format, public API contract, schema lock-in.
2. Blocking needs that would read UNKNOWN or could-not-look, because no adapter or qualified checker class exists for that stack. Counted at least as heavily as ACTIVE needs, so a stack Felix cannot see does not win by looking empty.
3. Returns to the person (channel acts).
4. New providers not already in `stack.tsv` (§7, reuse before adding).
5. Units at B3 and above.
6. Critical-path length.

**3. Choice.**
- The engine keeps the Pareto front over these attributes. Within the front the host chooses: a competent local choice, per invariant 4.
- The choice goes back to the person when front members differ in an irreversible commitment, or when the person reserved that kind of choice.
- Otherwise it is recorded as a decision default with the delta to each other front member, and the person can overturn it.
- The attribute definitions are a founder-owned policy table that escapes on any change, because changing them changes which design runs.

There are no weights and nothing to tune. The rule does not judge elegance, performance or idiom; the host and the person own those.

Known bias: attribute 2 favours stacks Felix can instrument. The counterweights:
- declared constraints filter first;
- the decisive attribute is printed;
- architecture overturns are counted for the founder's review.

The same pattern covers model choice. Felix publishes an advisory, raise-only floor by consequence. The host rents the cheapest model above it (decision D1). Whether adaptive routing exists at all is decided by the held-out replay's predeclared rules (0cw item 2).

## 6. Adaptation of the project over time

Posture is recomputed, never stored. Each change marks stale only what is downstream of it.

**The envelope.** Each axis is an ordered domain with three kinds of value:
- **OBSERVED floors** are rows in an envelope-floor table. For example: a model SDK in the dependency manifest sets money to at least paid-upstream; a deploy probe plus a route probe set the public-HTTP fact. Floors raise the effective value with no question.
- **A DECLARED value** may lower the effective value, but never below the observed floor. A declaration below the floor holds release as a critical UNKNOWN (pathway 5).
- **INFERRED values never move the effective value.** They only seed the default suggested in a question. "Exposure" is not an envelope axis; it is the OBSERVED or DECLARED public-HTTP fact.

**Maturity behaviour** (v3.2 §8) is applicability, not code branches. Rows read effective maturity:
- post-deploy verification and rollback from public-beta;
- restore drills and availability from production.
Derived dormancy switches them on and off, the same way the ledger already refuses stored ACTIVE-to-DORMANT transitions (amendments §1.4).

**Topology.**
- A new surface appends its role's probe rows only through a founder-authored commit. Probes stay founder-authored (`lib/probes.sh:61-64`). A model may file a probe template as an ADVISORY ticket.
- A surface that was declared and then not observed after its unit finished holds as UNKNOWN for one epoch, then follows topology, so the §14 "endpoint removed" case goes DORMANT through grounded state.
- A swapped instrument (`facts.sh` reports "instrument changed", built) stales the receipts that depended on it.

**Triggers** (thesis I7). The list is enumerated, and every fire and every check that found nothing is recorded:
- a decision commit;
- an answered question;
- a change in the situation signature (the set of classes active for this project and their states, not probe counts);
- a new surface;
- a raised floor;
- a stale receipt;
- an UNKNOWN entering a release window;
- a post-deploy probe failure;
- a closed outcome window.

A person's tick fires them until a schedule grant exists (amendments §1.3; schedules are not before March). Keying on the situation signature means a commit that adds a test re-runs nothing.

**The world.**
- When a provider text's digest changes, the citations resting on it go stale.
- Dependency and provider pins stale dependent receipts (§7 step 7, specified).
- A change of model stales nothing (trust invariance).

## 7. Recursive self-improvement of Felix

**What exists today.** Six loops exist, and each closes only through a person or only on Felix's own hygiene:

| Loop | Where | What closes it |
|---|---|---|
| Gate failure, recurrence, promote | `lib/memory.sh:492`, `felix:5306`, `lib/next.sh:182-203` | A person writes the lesson. There is no efficacy measure. |
| Lessons mounted by token overlap | `lib/lessons.sh`, `hooks/user-prompt` | Nothing measures them. |
| Debt trigger after a gate catch | `lib/guard.sh:150` | A session writes a lesson or a log line. |
| Ledger retire list | `lib/ledger.sh:234-255` | A person. The list is route-keyed and confounded. |
| Router learning from declines | `felix route --ack/--promote` | A person. Router precision is about 2%. |
| Five-merge GREEN streak | `lib/automerge.sh:20` | Mechanical, but the label it counts is applied by hand. |

Specified and unbuilt: the outcome record (0cw item 6, thesis I6), the earned-autonomy record with a lag (08-14 §3.1), the authority-change kernel (08-14 §4a), the full judge pin (Phase 0b step 15), and the sealed seeded-omission corpus. Nothing in the engine edits a situation table, budget or procedure from outcomes.

**What is new here** is a demand-side loop. It improves what Felix thinks projects owe, not only Felix's own habits.

**Three levels.**
1. **Project obligations.** Governed by sections 2-6.
2. **Felix's tables.** These may learn:
    - situation rows and coverage citations;
    - qualification mutations, meaning the ways each checker has been fooled;
    - envelope floors;
    - default kinds;
    - moments;
    - budget assignments;
    - lessons promoted into mechanism.
3. **The improvement machinery.** This covers:
    - the gap classifier, the replay, and the list of label sources;
    - the promotion and demotion thresholds, the lag window, and the metrics;
    - the attribute definitions;
    - the escape classification of each table.

    It joins `FELIX_TRUST_BASE` (`lib/land-table.sh:97`) and gets a channel, so every change escapes to the founder. That must ship in the same PR that adds the libraries, because today the `^engine/harness/lib/` risk row carries no channel and T1 (refusing unattended landing on the trust base) is unbuilt. Until then the loop is report-only. That is an ordering of the build, not a property already in place.

**Signals.** Labels come only from mechanical joins, never from commit or PR text:
- a revert sha;
- the same obligation id reopened;
- the same probe member at a later tree;
- a failed post-deploy probe row;
- a person-channel incident;
- a founder-named need whose class predicate already held at its epoch;
- the sealed corpus.

Outcomes join on the merge commit plus the PR number, not the land ledger. On 10-19 the land ledger held 25 rows and 0 merges: every merge so far went through a session or the founder, so the ledger has no outcomes to join. A success counts only after the lag window, 14 days to match `felix_mem_recurring_mistakes`. The absence of an incident is never a label. A label computed by Felix's own checkers carries a same-authority mark and cannot alone justify force.

**Triage.** A walk down the trace at the miss tree, in this order. The first step that fails names one gap kind:
1. Probe: was the surface enumerated?
2. Vocabulary: did the member map to a role?
3. Situation: was there a row for that cell?
4. Severity: was the class blocking at this maturity?
5. Admission: did a candidate exist but was never admitted?
6. Instrument: did the checker read SATISFIED on the miss tree?
7. Staleness: was a receipt accepted after an input outside the tree changed?
8. Interpretation: was the decision misread?
9. Otherwise the miss is unclassifiable. It is printed with the residual as the vocabulary's own gap report.

**Proposal and validation.** A model drafts one class-level row through the provider protocol, or the founder writes it. The engine then checks five things:
- **Vocabulary lint:** the row may use only capability tags, roles, axes and need tokens, and may name no project or framework (constitution invariant 1, extended).
- **Prevention, not truth.** At the miss tree, the owed need's instrument, or a failing witness the engine runs mechanically, must read UNSATISFIED. If no instrument exists the result is UNKNOWN and the gap kind becomes instrument. A predicate that is merely true at the miss tree does not pass.
- **Blind fixtures.** A lease that never saw the proposer writes the expected classes from the miss record. It also writes at least two positive and two negative sibling fixtures per ecosystem, including one where the grounds are present but the obligation does not apply (a cluster node that must bind every interface). These are stored in the memory root or under `projects/felix/`, scrubbed of project paths. Only synthetic fixtures live under `engine/harness`.
- **Exposure:** how many governed projects the row would newly activate, printed as a false-positive estimate.
- **Determinism:** two runs produce identical bytes with the network off.

**Admission path**, staged under direction row 25:

| Change | Before control 7 and the judge pin | After both |
|---|---|---|
| New ADVISORY situation row or qualification mutation | Lands on green: it is an addition to an additive table and cannot block | Same |
| Promotion to TASK_BLOCKING | Founder | Felix may append an enforce row if the base engine's one-time recount meets thresholds fixed in advance (the pending Decision 2(b), widened) |
| Promotion to RELEASE_BLOCKING | Founder | Founder |
| Any edit to roles, axes, probe adapters, decisions, defaults or attribute definitions | Escapes: these tables are shaped like exemption tables, where an addition can widen (`escape.sh:89-112`) | Same |
| Any removal, lowering, narrowed applicability, or a question turned back into a default | Founder, with a replay attached, batched into one weekly return; a decline is recorded through `felix route --ack` | Same |
| An ADVISORY row with zero confirmed catches across N windows drops to INFO | Automatic: it widens nothing enforcing | Same |
| A discovery budget lowered on cost evidence when archive and corpus recall do not drop | Founder until March (no budgets exist before then) | Allowed: a budget is not an obligation, so §6 item 5 does not apply |

Once recounted in its PR, an enforce row's force does not depend on evidence stored in the memory root, so deleting that evidence demotes nothing.

**Engineering detail.** Learned template rows must enter each project's epoch. The policy component gains a digest of exactly the template rows that derive something for that project. Then a template change stales only the receipts it affects, and a deploy cannot change a blocking set inside an unchanged epoch. Adding a basename to `FELIX_COMMISSION_TABLES` (`commission.sh:52`) would hash a per-project file instead, which is not what is needed.

**Guards.**

| Risk | Guard |
|---|---|
| **Ratchet.** Rows grow until everything blocks. | Rows enter with no force. Force needs independent, lagged catches across at least 2 projects in at least 2 ecosystems. A cap on shadow rows per class. ADVISORY rows decay to INFO automatically. The printed and bounded figure is the false-block rate, not the row count. |
| **Self-grading.** | The proposer never writes the labels or the fixture expectations. The replay checks prevention. The base engine judges tables now, and engine code after the step-15 pin. Same-authority labels cannot be the sole witness. |
| **Goodhart on the archive.** | The sealed corpus is the only scorer of "better". If open-archive recall rises while sealed recall stays flat, autonomous landing of new rows is suspended. Without the corpus, Felix may add ADVISORY rows but may never claim it improved. |
| **Drift.** | Every table is in a digest that moves the epoch. Each row records the miss or citation it came from. A quarterly replay of current against old tables over the same recorded trees prints the change in ACTIVE blocking rows and false blocks. |
| **Founder load.** | Questions per objective and returns per session are printed beside recall. Rising questions with flat recall is a falsifier. |
| **Cost.** | Proposals fire only on a recorded miss, never as a standing "what am I missing" call (rejected in 08-11 §7). Replay is bash over logs with no tokens. Model replays run only on the corpus, under the founder's ceiling. |
| **Cross-tenant poisoning.** | Learning crosses projects only within one home. Crossing homes is a maintainer template release, never automatic. |

**Lessons.** Efficacy is measured by date: distinct-tree recurrence of the failure before and after the lesson. A lesson whose failure recurs after its date becomes a miss of kind "habit, not mechanism", which proposes a situation row, a deny row or a gate check. This extends `lib/next.sh:182-203`, which says "build the mechanism" today without ordering by date.

**Build side.** The founder asked about recursive improvement of builds, not only of obligations. Per unit, Felix records:
- declared versus actual writes;
- the re-plan count;
- rework of a slice;
- lagged success.

These feed the predeclared decision rules of the held-out replay. They never feed autonomous changes to decomposition or to the attribute definitions, because those are non-monotone and belong to the founder.

## 8. Guards against slop and against grand-scope failure

| Failure | Guard |
|---|---|
| A model silently resolves ambiguity toward convenience | INFERRED never moves the effective envelope. A material fork is asked once, and units hinging on it are held. A lowering needs a person-channel decision that escapes at merge. |
| A session forges the founder's consent | Decisions come only from a TTY writer plus an escape on `decisions.tsv`. Session prompts are provenance only and never feed a widening path. The machine-prompt filter (`lib/route.sh:246`) leans toward "a person typed it", so it is not trusted for authority. Stated as tamper-evident, not tamper-proof (floor and wall). |
| A plan that looks complete but drops a cross-cutting obligation | Obligations come from the situation compile over facts, independently of the plan. The coverage join refuses a plan that leaves any blocking need unclaimed. |
| A plan that drops what the founder asked for | Reverse coverage: every current-increment decision row is cited by a unit that has an acceptance check. Uncited rows print as "intent not realised". |
| Felix or the host adds scope nobody asked for | The trace rule. A unit implementing a non-goal is refused. |
| A closed vocabulary reads as "owes nothing" | Detector silence is could-not-look. The residual sits beside every count. The bash fixture must print a non-empty residual. Before seeding, roles and axes are drafted against all three ecosystems at once, and anything web-only is printed as web-only. |
| "0 unresolved" over a small list | The headline carries M of N, K UNKNOWN, and residual R. "Production-ready" is never claimed; receipts are "valid for their explicit claims". |
| A grand scope compiles into a plan nobody can verify | Two-level planning, trust-boundary cuts, increments as release targets, a slice rule that requires supply, and an authority grant before any unverifiable work. |
| A declared low maturity hides real exposure | Observed floors. A contradiction holds release as a critical UNKNOWN. |
| Correlated proposers | Disagreement becomes UNKNOWN and is never averaged. Codex read-only is a second-family reader at B3 and above (decided, direction row 19). Model agreement never corroborates. |
| A plan misdeclares what it touches | The write check on the diff. A mismatch voids the selection and is recorded per worker class. |

## 9. The first buildable slice

**Name:** situations owed, report-only, with admission drafts.

It is need-side intake. Under direction row 25 it waits on no trust milestone. It changes no verdict, calls no model, and writes no enforcing table.

**What it builds:**
1. **`engine/harness/templates/situations.tsv`.** Columns: `class`, `applies`, `owes`, `class_by_maturity`, `source`.
    - `applies` is a conjunction of `probe:<cap>=<state>`, `cap:<name>` and `env:<axis>>=<value>`.
    - Every row's `source` is a provider citation digest or a miss hash, never a project name.
    - Seed about six rows from recorded misses and v3.2 §10. Example: public ingress plus a paid outbound call owes a request and spend bound. That is the rate-limit omission three authors made, and Elenchus's second entrypoint. The founder's commit authorizes the seed (amendments §1.1).
    - Draft the role and axis vocabulary against all three ecosystems before seeding.
    - One new `schemas.tsv` row, which is an addition and therefore free.
2. **`lib/situations.sh` and `felix situations [--at <tree>]`.**
    - Evaluates three-valued over `facts.log` at a recorded tree.
    - A capability with no grounded probe, or one the detector does not name, reads could-not-look.
    - Prints each class with its grounds, then: examined N, active A, dormant D, could-not-look U (named), unbound predicates, cells with no row.
3. **`felix situations --propose`.** For each ACTIVE class with no admitted row, prints an `obligations.tsv`-shaped row with grounds, plus the command to admit it. Admission stays the founder's commit; the founder approves rather than writes. The proposed rows are never committed by a session on its own, because an addition to `obligations.tsv` would land on green.

**Acceptance.** The assertions are authored blind from this text and shown red on main first.

- **(a) Python web fixture:** `requirements.txt` naming fastapi and anthropic, one POST route, an `http_route` probe.
    - Today: one dormant row, nothing owed. This is the inventory's sandbox walk.
    - After: the paid-ingress class is ACTIVE with grounds `http_route found (api), llm detected`, and `--propose` prints the row.
    - Delete the route: the class is DORMANT, with the witness named.
- **(b) Rust fixture:** a cargo workspace whose member depends on axum, with no probe grounding api.
    - The HTTP classes read **could not look**, never DORMANT.
    - Add a probe row that grounds api: the class goes ACTIVE.
    - A negative fixture (a cluster node that binds every interface) activates no loopback-binding class.
- **(c) Bash harness (third check):** a non-empty residual, never an empty report with exit 0.
- **(d) Determinism:** identical bytes twice, network off, no key.
- **(e) Real data:** one run each, on Elenchus's and Veldra's recorded facts. Elenchus's second-entrypoint spend gap must appear as an ACTIVE class with a proposed row. Whether an admitted row then reads SATISFIED depends on a qualified checker, which this slice does not provide.

**Done means** (a)-(e) are green in the suite, felix-home's gate is green, and the slice's own gap is stated: classes needing a capability tag that does not exist (plugin hooks, peer listeners) read as cells with no row.

**Next slices:**
2. `misses.tsv` and `felix retro`: the first three gap kinds, the prevention-form replay, blind fixtures.
3. The outcome record, lane item 7.
4. Binding derived rows into enforcement, with the epoch digest of section 7. This is the one that needs founder decision c.

**How it lands.** It is an engine PR in the red tier, built through spec, blind assertions, red first, review, then gate. It rides behind the rule against starting a new engine branch while more than 10 engine PRs are open. It does not add names to the escape or commission sets; that comes with slice 4, as a founder-carried PR.

## 10. Falsifiers

1. **Recall:** on the sealed corpus, catalog plus one pass finds no more planted omissions than a plain session on the strongest host with memory on, or a second-family session, and holds them no better across a restart. Then standing intake adds nothing (thesis I1).
2. **Determinism:** replaying a compile from the repository plus its bundle on a clean machine, with no model, changes any decision, obligation, unit id or order.
3. **Selection is narration:** paraphrased prompts or a second model family change the admissible front while the computed attribute rows stay the same.
4. **Materiality:** Felix asks a question whose answers leave the blocking set unchanged, or takes a default where they differ. Or the founder reverses defaults above a bound declared before the run.
5. **Blindness:** a Rust or other stack whose detector is silent reads DORMANT instead of could-not-look on any HTTP-keyed class.
6. **Class versus instance:** more than half of the confirmed real misses cannot be stated as a class-level row that passes the blind sibling fixtures without naming a project.
7. **Ratchet:** over a quarter, blocking rows per unit and positively evidenced false blocks rise while independently labelled catches and sealed recall stay flat. Or questions per objective rise.
8. **Self-grading:** any enforce row is accepted with only same-authority labels, or any label traces back to the component it grades.
9. **Widening without the founder:** any removal, lowering, narrowed applicability or default reversion lands without the escape firing.
10. **North star:** an obligation activated by an observed floor rise fails to hold an incomplete release in a session that never mentions it, or fails to go dormant when its grounding surface is removed.

## 11. What needs the founder

Each item is architecture-level and has a recommended answer.

- **a. How your words become binding.** Recommended: scope and decisions enter only through a terminal command a session cannot run on your behalf, and any change to them stops at merge for you. What you type in sessions is kept as provenance; it may make Felix more careful, never less. What changes: you type `felix scope` or `felix decide` in a terminal for the few things that bind.
- **b. Ambiguity.** Recommended: Felix asks each material ambiguity once, phrased as outcomes and batched. Meanwhile it builds everything that does not hinge on the answer and holds only the release. It never takes a less careful reading without you. What changes: a few more questions up front, and no silent product decisions.
- **c. Rules derived from a surface bind without a per-row commit.** Recommended: yes, at task scope only, after control 7 and the judge pin. Release-blocking stays yours. Until then Felix prepares each row and you approve it in one word.
- **d. Felix learns its own rulebook.** Recommended: new rules may land on their own at advisory strength now. Task-blocking force follows the pending Decision 2(b) after the pin, decided together with it. Every loosening is yours, batched weekly with its replay.
- **e. Learning across projects.** Recommended: within your home, yes. Across other people's homes, only through a maintainer release, never automatically.
- **f. How Felix learns.** Recommended: never on its own. The classifier, replay, label sources, thresholds and the definition of "best" stay yours permanently.
- **g. Reserved choices.** Recommended set: creating an account or spending money; holding people's identities; vendor, protocol or storage-format lock-in; anything touching the authority kernel. Felix and the host settle everything else and tell you what was picked.
- **h. Pending consent.** The sealed corpus spending ceiling. Recommended: grant it. Without it, Felix may tighten its rules but can never claim it got better.

## 12. Rejected from the three designs

**From the compiler design:**
- Every UserPromptSubmit prompt as the authority log: the machine filter fails toward "typed", and the memory root can be forged.
- An INTERPRETED class, and two agreeing readers founding DECLARED roles: this breaks v3.2 §2.
- Maturity defaulted to "the strictest value without a channel act": Felix picking an envelope value, against anti-slop row 5.
- Felix picking the stack by a lexicographic order: replaced by a Pareto front plus the host's choice (invariant 4).
- Role, adapter and axes additions treated as free tightenings: those tables are exemption-shaped.
- `situations.tsv` added to `FELIX_COMMISSION_TABLES` by basename: it would hash a per-project file and leave template changes outside the epoch.
- Fleet-wide autonomous tightening before the pin: Felix-authored admission ahead of row 25.
- Regression cases cut from product trees into `engine/harness`: breaks invariant 1 and the public snapshot.
- First-slice step (e) with a deliberately withheld row: the test could not fail.
- Budget "raised for a window": either a widening by Felix or a hidden ratchet.
- Unit ids hashed over utterance spans: re-readings churn the outcome join.
- The k=5 cohort threshold as a Felix default: a product fork that cannot be ordered, so it is a question.

**From the adaptation-recursion design:**
- Effective envelope = max(observed, INFERRED): model output alone would ground blocking rows.
- "Exposure" as an envelope axis: it is an observed fact.
- Appended intent rows superseding earlier ones: a widening by append.
- `units.tsv` in the memory root read by Stop and the gate: an unsigned authority file.
- Learned template rows outside the epoch.
- Replay E1 as "the predicate is true at the miss tree": it tests truth, not prevention.
- Preference key "fewest ACTIVE classes": it punishes learning and rewards blindness.
- Labels from commit or PR text links: the host would decide its own labels.
- The land ledger as the outcome join: 0 merges recorded there.
- "The improvement machinery sits in the trust base" stated as built: T1 is unbuilt.
- Acceptance test (a) fitted to a known answer.

**From the adversary design:**
- An origin flag "human-typed" on prompts: the hook payload has no such field.
- Span-cited readings classed DECLARED: they are INFERRED.
- Second-family agreement as corroboration toward TASK_BLOCKING: breaks trust invariance and §4 pathway 3.
- The proposer writing its own fixture expectations: self-grading.
- Autonomous ceiling raises and question growth with only founder relief: a friction ratchet.
- Cost inadmissible for lowering a discovery budget: a misreading of §6 item 5.
- A miss archive in `engine/harness/tests/misses` naming projects: breaks invariant 1.
- Irreversibility computed from path channels only: web-shaped.
- Skeleton = deploy plus health probe: web-shaped.
- Whole-product plans claiming every feature at unit granularity up front: contradicts slice re-planning.
- Separation of duties claimed from lease and authorship records that do not exist.
- Felix as the only bash reference fixture: an instance validated on its own source.