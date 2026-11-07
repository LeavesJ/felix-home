# Dynamic load management on this Mac

**Founder direction, 2026-11-06, in his words:** "as we're developing and
making felix more sophisticated, think about optimization. Overloading issue
should easily be managed by a dynamic optimization issue". Felix owns the how.
This document sets out the how in three slices, and gives slice 0's contract.
Whether the design binds future sessions was his decision. Section 8 gives
the row for `docs/direction.md` §4, which he said yes to on 11-06.

Paths are relative to the worktree. `eh/` is `engine/harness/`. A bare
four-digit number is `eh/tests/parts/<n>-*.sh`. "The mod" is the dash mod,
`~/.claude/mods/dash/hooks/register.tsx`, which is not in this repository.

## 1. What changes

**Today.** Work on this Mac starts whenever its caller decides, at a size
the caller fixed in advance:
- a session's gate;
- a workflow's builders and the part runs each one starts;
- the lander tick;
- the pulse;
- the dash mod's readers in every session;
- every hook.

None of them looks at the machine, and nothing ranks them. Under load each
job takes longer. Jobs that take longer overlap more, and their timeouts
fire. A timeout often leaves the work running and starts it again. So
overload feeds itself.

**After.** Heavy work asks for a slot before it starts, and the answer depends
on measured headroom: the load average against the cores, and memory pressure.
- The founder's own commands are never gated.
- Background readers are refused first, and they run at background QoS.
- An expensive read runs once, and every caller shares its result.
- Every job runs as a process group with a deadline, and the group is killed
  when the deadline passes.
- Every decision is written down with the load it saw. Felix can then say
  what the load cost: how long a gate waited, and behind what.
- The caps are derived from those records, not chosen by hand.

## 2. What was measured

**Three overloads.**

| When | Load | Cores | What ran | Effect |
|---|---|---|---|---|
| 09-23 | 150-280 | 10 | 26 Claude Code processes with their suites | wall time 5-17x CPU (memory `measure-cpu-not-wall-under-load`) |
| 10-25 | 351 | 10 | about 30 suites from 8 workflow builders; 67% system time, 55 MB free | parts 10-30x slower; 20 orphaned infinite loops at ppid 1, 18 h to 1.8 days old |
| 11-05/06 | 166 | 18 | lane slice 1's record run among others | more than 3 h 45 min, against about 25 min quiet |

**`felix cost`, read 2026-11-06 at 07:40Z** (load 122, 18 cores, child CPU by
getrusage):
- One `felix cost --week --tsv` run took 15.7 s CPU (15.1 user, 0.6 system)
  and 29.4 s of wall time.
- It read 140 transcripts, 1236 MB in all. The week had been open for 18.7
  hours.
- By stage: find took 0.13 s of CPU, grep 9.27 s, and awk about 2.5 s. grep
  passed 146 MB of matching lines, 31,286 of them, to awk.
- Transcripts grow through the week. At this rate the week's last scan reads
  about 9 times as many bytes, and costs about 110-140 s of CPU.

**The mod's two defects, reproduced.**
1. **Its lock is check-then-set.** `readSpend` reads `spendLock` from the
   store, then sets it. Two sessions that read in the same tick both start a
   scan. On 11-06 at about 07:11Z three did (pids 67285, 74939, 78383).
2. **Its timeout leaves the scan running.** `$.process.run(..., {timeoutMs:
   180000})` sends TERM to `felix` alone. The test: node's `execFile` with a
   3 s timeout, standing in for the mod's call, was run on `felix cost`.
   After the timeout:
   - the pipeline's brace-group subshell, and its grep and awk, were alive at
     ppid 1;
   - they were still scanning 13 s later.
   - The orphans seen at 05:45Z (ppid 1, about 59 minutes old) fit this.

   The mod's lock lasts 3 minutes and its cache 15. Under load, a scan
   outlives both, the next session starts another, and the orphans add up.

**What the obvious cache buys.** Reusing a result "while no transcript is
newer" seldom holds while sessions run, because every live session appends
to its own transcript every few seconds. Two things count more than the
cache:
- one run at a time;
- callers served the last result instead of starting their own scan.

The mod polls every 5 minutes. A reading may be reused for up to 15 minutes,
the age the mod already accepts, so one scan serves every session in that
time.

