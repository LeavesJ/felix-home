# Episode codebook

The labels a reader assigns to each founder turn and each agent move, as used
by the pilot of 2026-09-23 (`docs/2026-09-23-episode-pilot.md`). The next
batch labels against this file.

## Founder turn kinds

| Kind | Meaning |
|---|---|
| idea | New direction |
| sharpening | Refines the founder's own idea |
| judgment | Decides between options or sets priority |
| direction-feedback | Says the work is going the wrong way at the level of what, not how |
| approval | Go, merge, yes |
| question | Asks for information the founder legitimately needs |
| operational | Continue, restart, context low; counted as neither intended nor leakage |
| leakage (any kind below) | The founder doing the agent's job |
| mechanics-correction | Corrected how something was built |
| repeat-settled | Restated a decision already recorded |
| answered-agent-question | Answered a design or mechanics question the agent should have decided |
| caught-unverified-claim | Caught a false or unchecked claim about state |
| unstuck-needless-stop | Pushed past a stop, hedge or escalation that should not have happened |
| translated-to-engineering | Turned the founder's idea into engineering terms |
| caught-overreach | Reined in work beyond or beside what was asked |
| other | Anything else, mostly typing commands the agent handed over |

## Agent moves

proposed, asked-outcome, asked-mechanics, decided,
executed, verified, reported, overreached, underreached, misread.

## Method files

Beside this file: the prompt indexer (`index.py`), the transcript reader
(`dump.py`), the workflow script (`workflow.js`) and the recount (`turns.py`). The pilot's own run
is `wf_cffda6be-01f`.

## Record format changes for the next batch

Found by the pilot; section 8 of the report points here.

| What | Problem found | Change |
|---|---|---|
| The unit | Per-episode counts summed shared turns: 622 rows for 321 turns | The turn table is primary; episodes reference turn ids (session plus message uuid) |
| Labels | Of the 97 turns any reader called leakage, 37 had one reader only, and on 26 of the other 60 the readers disagreed | Label each turn once, by two blind readers, against the codebook; report agreement |
| Architecture-level repair | Counted as intended (§1) | Add a kind: the owner restores or supplies a design the agent narrowed or could not carry |
| Effort | Turns weigh a "go" and a 12K design the same | Carry characters, and owner time where it can be measured |
| `matched_intent` | A reader's inference; the rubric's ceiling is partial | The owner's rating, or the owner's first turn after delivery, linked |
| `found_by`, `lag` | Free text, mixed time zones | Enums, `lag_hours` as a number, UTC only |
| `kind` | Set before the outcome was known (E20) | Set after |
| Decisions | Scattered across intent, reversals and notes | A decisions array: originator, rounds, alternative rejected, binding doc, reversed by, stood from and to |
| Relayed input | Authorship of relayed texts unknown (E02, E03) | A source field: typed, relayed from a model, relayed from a person, outside the corpus |
