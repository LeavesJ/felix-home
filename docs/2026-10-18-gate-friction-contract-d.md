# Contract D: the parallel runner

This is step 3b of docs/2026-10-12-gate-friction-design.md, section 5. It is its own pull request, engine tier, and is built on C (#444), after which it lands. Its version is the next free one when it records.

C made every part run alone. D runs the parts in parallel, so that a suite turns the machine's cores into less wall time. The founder put C and then D ahead of everything else on 2026-10-16.

The design's rule binds every item: weaken no check. That includes weakening by scheduling, where an assertion that a serial run makes over many parts' work is made over less, or is skipped where a serial run makes it.

**Revision 12** (2026-10-20 UTC) amends revision 11 after D5's class sweep and the fifth review of its build, in the last section. Revision 11 (2026-10-20 UTC) amended revision 10 after the first pass of D8's evidence on its build, in the section before it, revision 10 (2026-10-20 UTC) amended revision 9 after the fourth review of its build and CI's first Linux run of it, in the one before that, revision 9 (2026-10-19 UTC) amended revision 8 after the third review, in the one before that, revision 8 (2026-10-19 UTC) amended revision 7 after the second review, in the one before that, and revision 7 (2026-10-19 UTC) amended revision 6 after the first review, in the one before that. Each amendment names what it replaces. Revision 6 (2026-10-18 UTC) answered five reviews, kept in audits/2026-10-18-gate-friction-d/:
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

## Amended after review 3 (revision 9, 2026-10-19)

Two lenses reviewed revision 8's build (286fbca0..2e8de446). Their reports are in audits/2026-10-18-gate-friction-d/, cited by report and number, numbered in each file's findings from 1: **proc3** (review-3-processes-and-tests.json) and **conf3** (review-3-conformance-and-weakening.json). In this section, round 2's fix reports are cited as **buildA**, **buildB**, **blind1** and **blind2** (fix-2-buildA.txt, fix-2-buildB.txt, fix-2-blind1.txt, fix-2-blind2.txt). Revision 7's conventions hold: each amendment names the clauses and lines it replaces, every line it does not name stands, and its "D8 gains" are added to D8's cases for the blind parts. File and line references are to 2e8de446. Every measurement this section reports as made for it was made on this Mac's /bin/bash 3.2.57 on 2026-10-19.

Every case this revision adds must be red against a build without the rule it names. Where the build already has that rule (R2's ignore, R13's read-back, R14, R15(a)'s check while a holder waits, and R16's guards and comparisons), the case is shown red against a copy of the build with the rule taken out, and the report names what was taken out and the FAIL it gave.

### R20. R15(a): the parent gone, told without a start time

Answers proc3 6. On Linux, procps prints lstart as /proc/stat's btime plus the process's start ticks, and btime moves when the wall clock is stepped (settimeofday, chrony's makestep, a leap second). R15(a) had every holder read the `-j` parent's start time every 10 s and take an answer that differed for the parent gone (0007:46-51), and end its unit's tree (0007:109). A clock step during a Linux `-j` run would then end every running unit while the parent lived. R20 replaces, in R15(a):
- in its lead, "and its start time as `ps -o lstart= -p PID` prints it, blanks trimmed. The parent reads its own start time once, at the head of `_par_run`.";
- the sub-bullet "At least once every 10 s, and just before it forks, it also reads the parent's start time with `ps -o lstart=`. An answer that is not empty and differs from the one it was given is the parent gone: another process has its pid. An empty answer decides nothing until the next check.";
- in the sub-bullet after it, "or started at another time".

The texts:
- **What the holder is given.** The `-j` parent's pid. The parent's start time is no longer passed to it, and the parent no longer reads its own at the head of `_par_run` (0007:770).
- **Once a second.** The holder keeps its `kill 0` of the parent's pid wherever R4 has it check its wrapper: at least once a second while it waits for a slot and while its unit runs, and once more just before it forks. A failure, for any reason, is the parent gone, as R15(a) says.
- **Every 10 s, and just before it forks**, it also checks that its wrapper's parent is still the `-j` parent's pid: `ps -o ppid= -p WRAPPER`, WRAPPER being its own parent's pid, which it keeps from its start (R4), the answer's blanks trimmed. It asks only while its own parent is still that pid (R4's check), so WRAPPER names its wrapper. An answer that is a pid other than the `-j` parent's is the parent gone. A wrapper whose parent died is reparented, to pid 1 or a subreaper, and a new process that takes the parent's pid is not the wrapper's parent, so neither a clock step nor a pid taken again moves the answer. An empty answer decides nothing until the next check.
- **Unchanged.** The holder treats the parent gone exactly as its wrapper gone (R4): it starts no unit; if its unit runs, it ends the unit's tree as R2 says (R14, R21) and reaps it; either way it exits 2. R15(a)'s "So within about 3 s of a kill -9 of the parent" stands: the `kill 0` finds a dead parent whose pid is free within a second, and the check of the wrapper's parent finds one whose pid was taken again within 10 s, as R15(a)'s start-time check did.
- **D8 gains:** R28's case of the parent killed with `kill -9` while a holder waits for a slot (proc3 8) runs under these checks.

### R21. R14: what a stopper has stopped, it signals by its pid

Answers proc3 6 for R14's members, and the Linux risk R14 states under "What is left". A step of the clock on ubuntu moves the start time procps prints for every process at once (R20). Under R14, a member stopped before a step read as not present after it and was sent no KILL, so what the stopper had stopped stayed stopped, with what it held: a holder, its slot. R21 adds to R14's "Present" bullet and to its steps 4 to 6, and replaces R14's bullet "Nothing it stopped is left stopped" and the third sub-bullet of its "What is left". As R14 does, it binds every stopper: the ending, red's `_stop_tree`, receipt.sh's `_rcp_stop`, the parent's endings of a unit's tree (R4, R15), and the holder's own stopper. Wherever this contract says "as R2 says", R2 reads as R14 has it with R21. receipt.sh stays under 500 lines (room is made inside it), and red grows as little as it can, as R2 says.
- **Stopped, then by its pid.** A member that the stopper sent STOP to, while a listing showed it with its start time, is signalled by its pid in the stopper's later steps (step 4's further rounds of STOP, step 5's KILL, then step 6's KILL and CONT after the last listing), with no further start-time check, whatever a later listing shows of it. R14's "Present" bullet gains: "A member this stopper has sent STOP is the exception: R21 signals it by its pid from then on."
- **Nothing it stopped is left stopped** (in place of R14's bullet). A member sent STOP was present in the listing just before it. A stopped process cannot exit, so its pid cannot pass to another process until a KILL ends it. Step 5 sends it KILL by that pid. So a clock step during a stop can no longer leave stopped what the stopper stopped.
- **Unchanged.** R14's start-time check stays for every member not yet stopped, and for TERM: step 3's TERM, and step 4's STOP to a member not yet stopped, go only to members present in the most recent non-empty listing.
- **What is left** (in place of R14's third sub-bullet):
  - *Two stoppers on one tree.* When the other one's KILL ends a member this one has stopped, and its pid is taken again before this stopper's KILL, within the same stop, this stopper's KILL and CONT reach the process that took the pid. R14 would have told that process apart by its start time. As R14's first residue does, it needs the pid space to wrap within that time.
  - *A clock step on ubuntu.* After it, no member that joined before it reads as present by its start time. Such a member not yet stopped has had TERM, if a listing before the step showed it, and nothing more, and nothing it forks is found: it runs on, never stopped. Where a recorded start time no longer matches (a lost unit's holder, from `slot.I`; a unit whose holder died, from `unit.I`; red, from `_rcp_redsig`; red's suite, from `SUITE_ST`), nothing is signalled, and the process runs on, never stopped. macOS keeps a process's start time with the process. Not measured.
- **D8 gains:** the twin of R14's case (R28). A `ps` first on PATH, like that case's, leaves out of the ending's first listing the row of R, a child that P starts when it starts, and shows it from the second listing on, so that the ending's second listing (step 4's first round) adds a member and step 4 makes a second round, with the ending's third listing. It shifts P's start time by one second only from that third listing on, after P was sent STOP. P ignores TERM. Once the parent has exited, P and R are gone, and nothing of the run is left, stopped or running. Against a build without R21, P is left stopped.

### R22. R15(b): no unit runs before `unit.I` is written

Answers conf3 5. The holder wrote `unit.I` after a `ps -o lstart=` that it ran once its unit was forked and running, and skipped the write when ps printed nothing (0007:93-104). A holder killed with -9 in that window left its unit running below pid 1, with its slot free and no `unit.I`, which is the loss R15(b) exists to close; one fork and exec of ps takes seconds at the load average of about 90 that conf3 saw. R22 replaces R15(b)'s "Right after it forks its unit, the holder writes one line to `$TMP/pj/unit.I`" with "Once it has forked its unit, and before the unit runs, the holder writes one line to `$TMP/pj/unit.I`", and adds to D6's holder step 3.
- **The pipe.** The holder gives the forked child a pipe, and the child reads one byte from it before it execs the unit, once it has set its signals as D6's holder step 3 says. The child closes the pipe's write end before it reads, and the holder closes its read end. Both ends are close-on-exec, as perl opens them, so the unit holds neither.
- **The order.** The holder writes `unit.I`, whole, through a sibling file and a rename, and only then writes the byte.
- **A holder that dies first** gives the child EOF, since the holder held the pipe's only other write end, and the child exits 2 without running the unit. A missing `unit.I` then always means no unit ran, so R15(b)'s "With no `unit.I`, or another start time, nothing is signalled" leaves nothing running that a `unit.I` would have named.
- **No start time.** A `ps -o lstart=` that prints nothing for the child is taken again, up to five tries in all, 0.2 s apart. When the fifth prints nothing too, or `unit.I` cannot be written, the holder closes the pipe without writing the byte, so the child exits 2 without running the unit. The holder reaps it and exits 2, and the unit has no mark (D3).
- **D8 gains:** none in this revision. The window was one `ps` call, and R22 closes it by construction.

### R23. R13: the ticker's fork and its last KILL

Answers proc3 7. R13 makes the ticker one of the ending's roots, and R14 sends nothing to a pid that may be another process's. The build broke both at an edge:
- the ticker is forked after `_par_arm` and its pid taken from `$!` on the next line (0007:785-787), so a signal between the two ran an ending without it as a root;
- the loop's end sent KILL to the ticker's pid whether or not the ticker still ran (0007:799), and a ticker ended from outside, which R13's "What is left" allows, may have left its pid to another process.

R23 adds to R13's "One of the ending's roots", and replaces its sentence "When its loop ends with no signal, the parent sends KILL to the ticker's pid and waits for it, before it closes the FIFO."
- **The fork.** The parent keeps the value `$!` has just before the ticker's fork. The ending takes `$!` as the ticker when the ticker's pid is still unset and `$!` differs from that value, as R3 does for a wrapper. When it does not differ, the fork had not happened.
- **The last KILL.** When its loop ends with no signal, the parent sends KILL to the ticker only while `builtin jobs -rp` lists the ticker's pid, the job-table test `_par_gone` uses for a wrapper (R14). It then waits for the ticker, listed or not, before it closes the FIFO.
- **D8 gains:** none. The fork window lasts microseconds, and the KILL's harm needs a pid taken again; both rest on review, as R18 says of R3's fork window.

### R24. R16: every builtin's status, aliases and readonly functions

Answers conf3 4 and 8.
- **Every status counts.** The status of every builtin call in the snapshot counts, in `_pm_take0`, `_pm_take1` and `_pm_snap`, `enable -n` and the `builtin enable NAME` that enables again included. If one fails (enable disabled, for example), `_pm_fin` reports `the shell state could not be compared`, as R16's "What cannot be guarded" says of a step of the comparison that fails, and the unit gets the seventh failure, never `shell ok`.
  - A non-zero status that is itself the answer is no failure: a descriptor test, a `read` at the end of its input, `declare -p` of a name that is not set, and `compgen -v LC_` with no match.
  - Measured for this revision, in a shell with nothing disabled, no alias and no job: `umask`, `set +o`, `shopt -p`, `trap -p`, `ulimit -a`, `ulimit -Ha`, `export -p`, `jobs -rp`, `enable -n`, `dirs -p`, `readonly -p`, `declare -f`, `compgen -b`, `compgen -k`, `alias -p` and `readonly -f` each exited 0; `compgen -v LC_` with no LC_ variable, and `declare -p` of an unset name, exited 1.
  - conf3 4 measured why: once `enable -n enable` has run, `builtin enable -n` prints nothing, so the list read empty, as at `_pm_start`, and the unit read `shell ok`, while under `-j 1` every later `enable` fails. Measured for this revision: the call then fails with `builtin: enable: not a shell builtin`, status 1.
  - R16's "What cannot be guarded" loses "or `enable`" from "A function named `builtin`, or `builtin` or `enable` disabled". A unit that disables `enable` still writes its end file and its mark, and gets the seventh failure. A function named `builtin`, or `builtin` disabled, stays as R16 says.
- **Aliases and readonly functions.** `_pm_snap` also takes `builtin alias -p` and `builtin readonly -f`, and `_pm_fin` compares them:
  - `alias NAME added`, `alias NAME changed` or `alias NAME removed`, from the `alias NAME=` lines;
  - `readonly function NAME added`, for a `declare -fr NAME` line that `_pm_start` did not have. Measured for this revision: `readonly -f` prints each readonly function's text and then `declare -fr NAME`, and `alias -p` prints `alias NAME='VALUE'`.
  - Under `-j 1` an alias carries to every later part that sets `expand_aliases`, and a readonly function makes a later part that defines that name fail. No part or lib file sets an alias or `expand_aliases` today (conf3 8).
  - R16's "Not compared, with the reason" is unchanged: the command hash table stays its one entry.
- **D8 gains:** under `-j 3`, each of these planted parts gives the seventh failure with exactly the `  | ` line shown, exit 1 and no receipt, and in a `--red` record copy no manifest, as R16's cases do; under `-j 1` none gives it:
  - `enable -n enable`: `the shell state could not be compared`;
  - `alias djx_al=true`: `alias djx_al added`;
  - `djx_rf() { :; }; readonly -f djx_rf`: `readonly function djx_rf added`.

### R25. R16's class clause: what the serial sweep shows, and what binds

Answers conf3 6. buildB's sweep with R16's comparator (sweep-shell-r8, 181 parts) found 25 change lines in five parts, all of them function rows. None was remedied, and the record does not mark them, though buildB's report gives their reason. A serial sweep compares each part with what the parts before it left, not with the prelude, as a unit does. R25 replaces, in R16's "The class (D5)", "Every change it finds is remedied in its part or helper, and none is kept."
- **What it shows.** The serial sweep shows only changes a part makes whatever ran before it. A change that exists only because an earlier part made something is serial-only, and a change that a part makes only when an earlier part has not (`[ -n "${X-}" ] || export X=...`) it cannot show. Every change it shows that a unit would also report is remedied in its part or helper, and none is kept.
- **Its five function rows are serial-only.** Each function is defined by an earlier part, never by the prelude or tests/lib, so no unit holds it at `_pm_start` and no unit reports it:
  - 0160: `function _tr changed`. `_tr` is defined by 0080;
  - 0290: the 18 lines `function NAME removed` for `_bwbadrow`, `_bwbytes`, `_bwcatch`, `_bwhead`, `_bwlast`, `_bwlesson`, `_bwlog`, `_bwnf`, `_bwpick`, `_bwprose`, `_bwrows`, `_bwsays`, `_bwsays0`, `_bwsess`, `_bwuntimed`, `_bwverdict`, `_bwwhen` and `_bwwrote`. All 18 are defined by 0280;
  - 0370: `function _rf changed` and `function _sev changed`. `_rf` is defined by 0330, and `_sev` by 0360;
  - 0600: `function _nd changed`. `_nd` is defined by 0420;
  - 1230 (1230-gate-friction-a-addendum-blind): `function _gfb_dead changed`, `function _gfb_git changed` and `function _gfb_said changed`. All three are defined by 1210.

  The record (rec-p2A.tsv, rec-p2B.tsv and rec-p2D.tsv) marks each of these rows serial-only, with the part that defines the function.
- **What binds.** Showing that no unit gives the seventh failure is the owed `-j 1` against `-j 8` run of the real suite, with R16's comparator as R24 has it. That run is the evidence that binds; the sweep is not. "The evidence, still owed" stands, with this.

### R26. R12: a blind part's length

Answers proc3 5. R12 capped each of 1291 to 1294 at 600 lines, and 1294 is 640 (593 at 286fbca0). R26 replaces R12's "Each of the four is at most 600 lines and is meant to run alone in at most five minutes on a quiet machine, and the PR reports each one's wall time alone."
- **The limit.** The 600-line cap on each blind part (1291 to 1296) is replaced by the suite's own limit for a part, 1000 lines (1040:25).
- **What R12 wanted** is run time: each blind part runs alone in about five minutes on a quiet machine, and the PR reports each one's wall time alone.
- **1294**, at 640 lines, runs alone in about 220 s (216 s in buildB's count, 236 s in blind2's).
- **D8 gains:** none.

### R27. D8: what the TERM-twice and dispositions cases pin, and R2's ignore where it can be seen

Answers proc3 4.
- **1296's TERM-twice case** (proc2 7(c), 1296:254-255) is a check that a second TERM during the ending changes nothing: exit 143, nothing of the run left, stopped or running, no slot held, no receipt, and no line of its stderr printed twice. Its name says so and does not name R2, for example "D6: a second TERM sent to the parent during its ending changes nothing: ...". The parent's own ignore of TERM rests on review. exA in proc3 measured why it cannot be observed there: on bash 3.2 the second TERM is held back while the first trap runs, and is delivered when that trap's `exit` leaves the handler, so a parent without the ignore runs its trap a second time, finds every unit ended and no ticker, and exits 143 again.
- **R2's ignore, where it can be seen.** The second TERM goes to a stopper of red's tree while it stops a suite whose unit ignores TERM (in red's suite only, under `FELIX_TEST_NO_MANIFEST=1`). Nothing of red's tree is left, stopped or running. Two `--red` record cases:
  - *red's monitor.* The record run has a runner failure while red's suite runs that unit, as conf2 12's case has it, so red's monitor stops red's suite (R1). A second TERM is sent to red's monitor while it stops. The record run exits before `_rcp_red_end`'s 60 s bound (R1) has passed: a monitor ended between its STOP and its KILL leaves red's suite stopped, and the record run then waits out that bound;
  - *the record run's watcher.* The record run is killed with `kill -9` while red's suite runs that unit, so its watcher stops red's tree (`_rcp_stop`). A second TERM is sent to the process that runs `_rcp_stop`'s steps while it stops: the subshell that `_rcp_stop` runs them in and the watcher waits for (R2), not the watcher. The watcher traps TERM, and bash runs that trap only once the foreground subshell has ended, so a TERM to the watcher leaves the stop to its end whether the subshell ignores TERM or not, and pins nothing of R2's ignore. Measured for this revision: a function that traps TERM, sent TERM 1 s into a 3 s foreground `( )` with no trap, ran its trap only after the `( )` had finished.

  Each is red against a build whose stopper there does not ignore TERM. To be so, the case makes its second TERM land between that stopper's STOP and its KILL, for example with a `ps` first on PATH that makes that stopper's listings slow once a trigger file exists, and its comment says how.
  - *Which process.* The shim finds the process that runs the stopper's steps as its own grandparent: its parent is the `$( )` that runs the listing, and that one's parent runs the steps. That is red's monitor in the first case, since the monitor runs `_stop_tree` itself, and `_rcp_stop`'s subshell in the second. Measured for this revision: a `ps` first on PATH, called as `o="$(ps -A -o pid= -o ppid= | awk ...)"` from a function in a `( )` that ignores TERM, inside a `( )` that traps it, had the `$( )` as its parent and the inner `( )` as its grandparent. bash 5.2 was not measured, and the case's comment says what it found there.
  - *The watcher case's mutants.* It is red against both: `_rcp_stop`'s subshell without its `trap '' TERM`, which dies at the TERM between its STOP and its KILL; and `_rcp_stop`'s steps run in the watcher's own shell with no subshell, where the shim's grandparent is the watcher, whose trap exits once the listing returns. Either leaves stopped what the stopper had stopped.
  - *Red's own stoppers.* Red ends its suite too: red's `_abort`, on step 3's TERM, and red's monitor, which also finds the record run gone with no mark. If they end red's tree within the 30 s that `_rcp_stop` waits for red (R2's step 3), the watcher's stopper finds nothing to stop, and the case passes against both mutants. So the case keeps red's tree whole until that stopper's STOP, for example with the shim holding, past those 30 s, every listing that a process of red's tree makes. It makes sure that step 4's first round adds a member, so that a second round's listing falls between the STOP and the KILL, for example with a unit that forks a `sleep 1` each second. Its comment says how.
- **1292's dispositions runs** (1292:310-338) drop "the ticker included" and the rev8 1 claim from their names and their comment. R27 replaces, in R13's last D8 gain, ", the ticker included (rev8 1)" with nothing, and adds to R13's "Its signals": "With TERM ignored at the parent, the ticker's reset cannot be observed in those runs: the units ignore TERM too, and the normal end KILLs the ticker. The same holds of the run started with HUP ignored, which also ends normally. The reset rests on review, and on R13's measurement of a perl that sets them to their defaults."

### R28. D8: the cases review 3 found missing

Answers proc3 1, 2, 3 and 8, and conf3 1, 2, 3 and 7. Each goes to the blind authors.
- **A run's slot file, from the run itself** (proc3 1, a blocker). 1296's lh and hh cases find a run's slot file from the run: the planted part writes `${FELIX_TEST_RAN%/*}`, the parent's `$TMP/pj`, to a file of the case's fixture directory, and the case reads `slot.*` there and nowhere else. No case globs where `mktemp -d` might have put a run's `$TMP`. GNU mktemp honours TMPDIR and macOS's ignores it, so 1296's glob beside the suite's own `$TMP` (1296:146-149) finds nothing on ubuntu, which fails both cases on every CI run, and reads other sessions' runs' files on macOS. The reading at 1296:23-26 is corrected with it.
  - *Not `FELIX_TEST_PART_LOG`.* Part mode unsets the `FELIX_TEST_PART_*` variables once read (D1), at 0001's head (0001:129-130), before any member runs, so a member that reads `FELIX_TEST_PART_LOG` reads it empty. proc3 1's own remedy named that variable.
  - *What a member reads.* R28 adds to D2's step 2: "From `@@prelude-done` on, `$FELIX_TEST_RAN`, a variable of the unit's shell, names that ran file, the one `FELIX_TEST_PART_RAN` named. Under `-j N` that is the parent's `$TMP/pj/ran.I`, beside its `slot.I`, `unit.I`, `log.I` and `end.I`, so a member finds the parent's `$TMP/pj` as `${FELIX_TEST_RAN%/*}`." The build has it: `_pm_start` sets `FELIX_TEST_RAN` from the ran file part mode was given (0007:321), and the parent names every unit's files in `$TMP/pj` (0007:729, 0007:769).
- **R14's case, as R14 writes it** (proc3 2, conf3 1).
  - *The shim.* A `ps` first on PATH runs the real one and passes its output on. Once a trigger file exists, it counts each `ps -A` call whose arguments hold `ppid=`, as R19 counts the ending's listings (so a holder's `ps -o ppid= -p` of R20 is not counted), and from the second such listing on it prints the row of P with a start time one second later.
  - *P.* A unit starts P with `&`. P writes its pid to a file, appends one line to a second file for each TERM it gets, and goes on running.
  - *The run.* The case writes the trigger and sends TERM to the parent once P is up. The unit dies on that TERM before the second listing, so P, reparented, is a member held with its first listing's start time, and is not present from the second listing on.
  - *After the parent has exited:* P runs and is not stopped (its `ps -o stat=` holds no `T`), and its second file holds exactly one line. The case then ends P by its recorded pid.
  - It is red against a stopper that signals by pid alone, as R2's did. R21's twin is its companion.
- **R13's `@@gone` read-back** (proc3 3). 1296's lost-holder case (lh, 1296:258) gets, in place of its quick part 0020-lq.sh, a part that waits for a release file (bounded) and then passes. The case writes that file about 5 s after the wrapper's kill -9. With W = 2 the parent is then inside its ending of the stopped holder (about 10 s, since a stopped holder answers `kill -0`), so it has fallen W behind its ticker, at least one `@@tick` precedes that unit's line in the FIFO, and the first `_par_gone` after the ending finds that unit's wrapper gone. The unit reads as ok, not as lost: its `  ok    ` line once, and no `part ended without its mark` line naming it. It is red against a build that marks a wrapper found gone lost at once, or that waits only for the next `@@tick`.
- **The parent killed while a holder waits** (proc3 8). With `FELIX_TEST_SLOTS=1` and the slot's lock held by the case's own perl, recorded by its pid, a `-j 2` run of two parts. Once the parent's prelude has ended (the mark planted at the end of 0006, as 1294's R6 case plants it) and 2 s have passed, the parent is killed with `kill -9`. Within 3 s nothing of the run is left, stopped or running, and no unit starts once the case lets the slot go. It is red against a holder that checks the `-j` parent only while its unit runs.
- **R16's guard, with functions that do not forward** (conf3 2). Each of these planted parts sits beside `umask 077`, each in its own `-j 3` part outside the `-j 1` set, since under `-j 1` it would break the parts after it. Each gives the seventh failure with exactly these `  | ` lines, WAS being the case's own umask:
  - `perl() { :; }`: `umask WAS is now 0077` and `function perl added over a command`;
  - `compgen() { :; }`: `umask WAS is now 0077` and `function compgen added over a builtin`;
  - `declare() { :; }`: `umask WAS is now 0077` and `function declare added over a builtin`.

  With functions that forward, as R16's cases plant them, a comparator that calls perl or export by name gives the same lines as one that calls them through `builtin` and `builtin command`, so those cases pin nothing of the guard. conf3 2 measured a mutant `_pm_x() { "$@"; }`: beside `perl() { command perl "$@"; }` it gave the build's two lines, and beside `perl() { :; }` none, where the build gave both. So R16's two forwarding cases, `export() { builtin export "$@"; }` and `perl() { command perl "$@"; }` beside `umask 077`, are no longer cases of the seventh failure. They stay only as `-j 1` controls.
- **R16's comparisons that had no case** (conf3 3). Under `-j 3`, each of these planted parts gives the seventh failure with exactly the `  | ` line shown, exit 1 and no receipt, as R16's cases do:
  - `CDPATH=/djx`: `variable CDPATH added`;
  - `LC_COLLATE=C`, plain, with LC_COLLATE absent from the run's environment: `variable LC_COLLATE added`;
  - `OPTIND=5`: `variable OPTIND changed`;
  - `trap - EXIT`, numbered last, so that the `-j 1` run reaches every part: `trap on EXIT removed`;
  - a two-member group in the copy's groups.tsv whose first member runs `shopt -s nullglob`: one seventh failure, naming the group's unit, with `  | shopt -u nullglob is now shopt -s nullglob`.
- **1293's R1 sleeper** (conf3 7). Its wait for red's suite to reach the sleeper (1293:323, `-lt 100`, 20 s) is raised to 60 s (`-lt 300`). The run's 150 s bound still holds.

### Every finding of review 3, and where it went

Test fixes go to a blind author with this revision, before any code fix: R27, R28, and the D8 gains of R21 and R24. Code fixes go to the builders once the new blind tests are red: R20, R21, R22, R23 and R24.

- proc3 1 (blocker, test): R28, a run's slot file read from the run itself, through `${FELIX_TEST_RAN%/*}`, which R28 pins in D2's step 2.
- proc3 2 (major, test): R28, R14's case as R14 writes it; R21 adds its twin.
- proc3 3 (major, test): R28, the `@@gone` read-back case.
- proc3 4 (minor, test): R27, (a) the TERM-twice case renamed and R2's ignore pinned at red's monitor and at the subshell that runs the watcher's `_rcp_stop`, (b) the dispositions names, and R13's note.
- proc3 5 (minor, test): R26, the suite's 1000-line limit in place of 600.
- proc3 6 (minor, contract): R20, the holder's check of the parent without a start time; R21, the stoppers' stopped members signalled by pid.
- proc3 7 (minor, code): R23, both edges of the ticker.
- proc3 8 (minor, test): R28, the parent killed while a holder waits for a slot.
- conf3 1 (major, test): R28, with proc3 2.
- conf3 2 (major, contract): R28, shadows that do not forward; R16's forwarding cases become `-j 1` controls.
- conf3 3 (major, contract): R28, the watched variables, OPTIND, a trap removed and a group.
- conf3 4 (minor, code): R24, every builtin's status counts; `enable -n enable` is in its D8 gains.
- conf3 5 (minor, contract): R22, the pipe that holds the unit until `unit.I` is written.
- conf3 6 (minor, contract): R25, the sweep's five rows serial-only, and the `-j 1` against `-j 8` run as the evidence that binds.
- conf3 7 (minor, test): R28, the sleeper wait at 60 s.
- conf3 8 (minor, contract): R24, aliases and readonly functions compared; both are in its D8 gains.

conf2 6, the evidence, is still owed and not re-reported (R25).

**Deliberately not taken:**
- proc3 1's lesser remedy, a second glob of the case's own TMPDIR: the run names its own directory, so no case guesses where `mktemp -d` put it. Its main remedy's variable, `FELIX_TEST_PART_LOG`, is not taken either: part mode has unset it before any member runs, and R28 reads `FELIX_TEST_RAN`.
- proc3 4's TERM to the watcher itself: the watcher runs its trap only once `_rcp_stop`'s subshell has ended, so R27 sends the TERM to that subshell.
- proc3 5's other remedies, a block moved out of 1294 or a new part: R26 replaces the cap with the limit every part has.
- proc3 6's second way, field 22 of /proc/PID/stat: R20 asks for the wrapper's parent, which needs no Linux branch. Its "the same choice for R14's members" is answered by R21 instead: what a stopper has stopped it signals by pid, and the start time stays for the rest.
- proc3 7's third remedy, R13 amended to accept both edges: R23 closes them.
- conf3 1's further cases for the holder's `endtree` and red's `_stop_tree`: not in this revision. The parent's ending is the one stopper with a start-time case; the start-time checks of the holder's, red's and receipt.sh's stoppers rest on review.
- conf3 4's line `builtin enable disabled`: R24 reports `the shell state could not be compared`, as R16 does for a step that fails.
- conf3 5's other remedy, the window named under "What is left": R22 closes it.
- conf3 7's other remedy, the case skipped when no slept file appears: R28 raises the wait.
- conf3 8's other remedy, both listed as not compared, with a lint: R24 compares them.

## Amended after review 4 and CI's first Linux run (revision 10, 2026-10-20)

Two lenses reviewed revision 9's build (2e8de446..637cfe0f, with main 3999c182 merged in at 36a1ad25). Their reports are in audits/2026-10-18-gate-friction-d/, cited by report and number, numbered in each file's findings from 1: **proc4** (review-4-processes-and-tests.json) and **conf4** (review-4-conformance-and-weakening.json).

**ci456** is CI's run of this branch at 36a1ad25 (draft PR #456, run 39344632376, kept there as ci-456-run-39344632376.log): ubuntu, bash 5.2, dash as /bin/sh, GNU coreutils and procps. Its suite ran every part at `-j 1`, the blind parts' inner `-j` runs included, and failed exactly four assertions:
- two that say only that the record and the version are owed: red.tsv's base, and this engine's version above origin/main's;
- **(1)** 1293's R27 monitor case: `expected [within-45s between-stop-and-kill] got [within-45s no stopped process when the TERM was sent [stopped=0]]`, as conf4 2 predicted;
- **(2)** 1294's "R5: under a relative TMPDIR the slot files are made below the directory the run started in": `expected [0 0 1 2  4] got [1  0]`, exit 1 and no unit started.

Every other case of 1291 to 1296 passed there, 1293's R27 watcher case among them, which conf4 1 predicted would fail there.

Revision 7's conventions hold: each amendment names the clauses and lines it replaces, every line it does not name stands, and its "D8 gains" are added to D8's cases for the blind parts. File and line references are to 36a1ad25. Revision 9's rule holds for every case this revision adds: it is red against a build without the rule it names, and where the build already has that rule, against a copy of the build with the rule taken out, the report naming what was taken out and the FAIL it gave. Where this section says it simulated Linux, it did so on this Mac on 2026-10-20 (UTC), with /bin/bash 3.2.57, and says what it simulated.

### R29. R5, D2: a relative TMPDIR is made absolute before `$TMP`

Answers ci456 (2). GNU mktemp honours TMPDIR, so under a relative TMPDIR the name `mktemp -d` gives (0001:324) is relative. macOS's mktemp ignores TMPDIR, which is why no run here showed it. R29 adds to R5's first bullet and to D2.
- **The rule.** A relative TMPDIR is made absolute against the directory the run started in (`_og_start`, 0001:188), and exported, before part 0001 makes the run's `$TMP`. So GNU mktemp, the slots directory (R5's D) and every child, every unit included (D2), see one absolute path.
- **An empty TMPDIR** stays as unset: it is not made absolute, and `${TMPDIR:-/tmp}` and mktemp read it as unset, as now.
- **Unchanged.** R5's sentence on a relative D stands; the run's own TMPDIR no longer gives one. 0001:336, which makes a relative `$TMP` absolute, stands.
- **What R29 changes, and what it does not.** The build already makes the run's own names absolute: 0001:336 makes a relative `$TMP` absolute, 0007:459 makes R5's D absolute against `_og_start`, and 0007:747 starts every wrapper in `_og_start`. What a relative TMPDIR still breaks is any later bare `mktemp -d` under GNU mktemp, a part's own included: a part stands in `$TMP/cwd` (0001:394), a unit's in its own run's, and the relative TMPDIR is read from there. R29 is what makes that call land where the run's own did.
- **What ended ci456's run** was not that. It was 0001's enclosure check (0001:432-436), which R29 does not move. The case starts its run in its fixture checkout F (1294:103, `cd "$_db4_F"`), which `_suite_copy_tree` makes a git checkout (0003:907), and its TMPDIR, `reltmp`, names `$F/reltmp`. So under GNU mktemp `$TMP` is made below F, made absolute or not, and 0001 refuses with exit 1 before 0007 runs: no slots directory, no unit, ci456's `1  0`.
  - Simulated when this section was first written, with a GNU-style mktemp stand-in first on PATH and 0001's own `_fixture_enclosed` run in `$TMP/cwd` of a `$TMP` it made from inside a git checkout: with TMPDIR `reltmp`, and with that TMPDIR made absolute, the checkout's `.git` is found (status 0); with TMPDIR `../r29out`, outside the checkout, none is (status 1).
  - Measured by this revision's review, with the same stand-in and 0001's `_fixture_floor` and `_fixture_enclosed` run from a git checkout c/f: TMPDIR `reltmp` or `$F/reltmp` is refused with R29 or without. With TMPDIR `../reltmp` the run starts. Without R29 a part's bare `mktemp -d` from `$TMP/cwd` then fails (`mkdir: ../reltmp: No such file or directory`, status 1); with R29 it succeeds below c/reltmp.
- **1294's case, its geometry decided.** The case's TMPDIR becomes `../reltmp`, relative to the directory the run starts in (F) and naming `$_db4_c/reltmp`: outside F's checkout, and still under `$TMP` as R12 wants. The case makes that directory (in place of `$_db4_F/reltmp`) and expects the slot files below it: `0 0 1 2  4`, read from `$_db4_c/reltmp`. Its name becomes "R5: under a TMPDIR relative to the directory the run started in, the slot files are made below that directory, and the run passes: its holders found the files the parent made".
  - This case names R5's relative D, which the build already has. It passes on GNU and on this Mac with R29 or without, and is not R29's red case. By revision 9's rule it is red against a copy with R29's step and 0007:459's line both taken out: the parent, standing in `$TMP/cwd`, and its holders, in F, then name two directories.
- **D8 gains: R29's own case.** This replaces this section's first text, which named 1294's case as R29's case: as the case stood, it could pass on ubuntu with no build, and with its TMPDIR moved out of F it passes without R29.
  - **The shim.** A `mktemp` first on PATH, GNU-style. Only a bare `mktemp -d`, with no other argument, honours TMPDIR: it makes `${TMPDIR:-/tmp}/tmp.XXXXXXXXXX` (an empty TMPDIR is read as unset), prints the name as TMPDIR gave it, relative when TMPDIR is relative, and when the directory cannot be made prints mkdir's line on stderr and exits 1. Every other form is passed to the real mktemp (`/usr/bin/mktemp`, found by its path, not by PATH).
  - **The run.** With the shim first on PATH and TMPDIR `../reltmp` (the directory `$_db4_c/reltmp` made), a copy whose planted part runs a bare `mktemp -d` from its working directory, and writes its status and the name it got to a file the case names in the run's environment. Once under `-j 2` and once under `-j 1`.
  - **Expected**, under each: the run exits 0, the planted part's status is 0, and the name is a directory whose physical path (`cd` to it, then `pwd -P`) is below the physical path of `$_db4_c/reltmp`. R29's absolute TMPDIR is made against `_og_start`, a logical path, so the case compares physical paths.
  - **Red.** It is red against the build at 36a1ad25, under both: the part's `mktemp -d` fails with `No such file or directory`, as this revision's review measured above.

### R30. R23: the ticker's fork window, and the last KILL

Answers proc4 1. A process substitution sets `$!` as well: proc4 1 measured it on bash 3.2, and read in bash 5.2's make_child that it holds there. `_par_order` runs one (0007:524) after the kept value is taken (0007:791) and before the ticker's fork, and the driver runs one in the parent after `_par_run` (run:471). So the ending that `_fx_exit` runs at every `-j` run's end took a dead substitution's pid for the ticker and ran a stopper over it, and would take any job started after `_par_run` for the ticker too. R30 replaces R23's "The fork" bullet, and adds to its "The last KILL".
- **The window.** The comparison of `$!` with the kept value holds only between the ticker's fork and `_pj_tk=$!`. A flag set just before the fork and cleared just after it bounds it: the ending takes `$!` as the ticker only while that flag is set, the ticker's pid is unset, and `$!` differs from the kept value. The kept value is taken right before the fork, after `_par_order`.
- **The last KILL.** When the job table cannot be read at the loop's end (`_par_jl` fails), the parent sends no KILL by pid. This replaces the build's fallback (0007:819), which sent KILL by pid alone.
- **The FIFO is closed before the wait.** In both branches the parent closes fd 63 (`exec 63>&-`) before `wait "$_pj_tk"`, not after it (0007:820-821). This replaces, in R23's "The last KILL", "before it closes the FIFO" with "after it closes the FIFO". The ticker's next write then fails, within W s, and the ticker ends (R13: a failed write), so the wait reaps it.
  - Why it is needed. The ticker exits only on a change of parent or a failed write (R13), and it passes over a full FIFO's EAGAIN (0007:172-178). With the parent still holding the FIFO open for reading, no write fails, so in the branch that sends no KILL the wait would not return. R30's first text said "The wait then reaps the ticker" with the FIFO still open; that was false.
  - Measured for this revision, on /bin/bash 3.2.57 with 0007's own `_pj_tkpl` at W=2, the FIFO opened `63<>` and the ticker forked with `63>&-` as at 0007:802-806: with fd 63 kept open, `wait` had not returned when a watchdog sent the ticker KILL 13 s later (status 137); with it closed, the ticker ended by itself, status 141 (SIGPIPE) on its next write, or 1 when the close came before its `sysopen`. This revision's review measured the same: rc 124 at a 15 s bound kept open, status 141 after 1 s closed.
  - It holds only while no other process holds fd 63. Measured for this revision: a background subshell that inherited fd 63 kept the wait from returning with the parent's copy closed. Each wrapper holds it until it exits, and every wrapper has exited when the loop ends (0007:807-818); the holder and the ticker are forked with `63>&-`. Nothing else the parent forks after opening the FIFO may outlive the loop with fd 63 open.
- **D8 gains:** a case for the branch that cannot read the job table. The fork window still has none: it lasts microseconds, as R23 says.
  - **The interface.** The parent's job-table read writes `builtin jobs -rp` to the file `$_pj_dir/jobs` (0007:707), and `_par_jl` fails when that path cannot be written. The contract names that file as the interface this case uses. A wrapper exports the unit's log as `$_pj_dir/log.N` (0007:749), and the unit's 0001 keeps it as `_pm_log` and unsets FELIX_TEST_PART_LOG (0001:129-130). So a planted part, sourced in the unit's shell, names the file `${_pm_log%/*}/jobs`; `${FELIX_TEST_PART_LOG%/*}` is empty there.
  - **The run.** A `-j 2` run, with FELIX_TEST_SLOT_NOTE=5 so that W is 5, and slots enough that no unit waits. Its planted part replaces `${_pm_log%/*}/jobs` with a directory (`rm -f`, then `mkdir`), sleeps 2W s (10 s) so that at least one tick's `_par_jl` fails while it runs, writes the time it ends to a file the case names, and passes.
  - **Expected.** The run exits 0 within W + 10 s (15 s) of that time, and nothing of the run is left, stopped or running (R12), the ticker included.
  - **Red.** It is red against R30's first text, the KILL dropped and the FIFO still closed after the wait: that run reaches run.pl's bound. It does not tell R30's build from 36a1ad25's, whose KILL by pid also ends the wait; that half of R30, no KILL to a pid that may be another process's, rests on review, as R23's KILL does.

### R31. R24, R16: readonly functions with other flags, four more watched variables, and descriptors from 10 up

Answers conf4 3. Each is shell state a serial run carries to the parts after it, which `-j N` did not compare. No part does any of them today (conf4 3 grepped parts/ and lib/).
- **Readonly functions.** R24's readonly-function line matches any `declare -f` flags that hold `r`, `declare -frx` and `declare -frt` among them, as well as `declare -fr`. conf4 3 measured that 0007:273's `declare -fr (\S+)` gives no line for a readonly function that is also exported (`declare -frx NAME`) or traced (`declare -frt NAME`). R24's variable line already allows other flags (0007:268).
- **Watched variables.** R16's "Plain variables the main shell itself reads" gains EXECIGNORE, FUNCNEST, BASH_COMPAT and CHILD_MAX, which bash 4 and 5 read (0007:258 and 0007:292). bash 3.2 reads none of them, so their effect cannot be measured here, but the comparison is by name and reads the same under 3.2 and 5.2. BASH_COMPAT is watched although its name starts `BASH`: R8's exclusion list binds the recorded plain variables, not this list.
- **Descriptors 10 and above** are not compared, and join R16's "Not compared, with the reason", beside the command hash table. The reason: bash can name them only by globbing /dev/fd, whose own directory descriptor moves the set. Descriptors 0 to 9 stay compared as R16 has them.
  - **The lint.** A lint checks that no line of a part or of tests/lib opens one at the top level (`exec {NAME}>`, or `exec N>` with N from 10 up).
  - Today's lines that open one are not at the top level: 0007:802 opens 63 inside `_par_run`, and 0750:319-327 open 11 inside functions' subshells, through `eval`.
- **D8 gains:**
  - under `-j 3`, each of these planted parts gives the seventh failure with exactly the `  | ` line shown, exit 1 and no receipt, and in a `--red` record copy no manifest, as R24's cases do; under `-j 1` neither gives it:
    - a readonly exported function, `djx_rx() { :; }; readonly -f djx_rx; export -f djx_rx`: `readonly function djx_rx added`;
    - `EXECIGNORE='*/djx'`, plain, with EXECIGNORE absent from the run's environment: `variable EXECIGNORE added`;
  - the lint: it passes on the tree's parts and tests/lib, and fails on a planted part with a top-level `exec 11>/dev/null`, and on one with a top-level `exec {djx_fd}>/dev/null`.

### R32. R27's monitor case on bash 5.2

Answers ci456 (1) and conf4 2. R32 adds to R27's monitor case.
- **What each bash does.** On bash 5.2, red's `( cd "$TREE" && ... bash run ... ) &` (red:448-449) runs its last command in place, so SUITE is the `-j` parent itself. Bash 3.2 forks there: SUITE is the subshell, and the `-j` parent is its child.
  - conf4 2 measured 3.2, and read 5.2's execute_cmd.c (`optimize_subshell_command`, `optimize_connection_fork`).
  - So on 5.2 the suite's own ending, whose listings the case's shim did not hold (1293:372-375), ended the TERM-ignoring unit about when the monitor's wait for its root ended. The monitor's second listing then found nothing new, and its third came after its KILL: ci456's `stopped=0`.
- **The hold.** In mon mode the case's shim holds every ending listing (R19's `ps -A ... ppid=` call) made by a process of red's suite, bounded, until the TERM is sent, as wat mode holds red's tree. So the suite's own ending stops nothing before the monitor's STOP, on 3.2 and 5.2 alike.
- **The comment.** The case's comment (1293:340-352) says what each bash does.
- **Red.** The case stays red against a monitor that does not ignore TERM.

### R33. R27's watcher case: green on ubuntu, and not resting on /bin/sh

Answers conf4 1. R27's watcher case passed on CI's ubuntu (ci456), against conf4 1's prediction. Why it passed there was not measured. R33 adds to R27's "Which process".
- **conf4 1's reading** stays in the contract as the reason to make the shim's identification independent of /bin/sh.
  - A holder lists through perl's backticks (`endtree`'s listing, 0007:56), which run `/bin/sh -c`.
  - On ubuntu /bin/sh is dash, which execs the listing's ps in place. So the ps's parent is the holder's perl, and its grandparent is the holder's wrapper, a fork of the record run whose command line holds `--record-assertions`. Wat mode (1293:376-377) then counts the record run's holder as the watcher's stopper.
  - conf4 1 measured /bin/dash here: the listed ps's parent was the perl itself, and under /bin/sh (bash 3.2 on this Mac) it was the sh.
