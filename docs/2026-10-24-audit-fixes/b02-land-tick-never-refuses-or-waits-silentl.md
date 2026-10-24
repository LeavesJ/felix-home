# Audit fix b02: the land tick never refuses or waits silently, contract, 2026-10-24

Batch b02 of the 2026-10-24 audit. It covers `engine/harness/lib/green-tick.sh`,
`engine/harness/lib/green-install.sh` (the trampoline, install and status) and
`docs/2026-10-15-land-on-green-contract.md`. It amends that contract. Where the two
differ, this document wins. In this document B1, B2, ... are the required behaviours
and A1, A2, ... are the assertions. The land-on-green contract's own clauses are
always written "contract G2" or "contract A13", so they never clash with an assertion
number.

Read on origin/main at 69b51a61 (0.49.307): `lib/green-tick.sh` (479 lines),
`lib/green-install.sh` (237), the land-on-green contract (512),
cmd_merge (`felix`:1776-2175), `felix_merge_blockers` (`lib/escape.sh`:599-783),
`_felix_receipt_path` (`lib/verify.sh`:481), `felix_commission_receipt_path`
(`lib/commission.sh`:637), `felix_accepted_deploy_diff` (`lib/resolve.sh`:1830),
the stuck-PR page's ledger reading (`lib/pr-status-state.sh`:216-239), and the test
fixture `tests/lib/land-on-green.sh` with parts 1280-1289.

## 1. Defects

Severities are the skeptics' corrected ones.

- **C011 (high, silent stall). A refusal stays final even when its blocker clears
  without a new head.** `_gt_candidate` (green-tick.sh:375) returns before `felix
  merge` whenever the PR's newest row is `refused` on the same head and the same
  `[main <sha>]`, whatever the blocker was. Scenario: a session marks its PR ready
  while its local gate still runs. The tick's merge refuses with "the tree changed
  since the receipt" (#450, 2026-10-19T09:09:55Z). The gate passes about 40 minutes
  later. The tick never tries again and tells no one. A person merged #450 by hand at
  10:12:27Z. A commission re-stamp (#458), a `gh pr merge` network failure and "the
  working tree was edited while this ran" freeze the PR the same way. If nothing else
  lands, main never moves and the freeze never lifts.
- **C001 (medium, silent stall). The deploy wait has no bound and no second word.**
  `_gt_deploy` (green-tick.sh:231-235) holds a deploy while `pgrep -f
  'engine/harness/tests/run|gate\.sh'` matches anything. That match covers a hung or
  orphaned suite, or `vim projects/felix/gate.sh`. It writes one `deploy-owed` row
  with one notification and then nothing, and while the deploy is owed no PR of any
  kind lands (green-tick.sh:431). Scenario: an orphaned `tests/run` lives for days
  (memory, 10-22: an orphan held a core for 8 days). Landing stops for its whole
  life, and the only trace is one banner reading "a gate or suite is running", which
  names no process. The `gh` and `fetch` stops (green-tick.sh:418-427) have the same
  shape: one row, then silence.
- **C097 (medium, machine-bound). One dead token anywhere stops all landing.** The
  tick runs a bare `gh auth status` (green-tick.sh:418). gh exits 1 when any account
  on any host has a broken token. Scenario: a stale GitHub Enterprise login, or an
  inactive second github.com account, sits beside a working one. Every `gh pr list
  --repo` call would succeed, yet every tick stops at the precheck. The skeptic
  reproduced both shapes with gh 2.102.0. The four real `gh` rows in the ledger were
  other, transient failures.
- **C082 (medium, silent stall). An engine merge made by hand strands landing until
  someone deploys by hand.** The trampoline (green-install.sh:129-135) reads
  origin/main's version without a fetch. When that version's cache entry is missing,
  it runs nothing, writes one deduplicated row and stops. The in-engine deploy is
  never reached. Scenario: a session lands an engine PR with `felix merge`, or the
  founder merges an escape PR on GitHub, and any process fetches. A second path:
  the tick itself fetches, then defers its deploy because a gate is running, and the
  next trampoline run reads the new main. Ledger: 2026-10-22T21:32:45Z (0.49.305)
  and 2026-10-23T01:47:22Z (0.49.306), each cleared by a hand `felix install`.
- **C083 (medium, naive). A cache entry at main's version that holds other bytes
  cannot be repaired, and every message points to a remedy that does nothing.**
  `felix install --no-bump` leaves an existing entry in place (felix:624-648). The
  verify then writes `deployed-unverified "diff: ..."` (green-tick.sh:263-264). The
  trampoline's "differs" row says "nothing runs until main is deployed from the
  home" (green-install.sh:147), and deploying from the home changes nothing.
  Scenario: two PRs both bump to the same version. The second lands, and from then
  on the trampoline and every session's `felix merge` refuse. The only way out,
  removing the entry and installing again, is printed nowhere.
- **C100 (low, naive). The post-deploy verify cannot see broken hooks, and the
  contract says it can.** The verify pipes a stub payload to the home's
  `session-start` and checks only its exit status (green-tick.sh:265-268).
  `session-start` exits 0 with no output when `lib/resolve.sh` cannot load (the
  skeptic reproduced this), and neither pre-tool nor stop is ever run. Scenario: a
  BWK-only awk abort in a hook lands on green and deploys "verified". Contract lines
  40-41 still claim that "G6's verify and pause cover" noticing a broken deploy.
- **C104 (low, naive). The land brakes carry no actor.** `--resume` is only `rm -f
  paused` (green-tick.sh:474). `--pause` writes no row until the next tick
  (green-tick.sh:79). `--install` and `--uninstall` write no row and send no
  notification (green-install.sh:155-196). Scenario: the founder pauses with a
  reason, a session resumes, and the next tick lands the PR he was holding. The
  ledger shows no resume, no actor and no reason, and an uninstall stops landing
  without a notification.

## 2. Required behaviour

Terms, used throughout:

- **Ledger, row, job row.** A row is one line of `land/ledger.tsv`: UTC time
  `YYYY-MM-DDTHH:MM:SSZ`, event, PR, head, worktree, wall seconds, detail (contract
  G8). A job row is a row whose PR column is `-`.
- **Aged.** A row is aged by moving the year in its first column back by one, as
  part 1280's `_lg_age` does. A test ages a row only that way.
- **The tick.** The tick is `felix land --tick` run from the home.
- **The trampoline.** The trampoline is the script `felix land --install` writes,
  run with launchd's environment (the fixture's `_la_tramp`).
