### 2026-10-08: `felix autonomy` has one writer at a time

This was found on 2026-10-02 by the adversarial review of
claude/autonomy-revoke-fails-closed and left unfixed there, because the race
predates that branch: main's `grep -vxF > autonomy.new && mv` was the same
unlocked read-modify-write. One pull request carries three branches, as the
carrier ruled: revoke revision 3, this writer lock, and
claude/autonomy-allow-fails-closed. Without the lock, the allow fix makes the
race worse.

**Defect closed.** `cmd_autonomy` rewrote `projects/<p>/autonomy` with nothing
held. Run A (`--revoke commission`) read the file. Run B (`--revoke tidy`)
then read, rewrote, moved, read back, and printed `revoked: tidy` with exit 0.
Then A's mv landed A's copy, which still held tidy. tidy is the grant that
deletes files at session start. A revoke racing an `--allow` lost the allow's
line the same way. Once `--allow` became a rewrite (felix_autonomy_grant), a
slower grant could also bring back a tidy that had been reported revoked,
which the old append never could.

**Mechanism.**
- **The lock.** `felix_autonomy_guard` (lib/autonomy.sh) is called from
  `cmd_autonomy` once arguments are validated, by any run given `--allow` or
  `--revoke`. It takes `projects/<p>/autonomy.lock` with mkdir and records the
  directory's inode. The lock is held through the revoke, the grant, both
  read-backs, the stamp write and the status page, and released only by the
  EXIT trap.
- **What the lock is.** An empty directory, which git does not track.
  FELIX_ESCAPE_AUTHORITY matches the name and never fires on it; escape.sh now
  says so.
- **A held lock is refused, never taken over.** The run exits 1, writes
  nothing, and prints no `allowed:` or `revoked:`. Its message:
  - says `not allowed` / `not revoked`;
  - names the lock;
  - says when the lock is more than a minute old;
  - says a stopped (Ctrl-Z) run still holds its lock;
  - gives `rmdir <path>`, quoted with %q.

  An unwritable project directory gets its own message.
- **Signals.** Every catchable signal that bash turns into an early exit is
  handled:
  - trapped: HUP INT QUIT PIPE ALRM TERM USR1 USR2 XCPU XFSZ VTALRM PROF
    ABRT TRAP SYS EMT (EMT exists on macOS only), and ILL FPE BUS SEGV;
  - ILL FPE BUS SEGV are never ignored, not even around mkdir, because an
    ignored signal is inherited and a child that really faults would then
    spin.
  - bash runs a trap only after the foreground command returns, so a rename in
    flight lands while the lock is still held.
  - While the lock is being taken, a signal is only noted, and acted on once
    the inode is recorded.
  - The release ignores every signal first. It removes the writer's temp file
    (`_FELIX_AUTONOMY_TMP`, an exact name set in the same command as mktemp),
    then the lock with `find -inum -empty -exec rmdir`. So it removes only the
    directory this run made, and only while it is empty. The run keeps that
    directory open, on the first of fds 9 to 3 it did not inherit, until
    then, so its inode number cannot be handed to another run's lock.
  - A signal handler releases before it exits, so a signal that arrives as
    the EXIT trap starts cannot cut the release short.
  - Nothing on the release path substitutes a command, because on bash 3.2 a
    failed write to a closed pipe leaves text in the stdout buffer for a
    substitution to capture.
- **Readers take nothing.** A rewrite lands by rename.

**Decided.**
- **Refuse rather than wait.** A run holds the lock for well under a second,
  and a person retypes.
- **No takeover, by age or by dead pid.** Takeover is the window in which two
  takers both write. No pid is kept inside the lock, because that would make
  it a file git can track.
- **A no-op revoke in a read-only project directory now refuses.** Revision 3
  of the revoke fix let it say `revoked:`. The brief says nothing prints
  `revoked:` or `allowed:` without the lock. Agreed with the revoke session;
  the amended assertion is commit 8594eba9.

**Built as contract, blind assertions, fix, review, then again.**
- **Round 1.**
  - An Opus agent wrote 64 assertions from contract L1-L8 (7e769251), blind
    to the fix.
  - Section runner (preamble 1-224):
    - against the revoke head 85ab3f7a: 36 fail;
    - against main 6fe5f986: 46 fail;
    - against fix a639e455: 64/64 pass.
