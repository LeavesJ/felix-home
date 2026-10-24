# Audit b30: Plan A steps 5 and 6: unit facts, the tracer, and a selection report

The contract for audit fix batch b30 (P5, P6a, P6b). It is the whole
specification the blind parts are written from. It says what must be true, not
how. It was written against main at 69b51a61 (0.49.307). It was read against
`tests/run`, parts 0001, 0003 (`_suite_copy_tree`), 0006, 0007,
`tests/receipt.sh`, `tests/groups.tsv`, the dispatch in `felix`, `lib/verify.sh`
(`felix_tree_id`), `projects/felix/risk.tsv`, and plan A's design (sections 2a,
2b, 4, 7 and 8, approved by the founder on 2026-10-24).

This step is report-only. A run that is not traced prints what it prints today
and judges as it judges today. No receipt, gate verdict or CI step changes. The
one new write a normal run makes is a facts file in the git directory (B2).

Words used below:
- **The runner** is part 0007's `_par_run`, the parent of a `tests/run -j N`
  run.
- A **unit** is what the runner starts as one process. It is a part in no group,
  named by its file name, or a group of `tests/groups.tsv`, named by the group.
- **C** is a checkout's common git directory, `git rev-parse --git-common-dir`
  made absolute.
- **T** is a run's tree id, the one `_rcp_begin` takes at the run's start. A
  receipt the run leaves names it in field 2.
- **D** is a trace directory.
- **M** is the commit a map was traced at.
- **P**, the platform, is `uname -s` with the letters A to Z made a to z.
- **B3x** means the suite's bash is 3.2 to 4.0, and **B5x** means 4.1 or later,
  by `BASH_VERSINFO`.
- A **copy** is a checkout `_suite_copy_tree` (part 0003, D8) makes.
- `<TAB>` is one tab.

## 1. Defects

- **P5 (medium).** The -j runner records no per-unit facts. It keeps only a
  durations file of whole seconds per unit (0007:827-832).
  *Scenario:* the durations total of 8341 s is 8 slots times 1048 s. That
  measures contention, not CPU. Nobody can say which unit is slow by CPU rather
  than by waiting, or which verdict a unit had in a given run. No later map or
  measurement can be tied to a unit id, because a unit is never told its name:
  part mode reads the four `FELIX_TEST_PART_` variables and unsets them
  (0001:129-130), and nothing else names the unit.
- **P6a (high).** Nothing records which functions and files each unit runs, so
  the map plan A selects from (design 2a) cannot be made.
  *Scenario:* without a recorded map, selection can only guess from names, and
  the founder rejected that. A one-line change to a helper every command calls
  would be selected too narrowly.
  The constraints are measured. bash 3.2 has no `BASH_XTRACEFD`, and assertions
  capture `2>&1`. So the bash 3.2 tracer must be a DEBUG trap under functrace
  that writes a file per process. bash 4.1 and later can use xtrace on a
  descriptor above 9 that is not 63 (63 is the runner's FIFO, 0007:801).
- **P6b (medium).** Nothing turns a map and a change into a selection anyone can
  read.
  *Scenario:* even with a map, nobody can see what a change would run, or which
  of design 2a's "everything runs when" rules fired. So the shadow step (design
  step 7) has nothing to compare against the full run.

### Measured before this contract: the bash 3.2 tracer's cost and faithfulness

A prototype DEBUG-trap tracer was used, under functrace, with one file per
process and records deduplicated per process. It ran under bash 3.2.57 (arm64
macOS) on six parts, each run alone through `alone.sh` (bwk), untraced and then
traced. The prototype is not the build. These are the numbers the build is
judged against.

| part | untraced s | traced s | verdicts traced |
|---|---|---|---|
| 0250 | 19.1 | 23.1 (+21%) | the same, 100 ok |
| 1070 | 11.2 | 14.9 (+33%) | the same, 214 ok |
| 1600 | 34.5 | 38.5 (+12%) | the same, 350 ok |
| 0610 | 14.4 | 16.8 (+17%) | the same, 158 ok; 99 trace files, 224 KB |
| 0992 | 8.6 and 10.2 | 10.3 and 12.1 | 2 and 4 FAIL |
| 0520 | 24.4 | 7.7 | 59 FAIL |

- **Overhead.** Where the trace changed no verdict, the wall-time overhead was
  +12% to +33%.
- **0992.** Two runs gave 2 and 4 FAIL. `lib/detect.sh:168,240` reads
  PIPESTATUS right after a pipeline. bash 3.2 resets PIPESTATUS after every
  DEBUG trap: `false | true; echo ${PIPESTATUS[*]}` prints `1 0` untraced and
  `0` under any trap that runs a command, the handler `:` included. No handler
  can undo this. `$?` is restored by bash itself. `$_` is clobbered too, but a
  handler can restore it by ending with `: "$saved"`.
- **0520.** 59 FAIL, from `lib/qualify.sh:213`'s PIPESTATUS. The part also
  exports its own BASH_ENV.