- **The rule.** The shim counts a listing as the stopper's only when the listing's parent is a `$( )` subshell of the stopper, which keeps its parent's command line: the ps's parent has the grandparent's command line. A perl or an sh has its own.
- **Both shells.** The case is required to stay green on both shells. Here it is also run with /bin/dash as the sh perl uses, for example on a copy whose holder runs its listing through `/bin/dash -c`, since perl's /bin/sh cannot be changed here.
- **Red.** It stays red against both of R27's watcher mutants.

### R34. R19: R2's shim in 1292 counts only `ps -A` calls

Answers proc4 2. R19 pins the ending's Nth listing as its Nth `ps -A` call. 1292's R2 shim counts every call whose arguments hold `ppid=` (1292:83), so a holder's `ps -o ppid= -p WRAPPER`, which R20 makes every 10 s (0007:48-50), takes a number. proc4 2 measured the holder's calls at 0, 10 and 20 s. So the case named for the second listing failed a holder's check, and step 4's second round was never failed. R34 adds to R19's listing pin.
- **The pin.** R2's shim in 1292 counts only `ps -A` calls, as R19 defines a listing. A holder's `ps -o ppid= -p` (R20) is never counted. 1296's shims already count so (R28).
- **D8 gains:** no new case. R2's three cases then fail the ending's first, second and third listings, as their names say.

