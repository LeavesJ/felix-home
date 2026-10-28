# Audit fix batch b08, round 3: the cloud check's hook reader fails closed on escapes and repeated keys

Contract, 2026-10-28, for branch `claude/audit-b08-change-scoped-verification-and-receipt-f`
at c86c55c6 (the review round, section 9 of the batch contract); line numbers are for that
tree. It adds to `b08-change-scoped-verification-and-receipt-f.md` and changes none of its
clauses but one: section 7's review round narrows B26 (B08R3V-5).

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
  comment above it, and the assertions go in part 1771, a part of their own (B08R3V-1;
  this line first said part 1770). Round 3 does not touch
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

Part 1771 holds the round-3 block (planned as a block of part 1770 after A68; B08R3V-1
says why it is a part of its own). It is written blind from this file, red first, over
FC built as part 1770 builds it. Each case starts from the tree's two files, edits one or
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
9. **The assertions are in part 1771, a part of their own** (replaced; this decision first
   put them in part 1770). The workflow that wrote them made the part, so it runs alone
   under `--part`. The costs are recorded in B08R3V-1: the driver ends at 500 lines, part
   1040's ceiling, and the part rebuilds FC, so its builder must match part 1770's.
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

## 7. Review round

Five review findings against the round-3 fix (b6e9de57 and 8e634e4b), judged on
2026-10-28 by the blind assertion author against sections 1 to 6. All five are real: the
first because the contract and the tree disagreed, the other four because each shows
the harm round 3 is for (the gate says `cloud ok` while the cloud runs fewer hooks or
none) by a route these sections did not close. Claude Code's behaviour below is what the
reviewers measured on 2.1.296; it was not re-run here. The clauses add to sections 2 to
5; where one replaces a sentence there, it says so. Their assertions, A85 to A111, are
in part 1771 after A84, named `B08R3V A<n> (R3V-<m>...)`.

Terms as in section 2. In addition: *the size clause* is `unreadable: <path> (larger
than 65536 bytes);`, *the not-JSON clause* is `unreadable: <path> (not JSON);`, *the
top-level clause* is `unreadable: .claude/settings.json (a top-level key other than
hooks);` and *the schema clause* is `unreadable: .claude/settings.json (a key or value
outside the hook schema);`. *A review-round fault* is a fault under B08R3V-2 to B08R3V-5.

**Finding 1 (medium): the assertions sat in a new part 1771 with a driver line, where
§3, §4 and Decision 9 put them in part 1770, and 1771's copy of the FC builder had
drifted.** Real: three sentences said part 1770 and the tree said 1771. Its
`_b83_mk` and `_b83_git` committed without `-c core.hooksPath=/dev/null`, which part
1770's `_b8c_mk` and `_b8c_git` pass, so a global `core.hooksPath` ran its hooks on
every FC commit, unbounded. Resolved by amending the contract to the tree (the
finding's second option), not by moving the block: the workflow made the part and runs
it alone, and a move would rebuild 280 lines inside a 467-line part.

**B08R3V-1. The part and its fixture.** Round 3's assertions and the review round's are
in `engine/harness/tests/parts/1771-b08-round-3-blind.sh`, sourced by its own
`tests/run` line after 1770's. That replaces §3's "the assertions go in part 1770", §4's
first sentence and Decision 9, each now amended in place. The driver ends at 500 lines,
part 1040's ceiling, so after this branch lands any part line on another branch needs
room made first (b00-driver-room); every in-flight audit branch adds two or three driver
lines, so that is owed with or without this one. Part 1771 builds FC as part 1770 does,
and every git commit it makes in an FC checkout, the first one in its builder and each
case's, passes `-c core.hooksPath=/dev/null` as 1770's do. A hook named by a global
`core.hooksPath` never runs there. Fixed in the part in the same commit as this section.

**Finding 5 (medium): a settings.json over 2 MiB is not read by Claude Code, and the
gate read it and said `cloud ok`.** Real; the contract set no size. Claude Code read no
hooks from a settings file of 2,098,408 bytes and read them from one of 2,096,360.

**B08R3V-2. Size.** Either file longer than 65536 bytes is unreadable, whatever it
holds, and nothing else is read from it: cloud FAIL with the size clause. A file of
exactly 65536 bytes is read as any other. 65536 is far under Claude Code's 2 MiB and
over twenty times the tree's settings.json (3,050 bytes).

**Finding 2 (high): `"disableAllHooks": true` in settings.json turns off every hook, and
the gate said `cloud ok`.** Real; the contract was silent on keys outside `hooks`.

**Finding 3 (high): a value of the wrong type anywhere in settings.json, or text that is
not JSON, makes Claude Code skip the whole file, and the gate said `cloud ok`.** Real.
It also answers section 6's open question: Claude Code ran no hooks from a settings file
with a `//` comment or a trailing comma, so the file Decision 11 left out runs nothing
in the cloud under `cloud ok`. Decision 11 is withdrawn. The finding's other option,
narrowing what the cloud line claims, is not taken: the cloud would still run no hooks,
and nothing would say so.

**B08R3V-3. Not JSON.** Either file is unreadable when it is not one JSON text (RFC
8259): one value, with nothing but JSON whitespace (space, tab, line feed, carriage
return) around it and between its tokens. Among the forms that are not JSON: a comment
(`//` or `/* */`) outside a string; a comma before `}` or `]`, a missing comma, or two
in a row; a bare word other than `true`, `false` and `null`; a number not in JSON's form
(a leading zero as in `0120`, a leading `+`, `.5`, `1.`); a string in single quotes; a
raw control character (a byte from 0x00 to 0x1F, a tab included) inside a string; an
unterminated string; a bracket left open or closed twice; anything after the value; an
empty file. The result is cloud FAIL with the not-JSON clause. Escapes are B08R3-1's,
checked first, so this rule sees no backslash but the quote escape.

**B08R3V-4. Settings' top level.** `.claude/settings.json`'s top-level object holds no
key but `hooks`. Any other top-level key, whatever its name or value
(`disableAllHooks`, `allowManagedHooksOnly`, `model`, `permissions`, `env`, `$schema`,
any other, and a value Claude Code accepts as much as one it rejects), makes the file
unreadable: cloud FAIL with the top-level clause. An allowlist, not a list of keys known
to be harmful: the gate cannot know every key a later Claude Code reads, and a key it
needs can be allowed later with a test.

**Finding 4 (medium): a value Claude Code rejects in a field the check does not compare
(`"shell": "zsh"`, `"statusMessage": 5`, `"type": "prompt"`) drops that hook, pre-tool
and every deny row with it, and the gate said `cloud ok`.** Real, though B26 says `ok`
"when only a statusMessage, shell or type differs". That allowance rests on the batch
contract's section 6 ("neither is the deny path"), and the reviewers' probe shows it is
false for a value Claude Code rejects: the hook is dropped and its sibling still runs.
The finding's "shell must match the plugin's" is taken as "absent or `bash`", because
B26 leaves `shell` uncompared and the plugin's file need not carry one.

**B08R3V-5. Settings' hook schema.** `.claude/settings.json` is unreadable unless all of
these hold. (a) Its top-level value is an object, and the value of `hooks` is an object.
(b) Every value in that object is an array, and every element of such an array is an
object (a group). (c) A group's keys are among `matcher` and `hooks`; it has `hooks`;
`matcher`'s value is a string; `hooks`' value is an array whose every element is an
object (a hook object). (d) A hook object's keys are among `type`, `command`, `shell`,
`async`, `timeout` and `statusMessage`; it has `type` and `command`; `type`'s value is
the string `command`; `command`'s is a string; `shell`'s, when present, is the string
`bash`; `async`'s, when present, is `true` or `false`; `timeout`'s, when present, is a
number written in digits alone; `statusMessage`'s, when present, is a string. A file
that fails any of them gives cloud FAIL with the schema clause. This narrows B26, the
one batch clause the review round changes: a `statusMessage` that is another string,
and a `shell` absent from one file and `bash` in the other, still read `cloud ok`; a
value Claude Code rejects does not; and settings' `type` is always `command`. Event
names are not checked, and the plugin's hooks.json is not held to this schema (see
below).

