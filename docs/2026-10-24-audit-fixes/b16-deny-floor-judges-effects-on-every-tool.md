# Audit fix b16: the deny floor judges effects on every tool

Batch 16 of the 2026-10-24 audit register. Branch `claude/audit-b16-deny-floor-judges-effects-on-every-tool`, from
`origin/main` at 69b51a61. This batch hits a founder stop: the PreToolUse matcher, and deny rows 19 and 20 of
`projects/felix/deny.tsv`. It is built and tested in full, then opened as a draft labelled `needs-founder`, and only the
founder merges it.

Files it may change: `engine/hooks/hooks.json`, `.claude/settings.json`, `engine/harness/hooks/pre-tool`,
`engine/harness/lib/deny.sh`, `engine/harness/lib/table.sh`, `engine/harness/bin/schema-check`, `engine/harness/felix`
(the doctor's deny block only), `projects/felix/deny.tsv` (rows 19 and 20, plus comments), `README.md` (the deny-table
row), `engine/harness/tests/parts/0620-denial-refuses-what-a-command-changes-not-wh.sh` (its wiring check only, see
section 3), and the two new parts. These stay unchanged: `engine/harness/lib/deny-read.sh`, the rows of
`engine/harness/templates/schemas.tsv` (one sentence of comment may be added), every `risk.tsv`,
`engine/harness/lib/escape.sh` and `engine/harness/lib/classify.sh`.

Size limits. `engine/harness/felix` (6734 lines) must not get longer: the doctor's deny block is replaced by one call.
`lib/deny.sh` (430), `lib/table.sh` (243) and `hooks/pre-tool` (134) stay at 500 lines or fewer. No new lib file. The
pattern refusals go in `lib/table.sh` or `bin/schema-check`, because the count rows at `projects/felix/risk.tsv:47-48`
guard exactly those two files. Code in a new file would need a new risk row, and that is a founder stop this batch does
not ask for.

## 1. Defects

**C020.** The PreToolUse hook is bound to six tool names. So no deny row ever judges Claude Code's own Monitor tool, or
any MCP tool that runs a shell command, even though every one of them carries a `command` field. Scenario: a Monitor
command ends in `pkill -f "tail -n +3 -f $LOG"` (a real call, 2026-09-25, transcript
`carrier-session-review-0b56b5/5a5a9812`). As a Bash call the pattern-kill row refuses it. As a Monitor call it is
allowed, for three reasons, each enough alone: `hooks.json:5` never binds Monitor; `pre-tool:102-106` keeps only rows
that name the exact tool; and `_felix_deny_field` (`deny.sh:71-78`) reads Monitor's `file_path`, so the subject comes
back empty. Severity is disputed. Verifier 1 rates it low: the floor's stated posture is against carelessness, and
README:184 names the six tools honestly. Verifier 2 rates it high: the Monitor path lets through, with no adversary
involved, an unsafe action the floor claims to stop. This contract fixes it either way. Measured 2026-10-24: in Felix's
ledger (`~/.felix/memory/felix/ledger*.tsv`), 8,986 of 133,666 recorded tool calls (6.7%) are tools outside the six, 797
of them Monitor; of the 1,027 distinct Monitor and MCP terminal commands in this machine's transcripts, Felix's shipped
Bash rows match exactly one, the pattern kill above.

**C076.** Felix never compiles or checks a deny or risk pattern against the engine that will run it, so a row that can
never fire passes with nothing said. Scenario: a deny row is written with `(?i)rm -rf` or `\bgit push --force\b`. Under
bash 3.2 on macOS the first pattern fails to compile (status 2) and the second matches nothing (status 1). Either way
`_felix_deny_first` (`deny.sh:223`) skips the row. `felix doctor` (`felix:5082-5098`) reports over-broad rows only, so
it says nothing. A risk.tsv row whose pattern grep cannot compile (an unbalanced `(`) is skipped by `escape.sh:436` and
`classify.sh:115` in the same way, so a declared escape is quietly declared away. Following the verifier's correction:
BSD grep under `LC_ALL=C` does support `\b`, `\d`, `\s` and `(?i)`, so for risk.tsv the split between machines runs the
other way (GNU grep lacks `\d`); and no shipped deny or risk pattern is affected today (all 229 rows compile and are
portable, scanned 2026-10-24). Severity: low.

**C079.** Felix's own rows 19 and 20 refuse spellings, not effects. A careless force push or a commit that skips hooks,
written in an equivalent form, walks past them. Scenario: `git push -fu origin x`, `git push origin +x`, `git -C . push
--force origin x`, `git commit -n -m x` and `git commit -nm x` are all allowed today, while the rows' reasons say they
are refused. Rows 19 and 20 lack the global-option tolerance that rows 131-135 have, and do not read combined short
flags or a `+` refspec. Severity: low, after the verifier's correction: row 135 already protects main, commits on a PR
branch survive in the reflog, and this checkout installs no git hooks, so `-n` skips nothing here today.

## 2. Required behaviour

Conventions. A payload is one JSON object piped to the shipped hook `$FROOT/harness/hooks/pre-tool`, as `_pre` in
`tests/lib/deny-hook.sh` sends it: `{"tool_name":"<T>","tool_input":{...}}`, plus `"session_id"` and `"cwd"` where an
item says so, every string JSON-escaped. Unless an item says otherwise, the hook runs from a checkout bound to the
prelude's `widget` project by a `.felix` marker, and `$FROOT/projects/widget/deny.tsv` holds the item's rows, columns
separated by one tab. "Refused" means exit 2 with stderr holding the row's whole reason; "allowed" means exit 0 with
nothing on stderr.

