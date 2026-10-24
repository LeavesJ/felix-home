# Audit fix b01: time limits on suite, gate, CI and probe commands

The contract for batch b01 of the 2026-10-24 audit: C004 (high), C041 (medium) and C019 (low, mostly refuted). It is written for a blind test author. Every B item can be checked from outside, and section 4 gives each assertion its fixture. Branch `claude/audit-b01-time-limits-on-suite-gate-ci-and-probe-c`, from origin/main 69b51a61 (0.49.307). Where a skeptic corrected the audit, the correction is followed and named.

**The choice this contract makes.** Every shell that runs parts gets a *quiet limit*. When the run reaches no new assertion for Q seconds, it is ended and says which assertion it reached last. One rule covers a serial run (CI's), a part-mode run, each `-j` unit and red's suite. Two of the fix sketches proposed a wall deadline per unit taken from the durations file. That is not used, because unit wall time moves tenfold with load. Part 0010 took 136 s alone in C's sweep and 1377 s on a loaded 10-22. Part 1293 took 526 s on 10-23 and 1747 s on 10-22, in other checkouts' durations files. So a deadline taken from that file either ends healthy units on a loaded Mac or sits hours away, and it does nothing for the serial run CI makes. Part 0007, the runner, therefore does not change. Probe, `when`, witness, `applies` and evidence commands get a wall limit of their own in the engine. The CI job's cap is the founder's (section 7).

## Readings this rests on

- **bash 3.2.57, measured 2026-10-24.** `bash -c 'trap "…" EXIT; sleep 30'` sent TERM runs its EXIT trap and exits 143. The same holds while it is blocked opening a FIFO for `read`. Either way its foreground child is orphaned, not ended. bash 5 is CI's and is not on this Mac.
- **Process groups, measured 2026-10-24.** `set -m` in a non-interactive bash 3.2 gives a background job a process group of its own, and `kill -TERM -- -PGID` ends it and its children. A grandchild that keeps a command's stdout open holds `$( )` open until that grandchild exits: a 5 s grandchild cost 6 s. So a limit has to end the group, not only the command's own process.
- **The suite.** tests/run:41 `exec </dev/null`. A serial run sources each part into its own shell, with no bound (run:216-410). The `-j` holder polls its unit with no deadline (0007:112-118), and the parent loops until every unit ends (0007:808-819). The only time-based act is `_par_nt`, one stderr line about a slot wait (0007:728-737). The record tail calls `_rcp_red_end` with no seconds (run:438), so it waits for red while red lives (receipt.sh:486-497). The only bounded wait is the runner-failure path's 60 s (0007:823).
- **The ran file.** `_ran` appends one line per ok, FAIL or skip, in any subshell (run:61). The file is `$TMP/ran` (0001:462), or the unit's own `FELIX_TEST_PART_RAN` in part mode, which `_pm_start` switches to (0007).
- **Red** places this tree's run, parts, lib and groups.tsv into the base checkout (red:371-396), and keeps the base's receipt.sh and red. `_suite_copy_tree` copies `$HERE/receipt.sh`, `$HERE/red` and `$HERE/lib` (0003:882-885). A fixture built inside red's run therefore holds this tree's driver and tests/lib beside the base's receipt.sh and red.
- **Driver copies.** `_suite_copy_driver` copies hold no tests/lib (0003:832). Parts 1220, 1230 and 1240 run record runs in such copies with a stand-in red. Anything the driver's tail calls has to work there.
- **Callers of the probes** run under `set -uo pipefail` (felix:54, hooks/stop:28, hooks/pre-tool:18). Stop over a green tree runs every probe (stop:347, verify.sh:610, epoch.sh:120). The epoch hashes fields 1-6 of every probe row, the detail included (epoch.sh:118-121). A changed byte in any detail would move every receipt's epoch.
- **The engine runs no perl.** lib/*.sh only mention it. probes.sh:143-148 gives the lack of `timeout(1)` on macOS as the reason it has no limit.
- **CI.** gate.yml:37 and :66 set no `timeout-minutes`, so GitHub's 360 applies. The last 15 pull-request runs took 33.5 to 45.1 min. The longest of 200 runs since 10-01 took 54 min (C004's second verifier).
- **Sizes.**
  - tests/run is 497 lines, and part 1040 holds it to 500.
  - receipt.sh is 499 and tests/red 559.
  - 0007 is 835, 0001 is 462, lib/probes.sh 457 and lib/obligations.sh 389.

## 1. Defects

**C004 (high, kept high by both verifiers).** No layer bounds a hung test: a `-j` unit, a serial part, the record run's wait for red and the CI gate job all wait without limit, and nobody is told while they wait.
*Scenario, as corrected.* A part, or an assertion red runs on the base engine, blocks on a FIFO read, on a `wait` for a child that never exits, or on an unstubbed `gh` waiting for auth. It is not stdin (run:41 closes it), and not git's index.lock, where git fails at once. Locally, `felix gate` or `tests/run --record-assertions` stops printing for good: no FAIL, no ledger row, no notice. The hung unit keeps one of this user's slots, and its process keeps the land tick's deploy deferred. In CI the job runs until GitHub ends it at 360 min. That is reported then as timed out, at about 18% of the Free plan's 2,000 minutes. It has not happened yet: the 9 "in_progress" skip rows in the land ledger were ordinary runs.

**C041 (medium, as the verifier set it).** Probe, `when`, witness, obligation `applies` and evidence commands run with no time limit (probes.sh:143-148 says so). They run on the path of `felix gate`, `felix merge`'s blockers (escape.sh:643, 705, 743) and the Stop hook's epoch check.
*Scenario.* A project's probe imports its app (elenchus's `http_route`) or asks the network, as README.md:289 invites ("whether a route is deployed"), and stalls.
- `felix gate` and `felix merge` hang with no output.
- At Stop over a green tree, the hook runs until the host's hook timeout kills it. The stop then goes through with no hold and no verification.log row, against stop:25: "Everything unexpected allows and records."

Two corrections:
- The land tick is not stuck on this. Its 30-minute watchdog sends TERM and writes a notified `timeout` row (green-tick.sh:156-158, 175-190).
- Felix's own probes are local git, ls and sed commands, so the hang threatens other projects more than Felix.

**C019 (low; one verifier refuted it, the other kept it at low).** Nothing in the engine keeps the Mac awake or records that it slept.
*Scenario, as corrected.* What is left is narrow. On a laptop with no desktop app holding an idle-sleep assertion, a night can idle-sleep away and no Felix output says so. The 10-23 "9 h stall" was no sleep: pmset shows none in that window. Direction rows 16 and 24 already make landing conditional on an awake Mac. Most of the finding is in section 6, "Not fixed: not a defect".

## 2. Required behaviour

Terms used below:
- "Plain decimal" is one or more of the digits 0123456789, with the first not 0, and nothing else: no sign, no blank, no unit.
- "The run" is one `tests/run` process.
- "Its group" is the process group a test case starts it in.
- Rows are shown with `\t` for a tab.

### The quiet limit (C004)

**B1. Where it applies.** These runs have a quiet limit:
- a serial run: no `-j`, or `-j 1`;
- a part-mode run (`--part NAME...`), started by hand or as a `-j` unit;
- red's suite, which is this tree's tests/run.

These have none:
- a `-j N` parent with N above 1, which sources no part (each of its units has a limit of its own);
- a driver copy with no tests/lib beside it (`_suite_copy_driver`), which also prints nothing about one.

The limit runs from the end of the prelude (once tests/lib is loaded) to the line before part 9990 in a serial run, and to the start of part mode's ending in a part-mode run. The prelude itself (parts 0001-0007 and tests/lib) and part 9990 are not covered.

**B2. The rule.** The run is ended when its ran file grows by no byte for Q seconds. The ran file is `$TMP/ran`, or in part mode the unit's own ran file.
- Q is `FELIX_TEST_QUIET_LIMIT`, and 1800 when that is unset.
- Time is counted in polls about a second apart, so a stretch in which the run's processes are frozen (a sleeping Mac, SIGSTOP) counts as at most one poll.
- A run that keeps reaching assertions is never ended by this, however long it runs.

**B3. How a run is ended.** When the limit is reached:
- (a) This line is printed on the run's stdout, at the start of a line of its own (a newline goes before it). NAME is the ran file's last line, or `none` when the file is empty:
  ```
    FAIL  no new assertion in Q s, so the run was ended; the last it reached: NAME
  ```
- (b) No assertion line of the run (`  ok    `, `  FAIL  `, `  skip  `) follows it. The command that hung does not get to print a verdict of its own after being killed.
- (c) Every process below the run's shell is ended (in a record run, red's tree as well). Then the shell gets TERM, so its EXIT trap runs and its `$TMP` is removed.
- (d) The exit status is neither 0 nor 2. No `reached` line is printed and no receipt is left. A record run leaves assertions.tsv as it was.
- (e) The run exits within Q + 15 s of the last assertion it reached. Within 3 s after that, nothing of its group is left, stopped or running.

**B4. A shell that does not end on TERM.** If the shell is still there 10 s after the TERM (a part left TERM ignored), it is sent KILL. Just before that, this line is printed, PATH being the run's `$TMP`, which is then left behind:
```
  note  the run's shell did not end on TERM and was killed; its temporary directory is left: PATH
```
The exit status is neither 0 nor 2, and the run is gone within Q + 30 s of its last assertion.

**B5. Under `-j N`.** A unit ended by its quiet limit shows, in its section of the output, the B3 line. The runner's existing lines for a unit that died follow it: `  FAIL  part did not finish: MEMBER` for each member that had not finished, and `  FAIL  part ended without its mark: UNIT`. No new kind of runner failure is added. Then:
- the unit's slot is released, and the other units run to their end;
- the run exits 1, writes no receipt and leaves the durations file as it was (contract D, D4);
- part 9990 reports the unit as it reports any unit that left no end file.

**B6. Red leaves the B3 line out.** tests/red counts and names no line that begins `  FAIL  no new assertion in `, the same way it leaves out the runner's seven prefixes (red:472). A red.tsv never lists it as an assertion. Without this, a `-j` red run with a quiet-ended unit would write a non-assertion name into red.tsv, and the record judge (part 1010, "every assertion red.tsv names as red is one the manifest lists") would fail the record.

**B7. The two suite variables.** `FELIX_TEST_QUIET_LIMIT` and `FELIX_TEST_RED_WAIT` are each read where `FELIX_TEST_JOBS` is: in part 0001, before `$TMP` is made and before red starts.
- Unset, each takes its default.
- Set to anything else, even the empty string, it must be plain decimal from 1 to 86400. Otherwise the run exits 2 with exactly one line on stderr, makes no `$TMP`, starts nothing and leaves an existing receipt where it was:
  ```
  tests/run: FELIX_TEST_QUIET_LIMIT is [V]: it must be a number of seconds from 1 to 86400 in plain decimal
  ```
  For `FELIX_TEST_RED_WAIT` the line is the same with that name.
- Neither variable is unset by the run, so units, red and the fixture suites a part starts inherit it.

**B8. The watchdog that enforces it** is one perl process, as the runner's holder and ticker are. If it cannot be started (perl does not run, or does not come up), the run goes on as it did before this change, with no quiet limit. It says so in one line on stderr that begins `tests/run: this run has no quiet limit: ` and gives the reason.

**B9. What the limit leaves alone (controls).**
- A run that never goes quiet prints exactly what it prints today: no line of the watchdog's on stdout or stderr.
- It is no job of the run's shell. A part's `jobs -p` lists only that part's own jobs, and a part's bare `wait` waits only for them.
- It is gone before the run's shell exits whenever the run ends any other way than by B3 or B4. When the shell is killed from outside, the watchdog is gone within 2 s. After a run that ends normally, its group holds no live process at the first listing and 0.1 s later.

**B10. Frozen time does not count.** Consider a serial run whose whole group is stopped (SIGSTOP) for 3Q seconds while a part is between two assertions a second apart, and then continued. It is not ended, and it finishes as it would have.

### The record run's wait for red (C004)

**B11. A limit on the wait.** Once a record run's suite has written the manifest and its mark, it waits for red for at most W seconds.
- W is `FELIX_TEST_RED_WAIT` when set. Otherwise it is E + Q, where E is the seconds the record run has run when it starts to wait, and Q its quiet limit. Red's own suite goes quiet at most Q after its last assertion, so W leaves it that much and the record suite's own length again.
- When red is still running at W, its tree is ended by receipt.sh's existing stopper, and this line is printed before what red wrote:
  ```
    red stopped: still running after its limit of W s, so it was ended
  ```
- The record run's exit status stays its suite's. A red that could not finish still does not turn a green suite red: the record judge reads red.tsv's `-` rows, as it does today.

**B12.** The runner-failure path's 60-second bound (contract D, R1, 0007:823) prints the same line, `limit of 60 s`, when it is the one that ends red.

**B13. Control.** A red that ends within W is shown as today, with no `red stopped` line.

### Probe and obligation commands (C041)

**B14. The probe limit.** `FELIX_PROBE_LIMIT`, in seconds, covers each `when`, probe and witness command. That is every call of `felix_probe_state` and `felix_probes_run`, so it reaches `felix gate`, `felix merge`'s blockers, the Stop hook's epoch and `probes-check`. It also covers each obligation `applies` command.
- Unset or empty, it is 30.
- Otherwise it must be plain decimal from 1 to 3600 (B16 says what happens when it is not).
- 30, because one hanging probe then adds at most 30 s to a Stop. The host's hook timeout is not known: 600 s by the 10-19 mods round, 60 s by deny.sh:100's note of 09-23.

**B15. A command past its limit.** A command still running L seconds after it started is ended, together with every process in its process group: anything it started that did not make a group or a session of its own. The call then returns within L + 5 s.
- The limit covers the command's output as well. A command whose own process has exited while something it left holds its stdout open past L counts as past its limit.
- The rows read as follows, and nothing after the command that was ended is run:
  ```
  when:     unknown\t0\tthe `when` command ran past its limit of L s and was ended, so whether this row applies is not known
  probe:    unknown\t0\tthe probe ran past its limit of L s and was ended, so its enumeration is not known
  witness:  unknown\t0\tthe witness ran past its limit of L s and was ended, so absent and blind cannot be told apart
  applies:  UNKNOWN\tUNKNOWN\tthe applies command ran past its limit of L s and was ended, so whether this applies is not known
  ```
  So the probe is not run behind a `when` that was ended, the witness is not run behind a probe that was ended, and the evidence is not run behind an `applies` that was ended.
- A probe that printed members and then hung reads as the probe row above (count 0).
- Each such row blocks: `felix_probes_blocking`, `felix_obligations_blocking` and `felix_merge_blockers` list it, as they list every `unknown` or `UNKNOWN`.

**B16. A bad `FELIX_PROBE_LIMIT`.** If the variable is set to anything else, nothing of the row is run (not even its `when`), and its value is never echoed into a row. Every probe row reads:
```
unknown\t0\tFELIX_PROBE_LIMIT is set to something that is not a whole number of seconds from 1 to 3600, so nothing was run
```
Every obligation with an `applies` command reads `UNKNOWN\tUNKNOWN\t` followed by the same sentence.

**B17. The evidence limit.** `FELIX_EVIDENCE_LIMIT` covers each obligation evidence command.
- Unset or empty, it is 300. Otherwise it must be plain decimal from 1 to 3600.
- Evidence past its limit is ended as in B15, and its row reads `ACTIVE\tUNKNOWN\tthe evidence ran past its limit of L s and was ended, so nothing was examined`.
- With a bad value the evidence is not run, and the row reads `ACTIVE\tUNKNOWN\tFELIX_EVIDENCE_LIMIT is set to something that is not a whole number of seconds from 1 to 3600, so the evidence was not run`.

**B18. Unchanged for every command that ends in time (controls).**
- State, count and detail are byte for byte as today, whatever the exit status: 0, 1, 2, 3, 124, 127, 128, 137, 142, 143, or death by a real TERM.
- stdin is still /dev/null.
- `felix_probes_run`'s fields 1-6, and with them `felix_epoch_topology`, are what they are today, so no receipt's epoch moves because of this change.

**B19. What the bound costs and needs.**
- It waits for nothing once the command has ended. A ten-row table whose commands end at once returns in under 5 s.
- No process it started outlives the call by more than 2 s.
- It prints nothing on stdout or stderr of its own.
- It works under the callers' `set -uo pipefail`, and it leaves the calling shell's options, traps and job table as they were.
- It needs only bash and the commands every supported machine has (sleep, kill, ps): no perl, python or `timeout(1)`. Apple has said scripting runtimes will leave macOS, and a minimal Linux image may lack perl. A file it makes is made under `$TMPDIR` with a template (part 1000).

**B20. The epoch at Stop.** For a project with one probe that hangs, `felix_epoch_topology` returns within L + 10 s. Its value is not empty, and it differs from the value the same table gives when that probe answers. So `felix_verify_current` reads `stale`, and the Stop hook holds once, as it does for any moved epoch, instead of running until the host kills it.

### Sizes (all)

**B21.**
- tests/run stays at 500 lines or fewer (part 1040), and grows by at most three: the two part lines and one tests/lib line. Every other change to it is made in place.
- 0007 gets no longer than 835 lines, receipt.sh than 500 and tests/red than 559. Any change to those is made in place.
- lib/probes.sh, lib/obligations.sh and part 0001 stay under 500.
- A new tests/lib file defines functions only (part 0006's judges) and stays under 500.

## 3. What must not change

- **Runs that never go quiet.** Their output, counts, exit status, receipt, durations file and red.tsv stay as they are. Pinned by:
  - 1200-gate-friction-a-blind.sh, 1210-gate-friction-a-blind.sh, 1220-gate-friction-a-blind.sh;
  - 1230-gate-friction-a-addendum-blind.sh, 1230-gate-friction-a-blind.sh, 1240-gate-friction-a-survivors-blind.sh;
  - 1250-gate-friction-a2-blind.sh, 1260-gate-friction-a3-blind.sh, 1270-gate-friction-b-blind.sh, 1290-gate-friction-c-blind.sh;
  - 1291-gate-friction-d-blind.sh through 1296-gate-friction-d-losses-blind.sh;
  - 0770-red-the-recorded-red-run.sh and 1010-the-record-this-branch-carries.sh.
- **The driver's shape** (1040-the-suite-is-cut-into-parts.sh, 1290-gate-friction-c-blind.sh, 0006-the-lib-judges.sh, 0770-red-the-recorded-red-run.sh):
  - parts and tests/lib files sourced one to a line, in name order;
  - `printf '\nreached\n'` exactly as it is, since red reads that line;
  - the tail's text, and the 500-line cap.
- **The `-j` runner, unchanged** (1291 to 1296):
  - its seven runner-failure lines and their prefixes;
  - slot waits with no limit and R6's single stderr note (contract D, R5 and R6);
  - the holder, the ticker and the stoppers;
  - durations written only by a run with no runner failure (D4).
- **Driver copies with no tests/lib.** They run, and print, as today, record runs with stand-in reds included: 1220-gate-friction-a-blind.sh, 1230-gate-friction-a-addendum-blind.sh, 1240-gate-friction-a-survivors-blind.sh and 1260-gate-friction-a3-blind.sh.
- **Jobs and waits a part makes** see no new job:
  - the `jobs -p` snapshots in 0050-appends-that-fail-paths-that-are-not-files-a.sh, 0060-a-partial-backfill-a-pipe-at-a-table-and-a-m.sh, 1020-readers-keep-the-unended-last-line-of-a-hand.sh and 1030-a-pipe-at-stack-tsv-read-by-the-stop-hook-in.sh;
  - the bare `wait` in 0150-the-unattended-repair-leaves-the-model-no-cr.sh, 0330-one-rollup-one-file.sh and 1240-gate-friction-a-survivors-blind.sh.
- **Part mode's shell comparison** (R8, R16) sees nothing the watchdog does: 1295-gate-friction-d-shell-blind.sh.
- **The EXIT trap and signal dispositions.** The trap acts only in its owner's shell, and INT and QUIT reach children as before: 0575-the-suite-s-exit-trap-acts-only-in-its-own-shell.sh, 0573-the-autonomy-file-has-one-writer-at-a-time.sh, 0574-revoke-then-allow-on-a-last-line-with-no-new.sh and 1292-gate-friction-d-signals-blind.sh.
- **Red's counts, refusals and `-` rows**, and the 60-second path's timing (R1, R32): 0770-red-the-recorded-red-run.sh and 1293-gate-friction-d-runner-failures-blind.sh.
- **Every probe and obligation reading for a command that ends in time**, closed stdin included (the `cat` row reads blind and does not hang):
  - 0390-probes-what-reality-says-and-the-difference.sh, 0400-candidates-what-a-model-proposed-and-nothing.sh, 0410-an-answer-that-is-neither-yes-nor-no.sh;
  - 0420-obligations-what-would-discharge-each-by-nam.sh, 0511-the-deployed-engine-probe-a-cache-prune-is-n.sh;
  - the callers in 0681-continued.sh, 0710-commissioning-a-seeded-check-reads-done-only.sh, 0780-exceptions-the-scoped-exception-channel.sh, 0994-bash-s-own-collation-and-the-bsd-text-tools.sh and 0996-continued.sh.
- **The epoch.** A receipt's epoch does not move because of this change: 0510-the-receipt-carries-the-epoch-and-a-fact-tha.sh and 0750-decision-epochs-the-four-things-a-decision-w.sh.
- **Engine scratch.** It is made under TMPDIR by a template: 1000-the-engine-makes-its-scratch-under-tmpdir.sh.
- **The founder PR keeps every `uses:` pinned** to a commit: 0160-unattended-readiness.sh.

## 4. Assertions

Every inner run, and every probe or obligation call that could hang, runs under the case's own bounded runner, as part 1291's `run.pl` does: fork; the child calls `setpgrp` and execs; the parent sets `alarm T` and on the alarm sends KILL to the group and exits 124. So against an engine without the fix, an assertion fails at T and does not hang. Every case points TMPDIR at a directory of its own, ends nothing by pattern (it signals by pid or group id), and finally checks that its groups hold no live process.

A suite fixture is `_suite_copy_tree` (part 0003): a checkout F of the suite in small, with planted parts numbered 0010 or later. Each planted part first writes `"$TMP"` to a file of the case. The planted parts are:
- **q-hang:** `ok "djx q1"; sleep 300`
- **q-steady:** `ok "djx s$i"` once a second, for the number of seconds the case gives
- **q-wait:** `sleep 1 & wait; ok "djx w1"`, which also writes `jobs -p | wc -l`, taken before its own `&`, to a case file
- **q-ignore:** `trap '' TERM; ok "djx i1"; sleep 300`
- **fast:** ten `ok "djx fN"` lines

A probe fixture is a checkout R, made with part 0002's fixture git helpers, that tracks `a.txt` and `b.txt`. Calls go through a subshell that sources the harness's lib/resolve.sh, detect.sh, probes.sh and obligations.sh, as tests/lib/probes.sh's `_ob` does.
- A **marker** command is `perl -e 'sleep 300' fx-p-X-$$`, so that `ps -A -o command=` can find it, and its fork variant is `perl -e 'fork; sleep 300' fx-p-X-$$`.
- A **ran-marker** is `touch "$C/NAME.ran"`, so the case can tell whether that command ran.

Assertions marked **(control)** pass before the fix and after it.

### Part 1630 (the suite)

- **A1 (B3).** Serial, Q=5, q-hang, T=60. The run exits within 25 s, with a status that is neither 0 nor 2.
- **A2 (B3).** In that run, stdout holds the line `  FAIL  no new assertion in 5 s, so the run was ended; the last it reached: djx q1` exactly once. It is the last line beginning `  ok    `, `  FAIL  ` or `  skip  `, and no line reads `reached`.
- **A3 (B3).** In that run, no receipt is left at F's `git rev-parse --git-path felix-suite-receipt`, and the `$TMP` path the part wrote no longer exists.
- **A4 (B3).** Within 3 s of that run's exit, its group holds no live process.
- **A5 (B1).** `tests/run --part 0010-q-hang.sh` by hand, Q=5. The A2 line is printed, the exit status is neither 0 nor 2, and the run exits within 25 s.
- **A6 (B5).** `-j 2`, Q=5, units 0010 (q-hang) and 0020 (fast), T=90. The run exits 1 within 45 s, and 0010's section holds the A2 line followed by `  FAIL  part did not finish: 0010-q-hang.sh` and `  FAIL  part ended without its mark: 0010-q-hang.sh`. All ten of 0020's `ok` lines are printed, and no receipt is left.
  - **(control)** A durations file planted at F's git-path with two rows is byte for byte unchanged.
  - **(control)** No file under the case's `TMPDIR/felix-suite-slots` is locked after the run.
  - **(control)** The group is empty within 3 s.
- **A7 (B2, B9; control).** Serial, Q=3, q-steady for 12 s. The run exits 0, prints `reached` and no line beginning `  FAIL  no new assertion in `, and prints nothing on stderr that a run with the variable unset does not.
- **A8 (B2; control).** As A7 under `-j 2`, with q-steady and fast as two units.
- **A9 (B9; control).** Serial, q-wait. The run exits 0 within 15 s, and the count q-wait wrote is 0.
- **A10 (B9; control).** Serial, fast. At the first listing after the run's exit, and 0.1 s later, its group holds no live process.
- **A11 (B10; control: a wall-clock watchdog fails it).** Serial, Q=5, q-steady for 15 s. Once three `djx s` lines are out, the case sends STOP to the run's group, waits 20 s and sends CONT. The run exits 0, prints `reached`, and prints no `no new assertion` line.
- **A12 (B4).** Serial, Q=5, q-ignore, T=90. The run exits within 40 s, with a status that is neither 0 nor 2. It prints `  note  the run's shell did not end on TERM and was killed; its temporary directory is left: P`, where P is the path the part wrote and still exists (the case then removes it). The group is empty within 3 s.
- **A13 (B7).** Each of these exits 2 with exactly one stderr line, the B7 line with V filled in, and no `mktemp` call (a mktemp first on PATH that writes down its calls, as part 1291 does). A receipt planted at F's git-path is unchanged.
  - `FELIX_TEST_QUIET_LIMIT` set to each of `''`, `0`, `07`, `86401`, `5s`, `-1`, `' 5'` and `+5`;
  - `FELIX_TEST_RED_WAIT` set to `0` and to `''`.
- **A14 (B8).** Serial, fast, with a directory first on PATH whose `perl` exits 1. The run exits 0 and prints `reached`, and its stderr holds a line beginning `tests/run: this run has no quiet limit: `.
- **A15 (B6).** In F, `FELIX_TEST_RED_JOBS=2 FELIX_TEST_QUIET_LIMIT=5 tests/red` by hand, T=180. The fixture is set up as follows:
  - Part 0010 is `ok "djx q1"; [ "${FELIX_TEST_NO_MANIFEST:-}" != 1 ] || sleep 300; ok "djx q2"`, and 0020 is fast.
  - assertions.tsv lists `djx q1`, `djx q2` and `djx f1` to `djx f10`, once each.

  Red exits 0. Its red.tsv has a row for `djx q2` with 1 failure, and no row whose name begins `no new assertion in `.
- **A16 (B6; control).** No name in this tree's assertions.tsv begins with `no new assertion in `.
- **A17 (B11).** A serial record run in F with `FELIX_TEST_RED_WAIT=5`, T=120, and a stand-in tests/red. The stand-in writes its pid, starts `sleep 600` in a child and waits for it. The run exits 0 within 60 s of its start and prints `  red stopped: still running after its limit of 5 s, so it was ended`. The stand-in's pid and its child are gone within 3 s of the exit.
- **A18 (B13; control).** As A17, with a stand-in that prints `red: stand-in` and exits 0 at once. The output holds `  red: stand-in` and no `red stopped` line, and the run exits 0.
- **A19 (B12).** A `-j 2` record run in F, T=180, with a stand-in red that ignores its mark and sleeps 600 in a child. Part 0010 leaves `umask 077` set, which is the seventh runner failure, and 0020 is fast. The run exits 1 within 110 s and prints `  red stopped: still running after its limit of 60 s, so it was ended`, and the stand-in's tree is gone within 3 s.
- **A20 (B21; control).** The line counts hold:
  - tests/run is at most 500;
  - tests/red is at most 559, and receipt.sh at most 500;
  - 0007 is at most 835;
  - lib/probes.sh, lib/obligations.sh and 0001 are each under 500.

### Part 1640 (probes and obligations)

Where T is not given below, it is 20.

- **A21 (B15, B19).** `FELIX_PROBE_LIMIT=2`, in a shell under `set -uo pipefail`. `felix_probe_state R - "<marker A>" "<ran-marker wit>"` returns within 7 s and prints exactly `unknown\t0\tthe probe ran past its limit of 2 s and was ended, so its enumeration is not known`. It prints nothing on stderr, and wit.ran does not exist. Within 2 s no process carries marker A, and the shell's `set +o`, `trap -p` and `jobs -p` read as they did before the call.
- **A22 (B15).** `felix_probe_state R "<marker B>" "<ran-marker probe>; echo x" "test -d ."` gives the `when` row with L 2 within 7 s, and probe.ran does not exist.
- **A23 (B15).** Probe `true`, witness `<marker C>`. The witness row with L 2 comes back within 7 s.
- **A24 (B15).** Probe `echo member; <fork marker D>`. The probe row (count 0) comes back within 7 s, and within 2 s no process carries marker D, neither parent nor child.
- **A25 (B15).** Probe `perl -e 'if (fork) { print "m\n"; exit 0 } sleep 300' fx-p-E-$$`, so the probe's own process has gone and its child holds stdout. The probe row comes back within 7 s, and no fx-p-E process is left within 2 s.
- **A26 (B15).** A probes.tsv with a hanging row `hang` and a found row `files` (`git ls-files`, witness `test -e .git`). `felix_probes_run | felix_probes_blocking` lists exactly the predicate `hang`, within 10 s.
- **A27 (B14).** `FELIX_PROBE_LIMIT` unset, probe `sleep 40; echo x`, T=60. The call returns after at least 25 s and within 38 s, and the detail names `30 s`.
- **A28 (B14; control).** `FELIX_PROBE_LIMIT=''`, probe `echo x`, witness `test -d .`. The row is `found\t1\t1 member(s) enumerated`.
- **A29 (B16).** `FELIX_PROBE_LIMIT` set to each of `0`, `07`, `3601`, `abc`, `1.5`, `-1` and `'2 '`. `felix_probe_state R "<ran-marker when>" "<ran-marker probe>; echo x" "<ran-marker wit>"` prints exactly the B16 row, and none of when.ran, probe.ran or wit.ran exists.
- **A30 (B15).** `FELIX_PROBE_LIMIT=2`. `felix_obligation_state R "<marker F>" "<ran-marker ev>"` prints exactly the `applies` row with L 2 within 7 s, and ev.ran does not exist.
- **A31 (B15).** An obligations.tsv with one RELEASE_BLOCKING row whose `applies` is a marker. `felix_obligations_run … release | felix_obligations_blocking release` lists that row with `UNKNOWN`, within 10 s.
- **A32 (B16).** `FELIX_PROBE_LIMIT=abc`, `applies` set to `<ran-marker ap>`. The row is `UNKNOWN\tUNKNOWN\t` followed by the B16 sentence, and ap.ran does not exist.
- **A33 (B17).** `FELIX_EVIDENCE_LIMIT=2`, `applies -`, evidence `<marker G>`. The row is exactly `ACTIVE\tUNKNOWN\tthe evidence ran past its limit of 2 s and was ended, so nothing was examined`, it comes back within 7 s, and no G process is left within 2 s.
- **A34 (B17).** `FELIX_EVIDENCE_LIMIT=0`, evidence `<ran-marker ev>`. The row is exactly the B17 bad-value row, and ev.ran does not exist.
- **A35 (B18; control).** `FELIX_PROBE_LIMIT=5`, witness `test -d .`:
  - `exit N` for N in 1, 2, 3, 124, 128, 137, 142 and 143 gives `blind\t0\tthe witness proves this surface exists and the probe exited N`;
  - `kill -TERM $$` gives the same row with 143;
  - `exit 127` gives `unknown\t0\ta command in the probe does not exist here, so nothing could be looked at`;
  - `true` gives `blind\t0\tthe witness proves this surface exists and the probe enumerated none of it`;
  - `echo m` gives `found\t1\t1 member(s) enumerated`;
  - `echo m; exit 3` gives `unknown\t1\tthe probe printed 1 member(s) and then exited 3, so the enumeration is partial`.
- **A36 (B18; control).** Probe `cat`, witness `test -d .`. The blind "enumerated none of it" row comes back within 5 s.
- **A37 (B18; control).** For this table in R:
  ```
  files\t-\t-\tgit ls-files\ttest -e .git
  rust\t-\t-\tgit ls-files "*.rs"\ttest -f Cargo.toml
  cargo\t-\ttest -f Cargo.toml\tls\ttest -d .
  ```
  `felix_probes_run | cut -f1-6` prints exactly:
  ```
  files\t-\tfound\t2\t2 member(s) enumerated\tgit ls-files
  rust\t-\tempty\t0\tthe probe found nothing and the witness agrees the surface is absent\tgit ls-files "*.rs"
  cargo\t-\tnot-applicable\t0\tthe `when` command says this does not apply here\tls
  ```
- **A38 (B19; control).** `FELIX_PROBE_LIMIT=2917`, a table of ten rows with probe `echo m` and witness `test -d .`. `felix_probes_run` returns within 5 s with nothing on stderr, and within 2 s no process has the command line `sleep 2917`.
- **A39 (B19).** With a directory first on PATH whose `perl`, `python3`, `timeout` and `gtimeout` exit 1, a probe `sh -c 'sleep 300; :' fx-p-H-$$` with `FELIX_PROBE_LIMIT=2` still gives the probe row within 7 s, and no fx-p-H process is left within 2 s. (The case's own runner is started by the real perl, outside that PATH.)
- **A40 (B20).** A project whose probes.tsv has one row, `slow\t-\t-\t"$C/maybe"\ttest -d .`. `$C/maybe` prints `m`, unless the file `$C/hang` exists, in which case it runs a marker. Run `felix_epoch_topology` with `FELIX_PROBE_LIMIT=2`, first without `$C/hang` (value T1), then with it (value T2). The second call returns within 12 s, and T2 is not empty and differs from T1.

**Not asserted, and why.**
- The defaults Q = 1800, W = E + Q and an evidence limit of 300 each show only after 30 minutes or more. The overrides assert the mechanism (A1, A17, A33), and A27 asserts the probe default.
- B5's 9990 lines are contract D's for any unit with no end file, and part 1293 pins them.

## 5. Parts

- **`engine/harness/tests/parts/1630-suite-time-limits-blind.sh`:** A1 to A20.
- **`engine/harness/tests/parts/1640-probe-time-limits-blind.sh`:** A21 to A40.

Each is sourced by one driver line, after 1600's, and each stays under 500 lines. Both follow the known traps: no `case` inside `$( )`, digits spelled out in brackets, `LC_ALL=C` for sort and comparisons, no associative arrays, no gawk-only builtins, and `$(( ))` quoted.

**Red, plainly.** tests/red puts this tree's run, parts and lib into the base. So the quiet-limit assertions (A1 to A14) pass in red against the base engine, because the watchdog they test is this tree's tests/lib. Their red-first evidence is therefore a run of 1630 on the commit that adds it, before the build, where each fails at its bound T. The assertions on receipt.sh and tests/red (A15, A17, A19) and on the engine lib (A21 to A27, A29 to A34, A39, A40) do show red in tests/red. The record (assertions.tsv, red.tsv) and the version are the session's, after the build.

## 6. Out of scope

- **projects/felix/gate.sh: printing the suite log's path before the run, and a heartbeat.** gate.sh is batch b08's file. The gate keeps the log private until the run ends (gate.sh:322, 363), so a heartbeat in the log would reach nobody until that changes. This batch bounds the silence instead: a hung unit fails within Q of its last assertion, and the gate then prints its FAIL lines. The change to make there: print `full log: PATH` before the run as well as after a failure.
- **`felix gate` running other projects' gates unbounded** (felix:770-786). The CLI is batch b13's file. A governed project's gate is that project's own command, and how long it may take is the project's decision, so a limit on it needs a per-project budget. Felix's own gate is bounded inside, by B2 and B14.
- **`timeout` keys in engine/hooks/hooks.json, and a total budget for the Stop hook with a record when it is spent.** hooks.json is batch b16's file and hooks/stop is b07's (C102's start-line design). This batch makes each probe finite: one that hangs adds at most 30 s to a Stop, and the Stop then holds (B20). Several hanging probes still add 30 s each.
- **verify.sh's wording for a probe that was cut off.** It says "the grounded facts moved since the receipt", which overstates what happened. verify.sh is batch b08's file. Suggested wording: "a grounded fact could not be read within its limit; run felix gate".
- **The qualification columns** (qualify-run.sh:412-414). They run only under `felix qualify`, never on the gate, merge or Stop path. They run a project's checks against mutants, so they take as long as those checks do. A limit there needs a per-row budget, which is a new table column, and a new table column is the founder's.
- **Slot waits stay unbounded** (contract D, R5). A unit waiting on a slot held by another session's hung unit, under an engine without this fix, waits until that run is ended.
- **The prelude and part 9990** are outside the quiet limit (B1). A `-j` unit that hangs in parts 0001-0007 is not ended. They write fixtures and copy the harness.
- **A process that leaves the run's tree or its process group** (`setsid`, a double fork) is found by neither bound.
- **A per-project probe limit** (a project.json key). The limits are environment variables, and the Stop hook inherits the host's environment, so a project whose probe needs more than 30 s has nowhere to say so yet.
- **The stuck-PR page naming a check that runs past its timeout** belongs to the pr-status files, batch b03.
- **C019's remainder: keep-awake and a sleep marker.** It is low severity. The files involved are felix (b13), green-tick.sh (b02) and overnight.sh. `caffeinate -i` would not have stopped the sleeps this Mac has, which are clamshell sleeps, and the desktop app already holds an idle-sleep assertion through each turn. This batch keeps its own new bounds safe from sleep where a false end would cost a whole run (B10). The red wait and the probe limit count wall time: a Mac that sleeps past them ends red, which the record judge then reports, or reads a probe as unknown and holds once. Both are said, and neither is silent.

### Not fixed: not a defect

- **C004: "a part that waits on stdin hangs".** It cannot: tests/run:41 runs `exec </dev/null`, and probes pass `</dev/null` (probes.sh:177, 272).
- **C004: "a fixture blocks on git's index lock".** git does not wait on index.lock; it fails at once.
- **C004: "in CI no failure is ever reported".** GitHub ends the job at 360 min, and pr-status-gh.sh:102 reads TIMED_OUT, CANCELLED and FAILURE as red. The cost is the six hours, which section 7 caps.
- **C004: "9 in_progress ledger rows" as evidence of stalls.** They were ordinary runs. #460's took 33 min and landed, and none of 200 runs since 10-01 went past 54 min.
- **C004: "slots are machine-wide".** They live under the per-user TMPDIR (0007, `_par_slots`), so they are shared by this user's sessions, not by the machine.
- **C041: "the land tick holds its lock until the 45-minute stuck row".** Its 30-minute watchdog sends TERM to the tick and its children and writes a notified `timeout` row (green-tick.sh:52, 156-158, 175-190).
- **C019: "direction row 16 assumes the Mac is kept awake".** Row 16 (direction.md:161) is a founder condition that says "A sleeping Mac lands nothing". Row 24 (direction.md:169) says the same, and the land-on-green contract's "Not in this" list puts waking a sleeping Mac out of scope (2026-10-15-land-on-green-contract.md:510). No document claims Felix keeps the Mac awake.
- **C019: "gate timing and cost numbers read 9 h as gate time".** cmd_gate, tests/run and gate.sh record no duration. The `-j` durations file (0007's `_par_fin`) counts wall time but only orders units. `felix cost` counts tokens, and a sleeping Mac spends none.
- **C019: "the 9 h 13 min stall was the Mac asleep".** pmset shows no sleep from 2026-10-22 22:06 to 10-23 13:33 PDT, the display stayed on, and the Claude app held its idle-sleep assertion. That stall had another cause, and keep-awake would not have prevented it.
- **C019: "sleep spends the night's grant".** The deadline is wall time on purpose (overnight.sh:38-39): a grant is a window of permission, not a quota of work.

## 7. Founder PR

`.github/workflows/gate.yml` gives each job a time limit. That is an execute escape, so the founder merges it, and the session lands it separately. This batch neither depends on it nor asserts it, since an assertion on the file would stay red until it merges. Every `uses:` line stays as it is (part 0160).

```diff
   reuse:
     if: github.event_name == 'push'
     runs-on: ubuntu-latest
+    # A reuse that cannot answer in ten minutes names no run, and the gate runs.
+    timeout-minutes: 10
     permissions:
       contents: read
@@
   gate:
     needs: reuse
     # Every pull_request run skips reuse, and a reuse that failed names no
     # run, so both reach the gate. Only a named run keeps it from running.
     if: ${{ !cancelled() && needs.reuse.outputs.run == '' }}
     runs-on: ubuntu-latest
+    # GitHub's default is 360 minutes. The longest of the 200 gate runs since
+    # 2026-10-01 took 54, and the 15 pull-request runs before 10-24 took 33.5
+    # to 45.1. A hang inside the suite ends sooner, at its quiet limit (30
+    # minutes with no new assertion); this ends one outside it.
+    timeout-minutes: 90
     steps:
```

When the reuse job times out it names no run, and the gate job's `if` still runs it. A gate job that times out concludes red on the stuck-PR page and to the land tick (pr-status-gh.sh:102). No deny row, escape row, commission grant or publishing is needed.
