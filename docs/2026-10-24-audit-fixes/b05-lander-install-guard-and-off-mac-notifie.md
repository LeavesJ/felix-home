# Audit fixes, batch b05: the lander's install guard and its off-Mac alerts

Three findings of the 2026-10-24 audit about land on green (docs/2026-10-15-land-on-green-contract.md,
"the land contract", not edited here: it is 512 lines): what the founder hears when the lander needs
him (C018), which project `felix land --install` serves (C013), and what install does off macOS
(C042). This file is the whole specification the blind assertions are written from: what must be
true, not how. G1-G9 and "land A1" to "land A31" are the land contract's clauses; a bare A-number
is this file's. Section 9, the review round, wins over sections 2-5 where they differ.

## 1. Defects

**C018. The lander's only alert is a banner on this Mac.** Every notified ledger row sends one
`osascript display notification` (lib/green-tick.sh:50-57; the trampoline's `owed()`,
lib/green-install.sh:105-113), its result discarded. *Scenario:* the founder is away; at 01:00 the
tick refuses a pull request, or pauses, or the trampoline writes `deploy-owed`; nothing reaches his
phone. *Severity: low* (second skeptic): banners are delivered (section 6), land A10 is met.
*Fixed because the founder decided it (2026-10-24; its sender on 2026-10-26, section 7):*
"When Felix needs the founder (any notified land row, a stopped or paused lander, a refusal), it
mentions the repository owner (or a configured GitHub login) in one standing issue on the governed
repository, created once with a fixed title and reused, so the alert reaches the GitHub app on his
phone. One comment per new event, never a repeat of an unchanged one; a failed post is itself
recorded and shown on felix status. It must work for any Felix user (GitHub is already required) and
must never post outside the governed repository."

**C013. `felix land --install` serves a project the lander does not serve.** `_gt_install`
(lib/green-install.sh:155-188) installs `felix.land.<p>` for whatever project `$PWD` resolves to, but
the trampoline enters `$FELIX_HOME_DIR` (:114) and its tick serves the home's project
(lib/green-tick.sh:466-470). *Scenario:* `--install` in another checkout, `webapp`, adds a second job
ticking felix-home; webapp's PRs never land while its `--status` says installed and loaded; its
`--pause` writes a file nothing reads; `--uninstall` in the home leaves `felix.land.webapp` running.
*Severity: high* (both skeptics). The stranger arm is not reachable today (0.49.232, the public
snapshot, predates `felix land`).

**C042. Off macOS, `felix land --install` writes macOS files before it fails.** With no launchd,
`_gt_install` writes the trampoline and `~/Library/LaunchAgents/felix.land.<p>.plist`, then dies at
`launchctl bootstrap` (lib/green-install.sh:160-186), where `felix pulse --install` checks first
(felix:6589-6593); `felix help` gives no platform note (felix:467). *Scenario:* on Linux both files
stay and `--status` reads `installed yes`. *Severity: low*: land on green is Mac-only (land contract
line 15, G9; direction.md row 24); left are the check's order and the help text.

## 2. Required behaviour

Terms. **The home** is `$FELIX_HOME_DIR`. **The home's project** is what
`felix_resolve_project "$FELIX_HOME_DIR"` names. **A project's land directory** is
`$(felix_mem_dir <project>)/land` (G1). **A GitHub origin**: the home's origin URL as its git config
holds it (`git config --get remote.origin.url`, before any `url.<base>.insteadOf` rewrite) is
exactly `https://github.com/OWNER/REPO`, `git@github.com:OWNER/REPO` or
`ssh://git@github.com/OWNER/REPO`, each optionally ending `.git`, where OWNER is 1-39 characters
from `ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-` not starting with `-`, and
REPO is 1-100 characters from that set plus `.` and `_`, and is neither `.` nor `..`. Any other URL
(a local path, another host, a user, a password, a port, a query, a trailing `/`) is not. **The
repository** is OWNER/REPO. **An event** is a ledger row of kind `landed`, `refused`, `founder`,
`deployed`, `deployed-unverified`, `paused`, `timeout`, `stuck`, `gh`, `fetch`, `deploy-owed` or
`unresolved` (the tick), or `deploy-owed` or `unreadable` (the trampoline), whose banner is sent: a
`refused` row land A13 keeps quiet, or a row `_gt_row_once` or `owed()` did not write, is not one.
**The event's detail** is the ledger detail up to, not including, its first ` [main ` (the text the
banner shows). **The title** is exactly `Felix needs you`. **The mention login** is `alert_login` in
the home's `projects/<p>/project.json` when that key is present, else `.owner.login` from call 2 of
B3.

### Who is told, and where (C018)

