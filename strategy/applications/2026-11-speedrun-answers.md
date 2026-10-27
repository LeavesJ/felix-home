# a16z speedrun SR008: application answers

Draft, 2026-10-27, for the form at speedrun.a16z.com/apply (closes 2026-11-01, 11:59 PM PT). The facts come from `2026-11-speedrun-brief.md` beside this file, `docs/direction.md`, the public README, investor deck v3, the resumes of 2026-10-17 (`Jarron_Deng_Resume_May_2030.pdf`) and 2026-09-30 (`Deng_Jarron_Resume_Berkeley_20260930_v6.pdf`), and Peter Washington's emails of 2026-09-12 and 2026-10-16. A separate reader then checked every sentence against those sources, and its corrections are in. Each text box's heading gives its character count against the form's limit, and filling a `[TK]` changes the count. Lines marked `[TK: ...]` are yours to fill.

## Before you submit

1. **#464 lands first.** You approved it on 10-27, and it lands once its gate passes. It changes `docs/direction.md` row 10 to allow a narrow commercial track that includes fundraising applications, and row 19 to bring the second host forward, Factory's Droid and then Codex. The anything-else box now says Droid and then Codex are next, which matches the binding file only once #464 is on main. If it hasn't landed when you submit, change that clause back to "and a second host is planned".
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

### Relevant experience (983 of 1000)

<!-- answer:experience -->
I lead BehaviorChangeBench, a Google DeepMind and UCSF TECH Lab project that tests how well frontier models coach someone through changing a health behavior over several sessions. I calibrated our LLM judges against blinded human labels until they agreed 83% of the time, where two humans agree with each other 87% of the time. Our adversarial branches took top model scores from 0.90 down to 0.65, and we're writing the paper in NeurIPS evaluation-track format to submit next semester.

Earlier I built Elenchus, an LLM product that more than 200 Berkeley students used to cross-examine a decision they had actually made, for up to eight rounds, until they could name the mechanism behind it. It shipped behind deterministic output gates and a 1,282-test offline suite, and when I then tested whether it really worked, its grader turned out to be biased (p = 0.000244). I retired the grader, and when a blind rater liked the core technique no better than a baseline, I cut that too.
<!-- /answer -->

### Tell us more about the team (884 of 1000, before the [TK]s)

<!-- answer:team -->
It's just me, and I'll be full time if I'm accepted. I'm an EECS student at Berkeley, and I'd take a leave of absence for spring 2027 to do the residency in San Francisco.

I'm building this as my own first customer. I want agents doing more of my work, not less, so I've had to stop taking their word for it. Over 73 days mine ran more than 87,100 model turns, and at that volume the same failures kept coming back: an old passing result offered as proof for new code, work called done before any check had run, an agent stopping on a check that had just failed. I'd run into the same problem with Elenchus's grader and with BehaviorChangeBench's judges, and both times the answer was to check the model against something it doesn't control. Using agents this hard is how I keep finding the next way they fail.

There's no cofounder yet, and I won't list someone who isn't committed. [TK: a possible cofounder, named as in progress]

Advisors: [TK: Felix advisors, or cut this line]
<!-- /answer -->

## Startup details

**Startup name:** Daimonion. Felix is the product the description and the other answers describe, so no other box changes.

### One-liner (96 of 100)

<!-- answer:oneliner -->
Checks AI coding agents' work on the exact code before it counts as done, for teams using agents
<!-- /answer -->

### Startup description (798 of 800)

<!-- answer:description -->
You ask a coding agent to add a feature. It runs the tests halfway through, keeps editing, then tells you everything passes, which was true of an earlier version of the code. The agent that wrote the code is usually the only one saying it's done. With Felix, a project names the checks it trusts and Felix records exactly which code they passed on. If the agent tries to stop on code they haven't passed on, Felix sends it back once, and felix merge won't take a branch without a current pass. That half runs today as an open-source Claude Code plugin. The other half is harder: working out what a project owes before any check runs. An agent once shipped a deployment of mine with green tests and no rate limiting, because nobody had asked for one. Finding gaps like that is what I'm building now.
<!-- /answer -->

**Primary category:** [TK: the list wasn't in the paste. Developer tools if it's there.] **Secondary:** AI infrastructure, or security if there's no infrastructure option.

**Where you'll build:** San Francisco, California, United States.

