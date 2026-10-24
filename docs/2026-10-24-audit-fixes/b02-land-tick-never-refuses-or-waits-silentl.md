# Audit fix b02: the land tick never refuses or waits silently, contract, 2026-10-24

Batch b02 of the 2026-10-24 audit: `engine/harness/lib/green-tick.sh`, `lib/green-install.sh`
(trampoline, install, status) and `docs/2026-10-15-land-on-green-contract.md`, which this amends and,
where they differ, overrides. B1, B2, ... are required behaviours and A1, A2, ... assertions; the
land-on-green contract's clauses are always written "contract G2", "contract A13". Read on origin/main
69b51a61 (0.49.307): green-tick.sh (479 lines), green-install.sh (237), the land-on-green contract
(512), cmd_merge (`felix`:1776-2175), `felix_merge_blockers` (`lib/escape.sh`:599-783),
`_felix_receipt_path` (`lib/verify.sh`:481), `felix_commission_receipt_path` (`lib/commission.sh`:637),
`felix_accepted_deploy_diff` (`lib/resolve.sh`:1830), `lib/pr-status-state.sh`:216-239, and the fixture
`tests/lib/land-on-green.sh` with parts 1280-1289.

## 1. Defects

Severities are the skeptics' corrected ones.

- **C011 (high, silent stall). A refusal stays final when its blocker clears without a new head.**
  `_gt_candidate` (green-tick.sh:375) skips felix merge whenever the PR's newest row is `refused` on the
  same head and `[main <sha>]`, whatever the blocker. Scenario: a PR is marked ready while its gate
  runs; the merge refuses "the tree changed since the receipt" (#450, 2026-10-19T09:09:55Z); the gate
  passes ~40 min later; the tick never retries or tells anyone, and a person merged it at 10:12:27Z. A
  commission re-stamp (#458), a `gh pr merge` network failure and "the working tree was edited while
  this ran" freeze a PR the same way, until main moves, which may be never if nothing else lands.
- **C001 (medium, silent stall). The deploy wait has no bound and no second word.** `_gt_deploy`
  (green-tick.sh:231-235) holds a deploy while `pgrep -f 'engine/harness/tests/run|gate\.sh'` matches
  anything (a hung or orphaned suite, `vim gate.sh`), writes one row and one notification, then nothing;
  meanwhile no PR lands (green-tick.sh:431). Scenario: an orphaned `tests/run` lives for days (memory
  10-22: 8 days) and landing stops with one banner that names no process. `gh` and `fetch` stops
  (green-tick.sh:418-427) have the same shape.
- **C097 (medium, machine-bound). One dead token anywhere stops all landing.** A bare `gh auth status`
  (green-tick.sh:418) exits 1 when any account on any host is broken. Scenario: a stale Enterprise login
  or an inactive second github.com account sits beside a working one; every `gh pr list --repo` would
  work, yet every tick stops. Reproduced by the skeptic with gh 2.102.0; the four real `gh` ledger rows
  were other, transient failures.
- **C082 (medium, silent stall). A hand engine merge strands landing until a hand deploy.** The
  trampoline (green-install.sh:129-135) reads origin/main's version without fetching and, when its entry
  is missing, runs nothing, so the in-engine deploy is unreachable. Scenario: a session's `felix merge`
  or the founder's GitHub merge lands an engine PR and anything fetches, or the tick fetches, defers its
  deploy for a running gate, and the next trampoline run reads the new main. Ledger 2026-10-22T21:32:45Z
  and 2026-10-23T01:47:22Z, both cleared by a hand `felix install`.
- **C083 (medium, naive). An entry at main's version with other bytes cannot be repaired, and every
  message names a remedy that does nothing.** `felix install --no-bump` leaves an existing entry in
  place (felix:624-648); the verify writes `deployed-unverified "diff:"` (green-tick.sh:263-264); the
  trampoline says "nothing runs until main is deployed from the home" (green-install.sh:147). Scenario:
  two PRs bump to the same version and the second lands; trampoline and every `felix merge` refuse from
  then on, and the way out is unprinted.
- **C100 (low, naive). The verify cannot see broken hooks, and the contract says it can.** It checks
  only `session-start`'s exit status (green-tick.sh:265-268), which is 0 with no output when
  `lib/resolve.sh` cannot load (reproduced); pre-tool and stop never run. Scenario: a BWK-only awk abort
  in a hook deploys "verified". Contract lines 40-41 say "G6's verify and pause cover" a broken deploy.
- **C104 (low, naive). The brakes carry no actor.** `--resume` is `rm -f paused` (green-tick.sh:474),
  `--pause` writes no row until a tick (green-tick.sh:79), `--install` and `--uninstall` write no row
  and notify nothing (green-install.sh:155-196). Scenario: the founder pauses with a reason, a session
  resumes, the next tick lands the PR he held, and the ledger shows no resume, actor or reason.

## 2. Required behaviour

Terms, used throughout:

- **Row, job row.** A row is one line of `land/ledger.tsv`: UTC `YYYY-MM-DDTHH:MM:SSZ`, event, PR, head,
  worktree, wall seconds, detail (contract G8); a job row has `-` as its PR.
- **Aged**: a row's first-column year moved back by one, as part 1280's `_lg_age` does; tests age rows
  only that way.
- **The tick** is `felix land --tick` run from the home. **The trampoline** is the script
  `felix land --install` writes, run with launchd's environment (the fixture's `_la_tramp`).
- **The gate receipt of a checkout W** is `$FELIX_HOME_DIR/state/gate/<id>`, where `<id>` is what
  `printf '%s' "$(cd W && pwd -P)" | git hash-object --stdin` prints: the path `_felix_receipt_path`
  gives and felix merge reads for W.
- **The commission receipt** is `$FELIX_HOME_DIR/state/commission/<name>`, `<name>` being the project
  directory's basename (`lgh` in the fixture): the path `felix_commission_receipt_path` gives.
- **The blocker block of felix merge's output.** Take the first line that is exactly `not merging`, skip
  the one empty line after it, and read up to the next empty line or the end. Each line is two spaces,
  the kind, spaces, the subject, spaces, the reason (cmd_merge's `'  %-11s %-22s %s'`). The kind is the
  line's first word, the subject its second. With no `not merging` line the block is empty.

### Refusals (C011; amends contract A13, A33)

- **B1. Class.** When the tick's felix merge run exits non-zero, the refusal gets one class:
  - *receipt*: exit 3, the block holds at least one line, and every line's kind is `unverified`, or
    `commission` with subject `receipt`;
  - *final*: exit 3 with any other block: any other kind, a `commission` subject other than `receipt`,
    or an empty block;
  - *hourly*: any status other than 0 and 3: cmd_merge's `die` refusals (judge, gh, usage, exit 1), its
    "moved" refusals (exit 4), and crashes.
- **B2. The refused row says what lifts it.** The detail is `<blocker> <clause> [main <sha>]`.
  `<blocker>` is chosen as today (contract G6: the first line that begins with two spaces, else the last
  line, cleaned). `<clause>` is exactly one of `(final until the head or main moves)`,
  `(tried again when a new gate or commission receipt is written)` or
  `(tried again an hour after this row)`. The detail still ends with
  ` [main <40 lowercase hex of refs/remotes/origin/main>]`, the suffix the stuck-PR page matches
  (`pr-status-state.sh`:218).
- **B3. Final.** When a PR's newest row is `refused` with the final clause on its current head and the
  current main, no tick runs felix merge for it, or writes a row for it, until its head or main moves,
  whatever the receipts hold and however old the row is. This is contract A13 as written.
- **B4. Receipt.** When a PR's newest row is `refused` with the receipt clause on its current head and
  main, and the PR passes every check before the refusal check (B8), the tick runs felix merge once more
  on the first tick at which its checkout's gate receipt, or the commission receipt, holds other bytes
  than it held just before the felix merge run that row records. A file absent then and present now has
  changed, and so has one present then and absent now. On a tick where neither has changed, no felix
  merge runs and no row is written.
- **B5. Hourly.** When a PR's newest row is `refused` with the hourly clause on its current head and
  main, felix merge runs once more on the first tick 3600 s or more after that row's time. Before that,
  nothing runs and nothing is written.
- **B6. Older rows.** A newest `refused` row on the current head and main whose detail carries none of
  the three clauses was written before this change, and is final as in B3.
- **B7. What a retry writes.** A retry that exits 0 writes `landed`, notifies `Felix: landed #<n>` and
  ends the candidate loop, as any landing does. A retry refused again writes a `refused` row every time
  (contract G6), classed anew, and notified only when its blocker, class or head differs from the PR's
  previous `refused` row (contract A6).
- **B8. Order.** Retries happen only for a PR that passes the checks run before the refusal check today
  (contract G4, G5, A3, A9, A12, A19, A23, A30). One that fails gets its `skip`, `founder` or `session`
  row and no felix merge.
- **B9. A missing record is unknown, not unchanged.** When the newest row is `refused` with the receipt
  clause but the tick holds no record of what the receipts held before that run (another engine wrote
  the row, or the record was lost), the tick runs felix merge once more and keeps a new record; the next
  tick, with nothing changed, runs nothing. Where the record lives is the implementation's: under
  `land/`, never in the ledger's columns, read only by the tick.

Why the reason for contract A13 still holds: only escape blockers write `escalated` rows, the
founder-interruption count. An escape is a final-class blocker, so no retry follows a refusal that held
one. Each PR costs says.log at most one `refused` row per receipt write, or one an hour.

### The gh check (C097; amends contract G2, A10)

- **B10.** The tick's gh precheck passes only when `gh auth status --hostname github.com --active` exits
  0; github.com is the only host `felix_repo_slug` reads. A broken token for another host, or for an
  inactive github.com account, does not stop the tick. When the check exits non-zero (a stale active
  account, no login, or a gh refusing either flag; the installed gh 2.102 lists both), the tick writes
  one `gh` row and lists no PR, deploys nothing and merges nothing, as today.
- **B11.** The `gh` row's detail begins `gh auth status` and contains `github.com`.

### Every wait is said again (C001; amends contract A4, A10, A14, A22)

- **B12. The deploy wait names what it waits on.** G7.1 is unchanged: `pgrep` gets `-f` as its own
  argument and the same pattern. When pgrep exits 0, the `deploy-owed` row's detail is
  `a gate or suite is running; matched <list>`, the list being `pid <p>` for each pid pgrep printed, in
  order, joined by `, `. Each pid may be followed by ` (<command>)`, the command as
  `ps -o command= -p <p>` prints it, cut to 80 bytes, left out when ps prints nothing. When pgrep exits
  anything but 0 or 1, the detail is `a gate or suite may be running: pgrep exited <n>`, with no list.
- **B13. A stop is said again each hour.** Two job rows are the same wait when their events are the same
  and their details agree up to the first `; ` (in full if there is none). The rule covers every
  deduplicated job row the tick writes: `gh`, `fetch`, `deploy-owed`, `stuck`, and `unresolved` written
  to FELIX_LAND_LEDGER. When the tick would write one:
  - if the newest job row is not the same wait, the row is written and notified, as today;
  - if it is the same wait and under 3600 s old, nothing is written or notified, even when the text
    after the first `; ` differs (other pids, say);
  - if it is the same wait and 3600 s old or older, one row is written and notified, with the detail
    `<the part before the first '; '>; still so since <T0>`, followed in B12's case by
    `; matched <list>` for this tick. `<T0>` is the time of the earliest row in the unbroken run of
    same-wait job rows that ends at the newest job row; PR rows do not break the run.

`paused` keeps its own hourly rule (contract G2).
- **B14.** A job row of another wait in between ends the run: the old wait's next row is a first row
  again, with no `still so since`.
- **B15. The trampoline too.** The trampoline's `deploy-owed` rows (contract A1, A24) and `unreadable`
  rows (A31) follow the same rule, each compared with the ledger's last row of any kind, as today, by
  B13's same-wait test. Within the hour nothing is written. At 3600 s or more, one more row and
  notification carry `; still so since <T0>`, `<T0>` being the earliest time in the trailing run of
  same-wait rows at the ledger's end. The trampoline still exits 1 and runs no engine; the `readable`
  row (A31) is unchanged.

### A hand merge deploys itself (C082; amends contract A1)

- **B16.** When main's version is V and `<cache>/<V>/harness/felix` does not exist, the trampoline
  checks four things before writing A1's "not installed" row:
  - (a) `git symbolic-ref HEAD` in the home prints `refs/heads/main`;
  - (b) `refs/heads/main` is an ancestor of `refs/remotes/origin/main` and not the same commit;
  - (c) the version H that `refs/heads/main` declares in `engine/.claude-plugin/plugin.json` has an
    executable `<cache>/<H>/harness/felix`;
  - (d) main's own `felix_accepted_deploy_diff`, loaded from origin/main's `lib/resolve.sh` as A1 loads
    it, returns 0 for `"$FELIX_HOME_DIR" refs/heads/main`.

When all four hold, it prints one line on stderr naming V and H and saying H's engine runs the tick that
deploys V, writes no ledger row, sends no notification, and runs
`exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE <cache>/<H>/harness/felix land --tick`,
so its status is that tick's. It writes no row because that tick writes its own (G7, B12-B13); a
trampoline row as well would alternate with them every five minutes and defeat both deduplications.
- **B17.** When any of (a)-(d) fails, or the check cannot be loaded or exits anything but 0, the
  trampoline writes A1's "not installed" row as today: one row (deduplicated as in B15), one
  notification, exit 1, no engine run.
- **B18.** A1 is otherwise unchanged: no fallback for an entry that is not executable or that differs,
  and no entry of any other version ever runs.
- **B19.** The tick B16 starts finds the deploy owed (contract G3), deploys, and merges nothing in that
  tick (A11). A later tick merges with main's entry.

### The differing entry is named truly (C083, partly; amends contract G7.4, A1)

- **B20.** When G7.4's first check (A21) finds the cache entry for main's version V is not origin/main's
  engine, and a directory `<cache>/<V>` existed before the tick ran `felix install --no-bump`, the
  `deployed-unverified` row (and `paused`, with the same reason) still begins `diff:`, and also says the
  entry existed before the install, contains the words `does not replace`, and names `<cache>/<V>`. When
  no such directory existed before, it reads as today.
- **B21.** A1's "differs" row keeps `differs from origin/main's engine` and `not main's engine`, adds
  that felix install does not replace an entry that exists (the words `does not replace`), names
  `<cache>/<V>`, and no longer says `deployed from the home`. Neither text contains `; `.

### The brakes leave rows (C104; amends contract G9)

`<id>` is CLAUDE_CODE_SESSION_ID, or `-` when that is unset or empty. Each row is a job row of seven
fields (G8).

- **B22.** `felix land --pause [reason]` writes `land/paused` as today (the reason, or `paused by hand`)
  and at once one `paused` row with detail `<reason>; by session <id>`, notified as `Felix: paused`. It
  exits 0. A tick within the hour writes no further `paused` row (G2).
- **B23.** With `land/paused` present, `felix land --resume` writes one `resumed` row with detail
  `the pause read: <its first line>; by session <id>`, notified as `Felix: resumed`, then removes the
  file and exits 0. With no such file it writes no row, notifies nothing and exits 0.
- **B24.** When `launchctl bootstrap` succeeds, `felix land --install` writes one `installed` row with
  detail `the job is armed: <plist path>; by session <id>`, notified as `Felix: installed`. A failed
  install writes no row and dies as today.
- **B25.** After its bootout and removals, `felix land --uninstall` writes one `uninstalled` row with
  detail `the job is disarmed: nothing lands unattended until felix land --install; by session <id>`,
  notified as `Felix: uninstalled`, whether or not anything was installed, and exits 0.

### The contract and the limits

- **B26.** In `docs/2026-10-15-land-on-green-contract.md`, the clauses B1-B25 change are edited in place
  and point here: G2's gh line, A1's "never runs ... another version", A10's last paragraph, A13, A33's
  "a session lands it", and G9's four brake commands. The sentence at lines 40-41, "What a present
  session adds is noticing a broken deploy, and G6's verify and pause cover that.", is replaced by one
  saying G7's verify covers a deploy that does not install or does not match main, and does not see a
  hook that fails open (roadmap step 12). Checks: `grep -c "G6's verify and pause cover that"` gives 0,
  `grep -c b02-land-tick` gives at least 1, and `wc -l` gives no more than 512.
- **B27.** `lib/green-tick.sh` stays under 500 lines (part 1280's G1 assertion). What does not fit goes
  into `lib/green-install.sh` (at most 500 lines), as the A23 checkout helpers did, and only past that
  into one new `lib/green-wait.sh`, sourced by `felix` beside the other two, outside the `lib/land*.sh`
  glob, also at most 500. No gawk-only awk builtin (part 1497). Everything runs under bash 3.2 and bash
  5.

## 3. What must not change

Every part named here must pass unedited.

- **Preflight, lock, paused** (one paused row an hour, a live lock holds, a dead one is taken, release
  on TERM): `1280-land-on-green-blind.sh` (G2), `1282-land-on-green-round-2-blind.sh` (A4, A5),
  `1283-land-on-green-round-3-blind.sh` (A15).
- **The gh precheck's failure path** (one row, nothing listed or merged; the stub fails every
  `auth status` form): 1280 (G2), 1283 (A10).
- **Candidate checks and their deduplicated rows**: 1280 (G4, G5), 1282 (A3, A6), 1283 (A9, A12),
  `1284-land-on-green-round-4-blind.sh` (A18, A19), `1287-land-on-green-round-7-blind.sh` (A30).
- **How felix merge is run** (main's entry, the matched worktree, no argument, three variables unset,
  one landing per tick, no worktree's engine) and **the refused detail** (first two-space line, else the
  last, tabs as spaces; B2's clause keeps its `has` checks true): 1280 (G6, G8).
- **Contract A13 for status-1 refusals** (not re-run at the same head and main; re-run once after either
  moves): 1283 (A13), 1282 (A6: a changed detail after main moves gives one new row and notification).
  The stub refuses with status 1, hourly under B1, and those parts never age a row, so they stay green.
- **The stuck-PR page's suffix** ` [main <sha>]`: `pr-status-state.sh`:218 and
  `1310-stuck-pr-page-states-blind.sh`, `1330-stuck-pr-page-review-blind.sh`,
  `1360-stuck-pr-page-last-ledger-row-blind.sh` (they seed their own rows).
- **The deploy path** (G3; `pgrep -f` as its own argument; "a gate or suite is running"; A2, A11, A14,
  A20, A21, A24, A26; a failed check as `deployed-unverified` naming it, `paused` with the same reason):
  `1281-land-on-green-deploy-blind.sh`, 1283 (A11, A14), `1285-land-on-green-round-5-blind.sh`,
  `1286-land-on-green-round-6-blind.sh`.
- **Rows written once** within the hour over two identical runs or ticks: 1283 (A10), 1282 (A1's
  `_la_owed`).
- **The trampoline, contract A1**: main's accepted entry runs; with main's entry missing and the home at
  origin/main no other version runs (1282 G9 review 1, `_lgr1_other`); one row per case, five distinct
  details holding `missing`/`not installed`, `execut`, `differ`/`not main`, `version`, `git` (1282);
  full ref names (1283 A8; 1284 A17, `refs/heads/main` taken as is).
- **The trampoline, contract A31** (`#!/bin/bash`, the read, `unreadable`/`readable`, recovery by the
  newest row's kind, `--install` rewriting the pair): `1288-land-on-green-round-8-blind.sh`,
  `1289-land-on-green-round-9-blind.sh`; both `_lg_reset` after `--install`, so B24's row never reaches
  their counts.
- **G9's commands** (exit codes, usage, `paused`'s content, `--status`): 1280, 1281; and 1280's last
  case, `--pause` then a tick giving exactly one seven-field row, which B22 keeps true because its row
  is a `paused` row and the tick then writes none.
- **The test library**: `tests/lib` files only define functions (`0006-the-lib-judges.sh`).

## 4. Assertions

"[control]" marks an assertion true before and after the fix; every other one is red on main today.

### Fixture for 1650

- `_lg_build amend`; worktree `b50` from `_lg_branch b50 notes/b50.md`, with `50<TAB><head>` appended to
  `$LG/shas` (both reused if present). Each case starts
  `_lg_reset; rm -f "$RC50" "$CC"; _lg_prs "$(_lg_pr 50)"; _lg_green 50`. felix merge's output is
  `$LGK/merge.b50.out`, its status `$LGK/merge.b50.rc`.
- `M50` counts felix.log rows whose directory is b50's and whose arguments are `merge`. `RC50` is b50's
  gate receipt and `CC` is `$LGH/state/commission/lgh`. "Rewrite" writes a line with a fresh counter.
- Outputs, blocker lines in cmd_merge's layout:
  - OUT-R, status 3: `not merging`, empty line,
    `  unverified  tree <pad> the tree changed since the receipt`, empty line,
    `Nothing here escapes the tree.`
  - OUT-C, status 3: the block `  commission  receipt <pad> the table set moved`, then an empty line,
    `Ask them to run, in order:`, an empty line, `  felix autonomy --allow commission`,
    `  felix commission`.
  - OUT-F, status 3: OUT-R's line plus `  evidence    notes/b50.md <pad> the change owes a test`.
  - OUT-E, status 3: one `  escape      write <pad> notes/b50.md: outside the tree`.
  - OUT-T, status 3: one `  commission  table <pad> projects/lgh/commissioning.tsv: unreadable`.
  - OUT-0, status 3: `not merging` and an empty line, nothing more.
  - OUT-G, status 1: `GraphQL: Something went wrong`, then
    `felix: gh pr merge failed, for the reason gh gave above. Nothing was merged.`
  - OUT-M, status 4: `not merging`, empty line,
    `  tree       edited under it, uncommitted or untracked`, empty line,
    `The working tree was edited while this ran.`

### Part 1650 assertions

- A1 (B1, B2). OUT-R, one tick: one `refused` row for 50 whose detail contains
  `(tried again when a new gate or commission receipt is written)`.
- A2 (B2) [control]. That detail begins `unverified` and ends with
  ` [main <sha of refs/remotes/origin/main>]`.
- A3 (B2). OUT-F gives `(final until the head or main moves)`.
- A4 (B2). OUT-G gives `(tried again an hour after this row)`, and so does OUT-M.
- A5 (B4) [control]. OUT-R, two ticks, receipts untouched: M50 is 1, one `refused` row.
- A6 (B4). OUT-R refused, then RC50 rewritten: the next tick makes M50 2.
- A7 (B4). The tick after, nothing touched: M50 stays 2.
- A8 (B4). Then RC50 removed (present then, absent now): the next tick makes M50 3.
- A9 (B4). OUT-C refused, then CC rewritten: the next tick makes M50 2, despite the two-space `felix`
  lines after the block.
- A10 (B4, B7). OUT-R refused, then the status set to 0 and RC50 rewritten: the next tick writes one
  `landed` row for 50 and one `Felix: landed #50` notification.
- A11 (B7). OUT-R refused, RC50 rewritten, the retry refused the same way: 2 `refused` rows for 50 and
  one `Felix: refused #50` notification.
- A12-A15 (B3) [control]. Refused, then RC50 and CC rewritten and rows aged, M50 stays 1: A12 OUT-F, A13
  OUT-E, A14 OUT-T, A15 OUT-0.
- A16 (B5) [control]. OUT-G, two ticks: M50 is 1.
- A17 (B5). OUT-G refused, rows aged: the next tick makes M50 2, the tick after leaves it 2.
- A18 (B5). OUT-M refused, rows aged: the next tick makes M50 2.
- A19 (B6) [control]. Seeded: one `refused` row for 50 at b50's head, detail
  `the receipt is stale [main <current main>]`, aged; RC50 and CC written. A tick leaves M50 at 0.
- A20 (B9). Seeded: one `refused` row for 50 at b50's head, detail
  `x (tried again when a new gate or commission receipt is written) [main <current main>]`, nothing else
  in `land/`. A tick makes M50 1; the tick after leaves it 1.
- A21 (B8) [control]. OUT-R refused, 50 relisted with label `felix:hold`, RC50 rewritten: a `skip` row
  for 50, M50 stays 1.
- A22 (B4, contract A13) [control]. OUT-R refused, one more commit on b50 (`_lg_more`), shas updated, 50
  relisted: the next tick makes M50 2.
- A23 (B3, contract A13) [control]. OUT-F refused, main moves (`_l3_commit`): the next tick makes M50 2.
- A24 (G8) [control]. Every row the part wrote has seven tab-separated fields.

### Fixture for 1660

- `_lg_build amend`. A wrapper over `$LGB/gh`, restored at the part's end: while `$LGK/gh-accounts`
  exists it answers `auth status` itself (logging its argv to gh.log as the stub does); otherwise it
  calls the stub. The table's rows are host, user, active (`yes`/`no`), token (`ok`/`stale`),
  tab-separated. It reads `--hostname H`, `--hostname=H` or `-h H`, and `--active` or `-a`; it considers
  the rows for H when H is given, and only active ones under `--active`; it exits 1 when no row is
  considered or any considered row is `stale`, else 0. That is gh 2.102's documented rule.
- `pgrep`: the stub numbers `$LGK/procs`'s matching lines `4%04d`. A wrapper exiting with
  `$LGK/pgrep.rc`'s status while that file exists is added if `$LGB/pgrep` does not already do so, and
  removed at the end. `fetch`: a `$LGB/git` wrapper fails `git fetch` while `$LGK/fetch.rc` exists, as
  1283's does, removed after use.
- A trampoline case first runs `_lg_land --install; _lg_reset`, then `_la_tramp`, whose output, stderr
  included, is `$LG/out.tramp`. `Vm` is `_l3_mainv` at the part's start. `S` is
  `LGX=(CLAUDE_CODE_SESSION_ID=s-1660)`.

### Part 1660 assertions

- A25 (B10). Accounts github.com/LeavesJ active ok and ghe.example.invalid/olduser active stale, PR 42
  green: one `landed` row for 42, no `gh` row.
- A26 (B10). github.com/LeavesJ active ok and github.com/oldwork inactive stale: 42 lands, no `gh` row.
- A27 (B10) [control]. github.com/LeavesJ active stale: one `gh` row, no `pr list` in gh.log, no merge.
- A28 (B10) [control]. An empty accounts table: one `gh` row, no merge.
- A29 (B11). A27's `gh` row begins `gh auth status` and contains `github.com`.
- A30 (B12). Main's entry removed; `procs` holds two matching lines, then one that does not match: one
  `deploy-owed` row beginning `a gate or suite is running`, containing `pid 40001` and `pid 40002` and
  not `pid 40003`.
- A31 (B12) [control]. pgrep.log holds `-f` as its own argument.
- A32 (B13) [control]. `procs` gains a third matching line and a tick runs: still one `deploy-owed` row
  and one notification.
- A33 (B13). Rows aged and T0 read as the row's time: the next tick writes a second row and
  notification, its detail beginning `a gate or suite is running; still so since <T0>` and containing
  `pid 40001`.
- A34 (B13). The tick after: still 2 rows.
- A35 (B14) [control]. A tick with `gh-auth.rc` 1 writes a `gh` row; the file removed, a tick runs: 3
  `deploy-owed` rows, the newest with no `still so since`.
- A36 (B12, B13). `pgrep.rc` 2: the row reads `a gate or suite may be running: pgrep exited 2`; aged,
  the next tick writes a second row containing `still so since`.
- A37 (B13). `gh-auth.rc` 1: one `gh` row, one notification; aged, the next tick gives 2 rows and 2
  notifications, the second row containing `still so since`.
- A38 (B13). `fetch.rc` 128: one `fetch` row; aged, the next tick gives 2, the second with
  `still so since`.
- A39 (B13). Skipped: no seam ages a live lock past 45 minutes, so `stuck` is not driven.
- A40 (B15). An untracked file under the home's `engine/harness/`; two trampoline runs: one
  `deploy-owed` row, one notification, status 1 both times [control]. Aged, a third run gives 2 rows and
  2 notifications, the second containing `still so since <T0>`, and no `land --tick`.
- A41 (B16). The home commits a bump to 9.65.0, pushes it, and resets its main back one commit to Vm's
  commit: on main, strictly behind, no 9.65.0 entry. The trampoline runs exactly one `land --tick`, from
  `$LGV/<Vm>/harness/felix`, exits 0, writes no `deploy-owed` row, sends no notification.
- A42 (B16). In A41, `out.tramp` names `9.65.0` and `<Vm>`.
- A43 (B16) [control]. In A41, that tick's felix.log columns 4-6 read `unset unset unset`.
- A44-A47 (B17) [control]. No `land --tick`, one `deploy-owed` row containing `not installed`, status 1,
  from: A44 A41's state with the home on branch `l60-side`; A45 A41's state plus one local commit on the
  home's main; A46 A41's state plus one extra file in `$LGV/<Vm>/harness`; A47 the home reset to
  origin/main.
- A48 (B18) [control]. A41's state plus a 9.65.0 entry whose felix is not executable: no tick from any
  entry, the row contains `execut`.
- A49 (B19) [control]. A41's state with 42 green: `_lg_land --tick` installs once, writes one `deployed`
  row, merges nothing; the next tick lands 42 through `$LGV/9.65.0/harness/felix`.
- A50 (B20). Main's entry present with one extra file, `install.taint` set, the home at origin/main: one
  `deployed-unverified` row beginning `diff:`, containing `does not replace` and
  `$LGV/<main's version>`; `paused` holds the same reason.
- A51 (B20) [control]. Main's entry absent, `install.taint` set: the `diff:` row does not contain
  `does not replace`.
- A52 (B21). The trampoline with main's entry holding one extra file: one `deploy-owed` row containing
  `differs`, `does not replace` and `$LGV/<main's version>`, not `deployed from the home`.
- A53 (B22). With S, `--pause "hold until I read #460"`: `paused` reads exactly that [control]; one
  `paused` row with detail `hold until I read #460; by session s-1660`; one notification titled
  `Felix: paused`.
- A54 (B22) [control]. A tick right after: still one `paused` row.
- A55 (B22). With `LGX=(CLAUDE_CODE_SESSION_ID=)`, `--pause x` writes a detail ending `; by session -`.
- A56 (B23). With S, after A53, `--resume`: one `resumed` row with detail
  `the pause read: hold until I read #460; by session s-1660`, one `Felix: resumed` notification, no
  `paused` file.
- A57 (B23) [control]. `--resume` with nothing paused exits 0 and writes no row.
- A58 (B24). With S, `--install` exits 0 and writes one `installed` row containing the plist's path and
  `by session s-1660`, with one `Felix: installed` notification.
- A59 (B25). With S, `--uninstall` exits 0 and writes one `uninstalled` row containing
  `by session s-1660`, with one `Felix: uninstalled` notification.
- A60 (B22-B25, G8). Every row from A53-A59 has seven fields and `-` as its PR.

## 5. Parts

- `engine/harness/tests/parts/1650-land-tick-retries-a-refusal-blind.sh`: B1-B9, A1-A24.
- `engine/harness/tests/parts/1660-land-tick-says-every-wait-blind.sh`: B10-B25, A25-A60.

Both are written blind from this document and the fixture library. Each opens with a `# >>>` marker and
a `printf` heading (as 1289), calls `_lg_build amend` so `--part` alone works, restores every stub it
wraps, leaves the home on main at origin/main with main's entry installed, and stays under 500 lines;
`tests/run` gains their lines after 1600's. Their names reach `assertions.tsv` only through the record.
Bash 3.2 rules hold (no `case` in `$( )`, `[0123456789]`, `LC_ALL=C`). B26 and B27 are checked by their
commands, not by a part.

## 6. Out of scope

- **C001: narrowing the process match** to processes running the home's engine. Contract G7.1 and A14
  chose the wide match: every project's gate runs through the home's engine (`~/.local/bin/felix` → the
  home; cmd_gate, `felix`:740-772), so a pull under any gate rewrites what it runs, a narrower pattern
  risks missing a real gate, and A14 reads doubt as "running". B12 makes a false match (`vim gate.sh`)
  visible and B13 bounds the silence.
- **C083: repairing the entry automatically** (move it aside, install again). That depends on how
  `claude plugin install` treats a listed version whose directory is gone, which nobody has measured,
  and it pulls a live engine out from under sessions' hooks; it belongs with roadmap step 12 (rollback).
  This batch makes the rows true (B20, B21). felix merge's "Run felix install on main" (`felix`:1898)
  and gate.sh's `installed` remedy make the same false claim from cmd_merge's judge block and
  `projects/felix/gate.sh`, outside this batch's files.
- **C083: one 30-minute watchdog over landing and deploy** is by design (contract G7); the skeptic found
  it adds to the risk but is no defect alone.
- **C100: the stronger verify** (the deployed pre-tool on a deny-row payload expecting exit 2, stop on a
  dirty checkout, `session-start` output required) is roadmap step 12; the fixture's hooks are silent
  stubs that every deploy assertion in 1281-1286 stands on. B26 corrects only the overclaiming sentence.
  felix merge accepting a `--quick` receipt is direction §5 item 5.
- **C104: refusing `--resume` over a hand pause.** Sessions pause and resume by routine (memory
  land-on-green-decided-2026-10-15); holding one PR uses the A30 labels. The stuck-PR page calling a
  green PR "ready / lander" while the lander is paused (`pr-status-state.sh`:240) is the skeptic's
  separate finding.
- **C011: re-checking the receipt in the tick** with `felix_verify_current` would run the probes every
  tick for every refused PR; B4's change trigger leaves the judging to felix merge.
- **C082: deploying from cmd_merge** after an engine merge: the merge boundary's code, which the
  founder's GitHub merges never reach. B16 covers both. Nor does `--status` say the installed trampoline
  is stale; section 7 says who re-arms it.

### Not fixed: not a defect

- **C001 (a), "matching another project's gate.sh is a false positive."** It is inside G7.1's reason:
  `~/.local/bin/felix` is a symlink to `/Users/a14808/Documents/Felix/engine/harness/felix` and cmd_gate
  runs `"$proj/$gate"` from the home (`felix`:740), so `_gt_deploy`'s `git pull --ff-only` and
  `felix install` (green-tick.sh:250-258) change the code under any running gate. Both skeptics refuted
  it. **"The A2 wait buys no safety"** is false for the same reason.
- **C001, "3-4 h suites leave no idle moment."** Overstated: records and gates take 40-90 min, and in
  five days the only gate wait lasted 61 min (2026-10-19T18:16:34Z-19:17:46Z) while the only open PR,
  #425, conflicted. The unbounded case left is fixed by B12 and B13.

## 7. Founder PR

None: no `.github/workflows` file, deny or escape row, commission grant or publication changes.

One step after landing is the founder's. The installed job keeps the trampoline it was installed with,
so B15-B18 and B21 do not run on this Mac until `felix land --install` is run again in the home, which
contract G9 makes his yes in chat (installing is persistent configuration):
`cd /Users/a14808/Documents/Felix && felix land --install`, after the deploy that carries this batch.

## 8. Red

Run on 69e1a9f6 before any engine code changed: parts 1650 and 1660 alone under bwk (macOS awk, bash
3.2). **33 assertions failed**: 12 of 1650's 24 (A1, A3, A4, A6-A11, A17, A18, A20) and 21 of 1660's 36
(A25, A26, A29, A30, A33, A34, A36-A38, A40-A43, A50, A52, A53, A55, A56, A58-A60). A39 is skipped. The
26 that passed are exactly the assertions marked [control], and none is vacuous: each reads a count that
a run or a row would have raised, and the 11 fixture controls passed.

- 1650, already true today because every `refused` row on the same head and main is final: A5, A12-A16,
  A19, A21. True because a new head or a moved main already re-runs it: A22, A23. True because the
  detail's layout and the seven fields are unchanged: A2, A24.
- 1660, controls the fix must keep: a stale active account, or none, still stops the tick (A27, A28);
  pgrep is given `-f` (A31); the same wait inside the hour is one row (A32, true today as the detail has
  no pid list to differ); a `gh` row between two waits (A35, counted relative to the rows before it); no
  fallback entry (A44-A48); the deploy chain (A49, A51); a tick after `--pause` leaves one `paused` row
  (A54: today the tick writes it) and `--resume` with nothing paused writes none (A57).

