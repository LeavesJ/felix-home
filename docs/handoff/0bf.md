## 0bf. Verified at session close, 2026-09-16 (night) — the ledger asks what main accepted, the same question as the gate

| | |
|---|---|
| merged | **#247**, red tier, on green CI; `felix merge` refused it on the stale commission receipt alone |
| deployed | **0.49.116**, carried in the pull request; the home's `felix install` deployed it byte-identical and wrote no bump |
| suite | **2256 passed, 0 failed**; 35 assertions added, blind, of which 30 fail against the previous engine |
| this session, in all | #243 #244 #245 #246 #247 and the section after this; three engine changes, each merged and deployed the same hour |

**§0be item 1, done.** `deploy-check`, the evidence behind the `engine_deployed`
obligation, asked whether the engine in the tree standing here was the live
plugin, and applied only where the marketplace served the tree — so the
obligation was dormant in every worktree and every runner while the gate's
`installed` check, since #239, asked whether the cache entry for the version
main declares holds main's engine. The two disagreed in every checkout that
was not the served one. Both ask main's question now, through one function,
`felix_accepted_deploy_diff`, that reads the version and the engine from the
base ref and compares the archive against the entry. The gate keeps its inline
copy on purpose — a verifier that sources the code it judges can be switched
off by editing that code — and the suite keeps the copies in step. The
obligation is ACTIVE in a worktree now, and satisfied here; a version main
declares with no entry reads as unsatisfied rather than unexaminable, because
written is not installed.

**What decides nothing any more.** The CLI's install path and the marketplace
registry. Installing a candidate adds a different entry and moves the live
pointer; it does not touch the entry main names, which is the one `felix
merge` judges with. The assertions for this were written blind with a decoy:
a live pointer at a version that does not exist and a higher entry on disk
that differs, so an implementation still reading either fails.

**The old block was re-pointed, not deleted.** Its assertions encoded the old
question — drift edited in the working tree, residue dropped into the tree, a
served-or-not gate on applicability, a fallback to the highest cached version
when no CLI answers. Each was rewritten to the new one: drift committed on
main, residue dropped into the entry, "not served" applies, and "the CLI is
not asked". The manifest names moved with them.

**Three engine changes in one session, and what each cost.** Every one went
blind-authored assertions first, a red run against the previous engine, a
green run recorded, the gate, a pull request, CI, a merge, a deploy from the
home, and a gate again on the deployed engine. The hook that forces facts
before edits denied roughly one edit in three on first touch and let the rest
through, which twice left a tree half-edited between two calls; the syntax
check and the suite caught both. Worth knowing before the next session spends
a run on it.

**Next, in order.** (1) A baseline obligation-discovery pass on one governed
product that writes candidates and admits nothing — Felix builds it; the
schedule and model spend are the founder's. (2) CI enforcement of `felix
merge`'s blockers, which needs the founder to choose GitHub Pro or accept that
CI is advisory. (3) Grants for high-risk plugins whose hooks run in every
session with no record. (4) Issue #2 stays open for spec step 5. Standing:
`projects/bazaar` and `projects/webapp` stay untracked, and commission is
stale until the founder runs it.

