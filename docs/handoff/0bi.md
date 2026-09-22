## 0bi. Verified at session close, 2026-09-17 — the red count is a file in the tree, the gate has one reader of the deploy question, and the distance to v3.2 re-measured off the tree

| | |
|---|---|
| merged | **#255** (red tier: `tests/red`, `red.tsv`, 0.49.118) and **#256** (red tier: the `installed` fold, 0.49.119), each through `felix merge` on green CI; nothing in either escaped the tree |
| deployed | **0.49.119**, carried in the pull requests; the home's `felix install` deployed each byte-identical and wrote no bump |
| suite | **2399 passed, 0 failed**; 39 assertions authored blind, 6 by hand |
| red.tsv | #255 reads **0 of 2383** with 25 skipped, because the base has no recorder; #256 reads ****9 of 2399** against `ee14fd1` at 0.49.118, none skipped, and the nine are the fold's own** |
| filed | **#254**, why the table-header sweep waits |
| this section | written by the session it describes; the pull request bodies carry the same claims, and §0bh says what that is worth |

**"Shown red" is a number in the tree now.** §0bh found that every claim
about *method* across six sections — authored blind, shown failing — left no
artifact on the machine, and the red count was one of them. `tests/red`
checks the base commit out whole as a detached worktree, puts this tree's
`tests/run` into it, runs that with the manifest comparison off, and writes
`tests/red.tsv` beside the manifest: base ref and sha, the engine version
there, the counts by line, and every assertion name that failed with how
often. `tests/run --record-assertions` calls it, so the manifest and the
count it was shown red with travel in one diff. A zero is recorded, never
refused: a refactor with an unchanged contract earns zero honestly, and
whether zero is acceptable is the reviewer's question with the number in
front of them. Measured on the way: the first version unpacked `git archive`
and read **2 of 2357** red against an engine byte-identical to the tree's —
the independence scanner's `git ls-files` and deploy-check's base ref, asking
git about a tree with no repository. A worktree answers, and the count is 0.
A read-only review then found three things the contract had not said: a run
killed by a signal left the *previous* change's claim on disk, so the file is
retracted first and written atomically now; `git worktree add` exits 1 over a
complete checkout when a post-checkout hook fails, so the checkout is judged
by what is on disk; and the inner suite's temporary root sat beside this
run's rather than under it, so a stray was not one pattern away. All three
are in #255's second commit.

**The gate asks one reader.** `installed` carried its own copy of the deploy
comparison — archive, `diff -rq`, an ignore-aware loop — on the argument that
a verifier which sources the code it judges can be switched off by editing
that code, and `felix_accepted_deploy_diff` carried the same logic for
deploy-check. #256 keeps the argument and drops the copy: the gate reads
`lib/resolve.sh` from the base ref with `git show`, never from the working
tree and never from the cache entry, sources it in a subshell and calls the
function, so the code that judges is the code main accepted and nothing a
candidate writes reaches it. Fourteen assertions were authored blind against
that contract — a stub committed on main decides and its output reaches the
gate; a stub in the working tree, on a side branch or in the cache entry
changes nothing; a main whose resolve.sh lacks the function or the file is
FAIL naming the function, never ok and never skipped — and one of them caught
the no-file message not naming the function. The four assertions that had
held the two copies in step by counting the copy's tokens asserted a premise
the fold removed; four now count the new mechanism's. One reading moved with
the fold and the suite did not see it; a reviewer did, by reproduction: a
directory main does not ship, holding nothing but ignored residue in the
entry, was drift to the copy — the missing diff operand — and is residue to
the function, which is what deploy-check had answered for the same fact all
along. Accepted as the consistent reading, said in the gate's comment, and
pinned beside `felix_deploy_diff` so the two cannot part in silence.

**The header sweep waits, and #254 says why.** §0bh's third item was to bring
the three projects' `probes.tsv` and `obligations.tsv` headers to #243's
wording. `felix_commission_policy_version` hashes those files whole, comments
included, and the epoch's `policy_version` is the same hash: a comment-only
edit re-stamps three projects, stales the commission receipt, and `felix
merge` refuses on it as it did for #250. That is a founder re-run for a
change that alters no row, no command and no verdict. The fix — hash rows
only — is a `lib/` change that churns every epoch once, and the moment is his.

