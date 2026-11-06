# Contract: an owed engine deploy gets its window (rev 2, 2026-11-06)

## Why

The lander's tick deploys the engine main declares only when no gate or suite
runs on the Mac (`_gt_deploy`, `pgrep -f 'engine/harness/tests/run|gate\.sh'`).
On 2026-11-06 main's 0.49.321 (#485) landed at 11:29Z and was still undeployed
after 14:40Z: sessions kept records and gates going back to back, so no tick
found a moment with none running. Every gate ended red on `installed` (the
TASK_BLOCKING obligation `engine_deployed`), and the tick merged nothing.

The deploy must not signal or invalidate a suite that is already running. So
the only way to a window is that **nothing new starts while a deploy is owed**,
and what runs drains. This contract is that rule, with its bounds.

Words: *the hold* is the lander's statement that a deploy is owed and new work
waits. *Memory root* is `${FELIX_MEMORY:-$HOME/.felix/memory}`. *The land
directory* is `<memory root>/<project>/land/`, where the ledger already lives.

## DW1. The hold file

`<land directory>/deploy-hold`, one line, three tab-separated fields:

    LEASE <TAB> SINCE <TAB> VERSION

- LEASE: seconds since the epoch at the tick's last assertion.
- SINCE: seconds since the epoch at which this owed deploy first held work back.
- VERSION: the engine version main declares, or `-`.

A hold is **in force** when all of these are true, at the time a reader looks:
1. the path is a regular file and its first line has exactly those three fields;
2. LEASE and SINCE are plain decimal integers, and `LEASE <= now + 60`;
3. `now - LEASE < 1200` (the lease; a tick runs every 300 s);
4. `now - SINCE < LIMIT`, where LIMIT is `FELIX_DEPLOY_HOLD_LIMIT` seconds when
   that is a plain decimal integer of at least 1, else 7200.

Anything else is not in force: a missing file, a directory, an empty or
garbled file, a stale lease, a lapsed limit. A reader never fails because of
one; it reads it as not in force. A reader looks at `<memory root>/*/land/deploy-hold`
and the machine is held when any one of them is in force. The engine names no
project, so no reader may name one.

## DW2. Who writes it: the tick

`felix land --tick` owns the file, and writes it whole each time (a temporary
file in the same directory, then a rename), so a reader never meets half a line.

1. **Asserted** when a deploy is owed and a gate or suite is running (the
   case `_gt_deploy` answers today with a `deploy-owed` row). The tick writes
   LEASE = now. SINCE is kept from the file already there when that file's
   lease was still fresh (`now - LEASE < 1200`) and its VERSION is the one main
   declares now; otherwise SINCE = now. The tick keeps refreshing the lease, with
   SINCE unchanged, after the limit has lapsed: the hold is then not in force
   (DW1.4) and is not asserted anew until the deploy is done or not owed.
2. **Held through the deploy.** When the tick finds nothing running and goes on
   to deploy, the hold is asserted (as in 1) before the deploy's first step and
   stays until the deploy ends, so nothing starts while the engine is replaced.
3. **Cleared** (the file removed) when any of these is true at the end of the
   tick: the deploy finished (a `deployed` row); no deploy is owed; the job is
   paused (by the tick itself, by `felix land --pause`, or because a deploy
   step failed and paused it); the deploy ended unverified. A hold must never
   outlive a lander that will not deploy.
4. The row the tick writes while a gate or suite runs is the same `deploy-owed`
   row as before (its first words are still "a gate or suite is running"), and
   its detail also holds the phrase `new suites and gates wait`. When the limit
   has lapsed it also holds `the hold has lapsed`.

Nothing is signalled. The tick sends no signal to any process, for any reason.

## DW3. What the tick counts as running

The tick's test for "a gate or suite is running" stays `pgrep -f` with the
pattern it has now. But a process **waiting at the hold** is not running work,
and neither is a shell wrapped around it. After `pgrep`, the tick drops from its
list every pid that is a *waiter* or an *ancestor of a waiter*. A waiter is a
process whose command line contains the token `felix-deploy-hold-wait`.

The tick learns the process table by running `ps -axo pid=,ppid=,command=`
through PATH once (its lines are `PID PPID COMMAND...`, blanks before the pid
allowed). Anything it cannot read, parse or trust counts as running: `ps` not
found, a non-zero status, no output, or a pid that `pgrep` listed and `ps` did
not. Only a pid that `ps` shows as a waiter or as an ancestor of one is dropped.
If every pid is dropped, nothing is running and the tick goes on to deploy. The
`matched ...` text of the row names only the pids that were not dropped.

