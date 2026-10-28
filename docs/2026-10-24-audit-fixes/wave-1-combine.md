# Audit wave 1: what combining the batches changed, contract, 2026-10-28

Wave 1 of the 2026-10-24 audit fixes is one branch, `claude/audit-wave-1`. It merges the batches b00,
b02, b03, b04, b05, b09, b21 and b23. Each passed alone on its own branch from origin/main 69b51a61
(0.49.307). This file is the contract for what their combination needs. Where it differs from those
batches' contracts (`b02-…`, `b03-…`, `b04-…`, `b05-…` in this folder), it wins. B-numbers and
A-numbers there are cited as "b05 B1" and "b02 B22".

Words used here:
- **H**, the home: `$FELIX_HOME_DIR`, the checkout that holds `projects/`.
- **hp**, the home's project: `felix_resolve_project H H`.
- **p**, the project of the checkout a command runs in.
- **Ld**, p's land directory: `$(felix_mem_dir p)/land`, holding `ledger.tsv` (seven tab fields:
  time, kind, pull request or `-`, sha, worktree, wall seconds, detail) and `alerts.tsv` (b05 B7,
  eight fields).
- **An attempt** is b05's one post attempt (b05 B1-B10). **A record** is one alerts.tsv line.
- **The R2 sentences** are b05 R2's enumerated sentences, one per kind.

## 1. Settled on the branch already (the record, not to be re-derived)

These were found by running the batches' parts under BWK awk and gawk on the combined tree, and are
fixed and pinned on the branch. They are listed so that nothing below undoes them.

- **S1.** `felix status` prints eight rows, in order: settings, schedule, pulse, reach, gate, land,
  hooks, alerts. b04 added land and hooks, and b05 added alerts. Parts 1100, 1690 (A1, A2) and 1720
  (A33) pin eight.
- **S2.** A `waiting` row (b03) holds nothing. `_gt_last` and b02's `_gt_held` both read past it, so a
  held refusal stays held until its blocker can lift. Pinned by 1650 A17 and 1670 b03 A12.
- **S3.** A paused lander is said once at session start. When the land row reads paused, the waits
  (b03) leave the pause to b04's landing badge, and the badge's context adds
  `felix land --resume ends the pause.` Pinned by 1690 A32b.
- **S4.** 1690's fixture home is a checkout whose `.felix` names its project, as b05's home-only
  lander requires.
- **S5.** The tick's lock and watchdog live in `lib/green-lock.sh`, sourced by `lib/green-tick.sh` at
  load. green-tick.sh stays under 500 lines (1280 G1).
- **S6.** In the trampoline's `owed()`, b05's attempt is made with b02's aged detail, inside b02's
  hourly guard.

## 2. Defects found by review of the combined tree

**W1 (high). One hand pause alerts the founder twice, and 1720 is red.**
- Before b02, `felix land --pause R` only wrote `Ld/paused`, and the next tick wrote the paused row
  with detail `R`. b02 (B22) has `--pause` write its own paused row, with detail
  `R; by session <id or ->`, through `_gt_say`, which b05 extended to make an attempt.
- An hour later the tick writes its hourly paused row with detail `R`. b05's B8 compares whole
  details. `R` differs from `R; by session -`, so the same pause is dispatched again.
- Part 1720 was written for the old meaning of `--pause`. On this tree it fails at A16, A17, the
  fixture control after A17, A18, A24 and A27, and A26 passes only vacuously.

**W2 (medium). Kinds with no sentence write false `failed` records.**
- b02 added `resumed`, `installed` and `uninstalled` to `_gt_say`'s banner kinds, and b03 added
  `waiting`. Each reaches b05's attempt, finds no R2 sentence, and appends a `failed` record that
  starts `kind:`.
- The founder then sees `alerts failed … installed kind: installed is not an event kind …` in
  `felix status`. The record also counts in R4's "Not delivered before this one", and it hides a
  standing `no-alert-workflow` behind a newer `failed`.

**W3 (medium). The phone is told the wrong thing for a tick that could not age what waits.**
- b03 writes two rows of kind `stuck`: "the ledger could not be read to age what waits", and
  "lib/green-wait.sh did not load: what waits is not aged".
