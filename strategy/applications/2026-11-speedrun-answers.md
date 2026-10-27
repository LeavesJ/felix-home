# a16z speedrun SR008: application answers

Draft, 2026-10-27, for the form at speedrun.a16z.com/apply (closes 2026-11-01, 11:59 PM PT). The facts come from `2026-11-speedrun-brief.md` beside this file, `docs/direction.md`, the public README, investor deck v3, the resumes of 2026-10-17 (`Jarron_Deng_Resume_May_2030.pdf`) and 2026-09-30 (`Deng_Jarron_Resume_Berkeley_20260930_v6.pdf`), and Peter Washington's emails of 2026-09-12 and 2026-10-16. A separate reader then checked every sentence against those sources, and its corrections are in. Each text box's heading gives its character count against the form's limit, and filling a `[TK]` changes the count. Lines marked `[TK: ...]` are yours to fill.

## Before you submit

1. **Approve or refuse #464.** On main, `docs/direction.md` row 10 still withdraws any market track, and §5 defers the Factory Droid adapter and "outreach and pricing" past March. #464 records your 10-27 decisions: a narrow commercial track that includes fundraising applications, and the second host brought forward. Until it lands, this application runs ahead of the binding file. The answers say only "a second host is planned", which holds either way.
2. **Sam Schmidgall's name.** Your BehaviorChangeBench notes (`private/01_mentors.md`) say his involvement is meant to stay separate unless Anthropic and Google both agree, and not to publish his name or affiliation without asking Peter first. The answers use the resume's wording, a Google DeepMind and UCSF TECH Lab project, and name nobody. Ask Peter before adding names.
3. **The NeurIPS line.** Peter's 10-16 email asks for the Intro, Related Work and Methods "in the format of a NeurIPS eval track paper". His 09-12 email sets the goal of submitting "ideally by early next semester". The venue and its deadline were still open on your 10-16 list. The answer says the paper is being drafted in that format and aimed at next semester. If Peter has since confirmed NeurIPS as the venue, it can say so outright.
4. **Entity and IP.** Nothing is incorporated under Daimonion yet. The brief records that whether Elenchus Labs' invention-assignment agreement reaches Felix "is genuinely unclear". Settle that before any term sheet.
5. **Your resume and deck.** Both still say 363 stops blocked and 35.7%. The answers use 206.

## Team

**Full-time or part-time on the startup?** Part-time.

**Number of full-time founders:** 0. The form says to enter 0 if you are part-time.

