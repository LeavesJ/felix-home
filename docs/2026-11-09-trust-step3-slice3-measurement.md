# Trust-plane step 3, slice 3: does the suite that judges Felix's engine come from the base?

2026-11-09. Slices 1 and 2 (`docs/2026-11-08-trust-step3-measurement.md`, `docs/2026-11-08-trust-step3-slice2-measurement.md`) moved the merge's tables and instruments to P and bound P to the base the provider names. They left residual R3: the suite that judges Felix's engine is the candidate's. Slice 3 has P's instrument parts judge the candidate. The spec is `audits/2026-11-08-trust-plane-step3/spec-slice3.md` in the memory root, with sections 4 to 7 amending it after each review and the merge with main. The inventory's labels (A1 to G2, R1 to R6) are those of `docs/2026-11-08-trust-step3-inventory.md`.

**Scope.** `felix merge`, as the lander and a session run it, dry runs included, for Felix's own repository, at two versions:
- **main:** `origin/main` 6fe629e6 (0.49.334);
- **slice 3:** this branch (0.49.335), spec rules S7 to S9 and amendments A1 to A20, in `engine/harness/lib/instrument.sh`, `instrument-run.sh`, `instrument-verdict.sh`, `instrument-keep.sh`, the canary under `engine/harness/tests/canary/`, and the partition `projects/felix/partition.tsv`.

Not measured: products' suites, which run none of this (S8.11); the gate and CI, which still run the candidate's suite (R4); the hosted authority, which does not exist; CI's bash 5.3 and gawk, which run this branch in CI and not on this Mac.

**This is an open set.** Every count below says what one test part, one run or one review counted. None of them is the size of the space. A route found later is a new row (design §11).

## Answer

**A candidate's change to an instrument part is judged by P's version of it.** On main, a candidate that loosens a guard, deletes or unsources it, or renames its assertion lands, as long as its own suite passes. On slice 3, P's version of each changed instrument part runs over what the squash would land, and its failures, and every assertion name the candidate dropped, refuse the merge (S8.1 to S8.3).

**A candidate's change to the machinery runs P's whole instrument.** When the driver's code, a helper under `tests/lib/`, `gate.sh` or a workflow changes, every instrument unit of P runs, and a canary from P checks that the candidate's driver still reports `bad`, `is` and `has` as failures (S8.4, S8.5). A `bad()` changed to count a pass is refused by the canary.

**Moving a part to subject goes to a person.** The partition is read from P. A row that marks a part `subject` when P does not is refused by name (S7.2).

**What still lands,** by the spec's section 3 and the amendments' open lists, as examples and not the set:
- a guard's body weakened under the same name: P's version still judges that candidate, but once it lands the weakened body is P's, and binds the next one (spec §3);
- candidate code inside P's run: a unit runs the candidate's engine as the same user, and nothing here is a sandbox (E4). A unit can find the user's real home without `HOME`, and so the kept judgements;
- a unit that removes its own judge's marker (A13, A19), or that outlives its process group;
- the gate, CI and their receipts (R4).

## 1. The battery: parts 2180 to 2183

Each part was written from the spec before the code it tests, without the implementation in view, and drives `felix merge --dry-run` from an installed entry over a scratch repository shaped like felix-home, with a fixture P of two to seven parts.

| Part | Written from | Red, against | Assertions reported on slice 3 |
|---|---|---|---|
| 2180 | spec sections 1 and 2 | main at 0.49.333: 18 of 106 fail | 106, none fail |
| 2181 | section 4 (A1 to A7) | the first build, 49df77a0: 16 of 102 fail | 102, none fail |
| 2182 | section 5 (A8 to A11) | round 1's fix, 21050721: 3 of 78 fail | 78, none fail |
| 2183 | sections 6 and 7 (A12 to A19) | round 2's fix, 2a05b99a: 2 of 81 fail; with A19's cases, 1df3b835: 2 of 93 fail | 93, none fail |

Counts are reported lines: a part reports one line per case of a loop, so a line count is larger than the number of assertions written. Against main at 0.49.334, ⟦red-whole⟧ of the suite's assertions fail (`tests/red`, `red.tsv`).

What the cases cover, as the spec lists them: an honest change and a subject part's count (passed); a loosened guard, with and without a partition row; a deleted, an unsourced and a renamed guard; a group whose subject member P's version would fail (not refused for it); the partition loosened, and loosened together with the part; `bad()` and `is()` neutered (refused by the canary, with every instrument unit run); an honest wording change to a helper (not refused); two judgements that cannot share a canary name; P's driver missing (`unknown SUITE`); a product (not run); nothing left after a pass, a refusal and a TERM; nothing run behind a slice 2 refusal. The amendments added a candidate cut before main's last landing, judged as the squash lands it (A1); the driver's blank lines (A2); time limits, signals and temporary directories (A7); the records and the kept judgements out of the units' reach (A8, A10, A12, A13); a KILLed judge (A14); a signal in each directory's making (A15); and two overlapping judgements (A19).

Each fault round's repros are filed beside the spec, and part 2181's A1 cases also pin A20 (section 3): 99 of 102 pass without it.

## 2. Cost and false blocks

**Nothing instrument changed:** no run tree is made (S8.7), which part 2180's control checks. Its cost was not timed.

**Instrument parts changed, machinery not:** P's units holding them. Three real parts (0620, 0204, 1510) as a candidate, at load 14 to 19: 41 s.