**B08R3V-6. One clause per file, in order.** This replaces B08R3-4's second sentence. A
file's one `unreadable:` clause is the first that applies of: the size clause
(B08R3V-2), the escape clause (B08R3-1), the not-JSON clause (B08R3V-3), the repeat
clause (B08R3-3), the top-level clause (B08R3V-4), the schema clause (B08R3V-5), then
today's `unreadable: <path>;`. A review-round fault counts as a round-3 fault for the
rest of B08R3-4: when either file has one, the binding reader prints the clauses,
hooks.json's first, and nothing else (no `bound differently for the cloud:`, no `not
bound for the cloud:`, no `no event-to-hook pairs`). The guard-count and toolbox clauses
follow as today. Every fixture of A69 to A84 is JSON, under 65536 bytes and inside the
schema, so each keeps its result.

**B08R3V-7. Everything else.** B08R3-5 holds for these rules too: size, grammar and
schema are read without `jq`, `python3` or `node`. B08R3-6 now reads: when neither file
has a fault under B08R3-1, B08R3-3 or B08R3V-2 to B08R3V-5, the cloud line and its
detail are what c86c55c6 prints. The tree's two files, and every fixture of A23 to A28
and A61 to A68, are JSON, small and inside the schema, so part 1770 keeps its results.
Decision 10 is replaced: gate.sh ends at most 80 lines longer than at 8e634e4b. Every
other line of section 3 stands.

### Assertions (part 1771, after A84; FC as for A69)

Each case starts from the tree's two files, edits one or both, checks the edit as round
3's cases do (`grep -cxF` for a named line, `wc -c` for a size), commits and runs the
gate with `--quick`. *Padded to N* means blank lines put after the file's first line
until it is N bytes long.

- **A85** (R3V-1; finding 1) A global `core.hooksPath` (through `GIT_CONFIG_GLOBAL`)
  names hooks that record each run, and a plain commit in a scratch repository runs
  them. FC built by the part's builder, then one commit through the part's case helper:
  both commits are made and no hook ran. (control: fixed in the part with this section)
- **A86** (R3V-2; finding 5) Settings padded to 65,537 bytes: cloud FAIL, with the size
  clause for settings.
- **A87** (R3V-2; finding 5) Settings with 2,100,000 newlines after its first line (the
  reviewers' file, over 2 MiB): cloud FAIL, with the size clause for settings.
- **A88** (R3V-2) Settings padded to exactly 65,536 bytes: `cloud ok`. (control)
- **A89** (R3V-2) hooks.json padded to 65,537 bytes: cloud FAIL, with the size clause
  for hooks.json.
- **A90** (R3V-4; finding 2) Settings gains `  "disableAllHooks": true,` after its first
  line: cloud FAIL, with the top-level clause.
- **A91** (R3V-4; finding 2) The same with `  "allowManagedHooksOnly": true,`.
- **A92** (R3V-4; finding 3) The same with `  "model": 5,`.
- **A93** (R3V-4) The same with `  "env": {},`, a key Claude Code accepts.
- **A94** (R3V-3; finding 3, section 6) Settings' Stop `statusMessage` line gains a
  trailing comma: cloud FAIL, with the not-JSON clause for settings.
- **A95** (R3V-3; finding 3) Settings gains `  // the cloud's hooks` after its first
  line: the same.
