# Contract D: the parallel runner

This is step 3b of docs/2026-10-12-gate-friction-design.md, section 5. It is its own pull request, engine tier, and is built on C (#444), after which it lands. Its version is the next free one when it records.

C made every part run alone. D runs the parts in parallel, so that a suite turns the machine's cores into less wall time. The founder put C and then D ahead of everything else on 2026-10-16.

The design's rule binds every item: weaken no check. That includes weakening by scheduling, where an assertion that a serial run makes over many parts' work is made over less, or is skipped where a serial run makes it.

**Revision 8** (2026-10-19 UTC) amends revision 7 after the second review of its build, in the last section. Revision 7 (2026-10-19 UTC) amended revision 6 after the first review, in the section before it. Each amendment names what it replaces. Revision 6 (2026-10-18 UTC) answered five reviews, kept in audits/2026-10-18-gate-friction-d/:
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

## Amended after review 1 (revision 7, 2026-10-19)

Four lenses reviewed revision 6's build (ae7d1099..266d4bde, with main 655606cf merged in after it). Their reports are in audits/2026-10-18-gate-friction-d/, with the builders' reports (round-1-build1 to 3) and the notes kept during the build (findings-for-review.md). Each amendment names the clauses it changes and the lines it replaces; every line it does not name stands. What an amendment's "D8 gains" lists is added to D8's cases for the blind part. Findings are cited by report and number, numbered in each file's order from 1: **processes** (review-1-processes-and-signals.json), **tests** (review-1-tests-catch-mutations.json), **conformance** (review-1-conformance.json), **weaken** (review-1-weaken-no-check.json), and **notes** 1 to 3 (findings-for-review.md, its entries of 20:55Z, 21:50Z and 22:41Z). A read-only review of this revision's first text found four more, cited as **rev7** 1 to 4 in its order (R8 fails 0290 today, the names a part adds, plain variables, 0710's manifests); R8 and R9 answer them.

Wherever revision 6 counts D3's runner failures or their prefixes as six (D3, D4, D8), read seven: R8 adds one.

### R1. D4, D6: a record run that ends on a runner failure waits for red

Answers processes 1 and notes 1 (its second question) and 3. Revision 6's run wrote `failed` and exited 1 at once, and its EXIT trap removed `$TMP`, the mark with it. Red's monitor then saw no mark and a gone record run, receipt.sh's watcher saw a gone record run, and both stopped red's tree in the same second. Four of red's suites were found stopped under pid 1 in that shape (notes 1 and 3, and two in processes 1). R1 replaces D4's sentences from "`_par_run` itself prints" to "red's suite never sets it", and D6's "apart from the one `_rcp_mark` call D4 names".
- **The run.** `_par_run` prints the log and the runner's failures and writes no manifest, as before. Where `_rcp_red` is set, it then (1) writes the mark with `_rcp_mark failed "$TMP/manifest.mark"`, (2) calls `_rcp_red_end "$TMP/manifest.mark" "$TMP/red.out" 60`, and (3) exits 1, still before the 9990 line. Where `_rcp_red` is unset (red's suite never sets it), it exits 1 after the log. So the mark stays readable until red has acted on it or been ended, and only then does the EXIT trap remove `$TMP`.
- **`_rcp_red_end` takes a bound.** Its third argument, when given, is a number of seconds. It waits for red as now (`_rcp_red_alive`, every 0.1 s for 2 s, then every second), for at most that long. If red still runs then, it ends red's tree with `_rcp_stop "$_rcp_red"` (R2). It then prints red's output and ends the watcher, as now. The tail's call passes no bound and is unchanged.
- **Red acts on `failed` while its suite runs.** On each pass, red's monitor also ends red's suite (R2) when the mark is a regular file whose first line is `failed`. Once its suite and monitor have ended, and before it reads the suite's log, red looks at the mark: a regular file whose first line is `failed` is refused at once, with the reason red gives that mark today, `the record run did not write a manifest (failed)`. red.tsv then holds `base - - -` and `run - - -`, as after the whole suite, only sooner (revision 6's red read the mark only after its suite had run to its end). This holds for a serial record run's `failed` mark too.
- **What is left.** Once such a record run has exited, its watcher has been ended, and no process of red's tree is left, stopped or running.
- **0007 and receipt.sh.** 0007 uses two things of receipt.sh, `_rcp_mark failed` and the bounded `_rcp_red_end`, each only where `_rcp_red` is set.
- **D8 gains:** in a `--red` record copy, every runner-failure case finds red's tree gone once the record run has exited (R12's group check), and red.tsv as D8 says.

### R2. D6: every stopper

Answers processes 1 and 2 and notes 1 (its second question) and 3. Revision 6's ending replaced the set of pids it held with each new listing, so a listing that failed or came back short lost pids it had already stopped. Red's and receipt.sh's stoppers took one listing and sent STOP and then KILL to it, so a stopper killed between the two left its tree stopped. R2 replaces D6's ending steps 1 to 3 (step 4 stands). It binds every stopper alike: the ending, red's `_stop_tree`, receipt.sh's `_rcp_stop`, and R4's two endings (a lost unit's holder, and a holder's own unit).

A stopper is given its roots (the running wrappers, R3's included; red's suite; red; a holder; a unit). It:
1. holds one set of pids, which starts as its roots and only grows: no pid is ever taken out of it;
2. lists with `ps -A -o pid=,ppid=` and adds every descendant, in that listing, of every pid in the set, so every listing is seeded with the whole set. A listing that comes back empty (ps failed, or printed no line) is taken again, up to five tries in all, 0.2 s apart; after the fifth the stopper goes on with the set it holds;
3. sends TERM to every pid in the set, and waits for its roots to go, up to 10 s (30 s in `_rcp_stop`), as now;
4. lists again, adds, and sends STOP to every pid in the set, repeating while a listing adds a pid, up to 30 times;
5. sends KILL to every pid in the set;
6. lists once more, adds, and sends KILL and then CONT to every pid in the set.

**A stopper ignores TERM while it stops.**
- The ending ignores INT, TERM, HUP and QUIT from its first step, whether `_par_sig` or `_fx_exit` called it.
- Red's monitor ignores TERM from the moment it begins to stop red's suite, before it writes `$TMP/gone`. Red, once its suite has ended, sends TERM to the monitor and then waits for it, and `_abort` does the same: a monitor that is not stopping ends at once, and one that is stopping is waited for, not killed.
- `_rcp_stop` runs its steps in a subshell that ignores TERM, and waits for it, so the stop goes on to its end while its caller (the watcher, or the record run's shell) keeps its own disposition.
- The parent's ending of a lost unit's holder holds INT, TERM, HUP and QUIT: a trap records the first to come, and once that ending is done the parent acts on it as D6 says. The holder's TERM handler already returns while it has a child, so its ending of its unit goes on.

**What this gives.** A TERM cannot leave a stopper half done, and when two stoppers work on one tree, the one that finishes last sends KILL and then CONT to all it found. A process can still be left stopped by a stopper that is itself stopped or killed between its STOP and its KILL, when no other stopper that found the process finishes after it; a KILL sent to a process group reaches the stopped processes in it as well. receipt.sh stays under 500 lines (room is made inside it), and red grows as little as it can.

**D8 gains:** a `ps` put first on PATH that fails on the ending's first, second or third listing. With a unit that ignores TERM and forks when it gets one, the parent is sent TERM, and nothing of the run is left, stopped or running.

### R3. D6: a wrapper being forked is recorded

Answers processes 3. Revision 6 recorded a wrapper's pid and state on the line after its fork. Bash runs a pending trap between the two, so a signal that landed there was handled with the wrapper unrecorded, and its holder and unit ran on after the parent had gone. R3 adds to D6's wrapper bullet.
- **Before the fork** the parent marks the unit running with no pid and keeps the value `$!` has then; **after it**, it takes the wrapper's pid from `$!`. The ending (R2) takes `$!` as the wrapper of a running unit with no pid when `$!` differs from the value kept; when it does not, the fork had not happened. On bash 3.2, `$!` already names the new child when the trap runs (processes 3 measured it 12 times of 12).
- **D8 gains:** a copy of many short units under `-j 4`, sent TERM at a spread of short delays after it starts, leaves no wrapper, holder or unit once the parent has exited.

### R4. D6: units that outlive their wrapper, QUIT, and the holder's streams

Answers processes 4 and 8, and conformance 10 (the slot file) and 15. R4 replaces, in D6's holder step 3, "writes the epoch at which it took it to the file the wrapper names", and D6's exit statuses.
- **The slot file.** The holder writes the file its wrapper names (`$TMP/pj/slot.I`) whole each time, through a sibling file and a rename. At its start, before its first try, it writes line 1 `- -`, and line 2: its pid, a space, and its start time as `ps -o lstart= -p PID` prints it, without the newline. Once it holds a slot, line 1 becomes `SLOT-EPOCH FIRST-TRY-EPOCH` (R6), and line 2 stays.
- **A lost unit** (a wrapper gone without a line, D6) has its holder's tree ended as R2 says. The parent reads line 2 of the unit's slot file, and ends the tree only when `ps -o lstart= -p PID` prints the same start time. With no line 2, or with another start time (the pid was reused), nothing is signalled. The unit fails as before (`part ended without its mark`).
- **A holder whose wrapper is gone.** The holder keeps its parent's pid from its start, and compares its parent's pid with it at least once a second, while it waits for a slot and while its unit runs, and once more just before it forks. When they differ, its wrapper is gone and it belongs to pid 1 or a subreaper. It then starts no unit; if its unit runs, it ends the unit's tree as R2 says and reaps it; either way it exits 2. Its wait for its unit is therefore a poll (`waitpid` with WNOHANG). The status it exits with when its unit ends (D6 holder step 4) is unchanged.
- **QUIT.** The parent traps QUIT as it traps INT, TERM and HUP. On QUIT it ends its units and exits 131. A parent started with QUIT ignored cannot trap it, and goes on as a serial run does. An interrupted run exits 130 on INT, 131 on QUIT, 143 on TERM and 129 on HUP.
- **The holder's streams.** The wrapper starts the holder with stdout and stderr appended to the unit's log, `$TMP/pj/log.I`. So no holder, unit or process below them holds the caller's stdout or stderr.
- **D8 gains:**
  - a wrapper killed with `kill -9` while its unit runs a member longer than the parent's silence (D6's `read -t`): the unit fails without its mark, and once the parent has exited, neither that holder nor that unit runs;
  - a wrapper killed with `kill -9` while its holder waits for a slot another process holds: once the slot is let go, no unit of that holder starts, and the holder is gone within 3 s;
  - QUIT sent to a parent started with QUIT at its default: exit 131, no `reached`, no unit, holder or wrapper left, and no receipt;
  - while a unit runs, its holder's stdout and stderr are the unit's log.