**Reading only appended bytes is deferred to slice 0b.** It would cut a
scan's CPU by about 50 times at the week's end. Most transcripts in a week
are finished, and the live ones grow by megabytes, not gigabytes. But:
- after slice 0, scans run at most 4 times an hour across the machine;
- each takes about 15 s of CPU now, and about 2 minutes at the week's end;
- that is about 0.4 to 3 CPU-hours a day, out of 432 on this Mac.
- In return it would replace the scan's whole read path, which two adversarial
  review rounds settled (1050, 1070).

So it pays, but modestly, and it is the riskiest part. Slice 0 splits the
scan from the totals, so the state that slice 0b needs has a place to go.
Section 5 says what slice 0b would do.

## 3. The class

Every actor sizes its own work with a fixed number:

| Actor | Fixed number | Sees the machine |
|---|---|---|
| suite `-j N` | slots = core count (`FELIX_TEST_SLOTS`), Mac-wide flocks in `$TMPDIR/felix-suite-slots` (0007) | no |
| part mode (`--part`) | takes no slot | no |
| scratch `tools/alone.sh` | 4 slots, Mac-wide, 1200 s limit | no |
| workflow builders | as many as the script starts | no |
| lander tick | one PR per tick, launchd interval | no |
| pulse | daily, launchd | no |
| dash mod | every 5 min per session; 3-min lock, 15-min cache in the store | no |
| `felix cost` | one full scan per call, no lock, no deadline | no |

Two things follow:
1. **Nothing ranks the work.** A background reader and the gate for the next
   landing compete on equal terms.
2. **Timeouts that do not bound a process group create work.** The mod's
   timeout and alone.sh's predecessor both left runs behind.

## 4. How Felix decides

1. **Admit against headroom, not a count.** Headroom is read when the job asks:
   the one-minute load average over the core count, and memory pressure. A
   count is a guess about headroom made in advance.
2. **Work has a class, and the classes have an order.** From first to last:
   - **foreground:** what a person typed. It is never gated.
   - **land:** the lander tick, and the gate of the PR it is landing.
   - **build:** records, part runs and workflow fan-out.
   - **background:** cost, status refresh, discover refresh, pulse, and mod
     pollers.
   A class gives way before the class above it does.
3. **Background gives way by not starting.** A background reader under
   overload serves its last result, marked as such. It never waits in a queue.
   When it runs, it runs at background QoS: `taskpolicy -b` on macOS, `nice`
   elsewhere.
4. **Coalesce expensive reads.** One run makes the result, and every caller
   reads it.
5. **Every job is a process group with a deadline,** under a supervisor that
   outlives its caller. A caller's timeout ends the caller only, and never
   orphans the work.
6. **Record every decision** with the load it saw, so the load's cost can be
   reported and the caps derived.

## 5. Slice 0: `felix cost`

Slice 0 builds principles 4 and 5 for the one reader that shows the class most
clearly. Then the mod comes to rely on it. Below, a **reading** is the scan's
per-response result for one window of one records root under one engine.
Everything `felix cost` prints is computed from it. Its **key** is:
- the records root, resolved to a physical path;
- the window's start;
- the window's end, or "open" for `--since`;
- the checksum (`cksum`) of `eh/lib/cost.sh`.

`--by`, `--top`, `--tsv`, the cap, the source wording and `as_of` are not in
the key. They only shape how a reading is printed, so one reading serves them
all.

### The contract

- **C1. Interface.** Every current argument, variable, output and status stays
  as it is, unless a clause below changes it. Two things are new:
  - `--max-age SECONDS`, a whole number from 0 to 604800;
  - `FELIX_COST_DEADLINE`, whole seconds from 1 to 86400, default 1800.
  
  An invalid value of either is refused with status 2, in the same form as
  today's refusals.
- **C2. Where readings live.** In `$HOME/.cache/felix/cost/`:
  - one file per key, named from the key's checksum;
  - one lock file, `lock`.
  
  The directory is not under `~/.felix`. The pulse runs `git add -A` there
  (`lib/pulse-stage.sh`), and it would commit every reading.
