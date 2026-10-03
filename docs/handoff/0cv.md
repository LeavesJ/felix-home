### 0cv. 2026-10-01: a receipt over a run that reported fewer rows than its table lists, or over counts that are not numbers, is indeterminate, and the reader refuses a receipt whose counts or result no run writes

Stacked on claude/commission-empty-state-unknown (3a5c86e4), which carries
when-crash and #375. The engine change is in lib/commission.sh and felix's
cmd_commission; the rest is the cmrc block in tests/run. No table under
projects/ changed, so the commission stamp does not move.

**Defects closed.** Both measured on /bin/bash 3.2.57, before and after, with
real failures and not stubs:

| Shape | Before | Now |
|---|---|---|
| `ulimit -u 1` in the run's loop shell, at row 2 of 3 | 1 row printed, `commissioned`, the held row gone | `indeterminate` |
| `ulimit -n 4` in that shell, so a substitution has no pipe | 2 rows printed, `commissioned` | `indeterminate` |
| a counts line `2 0  0 0 0`, with the gap at unknown | `commissioned` over a held row | `indeterminate`, counts all `?` |
| a receipt reading `commissioned` over five empty counts | `receipt_valid` rc 0 | `unreadable (`, rc 1 |

- `felix_commission_run_complete PROJ OUT [quiet]` is new. The needs OUT
  reports must match the needs `felix_commission_rows` lists: in order, and as
  many times. Both lists are read by one awk. A table that lists nothing is
  never complete. When the run is short it prints `K of N`, unless quiet.
- `felix_commission_counts` always prints six words. A count it could not read
  is `?`, and then it returns 1.
- `felix_commission_receipt_write`:
  - reads every count as digits, or writes `indeterminate`;
  - writes `?` for every count when the line was not six words;
  - writes `indeterminate` over an incomplete run.

  Both runs in cmd_commission and the suite's `_cm_stamp` go through it.
- `felix_commission_receipt_valid` refuses a result other than commissioned or
  held, and count fields that are not digits. It does so after the stale and
  indeterminate checks and before the claude-cli announcement.
- `cmd_commission` says `the run reported K of N rows ...` when a run was
  short, in --status too. It then says only what is true of the receipt:
  - in --status, that one would be indeterminate;
  - in a full run, that it was written indeterminate, or that none could be
    written.

  Its display reads counts as words, so a `?` no longer prints
  `integer expression expected`.

**Shown red first, though not yet through tests/red.**
- A separate agent wrote 48 assertions blind, from the spec, before the fix
  (5bb16848). Against the pre-fix engine, 31 failed, each for the reason its
  name gives, and the 17 controls passed.
- There are 60 assertions now. All pass at the head. Against the pre-fix
  engine, 40 fail.
- Every count above was taken in a scratch harness that reproduces the suite's
  commissioning fixture and runs this block alone. The carrier allowed no suite
  at load 300+. tests/red and the record wait for the slot.

**Adversarial review.** Three lenses ran, each finding went to a separate
skeptic, and all six findings were reproduced.
- The failures lens starved 270 fork and pipe points inside the receipt write
  and the reader. None gave `commissioned` or `held` over a truncated run, and
  no count came out as a wrong digit.
- Fixed:
  - The table's needs were read with `cut -f1`. BSD cut under a UTF-8 locale
    stops at a need holding a byte that is not UTF-8, so an honest run of such
    a table read `3 of 1` for good on macOS. Now one awk reads both sides, and
    K and N count records.
  - The short-run sentence said the receipt was indeterminate in --status,
    where none is written.
  - The receipt now asks for the status alone, which is two forks fewer.
- Tests added after review, not blind:
  - K over need-less lines;
  - the non-UTF-8 need;
  - count fields 6 and 10 alone;
  - unreadable before the claude-cli announcement;
  - every count `?` on the command;
  - the --status wording;
  - a gapped counts line writing `?` in every place.
- The first 48 assertions caught 20 mutants. Four shapes survived:
  - the six-word guard dropped;
  - unreadable checked after the claude-cli announcement;
  - K counting need-less lines;
  - the summary's held, malformed and awaiting tests reverted to `-gt`.

  Each was rebuilt against the head and run through the block: 59 of 60
  passed every time, and the one that failed was the assertion added after
  review for that shape.

**Gate.** Not run here. The carrier allows only slots 1 and 2 a suite. When
the slot is called, run `tests/run --record-assertions`, then
`tests/red <head of the slot ahead>`, then the gate. Version 0.49.233 is
empty-state's placeholder; the carrier assigns the real one.

**Handed on, not done here:**
- A full run that cannot write its receipt leaves the older receipt on disk.
  For example, a starved run whose write dies before it writes. The CLI now
  says so and exits 1. Emptying the receipt before the write was considered
  and not done:
  - a starved background run would then block every merge until somebody
    reran;
  - the receipt already stands for an earlier run whenever the tables have
    not moved.

  Whether a failed attempt should revoke it is a design call, not a fix.
- On bash 3.2, with `ulimit -n` below 10, the shell cannot save fd 1 around
  the receipt's `> "$path"`. The result word then lands in the receipt as a
  second line, which reads stale and so fails closed. This predates the
  change.
- Measured on bash 3.2 only. CI's 5.2 runs the suite. The stubs are plain
  function redefinitions, and the reviewers found no construct that depends on
  the bash version.
