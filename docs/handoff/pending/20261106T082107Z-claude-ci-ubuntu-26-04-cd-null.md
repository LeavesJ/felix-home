### 2026-11-06: the suite passes on bash 5.3, so the gate can pass on ubuntu-26.04 again (0.49.321)

**What failed.** `ubuntu-latest` became ubuntu-26.04 (image 20261101) between
2026-10-31 and 2026-11-06. Main's last green gate run (41228098493) was on
ubuntu-24.04. Every PR's gate since then failed in the suite, and the gate
prints only the first 30 FAIL lines (projects/felix/gate.sh:362), so the list
was never whole. #482 and #483 both hit it.

**The whole list.** The suite was run in an ubuntu:26.04 container (bash
5.3.9, uutils coreutils 0.10, gawk 5.3, perl 5.40, git 2.53; a non-root user,
a real init, `GITHUB_ACTIONS=true`, `-j 8`). 23 failures, from two causes:
- **`cd ""` fails in bash 5.3** ("cd: null directory", status 1; POSIX.1-2024).
  Bash 3.2, where the 2026-10-08 incident happened, returns 0 and stays put.
  - Part 0005's `_ff_case` cases `empty` and `gitdir` read the failed cd as
    "the case's own cd failed after the floor": 16 assertions.
  - Its two read-only probes of the same incident (`cd "$_ff_empty" && git
    rev-parse`) never reached git on 5.3, so they passed for the wrong
    reason, and each printed `cd: null directory` to stderr. Every `tests/run
    -j` child runs the prelude, so the parent's stderr file held two extra
    lines. That is all of part 1291's D5 (`[0 2]`, not `[0 0]`) and D6 ("3
    stderr lines, not 1"): six assertions.
- **A closed stdout is reopened on /dev/null in bash 5.3.** Part 2220's
  R2-F12 ran `felix lane --tsv` under `>&-` to make its write fail. Under 5.3
  the lines were written to /dev/null and felix exited 0: one assertion.

**What changed (`claude/ci-ubuntu-26-04-cd-null`).**
- `0005-fixture-floor.sh` gains `_ff_oldcd`, called first inside the `$( )` of
  each of the three probes. In that subshell only, it defines a `cd` that
  returns 0 for exactly one empty operand and passes everything else to
  `builtin cd`. Where the shell's own `cd ""` already succeeds (3.2, 5.2) it
  defines nothing, so the Mac runs the real thing. `_ff_case`'s text is
  untouched, so part 0200's pin (`1793434744 1884`) and the lint's three
  set-aside lines hold as they were.
- `2220-lane-command-blind.sh` stands R2-F12's stdout in as a descriptor 1
  open for reading only (`1< file`), as part 0574 already does ("a read-only
  stdout stands for every way a write fails"). The write fails with EBADF on
  every bash. A status alone could be sh's own, from a stand-in it could not
  set up, so the assertion also needs felix's sentence that the lane lines
  could not be written. The part is at 1000 lines, the suite's limit.
- No assertion name changed, so assertions.tsv and red.tsv are as they were.

**Shown red and green.** Same container, before and after: part 0005's 16 and
R2-F12 failed, and with these two files they pass. A mutant whose read-only
file cannot be opened turns R2-F12 red. The full suite on the fixed tree gave
15613 passed and no failure but the one below, and parts 0200, 0201 and 2220
pass on the Mac's bash 3.2.

**Not covered.**
- The container has no `node`, so 87 assertions skipped, among them part
  1090's monitor-page set. One of them is a manifest name ("the monitor page
  gives a passed gate its own class ... (control)"), which the container run
  reports as "assertion did not run". The runner image has node and they
  passed on 24.04; whether they pass on 26.04's node is CI's to say.
- Other parts close a descriptor with `>&-` as a stand-in (0573:553, 0574:15
  and :87). They pass on 5.3, but what they exercise there is a write to
  /dev/null, not a failed write. Not changed here.
- Pinning `runs-on: ubuntu-24.04` was not needed. It would have been the
  founder's to merge (a workflow file is an unconditional escape).
