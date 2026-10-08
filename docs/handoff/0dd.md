### 0dd. 2026-09-24 — the engine makes its scratch under TMPDIR, because a bare mktemp on a Mac does not, and no count of what a path left behind could see it

**Engine 0.49.265, branch `claude/engine-mktemp-tmpdir`, landed by the queue
carrier on 2026-10-02 in the slot after the unattended.yml sha pin (#403).** It follows b611b9's
`claude/red-mktemp-tmpdir` (0.49.200), which clears the 44 red rows #308's
lift assertions showed on every Mac. It makes tests/red's own root by a
template and runs the suite under the caller's TMPDIR, as a plain run does;
tests/run's root stays a bare `mktemp -d`, because nesting it under a moved
TMPDIR pushed a displayed path past `_felix_binding_sane`'s 80-character cut
(a separate task now).

**Measured, 2026-09-24, macOS 26.3.1.** A bare `mktemp` or `mktemp -d` makes
its file in `getconf DARWIN_USER_TEMP_DIR` (/var/folders/.../T), whatever
TMPDIR says: set elsewhere, unset, or naming a missing directory. A template
(`mktemp -d "$dir/x.XXXXXX"`) or `-p` honours TMPDIR, and a template in a
missing directory fails. GNU mktemp on the Linux runner honours TMPDIR in
every form.

**What changed.** Thirteen calls in `felix` (gate log, merge's judge,
discover's scratch, twice) and in lib/handoff.sh (three calls), monitor.sh,
pulse.sh, qualify.sh, resolve.sh (two calls) and route.sh, plus
`projects/felix/gate.sh:201` (the installed check's copy of main's
resolve.sh), now each pass `"${TMPDIR:-/tmp}"`, with its trailing slash
stripped, followed by `/felix-<what>.XXXXXX`. discover.sh:825 and the
gate's suite log already did. The root is a separate local: cmd_discover's
EXIT trap does `rm -rf` on its scratch variable, so the variable is never
allowed to hold TMPDIR itself, not even for one line. By the landing slot,
main's qualify.sh made no scratch file at all, so its call is gone and
twelve engine calls plus Felix's gate carry the change.

**The suite, per block that sets TMPDIR and counts what is left there.**
Each was shown red by a mutant that leaks into the TMPDIR it was given (run
block by block, at a load above 150):

| Block | Path it drives | mktemp | Red under a leak |
|---|---|---|---|
| discover entry (DM) | discover.sh:825 | template | "and leaves no scratch file behind" |
| two gates at once (GCT) | felix gate.sh suite log | template | "a passing gate leaves no suite log behind" |
| project gate logs (PGL) | elenchus gate and prepush, veldra gate | template | all six "no log is left behind" and "only the logs it names are kept" |
| veldra fmt (VFM) | veldra gate | template | "and the log it names…", both "leaves no log behind" |
| felix audit (AU), and after the reviews (_rvn) | lib/audit.sh | none | both read-only snapshot checks |
| tests/red (_red) | tests/red's own root | bare on main | fixed on b611b9's branch, which undertook to show it red; not seen here |

None of the counting blocks reached one of the thirteen, so none of them was
blind for this reason. The thirteen had no count of their own anywhere. The
same audit mutant, leaking by a bare mktemp instead, left 17 files in
/var/folders while both audit checks stayed green: the blindness, shown.

**New assertions** ("the engine makes its scratch under TMPDIR"): a reading
of every `$(mktemp` in felix, lib, bin, hooks and Felix's gate for a
template; a drive of four of the paths through a recording `mktemp` on PATH,
which checks each call names `$TMPDIR/felix-*.XXXXXX` and that nothing is
left there; and a guard that the drive did its work. Each shown red: the
first two on main's engine, the count with a pulse.sh that keeps its index,
the guard with TMPDIR pointed at a missing directory.

**Weighed, and left alone: lib/where-read.sh.** It models a bare `mktemp -d`
as landing in $TMPDIR, which on a Mac with TMPDIR moved is wrong: the file lands in
/var/folders. The error gives the same answer or a stricter one, never a
looser one. The real place is never the governed checkout. A TMPDIR that is
a temporary root lifts as the real place would. A TMPDIR inside the checkout,
or missing, keeps the row. A looser answer would need the checkout to hold
/var/folders/.../T.

**The cost.** A TMPDIR naming a missing directory now fails these paths on a
Mac, as it already did on Linux: bump and route refuse and leave the file
alone, handoff and qualify say so, and cmd_gate still prints and returns
the gate's own status but has no log to read its FAIL names back from.
Nothing was widened.

**Not done:** `projects/sv2-apps/gate.sh:36` still makes its log dir with a bare
`mktemp -d`. It is that project's gate, not Felix's.

**Traps paid:**
- The fact gate refuses any command holding `rm`, a scratch cleanup
  included, until the files, a rollback and the instruction are stated.
- A block extracted from tests/run must start at a statement boundary: 21575
  sits inside an `if`, and the extract died on `||`.
- A static check rooted at `$REAL_HARNESS/../..` read nothing from a harness
  copy with no checkout around it, and passed. It now reads the harness
  itself and asserts it read `felix`.
