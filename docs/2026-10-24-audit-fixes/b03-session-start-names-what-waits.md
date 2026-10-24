# Audit fix batch b03: session start names what waits

*Written 2026-10-24 against felix-home `origin/main` `69b51a61` (0.49.307), for
branch `claude/audit-b03-session-start-names-what-waits`. Input: the batch brief
(six defects with evidence, scenarios, fix sketches and skeptics' notes) and the
code in that tree. Where a skeptic corrected a claim or a severity, this
contract follows the correction.*

**This document is the whole contract for assertions.** An assertion author
needs nothing else, apart from the suite's existing fixtures and stubs
(`tests/lib/land-on-green.sh`, `tests/lib/stuck-pr.sh`), which may be reused.
"Now" is the wall clock when the assertion runs; times relative to it are
written with `date -u` in whichever form the platform takes (`-r N` on BSD,
`-d @N` on GNU). Every memory root a part uses is its own directory under
`$TMP`, never the suite's `$MEM`.

---

## 1. Defects

| id | severity (after skeptics) | one sentence | scenario |
|---|---|---|---|
| C002 | high by one skeptic, medium by the other | A green PR that waits on a session, a conflict, CI or the founder writes one ledger row and is never notified, aged or named anywhere a person looks. | A PR is gated in a scratch clone or its worktree is archived, or main moves under it and it conflicts. Every five minutes the tick dedups its row (`green-tick.sh:68-75`); `_gt_say` (`:52`) notifies neither `skip` nor `session`; no hook, `status.sh` or `pulse.sh` reads `land/ledger.tsv`. #425 alternated `session` and `skip: conflicting with main` from 10-18 to 10-23 with no one told. Corrections: CI that runs out of Actions minutes usually ends in a failure the desktop app wakes on, so "queued forever" is weak; a paused lane is re-notified hourly (`:413`), not once. The strong cases are `session` and `conflicting`. |
| C038 | medium | The founder's screen line says `· N due` with no names, so a row only the founder can clear looks like routine upkeep, and nothing marks it as his. | `session-start:769-773` builds `Felix: felix · 5 due`; the names go only into the model's context (`:315-323`). The snapshot row needs his yes (`direction.md` §6: "Each bring-forward to LeavesJ/Felix needs his yes"), yet `next.sh:165` gives it owner `felix` and sessions are told "Do them on one branch". Corrections: someone is told (the model, `felix next`, the count); "partly cannot clear" holds for the snapshot only; the "wrong-verdict fix" claim had no evidence. |
| C069 | medium | Decisions deferred overnight are shown at session start only to the session whose night is live, so a project's queue waits with nobody told. | `session-start:579-597` reads `felix_overnight_deferred_count` only inside `felix_overnight_active` for this session; `felix overnight --defer` writes the project-wide queue (`overnight.sh:364-374`) whether or not a night runs. Correction: the two live rows (#304, #310) were resolved by other routes within 2 and 9 days; what has lasted is a stale queue nobody is told exists, whose `--report` still says "waiting on you (2)". |
| C029 | medium by one skeptic, high by the other | When PreToolUse cannot judge a call, it allows it and Felix records nothing, so a broken deny reader looks exactly like a session that tried nothing forbidden. | `pre-tool:40-41` load libraries with `2>/dev/null \|\| exit 0`; `:120` reads `felix_deny_match`'s failure as no match; `felix_deny_code` (`deny.sh:427-430`) drops awk's status. Reproduced: a missing `deny-read.sh`, `deny.sh` or `resolve.sh`, an awk that exits non-zero, an unbound variable in the matcher, and `ulimit -u 1` each let `git push --force` through with no file written. Corrections: Claude Code itself logs the exit-1 and exit-128 cases; the 10-08 UTF-8 abort is fixed on this tree; a missing `deny.tsv` is a legitimate no-rules state. |
| C027 | high | On an organisation-owned repository every member's PR reads `outside`, waits for nobody, so red and conflicting PRs drop out of "needs you". | `pr-status.sh:143,231` take the governed account as the slug's owner; `pr-status-state.sh:160` makes any other author `outside`, checked first (`:227`); the lost-work page collapses `nobody`. Correction: the tick acts only on the home's slug and needs a local receipt and checkout, so "the tick would merge Alice's PR" is false; the founder's own `team1` (joshcodes42/Team1) and `sv2-apps` (stratum-mining) are owned by others, so he can meet this. |
| C087 | low | The stuck-PR page puts a green trust-base PR in `needs-attended`, "needs a session", while the tick lands such PRs unattended. | `pr-status-state.sh:210,237`; the tick has no trust-base test, `direction.md` row 24 says "Judge-changing PRs are included", and the tick landed #456 (which changes `projects/felix/gate.sh`) on 10-22. A session may spend time on a PR about to land. The finding's second half (rollup green, gate run unreadable) is mostly refuted: §6. |

---

## 2. Required behaviour

Paths: `MEMR` is the memory root (`$FELIX_MEMORY`, else `$HOME/.felix/memory`);
`MEM_P` is `MEMR/<project name>`; `LAND` is `MEM_P/land`. A ledger row is seven
tab-separated fields: time (UTC ISO `YYYY-MM-DDTHH:MM:SSZ`), event, PR, head,
worktree, wall seconds, detail.

### 2.1 The lander ages what waits (C002; `lib/green-tick.sh`)

Definitions, for an open PR `N` the tick's gh list gives at head `H`:
- A **wait row** of `N` is one with PR `N` whose event is `session`, `refused`
  or `founder`, or `skip` whose detail begins `conflicting with main`,
  `another open pull request has the head branch`, `gate run not green: `,
  `could not read the files`, or is `labelled needs-founder` or
  `labelled felix:founder` (label compared without regard to case).
- Every other row of `N` (`skip` for `a draft`, `labelled felix:hold`,
  `cross-repository: ...`, `its base is ...`; `landed`; anything else) is a
  **hold row**. Rows whose event is `waiting` are ignored by both terms.
- `N`'s **wait run** is the longest run of `N`'s last rows (ignoring `waiting`
  rows) that are all wait rows with head `H`. `T0` is the time of its first
  row. `N`'s **newest row** is its last row that is not `waiting`.

**B1.** A tick that reads the open PRs and does not land `N` appends, after
whatever row it wrote for `N`, exactly one row
`<now>  waiting  N  H  -  0  waits on <who> since <T0>: <event>: <detail>`
when all hold: the wait run is not empty; `T0` is at least 4 hours (14400 s)
before now; the ledger holds no `waiting` row for `N` with head `H` written less
than 24 hours (86400 s) before now. `<who>` is `the founder` when the newest
row is `founder` or a `labelled needs-founder`/`labelled felix:founder` skip,
else `a session`; `<event>` and `<detail>` are the newest row's. The row is
notified like the other notified kinds: one osascript call whose title is
`Felix: waiting #N`.
**B2.** Otherwise no `waiting` row and no notification: an empty wait run (the
newest row is a hold row, is for another head, or there is no row), `T0` less
than 4 hours ago, or a `waiting` row for `N` and `H` less than 24 hours old.
**B3.** A PR the tick's gh list does not return gets no `waiting` row, whatever
its rows. A tick that does not read the PR list (paused, lock held, gh auth
failed, fetch failed, a deploy owed or just run) writes no `waiting` row.
**B4.** `waiting` rows change nothing the tick decides: the one-row-per-wait
dedup and the "refused at this head and this main" skip read `N`'s newest row,
not a `waiting` row. After a `waiting` row, a tick over the same state writes
no new `session`, `skip` or `refused` row for `N` and calls no `felix merge`
for a PR refused at the same head and main.
**B5.** `felix land --status` is unchanged: it shows each PR's newest row of
any kind, so a `waiting` row shows there.

### 2.2 Session start names what waits (`hooks/session-start` and a new lib)

**B6.** Placement. Each paragraph below sits in the state block: after the
`Memory: ` line and before the line beginning `Read before planning:`; the
withheld line (`lib/own.sh`) stays the context's last paragraph. The screen
line (`systemMessage`) is one line, in this order:
`Felix: <project>[ · N due[ (yours: a, b)]][ · new tooling found][ · lander paused][ · PRs waiting: M][ · deferred for you: D][ · calls not judged: F]`.
Each bracket appears only when its paragraph does; `M`, `D` and `F` are a count
or the word `unknown`.
**B7.** Waiting PRs. When `LAND/ledger.tsv` is a readable regular file, every
PR whose newest row of any kind is a `waiting` row written less than 26 hours
(93600 s) before now is listed, ascending by PR number, under the line
`Pull requests waiting longer than four hours, as the lander last saw them (felix land --prs says more):`
one line each, `  #N <that row's detail>`, at most five, then
`  and K more: felix land --prs` when there are more. `M` counts all of them.
**B8.** No ledger file, or no such PR: no paragraph and no token. A ledger that
exists and is not a readable regular file, or whose read fails:
`Which pull requests wait could not be read: <path> is not a readable file.`
and `M` is `unknown`.
**B9.** Paused lander. When `LAND/paused` exists:
`The lander is paused, so nothing merges with nobody present: <reason>` and,
on the next line, `felix land --resume ends the pause.` `<reason>` is the
file's first line, `no reason given` when it is empty, `the reason could not be
read` when it cannot be read. Token ` · lander paused`.
**B10.** Deferred decisions. In every governed session start (any session id,
a night live or not), when `MEM_P/overnight/deferred.tsv` holds at least one
row that is not blank or a `#` comment:
`D decision(s) deferred overnight wait on the founder, the oldest from <date>.`
and, on the next line,
`felix overnight --report reads them back, and felix overnight --clear clears them once read.`
`<date>` is the smallest all-digit first column as `YYYY-MM-DD (UTC)`, or
`an unknown date` when no row has one. `D` is the row count.
**B11.** Absent or no rows: nothing. Present and not a readable regular file:
`Decisions deferred overnight could not be read: <path> is not a readable file.`
and `D` is `unknown`.
**B12.** The night paragraph is unchanged: the session that owns a live night
gets the direction and `Granted to this session: ...`; every other session gets
no line of the direction.
**B13.** Hook faults (reads §2.3's log). Rows of `MEMR/hook-faults.log` count
when their third field is this project's name or `-` and their time is less
than 7 days (604800 s) before now. A row whose time is `-` takes the time of the
next row below it that has an ISO time, or the log's modification time when no
row below it does. When `F` ≥ 1:
`PreToolUse could not judge F tool call(s) in the last 7 days, so the deny rows were not applied to them and each was allowed. The newest, <when>: <reason>. Each is a row of <path>.`
"The newest" is the last counted row in the file; `<when>` is its ISO time, or
`at a time not recorded` for a `-` row. No log or no counted row: nothing. A log
that exists and is not a readable regular file:
`Whether PreToolUse judged every call could not be read: <path> is not a readable file.`
and `F` is `unknown`.
**B14.** Maintenance the founder owns (§2.4). Due rows whose trigger is
`founder` are left out of the `Maintenance due:` line, which with its
`Do them on one branch. See 'felix maintenance'.` line appears only when a
row that is not the founder's is due. They are named on the line
`Due, and waiting on the founder's yes rather than a session: <item>[, <item>]`
where `<item>` is `<name> (<D> days since it last ran, every <C>)`,
`<name> (never run, every <C>)`, `<name> (its check says it is due)` or
`<name> (its check is refused)`. The screen's ` · N due` still counts every
due row, the founder's included, and is followed by
` (yours: <name>[, <name>])`.
**B15.** With none of this batch's state present (no `LAND`, no deferred
rows, no counted hook-fault row, no `founder` row), the context holds none of
the sentences of B7-B14 and the screen line none of their tokens; the
`Maintenance due:` line, the in-flight lines and ` · N due` are as before.

### 2.3 PreToolUse records what it could not judge (C029; `hooks/pre-tool`, `lib/deny.sh`)

**B16.** A fault row is appended to `MEMR/hook-faults.log`, five tab fields:
time (UTC ISO, or `-` when it could not be read without starting a process),
`pre-tool`, the project's name or `-` when none is resolved yet, the tool name
or `-`, and the reason (tabs and newlines as spaces). The hook still allows:
exit 0, nothing on stdout, as today.
**B17.** The reasons, each the whole field or its start:
`the hook could not find its own directory`; `lib/resolve.sh did not load`;
`lib/deny.sh did not load`; `the payload could not be read` (reading stdin
failed; an empty payload read without error is no fault);
`the Felix home could not be found`; `deny.tsv is not a readable file` (it
exists and is not a readable regular file); `the payload names no tool` (the
project has a `deny.tsv`); `the payload's <field> could not be read` (a row
names the tool and the subject field is absent, holds a raw `\001`, or its
reader failed); `the deny reader could not read the command: <why>`, where
`<why>` contains `lib/deny-read.sh` when that file did not load and
`awk exited <S>` when the reader's awk exited non-zero.
**B18.** Any other end of the hook before a verdict (an unbound variable in a
library or the matcher, a failed fork, an abort while loading) writes one row
from an EXIT trap that starts no process: time `-`, reason
`the hook ended with status <S> before a verdict`. The exit status is the
shell's own and is never 2.
**B19.** No row on: a refusal (exit 2, says.log as today); a call judged and
allowed; a directory no project governs; a project with no `deny.tsv`; a tool
no row names.
**B20.** When `MEMR` does not exist, no row is written, nothing is created,
and the exit is 0.
**B21.** Sourced, `felix_deny_match PROJ TOOL CMD [START]` keeps exit 0 and the
reason on a refusal and non-zero on anything else; exit 1 stays "judged, no row
matched". New: exit 2, with the why of B17 on stdout, when the command could not
be read (`deny-read.sh` not loaded, or the reader's awk or its substitution
exited non-zero). `felix_deny_subject` prints nothing when its awk fails, as
today (part 0630).

### 2.4 Maintenance the founder owns (C038; `lib/maintenance.sh`, `lib/next.sh`)

**B22.** The third column of `maintenance.tsv` takes `founder`: the row comes
due on its cadence, or its check, exactly as an `always` row does
(`felix_maint_status` prints the same line it would for `always`), and
`felix_maint_unreachable` never lists it. `felix maintenance` prints it as an
`always` row.
**B23.** `felix_next`: a due `founder` row's rank-4 row has owner `founder`
(text `upkeep due: <name> — <description>` as today); other due rows keep
owner `felix`.
**B24.** `projects/felix/maintenance.tsv`'s `snapshot` row has third column
`founder`; every other row is unchanged. `templates/maintenance.tsv`'s header
documents the value.

### 2.5 The stuck-PR page names the right actor (C027, C087, and B4's rows)

**B25.** The governed accounts are the slug's owner and the signed-in account:
the `login` field of `gh api user`'s JSON answer, read from the whole body
whatever `--jq` support the stub has. It is asked at most once per
`felix land --prs` or `--queue` run, only when the list holds a PR that is not
cross-repository and whose author is not the owner (compared without regard to
case), and never under `--no-gh`. A login is 1-39 characters of `A-Z a-z 0-9 -`;
anything else, a non-zero exit or no `login` field is "not read".
**B26.** A PR that is not cross-repository and whose author matches the owner
or the signed-in account (without regard to case) is never `outside`: its
state comes from the remaining rules as an owner's PR's does.
**B27.** Both read and the author matches neither: `outside`, needs `nobody`,
detail naming the author, the owner and the signed-in account. A
cross-repository PR is `outside` as today.
**B28.** The signed-in account not read, a PR not cross-repository and its
author not the owner: state `unknown`, needs `unknown`, detail containing
`the signed-in GitHub account was not read`. A PR by the owner is unaffected.
**B29.** gh is still asked only `pr list` and GETs through `api` (no `-X`,
`--method`, `-f`, `-F`, `--field`, `--raw-field`, `--input`).
**B30.** No PR is ever in state `needs-attended`. A green PR, not a draft, its
own head branch, no label, no founder path, changing a trust-base path, with
no same-head ledger row: `ready`, needs `lander`; the detail still holds
`touches the trust base: <paths>`.
**B31.** The same PR whose newest non-`waiting` row at this head is `session`,
or `refused` on the current origin/main: `refused`, needs `session`. With the
ledger unread: `unknown`, needs `unknown`.
**B32.** A trust-base PR that also changes a founder path is `founder`, its
detail saying `trust base`, as today.
**B33.** The page's per-PR ledger reading skips `waiting` rows: a PR's state
and detail are what they would be without them. The lander source row still
reports the ledger's newest row of any kind.

### 2.6 Every path

**B34.** Session start exits 0 and prints one JSON object on every path of
§2.2, the unreadable ones included, and on the tick's deploy-verify stub
payload.
**B35.** `hooks/session-start` is at most 780 lines; `lib/green-tick.sh` at
most 500; every file this batch adds or touches at most 500, except that a file
already over 500 does not grow. `lib/resolve.sh`, `lib/discover.sh`,
`lib/where-read.sh`, `lib/commission.sh`, `engine/harness/felix` and
`hooks/stop` are not touched.

---

## 3. What must not change

- **Session start** (parts `0010-resolution.sh`, `0120-scheduled-maintenance.sh`,
  `0460-maintenance-a-check-that-names-work-already.sh`,
  `0950-a-handoff-fold-already-in-flight-is-named-so.sh`,
  `0220-the-binding-itself.sh`, `0250-on-path-via-a-symlink.sh`,
  `0740-what-a-grant-refuses.sh`, `0800-the-lifecycle-recorder.sh`,
  `1130-unattended-work-runs-only-in-its-own-checkout.sh`,
  `0204-hooks-stand-where-the-session-stands.sh`,
  `0380-the-reconciler-reads-the-record-reached-besi.sh`,
  `0710-commissioning-a-seeded-check-reads-done-only.sh`,
  `1500-git-colour-never-reaches-what-the-engine-parses.sh`,
  `1510-no-caller-environment-changes-a-tool-s-output.sh`,
  `1281-land-on-green-deploy-blind.sh`, `1285-land-on-green-round-5-blind.sh`):
  a resume says nothing; a broken binding says so; an ungoverned directory
  says nothing; the `· N due` count equals `felix maintenance`'s `DUE` lines
  and is parsed by `s/.*· \([0-9][0-9]*\) due.*/\1/p` (so no new token may end
  in ` due`); `Maintenance due: <names>` is one line starting at column 0;
  `Already in flight, so not due: X on Y` lines; the night's direction only for
  its owner; the withheld line last and never on the screen; exit 0 on the
  tick's verify payload.
- **PreToolUse** (`0610-denial-reads-the-command-the-shell-runs.sh`,
  `0620-denial-refuses-what-a-command-changes-not-wh.sh`,
  `0630-the-subject-of-a-large-payload.sh`,
  `0994-bash-s-own-collation-and-the-bsd-text-tools.sh`, `0996-continued.sh`,
  `0998-continued.sh`, `0204-...`, `1510-...`,
  `1600-felix-refuses-a-pattern-kill-blind.sh`): every refusal and lift as
  today; a large payload judged within 20 s; a small payload runs no awk; an
  ungoverned checkout asks git for its remote once; no new process on a path
  that writes no fault row. After those parts run, no `hook-faults.log` exists
  in their memory roots: an existing part that leaves one means the fault
  classification is too broad.
- **The tick** (`1280-land-on-green-blind.sh` to `1289-land-on-green-round-9-blind.sh`):
  one row per unchanged wait; the notified kinds of G8 and A31 as they are,
  `skip` and `session` still not notified; a refusal not retried until head or
  main moves; 1288's recovery loop (a newest `skip`, `session`, `founder` or
  `refused` row of PR 5 dated 2026-10-18 under an empty PR list) still ends with
  two rows and no notification, which B3 guarantees.
