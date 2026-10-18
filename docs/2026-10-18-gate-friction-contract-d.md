# Contract D: the parallel runner

This is step 3b of docs/2026-10-12-gate-friction-design.md, section 5. It is its own pull request, engine tier, and is built on C (#444), after which it lands. Its version is the next free one when it records.

C made every part run alone. D runs the parts in parallel, so that a suite turns the machine's cores into less wall time. The founder put C and then D ahead of everything else on 2026-10-16.

The design's rule binds every item: weaken no check. That includes weakening by scheduling, where an assertion that a serial run makes over many parts' work is made over less, or is skipped where a serial run makes it.

**Revision 6** (2026-10-18 UTC) answers five reviews, kept in audits/2026-10-18-gate-friction-d/:
- wf_00c91ec7-6df: 61 findings, 12 blockers;
- wf_d8757a8b-3d0: 44 findings, 4 blockers;
- wf_ccaff3a8-78b: 18 findings, 5 blockers;
- wf_2bc0bebb-a30: 16 findings, 1 blocker. Most were races in revision 4's symbolic-link slots, which revision 5 replaced with kernel locks;
- wf_21407532-d3b: 14 findings, no blocker.

## What decided the list

- **C's sweep** (ad3370bd), every part run alone, five at a time under load:
  - all 144 parts numbered 0010 or later reach their end with no FAIL;
  - the longest wall times alone are 0010 (136 s), 0930 (134 s), 0700 (128 s), 0920 (123 s) and 0780 (122 s).
- **The prelude**, on 3820e969 under load 31: about 1.8 s of CPU per process. 145 processes pay about 260 s that a serial run pays once.
- **The machine** has 10 cores, 8 of them performance cores. `kern.maxprocperuid` is 2666.
- **The prelude's assertions** are all in part 0005: 48 lines. 0001 lays the fixture floor and makes `$TMP` (0001:166).
- **State a serial run carries to its end:**
  - the refusal log `$TMP/fx-refused` (0002:49);
  - the origin record `$TMP/origin-moved` (0003:600);
  - the counters and the ran file.

  The EXIT trap removes `$TMP` (0003:793). Part 9990 judges the run's end.
- **The record judge** is defined in part 1010, and the driver's tail calls it only if it is defined (run:407-414). 1240:191-192 pins the line printed when it is not.
- **`reached`** is printed after the 9990 line, and `_suite_flat` users depend on that order (lib/gitproof.sh:39-41, 124-125). Tail lines are pinned as text in `$HERE/run` (0770:111-131, 1010:354).
- **Red** takes `--after <mark> <pid> [base]`. It copies run, parts and lib into the base and nothing else (red:336-357). It counts every `  ok    `, `  FAIL  ` and `  skip  ` line in the log (red:426-428, 471-483). Its suite runs as a background job, without receipt.sh, and maps INT, TERM and HUP to 130, 143 and 129 (red:244).
- **The receipt** is one v1 line of exactly eight tabs (receipt.sh:29, 227). receipt.sh is 499 lines, and `receipt.sh:443, 463` read `$HERE/red.tsv` during the tail. receipt.sh:416-427 ends a tree by TERM, a wait, then STOP and KILL to the whole list.
- **CI** has no suite.yml. `gate.yml:90` runs `./engine/harness/felix gate` on ubuntu, which runs projects/felix/gate.sh. 1230:75 pins the gate's call to tests/run as exactly `--reuse`. On a failure, gate.sh shows only the log's FAIL lines (gate.sh:330-338).
- **bash 3.2.57**, measured 2026-10-18:
  - It has no `wait -n`, no `$BASHPID` and no fractional `read -t`.
  - **Async commands.** A command started with `&` starts with SIGINT and SIGQUIT ignored, and cannot trap or reset them, even under `set -m`. perl reports them there as `IGNORE`. `perl -e '$SIG{INT}=$SIG{QUIT}="DEFAULT"; exec @ARGV'` gives them back their defaults; 0530:417 already does this.
  - **The signal cases.** 0573 and 0574 probe whether a signal can reach a child, and skip about 18 names, under the same names, when it cannot.
  - **Arithmetic errors.** An error in `$(( ))`, `(( ))`, `let` or `[[ ]]` drops the rest of the command the shell is reading at its own top level, or the rest of a function call. Inside a file sourced with `.`, it drops only the rest of that file's own command: the file goes on, and `.` returns. Only an arithmetic error in an array subscript, such as a top-level `a[1/0]=1`, ends the sourced file and the rest of the line that sourced it.
  - **Aliases.** An alias named `.` is accepted. With `expand_aliases` set, it turns later top-level `. FILE` lines into no-ops.
  - **Variable names.** Part 0840 assigns `_j` in a top-level loop (0840:394-400), so a serial run leaves `_j=3` in the main shell.
  - **Mixed signals.** A parent started with INT ignored and QUIT at its default makes its serial children `INT:no QUIT:yes` under 0573's probe. perl reads that parent as `IGNORE` and `undef`, so each signal can be told apart.
  - **Bash reaps a killed `( ) &` child at once**, before any `wait`, so `kill -0` then says it is gone.
- **perl `flock`**, measured on macOS 2026-10-18:
  - `flock(FH, LOCK_EX | LOCK_NB)` on a file fails while another process holds it.
  - The kernel releases the lock when the holding process exits, however it exits, `kill -9` included, and while a child it started still runs.
  - perl opens its files close-on-exec, so a child it execs has no descriptor for the file (`lsof` shows none) and holds no lock.
  - perl is on ubuntu-latest: parts that run in CI call it unguarded (0530:417, 0560:213, 1240:44).
- **`_suite_preamble`** is parts 0001-0004 (0003:824). `_suite_copy_driver` keeps only those part lines (0003:834-847), and parts 1220, 1230, 1240 and 1260 pin what their copies print.
- **The driver** is 458 lines on C. Slot 18 adds about 31, and 1040:23 caps it at 500.
- **0940** reads `$IB/runs/*.err`, which 0900 to 0930 write: 97 files in order, 28 alone.

## D1. The interface

- **`tests/run -j N`**, as two words, with N from `1` to `64` in decimal, with no sign and no leading zero.
  - With no `-j`, N comes from `FELIX_TEST_JOBS` when that is set, read once and unset at once, before any part runs. Otherwise N is 1.
  - `-j` combines with `--record-assertions` and `--reuse` in any order.
- **Refusals.** Each of these exits 2 with one line on stderr, before `$TMP` is made:
  - `-j` with no N, `-jN` as one word, a second `-j`, or any other N;
  - a `FELIX_TEST_JOBS` that is not a valid N;
  - with N above 1, a `tests/groups.tsv` that is missing, unreadable, not a regular file or broken (D5). An empty file means no groups.
- **Where they are made.** The refusals are made by part 0001, at its head, before it makes `$TMP`. 0001 is a prelude part, under every lint and in `_suite_preamble`. The driver's own argument loop learns to pass `-j N` and `--part` over, and keeps its refusal text (pinned by 1220:241-242).
- **Where N lives.** 0001's head sets N in `_suite_jobs`, and nothing else sets it. Every driver line after the part list, the runner and 9990 read N only as `$_suite_jobs`. No other file of `_suite_files` names `_suite_jobs` except in a `$_suite_jobs` or `${_suite_jobs` expansion, and the blind part (D8) asserts that. The blind part builds the name from two pieces (`_n=_suite_; _n=${_n}jobs`), so it does not break its own rule.
- **`-j 1` is today's run.** One shell, the parts sourced in the driver's order, the same stdout and stderr lines in the same order.
- **`tests/run --part NAME...`** is part mode. NAME is a part file name as the driver's line names it, with no directory.
  - It takes one to six names, contiguous and in the driver's order.
  - It refuses, exiting 2 before `$TMP` is made:
    - a name the driver does not source;
    - 0001 to 0009, or 9990;
    - names out of order or not contiguous;
    - `--part` with `-j`, `--record-assertions` or `--reuse`.
  - It is keyed on the argument alone. It unsets the `FELIX_TEST_PART_*` variables once read.
  - With those variables unset (a person running it), it writes to stdout, keeps no ran or end file, and prints its runner lines (D2).
- **The gate.** projects/felix/gate.sh sets `FELIX_TEST_JOBS` to the core count for its call to tests/run:
  - `sysctl -n hw.ncpu`, then `getconf _NPROCESSORS_ONLN`, then 1, whichever first answers with a number;
  - held to 1 to 64;
  - never when `GITHUB_ACTIONS` is `true`.

  Its argument list stays `--reuse`, which keeps 1230:75's pin. When tests/run exits 2, gate.sh prints the log's last line under `tests FAIL`, so a refusal is not silent. It binds once landed, since `felix gate` runs the home copy.
- **CI does not change.** gate.yml is not touched, and CI's gate runs N = 1.

## D2. A unit

A **unit** is a group (D5), or a part in no group, numbered 0010 or later and not 9990.

For N above 1, the parent runs the prelude as `-j 1` does, 0005's assertions included. Its runner (D6) then runs every unit as `"$BASH" "$HERE/run" --part NAME...`:
- in the directory the parent was started in;
- with `FELIX_TEST_PART_LOG`, `_RAN` and `_END` naming files in the parent's `$TMP`;
- in a record run, also `FELIX_TEST_PART_RECORD=1`.

In part mode the driver, in order:
1. **Runs the whole prelude**, with stdout and stderr to the log file in the order written. It takes no receipt, starts no red run, compares no manifest, writes none and never prints `reached`.
2. **Prints `@@prelude-done`.** From then on it records the names it reaches in the ran file, and only there.
3. **For each member**, on a driver line of its own: `[ -z "${_pmK:-}" ] || . "$HERE/parts/$_pmK"; [ -z "${_pmK:-}" ] || _pm_done "$_pmK"`.
   - That line is a top-level line with no loop and no function around the source, and its shape does not match 1040's part-line pattern.
   - `_pm_done` prints `@@member-done NAME`.
   - What stops a member is what stops a part in the serial run. An arithmetic error in `$(( ))` inside the part drops only the rest of the part's own command: the part goes on, `.` returns, and the member reads as finished, as the serial run goes on. An error that ends the sourced file and the rest of its line, such as a top-level `a[1/0]=1`, leaves the member unfinished, and the next member's line still runs, as the serial run's next part line does.
   - With `FELIX_TEST_PART_RECORD=1` it first sets `FELIX_TEST_RECORD=1`, so part 1010 skips its record checks as in a serial record run.
4. **Writes its end state** to the end file, as 9990's three checks make them for its own shell, without asserting:
   - the floor: 9990:10-15's test;
   - its refusal lines;
   - its `_og_check` verdict and message;
   - its FAIL counter, counted from `@@prelude-done` on.
5. **Sets `_fx_final=1`** and prints the mark `@@part-done NAME...`.
6. **Exits 0**, whatever its FAIL count. The next driver line exits 3 if part mode reaches it, so a part mode whose end line was dropped never falls into the runner or the part list.

Every runner line (`@@prelude-done`, `@@member-done NAME`, `@@part-done NAME...`) starts a line of its own. Part mode ends a partial last line before printing one.

## D3. The log and the verdict

- **Order.** The parent prints the units' log files in the driver's part order. It prints a file once that unit and every unit before it have ended. Within a file:
  - the lines before `@@prelude-done` are dropped, unless the unit's prelude failed (below), when they are printed;
  - every line printed from before `@@prelude-done` is prefixed with `  | `, so that none starts like an assertion line;
  - the runner lines are removed;
  - everything else is printed as written, including what comes after the mark (an EXIT trap's lines, a stray background writer).
- **The runner's own failures.** Each prints a `  FAIL  ` line in the unit's place in the log and adds 1 to FAIL. None calls `_ran`: they are not assertion names. Their texts start with fixed prefixes, and the blind part asserts that no manifest name starts with one of them:
  - `part's prelude failed: UNIT`, when the file has a `  FAIL  ` line before `@@prelude-done`, or no `@@prelude-done` at all. The file's lines from before it follow, prefixed;
  - `part did not finish: MEMBER`, once for each member with no `@@member-done`, mark or no mark;
  - `part ended without its mark: UNIT`, when the file has no mark, whatever its member lines;
  - `part process ended with status S: UNIT`, when the unit has its mark and exited non-zero;
  - `part failed more than it printed: UNIT`, when the end file's FAIL counter is above the number of the file's `  FAIL  ` lines after `@@prelude-done`. A FAIL line written onto a partial line is counted by `-j 1`'s counter and by no line count, so without this a `-j N` run would pass where `-j 1` fails;
  - `part printed a line the runner owns: UNIT`, when a unit's file holds `reached`, or a runner line out of place. The places are: `@@prelude-done` once and first, the `@@member-done` lines once each in member order, the mark once and after them.

  UNIT is the group's name or the part's file name.
- **Waiting.** A unit that waited more than one second for a slot gets `  note  UNIT waited S s for a slot` at the head of its section. A note is not an assertion line.
- **Counts.** Under `-j N`, PASS, FAIL and SKIP are:
  - the parent's own counters;
  - plus the units' `  ok    `, `  FAIL  ` and `  skip  ` lines after `@@prelude-done`, as tests/red counts them;
  - plus the runner's own failures.

  Under `-j 1` the summary and the exit status come from the main shell's counters, as today.
- **The summary.** Under `-j N` the summary line ends ` (counted from lines)`: `P passed, F failed[, S skipped] (counted from lines)`. One tail line adds that suffix, keyed on `$_suite_jobs`. The suffix never ends ` (reused)`, which gate.sh reads as reuse.
- **Names reached.** The parent appends every unit's ran file to its own `$FELIX_TEST_RAN` before the tail reads it. The tail's lines are otherwise unchanged.
- **9990** runs in the parent in its place (D7). Under `-j N` its three assertions read the parent's own state and every unit's end file:
  - the floor is bad when the parent's or any unit's floor is bad;
  - the refusals are bad when the parent's refusal log or any end file holds a line, and the detail lists them all;
  - the origin is bad when the parent's `_og_check` or any unit's verdict is bad. It is a skip only when every one is a skip.

  A unit with no readable end file, mark or no mark, makes all three bad. Under `-j 1`, 9990 reads only its own shell, as today. Its names are unchanged and each is printed once.

## D4. The record, red and the receipt

- **A record run under `-j N`** runs its units with `FELIX_TEST_PART_RECORD=1`.
  - It writes the manifest only when none of D3's six runner failures was made. `_par_run` reads every unit's file and end file, the end file's FAIL counter included, to decide.
  - Otherwise it writes no manifest. `_par_run` itself prints the log and the runner's failures, writes the mark `failed` and exits 1, before the 9990 line, so before the record branch's `recorded` line and before `_rcp_red_end`. The watcher (receipt.sh:468-471) then ends red within a second or so. Only 9990's three checks go unjudged in that run, which has already failed. The mark is written by the one call `_par_run` makes into receipt.sh, `_rcp_mark failed "$TMP/manifest.mark"`, and only where `_rcp_red` is set, as the tail does; red's suite never sets it. A serial run whose part dies never reaches the manifest either.
  - An assertion FAIL, 9990's included, does not withhold the manifest, as under `-j 1`. A FAIL the unit counted and did not print is a runner failure (D3), so it does.
  - A manifest written under `-j N` is byte-identical to the one `-j 1` writes on the same tree.
- **The re-judge.** The record judge is defined in part 1010, which runs in a unit, so under `-j N` the tail takes its existing branch and prints `  no record judge in this suite: the record is not re-judged`. That line is pinned by 1240:191-192 and unchanged.
  - `_rcp_judged` stays 0, so the run leaves no record receipt (receipt.sh:342).
  - The gate's next run on the committed tree judges the record, as part 1010 does in every normal run.
  - Under `-j 1` the record is re-judged as today.
- **Red.**
  - A record run under `-j N` passes N to red in `FELIX_TEST_RED_JOBS`. It is exported by 0001 only between its argument check and the red start, and unset by part 0004's head, after red has started.
  - Red reads `FELIX_TEST_RED_JOBS` once, unsets it, and runs its suite with `-j N` when it is valid, or serially otherwise. It never passes it on.
  - Red copies this tree's `tests/groups.tsv` with run, parts and lib, removing the base's first. When this tree has none, red places none. Its `-j` suite then refuses, and red.tsv says so through `_none`.
  - Red leaves the runner's own failure lines (D3, by their six prefixes) out of its failed count and its names. A unit's unreached names are red by their shortfall, so red.tsv names only manifest names (1010:296-298), and its names still add up to its run row (1010:38).
  - Under `-j`, red's suite reaches `reached` when a unit dies, and that unit's names count by their shortfall, where a serial red run that died writes `-` rows. That is a deliberate difference: the `-j` red run says more, not less. A prelude or owned-line runner failure makes red refuse the log, as it refuses a stopped suite.
- **The receipt.**
  - Its format does not change.
  - `--reuse` accepts a receipt for the tree whatever N made it.
  - A `-j` run with any runner failure, or one that was interrupted, leaves no receipt.
- **Durations** are in `--git-path felix-suite-durations`, one line per unit: whole seconds, a tab, then the unit's name.
  - The file is written whole at the end of a `-j` run with no runner failure.
  - It is written only where `_rcp_on` is 1, so a red run reads and writes none.
  - `_rcp_begin` does not remove it.
  - A row is used only when it is `0` or digits with no leading zero, a tab, and the name of a unit of this run. Other rows are ignored. Rows are ordered with `sort`, and no value read from the file enters `$(( ))`.

## D5. Assertions about the whole run

An assertion that a serial run makes over the work of several parts must judge at least as much under `-j`. 9990 is bound by D3. The rest are bound by groups, or shown not to need one, as D8 finds them.

- **`tests/groups.tsv`** has one line per member: the group's name, a tab, then the part's file name.
  - A group's lines are adjacent. Its members are contiguous in the driver's order and number two to six.
  - A part is in at most one group, and none is 0001-0009 or 9990.
  - Lines starting `#` are comments.
  - A file that breaks a rule is refused as D1 says, with one line naming the rule.
  - `-j 1` does not read it.
- **The first group, `ib`**, is 0900, 0910, 0920, 0930 and 0940. Its `$IB/runs/*.err` assertion then reads the 97 files the serial run reads. At about 300 s of wall it bounds the run's wall until it is split, which is not in D.
- **risk.tsv** gains a yellow row for `^engine/harness/tests/groups\.tsv$` with no confine, so every change to the file stops for the verifier, as risk.tsv:32's row does. Regrouping can weaken an assertion without removing a line, so no count can stand in for reading the change.

Nothing in D5 adds or removes a manifest name.

## D6. The runner

The runner lives in a new prelude part, `parts/0007-the-parallel-runner.sh`. It defines functions and makes no assertion. It is self-contained and uses nothing from receipt.sh, which red's suite does not load, apart from the one `_rcp_mark` call D4 names. It does not join `_suite_preamble`, so `_suite_copy_driver`'s copies, and the counts parts 1220, 1230, 1240 and 1260 pin on them, are unchanged. Those copies run with N = 1 and never call it.

- **Order.** Units start longest first, by the durations file (D4).
  - A unit with no recorded duration starts before every recorded one. Ties go in driver order.
  - With no file, the order is driver order.
  - Where other runs hold slots, units may start out of that order.
- **N at a time.** At most N units of one run run at once.
- **Signals.** Before it starts a wrapper, the parent finds once, from a foreground perl child, how its own INT and QUIT are disposed: each is `IGNORE` or `DEFAULT`.
  - Every unit is started by the holder (below), which sets INT and QUIT each to the parent's value before it execs the unit. So a unit starts with them as the parent had them, in each of the four combinations, as a serial run's parts do.
  - A `-j N` run therefore makes the signal cases of 0573 and 0574 wherever a `-j 1` run from the same shell makes them.
- **Slots.** There are K of them: the core count found as D1's gate finds it (`sysctl`, then `getconf`, then 1, held to 1 to 64), or `FELIX_TEST_SLOTS` when that is set, a valid N used by tests.
  - Slot k is the regular file `${TMPDIR:-/tmp}/felix-suite-slots/k`, for k from 0 to K-1. The parent makes the directory and any missing file before it starts a wrapper, then takes and drops one lock there. It refuses with exit 2 and one line when it cannot do any of that, or when a name there is not a regular file.
  - A slot is held by holding a `flock` (`LOCK_EX | LOCK_NB`) on its file. Nothing else marks a slot. No holder is written, no age is read, and nothing is ever taken over: the kernel releases the lock when its holder exits, however it exits.
  - Every `-j` run on the machine shares the slots, red's included. A `-j 1` run takes none.
- **The holder.** Each unit is run by one perl process, the holder:
  1. **TERM.** Before its first try it installs one TERM handler. The handler exits 143 when the holder has no child, and otherwise returns, so the holder goes on waiting for its unit, which is sent its own TERM.
  2. **Waiting.** It tries each slot file in turn. Holding none, it waits one second and tries again. A `flock` that fails with anything but EWOULDBLOCK, or a slot file it cannot open, ends it with exit 2 before it starts its unit, which then has no mark (D3).
  3. **Starting.** Holding a slot, it writes the epoch at which it took it to the file the wrapper names for that unit in the parent's `$TMP`, then forks. Its child restores every signal the holder changed to the disposition the holder started with, sets INT and QUIT as the parent's probe read them, and execs the unit. The slot file is open close-on-exec, so neither the unit nor anything the unit starts holds the lock.
  4. **Ending.** It waits for the unit and exits with the unit's exit status, or with 128+n when the unit died of signal n, as bash reports it.
- **The wrapper.** Each holder is started by a wrapper: a `( )` subshell in the parent's job table, not inside the unit's process, because parts 0150 and 0330 end in a bare `wait`. The wrapper:
  - closes the FIFO's descriptor for the holder, so that no unit holds it;
  - runs the holder in the foreground;
  - after the holder ends, however it ends, writes the unit's name and the holder's exit status to the FIFO, as one line;
  - traps TERM, and exits without writing once its holder has ended.
- **Learning that a unit ended.** The parent reads the FIFO, which it holds open for reading and writing, with `read -t 30`.
  - On a timeout it checks each running wrapper's pid with `kill -0`, a builtin. A wrapper that is gone without a line ends its unit as having no mark.
  - **Time.** A unit's duration runs from the epoch its holder wrote to the moment its line is read, so it excludes the slot wait. D3's note's S is that epoch minus the moment the wrapper started.
  - It forks nothing while it waits, and runs no loop that forks per check.
  - Its own CPU over a run is at most 5 s.
- **Ending.** The parent traps INT, TERM and HUP. On any of them, and in `_fx_exit` whenever the parent ends with wrappers still running, it:
  1. takes one `ps -A -o pid=,ppid=` listing, and from it the trees of its wrappers;
  2. sends TERM to every pid in those trees, and waits up to 10 s for its wrappers to go;
  3. lists again, and adds to the pids it has every descendant of every pid it has, the first listing's included, so that a child moved to pid 1 and anything it forked since are found. It sends STOP to every pid it has. It repeats until a listing adds nothing (a stopped process cannot fork), then sends KILL to every pid it has, as receipt.sh:420-427 and red:185-191 do;
  4. waits, with the `wait` builtin, for every wrapper, so that every unit has been reaped before it exits.

  - **Slots.** No step removes a slot. Each holder's lock goes with it. A stopped holder still holds its lock, so no other run starts a unit on that slot while this run's units are being ended.
  - **Exit status.** An interrupted run exits 130 on INT, 143 on TERM and 129 on HUP, as red:244 does.
  - **What it leaves.** An interrupt before the 9990 line prints no `reached`, and leaves no receipt and no manifest. One that comes later leaves what the run had already written, and no receipt.
  - **`$TMP`.** A unit ended by KILL may leave its own `$TMP`, as a serial run killed so does.
  - **Reach.** A process a unit orphaned before the interrupt is in no listing, and is outside what the ending reaches, as it is in a serial run.

## D7. The driver

- **The hand-over**, at the end of the prelude, is these top-level lines:
  1. part mode's lines (D2), and the line that exits 3 after them;
  2. `[ "$_suite_jobs" -le 1 ] || _par_run`, then `[ "$_suite_jobs" -le 1 ] || [ "${_par_done:-}" = 1 ] || exit 1`, where `_par_done=1` is `_par_run`'s last statement;
  3. `[ "$_suite_jobs" -le 1 ] || { shopt -s expand_aliases; alias .=:; }`, so that under `-j N` the part lines that follow read as no-ops;
  4. after the last part line, before the 9990 line, `! alias . >/dev/null 2>&1 || { unalias .; shopt -u expand_aliases; }`, keyed on the alias itself. The 9990 line then runs in the parent in its place, and `reached` and the tail follow as today.
- **The tail** gains the one line that adds D3's summary suffix under `-j N`.
- **What does not move.** The part lines, the 9990 line, `reached` and the tail keep their text and their order, apart from that one tail line. `_suite_flat`, 1040's part-line rule and every pin on driver text hold.
- **The budget.** The driver is at most 500 lines after D with slot 18's lines merged in. The build shows the count both ways.
  - D adds about 16 lines: the hand-over, the tail line and the argument loop.
  - It frees at least 15 by moving the comment blocks that describe code now living in parts into those parts.

## D8. What the build must show

**Blind, in the suite: a new part, written from this contract alone.** It runs `-j 2` or `-j 3` on a fixture suite made by a new helper beside `_suite_copy_driver`:

`_suite_copy_tree [--red] F GROUPS MANIFEST STUB...`
- **What it makes.** F becomes a git checkout on branch `main`, with one commit and `refs/remotes/origin/main` at that commit, so that a run there can write a receipt and red can find its base. It holds:
  - `engine/harness/lib`, a copy of the harness's lib, and `engine/harness/felix`;
  - `engine/.claude-plugin/plugin.json`, naming `felix` at version `0.0.1`;
  - `engine/harness/tests`, holding receipt.sh, parts 0001 to 0007 and 9990 by number, tests/lib, red with `--red`, `groups.tsv` copied from GROUPS (none when GROUPS is `-`), and `assertions.tsv` copied from MANIFEST (none when MANIFEST is `-`).

  It does this as part 1240:80-95 builds its fixture.
- **Its driver.** The copy's driver keeps every line of the suite's own driver except the part lines from the first one after 0007 to the last one before 9990. Those it replaces with one line for each STUB, where the first of them stood.
- **STUB.** Each STUB is the path of a part file the caller wrote. It is copied into the copy's parts under its own name, which is numbered 0010 or later and is not 9990, as a unit's must be.
- **Failure.** It returns 1, with no `run` in the copy, when anything cannot be made.
- **TMPDIR.** Every case points `TMPDIR` at a fixture directory, so that no case touches the machine's slots.

The cases:
- **The refusals.** Each D1 refusal exits 2 before `$TMP` is made, `FELIX_TEST_JOBS` included.
- **groups.tsv.** Each rule refuses with its line, and a missing file refuses. The tree's own `tests/groups.tsv` puts 0900, 0910, 0920, 0930 and 0940 in one group.
- **`_suite_jobs`.** No file of `_suite_files` other than 0001 names it except in an expansion (D1).
- **The runner's prefixes.** No manifest name starts with one of D3's six runner-failure prefixes.
- **A positive control.** A copy with planted parts that all pass, run under `-j 3`, exits 0, leaves a receipt, and in a `--red` record copy writes the manifest and red.tsv. Every "no receipt" and "red ended" below is judged against this.
- **A group runs as one process.** Planted parts A and B each write a file under one directory below `$TMP`, and C asserts that the directory holds two files. With A, B and C as one group, `-j 3` passes C. With no groups line, `-j 3` fails C.
- **Runner failures.** Each gives its D3 FAIL line, exit 1 and no receipt. In a `--red` record copy each writes no manifest, and once red's process has gone (waited for, with a bound) red.tsv holds exactly the rows `base - - -` and `run - - -`, where the positive control's holds counts:
  - a unit killed with `kill -9` while it runs a member;
  - a unit killed after its last `@@member-done` and before its mark;
  - a part that runs `exit 0`;
  - a part that dies on an unbound variable under `set -u`;
  - a part that prints `reached`;
  - a part that prints a runner line;
  - a group member that dies, which fails it and every member after it;
  - a part whose `bad` line lands on a partial line, which gives `part failed more than it printed`;
  - a part that replaces the EXIT trap with one that removes `$TMP` and exits 5, which gives `part process ended with status 5: UNIT` under `-j 3`, where `-j 1` exits 5;
  - a FAIL in a unit's prelude only. A line planted in the copy's 0006 FAILs when a marker file in the fixture directory exists, and otherwise creates it. The parent's prelude creates it, and every unit then fails its prelude. The prelude's lines appear prefixed `  | `;
  - a member whose sourcing a top-level `a[1/0]=1` cuts short, while later members run. The case first measures, in a child of the same bash, that this ends a sourced file and the rest of the line that sourced it. Where it does not, the case prints skip with that reason.
- **Assertion failures.** Each gives its own FAIL and exit 1, and in record mode writes the manifest as `-j 1` does:
  - a failing assertion;
  - a refusal record planted in a unit, which fails 9990's refusal assertion;
  - a unit that ends outside its `$TMP/cwd`, which fails 9990's floor assertion.
- **The same as `-j 1`.** A planted part with a top-level `x=$((1/0))` between two assertions gives the same (verdict, name) lines under `-j 3` as under `-j 1`.
- **Signals.**
  - A planted part reports its INT, QUIT, TERM and HUP dispositions through perl. It reports the same under `-j 3` as under `-j 1`, from a parent started in each of the four ways: both at their defaults, both ignored, and each one ignored with the other at its default. Each is started through `perl -e '$SIG{INT}=shift; $SIG{QUIT}=shift; exec @ARGV' INT-VALUE QUIT-VALUE`.
  - TERM sent to the parent while units run exits 143.
  - INT sent to a parent started with INT at its default exits 130.
  - Each prints no `reached`, leaves no unit, holder or wrapper running and no slot held, and writes no receipt.
  - A planted unit starts, with `&`, a child that ignores TERM, and waits on it. When the parent is sent TERM the unit dies and the child moves to pid 1. After the parent has ended no such child runs.
  - As above, but the child forks a grandchild after the parent's TERM. After the parent has ended no grandchild runs.
- **An interrupt while a holder waits.** With `FELIX_TEST_SLOTS=1` and another process holding the slot's lock, TERM to the parent starts no unit after the parent has exited.
- **Slots.**
  - With `FELIX_TEST_SLOTS=3`, two `-j 4` runs of planted parts each append `start` and `end` epochs to one file, and the two never overlap more than three units. Without slots they could overlap eight.
  - A slot whose holder was killed with `kill -9` is free at once: a waiting run's `run --part NAME` process appears in `ps` within two seconds.
  - A filesystem or file on which `flock` fails with anything but EWOULDBLOCK makes the holder exit 2, and the parent, which takes and drops one lock before it starts any wrapper, refuses with exit 2 and one line.
  - A name under the slots directory that is not a regular file makes a `-j` run refuse with exit 2.
- **The gate.** gate.sh is run against a stub tests/run that records `$#:$*` and `FELIX_TEST_JOBS`, as 1230 does:
  - with `GITHUB_ACTIONS` unset, `FELIX_TEST_JOBS` equals the core count found the gate's way;
  - with `GITHUB_ACTIONS=true`, it is unset;
  - the argument list is `1:--reuse`;
  - a stub that exits 2 with one stderr line has that line shown under `tests FAIL`.
- **Part mode by hand.** It prints the planted part's lines and the runner lines to stdout.

The blind part runs in CI under bash 5 as well. Every case that measures a shell fact (the arithmetic and signal cases) measures it in that run's own bash.

**Evidence in the PR, made once:**
- **Equivalence on the real suite.** `-j 1` and `-j 8`, both started from a shell with INT and QUIT at their defaults, checked with the perl probe:
  - give the same multiset of (verdict, name) lines, with skips compared by name and by reason;
  - read 0573's and 0574's signal cases ok under `-j 8` wherever they read ok under `-j 1`;
  - print the part sections in the same order;
  - give, in record mode, the same manifest byte for byte and the same red.tsv against one base.
- **The class (D5).** An instrumented serial run lists, for each part, the files it created or changed under `$TMP`, and those under `$HOME` and `${TMPDIR:-/tmp}` outside it.
  - A part that names a path another part (not the prelude) created or changed, by glob, read, listing or a variable, is a candidate.
  - So is a file outside `$TMP` that two parts write, which is a race once they run at once.
  - Each candidate is read by hand and grouped, or shown not to need it. The PR lists every one with its verdict. 0940 and 9990 are among them.
- **The parent.** Its CPU over a full `-j 8` run is at most 5 s, from `ps -o time=`. While a planted 20 s unit runs, a once-a-second `ps` from outside shows its only children are its wrappers.
- **Cost, on a quiet machine, with the 2026-10-10 scripts:**
  - a `-j 8` run's CPU is at most the serial run's, plus 2 s per unit, plus 5%;
  - its wall is reported, not promised.

  Savings are claimed only from CPU measured quiet.
- **The driver's line count**, on D's tree and merged with slot 18.

## Not in this

- CI with `-j`.
- A cache of results across trees.
- Skipping parts a diff cannot reach.
- Splitting long parts or the first group.
- Re-judging a `-j` record run in the parent.
- Any change outside `tests/`, projects/felix/gate.sh and risk.tsv's one row.
