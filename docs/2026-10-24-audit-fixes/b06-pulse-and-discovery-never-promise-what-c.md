# Audit fix b06: pulse and discovery never promise what cannot happen

The whole specification for batch b06; the blind assertions are written from it alone. It says what
must be true, not how. Against `origin/main` 69b51a61 (0.49.307). Seven defects, each confirmed by two
skeptics, with their corrections used; claims that do not hold are in section 6.

Words used below. PROJ is `HOME/projects/NAME` in a Felix home HOME. The **record** is
`HOME/state/pulse.status.tsv`, rewritten whole by every pulse run: `# ran <epoch>`, then the lines the
run printed. The **refresh record** is `HOME/state/discover/NAME.refresh`, new here (B1). UTC is a
time printed `YYYY-MM-DDTHH:MMZ`, as `felix status` prints it. K1 to K6 are credential shapes that
`bin/secret-scan -` flags, assembled at run time (A0): K1 an `sk-ant-` key, K2 an `AKIA` key id, K3 a
`ghp_` token, K4 `Bearer` and 24 characters, K5 `https://user:<14 characters>@example.invalid`, K6
`password = "<14 characters>"`.

## 1. Defects

- **C016** (medium; one skeptic argued high). With TMPDIR unset or under `/tmp` (Linux's default) the
  background discovery refresh runs nothing, nothing records or says so, and the pulse says the next
  session refreshes it. *Scenario:* on stock Ubuntu commissioning fills the cache once; every later
  session's refresh gets 125 from `felix_neutral_run`; after 7 days "Worth a look" goes quiet with no
  line saying why, while a cron pulse prints `discovery cache; the next session refreshes it in the background`.
- **C043** (low, as corrected). Nothing breaks a left-behind lock `HOME/state/discover/.lock`; only the
  subshell's EXIT trap removes it. *Scenario:* a refresh is SIGKILLed or power is lost (TERM and HUP run
  the trap); every later session start returns at `mkdir`, for every project in the home, while the
  pulse promises a refresh. `lib/graph.sh`'s lock has the same shape.
- **C055** (high, as corrected). The cache stamp hashes the engine version, so every release makes
  every cache absent and discovery re-clones far more often than the README's "once a week".
  *Scenario:* since 2026-09-24, 71 commits touched `plugin.json` and 9 touched what writes the rows; each
  deploy's first session re-fetches up to 8 candidates, "Worth a look" is silent, and the commission
  discover row reads unknown, which on 2026-10-23 stopped unattended landing after a deploy.
- **C093** (medium). One nested git repository in memory stops the whole backup, and the refusal
  reaches no surface a person reads for 3 days. *Scenario:* an audit builds a fixture repository under
  memory; every pulse commits nothing, the refusal sits in the record and `pulse.log` only, and session
  start speaks at age 3 with no reason. It happened 10-02 to 10-12 and on 10-18.
- **C094** (low, as corrected). A verified push to a path on this disk stamps the backup current, and
  nothing says the copy is still on this disk. *Scenario:* the remote is a bare repository under
  `~/Library/Mobile Documents`; iCloud stalls, the pulse says `pushed and verified`, status shows 0
  days, and one disk failure loses memory and backup together.
- **C036** (medium; one skeptic argued high). A cloud session's records die with the VM, and the
  "memory exists in one place" warning cannot fire there. *Scenario:* a cloud gate fails, a lesson is
  written, the session ends, and lesson, catch and ledger vanish; the session saw only
  `Memory: /root/.felix/memory/felix/`. The loss is the founder's open item
  (`docs/handoff/0dh.md:108-112`); the silence is the defect.
- **C080** (medium). `says.log` and `routes.log` keep prompts and refused commands verbatim, and the
  pulse pushes memory with no credential scan. *Scenario:* a token in a prompt, or in a refused
  `curl -H 'Authorization: Bearer …'`, reaches the logs and the next pulse pushes it to the memory
  remote, where history keeps it. The founder's remote holds 4 such lines (fixtures' fake keys). In code Felix
  treats the same shape as a `disclose` escape.

## 2. Required behaviour

### D. Discovery

**B1. The refresh record.** Once a call `felix_discover_refresh_bg PROJ HOME FELIX` that took the lock
has finished (the lock is gone), the refresh record holds exactly one line `EPOCH<TAB>OUTCOME<TAB>DETAIL`:
EPOCH decimal seconds within the call's window (±2 s); OUTCOME `ran`, `failed` or `not-run`; DETAIL not
empty, with no tab or newline. Each later attempt that takes the lock replaces the whole file. No file
whose name contains `.new.` remains in `state/discover`. The call is otherwise unchanged: it returns 0 at
once, prints nothing, and its child closes inherited descriptors.

**B2. Not run.** In each case below FELIX never starts (its log gains no line), no `claude` starts, no
cache is written and no lock is left, as part 1130's B16 holds today. OUTCOME is `not-run`, and DETAIL
contains:

| TMPDIR | DETAIL contains |
|:---|:---|
| unset, empty or relative | `TMPDIR is not an absolute path` |
| a directory of mode 0777 | `TMPDIR is not a private directory` |
| a private directory under one holding `.mcp.json` | `.mcp.json` |
| a path that does not exist | `could not make an empty directory` |

**B3. Ran.** TMPDIR private; FELIX prints the current stamp line (exactly what
`_felix_discover_stamp_line` prints), then rows, and exits 0. The cache `HOME/state/discover/NAME.tsv`
is FELIX's stdout byte for byte, as today, and OUTCOME is `ran`.

**B4. Failed: FELIX's exit.** TMPDIR private; FELIX starts and exits non-zero. The previous cache is
byte-identical, as today; OUTCOME `failed`; DETAIL contains `exited 1` (or `exited 125`, and so on). A
started FELIX that exits 125 is `failed`, never `not-run`: `not-run` means never started.

