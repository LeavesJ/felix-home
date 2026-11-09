### 2026-11-09: the readers' merge detects no directory renames, as GitHub's merge does (S6.7, 0.49.337)

**What this is.** A fix to the change readers' merge (`_felix_merge_refs`, `lib/resolve.sh`), on branch `claude/trust-merge-dir-renames`, found right after 0.49.336 (trust step 3, slice 3) landed. The finding and the spec are in the memory root, `audits/2026-11-08-trust-plane-step3/merge-dir-renames/`.

**What changed.**
- **`lib/resolve.sh`.** The merge runs with `merge.directoryRenames=false`, given on its command line. On 0.49.336, `felix merge` refused #498, a handoff fold that empties `docs/handoff/pending/`, as unknown SUITE: git's default took the directory as renamed, moved the files main had since added to it, and failed, so slice 3's A1 had no squash tree. GitHub's own test merge of #498 holds the tree git writes with `false`. A caller's `GIT_CONFIG_PARAMETERS` or `GIT_CONFIG_COUNT` reached the merge before, and the command line now wins over both.
- **Tests.** Blind part 2184: 12 of its 25 assertions fail on 0.49.336, and 25 of 25 pass here.
- **Docs.** `docs/2026-11-08-trust-merge-driver.md` gains rule 5; slice 3's measurement names the false block.

**Open.**
- GitHub's merge settings are read from one pair, #498 onto main at 4dd8fed8, and not shown in general.
- A shape where GitHub would detect a directory rename, if one exists: there the readers would name a path at its old place while GitHub lands it at the new one. The review found no such shape in plain git, and the path set is what it was before the fix.
- The stuck-PR page takes no merge; it asks GitHub. The 0.49.334 write-up said otherwise, and is corrected here.
- File renames and conflict style are git's defaults, not compared with GitHub's.

**Release.** 0.49.337 fails closed until the founder authorizes it by name (direction row 49). The pull request is labelled needs-founder.
