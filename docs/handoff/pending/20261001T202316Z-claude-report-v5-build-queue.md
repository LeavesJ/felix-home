### 2026-10-01: the systems report v5, reviewed and decided. What Felix builds next, in what order, and what starts each step

This is the build queue that follows from the founder's 2026-09-30 systems
report. A session that picks up Felix work should not need to reopen the
report or the roadmap to know what comes next.

- **The report:** `~/Documents/Felix/Felix_Second_Engineering_Systems_Report_2026-09-30_v5_Routing_Clarified_Final.pdf`.
- **The review:** `~/.felix/memory/felix/audits/2026-10-01-report-v5-review/review.md`,
  with its PDF in `pdf/`. It gives the verdict, the corrections, the measured
  numbers, the amendments and the build order. The evidence and scripts are
  in `data/`.

**Decided by the founder, 2026-10-01.**

- **D1, both planes.** Felix stays the engineering OS. "Qualification and
  outcome-evidence layer" is how the Trust Plane faces outward, not what
  Felix is. Adaptive execution sits inside capability lifecycle. Felix
  supplies a floor set by repo-owned risk and the record of accepted outcomes,
  and the host picks the cheapest model above that floor. Felix never builds
  a model minimizer: GitHub, Cursor and Factory already ship one.
- **D2, engineering only.** The report's experiments run as engineering
  measurements with control arms. Its buyer, pilot and margin gates do not
  reopen the market track.
- **D3, one attended `felix dispatch` tick before March.** It runs on the
  founder's own API key with a host-enforced dollar cap, on felix-home and
  one other ecosystem. The roadmap text is #389. The founder approved it on
  2026-10-01, and the carrier lands it in its chain right after #388. If #389
  is still open when you read this, that is the carrier's order, not a
  question for the founder.

**Standing rules from this session.**

- **Every Workflow and Agent stage names its model and effort.**
    - Opus 5.5: specs, blind-assertion design, adversarial review, and trust
      boundaries. That covers qualify, obligations, receipt, verify, escape,
      the merge path and the hooks.
    - Sonnet 5.5 at high or xhigh, never max: implementing from a settled
      spec, plumbing, and fact checks.

  A stage that goes red twice moves to Opus. The full rule is in auto-memory,
  `engine-builds-use-ultracode`.
- **Fix intake, adopted by the carrier.** A new fix gets a slot only if it is
  one of:
    - a red gate on main;
    - a false block in a real session;
    - a blocker for a named Phase 0b step.

  Everything else is batched weekly.
- **No new engine branch while more than 10 engine PRs are open.**
- **No outside text says "independent acceptance"** until #350 and the Phase
  0b step 15 judge pin have landed. Today:
    - a `felix gate --quick` green, with tests skipped, clears both the Stop
      hold and `felix merge`;
    - merge re-runs neither the suite nor `qualify`;
    - merge reads no CI.
- **The model reminder** is the founder's working protocol with the session:
  one line in chat at each section change. It is not Felix behaviour; making
  it Felix behaviour would reopen the stealth decision.
- **Pin full model ids.** Every measurement, lease and record names
  `claude-opus-5-5` or `claude-sonnet-5-5` and records `claude --version`.
  The alias `opus` resolves differently on different host builds. Records
  take the model from the host's `resolvedModel`.
- **Claims.** No outside text:
    - calls the authorization-versus-acceptance opening validated;
    - cites the Reuters and Nasdaq items as demand;
    - calls a possible contact a customer, deployment, partnership or
      endorsement.

  Any cross-boundary test is synthetic or expressly authorized.
- **Reserved sessions.** One standing session works Phase 0b and one works
  the capability lane (review §4.4), so the lane's share actually happens.

**The queue.** Each item gives what it is, then **when** it starts. Designs
live under `audits/2026-10-01-report-v5-review/` in the memory root, written
below as `R/`.

*Trust track: Phase 0b in roadmap order, with two additions.*

1. **#350 (step 2).** The carrier slotted it at 0.49.246, so the carrier
   lands it.
2. **Merge refuses a receipt that skipped checks.** This is new; the report
   missed it.
    - **Spec and blind assertions:** `R/specs/skipped-receipt/`.
    - **When:** once 10 or fewer engine PRs are open. It must land before
      step 8, the actor's core.
    - **How:** an ultracode pipeline (spec → blind assertions → red first →
      adversarial review → gate).
3. **`felix inventory` (step 4).**
    - **Spec and blind assertions:** `R/specs/inventory/`, which revises the
      2026-09-24 spec against today's code.
    - **When:** same trigger as item 2.
