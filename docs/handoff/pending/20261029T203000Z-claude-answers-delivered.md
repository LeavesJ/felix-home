### 2026-10-29: the knowledge graph's answer is handed to every prompt, and the ledger counts whether it was used (0.49.311)

**What changed, in one line.** The graph is no longer named to a session; its
answer is handed over. On each prompt a person types, the user-prompt hook runs
`graphify query` on the prompt and puts the files and symbols it returns into
the model's context, each file once a session. Every session end refreshes the
graph when the holding checkout has moved past it. The ledger counts each
delivery as an `answer` row, a surface of its own, and `felix ledger` says how
often the session then opened, edited or ran a file the answer named. Spec:
`docs/2026-10-29-answers-delivered-spec.md`.

**Why this and not the edit-time dependents list that was proposed.** Measured
before building: of the files that depend on each file under `lib/` and `hooks/`,
the graph links 74 of 455 (16%). graphify's bash extractor resolves `source`
only from `felix` and `bin/`, makes no edge for a call inside `$(...)`, and
`affected` on a file seeds through `contains` while bash files `defines`, so
`graphify affected lib/graph.sh` answers "No affected nodes". A dependents list
84% short reads as complete. What the graph answers well is where a thing is,
and that is what is delivered.

**The founder's direction it carries (2026-10-29).** "Read the graphs at the
beginning instead of reading the files one by one", files being edited still
read whole; the graph updated after every session; and, generally, that a
capability plane which cannot get a well-known tool used cannot suggest or
mount sophisticated ones. Hence `lib/answer.sh` is written for any tool's
answer, not graphify's: `state/answer/<session>.tsv` holds `given`, `answer`
and `touch` rows, the ledger kind is `answer`, and `felix_answer_use` measures
follow-through for whichever tool wrote them.

**The baseline, before any answer was delivered.** Over 601 Felix transcripts
touched in the 14 days before this change, 1,027 person prompts of five words
or more would have had an answer; on 227 of them (22.1%) the session went on to
open, edit or run a file the answer would have named, and 288 of 7,528 named
files (3.8%) were opened. That is what a delivered answer has to beat, and the
second number says the answer is broad: about seven files a prompt, most of
them never opened. Separately, the ledger's "queried 3 times" undercounted: it
sees Skill calls only, and graphify run through Bash was about 60 real queries,
almost all in the four sessions (09-03, 09-04, 09-10, 09-17) whose subject was
graphify itself.

**Read next.**
- After a week of sessions on 0.49.311, `felix ledger`'s answers line against
  the 22.1% / 3.8% baseline. If follow-through stays at baseline, the answer is
  not changing behaviour and the next lever is its precision (fewer, better
  files), not its delivery.
- The graph's bash recall is graphify's extractor, not Felix. A fix upstream
  (resolve `. "${SCRIPT_DIR}/../lib/x.sh"`, edges inside `$(...)`) would make an
  edit-time dependents answer worth delivering; until then it is not.
- The ledger does not attribute a Bash-run CLI to its capability, so any tool
  used from the shell reads as unused. Not fixed here.
