### 2026-10-08: no engine entry point lets the caller's environment change what its tools print, nor how its shell runs

**Defect closed.** The engine reads what grep, ls, gh, tar, git diff and
bash's own `cd` and `read` produce as data. Nothing under engine/harness
removed the variables that change that. Measured on macOS (bash 3.2.57, BSD
grep 2.6.0, bsdtar 3.5.3) against main at 0.49.273, through `bash -c`, since
the tool shell's grep is ugrep:
- **GREP_OPTIONS.** BSD grep puts it in front of every call's own options.
  With `GREP_OPTIONS=-n`:
  - `felix doctor` read `declared: 1:ci 2:tests` and called ci undeclared;
  - `felix evidence` printed `8:harness`;
  - `felix ready` called the bundled skills "not installed";
  - `felix commission --status`, `felix maintenance` and `felix stack plan`
    changed their answers too.

  GNU grep has ignored it since 3.6, so CI never saw it.
- **SHELLOPTS, exported.** errexit made `felix doctor` exit 1. It also
  handed the entry point's own `set -uo pipefail` to every child, including
  checks written to run without pipefail.
- **GIT_EXTERNAL_DIFF=true.** `bin/secret-scan` passed a branch that adds a
  credential (found by the git-colour session).
- **POSIXLY_CORRECT.** Put bash 3.2 in posix mode, where the libraries'
  `<( )` is a syntax error. pre-tool still refused a force-push under it.
- **CDPATH=.:/x.** A relative `engine/harness/felix which` could not find
  its libraries.
- **Also measured:**
  - CLICOLOR_FORCE and GH_FORCE_TTY (ls and gh colour, gh JSON);
  - TAPE and TAR_READER_OPTIONS (tar);
  - GIT_DIFF_OPTS and the four GIT_*_PATHSPECS (git diff context, pathspec
    matching, `:(exclude)`);
  - TMOUT (a `read` from a slow producer ends early).

  TAR_OPTIONS, QUOTING_STYLE and BASHOPTS are documented for GNU tools and
  bash 4.1 or later, and were not measured here.

**Mechanism, and why there.** Every executable file under engine/harness
(the CLI, 8 hooks, 12 bin/ scripts, tests/run, tests/red) begins, after its
own `set`, with the same block:
- `set +o allexport +o errexit +o keyword +o noclobber +o noglob +o physical`;
- `export -n SHELLOPTS BASHOPTS`;
- `_FELIX_CALLER_CDPATH="${CDPATH-}"`;
- one unset of sixteen names.

Why this shape:
- **Not a library.** CDPATH must go before an entry point can find its
  lib/ directory.
- **Not per call.** The names leave the process environment, so every child
  inherits their absence. That includes a project's gate under `felix
  gate`, which now runs as it would on CI.
- **The one recorded fact.** lib/where.sh judges where a session's command
  runs under the caller's CDPATH. It reads the recorded value, and falls
  back to CDPATH when sourced directly.
- **The comment.** The dated comment above the block in engine/harness/felix
  says what was measured. It also says what was left alone, or is out of
  reach:
  - GREP_COLOR and GREP_COLORS, which are inert without colour;
  - xtrace and verbose;
  - locale;
  - TMPDIR;
  - BASH_ENV, exported functions, and SHELLOPTS=noexec;
  - a readonly name;
  - git colour configuration.

**Built as contract, blind assertions, fix, review.**
- **Blind block.** A blind author wrote 20 assertions from the contract on
  origin/main. 17 were red there on every host, using a grep shim that
  honours GREP_OPTIONS, an environment record, and the static rule.
- **Adversarial review of the first fix** (dc27380c) found:
  - high: pre-tool lost the caller's CDPATH, so `cd gov && git add -A`
    passed a checkout-scoped row that main refused;
  - medium: SHELLOPTS;
  - medium: three sentences of the comment that claimed more than was true;
  - low: TAR_READER_OPTIONS and TMOUT.

  All of these are fixed.
- **After review.** Peer sessions added GIT_EXTERNAL_DIFF, GIT_DIFF_OPTS and
  the four GIT_*_PATHSPECS. The blind static reader was amended, and marked
  not blind, to skip the `export -n` and the CDPATH record. Nine assertions
  were added after review.
- **Section runner, 29 assertions:**
  - the fix: 29/0, and 29/0 under a grep that ignores GREP_OPTIONS;
  - dc27380c: 23/6, all six post-review;
  - origin/main: 6/23.

**Traps paid:**
- **A section runner that splices REAL_HARNESS after a fixed line 23.** It
  now lands above the suite's own `REAL_HARNESS=` line, which re-pointed it at
  TMPDIR. `_copy_content` then copied TMPDIR into itself for 48 minutes,
  behind an empty log. tests/run now exits 2 when REAL_HARNESS is not an
  engine. Splice after the line `awk '/^REAL_HARNESS=/'` finds.
- **The fact gate refuses `rm -rf`, whatever facts come first.** The runaway
  fixture `$TMPDIR/tmp.weMqYcwdy1` was left for the founder.

**Landing.**
- **Slot.** 14 in the 2026-10-08 carrier queue.
- **Packaging.** It is to ride in one PR with claude/no-git-colour-in-parsed-output
  (slot 15), carried from that branch. If that stack is not reviewed and
  green on both blind blocks when 14 is called, this branch lands alone.
- **The locale bullet in the felix comment.** Whichever of this branch and
  claude/locale-c-sort-comm (slot 21) lands second rewrites it.

**Handed on:**
- **git colour configuration**, to claude/no-git-colour-in-parsed-output.
- **diff.external and textconv drivers**, to
  claude/no-diff-drivers-in-parsed-diffs (`--no-ext-diff --no-textconv` on
  every parsed patch).
- **lib/escape.sh's comm -23 in the caller's locale**, to
  claude/locale-c-sort-comm.
