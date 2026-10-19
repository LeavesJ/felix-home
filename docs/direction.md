# Felix: standing direction

**This file is the one current statement of what Felix is, what it is
building, in what order, and what is decided.** Where an older roadmap, build
queue, handoff section or memory note disagrees with it, this file wins. It
binds from the commit that lands it on main with the founder's yes. A copy on
a branch that has not landed is a proposal.

It is rewritten in place when direction changes. Its history is the git log,
and the documents it supersedes stay as they were. A session that changes
direction edits this file in the same pull request. Every pull request that
touches this file waits for the founder's yes, including one that only folds
in decisions he has already made, because the tick cannot tell the two apart
(§10). The land-on-green tick holds such a pull request only once contract
amendment A32 lands (`lib/green-tick.sh` treats this path as a direction
document; it is being built on `claude/direction-read-first`). Until then,
open it as a draft labelled `needs-founder`, or the tick will land it on
green.

As of: 2026-10-19. Last decisions recorded: derived rows may bind without his
per-row admission, within five bounds, with nothing armed yet (§4, row 27);
and the endgame serves founders at about level 3 of input and engineers at
about level 2, from one core (row 28).

**How a session uses it.**
1. Read this file first, then the constitution
   (`projects/felix/CLAUDE.md`).
2. Do not rebuild direction from memory notes or older roadmaps. They are
   history, and §9 says where their detail lives.
3. A founder decision dated after the "As of" line above wins over this
   file. Typically that is a pending handoff section or a line in the
   carrier's state file. The session that finds such a decision brings this
   file up to date in its own pull request.
4. This file holds no live status. §2 is a dated snapshot, and it names the
   commands that give today's numbers.

## 1. What Felix is

- **An engineering OS for other people's projects.** Felix turns intent into
  verified, shipped code and decides how that happens. It is built first,
  and best, on Claude Code, and is host-independent by design. It governs
  engineering and nothing past it: no billing, customers or support.
- **The split.** The founder owns what gets built. Felix owns how, optimally.
  "If the founder is thinking about tooling, Felix has failed at its job."
  Among documents, only direction waits for his yes: a roadmap or a
  change to one, the charter's account of what Felix is and of the split,
  and an amendment over his architecture text. His hard stops (row 4) also
  wait.
- **Two planes.** The endgame is an autonomous engineering control plane.
  The **trust plane** decides what may land and what a green verdict means.
  The **capability plane** decides what a project owes and who supplies
  each item, under what lease, checked by whom.
    - The capability plane's charter is v3.2 invariant 4: "Felix owns what
      must become true. The host owns how to make it true."
    - Its seven invariants are in the 2026-10-18 brief, §4 (I1-I7).
- **The architecture.** v3.2 (2026-09-02) and its conformance amendments
  govern. No alternative kernel is derived.
    - No model sits on the enforcing path, and model output only narrows.
    - No receipt or merge blocker reads which model did the work.
    - The engine stays bash, rows first.
- **Build first.** Commercialisation is an outcome of quality, not the
  purpose. There is no pricing, outreach or demand track.
- **Do not narrow Felix.** Take outside guides' facts and experiments, never
  their account of Felix's scope (founder, 2026-10-10).

## 2. Where it stands, honestly

A snapshot read on 2026-10-19 at about 07:45Z. For today's numbers, run
`felix land --prs`, `felix inventory` and `git log origin/main`, and read
the lander ledger (`~/.felix/memory/felix/land/ledger.tsv`) and the carrier
state (`~/.felix/memory/felix/audits/2026-10-08-carrier/state.md`).

