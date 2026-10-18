### 2026-10-18: the lost-work page, `felix monitor`, and three inventory fixes (Phase 0b step 6)

**Engine 0.49.299 (placeholder; this branch, `claude/lost-work-page`, cut from
`claude/stuck-pr-page` at 6627e2ba, which sits on origin/main e95e5d3b).** It
lands after step 5 (.298) and needs step 5 merged first. The contract is
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
- 0590 and 0600: four `felix monitor` calls now say `felix monitor --log`
  (contract B9.40); no name or expected value changed.
- 0920 N7: two assertions renamed and re-expected, because A1 moves a branch
  another pushed branch holds from undecided to `carried`. A record comparison
  will show two names gone and two added.
- 0870: `lib/inventory-chips.sh` is included in the host adapter's lints.
A parts-alone smoke (0001-0005 plus 0590, 0600, 0810, 0860-0920, 0940,
0990-0998, 1020, 1040, 1090, 1300-1350, 1400-1440) gave 1891 passed, 8 failed,
1 skipped. The 8 failures fail identically on the pre-build export: 7 in
0590/0600 come from running those parts without the parts before them, and one
is step 5's (below). **The full suite, `--record-assertions`, red and the gate
were not run on this branch**: it has no landing slot yet.

**Review.** One Opus review (`review.md`, `review-disposition.md` in the same
audit folder). The blocker (collapsed `proposed` and `handoff` said a complete
0 when unread) and both majors (two pushed names at one commit carried each
other; B9.2 left red by a fixture that never pushed its branch) are fixed in
85ad1829, with the contract amended in d3a311c4. Three minors were fixed: an
awk `-v` that expanded backslashes in land's error line, `GIT_DIR` making the
page refuse to run, and the upstream exclusion in A1.

**Open.**
- **Step 5's A111.** Part 0940's "inventory A111" fails on this branch and on
  `claude/stuck-pr-page`: `lib/pr-status.sh:27` sources and
  `lib/pr-status-gh.sh:9` names `inventory-gh.sh`. It is step 5's to settle
  before its record; this branch inherits the outcome. `lib/lost-work.sh` names
  none of them.
- **Test gaps left (review finding 7).** Nothing pins S1-S3's "modified after
  the proposal", S1's exclusion of the proposer's file, or the page's scratch
  cleanup after a signal. Part 0940's library lists do not name
  `inventory-chips.sh`. These need a blind round.
- **`tests/run` is at 497 lines.** The next part added will need the driver
  split or its part list moved.
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

**Next.** At "you are next": merge main (with step 5), set the version above
main, run `tests/run --record-assertions` and red, then `felix gate`, and open
the PR. Risk-red: new libs (`lost-work.sh`, `inventory-chips.sh`) and lib edits.
