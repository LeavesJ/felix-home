### 2026-10-18: the lost-work page, `felix monitor`, and three inventory fixes (Phase 0b step 6)

**Engine 0.49.301 (placeholder, set at "you are next"; this branch, `claude/lost-work-page`, cut from
`claude/stuck-pr-page` at 6627e2ba; origin/main 96074341, step 5 as #449 at
0.49.298, merged in at 237439dc).** The
carrier's order on 2026-10-18: gate friction C .298, step 5 with 3f .299, #446
.300, then step 6 about level with gate friction D, from .301 by
gate-readiness. The contract is
`docs/2026-10-18-lost-work-page-contract.md`: Part A changes `felix inventory`,
Part B adds the page.

**What it is.**
- `felix monitor [--tsv] [--repo DIR]... [--no-gh] [--no-host] [--days N]
  [--live MIN] [--blocked MIN]` prints the lost-work page. It is a read-only
  view over `felix inventory --tsv` and `felix land --prs --tsv`, run as child
  processes one repository at a time. What needs the founder is listed first:
  hazards, blocked sessions, open questions, work that never reached a PR, PRs
  waiting on the founder, a session or the lander, then PRs and rows not
  decided. Running, carried, landed, handoff and already-proposed work is
  collapsed to counts. The page writes nothing (no `state/monitor.html`),
  prints no command and acts on nothing.
- **Unknown is said, never 0.** Every group has a count and a completeness. An
  incomplete group says `at least <n>`, or `unknown` when it has no rows, with
  the reason (the cover row that was not read, or how many rows were not
  decided). `--tsv` prints nine columns: the group, then the source row's own
  eight, plus 16 summary rows per repository.
- `felix monitor --log [--open] [--watch] [--every N]` is the old HTML page,
  unchanged; each log option implies `--log`. Mixing page and log options, or
  an unknown argument, is usage (exit 2).

**Inventory fixes (Part A).**
- A1, `carried`: a branch, remote or worktree whose tip a pushed branch of
  another name or an open PR's head reaches is `carried by #<n>` or
  `carried by origin/<b>`, naming only the outermost carriers, and is no
  longer `unproposed` or `pr-closed-unlanded`. Remote rows, and local rows
  whose own name or upstream stands at their tip on origin, need strict
  descent, so two pushed names at one commit never carry each other.
- A2: chips proposed through `start_session` with `initiation`
  `own_initiative` are read. A proposal whose result made no card (denied) is
  no row; one with no result recorded is `unknown:chip-unstarted`. A
  `start_session` card 168 hours old says `card expired`.
