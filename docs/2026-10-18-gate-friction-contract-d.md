# Contract D: the parallel runner

This is step 3b of docs/2026-10-12-gate-friction-design.md, section 5. It is its own pull request, engine tier, and is built on C (#444), after which it lands. Its version is the next free one when it records.

C made every part run alone. D runs the parts in parallel, so that a suite turns the machine's cores into less wall time. The founder put C and then D ahead of everything else on 2026-10-16.

The design's rule binds every item: weaken no check. That includes weakening by scheduling, where an assertion that a serial run makes over many parts' work is made over less, or is skipped where a serial run makes it.

**Revision 7** (2026-10-19 UTC) amends revision 6 after the first review of its build, in the last section, which names what each amendment replaces. Revision 6 (2026-10-18 UTC) answered five reviews, kept in audits/2026-10-18-gate-friction-d/:
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

Four lenses reviewed revision 6's build (ae7d1099..266d4bde, with main 655606cf merged in after it). Their reports are in audits/2026-10-18-gate-friction-d/, with the builders' reports (round-1-build1 to 3) and the notes kept during the build (findings-for-review.md). Each amendment names the clauses it changes and the lines it replaces; every line it does not name stands. What an amendment's "D8 gains" lists is added to D8's cases for the blind part. Findings are cited by report and number, numbered in each file's order from 1: **processes** (review-1-processes-and-signals.json), **tests** (review-1-tests-catch-mutations.json), **conformance** (review-1-conformance.json), **weaken** (review-1-weaken-no-check.json), and **notes** 1 to 3 (findings-for-review.md, its entries of 20:55Z, 21:50Z and 22:41Z).

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

Answers weaken 2. A serial run carries umask, options, traps, exports and functions from each part to the parts after it, and a unit's run carries them nowhere. Revision 6 judged none of them, so a part that leaves one changed can fail the parts after it under `-j 1` while `-j N` passes.
- **`_pm_start` records**, as its last act and into files of the unit's `$TMP`: the output of `umask`, `set +o`, `shopt -p` and `trap -p`; for every variable exported then, inherited ones included, the line `export -p` prints for it, except PWD and OLDPWD (the floor judges the directory); and, for every function `declare -F` lists then, a digest of the text `declare -f` prints for it.
- **`_pm_fin`**, first, before anything else it does, takes them again and compares. Each change is one line: `umask WAS is now NOW`; `WAS-LINE is now NOW-LINE` for a `set +o` or `shopt -p` line that differs (`shopt -u nullglob is now shopt -s nullglob`); `trap on SIGNAL changed`, `added` or `removed`; `export NAME changed` or `removed`, with no value printed; `function NAME changed` or `removed`. An export or a function a part adds is not a change.
- **The end file** gains `shell ok`, or `shell changed` followed by one `shellmsg LINE` per change. An end file without a `shell` record is not readable (D3). D2 step 4's list gains it.
- **The seventh runner failure.** `shell changed` gives `  FAIL  part left the shell changed for the parts after it: UNIT`, after the unit's other runner failures, followed by each change as `  | LINE`. It is a runner failure like D3's other six: it adds 1 to FAIL and calls no `_ran`; it withholds the manifest in a record run and leaves no receipt; red leaves it out of its counts and names with the other six prefixes, and refuses no log for it; and no manifest name starts with its prefix. Under `-j 1` nothing is compared: a change carries to the parts after it, as today.
- **The class (D5, D8's evidence).** The instrumented serial run also records, for each part, every shell change it leaves: what `_pm_fin` compares, the names it newly exports and the functions it newly defines. The PR shows each change found as harmless (with the reason) or remedied (with the commit).
- **D8 gains:** under `-j 3`, each of these planted parts gives the seventh failure with its `  | ` line, exit 1 and no receipt, and in a `--red` record copy no manifest: `umask 077` left set; `shopt -s nullglob` left set; `trap : USR1` left set; PATH changed; a variable the case exported before the run unset; a function of tests/lib redefined. A part that exports a new name passes. Under `-j 1`, none of them gives the seventh failure.

### R9. D5: a third remedy, part 0710, risk.tsv and groups.tsv

Answers weaken 1 and 3, and conformance 12.
- **Builders.** A part cannot be grouped when its inputs come from parts that are not contiguous with it, or from more than six. It then gets them from tests/lib builders that make every input the serial run hands it, as C's do. A builder makes each input as the serial run leaves it for that part, in everything the part reads. It does nothing once the input is there, so in the serial run only the first caller builds, and the serial run is unchanged.
- **Part 0710 is the first.** In the serial run, its check of every `projects/*/stack.tsv` (0710:259-279) reads the manifests of five projects:
  - cmproj and cmstranger, from `_commissioning_build after-0700`, which 0710:12 already calls;
  - stranger, which 0010 makes through `_stranger_build` (tests/lib/cm-stub.sh);
  - setupproj (0190:203-208) and cmwebapp (0700:520-527). Their fixtures move into tests/lib builders, which 0190 and 0700 call in their place, as 0010 calls `_stranger_build`.

  0710 calls all three builders before its check. The PR shows, from one `-j 1` and one `-j 8` run, that 0710's glob finds the same projects, with stack.tsv files holding the same rows.
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