Words. A **shell tool** is Bash, Monitor, or any tool whose name begins with `mcp__`. A tool's **field** is the one key
the floor reads from its `tool_input`: `command` for a shell tool, `notebook_path` for NotebookEdit, `url` for WebFetch,
and `file_path` for every other tool.

**B1. Every tool is delivered to the hook.** In `engine/hooks/hooks.json`, the PreToolUse array holds exactly one entry,
and that entry has no `matcher` key. That is the same shape PostToolUse already has, and the ledger shows PostToolUse
firing for Monitor and MCP tools. The entry's one hook still runs `"${CLAUDE_PLUGIN_ROOT}/harness/hooks/pre-tool"` with
`"async": false`. The other events, their order and the SessionStart matcher `startup|resume|clear|compact` do not
change.

**B2. Cloud sessions get the same binding.** In `.claude/settings.json`, the PreToolUse entry likewise has no `matcher`
key. Its command still starts with the `CLAUDE_CODE_REMOTE` guard and still runs `engine/harness/hooks/pre-tool`.

**B3. A Bash row judges the command of every shell tool.** A row whose tool column is `Bash` refuses a call from any
shell tool whose `command` matches it. The command is read the way a Bash command is read (`felix_deny_code`). The
refusal is the same as for Bash: exit 2, the same stderr text, the row's reason.

**B4. MCP tools follow B3.** This holds for `mcp__terminal__run_in_terminal`, `mcp__claude-flow__terminal_execute`, and
any other `mcp__*` tool whose input carries a `command` key.

**B5. The reading is Bash's reading.** A shell tool's command is read exactly as Bash's is: quoted data, comments and
here-document bodies are not commands; a `-c` script, an `eval` argument and text piped into a shell are; and a command
over 1,024 characters is read whole (the awk path in `felix_deny_subject`).

**B6. The tool column keeps its meaning.** A row naming a tool other than Bash judges calls to that tool only, read on
that tool's field. A row naming `Monitor` refuses a matching Monitor command and does not refuse the same text as Bash.
A row naming Edit still does not refuse a Write. A Bash row never judges another tool's `file_path`, `notebook_path`,
`url` or content.

**B7. Other first-party tools are not read as shell commands.** A first-party tool other than Bash and Monitor is never
read as a shell command, even when its input carries `command`. For example, StructuredOutput `{"command":"pkill -f x"}`
and an invented name `Fixturetool` are both allowed. A `"command"` that sits inside a JSON string, such as an Edit
`new_string` holding `{\"command\": ...}`, is never a key.

**B8. A call with nothing to read is cheap.** When a payload's `tool_input` carries no key named for that tool's field,
the hook exits 0 with no output before it resolves the project. In particular, it runs no `git`.
- Fixture: a project resolved by `remote_match` and not by a marker. That is a `projects/<name>/project.json` holding
  `{"name":"<name>","remote_match":"example.com/<name>"}` in the home, a deny table with a Bash row, and a repository
  whose origin is `https://example.com/<name>.git` with no `.felix`. Put a `git` shim first on PATH that appends its
  arguments to a log and then runs the real git.
- Expected: Glob `{"pattern":"**/*.sh","path":"."}`, an `mcp__fixture__navigate` call `{"url":"https://example.com"}`
  and Monitor `{"ws":{"url":"wss://example.com/s"},"description":"d","timeout_ms":1000}` each exit 0, with empty stderr
  and an empty shim log.
- In the same fixture, a Read `{"file_path":"x"}` still writes to the log (the project is resolved), and Bash `pkill -f
  x` is refused.

**B9. Rows scoped to the checkout.** For a row with scope `checkout` (`deny.sh:37-45`), a Monitor command is judged
where it acts, exactly as a Bash command is: by `felix_where_lifts`, starting at the payload's `cwd`. So the row is
passed over when the command acts only in a throwaway fixture, and stands in the governed checkout. For an `mcp__*`
shell tool, where the command runs cannot be told: the tool may carry its own `cwd`, or a server session's. So a scoped
row that matches stands. It refuses, and stderr holds `It stood although this row covers only the governed checkout:`
followed by a reason.

**B10. A refusal is recorded.** A refusal through any shell tool appends one line to `$FELIX_MEMORY/<project>/says.log`,
in the same format as a Bash refusal: field 2 is `denied`, and field 5 holds the command and the reason.

**B11. Fail-open stays fail-open.** Each of these allows, for any tool name: a payload that does not parse, a repository
nothing governs, a project with no `deny.tsv`, and a row whose pattern bash cannot compile (it is skipped, and later
rows still refuse).

**B12. README tells the truth.** The `README.md` row "The deny table" no longer begins "Before a Bash, Edit, Write,
Read, NotebookEdit or WebFetch call runs". It names Monitor and MCP tools. Replacement first sentence: "Before any tool
call runs, Felix matches its shell command (from Bash, Monitor or an MCP tool), or the file path or URL of an Edit,
Write, Read, NotebookEdit or WebFetch call, against the project's `deny.tsv` and refuses a match with its reason". The
rest of the row is kept: "spellings, not intent" stays.

