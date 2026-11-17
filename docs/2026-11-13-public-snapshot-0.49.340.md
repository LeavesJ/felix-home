# The public snapshot: staged 2026-11-13 at 0.49.340, published 2026-11-17 at 0.49.352

**Scope.** This covers the public snapshot at `github.com/LeavesJ/Felix`. The
outcome section records the cut that was published on 2026-11-17, from
felix-home's main at `debec2c3` (engine 0.49.352). The sections after it record
what one overnight session staged and audited on 2026-11-13 from main at
`cf0cb744` (engine 0.49.340), before anything was pushed. The last section lists
what is still unchecked, including three questions left open for a design
session.

## Outcome: published 2026-11-17 as engine 0.49.352

You answered "Land fixes, then publish". These steps followed.

- **The fixes landed in felix-home.**
    - PR #514 (0.49.346) carried part 1860's fixtures, the 92 acknowledgements
      you turned on, and the README link.
    - The first real cut, from main at `c9bff19b` on 2026-11-15, passed its
      scrub and audit, then stopped in its own suite: 25 failures in six parts
      that read what the snapshot withholds.
    - PR #517 (0.49.352) fixed those six parts. Its one escape line, part
      2400's renamed assertion, landed with your "Rename it, land all six".
    - PRs #515, #516 and #518 landed in between.
- **The cut.** `snapshot.sh` ran from main at `debec2c3`, 01:14Z to 03:09Z. Its
  audit: 17 names derived, 8 rewritten, 98 lines acknowledged, none open. The
  secret scan found 4 hits, all planted fixtures already public. The suite on
  the staged commit `7896763`: 17746 passed, 0 failed, 115 skipped.
- **What changed since the 2026-11-15 cut:** 34 files, all from #515 to #518.
  The wider audit described below ran over those 34 files, the PR body and the
  commit message, with its private inputs read afresh from the home. It found
  no leak:
    - one name, the author field in `plugin.json`, as on the public main;
    - generic paths only, such as `/Users/Shared/felix-authority`;
    - fixture addresses: `example` and `.invalid` domains, and SSH users such
      as `git@github.com`;
    - 12-word runs shared with private files, which are those files quoting
      the engine.
- **Install test**, as described below, on the staged branch:
    - the install exited 0;
    - `felix@felix` 0.49.352 is enabled;
    - the plugin cache is byte-identical to `engine/`, with no version bump;
    - `felix which` binds the scratch project;
    - the real HOME's pointer and plugin registry are unchanged.
- **Published.** Branch `snapshot/2026-11-16` was pushed; no `main` was pushed.
  LeavesJ/Felix#7 carried it. Its CI, the suite run serially on ubuntu-latest,
  passed in 1h50m, and #7 was merged with a merge commit as `c98268bd`. The
  public main's tree is the staged commit's tree. `felix maintenance --ran
  snapshot` recorded the run.
- **Public change:** engine 0.49.232 to 0.49.352; 504 files, 402 added, 102
  modified and none removed; +163,754 / −27,563 lines.

## Where it stood on 2026-11-13

**Main cannot be cut as it is.** `snapshot.sh` stops on it twice, as it is
designed to, and both stops are in suite part 1860 (#475, 2026-10-29, after the
last snapshot):

- `webapp` has been a governed project on main since #388 (2026-10-01). Part 1860
  used it as a fixture project's name in shell code, where the scrub's phrase
  would split one word into four.
- Part 1860 used a governed project's private remote as fixture data. The scrub
  rewrites the repository part and leaves the owner next to it, and the run stops
  there.

**Then the audit stops on 92 lines** that no acknowledgement covers. It also stops
on `zz`, an empty directory the memory root has held since 2026-10-01, which is
too short to search for. I read the 33 lines that are not `git@github.com`
remotes in full, and for the other 59 I read the remote each one names. None names a project or a
person (see the table under the audit).

**Four local commits fix everything tonight's run stopped on.** They are on branch
`LeavesJ/gifted-bouman-2e0b89`. None is pushed or gated:

| Commit | What |
|---|---|
| `f628a788` | part 1860: the fixture `webapp` is now `website` |
| `51888420` | part 1860: the fixture remote is now `Acme/Atlas` |
| `0c574c90` | `.snapshot-ack.tsv`: 92 rows and an `@name zz` row, **commented out** for you to turn on |
| `bf402aa2` | README: the "Designed, not built" row no longer links into `docs/`, which the snapshot withholds |

