### 2026-10-18: slot 3f, a child of the suite took its EXIT trap and emptied $TMP

Part 0573 failed on Linux CI from L12 on (#441, run 38957354055, attempt 1):
`mkfifo` under `$TMP` gave "no FIFO", and `printf > "$FROOT/projects/widget/autonomy"`
said No such file or directory. The suite's temporary directory was gone and
the suite ran on. The closing "grep: write error: Broken pipe" is the gate's
own `grep | head` over the failure log, not the suite. macOS has never shown it.

**Cause.** The process group was not at fault. A child the suite forks took
the suite's EXIT trap and removed `$TMP`. In bash 5.2 (Ubuntu's), `make_child`
blocks INT and TERM across `fork` and unblocks them in the child at once.
`execute_in_subshell` then runs `QUIT; CHECK_TERMSIG` before
`reset_terminating_signals` and `reset_signal_handlers`. The suite traps EXIT
and nothing else, so a non-interactive bash handles INT and TERM in
`termsig_sighandler`, which has no `SUBSHELL_IGNTRAP` check. That check is
only in `trap_handler`, for trapped signals, and it is why felix, which traps
INT and TERM itself, is not exposed the same way. So a `( ... ) &` child
signalled before its reset runs `termsig_handler`, then `run_exit_trap`, with
the parent's trap still set: `_fx_exit`, then `rm -rf "$TMP"`. `_lwsweep`
signals its first runs at delay 0: INT to the group, and TERM to the pid by
the same path. On a loaded runner the child had not reset yet. Part 0003's
comment said the opposite ("EXIT traps are not inherited by subshells").

**Evidence.**
- The CI log above.
- bash-5.2 `jobs.c` 2134-2225 and `execute_cmd.c` 1573-1580, and `sig.c`'s
  termsig handlers.
- A loop of the sweep's shape, `scratchpad repro/micro.sh` (copied to
  `audits/2026-10-18-slot-3f/`): old trap against guarded trap, INT to the
  group and TERM to the pid at delay 0. On macOS bash 3.2.57, no run in 100
  had a child take the trap, which fits CI being the only place it showed.
- Linux bash 5.2: not reproduced. The carrier held Docker until there was
  a gap between records (16 GB, records fail on wall-clock fixtures under
  load), and none came before this was otherwise done. So the bash 5.2
  mechanism is reasoned from its source plus the CI log, and the fix is
  shown by 0575 going from red to green on bash 3.2. `incontainer.sh`
  beside `micro.sh` runs both the loop and 0573 on ubuntu:24.04 when a gap
  allows: a 2-CPU, ≤4 GB VM, one part only, paused when a record starts.

**Fix.** Parts 0001 and 0003 only. Both EXIT traps read the pid of the
process running them and act only when it is the shell that made `$TMP`
(`_tmp_by`). Elsewhere the trap only exits, with the status it was given. The
pid is `BASHPID`, or on bash 3.2 the PPID of a `/bin/sh` exec'd in a `$(...)`,
as `lib/qualify-run.sh` reads its own. The read is kept as text (`_tmp_pid`)
and written into each trap when it is set, so no later definition can take
the removal away (the fixture floor owner's ask, 2026-10-08). A pid that
cannot be read at the start stops the suite before `mktemp`. One that cannot
be read at exit leaves `$TMP` rather than remove it. It is not
`BASH_SUBSHELL`, as first written: the blind part's "uncounted" child showed
that bash 3.2 would then take a child for its parent.

**Test.** Part 0575 was written blind from the contract alone (49496ead),
then the fix landed (5ab64574). It runs the suite's current EXIT trap,
read from `trap -p EXIT`, in three children of the suite: one exiting 0, one
reading `BASH_SUBSHELL` 0, and one exiting 7. For each it checks that a
stand-in for `$TMP` survives, no report is printed, and the status is kept.
`$TMP` is moved to a scratch directory first. Against main it fails 8 of 11
(onepart). With the fix: 73/0, prelude included, on bash 3.2. The owner's
own removal stays pinned by parts 0200 and 0201's section runners.

**Owed at landing.** A record, for `assertions.tsv` (11 new names) and
`red.tsv`. The version is the carrier's. The gate runs when the carrier
calls. No engine file changed.

**Order.** Written to land after gate friction C (#444, `claude/gf-c`
ca87df52). At the carry (2026-10-18) it rides with the stuck-PR page at
0.49.298 instead, ahead of C, which waits on the founder's merge; C merges it
in when it records again.
C rewrites the prelude, 0001-0006, but leaves both trap lines as main has
them. An in-memory merge of this branch onto C (`git merge-tree`) was clean,
and 0575 run alone on that merged tree, behind C's prelude including 0005
and 0006, passed 11 of 11 (onepart, bash 3.2). C keeps no list of parts
other than the driver, and the merged driver sources 0575 between 0574 and
0579. Merge C in before the record. If 0573 reds a queue PR's CI before
this lands, it is this flake: rerun the job and name slot 3f.

**Left as found.** `_lwsweep`'s delay-0 runs are signalled before felix has
started. Since the fix they end as the pre-exec subshell dying of the
signal. They still count as "cut", and they test nothing about felix. Making
the sweep wait for exec is the part owner's call.
