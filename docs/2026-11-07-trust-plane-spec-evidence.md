# Felix trust plane: the specification, part 2 of 3

2026-11-07, revision 1 on 2026-11-08. Evidence, a need's model, escapes and suspensions, transitions and the acceptance rule, the observability boundary, and the method's contract. Part 1 (`docs/2026-11-07-trust-plane-spec.md`) states the scope, the conventions, what this specification binds and when, and what revision 1 changed; it applies here unchanged. A section written §4.4 is the design's (`docs/2026-11-07-trust-plane-design.md`). Sections 1.8 and 5 are new in revision 1.

## 1. Evidence (design §4.4)

### 1.1 The evidence record

**E1.** An evidence record holds the envelope (part 1 §2.2) and every field below. A record missing one is malformed, and malformed is not valid. The design gives the first eight fields as the reviewer's set, open to more. This specification adds the rest.

| Field | What it holds |
|---|---|
| `subject` | a typed subject identity (part 1 §2.8) |
| `instrument` | the checker version (entry hash) and the id of the closure observed in this run (E4) |
| `policy_epoch` | the version of P the run was made under: the policy-version component of the decision epoch (`felix_epoch_policy`), not the envelope's whole `epoch` |
| `provenance` | `authority_run` or `provider_read`, with the run's identity (part 2 §1.5) |
| `environment` | operating system, toolchain versions, and the runner's identity |
| `inputs` | every input the run read, each by content (R3), including inputs outside the subject such as probe facts and the clock |
| `independence` | identity, context and authority (part 2 §1.6) |
| `result` | one of K1's four values. It is derived from `exit` and `cases` and the need's model, never taken from the checker's say-so (MD6) |
| `cases`, `residual` | how many cases were examined, with a reference to the coverage report naming what was examined and a verdict for each. For each case the report also gives its descriptor: the fault classes the case injected and the value of each input that the need's model gives a domain (MD5). And the stated limits |
| `need` | the need the run was made for |
| `exit` | the checker's own exit status, as read |
| `gateway` | whether the I/O gateway reports that it saw the whole run (E4) |
| `started`, `finished` | on the authority's clock |

### 1.2 The instrument and its closure

**E2. An instrument is everything its check executes,** not the file that names it. So far its closure takes in the scripts it runs, test discovery and its configuration, the dependencies it executes, and the toolchain versions it needs. That list is a set of examples, not the whole set (K4). A workflow can stay byte-identical while the check it runs changes. Suppose it runs `npm test`, and the candidate rewrites the test script to always succeed. The judge has changed and the workflow has not.

**E3. The authorized closure comes from policy.** For each checker version, P holds the content of every file and package that makes up its instrument part (E5).

**E4. The observed closure is recorded, not listed.** It is what the I/O gateway saw the run read and execute. Each item it saw is classed as instrument or subject (E5). A run counts only when all three of these hold:
- every observed instrument item's content equals P's version of that item;
- no observed item is unclassed;
- the gateway reports that it saw the whole run.

Anything else makes the record not valid, with `not_run_for_subject` and a detail line saying which of the three failed. Whatever the gateway misses without knowing it is a gap in the judge, and part 3 §4 keeps that risk open.

**E4a. Until a gateway sees a run,** none of E4's three conditions can be read, and this rule stands in for E4, for an `authority_run` and a `provider_read` alike (D28). The run counts only when every instrument file it names (its workflow, and the scripts and configuration the partition marks) is P's version, and every path the candidate changed is one the partition marks as subject. The receipt then lists "closure not observed" among the residual. What this misses is an executed file that the partition marks as subject when it is in fact judge. The partition is policy, so that is a policy error, and correcting it is a tightening.

### 1.3 Instrument against subject

**E5. The partition.** P marks, for each repository, which paths and packages are instrument and which are subject. An item it marks as neither is unclassed, and a run that reads or executes an unclassed item does not count (E4). Nothing is subject by default (D28). Marking an item instrument is a tightening. Marking it subject lets the candidate supply it, so that is a loosening, and it goes to a person. The authority has to read and run the candidate's code, because that code is the subject under test. Doing so never makes it part of the judge: the check runs P's instrument closure over the candidate's subject.

