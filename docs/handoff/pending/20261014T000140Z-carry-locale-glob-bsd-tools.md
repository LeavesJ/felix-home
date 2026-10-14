### 2026-10-14: the locale sweep (slot 3c, was 21+22), carried onto the split suite after 3+3b

Slot 3c of the 2026-10-08 weekly batch, carried by "Inventory work
prioritization" [9b9acc] after its owner [c686f0] was archived. Its two
pending sections (`20261008T213815Z-claude-locale-c-sort-comm.md`,
`20261009T005406Z-claude-locale-glob-bsd-tools.md`) say what the change is and
how it was reviewed. This section says only how it was moved onto a main that
has #424's driver and parts and 3+3b's fixture guard.

**How it was moved.** The branch's only test change was one block of 2,156
lines, added just before "the engine makes its scratch under TMPDIR". On main
that point falls 372 lines into part 1000. Those 372 lines are the end of
part 0990's section, so they moved to 0990 (842 lines). The block became parts
0992 (sort, comm, join and uniq), 0994 (bash's own collation and the BSD text
tools, to G1), 0996 (G1 to L4) and 0998 (L4 to the end), each cut at a
top-level comment and parsing alone under `bash -n`. Part 1000 keeps its own
section. The driver is 474 lines on main b0ea2150. The one engine conflict, in
`lib/maintenance.sh`, kept both edits: main's `rc` local and the branch's
`LC_ALL=C cut`.

**Conversions owed at the merge.** `_fx_lint` found 21 raw fixture git sites
in the block, the count the state file foresaw. All were converted by 3b's
rule, and the lint again reports only `_ff_case`'s three reviewed probes.

**Main's code since the branch was cut.** The branch's own lints found 17
sites in code main added after the branch was cut: one bare `sort` in
`lib/cost.sh`, and 16 digit-range brackets in bash patterns across
`lib/cost.sh`, `own.sh`, `reach-read.sh`, `reach.sh` and `status.sh`. Each was
written to the branch's rules (`LC_ALL=C sort`, brackets spelled out), one
line each, and no behaviour was meant to change.

**Found by the first full record on main (one red), fixed.** Part 1230
locates the gate receipt reader in `felix` by its text,
`reported="$(awk '`, and the sweep had made that line `LC_ALL=C awk`. The
locator now accepts either form, and still requires the reader and its
`tests:reused`. The second record passed 8838 with none failing. Corrected
here after #436 opened: this section first said the driver was 473 lines.
