### 2026-10-08: the second review of #401's tests, closed in tests only

#401 made a commissioning row unknown when one of its lookups could not be
made, instead of reading the failure as a valid no. A second adversarial review
of its test block (`# A lookup that could not be made is unknown, never a no`
in engine/harness/tests/run) found four places the block was weaker than its
comments said. An adversarial review of the new assertions then found three
more. The engine was right throughout. Only the tests change here.

**What the block now asserts.**
- **The names lookup's own substitution failing to make its pipe**, which the
  block had called beyond any stub. It is asserted two ways.
  - A function named `[` that exits 0 ends the substitution before its `.`
    sentinel. This holds only while the lookup tests its status with `[`,
    which the shape check pins.
  - Every descriptor below a lowered limit is taken, so the pipe really cannot
    be made, however the lookup is spelled. This was measured on 3.2.57. CI
    runs bash 5.2, where an engine keeping the sentinel passes either way.
- **A count whose grep printed it and then failed.** The provider row reads
  unknown, not answered.
- **The shape check.** It now reports a process substitution, a backquote,
  and every engine function a lookup calls. It reads only the named function's
  body, so a walk moved into a helper had passed it. Measured on 3.2.57 with no
  descriptor free:
  - a backquote expands to nothing at status 0, the same as `$(`;
  - a `< <(...)` redirect fails at status 1 and its loop never runs.
- **The receipt over a provider row whose rows could not be counted is
  indeterminate.** commission.sh's header and escape.sh both say this, and
  nothing asserted it end to end.

**Evidence.**
- 52 of 52 pass on the branch, twice in a row.
- Against the engine before #401 (97ccb117), 32 of 52 fail, including all six
  new assertions.
- These mutants of main's engine each pass main's old block and fail only the
  new assertions aimed at them:
  - the `.` sentinel dropped (the `[` stub and the descriptor assertion);
  - a `< <(...)` walk, a backquote walk, a walk moved into a helper, and a
    membership test moved into a helper (the shape check);
  - a count that reads only PIPESTATUS[0] (the printed-count assertion);
  - a count of unknown rows that skips provider rows (the receipt assertion
    alone).
- A correct lookup that carries its status in the text instead of a `.`
  fails the two spelling pins, the `[` stub and the shape check, and passes
  the descriptor assertion. Moving the lookup off its present spelling means
  updating those two pins.

A red count of zero against main is expected, because the fix is already on
main. The evidence above comes from the block run alone against each engine,
not from the record.