**E6. Mixed files.** Some files hold both instrument and subject. A package manifest holding both the dependencies and the test script is one example. For each ecosystem, P may declare a split of such files into their instrument and subject parts:
- **With a split,** the instrument parts are P's version, the subject parts are the candidate's, and the check runs on the file merged from the two.
- **Without one,** the whole file is instrument (D13). Its parts in P's version run, and the candidate's change to it is a policy change (A5).

That fails closed, at the price of false blocks on dependency changes, which are counted. How each ecosystem's mixed files split is open, and is worked out per ecosystem.

**E7. Felix's own instrument, as an example of E5 and not the set.** It takes in its `gate.sh`, which already binds only after it lands; `tests/run` and `tests/parts/`; the workflow definitions; and the suite's manifest. Step 3 enumerates the rest from what the gate actually reads (design §6).

### 1.4 When a record counts

A record is valid for a decision when all seven of these hold:
- **V1.** Its subject is the decision's subject (R18, R19).
- **V2.** Its observed closure matches a checker version that P authorizes and that holds a valid qualification for the need's fault class (E4, part 2 §1.7).
- **V3.** Its `policy_epoch` equals P's current policy version.
- **V4.** Its provenance is one the worker cannot forge (part 2 §1.5).
- **V5.** None of its recorded inputs has changed, and they are all known (R12, R13).
- **V6.** Its independence meets the need's minimum (part 2 §1.6).
- **V7.** No current suspension covers it: not the record itself, not its checker version for its fault class, and not the method that qualified that version (part 2 §2). The design lists suspension apart from validity. Writing it here keeps a suspended checker's old evidence from counting (D6).

**E8. From evidence to discharge.** Discharge is read from the newest valid record for the need, the subject and the epoch, by its derived result (MD6):
- `pass` gives SATISFIED;
- `fail` gives UNSATISFIED, with `failed`;
- `could_not_examine` or `unknown` gives UNKNOWN, with `could_not_examine`;
- no valid record gives UNKNOWN, with `not_run_for_subject`.

Today exit 0 holds, 2 means "cannot examine", and 126 or 127 means unknown (`felix_obligation_state`), and any other status fails. The derivation of MD6 keeps those readings and adds one thing: a failure whose every failing case reads `outside` the need's model does not fail the need. The newest valid record decides, and every earlier valid record for the same need, subject and epoch that did not pass is listed in the receipt (D7). That is C9's rule: an older green run never stands in for a newer one (`_felix_merge_gate_held`, `lib/escape.sh:536`). Only the authority writes records, so a worker cannot add a newer one. Laundering a flaky result through repeated runs shows up in reruns per PR, which is already measured.

### 1.5 Provenance, and customer CI

**E9. Two kinds of provenance count.**
- `authority_run`: the authority ran the check itself, in its own environment, under its own identity.
- `provider_read`: a run on the provider's CI that the authority read directly through the provider's API, with its own identity, including what the run shows about which checks it ran.

These never count: a worker's report, a status check on its own, a local gate receipt, or any file in a tree. They are advisory (design §4.7).

**CI1.** A CI run counts when it executed the authorized instrument closure on the exact subject. Its tree is the decision's tree, and its closure is P's.

**CI2.** If the candidate changed any part of that closure, its own run is not evidence, and the need carries `instrument_changed`. The authority then runs the authorized closure itself (`authority_run`), and the change to the closure goes through the policy-change rule (A5). A tightening lands on green, a loosening goes to a person, and a change to the judge's own artifacts waits for the founder until the judge is pinned (row 38).

**CI3.** A green status check does not show which checks ran, so on its own it is not evidence.

**CI4. How a provider run's closure is established** while no gateway runs on the provider's runners (D14). A provider run counts as `provider_read` only under E4a: the workflow file the run used is byte-identical to P's version, and every path the candidate changed is marked subject, so no instrument path and no mixed file without a split (E6) is among them. Otherwise the authority runs the closure itself. Every such run draws runner minutes, and the receipt reports them (design §7).

### 1.6 Independence, as validity reads it (design §4.5)

