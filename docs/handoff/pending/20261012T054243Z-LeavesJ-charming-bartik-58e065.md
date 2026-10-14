### 2026-10-11: every uses: in felix-home's own workflows is a commit sha, and the suite holds every workflow beside the harness to it

**Engine 0.49.280**, the next free number after main's 0.49.279. It is
row "?" of the 10-08 carrier queue
(~/.felix/memory/felix/audits/2026-10-08-carrier/state.md). No carrier was
running, so the founder approved the merge directly on 2026-10-12. It was
built on 10-08 at a 0.49.274 placeholder, which #418 took. Main 97cdd50a
(0.49.279) was merged in, then 53d076a0 (#422, docs only). The block moved
into parts/0160 after #424 split tests/run. If another engine PR lands
first, renumber.

**What changed.** `.github/workflows/gate.yml` ran both checkouts on
`actions/checkout@v4`, a tag its owner can move. Both now name
`fbc6f3992d24b796d5a048ff273f7fcc4a7b6c09 # v5.1.0`, the commit the
templates already pin (#403 for unattended.yml, #354 for what bootstrap
renders):
- `gh api repos/actions/checkout/git/ref/tags/v5` read a lightweight tag
  (`object.type` commit, nothing to dereference) at that sha on 10-08 and
  again on 10-11, and `refs/tags/v5.1.0` names the same commit.
- v5 rather than v4: v5 is the lowest major on Node 24, the templates moved
  to it, and nothing in this workflow needs v4. Both steps keep every `with:`
  key: `persist-credentials: false` on both (#346), `fetch-depth: 0` on the
  gate job.
- They are the only `uses:` lines in the directory. `reuse-verified-tree.sh`
  and its test hold none and read gate.yml only as a path name. The test
  passes 27/0.

The two sibling sections held what Felix renders for other repositories.
felix-home's own CI was left out of #354 (§0dc, "out of scope, and a
person's"), because a change under `.github/workflows` is an `execute`
escape: `felix merge` refuses it and the founder merges it.

**The test** ("every uses: in the workflows beside this harness names a full
commit sha, not a ref its owner can move", the last section of
tests/parts/0160-unattended-readiness.sh) reads every `.yml` and `.yaml` in
`$REAL_HARNESS/../../.github/workflows`, and every `uses:` key in each, a
step's or a job's, with the reader the two sibling sections use. It fails
when:
- no workflow file is there;
- awk could not read one of them (its exit status is kept, not piped away);
- the files hold no `uses:` line between them;
- any value does not end `@` and 40 lowercase hex.

Shown red first with the one-block section runner (the driver's preamble,
then this block, spliced by its header):
- against a `git archive origin/main engine .github` of 97cdd50a it reads
  `gate.yml:42: actions/checkout@v4;gate.yml:66: actions/checkout@v4`, and
  it passes on this tree;
- mutants, each failing as named: no workflow file; workflows with no
  `uses:`; an unreadable workflow (awk exit 2); a quoted tag; a `.yaml` file
  with a tag; a seven-hex sha; a job-level reusable workflow on `@main`; an
  uppercase sha;
- each passing as it should: a commented-out tag, and a single-quoted pinned
  value.

**What it will stop next, and it is a person's to clear.** A snapshot's
verification clone (projects/felix/snapshot.sh, `$OUT/verify`) is the public
repository, and its `.github/workflows` holds LeavesJ/Felix's own
`suite.yml`, which runs `actions/checkout@v4`. Run on that file, the block
fails with `suite.yml:37: actions/checkout@v4`, so the next `snapshot.sh`
dies at "the suite did not pass on the snapshot". The public repository
keeps that file outside the staged paths, so the snapshot cannot carry the
fix. LeavesJ/Felix#6 pins `suite.yml` there to the same commit, and the
block passes on it. It must merge before the next snapshot. That is
deliberate: the public CI has the same hole, and an exemption for it would be
an instance of the rule rather than the rule.

**Not done here.** The `# vX.Y.Z` comment after each sha is a claim a
reviewer checks when the pin moves. No assertion reads it, here or in the
two sibling sections.