**B5. Failed: a cache no reader takes.** TMPDIR private; FELIX exits 0 but its first line is not the
current stamp line (for example `# stamp stub`). The cache is still its stdout (part 1130's B15);
OUTCOME `failed`; DETAIL contains `stamp`. `ran` is recorded only when the written cache is current by
`felix_discover_cache_current`.

**B6. The lock.** (a) A lock directory modified under 30 minutes ago: the call returns 0, FELIX does not
start within three times a control run's duration, the refresh record is unchanged (absent or
byte-identical), and the lock stays. (b) A lock older than 30 minutes (`touch -t 200001010000`) is
removed, FELIX runs once, the record is written, and the lock is gone after. Accepted, as for reach
(`felix_reach_refresh_bg`): a refresh still running after 30 minutes can be overlapped, and its EXIT trap
may remove the newer run's lock.

**B7. The graph lock.** `felix_graph_refresh_bg ROOT` follows B6 with the lock
`ROOT/graphify-out/.felix-refresh.lock` and a stub `graphify` on PATH logging its calls: (a) a fresh
lock means no `graphify` call and the lock stays; (b) a lock older than 30 minutes is broken,
`graphify update ROOT` runs once, and the lock is gone afterwards. The graph refresh keeps no record.

**B8. The pulse's discovery line.** `felix_pulse_report HOME`, for NAME with `routes.tsv`, prints at
most one discovery line for NAME, and nothing it prints contains `refreshes it in the background`:

- (a) cache current and fresh: no `stale` or `discover-unread` line for NAME, whatever the record holds;
- (b) cache stale or absent, no refresh record:
  `stale<TAB>NAME<TAB>discovery cache; no background refresh is recorded here, and the next session in its checkout starts one`
- (c) stale, record `ran`:
  `stale<TAB>NAME<TAB>discovery cache; the last background refresh ran at UTC, and the next session in its checkout starts another`
- (d) stale, record `not-run`:
  `discover-unread<TAB>NAME<TAB>the last background refresh, at UTC, ran nothing: DETAIL; felix discover --adopt in its checkout fills the cache in the foreground`
- (e) stale, record `failed`: as (d) with `failed:` in place of `ran nothing:`;
- (f) stale, record unreadable (empty, more than one line, not three fields, EPOCH not digits, or an
  unknown OUTCOME):
  `discover-unread<TAB>NAME<TAB>the record of the last background refresh could not be read, so whether one can run here is not known; felix discover --adopt in its checkout fills the cache in the foreground`

UTC is the record's EPOCH. In (d) and (e) no line for NAME contains `the next session`. A project
without `routes.tsv` gets no discovery line, as today.

**B9. Said once at session start.** SessionStart in a checkout of NAME, `routes.tsv` present, `claude`
on PATH. (a) Cache stale or absent, record `not-run` or `failed`: additionalContext holds
`Discovery has not refreshed for NAME: the last background refresh, at UTC, ran nothing: DETAIL. felix discover --adopt fills the cache in the foreground.`
(`failed:` for a failed record). (b) The next start with the same OUTCOME and DETAIL, whatever the EPOCH:
not said. (c) A different OUTCOME or DETAIL from the one last said: said again. (d) Never with a `ran`
record, no record, or a current, fresh cache. (e) Unchanged: on a stale cache the hook starts the
refresh and does not wait; with a stub that sleeps 8 s the lock is held when the hook returns, gone later.

**B10. The stamp covers what writes the rows, not the version.** `_felix_discover_stamp [TPL]` from an
engine-tree copy X (`engine/harness` plus `engine/.claude-plugin/plugin.json`), X's `lib/discover.sh`
sourced. (a) It exits 0 and prints 40 lowercase hex characters. (b) Same value after: only `"version"`
changed in X's `plugin.json`; a comment line appended to X's `lib/pulse.sh`; one appended at the end of
X's `felix`. (c) Different after: one line appended to `lib/discover.sh`; one to `lib/detect.sh`; one
comment line inserted directly after `cmd_discover() {` in `felix`; one line changed in
`TPL/discover-rules.tsv` (part 0580 pins that). (d) When the stamp cannot be computed (X without
`felix`), no cache is current: `felix_discover_cache_current` returns 1 for a cache headed `# stamp `
alone and for one headed as X's `_felix_discover_stamp_line` prints, and `felix_discover_stale` returns
0. (e) A fresh cache headed by X's stamp line with two rows, then X's version bumped: from X,
`felix_discover_cache_current` returns 0, `felix_discover_stale` 1, `felix_discover_unseen` lists both
names, and `felix_discover_adopt` reads the rows. Accepted once: the first deploy of this change makes
every older cache read as not current.

**B11. README says what happens.** `README.md` no longer contains `clones candidate plugins once a week`;
contains the literal `[redacted]`; and its hooks-table row beginning `| Session start |` contains
`TMPDIR`. It says: cloning happens about weekly and after an update that changes how discovery scores;
where TMPDIR names no private directory nothing is cloned and the pulse and session start say why;
refused commands are recorded with credential shapes written as `[redacted]`.

### P. The pulse's backup

"Nothing staged by hand" means M's index matches HEAD's tree (on an unborn branch: the index is empty).

**B12. A nested repository is left out; the rest is backed up.** `felix_pulse_backup M`, M on `main`,
nothing staged by hand; `l.md` changed, and new `scraps/` and `a  b/` (two spaces), each a git repository
with one commit; the only remote R a bare repository on this disk (the same holds with no remote).
- Exactly one line starts `backup<TAB>a nested git repository sits inside memory (`, names `scraps` and
  `a  b`, and contains `restore EMPTY` and `NOT backed up`; then exactly `backup<TAB>committed`; then
  (with R) one starting `backup<TAB>pushed and verified: `.
