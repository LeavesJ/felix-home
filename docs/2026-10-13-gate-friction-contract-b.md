# Contract B: the slow assertions, and `qualified` rows in parallel

Step 2 of docs/2026-10-12-gate-friction-design.md (section 4), its own pull
request, engine tier. Built on main d36ec648 (A and A3 landed as 0.49.284 and
0.49.285, #434 as 0.49.286). Version: the next free one when it records.

The design's rule binds every item: weaken no check, and show each change by
the assertion's own verdict on the old and the new code.

## Split after review, 2026-10-14

B1 and B2 land in this PR as 0.49.289. B3 is cut and goes back to its contract
as a PR of its own (branch claude/gf-b3 holds the first build, a06ae3a3). The
second Opus review reproduced five blocking defects in it. Four are the loop's
signal and fork windows, and the job count read from a zero-padded value. The
fifth is the design itself: rows running at once share the repository's
`.git/worktrees`, and while one row adds or removes its worktree, a column's
`git worktree list`, `git branch` or checkout in another row fails with 128.
Such a failure can turn a verdict, and weakening a check is what this design
forbids. B3's revised contract must keep every column's git reads off a
worktree list that is changing: for example, add a batch's worktrees one at a
time, run its columns, then remove them one at a time.

Review findings on B1, fixed here: part 1270's positive-control check passed
for any extra assertion (it now also requires that control to fail when
widget declares nothing a rule names), and the control in 0580 did not check
that the decoy entry is absent (it does now).

## What decided the list

One instrumented whole-suite run on main d36ec648, 2026-10-13, in a clone,
load 30 to 165 (audits/2026-10-12-gate-friction/timeall.sh and profsum.py,
under the memory root). After the prelude, `_ran` also appended `$SECONDS`, the
assertion's name and bash's `times` (no forks), so each assertion's CPU is the
growth of the shell's and its children's CPU since the one before it.

- 8391 assertions, 2135 s of CPU, 2649 s of wall.
- **One assertion is 24% of the suite:** "discovery writes nothing", part 0580,
  516 s of CPU and 418 s of wall.
- The first assertion, "felix new exits 0", carries 72 s: the driver's prelude
  and part 0010 up to it. That is step 3's concern (every part process would
  pay a prelude), not this one's.
- After those two, no assertion takes more than 31 s, and the ones above 15 s
  are runs of a whole command that the assertion is about (inventory A1, the
  26,000-runner deny-hook cost check, a commissioning run). They stay.

So B is three items: B1 below (CPU), B2 (wall, no CPU), B3 (the gate's
`qualified`, 125 s on 2026-10-10). The 2026-10-10 names "inventory blind
contract, 177 s" and "commissioning, 111 s" are spread over hundreds of
assertions with no single cost to cut; they are not in B, and that is said in
the PR.

## B1. Discovery's no-write check runs against a catalogue the suite owns

**Today.** Part 0580, block "It recommends. It must never acquire.":

    before="$(cksum < "$FROOT/projects/widget/stack.tsv")"
    out="$(cd "$REPO" && "$FELIX" discover 2>&1)"; rc=$?
    after=...;  is "discovery writes nothing" "$after" "$before"
    out="$(cd "$REPO" && "$FELIX" discover --yes 2>&1)"; rc=$?
    [ "$rc" -ne 0 ] && ok "there is no --yes" || bad ...

Both runs use the PATH the suite inherited, so `felix discover` runs the real
`claude` CLI and reads this machine's whole plugin catalogue
(`claude plugin list --json --available`), scoring every entry. Here that is
516 s of CPU. On a machine with no `claude` (the Linux CI runner), `cmd_discover`
exits at "felix discover needs the claude CLI" before reading anything, so
"discovery writes nothing" holds over a run that read nothing. The assertion
is slow on one machine and vacuous on the other, and on neither does the suite
own what it reads.

**Contract.**
1. Both runs in that block put a stub `claude` first on PATH, written by the
   suite. They never reach the real CLI. The stub logs every call and exits
   non-zero on any call shape it was not taught, as the suite's existing stub
   (`CMSTUB`, part 0010) does. It may be `CMSTUB` taught one more answer, or a
   stub of the block's own; either way the existing stub's answers to every
   other part are unchanged.
