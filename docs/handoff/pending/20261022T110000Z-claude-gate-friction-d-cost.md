### 2026-10-22: the gate's N is measured, and D's cost clause is missed

**Engine 0.49.305 (this branch, `claude/gate-friction-d-cost`, on
origin/main 10381d82, 0.49.303; #455 holds 0.49.304).** This is D's
follow-up after #456 landed. The contract is
`docs/2026-10-18-gate-friction-contract-d.md`, revision 16: R49 to R52, in
its last section. The land-on-green contract gains A33.

**What changed.**
- **The gate's N.** projects/felix/gate.sh now sets `FELIX_TEST_JOBS` to
  `sysctl -n hw.perflevel0.logicalcpu` when that answers a number that is
  at least one. Otherwise it uses the core count, as before: `hw.ncpu`,
  then getconf, then 1. N is held to 1 to 64.
  - On this M1 Pro, N goes from 10 to 8.
  - A machine with one performance level, or with two threads per core,
    keeps the N it had.
  - The slots K stay the core count.
- **Parts 1293 and 1294.** Blind authors rewrote their D1 names from R51 and
  R52 to expect that rule. 1294's sysctl stub now answers each key apart.
  New holds pin the order of the steps, zero at each step, leading zeros, a
  count of 1, and the hold to 64.
- **R49.** D8's cost clause was not met. p8e used 5,689 s of CPU against a
  bound of 4,670 s: 1.38 times serial for 3.83 times less wall.
  - The clause stays as written, and D claims no CPU saving.
  - The extra sys has two candidate causes, which the runs cannot tell
    apart: fork and exec contention, and paging (16 GB, with 21.5 GB of
    swap in use).
- **R50 and R51.** Four quiet runs were measured against a rule fixed
  before them: `-j 10`, 4, 8 and 6. The rule picks 6, but R50 allows only a
  rule over what the machine reports, and none of those gives 6. The
  smaller allowed rule within the band is the performance-core count, 8.
  Against 10, it takes 18% less wall and 5% less CPU.
- **A33 (land contract).** A pull request whose gate passed only in a
  scratch clone stays a draft until its home worktree's gate passes.
  Otherwise `felix merge` refuses it there, and A13 keeps that refusal.

**Open.**
- **The 48 GB laptop.** Run R50's rule again there, with the same scripts
  (evidence/ev-chain3.sh and cost-n.py), before calling 8 that machine's N.
- **The cause of the extra sys.** Fork and exec, or paging. A profile, or
  the runs on the 48 GB laptop, would tell them apart.
- **The commission re-stamp.** It waits on #455, and the carrier
  recomputes it.
- **#452.** Its A32 edits the land contract in another place than A33.
