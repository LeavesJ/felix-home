# Felix trust plane: the specification, part 3 of 3

2026-11-07, revision 1 on 2026-11-08. The two mappings that design §9 step 2 and direction §5 item 0 ask for, then the decisions this specification made and what it leaves open. Parts 1 and 2 are `docs/2026-11-07-trust-plane-spec.md` and `docs/2026-11-07-trust-plane-spec-evidence.md`. Part 1 states the scope and what revision 1 changed. In this part, revision 1 adds §1.6, three changed rows in §2.2, decisions D31 to D37, and eight open questions and four risks in §4.

## 1. Today's engine, mapped onto the specification

Line numbers are for `b7aab8e9` (main, #482). Revision 1's §1.6 was read at the same commit. The mapping covers the files the design names as the first implementation (`lib/obligations.sh`, `lib/exceptions.sh`, `lib/escape.sh`) and the other files whose functions a rule here reads. It is a reading of the code, not a test of it. Nothing was run to produce it. Where a cell says "missing", nothing in the files read does that part. For each row:
- **enforces** means what the engine already does as the rule says;
- **differs** means what it does otherwise;
- **missing** means what no code in those files does.

### 1.1 The record contract (part 1 §2)

| Rule | Today | Enforces | Differs | Missing |
|---|---|---|---|---|
| R1, K1, K2: closed types, malformed refused | `_felix_obligation_scan` (`lib/obligations.sh:78`); `_felix_exceptions_scan` (`lib/exceptions.sh:289`) | class and pathway are closed sets; a malformed row is refused with a reason; a scan that fails admits nothing | refusals are sentences, not codes | — |
| R4 to R6: versioning | `felix_receipt` (`lib/receipt.sh:98`) versions the receipt's shape; `templates/schemas.tsv` declares each table's columns, checked by `lib/table.sh` | a shape for each table, which a project cannot declare for itself; a versioned receipt | a table's shape has no version, and a change to it is an edit of `schemas.tsv`, judged by the `verifier` channel | a version on every record kind |
| R7 to R10: append-only provenance | git history of the tables; `candidates.tsv` under the memory root (`felix_candidates_record`, `lib/candidates.sh:137`) | a candidate keeps its stamp, tree and epoch | the ledger is edited in place. History is git's, and what a decision read is not recorded with it | `supersedes`, and decisions that name the records they read |
| R11: where records live | needs and exceptions in `projects/<name>/`; receipts and ledgers under `state/` and the memory root | exceptions are read only from the remote-tracking main (`felix_exceptions_ref`, `lib/exceptions.sh:111`) | needs, checkers and qualification are read from the project directory the caller passes. That is a working tree, not the authorized policy. In a worktree session it is the home checkout's copy (`lib/exceptions.sh:411`) | the authority's own store |
| R12, R13: invalidation | `felix_verify_current` (`lib/verify.sh:585`): a receipt is current for its exact tree, and stale "for a fact that moved outside the tree" | the tree keys a receipt, and a moved outside fact stales it | one receipt stands for the whole gate, not one record per need | per-kind invalidation rules |
| R14 to R16: one writer, verified identity | the `exception` and `authority` escapes (`lib/escape.sh:141`, `:150`) give the grant to a person's merge | a person's merge is what makes a grant | identity is the merge, by whoever merges. The provider's report of who merged is not read | writer checks on every record |
| R17, R18: typed subjects | none | — | both rows of `projects/felix/obligations.tsv` (`lifecycle_wired`, `engine_deployed`) name no subject, so R17 reads both as `revision`. `engine_deployed` is, by its name, about a deployment: an example of a row whose real subject is not the revision | subject types |
| R19: a revision is its tree | `felix_tree_id` (`lib/verify.sh:361`); `felix_merge_checkout` (`lib/escape.sh:486`) re-reads branch, commit and tree before merging | receipts are keyed on the tree | C9 asks about the commit, not the tree (`_felix_merge_gate_held`, `lib/escape.sh:536`) | — |
| envelope `epoch` | `felix_epoch` (`lib/epoch.sh:188`) | v3.2's four components are hashed and reported, and a gate receipt whose epoch differs from the current one reads stale (`felix_verify_current`, `lib/verify.sh:601-609`) | by its own header it does not decide whether a shrink of the ledger may land. Its policy version hashes `FELIX_COMMISSION_TABLES` (`lib/commission.sh:52`), which leaves out `qualification.tsv`, `exceptions.tsv`, the gate, the suite and the workflows, all of which P holds under design §4.1 | the judge's identity in the epoch (roadmap step 14's remaining half) |

### 1.2 States and admission (part 1 §3)

| Rule | Today | Enforces | Differs | Missing |
|---|---|---|---|---|
| S1: lifecycle stored | a row in `obligations.tsv` is ADMITTED; a removed row is SUPERSEDED (`lib/obligations.sh:10-12`); `lib/candidates.sh` holds CANDIDATE | three of the four states | ADMITTED is a row's presence, not a record | REJECTED as a record; `admission` records |
| S2, S3: derived, never stored | `felix_obligation_state` (`lib/obligations.sh:133`) | applicability and discharge are derived on every run | derived from live commands in the checkout, not from evidence records | evidence records |
| S4: exception derived | `felix_exception_for` (`lib/exceptions.sh:333`) | read from the remote-tracking main; TASK_BLOCKING only; keyed to a content-hash prefix of 12 or more characters; unexpired; within the horizon; the earliest live expiry wins; never on an authority hold | a grant is honoured on a row whose applicability is UNKNOWN (part 1 §4, P5). Exceptions are read only where the ledger and the governed tree share a repository (`lib/obligations.sh:212-215`) | an exception's limit to pre-release transitions (part 2 §3.2) |
| S7: edit strictness | `_felix_escape_shrank` (`lib/escape.sh:267`) | removing a row escapes | an in-place edit of a row escapes too, because the old line is gone (order and a trailing comma are ignored), so a tightening edit goes to a person as well. That fails closed, and S7 would narrow it | S7's order |
| S8: authority hold | `felix_obligations_blocking` (`lib/obligations.sh:249`); `felix_exception_for` (`lib/exceptions.sh:339`) | pathway `unknown` blocks before any exception, and no grant clears it | a non-blocking row with pathway `unknown` holds nothing, because the class is read first (`:246`). S8 keeps that (D24) | the `authority_hold` code |
| S9: probabilistic is advisory | `_felix_obligation_scan` (`lib/obligations.sh:102`); `lib/candidates.sh` stamps `probabilistic` | yes | — | — |
| S10, part 1 §3.3: reason codes | `felix_obligation_state` detail text; `cmd_obligations` (`felix:6007`) prints applies, discharge and a detail column | `excepted` is marked; a failed checker and an unrun one are told apart by their sentences | codes are sentences, and no precedence is defined | the closed code set; the transition hold codes |
| AD1 to AD9: the admission transaction | `felix_candidates_rules` and `felix_candidates_record` (`lib/candidates.sh:79`, `:137`) | a proposal is recorded with its provenance and epoch, and a model's class is never downgraded quietly | admission is a person copying a row and committing it. Adding a blocking row fires no escape channel (direction §5, "the admission line is a convention") | the hold by pathway (`admission_pending`), qualification by the authority, the order of admission before acceptance, and AD7's separation |
| AD10: intent | none | — | — | intent records, whose admission authority is open (part 3 §4), and the leases AD10 times them against |

### 1.3 Applicability (part 1 §4)

| Rule | Today | Enforces | Differs | Missing |
|---|---|---|---|---|
| P2: one side | `felix_obligation_state` (`lib/obligations.sh:136-148`) | 0 is ACTIVE; 1 is DORMANT; 126, 127 and any other status are UNKNOWN, which blocks. Since 2026-09-16 a crash no longer reads DORMANT | read on the checkout only. No timeout is set and the output is not read (`_felix_probe_ask`, `lib/probes.sh:173`) | P2's timeout |
| P1, P3, P4: both sides | none | — | a candidate whose `applies` reads DORMANT retires its own need | the base-side reading and the table. Direction §5 ("Before row 27 arms anything", "A change must not blind its own hold") already asks for this |
| P5: UNKNOWN blocks on its own | `felix_obligations_blocking` (`lib/obligations.sh:243`) | an UNKNOWN row blocks through `$5 != "SATISFIED"`, because its discharge is UNKNOWN as well | an excepted TASK_BLOCKING row is passed before that test (`:250`), and `felix_obligations_run` looks up a grant for every row that is neither DORMANT nor SATISFIED (`:212-213`), so a grant clears UNKNOWN applicability | A1 as a clause of its own |
| P6: clearing `subject_removed` | none | — | — | the code, intent, and the founder's authorization |
| P8: `applies` as a checker | `qualification.tsv` qualifies checkers named by id | — | `applies` commands are not qualified | P8's seeded cases |
| P10: grounds | `felix_obligations_orphans`, `felix_obligations_ungrounded` (`lib/obligations.sh:258`, `:274`) | an orphan grounding is refused; an ungrounded row is counted | — | — |

### 1.4 Evidence and suspensions (part 2 §1 and §2)

| Rule | Today | Enforces | Differs | Missing |
|---|---|---|---|---|
| E1: evidence records | none; an evidence command's output is its coverage report (`lib/obligations.sh:30-32`) | the coverage report's form | discharge is computed on each run and not kept as a record of its own. The gate keeps one receipt for the tree | the record |
| E2 to E6: closure and partition | `FELIX_ESCAPE_TABLES` (`lib/escape.sh:78`), the `execute` channel (`:116`), `risk.tsv` confines (`_felix_escape_confined`, `:180`; `count:` in `_felix_escape_fewer`, `:239`); `gate.sh` binds only after it lands (design §4.1) | some instrument parts are guarded by path: a deciding table may not shrink, a workflow change escapes, the suite may not count fewer assertions. The manifest confine is today's form of a mixed-file split | outside those guards and the merge judge's copy of main's engine, the instrument comes from the candidate's tree. The evidence command runs `bash -c` in the candidate's checkout (`lib/obligations.sh:150-151`), so a script it calls is the candidate's | the I/O gateway, the observed closure, the partition in P |
| V1 to V7: validity | `felix_verify_current`; C9 | the subject by tree (V1); C9 is a provider run read directly for the exact commit, with the newest run deciding (V4 in part, E8) | the gate receipt is written by the session, and a session can write that file (`lib/escape.sh:500-507`). C9 is read with the session's `gh` login, not the authority's identity, and only for a receipt reporting `tests:reused` | V2, V3, V6 and V7 as written |
| CI1 to CI4 | `_felix_merge_gate_held` (`lib/escape.sh:536`) | only the named gate workflow counts, and an answer about another commit is no evidence | it does not check that the run executed P's closure. A pull request's run uses the candidate's workflow file | CI2's authority rerun and `instrument_changed` |
| E13 to E15: qualification by content | `felix_qualify_run` (`lib/qualify.sh:317`), six controls; `felix qualify --gate` | the six controls; refusal of a held control, a checker never shown failing, and an unreadable table | rows are keyed by checker id and command, not by the content of the checker or its closure, so an edited checker keeps its rows. Qualification runs in a worktree of the candidate's HEAD | content binding; the authority's seeds; control 7 (roadmap Phase 1) |
| X1 to X9: escapes and suspensions | `lib/incident.sh` turns an error into a brief for a fix | — | it does not tie the error to the receipt or the evidence that let it through, and it suspends nothing | the escape and suspension records, scope, and repair |

### 1.5 Transitions and observability (part 2 §3 and §4)

| Rule | Today | Enforces | Differs | Missing |
|---|---|---|---|---|
| T1, part 2 §3.1: transition types | two moments: the gate (task) and `felix merge`. The merge reads obligations in `release` mode (`lib/escape.sh:742`) | — | the merge is treated as a release: RELEASE_BLOCKING and AUTHORITY_BLOCKING hold it, and TASK_BLOCKING is dropped (`lib/obligations.sh:247`). TASK_BLOCKING reaches a merge through the gates that must pass first: the local gate receipt for the implementation tree (`cmd_gate` runs `cmd_obligations --gate`, `felix:968`) and, under land on green, CI's gate run on the exact head (row 24). Under T1 a merge reaching no effect requires TASK_BLOCKING needs on the combined revision, with exceptions allowed. That is a tightening (D2) | `artifact`, `deploy`, `operate` |
| A1 to A3 | `felix_obligations_blocking` (`lib/obligations.sh:243`) | clauses 2 and 3 at the task and release moments, as design §4.6 says | A1 is not its own clause (P5, above). An exception can clear any TASK_BLOCKING row that is not SATISFIED | A2a's task scope: direction §5 records that a failing TASK_BLOCKING row holds every pull request |
| A4 | none | — | — | `admission_pending` |
| A5: inputs from P | `felix_escapes` (`lib/escape.sh:305`), `_felix_kernel_blockers` (`felix:1728`), `felix_merge_handoff` (`lib/merge-judge.sh:106`) | the verdict is formed by a copy of main's engine; shrinking a deciding table escapes; exceptions come from the remote-tracking main; `gate.sh` binds after landing | other inputs come from the candidate tree (design §6). The merge judge's known gaps, from its header and the 10-31 design's §4.8: a branch whose felix no longer hands off judges itself; an entry run in place sources its own libraries; a same-user process can swap the copy; a SIGKILL leaves the copy behind | the enumeration of every input (step 3) |
| A6: residual | none mechanical; by hand, a B3-and-above PR that states a limit opens as a `needs-founder` draft (row 39) | the founder's stop, by hand | — | residual lists in evidence, and B-class computation |
| A7, T4: effects and the release interim | `felix_escapes`: `execute`, `durable`, `disclose` (`lib/escape.sh:116`, `:153`, `:358`) | a merge that runs a workflow change, a migration or destructive SQL, or adds a credential escapes to a person | the stops are by path and by what was added, at the merge, whether or not the merge reaches a deploy. Felix deploys its own engine after merging (row 4) in a step of its own, not as an authority transition | O3 to O7, `release_unauthorized`, and founder release authorizations |
| T6, T7: every clause, and the denominator | `cmd_obligations` (`felix:6007`) prints active, dormant, unknown, blocking and excepted counts, and the ungrounded count | a denominator in part | no clause list; no count of needs about other subjects | T6, and T7 in full |
| T8: who evaluates | `felix merge` through `felix_merge_handoff`; the land tick (row 24) | main's engine forms the verdict | runs on the founder's Mac, under the session's user | the hosted authority (step 3, row 43) |

**One worked example, as an example and not the set: felix-home under part 2 §4.** Its one workflow, `gate.yml`, runs on pull requests and on every push to main. Its token permissions are read-only (`contents: read`, plus `pull-requests`, `actions` and `checks` read for the push-only `reuse` job), and it references no secret. Under O4 that shows no credential, not that there is no effect, so it would read `unknown` until declared. Whether the authority's identity can read the repository's webhooks and installed apps depends on the permissions it is granted, and whatever it cannot read needs a declaration too (O5). A declaration of `none` by the founder can cover both, keyed to their fingerprints. Until that declaration exists, T4 would fail every felix-home merge closed once the authority governs felix-home. That is the false block O8 counts.

### 1.6 The method's contract (part 2 §1.8 and §5; new in revision 1)

| Rule | Today | Enforces | Differs | Missing |
|---|---|---|---|---|
| MD1 to MD4, MD7: a need's model | `obligations.tsv` has the columns `obligation class pathway applies evidence grounds? reason? needs?` (`templates/schemas.tsv:75`) | — | a need has no model, so no failing case can be placed outside anything | a `model` field and its version (R4, R5); S7's order for it in `_felix_escape_shrank`; the codes `outside_model` and `model_unstated` |
| MD5, MD6: reading a case, and the derived result | `felix_obligation_state` (`lib/obligations.sh:150-163`) | the status readings MD6 keeps: 0 is SATISFIED, 2, 126 and 127 are UNKNOWN | the result is the exit status alone. The evidence command's output is its coverage report, with a verdict for each member (`lib/obligations.sh:30-32`), and only its last line reaches the detail. No file read parses the per-member verdicts, and there is no descriptor | the descriptor, the membership reading, and the derivation |
| MD8: the model control | `felix_qualify_run` (`lib/qualify.sh:317`), six controls | the six controls. Its header says the mutations "must be authored by something that has not seen the checker" and that this "cannot be enforced" (`:59-62`) | no control concerns a model | the model control. Control 7, the coverage report, is roadmap Phase 1's |
| MD9: a model arms nothing | the ratchet (`lib/qualify.sh`, header) | a control nobody declared refuses nothing | — | the receipt that prints both results |
| SO1 to SO7: checker kind and context | `qualification.tsv` has the columns `checker command control expect mutation premise?` (`templates/schemas.tsv:71`). `felix_candidates_record` (`lib/candidates.sh:137`) records who proposed a candidate | a checker is named by an id and judged by its controls | there is no kind, and no record of what a checker's author saw. A proposal records who made it and not what that author was shown | `kind`; `requirement`; the lease and the context it records; a qualification that reads the kind from its seeds (SO7) |
| PK1 to PK5: the review packet | `lib/review.sh` records a verdict for a surface no test can judge (`felix_review_record`, `:57`; `felix_review_passed`, `:144`) | a verdict is keyed to the exact tree, and a missing or blocking verdict behaves as no pass (`:32-34`) | it is a different review. A `pass` verdict clears the `reviewed` escape (`:27`), where PK4 makes the residual review advisory, unable to clear or block. Its header says independence cannot be checked (`:35`) | the residual review's packet, its program check, and its measure. No file read builds a packet |

## 2. Which steps of direction §5 the design's steps 3 to 9 replace

Direction §5 item 0 and row 51 say: where a step of item 4 does what a design step does, the design step replaces it, and this specification writes that mapping down. By Felix's reading of that delegation, the replacements below bind once this specification lands, and folding them into direction §5's own text is a direction edit, owed in the next fold, for the founder's yes. The design's steps are:
- **3:** separate the authority;
- **4:** the queue owns landing;
- **5:** shard the suite;
- **6:** the class-rule catalogue;
- **7:** the Rust spike;
- **8:** reuse, then batching;
- **9:** release and operations.

### 2.1 Item 4: the trust track

| §5 step | What it does | Design step | Verdict | Why |
|---|---|---|---|---|
| 0cw trust item 2 | merge refuses a receipt that skipped checks | none in full; step 3's authority, once it runs the contract itself, makes it moot | **Stays** | It closes a live gap in today's interim authority: a declared contract run in part and then called green (design §2). Its spec and blind assertions exist (`audits/2026-10-01-report-v5-review/specs/skipped-receipt/`). "Before step 8" now reads "before design step 4" |
| 7 | a readiness status on a head the author's gate passed, and the closing-notice line | 4 | **Replaced** | Entry to the queue is the queue's own signal. The author's gate is advisory (design §4.7). The closing-notice line is a surface (row 20), and it moves with step 4 |
| 8 | the actor's core, in shadow | 4, with 3 | **Replaced** | The queue owns landing, and the authority decides. Shadow-first carries over |
| 9 | restart step 1a | none | **Stays** | Restart moments are not trust-plane work (`docs/2026-09-23-restart-moments-scope.md`) |
| 10 | attended landing | 4 | **Replaced** | Land on green (row 24) stays the landing path until step 4's queue replaces it |
| 11 | version, `red.tsv` and manifest written at landing, armed | 4 | **Replaced** | What landing writes becomes a requirement of step 4 |
| 12 | post-deploy verify and full rollback | 9 | **Replaced** | These are needs about a deployment and an operational outcome (R18). Until step 9, row 49's interim rule holds (T4) |
| 13 | the trust base, now only for an actor that re-gates in its own clone (direction §8) | 3, with 4 | **Replaced** | The authority is that actor. Its policy-change rule holds changes to the judge's own artifacts (design §4.1; A5; row 38) |
| 14 | #304, then the judge-identity epoch | 3 | **Replaced, the remaining half** | #304 has merged. The judge's identity enters through every evidence record's instrument version and policy epoch (V2, V3) |
| 15 | the judge pinned outside the change it judges, for every checker the gate, probes and obligations run | 3 | **Replaced** | This is what step 3 does. Rows 4, 24 and 38 hold certain PRs "until roadmap step 15 pins the judge outside every change it judges". By Felix's reading, their end condition is the pin, not the step number: the holds end only when step 3 has delivered the pin and its measurement shows a worker can no longer land around the authority or change the instrument that judges it. Rewording those rows is the founder's |
| 16 | the founder's stamps leave the tracked tree | 3 | **Replaced** | Stamps become founder `authorization` records on the policy source, read with the identity the provider verified (R11, R16) |
| 17 | the scheduler and its arming brakes | 4 | **Replaced** | The brakes the land-on-green contract holds (G2, G3, A11) become requirements of step 4 |
| 18 | deny rows on raw merges and on the grant, in the founder's lane | 3 | **Stays, as the interim** | Step 3 replaces it once worker tokens cannot push or merge to main (design §4.8). That needs the hosted identity and a repository where worker tokens can be kept off main. felix-home's plan has no branch protection on a private repository (`lib/escape.sh:498-499`), and row 43's org move, which has no date, is the planned route. Until then the deny rows are the floor |
| then | at least 10 shadow agreements, 5 clean attended landings, one Elenchus shadow run, the founder's arming sitting | 4 | **Re-scoped; the sitting stays** | The counts become step 4's arming bars, fixed before its shadow runs. How much Felix lands unattended stays the founder's call |

### 2.2 Item 2: the kernel refactor and the evidence engine

| §5 step | What it does | Design step | Verdict | Why |
|---|---|---|---|---|
| The 10-31 design's step 1b, the kernel refactor | decision kernels for the trust core, checked over their whole domain | none | **Stays, re-scoped** | No design step does it. Its kernels implement this specification: `oblig_decide` is part 1 §3 and §4, `merge_decide` is part 2 §3's seven clauses, `stricter` is the two-sided table and S7, and `result_derive` (new in revision 1) is MD5 and MD6 over their finite domain. Their domains are recomputed from K1's closed types, and 1b-a's blind properties are written from this specification's rule ids. Its place behind the audit's batches 12, 10 and 20 is unchanged, and both of its PRs stay the founder's to merge (row 38) |
| The 10-31 design's step 3 | case format, linter, instantiator, per-claim receipts, `felix case` and the `case` gate check, report-only | 6, with part 2 §1 and §5 | **Replaced** | Row 50 already replaced the evidence engine's place. Per-claim receipts become evidence records (E1). Claims instantiated from classes become the class-rule catalogue. In revision 1 the catalogue is built to part 2 §5's contract: class rules, spec oracles and a model for each need, and not class rules alone |
| The 10-31 design's step 4 | the harness in the engine, pinned; the `case` blocker in shadow on two new features | 6 and 3 | **Replaced** | The catalogue's shadow measures pass rate, false blocks and time per feature. Row 39's condition, shadow on two features built after the blocker exists with bars fixed first, stays the arming condition for any blocker the catalogue adds. Revision 1 adds that the shadow does not start until a rerun of design step 1 has passed (part 2 §5.4) |
| The 10-31 design's step 5 | crash consistency at every state write, the turnstile, awk monitors over `ledger.tsv`, standing claims, the nightly sweep, a discrimination report | 4, 6 and 8 | **Replaced, split** | The lander's crash consistency and turnstile go to step 4. A crash between durable writes and concurrency on shared protocols are fault tiers (design §4.7), so they go to step 6. Standing claims and the nightly sweep are reuse, step 8. The discrimination report goes to step 6 |
| The 10-31 design's step 1, the narrow fix (#486) | the resolver's and table validator's reads through one capture primitive | none | **Stays** | It is a fix in flight, and direction §5 lets it finish |

**What the design keeps from the 10-31 design** (row 50) maps as follows:
- the claim catalogue becomes the class-rule catalogue (step 6);
- the fault model becomes the fault tiers (design §4.7);
- discrimination by mutation becomes the qualification method (part 2 §1.7);
- per-claim receipts become evidence records;
- the judge pin is step 3.

**Outside the set asked about, noted only:** item 5's qualified-judge join is where V2 first binds. This mapping does not replace it.

**A dependency, not a placement.** Step 1b-b and step 3 rewrite the same decision code (`lib/obligations.sh`, `lib/escape.sh`, the merge judge). Written once as kernels against this specification, that code serves both. Writing it twice would mean rewriting the same files two times over. Placement stays as direction gives it.

## 3. Decisions made here

Each decision fills a gap in draft 5 or settles a conflict in it. Design questions are Felix's. None of these needs the founder, because each one does one of three things: it tightens, it reads the design's text where the text was silent, or it follows a rule the engine or direction already holds. Some are not the most closed choice available, and their reasons say why:
- D7 follows rule C9 rather than letting any earlier failure block;
- D12 lets the candidate decide a first release;
- D14 and D28 count a run without a gateway, on the partition's word;
- D22 defers enforcement to the arming already decided;
- D27 limits pre-existing failures as row 27 requires;
- D31 to D34 move failures from blocking to advisory, each only on a positive reading, a ground and a passing model control, and D34 keeps all of it unarmed until the founder's arming rules hold.

| # | Decision | Why |
|---|---|---|
| D1 | A revision's identity is its tree, plus inputs recorded outside it (R19) | Evidence about a tree is about its content. Receipts are already keyed this way. Evidence then carries from the implementation revision to the combined revision only when the trees are equal |
| D2 | A merge that reaches no effect requires TASK_BLOCKING needs on the combined revision, with exceptions allowed (T1, part 2 §3.2) | §4.6 makes the subject decide when a need is checked. Today's merge drops TASK_BLOCKING and leans on the receipt for the implementation tree. A tightening |
| D3 | An exception clears only a TASK_BLOCKING need held by `failed`, `could_not_examine` or `not_run_for_subject`. It never clears UNKNOWN applicability, a subject removal or a suspension (P5, A1, A2) | §4.3 says "no evidence result can override it", and a grant is weaker than evidence. §4.3 clears a removal only by evidence or authorization, and §4.4 holds a suspension until repair. Today a grant clears any TASK_BLOCKING row that is not SATISFIED, so this is a tightening |
| D4 | Need codes gain `authority_hold` and the secondary `base_unknown`; transitions get five hold codes | Three of the seven clauses had no code, and an unknown base "listed" had no form. A held transition that printed nothing would be the emptiness-as-clean defect (`lib/receipt.sh`, header) |
| D5 | The primary-code precedence of part 1 §3.3 | Receipts must be deterministic (K5). The order runs from the most basic fact to the least |
| D6 | Validity includes "not suspended" (V7) | Otherwise a suspended checker's old evidence would keep counting |
| D7 | The newest valid record decides, and earlier failures are listed (E8) | C9's rule. Only the authority writes records, so a worker cannot add a newer one |
| D8 | No valid record makes discharge UNKNOWN, not UNSATISFIED | Nothing was examined, and unknown is never clean. Both block |
| D9 | S7's strictness order; any edit it cannot compare counts as loosening | A tightening has to be shown mechanically, or it is not one |
| D10 | A proposal holds by its pathway, whatever class it proposes; a holding proposal cannot be withdrawn by its proposer; a failed qualification sends it back rather than rejecting it; an admission change touches only the policy source (AD2, AD3, AD7) | §4.2 holds on "could make it blocking". Each one closes a way for a change to unbind or escape its own need |
| D11 | "Before the work began" means landed before the lease the task was dispatched under, and contained in its base. With no lease, no intent authorizes a removal (AD10) | A lease is written by the dispatcher before the work starts. A change request's creation time can follow the work, and a rebase can put an intent into a base after the fact |
| D12 | The base for each transition type; with no prior subject, the base side reads DORMANT (P1) | §4.3 defines the table and not its inputs. DORMANT lets the candidate decide, which is what a first release needs |
| D13 | A mixed file with no split for its ecosystem is wholly instrument (E6) | Fail closed. The false blocks are counted |
| D14 | Until a gateway runs on provider runners, a provider run counts only when the workflow is P's and the candidate touches no instrument path (CI4) | It can be checked from the diff. It cannot see what a step runs, so the authority runs the closure itself otherwise |
| D15 | Suspension scope starts at `version_class`; narrowing needs a witness or a person; `unclassified` suspends every use; no suspension lapses with time (X4, X8) | §4.4 names the default and not who moves away from it. A narrower suspension lets more through |
| D16 | An observation can show an effect, never its absence; absence needs a declaration, which widens; the surface catalogue must be covered (O4, O7) | §4.8: "Incomplete observation is never turned into a claim that a merge is reversible" |
| D17 | A merge that reaches a deployment is judged under both the merge rule and the deployment rule (T2) | §4.6's sentence leaves open whether the combined revision's needs still hold there. They do |
| D18 | Seven record kinds beyond §5's five (part 1 §2.1) | Each has a different writer and invalidation rule, and §5 requires one writer per field |
| D19 | No ignorable fields; versions are exact (R4, R5) | An ignored field may be one that narrows |
| D20 | A forked chain reads UNKNOWN (R8) | A reader cannot tell which of two current records stands |
| D21 | A release authorization names one subject and one target, and serves that subject alone (T5) | Row 49 says "by name". Reusing it would let a merge's subject change under an approval |
| D22 | The qualification of `applies` binds with the qualified-judge join; until then it is printed (P8) | Arming is the founder's call (the `lib/qualify.sh` ratchet). The two-sided table carries the safety meanwhile |
| D23 | `task_complete` is the authority's decision; the worker's gate is advisory (T3) | §4.6 lists task completion as a transition, and §4.7 makes the worker side advisory |
| D24 | An authority hold is a blocking need's; a non-blocking need with pathway `unknown` holds nothing (S8, A3) | Today reads the class first, and part 2 §3.2 says INFO and ADVISORY never hold |
| D25 | Superseding an AUTHORITY_BLOCKING need, or one in row 40's classes, is the founder's; `authorization` records are the founder's (part 1 §3.2, §2.1) | Rows 40, 48 and 49 give these to the founder. A person's supersession would get around row 48 |
| D26 | Until step 9, needs about an artifact, a deployment or an operation are counted and not evaluated, and a release proceeds on the founder's authorization by name (T4) | Their subject does not exist before the transition, so evidence about it cannot. Requiring it would hold, with no way through, every authorized release that has such a need |
| D27 | Task scope for derived rows: a row already failing on the base holds only a change that touches its grounds' surfaces (A2a) | Row 27, bound 1, and direction §5's build list for it. Draft 5 does not mention it, and dropping it would contradict a founder decision |
| D28 | Nothing is subject by default; an unclassed item voids a run; without a gateway a run counts only when the candidate changed subject paths alone (E4a, E5) | §4.4: the closure is "recorded from what the check actually read and ran ... not from a list". A default of subject would let an executed file the partition missed judge from the candidate's tree |
| D29 | A base that cannot be looked up reads UNKNOWN; a B-class that cannot be computed reads as B3 and above (P1, A6) | Unknown is never clean |
| D30 | A release authorization is a change of its own, not the merge of what it releases; `supersedes` is a list, and a suspension ends with a `lifted` record (T5, R8, X6) | Row 49: release authorization is never taken from merge authorization. R8 resolves a fork with one record that names both branches, which a single `supersedes` id cannot do, and R9 keeps a chain to one kind |
| D31 | A need may state a model. A fault or an input is `outside` only by a positive reading: a fault class read `not_met`, or a domain predicate that rejects the value. Everything else is `unknown` and counts inside. A need with no usable model reads exactly as today (MD1, MD2, MD5) | Step 1's false blocks were mostly faults and inputs that no deployment meets (4 of 5). A waiver needs a positive reading and a ground, because unknown is never clean (K2). With no model nothing changes, so no existing need is loosened |
| D32 | The authority derives the result from the exit status and the cases. A failure whose every failing case is `outside` passes, and a failure that names no failing case fails (MD6) | The coverage report already holds a verdict for each member and no file read parses it (§1.6). Reading it is the only way to tell an outside failure from an inside one. A status failure with no named case has nothing to place outside |
| D33 | A model is authored, kept independent and qualified like a checker. An unqualified model reads as not stated. Removing a model or an exclusion tightens, and every other change loosens. A proven outside case suspends the model at scope `model`, free (MD3, MD4, MD8, X3) | A model written by whoever produced a change could exclude that change's own defect. Widening a domain tightens in fact but cannot be shown mechanically (D9) |
| D34 | A model arms nothing by itself. Until part 1's arming rules hold, the receipt prints the result both ways and the result without the model decides (MD9) | How much Felix may block is the founder's call (`lib/qualify.sh`, header), and waivers are the direction in which that call matters most |
| D35 | A spec oracle is a checker kind whose author's context is `blind`, read from the dispatch and not from the author. The kinds are closed. A kind is read from the qualification's seeds, and two distinct sites or regions is the least that makes a class (SO1 to SO7) | Step 1: 10 of the 18 catches were a class check, the labels often misdescribed the checks behind them, and the R1 to R8 catalogue fit 7 of the 18 defects. Context cannot be verified until leases exist, so it reads `saw_implementation` without one (E12) |
| D36 | The review packet carries no findings, a program refuses one that does, and the review's output is advisory, with its own contribution measured apart (PK1 to PK5) | Step 1's held-out reviewers held on 25 rows, each already in the packet, so the review's own contribution could not be measured |
| D37 | The method's contract binds its tooling and the catalogue from this revision. The method does not advance to the prospective trial until a pre-registered rerun passes. Fault tiers and mutants stay in the method with their contribution unmeasured (part 2 §5.1, §5.4) | The step 1 report's verdict. Dropping the tiers would rest on the absence of evidence from runs that barely used them |

## 4. Open, and where each belongs

These are the questions seen so far. More will come.

| Question | Where it belongs |
|---|---|
| How needs are found and how complete the list is; who writes each checker; leases and dispatch; discovery; turning escapes into needs | the capability plane's design (row 42) |
| Who admits an intent, and by what act; and leases, which AD10 times intents against | the intent design's §11, first decision; direction §6; leases in the capability design (direction §5 puts leases with real authority after March) |
| Who stands in for "the founder" of rows 48 and 49 on a product Felix governs (the 10-31 design reads "the project's owner") | the founder, when a product's first release or removal reaches the authority |
| How the candidate side of a need about an artifact, a deployment or an operation is read before its subject exists (T4, D26) | step 9 |
| How complete each repository's partition is (E5), and the false blocks unclassed items cause | step 3, measured |
| **Whether row 49's interim rule covers Felix's own engine deploy once the authority governs felix-home.** Row 4 has Felix deploy after it merges. Row 49 makes every deployment transition wait for the founder's authorization by name until the release subsystem exists. Typing `engine_deployed` as a deployment need would bring the same question forward. By Felix's reading, nothing changes before the authority governs felix-home's deploys, because this specification arms nothing | the founder, asked once, when step 3 or step 9 first reaches felix-home's deploy |
| Whether landing and releasing are separate steps when a merge reaches no effect | direction §6; to be tried natively first |
| Each ecosystem's split of mixed files, starting with felix-home's | step 3, then one ecosystem at a time |
| The I/O gateway, and how complete its view is | step 3, and the Rust spike (step 7) |
| The wire encoding; how the store is retained and compacted | step 3; step 8 for reuse |
| The surface catalogue's first members (O7) | step 3, from what the provider documents and its identity can read |
| Founder identity on the provider, and the hosted identity | step 3, with the org move (row 43) |
| Exceptions and the policy source for a product project whose tables live in felix-home | direction §5, "Before row 27 arms anything" |
| Every bound and bar: false-block bounds, arming bars, B-class details | the founder from shadow data (row 39); bars fixed before each shadow runs |
| How an escape's fault class is decided | the fault model's owners, step 6 |
| Whether flaky evidence needs more than "the newest decides" | step 4 and step 8, from measured reruns per PR |
| Whether declarations need an expiry beyond their fingerprints | step 3 and step 9, measured |
| Comparing edits to evidence or `applies` commands for strictness | later, if founder stops from in-place edits are measured |
| Who states a need's first model, and from what facts about its deployment, on a product Felix governs | the capability plane's design (row 42) for finding and writing it; the owner of the deployment for the facts |
| How a case's fault label is read once a gateway records what a run injected (MD5) | step 3 and the gateway. Until then the label is a claim, and the model control tests it |
| Whether two seeded sites or regions is enough to tell a class from an instance (SO7) | measurement, in step 6 |
| How the authority verifies a checker author's `blind` context before leases exist (SO3) | the capability design's leases (direction §5, after March). Until then a measurement records its own dispatch |
| Whether stored cases can be read again under a changed model without a rerun (MD2, V3) | step 8, reuse |
| Whether the three changes bring the false blocks under the bar | the rerun, pre-registered (part 2 §5.4) |
| The historical set's gaps: the T1 sweep over every site the surfaces run, the differential under faults, the full mutant sample | the catalogue, step 6 |
| Whether the class-rule catalogue generalises beyond bash, where it was derived (it fit 7 of the 18 held-out defects) | the catalogue, step 6 |
| The engine's language | row 6, after step 7 |
| How Felix is sold | the founder (design §12) |

**Risks this specification adds to design §11:**
- **The hold codes and D4 may need new members.** Anything they do not cover reads UNKNOWN.
- **D2 adds TASK_BLOCKING checks at the merge.** Their false blocks are counted.
- **D11 sends every subject removal of a TASK_BLOCKING or RELEASE_BLOCKING need to evidence or a person until leases exist.** Those interruptions are counted.
- **D28 voids runs that touch an unclassed item** until each repository's partition is complete. Those false blocks are counted.
- **The declaration felix-home needs (part 3 §1.5) is a founder act** before the authority can land anything there.
- **A model is a waiver.** One that is too wide turns a real defect into an advisory. The rerun's recall and the escapes measure it, and MD9 keeps it unarmed meanwhile.
- **A blind oracle may not run on a correct change,** for example on an interface mismatch, and an oracle that cannot run blocks (E8). The rerun counts those blocks.
- **Context `blind` cannot be verified** until leases exist (SO3).
- **Step 1 is one set** of 18 cases from three authors, and the three changes were chosen after its results were seen. A pass on that set would show nothing about them. A fresh set can show it, and the rerun uses one.
- **Self-review.** This specification can still settle something it should not, and the closure check in `~/CLAUDE.md` is the guard.