- A3: "started" is S1 (the prompt, read past the `Background ... Task:` frame
  and past a reminder item that ends in blank lines), S2 (a session titled
  with the chip's title), or S3 (a `start_session` call naming the proposal id).
  The reminder fix in the awk `human()` also corrects `question`.
- A4: a failed pending-section listing adds `unknown:handoff-pending` to the
  `default` cover row.

**Measured on felix-home (contract §B10).** Before: 62 `chip-unstarted` rows,
35 of them started (the reminder-item bug) and 5 denied proposals; 27 of 66
unproposed, closed or undecided rows carried. After, the page at d3a311c4 run on
`~/Documents/Felix` with gh (origin/main 1c5ca0d0): exit 0 in 2 min 58 s; 24 unstarted chips, 78 rows that never reached a PR, 4 blocked
sessions, at least 4 open questions (2 rows not decided), 4 PRs waiting on a
session, carried 19, landed 458.

**Tests.** Five new parts, sourced before 9990: 1400 (A1), 1410 (A2, A3), 1420
(the page's groups, TSV, read-only, filter), 1430 (unknown readings, log page,
usage, exit) and 1440 (the review round). 1400-1430 hold 145 assertions written
blind from the contract before any implementation (Opus); on the pre-build
tree they gave 21 passed and 124 failed, the 21 being fixture controls and two
pins of the old `--log` behaviour (evidence:
`audits/2026-10-18-lost-work-page/red-evidence.md` under the memory root).
1440 holds 21 assertions for the review's findings, shown red before each fix.
Changed existing parts:
- 0590 and 0600: six `felix monitor` calls now say `felix monitor --log`
  (contract B9.40); no name or expected value changed. Two of them are in
  0600's capabilities block (#443), which reached this branch with the merge
  of main and failed three assertions until restated.
- 0920 N7: two assertions renamed and re-expected, because A1 moves a branch
  another pushed branch holds from undecided to `carried`. A record comparison
  will show two names gone and two added.
- 0870: `lib/inventory-chips.sh` is included in the host adapter's lints.
A parts-alone smoke (0001-0005 plus 0590, 0600, 0810, 0860-0920, 0940,
0990-0998, 1020, 1040, 1090, 1300-1360, 1400-1440) on the merge with main, at
ff376654, gave 2208 passed, 10 failed, 1 skipped. Seven of the failures are in
0590/0600 and fail the same way on the pre-build export: those parts need
helpers (`_stage`, `_reset`, `PLAIN`) from parts the smoke does not run. The
other three were the capabilities block's bare `felix monitor`, restated in
5ac72182; 0600 alone then gave 259 passed and 5 failed, all five of the
block's monitor assertions passing and the five failures the alone-only ones.
The carrier's ruling on those: if they still fail alone on main with C, that
is a C4 gap for row 0, not this branch's.
B9.2 and A111, which failed before the merge, now pass. **The full suite, `--record-assertions`, red and the gate
were not run on this branch**: it has no landing slot yet.
The carrier's two record seams were checked on 1400-1440. No name starts with a
non-ASCII byte. Two names carried what the engine printed (B9.26's row count,
and B9.30/31's "at least N" for work that never reached a PR), so a red tree
would name assertions the record lacks. ff376654 makes both fixed strings and
moves the count into `bad`'s detail; the expected values are unchanged.

**Review.** One Opus review (`review.md`, `review-disposition.md` in the same
audit folder). The blocker (collapsed `proposed` and `handoff` said a complete
0 when unread) and both majors (two pushed names at one commit carried each
other; B9.2 left red by a fixture that never pushed its branch) are fixed in
85ad1829, with the contract amended in d3a311c4. Three minors were fixed: an
awk `-v` that expanded backslashes in land's error line, `GIT_DIR` making the
page refuse to run, and the upstream exclusion in A1.

**Open.**
- **Step 5's A111, settled by the carrier on step 5 and merged in.** Part
  0940's "inventory A111" failed on `claude/stuck-pr-page`:
  `lib/pr-status.sh:27` sources and `lib/pr-status-gh.sh:9` names
  `inventory-gh.sh`. The carrier restated A111 on step 5 (spec v2 R12): those
  two files may name `inventory-gh.sh` and nothing else of the inventory. Main
  at 96074341 carries it, with R11 and slot 3f, and this branch merged it at
  237439dc; `lib/lost-work.sh` names none of them and needs no change.
- **Test gaps left (review finding 7).** Nothing pins S1-S3's "modified after
  the proposal", S1's exclusion of the proposer's file, or the page's scratch
  cleanup after a signal. Part 0940's library lists do not name
  `inventory-chips.sh`. These need a blind round.
- **The parts do not yet run alone, which C (#444) requires (its C4).** 1410,
  1420, 1430 and 1440 call 1400's `_lw_*` helpers and read the fixture 1400
  builds (`LW`, `LW_F`, `LWC`, `LWM`, `LWT`, `LWX`, `LWL`); 1430 also reads
  1420's page fixture (`PG`, `PGR`, `LWW`, `LW_HP`, `LW_HEAD`, `LWK`). None
  uses step 5's `_sp_*`. After C lands and main is merged: move the helpers
  and both fixtures into `tests/lib/lost-work.sh` in C's form (definitions
  only, a `_lost_work_vars`, an idempotent `_lw_build [page]` each part
  calls), add its one driver line, and run each part alone. C frees about 30
  driver lines, so the 5 parts and 1 lib line fit.
- **`tests/run` is at 478 lines, sourcing 173 parts.** A few more parts will
  need the driver split or its part list moved.
- **Noise the page shows.** Subagent and workflow worktrees (`agent-*`,
  `wf_*`) holding unpushed blind branches make up a large share of "work that
  never reached a PR" on felix-home. A group for helper worktrees ("spawned by
  session") is a candidate next refinement.
- **No PR titles.** Step 5's TSV has no title column, so PR lines show number,
  state and detail only.
- **Unobserved.** S3 has no example in the records yet, so it counts any
  result. The seven-day card expiry is what the desktop's result text says.
- `handoff` is not made incomplete when the `default` cover row is merely
  `unknown` (the listing then comes from HEAD, as before). That is one
  condition in `calc()` in `lib/lost-work.sh` if it should.

**Next.** At "you are next" from the carrier, and not before: merge main again
if it has moved, set the version the carrier gives, run
`tests/run --record-assertions` and red, run `engine/harness/bin/schema-check`,
then `felix gate`, and open the PR. Risk-red: new libs (`lost-work.sh`, `inventory-chips.sh`) and lib edits.