## DW4. Who waits

A command **enters** through one of two doors. Both skip the wait, and say
nothing, when `FELIX_HOLD_PASSED` is set to anything non-empty in the
environment, or `FELIX_DEPLOY_HOLD` is `off`. Otherwise, when the machine is
held (DW1), they wait; when it is not, they go on at once with no wait and no
output.

1. **`tests/run`, in every mode but `--part`** (a full run, `-j N`,
   `--record-assertions`, `--reuse`). The wait comes before the suite creates
   anything: no temporary directory, no fixture, nothing on stdout. **Part mode
   (`--part`, one to six parts) does not wait** and says nothing: it is a person's
   or a builder's own short run, it takes no slot, and the ledger shows no part
   run among what held the deploy back on 2026-11-06. It still exports
   `FELIX_HOLD_PASSED=1` on starting, as below, so nothing it starts waits.
   A part run that is running when the tick looks still counts as running (DW3);
   it ends by itself.
2. **`felix gate`, with any arguments**, before it runs the project's gate
   command and before it prints anything on stdout.

On going on, each door **exports `FELIX_HOLD_PASSED=1`**, so everything it
starts (a project's `gate.sh`, `tests/run --reuse` under it, the runner's
`--part` children, `tests/red`) enters without waiting. A hold taken after a
gate began therefore never stops the gate's own suite. A caller that wants to
test the wait itself runs the command with `FELIX_HOLD_PASSED` out of its
environment.

The tick's own `felix gate --quick` in the home, run during a deploy, is run
with `FELIX_HOLD_PASSED=1`: the tick holds the hold and must not wait on it.

## DW5. How a waiter waits

- It looks again every `FELIX_DEPLOY_HOLD_POLL` seconds (a positive number,
  fractions allowed; default 5).
- Everything it says goes to **stderr**. Its stdout stays empty.
- Its first line, at once, is
  `<who>: waiting for the engine deploy ...` where `<who>` is `tests/run` or
  `felix gate`. The rest of the line holds the VERSION when the file has one,
  the time the hold began, `at most <LIMIT> s`, and the words
  `FELIX_DEPLOY_HOLD=off` as the way past it.
- While it waits it says one more line every `FELIX_DEPLOY_HOLD_SAY` seconds
  (default 300), beginning `<who>: still waiting for the engine deploy` and
  holding the seconds waited.
- It goes on, and says one line, `<who>: went ahead after <N> s: <why>`, when
  the machine is no longer held. `<why>` is `the hold ended` when no hold file
  is in force because it is gone, and `the hold lapsed` when a file is there but
  not in force (DW1.3, DW1.4).
- **It is bounded.** After `FELIX_DEPLOY_HOLD_LIMIT` seconds of its own waiting
  (default 7200, the same reading as DW1.4) it goes ahead whether or not the
  machine is still held, saying `went ahead after <N> s: the limit was reached`.
  The bound never depends on the lander being alive.
- A waiter that cannot wait (no perl where it needs one) goes ahead at once,
  and says `not waiting for the engine deploy:` and why, once.

## DW6. A waiter does not look like running work

While a waiter waits, neither it nor any process it starts has a command line
that matches the tick's pattern `engine/harness/tests/run|gate\.sh`, and a
process it leaves in the table while it sleeps carries the token
`felix-deploy-hold-wait` in its command line (DW3). A caller's own wrapper
(`bash -c '...tests/run...'`) matches the pattern; the tick drops it because it
is an ancestor of the waiter.

## DW7. Fail open

Reading the hold, the clock, the table of processes: any failure there makes
the reader act as if nothing were held. A wait is never longer than DW5's bound
because of a damaged file, and a command is never refused because of one.

## What this does not do

- It does not stop a suite or gate that has started. Those drain.
- It does not decide when the deploy runs; the tick's five-minute run does.
- It does not replace the Mac-wide suite slots (`$TMPDIR/felix-suite-slots`),
  which size how many `-j` units run at once. The hold is asked before the
  slots are, at the door.
- A deploy that is owed for another reason (the home off main, a tracked change
  in the home) asserts no hold: holding work back would not get it deployed.
- The first deploy of this change is made by a tick that does not have it.
