# A capability reached from the shell: the ledger counts a CLI run through Bash, the specification

Written 2026-10-31 against main at 1fca9559 (engine 0.49.320). Every behaviour
below is numbered, says what is observable, and is meant to become one or more
assertions in `engine/harness/tests/parts/`. Decisions taken where the brief
left a choice are in section 8, each with its evidence.

Tier: adversarial. `lib/ledger.sh`, the new `lib/ledger-runs.sh`, and the
post-tool and session-start hooks run in every session of every governed
project.

Notation: `\t` is one tab byte. A row written `a\tb\tc` is one line ending in a
newline. Paths are relative to `engine/harness/` unless they start with
`projects/` or `docs/`. "The payload" is the JSON object Claude Code writes to
a hook's standard input.

---

## 0. Why, in one paragraph

`felix_ledger_signal` records each PostToolUse call by what it reached: an MCP
server by its server, a skill by its name, an agent by its type, and anything
else as `tool <name>`. A Bash call that runs `graphify query ...` is therefore
recorded as `tool Bash`, and graphify, which is a command-line tool, can never
be reached at all. On 2026-10-31 `felix ledger` said graphify was "pointed at in
17 of 244 sessions, named 25 times, never reached", and session start printed
the same line as "the only unconfounded signal here". The transcripts on this
machine say otherwise: 69 Bash commands run graphify. A capability plane that
cannot see a well-known tool being used cannot judge whether to suggest or
mount anything. This change reads the Bash command, in bash alone and without
a process, and records a reach of the capability when the command runs a
program the project's route table names.

## 1. Measured before the change

- `felix ledger` for felix, read 2026-10-31 18:45Z, 244 sessions: `graphify`
  17 sessions, named 25, reached 0, and on the retire list; `semgrep` on it too
  ("its countable surfaces never reached"); `Bash` 241 sessions, 190,516 calls.
- The route tables name these bare play entries (no `:` and no `@`): felix
  `code-review semgrep graphify claude-md-management`; the template and five
  other projects `frontend-design impeccable playwright` or two of them;
  elenchus twelve, veldra three, one project none. Of them, graphify and
  semgrep are programs that sessions run from the shell on this machine.
- Transcripts on this machine hold 1,313 Bash commands that contain any of
  those names as text. Most carry the name as data: inside quotes, in a
  here-document written to a file, in a comment, or as an argument (`command -v
  graphify`, `pgrep -fl graphify`, `grep 'graphify '`). A prototype of the
  reading in section 3 found 69 that run graphify and 23 that run semgrep; each
  of the 92 was read by hand at the position the reading named, and each is a
  run.
- The post-tool hook costs about 22 ms of CPU per call today, almost all of it
  in the processes it starts.
- Passing a 4 MB payload to a shell function with `local raw="$1"` costs about
  45 ms of CPU in bash 3.2; the hook already does this. Cutting the first 32 KB
  of a 4 MB string with an unquoted `${raw:0:32768}` costs about 3.6 ms.
- The prototype read each of the 1,313 commands in a median of about 2 ms of
  CPU, p90 about 5 ms, at most about 19 ms (bash 3.2.57, macOS 27), bounded as
  section 3 says.
- macOS's regex library rejects an empty alternative such as `(|a)`, and bash
  then reports no match rather than an error. Every pattern must be valid ERE
  on both macOS and glibc.

## 2. The names a session can reach from the shell (N)

N1. **Written at session start.** On every SessionStart (sources `startup`,
`resume`, `clear` and `compact` alike, and before a resume leaves the hook), for
a governed directory whose payload carries a usable session id, the hook writes
`<home>/state/ledger/<session>.names`, where `<home>` is the Felix home and
`<session>` the payload's first `session_id`. It creates `state/ledger/` when
missing. A failure to write is silent and never changes what the hook prints or
its exit status.