**E10.** The record carries three parts:
- **identity:** the identity of the checker's author against the producer's, both as the authority verified them;
- **context:** `blind` or `saw_implementation`;
- **authority:** the identities that can change the checker or its qualification. The worker being judged must never be among them.

**E11.** The minimum is a property of the need, set by its class and stakes, never by how simple the change looks (row 44). The design's proposed default is that blocking needs at B3 and above need context `blind`, and every other need needs a different identity.

**E12.** A part that was not recorded does not meet any minimum.

### 1.7 Qualification is bound to the closure's content

**E13.** A qualification record is keyed on four things: the checker version (its entry hash and authorized closure hash), the fault class, the method version and the seeded set. If any of them changes, there is no qualification: a checker that was edited, or whose closure changed, starts unqualified.

**E14.** The authority runs qualification against seeded violations it holds. The method's current controls are amendments §2.1's seven: the six that `lib/qualify.sh` runs, plus control 7, the coverage report, which roadmap Phase 1 adds.

**E15.** A qualification that failed or is missing is printed. It refuses only as the ratchet already decided (`lib/qualify.sh`, header), until the qualified-judge join arms.

### 1.8 A need's model (new in revision 1; step 1 report §6, change 1)

Step 1's executors held on any fault they could inject and any input they could build, because no need said which faults and inputs its deployment meets. Of the 5 false blocks among 18 clean twins, 4 were of that kind: two setup faults, a float within one ulp of a half, and an envelope with its body missing (report §2.5). The design already says outside text names a stated model (§2, Accuracy). This section gives each need one, and a rule for what falls outside it.

