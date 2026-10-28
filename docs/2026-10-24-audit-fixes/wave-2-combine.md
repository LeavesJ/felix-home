# Audit wave 2: what combining the batches changed, contract, 2026-10-28

Wave 2 of the 2026-10-24 audit fixes is one branch, `claude/audit-wave-2`. It takes wave 1's gated
tip (`claude/audit-wave-1`, 0.49.308) and the batches whose finals went green after it. This file is
the contract for what their combination needs. Where it differs from `wave-1-combine.md` or a batch's
contract in this folder, it wins. Clauses there are cited as "wave-1 C1" and "b05 B8".

The words are wave-1-combine.md's: **H**, **hp**, **p**, **Ld** (p's land directory, holding
`ledger.tsv` and `alerts.tsv`), **an attempt**, **a record** and **the R2 sentences**.

## 1. Defects found by review of wave 1 (all low)

None is live until the founder merges `.github/workflows/felix-alert.yml`: until then every attempt
records `no-alert-workflow`, and b05 B8 skips nothing.

**L1. With two or more events that alternate, each is sent again.** b05 B8 compares an event with the
newest `dispatched` record of any kind. A tick that writes `waiting` rows for #1 and #2 dispatches
both. The next day's rows for the same two pull requests and details are each compared with the
other's record, so both are sent again, every day. The same happens to the hourly `paused` row
whenever any other event was dispatched since the pause was said.

**L2. A pause after a resume, for the same reason, is not said.** `felix land --pause R`, then
`--resume`, then `--pause R` again: the second pause's attempt finds the first one's `dispatched`
record with detail `R` and is skipped. The phone was told of a pause, never of the resume (wave-1 C2),
and is not told the lander stopped again.

**L3. Part 1720 no longer has a tick meet a hanging or failing gh.** Wave-1 C1 moved the paused event
to the `--pause`, and part 1720's restated A26 and A27 now meet the hang and the failure in the
`--pause` alone. B9's bound and B10's "landing is unchanged" are no longer checked inside a tick.

**L4. Part 1720's A31 says a tick rewrote `alerts.repo`.** Since wave-1 C1 it is the `--pause`'s
attempt that does. Its comment, its name and the fixture control before it still say the tick.

## 2. Required behaviour

- **D1. B8 compares an event with its own last record.** This amends b05 B8 and R4.
  - An event is a repeat when the newest record in `alerts.tsv` whose kind (field 3) and pull request
    (field 4) equal the event's is `dispatched` and its detail (field 8) equals the event's detail.
  - A repeat runs no gh call and appends no record. Anything else is attempted.
  - Records of other kinds or other pull requests do not count, whatever their state or age.
  - A newest same-kind, same-pull-request record that is `failed` or `no-alert-workflow` means the
    event is attempted again when it is raised again (R4), as before.
  - R4's line 4 is unchanged. N still counts every `no-alert-workflow` and `failed` record after the
    newest `dispatched` record of any kind (all of them when there is none).
- **D2. A resume ends the pause it resumed.**
  - For kind `paused` only, a record that would make the event a repeat under D1 does not when the
    ledger holds a `resumed` row whose time (field 1) is at or after that record's time (field 1).
  - So `--pause R`, `--resume`, `--pause R` dispatches twice. A tick's hourly `paused` row for the
    same reason after the second pause's dispatch is a repeat again.
  - A pause the tick sets itself (`_gt_pause`) and a person's resume of it follow the same rule.
  - Times have one-second resolution. When a resume and a dispatch share a second, the event counts
    as ended, so the error is one extra alert, never a silent pause.
  - Nothing is written to `alerts.tsv` for a resume (wave-1 C2 stands).
- **D3.** The trampoline carries `lib/notify.sh` whole (b05 B11), so D1 and D2 reach its attempts
  (`deploy-owed`, `unreadable`) with no copy to keep in step.

## 3. What must not change

- Every b05 B1-B11 and R1-R8 clause except B8's comparison and R4's sentence about it: the calls and
  their order, the standing issue, the enumerated body, `GH_*` handling, the bound, the folding.
- Wave-1 C1-C8 and their pins in parts 2120 and 1720, b02's 1650, 1660 and 1665, b04's 1690, b03's
  1670 and 1680, b05's 1710, and part 1100.
- The ledger, the banners and `felix status`'s alerts row, for any sequence of events (b05 B10, R5).

## 4. The assertions

