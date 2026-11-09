# The change readers' merge ignores the checkout's merge configuration (S6.6, 0.49.334; S6.7, 0.49.337)

2026-11-08. A security finding and its fix, separate from trust step 3's slices. It was found while building slice 2
(#497), and it was present on main before that (0.49.332), where the readers' code is byte-identical.

**Scope:** the two readers that take a 3-way merge when main has moved since the branch was cut, `felix_added_lines`
and `felix_changed_paths` in `engine/harness/lib/resolve.sh`, through `_felix_merge_refs`. The escape scan's
destructive-SQL check and `lib/classify.sh`'s content rows read the added lines through them, and the escape scan's
path rules (the risk table's rows) read the changed paths through them. `bin/secret-scan`, behind the `disclose`
escape, reads the three-dot diff instead. Out of scope, and recorded open at the end:
- other readers that run git in the worker's checkout (the class is slice 3's partition, spec E5);
- the index and the working tree (inventory E3);
- products' homes.

## What was found

When main has moved since the candidate was cut, `felix_added_lines` reads the lines a change adds from
`git merge-tree --write-tree base HEAD`. For each path both sides changed, that 3-way merge runs the merge driver the
attributes name, and a driver is defined in git config. The checkout's own `.git/config` and `.git/info/attributes`
are the worker's to write, and slice 2's scrub (S6.1) clears only the environment.

A driver `true` keeps main's side of the file and exits 0. The candidate's lines in that file are then not "added",
and the provider's squash still lands them. Shown on #497's head 5616dba9, in a scratch copy of part 2178:
- **An added line.** A candidate adds a line shaped like a credential (a `TOKEN` variable set to a planted value) to
  a file main also changed. With no driver it is refused.
  With the checkout's driver named, it is **merged**. Which rule refused it was not recorded. `bin/secret-scan`, behind
  the `disclose` escape, reads the three-dot diff and takes no merge, so a line it flags is still refused with the
  driver. What the driver hides is a line read through `felix_added_lines`, such as the escape scan's destructive SQL
  check and `lib/classify.sh`'s content rows.
- **A danger path.** A candidate changes `danger/y`, which main also changed. With no driver it is refused
  (`escape exfil`, the risk table's red `^danger/` row). With the driver, it is **merged**.

A built-in `union` driver, named by the candidate's own `.gitattributes` with no config, keeps both sides, and the
line is still read.

**A second hole, found by the fix's review.** While the checkout's objects are reachable, `merge-tree` takes a loose
object planted there under the merged blob's id as already written. If that object holds main's bytes, the line is
lost the same way, with no driver at all. Slice 2's check (S6) covers the objects of B, H and their merge base, and
the merge's result is not among them. Shown by the fix's blind rule-2 cases, inside `felix merge --dry-run` without
rule 2: a candidate adding destructive SQL is refused (`escape durable ADDED-LINES`) without the plant, and would be
squashed with it. A credential line is still refused with the plant, by `disclose`, which reads three-dot.

## The fix (S6.6)

1. **Where the merge runs.** `_felix_merge_refs` runs `merge-tree` in an empty bare repository it makes for the call:
   - its object store is the one the checkout reads: `GIT_OBJECT_DIRECTORY` when the caller set one, as `felix merge`'s
     checked copy does;
   - the two sides are named by commit id, resolved once in the checkout, and a shallow checkout's boundary is copied
     in;
   - global and system config and attributes are off (`GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`,
     `GIT_ATTR_NOSYSTEM=1`, `core.attributesFile=/dev/null`), and the repository has no `info/attributes`;
   - the caller's `GIT_DIR`, `GIT_WORK_TREE`, `GIT_COMMON_DIR` and `GIT_INDEX_FILE` reach neither git;
   - a relative object directory is read from the checkout;
   - a TERM or INT removes the directory.

   A `.gitattributes` in the merged commits' own trees can then name only git's built-in drivers, unless the caller's
   environment defines one (`GIT_CONFIG_PARAMETERS`, `GIT_CONFIG_COUNT`). Under `felix merge`, slice 2 has replaced
   those with its own.
2. **Inside `felix merge`, the checked copy alone.** Once slice 2's copy is in force, the merge's only alternate is
   the copy's `v` store. What the merge writes is then its own result, written into the copy, which the readers' diff
   reads first. `lib/bind.sh` keeps the copy's location in a shell variable, unset when it loads.

   As 0.49.334 landed it, this rule made the merge fail whenever the merge base had a parent: the copy holds no commit
   older than the base, and `merge-tree` walked to its parents. Inside `felix merge` every reader then took three-dot,
   the stricter direction. Part 2179's fixtures never reach a base with a parent, so it passed either way. 0.49.336
   writes the base into the made repository's shallow file when the copy is read alone (slice 3's A20, in
   `docs/2026-11-09-trust-step3-slice3-measurement.md`).
3. **Failure** falls back to the three-dot diff, as before. Three-dot over-reports, so the fallback can make a verdict
   stricter and never weaker.
4. **Unchanged** for a configuration with no driver, attribute or merge setting.
5. **No directory renames (S6.7, 0.49.337).** The merge runs with `merge.directoryRenames=false`, given on its
   command line, so no config file and no `GIT_CONFIG_*` variable the caller exports turns it back on.

   Found after 0.49.336 landed: `felix merge` refused #498, a handoff fold that empties `docs/handoff/pending/`, with
   unknown SUITE. Under git's default (`conflict`), the merge took pending/ as renamed into docs/handoff/, moved the
   four files main had since added there, and failed. With no tree, every reader took three-dot, and slice 3's A1
   refused. With `true`, the files move and the merge succeeds, and the changed paths then blame the branch for
   main's files; a caller's `GIT_CONFIG_PARAMETERS` or `GIT_CONFIG_COUNT` reached the merge and could set that.
   GitHub's own test merge of #498 (`refs/pull/498/merge`) holds byte-for-byte the tree git writes with `false`, and
   the squash `felix merge` lands is GitHub's. That is one pair observed, not GitHub's setting shown in general. The
   finding and the spec are `audits/2026-11-08-trust-plane-step3/merge-dir-renames/` in the memory root.

## Shown

- **Blind part 2179,** written from the spec before the fix: 15 of its 31 assertions passed on main (0.49.332) and 31 of 31 on the fix.
- **Its rule-2 cases,** written blind from rule 2 after the first fix: on the branch without rule 2 (325b6aa2), 13 of
  14 pass and the planted-SQL case fails; with rule 2 (51d99a03), all 14 pass, and part 2179 as a whole has 45 of 45.
- **The review's three branch cases:**
  - `GIT_COMMON_DIR` naming the checkout;
  - `GIT_WORK_TREE` set;
  - a relative object directory, from another working directory.

  In each, the reader takes the merge, keeps the line and runs no driver.
- **Blind part 2184,** written from S6.7's spec before the fix: 12 of its 25 assertions fail on 0.49.336 and 25 of
  25 pass with the fix. Part 2181, which holds A1's cases, still passes in part mode: 40 lines, none failing.
- **The suite** ran in full under `tests/run --record-assertions` before the pull request opened. Its counts, and
  `felix gate`'s, are in the pull request's body.

## Cost

Measured on this Mac: `_felix_merge_refs` on a diverged branch of 200 files, 40 calls in each of three runs, CPU from
`getrusage` with children. It took about 21 ms a call on main and 57 to 58 ms with the fix. The difference is the
made repository and the extra reads that name the sides.

The readers take the merge only when main has moved since the branch was cut. When it has not, they return early, as
before.

## Not reached

- **Other readers that run git in the worker's checkout,** with its config. The class is slice 3's partition (spec E5),
  where P's instruments read an export of H's committed tree.
- **The built-in `binary` driver,** named by the candidate's own `.gitattributes`. It is expected to conflict and fall
  back, and it was not run.
- **Other config the merge reads** in the made repository. None comes from the checkout's files. Directory renames are off
  since S6.7; file renames and conflict style are git's own defaults, and they were not varied against GitHub's.
- **The stuck-PR page (`lib/pr-status.sh`)** takes no merge: it asks GitHub for `mergeable` and the merge state.
  An earlier version of this list said it ran its own `merge-tree`; it does not, and has not (review of S6.7,
  2026-11-09). Nothing else in the engine computes a merge tree.
- **`bin/secret-scan`,** which keeps its own copy of the patch reader. It reads three-dot, so it takes no merge.
- **Outside `felix merge`** (the gate's readers), the checkout's objects are still reachable, so a planted merged blob
  still hides a line there. The gate's receipt is the worker's file (residual R4), and the merge itself reads the copy
  alone.
