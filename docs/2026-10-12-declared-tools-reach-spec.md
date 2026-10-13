# Declared tools' reach, the pulse's two new duties, and `felix status`: the specification

Written 2026-10-12. The design brief was decided by the orchestrating session;
this makes it exact and does not reopen it. Every behaviour below is numbered,
says what is observable, and is meant to become one or more assertions in
`engine/harness/tests/parts/`. The decisions taken where the brief left a
choice are in section 7, each with its reason.

Tier: adversarial. `engine/harness/lib`, the `felix` CLI and
`hooks/session-start` run in every session of every governed project.

Notation: `\t` is one tab byte. `<epoch>` is `date +%s`. A row written
`a\tb\tc` is one line ending in a newline.

---

## 0. What exists today, read for this spec

- `lib/stack.sh` reads `claude mcp list` into `_FELIX_MCPS` inside
  `_felix_load_state` (with `|| true`, so a failed run is an empty list), and
  `_felix_mcp_connected <name>` walks it: a line matching `<name>:*` or
  `*:<name>:*` is not mounted when it contains `Failed to connect` or
  `Needs authentication`, and is mounted otherwise. `felix_stack_plan` calls it
  through `_felix_have` for `mcp` rows. Plugin rows are `present` once
  `claude plugin list` names them, whatever their servers do.
- `lib/toolbox.sh`: `felix_toolbox_path <plugin-name>` returns the newest
  `$FELIX_PLUGIN_CACHE/*/<plugin-name>/<version>` directory (sort -V), or 1.
  `FELIX_PLUGIN_CACHE` defaults to `$HOME/.claude/plugins/cache` and is the
  suite's override.
- Plugin manifests on this machine come in three shapes, all observed
  2026-10-12: `.mcp.json` wrapping servers in `"mcpServers"` (context7),
  `.mcp.json` with servers at the top level (github, playwright), and
  `.claude-plugin/plugin.json` carrying `"mcpServers": "./.dd_claude-code_mcp.json"`
  (datadog, server key `mcp`).