- HEAD moved one commit; its tree holds the new `l.md`, nothing at or under `scraps` or `a  b`, and no
  160000 entry HEAD~1 lacks. `git ls-files -s` holds no 160000 entry, `git status --porcelain` lists
  both directories untracked, each nested HEAD and its files are unchanged, and R's main equals HEAD.
- A gitlink already in HEAD is not new: neither named nor left out (part 0470 holds this today).

**B13. Only nested repositories are new.** As B12 with no other change: the nested line as in B12; no
`backup<TAB>committed` line and none containing `commit FAILED`; a line exactly
`backup<TAB>nothing else new to commit`; HEAD unchanged. The push still runs: with R one commit behind
HEAD (HEAD committed by hand after the last push), R ends at HEAD and `pushed and verified` is printed.

**B14. A nested repository beside a selection staged by hand.** `a.md` staged by hand, `b.md` changed
and unstaged, `nested/` a new repository: one line starts
`backup<TAB>a nested git repository sits inside memory (`, names `nested`, and contains
`restore EMPTY`, `staged by hand` and `NOT backed up`; no `backup<TAB>committed`; HEAD unchanged;
`git diff --cached --name-only` byte-identical to before; the push step still runs. The pulse does not
start acting in a state where it used to stand down beside a person's staged work.

**B15. A file that gains a credential is left out; the rest is backed up.** Nothing staged by hand;
`l.md` gains a clean line, `ok.md` gains `the token field is documented here`, a new `notes/leak.md`
holds a line with K1, and the tracked `m.log` gains a line with K2.
- One line starts `backup<TAB>a possible credential was added to `, names `notes/leak.md` and `m.log`,
  contains `NOT backed up`, and contains neither K1 nor K2 nor the last 12 characters of either. Then
  `backup<TAB>committed`.
- HEAD's tree holds the new `l.md` and `ok.md` and no `notes/leak.md`; HEAD's `m.log` equals HEAD~1's.
  The working tree is untouched (`notes/leak.md` still holds K1, `m.log` K2).
- With a nested repository and a credential both left out, the nested line comes first. When every
  change was left out, the next line is `backup<TAB>nothing else new to commit`, as in B13.
- "A credential" is `bin/secret-scan -`'s verdict on that path's added lines against HEAD, as git's text
  diff shows them; a file git reads as binary is not scanned. On an unborn branch every staged line is
  added: a new file with K1 is left out and named, and the other files make the first commit.

**B16. A credential beside a selection staged by hand.** One line starts
`backup<TAB>a possible credential was added to `, names the file, and contains `staged by hand` and
`NOT backed up`; no `backup<TAB>committed`; HEAD and the staged selection unchanged.

**B17. The scan cannot run.** A harness copy with `bin/secret-scan` removed, `lib/pulse.sh` sourced
from it, and a clean change to `l.md`: one line starts
`backup<TAB>could not scan what would be committed for credentials (` and contains `NOT backed up`; no
`committed` line; HEAD unchanged; no push (R unchanged). With no change at all the line is
`backup<TAB>nothing new to commit`, as today; the scanner is not needed. Not asked is not no.

**B18. End to end, nothing leaks into Felix's records.** `felix pulse`, `FELIX_HOME=H`, `FELIX_MEMORY=M`
(M itself the repository), M as in B15: exit 0; `H/state/pulse.status.tsv` and `H/state/pulse.log` hold
the credential line naming `notes/leak.md`; no file under `H/state`, nor stdout, holds K1 or K2; the
settings line still sits between the backup and report lines (part 1100).

**B19. Where the verified copy is.** `felix_pulse_remote_where REPO REMOTE` prints exactly one word and
exits 0, classifying what `git -C REPO remote get-url REMOTE` prints (the URL verification reads back
from, insteadOf applied). It never prints the URL: for `https://user:<14 characters>@example.invalid/m.git`
it prints exactly `network`. `disk` for `/abs/m.git`, `../rel.git`, `rel.git`, `./a:b.git`,
`file:///abs/m.git`; `network` for `https://example.invalid/m.git`, `ssh://git@example.invalid/m.git`,
`git@example.invalid:m.git`, `example.invalid:m.git`; `unknown` for `fx::/abs/m.git` and for a remote
name not configured.

After a verified push to a bare repository given by absolute path (or as `file://` plus the path), the
verified line is exactly
`backup<TAB>pushed and verified: NAME holds SHA12; NAME is a path on this machine, so this copy is only as far from this disk as whatever syncs that path`;
with `FELIX_HOME_DIR=H`, `H/state/pulse.last-push` is written as today and `H/state/pulse.last-push.where`
holds the one line `disk`. A `network` push keeps today's line and writes `network`. An `unknown` push
appends `; where NAME is could not be read` and writes `unknown`. A failed or unverified push writes
neither file, as today for the stamp. The URL is written nowhere.

**B20. `felix status`'s pulse row.** The pulse row of `felix_status_rows H CWD` keeps state `value`, the
age as its value, and its place among the five rows (part 1100). Its detail is, in order:
`days since memory reached its remote`; then `, a path on this machine` when the where file holds `disk`,
`, a remote whose place could not be read` when it holds `unknown` or anything but `disk` or `network`,
and nothing when it is absent or `network`; then
`; the last run did not back up all of memory (felix pulse says why)` when the record holds a line whose
first field is `backup` and which contains `NOT backed up`; then `; last run UTC` or
`; last run not recorded`, as today. Part 1100's exact strings hold for its fixtures.