### R35. R20's D8 gain: an orphan case

Answers proc4 3. R20's own check, that its wrapper's parent is still the `-j` parent, had no case. R28's pw case kills the parent with -9, whose pid is then free, and the holder's `kill 0` (0007:47) finds it gone before R20's check (0007:48-51) is reached. So a holder without R20's check passed every blind part, and so did one that kept R15's start-time comparison, the Linux clock-step hazard R20 removes. R35 adds to R20's "D8 gains".
- **The shim.** Once a gate file exists, a `ps` first on PATH answers a holder's `ps -o ppid= -p WRAPPER` (a call whose arguments hold `ppid=` and ` -p `, and not ` -A `) with `1`. Every other call is the real ps's.
- **The run.** A `-j 2` run of one long part, with the gate written once the unit is up.
- **Expected.** Within 20 s the unit is gone (the holder asks at most once every 10 s, and under load the shim, ps and the stopper's listings take seconds more; review 5 measured 1.9 to 7.4 s at load 6), and the parent, still running, fails it as ended without its mark (`part ended without its mark: UNIT`; the holder exits 2). Exit 1, no receipt, and nothing of the run left, stopped or running.
- **Red.** It is red against a holder without R20's check, and against one that compares the parent's start time as R15 did.

### R36. R28's pw case: the kill waits for a holder

Answers proc4 4. The pw case killed the parent 2 s after the mark at the end of the copy's 0006 (1296:472-473). After 0006 the parent still sources 0007 and the lib files and runs `_par_run`'s setup before it forks a wrapper, so under load the kill could land before any holder existed, and the case then passed for any build, R15(a)'s mutant included.
- **The text.** R36 replaces, in R28's "The parent killed while a holder waits", "and 2 s have passed" with "and a holder has written its slot line (1296's `_db6_hpid_up`) and at least one slot poll has run". So the parent is killed then, not 2 s after the prelude mark.
- **Unchanged.** The case's check that no unit has started while the slot was held elsewhere stays, as do its other checks.