- **The page** (`1300-` to `1360-stuck-pr-page-*`, `1450-` to
  `1495-lost-work-*`, `1570-` to `1585-helper-worktrees-*`): case 7's #108
  (fork) and #109 (author `someone-else`) stay `outside`, and never in
  `--queue`; case 17's "gh was called with pr list and api only" and "every gh
  api call is a GET"; the six source rows in the order gh land ledger lander
  budget origin; `--no-gh` asks gh nothing; 1340's R1 "gh is asked nothing but
  pr list, a GET of repos/<owner>/<name> and the billing GETs" stays true,
  because no PR in its fixture has a non-owner author (B25 asks nothing then).
- **Maintenance and next** (`0120-...`, `0460-...`,
  `0600-what-to-do-next.sh`): rows with `always` or a capability behave as
  today; `upkeep due: <name> — <desc>` text.

**Pinned values this batch changes on purpose.** Change only the expected
value; leave each assertion's text, since `tests/assertions.tsv` keys on it.
- `tests/parts/1310-stuck-pr-page-states-blind.sh:116`, case 9 (#111,
  `engine/harness/felix`): `needs-attended session` becomes `ready lander` (B30).
- `tests/parts/1330-stuck-pr-page-review-blind.sh:182` (#167, two trust-base
  paths): `needs-attended session` becomes `ready lander` (B30).
