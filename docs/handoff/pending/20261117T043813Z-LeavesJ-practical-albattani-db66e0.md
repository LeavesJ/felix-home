### 2026-11-17: the judge's removers each finish, whatever the other is doing (0.49.355)

**Scope.** This section covers the two perl programs in `lib/instrument-run.sh` that remove a judgement's
directories after the judge is gone: the watchdog (`_felix_instr_wdpl`, started by `_felix_instr_watch`) and each
unit's supervisor (`_felix_instr_pl`) on its judge-gone path. The contract is
`docs/2026-11-17-instrument-removers-contract.md` (rev 1, IR1 to IR6). Other `File::Path` callers, and any second
cause of part 2183's A14, are under Open and are not changed.

**Why.** Part 2183's A14 KILLs the judge while one unit sleeps. It sometimes found bind.sh's `felix-objects.*`, or
its `.list`, left under TMPDIR. That refused the pipe-readers branch's dry run on 2026-11-16, and a red run against
main 212830c4 shows the same leftover (`docs/handoff/0gk.md`). Part 2183 runs among the merge judge's units, so the
flake could refuse any machinery PR.

After the KILL, the watchdog and each running unit's supervisor both remove J, R, UP and HP. `File::Path` 2.18
(system perl 5.34) croaks with "cannot chdir to .. from X, aborting" when the other process removes the directory it
stands in. The croak ended the watchdog with status 2 before the bind copy, which it removed last and which nothing
else removes. It also ended the supervisor's single `remove_tree` before R, U, UP and HP.

A croak also leaves the process standing in a directory that no longer exists, and `rmtree` begins with
`getcwd() or return 0`. So catching the croak alone would not have been enough: the next removal would remove
nothing.

**What changed.**
- `lib/instrument-run.sh`: `_felix_instr_rmpl` holds a perl sub, `_rmeach`, that is concatenated into both programs.
  It removes each path on its own:
  - the removal runs in `eval`, then the program returns to `/`;
  - it tries again while the path is there, up to 20 attempts 0.1 s apart;
  - a symbolic link is removed as a link, and a dangling one too.

  The watchdog ends with `_rmeach(@rm)`. The supervisor's judge-gone path ends with
  `_rmeach($jd, $rd, $ud, $up, $hp)` and still exits 125.
- `_felix_instr_watch` hands the watchdog the bind copy and its list first, since only the watchdog removes them.
- `tests/run` sources part 2510 after 2490. It joins one wrapped comment (lines 26 and 27) so that it stays at 500
  lines. That comment is not the one the pipe-readers branch joins.

**Measured.** All on this Mac.
- Outside the suite, on 2026-11-17, the watchdog program was run with a second process removing J at the same moment.
  It left the bind directory in 14 of 20 rounds (the branch's copy) and in 15 of 20 (main's, which is byte-identical).
  Run alone, it left it in 0 of 20.
- Scratch probe: after a croak, the next `remove_tree` left another tree in 5 of 5 rounds. With `chdir "/"` first, it
  left one in 0 of 2.
- Part 2510, blind, run alone on main's engine (0.49.352) at load 7 to 13. Every control and the arming check passed:
  the plain pair died in 5 of 5 rounds, over a J of 8,881 entries that one removal takes 0.31 s on. The race
  assertions were red:
  - the watchdog left its paths in 9 of 20 rounds;
  - the shell's watchdog left them in 4 of 20;
  - the supervisor left them in 7 of 20.

  Each such round exited 2. The part's first run had misread every pid, through a `sed -n '1s/…//gp'` that prints only
  when it substitutes. That was fixed in 001e698a before the red counts above.
- The adversarial review (Opus, read only) found no blocker. Its eight notes led to contract rev 2:
  - IR2's bound is 20 attempts, since no code bounded rev 1's 3 s;
  - IR4 now says which paths are made 0700;
  - IR3's order is asserted;
  - each race must show it collided;
  - no wait in the part is unbounded.

  The part was amended blind from rev 2.
- Part 2510 at rev 2 (22 assertions), run alone, one engine after another, on battery under `caffeinate`, at load
  about 5:

  | Engine | Result | Time |
  | --- | --- | --- |
  | Fixed (this branch) | 22 ok | 118 s |
  | Main's lib (0.49.352) | 16 ok, 6 FAIL | 64 s |
  | Mutant: bind copy passed last again | 21 ok, 1 FAIL | 65 s |
  | Mutant: removal not in `eval` | 17 ok, 5 FAIL | 106 s |
  | Mutant: no return to `/` after a removal that died | 18 ok, 4 FAIL | 290 s |
  | Mutant: one attempt only | 19 ok, 3 FAIL | 104 s |

  - Main's lib fails the order assertion and IR2, IR3 and IR4, each for the paths left and for the exit status.
  - The bind-copy-last mutant fails the order assertion only.
  - The other three fail the race assertions.
  - In every race on every engine, the rival's own removal died in 8 to 20 of the 20 rounds, so the rounds collided.
- The record, the gate and the merge dry run: in the pull request.

**Open.**
- Other `File::Path` callers in the engine. One is `_felix_instr_tcpl`'s scratch directory, which one process owns.
  Others are in other libraries. None was swept for a second remover.
- Whether A14 has a second cause. The pipe-readers note guessed at a watchdog started without the bind copy, which
  would happen when `_FELIX_BIND_OWNER` differs from `_FELIX_INSTR_OWNER`. That was not ruled out here.
- bind.sh's own EXIT trap removes the copy with `rm -rf`. Whether anything else removes it at the same moment was not
  read.
- A removal that fails without croaking now costs up to 20 attempts on that path before the program gives up. One
  example is a file a unit marked immutable with `chflags uchg`. Each attempt walks the tree again, and there are up
  to 2 s of pauses besides. Before, the program gave up after one walk. Nobody waits on these processes after a KILL,
  and the bind copy now goes first, so it is not delayed.
- `_rmeach` checks a path is a directory and not a link, then chmods it by path, so a same-user unit that swaps the
  path for a link in between gets the chmod applied to the link's target. The watchdog already did this. The
  supervisor now does it on five paths, where before it chmodded UP once. That gives such a unit nothing it could not
  already do, and it cannot cause a removal.
- On CI (ubuntu-26.04), the review reasoned, without measuring, that a walk out of a removed directory follows its
  parent and does not croak. If so, part 2510's arming skips its race assertions there. A regression of the fix would
  then show only on this Mac.
