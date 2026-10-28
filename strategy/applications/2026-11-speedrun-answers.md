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

### Relevant experience (970 of 1000)

<!-- answer:experience -->
My two biggest AI projects, and now Felix, all come back to one question: is the AI actually doing what it says it's doing?

Right now I lead BehaviorChangeBench, a Google DeepMind and UCSF TECH Lab project that asks it about health coaching. Can a frontier model really help someone change a habit over a series of conversations? So far the best models look great on the easy cases and much worse once a conversation gets hard, and we're writing that up in NeurIPS evaluation-track format to submit next semester.

Earlier I built Elenchus, which more than 200 Berkeley students used. You bring it a real decision you've made, and it keeps asking you why until you can name what actually drove it. Building it taught me to distrust my own results: when I tested it properly, the technique I'd built it around did no better than a plain baseline, and I cut it. Felix comes from the same habit: don't believe the AI, or yourself, until something outside both has checked.
<!-- /answer -->

### Tell us more about the team (927 of 1000, before the [TK]s)

<!-- answer:team -->
I'm building this because I needed it first. I hand coding agents as much of my work as they'll take, and the more I gave them, the more often one would tell me a job was done when nothing had shown it was. I could have pulled back and given them less. I wanted to give them more, and that meant building something that checks their work for me. Felix now runs on my own projects.

I think that's the right way in. The teams that get the most out of agents won't be the ones that trust them least, but the ones that can check them. And checking AI is work I've already been doing: at Elenchus and at BehaviorChangeBench, a lot of my best work was catching AI being wrong, my own included.

It's a team of one today. I don't have a cofounder yet [TK: or name one, as in progress], and I'd rather tell you that than list someone who isn't all in. If I get in, I'll take a leave from Berkeley for spring 2027 and build this full time in San Francisco.

Advisors: [TK: Felix advisors, or cut this line]
<!-- /answer -->

## Startup details

**Startup name:** Daimonion. Felix is the product the description and the other answers describe, so no other box changes.

### One-liner (92 of 100)

<!-- answer:oneliner -->
Catches AI coding agents calling work done before it's been checked, for teams that use them
<!-- /answer -->

### Startup description (738 of 800)

<!-- answer:description -->
Coding agents are good enough now to hand real work to, but it's still hard to know when they're actually done. The agent that wrote the code is also the one telling you it works, and it's often wrong in ways that look right. The tests passed on an older version of the code, or the feature passes every test and still misses what mattered. Felix sits between an agent saying "done" and that work counting as done. Today it sends an agent back when the project's own checks haven't passed on the exact code it's handing over, and it runs as an open-source plugin for Claude Code. Next, it works out what a project needed checked that nobody wrote down, like the rate limit one of my agents shipped without because no one had asked for it.
<!-- /answer -->

**Primary category:** [TK: the list wasn't in the paste. Developer tools if it's there.] **Secondary:** AI infrastructure, or security if there's no infrastructure option.

**Where you'll build:** San Francisco, California, United States.

**Founded:** [TK: the form showed July 2026. The resume and the repository both start Felix in August 2026 (its first design documents are dated 2026-08-09).]

**Website:** github.com/LeavesJ/Felix, until there's a site.

### Anything else we should know? (989 of 1000)

<!-- answer:anything -->
Why won't the agent vendors build this? A vendor grading its own agent is the same problem one level up, and teams already run agents from more than one vendor. Felix doesn't care which model wrote the code. It runs on Claude Code today, with Factory's Droid and then Codex next. The first buyer I'm going after is the platform lead at a 50 to 500 engineer company running several coding agents.

Where it stands: Felix has one real user, me, and the half that catches missing requirements is still being built. The first outside test is likely a February pilot with a semiconductor supply-chain software team at a family-connected company. It's agreed in principle, nothing's signed, and it depends on Felix running inside their network, which it can't yet.

If you use Claude Code, try it: clone github.com/LeavesJ/Felix and run felix audit. It installs nothing, just reads the transcripts Claude Code already keeps and shows how often your agent finished on an edit nothing had checked.
<!-- /answer -->