### S. Session start

**B21. A pulse that left memory out is said on day one.** SessionStart in a governed checkout,
`FELIX_HOME_DIR=H`. (a) A record starting `# ran E` with a line whose first field is `backup` and which
contains `NOT backed up`: additionalContext holds `The last pulse, at UTC, did not back up all of memory:`
(UTC from E), then each such line's text without its `backup<TAB>` prefix. (b) No such line, or no
record: no such paragraph. (c) Independent of age: with a stamp written today it still appears. (d) Age
banners unchanged: `pulse.log` and no stamp gives `never once got memory off this disk`; a stamp 9 days
old gives `Memory last reached the remote 9 days ago`; a stamp from today, or neither file, gives
neither. (e) A first line not `# ran <digits>`: the paragraph says `at a time not recorded`.

**B22. A cloud session is told its memory dies with the machine.** In a governed checkout with
`CLAUDE_CODE_REMOTE=true`, additionalContext holds
`This is a cloud session: nothing backs up the memory directory above from here, and unless it sits on storage that outlives this machine, what Felix records in it (lessons, catches, declines, the ledger) is lost with the machine.`
With it unset, `false`, `1` or `TRUE`, the sentence is absent (`true` is `.claude/settings.json`'s test).

### R. What Felix records

**B23. `felix_say` writes no credential.** Every credential-shaped substring is written as the literal
`[redacted]`. `felix_say PROJ KIND TEXT CAUSE SESS` with K1 to K6 in TEXT and in CAUSE: `says.log` gains
one 5-field line as today; fields 4 and 5 hold none of K1 to K6 and do hold `[redacted]`;
`bin/secret-scan - < says.log` exits 0. Redaction precedes field 4's 200-character cut: a CAUSE of 190
`x` then K1 leaves no `sk-ant` in field 4. Field 5 is still uncut and a newline still becomes `\n`.
Controls: `the token field is documented` is written unchanged; `line one`/`line two` across a newline
is `line one\nline two`; session and kind fields unchanged.

**B24. `felix_route_log` writes no credential.**
`felix_route_log PROJ - 0 '{"session_id":"s","prompt":"deploy with K1 now"}'`: field 4 of the
`routes.log` line holds `[redacted]` and not K1. Redaction precedes the 160-byte cut: a plain-text
prompt (not JSON) of 150 `x` then K1 leaves a field 4 of exactly 160 bytes with no `sk-ant`. Controls:
`repair the queue worker` is recorded with no `[redacted]`; the runtime's envelope keys are still
stripped and `_felix_mon_prompt` still renders the sentence (part 0240).

**B25. Through the hooks.** (a) A deny row in the widget fixture refuses a Bash command carrying K4: the
pre-tool hook refuses as today, and the last `says.log` line of kind `denied` holds `[redacted]` and not
K4. (b) The user-prompt hook gets a prompt holding K1: the last `routes.log` line holds `[redacted]` and
not K1.

**B26. One source for credential shapes.** Exactly one file under `engine/harness` holds a line starting
`FELIX_SCAN_PATTERNS=`; the redaction and `bin/secret-scan` read that one definition, so a shape added
to the scanner reaches the redaction with no second edit.

### X. Budgets

**B27.** Checked with `wc -l` at review, not by the suite (a suite bound would bind every later change).
`lib/pulse.sh` ≤ 500 (476 today), `bin/secret-scan` ≤ 500 (459); not longer than today: `lib/discover.sh`
(1580), `lib/route.sh` (777), `hooks/session-start` (780), `felix` (6734), `lib/resolve.sh`,
`lib/commission.sh`, `lib/where-read.sh`. New code goes in at most two new `lib/` files of ≤ 500 lines,
each sourced with the house guard (`command -v X || . "$(dirname "${BASH_SOURCE[0]:-$0}")/x.sh"`), so
`lib/resolve.sh` plus any one of `lib/pulse.sh`, `lib/discover.sh`, `lib/say.sh`, `lib/route.sh`,
`lib/status.sh`, `lib/graph.sh` defines every function named here for that area. Session start pays for
its new notices by moving its backup-banner and discovery blocks into lib calls. Bash 3.2 and 5: no
gawk-only awk (part 1497), no `sed` `I` flag, `grep -i` for case-insensitive matching, `LC_ALL=C` for
every sort and comparison.

## 3. What must not change

| Behaviour | Pinned by |
|:---|:---|
| Backup guards: merge, rebase, unmerged index, detached HEAD, foreign or no repo, no remote (`only this disk`), two remotes, divergence not forced, split push URL (`reads back`), failed commit (`NOT backed up`, never ending on success) | `0470-the-pulse-the-heartbeat-that-does-not-wait-f.sh` |
| Nested lines keep `restore EMPTY` and the path (`scraps`, `undeclared`, `a  b`); nested-only commits nothing and leaves no gitlink; a hand-staged selection survives; a gitlink in history never blocks | 0470 |
| `pushed and verified: origin` and `pushed and verified` prefixes; the stamp only on a verified push, local bare remote included; `felix_pulse_backup_age` empty, `never`, `0`, `9`; `--install`, `--uninstall` | 0470 |
| Report `due`, `unchecked`, and `stale<TAB>pulsey` for a stale cache with no refresh record | 0470, `0460-maintenance-a-check-that-names-work-already.sh`, `0671-continued.sh` |
| Fail closed over a tracked pipe, no scratch index, a corrupt index; `L2` names the pipe | `1520-git-readers-fail-closed.sh` |
| `felix status`: five rows in order, four fields, the pulse row's exact detail for its fixtures; the pulse's settings and reach lines, the record and the log | `1100-declared-tools-reach-the-pulse-and-felix-status.sh` |
| `felix_neutral_dir` statuses 1-4, the marker, reach's TMPDIR sentences, no `/tmp` fallback; 1130's B15 (cache is stdout, a failure keeps the old one, no `.new.`, no lock) and B16 (TMPDIR unset, relative, 0777 or under `.mcp.json`: no felix, no claude, no `NAME.tsv`, no lock) | `1120-found-in-review-reach-runs-in-an-empty-directory.sh`, `1130-unattended-work-runs-only-in-its-own-checkout.sh` |
| The stamp follows the rules; a cache with no or another stamp adopts nothing and reads stale; `discover --adopt` refills it; stale when never written, not when fresh; unseen and `.seen` | `0580-tidying-with-the-checks-that-make-it-safe.sh`, `0290-noticing-when-another-plugin-breaks-the-sess.sh` |
| Caches headed by the live `_felix_discover_stamp_line` read current; the felix line `  [ "$quiet" -eq 1 ] && _felix_discover_stamp_line "$tpl"` exists once; the commission discover row reads unknown on a cache not current | 0030, 0040, 0050, 0680, 0730, 0980, 0994, 1020, `tests/lib/discover.sh`; `1270-gate-friction-b-blind.sh`; `0710-commissioning-a-seeded-check-reads-done-only.sh`, `0711-commissioning-a-check-says-it-could-not-be-a.sh` |
| `says.log`: 5 fields, session, cause, `\n` escaping, briefs, kinds `denied` `lifted` `escalated` `excepted` `held`, a dry run byte for byte | `0590-the-pre-flight.sh`, `0230-the-intent-router.sh`, `0620-denial-refuses-what-a-command-changes-not-wh.sh`, `0100-merging.sh`, `0780-exceptions-the-scoped-exception-channel.sh`, `0360-what-felix-merge-records-and-what-it-hands-g.sh` |
| `routes.log`: envelope strip, path keys dropped, `"prompt":` kept for the monitor, the 160-byte cut, promote | `0240-continued.sh`, `0600-what-to-do-next.sh` |
| Memory out of the checkout; the scanner's own verdicts; the deployed surface | `0450-memory-scan-memory-stays-out-doctrine-stays.sh`, `0080-risk-classification.sh`, `0640-the-deployed-surface-is-three-directories.sh` |

Also unchanged: the engine names no project; the pulse runs no `claude` and reaches no network beyond the
backup remote; `felix status` writes nothing; no existing assertion is renamed or removed;
`tests/assertions.tsv` and `tests/red.tsv` are not edited here.

## 4. Assertions

**A0, for every fixture.** Credential shapes are assembled at run time
(`printf '%s%s' AKIA ABCDEFGHIJKLMNOP`), so no line of either part matches the scanner. Git goes through
`_fx_git` or `_fx_cd` under `$TMP` (parts 0002, 0003). A private TMPDIR needs a base no ancestor of which group or
other can write (`$TMP` on macOS, not a Linux runner's `/tmp`): pick it as part 1130's OWBASE loop does
(`$TMP`, `XDG_RUNTIME_DIR`, `RUNNER_TEMP`, `HOME`, each tried with `_rx_base_ok` from
`tests/lib/reach.sh`), register one outside `$TMP` with `_fx_root_add`, remove it at the end. With no
such base those assertions `skip` with the reason and never pass.

Shapes. **DH**: `DH/projects/dp/` with `project.json`, `routes.tsv`, `CLAUDE.md`, and `DH/state/discover/`.
**Stub FELIX**: appends `$(pwd -P)<TAB>$*` to a log; on `discover --inspect --quiet` prints a stamp line
the fixture chose, then `cand1<TAB>llm<TAB>low<TAB>-` and `cand2<TAB>llm<TAB>low<TAB>-`, sleeps
`STUB_SLEEP`, exits `STUB_RC`. **Lib calls** run under `/bin/bash -c` sourcing `lib/resolve.sh` and the
lib, from `$FROOT/harness` or a copy. **Wait**: poll every 0.2 s up to 20 s for the lock gone and the
record present. **Session fixture**: a governed checkout as part 1130 builds one (harness copy with the
stub as `felix`, `claude` stubbed, fixture HOME, FELIX_HOME, FELIX_MEMORY), a SessionStart payload on
stdin, additionalContext read with `python3`, the lock cleared between runs. **M**: `git init -b main`,
a base commit of `l.md`, `ok.md`, `m.log`. **R**: a bare repository at an absolute path. **[control]**
marks an assertion true before and after the fix; every other one is red before it.

### Part 1730 (discovery)

- **A1 (B1).** DH, private TMPDIR, stub with the current stamp: after the wait `dp.refresh` is one line
  of three tab fields, the epoch inside the window, outcome `ran`.
- **A2 (B1).** Same run: no name containing `.new.` in `state/discover`; the call printed nothing and
  returned 0 **[control** for those two**]**.
- **A3 (B2).** `env -u TMPDIR`, then `TMPDIR=`, then `TMPDIR=rel-tmp`: no stub line, no `dp.tsv`, no
  `.lock`; record `not-run` with `TMPDIR is not an absolute path`.
- **A4 (B2).** TMPDIR a 0777 directory, a private one under a `.mcp.json`, a missing path: `not-run` with
  `TMPDIR is not a private directory`, `.mcp.json`, `could not make an empty directory` respectively.
- **A5 (B2).** Across A3-A4: no stub line, no `claude` call, no cache, no lock **[control]**.
- **A6 (B3).** Private TMPDIR: `dp.tsv` equals the stub's stdout **[control]**.
- **A7 (B4).** `STUB_RC=1` over a previous cache: cache byte-identical; record `failed`, `exited 1`.
- **A8 (B4).** `STUB_RC=125`, private TMPDIR: the stub ran once; record `failed`, `exited 125`.
- **A9 (B5).** Stub prints `# stamp stub`: `dp.tsv` is that line plus the rows; record `failed`, detail
  holding `stamp`.
- **A10 (B6a).** A fresh `.lock` the test made: no stub line within 3× A6's duration; record absent (and,
  in a second variant, byte-identical to a pre-written one); `.lock` still present.
- **A11 (B6b).** `.lock` aged with `touch -t 200001010000`: one stub line, `.lock` gone, record written.
- **A12 (B7).** Repo G with `graphify-out/` and a stub `graphify`: a fresh `.felix-refresh.lock` gives no
  call within the window and stays; the same lock aged gives one `update G` call and is gone.
- **A13 (B8a).** Current, fresh cache and a `not-run` record: no `stale` or `discover-unread` dp line.
- **A14 (B8b).** No cache, no record: exactly B8(b)'s line for dp.
- **A15 (B8c).** No cache, record `86400<TAB>ran<TAB>the cache was rewritten`: exactly
  `stale<TAB>dp<TAB>discovery cache; the last background refresh ran at 1970-01-02T00:00Z, and the next session in its checkout starts another`.
- **A16 (B8d).** No cache, record
  `86400<TAB>not-run<TAB>TMPDIR is not an absolute path, so there is no private directory to run discovery in`:
  exactly one dp discovery line,
  `discover-unread<TAB>dp<TAB>the last background refresh, at 1970-01-02T00:00Z, ran nothing: TMPDIR is not an absolute path, so there is no private directory to run discovery in; felix discover --adopt in its checkout fills the cache in the foreground`,
  and no dp line holds `the next session`.
- **A17 (B8e).** Record `86400<TAB>failed<TAB>felix discover exited 3; the previous cache was left as it was`:
  the line holds `at 1970-01-02T00:00Z, failed: felix discover exited 3; the previous cache was left as it was;`.
- **A18 (B8f).** An empty record, a two-line one, `abc<TAB>ran<TAB>x`, and `86400<TAB>maybe<TAB>x`: each
  gives exactly B8(f)'s line.
- **A19 (B8).** Across A13-A18 no report line holds `refreshes it in the background`; a project without
  `routes.tsv` gets no discovery line (that half **[control]**).
- **A20 (B9a).** Session fixture, `env -u TMPDIR`, no cache. Run 1 writes the record, checked to read
  `not-run` (a precondition, as part 0470 asserts its fixtures). Run 2's context holds
  `Discovery has not refreshed for dp: the last background refresh, at ` and
  `ran nothing: TMPDIR is not an absolute path`.
- **A21 (B9b).** Run 3, same environment: no `Discovery has not refreshed`.
- **A22 (B9c).** The record overwritten with
  `<now><TAB>failed<TAB>felix discover exited 3; the previous cache was left as it was`: run 4's context
  holds `failed: felix discover exited 3`.
- **A23 (B9d).** A `ran` record with no cache; separately a current, fresh cache with a `not-run`
  record: no paragraph in either.
- **A24 (B9e).** `STUB_SLEEP=8`, private TMPDIR, no cache: `.lock` exists when the hook returns; after
  the wait it is gone and the stub logged one refresh **[control]**.
- **A25 (B10a, b).** Copy X: 40 hex; equal after a version bump in X's `plugin.json`; equal after a line
  appended to X's `lib/pulse.sh` and at the end of X's `felix` (those two **[control]**).
- **A26 (B10c).** Different after one line appended to `lib/discover.sh`, after one to `lib/detect.sh`,
  after a comment inserted directly after `cmd_discover() {`, each in its own copy, and after a
  rules-table change (that one **[control]**).
- **A27 (B10d).** X without `felix`: `felix_discover_cache_current` 1 for a cache headed `# stamp ` and 1
  for one headed by X's own `_felix_discover_stamp_line`; `felix_discover_stale` 0 for both.
- **A28 (B10e).** A cache headed by X's stamp line, then X's version bumped: `felix_discover_cache_current`
  0, `felix_discover_stale` 1, `felix_discover_unseen` prints `cand1` and `cand2`,
  `felix_discover_adopt` prints two rows.
- **A29 (B11).** `README.md` lacks `clones candidate plugins once a week`, holds `[redacted]`, and its
  `| Session start |` row holds `TMPDIR`.

### Part 1740 (backup, surfaces, records)

- **A30 (B12).** M with `l.md` changed and new repositories `scraps/` and `a  b/`, remote R: one nested
  line naming both with `restore EMPTY` and `NOT backed up`, then `backup<TAB>committed`, then
  `pushed and verified`; HEAD holds the new `l.md`, nothing under either directory, no new 160000
  entry; no gitlink in the index; both untracked, their HEADs unchanged; R's main equals HEAD.
- **A31 (B12).** A gitlink already in HEAD and `l.md` changed: `committed`; the old link not named
  **[control]**.
- **A32 (B13).** Only `scraps/` new, HEAD committed by hand after the last push: no `committed` line;
  `backup<TAB>nothing else new to commit`; HEAD unchanged; R moves to HEAD; `pushed and verified`.
- **A33 (B14).** `a.md` staged by hand, `b.md` unstaged, `nested/` new: the nested line holds
  `staged by hand` and `NOT backed up`; no `committed`; HEAD and `diff --cached --name-only` unchanged.
- **A34 (B15).** K1 in a new `notes/leak.md`, K2 appended to `m.log`, clean changes to `l.md` and
  `ok.md`: the credential line names both files, says `NOT backed up`, holds neither key nor either's
  last 12 characters; `committed`; HEAD holds the new `l.md` and `ok.md`, no `notes/leak.md`, and
  HEAD~1's `m.log`; the working-tree files still hold K1 and K2.
- **A35 (B15).** Each of K1-K6 alone through `bin/secret-scan -` exits 1;
  `the token field is documented here` exits 0 **[control]**.
- **A36 (B15).** Unborn branch, new `leak.md` with K1 and new `a.md`: `leak.md` named and left out; the
  first commit holds `a.md` only.
- **A37 (B16).** `a.md` staged by hand, K1 in a new file: the credential line holds `staged by hand` and
  `NOT backed up`; no `committed`; HEAD and the staged selection unchanged.
- **A38 (B17).** A harness copy without `bin/secret-scan`, `l.md` changed: the line holds
  `could not scan what would be committed for credentials (` and `NOT backed up`; HEAD and R unchanged.
- **A39 (B17).** The same copy, clean tree: `nothing new to commit` **[control]**.
- **A40 (B18).** `felix pulse`, `FELIX_HOME=H`, `FELIX_MEMORY=M`, M as in A34: exit 0; record and log
  hold `notes/leak.md`; `grep -rF` finds K1 and K2 in no file under `H/state` and not in stdout.
- **A41 (B19).** `felix_pulse_remote_where` gives the word B19 lists for each URL, exit 0 each time,
  and exactly `network` for the userinfo URL.
- **A42 (B19).** Push to R by absolute path, and again with the remote URL `file://R`, with
  `FELIX_HOME_DIR=H`: exactly B19's disk line; `pulse.last-push` digits; `pulse.last-push.where` `disk`.
- **A43 (B19).** An unverified push (0470's split push URL): neither file written **[control** for the
  stamp**]**.
- **A44 (B20).** `pulse.log`, record `# ran 86400`, a stamp two days old, where `disk`: the pulse row is
  `pulse<TAB>value<TAB>2<TAB>days since memory reached its remote, a path on this machine; last run 1970-01-02T00:00Z`.
- **A45 (B20).** Where `garbage`: the clause is `, a remote whose place could not be read`.
- **A46 (B20).** Where `disk` and the record adding
  `backup<TAB>commit FAILED; nothing was pushed, and this memory is NOT backed up`: the detail is
  `days since memory reached its remote, a path on this machine; the last run did not back up all of memory (felix pulse says why); last run 1970-01-02T00:00Z`.
- **A47 (B20).** No where file, no such line: part 1100's exact detail **[control]**.
- **A48 (B21a, c).** Session fixture; record `# ran 86400` plus a nested line naming `audits/x/fixture`;
  a stamp from now: context holds `The last pulse, at 1970-01-02T00:00Z, did not back up all of memory:`
  and `audits/x/fixture`.
- **A49 (B21b).** A record with only `backup<TAB>committed` and
  `backup<TAB>pushed and verified: r holds 0123456789ab`, and separately no record: no such paragraph
  **[control]**.
- **A50 (B21d).** `pulse.log`, no stamp: `never once got memory off this disk`; a stamp 9 days old:
  `Memory last reached the remote 9 days ago`; a stamp from now: neither **[control]**.
- **A51 (B21e).** Record first line `# ran soon`: the paragraph holds `at a time not recorded`.
- **A52 (B22).** `CLAUDE_CODE_REMOTE=true`: B22's sentence present; unset, `false`, `1`, `TRUE`: absent
  (unset **[control]**).
- **A53 (B23).** `felix_say` with K1-K6 in TEXT and CAUSE: 5 fields; fields 4 and 5 hold `[redacted]` and
  none of K1-K6; `bin/secret-scan - < says.log` exits 0. A CAUSE of 190 `x` then K1: no `sk-ant` in
  field 4.
- **A54 (B23).** TEXT `the token field is documented`, CAUSE `why I asked`: unchanged; `line one`,
  newline, `line two` written as `line one\nline two` **[control]**.
- **A55 (B24).** `felix_route_log` with K1 in the prompt: field 4 holds `[redacted]`, not K1. A plain-text
  prompt of 150 `x` then K1: field 4 is 160 bytes with no `sk-ant`.
- **A56 (B24).** `repair the queue worker`: field 4 holds it and no `[redacted]` **[control]**.
- **A57 (B25a).** Widget fixture with a deny row added for the test and removed after: a Bash command
  carrying K4 is refused as today; the last `denied` line holds `[redacted]`, not K4.
- **A58 (B25b).** Widget fixture's user-prompt hook with K1 in the prompt: the last `routes.log` line
  holds `[redacted]`, not K1.
- **A59 (B26).** `grep -rl '^FELIX_SCAN_PATTERNS=' "$FROOT/harness"` prints exactly one path **[control]**.
- **A60 (A0).** `bin/secret-scan -` over each new part file exits 0.

## 5. Parts

`engine/harness/tests/parts/1730-discovery-never-promises-blind.sh` holds A1-A29, and
`engine/harness/tests/parts/1740-pulse-backup-and-records-blind.sh` holds A30-A60. Each is ≤ 500 lines,
registered in `engine/harness/tests/run` after `1600-felix-refuses-a-pattern-kill-blind.sh` and before
`9990-…`, in no group of `groups.tsv`, and committed before the run that lints it (lints read tracked
files only). Each assertion name is the sentence it proves, and is new.

## 6. Out of scope, with why

- **A TMPDIR fallback of Felix's own** (C016's sketch). Decided the other way:
  `docs/2026-10-12-declared-tools-reach-spec.md` (about lines 859-867: "remove the fallback, and run
  nothing where there is no private `TMPDIR`") and `docs/2026-10-13-unattended-own-checkout-spec.md` B16
  and D1; parts 1120 and 1130 pin it, and `felix_neutral_dir` is shared with reach. That spec accepted
  reach's cost because it is said (`reach-unread`); B2, B8 and B9 give discovery the same.
- **A discovery row in `felix status`**: part 1100 pins exactly five rows. **A per-project lock or a pid
  in the lock**: the lock stays home-wide; B6's rule is reach's.
- **C055's side notes** (plain `felix discover` never writes the cache; the land tick cuts off the
  refresh it starts) and **the commission receipt not going stale on engine changes**: separate findings.