- **The gate receipt of a checkout W.** The file
  `$FELIX_HOME_DIR/state/gate/<id>`, where `<id>` is printed by `printf '%s' "$(cd
  W && pwd -P)" | git hash-object --stdin`. This is the path `_felix_receipt_path`
  prints, and the path felix merge reads for W.
- **The commission receipt.** The file `$FELIX_HOME_DIR/state/commission/<name>`,
  where `<name>` is the project directory's basename (`lgh` in the fixture). This is
  the path `felix_commission_receipt_path` prints.
- **The blocker block of felix merge's output.** Take the first line that is exactly
  `not merging`, skip the one empty line after it, and read up to the next empty line
  or the end of the output. Each line in the block is two spaces, then the kind,
  spaces, the subject, spaces and the reason (cmd_merge's `'  %-11s %-22s %s'`). The
  kind is the line's first word and the subject its second. A missing `not merging`
  line is an empty block.

### Refusals (C011; amends contract A13, A33)

- **B1. Class.** When the tick's felix merge run exits non-zero, the tick sorts the
  refusal into one of three classes:
  - *receipt*: the run exited 3, the block holds at least one line, and every line's
    kind is `unverified`, or `commission` with subject `receipt`;
  - *final*: the run exited 3 with any other block, meaning any other kind, a
    `commission` subject other than `receipt`, or an empty block;
  - *hourly*: the run exited with any status other than 0 and 3. That covers
    cmd_merge's `die` refusals (judge, gh, usage, exit 1), its "moved" refusals
    (exit 4), and crashes.
- **B2. The refused row says what lifts it.** The detail is `<blocker> <clause>
  [main <sha>]`. `<blocker>` is chosen as today (contract G6: the first line that
  begins with two spaces, else the last line, cleaned). `<clause>` is exactly one of:
  - `(final until the head or main moves)`;
  - `(tried again when a new gate or commission receipt is written)`;
  - `(tried again an hour after this row)`.

  The detail still ends with ` [main <40 lowercase hex of refs/remotes/origin/main>]`.
  The stuck-PR page matches that suffix (`pr-status-state.sh`:218).
- **B3. Final.** Suppose a PR's newest row is `refused` with the final clause, on its
  current head and the current main. No tick runs felix merge for it again, and no
  tick writes a row for it, until its head or main moves. That holds whatever the
  receipts hold and however old the row is. This is contract A13 as written.
- **B4. Receipt.** Suppose a PR's newest row is `refused` with the receipt clause, on
  its current head and main, and the PR passes every check before the refusal check
  (B8). The tick runs felix merge once more on the first tick at which the gate
  receipt of its checkout, or the commission receipt, holds different bytes from
  those it held just before the felix merge run that row records. A file that was
  absent then and is present now has changed. So has a file that was present then
  and is absent now. On a tick where neither has changed, the tick runs no felix
  merge and writes no row.
- **B5. Hourly.** Suppose a PR's newest row is `refused` with the hourly clause, on
  its current head and main. The tick runs felix merge once more on the first tick
  that falls 3600 s or more after that row's time. Before that it runs nothing and
  writes nothing.
- **B6. Older rows.** A newest `refused` row on the current head and main whose detail
  carries none of the three clauses was written before this change. It is final, as
  in B3.
- **B7. What a retry writes.** A retry that exits 0 writes `landed`, sends the
  notification `Felix: landed #<n>` and ends the candidate loop, like any landing. A
  retry that is refused again writes a `refused` row every time (contract G6), with
  its class worked out anew. That row is notified only when its blocker, its class or
  the head differs from the PR's previous `refused` row (contract A6).
- **B8. Order.** A retry happens only for a PR that passes the checks that come
  before the refusal check today: contract G4, G5, A3, A9, A12, A19, A23 and A30. A PR
  that fails one of them gets its `skip`, `founder` or `session` row and no felix
  merge.
- **B9. A missing record is unknown, not unchanged.** Suppose the newest row is
  `refused` with the receipt clause, but the tick holds no record of what the
  receipts held before that run. That happens when another engine wrote the row, or
  the record was lost. The tick then runs felix merge once more and keeps a new
  record. On the next tick, if nothing has changed, it runs nothing. Where the record
  lives is the implementation's choice: under `land/`, never in the ledger's
  columns, and read by nothing but the tick.

Why the reason for contract A13 still holds: only escape blockers write
`escalated` rows, the founder-interruption count. An escape is a final-class
blocker, and neither a receipt-class nor an hourly retry can follow a refusal that
held one. Each says.log `refused` row costs at most one per receipt write, or one an
hour, per PR.

### The gh check (C097; amends contract G2, A10)

- **B10.** The tick's gh precheck passes only when `gh auth status --hostname
  github.com --active` exits 0. github.com is the only host `felix_repo_slug` reads.
  A broken token for another host, or for an inactive github.com account, does not
  stop the tick. When the check exits non-zero, the tick writes one `gh` row and
  lists no PR, deploys nothing and merges nothing, as today. That covers a stale
  active account, no login, and a gh that refuses either flag. The installed gh
  2.102 lists both flags.
- **B11.** The `gh` row's detail begins `gh auth status` and contains `github.com`.

### Every wait is said again (C001; amends contract A4, A10, A14, A22)

- **B12. The deploy wait names what it waits on.** G7.1 is unchanged: the tick still
  calls `pgrep` with `-f` as its own argument and the same pattern. When pgrep exits
  0, the `deploy-owed` row's detail is `a gate or suite is running; matched <list>`.
  The list holds `pid <p>` for each pid pgrep printed, in its order, joined by `, `.
  Each pid may be followed by ` (<command>)`, where the command is what `ps -o
  command= -p <p>` prints, cut to 80 bytes. The command is left out when ps prints
  nothing. When pgrep exits anything but 0 or 1, the detail is `a gate or suite may
  be running: pgrep exited <n>`, with no list.
- **B13. A stop is said again each hour.** Two job rows are the same wait when they
  have the same event and their details agree up to the first `; `, or in full if
  there is none. The rule covers every deduplicated job row the tick writes: `gh`,
  `fetch`, `deploy-owed`, `stuck`, and `unresolved` written to FELIX_LAND_LEDGER.
  When the tick would write one:
  - if the newest job row is not the same wait, the row is written and notified as
    today;
  - if it is the same wait and less than 3600 s old, nothing is written or notified,
    even when the text after the first `; ` differs (other pids, say);
  - if it is the same wait and 3600 s old or older, one row is written and notified.
    Its detail is `<the part before the first '; '>; still so since <T0>`, followed
    in B12's case by `; matched <list>` for this tick. `<T0>` is the time column of
    the earliest row in the unbroken run of same-wait job rows that ends at the
    newest job row. Rows of pull requests do not break the run.

  `paused` keeps its own hourly rule (contract G2).
- **B14.** A job row of another wait in between ends the run. The next row of the old
  wait is a first row again, and it carries no `still so since`.
- **B15. The trampoline too.** The trampoline's own rows follow the same rule:
  `deploy-owed` rows (contract A1 and A24) and `unreadable` rows (A31). Each one is
  compared with the ledger's last row of any kind, as today, using B13's same-wait
  test. Within the hour nothing is written. At 3600 s or more, one more row and one
  notification are written, with `; still so since <T0>`. `<T0>` is the earliest
  time in the trailing run of same-wait rows at the end of the ledger. The
  trampoline still exits 1 and runs no engine. The `readable` row (A31) is
  unchanged.

### A hand merge deploys itself (C082; amends contract A1)

- **B16.** Suppose main's version is V and `<cache>/<V>/harness/felix` does not
  exist. Before writing A1's "not installed" row, the trampoline checks four things:
  - (a) `git symbolic-ref HEAD` in the home prints `refs/heads/main`;
  - (b) `refs/heads/main` is an ancestor of `refs/remotes/origin/main` and is not the
    same commit;
  - (c) the version H that `refs/heads/main` declares in
    `engine/.claude-plugin/plugin.json` has an executable
    `<cache>/<H>/harness/felix`;
  - (d) main's own `felix_accepted_deploy_diff`, loaded from origin/main's
    `lib/resolve.sh` as A1 loads it, returns 0 for `"$FELIX_HOME_DIR"
    refs/heads/main`.

  When all four hold, the trampoline prints one line on stderr that names V and H and
  says H's engine runs the tick that deploys V. It writes no ledger row and sends no
  notification. It then runs `exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u
  FELIX_KERNEL_CACHE <cache>/<H>/harness/felix land --tick`, so its exit status is
  that tick's. It writes no row because the tick it starts writes its own (G7,
  B12-B13). A trampoline row as well would alternate with those rows every five
  minutes and defeat both deduplications.
- **B17.** When any of (a)-(d) fails, or the check cannot be loaded or exits anything
  but 0, the trampoline writes A1's "not installed" row as today: one row
  (deduplicated as in B15), one notification, exit 1, and no engine run.
- **B18.** A1 is otherwise unchanged. There is no fallback for an entry that is not
  executable or that differs, and no entry of any other version ever runs.
- **B19.** The tick that B16 starts finds the deploy owed (contract G3). It deploys
  and merges nothing in that tick (A11). A later tick merges with main's entry.

### The differing entry is named truly (C083, partly; amends contract G7.4, A1)

- **B20.** Suppose G7.4's first check (A21) finds that the cache entry for main's
  version V is not origin/main's engine, and a directory `<cache>/<V>` existed before
  the tick ran `felix install --no-bump`. The `deployed-unverified` row, and `paused`
  with the same reason, still begins `diff:`. It also says that the entry existed
  before the install, contains the words `does not replace`, and names `<cache>/<V>`.
  When no such directory existed before the install, the row reads as it does today.
- **B21.** A1's "differs" row keeps the words `differs from origin/main's engine` and
  `not main's engine`. It adds that felix install does not replace an entry that
  exists, using the words `does not replace`, and it names `<cache>/<V>`. It no
  longer says `deployed from the home`. Neither text contains `; `.

### The brakes leave rows (C104; amends contract G9)

`<id>` below is CLAUDE_CODE_SESSION_ID, or `-` when that is unset or empty. Every row
is a job row of seven fields (G8).

- **B22.** `felix land --pause [reason]` writes `land/paused` as today: the reason,
  or `paused by hand`. It also writes one `paused` row at once, with detail
  `<reason>; by session <id>`, and sends one notification titled `Felix: paused`. It
  exits 0. A tick within the hour writes no further `paused` row (G2).
- **B23.** When `land/paused` exists, `felix land --resume` writes one `resumed` row,
  with detail `the pause read: <its first line>; by session <id>`, and sends one
  notification titled `Felix: resumed`. It then removes the file and exits 0. When
  the file does not exist, it writes no row, sends no notification and exits 0.
- **B24.** When `launchctl bootstrap` succeeds, `felix land --install` writes one
  `installed` row, with detail `the job is armed: <plist path>; by session <id>`, and
  sends one notification titled `Felix: installed`. A failed install writes no row
  and dies as today.
- **B25.** After its bootout and removals, `felix land --uninstall` writes one
  `uninstalled` row, with detail `the job is disarmed: nothing lands unattended until
  felix land --install; by session <id>`, and sends one notification titled `Felix:
  uninstalled`. It does this whether or not anything was installed, and exits 0.

### The contract and the limits

- **B26.** In `docs/2026-10-15-land-on-green-contract.md`, the clauses that B1-B25
  change are edited in place and point here: G2's gh line, A1's "never runs ...
  another version", A10's last paragraph, A13, A33's "a session lands it", and G9's
  four brake commands. The sentence at lines 40-41, "What a present session adds is
  noticing a broken deploy, and G6's verify and pause cover that.", is replaced. The
  new sentence says that G7's verify covers a deploy that does not install or does
  not match main, and does not see a hook that fails open, which is roadmap step 12.
  The checks are:
  - `grep -c "G6's verify and pause cover that"` on the file gives 0;
  - `grep -c b02-land-tick` gives at least 1;
  - `wc -l` gives no more than 512.
- **B27.** `lib/green-tick.sh` stays under 500 lines (part 1280's G1 assertion). Code
  that does not fit goes into `lib/green-install.sh`, which stays at no more than 500
  lines, as the A23 checkout helpers did. Only if it would pass 500 does the code go
  into one new `lib/green-wait.sh`, sourced by `felix` beside the other two, outside
  the `lib/land*.sh` glob, and also no more than 500 lines. Nothing uses a gawk-only
  awk builtin (part 1497). Everything runs under bash 3.2 and bash 5.

## 3. What must not change

Each item names the existing parts that pin it. All of them must pass unedited.

- **Preflight, lock and paused.** Paused is one row an hour, a live lock holds, a dead
  one is taken, and the lock is released on TERM. Pinned by
  `1280-land-on-green-blind.sh` (G2), `1282-land-on-green-round-2-blind.sh` (A4, A5)
  and `1283-land-on-green-round-3-blind.sh` (A15).
- **The gh precheck's failure path.** One row, nothing listed, nothing merged; the
  stub fails every `auth status` form. Pinned by 1280 (G2) and 1283 (A10).
- **Candidate checks and their deduplicated rows.** Pinned by 1280 (G4, G5),
  1282 (A3, A6), 1283 (A9, A12), `1284-land-on-green-round-4-blind.sh` (A18, A19) and
  `1287-land-on-green-round-7-blind.sh` (A30).
- **How felix merge is run.** Main's cache entry, in the matched worktree, with no
  argument and the three variables unset. One landing per tick, and no worktree's
  engine ever runs. Pinned by 1280 (G6).
- **The refused row's detail.** It holds the first two-space line, or else the last
  line, cleaned; its tab becomes a space. Pinned by 1280 (G6, G8). The clause B2 adds
  must keep those `has` checks true.
- **Contract A13 for status-1 refusals.** Not re-run on the next tick at the same
  head and main, and re-run once after the head or main moves. Pinned by 1283 (A13)
  and 1282 (A6: a changed detail after main moves gives one new row and one new
  notification). The fixture's stub refuses with status 1, which is hourly under B1.
  Those parts never age a row, so they stay green.
- **The suffix the stuck-PR page reads.** The detail ends with ` [main <sha>]`.
  Pinned by the parser `lib/pr-status-state.sh`:218 and by
  `1310-stuck-pr-page-states-blind.sh`, `1330-stuck-pr-page-review-blind.sh` and
  `1360-stuck-pr-page-last-ledger-row-blind.sh`, which seed their own rows.
- **The deploy path.** G3, `pgrep -f` as its own argument, "a gate or suite is
  running" in the row, A2, A11, A14, A20, A21, A24 and A26, and a failed check written
  as `deployed-unverified` naming it, with `paused` holding the same reason. Pinned by
  `1281-land-on-green-deploy-blind.sh`, 1283 (A11, A14),
  `1285-land-on-green-round-5-blind.sh` and `1286-land-on-green-round-6-blind.sh`.
- **Rows written once.** A10 rows are written once and notified once over two
  identical runs or ticks, within the hour. Pinned by 1283 (A10) and 1282 (A1's
  `_la_owed`).
- **The trampoline, contract A1.** Main's accepted entry runs. With main's entry
  missing while the home is at origin/main, no other version runs (1282, G9 review 1,
  `_lgr1_other`). There is one row per case, and five distinct details whose words
  are `missing`/`not installed`, `execut`, `differ`/`not main`, `version` and `git`
  (1282). Refs are taken by their full names (1283 A8; 1284 A17, where `felix_base_ref`
  returns `refs/heads/main` as it is).
- **The trampoline, contract A31.** The `#!/bin/bash` line, the read, the `unreadable`
  and `readable` rows, recovery keyed on the newest row's kind, and `--install`
  rewriting the pair. Pinned by `1288-land-on-green-round-8-blind.sh` and
  `1289-land-on-green-round-9-blind.sh`. Those parts call `_lg_reset` after
  `--install`, so B24's row does not reach their counts.
- **G9's commands.** Exit codes, usage, the content of `paused`, `--status`. Pinned by
  1280 and 1281. Also pinned by 1280's last case: `--pause` followed by a tick gives
  exactly one row of seven fields. B22 keeps that true, because its row is a `paused`
  row and the tick then writes none.
- **The test library.** `tests/lib` files define functions and nothing else
  (`0006-the-lib-judges.sh`).

## 4. Assertions

"[control]" marks an assertion that is true before and after the fix. Every other
assertion is red on main today.

### Fixture for 1650

- Call `_lg_build amend`. Make worktree `b50` with `_lg_branch b50 notes/b50.md` and
  append `50<TAB><head>` to `$LG/shas`; reuse both if they already exist.
- Each case starts with `_lg_reset; rm -f "$RC50" "$CC"; _lg_prs "$(_lg_pr 50)";
  _lg_green 50`.
- felix merge's output goes in `$LGK/merge.b50.out` and its status in
  `$LGK/merge.b50.rc`.
- `M50` counts the felix.log rows whose directory is b50's and whose arguments are
  `merge`.
- `RC50` is b50's gate receipt (section 2 terms) and `CC` is
  `$LGH/state/commission/lgh`.
- "Rewrite" means writing a line with a fresh counter.
- Outputs, with blocker lines in cmd_merge's layout:
  - OUT-R, status 3: `not merging`, an empty line, `  unverified  tree <pad> the
    tree changed since the receipt`, an empty line, `Nothing here escapes the tree.`
  - OUT-C, status 3: the block `  commission  receipt <pad> the table set moved`,
    then an empty line, `Ask them to run, in order:`, an empty line, `  felix
    autonomy --allow commission` and `  felix commission`.
  - OUT-F, status 3: OUT-R's line plus `  evidence    notes/b50.md <pad> the change
    owes a test`.
  - OUT-E, status 3: one `  escape      write <pad> notes/b50.md: outside the tree`.
  - OUT-T, status 3: one `  commission  table <pad> projects/lgh/commissioning.tsv:
    unreadable`.
  - OUT-0, status 3: `not merging` and an empty line, nothing more.
  - OUT-G, status 1: `GraphQL: Something went wrong` and `felix: gh pr merge failed,
    for the reason gh gave above. Nothing was merged.`
  - OUT-M, status 4: `not merging`, an empty line, `  tree       edited under it,
    uncommitted or untracked`, an empty line, `The working tree was edited while this
    ran.`

### Part 1650 assertions

- A1 (B1, B2). OUT-R, one tick: one `refused` row for 50 whose detail contains
  `(tried again when a new gate or commission receipt is written)`.
- A2 (B2) [control]. That detail begins `unverified` and ends with ` [main <sha of
  refs/remotes/origin/main>]`.
- A3 (B2). OUT-F gives `(final until the head or main moves)`.
- A4 (B2). OUT-G gives `(tried again an hour after this row)`, and so does OUT-M.
- A5 (B4) [control]. OUT-R, two ticks with the receipts untouched: M50 is 1, and
  there is one `refused` row.
- A6 (B4). OUT-R refused, then RC50 is rewritten: the next tick makes M50 2.
- A7 (B4). The tick after that, with nothing touched: M50 is still 2.
- A8 (B4). Then RC50 is removed, so it was present then and is absent now: the next
  tick makes M50 3.
- A9 (B4). OUT-C refused, then CC is rewritten: the next tick makes M50 2, despite
  the two-space `felix` lines after the block.
- A10 (B4, B7). OUT-R refused, then the status is set to 0 and RC50 rewritten: the
  next tick writes one `landed` row for 50 and one `Felix: landed #50` notification.
- A11 (B7). OUT-R refused, RC50 rewritten, and the retry is refused the same way:
  there are 2 `refused` rows for 50 and one `Felix: refused #50` notification.
- A12 (B3) [control]. OUT-F refused, then RC50 and CC are rewritten and the rows
  aged: the next tick leaves M50 at 1.
- A13 (B3) [control]. The same with OUT-E: M50 is 1.
- A14 (B3) [control]. OUT-T refused, then CC rewritten: M50 is 1.
- A15 (B3) [control]. OUT-0 refused, then rewritten and aged: M50 is 1.
- A16 (B5) [control]. OUT-G, two ticks: M50 is 1.
- A17 (B5). OUT-G refused, then the rows aged: the next tick makes M50 2, and the
  tick after leaves it at 2.
- A18 (B5). OUT-M refused, then the rows aged: the next tick makes M50 2.
- A19 (B6) [control]. The ledger is seeded with one `refused` row for 50 at b50's
  head with detail `the receipt is stale [main <current main>]`, aged. RC50 and CC
  are written. A tick leaves M50 at 0.
- A20 (B9). The ledger is seeded with one `refused` row for 50 at b50's head with
  detail `x (tried again when a new gate or commission receipt is written) [main
  <current main>]`, and nothing else is in `land/`. A tick makes M50 1, and the tick
  after leaves it at 1.
- A21 (B8) [control]. OUT-R refused, then 50 is relisted with a `felix:hold` label
  and RC50 rewritten: the tick writes a `skip` row for 50 and leaves M50 at 1.
- A22 (B4, contract A13) [control]. OUT-R refused, then one more commit on b50
  (`_lg_more`), the shas updated and 50 relisted: the next tick makes M50 2.
- A23 (B3, contract A13) [control]. OUT-F refused, then main moves (`_l3_commit`):
  the next tick makes M50 2.
- A24 (G8) [control]. Every row the part wrote has seven tab-separated fields.

### Fixture for 1660

- Call `_lg_build amend`.
- Over `$LGB/gh` sits a wrapper, restored at the part's end. When `$LGK/gh-accounts`
  exists, the wrapper answers `auth status` itself from that table and logs its argv
  to gh.log as the stub does. Otherwise it calls the stub.
  - Each row of the table is host, user, active (`yes`/`no`) and token (`ok`/`stale`),
    tab-separated.
  - The wrapper takes `--hostname H`, `--hostname=H` or `-h H`, and `--active` or
    `-a`.
  - The rows considered are those for H, when H is given, and only the active ones
    when `--active` is given.
  - It exits 1 when no row is considered or any considered row is `stale`, and 0
    otherwise. That is gh 2.102's documented rule.
- `pgrep`: the stub numbers the matching lines of `$LGK/procs` as `4%04d`. A
  wrapper that exits with the status in `$LGK/pgrep.rc` while that file exists is
  added if `$LGB/pgrep` does not already behave that way, and is removed at the end.
- `fetch`: a `$LGB/git` wrapper fails `git fetch` while `$LGK/fetch.rc` exists, as
  1283's does, and is removed after use.
- Before a trampoline case, run `_lg_land --install; _lg_reset`, then run the
  trampoline with `_la_tramp`, whose output, stderr included, is `$LG/out.tramp`.
- `Vm` is `_l3_mainv` read when the part starts. `S` is
  `LGX=(CLAUDE_CODE_SESSION_ID=s-1660)`.

### Part 1660 assertions

- A25 (B10). The accounts are github.com/LeavesJ active ok and
  ghe.example.invalid/olduser active stale, with PR 42 green: one `landed` row for 42
  and no `gh` row.
- A26 (B10). github.com/LeavesJ active ok and github.com/oldwork inactive stale: 42
  lands and there is no `gh` row.
- A27 (B10) [control]. github.com/LeavesJ active stale: one `gh` row, no `pr list` in
  gh.log, and no merge.
- A28 (B10) [control]. An empty accounts table: one `gh` row and no merge.
- A29 (B11). In A27, the `gh` row's detail begins `gh auth status` and contains
  `github.com`.
- A30 (B12). Main's entry is removed and `procs` holds two matching lines then one
  that does not match: one `deploy-owed` row whose detail begins `a gate or suite is
  running` and contains `pid 40001` and `pid 40002` but not `pid 40003`.
- A31 (B12) [control]. pgrep.log holds `-f` as its own argument.
- A32 (B13) [control]. Then `procs` gains a third matching line and another tick
  runs: still one `deploy-owed` row and one notification.
- A33 (B13). Then the rows are aged, and T0 is read as the row's time: the next tick
  writes a second row and a second notification. The second row's detail begins `a
  gate or suite is running; still so since <T0>` and contains `pid 40001`.
- A34 (B13). The tick after that: still 2 rows.
- A35 (B14) [control]. Then one tick with `gh-auth.rc` set to 1 gives a `gh` row; the
  file is removed and another tick runs. There are now 3 `deploy-owed` rows, and the
  newest has no `still so since`.
- A36 (B12, B13). `pgrep.rc` is 2: the row reads `a gate or suite may be running:
  pgrep exited 2`. Aged, the next tick writes a second row that contains `still so
  since`.
- A37 (B13). `gh-auth.rc` is 1: one `gh` row and one notification. Aged, the next
  tick gives 2 rows and 2 notifications, and the second row contains `still so
  since`.
- A38 (B13). `fetch.rc` is 128: one `fetch` row. Aged, the next tick gives 2 rows,
  the second containing `still so since`.
- A39 (B13). Skipped: no seam ages a live lock past 45 minutes, so `stuck` is not
  driven.
- A40 (B15). An untracked file sits under the home's `engine/harness/`, and the
  trampoline runs twice: one `deploy-owed` row, one notification and status 1 each
  time [control]. Aged, a third run gives 2 rows and 2 notifications. The second row
  contains `still so since <T0>`, and no `land --tick` ran.
- A41 (B16). The home commits a version bump to 9.65.0, pushes it, and resets its
  main back one commit to Vm's commit. The home is on main, strictly behind, and
  there is no 9.65.0 entry. The trampoline runs exactly one `land --tick`, from
  `$LGV/<Vm>/harness/felix`, exits 0, writes no `deploy-owed` row and sends no
  notification.
- A42 (B16). In A41, `out.tramp` names `9.65.0` and `<Vm>`.
- A43 (B16) [control]. In A41, felix.log's columns 4-6 for that tick read `unset unset
  unset`.
- A44 (B17) [control]. From A41's state with the home on branch `l60-side`: no `land
  --tick`, one `deploy-owed` row containing `not installed`, and status 1.
- A45 (B17) [control]. From A41's state with one local commit on the home's main: no
  tick, and the same row.
- A46 (B17) [control]. From A41's state with one extra file in `$LGV/<Vm>/harness`:
  no tick, and the same row.
- A47 (B17) [control]. With the home reset to origin/main: no tick, and the same row.
- A48 (B18) [control]. From A41's state with a 9.65.0 entry whose felix is not
  executable: no tick from any entry, and the row contains `execut`.
- A49 (B19) [control]. From A41's state with 42 green: `_lg_land --tick` installs
  once, writes one `deployed` row and merges nothing. The next tick lands 42 through
  `$LGV/9.65.0/harness/felix`.
- A50 (B20). Main's entry is present with one extra file, `install.taint` is set and
  the home is at origin/main. A tick writes one `deployed-unverified` row. Its detail
  begins `diff:` and contains `does not replace` and `$LGV/<main's version>`, and
  `paused` holds the same reason.
- A51 (B20) [control]. Main's entry is absent and `install.taint` is set: the
  `diff:` row does not contain `does not replace`.
- A52 (B21). The trampoline runs with main's entry holding one extra file: one
  `deploy-owed` row containing `differs`, `does not replace` and `$LGV/<main's
  version>`, and not containing `deployed from the home`.
- A53 (B22). With S set, `--pause "hold until I read #460"` makes `paused` read
  exactly that [control]. One `paused` row has the detail `hold until I read #460;
  by session s-1660`, and one notification is titled `Felix: paused`.
- A54 (B22) [control]. A tick right after: there is still one `paused` row.
- A55 (B22). With `LGX=(CLAUDE_CODE_SESSION_ID=)`, `--pause x` writes a detail
  ending `; by session -`.
- A56 (B23). With S set, after A53, `--resume` writes one `resumed` row with the
  detail `the pause read: hold until I read #460; by session s-1660`, one `Felix:
  resumed` notification, and no `paused` file is left.
- A57 (B23) [control]. `--resume` with nothing paused exits 0 and writes no row.
- A58 (B24). With S set, `--install` exits 0 and writes one `installed` row
  containing the plist's path and `by session s-1660`, with one `Felix: installed`
  notification.
- A59 (B25). With S set, `--uninstall` exits 0 and writes one `uninstalled` row
  containing `by session s-1660`, with one `Felix: uninstalled` notification.
- A60 (B22-B25, G8). Every row from A53-A59 has seven fields and `-` as its PR.

## 5. Parts

- `engine/harness/tests/parts/1650-land-tick-retries-a-refusal-blind.sh`: B1-B9,
  A1-A24.
- `engine/harness/tests/parts/1660-land-tick-says-every-wait-blind.sh`: B10-B25,
  A25-A60.

Both are written blind from this document and the fixture library. Each opens with a
`# >>> name` marker line and a `printf` heading, as 1289 does, and calls `_lg_build
amend` so that `--part` alone works. Each restores every stub it wraps, and leaves the
home on main at origin/main with main's entry installed. Each stays under 500 lines.
`tests/run` gains their two lines after the 1600 line. Their names enter
`assertions.tsv` only through the record, which the builder does not run. Bash 3.2
traps apply: no `case` inside `$( )`, `[0123456789]`, `LC_ALL=C`, no arrays beyond
`LGX`. B26 and B27 are checked by the commands they name, not by a part.

## 6. Out of scope

- **C001: narrowing the process match** to processes that run the home's engine.
  Contract G7.1 and A14 decided the wide match on purpose. Every project's gate runs
  through the home's engine (`~/.local/bin/felix` → the home; cmd_gate,
  `felix`:740-772), so a pull under any running gate rewrites what it is running. A
  narrower pattern risks missing a real gate, and A14 reads doubt as "running". B12
  names the matched processes, so a false match such as `vim gate.sh` is visible, and
  B13 bounds the silence.
- **C083: repairing the entry automatically** by moving it aside and installing again.
  That depends on how `claude plugin install` handles a version its registry lists
  but whose directory is gone, which nobody has measured. It also means taking a
  live engine directory out from under sessions' hooks for the length of the
  install. That belongs with roadmap step 12 (rollback). This batch makes the rows
  true (B20, B21). felix merge's "Run felix install on main" (`felix`:1898) and
  gate.sh's `installed` remedy make the same false claim. They are in cmd_merge's
  judge block and `projects/felix/gate.sh`, outside this batch's files, so they go to
  a later batch.
- **C083: landing and deploying under one 30-minute watchdog.** This is by design
  (contract G7). The skeptic found it adds to the risk but is not a defect on its
  own.
- **C100: the stronger verify.** That means running the deployed entry's pre-tool on
  a deny-row payload (expecting exit 2), stop on a dirty checkout, and requiring
  `session-start` output. It is roadmap step 12. The fixture's hooks are silent
  stubs, and every deploy assertion in 1281-1286 stands on them. B26 corrects only
  the sentence that claims more. felix merge accepting a `--quick` receipt is
  direction §5 item 5, owed separately.
- **C104: refusing `--resume` over a hand pause.** Sessions pause and resume by
  routine (memory land-on-green-decided-2026-10-15). Holding one PR uses the
  `felix:hold` and `needs-founder` labels (contract A30). The stuck-PR page calls a
  green PR "ready / lander" while the lander is paused or uninstalled
  (`pr-status-state.sh`:240). That is the skeptic's separate finding.
- **C011: re-checking the receipt inside the tick** with `felix_verify_current`. It
  runs the probes on every tick for every refused PR. B4's change trigger leaves
  judging to felix merge.
- **C082: deploying from cmd_merge** after an engine merge. That is the merge
  boundary's code, and the founder's merges on GitHub never pass through it. B16
  covers both cases.
- **The installed job knowing its trampoline is stale.** `--status` does not compare
  the installed body with this engine's. Section 7 says who re-arms it.

### Not fixed: not a defect

- **C001 (a): "matching another project's gate.sh is a false positive."** It is
  inside G7.1's reason. `~/.local/bin/felix` is a symlink to
  `/Users/a14808/Documents/Felix/engine/harness/felix`, and cmd_gate runs
  `"$proj/$gate"` from the home's engine and the home's `projects/<p>/` (`felix`:740).
  So `_gt_deploy`'s `git pull --ff-only` and `felix install` (green-tick.sh:250-258)
  change the code under any running gate. Both skeptics refuted this claim.
- **C001: "the A2 wait buys no safety, because the engine under a suite does not
  change."** It is false for the same reason: A2's deploy pulls the home, and every
  gate runs the home's gate script and engine.
- **C001: "3-4 h suites, so no idle moment".** This is overstated. Records and gates
  take 40-90 minutes, and in five days the only gate wait lasted 61 minutes
  (2026-10-19T18:16:34Z-19:17:46Z), when the only open PR, #425, was conflicting.
  The unbounded case that remains is fixed by B12 and B13.

## 7. Founder PR

None. The batch changes no `.github/workflows` file, deny or escape row, commission
grant or publication.

One step after landing is the founder's. The installed job keeps the trampoline it
was installed with, so B15-B18 and B21 do not run on this Mac until `felix land
--install` is run again in the home. Contract G9 makes installing persistent
configuration, which a session runs only on the founder's yes in chat. The exact
step is `cd /Users/a14808/Documents/Felix && felix land --install`, after the deploy
of the version that carries this batch.
