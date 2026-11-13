# Felix: standing direction

**This file is the one current statement of what Felix is, what it is
building, in what order, and what is decided.** Where an older roadmap, build
queue, handoff section or memory note disagrees with it, this file wins. It
binds from the commit that lands it on main with the founder's yes. A copy on
a branch that has not landed is a proposal.

It is rewritten in place when direction changes; its history is the git log,
and the documents it supersedes stay as they were. A session that changes
direction edits this file in the same pull request. Every pull request that
touches it waits for the founder's yes, a fold of decisions already made
included, because the tick cannot tell the two apart (§10). The tick holds
such a pull request only once amendment A32 lands (draft #452,
`claude/direction-read-first`). Until then, open it as a draft labelled
`needs-founder`, or the tick will land it on green.

As of: 2026-11-07T05:00Z: rows 42 to 51, the decisions of the trust-plane
revisit (11-06 and 11-07), its design made final, and trust rework placed
first. A pending section dated later still wins (point 3).
Before them: row 41 (11-06: load is managed, not capped), the refusal of
slice 0's limits (row 40), the trust-plane answers (rows 36 to 40), what Felix
is for a team and the lane's share (10-29, rows 34, 15, 20 and 28), and its
first slices (row 35).

**How a session uses it.**
1. Read this file first, then the constitution (`projects/felix/CLAUDE.md`).
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
  checked, shipped code and decides how that happens; row 36 says what
  "checked" may claim. It is built first, and best, on Claude Code, and is
  host-independent by design. It governs engineering and nothing past it: no
  billing, customers or support.
- **For a team, the independent manager** (row 34). Felix is the engineering
  manager a team's agents report to, whoever made them, and the senior
  manager over its whole pipeline. Enterprise comes first; an edition for
  founders and others without an engineering team is derived from it (row 28).
- **The split.** The founder owns what gets built. Felix owns how, optimally.
  "If the founder is thinking about tooling, Felix has failed at its job."
  Only direction waits for the founder's yes among documents (a roadmap or a
  change to one, the charter's account of what Felix is and of the split,
  and an amendment over the founder's architecture text), as do row 4's stops.
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
  purpose. Beside it runs only the narrow commercial track in row 10:
  fundraising applications, one paid pilot contract and up to four design
  partners, with no broad outreach and no price page.
- **Do not narrow Felix.** Take outside guides' facts and experiments, never
  their account of Felix's scope (founder, 2026-10-10).

## 2. Where it stands, honestly

A snapshot read on 2026-10-19 at about 07:45Z; landing and the audit were
read again on 2026-10-27. For today's numbers, run `felix land --prs`,
`felix inventory` and `git log origin/main`, and read the lander ledger
(`~/.felix/memory/felix/land/ledger.tsv`) and the carrier state
(`~/.felix/memory/felix/audits/2026-10-08-carrier/state.md`).

