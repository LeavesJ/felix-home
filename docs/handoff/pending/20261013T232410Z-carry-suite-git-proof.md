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
  checks, `FELIX_TEST_RAN`), 0002 (`_fx_cd`, `_fx_git` and the roots) and 0003
  (`_fx_lint`, the origin record, the EXIT trap and `_suite_flat`), cut where
  the lint begins so that no part passes 1,000 lines. Each is sourced from the
  driver line its text came from.
- Main's widget fixture became part 0004, so the driver stays within 500
  lines (470).
- Part 0200 held 3,224 lines after the merge. It was cut into 0200-0204 at
  section headers, each piece parsing alone under `bash -n`.

**Six checks read the suite's own text.** They were written against one file:
`_ff_self` (the preamble refusals), `_fxl_file` (C3, the lint and the
`_ff_case` pin), and `_gp_src`, `_g2_src`, `_g3_src` and `_rh_src` (the
preamble-and-one-section runners). On the driver alone they would read no
section, because its first header is `reached`. They now read
`_suite_flat` (end of part 0003), which rebuilds the one file once per run
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

**Fixture roots outside `$TMP`.** Parts 1100 (#431) and 1130 (#434) make
their fixtures outside `$TMP` on a Linux runner, where `$TMP` sits under a
world-writable /tmp. The guard would have refused all 14 of their converted
lines there. `_fx_root_add` (part 0002) registers such a base. It must be
absolute, empty, free of newlines and colons, and have no `.git` in it or
above it. `_fx_root_del` takes the base back before the part removes it. A
directory is proven only against the root it lies below. The `.git` walk and
`_fx_below` both stop at that root, so one root never vouches for another. A
gitfile's target is now held to the same commondir check as a `.git`
directory; before this, the target was not checked at all. One Opus review
found nine issues, all fixed, among them B2's unchanged copy reading the
driver instead of the flat suite, and 0005 skipping where `_suite_flat` had
failed. Part 0205 has 13 assertions. Ten mutants of the guard were run
against them and nine turned it red. The survivor removes the empty-walk-root
guard in `_fx_below`, which no current path reaches. Parts 1100-1130 passed
644/0 twice: once as macOS runs them, and once with `TMPDIR` under a
world-writable ancestor and `RUNNER_TEMP` private, which is the runner's path.

**Found by the first full record (212 red), all fixed.**
- `_suite_flat` was written `[ -s f ] || awk ... && mv`, which bash reads as
  `(A || B) && C`. Only its first call worked (part 0005's), and every later
  reader got nothing. It is an `if` now.
- Part 0002 held 1,077 lines, past part 1040's 1,000. It was cut where the lint
  begins, into 0002 and 0003.
- The gate-friction blocks (1220, the 1230 addendum, 1240, 1260) ran a copy of
  the driver with every part line swapped for stubs. After 3+3b that dropped
  `$TMP`, the guard and the EXIT trap, and put the stubs ahead of argument
  parsing. `_suite_copy_driver` (part 0003) now keeps the preamble parts
  (0001-0004, the text that was the driver's own on main) where they stand,
  copies the harness's `felix` (the driver's `REAL_HARNESS` guard needs it),
  and puts the stubs where the suite's first part stood. Row 0's
  `onepart.sh` meets the same break and can use it.
- iCloud had left 121 `* 2` copies of tracked files in this worktree, 109 of
  them in `parts/`, and two `main 2` ref files in `.git` that stopped every
  clone. All were moved aside, not deleted, and listed in the carrier's state
  file.

**After it lands.** Row 0's step C (every part runs alone) builds on
`_fx_cd`/`_fx_git` and starts once this is on main ("Queue-based build
system" [62efaa]). Each later batch branch converts its own raw sites when it
merges main, and names the count at "you are next".
