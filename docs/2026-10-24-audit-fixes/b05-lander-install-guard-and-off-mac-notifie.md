# Audit fixes, batch b05: the lander's install guard and its off-Mac alerts

Three findings of the 2026-10-24 audit about land on green
(docs/2026-10-15-land-on-green-contract.md, "the land contract"): what the founder hears when the
lander needs him (C018), which project `felix land --install` serves (C013), and what install does
off macOS (C042). The founder decided C018's channel on 2026-10-24 (batch note, quoted under C018).
This file is the whole specification the blind assertions are written from. It says what must be
true, not how. Where it changes a land-contract clause it says which; the land contract itself is
not edited (it is already 512 lines). G1-G9 and "land A1" to "land A31" are the land contract's
clauses; a bare A-number is an assertion of this file.

## 1. Defects

**C018. The lander's only alert is a banner on this Mac.** Every notified ledger row sends one
`osascript display notification` (lib/green-tick.sh:50-57; the trampoline's `owed()`,
lib/green-install.sh:105-113), its result discarded, and nothing else. *Scenario:* the founder is
away for eight hours; at 01:00 the tick refuses a pull request, pauses on `deployed-unverified`, or
the trampoline writes `deploy-owed`. A banner goes to the Mac's Notification Center; nothing reaches
his phone; landing stays stopped until he is back at the Mac. *Severity: low*, as the second skeptic
corrected it (the first kept high): banners are delivered (section 6), and land A10 is met as
written. *Fixed now because the founder decided it:* "When Felix needs the founder (any notified
land row, a stopped or paused lander, a refusal), it mentions the repository owner (or a configured
GitHub login) in one standing issue on the governed repository, created once with a fixed title and
reused, so the alert reaches the GitHub app on his phone. One comment per new event, never a repeat
of an unchanged one; a failed post is itself recorded and shown on felix status. It must work for
any Felix user (GitHub is already required) and must never post outside the governed repository."

**C013. `felix land --install` serves a project the lander does not serve.** `_gt_install`
(lib/green-install.sh:155-188) installs `felix.land.<p>` for whatever project `$PWD` resolves to and
prints "land on green is installed for <p>", but the trampoline always enters `$FELIX_HOME_DIR`
(:114) and its tick resolves the home's project, `_GT_LAND` and `_GT_REPO`
(lib/green-tick.sh:466-470). *Scenario:* the founder, on his yes, runs `felix land --install` in
another governed checkout, `webapp`. A second job ticks felix-home every five minutes; webapp's
green pull requests never land; in webapp `felix land --status` says `installed yes`, `loaded yes`,
and `--prs` shows its PRs waiting for the lander; `felix land --pause` in webapp writes a `paused`
file nothing reads; `--uninstall` in the home leaves `felix.land.webapp` landing felix-home's PRs.
*Severity: high* (both skeptics). *Corrections:* the stranger arm is not reachable today (the public
snapshot, 0.49.232, predates `felix land`, 0.49.293); the unattended upstream pull and install are
G3 and G7, not this (section 6); the remote_match rewrite is snapshot.sh:249, not :250.

**C042. Off macOS, `felix land --install` writes macOS files before it fails.** On a machine with no
launchd, `_gt_install` writes `~/Library/Application Support/felix/land/<p>/tick` and
`~/Library/LaunchAgents/felix.land.<p>.plist`, then dies at `launchctl bootstrap`
(lib/green-install.sh:160-186), where `felix pulse --install` checks first (felix:6589-6593).
`felix help` lists `land --install` with no platform note (felix:467). *Scenario:* on a Linux
laptop, `felix land --install` leaves the two files behind and fails; `felix land --status` then
reads `installed yes`. *Severity: low* (skeptic): land on green is decided Mac-only (land contract
line 15, G9; direction.md row 24); what is left is the order of the check and the help text.

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
  `--json` or `--limit` (100 or more), and adds nothing that writes (`-X`, `--method`, `-f`, `-F`,
  `--field`, `--raw-field`, `--input`):
  1. `gh api --hostname github.com user`, read for `.login` (the posting account, POSTER);
  2. `gh api --hostname github.com repos/OWNER/REPO`, read for `.full_name`, `.owner.login`,
     `.owner.type`, and `.permissions.admin`, `.maintain`, `.push`;
  3. `gh issue list --repo github.com/OWNER/REPO --state all`, read for each issue's `number`,
     `title` and `author.login`;
  4. only when 3 finds no standing issue (B5):
     `gh issue create --repo github.com/OWNER/REPO --title "Felix needs you" --body-file -`;
  5. `gh issue comment N --repo github.com/OWNER/REPO --body-file -`.

  The notifier runs no other gh command (no `issue edit|close|reopen|lock|delete|transfer|pin`, no
  `pr`, `label`, `workflow` or writing `api`). Every call names exactly `github.com/OWNER/REPO`,
  `repos/OWNER/REPO` or `user`.