- **B1. When.** After each event's ledger row is written and its banner sent, exactly as today,
  Felix makes one post attempt. No other row starts one (`skip`, `session`, `readable`, a quiet
  `refused`, and any row a person's `felix land` command writes). The attempt runs in the same
  process: in the tick inside `_gt_say`'s call, in the trampoline inside `owed()` before it exits 1.
- **B2. Not a GitHub origin.** When the home's origin is not a GitHub origin, the attempt runs no gh
  command and appends one `failed` record (B7) whose note is
  `origin: the home's origin is not a github.com repository URL`. No record ever holds the origin
  URL's text (a URL can carry a token).
- **B3. The calls.** An attempt runs at most these gh commands, in this order, each with `GH_HOST`
  and `GH_REPO` removed from its environment and `GH_PROMPT_DISABLED=1`. It may add `--jq`, `-q`,
  `--json` or `--limit` (100 or more) to calls 1-4, and adds nothing that writes (`-X`, `--method`,
  `-f`, `-F`, `--field`, `--raw-field`, `--input`) to them:
  1. `gh api --hostname github.com user`, read for `.login` (the posting account, POSTER);
  2. `gh api --hostname github.com repos/OWNER/REPO`, read for `.full_name`, `.owner.login`,
     `.owner.type`, and `.permissions.admin`, `.maintain`, `.push`;
  3. `gh issue list --repo github.com/OWNER/REPO --state all`, read for each issue's `number`,
     `title` and `author.login`;
  4. only when 3 finds no standing issue (B5):
     `gh issue create --repo github.com/OWNER/REPO --title "Felix needs you" --body-file -`;
  5. R1's dispatch to `felix-alert.yml` (section 9), which replaced `gh issue comment`.

  The notifier runs no other gh command (no `issue comment|edit|close|reopen|lock|delete|transfer|pin`,
  no `pr` or `label`, no `workflow` but R1's, no writing `api`). Every call names exactly
  `github.com/OWNER/REPO`, `repos/OWNER/REPO` or `user`.
- **B4. Never outside the governed repository.** The attempt creates and dispatches nothing, and
  appends one `failed` record whose note starts with the step name shown, when: `alert_login` is
  present and is not 1-39 characters from
  `ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-` or starts with `-`
  (`alert_login:`; no gh call at all); call 1 or 2 exits non-zero, times out (B9) or gives no value
  for the field it is read for (`gh api user:`, `gh api repos:`); `.full_name` is not OWNER/REPO
  compared without regard to case, as after a rename, transfer or redirect (`full_name:`, naming
  what GitHub answered); none of the three permissions is `true`, so the account cannot write to it
  (`permission:`; this keeps a clone of someone else's repository from posting on it); `alert_login`
  is absent and `.owner.type` is not `User`, so the mention would name an organization and notify no
  one (`owner:`, saying to set `alert_login`); call 3 exits non-zero, times out, or its answer
  cannot be read (`gh issue list:`); call 4 exits non-zero, times out, or prints no
  `https://github.com/OWNER/REPO/issues/N` with N digits and OWNER/REPO compared without regard to
  case (`gh issue create:`). Call 5 is judged by R3. After the first failing call no later call
  runs. A gh call's note names its exit status (`exited N`) or `timed out after S seconds`.
- **B5. The standing issue** is the lowest-numbered issue call 3 lists whose title is exactly the
  title and whose `author.login` is POSTER (without regard to case), open or closed. With none, call
  4 creates it; its body holds no `@` and none of the event's detail. Felix never edits, closes,
  reopens, labels or assigns it. Against a gh that lists the issue it created, `gh issue create`
  runs once over any number of attempts.
- **B6. The comment** is gone: R1 and R2 (section 9) send a dispatch whose body is fixed text.
- **B7. The record.** Every attempt that runs (B8's skip runs none) appends exactly one row to
  `<land directory>/alerts.tsv`, eight tab-separated fields: the UTC time (`YYYY-MM-DDTHH:MM:SSZ`);
  R3's state (`dispatched`, `no-alert-workflow` or `failed`); the event's kind; the pull request
  number or `-`; the issue as `OWNER/REPO#N` or `-`; the run URL or `-`; the note (R3's, or B2's,
  B4's, B9's or B11's reason for `failed`); the event's detail with every `$HOME/` written `~/`. A
  tab, CR or newline in any field becomes a space. A record that cannot be appended changes nothing
  else (B10).
- **B8. No repeats.** An event whose kind, pull request and detail (field 8) equal the newest
  `dispatched` record's runs no gh call and appends no record. A `failed` or `no-alert-workflow`
  record does not count: the same event raised again (the next hourly `paused` row) is attempted
  again (R4).
- **B9. Bounded.** Each gh call of an attempt is ended once it has run `_FN_SECS` seconds (default
  30; set only by a test, on the line after the CLI sources lib/green-tick.sh, as land A28 lets a
  test set `_GT_WDSECS`; the trampoline carries the value its install ran with): TERM, then KILL if
  it still runs two seconds later. The process gh ran as is then no longer running, and the attempt
  records `failed` with a note saying `timed out`.
- **B10. Landing is unchanged.** Whatever the gh calls answer, or if they hang (B9), the ledger rows
  (fields 2-7), the banners (osascript calls), the `felix merge` runs, the deploys, the `paused`
  file and the exit status are those of the same scenario in a home whose origin is not a GitHub
  origin. The notifier writes no ledger row and sends no banner of its own.
- **B11. The trampoline** attempts its own events by B1-B10. It runs no git and sources no file from
  the home or the plugin cache: it carries its own code, written by `--install`. It reads the
  repository and `alert_login` (when set) from `<its ledger's directory>/alerts.repo` (never holding
  the origin URL's text), which `--install` writes and every attempt of a tick that resolved its
  project rewrites from the home's origin and `project.json` (a non-GitHub origin recorded as none);
  neither rewrites the installed trampoline or plist. With the file absent or naming none, it runs
  no gh call and appends one `failed` record noting `record:` (or B2's reason for a recorded none).
  `felix land --install` runs no gh command.
- **B12. A tick with no project.** Land A22's hand-run tick that resolves no project and has no
  `FELIX_LAND_LEDGER` makes no attempt and writes no record. With `FELIX_LAND_LEDGER` set, its
  `unresolved` row is attempted from that ledger directory's `alerts.repo`, as B11.
- **B13. `felix status` shows it.** `felix status --tsv` prints a sixth row after `gate`:
  `alerts<TAB>state<TAB>value<TAB>detail`, read from the home's project's `alerts.tsv` alone. It
  writes nothing and runs no gh. Its newest record decides:

  | newest record | state | value | detail |
  |---|---|---|---|
  | the home resolves no project | `unknown` | `-` | says so, naming the home |
  | no `alerts.tsv`, or no row | `none` | `-` | `no alert has been tried for <p>` |
  | not 8 fields, or field 2 not one of R3's three states | `unknown` | `-` | says the record cannot be read |
  | `dispatched` or `no-alert-workflow` | `value` | that state | as R5 (section 9) |
  | `failed` | `value` | `failed` | its time, kind, `#PR`, and field 7 |

  The first five rows, their order and their content are unchanged. Plain `felix status` prints it
  the way it prints the others.

### The lander serves the home's project only (C013)

- **B14.** `felix land --install`, `--pause [reason]`, `--resume`, `--tick` and `--status [--tsv]`,
  run from a checkout whose project resolves and is not the home's project, exit 1, print nothing on
  stdout, and print on stderr a refusal naming both projects and containing
  `land on green lands the home's own pull requests only`. They write nothing: no plist, trampoline,
  `launchctl` call, `paused` file, ledger row or record in either project's land directory.
- **B15.** When the checkout's project resolves and the home's project does not, the same commands
  exit 1 with a refusal on stderr containing `resolves no project`, and write nothing, as B14.
- **B16.** From the home, and from any worktree of the home, every `felix land` command behaves as
  today. **B17.** `--uninstall`, `--prs` and `--queue` are refused from no project; `--uninstall`
  from another project still boots out and removes that project's job (one installed before this).

### Off macOS (C042)

- **B18.** `felix land --install` from the home when no `launchctl` is on `PATH` exits 1, prints a
  refusal containing `launchctl`, `macOS` and `nothing was written`, prints no cron line (one would
  bypass land A1's and A31's checks), and writes nothing: no `$HOME/Library`, land directory or
  `alerts.repo`, no gh call. The check reads `PATH`, so CI's stub `launchctl` keeps every install
  case. **B19.** The `felix land` line of `felix help` says `macOS only` (felix does not grow).

## 3. What must not change

- **Ledger rows** (kinds, seven columns, deduplication, order): 1280 (G8, G4), 1283 (land A10), 1282
  (land A13), 1288, 1289 (land A31). **The banner**: one osascript notification per event, same
  title and detail, after its row; a failed or hung post sends none of its own: 1280-1284, 1288, 1289.
- **In a home whose origin is not a GitHub origin** (every existing land fixture's origin is a local
  path), the tick and the trampoline make no gh call beyond today's: 1280 ("G2: and does nothing
  else: it asks gh nothing"; "G6: the tick writes no label, comment, review or merge through gh"),
  1285 (land A25). G6 narrows by the founder's decisions: the tick still writes nothing to a pull
  request; its only gh writes are `issue create` and R1's dispatch.
- **The tick's lock, watchdog and exit 0** in every case (G2; land A4, A5, A25, A28): 1280, 1282, 1285.
- **The trampoline** reads nothing of the home before land A31's read, runs no git in the unreadable
  case (1288, `_lg_cnt git` 0), runs no felix but main's accepted entry, exits 1 on every owed case
  (1282, 1288), and no tool it runs names `plugin.json` or reads it on stdin (1289). A tick never
  rewrites an installed trampoline or plist (1289, byte for byte).
- **Install from the home or a worktree** with a `launchctl` on `PATH`: the same plist and trampoline
  paths and the line `land on green is installed for <p>: <plist>` (1281, 1282, 1289).
  **`--uninstall`** from anywhere (1281-1284, 1288, 1289). **`--status` from the home**: installed,
  loaded, paused, `last`, then each pull request's last row, writing nothing, with no alert state
  (1280, 1288, 1360). **`--prs`, `--queue`** (1300-1360) and **land A22's unresolved row** (1283).
- **`felix status`'s first five rows**, read-only and offline, and its plain form (S2): 1100, 1110.
  **The one existing pin this batch changes**, in 1100: "and prints exactly five rows: settings,
  schedule, pulse, reach, gate" (line 409) becomes "and prints exactly six rows: settings, schedule,
  pulse, reach, gate, alerts", expecting `settings schedule pulse reach gate alerts `; its S4 guard
  (line 431, `= 5`) becomes `= 6`, the two `bad` details "status did not answer six rows". The record
  step re-records both names. The reach spec's S1 and S2 ("five rows") read as amended here, and
  lib/status.sh's header comment says six.
- **Sizes**: lib/green-tick.sh (1280 G1), lib/green-install.sh, lib/status.sh (1100) and
  lib/notify.sh under 500 lines; felix no longer; tests/run two part lines more (1040's cap is 500).
  **The lints over lib/*.sh**, which read lib/notify.sh: 0370, 0960, 1000, 1030, 1497 (no gawk
  builtins; `LC_ALL=C` on every awk, sed, sort, cut, tr), 1530; land A18's and A28's rules; bash 3.2.

## 4. Assertions

**Fixture F1 (part 1710)**, a home of its own: a bare origin at `$F1/github.com/fixture/lgh.git`;
the home `$F1/home` cloned from it, on `main`, whose pushed commit holds
`engine/.claude-plugin/plugin.json` (version 9.0.0), `projects/lgh/project.json` (remote_match
`github.com/fixture/lgh`) and `projects/other/project.json` (remote_match
`github.com/fixture/other`); `$F1/other`, a repository with one commit and origin
`$F1/github.com/fixture/other.git`; `$F1/wt`, a worktree of the home on branch `w`. Stubs first on
`PATH` in `$F1/bin`: `launchctl` (logs its argv; `print` and `list` exit 113, all else 0), `gh` and
`osascript` (log, exit 0). Each run is `felix land ...` from the named directory with
`FELIX_ALLOW_RED`, `FELIX_KERNEL`, `FELIX_KERNEL_CACHE` unset, `HOME` a fresh `$F1/user.N`,
`FELIX_HOME=FELIX_HOME_DIR=$F1/home`, `FELIX_MEMORY=$F1/mem`. **The no-launchd `PATH`** is
`$F1/bin2:$F1/mirror`: `$F1/bin2` holds the gh and osascript stubs only; `$F1/mirror` a symlink to
every executable in every directory of the caller's `PATH`, first one winning, except any named
`launchctl`.

**Fixture F2 (part 1720)**, the shared land fixture: `_lg_build amend` from
tests/lib/land-on-green.sh (`$LGH`, `$LAND`, the osascript log, `$LATR`), whose origin is a local
path. **The GitHub state** adds, and the part undoes at its end:
`git -C "$LGH" config remote.origin.url https://github.com/fixture/lgh.git` and
`git -C "$LGH" config url."$LGO".insteadOf https://github.com/fixture/lgh.git` (so fetch stays
local, `felix_repo_slug` still reads `fixture/lgh` and the project still resolves);
`GIT_ALLOW_PROTOCOL=file`, `GH_HOST=evil.example` and `GH_REPO=someone/else` in each run's `LGX`
(set after each `_lg_reset`, which empties it); and a gh wrapper in front of the fixture's gh. The
wrapper logs each call's argv and whether `GH_HOST` and `GH_REPO` are set, keeps the standard input
of `issue create` and `issue comment`, and answers: `api ... user` with `{"login": L}` (L defaults
to `fixture-bot`); `api ... repos/fixture/lgh` with `full_name` (default `fixture/lgh`), `owner`
`{login: fixture, type: (default User)}` and `permissions`
`{admin: false, maintain: false, push: (default true)}`; `issue list` with its issues file (`[]` at
first); `issue create` by adding the issue and printing `https://github.com/fixture/lgh/issues/<n>`;
`issue comment N` with `https://github.com/fixture/lgh/issues/N#issuecomment-<k>`; `workflow run`
by keeping its argv and its `body=` value, printing
`Created workflow_dispatch event for felix-alert.yml at main` on stderr and
`https://github.com/fixture/lgh/actions/runs/<n>` on stdout, or, when the control file `workflow`
exists or the workflow named is not `felix-alert.yml`, exiting 1 with
`could not find any workflows named <name>` on stderr. It applies `--jq` with jq as the fixture's gh
does. A control file per step (`user`, `repos`, `list`, `create`, `comment`, `dispatch`) makes that
step exit a given status, or write its pid and `exec sleep 300`. Every other call goes to the
fixture's gh. **A patched CLI copy**, as in 1285, sets `_FN_SECS=2` on the line after it sources
lib/green-tick.sh. **BODY** below is the dispatch's `body=` value, read by line. Controls are
marked **(control)**: they hold before the fix and after it.

**Part 1710**

- **A1 (B16, control).** `--install` from `$F1/home`: exit 0; prints
  `land on green is installed for lgh`; writes `Library/LaunchAgents/felix.land.lgh.plist` and the
  trampoline; one `launchctl bootstrap` is logged.
- **A2 (B16, control).** The same from `$F1/wt`: plist `felix.land.lgh`.
- **A3 (B14).** `--install` from `$F1/other`: exit 1; stdout empty; stderr contains `other`, `lgh`
  and `land on green lands the home's own pull requests only`; no `felix.land.other.plist`, no
  `Library/Application Support/felix/land/other`, an empty launchctl log, no `$F1/mem/other/land`.
- **A4 (B14).** `--pause x` from `$F1/other`: exit 1; neither `$F1/mem/other/land/paused` nor
  `$F1/mem/lgh/land/paused` exists.
- **A5 (B14).** With `$F1/mem/lgh/land/paused` written, `--resume` from `$F1/other` exits 1 and the
  file is still there.
- **A6 (B14).** `--status` and `--status --tsv` from `$F1/other` each exit 1 with stdout empty.
- **A7 (B14).** `--tick` from `$F1/other`: exit 1; no `ledger.tsv` under `$F1/mem/other` or
  `$F1/mem/lgh`; an empty gh log.
- **A8 (B17, control).** `--uninstall` from `$F1/other`: exit 0; prints
  `land on green is uninstalled for other`; `launchctl bootout gui/<uid>/felix.land.other` logged.
- **A9 (B17, control).** `--prs --no-gh` from `$F1/other`: its stderr does not contain
  `home's own pull requests`.
- **A10 (B15).** With the home's `projects/lgh/project.json` remote_match set to
  `github.com/fixture/nothing` (restored after): `--install` from `$F1/other` exits 1, stderr
  contains `resolves no project`, and nothing is written (as A3 checks).
- **A11 (B18).** `--install` from `$F1/home` under the no-launchd `PATH` with a fresh `HOME`: exit
  1; output contains `launchctl`, `macOS` and `nothing was written`; `$HOME/Library` does not exist;
  `$F1/mem/lgh/land` does not exist; an empty gh log. Fixture control: under that `PATH`,
  `command -v launchctl` finds nothing and `command -v git` finds one.
- **A12 (B18, control).** The same install with `$F1/bin` first on `PATH` succeeds, as A1.
- **A13 (B19).** The `felix help` line starting `    felix land` contains `macOS only`.

**Part 1720** (A16 and A18-A34 as restated in the review round, section 9)

- **A14 (B2, control).** F2 as built: `--pause "r1"` then `--tick` writes one `paused` row, sends
  one banner titled `Felix: paused`, and the fixture's gh log is empty.
- **A15 (B2, B7).** That run appends one `alerts.tsv` row: eight fields; field 2 `failed`; field 3
  `paused`; field 7 starts with `origin:`. `alerts.tsv` does not contain the text of `$LGO`.
- **A16 (B3, B5, R1-R3).** GitHub state: `--pause "held for the alerts test"` then `--tick`. The
  wrapper logs exactly, in order: `api` naming `user`, `api` naming `repos/fixture/lgh`,
  `issue list`, `issue create`, `workflow run`. `issue create` carries `--title` `Felix needs you`
  and a body with no `@` and no `alerts test`; `issue list` carries `--state all`; each issue call
  carries `--repo github.com/fixture/lgh`; no call has `GH_HOST` or `GH_REPO` set, and the dispatch
  has `GH_PROMPT_DISABLED=1`. Its argv is exactly
  `workflow run felix-alert.yml --repo github.com/fixture/lgh -f issue=1 -f body=BODY`, and BODY is
  `@fixture Felix land: paused`, an empty line, `Landing is paused until felix land --resume.`,
  `details: felix land --status on the machine that runs the lander`. `alerts.tsv` has one row:
  `dispatched`, `paused`, `-`, `fixture/lgh#1`, field 6 the run URL the wrapper printed, field 7
  `through felix-alert.yml mentioning @fixture`, field 8 `held for the alerts test`.
- **A17 (B8).** Age the `paused` row past the hour (as 1280's G2 block does) and tick again: one
  more `paused` row and one more banner; no new wrapper call; still one `alerts.tsv` row.
- **A18 (B5, B1).** `--resume`, `--pause "r2"`, the ledger aged, `--tick`: no `issue create`; one
  `workflow run` naming `issue=1`; `alerts.tsv` has two `dispatched` rows.
- **A19 (B1, R2).** GitHub state with the fixture's `gh auth status` failing: a `--tick` writes one
  `gh` row, and BODY's line 1 is `@fixture Felix land: gh`, its line 3 R2's `gh` sentence.
- **A20 (B1, R2).** GitHub state, a tick over pull requests 41 and 42, both green as in 1280's G8
  block; 41's `ctl/merge.b41.rc` holds 1 and its `ctl/merge.b41.out` holds the line
  `  blocker one: the receipt is stale`. Fixture control: the ledger holds `refused` #41 and
  `landed` #42. One BODY's line 1 is `@fixture Felix land: refused #41`, line 3 R2's `refused`
  sentence, holding neither `blocker one` nor ` [main `; another's line 1 is
  `@fixture Felix land: landed #42`, line 3 R2's `landed` sentence.
- **A21 (B1).** GitHub state, a tick over one draft pull request #21: a `skip` row and no `api`,
  `issue` or `workflow` call.
- **A22 (B4, R8).** GitHub state, each case a `--pause` with a fresh reason then `--tick`, making no
  `workflow run` or `issue comment` call, no `issue create` but in the create case, and one `failed`
  row whose field 7 starts as shown: `full_name` answered `fixture/other` (`full_name:`); `push`
  `false` (`permission:`); owner type `Organization` with no `alert_login` (`owner:`); `alert_login`
  `bad login` (`alert_login:`, and the wrapper logs no call at all); `create` answering
  `https://github.com/fixture/other/issues/1` (`gh issue create:`, after exactly one `issue create`);
  `user` exiting 1 (`gh api user:` and `exited 1`, and no later call is logged).
- **A23 (R2).** With `alert_login` `someone-else` in `projects/lgh/project.json` (restored after),
  BODY's line 1 starts `@someone-else Felix land:`.
- **A24 (R2-R4).** Two events whose `dispatch` step exits 1 leave two `failed` rows (field 7
  starting `gh workflow run:`); a third, the step answering again, is `dispatched`, and its BODY's
  line 4 is `Not delivered before this one: 2 (the newest: K at T).`, K and T fields 3 and 1 of the
  second `failed` row, and line 5 the `details:` line.
- **A25 (R2, B7).** A paused reason of a token (`ghp_` and 36 letters and digits), then
  ` $HOME/x and a@b`: no gh call's argv holds the token, and no body (`issue create`'s or BODY)
  holds the token, `$HOME`'s value, `x and` or `a@b`; BODY has one `@`, on line 1; field 8 holds
  `~/x and a@b`.
- **A26 (B9).** The patched CLI, GitHub state, the `dispatch` step hanging: `--pause r9` then
  `--tick` exits 0 within 20 seconds; the pid the hung step wrote is not alive; one `failed` row,
  field 7 containing `timed out`.
- **A27 (B10).** The same paused scenario in F2 as built, in the GitHub state with `user` exiting 1,
  and in the GitHub state as A26: the same ledger fields 2-7, one banner, exit 0, in all three.
- **A28 (B11, R7).** GitHub state: `--install` from `$LGH` (no wrapper call is logged, B11), then
  the trampoline as `_la_tramp` runs it but with `FELIX_HOME_DIR` naming a directory that does not
  exist: exit 1, one `deploy-owed` row, one dispatch whose BODY's line 1 is
  `@fixture Felix land: deploy-owed` and line 3 R2's `deploy-owed` sentence, and a `dispatched` row.
- **A29 (B11, R7).** GitHub state, the trampoline with plugin.json unopenable as 1288 makes it, a
  logging git first on its `PATH`: one BODY's line 1 is `@fixture Felix land: unreadable`, line 3
  R2's `unreadable` sentence, and the git log is empty.
- **A30 (B11).** A file that writes a tripwire file when sourced is put at the home's
  `engine/harness/lib/notify.sh` (untracked) and at the cache entry's `harness/lib/notify.sh`, both
  removed after. The trampoline, run as `_la_tramp` runs it, writes the `deploy-owed` row naming the
  untracked file; a dispatch is made for it; the tripwire does not exist.
- **A31 (B11).** After A28, with no `_lg_reset` between: origin set back to `$LGO`; `--pause r31`
  and `--tick` (its attempt rewrites `alerts.repo`); then the trampoline with a missing
  `FELIX_HOME_DIR`: no wrapper call, and the newest record is `failed`.
- **A32 (B12).** GitHub state, a hand-run `--tick` from a directory that resolves no project,
  `FELIX_LAND_LEDGER` unset: no wrapper call, and no `alerts.tsv` exists under `$LGM` but the one
  `$LAND` held before.
- **A33 (B13, R5).** `felix status --tsv` from `$LGH` prints exactly six rows in the order
  `settings schedule pulse reach gate alerts`. The `alerts` row reads, in turn: with no
  `alerts.tsv`, `none` `-`; after A16, `value` `dispatched` with a detail containing field 6; after
  a `failed` row, `value` `failed` with a detail containing its field 7; with a hand-appended row of
  three fields, `unknown` `-`; then with a hand-appended eight-field `posted` row, `unknown` `-`;
  with `FELIX_HOME_DIR` naming a directory that resolves no project, `unknown` `-`. Each run leaves
  `_lgsnap` unchanged and logs no wrapper call; plain `felix status` aligns the row as 1100's S2.
- **A34 (B3, R1).** Across every run of part 1720, the wrapper's log holds no `issue` call but
  `list` and `create` (so no `issue comment`), no `pr` call from the notifier, no `label` call, no
  `workflow` call but `workflow run felix-alert.yml`, and no `api` call carrying `-X`, `--method`,
  `-f`, `-F`, `--field`, `--raw-field` or `--input`; and some dispatch was made.
- **A35 (B10, control).** In the GitHub state a paused tick still writes one seven-field `paused`
  row and one banner titled `Felix: paused` (G8).
- **A36-A39** are in section 9. The amended pin in 1100 (section 3, six rows) is also B13's.

## 5. Parts

`1710-lander-serves-the-home-only-blind.sh` (A1-A13, F1) and `1720-lander-alerts-reach-github-blind.sh`
(A14-A39, F2), written blind from this file, one tests/run line each after 1600's and before 9990's;
neither joins a group in tests/groups.tsv (1720 builds the shared fixture through `_lg_build`).

## 6. Out of scope

- **Alerts from other unattended paths** (overnight, the pulse, a late gate, discovery), and a
  session-start notice of the land state beyond R6's alert line (the second skeptic's, medium).
- **Jobs installed for another project before this fix**: none on this Mac (read 2026-10-24: only
  `felix.land.felix.plist` and `felix.pulse.plist`); B17 keeps `--uninstall` able to remove one.
- **A stranger's home cloned from LeavesJ/Felix**, pulling and installing upstream main unattended:
  G3 and G7, not C013. B4's permission check keeps its alerts off the founder's repository.
- **A Linux scheduler and notify-send**: decided Mac-only; `felix_schedule_state` answers `unknown`.
- **Re-sending an old alert by itself**: an event is retried when raised again (B8, R4), the next
  dispatch counts what was missed (R2), and `felix status` shows it.
- **Proof that a phone was alerted**: GitHub reports no push delivery; `dispatched` records a
  started run, not a delivery. **Hosts other than github.com**; two hand-run ticks in one second.

**Not fixed, not a defect.** C018 "no banner was ever shown": the usernoted log shows the 2026-10-23
`landed 460` and `deployed` banners delivered (second skeptic, steps 4-5). C018 "landing stays
stopped until he runs `--prs` or `--status`": the banner waits in Notification Center. C042 "every
green PR waits for a person": `felix automerge --enable` (felix:4386) works on any OS. C042, Full
Disk Access: land A31's remedy. C013, the stranger's unattended pull and install: G3 and G7.

## 7. Founder PR

None: no deny or escape row, commission grant or publishing, and no workflow. Three things are his.

1. **A reinstall, on his yes in chat.** Only `felix land --install` rewrites an installed trampoline
   (the land contract's "Installed jobs"), so its own alerts (B11, R7) start once he says yes to
   running it from the home after this deploys; until then they reach only the Mac.
2. **His decision of 2026-10-26** (in chat, on the review's posted-self major): the tick posted as
   his own login and mentioned him, and GitHub's docs say "You will not get notifications for your
   own actions". Of (a) accept it, (b) alerts from github-actions[bot], (c) a second account's token,
   he chose **(b)**, so his phone is notified: R1-R7 (section 9). Each alert costs about one Actions
   minute on the private home.
3. **Merging `.github/workflows/felix-alert.yml`, exactly this file.** Until it is on the default
   branch every dispatch records `no-alert-workflow` (R3), shown by `felix status` and the session
   start (R5, R6), and the alert waits in `alerts.tsv` (R4).

   ```yaml
   name: felix-alert
   on: { workflow_dispatch: { inputs: { issue: { required: true }, body: { required: true } } } }
   permissions: { issues: write }
   jobs:
     comment:
       runs-on: ubuntu-latest
       timeout-minutes: 2
       steps:
         - env:
             GH_TOKEN: ${{ github.token }}
             ISSUE: ${{ inputs.issue }}
             BODY: ${{ inputs.body }}
           run: |
             case "$ISSUE" in ''|*[!0123456789]*) echo "issue is not a number" >&2; exit 2 ;; esac
             printf '%s\n' "$BODY" | gh issue comment "$ISSUE" --repo "$GITHUB_REPOSITORY" --body-file -
   ```

## 8. Red

Before any code changed (5d0fff99), `alone.sh bwk 1710 1720`: 83 ok (62 the preamble's), 26 FAIL:
1710 A3-A7, A10, A11, A13 and 1720 A15-A20, A22-A26, A28-A34. Of the parts' 21 ok, A21 was already
true and A27 vacuous while no notifier ran; the rest are controls.

## 9. Review round (2026-10-26)

The review found A22 could never pass (M1), A33 read a value set inside `$( )` (M2), and the tick
posted as the founder's own login mentioning that login, so his phone most likely stayed silent
(M3, C018's scenario). The founder answered (F1, section 7). This section is required behaviour.

- **R1 (M3, F1). Alerts come from github-actions[bot].** Call 5 of B3 is exactly
  `gh workflow run felix-alert.yml --repo github.com/OWNER/REPO -f issue=N -f body=BODY`: these
  arguments in this order and no others, N the standing issue's number (B5), BODY as R2, with B3's
  environment and B9's bound. The notifier never runs `gh issue comment` and no `workflow` command
  but this one. Calls 1-4 and their B4 checks stay. Call 4, made only when no standing issue exists,
  is the one write made as the gh login, and its body holds no `@` and none of the event's detail.
  Nothing posts or mentions as that login, so `posted` and `posted-self` are gone.
- **R2 (F1). BODY** is these lines and nothing else (a final newline optional): 1,
  `@LOGIN Felix land: KIND`, then a space and `#PR` when the row names a pull request (LOGIN the
  mention login, checked by B4); 2, empty; 3, the sentence below for KIND; 4, only when R4 finds
  undelivered records, `Not delivered before this one: N (the newest: KIND at TIME).`; last,
  `details: felix land --status on the machine that runs the lander`. The event's detail never
  enters BODY or any gh argument, on a public, private or unknown-visibility repository alike; it
  stays in the ledger and in field 8. Only line 1 holds an `@`. Line 3 by kind, exactly:
  `landed`: `A green pull request was merged into main.`; `paused`: `Landing is paused until felix land --resume.`;
  `refused`: `felix merge refused a green pull request.`; `gh`: `gh auth status failed, so nothing lands.`;
  `founder`: `A green pull request changes a direction document and waits for your yes.`;
  `deployed`: `The engine on main was installed and verified.`; `stuck`: `A tick has held the lock for more than 45 minutes.`;
  `deployed-unverified`: `The engine on main was installed but not verified, and landing is paused.`;
  `timeout`: `A tick ran past its time limit and was stopped.`; `unresolved`: `The tick resolved no project, so nothing lands.`;
  `fetch`: `The home could not fetch its origin, so nothing lands.`;
  `deploy-owed`: `A deploy of main is owed and has not run, so nothing lands.`;
  `unreadable`: `The lander could not read the home, so nothing lands.`
- **R3 (F1). The record's state.** The dispatch exits 0: `dispatched`, field 6 the first
  `https://github.com/OWNER/REPO/actions/runs/N` in its output (else `-`), field 7
  `through felix-alert.yml mentioning @LOGIN`. It exits non-zero with
  `could not find any workflows named felix-alert.yml` on stderr (gh's words when the repository has
  no such workflow, as until section 7's file is merged): `no-alert-workflow`, field 7 starting
  `gh workflow run:` and naming `.github/workflows/felix-alert.yml`. Any other exit, or B9's
  timeout: `failed`, field 7 starting `gh workflow run:` in B4's wording. Never `posted`.
- **R4 (F1). Kept, and sent once it can.** No attempt removes or rewrites an earlier record. B8
  compares with the newest `dispatched` record only, so an event whose last attempt was
  `no-alert-workflow` or `failed` is attempted again whenever it is raised again (the hourly
  `paused` row, the trampoline's next `deploy-owed`). The first dispatch after such records carries
  R2's line 4: N counts the `no-alert-workflow` and `failed` records after the newest `dispatched`
  one (all of them when there is none), KIND and TIME the newest one's fields 3 and 1.
- **R5 (F1). `felix status`.** Newest record `dispatched`: `value`, `dispatched`, a detail with its
  time, kind, `#PR` when it has one, and field 6. Newest `no-alert-workflow`: `value`,
  `no-alert-workflow`, a detail with its time, kind and `#PR`, saying the alert was not sent and
  naming `.github/workflows/felix-alert.yml`. A field 2 that is not one of R3's three (an older
  `posted` too) is `unknown`, as a record that cannot be read. No detail says `posted-self`.
- **R6 (F1). The session-start line.** When the newest record of the home's project's `alerts.tsv` is
  `no-alert-workflow`, `hooks/session-start` run in a checkout of that project prints a line holding
  `no-alert-workflow` and `felix-alert.yml`, and leaves `alerts.tsv` as it was; when the newest is
  `dispatched`, nothing it prints holds `no-alert-workflow`.
- **R7.** The trampoline (B11) does R1-R4 for its own events, from its own code.
- **R8 (M1).** A22 said no case makes an `issue create`, but in its create case B4 makes call 4 and
  then judges its answer: one `issue create`, then nothing. B4 decides; A22 is restated. **R9 (M2).**
  A33's detail checks read a value set inside `$( )`; the part sets it in its own shell instead.

New assertions, part 1720, fixture F2:

- **A36 (R1, R5, M3).** The wrapper's login `fixture`, the owner's, no `alert_login` (poster and
  mention one account, as for the founder): the calls end in `workflow run`, none is `issue comment`;
  the record is `dispatched`, field 7 `through felix-alert.yml mentioning @fixture`; `felix status`
  reads `value` `dispatched`, its detail holding neither `posted-self` nor `own actions`.
- **A37 (R3, R5, B10).** With `workflow` present, a paused event makes one `workflow run`, records
  `no-alert-workflow` (field 7 starting `gh workflow run:`, holding `felix-alert.yml`), writes one
  `paused` row and one banner; `felix status` reads `value` `no-alert-workflow`, naming the file.
- **A38 (R6).** `hooks/session-start`, bounded at 30 s, stdin
  `{"session_id":"l20","source":"startup","cwd":C}`, run in C, a clone of the home with the GitHub
  origin, as the home, with a fresh `HOME` and a memory holding A37's `alerts.tsv`: it prints
  `no-alert-workflow` and `felix-alert.yml`, leaving the file as it was; with A39's, no
  `no-alert-workflow`. Fixture control: it ends by itself both times.
- **A39 (R4).** Then `workflow` removed, the ledger aged, `--tick` (the same event raised again): one
  `workflow run`; a second record, `dispatched`; the first unchanged; BODY's line 4
  `Not delivered before this one: 1 (the newest: paused at T).`, T the first record's field 1.