**MD1. What a model is.** A model is a field of the `need` record. It states, as observed (K4), the faults and the inputs of the deployment the need is about, in two parts:
- **faults:** fault classes, each read `met` or `not_met`. A `not_met` reading carries a ground. A class the model does not list is unstated. Classes are named from FM-1 (the 10-31 design's §2.3) and the fault tiers (design §4.7). Both are open, so a fault that neither names is unstated too. A `not_met` reading might be, for example, "the destination folder is unwritable".
- **inputs:** for each input the need's subject reads, a domain: a predicate the authority can evaluate on the input's value as the case descriptor records it, with its ground. An input with no domain is unstated. A predicate is written in one of a closed list of forms (K1), so that no model needs a program to be read. In revision 1 the forms are `regex` (an extended regular expression the whole value matches), `range` (a decimal number between two bounds, inclusive), `set` (one of a listed set of values), `length` (a text length between two bounds) and `keys` (a JSON object that has at least the listed keys). A predicate in any other form reads `unknown` (MD5), and a new form is a new schema version (K3).

A ground is a probe predicate (`probes.tsv`, P10) that the exclusion rests on, or a declared fact with its declarer. A declared ground works like a declaration of `none` (O6): it lands only with a person's approval, and on Felix itself the founder's.

**MD2. No usable model, no waiver.** A need reads as having no model when none was stated, when its model has no passing model control (MD8), when a ground no longer reads as it did (R12), or when a suspension of scope `model` covers it (X3). Every case then reads `inside`, which is how the engine reads a failing evidence command today, and the receipt says `model_unstated`. A model is never inferred, by a checker or a reader, from what a checker did not exercise.

**MD3. A model is authored and qualified like a checker.** Its author's identity and context are recorded (E10). The minimum independence of the need's checker (E11) applies to the model too, since a model written by whoever produced a change could exclude that change's own defect. The authority qualifies the model with the checker (MD8).

**MD4. Strictness.** Removing a model, or removing one of its exclusions, tightens (S7). That means reading a `not_met` fault as `met` or unstated, or dropping an input's domain. Every other change loosens, widening a domain included, because two predicates cannot in general be compared mechanically (D9).

**MD5. Reading a case.** The authority reads each failing case itself, against the model, along the dimensions of the case's descriptor (E1). A dimension reads:
- `outside` only by a positive reading: a fault class the model reads `not_met`, or an input value for which the domain predicate exits 1;
- `inside` when the model reads the fault class `met`, or the predicate exits 0;
- `unknown` otherwise: an unstated class, an input with no domain, a predicate that exits any other status, times out or cannot read the value, a descriptor that is missing or unreadable, or a fault the checker did not label.

A case reads `outside` when any one of its dimensions reads `outside`, since the model says the deployment does not meet that combination. It reads `inside` when every dimension reads `inside`. Otherwise it reads `unknown`. Until a gateway records what a run injected, the fault dimension is the checker's own label, which is a claim. The receipt says "fault labels not observed", and MD8 is what tests the labels. E4a stands in for the closure in the same way.

**MD6. The derived result.** The authority derives `result` from the run's `exit` and its cases, in this order:
1. The run did not finish, its status is 2, 126 or 127, it was killed or timed out, or its coverage report cannot be read: `could_not_examine` or `unknown`, as E8 reads them today.
2. Some failing case reads `inside` or `unknown`: `fail`.
3. The status is a failure and the report names no failing case: `fail`, because nothing places the failure outside.
4. Otherwise `pass`: either no case failed, or every failing case reads `outside`.

**MD7. Outside cases stay visible.** They never fail the need on their own, and they never go unprinted. Each is listed with its descriptor, and the receipt prints the model's hash and the counts of failing cases that read inside, outside and unknown (S10, T7). The primary code is unaffected and `outside_model` is a secondary code. An outside case that later proves a real defect in a deployment is an escape whose fault class is `model` (X3).

**MD8. The model control.** The checker's qualification (E14) gains a control for its model. Its seeded set holds:
- at least one violation of the requirement that reads `inside`, which the checker must reject;
- for each exclusion the model states, at least one seeded case that reads `outside`, which must come out as an outside case and not as a failure of the need.

A model without a passing model control reads as not stated (MD2). The control is new. The amendments' seven controls are unchanged.

**MD9. A model arms nothing by itself.** How much Felix may block is the founder's call (`lib/qualify.sh`, header), and a model moves failures from blocking to advisory. So no model waives anything until part 1's arming rules hold. Until then the receipt prints the result both ways, with the model and without it, and the result without it decides.

**What a model does not do.** It leaves alone a block that rests on an input or a fault the deployment does meet, and a block that rests on a guard choice: step 1's fifth false block was a standard guard that also drops two key names the requirement does not mention. It does not make its author complete: a fault the author left unstated reads `unknown` and blocks. It is also a waiver, so a model that is too wide lets a real defect become advisory. Recall measures that, and an escape records it (MD7). Whether models bring false blocks under the bar is the rerun's question (§5.4), not this section's.

## 2. Escapes, suspensions and repair (design §4.4)

**X1. An escape record** names the defect and how it was found, the decision and evidence records that let it through (the receipt, design §5), and its fault class in the fault model. Row 50 keeps the 10-31 design's FM-1 as that model. An escape no fault class fits is recorded as `unclassified`.

**X2. On an escape,** the evidence that passed the defect is marked as having missed a real defect, by a record that points at it (R7), and it stops being valid (V7). The need cannot read SATISFIED again until a checker that catches the escape passes it:
- on the subject where the defect was found, the escape record itself is a `fail` for the need, so it reads UNSATISFIED with `failed`;
- on any other subject, before the repair, it reads UNKNOWN, with `checker_suspended` (X5), or with `not_run_for_subject` at `record` scope, where the checker is rerun as it is.

**X3. What is suspended depends on what the escape shows:**

| The escape shows | Scope | What is suspended |
|---|---|---|
| One evidence record was wrong, for example a run on stale inputs | `record` | that record |
| The checker version misses this fault class | `version_class` (the default) | that version, for that class |
| The checker is wrong wherever it is used | `checker` | every use of that checker |
| The qualification method passed a checker that does not discriminate | `method_class` | the method for that class, and every checker it qualified for that class |
| A case the need's model read `outside` proved to be a real defect in a deployment | `model` | the need's model, which then reads as not stated (MD2). Its evidence stays valid, and its result is derived again without the model (MD6) |

**X4. Who sets the scope.** The trust side does, starting from the default, `version_class` (D15):
- **Narrowing to `record`** needs a mechanical witness, such as the record's inputs differing from the inputs of the subject where the defect was found. Without one, narrowing is a loosening and goes to a person.
- **Widening** is free. It goes to `checker` when the checker also fails a seed unrelated to this escape, and to `method_class` when it passes a mutant that the method's own seeds already held.
- **An `unclassified` escape** suspends at `checker` scope.
- **A `model` suspension** is set whenever an outside case is shown to be a real defect in a deployment. It only widens what blocks, so it is free.

**X5. What a suspension does.** Every evidence record inside its scope stops being valid (V7), except at scope `model`, where the records stay valid and are read without the model. Every need that relied on one of them reads UNKNOWN, with `checker_suspended`, at the next transition about any subject. Those transitions block until the repair lands, whether or not they are the fix.

**X6. Repair is independent.**
- The authority qualifies the replacement or repaired checker with the escape among its seeded violations, and the checker must still catch every earlier seed.
- The suspended checker takes no part in qualifying its own replacement: a broken checker never certifies its replacement.
- For a `model` suspension, the repair is a changed model that reads the escape's case `inside` and passes the model control (MD8).
- The repair lands as a policy change (part 1 §3.4, AD8). After it lands, a `suspension` record with scope `lifted` supersedes the suspension and names the repair's qualification record.

**X7.** The fix for the defect waits only for that repair, and is then judged by the requalified checker.

**X8.** A suspension never lapses with time.

**X9. Measured:** the time from an escape to its repair landing, and the number of changes held meanwhile.

## 3. Transitions, and the acceptance rule (design §4.6)

### 3.1 Transition types

A need's class says how hard it holds. Its subject says when it is checked.

| Transition | Its subject | Base | Begun by |
|---|---|---|---|
| `task_complete` | the implementation revision | P1 | the worker's hand-off |
| `merge` | the combined revision | P1 | the queue |
| `artifact` | the artifact | P1 | a build or release |
| `deploy` | the deployment | P1 | a release |
| `operate` | the operational outcome | P1 | continued operation |

**T1.** Each transition requires every applicable blocking need about the subject it creates or changes. Needs about other subjects are not evaluated there, and the denominator counts them. This is what removes the deadlock: a need about a deployed service is never required before the merge that the deployment depends on.

**T2. A merge is classed by what it reaches** (part 2 §4). If it reaches no effect, it is a `merge`. If it reaches a deployment effect or an unknown effect, it is a `merge` and also the `deploy` it reaches. Both rules apply, and it proceeds only when both pass (D17). The needs about the combined revision still hold at a merge that reaches a deployment.

**T3. Task completion is the authority's decision.** The authority evaluates `task_complete` when a task hands off. A worker session's own gate before that is advisory (design §4.7). When the target has not moved, the implementation and combined revisions have the same tree (R19), so one evaluation serves both, for a merge that reaches no effect. A merge that reaches an effect is judged again under T2, where no exception is allowed.

### 3.2 What each class holds

| Class | Holds | Exception | Who clears a wrong hold |
|---|---|---|---|
| INFO, ADVISORY | never; they are printed | — | — |
| TASK_BLOCKING | yes | a valid exception, at `task_complete` and at a `merge` that reaches no effect, for a need held only at precedence 6 to 8 (part 1 §3.3), and nowhere else (amendments §3) | a person, with a dated exception |
| RELEASE_BLOCKING | yes | never | a person, by superseding or editing the need (part 1 §3.2). In row 40's classes, only the founder |
| AUTHORITY_BLOCKING | yes | never | the founder |

### 3.3 The rule at one transition

Let T be a transition with subject s, under policy epoch P, from base b. T may proceed when all seven of these clauses hold.

**A1. Applicability is known.** No blocking need about s has an effective applicability of UNKNOWN (part 1 §4). This clause stands on its own: no evidence result and no exception overrides it. Code: `applicability_unknown`.

**A2. Required needs are met.** Every blocking need about s whose effective applicability is ACTIVE is SATISFIED by evidence valid for s (part 2 §1.4). That includes a need held at `subject_removed`, unless its removal is authorized (P6). A TASK_BLOCKING need held only by `failed`, `could_not_examine` or `not_run_for_subject` may carry a valid exception instead, at the transitions part 2 §3.2 allows. An exception never stands in for an authorized removal or a repair, so it clears neither `subject_removed` nor `checker_suspended` (D3). Codes: part 1 §3.3, precedence 3 and 5 to 8.

**A2a. Task scope, for derived rows (row 27, bound 1; direction §5, "Before row 27 arms anything").** For a need admitted as a derived row under row 27:
- if it is SATISFIED on the base and not on c, it holds T wherever T's change edits;
- if it is already not SATISFIED on the base, it holds T only when T's change touches a surface its grounds name. Where that cannot be told, it holds.

Every other need holds under A2 as written (D27).

**A3. No authority hold applies.** No blocking need about s with pathway `unknown` applies (S8). An exception does not clear one. Code: `authority_hold`.

**A4. No admission is pending.** Every proposal of a holding kind that the task opened is resolved (AD2, AD3). Code: `admission_pending`.

**A5. Every input came from P.** If T's change touches any of P's inputs, the policy-change rule (design §4.1) has passed for that part:
- a tightening has landed under its own rules;
- a loosening has a person's approval;
- a change to the judge's own artifacts waits for the founder's merge until the judge is pinned outside every change it judges (row 38).

Code: `policy_change_pending`.

**A6. Residual limits are answered.** The residual limits of the evidence that satisfied each need are listed. At B3 and above, each has the founder's answer (row 39; the 10-31 design's decision 5). The B-class is computed from paths, reach and `risk.tsv`, and a model may only raise it (the 10-31 design's §11.2, decision 15). At B0 to B2 the limits are listed as unchecked (UNKNOWN), and they do not hold the transition (row 39). A B-class that cannot be computed reads as B3 and above (D29). Code: `residual_unanswered`.

**A7. Every reachable effect is within T's authority** (part 2 §4). An unknown effect makes T a deployment transition (T2), and the deployment's rule governs it. Codes: `effect_unknown`, `release_unauthorized`.

**T4. Releases fail closed until the release subsystem exists (row 49).** Every `artifact` and `deploy` transition, and every merge that reaches one, holds with `release_unauthorized`. It proceeds only on a founder `authorization` record that names that release: the exact subject identity (the combined revision's tree, or the artifact's digest) and its target. Merge authorization never stands in for release authorization. Until step 9 builds the release subsystem, needs about an `artifact`, a `deployment` or an `operation` are counted, listed as not evaluated, and not required, because their subject does not exist before the transition and how their candidate side is read is step 9's to define (part 3 §4). The founder's authorization by name is what such a transition proceeds on (row 49). The needs about the combined revision still hold at a merge that reaches a release (T2), and `operate` transitions do not exist yet (D26).

**T5. The founder's release authorization** names one subject identity and one target, and serves for that subject alone (D21). It is a change of its own, which adds one `authorization` record naming the tree or digest and the target to the policy source, landed by the founder's own act as the provider reports who performed it (R16). Merging the change being released never counts as that act, since that would take release authorization from merge authorization (row 49). Until the hosted authority exists, the authorization's change opens as a draft labelled `needs-founder`, which the founder merges (D30).

**T6. Every clause is evaluated,** and none short-circuits another. The decision record lists each clause as held or clear, with its codes. A held transition therefore always names its reason.

**T7. The denominator.** Each receipt prints:
- how many needs are admitted;
- how many of them are about s's type, and how many about other subjects;
- how many apply (ACTIVE or UNKNOWN), and how many are DORMANT;
- how many are satisfied, how many excepted, and how many hold, by code;
- for each need, its model's hash or "model not stated", and the failing cases that read inside, outside and unknown (MD7);
- for each evidence record, what was examined out of what, from its coverage report;
- the list's known gaps (design §0, row 1).

**T8. Who evaluates.** The authority does: hosted, with its own identity (design §4.8, row 43). It runs once on the combined revision in the queue, one change at a time per branch. Until it exists, the interim evaluator is `felix merge`'s judge, a copy of main's engine (`lib/merge-judge.sh`), and its known limits are printed with each decision. Its header (`lib/merge-judge.sh`) and the 10-31 design's §4.8 name these so far:
- a branch whose own felix no longer hands off still judges itself when run from that branch;
- an entry that runs in place sources its own libraries (C063);
- a same-user process can swap the copy between its check and its use;
- a SIGKILL leaves the copy behind.

## 4. The observability boundary (design §4.8)

**O1. Reversibility belongs to the transition and everything it reaches,** not to the commit. A merge is a deployment transition if it reaches an effect. So far, effects include triggering a deployment, publishing a package, running a workflow with production credentials, and writing to an outside system. That list is a set of examples (K4). This holds however much a revert could undo.

**O2.** Every surface that could respond to a transition is in exactly one class: observed, declared, or unknown.

**O3. Observed.** The authority enumerates what its identity can read through the provider's API. So far that covers:
- the repository's own automation definitions, meaning the workflows a merge triggers, with their triggers, jobs, environments, the secrets they reference and their token permissions;
- branch protection and rulesets;
- deployment environments;
- every other surface the provider lets its identity read.

Each surface is recorded with a fingerprint of what was read. The list comes from what can be read, not from a list written in advance.

**O4. An observation can show an effect, never its absence** (D16):
- A triggered workflow that references any secret beyond the provider's default token, uses a deployment environment, or holds a write permission is classed `effect`.
- One that cannot be read whole is `unknown`.
- A workflow with none of those signs can still write to an outside system with no credential at all, so it is `unknown` too, unless a declaration (O6) classes it `none`.

Incomplete observation is never turned into a claim that a merge is reversible.

**O5. Not observable from the repository.** External webhooks, installed apps, cloud deployment integrations and organization-level automation are examples of surfaces that can respond to a merge without being defined in the repository. Whoever controls such a surface declares its effects in policy, and they are authorized separately.

**O6. The declaration record** names a surface or a class of surfaces, an effect class, the declarer, and the fingerprint of any part that can be observed.
- A declaration of `effect` tightens, and it lands free.
- A declaration of `none` widens, since it turns an unknown into a pass. It lands only through the loosening path of the policy-change rule, with a person's approval (on Felix itself, the founder's).
- A declaration stops holding when the fingerprint of its observable part changes (part 1 §2.5). A changed workflow file needs declaring again, and changing a workflow is already a founder stop today (the `execute` channel).