New assertions go in a new part, `2140-wave-2-combine-blind.sh`, written from this contract alone. It
may use the suite's helpers, the fixtures in `tests/lib/land-on-green.sh`, and fixture patterns from
parts 1710, 1720 and 2120. Each name starts `W2C`. Red first. At least these cases:
- **For D1:**
  - A tick that writes `waiting` rows for two pull requests dispatches each once. With those rows
    moved 25 hours back, the next tick writes them again with the same details and dispatches neither.
  - `--pause R` dispatched, then another kind's event dispatched (a `waiting` row will do), then the
    ledger aged past the hour and a tick: the hourly `paused` row is a repeat, so no gh call.
  - A control: an event whose newest same-kind record is `no-alert-workflow` is attempted again.
- **For D2:**
  - `--pause R`, `--resume`, `--pause R`: two `workflow run` calls and two `dispatched` records with
    field 8 `R`. A tick with the ledger then aged past the hour sends nothing more.
  - Aging the ledger moves a `resumed` row's time too. A case that needs the resume to count must not
    age the ledger between the resume and the pause it ends.

Part 1720 is restated, keeping each A-number and saying in its name that it was restated for this
file:
- **A26 (L3).** After the slow `--pause` meets the hang, the ledger is aged past the hour and a slow
  `--tick` runs. The tick's hourly `paused` row is attempted again (its newest record is `failed`,
  D1), meets the hang, and is ended within B9's bound. The hung gh is gone, and two `failed` records
  both say timed out.
- **A27 (L3).** Each of its three scenarios ages the ledger past the hour before its `--tick`, so the
  tick's attempt meets a local origin, a failing `gh api user` or a hanging dispatch. The ledger fields
  2-7 are the same in all three: the `--pause`'s row ending `; by session -` and the tick's hourly
  row. Exit 0 throughout.
- **A31 (L4).** The comment, the name and the fixture control say that the `--pause`'s attempt, with
  a local origin, rewrote `alerts.repo`. What it checks is unchanged.
- Any other assertion in parts 1710, 1720 or 2120 that pins B8's old comparison (an event compared
  with another kind's or pull request's newest record) is restated for D1 the same way.

## 5. Review round (review of 6c63de0e)

The review found that D1 as written silences a recurring event. It also found three gaps in D2
and two weakened assertions. The clauses below amend section 2. Their assertions go in part 2140
after its last, named `W2C R<n>`, plus the restated 1720 cases listed at the end.

- **D4. A job event standing for a day is said again (amends D1).** For an event with no pull
  request (field 4 is `-`) whose kind is not `paused`, D1's repeat holds only while the matching
  dispatched record is less than 24 hours old.
  - Age is the record's time (field 1) against the attempt's own clock.
  - So a watchdog `timeout` with a fixed detail that recurs a week later is sent.
  - A `deploy-owed` that stands for days is sent at most once a day.
  - `paused` keeps D2.
  - An event with a pull request keeps D1 unchanged. A `waiting` row 25 hours on is still a
    repeat, as wave-1 C3 and part 2120's C3c pin it.
  - A record whose time cannot be read counts as old, so the event is sent.
- **D2a. A resume ends the pause that raised the record (amends D2).**
  - The pause that raised a `paused` record is the newest `paused` ledger row whose time is at
    or before the record's time.
  - A `resumed` ledger row whose time is at or after that row's time ends the pause.
  - So a resume made while the record's attempt was still running counts.
  - With no such `paused` row, D2 applies as written.
- **D2b. A ledger that cannot be read ends the pause.** When `ledger.tsv` exists but cannot be
  read, a `paused` event is not a repeat. The error is one extra alert, as D2 intends.
- **D5. Kinds and pull requests are compared as strings.** `031`, `31.0` and `31` are three pull
  requests, as the comparison before D1 had them.

### Assertions

- **R1 (D4)** A `timeout` job event dispatched, a second `timeout` with the same detail raised at
  once: no dispatch. Then the first record's time moved 25 hours back in alerts.tsv: the next
  `timeout` with that detail dispatches.
- **R2 (D4)** A `deploy-owed` dispatched 23 hours ago (its time set by hand in alerts.tsv) and
  raised again: no dispatch. The same at 25 hours: one dispatch.
- **R3 (D4, control)** A `waiting #31` record moved 25 hours back, and the same waiting row
  again: no dispatch.
- **R4 (D4)** A job record whose field 1 is not a time: the event dispatches.
- **R5 (D2a)** `--pause R` whose attempt is held by a slow gh stub, with `--resume` run while it
  is held (resumed row before the record's time, after the paused row's), then `--pause R`
  again: two dispatches.
- **R6 (D2b)** `--pause R` dispatched, `--resume`, ledger.tsv made unreadable (mode 200),
  `--pause R`: two dispatches.
- **R7 (D5)** Records for pull request `31`, then an event for `031` with the same kind and
  detail: one dispatch.
