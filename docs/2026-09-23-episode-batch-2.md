# The founder-episode harvest, batch 2: five missed episodes and two controls

This extends the pilot (`docs/2026-09-23-episode-pilot.md`), which reconstructed
twenty episodes from the history of building Felix. Batch 2 adds:

- the five big episodes the pilot's critic found missing: the monitor (E21), the
  issue-to-PR and unattended loop (E22), what Felix costs a session (E23), the
  lessons and promote ladder (E24), and decisions the agent made that later
  created work for the founder (E25);
- two control sessions (E26, E27), as a check on the pilot's habit of choosing
  contested episodes.

It also tries the pilot's method fixes:
- a second reader who labels each turn without seeing the first reader's labels;
- a `restored-design` label for when the founder repairs a design the agent had
  narrowed;
- an origin for every turn;
- a decisions list per episode;
- lags as numbers.

**What it found.**

- **A leakage rate depends mostly on which turns are chosen.** On the 81 turns
  both batches labelled, the pilot's own labels already give 42% leakage,
  against the pilot's overall 31%. The rule used to settle disagreements moves
  batch 2's figure between 36% and 50%. So any rate needs its sample and its
  counting rule stated beside it. The pilot's 31% and batch 2's 50% measure
  different things.
- **Two readers agreed on 70% of turn labels.** Their most common split was
  whether a founder "go" was an approval or a push past a stop that should not
  have happened. That is exactly the line the new direction-level rule draws.
- **The agent made most of the decisions, and several of its choices became the
  founder's recurring chores.** Across the seven records the agent originated 60
  decisions. The commission hash, per-project overnight state, and treating the
  commission run as the founder's act each became a repeating job for him. No
  record shows the cost to the owner being stated when the decision was made,
  and the record format had no field for it.
- **The pilot's tools mislabelled messages from other sessions.** The transcript
  reader printed task notifications and messages from other sessions as the
  founder's turns, and the prompt index counted them as his prompts. Both are
  fixed. Re-matched against an index that tags origin, none of the pilot's
  turns turned out to be another session's message, so the pilot's figures
  stand.

## 1. How batch 2 was run, and its limits

**The run.** Workflow `wf_a7320bd6-055` ran seven reconstructions, seven blind
labellings and seven checks, then one synthesis and one critic.
- **The checks.** One skeptic per episode checked 472 claims, refuted 84 (18%)
  and marked 26 unsupported. All seven records ended as "holds with
  corrections". The pilot's figure was 16% refuted.
- **The interruption.** A session restart stopped the run before its critic
  finished. The finished results were taken from the run's journal, and the
  critic was re-run on its own.

**The controls.**
- **How they were drawn.** Candidates were Felix sessions with five or more
  indexed prompts, none of whose turns appear in the pilot's turn table, with
  non-Felix work excluded by title. They were ordered by the SHA-256 of their
  session ids, and the first two were taken: 887e409d and 627a4816.
- **Why they are a different unit.** Each is one session, whereas an episode
  follows one subject. 887e409d was also launched from a chip in a session the
  pilot read (207f7bdf).

**Counting.**
- **Which turns count.** Founder turns are the ones the founder typed, relayed,
  or answered through the question tool. Chip prompts, other sessions' messages
  and platform text are left out.
- **Overlap.** Ten turns sit in two episodes each, so the 117 episode-turns
  collapse to 107 distinct ones.

**Limits.**
- **The five big episodes are selected, not sampled.** E25 was chosen for owner
  burden, and it supplies 26 of the 61 leakage labels.
- **The second reader did not see every turn.** 19 of the 107 distinct turns
  had only one reader (E25 10, E24 5, E21 2, E22 2), and 9 of those are
  labelled leakage.
- **The adjudicator leaned one way.** Where the readers split on whether a turn
  was leakage at all, it chose leakage 19 times in 21. Readers were again primed
  with the founder's memory index.
- **E23's labels are weak.** The two readers agreed on 1 of its 8 turns.
- **Most of batch 2 re-reads the pilot.** 81 of its turns are already in the
  pilot's turn table.

## 2. The seven episodes

"Turns" is the episode's own distinct non-operational founder turns. Leakage uses
its adjudicated labels. Match is the reader's inference, since the founder has
rated nothing.

