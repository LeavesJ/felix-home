# What separates AI engineering from vibe coding, and what Felix can do about it

Research brief for the founder, 2026-10-19.

**How it was made.**
- Five evidence sweeps at primary sources: Cherny, Torvalds, practitioners, empirical studies, theory.
- An independent re-fetch of every cited source: 63 findings VERIFIED, 41 PARAPHRASE_OK, 3 UNVERIFIED, 3 WRONG.
- Three blind theories, each with one refuter.
- A deepening pass, because the founder asked to "think as hard as you can, but do also analyze the limitation and the probable partial answer". It made three attempts, each with its own refuter: a full answer, the limits with the probable partial answer, and what the capability plane is if it is not dispatch.

Every claim about a person rests on a finding graded VERIFIED or PARAPHRASE_OK. Findings graded UNVERIFIED or WRONG appear only in the source table, marked as such.

**Standing.** This is research, not direction. It decides nothing. `docs/direction.md` §7 lists it as a design on file. Any proposal here becomes a build target only through that file, and only after the founder's yes. Sections 10 to 13 are the deepening pass. Sections 1 to 9 were corrected where that pass showed them wrong.

**What it concluded, in three lines.**
- **Probable partial answer (section 12).** For a person who owns the product, Felix could probably hold work to engineering on everything class-level, observable and elicitable, with design fit contested. For a non-owner it stays partial. Apart from path tiers, the obligations ledger and tree receipts, none of it is built for another project today: 0 of 22 candidates are admitted, and there is no dispatch.
- **Capability plane (sections 6 and 13).** Felix rents the labor and the noticing. By design it keeps the standing list of what is owed, who writes the check, which units of work run and in what order, and retirement on outcomes; most of that is not built yet. It is only dispatch if arm D does not beat the off-the-shelf composite A+ on recall at the false-block bound and arm C matches arm D (section 13, last subsection).
- **Three decisions are yours (section 14):** who the endgame's novice is; whether a bounded derived row class may later bind without your admission, which widens Decision 2(b) and is decided with it; and the unattended credential plus a spending ceiling. The ceiling unblocks section 8's corpus run and the cheap first version of section 12's measurement; dispatch still waits on the trust gates.

---

## 1. The answer

The code does not separate the two, and neither does the person typing it. The same model writes a weekend toy and the Claude Code codebase. Boris Cherny reports that Claude wrote every line of his 259 PRs in one month, and Linus Torvalds had Claude Code write a kernel page-cache series. What differs is what the result is held to. Vibe coding holds the code to the prompt and to whatever running it shows, without reading it (PR1, EV22). Engineering holds it to four things:

- everything the change owes, including obligations nobody stated;
- a check written by someone other than the producer, which has been seen to fail;
- a record that outlives the session, so the next change answers to the same standard and every miss becomes a standing check;
- a named person who answers for the result for as long as anyone depends on it.

Architecture is the same standard applied across changes. Each change is checked against the recorded decisions of the changes before it, and the chosen representation removes special cases instead of adding them (factors 7 and 9). No single diff shows either. That is why changes that can each be justified can still wreck a system, whether vibe-coded (PR8) or written by hand (TH2). This is the least-evidenced part of the answer.

The founder suspected the difference is reasoning. That is partly right, but the reasoning that matters is about the acceptance standard, not the code: what is owed, what would show this is wrong, and whether this change extends the design or patches around it. Today's models can do several of these moves when something prompts them. Their verdict on their own work is not evidence (TH15, TH16, CH23; the first two are 2025-era), and they cannot supply facts that are not in their context. Engineering has always been mostly that surrounding standard. Agents made it visible because they made typing free.

**Can it be tackled? Partly.** Work can be held deterministically to the part of the standard where three things are true: the deciding facts are recorded, the properties fall into classes a machine can check, and the checks stand outside the producer (section 12). Some things cannot be supplied: a stake, a person's comprehension, a verdict on design fit, and obligations that are in no class and that nobody states (section 10, F3, F12, F14, F15). The measurement in section 12 decides whether the rest is enough.

**The sentence to carry:** The same model writes both. Vibe coding holds the work to the prompt and to what a run shows. Engineering holds it to everything it owes, including what nobody said, judged by a check its author did not write and has seen fail, kept standing after the session, and answered for by someone who will live with the result.

---

## 2. Why "humans architect, AI does the chores" is wrong

The usual answer fails in four ways. It also has a real kernel, which section 2.5 states.

**2.1 The people the founder named no longer keep "the hard code".** Cherny has not edited a line by hand since November 2025 (CH1, CH13). In May 2025 he still hand-wrote intricate data-model refactors. His stated reason was that doing them was easier than explaining them (CH2). That is explanation cost, which correlates with difficulty but is not the same thing. DHH wrote none of the shipped Omarchy 4 code (PR9). Lopopolo's OpenAI team shipped an internal product with zero hand-written code (PR11). Karpathy went from 80% manual to 80% agent within a month (PR6). Wherever this line sits, it moves with every model generation, so it cannot be the definition.

**2.2 Delegation follows verifiability, stakes and expertise, not difficulty.**
- Anthropic's study of its own engineers found they delegate what is easy to check, low-stakes or tedious, and that the boundary keeps moving (CH18).
- Torvalds hands AI the work he is bad at: Python, on a toy leaf tool whose voltage scale he tied to a signal-generator and oscilloscope reading (TO5, TO6, TO18).
- Cherny's own line between vibe coding and engineering is where the code sits: throwaway versus critical path (CH3).

**2.3 Failures cluster on the "boring" obligations as much as on the hard core.**
- METR's agent PRs that passed the maintainers' tests were all unmergeable as-is. They lacked test coverage, docs and lint compliance (EV3/TH20). That sample is n=4, and on the test-failing runs core functionality failed too, so "AI only fails on chores" is also wrong.
- Models picked the insecure option in about 45% of tasks where the prompt did not ask for security, and larger models did no better (EV9).
- Generated Supabase apps shipped with row-level security that was present but insufficient (EV18).
- MenuGen matched Stripe payments to users by email instead of user id (PR7).
- Felix's founding miss was a green deploy with no rate limiting, an omission that survived three independent authors.

If the AI reliably did the boring part, none of these would happen. The "boring" obligations are exactly the ones a prompt leaves out.

**2.4 Humans doing architecture does not protect architecture.**
- At 37signals, designers vibe-coded PRs that could each be justified, but together they wrecked the system's architecture and had to be cleaned up by hand (PR8; DHH dates this to February 2026 and says practice has changed since).
- Naur documented the same failure in 1985 with human programmers who had full documentation (TH2).
- In both cases the damage was in the aggregate of changes, not in any one hard task done badly.

**2.5 What the trope gets right.** At any given date, the frontier these people keep for themselves still looks like difficulty plus expertise:
- Lopopolo still does the gnarliest refactors himself (PR11).
- Torvalds judged the AI's attempt in his own C domain poor and did it himself (TO18). He also keeps the data representation and interfaces (TO6, TO7).
- Cherny hand-wrote the parts he had strong opinions about (CH3).

So today the person still keeps novel, long-lived representation choices (F9), refusal and risk. This brief reads the reason as irreversibility and the lack of any class row, not difficulty, but the evidence above does not separate the two. Recurring representation choices, such as identity keys and whether row-level security is sufficient, can become class rows (F8). The "chores" half of the trope fails outright (2.3). The difference from the trope is the dividing line. It is not hard versus easy. It is three other splits:
- the producer of the work versus the party that judges it;
- a session versus a standing record;
- facts a probe can observe versus facts only a person knows.

Those three lines can be tested, and the trope's line cannot.

---

## 3. What the people actually show

**Boris Cherny (Claude Code).** His involvement cannot be counted in lines, because he typed none from about November 2025 (CH1, CH13). It went into decisions rather than typing (listed below the table). He ran about 10-15 sessions in parallel and described his job as context switching (CH4). What he kept changed over time:

| Date | His working mode | Status |
|---|---|---|
| 2025-05 | Hand-wrote data-model refactors that were costly to explain; called choosing between hand and delegation a matter of judgement with no rule (CH2) | VERIFIED |
| 2025-12 | Vibe coding fine for throwaway or off-critical-path code; critical code worked plan-first, in small steps (CH3) | VERIFIED, secondary report |
| 2026-01 | Most sessions start in plan mode; about 10-15 sessions in parallel; describes his job as context switching (CH4) | PARAPHRASE_OK |
| 2026-02 | Still looks at the code; wants a human on it except for prototypes (CH13) | VERIFIED |
| 2026-04 | Looks only at the final result, which works because he designs the verification (CH6, CH7) | VERIFIED / PARAPHRASE_OK |
| 2026-06 | Reportedly dropped plan mode (CH8) | fan-site secondary, details unconfirmed |
| later | Reportedly writes loops that prompt Claude (CH22) | secondary, date unsupported |

Three things hold at every date:
- He decides what to build, by picking among working prototypes and cutting bad ideas fast (CH11, CH13).
- He designs the check: Stop hooks until tests pass, subagents that test review findings for false positives, and verification as his top tip (CH6, CH9).
- He turns every correction into a lasting rule: a CLAUDE.md line per mistake, and a lint rule once a review comment recurs 3-4 times (CH5, CH12).

He reasons about models empirically, not from specification (CH21). He is careful with numbers. His 80-90% share was an estimate, and he will not claim the last 10% until attribution is measured (CH2, CH17).

His team's October 2026 post is the closest published answer to the founder's question (CH14-CH16):
- A risk tier is set by what the change touches, not who wrote it, and an agent's approval never counts as a person's.
- Humans stay on direction, risky code, architecture others will copy, reading the evidence, and owning the outcome.
- Incident reviews ask which layer should have caught the miss.
- Nobody holds the full system in mind, and the team says it does not think anyone needs to. It also admits it has no process for building shared context.

That post is on claude.dev. The check did not confirm the domain is Anthropic-owned, and its outcome figures are internal with no sample size.

The current Claude Code best-practices page names the model's characteristic failure directly: "Claude stops when the work looks done." (CH23). Cat Wu asks Claude to interview her because it does not ask questions on its own (CH19).

**Linus Torvalds.** His stance on tools reversed and his test did not.
- In 2000 he refused to support a kernel debugger because it let people fix behaviour line by line without understanding what the code means. His biggest job, he said, was refusing features (TO1, TO2).
- In October 2026 he calls tool-specific AI rules idiotic and says his expectation is that people understand what they are doing (TO3).

His own AI use follows a placement rule:
- He vibe-coded a Python visualizer for a hobby audio project, in a language he does not know, at toy stakes (TO5).
- Even there, he chose the data representation, diagnosed the agent's stall himself and handed it a design change rather than a retry, and tied its voltage scale to a signal-generator and oscilloscope reading (TO4, TO6).
- The AI commits sit on their own branch, with a merge message that says what the tool did (TO4).
- On real kernel work, Claude Code did the code and tests "under my direction". He ran the measurements on his own machine, and the branch carries "-with-llm" in its name and is unmerged (TO17; patch count and benchmark figures unverified).

AI first earned his trust as a reviewer, measured against his own review (TO13). Kernel policy:
- agents may not add Signed-off-by;
- in bug-fix work, the agent must state what it could not build, test or reproduce;
- the agent must never send anything itself (TO20).

A patch to drop the Assisted-by provenance tag was posted after the October maintainers summit (TO19). It is pending, and the patch gives no reason. The live doc still required the tag when it was read.

One tension remains: he keeps the Python tool alive by re-prompting rather than understanding it. Only the low stakes resolve that.

**Others**
- **Karpathy.** Defined vibe coding as deliberately not looking at the code (PR1). His January 2026 list of model failures is meta-cognitive: they do not manage confusion, seek clarification, surface inconsistencies, present tradeoffs or push back, and they bloat code until a human asks for something simpler (PR6). On a repo built deliberately against the usual patterns, the model's prior kept overriding his intent (PR5). The same January post also advises giving agents success criteria and tests first.
- **Willison.** The line is whether you can explain the code and prove it works, with a test that fails if the change is reverted (PR2, PR15). He also frames "vibe engineering" as existing senior discipline that agents make more valuable (PR3).
- **Beck.** Moves his values into constraints the agent must follow: plan.md, strict test order, structural and behavioural changes never mixed. He watches for agents disabling tests (PR4).
- **DHH.** Reviews the shape of everything and reads lines only in the model layer (PR9).
- **Hashimoto.** Calibrated agents by blindly redoing his own commits and comparing. Every agent error then becomes a permanent fix to the harness (PR10).
- **Lopopolo.** Engineers' taste is pulled out of their heads and encoded in docs, linters, error messages and layout before the agent acts (PR11).
- **Ronacher.** Describes his own lapse into overbuilding when building got cheap (PR14).

