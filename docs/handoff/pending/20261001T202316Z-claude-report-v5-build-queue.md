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
    - **Results:** `R/host-measurements/results.md`.
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
        - Creating the answer file needs the Write rule that item 1 found
          governs creation.
    - **It also sets:** `Read(//proc/**)` denied, `--max-budget-usd`, and
      `--permission-prompts none`.
5. **The attended dispatch tick (D3).**
    - **When:** item 4 has landed and #350 has merged.
    - **Who:** supplying the API key is the founder's act; ask for it then.
    - **Where:** felix-home and one other ecosystem.
6. **Outcome-attribution record, then passive routing (report stage 3).**
    - **When:** after item 1 has pinned the payload fields.
    - **What it records:** agent id, model, effort and edited paths, then
      tree, receipt verdict and PR state.
    - **Rule:** record only. It never touches `verify.sh` or `receipt.sh`.
7. **Retire list keyed to installs (lane item 2).** **When:** the pending
   `ledger.sh` change on `claude/fresh-repo-tree-identity`, stacked on #378,
   has landed.
8. **Consequence floor.**
    - **What:** a minimum model, effort and verification depth from the
      `risk.tsv` tier and channel, the obligation's enforcement class and the
      v3.2 §10 budget class.
    - **Rules:** advisory and raise-only, never a verdict.
    - **When:** after item 6.

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

**If wave 1 died with its session.**
- Each lane that settled has a `disposition.md` beside its artifact.
- Re-run any lane without one from `R/wave-1-workflow.js`. Update its `REPO`
  constant to the session's own worktree first.

**The founder's open items.** None blocks the queue above except where it
names one.
- Admit or refuse the 22 obligation candidates (Elenchus 7, Veldra 15). This
  was due Sep 26-27, and every checker was found flawed on blind re-check.
- Whether the `independence` gate check, which enforces with 4 of 6
  controls, is grandfathered under amendments §2.1.
- A one-word rating of #389 (yes, partial or no) once it has landed.
- The API key for capability item 5, when asked.
