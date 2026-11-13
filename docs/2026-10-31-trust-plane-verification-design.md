# Felix trust plane: evidence-carrying changes, designed at frontier level

Design document, written 2026-10-30 and revised 2026-10-31 after two critics read it. It synthesises a design workflow made up of two grounding stages, four research stages, five competing designs and three judges. It is a design on file, and nothing in it is built. §13.3 lists what the revision could not settle or did not do. It was fact-checked on 2026-10-31. Ten checkers compared 543 claims with their sources, a second reader tried to refute each finding of consequence, and 99 corrections were made. 47 claims could not be checked: the judges' verdicts, which are not filed, git and engine runs the checkers were not allowed to make, a few papers that could not be fetched, and estimates with no measurement to compare them with. The founder answered §11.1's seven decisions on 2026-10-31. §11.1 records each answer, and §4.8 and §10 follow them. One answer, to decision 5, differs from the recommendation.

**How this was written.** I read all eleven workflow files in full: g1 to g6, and d1 to d5. The three judges' verdicts were in an earlier stage's task text. They are not filed in the workflow directory, so a claim credited to a judge here cannot be checked from a file, and none of the decisions below rests on a judge's vote alone. I changed no file in any repository, in `~/.claude` or in `~/.felix`, and I ran nothing in the lane-counter worktree. I checked these myself:
- Read-only `sed`, `grep` and `wc` on main, in the home checkout `/Users/a14808/Documents/Felix`, at `cc238b25`. It declares 0.49.317 in `engine/.claude-plugin/plugin.json`. The lane build forked from main at `c170ed5f` (0.49.315), which I read with `git merge-base`.
- The v3.2 spec and its amendments, the constitution's invariants, `docs/direction.md`, the audit register and the reach-checks design.
- The bash 3.2 man page's `extdebug` text, on this Mac.
- The sixteen memory notes listed in Sources (two for their dates only, five by their index lines), and `g2/measure.txt` in the workflow directory.
- `git diff --stat` of `claude/audit-combined` and `origin/claude/audit-combined` against main, for the trust-core files only.

**Nothing in this document was executed.** Not every stage could run commands. d1, d2, d5 and g3 say a guard refused them bash. d4 ran two read-only git commands, and g2 ran its own Python scripts over the workflow journals, with `git log -S`. No stage ran Felix, a test or the gate, and the revision ran only reads. So every time, cell count and catch rate here is an estimate unless a measured source is named. §9 is the run that tests them.

**Where files live.** "The workflow directory" means `~/.felix/memory/felix/audits/2026-10-30-trust-plane-design/workflow/` in the memory root. The stages wrote their files in a session scratchpad under `/private/tmp`, and they were copied there on 2026-10-31, when this design was filed. In it:
- g1 to g6 are `g1-trust-plane.md`, `g2-slice0-data.md`, `g3-simulation.md`, `g4-generated-tests.md`, `g5-spec-formal-market.md` and `g6-design-deliberation.md`.
- d1 to d5 are `d1-invariant-compiler.md`, `d2-simulation-substrate.md`, `d3-evidence-carrying-change.md`, `d4-adequacy-search.md` and `d5-proof-where-it-pays.md`.

---

## In one page

**The problem.** Slice 0 of `felix lane` took 2.9 h to build and then 21.5 h of wall time to check through review 3 round 3 (about 22.5 h with round 4 and the final check):
- seven serial review rounds, then an eighth, and two chains the lead set;
- 46 findings, then 49;
- 129 hand-written assertions.

The largest share of the findings, 20 of 46, and 20 of the 26 on fault paths, was one property: a read, write or resolution that does not finish must never yield a value. It was found one read at a time, under faults the reviewers made up as they went. 17 of the 46 findings were created or left open by an earlier fix, and each was caught only by a later review round, often not the next one, from under an hour to about eight hours after the fix. On my reading of main, the release path that decides what lands has the same gap (§1.4).

**The loop now in force is no longer that loop.** Since 10-30, `lane-slice-review-budget.md` caps slices 1 and 2 at the first-build review plus at most two fault-injection rounds, and sends fault classes in shared code to the trust plane. On g2 §3's per-round agent-minutes, that cap would have cost slice 0 about 5.4 h of serial agent time (R1, R2.1, R2.2), or 7.8 h with the R1a chain. It is bounded, and it buys that bound by giving up coverage: no denominator, no evidence that its checks can fail, and shared-code faults left as stated limits.

**The decision.** A change no longer reaches the lander as a diff with a green suite. It arrives as an **evidence-carrying change**, which carries a **case**. The case has five parts:
- claims, mostly generated from a versioned catalogue of claim classes;
- evidence for each claim, produced by machine search over a stated fault model, with a printed denominator;
- evidence that the evidence can fail, from mutation and a positive control;
- a residual computed by the engine, never reported by the author;
- per-claim receipts that go stale when their inputs move.

Models propose claims, generators, fault kinds and mutants. Mechanisms decide. `felix merge` reads the case: READY, HOLD or ESCALATE.

**Where it comes from.** The spine is d3, for its fit to v3.2's objects (§11.2 #1). Grafted onto it:
- from d1, the schema-derived information order as the main oracle, plus its planner and its replay protocol;
- from d2, the safety order for deciders, the determinism envelope, crash consistency and interleavings;
- from d4, the "indistinguishable" mutant class and coupling measured on Felix's own faults;
- from d5, first and above all, decision kernels checked exhaustively for the trust plane's own core (each read found, empty, blind, not-applicable or did not finish), one observation primitive, and a mechanical check that a spec has not widened.

**What it should cost** (estimates; the per-run cost t was measured only for a bare run, and S, K̄ and the layout factor are unmeasured, §5):
- Slice 0: about 9 h of checking after the build at central constants (about 12.5 h if the final run forces one more loop), with bounds from about 5 h to over 30 h. That is against 21.5 h for the uncapped loop, and about 5.4-7.8 h of serial agent time for the capped loop now in force.
- **So on these constants the method is not faster than the policy in force. Its case rests on strength:** a printed denominator, evidence shown able to fail, a computed residual, and shared-code faults found rather than stated as limits. Speed depends on two unmeasured levers, a lower per-run cost (a fork-server) and sound reach-scoped reruns (the function-entry tracer). With both at the values §5.3 assumes, slice 0 comes to about 4.7 h, level with the cap or a little faster.
- A feature ten times larger: checking about 30-70 h after the build (central about 47 h), about four times the build, and about 60 h end to end. With both levers, about 25 h, twice the build. It is not at parity. The capped loop is bounded at 10x too, likely cheaper, and weaker.

**What it claims.** "Checked within fault model FM-n, over N cells, with discrimination shown and the residual listed." It never claims "verified". The floor is unchanged: receipts are unsigned same-user files, and `gh pr merge` skips `felix merge`.

**What happens first.** Measurements, then one narrow fix. None of it is new engine design, and none of it needs a founder act while CI runs (§13.2 names one reading of direction §5 that could change that for item 4):
1. A spike of the bash 3.2 DEBUG trap, including the status a skipped command leaves and whether function entry can be traced.
2. A replay of slice 0's history in three parts, with its bars declared before it runs and its compute budgeted under the Mac-wide slots. It includes a sweep of main's own release core.
3. A replay of the design-deliberation stages on slice 0's design.
4. The trust-plane PR already owed, kept narrow: the shared resolver's and table validator's reads go through `felix_capture`, with a read that did not finish mapped to unknown, red-first from the sweep of main's core.

The founder placed the kernel refactor of the trust core on 2026-10-31 (decision 2), right after the audit's batches on its files, batch 20 among them, which waits on plan A (direction §5); by Felix's reading of decision 4, both its PRs wait for the founder's merge. The enforcing engine is built beside plan A after the audit, and only after the replay and the prospective tests on two features pass.

**The founder decided the seven on 2026-10-31** (§11.1), six of them as recommended:
- Felix claims "checked within a stated fault model", never "verified", in receipts, pitches and applications (until the evidence engine exists, by Felix's interim reading, a text says only what ran; direction row 36);
- the kernel refactor goes right after the audit's batches on its files, and the enforcing build beside plan A after the audit, once the replay and two prospective tests pass;
- the blocker arms after a silent shadow on two new features (by Felix's reading, built after the blocker exists) meets bars fixed before it runs, and holds only while false blocks stay under a bound the founder sets from that data;
- PRs that change the checker's claim catalogue, fault model, oracle, case evaluator and decision kernels, and, by Felix's reading of the question's "the code that computes a verdict", the reference kernels, properties and abstraction map (with its concretisation) that judge them, and the tables that make its cells and mutants (`effects.tsv`, `bytes.tsv`, `layouts.tsv`, `operators.tsv`; §10), wait for the founder until roadmap step 15 pins the judge outside every change it judges;
- hand assertions are retired only by hand merge; once two features' trial data show that planted faults stand in for real bugs, Felix asks again;
- the four claim classes are admitted as RELEASE_BLOCKING after the shadow, only the founder clears a wrong hold in them, and a base defect is inherited only after the founder accepts it for that one shared function.

One differs from the recommendation. A narrowing no mechanism can witness holds its change for the founder only at B3 and above. At B0-B2 the change may land with the narrowed claims UNKNOWN in its receipt and residual, and no one is asked to clear them (§4.8).

Everything else is decided here, with the reason given.

---

## 1. The problem

### 1.1 What slice 0 cost

| Measure | Value | Source |
|---|---|---|
| Build stages (blind A to own gate) | 2.9 h wall, 10-29 22:48 to 10-30 01:40 | g2 §1 |
| Checking, first review to g2's snapshot (10-30 23:11, during R3.3's fix stage) | **21.5 h wall**: 1,156 agent-minutes in serial stages, plus 135 min with no agent running. Review 3 round 4 (23:13 to 23:48) and a final part check (23:54 to 10-31 00:09) followed, about 22.5 h from the first review in all | g2 §1; wf_7ba6efc7-d1c journal and transcripts |
| Rounds | 7 model review rounds to g2's snapshot (R1, R2.1-R2.3, R3.1-R3.3), then R3.4, 8 in all, plus 2 chains the lead set (R1a, item 46) | g2 §1 |
| Findings | 46 through R3.3 (19 blockers, 10 majors, 15 minors, 2 from the lead); R3.4 added 3 minors (V3R4-F1 to F3), 49 in all | g2 §1 |
| Agent-minutes by kind | review 380, blind assertions 321, fix 296, red check 138, final checks 21 | g2 §3 |
| Hand assertions for findings | 129 | g2 §1 |
| Test lines | 1,971 before review → 4,526 at `cff711ef` (+2,555) | g2 §1 |
| Engine lines | 447 → 746 (`lib/lane.sh` 499, `lib/lane-resolve.sh` 155, plus edits) | g2 §1 |
| Probe scripts left outside the suite | 125 `review*.sh`, 5,319 lines at g2's snapshot; 133 and 5,566 after round 4. 548 of those lines are generic: an injector, a classifier, a real-limit loop, a sweep and a bisect | g2 §1 |
| `felix gate` | one run on 10-10 on the old Mac (main 6063271b): 1,565 s wall, 1,298 s CPU (659 user, 639 sys: fork-bound); the suite was 91% of it. Not re-measured since | `/Users/a14808/.claude/projects/-Users-a14808-Documents-Felix/memory/gate-time-measured-2026-10-10.md` |
| The capped loop now in force, applied to slice 0 (estimate) | 324 agent-min serial (R1 86, R2.1 129, R2.2 109), about 5.4 h; 470 agent-min with R1a, about 7.8 h. Review 3 plus item 46 took 546 agent-min to g2's snapshot; these per-round figures leave out round 4 (about 35 agent-min) and the final check (about 15). The cap routes that work's fault classes away | g2 §3's per-round table; `lane-slice-review-budget.md` |
| One bare `felix lane --tsv` run | about 1.07 s CPU on real history, about 0.86 s with a one-day window, about 1.2 s wall; the hook adds about 0.14 s CPU | `g2/measure.txt` in the workflow directory |

The memory note `lane-slice-review-budget.md`, in the same memory directory, counts "built in about 4.5 h" and "about 20 h more". It ends the build at 03:14 and so includes the first review and its fixes. g2 ends the build at 01:40. The span is the same, cut at a different point. The task text's 719 engine lines and 4,558 test lines were probably taken at an earlier commit. I use g2's figures, read with `git diff --stat` at `cff711ef`.

### 1.2 What the findings were

The 46 findings break down as follows (g2 §2-§3):
- **Path.** 26 are on fault paths. 20 are on the normal path.
- **Property P1.** 20 items are one property: "a read, write or resolution that did not finish never yields a value". They took 448 agent-minutes and 86 hand assertions, counting item 46's share (30 of the 86 are item 46's).
- **Fault classes.** Fork failure 14; kill 3; process limit 1; open-file limit 2; odd bytes or layouts 9; equivalence to main 4; other 13.
- **How each would have been found.** Fault injection over every command 26; metamorphic relation 6; generated layouts 5; differential against main 4; lint 2; only a model or the lead 3. So, on g2's reading of each finding (a hand classification, not a run), 43 of 46 could have been found by a mechanical check. Five of those (F8, F9, R3-F3, V3R1-F2, V3R1-F3) would still have needed a decision from the lead once found, six with R2-F8's residual; model-only V3R3-F3 and design item 46 needed one too.
- **Created by fixes.** 11 were introduced by an earlier fix, and 6 more were left open by a fix that covered one instance of a class. That is **17 of 46 (37%)**, and 9 of 13 in review 3. One commit, `ebfa3c35`, accounts for 7 of them.

### 1.3 Why the loop was slow: three missing objects

The plan stated the property before the build. Its Global Constraints say "`unknown` is never printed or counted as `ok`", and C3 says "Any git read that does not finish ... makes the lane `unknown`" (plan at `8c5b8725`, quoted in d3 §1). What it lacked was everything that makes a property checkable. g4 §0 names three missing objects: a fault model, a generator and an adequacy number. d3 §1 adds the missing enumeration of sites, and every design agrees.
1. **No fault model.** C3 named four faults as examples. Reviewers invented the rest round by round.
2. **No enumeration of sites.** The property covered git reads only. The defects sat at `date`, `awk`, `tr`, `mktemp`, `pwd`, redirections, the shared resolver and the table validator. The reviewers' own bulk sweep, `review2-r2-c9all.sh`, ran 200 runs and reported 0 violations. It still missed R2B-F1, because it enumerated the reads a reviewer had listed, not every command the surface runs (g2 §4).
3. **No adequacy number.** Nothing said whether the 129 assertions could fail for the right reason. Nothing said when to stop.

Two scripts show that the generic method already worked in scratch, and where it stops:
- `i48-sentence.sh` ran 206 runs over 103 layouts and 2 locales, with 0 bad. That confirmed a fix for which the round's blind stage wrote 4 assertions.
- The 62-layout drift run reported 0 drift and missed V3R2-F3, because its generator had no value ending in LF (g2 §4).

The lesson: a sweep is only as strong as its enumeration and its generator's byte classes. The design is built around those two weaknesses.

### 1.4 The same gap appears to sit on the release path

These are readings of main. I re-read each line myself and ran nothing, so none of them is a finding until §9's P2 sweep confirms it, on main and on `claude/audit-combined` (§9.2).

- **`felix_merge_blockers`** (`engine/harness/lib/escape.sh:605-783`). It builds the blocker list from producer pipelines. Here is what does and does not read their statuses.
  - On a self-governed project, `cmd_merge` runs the judge as `blockers="$(_felix_kernel_blockers ...)"` and checks `krc=$?`; only 0 permits, 4 and anything else refuse (`engine/harness/felix:1919-1925`). The judge child runs under `set -uo pipefail` (`felix:1726`).
  - Once the libraries load, `krc` is the judge child's exit, whose last command is `felix_merge_blockers` (`felix:1733`), so it is that function's status, which is the status of its last statement, the commission block (`escape.sh:767-782`). So a failure in any producer pipeline earlier in the function never reaches `krc`. pipefail sets each pipeline's status, and no line reads it.
  - Eight producer pipelines are in that position: `felix_escapes ... | while` at line 615; `felix_evidence_check ... | while` at 672-673; `felix_probe_malformed | while` at 699; `felix_probes_run | felix_probes_blocking | while` at 704-705; `felix_obligation_malformed | while` at 731; `felix_obligations_orphans | while` at 738; `felix_obligations_run ... release | felix_obligations_blocking release | while` at 742-743; and `felix_commission_malformed | while` at 774. All eight are P2 targets.
  - On a project that is not self-governed, `blockers="$(felix_merge_blockers ...)"` at `felix:1927` reads no status at all, and `if [ -n "$blockers" ]` at line 1930 treats an empty list as "nothing blocks".
- **`felix_obligations_run`** (`engine/harness/lib/obligations.sh:196`). It extracts the class with `cls="$(_felix_obligation_field "$line" 2)"`. If that fork fails, `cls` is empty. The blocking filter's first rule, `$2 !~ /_BLOCKING$/ { next }` (line 246), then drops the row without a word.
- **`felix_table_check`** (`engine/harness/lib/table.sh:153`). It classifies every line in one `out="$(LC_ALL=C awk ...)"`. Line 190 tests `[ "${rows:-0}" -eq 0 ] && [ "$empty" = "refused" ]`. If the awk never ran, an empty table can pass where emptiness is allowed. This is g2's R2-F4, on main.
- **`_gt_deploy_owed`** (`engine/harness/lib/green-tick.sh:126`). It compares two `$(git rev-parse ...)` substitutions with `2>/dev/null`. If both fail, they are equal and empty, which reads as "no deploy owed". d5 §2.3 notes that `felix merge`'s own judge check may close this a second time; neither d5 nor I checked that.

**Counts.** Across seven trust-core files there are 348 raw `$(` and 0 calls to the checked-capture primitive `felix_capture` (`engine/harness/lib/detect.sh:202`). The files and their counts are `resolve.sh` 83, `table.sh` 13, `obligations.sh` 24, `escape.sh` 50, `green-tick.sh` 74, `receipt.sh` 39 and `verify.sh` 65. Those seven files hold 4,644 lines (`wc -l` on main: resolve 1,872, escape 798, verify 663, green-tick 403, obligations 389, receipt 276, table 243). My grep counted comments too, so 348 is an upper bound.

**The seven files are not the core.** The merge judge sources `resolve`, `verify`, `review`, `classify`, `evidence` and `escape` (`felix:1728`). `escape.sh` loads `probes.sh`, `commission.sh` and `obligations.sh` (lines 35-55), and `bootstrap.sh` and `detect.sh` when the C9 check needs them (lines 544-545); `commission.sh` loads `detect`, `stack`, `probes` and `final-filter`; `land-table.sh` (loaded at `escape.sh:798`) loads `say.sh`; `verify.sh` loads `epoch.sh`; `obligations.sh` loads `exceptions.sh`. Several producers of `felix_merge_blockers` live in `probes.sh`, `evidence.sh` and `commission.sh`. By a hand trace of `.` lines, the merge judge's source closure is about 10,100 lines across 22 libraries, counting `own.sh` and `qualify.sh` (which `resolve.sh`, `commission.sh` and `obligations.sh` load), `admit.sh`, `final-filter-lex.sh` and `final-filter-stages.sh`. It does not include `table.sh`, `receipt.sh` or `green-tick.sh`. Of it, the eight libraries outside the seven (`review`, `classify`, `evidence`, `probes`, `commission`, `land-table`, `detect`, `bootstrap`) hold 3,323 lines and 194 raw `$(`. A producer outside the seven that returns 0 after an unchecked internal failure hands the merge decision a definite value. So the core is defined in §4.7 as the source closure of the merge judge and the Stop hook, computed from the sourcing graph, not as a hand list.

The prose rule "an empty or unreadable input is never read as clean" appears file by file (g1 §2). Nothing checks it as a property of the engine. Direction §2 says Felix today is "a strong 'no' and a weak 'yes'".

**The audit is already on part of this.** The audit register (`docs/2026-10-24-audit-register.md`, on main) has C060, "Lookups that end in `return 0` ... still answer done when a nested fork dies", with a fix through `felix_capture`, and batches whose files include `green-tick.sh` (line 70), `escape.sh` with `classify.sh` (line 225), `resolve.sh` (line 262) and `obligations.sh` (line 401). Direction §5 puts the audit first and gives it to another session. `claude/audit-combined` changes `green-tick.sh` and `felix` against main, and none of `resolve.sh`, `table.sh`, `obligations.sh` or `escape.sh` (`git diff --stat`). I did not read which register fixes have landed.

**This is a reading, the most consequential one in the workflow, and P2 confirms or refutes it.** The trust plane cannot honestly be sold as a check while the code that decides what lands may read "a producer printed nothing" as "nothing blocks".

### 1.5 What the founder asked, and what any answer must keep

**The request,** relayed verbatim by the harness: "those handwritten assertions and the entire 20-hour checks are not the best thing, obviously"; "It's not a GitHub CI"; "the trust plane is inherently very, very sophisticated. As it should be." The task adds: far faster, scaling to much larger features, and stronger, not weaker.

**What must hold, quoted from its source.**
- **v3.2's thesis:** "Probabilistic components may observe, infer, propose, and plan. They may not make their own conclusions release-authoritative." (`/Users/a14808/Documents/UC Berkeley/Career/Founder OS/felix_v32_architecture_spec.md:11`)
- **v3.2 invariant 1:** no self-authorization (line 15).
- **v3.2 invariant 2:** "Within one decision epoch, discovery may only add constraints" (line 16).
- **v3.2 §4's admission pathways:** a single probabilistic discovery is "advisory only"; a witness-backed one "may release-block for consequential failure classes"; a critical unknown is a hold (lines 186-192).
- **v3.2 §6:** the host may challenge applicability or propose alternate evidence, and "No conversational escape hatch changes obligation state" (lines 267-280).
- **v3.2 §10:** "Budget exhaustion does not turn unknown risk into green" (line 396).
- **Amendments §1.3:** unknown is a state "which no table can declare and nothing can demote" (lines 83-86).
- **Amendments §2.2:** "The mutations must be authored by something that has not seen the checker" (lines 137-140).
- **Amendments §3:** an exception is "Not reachable by the session. The grant must not be a command the model can invoke" (lines 175-177).
- **Amendments §4's first increment:** four computed states, found, empty, blind and not-applicable; "`unknown` blocks; empty is never clean" (lines 203-205).
- **v3.2 §12:** "receipt proves only its explicit claim" (line 456).
- **Amendments §2.3**, in `/Users/a14808/Documents/UC Berkeley/Career/Founder OS/felix_v32_conformance_amendments.md`: "A candidate may not alter both the program and its judge" (line 144).
- **Amendments §2.4:** "Every enforcing verifier requires evidence that it discriminates the property it ..." (line 153).
- **Amendments §6:** "one authority still writes both the work and the judgement of the work ... Enumeration remains the weakest joint of any checker" (lines 230-232). It must be stated wherever the system reports its own trustworthiness.
- **Constitution invariant 2:** the enforcing path is bash and git only, with no network, key or model, and a model's output "may only ever narrow what the mechanical path already allowed" (`/Users/a14808/Documents/Felix/projects/felix/CLAUDE.md:96-101`), with one stated exception, the `reviewed` escape (lines 103-113).
- **Constitution invariant 5:** a gate is shown failing before it is believed.
- **Direction row 6:** "The engine stays bash, rows first. No new runtime on the enforcing path."
- **Direction row 30:** CI stays full, and a selective run takes the Mac-wide suite slots.
- **Direction row 32:** nothing stalls silent.
- **The gate-friction rule:** "Weaken no check. Anything that skips work says what it skipped and why the change cannot reach it, or it is a gate that cannot fail" (g1 §4).

---

## 2. What Felix may say it checked

### 2.1 The claim a receipt makes

A Felix evidence receipt makes exactly one kind of statement:

