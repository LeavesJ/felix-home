### 2026-09-24 — the Actions outage measured: a spending cap, not capacity; a push to main now reuses its pull request's green run of the same tree

**No engine change.** `.github/workflows/gate.yml` and two scripts beside it,
on `claude/felix-verification-scheduler-1fe223`. It is an `execute` escape, so
`felix merge` refuses it and it merges on the founder's yes.

**Why.** From 2026-09-25 00:07Z GitHub refused every felix-home job. The
founder and an outside reviewer read that as a new verification ceiling. The
measurement is in `~/.felix/memory/felix/audits/2026-09-24-ci-budget/`
(`ci-budget.md`, its PDF, and `data/` with the scripts).

**What the data says.**

- **A budget cap, not capacity.** September's 531 runs came to about 2,042
  billed minutes against the Free plan's 2,000, with a $0 spending limit. Since
  09-22, jobs waited a median of 3 s to start, and at most 4 ran at once
  against the plan's 20.
- **Post-merge runs on main never failed.** They were 34.5% of minutes, and
  0 of 203 failed. 174 of them gated a tree the pull request's run had already
  passed.
- **Drafts:** 20% of minutes gross, but only about 6.5% net, because 45 of 54
  went ready.
- **Freshness:** 21 of 37 PR failures were freshness checks alone. L2b removes
  that class.
- **Nothing in the engine reads CI.** `felix merge` never does; sessions
  stopped on the working rule "merge once CI is green". Under the landing
  actor, CI on landed commits is the brake, so the budget sets availability as
  well as cost.

**What was built.**

- The `reuse` job runs on pushes to main only, holding `pull-requests`,
  `actions` and `checks` read. It finds the merged pull request, then the
  pull_request run of `gate.yml` on its head that ran last (by
  `run_started_at`). That run must be green, and its gate job must name exactly
  one `gated tree` annotation equal to the landed tree.
- The `gate` job emits that annotation before the gate runs. It is skipped only
  when `reuse` names a run.
- `reuse-verified-tree.test.sh` has 27 cases. Its stand-in `gh` answers only
  exact URLs, and nine mutations of the step were each caught.

**The review changed the design.** One adversarial reviewer found a hole in
the first version. It inferred the gated tree from ancestry, so it could reuse
a run whose base was another branch: a pull request retargeted to main after
its last run, or a head shared by two pull requests. The run object keeps no
base once the pull request merges. The annotation records the tree the run
actually gated, which also drops the dependence on main only moving forward.
The reviewer also found:

- a stand-in `gh` that three broken copies passed;
- "latest" meaning latest created rather than latest started;
- token claims that overstated.

All of these are fixed.

**What is not proven until it runs.** The replay of the first version
reused 168 of 203 September pushes. The annotation version cannot be replayed,
because old runs carry no annotation. Its first live test is this PR's own
push to main. Check that run's `reuse` job summary: a green run with the `gate`
job skipped means it worked.

**Rules recorded for the verification plane** (R1-R6 in the audit, Felix's
call, not asked):

- R1: evidence is keyed by tree, judge and environment.
- R2: a skip is only ever a reuse.
- R3: remote CI is spent at the landing frontier, with readiness in L6a.
- R4: freshness never costs a runner; L2b removes it.
- R5: the month-to-date budget goes on the L3a status page.
- R6: docs-only changes run the full gate until the suite's reads are
  measured. This suite pins README text, so a path filter would drop real
  checks.
- Not now: a self-hosted runner.

**Next.**

- The founder's yes on the merge.
- After it lands, read the first push run.
- Then carry the reuse into the bootstrap template (`lib/bootstrap.sh`), so
  adopters get it too. That is engine work, through the pipeline.