4. **Steps 3 and 5-18, in roadmap order.**
    - Step 8, the actor's core, must read the CI conclusion for the exact
      head SHA. Merge consults no CI today.
    - The actor lands only through `felix merge`. The gate only announces an
      absent `qualification.tsv` or a stale commissioning receipt; merge
      refuses both, so nothing may land around merge.
    - Step 6, the lost-work page, is the report's §11 console. Its scope is
      closure C1 in `R/coverage/coverage.md`:
        - all seven categories;
        - "not measured yet" in place of a missing source;
        - the permitted decision shown as text only;
        - strips added at M1 and M2 as their data lands.
    - Step 18 (deny rows on raw merges) also covers `felix automerge
      --enable`, which turns on GitHub auto-merge and lands without `felix
      merge`. Until then, no session runs it.
    - The unattended repair (`templates/unattended.yml`) stays off. It holds
      a key and loads repo settings, without `--bare` or `--setting-sources`.
      Before anyone enables it, it gets item 4's measured lease hardening and
      one attended validation run, as part of step 17's arming brakes after
      the pin.
    - Realistic dates with the 3-in-4 stretch:
        - attended landing (step 10), about Oct 29 to Nov 2;
        - judge pin (step 15), mid-November;
        - the arming sitting, late November.

      Nothing lands unattended before the pin.

*Capability lane: one session in four. The order is Felix's.*

1. **Host measurement.**
    - **What it measured:** the real Claude Code binaries (2.1.284 desktop,
      2.1.260 CLI) against a local Messages API stand-in, with no login and
      no model. The questions were:
        - restricted-lease I/O;
        - what loads without `--bare`;
        - hook payloads inside subagents;
        - whether `updatedInput` can rewrite `Agent.model`;
        - `--max-budget-usd`.
    - **Results:** `R/host-measurements/results.md`, settled in two rounds
      (see "Wave 1, settled" below). It is done, so items 4 and 6 may start.
    - **Before step 8, measure:**
        - the real `pre-tool` blocking a `deny.tsv` row inside a restricted
          lease;
        - a plugin enabled from user settings, under `--restricted`;
        - an OS-level egress block;
        - Workflow-spawned agents.
2. **Held-out replay.** This decides whether adaptive routing is built at
   all.
    - **Protocol:** `R/replay/protocol.md`.
    - **When:** once the protocol's `disposition.md` exists. Run it right
      after a weekly usage reset, with one engine sha and one host build
      pinned.
    - **Its predeclared rule:**
        - **Static Sonnet** for implementation, if Sonnet passes at least
          Opus's count minus one.
        - **Escalation-on-failure only**, if the cascade beats both static
          policies by 10% or more.
        - **Difficulty-predictive routing**, only if the per-task oracle beats
          the best static policy by 5% or more and a pre-task feature
          separates Sonnet's failures.

      Write the result into `engine-builds-use-ultracode`.
3. **Seeded-omission corpus (lane item 1).**
    - **Protocol:** `R/seeded-corpus/protocol.md`.
    - **Steps:** plant, seal, then run both arms (Felix's obligations request
      against plain Claude Code).
    - **If recall does not beat plain Claude Code:** say so, and narrow to
      the obligations people name (roadmap §5).
4. **`felix dispatch --dry-run` (lane item 3).**
    - **When:** after item 1's results.
    - **The lease prints only measured flags, and fixes the four defects in
      review §4.7:**
        - It names its pool. `--bare` means an API key, never the
          subscription.
        - It records `claude --version`.
        - The answer directory goes in `--add-dir`, which exposes its
          siblings to Read.
        - An `Edit(<answer file>)` rule lets Write create the file
          (measured), so the lease names the file exactly.
    - **It also sets:**
        - `Read(//proc/**)` denied;
        - `--max-budget-usd` and `--permission-prompts none`;
        - no `Agent` tool;
        - `DISABLE_TELEMETRY=1` and `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`;
        - the full model id.
    - **After the run,** it checks `total_cost_usd`. The binary's cap is
      soft, so it cannot trust the exit code.
5. **The attended dispatch tick (D3).**
    - **When:** item 4 has landed and #350 has merged.
    - **Who:** supplying the API key is the founder's act; ask for it then.
    - **Where:** felix-home and one other ecosystem.