- b05's sentence for `stuck` is "A tick has held the lock for more than 45 minutes." So the alert
  names the wrong failure.

**W4 (medium). Status tells a checkout outside the home to install a lander it may not install.**
- b04's land row in a governed checkout whose p is not hp reads "no land-on-green job for p; felix
  land --install schedules one", or "… nothing lands here until felix land --install".
- b05 (C013) now refuses `felix land --install`, `--tick`, `--pause`, `--resume` and `--status` there.
- A job installed for such a p before b05 dies at every tick before its heartbeat, so it reads as
  not-ticking with advice about a hung tick.

**W5 (low).** Two combine comments in parts 1690 and 1720 cite this folder or a file that is not in
the repository. They should cite this file.

## 3. Required behaviour

- **C1. A hand pause is the pause event, said once.**
  - The paused row that `felix land --pause R` writes (b02 B22) starts one attempt. This amends b05
    B1: "any row a person's `felix land` command writes" now means the `resumed`, `installed` and
    `uninstalled` rows only.
  - The attempt's detail (alerts.tsv field 8, and the detail b05 B8 compares) is the ledger detail
    with b02's `; by session <id or ->` suffix removed. The ledger row keeps the suffix, so b02's
    parts are unchanged.
  - The tick's later hourly paused row for the same reason is therefore the same event under B8: no
    gh call and no new record.
  - A pause with another reason is a new event.
  - A pause the tick sets itself (`_gt_pause`, for example after an unverified deploy) is said by the
    tick's paused row as before.
- **C2. A person's commands do not alert.** Rows of kind `resumed`, `installed` and `uninstalled` keep
  their ledger row and banner. They start no attempt: no gh call, and nothing appended to alerts.tsv.
- **C3. A green pull request that waits reaches the phone.**
  - A `waiting` row (b03) starts an attempt like any tick event, under b05 B1-B10.
  - Its R2 sentence is exactly `A green pull request has waited more than four hours to land.`
  - The dispatch body's line 1 is `@<login> Felix land: waiting #<pr>`.
  - B8 applies: the same kind, pull request and detail is not sent again.
  - This follows the founder's decision of 2026-10-25 that nothing stalls silent.
- **C4. A tick that cannot age what waits says so as `unaged`.**
  - b03's two rows above are of a new kind, `unaged`, with the same details as today.
  - `stuck` is written only by the lock check (`lib/green-lock.sh`), so its sentence stays true.
  - `unaged` has a banner and an attempt. Its R2 sentence is exactly
    `A tick could not age what waits, so no waiting pull request is named.`
  - `_gt_row_once`'s once-per-kind-and-detail rule applies to it as it did to the `stuck` rows.
- **C5. Only kinds with a sentence alert.**
  - Every kind that starts an attempt has an R2 sentence.
  - A row of any other kind starts no attempt and appends nothing to alerts.tsv.
  - The `kind:` failed record stays only as a defence for a caller outside `_gt_say` and `owed()`.
  - The R2 kinds after this contract are b05's thirteen (landed, paused, refused, gh, founder,
    deployed, stuck, deployed-unverified, timeout, unresolved, fetch, deploy-owed, unreadable) plus
    `waiting` and `unaged`.
- **C6. The land row and the badge in a checkout outside the home.** When hp resolves and differs
  from p:
  - **With no job installed for p** (no plist `$HOME/Library/LaunchAgents/felix.land.<p>.plist`), the
    land row is state `none`. Its detail names p and hp and says that land on green lands hp's pull
    requests only, so p has no lander. It does not contain `felix land --install`.
  - **With a plist for p present**, the land row is state `value`, value `not-home`. Its detail names
    the plist path and hp, and says the job serves nothing for p and that `felix land --uninstall`
    from this checkout removes it. `--uninstall` stays allowed outside the home (b05).
  - **The session-start landing badge** (`felix_lander_notice`) shows `landing not-home` in that
    case, as it does for paused, not-loaded and not-ticking.
  - **Unchanged:** when hp does not resolve, or equals p, the land row is exactly as b04 has it.
  - **The home is the status home:** the H that `felix status` and session start already resolve.
    `felix_status_rows` has it as its first argument, and session start has `$FELIX_HOME_DIR`.
