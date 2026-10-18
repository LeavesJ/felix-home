### 2026-10-08 — a Felix home whose path holds a space resolves through the pointer

**One engine PR, 0.49.280** (branch `claude/quirky-heisenberg-fc2149`). It is
the fix the #406 section left for another session. That session wrote it on
2026-09-24 as c49fbeb8, pushed it, and ended before opening a pull request.
The 10-01 carrier listed it as post-queue. The binding-paths session (#406)
carried it from there: main merged in, only the version line conflicted.

**What was wrong.** `felix install --home` writes the path verbatim.
`felix_home` and `felix_binding_broken` read it with `tr -d '[:space:]'`,
which deletes the spaces inside a path as well. A real home at
`<tmp>/Mobile Documents/Felix` fell back to `~/.felix`, and the stop hook
refused naming `.../MobileDocuments/Felix`, a path nobody wrote. iCloud's
`~/Library/Mobile Documents/` is the common place for a stranger's home.

**The change.** One reader, `_felix_home_pointer` in `lib/resolve.sh`, trims
whitespace at the two ends and nothing inside; both readers use it, and
`projects/felix/snapshot.sh` reads the pointer the same way. An empty or
whitespace-only pointer still reads as empty. On 2026-10-08 main had no other
reader of `~/.felix-home`.

**tests/run, +3, red on main.** A real home under `Mobile Documents` holding
the widget project: `felix_home` resolves to it, the stop hook raises no
refusal, and `felix which` governs from it. Run as a section (the preamble
plus the stop-hook section through the new block), all three failed against
main's engine and passed against the branch. The record's `red.tsv` is the
full-suite version of that.