6. **Outcome-attribution record, then passive routing (report stage 3).**
    - **When:** after item 1 has pinned the payload fields.
    - **What it records:** agent id, model, effort and edited paths, then
      tree, receipt verdict and PR state. It reads the model from
      `PostToolUse(Agent).tool_response.resolvedModel`. Each row carries a
      task key: the dispatch request id for the tick, the PR branch for
      native work. The key joins objective, agent rows and receipt.
    - **Rule:** record only. It never touches `verify.sh` or `receipt.sh`.
7. **Retire list keyed to installs (lane item 2).** **When:** the pending
   `ledger.sh` change on `claude/fresh-repo-tree-identity`, stacked on #378,
   has landed.
8. **Consequence floor.**
    - **What:** a minimum model, effort and verification depth from the
      `risk.tsv` tier and channel, the obligation's enforcement class and the
      v3.2 §10 budget class.
    - **Rules:** advisory and raise-only, never a verdict. It never
      rewrites an Agent call's input: measured, a rewrite can lower the
      model, and it would add an enforcing output to the fail-open hook.
    - **When:** after item 6.
9. **Task-scoped checkpoint** (report 6.8 and D.1).
    - **What:** a memory-root file keyed by task, not a table column. It
      holds Felix-written references (revision, tree id, receipt path,
      obligation-row hash, pool) and the stage. No transcript is ever passed
      to another provider.
    - **When:** the replay keeps escalation or adaptive routing, or M2's one
      adaptive transition is being built. The replay is also the first
      qualified-worker experiment.

*Later, each on its own trigger.*

- **The `felix.receipt/2` evidence packet:** a derived view. It adds
  `skipped`, the judge's identity, worker model and effort, and the residual.
  It comes after the judge pin.
- **Experiment C (post-merge invalidation):** with Phase 0b step 12 and the
  Phase 2 stale receipts.
- **Experiment A (review aid):** after the pin.
- **Provider federation:** roadmap Phase 4. A second provider is evidence
  that the verdict holds when the agent changes, not a way to pool compute.
  Anthropic bars products from routing users' Pro/Max credentials, so pools
  stay a dormant contract.
- **Experiment B (cross-org):** v3.2 build step 9.
- **The reporting contract** (report Appendix C) comes with the next report,
  which is regenerated only on the founder's request.
    - It prints "not comparable" beside any row whose instrument changed.
    - It reuses the 2026-09-24 ci-budget scripts for CI accounting.
    - The review's scripts are in `R/data/telemetry/`.
- **A per-task capability contract view,** derived and read-only, after
  capability items 4 and 6.

**Wave 1, settled 2026-10-01.**

Every lane has a `disposition.md` under `R/`.

- **Host measurement** (`R/host-measurements/results.md`, round 2).
    - `--max-budget-usd` is soft. When subagents lagged the main turn, a
      capped run exited 0 while over its cap in 39 of 39 runs. It overshot by
      1 to 6 responses, and streams that had already started are not counted
      in `total_cost_usd`.
    - Writing a floor model into an Agent call that names no model can lower
      the model rather than raise it. So the consequence floor stays advisory.
    - Read a subagent's model from `PostToolUse(Agent).tool_response.resolvedModel`.
      The transcript line is unreliable.
    - The binaries call Anthropic's non-model endpoints on their own.
      `DISABLE_TELEMETRY=1` together with `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`
      stops every connection, and runs still succeed.
    - The lease requirements it lists are proposals for capability item 4,
      not host facts.
- **Replay** (`R/replay/protocol.md`, `disposition.md`). 15 of 20
  challenge findings were adopted in full and 5 in part.
    - Each arm is its own `claude -p` process in a macOS sandbox, with no
      Workflow agents.
    - The held-out tests leak. 75 felix-home trees sit in `/private/tmp`,
      and the public `LeavesJ/Felix` snapshot holds the fixes, so the arms
      must not see either.
    - Run V0 first. The run then costs about 95 suite runs and about $410
      ($245-665). It stops before any arm if fewer than 20 tasks survive
      screening.
    - It competes with landing for the carrier's suite slots, so ask the
      carrier for slots.
- **Seeded corpus** (`R/seeded-corpus/protocol.md`, `prompts.md`,
  `disposition.md`).
    - The protocol is settled. It is now 800 lines; split it when it is
      built.
    - It costs about $96-632, depending on runs and replication.
    - The proxy, the wrapper and the stand-in's logging are not built yet.
- **`felix inventory` spec** (`R/specs/inventory/spec.md`, `assertions.md`,
  `disposition.md`). It is settled and ready for trust item 3 once the WIP
  trigger holds. The blind author, not the implementer, reconciles the
  branch's assertions.