**B13. schema-check refuses a deny pattern that does not compile.** For every `deny.tsv` in the tree, a row is: a line
that is not a comment, has a non-empty first field and a non-empty second field. If `[[ "" =~ $pattern ]]` under
`LC_ALL=C` returns 2 for that row's pattern, `bin/schema-check` prints `<path>:<line>\tpattern-uncompilable\t<why>` and
exits 1. `<path>` is relative to the worktree root, `<line>` is the file's 1-based line number, and `<why>` names the
engine (bash's `=~`) and says the hook skips the row. The refusal count in the summary line includes it.

**B14. schema-check refuses a deny pattern that is not portable.** A pattern is refused as
`<path>:<line>\tpattern-unportable\t<why>` (exit 1) when it holds an unescaped backslash followed by one of `s S d D w W
b B y < >` (unescaped: preceded by an even number of consecutive backslashes, zero included; this is the list
`lib/audit.sh:226` already refuses for `--verify`), or holds `[[:<:]]` or `[[:>:]]`. `<why>` names the escape it found
(for example `\b`) and gives the POSIX spelling to use: `[[:space:]]`, `[[:digit:]]`, `[[:alnum:]_]`, or
`([^[:alnum:]_]|$)`. Neither `(?` nor any other error that every engine rejects belongs on this list: B13 catches those.

**B15. These are portable.** `\.`, `\+`, `\(`, `\\d` (an escaped backslash followed by `d`), `\\[nrt]`, `(\\\\)*`,
`[[:space:]]` and every pattern in the shipped tables produce no `pattern-*` line.

**B16. risk.tsv gets the same two checks.** They apply to its pattern column (column 3), for rows of both kinds (`path`,
`content`). The compile check runs the pattern as the runners do, `LC_ALL=C grep -qE "<pattern>" <<<""`, and status 2
means it cannot compile. So `^src/(auth` is pattern-uncompilable, and `\d+\.sql$` and `[[:<:]]password` are
pattern-unportable.

**B17. Comments, blanks and empty patterns.** These checks never judge a comment line, a blank line, or a row with an
empty pattern, even when the comment holds `(?i)` or `\b`. A tree whose patterns are all clean still exits 0 with `every
one declared and every row accepted`.

**B18. The shipped tree passes.** schema-check run on this repository prints no `pattern-uncompilable` and no
`pattern-unportable` line.

**B19. felix doctor reports what the hook skips without saying so.** Run in a checkout of the project, `felix doctor`
prints one section for each of these that applies, each under a fixed header line:
- `deny rules whose pattern does not compile`: every row B13 would refuse, one line each, with tool and pattern.
- `deny rules that read differently on macOS and Linux`: every row B14 would refuse, with tool, pattern and escape.
- `deny rules naming a tool Felix reads no field of`: every row whose tool is none of Bash, Monitor, Edit, MultiEdit,
  Write, Read, NotebookEdit or WebFetch, and does not begin with `mcp__`. It holds the tool and the pattern. The footer
  says such a row is matched against `file_path`, so it refuses nothing when the tool has none, and that tool names are
  case-sensitive.
- When `deny.tsv` exists but cannot be read, a line holding the path and `could not be read`, saying what it refuses is
  not known. No other deny section is printed for it.
- When the shared pattern check cannot be loaded (for example `lib/table.sh` is missing), a line saying the deny
  patterns `could not be checked`. Doctor does not stay silent as though the patterns were clean.

The existing `deny rules too broad to enforce` section stays word for word. A table whose rows are all narrow,
compiling, portable and for known tools prints none of these headers. `felix doctor` exits 0 in every case. The check
that B13 and B14 use is one function, shared by schema-check and doctor and kept in `lib/table.sh`. The hook never calls
it.

**B20. The force-push row refuses its spellings.** With `projects/felix/deny.tsv` as shipped, copied whole into the
fixture project, each of these Bash commands is refused with the reason `force push drops commits, and Felix's history
is the audit trail`:
- `git push --force origin feat/x`, `git push -f origin feat/x` (as today)
- `git push -fu origin feat/x`, `git push -uf origin feat/x`, `git push -qf origin feat/x`, `git push -4f origin feat/x`
- `git push origin +feat/x`, `git push origin +HEAD:feat/x`, `git push origin feat/a +feat/b`
- `git -C . push --force origin feat/x`, `git -C /tmp/elsewhere push -f origin feat/x`, `git -c push.default=current
  push --force origin feat/x`, `git --no-pager push -f origin feat/x`
- `git  push --force origin feat/x` (two blanks), `git push origin feat/x --force`

**B21. The verify row refuses its spellings.** With the same table, each of these is refused with the reason
`--no-verify is how a gate stops being a gate. Fix the tree instead`:
- `git commit --no-verify -m x`, `git commit -m x --no-verify` (as today)
- `git commit -n -m x`, `git commit -nm x`, `git commit -anm x`, `git commit -m x -n`, `git commit -m "a b" -n`, `git
  commit -n`, `git commit --amend -n --no-edit`
- `git -C . commit --no-verify -m x`, `git -c user.name=t commit -n -m x`

**B22. Allowed under the shipped table.** With the same table, each of these is allowed (no row of the table refuses any
of them):
- `git push --force-with-lease origin feat/x` (pinned at 0610 case 19, and a choice, not a gap)
- `git push --force-with-lease=feat/x:abc123 origin feat/x`
- `git push --force-if-includes --force-with-lease origin feat/x`
- `git push -u origin feat/x`, `git push -n origin feat/x`, `git push -o ci.skip origin feat/x`, `git push --follow-tags
  origin feat/x`
- `git push origin feat/x+y`, `git push origin a:b`, `git stash push -f`
- `git commit -m "-n is fine"`, `git commit -mnote`, `git commit -sm x`, `git commit -v -m x`, `git commit --amend
  --no-edit`, `git commit -m "fix: git push --force here"`, `git log -n 3`

Rows 19 and 20 keep their reasons exactly as they are, and keep three columns (no scope).

Measured with the candidate rows of section 7 on 2026-10-24: over 7,493 distinct Bash and Monitor commands naming push
or commit in this machine's transcripts, they refuse 7 that today's rows allow, all force pushes to a PR branch (`-qf`
six times, `-uf` once); the commit row refuses the same 11 as today's; and over the 98 Bash payloads in parts 0600,
0610, 0620 and 0630, and the 59 case lines of 0620, every verdict is unchanged.

## 3. What must not change

- **Fail-open.** Each of these allows: a payload that does not parse, an ungoverned repository, no `deny.tsv`, a
  malformed row, an over-broad row, a pattern that does not compile. A broken table must never refuse every call
  (`deny.sh:20-35`). Pinned in `0600-what-to-do-next.sh`, "denial" and "denial past Bash".
- **Tool column and field.** A row naming Edit does not refuse a Write. Content is never matched. The first copy of the
  field wins over a later one. NotebookEdit is read on `notebook_path`. Pinned in `0600-what-to-do-next.sh`.
- **The Bash reading.** Every case in `0610-denial-reads-the-command-the-shell-runs.sh`, including case 19,
  `--force-with-lease is not --force`. Large payloads, in `0630-the-subject-of-a-large-payload.sh`. Locale, in
  `0998-continued.sh` E26.
- **Shipped tables and scoped rows.** Every 0 and 2 line, and every scoped case, in
  `0620-denial-refuses-what-a-command-changes-not-wh.sh`. Its wiring check (lines 143-147) wants each of Bash, Edit,
  Write, Read and NotebookEdit in the PreToolUse matcher, which a matcher-less entry fails as written. The builder
  changes that check only so that an entry with no `matcher` key counts as bound for every tool; the five names
  `PreToolUse is bound for $t` stay, so `tests/assertions.tsv` does not change, and on base the check still passes.
- **The pattern-kill row.** Every case in `1600-felix-refuses-a-pattern-kill-blind.sh`.
- **The rest of the hook path.** Unended last rows (`1020-readers-keep-the-unended-last-line-of-a-hand.sh`); where the
  session stands (`0204-hooks-stand-where-the-session-stands.sh`: the B8 early exit comes after the tool name is read
  and never skips `felix_hook_enter` for a payload that carries a subject); the caller's environment
  (`1510-no-caller-environment-changes-a-tool-s-output.sh`).
- **Hook wiring.** The SessionStart matcher (`0010-resolution.sh`); events and lifecycle coverage over `hooks.json`
  (`0480-the-one-line-git-cannot-reconstruct.sh`, `0410-an-answer-that-is-neither-yes-nor-no.sh`,
  `0430-hooks-events-reads-keys-not-strings.sh`); `engine/harness/templates/lifecycle.tsv` keeps PreToolUse `wired`.
- **Doctor.** `doctor names the rule that refuses everything` and `doctor is quiet when every rule is narrow` (0600).
  `doctor exits 0 despite drift` (0010).
- **schema-check.** Its fixture counts and kinds (`0730-schema-check-every-table-declared-every-row.sh`). The count rows
  still count at least 15 in `table.sh` and at least 5 `add "` in `schema-check` (0730:141-145). New refusals are
  printed through the same `add "$(printf '%s:%s\tpattern-...\t...'` shape, or as `\t<kind>\t` lines in `table.sh`, so
  those counts rise.
- **Locale.** Every new function that matches with `[[ =~ ]]` or sorts pins `LC_ALL=C`, as `_felix_deny_first` does (the
  L3 lint in `0996-continued.sh` names it and `felix_deny_overbroad`). The B13 compile check uses the hot path's locale,
  or doctor and the hook disagree on a byte that is not UTF-8 (2026-10-08).
- **Other rows and the refusal text.** Rows other than 19 and 20 in `projects/felix/deny.tsv`, and every row of
  `projects/elenchus/deny.tsv`, are unchanged; row 135 (no push to main) refuses what it refused; the stderr text
  ("Felix refused this command." / reason / "This is a rule in ...") and the `says.log` format are unchanged.
- **Machines.** Both bash 3.2 with BWK awk and bash 5 with gawk run every path. No associative arrays, no `case` inside
  `$( )`, digit brackets spelled `[0123456789]`.

## 4. Assertions

Every part runs alone: it builds its own fixtures and relies only on the prelude (`FROOT`, `TMP`, `REAL_HARNESS`,
`FELIX`, `MEM`, `_pre`, `_fx_cd`, `is`, `has`, `ok`, `bad`, `skip`). Every name is printed on every run. When a fixture
cannot be built, or a file is not beside the harness (`projects/felix/deny.tsv`, `README.md`, `.claude/settings.json`),
the assertion is a `skip` with the same name, never a pass. An exit that is neither 0 nor 2 is named in the failure.
`[control]` marks an assertion true both before and after the fix. Write the parts with the Write tool, not a Bash
here-document: this machine's ecc plugin hook refuses any Bash command whose text holds `--no-verify`.

### 1930, the floor on every tool (C020)

**Fixture T1.** The checkout bound to `widget`, whose `deny.tsv` holds the rows below. A4 to A19, A29 and A30 run
against it.

| tool | pattern | reason |
|---|---|---|
| `Bash` | `git push --force` | `force push drops commits` |
| `Bash` | `pkill -f` | `a pattern kill reaches other sessions` |
| `Monitor` | `sleep 600` | `a monitor must not sleep this long` |
| `Read` | `\.env$` | `reading a secret` |

- **A1 (B1).** In the shipped `hooks.json`, read from the line holding `"PreToolUse"` up to the line holding
  `"PostToolUse"`. The span has no `"matcher"`, and exactly one line holding `harness/hooks/pre-tool`.
- **A2 (B1) [control].** `hooks.json` still has each of PostToolUse, SubagentStop, SessionEnd, SessionStart,
  UserPromptSubmit, Stop and SubagentStart as a key, once each. The SessionStart matcher reads
  `startup|resume|clear|compact`.
- **A3 (B2).** In `.claude/settings.json`, read over the same span: no `"matcher"`, and the command holds both
  `CLAUDE_CODE_REMOTE` and `engine/harness/hooks/pre-tool`.
- **A4 (B3).** Monitor `{"command":"pkill -f x","description":"d","timeout_ms":1000}` is refused, and stderr has `a
  pattern kill reaches other sessions`.
- **A5 (B3).** Monitor `git push --force origin feat/x` is refused.
- **A6 (B3) [control].** Bash `pkill -f x` is refused.
- **A7 (B4).** `mcp__terminal__run_in_terminal` `{"command":"pkill -f x","title":"t"}` is refused.
- **A8 (B4).** `mcp__claude-flow__terminal_execute` `{"command":"git push --force origin feat/x","sessionId":"s1"}` is
  refused.
- **A9 (B4).** `mcp__fixture__shell` `{"command":"pkill -f x"}` is refused.
- **A10 (B5) [control].** Monitor `echo 'pkill -f x'` is allowed.
- **A11 (B5).** Monitor `bash -c 'pkill -f x'` is refused.
- **A12 (B5) [control].** Monitor `tail -f log | grep --line-buffered 'pkill -f x'` is allowed.
- **A13 (B5).** Monitor `echo <1,100 a's> ; pkill -f x` (a payload over 1,024 characters) is refused.
- **A14 (B6).** Monitor `sleep 600` is refused with `a monitor must not sleep this long`.
- **A15 (B6) [control].** Bash `sleep 600` is allowed.
- **A16 (B7) [control].** StructuredOutput `{"command":"pkill -f x"}` is allowed.
- **A17 (B7) [control].** `Fixturetool` `{"command":"pkill -f x"}` is allowed.
- **A18 (B7) [control].** `mcp__fixture__memory` `{"key":"k","value":"{\"command\": \"pkill -f x\"}"}` is allowed. Its
  only `command` sits inside a string, so it is not a key.
- **A19 (B6) [control].** Write `{"file_path":"/w/pkill -f x","content":"y"}` is allowed, and Read
  `{"file_path":"/w/.env"}` is refused.

**Fixture T2 (B8).** A home project `gizmo1930` resolved by `remote_match` `example.com/gizmo1930`, holding the row
`Bash<TAB>pkill -f<TAB>no pattern kills`. A repository with origin `https://example.com/gizmo1930.git` and no `.felix`.
A `git` shim in `$TMP/shim1930/git`, first on PATH, that appends `$*` to a log and then runs the git found before the
shim was added. The log is emptied before each call.
- **A20 (B8).** Glob `{"pattern":"**/*.sh","path":"."}` exits 0, with empty stderr and a log of 0 lines.
- **A21 (B8).** `mcp__fixture__navigate` `{"url":"https://example.com"}` exits 0, with a log of 0 lines.
- **A22 (B8).** Monitor `{"ws":{"url":"wss://example.com/s"},"description":"d","timeout_ms":1000}` exits 0, with a log
  of 0 lines.
- **A23 (B8) [control].** Read `{"file_path":"x"}` exits 0, and the log has at least 1 line, so the shim is on the path
  the hook takes.
- **A24 (B8) [control].** Bash `pkill -f x` is refused.

**Fixture T3 (B9).** Built as part 0620 builds its scoped fixture: a governed checkout `GOV` bound to `widget`, with an
origin, and a scratch clone `SCR/clone` under `$TMP`, which lies under the suite's TMPDIR (assert that, as 0620 does).
The table holds `Bash<TAB>git( +-[^ ]+( +[^ ]+)?)* +remote +(add|set-url|rename|remove|rm)( |$)<TAB>the remote is where
the person is<TAB>checkout`. The hook runs from `GOV`. The command is `git remote add up https://example.com/up.git`.
- **A25 (B9) [control].** Monitor, with `"cwd"` set to `SCR/clone`: allowed.
- **A26 (B9).** Monitor with no `"cwd"`, so the command starts in `GOV`: refused, and stderr has `the remote is where
  the person is`.
- **A27 (B9).** `mcp__terminal__run_in_terminal`, with `"cwd"` set to `SCR/clone`: refused, and stderr has `It stood
  although this row covers only the governed checkout`.
- **A28 (B9) [control].** Bash, with `"cwd"` set to `SCR/clone`: allowed.
- **A29 (B10).** After A4, `$MEM/widget/says.log` has one more line whose field 2 is `denied` and which holds `pkill -f
  x`.
- **A30 (B11) [control].** Each of these is allowed: Monitor `not json at all`; Monitor `pkill -f x` in a repository
  nothing governs; Monitor `pkill -f x` with `widget/deny.tsv` removed.
- **A31 (B12).** README.md's line beginning `| **The deny table** |` holds `Monitor`, and does not hold `Before a Bash,
  Edit, Write, Read, NotebookEdit or WebFetch call runs`.

### 1940, patterns and spellings (C076, C079)

**Fixture S1.** A git tree `$TMP/sc1940`, committed after each change, as 0730 does. Its
`engine/harness/templates/schemas.tsv` holds three rows: `schemas.tsv`, plus `deny.tsv` and `risk.tsv` copied verbatim
from the shipped schemas.tsv. It also holds `p/deny.tsv` and `p/risk.tsv` as each assertion says. schema-check is run as
`$REAL_HARNESS/bin/schema-check` from the tree.
- **A32 (B13).** `p/deny.tsv` line 2 is `Bash<TAB>(?i)rm -rf<TAB>no rm`. Expect rc 1 and a line beginning
  `p/deny.tsv:2<TAB>pattern-uncompilable<TAB>`.
- **A33 (B13).** A row with the pattern `git push (` gives `pattern-uncompilable` at its line.
- **A34 (B14).** Thirteen rows, one each for `\s`, `\S`, `\d`, `\D`, `\w`, `\W`, `\b`, `\B`, `\y`, `\<` and `\>` (each
  written `x\?y`, with `?` the escape letter), then `[[:<:]]x` and `x[[:>:]]`. Each line gives `pattern-unportable` at
  its line number, and its why holds the escape. One assertion per row. Do not assert that it is the only line: on
  glibc, `[[:<:]]` is also uncompilable.
- **A35 (B15) [control].** Rows with the patterns `\.felix(-home)?$`, `\+x`, `\(x`, `a\\d`,
  `(^|[^\\])(\\\\)*(\\[nrt])+`, `[[:space:]]+` and `git( +-[^ ]+)* +push` give no `pattern-` line naming their line
  numbers.
- **A36 (B16).** In `p/risk.tsv`, each at its line: `red<TAB>path<TAB>^src/(auth<TAB>auth` gives `pattern-uncompilable`;
  `red<TAB>path<TAB>\d+\.sql$<TAB>migrations` and `red<TAB>content<TAB>[[:<:]]password<TAB>secret` give
  `pattern-unportable`.
- **A37 (B16) [control].** `red<TAB>path<TAB>^db/migrations/<TAB>migrations` gives no `pattern-` line.
- **A38 (B17) [control].** With only clean rows in both tables: rc 0, and the output holds `every one declared and every
  row accepted`.
- **A39 (B17) [control].** Comment lines `# (?i) is not POSIX` and `# \b neither`, a blank line, and a deny row whose
  pattern cell is empty give no `pattern-` line naming their line numbers.
- **A40 (B18) [control].** schema-check run from `$REAL_HARNESS/../..`, a git worktree, prints no line holding
  `pattern-uncompilable` or `pattern-unportable`. Skip when that directory is not a git worktree.

**Fixture D1 (B19).** The checkout bound to `widget`, with `felix doctor` run as `$FELIX doctor` from it. The table
changes per assertion.
- **A41.** The row `Bash<TAB>(?i)rm -rf<TAB>x`: the output has `deny rules whose pattern does not compile` and `(?i)rm
  -rf`.
- **A42.** The row `Bash<TAB>\bgit push --force\b<TAB>x`: the output has `deny rules that read differently on macOS and
  Linux` and `\bgit push --force\b`.
- **A43.** The rows `bash<TAB>zz1943 push<TAB>x` and `Grep<TAB>zz1943\.env<TAB>x`: the output has `deny rules naming a
  tool Felix reads no field of`, a line holding both `bash` and `zz1943 push`, and a line holding both `Grep` and
  `zz1943\.env`.
- **A44 [control].** One narrow, distinct, portable row each for Bash, Monitor, Edit, MultiEdit, Write, Read,
  NotebookEdit, WebFetch and `mcp__terminal__run_in_terminal`. The output holds none of the three headers, nor `refuses
  everything it was asked about`.
- **A45 [control].** `felix doctor` exits 0 for each table in A41 to A44.
- **A46.** The A41 table, made unreadable with `chmod 000`: the output holds `could not be read` and the table's path,
  and does not hold `deny rules whose pattern does not compile`. Skip when the file is still readable after the chmod,
  as it is for root. Restore the mode afterwards.
- **A47.** `cp -R "$FROOT" "$TMP/froot1940"`, remove `$TMP/froot1940/harness/lib/table.sh`, and run
  `$TMP/froot1940/harness/felix doctor` with `FELIX_HOME=$TMP/froot1940` for that one call. The prelude exports
  `FELIX_HOME=$FROOT`, which is why it is overridden. Run it from a checkout bound to `widget`, with the A41 table in
  `$TMP/froot1940/projects/widget/deny.tsv`. The output holds `could not be checked`, and the exit is 0.
- **A48 (B11) [control].** The rows `Bash<TAB>(?i)rm -rf<TAB>x` and then `Bash<TAB>git push --force<TAB>force push drops
  commits`: the hook refuses Bash `git push --force origin feat/x` and allows Bash `rm -rf /tmp/x`.

**Fixture F1 (B20-B22).** Find `projects/felix/deny.tsv` beside the harness
(`$REAL_HARNESS/../../projects/felix/deny.tsv`). Copy it whole into `$FROOT/projects/widget/deny.tsv`. Its checkout is
`$TMP/spell1940-repo`, bound by marker. Each case is a Bash command, JSON-escaped.
- **A49 (B20).** One assertion per command in B20: refused, and stderr has `force push drops commits`. The first two are
  `[control]`.
- **A50 (B21).** One assertion per command in B21: refused, and stderr has `--no-verify is how a gate stops being a
  gate`. The first two are `[control]`.
- **A51 (B22) [control].** One assertion per command in B22: allowed.
- **A52 (B22) [control].** Exactly one non-comment row has a reason beginning `force push drops commits`, and exactly
  one has a reason beginning `--no-verify is how`. Each is a `Bash` row with exactly three tab-separated fields.

## 5. Parts

- `engine/harness/tests/parts/1930-deny-every-tool-blind.sh`: A1 to A31.
- `engine/harness/tests/parts/1940-deny-patterns-and-spellings-blind.sh`: A32 to A52.

Both are written blind, from this contract alone. They are run with `alone.sh <worktree> bwk|gawk
1930-deny-every-tool-blind.sh 1940-deny-patterns-and-spellings-blind.sh`.

Red before the fix: A1, A3, A4, A5, A7-A9, A11, A13, A14, A20-A22, A26, A27, A29, A31-A34, A36, A41-A43, A46, A47, and
the new spellings in A49 and A50. Everything marked `[control]`, and the first two cases of A49 and A50, is green both
before and after.

## 6. Out of scope

- **Interpreter arguments as code** (`python3 -c`, `perl -e`, `node -e`, `ruby -e`, `osascript -e`). This is the floor's
  documented limit: README:315-316 says the hooks "catch an agent that forgets, not one that's trying to get round
  them", README:335-336 that the table "refuses spellings, not intent", and `projects/felix/deny.tsv:104-107` and `:113`
  the same. Adding them to the run-its-argument set in `deny-read.sh` would not reach the inner command anyway: the
  reader is a shell reader, and a quoted span holding a blank inside Python source is data `_` to it. `deny-read.sh`
  does not change.
- **Grep and Glob read by Read rows.** No project has a Read row; Grep's `path` is often a directory, so a path row
  cannot see which files it reads; `cat .env` through Bash already passes a Read row; and the ledger records 0 Grep or
  Glob calls. A row naming Grep is now reported by doctor (B19).
- **First-party shell tools other than Bash and Monitor** (PowerShell, or a future tool). The engine runs under bash on
  macOS and Linux. A first-party tool is read as a shell command only by name, and a new one is added by name, as
  Monitor is here. Nothing reports such a tool while it is unmapped. That belongs to the self-diagnosis `blind` and
  `unreachable` states (`docs/2026-08-11-self-diagnosis-design.md:152-153`), which are not built.
- **A doctor list of installed tools that run shells.** This was in the fix sketch. Neither a hook nor doctor can read
  an MCP tool's schema, so whether a tool "runs a shell" cannot be decided from its name. The `mcp__*` `command` rule
  (B4) covers the shape that every observed shell tool shares.
- **MCP tools that write files by `path`.** Edit and Write rows do not judge them. No table names one.
- **Elenchus's force-push row** (`projects/elenchus/deny.tsv`). It has the same spelling gap. It is that project's
  table, and its change is that project's pull request.
- **Neighbouring spellings that are not equivalents of the named rows:** `git push --no-verify`, `git -c
  core.hooksPath=... commit`, abbreviated long options (`--no-verif`), `git push --mirror` and `git push --delete`. They
  are different commands or different effects, the defect does not name them, and this checkout installs no git hooks
  for a verify flag to skip.
- **Reading limits the new rows keep, asserted neither way.** `git commit -m "-n"` is refused: the reader keeps a quoted
  single word as its own text. `echo git push -f origin x` is refused, as it is today.
- **The runners' handling of a bad risk pattern** (grep's stderr reaching the caller at `escape.sh:436` and
  `classify.sh:115`), and the deny hook's fail-open skip, which `deny.sh:20-23` records as a choice. Once B13, B14 and
  B16 refuse such a row at the gate, it cannot land. The runner files are not in this batch.
- **Escapes beyond the `audit.sh:226` list** (`\A`, `\z`, `\Q`, `\p{...}`). None is in any shipped table. If one is ever
  needed, it belongs in a follow-up that widens both lists together.

### Not fixed: not a defect

- **C020's overclaim.** README:184 names exactly the six tools, and README:331-337 says the table refuses spellings, not
  intent. B12 updates README:184 because the fix changes what is true.
- **C020's refuse-then-reroute scenario.** Re-running a refused command through an MCP terminal on purpose is evasion,
  and README:315-316 disclaims evasion. Across the transcripts there is exactly one real `run_in_terminal` call (`npx
  vercel login`), and no refused command was ever re-run through one.
- **C076's claim that risk rows using `\b`, `\d` or `(?i)` never fire on macOS.** It is false. `LC_ALL=C /usr/bin/grep
  -qE '\bgit\b' <<<'a git b'` returns 0, and the verifier's `_felix_classify_pass` matched `\bauth\b`, `(?i)BILLING/`
  and `\d+\.sql`. The residual is real, and B16 handles it: an uncompilable risk pattern is skipped, and `\d` fails on
  GNU grep.
- **C076's "its tests pass on Linux CI".** No Felix command tests a project's deny rows, so there is no such mechanism.
- **C079's `--force-with-lease`.** Allowing it is a tested choice (0610 case 19), not a gap. B22 keeps it.

## 7. Founder PR

The whole batch is one pull request, a draft labelled `needs-founder`, because it changes four founder stops at once:
the PreToolUse matcher (`engine/hooks/hooks.json`, a red path at `projects/felix/risk.tsv:33`), its cloud copy
(`.claude/settings.json`, red at `:36`), `engine/harness/hooks/pre-tool` (red at `:25`), and two deny rows
(`projects/felix/deny.tsv` is in `FELIX_ESCAPE_TABLES`, and replacing a row is a verifier escape). `hooks.json`,
`pre-tool`, `deny.sh` and `felix` are also in `FELIX_TRUST_BASE` (`lib/land-table.sh:97`), so land-on-green will not
land it.

The exact changes:

```diff
--- a/engine/hooks/hooks.json
+++ b/engine/hooks/hooks.json
     "PreToolUse": [
       {
-        "matcher": "Bash|Edit|Write|Read|NotebookEdit|WebFetch",
         "hooks": [
--- a/.claude/settings.json
+++ b/.claude/settings.json
     "PreToolUse": [
       {
-        "matcher": "Bash|Edit|Write|Read|NotebookEdit|WebFetch",
         "hooks": [
```

`projects/felix/deny.tsv`, rows 19 and 20 replaced in place. Columns are tool, pattern and reason, separated by one tab.
The reasons are unchanged:

```
Bash	git( +-[^ ]+( +[^ ]+)?)* +push( +[^ ;&|]+)* +(--force|-[46dnquv]*f[^ ]*|\+[^ ]+)( |$)	force push drops commits, and Felix's history is the audit trail
Bash	git( +-[^ ]+( +[^ ]+)?)* +commit( +[^ ;&|]+)* +(--no-verify|-[aeiopqsvz]*n[^ ]*)( |$)	--no-verify is how a gate stops being a gate. Fix the tree instead
```

Add a comment above them saying: git's global options are tolerated, as in rows 131-135; a cluster of push's flags that
take no value (`-4 -6 -d -n -q -u -v`) may hold `-f`, and a `+` refspec is a force; a cluster of commit's flags that
take no value (`-a -e -i -o -p -q -s -v -z`) may hold `-n`, which is `--no-verify`; and `-o`, `-m` and the other flags
that take a value end a cluster, so `git commit -mnote` is a message and not `-n`. Both rows were probed on 2026-10-24
against the cases in B20-B22 and against the transcript corpus counted under B22.

After he merges:
1. Deploy by hand with `felix install` from the main checkout. The land tick does not deploy a merge it did not make.
2. Restart open sessions. A session started before the deploy keeps the old matcher.
3. Re-stamp the commission grant. `deny.tsv` is one of the tables the commission policy version hashes
   (`FELIX_COMMISSION_TABLES`, `lib/commission.sh:52`). So `felix commission`, then `felix autonomy --allow commission`,
   as #459 did after #455.

Nothing else in this batch needs him: no `.github/workflows` change; no risk or escape row, because the pattern refusals
live in files that `projects/felix/risk.tsv:47-48` already count; `engine/.claude-plugin/plugin.json` is not touched;
nothing is published.

## 8. Red

Run 2026-10-25 on base 69b51a61 plus the two blind parts, before any code changed: `alone.sh <worktree> bwk
1930-deny-every-tool-blind.sh 1940-deny-patterns-and-spellings-blind.sh` (macOS awk, bash 3.2). The two parts hold 105
assertions: **59 failed, 46 passed, 0 skipped.** The 59 are exactly the contract's red list in section 5: A1, A3, A4,
A5, A7, A8, A9, A11, A13, A14, A20, A21, A22, A26, A27, A29, A31, A32, A33, A34 (all thirteen rows), A36, A41, A42, A43,
A46, A47, and the 12 new force-push spellings of A49 and the 9 new commit spellings of A50. Each failed for the reason the
contract gives, not for a fixture fault: the six-name matcher never delivers Monitor or an `mcp__` tool (A4 to A14, A26 to
A29); the hook runs `git remote get-url origin` before it looks for a subject (A20 to A22); README row 184 still lists
six tools (A31); no pattern check exists in schema-check or doctor (A32 to A47); rows 19 and 20 are spellings (A49, A50).

The 46 that passed, and why each is not a defect in the part:
- **Controls, true before and after (16):** A2, A6, A15, A19, A23, A24, A28, T3 (the fixture's own check), A38 and A45
  (schema-check and doctor already say and exit as the contract wants on a clean table), A48 (a row bash cannot compile
  is skipped, fail-open), A52 (rows 19 and 20 are already one Bash row of three fields each), and the contract's
  `[control]` cases of A49 (`git push --force`, `git push -f`) and A50 (the two spellings with the long verify flag).
- **Already true on base, not marked a control (1):** A49 `git push origin feat/x --force`. Today's row 19 reads `--force`
  anywhere after `push`, so it was refused before; B20 keeps it.
- **Allowed today, because nothing could refuse them (17, all of A51):** the neighbours B22 keeps allowed. They pass on
  base since today's rows are narrower than the new ones; they become a test only once rows 19 and 20 widen, and they are
  what stops the widening from over-reaching.
- **Vacuous on base, meaningful after (12):** A10, A12, A16, A17, A18, A25 and the Monitor halves of A30 pass because the
  hook is never run for Monitor, StructuredOutput, Fixturetool or an `mcp__` tool, so "allowed" is true by absence and not
  by judgement; after B1 they check B5, B7 and B9. A35, A37, A39, A40 and A44 pass because schema-check and doctor print
  no `pattern-` line and no new header at all today; after B13 to B19 they check that the new checks do not over-refuse
  (A40 on the shipped tree).
