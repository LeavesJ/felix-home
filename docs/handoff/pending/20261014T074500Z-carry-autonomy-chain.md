### 2026-10-14: the autonomy chain (slots 4-6), carried onto the split suite and the locale rule

Slots 4, 5 and 6 of the 2026-10-08 weekly batch are one pull request, as
the carrier ruled on 2026-10-08: revoke fails closed, `--allow` says allowed
only when it is, and the writer lock. They are carried by "Inventory work
prioritization" [49e3db] after their owners were archived. Their three
pending sections (`20261002T013810Z-claude-autonomy-revoke-fails-closed.md`,
`20261008T194539Z-claude-autonomy-allow-fails-closed.md`,
`20261008T201052Z-claude-autonomy-writer-lock.md`) say what the change is and
how it was reviewed. This section says only how it was moved onto main, which
since the branch was written has cut tests/run into a driver and parts (#424),
added the fixture guard (3+3b, #435) and added the locale rule (3c).

**How it was moved.** The tests were moved the way 3+3b was. 3c's driver and
parts were expanded into one file with a marker line at each part's start and
end, the branch's test diff from its merge base (e2748140) was merged into it
with `git merge-file`, and the result was cut back on the markers. The diff's
two hunks merged with no conflict:
- the one assertion the writer lock amends in part 0030 (the `.274` NUL
  case, now refused and the file left byte-identical);
- 2,989 lines of the chain's own blocks, which the branch had placed inside
  part 0570's "autonomy is opted into, never assumed" section, between "comments
  and blanks are not capabilities" and the commission-grant check.

**Where the new text sits.** The tests run in the order the branch tested
them. Part 0570 keeps its first 464 lines. The chain's blocks become parts
0571-0574, cut at their own section headers (742, 398, 972 and 877 lines). The
33-line commission-grant check that followed them becomes part 0579. The driver
sources five more parts (479 lines). `felix` and `lib/escape.sh` merged
without conflict.

**Owed at the merge.**
- The fixture guard: `_fx_lint` finds no raw `cd` or git call in the new parts.
- The locale rule: 3c's lint found four digit ranges in `lib/autonomy.sh`
  that bash reads by the locale's collation. Three are in the lock's size and
  inode checks (`*[0-9]*` twice, `*[!0-9]*`) and one in the fd it closes
  (`[3-9]`). Each is spelled out as 3c spelled the others.

**Version.** 0.49.290, after 3c (0.49.288) and row 0's B (0.49.289).
