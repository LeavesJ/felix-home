# Audit fix batch b08, round 3: the cloud check's hook reader fails closed on escapes and repeated keys

Contract, 2026-10-28, for branch `claude/audit-b08-change-scoped-verification-and-receipt-f`
at c86c55c6 (the review round, section 9 of the batch contract); line numbers are for that
tree. It adds to `b08-change-scoped-verification-and-receipt-f.md` and changes none of its
clauses.

## 1. The finding

An automated security review of c86c55c6 found three parser differentials (medium) in the
awk JSON reader that commit put in `_cloud_check` (`projects/felix/gate.sh:599-678`). JSON
string escapes are not decoded: a key such as `matcher` written with a `\u` escape, or a
command written with `\/`, reads differently than it does to Claude Code's JSON parser. A
key repeated in one object also goes unnoticed, though Claude Code's parser keeps the last.
A session that edits `.claude/settings.json` could then get `cloud ok` from the gate while
Claude Code runs something else. The session holding the batch verified it and set round 3,
which must fail closed on both. The string scan skips every escape unread (line 644), and a
key is stored without asking whether its object already holds it (line 624).

### Reproduced on c86c55c6

A checkout built as part 1770 builds FC: this tree's gate.sh, its stubs, and copies of the
two hook files with one edited per case. The command was `bash projects/felix/gate.sh --quick`.
The right column is what jq 1.8.2 read from each edited file; `JSON.parse` (node 26.3.1)
read the same constructs (an escaped key, a repeated key, `\/`) the same way.

| | Edit | Gate today | A JSON parser reads |
|---|---|---|---|
| S1 | settings' PostToolUse group gains `"matc\u0068er": "Read",` | `cloud ok` | PostToolUse matcher `Read` |
| S2 | settings' pre-tool hook gains `"timeou\u0074": 1,` | `cloud ok` | pre-tool timeout `1` |
| S3 | settings' pre-tool hook gains, after its command, `"command": "[ \"$CLAUDE_CODE_REMOTE\" = true ] \|\| exit 0; true",` | `cloud ok` | pre-tool command `... exit 0; true` |
| S4 | settings' top object gains `,"hooks": {}` after its hooks | `cloud ok` | `hooks` is `{}` |
| S5 | settings gains `"PreToolUse": [],` after its PreToolUse | `cloud ok` | PreToolUse is `[]` |
| S6 | hooks.json gains a PreCompact group whose one-line hook's command is `"\"${CLAUDE_PLUGIN_ROOT}\/harness\/hooks\/pre-compact\""`; settings binds no PreCompact | `cloud ok` | the plugin binds PreCompact/pre-compact and settings does not (B28) |
| S7 | settings' PreToolUse keeps its matcher and gains `"matc\u0068er": "Read",` after it | `cloud ok` | PreToolUse matcher `Read` |

In every case the gate says `cloud ok` while the cloud session does something else. It
runs pre-tool, and every deny row, for fewer tools (S1, S7), or under a one-second timeout
(S2). It runs `true` in pre-tool's place (S3), or runs no hooks at all (S4, S5). Or it never
gets a hook the plugin runs locally (S6).

### What is real, and how round 3 narrows it

- **Escapes.** These are real for `\u` (S1, S2, S7) and `\/` (S6). "Any backslash escape" is
  not real as stated. Both of the tree's files hold `\"` in every command (36 in settings.json,
  16 in hooks.json, and no other escape), so refusing every escape would make the tree's own
  files unreadable, along with A23 and every real gate run. Nor can `\"` change a decision:
  no key the reader looks for holds `"` or `\`, the reader takes a matcher only when its
  value holds neither (B29), and both characters end the `[a-z-]+` hook name after
  `harness/hooks/`. Round 3 keeps `\"` and refuses every other escape.
- **Repeated keys.** These are real, but the reader does not keep the first value
  everywhere. For `matcher`, `async` and `timeout` it already keeps the last, as a parser
  does: give settings' PostToolUse `"matcher": "Read",` then `"matcher": "Bash",` and the
  reader and jq both read `Bash`. It differs from a parser in two places: a command naming `harness/hooks/`
  followed by one that does not (S3, where it keeps the first), and a key whose value is an
  object or array, repeated (S4, S5, where it reads both). Round 3 still refuses every
  repeated key, because which value counts is the parser's choice.
- **Who is misled.** Both files are red paths (risk.tsv rows 33 and 36), so a change to
  either reaches the founder, whose review the `cloud` line tells that the two agree.