- `tests/lib/stuck-pr.sh`'s gh stub: `api user` (or `/user`) is answered
  with `{"login":"fixture","id":1,"type":"User"}`, or with `ctl/user.json` when
  that file exists, or fails with `ctl/user.rc`'s status and `ctl/user.err` when
  that exists. Without it #109 would read `unknown` under B28.

---

## 4. Assertions

Fixtures. **FX-T**: the land-on-green fixture (`_lg_build base`, `_lg_reset`)
with one open PR `N` the gh stub lists (`_lg_prs`), CI green on its head
(`_lg_green`), the deploy not owed, and ledger rows written by hand with times
relative to now. **FX-P**: the stuck-PR fixture (`_sp_build`) or the part's own
copy; for C027 an origin whose path ends `github.com/acme/app.git` and a stub
answering `pr list` for it and `api user`. **FX-D**: a home with
`projects/demo/{project.json,CLAUDE.md}` and `deny.tsv` holding
`Bash<TAB>git push .*--force<TAB>no forced pushes`, a repository whose `.felix`
names `demo`, `MEMR` an existing empty directory, a copy of `engine/harness` to
break, the payload `{"session_id":"b03","cwd":"<repo>","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"git push --force origin main"}}`,
run from the repository as
`env -i PATH=/usr/bin:/bin:/usr/sbin:/sbin HOME=<h> FELIX_HOME=<home> FELIX_MEMORY=<MEMR> /bin/bash <copy>/hooks/pre-tool`.
**FX-S**: a governed project `p` (its own home, or the suite's widget) with
`FELIX_MEMORY` the part's own directory, started from its repository with a
`{"source":"startup","session_id":"<id>"}` payload; the screen line and
context read with `python3 -c 'json.load'` as part 0120 does. [control] marks
an assertion true before the fix and after it.

The lander (FX-T):
- **A1** (B1) `N`'s only row: `session`, head `H`, `no checkout holds the gated head`, five hours old. One tick adds exactly one row: `waiting`, PR `N`, head `H`, worktree `-`, wall `0`, detail `waits on a session since <that row's time>: session: no checkout holds the gated head`; the osascript log holds one call with title `Felix: waiting #N`.
- **A2** (B2) A second tick straight after A1 adds no row and no osascript call.
- **A3** (B1, B2) As A1 with a `waiting` row for `N` and `H` 25 hours old after the session row: one new `waiting` row. With that row 23 hours old: none.
- **A4** (B1) Rows at head `H`: `session` 6 h old, `skip conflicting with main` 3 h old, `session` 1 h old: one `waiting` row; its `since` is the 6-hour row's time; its detail ends `session: no checkout holds the gated head`.
- **A5** (B2) [control] `session` 6 h, `skip a draft` 3 h, `session` 2 h, all at `H`: no `waiting` row.
- **A6** (B2) [control] `session` at an older head 6 h old, then `session` at `H` 1 h old, gh listing `H`: no `waiting` row.
- **A7** (B2) [control] For each of `skip a draft`, `skip labelled felix:hold`, `skip cross-repository: the head is not in this repository`, `skip its base is dev, not main: only pull requests into main are merged`, ten days old, with gh's list agreeing (draft, label, cross, base): no `waiting` row, no notification.
- **A8** (B1) gh lists `N` labelled `needs-founder`; its row `skip labelled needs-founder` 5 h old: one `waiting` row whose detail starts `waits on the founder since `.
- **A9** (B3) [control] gh lists no PR; `N`'s newest row is a `session` row ten days old: no row added, no notification.
- **A10** (B3) [control] `LAND/paused` exists; `N` listed with a 10-hour-old `session` row: no `waiting` row.
- **A11** (B4) After A1's `waiting` row, a third tick: `N` still has exactly one `session` row and no new `skip` row.
- **A12** (B4) `N`'s head is held by a fixture worktree and its row is `refused ... [main <origin/main sha>]` 5 h old: the tick adds a `waiting` row whose detail contains `: refused: ` and the felix stub logs no `merge`; the next tick logs none either.

The page (FX-P):
- **A13** (B33) #133's fixture `session` row plus a later `waiting` row for #133 at the same head: `felix land --prs --tsv` gives #133 the same state, needs and detail as the same run without the `waiting` row, the detail holding `the lander cannot use it: no checkout holds the gated head` (part 1310 case 23 reads `refused session`).
- **A14** (B33) [control] With that `waiting` row the ledger's newest row, the `lander` source row's detail contains `last ledger row` and `waiting:`.
- **A15** (B26) Slug `acme/app`, `api user` answering `{"login":"alice","id":2,"type":"User"}` whatever `--jq` is given. #7 by `alice`, CONFLICTING, one failed check: `needs-session session`. #8 by `alice`, one failed check: `red session`. #10 by `ALICE`, one failed check: `red session`.
- **A16** (B27) Same run: #9 by `bob`, one failed check: `outside nobody`; detail contains `bob`, `acme` and `alice`.
- **A17** (B27) [control] #12 by `alice`, cross-repository: `outside nobody`.
- **A18** (B28) `api user` exits 1 with `gh: Not Found (HTTP 404)`: #8 `unknown unknown`, detail contains `the signed-in GitHub account was not read`; #11 by `acme`, one failed check: `red session`.
- **A19** (B25, B28) `api user` answering `{"message":"Bad credentials"}`, then `{"login":"al ice"}`: #8 `unknown unknown` each time.
- **A20** (B25) A15's gh log has exactly one line starting `api user`. A run whose PRs are all by `acme` or cross-repository has none; a `--no-gh` run asks gh nothing.
- **A21** (B29) [control] In A15's run every gh call starts `pr list` or `api`, and no `api` call carries `-X`, `--method`, `-f`, `-F`, `--field`, `--raw-field` or `--input`.
- **A22** (B25) `--queue` over two projects, each listing one same-repository PR by a non-owner: at most one `api user` line.
- **A23** (B30) fixture/home, a green PR changing only `engine/harness/felix`, no ledger row: `ready lander`, detail contains `touches the trust base: engine/harness/felix`.
- **A24** (B30) The same changing `engine/harness/felix` and `engine/harness/lib/verify.sh`: `ready lander`, detail names both.
- **A25** (B31) A23's PR with a same-head `session` row: `refused session`; with a same-head `refused` row on the current origin/main instead: `refused session`.
- **A26** (B31) A23's PR with the ledger path a directory: `unknown unknown`.
- **A27** (B32) [control] A green PR changing `projects/felix/risk.tsv` and `engine/harness/felix`: `founder founder`, detail contains `trust base`.
- **A28** (B30) Over part 1310's whole fixture, no `pr` row of `--prs --tsv` has state `needs-attended`.

PreToolUse (FX-D):
- **A29** (B19) [control] Intact copy: the force push exits 2 and writes a says.log row; `git status` exits 0; neither leaves `MEMR/hook-faults.log`.
- **A30** (B16, B17) `lib/deny-read.sh` renamed `deny-read 2.sh`: exit 0; the log holds one row of five fields: an ISO time or `-`, `pre-tool`, `demo`, `Bash`, a reason containing `deny-read.sh`.
- **A31** (B17) `lib/deny.sh` renamed: exit 0, one row, third field `-`, reason `lib/deny.sh did not load`.
- **A32** (B17) `lib/resolve.sh` renamed: exit 0, one row, reason `lib/resolve.sh did not load`.
- **A33** (B17) `lib/deny-read.sh` replaced by the one line `_FELIX_DENY_READ='BEGIN { exit 3 }'`: exit 0, one row whose reason contains `awk exited 3`.
- **A34** (B18) `_felix_deny_first() { : "$_felix_b03_unbound"; }` appended to the copy's `lib/deny.sh`: exit status not 2, one row whose reason starts `the hook ended with status `.
- **A35** (B18) `: "$_felix_b03_unbound_load"` appended to the copy's `lib/deny.sh`: exit status not 2, one row.
- **A36** (B18) `/bin/bash -c 'ulimit -u 1; exec /bin/bash "$0"' <copy>/hooks/pre-tool` fed the payload: exit status not 2; one row, time `-` or ISO, reason starting `the hook ended with status `. Skipped when `id -u` is 0.
- **A37** (B17) `deny.tsv` replaced by a directory of that name: exit 0, one row, reason `deny.tsv is not a readable file`.
- **A38** (B17) The payload with `tool_name` removed: exit 0, one row, reason `the payload names no tool`.
- **A39** (B19) [control] The repository without `.felix`, with `deny-read.sh` renamed: exit 0, no log.
- **A40** (B19) [control] `projects/demo/deny.tsv` removed: exit 0, no log.
- **A41** (B20) `FELIX_MEMORY` names a directory that does not exist, `deny-read.sh` renamed: exit 0, and the directory still does not exist.
- **A42** (B21) Sourcing the copy's `lib/deny.sh` with no `deny-read.sh` beside it, `felix_deny_match <home>/projects/demo Bash 'git push --force origin main'` exits 2 and prints text containing `deny-read.sh`. [control] With the intact lib it exits 0 printing `no forced pushes`, and `git status` exits 1.

Session start (FX-S):
- **A43** (B7) `LAND/ledger.tsv`: #425 `session` 30 h old and `waiting` 2 h old (detail `waits on a session since <t>: session: no checkout holds the gated head`); #7 `waiting` 30 h old; #9 `waiting` 1 h old then `landed` 30 min old. The context holds the header line and exactly one line starting `  #`, which starts `  #425 waits on a session since `; the screen line contains ` · PRs waiting: 1`.
- **A44** (B7) PRs #1 to #7 each with a `waiting` row 1 h old: five `  #` lines, #1 to #5 in that order, then `  and 2 more: felix land --prs`; ` · PRs waiting: 7`.
- **A45** (B8) [control] No `LAND`: no header line, no `PRs waiting` token.
- **A46** (B8, B34) `LAND/ledger.tsv` a directory: the context contains `Which pull requests wait could not be read:` and that path; ` · PRs waiting: unknown`; exit 0.
- **A47** (B9) `LAND/paused` holding `held for the test` then `second line`: the context contains `The lander is paused, so nothing merges with nobody present: held for the test` and `felix land --resume ends the pause.`, and not `second line`; ` · lander paused`. An empty `paused`: `: no reason given`.
- **A48** (B10) `MEM_P/overnight/deferred.tsv` with rows `1790169800<TAB>question<TAB>b<TAB>-` and `1790169788<TAB>approval<TAB>a<TAB>-`, no night, session id `bystander`: the context contains `2 decision(s) deferred overnight wait on the founder, the oldest from 2026-09-23 (UTC).` and `felix overnight --report reads them back, and felix overnight --clear clears them once read.`; ` · deferred for you: 2`.
- **A49** (B10, B12) The same rows with a live night granted to session `s1` (`felix_overnight_start`): started as `s1`, the context holds the direction's longest line, `Granted to this session:` and the deferred paragraph; started as `bystander`, the deferred paragraph and no line of the direction [the direction half is a control].
- **A50** (B11) `deferred.tsv` a directory: `Decisions deferred overnight could not be read:` and ` · deferred for you: unknown`. One row whose first field is `x`: `the oldest from an unknown date.`
- **A51** (B13) `MEMR/hook-faults.log` rows: 1 h old `pre-tool p Bash lib/deny.sh did not load`; 8 days old `pre-tool p Bash old`; 2 h old `pre-tool other Bash theirs`; last, `- pre-tool - - the hook ended with status 128 before a verdict`; the file's time now. The context contains `PreToolUse could not judge 2 tool call(s) in the last 7 days`, `The newest, at a time not recorded: the hook ended with status 128 before a verdict.` and the log's path; ` · calls not judged: 2`.
- **A52** (B13) As A51 with a row 9 days old after the `-` row: `could not judge 1 tool call(s)` and `The newest, <the 1-hour row's time>: lib/deny.sh did not load.`
- **A53** (B13) Only the `-` row, the file's time set eight days back with `touch -t`: no paragraph, no token.
- **A54** (B13) The log a directory: `Whether PreToolUse judged every call could not be read:` and ` · calls not judged: unknown`.
- **A55** (B13, B17) End to end: A30's run writes its row under `MEMR`; a session start of project `demo` with `FELIX_MEMORY=MEMR` shows ` · calls not judged: 1`.
- **A56** (B14) `maintenance.tsv`: `snapshot<TAB>14<TAB>founder<TAB>bring the snapshot up` and `weekly<TAB>7<TAB>always<TAB>a cleanup`; the log: `snapshot` ran 28 days ago, `weekly` never. The context's `Maintenance due:` line is exactly `Maintenance due: weekly`; it contains `Due, and waiting on the founder's yes rather than a session: snapshot (28 days since it last ran, every 14)`; the screen contains ` · 2 due (yours: snapshot)`, and the 0120 sed gives `2`, equal to `felix maintenance | grep -c '^  DUE '`.
- **A57** (B14) Only the `snapshot` row: no `Maintenance due:` and no `Do them on one branch` line; the founder line; ` · 1 due (yours: snapshot)`. With no log row for it: `snapshot (never run, every 14)`.
- **A58** (B15) [control] No `founder` row and none of this batch's state: no line starting `Due, and waiting on the founder's yes`, and the screen line matches `^Felix: p( · [0123456789]+ due)?( · new tooling found)?$`.
- **A59** (B6) With A43's ledger, A47's `paused`, A48's queue and A51's log at once: the tokens come in the order of B6, and each new paragraph lies after the `Memory: ` line and before `Read before planning:`; the screen line is one line.
- **A60** (B22) `felix_maint_status` on A56's table prints `due<TAB>snapshot<TAB>28<TAB>14<TAB>bring the snapshot up`; `felix_maint_unreachable` prints nothing; `felix maintenance` prints a line starting `  DUE     snapshot`.
- **A61** (B23) `felix_next` on A56's table: the rank-4 row for `snapshot` has owner `founder`, the one for `weekly` owner `felix`.
- **A62** (B24) This tree's `projects/felix/maintenance.tsv`: the `snapshot` row's third field is `founder`; `deployed`, `discover`, `promote`, `lessons`, `graphify` and `handoff` keep `always`.
- **A63** (B35) [control] `wc -l` of `hooks/session-start` ≤ 780 and of `lib/green-tick.sh` ≤ 500.

---

## 5. Parts

- `engine/harness/tests/parts/1670-session-start-names-what-waits-blind.sh`:
  A29-A63 (PreToolUse, session start, maintenance).
- `engine/harness/tests/parts/1680-the-lander-ages-what-waits-blind.sh`:
  A1-A28 (the tick and the page).

Each builds its own fixture under `$TMP` and needs no `groups.tsv` row. Both
run under bash 3.2 with BWK awk and under bash 5 with gawk.

---

## 6. Out of scope

**Not fixed: not a defect.**
- C087's second half (a green rollup shown `ready` while the tick's gate check
  says "GitHub could not be asked"). felix-home has one workflow, `gate.yml`,
  so the rollup and `_felix_merge_gate_held` (`escape.sh:536`) agree whenever
  gh answers; the tick asks again every tick; and the page already prints
  `the lander: skip: gate run not green: ...` on the PR's line
  (`pr-status-state.sh:222`). "The reader is told nobody needs to act" is false.