N2. **What a name is.** A name is a play entry, a word of the fourth field of a
`routes.tsv` row of the session's project, that:
- is in a row the router reads (`_felix_route_rows`: not blank, not starting
  with `#`, a non-empty third field; a last row with no newline counts);
- consists only of the bytes `A-Z a-z 0-9 . _ + -`, starts with a letter or a
  digit, and is at most 64 bytes long.

So `superpowers:brainstorming`, `semgrep@claude-plugins-official`, `-` and
`a/b` are not names, and `graphify`, `code-review` and `sentry-cli` are.

N3. **The file's content.** One line ending in a newline: each name once, in
the order it first appears (rows top to bottom, entries left to right),
separated by single spaces. At most the first 32 distinct names. When no entry
qualifies, or the project has no `routes.tsv`, the file holds one empty line.

N4. **Replaced whole.** A second start of the same session id replaces the
file; it is never appended to. It is written to a temporary name in the same
directory and renamed into place, so a reader never sees half of it. A
symbolic link at its path is replaced, never followed; a directory there is
left as it is, and the session gets no names file.

N5. **A session id that is not a file name.** A session id is usable when it is
non-empty and made only of `A-Z a-z 0-9 _ -` (the rule `lib/answer.sh` applies
to its own per-session file). Otherwise no names file is written, and the
post-tool hook reads none (P6).

N6. **Ungoverned.** In a directory no project governs, nothing is written.

## 3. Reading what a Bash command runs (R)

R0. **The text read.** The command is the JSON string value of the `"command"`
key, read only when the first occurrence of the text `"command"` within the
first 32,768 bytes of the payload is that key: followed by optional blanks, a
colon, optional blanks and the opening quote. Otherwise nothing is read. Only
the first 16,384 bytes of the value as the payload writes it (a JSON escape
such as `\n` is two of them), and none past the payload's 32,768th byte, are
read; the value ends at its first unescaped closing quote. JSON escapes read as
JSON defines them: `\"` is a double quote, `\\` a backslash, `\/` a slash, `\n`
a line break, `\t` a tab. `\r`, `\b`, `\f` and `\uXXXX` are characters, and no
name contains one.

R1. **The program word.** The command runs NAME when NAME is the program word
of one of its simple commands (R2, R3). Program words are taken in the order
their text appears in the command; the first one that is a name of the session
(N) is the reach, and nothing after it changes the result.

R2. **Where a simple command starts.**
- at the start of the command;
- after a line break, `;`, `&`, `&&`, `||`, `|`, `|&`;
- after `(` opening a subshell, inside `$(...)`, inside backticks, inside
  `<(...)` and `>(...)`;
- after the reserved words `!`, `{`, `if`, `then`, `else`, `elif`, `while`,
  `until`, `do` when they stand where a program word would;
- after the `)` that ends a `case` pattern;
- at the start of the body of a function the command defines, in any of the
  forms `NAME()`, `NAME ()`, `function NAME` and `function NAME()`: a function
  is defined to be called. The function's own name is not a program word.

R3. **Words before the program word.** At the start of a simple command these
are passed over, and the next word is considered:
- an assignment: an unquoted shell identifier followed by `=` or `+=`, whatever
  follows (`FOO=1`, `X="a b"`, `P=$(...)`);
- a redirection and its target: `<`, `>`, `>>`, `>|`, `<>`, `<&`, `>&`, `&>`,
  `&>>`, `<<<`, each optionally after a file-descriptor number (`2>&1`,
  `2>/dev/null`), with the target in the same word or the next;
- a wrapper and its options: `time` (`-p`, `-o FILE`, `-f FORMAT`), `nohup`,
  `exec` (`-c`, `-l`, `-a NAME`), `command` (`-p`), `nice` (`-n N`,
  `--adjustment N`, `-N`, `--adjustment=N`), `env` (`-i`, `-`, `-u NAME`,
  `--unset NAME`, `-C DIR`, `--chdir DIR`, `-P PATH`, other `-` options, and
  assignments), `timeout` (`-s SIG`, `--signal SIG`, `-k DUR`,
  `--kill-after DUR`, other `-` options, then one duration word). An option
  written with its argument after `=` (`--chdir=DIR`) is one word. After a
  wrapper, every word that starts with `-` is an option, the options listed
  with an argument also take the next word, and `--` ends the options.
  Wrappers chain (`nohup time graphify`). A wrapper is recognised by the part
  of its word after the last `/` (`/usr/bin/env`).