- **Review 1, two Opus reviewers.**
  - *Fail-open hunt.* Every finding was reproduced on bash 3.2:
    - H1: ALRM, USR1 and the rest ran the EXIT trap at once, mid-mv, and tidy
      came back.
    - H2: the lock a person removed by hand was followed by the next run's lock
      being removed.
    - M1: a closed or piped stdout leaked the lock through the stdout buffer.
    - M2: a signal between the mkdir and its record leaked the lock.
    - M3: a second signal during the release leaked it.
    - M4: QUIT and PROF killed the run without the trap.
  - *Mutation test.* 14 of 19 mutants killed. Its 9 follow-up assertions
    (a00c2bec) kill the 5 survivors: no signal traps, early release, takeover
    by age, rm -rf, no INT trap.
- **Revision 2 (29f01865)** closes all of them. On the six autonomy blocks
  (reader, revoke 1-3, allow, lock): 358/0/0.
- **Round 2.** A second blind author wrote 73 assertions from contract
  L9-L16 (c94b1f8b): every fatal signal, a dead stdout, signals at any
  moment, a lock a person replaced, a lock with contents, a dated lock, the
  advice, and temp files.
  - Section runner, that block alone:
    - against revision 1 (a00c2bec): 23 fail;
    - against main 6fe5f986: 31 fail;
    - against revision 2 (29f01865): 73/73 pass.
  - The author also raised a case it could not make deterministic: a Ctrl-C
    held down on the process group can kill mkdir after the directory exists.
    mkdir then reports failure, the run takes its own lock for another's, and
    the lock outlives it. a068acb3 runs mkdir and ls with the signals ignored.
- **Review 2, one Opus reviewer, of revision 2.** Each finding was
  reproduced on bash 3.2:
  - F1: a signal pending as the EXIT trap started ran its handler first, and
    the handler's exit cut the release short, so the lock leaked.
  - F2: ABRT, TRAP, SYS and EMT ran the EXIT trap at once, mid-mv, as ALRM
    had in round 1. A sent ILL, FPE, BUS or SEGV did the same.
  - F3: `--revoke X --allow Y` with stdout closed. The failed `revoked:`
    stayed in bash 3.2's buffer, and the grant's mktemp substitution captured
    it into the temp file's name, so the real temp file was left behind.
  - F4: a Ctrl-C between mktemp making the file and its name reaching the
    shell left the file.
  - F5: a find that failed during the release left the lock with no word.
  - S1: on Linux, a freed inode number can come straight back. A person's
    rmdir followed by another run's mkdir could get the same inode, and this
    run would then remove that run's lock.
- **Revision 3 (0877707e)** closes all six:
  - the handler releases before it exits;
  - the four signals wait like the rest, and the other four are ignored;
  - a closed stdout goes to /dev/null before anything prints;
  - mktemp ignores the signals;
  - a failed find says so;
  - the lock directory stays open on fd 9 until its release, so its inode
    cannot be reused.

  On every autonomy block (reader, revoke 1-4, allow, both lock blocks, the
  stamp): 473/0/0.
- **Review 2's assertions (51960255), not blind.** The reviewer turned its
  repros into 48 assertions at the end of the round-2 block. 27 fail on
  a068acb3:

  | Finding | Assertions | Fail on a068acb3 |
  |---|---|---|
  | F1 | 2 | 1 |
  | F2 | 35 | 16 |
  | F3 | 5 | 5 |
  | F4 | 2 | 2 |
  | F5 | 2 | 2 |
  | S1 | 2 | 1 |

  The other 21 pass on both engines by design: they check the state after
  the run ends, which a068acb3 also got right.

  On the whole range, 21841-24156: 521/0/0 on the tree. On a068acb3 it is
  472/49, of which 22 are revoke revision 4's, which a068acb3 predates.

  What is built rather than caught:
  - F1's window is microseconds. The assertion builds the state bash is in
    at that moment: an EXIT trap that runs the handler before the release.
  - F4 is widened by a mktemp shim that pauses between making the file and
    printing its name.
  - S1 cannot fail on macOS, because APFS never reuses inode numbers. The
    assertion reads the mechanism, fd 9, through lsof or /proc, and is
    skipped where neither exists.
  - EMT is skipped where `kill -l` does not know it (Linux).
  - F5's unreadable lock is skipped as root.
  - F3 was measured red on bash 3.2 only.
