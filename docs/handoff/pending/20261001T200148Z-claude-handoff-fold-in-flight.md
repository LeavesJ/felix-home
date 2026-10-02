### 2026-10-01 — a handoff fold already pushed is named at session start, so a second session does not fold the same sections

**Engine change, adversarial tier.** lib/handoff.sh, lib/maintenance.sh,
hooks/session-start, felix (cmd_maintenance), a new bin/handoff-in-flight,
templates/maintenance.tsv (comments), tests/run. Project data:
projects/felix/maintenance.tsv's `handoff` row. No escape or commission
table is touched, so `felix merge` lands it and the receipt does not move.

**Why.** The `handoff` upkeep row read "due" in every session while three
sections waited, and with about twenty sessions at once several folded
overlapping sections: #347, #351 and #377, of which only #377 landed. The
check made a stale fold fail rather than corrupt anything, so the cost was
work and queue slots.

**What changed (claude/handoff-fold-in-flight).**
- A maintenance check that passes and prints is naming work already in
  flight: the row reads `inflight`, holding what it printed, and is not due.
  A failing check is due whatever it printed. The check runs with
  `FELIX_HARNESS_DIR` set to the engine reading the table. No column was
  added: a sixth one changes maintenance.tsv's row in templates/schemas.tsv,
  an escape table, and would have stopped the merge for the founder.
- The session start adds `Already in flight, so not due: <name> on
  <holders>`, and `felix maintenance` shows the row as `in-flt`. The
  overnight stop, `felix next` and the pulse keep only `due`.
- `felix_handoff_in_flight` and `bin/handoff-in-flight` name a branch under
  main's remote whose marker is past main's and one of whose merge-bases with
  main holds main's marker. They use git only, with no gh and no network. A
  tip commit older than 48 h by committer time, or dated more than an hour
  ahead of the clock, counts as abandoned.
- The felix row's check is now `pending < 3 || "$FELIX_HARNESS_DIR/bin/handoff-in-flight" --within 48`.

**On real input (2026-10-01).** It named #386 (`claude/handoff-fold-1001`,
0cn, cut from 5772afac) and nothing else among 178 branches. The cost was
about 0.2 s of CPU, run only when three sections wait.

**Evidence.**
- Two blind authors wrote 108 assertions from the spec alone. On main, 76
  are red. Of the 32 that pass there, 28 guard behaviour the spec keeps
  (named `unchanged:`), 1 checks the fixture, and 3 read `due` only because
  main has no script, each paired with a red exit-code assertion.
- A three-lens review found 11 defects that a refuter could not dismiss.
  Four were behaviour; each got an assertion, red on the first version
  (2f39f73e) and green now:
  - a criss-cross with two merge-bases;
  - a ref pruned between listing and grep, which blanked the read;
  - a future-dated tip passing the bound;
  - a control byte breaking the session start's JSON.
  The other seven were overclaims in comments and the design note, now
  reworded.
- Section runners: the maintenance section with its new block, 83/83; the
  handoff section with its two new blocks, 96/96; the pipe lint, green. The
  full suite, the assertion record and the gate wait for the carrier's slot.

**Coordination.** The landing actor's final design (`design.md`, 2026-09-24)
keeps the fold as upkeep in v1. This lands nothing; it only names a fold
already pushed. docs/2026-09-24-handoff-sections.md records both.

**Open.**
- A fold not yet pushed is invisible, so two sessions starting within the
  same minutes can still both fold.
- Carried here: claude/handoff-check-relative-path (3 commits, its own
  pending section). handoff-check, lifecycle-check and obligations-check
  found their libraries after moving to the checkout top, so a relative call
  from a subdirectory failed. Its 3 assertions are red against main as a git
  checkout, for that reason (`cd: ../bin/..: No such file or directory`).
- handoff-check reads one merge-base, as this did before the review. In a
  criss-cross where git picks the base after main's fold, it refuses a fold
  that this names, until the 48-hour bound.
