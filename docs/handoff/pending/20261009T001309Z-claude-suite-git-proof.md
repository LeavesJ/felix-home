### 2026-10-08: a fixture git write in tests/run proves its repository sits under $TMP, a lint refuses the raw shape, and a moved remote is never green

Carries claude/suite-fixture-floor (f34bc7ad3; its section is the one just
before this). Its owner's session ended, so its carrier position (3) and this
branch's (3b) land as one PR. The floor is the class fix: the suite stands in
`$TMP/cwd` under a ceiling. This branch is the rest of the founder's brief on
the 2026-10-08 12:47:41 incident.

**Why the floor is not all of it.**
- `git -C ""` is a no-op, just as `cd ""` is. Measured on git 2.54 and bash
  3.2.57: from a checkout, `git -C "" rev-parse --show-toplevel` prints that
  checkout and exits 0. So a line converted from `cd "$X" && git ...` to
  `git -C "$X" ...` is exactly as exposed.
- A fixture written in the incident's shape after the floor lands is still
  one top-level cd away from it. Nothing said so until a run did the damage.
- The incident was found by its effect, and the founder had to work out
  which run caused it from the outside. No run checked its own effect on the
  checkout it started in.

**What landed.**
1. **`_fx_cd DIR` and `_fx_git DIR ARGS...`** (preamble). They refuse, run
   nothing and change nothing when:
   - DIR is empty, is not a directory, or is not physically strictly below
     `$TMP`;
   - the repository git would open from DIR, found as git finds it (a `.git`
     directory counts only when it holds HEAD, objects and refs), points
     outside `$TMP` by a `gitdir:` file, a symlink or a `commondir`;
   - `GIT_DIR`, `GIT_WORK_TREE`, `GIT_COMMON_DIR`, `GIT_INDEX_FILE`,
     `GIT_OBJECT_DIRECTORY`, `GIT_ALTERNATE_OBJECT_DIRECTORIES` or
     `GIT_CONFIG` is set;
   - `_fx_git` is handed `-C`, `--git-dir` or `--work-tree` before the
     subcommand;
   - they are called from the suite's own shell.

   On success they stand in DIR and export `$TMP` as a git ceiling. The
   success path forks nothing: it uses `cd -P`, `pwd -P`, `read` and parameter
   expansion. A refusal is written to `$TMP/fx-refused` (line, DIR, reason)
   as well as stderr, because fixtures silence both streams and run in
   subshells.
2. **`_fx_lint FILE`** (preamble; a POSIX-awk lexer). It reports each:
   - raw `cd` on a variable followed by a git write in the same command group;
   - raw `git -C` on a variable with a write for subcommand.

   It reads groups across lines, comments, quotes, heredocs, case patterns,
   `NAME=value` prefixes, `builtin`/`command cd`, `env`, `exec`, `time`,
   `nice`, `nohup` and `timeout` with their option values, and every git
   global option before the subcommand. Any subcommand not named as a read is a write, and so
   is `remote -v add`. A section asserts the lint is clean over this file. It
   sets aside only the floor's three deliberate probes in `_ff_case`. A
   second assertion holds that set at three, and a third pins `_ff_case`'s
   text by cksum, so a write added to the probe cannot hide behind the
   set-aside.
3. **The conversion.** 379 of main's cds became `_fx_cd`, plus the floor's one, and 68 `git -C` became `_fx_git`.
   One reader of the real checkout now names its subcommand, so it stays a
   read. The diff is a rename at every site. Measured by the regression
   reviewer: 13 sections old against new, identical results.