2. The stub's `plugin list --json --available` answers a small catalogue the
   block writes, holding at least one entry that `felix discover` lists as a
   candidate for the widget project under the current rules
   (`templates/discover-rules.tsv` and widget's declared capabilities). The
   block must not depend on `felix discover` fetching anything over the
   network: the plain run (no flags) lists candidates and does not fetch.
3. **A positive control, a new assertion:** the plain run's output names the
   catalogue's matching entry. Without it, "discovery writes nothing" can pass
   over a run that matched nothing or stopped early, a statement about a path
   nothing walked (the principle written at the top of this same part).
4. "discovery writes nothing" and "there is no --yes" keep their names, and
   their checks are unchanged: stack.tsv's cksum before and after the plain run
   is equal; `discover --yes` exits non-zero.
5. Nothing else in part 0580 changes.

**Shown failing.** With an engine whose plain `felix discover` appends a row to
the project's stack.tsv (a mutant), "discovery writes nothing" fails under the
new block. With a stub catalogue that matches nothing, the positive control
fails. Both are shown in the PR, and the mutant must fail on this machine and
on one with no `claude` on PATH.

**Measured.** The block's CPU in the same instrumentation, before and after.

**Not in B, flagged:** the real `felix discover` costing 516 s of CPU on a real
catalogue is a product defect of its own (a person running it waits about seven
minutes here). It is a separate task, not this PR.

## B2. The three signal tests wait on the signal, with the same bound

**Today.** Part 0920, `_ibsig` ("inventory A14: the scratch directory is
removed when the run is sent TERM, HUP or INT"). The gh stub (part 0900, line
52) does `exec sleep 30` while `$IB/gh/slow` exists. `_ibsig` waits for the
stub's pid file, removes `slow`, sends the signal to the run, and waits up to
60 s for the run to exit. bash runs a trap only after its foreground child
exits, so each run exits when the stub's `sleep 30` ends: about 30 s of wall
and no CPU each, about 90 s for the three.

**Contract.**
1. The stub, once it has written its pid, waits until the test releases it, up
   to the same 30 s bound, and then exits as `sleep 30` would have (status 0,
   no output). Released means the test has sent the signal: `_ibsig` releases
   the stub only after `kill -$sig`, by a file or a fifo of `$IB`'s own.
2. The run is still waiting on gh when the signal arrives, as today: the stub
   is not released before the signal is sent.
3. Every A14 name and every verdict is unchanged, and so is the 60 s bound on
   the run's exit and the KILL fallbacks in `_ibsig`. Nothing else in parts
   0900 and 0920 changes. The stub's other answers are unchanged.

**Shown failing.** With an engine whose inventory run does not remove its
scratch on TERM (a mutant), the TERM row fails, before and after. Shown in the
PR.

**Measured.** The three A14 assertions' wall, before and after.

## B3. `qualified` rows run in parallel

**Today.** `_felix_qualify_run_rows` (lib/qualify.sh) runs each row in turn:
`got="$(_felix_qualify_one ...)"`, then one verdict line. Each row already runs
in a process, a scratch base and a worktree of its own (0cq), and nothing a row
does is read by the next. 296 rows in felix-home's table; `qualified` was 125 s
of the gate on 2026-10-10.

**Contract.**
1. **How many at once.** `FELIX_QUALIFY_JOBS`: a positive integer is the most
   rows in flight at once. Unset, it is the machine's online CPU count
   (`getconf _NPROCESSORS_ONLN`, then `sysctl -n hw.ncpu`), and 1 when neither
   answers. Any other value (empty, 0, negative, not digits, digits with a
   sign or space) is 1. 1 runs exactly today's loop. Never more rows in flight
   than there are rows selected.
2. **The same output.** For any table, tree and selection, stdout of
   `_felix_qualify_run_rows` is byte for byte what it prints with
   `FELIX_QUALIFY_JOBS=1`: the same verdict lines in the table's order, the
   same skipped lines skipped. Its exit status is today's. A row whose process
   ended without giving a verdict (killed, or died) is reported as
   `unrunnable`, never as met, held or a missing line, and makes the status
   non-zero.
3. **Stderr.** Each row's stderr reaches the caller's stderr whole, never
   interleaved with another row's, in the table's order.
4. **The sweep** (`_felix_qualify_sweep`) runs once, before any row starts, as
   today. Anything the loop itself writes (a row's verdict or stderr while it
   waits for its turn to print) lives in a directory under `$TMPDIR` that the
   sweep's patterns never match (not `felix-qualify.` and six characters, and
   not `tmp.*`), and it is gone when the loop returns, however it returns
   short of SIGKILL.
