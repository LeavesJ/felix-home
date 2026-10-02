### 2026-10-02: an assertion the base run never reached is recorded red, and the gate fails a record that counts fewer assertions than the manifest lists (#371's follow-up)

Built on #371 (claude/red-requires-reached). That fix makes tests/red refuse
a suite that stopped before its `reached` line. This one closes the hole
#371 named and left open: a suite can reach its end without running every
assertion.

**Defect closed.** Bash 3.2, which runs the suite on a Mac, drops the rest of
a top-level command list, or of a block, when `$(( ))` errors, and carries
on. A base engine that writes `-` where the suite does arithmetic loses those
assertions silently. The suite still prints `reached`, and tests/red counted
only the lines it saw. The record then shows fewer red than true. Main's
record at 27573cbe (#383) is one: `run 21 3868 5`, 3,894 assertions against
a manifest of 3,900, so at least six listed assertions were counted nowhere.

**What shipped (claude/red-counts-unreached).**
- tests/red reads this tree's manifest once, before the suite runs, and
  refuses one that is not a manifest.
- After the run it counts each listed name's ok, FAIL and skip lines in one
  copy of the log. A name reached fewer times than listed is recorded red by
  its shortfall. The run row's failed count and the name rows include that
  shortfall, so they still add up.
- The suite writes the manifest through `_ran_rows`, which keeps every name
  byte for byte. Folded blanks would have read as never reached.
- The gate's `_rtn1` compares a real run with the manifest beside it. A run
  that counts fewer assertions than the manifest lists is not a record this
  tests/red writes, and it fails. That is the `0 of 270` record #371 found.

**Decided.**
- **A shortfall is recorded, not refused.** The manifest says the assertion
  ran against this tree's own engine. If it did not run against the base's,
  the base does not meet the tree's contract there, which is what red means.
- **A skip counts as reached**, whatever gates it. A block skipped because the
  base lacks a script the tree adds reads as reached, not red. That gap is
  known, and tests/red's header says so.
- **The comparison is one-directional**, like the suite's own. A name reached
  more often than listed, or not listed at all, is not compared, so a run may
  count more than the manifest. It may not count fewer.

**Traps worth keeping.**
- **A manifest out of date errs both ways.** A listed name tests/run no
  longer has reads as red. A name added after the manifest was written is
  not compared. `--record-assertions` writes the manifest just before it
  calls tests/red, so this arises only in a run by hand.
- **A skip reason must stay on one line.** tests/red attributes a skip line
  only when it ends in `)`. A reason holding a newline breaks that, and its
  name reads as never reached. No skip in tests/run has one today.
- **The record block reaches the same names in every mode.** An assertion
  added there behind a mode test would read as red on every record. `_rtjn14`
  pins it for `_rt_judge`'s four names.