**Founded:** [TK: the form showed July 2026. The resume and the repository both start Felix in August 2026 (its first design documents are dated 2026-08-09).]

**Website:** github.com/LeavesJ/Felix, until there's a site.

### Anything else we should know? (989 of 1000)

<!-- answer:anything -->
This can't come from the agent vendors, because a vendor's report on its own agent's work isn't a check. Teams also run agents from more than one vendor, and Felix's verdict never depends on which model did the work. It runs only on Claude Code today, with Factory's Droid and then Codex next. The buyer I'm designing for is a platform lead at a 50 to 500 engineer company running more than one coding agent.

What I haven't proven: Felix has one real user, me, and the half that finds missing obligations has a test that hasn't run yet. The likely first outside test is a February pilot with a semiconductor supply-chain software team at a family-connected company. It's agreed in principle, not signed, and waits on Felix keeping their code inside their network.

If you use Claude Code, clone github.com/LeavesJ/Felix and run felix audit. It reads the transcripts Claude Code already keeps, writes and installs nothing, and counts the turns that ended on an edit no check had run after.
<!-- /answer -->

## Show us more (all optional)

**Team video:** skipped, by your decision of 10-27. The slot is optional.

**Pitch deck:** optional. See "The deck" below before uploading anything: deck v4's slide 8 still says "363 unverified stops blocked", and these answers use 206.

### Traction (816 characters, no limit shown)

<!-- answer:traction -->
There's no revenue and no customers yet, and every number here comes from my own sessions. Across 43 of them between August 10 and September 21, 2026, Felix held an agent's attempt to stop 206 times. All but three came down to one of three causes: in 135 the checks had last run on different code, in 39 they had never run in that checkout, and in 29 they had failed on the exact code the agent was stopping on. Sent back, the agents reran the checks about 130 times, and at least 15 of those runs failed, all of them runs the agents would have stopped before. The number I'm trying to drive down is how often a person has to step in, and in a September pilot readers labelled 81 of 265 of my turns (31%) as me doing work the agent should have done. The engine is public under Apache-2.0 at github.com/LeavesJ/Felix.
<!-- /answer -->

**Funding history:** [TK: none, if no outside money has gone into Felix.]

**Active fundraising round:** [TK]

**Where did you learn about speedrun?** [TK: yours. Your inbox has the Berkeley EECS jobs list posts about a16z coffee chats, the 11/4 info session and the 11/5 pitch night.]

## Where each answer comes from

| Box | Built from | Left out, and why |
|---|---|---|
| Relevant experience | Resume of 10-17 (BehaviorChangeBench numbers, 200+ Elenchus users, the 1,282-test suite, p = 0.000244); resume of 09-30 (the eight rounds of cross-examination, and the core technique cut after a blind rater); Peter's emails for the paper line. The box is the track record only, and the argument for why it matters to Felix moved to the team box | Sam's name (item 2 above); Elenchus Labs as a company you co-founded, by your decision of 10-27, since this application is for a different company; ReserveGrid, retired the same day; Wake Forest and Marketech, which don't bear on Felix |
| Team | Your answers on 10-27 (part time now, a leave for spring 2027); deck v3's why-this-founder case: slide 5 (the usage numbers, here the resume's 87,100+ turns over 73 days), slide 6 (measure where AI fails, then build the failure into structure; push autonomy, distrust self-certification), the README's three causes of the 206 holds (stale result, no check run, failed check), not slide 8's test weakening, which the deck frames as a risk rather than something measured; the resume of 09-30 for Elenchus's grader | "Felix was written by the agents it governs": true, but it argues for the tool, not the founder; Duet as CSO, since an AI session listed as an officer reads as a gimmick on a team box; any claim of using agents harder than other people, which nothing measures |
| One-liner | The README's two halves, cut to the one that runs | "Decides what counts as done", the brief's category line, which claims more than a hold that sends an agent back once |
| Description | The README's opening example, its hold and `felix merge` wording, and the rate-limit story | Receipts as the lead (the brief: others already have signed, tree-bound receipts) |
| Anything else | The brief's answer to "why won't the vendors build it", its first buyer, its "not yet true" list; #464's row 19 for Droid and then Codex; direction §6 for the pilot boundary | Price ($1,000 a month plus $40 a committer is a hypothesis, and row 10 as changed keeps no price page); METR, which goes in the deck |
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