**Total FTE employees:** [TK: the form showed 1, but it counts part-time people proportionally, so a part-time solo founder is below 1. Enter the share that's true, for example 0.5.]

**Founder details:** Jarron Deng, jarrondeng@gmail.com, +1 949 402 1712. The SMS consent box is optional.

**City:** [TK: the form showed Scottsdale. If it asks where you live now, that's Berkeley.]

**College / university:** University of California, Berkeley.

**Highest education:** [TK: the form showed Bachelor's degree, which isn't finished yet. Pick the option that's true, such as "in progress" if the list has it.]

**Years of professional experience:** [TK: your call. The record has a summer internship (2024), five months of remote research at Wake Forest (2025), and Veldra since 2023. 1 is defensible.]

**Technical enough to build the product end to end?** Yes.

**GitHub:** github.com/LeavesJ. **Portfolio:** github.com/LeavesJ/Felix. **LinkedIn, X:** [TK]

### Relevant experience (997 of 1000)

<!-- answer:experience -->
I lead BehaviorChangeBench, a Google DeepMind and UCSF TECH Lab benchmark of how frontier models coach people through health-behavior change across sessions. I calibrated its LLM judges to 83% agreement with blinded human labels, against an 87% human-to-human ceiling, and our adversarial branches pushed top model scores from 0.90 to 0.65. We're drafting the paper in NeurIPS evaluation-track format, to submit next semester.

Earlier I built Elenchus and shipped it to 200+ Berkeley students. It cross-examines a student's real decision for up to eight rounds, until they can name the mechanism behind it. It ran behind deterministic output gates and a 1,282-test offline suite, and then I tested whether it worked. Its own grader showed a systematic scoring bias (p = 0.000244), so I retired the grader. When a blind rater liked the core technique's output no better than baseline, I cut that too. Felix is the same habit, turned on the coding agents I ran for 87,100+ model turns over 73 days.
<!-- /answer -->

### Tell us more about the team (549 of 1000)

<!-- answer:team -->
It's just me for now. I'm part time today because I'm an EECS student at Berkeley. If I'm accepted, I'll take a leave of absence for spring 2027 and work on this full time in San Francisco.

Agents do most of the engineering. Most of Felix was written by the coding agents it governs, under its own gate, and every hold it has made so far was in my own sessions.

I don't have a cofounder, and I'd rather say so than list someone who isn't committed. [TK: a possible cofounder, named as in progress]

Advisors: [TK: Felix advisors, or cut this line]
<!-- /answer -->

## Startup details

**Startup name:** Daimonion. Felix is the product the description and the other answers describe, so no other box changes.

### One-liner (96 of 100)

<!-- answer:oneliner -->
Checks AI coding agents' work on the exact code before it counts as done, for teams using agents
<!-- /answer -->

### Startup description (782 of 800)

<!-- answer:description -->
An AI coding agent runs your tests halfway through a task, keeps editing, then tells you everything passes. It did, on an earlier version of the code. The agent that wrote the code is usually the only one saying it's done. With Felix, a project names the checks it trusts, and Felix records exactly which code they passed on. If an agent tries to stop on code they haven't passed on, Felix sends it back once, and felix merge won't take a branch without a current pass. That half runs today as an open-source Claude Code plugin. The other half comes before any check runs: working out what a project owes. An agent once shipped a deployment of mine with green tests and no rate limiting, because nobody had asked for one. I'm building that half now: finding the checks nobody wrote.
<!-- /answer -->

**Primary category:** [TK: the list wasn't in the paste. Developer tools if it's there.] **Secondary:** AI infrastructure, or security if there's no infrastructure option.

**Where you'll build:** San Francisco, California, United States.

**Founded:** [TK: the form showed July 2026. The resume and the repository both start Felix in August 2026 (its first design documents are dated 2026-08-09).]

**Website:** github.com/LeavesJ/Felix, until there's a site.

### Anything else we should know? (971 of 1000)

<!-- answer:anything -->
A vendor's report on its own agent's work isn't a check, and teams now run agents from more than one vendor. Felix's verdict never depends on which model did the work. It runs only on Claude Code today, and a second host is planned. The buyer I'm designing for is a platform lead at a 50 to 500 engineer company running more than one coding agent. What isn't true yet: Felix has one real user, me, and the half that finds missing obligations has a settled test that hasn't run. The likely first outside test is a February pilot with a semiconductor supply-chain software team at a company my family is connected to. It's agreed in principle, nothing is signed, and it waits on Felix keeping their code inside their network, which it can't do yet.

If you use Claude Code, clone github.com/LeavesJ/Felix and run felix audit. It reads the transcripts Claude Code already keeps, writes and installs nothing, and counts the turns that ended on an edit no check had run after.
<!-- /answer -->

## Show us more (all optional)

**Team video:** skipped, by your decision of 10-27. The slot is optional.

**Pitch deck:** optional. See "The deck" below before uploading anything: deck v4's slide 8 still says "363 unverified stops blocked", and these answers use 206.

### Traction (767 characters, no limit shown)

<!-- answer:traction -->
Pre-revenue, with no customers yet. Across 43 of my own sessions between August 10 and September 21, 2026, Felix held an agent's attempt to stop 206 times. All but three had one of three causes. In 135 the checks had last run on different code, in 39 they had never run in that checkout, and in 29 they had failed on the exact code the agent was stopping on. Sent back, the agents reran the checks about 130 times, and at least 15 of those runs failed. Without the hold, they would have stopped before running any of them. The number I'm driving down is how often a person has to step in. In a September pilot, readers labelled 81 of 265 of my turns (31%) as me doing work the agent should have done. The engine is public under Apache-2.0 at github.com/LeavesJ/Felix.
<!-- /answer -->

**Funding history:** [TK: none, if no outside money has gone into Felix.]

**Active fundraising round:** [TK]

**Where did you learn about speedrun?** [TK: yours. Your inbox has the Berkeley EECS jobs list posts about a16z coffee chats, the 11/4 info session and the 11/5 pitch night.]

## Where each answer comes from

| Box | Built from | Left out, and why |
|---|---|---|
| Relevant experience | Resume of 10-17 (BehaviorChangeBench numbers, 200+ Elenchus users, the 1,282-test suite, p = 0.000244, 87,100+ turns); resume of 09-30 (the eight rounds of cross-examination, and the core technique cut after a blind rater); deck v3 slides 4 and 6 for why Elenchus matters to Felix; Peter's emails for the paper line | Sam's name (item 2 above); Elenchus Labs as a company you co-founded, by your decision of 10-27, since this application is for a different company; ReserveGrid, retired the same day; Wake Forest and Marketech, which don't bear on Felix |
| Team | Your answers on 10-27 (part time now, a leave for spring 2027); the README line that most of Felix was written by the agents it governs | Duet as CSO: an AI session listed as an officer reads as a gimmick on a team box |
| One-liner | The README's two halves, cut to the one that runs | "Decides what counts as done", the brief's category line, which claims more than a hold that sends an agent back once |
| Description | The README's opening example, its hold and `felix merge` wording, and the rate-limit story | Receipts as the lead (the brief: others already have signed, tree-bound receipts) |
| Anything else | The brief's answer to "why won't the vendors build it", its first buyer, its "not yet true" list; direction §6 for the pilot boundary | Price ($1,000 a month plus $40 a committer is a hypothesis, and row 10 as changed keeps no price page); METR, which goes in the deck |
| Traction | The README's 206 holds; the episode pilot's 31% (`docs/2026-09-23-episode-pilot.md`), the baseline of the binding objective. A second batch measured 36 to 50%, depending on the counting rule; add it if you want the range | The 363 and 35.7%, which the brief retired; the test count, where the README (about 3,000 assertions) and the brief (13,818) disagree |

## The name

**Decided 2026-10-27: the company is Daimonion, and its product is Felix.** The company name carries the long-run goal, a one-person company that is fully capable. The product name carries the first step, and the application talks only about Felix. `docs/direction.md` keeps Felix itself to engineering; the larger goal belongs to the company, not to Felix.

The name has two meanings in Plato, and both fit:
- **Now.** In the *Apology* (31d), Socrates describes an inner sign that "always forbids but never commands me to do anything." That is Felix today, which direction §2 calls "a strong no and a weak yes".
- **Later.** In the myth of Er that closes the *Republic*, each soul chooses its daimon, which then guards its life and carries out the choice it made. The founder chooses what, and the daimon handles how, which is the split in Felix's constitution. That meaning matters more, because the constitution calls a Felix that only says no "the defect".

Unix also calls a process that runs in the background, unattended, a daemon. And the name sits beside Elenchus Labs: both are Socratic, one testing a claim and the other guarding an act.

Said "dye-MOH-nee-on". No company was found under the name. The nearest is **Daimon Labs**, a New York AI-companionship chatbot startup with pre-seed money from LDV Capital (reported in 2023). It is a different word in a different market, but it is an AI company, so check the trademark before incorporating. Also near: Searchdaimon (Norwegian search software) and Daimon (a wellness platform). daimonion.com has been registered since 2005, and daimonion.ai is a parked "Launching Soon" page from 2025, so the website stays github.com/LeavesJ/Felix until a domain is chosen.

Also considered:

| Name | What it means | Why not |
|---|---|---|
| Felix | The product's own name | Felix Capital is a London venture firm, and the word is common |
| Entelechy | Aristotle's word for a thing whose purpose is fully realized | Says nothing about holding work to account; .com and .ai are registered |
| Euthyna | The audit every Athenian official faced at the end of a term | Euthyna.ai already sells verification of sustainability reports |
| Ephor | The Spartan overseers who held kings to account | EphoraAI uses the same idea for a judge agent over other agents |
| Kybernetes | Greek for helmsman | Kubernetes already made it the name of a control plane |
| Detent, Escapement | Mechanical parts that hold or meter motion | Accurate, without the weight of a Greek name |
| Assay | A test of what the maker claims | "tryassay" already sells AI code verification |

## The deck

The upload is optional, and the speedrun team's own FAQ says a deck "can sometimes get in the way". Send one only if it is short and agrees with every number above. Deck v4 (`~/Downloads/Felix_Autonomous_Engineering_Control_Plane_Investor_Deck_v4.pptx`, 18 slides) is a thesis deck. It argues the idea well, but it says 363 and 35.7% where these answers say 206, and its two invariant slides centre on receipts, which the brief says not to lead with because signed, tree-bound receipts already exist elsewhere.

A proposed nine-slide deck, cut from v4 and the brief:

| # | Slide | From |
|---|---|---|
| 1 | Daimonion, Felix, and the one-liner. | new |
| 2 | The failure: the agent says "done" on code that changed after the tests ran. | v4 slide 8, without its 363 and 35.7% line |
| 3 | What Felix does with one change, start to finish: the hold, the receipt for that exact code, and the merge that refuses without it. | v4 slide 9, the README's walkthrough |
| 4 | The evidence: 206 holds in 43 sessions, the three causes, about 130 reruns, at least 15 of them failed. | README |
| 5 | The harder half: the rate-limit story, what a project owes, and the seeded-omission test that is designed but hasn't run. | README, brief |
| 6 | Why now: METR's maintainers rejected about half the PRs that passed the grader; every vendor reviews its own agent's work. | brief, METR note of 2026-03-10 |
| 7 | Who pays, marked as a hypothesis: platform leads at 50 to 500 engineer teams running two or more agent vendors, self-hosted, paying for the verdict rather than for tokens. | brief |
| 8 | Why me: BehaviorChangeBench, Elenchus as a product (200+ students, the grader it retired), 87,100+ model turns. | v4 slides 4 and 6, resume |
| 9 | The next twelve weeks: the M1 attended loop, the M2 MVP with the seeded-omission result, the February pilot, and full time from February. | brief roadmap |

Out from v4: the kernel and browser analogy (slide 11), invariant infrastructure for finance and healthcare (slide 16), and the two thesis slides at the front (2 and 3). They widen the claim past what has been measured, and a reviewer reads the numbers first.

If v4 goes out with only its numbers fixed, slide 17 also needs changing: it still says "Current build focus: Trust Plane MVP", while direction row 25 (10-19) builds need intake alongside the trust plane. `direction.md` §6 points to wording for it in §9 of the 2026-10-18 brief.

Still open: whether to send a deck at all, and if so, whether it is the nine slides above or v4 with only its numbers fixed.
