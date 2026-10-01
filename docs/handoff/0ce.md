### 0ce. 2026-09-24 — the 44 red rows every Mac recorded since #308 were tests/red moving TMPDIR, which macOS's mktemp ignores; red now runs the suite in the caller's TMPDIR

**One engine PR from this session, version 0.49.200, tests only**
(`engine/harness/tests/red`, and one fixture assertion in
`engine/harness/tests/run`; lib/where.sh unchanged). Since #308 (0.49.181),
every `tests/red` run on a Mac reported the same 44 of #308's lift assertions
failing, against a base whose engine was the tree's own. #341's record (45
rows) and #344's (49) share exactly those 44; the rest are their own.

**Measured, not read.** On macOS 26.3, `/usr/bin/mktemp -d` and bare
`mktemp` make their entry in the per-user `/var/folders/.../T` whatever
`TMPDIR` says: an existing directory, a missing one, or unset. A template or
`-p` honours TMPDIR, and so does python's tempfile. tests/red ran the suite
with `TMPDIR="$TMP/t"`, so the suite's root landed beside red's directory,
not in it. lib/where.sh counts `/tmp` and `$TMPDIR` as temporary roots, so
every scoped fixture read as "outside every temporary directory" and each lift
was refused. The Linux runner's GNU mktemp honours TMPDIR, so CI never saw it.

**Two fixes tried, one kept.** Making the suite honour the moved TMPDIR (a
template for its root) put the fixtures back under a root, and a red run
then failed "and says which directory it was sent to": nesting adds
seventeen characters to every path, and `_felix_binding_sane` in
lib/resolve.sh cuts a displayed path at eighty. A plain run's
`$TMP/not-a-felix-home` on this Mac is exactly eighty. So red now runs the
suite with the caller's TMPDIR, as a plain run does, and the suite's root
line is main's. The cost, said in tests/red: its stray pattern no longer
covers a process naming only the suite's root, which on a Mac it never did.

**Also in the PR.** Red's own root is made by a template under TMPDIR, so the
suite's "no temporary directory is left under the tmpdir it was given" can
fail on a Mac. It could not before: with red's `_cleanup` trap removed, main's
red left 0 directories under the given tmpdir, and the new red left 1. And one
fixture assertion, "the scoped fixture lies under the TMPDIR the suite was
given", fails if the fixture is outside TMPDIR (shown on a root made the old
way under a moved TMPDIR), so a return of this cause reads as one line and
not 44.

**Left as found, and worth a look (a separate session took it):** the
engine's own bare `mktemp` and `mktemp -d` calls (qualify.sh, handoff.sh,
resolve.sh, route.sh, pulse.sh, monitor.sh, felix) ignore TMPDIR on a Mac the
same way. gate.sh names its logs by a template, so the GCT and PGL leftover
counts are real. A plain Mac run under any TMPDIR other than the per-user one
(a sandboxed shell's `/tmp/claude-501/...`) puts the fixtures outside every
root the same way (shown on the judge alone, not in a full run), and the
fixture assertion would say so. where-read.sh models
`mktemp -d` as landing in `$TMPDIR`. On a Mac the real directory is the
per-user one, which is also throwaway, so the model can err only toward
refusing.

**Traps paid:**
- The Edit tool dropped the trailing space of a `new_string` ending in
  `cp `, so the scoped fixture's marker row read `cp` and matched `scp`. A peer
  session caught it in the diff. Diff a line you meant to leave alone against
  main before recording.
- Killing a suite: bash defers TERM while it waits on a child, and in the
  tool shell (zsh) an unquoted `$P` holding several pids is one argument, so
  `kill $P` ends nothing. Collect the tree under `bash -c` and KILL the suite
  pid itself.
- `( cd X && nohup cmd & disown )` fails in the tool shell ("no current
  job") and stops an `&&` chain after starting the first run. Start each
  detached run on its own line.
- Twice, something outside the session ended a detached
  `tests/red origin/main` with SIGTERM, while a `tests/red f92b8ed7` and a
  plain `tests/run` started at the same moment survived. Most likely a session
  clearing its own red runs by that pattern. An evidence run named by sha
  (`tests/red <sha>`) was not touched.
- A red run killed part-way records FAIL for whatever assertion was running,
  so a partial red.tsv has rows that mean nothing.
- The desktop guard refuses Edit and Write in any worktree but the session's
  own, so do not move the PR branch into a second worktree to run records in
  parallel. Run the extra red runs from a detached worktree and keep the
  branch where the session stands.