**Alexandr Wang.** The record is thin. There is one secondary report (Fortune, via a podcast): he told 13-year-olds to spend all their time vibe-coding and treated tool fluency as the skill (PR21). Nothing in the evidence shows how he or Scale draw the line between vibe coding and engineering. Whether vibe-coding hours build the judgement that separates the two is unresolved. EV6 and EV7 suggest it depends on how the person engages, not on the hours.

**Where the record is thin overall:**
- Most practitioner evidence is self-report from famous successes. No study covers ordinary teams.
- Several Cherny points are secondary or fan-site sources (CH8, CH22).
- Torvalds's kernel-patch details are unverified (TO17), and the reason for the tag deprecation is unsourced (TO19).
- The Anthropic team post has no sample sizes.
- The Wang record is one quote.

### 3.1 How AI, founders and top engineers reason, as far as this evidence shows

| | Where the reasoning goes | Typical move | Blind spot | What it does to the work |
|---|---|---|---|---|
| Model today | Executing the brief from a strong generic prior | Fills every gap with the usual answer; stops when the work looks done | Can state the user's intent when asked but does not consult it under optimisation pressure (TH16); keeps no memory across sessions (TH17) | Plausible code that settles gaps silently and stops on appearance (CH23) |
| Founder-builder (Cherny) | What to build, and how it gets checked | Builds several working options and cuts; designs checks and loops | Evidence for this comes from one person | Fast options and strong checks; without the checks, the person becomes the verification loop (EV16) |
| Engineer (Torvalds) | Representation, refusal, a user contract with no expiry | Removes special cases (TO8); says no; checks with outside instruments | Doesn't scale by inspecting everything, so trust runs through 5-15 accountable people (TO10) | Fewer special cases and refused features; slow, and it scales only through trusted people (TO10) |

---

## 4. The distinguishing factors, ranked by strength of evidence

"Converged" means all three blind theories (system theory, reasoning acts, loop) reached the factor independently.

**Premise, not a factor: who types does not separate the two.** All three theories converged on this, and it is the most robust finding (CH1, CH13, PR9, PR11, TO17, and EV8, which found no code-level maintainability penalty in a preregistered study).

| Rank | Factor | Evidence | Converged | Falsifier |
|---|---|---|---|---|
| 1 | **"Done" is decided outside the producer**, by a check that can fail and covers more than the runnable slice | Strong. 38% passed maintainer tests, 0 of 15 mergeable (EV3/TH20). About 24 points between grader and maintainer acceptance, against a human baseline that is itself noisy (~68%) (EV4). 29.6% of "plausible" patches diverge from the human fix (TH19). Models special-case or edit tests under pressure (TH15), and telling them not to cheat barely helps (TH16). Anthropic's own docs (CH23) | 3/3 | Fix the model and objectives. If an independently written acceptance check gives the same blind merge rate and lagged rework as a test written by the generator, this factor is wrong. |
| 2 | **Obligations nobody stated** get found from facts outside the prompt | Strong on the failure, weak on the fix. EV9, EV11, EV18, PR7, implicit requirements in EV1/EV3, and the rate-limit miss. Mostly a missing-input problem, not missing reasoning | 3/3 (as tacit theory, as surfacing obligations, as interrogating the brief) | On a sealed seeded-omission corpus, if a plain strongest-model session on vague prompts matches the recall of a state-derived intake, this factor does not separate the two. That is already Felix's I1 falsifier. |
| 3 | **Every miss becomes a standing, mechanical check** in the layer that should have caught it | The most consistent practice in the record (CH5, CH12, CH16, PR10, PR11). Its effect is unmeasured, and CH16's revert drop has no n. Prose rules leak (PR6, TH16) | 3/3 | Count repeat misses of already-corrected classes over a quarter. If they do not fall as checks are added, or fall equally when corrections stay as prose, this factor adds nothing. |
| 4 | **Assurance and attention are set by consequence and horizon, not difficulty** | Good. CH3, CH14, CH20 (93% of permission prompts approved), TO5/TO18, PR9, PR2, TH22. Caveat: "outside my expertise" is partly a difficulty criterion | 3/3 | At a fixed review budget, if consequence-tiered review gives the same defect-escape rate as uniform review, this factor is wrong. |
| 5 | **The producer cannot certify its own work**, and a named person signs, together with a statement of the gaps | Good on the first half, but split. People's self-assessment is unreliable (EV1, superseded by EV2 on the speed figure; EV10; TH11), and EV16 shows the checking gap. Models game proxies and stop on appearance (TH15, TH16, CH23). No finding measures a producer's report on its own blind spots directly. The practice is clear (TO14, TO20, CH14). The value of a gap statement is unproven | 3/3 | Compare changes accepted on the generator's own verdict with changes accepted by an independent party. If their revert and incident rates match, the factor is wrong. Separately, seed known gaps: if worker gap lists miss them, those lists are narration. |
| 6 | **Reasoning moves the model can make but does not trigger**: interrogating the brief, a premortem, stepping back when a proxy conflicts with the spec, proposing something simpler | Moderate, from 2025-era models, and model-specific. Sonnet 4 detected underspecification 74% of the time with a neutral prompt and 89% with encouragement, but rarely acted on it, and interacting improved results by up to 74% relative (TH18). Also CH19, PR6, TH15. The host may already be absorbing these moves: interview patterns are documented (CH23) and plan mode was reportedly dropped (CH8) | 3/3, all as hypotheses | Rebuild the underspecification test on the current strongest model. If unprompted behaviour reaches the prompted rate, the move has been absorbed. In the experiment, if triggered moves add nothing over the verification-only arm, the factor is wrong for this generation. |
| 7 | **Architecture lives in the aggregate of changes**, so a design record has to govern each change against the ones before it | Weakest of those kept. PR8 is confounded (non-engineers) and dated by its own witness; TH2 is an anecdote; EV12 is vendor data and correlational; EV8 cuts against it | 3/3, as a hypothesis | Run a sequence of K dependent agent changes and measure mechanically: duplicated mechanisms, special cases, half-finished migrations, the ratio of moved to copied code. If changes reviewed one diff at a time drift no more than changes checked against recorded decisions, the factor is wrong. Blind "extends or patches" labels are circular by Naur's own premise, so they cannot be the primary measure. |
| 8 | **A person who understands the system** remains somewhere | Contested. EV6 (junior engineers) and EV7 (novices, a single author) show comprehension loss when thinking is delegated, and recovery when explanation is forced. CH18 names a "paradox of supervision". TO3 and PR2 put understanding at the centre. Against this, CH15's team says nobody needs a full mental model | Central for two theories; the weakest point for the third | If a comprehension gate on high-consequence changes shows no effect for experienced engineers on real repositories, a loop of checks alone is enough. |
| 9 | **Representation and subtraction**: choosing the model that removes special cases, and refusing or cutting scope | Anecdotal but consistent (TO2, TO6-TO8, PR5, PR6, PR14, CH11). Felix has no mechanism for this | Named by one theory, folded into factor 7 by another | Run the same tasks with model-default versus expert-directed representation. If later change cost is the same, the factor does not separate the two. |

The first five survive every refutation with only minor rewording. Factors 6 and 7 are hypotheses worth testing. Factor 8 is the place where the rival in section 9 bites.

---

## 5. How AI reasons today versus how the best engineers reason

| Moment | What the best engineers do | What the model does today | What a vague prompt leaves undone | What the person does not know was needed |
|---|---|---|---|---|
| Before code | Treat the request as a draft with errors, and debug the specification (TH5, TH14). Make the model ask (CH19) | Treats the spec as complete. Often detects ambiguity (Sonnet 4: 74% under a neutral prompt) but rarely asks unprompted (TH18) | Every ambiguity gets settled silently by the prior | That decisions were made for them at all |
| Finding what is owed | Recognise the situation's class and run it forward in their head (TH11). Torvalds counts any user-observed breakage as a bug (TO11) | Builds the stated function. Misses security when unasked (EV9), business rules and local patterns (EV11), and identity keys (PR7) | Rate limits, authorization, idempotency, consumer contracts, house conventions, docs and coverage | The whole category. "Prompt better" cannot fix what the person cannot name. |
| Choosing the shape | Fix the data representation and interfaces first so special cases vanish (TO6-TO9). Keep code local and plain for a limited reader (PR13) | Defaults to the usual pattern, even against deliberate local design (PR5) | The representation gets chosen implicitly, and later change costs follow from it | That a choice with long consequences was made |
| Committing to a plan | Premortem: assume it already failed and list why (TH12) | Executes the plan forward | No failure analysis | The failure modes the premortem would have listed |
| Proxy conflicts with spec | Go back to the spec or design | After repeated failures, special-cases or edits the tests (TH15) | Green tests while the intent is violated | That "passing" was bought by changing the test |
| Deciding it is done | Use an outside instrument, see the check fail first, test end to end (PR15, TO6, CH6) | Stops when it looks done (CH23). Declares features complete without end-to-end checks (TH17) | No stopping condition except appearance | That they have become the verification loop, or that nobody is (EV16: 96% distrust AI code, 48% always check) |
| Simplifying | Ask "couldn't you just do this instead?" and subtract (PR6). Say no to features (TO2) | Adds code and scope (PR4, PR6, EV12) | Nothing gets removed, and complexity grows (TH8) | That something simpler existed |
| After a miss | Ask which layer should have caught it, and make the fix mechanical (CH12, CH16) | Fixes the instance inside the session | The same class of mistake returns next session | That this was a class, not a one-off |
| Across changes | Check whether the change extends the design or patches around it (TH2, TH3). Record rejected alternatives and mark unknowns (TH7) | No memory across sessions (TH17). Produces locally valid but divergent patches (TH19) | Each change justified locally while the whole drifts (PR8) | That the architecture is eroding, since no single diff shows it |

What the table shows: the model's gaps are concentrated at boundaries (start, commitment, conflict, finish, after a miss, across sessions), not in writing code. Some gaps are triggers. Others are missing facts. Some, the self-grading ones, no amount of prompting can fix.

**A vague prompt against a designed architecture.** The two differ less in detail than in what gets decided, and by whom. A vague prompt lets the model's prior settle every ambiguity, the representation and the stopping point, without saying so. A designed architecture records those choices, the alternatives rejected, and the checks that would show them wrong. A longer prompt cannot close the gap, because it cannot name obligations the person does not know exist.

---

## 6. What it means for Felix where the capability and trust planes meet

**Is this "beyond plugins"? Yes.** In the capability plane, the unit is the obligation and how it is supplied, not a plugin. Plugins, skills and models are rented suppliers. So are reasoning moves and independent check-writers. Felix owns the frame:
- which obligations the work owes;
- when a move fires, from recorded state (I7);
- who writes the check, recorded on the lease (I5);
- which units of work exist, in what order and isolation (the Execution Coordinator);
- retirement on attributed outcomes (I6);
- what the output binds in the trust plane.

Section 13 lists the rest.

This is the thesis's I1-I7 applied to the founder's question. It is not a new architecture.

**Built today** (felix-home unless stated; path tiers, the obligations ledger and tree receipts also run on every governed project):
- the Stop hold, the gate and deny rows;
- tree-bound receipts, which go stale when the tree changes;
- UNKNOWN holds (felix-home only);
- path-based risk tiers in risk.tsv;
- probes.sh and facts.sh;
- the candidate request/answer protocol: 22 candidates proposed, 0 admitted;
- read-before-install and the risk=high refusal;
- blind authorship, as a pipeline convention only;
- the leakage codebook (70% agreement between readers);
- lessons and CLAUDE.md doctrine, which is Cherny's correction-to-rule loop done by hand.

In short, Felix is a strong "no" and a weak "yes". It performs no unattended capability act, because no dispatch exists, and the router's precision is about 2%.

**New. Each piece maps to a factor from section 4:**