- **Review 3, one Opus reviewer, of revision 3.** It found no fail-open path.
  The reviewer reported four findings; three were reproduced:
  - **Data loss.** `--revoke tidy --allow commission` with a stdout that is
    open but refuses writes (a read-only fd 1, or a dead pipe with SIGPIPE
    ignored) emptied the grant file:
    1. The failed `revoked:` stayed in bash 3.2's stdout buffer.
    2. The grant's `$(( $(wc -c < "$f") ))` captured it.
    3. `set -u` stopped the grant's subshell, and bash 3.2 ended it with
       status 0. That happens only when bash runs a script file; under
       `bash -c` it is 127.
    4. The grant took 0 for "written", and moved its empty temp file over
       the grants.

    Revision 3's upfront check caught only a closed stdout.
  - **Hang.** An ignored signal is inherited, so with ILL, FPE, BUS and SEGV
    ignored, a child that really faulted spun on macOS instead of dying.
    The run hung holding the lock.
  - **fd 9.** fd 9 was taken whatever it held, so a caller's flock on fd 9
    was let go.
  - **Not reproduced.** The reviewer reported "Ctrl-C during the lock's
    mktemp is dropped". That was its probe: a job started with `&` in a
    non-interactive script begins with INT ignored, and bash cannot trap a
    signal ignored at entry. With job control on, INT gives exit 130 and
    nothing is written.
- **Revision 4 (6c85784a, tests f45cac5b):**
  - ILL, FPE, BUS and SEGV are trapped like the rest, and never ignored, so
    a child's fault ends the child.
  - Every line that says what was written prints from a child
    (`felix_autonomy_say`). Once one fails, stdout goes to /dev/null. That
    replaces the upfront check.
  - The grant's subshell exits 10 for "written", and 0 counts as failure.
  - The lock is held open on the first of fds 9 to 3 the run did not
    inherit.
  - The bash 3.2 `set -u` status bug is engine-wide, and is filed as a
    separate task. The revoke session has been told that its second pass
    has the same shape.
- **Review 3's assertions, not blind.** Six new assertions, and ILL, FPE,
  BUS and SEGV join the signals that wait:
  - a child that faults dies;
  - two cases with a read-only stdout, checking the grants and the stamp;
  - a grant subshell that `set -u` stops is refused;
  - a caller's fd 9 survives.

  Against revision 3 (0877707e), 10 fail: the 6, plus "exits non-zero" for
  each of the 4 fault signals. On the whole range, 21841-24201: 548/0/0 on
  the tree. Red was measured on bash 3.2. On 5.2 the grant-status assertion
  passes against revision 3 as well.
- **Revoke revision 5 merged (c56a5ff5).** The revoke session took the
  `set -u` status bug into both revoke passes and into felix_autonomy_allows,
  which now answers a grant with 10. On revision 4, an arithmetic stop in
  the reader answered "granted"; that one was fail-open. The only conflict was
  the second pass's lines next to the lock's mktemp, and both sides are
  kept. On every autonomy block (21841-24382): 582/0/0.
- **Revoke blind block 7 merged (12bc2b12).** It holds `set -u` stops run
  as a script, and changes tests only. On every autonomy block
  (21841-24466): 591/0/0.