- `claude mcp list` (measured 2026-10-12, 5.6 s wall, exit 0 although two
  servers failed): a first line `Checking MCP server health…`, a blank line,
  then one line per server, `<key>: <target> - <glyph> <status>`, where key is
  `plugin:<plugin>:<server>` for a plugin's server, the target may be a URL
  carrying a query string (context7's carries `?client=...`), and status is
  `Connected`, `Needs authentication`, or `Failed to connect — <error>` where
  the error can itself quote a URL with a query string. No tab, no escape
  sequence, when stdout is not a terminal.
- `claude mcp list` and project-scoped servers (measured 2026-10-12 with the real
  CLI, after the review of this branch): run in a directory holding a
  `.mcp.json` whose server is not yet approved, it lists that server as
  `<key>: ... - ⏸ Pending approval (run `claude` to approve)` and does not start
  it (the probe's marker file was never written). Run in an empty directory it
  does not list the server at all, and exporting `CLAUDE_PROJECT_DIR` naming the
  checkout changes nothing. It does start a user-scoped server (`npx -y
  ruflo@latest` is one here) in whatever directory it is run in, and a
  project-scoped server that is approved, or auto-enabled by
  `enableAllProjectMcpServers`, is started like any other. It walks up: run in
  an empty subdirectory of a checkout, it lists the checkout's `.mcp.json`
  server, so an empty directory under a project is not neutral.
- Who can write where (measured 2026-10-12, macOS 26): `/tmp` is
  `/private/tmp`, owned by root, mode 1777, so any local user can create a file
  in it (the sticky bit stops a delete, not a create). The per-user temporary
  directory (`getconf DARWIN_USER_TEMP_DIR`, the default `TMPDIR`) is
  `/private/var/folders/<xx>/<hash>/T`, owned by the user, mode 0700, under a
  parent owned by the user at 0755, then `/private/var/folders/<xx>`,
  `/private/var/folders`, `/private/var`, `/private` and `/`, all owned by root
  at 0755. A bare `mktemp -d` on macOS ignores `TMPDIR` and always uses that
  per-user directory (part 1000), so the template form is required. `stat -f
  '%u %Lp'` reads owner and mode on macOS and `stat -c '%u %a'` on GNU; each
  fails on the other platform.
- `lib/discover.sh`: `felix_discover_refresh_bg` takes a lock directory with
  `mkdir`, runs a subshell that traps `rmdir` on EXIT, calls
  `felix_close_inherited_fds`, `cd`s to the checkout, writes `<cache>.new.$$`
  and moves it into place only on success, all `</dev/null >/dev/null 2>&1 &`.
- `hooks/session-start` already sources `stack.sh` and `pulse.sh`, resolves
  `PROJ`, `FELIX_HOME_DIR` and `_repo_root`, and starts the discovery refresh
  in the block headed `# --- discovery ----`, before the emit.
- `lib/pulse.sh`: `felix_pulse_backup`, `felix_pulse_backup_age <home>`
  (empty when `state/pulse.log` is absent, `never` when it exists with no
  verified push stamp, else whole days), `felix_pulse_report <home>` (lines
  `<kind>\t<project>\t<text>` for `due`, `unchecked`, `unknown`, `stale`), and
  `felix_pulse_plist`. `cmd_pulse` prints `pulse\t<UTC ISO>`, then backup lines,
  then report lines, all through `tee -a state/pulse.log`. The plist lives at
  `$HOME/Library/LaunchAgents/felix.pulse.plist`, label `felix.pulse`.
- `lib/verify.sh`: `felix_verify_current <root> <home> <proj>` prints one line,
  `none`, `red`, `stale\t<reason>` or `current`. It recomputes the decision
  epoch, which runs the project's probes, only when the receipt's tree id
  matches.
- `felix`: `cmd_stack` takes `sub="${1:-plan}"`, shifts, scans the rest for
  `--yes`, handles `reconcile` before the `stack.tsv` guard, computes
  `felix_stack_plan` (three `claude` reads), then answers `plan`, and dies with
  `usage: felix stack [plan|apply|reconcile] [--yes]` for anything that is not
  `apply`. Today `felix stack --reach` therefore runs the plan's three reads and
  then dies. Extra arguments after a subcommand are ignored, so
  `felix stack apply --yes --anything` applies.
- The suite (`tests/run`) builds a fixture home `$FROOT` (exported as
  `FELIX_HOME`), memory root `$MEM` (exported as `FELIX_MEMORY`), and a
  checkout `$REPO` bound by marker. HOME is not isolated globally: a part sets
  `HOME=<fixture>` on the command it runs (`0470` uses `$TMP/pulse-fakehome`).
  Commands are stubbed by a directory first on `PATH`: `0010` writes a `claude`
  that logs every argument line and exits 2 on any shape it was not taught;
  `0470` writes `launchctl` and `uname` stubs (`UNAME_STUB=Darwin|Linux`).
  `0480` asserts that every command the dispatcher's `case "${1:-help}"` names
  appears in `felix help` as `felix <command>`. `1040` asserts every part is
  sourced once by `run`, is named `NNNN-name.sh`, is at most 1,000 lines, and
  parses alone. `1000` asserts every `mktemp` is given a template.
- Shipped engine versions are recorded in `engine/.claude-plugin/plugin.json`
  and, per landing, in a pending handoff section under
  `docs/handoff/pending/` written with `felix handoff --section FILE`.

---

## 1. Files

| file | change |
|---|---|
| `engine/harness/lib/reach.sh` | new: the read, the classifier, the cache, the background refresh, the pulse lines, the status summary |
| `engine/harness/lib/status.sh` | new: `felix_settings_state`, `felix_schedule_state`, the five status rows |
| `engine/harness/lib/stack.sh` | one helper extracted from `_felix_mcp_connected`, which keeps its behaviour |
| `engine/harness/lib/pulse.sh` | header text, the reach lines inside `felix_pulse_report`, two guarded sources |
| `engine/harness/felix` | sources both new libs; `cmd_stack --reach`; `cmd_pulse` settings line and record; `cmd_status`; dispatcher; `usage`; header comment |
| `engine/harness/hooks/session-start` | sources `reach.sh`; one block that starts the refresh |
| `engine/.claude-plugin/plugin.json` | `"version": "0.49.282"` |
| `engine/harness/tests/parts/1100-…`, `1110-…`, `1120-…` | the assertions; `tests/run` sources each; `assertions.tsv` and `red.tsv` re-recorded |
| `docs/handoff/pending/<stamp>-claude-declared-tools-reach.md` | the shipped-version entry |

Every new or edited lib stays under 500 lines (`reach.sh` and `status.sh` are
new; `pulse.sh` is 383 today and gains under 40). No engine file names a
project. Both new libs follow the house pattern: anything they call from
another lib is sourced by path behind `command -v <fn> || . "$(dirname
"${BASH_SOURCE[0]:-$0}")/<lib>.sh"`, because the suite sources libs alone in
subshells.

---

## 2. Part 1: reach

### Functions (lib/reach.sh unless noted)

- `_felix_mcp_line_state <line>` (lib/stack.sh): prints `failed` when the line
  contains `Failed to connect`, else `needs-auth` when it contains
  `Needs authentication`, else `connected` when it contains `Connected`, else
  `other`. Checked in that order.
- `_felix_mcp_connected <name>` (lib/stack.sh) keeps its matching and its
  verdicts and asks the helper: a matching line whose state is `failed` or
  `needs-auth` returns 1; any other matching line returns 0; no matching line
  returns 1.
- `felix_reach_read` (in `lib/reach-read.sh`, which `lib/reach.sh` sources, so
  that neither file passes 500 lines): runs `claude mcp list` once, from a fresh
  empty directory under a private `TMPDIR` (R13) and never the caller's, into
  `_FELIX_REACH_LIST`; returns 0 when the list was read and 1 when not, setting
  `_FELIX_REACH_WHY` to one sentence. `_felix_reach_private <dir>` is the test
  R13 applies to `TMPDIR`.
- `felix_reach_rows <proj>`: classifies every `plugin` and `mcp` row of
  `<proj>/stack.tsv` against the list already read (or, when the last read
  failed, as unknown). Emits rows, prints nothing else.
- `felix_reach_cache <proj> <home>`: prints `<home>/state/reach/<basename proj>.tsv`.
- `felix_reach_refresh <proj> <home>`: read, classify, write the cache when
  the read succeeded, print the rows; returns the read's status.
- `felix_reach_due <proj> <home>`: 0 when the project declares a plugin or mcp
  row and its cache is absent, has no valid header, or was read 24 hours ago
  or more.
- `felix_reach_refresh_bg <proj> <home>`: the background form. It takes no
  checkout root: it does not stand in the checkout and has no use for it (R13).
- `felix_reach_report <proj> <home>`: the pulse's lines for one project.
- `felix_reach_summary <proj> <home>`: the status row's state, value, detail.

### Behaviours

**R1. One read.** `felix_reach_read` runs `claude mcp list` exactly once per
call, from the empty directory R13 makes, with stderr discarded, capturing
stdout, the exit status and a sentinel in one substitution (shape:
`out="$(cd "$dir" && claude mcp list 2>/dev/null; printf '\n.%s' "$?")"`),
so a substitution that could not make its pipe reads as unread, not as an
empty list. It is unread, return 1, when:
- `command -v claude` fails: `_FELIX_REACH_WHY` = `no claude CLI on PATH`;
- `TMPDIR` is unset, empty or not an absolute path (R13): `TMPDIR is not an
  absolute path, so there is no private directory to run claude mcp list in`,
  and `claude` is not run;
- `TMPDIR` is not a private directory (R13): `TMPDIR is not a private
  directory, so claude mcp list was not run: it must be owned by you and
  writable by no one else, under parents only you or root can write`, and
  `claude` is not run;
- the empty directory could not be made or entered (R13), or `TMPDIR` is `/` or
  names no directory: `could not make an empty directory to run claude mcp list
  in`, and `claude` is not run;
- a `.mcp.json` exists in that directory's parents (R13): `a .mcp.json sits
  above the scratch directory, so claude mcp list could start a project-scoped
  server there`, and `claude` is not run;
- the sentinel is missing: `the list's output could not be captured`;
- the exit status is not 0: `claude mcp list exited <n>`;
- stdout is empty: `claude mcp list printed nothing`.
A stub `claude` that prints the five-line fixture below and exits 0 is read.
A stub that prints the same and exits 1 is unread. A stub that exits 0 and
prints nothing is unread.

Fixture used throughout this spec (call it LIST-A):

```
Checking MCP server health…

plugin:ctx:ctx: https://mcp.example/mcp?client=claude&key=SECRET (HTTP) - ✔ Connected
plugin:gh:gh: https://api.example/mcp/ (HTTP) - ✘ Failed to connect — HTTP 400: bad request
plugin:cf:cf-api: https://cf.example/mcp (HTTP) - ! Needs authentication
plugin:cf:cf-docs: https://docs.cf.example/mcp (HTTP) - ✔ Connected
plugin:dd:mcp: https://not-setup/v1/mcp?referrer=x (HTTP) - ✘ Failed to connect — ENOTFOUND: TypeError dialing https://not-setup[redacted]?k=REDACTED (ENOTFOUND)
sentry: https://mcp.sentry.example/mcp (HTTP) - ✔ Connected
```

**R2. Server lines.** A list line is a server line when it contains `: ` and
the text before the first `: ` (its key) contains no space. Every other line
(the health header, the blank line, prose) is ignored.

**R3. Row shape.** Each emitted row and each cache row is
`<state>\t<kind>\t<declared name>\t<server>\t<detail>`. `state` is one of
`connected`, `needs-auth`, `failed`, `not-listed`, `no-server`, `unknown`.
`kind` is `plugin` or `mcp`. The declared name is column 2 of the stack.tsv
row, verbatim. `server` is the server line's key, verbatim, or `-` when no
line names one. `detail` is never empty (`-` at least) and holds no tab, CR or
newline (each replaced by a space).

**R4. Plugin rows.** For a row `plugin\t<x>[@<mkt>]\t...`, with `x` the name
before any `@`:
1. The list unread (R1): one row `unknown\tplugin\t<name>\t-\t<_FELIX_REACH_WHY>`.
2. Server lines whose key begins `plugin:<x>:`: one row per such line, in
   list order, state from `_felix_mcp_line_state` (`other` maps to
   `unknown`), server = the key.
3. No such line, and `felix_toolbox_path <x>` fails: `unknown`, server `-`,
   detail `no installed directory for <x>, so whether it ships an MCP server is not known`.
4. No such line, the directory found, and the plugin declares a server (R5):
   `not-listed`, server `-`, detail
   `the plugin declares an MCP server and no line of claude mcp list names one`.
5. No such line, the directory found, no server declared: `no-server`,
   server `-`, detail `the plugin declares no MCP server; its reach is its install, which felix stack plan reports`.

With LIST-A and stack rows `plugin ctx@m`, `plugin gh@m`, `plugin cf@m`,
`plugin dd@m`, `plugin quiet@m` (fixture cache directory, no server
manifest), `plugin gone@m` (no directory), `plugin lost@m` (directory with
`.mcp.json` holding `"command"`): rows in that order are
`connected ctx`, `failed gh`, `needs-auth cf cf-api`, `connected cf cf-docs`,
`failed dd`, `no-server quiet`, `unknown gone`, `not-listed lost`.

**R5. Declares a server.** A plugin directory `d` declares an MCP server when
`d/.mcp.json` exists and its text contains `"command"` or `"url"`, or when
`d/.claude-plugin/plugin.json` exists and its text contains `"mcpServers"`.
The text is read whole into a variable and tested with `case`, never piped
into `grep -q`. All three shapes in section 0 read as declaring.

**R6. mcp rows.** For a row `mcp\t<n>\t...`: list unread gives one `unknown`
row as in R4.1; otherwise every server line `_felix_mcp_connected` would match
(key equal to `<n>`, or containing `:<n>:`; the same two `case` patterns) gives
one row, state as in R4.2; no matching line gives
`unknown\tmcp\t<n>\t-\tno line of claude mcp list names this server; a project-scoped server is not started by Felix, so whether it connects is not known`.
The list is read from an empty directory (R13), where a project-scoped server
is not listed because Felix did not start it, so a server that list does not
name is not known to be missing. `no-server` and `not-listed` never apply to an
mcp row, and neither does `failed` unless a line says `Failed to connect`.
(Until the review of this branch the no-match row was `not-listed`.) With
LIST-A, `mcp sentry` reads `connected`, and an mcp row `nothere` reads `unknown`
with that detail.

**R7. Detail never carries a query string.** For a server line, detail is the
text from the first occurrence of the status phrase (`Failed to connect`,
`Needs authentication` or `Connected`) to the end of the line, cut before its
first `?`. For `other`, it is the text after the line's last ` - `, cut the
same way. The target column of the line is never copied. With LIST-A, no row,
cache line, pulse line or status line contains `SECRET`, `REDACTED`,
`client=`, `referrer` or `?`; the `dd` row's detail is
`Failed to connect — ENOTFOUND: TypeError dialing https://not-setup[redacted]`.
No truncation: a byte cut can split a multibyte character, and one bad byte
empties a macOS UTF-8 `sort`.

**R8. Rows the stack does not hold.** `marketplace` and `skill` rows emit
nothing. A project with no stack.tsv, or no plugin or mcp row, emits nothing.
Capability is not consulted: a dormant row is read like any other (section 7,
D7).

**R9. The cache.** Path `$FELIX_HOME_DIR/state/reach/<project>.tsv`. Content:
first line `# read <epoch> <dir>` (dir = `pwd -P` of the empty directory the
read ran in, R13, the rest of the line; the directory is gone by the time
anyone reads it, and it is never the checkout or `$HOME`), then exactly the rows
`felix_reach_rows` printed. Written to
`<cache>.new.$$` and moved with `mv -f`; on any failure the temp file is
removed. Written only when R1 read the list: an unread list leaves an
existing cache byte-identical, and creates none. A project with no plugin or
mcp row gets no cache. A cache whose first line is not `# read <digits> ...`
is treated everywhere as absent.

**R10. Background refresh at SessionStart.** In `hooks/session-start`,
immediately after the discovery block and before the commissioning block:

```
if [ -n "$PROJ" ] && [ -f "$PROJ/stack.tsv" ] && command -v claude >/dev/null 2>&1 \
   && command -v felix_reach_due >/dev/null 2>&1 \
   && felix_reach_due "$PROJ" "$FELIX_HOME_DIR"; then
  felix_reach_refresh_bg "$PROJ" "$FELIX_HOME_DIR"
fi
```

`felix_reach_refresh_bg` has `felix_discover_refresh_bg`'s shape without its
`cd` to the checkout: `mkdir -p state/reach`, take the lock directory
`state/reach/<project>.lock` with `mkdir` (return 0 if held), then a subshell
that traps `rmdir` of the lock on EXIT, calls `felix_close_inherited_fds`, and
runs `felix_reach_refresh`, the whole subshell `</dev/null >/dev/null 2>&1 &`;
return 0. It never stands in the checkout: the read it runs makes its own empty
directory (R13). (The first draft `cd`ed to the checkout so a project-scoped
`.mcp.json` would be seen; that instruction is withdrawn, R13 and D18 say why.)
A lock directory older than 30
minutes (`find <lock> -maxdepth 0 -mmin +30` names it) is removed with `rmdir`
and taken again, because a refresh killed by a signal never runs its trap.
Observable:
- Nothing about reach reaches the session: with the cache absent, and with
  LIST-A as the stub's answer, the hook's stdout contains none of
  `reach`, `needs-auth`, `not-listed`, `Failed to connect` or
  `Needs authentication`, and is valid JSON as `0010` already checks.
- With a stub `claude` whose `mcp list` sleeps 5 s, the hook returns in under
  3 s and exits 0.
- With the cache absent, a cache appears within 10 s, its header's directory
  is a `felix-reach.XXXXXX` directory under TMPDIR and not the checkout root,
  its rows are R4's.
- In a fixture checkout whose `.mcp.json` declares a server whose command would
  write a marker file, and with a `claude` stub that records its `$PWD` and
  starts the `.mcp.json` command of the directory it is run in (its control, run
  in the checkout, does write the marker): after a session start in that
  checkout and the refresh, the recorded `$PWD` is neither the checkout nor
  `$HOME`, no marker was written (a second `.mcp.json` in the fixture `$HOME`
  has its own marker, also never written), and TMPDIR holds nothing.
- With a TMPDIR that cannot make a directory, or that others could write into
  (R13), the refresh runs no `claude` command and writes no cache, and its lock
  is released.
- With a cache read less than 24 h ago, the stub's log gains no `mcp list`
  line from a second hook run.
- With the header epoch set to now − 90,000, a hook run refreshes it.
- With a stub whose `mcp list` exits 1 and an existing cache, the cache is
  byte-identical after the refresh has had 10 s.
- With the lock directory present and fresh, no refresh runs; with it 31
  minutes old (`touch -t`), one does.

**R11. `felix stack --reach [--tsv]`.** Recognised only as the first argument
to `felix stack`, and handled before the `stack.tsv` guard and before
`felix_stack_plan`, so it runs one `claude` command, `mcp list`, and no
`plugin list` or `marketplace list`. It runs `felix_reach_refresh`, whose read
is from an empty directory (R13) whatever the cwd, so a project-scoped
`.mcp.json` server of the checkout the person stands in is neither started nor
listed, and exits 0 for any report, unread list included.
- `--tsv`: stdout is exactly the rows, no header, no summary; nothing else.
- Without `--tsv`, aligned lines `printf '%-11s %-7s %-44s %-34s %s\n'` of
  state, kind, name, server, detail, under a header line made by the same
  printf from `STATE KIND NAME SERVER DETAIL`, then a blank line and
  `<c> of <t> servers connected; <u> unreachable; <k> unknown.`, where `t`
  counts rows whose state is not `no-server`, `c` the `connected` rows, `u`
  the `needs-auth`, `failed` and `not-listed` rows, `k` the `unknown` rows.
  Then one of: `Advisory: nothing was installed, enabled or held. Written to <cache>.`
  or, when the list was unread,
  `The server list could not be read (<why>); the cache was left as it was.`
- A project with no plugin or mcp row: `<project> declares no plugin or mcp rows; nothing to reach.`,
  exit 0, no cache.
- Usage errors, exit 2, stderr containing
  `usage: felix stack [plan|apply|reconcile] [--yes] | felix stack --reach [--tsv]`
  (through `die`, so prefixed `felix: `), nothing on stdout: any argument after `--reach` other than a
  single `--tsv`; and `--reach` anywhere but first (`felix stack apply --yes --reach`
  installs nothing, runs no `claude` command, and exits 2).
- `felix stack plan`, `apply`, `reconcile` and bare `felix stack` behave
  exactly as before for every other argument list.
- With the stub of R10: `felix stack --reach --tsv` run from the hostile
  checkout records a `$PWD` that is neither the checkout nor `$HOME`, writes no
  marker, leaves TMPDIR empty, and the cache header names the recorded
  directory. Run from a scratch home (`FELIX_HOME`, D20) it writes the cache and
  `pulse.status.tsv` under that home and nothing under the home the
  `~/.felix-home` pointer names.

**R12. Advisory only.** Nothing outside lib/reach.sh, lib/status.sh and
`felix stack --reach` reads `state/reach`. Observable:
- A stub whose `plugin list` names `cf@m` and whose `mcp list` is LIST-A:
  `felix stack plan` prints `present` for `plugin cf@m`, though its server
  `cf-api` needs authentication.
- `_felix_mcp_connected` verdicts are unchanged: `mcp sentry` with LIST-A is
  `present` in the plan; an mcp row `cf-api` (matched via `:cf-api:`) is not
  present, because its line needs authentication.
- A text check: of the files `felix`, `lib/*.sh`, `hooks/*` and `bin/*`,
  only `lib/reach.sh` contains the string `state/reach`.
- The comment at the head of lib/reach.sh says invariant 2 holds because
  nothing on the enforcing path waits on or reads this result: the hook only
  starts it detached and never reads it; the gate, the Stop hook,
  commissioning and `felix stack plan` never read the cache.

**R13. The list is read from an empty directory under a private TMPDIR, never
the checkout.** This replaces the first draft's instruction to read it in the
checkout, withdrawn after the adversarial review. `felix_reach_read` makes the
directory with `mktemp -d "<physical TMPDIR>/felix-reach.XXXXXX"` (a template, so
it honours TMPDIR on macOS, as part 1000 requires), runs `claude mcp list` with
that as the cwd, and removes the directory and whatever `claude` left in it
afterwards, on every path after it was made, read or unread. The directory is
never the checkout and never `$HOME`, which is itself a repository on the
machine this was found on. It fails closed: when `mktemp` fails or the directory
cannot be entered, the list is unread (R1's sentence) and `claude` is not run,
in no other directory.

*TMPDIR must be a directory nobody else can write (D21).* There is no default:
`TMPDIR` is used only when all of these hold, tested on the physical path
(`cd "$TMPDIR" && pwd -P`, so a symlink is judged by where it leads, and `/` is
refused outright):
1. it is an absolute path (unset, empty, `.` and any relative path are refused
   with the first sentence of R1, whatever the directory they name);
2. the directory is owned by the current user (`test -O`);
3. it and every ancestor up to `/` is owned by root or the current user;
4. it and every ancestor up to `/` has neither the group write bit nor the
   other write bit (mode `& 022` is zero), the sticky bit not excusing it.
Owner and mode come from `stat -c '%u %a'`, then `stat -f '%u %Lp'`, each
answer accepted only as a decimal uid and octal digits, then `ls -ldn` (uid the
third field, write bits the 6th and 9th characters of the mode string). When
none can say, the directory is not private. No other principal can
create, replace or rename anything in that chain, so there is no window between
the check and the read. macOS's
per-user temporary directory passes; a Linux machine whose `TMPDIR` is unset or
under `/tmp` does not, and reads `unknown` until `TMPDIR` names a private
directory. Not covered, and said: another process of the same user, and an ACL
that grants someone else write.

*The ancestor `.mcp.json` check stays.* Because the CLI walks up to a parent's
`.mcp.json` (section 0), the directory is also refused, and the list unread
with its own sentence (R1), when any directory from it up to `/` holds a
`.mcp.json`: a `TMPDIR` inside a repository. It is a check made before the read
and so cannot by itself close a race; R13's rule above does that, and this
catches what the rule does not mean to, a private directory that happens to sit
under a project.

The reason for all of it is that a project-scoped server declared by the
checkout's `.mcp.json` is started by `claude mcp list` once it is approved, or
auto-enabled by `enableAllProjectMcpServers`, and the refresh runs in every
session start of every governed project, including a repository the founder
opened to hunt for bugs. Measured 2026-10-12 (section 0): a server still pending
approval is not started, so the review found the old behaviour safe only while
Claude Code's approval state happened to hold; this removes the dependence on
it. Consequences, accepted (D18, D19, D21): servers that exist only in a
project's `.mcp.json` or a local-scope entry are not listed, so an mcp row
naming one reads `unknown` (R6); plugin rows are unaffected for a plugin
installed at user scope, which is how `felix stack apply` installs them; a
plugin a person enabled only through a project's own settings reads as if not
listed; and where `TMPDIR` is not private nothing is read at all, so `felix
stack --reach` prints every declared row as `unknown` with the sentence that
says why, and no cache is written: the pulse says `reach-unread` until one is,
and `reach-stale` once an old one is a week old.

---

## 3. Part 2: the pulse

**P1. The settings check is one function.** `felix_settings_state` in
lib/status.sh prints `<value>\t<detail>` and returns 0. The file is
`${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json`; the parser is
`${FELIX_JQ:-jq}`. In order:
1. The file does not exist (`[ -e ]` false): `missing\t<path> does not exist`.
2. It exists and is not readable: `unknown\t<path> is not readable`.
3. No parser (`command -v "${FELIX_JQ:-jq}"` fails):
   `unknown\tno JSON parser on this machine (jq); <path> was not read`.
4. The parser run is
   `jq -r 'if type == "object" then (if (try (.enabledPlugins["felix@felix"] == true) catch false) then "ok" else "felix-off \(try (.enabledPlugins["felix@felix"] | tojson) catch "null")" end) else "not-object" end' <path>`.
   - exit not 0: `invalid\t<path> does not parse as JSON: <first line of jq's stderr, tabs replaced>`;
   - exit 0 and output empty: `invalid\t<path> is empty`;
   - output `not-object`: `invalid\t<path> parses, and its top level is not an object`;
   - output `ok`: `ok\t<path> enables felix@felix`;
   - output `felix-off <v>`: `felix-off\t<path> does not enable felix@felix (enabledPlugins["felix@felix"] reads <v>)`,
     with `; a session-start hook is registered by hand` appended when the
     file's text contains `harness/hooks/session-start`;
   - any other output: `unknown\tthe parser answered something this check does not know`.
`ok` is printed only on output exactly `ok` from a parser that exited 0.
Fixtures (HOME set to a fixture, `CLAUDE_CONFIG_DIR` unset): no file
`missing`; `{"enabledPlugins":{"felix@felix":true}}` `ok`;
`{"enabledPlugins":{"felix@felix":false}}` `felix-off` with `reads false`;
`{}` `felix-off` with `reads null`; `{"enabledPlugins":` `invalid`; an empty
file `invalid`; `[]` `invalid`; `FELIX_JQ=/nonexistent` `unknown`; a stub
`jq` that exits 0 printing nothing `invalid`, never `ok`. With
`CLAUDE_CONFIG_DIR=<dir>` the detail names `<dir>/settings.json`. Tests that
need a real jq skip with `skip` when none is on PATH.

**P2. The settings line.** `felix pulse` prints `settings\t<value>\t<detail>`
from P1 on every run, after the backup lines and before the report lines.

**P3. Reach lines, from caches only.** `felix_pulse_report` calls
`felix_reach_report "$proj" "$home"` for each project it already visits,
after that project's discovery line. For a project with no plugin or mcp row
it prints nothing. Otherwise:
- no valid cache:
  `reach-unread\t<project>\t<n> declared plugin or mcp row(s) and no reach cache; the next session in its checkout reads one, or run felix stack --reach there`;
- a cache: one line per row whose state is `needs-auth`, `failed` or
  `not-listed`, in cache order,
  `unreachable\t<project>\t<declared name> <server> <state>`;
  one line when any row is `unknown`,
  `reach-unknown\t<project>\t<k> declared row(s) whose reach is not known: <declared names, space-separated, in cache order>`;
  and one line when the header epoch is 7 × 86,400 s or more in the past,
  `reach-stale\t<project>\tthe reach cache was read <d> days ago`.
- `connected` and `no-server` rows print nothing.
With the R4 rows cached for project `reachy`: exactly four `unreachable`
lines, in this order, `gh@m plugin:gh:gh failed`,
`cf@m plugin:cf:cf-api needs-auth`, `dd@m plugin:dd:mcp failed`,
`lost@m - not-listed`; one `reach-unknown` line naming `gone@m`; no
`reach-stale` line; and nothing for `ctx@m`, `cf-docs` or `quiet@m`. With
the header epoch set to now − 8 × 86,400 a `reach-stale` line reads
`read 8 days ago`.

**P4. The pulse runs no `claude` command.** With a logging `claude` stub
first on PATH, `felix pulse` leaves the stub's log empty. The comment above
`felix_reach_report`'s call (or in the pulse header) says why: the launchd job
runs `/bin/bash`, which holds Full Disk Access on this machine, and
`claude mcp list` starts every configured stdio server, some at floating
`npx …@latest` versions, so a daily unattended run would hand floating
third-party code full disk access; and the pulse's charter is no network
beyond the backup remote.

**P5. The record.** Each `felix pulse` run (not `--install` or
`--uninstall`) writes `$FELIX_HOME_DIR/state/pulse.status.tsv`: first line
`# ran <epoch>`, then every line the run printed after its `pulse\t<ISO>`
header (backup, settings, report), in order. Written to
`pulse.status.tsv.new.$$` and moved with `mv -f`. The printed lines and the
lines appended to `state/pulse.log` keep today's content and order, with the
settings line added (P2). The record is written even when the log append
fails. Observable: after a run, the file's first line matches
`^# ran [0-9]+$`, its epoch is within 5 s of the test's clock, and its second
line onward equals the run's stdout without the first line.

**P6. Honest header.** The `Duties, deliberately two` paragraph of
lib/pulse.sh is rewritten to name four duties and the record: backup (the
only one that writes outside `state/` or reaches a network, and only the
backup remote), report, settings, reach (the last three read and never act),
and the record (`state/pulse.status.tsv`, so a surface reads the last run
without parsing the log). It keeps the sentence that nothing here schedules
itself.

**P7. Exit status.** `felix pulse` still exits 0 for every report, whatever
the settings value or the reach lines say.

---

## 4. Part 3: `felix status`

**S1. Contract.** `felix status --tsv` prints exactly five lines, in this
order, and nothing else on stdout:

```
settings\t<state>\t<value>\t<detail>
schedule\t<state>\t<value>\t<detail>
pulse\t<state>\t<value>\t<detail>
reach\t<state>\t<value>\t<detail>
gate\t<state>\t<value>\t<detail>
```

`state` is `value`, `none` or `unknown`. When state is `none` or `unknown`,
value is `-`. Detail is never empty (`-` at least) and holds no tab or
newline. No header line. Consumers ignore rows they do not know, so a later
row is added at the end without breaking one. Exit 0 for any report.

**S2. Human form.** `felix status` prints the same five rows as
`printf '%-9s %-12s %s\n' <row> <shown> <detail>`, where shown is the value
when state is `value` and the state word otherwise. No header.

**S3. Usage.** Any argument other than a single `--tsv` puts
`usage: felix status [--tsv]` on stderr (through `die`, prefixed `felix: `),
nothing on stdout, and exits 2.
`felix status --help` prints the general usage and exits 0, through the
existing `--help` catch.

**S4. Read-only.** `felix status` writes nothing, takes no network, and never
runs `claude`, the suite, `felix gate`, `claude mcp list` or `felix cost`. It
exports `GIT_OPTIONAL_LOCKS=0` before any git command, so git refreshes no
index. Observable: touch a marker; run `felix status --tsv` from a governed
fixture checkout with a logging `claude` stub on PATH; then
`find <home>/state <memory root> <checkout> -newer <marker>` prints nothing
(the checkout's `.git` included) and the stub's log is empty.

**S5. settings row.** From `felix_settings_state`: value `ok`, `felix-off`,
`invalid` or `missing` with state `value`; `unknown` (no parser, unreadable,
an unrecognised answer) with state `unknown`. Detail is P1's.

**S6. schedule row.** In order:
1. `uname` is not `Darwin`: `unknown`, detail `no launchd on <uname>`.
2. `$HOME/Library/LaunchAgents/felix.pulse.plist` absent: `none`, detail
   `no felix.pulse agent; felix pulse --install schedules one`.
3. `launchctl` not on PATH, or `launchctl list` exits non-zero, or its first
   line is not `PID\tStatus\tLabel`: `unknown`, detail `launchctl could not answer`.
4. No line whose third tab field is exactly `felix.pulse`: value
   `not-loaded`, detail `the agent's plist exists and launchd has not loaded it`.
5. That line's second field (launchd's decoded last exit status):
   `0` gives value `loaded`, detail `last exit 0`; a positive `N` gives value
   `exit-N`, detail `loaded; the last run exited N`; a negative `-N` gives
   value `signal-N`, detail `loaded; the last run was stopped by signal N`;
   anything else gives `unknown`, detail `launchctl reported a status this check does not read: <field>`.
   When the first field is a number, `; running now, pid <n>` is appended to
   the detail.
One `launchctl list` call, read whole, matched with awk on the third field.
Stubs (`uname`, `launchctl` first on PATH, HOME a fixture holding or lacking
the plist): `-\t0\tfelix.pulse` gives `loaded`; `-\t126\tfelix.pulse` gives
`exit-126`; `-\t-9\tfelix.pulse` gives `signal-9`; a table without the label
gives `not-loaded`; a launchctl exiting 113 gives `unknown`; `UNAME_STUB=Linux`
gives `unknown` whatever else holds.

**S7. pulse row.**
- `none`, detail `the pulse has never run here`, when neither
  `$FELIX_HOME_DIR/state/pulse.log` nor `state/pulse.status.tsv` exists.
- `unknown`, detail `no Felix home resolved`, when the home is empty or not
  a directory.
- Otherwise `value`: value is `felix_pulse_backup_age`'s answer (whole days,
  or `never`), detail
  `days since memory reached its remote; last run <UTC YYYY-MM-DDTHH:MMZ>`
  from `pulse.status.tsv`'s epoch, or `...; last run not recorded` when that
  file is missing or its first line is not `# ran <digits>`.
After one `felix pulse` in a fixture with no memory repository: value
`never`, detail containing `last run 20`.

**S8. reach row.** For the project the cwd resolves to
(`felix_resolve_project "$PWD" "$FELIX_HOME_DIR"`):
- `none`, detail `this directory is not a governed checkout`, when it
  resolves to nothing;
- `none`, detail `<project> declares no plugin or mcp rows`, when it has
  none;
- `unknown`, detail `no reach cache for <project>; felix stack --reach reads one`,
  when it has no valid cache;
- otherwise `value`: value `<c>/<t>` with R11's counting, detail
  `unreachable: <labels>; <k> unknown; read <age> ago`, where labels are
  `<server> <state>` (the declared name when server is `-`) joined by `, `,
  the unreachable clause is `none unreachable` when there are none, the
  unknown clause is left out at zero, and age is `<h>h` under 48 hours and
  `<d>d` from there.
With the R4 rows cached: value `2/7`; detail starting `unreachable: plugin:gh:gh failed, plugin:cf:cf-api needs-auth, plugin:dd:mcp failed, lost@m not-listed; 1 unknown; read `.

**S9. gate row.** For the cwd's checkout (`felix_repo_root "$PWD"`) and
project:
- `none`, detail `this directory is not a governed checkout`, when no
  project resolves;
- from `felix_verify_current <root> <home> <proj>`: `current` gives value
  `current`, detail `-`; `red` gives value `red`, detail
  `the last gate run here was red`; `stale\t<reason>` gives value `stale`,
  detail `<reason>`; `none` gives value `none-run`, detail
  `no gate has run in this checkout`;
- anything else, or no output: `unknown`, detail `the receipt could not be read`.
Fixtures: no receipt `none-run`; a receipt written by `felix_verify_record`
with rc 1 for the current tree id `red`; a green receipt followed by an edit
to a tracked file `stale` with detail `the tree changed since the receipt`.

**S10. Speed.** No assertion times it. The implementer measures
`felix status --tsv` once on this machine in a governed checkout and puts the
number in the handoff section; the target is well under 2 s. The gate row is
the slow one, because a receipt matching the tree makes
`felix_verify_current` run the project's probes.

**S11. Discoverable.** The dispatcher gains `status) shift; cmd_status "$@" ;;`.
`usage()` gains, under `every day`,
`felix status [--tsv]     read-only: settings, the pulse schedule and last run, declared tools' reach, this checkout's gate`,
and its `felix stack` line becomes
`felix stack [plan|apply|reconcile|--reach [--tsv]] install what this project declares; reconcile reads the record; --reach asks whether declared servers connect`.
The header comment of `felix` gains matching lines. `0480`'s
`help covers every command that dispatches` stays green.

---

## 5. What the dashboard reads

The status surface is a Claude Code mod, built outside this repository. Its
contract with Felix is S1 and nothing else: it runs `felix status --tsv` on a
timer, shows each row's state and value, and ignores rows it does not know.
Weekly spend is not a row: `felix cost --tsv` takes about 20 s, so the mod
runs it on its own, slower timer. The mod never parses `pulse.log` or a
cache file; if it needs more than a row says, the row grows a detail or a
new row is added at the end.

---

## 6. Version and record

- `engine/.claude-plugin/plugin.json` `"version": "0.49.282"`. Read on
  2026-10-12: main 0.49.280; worktree `claude/secret-scan-quoted-reference`
  holds 0.49.281 (unpushed); every other worktree is at or below 0.49.280;
  open PR #425 carries 0.49.280 and #365, #360 older numbers. If another engine
  PR lands first, renumber.
- A pending handoff section, written through `felix handoff --section FILE`,
  headed `### 2026-10-12: declared tools' reach, the pulse's settings and reach lines, and felix status`,
  opening `**Engine 0.49.282**`, naming the three surfaces, the measured
  `felix status` time (S10), and what is not built (the mod).
- Assertions recorded with `tests/run --record-assertions`, which also writes
  `red.tsv`; the new names fail against main's engine there, which is the red.

---

## 7. Decisions taken where the brief left a choice

**D1. The spelling is `felix stack --reach`, first argument only.** A bare
`reach` would be a fourth verb beside `plan`, `apply` and `reconcile`, and the
three that exist all decide or propose something; this one only reads. Taking
it first, before the `stack.tsv` guard and the plan, keeps it to one `claude`
call. `--reach` elsewhere is refused because the parser today ignores unknown
arguments, so `felix stack apply --yes --reach` would otherwise install
while the person thought they were asking a question. Other unknown
arguments keep today's behaviour; tightening them all is a separate change.

**D2. Two new libs, not one.** `reach.sh` holds the read and the cache;
`status.sh` holds the settings and schedule checks and the five rows. The
settings check lives in `status.sh` because both the pulse and status call
it, and `pulse.sh` at 383 lines would pass 500 with it and the reach lines.
`pulse.sh` sources `reach.sh` and `status.sh` behind guards at load;
`status.sh` sources `pulse.sh`, `reach.sh` and `verify.sh` behind guards at
call time, the way `verify.sh` takes `epoch.sh`, so no load-time cycle exists.

**D3. One parsing rule, extracted.** `_felix_mcp_line_state` is the single
reading of a status phrase, and `_felix_mcp_connected` keeps its exact
verdicts through it, including "a matching line that says something
unrecognised counts as mounted". Reach maps that same `other` to `unknown`,
because reach reports and never decides.

**D4. The server column is the list's key.** `plugin:cf:cf-api`, not
`cf-api`: a plugin can ship several servers, and the key is the one string
that names exactly one.

**D5. Unread includes an empty stdout.** A real `claude mcp list` with nothing
configured prints a sentence; zero bytes with exit 0 is not an empty
configuration, and reading it as one would turn every declared server into
`not-listed`.

**D6. Declaring a server is read from three files, by key.** `.mcp.json`
counts when it holds `"command"` or `"url"` (every stdio server has the
first, every remote one the second), so an empty `{}` is no declaration;
`plugin.json` counts on `"mcpServers"` alone, because it may also carry an
author `"url"`.

**D7. Every declared row is read, dormant or not.** Capability says whether
a row should be installed, not whether a server connects. The consequence,
accepted: a dormant row that was never installed reads `unknown` (no
directory), and the pulse and status say so rather than read it as fine.

**D8. A plugin with no directory is `unknown`, bundled plugins included.** A
bundled (`@inline`) plugin has no directory anywhere, so whether it ships a
server is not known from disk; any server line it has is still read by R4.2
first.

**D9. One clock: the header epoch.** Every age (the 24-hour refresh, the
7-day stale line, the status age) is computed from `# read <epoch>`, not file
mtime, so a copied or touched file cannot look fresh.

**D10. A 30-minute stale lock is broken.** The discovery lock has no such
rule; a refresh killed by a signal leaves its lock forever and reach would
never refresh again. Thirty minutes is ten times the slowest list read
measured here.

**D11. No timeout on `claude mcp list`.** Nobody waits on the background
read; a person running `--reach` can interrupt it; the pulse never runs it.
macOS ships no `timeout` binary to bound it with.

**D12. The settings path honours `CLAUDE_CONFIG_DIR`.** `cost.sh`, `audit.sh`
and `inventory-host.sh` already do for transcripts, and Claude Code reads
settings from there when it is set. The launchd job has no such variable and
reads `~/.claude`, which is where a stock install keeps it. Only the user
settings file is read: project and local settings can also enable a plugin,
and this check does not claim to know about them.

**D13. `FELIX_JQ` names the parser.** The brief makes "no parser" a state,
and on macOS 15 and later `/usr/bin/jq` is always on PATH, so without a knob
the suite could never reach it. The launchd PATH is `/usr/bin:/bin:...`, and
`/usr/bin/jq` is there on this machine (jq 1.8.2 at both paths).

**D14. The schedule row reads launchctl's table, not its dictionary.**
`launchctl list felix.pulse` reports `LastExitStatus` as a raw wait status
(exit 1 is 256); the table's Status column is already decoded, negative for
a signal. One `launchctl list` call, matched on the exact label.

**D15. Pulse line kinds are new words.** `unreachable`, `reach-unknown`,
`reach-stale`, `reach-unread` and `settings`, so a reader of `pulse.log` that
keys on today's `due`, `unchecked`, `unknown` and `stale` (both of which are
already per-maintenance and per-discovery) reads nothing new into them.

**D16. The status values are bare words.** `exit-126`, `2/7`, `never`,
`none-run`: no spaces, so a consumer can split on tab and compare the value
without trimming.

**D17. The human form has no header.** Five labelled rows say what they are;
a test can then assert the human and TSV forms carry the same rows in the
same order.

---

## 8. Decisions taken in review

The adversarial review of this branch raised two blockers. The first changed the
design and is recorded here with the behaviours it changes (R1, R6, R9, R10,
R11, R13). The second was a mistaken variable and changed nothing. A security
review of the fix for the first then raised a third (D21).

**D18. `claude mcp list` is read from an empty directory, never the checkout.**
The brief asked for the checkout as the cwd, so a project-scoped `.mcp.json`
server would be listed. That instruction is withdrawn. `claude mcp list` starts
the servers it lists, and a project-scoped one is started once it is approved,
or auto-enabled by `enableAllProjectMcpServers`; the SessionStart refresh runs
at every session start of every governed project, including repositories the
founder opens for bounty work, where a hostile `.mcp.json` is the expected
case. The review measured that a server still pending approval is not started
(the probe's marker was never written), and that `npx -y ruflo@latest`, a
user-scoped server, is started in the checkout. So the first design was safe
only while Claude Code's approval state happened to hold; this change does not
rely on it, which is why it is defense in depth and not the fix for an observed
attack. Measured again with the real CLI (section 0): from an empty directory a
project-scoped server is not listed at all, and exporting `CLAUDE_PROJECT_DIR`
naming the checkout changes nothing, so no variable needs scrubbing; but it does
walk up from its cwd to a parent's `.mcp.json`, so an ancestor check (any
`.mcp.json` from the directory to `/` leaves the list unread) closes the case of
a TMPDIR inside a repository (a file planted in a shared parent afterwards is
what D21 closes). The directory is made with `mktemp -d` under TMPDIR with a
template, because a bare `mktemp -d` on macOS ignores TMPDIR (part 1000). It is never the checkout and
never `$HOME`, which is itself a repository on this machine, so a fallback to
either would defeat the point; when none can be made the list is unread. An
unset or relative TMPDIR used to read as `/tmp`; D21 removes that. It is removed
recursively after the command
returns, and only a path of the shape `/*/felix-reach.??????` that is not a
symlink, because `claude` may leave files in its cwd and an `rmdir` would
leave them in TMPDIR. A refresh killed by a signal (or a `--reach` interrupted
by Ctrl-C) leaves its empty directory in TMPDIR, which the OS clears; removing
it would take an EXIT trap in a function the CLI sources. Cost, accepted:
servers that exist only in a project's `.mcp.json`, or in a local-scope entry
of `~/.claude.json`, are not seen. `felix stack apply` installs plugins with
`--scope user`, so plugin rows are unaffected; a plugin a person enabled only
through a project's own settings would read `not-listed`, a known false alarm
that is not changed here.

**D19. An mcp row the empty-directory list does not name is `unknown`.** With
the checkout out of the picture, absence from the list no longer says the
server is missing: it may be project-scoped, which Felix does not start. Saying
`not-listed` (and so an `unreachable` pulse line) would claim a failure nobody
observed; `unknown` (a `reach-unknown` line) says what is true, with a detail
that names the reason. A plugin row keeps `not-listed`, because a plugin's
server is user-scoped and its absence from the list is an observation.

**D20. The CLI's home override is `FELIX_HOME`; `FELIX_HOME_DIR` is not one.**
The review ran `felix stack --reach` with `FELIX_HOME_DIR` set to a scratch
directory and the real home's `state/reach/felix.tsv` was written. That is not
a defect of the cache path: `felix` and every hook assign `FELIX_HOME_DIR` from
`felix_home` (lib/resolve.sh), which reads `FELIX_HOME`, then the
`~/.felix-home` pointer, then the engine's own tree, and the assignment is
unconditional, as it is on main. A scratch home is `FELIX_HOME=<dir>`, which the
suite exports for exactly that reason. Reproduced both ways in a fixture with a
fake `$HOME` whose pointer names a "real" home: with `FELIX_HOME_DIR=<scratch>`
the pointer's home received `state/reach/<project>.tsv`, `pulse.status.tsv` and
`pulse.log`, as every other state file does on main; with `FELIX_HOME=<scratch>`
the scratch home received all three and the pointer's home none. Nothing
changed in the engine. Part 1120 pins that the reach cache, the pulse record
and log, and the SessionStart refresh all land in the home the invocation
resolved, and shows `FELIX_HOME_DIR` alone is not an override. (Part 1100's
`_rx_env` sets both variables to one value, which is why its assertions could
not have told them apart.)

**D21. TMPDIR must be a private directory, and there is no `/tmp` fallback.**
Raised by the security review of the fix for D18 (MEDIUM, time of check to time
of use). That fix fell back to `/tmp` when `TMPDIR` was unset or relative, and
checked that no `.mcp.json` sat in any ancestor of the scratch directory.
`/tmp` is shared and world-writable; the sticky bit stops another user deleting
a file, not creating one. So between the check finding no `/tmp/.mcp.json` and
`claude mcp list` running, another local user could plant it, and the CLI,
which reads a parent's `.mcp.json` (section 0), would find it and, if its
server is approved or auto-enabled, start it as the user. No exploitation is
known; the exposure is a local, unprivileged one, and the refresh runs at every
session start. A check cannot close a race, so the fix removes
the shared place instead of re-checking it: `TMPDIR` is used only when it is
absolute, owned by the user, writable by neither group nor others, and every
ancestor up to `/` is owned by root or the user and writable by neither group
nor others (R13), tested on the physical path. Otherwise `claude` is not run and
the list is unread, which every consumer already reads as `unknown`. The
ancestor `.mcp.json` check is kept, for a private directory that sits under a
project. Cost, accepted: on a machine whose temporary directory is not private
(Linux with `TMPDIR` unset, or set under `/tmp`) reach reads nothing until
`TMPDIR` names a private directory, so the pulse says `reach-unread` there and
`felix stack --reach` says why. The founder's machine is macOS, where the
default passes; the cost lands on the Linux CI runner, whose suite fixtures
therefore live under a private base (part 1100) and whose `claude` is absent in
any case. The rule is the review's: remove the fallback, and run nothing
where there is no private `TMPDIR`. A private directory of Felix's own was not
built, and the ancestor rule is what fails closed on a parent someone else owns.

**Left as it was, and named.** Read for the third blocker's request, not
changed in this branch. Every path in the engine that runs `claude mcp list`:
this branch's two (R10, R11), now in a private empty directory; and one call in
`lib/stack.sh`, `_felix_load_state`, which `felix_stack_plan` and `felix
profile <name>` use, with the caller's cwd.
- The only **unattended** path that reaches it is commissioning. `hooks/session-start`
  calls `felix_commission_resume_bg`, which, when the project's `autonomy` file
  names `commission` and the stamp over `commissioning.tsv` is current, starts
  `felix commission` detached with the checkout root as its cwd. Its `stack`
  row evaluates `felix_stack_plan` there, so `claude mcp list` (and `claude
  plugin list`, `claude plugin marketplace list`) run in the checkout. Only
  `projects/felix` grants `commission` on this machine (`projects/elenchus`
  grants `tidy`), and `state/commission/felix.bg.log` records runs on
  2026-10-12 at 20:25, 21:52 and 22:44 UTC. Its `human_steps` row runs
  `felix_setup_status`, which runs a project's `setup.tsv` checks with `bash -c`
  in the checkout; three template checks (`github-mcp`, `supabase-auth`,
  `sentry`) are `claude mcp list | grep`, but `projects/felix` has no
  `setup.tsv`, so that row does not reach it under the one grant that exists.
- What makes that path matter for a hostile repository: a checkout's own
  `.felix` file names its project and wins over the remote (lib/resolve.sh).
  Measured read-only in a scratch repository whose `.felix` held `felix`:
  `felix which` answered `project: felix` and `governs:` that directory. Nothing
  in `cmd_commission`, `felix_commission_resume_bg` or
  `felix_autonomy_commission_current` asks whether the checkout is the
  project's own. So a repository that names itself `felix` would have a
  detached `felix commission` started in it at session start, which is the
  exposure this branch removed from reach. Not run end to end here, because
  that would run the commissioning rows; it is read from the code. It wants its
  own decision (run the `stack` row's read from a private empty directory too,
  or refuse to run commissioning in a checkout whose remote is not the
  project's).
- Attended, in the person's own shell: `felix commission`, `felix new` (which
  runs `cmd_commission`), `felix stack plan|apply`, `felix profile <name>` and
  `felix setup`.
- Not reaching it: the pulse, the Stop hook, the discovery refresh
  (`lib/discover.sh` runs no `claude mcp list`), `felix route` (lib/route.sh
  reads no live mount state), the gate and `felix status`.
