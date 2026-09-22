## 0bd. Verified at session close, 2026-09-16 — an ask that crashes is unknown, and the probe gate is a checker

| | |
|---|---|
| merged | **#243**, red tier, on green CI; `felix merge` refused it on the stale commission receipt alone |
| deployed | **0.49.114**, carried in the pull request; the home's `felix install` deployed it byte-identical and wrote no bump |
| qualification on the merged tree | **47 of 47 met across 6 checkers**, up from 38 across 5 |
| suite | **2157 passed, 0 failed**; 23 assertions added, blind |
| commission | still **stale** since #241 moved `routes.tsv`; re-running it is the founder's, and until then `felix merge` refuses every pull request on that line |

**§0bc item 1, done.** `_felix_probe_ask` folded every exit but 0/126/127 into
1, so a command that crashed — grep on a bad regex exits 2, `git -C` into a
file exits 128 — read as a clean no in all three places it is asked: an
obligation's `applies` went DORMANT with a sentence saying the grounded state
had spoken, a probe row's `when` switched the row off as not-applicable, and a
`witness` that could not run turned "nothing found" into `empty`, the one state
that claims something about the world. Exit 1 is the only no now; anything
else is unknown, names its code ("exited 2, which is neither yes nor no"), and
blocks. The evidence and the probe are never run behind an applicability
nobody established. Shown on a fixture under main's engine first: a crashed
witness read `empty`, a crashed `when` read `not-applicable`, zero blocking.

**A pipeline is a limit, stated in the code and not solved.** `git ls-files |
grep -q x` reports grep's status, so a failure before the last stage is not
seen. `pipefail` is the wrong fix: `grep -q` closes early on a real match and
hands the producer SIGPIPE, exit 141, which would read as unknown on every
true yes.

**The probe gate could not be qualified, and now can.** `felix probes --gate`
resolves its project through the binding, which in a detached worktree is the
home's table and not the tree's, so no mutation of `probes.tsv` could ever be
staged in front of it — probes was the one gate check `qualification.tsv`
could not name. `engine/harness/bin/probes-check <project-dir>` mirrors
`obligations-check`, reads the same two functions, and takes six blind-authored
controls. Three more rows on `obligations-check` cover the `applies` column.
Against main's engine with the new checker in place, exactly the four rows
that measure this change were HELD — obligations violation and alternate,
probes violation and alternate — and every other row, including the probes
`decoupled_violation` (blind with every command exiting 0), was met on both.
That is what a control that measures one change and nothing else looks like.

**Two authors, both blind, and what each caught.** The controls author, given
both properties in prose and forbidden `bin/`, the two libraries and the
existing obligations rows, measured every planted exit code in a clone (2,
128, 1) before handing rows back, chose 128 for the probes alternate so that 2
and 128 are each covered on both checkers, and flagged one reading it would
not bet a row on: a probe that prints nothing and exits 1 (grep's no-match).
The code sends that to the witness, as it did before; nothing changed there.
The assertions author wrote 23, of which 11 fail against main's engine; two
more — the evidence and the probe never running behind an unknown — pass on
both, because main's code retires the row before either runs. They guard the
direction a future implementation could take, and are kept for that.

**Elenchus and veldra were reasoned about, not run.** Neither is checked out
on this machine. Every ask their tables declare is `test`, `grep -q` or `ls |
grep -q`, which exit 0 or 1, so none goes red under the new reading. Felix's
own were run: nine probes found, two obligations one active one dormant.

**Next, in order.** (1) The epoch's topology hash in the gate receipt, so a
changed gitignored or `$HOME` fact cannot ride an old green (§0bc item 2).
Felix's. (2) A baseline obligation-discovery pass on one governed product that
writes candidates and admits nothing — Felix builds it; the schedule and model
spend are the founder's. (3) CI enforcement of `felix merge`'s blockers, which
needs the founder to choose GitHub Pro or accept that CI is advisory. (4)
Grants for high-risk plugins whose hooks run in every session with no record.
(5) Re-point `deploy-check` and `engine_deployed` to #239's question. (6)
Issue #2 stays open for spec step 5, promotion after acceptance; steps 2-4
landed in #239 and `felix merge` has since merged an engine change from a
worktree. Standing: `projects/bazaar` and `projects/webapp` stay untracked.

