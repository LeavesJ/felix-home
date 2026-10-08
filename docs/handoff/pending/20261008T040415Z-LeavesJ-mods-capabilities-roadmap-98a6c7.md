### 2026-10-07: a mods round for capability item 1, on 2.1.293, before any function hook is planned on

This extends item 1 of the capability lane in the report-v5 build queue
(handoff 0cw, "Host measurement"). It adds measurement and builds nothing. It
is handoff material, not roadmap text: no direction changes, and the roadmap
and the queue keep their words. Anything below that would change direction
waits for the founder's yes.

**Why.** Claude Code 2.1.293 documents mods: plugins whose hooks are typed
functions that run inside the session (`turn.step`, `agent.spawn`,
`tool.call`, `session.measure` and many more events), where a hook
used to be a shell command that reads stdin. A built-in plugin-authoring
plugin first shows in the init lines of 2.1.286 and not in 2.1.284 or 2.1.260
(host-measurements `results.md`). Item 1's measurements covered command
hooks: every item on 2.1.260 and 2.1.284, and a decisive subset on 2.1.286.
The queue rests on several things a hook "cannot do". The 2.1.293
declarations say otherwise for function hooks. A declaration is a claim about
a build and not a measurement of it, and the declarations' own header says
the surface may change between releases without notice. So this round
measures first, as item 1 did.

**Premises that may move.** Every right-hand cell is declared, not measured.

| Premise the queue holds | Where | What the 2.1.293 declarations say | Q |
|---|---|---|---|
| No hook can set the main session's model or effort | review §3 | `turn.step` lets a hook send another `model` or `effort` on each request, for the main thread and for subagents | 2, 3 |
| Writing a floor model into an Agent call can lower the model, so the floor stays advisory | 0cw lane 8; wave 1 | `agent.spawn` gives the hook the parent's model (pinned) and returns the resolved `model` and `agentId` | 5 |
| `--max-budget-usd` is soft: 39 of 39 capped runs exited 0 over the cap | 0cw wave 1 | a `turn.step` answer without `next` sends no request, and `session.measure` pushes cost | 6 |
| Under `--restricted` only plugin hooks fire, and `--bare` fires none | results M2 | a mod is a plugin; whether its function hooks load under either flag is not declared | 1 |
| 91% of subagent traffic is Workflow agents | review §4.2 | `agent.spawn` can only refuse a Workflow agent; whether `turn.step` fires for its requests is not declared | 4 |
| Felix's hooks fail open | 0cw, the declined input-rewriting floor | a failing hook is skipped unless its `.catch` answers in its place | 7 |

**The questions.** Each gets MEASURED-YES, MEASURED-NO or NOT-MEASURABLE, and
the row says what would make a NOT-MEASURABLE measurable.

1. **Does a mod load?** A probe mod through `--plugin-dir` under `claude -p`,
   on 2.1.286 and 2.1.293: plain, `--restricted`, `--bare`, and
   `--setting-sources ""`. Also `claude plugin validate` and `claude plugin
   test` on the probe. *Decides:* whether a mod can sit on a lease's enforcing
   path at all.
2. **`turn.step` on the main thread.** Rewrite `model` to another full id, and
   rewrite `effort`. Read the request the stand-in received (it already logs
   `model` and `effort`), then what `resolvedModel` and `modelUsage` report.
   *Decides:* the first premise.
3. **`turn.step` in a subagent.** Is `agentId` present; does a rewrite reach
   the subagent's requests and not the parent's; what a `fork`, which inherits
   the parent's model, does.
4. **A Workflow agent.** This is the "Workflow-spawned agents" measurement
   already queued under item 1 ("Before step 8, measure"), so one scenario
   answers both. Does `agent.spawn` fire (it can only refuse), does
   `turn.step` fire with an `agentId`, does a rewrite take. If the Workflow
   tool is not offered under `-p`, the row says NOT-MEASURABLE and that it
   needs an attended Desktop run. *Decides:* whether mods matter for routing
   at all, since this is 91% of the traffic.
5. **`agent.spawn`.** The Agent call that names no model (the case measured
   to lower it). The hook raises, leaves and lowers. Compare three readings:
   the hook's returned `model`, the stand-in's `model` and
   `PostToolUse(Agent).resolvedModel`.
6. **A request-boundary stop.** Script the stand-in's usage, read cost from
   `session.measure`, answer `turn.step` without `next` past a threshold. Run
   the 39-of-39 shape (subagents lagging the main turn, `delay_ms`,
   `early_start`) and count the requests that still reach the stand-in after
   the stop. A stream already started is not stopped; count those apart.