**Felix is a strong "no" and a weak "yes".** What runs with nobody present
is the refusals:
- the Stop hold;
- the gate;
- the deny rows;
- receipts bound to the tree;
- the merge boundary (#350);
- session-start context.

Almost nothing that acts runs without the founder. The founder put it this
way on 10-19: "A lot of the ideas we have rn are good but very premature bc
none of them rly work without my involvement." The measurements agree.

| Loop | Measured | What it means |
|---|---|---|
| Landing | Land on green has been live since 10-18. Its ledger has 24 rows and **0 merges**: 7 skipped as drafts, 5 "no checkout holds the gated head", 4 conflicting with main, 3 labelled needs-founder, 2 with CI still running, and one each refused for no receipt, gh auth failed, and project unresolved. | Every PR that has landed went through a session or the founder. |
| Admission | 22 obligation candidates proposed (Elenchus 7, Veldra 15), **0 admitted**. Waiting on the founder since 09-26. | The trust plane judges only what someone listed by hand: felix-home has two obligations, and each other governed project has the one templated `lifecycle_wired` row. |
| Founder leakage | 31% of founder turns in the episode pilot, and 36-50% in batch 2, depending on the counting rule. | These are turns where the founder did Felix's job. |
| Routing | About 2% precision, with 106 declines recorded (measured 10-09). | Suggestions mostly miss. |
| Capability plane | From 09-25 to 10-19, 16 of 80 main commits touched capability libraries: 2 features, 0 lane items. | It has no measured number yet. |
| Noticing | The capability gap was raised by the founder on 09-25 and again on 10-18. | Felix did not notice it. |

- **Landed on the trust track.** Phase 0b steps 2 to 5:
    - PR #350, the merge boundary;
    - PR #358, `land.tsv`;
    - PR #397, `felix inventory`;
    - PR #449, the stuck-PR page.

  Land on green (#442, with A30 and A31) and gate friction A, A3, B and C
  are also in.
- **Main and step 6.** Main is at 0.49.300 (50601023). Step 6, the lost-work
  page, is open as #450.

## 3. How progress is judged

- **The binding objective** is founder interruptions per session, declared
  2026-08-12 (`docs/handoff/1.md`). It is deliberately not gate pass rate.
- **Felix's reading of the 10-19 remark.** This is Felix's call, because it is
  about how Felix judges its own work:
    - Rank work by whether it removes the founder from a loop he is in
      **today**.
    - A design counts as progress once it has run unattended, once, on two
      ecosystems. Until then it is a design on file (§7).
    - Report founder leakage and the loop numbers below, not features
      shipped.
    - Say plainly when a proposal still needs him.
- **The three loops he is in today,** each with the number that says
  whether it closed:
    1. **Landing.** The count of lander merges against ledger rows. Today it
        is 0 of 24.
    2. **Admission.** Admitted obligations against those proposed. Today it is
        0 of 22. Felix cannot close this loop alone, because admission is the
        founder's act.
        - On 10-19 he said yes to derived rows binding without his
          per-row admission, within bounds (row 27). Nothing is armed yet,
          and §5 lists what must be true first.
    3. **Direction currency.** Whether a fresh session starts from this file
        instead of rebuilding direction from memory notes.
        - On main, the session-start hook does not name this file yet.
        - The engine change that does, with amendment A32 beside it, is
          built on `claude/direction-read-first` as a draft. Its record and
          gate are owed at the carrier's slot.
- **The thesis's definition of autonomy,** engineering leakage per objective
  (brief §5), is a proposal. Whether it replaces or refines the 08-12
  objective is open (§6).

## 4. Decided and binding

The founder's decisions still in force, oldest first. Where a row was later
changed, the row states its current form.

| # | Date | Decision | Source |
|---|---|---|---|
| 1 | 08-10 | The split: the founder owns what, Felix owns how. | constitution, The split |
| 2 | 08-18 | Concurrency ladder: #2, hedging, #31, rung 3; rung 4 waits on a measured peer-verification hit rate. | memory concurrency-ladder-sequencing |
| 3 | 09-03 | v3.2 plus its conformance amendments govern, strictly. | memory felix-v32-amendments-are-binding |
| 4 | 09-13 | Felix merges its own PRs on green CI and deploys after. The founder's hard stops: commission and consent grants, `FELIX_ALLOW_RED`, risk=high installs, credentials or live keys, irreversible external writes, a risk.tsv escape channel firing, and publishing to the public repository. Of these stops, the tick holds drafts, the three hold labels and direction paths, and `felix merge` refuses escape channels that fire on main's engine and a stale commission. Any other one is held by hand: open it as a draft labelled `needs-founder`. | memory felix-merges-its-own-prs |
| 5 | 09-18 | Endgame: an autonomous engineering control plane with a Capability Plane and a Trust Plane. | `docs/2026-09-19-direction-decisions.md` |
| 6 | 09-19 | The engine stays bash, rows first. No new runtime on the enforcing path. | direction-decisions §1 |
| 7 | 09-19 | Control plane v0 is "the lease and its record", not a schedule. | direction-decisions §3 |
| 8 | 09-22 | Felix is a product for other people's projects; Claude Code first; host-independent; engineering only. | constitution |
| 9 | 09-22 | Record every declined suggestion with `felix route --ack`. | memory record-every-decline |
| 10 | 09-23 | Build first; the roadmap v1 market track is withdrawn. | `docs/2026-09-23-roadmap.md` |
| 11 | 09-23 | Among documents, only direction waits for his yes. Engineering merges on green, except the hard stops in row 4. | constitution |
| 12 | 09-23 | Stealth in the middle: a session hears from Felix at its start and end only, with one narrow exception. | constitution |
| 13 | 09-24 | F1: landing machinery (Phase 0b) comes before the qualified judge, and the judge pin comes before unattended arming. | roadmap Phase 0b, §7 |
| 14 | 09-24 | Lost-work order: inventory is step 4, the stuck-PR page step 5, and the lost-work page step 6. The page is read-only and replaces the monitor; consent stays his GitHub merge. | roadmap Phase 0b |
| 15 | 09-25 | A capability lane runs beside every phase at about one session in four. "The share is his; the lane's items and their order are Felix's." It never touches `qualify.sh`, `obligations.sh`, `receipt.sh` or the landing actor's files. | roadmap §3 |
| 16 | 10-01 | F2: once landing is armed it may run overnight with the Mac kept awake. A sleeping Mac lands nothing. | roadmap §7 |
| 17 | 10-01 | The 0cw rulings (`docs/handoff/0cw.md`). <br>• **D1, both planes:** the host picks its model above Felix's floor, and Felix never builds a model minimizer. <br>• **D2:** engineering only. <br>• **D3:** one attended dispatch tick before March, on his own API key under a dollar cap. <br>• **Models:** every Workflow stage names its model and effort. <br>• **Fix intake:** red-on-main, false-block or step-blocker fixes get a slot; the rest are batched weekly; no new engine branch while more than 10 engine PRs are open. <br>• **Claims:** no "independent acceptance" in outside text before #350 and the pin. <br>• **Plugin cache:** belongs to the carrier. <br>• **The console:** read-only. <br>• **The floor:** advisory and raise-only. | 0cw |
| 18 | 10-01 | Corpus terms: lease A with no shell, the sealed commitment kept private, and a weak result investigated rather than narrowed on. | 0cw, roadmap §5 as amended |
| 19 | 10-02 | Codex read-only starts now on his OpenAI credit. The Codex adapter is a lane item for about December, after arming and the pin. | roadmap §3 |
| 20 | 10-09 | The interface is built slowly as OS-style surfaces, read-only first, with chat later. | pending 20261009T234930Z |
| 21 | 10-10 | The seeded corpus gains a different-family arm. In Phase 2, a moved input stales only the receipts that depend on it. | memory commercial-radar-2026-10-10 |
| 22 | 10-12 | Gate friction is row 0 of the build queue. | carrier state |
| 23 | 10-12 | No native `permissions.deny` rules for secrets. Do not re-propose. | memory no-native-deny-rules |
| 24 | 10-15 | Land on green. Live since 10-18. A launchd tick runs `felix merge` with nobody present on an open PR only if it meets all of these: it is not a draft; it carries no label named `felix:hold`, `felix:founder` or `needs-founder` (other labels hold nothing); it is not cross-repository and does not conflict; it touches no `projects/*/CLAUDE.md` or `docs/*roadmap*` path; CI's gate run passed on the exact head (C9); and a home worktree holds that branch at that head. Judge-changing PRs are included. These are the main conditions, not all of them. `felix merge` must then pass in that worktree, which needs a green `felix gate` receipt there for this exact tree (a scratch clone's receipt is invisible to it). The contract also holds a PR whose base is not main (A12), whose head branch heads another open PR (A19), or whose paths are not plain ASCII (A9). The tick merges nothing while paused or while a deploy is owed or has just run (G2, G3, A11), lands one PR per tick, and lands nothing while the Mac sleeps. | `docs/2026-10-15-land-on-green-contract.md` |
| 25 | 10-19 | "Keep the 09-25 lane: build intake now, and gate capability authority (dispatch, leases, floor) on the trust milestones." | pending 20261019T071844Z |
| 26 | 10-19 | Felix refuses pattern kills with a deny row (his answer: "Refuse them"). He merges it himself. Nothing holds it mechanically: adding a row to `deny.tsv` fires no escape channel (`lib/escape.sh` treats adding as free). Landing it also changes a commission table (`deny.tsv` is in `FELIX_COMMISSION_TABLES`), so later merges wait until he re-stamps the commission. Open it as a draft labelled `needs-founder`. | carrier state |
| 27 | 10-19 | Derived rows may bind without his per-row admission (thesis Decision 2(b), intent design §11c, and §11d's task-blocking half). His words: "Yes to derived rows binding without my admission, with your five bounds." The bounds: (1) task scope only, never a release and never an escape channel; (2) witness-backed rows only, never a single model finding (`lib/candidates.sh` keeps refusing that); (3) the row's checker has qualified on seeded mutations; (4) nothing is armed before control 7 and the judge pin (row 25); (5) visibly Felix's: a Felix-authored commit he can tell from his, a person clears a false block with a dated exception, only people loosen, and a row retires after false blocks. Felix uses the grant first for instances of class rules he has admitted; a model-proposed candidate stays advisory until that path has run. | pending 20261019T071844Z |
| 28 | 10-19 | Two users share one Felix core. **Founders** turn a novel idea into something real; their input should be around level 3 of the 10-19 ladder (the idea plus its stakes: who uses it, how mature, what must never happen, money and time). Below level 3, Felix re-derives the level 3 to 6 elements (stakes, a product brief, an engineering plan, a design contract) as best it can and, before building, asks the founder questions and offers options that may inspire them. Maturity (prototype, private beta, public, production) is the element the rest keys on, as the research also found, so it is established first; re-deriving the others is harder than it sounds. **Engineers** want reliability: one shot, so they do not have to come back; their input should be around level 2 (the issue text), and level 1, a one-line wish, must still be handled. The engineers are the corporate users. Concurrency and parallelism matter more to them than to founders, and the first outside deployment is likely the subcontractor test in §6, so keep that weight in view. His words: "for founder <L3 we're able to at least to the best of our ability rederive the L3-L6 elements therefore before building ask them some questions (even inspire them)"; "for engineers it's more about reliability and whether not we really one shot what they request for they don't have to come back"; "the 'corporate' = 'engineers' here"; "my idea of 'rederivation' sounds a lot simpler than it acutally is but...again one ward we're emphasizing, from the resaerch as well, 'maturity'". | pending 20261019T071844Z |

Two things follow from rows 13, 24 and 25 together:
- Landing with nobody present is governed by row 24, and it is live.
- Capability acts with nobody present (dispatch, a lease, a retirement) wait
  on the step 15 judge pin and the arming sitting.

## 5. The build order now

Order, not status. Read status with the commands in §2. Roadmap and 0cw dates
were set before row 0 and land on green were inserted. Treat them as
estimates.

**Before taking an item, find its owner.** Read the carrier state's newest
lines and its Order table, and run ListAgents. A session takes the first item
nobody owns. On 10-19, step 6 (#450) belonged to its own session, D to the
row-0 session, and the pattern-kill row to the carrier. The carrier gives the
next version slot to the highest-placed branch that is gate-ready, so items
can land out of this order.

**The main sequence:**
1. **Phase 0b step 6, the lost-work page** (#450). It completes console v0:
   the inventory, the stuck-PR page and the lost-work page.
2. **Gate friction D** (`tests/run -j`), row 0.
3. **The pattern-kill deny row** (row 26): a draft labelled
   `needs-founder`, which the founder merges.
4. **Leftovers:**
    - slot 12 (`claude/project-writes-refuse-nonregular`);
    - PR #425, now conflicting with main;
    - drafts #365 and #360;
    - a one-line amendment to the land-on-green contract for PRs gated
      only in a scratch clone;
    - `claude/direction-read-first`: the session-start hook names this file
      first, and contract amendment A32 makes the tick hold a pull request
      that touches it. It is a draft; its record and gate are owed at the
      carrier's slot.
5. **The trust track, in roadmap order.**
    - First, 0cw trust item 2: merge refuses a receipt that skipped checks.
      It must land before step 8. Receipts record skipped checks in field
      5, but no landing of the refusal is recorded. Land on green narrows
      the gap by requiring green CI on the exact head (rule C9).
        - It starts once 10 or fewer engine PRs are open.
        - Its spec and blind assertions are in the memory root,
          `audits/2026-10-01-report-v5-review/specs/skipped-receipt/`.
    - Then steps 7 to 18, in the roadmap's order:
        - 7: a readiness status, and the closing-notice line moved here
          from step 5;
        - 8: the actor's core, in shadow;
        - 9: restart step 1a;
        - 10: attended landing;
        - 11: version, `red.tsv` and manifest written at landing, armed;
        - 12: post-deploy verify and full rollback;
        - 13: the trust base, now only for an actor that re-gates in its
          own clone (§8, and the land-on-green contract's departure);
        - 14: #304, then the judge-identity epoch;
        - 15: the judge pinned outside the change it judges;
        - 16: the founder's stamps leave the tracked tree;
        - 17: the scheduler and its arming brakes;
        - 18: the deny rows on raw merges and on the grant, in the
          founder's lane.
    - Then at least 10 shadow agreements, 5 clean attended landings, one
      Elenchus shadow run, and the founder's arming sitting.
6. **Phase 1, the qualified judge.**
    - `capabilities_needed`, then control 7, then the qualified-judge join.
      No row is armed before control 7 and the pin.
    - Also `coverage.tsv` and restart step 1b.
7. **Phases 2, 3 and 4.**
    - Phase 2: stale receipts, the ledger in the repository, and the private
      whole-life replay.
    - Phase 3: finals, Dec 7-18, engine only.
    - Phase 4: the public replay, the merge-point check, and the harvest rows
      before ECC hooks go off.

**Beside it, the capability lane** at about one session in four. 0cw
reserves one standing session for it. A session is a lane session when the
founder or the carrier starts it as one; any other session takes the main
sequence. A lane session counts only if it lands engine code or produces a
sealed, measured number. The order is Felix's call:
1. Workflow stage checks. This is a practice for every session, not a lane
   session's deliverable. Until Claude Code 2.1.301 or later is installed, a
   green Workflow run is trusted only after each stage's return and artifact
   are checked, because on earlier builds an agent can skip its step while
   the run reports success. Installed builds were below 2.1.301 on 10-19.
2. The #417 mods round, extended with Q9-Q14. Its record is
   `audits/2026-10-19-mods-round/` in the memory root, and its report is a
   pending handoff section.
3. The seeded-omission corpus, with second-family and strongest-host arms,
   once the founder sets its ceiling.
4. Codex read-only, as a second-family author.
5. The dry-run lease.
6. The retire re-key.
7. The outcome record.
8. The D3 attended tick.
9. The replay, as approved.
10. The advisory floor.
11. The Codex adapter, about December, after arming and the judge pin
    (row 19; roadmap §3 item 5).

- **Need side.** Items 1 to 4, plus obligation intake and admission, wait on
  no trust milestone. Item 3 waits on the founder's corpus ceiling, and
  admission is his act. Item 4 needs nothing more from him: its scripted
  runs use the Codex login he made with his API key on 10-02
  (`CODEX_HOME=~/.felix-codex`). Item 1 and obligation intake need nothing
  from him.
- **A lane session's first item.** Item 1 is a practice and item 2 has run,
  so a lane session takes the first of these that nobody owns: obligation
  intake (thesis I1 and I2: standing, grounded needs with their
  denominator, and admission drafts for the founder), then item 4, then
  item 3 once its ceiling is set.
- **Authority side.** Items 5 to 10 keep the trust gates set out in row 25.
- **Before row 27 arms anything.** These were found on 10-19, after his
  yes, and each is a build, not a new decision:
    - Task scope is not built. Today one failing TASK_BLOCKING row fails the
      whole obligations gate (`felix` obligations section), so it would hold
      every pull request on the project. A derived row must hold only a
      change that touches the surfaces its grounds name.
    - The admission line is a convention. Adding a row to
      `obligations.tsv` fires no escape channel, so a blocking addition must
      be made to escape before "visibly Felix's" means anything.
    - Exceptions are read only for felix-home. A product project's tables
      live in felix-home, so its owner has no clearance path yet.
    - Each class gets a shadow run first: would-holds logged with the gate
      unaffected, under a bound a person sets (or a trust-base default),
      never the proposer. A shadow bounds false blocks only on the projects
      it ran on, so an instance binds on a project only after that
      project's own window stays under the bound.
    - A change must not blind its own hold. A row is read at the merge base
      and at the head: a row ACTIVE at base keeps holding unless a probe at
      head reads empty with a witness, and "could not look" after ACTIVE
      reads UNKNOWN and holds. A change that turns a row from SATISFIED to
      not SATISFIED is held wherever it edits; only rows already failing at
      base are limited to the surfaces a change touches.
    - Additions to the tables that decide whether a blocking class applies
      (`probes.tsv`, the detection patterns) must escape, since one added
      probe could retire a hold.
    - Code that weakens the derivation lands on green today, because row 24
      includes judge-changing pull requests. Before anything arms, a pull
      request touching the class table or the derivation, binding,
      detection or obligations code must be held for a person. That amends
      row 24, so it is his decision, asked when the build reaches it.
    - A product project's exceptions open only after the boundary reads the
      home's diff and roadmap step 18's deny rows exist; earlier, an
      exception would be a grant a session can give itself.
    - The land ledger names which obligation failed a gate, so held merges
      can be traced to derived rows.
    - The review behind this list is in the memory root,
      `audits/2026-10-19-intent-and-vibe-coding/row27-and-ladder-review.json`.

**Not before March:** `felix dispatch` beyond the one tick, and leases with
real authority. Also deferred:
- discovery schedules and budgets;
- the Docker sandbox;
- DSSE receipts;
- retiring the router;
- team concurrency;
- a Factory Droid adapter;
- outreach and pricing.

**Owed measurements.** None of these has a slot of its own. Each runs when
its precondition holds.
- The after-measure of hold-once and `felix cost`, now due.
- Gate time on the 48 GB laptop: pre-A main against A+A3, then B and C.
- The handoff fold: 40 pending sections wait.
- Two zero-token counts for row 27, before any build: how many row
  admissions one class admission would replace across the governed
  projects (the 22 candidates name 22 different properties), and
  `engine_deployed`'s gate failures by cause (it failed this file's own
  gate on 10-19 because 0.49.301 was not yet deployed).

## 6. Open, waiting on the founder

Nothing in §4 is asked or re-proposed again. Each item below is asked once,
when a build step reaches it or in the closing report that first raises it,
and not again until he raises it, unless its line names a later moment.

**Decisions:**
- Admit or refuse the 22 candidates (Elenchus 7, Veldra 15).
- Whether the thesis's leakage-per-objective definition replaces or refines
  the 08-12 objective.
- The aim he raised on 10-19: rely on Felix to build production-ready work
  and PRs from a few sentences of scope, with recursive improvement and
  adaptation. The design is on file (§7). Its §11 asks eight decisions,
  each with a recommended answer. The first is how his words become binding:
  through a terminal command that a session cannot run for him.
- Whether Felix must also produce engineering for someone who will not own
  or understand the code. Row 28 names founders and engineers, both owners;
  the non-owner case was not raised. The vibe-coding brief's §12 designs the
  test that separates the two. Ask only if a build step reaches it.
- The interface proposals of 10-09 (data contract first, unknown is not
  zero, no shell before about three surfaces, read-only first, two
  audiences).
- Whether the console, a chat or a per-function toggle should ever act.
- Which Felix functions become user toggles.
- Whether the independence gate check, which enforces with 4 of 6
  controls, is grandfathered under amendments §2.1.
- Whether deny row 134 should also cover `git config remote.*`, and
  confirming the restored origin URL.

**Consents:**
- The corpus spending ceiling: $96-349 for one corpus at 3 runs, or $172-632
  with the replication. Lane item 3 (the corpus) waits on it. It was asked
  in the 10-18 brief; ask again only when the corpus is about to run. He
  confirmed that on 10-19 ("we'll talk about it when that day arrives").
- The API key for the D3 tick, and its spend limit. Ask only when the tick is
  near.

**His acts:**
- Merge the pattern-kill deny-row PR (row 26).
- Merge Elenchus #29.
- Lift the `spawn_task` chip-freeze deny row.
- Re-stamp the commission after any commission-table change.
- Run `felix commission` in the six other projects.
- Fill the three held commission rows.
- The arming sitting.
- About ten minutes at the Code tab for #417's Q8 (attended Desktop). The
  round's 2.1.299-2.1.301 arms rerun once the desktop app updates itself
  past 2.1.301, with no download.
- Widen the GitHub token scope, so that the Actions-budget row reads.

**His documents:**
- Deck v4 slide 17 still says "Current build focus: Trust Plane MVP". The
  2026-10-18 brief's §9 has wording for it.
- The constitution's invariant-2 wording and its library count.
- The nine CLAUDE.md edits proposed by the 10-18 commission audit.
- Adding an installation guide to the roadmap.

**Boundaries he set:**
- The TSMC-subcontractor test is approved in principle only, and egress
  control comes first.
- The input-rewriting floor is declined. The 10-19 mods round kept it
  declined; re-raise it only with new measured evidence.
- Never make felix-home public. Each bring-forward to LeavesJ/Felix needs his
  yes.

## 7. Designs on file, not yet build targets

A design here is not a commitment. It becomes a build target in two cases:
- its first slice is placed in §5 by a decision recorded in §4;
- it is a lane item, whose order is Felix's call.

| Design | What it says | Status |
|---|---|---|
| `docs/2026-10-18-capability-plane-thesis.md` | The capability plane's charter (v3.2 invariant 4), seven invariants I1-I7, the anti-slop contract, and autonomy as leakage per objective. | Decided parts are row 25 and the lane order. The rest is on file. |
| `docs/2026-10-19-intent-to-build-design.md` | How Felix turns a few sentences of scope into an admitted, checkable build, and improves its own tables. Felix is deterministic about the frame; models write the content as typed answers. | On file. Its first slice, situations owed (report-only, with admission drafts), is proposed as a lane intake item. Its §11 lists eight founder decisions, each with a recommended answer. §11c, and §11d's task-blocking half, are decided by row 27. Row 28 moves §11b's questions before building for a founder below level 3. The rest are open. |
| `docs/2026-10-19-ai-engineering-vs-vibe-coding.md` | What separates AI-assisted engineering from vibe coding: what the work is held to, not who types it. It sets out a full answer part by part, its limits, the probable partial answer with the measurement that would show it is enough, and what makes the capability plane more than dispatch. | On file. Research, not direction. Its zero-token pre-checks (proxy-conflict signals over transcripts, miss-to-layer classification of coded leakage turns) are candidate lane items. |
| Reflection triggers (memory, 08-18) | Felix questions its inputs but not its method; it needs enumerated trigger moments. | Open. |
| `docs/2026-09-23-restart-moments-scope.md` | Restart moments. | Step 1a is on the trust track and 1b in Phase 1. Step 2 waits on the handoff repair. |

## 8. No longer binding

Older text still says some of these. Where it does, this file and §4 govern.

| Was | Replaced by |
|---|---|
| "Felix is Phase 1 of the guidebook and nothing past it" (08-10) | Row 8, a product for other people's projects (09-22) |
| Roadmap v1's outside-user and outreach track | Row 10, build first (09-23) |
| F2 (a): nothing lands while the Mac sleeps, to be revisited in Phase 4 (09-24) | Row 16 (10-01) |
| "Before arming, nothing lands unattended at any hour" (roadmap Phase 0b), and "Nothing lands unattended before the pin" (0cw line 126) | Row 24, land on green (10-15). Unattended *capability* authority still waits on the pin and arming (row 25). |
| Roadmap step 13: "a change to the code that judges never lands with nobody present" | Land on green lands judge-changing PRs. The departure is recorded in its contract. |
| "If recall does not beat the control, narrow to the obligations people name" (roadmap §5 original, 0cw item 3, `README.md` lines 410-415) | Roadmap §5 as amended 10-01: investigate, do not narrow |
| The 0cw capability-lane order (host measurement, replay second, ...) and the README's "three things come first" | The 10-19 lane order (§5) |
| Report v5 review build order (10-01) | 0cw, then the 10-19 lane order |
| Deck v3's "finish Trust Plane MVP before Capability work", and trust-first as the original decision (10-18) | Row 25 (10-19). Deck v4 slide 13 matches; slide 17 does not yet. |
| Roadmap step 5's "one line in the session's closing notice" | The line moved to step 7 (stuck-PR spec, 10-13) |
| Roadmap step 7's "`felix:hold` as the only hold" | Amendment A30: `felix:hold`, `felix:founder` or `needs-founder`, in any case, until step 7 is built |
| Constitution: "the monitor stays as the deeper page" | Step 6: `felix monitor` rebuilt as the lost-work page over the inventory |
| Memory felix-is-a-commercial-product: dispatch February at the earliest, the corpus in Phase 1, no Phase 0b | The roadmap as amended through 10-02, and this file |
| Memory capability-plane-stagnation: the corpus is the lane's first item | It is third in the 10-19 order |
| Memory mods-round-addendum-417: "NOT run yet", arms on 2.1.286, the Q4 premise | Run 10-19 on 2.1.293, 2.1.295 and 2.1.296, and reported in a pending section. 2.1.286 is gone, and Q4 is stale from 2.1.300. |
| Roadmap §3's and 0cw's lane item numbers (corpus 1, retire list 2, dry run 3, Codex 4, adapter 5) | The 10-19 numbering in §5. "Lane item N" means §5's list from 10-19 on. |
| 0cw capability item 9, the task-scoped checkpoint | Waits on its own trigger (the replay keeping escalation or adaptive routing, or M2's adaptive transition). It is not in the 10-19 order. |
| `docs/handoff/2.md`: Felix "cannot plan work from scratch" (08-11) | Still true of dispatch. `felix shape`, `felix brief` and the red-tier deny rows exist since. |

**Stale text, to be fixed in the next fold and README pass:**
- 0cw lines 164-168, 333-334 and 345-346 ("Before arming, nothing lands
  unattended.").
- The roadmap: step 4's "being built now", step 5, step 10's date, the
  arming date (Phase 0b's "Then" line and §6, "Oct 27-Nov 2"), §2's
  in-flight list, §6's "schedule the memory backup", and §7's 09-24 line
  "nothing lands unattended while it is judged by its own checkers".
- `README.md` lines 409-420.
- The constitution's "the monitor stays as the deeper page" (in the
  stealth paragraph) and its "forty-one sourced libraries".
- HANDOFF.md's "Current state", which is 0di of 10-01.

## 9. Where the detail lives

| Topic | File |
|---|---|
| The charter and the split | `projects/felix/CLAUDE.md` |
| Phases, steps, effort and signals | `docs/2026-09-23-roadmap.md`, read through §4 and §8 of this file |
| The 10-01 rulings and lane item detail | `docs/handoff/0cw.md` |
| The capability plane | `docs/2026-10-18-capability-plane-thesis.md`, with evidence in the memory root, `audits/2026-10-18-capability-plane/` |
| Landing with nobody present | `docs/2026-10-15-land-on-green-contract.md` |
| Gate friction | `docs/2026-10-12-gate-friction-design.md` and contracts A to C |
| The queue as it moves | The carrier state, `~/.felix/memory/felix/audits/2026-10-08-carrier/state.md` |
| Recent sessions' decisions | `docs/handoff/pending/`, newest first, folded into `HANDOFF.md` |
| Founder leakage | `docs/2026-09-23-episode-pilot.md`, `docs/2026-09-23-episode-batch-2.md` |
| Why the engine is bash | `docs/2026-09-19-direction-decisions.md` §1 |

## 10. How this file stays current

- **Who edits it.** A pull request that changes direction edits this file
  in the same pull request. Every pull request that touches this file waits
  for the founder's yes, including a fold of decisions he has already made.
  The constitution's rule that records merge on green covers pending
  sections, not this file.
- **Founder decisions made in conversation.** These are recorded in a pending
  section first, as now. That section merges on green, and the decision
  binds from it (point 3 above), so the fold waiting for his yes delays
  nothing. The next session that touches direction folds them in here and
  moves the "As of" line.
- **Live state stays out.** Steps landing, PR numbers and versions are read
  by command. That way an engineering PR never needs to touch this file,
  and never waits for a yes because of it.
- **Designs reach the build order only through this file.** The
  intent-to-build design and the vibe-coding brief are on file (§7). A slice
  of either enters §5 in one of two ways: a founder decision recorded in §4,
  or a lane item placed by Felix under row 15. A design on file is never
  placed by itself.
- **Pointers to this file.**
    - `MEMORY.md` names it on its first line.
    - The constitution names it in "The split", beside the list of what
      waits for his yes. That is a one-line edit to the charter, so it waits
      on the same yes as this file.
    - The session-start hook names it first once
      `claude/direction-read-first` lands (§3).
