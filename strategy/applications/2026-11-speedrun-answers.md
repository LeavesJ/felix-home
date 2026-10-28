# a16z speedrun SR008: application answers

Draft, 2026-10-27, for the form at speedrun.a16z.com/apply (closes 2026-11-01, 11:59 PM PT). The facts come from `2026-11-speedrun-brief.md` beside this file, `docs/direction.md`, the public README, investor deck v3, the resumes of 2026-10-17 (`Jarron_Deng_Resume_May_2030.pdf`) and 2026-09-30 (`Deng_Jarron_Resume_Berkeley_20260930_v6.pdf`), and Peter Washington's emails of 2026-09-12 and 2026-10-16. A separate reader then checked every sentence against those sources, and its corrections are in. Each text box's heading gives its character count against the form's limit, and filling a `[TK]` changes the count. Lines marked `[TK: ...]` are yours to fill.

## Before you submit

1. **#464 is on main** (7b0521a1, 10-27). `docs/direction.md` now allows a narrow commercial track that includes fundraising applications, and brings the second host forward: Factory's Droid, then Codex. The anything-else box says exactly that.
2. **Sam Schmidgall's name.** Your BehaviorChangeBench notes (`private/01_mentors.md`) say his involvement is meant to stay separate unless Anthropic and Google both agree, and not to publish his name or affiliation without asking Peter first. The answers use the resume's wording, a Google DeepMind and UCSF TECH Lab project, and name nobody. Ask Peter before adding names.
3. **The NeurIPS line.** Peter's 10-16 email asks for the Intro, Related Work and Methods "in the format of a NeurIPS eval track paper". His 09-12 email sets the goal of submitting "ideally by early next semester". The venue and its deadline were still open on your 10-16 list. The answer says the paper is being drafted in that format and aimed at next semester. If Peter has since confirmed NeurIPS as the venue, it can say so outright.
4. **Entity and IP.** Nothing is incorporated under Daimonion yet. The brief records that whether Elenchus Labs' invention-assignment agreement reaches Felix "is genuinely unclear". Settle that before any term sheet.
5. **Your resume and the old deck.** Your resume and deck v4 still say 363 stops blocked and 35.7%. The answers and the new deck use 206, so upload the new deck (`pdf/2026-11-speedrun-deck.pdf`), not v4.
6. **The pilot line.** The anything-else box says the first outside pilot is planned for February. Be ready to say, when asked, that the team is at a company your family is connected to, that it's agreed in principle and unsigned, and that it needs Felix to run inside their network. Those details are in the interview list, not the box.

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

### Tell us more about the team (834 of 1000, before the [TK]s)

<!-- answer:team -->
I'm building this because I needed it first. I hand coding agents as much of my work as they'll take, and the more I gave them, the more often one would tell me a job was done when nothing had shown it was. I could have pulled back and given them less. I wanted to give them more, and that meant building something that checks their work for me. Felix now checks the agents on my own projects.

I think that's the right way in. The teams that get the most out of agents won't be the ones that trust them least, but the ones that can check them. And checking AI is work I've already been doing: at Elenchus and at BehaviorChangeBench, a lot of my best work was catching AI being wrong, my own included.

Right now it's just me [TK: or name a cofounder in progress], and if I get in, I'll take a leave from Berkeley for spring 2027 and build this full time in San Francisco.

Advisors: [TK: Felix advisors, or cut this line]
<!-- /answer -->

## Startup details

**Startup name:** Daimonion. Felix is the product the description and the other answers describe, so no other box changes.

### One-liner (58 of 100)

<!-- answer:oneliner -->
Deterministic senior engineer for autonomous coding agents
<!-- /answer -->

### Startup description (795 of 800)

<!-- answer:description -->
The same AI model can vibe-code a demo or engineer a product. Felix sits on top of your coding agents and makes them do the second. It keeps a list of what each project needs, including what nobody asked for, like a rate limit on a public endpoint. Each need gets a test written by an agent other than the one that did the work, and the test has to catch a planted bug before it counts. Code, not a model, decides when the work is done, and every bug that slips through becomes a new test. CI runs the tests you already have. Felix decides which tests the work needs and who writes them. A model can add to the list, but only a passing test can cross something off. On my own projects, it has sent agents back 206 times, mostly for calling work done on tests that never ran or ran on older code.
<!-- /answer -->

**Primary category:** [TK: the list wasn't in the paste. Developer tools if it's there.] **Secondary:** AI infrastructure, or security if there's no infrastructure option.

**Where you'll build:** San Francisco, California, United States.

**Founded:** [TK: the form showed July 2026. The resume and the repository both start Felix in August 2026 (its first design documents are dated 2026-08-09).]