**O7. Unknown.** The authority holds a catalogue of the classes of surface that can respond to a transition. It is policy, open by K4, and adding a class to it is a tightening. A transition reaches no effect only when every class in that catalogue is covered: observed as `none` where O4 allows, or declared `none`. A class that is not covered is unknown. An unknown effect counts as irreversible, and T4 then fails the merge closed.

**O8.** This will cause false blocks at first. Each one counts as a potential founder interruption, and declarations reduce them (design §2, autonomy).

**O9. Merge authorization and deployment authorization are separate decisions** inside the one authority. A decision record says which one it is.

**O10. Open (direction §6):** whether landing and releasing are separate steps when a merge reaches no effect. It is to be tried natively before it is asked again.

## 5. The method's contract (design §4.7; new in revision 1)

The worker-side method is advisory: no decision reads its records (R11), and the design reads a wrong skip there as one that only delays a change (§4.7). This section fixes what the method must produce, so that its outputs can be proposed as needs (AD1) and so that step 1's measurement can be repeated on the same terms. The method's parts so far are class rules, spec oracles, fault tiers with mutants on the change's own lines, and one residual review. That list is open (K4).

### 5.1 What step 1 measured

Step 1 ran the method once on one blind held-out set: 18 defective subjects and their 18 clean twins, six cases in each of bash, Python and TypeScript, three authors (one per ecosystem), and one run per subject. The counts below were taken on that set only. They come from `step1-report.md`.
- **Recall:** 18 of 18 defective subjects caught.
- **False blocks:** 5 of the 18 clean twins, against a limit of 4. Four of the five were faults or inputs that no deployment meets (§1.8); the fifth was a guard choice.
- **Shape of the catching check:** 10 of the 18 catches were a class check, meaning an oracle swept over a population of inputs or over several code sites (9 to 11 on borderline calls), and the report's summary calls them spec oracles swept over inputs. 8 were a single scenario aimed at the flagged behaviour. None came from a fault tier at enumerated sites or from a mutant.
- **The R1 to R8 catalogue** fit 7 of the 18 defects, and 1 more partly. That is the report author's reading after the fact.
- **Fault tiers ran thinly,** by the executors' own accounts: T1 on about 6 of the 36 subjects, T3 on about 4, and T2 and T4 on none.
- **The residual review's own contribution was not measured.** Its held-out packets carried the executors' findings, and its reviewers held on 25 rows, each already in the packet. On the one historical packet that held to the brief, it added nothing new.