**I cut a preview from main plus those commits.** The 92 rows were turned on only
in a scratch copy. The preview passes `snapshot.sh`'s scrub and audit, my wider
audit found no leak in it, and `felix install` from it works in a scratch HOME.
I made three changes to a scratch copy of `snapshot.sh` for this run. I removed
the suite step (a constraint on tonight's work), relaxed the check that the source
is on main, and pointed the acknowledgements at the scratch file.

## What changes publicly

| | Public now | Staged |
|---|---|---|
| Engine | 0.49.232 (2026-09-26) | 0.49.340, or whatever main holds once the fixes land: 0.49.341 at the earliest, since two open PRs hold 0.49.339 |
| Files | | 480 changed: 378 added, 102 modified, none removed; +156,174 / −27,533 lines |
| Commands | 51 in `felix` help | 57: adds `cost`, `inventory`, `land`, `lane`, `situations` and `status`, and removes none |

Most of the added files are the suite's 266 parts, because `tests/run` was split
into parts on 2026-10-11. Another 51 are new engine libraries. Four new project
tables are published: `land.tsv`, `lanes.tsv`, `lane-next.tsv` and
`partition.tsv`. The README gains 75 lines and loses 53, mostly where claims
were reworded more narrowly. `LICENSE` and the public `suite.yml` are unchanged.

## What the audit looked for, and found

**`snapshot.sh`'s own audit:**

- 17 names derived and 8 rewritten.
- 98 lines changed, each on a name.
- 98 lines acknowledged: 4 by existing rows, and 94 hits on 92 lines by the
  proposed rows.
- secret-scan: 4 hits, all planted fixtures that are already public.
- It printed 7 lines that the scrub rewrote from halves or stand-ins, for a person
  to read. I read them. All are fixture spellings of one project, and all were
  rewritten correctly.

**A wider net, written separately from the scrub**, reading every file as bytes:

| Looked for | Found |
|---|---|
| 70 names: the governed projects; the account's 12 repositories, 6 of them private; four third-party owners from remotes on disk; people, schools, organizations and applications from your memory and disk; the machine login. In any case, with up to two separators between letters, with one character standing in, and in base64 and hex | Your name, only where it is already the public author and copyright holder. No other name |
| Private paths: `/Users/`, iCloud, scratch, `.claude/projects`, worktrees, the notes folder | Fixtures such as `/Users/x` and `.claude/worktrees/gone6`, and the engine's own paths such as `~/Library/Logs/felix`. No path from this machine |
| Addresses | Your gmail address once, in `projects/felix/snapshot.sh`. It is already public there and on 12 public commits. The other addresses are fixtures, plus Claude Code's public trailer address |
| 1,082 real session ids and 266 real worktree names | No session id. Two worktree names that are also fixture names in tests |
| Credential shapes (18 kinds) and phone numbers | Planted examples only, such as AWS's documented example key. No phone number |
| 12-word runs shared with 532 private files: `docs/`, `HANDOFF.md`, `strategy/`, `.claude/`, `cloud-verify.md`, the prompt log, lessons and memory notes | Felix's own wording, quoted from the engine into those files. The samples I read held no private matter |
| Tree shape and consent | Only the published set. No autonomy file, and `exceptions.tsv` is the empty template |

The 92 proposed rows:

| Lines | What the audit read | Why it is not a leak |
|---|---|---|
| 59 | `git@github.com` | the SSH user in a fixture or parser remote (acme, OwnerX, OWNER/REPO) |
| 10 | `tok@`, `SECRETTOKEN@`, `b12tok:SECRET-b12@` | userinfo planted in fixture remotes |
| 3 | `git@ssh.github.com`, `git@gitlab.com` | SSH users |
| 1 | `noreply@anthropic.com` | Claude Code's trailer address, inside a fixture commit message |
| 19 | `team1` | `team/svc` (the slash read as a stand-in), `oterm1`, or "team" near a lone `1` |

## The README against the engine

- Every `felix <command>` the README names exists in the staged engine, except
  `felix dispatch`, which it lists as "Designed, not built".
- Each of its eight flags is read by its own command.
- Nine claims that are new since the public copy are in the engine's code: the
  merge judge, `[redacted]` logging, discovery's `TMPDIR` rule, the land job's
  five minutes and macOS, the pulse's two exclusions, the subagent wording, and
  probes' instrument line.
- I found one defect, the link into `docs/`, and fixed it in `bf402aa2`.

## Install test

I ran this in a scratch HOME with a cleared environment (only a fixed PATH, user
name and locale), following
the README: clone the staged branch, run `felix/engine/harness/felix install`,
make the symlink, then run `felix new sproj --no-commission`.

- The install exited 0.
- `claude plugin list` shows `felix@felix` 0.49.340, enabled.
- The plugin cache is byte-identical to the tree's `engine/`, and the version was
  not bumped.
- `felix which` binds the scratch project.
- Nothing was written to the real HOME's pointer or plugin registry.

## Not checked, as of 2026-11-17

Checked since 2026-11-13:

- **The suite.** It ran on the published commit here and in the public CI.
- **The fixes' version bumps and `tests/red` records.** These went through #514
  and #517.
- **The real cut and its difference from the preview.** Both are covered in the
  outcome section.
- **Whether the public CI passes.** It passed.

The two README claims (bootstrap's conditions for setting the rule, and
discovery running again after an update) were not checked one by one. The suite
parts that pin them passed in both runs.

Still unchecked or undecided:

- Deliberate obfuscation, and names outside the 70.
- Three spellings from the first snapshot are still in the public history.
  Whether to rewrite it stays your call.
- `.claude/`, `cloud-verify.md` and `strategy/` at the home's root are withheld
  only by default, because no rule names them yet. The cut says so each time.
- The public `suite.yml` runs the suite serially. It took 1h50m on this commit,
  and GitHub stops a job at 6 hours. That margin shrinks as the suite grows.
  Changing that workflow is a change to the public repository outside the
  snapshot.
- Open, for a design session:
    - The address rule reads SSH remotes as addresses. That accounted for 59
      of the 92 rows.
    - A part that reads a withheld file only on a path the snapshot run did
      not take would not have failed there. PR #517 fixed the six that failed
      in one run; it was not a search for the rest.
    - `engine/harness/tests/red.tsv` carries a felix-home commit id into the
      public tree. The public main's copy already did. The script keeps the
      home's id out of the commit message, but not out of this file.