### Every finding of review 4 and of ci456, and where it went

Test fixes go to a blind author with this revision, before any code fix: R32, R33, R34, R35 and R36, the D8 gains of R29, R30 and R31, and R29's new geometry for 1294's R5 case. Code fixes go to the builders once the new blind tests are red: R29, R30 and R31.

- proc4 1 (minor, code): R30, the comparison of `$!` held to the ticker's fork, the kept value taken after `_par_order`, no KILL by pid when the job table cannot be read, and the FIFO closed before the wait so that the wait returns; with a case for the unreadable job table.
- proc4 2 (minor, test): R34, 1292's R2 shim counts only `ps -A` calls.
- proc4 3 (minor, test): R35, the orphan case for R20's check.
- proc4 4 (minor, test): R36, the pw case's kill waits for a holder's slot line and a slot poll.
- conf4 1 (blocker, test): R33. The case passed on ubuntu (ci456) against its prediction; its reading of dash stays as the reason for the shim's new rule, and the case is run with /bin/dash here.
- conf4 2 (major, test): R32, mon mode holds red's suite's listings; it is ci456 (1).
- conf4 3 (minor, contract): R31, (a) readonly functions with any flags that hold `r`, (b) descriptors 10 and above not compared, with the reason and a lint, (c) EXECIGNORE, FUNCNEST, BASH_COMPAT and CHILD_MAX watched.
- ci456 (1), 1293's R27 monitor case: R32.
- ci456 (2), 1294's R5 relative-TMPDIR case: R29. The case's TMPDIR lay inside its fixture checkout, which 0001 refuses; it becomes `../reltmp`, and R29 gains its own red case, a part's bare `mktemp -d` under a GNU-style mktemp.
- ci456's other two FAILs, red.tsv's base and this engine's version above origin/main's: owed at the carrier's record and version, as for every build of D. No contract change.
- conf4's summary, missing evidence: the reports of the red-against-a-mutant runs that revision 9's preamble asks for are not named for R27's and R28's cases. They are owed with the next round's reports, with those of this revision's cases.