- **1720 A31, restated again.** Its trampoline runs with a home path no earlier case used, so
  its deploy-owed detail is new. A31 asserts the trampoline appended exactly one record, failed,
  kind `deploy-owed`, with a note starting `origin:`, after the `--pause`'s own record.
- **1720 A27, restated again.** Each scenario's paused rows are pinned field by field. Pull
  request, sha and worktree are `-`, only the wall field is open, and the details are the
  `--pause`'s `; by session -` row and the tick's row.

## 6. Second review round (review of 995a8526)

The build of section 5 was green except for timing. The review found one high, one medium and
four lows. The high and the flake have one cause, and the cause is this contract's D2a.

**The invariant D2 serves.** The last paused alert the phone received must say what is true now.
A resume is never alerted (wave-1 C2). So a pause whose alert was dispatched after a resume, for
the same reason, leaves the phone's last word true. Sending it again adds nothing.

- **D2a is withdrawn. D2 stands as section 2 writes it.** D2a compared a resume with the paused
  row that raised the record, not with the record. Ledger times have one-second resolution, so
  "the newest paused row at or before the record" picks a different row depending on which second
  the tick's own row lands in. Under D2a, 1720 A18 and 2140's D2a2 pass or fail by timing, and
  2140 W2C D2c fails whenever the tick's row lands a second after the record. D2a was also
  unneeded. In its case (a resume while the attempt runs, then `--pause R` again), the alert said
  "paused R" after the resume, so by the invariant above the second pause is a repeat. D2's own
  tie rule stands: a resume in the record's second ends the pause, and the error is one extra
  alert.
- **D2b, bounded (replaces section 5's D2b).** When `ledger.tsv` exists but cannot be read (not
  a regular readable file, or the read fails), a `paused` event is a repeat only while the
  matching dispatched record is under an hour old. Age is read as D4 reads it. Without this bound,
  an unreadable ledger made every 5-minute tick dispatch: the tick cannot read its hourly age, so
  it writes a paused row each time. With it, a paused alert is said at most once an hour while
  the ledger cannot be read. A missing ledger is not unreadable. With no ledger, no resume ends
  the pause, and D1 alone decides.
- **D4, keyed (amends section 5's D4).** For a job event (pull request `-`, kind not `paused`),
  the key is the detail up to its first `; `, or the whole detail when it has none. That is the
  "same wait" key the hourly writers use (`_gt_job_once`, the trampoline's `owed`). The event is
  a repeat when the newest record of the same kind and the same key is `dispatched` and under 24
  hours old.
  - Records of the same kind with another key do not count.
  - So the hourly `X; still so since HH:MM` row is the same event as `X`.
  - Two keys of one kind that alternate are each said at most once a day.
  - A newest same-key record that is `failed` or `no-alert-workflow` means the event is
    attempted, as R4 has it.
- **D4, a record from the future.** A record whose time is after the attempt's clock counts as
  old, so the event is sent. A clock stepped back can never silence a job event.
- **`paused` is exempt from D4, and that is pinned.** A paused record over a day old with no
  resume after it is still a repeat.

### Assertions (part 2140; restated cases keep their names and say "restated for section 6")

- **R5, restated (D2).** As section 5 describes, with the resumed row in a second strictly
  before the record's: the second `--pause R` is a repeat, with no `workflow run`. A variant has
  the resumed row written by hand in the record's own second, and gets one dispatch (D2's tie).
- **R6, restated (D2b).** `--pause R` dispatched, `--resume`, ledger.tsv made unreadable (mode
  200), `--pause R`: no dispatch. Then the record moved 61 minutes back and `--pause R`: one
  dispatch. The fixture checks the ledger cannot be read.
- **R8 (paused exempt from D4).** A dispatched paused record moved 25 hours back in alerts.tsv,
  no resumed row, the ledger aged past the hour, a tick: no dispatch.
- **R9 (no ledger).** `--pause R` dispatched, ledger.tsv removed, `--pause R`: no dispatch.
- **R10 (D4 keyed).** A job event with detail `X` dispatched, then the same kind with detail
  `X; still so since 10:00`: no dispatch. With the record 25 hours back: one dispatch.
- **R11 (D4 keyed).** Same kind, detail `A` dispatched, then detail `B` dispatched, then `A`
  again: no dispatch.
- **R12 (D4, future time).** A job record whose field 1 is an hour after the clock, then the
  same event: one dispatch.
- **Unchanged and deterministic:** 1720 A18, 2140 W2C D2a2, D2b and D2c must pass in every run.
  The builder runs 2140 and 1720 three times under each awk, and reports each count.