5. **Signals.** A fact this rests on, measured 2026-10-13 on bash 3.2.57: a
   subshell started with `&` in a non-interactive bash ignores SIGINT, and a
   trap it sets on INT never runs; TERM and HUP traps do run. Today a group
   INT reaches each serial row's trap. So under N > 1:
   a. INT, TERM or HUP to the loop, or to its process group, starts no row
      after it;
   b. every row in flight throws its tree away as a serial row does on that
      signal: its base and worktree are gone and git no longer lists the
      worktree, before the loop exits;
   c. the loop exits with 128 plus the number of the signal it received.
   Shown with a row whose command waits until the signal is sent (no sleeps
   standing in for a race), for each of the three signals, at N = 1 and N = 4.
6. **SIGKILL.** A row process killed outright leaves a base whose owner is
   dead, which the next run's sweep removes, as today. Unchanged.
7. **Concurrency is real.** With N ≥ 2, two rows are in flight at once: shown
   by a table whose first row's command waits (bounded, 20 s) until the second
   row's command has started, and is met only then. At N = 1 the same table's
   first row is held or unrunnable, not met. No assertion here reads elapsed
   time.
8. **No new lines.** `felix qualify` and the gate's `qualified` line print
   what they print today. Callers (`cmd_qualify`, `felix_qualify_run`) need no
   change beyond what the loop does.
9. **Shared git state.** Rows add and remove worktrees of one repository at
   once. A row that cannot add its worktree is `unrunnable`, as today; a row
   must never remove or prune another row's worktree. Shown with N rows whose
   mutations differ and whose verdicts depend on their own mutation only.

**Shown failing.** Item 2 by a table holding a met, a held, an unrunnable and
an inapplicable row, compared byte for byte at N = 1 and N = 4. Item 7 at
N = 1 and N = 2. Item 5 at N = 4 against a mutant loop that does not forward
the signal (a tree is left). Item 1 by each malformed value.

**Measured.** felix-home's `qualified` wall and CPU at N = 1 and unset.

## For the blind author

Write the new assertions in one new part, `1270-gate-friction-b-blind.sh`, from
this contract alone. B1 and B2 change existing parts. Assert what the contract
says about them through the suite as it runs (the positive control's name,
that the block's stub log shows the calls and the real CLI was never reached).
Do not assert elapsed time anywhere. B3 is the bulk: drive
`_felix_qualify_run_rows` and `felix qualify` on scratch repositories of the
part's own, never on `$HERE`'s checkout.

## B4. The receipt's host is the machine's name, not the network's (added 2026-10-14)

**Found.** B's record run on e25774f1 (2026-10-14 ~20:30Z) ended 8840 passed,
7 failed. All seven were part 1200's receipt assertions, and all said the same
thing: `_sr_env`'s host was `Jarrons-Mac-567.local` when the run started and
`wifi-10-44-222-61.wifi.berkeley.edu` when the assertion ran. `_sr_env` takes
the host from `uname -n`, which on macOS follows the network the Mac is on, and
on campus Wi-Fi the name changes as the laptop roams (it changed again within
the hour). #433 noted this as a follow-up that costs a reuse. It also makes any
whole-suite run that spans a network change fail, a record run and a gate
alike, for a reason that has nothing to do with the tree.

**Contract.**
1. `_sr_env`'s host is, in this order: the output of
   `/usr/sbin/scutil --get LocalHostName` when that file is executable, the
   command exits 0, and its output is one non-empty line of only ASCII letters,
   digits and hyphens; otherwise `uname -n`, as today. The path is absolute, so
   the answer does not depend on PATH (PATH is a field of its own). macOS
   keeps LocalHostName across networks; it is the name set under Sharing.
2. Nothing else in `_sr_env` changes: the field order, the other four fields,
   one line.
3. A receipt written before this change names the old host, so on macOS it now
   reads as `another environment` and the suite runs. That is the safe
   direction, and it is said in the PR.
4. On a machine without scutil (the Linux CI runner), the host is `uname -n`,
   as today.
5. Two Macs that share one LocalHostName and one git directory (through file
   sync) would read as one host. That was already true of `uname -n`, and it
   is said rather than fixed here.

**Shown failing.** On a Mac, with a `uname` first on PATH that prints a
different name on every call, two `_sr_env` calls print the same host (today
they differ). Part 1200's assertion of `_sr_env`'s shape is updated to expect
item 1's host. A mutant that keeps `uname -n` fails the new assertion on a Mac.
