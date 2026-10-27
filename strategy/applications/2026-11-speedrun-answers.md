# a16z speedrun SR008: application answers

Draft, 2026-10-27, for the form at speedrun.a16z.com/apply (closes 2026-11-01, 11:59 PM PT). The facts come from `2026-11-speedrun-brief.md` beside this file, the public README, investor deck v3, the resume of 2026-10-17 (`Jarron_Deng_Resume_May_2030.pdf`), and Peter Washington's email of 2026-10-16. Each text box's heading gives its character count as drafted against the form's limit; filling a `[TK]` changes the count. Lines marked `[TK: ...]` are yours to fill, and the answers do not depend on them.

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

### Relevant experience (910 of 1000)

<!-- answer:experience -->
I lead BehaviorChangeBench, a benchmark of how frontier models coach people through health-behavior change over several sessions, mentored by Sam Schmidgall (Google DeepMind) and Peter Washington (UCSF TECH Lab). I calibrated its LLM judges to 83% agreement with blinded human labels, against an 87% ceiling between two humans, and our adversarial branches pushed top model scores from 0.90 down to 0.65. We're drafting it for the NeurIPS evaluation track. Before that I co-founded Elenchus Labs and shipped an LLM product to 200+ Berkeley users, then caught its own grader finding an effect in data that had none (p = 0.000244) and retired it. Earlier I built ReserveGrid, a Rust verifier that catches tampered Bitcoin block templates. Felix came out of running coding agents for 87,137 model turns over 73 days. The same failures kept coming back, so I turned them into checks that run without anyone asking.
<!-- /answer -->

### Tell us more about the team (617 of 1000)

<!-- answer:team -->
It's just me for now. I'm part time today because I'm an EECS student at Berkeley. If I'm accepted, I'll take a leave of absence for spring 2027 and work on this full time in San Francisco.

The engineering team is agents. Most of Felix was written by the coding agents it governs, under its own gate, and every hold it has made so far was on that work. Each failure Felix guards against is one I hit first in my own repositories.

I don't have a cofounder, and I'd rather say so than list someone who isn't committed. [TK: a possible cofounder, named as in progress]

Advisors: [TK: Felix advisors, or cut this line]
<!-- /answer -->

## Startup details

**Startup name:** [TK: see "The name" at the end.]

### One-liner (92 of 100)

<!-- answer:oneliner -->
Decides when an AI coding agent's work is really done, for teams shipping agent-written code
<!-- /answer -->

### Startup description (797 of 800)

<!-- answer:description -->
An AI coding agent runs your tests halfway through a task, keeps editing, then tells you everything passes. It did, on an earlier version of the code. The agent that wrote the code is usually the only one saying it's done. Felix sits between the agent and the merge. A project names the checks it trusts, and Felix records exactly which code they passed on. It sends an agent back when it tries to stop on code nothing has checked, and won't merge a branch without a current pass. That half runs today as an open-source Claude Code plugin. The harder half comes before any check runs: working out what a project owes. An agent once shipped a deployment of mine with green tests and no rate limiting, because nobody had asked for one. That's what I'm building next: finding the checks nobody wrote.
<!-- /answer -->

**Primary category:** [TK: the list wasn't in the paste. Developer tools if it's there.] **Secondary:** AI infrastructure, or security if there's no infrastructure option.

**Where you'll build:** San Francisco, California, United States.

**Founded:** [TK: the form showed July 2026. The resume and the repository both start Felix in August 2026 (its first design documents are dated 2026-08-09).]

**Website:** github.com/LeavesJ/Felix, until there's a site.

### Anything else we should know? (908 of 1000)

<!-- answer:anything -->
What's real and what isn't. Felix runs only on Claude Code today. Factory's Droid and then Codex are next, because a verdict that works on one vendor's agent is that vendor's opinion. It has one real user, me. The half that finds missing obligations is designed, and its test is settled: a seeded set of known omissions, scored against plain Claude Code. That test hasn't run yet. The first outside test is a February pilot with a semiconductor supply-chain software team at a company my family is connected to. It's agreed in principle, nothing is signed, and it waits on Felix keeping their code inside their network, which it can't do yet.

If you use Claude Code, you can try the idea on your own history. From a clone of github.com/LeavesJ/Felix, felix audit reads the transcripts Claude Code already keeps, writes and installs nothing, and counts the turns that ended on an edit no check had run after.
<!-- /answer -->

