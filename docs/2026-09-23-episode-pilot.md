# Building Felix, measured as Felix's own workload: a pilot of twenty episodes

On 2026-09-23 the founder pointed out that the way Felix is being built is the
way Felix is meant to work. The founder brings an idea, sharpens it, gives
feedback and judgment, and almost never asks an engineering question; the agent
does everything else. So the history of building Felix is a record of the
whole pipeline Felix will run for its users: what the owner meant, what
happened in between, what was delivered, and whether it was what they meant.
The founder also pointed out that Felix's `lessons.md` learns only engineering
from that record, and that a new thing is needed for the rest.

This pilot reconstructs twenty episodes from that record, weighted to the big
architectural decisions, and asks what the new thing has to be.

**What it found.**

- **About a third of the founder's effort went into the agent's job.** Of 265
  non-operational founder turns, 81 (31%) were labelled as the founder doing
  work the agent should have done, by a strict majority of the readers who saw
  them. Weighted by characters typed, the share is also 31%. The three largest
  of those turns were architecture-level design texts (13, 12 and 11 thousand
  characters), not engineering corrections.
- **The founder's effort went to three places.** Pushing past stops that should
  not have happened, answering questions the agent should have decided, and
  restating decisions already made. Those three account for 52 of the 81 turns.
- **By the readers' account, every episode fell short somewhere of what was
  meant.** The founder has rated none of them. The shortfalls fall into five
  recurring patterns, the most common being that the words shipped but the
  behaviour did not.
- **The interaction lessons already exist, as prose, and prose is what failed.**
  One lesson was mounted into a session twice and broken about an hour later
  (E19). One standing direction was restated eight or more times while the
  engine printed the opposite for 33 days (E15). The new thing therefore cannot be
  another table of advice. It has to be mechanisms that fire at the moments
  the failures happen, measured against the owner's turns.

## 1. What was measured, and how far to trust it

**The four layers.** Each episode is one record with four parts:

- **Intent.** The founder's first statement, each sharpening, the final intent,
  and the docs that recorded the founder's reasoning at each checkpoint.
- **Middle.** Every founder turn in the episode, labelled by kind (codebook in
  `docs/episodes/method/codebook.md`), with what the agent did next.
- **Delivery.** What was actually submitted: pull requests, docs, memory entries
  and mechanisms, what the agent claimed was done, and the gate state.
- **Outcome.** Whether the delivery was what the founder meant, and what the
  founder had to clarify. What went wrong, what was missed, who noticed and how
  late, and what was reversed and by whom.

**How the records were built.** One workflow, `wf_cffda6be-01f`: 46 agents,
3,222 tool calls, about 14.5 million subagent tokens, 2 hours 12 minutes. Its
script, the prompt indexer, the transcript reader and the recount are in
`docs/episodes/method/`.

1. **Discovery and selection.** Three independent sweeps (the founder's prompts
   in order, the docs and handoff sections, both memories) proposed 100
   candidates. One agent kept 20 and recorded a reason for each of the 25 it
   merged or dropped (`docs/episodes/2026-09-23-pilot-selection.jsonl`).
2. **Reconstruction.** One reader per episode worked from the transcripts
   themselves (36 sessions), not from the docs alone.
3. **Verification.** One skeptic per episode reopened the sources and tried to
   refute the record. They checked 1,462 claims, refuted 241 (16%), marked 68
   unsupported and added 218 missed items. All 20 records ended as "holds with
   corrections", and the corrected records are the ones used here
   (`docs/episodes/2026-09-23-pilot-records.jsonl`).
4. **Synthesis and critique.** One agent synthesised the records and one critic
   attacked the synthesis. This report is that synthesis rewritten with every
   correction the critic made that held on checking.

**The turn table.** Episodes overlap: one founder turn (2be823c0 2026-09-02T23:18Z)
appears in six of them. So every founder-effort figure here comes from a
de-duplicated table, `docs/episodes/2026-09-23-pilot-turns.jsonl`. Each of the
622 exchange rows is matched to the real prompt in the prompt index (same
session, nearest timestamp); 283 of the 321 distinct turns matched, and the
other 38 are question-tool answers and queued attachments the index misses.
Each episode that saw a turn casts one vote, its most common label for that
turn, and a turn counts as leakage only on a strict majority of votes. Ties are
reported separately.

