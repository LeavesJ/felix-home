### 2026-10-28: contract D's blind parts hold their time windows under a loaded full gate (0.49.309)

**Engine 0.49.309 (branch `LeavesJ/angry-hopper-079c19`, on origin/main 78f0268f).**
On 2026-10-28 three `felix gate` runs failed on names of 1293, 1294 and 1295
whose verdicts depend on time. The machine's load was 100 to 230, and each
name passed when its part ran alone. The findings are
audits/2026-10-18-gate-friction-d/evidence/gate-red-2026-10-28.md. Contract D
gains revisions 17 and 18 (docs/2026-10-18-gate-friction-contract-d.md, last
two sections). Blind authors changed parts 1291 to 1296 to fit them. No rule
of the runner, red or receipt.sh changes.

**What changed.**
- **R53, 1293's forged case.** The hold's C is now 40 s, counted from the
  record run's `failed` mark, not from hold.go. Measured at a load of about
  300, go-to-mark grows with load, from 9 to 26 s, while mark-to-step-end
  stays at 0.3 to 1.2 s.
- **R54, 1294's D4 wait case.** The waiting unit's duration is compared with
  its own wait S (at least 30 s), not with the other unit's duration.
- **R55, 1295's R8 run.** Every inner run bound is 600 s. A bound is not a
  margin.
- **R56 and R57.** One rule for every time window, by kind: bound, margin,
  floor or gap. The authors swept all six parts with it.
- **R58 to R62, after revision 17's review:**
  - watches, a kind of their own, last their floor (R58);
  - a record run ended by a signal is drained as a bound (R59);
  - the watcher is waited for at the record run's exit (R60);
  - what a case starts ends with its case (R61);
  - every part logs its runs and margins to DJX_MLOG (R62).

**Evidence.** Red-first trees are built by
evidence/ev18-trees.sh: one mutant per clause, each mapped to the names that
must FAIL in it. The runs, the record and the gate under 30 CPU burners are in
the PR body.

**Open.**
- **1296's lh.** It keeps a pause that places an event inside a span of D's
  build (revision 18's review, "A placement, open"). Under load it does not
  tell apart a build without R13's read-back. This is a revision of its own.
- **R60's narrowing.** A wrapper that outlives a record run's normal exit by
  less than 20 s is caught by no name (recorded in revision 18's review).