## Show us more (all optional)

**Team video:** skipped, by your decision of 10-27. The slot is optional.

**Pitch deck:** optional. See "The deck" below before uploading anything: deck v4's slide 8 still says "363 unverified stops blocked", and these answers use 206.

### Traction (589 characters, no limit shown)

<!-- answer:traction -->
Pre-revenue, with no customers yet. Across 43 of my own sessions between August 10 and September 21, 2026, Felix held an agent's attempt to stop 206 times. All but three had one of three causes. In 135 the checks had last run on different code, in 39 they had never run in that checkout, and in 29 they had failed on the exact code the agent was stopping on. Sent back, the agents reran the checks about 130 times, and at least 15 of those runs failed. Without the hold, they would have stopped before running any of them. The engine is public under Apache-2.0 at github.com/LeavesJ/Felix.
<!-- /answer -->

**Funding history:** [TK: none, if no outside money has gone into Felix.]

**Active fundraising round:** [TK]

**Where did you learn about speedrun?** [TK: yours. Your inbox has the Berkeley EECS jobs list posts about a16z coffee chats, the 11/4 info session and the 11/5 pitch night.]

## The name

The product stays Felix: the public repository, the README, the logo and the record all carry it. What you're choosing is the name in the "Startup name" box, which can differ from the product, the way Anysphere makes Cursor. Two facts about "Felix" on its own: Felix Capital is a London venture firm (Peloton, Deliveroo), so a VC reader may hear a fund, and the word is common.

| Option | Why | Against |
|---|---|---|
| **Felix** | One name everywhere. The reviewer clicks the GitHub link and sees the same word. Renaming before incorporation costs nothing, and speedrun helps set up the company. | The collision and the plainness you already noticed. |
| **Detent** | A detent is the catch that holds a moving part in place until enough force moves it. Holding an agent until the proof exists is what Felix does. Searches found no company by that name in AI or developer tools. | Two names on one application until people learn them. |
| **Escapement** | The part of a clock that lets energy out in measured steps, which fits landing work only when it's proven. Nothing found by that name in software. | Long, and hard to spell when heard aloud. |
| Assay (taken) | An assay tests what the maker claims. | "tryassay" already sells AI code verification. |

## The deck

The upload is optional, and the speedrun team's own FAQ says a deck "can sometimes get in the way". Send one only if it is short and agrees with every number above. Deck v4 (`~/Downloads/Felix_Autonomous_Engineering_Control_Plane_Investor_Deck_v4.pptx`, 18 slides) is a thesis deck. It argues the idea well, but it says 363 and 35.7% where these answers say 206, and its two invariant slides centre on receipts, which the brief says not to lead with because signed, tree-bound receipts already exist elsewhere.

A proposed nine-slide deck, cut from v4 and the brief:

| # | Slide | From |
|---|---|---|
| 1 | Name and the one-liner. | new |
| 2 | The failure: the agent says "done" on code that changed after the tests ran. | v4 slide 8, without its 363 and 35.7% line |
| 3 | What Felix does with one change, start to finish: the hold, the receipt for that exact code, and the merge that refuses without it. | v4 slide 9, the README's walkthrough |
| 4 | The evidence: 206 holds in 43 sessions, the three causes, about 130 reruns, at least 15 of them failed. | README |
| 5 | The harder half: the rate-limit story, what a project owes, and the seeded-omission test that is designed but hasn't run. | README, brief |
| 6 | Why now: METR's maintainers rejected about half the PRs that passed the grader; every vendor reviews its own agent's work. | brief, METR note of 2026-03-10 |
| 7 | Who pays, marked as a hypothesis: platform leads at 50 to 500 engineer teams running two or more agent vendors, self-hosted, paying for the verdict rather than for tokens. | brief |
| 8 | Why me: BehaviorChangeBench, Elenchus, ReserveGrid, 87,137 model turns. | v4 slide 6, resume |
| 9 | The next twelve weeks: the M1 attended loop, the M2 MVP with the seeded-omission result, the February pilot, the second host, and full time from February. | brief roadmap |

Out from v4: the kernel and browser analogy (slide 11), invariant infrastructure for finance and healthcare (slide 16), and the two thesis slides at the front (2 and 3). They widen the claim past what has been measured, and a reviewer reads the numbers first.

Still open: whether to send a deck at all, and if so, whether it is the nine slides above or v4 with only its numbers fixed.