- **A96** (R3V-3) The Stop hook's `"shell": "bash",` loses its comma: the same.
- **A97** (R3V-3) The provision hook's `"timeout": 120` is written `"timeout": 0120`
  (digits, so B29's layout holds): the same.
- **A98** (R3V-3) Settings' Stop `statusMessage` holds a raw tab between `Checking` and
  `the`: the same.
- **A99** (R3V-3) hooks.json gains `    // the subagent hooks` before
  `    "SubagentStart": [`: cloud FAIL, with the not-JSON clause for hooks.json.
- **A100** (R3V-5; finding 4a) Settings' pre-tool `"shell": "bash",` becomes
  `"shell": "zsh",`: cloud FAIL, with the schema clause.
- **A101** (R3V-5; finding 4b) Settings' pre-tool hook gains
  `            "statusMessage": 5,` after its command line: the same.
- **A102** (R3V-5; finding 4c) Settings' first `"type": "command",` (pre-tool's) becomes
  `"type": "prompt", "prompt": "ok",`: the same.
- **A103** (R3V-5) Settings' pre-tool hook gains `            "once": true,` after its
  command line: the same.
- **A104** (R3V-5) Settings' PreToolUse group gains `        "description": "the deny
  path",` before its matcher line: the same.
- **A105** (R3V-5) Settings' pre-tool hook loses its `"shell": "bash",` line: `cloud ok`.
  (control: B26's allowance that stands)
- **A106** (R3V-5) Settings gains `    "Notification": {},` before
  `    "SubagentStart": [`: cloud FAIL, with the schema clause.
- **A107** (R3V-6) A90's settings with A94's trailing comma: cloud FAIL, the not-JSON
  clause, and no top-level clause.
- **A108** (R3V-6) A90's settings with A100's `zsh`: cloud FAIL, the top-level clause,
  and no schema clause.
- **A109** (R3V-6) Settings' Stop `statusMessage` written `"Checking the gate",`
  (an escape and a trailing comma): cloud FAIL, the escape clause, and no not-JSON
  clause. (true on 8e634e4b, which knows no not-JSON rule; it pins the order)
- **A110** (R3V-6) The plugin's PreToolUse matcher widened as in A25, with A90's
  settings: cloud FAIL, the top-level clause, and no `bound differently`.
- **A111** (R3-5, R3V-7) Over A86 to A110, the stubs for `jq`, `python3` and `node`,
  first on PATH, record no call. (control)

Expected red on this commit (8e634e4b's gate): A86, A87, A89 to A104, A106 to A108 and
A110 fail (22); A85, A88, A105, A109 and A111 pass (5). A69 to A84 keep round 3's
results.

### Found, not the review round's

- **Event names.** An unknown event key in settings (`"Foo": []`) is not refused. No
  probe showed Claude Code skipping a file for one, and a misspelled event the plugin
  binds still reads `not bound for the cloud:`.
- **The plugin's hooks.json against B08R3V-4 and B08R3V-5.** Not held to them. The
  plugin loader reads it under its own schema, and a plugin hook Claude Code drops is
  dropped in local sessions as well, so the cloud does not run less than a local session
  does. Size and grammar (B08R3V-2, B08R3V-3) apply to both files.
- **`.claude/settings.local.json`.** Claude Code reads it beside settings.json (its own
  `disableAllHooks` message names both files). The repository does not ignore it; only
  this machine's global git ignore does. A committed one could set `disableAllHooks` in
  the cloud and the check would not read it. That is for the session holding the batch.

## 8. Follow-up round: a NUL byte, and a committed local settings file

Two faults found after the review round, by the commit security review of 8e634e4b and by
section 7's last list. Each lets the gate say `cloud ok` while the cloud runs fewer hooks
or none. The clauses add to sections 2, 4 and 7. Their assertions, A112 onwards, are in
part 1771 after A111, named `B08R3W A<n> (R3W-<m>...)`, over FC as for A69.

**Finding W1 (medium): a NUL byte.** The reader's control-character set is built from
bytes 1 to 31, so a NUL byte (0x00) is not refused. BWK awk (the Mac) and gawk (CI) read
a NUL differently: one ends the line or the string at it, the other keeps it as a byte.
So one tree can get two verdicts, and an escape or a repeated key after a NUL can be
hidden from one of them. Claude Code's JSON parser rejects a file that holds a NUL.

- **B08R3W-1. NUL.** Either file holding a NUL byte anywhere is unreadable, and nothing
  else is read from it: cloud FAIL, with the clause `unreadable: <path> (a NUL byte);`.
  - It is decided before awk reads the file, by a byte test outside awk, so BWK awk and
    gawk give the same verdict on every file.
  - In B08R3V-6's order it comes after size and before escape: size, NUL, escape, not
    JSON, repeat, top-level key, schema. A file over 65536 bytes gets the size clause
    only, NUL or not.
  - B08R3-4's rules hold for it as for any round-3 clause: one clause per file,
    hooks.json's first, and over it nothing is compared.

**Finding W2 (medium): a committed `.claude/settings.local.json`.** Claude Code reads it
beside settings.json, so a committed one can set `disableAllHooks` or add hooks in the
cloud, and the check never reads it. Only this machine's global git ignore keeps it out
of the repository today.

- **B08R3W-2. A local settings file in the index.** When `.claude/settings.local.json`
  is in the checkout's git index (tracked or staged), the cloud line is FAIL.
  - The detail begins with `unreadable: .claude/settings.local.json (a local settings
    file in the repository, which Claude Code reads beside settings.json);`.
  - What the two files give follows it as without it: their clauses, or their
    comparisons and the guard-count and toolbox clauses.
  - The file's contents are not read, so an empty or valid one fails the same.
  - A `.claude/settings.local.json` that is on disk but not in the index is ignored, as
    today. The cloud never sees it.
  - When git cannot say whether the file is in the index, the line is FAIL with the
    same clause, ending `(git could not say whether it is in the repository);`
    instead. No outside input reaches that case, so it has no assertion.
- **B08R3W-3. Nothing else changes.** A tree with no NUL byte in either file and no
  local settings file in the index gives what 4d68d57f gives, byte for byte. The check
  still calls no jq, python3 or node, and writes no file.

### Assertions (part 1771, after A111; FC as for A69)

- **A112** (R3W-1) settings.json with one NUL byte inside the PostToolUse group's
  `statusMessage` value: cloud FAIL, the NUL clause for settings.json, no other clause
  for it, last line `gate: FAIL (cloud)`, exit 1.
- **A113** (R3W-1) hooks.json with one NUL byte between two keys of a hook object: the
  NUL clause for hooks.json.
- **A114** (R3W-1) settings.json whose last byte is a NUL, after its closing brace:
  the NUL clause.
- **A115** (R3W-1) settings.json with a NUL byte and then, after it, a `\/` escape in a
  command: the NUL clause, not the escape clause.
- **A116** (R3W-1, R3V-2) settings.json padded past 65536 bytes with a NUL inside: the
  size clause only.
- **A117** (R3W-1, R3-4) both files with a NUL byte: two NUL clauses, hooks.json's
  first, and no `bound differently`, `not bound` or `no event-to-hook pairs`.
- **A118** (R3W-2) `.claude/settings.local.json` holding `{}`, added and committed: cloud
  FAIL, the detail beginning with the local-settings clause, exit 1.
- **A119** (R3W-2) the same file staged with `git add` but not committed: the same.
- **A120** (R3W-2, R3-4) the local file committed and settings.json given a `\/`
  escape: the local clause first, then settings.json's escape clause.
- **A121** (control, R3W-2) `.claude/settings.local.json` on disk with
  `{"disableAllHooks": true}`, not in the index: cloud ok.
- **A122** (control, R3W-3) the tree's two files, no local file: cloud ok, the detail
  byte for byte as on 4d68d57f.
- **A123** (control, R3-5) over A112 to A122, the `jq`, `python3` and `node` stubs record
  no call.

Every case also greps its fixture for the byte or file it plants: `od` shows the NUL, or
`git ls-files` shows the local file. A broken fixture cannot then pass for the rule.
Expected red on 4d68d57f: A112 to A120 fail (9). A121 to A123 pass (3).

## 9. Second follow-up: what section 8's review found

The review of 24ae0a93 (section 8's fix) found one medium and two lows. Each is a way the cloud
line says `ok`, or says different things on two machines, for a tree section 8 meant to fail.
Their assertions, A124 onwards, are in part 1771 after A123, named `B08R3X A<n> (R3X-<m>...)`,
over FC as for A69.

- **B08R3X-1 (medium). `.claude` must be a real directory.** When `.claude` is a symlink on
  disk, or the index holds an entry at the path `.claude` itself (a symlink, mode 120000, or a
  gitlink, 160000), git does not resolve `.claude/settings.local.json` through it, so section
  8's test cannot see a local settings file there.
  - The cloud line is then FAIL. Its detail begins with
    `unreadable: .claude (not a directory in the repository, so its settings files cannot be
    judged);`.
  - Nothing else is read from `.claude`.
- **B08R3X-2 (low). The local-file test runs whatever settings.json's state.** B08R3W-2's test
  runs before the check decides whether `.claude/settings.json` exists. A local settings file in
  the index with no settings.json is cloud FAIL with the local clause, never `skipped`. With
  neither file the cloud line is as today.
- **B08R3X-3 (low). Nothing is counted in a file that cannot be read.**
  - The guard counts (the commands naming harness hooks, and those carrying the
    CLAUDE_CODE_REMOTE guard) are not taken from a settings file with a size or NUL fault.
  - Over such a file the detail holds that file's clause and no guard-count clause.
  - The counts are otherwise as today.
- **Found, not this round's:** an unguarded command on the same line as a guarded one passes the
  line-based guard count. The defect predates round 3. Counting per command string inside the
  awk reader would fix it, and that is the batch owner's to schedule.

### Assertions (part 1771, after A123)

- **A124** (R3X-1) `.claude` committed as a symlink to a directory `cfg` that holds
  settings.json, the cloud files and a settings.local.json added with `git add -f`: cloud FAIL,
  the detail beginning with the `.claude` clause. The fixture checks `git ls-files -s -- .claude`
  shows mode 120000.
- **A125** (R3X-1) `.claude` a symlink on disk only, its target untracked and the real
  `.claude` removed from the index: the same clause.
- **A126** (control, R3X-1) the tree's own `.claude`, a real directory: cloud ok, the detail as
  A122 pins it.
- **A127** (R3X-2) the local file committed and settings.json removed from disk and index:
  cloud FAIL, the local clause, no `skipped`.
- **A128** (control, R3X-2) settings.json removed and no local file: the cloud line exactly as
  4d68d57f prints it for that tree.
- **A129** (R3X-3) settings.json with a NUL byte, and one line holding a guarded and an
  unguarded harness command: the NUL clause, and no `without the CLAUDE_CODE_REMOTE guard`
  clause.
- **A130** (R3X-3) settings.json over 65536 bytes with that same line: the size clause, and no
  guard-count clause.

Expected red on 24ae0a93: A124, A125, A127, A129 and A130 fail (5). A126 and A128 pass (2).

## 10. Third follow-up: the cloud check judges what git holds

The review of 2eeedbed (section 9's fix) found three mediums and two lows. Two of the mediums are
one class, which sections 8 and 9 each closed one instance of: the cloud check reads the working
tree, and on the Mac the working tree can answer for a path git does not hold. APFS folds case,
and `[ -f ]` follows a symlink at any depth. The cloud gets only what git holds, byte for byte, on
a file system that folds nothing. So a committed `.Claude/settings.json`, a committed
`.claude/Settings.json`, a committed symlink at `.claude/settings.json` or at `.claude/cloud`, each
read `cloud ok` on the Mac and `skipped` in CI, while the cloud ran no project hook or carried no
toolbox. This round closes the class, not the instances.

- **B08R3Y-1 (medium, class). Judge the index, never the disk.**
  - **Exact entries.** A file under `.claude/` exists for the cloud check only when the index
    holds an entry whose path is byte for byte that path (`git ls-files -s`, compared exactly,
    case included). `.claude/settings.json` is "in this tree" only when the index holds it so.
  - **Content from the index.** Every file the cloud check reads under `.claude/`
    (`settings.json` and `cloud/toolbox.json`) is read from its index blob
    (`git cat-file blob :<path>`), never from the working tree. The size, NUL, escape, JSON,
    repeat, key and schema rules, the binding comparison, the guard counts and the toolbox names
    all apply to that content. An edit not yet staged is not judged until it is staged. That is
    what the commit, and so the cloud, will hold.
  - **Regular files only.** Every index entry under `.claude/`, at any depth, must have mode
    100644 or 100755. Each entry with any other mode (120000, a symlink; 160000, a gitlink) adds
    the clause ` unreadable: <path> (not a regular file in the repository, so the cloud would not
    get its content);`, one per entry, in index order.
  - **No case variants.** Each index entry whose path differs only by case from `.claude`, from a
    path beginning `.claude/`, or from `.claude/settings.json`, `.claude/settings.local.json` or
    `.claude/cloud/toolbox.json` adds the clause ` unreadable: <path> (its name differs only by
    case from one the cloud reads, and the cloud's file system does not fold case);`. One clause
    per entry, in index order. Compare with ASCII case folding only.
  - When any clause in this bullet is present, the cloud line is FAIL. It is never `skipped`.
  - B08R3X-1 stands: a `.claude` that is a symlink or a non-directory on disk, or an entry at the
    path `.claude` itself, gives its clause, and nothing else is read.
  - `engine/hooks/hooks.json` is the engine's own reference, not something the cloud loads. It is
    out of this bullet and is read as today.
- **B08R3Y-2 (medium, tests).** A129 and A130 could not be red. Their only unguarded command
  shared a line with a guarded one, so the line-based count never moved. Each fixture now also
  holds an unguarded harness command on a line of its own. A129's NUL may sit anywhere in the
  file. Expected red on 24ae0a93 for both, under BSD and GNU grep alike.
- **B08R3Y-3 (low, tests).** "Nothing else is read from `.claude`" (B08R3X-1) is asserted. A124's
  target directory `cfg` holds a settings.json with an unguarded command on its own line and an
  escape other than `\"`. A124 asserts the detail equals the `.claude` clause exactly.
- **B08R3Y-4 (low).** When the binding comparison cannot run because no event-to-hook pairs were
  read (hooks.json missing or unreadable), a settings.json with a size or NUL fault still adds
  its clause (`larger than 65536 bytes` or `a NUL byte`, as section 8 words it). It appears beside
  the no-pairs message. B08R3X-3 stands: no guard count is taken over that file.
- **B08R3Y-5 (low, the found-not-ours of section 9).** The guard counts are per command, not per
  line. Every occurrence of `"command":` counts once, and every occurrence of the guarded prefix
  counts once, so a line that holds a guarded and an unguarded command adds one to the
  difference.

### What must not change (beyond section 3)

- The clean tree's cloud line, and every fixture A69-A128 builds, read as on 2eeedbed. A129 and
  A130 are restated (B08R3Y-2), and A124 is strengthened (B08R3Y-3).
- The check-line count stays at 26. gate.sh stays within 80 lines over 8e634e4b, unless the
  builder shows the class cannot fit, and then it says so.
- No jq, no python: bash, git and the awks only (constitution invariant 2).

### Assertions (part 1771, after A130)

Named `B08R3Y A<n> (R3Y-<m>...)`, over FC as for A69. On macOS, case-variant entries are made in
the index without touching the disk: `git update-index --add --cacheinfo 100644,<sha>,<path>`
after `git rm --cached` of the exact path. The fixture checks `git ls-files -s` shows exactly
what the case names.

- **A131** (R3Y-1, mode) `.claude/settings.json` committed as a symlink (120000) to an untracked
  `../cfg/settings.json` that holds the tree's good settings: cloud FAIL, the not-a-regular-file
  clause naming `.claude/settings.json`, and no `skipped`.
- **A132** (R3Y-1, mode) `.claude/cloud` committed as a symlink to an untracked copy of the tree's
  cloud directory, with settings.json real: cloud FAIL, the clause naming `.claude/cloud`.
- **A133** (R3Y-1, case) the index holds `.Claude/settings.json` and no exact `.claude/...` entry:
  cloud FAIL, the case clause naming `.Claude/settings.json`, and no `skipped`.
- **A134** (R3Y-1, case) the index holds `.claude/Settings.json` and no exact
  `.claude/settings.json`: cloud FAIL, the case clause naming `.claude/Settings.json`.
- **A135** (R3Y-1, index over disk) the index holds the tree's good settings.json. The working
  tree's copy has an unguarded command on its own line, unstaged. The cloud line is exactly
  A126's.
- **A136** (R3Y-1, index over disk) the reverse. The index holds a settings.json with an
  unguarded command on its own line, and the working tree's copy is the good one: cloud FAIL with
  `1 command(s) without the CLAUDE_CODE_REMOTE guard;`.
- **A137** (R3Y-1, untracked) `.claude` is a real directory on disk holding the good files, and
  none of them is in the index: the cloud line is the `skipped` line A128 pins.
- **A129, A130** restated for B08R3Y-2: as section 9, plus an unguarded command on its own line.
- **A124** restated for B08R3Y-3: as section 9, with the faults behind the link. The detail is
  exactly the `.claude` clause.
- **A138** (R3Y-4) hooks.json removed, and settings.json holding a NUL byte and an unguarded
  command on its own line: cloud FAIL, the detail holding the no-pairs message and `a NUL byte`
  naming `.claude/settings.json`, and no guard-count clause.
- **A139** (R3Y-5) one line holding a guarded then an unguarded harness command, no NUL, nothing
  else wrong: cloud FAIL with `1 command(s) without the CLAUDE_CODE_REMOTE guard;`.
- **A140** (control) the tree's own `.claude`, staged and clean: as A126.

Expected red on 2eeedbed: A131 to A139 (9), since 2eeedbed reads the disk. A137 is among them,
because 2eeedbed judges the untracked files and says `ok`. A129 and A130 as restated are red on
24ae0a93 and green on 2eeedbed, because they test B08R3X-3. A124 restated and A140 pass on
2eeedbed. Report each one.

## 11. Fourth follow-up: what git holds is what a checkout writes

The review of 25f4fd53 (section 10's fix) found the clauses it targets correct across symlinks,
gitlinks, case variants, conflicted stages, intent-to-add entries and sparse checkouts. It found
one medium regression beside them, one older medium, and five lows.

- **B08R3Z-1 (medium, regression). A checkout conversion is a fault.** Git can change a file's
  bytes between the index and the working tree, through attributes in a committed
  `.gitattributes`. Section 10's index blob is then not what the cloud's checkout writes. A
  `working-tree-encoding=UTF-16` on settings.json gives the cloud a UTF-16 file that Claude Code
  cannot parse. 2eeedbed failed that tree for its NUL bytes; 25f4fd53 reads it ok.
  - For every regular-file index entry under `.claude/`, the attributes `working-tree-encoding`,
    `filter` and `ident` are read from the index (`git check-attr --cached`). Each one set on an
    entry adds ` unreadable: <path> (git attribute <attr> changes it at checkout);`, one per
    entry and attribute, in index order.
  - `text` and `eol` are not faults. They change only line endings, which JSON reads as
    whitespace. The content judged stays the index blob.
  - An attribute from a machine-local source (`.git/info/attributes`, `core.attributesFile`)
    also counts. That fails closed, and only on that machine.
- **B08R3Z-2 (medium, older). The guard count reads the JSON, not the text.** Every hook object's
  `command` value in settings.json counts once, however the key is spaced or broken across
  lines. It is guarded when the value begins with the guard prefix the check already names. The
  count is taken in the awk that parses settings.json, and the two greps go. The clause and its
  wording are unchanged. B08R3X-3 stands: over a size or NUL fault, no count is taken.
- **B08R3Z-3 (low). A non-ASCII name the Mac may fold.** APFS folds some non-ASCII letters onto
  ASCII ones, for example U+017F (`ſ`) onto `s`. So the index can hold `.claude/ſettings.json`
  while the Mac's disk answers for `.claude/settings.json`.
  - Each index entry is compared component by component with the components the cloud reads:
    - first: `.claude`;
    - second: `settings.json`, `settings.local.json` or `cloud`;
    - third, under `cloud`: `toolbox.json` or `provision`.
  - A component holding a byte above 0x7f is a fold risk when, with each run of such bytes
    standing for any one character and ASCII case folded, it matches the component read at that
    position, and the components before it match too.
  - Such an entry adds ` unreadable: <path> (a non-ASCII name the Mac's file system may fold onto
    one the cloud reads);`. The line is FAIL, never `skipped`.
  - A non-ASCII name elsewhere under `.claude/` is not a fault, for example
    `.claude/cloud/notes-é.md` or `.claude/agents/é.md`.
- **B08R3Z-4 (low). Both sides of the toolbox comparison come from the index.** The stack rows
  are read from the index blob of `projects/felix/stack.tsv`, like toolbox.json.
  `engine/hooks/hooks.json` is still read from disk (section 10). On a tree with unstaged edits,
  that one comparison mixes sources, and this contract accepts that.
- **B08R3Z-5 (low). The check leaves no file behind on any exit.** Feed the blobs to awk, grep
  and sed through pipes or variables, not a temp file. If a file is unavoidable, a trap removes
  it on EXIT, INT and TERM, without disturbing any trap gate.sh already sets.
- **B08R3Z-6 (low). A missing stage-0 copy is said as such.** When git's index holds no stage-0
  `.claude/settings.json` (a merge conflict), the clause is ` unreadable: .claude/settings.json
  (git's index holds no stage-0 copy of it);`. No clause holds a path on the machine running the
  gate.
- **B08R3Z-7 (low, tests). The index, not HEAD.** Section 10's cases committed their index, so a
  check reading `HEAD:<path>` passed them all. Two cases separate the two (below).

### What must not change (beyond sections 3 and 10)

- Every A69-A140 case reads as on 25f4fd53. The clean tree's line is byte for byte as before.
- gate.sh may grow to 120 lines over 8e634e4b; the builder reports the count. gate.sh is past
  500 lines on main already. Moving the cloud check into its own file is a batch of its own,
  because a new file needs its own risk row.

### Assertions (part 1771 after A140, or a new part 1772 if 1771 would pass 950 lines)

Named `B08R3Z A<n> (R3Z-<m>...)`.

- **A141** (R3Z-1) A committed `.gitattributes` holds `.claude/settings.json
  working-tree-encoding=UTF-16`, and the tree's settings.json is added through it, so the index
  blob is UTF-8. Expected: cloud FAIL with the attribute clause naming `.claude/settings.json` and
  `working-tree-encoding`. The fixture checks the blob is UTF-8 and `git check-attr --cached`
  reports the attribute.
- **A142** (R3Z-1) the same for `.claude/cloud/toolbox.json`.
- **A143** (R3Z-1) `.claude/settings.json filter=felixtest`, with no driver configured: the
  `filter` clause.
- **A144** (R3Z-1, control) `.claude/settings.json text eol=lf`: the cloud line as A140.
- **A145** (R3Z-2) one hook's command written `"command" : "<unguarded harness command>"`: cloud
  FAIL with `1 command(s) without the CLAUDE_CODE_REMOTE guard;`.
- **A146** (R3Z-2) the same with a newline between `"command"` and `:`.
- **A147** (R3Z-2, control) a guarded command written `"command" : "<the guard prefix>..."`: no
  guard clause.
- **A148** (R3Z-3) the index holds `.claude/ſettings.json` (U+017F, bytes C5 BF), the tree's
  good blob, and no exact `.claude/settings.json`: the non-ASCII clause, and no `skipped`.
- **A149** (R3Z-3, control) the tree's own `.claude` plus a committed `.claude/cloud/notes-é.md`:
  the cloud line as A140.
- **A150** (R3Z-4) a toolbox entry removed and staged, and its stack row removed on disk only:
  cloud FAIL with `<name> has no entry in .claude/cloud/toolbox.json;`.
- **A151** (R3Z-5) the gate run with TMPDIR (and GTLOG_DIR if the gate reads it) set to an empty
  directory: after the run, that directory holds no file the cloud check made.
- **A152** (R3Z-6) settings.json in a merge conflict (stages 1-3 only): the stage-0 clause
  exactly, and no `/` inside its parentheses.
- **A153** (R3Z-7) HEAD and the disk hold the good settings.json, and the index holds a staged,
  uncommitted copy with an unguarded command on its own line: the guard clause.
- **A154** (R3Z-7, control) HEAD holds the unguarded copy, while the index and the disk hold the
  good one: the cloud line as A140.

Expected red on 25f4fd53: A141, A142, A143, A145, A146, A148, A150 and A152 (8). A151 may be red
if 25f4fd53 leaves its temp file in TMPDIR. A153 should pass on 25f4fd53, because it reads the
index. The controls pass. Report each one.

## 12. Fifth follow-up: every file the cloud runs is judged as its reader reads it

The review of 9801aa12 (section 11's fix) found no fail-open in the code it added. Fourteen earlier
fixture types read the same as on 25f4fd53. It found two mediums and five lows. The first medium is
this contract's own error. Section 11 exempted `text` and `eol` because JSON reads a line end as
whitespace, but `.claude/cloud/provision` is bash. The second medium is older: the toolbox was
never parsed, only matched line by line with sed.

- **B08R3Z2-1 (medium). A line-ending conversion is a fault outside the two JSON files.**
  - For every regular-file index entry under `.claude/` other than `.claude/settings.json` and
    `.claude/cloud/toolbox.json`, a checkout that writes CRLF is a fault. On the cloud's Linux
    checkout, with no local config, that is `eol` set to `crlf`. The legacy `crlf` attribute
    alone means `text` and writes LF there, so it is not a fault.
  - It adds ` unreadable: <path> (git attribute eol changes it at checkout);`, in the B08R3Z-1
    order.
  - The two JSON files keep section 11's exemption.
  - Attributes are read with `git -c core.ignorecase=false check-attr --cached`, so a pattern that
    matches only by case folding counts on the Mac as it does on Linux. This closes the
    review's low, where a `.CLAUDE/...` pattern failed on the Mac and passed in CI.
- **B08R3Z2-2 (medium, older). The toolbox is parsed, and provision must be there.**
  - `.claude/cloud/toolbox.json`'s index blob goes through the JSON reader settings.json already
    uses: size, NUL, escape, one JSON text, no repeated key.
  - Its top level must be one object holding `tools`, an array of objects, each with a string
    `name`. The names are read from that parse. sed is gone.
  - A toolbox that fails any of this adds ` unreadable: .claude/cloud/toolbox.json (<the first
    fault, in the reader's words>);`. No `has no entry` clause is said over it.
  - When any command in settings.json names `.claude/cloud/provision`, the index must hold that
    path as a regular file with mode 100755. Otherwise the line adds ` unreadable:
    .claude/cloud/provision (settings.json runs it, and git's index holds no executable file
    there);`.
- **B08R3Z2-3 (low, regression). stack.tsv by section 10's rules.** `projects/felix/stack.tsv` is
  read only as a stage-0 regular-file entry (100644 or 100755). Anything else adds ` unreadable:
  projects/felix/stack.tsv (not a regular file at stage 0 in git's index);`, and no toolbox row
  is compared.
- **B08R3Z2-4 (low, the #376 class). No `printf | grep -q` under pipefail.** The toolbox membership
  test must not race SIGPIPE, which it did once in about 110 runs of a good tree. Use awk or a
  `case` over the parsed names.
- **B08R3Z2-5 (low, tests).**
  - A151 tests a normal exit only, and passes on 25f4fd53. It is renamed a pin.
  - "On any exit" is pinned by reading: the cloud check contains no `mktemp` and writes no file.
  - Assertions are added for `ident`, for a machine-local attribute source (`.git/info/attributes`),
    and for the fold test on `.claude/cloud/proviſion` and `.claude/ſettings.local.json`, with
    `.claude/cloud/notes-ſ.md` as the control.

### Limits

- gate.sh may grow to 160 lines over 8e634e4b; the builder reports the count.
- Moving the cloud check into its own file is still the founder's batch (a new risk row).

### Assertions (part 1772 after A154)

Named `B08R3Z2 A<n> (R3Z2-<m>...)`.

- **A155** (R3Z2-1) a committed `.claude/cloud/provision text eol=crlf`: the eol clause naming
  provision.
- **A156** (R3Z2-1, control) `.claude/settings.json text eol=crlf`: cloud ok, as A140.
- **A157** (R3Z2-1) a committed `.CLAUDE/settings.json filter=felixtest`, with the repository's
  core.ignorecase true: no filter clause, as Linux reads it.
- **A158** (R3Z2-2) toolbox.json with `,"tools": []` added before its closing brace: the toolbox
  clause, a repeated key.
- **A159** (R3Z2-2) toolbox.json with a trailing comma: the toolbox clause, not JSON.
- **A160** (R3Z2-2) toolbox.json whose `tools` is an object: the toolbox clause.
- **A161** (R3Z2-2) settings.json runs provision, and provision is removed from the index: the
  provision clause.
- **A162** (R3Z2-2) provision committed at mode 100644: the provision clause.
- **A163** (R3Z2-3) stack.tsv committed as a symlink to a file holding an extra plugin row: the
  stack.tsv clause.
- **A164** (R3Z2-3) stack.tsv in a merge conflict: the stack.tsv clause.
- **A165** (R3Z-1, coverage) `.claude/settings.json ident`: the ident clause.
- **A166** (R3Z-1, coverage) `.git/info/attributes` holding `.claude/cloud/provision filter=x`:
  the filter clause.
- **A167** (R3Z-3, coverage) the index holding `.claude/cloud/proviſion` in place of provision:
  the non-ASCII clause. A variant with `.claude/ſettings.local.json` gives the same.
- **A168** (R3Z-3, control) `.claude/cloud/notes-ſ.md` committed beside the good tree: as A140.
- **A169** (R3Z2-5) gate.sh's cloud block, read as text, holds no `mktemp`.
- **A151** renamed: "a pin, normal exit".

Expected red on 9801aa12: A155, A157, A158, A159, A160, A161, A162, A163 and A164 (9), and A169
if 9801aa12 still holds a mktemp in the block. The coverage cases, the controls and A151 pass.
Report each one.