- **A SessionEnd push of cloud memory, or `CLAUDE_CODE_REMOTE_MEMORY_DIR`** (C036's sketch): the VM has
  no memory remote, nothing shows the variable is set or outlives the VM, and a credentialed cloud remote
  is the founder's open item (`docs/handoff/0dh.md:108-112`). B22 says it.
- **Silence before a laptop's first pulse**: recorded design ("nothing to report rather than an alarm");
  scheduling is a grant, and `felix status` says it never ran.
- **Redaction in other memory writers** (`lessons.md`, `mistakes.log`, `decisions.log`, handoffs): B15's
  scan covers every file where memory leaves. **Rewriting history** that holds the 4 fixture keys:
  irreversible, a person's call.
- **pre-tool's stderr echo** (the transcript, not a Felix record); **binary files** (text diffs only, as
  the scanner); **iCloud's upload state** (`brctl`, macOS-only); **the pulse's other refusals**
  (unchanged, still before the push).

### Not fixed: not a defect

- **C043, "sleep, reboot or TERM-then-KILL orphans the lock"**: bash runs the EXIT trap on TERM and HUP
  (measured on /bin/bash 3.2.57; only KILL left it), and sleep kills nothing. B6 covers KILL. **"7 of 9
  caches stale from a lock"**: misattributed; the founder's `state/discover` has no `.lock`, and those
  projects had no session or an engine change. **"A refresh failing every time holds the lock"**: a
  failing run frees it; its silence is the defect (B1, B4, B8).