**Limits. Read these before any number.**

- **Twenty episodes, one founder, one product building itself.** The episodes
  were chosen for size and contest, so they lean toward failure. In particular,
  E05, E14 and E15 were chosen partly because the founder had to repeat
  himself, and they hold 56 of the 177 leakage labels that readers gave.
- **Labels are reader judgments, and readers disagree.** 97 turns got a
  leakage label in at least one episode and 81 by strict majority, with 11
  ties. Only 34 got it from every reader where two or more readers saw the
  turn, and 118 of the 265 non-operational turns had a single reader.
- **The corrected records were not re-verified.** At least two errors remain
  that the critic found: E01's one-liner, fixed below, and E03 against E15 on
  when a review was requested.
- **Readers were primed.** They ran with the founder's auto-memory index loaded,
  which already names rules such as "Felix merges its own PRs", so they were
  primed to see restatements of those rules.
- **"Matched intent" is a reader's inference.** The founder rated no episode.
  The rubric scores any shortfall as partial, so even the episode chosen as a
  clean delivery (E20) scores partial. The 19 partials and 1 no are the
  rubric's ceiling, not a finding.
- **Some founder input is outside the corpus:** the 2026-08-09 founding
  sessions, one phone session, ChatGPT conversations, and images and PDFs.
- **The labels are engineering-shaped.** When the founder had to restore a
  design the agent had narrowed, the turn was usually labelled
  "direction-feedback" or "idea", so it counts as intended.
  - Example: the 23:18Z turn above is direction-feedback in all six episodes
    that cite it, although E10 records that the recommendation it answered had
    given away what the charter assigns to Felix.
  - Example: the turn where the founder supplied v3.2 (2be823c0 2026-09-03T06:45Z)
    is labelled "idea".

  The leakage figures below therefore understate the founder's corrective work
  on the big decisions.

## 2. The twenty episodes

Turns are the episode's own distinct non-operational turns, and leakage is by
the episode's own labels. Details of each are in the records file.