- `command` with an option word containing `v` or `V` (`-v`, `-V`, `-pv`)
  looks a program up and runs none: that simple command has no program word.
- `env` with `-S` or `--split-string` has no program word that this reading
  follows.

R4. **The program word's name.** The word's text after quote removal, from
after its last `/`: `'graphify'`, `"graphify"`, `\graphify`, `./graphify`,
`~/.local/bin/graphify`, `/opt/x/bin/graphify`, `$HOME/.local/bin/graphify`
and `"$D"/graphify` all name `graphify`. The part after the last `/` must be
literal: a word whose last part holds a parameter expansion, a command
substitution or a backtick (`$G`, `$(cat f)`, `x$y`) names nothing. A word that
is a reserved word (R2) is not a program word. A name the command's text does
not spell whole, because quoting or an escape splits it (`gra"phi"fy`,
`gra\phify`), is not seen: the reading starts only for a command whose text
holds a name's own bytes (C3).

R5. **Compared exactly.** Byte for byte and case-sensitive: `Graphify` and
`graphifyx` are not `graphify`, and a quoted word holding two names
(`"graphify semgrep"`) is neither of them.

R6. **Text a command only carries is never a program word.** Words inside
single quotes, double quotes, `$'...'` or `${...}` (but the commands of a
`$(...)` or backtick substitution inside double quotes or `${...}` are read,
as the shell runs them), here-document bodies,
comments (`#` at the start of a word, to the end of its line, among an array's
values too), arguments of any
program, `case` subjects and patterns (including alternatives after `|`), the
words after `for`, `select` and `[[` up to the end of that clause (`&&`, `||`
and `(` inside `[[ ... ]]` do not start a command), array values in
`a=(...)`, and arithmetic in `((...))` and `$((...))`, which is read to its
closing pair and not into.

R7. **Here-documents.** `<<WORD`, `<<-WORD`, `<< WORD`, `<<'WORD'`,
`<<"WORD"` and `<<\WORD`, where WORD is made of `A-Z a-z 0-9 _ . -`. The body
runs from the line after the operator's line to the first line that is WORD
alone (for `<<-`, after any leading tabs). Reading resumes after that line,
whose line break counts as a separator. Several here-documents on one line are
read in order. When WORD is unquoted the shell joins a body line that ends in a
backslash to the next before it looks for WORD, so a WORD line that directly
follows such a line is not the end of the body: it ends the reading (R9). A
backslash line further up changes nothing. A substitution in such a body runs,
and is not read (R10). `<<<` is a here-string, not a
here-document (R3).

R8. **Line continuation.** A backslash at the end of a line joins it to the
next: no separator.

R9. **Where the reading ends early.** An unclosed quote, a here-document whose
delimiter has another shape or whose delimiter line is not found, a construct
nested more than 32 levels deep, the step bound, the byte bounds of R0, and the
end of the value. Program words read before that point still count; nothing
after it is read, and a word that a byte bound cuts is not read.
- Nesting: the command itself is level 0, and each `(...)`, `$(...)`,
  `` `...` ``, `<(...)`, `>(...)`, `${...}`, `"..."` or `a=(...)` value inside
  another construct is one level deeper. `graphify` inside 32 nested `$(` is
  read; inside 33 it is not.
- Steps: the reading takes at most 8,192 steps, and every step but the one
  that finds the end of the text consumes at least one byte, so a command
  shorter than 8,192 bytes as the payload writes it is never cut by this
  bound.

