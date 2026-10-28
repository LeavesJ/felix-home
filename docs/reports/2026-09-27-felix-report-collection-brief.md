# Felix — Canonical Report Data Collection Brief
Date: 2026-09-27 (America/Los_Angeles)
Status: collection instructions; NOT a completed report.

## Mission
Produce a read-only, evidence-grounded snapshot for the next Felix engineering, product, and research report. Do not implement features, merge PRs, edit doctrine, change gates, or consume a full CI run merely to collect data. Avoid including credentials, secrets, private prompts, raw transcripts, or source code in the handoff.

## Historical baseline
Previous canonical code window:
BASE `31ed8a8ebd28be9cdf0c7dbf7708adabb767eca4`
END  `c6989dc5168f5113745591fde1115b7270dfe933`

Previous report: `Felix_48h_Engineering_Systems_Report_2026-09-24_v2.pdf`.
Historical metrics: 50 landed commits; 162 files changed; +24,072/-6,929 lines; 6.975B raw model token events (97%+ cache reads); 30,694 deduplicated model responses; 32,187 tool calls (26,295 Bash); 12+ average concurrent sessions; 363 stop holds; 9m56s median full-suite runtime; ~17 open real PRs at prior snapshot.
Do not mix Git SHA deltas with operational telemetry cutoffs. Reuse the prior report's methods, not just its topline numbers.

## Local collection — do this first
1. Record UTC collection timestamp, machine/OS, repository paths, current main and remote/main exact SHAs, and git fetch date. Freeze the selected new END SHA. If baseline END is missing or is not an ancestor, record divergence and stop delta arithmetic; reconstruct ancestry before comparing.
2. Inspect BOTH `LeavesJ/Felix` and `LeavesJ/felix-home`; document which data/repository are public, private, local-only, or stale. Include engine, tests, policy/qualification files, docs/handoff, worktrees, and UI.
3. Compute accepted mainline delta (baseline END..new END): commit chronology and subject, author/committer, first-parent vs all reachable commits, files, diffstat, subsystem additions/deletions, testing/engine ratio, assertion registry, test-runner changes, and classified changes. Isolate renames/migrations to avoid inflated LOC claims.
4. PR and candidate lifecycle: all created/merged/closed/open since baseline, merge SHA, age, review/check status, conflicts, staleness, pending branches, worktree inventory, unique non-main commits after global deduplication, superseded/abandoned work. Separate landed, qualified-but-unmerged, unqualified, and research-only. Right-censor open PR latency.
5. Trust Plane: schema validation, `UNKNOWN`, checker qualification and controlled mutations, protected judge/authority, immutable/provenance-bound receipts, dependency-aware staleness, denial handling, exceptions, direct merge bypasses, independent CI wall, continuity and handoff state. Demonstrate actual behavior and remaining bypasses instead of inferring status from files/commit messages.
6. Capability Plane: actual `felix dispatch` status, task admission, worker restriction, resource budgeting, capability discovery, leases/ownership, handoffs/recovery, evidence submission and integration. Distinguish built, partially built, planned and tested externally.
7. Operational telemetry from LOCAL Claude JSONL, Felix audit, lifecycle, CI and gate logs; never transmit raw session content. Aggregate assistant messages by `message.id` across parent and subagent JSONL; separate input, output, cache creation and cache read. Report parent/subagent traffic, tool calls by type, sessions, text turns vs UI interventions, stop holds, stale/never/failed results, resumes/handoffs and sample coverage. Retain exact telemetry time window and limitations.
8. Verification economics: measure current controlled full-suite runtime if safe/approved; otherwise use actual completed CI logs and mark absent benchmarks. Show pass/fail/skipped count, CI minutes and quota, queue/critical path, per-candidate repeated checks, cancellation, cache reuse, and cost per accepted outcome where supported. Do not silently equate raw tokens with billable compute or dollar cost.
9. Capture failures and counterexamples: no cherry-picking. Include any missing/stale evidence accepted, policy bypasses, failed gates, PR divergence, loops, resurrected state, unexplained checks, and high-cost dead ends.

## Research and product evaluation — separate from collection
- Central architecture question: bounded requirement/qualification contracts assembled from (A) user intent/domain-expert clarification, (B) versioned domain knowledge/standards, (C) actual repository/system/org context, (D) independent adversarial omission discovery. Track provenance, applicability, assumptions, open/UNKNOWN states. Agreement is not proof of exhaustiveness.
- Protected deterministic enforcement of *established* obligations is separate from probabilistic discovery; never assert arbitrary product completeness. Qualify checkers through known-pass/fail, seeded omissions/mutations, blinded labels and independently reviewable evidence. Product→task→integration→release→post-deployment obligations.
- BehaviorChangeBench-inspired bounded research: free-text vs structured cross-session handoffs; explicit claim/evidence/unknown fields; multi-agent disagreement and correlated failure; cross-family judges; prompt injection/relay risks; effect on error discovery, false acceptance, communication fidelity, latency and cost. Research experiments first, not indiscriminate spawning.
- Distinct customer hypotheses: (1) founder/domain expert zero-to-one guided delegation; (2) serious developer/brownfield engineering workbench; (3) org governance buyer. Compare enterprise against skilled engineers ALREADY using frontier agents, not manual coding.
- Prospective joint supply-chain OS pilot: TSMC team majority developer, mother's subcontractor company meaningful share; mother's preliminary approval is conditional on product readiness and internal permissions. No TSMC-approved Felix trial, customer relationship or publication claim yet. Test only authorized assets/data and report independently accepted outcomes, human effort, usability, quality, total operating cost and willingness to pay.
- Model-progress scenario: more capable model means more execution and potential verification load, while generic orchestration risks commoditization. Evaluate Felix incremental benefit over model-native agent workflows.

## Report output requirements
1. Source/measurement boundary and updated SHA table.
2. Baseline vs new-window metric comparison with missing values explicitly marked.
3. Commit-by-commit classification and PR/worktree lifecycle appendix.
4. Trust Plane vs Capability Plane actual balance and bottlenecks.
5. End-to-end MVP readiness (task → bounded contract → dispatch → evidence → protected acceptance → inspectable UI).
6. Pilot/readiness, two customer hypotheses and controlled benchmarks.
7. CI and model economics, actual landing throughput, institutional continuity.
8. Staged roadmap: immediate consolidation; minimal dispatch; bounded qualification; UI; pilot; multi-agent evaluation research; multi-year lifecycle scope beyond merge.
9. What to stop building for now, what to test, milestone exit conditions, unresolved risks.
10. Explicit FACT / OBSERVATION / HYPOTHESIS / UNKNOWN tags and source references for each important claim.

## Return to ChatGPT
Provide an aggregate/sanitized data bundle or report generated from the LOCAL repositories and logs, plus exact source SHAs and collection timestamp. Do not upload `.env`, keys, proprietary joint-project files, credentials, raw Claude transcripts, or any company-controlled data without permission. Public GitHub README is not a substitute for the current local canonical state.
