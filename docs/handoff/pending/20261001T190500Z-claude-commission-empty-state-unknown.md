### 2026-09-25 to 10-01: a commissioning state line that comes back empty, names no state, or was never read makes its row unknown, so the receipt no longer reads commissioned over it

Stacked on claude/commission-when-crash-unknown (e33e9ef9), which carries
#375. It lands after both, in the slot the carrier gives it. The engine
change is in lib/commission.sh; the rest is in tests/run.

**Defect closed.**
- `felix_commission_run` captured each row's state line, split it with
  `IFS=$'\t' read -r st detail prov`, and took the first field as the state.
- When `felix_commission_state` printed nothing, `st` was empty. That happens
  when a fork inside it fails with EAGAIN; it was measured with `ulimit -u 1`
  inside the state function's own subshell.
- The row then printed with class `n/a`, `felix_commission_counts` counted it
  as nothing, and `felix_commission_receipt_write` wrote `commissioned` when
  every other row was done.

Now, after both reads (before the runner, and after a `felix:` answer ran):
- A state that is none of the eight a row can have becomes `unknown`.
- Its detail says the row's state could not be computed, and its provenance
  becomes `-`.
- The check is `_felix_commission_state_known`, a builtin `case` beside
  `felix_commission_class`. It forks nothing.
- `st`, `detail` and `prov` are cleared before each read. A read that never
  ran (a here-document that could not be written, on bash 3.2) had left the
  previous row's `done` on a row whose check failed.

**Shown red first.** A separate agent wrote nine assertions blind, from the
contract, before the fix (7ff6dcdc). Against origin/main's engine, seven of
them fail:
- the empty row reads `[]` and `n/a`;
- the receipt reads `commissioned`;
- a stray word reads `finished n/a`;
- the re-read after an answer reads blank.

The same comparison with a real fork failure, not a stub: `ulimit -u 1` in
one row's state subshell gives a `commissioned` receipt on main and
`indeterminate` here.

**Adversarial review.** It found ten things.
- Fixed here:
  - the previous row's state carried over when the read never ran (the new
    assertion fails on a no-reset mutant with `done done`);
  - the guard now also resets provenance;
  - comments and the commit subject claimed more than was measured;
  - four tests added after review, not blind: a row after the bad one, the
    re-read's answer having run, the never-read state line, and the fixture
    left as found.
- Mutations of the guard (dropped at either site, detail dropped, predicate
  always true, `''` or `held` changed in the list) are caught by this block.
  Removing `not-applicable` or the provider states from the list is caught by
  the wider commissioning section, not this block.

**Gate.** At d163657a: 3894 passed and 1 failed. The failure was `red.tsv`,
recorded against an older engine; every other check was ok. The record was
not retaken. At load 330 on 2026-10-01 it would have taken about fifteen
hours, and it would be stale by the slot anyway. Re-record with
`tests/run --record-assertions` against the head this lands on, then gate.
Version 0.49.233 is a placeholder; the carrier assigns the real one.

**Handed on, not done here:**
- A fork that fails in the run's own loop shell ends the loop (status 128 on
  bash 3.2). The rows after it go missing rather than blank, and the receipt
  still reads commissioned. Only the consumer can catch this, by requiring
  every need once in the run's output. `felix_commission_counts` coming back
  empty or shifted is the same class.
  Session "Make the commission receipt refuse an incomplete run".
- A lookup inside the state function that fails into a valid word, such as
  `_felix_cap_active` giving `not-applicable`, or the provider state probably
  giving `answered`. The guard cannot tell those from real answers.
  Session "Stop commission lookups failing into a valid state".