## 2. Required behaviour

Terms. *The two files* are `engine/hooks/hooks.json` and `.claude/settings.json`, and
`<path>` is the name the gate prints for one of them today. *A string* is a key or a value
in double quotes. *An escape* is a backslash inside a string together with the character
after it. *The quote escape* is `\"`. *A round-3 fault* is a fault under B08R3-1 or
B08R3-3. In FC (part 1770's checkout, gate run with `--quick`), *cloud FAIL* means three
things together: the line `  cloud              FAIL`, the gate's last line
`gate: FAIL (cloud)`, and exit status 1. *The detail* is the line under the cloud line.
*The escape clause* is `unreadable: <path> (an escape other than \");` and *the repeat
clause* is `unreadable: <path> (a key repeated in one object);`.

**B08R3-1. Escapes other than the quote escape.** A file is unreadable if it holds a
backslash that does not begin a quote escape inside a string. That holds whatever the escape
decodes to and wherever it sits: in a key or a value, at any depth, in a field the check
compares or one it does not (`statusMessage`, `shell`, `type`, any other). It covers `\\`,
`\/`, `\b`, `\f`, `\n`, `\r`, `\t`, every `\u`, and a backslash outside any string. The
result is cloud FAIL with the escape clause in the detail. The check never prints
`cloud ok` for such a file, even when decoding would leave every binding equal
(`"Checking\u0020the gate"`).

**B08R3-2. The quote escape stays readable.** `\"` is read as today, in keys and values.
The tree's two files give `cloud ok`. A value not compared that gains more quote escapes
(`"statusMessage": "Checking \"the\" gate"`) still gives `cloud ok`, and a hook name
followed by `\"` reads as today.

**B08R3-3. Repeated keys.** A file is unreadable if one object holds two keys with the same
bytes. That holds whatever their values and whichever value a parser would keep, at any
depth, including objects the check otherwise skips. The result is cloud FAIL with the
repeat clause in the detail. It includes a repeated `matcher` whose last value equals the
plugin's, which reads `cloud ok` today. Keys in different objects never count: each hook
object's own `type` and `command` are not repeats, and neither is each group's own
`matcher` and `hooks`.

**B08R3-4. One clause per file, and no comparison over an unreadable file.** Each file gets
at most one `unreadable:` clause. It is the escape clause if B08R3-1 applies, else the
repeat clause if B08R3-3 does. Failing both, it is today's `unreadable: <path>;` if the file
is unreadable for a reason it is today. When either file has a round-3 fault, the binding
reader prints those clauses, hooks.json's first, and nothing else from the reader: no `bound
differently for the cloud:`, no `not bound for the cloud:`, no `no event-to-hook pairs`. A
round-3 clause is printed even when no binding could be read from its file. The guard-count
and toolbox clauses are read outside the binding reader and follow as today.

**B08R3-5. No other tool decides.** The check reads the two files with awk alone, as today
(projects/felix/CLAUDE.md, invariant 2). It runs no `jq`, `python3` or `node`, so the same
two files give the same cloud line whether or not those tools are on PATH.

**B08R3-6. Everything else as today.** When neither file has a round-3 fault, the cloud line
and its detail are byte for byte what c86c55c6 prints for those files. The check writes no
file.

## 3. What must not change

- **B26 to B31 and their assertions**: A23 to A28 and A61 to A68 in part 1770, as written.
  No fixture of theirs holds a repeated key or an escape other than `\"`, so each keeps its result.
- **The rest of the batch**: C003 (B1 to B12), C045 (B13 to B25), A1 to A33 in part 1770,
  part 1780, and section 7's split. Round 3 is C110, so it lands with the first pull
  request, on green.
- **Files.** The fix changes `projects/felix/gate.sh` only, inside `_cloud_check` and the
  comment above it, and the assertions go in part 1770. Round 3 does not touch
  `engine/harness/tests/receipt.sh` (risk row 45, the founder's pull request), `risk.tsv`
  or any other table, either hook file (red rows 33 and 36), or `.github/workflows`. It adds
  no column and no deny, escape or risk row.
- **Counts.** gate.sh keeps 26 or more lines matching `^[[:space:]]*(pass|fail|check) `
  (row 41). There are 26 today, and `pass cloud` and `fail cloud` stay as they are. Part
  1770's `ok|is|has|bad` count does not drop (row 42).
- **Length.** gate.sh ends at most 12 lines longer than its 704 at c86c55c6 (Decision 10).
- **Shells and awk**: bash 3.2 and 5, and BWK awk and gawk with no gawk-only builtin (part
  1497), under `LC_ALL=C` with digits spelled out in brackets. SUBSEP arrays are POSIX. gawk
  5.3 and later reads `\u` in an awk string constant as a Unicode escape, so any awk
  program in the gate or the part that must emit or match a backslash writes it as `\\`.

## 4. Assertions

Part 1770 gets a round-3 block after A68. It is written blind from this file, red first,
over FC as A23 is (`_b8c_case`). Each case starts from the tree's two files, edits one or
both with an awk program, commits, runs the gate with `--quick`, and reads the cloud line
and the detail. Each case also checks with `grep -cxF` that the edited file holds the
exact line the case names, so an edit that wrote something else fails as a fixture and
not as the rule. Every assertion not marked (control) gives `cloud ok`, or another detail,
on c86c55c6.

- **A69** (R3-1; S1) Settings' PostToolUse group gains `        "matc\u0068er": "Read",` as
  its first line inside the group: cloud FAIL, with the escape clause for settings.
- **A70** (R3-1; S2) Settings' pre-tool hook gains `            "timeou\u0074": 1,` after
  its command line: cloud FAIL, with the escape clause for settings.
- **A71** (R3-1, R3-4; S6) hooks.json gains, before `    "SubagentStart": [`, the line
  `    "PreCompact": [ { "hooks": [ { "type": "command", "command":
  "\"${CLAUDE_PLUGIN_ROOT}\/harness\/hooks\/pre-compact\"" } ] } ],`: cloud FAIL, with the
  escape clause for hooks.json, and no `not bound` in the detail.
- **A72** (R3-1, R3-4; S7) Settings' PreToolUse keeps its matcher line and gains
  `        "matc\u0068er": "Read",` after it: cloud FAIL, with the escape clause for settings
  and no repeat clause (the raw keys differ, so the escape rule is what catches it).
- **A73** (R3-1) Settings' Stop `statusMessage` is written `"Checking\u0020the gate"` (a
  parser reads the tree's own value): cloud FAIL, with the escape clause for settings.
- **A74** (R3-1) Settings' Stop `statusMessage` is written `"Checking the gate\\"`, a `\\`
  just before the closing quote: cloud FAIL, with the escape clause for settings.
- **A75** (R3-3; S3) Settings' pre-tool hook gains, after its command line,
  `            "command": "[ \"$CLAUDE_CODE_REMOTE\" = true ] || exit 0; true",`: cloud
  FAIL, with the repeat clause for settings.
- **A76** (R3-3; S4) Settings gains the line `  ,"hooks": {}` before its final `}`: cloud
  FAIL, with the repeat clause for settings.
- **A77** (R3-3; S5) Settings gains `    "PreToolUse": [],` before `    "PostToolUse": [`:
  cloud FAIL, with the repeat clause for settings.
- **A78** (R3-3) Settings' PreToolUse gains `        "matcher": "Read",` before its matcher
  line, so the last is still the plugin's: cloud FAIL, with the repeat clause for settings.
- **A79** (R3-4) A71's hooks.json with A75's settings: the detail holds the escape clause
  for hooks.json and then the repeat clause for settings, in that order.
- **A80** (R3-4) The hooks.json matcher widened as in A25, with A73's settings: cloud FAIL,
  with the escape clause for settings and no `bound differently`. Today's detail is A25's
  clause.
- **A81** (R3-4) Settings' line 2 is written `  "hook\u0073": {`: cloud FAIL, with the
  escape clause for settings and no `no event-to-hook pairs`. Today's detail is
  `unreadable: no event-to-hook pairs read from one of the two files`.
- **A82** (R3-2) Settings' Stop `statusMessage` is written `"Checking \"the\" gate"`:
  `cloud ok`. (control)
- **A83** (R3-2, R3-3) Both files gain, before `    "SubagentStart": [`, a PreCompact group
  with `"matcher": "auto"` and A64's one-line hook (in settings, with its guard): `cloud ok`.
  The quote escapes in a one-line hook are read, and `matcher`, `hooks`, `type` and
  `command` repeated across objects are not repeats. (control)
- **A84** (R3-5) Over A69 to A83, stubs for `jq`, `python3` and `node`, first on PATH,
  record no call. (control)

Expected red: A69 to A81 fail (13) and A82 to A84 pass (3, the controls); A1 to A68 stay
as they are. In a scratch FC under macOS awk on c86c55c6, every case from A69 to A83 was run
(A74's with two `\\` pairs), and each read as this predicts; A84 rests on gate.sh calling none
of the three today.

## 5. Decisions

1. **Keep `\"` and refuse every other escape**, rather than the finding's "any backslash
   escape". The tree's two files hold 52 quote escapes, so refusing them fails every gate
   run, and `\"` cannot change a decision the reader makes (section 1).
2. **Refuse `\\` too**, though it cannot change a decision either. Neither file uses it.
   Allowing it would mean reasoning about runs of backslashes inside one string. Refusing
   is loud and on the closed side, and a later need can widen the rule with a test.
3. **Refuse rather than decode.** Decoding `\u` in BWK awk means hand-written UTF-8 and
   surrogate pairs. A refusal is a few lines and cannot fail open. The consequence is
   accepted: a writer that emits `\/` or `\uXXXX` makes the cloud check fail until the
   file is written plainly. PHP's `json_encode` does that by default, and so does Python's
   `json.dump` for any non-ASCII character. The tree's files are written by hand.
4. **Repeated keys are refused at every depth**, not only for the keys the check reads.
   Which keys matter can only be known after keys are read correctly, and a file whose
   meaning depends on the parser's choice cannot be vouched for. The cost is a FAIL on a
   file that is already defective.
5. **No jq**, the finding's option. Invariant 2 of the constitution
   (projects/felix/CLAUDE.md:96) puts the enforcing path on bash and git only, and the
   gate's own comment reads toolbox names with sed for that reason. A check that ran only
   where jq is installed would give one tree two verdicts by machine, so a receipt would
   not mean one thing. Once escapes and repeated keys are refused, the raw text the awk
   reads equals what a parser decodes for every key and value the check compares, so jq
   adds nothing round 3 needs. B08R3-5 and A84 keep it out.
6. **The reason goes in the clause.** `unreadable: .claude/settings.json;` alone does not
   tell a session what to fix. An assertion that checked only `unreadable:` could also
   pass on a layout fault in its own fixture, so A69 to A81 name the reason.
7. **One clause per file, escape first.** Without decoding, an escaped key (S7) cannot be
   seen as a repeat, so the escape is the root cause, and one clause keeps the detail
   stable.
8. **Round-3 clauses suppress the comparisons and the no-pairs message.** A comparison over
   a file the check could not read is a guess, and the no-pairs text would hide the reason
   (A81).
9. **The assertions go in part 1770, not a new part.** FC and its helpers live in 1770. A
   new part needs a tests/run line, taking the driver from 499 lines to 500, its ceiling
   (part 1040), and would rebuild FC or borrow 1770's functions, which a lone `--part` run
   lacks. 1770 may pass 500 lines; part 1040's limit for a part is 1,000.
10. **gate.sh grows by at most 12 lines.** The rule is a few awk statements and one block
    in END. Anything larger is a rewrite of the reader, which round 3 does not ask for.
11. **Text that is not JSON is left out** (section 6): round 3's scope is the finding.

## 6. Found, not round 3's

These were reproduced on c86c55c6 in the same scratch FC. The first two do the same harm
the finding names: the gate reports bindings that Claude Code does not run.
- **Text that is not JSON.** Give the settings Stop hook's `statusMessage` line a trailing
  comma and the gate reads `cloud ok`, while jq and `JSON.parse` both reject the file
  (`JSON.parse`: `Expected double-quoted property name`). What Claude Code does with a settings file it
  cannot parse was not checked here. If it skips the file, the cloud runs no hooks under a
  `cloud ok`. The reader tokenises without a grammar, so it accepts trailing commas and bare
  words. A grammar check is a change of its own, with its own red: a value only where one is
  due, JSON's literal and number forms, and no raw control characters.
- **A command that names a hook without running it.** Write settings' pre-tool command as
  `[ \"$CLAUDE_CODE_REMOTE\" = true ] || exit 0; true # harness/hooks/pre-tool` and the gate
  reads `cloud ok`. B26 makes a binding any command that names `harness/hooks/<name>`, and
  the guard count is satisfied. No escape or repeated key is involved. Pinning each command's
  whole form changes B26's definition, and that is for the session holding the batch to
  decide.
- **gate.sh's length.** The batch's section 3 says `projects/felix/gate.sh` (652 lines) may
  not end longer than it began. c86c55c6 left it at 704, and round 3 does not restore it.
