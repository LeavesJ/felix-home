### 2026-10-01: a red run whose suite died is refused, not recorded as zero red, and the gate fails a record that shows no red run for an engine change (#371)

**What shipped (claude/red-requires-reached).** `tests/red` used to ignore
the suite's exit status, and refused only a run that reached no assertion. A
suite killed part way was written to red.tsv as a clean run. On 2026-09-25 a
suite whose shells were stopped at assertion 270 printed `0 of 270` and
exited 0; that record was discarded by hand. An earlier record read `0 of
1320` just after fork had failed at kern.maxprocperuid, very likely cut off
by it. The full suite holds about 3,700 assertions. That was #371.

Now `tests/red` keeps the exit status and counts a run only when the last
line that is exactly `reached` comes after the last `ok`, `FAIL` or `skip`
line in the log. The suite prints that marker after its last assertion.
Otherwise the run is refused: red.tsv gets base and run rows of `-`, the exit
is 2, and the line reads `red: not run: the suite against <base> did not
finish (exit <rc> after <n> assertions)`.

That alone would have turned a false zero into a dash that still passed. The
record block in tests/run (`_rtn1` to `_rtn4`) read a `-` base as "a
published snapshot" and skipped. The block now makes its whole judgment of a
checkout in one function, `_rt_judge <checkout>`. It reads that checkout's
red.tsv, manifest, plugin.json and git. The suite calls it once for its own
checkout, and the fixtures call it on a checkout built in the block. Under it:
- `_rt_base_kind` names a base: retracted (`-`), commit (forty lower-case hex
  that is a commit here), snapshot (forty hex that is not), or malformed
  (anything else, ref names and abbreviated ids included).
- `_rt_base_check` decides `_rtn3`, and `_rt_record_whole` decides `_rtn1`
  (the base and run rows agree, a real run counts at least one assertion,
  the names add up to the failed count).
- `_rt_report` maps each verdict line onto ok, skip or bad; anything else is
  bad.

Record mode (`FELIX_TEST_RECORD` at exactly 1) and a red run
(`FELIX_TEST_NO_MANIFEST` at exactly 1) are read inside `_rt_judge`, not at
the call. At the call no assertion asked either, and a one-character test
change there skipped all four checks on every run with every assertion green.
Two review rounds found that, one per variable. The call itself is the one
line no fixture reaches. An assertion requires it to be one bare, unindented
line, `_rt_judge "$REAL_HARNESS/../.."`, and the only line in the file that
names it. An assignment, a subshell or a guard at that line fails there.

**Decided.**
- **An engine change carrying a `-` record fails `_rtn3`.** That includes a
  published snapshot built from a home whose main holds one, because the
  public tree would ship an engine whose red run was never shown. The detail
  says to re-record in the repository where the change was made.
- **An engine change with no red.tsv at all fails `_rtn3`**, as a red.tsv
  merge conflict resolved by deleting the file leaves. snapshot.sh archives
  `engine/` whole, so red.tsv ships in the snapshot and this cannot break one.
- **A docs-only change carrying `-` still passes.** No red run is owed there.
- **A base must be what tests/red writes**, a full forty-hex sha. A
  hand-edited `origin/main` resolved after every merge and never went stale.
- **A red run reaches every record-block name a normal run reaches.** Only
  `_rt_judge`'s four skip there. The follow-up counts a name a red run does
  not reach as red, so parity is required.
- **`--record-assertions` still ignores tests/red's exit status.** A run that
  died shows `red: not run: ...` in the record output, and the next plain
  suite run fails `_rtn3` on the `-` record.

**Traps worth keeping.**
- **The marker shows less than it seems.** `reached` shows that the suite's
  main shell got to its end, not that every assertion ran. Bash drops a whole
  statement whose `$(( ))` errors and carries on. A base whose output trips
  one of those loses those assertions from the count, red ones included.
  That is the follow-up on claude/red-counts-unreached.
- **The suite's own `printf '\nreached\n'` is load-bearing.** A red-block
  assertion requires it to be the last section-shaped line of tests/run. A
  section added after it fails that assertion, which is cheaper than every
  engine PR's red run failing.
- **A background writer can split the marker.** The leading newline and
  `reached\n` are two writes, and a stray writer landing between them gives a
  line like `....reached`. The run is then refused, which fails safe. A rerun
  fixes it.
- **The record block runs in red runs too**, where tests/red has exported
  `FELIX_TEST_NO_MANIFEST=1`. A fixture that calls `_rt_judge` must unset it,
  as `_rt_judged` does, or every case reads as red there.

**Open, and where.**
- The base run's unreached assertions, and a run total below the manifest's:
  claude/red-counts-unreached, building on this branch.