- **Skipped-receipt spec** (`R/specs/skipped-receipt/spec.md`,
  `assertions.md`, `disposition.md`). It is settled and ready for trust
  item 2.
    - A green CI run never clears the refusal, because felix-home's CI
      always skips `installed`.
    - It also stops `felix receipt` calling a skipped green "verified".

If a lane ever has to be re-run, use `R/wave-1-workflow.js`. Update its
`REPO` constant to your own worktree first.

**Report coverage, checked 2026-10-01.** `R/coverage/coverage.md` (PDF in
`R/coverage/pdf/`) lists every proposal in the report: 308 items. Agents
extracted 300 of them without seeing the review. A critic found 8 more and
overturned 37 verdicts. Each item has a status and a milestone. The 18 items
with no disposition, and the ones the critic reopened, are settled by the
closures below. The generator is `R/coverage/build.py`, and the final
statuses are in `reconcile.json`.

- **C1:** the console scope.
- **C2 and C2b:** trust controls and auto-merge, in trust item 4.
- **C3:** model ids, under the standing rules.
- **C5:** the reporting contract, under Later.
- **C6:** claims, under the standing rules.
- **C7:** the task key, the checkpoint (capability item 9), the qualified
  worker, and the reserved sessions.
- **C8:** the institution vision. It holds only from M2.

No gap is left. Each of the 308 items is built, queued, amended, deferred
with a trigger, agreed, or declined with its reason.

**The MVP, as the founder asked on 2026-10-01: "a UI that functions like
what I proposed and does everything I proposed, after the revision".**

Every coverage item carries one of four milestones. The dates assume the
3-in-4 trust share and today's landing rate. P50 means even odds, and P80
means four in five.

| Milestone | What exists | P50 | P80 |
|---|---|---|---|
| M0 console v0 | `felix inventory`, the stuck-PR page and the lost-work page (Phase 0b steps 4-6). This is the report's §11 exception console, read-only, with what needs a decision first | Oct 24 | Nov 7 |
| M1 attended loop | One objective runs end to end: obligations, then the attended capped dispatch tick (D3), then independent verification, then attended landing (step 10), then one measured routing decision. The console shows holds, queue, the pool and spend | late Nov | early Jan |
| M2 full MVP | Every §9.3 criterion: judge pinned (step 15), the qualified judge (Phase 1), post-deploy check and rollback exercised (step 12), stale receipts (Phase 2), Elenchus and a second ecosystem, the corpus against plain Claude Code, the replay's routing decision | late Jan | late Feb |
| M3 after MVP | Second provider, writable routing and pool settings, customer keys, schedules | not before March by design | — |

- **What moves the dates.** Landing throughput, not authoring:
    - 93 merges in the week of Sep 21, against 1 since Sep 26;
    - the weekly usage limit, which bound on Sep 22 and Oct 1;
    - the Actions billing cap;
    - the founder answering the items below.
- **The review's early signals still apply.** #350 should merge by Oct 8,
  and the `felix inventory` PR should open by Oct 5.
- **The console is read-only by roadmap decision** (Phase 0b step 6).
  Consent stays the founder's GitHub merge. A console that acts would
  change the roadmap, so only the founder can choose it.

**The founder's open items.** None blocks the queue above except where it
names one.
- Admit or refuse the 22 obligation candidates (Elenchus 7, Veldra 15). This
  was due Sep 26-27, and every checker was found flawed on blind re-check.
- Whether the `independence` gate check, which enforces with 4 of 6
  controls, is grandfathered under amendments §2.1.
- A one-word rating of #389 (yes, partial or no) once it has landed.
- The API key for capability item 5, when asked.
    - **Recommended:** make it a spend-limited key or workspace. The binary's
      own cap is soft, so this is the only hard bound.
- **The replay:**
    - whether its separate `claude -p` arms, started by an attended driver on
      his subscription, sit outside D3 (the protocol assumes they do);
    - about $410 of usage;
    - a run after a weekly reset.
- **The seeded corpus:**
    - lease A (no shell; recommended) or lease B;
    - a spending ceiling;
    - whether to post the sealed commitment publicly;
    - a person for the 20% label sample;
    - whether an underpowered result should narrow at all. That would be a
      roadmap amendment.
- **Whether the console should ever act.** It is read-only by roadmap
  decision (Phase 0b step 6), and consent is his GitHub merge.
- **An input-rewriting consequence floor:** declined by default. Building it
  would be an architecture change, because it adds an enforcing output to
  the fail-open hook.