- C038's "deployed can never clear on its own". Felix records runs and does
  not perform routines by design (`maintenance.sh:7-11`); any session clears it
  with `felix maintenance --ran deployed` in a PR, as #416 did. The tick cannot
  write the committed log without dirtying the home, which pauses it
  (`green-tick.sh:237-241`).
- C029's "deny.tsv missing allows": a project with no table has no rules
  (`felix new` writes none); B19 keeps it silent.

**Left for later, and why.**
- A land row in `felix status` or `felix pulse` (C002, C029 sketches): the
  status rows are pinned as `settings schedule pulse reach gate`
  (`1100-declared-tools-reach-the-pulse-and-felix-status.sh:410`) and read by
  the dash band; a sixth row is a surface decision of its own. Session start
  is the surface the charter gives Felix.
- Telling that the lander stopped (an unloaded LaunchAgent, no tick in 15
  minutes): a quiet ledger is normal when nothing changes, so it needs a
  heartbeat the tick does not write. `felix land --status` reads it on demand.
- The closing notice at Stop, for waiting PRs and for a night that ended
  (C069's "notify when a night ends"): the stop hook has no closing notice yet;
  it is roadmap step 7 (`direction.md` §5), the engine has no notify channel
  beyond the tick's osascript, and `hooks/stop` is 610 lines. The next session
  start now names both.
- Clearing the two stale deferred rows (#304, #310): the queue is cleared by a
  person (`overnight.sh:388-389`); B10 tells him it is there.
- `felix maintenance` marking founder rows, and founder rows in the stop hook's
  overnight due list and the pulse log: `felix` and `hooks/stop` are over 500
  lines and may not grow; session start and `felix next` carry the mark.
- A session-start self-probe of the deny reader (C029 sketch): session start
  sources no deny library (`session-start:37-70`), and the fault log catches a
  broken reader from its first call.
- A resolve that fails under fork exhaustion reads as ungoverned: telling the
  two apart needs `felix_resolve_project` to return a third status, in
  `lib/resolve.sh`, which may not grow.
- A list of governed accounts in `project.json` (C027 sketch): a new
  configuration key; the signed-in account covers a member's own PRs.
- The risk rows with a verifier channel that the page marks `founder` (C087
  "also seen"), and mergeability UNKNOWN reading as `session` (C002 "extra"):
  separate findings.
- Spec v2's §3 governed account and §4 state 9 are superseded by B25-B30; the
  spec lives under the memory root, outside this tree, so this contract is the
  record.

---

## 7. Founder PR

None. Every path here merges on green: `hooks/pre-tool` and `lib/deny.sh` are
in the trust base, and judge-changing PRs land unattended (`direction.md` row
24); `projects/felix/maintenance.tsv` is not a commission, escape or founder
table; no `.github/workflows` file, deny or escape row, commission grant or
publishing is involved.

---

## 8. Red

Run on 2026-10-24 at f1f9a41f (main 69b51a61 and the two blind parts, no code
changed), both parts in one run under bwk (macOS awk, bash 3.2) by alone.sh from
a fresh temporary directory. 65 assertions: A1 to A63 and two fixture controls
that part 1680 opens with.

| Part | Assertions | Failed | Passed | Skipped |
|---|---|---|---|---|
| 1670 | 35 (A29-A63) | 27 | 8 | 0 |
| 1680 | 30 (A1-A28, two fixture controls) | 16 | 14 | 0 |
| Total | 65 | 43 | 22 | 0 |

Failed in 1670: A30-A38, A42-A44, A46-A52, A54-A57, A59-A62. Failed in 1680: A1,
A3, A4, A8, A12, A13, A15, A16, A18, A19, A20, A23, A24, A25, A26, A28. Every
failure is the missing behaviour: the pre-tool hook writes no `hook-faults.log`
row on any path, `felix_deny_match` answers 1 where the reader is missing, the
tick writes no `waiting` row, session start prints `Felix: <p>` with none of the
new paragraphs or tokens, `snapshot` is still `always`, a non-owner's PR reads
`outside`, and a trust-base PR reads `needs-attended`. No failure comes from the
fixture (the two fixture controls pass).

The 22 that passed carry no new behaviour that was already true: 17 are
controls and 5 are vacuous.

**Controls, true before and after the fix (17):**
- A29: an intact hook refuses the forced push, allows `git status` and leaves no
  fault log.
- A39, A40: a directory no project governs, and a project with no `deny.tsv`,
  write no fault row.
- A45: no `LAND` directory, no waiting-PR header and no token.
- A58: with none of this batch's state the screen line is `Felix: p` plus the
  old tokens.
- A63: `hooks/session-start` is 780 lines and `lib/green-tick.sh` 479 on this
  tree, inside B35's bounds. The hook is at its limit, so the fix must move
  code out of it before it adds a line.
- The two fixture controls of 1680: a tick over a green PR no checkout holds
  writes one `session` row and no notification; the tick's own `skip` for a
  `needs-founder` label reads `labelled needs-founder`.
- A5, A6, A7, A9, A10: a `skip` for a draft ends the run; an older head does
  not count; hold rows ten days old give no row; a PR gh does not list gets
  none; a paused tick writes none.
- A14: the lander source row names the newest ledger row of any kind.
- A17: a cross-repository PR is `outside`.
- A21: gh is asked only `pr list` and GETs through `api`.
- A27: a green PR changing a founder path and the trust base is `founder`.

**Vacuous before the fix (5):** each holds because the code it guards is not
there yet, and tests the fix once it is.
- A2: no tick writes a `waiting` row, so a second tick adds none.
- A11: no `waiting` row exists, so a third tick still holds one `session` row
  and no `skip` row.
- A22: gh is never asked `api user` yet, so `--queue` asks at most once.
- A41: the hook writes nothing on any path, so a missing memory root stays
  missing and uncreated.
- A53: session start reads no fault log, so a log of one old `-` row adds no
  paragraph.
