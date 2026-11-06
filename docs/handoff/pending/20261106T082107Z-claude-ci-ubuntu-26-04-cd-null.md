### 2026-11-06: the suite passes on bash 5.3, so the gate can pass on ubuntu-26.04 again (0.49.321)

**What failed.** `ubuntu-latest` became ubuntu-26.04 (image 20261101) between
2026-10-31 and 2026-11-06. Main's last green gate run (41228098493) was on
ubuntu-24.04. The gate runs of #482 and #483 since then failed in the suite,
and the gate prints only the first 30 FAIL lines (projects/felix/gate.sh:362),
so the list was never whole.

**The whole list.** Main's tree (1fca9559) was run in an ubuntu:26.04
container: bash 5.3.9, uutils coreutils 0.10, perl 5.40, git 2.53, a gawk 5.3
that I installed as awk (the runner's readme does not say which awk it has),
a non-root user, a real init, `GITHUB_ACTIONS=true`, `-j 8`. It gave **386
failures** (15454 passed, 147 skipped). Two causes, and one is nearly all of
them:
- **`cd ""` fails in bash 5.3** ("cd: null directory", status 1; POSIX.1-2024).
  Bash 3.2, where the 2026-10-08 incident happened, returns 0 and stays put.
  - Part 0005's `_ff_case` cases `empty` and `gitdir` read the failed cd as
    "the case's own cd failed after the floor": 16 assertions, in the
    prelude every unit runs.
  - So 223 more FAILs read "part's prelude failed: <part>", and 144 more
    are assertions of the gate-friction-D parts (1291 to 1296) that plant a
    suite run and expect it to exit 0 or leave a clean stderr: the planted run
    carries the prelude's failure. D5 and the D6 refusals are among them.
    That is 383 of the 386; the other three are R2-F12 (below), the monitor
    control that the container's missing `node` leaves unreached, and the
    red.tsv record, which the container's tree had not redone.
  - Its two read-only probes of the same incident (`cd "$_ff_empty" && git
    rev-parse`) never reached git on 5.3, so they passed for the wrong
    reason, and each printed `cd: null directory` to stderr. On main's tree a
    run's stderr holds four such lines (0005:90, :91 and :206 twice), so D5
    reads `[1 4]` and a D6 refusal "5 stderr lines, not 1". On #482's and
    #483's trees, whose edit silenced :206 and ignored its failure, the same
    two probes alone give D5 `[0 2]` and "3 stderr lines".
- **A closed stdout is reopened on /dev/null in bash 5.3.** Part 2220's
  R2-F12 ran `felix lane --tsv` under `>&-` to make its write fail. Under 5.3
  the lines were written to /dev/null and felix exited 0: one assertion, and
  the one the 30-line cap hid, since it sits after part 1291.

**What changed (`claude/ci-ubuntu-26-04-cd-null`).**
- `0005-fixture-floor.sh` gains `_ff_oldcd`, called first inside the `$( )` of
  each of the three probes. In that subshell only, it defines a `cd` that
  returns 0 for exactly one empty operand and passes everything else to
  `builtin cd`. Where the shell's own `cd ""` already succeeds (bash 3.2, the
  Mac's) it defines nothing, so the Mac runs the real thing. `_ff_case`'s text
  is untouched, so part 0200's pin (`1793434744 1884`) and the lint's three
  set-aside lines hold as they were.
- `2220-lane-command-blind.sh` stands R2-F12's stdout in as a descriptor 1
  open for reading only (`1< file`), as part 0574 already does ("a read-only
  stdout stands for every way a write fails"). The write fails with EBADF on
  every bash. A status alone could be sh's own, from a stand-in it could not
  set up, so the assertion also needs felix's sentence that the lane lines
  could not be written. The part is at 1000 lines, the suite's limit.
- No assertion name changed, so assertions.tsv stands. red.tsv is re-recorded
  against origin/main 1fca955 (0 of 15764 assertions fail against that
  engine), as any engine change requires.

**Shown red and green.** Same container, main's tree against this one: 386
failures against 2. Of those 2, one is the container's (no `node`, below) and
one is red.tsv, which that run had not yet re-recorded. A mutant whose
read-only file cannot be opened turns R2-F12 red. On the Mac's bash 3.2, parts
0200, 0201, 1040 and 2220 pass.

**Not covered.**
- The container has no `node`, so 87 assertions skipped, among them part
  1090's monitor-page set. One of them is a manifest name ("the monitor page
  gives a passed gate its own class ... (control)"), which the container run
  reports as "assertion did not run". The runner image lists Node.js 24.22.2
  and the last green run on ubuntu-24.04 reached these assertions; whether
  they pass on 26.04 is the pull request's CI run to say.
- Which awk the 26.04 runner has is unread; the container used gawk.
- Other parts close a descriptor with `>&-` as a stand-in (0573:553, 0574:15
  and :87). They pass on 5.3; a bash script started that way gets /dev/null
  as its stdout, so what they exercise is a write to /dev/null, not a failed
  write. Not changed here.
- Pinning `runs-on: ubuntu-24.04` is the alternative if this does not hold on
  the runner. It would be the founder's to merge (a workflow file is an
  unconditional escape).
