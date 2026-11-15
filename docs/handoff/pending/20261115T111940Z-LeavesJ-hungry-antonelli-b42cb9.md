### 2026-11-15: five more parts hand the engine the suite's git where they narrow PATH to keep a claude CLI or a stub in front, so a /usr/bin/git that refuses to run no longer fails thirty of their assertions (suite only, 0.49.348)

**Scope.** The test files under `engine/harness/tests/` that hold `/usr/bin:/bin`, after part 2300 (#513): why each narrows PATH, whether that hands the engine Apple's `/usr/bin/git`, and the change to the five that fail when it refuses. How the engine reads a git that cannot run, other forms of narrowed PATH, and the gate's checks outside the suite are under Left open and are not changed here.

**Instrument.** The one #513 used: `DEVELOPER_DIR` at a directory whose `usr/bin/xcrun` prints Xcode's licence sentence and exits 69, which makes `/usr/bin/git` refuse exactly as it does from an Xcode update until the licence is accepted. A second copy also logs each call that reaches it, so a run says how many `/usr/bin/git` calls a part made.

```bash
DEVELOPER_DIR=<that directory> engine/harness/tests/run --part <part>
```

**The files.** A grep of this tree finds 22 besides 2300. Each was read before anything was changed. "Red" is the unchanged part under the stand-in; "calls" is how many calls reached the logging stand-in.

| Part | Why it narrows PATH | Red | Calls | Changed |
|---|---|---|---|---|
| 0070 | `felix stack plan` with no claude CLI | 0 of 157 | 0 | no |
| 0330 | `felix ledger` with no claude CLI | 0 of 133 | 3, `rev-parse --show-toplevel` | no |
| 0430 | the two deploy-check helpers with no CLI | 5 of 141 | 0 after | yes |
| 0480 | `NOCLI`: the readiness reader with no CLI | 0 of 144 | 0 | no |
| 0590 | `_NOCLI`: the pre-flight with no CLI | 0 of 127 | 0 | no |
| 0600 | `felix next`'s all-clear with no CLI and an empty home | 0 of 261 | 6: `rev-parse`, `check-ref-format`, `hash-object` | no |
| 0671 | setup, maintenance and stack with no CLI | 0 of 105 | 0 | no |
| 0680 | each block's CLI and hook, so that no claude but the block's own stub is found | 14 of 195 | 0 after | yes |
| 0681 | the CLI, the hook and the readers, behind a stub directory or none | 7 of 310 | 0 after | yes |
| 0710 | the session-start hook, with the stub as the only claude | 2 of 231 | 0 after | yes |
| 0760 | no graphify on PATH | 0 of 132 | 0 | no |
| 0970 | the readiness inventory with a stub claude first | 0 of 99 | 0 | no |
| 1100 | asks whether `/usr/bin:/bin` holds a claude, then reads reach with none | 0 of 292 | 0 | no |
| 1200 | already puts `$(dirname "$(command -v git)")` first | 0 of 122 | 0 | no |
| 1270 | as 1200 | 0 of 73, 1 skip | 0 | no |
| 1281 | a launchd plist's PATH string inside an assertion, not a narrowing | 0 of 129 | 0 | no |
| 1283 | as 1281 | 0 of 112, 2 skips | 0 | no |
| 1670 | the pre-tool hook under `env -i` | 0 of 104 | out of reach; 1 when let through | no |
| 1690 | a branch for a Mac with no `launchctl`, skipped here | 0 of 99, 1 skip | 0 | no |
| 1830 | A25: `felix next` with no claude CLI | 2 of 118 | 0 after | yes |
| 1970 | `felix ledger` with no CLI | 0 of 89 | 3, `rev-parse --show-toplevel` | no |
| 2031 | asks what a PATH of `/usr/bin:/bin` finds; `/usr/bin/git` stays by design | 0 of 78 | 0 | no |
| 2300 | `felix next` with no claude CLI | 9, in #513 | 0 | in #513 |

"Calls" counts only calls that keep `DEVELOPER_DIR`; a call under `env -i` drops it and is not counted. For the changed parts it is the count after the change.


**What changed (five parts).** Each puts a directory holding one link, to `type -P git`, the git the rest of the suite runs, ahead of `/usr/bin` on the PATH it narrows, as 2300's `$ERA/git`. Nothing else is on it, so what each narrowing keeps out (a claude CLI, or everything but a stub) stays out.
- 0430: `$DCK/git`, in the two deploy-check helpers with no CLI.
- 0680: `$_durgit`, made in the first block, put in every block's narrowed PATH (ten sites, the stub directories first), and removed and unset by the last block. One directory for the part, because the part stands at 999 of the 1,000 lines part 1040 allows.
- 0681: `$_duregit`, in its seven narrowed PATHs, behind the stub directory where there is one; removed and unset with the block's other directories.
- 0710: `_cmhook` puts `$_cmgit` first on a PATH it is given, so the four calls that pass `$CMSTUB:/usr/bin:/bin` (one of them inside an assertion) are unchanged; a call with no PATH keeps the suite's.
- 1830: `$B11/git` ahead of A25's `/usr/bin:/bin`, the same PATH 2300 gives `felix next`. The blind part's reading of that PATH in its header says so.

No assertion line is added, removed or changed, so `assertions.tsv` is unchanged.

**Red, then green.** Each changed part was run three ways with `tests/run --part`: unchanged under the stand-in, changed under the logging stand-in, and changed with no stand-in.

| Part | Unchanged, stand-in | Changed, stand-in | Changed, plain |
|---|---|---|---|
| 0430 | 5 FAIL, 136 ok | 141 ok, 0 calls | 141 ok |
| 0680 | 14 FAIL, 181 ok | 195 ok, 0 calls | 195 ok |
| 0681 | 7 FAIL, 303 ok | 310 ok, 0 calls | 310 ok |
| 0710 | 2 FAIL, 229 ok | 231 ok, 0 calls | 231 ok |
| 1830 | 2 FAIL, 116 ok | 118 ok, 0 calls | 118 ok |

Thirty assertions fail before the change and none after, on this Mac, one run of each.

**red.tsv.** Recorded with `tests/run --record-assertions` against origin/main c9bff19b (#514), where this branch now stands; the counts are in the file. A first record, made with `tests/red origin/main` against 6ef98291 before #514 landed (one part at a time, 08:26Z to 11:09Z), read 5 of 17658 failing: two in 0290 (the catalogue refresh its hook forks did not land in time) and three of the "leaves the projects, the state and the memory as it found them" checks, one in 0671 and two in 0680. The engine there differs from this tree's only in its version. Each of the three parts then ran alone in this tree with 0 FAIL (0290 119 ok, 0671 105, 0680 195), and that record was set aside when main moved. For eleven seconds of it (09:35:33Z to 09:35:46Z) another worktree's record ran beside it; which parts were running then was not logged.

**Not blind, and said so.** 1830 was written blind on 2026-10-24; this changes the environment of one reader in it, and the header's reading now says the PATH differs from 0600's.

**Unchanged, and why.** The 17 unchanged parts were run under the logging stand-in as they stand, and none failed (the table's Red and Calls columns). Ten narrow PATH to keep a claude CLI or another tool out, and either make no `/usr/bin/git` call the stand-in sees or make calls whose failure no assertion reads: 0070, 0330, 0480, 0590, 0600, 0671, 0760, 0970, 1100, 1970. Two already put the suite's git first (1200, 1270). Two hold the string in an expected plist, not a PATH (1281, 1283). 1670 runs under `env -i`, and 1690's branch is skipped on a Mac. 2031 asks what that PATH holds, so `/usr/bin/git` stays in it by design.


**Left open.**
- The parts not red under the stand-in that still reach `/usr/bin/git` (the table's calls column) were left alone: no assertion of theirs fails when it refuses, so a change there could not be shown red. A later change to what they assert could make them red the same way.
- 1670 runs the pre-tool hook under `env -i`, which drops `DEVELOPER_DIR`, so the stand-in cannot reach it as written; it was run once with the variable let through its `env -i` (an edit made for that run and reverted) to read what a refusing git does there. That run made one `/usr/bin/git` call (`git remote get-url origin`), and all 104 assertions held; the part is unchanged.
- Other shapes of narrowed PATH were not swept: a grep for `PATH=/usr/bin` alone found one line, in part 0202, and it is lint input in a here-document, not a command.
- `felix_base_resolves` in `lib/resolve.sh` still returns 1 for any failure of git (#513's first open item); branch LeavesJ/epic-wilson-dc82c0 (0.49.347) has it.
- A real licence window also breaks Xcode's other shims in `/usr/bin` (`python3`, `make`, `clang` and the rest), which a narrowed PATH would also hand a part. Only git was looked at.
