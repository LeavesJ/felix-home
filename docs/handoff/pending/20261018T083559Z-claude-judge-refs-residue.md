### 2026-10-18: the judge's base is a full ref name, and residue comes from main's committed rules; Part C is written and not built

The two new slot class entries the carrier recorded on 2026-10-15 (see
`audits/2026-10-08-carrier/state.md` under the memory root) are built on
`claude/judge-refs-residue`. The branch is a security change kept apart from
other work. The review found more in the same function, and that part
(Part C) is specified but not built. So the branch is **not ready to land**
as the fix for hole 2.

**Contract.** `docs/2026-10-18-judge-refs-residue-contract.md`:
- Part A: which commit "main" names, A1-A12.
- Part B: what counts as residue, B1-B10.
- Part C: what the review found, C1-C8, plus two follow-ups.

**Built and tested (A and B).**
- **`felix_base_ref` has one definition.** It prints full names
  (`refs/remotes/origin/<base>`, then `refs/heads/<base>`), looked up as
  refs of exactly those names.
  - `origin/X` reads only `refs/remotes/origin/X`.
  - A full-length object id, in either case, is an object name.
- **Readers that resolve through it.** `felix_kernel_dir` and the felix
  gate's `installed` check read main by full name.
- **`felix merge` takes only a full ref name as its base** (A12). It refuses
  rather than fall back to the name as given. Five existing parts passed
  `--base HEAD~1`, and they now name a branch made at that commit.
- **`felix_accepted_deploy_diff` reads main once, by sha.** Residue comes
  only from the `.gitignore` blobs main holds, read in a scratch repository
  that no machine-local input reaches.
  - A path main ships is never residue.
  - Nothing under `commands/` that only the entry holds is residue.
- **The working-tree form** (`felix install`'s verify, `felix next`) never
  treats a path the repository tracks as residue.
- **Version:** 0.49.299 is a placeholder; the carrier assigns the number.

**Evidence.** Part runners, not the full suite.
- **Blind parts 1400-1402**, written from the contract by an author who did
  not read the code under test:
  - 156 ok / 121 FAIL on main (ddad08e1), and 277 ok / 0 FAIL on 3289129f;
  - 1402 (A12) alone: 20 ok / 9 FAIL on main, 29 / 0 on the fix.
- **Regression parts** (0100, 0110, 0340, 0350, 0440, 0640, 0970, 0990,
  1250, 1280-1286 and their predecessors):
  - every changed verdict is accounted for;
  - two FAILs show on both sides, and are the cut runner's export directory.
- **The review's mutants:** 20 of 23 were caught.
  - One survivor is a real gap (rules read by short name); C5 pins it.
  - The other two pin the directory-form query and `show-ref` over
    `rev-parse`. One of those is equivalent while the ref exists.
- **The runner:** `jrr-runner.sh`, in this session's scratchpad. It exports
  engine/ and projects/felix/gate.sh from a committed revision and runs
  parts 0001-0005 plus 1400-1402 from a fresh temporary directory.

**Not built: Part C.** The review measured that the comparison still reads
main's side through `git archive` in the home. Archive applies that
checkout's attributes and filter settings, so the bytes compared are not
main's stored blobs. It also measured that the comparison covers only
`harness/`, `hooks/` and `commands/` of the entry. The design the review
proposed, and C1-C4 require:
- read main's side as `git ls-tree -r` paths, modes and blob ids;
- hash the entry's files raw (`git hash-object --no-filters`);
- compare type, mode and blob id at every top-level name;
- residue only for entry-only paths beneath `harness/` and `hooks/` that
  main's committed rules match.

Measured 2026-10-18: the real entry for main's 0.49.295 holds exactly main's
`engine/` tree, with the same files and modes and no non-regular files. So
this comparison turns nothing red today.

Part C's blind assertions were not written. The authoring turn was stopped
by the safety classifier, as on 2026-09-23 (memory
`classifier-stops-refusal-case-authoring`). Restating the brief must not be
tried again. The next author should take Part C's cases from the review's
measured fixtures instead, phrased in terms of what the comparison reads.
Those fixtures are in its scratch directory under
`/var/folders/hf/qc508jj12bn1xms5slg2x6w00000gn/T/rev-jrr.H55Av6`
(`e1.sh`-`e4.sh`, `m/`, `logs/`), which a hook kept from being deleted.

**Draft #360 is superseded.**
- **Covered here:** `claude/deploy-diff-residue-tracked` closes two of the
  same things. Tracked content is never residue, and main is read from one
  commit. This branch does both.
- **Left open in #360:** it still reads ignore rules from the checkout, so
  hole 2 stays open there. It has no `commands/` rule, the follow-up it
  owed. It reads main through `git archive` in the home, as Part C
  describes.
- **#360 has two tests this branch lacks:** a bound on git calls per diff
  line, and a stray listed first, so that a query reading stdin would
  swallow a drift line. Port them if wanted. Neither is a defect here: every
  query in the loop reads `/dev/null`.
- **Recommendation:** close #360 in favour of this branch.

**Follow-ups, not in this change.**
- **The judge reads its libraries from a writable directory.** `felix merge`
  verifies the cache entry, then sources the judge's libraries from that
  directory. The fix: source main's libraries, read by sha, from a private
  directory.
- **`refs/remotes/origin/main` is trusted.** Every guarantee here assumes
  that ref is the remote's. Nobody has checked whether the deny rows keep a
  session from moving it.

**Landing.**
- **Escapes and judge code.** The branch changes `projects/felix/gate.sh`
  and the judge code in `lib/resolve.sh`, so it opens as draft and
  needs-founder.
- **When it binds.** The gate and `felix merge` read `lib/resolve.sh` from
  main, so the change binds only after it lands.
- **Merging main in.** Main moved to ddad08e1 (A30, 0.49.295) after the
  branch was cut from 248d9c7e. The carrier merges main in at the slot.
- **Records.** `assertions.tsv` and `red.tsv` wait for the carrier's record.