1. **The acceptance standard as a standing record (factors 2, 7).** Extend the need ledger beyond "what must exist" with:
    - preservation rows (what must stay true: identity keys, observed consumer contracts, deliberate departures from the usual pattern);
    - assumption rows, each naming what would invalidate it;
    - decision rows with the alternatives rejected.

    Every row is grounded in OBSERVED or DECLARED facts (I1). Derivation from tests, consumers and revert history is advisory until admitted. The founding case, the missing obligation, stays the priority. Preservation rows add to it and do not replace it.
2. **Independent "done" (factors 1, 5).** The capability plane allocates who writes the acceptance check. It is never the producer (I5). The check counts only after it has been shown failing on seeded mutations of an implementation, decoupled controls included (invariant 5). Failing on an empty tree is not enough, because a check keyed on a lexical shadow fails there too. Every dispatched worker's answer file must list what it could not build, test or reproduce, as the kernel requires for bug-fix work (TO20). A missing list is a hold. A worker's gap list feeds the residual only after that worker's lists have named seeded gaps in qualification (section 12, item 5).
3. **Moves fired by state (factor 6).**
    - Interrogation of the objective at start, with ASSUMED as the default tag.
    - A premortem when a plan is committed.
    - A proxy-conflict detector whose deterministic part is the count of edit/test cycles on one file and the count of review rounds (TH15, CH16). Test edits are found by path and by test-module markers. A Rust hunk whose `#[cfg(test)]` header falls outside the hunk needs whole-file parsing. "A change not about tests" and "test-specific comments" are semantic judgments, so they stay advisory.
    - A simplification proposal before acceptance.

    Each move only proposes rows. This half may depreciate with each model generation, so it is built after items 1, 2 and 4.
4. **The miss-to-layer loop (factor 3).** Each revert, failed gate and incident is joined mechanically to the layer that should have caught it. Founder-leakage turns are classified too, but their labels (70% reader agreement) only propose rows and never justify force. Recurrences are counted. A candidate row or check is filed in that layer, and checks retire on outcomes attributed to them (I6). This is the strongest proposal in the evidence. It builds the class, not the instance, and its output is candidate rows only.
5. **Discharge, not just holds (invariant 3).** Where a reversible obligation has a known remedy, such as adding a request ceiling, Felix will dispatch a worker under a lease to discharge it, once the trust gates of direction row 25 allow dispatch, rather than print a suggestion. Until then, a host session does the work under Felix's holds. Without this, the direction shrinks Felix to its checking half, which the refutations warned against.
6. **Consequence tier (factor 4).** The tier is computed deterministically from what a change touches, using risk.tsv, the observed topology and channels. A model may raise a tier, never lower it (I4). This decides where returns to the person are spent.

**The integration point, in one line:** the capability plane proposes rows, fires moves, writes independent checks and discharges reversible obligations. Admission decides what binds. The trust plane holds changes against admitted rows and prints the residual. The person's input becomes the facts only they hold (product intent, the risk envelope, declared horizon per path), plus admission and authority.

**Constraint from what runs unattended.** Every new piece adds qualification and admission load, and that pair is already the bottleneck at 0 of 22: checkers qualify first, then the founder commits (L12). So the order is: pieces that run with nobody present come first. Those are the proxy-conflict detector run over existing transcripts, the gap-statement field, and the miss-to-layer classifier run on existing sessions. Nothing new arms a hold until a derived row has been admitted and its checker qualified.

**What Felix must not do**
- **Do not let a model clear anything.**
    - Model output may only file candidate rows or advisory notes.
    - A hold arises only from an admitted row checked mechanically.
    - OBSERVED status comes only from a probe, and DECLARED status only from a person through a channel a session cannot write. Neither ever comes from a model.
    - A dismissal is a person's typed act or a mechanical one.
    - A teach-back or "understanding" requirement cannot be on the enforcing path. A presence check of a model-writable explanation cannot fail, which breaks invariant 5, and judging its content would break invariant 2.
- **Do not treat presence as evidence.** A design record or plan file that exists is the equivalent of "RLS is enabled" (EV18).
- **Do not hold every change on rows that read UNKNOWN.** That turns the omission engine into a false-block engine. Bound false blocks before arming.
- **Do not route every model-generated question to the person.** Attention collapses with volume (CH20), and leakage would rise.
- **Do not chase every reviewer finding.** Reviewers asked to find gaps usually report some (PR16).
- **Do not encode one pioneer's current workflow as doctrine.** Cherny re-derives his with each model (CH4, CH8). Encode contracts (trigger, artifact, independence, persistence), not prompt recipes.
- **Do not treat provenance tags, self-report or agent approval as trust signals.** Disclosure is fine, but it is not the signal (TO14, TO19, CH14).
- **Do not call vibe coding bad.** Cherny and Torvalds both use it on purpose (CH3, TO5). The defect is putting it in the wrong place.
- **Do not claim Felix holds a system's theory, makes models reason like engineers, or removes the need for understanding.** Naur's limit (TH3) and the comprehension evidence (EV6, EV7) stand against all three.
- **Do not make the founder the holder of the engineering theory.**
- **Do not cite the WRONG or UNVERIFIED items:** PR12, EV17's added details, EV19's counts, CH10's six-month rule, TH6's MMM wording, TH13's habits.

---

## 7. How to say what Felix does

Every candidate sentence the theories drafted overclaimed in the present tense. Two rules follow from the anti-slop contract: outside text claims only rows marked built, and unbuilt work goes in Status.

**What Felix is for (state it as a direction, not as a current capability):**
> The same model writes throwaway code and engineered code. The difference is what the work is held to. Felix is being built to hold a project's work to what it owes, including what nobody asked for, checked by something other than the thing that wrote it, and to say plainly what it has not checked.

**What is true today, on Felix's own repository:**
> Felix will not let a session call its work done while a hold is open. It binds each passing check to the exact revision it ran on and marks it stale when the tree changes. On its own repository it holds on unknowns instead of reporting them as passes. Felix can ask a model to propose what a project owes, and keeps only proposals grounded on what its probes observe. None of the 22 proposed so far has been admitted.

Notes on wording:
- Describe the user's role as supplying what only they can know: what matters, how much risk is acceptable, and what is throwaway. Do not describe it as "doing less engineering".
- Avoid these words: production-ready, one prompt, no engineering needed, understands your code, thinks like a senior engineer, better vibe coding.
- Cite the pioneers only as evidence of the pattern, never as endorsement.
- Any number quoted (seeded-omission recall against a plain strongest-model session, leakage per objective, false-block rate) is quoted only after it has been measured.

---

## 8. The first experiment

**Zero-token pre-checks, run first, no founder involved:**
1. Run the proxy-conflict signals over existing founder session transcripts, and count how often they fired before a founder correction.
2. Classify the leakage turns already coded in batch 2 by "which layer should have caught it", and count recurring classes.

These test the two cheapest pieces on data Felix already has.

**Main run: added arms on the sealed seeded-omission protocol** (settled 10-01, not yet run).
- **Ecosystems:** Elenchus (Python web), Veldra (Rust) and an unrelated bash project. felix-home is scored separately, because there Felix judges its own repository.
- **Objectives:** each ecosystem gets a sequence of five dependent objectives, given as vague one-line prompts.
- **Seeds:** blind seed authors, who never see the arms or the move designs, derive the planted obligations and preservation invariants from each repository's history. This repairs the circularity the refutations found.

**Arms.** Every arm uses a model pinned by full id. A second model family judges, to avoid same-vendor grading.

| Arm | What it tests |
|---|---|
| A+: the strongest composite of off-the-shelf parts: the strongest model by full id, host memory and side agent on, the host's native validator, an independent third-party reviewer, and AGENTS.md rules written from the same misses | Baseline. C against D isolates the ledger. |
| A-weak: A+ on a fixed weaker model | Size of the model effect |
| B: A+ plus an acceptance check written independently of the worker, and the worker's gap statement | Verification only (factors 1, 5) |
| C: B plus state-triggered moves (interrogation, premortem, proxy-conflict halt, simplification proposal) | Whether triggers add anything beyond checks (factor 6) |
| D: C with rows that Felix derives unattended from the repository, with no answer key given | Felix's omission capability itself (factor 2) |
| E: C plus the miss-to-layer loop carried across the five-objective sequence | Persistence and drift (factors 3, 7) |

**Measures, declared in advance:**
- recall of the seeded items, scored by held-out differential tests;
- merge decision by a blind reviewer who is not the founder;
- lagged rework and reverts;
- mechanical drift measures across the sequence;
- false-block rate against a bound declared before the run;
- leakage per objective, using the codebook;
- tokens and dollars.

Report intervals; n is small.

**What would change the direction:**
- **B roughly equals C:** the value is independent checks, not triggered reasoning. Cut the move-firing and invest in check-writing and discharge.
- **The model swap (A+ against A-weak) moves results more than any loop arm:** the capability-plane direction loses its basis for this generation. Re-run each generation.
- **D's recall is roughly A+'s:** Felix cannot yet derive what nobody stated, and the omission-engine claim stays unproven. If C also matches D, this is section 13's "only dispatch" result: investigate it under roadmap §5 as amended before changing where derivation sits in the lane order (direction §5). Either way it is not a thing to claim.
- **Gains come only from more blocking:** the result fails, whatever the recall.
- **E shows less drift and fewer repeated miss classes than C:** the standing record is the asset to build first.

**Precondition.** Unattended dispatch needs its own credential and a spending ceiling sized against the weekly token allowance. Supplying both is the founder's act. Both are needed but not enough: unattended dispatch also waits on the trust gates of direction row 25 (the step 15 judge pin and the arming sitting), and dispatch beyond the one attended D3 tick (direction row 17: one attended dispatch before March under a dollar cap) is not before March. Until then, any run with a person in the loop is reported as a pilot that a person ticked, and it does not count as Felix progress.

---

## 9. The strongest rival explanation

**The rival: ownership over a time horizon.** On this view, a result is engineered when a specific person intends the code to live, will answer for it, and holds or deliberately rebuilds its theory. Checks, loops and rules are what such a person builds. They are symptoms of ownership, not its cause.

The rival fits the evidence well:
- Cherny's line is about lifespan and placement (CH3).
- Torvalds vibe-codes only where he accepts no maintenance burden (TO5, TO12).
- DHH's designers worked inside 37signals' review process and still drifted, while Lopopolo's owning engineers did not (PR8 against PR11).
- The kernel kept the one thing that binds a person, the Signed-off-by (TO20).
- Anthropic's team keeps "owning the outcome" for humans (CH14).

A narrower variant, "acceptance-function coverage" from the first refutation, says the difference is simply how much of the true acceptance standard is enforced, with no theory-holder needed. That variant is largely what section 1 adopts. The synthesis took it over and demoted "the system's theory" to a hypothesis (factor 7).

**Does ownership win? Not outright. It takes one point.**
- **Where it loses.** It cannot explain why owners with the same intent still miss unstated obligations (EV1, EV3, and the rate limit, which an owner missed). It cannot explain why owners need outside instruments because their own confidence is wrong (EV1, EV10). Ownership is necessary, not sufficient.
- **Where it wins.** Felix cannot supply ownership. The rival also predicts something the main answer must face: for a person who does not own or understand the system, Felix's returns ("what is the risk envelope?", "should this exist?") will get low-resolution answers or rubber stamps. So the gains from arms B to E should be largest where an owner already exists. That cuts against the endgame's novice case, where expert and novice differ only in the resolution of the constraints they supply.