**Felix is a strong "no" and a weak "yes".** What runs with nobody present
is the refusals: the Stop hold, the gate, the deny rows, receipts bound to
the tree, the merge boundary (#350) and session-start context.

Almost nothing that acts runs without the founder. The founder put it this
way on 10-19: "A lot of the ideas we have rn are good but very premature bc
none of them rly work without my involvement." The measurements agree.

| Loop | Measured | What it means |
|---|---|---|
| Landing | Land on green has been live since 10-18. On 10-19 its ledger had 24 rows and 0 merges. By 10-27 it had 95 rows and **5 merges** (#451, #454, #456, #457, #460), half of the 10 PRs main took from 10-19 to 10-23. No engineering PR landed after #460 (10-23) through 10-27. | The tick lands with nobody present once a session has gated the branch in a home worktree. A session still has to do that step. |
| Audit (10-23/24) | 96 defects confirmed in 23 batches: 21 high, 44 medium, 31 low (`docs/2026-10-24-audit-register.md`). | Many were silent stalls or verdicts that claimed more than they checked. They are being fixed batch by batch (§5). |
| Admission | 22 obligation candidates proposed (Elenchus 7, Veldra 15), **0 admitted**. Waiting on the founder since 09-26. | The trust plane judges only what someone listed by hand: felix-home has two obligations, and each other governed project has the one templated `lifecycle_wired` row. |
| Founder leakage | 31% of founder turns in the episode pilot, and 36-50% in batch 2, depending on the counting rule. | These are turns where the founder did Felix's job. |
| Routing | About 2% precision, with 106 declines recorded (measured 10-09). | Suggestions mostly miss. |
| Capability plane | From 09-25 to 10-19, 16 of 80 main commits touched capability libraries: 2 features, 0 lane items. | It has no measured number yet. |
| Noticing | The capability gap was raised by the founder on 09-25 and again on 10-18. | Felix did not notice it. |

## 3. How progress is judged

- **The binding objective** is founder interruptions per session, declared
  2026-08-12 (`docs/handoff/1.md`). It is deliberately not gate pass rate.
- **Felix's reading of the 10-19 remark.** This is Felix's call, because it is
  about how Felix judges its own work:
    - Rank work by whether it removes the founder from a loop he is in
      **today**.
    - A design counts as progress once it has run unattended, once, on two
      ecosystems. Until then it is a design on file (§7).
    - Report founder leakage and the loop numbers below, not features shipped.
    - Say plainly when a proposal still needs him.
- **The three loops he is in today,** each with the number that says
  whether it closed:
    1. **Landing.** The count of lander merges against ledger rows: 0 of 24
        on 10-19, and 5 of 95 on 10-27.
    2. **Admission.** Admitted obligations against those proposed. Today it is
        0 of 22. Felix cannot close this loop alone, because admission is the
        founder's act.
        - Row 27 (10-19) lets derived rows bind without per-row admission,
          within bounds. Nothing is armed yet; §5 lists what must be true.
    3. **Direction currency.** Whether a fresh session starts from this file
        instead of rebuilding direction from memory notes. On main, the
        session-start hook does not name this file yet (draft #452, A32).
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
| 4 | 09-13, changed 10-31 | Felix merges its own PRs on green CI and deploys after. The founder's hard stops: commission and consent grants, `FELIX_ALLOW_RED`, risk=high installs, credentials or live keys, irreversible external writes, a risk.tsv escape channel firing, and publishing to the public repository; from 10-31, a change to the trust-plane checker's judge artifacts until roadmap step 15 pins the judge outside every change it judges (row 38); and, from 10-31 by Felix's reading of their start (the answers name none), a high-stakes build's limit no automatic check can show harmless (row 39) and a new high-stakes feature's inherited known main defect in a shared function the founder has not accepted (row 40). Of these stops, the tick holds drafts, the three hold labels and direction paths, and `felix merge` refuses escape channels that fire on main's engine and a stale commission. Any other one is held by hand: open it as a draft labelled `needs-founder`. | memory felix-merges-its-own-prs; founder, 10-31 |
| 5 | 09-18 | Endgame: an autonomous engineering control plane with a Capability Plane and a Trust Plane. | `docs/2026-09-19-direction-decisions.md` |
| 6 | 09-19 | The engine stays bash, rows first. No new runtime on the enforcing path. | direction-decisions §1 |
| 7 | 09-19 | Control plane v0 is "the lease and its record", not a schedule. | direction-decisions §3 |
| 8 | 09-22 | Felix is a product for other people's projects; Claude Code first; host-independent; engineering only. | constitution |
| 9 | 09-22 | Record every declined suggestion with `felix route --ack`. | memory record-every-decline |
| 10 | 09-23, changed 10-27 | Build first stays the engineering rule, and the roadmap v1 market track stays withdrawn. From 10-27 a narrow commercial track runs beside it: fundraising applications, one paid pilot contract, and up to four design partners. No broad outreach and no price page. | `docs/2026-09-23-roadmap.md`; founder, 10-27 |
| 11 | 09-23 | Among documents, only direction waits for his yes. Engineering merges on green, except the hard stops in row 4. | constitution |
| 12 | 09-23 | Stealth in the middle: a session hears from Felix at its start and end only, with one narrow exception. | constitution |
| 13 | 09-24 | F1: landing machinery (Phase 0b) comes before the qualified judge, and the judge pin comes before unattended arming. | roadmap Phase 0b, §7 |
| 14 | 09-24 | Lost-work order: inventory is step 4, the stuck-PR page step 5, and the lost-work page step 6. The page is read-only and replaces the monitor; consent stays his GitHub merge. | roadmap Phase 0b |
| 15 | 09-25, changed 10-29 | A capability lane runs beside every phase. "The share is his; the lane's items and their order are Felix's." From 10-29 the share is half until intake (lane slice 1, row 35) merges on main, then one in four ("Half until intake lands"): "Every other session that starts without a task from you takes the first open capability item until the intake slice merges. Then the share drops back to one in four. Trust work gets the other half in the meantime." A change to the share is not held: it lands on green ("No, it lands on green"), and the lane counter names the commit that last changed it. The lane never touches `qualify.sh`, `obligations.sh`, `receipt.sh` or the landing actor's files. | roadmap §3; founder, 10-29 |
| 16 | 10-01 | F2: once landing is armed it may run overnight with the Mac kept awake. A sleeping Mac lands nothing. | roadmap §7 |
| 17 | 10-01 | The 0cw rulings (`docs/handoff/0cw.md`). <br>• **D1, both planes:** the host picks its model above Felix's floor, and Felix never builds a model minimizer. <br>• **D2:** engineering only. <br>• **D3:** one attended dispatch tick before March, on his own API key under a dollar cap. <br>• **Models:** every Workflow stage names its model and effort. <br>• **Fix intake:** red-on-main, false-block or step-blocker fixes get a slot; the rest are batched weekly; no new engine branch while more than 10 engine PRs are open. <br>• **Claims:** no "independent acceptance" in outside text before #350 and the pin. <br>• **Plugin cache:** belongs to the carrier. <br>• **The console:** read-only. <br>• **The floor:** advisory and raise-only. | 0cw |
| 18 | 10-01 | Corpus terms: lease A with no shell, the sealed commitment kept private, and a weak result investigated rather than narrowed on. | 0cw, roadmap §5 as amended |
| 19 | 10-02, changed 10-27 | Codex read-only starts now on his OpenAI credit. The second host comes forward: the Factory Droid adapter first, then the Codex adapter, as lane item 11, beside the trust track and the judge pin rather than after arming. His words: "Move row 19 too". | roadmap §3; founder, 10-27 |
| 20 | 10-09, changed 10-29 | The interface is built slowly as OS-style surfaces, read-only first, with chat later. From 10-29, Felix does not become a chat bot ("I don't want to make it so this becomes another Claude duet, ChatGPT bots"). In a team it starts underneath, briefing agents and checking changes, and stays on engineering ground first: "later use the engineering leverage to introduce the departmental liaison". Manager-engineer interaction and a better Slack presence come "once we ship the MCP later on". | pending 20261009T234930Z; founder, 10-29 |
| 21 | 10-10 | The seeded corpus gains a different-family arm. In Phase 2, a moved input stales only the receipts that depend on it. | memory commercial-radar-2026-10-10 |
| 22 | 10-12 | Gate friction is row 0 of the build queue. | carrier state |
| 23 | 10-12 | No native `permissions.deny` rules for secrets. Do not re-propose. | memory no-native-deny-rules |
| 24 | 10-15, changed 10-31 | Land on green. Live since 10-18. A launchd tick runs `felix merge` with nobody present on an open PR only if it meets all of these: it is not a draft; it carries no label named `felix:hold`, `felix:founder` or `needs-founder` (other labels hold nothing); it is not cross-repository and does not conflict; it touches no `projects/*/CLAUDE.md` or `docs/*roadmap*` path; CI's gate run passed on the exact head (C9); and a home worktree holds that branch at that head. Judge-changing PRs are included, except the trust-plane checker's judge artifacts, held by hand for the founder until roadmap step 15 pins the judge outside every change it judges (row 38). These are the main conditions, not all of them. `felix merge` must then pass in that worktree, which needs a green `felix gate` receipt there for this exact tree (a scratch clone's receipt is invisible to it). The contract also holds a PR whose base is not main (A12), whose head branch heads another open PR (A19), or whose paths are not plain ASCII (A9). The tick merges nothing while paused or while a deploy is owed or has just run (G2, G3, A11), lands one PR per tick, and lands nothing while the Mac sleeps. | `docs/2026-10-15-land-on-green-contract.md`; founder, 10-31 |
| 25 | 10-19 | "Keep the 09-25 lane: build intake now, and gate capability authority (dispatch, leases, floor) on the trust milestones." | pending 20261019T071844Z |
| 26 | 10-19 | Felix refuses pattern kills with a deny row (his answer: "Refuse them"). It landed as #455 (0.49.306), and the commission was re-stamped over it in #459. Nothing held it mechanically: adding a row to `deny.tsv` fires no escape channel (`lib/escape.sh` treats adding as free), and `deny.tsv` is a commission table (`FELIX_COMMISSION_TABLES`), so a merge that changes it leaves later merges waiting on his re-stamp. | carrier state |
| 27 | 10-19, changed 10-31 | Derived rows may bind without the founder's per-row admission (thesis Decision 2(b), intent design §11c, and §11d's task-blocking half). The founder's words: "Yes to derived rows binding without my admission, with your five bounds." The bounds: (1) task scope only, never a release and never an escape channel (row 40's four claim classes hold releases, granted 10-31); (2) witness-backed rows only, never a single model finding (`lib/candidates.sh` keeps refusing that); (3) the row's checker has qualified on seeded mutations; (4) nothing is armed before control 7 and the judge pin (row 25); (5) visibly Felix's: a Felix-authored commit the founder can tell from their own, a person clears a false block with a dated exception (in row 40's classes only the founder clears one, never by exception), only people loosen, and a row retires after false blocks. Felix uses the grant first for instances of class rules the founder has admitted; a model-proposed candidate stays advisory until that path has run. | pending 20261019T071844Z; founder, 10-31 |
| 28 | 10-19, changed 10-29 | Two users share one Felix core. **Founders** turn a novel idea into something real; their input should be around level 3 of the 10-19 ladder (the idea plus its stakes: who uses it, how mature, what must never happen, money and time). Below level 3, Felix re-derives the level 3 to 6 elements (stakes, a product brief, an engineering plan, a design contract) as best it can and, before building, asks the founder questions and offers options that may inspire them. Maturity (prototype, private beta, public, production) is the element the rest keys on, as the research also found, so it is established first; re-deriving the others is harder than it sounds. **Engineers** want reliability: one shot, so they do not have to come back; their input should be around level 2 (the issue text), and level 1, a one-line wish, must still be handled. The engineers are the corporate users. Concurrency and parallelism matter more to them than to founders. The founder's words: "for founder <L3 we're able to at least to the best of our ability rederive the L3-L6 elements therefore before building ask them some questions (even inspire them)"; "for engineers it's more about reliability and whether not we really one shot what they request for they don't have to come back"; "the 'corporate' = 'engineers' here"; "my idea of 'rederivation' sounds a lot simpler than it acutally is but...again one ward we're emphasizing, from the resaerch as well, 'maturity'". **Changed 10-29:** the two users become two editions: enterprise first, for software teams ("that'd be very enterprise oriented which is what we're doing first for our potential users"), and a commercial edition, derived from it afterwards, for founders and others who want to build but lack engineering hygiene and an engineering team ("Like a solo company founder"). Inside a company the first champion is the engineering manager and the target the whole department ("entire engineering department, so ig engineering manager"). Felix plans on a generic software development team as its first client; the industrial prospect in §6 is rumored and unconfirmed, not standing ground ("Just envision that our first client will be a software dev team"). At the end state an engineer's run is one shot with no questions back: "Final state should be that second option is not even an option bc felix's pipeline already figures out everything". | pending 20261019T071844Z; founder, 10-29 |
| 29 | 10-23, corrected 10-31 | Every incomplete or naive design and build in Felix is found and fixed. The audit confirmed 96 defects in 23 file-disjoint batches. Each batch is built with a contract, blind tests, red first, the fix, an adversarial review, and a second round when the review finds a major. Batches 1, 10, 16, 17 and 19, and the founder halves of batches 8, 11 and 12, touch the founder's stops, so they open as drafts labelled `needs-founder`. Publishing batch 22's snapshot stays the founder's act. | `docs/2026-10-24-audit-register.md`; pending 20261028T210239Z (wave 2's founder drafts) |
| 30 | 10-24 | Plan A. Local checks run what a change reaches plus the project's essentials. CI stays full. The home advances only on release green. It is built in the design's step order, report-only first. The essentials are never a hard-coded list: Felix finds a project's guards and breaks each one in a scratch copy, and a guard whose removal no test notices is an unguarded essential. A selective run takes the Mac-wide suite slots. | `docs/2026-10-24-reach-checks-design.md` |
| 31 | 10-24 | The land job may post one comment per new event on one standing issue, with enumerated text only, and nothing else on GitHub. That widens land-on-green G6 for exactly that. | pending 20261027T221322Z |
| 32 | 10-25 | Nothing stalls silent: a stalled run, agent or test says so where he will see it. After that, speed per item: several PRs landing, and a suite that never sits idle. | pending 20261027T221322Z |
| 33 | 10-26 | Off-Mac alerts come from github-actions[bot], through a dispatched `.github/workflows/felix-alert.yml` (option b of the b05 contract). A comment under his own gh login most likely never notifies his phone. The workflow file is a founder stop. It goes in one draft PR labelled `needs-founder`, with batch 1's `gate.yml` time limits. | pending 20261027T221322Z |
| 34 | 10-29 | What Felix is for a team. <br>• **Role:** the senior manager over the whole pipeline, "dynamically in charge of disaptching + communicating + organizing (again senior manager remember) role, delete distribute tasks, all of the above, plus the entire pipeline of from ideas, to skills/tools installations, ledger, contract, answers, obligations, routing, model adjustment, token optimization, scaffolding, and more I did not name." Offered four cores, the founder chose all four: "Standing need ledger", "Contract and lease", "Answers at the moment" and "One obligation's whole life". By Felix's reading, this pictures Felix and grants no authority: leases and mounting tools stay under row 25's gates. <br>• **Positioning:** the founder chose the option "Independent manager", whose text reads: "Felix is the engineering manager your agents report to, whoever made them. It decides what the work owes, who checks whom and what counts as done, and dispatches through the agents the team already uses. Its number is verified work per hour of your attention." Row 36 made the number checked work per hour of human attention. <br>• **The capability plane** tells a project what work is owed and what is needed to fix it, and must "match what we want while making sure we're not just doing factory rip off instead incorporating what's on the market + on unique, integrative design along with trust plane, ultimately delivering the autonomous engineering experience". Tools such as context7 and graphify are "the most basic layer" of it; the final stage designs and finds far more sophisticated ones. Using a tool comes first: "if we cannot even figure out how to use a tool, how can we figure out how to suggest a tool? And actually mount it, automatically, right?" | founder, 10-29 |
| 35 | 10-30 | The capability lane's first three slices are approved (`docs/2026-10-29-capability-lane-first-slices-design.md`, on main): slice 0 the lane counter, `felix lane`; slice 1 `felix situations`, which is intake (the intent design's §9 slice); slice 2 `felix retro`, the come-backs. The founder chose "Approve it" (its message: "I approve the lane design. Write the build plan."), then "Yes, build slice 0". Rules the design marks "(My call.)" are Felix's, except the share's unit, which row 15 makes the founder's (§5). | founder, 10-30 |
| 36 | 10-31 | **Claims.** Receipts, pitches and applications say a change was checked against a stated list of faults, over a printed number of cases, with what stayed unchecked listed. Felix never says "verified" or "proven", and its headline number is checked work per hour of human attention. The founder chose "Checked, in every text". Until the evidence engine (row 37) exists, a text says what ran, such as the gate and its suite, and names no fault list or case count Felix does not have; this interim reading is Felix's. | trust-plane design (`docs/2026-10-31-trust-plane-verification-design.md`) §11.1, decision 1; founder, 10-31 |
| 37 | 10-31 | **Placement.** The trust core's kernel refactor (the design's step 1b) starts once the audit's fixes to the files it rewrites have landed, batch 20 (`obligations.sh`) among them, which waits on plan A (§5). The evidence engine (its steps 3-5) is built beside plan A after the audit, sharing its parts, once the replay of slice 0's history and the prospective tests on two features (design step 2) pass. Step 6 is not placed. "Meanwhile the measurements, the trials and one narrow fix go ahead." The founder chose "After the audit". | trust-plane design §11.1, decision 2; founder, 10-31 |
| 38 | 10-31 | **Judge PRs.** Until roadmap step 15 pins the judge outside every change it judges (the checker's own pin, design §4.8, is not enough), a PR that changes the trust-plane checker's judge artifacts waits for the founder's merge, held by hand as a draft labelled `needs-founder`. The artifacts are its claim catalogue, fault model, oracle, case evaluator and decision kernels, and, by Felix's reading of the question's "the code that computes a verdict", the reference kernels, properties and abstraction map (with its concretisation) that judge them, and the tables that make its cells and mutants (`effects.tsv`, `bytes.tsv`, `layouts.tsv`, `operators.tsv`; design §10). Also by Felix's reading, today's verdict code (`felix merge`'s judge, `lib/escape.sh`'s merge blockers) is not covered until step 1b moves its decisions into these kernels; §5's row-24 question stays open. After the pin these land on green, and only a change that removes a check or lets more through is stopped. This amends row 24. The founder chose "Yours until the pin". | trust-plane design §11.1, decision 4; founder, 10-31 |
| 39 | 10-31 | **The `case` blocker.** It holds a failing high-stakes change (code a hook, the gate or landing runs: B3 and above) only after its own silent shadow on two new features (by Felix's reading of "trials", design step 4, on features built after the blocker exists, after row 37's prospective tests) meets bars fixed before it ran, and only while wrong holds stay under a rate the founder sets from that data ("After trials, your bound"). **Limits.** A limit a build accepts that no automatic check can show harmless, as slice 0's stated limits were, goes to the founder only on high-stakes code ("On high-stakes code these come to you"); at B0-B2 the change lands with the limit listed as unchecked (UNKNOWN) in its receipt and residual, and no one is asked ("Only high-stakes ones", not the recommendation); until the `case` evidence exists, by Felix's interim reading, such a change lists the limit as unchecked in its pull request and handoff. By Felix's reading (the answer names no start), the high-stakes half binds from 10-31: until the `case` evidence carries such a limit as an unwitnessed narrowing (held until the founder clears it or, by design §4.8, a trust-plane PR opens a new epoch), a B3-and-above PR that states one opens as a draft labelled `needs-founder`. Retiring a hand-written test by mutation subsumption stays a hand merge, as row 4's verifier channel already makes it, until two features' trial data show that planted faults stand in for real bugs; then it is asked again ("Not yet, you merge each"). | trust-plane design §11.1, decisions 3, 5 and 6; founder, 10-31 |
| 40 | 10-31 | **Admission.** After row 39's shadow, FAILCLOSED, WRITESET, OFFLINE and BASEEQUIV on code every session runs ("An unfinished read never yields a value; code writes only what it declares; it uses no network; outside its declared change, it behaves exactly as main does") may hold a release, under row 27's other bounds; release scope is granted here. Only the founder clears a wrong hold in them, never a dated exception. A new high-stakes feature (B3 and above) carries a known defect main already has in shared code only after the founder accepts it for that one function, which files the defect as an obligation to fix; later features on that function do not ask again. By Felix's reading (the answer names no start), the inheritance stop binds from 10-31, held by hand as a `needs-founder` draft until the `case` evidence carries it. The founder chose "Admit after trials" and "You accept per function". This amends row 27. Slice 0 (#480) landed on green at 10:01Z, after these answers, and nothing held it; it states four limits of its own (row 39) and five defects inherited from shared functions. The founder refused all nine at 18:13Z ("Refuse, fix them": "I don't accept slice 0's limits. Make each of its own limits and each inherited defect a follow-up fix."), so none is accepted, and a later high-stakes feature on those functions still asks. By Felix's reading of "fix them", each takes row 17's fix slot, not the weekly batch. Felix's placement: the lane's four and its own slug check in one lane fix; the resolver's, `_felix_remote_slug`'s and the table validator's reads in the trust plane's narrow fix (design step 1, §5); felix's load-time descriptor and `lib/own.sh`'s reads under the caller's `GIT_DIR` in one shared-code fix. | trust-plane design §11.1, decision 7; founder, 10-31; slice 0's limits, founder, 10-31 18:13Z |
| 41 | 11-06 | **Load on this Mac is managed, not capped.** Heavy Felix work asks for a slot and is admitted against measured headroom: the load against the cores, and memory pressure. No fixed count is set in advance. The founder's own commands are never gated. Background work gives way first and runs at background QoS. Every job runs as a process group with a deadline under a supervisor, so a timeout never orphans work. Every admission decision is recorded with the load it saw, and caps are derived from those records: the concurrency at which throughput stops rising. No new fixed concurrency cap is added to Felix. His direction: "as we're developing and making felix more sophisticated, think about optimization. Overloading issue should easily be managed by a dynamic optimization issue". Asked whether to add this row as proposed, he answered "Yes, add it". | `docs/2026-11-06-load-governor-design.md` §8; pending 20261106T084122Z |
| 42 | 11-06, 11-07 | **Intake first, then the trust plane, before large capability builds.** Lane slice 1 (#484) lands; slice 2 and later capability builds wait for the trust-plane revisit, because "trust problem must be settled bc the probelm will propogate to future capability build...which WILL be large engineering work". The revisit is a trust-plane redesign. The capability plane gets its own design after it: "It's a part that we're going to design later ... Again, this is still a trust plane redesign." Row 15's share is unchanged. By Felix's reading, a lane session that starts after intake lands and before the revisit settles takes trust-revisit work, not slice 2. | pending 20261107T041523Z |
| 43 | 11-06 | **Felix becomes infrastructure.** "At the scale that we're running right now, come on, I cannot live off of a local tool." The authority that approves landing runs hosted, off the developer's machine. felix-home moves to the Daimonion org after the IP assignment. No date is set, and it does not move without his go-ahead. | pending 20261107T041523Z |
| 44 | 11-06 | **The same machine rigor for every change.** A task does not earn less rigor because it is simple: "We should not go easy on this"; "Same machine rigor should be the baseline anyway". He also rejected rigor bought with process: "Rigor is currently bought with process. And that is terrible." The aim is "the smartest algorithm", not the longest or the hardest. | pending 20261107T041523Z |
| 45 | 11-06 | **Designs answer to directions, and the directions are an open list.** So far they are speed, accuracy, efficiency, security, commercial viability and autonomy. "Everything I say is a direction." Designs stay within the token and compute budgets real users have ("Keep the human constraint in mind"). They do not put latency at risk ("we should not have even thought about the idea of a 21.5 hours check"). They stay commercially viable for a customer who pays both an API bill and Felix's fee: "Why would they be using a product that would spike their API keys by 20%? While also paying me the fee." | pending 20261107T041523Z |
| 46 | 11-07 | **Open sets stay open.** An example the founder gives illustrates a set; it is not the set. A count is not the space either. "I don't want you to finalize things"; "engineering complexity is a lot more than rate limiting"; "we had 22 does that mean everything?" This holds in specs, designs, this file, pitches and memory: "I don't want to see this pattern again." Felix reads it this way: an example is written as an example; a count says what it counted; a question outside a document's scope is recorded as open, not answered; and no acceptance test, evaluation set or headline number rests on one instance of an open set. | pending 20261107T041523Z |
| 47 | 11-07 | **Everything serves the product, and this file holds the newest decisions.** "Everything serves for the sake of the product." Designs are judged against §1, and against the pitch only where the pitch still agrees with this file. Pitch material that no longer fits is set aside: "don't take that into account". "direction markdown should always be updated. It should always contain our newest decision." | pending 20261107T041523Z |
| 48 | 11-07 | **Who authorizes removing what a need checks.** A change can remove the subject of a need that applied on its base (`subject_removed`, trust-plane design draft 4 §4.3). For TASK_BLOCKING and RELEASE_BLOCKING needs, the removal is authorized by the task's admitted intent, which was admitted before the work began. For AUTHORITY_BLOCKING needs, the founder authorizes it. His answer: "Task intent; you for top". | pending 20261107T043947Z |
| 49 | 11-07 | **Releases fail closed until the release subsystem exists.** A release or deployment transition, including a merge that reaches one, proceeds only when the founder authorizes that release by name. Release authorization is never taken from merge authorization (trust-plane design §4.6). His answer: "Yes, as proposed". | pending 20261107T050000Z |
| 50 | 11-07 | **The trust-plane design is final.** `docs/2026-11-07-trust-plane-design.md`, draft 5 of the 11-06 revisit, is the trust plane's design. Its core rules: the verdict unit is the admitted need; a judged change never supplies its own judge; applicability is read on both the base and the candidate; evidence counts only from an authorized instrument closure; each need is checked at the transition whose subject it is about; and a new need binds through an admission transaction that lands before its implementation. It keeps the 10-31 design's claim catalogue, fault model, discrimination by mutation, per-claim receipts and judge pin (rows 36 to 40). It replaces that design's serial review rounds and its evidence engine's place in §5. "ok i think v5's directions can be final." | pending 20261107T050000Z |
| 51 | 11-07 | **Trust rework is first in the queue.** The founder asked "should trust rework be top of our queue now". Felix answered yes, in the order §5 now gives: intake (#484) lands first; the design's steps 1 and 2 start at once; fixes already in flight finish; then the design's engine steps. He answered "Yes, land it" to the fold that carries this order. | pending 20261107T050000Z |
| 52 | 11-08 | **The first partition of Felix's test parts is approved.** `projects/felix/partition.tsv` marks 209 parts instrument and 50 subject, each with a reason, after three readings of Felix's proposal (trust-plane step 3, slice 3, spec E5). Marking a part subject is a loosening, so a later row that moves a part to subject goes to the founder, and an instrument part a candidate changes is run as the judged base holds it. His answer to the overnight queue: "authorize slice 2 and approve slice 3". | slice 3's pull request |

## 5. The build order now

Order, not status; read status with §2's commands. Roadmap and 0cw dates
were set before row 0 and land on green were inserted; treat them as estimates.

**Before taking an item, find its owner.** Read the carrier state's newest
lines and its Order table, and run ListAgents. A session takes the first item
nobody owns. The carrier gives the next version slot to the highest-placed
branch that is gate-ready, so items can land out of this order.

**The main sequence:**
0. **Trust rework, the trust-plane design (rows 50 and 51).**
    - Intake (#484) lands first (row 42).
    - At once, beside everything below: the design's step 1, which replays
      slice 0 against a blind held-out set, and its step 2, the
      specification. Neither touches an engine file.
    - Fixes already open finish. No new audit batch starts ahead of the
      design's engine steps.
    - Then the design's engine steps 3 to 9, in its order. They replace
      item 2's evidence engine (the 10-31 design's steps 3 to 5). Where a
      step of item 4 does what a design step does, the design step replaces
      it; step 2's specification writes that mapping down. Until then, item
      4's steps stay listed and do not start ahead of the design's steps.
      The kernel refactor (step 1b) waits for that specification, because it
      rewrites the files the specification maps.
1. **The audit's 23 batches** (row 29): the non-founder ones in combined
   waves, each founder batch as its own draft.
2. **Plan A** (row 30), in the design's step order, report-only first.
   Batch 20 and C044 wait on it.
    - After the audit's batches on its files, at least 12 (`resolve.sh`), 10
      (`escape.sh`, a founder draft) and 20 (`obligations.sh`, which waits on
      plan A), and after the specification of item 0: the trust core's
      kernel refactor (step 1b, not restart step 1b; row 37), both PRs the
      founder's (row 38).
    - The 10-31 design's evidence engine (its steps 3-5, row 37) is replaced
      by item 0 (row 50). Its step 1, the narrow fix (#486), is a fix in
      flight and finishes.
3. **Leftovers:** slot 12 (`claude/project-writes-refuse-nonregular`); PR
   #425; the secret-scan quoted-reference fix
   (`salvage/2026-10-27/secret-scan-ref`); drafts #365 and #360; a one-line
   land-on-green amendment for PRs gated only in a scratch clone; and draft
   #452 (§3).
4. **The trust track, in roadmap order.**
    - First, 0cw trust item 2: merge refuses a receipt that skipped checks.
      It must land before step 8, and starts once 10 or fewer engine PRs are
      open. Its spec and blind assertions are in the memory root,
      `audits/2026-10-01-report-v5-review/specs/skipped-receipt/`.
    - Then steps 7 to 18, in the roadmap's order: 7, a readiness status,
      with the closing-notice line moved here from step 5; 8, the actor's
      core, in shadow; 9, restart step 1a; 10, attended landing; 11, version,
      `red.tsv` and manifest written at landing, armed; 12, post-deploy
      verify and full rollback; 13, the trust base, now only for an actor
      that re-gates in its own clone (§8); 14, #304, then the judge-identity
      epoch; 15, the judge pinned outside the change it judges; 16, the
      founder's stamps leave the tracked tree; 17, the scheduler and its
      arming brakes; 18, the deny rows on raw merges and on the grant, in the
      founder's lane.
    - Then at least 10 shadow agreements, 5 clean attended landings, one
      Elenchus shadow run, and the founder's arming sitting.
5. **Phase 1, the qualified judge.**
    - `capabilities_needed`, then control 7, then the qualified-judge join.
      No row is armed before control 7 and the pin.
    - Also `coverage.tsv` and restart step 1b.
6. **Phases 2, 3 and 4.**
    - Phase 2: stale receipts, the ledger in the repository, and the private
      whole-life replay.
    - Phase 3: finals, Dec 7-18, engine only.
    - Phase 4: the public replay, the merge-point check, and the harvest rows
      before ECC hooks go off.

**Beside it, the capability lane,** at half the sessions until intake lands
and one in four after (row 15); 0cw also reserves one standing session for
it. `felix lane` (slice 0) counts the share in engine landings over 14 days;
the founder's answer counted sessions, so that unit waits for the founder's
yes with this fold. Until intake lands, every other untasked session takes
the first open lane item; after it the lane design hands one to such a
session when the lane is short (row 35). Any other session takes the main
sequence. The order is Felix's call:
1. Workflow stage checks, a practice for every session rather than a lane
   deliverable: until Claude Code 2.1.301 or later is installed, a green
   Workflow run is trusted only after each stage's return and artifact are
   checked, because on earlier builds an agent can skip its step.
2. The #417 mods round, extended with Q9-Q14, run on 10-19. Its record is
   `audits/2026-10-19-mods-round/` in the memory root.
3. The seeded-omission corpus, with second-family and strongest-host arms,
   once the founder sets its ceiling.
4. Codex read-only, as a second-family author.
5. The dry-run lease.
6. The retire re-key.
7. The outcome record.
8. The D3 attended tick.
9. The replay, as approved.
10. The advisory floor.
11. The second host: the Factory Droid adapter first, then the Codex
    adapter, beside the trust track and the judge pin rather than after
    arming (row 19 as changed 10-27; roadmap §3 item 5).

- **Need side.** Items 1 to 4 and 11, plus obligation intake and admission,
  wait on no trust milestone. Item 3 waits on the founder's corpus ceiling,
  and admission is the founder's act; items 1 and 4 and intake need nothing
  more (item 4 uses the Codex login of 10-02, `CODEX_HOME=~/.felix-codex`).
- **A lane session's first item.** Item 1 is a practice and item 2 has run,
  so a lane session takes the first of these nobody owns: the lane design's
  slices after slice 0, first slice 1 `felix situations` (obligation intake,
  row 35; thesis I1 and I2), then slice 2 `felix retro`, which this fold
  places and row 42 holds until the trust-plane revisit settles; then item 4, item 11, and item 3 once its ceiling is set.
- **Authority side.** Items 5 to 10 keep the trust gates set out in row 25.
- **Before row 27 arms anything,** row 40's classes included (they take
  release scope, the founder's clearance and false-block bound in place of
  task scope, a dated exception and a default bound). These were found on
  10-19, after the founder's yes, and each is a build, not a new decision:
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
      row 24, so it is the founder's decision, asked when the build reaches
      it. Row 38 settled it for the trust-plane checker's judge artifacts,
      which overlap the code named here.
    - A product project's exceptions open only after the boundary reads the
      home's diff and roadmap step 18's deny rows exist; earlier, an
      exception would be a grant a session can give itself.
    - The land ledger names which obligation failed a gate, so held merges
      can be traced to derived rows.
    - The review behind this list is in the memory root,
      `audits/2026-10-19-intent-and-vibe-coding/row27-and-ladder-review.json`.

**Not before March:** `felix dispatch` beyond the one tick, and leases with
real authority. Also deferred: discovery schedules and budgets, the Docker
sandbox, DSSE receipts, retiring the router, team concurrency, and broad
outreach and a price page (row 10). For DSSE receipts the founder ruled a
CI-only signing key off roadmap §4's enforcing path ("Off, with conditions",
10-29): nothing that decides reads or waits on the signature; signing is a
separate job after CI's judgment and cannot change it; only main's workflow
may use the key, by the token pin, else the key's own rules, else felix-home
stays unsigned; a test shows those refusals before the first receipt is
signed ("Token pin alone", 10-31).

**Owed measurements.** Each runs when its precondition holds; none has a slot.
- The after-measure of hold-once and `felix cost`, now due.
- Gate time on the 48 GB laptop: pre-A main against A+A3, then B and C.
- The handoff fold of the pending sections.
- Two zero-token counts for row 27, before any build: how many row
  admissions one class admission would replace (the 22 candidates name 22
  properties), and `engine_deployed`'s gate failures by cause.

## 6. Open, waiting on the founder

Nothing in §4 is asked or re-proposed again. Each item below is asked once,
when a build step reaches it or in the closing report that first raises it,
and not again until he raises it, unless its line names a later moment.

**Decisions:**
- Admit or refuse the 22 candidates (Elenchus 7, Veldra 15).
- Whether the thesis's leakage-per-objective definition replaces or refines
  the 08-12 objective.
- The aim the founder raised on 10-19: production-ready work and PRs from a
  few sentences of scope, with recursive improvement and adaptation. Its
  design is on file (§7), and its §11 asks eight decisions, the first how
  the founder's words bind (through a terminal command a session cannot run).
- Whether Felix must also produce engineering for someone who will not own
  or understand the code (row 28 names only owners). The vibe-coding brief's
  §12 designs the test; ask only if a build step reaches it.
- The interface proposals of 10-09 (data contract first, unknown is not
  zero, no shell before about three surfaces, read-only first, two audiences).
- Whether the console, a chat or a per-function toggle should ever act.
- Which Felix functions become user toggles.
- Whether the independence gate check, which enforces with 4 of 6
  controls, is grandfathered under amendments §2.1.
- Confirming the origin URL restored on 10-08.
- Whether a project's first `evidence_vendored` line should escape (audit
  batch 11, round 3). Ask once, when a build step reaches it.
- Where the Claude Code auto-memory folder is backed up. It holds about 150
  notes, is in no repository, and `felix pulse` does not cover it.
- From the shadow's data (row 39), the `case` blocker's false-block bound;
  once two features' trial data show that planted faults stand in for real
  bugs, whether retiring tests by mutation subsumption may land on green.
  Felix's rule: re-ask row 39's limits if features 1-2 average over two stops.
- Two questions the founder raised on 10-29: whether Felix needs "an actual
  software" beyond the plugin, and how its added value shows inside an
  engineering team. A session's proposals for both are unconfirmed.
- Landing versus releasing: whether release is a separate step that comes
  only after deep checks pass. On 11-06 he said: "I cannot answer question two
  to you yet ... We have to run that perhaps natively." It is tried natively
  before it is asked again.
- The language. Row 6 stands. The 11-06 re-measure reopened the question,
  and the trust-plane revisit asks it after its Rust spike.

**Consents:**
- The corpus spending ceiling: $96-349 for one corpus at 3 runs, or $172-632
  with the replication. Lane item 3 waits on it. Ask again only when the
  corpus is about to run, as the founder confirmed on 10-19 ("we'll talk
  about it when that day arrives").
- The D3 tick's API key and spend limit; ask only when the tick is near.

**His acts:**
- Merge the founder drafts as they open (rows 29, 30, 33 and 38): batch 1
  whole; the workflows PR (the alert workflow with batch 1's time limits);
  batches 10, 16, 17 and 19; the founder halves of batches 8 (receipt), 11
  (template) and 12 (deny rows); plan A's b30, after the PR adding its
  risk.tsv row; and, until roadmap step 15's pin, row 38's judge PRs.
- Accept or refuse high-stakes limits (row 39) and inherited defects per
  shared function (row 40); slice 0's nine were refused, so each is a fix;
  after the shadow, clear wrong holds in row 40's classes.
- Merge Elenchus #29; lift the `spawn_task` chip-freeze deny row; re-stamp
  the commission after a commission-table change; run `felix commission` in
  six other projects; fill the three held commission rows; the arming sitting.
- About ten minutes at the Code tab for #417's Q8 (attended Desktop); the
  round's 2.1.299-2.1.301 arms rerun once the desktop app passes 2.1.301.
- Widen the GitHub token scope, so that the Actions-budget row reads.

**His documents:**
- Deck v4 (`docs/decks/2026-10-19-felix-investor-deck-v4.pptx`) slide 17
  still says "Current build focus: Trust Plane MVP" (the 2026-10-18 brief's
  §9 has wording for it); it and slides 9, 10, 13 and 14 break row 36.
- The official pitch (`strategy/applications/`, tag `pitch/2026-10-27`),
  where later pitches start: deck lines 72 and 89 and brief lines 28, 32,
  78 and 109 break row 36; its February pilot, named in all three files,
  breaks row 28; and its one-liner predates row 34. Felix's rewording is
  in memory `felix-official-pitch`; a new tag is the founder's act.
- The constitution's invariant-2 wording and its library count; the nine
  CLAUDE.md edits the 10-18 commission audit proposed; an installation guide
  in the roadmap; and draft #474, Felix's own Codex reader (roadmap §3 item 5).

**Boundaries he set:**
- The TSMC-subcontractor test is approved in principle only, and egress
  control comes first. It is rumored and unconfirmed (10-29), not standing
  ground: plan for a generic software team (row 28).
- The input-rewriting floor is declined. The 10-19 mods round kept it
  declined; re-raise it only with new measured evidence.
- Never make felix-home public. The founder made it private on 10-30 at
  about 06:00Z; a 10-24 switch never took effect, so it was public from
  08-09. Each bring-forward to LeavesJ/Felix needs the founder's yes.

## 7. Designs on file

A design here is not a commitment. It becomes a build target when a decision
recorded in §4 places its first slice in §5, or when it is a lane item, whose
order is Felix's call.

| Design | What it says | Status |
|---|---|---|
| `docs/2026-10-18-capability-plane-thesis.md` | The capability plane's charter (v3.2 invariant 4), seven invariants I1-I7, the anti-slop contract, and autonomy as leakage per objective. | Decided parts are row 25 and the lane order. The rest is on file. |
| `docs/2026-10-19-intent-to-build-design.md` | How Felix turns a few sentences of scope into an admitted, checkable build, and improves its own tables. Felix is deterministic about the frame; models write the content as typed answers. | On file. Its first slice, situations owed (report-only, with admission drafts), is lane slice 1 (row 35). Its §11 lists eight founder decisions, each with a recommended answer. §11c, and §11d's task-blocking half, are decided by row 27. Row 28 moves §11b's questions before building for a founder below level 3. The rest are open. |
| `docs/2026-10-19-ai-engineering-vs-vibe-coding.md` | What separates AI-assisted engineering from vibe coding: what the work is held to, not who types it. It sets out a full answer part by part, its limits, the probable partial answer with the measurement that would show it is enough, and what makes the capability plane more than dispatch. | On file. Research, not direction. Its zero-token pre-checks (proxy-conflict signals over transcripts, miss-to-layer classification of coded leakage turns) are candidate lane items. |
| Reflection triggers (memory, 08-18) | Felix questions its inputs but not its method; it needs enumerated trigger moments. | Open. |
| `docs/2026-09-23-restart-moments-scope.md` | Restart moments. | Step 1a is on the trust track and 1b in Phase 1. Step 2 waits on the handoff repair. |
| `docs/2026-10-29-capability-lane-first-slices-design.md` | The capability lane's first three slices: the lane counter, `felix situations` (intake) and `felix retro` (come-backs). | Approved (row 35). The slices are lane items (§5). |
| `docs/2026-10-31-trust-plane-verification-design.md` | A change reaches the lander carrying its evidence: claims from a versioned catalogue, a machine search over a stated fault model with a printed number of cases, evidence that each check can fail, and what stayed unchecked. Models propose; mechanisms decide. Its §8 makes design deliberation a Felix capability. | Its seven decisions are rows 36 to 40. Row 50 keeps its claims, fault model, discrimination, receipts and judge pin, and replaces its serial review rounds and its evidence engine's place in §5. Nothing is built, and no catch or speed figure from it goes into outside text before a replay and two prospective tests (its §11.2 #14). |
| The trust-plane revisit, 11-06 to 11-07 (memory root `designs/2026-11-06-trust-plane-revisit/`: the brief, sketches 1 and 2, drafts 2 to 5 and their PDFs; the language re-measure, `audits/2026-11-06-language-remeasure/report.md`) | The trust plane redesigned for the product. The verdict unit is the admitted need, not a green suite. Each checker carries an evidence record. The authority runs hosted, apart from the workers, and the queue owns landing. Latency is a measured objective, and budgets are set by the user. Draft 5 is final and filed as `docs/2026-11-07-trust-plane-design.md`. The capability plane is outside its scope (row 42). | Final (row 50). It is placed first in §5 (row 51). Nothing is built. |

## 8. No longer binding

Older text still says some of these. Where it does, this file and §4 govern.

| Was | Replaced by |
|---|---|
| The 10-31 trust-plane design's serial review rounds, and its evidence engine as §5 item 2's placement | Row 50: the trust-plane design of 11-07 and its order |
| The 10-27 pitch, decks v3 and v4, and earlier applications, read as statements of direction | Row 47: this file governs, and pitch material that no longer fits it is set aside |
| Roadmap v1's outside-user and outreach track, and row 10's "no pricing, outreach or demand track" (09-23) | Row 10 as changed 10-27: build first, with a narrow commercial track beside it |
| Row 19's "the Codex adapter is a lane item for about December, after arming and the pin", and the Factory Droid adapter deferred past March | Row 19 as changed 10-27: Droid first, then Codex, beside the judge pin |
| "Felix is Phase 1 of the guidebook and nothing past it" (08-10) | Row 8, a product for other people's projects (09-22) |
| "Felix turns intent into verified, shipped code" (§1 and the constitution before 10-31); "verified work per hour of your attention" (the 10-29 positioning option); "verified", "proven" and "proof" in the 08-17 to 09-30 reports and decks v3 and v4; the thesis's "M obligations proven on this revision" (10-18 thesis §6) | Row 36 (10-31): "checked", against a stated list of faults; never "verified" or "proven" (nor, by Felix's reading, "proof") |
| Row 15's "about one session in four" (09-25; roadmap §3, 0cw), with a lane session started only by the founder or the carrier; the thesis's count of a lane session that lands engine code or a sealed, measured number | Row 15 as changed 10-29: half until intake lands, then one in four; `felix lane` counts engine landings only (§5) |
| Row 28's "the first outside deployment is likely the subcontractor test in §6, so keep that weight in view" (10-19) | Row 28 as changed 10-29: plan on a generic software team as the first client |
| F2 (a): nothing lands while the Mac sleeps, to be revisited in Phase 4 (09-24) | Row 16 (10-01) |
| "Before arming, nothing lands unattended at any hour" (roadmap Phase 0b), and "Nothing lands unattended before the pin" (0cw line 126) | Row 24, land on green (10-15). Unattended *capability* authority still waits on the pin and arming (row 25). |
| Roadmap step 13: "a change to the code that judges never lands with nobody present" | Land on green lands judge-changing PRs, except the trust-plane checker's judge artifacts until roadmap step 15 pins the judge outside every change it judges (row 38). The departure is recorded in its contract, which predates row 38. |
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

**Stale text, still to be fixed:** 0cw lines 164-168, 333-334 and 345-346
("Before arming, nothing lands unattended."); the roadmap's step 4 "being
built now", step 5, step 10's date, the arming date (Phase 0b's "Then" line
and §6, "Oct 27-Nov 2"), §2's in-flight list, §6's "schedule the memory
backup" and §7's 09-24 line "nothing lands unattended while it is judged by
its own checkers"; the README's "Where it's going" order; HANDOFF.md's
"Current state"; the constitution's "the monitor stays as the deeper page"
and "forty-one sourced libraries"; and "verified" in the engine's own text.

## 9. Where the detail lives

| Topic | File |
|---|---|
| The charter and the split | `projects/felix/CLAUDE.md` |
| Phases, steps, effort and signals | `docs/2026-09-23-roadmap.md`, read through §4 and §8 of this file |
| The 10-01 rulings and lane item detail | `docs/handoff/0cw.md` |
| The capability plane | `docs/2026-10-18-capability-plane-thesis.md`, with evidence in the memory root, `audits/2026-10-18-capability-plane/`; the lane's first slices, `docs/2026-10-29-capability-lane-first-slices-design.md` |
| Landing with nobody present | `docs/2026-10-15-land-on-green-contract.md`; the evidence a change is to carry to land (designed, not built), `docs/2026-10-31-trust-plane-verification-design.md` |
| Gate friction | `docs/2026-10-12-gate-friction-design.md` and contracts A to D |
| The audit and plan A | `docs/2026-10-24-audit-register.md` and `docs/2026-10-24-reach-checks-design.md`; build state in the memory root, `audits/2026-10-24-audit-fixes/` |
| The founder's reports, decks and posts | `docs/reports/`, `docs/decks/` and `docs/outreach/`, by date; the official pitch is `strategy/applications/` (tag `pitch/2026-10-27`). Pending 20261027T221322Z says what each is and how to read the radar. |
| The queue as it moves | The carrier state, `~/.felix/memory/felix/audits/2026-10-08-carrier/state.md` |
| Recent sessions' decisions | `docs/handoff/pending/`, newest first, folded into `HANDOFF.md` |
| Founder leakage | `docs/2026-09-23-episode-pilot.md`, `docs/2026-09-23-episode-batch-2.md` |
| Why the engine is bash | `docs/2026-09-19-direction-decisions.md` §1 |

## 10. How this file stays current

- **Who edits it.** As the top of this file says, every pull request that
  touches it waits for the founder's yes, a fold included. The constitution's
  rule that records merge on green covers pending sections, not this file.
- **Founder decisions made in conversation.** These are recorded in a pending
  section first, as now. That section merges on green, and the decision
  binds from it (point 3 above), so the fold waiting for his yes delays
  nothing. The next session that touches direction folds them in here and
  moves the "As of" line.
- **Live state stays out.** Steps landing, PR numbers and versions are read
  by command. That way an engineering PR never needs to touch this file,
  and never waits for a yes because of it.
- **Designs reach the build order only through this file.** A slice of a
  design on file (§7) enters §5 in one of two ways: a founder decision
  recorded in §4, or a lane item placed by Felix under row 15. A design on
  file is never placed by itself.
- **Pointers to this file.** `MEMORY.md` names it on its first line. The
  constitution names it in "The split", beside the list of what waits for
  his yes. The session-start hook names it first once
  `claude/direction-read-first` lands (§3).