**Website:** github.com/LeavesJ/Felix, until there's a site.

### Anything else we should know? (985 of 1000)

<!-- answer:anything -->
Here's where this goes. Today you prompt an agent and hope. Felix becomes the layer between you and your agents. You say what you want and make the calls that are yours. Felix works out what engineering that takes, hands it to agents in short sessions with only the tools each one needs, and won't call it done until it's checked.

The agent vendors can't be that layer. A vendor grading its own agent is the same problem one level up, and teams already run agents from more than one vendor. Felix doesn't care which model wrote the code. It runs on Claude Code today, with Factory's Droid and then Codex next. My first buyer is the platform lead at a 50 to 500 engineer company running several coding agents, and the first outside pilot, with a semiconductor supply-chain software team, is planned for February.

If you use Claude Code, clone github.com/LeavesJ/Felix and run felix audit. It installs nothing and shows you how often your agent finished on an edit nothing had checked.
<!-- /answer -->

## Show us more (all optional)

**Team video:** skipped, by your decision of 10-27. The slot is optional.

**Pitch deck:** optional. See "The deck" below before uploading anything: deck v4's slide 8 still says "363 unverified stops blocked", and these answers use 206.

### Traction (714 characters, no limit shown)

<!-- answer:traction -->
Pre-revenue, and Felix is in daily use on my own projects. In six weeks across 43 of my sessions, it stopped an agent from calling something done 206 times. Almost every time, the agent's evidence was stale (the tests had last run on older code), missing (they'd never run), or bad (they'd failed on the very code it was handing over). Sent back, the agents reran their checks about 130 times, and at least 15 of those runs failed, problems that would otherwise have slipped through. The number I'm driving down is how often a person has to step in: in a September pilot, readers marked 31% of my turns as me doing work the agent should have done. Felix is open source under Apache-2.0 at github.com/LeavesJ/Felix.
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
| One-liner | The form's own shape, "AI-powered therapist for Gen Z": a twist, a familiar role, an audience, and no verb. "Deterministic" is the trust half, where code decides and no model does. "Senior engineer" is the role that knows what the work needs, the rate limit nobody asked for included, and signs it off. "For autonomous coding agents" keeps the autonomy and puts Felix above the agents rather than beside Devin | Your internal phrase, the autonomous engineering control plane, made concrete; cold reads of 10-27, where role nouns alone read as coordination (manager, org) or a linter (standards), and taglines and "that does X" clauses weren't punchlines |
| Description | One loop, not two halves: vibe coding against engineering, where the difference is what the work is held to. Felix keeps the list of what each project needs, has each need tested by an agent other than the producer, qualifies the test on a planted bug, and lets code alone decide done. The CI line answers the question every cold reader asked. The model-may-add, only-a-test-may-close line is the join | `docs/2026-10-19-ai-engineering-vs-vibe-coding.md` (§1's thesis, §13's row lifecycle and the comparison with Factory's per-mission contract); v3.2's rule that a model may propose but never make its conclusion authoritative; the README's 206 holds, of which 174 were checks that never ran or ran on other code, hence "mostly". No host or plugin is named, since Claude Code is only where Felix runs today |
| Anything else | The full picture: the layer between a person and their agents, why the vendors can't be it, the second host, the first buyer and pilot, and something they can run | The README's "Where it's going"; the brief's vendor answer and first buyer; #464's row 19; direction §6 for the pilot |
| Traction | The numbers, said plainly | The README's 206 holds in 43 sessions; the episode pilot's 31% (`docs/2026-09-23-episode-pilot.md`) |

## Saved for the interview

These are true, and they're the follow-up questions a partner asks once the boxes have done their job. Use them when asked; none of them goes in a box.

- BehaviorChangeBench's judges agree with blinded human labels 83% of the time, against 87% between two humans. Top model scores fall from 0.90 to 0.65 on the adversarial branches.
- Elenchus ran behind deterministic output gates and a 1,282-test offline suite. Its grader showed a scoring bias (p = 0.000244) and was retired, and a second grader blinded by function signature took back credit the first had given too easily.
- 87,100+ model turns over 73 days (resume of 10-17); deck v3 adds about 109,000 tool calls.
- How the hold works: a project names the checks it trusts, Felix records which code they passed on, an agent stopping on code they haven't passed on is sent back once, and `felix merge` refuses a branch without a current pass.
- Of the 206 holds, 135 were checks that last ran on different code, 39 checks that never ran in that checkout, and 29 checks that failed on the exact code.
- Where each half stands. Live and in daily use on your projects: the Stop hold, receipts and their staleness, `felix merge`, obligations that block while unchecked, project setup with a starter set of plugins, and plugin discovery that reads a plugin before installing it. Built with little real use: obligations a model proposes, advisory only (22 proposed on two projects, none admitted yet). Next: the join, where an obligation stays unmet until a qualified checker is attached. Designed, not built: `felix dispatch`. Felix has one real user so far, you.
- What the description pitches ahead of the code. A test written by an agent other than the producer is a working convention (blind authorship), and Felix doesn't yet assign it. The planted-bug rule qualifies Felix's own checks today. A model's additions are advisory until admitted. Turning a slipped bug into a standing test is designed but not built yet; direction lists its first step, classifying misses, as a candidate lane item. Slide 4 of the deck pitches the same loop. "Deterministic" in the one-liner is about the verdict: models propose what the work needs, and only a passing check decides it's done.
- The pilot: a semiconductor supply-chain software team at a company your family is connected to, agreed in principle, nothing signed, and waiting on Felix running inside their network.
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

**Upload `pdf/2026-11-speedrun-deck.pdf`.** It has ten slides, built 10-27 from `deck/2026-11-speedrun-deck.html` and `deck/deck.css`. Speedrun's partners disagree about decks. Andrew Lee said in a May 2025 Q&A that a deck "can sometimes get in the way". Josh Lu said he couldn't think of an interview he had scheduled without clicking the deck link, and the January 2026 roundtable settled on seven to ten slides. The FAQ itself only covers uploads. The team section gets most of the review time, so the deck backs it up rather than repeating it.

Each slide answers one question a partner asks, in the order speedrun reads them:

| # | The question | The slide's claim |
|---|---|---|
| 1 | What do you do? | Deterministic senior engineer for autonomous coding agents |
| 2 | Why should anyone care? | "Your agent says it's done. Nothing has checked." Two agent reports redlined: tests that last ran on older code (135 holds) and the real deploy with no rate limiting |
| 3 | Why you? | "I needed it first": 87,100+ turns, BehaviorChangeBench, Elenchus, full time for spring 2027 |
| 4 | What do you know that others don't? | Engineering is what the work is held to. The loop: need, a test by another agent, a planted bug, code decides, a miss becomes a need |
| 5 | What's your progress? | 206 holds, 135 / 39 / 29 / 3, about 130 reruns, 31%, the hooks load in Codex in a test run |
| 6 | Why now? | Agent labor got cheap and knowing it's right didn't: valuations, vendors reviewing their own agents, METR, Anthropic's docs, Rauch |
| 7 | Why hasn't anyone done this, and who else is here? | "The judge can't be the one being judged." A 2x2: who decides done (a model or code) against what the work is held to (only what someone wrote down, or what the project needs including the unasked) |
| 8 | What happens as models get better? | Difficulty falls each generation and a shipped mistake costs as much as ever. Felix takes the ideas and keeps the verdict |
| 9 | How big, and how does it make money? | The first buyer, self-hosted pricing, and 36.5M developers x $480 a year = $17.5B at the committer price, with Protect AI and DX as comparables |
| 10 | Where does it go? | The layer between you and your agents. Live today, then December to January, February and Demo Day |

**The theme.** Each slide is drawn as an engineering drafting sheet, with zone marks on the frame and a title block in the corner. On a drawing, the person who draws never checks, so every title block reads "Drawn by Jarron Deng" and "Checked by: a reader who didn't write it". A blind reader did check the deck. The colours are Felix's own, from `assets/felix-mark-light.svg`. Red is the checker's pencil and appears only where a check found something. The type is DIN Condensed, from the German standards body, with Charter for body text. Monospace is used only where a slide quotes an agent.

**Outside numbers, verified 10-27 against primary sources.** Several in our own notes were wrong:
- Cognition is at $48B with a $1B run-rate (Sep 2026); $26B was its earlier Series D.
- METR's "38%, 0 of 15" is an older 2025 study. The March 2026 note says about half of test-passing agent PRs would not be merged.
- The Rauch quote has "I think," restored.
- Claude Code's $2.5B run-rate dates from February and is left out. If Anthropic's S-1 is public before Nov 1, check it for a newer figure.
- Acquisition prices come from filings only: Protect AI $634.5M (Palo Alto 10-K). DX's "about $1B" comes from Atlassian's announcement.

Each sourced slide prints its sources at the bottom.

**What the deck pitches ahead of the code:** the same items as the interview list, plus slide 10's December to January and Demo Day milestones, which are plans.

**To rebuild the PDF after an edit,** print the HTML with headless Chrome at 1600 x 900. The renderer is the same one used for the answers PDF, with the page size set by the stylesheet's `@page`.