R10. **Runs this reading does not see** (stated limits; such a call stays
`tool\tBash`): a command handed to another shell as text (`bash -c '...'`,
`sh -c`, `eval`, `ssh host '...'`), a program named as an argument of another
program (`xargs NAME`, `sudo NAME`, `watch NAME`, a language interpreter
running a module or a package runner fetching a tool), `coproc`, aliases, a
substitution inside arithmetic or inside an unquoted here-document's body (R7),
a name split by quoting (R4), a `case` pattern spanning lines in unusual ways,
and anything past R9's bounds.

R11. **Runs this reading reports that the shell would not make** (stated
limits, found in review, and in none of the 2,151 real commands that hold a
name): a quoted or escaped word that spells a reserved word or an operator
(`'!' graphify`, `"do" graphify`, `[[ $x == "]]" || graphify ]]`,
`"2">x graphify`), an assignment or `--` after a wrapper
(`nohup FOO=1 graphify`), and a function
the command defines under a name it then calls (`graphify() { echo stub; };
graphify query`), each read as what it spells. A command the shell cannot parse
is read up to where it breaks. Most of these fail when the shell runs them, and
PostToolUse is not sent for a call that failed, so one reaches the ledger only
when the call as a whole still succeeds.

## 4. The record (P)

P1. **A reach.** For a PostToolUse call whose `tool_name` is `Bash`, when the
session's names file (N) holds at least one name and the command runs one of
them (R), the line the post-tool hook appends to
`<home>/state/ledger/<session>.tsv` for that call is `cli\t<name>` and not
`tool\tBash`. The `alive\tpost-tool` line is written as before. One call line
per post-tool run, as for every other tool.

P2. **Only the name.** The hook writes nothing else from the command: no
argument, no path, no part of the text, anywhere. A command holding a
credential leaves only `cli\t<name>` or `tool\tBash`.

P3. **Nothing else changes.** Non-Bash calls, a Bash call that runs no name, a
session with no names file, an empty names file, and an unreadable names file
all record exactly what they recorded before this change.

P4. **One name.** A command that runs two names records the first in reading
order (R1).

P5. **The answers' touch.** `felix_answer_touch` (lib/answer.sh) is given
`tool\tBash` for a call recorded as `cli\t<name>`, so the answers measure reads
the command exactly as it did before this change.

P6. **The file read.** The only file the post-tool hook reads beyond its
libraries and the payload is the names file, and only for a Bash call, and only
when the session id is usable (N5). It never reads the session's ledger file or
any other record it writes. A names file whose first line is anything but
names (N2) with one space between each two, and none before the first or after
the last, is read as no names file.

P7. **`felix_ledger_signal RAW [NAMES_FILE]`.** The function the hook calls.
With NAMES_FILE omitted, empty, missing or unreadable it prints exactly what it
printed before. With a names file it prints `cli\t<name>` for a Bash payload
whose command runs a name, and what it printed before otherwise.

## 5. The fold and the reports (F)

These follow from the existing code once a `cli` line is on disk; they are
specified so that they are tested.

F1. **The fold.** `felix_ledger_rollup` writes a `cli` line as a reach row
`<session>\t<date>\tcli\t<name>\t<count>\t<namings>`, where `<count>` is the
number of `cli\t<name>` lines and `<namings>` the number of `named\t<name>`
lines in the session's appends.

F2. **No zero row beside a reach.** In a session with a `cli\t<name>` reach,
the fold writes no `named` row for `<name>` and no zero row for a `stack.tsv`
declaration of `<name>`, whatever its kind.

F3. **A call for the record's wholeness.** A `cli` line is a call when the fold
asks whether the session's appends are whole (`_felix_ledger_whole`): one alive
line and one `cli` line are a whole run.

F4. **Counted.** `felix ledger` reports the capability with the session in its
SESSIONS column and the `cli` reaches in its REACHED column. A `cli` row is
never shown with the ` (built-in)` mark, which belongs to unqualified `skill`
rows only.