- **C3. A current reading is served as if just read.** Two conditions make a
  reading current:
  - a reading for the key is kept;
  - since its scan began, nothing under the root has changed. A `find -L` of
    the root finds no `*.jsonl` file and no directory, the root included, with
    a status-change time (ctime) newer than the reading's scan start. It finds
    no `*.jsonl` that is a dangling link, and it reports no error. On a root
    whose times carry no fraction of a second, the scan start is taken as two
    seconds before the second it began in.

  `felix cost` then prints byte for byte what a fresh scan would print now,
  with `as_of` now. It opens no transcript, and it does not take the lock.
- **C4. One run at a time, machine-wide.** When no reading is current, the
  caller asks for the lock without waiting. The lock is a kernel `flock`, held
  by the supervisor (C7) for exactly the run's life. The kernel drops it when
  the supervisor ends, however it ends. Under the lock the run checks C3
  again, and scans only if no reading is current yet. So callers that arrive
  in the same second make one scan between them.
- **C5. Callers are never queued behind a run.** When another run holds the
  lock, the caller returns at once with status 0:
  - **A reading for its key is kept.** It prints that reading. Its `as_of` is
    the one the run that made the reading printed, which follows
    `FELIX_COST_NOW` when that was set. It adds a row `cover	served	last`
    straight after the `as_of` row. In text, the line after `window` is
    `served   the reading made at <as_of>; another felix cost run is reading
    now`.
  - **None is kept.** The cover rows read `files_read 0`, `files_unread 0`,
    `responses_unread 0`, `coverage unknown`, and `as_of` now. Then come
    `cover	served	none` and `total	all	unknown	unknown	unknown`. In text,
    the total line is `total    unknown (another felix cost run is reading
    now, and no earlier reading of this window is kept)`, and `calls
    unknown` follows it.
- **C6. `--max-age N`.** A kept reading whose scan began at most N seconds
  ago, by the real clock and never by `FELIX_COST_NOW`, is printed without
  checking for changes, and without the lock. Its `as_of` is the reading's
  own, as in C5, and it adds `cover	served	aged` after `as_of`. In text, the
  line after `window` is `served   the reading made at <as_of>, <age> s ago
  (--max-age N)`. An older reading, or none, goes on to C3 to C5.
- **C7. Process group and deadline.** The scan runs in a process group of its
  own, under a supervisor that holds the lock.
  - At `FELIX_COST_DEADLINE` seconds after the scan starts, the supervisor
    sends TERM to the group, and KILL to it 5 s later.
  - When the scan ends, for any reason, the supervisor kills whatever is left
    in its group.
  - A scan cut at its deadline writes no reading, and its temporary files are
    removed: the directory then holds only `lock` and the readings it held
    before.
  - A caller still waiting then prints as C5 says, status 0, with one change of
    words. The `served` line ends `the new reading did not finish within N s`
    instead of `another felix cost run is reading now`. The total line of
    "none" reads `unknown (the reading did not finish within N s, and no
    earlier reading of this window is kept)`. The rows are C5's, `served last`
    or `served none`.
  - The caller waits for its own run, up to the deadline and the 5 s after it.
- **C8. The caller can die, and the work is not lost.** The supervisor and the
  scan hold none of the caller's standard streams. So a caller killed by a
  timeout (the mod sends TERM to `felix` alone) does not leave a process
  holding the pipe that the timeout was meant to close.
  - **After that:** the supervisor goes on, the scan finishes or meets its
    deadline, the reading is written, and the lock is released.
  - **INT, QUIT, HUP and TSTP:** the supervisor ignores them, and the scan's
    group is not the terminal's foreground group. So neither a Ctrl-C nor a
    Ctrl-Z stops a run that holds the lock. A caller waiting on the supervisor
    waits interruptibly, so a person's Ctrl-C ends `felix` at once.
  - **TERM to the supervisor itself:** it kills the scan's group and ends, and
    the lock goes with it.
- **C9. Readings are whole or absent.** A reading is written to a temporary
  file in the same directory once its scan has ended, and renamed into place.
  So while a scan runs, the directory holds only `lock` and the readings. A
  reader treats a file as absent when it does not parse, or when its first
  line does not name exactly its key.