**Machinery changed: one honest full run of the real repository,** H respacing one comment in `tests/run`, B the branch:

| Build | Units | Seconds | Load | Refused with |
|---|---|---|---|---|
| first build, 49df77a0 | 198 | 4,044 | near 100 | 1 line: 2180's S8.9 fixture control (A4) |
| round 2, 2a05b99a | 200 | 1,395 | 5 to 27 | 51 lines: 0620 (46), 0204, 1510, 0992 and 2182 (2) |
| round 3, d4b28834 | 201 | 2,024 | 23 to 91 | 2 lines: 0200's lint on 2183, and 2183's A14 |
| this branch, ⟦tip⟧ | ⟦units⟧ | ⟦secs⟧ | ⟦load⟧ | ⟦final⟧ |

Each row is one sample, on this Mac, while other sessions' suites ran. Round 2's 48 lines from 0620, 0204 and 1510 came from where a unit ran: its `HOME` under the run directory dropped the units' `TMPDIR` as a temporary root (`lib/where.sh`), so the scoped lifts those parts test refused, and T sat under the units' own `TMPDIR`. Each of those parts passed alone. A17 fixed the layout. 0992's line was the slice's own sort lint failure (A18). Round 3's two lines were the blind part's own fixtures, fixed with A19's assertions.

**The kept judgement (A5):** a second dry run of the same pair, at the same base and engine, read the first's blocker lines back in 3.11 s, byte for byte.

**Where a refusal now comes from that did not before:**
- **Every machinery change waits for a full run,** tens of minutes on this Mac, once per pair of base, landed tree and engine. The lander's tick holds the pull request while it runs.
- **A judgement made while another runs in the same home** runs in full and is not kept (A19): what it would read or write is within reach of the other's units.
- **A part of P that tests where it runs** can pass in the checkout and fail as a unit. Examples of what still differs, from round 3, not the set: T is a repository of its own, not a linked worktree; it is not under `HOME`; the unit's `HOME` is empty; T is under `/var/tmp` on this Mac.
- **A mixed part** (spec §3: 1690, 1720, 1700, 0240 known) is instrument, so a landing that changes its subject assertion goes to a person.

## 3. The reviews

The review budget was the first build's review and two fault rounds. Each fault round's findings were reproduced, then given to a skeptic told to refute them.

- **The first build's review** (`slice3/review/`): three lenses and an automated commit review. Its confirmed findings are A1 to A7: a branch cut before main's last landing was judged by main's own new parts (a blocker); the driver's blank lines counted as machinery; P against itself refused; duplicate rows; and eight faults in failure and cleanup.
- **Fault round 1** (`slice3/round1/review/`): two confirmed, and one from the automated review: a unit could overwrite the manifest the judge read afterwards (A8); a signal while T was built left it (A9); a unit could leave a clean kept judgement for a later candidate (A10).
- **Fault round 2** (`slice3/round2/review/`): four confirmed, and three gaps from the automated review: a unit rewrote the canary's copy before the canary ran, so a neutered `bad()` passed (A12); a unit forged a judgement and ended its judge before the sweep (A13); a KILLed judge left the units' directories (A14); a TERM before the traps left the run directory (A15). One finding was refuted: two judgements sweeping each other's receipts, which loses a receipt and so only costs a run.
- **Round 3, with no fault round left:** each fix was checked against the repro of every confirmed finding of fault rounds 1 and 2 and against the automated review's scenarios (`slice3/round3/check/`), and none came back. Three repros as written had gone vacuous under the new layout, and were rebuilt so that they fail at the round they were written for. One repro removed every `felix-instrument-r.*` under `/tmp`, including a concurrent full run's live records directory, and that run's canary failure was this incident's (`check/INCIDENT-r1-f3-cleanup.txt`).
- **The automated review of round 3** found that a judgement read a kept judgement while another judgement's units ran (A19). Fixed, and its assertions written blind.
- **Merged with main at 0.49.334 (A20),** part 2181's A1 cases failed: inside `felix merge`, 0.49.334's merge reads the checked copy alone, the copy holds no commit older than the merge base, and `merge-tree` failed on its parents. By that mechanism both change readers (`felix_added_lines`, `felix_changed_paths`) took three-dot inside `felix merge` on 0.49.334 whenever the merge base had a parent, the stricter direction, and slice 3 refused a candidate whose base moved, as in 2181's A1 cases. Part 2179's fixtures never reach a merge base with a parent, so it passed with and without the fix. The merge base is now the made repository's shallow boundary, as a shallow checkout's already was (`lib/resolve.sh`; `slice3/round3/merge/`).

## 4. Open after slice 3

As examples and not the set:
- **R4: the gate, CI and their receipts** still run and record the candidate's suite.
- **Candidate code in P's run (E4).** Units run as the worker's user. Process groups, a `HOME` of their own and the sweeps are not a sandbox: a unit can find the real home, kill the watchdog, outlive its group, or remove its judge's marker.
- **The kept judgement is the worker's to write** (R4), with nothing that signs it. A judgement read between two runs trusts the file.
- **A weakened body under a kept name,** and the canary's strength (one canary, four helpers).
- **The stale manifest:** S8.3 counts names in the manifest H writes; reading the names H's version reaches is the direction.
- **Exact counts in instrument parts,** and **mixed parts**, decided in spec §3.
- **Products' suites,** each with its own partition (E5 is per repository).
- **A criss-cross history:** with more than one merge base, the readers' merge fails and takes three-dot, as before.