F5. **Off the retire list.** A capability with a folded `cli` reach is not in
`felix ledger`'s "pointed at and never reached for" list nor in session start's
"Pointed at and never once reached for:" line.

F6. **Not a server.** `felix_ledger_mcp` ignores `cli` rows.

## 6. Cost (C)

C1. **No new process.** A post-tool run starts no process that the same run
would not have started before this change, for any payload, with or without a
names file: the reading, the names file read and the library load are bash
builtins and `.`.

C2. **No git.** Nothing added runs git.

C3. **Loaded only when needed.** `lib/ledger-runs.sh` is loaded only for a
Bash call whose command (within R0's bound) contains one of the session's
names as text. Loading `lib/ledger.sh` runs no program on PATH.

C4. **Bounded.** A Bash payload of 4 MB, or a 16 KB command of any content, is
recorded by the post-tool hook in under 2 seconds of CPU on the suite's
machine, and the hook exits 0.

C5. **Bash 3.2 and 5, BWK awk and gawk.** Nothing added depends on the bash
version beyond 3.2, on the locale, or on awk. The reading runs with `LC_ALL=C`,
so lengths and the bound are bytes under a UTF-8 locale too.

## 7. What session start says

Nothing new. N1 writes a file and prints nothing. The retire line changes only
through the data (F5).

## 8. Decisions

D1. **The route table, not the stack.** The brief says "a CLI the route table
can name". A route naming a tool is the policy's decision that the tool fits
the work, and the play entry is the string the ledger already counts as
`named`, so the reach and the naming meet on one name. `stack.tsv` declares how
a tool is installed, which is not what a shell command runs.

Two consequences, found in review. A reach counts under its name's owner, and a
plugin of the same name shares it: a run of the `semgrep` CLI credits the
`semgrep` plugin that `stack.tsv` declares, and takes it off
`felix_ledger_partly`'s list. That is the question the list asks of a route
(the play pointed at semgrep, and the session ran semgrep). Whether the
plugin's own surfaces, its MCP server and skills, were what was used is a
question a CLI run does not answer. And `stack.tsv` already has a `cli` kind
(elenchus declares `cli strix-agent`), whose names this does not read. A
declared `cli` row that a session runs from the shell keeps its zero row until
it does: a follow-up.

D2. **A names file per session, written at session start.** The post-tool hook
must not resolve the project: resolution runs git, and git after every tool
call is what the hook's comment forbids. Session start resolves the project
anyway. Per session, not per home, because each project has its own routes,
and a session's reach belongs to its project's ledger. Beside the session's
appends, under `state/ledger/`, so it lives and is found where they are; the
`.names` suffix keeps it out of every `*.tsv` glob over that directory.

D3. **`cli` replaces `tool Bash` for the call.** A Skill call is recorded as
`skill <name>` and not also `tool Skill`, an Agent call as `agent <type>`, an
MCP call as `mcp <server>`: the record names what the call reached, not the
tool that carried it. One line per run also keeps the fold's wholeness test
(alive lines against call lines) exact: a second line per call would read a
lost run as whole. The cost is that `Bash`'s REACHED column no longer counts
the calls that ran a capability: 92 of the 1,313 commands that mention a name,
across every transcript on this machine.

D4. **Read in bash, bounded, precision first.** No process (C1), so no awk:
the engine's readers that do this properly (`lib/deny-read.sh`,
`lib/where-read.sh`) are awk programs. A miss leaves the call as it is today; a
false reach would take a capability off the retire list on evidence of nothing,
and keep a route that is ignored. So everything the reading cannot follow ends
it (R9) rather than guessing, and text a command only carries never counts
(R6).

D5. **No backfill.** The ledger never recorded the command, and rewriting a
record to change its shape is the one operation the ledger's own header rules
out. The baseline is re-read from the transcripts with this reading, and the
pull request reports what it adds.

