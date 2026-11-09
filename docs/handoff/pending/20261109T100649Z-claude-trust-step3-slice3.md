### 2026-11-09: P's instrument parts judge the candidate (trust-plane step 3, slice 3, 0.49.335)

**What this is.** Design step 3, slice 3, on branch `claude/trust-step3-slice3`. It moves inventory row D2 for the merge and narrows residual R3.
- The spec is in the memory root, `audits/2026-11-08-trust-plane-step3/spec-slice3.md`: rules S7 to S9, then amendments A1 to A21 after each review. The run logs are beside it in `slice3/`.
- The measurement is `docs/2026-11-09-trust-step3-slice3-measurement.md`. The inventory's last column is now "After slices 1 to 3".
- The founder approved the first partition (`projects/felix/partition.tsv`: 209 parts instrument, 50 subject) with "authorize slice 2 and approve slice 3", 2026-11-08 19:37Z.

**What changed.**
- **`lib/instrument.sh`, `instrument-run.sh`, `instrument-verdict.sh`, `instrument-keep.sh` (new).** In `felix merge` for Felix's own repository, after slice 2's binding:
  - which parts are instrument is read from P's partition, and a row moved to `subject` is refused by name (S7);
  - each instrument part the candidate changes, judged against the tree the squash would land (A1), runs as P holds it in a run tree outside the checkout, under process groups, time limits and signal traps; its failures and every assertion name it dropped refuse (S8.1 to S8.3);
  - a change to the machinery (the driver's code, `tests/lib`, `gate.sh`, workflows, anything else under `tests/` but parts and records) runs every instrument unit of P and the canary in `tests/canary/` under the candidate's driver (S8.4, S8.5);
  - a machinery change's judgement is kept in the home's state for its pair (A5). A kept judgement a unit could have written is not read: the units' own `HOME`, a sweep of what changed during the run, a marker of each running judgement, and no read while another judgement runs (A10, A13, A19).
- **`lib/resolve.sh` (A20).** Inside `felix merge`, the readers' merge now stops at the merge base. As 0.49.334 landed it, that merge failed whenever the base had a parent, and both change readers took three-dot there.
- **`lib/bind.sh`.** The copy's long git commands run in process groups of their own, and QUIT is trapped (A9).
- **Tests.** Blind parts 2180 to 2183, one per spec round. 2180 has 106 reported lines, 2181 has 102, 2182 has 78 and 2183 has 93, and none fails here.

**Measured** (details in the report).
- **Battery:** on main, a loosened, deleted, unsourced or renamed guard, or a neutered `bad()` or `is()`, lands when the candidate's suite passes. Here each is refused, and so is a partition row moved to `subject`, which main has no table for.
- **Cost:** a machinery change runs about 200 units, 1,395 to 4,044 s on this Mac across the rounds' runs, once per pair; the kept judgement reads back in about 3 s. A change to a few parts runs those units (41 s for three).
- **False blocks:** round 2's honest full run refused 51 lines, from where units ran (A17) and one lint (A18). The final run, on this branch with the same honest change, refused nothing: 202 units, 1,350 s, and its kept judgement read back in 1.75 s.
- **Review:** the first build's review and two fault rounds, then checks against each confirmed finding's repro, which found no regression. Three later findings: an automated review's (A19), the merge with 0.49.334 (A20), and a watchdog race behind a gate failure under load (A21).

**Open, for whoever takes step 3 next.**
- **Candidate code in P's run (E4).** Units run as the worker's user, and none of this is a sandbox: a unit can find the real home, outlive its group, or remove its judge's marker (A13's open list).
- **The kept judgement is the worker's file (R4),** unsigned, until the authority has an identity of its own (R1, step 4).
- **A guard weakened under its own name,** the canary's strength, the stale manifest, exact counts and mixed parts (spec §3).
- **The gate and CI** still run the candidate's suite (D1, D3).
- **Products' suites,** each with a partition of its own.

**Release.** 0.49.335 fails closed until the founder authorizes it by name (direction row 49). The pull request is labelled needs-founder.