4. **The origin guard.** Before `$TMP` is made, the preamble snapshots each
   config watched (the start checkout's common config, the suite's own
   checkout's, and `config.worktree` when worktree config is on). It reads
   only, prints nothing and never exits. The snapshot holds:
   - remote url/pushurl/fetch/push/mirror, `url.*.insteadOf` and
     `pushInsteadOf`, `include*.path` and `extensions.worktreeConfig`, with
     includes followed;
   - per remote, whether it has refs and whether any branch tracks it.

   A bare-repository start is asked of git. A `.git` found but unreadable
   reads unreadable, not empty. Each assertion's `_ran` compares the configs'
   mtimes with a stamp (`test -nt`, no fork), and on a change re-reads and
   records the first move between two named assertions. A config that
   cannot be re-read is not a move: the end reads it three times, then says
   it could not. The last section
   fails the run on a move, including one put back before the end. The EXIT
   trap does the same for a run that never gets there, such as a section
   runner. The messages say the remotes moved *while this run ran*, never
   that this run moved them, because dozens of suites share one config. It
   restores nothing.
5. **The harness guard** (carrier ruling, added after both blind rounds, not
   blind). At 18:04 a section runner handed the suite a harness path that did
   not exist. `$(cd X && pwd)` gave an empty REAL_HARNESS, the floor's cwd
   is in no checkout, so `_copy_content` fell through to `cp -R "/."`. It
   wrote 123 GB before it was killed. Now:
   - the line after REAL_HARNESS exits 2 when it is empty or lacks `felix` or
     `lib/`, before the origin snapshot, `$TMP` or any copy; a runner that
     sets its own REAL_HARNESS on the next line meets the check too;
   - `_copy_content` refuses a source that is empty or not a directory, before
     its mkdir.

   The floor's preamble child (`head.sh`) gets a stand-in `felix` and `lib/`
   so it reaches the checks it tests. One section, "the suite copies only a
   harness", holds two assertions: both red against 00adb3281 (with cp
   shadowed, the old copy asked for `cp -R /. …`), both green after. Neither
   probe can copy anything if its check is missing. The 14/15 branch's guard
   ("no felix and no lib/") is looser than this one and can be dropped at its
   merge.

**Conversion rule for every branch landing after this.**
- `( cd "$X" && git <write> ... )` becomes `( _fx_cd "$X" && git <write> ... )`.
  It must sit inside `( )` or `$( )`, never at top level.
- `git [-c k=v] -C "$X" <write> ...` becomes `_fx_git "$X" [-c k=v] <write> ...`.

The C3 assertion names any site missed.

**Not covered, said in the comments.**
- A raw `( cd "$X" && "$FELIX" ... )` with X empty. The engine's own
  `felix_repo_root` walks from the cwd, so this class rests on the floor,
  which contains it (the review measured that on the merged tree).
- Backticks, `eval`, `bash -c` bodies, scripts written to files, git through
  a variable, `xargs git`, and a raw cd at the top of a multi-line `{ }` body.
- Ref values: concurrent fetches move them.
- A refusal under a file-size limit leaves only its stderr line.

**Evidence.** Contract, review findings and mutants:
`$FELIX_MEMORY/felix/audits/2026-10-08-suite-git-proof/`.
- **Blind block** (78, from the contract alone, written in parallel with the
  implementation): 74 red against main's preamble, 78/78 against the
  implementation.
- **Review round 1** (two Opus lenses): 16 findings. 13 were acted on through
  contract amendments A1-A9 and the merge. Two are documented, not built (E9,
  E10), and one is the record that waits for the slot (R6). Blind block 2 (55, from the amendments alone): 40 red
  against the pre-fix head, 55/55 after.
- **Mutation**: 112 mutants, 90 killed by the blind block. The runner's 16
  extra assertions kill 18 of the 22 survivors; the other 4 are equivalent.
- **Review round 2** (one Opus reviewer, on the fixes and the merge): 7
  findings, all fixed as amendments B1-B7. Two were medium:
  - under load, one failed fork while re-reading a config read as a move,
    which A5 made sticky, so it would have reddened an hour-long gate for
    nothing;
  - the set-aside would have hidden a write added to `_ff_case`.

  Blind block 3 (46, from B1-B7 alone): 30 red against the pre-fix head,
  46/46 after.
- **The floor, changed here.** B7 made `_fixture_floor`'s "not a repository"
  test require git's status 128 as well as its exact lowercase text (it
  matched `[Nn]ot` alone before), the same test the origin guard uses. The
  floor's own section still passes 61/0, with 1 skip that needs a checkout.
- **Real input**, read only:
  - a 3-minute soak started in a worktree watched the home's config and that
    worktree's `config.worktree`, and read green;
  - a soak on a copy of the home's config (209 branches tracking origin) read
    green through a `push -u`, a branch section removed, Desktop's
    `github-pr-owner-number` and gh's `gh-resolved`, with no move recorded.
- **Merged tree, section runner from inside an export**: the floor's section,
  the lint section, the four proof blocks (78 + 55 + 46 blind, 16 from the
  mutation runner), the harness guard's section and both end checks gave 263
  passed, 0 failed, 2 skipped (both need a start inside a checkout).
- The real home's `remote.*` config was compared before and after every run,
  and never moved.

**Process note.** A fix-round agent ran two probes from a script file after
the Felix pre-tool hook refused them as typed. They touched only a mktemp
checkout, but re-running a refused command through another vehicle routes
around a deny row. Later agent prompts say to stop and report a refusal
instead.
