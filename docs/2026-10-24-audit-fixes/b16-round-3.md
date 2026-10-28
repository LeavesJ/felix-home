# Audit fix b16, round 3: every command-carrying tool is judged with the Bash rows

Round 3 of batch 16 (`b16-deny-floor-judges-effects-on-every-tool.md`, "the batch contract"). Branch
`claude/audit-b16-deny-floor-judges-effects-on-every-tool`, at 2c532ed4 (the review round). Where this file and the
batch contract's sections 2, 4 or 9 disagree, this file wins. It may change `engine/harness/lib/deny.sh`,
`engine/harness/hooks/pre-tool`, the deny-table row of `README.md`, and
`engine/harness/tests/parts/1930-deny-every-tool-blind.sh`. Nothing else: no `.tsv` row or column, no `hooks.json`, no
`.claude/settings.json`, no `.github/workflows`.

## 1. The finding, and what is real

The commit security review of 2c532ed4 (HIGH, two findings): `FELIX_DENY_SHELL_TOOLS` (`deny.sh:77-78`) judges Bash rows
against Bash, Monitor, `mcp__terminal__run_in_terminal` and `mcp__claude-flow__terminal_execute` by exact name, and the
hook's early exit follows the same list (`pre-tool:124-130`). A plugin-prefixed or new terminal tool carrying a command is
not judged. Not a regression against `origin/main`, which judges a tool only when a row names it; against b16's own goal,
an instance, not the class.

**Reproduced 2026-10-28 on 2c532ed4.** A fixture home whose `widget/deny.tsv` holds `Bash<TAB>pkill -f<TAB>a pattern
kill reaches other sessions`, the hook run from a checkout marked `widget`, each payload
`{"tool_name":"<T>","tool_input":{"command":"pkill -f vitest"}}`. Bash, Monitor and the two named MCP terminals: exit 2,
the row's reason, one `denied` line each. `mcp__plugin_x__terminal_execute`, `mcp__desktop-commander__start_process` and
`mcp__shell__execute_command`: exit 0, empty stderr, nothing in `says.log`. The row scan finds no row naming the tool,
`_felix_deny_shell_tool` says no, and the hook exits 0; `felix_deny_match` (`deny.sh:361`) would also skip the Bash rows
for it. Real as stated.

The same probe found three places where the calls a predicate admits and the text the reader reads part, the same class:
- **(a)** The B8 early exit (`pre-tool:74-77`) knows only `"command":` and `"command" :`. Bash `{"command"  :  "pkill -f
  x"}` (two blanks) exits 0 before the project is resolved, though `felix_deny_subject` reads it (0630, "space round the
  colon").
- **(b)** `felix_deny_subject` takes the first appearance of the field's name even where it is a value.
  `mcp__terminal__run_in_terminal` `{"type":"command","command":"pkill -f x"}` reads the subject `command`, and exits 0.
- **(c)** A value that is not a string is read as the next string after it. With `mcp__x__named<TAB>pkill<TAB>named
  row`, `{"command":["pkill","-f","x"]}` is refused on the subject `pkill`, and `{"command":null,"note":"pkill"}` exits 0.

Severity of (a) to (c): low. Claude Code writes compact JSON, and of the 6,281 `mcp__` calls recorded in this machine's
transcripts (`rg` over `~/.claude/projects`, 2026-10-28) exactly one carries a `command` key (the one `run_in_terminal`
call), and none carries `cmd`, `script`, `argv` or `shell`. They are in this round because the finding asks for one
predicate, and these are where the predicate and the reading disagree.

## 2. Words (these replace the Words of section 2 and M1)

- **Key.** A payload holds the key `<name>` where the name stands between double quotes followed by any run of blanks
  (space, tab, CR, LF, or none) and then a colon. An appearance followed by anything else is a value, not a key. A
  `\"command\"` inside a JSON string is neither (A18).
- **Subject.** The value of the first key appearance of the tool's field (`command`, `notebook_path`, `url`, `file_path`,
  as in section 2), read as today. When that value does not begin with `"`, the call has no subject.
- **Named terminal.** `Bash`, `Monitor`, `mcp__terminal__run_in_terminal`, `mcp__claude-flow__terminal_execute`.
- **Not a shell.** `mcp__claude-flow__hooks_pre-command`, `mcp__claude-flow__hooks_post-command`,
  `mcp__plugin_vercel_vercel__run_session_command`.
