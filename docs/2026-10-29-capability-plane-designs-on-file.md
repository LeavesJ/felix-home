# The capability plane: everything on the table

This combines what seven readers extracted, as of 2026-10-29. Every row cites the paths those readers gave. Nothing in it is new design.

## At a glance

- **The plane is older than it feels.**
  - "Installed is not active" dates from 08-09.
  - Felix owning the capability lifecycle, the Capability Manager and the Execution Coordinator date from 09-02.
  - The lease as a launch configuration dates from 09-19, and the seven invariants from 10-18.
  - Sources: v2 p.1; v3.1 p.63; SPEC §1, §7; dd §3; thesis §4.
- **What runs today on the capability side:**
  - the install policy;
  - commissioning;
  - plugin discovery, which reads a plugin before installing it;
  - probes;
  - an obligation ledger whose rows were all admitted by hand;
  - a keyword router that is right about 2% of the time.

  Everything else that decides what a project needs only reports. Sources: built reader §1; h:z.
- **What does not exist yet:** leases, dispatch, workers, the floor, retirement, and a second host. The Execution Coordinator has a one-line charter and nothing more. Sources: built reader §4; SPEC l.62.
- **Binding now:**
  - D1: Felix sets the floor, the host picks the model, and Felix builds no minimizer.
  - D3: one attended dispatch tick before March.
  - Row 25: build intake now, and gate authority on the trust milestones.
  - Row 27: derived rows may bind within five bounds. Nothing is armed yet.
  - Row 28: the input ladder.
  - Row 19: the Droid adapter first, then Codex.

  Source: dir §4.
- **The weakest numbers:**
  - 22 candidate obligations were proposed and 0 admitted.
  - The seeded-omission corpus has a settled protocol and has never run.
  - From 09-25 to 10-19, 16 of 80 commits touched capability libraries, and none was a lane item.

  Source: thesis §1, §10.

## How to read this

Status words:
- **decided** means decided and binding.
- **on file** means written in a design but not decided.
- **open** means an unresolved question or defect.
- **rejected**, **superseded**, **built**, **partly built** and **not built** mean what they say.

When readers disagree, the row gives the latest dated source and the clash is listed in §5.

| key | path |
|---|---|
| FOS | `/Users/a14808/Documents/UC Berkeley/Career/Founder OS/` (the v3.2 reader places v2, v3.0 and v3.1 there too) |
| v2 | FOS `founder_autonomous_engineering_os_v2_expanded.pdf`. Pages 1-17 are v1.1 and pages 18-43 are v2.0. Dated 2026-08-09. |
| v3.0 | FOS `founder_autonomous_company_os_v3_ultron.pdf`. New pages 44-57. Dated 08-13. |
| Brief | `Felix_Research_Brief.pdf` and `Felix_Research_Brief_v2.pdf`, 08-17. The early reader gave no folder. |
| v3.1 | FOS `founder_autonomous_company_os_v3_1_felix_runtime.pdf`. New pages 58-72, the same as KRN pp.58-72. Dated 09-02. |
| SPEC | FOS `felix_v32_architecture_spec.md`, cited by line. Dated 09-02. |
| AMD | FOS `felix_v32_conformance_amendments.md`, 09-03 |
| ADD / KRN | FOS `felix_v32_addendum.pdf` (pp.73-87) and `founder_autonomous_company_os_v3_2_felix_authority_kernel.pdf`. ADD is KRN pp.73-87. |
| RPT | FOS `Felix_48h_Engineering_Systems_Report_2026-09-24_v2.pdf` |
| repo paths | Relative to `/Users/a14808/Documents/Felix/.claude/worktrees/agent-beacon-drift-481a64` |
| h:X | `docs/handoff/0X.md`, for example h:cw = `docs/handoff/0cw.md` |
| p:X | `docs/handoff/pending/<file ending X>.md`: 98a6c7 (mods spec, 10-07); a198d9 (mods measured, 10-19); f104de (interface, 10-09); b65b07 (radar, 10-10); 07d9c8 (lane, 10-19) |
| router / dist / dd / wfs / road | `docs/2026-08-09-intent-router-design.md`, `docs/2026-09-17-v32-distance.md`, `docs/2026-09-19-direction-decisions.md`, `docs/2026-09-21-where-felix-stands.md`, `docs/2026-09-23-roadmap.md` |
| pilot / b2 | `docs/2026-09-23-episode-pilot.md`, `docs/2026-09-23-episode-batch-2.md` |
| reachspec / reachchk / audit | `docs/2026-10-12-declared-tools-reach-spec.md`, `docs/2026-10-24-reach-checks-design.md`, `docs/2026-10-24-audit-register.md` (finding ids C0nn) |
| thesis / intent / vibe / jepa | `docs/2026-10-18-capability-plane-thesis.md`, `docs/2026-10-19-intent-to-build-design.md`, `docs/2026-10-19-ai-engineering-vs-vibe-coding.md`, `docs/2026-10-19-jepa-and-learned-choices.md` |
| dir | `docs/direction.md`. "Row N" is a §4 decision. |
| lib/X | `engine/harness/lib/X.sh`. HEAD is `78f0268f` (10-28, 0.49.308). |
| MEM | `~/.felix/memory/felix/`. Audit folders: rv5 = `audits/2026-10-01-report-v5-review/`, mods = `audits/2026-10-19-mods-round/`, cpa = `audits/2026-10-18-capability-plane/`, iva = `audits/2026-10-19-intent-and-vibe-coding/`, beacon = `audits/2026-10-29-beacon-spike/` |
| M:X | `~/.claude/projects/-Users-a14808-Documents-Felix/memory/X.md` |
| L | `~/.felix/memory/felix/lessons.md` |
| PR 473 / 474 | felix-home draft PRs labelled `needs-founder` |

## 1. Timeline

