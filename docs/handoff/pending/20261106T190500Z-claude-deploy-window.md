### 2026-11-06: an owed engine deploy gets its window; new suites and gates wait for it (0.49.326)

**What failed.** `_gt_deploy` returns "deploy owed" whenever
`pgrep -f 'engine/harness/tests/run|gate\.sh'` matches anything, and signals
nothing, because a deploy under a running suite would invalidate what the suite
measures. Main's 0.49.321 (#485) landed at 11:29Z on 2026-11-06 and was still
undeployed after 14:40Z: the ledger has a `deploy-owed` row every hour, "a gate
or suite is running; still so since 2026-11-06T11:29:21Z", and the processes it
names change every time, because sessions kept records and gates going back to
back. No tick found a moment with none running. Every gate meanwhile ended red
on `installed` (the TASK_BLOCKING obligation `engine_deployed`), and the tick,
which merges nothing while a deploy is owed, merged nothing. On this Mac at
about 18:50Z the same pattern matched 149 processes: 6 `projects/felix/gate.sh`
and 42 `tests/run --reuse`.

**What changed.** The contract is `docs/2026-11-06-deploy-window-contract.md`
(DW1 to DW7). Nothing new starts while a deploy is owed, so what runs drains and
the tick's next run deploys.
- `lib/deploy-hold.sh`, new. The hold is a file,
  `<memory root>/<project>/land/deploy-hold`: `LEASE SINCE VERSION`, tab
  separated. It is in force while its lease is under 1200 s old and it began
  under `FELIX_DEPLOY_HOLD_LIMIT` (7200) seconds ago. Anything unreadable is not
  in force (fail open).
- The tick (`lib/green-tick.sh`) writes it whole when a deploy is owed and a gate
  or suite is running, keeps `SINCE` while the lease is fresh, holds it through
  the deploy itself, and removes it on every other way out: deployed, not owed,
  paused (also by hand), unverified, uninstalled. It sends no signal.
- Two doors wait while the machine is held, say why on stderr, and go ahead at a
  bound: `tests/run` in every mode but `--part` (before it makes anything) and
  `felix gate` (before it runs the project's gate). Part mode does not wait: it is
  a person's or a builder's own short run, and none of the processes the ledger
  names as holding the deploy back on 2026-11-06 was a `--part` run (the load
  governor session asked for this; its design keeps a person's own work
  ungated). It passes `FELIX_HOLD_PASSED=1` on all the same. Each exports
  `FELIX_HOLD_PASSED=1` on going on, so a `gate.sh`, its `tests/run --reuse`, the
  runner's `--part` children and `tests/red` do not wait again. The tick's own
  `felix gate --quick` is run with it. `FELIX_DEPLOY_HOLD=off` goes ahead.
- **A waiter must not look like work.** A bash waiting in `tests/run` has the
  lander's pattern in its command line, and an agent's `bash -c '...tests/run...'`
  wrapper does too, so a wait inside either would have kept the deploy waiting for
  the wait. The run door replaces itself with a perl that sleeps (the script's
  path and arguments travel in its environment) and starts the script again; the
  gate door sleeps in a child. Both carry the token `felix-deploy-hold-wait`, and
  the tick drops from its list every pid that is a holder of the token or above
  one (`ps -axo pid=,ppid=,command=`). A pid `ps` does not show stays: it counts
  as running.

**Shown red and green.** Part 2480 was written blind from the contract by an
agent that had not seen the implementation. (Figures to be filled in.)

**Not done, and limits.**
- The first deploy of this change is made by a tick that does not have it, so
  it needs a moment with nothing running, or a hand deploy from the home.
- At 18:50Z the lander was not ticking at all (`felix.land.felix` loaded, no
  tick since 16:49Z, the trampoline unable to read `FELIX_HOME_DIR`: /bin/bash
  needs Full Disk Access). That is a separate cause and the founder's to grant.
- A suite that is already running is never touched, so a deploy still waits as
  long as the longest run that began before the hold. After
  `FELIX_DEPLOY_HOLD_LIMIT` seconds from the hold's start the hold is spent and
  new suites run again until the deploy is done; a hung process that matches the
  pattern therefore costs everyone that long once, not for good.
- Between a waiter's pause and its next look a bash is in the table for a few
  milliseconds with the lander's pattern in its command line. A tick that
  samples then reads a run and tries again five minutes later.
- The Mac-wide suite slots (`$TMPDIR/felix-suite-slots`) are unchanged. The
  dynamic load governor (design `docs/2026-11-06-load-governor-design.md`, slice
  1) can fold the hold in as a land-class rule; its two call sites are
  `_dh_enter_run` and `_dh_wait_gate`.