- **C7. No paused lander is named outside the home.** In a checkout whose p is not hp, session start
  names no paused lander for p: no `lander paused` token and no `The lander is paused` paragraph.
  `felix land --resume` is refused there, so the advice could not be followed. In the home's own
  checkouts, S3 holds as it is.
- **C8.** The combine comments in parts 1690 and 1720 cite
  `docs/2026-10-24-audit-fixes/wave-1-combine.md`.

## 4. What must not change

- **b02's parts 1650, 1660 and 1665.** They read the ledger and the banners. Hand-pause rows keep
  `; by session <id or ->`, and resumed, installed and uninstalled rows keep their ledger row and
  banner.
- **b05's B2-B10 and R1-R8** for every kind that alerts: the calls and their order, the standing
  issue, the enumerated body, `GH_*` handling, the bound (B9) and the token folding (R2, B7).
- **b04's 1690 A1-A37 and A32b**, b03's 1670 and 1680 (except where a `waiting` row now also makes an
  attempt, which none of them counts), b05's 1710, and part 1100.
- **S1-S6 above.**
- **What a land-row consumer sees in the home and its worktrees** (C6 changes only checkouts outside
  the home), and the eight rows' shape (D16 in part 1100).

## 5. The assertions

New assertions go in a new part, `2120-wave-1-combine-blind.sh`, written from this contract alone. It
may use the suite's helpers and the fixtures in `tests/lib/land-on-green.sh` and
`tests/lib/stuck-pr.sh`, and it may copy fixture patterns from parts 1690, 1710 and 1720. It covers
C1-C7, red first against the branch as it stands. At least these cases:
- **For C1:**
  - In a GitHub-state home, `--pause R`, then a tick with the ledger aged past the hour: exactly one
    `workflow run` and exactly one dispatched record, whose field 8 is `R`.
  - `--pause R2` after that dispatches again.
- **For C2:** `--resume`, `--install` and `--uninstall` each append no alerts.tsv record and make no gh
  call.
- **For C3:** a tick that writes a `waiting` row in the GitHub state dispatches a body whose line 1 is
  `@<login> Felix land: waiting #<pr>` and whose line 3 is the C3 sentence. A second tick with
  nothing changed makes no second dispatch.
- **For C4:** a tick whose `lib/green-wait.sh` is missing writes a row of kind `unaged` and none of
  kind `stuck`. Its dispatch carries the C4 sentence and not the lock sentence.
- **For C5:** after the C1-C4 cases, no record's note starts `kind:`.
- **For C6:** from a second governed checkout whose p is not hp, run `felix status --tsv`:
  - with no plist, the land row is `none`, names p and hp, and holds no `felix land --install`;
  - with p's plist present, the land row is `value not-home` and names `felix land --uninstall`;
  - session start in that checkout shows `landing not-home`.
- **For C7:** with `Ld/paused` present for that p, session start there holds no `lander paused` and
  no `The lander is paused`.

Part 1720's assertions A14-A18 (and the control after A17), A24, A26 and A27 test the paused event as
the tick raised it before b02. Restate them for C1, keeping what each one checks:
- **A14-A15:** one paused event, local origin, one failed record.
- **A16:** the calls and body for a paused event.
- **A17:** the same event an hour later sends nothing.
- **A18:** a new event dispatches on the standing issue.
- **A24:** failed dispatches are counted in the next body (R4). Re-derive its counts from C1, C2
  and R4.
- **A26:** a hanging dispatch is bounded (B9). The hang must be met by a command run with
  `_FN_SECS=2`, which is now the `--pause` that raises the event.
- **A27:** the paused scenario gives the same ledger fields with a local origin, with gh failing and
  with a hanging dispatch. The ledger detail now ends `; by session <id or ->`.

A restated assertion keeps its A-number and says it was restated for this contract.