- **C016, "the catalogue is never built"**: commissioning fills it once in the foreground (`felix` about
  3229-3241, `templates/commissioning.tsv:85`); the unattended refresh is what stalls.
- **C036, "routes mount nothing"**: routes come from `routes.tsv`; lessons are a separate block
  (`hooks/user-prompt` about 245-257). **"The platform offers a persistent directory"**: not
  established; the binary only switches auto-memory off remotely unless the variable is set.
- **C055, "one session a day never shows Worth a look"**: a one-session delay unless a release lands
  between every two sessions; `felix_discover_unseen` marks nothing seen when it prints nothing.
- **C094, "the banners and status row claim the copy left the disk"**: every visible line is literally
  true; the claim is in code comments. B19 and B20 close the gap.

## 7. Founder PR

None. No `.github/workflows` change, no deny or escape row, no commission grant or table (the grant
hashes project tables, untouched), nothing published.

## 8. Red

Run before any code changed, at d17ea00b, `tests/run --part 1730-discovery-never-promises-blind.sh
1740-pulse-backup-and-records-blind.sh` alone under macOS BWK awk and bash 3.2 (7 min, nearly all of it
the 20 s Waits on records the engine never writes). 66 assertions of this batch: **43 failed, 23 passed**,
none skipped (a private base was found).