- **C10. Without the means, nothing changes.** In these cases `felix cost`
  scans inline exactly as before this change, and writes nothing:
  - `HOME` is unset or empty;
  - the cache directory cannot be made or written;
  - perl is not on `PATH`;
  - the reading cannot be written, as on a full disk.
- **C11. Pruning.** When a reading is written, two kinds of file are removed:
  readings not rewritten for 14 days, and temporary files older than a day.
- **C12. Same numbers.** Splitting the scan from the totals changes nothing it
  prints. Every assertion of 1050, 1060 and 1070 holds, with or without a
  kept reading, with one change: 1060's check that `felix cost` creates and
  changes nothing now excludes `$HOME/.cache/felix/cost`, where C2 puts the
  readings.
- **C13. What reads a transcript.** As today, the scan opens transcripts only
  through `grep`, resolved from `PATH`, at most once per 256 files. The
  freshness check of C3 runs `find`, which reads no file's contents. So a
  `grep` placed first on `PATH` sees every scan, and nothing else.

### Built as

- **Two stages.** `lib/cost.sh` keeps the scan, and its awk is cut at
  `settle()`. Stage 1 emits:
  - a coverage row (files read, files unread, whether any transcript exists);
  - one row per response id: weight, time, model, id, then record directory.
  
  The record directory is last, so a tab in it cannot shift a field. Stage 2
  is the rest of today's `END`: window, totals, facets, text and TSV. The
  fallback (C10) pipes stage 1 straight into stage 2, as one pass.
- **`lib/cost-cache.sh`, new.** It holds the key, the freshness check, the
  reading's header (scan start in epoch seconds, `as_of`, key), and serving.
  It also holds the supervisor, one `perl -e`. It closes every descriptor
  above stderr and takes the flock with `LOCK_NB`. It ignores INT, QUIT, HUP
  and TSTP, and sets its CHLD handler before it forks. (On macOS a CHLD whose
  action is the default is discarded even while blocked, so a child that
  ended first would have left the supervisor waiting for good, holding the
  lock.) It puts the child in its own group and execs the scan, enforces the
  deadline with `alarm`, and kills the group. The caller starts it in the
  background and `wait`s, so the wait can be interrupted.
- **The reading's mtime is its scan start.** The run touches `lock` before
  find runs: only the lock's holder writes it, and a reader passes it over,
  so it stamps the start without adding a file. The scan holds stage 1's rows
  in memory until it ends. Then the run writes the temporary file, copies the
  lock's time onto it with `touch -r`, and renames it into place. So C3 is one
  `find -cnewer` against the reading itself. A scan killed before the rename
  leaves the old reading and its old time. That errs toward a needless
  rescan, never toward a stale "current".
- **Coarse filesystems.** HFS+ keeps whole seconds and FAT two, so a change
  made just after the scan began could carry a time at or before the scan
  start. When the root's own ctime has no fraction of a second, the reading is
  dated two seconds before the second its scan began in, with perl's `utime`.
  On APFS that branch is never taken.
- **The root is checked again before the write.** The scan resolves its root
  once more, and writes nothing if it now resolves elsewhere, as when a link
  on the way to it was moved during the scan.

### The mod, relying on it

- `readSpend` drops its store lock, which was check-then-set, and its 15-minute
  store cache.
- Every 5 minutes it runs `felix cost --week --tsv --max-age 840`. `felix`
  then serves every session the same reading for up to 14 minutes, and makes
  one scan when the reading is older.
- `served last` and `served none` show as the last value, or as unknown, with
  the detail "another felix cost run is reading now".
- When the call times out, the band keeps the previous value. It says the
  refresh is still running and the next read gets it. It no longer overwrites
  the value with unknown for 15 minutes.
- Until the engine with `--max-age` is deployed, the mod gets the old engine's
  `unknown argument: --max-age` refusal. It then makes the call without the
  flag, behind its old store guard. That path goes away once the deploy has
  run on every Mac it serves.
- It is built with the plugin-authoring skill, in the dev copy, and its tests
  run before it is installed.

### Limits slice 0 keeps, stated

- **No perl, no coalescing.** The lock and the supervisor need perl (C10). It
  is on macOS and on the CI image, as the suite's runner already assumes
  (0007).