**Settled after this revision's review:** R29's open item (the case's TMPDIR becomes `../reltmp`, and R29 gains its own case) and R30's (the FIFO is closed before the wait, with a case). Nothing is left open in this text.

**Deliberately not taken:**
- conf4 3 (b)'s first remedy, descriptors 10 and above compared from /dev/fd or /proc/$$/fd minus the runner's own: R31 lists them as not compared, for its reason, with a lint.

## Amended after the first evidence pass (revision 11, 2026-10-20)

The first pass of D8's evidence ran on frozen clones of 14b5ec35 (revision 10's build through e731b937, with main e3636d40 merged in), each started from perl with INT and QUIT at their defaults. Its findings are audits/2026-10-18-gate-friction-d/evidence/findings-ev1.md, cited as **ev1** N, N being its numbered items. Its runs are in evidence/runs/: **j1**, the serial record run (`--record-assertions`, 09:51:35-11:16:42Z), and **j8**, the parallel one (`-j 8 --record-assertions`, 09:01:26-09:51:35Z), each with its log.tsv, red.tsv and summary.json, and **compare-j1-j8.txt**, the comparison ev-compare.py made of the two. Load was 7 to 210 during j8 and 9 to 30 during j1.

Revision 7's conventions hold: each amendment names the clauses and lines it replaces, every line it does not name stands, and its "D8 gains" are added to D8's cases for the blind parts. File and line references are to 14b5ec35. Revision 9's rule holds for every case this revision adds: it is red against a build without the rule it names, and where the build already has that rule, against a copy of the build with the rule taken out, the report naming what was taken out and the FAIL it gave. The figures this section gives are ev1's, measured on this Mac on 2026-10-20 (UTC) under that load; what it read from the tree at 14b5ec35 itself, it names by file and line.

### R37. D5, D8: no pipe into a tar that extracts

Answers ev1 1. R37 adds to D5 and to D8.
- **What failed.** j8 failed six assertions of 1291 that j1 passed: two of D1, two of D2, one of D4 and one of R9, all on its grp copy, each run of which exited 127. Just before them the unit printed two lines, `tar: Write error` and `tar: Error exit delayed from previous errors.`, and `_suite_copy_tree` had returned 1 at its `_copy_content`, so the copy had no `run`, and 1291 does not check `_db1_new grp`'s status (1291:294).
- **Why.** `_copy_content` (0004:83-87) runs `( ... | tar -c --null -T - -f - ) | tar -x -f - -C "$dest"` under the suite's pipefail. macOS bsdtar 3.5.3's extractor stops reading at the end-of-archive marker and does not drain its input. When the writer still has records to write at that moment, its next write fails with EPIPE, it reports `Write error`, and the pipeline fails. ev1 1 reproduced it: a writer that writes after the archive's end gets `Broken pipe` while the extractor exits 0.
- **The class.** It is the class of the land contract's A29 (docs/2026-10-15-land-on-green-contract.md:409-421): `git archive | tar -x` under pipefail failed 192 of 1,500 runs on a fixture-sized engine with ten loops at once, and A29 moved main's check off the pipe. The suite kept the pipe, and it is of 0960's class too, a reader that stops early under pipefail, which 0960's lint reads only for grep.
- **The rule.** Every tar extraction in engine/harness reads an archive written whole to a file first (`tar -c -f FILE`, `git archive -o FILE`), FILE being a file of the call's own under `$TMP`, never a pipe. The two fixture controls below are the only pipes into an extracting tar, each on purpose. A `tar -xO -f FILE` whose output is piped to a reader that reads to its end, as 1403's `sed -n 1p` and `grep -c` do, is no extraction from a pipe. The sites at 14b5ec35:
  - 0004:83-87, `_copy_content`;
  - 0430:281, 0440:150 and 0940:237, each `git archive | tar -x`;
  - 1403:85 and 1403:109, each `git archive | tar -xO | ...`;
  - none in tests/lib, lib, bin or felix.
