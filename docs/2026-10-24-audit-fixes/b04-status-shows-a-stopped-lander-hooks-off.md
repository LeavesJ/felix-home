# Audit b04: status shows a stopped lander, hooks off and ungoverned projects

The contract for audit fix batch b04 (C005, C014, C115). It is the whole
specification the blind parts are written from. It says what must be true, not
how. It was written against main at 69b51a61 (0.49.307), reading
`lib/status.sh`, `lib/green-tick.sh`, `lib/green-install.sh`,
`lib/pr-status.sh`, `lib/lifecycle.sh`, `lib/guard.sh`, `lib/detect.sh`,
`hooks/session-start`, `hooks/stop` and `felix` (`cmd_doctor`, `cmd_status`).

Words used below. **H** is a Felix home, **C** a checkout governed by project
**p** of H, **U** the HOME directory and **M** the memory root
(`FELIX_MEMORY`). **Ld** is p's land directory, `M/<p>/land`: `ledger.tsv`,
`paused` and `lock/` as today, and the new `heartbeat`. **Pl** is the job's
plist, `U/Library/LaunchAgents/felix.land.<p>.plist`; its label is
`felix.land.<p>`. A **row** is a line of `felix status --tsv`,
`<row> TAB <state> TAB <value> TAB <detail>`. `·` is U+00B7, the middle dot
the session line's ` · N due` badge already uses.

## 1. Defects

- **C005 (high).** A paused, unloaded, uninstalled or hung land-on-green job
  shows on no surface a person reads at the start of a session. `felix status`
  has no row for it, and no hook reads its state.
  *Scenario:* a session runs `felix maintenance --ran handoff`, which dirties
  the home's tracked `projects/felix/maintenance.log`. On the first tick that
  owes a deploy (the tick after any merge moves origin/main past the home),
  the job pauses with "the home checkout holds a tracked change".
  `felix status` and session start keep reading as before, and nothing lands
  until someone runs `felix land --status`. This happened from 01:52Z to
  06:01Z on 2026-10-23. A job that is unloaded, removed or hung writes no row
  at all. launchd never starts a second copy of a running job, so the 45-minute
  `stuck` row, which only a second tick writes, never appears either.
  *Skeptics' corrections, followed here:* a pause is not wholly silent, because
  the tick rewrites a `paused` row and sends a banner once an hour
  (green-tick.sh:408-414). "Off macOS" does not apply, because the job exists
  only under launchd. Under Focus, banners still collect in Notification
  Center. Severity stays high for the dead or hung job, which tells no one.
- **C014 (high).** Settings that switch Felix's hooks off go undetected. The
  settings check reads one key of the user file only, so `felix status` says
  `settings ok` while every hook is off.
  *Scenario:* `{"disableAllHooks": true}` is written to a governed checkout's
  gitignored `.claude/settings.local.json`, or to the user file beside
  `"enabledPlugins":{"felix@felix":true}`. Or a stranger's repository commits
  `.claude/settings.json` with `"enabledPlugins":{"felix@felix":false}`. No
  Felix hook fires, `felix status` prints `settings ok ... enables
  felix@felix`, and `felix doctor` says nothing about settings.
