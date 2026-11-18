# Contract: a pipe's reader reads to the end (rev 3, 2026-11-16)

**Scope.** The pipes in the engine's code (`engine/harness/felix`, `lib/*.sh`,
`bin/*`, `hooks/*`, and the suite's own `tests/run` and `tests/lib/*`) whose
reader leaves before its input ends, where that reader is one of: an awk program
that can `exit` before its input is read, `head`, `sed` with `q`, or a `grep`
that can stop early. It covers what each of those sites prints, a lint for the
awk shape, and a behavioural test of the site that failed CI. Open, and not
answered here: the readers and producers listed under PR8.

## Why

On 2026-11-16 CI run 43865092616 (PR #518, the step 4 setup slice) failed part
1870's A16, which counts any output that names the judging copy
`felix-merge-main.*`. Its output held:

    .../felix-merge-main.XXXX/engine/harness/lib/instrument.sh: line 83: printf: write error: Broken pipe

`_felix_instr_sha` (lib/instrument.sh) runs `printf '%s\n' "$1" | awk '... {
print m[3]; exit }'` over a tree listing. The awk leaves at its first match
while printf is still writing; bash 3.2 writes a list one `write()` per line, and
bash 5 in chunks, so any listing past a pipe's 64 KB with the match early leaves
printf blocked on a full pipe when the reader goes. Its next write then fails:
- where SIGPIPE is at its default, printf dies of it, and under `set -o
  pipefail` the pipeline's status is 141;
- where SIGPIPE is ignored, as on the GitHub Actions runner, printf gets EPIPE,
  bash prints `printf: write error: Broken pipe` with the script's path on
  standard error, and the pipeline's status under pipefail is 1.

Measured on this Mac (bash 3.2.57) with a 604 KB listing whose first line is the
match: SIGPIPE ignored gave status 1 and that line; SIGPIPE at default gave 141
and no line. The blob id printed was right both times. Part 1870 alone with
SIGPIPE ignored passes, because the judge's real listing and its match position
vary with load and tree, so CI saw it once.

The lesson of 2026-09-25 (memory `lessons.md`: "Never pipe a variable into an
early-exiting reader") names this shape for grep -q, grep -m, head, awk exit and
sed q. #376 fixed fifty grep sites and added part 0960's lint, which sees grep
alone; its comment says it does not see head, sed q or an awk that exits.

Words. *A reader leaves early* when it can stop reading its standard input
before end of file. *Shell-fed*: a stage before the reader, in the same
pipeline, is shell code: the `printf` or `echo` builtin, a shell loop (`done |`)
or a shell function. *Program-fed*: every stage before it is a program reading
files, the system or git.

## PR1. `_felix_instr_sha` reads its listing to the end

`_felix_instr_sha LISTING PATH` (lib/instrument.sh). LISTING is `git ls-tree
-r` output: lines `<mode> <type> <id><TAB><path>`. It prints the id of the first
line whose path is exactly PATH and whose type is `blob`, then one newline, and
nothing when there is none. Lines with that path and another type are passed
over. This is today's output and it does not change.

What changes: for any LISTING, under `set -o pipefail`, with SIGPIPE ignored and
with SIGPIPE at its default, the function writes nothing to standard error and
returns 0. That holds for a listing of 256 KB or more whose matching line is the
first, which fails on the base engine (in the measurement above: status 1 and
the write-error line when ignored; 141 when at default). The same listing with the match on its last
line, and a listing with no match, pass today and still pass.

`_felix_instr_text` and `_felix_instr_tofile` find their blob through it, so
they hold the same.

## PR2. `_gt_detail` and `_gt_class` read felix merge's output to the end

Both live in the land tick's libraries and read `felix merge`'s output, which
holds about a hundred lines when a judgement has escapes.

`_gt_detail OUTPUT` (lib/green-tick.sh) prints, without a trailing newline, the
first line of OUTPUT that begins with two spaces; when there is none, the last
line that holds a non-blank character.

`_gt_class STATUS OUTPUT` (lib/green-install.sh) prints `hourly`, with no newline,
when STATUS is not `3`. Otherwise it reads the block that follows the first line
that is exactly `not merging`: past one empty line if the next line is empty, to
the next empty line. Over the block's lines: a line whose first two fields are
`base provider` sets p; a line whose first field is `not-green` or `unverified`
sets h when its second field is `tests`; any other line, except one whose first
two fields are `commission receipt`, sets b. It prints, then a newline: when p,
`hourly` if the block is that one line, else `final`; otherwise `receipt` when
the block has a line and b is unset and h is unset, `hourly` when the block has a
line and b is unset and h is set, and `final` otherwise. Lines after the block
are not read as part of it, whatever they hold, including a second `not
merging`.

For each, with an OUTPUT of 256 KB or more whose deciding line comes first (the
first two-space line; the block right after a first-line `not merging`) and the
bulk after it: under `set -o pipefail`, with SIGPIPE ignored and at its default,
nothing on standard error and status 0, and the output as above. On the base
engine `_gt_class` fails both ways. `_gt_detail` fails only with SIGPIPE
ignored: its cut-off printf sits in an assignment whose status is not the
function's, so at the default it already reads clean.

## PR3. No awk reached through a pipe exits before its input ends

In the files of the scope line, no awk program that reads a pipe holds an `exit`
outside its END action. Where one did, the program now reads to the end and
prints what it printed before: a flag set where it left, every rule after it
passed over while the flag holds, and the END action, if any, unchanged.

One site keeps its exit on purpose, and the lint holds it by name:
`lib/inventory-orphans.sh`, the awk that reads the loop of `find` over ignored
directories (`++n > 2000 { p = 1; exit }`). Nothing it cuts off is shell code:
`find` and `/usr/bin/printf` write the pipe, and the loop's status is not read,
so no bash write error and no status rests on the cut. The cut stops the walk
only where SIGPIPE is at its default. Where it is ignored, each `find` takes
EPIPE and walks on, and its "Permission denied" lines reach the file the
unreadable count is read from, so that count can differ by disposition (PR8).

## PR4. The lint

A matcher that prints `FILE:LINE` for each line where a pipe hands its output to
an awk whose program holds `exit` outside any END action. It reads like part
0960's `_spl_scan`:
- a `|` that is not half of `||`; a pipe that ends a code line (before an
  optional comment, or a backslash) carries to the next code line, and a line
  may start with `|`; comment lines are skipped;
- after the pipe, optionally `command`, `env`, `nice`, `timeout N`, `if`, `!`,
  `VAR=value` prefixes and a leading backslash; then `awk`, `gawk`, `mawk` or
  `nawk` as a word, or a variable whose name ends in `AWK` (`"$_AE_AWK"`,
  `$AWK`, `"${X_AWK}"`), which names an awk. A prefix's value may be quoted and
  hold blanks or a `$( )`: `X="a b" awk`, `P="$1" N="$t $(r) " awk`;
- the shell line's code ends at a `#` that follows a blank outside quotes: a
  trailing comment is not code, so a `| awk` written in one is not read;
- options before the program: `-F` and `-v` with their argument attached or as
  the next word, quoted or not, and `--`. `-f` means the program is in a file,
  which is not read;
- the program is the first argument after the options, single-quoted, and may
  run over several lines to its closing quote; awk's own arguments may carry
  past a backslash that ends a line; a program held in a variable or in double
  quotes is not read;
- inside it, `exit` as a word. Not a word: `exitcode`, `do_exit`. Not counted:
  text in a double-quoted awk string; an awk comment, from a `#` that begins a
  program line or follows a blank to the end of that line; anything inside the
  braces of an action whose pattern is `END`. Counted: an exit in a BEGIN action
  (awk then reads no input at all), in a function body, or in any other rule; a
  regex literal is read as code, so `/exit/` counts. A `/` where awk expects an
  operand (at the start of a pattern, after `(`, `,`, `!`, `~`, `&&`, `||`, `{`,
  `;` or a newline) opens a regex literal, which runs to the next `/` not escaped
  and not inside a bracket expression; a `"` inside a regex literal opens no
  string, so in `/"/ { print; exit }` the exit counts.
The flagged line is the one that holds the awk word.

Scan set: `felix`, `lib/*.sh`, `hooks/*`, `bin/*`, `tests/lib/*` and `tests/run`
of the harness under test. Not `tests/parts/`, which hold samples, and not
`templates/`.

The allowance is exactly one entry, PR3's: a flagged line in
`lib/inventory-orphans.sh` whose text holds `++n > 2000 { p = 1; exit }`. It is
read from a list in the test with the reason beside it. An allowance that no
flagged line matches fails, so a moved or fixed site cannot leave it behind.

On the base tree the scan names the sites this contract fixes and the
allowance's (32 lines: the 29 rev 2 counted, and bin/authority-engine's three
awks named through `"$_AE_AWK"`, at 105, 157 and 286 on the base tree), among them lib/instrument.sh's
`_felix_instr_sha`; on the fixed tree it names none past the allowance.

## PR5. `head` fed by shell code reads to the end

In the files of the scope line, a `head` that a shell-fed pipe reaches is
replaced by a reader that reads its input to the end and prints the same bytes:
`LC_ALL=C sed -n 1p` for `head -1` or `head -n 1`, `LC_ALL=C sed -n '1,Np'` for
`head -N` with N a number, and `{ head ARGS; cat >/dev/null; }` where N is a
variable. On a last line without a newline, macOS and GNU sed print it without
one, as head does. This is not linted (PR8).

Program-fed `head`s stay as they are (PR8): `git` dies silently on EPIPE whatever
SIGPIPE's disposition, and `find ... | head -n 1` uses the cut to stop a walk.

## PR6. The grep in the suite's library

`tests/lib/audit.sh`'s `_au_resume` pipes `_au_first "$_auo"` into `grep -qiE`.
It reads a here-string of the same text instead, as #376's sites do. Part 0960's
scan set is not widened to `tests/lib` here (PR8).

## PR7. What does not change

For every input, each site prints the same bytes on standard output as before,
and where no reader left early, the same status and standard error.

## PR8. Open

Found in the sweep and not changed here, each for its own change:
- Program-fed `head` (about thirty sites: `sed -n ... FILE | head -1`,
  `git ... | head`, `find ... | head -n 1`, `git cat-file blob | head -c 8000`).
  Under SIGPIPE ignored, a GNU tool among them prints its own write error where
  its standard error is not redirected.
- `cmp -s -` fed by a pipe, which stops at the first difference: lib/discover.sh
  (`tr | cmp -s - FILE`) and lib/memory.sh (`felix_mem_mistake_rows | cmp -s -`).
- `read` in a group fed by a pipe: lib/commission.sh's ask (`... | { read -r _l;
  ... }`), whose writer's standard error is already discarded.
- A `while read` loop fed by a pipe that breaks or returns, as in
  `felix_guard_culprit`. Not swept.
- A lint for the shell-fed `head` and `sed q` shapes, and part 0960's grep scan
  over `tests/lib` and `tests/run`.
- The find loop in lib/inventory-orphans.sh (PR3's allowance): where SIGPIPE is
  ignored its walk is not bounded by the cut, and its unreadable count reads
  directories past the 2,000-file cut that the default would not reach.
- Whether CI should run with SIGPIPE at its default. The engine runs on hosts
  that ignore it, so the code is fixed and not the runner.

## Revisions

Rev 2: the blind author of part 2500 found two clauses that did not hold on the
base engine and asked about two readings. `_gt_class` prints `hourly` with no
newline when STATUS is not 3 (rev 1 said a newline). `_gt_detail` at the default
SIGPIPE already passes (rev 1 said it failed). PR4 now says that awk's arguments
carry past a backslash-newline and that a regex literal is read as code, as the
part reads them. No assertion changes: the part pinned neither rev 1 clause.

Rev 3, from three adversarial reviews of the build:
- Three awks the sweep missed, in bin/authority-engine, run awk through
  `"$_AE_AWK"`, which rev 2's lint could not see; a reviewer found two, and the
  author of the amended part found the third (line 157, whose exit sits two
  lines below the awk word). PR4 now reads an awk named through a variable whose
  name ends in `AWK`, and the base count is 32.
- Three shapes rev 2's matcher read wrong: a prefix whose quoted value holds a
  blank (three such awks are in the tree, none exiting), a `"` inside a regex
  literal (the exit after it went unseen), and a `| awk` in a trailing shell
  comment (flagged, though it is no code). PR4 now names each.
