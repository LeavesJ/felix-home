### 2026-10-23: helper worktrees placed apart, in `felix inventory` and on the lost-work page (step 6 follow-up)

**Engine 0.49.307 (this branch, `claude/helper-worktrees-apart`, on origin/main
ed32bcaa).** It closes the step 6 note's open item "Noise the page shows"
(`20261018T125033Z-claude-lost-work-page.md`). The contract is Part C of
`docs/2026-10-18-lost-work-page-contract.md`, with its review round in C8.
Picked by the session as the next inventory step when the founder, mid-migration
to the new laptop, asked for "something somewhat easy" that builds on the
inventory.

**Why.** On felix-home at ed32bcaa the page showed 4 blocked sessions, and 3 of
them were workflow agents that died 5 to 11 days ago, still waiting on
`StructuredOutput`. Of its 75 rows of work that never reached a PR, 10 were
subagent or workflow worktrees (`agent-<hex>`, `wf_<id>-<n>`) holding blind
assertions their spawning session had already used. The inventory spec already
says a subagent's question or pending call is not the session's.

**What changed.**
- **The inventory's `helper` state.** A worktree or orphan row holds `helper`
  when its name has a helper's form and the host records name the session that
  spawned it, which is exactly when the detail says `spawned by session`. It is
  a placement mark: printed after `landed` and before `possible-duplicate` and
  the unknowns, never a headline, and never a bar to `landed`. A helper's
  name whose records were not searched (`--no-host`, or a records root the run
  cannot enter) gives `unknown:helper`, last.
- **The host adapter.** `felix_inv_host_dir` prints a seventh field (yes, no or
  unknown), and `felix_inv_host_helper_form` holds the name rule, read by name
  alone. The core never reads the name or the detail text to decide it.
- **`felix inventory`'s view.** Helper rows that would be listed go to a
  section `in helper worktrees  <n>` after the temporary one, and are listed
  nowhere else. Live and landed helpers stay in the last line's counts.
- **`felix monitor`.** A group `helper`, right after `hazard` in B3's order,
  collapsed to `helper worktrees <n>` after `running`. It is incomplete when
  sessions were not read, or when a row carries `unknown:helper`. That makes 17
  summary rows per repository; there were 16. A row with `unknown:helper` stays
  in its own group, because it is not known to be a helper.
- **The review round (C8).** The core split the adapter's line with a tab as
  IFS, and a tab is IFS whitespace. With the seventh field, a line with one
  empty field (a session file named `.jsonl`) passed the six-field check
  shifted, and turned a blocked session into a question with an epoch as its
  owner. The line is now read by position, and an empty owner reads
  `unknown`. A worktree that is both temp and helper shows `helper` in the
  temporary section.

**Measured on felix-home** (`--no-gh`, by the implementer, on this tree): 17
summaries, `helper` complete 14, `blocked` 1 (was 4), `quiet` 4 (was 5).
`felix inventory` lists 13 rows under `in helper worktrees`. The 14th, an
orphan holding nothing unique, is counted in the last line.

**Tests.**
- Three new parts, each written blind from the contract by an Opus author who
  never read the inventory or page code.
- 1570: 41 assertions, C5 items 1-13, inventory and view.
- 1580: 19 assertions, items 14-18, the page.
- Red on 60c6027a, before the build: 32 of the 60 failed. Of the 28 that
  passed, the controls held, and 7 were explained as vacuous or already true.
- 1585: 14 assertions for C8. Red on 2002827b, before the fixes: 5 failed,
  every one a fixed-behaviour assertion.
- Restated parts, counts and group lists only: 1470, 1480, 1490 and 1495
  (16 summaries became 17, 32 became 34), plus 1470's own copies of the group
  order and B4's table.
- Alone, under macOS awk and under gawk 5.4.1, each part reached its end with
  0 failed: 1570-1585 (then numbered 1550-1565), 1450-1497, 0870-0940, 1040 and 1070. 0870 kept its 1
  skip.
- The record at 0.49.307, on a933c40b: 13877 passed, 0 failed, 25 skipped,
  the same skip count as #455's record, so the signal cases ran. The manifest
  gained 86 names and lost 12, all 12 being the restated count names; it now
  holds 13902. Red against origin/main ed32bcaa (0.49.306): 52 failed, every
  one this branch's. 37 are blind Part C and C8 assertions, and 15 are the
  restated count assertions.
- The parts were then renumbered, with no content changed. They had been
  1550, 1560 and 1565, which `claude/direction-read-first` (#452) already
  holds.
- `felix gate` runs in this worktree on the commit that carries this note.
  Its result is in the PR, because a note committed after the gate would
  change the tree the gate's receipt names.

**Review.** Two Opus reviews, read-only: one asked for a smaller design, one
for an input that defeats it.
- The simplification lens found the design already small, with no unreachable
  branch.
- Its four minors are fixed in C8: the contract's sentence on `unknown:helper`
  and `landed`, the temporary section's `helper`, a redundant call, and two
  comments.
- The defeat lens found the major above, confirmed on a fixture against
  origin/main.

**Open.**
- **An unreadable records root still reads `sessions read`.** With
  `~/.claude/projects` at mode 000, the `sessions` cover row says `read` and
  the owner says `-`: inventory spec §5.2's "unread is unknown" does not hold
  there. This predates Part C. Only the helper field answers `unknown` in that
  case. The blind author found it (C5.6).
- **The other open items of the step 6 note stand:**
  - test gaps from review finding 7;
  - no PR titles on the page;
  - S3 unobserved;
  - `handoff` with an `unknown` default cover row.
- **`tests/run` is at 497 lines.** Part 1040 allows 500, so the next part
  needs the driver's part list moved.

**Next.** Open the PR at 0.49.307. It touches no founder or escape path, so the
land job merges it on green CI and the carrier deploys after the merge.
Risk-red: lib edits.
