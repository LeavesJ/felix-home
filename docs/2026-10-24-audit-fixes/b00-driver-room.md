# Audit batch b00: room in the test driver

Batch b00 of the audit fixes of 2026-10-24, branch `claude/audit-b00-driver-room`,
cut from origin/main at 69b51a61 (0.49.307, #460). Engine tier, tests only.
New parts are numbered in 1610-1629. Nothing here changes what the suite runs:
the driver loses comment lines, the explanations they held go next to the code
they explain, and one new part holds the driver to its new shape.

The brief (`batches/b00.json`) lists no auditor defect. It carries one
requirement, in its notes, written R1 below. This batch lands first: about 22
batches after it each add one or two lines to the driver.

## 1. Defects

**R1. The driver has three lines of room, and about 22 batches each add one or
two.** `engine/harness/tests/run` is 497 lines on 69b51a61, and part 1040 holds
it to 500 (`[ "$(awk 'END { print NR }' "$HERE/run")" -le 500 ]`, its line 27).
Each batch adds a part line, `. "$HERE/parts/NNNN-name.sh"`, and some add a lib
line. Scenario: the fourth such line takes the driver to 501, part 1040's "and
the driver itself is under 500 lines" fails, and every gate after it is red
until someone frees lines in a hurry. That is when a loop over the parts gets
written, which part 1040 (lines 11-15) forbids: in bash 3.2 an arithmetic error
inside `$(( ))` discards the whole top-level command it sits in, so a loop
would discard the rest of the suite. Or code gets moved, which is what freed
the last room on 2026-10-17 (part 0004, lines 4-6).

Measured on 69b51a61: 193 part lines, 47 lib lines, 133 other code lines, 111
comment lines (the shebang among them) and 13 blank lines, so 257 lines that
are neither part nor lib lines. After the opening block, 19 comment runs are
longer than two lines. The longest, lines 64-71 (`_ran_rows`'s history) and
76-83 (`_manifest_short`'s), are eight lines each, and part 0770 already says
both.

## 2. Required behaviour

Definitions, used by every item:

- **Driver**: `engine/harness/tests/run`. **Line**: as awk counts NR; a last
  line with no newline is a line.
- **Part line**: a line that is exactly `. "$HERE/parts/NAME"`, NAME holding no
  `"` and no `/` (the shape part 1040 reads). **Lib line**: the same with
  `lib/` for `parts/` (the shape part 1290 reads). A line with leading blanks, a
  trailing comment, or a `/` in NAME is neither.
- **Comment line**: a line whose first character that is not a space or a tab
  is `#`. A code line with a trailing `# ...` is not one.
- **Opening block**: every line before the first line that is exactly
  `set -uo pipefail` (lines 1-16 on the base: the shebang, the title, the usage).
- **Comment run**: a maximal run of consecutive comment lines. A blank line
  ends a run.
- **Frozen region**: from the line `# The names defined so far, one a line, for
  _lib_clashes: a lib file may not take one.` through the line
  `. "$HERE/parts/9990-the-run-stayed-inside-its-temporary-directory.sh"`, both
  included: lines 157-412 on the base, 256 lines, holding the lib block, the
  hand-over and every part line from 0010 to 9990.
- **Base**: 69b51a61. If main moves before this lands, the base is
  `git merge-base HEAD origin/main`, and the part lines another batch landed are
  base lines.

**B1. Room for part and lib lines.** The driver holds at most 197 lines that
are neither part lines nor lib lines (257 on the base: at least 60 freed).
`LC_ALL=C awk '!/^\. "\$HERE\/(parts|lib)\/[^"\/]+"$/ { n++ } END { print n + 0 }' engine/harness/tests/run`
prints 257 on the base and at most 197 after. Part 1040's 500 then leaves at
least 303 lines for part and lib lines; this batch leaves 241 of them used (194
part lines, its own among them, and 47 lib lines), so at least 62 are free. At
this change `awk 'END { print NR }'` on the driver prints at most 438. The
bound is permanent, and later batches never meet it by adding parts or libs,
since a part line or a lib line does not count. Part 1040 still passes.

**B2. No long explanation is left in the driver.** After the opening block, no
comment run is longer than two lines. On the base 19 are, starting at lines
28, 37, 45, 52, 60, 64, 76, 99, 113, 128, 145, 414, 420, 434, 442, 456, 463,
469 and 488. A pointer is one line wherever one line carries it, never more
than two. The opening block is exempt (it counts toward B1). Unknown path: a
driver with no line exactly `set -uo pipefail` has no opening block to end; the
check fails and says it found no such line, and never reports "no long run".

**B3. Every pointer in a driver comment resolves.** Every comment line after
the opening block is read, one line at a time:

- (a) each `part NNNN` or `parts NNNN` (the word, one space, four digits) names
  a file `engine/harness/tests/parts/NNNN-*.sh` that exists;
- (b) each `receipt.sh, "TEXT"` names a TEXT that occurs in
  `engine/harness/tests/receipt.sh`, TEXT running from the `"` after
  `receipt.sh, ` to the next `"` on the same line;
- (c) each word read as a path names a file or directory that exists under the
  checkout root (`$REAL_HARNESS/../..`), under `$REAL_HARNESS`, or under the
  tests directory (`$HERE`). The words are the text after the line's first
  `#`, split on blanks. From each word, leading `(`, `[`, `"`, `'` and backtick
  are stripped, then trailing `)`, `]`, `,`, `.`, `:`, `;`, `"`, `'` and
  backtick, then one trailing `'s`, then the trailing set once more. A word is
  read as a path when it then ends in `.sh` or begins `tests/` or `engine/`. A
  word holding `*` or `$` is not read.

On the base all of them hold: 5 part pointers (0203, 0003, 0001, 0003, 0006),
2 receipt.sh pointers ("red, beside a record run", lines 115 and 146) and 11
path words (engine/harness/felix, tests/red, tests/run, receipt.sh). So B3 is a
control. Failure paths: each pointer that does not resolve is reported with its
line number and the pointer, and the check fails; a `receipt.sh, "` with no
closing `"` on its line is reported as a pointer that could not be read; a
receipt.sh that is missing or unreadable is reported, and every (b) pointer
then fails, none passing. What B3 does not read, said here rather than hidden:
trailing comments on code lines, the opening block, a `part` and its number
split across two lines, the second number of "parts 0005 and 0010", and
function names. So a pointer keeps `part NNNN` on one line.

**B4. What runs is unchanged.**

- (a) Outside comment lines and blank lines the driver is the base's plus one
  line.
  `diff <(git show <base>:engine/harness/tests/run | LC_ALL=C awk '!/^[[:space:]]*(#|$)/') <(LC_ALL=C awk '!/^[[:space:]]*(#|$)/' engine/harness/tests/run)`
  prints one hunk whose only changed line is
  `> . "$HERE/parts/1610-driver-room-blind.sh"` (the base against itself prints
  nothing: 373 lines each side). Lines leave only as whole comment lines or
  whole blank lines, and arrive only as whole comment lines and that one part
  line. No comment goes on a code line, and no trailing comment changes (lines
  72 and 84).
- (b) The frozen region is byte for byte the base's, but for the 1610 part line
  inserted in name order right after the 1600 line:
  `LC_ALL=C awk '/^# The names defined so far/,/^\. "\$HERE\/parts\/9990-/'` on
  both sides, diffed, shows that one added line and nothing else. The reason is
  projects/felix/land.tsv: tests/run lands by insertions-union, which merges two
  sides only when every conflict is two insertions. Every other batch inserts
  its part or lib lines in this region, and a deletion beside one of them would
  make that landing a conflict no rule resolves.
- (c) The block part 0770's red fixtures lift (`_red_helpers`, part 0770 line
  412: `awk '/^PASS=0; FAIL=0/ { on = 1 } on { print } on && /^skip\(\)/ { exit }'`)
  still begins at the driver's one line starting `PASS=0; FAIL=0` and ends at
  the first line after it starting `skip()`, and its code lines are the base's.
  Its comments may shrink.
- (d) Line 1 is exactly `#!/usr/bin/env bash`, and the mode is still 100755
  (`git ls-files -s engine/harness/tests/run`).

**B5. Every explanation removed is still said, next to what it explains.** Each
comment run the change shortens either points at a file that already says what
it said, or moves its text there; section 3a names the home of each and the
line on the base where it already says it. Moved text goes in at the top level
of its destination, outside any quoted string, heredoc, awk program or function
body (in part 0005, never inside `_ff_case`, whose whole text part 0200 pins by
cksum). It names the jobs variable only as a `$` or `${` expansion (part 1291's
`_db1_jobs` reads comments in every file but 0001), and holds no `local`
assignment (part 0590's scanner reads every line of `_suite_files`). It leaves
its destination at or under 500 lines, and goes into no file already past 500:
not parts 0003 (932 lines), 0007 (835), 0203 (918), 0770 (856) or 1010 (746),
not tests/red (559), engine/harness/felix or projects/felix/gate.sh (652).
tests/receipt.sh is at 499 and gains no line: what the driver says about the
receipt is already in it.

**B6. The parts that read the driver or the suite's text pass alone.** Each set
below is run as
`( cd "$(mktemp -d)" && bash <worktree>/engine/harness/tests/run --part NAME... )`,
once under macOS BWK awk and bash 3.2 and once with gawk first on PATH. The
workflow's
`/private/tmp/claude-501/-Users-a14808-Documents-Felix--claude-worktrees-inventory-next-steps-fea035/758939f7-8603-48da-b32f-a7b91ff35acf/scratchpad/tools/alone.sh WORKTREE bwk|gawk NAME...`
does both, with INT and QUIT reset. After the change each set's result is
section 4's base result: the same exit status and no `  FAIL` line the base did
not print. A set that does not reach its summary, exits other than 0 or 1, is
killed, or prints no `  ok` line, is a failure to report, not a pass. A FAIL
from an assertion that bounds a time is re-run once alone; if it then passes,
it is named in the pull request as load, never dropped unsaid. Parts 0001-0009
and 9990 cannot run alone. They run as every set's prelude, so every set
exercises 0001 and 0004 with the moved text, and part 1040's "every part parses
on its own" reads them too. The sets, each contiguous in the driver's order:

- 0200
- 0202 0203
- 0440
- 0590
- 0640
- 0720
- 0770
- 0840
- 1010
- 1040
- 1200 1210 1220 1230-gate-friction-a-addendum 1230-gate-friction-a 1240
- 1250 1260 1270 1280 1281 1282
- 1283 1284 1285 1286 1287 1288
- 1289 1290 1291 1292 1293 1294
- 1295 1296
- 1500 1510
- 1600 1610 (after the change only)

0440 and 0640 write stub drivers of their own, and 0840 only names tests/run
inside audit fixtures: none of the three reads the real driver. They are in the
list the brief named, and are controls.

Part 1010 is the one set whose result moves for a reason outside this batch.
Its two record checks, "red.tsv was recorded against the engine origin/main
held where this tree branched from it" and "this engine's version is above
origin/main's when this tree holds commits origin/main lacks", skip on the base
and on this contract's commit ("this tree changes no engine file"). Once the
branch changes a file under engine/, tests included, both are owed (part 1010
lines 171-186), and they fail until the carrier records red.tsv and raises the
version in plugin.json, which this batch may not touch. Those two FAILs are
expected on the builder's branch and are the carrier's to clear; any other
FAIL in 1010 is not.

**B7. The change touches only these files**: engine/harness/tests/run,
parts/0001-the-origin-guard-and-the-temporary-directory.sh,
parts/0004-the-widget-fixture.sh, the new parts/1610-driver-room-blind.sh, and
this contract. `git diff --stat <base>` names no other file: no assertions.tsv,
red.tsv, plugin.json, receipt.sh, red, HANDOFF.md or docs/handoff/. A builder
who homes a moved explanation elsewhere names that file in the pull request and
meets B5 for it. Each file touched is at or under 500 lines (`wc -l`).

**B8. The new part is a part like the others.** One line sources it, in name
order (part 1040); it parses alone and is at most 500 lines. It reads only
`$HERE/run`, `$HERE/parts`, `$HERE/lib`, `$HERE/receipt.sh` and paths under
`$REAL_HARNESS/../..`, and writes only under `$TMP` (part 9990). It runs under
bash 3.2 and 5 and under BWK awk and gawk: LC_ALL=C for sort and comparison,
digits spelled `[0123456789]`, no gawk-only builtin, no `case` inside `$( )`,
no printf or echo of a variable piped into `grep -q` (part 0200), no git write
from a raw cd (part 0200's `_fx_lint`). An assertion that cannot read the file
it reads fails with a reason naming the file; none skips, none passes.

**Red first.** A1 and A5 fail on the base driver: shown by running part 1610
alone on the commit that adds it, before the commit that edits the driver.
tests/red cannot show it. Red runs this tree's tests/run and parts against the
base's engine, so the driver a red run reads is the new one, and red.tsv will
record these assertions passing. That is no evidence either way: red measures
the engine, not the driver.

## 3. What must not change

Each item is an existing behaviour the edit could break, and the parts that pin
it. All of them are among B6's sets or run as every set's prelude.

1. **Part lines, one per file, in name order.** Part 1040 (every file in parts
   sourced once in `LC_ALL=C` name order, none that is not there; NNNN-name.sh;
   the driver at most 500 lines; every part parses alone). Part 0001's
   `_sj_order` reads the part lines for `-j N` and `--part`, and `_sj_member`
   refuses a name the driver does not source (parts 1291-1296 test both). Part
   0007's runner relies on `alias .=:` turning the part lines after the
   hand-over into no-ops (driver lines 223-225, the unalias at 411).
2. **Lib lines and lib-before.names.** Part 1290: one line per tests/lib/*.sh,
   in name order, after the 0005 line and before the 0010 line; exactly one
   line outside a comment naming lib-before.names, after the 0005 line and
   before the first lib line. Part 0006 (`_lib_clashes`) reads
   `$TMP/lib-before.names`, and defines the `_vars` functions the driver calls
   at lines 208-211.
3. **The helper block** (B4c). Part 0770's `_red_helpers` and the red fixtures
   built on it (`_red_count`), and its two pins on driver code: exactly one line
   `_ran_rows < "$FELIX_TEST_RAN" > "$_ran_counts"` at column 1 (0770 line 112)
   and exactly one `  done < <(_manifest_short "$FELIX_TEST_MANIFEST" "$_ran_counts")`
   (line 131).
4. **The completion marker** `printf '\nreached\n'`: the last
   section-header-shaped line of `_suite_src` (0770 lines 750-758), the line
   tests/red's awk wants after the last assertion line (red line 476), and the
   end of the cut parts 0202, 0203 and tests/lib/gitproof.sh take (`_g3_mark`,
   `_gp_mark`).
5. **The record-mode branch**: `if [ "$FELIX_TEST_RECORD" -eq 1 ]; then`
   through its first `fi` at column 1, holding the one indented
   `_rt_judge "$REAL_HARNESS/../.."` (part 1010, lines 340-363).
6. **The lines before part 0001's `TMP="$(mktemp -d)"`** and before its
   `FELIX_TEST_RAN="$TMP/ran"`: the `REAL_HARNESS=` line, the check after it,
   `exec </dev/null`. Part 0203 ("the suite copies only a harness", lines
   872-917) runs the lines before `TMP=` as a child, with REAL_HARNESS
   rewritten after the line beginning `REAL_HARNESS=`; part 0005 (its checks 7
   and 8) runs the lines before `FELIX_TEST_RAN="$TMP/ran"`; parts 0202, 0203
   and tests/lib/gitproof.sh run the lines before the first `printf '\n` line.
7. **The caller-environment block** (driver lines 21-26) **and the git colour
   pin** (31-35). Part 1510 (the first command after `set` is the unset; the
   block after `set -u` equals engine/harness/felix's) and part 1500 (the pin's
   region parses and forks nothing). Both skip comment lines, so the pointer
   comments above them may shrink.
8. **The argument loop, the receipt calls, the manifest comparison and the
   summary** (lines 117-150 and 414-497). Parts 1200-1296 run copies of the
   driver made by part 0003's `_suite_copy_driver` and `_suite_copy_tree`
   (lines 836-912), with stub parts.
9. **The shebang and the executable bit.** Part 0720 (executable-check), part
   1500 (the executable files read include tests/run), part 1510 (`find -perm
   -u+x` reaches ./tests/run), and the gate's `executable` row
   (projects/felix/qualification.tsv line 184).
10. **The suite-text lints, which read the destinations too.** Part 0200
    (`_fx_lint` over `_suite_flat`; `_pfsites` over `_suite_src`, comment lines
    skipped), part 0590 (the self-reference scanner over `_suite_files`,
    comment lines read), part 1291 (`_db1_jobs`, comment lines read; `_db1_jc`
    on 0001, comments stripped), parts 0005 and 0200 (`_ff_case` by cksum).
11. **The section title a pointer quotes**: `red, beside a record run`, the
    header at receipt.sh line 379 (B3b reads it).

### 3a. Where each explanation lives

The base lines of each comment run the change shortens, what it says, and its
home after the change. "Already" gives the base line where the home says it,
and there the driver keeps a pointer only. "Moved" means the text goes there.

| Run | What it says | Home after |
|---|---|---|
| 4-10 | the claim under test: an invented project, no Elenchus, no remote | part 0004, above its `---- fixture ----` header (line 102). Moved, 7 lines |
| 19-20 | the caller's environment | engine/harness/felix, the comment above line 132. Already |
| 28-30 | git's colour pin | engine/harness/felix, the comment above line 210. Already |
| 37-40 | stdin is /dev/null: hooks/session-start reads a payload | no other home; kept in the driver, at most two lines |
| 45-47 | REAL_HARNESS must name a harness | part 0203 lines 872-882. Already |
| 52-54 | the driver's shape; why not a loop; `_suite_*` | part 1040 lines 3-15; part 0003 lines 796-806 and 913-918. Already |
| 57-58 | FELIX_TEST_RAN | part 0001 lines 445-461. Already |
| 60-62 | `_og_tick`; the lifted block stays silent under set -u | part 0003 line 662; part 0770 lines 395-412. The set -u reason stays in the pointer |
| 64-71 | `_ran_rows` keeps a name byte for byte; the fold before 2026-10-01 | part 0770 lines 104-108. Already (the mechanism, assigning to awk's `$1`, may ride in the pointer) |
| 76-83 | `_manifest_short`: one pass, 88 s, bytes, odd rows | part 0770 lines 113-131, the cases pinned by its assertions. Already |
| 99-104 | some skips describe the machine; a skip counts as reached | part 0001, in its comment at lines 445-461. Moved, about 4 lines |
| 113-116 | the manifest; `--record-assertions`; red beside it; FELIX_TEST_NO_MANIFEST | receipt.sh from line 379; tests/red lines 15-24. Already |
| 128-131 | the receipt and `--reuse`; a red run and part mode load none | receipt.sh lines 1-8 and 279-283; the if chain itself. Already |
| 139-140 | `_rcp_root`'s dots | kept in the driver (two lines or one) |
| 145-148 | red starts here, disowned, before part 0004's exports | receipt.sh lines 379-385 and 429-435. Already; the ordering against part 0004's exports stays in the pointer |
| 414-418 | the completion marker | tests/red lines 49-66 and 476; part 0770 lines 750-758. Already |
| 420-423 | #67; one way only; counted per name | part 0001 lines 445-461 has #67. The one-way rule and counting per name: moved, about 3 lines |
| 434-437 | red.tsv in the same diff; red's status its own | receipt.sh lines 484-485 (`_rcp_red_end`); tests/red lines 34-42. Already |
| 442-444 | the record judged again, record mode off | part 1010 lines 336-348. Already |
| 456-460 | a red run compares nothing | tests/red lines 20-24. Already |
| 463-467 | FAIL lines are the one channel to a CI log; .github/workflows is an escape | no other home (gate.sh is past 500); kept, at most two lines |
| 469-471 | names go through files, never `awk -v` | tests/red line 514; part 0770 lines 122-125 (the backslash case). Already |
| 488-491 | the receipt before the summary line | receipt.sh lines 304-306. Already |

With these, 67 lines go (to 190 by B1's count), and 60 without the move into
0004. Blank lines outside the frozen region may go too. Part 0001 grows by
about 7 lines to about 469, part 0004 by 7 to about 167.

## 4. Assertions

### In part 1610: A1-A12

Each check takes a driver file and the tests directory it is read against (for
the real driver, `$HERE/run` and `$HERE`). A plant is a file the part writes
under `$TMP` with exactly the text shown, every line newline-terminated unless
said otherwise.

**A1 (B1).** The real driver holds at most 197 lines that are neither part nor
lib lines; on failure the detail gives the count. Red on the base (257), green
after.

**A2 (B1, control).** On the real driver the count of part lines equals the
number of files in `$HERE/parts`, the count of lib lines equals the number of
`*.sh` files in `$HERE/lib`, and more than 0 lines were read, so A1 cannot pass
by reading nothing. True before (193, 47) and after (194, 47).

**A3 (B1, control).** This plant of 12 lines, whose line 7 is empty and whose
line 8 begins with two spaces:

```
#!/usr/bin/env bash
set -uo pipefail
. "$HERE/parts/0010-a.sh"
. "$HERE/lib/a.sh"
# a comment
. "$HERE/parts/0020-b.sh"

  . "$HERE/parts/0030-c.sh"
. "$HERE/parts/0040-d.sh" # a trailing comment
. "$HERE/lib/b.sh"
. "$HERE/parts/0050-e.sh"
. "$HERE/parts/sub/f.sh"
```

counts 7 other lines, 3 part lines, 2 lib lines and 12 lines. The same text
with no newline after its last line counts the same.

**A4 (B1, control).** The count over `$TMP/no-such-driver` is refused: a status
other than 0 and a message naming the path, never a count of 0.

**A5 (B2).** In the real driver no comment run after the opening block is
longer than two lines; on failure the detail lists each such run's first line
and length. Red on the base (19 runs), green after.

**A6 (B2, control).** The real driver has a line exactly `set -uo pipefail`
and at least one comment line after it, so A5 cannot pass on a driver read as
empty. True before and after.

**A7 (B2, control).** This plant of 20 lines, whose line 12 begins with two
spaces and whose line 14 is empty:

```
#!/usr/bin/env bash
# opening one
# opening two
# opening three
# opening four
set -uo pipefail
x=1
# two
# lines
y=2 # a trailing comment is code
# three
  # indented
# lines

# two again
# after a blank
z=3
# three at
# the end
# of the file
```

reports exactly two runs, starting at line 11 and at line 18, three lines
each: not the opening block (lines 1-5), not 8-9, not 15-16.

**A8 (B2, control).** This plant, whose line 2 begins with two spaces:

```
#!/usr/bin/env bash
  set -uo pipefail
set -uo pipefail # with a comment
# one
# two
# three
x=1
```

is refused: a status other than 0 and a message saying there is no line exactly
`set -uo pipefail`. It does not report "no long run".

**A9 (B3, control).** On the real driver, (a), (b) and (c) report nothing, and
at least one part pointer was read. True before and after.

**A10 (B3, control).** This plant, read against `$HERE`:

```
#!/usr/bin/env bash
set -uo pipefail
# see part 9999 for why
# and (receipt.sh, "no such section here")
# and tests/no-such-file.sh, which is gone
x=1
```

reports exactly three findings: line 3 `part 9999`, line 4 `no such section
here`, line 5 `tests/no-such-file.sh`.

**A11 (B3, control).** This plant, read against `$HERE`, reports nothing:

```
#!/usr/bin/env bash
# part 9999 in the opening block is not read
set -uo pipefail
# why: part 1040, and (part 0003's) helpers
# (receipt.sh, "red, beside a record run")
# `tests/receipt.sh`, engine/harness/felix's and tests/lib/*.sh and "$HERE/run"
x=1
```

**A12 (B3, control).** This plant, read against `$HERE`, reports one finding:
line 3, a receipt.sh pointer it could not read.

```
#!/usr/bin/env bash
set -uo pipefail
# (receipt.sh, "red, beside a record run
# x")
x=1
```

And the plant below, read against a tests directory under `$TMP` that holds an
empty `parts/` and no receipt.sh, fails: one of its findings says receipt.sh
cannot be read, and its (b) pointer is not passed.

```
#!/usr/bin/env bash
set -uo pipefail
# (receipt.sh, "red, beside a record run")
x=1
```

### Checked by command at review, not in a part: A13-A19

- **A13 (B4a).** The `diff` of B4a prints one hunk whose only changed line is
  `> . "$HERE/parts/1610-driver-room-blind.sh"`.
- **A14 (B4b).** The frozen region's `diff` prints that one added line and
  nothing else.
- **A15 (B4c).** `awk '/^PASS=0; FAIL=0/ { on = 1 } on { print } on && /^skip\(\)/ { exit }' engine/harness/tests/run | awk '!/^[[:space:]]*(#|$)/'`
  prints the same lines on the base and after.
- **A16 (B4d).** `head -1` prints `#!/usr/bin/env bash`; `git ls-files -s`
  shows 100755.
- **A17 (B5).** Read with 3a beside the diff: each removed run's substance is at
  its home; moved text sits at the top level; `wc -l` on parts 0001 and 0004 is
  at most 500; receipt.sh is unchanged.
- **A18 (B6).** Every set of B6, under both awks, against section 4.
- **A19 (B7).** `git diff --stat <base>` names only B7's files.

### The base's results for B6

Measured 2026-10-24, 10:41 to 11:44, with alone.sh from a fresh mktemp
directory, on 69b51a61 and then on this contract's first commit (3a84bdd6,
docs only, which no part reads as an engine change). The load average was 30
to 370 throughout, with the other batches running. Every set exited 0 with no
FAIL, and BWK awk and gawk gave the same counts. The ok counts include the
prelude's own assertions.

| Set | ok | FAIL | skip | bwk s | gawk s |
|---|---|---|---|---|---|
| 0200 | 141 | 0 | 0 | 278 | 256 |
| 0202 0203 | 181 | 0 | 0 | 161 | 124 |
| 0440 | 100 | 0 | 0 | 158 | 180 |
| 0590 | 127 | 0 | 0 | 26 | 19 |
| 0640 | 105 | 0 | 0 | 14 | 12 |
| 0720 | 127 | 0 | 0 | 67 | 65 |
| 0770 | 168 | 0 | 0 | 35 | 37 |
| 0840 | 84 | 0 | 0 | 59 | 42 |
| 1010 | 136 | 0 | 2 | 12 | 13 |
| 1040 | 67 | 0 | 0 | 7 | 5 |
| 1200-1240 | 268 | 0 | 0 | 93 | 80 |
| 1250-1282 | 420 | 0 | 3 | 255 | 237 |
| 1283-1288 | 462 | 0 | 2 | 187 | 177 |
| 1289-1294 | 470 | 0 | 0 | 1706 | 1661 |
| 1295 1296 | 152 | 0 | 0 | 321 | 291 |
| 1500 1510 | 157 | 0 | 0 | 39 | 47 |
| 1600 | 350 | 0 | 0 | 41 | 28 |

The skips, all by design: 1010's two record checks (above, B6); 1250-1282's
B4 (no scutil-less host here) and two A4 watchdog rows (no seam shortens 30
minutes); 1283-1288's A10 (no ledger for a tick with no project) and A15 (the
same 30 minutes). After the change the same counts are expected. The
exceptions are 1600 1610, which adds A1-A12, and 1010 once engine files
change (B6). Every other set should reach its ok count with the same skips
and no FAIL.

## 5. Parts

One new part, `engine/harness/tests/parts/1610-driver-room-blind.sh`, holding
A1-A12, sourced by `. "$HERE/parts/1610-driver-room-blind.sh"` right after the
1600 line. No groups.tsv entry: it runs as a unit of its own. Its assertion
names are new, so the manifest lists them only after the carrier's record;
until then a full run notes them as ran and unlisted, which is not a failure.
1611-1629 stay unused.

## 6. Out of scope

**Not fixed: not a defect.** The brief speaks of "the helper block tests/red
lifts out of the driver". tests/red never reads the driver's text: it copies
the file whole into the base's tree (red line 371). The lift is part 0770's
`_red_helpers` (line 412), which builds the red fixtures, and B4c is written
against that. A wording correction, not a defect.

- **tests/red line 71, "(tests/run says what that cost)".** A pointer into the
  driver that already resolves to nothing on the base: the cost (1429 s of the
  gate's 1565) is in receipt.sh lines 10-13. tests/red is 559 lines, and every
  change to it is a verifier read (risk.tsv line 45). The fix is the same line
  reworded, "(tests/receipt.sh says what that cost)". Left to a batch that
  edits tests/red.
- **Moving code out of the driver**, such as the manifest comparison (lines
  420-486) into receipt.sh or a part. It would free more, but it changes where
  code runs and what each copy of the driver carries (`_suite_copy_driver`,
  `_suite_copy_tree`, tests/red). The brief asks for comments only, and they
  give the 60.
- **A loop over the parts.** Part 1040 forbids it.
- **The trailing comments on lines 72 and 84.** They are code lines (B4a), and
  are kept.
- **The record (assertions.tsv, red.tsv) and the version in plugin.json.** The
  carrier's, by the batch rules. red.tsv will not show A1 or A5 red (section 2,
  Red first).
- **What B3 does not read** (trailing comments, wrapped pointers, a second
  number after "and", function names). Stated in B3 as gaps, not closed: each
  would widen a rule whose job is the pointers this batch writes, on one line.

## 7. Founder PR

None. The batch changes no .github/workflows file, no deny or escape row, no
commission grant, and publishes nothing. tests/run and the parts are yellow in
projects/felix/risk.tsv (line 42: the verifier reads them). land.tsv's
tests/run row (insertions-union) is unchanged; B4b is there so that it keeps
landing the batches after this one.
