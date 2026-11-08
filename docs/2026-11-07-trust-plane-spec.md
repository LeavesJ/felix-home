# Felix trust plane: the specification, part 1 of 3

2026-11-07. Step 2 of the trust-plane design, which direction row 50 made final. The design is filed as `docs/2026-11-07-trust-plane-design.md` on branch `claude/direction-fold-2026-11-07` (PR #490) until that lands; the same text is in the memory root at `designs/2026-11-06-trust-plane-revisit/design-draft-5.md`. A section written §4.2 is the design's. A section of this specification is written "part 1 §3".

**Revision 1, 2026-11-08.** Step 1 of the design replayed slice 0 against a blind held-out set (18 defective subjects and 18 clean twins, in bash, Python and TypeScript, one run per subject). It did not advance the method: 5 of the 18 clean twins drew a false block against a limit of 4 (memory root, `audits/2026-11-07-trust-plane-step1/report/step1-report.md`, §6). This revision carries the three method changes that report names, each a Felix call: a stated model for each need (S7, MD1 to MD9 in part 2 §1.8), spec oracles as a checker kind written blind to the implementation (SO1 to SO7 in part 2 §5.2), and a review packet that carries no findings (PK1 to PK5 in part 2 §5.3). The first version of this specification, #493, was written in parallel with step 1 and has none of them. Part 2 §5 is new. Whether the method advances to the prospective trial is decided by a pre-registered rerun and not here (part 2 §5.4).

The specification has three files, each under 500 lines:
1. **This file:** scope, conventions and closed types, the record contract, states and admission, and applicability.
2. **`docs/2026-11-07-trust-plane-spec-evidence.md`:** evidence and its validity, a need's model, escapes and suspensions, transitions and the acceptance rule, the observability boundary, and the method's contract.
3. **`docs/2026-11-07-trust-plane-spec-mappings.md`:** today's engine mapped onto this specification; which steps of direction §5 the design's steps 3 to 9 replace and which stay; the decisions this specification made; and what it leaves open.

**What this is.** It says what the trust plane's records, states and transitions are, precisely enough that step 3's build and its blind assertions can be written from it without the design beside it. Each rule has an id, such as S4, for tests and receipts to cite. Design questions are Felix's, so this document is Felix's. It rests on the founder's decisions in direction rows 48 to 51 and changes none of them. Where it reads a direction row, it says "by Felix's reading".

**What it binds, and when.** This document builds nothing, arms nothing and changes no engine file. Each rule binds from the design step that builds it, report-only or in shadow first, under the arming rules already decided:
- No row is armed before control 7 and the judge pin (roadmap Phase 1; amendments §2.1 and §2.3).
- Derived rows bind within row 27's bounds, and row 40's classes after their shadow.
- How much Felix may block is the founder's call (`lib/qualify.sh`, header).

Until a rule is built, today's engine stays the enforcing path. Part 3 §1 maps what it already enforces.

## Scope

**In scope:** the five parts that design §9 step 2 names:
- the record contract (§5): versioning, append-only provenance, explicit invalidation rules and typed subjects (part 1 §2);
- the state machine and the admission transaction (§4.2), and the whole applicability table (§4.3), `subject_removed` included (part 1 §3 and §4);
- evidence (§4.4): validity, instrument closure, instrument against subject, mixed files, CI counted only with the authorized closure, and the scope and repair of suspensions (part 2 §1 and §2);
- transitions (§4.6): subject typing, the seven-clause acceptance rule, and the interim rule that releases fail closed (row 49) (part 2 §3);
- the observability boundary (§4.8) (part 2 §4);
- the method's contract (§4.7), as far as a need's model, the spec oracle as a checker kind and the review packet touch it (part 1 §2.1 and S7; part 2 §1.8 and §5). The method is advisory: no decision reads a worker-side record (R11).

Independence (§4.5) appears only as far as evidence validity reads it.

**Out of scope, each recorded as open in part 3 §4 with where it belongs:**
- the capability plane (row 42): how needs are found, who writes each checker, leases, dispatch, and turning escapes into new needs;
- the release subsystem itself (design step 9) and the queue (step 4);
- the hosted authority's deployment and identity (step 3, row 43);
- each ecosystem's split of mixed files, and the I/O gateway's implementation;
- every numeric budget, bar and bound, which measurement or the founder sets;
- the wire encoding beyond part 1 §2.7;
- whether landing and releasing are separate steps when a merge reaches no effect (direction §6).

## 1. Conventions and closed types

**K1. A type Felix defines is closed.** These are decisions, not facts about the world (design §1). The closed types are:

| Type | Members |
|---|---|
| Record kind | part 1 §2.1 |
| Subject type | `revision`, `artifact`, `deployment`, `operation` (part 1 §2.8) |
| Transition type | `task_complete`, `merge`, `artifact`, `deploy`, `operate` (part 2 §3.1) |
| Lifecycle | CANDIDATE, ADMITTED, REJECTED, SUPERSEDED |
| Applicability | ACTIVE, DORMANT, UNKNOWN |
| Discharge | SATISFIED, UNSATISFIED, UNKNOWN |
| Exception | present, absent |
| Class | INFO, ADVISORY, TASK_BLOCKING, RELEASE_BLOCKING, AUTHORITY_BLOCKING |
| Pathway | `deterministic`, `witness`, `corroborated`, `probabilistic`, `unknown` |
| Need-level reason code | part 1 §3.3 |
| Transition hold code | part 1 §3.3 |
| Evidence result | `pass`, `fail`, `could_not_examine`, `unknown` |
| Provenance | `authority_run`, `provider_read` (part 2 §1.5) |
| Independence context | `blind`, `saw_implementation` |
| Suspension scope | `record`, `version_class`, `checker`, `method_class`, `model`, and `lifted`, which ends a suspension (part 2 §2) |
| Effect class | `none`, `effect`, `unknown` (part 2 §4) |
| Checker kind | `class_rule`, `spec_oracle`, `fault_tier`, `instance` (part 2 §5.2) |
| Model reading | `inside`, `outside`, `unknown` (part 2 §1.8) |
| Domain form | `regex`, `range`, `set`, `length`, `keys` (part 2 §1.8) |

**K2. A value outside its type reads UNKNOWN, and UNKNOWN blocks.** A record holding such a value is UNKNOWN as a whole, not in part, unless the schema marks that field report-only (R5).

**K3. A member is added only by a new schema version** (R4), and that version lands as a policy change. A member that can only hold more is a tightening. A member that can let anything through is a loosening, and goes to a person.

**K4. The world's sets stay open.** Faults, effect surfaces, the inputs a check reads, and ecosystems are open sets. This specification writes their members as examples. Where a rule needs one of them enumerated, the enumeration is taken from what was observed, and whatever was not observed reads UNKNOWN.

**K5. Output is deterministic.** A receipt lists needs in ledger order and reason codes in the precedence of part 1 §3.3. Two evaluations over the same records print the same bytes, apart from their own stamps.

## 2. The record contract (design §5)

### 2.1 Record kinds

The design names five kinds: needs, checkers, evidence, decisions and escapes. Its own rules write seven more, and this specification gives each one a kind of its own, because each has a different writer and a different invalidation rule (decision D18, part 3 §3).

| Kind | What it holds | Writer |
|---|---|---|
| `need` | name, class, pathway, subject type, `applies` checker, evidence checker, grounds, minimum independence, reason, and optionally a model: the faults and inputs of the deployment the need is about (part 2 §1.8) | proposed by the capability side; its lifecycle is the trust side's (`admission`) |
| `admission` | one lifecycle move of one need: from, to, pathway, the qualification it rests on, the policy change that landed it | trust side |
| `checker` | one checker version: id, entry content hash, authorized closure, author identity, author context, the kind it claims, and for a spec oracle the requirement it was written from (part 2 §5.2) | supplied by the capability side; the authorized closure is the trust side's |
| `qualification` | checker version, fault class, method version and seeded set, with each seed's result | the authority |
| `evidence` | part 2 §1.1 | the authority |
| `decision` | one transition's verdict: type, subject, base, epoch, one row per need, each clause's state and codes, and the denominator | the authority |
| `escape` | a defect that got through: the decisions and evidence that passed it, its fault class, how it was found | trust side (a report from anyone is a candidate until recorded) |
| `suspension` | a scope from part 2 §2 and the escape it rests on | trust side |
| `exception` | need name, need content hash, expiry, granted by | a person, through the `exception` escape |
| `intent` | a task id and the needs whose subject it may remove (part 1 §3.5) | admitted on the policy source; who admits it is open (part 3 §4) |
| `authorization` | the founder's act: a removal of an AUTHORITY_BLOCKING need's subject (row 48), one release by name (row 49), or an answer to a residual limit at B3 and above (row 39) | the founder, landed on the policy source as a change of its own (T5) |
| `effect_declaration` | a surface the authority cannot observe, its effect class, the declarer, and the fingerprint of any part that can be observed | whoever controls the surface; a declaration of `none` also needs a person's approval (part 2 §4) |
| `lease`, `cost` | the capability side's own records | capability side; the trust side reads them as reports only |

### 2.2 The envelope

Every record carries these fields:
- `schema`, the kind and its version;
- `id`, the hash of the record's canonical bytes with `id` left out;
- `writer`, the plane and the identity the authority verified;
- `written_at`, together with whose clock it is;
- `supersedes`, a list of record ids, or `-`;
- `inputs`, typed references, each carrying the content identity of what it names;
- `epoch`, the decision epoch it was written under (v3.2 §3; `lib/epoch.sh`).

**R1.** A record that lacks an envelope field is malformed. A malformed record is not a record, so whatever needed it reads UNKNOWN.

**R2.** The `id` is computed and never supplied. A record whose `id` does not match its own bytes is not a record.

**R3.** An input is identified by its content, never by its name or path. A path whose bytes change is a different input.

### 2.3 Versioning

**R4.** Each kind has a schema version, an integer. A reader names the versions it can read, and a record of any other version is UNKNOWN to that reader, as a whole.

**R5.** No field is ignorable. Adding a field makes a new version. An unknown field might narrow what a record allows, and a reader that skipped it would widen. The one exception is a field the schema marks report-only, which no decision reads. The receipt shape already works this way: `lib/receipt.sh` versions its shape "so a reader can refuse a shape it does not know".

**R6.** A new version lands as a policy change, because it changes what the authority reads. Old records are never rewritten (R7). A reader for an old version stays until no current record uses that version.

### 2.4 Append-only provenance

**R7. Records are never edited or deleted.** A correction is a new record whose `supersedes` names the old one.

**R8.** The current record of a chain is the one that no record supersedes. If a chain has two current records, it has forked, and it reads UNKNOWN until one record supersedes both.

**R9.** A record may supersede only a record of its own kind, written by the same writer.

**R10.** Every decision names the ids of the records it read. Any decision can then be replayed from the store as it stood. How the store is retained or compacted is open (part 3 §4).

**R11. Where records live.**
- **The authorized policy** holds what judges: needs, checkers' authorized closures, exceptions, intents, authorizations and effect declarations. This is the authority's own copy at the target branch's landed state (design §4.1).
- **The authority's store** holds what it writes: evidence, qualifications, decisions, escapes and suspensions. No tree a worker writes is part of that store.
- **The worker side's own records** are advisory, and no decision reads them (design §4.7).

### 2.5 Invalidation rules

**R12.** "Does this still apply?" is answered by a lookup. The current identity of each input a record names is compared with the identity it recorded, and the store is asked for a record that supersedes or suspends it. No validity is decided by reading prose.

**R13.** If the inputs a record read are not known, it is invalid: it is rerun, never reused (design §2, efficiency).

| Kind | Holds while | Stops holding when |
|---|---|---|
| `need` | admitted and not superseded | an `admission` record moves it to SUPERSEDED. Applicability and discharge are never stored (S2, S3) |
| `model` (a field of `need`) | its need is admitted, its grounds still read as they did, its qualification holds, and no suspension of scope `model` covers it | any of those stops holding. The need then reads as having no model (MD2). The model is never reused or inferred |
| `checker` | its entry hash and its authorized closure are unchanged | any byte of either changes: that is a new version, and it starts unqualified (E13) |
| `qualification` | its checker version, method version and seeded set are unchanged, and no suspension covers it | any of them changes, or a suspension covers it (part 2 §2) |
| `evidence` | V1 to V7 hold (part 2 §1.4) | any one of them fails |
| `decision` | always, as a record of what was decided | it authorizes a transition only while the subject, base and epoch are still the transition's. Once the target moves, the combined revision is a new subject |
| `exception` | read from the policy source, keyed to the need's current content hash, unexpired and within the horizon | the need's row changes, the grant expires, or the policy source is in doubt (today's rules, `lib/exceptions.sh`) |
| `intent` | landed before the task began (part 1 §3.5) and not superseded | superseded |
| `authorization` | it names the transition's exact subject identity and target | the subject changes by a single byte, or the authorization was already used for another subject (D21) |
| `effect_declaration` | the observable part's fingerprint is unchanged, and the declarer's control still reads true where it can be read | either one changes (part 2 §4) |
| `suspension` | until a later `suspension` record with scope `lifted` supersedes it, naming the repair's qualification record (X6) | the repair lands. It never lapses with time |

### 2.6 One writer per field

**R14.** Each field of each kind has one writer, given in part 1 §2.1. The capability side proposes needs, supplies checkers and leases, and records cost. The trust side admits needs, qualifies checkers, records evidence and decides transitions. A person writes exceptions and effect declarations, and the founder writes authorizations, each through the policy-change rule.

**R15.** A record or field written by anything other than its writer is not read. If a decision needed it, that input reads UNKNOWN.

**R16.** A writer's identity is the one the authority verified: the provider's report of who landed a policy change, or the authority's own identity for the records it writes. A name a record states about itself is never its identity.

### 2.7 Encoding

This specification fixes the logical schema. The encoding on the enforcing path stays readable by bash and git (direction row 6; constitution invariant 2), with these properties:
- each kind has one canonical byte form, which is what gets hashed;
- no field holds a field separator, and the engine already maps tabs and CRs out of detail text (`felix_obligation_state`);
- a NUL byte anywhere makes a record unreadable (`lib/qualify.sh`).

Step 3 fixes the rest. A Rust port (step 7) has to read the same bytes.

### 2.8 Typed subjects

| Subject type | Identity | Created by |
|---|---|---|
| `revision` | repository and tree object id. It plays two roles: the **implementation revision** (a task's head) and the **combined revision** (that head merged onto the target's tip in the queue) | `task_complete`, `merge` |
| `artifact` | digest of the artifact's bytes, the revision it was built from, and the identity of its build recipe | `artifact` |
| `deployment` | artifact digest, target environment, and the deployment id the provider assigns | `deploy` |
| `operation` | a deployment identity, an observation window, and the outcome measure the need names | `operate` |

**R17.** Each need names one subject type. A need that names none is read as `revision`, and every receipt that reads it so says "subject read as revision" (design §11).

**R18.** Evidence about one subject never discharges a need about another subject, whether of another type or another identity of the same type. Code that passes does not show the deploy succeeded, and a successful deploy does not show the workflow still works (design §5).

**R19.** A revision's identity is its tree, not its commit (D1). Evidence about the implementation revision therefore counts for the combined revision exactly when the two trees are equal and no recorded input has changed, because then they are the same subject. Today's receipts are keyed on the tree for the same reason (`felix_tree_id`, `lib/verify.sh`). An input outside the tree goes into the evidence's `inputs` (R3), not into the subject.

## 3. States, and who may move them (design §4.2)

### 3.1 Four axes, kept apart

**S1.** Lifecycle is stored, as `admission` records. A need's state is that of its current admission record (R8).

**S2.** Applicability is derived on every evaluation, for each side (part 1 §4), and never stored (amendments §1.4).

**S3.** Discharge is derived from the evidence valid for the transition's subject (part 2 §1). The evidence record is stored. "SATISFIED" never is.

**S4.** Whether an exception is present is derived when the evaluation runs, from `exception` records on the policy source.

**S5.** No axis is written into another. No single status stands for two of them.

### 3.2 Lifecycle moves

| From → to | By | When |
|---|---|---|
| none → CANDIDATE | capability side, with a proposal | The proposal is well-formed. A model's finding is stamped `probabilistic` by the engine and never read from the model (`lib/candidates.sh`) |
| CANDIDATE → ADMITTED | trust side, by an admission transaction (part 1 §3.4) | v3.2 §4's pathways and rows 27 and 40 hold, and the authority has qualified the checker |
| CANDIDATE → REJECTED | trust side | The proposal is malformed, its pathway cannot carry its class, or a person rejects it. A failed qualification is not a ground (AD3) |
| ADMITTED → SUPERSEDED | a person only; the founder only, for an AUTHORITY_BLOCKING need or a need in row 40's classes | Removing a need escapes (the `verifier` channel today) |
| ADMITTED → SUPERSEDED, plus a new ADMITTED (an edit) | trust side when S7 says tightening; otherwise a person, or the founder where the old need is AUTHORITY_BLOCKING or in row 40's classes | S7 |

**S6.** No other move exists. A REJECTED or SUPERSEDED need never moves again. Proposing it again makes a new CANDIDATE that points back to it.

**S7. Strictness, for telling a tightening edit from a loosening one.** An edit tightens only when every field stays the same except one or more of these:
- the class is raised, in the order INFO < ADVISORY < TASK_BLOCKING < RELEASE_BLOCKING < AUTHORITY_BLOCKING;
- the minimum independence is raised, from identity to context;
- `applies` becomes `-`, which always applies;
- the model is removed, or one of its exclusions is removed (MD4).

Any other edit counts as loosening, because it cannot be compared mechanically. That covers the evidence command, the `applies` command, the subject type, the grounds, the pathway, and every other change to a model. Adding an exclusion to a model loosens, since it turns a block into an advisory. Today an in-place edit of a row escapes, because the old line is no longer in the table (`_felix_escape_shrank`). That comparison ignores line order and a trailing comma. Until step 3 builds S7, that stays as it is.

**S8. Pathway `unknown` is an authority hold.** While a blocking need with pathway `unknown` applies, it blocks every transition about its subject, whatever its evidence says. No exception clears it (amendments §1.3; `felix_obligations_blocking`). Its code is `authority_hold`. A non-blocking need with pathway `unknown` is printed and holds nothing, as today: the class is read first (`lib/obligations.sh:246`).

**S9. A single probabilistic finding is advisory.** A need that pairs `probabilistic` with a blocking class is refused (`_felix_obligation_scan`, `lib/obligations.sh:102`).

### 3.3 Reason codes

Every need at a transition gets one primary code, chosen by the precedence below, plus every secondary code that also holds. The design's set is closed by design (§4.2). This specification adds `authority_hold` and `base_unknown` to it (D4).

| Precedence | Code | Meaning | Blocks |
|---|---|---|---|
| 1 | `applicability_unknown` | the effective applicability is UNKNOWN (part 1 §4) | yes, and nothing overrides it (A1) |
| 2 | `authority_hold` | a blocking need's pathway is `unknown` and it applies (S8) | yes; no exception clears it |
| 3 | `subject_removed` | ACTIVE on the base, DORMANT on the candidate, and not cleared (P6) | yes, until cleared |
| 4 | `dormant_both_sides` | DORMANT on both sides | no |
| 5 | `checker_suspended` | the evidence's checker is suspended for this scope (part 2 §2) | yes |
| 6 | `failed` | the newest valid evidence says `fail` | yes |
| 7 | `could_not_examine` | the newest valid evidence says `could_not_examine` or `unknown` | yes |
| 8 | `not_run_for_subject` | no valid evidence for this subject exists (part 2 §1.4) | yes |
| 9 | `excepted` | a valid exception clears this TASK_BLOCKING need, held only at precedence 6 to 8, at a transition part 2 §3.2 allows | no |
| — | `-` | SATISFIED, with no other code holding | no |
| secondary | `instrument_changed` | the candidate changed part of this instrument's closure, so its own result is not evidence. The authority's run of the authorized closure decides (part 2 §1.5) | never on its own |
| secondary | `exception_expired` | a grant keyed to this need's current content exists and has expired | no; the need is judged as unexcepted |
| secondary | `base_unknown` | the candidate reads ACTIVE and the base reads UNKNOWN (part 1 §4) | no |
| secondary | `outside_model` | one or more failing cases of the need's newest valid evidence read `outside` its model. They are listed and counted, and they do not make the need fail (part 2 §1.8, MD6, MD7) | never |
| secondary | `model_unstated` | the need is blocking and has no usable model: none was stated, or it is unqualified, ungrounded or suspended. Every case counts inside (MD2) | no |

**Transition hold codes.** Clauses A4 to A7 (part 2 §3.3) hold a transition for reasons that belong to no single need. Without codes of their own, a transition held by one of them would print no reason at all (D4). They form a closed set:

| Code | Clause | Meaning |
|---|---|---|
| `admission_pending` | A4 | a proposal the task opened, of a kind that holds, is not resolved (AD2) |
| `policy_change_pending` | A5 | the change touches an input of P, and the policy-change rule has not passed for that part |
| `residual_unanswered` | A6 | at B3 and above, a residual limit of the satisfying evidence has no answer from the founder |
| `effect_unknown` | A7 | a surface the transition may reach is neither observed nor declared (part 2 §4) |
| `release_unauthorized` | A7, T4 | a release or deployment transition, or a merge that reaches one, has no founder authorization naming it (row 49) |

**S10. What a receipt prints for each need:** lifecycle, class, pathway, subject type (and "read as revision" where R17 applied), applicability on the base, on the candidate and in effect, discharge, exception state, primary code, secondary codes, the ids of the evidence records it used, and its model: the model's hash, or "model not stated", with the number of failing cases that read inside, outside and unknown (MD7). Today's report prints a sentence of detail in place of a code (`felix_obligation_state`). Part 3 §1 maps the difference.

### 3.4 The admission transaction

Admitting a need and accepting the implementation that prompted it are two events, and they happen in this order. The design's example is a change that adds money transfers, where the work shows that a retry must never duplicate a transfer.

**AD1. Proposal.** The capability side writes a CANDIDATE: the need's fields (its model among them, if it has one), a checker for it, the task that prompted it, and the proposer's identity.

**AD2. The hold.** A proposal holds its task when its pathway could make it blocking: `deterministic`, `witness`, `corroborated` or `unknown`, whatever class it proposes (design §4.2). Proposing a lower class therefore does not avoid the hold, and raising the class later is a tightening that the hold already covered. While it holds, `admission_pending` is on every transition of that task. A `probabilistic` proposal never holds.

**AD3. Only the trust side resolves a hold**, by ADMITTED (landed) or by REJECTED. The proposer cannot withdraw a proposal that holds, since that would let a change unbind its own need (D10). If the checker fails qualification, the need is not REJECTED for it: the proposal goes back for another checker, and the hold stays. A rejection on that ground would let a bad checker retire a real need.

**AD4. Admission is a policy change,** a change of its own, judged under the policy P that stands before it. Adding a need tightens P, so it lands under the admission rules: row 27 for derived rows (task scope, witness-backed, qualified, visibly Felix's, nothing armed before control 7 and the pin) and row 40 for release scope. A model admitted with a new need is part of that tightening, because before the admission the need blocked nothing. A later change to the model is a policy change of its own, judged by S7.

**AD5. The authority qualifies the checker itself,** against seeded violations it holds. It never takes the candidate's word for the result.

**AD6. Acceptance.** The implementation is judged under P′, which is P plus the admitted need, in a new epoch. Evidence produced under P is not valid under P′ (V3), and it is run again.

**AD7. Neither event approves the other.** The admission's change touches only the policy source: the need, its checker and its seeds. If it also changes the need's subject, it is split or rejected, because otherwise that implementation would be judged under P and would escape the very need it carries. The implementation's change does not touch the need or its checker. If it does, that part is a policy change and goes through A5.

**AD8. The same path for every new judge.** Any new checker or stricter rule takes effect the same way: it lands as a policy change, judged by the policy before it, and binds from then on.

**AD9. Measured:** how long each proposal holds its task.

### 3.5 Intent, for removals (row 48)

**AD10.** An `intent` record names a task and the needs, by id, whose subject that task may remove. It authorizes the removal of a TASK_BLOCKING or RELEASE_BLOCKING need's subject only when it was admitted before the work began. By Felix's reading, "before the work began" is decided mechanically as follows (D11):
- the intent's admission landed on the policy source before the lease under which the capability side dispatched the task's work;
- the task's base contains the intent.

A lease is written by the capability side when it dispatches the work, before the worker starts. A change request or a push can come after the work is done, and a rebase can put an intent into a base after the fact. So a task with no lease has no intent that authorizes a removal, and until leases exist a removal clears only by evidence or by superseding the need (P6). Direction §5 puts leases with real authority after March. The removals this holds for a person are counted. How an intent is admitted, and by whose act, is open. It belongs to the intent design's §11 (its first decision) and direction §6.

## 4. Applicability on both sides (design §4.3)

**P1. Inputs.** Applicability is read with three inputs: the base b, the candidate c, and the need's `applies` checker as P holds it, never the candidate's. The base depends on the transition:

| Transition | Base b |
|---|---|
| `task_complete` | the merge base of the task's head with the target |
| `merge` | the target tip the combined revision is built on |
| `artifact`, `deploy`, `operate` | the subject this one replaces: the last artifact built for that target, the last deployment in that environment, or the previous window. Where there is none, the base side reads DORMANT (D12). These bind from step 9 (part 2, T4) |

Where the base cannot be looked up, because a ref, a record or the provider cannot be read, the base side reads UNKNOWN, never DORMANT.

**P2. Reading one side.** The `applies` command's exit status is read as follows:
- 0 is ACTIVE;
- 1 is DORMANT;
- anything else is UNKNOWN: 126, 127, a crash, a signal, a timeout, output that cannot be read, or a read that did not finish.

`-` reads ACTIVE on both sides. Today's reading of the exit status is the same (`felix_obligation_state`, `lib/obligations.sh:133`). Today sets no timeout and does not read the command's output (`_felix_probe_ask`, `lib/probes.sh:173`).

**P3. The two sides combined.** Every combination has a defined result:

| Base \ Candidate | ACTIVE | DORMANT | UNKNOWN |
|---|---|---|---|
| **ACTIVE** | ACTIVE | ACTIVE, `subject_removed` | UNKNOWN, `applicability_unknown` |
| **DORMANT** | ACTIVE | DORMANT, `dormant_both_sides` | UNKNOWN, `applicability_unknown` |
| **UNKNOWN** | ACTIVE, with `base_unknown` | UNKNOWN, `applicability_unknown` | UNKNOWN, `applicability_unknown` |

**P4. Precedence.**
- If the candidate reads UNKNOWN, the result is UNKNOWN.
- If the candidate reads ACTIVE, the result is ACTIVE. An unknown base is listed, and it changes nothing about what the candidate has to show.
- If the candidate reads DORMANT, the base decides: ACTIVE gives `subject_removed`, UNKNOWN gives UNKNOWN, and DORMANT gives DORMANT.

**P5. UNKNOWN applicability blocks on its own.** No evidence result and no exception overrides it, because a checker cannot answer whether a need applies here (A1). Today an exception can clear a TASK_BLOCKING row whose applicability reads UNKNOWN. Part 3 §1 maps that difference (D3).

**P6. Clearing `subject_removed`.** It clears in one of two ways:
- **The evidence still holds on c.** The need is SATISFIED by evidence valid for c.
- **The removal is authorized.** For a TASK_BLOCKING or RELEASE_BLOCKING need, an intent admitted before the work began names it (AD10). For an AUTHORITY_BLOCKING need, a founder `authorization` record names the need and the subject (row 48).

Once the change lands with that authorization, the next base reads DORMANT, and the need is `dormant_both_sides` from then on. If neither way is open, the transition waits. The need may still be superseded, by a person, or by the founder where it is AUTHORITY_BLOCKING or in row 40's classes (part 1 §3.2).

**P7. ACTIVE means the evidence runs on c.** If the evidence cannot find the subject, it exits 2, which reads `could_not_examine`, and the change blocks. That is the reviewer's example: a reroute hides an endpoint from discovery, its authentication need was ACTIVE on the base and so stays ACTIVE, and its evidence cannot find the endpoint.

**P8. An `applies` command is a checker.** It is read from P, bound to its content, and qualified on seeded cases where the subject still exists but has moved or been renamed. Its qualification binds when the qualified-judge join arms (roadmap Phase 1). Until then it is printed beside each need, and the two-sided table is what stops a candidate from retiring its own need (D22).

**P9.** Applicability is read for each transition separately. A need's effective applicability at one transition says nothing about another.

**P10.** A need's grounds name the probe predicates its applicability rests on (`probes.tsv`). Those probes are inputs of the reading (R3). A need with no grounds is counted, not refused, as today (`felix_obligations_ungrounded`).