7. **Failure.** A hook that throws, one that outlasts its budget, and one
   whose `.catch` denies. Do requests still go out. *Decides:* whether a mod
   fails open, as Felix's hooks do, or closed.
8. **Desktop, attended and optional.** A probe mod in the Desktop Code tab on
   2.1.293: does it load, and what the one hot-reload question says. About
   ten minutes of the founder's, and the restart-moments probe visit can carry
   it. The probe draws nothing on screen.

Not measurable on the stand-in, and said so rather than guessed:

- **The cache cost of switching a model.** The stand-in has no cache. The
  review's number (a parent switch writes a median 321,582 cache tokens
  against about 1,100, n=12) stands. A mod that switches the main model is
  not run on real tokens before the replay decides.
- **Rate-limit windows.** `session.measure` leaves them empty off a
  subscription. A passive logger in the founder's own session would read them
  at no extra spend, if he chooses to enable one.

**Method.**

- **Rig.** Copy `settle2/rig` into `audits/2026-10-07-mods-round/` in the
  memory root, add `desktop-2.1.293` to the binary table (found under
  `~/Library/Application Support/Claude/claude-code/2.1.293/`), and record
  `--version` and sha256 at run time. The app re-lays its directories: the
  2.1.284 path moved mid-measurement last time. Models are full ids, read from
  the host.
- **Isolation unchanged.** `env -i`, a scratch HOME, the stand-in at
  `ANTHROPIC_BASE_URL`, a dummy key, and `DISABLE_TELEMETRY=1` with
  `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`. No credential is read and no
  token is spent.
- **Probe mods.** Deterministic, no model, no network, no UI calls. They live
  in scratch and load through `--plugin-dir`. They are not installed, and
  nothing is written under `~/.claude/plugins/cache/`.
- **Predictions first.** Before any run, a blind author writes the expected
  outcome of each question from a frozen copy of the declarations file kept
  with its sha256 (the plugin-authoring skill writes its copy under
  `/private/tmp` as it loads, and a restart names a new folder). Runs are judged against those predictions, and a declared-but-wrong
  behaviour is a finding. Then one adversarial challenge round, as rounds 1
  and 2 had.
- **Versions and load.** Each verdict is stated for 2.1.286 and 2.1.293.
  Timing verdicts, Q6 above all, use child CPU and not wall time, and carry
  the load average, which has run at 100 to 370 on this Mac.
- **Record.** Rows in `results.tsv` marked `[mods-round 2026-10-07]`, a
  section in `results.md`, and a `disposition.md` after the challenge round.
- **Stage models.** Predictions and the challenge round on Opus 5.5. Rig and
  probe plumbing, the runs, and the fact-check of the results on Sonnet 5.5 at
  high. A stage that goes red twice moves to Opus.

**Not in this round.**

- No engine change and no felix-home PR. Nothing touches `verify.sh`,
  `receipt.sh`, merge or the gate.
- No real tokens and no credential.
- No routing, floor or stop is built. The roadmap and the queue are
  unchanged.
- Nothing measured here becomes an input to a receipt or a merge blocker
  (trust invariance), and no probe puts a model on an enforcing path
  (invariant 2).

**Size and when.** About 0.5 to 1 lane session and no tokens. Spec and
measurement work is allowed now: it is not an engine branch, so the "more than
10 engine PRs" rule does not stop it. It is not a suite or a gate, so it asks
the carrier for no slot. It runs before item 4 (the dry-run lease) and item 6
(the outcome record), because the answers to 1, 3 and 6 change what those two
choose.

**What it may put in front of the founder.** None of these is asked now.

- **If Q6 holds:** the attended tick could stop before the next request goes
  out past the cap, where today it is checked afterwards. The cost is that the
  lease would load one plugin, and the 2026-10-01 amendment says no plugin.
  His call, on the numbers.
- **If Q5 shows a typed spawn never lowers a model:** the declined
  input-rewriting floor can be reconsidered with evidence. It would still be
  an architecture change, an enforcing output where Felix's hooks fail open,
  so it stays unbuilt until he decides.
- **If Q3 and Q4 show `turn.step` reaches Workflow agents:** the review's 12.8%
  ceiling for moving Opus subagent work to Sonnet becomes reachable at the
  host and not only by editing scripts. The replay's predeclared rule still
  decides whether routing is built at all.
- **Anything a mod draws on screen** is the stealth question again. The model
  reminder stays chat-only.