## Show us more (all optional)

**Team video:** skipped, by your decision of 10-27. The slot is optional.

**Pitch deck:** optional. See "The deck" below before uploading anything: deck v4's slide 8 still says "363 unverified stops blocked", and these answers use 206.

### Traction (758 characters, no limit shown)

<!-- answer:traction -->
No revenue or customers yet. Felix has one user, me, and it already catches things I'd have missed. In six weeks across 43 of my sessions, it stopped an agent from calling something done 206 times. Almost every time, the agent's evidence was stale (the tests had passed on older code), missing (they'd never run), or bad (they'd failed on the very code it was handing over). Sent back, the agents reran their checks about 130 times, and at least 15 of those runs failed, problems that would otherwise have slipped through. What I'm trying to shrink is how often I still have to step in myself: in a September pilot, readers marked 31% of my turns as me doing work the agent should have done. Felix is open source under Apache-2.0 at github.com/LeavesJ/Felix.
<!-- /answer -->

**Funding history:** [TK: none, if no outside money has gone into Felix.]

**Active fundraising round:** [TK]

**Where did you learn about speedrun?** [TK: yours. Your inbox has the Berkeley EECS jobs list posts about a16z coffee chats, the 11/4 info session and the 11/5 pitch night.]

## Where each answer comes from

Each box leads with what Felix is and why it matters, in the voice of someone talking, and keeps a number only where it makes the point land. Traction is the box for numbers. What came out is in the next section, for the interview.

| Box | What it's for | Built from |
|---|---|---|
| Relevant experience | One question runs through BehaviorChangeBench, Elenchus and Felix: is the AI doing what it says? Elenchus is there for its 200+ Berkeley users and for cutting its own core technique when a blind test said to | Resume of 10-17 (BehaviorChangeBench, 200+ users); resume of 09-30 (the cross-examination, the technique cut after a blind rater); Peter's emails for the paper line. Not here: Sam's name (item 2 above), Elenchus Labs as a company you co-founded, ReserveGrid |
| Team | Why you: you needed it first, you want agents doing more rather than less, and catching AI being wrong is work you've already done. Solo and full time come last, as the close | Your answers of 10-27; deck v3 slides 5 and 6 (extreme usage found the failures; push autonomy, distrust self-certification) |
| One-liner | What it does and for whom, with no mechanism words | The README's first half |
| Description | Agents grade their own homework; Felix sits between "done" and counting as done; next, the checks nobody wrote | The README's opening example and the rate-limit story |
| Anything else | Why the vendors won't build it, the first buyer, an honest account of what isn't proven, and something they can run | The brief's vendor answer and first buyer; #464's row 19 for Droid and then Codex; direction §6 for the pilot boundary |
| Traction | The numbers, said plainly | The README's 206 holds in 43 sessions; the episode pilot's 31% (`docs/2026-09-23-episode-pilot.md`) |

## Saved for the interview

These are true, and they're the follow-up questions a partner asks once the boxes have done their job. Use them when asked; none of them goes in a box.

- BehaviorChangeBench's judges agree with blinded human labels 83% of the time, against 87% between two humans. Top model scores fall from 0.90 to 0.65 on the adversarial branches.
- Elenchus ran behind deterministic output gates and a 1,282-test offline suite. Its grader showed a scoring bias (p = 0.000244) and was retired, and a second grader blinded by function signature took back credit the first had given too easily.
- 87,100+ model turns over 73 days (resume of 10-17); deck v3 adds about 109,000 tool calls.
- How the hold works: a project names the checks it trusts, Felix records which code they passed on, an agent stopping on code they haven't passed on is sent back once, and `felix merge` refuses a branch without a current pass.
- Of the 206 holds, 135 were checks that last ran on different code, 39 checks that never ran in that checkout, and 29 checks that failed on the exact code.
- Price, as a hypothesis only: about $1,000 a month plus $40 a committer.

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