D6. **Out of scope, found on the way.** A Skill call that invokes a standalone
skill declared as `skill <name>` in `stack.tsv` (graphify's own declaration) is
filed under `<name> (built-in)` by `felix_ledger_summary`, because an
unqualified skill row is read as the host's. graphify's 3 Skill reaches sit
there today. And `felix_route_step_used` asks the transcript whether a play
step was used and does not see a CLI run either, so the route keeps naming
graphify as due in a session that ran it. Both are follow-ups.

D7. **The reading follows constructs no real reach passed through.** A review
measured a reading that ends at `case`, `[[ ]]`, function bodies, `${...}`,
`$'...'`, arrays and arithmetic instead of following them. It is about 130
lines shorter, gives the same answer on all 2,151 real commands that hold a
name, and turns 19 blind assertions from reaches into misses, none into a false
reach. It is not taken. A session plausibly writes those shapes before a tool
(`cd "${d}" && graphify ...`, `[[ -d out ]] && graphify ...`), the corpus is
one person's, and following them costs about 0.2 ms, paid only when a name is
in the command.

---

## 9. Amendment, 2026-11-06: the declared CLI, the route step, the session id

Written against the tree at 7096f618 (engine 0.49.321, with sections 0 to 8
above built). It closes three follow-ups that sections D1 and D6 left open and
the handoff for 0.49.321 listed. Behaviours are numbered as above and are meant
to become assertions. Sections 0 to 8 stand; where this section says a name or
a bound differently, this section is the later word.

### 9.1 Why, in one paragraph

A reach is only as complete as the names and the readers around it. (a) Session
start writes the names a session can reach from the play entries of
`routes.tsv`, so a CLI that `stack.tsv` declares with its own `cli` kind
(elenchus: `cli strix-agent`) and that no route names is never a name, a
session that runs it records `tool Bash`, and its stack zero row says it was
never reached. (b) `felix_route_step_used` asks only the transcript whether a
play step was used, so a session that has run `graphify` is told, on its next
prompt, that graphify is the step still due, and at Stop that it skipped it.
(c) `felix_ledger_session_id` runs a regular expression over the whole payload,
which is up to 4 MB, after every tool call, where the Bash reading already cuts
its payload to a leading window of 32,768 bytes.

### 9.2 The declared CLI (N7, N8)

N7. **A name from `stack.tsv`.** A name (N2) is also the second field of a
row of the session's project's `stack.tsv` whose first field is exactly `cli`,
when that field meets N2's byte rule as it stands (`A-Z a-z 0-9 . _ + -`,
starts with a letter or a digit, at most 64 bytes). The field is taken whole:
`strix-agent` is a name, `strix-agent@x`, `a/b` and `-` are not, and nothing is
stripped from it. Rows are read for their tab-separated fields as written: a blank row,
a row whose first field is empty or starts with `#`, and a row with an empty
second field (`cli`, two tabs, a third field) are skipped, and a last row with
no newline counts. A carriage return is not stripped, so a name followed by
one is not a name. (The fold reads `stack.tsv` with a tab in `IFS`, which runs
two tabs together; such a row keeps a zero row under the third field's name
there. That is a stated limit of the fold, not changed here.) A row of any
other kind (`plugin`, `skill`, `mcp`, `marketplace`, `hook`, or a word the
engine does not know) is never a name here, whatever its second field is, and
neither is a kind that only starts or ends with `cli` (`cli-extra`, `xcli`).
The kind is compared byte for byte and case-sensitively: `CLI` is not `cli`.

N8. **Order, once, and the cap.** The names file (N1, N3) holds the
`routes.tsv` names first, in N3's order, then the `stack.tsv` names in row
order. Each name appears once in all: one that both files give is where
`routes.tsv` put it. N3's cap of 32 counts both kinds together, in this
order, so a project whose routes already give 32 names gets no declared CLI,
and the 33rd name of the two is not written. A project with a `stack.tsv` and
no `routes.tsv` gets the declared names; a project with neither, or with
neither kind of name, gets one empty line, as N3 says. Everything N4 and N5
say of the file (replaced whole, a link replaced, a directory left, a usable
session id, an ungoverned directory) holds for it unchanged.

