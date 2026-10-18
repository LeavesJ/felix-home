### 2026-10-18: the judge's base is a full ref name, and the deploy comparison reads main's stored tree against the whole cache entry, raw

The two new slot class entries the carrier recorded on 2026-10-15 (see
`audits/2026-10-08-carrier/state.md` under the memory root) are built on
`claude/judge-refs-residue`, LeavesJ/felix-home#446. The branch is a
security change, kept apart from other work.

**Contract.** `docs/2026-10-18-judge-refs-residue-contract.md`:
- Part A: which commit "main" names (A1-A12).
- Part B: what counts as residue (B1-B10).
- Part C: what the review of the first fix found (C1-C8), plus two
  follow-ups.

**What changed.**
- **`felix_base_ref` has one definition.** It prints full names
  (`refs/remotes/origin/<base>`, then `refs/heads/<base>`), looked up as
  refs of exactly those names:
  - `origin/X` reads only `refs/remotes/origin/X`;
  - a full-length object id, in either case, is an object name.
- **Readers that resolve through it.** `felix_kernel_dir` and the felix
  gate's `installed` check read main by full name.
- **`felix merge`'s base.** It takes only a ref name that passes
  `git check-ref-format` and resolves by full name. Otherwise it refuses:
  it never uses the name as given (A12, C8).
- **`felix_accepted_deploy_diff` reads main once, by sha.** Main's side is
  the `git ls-tree` paths, modes and blob ids. The entry's side is every path
  under the entry, with its type and a raw `git hash-object --no-filters`
  hash. No `git archive` and no checkout settings enter.
  - It compares at every top-level name, `.claude-plugin/` included, by type
    and mode as well as bytes.
  - An entry-only path is residue only beneath `harness/` and `hooks/`, and
    only when the `.gitignore` blobs main holds match it. Those rules are
    read in a scratch repository that no machine-local input reaches.
  - A path main ships is never residue.
  - TERM and INT remove its temporary directory.
- **The working-tree form** (`felix install`'s verify, `felix next`) never
  treats a path the repository tracks as residue.
- **Version:** 0.49.300 is the placeholder, set by the carrier; the real
  number is set at "you are next".

**Evidence.** Part runners only, by the carrier's order. No record and no
gate yet.
- **Blind parts 1400-1402**, written from the contract by an author who did
  not read the code under test:
  - 156 ok / 121 FAIL on main ddad08e1;
  - 1402 (A12) alone: 20 ok / 9 FAIL on main.
- **Part 1403 (C1-C8)** was written by the implementer from the review's
  measured cases, not blind. It was 33 ok / 31 FAIL before the fix.
- **On the head 6946a00f:** 1400-1403 read 341 ok / 0 FAIL. With #447's parts
  1500-1540 in the same run, there are 2 FAILs, and both show identically on
  main 0db47b70: the cut runner exports no `bin/`.
- **On real input:** the new comparison, run under `/bin/bash` against this
  machine's real cache entry for main's 0.49.295 and
  `refs/remotes/origin/main`, returned "identical" in about 1 s and left no
  temporary directory. That entry holds exactly main's `engine/` tree: same
  four top-level names, same files, all 23 executables keep their bit, and
  there are no non-regular files.
- **Two Opus review rounds:**
  - **Round 1 (3289129f):** 20 of 23 mutants were caught. It found the
    conversions applied when main was read through archive, and the
    three-directory scope; those became Part C.
  - **Round 2 (669a3cad):** every case round 1 had measured as accepted now
    reads as drift. 12 of 13 new mutants were caught; the survivor is
    equivalent (`--no-filters` inside the clean scratch repository).
  - **Its verdict:** Parts B and C close hole 2, and the branch with Part A
    supersedes #360.
- **Restated parts.** Existing parts that expected the short base name, the
  checkout's ignore rules, `--base HEAD~1`, or cache entries holding
  `harness/` alone were restated, each with a 2026-10-18 comment:
  - 0100, 0110, 0340, 0350, 0360, 0430, 0440, 0970, 0990, 1250;
  - 1280-1282, 1284-1286, 1500.

  Under an always-accept mutant they fail 49 times, each for its named
  reason.

**Operational note.** A file at the top of the home's `engine/` that is not
`harness`, `hooks`, `commands` or `.claude-plugin` will read as drift once
the next install copies it into the cache. A `.DS_Store` is one example. The
gate's `installed` check then fails until the stray is removed and the
engine reinstalled at a new version. It fails closed and names the path.

**Draft #360.** Its branch `claude/deploy-diff-residue-tracked` is
superseded:
- **Covered here:** tracked content is never residue, and main is read from
  one commit.
- **Left open in #360:**
  - ignore rules are still read from the checkout;
  - there is no `commands/` rule;
  - main is still read through `git archive`.
- **In #360 and not here:** a bound on git calls per diff line, and a stray
  listed first. Neither is a defect here.

The carrier passed the supersession to the founder, who owns that PR.

**Follow-ups, not in this change** (proposed as sessions):
- **The judge reads its libraries from a writable directory.** `felix merge`
  verifies the cache entry, then sources the judge's libraries from that
  directory. The fix: source main's libraries, read by sha, from a private
  directory.
- **`refs/remotes/origin/main` is trusted.** Every guarantee here assumes
  that ref is the remote's. Nobody has checked whether the deny rows keep a
  session from moving it.
- **Latent, minor:** if main ever ships a symlink or gitlink under `engine/`,
  the comparison would read it as drift forever. Main ships none today.

**Traps paid.**
- **The executable bit.** A merge resolution that rewrote `tests/run`
  through a temporary file and `mv` dropped its bit, and CI's executable
  check caught it. Resolve conflicts in place.
- **The safety classifier.** Asking a blind author for Part C's catalogue of
  cases was stopped (memory `classifier-stops-refusal-case-authoring`).
  Part C's cases came from the review's measured fixtures instead.
- **zsh.** Sourcing the bash library in zsh gave a false "declares no engine
  version". Run real-input checks under `/bin/bash`.

**Each part runs alone (gate friction C).** 1401 used 1400's helpers, its
jrr project and its JS and JG fixtures, and alone it stopped with 95 FAILs.
- **The move.** 100 lines moved verbatim into `tests/lib/judge-refs.sh`,
  which defines functions and nothing else. Its builders are `_jr_project`,
  `_js_build` and `_jg_build`, and their bodies are 1400's own lines.
- **Who builds what.** 1400 calls the builders where those lines stood, and
  removes what it built at its end. 1401 builds its own fixtures before B10.
- **Measured with C's `marked.sh` on 358eaf4a.** Each of 1400-1403 runs
  alone with 0 FAIL and no unbound name. Each part's (verdict, name) pairs
  are the same alone and in order. Run in order, the four print the same 403
  pairs as before the move. The lint passes on the lib file.
- **Until C lands, each part sources the lib file itself.** Main's driver
  copies do not carry `lib/`.

**Landing.**
- **At the merge with C.** Drop the two per-part `. "$HERE/lib/judge-refs.sh"`
  lines. Add `judge-refs.sh` to C's lib block in name order, after
  `inventory.sh`. Run 1290, then each new part alone.
- **Escapes and judge code.** The branch changes judge code in
  `lib/resolve.sh` and `felix`, and changes `projects/felix/gate.sh`, so it
  stays draft and needs-founder.
- **When it binds.** The gate and `felix merge` read `lib/resolve.sh` from
  main, so the change binds only after it lands.
- **Records.** CI's gate is red until the record: `red.tsv` and the manifest
  wait for the carrier's `tests/run --record-assertions`.
