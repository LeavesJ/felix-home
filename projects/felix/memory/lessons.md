# Lessons

Written down when something cost time, or would have cost it twice.

## Always

Run the gate before claiming anything is done. The Stop hook enforces this now,
but it blocks once per chain and fails open on every error, so it is a reminder
with a record, not a substitute for running it.

- **A suite section that inherits fixture state reads like a product bug.**
  `tests/run` rewrites the widget project's gate in several places to prove
  different things. A later section assumed the original gate and asserted that
  a failing gate blocks; by then the gate was `true`, which cannot fail. Two
  assertions went red and the hook looked broken. It was correct the whole time,
  and reproducing it standalone passed immediately, which is the tell. A section
  that depends on a fixture value must declare that value itself.

- **A check that skips absent files passes by finding nothing.** The first
  version of the gitignore guard looped over `projects/*/memory/*.log` and
  skipped anything not present. In a worktree those files are untracked and
  therefore absent, so it reported ok while proving nothing. `git check-ignore`
  evaluates a path whether or not a file is there. Assert the rule, not the
  filesystem — and show the check failing before believing it, which is already
  the constitution's fourth invariant.

- **`tests/run` computes the harness path from `$0`.** It does
  `REAL_HARNESS="$(cd "$(dirname "$0")/.." && pwd)"` and then `cp -R` that into a
  temp root. Copy the suite anywhere outside `engine/harness/tests/` and it
  resolves to the parent of wherever it landed: from `/tmp` it began copying the
  root filesystem, reached 18GB, and the `cp` survived its parent shell as an
  orphan reparented to init, so every attempt to delete the temp directory lost
  ground until the copy itself was killed. Debug the suite in place.

- **Verification has no native record anywhere in Claude Code.** Transcripts
  carry `is_error` on tool results; Bash results carry stdout and stderr but no
  exit code. Whether a gate passed exists only if Felix writes it down. That is
  what `memory/verification.log` is for, and why the completion gate was built
  before the capability ledger that depends on it.

- **A changed engine at an unchanged version never deploys.** Claude Code
  caches a plugin by version, so `claude plugin install` and `claude plugin
  update` are both no-ops on a same-version change and both report success.
  Adding an already-registered marketplace also does not re-read the manifest,
  so a bumped version stays invisible until `marketplace update`. Three
  separate defects, all hidden behind cheerful output. `felix install` now
  diffs the tree against the version the CLI reports as live and is the only
  thing that speaks. Announcing a deployment is what let this recur.

- **A record written inside the tree it describes invalidates itself.** Felix's
  home is the Felix repository when Felix governs itself, so the gate receipt
  landed in the tree whose identity it recorded. Writing it changed the tree,
  which invalidated the receipt just written, and no gate run could ever
  produce a valid one. The suite never saw it because its fixture puts the home
  outside the governed repo — true of every project except the one Felix is.
  Test the layout you actually run in, not the convenient one.

- **Run the deployed thing against the real repository.** Both defects above
  survived a green 233-assertion suite and were found within minutes of
  executing the installed hooks by hand. The suite tests the code; only running
  it where it will run tests the deployment. Third occurrence of this shape.

- **Ask what a measurement is caused by before acting on it.** Usage counts
  cannot show a capability is useful, because loading it is what causes it to be
  used. Absence of use given presence is the unconfounded direction, and it is
  the only one worth acting on. The same shape will recur anywhere Felix
  measures something it also controls.
