## 0ar. Verified at session close, 2026-09-06 — the checker night: two grants, one caught at the boundary, and the distance to v3.2 measured

**Landed on main.** #207 `authority` is an engine escape: a change under
`projects/<p>/autonomy*` cannot pass `felix merge` unattended, proven on a probe
branch after merge. #208 `independence` is `bin/independence-scan`, four
blind-authored controls, two named gaps (fragment assembly, a project called
`ledger`), and twelve behavioural assertions in place of five source-greps.
The founder merged #208 by hand: the `verifier` confine saw `pass|fail` lines
go 20 → 19 because the check moved into a command, and relocation reads as
removal. Not argued with; the confine was not touched. Deployed 0.49.107.

**Two mistakes, one mechanism.** #206 granted Felix `commission` by a
`git add -A` sweep while the PR said ungranted; an hour after recording that
lesson, the same sweep put seven of another branch's untracked docs into
#207's first commit. `git status --porcelain` before every add; the
structural fix is #207 itself. The founder then granted `commission`
legitimately. The stamp is bound to the policy table hash and renders `[!]`
when stale.

**Scanner.** `secret-scan` catches PEM only in its dashed form now — prose
naming the header passes, a real header fails — because the bare phrase
tripped on documentation. `secret` is 8/8 with credential values assembled at
run time, so the table cannot poison the baseline.

**find-skills, read by an agent.** Take three things: a content hash of the
copy Felix read against the copy it installed (invariant 4 is literally false
today — `discover` inspects a scratch checkout, `stack apply` fetches again);
announce install drift; and fix `felix_discover_candidates`, which reads a CLI
error as an empty catalogue and caches "nothing matches" for seven days. Copy
nothing else from it.

**Distance to v3.2, read off the tree, not recalled.** Build steps 1, 3, 6
built; 4 half (the boundary consumes receipts, not obligations); 5 and 7 thin;
2 at zero — `obligation` 0 functions, `epoch` 0, `lease` 0, no
`procedures.tsv`, unchanged since the amendment counted the word twice.
Qualification has six of seven controls; control 7, the coverage report, is
unbuilt; 2 of 11 checkers have been through it. The amendment's first
increment is complete. The admission rule it was the first increment *of* has
not been started. The north-star sentence is two to four sessions away on this
substrate; steps 5, 7 and 9 need Docker and a model surface bash has not got.
§6's residual held twice tonight: one authority wrote the work and the
judgement, the boundary caught it both times, and the same authority then
recommended the merge.

**Next session's first action.** The first admission rule: one obligation in
a `procedures.tsv`, three-axis state, dormancy derived not stored, qualified
through the seven controls, wired to `felix merge` in the same commit. Shown
failing before believed. Then find-skills item three, then the next checker.