> For tree T, judged by the harness, fault model and oracles pinned from main at version V, claim C held:
> - over the enumerated domain D: these surfaces, these mediated effect sites (static and dynamic counts printed), these generated inputs (classes covered and classes declared impossible printed), and these fault kinds from FM-n;
> - exhaustively at depth 1, and over n sampled depth-2 pairs from seed s.
>
> The evidence was shown able to fail:
> - a known-bad variant failed it;
> - k of m mutants of the change's own lines were killed;
> - the operator catalogue's measured coupling to Felix's real faults is c.
>
> Everything not covered is listed by class.

It is LOCAL_MEASUREMENT evidence in v3.2 §11's classes, with a CI sample attached. It is evidence for its explicit claim and nothing more (v3.2 §12). It carries amendments §6's sentence.

### 2.2 Method classes, and the words each may use

| Method class | What it is | Words allowed |
|---|---|---|
| Exhaustive over a finite domain | A decision kernel checked on every vector of its stated domain, against blind properties and a blind reference kernel | "checked exhaustively over <domain>" |
| Bounded-exhaustive within a model | Every (site, fault kind) cell at depth 1, within FM-n and generator set G | "checked within FM-n over N cells" |
| Sampled | Depth-2 pairs, input generators beyond pairwise, config swarms | "sampled: N cases from seed s" |
| Differential | Equality to base, or to an analogue the engine derives, under the same inputs and faults | "equal to base over …" |
| Reference | Agreement with a separately written, obviously correct model on generated inputs | "agrees with reference R over …" |
| Review | A model's or a person's reading | advisory; never on a receipt as evidence |

