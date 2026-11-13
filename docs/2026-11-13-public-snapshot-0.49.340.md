# The public snapshot of engine 0.49.340, staged 2026-11-13

**Scope.** This covers what one overnight session staged and audited for
`github.com/LeavesJ/Felix`, cut from felix-home's main at `cf0cb744` (engine
0.49.340), and what it left unchecked. Nothing was pushed, to the public
repository or to felix-home. The question at the end is whether to publish. One
question is left open for a design session: how the audit's address rule should
treat SSH remotes.

## Where it stands

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

## Not checked

- **The suite** was not run on the preview, and part 1860 was not run after the
  renames, because other sessions were gating. The fix PR's gate would run it,
  and so would the public PR's CI.
- **The fix commits' version bump and `tests/red` record.** Both need a suite run.
- **The real cut.** Tonight's tree is a preview. Once the fixes land,
  `snapshot.sh` runs again from main. Its tree should differ from tonight's only
  by the version, `red.tsv` and whatever else lands in the meantime, and that
  difference is what gets audited again.
- Two of the README's new claims: bootstrap's conditions for setting the rule, and
  discovery running again after an update. Suite parts pin both, but I did not
  run them.
- Deliberate obfuscation, and names outside the 70.
- Whether the public CI (ubuntu-latest) passes.
- Three spellings from the first snapshot are still in the public history.
  Whether to rewrite it stays your call.
- `.claude/`, `cloud-verify.md` and `strategy/` at the home's root are withheld
  only by default, because no rule names them yet.
- Open, for a design session: the address rule reads SSH remotes as addresses.
  That accounts for 59 of tonight's 92 rows.