N9. **What follows.** Because the names file now holds a declared CLI's name,
P1 to P7 apply to it without change: a Bash call that runs `strix-agent` as a
program (R) is recorded as `cli\tstrix-agent`, and a call that only mentions
it is not. The fold needs no change (F1, F2): in a session with a
`cli\tstrix-agent` reach it writes the reach row and no zero row for the
`stack.tsv` declaration of `strix-agent`, and in a session without one it
writes the zero row as before.

### 9.3 A route step run as a program (U)

U1. **The step is used.** `felix_route_step_used TRANSCRIPT STEP [LEDGER]`,
where LEDGER is the path of a session's appends, `state/ledger/<session>.tsv`
(the file P1 appends to). Given a LEDGER that is a readable regular file, it
returns 0 for a STEP that is a name (N2's byte rule) when the file holds a line
that is exactly `cli`, a tab, and STEP, followed by a line break. It does not
need the transcript for this: with TRANSCRIPT empty, missing or unreadable,
and such a line in LEDGER, it returns 0.

U2. **Exact.** The line is compared whole, byte for byte, case-sensitively. A
STEP of `graphify` is not used by `cli\tgraphifyx`, `cli\tGraphify`,
`cli\tgraph`, `cli\tgraphify extra`, by a line of any other kind with the same
name (`tool`, `named`, `skill`, `mcp`, `agent`, `answer`, `alive`), or by a
line that holds `cli\tgraphify` anywhere but as its whole. A STEP that is not
a name (a `:` or an `@` in it, a `/`, `-`, or one longer than 64 bytes) is
never used by this. In particular a qualified step (`superpowers:brainstorming`,
`semgrep@claude-plugins-official`) is not satisfied by a `cli` line of its
plugin's bare name.

U3. **Nothing else changes.** With LEDGER omitted, empty, missing, a directory
or unreadable, and with a LEDGER that holds no such line, it returns what it
returned before this section, for every transcript. Every signal it read from
the transcript still counts when LEDGER is given: a step used by the
transcript is used.

U4. **The functions that ask it.** `felix_route_due TRANSCRIPT PLAY [LEDGER]`
and `felix_route_skipped TRANSCRIPT PLAY [LEDGER]` take the same optional
LEDGER and hand it to each step they ask about, and `felix_route_render PROJ
NAME PLAY ROOT PSCORE TRANSCRIPT [LEDGER]` hands it to `felix_route_due`.
With LEDGER omitted each prints exactly what it printed before. With a LEDGER
whose file holds `cli\tgraphify`, a play `graphify claude-md-management` has
`claude-md-management` due and not `graphify`, and skips neither when both have
been run; a play whose every step is used has nothing due and nothing skipped.

U5. **The hooks hand it over.** `hooks/user-prompt` hands the session's
appends, `<home>/state/ledger/<session>.tsv`, to `felix_route_due` (the due
step that keys the announcement) and to `felix_route_render`, and
`hooks/stop` hands it to `felix_route_skipped`, when the payload's
`session_id` is usable (N5). When it is not usable, or the file does not exist
yet, they hand none and behave as before. Observable through the hooks: in a
session whose appends hold `cli\tgraphify`, the route block that the prompt
hook injects for a play `graphify claude-md-management` does not name graphify
as the step wanted, and the Stop hook's list of steps the session skipped does
not hold it; in a session whose appends hold only `tool\tBash`, both are as
before. Stop still says nothing about skipped steps when the payload names no
transcript, as before.

U6. **No new cost.** U1 reads the file once per step and starts no process in
the post-tool hook (it is not reached from there). In the prompt and Stop
hooks it adds at most one read of a file per play step and no `git`.

### 9.4 The session id, bounded (W)

W1. **A leading window.** `felix_ledger_session_id RAW` looks for the key only
within the first 32,768 bytes of RAW, counted in bytes in any locale, the
bound `felix_ledger_signal` puts on a Bash payload (R0). The key, its colon,
its value and the value's closing quote must all lie within that window. The
first such `"session_id": "value"` in the window is the session, as before. A
payload whose first `session_id` begins in the window and is not closed by
byte 32,768, and one whose first `session_id` lies past it, name no session:
the function returns 1 with the variable empty, and does not look further.

W2. **Everything else as it was.** For a payload whose first `session_id` lies
wholly within the window, the function returns what it returned before: 0 with
the variable set to the value when the value is non-empty; 1 with it empty
when the value is empty or no key is present; the first `session_id` and not a
later one; blanks allowed around the colon. Claude Code writes the key first,
so every payload it sends today is in this case, with a 4 MB tool response
after it too.

W3. **Through the hooks.** `hooks/post-tool` and `hooks/session-start` take
their session from this function. A PostToolUse payload of 4 MB whose
`session_id` is at its start records one `alive` line and one call line in
that session's file, as before. A payload whose only `session_id` lies past
32,768 bytes exits 0 and records nothing for the call: the hook has no session
to record it for, as for a payload with no `session_id` at all.

W4. **Bytes, in any locale.** The window is 32,768 bytes under a UTF-8 locale
too: a payload whose key's closing quote falls on byte 32,768 is found and one
whose closing quote falls on byte 32,769 is not, however many characters
that is, and a multi-byte character before the key counts its bytes. The match
runs under `LC_ALL=C` (C5), and nothing in the function depends on the bash
version beyond 3.2.

W6. **The hook hands on the window.** `hooks/post-tool` gives the function the
first 32,768 characters of the payload, not the payload: handing a 4 MB string
to a function as an argument is most of what the call costs (about 19 of 25 ms
of CPU measured on this Mac for a 4 MB payload with the key first, against 5 ms
when the hook cuts). A character is at least a byte, so what the function
receives holds the whole byte window (W1) whenever the payload does, and it cuts
the rest itself. The result is W1 to W4 exactly, through the hook (W3).

W5. **Cost.** No new process (C1, C2). On a 4 MB payload with the key at its
start the function costs no more CPU than on a payload of 32,768 bytes plus
what handing the argument to a function costs, and under C4's bound. The pull
request reports the CPU of the function before and after on a 4 MB payload,
measured with `getrusage`, as the minimum of several runs.

### 9.5 Decisions

D8. **The declared kind is the only addition to the names.** `stack.tsv` also
declares `plugin`, `skill`, `mcp`, `marketplace` and hook rows. A plugin's name
is the owner a reach credits through its surfaces, and a CLI run does not say
which of them was used (D1), so these stay out. The `cli` kind is by its
definition what a session runs from the shell, which is what R reads.

D9. **Routes before declarations, and one cap.** The route table is the
policy's decision that a tool fits the work, so its names come first when the
cap binds. 32 is N3's cap, kept: the names file is read on every Bash call that
holds a name, and its length is what that read pays for.

D10. **The ledger, not the transcript, for a CLI run.** A transcript records a
Bash call as a tool use with its command text, and finding a run in it would
mean reading shell grammar a second time and holding the command. The ledger
already holds what the first reading decided, as a name and nothing else, so
the step asks the ledger. The cost is that a run the first reading did not see
(R10) is not used here either, which is the same answer the ledger gives.

D11. **A window, not a scan.** The key is the second field of the payload
Claude Code writes, after the event name and before the tool; a bound of
32,768 bytes is a thousand times what precedes it. A payload where it lies
past the bound is not one Claude Code writes, and the cost of mistaking it for
"no session" is a call not recorded, the same cost as a payload with no
`session_id`. The alternative, a scan for the key without a regular
expression, would cost a loop in bash over 4 MB where it now costs a cut.

D12. **Out of scope.** D6's first follow-up, a standalone skill declared
`skill <name>` filed under `<name> (built-in)`, is not part of this section.