| Id | Episode | Turns | Leakage | Restored design | Match | The story |
|---|---|---|---|---|---|---|
| E21 | The monitor (visibility layer) | 25 | 10 | 4 | partial | Built in a day to the founder's design (91c15299 08-10). The next plan dropped one of the four layers he had chosen, and he restored it. The charter says status belongs in the monitor, yet nothing directs anyone to `felix monitor`, and it was last rendered on 09-05. A promised archive popup was announced and never built. |
| E22 | Issue-to-PR and unattended loop | 25 | 15 | 0 | partial | Two verbs shipped in one night. The first real PR waited about 30 hours through three hand-backs. Stage two of "Both, staged" was never built and never deferred on the record. The switched-off loop skipped all 38 of its runs, and six defects surfaced through audits or follow-on chips. |
| E23 | What Felix costs a session | 5 | 3 | 1 | partial | The founder's slowdown question (4c96b238 08-13T08:19Z) exposed a per-hook cost measured on one path. The fix left a read that grows faster than its input, and real refusals paid for it (15 s and about 132 s). Session pace end to end was never measured. The readers agreed on 1 of 8 labels. |
| E24 | Lessons, mistakes and promote ladder | 18 | 6 | 2 | partial | The top rung turned caught mistakes into mechanisms three times (b1a4e1fa, #195, #207). But 132 of 181 lessons mount as a bare date, the matcher reads the hook envelope, and interaction lessons got in only when the founder named them. |
| E25 | Decisions the agent originated | 41 | 26 | 0 | partial | Chosen for owner burden. The agent originated 11 of the 13 decisions and asked about 3. A twelve-table hash under the commission receipt and grant, plus doctrine saying the run is his, made re-stamps his chore. |
| E26 | Control: deny rows scoped to the checkout | 2 | 1 | 0 | partial | A strong build that never landed. A stale commission blocker was repeated six times, and landing was deferred with no owner. The one leakage label was a split, resolved by citing the pilot's own label for a similar turn. |
| E27 | Control: the self-judgement guard | 1 | 0 | 0 | yes | Measured, built, broken by the agent's own reviewer, and reverted. It scores "yes" only against the agent-written chip's narrow ask. A pre-existing bug went only into a memory file and is still open. |

The Turns column sums to 117 over the episodes, which is 107 distinct turns.

## 3. What the rate means

- **By the adjudicated labels:** 54 of 107 distinct turns are leakage (50%).
  They hold 58% of the sized characters, or about 48% without one turn that is
  mostly pasted model output (fa389b5e 07:55:18Z).
- **If the adjudicator's 20 leaning calls are reversed:** 37 of 104 (36%).
  Three of those turns revert to operational.
- **On the 81 turns both batches labelled:** the pilot's labels give 33 of 78
  (42%), and batch 2's give 39 of 79 (49%). Choosing those turns moves the rate
  about 11 points from the pilot's 31%, and the change of labels about 7.
- **By kind (shares, with splits):** needless stops 17, restated decisions 10,
  and 7 each for restored designs, caught claims and answered agent questions,
  then 5 other and 1 mechanics correction. At least 6 of the 17 needless stops
  were split adjudications. The three kinds the pilot led with account for 34
  of 107 turns (32%).
- **The controls hold 3 non-operational founder turns between them.** That
  cannot test the pilot's rate either way, so they are reported as instances
  only.
  - In both sessions the founder's input during the session was a chip click
    and a line or two. In E27 there were also two model switches after a
    platform fallback, which is not Felix's doing.
  - E26's stranded pull request cost the founder later, in turns counted in
    E25.

A leakage rate is still the right metric, but only with a fixed sample (for
example, every session in a week), one counting rule, and both readers' counts
reported beside the adjudicated one.

## 4. How reliable the labels are

The readers compared 123 labels and agreed on 86 (70%). Per episode:

| E21 | E22 | E23 | E24 | E25 | E26 | E27 |
|---|---|---|---|---|---|---|
| 14 of 23 | 21 of 27 | 1 of 8 | 9 of 13 | 22 of 31 | 13 of 15 | 6 of 6 |

The controls agree most because most of their rows are chip, peer or command
rows.

| Where the readers split | Splits |
|---|---|
| A "go" or approval, versus a push past a stop that should not have happened | 5 |
| Judgment or approval, versus answering the agent's question | 4 |
| Question, idea or direction feedback, versus catching a claim | 4 |
| Operational, versus leakage (a context warning, "continue") | 4 |
| Idea or sharpening, versus restored design | 3 |
| Two different leakage kinds | 5 |
| Two non-leakage kinds, or operational versus not | 10 |

**Four codebook rules would remove most of these.**
1. A "go" after the agent named next work that was already approved, or was its
   own, is a needless stop.
2. A context warning past the recorded session limit is a restatement.
3. A yes to a question the agent's own binding document already answered is an
   answered agent question.
4. A chip launch is always operational.

**Checked against the pilot.** Whether a turn is leakage is steadier than which
kind it is. On the 81 shared turns, the class matched on 66 (81%). Nine turns
moved into leakage and three moved out. Of the nine, three moved through the
new restored-design kind, which is the undercount the pilot predicted.

**One label measures taste rather than the pipeline.** 85410a9f 18:25:12Z ("too
bland") is labelled restored-design, although the agent's plain README was an
honesty choice. It should be relabelled as direction feedback.

## 5. Decisions the agent originated

The seven records hold 60 decisions the agent originated, and the founder was
asked about 14 of them. E25, which was chosen for this, supplies 11. In 37 rows
a later cost to the founder is named. Seven of those are his by rule: escape
tables, a credential, and a chip click. Of the other 30, at least 8 name a
cost that is likely or built into the design rather than an act he performed.

**Shapes that recur:**

- **A safeguard keyed wider than what it protects.**
  - The commission receipt and grant hash twelve tables
    (`lib/commission.sh`, `lib/autonomy.sh:47-55`), so an unrelated table edit
    stales them.
  - The epoch counts probe members (#227), so every deploy stales every receipt,
    which is why #304 is held.
  - These produced merge freezes (#298: 2 h 03 min) and repeated re-stamps.
- **A founder act written into doctrine without asking.**
  - A passing remark became "the commission run is the founder's"
    (`docs/handoff/0bc.md`), but `cmd_commission` reads no grant.
  - Holding Elenchus PR #4 for a human merge cost about 30 hours.
- **Deferred with no owner or trigger.**
  - Stage two of the loop.
  - Overnight state per project (#222, used for one night).
  - "Land at landing" (#308).
  - A bug parked in a memory file.

**What the records do not show.**
- **Whether asking protects the founder.** He was asked about 6 of the 30, and
  not asked about 24. The split does not favour either side.
- **Whether costs went unstated.** The record format had no field for the cost
  to the owner as stated when a decision was made, so "never stated" is
  unmeasured, not a finding.
- **Who found the costs.** Half of the 30 (15) surfaced through the founder or
  an audit he asked for, and 10 only in this harvest.

## 6. What the five episodes add to the interaction layer

These amend the pilot's §7 table. Items marked *instance* rest on one case.

- **The monitor (E21).**
  - A metric needs a moment when someone reads it. The charter sends status to
    `felix monitor` (`cmd_monitor`, `lib/monitor.sh`), but nothing leads anyone
    there: `engine/commands/felix.md:32` says not to run it unasked, and it was
    last rendered on 09-05. Where status should live is the founder's call (§8).
  - When the owner picks a set, compare every later plan with it: here one of
    four chosen layers was dropped before anything was delivered.
  - *Instance:* an announced dispatch with no dispatch after it
    (fa389b5e 21:16:16Z). The Stop hook can check announced work against the
    turn's tool calls.
- **The loop (E22).**
  - The Stop hook's read of the closing report should flag "next is X" when X
    is approved work or the agent's own. Five bare "go" turns followed such
    reports.
  - *Instance:* a stage a design doc defers becomes a decided-but-unbuilt row
    with a trigger.
  - *Instance:* a switched-off path gets a maintenance row that re-checks it on
    a cadence (`templates/unattended.yml` skipped 38 runs).
  - Every owner item lives in the one owner queue. Lists in handoffs are not a
    queue.
- **Felix's own cost (E23).**
  - Interaction checks fire at turn boundaries (`hooks/user-prompt`,
    `hooks/stop`), never on the per-call path (`hooks/pre-tool`). Each carries
    a deadline or linearity assertion in `tests/run`.
  - Add a metric of Felix's own friction per session: hook time (not recorded
    today), Stop holds, false refusals, and the required gate run.
  - The records give two false-refusal figures that are not reconciled: 130 of
    175 logged refusals false (E23), and 91 of 146 lifted by #308 (E26).
- **The lessons ladder (E24).** These are engineering fixes, and Felix's to
  make:
  - mount the full headline (`lib/memory.sh:32-36`, `lib/lessons.sh:76-78`);
  - match on the prompt rather than the raw envelope (`hooks/user-prompt:48`);
  - give `mistakes.log` rows a session id (`lib/guard.sh:95`);
  - feed restated-direction turns to `felix next` rank 5;
  - correct `projects/felix/CLAUDE.md:160-163` and the `felix new` template
    (`felix:930`).

  The ladder's automatic intake sees only failed gate checks, so the owner-turn
  table is the intake the interaction layer needs.
- **Agent-originated decisions (E25).**
  - The decisions table gains the originator, whether the owner was asked, and
    the owner's recurring cost as stated at the time.
  - An act is owner-only only if code requires a person.
  - A mechanism only the owner can clear reports the owner acts it causes.
    Stale-receipt refusals in `lib/escape.sh:505-526` log no row today.
  - `felix merge` writes `escalated` rows even on `--dry-run`, which inflates
    the declared objective.

## 7. Changes to the pilot

**Kept.** Four of the five delivery patterns recur here, each shown by
instances in E21, E22, E24, E26 and E27:
- the words shipped but the behaviour did not;
- decided work slid down the queue;
- work was verified against its own spec, not the owner's use;
- the owner acted as the message bus between sessions.

The new thing is still mechanisms at moments rather than advice. That now rests
on E15; E24 shows the lesson mount was a weak carrier.

**Changed.**
- **The 31% baseline** must state its sample and its counting rule, and kinds
  are reported as shares with their splits.
- **The lessons claim** in the pilot's opening was the agent's, from a grep cut
  off at twelve lines. `lessons.md` holds some interaction entries; its
  automatic intake sees only gate failures, its mount is headline-only and
  matched against the envelope, and it never ships. The pilot's opening is now
  corrected.
- **The §7 metrics** gain Felix's own friction and burden that lands after the
  session.
- **The owner queue** gains the rule that an act is owner-only only if code
  requires a person.
- **The labels are no longer engineering-shaped only.** The restored-design kind
  partly fixes the pilot's §1 limit.

**Withdrawn.**
- **"What Felix costs a session has never been measured."** Per-hook latency
  was measured on 08-11 and 08-13. What was never measured is session pace end
  to end and the slow tail on large payloads.
- **E19 as a clean test of advice.** The claim that prose fails is kept on
  E15's evidence alone.

## 8. What is the founder's to decide

One question here is direction-level under #319, because the charter names the
place.

**Where should Felix's status reach you?** The charter says status belongs in
the monitor, but nothing leads you to the monitor, and it was last rendered on
09-05. The recommended change: status goes in the end-of-session notice, where
Felix already speaks, and the monitor stays as the deeper page. That keeps the
charter's "hear from Felix at its start and at its end" and changes one
sentence of it.

Everything else here is Felix's to build: the codebook rules, the capture and
origin fixes, the lessons-ladder fixes, the decisions table, and the next batch
on a fixed sample.

## Data and method

- **Records:** `docs/episodes/2026-09-23-batch2-records.jsonl`, each with final
  labels.
- **Second-reader labels, agreement and adjudications:**
  `docs/episodes/2026-09-23-batch2-labels.jsonl`.
- **Tools** (`docs/episodes/method/`): the prompt index now tags each row's
  origin, and the transcript reader marks notifications and other sessions'
  messages as not the founder.
- **The pilot re-checked against the origin-tagged index:** 228 of its 266
  non-operational turns match a founder-typed prompt, 36 are not indexed, and 2
  matched a task notification (likely a founder turn the index misses beside
  it). None was another session's message.
