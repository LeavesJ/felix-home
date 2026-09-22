## 0ax. Verified at session close, 2026-09-12 (late) — the history was cleaned, and the sweep found one commit that existed on one disk

| | |
|---|---|
| remote branches | **148 → 11**; 138 deleted, all of them with a merged pull request |
| local branches | **179 → 33**; 146 deleted, every one patch-identical to `main` |
| kept | `main`, the open PR, four closed-unmerged, three that never had a PR, two salvage refs |
| archive | `branch-archive-2026-09-12.tsv` in the memory root: branch, tip, PR, merge time |

**The founder handed this decision over, so here is the rule it was made on.**
Delete a branch only when GitHub reports its pull request merged. That is safe
for a reason worth writing down rather than assuming: the remote carries
`refs/pull/<n>/head` for every pull request it has ever had — 181 of them, one
per PR, merged or closed — and those refs outlive the branch. Checked against a
branch deleted last week: `docs/handoff-0at` is gone and `refs/pull/217/head`
still resolves to its tip. So deleting a merged-PR branch destroys no commit,
and the pull request page restores the branch itself on request. Branches that
never had a pull request are the only ones where deletion would lose objects,
and all three of those were kept.

**The squash is why the naive instrument reads wrong.** `felix merge` squashes,
so a merged branch is not an ancestor of `main` — 9 of 148 were reachable, and
that number says nothing about the other 139. Patch identity is the instrument
that works: `git cherry origin/main <branch>` marks a squashed commit as
already applied because the squash of a one-commit branch has the same diff.
Of 39 local branches holding commits on no remote, 31 were that artifact and 8
were real.

**Verified before anything was deleted, and the verification earned its keep.**
Sixteen branches spread across the list went to two independent lenses each —
pull-request provenance, and content presence in `main` ignoring ancestry —
with instructions to default to unsafe. Thirty-two verdicts, none of them
saying work was missing. A separate critic was asked for the class the sample
would miss, and found four, three of which resolved safely: a branch with
commits pushed after its merge (`feat/pulse`, re-landed by #119), a partial
squash where the rest had landed directly on `main` (`claude/felix-development-ea0f37`),
and 27 branch names cited in prose that outlives the ref.

**The fourth was real.** `fix/the-fold-count-says-what-it-folded` carried a
local commit, `53fc527`, written three minutes before its pull request merged
and never pushed. It is an ancestor of no remote ref and of no pull-request
head, and the three assertions it adds are absent from `main`'s
`assertions.tsv`. Nothing in the delete list would have taken it — the patch
check had already held that branch back — but the ordinary follow-through
would have: `git fetch --prune`, then delete every local branch whose upstream
is gone, and it goes without a word. It is now pushed to
`salvage/fold-count-read-not-grepped`, so it exists off this disk for the first
time. Whether those assertions should land is a separate question nobody has
answered.

**What this session got wrong, before it got it right.** The first deletion
attempt built the refspecs into a shell variable and ran `git push origin
$refs`. Six batches, six failures, and the loop printed `ok` after each one
because it echoed a word instead of testing a status. The cause is a lesson
this repository already holds: **zsh does not word-split an unquoted variable**,
so 25 refspecs arrived as one argument. Nothing was deleted, and the report
said everything was. `xargs` splits correctly and reports what it did.

**Next, in order.** (1) `graphify` is due again, because #220 merged; the
refresh this session ran predates §0aw and §0ax. (2) The next checker through
the six controls, blind. (3) find-skills item one, the content hash. (4) Step
2's epochs as hashes. (5) Standing, from §0aw and unchanged: `projects/bazaar/`
and `projects/webapp/` are still untracked, and that is the founder's call.