- **Other PIPESTATUS readers.** `felix:771,773` (`felix gate`'s own status),
  `lib/procedures.sh:95` and `lib/commission-provider.sh:238` read it the same
  way.
- **What a check catches.** Every failing case was caught by one check: the next
  command reads PIPESTATUS after a pipeline of two or more commands. This held
  for 13 records in 0520 and 12 in 0992. B14 makes that check required, and
  turns its finding into "unfaithful", never into a narrower map.

## 2. Required behaviour

### Unit facts (P5)

- **B1. The unit's id.** In a `tests/run -j N` run with N of 2 or more, the
  runner starts every unit with `FELIX_TEST_UNIT` exported and set to the
  unit's name. A value the caller exported is replaced for the units. Every
  process a unit starts inherits it unless that process changes it. Part mode
  does not unset it. 0001's unset list stays the four `FELIX_TEST_PART_` names.
  A `-j 1` run, and a `tests/run --part` started by hand, set no
  `FELIX_TEST_UNIT`. A part there sees it only as the caller left it.
- **B2. Where facts are kept.** A run keeps its facts when all of these hold:
  - it is a `-j N` run with N of 2 or more;
  - it is not red's run: `FELIX_TEST_NO_MANIFEST` is not `1`;
  - its suite has `tests/receipt.sh` and `tests/select.sh` beside it;
  - it is a run that keeps a durations file today: started from the suite of a
    checkout whose top is two directories above `engine/harness`;
  - it is not traced (B8);
  - its runner judged every unit, so no INT, TERM, HUP or QUIT ended it first.

  Then, once the last unit is judged and before the runner does anything else,
  it writes `C/felix-testmap/runs/<T>.tsv`. A record run keeps its file, even
  one that then stops on a runner failure (0007:822-825). The file is written
  whole: a temporary file in `runs/`, renamed over any file of that name. A
  second run of the same tree replaces the first run's file.
- **B3. The facts file.** Tab-separated, with no other lines than these:
  - Line 1: `run<TAB>v1<TAB><T><TAB><N><TAB><$BASH_VERSION of the runner>`.
  - Then one line per unit, in the driver's order:
    `unit<TAB><name><TAB><verdict><TAB><wall><TAB><cpu>`.
  - **verdict** is `pass` when the unit added no FAIL to the run's count, and
    `fail` when it added one or more. Either kind counts: an assertion's FAIL,
    or a runner failure the runner charged to the unit (no mark, an exit status,
    a runner-owned line, the shell left changed, and 0007's others). A unit with
    skips and no FAIL is `pass`.
  - **wall** is whole seconds, the measure the durations file keeps: from when
    the unit's holder took its slot to when the runner learned the unit had
    ended. It is `unknown` when the runner could not read it, never `0` for a
    time it could not read.
  - **cpu** is the user plus system CPU seconds of the unit's process and of
    every process below it that was waited for. It is read once the unit has
    ended and written with exactly two decimals (`3.07`), or `unknown`. A
    process still running after the unit ended is not counted.
- **B4. Where nothing is kept, and nothing is said.** These runs keep no facts
  file, make no `C/felix-testmap`, and print nothing about either:
  - part mode;
  - a `-j 1` run;
  - red's runs;
  - a run whose suite lacks `tests/select.sh` or `tests/receipt.sh`, as every
    copy lacks `tests/select.sh`;
  - a run a signal ended.
- **B5. A file that cannot be kept.** B2 can hold and the file still not be
  written. The tree may have no id, or C may not be readable. `C/felix-testmap`
  or `C/felix-testmap/runs` may be a symbolic link or not a directory. The write
  or the rename may fail. Then the run prints exactly one line on stderr,
  `tests/run: the unit facts were not kept: <why>`, and writes nothing through a
  link. Its stdout, exit status, receipt and durations file are what they would
  have been had the facts been kept.
- **B6. Nothing else changes.** A -j run that keeps its facts prints exactly
  what it prints today:
  - no line on stdout or stderr about facts, maps or tracing;
  - the same verdict lines, sections and `(counted from lines)` summary;
  - the same exit status, receipt and durations file.

  The runner's files in `$TMP/pj` keep their names. Any new one there begins
  with none of `slot.`, `unit.`, `log.`, `ran.`, `end.`, `jobs`, `stats` and
  `fifo` (part 1296 counts `slot.*`).

### The tracer (P6a)

- **B7. Off unless asked for.** With `FELIX_TEST_TRACE_DIR` unset or empty:
  - the runner sets no `BASH_ENV` for any unit, and one the caller exported
    passes through as today;
  - the tracer is loaded nowhere;
  - the run is B6's run.
- **B8. A traced run.** A run is traced when all of these hold:
  - it is a `-j N` run with N of 2 or more;
  - it is not `--record-assertions`;
  - it is not red's run: `FELIX_TEST_NO_MANIFEST` is not `1`;
  - it was started with `FELIX_TEST_TRACE_DIR` set to a non-empty D;
  - `FELIX_TEST_UNIT` is unset or empty.

  Before any unit starts, a traced run refuses when any of these holds:
  - D is not an absolute path;
  - D is not an existing directory, is a symbolic link, cannot be written, or
    holds any entry;
  - D is the checkout's top or lies below it, compared with links resolved;
  - `BASH_ENV` is set and not empty (the tracer is loaded through it);
  - the suite has no `tests/trace.sh` or no `tests/select.sh` beside it.

  A refusal exits 2, prints exactly one line on stderr beginning
  `tests/run: FELIX_TEST_TRACE_DIR`, starts no unit and writes nothing in D.
  Otherwise every unit's process starts with `BASH_ENV` set to the absolute
  path of the suite's `tests/trace.sh`, and nothing else about how the units are
  started changes.
- **B9. What a traced run leaves.**
  - **`D/units.tsv`**, written whole once every unit is judged. It is B3's
    format with three more lines:
    - after the `run` line, `top<TAB><the checkout's top>`, taken before the
      first unit starts;
    - after `top`, `head<TAB><HEAD's full id><TAB><state>`, also taken before
      the first unit starts;
    - as the last line, `end<TAB><HEAD's full id><TAB><state>`, taken after the
      last unit is judged.

    state is `clean` when `git status --porcelain` (untracked files listed,
    ignored files not) printed nothing, `dirty` when it printed something, and
    `unknown` when git failed. That git runs with `GIT_OPTIONAL_LOCKS=0`, so it
    writes no index. An id git could not give is `-`. Wall and CPU are the
    traced run's.
  - **`D/<unit>/`**, one directory per unit. It holds one file `<pid>.trace`
    for each bash process of the unit that loaded the tracer. A subshell writes
    to its parent's file.
  - **No receipt.** The run's start takes the last receipt away, as every run's
    does, and the run writes none.
  - **Nothing else written.** The durations file is not written, and nothing is
    written under `C/felix-testmap/runs/`.
  - **The same output.** For parts the tracer leaves faithful (B14), stdout
    holds the lines the same run prints untraced. Nothing reaches stderr.
- **B10. How it traces, and what it leaves alone.**
  - Under B3x the tracer is a DEBUG trap with functrace on, and xtrace stays
    off.
  - Under B5x it is xtrace written to `BASH_XTRACEFD`, a descriptor above 9 that
    is not 63.
  - In every traced process:
    - nothing the tracer writes reaches stdout or stderr;
    - descriptors 0 to 9, and 63, are as they would be untraced;
    - the next command sees the `$?` and `$_` it would see untraced, and under
      B5x the same PIPESTATUS;
    - with `extdebug` on, no command is skipped;
    - under `set -e` and `set -u` the tracer stops nothing;
    - part mode's shell comparison (R8) finds no change in a part that changed
      nothing.
- **B11. What is recorded.** For each traced bash process, every function
  entered (with the file it was defined in) and every file whose top level ran
  are recorded at least once each. That holds in the process itself, in a `( )`
  subshell, in a command substitution, in a pipeline's elements, in a sourced
  file and in a function.
  - A child bash that inherits the environment loads the tracer through
    BASH_ENV and records for the same unit. That covers a script run by path or
    shebang, `bash FILE`, `bash -c`, the CLI and the hooks.
  - Top level is recorded as top level, never as a function named `main` or
    `source`.
  - A file sourced through a relative path is named by where it was when
    sourced, even after the process changes directory.
- **B12. One unit, one directory.** Everything a unit's processes record lands
  in that unit's `D/<unit>/`. That includes what a process records after it sets
  `FELIX_TEST_UNIT` itself, and what the units of a -j run started inside the
  unit record.
  - A -j run started with `FELIX_TEST_UNIT` set, so inside a unit, does not read
    `FELIX_TEST_TRACE_DIR`. It checks nothing, changes no `BASH_ENV`, and writes
    no `D/units.tsv`. It keeps its receipt, durations and facts as an untraced
    run does.
  - Its processes stay traced only through what they inherited. No directory in
    D is named for one of its units.
- **B13. Incomplete: what the tracer cannot follow.** A unit is incomplete in
  its map (B20) when one of its traced processes ran one of the commands below.
  The command word is read after any leading `NAME=value` assignments and any of
  `exec`, `command`, `builtin`, `nohup`, `nice` and `time`.
  - `env` with `-i`, `-`, `--ignore-environment`, or `-u BASH_ENV` (also
    spelled `-uBASH_ENV` or `--unset=BASH_ENV`);
  - `exec -c`;
  - any command run with a leading `BASH_ENV=` assignment;
  - `unset` or `export -n` naming BASH_ENV;
  - under B3x, `trap` naming DEBUG, or `set` with `+T` or `+o functrace`;
  - under B5x, `set` with `+x` or `+o xtrace`, or an assignment to
    `BASH_XTRACEFD` or `PS4`.

  A unit is also incomplete when `BASH_ENV` in one of its processes stops naming
  the tracer. The reason names the command, or says that `BASH_ENV` changed, and
  what it now holds. A command that only mentions these words in a quoted
  argument or an assignment's value (`_q='env -i'`) marks nothing.
- **B14. Unfaithful.** A unit is unfaithful in its map when either holds:
  - it failed in the traced run, so its verdict in `D/units.tsv` is `fail`. The
    reason is `failed under tracing`.
  - under B3x, one of its traced processes ran a command that reads PIPESTATUS
    right after a pipeline of two or more commands. The reason holds
    `PIPESTATUS` and the file the command was in.
- **B15. Record runs and red.** A `--record-assertions` run and red's run never
  read `FELIX_TEST_TRACE_DIR`. They make no check, set no `BASH_ENV` and write
  nothing in D. Each is the untraced run, and keeps facts by B2.

### Maps (P6a, P6b)

- **B16. `felix testmap --compile D`.** It is run from a git checkout that holds
  commit M, the id on the `head` line of `D/units.tsv`. It writes
  `C/felix-testmap/<P>/<M>/map.tsv` whole, making the directories and replacing
  any map there, and exits 0. It prints three lines:
  ```
  testmap: map for <M> (<P>) written to <path>
  testmap: <n> units: <c> complete, <i> incomplete, <u> unfaithful
  testmap: <time line>
  ```
  The time line depends on whether `C/felix-testmap/runs/<T>.tsv` exists for
  the T on D's `run` line:
  - when it exists, the line is
    `unit time from untraced runs: traced CPU <t> s against untraced <u> s for the same tree, <r>x`.
    t and u are sums over the units whose CPU both files know, with two
    decimals, and r is t/u with two decimals;
  - otherwise it is
    `unit time from the traced run: no untraced run of tree <T> is recorded here, so the tracer's overhead is not known`.
- **B17. What compile refuses.** In each case below, compile exits 1, prints
  exactly one line on stderr beginning `felix testmap:`, and writes or changes
  no map:
  - `D/units.tsv` is missing or unreadable: the traced run did not reach its
    end;
  - it lacks its `run`, `top`, `head` or `end` line, or holds no `unit` line;
  - the `head` or `end` state is not `clean`, or the two ids differ: a map is
    made only from a traced run of one clean commit;
  - M is not a commit in this checkout;
  - the working directory is not in a git checkout;
  - P cannot be read;
  - `C/felix-testmap`, or a directory on the way to the map, is a symbolic link
    or not a directory.
- **B18. The map.** Tab-separated. The order of lines is:
  - line 1: `map<TAB>v1<TAB><M><TAB><P><TAB><epoch seconds made><TAB><source>`,
    where source is `untraced` when the B16 runs file exists and `traced`
    otherwise;
  - one `unit<TAB><name><TAB><status><TAB><seconds><TAB><reason>` line per
    `unit` line of `D/units.tsv`, in its order:
    - status is `complete`, `incomplete` or `unfaithful` (B20);
    - seconds is the unit's CPU from the runs file when the source is
      `untraced`, or the traced CPU when it is `traced`. It has two decimals, or
      is `unknown` (a unit the runs file lacks, or knows only as `unknown`);
    - reason is `-` for complete; otherwise one line of text, with tabs and
      newlines made spaces;
  - then, sorted in byte order (`LC_ALL=C`) with no line twice:
    `fn<TAB><unit><TAB><path><TAB><function>` for each function a unit entered,
    and `top<TAB><unit><TAB><path>` for each file whose top level it ran. Paths
    come from B19.
- **B19. Mapping a recorded path.**
  - First the path is made lexical: `.` and `..` components are resolved and
    doubled slashes folded.
  - A path at or under the traced checkout's top, as its `top` line names it or
    with links resolved, becomes that relative path.
  - Otherwise, a path holding `/harness/` becomes `engine/harness/` followed by
    what follows its last `/harness/`. This covers the copies of the harness
    that fixtures make under `$TMP`.
  - A record is kept only when its relative path is a file in commit M. Every
    other record is dropped: code a part wrote under `$TMP`, a system file, a
    `bash -c` string, a function with no file.
  - Records for `engine/harness/tests/trace.sh` are dropped.
- **B20. Status, and the trace as data.** A unit's status is `unfaithful` when
  B14 holds. Otherwise it is `incomplete` when any of these holds:
  - B13 holds;
  - D has no `D/<unit>/` or no trace file in it. The reason is
    `no trace was written`;
  - a trace file holds a line that is not a record. The reason is
    `a trace line could not be read`.

  Otherwise the status is `complete`. Every line the tracer writes begins with a
  lowercase letter `a` to `z`. A line that does not, or that compile cannot read
  as a record, is not a record. Nothing in D is run, sourced or evaluated: it is
  read as text. Directories in D named for no unit of `D/units.tsv` are not read.

### The command (P6b)

- **B21. `felix testmap`.**
  - It is dispatched before the Felix home is resolved, as `felix cost` is, so
    it works with no home.
  - `felix testmap --help` prints the usage on stdout and exits 0. Its first
    line is `usage: felix testmap --report [BASE] | --compile DIR`.
  - The usage goes to stderr with exit 2 for any of: no argument, an unknown
    word, `--compile` without exactly one DIR, `--report` with more than one
    BASE.
  - An engine with no `tests/select.sh` beside its CLI makes every testmap
    command print one line on stderr and exit 1.
  - `felix help` is unchanged.

### The report (P6b)

- **B22. `felix testmap --report [BASE]`.** It is run from a directory in a git
  checkout. BASE defaults to `origin/main`. It exits 0 apart from B21's usage
  errors. It prints on stdout and, on every path below, nothing on stderr. It is
  read-only:
  - it creates, changes or removes nothing in the checkout or its git directory,
    the index included (git runs with `GIT_OPTIONAL_LOCKS=0`), and no map or
    runs file;
  - it runs no `git fetch`, `pull`, `push`, `ls-remote` or `remote`, and no
    suite or part.

  Its lines, in this order:
  1. `testmap: <top>`, the checkout's top;
  2. `base: <BASE> <full id>`, or `base: <BASE> unknown`;
  3. `map: <M> <P> dated <M's committer date, UTC, YYYY-MM-DD>, unit time from <source> runs`,
     or `map: none`;
  4. zero or more `everything runs: <reason>` lines (B26), each printed once;
  5. zero or more `selected <unit>: <reason>[; <reason>...]` lines (B27), in the
     tree's driver order;
  6. only when a map was used, `summary: <k> of <n> units selected, <p>% of unit time`,
     or `summary: <k> of <n> units selected, share of unit time not known`.
     Here k counts the selected units and n the tree's units (B25);
  7. `result: everything runs` when any line 4 was printed; otherwise
     `result: the selection runs` when k is above 0; otherwise
     `result: nothing to run`;
  8. `report only: nothing was run, and no verdict, receipt or gate changes`.

  Two cases print only one line and exit 0, instead of lines 1 to 8:
  - outside a git checkout:
    `testmap: <dir> is not in a git checkout, so there is nothing to select`;
  - in a checkout whose top has no `engine/harness/tests/run`:
    `testmap: <top> has no engine/harness/tests/run, so there is no suite to select from`.
- **B23. Which map.**
  - Only this platform's maps are read: `C/felix-testmap/<P>/<dir>/map.tsv`.
  - A map is usable when its `<dir>` is a full commit id, that commit exists
    here, and it is BASE or an ancestor of BASE.
  - The newest usable map, by its commit's committer date, is used.
  - BASE not a commit: `base: <BASE> unknown`, `map: none`, and
    `everything runs: the base [<BASE>] is not a commit here`.
  - None usable: `map: none` and
    `everything runs: no map for <P> here whose commit is an ancestor of <BASE>`.
  - The chosen map's file does not read as B18's (line 1, unit lines, statuses,
    seconds): `map: none` and
    `everything runs: the map <path> cannot be read: <why>`, with no selected
    and no summary line. No older map is tried.
  - The chosen map's commit is dated 14 days (1,209,600 s) or more before now:
    `everything runs: the map's commit <M> is <d> days old (the limit is 14)`,
    where d is whole days rounded down. Selection is still worked out and
    printed.
- **B24. The change.** The change is every path that differs between M and the
  working tree:
  - tracked files changed, whether staged or not;
  - files added or deleted, with no rename detection;
  - untracked files that are not ignored.

  With no differing path, nothing is selected and the result is
  `nothing to run`.
- **B25. The tree's units.** They are made as 0001 makes them from the tree's
  `engine/harness/tests/run` (its lines `. "$HERE/parts/NAME"`) and
  `engine/harness/tests/groups.tsv`. A group is one unit named for the group.
  Every other part numbered 0010 or later is a unit of its own. Parts 0001 to
  0009 and 9990 are in no unit. When groups.tsv breaks 0001's rules,
  `everything runs: the units of this tree could not be read: <why>` is printed,
  and the units are the parts alone.
- **B26. Everything runs when** one of these holds; each prints its own line:
  - A differing path is code outside the units:
    `engine/harness/tests/run`, `tests/red`, `tests/receipt.sh`,
    `tests/groups.tsv`, `tests/trace.sh`, `tests/select.sh`,
    `tests/select-*.sh`, `engine/harness/lib/testmap.sh`, a part numbered 0001
    to 0009 or 9990, or anything under `.github/`. The line is
    `everything runs: <path> is code outside the units`.
  - A line the tree adds, in a differing file that is not a part file, adds a
    computed call. The line is
    `everything runs: <path>:<the line's number in the tree> adds a computed call`.
    A line adds one when, after leading blanks and any of `if`, `then`, `else`,
    `do`, `!`, `{`, `(`, `&&`, `||` and `;`, it starts with any of these:
    - `eval `;
    - `source "$`, `source $`, `. "$` or `. $`;
    - a variable as the command word: `"$` or `"${`, or `$` followed by a name
      or `{`;
    - `bash -c`, `sh -c` or `"$BASH" -c`;
    - `trap '` or `trap "`;
    - `declare -f`, `export -f` or `compgen -A function`.

    A line whose first non-blank character is `#` adds none.
  - A differing path is read by no `fn` or `top` row of the map, and it is not a
    part file, a record file (B27) or code outside the units. The line is
    `everything runs: <path> changed and no map reads it`.
  - The selection is 70% or more of unit time:
    `everything runs: the selection is <p>% of unit time (the limit is 70%)`.
    When the share is not known (B29), the line is
    `everything runs: the selection's share of unit time is not known`.
- **B27. What is selected.** With a usable map and at least one differing path,
  a unit of the tree is selected for each reason below that holds. Its reasons
  are joined by `; ` in this order:
  1. `new unit`, for a unit the map does not have;
  2. `new part <name>` for each of its part files that M lacks, and
     `changed part <name>` for each that differs;
  3. `function <name> in <path>` for each `fn` row (unit, path, name) whose
     path differs and whose function's body differs between M and the tree
     (B28). This includes a function defined in only one of them, and one the
     parser finds in neither;
  4. `<path> could not be parsed into functions`, instead of 3 and 5 for that
     path, when the unit has any row for a differing path that cannot be parsed
     in M or in the tree;
  5. `top level of <path>` for each `top` row (unit, path) whose path differs
     and whose top level differs;
  6. `record file <path>`, for the unit holding the part numbered 1010 when
     `engine/harness/tests/assertions.tsv` or `tests/red.tsv` differs. With no
     part 1010 in the tree, a record file counts as a file no map reads;
  7. `incomplete in the map: <reason>` or `unfaithful in the map: <reason>`,
     for a unit whose map status is not `complete`.

  Rows whose path is a part file are not read for reasons 3 to 5; a differing
  part selects its unit by reason 2. A unit with no reason is not selected.
- **B28. Functions and top level.** Both versions of a file are read the same
  way, and neither is run or sourced.
  - **A definition** is a line that, after leading blanks, is `NAME()`,
    `NAME ()` or `function NAME` (with or without `()`), followed by optional
    blanks and `{` or `(`. NAME is letters, digits and `_ - . :`.
  - **A one-line definition** ends on its own line. That is when the line,
    ignoring trailing blanks and a comment, ends with the `}` or `)` that closes
    it.
  - **The end of any other definition** is the first later line that, after
    exactly the definition line's leading blanks, starts with its closing `}`
    (or `)`), followed by nothing, blanks, `;`, a redirection such as
    `2>/dev/null`, or a comment.
  - **Not parsed.** A file is not parsed when a definition finds no end before
    the next definition at the same or less indentation, or before the end of
    the file.
  - **A function's body** is the text of its lines, first to last. Definitions
    may nest, and an outer body holds the inner ones. A name defined more than
    once has all its definitions, in file order, as its body.
  - **The top level** is every line outside every definition, in order. It
    differs when that text differs. Moving a function, with nothing else
    changed, changes neither its body nor the top level.
  - **Heredocs and strings** get no special reading. A misread can only make a
    function end early, and its remaining lines then count as top level. Every
    unit that entered the function also ran the file's top level, so such a
    misread selects more, never less.
- **B29. Unit time and the share.** A unit's time is the map's seconds. The
  share is the selected units' seconds over all units' seconds, counting only
  units in both the tree and the map, rounded down to a whole percent. It is not
  known when any such unit's seconds are `unknown`, or when the total is 0.

### Where the code is

- **B30.**
  - The new code lives in three files:
    - `engine/harness/tests/trace.sh`, the tracer;
    - `engine/harness/tests/select.sh`, which holds the facts, the maps and the
      report, and may be split into further `engine/harness/tests/select-<name>.sh`
      files;
    - `engine/harness/lib/testmap.sh`, the command.
  - None of them has a `#!` line or the executable bit. Part 0720 judges
    executables by shebang, and part 1510 requires every executable to begin
    with the scrub block, which a BASH_ENV file must not run.
  - Sourcing `tests/select.sh`, or any `select-*.sh`, defines functions and
    nothing else: `_lib_runs_nothing` (part 0006) returns 0 for each.
  - Every function they define starts `_tm_`, and no other file of the suite
    defines a `_tm_` function.
  - Their awk passes `_awk_names` (`tests/lib/awk-names.sh`).
  - Each new file is under 500 lines.

## 3. What must not change

| Behaviour | Pinned by |
|---|---|
| The -j runner as gate friction D built it. Units, part mode, logs, verdict lines, the `(counted from lines)` summary and the print order. The durations file (D4: written only with no runner failure, `seconds<TAB>unit`). Receipts from -j runs. Record and red under -j. Groups, signals, slots, holders, the stopper, lost units and runner failures. The shell comparison. | `1291-gate-friction-d-blind.sh`, `1292-gate-friction-d-signals-blind.sh`, `1293-gate-friction-d-runner-failures-blind.sh`, `1294-gate-friction-d-slots-blind.sh`, `1295-gate-friction-d-shell-blind.sh`, `1296-gate-friction-d-losses-blind.sh` |
| Part mode unsets the four `FELIX_TEST_PART_` names and no other; a unit's environment holds no `FELIX_TEST_PART_` name (`djx-pv`) | `1291-gate-friction-d-blind.sh` (D2) |
| The suite receipt: taken away at a run's start, written only by a passing compared run on an unchanged tree in an unchanged environment, and reuse | `1200`-`1270` gate friction A, A2, A3, B parts, `1290-gate-friction-c-blind.sh`, `0370-a-receipt-that-cannot-claim-more-than-it-kno.sh`, `0510-the-receipt-carries-the-epoch-and-a-fact-tha.sh` |
| The record, the manifest and red | `1010-the-record-this-branch-carries.sh`, `0770-red-the-recorded-red-run.sh` |
| The driver under 500 lines; parts at most 1,000; every part sourced once, in name order, as `NNNN-name.sh`; `_suite_files` and the tests/lib lines | `1040-the-suite-is-cut-into-parts.sh`, `1290-gate-friction-c-blind.sh` |
| No top-level `exec` opening a descriptor of 10 or above in a part or tests/lib (R31) | `1295-gate-friction-d-shell-blind.sh` |
| Every executable under the engine begins with the scrub block; the executable bit follows the shebang | `1510-no-caller-environment-changes-a-tool-s-output.sh`, `0720-the-engine-manifest.sh` |
| The lints that read every `engine/harness/lib/*.sh`, `lib/testmap.sh` included: no fallback on a HEAD read, no self-referencing local, no pipe into `grep -q`, every mktemp given a template, guarded table reads, `felix_base_ref` once, no gawk-only name | `0370-...`, `0590-the-pre-flight.sh`, `0960-no-engine-test-reads-a-pipe-through-a-grep-t.sh`, `1000-the-engine-makes-its-scratch-under-tmpdir.sh`, `1030-a-pipe-at-stack-tsv-read-by-the-stop-hook-in.sh`, `1400-judge-refs-residue-blind.sh`, `1497-lib-awk-gawk-names-blind.sh` |
| `felix cost` and `felix inventory`, dispatched before the home and printing what they print; `<subcommand> --help` answers usage (#102) | `1050-felix-cost-tokens-spent-read-from-the-transc.sh`, `1060-continued.sh`, `1070-felix-cost-the-2026-10-11-addendum.sh`, `0860`-`0940` inventory parts, `0220-the-binding-itself.sh`, `1310-stuck-pr-page-states-blind.sh` |
| The deployed surface is harness/, hooks/ and commands/, so the new tests/ files ship inside harness/ | `0640-the-deployed-surface-is-three-directories.sh`, `0440-gate-installed-the-deployed-engine-is-the-on.sh` |
| tests/lib files define only functions and take no name the suite holds | `0006-the-lib-judges.sh` judges, `1290-gate-friction-c-blind.sh` |

**Sizes and places.** Check with `wc -l` and `git diff --numstat origin/main`.
- `engine/harness/tests/run` goes from 497 to 499 lines. Its only change is the
  two new part lines, after `1600-felix-refuses-a-pattern-kill-blind.sh`'s line
  and before the `! alias .` line.
- Part 0007 stays at or under 835 lines. No line is added or removed, and at
  most eight lines change. Each changed line still does what it did. The new
  work is calls into `tests/select.sh`. When that file is absent, as in every
  copy, the runner behaves exactly as at 69b51a61.
- These are unchanged: `tests/receipt.sh` (499), `tests/red`,
  `tests/groups.tsv`, parts 0001 to 0006, 9990, `assertions.tsv`, `red.tsv`
  and `.github/`. `lib/resolve.sh`, `lib/discover.sh`, `lib/where-read.sh` and
  `lib/commission.sh` do not get longer.
- `engine/harness/felix` stays at or under 6734 lines. One way: the cost
  dispatch line becomes a `case` that also dispatches testmap. `felix help`
  keeps its text.

**A note for the builder.** Part mode's comparison skips variables whose names
start `_og_`, `_pm`, `_par_`, `_pj_` or `BASH` (0007:255). A variable the tracer
sets after `lib-before.names` is taken must be among those, or B10's last clause
fails.

**Felix's calls made in this contract.** These are design details, decided and
documented here:
- **Parts are exempt from the computed-call rule.** A part runs only in its own
  unit, and a differing part selects that unit anyway. Without the exemption,
  `"$FELIX" ...`, which nearly every part line holds, would make every part edit
  run everything.
- **A traced run writes no receipt and no durations, and keeps its facts in D.**
  Traced timings never mix with untraced ones. A pass that bash 3.2's
  PIPESTATUS reset may have produced never becomes a receipt.
- **The report reads only this platform's map.** Selecting from the Linux map
  needs design 8's CI job.
- **Unit time comes from an untraced run of the same tree when one is
  recorded,** so the 70% bound is not skewed by the tracer.
- **The parser errs toward top level** (B28).

## 4. Assertions

Controls are marked: they hold before and after the fix, and pin what makes the
others mean something. Every other assertion fails on main today.

### Fixtures for part 2100

**Fixture S.** Everything lives under `$TMP/tm`.
- **Copies.** Each is made by `_suite_copy_tree` from planted parts the part
  writes. The part then copies in further files and commits them as a second
  commit, with `refs/remotes/origin/main` moved to it. Those files are
  `$HERE/trace.sh`, `$HERE/select.sh` and each `$HERE/select-*.sh` (into the
  copy's `engine/harness/tests/`), plus the fixture libraries below.
  - **P**: parts `0010-pp-a.sh`, `0020-pp-b.sh` and `0030-pp-c.sh`. Each prints
    `djx-sec NAME`. 0010 also prints `djx-unit:${FELIX_TEST_UNIT-unset}` and
    `djx-benv:${BASH_ENV-unset}`. Each makes one `ok`, and 0030 also a `skip`.
    No groups. Its manifest lists the prelude's first assertion, made as part
    1291's positive control makes `pman.tsv`, so a passing run leaves a receipt.
  - **P0**: P's parts, with neither trace.sh nor select.sh added.
  - **R**: `_suite_copy_tree --red` of P's parts, with trace.sh and select.sh
    added.
  - **T**: the twelve units listed below.
- **Fixture libraries in T's `engine/harness/lib/`.**
  - `tm-a.sh`: top-level `tm_top=1`, then multi-line functions `tm_f1` to
    `tm_f7`, each with the body `:`.
  - `tm-b.sh`: `tm_b1`.
  - `tm-r.sh`: `tm_r1`.
  - `tm-child.sh`: `tm_c() { :; }`, then a call `tm_c`.
- **Running a copy.** A run uses a bounded runner of 1291's `run.pl` shape: its
  own process group, a time limit, and INT and QUIT reset. It runs from the
  copy's top, under
  `env -u FELIX_TEST_UNIT -u FELIX_TEST_TRACE_DIR -u BASH_ENV -u FELIX_TEST_JOBS -u FELIX_TEST_SLOTS -u FELIX_TEST_NO_MANIFEST -u FELIX_TEST_RED_JOBS -u FELIX_TEST_PART_LOG -u FELIX_TEST_PART_RAN -u FELIX_TEST_PART_END -u FELIX_TEST_PART_RECORD`
  with `TMPDIR` a fixture directory and `FELIX_TEST_SLOTS=4`, plus what the case
  sets. stdout and stderr go to files. Every case ends by checking that its
  process group holds no live process (1291's sweep). Nothing is killed by
  pattern.
- **Trace directories.** D1 to D5 are fresh empty directories under
  `$TMP/tm/d`, outside every copy.
- **Terms used in the tables.**
  - "the runs of X" are the files under `X/.git/felix-testmap/runs/`;
  - "verdict lines" are the lines starting `  ok    `, `  FAIL  ` or
    `  skip  `, sorted;
  - "rows" are lines of a map;
  - "MT" is T's map.
- **Skips by bash version.** Assertions marked B3x or B5x skip on the other
  bash, with the reason `bash <BASH_VERSION> here: this checks the <other>
  tracer`. Locally only B3x runs; CI runs B5x.

**T's units.** Each part prints `djx-sec NAME`.

| unit | what it does |
|---|---|
| `0010-tm-a.sh` | Sources `$REAL_HARNESS/lib/tm-a.sh` and calls `tm_f1`, `( tm_f3 )` and `_x="$(tm_f4)"`. Runs `bash "$REAL_HARNESS/lib/tm-child.sh"`. Copies tm-a.sh to `$TMP/tmcp/harness/lib/tm-a.sh`, sources the copy and calls `tm_f5`. Sources `"$REAL_HARNESS/bin/../lib/tm-b.sh"` and calls `tm_b1`. Runs `( cd "$REAL_HARNESS" && . ./lib/tm-r.sh && cd / && tm_r1 )` and `( export FELIX_TEST_UNIT=elsewhere; bash "$REAL_HARNESS/lib/tm-child.sh" )`. Prints `djx-unit:`, `djx-benv:` and `djx-mech:<x or ->:<BASH_XTRACEFD or ->:<number of lines trap -p DEBUG prints>:<functrace on or off>`; `ok` |
| `0020-tm-b.sh` | `sleep 2`; `ok` |
| `0030-tm-c.sh` | A child perl that spends 2.0 s of its own user CPU; `ok` |
| `0040-tm-d.sh` | One `bad` |
| `0050-tm-e.sh` | `env -i PATH="$PATH" /bin/bash -c true`; `ok` |
| `0060-tm-f.sh` | `false \| true; _r="${PIPESTATUS[0]}"`; prints `djx-ps:$_r`; `ok` |
| `0070-tm-g.sh` | `_q='env -i is only words here'`. `tm_g3() { return 3; }; tm_g3` followed by `is` that `$?` is 3. `: a b` followed by `is` that `$_` is `b`. `is` that `( shopt -s extdebug; false; _y=1; printf %s "$_y" )` prints 1. `is` that `( set -eu; tm_g0() { :; }; tm_g0; printf reached )` prints `reached`. `is` that `bash -c 'f() { :; }; f' 2>&1` prints nothing |
| `tg` (group: `0080-tm-h.sh`, `0090-tm-i.sh`) | 0080 sources tm-a.sh and calls `tm_f7`; 0090 makes one `ok` |
| `0100-tm-j.sh` | `( trap - DEBUG; : )` and `( set +x; : )`; `ok` |
| `0110-tm-k.sh` | `ok` when `FELIX_TEST_TRACE_DIR` is unset or empty, `bad` otherwise |
| `0120-tm-l.sh` | Makes an inner copy I with `_suite_copy_tree`, holding `0010-in-a.sh` (sources `$REAL_HARNESS/lib/tm-a.sh`, calls `tm_f6`, `ok`) and `0020-in-b.sh` (`ok`), with a manifest so that a passing run leaves a receipt. Runs I's driver with `-j 2` from I's top, with `TMPDIR` its own and `FELIX_TEST_SLOTS=2`. `FELIX_TEST_UNIT`, `FELIX_TEST_TRACE_DIR` and `BASH_ENV` stay as inherited. `is` that the run exited 0 and that I holds a receipt |

**Runs on T, in this order:**
1. T-u: untraced `-j 4`;
2. T-t: traced `-j 4` with `FELIX_TEST_TRACE_DIR=D1`;
3. `$FELIX testmap --compile D1` from T's top, which writes MT;
4. the cases that change MT, which come last.

### Part 2100: unit facts, the tracer and maps

| A | B | Fixture | Expected |
|---|---|---|---|
| A1 | B1 | P, `-j 1` | **control:** output holds `djx-unit:unset` |
| A2 | B1 | P, `-j 2` (P-u) | output holds `djx-unit:0010-pp-a.sh` |
| A3 | B1 | P-u with `FELIX_TEST_UNIT=stray` in the run's environment | output holds `djx-unit:0010-pp-a.sh` |
| A4 | B7 | P-u | **control:** output holds `djx-benv:unset` |
| A5 | B2, B6 | P-u | **control:** exit 0, a receipt is present, and the durations file has the three unit names |
| A6 | B2, B3 | P-u | the runs of P are exactly one file, named `<field 2 of P's receipt>.tsv` |
| A7 | B3 | that file | line 1 is `run`, `v1`, the same T, `2` and the runner's BASH_VERSION, tab-separated; then exactly three lines, `unit` with `0010-pp-a.sh`, `0020-pp-b.sh` and `0030-pp-c.sh` in that order, each `pass` |
| A8 | B3 | that file | every wall field matches `^(0\|[123456789][0123456789]*\|unknown)$` and every cpu field matches `^([0123456789]+[.][0123456789][0123456789]\|unknown)$` |
| A9 | B2 | P-u again | the runs of P are still one file |
| A10 | B6 | P-u, beside P `-j 1` | **control:** the same verdict lines; P-u's stderr is empty; no stdout line contains `testmap`, `unit facts` or `trace` |
| A11 | B4 | P0, `-j 2` | **control:** exit 0, empty stderr, and no `P0/.git/felix-testmap` |
| A12 | B4 | P, `tests/run --part 0010-pp-a.sh` | no new file in the runs of P |
| A13 | B5 | P with `.git/felix-testmap` a regular file, `-j 2` | exit 0; stderr is exactly one line starting `tests/run: the unit facts were not kept: `; a receipt is present; the same verdict lines as P-u |
| A14 | B5 | P with `.git/felix-testmap` a link to an empty directory E, `-j 2` | one such stderr line, and E stays empty |
| A15 | B3 | the runs of T after T-u | twelve unit lines in this order: `0010-tm-a.sh 0020-tm-b.sh 0030-tm-c.sh 0040-tm-d.sh 0050-tm-e.sh 0060-tm-f.sh 0070-tm-g.sh tg 0100-tm-j.sh 0110-tm-k.sh 0120-tm-l.sh`, with tg in its driver place (eleven names and tg) |
| A16 | B3 | the same | 0040's verdict is `fail` and every other unit's is `pass` |
| A17 | B3 | the same | 0020's wall is 2 or more |
| A18 | B3 | the same | 0030's cpu is at least 0020's cpu plus 1.20 |
| A19 | B3 | T-u | exit 1, and the output holds `djx-ps:1` |
| A20 | B8 | P, `FELIX_TEST_TRACE_DIR=d` (relative) | exit 2; stderr is one line starting `tests/run: FELIX_TEST_TRACE_DIR`; no `djx-sec` on stdout |
| A21 | B8 | P, D2 holding one file | as A20, and D2 still holds only that file |
| A22 | B8 | P, D = `P/sub`, an empty directory | as A20 |
| A23 | B8 | P, D2 empty, `BASH_ENV=/dev/null` | as A20, and D2 empty |
| A24 | B8 | P0, D2 empty | as A20, and D2 empty |
| A25 | B8 | P, D = a link to an empty directory | as A20 |
| A26 | B7 | P, `FELIX_TEST_TRACE_DIR=` (empty) | **control:** exit 0, a receipt is present, and the output holds `djx-benv:unset` |
| A27 | B8, B9 | P, D2, `-j 2` (P-t) | exit 0 and empty stderr |
| A28 | B8 | P-t | `djx-benv:` is followed by an absolute path ending `/engine/harness/tests/trace.sh` |
| A29 | B9 | P-t | no receipt; the durations file is byte-for-byte what it was before P-t; the runs of P are what they were before P-t |
| A30 | B9 | `D2/units.tsv` | the lines are `run`, `top` (P's top), `head` (P's HEAD, `clean`), three `unit` lines, then `end` (P's HEAD, `clean`) |
| A31 | B9 | D2 | `D2/0010-pp-a.sh` holds at least one file matching `[0123456789]*.trace` |
| A32 | B9, B6 | P-t beside P-u | the same verdict lines |
| A33 | B15 | R, `--record-assertions -j 2`, D3 | exit 0; D3 is empty; the output holds `djx-benv:unset` |
| A34 | B9 | T-t | exit 1 and empty stderr |
| A35 | B9 | `D1/units.tsv` | `head` and `end` both name T's HEAD and read `clean`; twelve `unit` lines; 0040 and 0110 are `fail` |
| A36 | B9, B12 | D1 | exactly one directory per unit of A15 and no other: no `elsewhere`, no `0010-in-a.sh`, no `0020-in-b.sh` |
| A37 | B9, B11 | `D1/0010-tm-a.sh` | at least two trace files |
| A38 | B10 | T-t, B3x | `djx-mech:-:-:` followed by a number of 1 or more and `:on` |
| A39 | B10 | T-t, B5x | `djx-mech:x:<n>:`, where n is above 9 and is not 63 |
| A40 | B10 | T-t | 0070's section holds no `FAIL` line |
| A41 | B10, B9 | T-t beside T-u | every stdout line of T-t that is not a verdict line, a detail line (eight blanks), a `  note  ` line, a `djx-` line or the summary also appears in T-u's stdout |
| A42 | B16 | compile D1 | exit 0; stdout is three lines, the first `testmap: map for <T's HEAD> (<P>) written to <T's C>/felix-testmap/<P>/<T's HEAD>/map.tsv` |
| A43 | B16 | the same | line 3 matches `^testmap: unit time from untraced runs: traced CPU [0123456789]+[.][0123456789]{2} s against untraced [0123456789]+[.][0123456789]{2} s for the same tree, [0123456789]+[.][0123456789]{2}x$` |
| A44 | B18 | MT | line 1 is `map`, `v1`, T's HEAD, P, an epoch within the last hour, `untraced`; then the twelve `unit` lines in A15's order |
| A45 | B16, B18 | MT and the compile's line 2 | the counts in line 2 equal the counts of each status among MT's unit lines |
| A46 | B18, B20 | MT | `0010-tm-a.sh`, `0020-tm-b.sh`, `0030-tm-c.sh` and `tg` are `complete`, each with reason `-` |
| A47 | B13, B20 | MT | **control for B13's last sentence:** `0070-tm-g.sh` is `complete` |
| A48 | B14 | MT | `0040-tm-d.sh` and `0110-tm-k.sh` are `unfaithful`, each reason holding `failed under tracing` |
| A49 | B13 | MT | `0050-tm-e.sh` is `incomplete`, its reason holding `env -i` |
| A50 | B14 | MT, B3x | `0060-tm-f.sh` is `unfaithful`, its reason holding `PIPESTATUS` |
| A51 | B10, B14 | MT and T-t, B5x | `0060-tm-f.sh` is `complete`, and T-t's output holds `djx-ps:1` |
| A52 | B13 | MT | `0100-tm-j.sh` is `incomplete`; under B3x its reason holds `trap` or `set`, under B5x it holds `set +x` |
| A53 | B11, B19 | MT | rows `fn 0010-tm-a.sh engine/harness/lib/tm-a.sh` for each of `tm_f1`, `tm_f3`, `tm_f4` and `tm_f5`, tab-separated |
| A54 | B11, B19 | MT | rows `fn 0010-tm-a.sh engine/harness/lib/tm-b.sh tm_b1`, `fn 0010-tm-a.sh engine/harness/lib/tm-r.sh tm_r1` and `fn 0010-tm-a.sh engine/harness/lib/tm-child.sh tm_c` |
| A55 | B11 | MT | rows `top 0010-tm-a.sh <path>` for `engine/harness/lib/tm-a.sh`, `engine/harness/lib/tm-child.sh` and `engine/harness/tests/parts/0010-tm-a.sh` |
| A56 | B11 | MT | no `fn` row names `tm_f2`; no `fn` row's function is `main` or `source` |
| A57 | B11, B12 | MT | the row `fn tg engine/harness/lib/tm-a.sh tm_f7` |
| A58 | B12 | MT | the row `fn 0120-tm-l.sh engine/harness/lib/tm-a.sh tm_f6`; no row's unit is `elsewhere`, `0010-in-a.sh` or `0020-in-b.sh` |
| A59 | B19 | MT | no row's path starts `/`; every row's path is listed by `git -C T ls-tree -r --name-only HEAD` |
| A60 | B18 | MT | the `fn` and `top` lines are in byte order, with none twice |
| A61 | B17 | compile of an empty directory | exit 1; one stderr line starting `felix testmap:`; MT is byte-for-byte unchanged |
| A62 | B17 | a copy of D1 with the `head` state `dirty` | as A61 |
| A63 | B17 | a copy of D1 with the `head` and `end` ids forty `0`s | as A61 |
| A64 | B17 | compile of D1 run from `$TMP/tm/d`, outside every checkout | exit 1 and one stderr line |
| A65 | B16 | P's runs moved aside; compile D2 from P's top | line 3 is `testmap: unit time from the traced run: no untraced run of tree <D2's T> is recorded here, so the tracer's overhead is not known`; the map's line 1 ends `traced` |
| A66 | B27 | T with `tm_f7`'s body changed; `$FELIX testmap --report` from T's top | a line `selected tg: function tm_f7 in engine/harness/lib/tm-a.sh`; no `selected 0010-tm-a.sh:` line has a `function` reason |
| A67 | B20 | a copy of D1 with a line `#junk` appended to a trace file of `0070-tm-g.sh`, compiled after the copy was made (run last) | exit 0; `0070-tm-g.sh` is `incomplete` with reason `a trace line could not be read` |

### Fixture for part 2110

**Fixture RP** is a git repository under `$TMP/tr` that is made by hand; no
suite runs in it. Its files:
- `engine/harness/tests/run`, whose part lines name, in order: `0001-pre.sh`,
  `0010-a.sh`, `0020-b.sh`, `0030-c.sh`, `0040-d.sh`, `0050-e.sh`,
  `0060-f.sh`, `1010-r.sh` and `9990-end.sh`.
- `engine/harness/tests/groups.tsv`, which puts `0040-d.sh` and `0050-e.sh` in
  group `g`.
- Each part file, holding one line `ok "x"`.
- `engine/harness/tests/assertions.tsv` and `engine/harness/tests/red.tsv`, one
  line each.
- `engine/harness/lib/a.sh`, holding with no blank lines:
  - `a_top=1`;
  - `f1() {`, `  echo one`, `}`;
  - `f2() {`, `  echo two`, `}`;
  - `f3() { echo three; }`;
  - `f4() {`, `  echo four`, `} 2>/dev/null`;
  - `function f5 {`, `  echo five`, `}`.
- `engine/harness/lib/b.sh`: `f1() {`, `  echo b-one`, `}`.
- `engine/harness/lib/c.sh`: `c1() {`, `  echo c`, and no closing line.
- `engine/harness/lib/d.sh`: `d1() { :; }`.
- `projects/x/t.tsv` and `docs/n.md`.

The tree's units are `0010-a.sh 0020-b.sh 0030-c.sh g 0060-f.sh 1010-r.sh`, so
n is 6.

The commits:
- **C0** holds every file and is dated 20 days and 1 hour ago (author and
  committer date).
- **C1** changes only `docs/n.md` and is dated now.
- `main` and `refs/remotes/origin/main` are at C1.
- **X** is a commit on another branch, from C0, dated now.

**MAP1** is `C/felix-testmap/<P>/<C1>/map.tsv`, written by the part. P is
computed as B's definition says. Its first line is
`map<TAB>v1<TAB><C1><TAB><P><TAB><now><TAB>untraced`. Its unit lines:
- 0010, 0020, 0030 and g: `complete`, `10.00`;
- `0060-f.sh`: `incomplete`, `10.00`, reason
  `a command started without the tracer: env -i x`;
- `1010-r.sh`: `complete`, `50.00`.

Its rows:
- `fn` rows: 0010 enters a.sh's `f1`; 0020 enters a.sh's `f2`; 0030 enters
  b.sh's `f1` and c.sh's `c1`; g enters a.sh's `f3`, `f4` and `f5`.
- `top` rows: a.sh for 0010, 0020 and g; b.sh and c.sh for 0030.

There is also a map at C0, MAP0, the same with C0's id. MAPX is the same with
X's id.

**Each case** starts from a clean working tree at C1. The part makes the case's
change, runs `$FELIX testmap --report` from RP's top (BASE as given), and puts
the tree back. Every run is made with `FELIX_HOME=$TMP/tr/nohome`, which does
not exist. Its stdout and stderr go to files.

"The tail" is the two lines
`result: <...>` and `report only: nothing was run, and no verdict, receipt or gate changes`.

### Part 2110: the report and the command

| A | B | Change | Expected |
|---|---|---|---|
| A68 | B22 | none | exit 0; empty stderr; lines 1 to 3 are `testmap: <RP top>`, `base: origin/main <C1>` and `map: <C1> <P> dated <today, UTC>, unit time from untraced runs`; no `everything runs` and no `selected` line; `summary: 0 of 6 units selected, 0% of unit time`; the tail with `result: nothing to run` |
| A69 | B27 | `echo one` → `echo uno` in a.sh's `f1` | exactly two selected lines: `selected 0010-a.sh: function f1 in engine/harness/lib/a.sh` and `selected 0060-f.sh: incomplete in the map: a command started without the tracer: env -i x`; `summary: 2 of 6 units selected, 20% of unit time`; `result: the selection runs` |
| A70 | B27 | b.sh's `f1` body changed | `selected 0030-c.sh: function f1 in engine/harness/lib/b.sh`; no `selected 0010-a.sh` line |
| A71 | B27, B28 | `a_top=1` → `a_top=2` | `selected 0010-a.sh: top level of engine/harness/lib/a.sh`, the same for `0020-b.sh` and for `g`; no `selected 0030-c.sh` |
| A72 | B28 | `f3`'s one line changed | `selected g: function f3 in engine/harness/lib/a.sh`; no 0010 or 0020 line |
| A73 | B28 | `echo four` changed inside `f4` (the `} 2>/dev/null` closing) | `selected g: function f4 in engine/harness/lib/a.sh`; no line holds `could not be parsed` |
| A74 | B28 | `echo five` changed inside `function f5 {` | `selected g: function f5 in engine/harness/lib/a.sh` |
| A75 | B27 | `f2`'s three lines deleted | `selected 0020-b.sh: function f2 in engine/harness/lib/a.sh`; no 0010 line |
| A76 | B28 | `f1`'s and `f2`'s blocks swapped, bodies unchanged | no `selected 0010-a.sh` and no `selected 0020-b.sh`; 0060 is selected |
| A77 | B27, B28 | a line added to c.sh | `selected 0030-c.sh: engine/harness/lib/c.sh could not be parsed into functions` |
| A78 | B27 | `0020-b.sh` edited | `selected 0020-b.sh: changed part 0020-b.sh`; no `everything runs` line |
| A79 | B27 | `0050-e.sh` edited | `selected g: changed part 0050-e.sh` |
| A80 | B26, B27 | new part `0070-n.sh`, and its line added to `tests/run` after 0060's | `everything runs: engine/harness/tests/run is code outside the units`; `selected 0070-n.sh: new unit; new part 0070-n.sh`; `summary: ` with `of 7 units`; `result: everything runs` |
| A81 | B26 | a comment line added to groups.tsv | `everything runs: engine/harness/tests/groups.tsv is code outside the units` |
| A82 | B26 | `0001-pre.sh` edited; then, separately, `9990-end.sh` | each gives its path's `is code outside the units` line |
| A83 | B26 | an untracked `engine/harness/tests/select.sh`; then, separately, `.github/workflows/g.yml` | each gives its path's `is code outside the units` line |
| A84 | B26 | inside `f1`, after `echo one`, the added line `  eval "$x"` (line 4 of the tree's a.sh) | `everything runs: engine/harness/lib/a.sh:4 adds a computed call`; and `selected 0010-a.sh: function f1 in engine/harness/lib/a.sh` |
| A85 | B26 | the same place, one case each: `"$tool" --flag`, `. "$f"`, `bash -c 'true'`, `trap 'echo t' EXIT`, `declare -f f1`, `export -f f1`, `compgen -A function` | each prints the `a.sh:4 adds a computed call` line |
| A86 | B26 | the same place, one case each: `# eval "$x" in a comment`, `echo "eval it"` | **control:** no `everything runs` line; f1 selected |
| A87 | B26 | `  eval "$x"` added to `0020-b.sh` | no `adds a computed call` line; `selected 0020-b.sh: changed part 0020-b.sh` |
| A88 | B26 | `projects/x/t.tsv` edited; then `docs/n.md`; then `engine/harness/lib/d.sh`; then an untracked `engine/harness/lib/new.sh` | each gives `everything runs: <its path> changed and no map reads it` |
| A89 | B27 | `assertions.tsv` edited | `selected 1010-r.sh: record file engine/harness/tests/assertions.tsv`; no `everything runs` line; `summary: 2 of 6 units selected, 60% of unit time` |
| A90 | B26, B29 | `assertions.tsv` edited, and a line `b_top=1` added before b.sh's `f1` | `everything runs: the selection is 70% of unit time (the limit is 70%)`; `selected 0030-c.sh: top level of engine/harness/lib/b.sh` |
| A91 | B29 | MAP1 with `0020-b.sh`'s seconds `unknown`, and A69's change | `everything runs: the selection's share of unit time is not known`; `summary: 2 of 6 units selected, share of unit time not known` |
| A92 | B23 | BASE `nosuch` | `base: nosuch unknown`; `map: none`; `everything runs: the base [nosuch] is not a commit here`; no summary; `result: everything runs` |
| A93 | B23 | BASE C0's id | `map: <C0> <P> dated ...`; `everything runs: the map's commit <C0> is 20 days old (the limit is 14)` |
| A94 | B23 | MAP1's directory renamed to `notacommit` (MAP0 and MAPX in place) | the map line names C0, and the 14-day line is printed |
| A95 | B23 | all maps moved to `C/felix-testmap/otheros/` | `map: none`; `everything runs: no map for <P> here whose commit is an ancestor of origin/main` |
| A96 | B23 | MAP1's first line made `map<TAB>v9...` | `map: none`; a line starting `everything runs: the map <MAP1's path> cannot be read: `; no `selected` and no summary line |
| A97 | B22 | run from `$TMP/tr/plain`, which no checkout encloses | exit 0; stdout is the one line `testmap: <that dir> is not in a git checkout, so there is nothing to select` |
| A98 | B22 | run from a git repository with no `engine/harness/tests/run` | exit 0; stdout is the one line `testmap: <its top> has no engine/harness/tests/run, so there is no suite to select from` |
| A99 | B21 | `$FELIX testmap` with no argument; `--bogus`; `--report a b`; `--compile` with no DIR | each exits 2, prints nothing on stdout, and prints a stderr line starting `usage: felix testmap` |
| A100 | B21 | `$FELIX testmap --help` | exit 0; stdout's first line is `usage: felix testmap --report [BASE] \| --compile DIR` |
| A101 | B21 | `$FELIX help` before and after A68 to A100 | **control:** both outputs hold no `testmap` |
| A102 | B22 | marker file touched; then A68's, A69's (change made before the marker) and A95's reports | nothing under RP, `.git/index` included, is newer than the marker |
| A103 | B22 | a `git` first on PATH that logs its arguments and runs the real git, during A102's three reports | no logged line starts `fetch`, `pull`, `push`, `ls-remote` or `remote` |
| A104 | B22 | every report case above | the last line is `report only: nothing was run, and no verdict, receipt or gate changes`, and stderr is empty |
| A105 | B30 | `$HERE/trace.sh`, `$HERE/select.sh`, every `$HERE/select-*.sh`, and `$REAL_HARNESS/lib/testmap.sh` | each exists, its first line does not start `#!`, it is not executable, and it has under 500 lines |
| A106 | B30 | `_awk_names` over the same files | exit 0 and no output |
| A107 | B30 | `_lib_runs_nothing` on `select.sh` and each `select-*.sh` | 0 for each |
| A108 | B30 | the definitions in `select.sh` and `select-*.sh`; the parts, tests/lib, `run`, `red` and `receipt.sh` | every function the first set defines starts `_tm_`, and the second set defines no `_tm_` function |

## 5. Parts

- `engine/harness/tests/parts/2100-unit-facts-and-tracer-blind.sh`: A1 to A67.
- `engine/harness/tests/parts/2110-testmap-report-blind.sh`: A68 to A108.

Both are written from this file alone, before the fix, and are red first.
- Each builds its own fixtures under `$TMP` and stands alone.
- The driver lists each with one line, in this order, after part 1600's line and
  before the `! alias .` line. Those two lines are the only change to
  `tests/run`.
- Each runs under alone.sh by itself, and passes under bwk with bash 3.2 and
  under gawk with bash 5.
- Neither leaves a process running, and neither opens a descriptor of 10 or more
  at its top level (R31).
- Each names its assertions by sentence with the A number first, as the house's
  blind parts do.
- Timings are never held closer than these bounds: a 2 s sleep with a "2 or
  more" check, and 2.0 s of CPU with a 1.20 s margin.
- Both parts start every fixture run with the environment Fixture S names. So
  when the real suite is itself traced, part 2100 reads as incomplete (it runs
  `env -u BASH_ENV`), which is what B13 asks.

## 6. Out of scope

- **Linux file opens and the CI testmap job.** design 2a's `strace -f -e
  trace=openat,execve`, and the testmap artifact the tick fetches (design 8),
  both need a step in `.github/workflows/gate.yml` and strace on the runner.
  That is a workflow change, the founder's, and comes later as its own PR, as
  the batch says. Until then no map knows which data files a unit reads, so B26
  makes every data change run everything.
- **Counting bash processes started against processes traced** (design 2a).
  That needs strace's execve list. B13's command check is the stand-in, and
  design 4.4's fault injection measures what it misses.
- **Marking a child started as `sh`.** bash started as `sh` reads no BASH_ENV,
  so such a child is untraced. But a rule naming `sh` would mark every unit on
  bash 3.2: 0001:318 makes each unit run `exec /bin/sh -c 'echo "$PPID"'`. A
  changed shell file that only `sh` children run is a file no map reads, so B26
  runs everything for it. Design 4.4's fault injection measures the rest.
- **Making the bash 3.2 tracer faithful to PIPESTATUS.** It cannot be done:
  bash 3.2 resets PIPESTATUS after every DEBUG trap (section 1). B14 marks such
  a unit unfaithful instead, so it always runs.
- **Refresh in idle slots, maps for each main commit, the shadow comparison,
  the essential set, per-unit results, red's scope row, the selective record
  and manifest, `felix merge` recomputing, receipt v2.** These are design steps
  7 to 10 and later. For now a map is made by hand:
  `FELIX_TEST_TRACE_DIR=D engine/harness/tests/run -j N` in a clean worktree of
  main, then `felix testmap --compile D`.
- **Selecting on the Mac from the Linux map, and the platform-branching rule.**
  Both need the Linux map. The report reads its own platform's map only.
- **Assertion names per unit in the map.** Only the selective record (step 10)
  reads unit-to-name.
- **An `unknown` verdict.** B2 keeps facts only once every unit is judged, and a
  judged unit is pass or fail. A run a signal ended keeps nothing, rather than
  rows of unknowns no reader can tell from a slow run.
- **Exempting a driver change that only adds part lines** from "outside the
  units". Today every new part makes everything run (A80). Whether that is too
  wide is for the shadow step to measure before any rule changes.
- **Retention of `runs/` and of maps.** A facts file is a few KB per tree run.
  A map is about one row per function per unit, a few MB. Neither is read for
  any verdict yet.
- **Listing `testmap` in `felix help`.** `felix` may not grow (section 3), and
  the report is for Felix's own use until selection is armed.
- **Facts for serial runs.** A `-j 1` run is one shell, with no units in it.

### Not fixed: not a defect

None. All three defects hold when the code is read:
- **P5:** 0007 keeps only the durations file (0007:827-832), and part mode
  exports no unit id (0001:129-130).
- **P6a:** no file under `engine/harness/tests` sets a DEBUG trap or
  `BASH_XTRACEFD` for units. 0006's DEBUG trap is its lib judge's, in a child
  under `env -i`.
- **P6b:** no command reads a map or a diff for selection.

The skeptics returned no corrections to these three.

## 7. Founder PR

**This batch's own PR lands on the founder's hand merge.** It changes part 0007,
which `projects/felix/risk.tsv:44` routes to the verifier on any change. It
touches no `.github/`, deny or escape row, and no commission table.

**One founder PR is needed with it, because of a gap this batch opens.** The -j
runner will source `tests/select.sh` into the shell that counts every unit's
PASS and FAIL. Every traced unit will load `tests/trace.sh`. So either file can
weaken what a run counts or leaves without a line of 0007 changing. No verifier
row covers them. The exact change is one row in `projects/felix/risk.tsv`,
inserted after line 44 (the 0007 row):

```
yellow	path	^engine/harness/tests/(trace|select(-[a-z0-9-]+)?)\.sh$	the -j runner sources the selector into the shell that counts every unit, and every traced unit loads the tracer, so either can weaken what a run counts or leaves without a line of 0007 changing; every change is read by the verifier and no count stands in for it	verifier
```

risk.tsv is a commission table (`lib/commission.sh:52`), so the row needs the
commission re-stamp, which is the founder's.

The row should land before this batch's PR. A new escape row does not judge the
PR that adds it, and this PR is the first to add the two files.

The CI testmap job is not part of this batch. It is a later founder PR, as the
batch says.

## 8. Red

Run on 2026-10-24 at 2b437783, before any code changed, with
`alone.sh <worktree> bwk 2100-unit-facts-and-tracer-blind.sh 2110-testmap-report-blind.sh`
(macOS awk, bash 3.2.57). It ran 3 min 26 s and exited 0.

**Counts.** The two parts hold 108 assertions, A1 to A108. 92 failed, 14 passed
and 2 skipped (A39 and A51, which check the bash 4.1 or later tracer and skip on
3.2). The summary line, `ok=77 fail=92 skip=2`, also counts the 62 `ok` lines of
the prelude parts the driver runs first (fixture floor and `_fixture_floor`),
and part 2100's closing fixture assertion.

**The 14 that passed, and why.**

| A | Why it passes on main |
|---|---|
| A1, A4, A5, A10, A11, A26, A101 | Controls the contract marks. They pin what makes the failing ones mean something: a `-j 1` run sees no `FELIX_TEST_UNIT`, an untraced run sets no `BASH_ENV`, the durations file and receipt exist, a run prints no word about facts, a copy with no `select.sh` is silent, an empty `FELIX_TEST_TRACE_DIR` is no trace, and `felix help` names no testmap. |
| A19 | Already true. It asks of the untraced run of T that it exits 1 and the PIPESTATUS reader prints 1. Nothing in it touches facts or the tracer. |
| A27, A34 | Already true. Main ignores `FELIX_TEST_TRACE_DIR`, so the "traced" run is an untraced one: exit 0 (P) or 1 (T) with nothing on stderr. They hold again once the tracer is real, but they cannot tell a working tracer from none. |
| A32, A41 | Vacuous on main. They compare a traced run with an untraced one, and on main the two are the same run. They mean something only once a tracer is loaded. |
| A33 | Already true. A record run never reads `FELIX_TEST_TRACE_DIR`, and on main nothing reads it. D3 is empty and no unit sees `BASH_ENV`. |
| A40 | Vacuous on main. Part 0070's `$?`, `$_`, extdebug, `set -eu` and child-bash checks hold because no tracer runs. They guard B10 once one does. |

The part 2100 header names A19, A27, A32, A33, A34, A40 and A41 as true on main
by construction. The other 92 are the assertions that gate the fix.

**Why the 92 fail.** Each fails for the reason B1 to B30 says it should:
`FELIX_TEST_UNIT` is never exported (A2, A3), no facts file is written (A6 to
A9, A12 to A18), the trace directory is not read or checked (A20 to A25, A28 to
A31, A35 to A38, A42 onwards), `felix testmap` is an unknown command (A42 to A100,
A66), and `trace.sh`, `select.sh` and `lib/testmap.sh` do not exist (A105 to
A108).
