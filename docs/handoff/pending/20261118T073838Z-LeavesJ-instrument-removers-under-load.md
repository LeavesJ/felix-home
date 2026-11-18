### 2026-11-18: the judge's removers retry a path for up to 30 s, not 20 attempts (0.49.358)

**Scope.** This section covers `_rmeach`, the removal routine that the watchdog and a gone judge's supervisors share
in `lib/instrument-run.sh`, and part 2510, which tests it. The contract is
`docs/2026-11-17-instrument-removers-contract.md`, now rev 4. Which of two candidates failed the red pass that led
here is under Open and is not settled.

**Why.** On 2026-11-18 the pipe-readers branch's record ran its red pass against main b03e7c10 (0.49.355). That
pass ran at -j 6 beside the record's own suite, at load 21 to 28. It failed part 2510's two IR4 race assertions,
which had passed in the record's own run. The red log went with its temporary directory, so two candidates were not
told apart:
- the part's own 10 s limit on each program;
- `_rmeach`'s 20 attempts, 0.1 s apart.

The second was read from File::Path's walk, and not measured. When two processes walk the same tree, the one behind
keeps dying, because the one ahead removes each directory the trailing one has just entered. So once the program has
died once, it dies on every attempt until the other process ends. Twenty attempts are about 2 s plus the walks, and
a loaded host can make the other process outlast that. A unit still writing into J before its supervisor ends it
does the same. A bound in time does not depend on the host's speed.

**What changed.**
- `lib/instrument-run.sh`: `_rmeach` tries a path again while it is there, 0.1 s apart, for up to 30 s on that path.
  The last attempt can run past 30 s by its own walk. Before, it made up to 20 attempts. Nothing else in the two
  programs changed.
- The contract:
  - rev 3: IR2's bound is 30 s a path, and IR4 reads "within IR2's 30 s". IR6 says the part's limits on each
    program sit above 30 s. A rival removes and remakes what is under J for about 4 s, then stops with J still there.
  - rev 4: such a round counts only when it outlasted the program, that is, when the rival made something and J was
    still there as it stopped. Rounds go on until 5 have outlasted, 10 at most. For the supervisor, the rival starts
    at PARENT gone. The cost clause says what the part takes.
- Part 2510, amended blind from rev 3 and then rev 4, now has 24 assertions:
  - every wait on a program while it removes is 45 s, where it was 10 s (6 s in IR3);
  - two assertions are new, one for the watchdog and one for the supervisor's judge-gone path. In each, a worker
    turns over what is under J until 4.2 s after PARENT is gone (the watchdog) or after the unit's group is gone
    (the supervisor).
- `engine/.claude-plugin/plugin.json`: 0.49.358. 0.49.356 is #520, and 0.49.357 is the pipe-readers branch.

**Measured.** All on this Mac, each run of part 2510 alone, one engine after another, on battery under `caffeinate`.
- At rev 3 (7142c0ae), 05:42 to 05:51Z, at load about 4 to 6:

  | Engine | Result | Time |
  | --- | --- | --- |
  | Fixed (this branch) | 23 ok, 1 FAIL | 144 s |
  | Main's lib (0.49.355) | 22 ok, 2 FAIL | 146 s |
  | Mutant: a 3 s bound | 22 ok, 2 FAIL | 144 s |

  The fixed engine's FAIL was the part's own. In 2 of the supervisor's 5 worker rounds, the worker found J already
  gone and made nothing, and rev 3's part counted that as a fixture failure. That led to contract rev 4 (be2f27f8)
  and the part's amendment from it (4340b9eb).
- At rev 4, with the lid open and no sleep in the power log over any counted run:

  | Engine | Result | Time | Worker rounds: watchdog, supervisor |
  | --- | --- | --- | --- |
  | Fixed (this branch) | 24 ok | 156 s | 5 of 7 outlasted; 5 of 6 outlasted |
  | Main's lib (0.49.355) | 22 ok, 2 FAIL | 116 s | J left in 5 of 5; in 5 of 7 |
  | Mutant: a 3 s bound | 22 ok, 2 FAIL | 163 s | J left in 5 of 8; in 5 of 6 |

  Main's lib and the mutant fail only the two worker assertions.
- A first run of main's lib and the mutant at rev 4 is not counted. The lid closed at 05:59Z, and the power log shows
  that run in dark-wake slices. In it, each program once reached the part's 45 s limit with nothing removed, and
  IR3's order assertion saw no look in one round. Both fit processes frozen while the wall clock ran on.
- The record, the gate and the merge dry run: in the pull request.

**Open.**
- Which candidate failed the red pass. A rerun at that load, with its log kept, would tell them apart.
- A removal that fails without croaking now costs up to 30 s on each path before the program gives up, where #521's
  limit was 20 attempts. A file a unit marked immutable with `chflags uchg` is one example. That makes up to 150 s
  over the supervisor's five paths. Nobody waits on these processes after a KILL. The bind copy still goes first, so
  it is not delayed.
- The worker makes and removes about 500 trees of 125 entries in each of its rounds. After the slept run,
  `fseventsd` was at about 100% CPU. Whether the part's churn slows the parts beside it in a record was not measured.
- What #521's section left open still stands:
  - other `File::Path` callers;
  - a second cause of part 2183's A14;
  - bind.sh's own `rm -rf`;
  - the chmod TOCTOU;
  - CI on Linux probably skipping the race assertions.
