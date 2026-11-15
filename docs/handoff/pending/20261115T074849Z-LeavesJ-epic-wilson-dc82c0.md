### 2026-11-14: a git that cannot run is told apart from a base that names nothing and from a tree that changed (0.49.347)

**Scope.** How the readers of a base (`felix_base_resolves`) and of the gate receipt (`felix_verify_current`) say a git that could not run, and the sentences `felix merge` prints about it. The contract is `docs/2026-11-14-git-cannot-run-contract.md` (rev 3, GR1 to GR8). The other readers of a git failure are under Open and are not changed.

**Why.** On 2026-11-14 an Xcode update left `/usr/bin/git`, Apple's shim, exiting 69 until the licence was accepted, during a full gate (cause: the pending section of LeavesJ/jolly-robinson-049cab, #513). `felix next` with that git said the base names nothing and the tree has no green receipt; the ref and the receipt existed. `felix_base_resolves` failed for any failure of git, and `felix_verify_current` found no receipt, because its path is a hash git computes, and read an empty tree id as a changed tree.

**What changed.**
- `lib/resolve.sh`: `felix_git_runs [VAR]` asks `git --version`, only after a git call has already failed. Non-zero is a git that could not run, and VAR holds "git could not run here (git --version exited N)". `felix_base_resolves` returns 2 then and fills a third argument with that clause; a base that names nothing returns exactly 1, where it gave git's 128. A caller that only asks whether it resolved reads 2 as 1, so `felix_land_owed` and `felix_land_would_refuse` are unchanged. `felix_base_subject` quotes a base spelled `GIT`, `CHANGED-PATHS`, `ADDED-LINES` or `SUITE`, so a reader that branches on those subjects does not take a base that names nothing for one of them.
- `lib/evidence.sh`, `lib/escape.sh`, `lib/classify.sh`: the row is `unknown`, subject `GIT` (a pseudo-subject like `CHANGED-PATHS`), and the reason starts with the clause and names the base.
- `lib/verify.sh`: when the receipt's path cannot be hashed, or a green receipt's tree id is empty, and git could not run, the answer is `stale`, the clause, "so this tree cannot be identified and no receipt can be confirmed for it", with status 2. A receipt handed in that is empty (`none`) or not green (`red`) is read without git and is unchanged.
- Readers: `felix next` (the action is "make git run here, then run this again"), `felix evidence`, `felix classify`, `felix scope`, `felix pr`, `felix status` (the gate row is `unknown`), `felix merge` (where it cannot read the base's commit, and, after the base was read, a closing paragraph about git that replaces "The rest escapes nothing") and the Stop hook (the hold names the clause, not a named pipe, and says no gate run can record a receipt; its detail stays `tree unknown`).

**Measured.** All on this Mac, one part run at a time.
- Part 2490 (blind, rev 2): 25 of 113 assertions failed on main's engine (3ecdfcf9); 113 of 113 passed on 61924e71.
- Its rev 3 assertions (11, written blind from the review's three should-fix items): 8 of 124 failed on 61924e71; after the fixes, 124 of 124 passed. One of the 8 found that `felix merge` still ended on "The rest escapes nothing" after a scan that never ran.
- Part 1100 (the 500-line cap on `lib/status.sh`, which a first draft broke at 506): 292 of 292.
- The full record and gate: in this PR's receipts.

**Open.**
- Other readers of a git failure: the Stop hook allows a stop unchecked when its own `git rev-parse --git-dir` fails; the receipt document leaves `tree` out of `unknown` when git cannot run (`receipt.sh`); the merge boundary reads `none` for a receipt it could not find (`escape.sh`); under the exit-69 stand-in `felix next` in this checkout also listed "upkeep due: graphify", which a working git did not (seen once, not traced); `felix_tree_id`'s other callers.
- A git that stops running partway through the Stop hook gets a hold without the clause; the lander classes the refusal a git that stopped mid-judge causes as final.
- A git that answers `--version` and fails every other call reads as before; a git that starts or stops running between the failed call and the probe is read by the probe.
- The 22 test files that narrow `PATH` to `/usr/bin:/bin`; whether `felix gate`'s own checks outside the suite are exposed.