These counts do not show that fault tiers and mutants add nothing. They ran on a fraction of the subjects, so their contribution is unmeasured. This specification keeps them in the method at that status (D37).

### 5.2 Spec oracles beside class rules (change 2)

**SO1.** A spec oracle is a checker written from the requirement alone. It judges the behaviour the requirement states, by a reference computation or a property, and where it can over a swept population of inputs and not one scenario. It does not read the change to decide what to test.

**SO2.** Its author's context is `blind`: the author was given the requirement, the interface the requirement names, and the code as it stood before the change, and was given neither the change nor any implementation of it. A checker whose author saw the implementation is not a spec oracle whatever it is called; its kind is `instance`, or what SO7 shows.

**SO3.** Context is read from the dispatch and not from the author's word. It is read from the lease the capability side wrote when it dispatched the author, which records what was put in the author's context. A checker with no lease reads `saw_implementation` (E12). Leases come after March (direction §5), so until they exist no checker has a verified `blind` context, and a measurement of the method records its own dispatch instead (part 3 §4).

**SO4.** A spec oracle needs context `blind` whatever its need's class and stakes. E11's default for other checkers is unchanged.

**SO5.** Qualification applies to a spec oracle unchanged (E13 to E15, design §4.5): decoupled violation and satisfaction, a coverage report, and mutations authored by something that has not seen the checker.