- Both lists are exact, case-sensitive names, each held once, in `lib/deny.sh`.
- **Unknown** call: an `mcp__` tool on neither list whose payload holds a `command` key with a non-empty string subject.
  **Unread** call: such a tool whose first `command` key holds a value that is not a string (array, object, number,
  `true`, `false`, `null`). A first-party tool other than Bash and Monitor is neither: B7 stands.

## 3. Required behaviour

**B16R3-1. An unknown call is judged with the Bash rows.** A project needs no row naming the tool: a `Bash` row whose
pattern matches the subject, read as Bash's is (`felix_deny_code`, B5), refuses it with exit 2, the stderr text of a Bash
refusal and the row's reason. The tool's own rows still judge it as it stands (B6, A57). This replaces M1's "a Bash row
never judges any other `mcp__*` tool, whatever its input holds", and restates A9.

**B16R3-2. A refusal says why a Bash row judged the tool.** When a Bash row refuses an unknown call, its reason, on stderr
and in the `denied` line, gains one line: `Felix does not know whether <tool> runs its command on this machine; until it
does, the Bash rows judge that command as well.` with `<tool>` the call's tool name. No other refusal gains it: not a
named terminal's, and not one made by a row naming the tool.

**B16R3-3. Every unknown or unread call is reported.** In a governed project whose `deny.tsv` holds at least one `Bash`
row, each such call appends exactly one line to `$FELIX_MEMORY/<project>/says.log` through `felix_say`: field 2
`unknown-shell`, field 3 the payload's `session_id` (or `unknown`), field 4 the tool name, field 5 the subject (unknown)
or `its command is not a string, so no row could read it` (unread). This holds whatever the verdict; a refused call also
writes its `denied` line (B10), so it leaves two. An allowed call exits 0 with nothing on stderr. No `unknown-shell` line
is written for a named terminal, a tool that is not a shell, a first-party tool, a call with no `command` key, a project
whose table has no `Bash` row, a project with no `deny.tsv`, or a repository nothing governs (B11).

**B16R3-4. An unread call has no subject.** No row reads it, whichever tool the row names, so it is allowed, and it is
reported by B16R3-3. This changes B6 for a field that holds no string: a row naming the tool no longer reads the next
string after it. An empty string (`"command":""`) runs nothing: allowed, not reported.

