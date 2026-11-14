### 2026-11-14: part 2300 hands felix next the suite's git, so a /usr/bin/git that refuses to run, as one did during a gate while Xcode updated, no longer fails its nine next assertions (suite only, 0.49.345)

**Scope.** Why part 2300 failed nine `felix next` assertions in one full gate on 2026-11-14 (09:24Z to 09:53Z, commit 74d46a11, #512's fold, engine 0.49.343) and passed alone, and the change to that part. How the engine reads a git that cannot run, and the other parts that narrow PATH the same way, are under Left open and are not changed here.

**Cause.** The App Store installed Xcode 27.2 while that gate ran. `/var/log/install.log` records the swap of `/Applications/Xcode.app` at 09:36:10Z, and `/Library/Preferences/com.apple.dt.Xcode.plist` was rewritten with the 27.2 licence at 09:39:14Z by an `xcodebuild` started from Terminal. Between the two, `/usr/bin/git`, Xcode's shim, exits 69 on every call (the memory note of 2026-10-12 on the licence). Part 2300 runs every reader with the suite's git but one: `felix next` runs under `env PATH="/usr/bin:/bin"`, as 1830 A25 runs it, so that no claude CLI is found, and that PATH hands it `/usr/bin/git`. With git refusing, next said the base `refs/heads/era-base` names nothing and the tree has no green gate receipt. Its evidence row then held no "not judged", and the nine assertions that wait for one failed: C5's agreement and R's four states, A5 and A6. The next assertions of C1 and C3 passed in the same run, because they expect no such row.

**Evidence that it was this, in that run.**
- The unified log has `/usr/bin/git` processes from 09:36:57Z to 09:37:58Z in seven bursts of five, inside the window. Part 2300 runs next over seven states: C1, C3, C5 and R's four.
- Run alone with `/usr/bin/git` made to exit 69 (below), the part's next calls make 35 calls to it, five a call. Run alone as it is, the log shows seven bursts of 53. Five a call is what a refusing git gives here; 53 is what a working one gives.
- The other `/usr/bin/git` bursts of that run (09:24Z to 09:28Z, 09:32Z, 09:42Z, 09:46Z) fall outside the window, and nothing else in the run failed.
- Not separable: in the green gate that followed (10:01Z to 10:31Z), other parts' `/usr/bin/git` calls overlap the part's, and splitting the calls at gaps of one or two seconds did not separate its bursts there.

**Reproduced on demand.** A `DEVELOPER_DIR` whose `usr/bin/xcrun` prints the licence sentence and exits 69 makes Apple's `/usr/bin/git` shim do the same, and the part's `env PATH=... HOME=...` keeps the variable:

```bash
DEVELOPER_DIR=<that directory> engine/harness/tests/run --part 2300-evidence-readers-agree-blind.sh
```

- Unchanged part, twice (a `DEVELOPER_DIR` that does not exist, then the exit-69 stand-in): 9 FAIL each time, the gate log's nine names, and C5's failure text byte for byte.
- Unchanged part, plain: 156 ok, 0 FAIL.

**What changed (one part).** `$ERA/git` holds one link, to `type -P git`, the git every other reader in the part runs, and next's PATH is `$ERA/git:/usr/bin:/bin`. Nothing else is on it that was not there before, so the claude CLI stays out of reach. The changed part under the exit-69 stand-in: 156 ok, 0 FAIL, and no call reached the stand-in. Plain: 156 ok, 0 FAIL. No assertion is added, removed or renamed, so `assertions.tsv` is unchanged. `red.tsv` is recorded again, because part 1010 asks that the record name the engine origin/main held where this tree branched from it (04755345, 0.49.343), and the old record named 6451e295: against it, 0 of 17658 assertions fail (17610 pass, 48 skip). That run cannot show this red, since it runs this tree's assertions against the base's engine with a git that works, and no engine file changed; the red is the stand-in runs above.

**Not blind, and said so.** This changes the environment of one reader in a part written blind on 2026-11-05 and 06. Amendment 3's reading in its header now says the PATH differs from A25's, and the comment above `_era_read` says why.

**Left open.**
- `felix next` printed "this base names nothing here" and "this tree has no green gate receipt" while git could not run, and both were untrue then: the ref and the receipt existed. `felix_base_resolves` in `lib/resolve.sh` returns 1 for any failure of git. Changing that is an engine change in the adversarial tier and belongs to a session of its own.
- 22 other files under `engine/harness/tests/` hold `/usr/bin:/bin` (a grep of this tree), 0430 and 0710 among them, which failed nine assertions the same way on 2026-10-12. Whether each hands the engine `/usr/bin/git` depends on why it narrows PATH (2031 tests what is on PATH), so each is read before it is changed.
- Whether the gate's own checks outside the suite are exposed to the same window was not looked at.