**SO6.** The kinds are closed (K1):
- `class_rule` enumerates the sites or the inputs of a rule's class and tests each. R1 to R8 are the first rules, and the list of rules is open;
- `spec_oracle` is SO1 and SO2;
- `fault_tier` injects a fault from a tier (design §4.7) at enumerated sites, or runs a mutant;
- `instance` tests one scenario aimed at one behaviour.

**SO7. A kind is shown, not labelled.** Step 1 found that the `rule:` and `tier:` labels often misdescribed the check behind them (report §2.3). The authority reads a checker's kind from its qualification record. `class_rule` and `spec_oracle` hold only when the qualification rejected seeded violations at two or more distinct sites or input regions. A checker that rejected one is `instance`, whatever its author says. Two is the least number that tells a class from an instance, and whether it is enough is a question for measurement (part 3 §4).

### 5.3 The review packet carries no findings (change 3)

**PK1.** The residual review reads one packet. It holds:
- the requirement;
- the diff from the base to the head;
- the surviving mutants, each with its line and what it changed;
- the cells the run could not cover, and why;
- the obligations the run could not check mechanically, each written as a question;
- any suspicion the run could not back with a failing run.

**PK2.** The packet carries no finding of the run: no failing check, no blocking row, no verdict, and no summary of what the run caught or cleared. A suspicion is not a finding, and the packet labels it as the run's unverified claim.

**PK3.** A program checks the packet before it is sent. It refuses a packet that holds the id, the location or the evidence command of any row of the run's findings. A refused packet is rewritten by the run that wrote it, and is never edited by hand.

**PK4.** The review's output is advisory (S9). A review can propose a candidate need (AD1) and can never block.

**PK5. Measured:** the defects, seeded or real, that only the review raised, out of the defects in the set; the holds that restate a suspicion in the packet, counted apart; and the review's false holds. Step 1 measured none of these, for the reason in §5.1.

### 5.4 Status of the method

The model rules (MD1 to MD9), SO1 to SO7 and PK1 to PK5 are the method's contract from this revision. They bind the method's tooling and the catalogue (design step 6), and no blocker is armed on them (MD9).

The method advances to the prospective trial (row 39) only if a rerun passes the bars that step 1 fixed, on a fresh blind set from new authors, under a pre-registration written before any case is authored (memory root, `audits/2026-11-08-trust-plane-step1-rerun/prereg.md`). Until a rerun passes, it does not advance. A pass lets the method go on to the prospective trial and settles nothing beyond that (design §9, step 1). The prospective trial and the catalogue wait on it, and the historical set's gaps belong to the catalogue (part 3 §4).