- PR3's allowance said its cut bounds the walk. That holds only where SIGPIPE
  is at its default; PR3 says so, and PR8 lists the rest.
- `_gt_class`'s `hourly` with no newline (rev 2) is now compared exactly.

## Tests

Two blind parts. `tests/parts/2500-pipe-readers-read-to-the-end-blind.sh` holds
PR1's and PR2's cases: large inputs, SIGPIPE ignored and at its default, with
their controls. `tests/parts/2501-pipe-readers-lint-blind.sh` holds PR4's
matcher on written-out samples, its allowance and its scan of the harness. One
author wrote the first form from rev 1. A second amended it from rev 3 and moved
the lint into 2501, keeping every assertion name.

Each part was run alone through a one-part runner, not `tests/run`, on this Mac:
- rev 1's part, 50 assertions: main's engine 42 ok, 8 FAIL; the first fix
  (e7c90797) 50 ok. Four copies of that fix, each with one fix undone (main's
  lib/instrument.sh, main's lib/green-install.sh, the exit put back in
  lib/bootstrap-gh.sh, the exit put back in bin/obligations-check), failed 5,
  3, 1 and 1 assertions, each naming its site.
- rev 3's parts, 34 and 24 assertions: main's engine 27 ok and 7 FAIL, and 23 ok
  and 1 FAIL (the scan, naming 31 lines past the allowance). The commit before
  the last fix fails the scan at bin/authority-engine:157 alone. The fixed tree
  passes 34 and 24. The amendment's 8 new samples each failed when run against
  rev 2's matcher.

Engine 0.49.359. It was 0.49.353, then 0.49.357, while #521, #520 and #523 landed as 0.49.355, 0.49.356 and 0.49.358.
