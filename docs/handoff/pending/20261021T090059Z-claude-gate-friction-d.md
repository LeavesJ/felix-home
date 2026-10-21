### 2026-10-21: the parallel suite runner, `tests/run -j N` (gate friction D)

**Engine 0.49.303 (this branch, `claude/gate-friction-d`, on origin/main
e3636d40).** Row 0's last step, after C (#444, 0.49.299), which made every
part run alone. The contract is `docs/2026-10-18-gate-friction-contract-d.md`,
revision 12. Its amendment sections record every review and evidence pass that
changed it. The evidence and the cost on the tree that lands are in the PR.

**What changed.**
- **`tests/run -j N`**, N from 1 to 64, or `FELIX_TEST_JOBS` when no `-j` is
  given. `-j 1` is the serial run, line for line. `-j` combines with
  `--record-assertions` and `--reuse`. A bad N, or a broken
  `tests/groups.tsv` under N above 1, exits 2 before anything runs.
- **Units.** The parent runs the prelude (0001 to 0007) once. It then runs each
  unit as `tests/run --part NAME...` in a process of its own, at most N at
  once, longest first by the durations file
  (`git rev-parse --git-path felix-suite-durations`). A unit is a group, or a
  part numbered 0010 or later that is in no group, other than 9990. 9990 runs
  in the parent and judges the parent's and every unit's end state.
- **`tests/run --part NAME...`** runs one to six adjacent parts after the
  prelude. It is refused with `-j`, `--record-assertions` or `--reuse`.
- **Slots.** Every `-j` run on the machine shares K slots, red's suite
  included. K is the core count, or `FELIX_TEST_SLOTS` in tests. A slot is a
  `flock` on a file under `${TMPDIR:-/tmp}/felix-suite-slots`, which the
  kernel releases however its holder ends. A `-j 1` run takes none.
- **The log** comes out in the driver's order. Under `-j` the summary ends
  ` (counted from lines)`. Seven runner failures each print a `  FAIL  ` line
  in the unit's place: a prelude that failed, a member that did not finish,
  no mark, a non-zero status, more FAILs than lines, a runner line printed by
  a part, and a part that left the shell changed for the parts after it.
- **Record runs under `-j`** write the same manifest byte for byte, run red's
  suite with `-j N` too, and are not re-judged. The gate's next run judges
  the record, as part 1010 does in every run.
- **Groups** (`tests/groups.tsv`, a yellow risk row, so the verifier reads
  every change to it). These parts run in one process, in order, because a
  later one judges an earlier one's work:
  - ib, 0900-0940;
  - rx, 1100-1120;
  - gp, 0200-0201;
  - au, 0810-0850.
- **`felix gate`** passes the core count as `FELIX_TEST_JOBS`, except on
  GitHub's runner. It binds once landed, because `felix gate` runs the home
  copy of gate.sh. CI's gate stays serial.
- **Suite fixes made along the way.**
  - No pipe into an extracting tar anywhere under engine/harness: an archive
    is written whole to a file first (A29's class, which D's load set off).
    1296 holds a lint for it.
  - `_copy_content` copies the rest of a tree when a tracked file has been
    deleted from the working tree.
  - 0870 checks its own runs for `Permission denied`.
  - 0580 seeds widget's stack.tsv when a run alone has none.
  - 0140 and 0150 run the unattended template's step with a `mktemp` that
    lands under `$TMP`.
- **Tests.** Six blind parts, 1291 to 1296, written from the contract alone
  and red before each build. The two `mktemp` checks in 0140 and 0150 were
  written by the builder; a reviewer checked them against the contract, and
  they are red without the stand-in.

**How to use it.** `engine/harness/tests/run -j 8` for a whole run. A long
pole bounds the wall time: ib, and the D blind parts 1291 to 1294, each a few
minutes.

**Open.**
- projects/felix/snapshot.sh:224 still pipes `git archive` into `tar -x`. It
  is outside D.
- templates/unattended.yml:371's `named="$(mktemp)"` is never removed. On a
  runner it is the runner's. The suite no longer leaks it.
- A unit ended by KILL leaves its own `$TMP`, as a serial run killed so does.
- 1291:294 does not check `_db1_new grp`'s status, so a copy that cannot be
  made fails its cases with exit 127 and no line naming the copy.
- 0780:31 and 0190:376 and :384 print `Broken pipe` under load: a reader that
  stops early (0960's class), with no verdict lost.
- If #455 lands first, D re-versions to 0.49.304 and records again.