- **Review 4, one Opus reviewer, of revision 4.** No fail-open path and no
  data loss.
  - Checked and sound:
    - a stdout that refuses writes, in every form tried (read-only, closed,
      a broken pipe with SIGPIPE ignored or default, `| head -1`, closed
      fds 0, 1 and 2 together);
    - every fault and async signal sent mid-mv, to revoke and to allow;
    - signals during the lock's own mkdir;
    - the fd probe, checked with lsof, including `ulimit -n` of 12 or less;
    - exit 10;
    - a file size limit;
    - a real terminal, where Ctrl-C mid-mv gives 130 and leaves the file
      consistent.
  - Three findings, all older than revision 4:
    - The stamp write is unchecked, and "stamped against commissioning.tsv"
      prints after a stamp write that failed. Fail-closed: the stamp is
      stale, the status page says `[!]` and the unattended run refuses.
      claude/project-writes-refuse-nonregular already fixes this (its
      felix_replace_file, then "stamped" only on success), so it is left to
      that branch. Its session is told that cmd_autonomy's status lines are
      felix_autonomy_say now.
    - With stderr refusing writes, `die`'s text comes out on stdout at exit.
      Cosmetic: the lock is released and the file untouched.
    - Faults ignored by whoever started felix cannot be trapped, so a child
      that really faults still spins with the lock held. Fail-closed, and
      outside what bash allows. The comment now says so.

**Red evidence, per block, for the PR body.**
- Revoke: in its own pending note.
- Allow, as its session states it:
  - The blind block has 117 assertions, written from the contract by an agent
    that had not read the fix. 71/117 fail against origin/main 6fe5f986,
    69/117 against the revoke base 920ccdb8, and 0/117 on the fix 1c347cbb.
  - The whole block as it stands has 142: the 117 blind ones, 23 from the
    mutation and fail-open reviews, and 2 for the file mode. The 25 that are
    not blind are marked "not blind". 89/142 fail against main 6fe5f986.
  - Each of the 7 review groups (25 assertions) kills its mutant: at least
    one assertion in the group fails on it, and all of them pass on the fix.
    The groups are a short read, a read-only file, a leaked write tail,
    read-back rc 3, a 2040-byte cut, the capability check (2 assertions) and
    the mode (2 assertions). Group 5 kills its in-place-append mutant on macOS
    only; on Linux that is reasoned, not measured.
  - It was run on a section runner: the preamble through the line before
    `printf '\nresolution\n'`, with REAL_HARNESS set to a
    `git archive origin/main engine` export.
  - Only bash 3.2 was run locally. CI's 5.2 is the first run there.
- Lock: as above.

**Handed on, not done here.**
- A lock left by SIGKILL, power loss or a crash stays until a person removes
  it. The refusal says how.
- iCloud could, in principle, restore a removed lock or add a file inside one.
  Unconfirmed: the home lives in iCloud Documents and could not be tested.
- Exit statuses for USR1, USR2 and SYS use Linux's numbers on every
  platform. Nothing reads them.
- A fatal signal bash does not handle at all (IO, PWR and STKFLT on Linux)
  kills the run outright. The mv lands and the lock stays, so the next run
  refuses. That is a leak, never a regrant.
- A real fault in bash itself (not in a child) would re-run under the
  handler and hang the run with the lock held. That is reasoned, not
  measured.
- Faults ignored by whoever started felix stay ignored, because bash cannot
  trap a signal ignored at entry. A child that really faults then spins
  with the lock held until it is killed.
- With stderr refusing writes, `die`'s message lands on stdout at exit.
  Cosmetic.
- An unchecked stamp write, which then says "stamped": left to
  claude/project-writes-refuse-nonregular, which fixes it.
- Exit statuses for ILL, FPE, BUS and SEGV use Linux's numbers too, and
  BUS's differs on macOS.
- bash 3.2's `set -u` status bug is engine-wide. It is filed as its own
  task.
- The stamp branch's refusal wording: done. claude/project-writes-refuse-nonregular
  said "nothing was written for commission", which is untrue for
  `--revoke X --allow commission`, where the revoke has already written. Its
  session fixed the wording in 81bab858 ("no commission grant or stamp was
  written").
- adopt-newline (.274), once it is on main: its block-1 assertion about a
  grant ending in a NUL byte must become "refused and byte-identical". The
  allow fix's pending note says so.

**Landing.** In the carrier's 2026-10-08 batch (state file
`~/.felix/memory/felix/audits/2026-10-08-carrier/state.md`), after .274, as
one PR with revoke at .275 if all three are ready together, otherwise after
it. No table under projects/, no escape table and no commission table is
touched. The version is the carrier's to assign, and the record and gate run
only on its "you are next".
