### 2026-11-06: felix brief and felix incident read project.json's evidence declarations, so a declaration felix merge refuses is one project.json row and not ordinary rows (0.49.326)

**What was wrong.** `felix merge` reads `project.json`'s `evidence_vendored` and
`evidence_reads_vendored` before it judges any evidence row, and when it cannot
read them it refuses with `evidence project.json ... so the rules were not
judged` (b11 round 3, B11R3-8). `felix incident` and `felix brief` (the "what a
fix must prove" section, `felix_brief_evidence` calling
`_felix_evidence_judge ... brief`) never read `project.json` (B11R3-11). So
for a declaration the merge refuses (a name in `evidence_reads_vendored` that
is no row of `evidence.tsv`, an absolute `evidence_vendored` entry, a key given
twice, a value that is not one JSON string, a `..` component, a committed
symlink) the brief printed the table's ordinary rows, or a heading with
nothing under it when the table held no row the path reaches. Same species as
the path disagreement #488 closed. Found by #488's adversarial review and left
out of its scope.

**What changed (`claude/brief-reads-declaration`).**
- `_felix_evidence_judge` asks `_felix_evidence_declared` in both modes. When
  it fails, both modes say the one `project.json` unknown and no row, the
  check's own rule (the declaration stands for every row). The brief reads
  the declaration only to ask whether it can be read: it still sets nothing
  aside, so a path under a declared `vendor/` still fires a row.
- `felix_brief_evidence PROJ PATHS [ROOT]` takes an optional repository (the
  one the command runs in; absent, the one holding the current directory) and
  reads `project.json` at `main` as `felix evidence` and `felix merge` resolve
  it (`origin/main` when that exists), at `HEAD` when `main` names nothing, and
  from the disk when the project directory is not inside that repository.
  `felix_brief_render` and `cmd_incident` pass their `$root`.
- The order is the check's: a path at `evidence.tsv` that is not a readable
  table gives the one `evidence.tsv` row first; no `evidence.tsv`, no section.
- Contract `docs/2026-11-06-brief-reads-the-declaration-contract.md`. Blind
  parts `2310-brief-reads-the-declaration-blind.sh` (155 names) and
  `2311-brief-reads-the-base-blind.sh` (36 names, the amendments). Part 1832's
  A149 and its section line are reworded (its fixture is no repository, so it
  still holds); two dated audit docs got a forward pointer.

**Measured, not read off the code.** On main (4c4c0b3d) part 2310 gives 82 red
and 73 green (the controls and the arming assertions), the red for the
contract's reason in every case (a red-check agent classified all 82; three
runs identical; nothing left behind). Against the engine that read `HEAD` the
8 red names of 2311 are the base ones (Q1, Q2, Q5).

**The review (three Opus 5.5 xhigh lenses: disagreement hunter, mutation
tester, regression reader; the blind author Opus 5.5 xhigh; the red check and
the mutant re-run Sonnet 5.5 xhigh).** No regression outside the bad-declaration
cases: 20 controls over seven commands print the same bytes on the old and new
engine. What it found:
- **The brief read `HEAD`, the merge reads the base.** When `main` moves after
  the branch point, or a branch is cut from a stale local `main`, the two
  disagreed with a change that never touched `project.json`, both ways. This
  was the first contract's own decision (D4: `HEAD`) and its out-of-scope line
  covered only a branch editing its own declaration. Fixed by reading `main`,
  with `HEAD` as the fallback (the same `felix_base_ref ... main || ""` that
  `felix next` uses); Q1 and Q2 hold it.
- **Seven mutants survived part 2310**, in shapes it never built: a project in
  a different repository from the checkout (Q8), more than one implicated path
  (Q6), the command run from a subdirectory (Q7), an unborn `HEAD` (Q4, Q5),
  no `main` (Q3). Part 2311 was written blind from the amended contract, then
  the survivors and new ones were run again, 13 mutants in all: every one
  killed, none left.
- Equivalent mutants (dropping `"$root"` from the two callers) are
  indistinguishable by design: both compute the default.

**Left out, and why.**
- A brief or trace naming no file in the checkout prints no section, so no
  `project.json` row either (the brief says nothing can be scoped); the merge
  still refuses. Old behaviour.
- A detached `HEAD` or an orphan branch: `felix merge` refuses with "cannot
  name the branch to merge" before its evidence check, so "all four or none"
  holds of the other three only.
- Outside any repository the brief reads no declaration (no commit holds one);
  with the current directory above the project and with it outside, the two
  differ. Merge cannot run there.
- Nothing builds a repository whose local `main` and `origin/main` differ, so a
  mutant preferring local `main` over `origin/main` would survive; the brief
  calls the resolver the others call, so the preference is theirs.
- `felix incident` still prints its heading over nothing for a good declaration
  and a table with no row the path reaches. Old behaviour, and `[ -f ]` on the
  path is #488's.
- Wording: `felix evidence` and `felix next` say the project.json row is
  corrected "in evidence.tsv"; the brief's reason for a committed link says "at
  the base" though it read the base. Not reworded, as the task said.
- The run depends on #488 only for the `tests/run` registration lines and the
  version slot (merge-tree: those two files conflict, `evidence.sh` and `felix`
  merge cleanly). Whichever lands second resolves them.
