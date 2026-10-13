### 2026-10-13: the fixture floor and the fixture git proof (slots 3+3b), carried onto the split suite

Slots 3 and 3b of the 2026-10-08 weekly batch, carried by "Inventory work
prioritization" [9b9acc] after their owners were archived. Their two pending
sections (`20261008T212620Z-claude-suite-fixture-floor.md`,
`20261009T001309Z-claude-suite-git-proof.md`) say what the change is and how
it was reviewed. This section says only how it was moved onto main
d36ec648 (0.49.286), which had cut tests/run into a driver and parts since
the branch was written (#424).

**How it was moved.** Main's driver and parts were expanded into one file,
with a marker line at each part's start and end. The branch's diff from its
base (6fe5f986) was merged into that file with `git merge-file`, and the
result was cut back on the markers. 431 hunks gave 5 conflicts, each settled
by hand and asserted in the script that did it:
- the REAL_HARNESS guard and the driver's own comment, both kept;
- the fixture floor at the start of resolution, made part 0005;
- two of main's lines that 3b converts, given both edits;
- the end-of-suite checks, made part 9990 so they stay after every other part.

**Where the new text sits.**
- 3b's preamble helpers became parts 0001 (the origin guard, `$TMP` and its
  checks, `FELIX_TEST_RAN`) and 0002 (`_fx_cd`, `_fx_git`, `_fx_lint`, the
  EXIT trap). Each is sourced from the driver line its text came from.
- Main's widget fixture became part 0004, so the driver stays within 500
  lines (468).
- Part 0200 held 3,224 lines after the merge. It was cut into 0200-0204 at
  section headers, each piece parsing alone under `bash -n`.

**Six checks read the suite's own text.** They were written against one file:
`_ff_self` (the preamble refusals), `_fxl_file` (C3, the lint and the
`_ff_case` pin), and `_gp_src`, `_g2_src`, `_g3_src` and `_rh_src` (the
preamble-and-one-section runners). On the driver alone they would read no
section, because its first header is `reached`. They now read
`_suite_flat` (end of part 0002), which rebuilds the one file once per run
from `$REAL_HARNESS/tests`. That rebuild was checked against the merged file:
the only differences are its own definition and those six lines. The
`_ff_case` cksum is unchanged (1793434744 1884), so the set-aside needs no new
review.

**Conversions owed at the merge.** `_fx_lint` over the driver and every part
found 45 raw sites, all in parts main added after the branch's base. The
state file had foreseen this ("converts 1's +9 and 2's +1 at its main merge"),
and the gate-friction and own parts added the rest. 44 lines were converted
by 3b's final rule. One line holds two sites. After that, the lint reports
only `_ff_case`'s three reviewed probes.

**After it lands.** Row 0's step C (every part runs alone) builds on
`_fx_cd`/`_fx_git` and starts once this is on main ("Queue-based build
system" [62efaa]). Each later batch branch converts its own raw sites when it
merges main, and names the count at "you are next".