- **Some roots are never current.** A root that holds an unreadable directory
  or a link loop makes find report an error, and a dangling `*.jsonl` link
  counts as a change. Such a root is rescanned on every call, as it is today.
- **The inline fallback is unsupervised.** When the lock cannot be taken at
  all, or a reading cannot be written, the scan runs inline as it does today:
  no deadline and no process group of its own.
- **Other clocks.** A root on a network filesystem takes its times from the
  server's clock. If that clock runs behind this Mac's, a change can carry a
  time at or before the reading's, and a stale reading is then served as
  current. So can a root with fine times that reaches, through a link, a
  filesystem with coarse ones.
- **Tabs in ids and model names.** Stage 1's rows are cut at tabs, and only
  the record directory, which comes last, may hold one. A response id or
  model name holding a raw tab would shift the fields. JSON escapes a tab in
  a string, so a transcript that parses cannot hold one.
- **Spurious rescans.** C3 counts any directory change under the root, a
  session's memory directory included. That costs a needless rescan, never a
  wrong number.
- **KILL to the supervisor.** If the supervisor is killed with KILL, its scan
  is left without a deadline. The scan is finite: it is find, grep and awk over
  regular files. But for its remaining life a second run can start beside it.
- **A person's waiting run is still a full scan.** A person at the terminal
  waits for the scan they start, up to the deadline. Slice 0b is what makes
  that scan cheap.
- **No QoS yet.** Background QoS for the scan comes with slice 1, which is
  where the class is decided.

### Slice 0b: appended bytes only (deferred)

The reading would also keep, per file, three things:
- the device and inode;
- the byte offset of its last complete line;
- the last 32 bytes before that offset.

A file whose ctime is not newer than the reading's would be skipped. A grown
file would be read from its offset, after a check of those 32 bytes. Any
mismatch, a shrunk file or a new inode would mean the whole file is read
again. Two rules from stage 1 would carry over:
- within a file, the last line of an id wins;
- across files, the largest weight wins.

Stage 1 would merge the new lines into the file's kept per-id rows. It is
built only if a week-end measurement shows scans still costing more than a
few minutes of CPU an hour, or when a person's waiting scan matters.

## 6. Slice 1: the governor, report-only first

**One entry point.** `felix load` and `lib/load.sh`:
- `felix load run --class CLASS [--name NAME] -- CMD...` runs CMD when it is
  admitted;
- `felix load --tsv` reports.

The helpers that already exist call it:
- the suite's `-j` slot holder (0007);
- the part-run helper that replaces the scratch `alone.sh`;
- the gate's suite step;
- the lander tick;
- the pulse;
- `felix cost`'s supervisor;
- the discover refresh.

**Headroom.**
- **Load.** `sysctl -n vm.loadavg` (macOS) or `/proc/loadavg`, over
  `hw.ncpu` or `getconf _NPROCESSORS_ONLN`. On Apple silicon,
  `hw.perflevel0.physicalcpu` and `hw.perflevel1.physicalcpu` split the cores.
  This Mac has 6 performance cores and 12 efficiency cores, and background
  QoS runs on the 12.
- **Memory.** `sysctl -n kern.memorystatus_vm_pressure_level` (1 normal,
  2 warning, 4 critical) on macOS; `/proc/pressure/memory` or `MemAvailable`
  on Linux.

Headroom is read at each admission, and once a second while a job waits. It
is never cached.

**Admission, by class.** The thresholds start as below. Slice 2 replaces them
with derived values.

| Class | Admitted when | Otherwise |
|---|---|---|
| foreground | always | (never gated) |
| land | load/core < 3 and memory not critical, or it has waited 10 min | waits, re-reading each second |
| build | load/core < 1.5, memory normal, and fewer build jobs than the current cap | waits, with backoff to 30 s |
| background | load/core < 0.7 and memory normal | does not start; serves its last result, or skips this round |

**Who is foreground.** Only work that declares a class is ever gated.
Whatever a person types, and whatever has no class, is foreground.
- That makes "the founder's own session is never gated" true by
  construction. The governor cannot tell his session from a workflow agent,
  and it does not try.
- The cost is that a build agent's bare `tests/run` is not gated. The
  report-only phase measures how much load comes from unclassed heavy work.
  The gate and `tests/run` write rows even when no class is declared. That
  number decides whether slice 1b classes them, through session start, by
  marking sessions a person did not start.

