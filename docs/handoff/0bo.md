## 0bo. 2026-09-21 — four outside reviews checked against the transcripts, and where Felix stands

Read `docs/2026-09-21-where-felix-stands.md`; this section only points at it.
The queue order of §0bn stands. What changed:

- **Long context is not the problem; handoff is.** No measured quality loss at
  long context. Every direct-strength recorded failure is a handoff failure.
  Resuming a large session after an idle hour costs about 12% of coordinator
  input. So: start fresh instead of resuming a large idle session, and restart
  after any engine deploy.
- **Floor and wall.** The durable logic runs on the agent's side. The wall, a
  required server-side check, exists on 1 of 5 governed repositories and not
  on felix-home.
- **Before queue item 1:** a minimal lifecycle recorder, because step 1
  removes ECC's resume markers and cost file. Before item 2: the handoff
  overwrite guard, the session-start wording and resume in the matcher, plus
  LeavesJ/Elenchus#20.
- **With item 4:** engine identity goes on the receipt, never into the epoch.
- **New:** split or index tests/run, felix and this file. Reading them is a
  large share of the growth in Bash calls.
- **README rewritten** from verified claims only. Publishing it to
  LeavesJ/Felix is the founder's call.

