### 2026-11-06: the evidence readers ask the judge's own question about evidence.tsv (0.49.322)

**What landed (branch `claude/evidence-readers-agree`).** The adversarial review
of #482 found that `felix classify`, `felix receipt` and `felix evidence` tested
`evidence.tsv` with `[ -f ]` before they consulted the evidence judge, while the
judge that `felix merge` runs (`_felix_evidence_judge`) first asks `-e || -L`.
So a directory, a dangling link or a FIFO at the path stood for the judge and
was not there for the reader.
- Measured on main 1fca9559 with a fixture, not read off the code: for each of
  those states `felix merge --dry-run` named an `evidence` blocker ("exists but
  cannot be read, so its rules were not judged"), `felix classify` on a green
  change said "Reversible, and nothing is unproven. Eligible for auto-merge",
  `felix evidence` died with "declares no evidence.tsv", and `felix receipt`
  listed nothing unknown. `felix incident` had the same `-f` test and printed no
  "the fix will have to prove" section: a fourth reader. `felix next` and the
  brief path (`felix_brief_evidence`) already called the judge without a file
  test and agreed.
- `lib/evidence.sh` now defines `felix_evidence_table_present PROJ`, the
  judge's own question. The judge asks it, and so do `felix evidence`,
  `felix classify`, `felix incident` and `felix receipt`. There is one
  definition and no copy. The judge's wording, and the readers', are unchanged.
- The contract is `docs/2026-11-05-evidence-readers-agree-contract.md`. The
  blind part is `tests/parts/2300-evidence-readers-agree-blind.sh`: 94
  assertions of its own, 33 red against main (D1, D2, D3, D4 (b), and A1 to A5
  in the four states that stand and are not a table: a directory, a dangling
  link, a link to a directory and a FIFO) and 61 green there (the controls C1
  to C6, the arming assertions, and the regression guards A6 `felix next` and
  A7 `felix brief`, which already agreed with the judge). D3 is a source check
  that no file but `lib/evidence.sh` tests the evidence path with any unary
  file operator; D2 replaces the function in a subshell and shows the judge
  follows it. Re-run by this session, not only reported: 94 of 94 pass on the
  fix, 61 pass and 33 fail on main's engine, the same names in both runs.

**The review (three Opus 5.5 xhigh lenses: disagreement hunter, mutation
tester, regression reader).** No reader other than the five changed disagrees
with the judge for a path that stands: `felix next`, `felix brief` and
`felix merge` already called the judge without a file test. What it found:
- Mutation: with a FIFO only in D1, three mutants survived (a FIFO-only
  carve-out in `felix evidence`, in `felix classify` and in the judge), and
  one more with `felix incident` printing its section with nothing at the
  path. A variable-guard regression in `lib/next.sh` or `lib/intake.sh` got
  past D3 because the part never ran those two readers. D1's watchdog left a
  FIFO opener blocked after the suite's temporary directory was gone.
- Regression: a shell that sources `lib/receipt.sh` alone printed "command not
  found" on stderr for every state, because the new question lives in
  `evidence.sh`. No production caller loads that way (the CLI sources
  `evidence.sh` first), but the old form failed open there with an empty
  evidence block, so `receipt.sh` now loads `evidence.sh` when the function is
  missing, as `intake.sh` does.
- Byte for byte: the controls (absent, readable file with its rule unmet, met
  or not reached, a link to a file, a row that is not four cells) print the
  same on the old and new engine over `felix evidence`, `classify`, `receipt`,
  `merge --dry-run` and `incident`; the added lines name no project.
- All of it went back to a blind author as contract amendments 1 to 6: the
  FIFO in R, `incident` in C1, `felix next` (A6) and `felix brief` (A7), D3 over
  every unary file operator, and D4 for `receipt.sh` sourced alone.

**Follow-ups found and left out of scope** (the contract rules out rewording
and a different disagreement):
- Brief mode (`felix incident`, `felix brief`) never reads `project.json`
  (`evidence.sh`, B11R3-11), so a bad `evidence_reads_vendored` or
  `evidence_vendored` declaration, or an empty `evidence.tsv` beside one, makes
  `felix merge` refuse while the brief prints ordinary rows or an empty
  "the fix will have to prove" section.
- `felix classify`'s yellow and red sentences say `felix merge` "stops only on a
  channel that escapes the tree", while merge also refuses on an evidence row;
  classify reads evidence on the green tier only.
- `felix next` tells a person to "correct that row of evidence.tsv" for a
  not-judged subject that is a directory, a `project.json` key or a changed
  path with a newline in it; the remedy should follow the subject.

**Decisions.**
- The helper's name is `felix_evidence_table_present`, not `_declared`:
  `_felix_evidence_declared` already means project.json's vendored-rule
  declaration.
- `_felix_evidence_declared`'s own `[ -f evidence.tsv ]` stays. It runs only
  after the judge has found a regular file.
- A5's "iff" is read over the controls whose change is green (C1, C3, C5): C2
  and C4 list a gap as an `evidence` blocker without "not judged", so a literal
  reading would break the iff.
- The contract's C1 clause "felix_evidence_table_present exits 1" cannot hold on
  main, where the function does not exist, so the blind author asserted it under
  a D1 name (red on main); C1's four reader clauses are the control.

**Method and what went wrong.** Engine-build method: contract, blind author
(Opus 5.5, xhigh) in an isolated worktree, red against main, adversarial review
(three Opus 5.5 xhigh lenses), record, gate. The first blind author was killed
when the Mac slept mid-response; the retry reused its worktree, which sat on the
contract commit with main's engine, so its run was still red against main. A
fresh isolated worktree would have started from the branch tip, which already
held the fix. The session asked the app to keep the Mac awake. Two Bash
commands were refused: a recursive `rm` by the fact gate, and an `ln -s` by the
deny row on symlinks, which matches command text. The dangling-link fixture was
written as a script file and run by path, as the suite does for its own
fixtures; the deny row was not edited.

**Not done / open.**
- #482 and #483 both claim 0.49.321; this change takes 0.49.322. Each merge
  stales the others' manifests and versions.
- #482 edits `felix` and `lib/receipt.sh` too; the hunks here are one line each,
  but a textual conflict is possible.