**QoS.** Background jobs run under `taskpolicy -b` (macOS), or `nice -n 19`
with `ionice -c 3` where present. Build jobs run under `nice -n 5`.

**Rows.** One row per decision goes to `$FELIX_MEMORY/load.tsv`, which the
pulse backs up because slice 2 needs its history. A row has:
- the time, class, name and pid;
- the decision: admit, wait, give way, or report-only "would wait";
- load1, load5, the cores, the memory level, and the jobs running per class.

When a job ends, a second row adds its wait seconds, its child CPU seconds,
its wall seconds and its exit status. `felix load --report` then answers
questions like these:
- the gate on branch X waited 14 minutes behind 3 build jobs and 1 background
  job, at a load of 2.4 per core;
- background readers gave way 37 times today.

**Report-only first.** For a week, the governor admits everything and writes
the decision it would have made. Enforcement is turned on per class,
background first. It is turned on only after its would-wait rows show that
holding back that class would have cut the load without holding up a landing.

**Not in slice 1:**
- Gating Claude Code itself: its model calls, or the number of sessions.
  Only Felix's own jobs are gated.
- Killing anything for load. A job past its deadline is killed by its own
  supervisor. The governor only decides what starts.

## 7. Slice 2: the cap, derived

The build class's cap stops being a number in a file.

**The input.** From `load.tsv`, for each window of 10 minutes:
- the build concurrency c, the time-weighted mean of build jobs running;
- the throughput: child CPU seconds of finished build jobs per wall second;
- the system-time share where it can be read.

**The knee.** Throughput rises with c until the machine saturates, then flattens
or falls. Fork and exec storms showed as 67% system time on 10-25. The cap is
the smallest c at which one more job raised throughput by less than 5%,
measured over the last 7 days, and bounded between 1 and the core count.

**The rule.** It is recomputed daily by the pulse. It is report-only for its
first week: the derived cap is shown beside the fixed one. Then it enforces.
A day with fewer than 50 finished build jobs keeps the previous cap. Changing
machines (memory `machine-change-48gb-rebaselines-gate-time`) starts the
derivation over.

**The same rule for land and background?** Not until the rows show they
contend. One PR lands per tick, so land's concurrency is 1 by contract.

## 8. The direction row (the founder said yes, 11-06)

Proposed here so the design could bind future sessions. Asked whether to add
it as proposed, the founder answered "Yes, add it" on 2026-11-06. It binds
from this branch's pending handoff section once that lands (`docs/direction.md`
§10). The fold into §4 is row 41, in draft #489, which waits for his merge.

> **Load on this Mac is managed, not capped.** Heavy Felix work asks for a slot
> and is admitted against measured headroom: the load against the cores, and
> memory pressure. No fixed count is set in advance. The founder's own commands
> are never gated. Background work gives way first and runs at background QoS.
> Every job runs as a process group with a deadline under a supervisor, so a
> timeout never orphans work. Every admission decision is recorded with the load
> it saw, and caps are derived from those records: the concurrency at which
> throughput stops rising. No new fixed concurrency cap is added to Felix.

Without the row, slices 0 to 2 are still Felix's to build. The row only stops
a later session from adding the next fixed cap.

## 9. Order and budget

1. **Slice 0.** The contract above. The engine change goes through the ultracode
   pipeline:
   - blind assertions from section 5 alone, as part 1075;
   - red on main;
   - the implementation;
   - one adversarial review;
   - at most two fault rounds (memory `lane-slice-review-budget`);
   - the record, red and gate, and the PR.

   The mod change follows in the dev copy and is installed after the deploy.
2. **Slice 1, report-only.** `lib/load.sh`, the rows, and the existing slot
   holders calling it. Then a week of rows.
3. **Slice 1, enforcing,** one class at a time: background first, then build.
   The scratch `alone.sh` and its 4 slots are retired.
4. **Slice 2.** The derived cap, report-only for a week, then enforcing.
5. **Slice 0b,** only on the trigger in section 5.

Each slice's PR states its limits in its body. None changes what the gate
verdict means: the governor decides when a gate starts, never what it says.