### R5. D6a: the slots directory

Answers processes 6, conformance 11 and notes 2. D6a is new. It stands after D6's slots bullet, and replaces the second and third sentences of that bullet's first sub-bullet (from "The parent makes the directory"). D is `${TMPDIR:-/tmp}/felix-suite-slots`, a name that does not change.
- **A relative D** is taken relative to the directory the run started in (`_og_start`), before anything is made or checked, so the parent and every holder name one absolute path. **A missing D** is made with `mkdir -p -m 0700`, which gives D, and only D, that mode.
- **The checks.** Then, whoever made D, the parent checks it before it starts any wrapper. Each failure refuses with exit 2 and the line `tests/run: the slots directory [D]`, followed by `cannot be made` (the mkdir failed and nothing is at D), `is a symbolic link` (its last component is one, whatever it points to), `is not a directory`, `is not owned by this user` (its owner is not the effective user), or `is writable by its group or by others` (its mode has 020 or 002).
- **Every entry.** Every name in D other than `.` and `..` must be a regular file and not a symbolic link, names that start with a dot and names above K-1 included. Any other refuses with exit 2 and `tests/run: [D/NAME] is not a regular file: the slots directory holds slot files and nothing else`, and is never opened. Then, as before, the parent makes any missing slot file 0 to K-1 and takes and drops one lock, and refuses with exit 2 and one line when it cannot.
- **No time limit.** No wait gets one. With the owner and mode checks no other user can hold a slot, and R6 shows a stuck holder of this user's.
- **D8 gains:** D a symbolic link, and D at mode 0775 and at 0757, are refused; a missing D is made at mode 0700; under a relative TMPDIR the slot files are made below the start directory and the run passes; a directory named `.x`, and a directory named `9` beside `FELIX_TEST_SLOTS=2`, are each refused.

### R6. D6: a wait for a slot is visible while it lasts, and S

Answers processes 7, conformance 10 (S) and notes 2. R6 replaces D6's "D3's note's S is that epoch minus the moment the wrapper started", and D6's `read -t 30`.
- **T** is `FELIX_TEST_SLOT_NOTE` when that is a positive integer in plain decimal, with no sign, no leading zero and at most six digits, so a test can use 2. Anything else, or unset, means 300. The parent reads it once, when `_par_run` begins. It reads its FIFO with `read -t W`, W being T when T is below 30, and 30 otherwise.
- **The line.** On every return from that read, a line or a timeout, the parent looks at each running unit that has not had the line. When the unit's slot file (R4) is missing or its first field is `-`, and its wrapper started T or more seconds before (by the shell's `$SECONDS`, so nothing forks), the parent prints to stderr, once for that unit, `tests/run: UNIT has waited T s for a slot and goes on waiting`. It takes nothing over and touches no lock: the unit starts when its holder gets a slot. With T at 300, W stays 30, and the parent's CPU bound stands.
- **S** is the epoch at which the holder took its slot minus the epoch of its first try for one, and 0 when that first try got one. Both are on line 1 of the slot file (R4).
- **D8 gains:** with `FELIX_TEST_SLOTS=1`, the slot held by another process, and `FELIX_TEST_SLOT_NOTE=2`, the parent's stderr holds the line for the waiting unit once, before the slot is let go, and the run then passes. With the slot free there is no such line.

### R7. D2, D3: the wait note's shape, a unit's `reached`, and a prelude FAIL on a partial line

Answers tests 2, conformance 2 and 9, and weaken 6 and 7.
- **The note.** The wait note stays `  note  UNIT waited S s for a slot`. A reader tells it from the tail's `  note  N assertion(s) ran that the manifest does not list.` by that shape alone, `^  note  [^ ]+ waited [0123456789]+ s for a slot$`. Counting every `  note  ` line counts the tail's note too.
- **`reached`.** A `reached` line after `@@prelude-done` in a unit's file is printed in its place as `  | reached`, so the log shows it and it reads as no completion marker. It still gives `part printed a line the runner owns: UNIT`. This replaces "the runner lines are removed" for that one line.
- **A prelude FAIL on a partial line.** The end file gains the record `prefail N`, N being the unit's FAIL counter at `@@prelude-done`: what its prelude counted. The parent also reports `part's prelude failed: UNIT` (the lines from before the mark following, prefixed) when N is above the number of the file's lines before `@@prelude-done` that start `  FAIL  `. An end file without `prefail` is not readable (D3). D2 step 4's list and D3's prelude bullet gain this.
- **D8 gains:** a copy whose manifest lists only the stubs, so that the tail prints its own note, where a unit that waited gives exactly one line of the note's shape; a part that prints `reached`, which shows `  | reached` and gives the owned-line failure; and a line planted in the copy's 0006 that, in units only, prints a FAIL onto a partial line, which gives `part's prelude failed: UNIT` for every unit.

### R8. D2, D3, D5: the shell a unit leaves