Failed (43): A1, A3, A4, A7, A8, A9, A11, A12, A14-A19, A20 and its precondition, A21, A22, A25-A30,
A32-A34, A36-A38, A40-A42, A44-A46, A48, A51, A52, A53, A55, A57, A58.

Passed (23), and why each did:

| Assertion | Why it passed before the fix |
|:---|:---|
| A2, A6 | Controls (B1's no `.new.` file, silent call and 0; B3's cache is stdout): true before and after. |
| A5 | Control: B16's six TMPDIR cases already start no felix or claude and leave no cache or lock. |
| A10 | Already true, and half vacuous: today any lock blocks whatever its age, so a fresh one starts no felix; the record is never written, so "absent" holds trivially. A11 is the half that fails. |
| A13 | Already true: a current, fresh cache prints nothing; the record is not read today, so "whatever it holds" is vacuous. |
| A19 (control), A24 (control), A25 (control), A26 (control) | Controls: a project without `routes.tsv` has no discovery line; the hook starts the refresh and does not wait; pulse.sh and the end of felix leave the stamp alone; a rules-table change moves it. |
| A23 | Vacuous before: the session-start sentence does not exist, so "never said with a ran record or a current cache" holds trivially. It guards only after the fix. |
| A31 (control), A35 (control), A39 (control) | Controls: a gitlink already in HEAD is not new; `secret-scan -` flags K1-K6 and passes the documented token field; no scanner and no change reads `nothing new to commit`. |
| A43 (control) | Control: a push nothing reads back writes no `pulse.last-push`. |
| A43 (`.where`) | Vacuous before: no code writes `pulse.last-push.where`, so it is absent after any push; it guards only after B19. |
| A47 (control), A50 (control) | Controls: the pulse row with no where file or NOT-backed-up line is part 1100's; the age banners are unchanged. |
| A49 (control) | Vacuous before: the B21 paragraph does not exist, so "no such paragraph" holds for any record; it guards only after B21. |
| A52 (control) | Vacuous before: the cloud sentence does not exist, so it is absent with the variable unset. |
| A54 (control), A56 (control) | Controls: a clean text is written unchanged and a newline becomes `\n`; a clean prompt is logged with no `[redacted]` and the monitor renders it. |
| A59 (control) | Control: exactly one file under the harness defines `FELIX_SCAN_PATTERNS=` today. |
| A60 | Already true: it scans the two part files, which hold no shape by construction (A0). |