| Id | Episode | Turns | Leakage | The story |
|---|---|---|---|---|
| E01 | Founding charter: from "governance layer" to "pilot of implementation", for anyone | 67 | 18 (27%) | The owner-what / agent-how split was stated at fa389b5e 21:23Z and reached the charter at 21:26Z (0ea48090). The founder's audience ("anyone", "a stranger") became a charter test only in #290, six weeks later. |
| E02 | Felix governs itself; earned autonomy (#5) | 30 | 12 (40%) | "Don't exempt Felix" turned into seven red-merge approvals in five hours. The #5 design was recorded faithfully and never built. Merge autonomy came by direction on 09-12/13 instead, and the two were never reconciled. |
| E03 | The trust root: V_n judges V_n+1 (route 2), #2, floor versus wall | 35 | 6 (17%) | The principle was stated in one night (08-14). Its promotion spec waited 26 days (#239). #2 and #28 were still open 40 days later. |
| E04 | Invariant 2 and staying in bash | 9 | 1 (11%) | The founder chose "let Felix call a model". The agent committed a narrower rule and shipped with no model. On 09-19 the agent's own panel reversed its typed-core position. |
| E05 | Where Felix stops and asks; the declared objective | 42 | 17 (40%) | Each correction became a written rule within minutes, and the leakage continued. The declared objective (founder interruptions per session) was never computable: every `escalated` row has session `unknown`. |
| E06 | Repository privacy and the public snapshot | 24 | 5 (21%) | The repo was found public and pitched as an opportunity before any exposure inventory, then made private that night. The first public snapshot was uninstallable for five days. |
| E07 | Capability routing: keyword router, rejected registry, advisory redesign | 65 | 25 (38%) | On day one the ask was "Felix picks the tool". On the agent's latency question the founder chose to drop the model, and that choice shipped as the keyword router. Four table patches, a rejected registry and a redesign followed, and the router is now "expected to die". The only episode scored **no**. |
| E08 | Concurrent sessions and the concurrency ladder | 22 | 8 (36%) | "Live engineers talking to one another" became a four-rung ladder. Practice jumped to about ten sessions without rung 3, and the founder is still the message bus between them. |
| E09 | Felix as an omission engine | 21 | 10 (48%) | The rate-limit miss behind the thesis was fixed locally in ten minutes and never pushed. No obligation has yet been derived and admitted. |
| E10 | "Is Felix even worth building?": the worth audit | 9 | 5 (56%) | A 31-agent audit keyed on what fired recommended keeping only the gate. The founder rescued the thesis. |
| E11 | v3.2: four agent kernels rejected, the founder's architecture adopted and amended | 26 | 10 (38%) | Four agent-derived kernels in about seven hours each narrowed Felix, and the founder wrote v3.2 himself. The founder told the agent to store the amendments and abide by them. The clause by which they supersede v3.2 was shown once and never got an explicit yes. |
| E12 | ECC: advised against, installed anyway, hooks off in two steps | 8 | 2 (25%) | Memory said "installed nowhere" for 14 days. The settings edit was listed as the founder's job five or more times and was never asked as one yes, until the founder started it himself. |
| E13 | Commissioning and the consent grant | 13 | 6 (46%) | The first-encounter toolbox was built as asked. Its grant reused a whole-table hash and became the founder's most repeated chore; unattended commissioning ran on about 2 of 17 days. |
| E14 | Overnight sessions, handoffs, session lifetime | 33 | 12 (36%) | The overnight rules were typed at the start of six nights before #222. #222 ran one night with its hooks inert. The founder was left policing an 847K context. |
| E15 | Felix merges its own pull requests | 41 | 27 (66%) | The direction was stated or restated at least eight times. The engine printed "a human merges" for 33 days after escape.sh. |
| E16 | The endgame: control plane, capability plane and trust plane | 30 | 5 (17%) | The agent measured launch-time mounting on day one and then lost the finding for 39 days; an outside grader re-supplied the framing. Dispatch is unbuilt. |
| E17 | Outside reviews, competitors and the market map | 43 | 8 (19%) | Every relayed review was checked claim by claim. Positioning narrowed twice after it had been recorded, and four stale claims survive in memory, a decision doc and the public README. |
| E18 | Felix becomes a product; roadmap v1 withdrawn | 5 | 0 | The charter was amended within 51 minutes (#290). Roadmap v1, with an outreach track, merged before the founder had read it and was withdrawn 3 minutes 49 seconds later. |
| E19 | #115 dropped a word the engine reads; #123 restored it | 2 | 0 | A reworded gate message broke a grep contract and was live for about six hours. The agent found and fixed it with no founder effort. |
| E20 | #263 pins the merge judge outside the tree it judges | 2 | 0 | Selected as the clean delivery. It shipped 33 days after "route 2.", and #2 and #28, the reasons route 2 was chosen, are still open. |

## 3. Where the founder's effort went

**Leakage by kind.** Strict-majority leakage turns, by their majority kind:

| Kind | Turns | Sharpest examples |
|---|---|---|
| Pushing past a stop that should not have happened | 19 | "if they're due why don't u do it? Why ask me?" (c79569a0 09-12T09:55Z). "stress test it yourself first" (b2baf090 08-18T03:58Z). |
| Answering a question the agent should have decided | 17 | A 12K-character design written to answer the agent's question about how base-version evaluation works (fe3fffd4 08-14T02:02Z). The #227 hash-contents question, which the founder answered while saying the asking "really breaks the felix thesis" (c79569a0 09-13T00:05Z). |
| Restating a settled decision | 16 | Merge authority, from fa389b5e 08-11T00:49Z to b247631e 09-23T08:44Z (E15). "i thought i made it clear over and over again" (614500d8 09-13T23:40Z). |
| Other: mostly typing commands the agent handed over | 14 | The founder was handed a `rm -rf projects/veldra` before #96 had merged, which took a governed project's doctrine offline (0411b62d 08-30). The founder relayed a re-stamp between sessions (cc4cee05 09-23T08:45Z). |
| Catching a claim about state that was false or unchecked | 10 | "i never said default is inline i said be strategic": the agent had quoted its own harness configuration back as the founder's rule (fa389b5e 08-10T21:15Z). The founder's own `felix merge` failed 30 minutes after "done and verified" (b2baf090 08-18T01:48Z). |
| Correcting how something was built | 3 | Parallel dispatch "should be what felix is doing right here" (fa389b5e 08-11T08:16Z). |
| Translating an idea into engineering terms | 1 | A 10.9K-character falsification brief (0f27ee6e 08-19T08:17Z). |
| Reining in overreach | 1 | Unrequested non-Felix reminders in a Felix report (2be823c0 09-03T09:39Z). |

**By characters.** Counting turns weighs a "go" the same as a
twelve-thousand-character design. Of the 181,972 characters in the 228
non-operational turns the index could size, 56,821 (31%) are in leakage turns.
The three largest leakage turns (2be823c0 09-03T06:29Z at 13,049 characters,
fe3fffd4 08-14T02:02Z at 12,090, 0f27ee6e 08-19T08:17Z at 10,857) together are
63% of all leakage characters. Each is the founder writing architecture the
agent had asked for, narrowed or failed to carry.

**By big decision.** The share of each episode's own turns that were leakage
runs from 66% for the merge direction (E15), 56% for the worth audit (E10) and
48% for the omission engine (E09), down to 17% for the trust root (E03) and the
endgame (E16). The episodes where the founder was setting direction (E16, E17)
cost less repair than those where a direction had to be carried into the engine
(E15, E05, E13).

**Over time.** Strict-majority leakage was 31 of 110 turns (28%) on Aug 10–15,
19 of 54 (35%) on Aug 16–31, 25 of 57 (44%) on Sep 1–15 and 6 of 44 (14%) on
Sep 16–23. The last window is small and dominated by idea-heavy sessions. With
single readers on 118 turns and ties moving each window by several points, the
data support no trend claim either way.

**What the agent did after being pushed.** The row labels count 86
`executed` and 35 `verified` moves after leakage turns. But 27 of the 177
agent moves after a leakage turn (15%) were again underreached, a mechanics
question, a misreading or overreach, so being pushed once did not always fix
the pattern.

## 4. Delivery against intent

The twenty shortfalls fall into five recurring patterns.

1. **The words shipped; the behaviour did not.** A correction became a rule in
   memory or handoff prose within minutes, while engine text, tables or older
   records went on saying the opposite.
   - E15: `felix classify` printed "a human merges" until #241, 33 days after
     escape.sh.
   - E02: three coexisting records on who merges Felix's red work.
   - E12: memory said ECC was "installed nowhere" for 14 days.
2. **Decided work slid down the queue or was never built.**
   - E02: the earned-autonomy ledger and the §0d guard were never built.
   - E03: #2's spec of 08-18 was built on 09-13, and #28 is still open.
   - E09: the Elenchus and veldra fixes sit on unpushed branches.
   - E16: dispatch was moved to February.
3. **The agent narrowed the design to what was cheap to prove.**
   - E04: the model judgment the founder chose shipped as mechanical-only.
   - E10 and E11: four kernels, each narrower than the charter.
   - E16: "Capability Plane stays thin", restored by the founder the same hour.

   The defect is the silent narrowing, not the disagreement: in E04 the
   founder's own v3.2 later adopted the narrower principle.
4. **Verified against its own spec, not the owner's use.**
   - E03: route 2 was "done and verified in all three places", and the
     founder's first run failed 30 minutes later.
   - E06: the public snapshot was uninstallable for five days.
   - E19: the marker rename passed an 18-agent review and a green suite.
5. **The owner as the bus.**
   - E08 and E13: the founder relayed state between sessions.
   - E15: the founder typed commands handed over.
   - E12: the founder started a settings edit that was listed as theirs for days.
   - E03 and E06: the agent asked the founder for an approval the platform
     could not count, because the founder had authored the pull request.

**What was overlooked, and who found it.** The records list 193 overlooked
items. The rows are not de-duplicated across episodes, so the proportions
below are approximate.

- **The founder found or triggered the find in 64 (about a third).** The
  founder's finds cluster where the agent misframed the "what": routing (E07),
  session lifetime (E14) and the kernels (E10, E11).
- **The agent and the checks it dispatched found most engineering defects,
  often before merge.** E03, E09 and E11 have seven such finds each. But those
  panels also produced positions the founder then had to reverse: the 31-agent
  worth audit (E10), the kernel rounds (E11), and the 18-agent review that
  passed #115's regression (E19).
- **About 26 items are still open**, going by their lag fields.

Records that contradict each other and states that decay are caught only when
someone runs an audit for them. The agent's own audits caught some (§0bh found
11 false and 26 stale claims in 250). Several were found only by this pilot:
the commission grant stale for 10 days (E13); 10 of 38 merges with no record of
passing the pinned judge (E20); stale claims in the public README (E17); and
the line in `felix-is-an-omission-engine.md` that still says the application
has no rate limiting at all, 20 days after the claim was retracted (E10).

**The longest lags.** About six weeks for the founder's audience to become a
charter test (E01). 33 days of engine text contradicting the merge direction
(E15). 26 days from #2's spec to its build (E03). 20 days, and counting, for the
declared objective to stay uncomputable (E05). About six weeks of session-start
calling HANDOFF.md "standing direction", wording that is still at
`engine/harness/hooks/session-start:498-499` (E14).

## 5. How big decisions actually get made here

| Decision | Originated by | Rounds before it held | Reversed by | How long it stood |
|---|---|---|---|---|
| Felix is the pilot of implementation, not the governance layer (E01) | Founder, fa389b5e 08-10T21:19–21:31Z | The agent defended govern-only once, then conceded | — | 08-10 to now |
| Phase-1 scope, then a product for other people's projects (E01, E18) | Founder both times | 1 | Founder, 46af4fa6 09-23T01:09Z (#290) | About six weeks |
| Earned autonomy, #5 (E02) | Founder text; agent added lag and a fixed point | Three founder texts in 34 minutes | Superseded in practice by merge-on-green; never reconciled | Never built |
| V_n judges V_n+1, route 2 (E03, E20) | Founder's principle; agent proposed route 2 | First build vacuous, found by review; a hole found 09-17 by a refuter | Review, evidence | Pin shipped 09-18; the wall is still open |
| Keyword router (E07) | Agent's design, after the founder dropped the model on the agent's latency question | Four table patches, a rejected registry, the redesign | Founder, review, evidence | "Expected to die"; removal not before February |
| Repository visibility (E06) | Found public; founder said make it public | Public, private, "public stays", private, all within about 90 minutes | Evidence, founder | Private since 08-14; a public snapshot since 09-13 |
| Narrowed kernel replaced by v3.2 (E10, E11) | Agent's recommendation 09-02T23:16Z; founder's v3.2 09-03T06:45Z | Four agent kernels in about seven hours | Founder, four times | Bound 09-03; still governs |
| Bash versus a typed core (E04) | Outside grader; agent's position | Delegated to the agent ("I mean it"), then a panel | The agent's own panel, 09-19 | Stands |
| ECC: do not mount (E12) | Agent, 09-02 | Founder installed ECC anyway, 09-03 | Founder | Hooks off in step 1 on 09-22; step 2 open |
| Felix merges its own PRs (E15) | Founder, 08-11 and 08-12 | Restated eight or more times | — | Engine text fixed 09-14 (#241) |
| Roadmap v1 with an outreach track (E18) | Agent, from a relayed brief and its own thesis | Merged, then withdrawn | Founder | 3 minutes 49 seconds |

The founder originates nearly every decision about what Felix is. The agent
originates most decisions about how, and some of those (the grant hash in #203,
overnight state per project in #222, the revert rule, the amendments that
supersede v3.2) created work for the founder later. That is a class this pilot
did not reconstruct (§9).

**What makes a decision stand:** being written where every session reads it,
plus a mechanism or test that enforces it. Examples: v3.2 with its amendments;
#241's merge text, pinned by 11 assertions; #263's judge pin.

**What makes one decay:** prose only. Examples: "enforced by nothing" (E02 §0d);
a direction at line 4404 of a 5,059-line handoff (E15); a claim in memory only
(E12); a parked review with no trigger (E07).

A mechanism is not sufficient on its own. The per-project overnight state
(#222, E14) and the commission grant (E13) were mechanisms, and each became the
burden itself.

## 6. The interaction rules

These are the thirteen rules the records support. Each is worded for whoever
owns the "what" and cites at least two episodes. For each, the
**Now** line says where the rule lives today:

- whether the assistant's auto-memory for this founder holds it (feedback
  files);
- whether Felix's own `lessons.md` holds it;
- whether anything in the engine enforces it.

1. **Decide the how; bring the owner only what changes what the product is.**
   Tooling, thresholds, data models, hash contents, sequencing and model choice
   are the agent's to decide, with the reason written down. Bring the owner
   only these, as one question with a recommended answer:
   - changes to what the product is or who it is for;
   - money;
   - visibility;
   - consent and authority grants;
   - acts a revert cannot undo.

   *Evidence:* E01, E02, E03, E07, E14.
   *Now:* four auto-memory files and `lessons.md:400`. The engine enforces it
   only at the merge boundary (`felix:1455-1465`, `lib/receipt.sh:189-195`).
   Questions asked in chat are ungoverned.
2. **Never put your own work on the owner's list.** Merges, pushes, deploys,
   tidying, due routines and commands to type are the agent's; do them and
   report. When only the owner can act, name that one act.
   *Evidence:* E01, E02, E05, E13, E14, E15.
   *Now:* merges and deploys in auto-memory. The general rule sits in an
   archived handoff section. Nothing reads a closing report for work handed back.
3. **Treat a restated direction as a missing mechanism.** The first time the
   owner states a direction, write it where every session reads it and remove
   every sentence that contradicts it. The second time, build the mechanism.
   *Evidence:* E02, E05, E12, E14, E15.
   *Now:* one instance (`lib/overnight.sh`). Working against the rule,
   `hooks/session-start:498-499` calls HANDOFF.md "standing direction".
4. **Read state before stating it, and say who set a limit.** Say whether a
   limit is the platform's, the owner's or our own code's. Never quote
   configuration as the owner's instruction. Say what was searched before
   saying something is absent.
   *Evidence:* E01, E04, E05, E07, E10, E13, E17, E19.
   *Now:* two auto-memory files and three `lessons.md` entries. The Stop hook
   requires the gate before "done" (`hooks/stop:462-466`); prose claims to the
   owner are unchecked.
5. **Build the class, and make the audience a test.** Named tools and moments
   are examples of a class. Who the product is for is a test every change must
   pass, on more than one project.
   *Evidence:* E01, E07, E09, E10, E11.
   *Now:* auto-memory, the invariant-1 ecosystem check and
   `projects/felix/CLAUDE.md:17`.
6. **Never narrow what was chosen silently.** If a narrower version seems
   right, say what it loses and get a yes before committing it. Never label it
   "as chosen".
   *Evidence:* E04, E10, E11, E16.
   *Now:* nothing.
7. **The owner's record is the brief.** Re-read the owner's binding documents
   before building on them. The owner's approval of a default is not a check
   that the default conforms to them.
   *Evidence:* E03, E11, E16, E18, E20.
   *Now:* one auto-memory file. `lib/qualify.sh:36` still calls blocking "a
   founder's decision".
8. **Keep decided work visible until it is built or deferred on the record.**
   Every "revisit after N" needs a trigger that fires.
   *Evidence:* E02, E03, E07, E08, E09, E20.
   *Now:* maintenance rows come due by cadence. Nothing tracks a
   decided-but-unbuilt item.
9. **Show new what-level documents before merging them.** Roadmaps, changes to
   the owner's role, and amendments that override the owner's own text wait for
   a yes. A document that only records what the owner said can merge on green.
   *Evidence:* E18 (#293 merged 03:10:04Z, rejected 03:13:53Z), E11, E17, E04.
   *Now:* `felix-merges-its-own-prs` lists what stays with the founder, but not
   what-level documents. `felix merge` stops only on escape channels, and a
   docs path never escapes. This rule conflicts with a standing direction, so
   it is the founder's call (§10).
10. **For an act only the owner can do: ask once, ask for something the
    platform will count, then verify.** Ask once for all concurrent sessions,
    and afterwards check that the capability actually came back.
    *Evidence:* E03, E06, E08, E12, E13, E15.
    *Now:* partly in `felix merge`. The fix to the stale-commission wording is
    unmerged.
11. **Test against the owner's use, and correct every record.** Name the
    success test before building and report against it. When a claim turns out
    wrong, correct every place it reached, including what the owner took to
    outside advisers.
    *Evidence:* E03, E09, E10, E17, E18, E19.
    *Now:* the gate and the suite. Nothing carries a correction to every record.
12. **A declared measure must be computable on the day it is declared.**
    Instrument what the agent controls first: its own questions and hand-backs.
    *Evidence:* E02, E05, E07, E13.
    *Now:* defective. `felix:1432-1441` writes `escalated` rows with an empty
    session, and questions asked in chat are not recorded.
13. **Check outside reviews claim by claim, and hand back a list of
    retractions.**
    *Evidence:* E10, E16, E17, E18.
    *Now:* nothing.

**What went well, and should be kept.** Measuring before answering (E07, E10,
E14). Blind and adversarial checks of the agent's own work: a 44-agent review
caught the vacuous route-2 judge before any push (E03), and a critic caught an
exit-status bug in #263 (E20). Open self-correction ("I was wrong, three
times", E10). Checking the founder's own claims about state before acting on
them (E01). Leaving the owner's safeguards and consent alone (E03, E06). Using
delegation well once given it (E04). In E19, the Stop hook and `felix next`
caught the agent with no founder effort. Well-posed escalations were answered
within minutes (E05), which shows they were well posed, not that the question
was the agent's to decide.

## 7. What the new thing has to be

**What ships today.** A stranger who installs Felix gets the instances that are
in the engine: `felix merge` stopping only on escape channels, the receipt
naming the founder only where a channel escapes, `felix classify` no longer
saying "a human merges", the overnight standing direction, and the Stop hook's
refusal to call work done before the gate passes. They do not get `lessons.md`
(per-project memory), the owner/agent split (only in `projects/felix/CLAUDE.md`,
not written by `felix new`), or anything that governs how the agent treats its
owner in general.

**Why not a table of rules mounted like `lessons.md`.** `lessons.md` entries
reach a session by token overlap, at most four per prompt (`lib/lessons.sh:19`).
That is advice, and the records show advice failing:

- E19: the lesson "Establish who set a limit" (`lessons.md:176`) was mounted at
  21:32Z and again at 22:02Z, and broken at 23:15Z.
- E15: the merge direction was in memory and handoff prose for 33 days while
  the engine said the opposite.

The auto-memory rule `use-what-you-set-up` already says that a lesson which is
advice about a behaviour is not working.

**The shape.** An interaction layer: moments at which a check fires, each with a
mechanism and a number read from the owner's turns.

| Moment | Mechanism | Rules | Measured by |
|---|---|---|---|
| The agent asks the owner something | An `asked` row: question, options, recommended answer, what-level or how-level, answer, owner latency. A how-level question is flagged at the moment it is asked. | 1, 12 | How-level questions per session; answered-agent-question turns |
| The agent ends a turn or session | The Stop hook reads the closing report for work handed back. It passes only owner-only acts, and those go to one queue shared across sessions. | 2, 10 | Handed-back acts per session; "other" turns |
| The agent claims done or verified | The success test is named before building and run the owner's way. The gate requirement already exists. | 11 | Caught-unverified-claim turns; time to the founder's first failure |
| A what-level document is about to merge | An escape channel for roadmap, charter and amendment paths (§10) | 9 | Withdrawals after merge |
| The owner states a direction that is already recorded | Detect the restatement, sweep for contrary text, and open the mechanism as work | 3 | Restatements before a mechanism; days from direction to mechanism |
| The owner picks an option | Record the choice. A delivery claiming "as chosen" is compared with the choice, and any narrowing needs a yes. | 6 | Narrowings found later |
| A decision is taken | A decisions table with status (kept, folded, retired) and a revisit trigger | 7, 8 | Decided-but-unbuilt age |
| Any escalation | The session id on `escalated` rows (`felix:1441`), so the declared objective can finally be computed | 12 | Owner interruptions per session |

**The corpus, kept going.** The pilot's harvest becomes a standing record:

- founder prompts stored whole, where `says.log` now cuts them at about 520
  characters;
- question-tool answers and queued attachments indexed as turns;
- a turn table labelled once per turn by two blind readers, with agreement
  reported;
- a one-word owner rating after each what-level delivery;
- a fix that names the delivery it corrects (today 5 of the 134 fix commits
  on main do).

With these in place, each episode becomes a regression case, and every session
the founder works adds to it.

**Metrics that measure the pipeline, not agreement.** The synthesis proposed
two metrics the critic showed score agreement, and both are dropped:

- **Recommendation acceptance.** A well-posed escalation is also accepted.
- **Reversals by source.** It mixes the founder correcting the agent's errors,
  overriding advice the records call sound (E12), and changing their own
  framing (E01, E06). Driving it down rewards agreement.

The ones kept, with this pilot as the first baseline:

| Metric | Baseline |
|---|---|
| Leakage rate | 31% of non-operational owner turns; 31% of owner characters |
| Leakage by kind | The table in §3 |
| Restatements before a mechanism | At least eight for the merge direction (E15) |
| Days from direction to mechanism | 33 for the merge text (E15); the audience test reached the charter after about six weeks as prose, so it has no mechanism date yet (E01) |
| Share of overlooked items the owner found | About a third |
| Owner-rated delivery against intent | None yet: the founder has rated nothing |

## 8. Schema and capture changes

The pilot's record format lost information in nine places, from the unit of
count to who found what. The changes, each with the problem that motivates it,
are in `docs/episodes/method/codebook.md`, where the next batch reads them.

## 9. The next batch

The critic found big episodes that this pilot missed. They should be
reconstructed before any rule is built on the pilot alone:

- **The monitor, or visibility layer.** It was one of the four layers the
  founder named on day one (91c15299 04:02Z), with nine founder decisions
  in the index. It was dropped at selection on the wrong grounds.
- **The issue-to-PR and unattended loop.** It is the precursor to dispatch,
  and has been kept off since 08-29.
- **What Felix costs a session.** The founder asked on 08-13 whether Felix
  slows sessions down, and it has never been measured.
- **The lessons, mistakes and promote ladder.** The new thing depends on it,
  and it was never reconstructed.
- **Decisions the agent originated that later created founder work:** the grant
  hash (#203), per-project overnight state (#222), the revert rule, and the
  amendments that supersede v3.2.

## 10. What was the founder's to decide: DECIDED 2026-09-23

Two things changed a standing direction or asked for the founder's time; the
rest of this report is Felix's to build under the roadmap.

1. **Direction-level documents wait for a yes before merging.** This covers
   roadmaps, the charter's account of what Felix is, and amendments over the
   founder's own text. The evidence is E18: a roadmap merged and was withdrawn
   3 minutes 49 seconds later.
2. **The founder rates each direction-level delivery**: yes, partial or no.

The founder bounded both: "don't go like i need a yes for every action item or
engineering task". Everything else merges on green, and asking for a yes on it
is the needless stop the pilot measured most. The decision is written into the
owner/agent split in `projects/felix/CLAUDE.md`.