- **B4. Never outside the governed repository.** The attempt creates and comments nothing, and
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
  case (`gh issue create:`); call 5 exits non-zero, times out, or exits 0 printing a URL not on
  `https://github.com/OWNER/REPO/issues/N` (`gh issue comment:`). After the first failing call no
  later call runs. A gh call's note names its exit status (`exited N`) or
  `timed out after S seconds`. Call 5 exiting 0 and printing nothing is `posted` with URL `-`.
- **B5. The standing issue** is the lowest-numbered issue call 3 lists whose title is exactly the
  title and whose `author.login` is POSTER (without regard to case), open or closed. With none, call
  4 creates it; its body contains no `@`. Felix never edits, closes, reopens, labels or assigns it.
  Against a gh that lists the issue it created, `gh issue create` runs once over any number of
  attempts.
- **B6. The comment**, given on standard input. Line 1: `@LOGIN Felix land: KIND`, followed by a
  space and `#PR` when the row names a pull request (LOGIN is the mention login). Line 2: empty.
  Line 3: four spaces, then the event's detail with every `$HOME/` written `~/` (a code block, in
  which GitHub links no mention). Later lines may name the project and the time. When `failed`
  records follow the newest `posted` record (or there are `failed` records and no `posted` one),
  exactly one later line reads `Not delivered before this one: N (the newest: KIND at TIME).`, N
  counting those records, KIND and TIME the newest one's kind and time fields. No line but 1 and 3
  holds an `@`.