**Distance to v3.2, re-measured off the tree** by a read-only agent with
file:line for every sub-item of spec §13 and every amendments section, on
2026-09-17. Steps 1, 2, 3, 4 and 6 are built or partial with vocabulary gaps:
probes, provenance, source identity, projection invalidation, candidates,
enforcement classes, epochs, three-axis state, receipts, dependencies,
invalidation, the commissioning pipeline and reconciliation all exist and are
wired to something that refuses. The relation engine is set-difference in
`probes.sh` with no typed store; the release state machine consumes
obligations and receipts with no READY/SHIP/HOLD vocabulary and no
post-deploy stage. **Step 5 is the hole:** trust tiers are a risk word,
`SOURCE_INSPECTED` is unnamed, and sandbox, scoped leases, revocation and
behaviour receipts are absent — the first three need Docker or a platform
that activates mid-session, which this one does not. **Step 7** has the first
increment (#250) and nothing schedules it; dispute protocol, stopping rule
and situation triggers are absent. Steps 8 and 9 are partial and absent.
Of the amendments: §0 built; §1.1 hashes without git authorship; §1.2's
behaviour exists without its names; §1.3 is detached with nothing to detach
it; §1.4 built; §2 has six of seven controls, no coverage-report control, no
author column, and the judge pinned for `felix merge` only — this session's
fold pins it for one gate check; **§3 is absent**: the Stop hook's
`FELIX_ALLOW_RED` is global, unscoped, unexpiring and uncounted, and the
amendment's three numbers are two. What bash and git alone can build, in the
order it earns: §3's exception channel; control 7 and the author column;
git authorship on policy versions, once #254 settles what is hashed; judge
pinning for the rest of the gate and for `qualify`; the stopping rule and
budget classes; `qualification.tsv` for elenchus and veldra. What cannot:
sandbox and behaviour receipts (Docker), leases (the platform), discovery at
depth (a model surface), and the risk-envelope values (the founder).

**Two things about method, measured rather than argued.** Blind authorship
found one contract deviation in 39 assertions; two reviewers reading the
finished code found five real defects, every one outside the stated
contract. They are not rivals: blind tests the sentence, review tests what
the sentence left out, and the pair is the instrument. And the session hit
lesson 2026-09-04 — commit first, gate second, merge third — exactly as
written, because the route matched was `orient` and that lesson is keyed to
other words; the cost was one eight-minute gate. That is #29 wearing a
lesson: what is mounted follows the route, not where the work is. A second
eight minutes went the same way for a fact nothing had written down:
`felix merge` squashes (`gh pr merge --squash`), so #256, stacked on #255's
commits so its red run could use the recorder, carried three commits main
already held and a version bump that would have conflicted; rebased onto
main with `--onto`, tree identical, and gated again. The memory note that
said `--merge` is corrected.

**ECC is installed, and the memory said otherwise.** `affaan-m/ECC` 2.2.1 has
been at user scope since 2026-09-03T21:24Z, after the 2026-09-02 read that
recommended against it; the memory note said it was installed nowhere and is
corrected. Its fact gate stops the first Bash call and the first edit of
every file until facts are typed into the reply, which is stealth in the
middle inverted; its `silent-failure-hunter` and `code-reviewer` were the two
reviewers above, and earned their cost. `felix toolbox` lists it high risk,
capability `ci`, reachable by no route.

**Next, in order.** The founder's, unchanged from §0bh with one added: (1)
the first real discovery run on the elenchus checkout; (2) the public
snapshot, now eighteen pull requests behind; (3) CI enforcement of `felix
merge`'s blockers; (4) grants for the high-risk plugins; (5) #2 step 5; (6)
#252; (7) #254, the moment to re-hash the policy version and re-stamp three
projects, after which the header sweep is one commit. Felix's, in a next
session: the §3 exception channel — an exception file under the project,
task-blocking only, keyed to the obligation's row hash, with an absolute
expiry, any change firing the escape, and three numbers counted — because it
is the top bash-buildable gap in the table and the Stop hook's global
override is what it replaces; then control 7 and the author column in
`qualification.tsv`. Standing: `projects/bazaar` and `projects/webapp` stay
untracked; elenchus's missing `gate.sh` is the product's.

