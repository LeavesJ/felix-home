### 2026-10-29: the capability lane restarted, and the founder's decisions on what Felix is

**Docs only so far (branch `claude/lane-situations-owed`).** This session
checked the capability plane against direction. It laid out every
capability-plane design on file in one document
(`docs/2026-10-29-capability-plane-designs-on-file.md`, with its PDF), and it
worked through the thesis with the founder in conversation. The lane's first
item is not built yet: intake, the intent design's §9 slice "situations owed".
It waits on a written design he approves.

**Why now.** The founder, 10-29: "supposedly, according to your direction map,
we should have begun working on capability plane simultaneously long ago. You
can check the directions marked down to verify that statement. I think we
really need to get it going."

**What was found.**
- Since row 25 (10-19: build intake now), main has taken 17 commits. One
  touched capability-side code, the audit's fixes, and none was a lane item.
- The 22 proposed obligations are still at 0 admitted.
- Nothing starts a lane session unless the founder or the carrier does.
  Nothing counts the one-in-four share of row 15, so the lane fell to zero
  without a warning.
- The audit swept the code that exists, which is mostly trust code, so it
  could not see what was never built. This is the stagnation of 09-25 again.

**Founder decisions, binding from this section.**
1. **The first client is a generic software development team.** The rumored
   industrial prospect is not standing ground: "this is rumored, unconfirmed.
   don't make this the standing ground. Just envision that our first client
   will be a software dev team". Read row 28's "keep that weight in view" this
   way. Egress control is one enterprise ask among others, not a
   prerequisite.
2. **Felix's role is the senior manager over the whole pipeline.** In his
   words, Felix is "dynamically in charge of disaptching + communicating +
   organizing (again senior manager remember) role, delete distribute tasks,
   all of the above, plus the entire pipeline of from ideas, to skills/tools
   installations, ledger, contract, answers, obligations, routing, model
   adjustment, token optimization, scaffolding, and more I did not name." He
   was asked which of four ideas felt most like Felix: the standing need
   ledger, the contract and lease, answers at the moment, and one
   obligation's whole life. He chose all four.
3. **An engineer's run ends in one shot, with no questions.** The options were
   "Done, plus what it owed", "Questions, then done" and "Plan to approve,
   then done". He answered: "Final state should be that second option is not
   even an option bc felix's pipeline already figures out everything. 'what
   changed owed that nobody asked for' is indeed the hardest part isn'
   it...there's so many things. But we'll design it when we get there".
4. **Positioning: the independent manager.** He chose it over "Senior
   engineer, as pitched" and "Orchestrator first". Felix is the engineering
   manager your agents report to, whoever made them. It decides what the work
   owes, who checks whom and what counts as done, and dispatches through the
   agents the team already uses. Its number is verified work per hour of the
   team's attention. Felix rents the dispatch, and it owns the judgment and the
   cross-vendor record of accepted outcomes. The pitch (tag `pitch/2026-10-27`)
   is his document and is not edited here.
5. **The lane's share is half until intake lands, then one in four.** He chose
   it over "One in four, enforced" and "Felix sets the share"; row 15 gives the
   share to him. Felix counts the share. Whenever the lane is short, the first
   open lane item goes to the next session that starts without a task from
   him, and trust work gets the other half in the meantime. "Intake lands"
   means the intent design's §9 slice merges on main.

6. **Two editions, enterprise first.** He set out "a clear enterprise versus
   commercial separation". The commercial edition is for "founders and people
   who want to build but lack the engineering hygiene and the entire
   engineering team to do so, right? Like a solo company founder". The
   enterprise edition is for software teams, where "a lot of things overlap,
   but there are some small details that are like very critical to change".
   Enterprise comes first: "that'd be very enterprise oriented which is what
   we're doing first for our potential users". In a team, Felix starts
   underneath, briefing agents and checking changes, and "later becomes this
   figure inside slack". He expects enterprise to be "a lot harder to build",
   with commercial derived from it afterwards. He then drew the scope line:
   "I don't want to make it so this becomes another Claude duet, ChatGPT
   bots", and "we should really stick with the engineering ground first, and
   later use the engineering leverage to introduce the departmental liaison".
   More interaction between managers and engineers, and a better Slack
   presence, come "once we ship the MCP later on".
7. **Inside a company, the first champion is the engineering manager, and the
   target is the whole engineering department.** In his words: "entire
   engineering department, so ig engineering manager....but like that'll just
   be natural you know once the autonomous engineering control plane is built
   it'll spread across entire engineering department".

**This session's reading, not his decision.**
- **Model adjustment and token optimization.** He pointed at report v5: "it's
  in the docs we had...i remember second report had many points in there a
  lot of design brainstorming". The 10-01 review's ruling, row 17 (D1),
  already covers what he listed:
  - the host picks the model;
  - Felix raises the model when the stakes call for it, and escalates a failed
    check by one tier;
  - it keeps accepted outcomes per model, and saves tokens through context;
  - the held-out replay decides whether adaptive routing is built.

  Row 17 stands unchanged.
- **Two guesses.** The session played back two guesses and he did not correct
  them:
  - "organizing" includes cancelling or reassigning tasks mid-run;
  - Felix may mount a tool by itself once it has shown it can use that tool
    well (his 10-29 floor).

  Treat them as this session's reading until he confirms them.
- **Felix as software, not only a plugin.** He asked: "do you not think we need
  an actual software?". The session proposed three layers, which he has not
  confirmed:
  - the judge stays a small deterministic engine on bash and git;
  - plugins become adapters, one for each host or tool;
  - new software sits on top: a desktop app for the commercial edition, and an
    org service for the enterprise edition that keeps the company's code inside
    the company.

  Felix cannot run on a server today.

**Not done.**
- The lane counter and the hand-off are not built.
- The strategy pass is still pending: whether the invariants hold, what is
  missing, and whether intake-first is the right order. So is the written
  design.
- Folding items 1 to 7 into `docs/direction.md` waits for his yes in its own
  draft PR.