- **B7. The record.** Every attempt that runs (B8's skip runs none) appends exactly one row to
  `<land directory>/alerts.tsv`, eight tab-separated fields: the UTC time (`YYYY-MM-DDTHH:MM:SSZ`);
  `posted` or `failed`; the event's kind; the pull request number or `-`; the issue as
  `OWNER/REPO#N` or `-`; the comment URL or `-`; the note (`as @POSTER mentioning @LOGIN` for
  `posted`; B2's, B4's, B9's or B11's reason for `failed`); the event's detail as on line 3 of B6
  without the four spaces. A tab, CR or newline in any field becomes a space. A record that cannot
  be appended changes nothing else (B10).
- **B8. No repeats.** An event whose kind, pull request and detail (field 8) equal the newest
  `posted` record's runs no gh call and appends no record. A `failed` record does not count: the
  same event raised again (the next hourly `paused` row) is attempted again.
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
  the home or from the plugin cache: it carries its own code, written by `--install`. It reads the
  repository and `alert_login` (when set) from `<its ledger's directory>/alerts.repo` (its form is
  the implementation's, but it never holds the origin URL's text), which `felix land --install`
  writes and every attempt of a tick that resolved its project rewrites from the home's origin and
  `project.json` before its calls (an origin that is not a GitHub origin is recorded as none).
  Neither ever rewrites the installed trampoline or plist. With the file absent or naming none, the
  trampoline runs no gh call and appends one `failed` record whose note starts `record:` (or carries
  B2's reason for a recorded none). `felix land --install` runs no gh command.
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
  | not 8 fields, or field 2 neither `posted` nor `failed` | `unknown` | `-` | says the record cannot be read |
  | `posted`, POSTER is not LOGIN | `value` | `posted` | its time, kind, `#PR` when it has one, and field 6 |
  | `posted`, POSTER is LOGIN (without regard to case) | `value` | `posted-self` | as for `posted`, and says GitHub documents no notification for an account's own actions, so whether a phone was alerted is not known |
  | `failed` | `value` | `failed` | its time, kind, `#PR`, and field 7 |

  The first five rows, their order and their content are unchanged. Plain `felix status` prints it
  the way it prints the others.

### The lander serves the home's project only (C013)

- **B14.** `felix land --install`, `--pause [reason]`, `--resume`, `--tick` and `--status [--tsv]`,
  run from a checkout whose project resolves and is not the home's project, exit 1, print nothing on
  stdout, and print on stderr a refusal naming both projects and containing
  `land on green lands the home's own pull requests only`. They write nothing: no plist, no
  trampoline, no `launchctl` call, no `paused` file, ledger row or record in either project's land
  directory.
- **B15.** When the checkout's project resolves and the home's project does not, the same commands
  exit 1 with a refusal on stderr containing `resolves no project`, and write nothing, as B14.
- **B16.** From the home, and from any worktree of the home, every `felix land` command behaves as
  today.
- **B17.** `--uninstall`, `--prs` and `--queue` are refused from no project; `--uninstall` from
  another project still boots out and removes that project's job, so a job installed before this fix
  can be removed.

### Off macOS (C042)

- **B18.** `felix land --install` from the home when no `launchctl` is on `PATH` exits 1, prints a
  refusal containing `launchctl`, `macOS` and `nothing was written`, prints no cron line (one would
  bypass the trampoline's land A1 and land A31 checks), and writes nothing: no `$HOME/Library`, no
  land directory, no `alerts.repo`, no gh call. The check reads `PATH`, so CI's stub `launchctl`
  keeps every existing install case.
- **B19.** The `felix land` line of `felix help` says `macOS only` (edited in place; felix does not
  grow).

## 3. What must not change

- **Ledger rows**: kinds, seven columns, deduplication and order. Pinned by 1280 (G8 seven fields,
  G4 ascending order), 1283 (land A10, once each), 1282 (land A13's refused rows), 1288 and 1289
  (land A31's rows).
- **The banner**: one osascript notification per event, same title and detail, after its row; a
  failed or hung post sends none of its own. Pinned by 1280 (G8), 1281 (deployed,
  deployed-unverified), 1282 (land A1; land A4's timeout), 1283, 1284 (one notification each), 1288
  and 1289 (osascript counts on the trampoline's rows).
- **In a home whose origin is not a GitHub origin** (every existing land fixture: its origin is a
  local path), the tick and the trampoline make no gh call beyond today's. Pinned by 1280 ("G2: and
  does nothing else: it asks gh nothing"; "G6: the tick writes no label, comment, review or merge
  through gh") and 1285 (land A25, "asking gh nothing more"). G6's meaning narrows by the founder's
  decision: the tick still writes nothing to a pull request; its only gh writes are the standing
  issue's `issue create` and `issue comment`.
- **The tick's lock, watchdog and exit 0** in every case (G2; land A4, A5, A25, A28): 1280, 1282,
  1285.
- **The trampoline** reads nothing of the home before land A31's read, runs no git in the unreadable
  case (1288: "the unopenable file writes the unreadable row alone", `_lg_cnt git` 0), runs no felix
  but main's accepted entry, exits 1 on every owed case (1282's land A1, 1288), and no tool it runs
  names `plugin.json` or has it on standard input (1289's tool wrappers). A tick never rewrites an
  installed trampoline or plist (1289: a hand-written old install is left byte for byte).
- **Install from the home or a worktree** with a `launchctl` on `PATH`: the same plist and
  trampoline paths and the line `land on green is installed for <p>: <plist>` (1281 G9, 1282 G9
  review 1, 1289's land A31 reinstall). **`--uninstall`** from anywhere, unchanged (1281, 1282,
  1283, 1284, 1288, 1289).
- **`--status` from the home**: installed, loaded, paused, `last`, then each pull request's last
  row, writing nothing (1280 G9, 1288's land A31, 1360 "one last line", "one last row"). The alert
  state is not added to `felix land --status`.
- **`--prs` and `--queue`** from any directory, unchanged and read-only (1300, 1310, 1320, 1330,
  1340, 1350, 1360). **Land A22's unresolved row** (1283).
- **`felix status`'s first five rows**, read-only and offline, and its plain form as the TSV aligned
  (S2): 1100, 1110.
- **The one existing pin this batch changes**, in 1100: the assertion "and prints exactly five rows:
  settings, schedule, pulse, reach, gate" (line 409) becomes "and prints exactly six rows: settings,
  schedule, pulse, reach, gate, alerts", expecting `settings schedule pulse reach gate alerts `; its
  S4 guard (line 431, `= 5`) becomes `= 6`, with the two `bad` details "status did not answer six
  rows". The record step re-records the two renamed names. The reach spec's S1 and S2 ("five rows")
  are read as amended here; lib/status.sh's header comment says six.
- **Sizes.** lib/green-tick.sh stays under 500 lines (479 today; 1280 G1). lib/green-install.sh,
  lib/status.sh (1100) and the new lib/notify.sh stay under 500; felix gets no longer. tests/run
  gains two part lines (497 to 499; 1040's cap is 500, which other batches adding parts will meet).
- **The engine-wide lints over lib/*.sh**, which now read lib/notify.sh: 0370 (nothing appended
  after git's HEAD), 0960 (no `| grep -q` on a producer), 1000 (every `mktemp` under `$TMPDIR`),
  1030, 1497 (no gawk builtin names; `LC_ALL=C` on every awk, sed, sort, cut and tr), 1530 (diff
  flags); and land A18's and land A28's portability rules and bash 3.2.

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
`issue comment N` with `https://github.com/fixture/lgh/issues/N#issuecomment-<k>`. It applies `--jq`
with jq as the fixture's gh does. A control file per step (`user`, `repos`, `list`, `create`,
`comment`) makes that step exit a given status, or write its pid and `exec sleep 300`. Every other
call goes to the fixture's gh. **A patched CLI copy**, as in 1285, sets `_FN_SECS=2` on the line
after it sources lib/green-tick.sh.

Controls are marked **(control)**: they hold before the fix and after it.

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
  `land on green is uninstalled for other`; `launchctl bootout gui/<uid>/felix.land.other` is
  logged.
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

**Part 1720**

- **A14 (B2, control).** F2 as built: `--pause "r1"` then `--tick` writes one `paused` row, sends
  one banner titled `Felix: paused`, and the fixture's gh log is empty.
- **A15 (B2, B7).** That run appends one `alerts.tsv` row: eight fields; field 2 `failed`; field 3
  `paused`; field 7 starts with `origin:`. `alerts.tsv` does not contain the text of `$LGO`.
- **A16 (B3, B5, B6, B7).** GitHub state: `--pause "held for the alerts test"` then `--tick`. The
  wrapper logs exactly, in order: `api` naming `user`, `api` naming `repos/fixture/lgh`,
  `issue list`, `issue create`, `issue comment 1`. `issue create` carries `--title`
  `Felix needs you`; `issue list` carries `--state all`; each issue call carries
  `--repo github.com/fixture/lgh`; every call has `GH_HOST` and `GH_REPO` unset. The comment body's
  line 1 is `@fixture Felix land: paused`, line 2 empty, line 3 `    held for the alerts test`.
  `alerts.tsv` has one row: `posted`, `paused`, `-`, `fixture/lgh#1`, field 6 starting
  `https://github.com/fixture/lgh/issues/1#issuecomment-`, field 7
  `as @fixture-bot mentioning @fixture`.
- **A17 (B8).** Age the `paused` row past the hour (as 1280's G2 block does) and tick again: one
  more `paused` row and one more banner; no new wrapper call; still one `alerts.tsv` row.
- **A18 (B5, B1).** `--resume`, `--pause "r2"`, `--tick`: no `issue create`; one more
  `issue comment 1`; `alerts.tsv` has two `posted` rows.
- **A19 (B1).** GitHub state with the fixture's `gh auth status` failing: a `--tick` writes one `gh`
  row, and the comment's line 1 is `@fixture Felix land: gh`.
- **A20 (B1, B6).** GitHub state, a tick over pull requests 41 and 42, both green as in 1280's G8
  block; 41's `ctl/merge.b41.rc` holds 1 and its `ctl/merge.b41.out` holds the line
  `  blocker one: the receipt is stale`. Fixture control: the ledger holds `refused` #41 and
  `landed` #42. One comment's line 1 is `@fixture Felix land: refused #41`, its line 3 starting with
  four spaces, containing `blocker one`, not containing ` [main `; another's line 1 is
  `@fixture Felix land: landed #42`.
- **A21 (B1).** GitHub state, a tick over one draft pull request #21: a `skip` row and no `api` or
  `issue` call.
- **A22 (B4).** GitHub state, each case a `--pause` with a fresh reason then `--tick`, making no
  `issue create` or `issue comment` call and one `failed` row whose field 7 starts as shown:
  `full_name` answered `fixture/other` (`full_name:`); `push` `false` (`permission:`); owner type
  `Organization` with no `alert_login` (`owner:`); `alert_login` `bad login` (`alert_login:`, and
  the wrapper logs no call at all); `create` answering `https://github.com/fixture/other/issues/1`
  (`gh issue create:`); `user` exiting 1 (`gh api user:` and `exited 1`, and no later call is
  logged).
- **A23 (B6).** With `alert_login` `someone-else` in `projects/lgh/project.json` (restored after),
  the comment's line 1 starts `@someone-else Felix land:`.
- **A24 (B6, B7).** Two events whose `comment` step exits 1 leave two `failed` rows (field 7
  starting `gh issue comment:`); a third, the step answering again, is `posted`, and its body has
  the line `Not delivered before this one: 2 (the newest: K at T).` with K and T fields 3 and 1 of
  the second `failed` row.
- **A25 (B6).** A paused reason `$HOME/x and a@b` gives line 3 `    ~/x and a@b`, and no line of the
  body holds the value of `$HOME`.
- **A26 (B9).** The patched CLI, GitHub state, the `comment` step hanging: `--pause r9` then
  `--tick` exits 0 within 20 seconds; the pid the hung step wrote is not alive; one `failed` row,
  field 7 containing `timed out`.
- **A27 (B10).** The same paused scenario in F2 as built, in the GitHub state with `user` exiting 1,
  and in the GitHub state as A26: the same ledger fields 2-7, one banner, exit 0, in all three.
- **A28 (B11).** GitHub state: `--install` from `$LGH` (no wrapper call is logged, B11), then the
  trampoline as `_la_tramp` runs it but with `FELIX_HOME_DIR` naming a directory that does not
  exist: exit 1, one `deploy-owed` row, one comment whose line 1 is
  `@fixture Felix land: deploy-owed`, and a `posted` row.
- **A29 (B11).** GitHub state, the trampoline with plugin.json unopenable as 1288 makes it, a
  logging git first on its `PATH`: one comment's line 1 is `@fixture Felix land: unreadable`, and
  the git log is empty.
- **A30 (B11).** A file that writes a tripwire file when sourced is put at the home's
  `engine/harness/lib/notify.sh` (untracked) and at the cache entry's `harness/lib/notify.sh`, both
  removed after. The trampoline, run as `_la_tramp` runs it, writes the `deploy-owed` row naming the
  untracked file; a comment is posted for it; the tripwire does not exist.
- **A31 (B11).** After A28, with no `_lg_reset` between: origin set back to `$LGO`; `--pause r31`
  and `--tick` (its attempt rewrites `alerts.repo`); then the trampoline with a missing
  `FELIX_HOME_DIR`: no wrapper call, and the newest record is `failed`.
- **A32 (B12).** GitHub state, a hand-run `--tick` from a directory that resolves no project,
  `FELIX_LAND_LEDGER` unset: no wrapper call, and no `alerts.tsv` exists under `$LGM` but the one
  `$LAND` held before.
- **A33 (B13).** `felix status --tsv` from `$LGH` prints exactly six rows in the order
  `settings schedule pulse reach gate alerts`. The `alerts` row reads, in turn: with no
  `alerts.tsv`, `none` `-`; after A16, `value` `posted` with a detail containing field 6; with the
  wrapper's login `fixture` after a new post, `value` `posted-self` with a detail containing `own`;
  after a `failed` row, `value` `failed` with a detail containing its field 7; with a hand-appended
  row of three fields, `unknown` `-`; with `FELIX_HOME_DIR` naming a directory that resolves no
  project, `unknown` `-`. Each run leaves the `$LAND` snapshot (`_lgsnap`) unchanged and logs no
  wrapper call; plain `felix status` prints the `alerts` row aligned as 1100's S2 form.
- **A34 (B3).** Across every run of part 1720, the wrapper's log holds no `issue` call with `edit`,
  `close`, `reopen`, `lock`, `delete`, `transfer` or `pin`, no `pr` call from the notifier, no
  `label` or `workflow` call, and no `api` call carrying `-X`, `--method`, `-f`, `-F`, `--field`,
  `--raw-field` or `--input`.
- **A35 (B10, control).** In the GitHub state a paused tick still writes one seven-field `paused`
  row and one banner titled `Felix: paused` (G8).

The amended pin in 1100 (section 3, six rows) is also B13's.

## 5. Parts

- `1710-lander-serves-the-home-only-blind.sh`: A1-A13, fixture F1.
- `1720-lander-alerts-reach-github-blind.sh`: A14-A35, fixture F2.

Both are written blind from this file and get one line each in tests/run after 1600's and before
9990's. Neither joins a group in tests/groups.tsv: 1720 builds the shared fixture itself through
`_lg_build`, and 1710 builds its own.

## 6. Out of scope

- **Alerts from other unattended paths** (overnight, the pulse, a gate past its deadline,
  discovery): the auditor's sketch named them; the founder's decision names the lander's events.
- **A session-start notice of the land state**: the second skeptic's separate finding (medium), not
  C018.
- **Jobs installed for another project before this fix**: none exists on this Mac
  (`~/Library/LaunchAgents` holds only `felix.land.felix.plist` and `felix.pulse.plist`, read
  2026-10-24), and no stranger has one. B17 keeps `--uninstall` able to remove one.
- **A stranger's home cloned from LeavesJ/Felix**, pulling and installing upstream main unattended
  and listing its pull requests: G3 and G7 (both skeptics), not C013. B4's permission check keeps
  its alerts off the founder's repository; a lander that refuses a repository its gh account cannot
  write to is a follow-up finding.
- **A Linux scheduler and notify-send**: decided Mac-only scope; `felix_schedule_state` already
  answers `unknown` on Linux.
- **Retrying a failed post by itself**: an event is retried when it is raised again (B8), later
  comments count what was missed (B6), and `felix status` shows it.
- **Proof that a phone was alerted**: GitHub reports no push delivery, and osascript's status proves
  no display; section 7 carries the question.
- **Hosts other than github.com**, and two hand-run ticks posting one event twice in the same
  second: not covered.

### Not fixed: not a defect

- **C018, "no banner was ever shown".** False: the usernoted log shows the 2026-10-23 22:34:02Z
  `landed 460` and 22:39:48Z `deployed` banners delivered to the lock screen and Notification Center
  (second skeptic's reproduction, steps 4-5). The missing ncprefs entry proves nothing about
  delivery.
- **C018, "landing stays stopped until he runs `--prs` or `--status`".** The banner waits in
  Notification Center. What is true is that nothing reaches him away from the Mac, which B1-B13 fix.
- **C042, "every green PR waits for a person".** `felix automerge --enable` (felix:4386) is
  GitHub-side and works on any OS.
- **C042, Full Disk Access for /bin/bash.** Land A31's decided remedy; an unreadable home is
  reported (`unreadable` row, banner, `--status` last).
- **C013, the stranger's unattended upstream pull and install.** G3 and G7, designed (both
  skeptics).

## 7. Founder PR

None. The batch needs no `.github/workflows` change, deny or escape row, commission grant or
publishing; its PR is an engine change and lands like any other.

Two things are his, and neither is a PR of this batch.

1. **A reinstall, on his yes in chat.** The land contract's "Installed jobs" says an installed
   trampoline is rewritten only by `felix land --install`. The trampoline's own alerts (B11) start
   only after he says yes to running it from the home once this is deployed. Until then the tick's
   alerts (B1) work, and the trampoline's `deploy-owed` and `unreadable` rows still reach only the
   Mac.
2. **An outcome question: will his phone hear it?** The tick posts with his own gh login and
   mentions `@LeavesJ`. GitHub's notification documentation (Enterprise 2.0 edition) says "You will
   not get notifications for your own actions"; whether github.com's mobile push skips a
   self-mention today is not verified. If it does, the comments are written and his phone stays
   silent, and `felix status` shows `posted-self` each time. The options, by what happens: (a)
   accept it, and see alerts when he opens the issue, which still beats the Mac alone; (b) alerts
   come from github-actions[bot], which does notify him, at about one Actions minute each on the
   private home (roughly 100 a month at the ledger's present rate). This needs the founder-merged
   workflow below and a later engine change: call 5 becomes
   `gh workflow run felix-alert.yml --repo github.com/OWNER/REPO -f issue=N -f body=...`, and a
   started run is recorded `dispatched`, not `posted`; (c) Felix posts with a second GitHub
   account's token, a credential he would create.

   For (b), the exact file `.github/workflows/felix-alert.yml`:

   ```yaml
   name: felix-alert
   on: { workflow_dispatch: { inputs: { issue: { required: true }, body: { required: true } } } }
   permissions: { issues: write }
   jobs:
     comment:
       runs-on: ubuntu-latest
       timeout-minutes: 2
       steps:
         - env: { GH_TOKEN: "${{ github.token }}", ISSUE: "${{ inputs.issue }}", BODY: "${{ inputs.body }}" }
           run: |
             case "$ISSUE" in ''|*[!0123456789]*) echo "issue is not a number" >&2; exit 2 ;; esac
             printf '%s\n' "$BODY" | gh issue comment "$ISSUE" --repo "$GITHUB_REPOSITORY" --body-file -
   ```