**The honest position.** Felix is designed to supply three of the four parts: obligations of known classes, from observed and declared facts; checks written under a separate lease (by the same vendor's models until the second-family author runs); and persistence. Of the three, only persistence is partly built for another project today (the ledger and tree receipts); derived obligations and separately leased checks are not. The fourth, a person who answers for the result, it cannot supply. It can make the answer precise, current and bounded: a signature over a hash of what was not checked at or above the release's consequence tier, void when that changes (section 12). That is a proxy for ownership, not ownership. The test that separates the main answer from this rival is to hand a working loop to a non-owner and see whether it still produces engineering. Section 12 designs it.

---

## 10. The full answer, attempted

### What "full" is measured against

A full answer here is measured against engineering, not against perfection. Five limits in section 11 (L1 to L5) bind Felix exactly as they bind Cherny's team and the kernel:

- facts that do not exist yet;
- undecidability;
- the first instance of a class nobody has met;
- the unchecked base at the bottom of every chain of checkers;
- a standard nobody can fully state.

Nobody calls those teams' work vibe coding because of these limits. So the test is this. Starting from a person's vague sentences, is the work held to the standard an engineering team would hold it to? That standard is section 1's four parts. Factors 6 to 9 are the hypotheses about how engineers meet them, and the table scores them too. And does the person spend time only on the facts and the authority that only they hold? Measured against engineering, a full answer may exist. Measured against perfection, none exists, for Felix or for anyone.

### Marks

Each part gets one mark:

- **Now.** No untested assumption is needed. The part may still be unbuilt, or waiting on a trust gate. The status column says which.
- **Assumption.** Reachable if a named assumption holds. The test is named.
- **Out of reach.** No mechanism inside the invariants supplies it.

Status words follow the intent design:
- **built**: in the engine;
- **specified**: written in v3.2, the amendments, the thesis or the 0cw handoff;
- **new**: not built; proposed in the intent design or in this brief.

### The parts

| # | Part | Mark | Assumption and its test | Status and gate |
|---|---|---|---|---|
| F1 | **Owed, by class.** Obligations that follow from observed topology. Examples: public ingress plus a paid upstream owes a request and spend bound; identity joins on an internal id, not email (PR7); row-level security must make a constructed cross-tenant read fail, not merely exist (EV18). | Assumption | **A1:** most consequential omissions are instances of recurring classes. Tests: (1) on the sealed corpus, arm D against the composite baseline (§13); (2) the share of confirmed real misses that can be written as a class row passing blind sibling fixtures (intent design, falsifier 6). | Probes and facts built. The situation compile is new: intent design slice 1, report-only, no trust gate. |
| F2 | **Owed, by declaration.** Who may see what, retention, horizon per path, the risk envelope. | Assumption | **A2:** the person can answer outcome-phrased questions at the resolution a row needs. Where they cannot, they choose reliably between working options (TH5, CH11; CH11 describes an expert team). Tests: count of defaults later reversed, returns per objective, and the arms in §12. | `decisions.tsv` TTY writer new (founder decision a). Thin working options need leases (direction row 25). |
| F3 | **Owed, but stated by nobody and in no class.** Project business rules (EV11), and the first instance of a class nobody has met. | Out of reach as derivation | Elicitation narrows it: F2's working options, and prediction items (hypothesis A7, §12). But rented models write the questions, and models of that kind miss business rules. The owner's resolution caps it too. Human teams also miss the first instance. | – |
| F4 | **A check outside the producer, seen to fail,** for classes a machine can check. | Now, for non-model instruments. Assumption, for model authors on separate leases. | **A3:** a check written on a separate lease from admitted rows, and qualified on seeded mutations, discriminates where a producer-written test does not. Tests: corpus arm B against arm A+; I5's same-family against cross-family arms. | Controls 1-6 built, for Felix's own checks. Control 7 absent. Arming on other projects waits on control 7 and the judge pin. Leases wait on row 25. |
| F5 | **A standing record,** with every miss turned into a class-level check. | Assumption | **A4:** mechanical standing checks cut repeat misses more than prose rules do. Prose rules leak (PR6, TH16). Tests: a quarterly repeat-miss count against a prose control; arm E against arm C. | Ledger, tree receipts and staleness built. `misses.tsv` and `felix retro` new (slice 2). |
| F6 | **Assurance set by consequence,** raise-only. | Now | Factor 4's falsifier stands. | Path tiers built. Computed tier specified. |
| F7 | **Supply.** A leased worker discharges a reversible gap instead of Felix printing a suggestion (invariant 3). | Assumption | A3, plus a bounded false-block rate. Test: arms D and E, counting obligations discharged autonomously (thesis §5 guard). | Specified (invariant 3; thesis I2, I3). No dispatch exists; gated by direction row 25, and dispatch beyond the one tick is not before March (direction §5). |
| F8 | **Representation, recurring cases** (PR7, EV18, PR13). | Assumption (A1) | As F1. These are class rows. | New |
| F9 | **Representation, novel and long-lived choices:** data model, identity, wire and storage formats, public interfaces. | Assumption for the choice. Out of reach for insight. | **A9:** choosing among k alternatives matches expert direction on later change cost. The choice uses admissibility, a Pareto front over computed attributes, and a measured cost of the next declared increment. Test: factor 9's falsifier. Irreversible differences go to the person (intent design §5). Out of reach: elegance, and any idea none of the k alternatives contains. | Pareto selection new. Look-ahead spikes need leases. |
| F10 | **Subtraction.** | Now, for refusal by trace. Assumption, for deletion. | Refusing a unit that implements a non-goal or cites no decision needs no assumption. **A10:** accepting a deletion is safe when the same receipts pass on strictly less code. Test: revert and incident rate of those merges. Until A10 is tested, deletion runs only where all three hold: the component's residual is empty, observed-consumer rows exist, and a differential test against prior behaviour passes. Elsewhere, orphans are reported. Refusing a feature stays the person's (TO2). Felix shows its price when the decision is made. | Trace rule new. Orphan report new. |
| F11 | **Architecture across changes: structure.** | Assumption | **A5:** two things track drift: structural relations derived from the chosen plan, and git measures. The measures are copied against moved lines (EV12's shape), co-change across component edges, and migration age (CH12). Tests: a zero-token check of whether these measures rise before reverts and fix commits on Elenchus, Veldra and felix-home; then a K-step sequence. | New |
| F12 | **Architecture across changes: design fit** ("extends or patches", TH2, TH3). | Out of reach as a verdict | A model's judgment cannot sit on the enforcing path (invariant 2). A blind label is circular by Naur's own premise. The capability plane can still supply design fit as advisory review (L9). | – |
| F13 | **Stand-in for the theory: the record.** Decisions with rejected alternatives (TH7). Assumptions with what would invalidate them (TH8). | Assumption | **A6:** a record lowers the cost of change K+1 to a fresh session. Test: a K-step sequence run with and without the record, with change K+1 measured mechanically (time, defects, drift), as EV8 measured downstream evolution. Not a quiz on where code lives, which models pass from the code alone. | New |
| F14 | **The theory: a person's comprehension.** | Out of reach | It cannot be enforced. A presence check on an explanation a model could write cannot fail (invariant 5). Judging the explanation's content puts a model on the path (invariant 2). EV7's gate was an LLM judge. | – |
| F15 | **Someone who answers: the stake.** | Out of reach | – | – |
| F16 | **Someone who answers: the precision of the signature.** | Assumption | **A8:** a signature over a hash of what was not checked at or above the release's consequence tier, void when that changes, gives better outcomes than an approval with no stated scope. Test: §12's arms. | New. Follows the `exceptions.sh` pattern (built). |
| F17 | **Reasoning moves at boundaries:** interview, premortem (TH12), proxy-conflict halt, simplification. | Assumption, and depreciating | **A11:** moves fired from recorded state add value over independent checks in this model generation. Test: arm C against arm B, re-run each generation. TH15 and TH18 are from 2025-era models. | New. Its deterministic half (edit/test cycle counts on one file, review-round counts) would be mechanical; none of it is built. |

### What the table says

- **For a person who owns the product,** every part is "now" or "assumption" except F3, F12, F14 and the insight half of F9. F15, the stake, is out of reach for Felix, and the owner supplies it.
    - Half of F3, the first instance, binds human teams as well. So does F12: their judgment of design fit belongs to people, and people get it wrong (TH2, PR8).
    - F14 is contested. Anthropic's team says nobody needs a full mental model (CH15). Naur says the theory cannot be rebuilt from documents (TH3).
    - So, measured against engineering, a full answer for an owner is probably reachable. It has one contested gap (design fit, and the theory behind it) and one bound: the owner's own resolution on F2 and F3. Felix goes for it.
- **For a person who will not own the product,** F15 is out of reach, and F2, F3 and F16 weaken with the person's stake. The answer is partial.
- **Which of the two holds is an empirical question.** §12 designs the test.
- **"Reachable" is a claim about design and evidence, not status.** Apart from path tiers (F6) and the ledger and tree receipts (F5), none of these parts is built for another project today. The numbers that decide how far it goes: 0 of 22 candidates admitted, and 0 lander merges.

### Three claims this section keeps out, because the attempts showed them wrong

1. **"The non-engineer only chooses, predicts and signs."** No finding supports this. CH11 is an expert team picking among prototypes. TH18 measures models, not people. Prediction items enter only as hypothesis A7.
2. **"Admitting rows at class level fixes the 0-of-22 bottleneck."** It does not. Every candidate's checker was found flawed on blind re-check (thesis I2). Qualification binds first, then admission (thesis §8).
3. **"A check seen failing on an empty tree meets invariant 5."** It does not. A check keyed on a lexical shadow also fails on an empty tree. Only the decoupled controls separate the two, and they need an implementation to mutate (`qualify.sh` header).

## 11. Where it stops

The limits fall into four groups:

- **11a** binds engineering itself.
- **11b** separates engineering from vibe coding, and Felix cannot supply it alone.
- **11c** is contested.
- **11d** is a gap in Felix today, and engineering work can close it.

### 11a. Limits of engineering itself

Felix inherits these exactly as any team does. They do not stand between Felix and engineering.

| | Limit | Hard or soft | Evidence | What Felix does or would do (status in section 12) |
|---|---|---|---|---|
| L1 | Facts that do not exist yet: future users, load, attackers, rules, the person's later intent | Hard | Assumptions decay as the world moves (TH8). Clients cannot specify a system before trying versions of it (TH5). | Records each assumption with what would invalidate it, and marks it STALE when its grounding fact moves. Maturity rows owe post-deploy verification and rollback whatever happens later (intent design §6). |
| L2 | No general procedure decides what a program does, so every check covers only a stated claim | Hard | 29.6% of plausible patches diverge from the human fix (TH19). 38% passed tests, yet 0 of 15 were mergeable (EV3). | Receipts are "valid for their explicit claims". Felix never says "proven" or "production-ready". |
| L3 | The first instance of a class nobody has met | Hard at any moment; eases with each confirmed miss | The intent design's own example finds timestamp re-identification only after an incident (§3, step 11). Experts build their library of situations from feedback (TH11). | One class row per confirmed miss, shared across the home. Prints the vocabulary version and the count of last quarter's misses outside it. That count is a lagged lower bound, not an error bar. |
| L4 | Every chain of checkers ends at a base nobody checked | Hard that the chain ends; soft where it ends | One authority still writes the work and its judgment (amendments §6). Confidence tracks coherence, not accuracy (TH11). | Ends the chain in a non-model instrument wherever the class allows. Writes cross-family authorship on the lease, never into a receipt condition. Claims no independent acceptance before the judge pin. |
| L5 | A check suite stands in for a standard nobody can fully state, and producers satisfy the stand-in | Hard while the standard stays unstated; the ratchet is soft | Tests are special-cased under pressure (TH15). RLS was checked for presence, not sufficiency (EV18). Maintainers would merge only about 68% of the original human patches, so the owners' standard is itself noisy (EV4). That figure is a noise baseline, not a ceiling. | Bounds false blocks before arming. Gives rows force only from lagged, independent catches. Scores "better" only on the sealed corpus. Judges a row's value by replay on the sealed corpus and on misses after the row landed, never on its founding miss, which it always catches. |

### 11b. What separates engineering from vibe coding, which Felix cannot supply alone

| | Limit | Hard or soft | Evidence | What Felix does or would do (status in section 12) |
|---|---|---|---|---|
| L6 | A party with a stake, who answers for the result | Hard | The kernel keeps the human Signed-off-by (TO20). An agent's approval never counts as a person's (CH14). Trust scales through accountable people (TO10). The line between vibe coding and engineering follows lifespan and maintenance (CH3, TO5, TO12). | The owner contract (§12). Prints "unsigned" and "no named owner". Routes accountability to each project's owner, never to Felix's founder. |
| L7 | Facts only a person holds: business rules, who may see what, how long a part must live | Soft (they can be asked), but capped by the person's resolution | AI misses business rules and local patterns (EV11). Whether RLS is sufficient depends on who should see what (EV18). Clients do not know what they want (TH5). | Asks only when the answers change what is owed, phrased as outcomes and batched. Offers working options where a description would get a low-resolution answer (CH11). |
| L8 | Elicitation inherits the blind spots of whoever writes the questions | Soft in mechanism, binding in practice | The question writer is a rented model, the kind that misses business rules (EV11) and fills gaps from its prior (PR5). | Writes questions on a lease that never saw the builder's plan. Samples prediction items across the product surface, not only from the residual. Lets answers add holds only. Prints the share of later misses that no question touched. |

### 11c. Contested

| | Limit | Hard or soft | Evidence | What Felix does or would do (status in section 12) |
|---|---|---|---|---|
| L9 | Design fit across changes | Contested in principle; hard for the enforcing path | Naur: a theory cannot be rebuilt from documents (TH3), and locally correct patches destroyed a compiler's structure (TH2). Against: a similar theory rebuilt by experiment (TH23); Anthropic's team says nobody needs a full model (CH15); no code-level maintainability penalty on a scoped feature (EV8). PR8's case is dated by its own witness to February 2026. | Holds structural rows and drift counts. Would supply an advisory design-fit review written by a second model family, once the Codex read-only author runs (direction row 19). The review fires deterministically on the three-round cap (CH16), on repeated edit/test cycles (TH15) or on a drift count. It goes to the person when consequence demands (I2's person route). It files candidate rows, never a hold. Prints "design fit not checked" on any change that touches a recorded decision without that review. |
| L10 | The person's comprehension, which erodes as Felix succeeds | Soft evidence; the direction is structural | Delegating the thinking cost comprehension, most of all in debugging (EV6, junior engineers). An explanation gate cut later failure (EV7: novices, LLM judge). Anthropic names a paradox of supervision (CH18). | Cannot enforce comprehension (invariants 2 and 5). Phrases every return as what it commits the person to. Counts returns that cannot be phrased that way, and treats a rising count as a defect. Offers explanations on request, never as a gate. |

### 11d. Gaps in Felix today

| | Limit | Hard or soft | Evidence | What Felix does or would do (status in section 12) |
|---|---|---|---|---|
| L11 | Attention collapses with volume | Hard that attention is finite; soft how much Felix spends | 93% of permission prompts are approved (CH20). 22 candidates have waited since 09-26. The router runs at about 2% precision, with 106 declines (direction §2). | Prints a return budget per objective beside recall. Turns an answer that never varies into a default. Treats a return left past a set age as a design defect, not a reason to send a reminder. |
| L12 | Admission: the bottleneck is checker qualification, then the founder's commit | Soft | 0 of 22 admitted. Every candidate's checker was found flawed on blind re-check (thesis I2, §8). | Qualifies before asking for admission. Class rows with blind siblings spread the cost of admission but do not fix it. Decision 2(b), after control 7 and the pin, is the route this brief builds on to take the founder out of this loop. |
| L13 | Materiality reads every fork as immaterial while the tables are young | Soft | Materiality compares blocking sets (intent design, stage 3). New class rows enter at ADVISORY, so the two sets match and the model's prior settles the fork (TH18, CH19). | Computes materiality over blocking and ADVISORY rows until a class has force, and labels such questions "advisory-material". Never takes a default it does not print. |
| L14 | Learning churns the owner's signature | Soft | Each new row at or above the release tier changes the residual and voids the contract. Frequent re-signing drifts to reflex (CH20). | Hashes only items at or above the release tier. Lower additions print as an unsigned delta, folded into renewal. Prints re-signs per owner per month; a bound declared in advance is the falsifier. |
| L15 | Moves the next model absorbs | A clock, not a limit | Sonnet 4 already detected underspecification 74% of the time under a neutral prompt (TH18). The docs ship an interview pattern (CH23). A fan site reports plan mode dropped (CH8). | Builds durable pieces first. Specifies moves as contracts (trigger, artifact, independence, persistence). Re-runs arm C against arm B each generation and deletes any move a plain session matches. |
| L16 | Cost | Soft, but binding now | One corpus at 3 runs costs $96-349, and $172-632 with replication. Spend caps were soft in 39 of 39 runs (thesis §2, §11). Independence adds one to three leases per obligation at B2 and above (thesis I5; intent design §4). | Confines independence to work whose consequence demands it. Runs zero-token checks first. Puts a spend limit on every lease and records each breach. |
| L17 | Same-user state | Soft: a deployment choice, not a principle | Receipts are unsigned files that any same-user process can write, and lease records will be too once leases exist. The server-side wall stands on one of five governed repositories (thesis I5, §9). | Claims tamper-evident only. A separate OS user, a key held off the machine, or a server-side required check would change this. Builds the wall repository by repository and prints which ones have it. |
| L18 | Thin, same-family evidence | Soft | Key Cherny points are secondary (CH8, CH22). Ownership of the claude.dev domain is unconfirmed (CH14-CH16). The comprehension studies are of learners (EV6, EV7). Most findings on model behaviour come from 2025-era models (TH15, TH16, TH18, EV3). Every sweep, theory and refutation behind this brief came from one model family. | Gives enforcing force only to factors 1-5. Parts resting on factors 6, 7 and 9 (F9, F11-F13, F17, and F10's deletion half) stay advisory or assumption-marked until their tests run; F10's refusal by trace needs no assumption. Has the Codex read-only author read the claims this brief acts on. |

None of this removes the founder from the landing loop (0 merges). Decision 2(b) is the route this brief builds on to take the founder out of the admission loop, and only for task-blocking rows. Felix says so whenever it proposes these pieces (direction §3).

## 12. The probable partial answer

### The binding rule

A row binds only when all three of these hold:

1. **Its deciding fact is recorded.** A probe observed it, or a person declared it through a channel a session cannot write. That channel is tamper-evident, not tamper-proof.
2. **Its property belongs to a known class** that a machine can check.
3. **Its checker stands outside the producer.** The checker has been shown failing on seeded mutations of an implementation, decoupled controls included.

Everything else is either a typed return to a person or printed residual. Supply sits beside this rule, not under it. Felix also discharges reversible items, plans units, writes leases and builds options, and none of that waits for a row to bind.

### What is true after it is built

Each item ends with its status as of 10-19.

1. **Each governed project carries a standing list of what it owes.** Fixed class rules derive it from observed topology and declared facts, including obligations nobody stated. It prints as "M of N" with a residual.
    *Status: probes, facts and the candidate protocol built; 0 of 22 admitted; situation table and residual new.*
2. **A change is done only when every active blocking row has a receipt for this revision.** The receipt comes from a checker written on a lease other than the builder's and qualified on seeded mutations. UNKNOWN never reads green.
    *Status: tree receipts and the Stop hold built; UNKNOWN holds on felix-home only; control 7, leases and the pin unbuilt.*
3. **Assurance follows what the change touches.** A model may raise the tier, never lower it.
    *Status: path tiers built.*
4. **Every miss becomes a candidate class row.** Each revert, failed gate and incident is joined mechanically to the layer that should have caught it. The resulting row is tested on blind fixtures and a prevention replay, and enters at ADVISORY. Task-blocking force depends on founder Decision 2(b) and intent design §11d.
    *Status: new.*
5. **Reversible gaps are discharged by a leased worker.** The worker must list what it could not build, test or reproduce. A worker's list counts only once that worker's lists have named seeded gaps in qualification.
    *Status: no dispatch; gated by row 25.*
6. **Questions go out only when the answers change what is owed.** They are phrased as outcomes and batched. Where a description would get a weak answer, the person picks between thin working options.
    *Status: new; the options need leases.*
7. **Felix owns which units of work exist, their order and their isolation,** with coverage checked both ways:
    - every blocking need has a unit;
    - every unit traces to a need or a decision;
    - a unit that implements a non-goal is refused;
    - orphans are reported.

    *Status: partition built in `shape.sh`; the rest new.*
8. **Each release target above prototype carries an owner contract** (below).
    *Status: new.*
9. **Every verdict carries its residual line.**
    *Status: residual line unbuilt; UNKNOWN holds exist on felix-home only.*

### The owner contract

The contract follows `exceptions.sh` (built). It is a person's dated row, keyed by hash to what it covers. Felix reads it only from the remote-tracking main. It takes effect only through a merge, and that merge is an escape a person takes.

- It names the owner, a horizon per path class, an expiry and an incident route.
- It signs a hash of the residual at or above the release's consequence tier.
- It is void when that residual changes, and the hold prints the difference.
- It never clears a blocking row. A release-blocking UNKNOWN still needs a qualified instrument or a policy route (amendments §3).
- A declared horizon may lower the tier, but never below an observed floor. Public ingress, a paid upstream, identity data or an observed consumer forces at least "maintained" (new; it extends intent design §6's observed floors to a horizon axis).
- A target declared throwaway needs no contract, and every headline calls it a prototype. Felix refuses the label, not the work (CH3, TO5).
- On repositories without the server-side wall, the contract is tamper-evident only.

This makes the answer precise, current and bounded. It is a proxy for ownership, not ownership itself.

### Prediction items (hypothesis A7)

- **How questions are set.** A lease independent of the builder writes forced-choice questions, sampled across the product surface. Example: "A signed-out user opens a review link. Do they see it, get sent to sign in, or get not-found?"
- **The answer key** is the behaviour a qualified scenario observes.
- **A wrong prediction** holds that item until the person either declares the observed behaviour intended or files a defect.
- **A right prediction** clears nothing.

They are reported as a way to draw out business rules nobody stated, never as proof of understanding. No finding supports them yet.

### What stays the person's

- What to build and what not to (TO2, CH11), including product forks that cannot be put in order.
- Facts no probe sees: who the users are, which data is sensitive, what a failure costs, business rules, and deliberate departures from convention (PR5).
- The horizon of each path, above the observed floor.
- Authority:
    - channels, credentials and money;
    - irreversible commitments;
    - any lowering of assurance;
    - release-blocking admission;
    - the rules of Felix's own improvement loop (intent design §11f).
- The signature.
- Representation, where the person reserves it.

Two of these are engineering review: release-blocking admission, and deciding whether a high-consequence design-fit flag matters. Felix's job there is to make those acts rare, qualified in advance and phrased as consequences. It is not to call them something else.

### The residual Felix prints

| Residual | Why nobody holds it | Printed as |
|---|---|---|
| Behaviour beyond what the checks claim | L2 | Each receipt's explicit claim |
| Classes outside the vocabulary | L3 | The vocabulary version, and last quarter's misses outside it |
| Surfaces Felix could not look at | No probe grounds them | "could not look", each surface named; never "dormant" |
| Facts that do not exist yet | L1 | Assumptions, each with what would invalidate it |
| Business rules nobody stated and no question reached | L7, L8 | The share of later misses no question touched |
| Design fit | L9 | "design fit not checked", the drift counts, and whether the advisory review ran |
| Blind spots every model family shares | L4 | Each receipt's independence class |
| The person's understanding | L10 | Nothing that implies it |
| An owner | L6 | "unsigned"; "no named owner" |
| Felix's own base | L4, L17 | "same authority until the judge pin"; "tamper-evident" |

### The partial answer in one paragraph

Engineering differs from vibe coding in what the work is held to. Felix can hold work, deterministically, to the part of that standard where three things are true: the deciding facts are recorded, the properties fall into classes a machine can check, and the checkers stand outside the producer and have been seen to fail. Once this is built, each governed project carries a standing list of what it owes, derived from what probes observe and what the person declared, including obligations nobody stated. Each item is checked on the exact revision by a checker written under a separate lease, and assurance follows what a change touches. Every miss becomes a candidate class row for every project in the home. Leased workers fix reversible gaps instead of printing them, and the person is asked only what changes the outcome. Models write the code, the designs, the checkers and the questions, and nothing a model writes binds by itself. The person keeps what to build and what not to, the facts no probe sees, how long each part must live, authority over costly and irreversible acts, release-blocking admission, and a signature over a hash of what was not checked at or above the release's consequence tier. Felix prints the rest: behaviour beyond what its checks claim, classes it has not yet learned, surfaces it could not see, the future, business rules no question reached, design fit, the blind spots all model families share, its own unchecked base, and a missing owner. For a person who owns the product, this is probably engineering on everything class-level, observable and elicitable, with design fit contested. The measurement below decides whether it is also engineering for someone who will not own the product.

### The measurement that would show it is enough

**Setup.** This is a second experiment, separate from section 8's arms A+ to E. Section 8 asks which parts of the loop add value; this one asks whose answers to Felix's returns are enough. It reuses section 8's protocol, ecosystems and seed-derivation method, with the seed exclusions below. All arms run on the sealed seeded-omission protocol. Each ecosystem gets five dependent objectives, each given as a one-line prompt, and every arm uses the same pinned model ids.

**Arms.**
- **Eng:** an experienced engineer with the strongest composite tooling (section 13) and no Felix. This is the engineering reference.
- **O:** the partial answer, with returns answered by the product's owner, who is not an engineer.
- **Ni:** the same, with returns answered by a non-owner who has everything the owner could write down (decision log, docs, incident list minus the seeds) but no stake.
- **Nb:** the same, with returns answered by a non-owner who holds only the one-line brief.
- **V:** a plain session on the brief, accepted when it looks done. This is the floor.

**Score.** A lagged escape rate per objective, which counts two things:
- seeded items that reach a merged revision unsatisfied, as judged by held-out differential tests;
- reverts and fixes to the change's lines within the 14-day window.

**Seeds.** Blind authors derive them from repository history. Incidents the owner lived through are excluded or scored separately, because otherwise the owner knows the answer key.

**Declared before the run:**
- an equivalence margin;
- a power check;
- a bound on the false-block rate;
- a budget of returns per objective.

**How to read the results** (escape rate, lower is better):
- **Enough:** O lands within the margin of Eng, and the guards hold. If the run is underpowered, the result is "inconclusive", not "enough".
- **Stake against information:**
    - O ≈ Ni < Nb: the effect is information, not stake. The record and elicitation carry it, and the novice case stands for informed people.
    - O < Ni ≈ Nb: the effect is stake. The partial answer holds for owners only, and "no named owner" goes into the headline.
    - O ≈ Ni ≈ Nb ≈ Eng: the full answer holds on these classes for anyone.
- **Short of engineering:** O sits well above Eng while both sit well below V. The residual list shows where the gap is.
- **Gains that come only from blocking beyond the false-block bound:** the run fails, whatever its escape rate.

**Practicalities.**
- **Ecosystems:** Elenchus (Python web), Veldra (Rust), and an unrelated bash project. felix-home is scored separately, because there Felix would be judging its own repository.
- **Participants:** Eng, O and Ni need outside people. Felix's governed projects have one owner, the founder, who is an engineer and lived their histories.
- **A cheap first version** can use the founder's projects with lived incidents excluded, and a model holding only the brief as Nb. It tests the resolution of answers, not stake, and must be reported that way.
- **Status of any run:** with no dispatch, any run is a pilot a person ticked. It does not count as progress under the 10-19 rule.
- **Funding:** like every corpus run, it waits on the founder's spending ceiling.

## 13. What this makes the capability plane

**Beyond dispatch.** Dispatch is only how items get supplied. The capability plane is the frame around capability:
- what is owed;
- by which units of work;
- under which lease;
- checked by whom;
- kept on what lagged evidence;
- the learning that grows the list of what is owed.

Felix rents the labor and the noticing.

**What Factory already does, and where Felix differs.** Factory derives a validation contract from intent inside one mission. The user can skip it, it is not bound to a commit, and it never goes stale. A cross-vendor validator has also been reported, unverified. Felix's intended difference is a contract that would stand across missions, be grounded in observed and declared facts with a denominator, bind to a commit, go stale and block, with independence allocated on a lease. Apart from the ledger and tree receipts, which bind, go stale and block on every governed project, none of it is built for another project yet: derived grounding with a denominator and leased independence are not. Deriving obligations from intent is not, by itself, a Felix advantage.

**Where the two planes meet is the row lifecycle.** This is v3.2's existing boundary, not a new mechanism:
1. The capability plane proposes a row.
2. The trust plane admits it.
3. The capability plane supplies it under a lease.
4. The trust plane qualifies it.
5. The trust plane enforces it through receipts.
6. Outcomes are attributed back, flowing from trust to capability only.
7. The capability plane drafts a strengthening or a retirement, and the trust plane admits it.

### What Felix rents

| Function | Rented from | Dated evidence | What Felix keeps |
|---|---|---|---|
| Labor: code, checkers, mutations, alternatives, spikes | Any host and model | Claude wrote every line of Cherny's 259 PRs (CH1, 2025-12-27). Claude Code wrote Torvalds's kernel series "under my direction" (TO17, 2026-10-11). | The lease each runs under (I3), and who may write which artifact (I5) |
| Picking the cheapest model above a floor | Host and vendor minimizers | Ruling D1 (0cw, 10-01). GitHub, Cursor and Factory ship minimizers (thesis I4, 10-18). | An advisory, raise-only floor by consequence, in full model ids |
| Worker runtime: forks, background agents, spawn | Claude Code | The Agent tool takes `effort` (2.1.292). agent.spawn can rewrite a workflow agent's prompt and model (2.1.300). Forks are on by default (2.1.302). Changelog read 10-18 (thesis §2). | Units of work, their order and isolation (the Execution Coordinator), and the record of what ran |
| In-session noticing and asking | The host | Interview-into-spec and writer/reviewer sessions are in the current docs (CH23, read 10-19). The "You should know" side agent is off by default and only flags (2.1.287). | When a pass fires (I7). Its notes enter as single probabilistic candidates (thesis R6). |
| In-session verification loops | The host | Stop hooks that run until tests pass (CH9, 2025-10-29); `/goal` and Stop hooks in the docs (CH23) | Whether a check binds, and who wrote it |
| A validation contract for one mission | Factory | Derived inside one mission, skippable by the user, not bound to a commit, never stale (market map 09-22, via thesis I1). Factory's 08-27 post occupies derivation from intent (thesis §12). | A contract that stands across missions, binds to a commit, goes stale and blocks |
| Correction memory, as context | Host memories | One CLAUDE.md rule per mistake (CH5, 2026-01-02). Projects shared memory since 09-17 (thesis §12). | Rows proven by replay at the miss tree and held mechanically |
| Review bots and security review | Hosts and review vendors | A blocking security review inside Anthropic's own pipeline (CH14, 2026-10-15). Vendors sell AI review and analysis (EV11, 2025-12-17; EV9, 2025-07-30). | Their output as candidate sources, never as judges. Outcome labels come only from mechanical joins. |
| Risk classification by a model | Hosts | A classifier sets the review tier (CH14). The auto-mode classifier misses 17% of dangerous actions, n=52 (CH20, 2026-03-25). | A deterministic tier from the repository's risk table, raise-only |
| Enforcing lease fields | The host | `--restricted`, `--strict-mcp-config`, tool.check agentId (2.1.290) (thesis I3) | Computing the lease's breadth from the need |
| Provider listings | Marketplaces, Tessl | Thesis §8 | Pinning, read-before-install, tier, revoke |

One agent's sweep on 10-19 reported more. It was not fact-checked, and its dates are the days it read each page, not ship dates:
- difficulty routing at Factory and Cursor;
- a cross-vendor validator in Factory Missions that can be switched off;
- vendor memories that the vendors' own docs call advisory.

Treat these as leads to verify. Each host release that duplicates a Felix mechanism is a candidate for deletion, while the contract stays with Felix (thesis §7).

### What Felix owns

| Owned | Status | Why a vendor paid for the work is poorly placed | Who already holds part of it |
|---|---|---|---|
| A grounded, standing list of what is owed, with a denominator and a residual (I1) | Candidate protocol built; situation table and residual new | A vendor's report on its own blind spots is worth nothing (amendments §2.2) | AGENTS.md in the repository carries rules across vendors, but without grounding or a denominator. Factory holds a per-mission validation contract. |
| Binding: a derived row holds the Stop and the merge | Stop hold, gate and merge boundary built; wall on 1 of 5 repositories | Binding lives in the customer's required checks, and Felix plugs in there | Any CI job or required check |
| Independence allocated on the lease (I5) | A pipeline convention only; control 7 absent | The party paid to finish cannot credibly choose its own auditor (thesis I5) | Independent review vendors (the EV9, EV11 and EV16 sources) |
| The Execution Coordinator: units, order, isolation, coverage both ways | Partition built in `shape.sh` | Renting it gives up v3.2's coordinator and the constitution's "which agent, in which order" | Per-mission coordinators in vendor products |
| The lease (I3) | v0 shape decided, flags measured 10-01; not built | Breadth computed from a need the repository owns survives a change of host | Host flags enforce a lease; they do not compute one |
| A raise-only consequence tier (I4) | Path tiers built | A vendor's tier is a model's output | Anthropic's internal classifier (CH14) |
| Triggers from recorded state (I7) | Specified; the router runs at about 2% | Host suggestions key on the session, not on a project ledger | Vendor event triggers (unverified) |
| Retirement on attributed, lagged outcomes (I6) | Specified | No vendor ranks itself against a competitor on a customer's repository | None found |
| Discharge of reversible items (invariant 3) | No dispatch; gated by row 25 | The vendor does the work. Felix owns which item is owed and what proves it done. | Every agent vendor, for the labor |
| Learning Felix's own tables, scored on a sealed corpus | New | A vendor cannot score its own improvement | Vendor rule-learning from review activity, which is advisory |
| The selection frame for architecture: admissibility, plus a Pareto front over computed attributes | New | – | None found |
| The owner contract | New | – | None found |

### Why the owned part is durable, and how far that goes

As far as these sources show, no single rival holds the whole combination:
- grounded rows with a denominator;
- binding through the customer's gate;
- independence allocated on a lease;
- ownership of which units run and in what order;
- retirement keyed to outcomes.

Each piece has a partial holder.

**Durable in what it rests on.** The combination rests on facts a better model does not change (thesis §7):
- A session ends, but the project's needs persist.
- The party paid to finish cannot be its own denominator or its own judge.
- Grounded state changes while no model runs.
- A model cannot observe risk-envelope facts.
- Qualification evidence does not transfer. A regenerated checker does not inherit the old checker's mutation record (thesis I2).

So the asset that accumulates is evidence, not scripts: class rows with blind fixtures, mutations that real misses produced, and attributed outcomes.

**Not shown durable in value.** That is unmeasured. The threat that matters is not the agent vendors but the forge, because it holds required checks. A repository-owned obligations file with required checks would leave Felix the derivation and the residual, which are exactly the unproven parts. Nothing in this evidence says any forge plans this. It is a hypothesis to watch.

### Where Felix falls short of its own standard today

Felix does not yet meet the independence standard it argues for:
- The same authority writes both the work and its judgment (amendments §6).
- Lease records do not exist yet. Once they do, they are evidence of intent until the judge pin, because state files are unsigned.
- Blind authorship is a convention, and control 7 is absent.
- Until the Codex read-only author runs, models rented from the same vendors whose work they judge write Felix's checkers.
- The wall stands on one of five repositories.

The argument above is about where these pieces belong. It is not about what Felix holds today.

### The one result that would show it is only dispatch

The test runs on the sealed seeded-omission corpus. The composite baseline, A+, is the strongest combination of off-the-shelf parts:
- the strongest model by full id;
- host memory and the side agent on;
- the host's native validator;
- an independent third-party reviewer;
- AGENTS.md rules written from the same misses.

**The result.** Arm D (rows Felix derives unattended) does not beat A+ on recall at the declared false-block bound, and arm C matches arm D.

If that happens, the ledger adds nothing that off-the-shelf parts plus an independent check do not already give. What is left of the capability plane is choosing whom to call, which is dispatch.

- Persistence across a restart is measured in the same run.
- Persistence across a change of host stays untested until the Codex adapter exists (about December), and is stated as untested.
- Under roadmap §5 as amended, this result is investigated before anything narrows.

---

## 14. Open questions for the founder

Only where his judgement is needed.

1. **Who is the novice in the endgame?** Evidence points to ownership as a condition Felix cannot supply. Is Felix's target the person who owns the outcome but lacks engineering expertise, or must it also produce engineering for someone who will not own or understand the code? This decides whether ownership (F15, L6) and understanding (factor 8, L10) are conditions Felix asks of the user, or residual Felix prints ("no named owner" for ownership; nothing implying understanding for comprehension). Felix cannot fill either (section 10, F14 and F15). Section 12's measurement (arms O, Ni and Nb) answers the empirical half; which person Felix is for is the founder's.
2. **Can any derived row class bind without your admission?** This is pending Decision 2(b): only after control 7 and the judge pin, and only for rows whose checkers have qualified (L12; section 10, excluded claim 2). A narrowly bounded class, for example a preservation row derived from an observed consumer contract that may hold a task but never a channel, would remove your commit from the loop, not the qualification step. It widens Decision 2(b) and intent design §11c and is decided with them. This is an authority question, so it is yours.
3. **The unattended credential and a spending ceiling for the experiment.** This is the founder's act that unblocks section 8's corpus run and the cheap first version of section 12's measurement; the full measurement also needs outside participants. Section 6's dispatch and discharge also wait on the trust gates of direction row 25 (section 10, F7).

---

## 15. Sources

Verdicts come from the evidence checks. Items marked UNVERIFIED or WRONG are listed so that nothing above silently relies on them.

| ID | Person | Date | What it shows | URL | Verdict |
|---|---|---|---|---|---|
| CH1 | Boris Cherny | 2025-12-27 | 259 PRs in 30 days, all lines by Claude; measures typing, not decisions | https://simonwillison.net/2025/Dec/27/boris-cherny | VERIFIED (secondary copy of X post) |
| CH2 | Boris Cherny | 2025-05-07 | 80-90% was an estimate; hand-wrote data-model refactors that were costly to explain | https://www.latent.space/p/claude-code | VERIFIED |
| CH3 | Boris Cherny (Business Insider) | 2025-12-16 | Vibe coding is fine off the critical path; critical code is worked plan-first | https://www.aol.com/articles/claude-codes-creator-explains-limits-050709610.html | VERIFIED (secondary) |
| CH4 | Boris Cherny | 2026-01-02 / 03-04 | Plan mode first, many parallel sessions, work as context switching | https://newsletter.pragmaticengineer.com/p/building-claude-code-with-boris-cherny | PARAPHRASE_OK |
| CH5 | Cherny / team | 2026-01-02 | A CLAUDE.md rule per mistake; rules added during review | https://threadreaderapp.com/thread/2007179832300581177.html | VERIFIED (mirror) |
| CH6 | Boris Cherny | 2026-01 / 04-16 | Verification is the top tip; /go skill; "2-3x" is his estimate | https://threadreaderapp.com/thread/2044847849662505288.html | PARAPHRASE_OK (quote from Jan thread) |
| CH7 | Boris Cherny | 2026-04-16 | Looks only at final results | https://threadreaderapp.com/thread/2044847849662505288.html | VERIFIED |
| CH8 | Cherny / Cat Wu | 2026-06-08 | Reportedly dropped plan mode | https://howborisusesclaudecode.com/ | PARAPHRASE_OK (fan site; model details unconfirmed) |
| CH9 | Boris Cherny | 2025-10-29 | Stop hooks until tests pass; subagents check review findings for false positives | https://every.to/podcast/transcript-how-to-use-claude-code-like-the-people-who-built-it | PARAPHRASE_OK |
| CH10 | Cherny / Cat Wu | 2025-09 to 2026-02 | Scaffolding deleted each release; "build for six months ahead" unsourced | https://every.to/podcast/transcript-how-to-use-claude-code-like-the-people-who-built-it | UNVERIFIED (partly verified; not relied on) |
| CH11 | Cherny / team | 2025-09-23 / 2026-03-04 | Prototypes instead of PRDs | https://newsletter.pragmaticengineer.com/p/how-claude-code-is-built | PARAPHRASE_OK (PRD half in 2026-03-04 article) |
| CH12 | Boris Cherny | 2026-03-04 | A lint rule after 3-4 recurrences; finish migrations | https://newsletter.pragmaticengineer.com/p/building-claude-code-with-boris-cherny | PARAPHRASE_OK |
| CH13 | Boris Cherny | 2026-02-19 | No hand edits since November; a human on code except prototypes | https://podscripts.co/podcasts/lennys-podcast-product-career-growth/head-of-claude-code-what-happens-after-coding-is-solved-boris-cherny | VERIFIED (auto transcript) |
| CH14 | Claude Code team | 2026-10-15 | Seven-layer review; tier set by the change; agent approval never counts as a person's | https://claude.dev/blog/solving-code-review-at-anthropic/ | VERIFIED (domain ownership unconfirmed) |
| CH15 | Claude Code team | 2026-10-15 | Nobody holds the full model, and they think nobody needs to; no shared-context process | https://claude.dev/blog/solving-code-review-at-anthropic/ | VERIFIED |
| CH16 | Claude Code team | 2026-10-15 | "Which layer should have caught it"; three-round cap; internal results, no n | https://claude.dev/blog/solving-code-review-at-anthropic/ | VERIFIED |
| CH17 | Boris Cherny | 2026-10-16 | Won't claim the last 10% until attribution is measured | https://x.com/bcherny/status/2111207278653399460 | PARAPHRASE_OK (search result only) |
| CH18 | Anthropic study | 2025-12-02 | Delegation follows verifiability; paradox of supervision | https://www.anthropic.com/research/how-ai-is-transforming-work-at-anthropic | VERIFIED |
| CH19 | Cat Wu | 2025-10-29 | Claude does not ask questions unprompted | https://every.to/podcast/transcript-how-to-use-claude-code-like-the-people-who-built-it | VERIFIED |
| CH20 | Claude Code team | 2026-03-25 | 93% of prompts approved; auto mode 17% false negatives (n=52) | https://www.anthropic.com/engineering/claude-code-auto-mode | PARAPHRASE_OK (Boris post unverified) |
| CH21 | Boris Cherny | 2026-09-23 | Reasons about models empirically | https://computerhistory.org/blog/in-conversation-with-boris-cherny-creator-of-claude-code/ | PARAPHRASE_OK |
| CH22 | Boris Cherny | date unsupported | Reportedly writes loops instead of prompts | https://github.com/cocodedk/loop-engineering | PARAPHRASE_OK (secondary; date unsupported) |
| CH23 | Anthropic docs | current 2026-10-19 | The model stops when the work looks done; evidence over claims; interview into a spec | https://code.claude.com/docs/en/best-practices | VERIFIED |
| TO1 | Linus Torvalds | 2000-09-06 | Look above the sources, at meaning; no debugger support | https://lkml.iu.edu/0009.0/1148.html | VERIFIED |
| TO2 | Linus Torvalds | 2000-09-06 | His biggest job is saying no to features | https://lkml.iu.edu/0009.0/1148.html | VERIFIED |
| TO3 | Linus Torvalds | 2026-10-13 | Expects understanding; calls tool-specific AI rules idiotic | https://lkml.iu.edu/2610.1/13255.html | VERIFIED |
| TO4 | Linus Torvalds | 2026-01-07 | Antigravity branch merge; he diagnosed the stall and gave a design change | https://github.com/torvalds/AudioNoise/commit/93a72563cba609a414297b558cb46ddd3ce9d6b5 | VERIFIED |
| TO5 | Linus Torvalds | 2026-01-09 | Python visualizer vibe-coded; toy stakes | https://github.com/torvalds/AudioNoise | VERIFIED |
| TO6 | Linus Torvalds | 2026-01-15 | Set the data representation; checked against an oscilloscope | https://github.com/torvalds/AudioNoise/commit/745e79b0ef279d98ae8f2ef450bf7d7b9abb13f4 | VERIFIED |
| TO7 | Linus Torvalds | 2026-01-08 | Hand-shaped the biquad interface; recorded known debt | https://github.com/torvalds/AudioNoise/commit/efa7475a0d551684c3880213c1e6c4761a0f120d | PARAPHRASE_OK |
| TO8 | Linus Torvalds | 2016 | "Good taste": make the special case the normal case | https://github.com/mkirchner/linked-list-good-taste | PARAPHRASE_OK (secondary transcription) |
| TO9 | Linus Torvalds | 2006-07-29 | Good programmers worry about data structures | https://lwn.net/Articles/193244/ | VERIFIED (LWN quote) |
| TO10 | Linus Torvalds | 2007-05-03 | Trust scales through 5-15 accountable people | https://singjupost.com/linus-torvalds-on-git-at-google-tech-talk-conference-full-transcript/ | PARAPHRASE_OK |
| TO11 | Linus Torvalds | 2012-11-12 | Don't break user space; no time limit | https://lkml.iu.edu/hypermail/linux/kernel/1211.1/02016.html | VERIFIED |
| TO12 | Linus Torvalds | 2025-11-18 | Vibe coding bad for maintenance; not using AI then | https://www.theregister.com/2025/11/18/linus_torvalds_vibe_coding | VERIFIED (secondary) |
| TO13 | Linus Torvalds | 2025-12 | Trusted an LLM first as a reviewer | https://lwn.net/SubscriberLink/1049830/d046b62b9e96e5ab/ | VERIFIED (secondary) |
| TO14 | Linus Torvalds | 2026-01-07 | Policy text binds only good actors | https://lkml.iu.edu/2601.0/04650.html | VERIFIED |
| TO15 | Linus Torvalds | 2026-05-25 | Understanding the end result; security list flooded | https://lwn.net/Articles/1073761/ | PARAPHRASE_OK (key phrase not verbatim; "did not scale" misapplied) |
| TO16 | Linus Torvalds | 2026-07-15 | Decisions on technical merit, not fear of tools | https://www.phoronix.com/news/Linux-Is-Not-Anti-AI | VERIFIED (secondary) |
| TO17 | Linus Torvalds | 2026-10-11 | Claude Code wrote a kernel series under his direction; isolated branch | https://www.phoronix.com/news/Linus-Torvalds-Claude-Code | PARAPHRASE_OK (patch count and benchmarks unverified) |
| TO18 | Linus Torvalds | 2026-10-09 | Uses AI for what he is bad at; careful on real work | https://linux.slashdot.org/story/26/10/13/034206/linus-torvalds-on-why-ai-works-for-him | PARAPHRASE_OK |
| TO19 | Kernel community (Levin) | 2026-10-09 | Patch to deprecate Assisted-by; human Signed-off-by kept | https://lkml.iu.edu/2610.1/02723.html | PARAPHRASE_OK (pending; reason unsourced) |
| TO20 | Kernel docs | 2025-12 to 2026 | Agents cannot sign, must state what they could not do, never send | https://docs.kernel.org/process/coding-assistants.html | VERIFIED (doc still required Assisted-by when read) |
| PR1 | Andrej Karpathy | 2025-02-02 | Coined vibe coding: deliberately not looking at the code | https://x.com/karpathy/status/1886192184808149383 | VERIFIED |
| PR2 | Simon Willison | 2025-03-19 | Explainable and tested means development | https://simonwillison.net/2025/Mar/19/vibe-coding/ | VERIFIED |
| PR3 | Simon Willison | 2025-10-07 | "Vibe engineering" is existing discipline that agents amplify | https://simonwillison.net/2025/Oct/7/vibe-engineering/ | VERIFIED |
| PR4 | Kent Beck | 2025-06-25 | Augmented coding: plan, TDD, watch for test tampering | https://newsletter.kentbeck.com/p/augmented-coding-beyond-the-vibes | VERIFIED |
| PR5 | Andrej Karpathy | 2025-10-17 | Model prior overrides local design intent | https://www.dwarkesh.com/p/andrej-karpathy | VERIFIED |
| PR6 | Andrej Karpathy | 2026-01-26 | 80% agent coding; models don't ask, don't push back, bloat code | https://x.com/karpathy/status/2015883857489522876 | VERIFIED (xcancel URL dead) |
| PR7 | Andrej Karpathy | 2025-04-27 | MenuGen matched Stripe payments by email instead of user id | https://karpathy.bearblog.dev/vibe-coding-menugen/ | VERIFIED |
| PR8 | DHH | ~2026-08 (event Feb 2026) | Designers' vibe-coded PRs together wrecked the architecture; "things are different now" | https://lexfridman.com/dhh-2-transcript/ | VERIFIED |
| PR9 | DHH | ~2026-08 | Reviewed the shape of everything; read lines only in the model layer | https://lexfridman.com/dhh-2-transcript/ | VERIFIED |
| PR10 | Mitchell Hashimoto | 2026-02-05 | Blind redo of his own commits; harness engineering | https://mitchellh.com/writing/my-ai-adoption-journey | VERIFIED |
| PR11 | Ryan Lopopolo | 2026-04-07 | Zero hand-written code with taste encoded upfront; still does the gnarliest refactors | https://latent.space/p/harness-eng | PARAPHRASE_OK |
| PR12 | Thorsten Ball | 2026-07-29 | Prompting practice talk; claimed figures misattributed | https://thorstenball.com/talks/how-i-prompt/ | WRONG (not relied on) |
| PR13 | Armin Ronacher | 2025-06-12 | Shape code for a reader with limited working memory | https://lucumr.pocoo.org/2025/6/12/agentic-coding/ | VERIFIED |
| PR14 | Armin Ronacher | 2026-01-18 / 02-13 | His own overbuilding lapse; review is the bottleneck | https://lucumr.pocoo.org/2026/2/13/the-final-bottleneck/ | PARAPHRASE_OK (bottleneck line echoes Ball) |
| PR15 | Simon Willison | 2025-12-18 | Deliver code proven to work; red first | https://simonwillison.net/2025/Dec/18/code-proven-to-work/ | PARAPHRASE_OK (quote is on the red-green TDD page) |
| PR16 | Anthropic docs | current | Gap-hunting reviewers usually report something | https://code.claude.com/docs/en/best-practices | VERIFIED |
| PR17 | Boris Cherny (VentureBeat) | 2026-01-02 | Setup thread: verification and CLAUDE.md | https://venturebeat.com/technology/the-creator-of-claude-code-just-revealed-his-workflow-and-developers-are | PARAPHRASE_OK (primary thread exists) |
| PR18 | Linus Torvalds | 2025-11 / 2026 | Vibe codes the peripheral tool, keeps the core | https://github.com/torvalds/AudioNoise | VERIFIED |
| PR19 | Addy Osmani | 2024-12-04 | The "70% problem"; non-experts' fixes diverge | https://addyo.substack.com/p/the-70-problem-hard-truths-about | PARAPHRASE_OK |
| PR20 | METR | 2025-07-10 / 2026-02-24 | Perceived speed versus measured speed; later superseded | https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/ | PARAPHRASE_OK |
| PR21 | Alexandr Wang (Fortune) | 2025-10-03 | Told teens to spend their time vibe-coding | https://fortune.com/2025/10/03/alexandr-wang-technology-self-starter-gen-z-billionaire-alexandr-wang-tells-13-year-olds-they-should-be-more-like-bill-gates-who-sneaked-out-of-the-house-to-code-at-night-mark-zuckerberg-scale-ai/ | PARAPHRASE_OK (secondary) |
| EV1 | METR | 2025-07-10 | Experts 19% slower while believing they were 20% faster | https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/ | PARAPHRASE_OK (CI not on page; superseded by EV2) |
| EV2 | METR | 2026-02-24 | Weak evidence of speedup; experts now choose which tasks to delegate | https://metr.org/blog/2026-02-24-uplift-update/ | PARAPHRASE_OK |
| EV3 | METR | 2025-08-12 | 38% passed tests, 0 of 15 mergeable | https://metr.org/blog/2025-08-12-research-update-towards-reconciling-slowdown-with-time-horizons | PARAPHRASE_OK (category figures n=4) |
| EV4 | METR | 2026-03-10 | Maintainers would reject about half of test-passing PRs | https://metr.org/notes/2026-03-10-many-swe-bench-passing-prs-would-not-be-merged-into-main/ | PARAPHRASE_OK |
| EV5 | Vo, Doshi, Sheinin | 2026-10-01 | 92.6% of output-passing runs had process deviations | https://arxiv.org/abs/2610.01833 | PARAPHRASE_OK (abstract only) |
| EV6 | Shen, Tamkin (Anthropic) | 2026-01-29 | Delegating the thinking cost comprehension (50% vs 67%) | https://www.anthropic.com/research/AI-assistance-coding-skills | VERIFIED |
| EV7 | Sankaranarayanan | 2026-02-22 | Explanation gate cut later failure from 77% to 39% (novices; gate is an LLM judge) | https://arxiv.org/abs/2602.20206 | VERIFIED |
| EV8 | Borg et al. | 2025-07-01 / 2026-02-26 | No downstream maintainability penalty on a scoped feature | https://arxiv.org/abs/2507.00788v3 | PARAPHRASE_OK (journal venue unverified) |
| EV9 | Veracode | 2025-07-30 | Insecure choice in 45% of cases; scale did not help | https://www.veracode.com/press-release/ai-generated-code-poses-major-security-risks-in-nearly-half-of-all-development-tasks-veracode-research-reveals/ | VERIFIED (vendor) |
| EV10 | Perry et al. | 2022-11 / 2023-11 | Less secure code written with more confidence | https://arxiv.org/abs/2211.03622 | VERIFIED |
| EV11 | CodeRabbit | 2025-12-17 | About 1.7x issues; attributed to missing business rules and local patterns | https://www.coderabbit.ai/blog/state-of-ai-vs-human-code-generation-report | VERIFIED (vendor) |
| EV12 | GitClear | 2025 | Copy/paste up, moved (refactored) code down | https://www.gitclear.com/ai_assistant_code_quality_2025_research | PARAPHRASE_OK (vendor, correlational) |
| EV13 | Cui et al. | 2024-09 / 2025 | +26% tasks, largest gains for juniors | https://papers.ssrn.com/abstract=4945566 | PARAPHRASE_OK (via search summaries) |
| EV14 | Faros AI | 2025 | Twice the code changes, flat company metrics | https://www.faros.ai/ai-productivity-paradox | PARAPHRASE_OK (vendor) |
| EV15 | Google DORA | 2024-10 / 2025-09 | AI amplifies the existing discipline | https://research.google/pubs/dora-2025-state-of-ai-assisted-software-development-report/ | PARAPHRASE_OK (2024 figures secondary) |
| EV16 | Sonar | 2026-01-08 | 96% distrust AI code; 48% always check it | https://www.sonarsource.com/company/press-releases/sonar-data-reveals-critical-verification-gap-in-ai-coding/ | VERIFIED (vendor) |
| EV17 | Lemkin / Replit | 2025-07 | Production database wiped during a freeze | https://www.eweek.com/news/replit-ai-coding-assistant-failure/ | WRONG (added details unsupported; not relied on) |
| EV18 | Matt Palmer | 2025-05-29 | RLS check tested presence, not sufficiency | https://mattpalmer.io/posts/CVE-2025-48757 | PARAPHRASE_OK |
| EV19 | Wiz / Moltbook | 2026-02 | Exposed key and no RLS | https://www.infosecurity-magazine.com/news/moltbook-exposes-user-data-api/ | WRONG (counts and details unsupported; not relied on) |
| EV20 | FT / AWS (Kiro) | 2026-02-20 | Agent reportedly deleted and recreated an environment; AWS disputes | https://the-decoder.com/aws-ai-coding-tool-decided-to-delete-and-recreate-a-customer-facing-system-causing-13-hour-outage-report-says/ | PARAPHRASE_OK (contested) |
| EV21 | Murphy-Hill et al. | 2026-07-01 | +24% merged PRs; volume, not value | https://arxiv.org/abs/2607.01418 | VERIFIED (abstract) |
| EV22 | Michels et al. | 2026-08-20 | Vibe coding defined as verifying by running, not reading | https://arxiv.org/abs/2608.20446 | PARAPHRASE_OK |
| EV23 | Sabry Farrag | 2026-05-01 | Argues specification discipline is the binding constraint | https://arxiv.org/abs/2605.01160 | VERIFIED (argued, not shown) |
| TH1 | Peter Naur | 1985 | A program is a theory held by people | https://gist.github.com/onlurking/fc5c81d18cfce9ff81bc968a7f342fb1 | VERIFIED (transcription) |
| TH2 | Peter Naur | 1985 | Locally correct patches destroyed a compiler's structure | https://gist.github.com/onlurking/fc5c81d18cfce9ff81bc968a7f342fb1 | PARAPHRASE_OK |
| TH3 | Peter Naur | 1985 | Theory cannot be rebuilt from documentation alone | https://gist.github.com/onlurking/fc5c81d18cfce9ff81bc968a7f342fb1 | VERIFIED |
| TH4 | Fred Brooks | 1986 | Essence versus accident in software difficulty | https://worrydream.com/refs/Brooks_1986_-_No_Silver_Bullet.pdf | VERIFIED |
| TH5 | Fred Brooks | 1986 | Debugging the specification is the hard part | https://worrydream.com/refs/Brooks_1986_-_No_Silver_Bullet.pdf | PARAPHRASE_OK |
| TH6 | Fred Brooks | 1975 / 1986 | Conceptual integrity (MMM half unread at source) | https://web.eecs.umich.edu/~weimerw/2018-481/readings/mythical-man-month.pdf | UNVERIFIED (not relied on) |
| TH7 | Parnas, Clements | 1986 | Record rejected alternatives; mark unknowns | https://users.ece.utexas.edu/~perry/education/SE-Intro/fakeit.pdf | VERIFIED |
| TH8 | Meir Lehman | 1996 | Complexity grows unless work reduces it; implicit assumptions decay | https://www.cs.kent.edu/~jmaletic/cs63902/Papers/Lehman96.pdf | VERIFIED |
| TH9 | John Ousterhout | 2024-09 to 2025-02 | Green tests discourage revisiting the design | https://github.com/johnousterhout/aposd-vs-clean-code | VERIFIED |
| TH10 | Ousterhout (via Orosz) | 2025-04-09 | Design matters more with AI; "tactical tornado" is Orosz's phrase | https://newsletter.pragmaticengineer.com/p/the-philosophy-of-software-design | VERIFIED (secondary) |
| TH11 | Kahneman, Klein | 2009-09 | Confidence tracks coherence, not accuracy | https://dl1.cuni.cz/mod/resource/view.php?id=153128 | VERIFIED |
| TH12 | Klein | 2007 / 2009 | Premortem method | https://dl1.cuni.cz/mod/resource/view.php?id=153128 | VERIFIED |
| TH13 | Petre, van der Hoek | 2016 | Expert design habits (several unsupported by the cited page) | https://www.bennadel.com/blog/3520-software-design-decoded-66-ways-experts-think-by-marian-petre-and-andre-van-der-hoek.htm | UNVERIFIED (not relied on) |
| TH14 | Edsger Dijkstra | c. 1978 | Natural language hides nonsense | https://www.cs.utexas.edu/~EWD/transcriptions/EWD06xx/EWD667.html | VERIFIED |
| TH15 | Anthropic system card | 2025-02 | Test special-casing after failed attempts; observable signals | https://assets.anthropic.com/m/785e231869ea8b3b/original/claude-3-7-sonnet-system-card.pdf | VERIFIED |
| TH16 | METR | 2025-06-05 | Reward hacking; intent stated when asked but not acted on; instructions barely help | https://metr.substack.com/p/2025-06-05-recent-reward-hacking | VERIFIED (one-task scope) |
| TH17 | Anthropic Engineering | 2025-11-26 | Each session starts with no memory; harness carries state | https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents | VERIFIED |
| TH18 | Vijayvargiya et al. | 2025-02 / 2026-01 | Models rarely ask; Sonnet 4 detects at 74% neutral, 89% encouraged | https://arxiv.org/html/2502.13069v2 | PARAPHRASE_OK ("near chance" overstated) |
| TH19 | Wang, Pradel, Liu | 2025-03 / 09 | 29.6% of plausible patches diverge from the human fix | https://arxiv.org/abs/2503.15223 | VERIFIED |
| TH20 | METR | 2025-08-12 | None of 15 PRs mergeable as-is | https://metr.org/blog/2025-08-12-research-update-towards-reconciling-slowdown-with-time-horizons | VERIFIED |
| TH21 | METR | 2025-07-10 / 2026-02-24 | Experts' self-assessment wrong in direction | https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/ | PARAPHRASE_OK |
| TH22 | Huang et al. | 2025-12 / 2026-08 | Professionals keep the plan and acceptance; refuse to delegate domain logic | https://arxiv.org/html/2512.14012 | VERIFIED |
| TH23 | jyn | 2025-05-24 | A similar theory can be rebuilt by experiment | https://jyn.dev/theory-building-without-a-mentor/ | VERIFIED |