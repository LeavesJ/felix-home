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
own rules over 2026-10-15 to 2026-10-28, counting only what the live measure
can count:
- graphify's CLI query (depth 2, budget 600), each node once a session;
- the turn up to the next person prompt as the window, a prompt queued while
  the model worked included;
- subagents' tool calls included, failed calls excluded (they never reach the
  post-tool hook);
- the spec's L4 rule, and Bash values cut as the hook cuts them;
- only the 15 sessions the hooks ran in. 344 automated SDK review sessions in
  the same folders load no plugin, so the live line can never see them.

Result: 236 answers from 259 asks (22 repeats). On 25 of them (11%) the
session went on to open, edit or run a file the answer would have named before
its next prompt: 33 of 1,132 named files (3%), and only 6 of those opened or
edited rather than run. The first answer of a session, the map the founder
asked for, was acted on in 1 of 15 sessions. 234 of the 236 answers were cut to
graphify's budget. Fifteen sessions is a small, clustered sample, so read 11%
as roughly one answer in ten, not as a precise rate. That is what a delivered
answer has to beat.

Two earlier figures are withdrawn:
- 22.1% of prompts and 3.8% of files, from graphify's in-process query, which
  walks depth 3 where the CLI the hook runs walks depth 2;
- 27% and 4%, which the review found counted the 344 SDK sessions and missed
  queued prompts.

The replay answers two weeks of prompts from today's graph, a little newer than
the one those sessions had. The script and its output are in the side-session
notes folder (`answers-baseline-replay.py`). Separately, the ledger's "queried
3 times" undercounted: it sees Skill calls only, and graphify run through Bash
was about 60 real queries, almost all in the four sessions (09-03, 09-04,
09-10, 09-17) whose subject was graphify itself.

**Read next.**
- After a week of sessions on 0.49.311, `felix ledger`'s answers line against
  11% of answers, 3% of files and 6 files opened or edited. Opened or edited
  is the column to watch: "run" is mostly the felix CLI, which sessions run
  anyway. If follow-through stays at baseline, the answer is not changing
  behaviour, and the next lever is its precision (fewer, better files; almost
  every answer is cut to the budget), not its delivery.
- A prompt arriving while the model works ends the turn too, and the post-tool
  hook runs asynchronously. So a call made just before such a prompt can land
  just after its row and be credited to no answer. The spec's L4 names this;
  it biases the live share down, not up.
- Asks that time out. The bound is 4 s, and graphify took 3.3-4.8 s wall at a
  load average of 130-180. `felix ledger` says how many asks timed out; a large
  share means the bound or the budget is the lever.
- The graph's bash recall is graphify's extractor, not Felix. A fix upstream
  (resolve `. "${SCRIPT_DIR}/../lib/x.sh"`, edges inside `$(...)`) would make an
  edit-time dependents answer worth delivering; until then it is not.
- The ledger does not attribute a Bash-run CLI to its capability, so any tool
  used from the shell reads as unused. Not fixed here.
