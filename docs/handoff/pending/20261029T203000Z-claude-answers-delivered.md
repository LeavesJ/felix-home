### 2026-10-29: the knowledge graph's answer is handed to every prompt, and the ledger counts whether it was used (0.49.311)

**What changed, in one line.** The graph is no longer named to a session; its
answer is handed over. On each prompt a person types, the user-prompt hook runs
`graphify query` on the prompt and puts the files and symbols it returns, with
their lines, into the model's context: each node once a session, and saying so
when graphify cut the answer to its budget. Every session end, and every start,
refreshes the graph when the holding checkout has moved past it and no refresh
has already run at that HEAD. The ledger counts each delivery as an `answer`
row, a surface of its own, and `felix ledger` says how often the session then
opened, edited or ran a file the answer named before its next prompt. Spec:
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
answer, not graphify's: `state/answer/<session>.tsv` holds `asked`, `root`,
`given`, `node`, `answer`, `prompt` and `touch` rows, the ledger kind is
`answer`, and `felix_answer_use` measures follow-through for whichever tool
wrote them. A touch row names the answered file a tool call reached and never
the call's path or command: the home sits in synced Documents, and a command
can hold a credential.

**The baseline, before any answer was delivered.** Replayed with the engine's
own rules (graphify's CLI query: depth 2, budget 600; each node once a session;
the turn up to the next person prompt as the window; subagents' tool calls
included; the spec's L4 token rule) over the person prompts of 2026-10-15 to
2026-10-28 in Felix's own checkouts: 485 asks in 358 sessions, 473 answered
and 12 repeats. On 128 of the 473 (27%) the session went on to open, edit or
run a file the answer would have named before its next prompt; 149 of 3,456
named files (4%), 121 of them opened or edited and not only run. 470 of the 473
answers were cut to graphify's budget. That is what a delivered answer has to
beat. An earlier figure, 22.1% of prompts and 3.8% of files, is withdrawn: it
came from graphify's in-process query, which walks depth 3 where the CLI the
hook runs walks depth 2, and from looser rules than the engine's. The replay
answers two weeks of prompts from today's graph, a little newer than the one
those sessions had. Separately, the ledger's "queried 3 times" undercounted: it
sees Skill calls only, and graphify run through Bash was about 60 real
queries, almost all in the four sessions (09-03, 09-04, 09-10, 09-17) whose
subject was graphify itself.

**Read next.**
- After a week of sessions on 0.49.311, `felix ledger`'s answers line against
  27% of answers and 4% of files. If follow-through stays at baseline, the
  answer is not changing behaviour and the next lever is its precision (fewer,
  better files; almost every answer is cut to the budget), not its delivery.
- Asks that time out. The bound is 4 s, and graphify took 3.3-4.8 s wall at a
  load average of 130-180. `felix ledger` says how many asks timed out; a large
  share means the bound or the budget is the lever.
- The graph's bash recall is graphify's extractor, not Felix. A fix upstream
  (resolve `. "${SCRIPT_DIR}/../lib/x.sh"`, edges inside `$(...)`) would make an
  edit-time dependents answer worth delivering; until then it is not.
- The ledger does not attribute a Bash-run CLI to its capability, so any tool
  used from the shell reads as unused. Not fixed here.