**B16R3-5. The not-a-shell list exempts its three names only.** Their calls are judged by rows naming them (B6) and by no
`Bash` row (A53 to A58 stand). Any other spelling, a plugin prefix included
(`mcp__plugin_claude-flow_claude-flow__hooks_pre-command`, `mcp__vercel__run_session_command`), is an unknown call. A
`command` key nested at any depth counts (the Vercel tool's `requestBody.command`): the hook does not parse JSON, so
depth cannot be told, and it reads the first key.

**B16R3-6. Named terminals are unchanged.** Bash, Monitor and the two MCP terminals are judged as at 2c532ed4; their
refusals gain no line and they write no `unknown-shell` line. A plugin-prefixed spelling of a named terminal
(`mcp__plugin_terminal_terminal__run_in_terminal`) is not named: it is an unknown call.

**B16R3-7. The key is read as a key, for every tool.** The subject is the value of the first key appearance (section 2),
so a value that spells the field's name is passed over: `{"type":"command","command":"pkill -f x"}` is read as `pkill -f
x`, and Read `{"mode":"file_path","file_path":"/w/.env"}` as `/w/.env`. The B8 early exit lets a call go before the
project is resolved only when the payload holds no key appearance of the field, whatever blanks stand before the colon.

**B16R3-8. Size changes nothing, and costs nothing new.** A payload over 1,024 characters gets the same subject, class,
verdict and `says.log` lines as the same call under it (0630's rule, extended to the class). Over 1,024 characters, the
key, the class and the subject are found by case matching and the subject's one awk; no bash `${s#...}`, `${s%...}` or
`${s//...}` searches the payload for the field. Bash 3.2 took 3 s for one `${raw#*\"command\"}` over 50,000 characters
(measured 2026-10-28), and that cost grows with the square. A key written `"command":` or `"command" :` costs no process
the hook does not run today; any other spelling may cost one awk.

**B16R3-9. Scoped rows stand for an unknown call.** As for an MCP terminal (B9): where its command runs cannot be told, so
a matching `checkout` row refuses, its reason followed by the `It stood although this row covers only the governed
checkout:` line and then the B16R3-2 line.

**B16R3-10. One predicate.** One function in `lib/deny.sh` decides a call's class from its tool name and payload, and the
early exit (B8), whether a `Bash` row counts for the call (`pre-tool`'s row scan), the judgement in `felix_deny_match` and
the report all take their answer from it. `hooks/pre-tool` holds no `mcp__` outside its comments, and none of the five
MCP names of section 2 appears in any file under `engine/harness` but `lib/deny.sh` (tests aside).

**B16R3-11. README tells the truth.** The deny-table row's first sentence becomes: "Before any tool call runs, Felix
matches its shell command (from Bash, Monitor, or any MCP tool whose input carries a command, unless Felix knows that tool
does not run it on this machine), or the file path or URL of an Edit, Write, Read, NotebookEdit or WebFetch call, against
the project's `deny.tsv` and refuses a match with its reason". The rest of the row stays.

**B16R3-12. Size.** `lib/deny.sh` (496 lines at 2c532ed4), `hooks/pre-tool` (158) and part 1930 (369) each stay at 500
lines or fewer. Room in `lib/deny.sh` is made by shortening its comments, keeping each date and number they record, not
by a new file. The new assertions go in part 1930, so `tests/run` and `tests/groups.tsv` do not change.

## 4. What must not change

- Every clause of the batch contract not restated here: B1 to B3, B5 to B22, M2, and section 3 whole (fail-open, the
  tool column, the Bash reading, the shipped tables and scoped rows, the pattern-kill row, the hook path, the wiring,
  doctor, schema-check, locale, the refusal text and the `says.log` format, both machines).
- Every assertion of parts 1930 and 1940 but A9 and A59, which section 5 restates; every case of 0600, 0610, 0620, 0630,
  1600 and 0204. 0630's "the first occurrence of the field wins" still holds: its first occurrence is a key.
- `projects/felix/deny.tsv`, `projects/elenchus/deny.tsv`, every `risk.tsv`, `hooks.json`, `.claude/settings.json`,
  `lib/deny-read.sh`, `lib/table.sh`, `bin/schema-check` and `engine/harness/felix`: unchanged by this round.
- `says.log` keeps five fields; `unknown-shell` is a new value of field 2, which is free text (`felix_say`), not a column.
- New matching pins `LC_ALL=C`; bash 3.2 with BWK awk and bash 5 with gawk both run every path.

## 5. Assertions (part 1930, written blind from this file and the batch contract)

On fixture T1 unless named. "Adds" counts lines of `$MEM/widget/says.log` around the one call. The payloads of A9 and A63
to A70 carry `"session_id":"s1930r3"`. `<pad>` is 1,100 `a`s.
- **A9 (R3-1, restated).** `mcp__fixture__shell` `{"command":"pkill -f x"}` is refused; stderr has `a pattern kill
  reaches other sessions` and `Felix does not know whether mcp__fixture__shell runs its command on this machine`.
- **A63 (R3-1, R3-2).** `mcp__plugin_x__terminal_execute` `{"command":"pkill -f x"}` is refused, with the reason and the
  B16R3-2 line naming that tool.
- **A64 (R3-1).** `mcp__desktop-commander__start_process` `{"command":"git push --force origin feat/x","timeout_ms":1000}`
  is refused with `force push drops commits`.
- **A65 (R3-1, B5).** `mcp__shell__execute_command` `{"command":"bash -c 'pkill -f x'"}` is refused.
- **A66 (R3-6).** `mcp__plugin_terminal_terminal__run_in_terminal` `{"command":"pkill -f x","title":"t"}` is refused, and
  stderr names that tool in the B16R3-2 line.
- **A67 (R3-5).** One each: `mcp__plugin_claude-flow_claude-flow__hooks_pre-command` `{"command":"git push --force origin
  feat/x"}` is refused with the force-push reason; `mcp__vercel__run_session_command`
  `{"sessionId":"s","requestBody":{"command":"pkill -f x","args":[]}}` is refused with the pattern-kill reason.
- **A68 (R3-1, B5) [control].** `mcp__plugin_x__terminal_execute` `{"command":"echo 'pkill -f x'"}` is allowed.
- **A69 (R3-8).** `mcp__plugin_x__terminal_execute` `{"command":"echo <pad> ; pkill -f x"}` is refused.
- **A70 (R3-8).** `mcp__plugin_x__terminal_execute` `{"note":"<pad>","command":"pkill -f x"}` is refused.
- **A71 (R3-3).** A63 adds exactly two lines: one with field 2 `denied`, holding `pkill -f x` and `does not know whether
  mcp__plugin_x__terminal_execute`; one with field 2 `unknown-shell`, field 3 `s1930r3`, field 4
  `mcp__plugin_x__terminal_execute`, holding `pkill -f x`.
- **A72 (R3-3).** `mcp__plugin_x__terminal_execute` `{"command":"ls -la"}` exits 0 with empty stderr and adds exactly one
  line: field 2 `unknown-shell`, field 4 the tool, holding `ls -la`.
- **A73 (R3-4).** `mcp__fixture__exec` `{"command":["pkill","-f","x"]}` is allowed and adds exactly one line: field 2
  `unknown-shell`, field 4 `mcp__fixture__exec`, holding `not a string`.
- **A74 (R3-4).** One each, the same for `{"command":null}`, `{"command":42}` and `{"command":{"argv":"pkill -f x"}}`.
- **A75 (R3-4, B6).** With `mcp__fixture__assess<TAB>pkill<TAB>this tool is named by the row` and T1's pattern-kill row,
  `mcp__fixture__assess` `{"command":["pkill","-f","x"]}` is allowed and adds one `unknown-shell` line holding `not a
  string`.
- **A76 (R3-3, R3-6) [control].** No `unknown-shell` line is added by any of: Bash, Monitor,
  `mcp__terminal__run_in_terminal` and `mcp__claude-flow__terminal_execute` each running `ls`; the A53, A54 and A55
  payloads; StructuredOutput and `Fixturetool` `{"command":"pkill -f x"}`; the A18 payload; the A21 payload.
- **A77 (R3-3) [control].** `mcp__plugin_x__terminal_execute` `pkill -f x` is allowed and adds no line: with the table
  holding only T1's Read row; with `widget/deny.tsv` removed; from a repository nothing governs.
- **A78 (R3-7).** One each, refused: Bash `{"command"  :  "pkill -f x"}`; Bash with a tab between `"command"` and the
  colon; `mcp__plugin_x__terminal_execute` with a line break (a raw LF byte) between the key and the colon.
- **A79 (R3-7).** One each, refused: `mcp__terminal__run_in_terminal` `{"type":"command","command":"pkill -f x"}`;
  `mcp__plugin_x__terminal_execute` with the same input; Read `{"mode":"file_path","file_path":"/w/.env"}`, with
  `reading a secret`.
- **A80 (R3-7) [control].** On T2: `mcp__fixture__memory` `{"kind":"command","note":"x"}` exits 0 with empty stderr and a
  git log of 0 lines.
- **A81 (R3-8).** The A63, A73 and A79 (first) inputs, each with `"pad":"<pad>"` put first in `tool_input`, give the same
  verdict and add the same kinds of line as without it. One assertion each.
- **A82 (R3-8).** `mcp__plugin_x__terminal_execute` `{"note":"<300,000 a's>","command":"pkill -f x"}` is refused, and the
  children's user plus system time that bash's `times` reports for a subshell running only that call is under 20 s.
  CPU, not wall, because this machine's load sets the wall clock. A skip when `times` prints nothing parseable.
- **A83 (R3-9).** On T3: `mcp__plugin_x__terminal_execute`, with `"cwd"` set to `SCR/clone`, running `git remote add up
  https://example.com/up.git`, is refused; stderr has `the remote is where the person is`, `It stood although this row
  covers only the governed checkout` and `does not know whether mcp__plugin_x__terminal_execute`.
- **A84 (R3-10) [control].** `hooks/pre-tool`'s lines that do not begin (after blanks) with `#` hold no `mcp__`; under
  `engine/harness`, outside `tests/`, each of the five MCP names of section 2 occurs in exactly one file, `lib/deny.sh`.
- **A85 (R3-12) [control].** `lib/deny.sh`, `hooks/pre-tool` and part 1930 have 500 lines or fewer.
- **A86 (R3-2) [control].** A57's refusal (a row naming `mcp__fixture__assess`, no Bash row) holds no `does not know
  whether`.
- **A59 (R3-11, restated).** README's deny-table row holds `any MCP tool whose input carries a command` and not `an MCP
  terminal tool Felix names`.

Red on 2c532ed4: A9, A59, A63 to A67, A69 to A75, A78, A79, A81 to A83. Controls, true before and after: A68, A76, A77,
A80, A84 to A86 (A68 and the MCP halves of A76 are vacuous before: the hook never judges those calls), and every earlier
control. Run with `alone.sh <worktree> bwk 1930-deny-every-tool-blind.sh 1940-deny-patterns-and-spellings-blind.sh`, then
with `gawk`.

## 6. Decisions

- **Judge the unknown, list the exceptions.** M1's narrowing was right about three tools and wrong as a rule: a list of
  terminals is an instance, and every miss was a silent pass. Now a miss of the terminal list costs a report line, and a
  miss of the not-a-shell list costs a judgement; neither clears a call. Measured cost: 1 of 6,281 recorded MCP calls
  carries a command.
- **Exact names in both lists, no suffix match.** The not-a-shell list exempts. Matching `*__hooks_pre-command` would
  exempt another server's tool of that name that does run its command. Plugin spellings are added by name once seen.
- **Vercel's `run_session_command` is not a shell here.** Its schema says it runs "inside a running sandbox session", and
  its `requestBody.command` is "the program name without arguments", with `args` an array the floor never reads. Only the
  spelling observed on this machine is listed.
- **A nested `command` counts.** The hook does not parse JSON, so it cannot tell depth. Reading the first key at any
  depth is the closed direction.
- **An unread command is reported, not refused.** This is the one place this round does not fail closed, by choice.
  Refusing would refuse a call that no row matched, and no project's table could lift it, because the lists are engine
  code: the deny-by-accident that `pre-tool`'s header and B11 forbid. Joining an argv array into a command line was not
  built: no such call was ever seen here.
- **The report is a `says.log` line.** It is the hook's existing record (B10), and the monitor page shows `says` rows.
  Rejected: stderr on exit 0 (Claude Code does not hand it to the model, and "allowed" means empty stderr); exit 1 (a hook
  error on every call reads as a broken tool); JSON `permissionDecision: "ask"` (a protocol the hook never used, not
  verified across permission modes, and it stops an unattended agent). Not built: a doctor section summing the lines,
  since `lib/deny.sh` is at 496 of 500 lines.
- **Report only where a Bash row exists.** There the class changes a verdict; elsewhere the hook stays as silent as B11
  has it. One line per call, not one per session: deduplication would read `says.log` on every call.
- **The added line only on a Bash row's refusal.** A row naming the tool needs no explanation, so A57 keeps its text.
- **First-party tools stay out (B7).** Claude Code names them, and StructuredOutput's `command` is data.
- **The key reading is fixed for every tool.** The finding asks for one predicate, and a reader that takes a value for the
  key, or an early exit narrower than the reader, is that predicate split in two. The fix changes only payloads with a
  value spelling the field's name, a non-string field, or blanks other than none or one space before the colon; 0630's
  cases all stay.
- **The assertions go in 1930**, the part that owns C020, so neither the runner nor the groups change.
- **A82 measures CPU with a wide bound.** A linear reading costs well under 1 s; a quadratic one, by the 50,000-character
  measure, about 100 s at 300,000.

## 7. Out of scope

- A shell carried under another key (`cmd`, `script`, `argv`): the floor reads `command` only, as README says, and none
  of the 6,281 recorded MCP calls has one.
- A `command` key that is not the first: the first copy wins (section 3 of the batch contract); a later one is not read.
- Interpreter arguments, first-party shells other than Bash and Monitor, and a doctor list of installed tools:
  section 6 of the batch contract, unchanged.

## 8. Founder PR

No new founder stop. `lib/deny.sh` and `hooks/pre-tool` are red paths (`projects/felix/risk.tsv`, `^engine/harness/lib/`
and `^engine/harness/hooks/`) and in `FELIX_TRUST_BASE`, both already changed by this batch's draft. Part 1930 is a
yellow verifier path counted on assertion lines; this round restates two and adds the rest, so the count rises. The PR
description gains one paragraph: Bash rows judge every MCP tool that carries a command except three named ones, and an
unknown one is reported as `unknown-shell`. Section 7's steps after the merge are unchanged.

## 9. Review round

Three findings of the review of c8442a95 (the round-3 fix) and cc079dd2 (its assertions), judged against this file.
All three are accepted and none is rejected. A fourth defect, in the assertions, was found while writing these (R3V-4).
Where this section and sections 2 to 6 disagree, this section wins. Its assertions are in part 1931, named `B16R3V<n>`;
`[control]` means true at c8442a95 and after the fix.

**Finding 1 (high): part 1930 still asserts round 2's A9 and A59. Accepted.** Section 4 lets A9 and A59 go and section 5
restates them, but the restated forms were written into part 1931 (`B16R3 A9`, `B16R3 A59`) and 1930 kept round 2's.
Its A9 wants `mcp__fixture__shell` `{"command":"pkill -f x"}` allowed, which B16R3-1 refuses. Its A59 wants README's row
to hold `terminal`, which B16R3-11's sentence does not. So against any engine that meets this file both fail, on both
machines, and the gate cannot pass. The defect is in the assertions, not the engine.

**R3V-1. No part asserts what round 3 reverses.** Part 1930 holds no assertion named A9 or A59: both are taken out of
it. Their round-3 forms are part 1931's `B16R3 A9` and `B16R3 A59`, each there once. The engine is not asked to change.

**Finding 2 (medium): the assertions are in part 1931 and `tests/run` gained a line, against B16R3-12. Accepted, as a
defect of this file.** B16R3-12 puts the new assertions in part 1930, keeps `tests/run` unchanged, and holds 1930 to 500
lines. At 369 lines, 1930 could not also take round 3's 410-line part, so the two rules could not both hold and the move
was forced. The defect is that nothing recorded it, so the round read as done to a contract it did not follow.

**R3V-2. Round 3's assertions live in part 1931.** This replaces B16R3-12's last sentence, the heading of section 5 and
section 6's "The assertions go in 1930". Round 3's assertions (A9 and A59 restated, A63 to A86, and this section's) are
in `engine/harness/tests/parts/1931-b16-round-3-blind.sh`. `tests/run` gains exactly one line, sourcing it, directly
after the line that sources part 1930; with it, `tests/run` stands at 500 lines. `tests/groups.tsv` does not change, so
neither part is in a group. `lib/deny.sh`, `hooks/pre-tool`, part 1930 and part 1931 each stay at 500 lines or fewer:
A85 bounds the first three and B16R3V3 the fourth. Section 5's run becomes `alone.sh <worktree> bwk|gawk
1930-deny-every-tool-blind.sh 1931-b16-round-3-blind.sh 1940-deny-patterns-and-spellings-blind.sh`. The PR description
says round 3's assertions are in part 1931 and that 1930's A9 and A59 moved there in their round-3 form.

**Finding 3 (medium): a key whose name ends in an escaped quote and the field's name is read as the field's key.
Accepted.** Section 2's Key says a key is a name between double quotes followed by a colon; it does not say the opening
quote must be a real one. `{"a\"command":"ls","command":"pkill -f x"}` holds one key named `command`, whose value is
`pkill -f x`. But the reader takes the `"command":` at the end of the key `a"command` and reads `ls`, so the command
the tool runs is never judged. The reviewer reproduced this on c8442a95 for an unknown call, for the named terminal
`mcp__terminal__run_in_terminal` and for Read on `file_path`, under 1,024 characters and over; 2c532ed4 read it the same
way. No careless call writes such a key, so like section 1's (a) to (c) its severity is low. It belongs in this round
because it is where the predicate and the reading still part, which B16R3-7 and B16R3-10 exist to close.

**R3V-3. A key is opened by a real quote.** Section 2's Key gains one condition. An appearance of the name counts only
when the nearest character before its opening quote, blanks (space, tab, CR, LF) passed over, is `{` or `,`. Every key of
a JSON object starts that way. No quote that is escaped, or that ends another key's name or a string, is preceded so.
The one test is used for every tool and field and at every size (B16R3-8), by the class (`felix_deny_class`,
B16R3-10), by the B8 early exit and by the subject, so all four agree. Exactly:
- When an appearance of the field's name that fails the test stands before the real key, the subject is the real key's
  value. Bash, a named terminal and an unknown call with `{"a\"command":"ls","command":"pkill -f x"}` are judged on
  `pkill -f x`. On T1 each is refused, and the unknown call's refusal carries the B16R3-2 line, a `denied` line and an
  `unknown-shell` line holding `pkill -f x`. Read `{"a\"file_path":"/w/ok","file_path":"/w/.env"}` is judged on
  `/w/.env`. The same holds with a 1,100-character field put first.
- A payload whose only appearances of the field's name fail the test holds no key, just as A18's string holds none. The
  call has nothing to read (B8): it exits 0 before the project is resolved, with nothing on stderr and no
  `unknown-shell` line. This lets through nothing a row could have read, because the tool receives no key of that name.
  It is the closed reading for the call that matters: the key the tool will run is the one judged.
- A real key after blanks still counts, including one that follows a value ending in an escaped backslash
  (`{ "note":"C:\\",<LF> "command" : "pkill -f x"}`).
- B16R3-8's cost rule and section 7's first-copy rule stand: of two real keys, the first is read.

**R3V-4. A payload is sent as written (found while writing these).** Under bash 3.2, a double-quoted argument holding
`{`, a literal comma and `}` inside `"$(...)"` is brace-expanded: `f "$(g "{\"a\":1,\"b\":2}")"` gives `f` two
arguments, `"a":1` and `"b":2` (probed 2026-10-28 with /bin/bash 3.2.57; in an assignment it does not happen). A70's
payload and A81's padded payloads were written that way, so on macOS the hook got `tool_input` without its braces and
without its `command` key. Both of round 3's runs on c8442a95 (bwk and gawk, each under bash 3.2) fail A70 and the three
A81 checks for that reason, with the padded call "allowed" and nothing added. Each such payload is now built in a
variable first and then sent, which keeps the meaning section 5 gives it. No engine change follows from this.

Assertions (part 1931; T1 and T2 as in part 1931, the `<pad>` of section 5):
- **B16R3V1 (R3V-1).** Part 1930 holds no line with `deny floor A9 (` or `deny floor A59 (`. Part 1931 holds
  `"B16R3 A9 (` and `"B16R3 A59 (` on one line each.
- **B16R3V2 (R3V-2) [control].** `tests/run` sources part 1930 once and part 1931 once, on the next line, and
  `tests/groups.tsv` names neither part.
- **B16R3V3 (R3V-2) [control].** Part 1931 has 500 lines or fewer.
- **B16R3V4 (R3V-3).** Bash `{"a\"command":"ls","command":"pkill -f x"}` is refused with the pattern-kill reason.
- **B16R3V5 (R3V-3).** `mcp__terminal__run_in_terminal` with the same input is refused.
- **B16R3V6 (R3V-3, R3-2, R3-3).** `mcp__plugin_x__terminal_execute` with the same input is refused, with the B16R3-2
  line naming that tool. It adds exactly two lines: one `denied` line holding `pkill -f x`, and one `unknown-shell` line
  with field 3 `s1930r3` and field 4 the tool, holding `pkill -f x`.
- **B16R3V7 (R3V-3).** Read `{"a\"file_path":"/w/ok","file_path":"/w/.env"}` is refused with `reading a secret`.
- **B16R3V8, B16R3V9 (R3V-3, R3-8).** B16R3V6's and B16R3V7's inputs, with `"pad":"<pad>"` put first, are refused.
- **B16R3V10 (R3V-3) [control].** `mcp__plugin_x__terminal_execute` `{ "note":"C:\\",<LF> "command" : "pkill -f x"}`
  is refused.
- **B16R3V11 (R3V-3, R3-10).** `mcp__plugin_x__terminal_execute` `{"a\"command":"pkill -f x"}` exits 0 with empty
  stderr and adds no line.
- **B16R3V12 (R3V-3, B8).** On T2, after A80's Read probe shows the shim is on the hook's path,
  `mcp__fixture__memory` `{"a\"command":"pkill -f x"}` exits 0 with empty stderr and a git log of 0 lines.

Expected red on c8442a95 with these assertions: B16R3V4 to B16R3V9, B16R3V11 and B16R3V12. These hold there: B16R3V2,
B16R3V3 and B16R3V10, and B16R3V1 from this commit on, since R3V-1's change is made here, in part 1930. A70 and A81
should now pass on c8442a95 under bash 3.2 (R3V-4).