| date | document | capability idea introduced or changed |
|---|---|---|
| 08-09 | v2 pp.1-17 (v1.1) | Installed is not active. Seven hand-written capability profiles. An unnamed "router" decides what is active. A setup plugin bootstraps each project. An MCP scope table keeps PROD off. |
| 08-09 | v2 pp.18-43 (v2.0) | Every external system becomes a governed capability: semantic tools, a mandatory Tool Gateway, brokers, an MCP registry, a model broker, a credit engine, an autonomy ladder 0-5, and an agent optimization loop. |
| 08-09 | router | Keyword router `routes.tsv → profiles.tsv → stack.tsv`. A model router was rejected on latency. The ledger, the reconciler and discovery are named as later slices. |
| 08-09/10 | built reader: cce90c0d, 66e88d1a, 25c90a0b | detect, adopt, recommend, stack and setup exist at import. The ledger and plugin discovery are added 08-10. |
| 08-13 | v3.0 pp.44-57 | The host executive is replaceable ("other capable hosts later"). Capabilities become a required part of a domain OS. Instruments are preferred over advisers. Multi-model specialists are demoted to optional. |
| 08-17 | Brief | "A tool being called does not mean it helped." Reviewers who agree are not independent. Coordination is harder than isolation. |
| 08-18 | h:c; M:concurrency-ladder-sequencing | Misroutes are bugs. Semantic routing only as a veto. The concurrency ladder, where verification only narrows. |
| 08-25 | h:z | Blind study: routing precision about 2%. A capability registry for a semantic router is rejected ("populate, don't build"). Deliberation forcing is held. |
| 08-30 | h:af, h:ag, h:ah | `route --ack` records declines. A′: Felix owns the moments, the model owns the selection, the record owns the judgement. `stack reconcile` proposes mounts from reach. |
| 08-31 | h:aj; M:build-the-class-not-the-instance | `felix procedures`: Felix may hold stances but never authors the enumeration. |
| 09-02 | v3.1 pp.58-72 | Felix owns the capability lifecycle. The capability object. NEED vs MOUNTED. Six activation moments. "Manual mounting is founder engineering hygiene." |
| 09-02 | SPEC | Capability Manager = package manager + IAM. Tiers T0-T3. A seven-step acquisition ending in a scoped lease. A one-line Execution Coordinator. Invariant 4. |
| 09-02 | M:felix-is-an-omission-engine | "What did neither know to look for" is the product. Deploy capabilities "mid session, early session, late session". |
| 09-03 | AMD | T2 becomes SOURCE_INSPECTED. Discovery is detached and unscheduled. Dormancy is derived. Seven checker controls. "There is no admission kernel." |
| 09-04/05 | h:am, h:an | The first-encounter toolbox becomes `commissioning.tsv`. The provider protocol. `felix_admit` by tier × grounding. A `grounding` column. |
| 09-12 | h:az | Install drift: a digest is taken at read time and compared at install. |
| 09-16 | lib/candidates.sh fc7a8ddf | First increment of obligation discovery. This is the last capability feature before the stall (M:capability-plane-stagnation-2026-09-25). |
| 09-17 | dist | Step 5's registry is partial. Sandbox, leases and revocation are absent. "Leases need mid-session activation." |
| 09-18 | M:felix-endgame-control-plane; h:bm | Endgame affirmed. The Capability Plane covers needs, provider, availability, when it appears, composition, how well it worked, and retirement. ECC is read as a content provider. |
| 09-19 | dd; h:bn | Control plane v0 = "the lease and its record, not the schedule". The market map is verified. Codex becomes the second-harness candidate. |
| 09-21 | wfs | Routing is compensatory and "expected to die". A Codex adapter is about 3-5 sessions. The Execution Coordinator owns sessions, and the Capability Manager owns leases. |
| 09-22 | h:bs; M:agent-vendor-access-and-terms; M:felix-market-map-verified-2026-09 | Labour is a commoditised provider class. Order: merge-point check, then adapters, then dispatch. Factory Missions already derives contracts. |
| 09-23 | road #293/#295; pilot; b2 | "Capability Plane stays thin" is struck within the hour, but its order is kept. 22 candidates proposed on Elenchus and Veldra. |
| 09-24 | RPT; a1bf2c7d | "The explicit Capability Plane still lags." Suggested Tasks are a crude primitive. Obligations gain a report-only `needs` column. |
| 09-25 | road 4c513055 (#374); README #373 | The capability lane takes one session in four, with three items: corpus, retire re-key, and dispatch dry run. |
| 10-01 | h:cw | D1 floor (no minimizer). D3 one attended tick. A capability queue of items 1-9. The spend cap is measured as soft. "A weak result does not narrow." |
| 10-02 | road 87a23a3b (#400); M:openai-credit-and-codex-adapter | Codex read-only (lane 4) and a Codex adapter about December (lane 5). Codex 0.153.4 measured. |
| 10-07 | p:98a6c7 | Mods round specified: typed in-session hooks are measured before anything is planned on them. |
| 10-09 | p:f104de; M:misrouting-belongs-in-the-capability-queue | OS-style read-only surfaces. Misrouting moves into the capability queue. |
| 10-10 | p:b65b07; M:ignore-guides-that-narrow-felix | Outside guides are read for evidence only. A second-family arm is added to the corpus. |
| 10-12 | reachspec | `felix stack --reach` and `felix status`: do the declared tools connect (advisory). |
| 10-13 | lib/own.sh d36ec648 | Unattended capability work runs only in the project's own checkout. |
| 10-18 | thesis | Seven invariants I1-I7. Rent the labour and the noticing. Own the need ledger, the lease, the floor, the Execution Coordinator, the moments and retirement. |
| 10-19 | dir rows 25/27/28; intent; vibe; jepa; p:07d9c8; p:a198d9 | The lane is kept and authority gated on trust. Derived rows are bounded. The input ladder. A ten-item lane order. The mods round is measured. |
| 10-24 | reachchk; audit; M:gstack-assessed-not-installed | Essentials are derived by breaking guards. Defects in detection and product intake (C090, C023, C101). |
| 10-27 | dir row 19 (cited by PR 474) | Second hosts: the Factory Droid adapter first, then Codex, beside the judge pin (lane item 11). |
| 10-28 | M:auto-adoption-stales-the-commission; M:agent-beacon-spike-2026-10-28 | An auto-adopted false `frontend` capability stopped landing. Beacon is proposed as event intake. |
| 10-29 | PR 473, PR 474; M:using-a-tool-is-the-capability-plane-floor | Beacon is a no-go, and Felix writes its own Codex reader. New floor: deliver a tool's answer at the moment it is needed, measure it, and count follow-through. |

## 2. The idea map

### (a) Needs and intake

| idea | first appeared | status now | sources |
|---|---|---|---|
| Felix owns what must become true; the host owns how, inside one unit of work | v3.1 p.63, 09-02 | decided (the thesis's charter) | SPEC l.18; v3.1 p.72; thesis §3; M:capability-plane-thesis-2026-10-18 |
| The product is what neither host nor Felix knew to look for (three authors missed one rate limit) | M:felix-is-an-omission-engine, 09-02 | decided | v3.1 p.67; README "Two questions" (#373) |
| Commissioning on first encounter: inspect, derive needs, reconcile capabilities, emit a receipt | v3.1 p.60 | built. 14-row table; the gate checks its shape and the merge checks its receipt. | SPEC §8; h:am; dist step 6; lib/commission.sh |
| Setup skills are commissioning instruments, not the architecture | v3.1 p.61, replacing the "bootstrapper" of v2 p.5 | built as provider rows | SPEC l.330; h:am; lib/commission-provider.sh |
| Risk envelope and founder intent contract (exposure, money, data, side effects, scale) | v3.1 p.61; ADD p.81 | partly built. Only maturity exists, asked at `felix new`, and nothing else reads it. | dist; built reader §4; h:am |
| No frozen checklist: a Baseline Coverage Compiler asks versioned providers for candidate obligations | v3.1 p.62; SPEC §9 | on file. `coverage.tsv` is specified, not built. | ADD p.82; h:bm; dd §2 |
| Situation, then candidate, then admission, then ledger; discovery only adds within an epoch | v3.1 pp.65-66 | partly built. Request/answer protocol exists; 22 proposed (7 Elenchus, 15 Veldra, 09-23), 0 admitted. | SPEC §3-4; lib/candidates.sh; README Status; built reader §3 |
| Discovery is detached and unscheduled, and `unknown` holds the gap | AMD §1.3, 09-03 | decided. The schedule is not built and is "not before March". | road §4; dist step 7 |
| Felix builds the observer, never the observation; `empty` needs a witness | ADD p.75; AMD §4 | built, enforcing | lib/probes.sh; lib/facts.sh |
| A standing need ledger printed "of M, residual R"; the proposer never reports its own residual (I1) | M:felix-endgame-control-plane, 09-18; thesis I1 | ledger built and enforcing; denominator and residual not built | thesis §4; lib/obligations.sh |
| Every admitted blocking need has a supply state; an obligation names the checker it needs (I2) | v3.1 p.69 `capabilities_needed` | partly built. `needs` resolves to complete, short or absent, report-only, and "absent" has no acquirer. | lib/obligations.sh:39, :300; road Phase 1; h:bv |
| Derived rows bind without per-row admission, within five bounds | thesis §11 Decision 2(b), 10-18 | decided (dir row 27). Nothing armed; pre-arming builds are listed. | dir §5; iva `row27-and-ladder-review.json` |
| "Situations owed": `situations.tsv` and `felix situations`, report-only | intent §9, 10-19 | on file, proposed as the first lane intake slice | dir §5; p:07d9c8 |
| Essentials derived by breaking guards; "of M guards, R unguarded" is intake's denominator | M:naive-builds-audit-paused-2026-10-24 ("not a hard-coded list") | decided (plan A), report-only first. Product adapters not built. | reachchk §2c |
| Felix owns the detector contract, never the detectors; detection is tested on three ecosystems | M:felix-is-an-omission-engine, 09-02 | open. Detection reads root manifests only (C090). | audit C090; intent §3 (Rust case) |
| Product projects are asked to propose obligations | audit C023, 10-24 | open, "waits for the design" | audit C023 |
| Session start adopts every detected capability that is not declared | built (lib/adopt.sh) | built, but flagged as policy produced by a relation (#252). It has no decline and stopped landing on 10-28. | h:bh; M:auto-adoption-stales-the-commission |
| Preservation, assumption and decision rows extend the ledger | vibe §6 item 1, 10-19 | on file | vibe §6 |

### (b) Supply: providers, tools, catalogue, install and compose

| idea | first appeared | status now | sources |
|---|---|---|---|
| Installed is not active; activate only the bundle a task needs | v2 p.1, 08-09 | decided. Built as reports (`felix profile`, `felix ready`). | v3.1 p.70; built reader §1c |
| Hand-written capability profiles (task class to bundle) | v2 p.3 | superseded in principle (v3.1 p.71 rejects a keyword-to-skill map), yet `profiles.tsv` is still built | templates/profiles.tsv |
| One owner per responsibility; reuse before acquisition | v2 p.5; v3.1 p.61 | decided | KRN p.61 |
| Capability Manager = package manager + IAM, with trust tiers T0-T3 | SPEC §7, 09-02 | decided; partly built. No per-provider record of tier, scope or activation. | dist step 5; AMD §1.2 |
| Acquisition: discover, inspect, sandbox, authorize (lease), verify, operate, revoke | SPEC §7 | partly built (first two steps only). T2 renamed SOURCE_INSPECTED. | ADD p.80; AMD §1.2; dist |
| Capability object (provides, providers, activation, per-environment authority, deactivation); provider object with declared vs observed behaviour | v3.1 p.63; ADD p.80 | not built | dist step 5 |
| Resolution is a dependency problem: the minimal bundle, scored on function, grounding, context cost, security, provenance, compatibility | v3.1 p.64 | not built | KRN p.64 |
| "Approve authority, not plumbing": acquiring a low-risk capability is autonomous | v3.1 p.63 | decided; built as `felix_admit` | ADD p.81 |
| Install policy by tier × grounding; INFERRED never installs; high never installs | h:an #159, 09-04 | built, enforcing | lib/admit.sh; MEM rv5 coverage |
| Read a plugin at its pinned sha before installing it; keep a digest; report drift | h:an #161; h:az 09-12 | built | lib/discover.sh; M:installed-plugins-leave-the-catalogue |
| Discovery blind spots: prose-only plugins tier low unread; installers outside the plugin layout are invisible; 42 of 269 plugins cannot be fetched | M:jev-assessed-not-adopted; M:gstack-assessed-not-installed (#461); h:an | open | as cited |
| A capability registry feeding a semantic router | h:z, 08-25 | rejected ("populate, don't build"; "do not build a second registry") | MEM rv5 coverage |
| Starter catalogue: 7 plugins at user scope; 16-row `catalog.tsv`; high-risk rows wait for a person | import | built | README; templates/catalog.tsv |
| MCP is an adapter, not the security layer; registry of source, pinned version, risk, scopes; containerized servers with egress limits | v2 p.31 | on file. The risk column is built; containment is not. | KRN p.31 |
| Semantic tools, a mandatory Tool Gateway, brokers, `credential_ref` | v2 pp.19-31 | on file. Retained at v3.0 p.56; no later source mentions them. | v3.0 p.56 |
| ECC proposes and never decides; its hooks go off in two steps | v3.1 p.68; dd §4 | decided. Step 1 done 09-21/22; step 2 waits on the harvest rows. | M:ecc-plugin-assessed-not-mounted; road Phase 4 |
| Trust recorded per provider surface; `coverage.tsv` with citations checked offline | h:bm, 09-18 | on file, waiting on the table validator | dd §2 |
| Reach: do the declared tools connect, read from an empty private directory | reachspec, 10-12 | built, advisory only | lib/reach.sh; lib/reach-read.sh |
| Cloud sessions carry the toolbox (`toolbox.json`) | h:dh, 09-28 | built, but its pins lag the local install (C111) | audit C111 |
| Deliver a tool's answer when it is needed, measure its quality here, count follow-through ("naming is advice; mounting is inventory") | M:use-what-you-set-up, 09-03 | decided 10-29. Graph-query build started 10-29. | M:using-a-tool-is-the-capability-plane-floor |
| Egress control before industrial use: confidentiality classes, an egress ledger, a local-only route | M:tsmc-prospective-test-boundary, 10-10 | not built | M:gstack-assessed-not-installed; p:b65b07 (experiment G) |

### (c) Leases, dispatch, workers and the Execution Coordinator

| idea | first appeared | status now | sources |
|---|---|---|---|
| Subagents are narrow specialists; parallelize only separable work | v2 p.6 | decided. `felix shape` built (advisory). In practice, 12+ sessions ran at once. | lib/shape.sh; RPT pp.2-4 |
| Authority narrows downward; it widens only by an explicit, audited mechanism | v3.0 p.48 | decided (v3.2 invariant 5) | SPEC l.13-20 |
| Execution Coordinator: schedules host work, retries, repair, provider lifecycle | SPEC l.62 | decided as Felix's own: units, order, isolation, "keeps and does not rent". One-line charter only; not built. | thesis §3, §5; wfs; built reader §4 |
| A scoped activation lease, no authority beyond the envelope | SPEC §7 step 4 | decided; not built ("`lease`: no functions") | dist |
| Leases need a host that activates capabilities mid-session | dist, 09-17 | superseded 09-19: a lease is one dispatched session's launch configuration, and revocation is that session ending | dd §3; M:felix-endgame-control-plane |
| Control plane v0 is the lease and its record, not the schedule (`felix dispatch --dry-run`, one typed tick) | dd §3, 09-19 | decided; not built | h:bn; README Status |
| Lease size and costs measured: 27 plugins / 12 MCP / 434 skills by default vs 1 / 0 / 17 leased; the spend cap is soft (39 of 39 runs overshot); `--bare` means an API key | dd §3; h:cw wave 1 | built (as measurements) | MEM rv5 host-measurements |
| Lease fields: pool, `claude --version`, full model id, named answer file, `Read(//proc/**)` denied, no Agent tool, telemetry off, `total_cost_usd` checked after the run | h:cw item 4 | on file (lane dry-run item) | p:a198d9 (with no Agent tool the cap stopped after one request) |
| Felix computes the lease and the host enforces it; a model may only narrow it; fields the host does not enforce read "unenforced" (I3) | thesis I3, 10-18 | on file | thesis §4 |
| Independence is set on the lease: separate leases for checker, mutation author and verifier (I5) | thesis I5 | on file. Blind authorship is a convention only; control 7 is absent. | projects/felix/qualification.tsv |
| One attended dispatch tick before March, on the founder's key with a dollar cap (D3) | h:cw, 10-01 | decided (dir row 17). Not built; comes after the dry run and #350. | road header |
| Build intake now; dispatch, leases and the floor wait on trust milestones | p:07d9c8, 10-19 | decided (dir row 25) | dir §5; M:capability-plane-thesis-2026-10-18 |
| Units of work are derived, never written by a model; a slice rule; isolation by shared writes | intent §4 | on file. The partition is built in `lib/shape.sh`. | intent §2 stage 10 |
| Two worker classes behind adapters (native, isolated) | thesis §8 R2 | on file | thesis §8 |
| Unattended repair worker: Read and Edit only, the gate decides, push only on green | `engine/harness/templates/unattended.yml`, 09-23/24 | built and switched off. Needs lease hardening and one attended run. | h:cb; h:cw |
| Concurrency ladder: verify finished work, verify designs, hold independent state, work concurrently | h:c, 08-18 | decided. Rungs 3-4 not built; rung 4 waits on evidence. | M:concurrency-ladder-sequencing; pilot E08 |
| Suggested Tasks: the model finds follow-on work, a person authorizes it, a new session runs it | RPT §14.1 | on file | RPT §13 |
| A task-scoped checkpoint of Felix-written references, never a transcript | h:cw item 9 | on file; depends on the replay | thesis §8 |
| Check each Workflow stage by its output (a stage that did nothing is recorded done) | p:a198d9, 10-19 | decided, lane item 1 | p:07d9c8; thesis §2 |
| Spend governor: put a price on a spawn and tie the limit to landing throughput | M:token-burn-measured-2026-10-08 | partly built (`felix cost`, hold-once); the governor is not built | lib/cost.sh |
| Unattended work only in the own checkout; autonomy grants `tidy` and `commission` | lib/own.sh 10-13; lib/autonomy.sh | built, enforcing | built reader §1b-c |

### (d) When a capability appears: moments, triggers, routes

| idea | first appeared | status now | sources |
|---|---|---|---|
| Session moments: fresh session, before coding, before done, before merge, after deploy | v2 pp.1-17 | partly built (hooks; `lifecycle.tsv`, `moments.tsv`) | lib/coverage.sh; lib/lifecycle.sh |
| Six activation moments, including event-triggered runs (woken by Sentry, CI or a deploy) | v3.1 p.64; v2 p.9 | on file. Event-triggered runs not built. | KRN p.64 |
| NEED(capability) vs MOUNTED(capability); attach at the next supported boundary | v3.1 p.64 | decided; not built as states | KRN p.64 |
| Deploy skills, plugins and MCP "mid session, early session, late session" | M:felix-is-an-omission-engine, 09-02 | decided as intent. "The mid-session half is materializing obligations." | thesis I7 |
| Keyword router names a play for each prompt | router, 08-09 | built, advisory. About 2% precision (n=158); reached in 24 of 418 sessions; 106 declines. | h:z; wfs; M:misrouting-belongs-in-the-capability-queue |
| A model in the prompt path for routing | router | rejected (4.1-8.6 s per call; no key) | lib/route.sh header |
| Semantic routing as a veto only | h:c, 08-18 | rejected in effect (veto layer rejected in decision A′) | M:jev-assessed-not-adopted |
| A′: Felix owns the moments, the model owns the selection, the record owns the judgement | h:ag, 08-30 | decided; built (0.49.31) | h:ah |
| Record every decline (`felix route --ack`) | h:af, 08-30 | built | M:record-every-decline |
| Deliberation forcing with decision-action closure | h:z, 08-25 | on file, held by the founder | h:z |
| Fix misrouting: stop routing what nobody typed, re-measure, do not improve the table | M:misrouting-belongs-in-the-capability-queue, 10-09 | decided; not yet placed in a roadmap | thesis §8 |
| Retire the router | wfs, 09-21 | open. A charter change, the founder's at Decision B, not before March. | road §4; README |
| Recorded state decides when (I7): new epoch, new surface, raised risk, intent change, UNKNOWN entering a release window, stale receipt | thesis I7, 10-18 | on file; not built | intent §6 (adds more triggers) |
| Discovery budgets B0-B4 and a stop rule | SPEC §10 | decided; not built, not before March | dist step 7; road §4 |
| `stack reconcile`: reach is the only evidence for a mount ("no mount-on-play-named") | h:ah, 08-30 | built (proposes only) | lib/stack.sh |
| Restart moments (a session behind the engine, idle resumes) | h:bz | built | RPT appendix 945c0299 |
| Moves fired by state: interrogate the objective, premortem, proxy-conflict halt, simplification | vibe §6 item 3 | on file | vibe §8 |

### (e) Outcomes and retirement

| idea | first appeared | status now | sources |
|---|---|---|---|
| Agent optimization loop: record tools, cost, retries and success; find redundant calls | v2 pp.38-39 | on file (retained at v3.0; no later source) | v3.0 p.56 |
| "A tool being called does not mean it helped" | Brief v1 p.1 | decided as a principle | L "Utilisation is not utility" |
| Ledger of `named` vs `calls`, with retire, unobserved and unrouted classes | lib/ledger.sh, 08-10 | built, report-only. The retire list was emptied because it had no true positives. | h:an, h:ao, h:ap |
| The retire rule needs a route to have named the tool, so it dies with the router | M:capability-plane-stagnation-2026-09-25 | open. Lane item: re-key retirement on what Felix installed. Not built. | road §3; h:cw item 7 |
| A dead hook reads as zero use and feeds the retire list | audit C101, 10-24 | open | audit C101 |
| Outcome-attribution record joined by a task key, record only | h:cw item 6 | on file. The model source moved to `modelUsage`. | p:a198d9 |
| Keep a provider on attributed, lagged outcomes; retirement is proposed, never silent; attribution flows trust to capability only (I6) | thesis I6 | on file. Row 25 gates it on the outcome record and the re-key. | p:07d9c8 |
| Revoking a provider invalidates the receipts built on it | SPEC §7 step 7 | decided; not built (no revocation exists) | ADD p.80 |
| Metrics: activation precision, acquisition success or rollback, founder hygiene interventions | v3.1 p.70 | on file; not computed | SPEC §14 |
| Log the admissible set and the pick's probability so the choice can be evaluated later | jepa §7, 10-19 | on file, "the one thing to do early" | jepa |
| Learn how to choose, never what binds | jepa §7 | on file, "not now" | jepa §8 |
| Miss-to-layer loop; Felix's tables learn, scored only on the sealed corpus | vibe §6 item 4; intent §7 | on file | intent §7 guards |

### (f) Floors and model choice

| idea | first appeared | status now | sources |
|---|---|---|---|
| Model broker driven by measured success, cost and credits; a credit engine | v2 pp.38-40 | never retired by name, and no v3.x source mentions it | v3.0 p.56 (absent from the matrix) |
| Multi-model specialists | v2 pp.35-36 | superseded: demoted to optional (v3.0 p.56); independent discovery allowed only when it narrows (v3.1 p.72) | KRN p.72 |
| Instruments over adviser LLMs | v3.0 p.47 | decided | KRN p.47 |
| Felix sets a floor and the host picks the cheapest model above it; Felix never builds a minimizer | h:cw D1, 10-01 | decided (dir row 17) | road §7; MEM rv5 review §4.2 |
| Difficulty is the host's problem; consequence and accepted outcome are Felix's | MEM rv5 review | decided | thesis I4 |
| Consequence floor: advisory, raise-only, full model ids | h:cw item 8 | decided as a shape; not built; last in the lane | thesis I4; p:07d9c8 |
| Input-rewriting floor | h:cw | declined by default. The mods round removed one of its reasons. Founder's call. | p:a198d9; dir §6 |
| Held-out replay with predeclared rules decides whether adaptive routing is built | h:cw item 2 | decided (about $410 approved); not run; ninth in the lane | M:felix-report-v5-review-2026-10-01 |
| No receipt or merge blocker reads which model did the work | MEM rv5 | decided (trust invariance) | thesis I4; M:mods-round-addendum-417 |
| Pin full model ids; aliases step down silently; read the model from `modelUsage` | h:cw; p:a198d9 | decided | thesis §2 |
| Build-stage model rules: Opus for specs and review, Sonnet for implementation, red twice moves to Opus | h:cw | decided as a working protocol, not Felix behaviour | M:engine-builds-use-ultracode |
| Pools are a dormant contract; a second provider shows the verdict holds, it does not pool compute | h:cw; MEM rv5 §4.8 | on file | M:agent-vendor-access-and-terms |
| Mod levers measured: `agent.spawn` raises or lowers; `turn.step` reaches Workflow agents; `onFailure:"block"` fails closed except at Stop | p:a198d9 | built (measured) | MEM mods `disposition.md` |

### (g) Second hosts and adapters

| idea | first appeared | status now | sources |
|---|---|---|---|
| The host executive is replaceable: "Claude Code today; other capable hosts later" | v3.0 p.44 | decided as direction | Brief ("replaceable model contexts") |
| "Claude Code first, done best; other hosts later" | M:felix-is-a-commercial-product, 09-22 | superseded on timing (10-02, 10-27) | M:openai-credit-and-codex-adapter |
| Codex CLI is the second harness that would prove the ledger survives a change of agent | dd §4, 09-19 | decided as the rationale | wfs |
| Claude's hook format is the de facto governance ABI; the merge point is host-independent | M:agent-vendor-access-and-terms, 09-22 | decided | h:bs |
| Integration order: merge-point check, then ride-along adapters, then dispatch on the customer's key | h:bs, 09-22 | decided | road §1 |
| Codex read-only for advisory review, as a second blind author, and as a replay arm | road item 4, 10-02 | decided (dir row 19), lane item 4 | M:standing-direction-file |
| Codex adapter: `apply_patch` paths, Stop output, a transcript reader per host, Codex config, hook-hash check | road item 5 | not built (4-6 sessions). `write_stdin` reaches no hook. | M:openai-credit-and-codex-adapter; L 2026-10-02 |
| Factory Droid adapter first, then Codex, beside the judge pin | dir row 19, changed 10-27 | decided per dir. The roadmap text waits on PR 474. | PR 474; M:felix-official-pitch |
| Droid does not carry Felix's governance (PreToolUse matches only Edit and Read; no SubagentStart; managed-hooks setting) | M:agent-vendor-access-and-terms | on file ("an adapter project, not hours") | as cited |
| Agent Beacon as the Codex and Droid transcript reader | M:agent-beacon-spike-2026-10-28 | rejected 10-29 (no go). At most an optional extra source. | PR 473; MEM beacon |
| Felix writes its own Codex reader; it scans `write_stdin` at Stop and blocks nothing | PR 474, 10-29 | on file (draft PR, needs the founder) | PR 474 |
| About 520 hook lines become a lease's allowlist, completion condition and launch context | wfs §4 | on file | wfs |

### (h) The experience: intent to production, questions, maturity, autonomy

| idea | first appeared | status now | sources |
|---|---|---|---|
| The founder owns product, taste and approvals; escalate only product calls, exhausted repair, high-risk acts | v2 pp.2, 14 | decided; carried into v3.1 p.59 and the endgame | M:felix-endgame-control-plane |
| Felix must not cede capability arrangement: "if the founder is thinking about tooling, Felix has failed" | v3.1 p.58 | decided | M:felix-is-the-implementation-pilot |
| Three loops test: commissioning alone is a setup assistant, execution support alone is ECC++, gap discovery alone is an auditor | v3.1 p.59 | decided | KRN p.59 |
| Endgame: Felix decides what engineering must exist, assembles, operates and proves it, and returns only the irreducible | M:felix-endgame-control-plane, 09-18 | decided | dd §1 |
| North star: an obligation nobody remembered blocks an incomplete deploy while the founder argues about onboarding | v3.1 p.70 | decided as the eval; not yet passed | SPEC §15; thesis §11 |
| Decide the how; bring the owner only what changes the product | pilot rule 1, 09-23 | decided | M:design-questions-are-felix-not-founder |
| The founder surface is an exception router, with a nine-field decision packet | v3.0 p.52 | on file | RPT §14 (queues by human action) |
| Autonomy ladder 0-5, earned by proven reliability | v2 pp.20-21 | on file, never reconciled. The thesis says channels are never earned. | thesis §12 |
| "Truly autonomous" = engineering leakage per objective at zero, guards holding, every return typed | thesis §5 | on file. Open whether it replaces the 08-12 objective. | dir §6 |
| Anti-slop headline: decisions made, obligations proven out of a denominator, UNKNOWN holding, residual | thesis §6 | on file | vibe §7 |
| Intent-to-build: deterministic frame, typed model content, computed materiality, Pareto front for architecture | intent, 10-19 | on file. §11 a, b, e, f, g open. | dir §7 |
| Input ladder L1-L6: founders at L3, engineers at L2-3; below L3, ask before building | dir row 28, 10-19 | decided | iva `row27-and-ladder-review.json` |
| Interaction layer: `asked` rows, Stop reads handed-back work, a decisions table with revisit triggers | pilot §7, 09-23 | on file | b2 E25 |
| OS-style read-only surfaces; a surface is a view over a command; unread means unknown | M:felix-interface-direction-2026-10-09 | decided as direction; partly built (`felix status --tsv`, the `dash` mod, inventory) | p:f104de; M:dash-mod-before-felix-dashboard |
| Judge a design by what runs without the founder, once, on two ecosystems | M:judge-by-what-runs-without-the-founder, 10-19 | decided | intent header |
| Owner contract: a person signs a hash of the residual at the release tier | vibe §12 | on file | vibe |
| Per-function on/off toggles | M:user-toggles-for-felix-functions, 09-25 | on file, deferred | as cited |

## 3. Built versus designed

From the "built" reader, at HEAD `78f0268f` (10-28). All files are `engine/harness/lib/` unless stated.

| strength | components | what they do today |
|---|---|---|
| enforcing | `obligations.sh` (`obligations --gate` in `felix gate`) | Runs the admitted ledger. Applicability and discharge are recomputed on every run. A blocking obligation stops the merge. The `needs` column is report-only. |
| enforcing | `probes.sh`, `facts.sh` | Five-state reality probes. `blind` and `unknown` block, and every answer is appended to `facts.log`. |
| enforcing | `commission.sh` | The gate fails when the table is absent or malformed. The merge blocks when the receipt is missing or stale. Held rows never block. |
| enforcing | `admit.sh` | The one install policy, by tier × grounding. |
| enforcing | `own.sh`, `autonomy.sh`, `budget.sh`, `overnight.sh` | Unattended work only in the own checkout. Opt-in grants. A daily ceiling on unattended runs. Granted nights. |
| acting, not judging | `adopt.sh` (automatic at session start), `stack apply --yes`, `ready --fix`, `discover --adopt` (low risk only), `toolbox --route`, the provider admit phase, `felix quarantine` | Declare rows, install what `admit.sh` allows, or disable a plugin. None decides a verdict. |
| advisory | `route.sh`, `reach.sh`, `shape.sh`, `graph.sh` | The prompt hook names a play, and Stop raises a skipped play once. Connectivity of declared tools. Fan-out advice. A graph line. |
| report-only | detect, recommend, discover (default), candidates, epoch, procedures, coverage, lifecycle, ledger, stack plan/reconcile, ready, toolbox, next, setup, cost, unattended, decisions | They show and propose. `candidates.sh` writes only `candidates.tsv`. The ledger prints a retire banner, and nothing applies a retirement. |
| built and switched off | `templates/unattended.yml` | Restricted repair worker. |

Data:
- `candidates.tsv`: Elenchus has 7 rows and Veldra 15, from one run each on 09-23. None was admitted.
- felix `routes.log`: 1399 dated rows, 47% with no route.
- felix `ledger.d`: 239 files, 5925 rows.

Source: built reader §3.

Not in the engine at all:
- leases;
- a sandbox (`admit.sh:46-47`: nothing is sandboxed);
- the Execution Coordinator;
- dispatch of work units;
- the Capability Manager, named once as a future owner (`obligations.sh:300`);
- Codex and Droid adapters;
- the floor;
- model routing;
- a residual or denominator;
- situations;
- outcome records beyond `named` and `calls`.

Source: built reader §4.

Pace: no capability-file commits from 09-17 to 09-21 (M:capability-plane-stagnation-2026-09-25). From 09-25 to 10-19 there were 2 capability features and 14 fixes, and none was a lane item (thesis §10).

## 4. The market line

| area | the market already has (Felix rents or integrates) | Felix's own, still unoccupied | decided line |
|---|---|---|---|
| labour | Claude, Codex and Factory as one commoditised provider class, run on the customer's key (h:bs) | none | Rent the labour (thesis §1; vibe §13) |
| model choice | Minimizers from GitHub, Cursor and Factory; product-level routing in Cursor, Copilot and Factory (h:cw D1; M:felix-report-v5-review-2026-10-01) | Consequence floor; outcome record | D1: never build a minimizer; adaptive execution sits inside the capability lifecycle (h:cw) |
| worker runtime | Forks, background agents, `agent.spawn`, Agent `effort`, the agents view (thesis §8) | The Execution Coordinator: which units exist, their order, isolation and lease | Thesis R1 split: rent the runtime, own the coordinator |
| catalogue and install | Marketplaces. Tessl (registry, security levels, manifest, activation, evals). AAIF Agent Plugins 1.0, which leaves verification and approval to clients. Anthropic's install suggestions and unused-plugin reports, though it "never installs a plugin automatically" (M:felix-market-map-verified-2026-09) | Need-driven lifecycle (Tessl removed need-derivation in CLI 0.76.0). Pinning, read-before-execute, tier, lease, revoke. | Rent the listings; own the admission contract (thesis §8) |
| noticing | The host's "You should know" and `/advisor`; in-session noticing (thesis §8 R6) | A standing, grounded intake with denominator and residual. Nothing in Claude Code 2.1.286-2.1.303 ships standing, blocking project obligations (cpa `verification.json`). | Rent the proposing model; own probes, request, corroboration and recall (thesis §12) |
| deriving needs from intent | Factory Missions derives a validation contract per mission (M:felix-market-map-verified-2026-09) | A contract that stands across missions, binds to a commit, goes stale and blocks | "Derivation from intent" is not unoccupied; "the time axis ... is the differentiator" (09-22 delta; vibe §13) |
| receipts | AI-SDLC's SHA-bound DSSE attestations; GitHub rulesets and attestations | Receipts that go stale on inputs outside the tree; a derived blocking UNKNOWN in a standing ledger | Never claim repo-owned receipts as novel (M:felix-market-map-verified-2026-09) |
| retirement | Anthropic's unused-plugin reporting | Retirement on observed, attributed value | Unoccupied (M:felix-market-map-verified-2026-09; thesis I6) |
| provenance and sandbox | Entire (sessions from 8 harnesses into git); NVIDIA OpenShell (sandbox, credential gateway) | A trust ledger enforced across harnesses | Integrate OpenShell; provenance is occupied, trust is not |
| telemetry | Harness's telemetry-to-rollback loop | Reopening an obligation from production telemetry | Unoccupied (market-map step 13) |
| hooks and console | Claude's hook format copied by Cursor, Copilot, Codex and Factory. Cursor Agents Window, OpenHands Agent Canvas, Factory App (RPT App. C) | A read-only data contract (`felix status --tsv`) | Hook plumbing is no differentiator (M:agent-vendor-access-and-terms); rent transcript rendering (thesis R5) |

The map's 13-step loop (M:felix-market-map-verified-2026-09, 09-19):
- Steps 1, 2, 8, 10, 11 and 12 are crowded.
- Steps 5 and 13 are empty everywhere.
- The 09-22 delta made "nobody derives capabilities from obligations" false, because of Factory Missions.
- What stays unoccupied: a standing blocking UNKNOWN, receipts that go stale, retirement on value, cross-harness trust, and reopening obligations from telemetry.
- "The position incumbents are least able to take is INDEPENDENCE."
- Felix's claim (d) is that capability lifecycle is the "emptiest ground in the market and Felix's least demonstrated".

The thesis's build/own/rent/drop (thesis §8; on file except the lane order):
- **Build:** the corpus, the attended tick, the outcome record, the retire list, Codex read-only, obligation intake, retirement on observed value.
- **Own the contract:** the dry-run lease, the floor, the Codex adapter, two worker classes, native agents not being the source of truth, provider admission.
- **Measure first:** the #417 round, the replay, the checkpoint, the advisory floor, agentId leases.
- **Rent:** the console UI, the advisor as a discovery source, the minimizer, the listings, the runtime.
- **Fix now, retire later:** the keyword router.
- **Rejected:** "capability stays thin", Felix as scheduler only, and derivation or repo receipts claimed as novel (thesis §12).

The core statement (h:bs, 09-22): "qualifying the evidence providers (observers and checkers) and deriving needs from standing obligations" is the distinct core.

The scope rule (M:ignore-guides-that-narrow-felix, 10-10): outside guides supply evidence, never scope.

**Factory, specifically:**
- **Missions:** derives a validation contract with per-assertion Evidence lines, and the skills each part needs. It does this within one mission. The contract is user-skippable, not bound to a commit, and nothing goes stale (M:felix-market-map-verified-2026-09; vibe §13).
- **08-27 research post:** builds "an inventory of what must be established, procedures ..., and current evidence", before implementation, and says this is going into the next Missions (same note).
- **Wording and metrics:** its "risk tiers, validation gates, audit" is marketing wording. Its "Autonomy ratio" counts tool calls per user message (same note; dd §4).
- **Factory Private:** puts the control plane in the customer's VPC (09-18).
- **Funding:** USD 200M at 5B (09-15).
- **`droid exec`:** runs headless with `--auto`, `--restrict-tools` and `--mission`. Its terms bar "competing products", a "service bureau" and published benchmarks (M:agent-vendor-access-and-terms).
- **Model routing:** ships a minimizer (h:cw D1).
- **Unverified leads:** difficulty routing, and a cross-vendor validator in Missions that can be switched off (vibe §13).
- **Threat:** "the largest threat to the narrative"; medium-high to own the narrative, low-medium to occupy the semantics (dd §4; same market note).

**Where Felix deliberately differs:**
- The contract stands across runs and binds to a commit.
- It goes stale when a dependency changes.
- The party being judged cannot skip it.
- Independence is set on the lease, and cross-vendor work runs on the customer's keys, because "the vendor paid when its agent finishes cannot credibly audit that agent" (thesis I5).
- Felix rents the minimizer instead of building one (D1).
- Felix binds worktree-style execution "to Trust Plane evidence, revision freshness, and landing authority" (RPT App. C).
- Felix never runs Droid on its own account for customers (M:agent-vendor-access-and-terms).

## 5. Contradictions and drift

| topic | what the documents say | latest dated position |
|---|---|---|
| Trust first or alongside | SPEC §13 places capability trust at step 5, after the kernels. RPT §15.8 says "after the Trust/continuity substrate stabilizes". The 09-23 "stays thin" line was struck, but its order was adopted (#293/#295). The founder on 10-18: "trust first then capability on top". Deck slide 17 says "Trust Plane MVP". | Row 25 (10-19): intake now, authority behind trust milestones. Slide 17 is still stale (dir §6; thesis §10; road §7). |
| Dispatch dates | dd §5: item 5 of 6 (09-19). February (#293, 09-22). "March at the earliest" (road §1). Dry run moved into the lane (09-25). One attended tick before March (D3, 10-01). | The D3 tick, after the dry run and #350. road §1 still says March beside the exception (road; h:cw). |
| Lane order | road §3: corpus, retire, dry run, Codex RO, Codex adapter. README: corpus, dry run, retire. h:cw queue 1-9: host measurement, replay, corpus, dry run, tick, outcome, retire, floor, checkpoint. | Ten-item order (p:07d9c8; thesis §10): stage checks, #417, corpus, Codex RO, dry run, retire re-key, outcome, tick, replay, floor. dir §5 adds item 11 (Droid, then Codex). The replay that "decides whether adaptive routing is built" now comes after the tick. |
| Item numbering | "Capability item 4" means the dry run in h:cw but Codex RO in p:b65b07. "Lane item 1" means the corpus in road but host measurement in h:cw. "Item 7" means retire in h:cw but the outcome record in jepa and intent §9. | dir §5's ten-item numbering (M:standing-direction-file: dir wins). |
| Weak corpus result | "Narrow to the obligations people name": 4c513055 (09-25), the README branch, h:cw item 3, the MEM rv5 corpus disposition. | "Investigate, do not narrow": road §5 as amended in ea865e82 (10-01). Stale copies flagged in p:07d9c8 and audit C017. |
| Leases and mid-session | dist (09-17): leases need mid-session activation (h:bi and h:bl repeat it). | dd §3 (09-19): a lease is a launch configuration. |
| Does a lease run hooks; the "no plugin" lease | dd and wfs: no hook runs, so closure holds by construction. h:cw lists this as unmeasured. The mods round: no mod fires under `--bare`, and a floor or request stop needs a loaded plugin. | Open, the founder's call (p:98a6c7; p:a198d9). |
| Source of a worker's model | h:cw: `resolvedModel`. | p:a198d9 (10-19): `modelUsage` or the transcript's `message.model`. |
| Router's fate | router: built as the mechanism. h:z: the evidence shows a routing role. wfs: "expected to die". README: "should go", yet it still suggests tools. The retire rule depends on it (M:capability-plane-stagnation-2026-09-25). | Fix misrouting now (thesis §8); retirement is a charter change at Decision B, not before March (road §4). |
| What triggers a mount | router: the reconciler acts when a route names an unmounted tool. | h:ah: "no mount-on-play-named"; only reach counts (built). |
| Who installs, and when | h:ak (09-03): install ungranted. h:am: commissioning installs. h:az: the README claim had never been true. #252: session start adopts on its own. C034: the consent text says nothing is installed. Anthropic never installs automatically. | Built: commissioning and adopt act. #252 and C034 are open (h:bh; audit). |
| Registry | h:z rejects a capability registry. v3.1 Phase 2 and SPEC step 5 want a provider registry. MEM rv5: "do not build a second registry". | Unreconciled. These are a routing registry and a provider-trust record. |
| Capability trust in the build order | v3.1 p.71: registry at phase 2, before commissioning. SPEC §13: step 5, after the kernels. | In practice step 6 (commissioning) is built and step 5 is partial (dist). |
| Second host timing | "No second host until Claude Code is right" (09-22). Phase 4 (h:cw). December, after arming (10-02). Sessions: 3-5 (wfs) or 4-6 (road). | Row 19 (10-27): Droid first, beside the judge pin. The roadmap waits on PR 474. |
| Who gives a derived row force | thesis 2(b): witness-backed candidates. The row-27 review: class rules only. intent §7: mechanical after the pin. | Row 27: "witness-backed rows only, never a single model finding". Whether class force stays permanent is open (§11f). |
| Column name | `capabilities_needed` (v3.1 p.69; road Phase 1). | `needs` is what is built (lib/obligations.sh; h:bv; README). |
| Parallelism | v2 p.6: separable subagents are safe. Brief failure 03: coordination is the harder problem. RPT: 12+ sessions and no landing actor. pilot E08: the founder is the message bus. | No design for concurrent work in one project beyond the ladder. |
| Autonomy scales | GREEN/YELLOW/RED (v2 p.8). AUTONOMOUS/POLICY-GATED/FOUNDER (v2 p.13). Levels 0-5 (v2 pp.20-21). | Unreconciled. The thesis says channels are never earned (§12). |
| Dormancy | ADD p.76 stores ACTIVE→DORMANT. intent §6 holds UNKNOWN for one epoch. | AMD §1.4: derived, never stored. dir §5 follows the row-27 safety attack. |
| ECC hooks, step 1 date | wfs: not made by 09-21. pilot E12: 09-22. | M:ecc-plugin-assessed-not-mounted: made 09-21, completed 09-22. |
| Beacon egress | PR 473: `lsof` clean. | MEM beacon run 3: `lsof` fail, 12 remote sockets. The PR text was not updated. |
| "Designed starting that day" | The 10-29 MEMORY.md index line says the plane's design starts on 10-29. | v3.1, SPEC, dd, the lane and the thesis predate it. |
| Landing counts on 10-19 | 0 lander merges (vibe). 2 (jepa). 25 rows and 0 merges (intent). 0 of 34 (row-27 review). 23 rows and 0 merges (M:judge-by-what-runs-without-the-founder). | Read at different times. |

## 6. Questions still open

**The founder's**
1. Admit or refuse the 22 candidates (dir §6; thesis Decision 2(a)).
2. The corpus spending ceiling: $96-349 per corpus at 3 runs, $172-632 with replication. He deferred it on 10-19 (dir §6; p:07d9c8).
3. Intent design §11 a (how his words become binding, "the first" of the eight), and b, e, f and g (dir §6; intent §11).
4. Whether leakage per objective replaces or refines the 08-12 objective (dir §6).
5. Whether Felix must also serve a non-owner. It "was not raised" (vibe §14; dir §6).
6. The API key and spend limit for the D3 tick, to be asked when the tick is near (h:cw).
7. The "no plugin" lease against mod-based stops and floors, and the input-rewriting floor after Q5, Q9 and Q13 (p:98a6c7; p:a198d9; thesis §11).
8. Router retirement, a charter change, at Decision B (wfs; road §4).
9. Whether the console should ever act (h:cw).
10. PR 474, and any change to lane item 5, which is a dir edit (PR 474; M:agent-beacon-spike-2026-10-28).
11. Whether Beacon's offline readers may run on a pilot engineer's machine (PR 473).
12. Whether `independence` at 4 of 6 controls is grandfathered (h:cw).
13. A discovery-schedule grant, an autonomy grant for unattended commissioning, and the risk-envelope values (AMD §1.3; h:ao; dist).
14. The commission consent text against what it actually installs. This is a founder stop (audit C034).
15. An unattended credential for experiments (vibe §14).
16. Deck slide 17, which is his document (dir §6).

**Felix's**
1. What the Execution Coordinator is: units, order, isolation and concurrency in one project. It has only one line (SPEC l.62; thesis §5; RPT §15).
2. The lane's six questions: what a project needs, who provides it, when it should appear, how to compose it, how well it worked, and when to retire it (road §3).
3. How a need that resolves to `absent` gets supplied, since there is no acquirer (lib/obligations.sh:300).
4. One trigger list out of I7, intent §6 and vibe's moves (thesis I7; intent §6; vibe §6).
5. Who selects the worker model once Felix dispatches (h:ag; h:cw).
6. Host measurements still owed:
   - pre-tool deny inside a restricted lease;
   - a user-settings plugin under `--restricted`;
   - an OS-level egress block;
   - Workflow agents;
   - Q8;
   - the 2.1.299-301 arms.

   Sources: h:cw; p:a198d9.
7. Whether to start Docker for T2 or keep denial-on-shape, and whether the replay sandbox holds (V0) (AMD §1.2; MEM rv5).
8. Discovery blind spots: 42 plugins that cannot be fetched, hook-only and prose-only plugins, and installers outside the plugin layout (h:an; h:ao; M:jev-assessed-not-adopted; M:gstack-assessed-not-installed).
9. What session start may write on its own, and a decline for detected capabilities (h:bh #252; M:auto-adoption-stales-the-commission).
10. Detection depth (C090), surfacing candidates in `felix next` (C089), and product intake (C023) (audit).
11. Reconciling the routing-registry and provider-registry ideas (h:z; dist).
12. What maturity changes in capability choice (dist; h:am).
13. A scope that spans several repositories (intent §4).
14. Conflict resolution between disagreeing peers for rung 4 (M:concurrency-ladder-sequencing).
15. Whether learned choosing fits intent §11f's "never on its own" (jepa; intent §11).
16. Where a governed product's doctrine lives in a cloud session (h:dh).
17. Whether to retire the model broker by name or fold it into D1 (v2 p.38; h:cw).

## 7. Lost ideas

These were proposed once and never decided, built or rejected:
- **Credit engine:** credits influence routing only after quality, security, reliability and latency are acceptable (v2 pp.39-40).
- **Model broker:** takes `historical_success_rate` and outputs a `verifier_model` (v2 p.38).
- **Kill switch:** `JARVIS MODE: READ ONLY`, with per-agent disables (v2 p.33).
- **Voice interface:** "voice does not bypass permissions" (v2 p.35).
- **MCP hardening:** servers containerized, dependency-scanned and egress-restricted (v2 p.31).
- **Tool Gateway:** per-call budget enforcement, semantic namespaces, `credential_ref`. Retained at v3.0 p.56, then silent (v2 pp.24-31).
- **Agent optimization questions:** "Which approvals are always accepted?", and cost per successful task (v2 p.39).
- **Autonomy ladder:** including its "act in sandbox" rung (v2 pp.20-21).
- **Maintenance routine:** a weekly aggregated maintenance PR and the maintenance cadence table (v2 p.10).
- **Domain registry:** capabilities, versions, authority and health per domain OS (v3.0 p.54).
- **Decision packet:** nine fields (v3.0 p.52).
- **Suggested-task intake:** an intake queue with an explicit auto-spawn policy, and `felix organization status --since 48h` (RPT §14.1, §15.6, §15.9).
- **Deferred stages:** a decided-but-unbuilt row with a trigger for every stage a design defers (b2 E22).
- **Decision provenance:** the decisions table records the originator and whether the owner was asked (b2 E25).
- **AgentShield:** as a raise-only reader in `felix discover` (M:ecc-plugin-assessed-not-mounted).
- **Egress record:** a hash-chained egress receipt before every off-machine send, and confidentiality-aware routing (experiment G) (M:gstack-assessed-not-installed; M:commercial-radar-2026-10-10).
- **Product interrogation:** in the style of gstack's `/office-hours` (M:gstack-assessed-not-installed).
- **Prediction items:** forced-choice behaviour questions keyed to a qualified scenario (vibe §12, A7).
- **Proxy-conflict detector:** run over existing transcripts at zero tokens (vibe §8).
- **Learned-table checks:** redundancy and collapse reports (jepa §6).
- **Routing-mode console controls:** Adaptive, preferred provider with fallback, or manual (MEM rv5 coverage).

These were decided in the v3.x texts, but no reader found them carried into any later plan:
- NEED vs MOUNTED as states (v3.1 p.64).
- The capability object with `activation`, `deactivation` and per-environment authority (v3.1 p.63).
- Provider scoring on six dimensions (v3.1 p.64).
- Event-triggered runs (v3.1 p.64).
- The lifecycle eval case of the right tool "installed but not active, or active with excessive privilege" (v3.1 p.70).


## 8. Corrections and additions from the critic (2026-10-29)

A critic read this map against its sources after it was written. Its findings stand beside the sections above: where a finding corrects a row, the finding wins.

1. **The synthesis leaves out the 09-22 product positioning PDF, the one source written to answer "is the capability plane a Factory rip-off".**
   - Path: `/Users/a14808/Documents/Felix/.claude/worktrees/agent-beacon-drift-481a64/docs/reports/2026-09-22-felix-product-positioning-discussion.pdf`. It is in Chinese. None of the seven readers listed it.
   - §5 states the risk directly. If the capability plane means "task decomposition + model selection + subagent spawning + parallel execution", it is "highly conflicting", and Felix becomes a "simplified Factory".
   - §5.1 warns against a false story. Do not claim Factory has no trust; it has autonomy levels, tool policies, allow and deny lists, a sandbox and validation.
   - §5.2 is a Factory-versus-Felix table of what each should own.
   - Ideas the synthesis does not have:
     - The **Capability Contract** as the unit of the plane, with ten fields: requirement, preconditions, providers, evidence contract, authority envelope, confidence (per provider × task class × environment), cost/latency, failure modes, freshness, retirement condition.
     - Competence beliefs come only from outcomes the Trust Plane accepted.
     - "Route capabilities, not models", over a capability graph.
     - When no provider is good enough, the gap goes to acquisition (find a provider, qualify it, Trust admits or rejects it).
     - **Capability Lease = Scope + Authority + Budget + Evidence Obligation + Expiry.**
     - The team is put together per task from the obligation graph, not fixed roles.
     - North star: Verified Engineering Progress / (Human Attention + Compute).
     - The data moat: verified outcomes by provider × task class × repo × authority level.
     - The aim is a world-class Trust Plane plus a provider-agnostic Capability Plane that is strong enough, not the best coder.
     - An MVP, 10 measures (including false-block rate), and 12 open questions (§9.2).
   - The contract idea comes back three more times, and the synthesis has no "capability contract" row anywhere:
     - Report v5 (`docs/reports/2026-09-30-felix-second-engineering-systems-report-v5.pdf`): "a task-bound capability contract: need, provider, qualification evidence, lease, measured outcome, freshness, resource pool and retirement rationale".
     - h:cw line 238: "A per-task capability contract view, derived and read-only, after capability items 4 and 6".
     - The rv5 review, covered in finding 2.

2. **Spot-check mismatch: a design instruction is filed as a rejection.**
   - Row (b) "A capability registry feeding a semantic router" is marked rejected and cites MEM rv5 for "do not build a second registry".
   - The source (`~/.felix/memory/felix/audits/2026-10-01-report-v5-review/review.md:108-111`) says the opposite kind of thing: "Promote the existing catalogue, commissioning, routing and ledger rather than build a second registry. Every field of the task-bound capability contract has a partial home today. Four are missing: a task key, an outcome column, provider-level qualification, and the lease and pool objects."
   - That is a build instruction with four named gaps. The h:z rejection is real but is a different object. h:z's verdict reads "implement only after architectural changes, and not the registry"; "populate, don't build" is h:af:89's paraphrase of #58.

3. **The founder cannot judge "not a Factory rip-off" or "market plus own design" from this map.**
   - None of the roughly 120 idea-map rows says who in the market already has it. Only §4 does that, by area.
   - The thesis itself flags the crowded shape: deck slide 15's "Coordinator: plan + integrate" is what Factory Missions, Claude Code Projects and Harness Cosmos already do (thesis line 103). Yet the Execution Coordinator rows in §2(c) are presented as Felix's own.
   - The positioning PDF's description of Factory is missing: Router (quality/latency/cost), Custom Droids (per-subagent model, tool policy and autonomy), Autonomy Levels, and the Missions design (fresh agents, narrow goals, shared state, explicit validation).
   - Neighbours missing from §4:
     - From the 10-27 pitch: Tiden, TestMaze, GUILDLESS and IronBee as verification layers, and the vendors' own reviewers (CodeRabbit, Bugbot, Devin Review, Claude Code Review). Source: pitch answers "Saved for the interview" and deck sheet 6, at `git show pitch/2026-10-27:strategy/applications/deck/2026-11-speedrun-deck.html`. GitHub Agent HQ is on deck sheet 5.
     - From the radar and the strategic note: Harness/Cosmos, Amazon Bedrock AgentCore, and NVIDIA Signed Agent Skills.
     - From the beacon note (M:agent-beacon-spike-2026-10-28): Asymptote's paid tier is "policy guardrails", which is trust-plane ground, and Paradev's $11.5M seed.
   - The market map is dated 09-19/22. Nothing in the synthesis says how old it is.

4. **The join to the trust plane has no section, and the boundaries that define it are mostly dropped.**
   - The thesis §12 rejected list is cut down to three items. Left out, and each of them is a join rule:
     - "Capability decides which obligations stand" (admission is trust work);
     - "A model floor below which the work does not count" (breaks trust invariance);
     - "Receipts invalidated when a worker's model changes";
     - "Cross-family structure as a receipt condition" (it belongs on the lease);
     - "Autonomy moves exactly as far as coverage";
     - "Retiring providers keyed only on open obligations";
     - "agentId leases as the lease guarantee".
   - The thesis's plane relation is missing: capability supplies the denominator and the supply, trust supplies the numerator. Without capability Felix is "a fancy GitHub CI gate" (cpa `candidates-with-refutations.json`; thesis lines 8 and 542).
   - The capability object row in (b) drops `obligations_created` and `receipt`. KRN p.63 lists both, and they are the join. KRN p.72 adds that "every capability should have provenance, scope, activation criteria, authority, and receipts".
   - dir row 15 is left out. The lane "never touches `qualify.sh`, `obligations.sh`, `receipt.sh`". Yet I2's join, the `needs` column and derived-row task scope all live in `obligations.sh`.

5. **Missed repository design documents from August and September.** The source key lists none of these.
   - `docs/2026-08-09-capability-ledger-design.md`:
     - The founding asymmetry: "Retiring is driven by evidence. Mounting is driven by declared need."
     - Three evidence classes (fact, unconfounded, confounded), each with its own permission.
     - Randomised trials (`felix ledger --trial`), reported with their power. Not built: `lib/ledger.sh` has no "trial".
     - Time a person spends deciding is kept apart from cost.
     - Hook-only plugins are excluded from retirement.
   - `docs/2026-08-09-capability-discovery-design.md`:
     - Claude Code plugins have no permission model.
     - Static analysis "catches accidents and carelessness. It does not catch an attacker."
     - Discovery was to run on a maintenance cadence and cache by sha. That row is not in `templates/maintenance.tsv`.
     - Auto-installing low-risk finds has to be earned from a record.
     - "Discovery without the ledger only ever adds."
   - `docs/2026-09-18-ecc-against-v32.md`:
     - "routes advise, requests get answered";
     - a red/green commit pair as accepted evidence;
     - lessons get a count (the miss rate §10 needs);
     - challengers as rows for budget classes B2 and B3.
   - `docs/2026-09-16-discovery-baseline-design.md` is uncited, though its content reaches the synthesis through `lib/candidates.sh`.
   - `docs/handoff/6.md:42` holds a decision the synthesis never mentions, dated 08-12: "Exploration arm on capability mounting: not yet, revisit at 20 sessions." The trigger passed long ago (`ledger.d` has 239 files).

6. **Status error: restart moments are marked "built" (row (d)).**
   - The cited commit 945c0299 says: "Proposed, nothing built."
   - `docs/2026-09-23-restart-moments-scope.md:16-18`: the engine-behind case is only "Named", idle resume is "Recorded only", and the 500K restart is "Deferred to step 2".
   - The fix it names, `/reload-plugins`, appears nowhere in `engine/harness/hooks` or `lib`.

7. **Status error: the autonomy ladder is marked "on file, never reconciled".**
   - `docs/2026-08-14-earned-autonomy-decision.md` is a founder decision. It replaces green-only trust with an earned record that has a lag. Its §4b sets: "execution competence earnable … root authority NOT earnable", and "autonomy may increase over observed execution competence; authority over the mechanism that grants autonomy may not."
   - That decision also sets the root-of-trust kernel any capability acquisition must respect. `docs/2026-08-15-authority-that-cannot-be-earned.md` is uncited as well.

8. **Status errors and gaps in what the engine does today.**
   - "Lost idea: maintenance routine … the maintenance cadence table (v2 p.10)" is built.
     - `lib/maintenance.sh` says "the guidebook's table on p10".
     - `templates/maintenance.tsv` has the cadences, including "dead-code 7 always one aggregated cleanup PR".
     - `felix maintenance` is dispatched at `felix:6721`.
   - "Event-triggered runs … not built" is partly wrong.
     - `templates/unattended.yml` fires on `workflow_run: workflows: [gate] types: [completed]`. It is built and switched off.
     - `felix incident` and `felix repair` (`felix:6719-6720`) turn production errors and CI failures into briefs.
   - The "kill switch" lost idea partly exists: `felix quarantine`, the `FELIX_UNATTENDED` variable, and the autonomy revoke.
   - §3 leaves out `lib/intake.sh` / `felix brief`, which brief an issue with "which tool this project already decided to reach for". It also leaves out `review.sh`, `repair.sh`, `incident.sh` and `maintenance.sh`.

9. **Spot-check mismatch: the Beacon egress row in §5 shows a conflict the source has already settled.**
   - M:agent-beacon-spike-2026-10-28 says: "Beacon added no egress … The lsof egress poll matches other sessions' `npm exec` MCP servers."
   - `audits/2026-10-29-beacon-spike/run3/egress-lsof.txt` is 12 `node` sockets from other processes.
   - "PR text not updated" may still be true. I could not read PR 473 or 474: `gh` timed out.

10. **Missed: the 10-29 build exists, but only uncommitted.**
    - Worktree `/Users/a14808/Documents/Felix/.claude/worktrees/eloquent-lewin-df2160` holds:
      - a new `engine/harness/lib/answer.sh` ("a capability's output handed to a session without being asked for, and what the session did next");
      - edits to `graph.sh`, `ledger.sh`, `own.sh` and three hooks;
      - a new spec, `docs/2026-10-29-answers-delivered-spec.md` (315 lines, sections A1-L5);
      - a pending handoff, `docs/handoff/pending/20261029T203000Z-claude-answers-delivered.md`.
    - The synthesis says "Graph-query build started 10-29" and gives no location. All of this is uncommitted, so it could be lost.

11. **An unlisted contradiction: three sources define the capability plane as difficulty routing, which D1 and I4 rule out.**
    - 09-29 strategic note, p.4: "The Capability Plane allocates models, tools and compute against task uncertainty". Report v5 p.11 repeats it.
    - Report v5: "Adaptive task-difficulty routing INVESTIGATE + BENCHMARK - core Capability Plane feature".
    - 10-10 radar: "Select models/harnesses based on difficulty, cost, confidentiality, execution location, consequence".
    - Other ideas in these sources that the synthesis lacks:
      - from the strategic note: the six-part Agent Outcome Evidence Packet, and Experiments A, B and C with their falsifiers;
      - from the radar: pass/kill criteria (catch at least 70% of seeded failures the factory misses, at under 25% added cost); verifiers get read, replay and probe authority but no write; truth-engine adapters; confidentiality-aware routing.
    - Paths: `docs/reports/2026-09-29-felix-strategic-intelligence.pdf`, `docs/reports/2026-10-10-commercial-technology-radar.pdf`, `docs/reports/2026-09-30-felix-second-engineering-systems-report-v5.pdf`.

12. **Missed: the 10-27 pitch tag makes capability claims ahead of the code.**
    - The pitch says:
      - Felix "hands it to agents in short sessions with only the tools each one needs" (the lease, not built);
      - "Felix decides … who writes each test" (I5, not built);
      - "Next: the join";
      - "Its hooks already load in OpenAI's Codex in a test run";
      - Droid as a second host by Demo Day;
      - the Demo Day measurement (plain Claude Code against Felix: what Felix catches, how often it is wrong, what checking costs);
      - verdicts paid for on the customer's own model keys.
    - The synthesis does not set these outward claims against built status. Source: `git show pitch/2026-10-27:strategy/applications/2026-11-speedrun-answers.md`.

13. **Missed: the decks.**
    - Deck v4 slide 13 (`docs/decks/2026-10-19-felix-investor-deck-v4.pptx`) is the founder's current four-question form of the plane: "What does this project owe? Who supplies each, under what lease? Who checks it, other than the builder? When does a provider lose its place?" It is not the roadmap's six questions.
    - Slide 14: "AI may propose new capabilities. Felix must decide when a proposal earns institutional reality." That is provider proposals, not only obligations.
    - Deck v3 (`audits/2026-10-18-capability-plane/deck-v3.txt`) slides 13 and 17 carry the trust-first sequence and the "Key proof: verified progress per unit of human attention + compute".
    - The pitch says to upload the new speedrun deck, not v4, so open question 16 (slide 17) matters less.

14. **Smaller spot-check mismatches.**
    - Model router rejection. `lib/route.sh:14-18` says "4.9-8.6s per call … rejected on measurement, not on principle … Quality was fine". The "no key" reason is not in that header or in the router design. 4.1 s comes from the design doc's table.
    - A′ "built (0.49.31)" is sourced to h:ah. The build record is h:ag ("A′ — approved, built, deployed (#111)", 0.49.31).

15. **Uncited: the standing direction, `docs/handoff/1.md`.** The synthesis's line that everything else "only reports" is never measured against it.
    - It says: "Interfere as much as possible … A command that prints a suggestion for something it could safely have done is a defect, not caution."
    - It also says to design surfaces "drivable by something that is not a human".
    - Its stage table already marks INTENT and DISPATCH absent.
    - M:capability-plane-stagnation-2026-09-25 gives a cause the synthesis drops: "harvest-from-records planning cannot see" an unbuilt plane.
    - The 09-21 control-plane report (`docs/reports/2026-09-21-felix-autonomous-engineering-control-plane-report.pdf`) and the 09-21 usage analysis add little beyond what is already in the synthesis.

16. **Rows that matched their sources.**
    - `admit.sh`: the tier × grounding table; INFERRED never installs; high always refused; "never sandboxed" at line 46.
    - Commissioning has 14 rows. `catalog.tsv` has 16.
    - Probes have five states, and `blind` and `unknown` block.
    - dir row 17 (D1, D3), row 19 (Droid then Codex, 10-27), and rows 25, 27 and 28.
    - The replay's "$410 is fine".
    - The retire list was emptied because "it had no true positives" (h:ao:24).
    - Droid's PreToolUse matches only Edit and Read, it has no SubagentStart, and admins can set `allowManagedHooksOnly`.
    - v3.0 p.56 demotes multi-model specialists. KRN p.64 lists the six activation moments and NEED vs MOUNTED.
    - The 10-28 auto-adoption stopped all landing.
    - 16 of 80 commits touched capability libraries, with 0 lane items.
