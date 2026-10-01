### 2026-10-01: a qualification row's premise, mutation and command each run in a bash of their own, and a column that ran nothing reads unrunnable wherever the runner can hear it

The engine change is `_felix_qualify_sh` and `_felix_qualify_one` in
lib/qualify.sh, with one section of tests/run (62 assertions, written blind
over three rounds). Nothing else moves. No row in
`projects/felix/qualification.tsv` changes: all 82 give byte-identical
verdicts under the old and the new runner (81 met, 1 inapplicable), checked
after each round.

**Defect closed.** Before this change, all three columns ran as
`( cd "$scratch" && eval "$x" )` inside the caller. For `felix qualify` and
`felix gate`, that is the felix CLI, so they ran under its `set -uo pipefail`.
Probes, obligations and maintenance already start a fresh `bash -c`.

Under pipefail, `producer | grep -q x` fails with x present: grep leaves at
its first match, and the producer dies of SIGPIPE (141). Pipefail only ever
turns a pipeline that held into one that failed, so each column moved its
verdict its own way:
- A premise read unrunnable. A negated premise applied its control where the
  premise is absent.
- A mutation's `&&` chain stopped short, so a pass control was met over a
  change the checker never saw.
- A command read fail, which on a fail control is met: exactly what a working
  checker reports. In the negated shape the ten schema-check rows use, it read
  pass, a false held. schema-check prints 3 lines with the match on line 1, so
  this was live and load-dependent.
- nounset in a script exits 1, not 127 (the commissioning session measured
  it). A premise that named an unset variable read inapplicable, and was
  silently not run.

**Decided, not left.**
- Not the commissioning design, where the row runs in-process under
  `set +o pipefail` and an alias wrapper protects engine functions.
  Qualification rows run the tree's own engine/harness/bin scripts, which are
  processes of their own. An in-process engine function would be the
  installed engine, which the mutation cannot reach.
- Not an edit to qualification.tsv. The rows are correct shell, and the
  defect was the runner.
- Rows run through `env -u SHELLOPTS -u BASHOPTS -u BASH_ENV -u
  POSIXLY_CORRECT`. An exported SHELLOPTS or BASH_ENV brought pipefail back
  into the "fresh" bash, and into every checker it ran.
- A column that ran nothing reads unrunnable wherever the runner can hear it:
  - blank or comment-only text;
  - text `bash -n` rejects;
  - a final 126 or 127;
  - a line of the column's own stderr, under its `felix-qualify` $0, saying a
    name was not found, or bash's parser refusing the text.

  The header lists what is not heard, and the remedies for row authors. Not
  heard:
  - a missing path, which bash reports as "No such file or directory", the
    same message as a failed redirection;
  - stderr the row hides;
  - wrappers;
  - locales where bash translates its messages.

**Built by three rounds of the engine-build workflow.** Each round ran a
blind assertion author, then the implementer, then adversarial reviewers. The
reviewers found every addition after round 1: the not-found scan, the parse
check, the blank check, the environment scrub and the narrowed syntax branch.
Every assertion is red on a named wrong runner, built as a scratch variant.

**Handed on, not done here** (both filed as tasks):
- Probes, obligations, maintenance and setup share the SHELLOPTS/BASH_ENV
  exposure and the missing `--`.
- A scratch worktree leaks when a mutation makes a directory unwritable, or
  when the run is killed. Three such trees were registered in the home
  checkout on 2026-09-25. The session "Stop qualify scratch worktrees
  leaking" carries the fix.

- lib/qualify.sh is 520 lines after #383 merged in: 467 on this branch, plus
  #383's 53. The split is deferred on purpose. Two stacked branches edit
  `_felix_qualify_one`: claude/qualify-scratch-cleanup and
  claude/engine-mktemp-tmpdir. Moving the function now would conflict both.
  The seam is the row runner (`_felix_qualify_sh`, `_felix_qualify_one`) on
  one side, and the table read and verdict logic on the other. Split there
  once both have landed.

**Traps paid:**
- A reviewer prompt named the implementation commit's parent as the "unfixed"
  baseline, but the parent already held the fix. Name the blind-tests commit
  as the baseline instead.
- A workflow that hits the session limit returns its reviewers as failed.
  Resuming with `resumeFromRunId` replays the finished agents from cache and
  reruns only those.
- `claude/engine-mktemp-tmpdir` rewrites this function's mktemp line.
  Whichever branch lands second keeps both: this branch's `local ... err got
  rc` line and the other branch's `felix-qualify.XXXXXX` template. Grep for
  the template afterwards.