- **The controls.** 1286's `_l7_plain` (1286:78-83) pipes `git archive` into `tar -x` on purpose. It is A29's fixture control: with 1286's stand-in git first on PATH, the pipe fails on each of three runs (1286:86-89). It stays as it is, and the lint (b) allows it by the part's name. D8 gain (a) adds a second control, a pipe of tar into tar. It calls tar through a variable that holds the bare word `tar`, so PATH still finds the stand-in, and the lint, which names only a literal `tar` after the pipe, does not see it ("What it does not see"). It is the one pipe into an extracting tar the lint is not to name, and its part is not allowed by name.
- **Why in D.** D's load makes the race fire: ev1 1 saw one copy fail among the thousands of tar pipes of a `-j 8` record run at load about 200. That one firing changed six verdicts of the equivalence evidence, so `-j 1` and `-j 8` differed by more than D's own differences. A29 measured the class, so R37 does not wait for it to fire again.
- **Outside D.** projects/felix/snapshot.sh:224 has the same pipe (ev1 1). It is outside what D changes ("Not in this"), and ev1 noted it in memory for its own change.
- **D8 gains:**
  - **(a) `_copy_content` whole under a reader that stops early.**
    - *The stand-in.* A `tar` first on PATH, written by the case, which calls the host's tar by the path `command -v tar` gave before the stand-in was put on PATH. For `-c` it runs the host's tar with the same arguments and then, after a pause (0.5 s, as 1286's stand-in git has it), writes 1 MiB of zero bytes more where the archive went: to standard output when the archive is `-f -` or no `-f` is given, else appended to the file `-f` names. That is what 1286's stand-in git does for `git archive` (1286:71-73). For `-x` it reads its archive, from standard input when the archive is `-f -` or no `-f` is given, else from the file, in records of 512 bytes, up to and including the end-of-archive marker (two records of zeros) and no further, as bsdtar does. It then extracts what it read with the host's tar and exits with that tar's status. So the case means the same under GNU tar, which reads its input to the end. It logs each call's mode to a file of the case. Its text calls the host's tar through a variable holding that path, never a literal `tar` after a `|`.
    - *Its control.* With the stand-in on PATH and `t=tar`, `"$t" -c -f - DIR | "$t" -x -f - -C DEST` under pipefail fails on each of three runs, and the log shows both modes called (fixture control, as 1286:86-89 has it for git archive). The variable is what keeps the lint from naming the line (see "The controls" above). Neither the control's comment nor its assertion's name writes a `|` followed by a literal `tar` with an extracting option, so the part holding (a) holds no line the lint names.
    - *The case.* With the stand-in first on PATH and pipefail set, as the suite sets it, `_copy_content` copies a source that is a git checkout holding a tracked file, an untracked file that is not ignored, and a file in a subdirectory. It returns 0, and the destination holds each of them with the same bytes, and nothing else.
    - *Red.* It is red against a `_copy_content` that pipes, as 0004:83-87 does at 14b5ec35.
  - **(b) The lint.** One matcher, in the manner of 0960's `_spl_scan` (0960:9-52), over every file of engine/harness/tests/parts, engine/harness/tests/lib, engine/harness/lib and engine/harness/bin, and engine/harness/felix.
    - *What it names.* file:line wherever a `|` that is not half of `||` is followed, after optional `command`, `env`, `nice`, `time`, `(` and `{` words, by `tar` with an option word or cluster that holds `x`, or `--extract` or `--get`. An option word or cluster is a word after `tar` that starts with one dash and is not `-` alone (`-x`, `-xO`, `-xzf`), or tar's first word when it has no dash (`xf`, the old style); a long option other than `--extract` and `--get` (`--exclude=x`) is not one.
    - *How it reads, as 0960's matcher reads.* Comment lines are skipped. A pipe that ends a line, or ends its code before a comment, carries onto the next line of code, and a line may start with the pipe. Quoted strings and trailing comments are read as code, so a string or a comment holding the shape is named.
    - *On the tree.* On the tree this round lands it names lines of 1286 alone, 1286's control and the lines that describe it, and it allows them by the part's name, so it reports nothing. (a)'s control, through its variable, is not named, and no other line of the tree is. At 14b5ec35 it names 1286:78 (the control's head comment), 1286:81 (its pipe) and 1286:88 (the assertion's name, a quoted string), and the six sites of R37's list, so it is red against 14b5ec35. The part that holds the lint holds no line the lint names: its samples are built from pieces at run time, as D1's blind part builds the jobs variable's name. Where (a) and (b) share a part, that holds of (a)'s lines too, as (a)'s control says.
    - *Samples*, each a file in a `mktemp -d`, as 0960's are. It flags `x | tar -x -C d`, `x |tar -xf -`, `x | tar xf -`, `x | tar -C d -x`, `x | tar -xO | sed -n 1p`, `x | tar --extract -f -`, `x | tar --get`, `x | command tar -x`, `x | env tar -x`, `x | nice tar -x`, `x | time tar -x`, `x | ( tar -x -C d )`, `x | { tar -x; }`, a pipe that ends a line with `tar -x` on the next, and a line that starts `| tar -x`. It passes `x || tar -x -f a.tar`, `tar -x -f a.tar`, `x | tar -c -f -`, `x | tar -t`, `x | tar -c --exclude=y -f -`, `tar -xO -f a.tar | sed -n 1p`, `tar -c -f - . | cat > a.tar`, and a comment line holding `x | tar -x`.
    - *What it does not see*, as 0960 lists its own: a VAR=value prefix, a wrapper given options of its own (`nice -n 15`), a tar named by its path or through a variable (as (a)'s control is, on purpose), a pipe into a function that runs tar, and code built at run time with eval.

### R38. D8: R1's leftover cases red against the base on every run, and 1292's interrupted record run the same on every run

Answers ev1 2. R38 adds to R1's D8 gains and to D8's evidence, and changes 1292's D6 case (below).
- **What differs.** j1's red.tsv names 35 failures and j8's 37, and 31 are in both. The rest are cases that look for a process of red's tree left after a record run: among 1293's R1 names, 4 only in j1 and 4 only in j8; 1295's R1 name only in j8 (ev1 2 counts it with 1293's, as 5); and 1292's D6 case only in j8. Each of the 13 names 1293:137 makes was red in at least one of the two runs, and 8 of them in one only.
- **Why.** Red's suite runs these cases on the base's tests/red and tests/receipt.sh. Red copies only run, parts, lib and groups.tsv into the base, so `_suite_copy_tree` builds each copy with the base's red and receipt.sh, which lack R1 and R2's stoppers. Read from origin/main (e3636d40):
  - its `_rcp_red_end` takes no bound and waits for red (receipt.sh:489-494);
  - its red runs its suite as a job and waits for the whole of it (red:427-434), and its monitor ends that suite only when the record run is gone with no mark (red:430);
  - its `_rcp_stop` is the one "What decided the list" describes: TERM, a wait, then STOP and KILL to one list.
  So a record run after a runner failure exits, against the base, only once red's suite has ended on its own. What is left of red's tree at that exit is only what is still ending then, for example the `sleep 1` that a `kill` of red's monitor (red:435) or of the record run's watcher (receipt.sh:497) leaves running. A listing taken at that moment catches it on some runs and not on others. The planted parts these cases give red's suite end in moments, so nothing of theirs holds red's tree open. Each case is red only some of the time against the build it must be red against, and red.tsv cannot be the same from one run to the next.
- **The names.**
  - 1293's 13 names "R1: and once the record run after ... has exited no process of red's tree is left, stopped or running", one for each runner failure of `_db3_rf` (1293:137, its calls at 1293:163-263);
  - 1295's "R1: and once that record run has exited no process of red's tree is left, stopped or running" (1295:281);
  - 1292's "D6: TERM to a record run under -j 2, both units up: ..." (1292:574), which "1292's D6 case" below treats.
- **The rule.** Each of the 14 R1 names fails on every run against a build that lacks R1, as red's suite runs it, with the base's tests/red and tests/receipt.sh in each copy. Each passes on every run against D's build. The mechanism below is what makes that so.
- **The mechanism, for the 14 R1 names.** Each case's red suite holds a red-only process that is still running when the record run exits, as 1293's 90 s sleeper case (1293:309-337) has one. That case's names are red in both j1's and j8's red.tsv. Unlike that case, the hold is bounded and released, so that it costs seconds.
  - *Where.* Only in the case's record half. A variable of the case's own is given to that run alone, as `_db3_E` and `_db5_E` give one, and the case's plain `-j 3` run is as it was. The step runs only where `FELIX_TEST_NO_MANIFEST=1`, which only red's suite sees, as 1293:280-283 and 1293:319 plant theirs. It comes before the case's own failure: in the body of a part, or, where the case's failure is in the units' prelude (pre, prp, prk), in the prelude the case plants. Where more than one unit or part would run it, only the first to make a directory of the case's runs it.
  - *The holder.* The step starts a holder H as a job. H is a process that ends within 0.2 s of the case's release file appearing, and on its own 60 s after it started. The step writes H's pid and a start file. It then waits until the record run's go file exists and C = 10 s more, and goes on, to the case's failure or to its end, without waiting for H.
  - *The record run's wait.* Where `FELIX_TEST_NO_MANIFEST` is not 1, in the same places, the record run's own units wait for that start file, 60 s at most, as 1293:326 waits for the sleeper's, and then write the go file, before the case's failure. So the record run fails, and writes `failed`, only once H runs.
  - *Against the base.* Red's suite goes on after C and ends by itself, leaving H running, a job no one waits for. Red then refuses the `failed` mark and exits, and the record run, which waited for red, exits. H's 60 s outlast C and red's tail, so H is in both of `_db3_atexit`'s listings (1293:37-44; 1295's `_db5_atexit`, 1295:41) and the name fails on every run.
  - *Against D's build.* Red's monitor ends red's suite on the `failed` mark while the step holds (R1), with H a descendant of the step, so nothing of red's tree is left when the record run exits, before `_db3_atexit`'s first listing. C must exceed, on each of the three runs against the branch, the time from the go file to the end of the holding step. The evidence gives the largest such time.
  - *The release.* The case writes the release file as soon as `_db3_atexit`'s listings are taken, before `_db3_clean` (in `_db3_run`, 1293:75, and `_db5_run`, 1295:86). Against the base, H then ends within 0.2 s, so `_db3_clean` (1293:46-52) waits about a second, not its 30 s.
  - *What it costs.* Against D's build, each case waits for red's suite to reach the step, as 1293:326's case does now: what red's base checkout and its preludes take. Against the base, as red's suite runs it in every record run, each case adds C and about a second, so about 14 times 11 s over the red units of 1293 and 1295. Today a leftover there can wait out `_db3_clean`'s 30 s. The evidence reports each part's time against both builds.
  - *What else it changes.* None of the case's other names. `_db3_chkr`'s red.tsv check holds against both builds, since red refuses a `failed` mark either way.
- **1292's D6 case: the same on every run, by passing.** Here the record run is ended by a TERM, not by a runner failure, so the record run's watcher stops red's tree after the record run has gone. Against the base that is its one-list `_rcp_stop`, with red's own one-list stop of its suite; the case gives them 30 s to clear the group (1292:161-168). A one-list stopper misses only a process forked after its listing. Against the base, then, the case fails only when red's suite starts one of rrt's `sleep 300` children (1292:271) just after the base's stoppers have listed, which is timing; j8's one failure is of that shape. A planted part could make the base's lists miss a process on every run only by holding those listings, as R33's watcher case (1293:483) does with its shim and its second TERM. That case already pins a watcher's stop of red's tree, and it is red in both j1's and j8's red.tsv. So 1292's case is made the same on every run the other way:
  - before its TERM, the case also waits, 60 s at most, until red's suite has started its rrt children and holds, read from a file the red-only side writes (where `FELIX_TEST_NO_MANIFEST=1`), as 1293:326 waits for the sleeper's. Red's tree then forks nothing while it is stopped, and the base's one list holds all of it;
  - its name and its checks stand. It passes on every run against D's build, and on every run against the base, which is what red.tsv needs of it. Its added cost is that wait. Revision 9's rule is unchanged for it: it stays red against a build without D6's ending of a record run.
- **D8 gains**, as evidence: for each of these cases, three runs against a copy whose tests/red and tests/receipt.sh are origin/main's (`git show origin/main:<path>`), and three runs against the branch. The 14 R1 names fail on each run against origin/main's and pass on each run against the branch. 1292's D6 name passes on all six. The reports of those runs are the evidence, in the PR, with each part's time and the largest go-to-end time against the branch (C's margin).
- **D8's red.tsv clause stands.** After R38 the evidence pass checks that the `-j 1` and `-j 8` record runs give byte-identical red.tsv.

### R39. D8's equivalence clause, D4: the serial record's re-judge section

Answers ev1 4. R39 adds to D8's evidence clause "Equivalence on the real suite".
- **What differs.** Under `-j N` a record run is not re-judged (D4's re-judge bullet): the tail prints `  no record judge in this suite: the record is not re-judged` (run:448). Under `-j 1` it prints an empty line, `the record this run wrote` and the record judge's names (run:441-446). So the serial record's re-judge section has no `-j` counterpart.
  - In ev1 4 it was the one difference in the order of the part sections (compare-j1-j8.txt: the first difference at line 303, `the record this run wrote` against the summary, 305 lines serial and 304 parallel).
  - Beside ev1 1's six, it was the one difference in the (verdict, name) multiset: the serial run had one FAIL more of "this engine's version is above origin/main's when this tree holds commits origin/main lacks", and the three ok lines of red.tsv's record checks.
- **The section** is the serial run's lines from `the record this run wrote` to the summary that are the record judge's: the header, the judge's assertion lines and their detail lines. The tail's manifest comparison after it (`  ok    every assertion in the manifest was reached`, run:475) is printed by both runs, and stays compared.
- **The checks.** D8's multiset check and its section-order check leave that section out of the serial run, and the evidence says so, naming the lines left out.
- **Unchanged.** Everything else in them stands: skips compared by name and by reason, 0573's and 0574's signal cases, the manifest byte for byte, and red.tsv (R38).

### Recorded, with no change

- **ev1 3, the stray lines.** The verdicts are unchanged. Each is a D5 candidate, judged in the PR from the class sweep (D5, D8's "The class"), which runs serially now under evidence/runs/d5:
  - 0140:208-215 keeps and restores `$FROOT/projects/widget/risk.tsv`, and 0450:376 and 387 keep and restore `widget/maintenance.tsv`. Both are files an earlier part made; in a unit they are absent, and `cp` prints `No such file or directory`;
  - 0580:274 redirects into `$FROOT/state/discover/`, which an earlier part makes, and its fallback makes it; 0580:341 and 343 read `$FROOT/projects/widget/stack.tsv`, absent in j8's unit;
  - 0780:31 (`_xc_col`, `printf | awk '... exit'`) printed `write error: Broken pipe` under load, a reader that stops early, of 0960's class;
  - the parent's R6 notes, `has waited 300 s for a slot`, for 5 units, with the record run and red each at `-j 8` on 10 cores;
  - lines that differ only in a pid or a line number: 0350's `Terminated` and 1296's `Killed: 9 perl`.
- **ev1 5 and 6, the parent.** They meet D8.
  - The parent's own CPU over the `-j 8` run was 3.0 s at its last 1 s sample, 0.7 s before its end, so at most 5 s.
  - While a planted 20 s unit ran (seconds 2 to 24 of p20b/children.txt), the parent's only children were its three wrappers and its ticker, as R13 has D8 read. A `(bash)` of the prelude at seconds 0 and 1, and the tail's `rm` at second 25, came before and after the unit ran.
- **ev1 5, the cost.** The cost clause (D8's "Cost, on a quiet machine") is measured after this round, on the tree that lands, with the plain pair (p8 and p1) moved there as ev1 5 says. ev1 5's record-run numbers are reported beside it as measured under load: j1 used 8,354 s of CPU (record and red, getrusage) over 5,107 s of wall, and j8 12,657 s over 3,009 s, above the bound of 9,121 s (1.05 times serial, plus 2 s for each of 175 units), with red at `-j 8` beside the record, so 350 units in all, at load 7 to 210. Savings are still claimed only from CPU measured quiet.
- **ev1 4, the rest.** assertions.tsv was byte-identical; both runs had no runner failure and no "part left the shell changed", which is R8's evidence gain and R25's binding evidence on 14b5ec35. The evidence pass is run again on the tree this round lands, with R38 and R39.
- **ev1 1, 1291:294.** 1291 does not check `_db1_new grp`'s status, so a copy that cannot be made fails its cases with exit 127 and no line naming the copy. With R37 the copy no longer fails this way. No change in this revision.

### Every item of ev1, and where it went

Test fixes go to a blind author with this revision, before any code fix: R37's D8 gains (a) and (b), and R38's cases. Code fixes go to the builders once the new blind tests are red: R37's six sites. R39 changes the evidence pass's comparison (ev-compare.py), not the suite.

- ev1 1 (the tar race, the A29 class): R37, every extraction reads an archive written whole to a file, at 0004:83-87, 0430:281, 0440:150, 0940:237, 1403:85 and 1403:109, with 1286's control kept and allowed by name; its D8 gains are `_copy_content` under a stand-in tar, with a tar-into-tar control called through a variable the lint does not see, and the lint. projects/felix/snapshot.sh:224 is outside D. 1291:294's unchecked status is recorded, with no change.
- ev1 2 (red.tsv not reproducible): R38. R1's 14 leftover names are red against the base on every run, through a red-only holder released after the record run's exit (C = 10 s; seconds per case, not 30 s). 1292's D6 case passes on every run against both builds, its TERM sent once red's suite holds, with a watcher's stop of red's tree pinned by R33's case. Each is shown by three runs each way; D8's byte-identical red.tsv clause stands.
- ev1 3 (stray lines): recorded, with no change; D5 candidates, judged in the PR from the class sweep.
- ev1 4 (order and manifest): R39, the serial re-judge section left out of the multiset and section-order checks, saying so; the manifest's identity and the absence of runner failures and of the seventh failure are recorded, and the pass is run again after this round.
- ev1 5 (the parent and cost): the parent's 3.0 s meets D8; the cost clause is measured after this round on the tree that lands, with ev1 5's record-run numbers beside it as measured under load.
- ev1 6 (the planted 20 s unit): meets D8, as R13 reads it.

## Amended after the class sweep and round 5's review (revision 12, 2026-10-20)

**The class sweep** is D8's evidence "The class (D5)", run once on a frozen clone of 14b5ec35. One serial run of the suite, from a driver that called a hook before every part line numbered 0010 or later (182 parts), recorded for each part the paths it made, changed and removed under `$TMP`, and those under `$HOME` and the host's temporary directories outside it. The run exited 0 with no FAIL, in 4,791 s of wall. Its record is audits/2026-10-18-gate-friction-d/evidence/runs/d5-class.txt, whose sections this revision cites by number (section 1, each part's seconds and counts; section 5, outside `$TMP`). Three read-only reviewers judged its clusters: readers 0010 to 0590 (evidence/d5-verdicts-0010-0590.json and .md), readers 0600 to 1540 with what was left outside `$TMP` (evidence/d5-verdicts-0600-1540-outside.json, its "clusters" and "outside" lists), and the whole-tree snapshots (evidence/d5-verdicts-snapshots.json). Every yes was confirmed by hand. evidence/d5-candidates.md is the table of all of them. A cluster is cited as **d5** R, R being its reader part as that table names it (d5 0201), and an entry of the outside list as **d5 outside** R (d5 outside 1292-1296).

**Round 5** reviewed revision 11's build: f071a281 (R38's cases in 1293 and 1292), 744c370b (R37's cases in 1296) and c8432b46 (R37's six sites). Two lenses, cited by report and number, numbered in each one's findings from 1: **conf5** (the result labelled review:conformance-and-weakening) and **proc5** (review:processes-and-tests), both in the journal of workflow wf_b7ae726a-340, /Users/a14808/.claude/projects/-Users-a14808-Documents-Felix--claude-worktrees-charming-bartik-58e065/31f23b02-d731-4c08-8011-021dab98cc58/subagents/workflows/wf_b7ae726a-340/journal.jsonl.

Revision 7's conventions hold: each amendment names the clauses and lines it replaces, every line it does not name stands, and its "D8 gains" are added to D8's cases for the blind parts; "D8 gains, as evidence" are added to D8's evidence, as R38's are. File and line references are to c8432b46, read there for this revision; where a verdict file cites 14b5ec35 and the line has moved, this section gives c8432b46's. Revision 9's rule holds for every case this revision adds: it is red against a build without the rule it names, and where the build already has that rule, against a copy of the build with the rule taken out, the report naming what was taken out and the FAIL it gave.

### R40. D5: the class sweep's remedies

Answers d5 0201, d5 0850, d5 0880-0890, d5 0580 (its lines 341 and 343) and d5 1270, which judge less when their reader runs alone, and d5 0140, d5 0450 and d5 0580 (its line 274), ev1 3's stray lines. R40 adds to D5's groups, after R17's rx, and to D8.

**Five clusters judge less alone.** The remedies:
- **(a) Group gp: 0200 and 0201** (d5 0201). `0200-generated-constitution.sh` and `0201-continued.sh` are adjacent at run:245-246.
  - `_gitproof_base` sets `_gp_rec0`, the length of the suite's refusal record, only when it is unset (lib/gitproof.sh:75-79). In the serial run 0200's call (0200:238) sets it and 0201's (`_gitproof_build`, 0201:4) keeps it, so 0201:308-311, "no refusal this block provoked reached the suite's own refusal record", judges every refusal 0200 and 0201 provoked. In a unit of its own, 0201 sets it at 0201:4 and judges only its own.
  - groups.tsv gains group gp, with a comment of its own: two members, contiguous, neither in another group, neither 0001 to 0009 or 9990. Serially the two take 25 s (d5-class.txt section 1: 14 s and 11 s).
- **(b) Group au: 0810, 0820, 0830, 0840 and 0850** (d5 0850), adjacent at run:321-325.
  - `_au_build` sets AU, AUD, AUSTUB_LOG and AU_ERR (lib/audit.sh:157-162) and empties the stub log only when it builds (:178). `_au_resume` takes the snapshots of AU and its HOME once, before the first audit run (:353-361). 0850:182-197 asserts, after the last audit run, that nothing changed under the scratch root outside the review fixtures or in the scratch HOME, and that no claude, gh, curl or wget was called: over the stub log and the snapshots since the first audit run. Run alone, those are 0850's own.
  - 0820, 0830 and 0840 have no such check of their own, and 0810's (0810:114-124) covers only 0810's runs. So serially a write or a stub call made only on a path of 0820 to 0840 fails 0850, and under `-j` it passes.
  - groups.tsv gains group au, after gp: five members, contiguous, none in another group. Serially the five take 50 s (section 1: 4, 10, 4, 24 and 8 s), well below ib's 300 s.
- **(c) 0870 judges its own runs' failed redirections** (d5 0880-0890). 0870:332's pattern gains `|Permission denied`, as 0880:132's and 0890:258's have it.
  - Every run of 0870 appends its stderr to IV_ERR (`_ivrun`, lib/inventory.sh:104), which 0870:9 empties first. Serially, 0880's and 0890's checks of IV_ERR read 0870's runs too; alone they read only what `_iv_runs` (lib/inventory.sh:606-625) makes again, which leaves out 0870:59, 62, 67, 230, 240 and 247 (the `IV_CMP` variants, and RC6B).
  - With the pattern, 0870 judges those runs itself, alone or not. Its name at 0870:333 is unchanged, so the manifest is.
  - Not a group: that would put 0860 to 0890 in one unit for a check 0870 can make itself. 0880 and 0890 keep their checks.
- **(d) 0580's "discovery writes nothing" compares a stack.tsv that no part run alone has** (d5 0580, d5 1270).
  - 0580:341-344 compares the cksum of `$FROOT/projects/widget/stack.tsv` before and after `felix discover`. Serially the file holds the three rows of lib/router.sh:49-53, which `_router_build tables` writes from 0230:5, and writes again from 0240:2 and 0250:3 through `routed`. Of the parts that change the file (0010, 0030, 0070, 0210, 0230 and 0590, d5 1270), 0230 is the last before 0580.
  - After the prelude the file is absent (ev1 3 found it absent in j8's unit), so alone both sides read a missing file. A discover that creates the file still shows; one that rewrites an existing stack.tsv shows only serially.
  - 1270 re-runs that block, cut from part 0580 from "# It recommends. It must never acquire." to the "seeing the whole toolbox" printf (1270:26-29), and has the same gap.
  - **The rule.** Inside that block, before its `before=` line, when `$FROOT/projects/widget/stack.tsv` is absent the block writes a non-empty one holding those three rows, as 0580:5 writes widget's capabilities only when they are not there. After the block's last read of the file (0580:343), it removes the file if it wrote it. Serially the file is there, nothing is written or removed, and the block judges as it did. 1270's keep and restore around its re-runs (1270:54-55) stands.
- **(e) ev1 3's stray lines, with no verdict changed** (d5 0140, d5 0450, d5 0580 line 274).
  - 0140 keeps widget's risk.tsv at 0140:208 and restores it at 0140:340; 0450 keeps widget's maintenance.tsv at 0450:376 and restores it at 0450:387. Each keeps and restores the file only when it exists, and a restore of a file that was absent leaves it absent: the part removes what it wrote there.
  - 0580:274 makes `$FROOT/state/discover` before its redirect, in place of the fallback after it.

risk.tsv's row for groups.tsv (D5) stops (a) and (b) for the verifier, as D5 means it to. Nothing in R40 adds or removes a manifest name.

**Recorded, with no change**, each with its verdict:
- **The whole-tree snapshots** of 0671 (0671:25-27, judged at :270), 0680 (four: :29-31 at :225, :255-257 at :489, :531-533 at :784, :818-820 at :990), 0681 (:16-18 at :343) and 0700:308-309 (file names only, judged at :340) judge the same alone. d5-verdicts-snapshots.json reads, command by command, every write their commands reach, and each is keyed to the block's own project. The second reader had left them unclear; the third settled them.
- **0940** is in ib (d5 0940). **9990** is D3's: it reads every unit's end file (d5 9990).
- **0780:31** (`_xc_col`, `printf | awk '... exit'`) and **0190:376 and :384** are 0960's class, a reader that stops early: stray `Broken pipe` lines, with no verdict lost, since awk prints its field before it exits and no caller reads the status (d5 0780).
- **Every other cluster** is independent, builder-backed, keep-restore, cleanup or already grouped (d5-candidates.md).

The PR lists every candidate with its verdict, from d5-candidates.md.

**D8 gains, as evidence.** For (a) to (d), the builder shows, by a mutation in a clone, that the check catches alone what it caught serially. D1 refuses `--part` with `-j` (0001:117), so a `-j` run of a few parts is made in a clone whose driver keeps, of its part lines from 0010 to the one before 9990, only those of the parts named, with a groups.tsv that holds only the group's own lines:
- (a) a mutation of 0200 that provokes a refusal reaching the suite's refusal record after 0200:238 makes 0201's name FAIL under `tests/run -j 2` on a driver of 0200 and 0201 with gp, and pass with gp removed from groups.tsv;
- (b) a mutation of 0820, 0830 or 0840 that calls the stub claude once makes 0850's name FAIL under `tests/run -j 2` on a driver of 0810 to 0850 with au, and pass without;
- (c) a mutation of one of 0870's runs that `_iv_runs` does not repeat, which makes it print `Permission denied` to stderr, makes 0870 FAIL alone (`tests/run --part 0870-continued.sh`);
- (d) a discover that rewrites an existing stack.tsv makes 0580 alone and 1270 alone FAIL their names: 0580's "discovery writes nothing", and 1270's verdict on its re-run of it.

The report names each mutation, the FAIL it gave, and the passes (a) and (b) ask for.

**D8 gains:** 1291's groups case (1291:253-268, its ib and rx checks) also finds that the tree's own groups.tsv puts 0200 and 0201 in one group, gp, and 0810, 0820, 0830, 0840 and 0850 in one group, au. It is red against c8432b46's groups.tsv, which has neither.

### R41. D5, D8: what the suite leaves outside `$TMP`

Answers d5's outside list. Section 5 of d5-class.txt lists every entry made or removed directly under a root outside `$TMP` during the run, by part. The sweep found no file that two parts write outside `$TMP`, so no race (D8's "The class", its second candidate), and two leaks. R41 adds to D8's TMPDIR bullet and to D6's `$TMP` bullet.
- **(a) The blind parts' nested runs** (d5 outside 1292-1296).
  - **What was left.** 54 top-level `$TMP` directories of nested runs, in the host's temporary directory: 1292 left 6, 1293 34, 1294 3, 1295 5 and 1296 6, and 1291 none. Each one's files name the sweep's `$TMP`.
  - **Why.** A nested run's 0001 makes its `$TMP` with a template-less `mktemp -d` (0001:329), which on macOS ignores TMPDIR (0001:415). So it lands beside the suite's own, not below the case's fixture directory as D8's TMPDIR bullet meant, and only its own run's EXIT trap removes it (0001:352, 0003:795). A nested run ended by a signal that runs no trap, or a unit of it killed, leaves it where the case's cleanup, which removes only the case's own directory under `$DB/n`, cannot see it.
  - **The rule.** Every nested run that 1292 to 1296 start has a stand-in `mktemp` first on PATH. Given no template argument (only options, such as `-d`, `-u` or `-q`), it passes the same options and the template `"$TMPDIR/tmp.XXXXXXXXXX"` to the host's mktemp; otherwise it passes its arguments unchanged. It calls the host's mktemp through a variable holding the path `command -v mktemp` gave before the stand-in was put on PATH, and logs each path it made to a file of the case. The run's TMPDIR is the case's fixture directory, made absolute by R29 before 0001:329, so each nested `$TMP` is below the case's directory and goes with the case's cleanup.
  - **Not changed.** A case that tests where mktemp puts a run's `$TMP` keeps the mktemp it has: R5's relative-TMPDIR case and R29's own case, in 1294 (R29's case keeps its GNU-style stand-in, 1294:316-331). 1291's stand-in (1291:24), which logs each call and passes it on unchanged, stands, since 1291 left nothing.
  - **D8 gains:** each of 1292 to 1296 asserts, after its cases, that every path its stand-in logged is under the part's own case directories. It is red, on macOS, against a copy of the part whose stand-in passes every call on unchanged (R41 taken out): its nested runs' `$TMP`s are then in the host's temporary directory. Under GNU mktemp, which honours TMPDIR, that copy passes, so the red run is this Mac's.
- **(b) The unattended template's file** (d5 outside 0140, 0150).
  - **What was left.** 0140 and 0150 run templates/unattended.yml's "Verify and push" step, whose `named="$(mktemp)"` (templates/unattended.yml:371) is never removed: 11 files, 10 from 0140 and 1 from 0150.
  - **The rule.** 0140 runs the step in `_verify` (0140:223-226) and 0150 at 0150:87-89. Each runs it with a stand-in of (a)'s shape first on the step's PATH (`$VP/vbin`, 0140:225; `$UC/bin`, 0150:88) and TMPDIR naming a directory of the part's own under `$TMP`, so the file lands under `$TMP`. The stand-in logs each path it made to `$VP/mktemp.log` in 0140 and `$UC/mktemp.log` in 0150, so that the check below and the build name one file.
  - **D8 gains:** in 0140, after its last `_verify` (0140:320) and before its restore of the risk table (0140:340), and in 0150, after its run of the step (0150:87-89): the stand-in's log holds at least one path, and every path it holds is under `$TMP`. The first holds because the step reaches its `mktemp` (templates/unattended.yml:371) on at least one of 0140's runs and on 0150's: the sweep found 10 files of 0140's and 1 of 0150's (d5-class.txt section 5, 730-739; d5 outside, its first entry). The files this rule removes hold an implicated set or nothing, never the run's path, so no check that looks for the run's name sees them, and R41's trial below does not; this check does. It is red against c8432b46, where no stand-in writes the log, on macOS and on ubuntu alike. It is also red, on macOS, against a copy whose stand-in passes every call on unchanged while still logging what the host's mktemp gave (R41 (b)'s template taken out): the step's template-less `mktemp` then ignores TMPDIR (0001:415) and its file is in the host's temporary directory. Under GNU mktemp that copy passes, so that red run is this Mac's, as (a)'s is.
  - **The template** is not changed in D: on a CI runner its temporary file is the runner's, and templates/ is outside D ("Not in this", as R9 has it). The PR notes it for a change of its own.
- **(c) A unit ended by KILL.** 0007 knows a unit by its pid (with its start time, in `unit.I`, R15(b)), and the unit's `$TMP` is the one its own 0001 made, which only its own EXIT trap removes. A unit is sent KILL only by a stopper, at its steps 5 and 6 (R14, with R21), and only once it has outlived the stopper's TERM and its wait (step 3); a unit that ends on that TERM runs its EXIT trap. The parent runs a stopper over a unit in its ending, on INT, TERM, HUP or QUIT and in `_fx_exit` (D6's "Ending", R4's QUIT, R13), in its ending of a lost unit's holder (R4), and in its ending of a unit whose holder died (R15(b)); the holder runs one over its own unit when its wrapper or the `-j` parent is gone (R4, R15(a), R20). That is accepted residue, as a serial run ended by KILL leaves its `$TMP`: D6's bullet "**`$TMP`.** A unit ended by KILL may leave its own `$TMP`, as a serial run killed so does." stands.
- **(d) Recorded** (d5 outside engine, unknown, 0007, 0004, and others').
  - The engine's own `felix-status-index.*`, `felix-reach.*` and `felix-discover.*` entries are removed by their makers: lib/status.sh:218 makes the index copy, and :219 and :224 remove it; lib/reach-read.sh:176 makes its directory, which :238 and :247 make and remove through `felix_neutral_dir` and `felix_neutral_rm`; felix's EXIT traps (felix:3417 and 3504) remove the discover scratch made at felix:3419 and 3506.
  - The 61 `tmp.*` directories the sweep could not tie to itself, since none of them names its `$TMP`, are judged by the evidence trial below, after R41.
  - The slots directory did not change during the run, `_copy_content` writes nothing outside the suite, and the rest of the list is other sessions' and the machine's.
- **D8 gains, as evidence:** a hooked trial over 1291 to 1296, 0140 and 0150 on the tree this round lands, hooked as the sweep was, finds no entry left in the host's temporary directory that names the trial. Since the files (b) removes do not name it, the trial also lists, as section 5 of d5-class.txt tied those 11 files to 0140 and 0150, every `tmp.*` file made directly under the host's temporary directory within 0140's or 0150's time window, and finds none of the step's shape: empty, or holding one of the two parts' implicated sets (`src/a.txt`, `.github/workflows/gate.yml`, `src/café.txt`).

### R42. Round 5's review

Answers conf5 1 to 4 and proc5 1 and 2.
- **(a) `_copy_content` and a skipped name** (conf5 1). R42(a) adds to R37's rule.
  - **What fails.** In the writer at 0004:87-91, the loop's status (0004:88-90) is the status of its body's last command. For a skipped name, a tracked file deleted from the working tree (0004:69-74), that command is `{ [ -e "$f" ] || [ -L "$f" ]; } && printf`, which returns 1. When that name is the last one git lists, the writer fails under pipefail, and R37's build extracts nothing (0004:92), where the pipe it replaced extracted the rest. conf5 1 measured it on /bin/bash 3.2 with pipefail, on a checkout with files a and zz committed and zz removed: the pipe returned 1 with a copied, R37's build returned 1 with the destination empty. Callers that ignore the status then work on an empty tree: among them the widget fixture's own harness (0004:104), 0800:27, 1240:83, 1220:45, 1230:75, 0430:170, 270 and 472, 1402:50, 1090:44 and 0220:277.
  - **The rule.** A skipped name is no failure. The loop's body returns 0 for it, and `_copy_content` returns 0 and copies every other file.
  - **D8 gains:** with the last path git lists a tracked file deleted from the working tree, and pipefail set, `_copy_content` returns 0 and the destination holds every other file with the same bytes. It is red against c8432b46.
- **(b) The lint of R37 (b)** (conf5 2 and 3). R42(b) replaces R37 (b)'s scope, its "What it names", its "What it does not see" and its "On the tree", adds to its samples, and replaces the last line of R37's site list, "none in tests/lib, lib, bin or felix".
  - **Its scope** is every text file under engine/harness except tests/assertions.tsv, tests/red.tsv and tests/groups.tsv. So tests/run, tests/red, tests/receipt.sh and hooks/ are read, where R37's scope (parts, tests/lib, lib, bin and felix; 1296's `_db7_files`, 1296:758) left them out (conf5 3).
  - ***What it names.*** file:line wherever a `|` that is not half of `||` is followed by an extracting tar, or by a `(` or `{` group any of whose simple commands is an extracting tar.
    - An extracting tar is `tar`, after optional `command`, `env`, `nice` and `time` words, with an option word or cluster that holds `x`, or `--extract` or `--get`. An option word or cluster is a word after `tar` that starts with one dash and is not `-` alone (`-x`, `-xO`, `-xzf`), or tar's first word when it has no dash (`xf`, the old style); a long option other than `--extract` and `--get` (`--exclude=x`) is not one.
    - A group's simple commands are its text split at `&&`, `;`, `||` and line ends, up to the group's own `)` or `}`, read onto the lines that follow it as well: `| (cd "$d" && tar -xf -)` and `| { cd "$d"; tar -x; }` are named (conf5 2).
    - tar's options go on past a trailing backslash onto the lines that follow: `| tar -C "$d" \` followed by a line `    -x -f -` is named (conf5 2).
  - ***How it reads*** is R37's, unchanged, with the group and the backslash read onto later lines as above.
  - ***What it does not see*** is R37's list, unchanged: a VAR=value prefix, a wrapper given options of its own (`nice -n 15`), a tar named by its path or through a variable (as R37 (a)'s control is, on purpose), a pipe into a function that runs tar, and code built at run time with eval. The three shapes conf5 2 found are no longer in it, since the lint names them.
  - ***On the tree.*** On the tree this round lands it names lines of 1286 alone, 1286's control and the lines that describe it, and allows them by the part's name, so it reports nothing; R37 (a)'s control, through its variable, is not named, and no other line of the tree is, the files R42 adds to the scope included. The part that holds the lint holds no line the lint names, as R37 says.
  - ***Samples*** gain, flagged: `x | (cd "$d" && tar -xf -)`, `x | ( cd "$d" || exit 1; tar -x -f - )`, `x | { cd "$d"; tar -x; }`, a `(` group that opens on the pipe's line and holds `cd "$d"` and `tar -x -f -` on lines of their own, `x | tar -C "$d" \` with `    -x -f -` on the next line, and `x | tar -C "$d" \` with `    -f - \` and then `    -x` on the next two. Passed: `x | ( cd "$d" && tar -c -f - . )`, `x | { cd "$d"; tar -t; }`, `x | ( cd "$d" && cat ); tar -x -f a.tar`, and `x | tar -C "$d" \` with `    -c -f -` on the next line. The new flagged samples are red against c8432b46's matcher (1296:665-702), which named none of conf5 2's three under BWK awk or gawk 5.4.1.
  - **The site list's last line** reads: none in tests/lib, tests/run, tests/red, tests/receipt.sh, hooks, lib, bin, templates or felix.
- **(c) R39's section ends where the manifest block begins** (conf5 4). R42(c) replaces R39's "The section" bullet.
  - **The section** is the serial run's lines from `the record this run wrote` (run:442) up to, and not including, the first line the manifest block prints: `  FAIL  assertion did not run:` (run:469), `  ok    every assertion in the manifest was reached` (run:475), `  N assertion(s) in the manifest never ran` (run:476) or `  note  ` (run:478).
  - Every line of the manifest block stays compared, its FAIL lines included. A cut made at the manifest's ok line, or at the summary, would drop a serial run's manifest misses from the multiset, and a serial run that skipped assertions would compare equal.
  - This changes only the evidence's comparator (ev-compare.py), not the suite.
- **(d) 1292's D6 case: a wait a serial red's suite can meet** (proc5 2). R42(d) replaces R38's sub-bullet "before its TERM, the case also waits, 60 s at most, until red's suite has started its rrt children and holds".
  - **What fails.** The wait (1292:242's `_db2_rup`, called at 1292:578) needs both `rup.0010-sa.sh` and `rup.0020-sb.sh`. Against the base, red's suite runs serially: origin/main's tests/red runs tests/run with no `-j`, 0001:143 unsets `FELIX_TEST_RED_JOBS`, and `_db2_run` passes on neither `FELIX_TEST_JOBS` nor `FELIX_TEST_RED_JOBS` (1292:148-149). So red's suite holds in 0010-sa and never starts 0020-sb, `rup.0020-sb.sh` never appears, and the wait always runs its 60 s. The case's bounds then add up to 90 + 15 + 60 + 0.5 + 45 = 210.5 s (its two waits for the units, at 1292:578; this wait; its pause; `_db2_stop`'s 45 s, 1292:186-190), above its run bound `_db2_lim=150` (1292:577). Under load the record run can end 124, and the name fail on some runs, which is what R38 set out to remove.
  - **The rule.** The case waits for `rup.0010-sa.sh` alone, 60 s at most, then at most 5 s for `rup.0020-sb.sh`, which a `-j 2` red's suite on the branch writes. Its bounds then add up to 90 + 15 + 60 + 5 + 0.5 + 45 = 215.5 s, and its run bound is raised to 240 s so that they fit. Its name and its checks stand.
  - **D8 gains, as evidence:** three runs against a copy whose tests/red and tests/receipt.sh are origin/main's (`git show origin/main:<path>`) and three on the branch, D6's name passing on all six, with each run's wall time.
- **(e) 1295's R1 name** (proc5 1). 1295:281, "R1: and once that record run has exited no process of red's tree is left, stopped or running", is one of R38's 14 names, and round 5 did not build it: 1295 is not in 14b5ec35..c8432b46. It is built as R38 states, by the mechanism 1293's 13 cases have:
  - a red-only holder in the failing parts of the record copy (as 1293:18-52's hold.pl, run only where `FELIX_TEST_NO_MANIFEST=1`, only by the first to make the case's hold directory), before their seventh failure, with the record side's wait for its start file and its go file;
  - `DJX_HOLD`, given through `_db5_E` to the record run at 1295:279 alone, beside `DJX_ULIM`, with the run bound 1293 gives its holder runs (1293:191, 240 s);
  - the release file written in `_db5_run` (1295:86-89) as soon as `_db5_atexit` (1295:41) has listed, before `_db5_clean`, as 1293:112 writes it.
  - **D8 gains, as evidence:** three runs each way, as R38's D8 gains ask: the name fails on each run against origin/main's tests/red and tests/receipt.sh and passes on each run against the branch, with the largest go-to-end time against the branch (C's margin) and the part's time against both.
- **Recorded, with no change.** Both reviews' other findings, from their summaries:
  - proc5 ran 1292 and 1293 once, through onepart on the branch: ok 174, FAIL 0, 608 s at load about 6 to 14. All 13 of 1293's holder cases passed, and the longest time from the go file to the end of the holding step was 2,160 ms, so C = 10 s has its margin. Nothing was left in its run's process group. It did not show the 13 names failing against origin/main's tests/red and tests/receipt.sh; that is R38's D8 evidence, still owed with (d)'s and (e)'s. The builder's five batches did not include 1292, so proc5's run was the only one on the branch since 1292 changed; the next round's report runs it.
  - conf5 lifted 1296's matcher and ran it over the tree with BWK awk and gawk 5.4.1: on c8432b46 it names 1286:78, 81 and 88 alone, and on a 14b5ec35 tree those and R37's six sites. R37's stand-in case gave 141 on every run against the piped `_copy_content` and 0 against R37's build. 0430, 0440 and 0940 write their archives under `$TMP`, 1403's output is unchanged, and tests/run, tests/red, tests/receipt.sh and hooks/ hold no tar today. R39's line references matched 14b5ec35. Neither review had GNU tar; CI's run of the blind parts is where the stand-in case meets it.

### Every finding and cluster this revision answers, and where it went

Test fixes go to a blind author with this revision, before any code fix: R40's D8 gain in 1291, R41 (a) in 1292 to 1296, R41 (b)'s D8 gain in 0140 and 0150, R42 (a)'s case and (b)'s lint in 1296, R42 (d) in 1292 and R42 (e) in 1295. Code fixes go to the builders once the new blind tests are red: R40 (a) to (e), R41 (b)'s stand-ins and TMPDIR in 0140 and 0150, and R42 (a)'s `_copy_content`. R42 (c) changes the evidence's comparator, not the suite. The D8 evidence of R40, R41 and R42 (d) and (e) is made on the tree this round lands.

- d5 0201 (0201:308-311, `_gp_rec0`): R40 (a), group gp; evidence by a mutation of 0200; 1291 finds gp.
- d5 0850 (0850:182-197 over 0810 to 0840's audit runs): R40 (b), group au; evidence by a mutation of 0820, 0830 or 0840; 1291 finds au.
- d5 0880-0890 (IV_ERR, `Permission denied`, 0870's runs `_iv_runs` does not repeat): R40 (c), 0870:332's pattern; evidence by a mutation of one of those runs; no group.
- d5 0580, lines 341 and 343, and d5 1270 (widget's stack.tsv): R40 (d), the block writes the three rows when the file is absent and removes them after; evidence by a discover that rewrites the file.
- d5 0140, d5 0450 and d5 0580 line 274 (ev1 3's stray lines): R40 (e), guarded keeps and restores, and the directory made first.
- d5 0671, 0680, 0681, 0700 (whole-tree snapshots): recorded, judge the same (d5-verdicts-snapshots.json).
- d5 0940 (in ib), d5 9990 (D3's), d5 0780 with 0190:376 and :384 (0960's class), and every other cluster of d5-candidates.md: recorded; the PR lists each with its verdict.
- d5 outside 1292-1296 (54 nested `$TMP`s): R41 (a), the mktemp stand-in, with each part's check of its log.
- d5 outside 0140, 0150 (11 files from templates/unattended.yml:371): R41 (b), the stand-in and a TMPDIR under `$TMP`, with each part's check of its log, and the trial's listing of the two parts' windows; the template is outside D.
- A killed unit's `$TMP` (d5 outside 1292-1296's evidence): R41 (c), accepted residue under D6's `$TMP` bullet.
- d5 outside engine, unknown, 0007, 0004 and others': R41 (d), recorded; the 61 unattributed `tmp.*` go to the trial after R41.
- conf5 1 (minor, code): R42 (a), a skipped name is no failure, with its case.
- conf5 2 (minor, test): R42 (b), groups and backslash continuations named, with samples.
- conf5 3 (minor, contract): R42 (b), the lint's scope is every text file under engine/harness but the three tables, and the site list says so.
- conf5 4 (minor, contract): R42 (c), R39's section ends before the manifest block's first line.
- proc5 1 (major, contract): R42 (e), 1295's R1 name built with 1293's mechanism.
- proc5 2 (major, test): R42 (d), the wait for 0010-sa alone, then 5 s for 0020-sb, and a run bound of 240 s.
- proc5's and conf5's summaries: recorded under R42; R38's evidence against origin/main is still owed.

**Deliberately not taken:**
- d5 0880-0890's other remedy, group iv of 0860 to 0890: R40 (c) lets 0870 judge its own runs.
- d5 0580's and d5 1270's other remedy, a tests/lib builder for widget's stack.tsv that 0580 and 1270 both call: R40 (d) writes the rows inside the block, which 1270's cut carries.
- d5 0671's other remedy, the tree seeded before each snapshot: the third reader found every write the blocks reach keyed to the block's own project.
- d5 0780's optional remedy, awk read from a here-string or with no `exit`: no verdict is lost, as for 0960's class.
- d5 1280's hazard, 0330's variable LG renamed: no verdict is lost (d5-candidates.md).
- conf5 2's other remedy, the three shapes listed under "What it does not see": R42 (b) names them.
- conf5 3's narrower remedy, tests/run, tests/red, tests/receipt.sh and hooks/ named one by one: R42 (b) reads every text file but the three tables.
- conf5 4's other remedy, the section as the record judge's own names, listed in ev-compare.py: R42 (c) ends it at the manifest block's first line, which needs no list kept in step with `_rt_judge`.