- **C115 (medium, corrected from the auditor's framing).** A project that
  declares no gate looks governed on the surfaces a person reads every day.
  Meanwhile the Stop hook checks no stop.
  *Scenario:* `felix new` on a Gradle repository prints `gate guess   none,
  set it yourself` once. From then on the session line reads `Felix: app`,
  `felix status` reads `gate none-run no gate has run in this checkout` as if
  a gate existed, `felix doctor` names no gate, and every stop passes
  unchecked. *Skeptic's correction:* the person is told once, at onboarding,
  and can find out later from `felix which`, `felix gate` and
  `felix commission --status`. So the defect is misleading daily surfaces, not
  "everywhere".

## 2. Required behaviour

### felix status: the rows

- **B1. Seven rows.** `felix status --tsv` exits 0 and prints exactly seven
  rows, in this order: `settings`, `schedule`, `pulse`, `reach`, `gate`,
  `land`, `hooks`. The new rows keep the existing shape on every path: four
  tab fields; a state of `value`, `none` or `unknown`; a value of `-` unless
  the state is `value`, and never with a space; a detail never empty.
  `felix status` without `--tsv` prints the same rows aligned, as today.

### The land row (C005)

The checks run in the order B2 to B9, and the first that applies decides the
row. N is the clause defined in B10.

- **B2. Not governed.** Run outside a governed checkout, the row is
  `land none - this directory is not a governed checkout`.
- **B3. No job, no record.** If Pl does not exist, and `Ld/ledger.tsv` is
  absent or a readable file with no non-empty line, the row is
  `land none - no land-on-green job for <p>; felix land --install schedules one`.
  It asks launchctl nothing.
- **B4. No launchd.** Otherwise, `uname` is asked (found through PATH, as the
  schedule row does). When it does not print `Darwin`, the row is
  `land unknown - no launchd on <what uname printed>`, or
  `... on this machine` when it printed nothing. launchctl is not asked.
- **B5. launchd's answer.** Otherwise the row asks
  `launchctl print gui/<uid>/felix.land.<p>`, launchctl found through PATH and
  `<uid>` from `id -u`. It asks with no other launchctl subcommand.
  - No launchctl on PATH: `land unknown - launchctl could not answer`.
  - Exit 113 (launchd's "could not find service") with Pl present:
    `land value not-loaded <Pl> exists and launchd has not loaded felix.land.<p>: nothing lands; N`.
  - Exit 113 with Pl absent:
    `land value not-installed no felix.land.<p> job is installed and launchd has none loaded, and N: nothing lands here until felix land --install`.
  - Any other non-zero exit E:
    `land unknown - launchctl print exited E, so whether felix.land.<p> is loaded is not known`.
  - Exit 0 means loaded, and B6 to B9 decide.
- **B6. Not ticking.** `Ld/heartbeat` holds a readable time (B12), and it is
  more than 2700 seconds before now. 2700 is the 30-minute watchdog plus three
  of the job's five-minute intervals. The row is
  `land value not-ticking launchd has felix.land.<p> loaded and no tick has started for <M> minutes, since <T>: a tick may be hung, or the job cannot start one; N`.
  M is the whole minutes, rounded down. T is the heartbeat's UTC minute,
  `YYYY-MM-DDTHH:MMZ`. This check comes before B7, so a job that is both
  paused and not ticking reads `not-ticking`.
- **B7. Paused.** `Ld/paused` exists. The row is
  `land value paused <R>: nothing lands while it is paused`. R is the file's
  first line, with tabs and CRs made spaces. It is `no reason could be read`
  when that line is empty or the file cannot be read. B7 applies whatever B8
  would say about the heartbeat.
- **B8. Liveness not known.**
  - `Ld/heartbeat` absent:
    `land unknown - launchd has felix.land.<p> loaded and it is not paused; no tick has recorded a heartbeat in Ld/heartbeat, so whether it still ticks is not known; N`.
  - Present but holding no readable time:
    `land unknown - Ld/heartbeat holds no time this check can read, so whether felix.land.<p> still ticks is not known; N`.
  - A time more than 300 seconds after now:
    `land unknown - Ld/heartbeat is dated <S> seconds after this clock, so whether felix.land.<p> still ticks is not known; N`.
- **B9. Running.** Otherwise the row is
  `land value running launchd has felix.land.<p> loaded, it is not paused, and its last tick started <M> min ago; N`.
- **B10. The newest-row clause N** is one of:
  - `the ledger has no row`, when `Ld/ledger.tsv` is absent or has no
    non-empty line;
  - `the ledger could not be read`, when it exists and cannot be read;
  - otherwise `the ledger's newest row is <f1> <f2>: <f7>`, from the file's
    last non-empty line, fields 1, 2 and 7 (tab-separated), with tabs and CRs
    made spaces.

  Every `Ld/...` and `<Pl>` in a detail is the full path.
- **B11. Read-only.** `felix status` stays read-only in every land and hooks
  state. It creates, changes or removes nothing under H, M (Ld included), C or
  `U/Library`. It runs no claude command. It calls launchctl only as `list` (the
  schedule row) and `print` (the land row).

### The heartbeat (C005)

- **B12. Written by every tick.** Every `felix land --tick` that resolves its
  project writes `Ld/heartbeat`, replacing what was there, before it does
  anything else of the tick. That means before the paused check, before it
  takes the lock, and before gh or git fetch. The file is exactly one line:
  the tick's start in whole seconds since the epoch, digits only, with a
  newline after them. A readable time is a first line of 1 to 12 characters,
  every one in `0123456789`.
  - A paused tick writes it, and so does a tick that finds the lock held by a
    live tick.
  - A heartbeat that cannot be written changes nothing else the tick does: it
    exits 0 and writes the rows it would have written.
  - `felix land --status`, `--pause`, `--resume`, `--install`,
    `--uninstall`, `--prs` and `--queue` write no heartbeat.
  - The trampoline is not changed, so a run it refuses (deploy owed,
    unreadable home) is a run with no tick and no heartbeat.

### Session start (C005, C115)

- **B13. The landing badge.** For a startup (or clear, or compact) payload in
  C, session start uses the answer `felix status`'s land row gives in the same
  directory and environment. When that row's value is `paused`, `not-loaded`
  or `not-ticking`:
  - the one-line `systemMessage` gains ` · landing <value>`;
  - the context (`hookSpecificOutput.additionalContext`) gains a line
    `Landing on green is <value>: <the row's detail>`.

  For every other answer (`none`, `running`, `not-installed`, any `unknown`)
  neither appears. Session start exits 0 and prints valid JSON in every land
  state, launchctl failing or absent included.
- **B14. The no-gate badge.** When `felix_json_str <proj>/project.json gate`
  reads empty, which is the same reading the Stop hook uses, the
  `systemMessage` gains ` · no gate, stops unchecked`. The context keeps its
  `Gate: none declared (set "gate" in <proj>/project.json)` line.
- **B15. Order and the rest.** The line is `Felix: <p>`, then
  ` · no gate, stops unchecked`, ` · <N> due`, ` · landing <value>` and
  ` · new tooling found`, each only when it applies, and stays one line. A
  resume payload still prints nothing. The broken-binding line is unchanged.

### Settings and hooks (C014)

- **B16. The user file.** `felix_settings_state` (the settings row, and the
  pulse's `settings` line) keeps its answers for missing, unreadable, no
  parser, does not parse, empty and not an object. When the file parses as an
  object:
  - `disableAllHooks` exactly `true` prints
    `hooks-off<TAB><f> sets disableAllHooks to true: Claude Code runs no hook, Felix's included, unless a project's own settings set it back to false`.
    This wins over `ok` and `felix-off`.
  - `disableAllHooks` present and neither `true` nor `false` prints
    `unknown<TAB><f> sets disableAllHooks to <its JSON>, which this check does not read`.
  - Absent or `false`: `ok` or `felix-off`, exactly as today.

  The settings row carries `hooks-off` as a value
  (`settings value hooks-off <detail>`), and `felix pulse` prints
  `settings<TAB>hooks-off<TAB><detail>`. `ok` is still printed only on a
  parser's exact `ok` with exit 0.
- **B17. The hooks row.** It reads the checkout's own files: R is the root
  `felix status` already computes for C, and the files are
  `R/.claude/settings.json` (project) and `R/.claude/settings.local.json`
  (local). For each key, the local file wins over the project file when it
  holds the key, which is Claude Code's documented precedence. The checks run
  in this order, and the first that applies decides the row.
  - Not governed: `hooks none - this directory is not a governed checkout`.
  - A present file that is not a regular readable file:
    `hooks unknown - <f> cannot be read, so whether it turns hooks off is not known`.
  - A present file but no parser (the `FELIX_JQ` knob, as the settings check
    uses): `hooks unknown - no JSON parser on this machine (jq); <the present files> not read, so whether they turn hooks off is not known`.
  - A present file that is empty, does not parse, or is not an object:
    `hooks unknown - <f> does not parse as a JSON object, so whether it turns hooks off is not known`.
  - Any of these makes the row unknown.
  - The winning `disableAllHooks` or `enabledPlugins["felix@felix"]` not a
    boolean: `hooks unknown - <f> sets <key> to <its JSON>, which this check does not read`.
  - The winning `disableAllHooks` true:
    `hooks value off <f> sets disableAllHooks to true: Claude Code runs no hook in a session here, Felix's included`.
  - Else the winning `enabledPlugins["felix@felix"]` false:
    `hooks value felix-off <f> sets enabledPlugins["felix@felix"] to false: Felix's hooks do not load in a session here`.
  - Otherwise `hooks value clear`. The detail is
    `no project or local settings file in R/.claude turns hooks off`, or
    `<the files read, joined by " and "> turn no hook off`. Either way it
    continues `; managed settings, a --settings file, --bare and an untrusted workspace are not read here`.
    With neither file present, no parser is needed.
- **B18. felix doctor.** In a governed checkout, `felix doctor` prints three
  lines straight after its `project:` line, in this order, each label padded
  to 14 columns as `project:` is:
  - `gate:` followed by the declared gate, or by
    `none declared: no stop is checked; set "gate" in <proj>/project.json`
    when B14's reading is empty;
  - `settings:` followed by `<word>: <detail>` from `felix_settings_state`;
  - `hooks:` followed by `<word>: <detail>` from the hooks row.

  `<word>` is the value when the state is `value`, and the state otherwise.
  Doctor still exits 0.

### The gate row (C115)

- **B19. No gate.** In a governed checkout, before any receipt is read:
  - `<proj>/project.json` absent: `gate value no-gate <proj>/project.json does not exist, so no gate is declared: the Stop hook checks no stop here`.
  - Present but not a regular readable file: `gate unknown - <proj>/project.json cannot be read, so whether a gate is declared is not known; the Stop hook reads no gate from it and checks no stop here`.
  - Readable, with an empty or absent `gate`: `gate value no-gate <p> declares no gate in <proj>/project.json: the Stop hook checks no stop here; set "gate" there`.
  - With a gate declared, the row is unchanged (`current`, `red`, `stale`,
    `none-run`, `unknown`).
- **B20. The Stop hook is unchanged.** With no gate it still exits 0 and
  prints nothing. No obligation is invented for a project mid-onboarding.

## 3. What must not change

| Behaviour | Pinned by |
|---|---|
| felix status: read-only (S4), no claude, usage exit 2 (S3), `--help`, aligned form (S2), D16 row shape; the five existing rows' answers (S5 settings, S6 schedule, S7 pulse, S8 reach, S9 gate, `none-run` for a gated project with no receipt included); the help line `felix status [--tsv]     read-only: settings, the pulse schedule and last run, declared tools' reach, this checkout's gate`, unchanged (S11); `lib/status.sh`, `lib/reach.sh`, `lib/pulse.sh` each under 500 lines | `1100-declared-tools-reach-the-pulse-and-felix-status.sh` |
| status leaves the index and checkout untouched with a green receipt | `1110-found-after-the-blind-part-status-index-and-long-list.sh` |
| the settings check's P1 answers (missing, no parser, empty, banana or okfail parser, unreadable, `ok`, `felix-off ... reads false`); the pulse's one settings line, after the backup lines and before the report lines (P2) | `1100-...` |
| felix land: usage, `--pause`, `--resume`; `--status` and `--status --tsv` as four lines (`installed`, `loaded`, `paused`, `last`) then a row per pull request, writing nothing; `lib/green-tick.sh` under 500 lines (G1) | `1280-land-on-green-blind.sh`, `1288-land-on-green-round-8-blind.sh` |
| `--install`, `--uninstall`, the trampoline's body and every refusal it makes; A31's read by the shell itself; a `--tick` leaving an installed pair byte for byte | `1281-land-on-green-deploy-blind.sh`, `1282-land-on-green-round-2-blind.sh`, `1283-land-on-green-round-3-blind.sh`, `1284-land-on-green-round-4-blind.sh`, `1289-land-on-green-round-9-blind.sh` |
| the tick's rows, deduplication, hourly paused row, lock, watchdog and deploy | `1280-land-on-green-blind.sh` and `1281`–`1288` (`1285-land-on-green-round-5-blind.sh`, `1286-...-round-6-...`, `1287-...-round-7-...` included) |
| the stuck-PR page's lander source row | `1300-stuck-pr-page-blind.sh`, `1310-stuck-pr-page-states-blind.sh`, `1320-stuck-pr-page-readings-blind.sh`, `1330-stuck-pr-page-review-blind.sh`, `1340-stuck-pr-page-amendments-blind.sh`, `1350-stuck-pr-page-terminal-and-risk-blind.sh`, `1360-stuck-pr-page-last-ledger-row-blind.sh` |
| Stop: no gate leaves the session alone; a broken binding blocks | `0220-the-binding-itself.sh`, `0204-hooks-stand-where-the-session-stands.sh` |
| session start: one line naming the project; the ` · N due` count; the `Felix: <p>` prefix; the normal context | `0250-on-path-via-a-symlink.sh`, `0120-scheduled-maintenance.sh`, `1130-unattended-work-runs-only-in-its-own-checkout.sh`, `0220-the-binding-itself.sh` |
| doctor: exits 0 despite drift; the `declared:` and `undeclared:` lines; byte-for-byte the same output whether `tr` works or fails, so the new lines must not depend on `tr`; unchanged under `GREP_OPTIONS=-n`; the quiet deny section | `0010-resolution.sh`, `0680-continued.sh`, `0681-continued.sh`, `1510-no-caller-environment-changes-a-tool-s-output.sh`, `0600-what-to-do-next.sh` |

**The one existing check that changes.** Part 1100 counts five rows in two
places, and B1 makes them seven. Exactly these change, each with a comment
above it, `# Changed by the b04 contract (docs/2026-10-24-audit-fixes/): two rows were added at the end, land and hooks, as the status header allows.`:

- The assertion `and prints exactly five rows: settings, schedule, pulse, reach, gate`
  becomes `and prints exactly seven rows: settings, schedule, pulse, reach, gate, land, hooks`.
  Its expected value becomes `settings schedule pulse reach gate land hooks `
  (a space after each).
- The S4 guard's `= 5` becomes `= 7`, and its two `status did not answer five rows`
  messages say `seven rows`.

The manifest change this makes (one name out, one in) is the record's, not
this batch's. `lib/status.sh`'s header names the seven rows, in order.

**Sizes.**
- `lib/status.sh` and `lib/green-tick.sh` stay under 500 lines.
- Files already over 500 lines end no longer than at 69b51a61:
  `hooks/session-start` 780, `hooks/stop` 610, `felix` 6734, and
  `lib/resolve.sh`, `lib/discover.sh`, `lib/where-read.sh`,
  `lib/commission.sh` as they are.
- Check with `wc -l`. Logic goes in the libs.

## 4. Assertions

**Fixture S** is the shape of every part 1690 assertion and most of 1700's.
- A `mktemp -d` under `$TMP`, holding H, U, M, C, P and a stub directory B.
  Git runs through the suite's fixture helpers (`_fx_git`, `_fx_cd`).
- `H/projects/lp/project.json` is
  `{"name":"lp","remote_match":"example.invalid/lp","gate":"true"}`, beside a
  `CLAUDE.md`.
- C is a git repository with one commit, holding only `.felix` (reading `lp`)
  and one text file. P is a git repository with no marker.
- `U/.claude/settings.json` is `{"enabledPlugins":{"felix@felix":true}}`.
- B is first on PATH and holds these stubs:
  - `uname`, which prints `$S_UNAME` or `Darwin`;
  - `launchctl`, which appends `$*` to a log and, for `print`, prints nothing
    and exits with the number in a control file (113 when there is none);
    for `list` it prints only `PID<TAB>Status<TAB>Label`;
  - `osascript`, which logs and exits 0;
  - `gh` and `claude`, which log and exit 1.
- Runs are made from C (or P) as
  `env -u COPILOT_CLI -u CURSOR_PLUGIN_ROOT -u CLAUDE_CONFIG_DIR HOME=U FELIX_HOME=H FELIX_HOME_DIR=H FELIX_MEMORY=M PATH=B:$PATH`,
  with `$FELIX status --tsv`, `$FELIX land ...`, `$FELIX doctor`, or
  `$FROOT/harness/hooks/session-start` fed
  `{"session_id":"b04","source":"startup","cwd":"<C>"}`.
- JSON is read with python3, as 0120 and 0250 do.
- "hb K" writes `Ld/heartbeat` as `$(( now - K ))`.
- "row1" is the ledger line
  `2026-10-23T06:16:28Z<TAB>paused<TAB>-<TAB>-<TAB>-<TAB>0<TAB>the home checkout holds a tracked change`.
- Pl is any file. A part that needs a real JSON parser skips those
  assertions, naming why, when `command -v jq` finds none, as 1100 does.

Controls hold before and after the fix. Every other assertion fails on main
today.

### Part 1690: the lander

| A | B | Fixture | Expected |
|---|---|---|---|
| A1 | B1 | S, no Pl, no Ld | exit 0; first fields `settings schedule pulse reach gate land hooks ` |
| A2 | B1 | each status output this part takes | no row breaks D16's shape (1100's awk) |
| A3 | B2 | run from P | `land	none	-	this directory is not a governed checkout` |
| A4 | B3 | no Pl, no Ld | `land	none	-	no land-on-green job for lp; felix land --install schedules one`; launchctl log has no `print` line |
| A5 | B4 | Pl, `S_UNAME=Linux` | `land	unknown	-	no launchd on Linux`; no `print` line |
| A6 | B5 | Pl, print exits 113 | `land	value	not-loaded	<Pl> exists and launchd has not loaded felix.land.lp: nothing lands; the ledger has no row` |
| A7 | B5 | same | the launchctl log holds a line matching `^print gui/[0123456789]+/felix\.land\.lp$` |
| A8 | B5, B10 | no Pl, ledger = row1, print 113 | `land	value	not-installed	no felix.land.lp job is installed and launchd has none loaded, and the ledger's newest row is 2026-10-23T06:16:28Z paused: the home checkout holds a tracked change: nothing lands here until felix land --install` |
| A9 | B5 | Pl, print exits 5 | `land	unknown	-	launchctl print exited 5, so whether felix.land.lp is loaded is not known` |
| A10 | B5 | Pl, PATH = a B without launchctl, then `/usr/bin:/bin`; skip when either holds a launchctl | `land	unknown	-	launchctl could not answer` |
| A11 | B6 | Pl, print 0, hb 3600, ledger = row1 | value `not-ticking`; detail matches `no tick has started for 6[01] minutes, since ` and ends `; the ledger's newest row is 2026-10-23T06:16:28Z paused: the home checkout holds a tracked change` |
| A12 | B6 | A11 plus `Ld/paused` | value `not-ticking` |
| A13 | B7 | Pl, print 0, hb 600, `Ld/paused` = `the home checkout holds a tracked change` | `land	value	paused	the home checkout holds a tracked change: nothing lands while it is paused` |
| A14 | B7 | A13 with no heartbeat | the same row |
| A15 | B7 | A13 with `Ld/paused` empty | detail `no reason could be read: nothing lands while it is paused` |
| A16 | B8 | Pl, print 0, no heartbeat, no paused | state `unknown`; detail holds `no tick has recorded a heartbeat in <Ld>/heartbeat` |
| A17 | B8 | heartbeat reads `soon` | state `unknown`; detail holds `holds no time this check can read` |
| A18 | B8 | hb -3600 (an hour ahead) | state `unknown`; detail holds `seconds after this clock` |
| A19 | B9, B10 | Pl, print 0, hb 120, ledger = row1 | value `running`; detail starts `launchd has felix.land.lp loaded, it is not paused, and its last tick started ` and ends with A11's clause |
| A20 | B9, B10 | A19 with no ledger | detail ends `; the ledger has no row` |
| A21 | B6, B9 | hb 2000, no paused | value `running`, not `not-ticking` |
| A22 | B11 | marker file touched before A4–A21's runs | **control:** `find H M C U/Library -newer marker` is empty; every launchctl log line starts `list` or `print` |
| A23 | B12 | `Ld/paused` present, `felix land --tick` from C, t0 and t1 read around it | exit 0; `Ld/heartbeat` is one line of digits, between t0 and t1 |
| A24 | B12 | same | **control:** the ledger gained one `paused` row and osascript was called once |
| A25 | B12 | no paused; `Ld/lock/pid` names a live `sleep` and there is no `started`; a tick | heartbeat between t0 and t1 |
| A26 | B12 | same | **control:** the ledger gained no row and gh was not called |
| A27 | B12 | `Ld/heartbeat` a directory, `Ld/paused` present, a tick | **control:** exit 0, and one `paused` row gained |
| A28 | B12 | no heartbeat; `land --status --tsv`, `--pause x`, `--resume` in turn | **control:** `Ld/heartbeat` absent after each |
| A29 | B12, B9 | Pl, print 0; a paused tick (A23), then `Ld/paused` removed | the land row's value is `running` |
| A30 | B13, B15 | no Pl, no Ld; session start | **control:** exit 0; `systemMessage` is `Felix: lp`; the context holds no `Landing on green is` |
| A31 | B13, B15 | A13's state; session start | `systemMessage` is A30's line followed by ` · landing paused`, one line |
| A32 | B13 | same | the context holds the line `Landing on green is paused: ` followed by the land row's detail as `felix status --tsv` prints it in that state |
| A33 | B13 | A6's state | `systemMessage` ends ` · landing not-loaded` |
| A34 | B13 | A11's state | `systemMessage` ends ` · landing not-ticking` |
| A35 | B13 | A19's state, then A8's, then A16's, then A5's | **control:** each `systemMessage` is A30's line, and no context holds `Landing on green is` |
| A36 | B13 | A9's state (print exits 5) | **control:** exit 0, the output parses as JSON |
| A37 | B15 | A13's state, payload `source` `resume` | **control:** prints nothing, exit 0 |

### Part 1700: hooks and gates

The fixture is S. Its own differences:
- Project `ng`'s `project.json` has no `gate` key.
- Project `ne`'s has `"gate": ""`.
- Project `nj` has no `project.json`.
- Project `dj`'s `project.json` is a directory.
- Each project has a checkout bound by `.felix`. CL is C, project lp's.
- U2 is a second HOME whose settings file each case writes.
- `.claude/settings*.json` files are written into CL per case and removed
  after.

| A | B | Fixture | Expected |
|---|---|---|---|
| A38 | B16 | U2 file `{"enabledPlugins":{"felix@felix":true},"disableAllHooks":true}` | the settings row is `settings	value	hooks-off	<f> sets disableAllHooks to true: Claude Code runs no hook, Felix's included, unless a project's own settings set it back to false` |
| A39 | B16 | the same, `felix pulse` from P | its output holds `settings	hooks-off	<the same detail>` |
| A40 | B16 | `felix@felix` false, `disableAllHooks` true | value `hooks-off` |
| A41 | B16 | `felix@felix` true, `disableAllHooks` false | **control:** `settings	value	ok	<f> enables felix@felix` |
| A42 | B16 | `"disableAllHooks":"yes"` | `settings	unknown	-	<f> sets disableAllHooks to "yes", which this check does not read` |
| A43 | B16 | A38's file, `FELIX_JQ=/nonexistent` | **control:** `settings	unknown	-	no JSON parser on this machine (jq); <f> was not read` |
| A44 | B17 | from P | `hooks	none	-	this directory is not a governed checkout` |
| A45 | B17 | CL with no `.claude` | value `clear`; detail holds `no project or local settings file` and `managed settings, a --settings file, --bare and an untrusted workspace are not read here` |
| A46 | B17 | local `{"disableAllHooks":true}` | `hooks	value	off	<CL>/.claude/settings.local.json sets disableAllHooks to true: Claude Code runs no hook in a session here, Felix's included` |
| A47 | B17 | project `{"disableAllHooks":true}` | value `off`; detail starts `<CL>/.claude/settings.json sets disableAllHooks` |
| A48 | B17 | project true, local `{"disableAllHooks":false}` | value `clear` |
| A49 | B17 | project `{"enabledPlugins":{"felix@felix":false}}` | `hooks	value	felix-off	<CL>/.claude/settings.json sets enabledPlugins["felix@felix"] to false: Felix's hooks do not load in a session here` |
| A50 | B17 | A49 plus local `{"enabledPlugins":{"felix@felix":true}}` | value `clear` |
| A51 | B17 | A49 plus local `{"disableAllHooks":true}` | value `off` |
| A52 | B17 | local `{not json`; then project `[]`; then project empty | each `hooks	unknown	-	<f> does not parse as a JSON object, so whether it turns hooks off is not known` |
| A53 | B17 | project `{"disableAllHooks":"true"}` | `hooks	unknown	-	<f> sets disableAllHooks to "true", which this check does not read` |
| A54 | B17 | A46's file, `FELIX_JQ=/nonexistent` | state `unknown`; detail starts `no JSON parser on this machine (jq)` |
| A55 | B17 | no `.claude` files, `FELIX_JQ=/nonexistent` | value `clear` |
| A56 | B17 | `settings.json` a directory | `hooks	unknown	-	<f> cannot be read, so whether it turns hooks off is not known` |
| A57 | B11, B17 | a marker before A45–A56's runs | **control:** nothing under CL, H or M is newer than it |
| A58 | B18 | A46's state, `felix doctor` from CL | exit 0; the lines after `project:      lp` are `gate:         true`, `settings:     ok: <U>/.claude/settings.json enables felix@felix`, then one starting `hooks:        off: <CL>/.claude/settings.local.json sets disableAllHooks to true` |
| A59 | B18 | `felix doctor` from ng's checkout | a line `gate:         none declared: no stop is checked; set "gate" in <H>/projects/ng/project.json` |
| A60 | B19 | status from ng's checkout | `gate	value	no-gate	ng declares no gate in <H>/projects/ng/project.json: the Stop hook checks no stop here; set "gate" there` |
| A61 | B19 | from ne's | value `no-gate` |
| A62 | B19 | from nj's | `gate	value	no-gate	<H>/projects/nj/project.json does not exist, so no gate is declared: the Stop hook checks no stop here` |
| A63 | B19 | from dj's | `gate	unknown	-	<H>/projects/dj/project.json cannot be read, so whether a gate is declared is not known; the Stop hook reads no gate from it and checks no stop here` |
| A64 | B19 | from CL, no receipt | **control:** `gate	value	none-run	no gate has run in this checkout` |
| A65 | B14 | session start in ng's checkout | `systemMessage` starts `Felix: ng · no gate, stops unchecked` |
| A66 | B14 | same | **control:** the context holds `Gate: none declared (set "gate" in <H>/projects/ng/project.json)` |
| A67 | B14 | session start in CL | **control:** `systemMessage` holds no `no gate` |
| A68 | B15 | ng's checkout, with a plist for `felix.land.ng`, print 0, hb 60 and `M/ng/land/paused` | `systemMessage` starts `Felix: ng · no gate, stops unchecked` and holds ` · landing paused` after it |
| A69 | B20 | ng's checkout with a tracked file edited; the Stop hook fed `{"hook_event_name":"Stop","stop_hook_active":false}` | **control:** prints nothing, exit 0 |

## 5. Parts

- `engine/harness/tests/parts/1690-status-lander-row-blind.sh`: A1–A37.
- `engine/harness/tests/parts/1700-hooks-and-gate-rows-blind.sh`: A38–A69.

Both are written from this file alone, before the fix, and are red first.
Each builds its own fixture under `$TMP` and stands alone: the driver lists
each one line after part 1600 and before 9990, and each runs under alone.sh by
itself. Each passes under bwk with bash 3.2 and under gawk with bash 5, and
leaves no process running (A25's `sleep` is ended by its pid). Assertions are
named by sentence with the A number first, as the house's blind parts are.
Timing is never closer than the bounds given: heartbeat ages of 60, 120, 600,
2000 and 3600 seconds, and a minute's slack on the regexes.

## 6. Out of scope

- **What pauses the job: `felix maintenance --ran` writing the tracked
  `maintenance.log`.** It is real. The skeptics confirmed it: maintenance.sh:55-57,
  `git ls-files` in the home, and felix:4743. It is one cause of many. The
  10-23 pause came from a commission re-stamp of the same class, and any
  tracked change pauses a deploy (green-tick.sh:238-241). This batch makes
  every pause visible. Moving the log changes what `felix maintenance` reads its
  due dates from (maintenance.sh's reader takes each line's name and epoch). So
  it is a change of its own, with its own contract.
- **Whether a deduplicated `gh`, `fetch`, `unresolved` or trampoline
  `deploy-owed` row still holds.** A recovery writes no row (only `unreadable`
  has its `readable` row), so the newest row cannot say whether its condition
  is current. The land row shows it as N, and its value comes only from
  current signals: plist, launchd, `paused` and heartbeat. Making those rows
  current needs the tick to record its last outcome, which is a change to
  green-tick.sh's every exit.
- **A trampoline that refuses every run** (main's engine not installed, an
  unreadable home) reads `not-ticking` after 45 minutes, not at once. The
  trampoline is unchanged. A31 says an installed trampoline changes only when
  `felix land --install` is run again, on the founder's yes.
- **The uninstalled job at session start.** `not-installed` shows in
  `felix status` and not on the session line. An uninstall is how a person
  turns landing off, and a line at every session after it would be a report
  nobody asked for.
- **The dash band.** The mod is outside this repository. It renders named
  cells and judges settings itself. Showing a `land` or `hooks` cell is a
  change to it.
- **The closing notice.** It is roadmap step 7 (direction.md:218), and so is
  the readiness status.
- **The pulse.** It does not report the lander, and it does not read checkout
  settings files. The pulse runs with no checkout.
- **Sessions Felix never saw.** That is reconciling transcripts against
  `lifecycle.log`, and counting Felix hook records with an exit code other than
  0 or 2 (guard.sh reads only `hook_blocking_error`). It needs a transcript
  reader and a way to tell SDK and subagent sessions, where SessionStart does
  not fire by design, from ungoverned ones. The auditor's 381-of-548 count was
  not checked by either skeptic.
- **What Felix cannot read.** Managed settings, a `--settings` file, `--bare`,
  safe mode and an untrusted workspace. The hooks row's detail says so. Also a
  session started in a subdirectory, whose project settings Claude Code may
  look for elsewhere than the checkout root.
- **More gate guesses** (Gradle, Maven, Bundler, Composer, .NET, Swift,
  python3). A guess is a decision about what proves a stranger's project
  correct. The defect is that no gate looked governed, and B14, B18 and B19
  fix that for every language at once. Noticed while reading, not fixed: a
  Makefile with only a `verify:` target is guessed as `make check`
  (detect.sh:276-277).
- **A session started in the first moments after the Mac wakes** may read
  `not-ticking` once, before launchd's missed interval has run.

### Not fixed: not a defect

- **C005, "a no-op off macOS or under Focus".** Off macOS there is no launchd
  job to stall (green-install.sh installs only a LaunchAgent). Under Focus,
  banners are held in Notification Center, not dropped.
- **C005, "a pause is silent".** It is not. `_gt_tick` rewrites a `paused` row
  and sends a banner at most once an hour while `paused` exists
  (green-tick.sh:408-414). The defect is the job that does not run, and a
  pause no session-start surface shows.
- **C014, "lifecycle.log: nothing reads it".** That is the design.
  lifecycle.sh:11-13 says the evaluations are derived later, from this file
  and the transcripts.
- **C115, "everywhere a person looks".** Several places do say it:
  - `felix new` prints `gate guess   none, set it yourself` (felix:1334);
  - commissioning holds `gate_declared` (templates/commissioning.tsv:81);
  - `felix which` prints an empty `gate:` (felix:736);
  - `felix gate` dies with "declares no gate" (felix:743);
  - session start's context says `Gate: none declared`.

## 7. Founder PR

None. The batch changes no `.github/workflows` file, no deny or escape row,
no commission grant and nothing published.
- **No reinstall.** The heartbeat is written by the engine's tick. It reaches
  the installed job when main's engine is deployed, which land on green does
  itself, so no `felix land --install` is needed.
- **No deny row.** The brief leaves a deny row against `disableAllHooks` to the
  founder, and this batch does not need one. A Write or Edit row matches the
  path, not the content, so it would refuse every edit to a project's
  `.claude/settings*.json`. What sessions may configure there is his decision,
  so no row is proposed here.

## 8. Red

Run on 2026-10-24 at c11e9235 (main 69b51a61 and the two blind parts, no code
changed), both parts in one run under bwk (macOS awk, bash 3.2) by alone.sh from
a fresh temporary directory. 69 assertions, A1 to A69.

| Part | Assertions | Failed | Passed | Skipped |
|---|---|---|---|---|
| 1690 | 37 | 27 | 9 | 1 (A10) |
| 1700 | 32 | 25 | 7 | 0 |
| Total | 69 | 52 | 16 | 1 |

Every failure is the missing behaviour. The status prints five rows, so the
`land` and `hooks` rows are absent (an empty row where a row is expected, and
`gate none-run` where `no-gate` is expected); the settings row answers `ok` or
`felix-off` where `hooks-off` or `unknown` is expected; no tick writes
`heartbeat`; doctor prints no `gate:`, `settings:` or `hooks:` line; session
start prints `Felix: <p>` and no badge. No failure comes from the fixture.

The 16 that passed are the contract's controls. No assertion that carries a
new behaviour passed.

**Already true, and a guard after the fix (11):**
- A24, A26: a paused tick writes one `paused` row and one notification; a tick
  that finds a live lock writes no row and asks gh nothing.
- A30, A35, A37: session start with no job reads `Felix: lp` with no landing
  line; the states that must show no badge show none (nothing shows a badge
  yet); a resume payload prints nothing.
- A41, A43: `disableAllHooks` false still reads `ok`; no parser still reads
  `unknown`.
- A64, A66, A67, A69: a gated project with no receipt reads `none-run`; the
  context keeps `Gate: none declared`; a gated project's line holds no
  `no gate`; the Stop hook with no gate prints nothing and exits 0.

**Vacuous before the fix (5):** each holds because the code it guards is not
there yet, and tests the fix once it is.
- A22: the read-only half holds, but status asks launchctl no `print` yet.
- A27: no tick tries to write a heartbeat, so a directory standing there
  changes nothing.
- A28: no command writes a heartbeat, so none writes one after `--status`,
  `--pause` or `--resume`.
- A36: session start asks launchctl nothing, so `print` exiting 5 cannot
  disturb it.
- A57: status reads no checkout settings file, so it changes none.

**Skipped (1):** A10 skips on this machine, as the part says it must: macOS
keeps `launchctl` in `/usr/bin`, so no PATH of the stubs, `/usr/bin` and `/bin`
goes without one. The behaviour (B5, no launchctl on PATH) is checked by hand
in the fix step.