**The word rule.** "Verified" and "proven" never appear on a receipt or in outside text. Kiro says of its own spec-derived property tests that "PBTs are not verification or proof" (https://kiro.dev/blog/general-availability/, via g5 §2). Anthropic's 2026-10-22 proof work says "'Formally verified' does not mean 'bug-free'" (https://www.anthropic.com/research/formal-verification, via g5 §3.1). Felix meets the same standard.

### 2.3 The fault model, FM-1

The kinds come from what an effect can actually do: what a command can return, what bash can fail to do, and what the environment can deny. This is LFI's rule (https://dslab.epfl.ch/research/lfi, via g3 §3.2), not a list of what reviewers imagined. The table merges d1 §5, d2 §3.4, d3 §4.1 and d5 §5.

| Id | Effect class | What happens at effect k | Made by | Real or simulated | Real-world origin |
|---|---|---|---|---|---|
| X1 | external command | nonzero status, nothing printed (1, 2, 128) | function tier returns without running | simulated | missing object, git fatal |
| X2 | external | nonzero after partial stdout | run, truncate, return nonzero | simulated | killed mid-write |
| X3 | upstream element of a pipe | status 0, stdout cut short | run, truncate, return 0 | simulated | pipe without `pipefail`, SIGPIPE |
| X4 | external | dies by signal (137, 143) | return 128+n, or kill the child | either | OOM, timeout |
| X5 | any fork: command, `$( )`, pipeline, subshell | bash cannot start it; single, or persistent from k | `ulimit -S -u` in the calling shell, as slice 0's `tests/lib/lane-probes.sh` does (on main since #480) | **real** | a process limit (fork failures seen in 16 of 352 runs under a real soft limit, g2 R2-F2) |
| X6 | external | does not return | virtual clock and deadline; only on surfaces that declare one | simulated | lock wait, prompt |
| X7 | external | status 0 with unexpected stderr | run, add stderr | simulated | warnings, localised messages |
| X8 | external | not found (127) or not executable (126) | shim returns it | simulated | PATH drift |
| K1 | Felix's own shell | the shell and its parent SIGKILLed at k | as the lane build's `_lf_fault kill` | **real** | crash, OOM |
| K2 | own shell | handled TERM, INT or HUP at k | layer signals its shell | **real** | ^C, logout |
| K3 | stdout | closed, or its reader gone after one line | `exec 1>&-`; an early-closing reader | **real** | a pager quits |
| R1 | redirection or open | ENOENT or EACCES | remove or `chmod 000` before k | **real** | TMPDIR cleaner |
| R2 | descriptors | EMFILE; `ulimit -n` swept from the inherited K to K+16 | runner | **real** | caller's limits |
| R3 | write | ENOSPC, `/dev/full`, `ulimit -f 0` | runner | **real** | full disk |
| B1 | builtin (`cd`, `pwd`, `read`) | fails, or its substitution subshell is killed | DEBUG-trap tier, or a function with the builtin's name | simulated | removed cwd |
| E1 | environment | TMPDIR, HOME or the memory root missing or unwritable | before the run, or before k | **real** | fresh or misconfigured host |
| S1 | state between reads | a commit, a ref move, a receipt rewrite or a table edit between effect k and k+1 | mutator at the boundary | **real** | another session landing |
| S2 | state | an object or file the run read is gone | remove it in the fixture copy | **real** | gc, partial clone |
| S3 | state | a worktree added or removed concurrently | mutator | **real** | parallel qualify rows (gate-time note, B3) |
| T1 | clock | jumps between two reads | virtual clock | simulated | NTP, a slow run |

**Inputs are a separate axis**, built by generators, not faults:
- **I1, byte classes in every name-shaped field.** LF, trailing LF, CR, tab, 0x01-0x1f, 0x7f, high bytes, invalid UTF-8, a leading dash, glob characters, space, empty, long, numeric-looking (`1` and `01`), and the surface's own sentinel words.
- **I2, records.** Every byte 0x00-0xff inserted into record-structured fields.
- **I3, decoys.** Names in other namespaces spelled like the one read.
- **L, layouts.** Partial, blobless and shallow clones; an old-git arm; mode 000; worktrees; detached HEAD; no origin.
- **V, environment and config, probed from git itself.** d4 ran `git rev-parse --local-env-vars` and got 15 variables, GIT_GRAFT_FILE among them, and `git help --config`, which printed 1,012 lines on git 2.56.0 (d4 §2). R2B-F3 escaped a hand-written list.
- **P, platform arms.** macOS bash 3.2 with BWK awk; Linux bash 5 with gawk.

**Bounds, printed in every receipt.**
- Depth 1 is exhaustive over (reached site × applicable kind). Each kind runs at its site's first occurrence, its last, and persistently from the first. The single and persistent variants follow SQLite, which runs each fault test once set to fail only once and again set to fail continuously after the first failure (https://www.sqlite.org/testing.html, via g3 §3.1).
- Depth 2 is sampled swarm-style, at a budget set by the budget class, with the seed recorded (Groce et al., https://www.cefns.nau.edu/~adg326/issta12.pdf, via g3 §5).
- Interleavings (S1) run at every effect boundary of a surface that claims a snapshot.
- For declared concurrent actors (the lander and a session; parallel qualify rows), a seeded turnstile runs with at most 2 preemptions. This comes later (§10).

These bounds rest on empirical small-scope results, not guarantees:
- most of the 198 user-reported failures studied (90%) needed three or fewer input events, and almost all (98%) needed three or fewer nodes (Yuan et al., https://usenix.org/conference/osdi14/technical-sessions/presentation/yuan);
- most file-system crash bugs need three or fewer operations (https://arxiv.org/abs/1810.02904);
- most interaction faults are 1-2 way (https://csrc.nist.gov/files/pubs/shared/itlb/itlbul2016-05.pdf);
- the nine previously unknown bugs that iterative context bounding found in its benchmarks were each exposed with at most 2 preempting context switches (Musuvathi and Qadeer, PLDI 2007, https://www.microsoft.com/en-us/research/publication/iterative-context-bounding-for-systematic-testing-of-multithreaded-programs/), and CHESS's authors report reproducing very serious bugs with just two preemptions (CHESS, OSDI 2008, https://static.usenix.org/events/osdi08/tech/full_papers/musuvathi/musuvathi_html/index.html).

All four come via g3 §5.

**Out of model, printed in every receipt:**
- a trusted tool that lies with status 0;
- faults inside git, awk or the kernel;
- power loss and fsync ordering;
- orderings inside one effect;
- depth 3 and beyond;
- unmediated effects (§4.3);
- the real network (`gh` answers from a fixture model whose fidelity is a stated limit);
- an adversarial same-user process.

**How the model grows.**
- A fault kind enters by witness: it must produce a violation, or kill a mutant, that no existing kind does (d4 §5).
- Every kind names a real-world origin, or it runs in shadow, reported but never blocking (d2 §3.4).
- A version bump stales every receipt checked against the older version (d4 §5; it applies v3.2 invariant 3, which requires every receipt to carry its invalidation semantics).
- Every lesson that names a fault becomes a row with its source. Today lessons are injected into prompts and never run (g1 gap 2).

**A contamination note.** The table above was written by people who had read the slice-0 findings. d2's version of it named findings in its origin column (R2-F2, R3-F1, F8 and others), and X5's row here still does. So do the oracle kernel's examples and the lint list in §4.5 (O4's `GIT_OPTIONAL_LOCKS=0` is V3R2-F5, O9's `1` and `01` is R2B-F4, O3's empty TMPDIR is F7, O1's lost row is R2-F2 and R2-F7, O2's cause map is P8, O11's unused globals is F10). So **the replay in §9 uses none of them.** It uses a fault model, catalogues, oracle rules and lints frozen from primary sources without the findings (§9.1), and the two are compared.

### 2.4 What a receipt never says

It never says that the claim set is complete; that the clean answer is right beyond what a reference or a base differential checks; or that a mutation score is a fault-detection rate. About 27% of real faults couple to no mutant of the commonly used operators, and about 17% to no mutant even with new or stronger operators (Just et al., https://homes.cs.washington.edu/~mernst/pubs/mutation-effectiveness-fse2014-abstract.html, via g4 §5). It never says that blindness held, and it never says the receipt is tamper-proof.

---

## 3. The frontier: what the best practitioners do and do not do

**Source quality.** Every world claim here comes from the research stages g3 to g6, or from d3, d4 and d5. Those stages mostly read abstracts, project pages and secondary summaries, and each says so in its section on what it did not verify. I re-read none of these sources.

### 3.1 What they do, and what Felix takes

| Practice | Who, with evidence | What Felix takes |
|---|---|---|
| **Deterministic simulation with replay** | FoundationDB simulates "an entire FoundationDB cluster within a single-threaded process" (https://apple.github.io/foundationdb/testing.html). TigerBeetle's VOPR runs real code under network, storage and process faults, and a 2026-08-20 post describes it checking each replica's internal state, such as checksum agreement on every commit (https://tigerbeetle.com/blog/2026-08-20-protocol-aware-dst). Dropbox's Trinity re-runs each test with the same seed and asserts that the same final state is reproduced (https://dropbox.tech/infrastructure/-testing-our-new-sync-engine). All via g3 §2. | The determinism envelope: virtual clock, deterministic `mktemp`, seeded `RANDOM`, a `gh` fixture model. Every failing cell becomes one replay line. |
| **Fail the Nth effect, systematically** | SQLite fails the Nth allocation or I/O, then N+1, until a run completes, in single and persistent variants. It has 590 times as much test code as library code (https://www.sqlite.org/testing.html). Linux has `fail-nth`, and strace has `--inject ... when=N` (https://man7.org/linux/man-pages/man1/strace.1.html). | Depth-1 exhaustive cells per (site, kind), single and persistent. On Linux CI for users, the syscall form. |
| **Give each failure an identity** | FATE/DESTINI explored more than 40,000 failure scenarios and found 16 new bugs (https://usenix.org/conference/nsdi11/fate-and-destini-framework-cloud-recovery-testing, via g3 §3.4). | Site identity: (surface, `FUNCNAME` stack, command word, argv shape, occurrence). That is what turns "the read of the landings" into an enumerable row. |
| **Error handling is where catastrophic failures live** | 92% of catastrophic failures in five distributed systems came from mishandling non-fatal errors that the software explicitly signalled (Yuan et al., OSDI 2014, link above, via g3 §3.6). | The P1 property, in its bash form, is the first claim class. |
| **Bounded-exhaustive beats random** | CrashMonkey and ACE reproduced 24 of 26 known crash bugs with bounded workloads (https://arxiv.org/abs/1810.02904). ALICE found crash vulnerabilities in git-log and git-commit in 2014 (https://www.usenix.org/node/186195). Both via g3 §4. | Small, stated bounds. Crash consistency, old-or-new, for Felix's own state writes. |
| **Generic oracles, written once** | Antithesis "always" and "sometimes" assertions: a "sometimes" fails by default, so a probe that never fired is a failure (https://antithesis.com/docs/properties_assertions/assertions/, via g3 §2.4). | O5 fired: a cell that did not fire is "not exercised", never "passed". |
| **Reference models as the spec** | ShardStore: executable reference models at about 1% of implementation size, 16 bugs that, in Amazon's words, would have needed "time-consuming and labor-intensive testing to find otherwise", "if they could have been found at all", specs adding about 14% to the code (https://www.amazon.science/blog/aws-team-wins-best-paper-award-for-work-on-automated-reasoning). Cedar ships a release only if "its model, proofs, and differential tests are up to date" (https://aws.amazon.com/blogs/opensource/lean-into-verified-software-development; method in https://arxiv.org/pdf/2407.01688). Both via g5 §4.1. | A blind reference model for every pure-function feature. A blind reference kernel for every decision kernel. A release condition that the evidence is current. |
| **Differential and metamorphic testing** | Csmith found 325+ compiler bugs (https://www-old.cs.utah.edu/~regehr/papers/pldi11-preprint.pdf). PatchDiff found 29.6% of plausible SWE-bench Verified patches behaviourally distinguishable from the developer's (https://arxiv.org/abs/2503.15223). Both via g4 §4. | Base equivalence by default, under faults. Metamorphic invariance over git's own environment and config lists. |
| **Mutation at diff time** | Google mutates only changed lines, a median of 7 mutants per change. Of the mutants developers gave feedback on (about 67k of 2.1M surfaced), 82% were rated productive across the whole dataset, and suppression rules raised the rate over time from 80% at the service's launch to 89% (https://ar5iv.labs.arxiv.org/html/2102.11378). Meta's ACH aims model-written mutants at a concern (https://arxiv.org/html/2501.12862v1). Meta's diff-time catching tests: of 22,126 generated tests, 41 candidate catches went to engineers and 8 were confirmed true positives (https://arxiv.org/abs/2601.22832). All via g4 §5, §7. | Diff-scoped mutation with arid rules. Targeted mutants as control 5 applied to tests. Mutation measures the evidence, and finding is left to the sweep. |
| **A small trusted kernel; models outside it** | de Moura: "for any fixed testing strategy, a sufficiently adversarial system can overfit to it" (https://leodemoura.github.io/blog/2026-2-28-when-ai-writes-the-worlds-software-who-verifies-it/). Kleppmann: the challenge "will move to correctly defining the specification" (https://martin.kleppmann.com/2025/12/08/ai-formal-verification.html). Both via g5 §3.1. | The oracle kernel and decision kernels stay small, qualified and pinned. The fight moves to the spec, so the spec gets a widening check and commit-reveal. |
| **The consumer checks cheaply what the producer searched expensively** | Proof-carrying code (Necula, POPL 1997, https://dl.acm.org/doi/10.1145/263699.263712; cited by d3, not fetched) | Merge-time spot replay of k cells per claim. |
| **Narrow, scoped attestations** | SLSA VSA: the result is "Either "PASSED" or "FAILED" to indicate if the artifact passed or failed the policy verification", and "A VSA does not protect against compromise of the verifier" (https://slsa.dev/spec/v1.1/verification_summary). Assurance 2.0 records defeaters and residual doubt (https://arxiv.org/abs/2205.04522). Both via g5 §6-7. | Receipts name policy, judge, scope, method class and residual. Qualification results attach as defeaters that were tried. |

### 3.2 What they do not do

- **Model review is not accurate enough to release on its own.** The leading review tools score about 51-65% F1 on Martian's Code Review Bench, by the vendors' own posts and press snapshots (CodeRabbit 51.2%, Greptile 60.8%, Cubic 64.9% per The New Stack) (https://www.coderabbit.ai/blog/coderabbit-tops-martian-code-review-benchmark, https://www.greptile.com/content-library/greptile-martian-code-review-benchmark, via g5 §8). Under v3.2 that is a discovery worker. Felix has one comparison of its own (08-18, n=1, a hypothesis not promoted to lessons). 41 adversarial agents spent 4.3M tokens and filed 37 findings, and 35 died under refutation. One survived, and it was a blocker. One blind agent spent 160k tokens and produced a better design and five findings, three of them confirmed. The comparison shows that model review's findings are mostly noise until refuted. It does not measure whether a review pass that finds nothing is fit to release (g1 §3; memory note blind-derivation-beats-adversarial-review.md).
- **They do not run debate until consensus, or self-refine without outside feedback.**
  - Debate "often fail[s] to outperform simple single-agent baselines" (https://arxiv.org/abs/2502.08788).
  - Models switch from right to wrong answers after seeing their peers' reasoning (https://arxiv.org/abs/2509.05396).
  - Without external feedback, models struggle to self-correct and sometimes get worse (https://arxiv.org/abs/2310.01798; https://arxiv.org/abs/2406.01297).

  All via g6 §2.2.
- **They do not count on independence between versions.**
  - In Knight and Leveson's study, coincident failures were far more common than independence predicts (https://www.kth.se/social/files/564df871f2765419e306178d/KnightLeveson.pdf).
  - On one leaderboard dataset, when two models both erred, they agreed on the same wrong answer 60% of the time (https://arxiv.org/abs/2506.07962).

  Both via g4 §4.2.
- **They do not trust coverage.** Once suite size is controlled for, coverage correlates only weakly to moderately with effectiveness (https://cs.ubc.ca/~rtholmes/papers/icse_2014_inozemtseva.pdf, via g4 §8).
- **They do not let the code be its own oracle.**
  - Generated oracles capture actual behaviour, not intended behaviour (https://arxiv.org/abs/2410.21136).
  - ACH states this limit of its own design.
- **They do not let the author touch the judge.** ImpossibleBench: frontier models "pass" contradictory tests by editing them (https://arxiv.org/abs/2510.20270, via g4 §7).
- **They do not call chaos engineering verification.** It shows resilience to the faults tried, not the absence of mishandled ones (g3 §8).
- **They do not use models to write formal specs unaided.** Models reached 8.6% semantic correctness on TLA+ (https://ai4fm.cs.luc.edu/papers/gsirs-2026-tla-llm/, via g5 §3.1).

### 3.3 Where Felix would go past what is documented

g5 §8 found four gaps, from documentation only. That is absence of documentation, not proof of absence. Three of them are below. The fourth is that only AI-SDLC separates the checker's author from the code's author by policy; proof vendors separate them by construction, and g5 counts Felix's pinned judge (amendments §2.3) as the same move for ordinary checks.
1. No vendor publishes, per repository, evidence that its checker discriminates the property it judges.
2. Nobody keeps a standing ledger in which an undecided claim holds release and receipts go stale when an input moves.
3. Nobody composes evidence of different strengths into one release decision, with each piece's scope and method stated.

Of the vendors g5 read, Antithesis does the most fault search: its FAQ suggests about 30-60 min on commits to main and 6-8 h nightly runs (https://antithesis.com/docs/faq/customer_faq/, via g5 §4.2). It documents no revision-bound receipt that goes stale. The design below is aimed at all three gaps at once, for every change an agent makes, with nobody present.

---

## 4. The design

### 4.1 Spine and grafts

The spine is **d3, the evidence-carrying change**, for its fit to v3.2's objects (admission pathways, the obligation ledger, the Evidence Kernel), its product, and its governance of evidence. The judges' verdicts (not filed, see the top) split two to one for it, with the third choosing d1 for its oracle discipline. That discipline is grafted whole.

| From | What is taken | Why |
|---|---|---|
| d3 | The case; the claim-class catalogue with mandatory instantiation; the default case for small changes; per-claim receipts; R-base; narrowing polarity; commit-reveal; the positive control; spot replay at merge; standing claims | The spine |
| d1 | The information order derived from a typed output schema (⊑) as the reader oracle; output-class coverage; the compiler's refusal of uncovered byte classes; pairwise covering arrays; the plan hash; census residuals in three kinds; a lint against new unmediated effects; its replay protocol. Its placement of each fault cell on the first layout that reaches the site is **replaced** by a discriminating-layout rule (§4.3 item 7), because on the simplest layout the clean value is often the very default a defect produces | ⊑ is finer than d3's "clean or an UNKNOWN form". It is `cls_lane_tsv`'s actual rule lifted into the schema. The byte-class refusal is the rule that would have stopped the trailing-LF miss. |
| d2 | The safety order for deciders (PASS may move to HOLD, never HOLD to PASS; a fail-open only where main already has it as a recorded design); the determinism envelope; a real-world origin for every fault kind; crash consistency at every write; the seeded turnstile; one `BASH_ENV` preload, with the bash 3.2 tracer built here and offered to plan A | The trust plane's real property, stated so it covers `felix merge`, the Stop hook and the receipt readers |
| d4 | The "indistinguishable" mutant class, never counted as equivalent and capped; operator coupling measured by reverting Felix's own fixes; domains probed from git; the mutation runner (reach-selected, cheapest first, stop at the first kill, subsumption); the bounded check language for finders, as a measured arm only | Discrimination evidence that measures itself, and a gap detector for weak generators |
| d5 | Decision kernels for the trust core (d5 wrote them three-valued; here each read has amendments §4's four states plus ⊥), checked exhaustively against blind properties and a blind reference kernel; the refinement oracle `bash == kernel(abstract(I, σ))`; one observation primitive with a census and a lint; the mechanical widening check; P2 (sweep main's core) and P3 (a prospective test on slice 1) | The strongest assurance on the code the trust plane is sold on, and the largest lever on cost at 10x |

**Rejected outright, for unsoundness.**
- d4's pruning of value faults by output lineage. A fault can matter through its status even where its output never reaches the answer, and it can end the shell.
- d2's per-cell reuse keyed only on the files on the faulted stack. A file sourced at start-up can set a global or an option off the stack. §4.8 gives the sound form that replaces it.
- d1's reach rule, "every cell whose site's stack contains a function the diff changed" (d1 §7 item 4). It has the same flaw: a changed function that ran earlier and set state is not on a later site's stack. §4.8 replaces it.
- d3's B3 rule that a surviving mutant passes if it is "listed as claimed-equivalent". That is a model claim unblocking release, which v3.2 invariant 1 forbids. The same objection removes every other way a model's text could make a cell pass without a mechanical witness (§4.4, §4.8): a declared fail-open, an "impossible" byte class, a non-additive delta, a collapse between values, a declared residual, a narrowing cleared by the lead's own record, and an analogue the lead picks.

### 4.2 Architecture

```text
 WRITTEN ONCE, VERSIONED, PINNED FROM MAIN            PER CHANGE (in the change's tree)
 templates/claim-classes.tsv  faults.tsv              case/<id>/: surfaces, schema, outcomes,
 bytes.tsv  env (probed)  layouts.tsv                 claims, reference model, examples,
 operators.tsv  oracle kernel (bash/awk)              generators, held-fixture and salt hashes,
 decision kernels + reference kernels (core)          declared residual
            |                                                    |
            |   blind case author(s) propose  ---> lint against the default case
            |                                      (relaxations = narrowings), instantiate, FREEZE
            |                                                    |
 code@head, code@base  ---> CENSUS (static where-read.sh + dynamic trace) ---> PLANNER
                                                                    | covering array, cells on
                                                                    | discriminating layouts, budget
                                                                    | class, reach scope, plan hash
                                                                    v
              RUNNER (Mac-wide slots; cloned fixtures; timeout + heartbeat; fork-server later)
              EFFECT LAYER via one BASH_ENV preload: tier 1 functions, tier 2 PATH shims,
              tier 3 extdebug DEBUG trap (after the spike); determinism envelope
                                                                    |
              ORACLE KERNEL (O1-O11) per cell -> clusters by (claim, site class, kind, function),
              each with a shrunk replay line
                                                                    |
              DISCRIMINATION: positive control; diff mutants + targeted mutants; survivor classes;
              coupling measured on Felix's own fault corpus
                                                                    |
              EVIDENCE KERNEL: per-claim receipts (stored by tree and plan hash), computed residual,
              staleness, spot-replay answers, the builder's challenge and alternate-evidence rows
                                                                    |
   felix gate: `case` check (reads receipts by tree; reused when fingerprints hold, and says so)
   CI: full suite (row 30) + a sample of cells on Linux, seeded from the CI run id
   felix merge: `case` blocker (report-only -> shadow -> armed by the founder): READY / HOLD / ESCALATE
   main: standing claims; nightly full sweep; escapes classified -> new rows
```

### 4.3 Components

Each component says whether a model proposes or a mechanism decides.

1. **The claim-class catalogue** (`templates/claim-classes.tsv`). Each class has:
   - a quantifier, over effects, environment, config, inputs, layouts, base or trace;
   - the oracles that judge it;
   - the surface kinds it is mandatory for;
   - a budget floor.

   The first classes, from g2's eight properties:

   | Class | Property |
   |---|---|
   | FAILCLOSED | P1 |
   | ENVINVARIANT | P2 |
   | BYTESAFE | P3 |
   | BASEEQUIV | P4 |
   | WRITESET and OFFLINE | P5 |
   | EXACTREF | P6 |
   | SNAPSHOT | P7 |
   | CAUSE | P8 |

   *Felix writes the classes once. A new class enters as a candidate and binds only by witness.*
2. **The fault model and catalogues** (§2.3): `faults.tsv`, `effects.tsv` (which command word is which effect class), `bytes.tsv`, `layouts.tsv` and `operators.tsv`, plus environment and config lists probed from git. *Written once. Grown only by witness. Additions to `effects.tsv`, and "impossible" entries in `bytes.tsv`, escape (§10).*
3. **The case** (§4.4). *Blind authors propose it. A linter decides that it is well formed and compares it with the default case the engine builds from the mandatory classes; every relaxation counts as a narrowing (§4.8). The instantiator adds every mandatory class at its budget, so FAILCLOSED cannot be left off a hook.*
4. **The effect layer** (g3 §9.1, d2 §3.1). One `BASH_ENV` preload. **The bash 3.2 tracer is this design's own deliverable.** Plan A's design builds the Linux tracer first, and the bash 3.2 one "only if a traced full run fits one night of idle slots" (`docs/2026-10-24-reach-checks-design.md:244`), so there may be no Mac tracer to share. This design builds it, step 0a checks it, and plan A may consume it. It has three tiers:
   - **Tier 1, exported functions.** One per command word, plus `pwd` and `cd`. A function sees `FUNCNAME`, `BASH_SOURCE` and argv, and can act on the real calling shell.
   - **Tier 2, PATH shims.** For children that are not bash, `env`, `xargs` and awk `system()`.
   - **Tier 3, an `extdebug` DEBUG trap.** For builtins, redirections, and the record of which functions were entered. The bash 3.2 man page on this Mac says that with `extdebug`, if the trap's command "returns a non-zero value, the next command is skipped and not executed", and that command substitutions, functions and subshells inherit the DEBUG and RETURN traps (man page lines 4344-4362). It does not say what status a skipped command leaves. If a skipped `x="$(pwd)"` leaves status 0 and an empty value, that fault does not happen in reality, and correctly guarded code would look fail-open. So step 0a measures that status, and tries instead a trap that ends the substitution's subshell with a nonzero status. No stage has run any of this.

   Every effect gets a site identity and a trace line, written to an open descriptor with builtins only. **Transparency check:** in pass-through mode, every surface must equal a run with the determinism envelope on and the layer passing through, byte for byte, and must equal a run with neither once the schema's declared volatile fields (a time, an age, a pid, a temp path) are normalised. Where it does not, that surface's verdicts read UNKNOWN. On main, the only clock override I found is `FELIX_COST_NOW` in `lib/cost.sh` (grep over `felix`, `lib` and `hooks`); the lane adds `FELIX_LANE_NOW` (plan at `8c5b8725`). So the status rows, the pulse, session start and `felix merge` have no clock override, and the envelope supplies one through the layer's `date`. **Unmediated effects** are census rows printed in the residual: absolute paths (g3 §1 counted 13 `/bin/bash`, 9 `/usr/bin/env`, 3 `/bin/sh`, 1 `/usr/bin/tail` and 1 `/usr/bin/time` on main), `exec`, `builtin X`, `env -i`, `BASH_ENV` cleared (`lib/qualify-run.sh:408,413`, `lib/commission.sh:352,399`, per d2 §1.3) and git's helper processes. A lint refuses new unmediated effects in a change. *Mechanism.*
5. **The determinism envelope** (d2 §3.2): a virtual clock, deterministic `mktemp` under the cell's TMPDIR, seeded `RANDOM`, fixed locale, and a `gh` fixture model whose fidelity is a stated limit. A cell whose rerun differs is reported as **nondeterministic**. That is a finding against the envelope, never a flaky pass. *Mechanism.*
6. **The census** (d1 §7). Two parts:
   - static: the command sites in every function reachable from each surface, from `lib/where-read.sh`'s reader, which needs a whole-file mode;
   - dynamic: the trace of every clean run.

   The difference is printed in three kinds: sites never reached (a generator gap), sites reached but not mediated (a layer gap), and effects that no claim or reason accounts for (a spec gap). The spec gaps go to the case author. *Mechanism.*
7. **The planner** (after d1 §7, with its layout rule replaced):
   - a pairwise covering array over the generators' dimensions;
   - every catalogue byte class on every byte field;
   - **fault cells on discriminating layouts.** O1 compares a faulted output only with the clean output of the same layout. On the simplest layout that reaches a read, the clean value is often the default a defect produces: every lane idle `0 of 0` (R2-F1), an empty next text (R2-F5), a `-` date (R2-F6), no landings or no lane (F1). The faulted run then equals the clean run, the fault fired, and a broken read passes. So each site gets at least one layout on which the clean values of the fields that depend on it differ from every default and every UNKNOWN form. A layout qualifies by a **default probe**, one run per (site, layout) that makes the site's effect succeed with empty output: if that run's output equals the clean output, the layout cannot tell a read that fell back to its default, and the planner picks another. On top of that, a pairwise (site × layout class) array covers the resolution, tie and nesting dimensions, because some defects need a particular layout as well as the fault: V3R1-F2 needs two projects whose `remote_match` values nest, V3R2-F2 needs a miss that stands (a `.felix` marker that names no project, or a tie between two `remote_match` values) with the fault falling in the third resolution, resolve_or_die's call to `felix_binding_broken`, F6 needs a commit whose object can go missing. A cell on a layout that failed its default probe reads "not discriminating", never "passed". Cells therefore grow with sites × discriminating layouts (§5.2 uses 1.5 per site, unmeasured);
   - depth set by the budget class, and the change's reach;
   - a plan hash covering every input.

   It refuses, and the result reads UNKNOWN and never a pass, when:
   - a case part is missing;
   - a required byte class is neither covered nor witnessed impossible (§4.4);
   - a site has no discriminating layout;
   - an effect class has no reason;
   - the plan is over budget;
   - the census did not finish. *Mechanism.*
8. **The runner.** It takes slots from the Mac-wide pool (row 30; `parallel-builders-oversubscribe-the-mac.md` caps part runs at 4) and builds fixtures from clones. `cp -c` cloning is unmeasured (d2 §3.6). Every cell has a timeout and the run has a heartbeat (row 32). Failures are shrunk, and each prints one replay line. A fork-server, which loads the engine once and forks per cell as AFL's does (d3 §12.3), is a measured later lever, not an assumption. *Mechanism.*
9. **The oracle kernel** (§4.5). About a dozen functions in bash and awk, written once and pinned from main. It qualifies like any checker:
   - the seven controls run on planted surfaces, which an author blind to the oracle kernel writes (§4.8);
   - the transparency check;
   - self-application: from its second version on, the kernel's own surfaces are swept by the base kernel. The first pinned version has no base kernel to sweep it. It qualifies on the blind planted surfaces, on the replay harness's planted-defect controls (§10 step 0b-i), and under the capped review, and its receipts say so. *Mechanism.*
10. **Discrimination** (§4.6). *Operators and the runner decide. A model only proposes targeted mutants.*
11. **The trust core** (§4.7): decision kernels, the observation primitive, and the widening check. *Mechanism. Blind authors propose properties and reference kernels.*
12. **The Evidence Kernel.** It writes per-claim receipts, computes the residual against the catalogue, marks receipts stale, and answers spot replays. It also evaluates two of the builder's five v3.2 §6 channels as rows: a **challenge of applicability** (it re-runs the census and grounded probes; grounded false makes the claim dormant, grounded true keeps it, and unknown holds) and **alternate evidence** (it judges whether the proposed evidence meets the same claim's method class and discrimination bar). Neither channel edits the case. In v3.2 §1's words, it "cannot invent obligations or widen authority". **Receipts live in the memory root, keyed by tree id and plan hash** (for example `<home>/state/case/<tree>/<plan-hash>/`), and every reader looks them up by tree, never by checkout. The gate receipt is keyed by the checkout's path (`_felix_receipt_path`, `lib/verify.sh:481-483`), which is why a scratch clone's gate receipt is invisible to `felix merge` (direction row 24); case receipts must not repeat that. *Mechanism.*
13. **The case evaluator and blocker.** `felix case`, a `case` gate check, and a `case` entry in `felix_merge_blockers`. Report-only, then shadow, then armed by the founder. *Mechanism.*
14. **Standing claims and the learning loop.** After landing, a change's claims stand on main, keyed on the function-level fingerprint of §4.8, which needs the tracer. They go stale when that fingerprint moves. **What a stale claim does to the PR that staled it is decided here:**
    - A standing claim at **B3 or above** is re-earned inside the evidence run of the PR that moves its fingerprint, and that PR holds until it is. B3 is where a hook, the gate, merge, receipts, obligations, qualify or escape reach, which is where a broken claim costs most.
    - A standing claim **below B3** is re-earned by the nightly sweep. Until then its receipt reads "stale, not re-earned". That is CI-on-main strength, weaker than the rest of this design, and the receipt says so.
    - The nightly is budgeted from the measured total of standing cells. When the night runs out, the rest stay "stale, not re-earned", oldest first next night.
    - **Cost.** A PR that changes a function every surface enters, such as `felix_resolve_project`, stales every B3 standing claim. After ten slice-0-sized features that is on the order of 100,000 runs, about 7 h at 4 slots on §5.2's central t. That is the price of a PR not being able to break another feature's B3 claims unseen.
    - **Until the tracer works,** standing claims are not kept per PR at all. Any edit to a sourced file stales all of them, and only the nightly re-earns them.

    Every escape is classified as a design, checking or implementation escape (g6 §3.2 S9) and becomes a row. *Mechanism. A model may classify, and the classification is recorded.*

### 4.4 What the spec must contain: the case

The lead's spec stays prose plus contracts. A blind author who has not seen any implementation derives the case from it. That much is checkable, because the case is committed before the first implementation commit.

| Part | Required | Content | Slice-0 example |
|---|---|---|---|
| Surfaces | yes | Entry argv, cwd and environment; kind (`new`, `altered`, `must-match`); write set; offline; budget class. The **analogue is not authored**: the engine derives it as the base surface whose trace reaches the same shared function at the same site (§4.8) | `felix-lane` new; `status-row` altered; `felix-merge` must-match; `felix-lane` and `status-row` write `-` (scratch under `${TMPDIR:-/tmp}` aside); `felix-merge`, the pulse and session start declare the writes they make on main today. The derived analogue for the lane's resolution sites would be `felix which` |
| Output schema | yes | Format; records and keys; each field's type (`exact`, `enum`, `int`, `date`, `sha`, `ident`, `bytes`); its unknown tokens; coupling rules; collapses, which may only map fields to `-` or an UNKNOWN token, never one value to another; volatile fields (time, age, pid, temp path) | `lane13`, the 13 columns of plan C5. Column 2 is `enum ok,short,zero,idle,unknown`. If column 2 is `unknown`, columns 3, 4 and 7 are `-` (d1 §4) |
| Outcomes | yes | VALUE forms. "Could not tell" forms, which carry no value: the linter checks that value fields are `-` or `unknown` and that the exit is outside success. For deciders, the safety order. A fail-open is allowed only where main already has it as a recorded design at the same function; a new one is a widening, held for a person | `E1`: stdout empty, exit 1, a stderr pattern. For `felix merge`: HOLD and REFUSE ⊑ PASS. The Stop hook's fail-open is main's recorded design (`engine/harness/hooks/stop:172-176`: "Everything else here allows and records") |
| Reasons and causes | when any field can be unknown | Each reason's pattern, and the effect classes that may cause it | R4 (table malformed) never under X5 at a scratch site; R10 for mktemp and TMPDIR |
| Delta against base | for surfaces that exist at base | What may differ from base; excluded code that must stay identical. An **additive** delta (head's output is base's output with records or fields inserted, checked by O8) is free; any delta that changes or removes base bytes is a narrowing | status rows 1-9 none (row 10 added: additive); excluded: `cmd_merge`, `cmd_land`, `felix_resolve_project`, `lib/table.sh` |
| Claims | instantiated + authored | Mandatory classes are instantiated by the engine. Authored claims are functional claims, relations and budget raises. How each enters v3.2's admission pathways is §4.8's table | relation: add a marked landing, then L+1 and T+1; agreement across surfaces |
| Reference model | for pure-function features | A short, obviously correct computation by another route, written blind | an awk count over `git rev-list --first-parent` plus `diff-tree` |
| Examples | 2-5 | **The only hand-written expected values**: canonical layouts with their full output | the plan's felix-home example |
| Generators | yes | Dimensions and values; byte fields and the classes they cover; held fixtures, stored as hashes only, in at least two sets (§4.6). A class may be left out only with a **mechanical witness cell** showing it cannot occur, for example git refusing the byte; without one the class runs | lanes 0/1/2/5; window 1/14; clone full/partial/shallow; NUL in a path, with a witness cell showing that no POSIX path and no bash string can hold it |
| Depth-2 salt | B3+ | At least two hashes, one revealed per evidence run (§4.6) | — |
| Declared residual | as needed | Stated limits, from a closed list of kinds. Each entry is a narrowing (§4.8) | "a project directory whose name ends in LF reads as a resolution that did not finish" (item 48) |

**Not allowed in a case:** an implementation prescription (v3.2 §4: `implementation_prescription: NONE`).

**The case is linted against the default case.** The engine builds a default case from the mandatory classes for every declared surface (the rules below, plus every byte class, every fault kind, byte-identity outside the surface's own new output, and no fail-open). The linter compares the authored case with it. Every relaxation the author declares (a non-additive delta, an "impossible" class without a witness, a collapse between values, a fail-open not inherited from main, a residual entry) counts as a narrowing from freeze zero, and §4.8's narrowing rule decides it. A model's text written before freeze therefore cannot remove a cell, or turn a failing cell into a passing one, any more than a builder's commit after it can (constitution invariant 2; v3.2 invariant 1).

**Small changes** (B0-B1) need no authored case. The engine builds a **default case** (d3 §3.7):
- under every fault cell, head is not worse than base, on the order VALUE-equal-to-clean, then UNKNOWN, then anything else;
- its writes stay within base's write set;
- it is offline if base was.

Every fix gets a regression check under faults for free.

### 4.5 The oracles, written once

| Id | Oracle | Holds when | g2 property |
|---|---|---|---|
| O1 | **Degradation / safety order** | *Readers:* out(cell) ⊑ out(clean) under the schema's information order. A faulted output may say `unknown` where the clean one gave a value, or drop to a declared "could not tell". It may never print a different value, lose a row while exiting 0, or invent one. Judged only on a discriminating layout (§4.3 item 7). *Deciders:* the outcome is the clean outcome or one at or below it in the declared safety order. PASS→HOLD is allowed and counted as a false block. HOLD→PASS never, except where main already fails open at the same function as a recorded design, and then that design's record must be left. | P1, deciders |
| O2 | Exit and cause | The exit is in the declared set for the output's class. It is never 0 for a "could not tell" form or for lost records. Every unknown names a reason the cause map allows for the faulted effect's class. | P1, P8 |
| O3 | Write set and residue | Files changed under the watched roots are a subset of the declared writes. TMPDIR is empty after a run that ended by itself. | P5 |
| O4 | Offline and trace | No transport ran. Every effect carries its declared attributes, for example `GIT_OPTIONAL_LOCKS=0` on every git call. | P5 |
| O5 | Fired, discriminating, and sometimes | A cell's fault actually acted, and its layout passed the default probe; otherwise it is "not exercised" or "not discriminating", never "passed". Across clean cells, every enum value of every field occurs at least once, which guards against a surface that always prints `unknown`. | coverage |
| O6 | Determinism | The same tree, seed and plan give byte-identical outcomes on a resample. | harness |
| O7 | Crash consistency | After K1 at a write effect, every state file holds its old or its new content, and the next clean run gives the reference. | writers |
| O8 | Base differential | A must-match surface is byte-identical to base, clean and under each fault. An altered surface is identical outside its declared delta. Static form: a changed function reachable from an excluded entry point. | P4 |
| O9 | Metamorphic | Invariance under each probed environment and config entry, each decoy and each rename; byte-class round trip; injectivity (`1` and `01` are two lanes); agreement across surfaces. | P2, P3, P6 |
| O10 | Reference and refinement | On clean cells, the output equals the blind reference model and the examples. For code behind a decision kernel, the bash output equals `kernel(abstract(I, σ))`. That form does not trust the clean run. | normal path |
| O11 | Lints | No new unmediated effect; no `local x=$(...)` masking a status (https://www.shellcheck.net/wiki/SC2155, via g4 §5); no pipe status read from the last element; no raw read in a core file (§4.7); new files under 500 lines, and no growth in a file already over 500 (on main that is 13 library files, among them `resolve.sh`, `escape.sh`, `verify.sh`, `commission.sh` and `detect.sh`, plus `felix` itself and the `stop` and `session-start` hooks); no unused globals. | hygiene |

**One limit, stated plainly.** Outside the kernelised core, O1 is relative to the clean run. If the clean run is wrong, the sweep certifies a consistent wrong answer. Only O8, O9, O10 and the examples judge the answer itself. So **the linter refuses a case for a new surface that has FAILCLOSED claims and no functional claim** (d3 §5).

### 4.6 Discrimination: evidence about the evidence

- **Positive control** on every sweep (d3 §6.4). The changed functions are run with every status check removed, and that run must fail. A sweep that cannot fail is not evidence (constitution invariant 5).
- **Mechanical mutation of the diff.** The operators are stored as data:
  - drop an `|| return`;
  - mask a status with `| cat` or `local x=$(…)`;
  - widen a status test;
  - swap the unknown branch for the empty one;
  - drop `LC_ALL=C` or an environment scrub;
  - shorten a full ref;
  - split a snapshot;
  - an off-by-one;
  - an empty function body.

  They come from d1 §6 and d4 §7.1. Arid lines (comments and message text) are not mutated. The operator catalogue is written by an author blind to the oracle kernel it will be measured against (§4.8).
- **Targeted mutants.** A mutant author writes them for each claim, keeping every syntactic marker of the protection. One example: "make a killed count look like no lane, leaving every `|| return` in place". The author sees the code and the claim, never the evidence. This is amendments control 5 turned on the tests. Survivors go to the case author as evidence gaps, never to the builder, within the attack bound of §4.9 S7.
- **The runner** (d4 §7.4). A mutant runs only the cells whose trace executed its line, cheapest first, and stops at the first kill. Mutants killed by the same cells are clustered. On a fix, only changed lines are regenerated.
- **What a survivor costs.** A survivor is known only after every cell in its domain has run without a kill, so survivors, not kills, set mutation's cost. The domain is every cell whose trace executed the mutated line, which needs tier 3's line record; without tier 3 it is every cell whose trace entered the mutated function, which on a new feature is most of a surface's cells. One narrowing, sound only for commands whose nonzero status always means failure: for an operator that changes only the failure branch (drop an `|| return`, widen a status test), the original and the mutant run the same commands whenever the guarded command returns 0, so the domain is the cells in which that command returned nonzero, faulted or not, about K̄ × modes × layouts per site. Value operators (an off-by-one, a dropped `LC_ALL=C`, a shortened ref) get no such narrowing. §5.2 prices this.
- **Survivor classes,** decided mechanically:
  - *unreached*: no cell's trace ran the line, so a generator is owed;
  - *indistinguishable*: every run in the claim's domain gives byte-identical outcomes. It is **never counted as equivalent**. It is cleared only by a distinguishing input, and its share is capped. Above the cap the change holds and the domain is flagged weak. This is the class that surfaces the trailing-LF kind of generator hole mechanically;
  - *divergent-but-accepted*: outcomes differ and every oracle accepts them. The case is too loose there. Accepting the divergence is a narrowing, and it clears only under §4.8's rule (a mechanical witness or a person), never by the lead's record;
  - *survived*: everything else.

  A model's argument that a mutant is equivalent is printed and changes nothing.
- **Coupling measured on Felix's own faults** (d4 §7.5). Revert each of slice 0's fixes (46 findings, less those settled as stated limits, such as F9 and V3R1-F3) one at a time on `cff711ef`, and count which the evidence kills. Then count how many lie within one operator of a classic mutant. The receipt prints the operator catalogue's version with this measured coupling, which turns Just et al.'s Java figure into a Felix measurement.
- **Commit-reveal** (d3 §6.3). Held fixtures and the depth-2 salt are committed as hashes before the build and revealed at evidence time. An artifact committed in an ancestor of every implementation commit cannot have been fitted to that implementation. That makes one slice of amendments §2.2's "load-bearing and unverifiable" blindness checkable, against an overfitting agent but not a malicious process. Two rules keep it true across the fix loop:
  - **At least two held sets and two salts are committed at freeze.** One is revealed for the first evidence run, and a fresh one is revealed for the final run behind stop-rule condition 3. A revealed set's fixtures and sampled pairs are known after the first run, so a later run on that set is no longer held out.
  - **The builder sees held-fixture cells by class only:** claim, fault kind and function, never the replay line or the fixture. Cells on non-held fixtures keep their replay lines.

  The receipt says which run used a set the builder had not seen.
- **Bars by budget class.** These are initial values, to be calibrated by the replay.

  | Class | Error-path mutants on changed lines | Targeted mutants | Indistinguishable cap |
  |---|---|---|---|
  | B1 | ≥ 60% killed, survivors listed | — | — |
  | B2 | ≥ 90% | — | 10% |
  | B3 | 100% killed, or listed as indistinguishable | all killed | 5% |
  | B4 | as B3 | as B3 | as B3, plus human attestation for each indistinguishable one |

  A targeted mutant that still survives when the attack bound of §4.9 S7 is reached leaves its claim UNKNOWN, and the case ESCALATEs. It never loops a third time.

### 4.7 The trust core: decision kernels, one primitive, a widening check

This is d5, taken as the trust core's design, because §1.4 is the most consequential reading in the workflow. Its first piece in the engine is the narrow owed fix (§10 step 1). The kernel refactor below is step 1b, which the founder placed by decision 2: it starts once the audit's fixes to its files have landed.

- **The core, defined.** The core is the source closure of the merge judge (`_felix_kernel_blockers`, `felix:1722-1735`) and of the Stop hook, computed from the sourcing graph, not a hand list. By my hand trace it is about 10,100 lines (§1.4), against the "about 2,500 to 3,000" lines d5 estimated by file (the seven files §1.4 counts already hold 4,644). Every scope and cost below that depends on the core's size is re-estimated on the computed closure before step 1b starts.
- **Decision kernels.** Each core decision becomes a pure bash function with no forks and no I/O. Each read's domain is amendments §4's four computed states plus ⊥: **found** (a value), **empty**, **blind** (the read failed while a witness shows the surface exists), **not-applicable**, and **⊥** ("did not finish"). Every kernel carries the property that blind and ⊥ are never clean, and that empty is never read as clean without a positive check that the surface was read ("`unknown` blocks; empty is never clean", amendments lines 203-205). The candidates and their stated domains, as d5 §3.2 computed them from its own three-valued bounds (the four-state domain is larger, and is recomputed in step 1b-a):

  | Kernel | Decides | Domain |
  |---|---|---|
  | `resolve_decide` | project binding | about 16,400 vectors |
  | `table_decide` | table admission | a line classifier over about 22,000 strings |
  | `oblig_decide` | obligation state and blocking | 10,800 (6 × 6 × 5 × 5 × 3 × 2 × 2; d5 printed 21,600) |
  | `merge_decide` | merge composition: READY only if every producer is definite and empty | 3^9 = 19,683 |
  | `stricter` | base against head | the product of the verdict lattice |
  | — | deploy-owed | — |

  The default ⊥ rule is Kleene's: if the answer depends on a read that is ⊥, the answer is UNKNOWN(read). A per-read override may only be more conservative.
- **Checked exhaustively**, and only when something it depends on moves. Each kernel is checked over its whole domain against two things, both written blind and hidden from the builder: its properties, and a reference kernel. Every property is paired with at least one spec mutant that must violate it, and the spec mutants are written by an author blind to the properties (§4.8). **Cost.** For each vector the check runs the kernel, the reference kernel and every property: with d5's receipt example of 9 properties that is about 11 evaluations per vector. Four of the kernels have domains near 20,000: `resolve_decide` about 16,400, `table_decide` about 22,000, `oblig_decide` 10,800 and `merge_decide` 19,683. `stricter`'s lattice product is small. That is about 69,000 vectors in all, and × 11 about 0.76 million evaluations, or about 1.3-6.3 minutes at d5's guessed 0.1-0.5 ms per evaluation, before spec mutants (each stops at its first violation). At the upper end that alone overruns the founder's target of about 5 minutes from built to landable, a budget that also has to hold record, red and a parallel suite (`gate-time-measured-2026-10-10.md`, "DESIGNED 2026-10-12"; `docs/2026-10-12-gate-friction-design.md` lines 9-11). At the lower end it takes a quarter of that budget. So the result is **keyed on the hashes of the kernel, its properties, its reference and its spec mutants**, and the gate reruns a kernel's check only when one of them changes, which the widening check already detects; otherwise the gate reads the keyed result and says it reused it. Step 0a measures the per-evaluation time.
- **The observation shell** gathers observations through **one primitive**: `felix_capture` (`lib/detect.sh:202`), or a successor with file and redirection variants. On my reading of its body, it returns 2 when the captured command failed or its substitution did not come back whole, because the sentinel `\n.` is missing. It strips exactly one trailing LF, so a value whose own last byte is LF survives when the command prints its own newline. I did not run it.

  It cannot see a status-0 lie from a pipeline's upstream element (X3). So the lint requires every pipeline inside a primitive call to run under `pipefail`, or as a function that checks each element.

  The primitive is swept **once, as a class, under every fault kind**. A census shows that every concrete effect in core files is a primitive call. A lint forbids raw `$(`, pipelines and `< file` reads in kernel and shell files.

  P1 then becomes a property of one function, plus a coverage fact, plus a per-caller check that ⊥ reaches the kernel as ⊥.
- **The refinement oracle** O10 judges the shell. For every input I and fault cell σ, the bash output equals `kernel(abstract(I, σ))`. `abstract` comes from the abstraction map and the fault schedule, never from the bash run's own reads. That removes, for the core, the shared weakness of every clean-run oracle. **The abstraction map is a judge artifact, and so is its concretisation** (the map from an abstract vector to a fixture, which comparing a new kernel with main's behaviour needs). A wrong abstraction, for example one that maps a truncated read to found, makes O10 pass without checking anything. So both are written by an author blind to the kernel, land only through a trust-plane PR, qualify by planted wrong abstractions that O10 must catch, and fall under the widening check.
- **The mechanical widening check** (d5 §8). A change to a kernel, a reference kernel or a property file is compared with base over the whole finite domain.
  - **Widening** means an answer where base said UNKNOWN or refused, or a changed answer that is not a move to UNKNOWN. It is **held for a person**.
  - **Narrowing** (an answer moved to UNKNOWN or a refusal, never a removed check) lands on green only after roadmap step 15 pins the judge outside every change it judges. Until then a narrowing of the catalogue, kernels, reference kernels, properties or abstraction map waits for the founder's merge (decision 4).

  This is v3.2 invariant 2, applied to specs. It also catches the case de Moura's zlib example illustrates: the AI added a size precondition, which de Moura calls "a proof engineering artifact", choosing a bound "sufficient to close the proof". A precondition like that makes a property hold vacuously on inputs it used to judge, so under this check it is a widening, and a person sees it.
- **Scope.** Kernels are for Felix's own trust core, as defined above: about 10,100 of the engine's roughly 40,000 lines in `felix` and `lib` (`wc -l`: 6,673 and 33,346). Features use cases, not kernels. Users' repositories are offered kernels as an optional refactor, never as a requirement (§7).
- **Not adopted now:** TLA+ for the lander and the receipt store. Models write it poorly (8.6%, §3.2), and TLC brings a Java runtime into CI. The lander's protocol properties are instead checked in bash by three means:
  1. O7 crash consistency at every write;
  2. the turnstile over at most 2 preemptions (d2 §3.9);
  3. awk monitors over the real `ledger.tsv`, which is trace validation with no new runtime.

  A model checker returns only if a protocol defect escapes these three, and then only in CI and off the enforcing path.

### 4.8 Authority: who writes what, and what decides

| Artifact | Written by | May not |
|---|---|---|
| Code | the builder (model) | write or edit the case, generators, catalogues, oracles or kernels. A builder commit that edits the case is a narrowing |
| Case, reference model, examples, generators, held fixtures, salt | blind case author(s), before the build; where the host allows, from a family other than the builder's (Codex read-only, direction row 19). That is recorded in the lease and never read by a blocker | see code or results before the freeze |
| Targeted mutants | a blind mutant author | see the evidence configuration |
| Catalogue, fault model, oracle kernel, decision and reference kernels, properties, abstraction map and its concretisation | trust-plane PRs only, each artifact by an author blind to the artifact that will judge it or be judged by it | land in a PR that also changes the code under judgement |
| Planted qualification surfaces for the oracle kernel (the seven controls) | an author blind to the oracle kernel | see the oracle kernel |
| Mutation operators (`operators.tsv`) | an author blind to the oracle kernel and to any case they will be run against | see the oracle kernel |
| Spec mutants for kernel properties | an author blind to the properties | see the properties |
| Planted wrong abstractions for O10 | an author blind to the abstraction map | see the map |
| Verdicts, clusters, residual, survivor classes, analogues | the mechanism | — |

Each judge artifact's authorship is recorded the way a case's is (amendments §2.2: "The mutations must be authored by something that has not seen the checker"). A property author who also wrote its spec mutants would write ones its properties catch.

**Authoritative for landing:**
1. per-claim receipts from **main's installed harness**, for the exact tree;
2. the case verdict computed from them;
3. the narrowing check;
4. the existing gate receipt and blockers, unchanged;
5. CI's run on the exact head.

**How case claims enter v3.2's admission pathways** (v3.2 §4, lines 186-192):

| Claim | Pathway | What it may do |
|---|---|---|
| Instantiated from an admitted mandatory class (decision 7) | 1, deterministic policy | release-block where the class's rule permits |
| Instantiated from a class not yet admitted | — | report-only, in shadow |
| Any claim with a failing cell | 2, witness-backed | release-block for consequential failure classes (B3 and above); task-block below |
| An authored claim with no failing cell and no evidence | 4, single probabilistic discovery | advisory only; it may trigger further measurement, and it never reaches the `case` merge blocker |
| A mandatory claim with no evidence, or any claim whose evidence did not finish (⊥) | 5, critical unknown | an evidence-gathering hold; never a fabricated requirement, and never green. A claim left UNKNOWN by an unwitnessed narrowing at B0-B2 does not hold: it lands UNKNOWN (decision 5) |

**The judge pin.** The evidence run uses main's installed harness, catalogue, fault model and oracles, the same cache entry `felix merge` already pins (`felix:1855-1900`, g1 §1.2). A harness byte-identical to a candidate that changes it is refused, as `felix:1883-1886` refuses self-judgement. A change to the harness is judged by main's harness under its own case. It becomes the judge only after landing, after failing its positive controls and after killing seeded mutants. This is this checker's part of roadmap step 15. It does not end decision 4's hold, which lasts until step 15 pins the judge outside every change it judges. **A known limit:** the audit register's C063 (`docs/2026-10-24-audit-register.md:290-292`) describes a session swapping the cache entry's `lib/escape.sh` during the roughly one-second byte comparison, so the judge sources code main never accepted. Audit batch 13 (`lib/merge-judge.sh`; `docs/2026-10-24-audit-fixes/b13-felix-cli-trust-and-binding.md` Part A) closed it for a session's `felix merge`, which now hands the verdict to a copy of main's engine cut from git into a private TMPDIR directory. Two gaps remain. A felix that runs in place as the entry, as the land tick and a session running the cache's felix directly both do, still sources the entry's libraries after the comparison; b13 §6 leaves that race to roadmap step 15. And a same-user process can swap the copy between its check and its use (`lib/merge-judge.sh:29-30`). The pin inherits whichever of the two its path takes, and every receipt says so until step 15 closes it.

**Not authoritative:**
- review notes;
- a model's equivalence label;
- the builder's claims;
- a case author's report of blindness;
- the decision record's prose;
- `red.tsv`;
- any receipt from a harness other than the pinned one.

**Narrowing.** The case is read at four points: the default case the engine builds (§4.4), the freeze commit, base and head. The stricter reading is taken, as `risk.tsv` is read (amendments §5). So narrowing is counted from freeze zero: a relaxation the blind author declared before freeze is a narrowing exactly as a builder's edit after it is.
- **Free:** adding a claim, a fault row, a fixture, or an UNKNOWN outcome form (an added UNKNOWN form cannot let an answer pass); an additive delta; a collapse to `-` or an UNKNOWN token.
- **A narrowing:** removing any of those; adding a VALUE form under a fault; a fail-open not inherited from main; a byte class left out; a non-additive delta; a collapse between values; a residual entry; accepting a divergent mutant; widening a write set; lowering a raised budget.
- **A narrowing clears only by a mechanical witness**, at every budget class:
  - the census shows the cells it removes are unreachable;
  - a witness cell shows the input cannot occur (git refusing the byte);
  - the fail-open is main's recorded design at the same function;
  - R-base, below, on a surface where inheriting base's outcome is allowed.
- **Without a witness,** the claims it touches read UNKNOWN. At B3 and above the case ESCALATEs: the project's owner clears it (on Felix itself, the founder; decision 5), or it takes effect only in a new epoch, through a trust-plane PR that changes a landed catalogue or table and that escapes like any other addition to a deciding table (§10). At B0-B2 the case does not escalate on it: the change may land with those claims UNKNOWN in its receipt and its residual, and no one is asked to clear them (the founder's decision 5, 2026-10-31). By Felix's reading, the founder's choice makes this an exception, at B0-B2, to this design's use of amendments §4's "`unknown` blocks" (written there for probe states); the option did not name §4. Either way no such claim reads as checked. The lead's decision record is printed and clears nothing: it is the session granting itself an exception, which amendments §3 forbids ("Not reachable by the session") and v3.2 invariant 2 forbids within an epoch. Holding these for a person was a founder decision (§11.1, decision 5), answered for B3 and above only. By Felix's reading (the option names no start), that hold binds from 2026-10-31, by hand until the `case` evidence exists: a B3-and-above build's stated limit goes to the founder as a pull request opened as a draft labelled `needs-founder` (direction row 39).

**R-base, made mechanical.** The engine derives the **analogue**: the base surface whose trace reaches the same shared function at the same site. Nothing authored chooses it. Take a site in **unchanged shared code** whose outcome under a fault equals that analogue's outcome under the same fault (O8). It is classed R-base. It is not passed, and it is not silently accepted:
- it is filed with its failing cell as a witness-backed candidate obligation (v3.2 pathway 2), for the shared code's owner. The project owner's acceptance of the inheritance for that one shared function (on Felix, the founder's; decision 7) turns it into an obligation to fix, and later features on that function do not ask again;
- it is printed in every case whose reach includes it;
- **on a new surface at B3 or above, it holds the change (TASK_BLOCKING)** unless the project's owner (on Felix, the founder) has admitted that inheritance for that shared function (§11.1, decision 7). Below B3, or on an altered or must-match surface, it is a stated, filed limit. By Felix's reading (the option names no start), the hold binds from 2026-10-31, by hand until the `case` evidence exists: a new B3-and-above feature's inherited shared-code defect goes to the founder as a pull request opened as a draft labelled `needs-founder` (direction row 40).

The lead made this call by hand for V3R1-F3 ("main's `felix which` does the same", g2 §2). Here a differential decides it, and on a new B3 surface the project's owner (on Felix, the founder) decides whether a new surface may inherit it.

**Spot replay at merge** (d3 §9.7). `felix merge` replays two sets of cells. A mismatch in either makes the receipt INVALID.
- **Every cell that failed in any earlier evidence run of the change.** A forged receipt most likely rewrites a failure as a pass, so these are always replayed.
- **k cells per claim (k = 5 initially), drawn from a seed the producer cannot set before merge:** main's tip at merge time, and the CI run id of the exact head where C9 has one. A seed from the tree or the receipt could be ground, by rewriting the receipt until the drawn cells are ones that pass.

The receipt prints the detection probability instead of a word like "catches". At a few hundred cells per claim (§5.2's central run is about 24,600 cells over about 40 claims), five drawn cells find a single flipped cell with probability under 2%; they find a receipt with a tenth of its cells altered with probability about 41% (1 − 0.9⁵). Spot replay is a check against stale or broadly wrong receipts, not against one careful edit. It cannot stop a same-user process forging both receipt and tree.

**Reuse and reach.** One fingerprint decides both whether a cell keeps its verdict and whether a change reaches it.
- **The fingerprint**, which needs the tracer's function-entry record (tier 3):
  - the bodies of **every** function the run entered, not only those on the faulted stack;
  - for every command word the run executed, whether it resolved to a function, a builtin or a file, and which definition or path won;
  - the top-level statements of every file the process sourced, **other than plain function definitions**, with any compound statement that contains a definition counted whole;
  - the data files it read; the environment; the bash and git versions; FM, the catalogues and the case.
- **Why it is sound.** A function that never ran cannot act. A global is set either at top level (in the fingerprint), by a function that ran (in the fingerprint), or by the environment (in the fingerprint). A new definition matters only if something calls its name, and a call is recorded as a resolution, so a new definition that shadows a called name or an external command moves the fingerprint, and a function with a new name that nothing calls moves nothing. This avoids tracing variable reads, which bash 3.2 cannot do cheaply.
- **Reach** is every cell whose fingerprint the change moves.
- **Until step 0a shows that function entry and command resolution can be traced, there is no sound reach.** Every evidence run after a fix reruns every cell, and §5 prices it that way. d1's stack-keyed reach is not a fallback, for the reason given in §4.1.
- Collapse by equivalence, such as all git reads behind one wrapper, is allowed only as a labelled sample: "collapsed by sample, n of m run".

### 4.9 One change, from spec to landing

| # | Stage | A model proposes | A mechanism decides | Output |
|---|---|---|---|---|
| S0 | Budget class | — | From touched paths, the reach map and `risk.tsv`: B3 when reachable from a hook, the gate, merge, receipt, obligations, qualify or escape. **Before any traced reach map exists**, reachability comes from the static reader `lib/where-read.sh` (in a whole-file mode it does not yet have), plus a rule by path: any change under `hooks/`, or to a file in the core's source closure (§4.7), is B3. A model may raise it, never lower it | budget per surface |
| S1 | Spec | lead: contracts, surfaces (design deliberation, §8, runs here; its cheap tier at B0-B2) | lint: every changed entry point is a declared surface, re-checked by trace after the build. Analogues are derived by the engine, not named here | spec |
| S2 | Blind case | case author(s): schema, outcomes, functional claims, relations, reference model, examples, generators, two held sets, two salts. The mutant author works in parallel | instantiator adds every mandatory class at its budget | case |
| S3 | Lint and freeze | — | schema; UNKNOWN forms carry no value; commitments present; comparison with the default case, every relaxation listed as a narrowing with its witness or none; plan dry-run; the freeze commit computed | case hash, narrowing list |
| S4 | Build | builder: code only | a builder commit that edits the case is a narrowing | tree |
| S5 | Evidence run | — | pinned harness: census, plan, sweep, generators, base differential, reference, oracles; claims run red against base first (invariant 5) | per-claim results; clusters by (claim, site class, kind, function) with replay lines; census residual |
| S6 | Fix by class | builder, given whole clusters, never single cells (held-fixture cells by class only, §4.6); fixers in parallel on disjoint files; the builder may file challenge and alternate-evidence rows (§4.3 item 12) | re-run every cell in reach (every cell, until the tracer works), plus every cell that failed before, plus O8 in full | new results |
| S7 | Case attack, **at most two rounds** | one attack lens on the case (fault model, oracles, layer blind spots, missing claims) and one "simpler" lens. Felix's data has the simpler lens beating the attack lens twice (`blind-derivation-beats-adversarial-review.md`, via g1). Round 1 reads the frozen case while the build runs; round 2 reads run 1's census residual and clusters while fix 1 runs | a finding counts only when it bites: a new cell fails on head, or a mutant survives the current evidence. Otherwise it stays advisory (v3.2 pathway 4). Findings go back to the blind author as rows, never to the builder. **At the bound,** claims with attack rows not yet run read UNKNOWN, the case ESCALATEs, and the rows go to the nightly sweep. Rounds per feature are recorded as a measured number | case, catalogue or oracle rows |
| S8 | Settle | lead: contract questions, batched (a new reason code, a scope) | additions are free; narrowings follow §4.8 and clear only by a mechanical witness or, at B3 and above, the project's owner (on Felix, the founder) | decision record (printed; it clears nothing) |
| S9 | Discrimination | targeted mutants (from S2) | positive control; diff mutation; survivor classes; bars | kill rates on receipts |
| S10 | Stop | — | the stop rule (§4.10) | READY / HOLD / ESCALATE |
| S11 | Gate, CI, land | — | gate checks receipts by tree (reused, and announced, when fingerprints hold); CI runs the full suite plus a sample of cells seeded from its run id; `felix merge` runs the `case` blocker with spot replay | landed tree, standing claims |
| S12 | Learn | a model may classify an escape | the classification is recorded; rows are added only | `faults.tsv`, catalogue, generators |

Review rounds do not appear. The loop is bounded: S5 and S6 repeat until the stop rule holds or the plan's budget is spent, and S7 runs at most twice. Each S5-S6 iteration costs a fix by class plus an evidence run, which on a new feature is close to a full run (§5.3), so it is about an hour or more of machine time at central constants, not minutes.

### 4.10 The stop rule (v3.2 §10, per claim)

Checking stops when all six of these hold:
1. Every claim has VALID receipts from the pinned harness for the exact tree, for every method its budget requires.
2. Every evidence item met its discrimination bar, with survivors listed and the indistinguishable share under its cap.
3. The evidence ran after the last code change, on a held set the builder had not seen. No fix lands without a fresh sweep, and this is aimed at the 37% of findings that an earlier fix introduced (11) or left open (6).
4. Every bite from the case attack, within its bound of two rounds, has run: no claim, fault kind or oracle correction is still waiting for a run. Rows that arrive at the bound leave their claims UNKNOWN, and the case ESCALATEs; this condition never means "attack until a round finds nothing", which was the old loop's rule moved onto the case.
5. Every residual is of a class its budget allows: no unexercised or non-discriminating cell on changed code at B3.
6. Every narrowing has a mechanical witness or the project owner's clearance (§4.8; on Felix, the founder's) at B3 and above; at B0-B2 an unwitnessed narrowing instead leaves its claims UNKNOWN in the receipt and residual, which does not stop the case (decision 5).

A mandatory claim without evidence, or any claim whose evidence did not finish, is UNKNOWN and enters as v3.2's pathway 5, a critical unknown that holds, except a claim left UNKNOWN by an unwitnessed narrowing at B0-B2, which lands as UNKNOWN (§4.8, decision 5). An authored claim without evidence is advisory only (§4.8's table). Running out of budget never turns either green.

---

## 5. Latency

### 5.1 The cost model

```text
T = T_case + T_build + Σ_iterations [ T_run(cells × t / slots) + T_fix(clusters) ]
    + T_attack + T_settle + T_discrimination + T_gate + T_ci
cells ≈ Σ_surfaces S × K̄ × modes × L_d          (fault cells on discriminating layouts)
      + S × L_d default probes + base runs at shared sites + covering-array clean runs (head and base)
      + env/config/locale runs + byte-class runs + depth-2 budget
      + mutant runs: kills (stop at first) + Σ_survivors |domain|
```

Machine time grows with effect sites × discriminating layouts, and runs in parallel on at most 4 Mac-wide slots shared with the builders. Mutation's cost is set by survivors and the size of their domains, not by kills. Agent time grows with surfaces, clusters and contract questions, and never with sites, because no one names a site by hand. On a new feature nearly every cell is in the reach of every fix, so each fix iteration costs close to a full run. The old loop grew with rounds × about 2 h of serial agents and did not converge on its own; since 10-30 the cap bounds it at three rounds, at the price of coverage (`lane-slice-review-budget.md`).

### 5.2 The constants, and what is measured

| Constant | Value used: central (range) | Basis |
|---|---|---|
| t, one cell run | **1.0 s** (0.86-1.5 s) | **Measured, bare:** one `felix lane --tsv` run costs about 1.07 s CPU on real history and about 0.86 s with a one-day window, about 1.2 s wall (`g2/measure.txt`). The only timed loop that includes an oracle, `~/.felix/memory/felix/audits/2026-10-30-trust-plane-design/lane-build/review2-ulimit.c.log`, has 650 rows; a judge read about 9.3 min for it, about 0.86 s a row, with `review2-ulimit.sh` classifying each row with forking `awk`, `tr`, `wc` and `python` against one shared fixture. **No measured figure includes** the layer (a `BASH_ENV` preload in every bash child, a trace line per effect, tier 3), a per-cell fixture clone (`cp -c`, unmeasured), or the oracle kernel. 1.5 s is a guess that covers them. **Step 0b-i measures t with all three included, and no latency figure from this section is quoted before it does** |
| S, reached sites per surface | 150 (100-200) | Nobody counted it. d2 assumed about 120 reached sites per surface (d2 §"Slice 0, assumed inputs"). d1 put it at about 150-250: the lane libraries' rough static count plus the shared code on their stacks, with no separate figure for the libraries alone. **Not measured** |
| K̄, applicable kinds × variants per site | 7 (6-8) | d1, d2, d3 |
| Modes per kind | 2 (1.5-3) | §2.3 runs each kind at its first occurrence, its last, and persistently. A site that occurs once has two of those; d1 §10 used 2-3. The earlier 1.3 had no source |
| L_d, discriminating layouts per site | 1.5 (1.2-3) | §4.3 item 7: one discriminating layout for most sites, with pairwise extras at resolution, tie and nesting sites. **Not measured** |
| Slots | 4 | the Mac-wide cap after the load-351 incident (`parallel-builders-oversubscribe-the-mac.md`), **shared with the builders' own part runs**. Capacity under `-j` on the 48 GB Mac is not measured (`machine-change-48gb-rebaselines-gate-time.md`, via g1 §3) |

The five designs put slice 0's evidence run at 3,800 (d3), about 4,300 (d5; a judge, whose verdict is not filed, put it near 7,000), 12,700 (d2) and 25,000 (d1) runs, a six-fold spread from the same code with no measurement. The first version of this document said 13,600. Critics showed that figure used an unsourced 1.3 modes, ignored the discriminating layouts O1 needs, and priced survivors at 100 runs each. I rebuild it:

| Cell family | Assumption | Runs: central (all-low; all-high) |
|---|---|---|
| Depth-1 fault cells | 5 surfaces × 150 sites × 7 kinds × 2 modes × 1.5 layouts | 15,750 (5,400; 72,000) |
| Default probes | one per (site, layout) | 1,100 (600; 3,000) |
| Base side of the differential | The head side is the depth-1 cell already counted. One base run per cell at a shared site, about a third | 5,250 (1,800; 24,000) |
| Clean covering-array runs | 60 layouts × 5 surfaces × head and base | 600 |
| Environment, config, locale | (15 env + about 60 config-swarm runs + 3 locales) × 5 | 400 |
| Byte-class round trips | about 100 per surface | 500 |
| Depth-2 sample at B3 | fixed budget | 1,000 |
| **One full run, without mutation** | | **≈ 24,600 (10,300; 101,500)** |
| Mutation, in the final run only | 150 mutants on the changed lines, all operators (R5's 60 in §9.2 is a different count: the error-path mutants of the two lane libraries only, for comparison with the lane parts). About 140 killed × about 5 runs to the first kill = 700. About 6 error-path survivors × about 100 cells each in which the guarded command failed = 600. About 4 value-operator survivors × about 2,000 cells that executed the line = 8,000. Without tier 3's line record the value survivors' domain is every cell entering the function, about 5,000 each, and the total is about 21,000 | **≈ 9,300 (3,000; 30,000)** |

**One full run** at t = 1.0 s is about 6.8 CPU-hours, or **about 1.7 h at 4 slots**. The final run's mutation adds about 0.65 h. The all-low case is about 37 minutes and the all-high case about 10.6 h; each puts every factor at its own end at once, so they are bounds, not a likely spread. This is an estimate, and step 0b-i measures each factor.

### 5.3 Slice 0, replayed under the design, stage by stage

The span runs from the start of blind authoring to a landable tree. The spec and design time, shared by both, is excluded. So is the one-time cost of building the harness.

| Stage | Old, measured | New: central, on the critical path | With both levers (t = 0.3 s, tracer) | Basis |
|---|---|---|---|---|
| Blind authoring | 1.25 h: blind assertions and red, 22:48-00:03 (d3 §12.2) | 1.0 h: blind case, reference model, two held sets, two salts; mutant author in parallel | 1.0 h | about 40 claim rows, most instantiated; R1-R9 forms already in plan C5 |
| Lint and freeze | — | 0.05 h | 0.05 h | mechanical |
| Build | 1.6 h (00:03-01:37) | 1.6 h; case attack round 1 runs beside it, off the path | 1.6 h | unchanged |
| Census, plan, default probes, red on base | — | 0.2 h | 0.1 h | mechanical |
| Evidence run 1, full | — | 1.7 h | 0.5 h | §5.2 |
| Fix by class 1, with triage, and the lead settling beside it | Nine fix stages, R1's 42 min among them, totalling 296 agent-min (g2 §3) | 2.0 h | 2.0 h | about 8-15 clusters, fixers parallel by file; triage of false-positive clusters, which §9.3's bars allow up to 25%; the 7 items that needed the lead's decision (g2 §3; g2 §5 put the lead's decisions on items 45 to 49 at 1-2 h) arrive together after run 1, and the fixes that depend on them wait. Attack round 2 runs beside this, off the path |
| Evidence run 2, with attack round 2's rows | — | 1.8 h: every cell reruns, because there is no sound reach without the tracer (§4.8) | 0.3 h: the cells in reach, about 60% on a new feature | |
| Fix 2 | — | 1.0 h | 1.0 h | |
| Evidence run 3, final: a fresh held set, the positive control and mutation | — | 2.4 h | 0.7 h | §5.2 |
| **Checking after the build** | **21.5 h** | **≈ 9 h**; about 12.5 h if the final run finds a fix-caused failure and forces one more loop. Bounds: about 5 h (all-low machine constants, fix stages as above) to over 30 h | **≈ 4.7 h** | |
| Gate and CI | not in the 21.5 h | about 1.4 h | about 1.4 h | gate 26 min as measured on 10-10 on the old Mac; the PR gate runs on 10-30 took 50-58 min (`actions-minutes-quota-binds.md`), plus sampled cells |
| **Blind authoring to landable** | **≈ 24.4 h**, plus gate and CI | **≈ 13-14 h** | **≈ 9 h** | |

g2 §5 reached 4-6 h of checking by a different route, assuming sweeps of minutes; d1, d3 and d5 estimated 3.8-5 h. d3 and d5 used low cell counts and a cheap survivor rule, d1 assumed 8-16 slots, and all three assumed reach-scoped reruns. On the corrected constants, those figures match only the column in which both levers work.

**Against the loop now in force.** The capped loop would have cost slice 0 about 5.4-7.8 h of serial agent time before gaps (§1.1). At central constants this method takes about 9 h and is slower. With a fork-server and the tracer working, it takes about 4.7 h, level with the cap or a little faster, because the agent work after the build (fixing, triage and settling: about 3 h) becomes the floor. What the method buys in either column is strength the cap gives up:
- a printed denominator;
- evidence shown able to fail;
- a computed residual;
- fault classes in shared code found and filed, not stated as limits;
- and a fresh sweep, on a held set, after every fix and before landing, so a fix-caused failure that the sweep's cells and oracles can detect is caught before landing. Depth 2 is sampled, layouts are chosen per site, and O1 judges against the clean run, so this is not every failure inside the fault model. The cap catches one only if it falls within its three rounds.

**Test lines** (estimate): about 250 lines of case TSV, about 30 of reference model, about 400 of blind functional examples and about 150 of domain generators (d3 §12.2), against 4,526 hand-written lines at HEAD.

**Fix-caused items:**
- Under stop-rule condition 3, a sweep runs after every fix and before landing, so a fix-caused item that the sweep can detect surfaces in the evidence run after the fix that caused it. How many it detects is what §9.2's R2 measures, against §9.3's bar of 13 of 17. That is a go/stop signal, not a catch figure. At central constants that run comes about two hours after the fix, about the old round's delay; with the levers it comes in well under an hour.
- Fixes made by class would probably prevent several of them.
- With the trust core done first (§4.7), d5 §14 reads 7 of the 46 items as never arising, because the lane would not have needed its own 155-line resolver copy, and 8 more as caught on main's core before slice 0, by kernel differential, primitive sweep or write-set oracle (so, in d5 §0's steady-state reading, none of the 15 reaches the lane). The 7 are a counterfactual, not a catch.

### 5.4 A feature ten times larger

Assume about 7,000 engine lines, about 20 surfaces (12-30) and about ten times the effect sites. **Every constant here is slice 0's estimate scaled, and none is measured. The 10x figure is rebuilt from constants measured on slices 0 and 1 (step 0b and the prospective test) before it is quoted outside this document or used in a decision.**

**Cells per full run.** Without the primitive: depth-1 about 157,500, default probes about 11,000, base side about 52,500, other families about 9,000 (they grow with surfaces), so about 230,000 runs, about 16 h at 4 slots on t = 1.0 s. With the primitive: §11.2 #17 makes it mandatory only in core files and new B3 feature files, so shared callees keep K̄ near 7. If half the sites are in new mediated code at K̄ about 3 (one ⊥ cell, a kill of the own shell, and an S1 interleaving at snapshot boundaries), the effective K̄ is about 5 and a full run is about 170,000 runs, about 12 h. The kinds the primitive cannot absorb stay in that count: S1 between reads, K2 and K3 at the surface's own output, X6 hangs, and R2 at the caller's descriptors, counted per boundary or per surface.

**Survivors.** About 1,500 mutants on changed lines. About 1,400 killed at about 5 runs each is 7,000 runs. About 60 error-path survivors at about 100 cells each is 6,000. About 40 value-operator survivors, each over the cells that executed its line (about 8,500 if its function sits in one surface group of twenty), is about 340,000 runs, about 24 h. A B3 survivor must run its whole domain to be listed as indistinguishable. Below B3, a seeded sample of 500 cells per survivor is enough, because a survivor that a sample did not kill still counts against the bar; sampling can only fail to clear it. If a third of the changed code is B3, discrimination is about 140,000 runs, about 9.7 h.

| Stage | Central (t = 1.0 s, tracer working) | Without the tracer | Both levers (t = 0.3 s, tracer) | What it grows with |
|---|---|---|---|---|
| Case authoring | 2-3 h, parallel per surface group | same | same | surfaces and schema fields. Mandatory classes instantiate |
| Build | 10-12 h wall with parallel builders | same | same | outside this design, and the least certain figure |
| Evidence run 1 | 12-16 h at 4 slots | same | 3.5-5 h | sites × discriminating layouts |
| Fix by class, two or three iterations | 4-6 h | same | same | clusters, by (claim × kind class × function), which grow much more slowly than sites |
| Two evidence runs after fixes, the final one included | 6-12 h (reach about 20-40% of cells per fix) | 24-32 h (every cell, twice) | 2-4 h | the reach of each fix |
| Case attack, two rounds | about 0.5 h on the path; the rest beside the build and run 1 | same | same | surfaces |
| Settle | 4-10 h on the path, of 7-20 h in all | same | same | contract questions. Slice 0 had 7 items that needed the lead's decision, from about 750 changed lines (g2 §3); g2 §5 put the lead's decisions on items 45 to 49 at about 1-2 h. Scaled linearly that is about 65 questions. g6's deliberation moves some before the build; how many is unmeasured |
| Discrimination | about 9.7 h (3-24 h) | more, without tier 3's line record | about 3 h | survivors × their domains |
| Gate and CI | 1.5-2 h | same | same | plan A's selection assumed |
| **Checking after the build** | **≈ 30-70 h (central ≈ 47 h, gate and CI included; about 45 h on §5.3's span)** | **central ≈ 66 h** | **central ≈ 25 h** | |
| **End to end** | **≈ 45-85 h (central ≈ 60 h)** | **central ≈ 80 h** | **central ≈ 38 h** | |

**Founder stops, counted as a cost.** At 10x one should expect on the order of 10-30 person decisions for one feature: narrowings with no mechanical witness at B3 and above (d3 read one or two per slice-0-sized feature; below B3 they land UNKNOWN and stop no one, §11.1 decision 5), attack-bound escalations (up to one per surface group), R-base inheritances on new B3 surfaces (decision 7), and B3 divergent-but-accepted survivors. Founder interruptions per session is the binding objective (direction §3), so the prospective test counts them.

**What this says plainly.**
- At ten times the size, checking is about four times the build at central constants, and about twice the build with both levers. It is not at parity.
- What dominates is CPU on one Mac, mutation survivors at B3, and the lead's contract questions.
- The uncapped old loop had no bound: slice 0's density was 46 items from about 750 changed engine lines, at about 6.6 items per 2-hour round, and it did not converge on its own (d3 §12.3, d5 §9.3). **The capped loop now in force does have a bound at 10x.** Its cost there is unmeasured. It stops after three rounds whatever remains, and yields no denominator. So at 10x the method is likely slower than the capped loop, and its case is again strength, plus whatever the levers buy.

**Levers, in the order they will be measured:**
1. A fork-server runner. Gate CPU is fork-bound (659 s user against 639 s system), so loading the engine once per run of cells could cut t several-fold. Step 0b-i measures how much of t is engine start-up, which bounds this lever. Unmeasured.
2. The function-entry tracer (§4.8). Without it there is no sound reach, and every rerun is full.
3. The observation primitive and its lint, migrated beyond touched files. Fewer kinds per site, soundly.
4. Reach-scoped runs on PRs to mature code, with the full sweep nightly on main. This helps PRs, not new features, whose cells are nearly all in reach.
5. More slots, if the 48 GB Mac's capacity is measured above 4.

d1's 12.5 h and d4's 8.5 h of checking for 10x (d4's 20 h includes the build) assumed 16 and 10-12 slots. At the recorded cap of 4, d1's 49 CPU-hour cold sweep is about 12 h on its own, as a judge noted. I do not use either figure.

### 5.5 The gate and CI

- **The gate.** The 26-minute gate is plan A's to cut (row 30), not this design's. The `case` check reads receipts bound to the tree and plan. It reruns only what moved, and says when it reused. The 5-minute target (gate-friction design, via g1 §5) is not spent on sweeps.
- **CI.** felix-home's CI is GitHub Free on 2 cores, with a nonzero paid budget since 10-01, so minutes cost money rather than hit a hard quota (`actions-minutes-quota-binds.md`). The same note records CI down from 10-25 09:44Z (every run `startup_failure`, cause unconfirmed, most likely billing), during which land on green landed nothing because C9 needs CI's gate on the exact head, and CI running again on 10-30 with PR gate runs of 50-58 minutes. I did not check CI's state today. CI runs the full suite, which row 30 keeps, plus a sample of each claim's cells under main's harness, seeded from its run id. The full sweep runs locally under the pinned judge, and nightly on main. **CI's independent check of the sweep is therefore sampled.** That is weaker than today's full-suite rerun for the suite's own scope, and every receipt says so.

---

## 6. Assurance

### 6.1 What a READY verdict guarantees

For each claim that does not read UNKNOWN:
- its proposition held over the enumerated set: every site the layer observed, from generated inputs G, under FM-n, at depth 1 exhaustively and depth 2 over the stated sample;
- every cell that counted had fired;
- the evidence was shown able to fail on the change's own error paths: the positive control failed, mutants were killed to the bar, and the coupling to Felix's real faults is printed;
- the judge is main's;
- for kernelised core code, the decision logic was checked exhaustively over its stated domain against blind properties and a blind reference, and the shell refines it on the covering set under the fault cells;
- everything not covered is listed by class.

For the change as a whole, at B3 and above no claim present in the default case, at freeze or at base was dropped or weakened without a mechanical witness or the project owner's clearance (§4.8; on Felix, the founder's); at B0-B2 a claim an unwitnessed narrowing touched reads UNKNOWN in the receipt and residual (decision 5).

### 6.2 What it cannot guarantee

1. **Spec gaps.** A claim nobody wrote. F11's "1 day" is the example. Mandatory classes and design deliberation shrink this gap, and nothing closes it.
2. **Faults outside FM-n, and inputs outside the generators' byte classes.**
3. **A wrong clean answer** outside the kernelised core, beyond what the reference, the examples and base equivalence judge.
4. **Effects the layer cannot see.** "Enumeration remains the weakest joint of any checker" (amendments §6). The census makes the gap visible, and it does not close it.
5. **Concurrency** beyond the stated turnstile bound.
6. **Blindness**, beyond the temporal precedence that commit-reveal makes checkable.
7. **Mutation adequacy is not fault adequacy.** About 27% of real faults couple to no mutant of the commonly used operators, and about 17% to no mutant even with new or stronger operators (Just et al., on Java).
8. **Platforms not run.**
9. **The trusted base itself**: bash, git, awk, the kernel, and the harness. The harness is qualified, not proven.
10. **The floor.** Receipts are unsigned same-user files, and `felix merge` is client-side, so `gh pr merge` skips it (`felix-floor-and-wall.md`, via g1 §2). Nothing signs before March, and even then signing stays off the deciding path: the founder's 10-29 ruling lets nothing that decides read or wait on a signature, and an unsigned receipt still lands (`agent-receipt-format-2026-10-29.md`; direction's "Not before March"; g1 §9 item 9).

### 6.3 How a receipt says it

The values below are placeholders, not results.

```text
claim     lane.failclosed@status-row    class FAILCLOSED@<hash>    budget B3
subject   tree <id>   case <hash> (freeze <sha>; read stricter of freeze, base, head)
judge     main's installed engine <version>: harness <hash>, FM-1 <hash>, catalogue <hash>, oracles <hash>
method    bounded-exhaustive within FM-1 at depth 1 (first, last, persistent); depth 2 sampled: <n> pairs,
          seed revealed from <hash> committed at <freeze sha>
census    static <n>; reached <n>; mediated <n>; unmediated <n> (listed); unreached <n> (listed; 0 in changed functions)
inputs    <n> layouts, pairwise over <d> dimensions; byte classes <k>/<k> covered, <j> declared impossible (listed)
cells     planned <n>; run <n>; fired <n>; not discriminating 0 on changed code; held <n> (set <k>, unseen by the builder);
          failed 0; nondeterministic 0; R-base <n> (filed as candidate <id>; inheritance admitted, so filed as an obligation to fix: <list>)
narrowing <n>, each with its witness, the person who cleared it, or, below B3, UNKNOWN
spot      replays every earlier failure, plus k = 5 per claim seeded from main's tip at merge; P(one flipped cell found) <p>
discrim   positive control failed as required; diff mutants <k>/<m> killed; indistinguishable <i> (cap 5%, listed);
          operator coupling to Felix's own faults <c>% (corpus <hash>)
kernels   resolve_decide: <N>/<N> vectors, <p> properties, blind reference agrees, <s>/<s> spec mutants caught
          [checked exhaustively over the stated domain]
residual  outside FM-1; layer-blind: <list>; non-bash children; gh model fidelity; platforms not run: <list>;
          judge pin open to the in-place entry race and the copy swap race (audit C063, b13) until roadmap step 15
evidence  LOCAL_MEASUREMENT; CI sample <n> cells on Linux, agreeing      words: "checked", never "verified"
blindness case authorship recorded, not verifiable (amendments §2.2); fixtures and salt precede the build: checked
residual  one authority still writes both the work and the judgement of the work (amendments §6)
status    VALID      depends: tree, harness, FM, catalogue, case (Phase 2: per-claim fingerprints, direction row 21)
```

An outside sentence built from it reads: "`felix lane` at tree <id> was checked, not proved: over <n> depth-1 cells of fault model FM-<v> and <m> generated layouts, every faulted run printed the clean answer or knew less, wrote nothing, and named the cause it met; <k> of <m> mutants of the change were killed; <u> effects were not mediated and are listed. One authority still writes both the work and the judgement of the work, and enumeration remains the weakest joint of any checker." The last sentence is amendments §6's, which must appear "wherever the system reports its own trustworthiness" (lines 230-235). The placeholders stay placeholders in any text outside Felix until §9's runs fill them (§11.2 #14).

### 6.4 Expected catch on slice 0: a hand mapping, not evidence

All five designs mapped g2's 46 items onto their own mechanisms by hand, after reading g2. Their figures run from 39 to 43 of 46, and g2 had already read 43 as having a mechanical detector, by hand classification, not a run. Their byte and layout catalogues (`1` against `01`, sentinel words, trailing LF, GIT_GRAFT_FILE, decoy refs) are visibly taken from the findings.

On the same reading, this design reaches the 41 items g2 classes as fault injection, metamorphic, layout or differential, plus the 2 lint items. Some of those 43 hold only on conditions:
- R2B-F2 needs tier 3, and R2B-F5 needs tier 3 or tier 1's `pwd`. Tier 3 must leave a nonzero status where it skips a command (§4.3 item 4).
- F3 and R2-F8 need the old-git arm.
- R2-F10 needs hostile values for each config key's type.
- V3R2-F3 needs the trailing-LF class.
- **Every P1 item whose defect prints a default needs a discriminating layout** (§4.3 item 7): R2-F1 (every lane idle `0 of 0`), R2-F5 (an empty next text), R2-F6 (a `-` date), F1 (no lane). On the first layout that reaches the read, those faulted runs can equal the clean run and pass.
- V3R1-F2 needs a layout with two projects whose `remote_match` values nest; V3R2-F2 needs a `.felix` marker that names no project, or a `remote_match` tie; F6 needs a commit whose object can be removed. Only the pairwise (site × layout class) array supplies those.

Five of the 43 still need a lead decision once detected (F8, F9, V3R1-F2, V3R1-F3, and R3-F3, whose resolution is design item 46), six if R2-F8's stated residual counts. V3R3-F3 needs one too, but it is outside the 43. Not settled mechanically: F11, V3R2-F4, and V3R3-F3 (detected; whether it is allowed is a spec question).

**No catch figure from any design, or from this paragraph, may be used inside Felix or in outside text** until two things have run:
- the replay with hindsight-free libraries (§9);
- the prospective test on slice 1 (or the feature it moves to, §9.4), whose findings nobody knows.

The judges' verdicts, which are not filed, named this the shared flaw.

---

## 7. The product

**What a team gets on every pull request an agent writes.** A case page in the PR. It shows:
- the claims the change owes, most of them instantiated from claim classes for the kinds of surface it touched;
- for each claim, the evidence, its method class and its scope, in the form "<n> cells of FM-<v> at depth 1; <p> sampled pairs; <k> of <m> error-path mutants killed" (no figure is filled in outside Felix before §9's runs, §11.2 #14);
- every failing cell as one replay command;
- every surviving mutant as a concrete diff, read as "this version of your code also passes every check you have";
- the residual by class, ending with amendments §6's sentence: "one authority still writes both the work and the judgement of the work", and enumeration remains the weakest joint of any checker;
- UNKNOWN holding wherever nothing was shown.

The lander merges by the case, and by nothing a model said. After landing, the claims stand. When a later change moves their reach, they go stale and must be earned again.

**Why it is not CI.**
- CI answers whether the tests someone wrote pass.
- The case answers what was claimed, over what denominator, under which fault model, and with which evidence shown able to fail. It also names what was not looked at, and keeps holding when an input moves.

The number in the positioning the founder chose read "verified work per hour of your attention" (the 10-29 option text). Decision 1 (2026-10-31) made it "checked work per hour of human attention" (direction row 36). The case gives that number a denominator. Human attention goes to contract questions, to narrowings no mechanism can witness at B3 and above (below B3 they land UNKNOWN and no one is asked, decision 5), and to residuals at B3 and above, not to reading diffs to guess what was tested.

**Across languages, honestly tiered.**
1. **Shell-driven work** (scripts, CLIs, build and deploy commands) gets the full layer, as Felix itself does.
2. **Any program at its process boundary**: fail-closed under process faults, the write set, offline, base equivalence, metamorphic invariance and reference agreement all apply as they are. On Linux CI, `strace --inject` and `fail-nth` reach system calls. On macOS, DYLD interposition is limited for SIP-protected binaries (community sources only, via g3 §10).
3. **In-process faults and deep systems** use the ecosystem's own tools as pinned evidence providers through the capability plane:
   - property-based and stateful testing;
   - deterministic simulation frameworks;
   - the ecosystem mutation tools Stryker, PIT, mutmut and cargo-mutants (d4 §14), whose per-mutant rows Felix's bash judge recomputes;
   - black-box fault services, taken as THIRD_PARTY_ATTESTATION for their stated claim only.
4. **Decision logic that matters** (authorisation, money, deletion, release) can be offered the kernel-and-shell refactor and checked exhaustively. That is offered, not required.

**What is defensible.** The injector is not: the reviewers wrote one in 66 lines, and their whole generic kit, injector, classifier, limit loop, sweep and bisect, is 548. Three things together are:
1. a small kernel that is qualified and pinned, which the agent that wrote the code cannot edit (amendments §2.3);
2. a catalogue and fault model grown row by row from escapes, so each team's change is checked against faults found elsewhere. **Only project-free rows cross between projects**: a fault kind, an origin class, a byte class, a layout class. A lint refuses any shared row that names a project, a path, a repository, a person or a value taken from a project's data, which is constitution invariant 1 ("The engine names no project") applied to the catalogue. Felix governs other people's projects (direction row 8), so a row derived from one team's escape stays in that team's project unless it passes the lint;
3. a ledger that composes evidence of different strengths into one release decision, with discrimination evidence and staleness.

On vendor documentation, nobody ships all three (§3.3). The claim rests on absence of documentation, not proof of absence.

**Honest limits of the offer.**
- For containerised distributed systems, deterministic hypervisor services go deeper, and Felix should hold their runs as evidence rather than compete with them.
- For compiled code on macOS, Felix's own layer reaches only the process boundary, and the receipt says so.
- Outside text never says "verified" or "proven". Once the evidence engine exists, it says "checked within a stated fault model"; until then it says what ran, such as the gate and its suite, and names no fault model (direction row 36). It claims no independent acceptance before #350 and the pin (direction row 17).

---

## 8. Design deliberation as a Felix capability

The founder's message asked for this directly: "how we are making sure that our engineering design is match our level ... This is also itself a capability, a Felix option". The workflow that produced this document is the capability's first instance, run by hand.

### 8.1 This instance, stage by stage

| Stage (g6 §3.2 name) | What ran | What it produced | Proposes or decides |
|---|---|---|---|
| S0 Trigger | The founder's request; nothing automatic | — | — |
| S1 Frame | g1: the trust plane as built and as directed | constraints quoted with file and line | proposes; its file claims are checkable |
| S2a Internal prior art | g2: slice 0 read as data from journals and git | 46 findings classified, times per stage | times and counts measured from records; the classification of each finding is g2's reading, not a run |
| S2b External prior art | g3 simulation and fault injection; g4 generated tests and adequacy; g5 specification, formal methods and market; g6 deliberation | sourced practice | proposes; read mostly through summaries |
| S3 Divergent design | d1-d5, each with a different charge, run in parallel and blind to one another | five designs | proposes |
| S5 Evidence first, judgment second (here judgment only) | three judges with different lenses (assurance and soundness; latency and scale; product and fit, the last doubled) | scores, grafts, fatal flaws | advisory. Judge 1 checked d5's code readings on main; judge 2 checked d1's slot arithmetic and d5's run count against measured logs |
| S7 Decide and record | this document | spine, grafts, decisions with reasons, alternatives | proposes. It is a model's synthesis, so its choice is a plan |

### 8.2 What this instance did well and badly

**Did well.**
- The designs were independent and parallel, with no debate. The judges disagreed on the winner (one chose d1, two chose d3), and that disagreement is recorded rather than smoothed over.
- The judges caught real errors (from their verdicts, which are not filed; the second, third and fourth are restated with their own reasoning in §5.4, §5.2 and §4.1):
  - d5's run count does not add up: 300 × 9 × 2 + 1,600 is about 7,000, not 4,300;
  - d1's and d4's 10x figures assume 16 and 10-12 slots against a recorded cap of 4;
  - d3's cell count is 3-6 times low;
  - lineage pruning and stack-only reuse are unsound;
  - a model claim can unblock release in d3's B3 rule.

  Each of these changed the decision here.
- The judges checked code readings against main, and I re-checked them (§1.4).

**Did badly.**
- **No spike.** No stage ran Felix code: d1, d2, d5 and g3 were refused bash, and d4 and g2 ran only read-only git commands and g2's journal scripts. So t, S, the slot capacity and the DEBUG trap were never measured, and the designs' slice-0 cell counts spread six-fold. The capability needs an evidence stage that can run code (g6 S5, "evidence first, judgment second"; AlphaEvolve's rule, https://deepmind.google/discover/blog/alphaevolve-a-gemini-powered-coding-agent-for-designing-advanced-algorithms/, via g6 §2.1).
- **Contamination.** Every designer read g2, so their catch figures cannot count as evidence (§6.4).
- **Correlated authors.** Nothing in the files says which model family each stage ran on. If all were one family, the designs share blind spots (Kim et al., §3.2). Panels of different families beat a single judge (https://arxiv.org/abs/2404.18796, via g6 §2.3).
- **No yield record.** Tokens and wall time per stage were not logged in any file I read, so this instance cannot report its own cost.
- **Unfiled verdicts.** The judges' verdicts lived only in a later stage's task text. The first version of this document rested its spine on "two of three judges", which no reader could check. The capability files every stage's output, verdicts included.
- **Optimism the critics caught.** The first version's cost figures used an unsourced mode factor, placed fault cells where they could not discriminate, priced survivors at a hundred runs, compared against a loop the 10-30 cap had already retired, and let model-authored case text widen before freeze. Two critics found these after the judges did not. The capability's S6 red team should include a "cost against the policy in force" lens and an "authority of every authored field" lens.

### 8.3 The capability

**Purpose.** Before a build, state what the checks will cover, so that review does not have to find it.

**Output.** A draft case. It holds the properties with their quantifiers, the effect inventory, the fault kinds that apply, the required response in every cell, the residual, and what evidence would reverse the decision. The draft goes to the blind case author (§4.9 S2) as candidate claims. It enforces only through qualified checks.

**Stages,** after g6 §3.2, with two changes from this instance:

| Stage | What happens | Change from this instance |
|---|---|---|
| S0 | Budget class, computed mechanically from paths and `risk.tsv`. A model may raise it and never lower it | — |
| S1 | Frame, followed by a scoped fact check whose skeptic defaults to "refuted". This reuses `lane-design-fact-check` (g6 §1.1) | — |
| S2 | Prior art. Internal comes first: findings, escapes and lessons for the surfaces touched | — |
| S3 | Two to four blind derivers with different charges, on different model families where the host allows | — |
| S4 | Union, then an STPA-style sweep: each effect × each fault kind × the required response (https://www.flighttestsafety.org/images/STPA_Handbook.pdf, via g6 §2.4). A cell with no response is an open question, not a pass | — |
| S5 | **Spikes are mandatory** wherever a cost or behaviour can be measured. A panel ranks designs only where nothing can be measured: anonymised, run in both orders, scored against a rubric, with no judge from the authoring family | new |
| S6 | Red team: simpler, premortem and defeat. A finding must be a concrete new cell or a cited fact | — |
| S7 | Decision record: the chosen design, the alternatives and why each lost, the residual, and what would reverse the decision (https://www.industrialempathy.com/posts/design-docs-at-google/, via g6 §2.5) | — |
| S9 | Learning: every post-build finding is classified as a design, checking or implementation escape | — |
| — | **Every stage logs its model, effort, tokens and wall time** (direction row 17 already requires model and effort) | new |

**Where it lives.** First as a Workflow script with no engine code, run by a session before a build; step 0c is its first run. Nothing on the enforcing path calls it, and if it ever becomes a `felix` subcommand it stays advisory, because a command that calls a model may only propose (constitution invariant 2). Its output enters the method only as candidate claims handed to the blind case author.

**Triggers, and a narrowing of the founder's request.** The founder asked for this "for every implementation". Felix runs it for every implementation, in two tiers, and that split is Felix's cost decision, stated here so it is visible:
- **The full tier** (S0-S9 below) when any one of these holds: B3 or higher; any change to trust-plane code; a new surface with no prior design; a surface whose history shows a design escape in the last ten changes; any change that would add a table, a runtime or a founder stop; a founder request.
- **The cheap tier** for everything else, B0-B2: S0, S1's fact check, and S4's effect × fault-kind sweep by one deriver, producing a draft case in about twenty minutes. No panel, no red team.

If the cheap tier's design recall (measure 1) falls below the full tier's by a margin the first ten cases show, the full tier's triggers widen.

**Honesty.** Models propose designs, properties, faults and critiques. Facts go to skeptics, inventories to traces, costs to spikes, and coverage to the cell report. Only the choice among designs is judgment, and that is a plan, never release-authoritative. Blindness is recorded and not verifiable (amendments §2.2), and every record says so.

**Measures,** computed from records, never recalled:
1. **Design recall.** Post-build findings whose property and fault were already on the draft case, divided by all post-build findings. This is the main number. Step 0c (§10) is its first measurement.
2. Post-build rounds and their wall time.
3. Escapes after landing, classified.
4. Time to land, split into design, build and checking.
5. Yield per stage: surviving findings per agent and per million tokens. A stage that yields nothing for five changes in a row leaves its class's budget.
6. Panel calibration: does the panel's rank predict outcomes over about ten cases? If not, panels leave the default.
7. Founder interventions per deliberation.

**Falsifier.** Step 0c runs the full tier's S0-S7 blind on slice 0's design as approved at `8c5b8725`, with the same hindsight-free inputs as FM-0 (§9.1), and scores the draft case's design recall against the 46 items, with two scorers from different families. If the draft case names neither the unfinished-read property nor most of the fault families, deliberation does not replace review, and the mechanical catalogue carries the load alone (g6 §6). The same run with only the cheap tier gives the first comparison of the tiers.

---

## 9. Validation before adoption

Nothing past step 0 of §10 is built until this has run, except the narrow owed fix of step 1, which needs only P2. It runs in a scratch clone made from git objects, never in the lane-counter worktree. It takes slots only through the Mac-wide 4-slot semaphore it shares with the builders' part runs (`parallel-builders-oversubscribe-the-mac.md`), and measures CPU with getrusage on a quiet machine (`measure-cpu-not-wall-under-load`, MEMORY.md). The protocol is d1 §16's, with arms from d4 and d3, and P2 and P3 from d5.

**Its inputs are in the memory root.** The reviewers' `review*.sh` scripts (125 when g2 counted them, 133 now, the five generic ones among them) and their logs are in `~/.felix/memory/felix/audits/2026-10-30-trust-plane-design/lane-build/`. g2's data (`findings.txt`, `outcomes.txt`, `measure.txt` and the rest of `g2/`) and this workflow's files are in the same directory's `workflow/`. They were written under `/private/tmp`, a path macOS may clean, and were copied out on 2026-10-31, when this design was filed. Everything below cites them there.

### 9.1 Frozen before anything runs, and hashed

1. **FM-0, the catalogues, the claim-class catalogue, the oracle rules and the lint list.** An agent writes them from **primary sources only**:
   - the bash 3.2 man page;
   - a command census of main at `c170ed5f`, the commit the lane build forked from;
   - the external sources listed by URL in g3's and g4's Sources sections, read at those URLs, **never g3's or g4's prose**, which describes `lane-probes.sh`'s `_lf_fault`, `_lf_fork`, `_lf_kill`, `_lf_gone` and `_lf_nfprog`, maps slice 0's findings to cells (g3 lines 15-17, 142-162, 225-235), and frames g4's argument on design items 45-47 (g4 lines 9-12, 72-73);
   - the oracle classes O1-O11 as abstract definitions, without this document's examples, which come from the findings (§2.3's contamination note).

   **No Felix memory notes.** They are edited in place, carry only a last-modified field, and sit in no repository (direction §6), and fault lessons such as `printf-grep-q-races-under-pipefail.md` (modified 2026-10-30T06:19Z) and `sandboxed-suite-traps.md` (2026-10-30T20:28Z) were last edited after the lane build began. No snapshot dated before it exists, so the notes are left out. The cutoff, wherever a date matters, is 2026-10-30T05:34Z (10-29 22:34 -0700), before the lane build's first stage; I did not confirm the time zone of the local times d1, d2, d4 and g3 give.

   It is not shown g2, the lane design's §11 items 44-49, the reviewers' scripts or `lane-probes.sh`. **Before the freeze, every input is grepped for slice-0 terms**, among them `lane`, `R2B-`, `V3R`, `item 4`, `_lf_`, `ulimit -u 1`, `ulimit -S -u 1`, `trailing LF`, `ends in LF`, `GRAFT` and `GIT_OPTIONAL_LOCKS`, and **any hit refuses the freeze**. This is the most important control, because a library shaped by the findings makes the replay circular (d4 §16), and the replay's go bar gates engine work.
2. **Two blind cases.** Two authors, the second from a different family where the host allows, are given only the design and plan at `8c5b8725`.
3. **A signature for each of the 46 items**, written from g2's table: surface, command word or function, fault kind or input class, and oracle. A failing cell matches a signature mechanically. Two scorers from different families score blind to each other, and their disagreements are reported.
4. **The harness's own qualification set:** planted defects not taken from slice 0, written by an author blind to the harness (§4.8), for step 0b-i.
5. **These bars.**

### 9.2 Arms and runs

**Arms.**
- **A:** the catalogue and mandatory classes only. The case holds just surfaces, schema and delta. This measures what the prelude alone catches.
- **B:** A plus the full blind case.
- **C:** B plus four finders on the bounded check language. C minus B measures what model finders add, per million tokens.
- The old method's known outcome: 46 items in 21.5 h, and the capped loop's estimated 5.4-7.8 h (§1.1).
- Design deliberation runs separately, as step 0c (§8.3's falsifier).

**Runs, in three parts.** A part starts only when the one before it has reported. Compute is estimated at §5.2's central constants and is re-estimated from 0b-i's measured t, S, K̄ and L_d before 0b-ii starts.

| Part | Run | Where | Measures | Compute (central, 4 slots) |
|---|---|---|---|---|
| 0a | Spike | `/bin/bash` 3.2 | The `extdebug` skip and the status a skipped command leaves; a trap that ends a substitution's subshell with a nonzero status instead; whether function entry and command resolution can be traced (the basis of §4.8's reach and reuse); the slowdown of each; exported functions shadowing `pwd` and `cd`; whether `/bin/sh` children import them; a kernel's per-evaluation time | minutes |
| 0b-i | Qualify | the harness against its planted-defect set (§9.1 item 4) | that it fails where it must; t with the layer, oracle and fixture clone included; S, K̄, L_d, modes; the start-up share of t | 1-2 h |
| 0b-ii | R1 | `3f893610`, the build's end, arms A and B (C if its finders are ready) | recall on the items present there; cells, CPU, wall | about 3.5 h |
| 0b-ii | R3 | `cff711ef` | new failing clusters, triaged as defect, contract question or false positive | about 1.7 h |
| 0b-ii | P2 | main's core, on main **and on `claude/audit-combined`**: the resolver, `felix_table_check`, `felix_obligations_run`, `felix_merge_blockers` with all eight producer pipelines of §1.4, `_gt_deploy_owed` | Confirms or refutes each §1.4 reading on both. Failing cells become the red-first evidence of the owed trust-plane PR. d5 §13 predicts cells with the shapes of R2-F3, R2B-F1, R3-F2, V3R1-F2, R2B-F6/V3R1-F5 and R2-F4. An item the audit branch already fixes is dropped from step 1 | about 1-2 h |
| 0b-ii | Determinism | 200-cell resample with the same seed | byte identity | minutes |
| 0b-ii | Transparency | every surface, pass-through against envelope-only, and against no layer with volatile fields normalised | exactness; the unmediated share | minutes |
| 0b-iii | R2 | each fix that introduced or left open one of the 17 (g2's Fix column: nine runs, after the eight fix commits `2fac1227`, `2bd07271`, `5b5be29d`, `dd710e53`, `2e9a6ade`, `26d33e3a`, `ebfa3c35` and `33875863`, and after the commit whose fixture growth took `tests/lib/lane-fixture.sh` past 500 lines (V3R3-F2)) | whether each is caught at the commit right after its cause | about 15 h: a full run per commit, since reach is not sound without the tracer |
| 0b-iii | R4 | `cff711ef`, with each of the 46 fixes reverted one at a time | operator coupling to Felix's own faults | about 15-20 h: a caught revert stops at its first kill, and an uncaught one costs a full run |
| 0b-iii | R5 | `cff711ef` | 60 error-path mutants of `lib/lane.sh` and `lib/lane-resolve.sh` (not the 150 of §5.2, which span every operator): the sweep's kill rate and CPU against the existing lane parts 2200-2250 | a few hours |
| 0b-iii | Holdout | one audit-register batch at its pre-fix commit, chosen after reading the register and `claude/audit-combined` | recall on findings the libraries never saw. Informative | 1-2 h |

0b-ii is about 7 h of compute and decides stop, or continue. 0b-iii is about 33-38 h of compute, so it runs on otherwise idle slots, mostly at night, and only after 0b-ii's numbers say continue. Go or narrow is decided after 0b-iii, because the fix-caused bar reads R2. The live lane build needs the same slots.

### 9.3 The metric and the bars

**The primary metric** is recall on the 41 items g2 classes as fault injection, metamorphic, generated layout or base differential. Each item is counted at the earliest commit where it is present, under hindsight-free libraries. **Recall is reported in two parts:** items whose oracle rule or catalogue row could only have come from a finding (the §2.3 contamination list), and the rest. Even frozen carefully, the replay is run by people who read the findings, so its recall is a go/stop signal for building the harness, never a catch figure. **The only catch figures are the holdout and the prospective tests** (§9.4).

**Go: build step 2 (§10) only if all of these hold, with the cost bar read through the band below the table.**

| Bar | Threshold |
|---|---|
| Recall, arm B | ≥ 33 of 41 (80%) |
| Fix-caused items caught at the commit after their cause | ≥ 13 of 17 (read from 0b-iii's R2) |
| False-positive clusters (mapping to no defect and no contract question) | ≤ 25% of failing clusters |
| Determinism | ≥ 99.5% byte-identical; every differing cell reported as a finding against the envelope |
| Transparency | exact on every surface; unmediated sites ≤ 10% of reached sites |
| Harness qualification | fails on every planted defect of §9.1 item 4 |
| Cost | first full evidence run at `3f893610` ≤ 60 min wall at 4 slots. §5.2's central estimate is about 1.7 h, so **this bar is expected to fail without a fork-server or a smaller measured cell count**; the band below says what follows |
| Authoring | the blind case takes ≤ 1.5 h wall. This guards against the 20 hours simply moving into authoring (d3 §17 risk 7) |

**The cost band.** If every other bar holds:
- **≤ 60 min:** go.
- **61-180 min:** step 2's prospective test may run, because its own time bar against the control decides whether the method is fast enough. Step 3 waits until a measured lever (the fork-server, or the tracer's reach on reruns) brings the first full run to 60 min or less. Step 1 never depended on sweep cost.
- **Over 3 h:** stop, as below.

**Informative, with no bar:**
- arm A's recall;
- arm C minus arm B;
- operator coupling;
- the sweep's kill rate against the existing lane parts;
- P2's results;
- new defects at `cff711ef`;
- holdout recall.

**Narrow.** If recall is 50-80%, or false positives are 25-35%:
1. classify each miss as a fault-model hole, a layer blind spot, an oracle hole or a generator hole;
2. fix the class once;
3. rerun, and report the result labelled post-hindsight, alongside the first result.

Go on to the prospective test only if the post-hindsight run meets the bars.

**Stop.** Do not build the engine substrate if any of these holds. Three of these are known after 0b-ii, and the fourth only in part. R1 gives recall on the items present at `3f893610`. About ten of the 41 come from a later fix and are first run by R2 in 0b-iii, so 0b-ii can stop on recall only when R1's catches plus those items still come to fewer than 21 of 41. Full recall on the 41 needs R2's runs in 0b-iii:
- recall is below 50%;
- the first run is over 3 h;
- determinism is below 97%;
- false positives are above 35%.

The fallback keeps the case's shape over blind hand-written examples instead of sweeps: claims, discrimination by mutation, the computed residual, the narrowing rule and per-claim receipts. It also uses g4's fault table and enumerator as helpers for hand-written parts (d2 §11). That is slower, and still stronger than today, because the suite gains discrimination evidence.

**Redesign the layer first** if transparency fails on more than one surface, or more than 10% of reached sites are unmediated.

### 9.4 The prospective tests, which gate the enforcing build

The replay is contaminated however carefully it is frozen, because everyone building it has read the findings. Only a feature whose findings are unknown measures recall honestly (d5 P3).

**Method.** Lane slice 1 lands under the capped review in force, which is the control: the first-build review plus at most two fault-injection rounds (`lane-slice-review-budget.md`). It never waits for the method. The method runs beside it with step 2's suite-side tooling, **on the frozen build-end tree, in its own clone**, and reads nothing of main, of the slice's PR or of the control's findings until it reaches its stop rule. Per-claim receipts, the `case` blocker and the pinned harness arrive only in steps 3-4, so **the stop rule that applies here is §4.10's conditions read from the branch tooling's result files, with no receipts**, and the result is "stop rule met in result files", never READY. Neither side sees the other's findings until both finish. Each side's fixes are its own. The method's findings are scored afterwards (below), and any confirmed defect the control missed becomes a red-on-main fix. If the harness has not qualified by slice 1's build end, slice 1 lands anyway, and the prospective test moves to the next lane slice or engine feature.

**Who confirms a defect.** Two scorers from different model families, blind to each other and to which side found what, confirm each candidate defect against the plan's contracts by building a failing case for it, as §9.1 item 3 does. Their disagreements are reported, and a candidate both reject is not a defect.

**Bars.**
- **Against the control alone:** the method found at least 80% of the control's confirmed defects, and every one it missed is classified as a fault-model, layer, oracle or generator hole. Recall on the union alone would mostly measure the method against its own findings.
- **Against the union:** the method found at least 80% of the union of confirmed defects from both.
- **Time against the control:** the method's wall time from the build's end to its stop rule is at most the control's wall time on the same tree (≤ 1.0x). The task's "far faster" (§1.5) is the target, 0.5x or less, and it is reported. It is not the gating bar because no column of §5.3 meets it: 0.5x of the capped loop's 5.4-7.8 h is about 2.7-3.9 h, and even the both-levers column comes to about 4.7 h. The central estimate (about 9 h) fails ≤ 1.0x too, so this bar passes only if the fork-server and the function-entry tracer measure near the values §5.3 assumes; the test is in part a test of those two levers. ≤ 1.0x asks that the added strength costs no time against the policy in force. The ratio to the build stage is reported too (slice 0's old ratio was 21.5 / 2.9, about 7.4).
- **Escapes:** any blocker the control finds inside the method's own fault model is an escape: it stops arming until it is explained and its class is fixed.
- **Attack rounds and founder stops** per feature are recorded.

**One feature is informative, not enough.** These bars must hold on two features (lane slice 1, and lane slice 2 or another engine feature) before steps 3-5 are built. If the harness has not qualified by slice 1's build end, the first test moves to the next lane slice or engine feature. Arming the blocker (decision 3) waits further, for step 4's silent shadow, which logs would-holds on two new features built after the blocker exists and must meet bars fixed before it runs, under the bound the founder sets from it.

---

## 10. Build order

Days are estimates in workflow-days. Steps 0a, 0b, 0c and the narrow step 1 need no founder act while CI runs. The founder placed step 1b and steps 3-5 on 2026-10-31 (decision 2), and both of step 1b's PRs, 1b-a and 1b-b's engine PR, wait for the founder's merge (decision 4, by Felix's reading of its "the code that computes a verdict"). Step 6 is not placed.

| Step | What | Days (est.) | Code | Whose call |
|---|---|---|---|---|
| 0a | DEBUG-trap spike on `/bin/bash` 3.2 (§9.2's spike row): the skip, **the status a skipped command leaves**, a trap that ends a substitution's subshell with a nonzero status instead, **whether function entry and command resolution can be traced**, the slowdown of each, exported functions over builtins, `/bin/sh` children, a kernel's per-evaluation time. **This decides tier 3, and whether there is sound reach** | 1-2 hours | scratch | Felix (a measurement) |
| 0b-i | **The replay harness, qualified and measured.** Built from the reviewers' 548 generic lines, `lane-probes.sh`'s mechanism, tiers 1 and 2 (tier 3 if 0a passes), the census (with the whole-file mode `lib/where-read.sh` lacks), the runner, O1 (⊑ and the safety order), O3, O5, O6 and O8, the default probe, the positive control, and a determinism envelope with a virtual clock and a `gh` model. It is a new verifier of several thousand lines, so risk 7 applies to it: it qualifies against planted defects not taken from slice 0, written by an author blind to it (§9.1 item 4), before any replay number counts. It measures t (with the layer, oracle and fixture clone), S, K̄, L_d and the start-up share of t | 2-3 | scratch, no engine code | Felix (a measurement) |
| 0b-ii | **The replay runs that can stop it:** R1, R3, P2 on main and on `claude/audit-combined`, determinism, transparency. Frozen libraries and blind cases first (§9.1) | 1, with about 7 h of compute | scratch | Felix (a measurement) |
| 0b-iii | **The rest of the replay, only after 0b-ii says continue:** R2, R4, R5, the holdout. Go or narrow is decided after it (§9.3) | 2-3, mostly unattended compute (about 33-38 h on idle slots) | scratch | Felix (a measurement) |
| 0c | **Design deliberation replayed** (§8.3's falsifier): a Workflow script runs the full tier's S0-S7, and separately the cheap tier, blind on slice 0's design at `8c5b8725`, and scores design recall against the 46 items | 0.5 | a Workflow script; no engine code | Felix (a measurement) |
| 1 | **The owed trust-plane PR, kept narrow.** The shared resolver's and table validator's reads (`resolve.sh`, `table.sh`) go through `felix_capture`, with a read that did not finish mapped to unknown. P2's failing cells are its red-first evidence. It needs P2, not the replay's go. P2's other confirmed cells (the eight merge producers, `felix_obligations_run`'s class read, `_gt_deploy_owed`) become red-on-main fixes of their own, each ordered against the audit batch that owns its file: `escape.sh`'s batch is a founder-stop batch (register line 225). They are not folded into step 1. **Before it opens:** CI is running (§5.5); 10 or fewer engine PRs are open (row 17); it does not collide with 0cw trust item 2, with the audit batch that owns `resolve.sh` (batch 12, register line 262), or with C060 (batch 19, register line 395). Rebase on `claude/audit-combined`, and drop anything the audit already fixes | 1-2. Estimated from slice 0's measured per-round cost under the cap: a build of about half a day, then P2's cells rerun under the harness 0b-i qualified, plus the capped review (about 5.4-7.8 h of serial agent time on slice 0's rounds) | engine: `resolve.sh`, `table.sh`; suite: red-first parts from P2's cells | Felix: a red-on-main fix through row 17's fix intake, owed by `lane-slice-review-budget.md`. It touches no obligations, class-table or detection code, and it lands on green as red-on-main fixes do if §13.2's reading of direction §5 holds. That passage holds "binding" code for a person, and whether this covers `resolve.sh`'s project binding is not settled. If it does, step 1 opens as a draft labelled `needs-founder`. It must also leave `table.sh` with at least as many lines matching the `count:` confine of its `verifier` row in projects/felix/risk.tsv. Otherwise that escape channel fires, which is a founder stop under direction row 4. Adversarial tier; every stage names its model and effort |
| 1b | **The kernel refactor, d5's way (decision 2).** **1b-a**, a trust-plane PR: blind properties, reference kernels, spec mutants (by an author blind to the properties), and the abstraction map with its concretisation, landed as report-only tests and shown red on main. **1b-b**, the shell and kernels change, judged by 1b-a as it landed, never by tests in the same PR (§4.8; amendments §2.3). Under decision 4 (decided 2026-10-31), 1b-a and 1b-b each open as a draft labelled `needs-founder` and wait for the founder's merge; 1b-a waits because, by Felix's reading of decision 4, it lands judge artifacts: the properties, reference kernels and abstraction map. Scope: the computed core closure (§4.7) | Not d5's 2-4 days. At slice 0's measured rate (the build wrote 447 changed engine lines in 2.9 h, and 21.5 h of checking took them to 746: about 24.4 h for about 750 lines), a refactor of 1,500-3,000 lines is on the order of 50-100 h under the old method. Re-estimated from step 2's measured rate before it starts | engine: `lib/kernel-*.sh`, the core closure; suite: `tests/kernel/`, `tests/refine` | placed by the founder on 2026-10-31, right after the audit's batches on its files, batch 20 among them, which waits on plan A (decision 2; direction §5); 1b-a and 1b-b wait for the founder's merge (decision 4; 1b-a by Felix's reading) |
| 2 | **The harness as suite-side tooling** (`tests/lib/fx*.sh`), promoted from 0b-i with its planted-defect controls passing, run in a lane session beside lane slice 1, on its frozen build-end tree, without delaying it: the slice lands under the capped review, which is the control. That is the prospective test (§9.4); if the harness has not qualified by slice 1's build end, it moves to the next lane slice or engine feature. Then the same on lane slice 2 or another engine feature | 2-3 per feature, plus the control | test-side | Felix: lane items under row 15, and the build method for lane slices is Felix's call. Not the audit batches (below) |
| 3 | After the audit, once the replay and the prospective tests on two features pass (decision 2): the case format, linter (against the default case), instantiator, per-claim receipts in the memory root by tree and plan hash, `felix case` report-only, and the `case` gate check report-only. Uses this design's bash 3.2 tracer, which plan A may consume, and shares plan A's function-extent parser (§7) and mutation step (step 8) | 6-10, my estimate (d3 sizes the enforcing version at about 2,400 lines built over several workflow sessions, and gives no day count). At slice 0's rate its checking alone could be two to three times that under the old method. Checked by the step-2 harness with its controls passing, plus the capped review; re-estimated after step 2 | engine: `lib/case.sh`, `lib/claim-receipt.sh` and the `felix case` subcommand, the part of d3's roughly 2,400 lines (d3 §16.2, at about 250-450 lines per library) that is not the harness; the harness libraries (`effect`, `sweep`, `oracle`, `gen`, `mutate`) arrive with step 4; six tables (below), with `schemas.tsv` rows | placed by the founder on 2026-10-31 beside plan A after the audit, once the replay and two prospective tests pass (decision 2); the direction §5 edit waits for the founder's merge |
| 4 | The harness moved into the engine and pinned to main's install; its first version qualifies on blind planted surfaces, transparency and the capped review, and self-application starts with its second version (§4.3 item 9); the `case` blocker in shadow (would-hold logged) on two new features built after the blocker exists | 4-6, plus shadow time | engine | placement as step 3; arming once that shadow meets bars fixed before it runs, and only while false blocks stay under a bound the founder sets from its data (decision 3) |
| 5 | Crash consistency at every state write, and the seeded turnstile, for the lander and the `.git/worktrees` race (gate-time note, B3 cut); awk monitors over `ledger.tsv`; standing claims on main, once the tracer works (§4.3 item 14); the nightly full sweep; a report of the existing suite's discrimination (mutation of main with the suite as killer), report-only | 5-8 | engine | placement as step 3 |
| 6 | Users' repositories at the process boundary, on two ecosystems (direction §3: "A design counts as progress once it has run unattended, once, on two ecosystems") | — | engine and capability plane | not placed |

**What changes in the engine** (steps 1, 1b and 3-5):
- New libraries:
  - `lib/kernel-*.sh`, `lib/case.sh` and `lib/claim-receipt.sh`;
  - `lib/effect.sh`, which is the shared preload and the bash 3.2 tracer;
  - `lib/sweep.sh`, `lib/oracle.sh`, `lib/gen.sh` and `lib/mutate.sh`.
- A `felix case` subcommand.
- `case` entries in `cmd_gate` and in `felix_merge_blockers` (`lib/escape.sh:605`).
- Six new tables in `templates/`, all joining `FELIX_ESCAPE_TABLES` so that removing a row, or changing one in place, escapes. Direction §5 says additions to the tables that decide whether a blocking class applies must also escape (under "Before row 27 arms anything"), so each table's columns are marked:

  | Table | Rows add | Additions |
  |---|---|---|
  | `claim-classes.tsv` | claims (a new class instantiates more) | free of escape; changing a class's "mandatory for" column in place escapes |
  | `faults.tsv` | fault kinds, so cells | free of escape |
  | `effects.tsv` (new, split out of `faults.tsv`) | a command word's effect class, which decides which kinds apply; one added row can move a word into a class with fewer kinds and remove cells | **escape** |
  | `bytes.tsv` | byte classes, so cells; and, in a separate column, witnessed "impossible" entries | classes free of escape; "impossible" entries **escape** |
  | `layouts.tsv` | layouts, so cells | free of escape |
  | `operators.tsv` | mutation operators, so mutants | free of escape |

  Free of escape is not free to land: until roadmap step 15 pins the judge outside every change it judges, every PR that changes one of these tables still waits for the founder's merge (decision 4; the four tables beyond the catalogue and fault model by Felix's reading, direction row 38).
- The `schemas.tsv` rows for the new tables are additions, and `lib/escape.sh` treats an addition to an escape table as free (direction row 26). A row changed in place fires (`table-column-is-a-founder-stop.md`). So adding them fires nothing. Adding the tables' names to `FELIX_ESCAPE_TABLES` is a change to `lib/escape.sh` that main's list cannot see, so that PR is held by hand (`new-escape-rows-invisible-to-their-own-pr.md`, in MEMORY.md).
- No new column on any existing table, and no new runtime on the enforcing path.

**What changes in the build method.**
- For lane slices and new engine features, the ultracode pipeline (spec, then blind assertions from the spec alone, then the implementation shown red first, then adversarial reviewers, then fixes, then the gate; `engine-builds-use-ultracode.md`) becomes §4.9's S0-S12 once step 2 shows it meets §9.4's bars.
- Blind assertions become a blind case.
- Review rounds become the bounded evidence-fix loop plus at most two case-attack rounds and one simpler lens.
- Findings go back to the blind author as rows.
- Fixes take whole clusters.
- Every stage still names its model and effort (row 17).
- **The audit batches are exempt.** Direction row 29 is a founder decision that each batch is built "with a contract, blind tests, red first, the fix, an adversarial review, and a second round when the review finds a major". Replacing that adversarial review would need the founder's decision, which this design does not ask for.
- The 10-30 review budget stays in force for any slice not built this way.

**What changes in the docs.**
- This design is filed in `docs/` as a design on file. Merging the document itself is on green, since among documents only direction waits (direction row 11). Listing it in direction §7, placing step 1b and steps 3-5 in §5, decision 1's edit to direction §1, and the seven answers as direction rows 36-40 (which amend rows 4, 24 and 27) are direction edits. The founder decided their substance on 2026-10-31, and the edits wait for the founder's merge of one direction PR (direction §10).
- `engine-builds-use-ultracode.md` is updated after step 2 measures.
- A "not built" line goes in the README's Status (`readme-not-built-lives-in-status`, MEMORY.md).
- A claim-class catalogue page.
- A v3.2 mapping section, covering obligations, evidence contracts, receipts and the residual. That mapping is g5 §6's.

**Order against direction §5.** The main sequence is the audit batches, then plan A, then leftovers, then the trust track, whose first item is 0cw trust item 2 (merge refuses a receipt that skipped checks), which "starts once 10 or fewer engine PRs are open" (direction §5, main sequence item 4). "A design on file is never placed by itself" (direction §10). So:
- steps 0a, 0b and 0c are measurements and consume no placement;
- step 1 is the narrow fix `lane-slice-review-budget.md` already owes, and enters through row 17's fix intake as a red-on-main fix, only while 10 or fewer engine PRs are open and after checking where trust item 2, the audit's `resolve.sh` batch (12) and C060's batch (19) stand;
- step 2 is the build method on lane items, which row 15 lets Felix place;
- step 1b, the kernel refactor, is a new architecture across the core, not the owed fix, so it needed placement: the founder placed it on 2026-10-31, right after the audit's batches on its files, batch 20 among them, which waits on plan A (decision 2; direction §5);
- steps 3-5 are placed beside plan A after the audit, once the replay and two prospective tests pass, and step 6 waits for placement.

I did not count the open engine PRs, or read whether trust item 2 has landed.

---

## 11. Decisions

### 11.1 The founder's: escapes, identity, priority

Each comes with my recommendation. The founder answered all seven on 2026-10-31, in eight questions (decision 7's two halves were asked apart), and each answer follows its item.

1. **Identity: what the trust plane claims.** The founder said "We are essentially verifying that it works." The honest form is "checked within a stated fault model, over a printed denominator, with the evidence shown able to fail and the residual listed". Kernelised decision logic is "checked exhaustively over its stated domain". "Verified" and "proven" are never used. *Recommend:* adopt it for receipts, pitches and applications. That also keeps direction row 17's rule of no "independent acceptance" claims before #350 and the pin. **Adopting it changes texts that are the founder's:** direction §1, "Felix turns intent into verified, shipped code", which is a direction edit and waits for the founder's yes; the positioning number, which the 10-29 option text gave as "verified work per hour of your attention"; and the official pitch of 10-27 with its ten-sheet deck (`felix-official-pitch.md`), which every later pitch starts from. I did not check the pitch and deck files for the word. **Decided 2026-10-31: as recommended,** in every text. Decision 1 made the positioning number "checked work per hour of human attention" (direction row 36). Until the evidence engine exists, a text says what ran, such as the gate and its suite, and names no fault list or case count Felix does not have; that interim reading is Felix's (direction row 36). The direction §1 edit waits for the founder's merge, and the pitch and deck are owed their rewording.
2. **Priority: placement.** Step 1b (the kernel refactor of the trust core) and steps 3-6 need a slot in direction §5, and the design needs a line in §7. *Recommend:* place 1b right after the audit's `resolve.sh`, `escape.sh` and `obligations.sh` batches land, because it rewrites their files; place steps 3-5 beside plan A, after the audit batches. They share plan A's extent parser, mutation step and slots, and plan A can take this design's bash 3.2 tracer instead of building its own. Placement of steps 3-5 waits on the replay and two prospective tests passing. **Decided 2026-10-31: as recommended.** Batch 20, the audit's `obligations.sh` batch, has no build yet and waits on plan A (direction §5 does not say for which of plan A's steps), so 1b waits for batch 20 to land, and through it for as much of plan A as batch 20 needs. Step 6 is not placed.
3. **Escape: arming the `case` blocker** in `felix merge` for B3 and higher surfaces, after the shadow on two features. How much Felix may block is the founder's decision (`lib/qualify.sh` header, via d1 §14). *Recommend:* arm it if the shadow's false-block rate stays under a bound the founder sets, and only after §9.4's bars hold on two features. **Decided 2026-10-31: as recommended.** By Felix's reading of "trials", the shadow runs on two new features built after the blocker exists, not on step 2's two, and must meet bars fixed before it runs ("Once those meet bars fixed before they ran"); the blocker then holds only while false blocks stay under the bound the founder sets from the shadow's measured false-block rate. The bars are written down before the shadow starts; this design does not set them yet. If false blocks go over the bound, the blocker stops holding and returns to shadow until the founder sets a bound again; that mechanism is Felix's reading of the option's "as long as".
4. **Escape: holding the checker's judge PRs for a person.** These are PRs that change the claim catalogue, the fault model, the oracle kernel, the case evaluator or a decision kernel, when they would otherwise land on green. This is a further amendment of row 24. Direction §5 treats the like amendment, for class-table, derivation, binding, detection and obligations code, as "the founder's decision, asked when the build reaches it" (under "Before row 27 arms anything"). Step 1b-b is that moment, so it is asked before 1b-b opens, and 1b-b waits as a draft labelled `needs-founder`. *Recommend:* hold them for a person until roadmap step 15's pin covers this checker. After that, land on green with removal-escape on the tables and the widening check on kernels. **Decided 2026-10-31: as recommended,** on the end condition in the option the founder chose: PRs that change the checker's claim catalogue, fault model, oracle, case evaluator and decision kernels, and, by Felix's reading of the question's "the code that computes a verdict", the reference kernels, properties and abstraction map (with its concretisation) that judge them, and the tables that make its cells and mutants (`effects.tsv`, `bytes.tsv`, `layouts.tsv`, `operators.tsv`; §10), wait for the founder's merge until roadmap step 15 pins the judge outside every change it judges. So step 1b-a waits as well as 1b-b.
5. **Escape: narrowings no mechanism can witness, at every budget class.** §4.8 counts narrowing from the default case, so a relaxation the blind author declares before freeze counts as one made after it. A narrowing with a mechanical witness clears itself. One without a witness leaves its claims UNKNOWN until a person clears it, or until a trust-plane PR changes a landed table in a new epoch. The lead's record clears nothing, because that would be the session granting itself an exception (amendments §3). On d3's reading of slice 0, that is one or two stops per slice-0-sized feature at B3, for example F9's sentinel limit, and more once B2's relaxations count. *Recommend:* yes. Count them, and revisit if the first two features average more than two. **Decided 2026-10-31, differently: only at B3 and above.** There a narrowing without a witness holds its change for the founder, as above. At B0-B2 it does not hold: the change may land with the narrowed claims UNKNOWN in its receipt and its residual, and no one is asked to clear them, so no claim reads as checked that was not (§4.8). The founder's choice gives up a person's look at low-stakes narrowings in exchange for fewer stops. The count of stops at B3 and above is still kept. Felix's own rule, not part of the founder's choice: it asks again if these stops average more than two a feature over the first two features. By Felix's reading, since the option names no start, these stops bind from 2026-10-31, by hand until the `case` evidence exists: a B3-and-above build's stated limit goes to the founder as a pull request opened as a draft labelled `needs-founder` (direction row 39).
6. **Escape: retiring hand-written assertions by mutation subsumption.** A part may be retired when every mutant it kills is also killed by the evidence. Retirement fires the `risk.tsv` verifier channel. Letting subsumption evidence clear that channel would change what a stop means. *Recommend:* not yet. Each retirement stays a hand merge until two features' shadow data exist. d2 recommended yes now, and I do not, because no one has measured coupling. **Decided 2026-10-31: as recommended,** on the trigger in the option the founder chose: each retirement waits for the founder's merge until two features' trial data show that planted faults stand in for real bugs, and it is asked again then. §9.4's trials do not measure that yet; the measurement is owed before the question can come back.
7. **Admission: claim classes as RELEASE_BLOCKING, and inherited base defects.** The classes are FAILCLOSED, WRITESET, OFFLINE and BASEEQUIV on hook-reached surfaces. Admission is the founder's act (direction §3, loop 2). The same act covers letting a new B3 surface inherit a base defect in shared code (R-base, §4.8), which otherwise holds the change. *Recommend:* admit the classes after the shadow, under the rest of row 27's bounds: witness-backed, qualified on seeded mutations, nothing armed before control 7 and the judge pin, and visibly Felix's. Row 27's first bound ("task scope only, never a release") cannot hold for a RELEASE_BLOCKING class, so release scope is the founder's to grant in this admission. An exception may never clear a RELEASE_BLOCKING obligation (amendments §3), so a false block in these classes is cleared by the founder's policy decision, not by row 27's dated exception. Admit inheritances one shared function at a time, each with its filed candidate obligation. **Decided 2026-10-31: as recommended, both halves.** The four classes are admitted after the shadow, with release scope, under row 27's other bounds, and inheritances one shared function at a time: each acceptance turns the defect's candidate obligation into an obligation to fix, and later features on that function do not ask again. By Felix's reading, since the option names no start, the second half binds from 2026-10-31, by hand until the `case` evidence exists: a new B3-and-above feature's inherited shared-code defect goes to the founder as a pull request opened as a draft labelled `needs-founder` (direction row 40).

### 11.2 Decided here, with the reason

| # | Decision | Reason |
|---|---|---|
| 1 | The spine is d3 | It fits v3.2's objects best (admission pathways, ledger, Evidence Kernel, task scope, row 21's staleness) and gives the clearest product. The judges' unfiled verdicts split two to one for it; the choice stands on the fit, not the vote |
| 2 | One oracle in two forms: d1's schema information order for readers, d2's safety order for deciders | ⊑ is finer than "clean or an UNKNOWN form" and is the rule `cls_lane_tsv` already used. The safety order covers `felix merge`, the Stop hook's recorded fail-open and the receipt readers |
| 3 | A model's equivalence claim never unblocks. Indistinguishable mutants are capped and cleared only by a distinguishing input | v3.2 invariant 1. It also detects generator holes mechanically |
| 4 | No lineage pruning of value faults | A failed effect can matter through its status, or end the shell, where its output never reaches the answer |
| 5 | Cell reuse and reach both use §4.8's function-level fingerprint; until step 0a shows function entry and command resolution can be traced, every rerun is full; equivalence collapse only as a labelled sample | Stack-only fingerprints, for reuse (d2) or for reach (d1), miss state set earlier off the stack. The sound version needs function-entry tracing, which is unverified |
| 6 | The owed fix first and narrow (step 1); the trust core's kernel refactor, d5's way, next, placed by decision 2 to start once the audit's fixes to its files land (step 1b) | §1.4: the trust plane cannot be sold while the merge decision may read "printed nothing" as "nothing blocks". The owed PR is narrower than the refactor, and a new architecture is not placed by itself (direction §10) |
| 7 | No TLA+ or Java now. Protocols get crash consistency, the turnstile and awk ledger monitors in bash | Models write TLA+ poorly (8.6%). It is a new runtime in CI. Once built (step 1b), the kernels cover the decision logic exhaustively |
| 8 | Every fault kind names a real-world origin, or runs in shadow | Guards against false blocks from faults that cannot happen |
| 9 | Environment and config domains are probed from git | R2B-F3 escaped a hand-written list |
| 10 | Commit-reveal of at least two held sets and two salts, a fresh one revealed for the final run; held cells shown to the builder by class only | Makes one slice of blindness checkable, against an overfitting builder, across the whole fix loop and not only its first run |
| 11 | A positive control on every sweep; spot replay at merge of every earlier failure plus k = 5 cells per claim, seeded from main's tip at merge and the CI run id; the detection probability printed | Constitution invariant 5. A cheap consumer-side check of an expensive producer-side search, with a seed the producer cannot grind |
| 12 | R-base is mechanical, by differential against an analogue the engine derives, always filed as a witness-backed candidate, and on a new B3 surface it holds unless the project's owner (on Felix, the founder) admitted the inheritance | Turns the lead's round-3 hand call into a rule without silently accepting base's defects, and without the lead choosing which analogue decides a cell |
| 13 | CI runs the full suite plus a sample of cells seeded from its run id. The full sweep runs locally under the pinned judge and nightly. Receipts say CI's check is sampled | GitHub Free's 2 cores, and minutes that cost money (nonzero budget since 10-01). Row 30 keeps the suite full in CI |
| 14 | No catch or latency figure from this document goes into outside text before §9's replay and the prospective tests | The figures are hand mappings and unmeasured constants; the judges' verdicts said the same |
| 15 | Budget classes are computed from paths, reach and `risk.tsv`. Models may only raise them. B0-B1 get the default case | v3.2 §10 and I4: assurance set by consequence |
| 16 | Model finders run only as replay arm C, not by default | Their yield on slice 0 is probably small (d4 §13), and agent-minutes stay near today's (d4 §11.1: about 800 against 1,156) |
| 17 | The primitive is mandatory in the core closure (§4.7) and in new B3 feature files; other code migrates when touched | Soundness of P1 as a class, and part of the cell reduction at 10x (about 230,000 to about 170,000 runs, §5.4); §5.4 counts what it does not reach |
| 18 | The build-method change applies to lane slices only after the prospective tests meet §9.4's bars; the audit batches keep row 29's method; otherwise the 10-30 budget stands | The build method for lane slices is Felix's call, and it should be earned. Row 29's method is a founder decision |
| 19 | The replay runs only in a scratch clone, under the Mac-wide 4-slot semaphore, measuring CPU by getrusage, in three parts with compute budgeted | The lane-counter worktree is live, and parallel builders overloaded the Mac on 10-25 |
| 20 | Fault cells sit on discriminating layouts, checked by a default probe, with a pairwise array over resolution, tie and nesting | On the first layout that reaches a read, the clean value is often the default a defect produces, and O1 then passes a broken read |
| 21 | Every authored relaxation is a narrowing from freeze zero, and a narrowing clears only by a mechanical witness or, at B3 and above, the project's owner (on Felix, the founder); at B0-B2 one without a witness lands UNKNOWN and no one is asked to clear it (decision 5) | Constitution invariant 2, v3.2 invariants 1 and 2, amendments §1.3 and §3: no model text, before or after freeze, turns unknown into pass |
| 22 | The case attack is bounded at two rounds; at the bound, open rows leave claims UNKNOWN and ESCALATE | An unbounded "attack until nothing is found" is the old loop moved onto the case |
| 23 | A stale standing claim at B3 or above holds the PR that staled it until re-earned; below B3 the nightly re-earns it and the receipt says "stale, not re-earned" | A PR must not break another feature's B3 claims unseen. Below B3, CI-on-main strength is accepted and stated |
| 24 | The bash 3.2 tracer is this design's deliverable; plan A may consume it | Plan A builds the Linux tracer first and the bash 3.2 one only if a traced run fits a night (`docs/2026-10-24-reach-checks-design.md:244`); this design needs it on the enforcing platform |

---

## 12. Alternatives considered, and why not

| Alternative | What it offered | Why it is not the spine |
|---|---|---|
| **d1, the invariant compiler** (one judge's winner) | The most careful soundness discipline. The schema-derived oracle. A compiler that refuses uncovered classes. The best replay protocol | Its strongest parts are grafted whole. As the spine, it is less native to v3.2's objects and states 10x times that assume 16 slots. Its first-reaching-layout placement and its stack-keyed reach are replaced (§4.1). Its cell counts (about 25,000 for slice 0, about 250,000 at 10x) turn out close to this design's corrected ones (§5.2, §5.4), so cell count is no longer a reason against it |
| **d2, the simulation substrate** | Deterministic simulation discipline. The safety order. Crash consistency and interleavings. The most honest reach table | One very large verifier leaning hardest on the unrun DEBUG tier. Per-cell reuse was unsound as written. Its best parts are grafted |
| **d4, adequacy search** | Mutation as a measure. Coupling measured on Felix's own faults. A finder market on a deterministic scoreboard | Mutation cannot see omissions, and slice 0's dominant defect was missing handling. By its own §13 it adds little detection over the sweep, and agent-minutes stay near today's. Lineage pruning is unsound. It is used as the discrimination layer |
| **d5, proof where it pays** | The highest assurance on the core. The refinement oracle that does not trust the clean run. The widening check | Users must refactor decision logic into pure kernels. TLA+ is weak when models write it, and it adds Java. Features fall back to an underspecified tier. It is taken as the trust core's design and the first engine target |
| **Keep the review loop under the 10-30 cap** | No new machinery. It is bounded: about 5.4-7.8 h of serial agent time on slice 0 (§1.1), likely less than this method's central 9 h, and bounded at 10x too | It is the policy in force and the control in §9.4. It bounds cost by giving up coverage: no denominator, no fault model, no evidence its checks can fail, and no stop rule other than a count. Fault classes its three rounds do not reach go unfound, and those in shared code are routed to the trust plane instead of being fixed in the slice. A fix regression outside its rounds is not found before landing. **This design does not beat it on time at central constants.** It is chosen for strength, and is faster only if its levers measure well, which §9.4's time bar tests against this control |
| **Plan A alone** | It cuts which tests run, and it is placed | It does not change how tests are produced or whether they discriminate (g1 gap 4). This design shares its extent parser and mutation step, and offers it the bash 3.2 tracer |
| **More model reviewers, panels or debate** | Familiar | Correlated errors, debate's poor replication, and Felix's 41 agents for one surviving finding (§3.2) |
| **An outside fault-search service as the verifier** | Deep, mature fault search | Not offline, not bash and git, and not on macOS for the engine. It cannot sit on the enforcing path. It is accepted later as an evidence provider |
| **Proof assistants for the engine** | Machine-checked proofs | The research found no verifier for bash 3.2 programs (g5 §3.2). Smoosh covers POSIX sh, not bash (g5 §3.2). A proof assistant would fit only narrow, separable pieces, and the kernels' exhaustive check already covers every vector of their finite domains |
| **Hypothesis or Python as the harness** | Mature generators and shrinking | Another runtime is allowed only as a suite-side or CI-only cross-check, recorded as skipped where absent (`docs/2026-09-19-direction-decisions.md` §1, via g1 §4). What decides must give the same verdict on every machine. A seeded bash and awk generator suffices for byte classes. Python tools remain providers for users |

---

## 13. Risks and open questions

### 13.1 Risks

1. **The DEBUG tier may not work, may be slow, or may model the wrong fault.** Builtin and redirection sites (R2B-F2, part of R2B-F5) then fall to function overrides and whole-process faults (`ulimit`, TMPDIR, `/dev/full`). What is lost goes to the residual. If a skipped command leaves status 0, a skip models a fault that does not happen and makes guarded code look fail-open; the substitute is a trap that ends the substitution's subshell with a nonzero status. If function entry cannot be traced, there is no sound reach or reuse, and every rerun stays full. Step 0a decides all three in an hour or two.
2. **The layer may change what it observes.**
   - Exported functions show in `type`.
   - Stacks get deeper.
   - The layer's own descriptors and forks shift the EMFILE and fork-limit thresholds.

   The transparency check guards against this, but a perturbation it cannot see would bias every verdict.
3. **False positives can replace review cost with triage cost.** Clustering, R-base and the origin rule absorb some of it. The replay measures the rest.
4. **Authoring may absorb the saving.** If writing the case is as slow as the review chains were, the speed is lost. The replay times it (bar ≤ 1.5 h).
5. **"Always unknown."** A surface that is unhelpfully cautious can pass O1. O5's output-class coverage, the reference model and the cause map limit this. The cost is that some honest cautious surfaces may be flagged.
6. **Overfitting.** "For any fixed testing strategy, a sufficiently adversarial system can overfit to it" (de Moura). Held fixtures, the revealed salt and a lint against code that probes for shims reduce this. They do not remove it.
7. **The harness becomes the largest single verifier.** One wrong comparison in O1 passes every cell, and one wrong comparison in the replay harness moves recall or false positives across the 80% and 25% bars in either direction. The replay harness alone is expected to run to several thousand lines. Each version has to qualify itself on planted defects an author blind to it wrote, plus transparency, and, from its second pinned version, self-application; the first pinned version has no base harness and leans on the step-2 harness and the capped review. It must stay small (v3.2 §12's root trust base).
8. **Cost at scale.** The 4-slot cap binds at 10x, and CI minutes cost money. Sweeps compete with builders for the Mac. Every receipt must say when a sample shrank.
9. **Founder stops.** Narrowings no mechanism can witness (at B3 and above; below B3 they land UNKNOWN, decision 5), attack-bound escalations, R-base inheritances on new B3 surfaces, widening holds and kernel-PR holds all spend the founder's interruptions, and founder interruptions per session is the binding objective (direction §3). §5.4 expects on the order of 10-30 for one 10x feature. They are counted and reported, and §9.4 records them per feature.
10. **R-base ships known defects below B3.** They are not worse than base, and they are printed and filed. A user can still hit one. On a new B3 surface they hold unless the founder admits the inheritance.
11. **Refactoring the enforcing core is the adversarial tier** (step 1b). The new kernel must equal main's behaviour on every vector without ⊥, and differ only toward UNKNOWN. That is the widening check applied to the refactor itself, and it is only as good as the abstraction map and its concretisation, which are judge artifacts written blind.
12. **Platform drift.** macOS runs bash 3.2 with BWK awk, and CI on ubuntu-latest runs gawk (`ci-awk-is-gawk-local-is-bwk`, by its MEMORY.md line), so the two give different cells. Receipts are per arm, and an arm not run is listed.
13. **Direction order.** The audit batches and plan A come first. Decision 2 placed step 1b after the audit's fixes to its files, and steps 3-5 beside plan A after the audit, once the replay and two prospective tests pass; step 6 is not placed. Building any of them sooner risks waste and collides with the audit's files. Steps 0a-0c and the narrow step 1 do not, provided step 1 is checked against the audit's batches 12 (`resolve.sh`) and 19 (C060) first.
14. **Words.** Outside text drifts toward "verified" (`plain-language-drifts-into-overclaim`, MEMORY.md). The receipt's word rule must hold in pitches too.
15. **The speed case may not come.** At central constants the method is slower than the capped loop on slice 0 (§5.3), and about four times the build at 10x (§5.4). If the fork-server and the tracer measure poorly, the method is a purchase of strength at a higher time cost than the policy in force, and the founder asked for both. §9.4's time bar tests this on a real feature before anything arms.
16. **Standing claims grow with the engine.** A PR that changes a function every surface enters re-earns every B3 standing claim; after ten slice-0-sized features that is on the order of 100,000 runs (§4.3 item 14). If that is too slow, the choice is between holding such PRs for hours and accepting CI-on-main strength at B3, which this design does not accept.
17. **Spot replay is weak against one careful edit.** Under 2% for a single flipped cell (§4.8). Replaying every earlier failure covers the likeliest forgery; nothing here stops a same-user process.
18. **The judge pin inherits what is left of audit C063's race** after audit batch 13, on the in-place path and in the copy, until roadmap step 15 closes it (§4.8).
19. **Mutation survivors dominate at 10x.** At B3 each survivor costs its whole domain; §5.4 puts discrimination at about 9.7 h central and up to about 24 h.

### 13.2 Open questions, each answered by a named run or read

- **What are t (with the layer, oracle and fixture clone), S, K̄, L_d, the start-up share of t and real slot capacity** on the 48 GB Mac? Answered by step 0b-i. Until then every cost the design predicts in §5 is an estimate. The only measured per-run cost is `g2/measure.txt`'s bare-run figure. The old loop's times and the gate and CI times are measured.
- **Does `extdebug`'s skip work on `/bin/bash` 3.2, what status does a skipped command leave, and can function entry and command resolution be traced, at what cost?** Do exported functions shadow every builtin the engine uses? Do `/bin/sh` children import them? Answered by step 0a. The man page does not say what status a skip leaves (lines 4344-4362).
- **Does `felix_capture` carry a value ending in LF?** My reading of `lib/detect.sh:202-212` says yes when the command prints its own newline after the value, and no when it does not. Not run.
- **Do the eight producer pipelines of §1.4 fail open?** My reading: `krc` is the status of `felix_merge_blockers`' last statement, so their statuses never reach it, and on the non-self-governed path no status is read. Not run. Answered by P2, on main and on `claude/audit-combined`.
- **Does `felix merge`'s judge check close `_gt_deploy_owed`'s fail-open a second time?** Answered by P2.
- **Is GIT_GRAFT_FILE in `git rev-parse --local-env-vars`?** d4 reports yes. I did not run it.
- **Does adding rows to `schemas.tsv` fire an escape?** Settled by reading: no. `lib/escape.sh` treats an addition as free (direction row 26), and only a row changed in place fires (`table-column-is-a-founder-stop.md`). Adding names to `FELIX_ESCAPE_TABLES` is held by hand, because main's list cannot see them (§10).
- **Does direction §5's held-for-a-person rule for "binding" code cover `resolve.sh`'s project binding?** I read the passage (direction §5, under "Before row 27 arms anything") as the obligation track's derivation and binding, so step 1, which only fails closed, lands on green. If it covers project binding, step 1 opens as a draft labelled `needs-founder`. Not settled.
- **Which audit fixes have landed, and does C060's fix already cover the resolver and validator reads?** Not read past the register and the `--stat` of `claude/audit-combined`. Read before step 1 opens.
- **How many engine PRs are open, and where does 0cw trust item 2 stand?** Not checked. Read before step 1 opens.
- **Is CI running today?** The memory note records it running again on 10-30; I did not check. If it is down for billing, as the 10-25 outage most likely was (its cause was never confirmed), fixing it is a founder act, and it gates step 1's landing and the prospective tests.
- **Is the audit register's batch fit to be a holdout?** Chosen after reading the register (step 0b-iii). The register's own reproduction fixtures may make some batches unfit.
- **How fast is `cp -c` cloning per cell?** And how much would a fork-server gain? Both are measured in step 0b-i.
- **How large are the four-state kernel domains?** d5's figures are three-valued; recomputed in step 1b-a.
- **What does the capped control cost in wall time on a real feature?** Measured by §9.4.
- **Which model family did each workflow stage run on?** The files do not say.

### 13.3 What this revision could not settle, or did not do

- **The judges' verdicts are not filed.** A critic asked that they be filed and cited. Their text was in an earlier stage's task text, which this stage did not have, and this stage may write only this file. So the revision removed the vote as a reason for any decision and marked every judge-credited claim as not checkable from a file. The log a judge read is cited by its absolute path (§5.2).
- **The workflow's inputs were copied out of `/private/tmp` after this stage,** on 2026-10-31, when the design was filed: to the memory root's `audits/2026-10-30-trust-plane-design/` (§9). This stage could write only this file.
- The PDF is built from this file.
- **The cost figures are rebuilt, not measured.** The revision raised slice 0's central estimate from about 4-5 h to about 9 h and the 10x estimate from about 17 h to about 47 h of checking. Both rest on a measured bare-run time and unmeasured S, K̄, L_d and layer overhead. The direction of the correction is clear; its size is not.
- **The capped loop's cost on slice 0 is itself an estimate,** from g2 §3's per-round agent-minutes, before gaps between stages; the cap was never run on slice 0.
- **The time zone of the local times d1, d2, d4 and g3 give** (used for the 10-29 22:34 cutoff, the spec commit's time, given here as 2026-10-30T05:34Z) was not confirmed. With Felix notes left out of FM-0's inputs, the cutoff matters only for dating the census commit, which precedes it either way.
- **Two critic fixes were taken in part.** §9.4's gating time bar is ≤ 1.0x the control rather than the suggested 0.5x, because every column of §5.3 fails 0.5x, and the central estimate fails 1.0x as well; 0.5x is reported as the target. And the function-level fingerprint does not trace global reads, which bash 3.2 cannot do cheaply; it fingerprints top-level statements and command resolution instead, with the soundness argument in §4.8. One critic count was not taken: the base differential adds one base run per cell, not two runs, because the head side is the depth-1 cell already counted (§5.2).

---

## Sources

### Felix files read for this document

- Workflow directory, as defined at the top: g1-g6 and d1-d5, read in full; `g2/measure.txt`. The three judges' verdicts were in an earlier stage's task text and are not filed.
- `~/.felix/memory/felix/audits/2026-10-30-trust-plane-design/lane-build/review2-ulimit.c.log` (651 lines, by `wc -l`; its first rows) and `review2-ulimit.sh` (file times only).
- `/Users/a14808/Documents/UC Berkeley/Career/Founder OS/felix_v32_architecture_spec.md`: lines 11-20, 180-192, 267-280, 387-396, 432, 456, 459, 492.
- `/Users/a14808/Documents/UC Berkeley/Career/Founder OS/felix_v32_conformance_amendments.md`: lines 43, 80-86, 134-146, 153, 170-180, 198-208, 225-238.
- `/Users/a14808/Documents/Felix/projects/felix/CLAUDE.md`: lines 85-115 (invariants 1-3).
- `/Users/a14808/Documents/Felix/docs/direction.md`: §1's opening, §3, §4 rows 1-33, §5 (its opening, the main sequence to the trust track, and the list under "Before row 27 arms anything"), the end of §6's decisions, and §10.
- `/Users/a14808/Documents/Felix/docs/2026-10-24-audit-register.md`: lines 1-30, 70, 225, 257, 262, 284-294, 388-401, 458, 473.
- `/Users/a14808/Documents/Felix/docs/2026-10-24-reach-checks-design.md`: lines 238-250.
- `/Users/a14808/Documents/Felix/engine/.claude-plugin/plugin.json`: version 0.49.317; main at `cc238b25` (`.git/refs/heads/main`).
- `/Users/a14808/Documents/Felix/engine/harness/lib/escape.sh`: lines 30-60 and 600-798.
- `/Users/a14808/Documents/Felix/engine/harness/lib/obligations.sh`: lines 192-200 and 242-250.
- `/Users/a14808/Documents/Felix/engine/harness/lib/verify.sh`: lines 481-483 and 546-560.
- `/Users/a14808/Documents/Felix/engine/harness/lib/commission.sh`: lines 30-48.
- `/Users/a14808/Documents/Felix/engine/harness/hooks/stop`: lines 168-182.
- `/Users/a14808/Documents/Felix/engine/harness/felix`: lines 1715-1740 and 1905-1945, and `grep -n` for the blocker capture, `krc` and `set -uo pipefail`.
- `wc -l` and `grep -o '\$('` counts on main for `resolve`, `escape`, `verify`, `green-tick`, `obligations`, `receipt`, `table`, `review`, `classify`, `evidence`, `probes`, `commission`, `land-table`, `detect`, `bootstrap`, `say`, `epoch`, `exceptions`, `stack` and `final-filter`; `grep` of the `.` lines in `escape.sh`, `probes.sh`, `commission.sh`, `land-table.sh`, `evidence.sh`, `verify.sh`, `obligations.sh`, `stack.sh`, `final-filter.sh` and `classify.sh`; `grep` for `FELIX_*NOW` in `felix`, `lib` and `hooks`.
- `git merge-base origin/main 3f893610` (`c170ed5f`); `git diff --stat` of `claude/audit-combined` (`ffb46bbb`) and `origin/claude/audit-combined` (`c665e021`) against main, for the trust-core files; the hunk headers of the former's `green-tick.sh` diff.
- The bash 3.2 man page on this Mac (`man -P cat bash`), lines 4344-4362.
- `/Users/a14808/Documents/Felix/engine/harness/lib/green-tick.sh`: lines 120-130 and 344-352.
- `/Users/a14808/Documents/Felix/engine/harness/lib/table.sh`: lines 150-156 and 186-192.
- `/Users/a14808/Documents/Felix/engine/harness/lib/detect.sh`: lines 198-215.
- The seven core files, by `grep -c` for `felix_capture` and `$(`: `lib/resolve.sh`, `table.sh`, `obligations.sh`, `escape.sh`, `green-tick.sh`, `receipt.sh` and `verify.sh`.
- `grep` for DEBUG traps in `lib`, `felix` and `hooks`. The only hit is a comment in `lib/where-read.sh:939`.
- Memory notes in `/Users/a14808/.claude/projects/-Users-a14808-Documents-Felix/memory/`:
  - `lane-slice-review-budget.md`
  - `parallel-builders-oversubscribe-the-mac.md`
  - `design-questions-are-felix-not-founder.md`
  - `engine-builds-use-ultracode.md`
  - `table-column-is-a-founder-stop.md`
  - `gate-time-measured-2026-10-10.md` (lines 3, 10 and 27)
  - `felix-is-the-independent-manager.md` (line 25)
  - `actions-minutes-quota-binds.md` (in full, modified 2026-10-30T11:12Z)
  - `felix-official-pitch.md` (lines 3-15)
  - `printf-grep-q-races-under-pipefail.md` and `sandboxed-suite-traps.md` (their `modified` fields only)
  - `new-escape-rows-invisible-to-their-own-pr.md`, `ci-awk-is-gawk-local-is-bwk.md`, `plain-language-drifts-into-overclaim.md`, `measure-cpu-not-wall-under-load.md` and `readme-not-built-lives-in-status.md`, by their MEMORY.md lines only
- `~/.felix/memory/felix/audits/2026-10-30-trust-plane-design/lane-build/`: the five generic reviewer scripts, by `wc -l` (548 lines in all).

Claims attributed to g1-g6 or d1-d5 rest on the files those stages name, which are listed in their own Sources sections.

### World sources

None was re-read here. Each comes through the research or design stage named, and most of those stages read abstracts or summaries rather than full papers.

- **Deterministic simulation and fault injection.** All via g3.
  - FoundationDB testing: https://apple.github.io/foundationdb/testing.html
  - BUGGIFY: https://transactional.blog/simulation/buggify
  - TigerBeetle safety: https://docs.tigerbeetle.com/concepts/safety/
  - TigerBeetle, protocol-aware DST, 2026-08-20: https://tigerbeetle.com/blog/2026-08-20-protocol-aware-dst
  - Dropbox, testing sync: https://dropbox.tech/infrastructure/-testing-our-new-sync-engine
  - Antithesis assertions: https://antithesis.com/docs/properties_assertions/assertions/
  - Antithesis FAQ (via g5): https://antithesis.com/docs/faq/customer_faq/
  - Eaton, the limits of DST: https://notes.eatonphil.com/2024-08-20-deterministic-simulation-testing.html
  - SQLite testing: https://www.sqlite.org/testing.html
  - LFI: https://dslab.epfl.ch/research/lfi
  - strace(1): https://man7.org/linux/man-pages/man1/strace.1.html
  - FATE and DESTINI: https://usenix.org/conference/nsdi11/fate-and-destini-framework-cloud-recovery-testing
  - Yuan et al., OSDI 2014: https://usenix.org/conference/osdi14/technical-sessions/presentation/yuan
  - ALICE: https://www.usenix.org/node/186195
  - CrashMonkey: https://arxiv.org/abs/1810.02904
  - NIST combinatorial testing: https://csrc.nist.gov/files/pubs/shared/itlb/itlbul2016-05.pdf
  - CHESS: https://static.usenix.org/events/osdi08/tech/full_papers/musuvathi/musuvathi_html/index.html
  - Swarm testing: https://www.cefns.nau.edu/~adg326/issta12.pdf
  - LDFI: https://doi.org/10.1145/2723372.2723711
- **Generated tests, mutation and independence.** All via g4.
  - Google, mutation testing at scale: https://ar5iv.labs.arxiv.org/html/2102.11378
  - Meta ACH: https://arxiv.org/html/2501.12862v1
  - Meta, diff-time catching tests: https://arxiv.org/abs/2601.22832
  - Just et al., FSE 2014: https://homes.cs.washington.edu/~mernst/pubs/mutation-effectiveness-fse2014-abstract.html
  - PatchDiff: https://arxiv.org/abs/2503.15223
  - Csmith: https://www-old.cs.utah.edu/~regehr/papers/pldi11-preprint.pdf
  - Knight and Leveson: https://www.kth.se/social/files/564df871f2765419e306178d/KnightLeveson.pdf
  - Kim et al., correlated errors: https://arxiv.org/abs/2506.07962
  - Inozemtseva and Holmes: https://cs.ubc.ca/~rtholmes/papers/icse_2014_inozemtseva.pdf
  - Konstantinou et al.: https://arxiv.org/abs/2410.21136
  - ImpossibleBench: https://arxiv.org/abs/2510.20270
  - ShellCheck SC2155: https://www.shellcheck.net/wiki/SC2155
  - Anthropic, property-based testing: https://www.anthropic.com/research/property-based-testing
- **Specification, formal methods, assurance and market.** All via g5.
  - Kiro GA: https://kiro.dev/blog/general-availability/
  - Anthropic and Theorem, 2026-10-22: https://www.anthropic.com/research/formal-verification
  - de Moura: https://leodemoura.github.io/blog/2026-2-28-when-ai-writes-the-worlds-software-who-verifies-it/
  - Kleppmann: https://martin.kleppmann.com/2025/12/08/ai-formal-verification.html
  - TLA+ with models: https://ai4fm.cs.luc.edu/papers/gsirs-2026-tla-llm/
  - ShardStore: https://www.amazon.science/blog/aws-team-wins-best-paper-award-for-work-on-automated-reasoning and https://www.cs.utexas.edu/~bornholt/papers/shardstore-sosp21.pdf
  - Cedar: https://arxiv.org/pdf/2407.01688 and https://aws.amazon.com/blogs/opensource/lean-into-verified-software-development
  - Assurance 2.0: https://arxiv.org/abs/2205.04522
  - SLSA VSA: https://slsa.dev/spec/v1.1/verification_summary
  - Martian bench reports: https://www.coderabbit.ai/blog/coderabbit-tops-martian-code-review-benchmark and https://www.greptile.com/content-library/greptile-martian-code-review-benchmark
- **Deliberation.** All via g6.
  - Debate: a systematic evaluation, https://arxiv.org/abs/2502.08788, and a study of its failure modes, https://arxiv.org/abs/2509.05396
  - Self-correction: https://arxiv.org/abs/2310.01798 and https://arxiv.org/abs/2406.01297
  - PoLL panels: https://arxiv.org/abs/2404.18796
  - AlphaEvolve: https://deepmind.google/discover/blog/alphaevolve-a-gemini-powered-coding-agent-for-designing-advanced-algorithms/
  - STPA Handbook: https://www.flighttestsafety.org/images/STPA_Handbook.pdf
  - Design docs at Google: https://www.industrialempathy.com/posts/design-docs-at-google/
- **Cited by the designs and not fetched by them.**
  - Necula, proof-carrying code (d3): https://dl.acm.org/doi/10.1145/263699.263712
  - AFL fork server (d3): https://lcamtuf.blogspot.com/2014/10/fuzzing-binaries-without-execve.html
  - Abadi and Lamport, refinement mappings (d5): https://www.microsoft.com/en-us/research/?p=145187
  - Stryker (d4): https://stryker-mutator.io/docs/General/dashboard/
  - PIT (d4): https://pitest.org/
  - mutmut (d4): https://github.com/boxed/mutmut
  - cargo-mutants (d4): https://github.com/sourcefrog/cargo-mutants