Answers weaken 2 and rev7 1, 2 and 3. A serial run carries the main shell's state from each part to the parts after it, and a unit's run carries it nowhere. Revision 6 judged none of it, so a part that leaves something changed can fail the parts after it under `-j 1` while `-j N` passes.
- **`_pm_start` records**, as its last act and into files of the unit's `$TMP`:
  - the output of `umask`, `set +o`, `shopt -p`, `trap -p`, `ulimit -a` and `ulimit -Ha`;
  - which of descriptors 0 to 9 are open, each tested with `{ true >&N; } 2>/dev/null`, which forks nothing and holds for a descriptor open only for reading (measured on bash 3.2.57, 2026-10-19: dup2 does not look at a descriptor's mode);
  - for every variable exported then, inherited ones included, the line `export -p` prints for it, except PWD and OLDPWD (the floor judges the directory);
  - for every variable set and not exported then whose name is in `$TMP/lib-before.names` (the names run writes before it loads tests/lib, run:158), the line `declare -p` prints for it, except the names of the exclusion list below;
  - for every function `declare -F` lists then, a digest of the text `declare -f` prints for it;
  - PATH as it is then.

  `_pm_start` and `_pm_fin` take these with no local variable whose name does not start `_pm`, so what they read is the parts' shell and not their own.
- **The exclusion list**, the plain variables not compared: PASS, FAIL and SKIP; every name that starts `_og_`, `_pm`, `_par_` or `_pj_`, the origin guard's, part mode's and the runner's own; `_fx_walkroot` and `_fx_r`, which 0002's fixture helpers set on every call; every name that starts `BASH`, and SHELLOPTS, which `set +o` covers; PWD and OLDPWD; and bash's own changing variables COLUMNS, DIRSTACK, EPOCHREALTIME, EPOCHSECONDS, FUNCNAME, GROUPS, HISTCMD, LINENO, LINES, OPTARG, OPTERR, OPTIND, PIPESTATUS, RANDOM, REPLY, SECONDS, SRANDOM and `_`. The list is closed. A prelude variable that a helper changes by design, if the sweep below finds one, is remedied in the helper (made local, or its call moved into a subshell); the list grows only by a revision of this contract.
- **The steering list**, the exports whose addition counts: every name that starts `GIT_`, `LC_` or `FELIX_`, and LANG, TZ, HOME, TMPDIR, PATH, CDPATH, ENV, BASH_ENV, SHELLOPTS, BASHOPTS, POSIXLY_CORRECT and XDG_CONFIG_HOME. Each changes what git, the engine, the locale, or the shells and paths of every later part do: an exported GIT_DIR makes `_fx_chdir` refuse every later fixture git command (0002:217).
- **`_pm_fin`**, first, before anything else it does, takes them again and compares. Each change is one line:
  - `umask WAS is now NOW`;
  - `WAS-LINE is now NOW-LINE`, for a `set +o` or `shopt -p` line that differs (`shopt -u nullglob is now shopt -s nullglob`);
  - `ulimit -a: WAS-LINE is now NOW-LINE` or `ulimit -Ha: WAS-LINE is now NOW-LINE`, for a limit line that differs, the lines taken in order;
  - `trap on SIGNAL changed`, `added` or `removed`;
  - `descriptor N opened` or `descriptor N closed`;
  - `export NAME changed` or `removed`, and `export NAME added` for a name of the steering list;
  - `variable NAME changed` or `removed`, for a recorded plain variable whose `declare -p` line differs or which is unset;
  - `function NAME changed` or `removed`; and `function NAME added over a builtin`, `over a keyword` or `over a command`, for a function that `declare -F` did not list at `_pm_start` and whose name is a builtin of the shell (`compgen -b`), a keyword (`compgen -k`), or a name for which `type -P NAME`, with PATH as `_pm_start` recorded it, prints a path.

  No value is printed. Any other export, variable or function a part adds is not a change.
- **Not compared, and why.**
  - *Variables of tests/lib*, which the lib files and their `_vars` functions set after `$TMP/lib-before.names` is written. The lib's helpers rewrite them on every call (`_ibopen` sets IB_F, lib/inventory-blind.sh:58; `_au_open` sets `_AU_F`, lib/audit.sh:21), and parts set them before a call (0920:3 sets IB_BR, 0820:154 sets `_AU_F`), so comparing them would fail parts that do what the lib asks of them. A carried value matters only to a later part that reads one before it sets it, which is what the sweep looks for.
  - *What an open descriptor names.* It cannot be read without a fork on macOS, where `[ /dev/fd/1 -ef FILE ]` is false when descriptor 1 is open on the regular file FILE (measured 2026-10-19). Whether a descriptor is open is compared, since one of 3 to 9 left open reaches every child of every later part under `-j 1`, and a pipe held open there keeps its reader from its end. A part that leaves descriptor 1 pointing elsewhere also loses its unit's marks, which D3 already fails. The sweep records where each part leaves descriptors 0 to 9 pointing.
- **The end file** gains `shell ok`, or `shell changed` followed by one `shellmsg LINE` per change. An end file without a `shell` record is not readable (D3). D2 step 4's list gains it.
- **The seventh runner failure.** `shell changed` gives `  FAIL  part left the shell changed for the parts after it: UNIT`, after the unit's other runner failures, followed by each change as `  | LINE`. It is a runner failure like D3's other six: it adds 1 to FAIL and calls no `_ran`; it withholds the manifest in a record run and leaves no receipt; red leaves it out of its counts and names with the other six prefixes, and refuses no log for it; and no manifest name starts with its prefix. Under `-j 1` nothing is compared: a change carries to the parts after it, as today.
- **The class (D5, D8's evidence).** The instrumented serial run records, for each part, every shell change it leaves: all that `_pm_fin` compares, every variable of tests/lib it changes or removes, where it leaves descriptors 0 to 9 pointing, and every name it newly exports, sets or defines.
  - *Every change `_pm_fin` would report is remedied* before the comparison binds: the part, or the helper that made it, is changed so that it leaves none. None is kept as harmless, since a kept one would fail every `-j N` run. Two are known:
    - 0290 unsets seven functions of tests/lib/bw.sh when it ends (0290:57-58: `_bwago`, `_bwstamp`, `_bwday`, `_bwmt`, `_bwreset`, `_bwg` and `_bwrepo`), seven `function NAME removed` lines in 0290's unit. It stops unsetting them and unsets only the names it and 0280 define, and lib/bw.sh's header (lib/bw.sh:12-13) drops "0290 unsets all of these when it ends". The serial run then hands them to the parts after 0290, as every unit's prelude does.
    - 0681 assigns and then unsets `_ffw` (0681:566 and 777), a name part 0005 sets (0005:329), `variable _ffw removed` in 0681's unit. It uses a name of its own instead.
  - *What is recorded and not compared* (variables of tests/lib, descriptors' targets, other new exports, new variables, new functions that hide nothing) is shown in the PR, each one harmless, with the reason (no later part reads it before setting it), or remedied, with the commit.
  - The sweep also shows that today's suite adds no export of the steering list and no function over a builtin, keyword or command.
- **D8 gains:**
  - under `-j 3`, each of these planted parts gives the seventh failure with its `  | ` line, exit 1 and no receipt, and in a `--red` record copy no manifest: `umask 077` left set; `shopt -s nullglob` left set; `trap : USR1` left set; PATH changed; a variable the case exported before the run unset; a function of tests/lib redefined; a function of tests/lib unset, as 0290 did; `git() { :; }` left defined (`function git added over a command`); `export GIT_DIR=/x` left set (`export GIT_DIR added`); FELIX given another value (`variable FELIX changed`); descriptor 7 left open (`descriptor 7 opened`); a soft limit lowered with `ulimit -S` below the value the case read first;
  - each of these passes under `-j 3`: a part that exports a new name outside the steering list, one that sets a new variable, one that defines a new function whose name is no builtin, keyword or command, and one that changes a variable of tests/lib (`IB_BR=x`);
  - under `-j 1`, none of them gives the seventh failure.
- **D8's evidence gains:** the `-j 8` run of the equivalence evidence gives no seventh failure, and the PR holds the sweep's record of each part's shell changes, with each one's verdict.

### R9. D5: a third remedy, part 0710, risk.tsv and groups.tsv

Answers weaken 1 and 3, conformance 12 and rev7 4.
- **Builders.** A part cannot be grouped when its inputs come from parts that are not contiguous with it, or from more than six. It then gets them from tests/lib builders that make every input the serial run hands it, as C's do. A builder makes each input as the serial run leaves it for that part, in everything the part reads. It does nothing once the input is there, so in the serial run only the first caller builds, and the serial run is unchanged.
- **Part 0710 is the first.** Its check (0710:259-279) takes `_gfiles`, every `projects/*/stack.tsv` whose header line ends in a tab and `grounding` (0710:267), and judges every row of each. In the serial run `_gfiles` holds every such manifest that the parts before 0710 left, and 0710 gets each of those projects from a builder. The set is what D5's instrumented serial run lists when 0710 starts. These are known:
  - cmproj and cmstranger, from `_commissioning_build after-0700`, which 0710:12 already calls;
  - stranger, which 0010 makes through `_stranger_build` (tests/lib/cm-stub.sh);
  - setupproj (0190:203-208), cmwebapp (0700:520-527) and hookproj (0060:398-425, adopted by hooks/session-start through lib/adopt.sh:75, which writes the grounding header, and removed by no part). Their fixtures move into tests/lib builders, which 0190, 0700 and 0060 call in their place, as 0010 calls `_stranger_build`;
  - any other the sweep lists, made the same way. Twelve more parts before 0710 run session-start (0120, 0180, 0190, 0220, 0250, 0320, 0330, 0380, 0460, 0671, 0680 and 0681), and the sweep reads what each leaves.

  A stack.tsv without the header (widget's after 0230's `_router_build`, lib/router.sh:49; holdproj's and quietproj's, 0380:180 and 220) is outside `_gfiles` and needs no builder. 0710 calls every builder before its check.
- **0710 says when a builder is missing.** The builders' file names, in one list, the projects they make. In every run, 0710's existing assertion "the engine writes manifests carrying the grounding column" also fails when `_gfiles` holds a project that is neither in that list nor made by 0710 before its check, with a detail naming each such project and saying that it has no builder. So a part added before 0710 that leaves such a manifest fails the serial run, CI's included, until its project has a builder, and `-j N` cannot read fewer manifests than `-j 1` without a run saying so. It adds no manifest name.
- **The evidence.** The PR shows, from one `-j 1` run and one `-j 8` run, that `_gfiles` names the same projects in both, and that each file in it holds the same rows once each run's `$TMP` is written as one placeholder.
- **risk.tsv.** D5's clause also gives yellow verifier rows with no confine to `^engine/harness/tests/parts/0007-the-parallel-runner\.sh$` and to `^engine/harness/tests/(red|receipt\.sh)$`, for groups.tsv's reason: a change there can weaken a check without removing an assertion line. "Not in this"'s last bullet now reads "Any change outside `tests/`, projects/felix/gate.sh, risk.tsv's three rows, and the one row in engine/harness/templates/schemas.tsv that declares groups.tsv". That row is 377b12e9, which part 0730 needs, since it refuses an undeclared tracked table.
- **groups.tsv** ignores empty lines, as it ignores comments.
- **D8 gains:** a groups.tsv with empty lines among its members gives the same groups as one without them.

### R10. D1 and D4: FELIX_TEST_JOBS where N must be 1

Answers conformance 7 and 8, and weaken 8.
- **The gate.** When `GITHUB_ACTIONS` is `true`, gate.sh runs tests/run with `FELIX_TEST_JOBS` removed from its environment (`env -u FELIX_TEST_JOBS`), so CI's gate runs N = 1 whatever it inherited. Otherwise it sets the variable to the core count, as D1 says.
- **Red** removes `FELIX_TEST_JOBS` as well as `FELIX_TEST_RED_JOBS` from its environment when it starts, so its suite runs `-j N` only from a valid `FELIX_TEST_RED_JOBS`.
- **D8 gains:** the gate with `GITHUB_ACTIONS=true` and `FELIX_TEST_JOBS=7`, where the stub sees it unset; red by hand with `FELIX_TEST_JOBS=3`, where its suite runs serially; and red by hand with `FELIX_TEST_JOBS=abc`, where its suite does not refuse.

### R11. D7: the budget, as it now is

Answers conformance 16. Slot 18 is in C, which landed on main as 655606cf. The driver is 470 lines there, and 475 on this branch after main's merge. Its limit is 500 (1040:23), and R12's two part lines bring it to 477. The build shows that one count. R11 replaces the premise line "The driver is 458 lines on C. Slot 18 adds about 31, and 1040:23 caps it at 500.", D7's budget bullet with its two sub-bullets, and D8's last evidence bullet, which now reads "The driver's line count on D's tree."

### R12. D8: the blind parts

Answers tests 3 and 15, conformance 3, 4 and 5, weaken 4, processes 5 and notes 1 (its first question). On 2026-10-18 at 23:05:50Z a reviewer's `pkill -f 'sleep 3'` could reach 1292's fixtures in other sessions' runs. R12 adds to D8's opening.
- **Every case ends every process it started.** Each inner run goes under a bounded runner that makes its own process group, as 1291 and 1292 do. After the run, and in a `--red` copy after red has gone, the case waits up to 30 s for that group to hold no process, stopped or running, zombies aside, read from `ps -A -o pid=,pgid=,stat=`. It fails when a process is left, naming it, and then sends CONT and then KILL to every pid left in the group, so the part never leaks. A process the case starts outside such a group (a slot holder, a sleeper) is ended by the pid the case recorded.
- **Bounded runners.** Every bounded runner sets, in its child before exec, INT and QUIT as the case asks, and HUP and TERM to their defaults, so the HUP and TERM cases hold under nohup.
- **No pattern kills.** No case kills by pattern: no pkill, no killall, no pgrep piped to kill. Every signal goes to a pid the case recorded, or to its own process group.
- **The cut.** Parts 1291 and 1292 are cut along their sections: 1291 into 1291 and 1293, and 1292 into 1292 and 1294. Each of the four is at most 600 lines and is meant to run alone in at most five minutes on a quiet machine, and the PR reports each one's wall time alone. The driver gains the two part lines, in number order. The cut removes no case, and the sleepers are cut to what their cases need.
- **Skip branches.** A case that measures the shell and branches reaches, in its skip branch, exactly the names its run branch reaches, each once.

### Every other finding

Test fixes go to a blind author with this revision, before any code fix. Code fixes go to the builders once the new blind tests are red.

**Test fixes (no contract change):**
- tests 1, conformance 1, weaken 5: run by hand, a part sees `FELIX_TEST_RECORD` as 0 (run:141 sets it), so 1291 expects `djx-rec:0`.
- tests 2, conformance 2, weaken 6: 1292's two note counts match R7's shape.
- tests 4: a `--red` case with a runner failure in red's suite only, from a part that dies only under `FELIX_TEST_NO_MANIFEST=1`, and its twin that prints `reached` there only.
- tests 5: the reverse marker cases, in which only the parent's prelude fails, records a refusal, or moves the origin.
- tests 6: every interrupt case finds the slot files afterwards, with the same names and inode numbers.
- tests 7: a background child that a unit leaves running holds no slot lock.
- tests 8: every planted part prints `djx-rec`, so a `-j` record run shows `FELIX_TEST_RECORD=1` in every unit, and a plain run shows 0.
- tests 9: the check that 0001 sets the jobs variable before `$TMP` skips comments and looks for an assignment.
- tests 10: the hostile durations rows go to units that have no other row, and the error grep gains `value too great`.
- tests 11: red over a base whose groups.tsv the tree lacks; an invalid `FELIX_TEST_RED_JOBS`; and the `-j 3` name made to say what 1291:150 measures.
- tests 12: a unit with no `@@prelude-done` at all gives `part's prelude failed`.
- tests 13: an empty `FELIX_TEST_JOBS`, `--part` naming 0007, and `FELIX_TEST_JOBS` unset in parts when `-j` is also given.
- tests 14: "within two seconds" timed in milliseconds, the overlap cap sampled from unit processes, and 1292:545's name made to say what it checks.
- conformance 6: the unit-prelude case asserts red.tsv's two rows, as every other runner-failure case does.

**Code fixes (no contract change):**
- conformance 13: red makes its filtered log with `grep -a`, or drops the prefixes inside its existing awk passes, so a NUL byte cannot turn the log into "Binary file matches".
- conformance 14: `_par_order` and `_par_cores` spell their digit sets out, as `[123456789]` and `[!0123456789]`.

**Deliberately not taken:**
- processes 1's other remedy, the mark kept outside `$TMP`: R1 keeps it there and waits for red instead.
- processes 2's refusal before the first wrapper when `ps` does not list the parent: R2's retried, growing listing covers a listing that fails at the ending, and a refusal at the start would stop a run over a passing ps failure that the run might never meet again.
- processes 4's other remedy (D6 says QUIT is not covered) and conformance 15's (D6 says a lost unit's holder is outside the ending): R4 covers both.
- processes 7's line from the holder: the holder's stderr is now its unit's log (R4), which is printed only once the unit ends, so the line comes from the parent (R6).
- conformance 9's other remedy, a unit's `reached` removed: R7 prints it.
- conformance 10's other remedy, S measured from the wrapper's start: R6 makes the build's reading the rule, so a loaded machine's perl start-up never reads as a wait.
- conformance 11's other remedy, D6 and D8 narrowed to a slot's name: R5 checks every entry.
- conformance 12's other remedy, an empty groups.tsv line refused: R9 ignores it.
- tests 3, conformance 3 and weaken 4's other remedy, HUP probed and the case skipped when it is ignored: R12's runners reset HUP and TERM, so the cases run under nohup and never skip for it.
- rev7 1's other remedy, an exemption list of changes kept as harmless: R8 remedies every change it would report (0290 and 0681 first) and keeps none. Its exclusion list holds only the counters, the runner's and the guard's own state, two fixture-helper registers and bash's own variables, never a change a part was found to leave.
- rev7 2's wider remedy, every export a part adds counted: R8 counts the steering list's names, which change what every later part's git, engine, locale and shells do. Any other new name is read only by the stubs that read it, and the sweep records each one for the PR.
- rev7 3's remedy taken in part: the prelude's plain variables are compared (R8); the variables of tests/lib and what a descriptor names are recorded by the sweep and not compared, for the reasons R8 gives.
- rev7 4's class remedy, every unit's manifests judged at `_pm_fin` and folded in the parent: it would be a new whole-run check, printed outside 0710's section, which D5 does not add. R9's builders keep the check in 0710, and 0710's report of a project with no builder keeps that remedy from going stale.

## Amended after review 2 (revision 8, 2026-10-19)

Two lenses reviewed revision 7's build (565e0711..edb64588, with main b103f04a, 0.49.302, merged in at 286fbca0). Their reports are in audits/2026-10-18-gate-friction-d/, cited by report and number, numbered in each file's findings from 1: **proc2** (review-2-processes-and-tests.json) and **conf2** (review-2-conformance-and-weakening.json). The round-1 fix reports are cited as **buildA**, **buildB**, **blind1** and **blind2** (fix-1-buildA.txt, fix-1-buildB.txt, fix-1-blind1.txt, fix-1-blind2.txt). Revision 7's conventions hold: each amendment names the clauses and lines it replaces, every line it does not name stands, and its "D8 gains" are added to D8's cases for the blind parts. File and line references are to edb64588. Every measurement this section reports as made for it was made on this Mac's /bin/bash 3.2.57 on 2026-10-19. A read-only review of this section's first text found two more, cited as **rev8** 1 and 2 in its order (a ticker started with TERM ignored, and R14's presence decided by pid alone); R13 and R14 answer them.

### R13. D6, R6: the parent never waits in an alarm-timed read

Answers proc2 1 and 4. On bash 3.2 a trap runs inside the signal handler while `read -t` blocks, and the read's own alarm then abandons the trap partway. proc2 1 measured this with 0007's own functions: `_par_sig` was cut when the read's 3 s ran out, the shell went on past the read with its signals ignored, and a wrapper and its TERM-ignoring child ran on. Measured again for this revision:
- a TERM trap that runs 4 s, sent 1 s into `read -t 3`, was cut at 3 s, and the script went on and exited 0. Sent into a plain `read`, it ran to its end and the script exited 143;
- an EXIT trap that runs 4 s, run by an untrapped USR1 sent 1 s into `read -t 3`, was cut when the shell died with 142 (SIGALRM). During a plain `read` it ran to its end, and the shell then died of USR1 (158).

So the ending can stop between STOP and KILL and leave processes stopped, holding their slots. Bash 5.2 was not measured, and the rule below does not depend on it. R13 replaces R6's sentence "It reads its FIFO with `read -t W`, W being T when T is below 30, and 30 otherwise.", R6's "On every return from that read, a line or a timeout", D6's "with `read -t 30`" and its "On a timeout" (R14 replaces the rest of that sentence), and, in R4's first D8 gain, "the parent's silence (D6's `read -t`)", which now reads "W (R13)".
- **The ticker.** One perl, which the parent starts in `_par_run` once its FIFO is open and before its first wrapper, as a job of its own, with stdin, stdout and stderr on /dev/null and descriptor 63 closed. It opens the FIFO for writing itself and writes the line `@@tick` to it every W seconds, each line with one `syswrite`. Once a second it compares its parent's pid with the one it started with, and it exits when they differ or a write fails. W stays R6's: T when T is below 30, else 30.
  - **Its signals.** Its first act is to set TERM and HUP to their defaults and unblock them, as 0530:417's perl sets INT, TERM and HUP to theirs. A ticker started by a parent that ignores TERM or HUP would otherwise ignore them too, and it exits only on a change of parent or a failed write, so a TERM to it would end nothing (rev8 1). INT and QUIT stay as every job starts with them, ignored (What decided the list).
  - Measured for this revision: under `perl -e '$SIG{TERM}=$SIG{HUP}="IGNORE"; exec @ARGV' /bin/bash`, a perl started with `&` read both as `IGNORE` and was still running after a TERM. Once it had set them to `DEFAULT`, a TERM ended it, and `wait` returned 143.
- **One of the ending's roots.** The ending's roots (R2) are the running wrappers, R3's included, and the ticker, in `_par_sig` and in `_fx_exit` alike. `_fx_exit` runs the ending whenever wrappers or the ticker still run, and the ending's `wait` (D6's step 4) waits for the ticker too. When its loop ends with no signal, the parent sends KILL to the ticker's pid and waits for it, before it closes the FIFO. The ticker holds nothing, and each `@@tick` is one write of 7 bytes, below PIPE_BUF, so a KILL leaves no part of a line in the FIFO, and it ends the ticker whatever its dispositions and its signal mask.
- **Reads.** Every read of the FIFO is a plain `read -r -u 63`. A `@@tick` stands for what a timeout was: in the main loop it is followed by `_par_gone` (R14), as a timeout was. R6's look at the waiting units follows every line the parent reads, a `@@tick` or another.
- **`_par_gone`'s one more second.** The second that `_par_gone` gave to a line written as its wrapper went (`read -t 1`, 0007:506) is given by the FIFO's order instead.
  - The parent writes the line `@@gone` to its own FIFO with the builtin printf and reads on. It handles every line before it as the main loop does, and passes over a `@@tick` among them.
  - Each wrapper found gone that has no line by the time `@@gone` is read back is lost (R4).
  - A wrapper writes its line before it exits, and the parent finds it gone only after it has exited, so its line is read before `@@gone`, however many `@@tick` lines wait ahead of it.
  - The next `@@tick` would not do. When the parent has fallen W behind its ticker (ending a lost unit's holder takes up to 10 s), that tick was written before the wrapper's line, and a unit that ended well would read as lost.
- **The rule.** No `read -t` in the `-j` parent: in `_par_run` and in everything it calls, the ending included.
- **What is left.** The ticker is not started again. If something outside the run ends it, the parent learns of units only from their lines. A wrapper gone without a line is then never found, and the run waits, as a run whose unit hangs waits, until it is interrupted.
- **D8's evidence.** "shows its only children are its wrappers" now reads "shows its only children are its wrappers and its ticker".
- **D8 gains:**
  - with `FELIX_TEST_SLOT_NOTE=2` (W is 2, so the ending outlasts what a 2 s `read -t` left it) and a unit that ignores TERM, TERM to the parent once the unit is up gives exit 143, no `reached`, nothing of the run left, stopped or running, and no slot held;
  - the same with INT, sent to a parent started with INT at its default, and a unit that ends at once when signalled, gives exit 130;
  - USR1, which the parent does not trap, sent while two units run: the EXIT trap's ending completes, no `reached` is printed, and nothing of the run is left;
  - in proc2 7(a)'s dispositions runs, the parent started with TERM ignored, and the one started with HUP ignored, each run their `-j 3` copy of units that pass and exit 0, not run.pl's 124, and once each has exited nothing of its process group is left, the ticker included (rev8 1).

### R14. D6, R2: a pid that may have been reused

Answers proc2 9 and rev8 2. A stopper's set only grows (R2), so a pid that exited during the TERM wait still got STOP and the last KILL, whatever process held that pid by then. This section's first text sent KILL only to the pids of the set present in the latest listing, decided by pid alone. A reused pid is an ordinary row of `ps -A -o pid=,ppid=`, so that closed only the microseconds between the last listing and the KILL, and step 4's STOP still went to the whole set (rev8 2). And `kill -0` of a wrapper that bash had already reaped asked about whatever process held its pid next. R14 replaces R2's steps 1 to 6, with their "lists with `ps -A -o pid=,ppid=`", and D6's "checks each running wrapper's pid with `kill -0`, a builtin". As R2 does, it binds every stopper: the ending, red's `_stop_tree`, receipt.sh's `_rcp_stop`, the parent's endings of a unit's tree (R4, R15), and the holder's own stopper (its perl, 0007:51-58). Wherever this contract says "as R2 says", R2 reads as R14 has it.
- **A member is a pid and its start time.** Every listing is `ps -A -o pid= -o ppid= -o lstart=`. lstart, which holds blanks, is the last column, so a row's start time is the rest of its line after its second field, with the blanks at its two ends trimmed and those inside kept. That is what `ps -o lstart= -p PID` prints, trimmed as R4 trims it. Measured for this revision: macOS pads the column with blanks at its end, and the two agree once trimmed. Each member of the set is held with the start time it had when it joined:
  - a descendant, with the start time of its row in the listing that adds it;
  - a root whose caller recorded its start time, with that one: a lost unit's holder (line 2 of its slot file, R4), a unit whose holder died (`unit.I`, R15), red in receipt.sh (`_rcp_redsig`, receipt.sh:439), and red's suite, whose start time red now reads with `ps -o lstart= -p` right after it starts it, as receipt.sh reads red's;
  - any other root, a child of the process that runs the stopper, which lives while it stops: the `-j` parent's wrappers and ticker, and a holder's own unit. It takes its start time from its row in the first non-empty listing, when that row has that process (`$$` in the parent's shell, the holder's own pid in its perl) as its parent. A root that listing does not show with that parent is never present;
  - a root whose recorded start time is empty (ps gave no answer when it was read): it is present in a listing that has a row with its pid, as R2 had it.
- **Present.** A member is present in a listing when the listing has a row with its pid and its start time. A row with its pid and another start time is another process. No later listing shows that pid with the member's start time again, so a member found so is never signalled again.
- **The steps.** A stopper:
  1. holds one set of members, which starts as its roots and only grows: no member is ever taken out of it;
  2. lists, and adds every descendant, in that listing, of every member present in it. A listing that comes back empty (ps failed, or printed no line) is taken again, up to five tries in all, 0.2 s apart; after the fifth the stopper goes on with the set it holds;
  3. sends TERM to every member present in the most recent non-empty listing, and waits for its roots to go, up to 10 s (30 s in `_rcp_stop`), as now;
  4. lists again, adds, and sends STOP to every member present in the most recent non-empty listing, repeating while a listing adds a member, up to 30 times;
  5. sends KILL to every member present in the most recent non-empty listing;
  6. lists once more, adds, and sends KILL and then CONT to every member present in the most recent non-empty listing.

  When every listing the stopper took came back empty, no descendant has joined, and steps 3 to 6 signal every root by its pid, as R2 had it.
- **Nothing it stopped is left stopped.** A member sent STOP was present in the listing just before it. A stopped process cannot exit by itself, so until some stopper's KILL ends it, every later listing shows it, and step 5 or step 6 sends it KILL.
- **The wait** in step 3 is unchanged. A root's pid taken again during it can only make it last to its bound.
- **What is left.**
  - A pid taken again by a process that started within the same second as the member it replaces reads as that member. That needs the pid space (99999 on macOS) to wrap within that second.
  - When every try of a step's own listing came back empty, its signals read an older listing, and a pid taken again since that one is not told apart.
  - procps derives the start time it prints from the boot time in /proc/stat, which a step of the clock moves. A step while a stopper works on ubuntu would make its members read as not present, and it would send them nothing more, so what it had stopped would stay stopped until another stopper ends it. macOS keeps a process's start time with the process. Not measured.
- **A wrapper gone.** `_par_gone` tells that a wrapper is gone from the shell's own job table, not from `kill -0`. It writes `builtin jobs -rp` to `$TMP/pj/jobs`, with stderr to /dev/null, and reads it back with `read`, which forks nothing. A running unit's wrapper whose pid that file does not hold is gone.
  - The builder measures on bash 3.2, and reports, that `jobs -rp` lists a running `( ) &` wrapper, stops listing it once it has ended, killed or not, and that the ending's `wait` for it still returns.
  - Measured for this revision: a `sleep 3 &` was listed; 0.2 s after a TERM it was not; `wait` for it then returned 143. A child started as `( sleep 2 & )` was never listed.
- **Unchanged.** The holder's check of its parent (R4).
- **D8 gains.** A reused pid cannot be made on demand, but a start time that differs can be shown:
  - a `ps` put first on PATH that runs the real one and passes its output on, except that from the ending's second listing on it prints a start time one second later on the row of a planted process P. P is started with `&` by a unit, writes its pid to a file, appends one line to a second file for each TERM it gets, and goes on running. TERM to the parent once P is up: once the parent has exited, P runs and is not stopped (its `ps -o stat=` holds no `T`), and its second file holds exactly one line. The case then ends P by its pid.

### R15. D6, R4: the parent killed with -9, and a holder killed with -9

Answers proc2 10. R4 left two losses:
- A parent killed with -9 runs no trap. Its holders check only their wrappers, so they run their units to the end with their slots held.
- A holder killed with -9 frees its slot at once, while its unit, now below pid 1, runs on, so more than K units can run on the machine.

R15 adds to R4.
- **(a) The parent gone.** Each holder is also given the `-j` parent's pid and its start time as `ps -o lstart= -p PID` prints it, blanks trimmed. The parent reads its own start time once, at the head of `_par_run`.
  - Wherever R4 has the holder check its wrapper (at least once a second while it waits for a slot and while its unit runs, and once more just before it forks), it also checks that parent with perl's `kill 0`, which forks nothing. A failure, for any reason, is the parent gone.
  - At least once every 10 s, and just before it forks, it also reads the parent's start time with `ps -o lstart=`. An answer that is not empty and differs from the one it was given is the parent gone: another process has its pid. An empty answer decides nothing until the next check.
  - It treats that parent gone, or started at another time, exactly as its wrapper gone (R4). It starts no unit. If its unit runs, it ends the unit's tree as R2 says and reaps it. Either way it exits 2.
  - Its wrapper then writes its line to the FIFO, which it holds open, and exits. The ticker exits too, since its parent's pid has changed (R13).

  So within about 3 s of a kill -9 of the parent, no holder or unit of the run runs and no slot is held. That holds for a unit that does not ignore TERM; one that does goes at the stopper's KILL, after its 10 s.
- **(b) A holder killed.** Right after it forks its unit, the holder writes one line to `$TMP/pj/unit.I`: the unit's pid, a space, and the unit's start time as `ps -o lstart=` prints it. It writes the file whole, through a sibling file and a rename.
  - Only that holder writes the file. It is neither `$TMP/pj/slot.I`, whose two lines stay as R4 fixes them, nor the slot's file in the slots directory, which no holder writes (D6).
  - When a wrapper's line gives the holder's status above 128, the parent reads `unit.I` before it marks the unit ended. It ends that unit's tree as R2 says, holding its signals as R2 has it hold them for a lost unit's holder, only when `ps -o lstart= -p PID` still prints the start time recorded.
  - With no `unit.I`, or another start time, nothing is signalled. A status above 128 also comes from a unit that died of a signal under a living holder (D6, holder step 4), which that holder has reaped.
  - The unit then fails as D3 says for a unit that ended without its mark.
- **D8 gains:**
  - the parent killed with `kill -9` while a unit runs a long member: within 3 s no holder or unit of the run is left, stopped or running, and a test `flock` (`LOCK_EX | LOCK_NB`) on the slot's file in the slots directory succeeds;
  - a holder killed with `kill -9` while its unit runs (its pid read from line 2 of its `$TMP/pj/slot.I`): within 3 s the unit is gone, the run fails naming it (`part ended without its mark: UNIT`), and once the parent has exited nothing of the run is left.

### R16. R8 widened: what a unit's shell is compared on

Answers conf2 1, 2, 3, 8 and 9. In R8, R16 replaces:
- the descriptor sub-bullet of "`_pm_start` records";
- the steering-list bullet, which is withdrawn;
- in `_pm_fin`'s list, "and `export NAME added` for a name of the steering list";
- "Any other export, variable or function a part adds is not a change.";
- OPTIND in the exclusion list;
- "other new exports" in the class's "What is recorded and not compared";
- "The sweep also shows that today's suite adds no export of the steering list and no function over a builtin, keyword or command.";
- the passing case "a part that exports a new name outside the steering list".

It also withdraws revision 7's "Deliberately not taken" entry for rev7 2's wider remedy, which R16 takes.
- **Descriptors.** Descriptors 0 and 3 to 9 are tested as now, with `{ builtin true >&N; } 2>/dev/null`. Descriptor 1 is tested with `{ builtin true <&1; } 2>/dev/null`, and descriptor 2 with a bare `builtin true >&2`, which fails silently when 2 is closed.
  - conf2 1 measured why R8's form is vacuous for both: with 2 closed, the group's own `2>/dev/null` opens 2 before the test runs, and `>&1` asks for no dup at all.
  - Measured for this revision: with 1 closed, `{ true <&1; } 2>/dev/null` fails, and with 2 closed, `true >&2` fails.
- **Jobs.** `_pm_start` records `jobs -rp` (the builtin, to a file of the unit's `$TMP`), and `_pm_fin` reports `job PID left running` for each job running then that was not running at `_pm_start`.
  - Under `-j 1` a later part's bare `wait` (0150, 0330) waits for such a job. Under `-j N` the unit ends and the job is orphaned.
  - A child started as `( cmd & )` is no job of the unit's shell, and is outside this, as D6's "Reach" says.
- **Exports.** Every export a part adds counts: `export NAME added`, for every name that `export -p` prints at `_pm_fin` and did not print at `_pm_start`, PWD and OLDPWD aside.
  - R8's steering list is withdrawn. Its premise, that any other name is read only by the stubs that read it, is false: conf2 3 found CLAUDE_CONFIG_DIR read by lib/cost.sh:157 and lib/status.sh:50, XDG_RUNTIME_DIR and RUNNER_TEMP by tests/lib/reach.sh:97-100, and PERL5OPT by every perl.
  - The allowlist of added exports kept is closed and empty. It grows only by a revision of this contract, each name with its reason.
- **Plain variables the main shell itself reads.** A variable that was not set at `_pm_start`, and is set and not exported at `_pm_fin`, gives `variable NAME added` when its name is CDPATH, GLOBIGNORE, LANG, TZ, TMOUT, TIMEFORMAT or POSIXLY_CORRECT, or starts `LC_`. Each of these steers the main shell itself, and so every later part of a serial run: its `cd`, its globs, its collation, its clock, its reads' timeout, `time`'s format, or POSIX mode.
- **State not compared before**, each with its line:
  - `$#` and the text of each positional parameter: `positional parameters changed`. A file sourced with no arguments shares the main shell's positional parameters, and a function sees its own. Measured: `set -- x y` in such a file left the caller with `2 x y`, and a function called with no arguments saw `$#` as 0. So the driver's two hand-over calls (run:214 and 221) pass them on: `[ -z "${_pm1:-}" ] || _pm_start "$@"` and `[ -z "${_pm1:-}" ] || _pm_fin "$@"`. These are the only driver lines R16 changes, and it adds none;
  - `enable -n`: `builtin NAME disabled`, or `builtin NAME enabled` for one disabled at `_pm_start`;
  - `dirs -p` past its first line, which is the working directory the floor judges: `directory stack changed`. DIRSTACK stays excluded as a variable;
  - OPTIND, taken off the exclusion list: `variable OPTIND changed`;
  - `readonly -p`: `readonly NAME added`, for a name that was not readonly at `_pm_start`. Measured: it prints `declare -r NAME="..."`.
- **Not compared, with the reason: the command hash table.** Bash empties it whenever PATH is assigned, and PATH is compared. `type -P` prints a hashed value, so comparing the table would need a walk of PATH. The sweep records that no part's top level runs `hash -p`.
- **Through `builtin`.** `_pm_start` and `_pm_fin`, and what they call to take, compare and write (`_pm_snap`, `_pm_diff`, the end file and the mark), call every builtin they use through `builtin`: `builtin printf`, `builtin read`, `builtin local`, `builtin compgen`, `builtin type` and the rest. They call perl, and every other command they run, through `builtin command`, with PATH as `_pm_start` recorded it. So no function a part leaves defined can stand in for the snapshot or the comparison. conf2 8 measured that `perl() { :; }` hides every change, and that `compgen() { :; }` hides itself.
  - **A disabled builtin.** Measured: once `enable -n printf` has run, `builtin printf` fails with "not a shell builtin". So `_pm_fin` takes `builtin enable -n` first of all. Then it enables again, with `builtin enable NAME`, each builtin disabled then that was not disabled at `_pm_start`, and only then takes the rest. Its lines come from what it took first.
  - **What cannot be guarded.** A function named `builtin`, or `builtin` or `enable` disabled, leaves these calls without effect. The end file and the mark are written by these calls too, so that unit has no readable end file and no mark, which D3 fails. Any step of the comparison that fails gives a change line, as `_pm_diff` already does (`the shell state could not be compared`), and never `shell ok`.
- **No value is printed**, apart from a job's pid.
- **Pin: trap names.** `trap on NAME` takes the name as `trap -p` prints it, as its last word: `SIGUSR1`, `EXIT`. Measured: `trap ':' USR1; trap -p USR1` prints `trap -- ':' SIGUSR1`. Every unit's `_pm_start` records the prelude's EXIT trap (0003:793), so a part that leaves an EXIT trap of its own set gives `trap on EXIT changed`. That is the seventh failure, beside whatever its trap prints. This settles blind2's ambiguity 5:
  - D3's after-mark case is 1294's fm case (1294:576-585), whose unit's EXIT trap prints `djy-after-mark` and removes `$TMP`. It now shows that line as written, once, after the unit's other lines, and no `@@` line. After it come the unit's runner failure, `  FAIL  part left the shell changed for the parts after it: 0010-fa.sh`, and `  | trap on EXIT changed`. The run exits 1 and leaves no receipt. The case asserts all of this.
  - D8's EXIT-trap case ("exits 5", 1293's trap5) gives `part process ended with status 5: UNIT` and, after it, the seventh failure with `  | trap on EXIT changed`. Its `-j 1` control still exits 5.
- **The class (D5).** The sweep is re-run with this comparator over every part before the comparison binds. Every change it finds is remedied in its part or helper, and none is kept. Its per-part record goes to the PR. buildB's sweep, made with R8's comparator, does not stand in for it. The sweep also shows that today's suite adds no export and no function over a builtin, keyword or command, and that no part's top level runs `hash -p`.
- **D8 gains** (conf2 5). Under `-j 3`, each of these planted parts gives the seventh failure with exactly the `  | ` lines shown, exit 1 and no receipt, and in a `--red` record copy no manifest, as R8's cases do:
  - `set -o pipefail`: `set +o pipefail is now set -o pipefail`;
  - `unset REPO`, a plain variable the prelude sets (0004:144): `variable REPO removed`;
  - `_fx_roots="$_fx_roots"$'\n'"$TMP/djx-root"`, a change to an underscore-prefixed prelude variable: `variable _fx_roots changed`;
  - `exec 0<&-`: `descriptor 0 closed`;
  - `exec 2>&-`: `descriptor 2 closed`;
  - `export LC_ALL=C`, with LC_ALL absent from the run's environment: `export LC_ALL added`;
  - `export CLAUDE_CONFIG_DIR=/x`, with it absent from the run's environment: `export CLAUDE_CONFIG_DIR added`;
  - a new value for an export the case made before the run (`DJX_KEEP=2`): `export DJX_KEEP changed`;
  - `export() { builtin export "$@"; }`: `function export added over a builtin`;
  - `perl() { command perl "$@"; }` beside `umask 077`: both `function perl added over a command` and `umask WAS is now 0077`, WAS being the case's own umask;
  - `sleep 30 &` left running, with its pid written to a file by which the case ends it: `job PID left running`;
  - `set -- a b c`: `positional parameters changed`;
  - `enable -n printf`: `builtin printf disabled`;
  - `pushd "$PWD" >/dev/null`, which leaves the stack changed and the working directory as found: `directory stack changed`;
  - `readonly djx_ro=1`: `readonly djx_ro added`;
  - a hard limit lowered with `ulimit -H` to its soft value: `ulimit -Ha: WAS-LINE is now NOW-LINE`, the resource's line as `ulimit -Ha` printed it before and after. The resource is one the case first measured, in a child of the same bash, to have a hard limit above its soft one that can be lowered. Where none can, the case is a skip with the same name;
  - `trap 'printf "djx-exit\n"' EXIT`: `trap on EXIT changed`.

  R8's passing case "a part that exports a new name outside the steering list" now fails, with `export NAME added`. The other passes stand: a new plain variable not named above, a new function hiding nothing, and a variable of tests/lib changed. Under `-j 1` none of them gives the seventh failure, as R8 says.

### R17. D5, R9: 0710 both ways, and the group rx

Answers conf2 4, 7 and 13, with buildB's R9 evidence.
- **Both ways.** R9's "0710 says when a builder is missing" gains the other direction. 0710's assertion "the engine writes manifests carrying the grounding column" also fails when a project that the builders' list names has no grounded stack.tsv in `_gfiles`, naming the project and the builder that should have made it. In every run, the projects of `_gfiles` equal the list.
  - With revision 7's one-way check, a builder call removed from 0710, or a builder that stops writing the grounding header, passed every run (conf2 4). Now the first fails 0710's unit under `-j N`, and the second fails the serial run as well.
  - The list is `_grounded_projects` (tests/lib/cm-stub.sh:121). It prints one line per project: its name, a tab, and the function that builds it: `cmstranger _commissioning_build`, `cmwebapp _cmwebapp_build`, `hookproj _hookproj_build`, `setupproj _setupproj_build`, `stranger _stranger_build`.
  - For each listed project that `_gfiles` lacks, the detail gains `[PROJECT has no grounded stack.tsv: BUILDER should have made it]`, beside revision 7's `[no tests/lib builder makes the manifest of: ...]`.
- **The known set** replaces R9's list after "These are known". It is the set buildB measured at serial 0710's start: cmstranger, cmwebapp, hookproj, setupproj and stranger, the same five as 0710 alone holds. cmproj, which `_commissioning_build after-0700` also makes, has a stack.tsv with a five-column header and is not grounded. So R9's "cmproj and cmstranger" is corrected to cmstranger. R9's sentences on what the sweep reads stand.
- **The PATH.** Each builder makes its fixture with the PATH its part used. `_setupproj_build` (cm-stub.sh:77-84) runs `felix new` with 0190's gh stub directory, `$TMP/fs-gh`, with its gh and ssh, first on PATH, as 0190's `_fs_path` has it (0190:181). When 0190 has not made that directory, the builder makes it itself, as 0190:152-180 does. Revision 7's build ran `felix new` with `$CMSTUB:$PATH`, so a gh call it made reached the machine's own gh (conf2 13).
- **The group rx.** D5's groups gain rx, beside ib.
  - Parts 1100, 1110 and 1120 are a serial hand-off of the reach fixture (tests/lib/reach.sh). 1100 builds it (1100:13), 1110 and 1120 take it up (1110:17, 1120:30), and only 1120 removes its base (1120:425).
  - On Linux, where `$TMP`'s ancestors are world-writable, RXBASE is a directory outside `$TMP` that `_rx_build` adds to `_fx_roots` (reach.sh:97-105). So 1100's and 1110's units would each leave a directory behind and give `variable _fx_roots changed` (conf2 7).
  - groups.tsv gains group rx with the three parts, after ib's lines, with a comment of its own. They are contiguous (run:354-356).
  - The part that removes the base, 1120, also restores `_fx_roots` to its value from before the base was added, byte for byte, so the group's unit leaves it as its prelude made it.
- **D8 gains:** D8's groups.tsv case, "The tree's own `tests/groups.tsv` puts 0900, 0910, 0920, 0930 and 0940 in one group", also finds 1100, 1110 and 1120 in a second group, rx.

### R18. D8: R3's case is a start-up check

Answers proc2 6. R3's D8 case stands, and what it checks is restated: TERM sent at a spread of short delays during a `-j 4` run's start-up ends everything, and leaves no wrapper, holder or unit once the parent has exited.
- The window between a wrapper's fork and `$!` lasts microseconds, and the case practically never lands in it. So the fork window itself rests on review and on processes 3's measurement (12 of 12, R3).
- The case's name says what it checks and does not name R3, for example "D6: TERM at a spread of short delays during a -j 4 run's start-up ends everything: ...".

### R19. Pins from round 1's ambiguities

Answers blind1's and blind2's ambiguities. Each pins a reading, and none changes what a build does.
- **R5's refusal lines** are `tests/run: the slots directory [D] ` followed by the phrase, with one space: `tests/run: the slots directory [D] is a symbolic link`. The entry line stays `tests/run: [D/NAME] is not a regular file: the slots directory holds slot files and nothing else` (blind2 1).
- **A set but empty `FELIX_TEST_JOBS`** is refused. D1 takes N from the variable "when that is set" and refuses "a `FELIX_TEST_JOBS` that is not a valid N". A variable set to the empty string is set, and the empty string is no N from 1 to 64. So it exits 2 with one stderr line before `$TMP` is made, as blind1 asserts and the build does (0001:110-112).
- **R1's "once such a record run has exited"** means that no process of red's tree is in both of two `ps` listings taken 0.1 s apart, the first right after the record run's exit (blind1).
- **R2's "the ending's Nth listing"** is the Nth `ps -A` call the ending makes after the signal, R14's `ps -A -o pid= -o ppid= -o lstart=`. A listing taken again because it came back empty is a call of its own (blind2 2).
- **red.tsv's rows** `base - - -` and `run - - -` are tab-separated, as red writes them (red:190) (blind2 6).

### The evidence, still owed

conf2 6's evidence is unchanged and still owed: the instrumented sweep (R8, R16), and the real suite's `-j 1` against `-j 8` equivalence run (D8's evidence, R9's), with no seventh failure. Both run at the carrier's slot after this round, with R16's comparator.

### Every other finding of review 2

Test fixes go to a blind author with this revision, before any code fix. Code fixes go to the builders once the new blind tests are red.

**Answered by an amendment:** proc2 1 and 4 (R13), 6 (R18), 9 (R14) and 10 (R15); conf2 1, 2, 3, 8 and 9 (R16), and 4, 7 and 13 (R17); rev8 1 (R13) and 2 (R14). conf2 5 is R16's D8 gains, and conf2 6 is the evidence above.

**Test fixes (no contract change):**
- proc2 2: 1292:448 tests `-f` on the unit's log after the EXIT trap has removed `$TMP`. The regular-file test is taken while the unit runs, before 1292:447.
- proc2 3: 1294:357-358 pass `tests/run: [` into a pattern (1294:340) that already starts with `tests/run: `. The phrase becomes `[`, or the whole entry path.
- proc2 5: the lu and hk cases run without `FELIX_TEST_SLOT_NOTE` (W = 30). Within 3 s of the wrapper's kill, only the holder's own check can then end the holder and unit, and the case checks this while the parent still runs. A new case pins the parent's ending of a lost unit's holder: with W = 2, STOP goes to the holder and then KILL to its wrapper. Once the parent has exited, the holder and its unit are gone and the unit failed without its mark.
- proc2 7:
  - (a) run.pl takes TERM and HUP dispositions as well. The dispositions case gains a parent started with TERM ignored and one started with HUP ignored, where the `-j 3` units read what the `-j 1` parts read, and each run asserts R13's last D8 gain (rev8 1);
  - (b) is R13's USR1 case;
  - (c) TERM sent twice, 0.5 s apart, to a parent whose unit ignores TERM gives exit 143, nothing left, and no stderr line printed twice.
- proc2 8:
  - (1) R6's line is expected within T + 3 s (5 s) of the parent's prelude's end, which pins W;
  - (2) `_db4_peak` gets a bound, or reads the job table;
  - (3) the 2 s bound after a kill -9 is timed in the perl that takes the listing.
- conf2 10: 1293:319's control greps 9990 for the names the cases use, `$_db3_n9b` and `$_db3_n9c` with `$_db3_n9a`, each in its own case, and prints `missing` when one is absent.
- conf2 11: the `-j 1` negative also requires every planted part's `  ok    djx shell NAME` line in s1.out, once each, so that run is known to have reached them all.
- conf2 12: a `--red` record case whose record run has a runner failure while red's suite runs a part that sleeps 90 s only under `FELIX_TEST_NO_MANIFEST=1`. The record run exits within 30 s, red.tsv holds the two `-` rows, and nothing of the group is left. This shows R1's "red acts on `failed` while its suite runs".
- conf2 2: the planted child in 1292's lc case (1292:452) is started as `( cmd & )`, so it is not a job of the unit's shell, and that case stays a pass under R16.
- Every planted part of 1291-1294 that leaves a change R16 now compares (an added export, a job left running, an EXIT trap), where the case is not about that change, is changed so that it leaves none. The fm and trap5 cases expect the seventh failure, as R16 says.

**Code fixes (no contract change):** none outside the amendments. proc2 2 and 3 found the code right.

**Deliberately not taken:**
- proc2 1's smaller remedy, traps that only record the signal and act on it after the read: with no alarm pending, R13's plain read lets the existing ending run to its end.
- proc2 10's line 3 of the slot file: R15 writes `$TMP/pj/unit.I`, so `slot.I` keeps the two lines R4 and R6 read.
- conf2 2's other remedy, the planted child disowned: `( cmd & )` is used.
- conf2 3's other remedy, a steering list derived from every `${NAME` the engine reads and kept current by a lint: R16 counts every added export, with an empty allowlist that only a revision grows.
- conf2 7's other remedy, 1100 made the owner that removes the base: R17 groups the three parts, as they were written to run.
- conf2 9's digest of `$*`, and its hash entries whose path differs from `type -P`: R16 compares each positional parameter's text, and leaves the hash table out, with its reason.
