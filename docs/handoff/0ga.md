### 0ga. 2026-11-08: part 1495 compares two page runs with the ages they print put aside, so a minute boundary between the runs is not a failure (suite only, 0.49.335)

**What this is.** A flake in the test, not in `felix monitor`. On 2026-11-07 a full `felix gate` on main 4b3179ff went red on part 1495's "B9.41: and stdout is exactly what felix monitor --repo B prints with the real awk" (35 min against 45), because the Mac slept between the two runs. The part passed 85/85 alone. Branch `LeavesJ/practical-driscoll-e10880`; no engine code changed.

**Cause.** The part compares two runs made at different moments, byte for byte, and its header said two runs seconds apart print the same bytes. They do not: the origin row reads the clock (`lib/pr-status.sh` `_ps_fetch_age`, `lib/inventory.sh` `_FI_NOW`, both `date +%s`) and prints "origin/main last moved N min ago; last fetch, of any ref, N min ago", and the default-branch cover row prints "fetched Nh ago".
- The brief's guess that the `--tsv` twin carries no relative time was wrong. `felix monitor --tsv` holds the origin source row and the default cover row, `felix land --prs --tsv` holds the origin row, and `felix inventory --tsv` holds the cover row. All four comparisons in the part carry a clock-read age, not one: the control at "under the stub felix inventory --tsv and felix land --prs --tsv" (minutes in `land`, hours in `inventory`), the text page, and the TSV. The TSV twin failed under the clock skew below as well, so it passes while its two runs fall in one minute.

**What changed (`tests/parts/1495-lost-work-page-awk-fails-blind.sh`, one file).**
- `_lw95_unaged RUN` puts every `N min ago`, `N h ago`, `N days ago` and `fetched Nh ago` as `<age> ago`; `_lw95_same` compares the runs through it. No other byte is changed, bar a final newline that `sed` may supply on both sides.
- The two assertions that said "exactly" now say "the ages each prints aside". One assertion is new, a fixture control: pages that differ only in an age are the same, another commit or another word is a difference, and no reference output is no verdict. Its name has no count in it.

**Shown red, then green.** The clock was skewed with a `date` shim first on PATH (every `date +%s` answers real time plus S seconds per call so far), so no two runs read one clock. The engine was not touched.
- The unchanged part: 2 FAIL at S=125 s, and 3 at S=3700 s, on the three comparisons above. The failure text is the flake's own: `fetched 23h ago` against `27h ago`.
- The changed part: 86 pass, 0 fail, plain and at S=61, 97 and 125 s.
- Two mutants of `_lw95_unaged` (no mask; a mask over every hex digit) each fail the new control and nothing else, so the control is armed in both directions.

**Not blind, and said so.** This corrects an assertion of a part that was written blind in #454; no spec changed, so there was nothing to derive from. The new control was written after the fix and mutation-checked, not red-first against a spec.

**Left open.** The worktree row's `age_h` column and the `, 23h:` suffix of the page's worktree lines are also clock-read, in whole hours since a commit. The part's header says `age_h` is 0 for commits made inside the part, so they should change only if an hour passes between building the fixture and a run. At S=3700 s the changed part still fails three names, on `age_h` and `Nh:` and nothing else. The part does not mask them, because masking a column by position is the wider change; a Mac that sleeps for an hour inside one part would still trip them.
A search of the parts that run `monitor`, `inventory` or `land --prs` for `cmp`, `diff`, `_same`, "byte for byte" and "exactly what" found no other comparison of two page runs: 1470's B9.34 compares repository snapshots, 0870 compares kind and state columns, 0880 compares file snapshots, 1020 and 2470 read commands that print no age. A comparison written another way would not have been found. A class rule (a lint on two page runs compared without the mask) is not built.

**Gate.** The result is in the pull request.
