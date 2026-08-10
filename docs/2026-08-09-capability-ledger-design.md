# Capability ledger — design

Written 2026-08-09, replacing an earlier sketch that was wrong. Every
measurement claim below was computed on this machine against real data, not
assumed.

Slice 3 of four. Answers one question: **which capabilities earn their place,
and what is Felix allowed to conclude from what it sees?**

## The mistake this replaces

The first version of this design retired capabilities by usage count: measure
how often each plugin is used, drop the ones that aren't, keep the ones that
are.

That is circular, and the loop is tight:

```
Felix loads A  →  Claude therefore uses A  →  Felix observes A was used
      ↑                                                    │
      └────────  Felix concludes A is useful  ←────────────┘
```

Usage is *caused by* loading. A capability that is always loaded will always
look useful, and one that is never loaded can never prove itself. Counting
harder does not fix this; no amount of observation resolves a confound.

## The asymmetry that rescues it

The confound runs in one direction only.

**"Loaded and used" is confounded.** It cannot distinguish a capability that was
needed from one that was merely present.

**"Loaded across many sessions and never once invoked" is not confounded.** The
capability was mounted, it was in scope, the work matched its profile, and it
was still ignored every time. There is no alternative explanation to rule out.
Absence of use, given presence, is real evidence.

This single asymmetry decides the whole architecture:

> **Retiring is driven by evidence. Mounting is driven by declared need.**

Felix never concludes "load more of X because X was used." Mounting comes from
`routes.tsv` and `profiles.tsv` — from what a kind of work *requires* — which is
a statement about the task, not a statistic about the past. Only removal is
data-driven, and only on the unconfounded signal.

That closes the loop permanently. There is no path by which loading something
causes Felix to load it more.

## Three classes of evidence, three permissions

| Class | What it is | Confounded? | What Felix may do |
|---|---|---|---|
| **Fact** | Context cost, what is installed, what is mounted, what a profile declares | No — measured, not inferred | Report, and act freely |
| **Unconfounded** | Zero invocations across N sessions where the capability was loaded and in-profile | No | Propose retirement |
| **Confounded** | Usage counts, correlation between a capability being present and a task going well | Yes | Record. Report as correlation. **Never act on alone** |

Anything in the third class needs a trial before it becomes a conclusion, and
trials are expensive — see below. Most of the value is in the first two classes,
which need no statistics at all.

## What is actually measurable

Verified by computing a real ledger row from this session's own transcript
(`~/.claude/projects/<slug>/<session-id>.jsonl`, 1.7MB, 148 assistant messages):

```
title:   MCP/plugin automatic tuning
models:  {'claude-opus-5': 148}
human mid-task interjections: 3

capabilities actually used
  superpowers:brainstorming                 97 msgs
  superpowers:dispatching-parallel-agents   43 msgs

tool calls, median latency
  Bash              35   0.62s
  Read               9   0.02s
  AskUserQuestion    9   125.12s
  Edit               8   0.24s
  Agent              4   338.48s
```

Every capability other than those two was loaded and contributed nothing.
`context7` and `playwright` were mounted for the entire session and produced
zero `mcp__*` tool calls.

| Signal | Source | Notes |
|---|---|---|
| Which capabilities were used | `assistant.attributionSkill` / `attributionPlugin` per message | Non-null only when actually active. This is the core signal |
| MCP server usage | `tool_use.name` matching `mcp__<server>__*` | The only way to see MCP contribution; attribution fields do not cover it |
| Tool call counts | `tool_use` blocks grouped by name | |
| Latency | `tool_use` → matching `tool_result` timestamps | **See the human-time problem below** |
| Human corrections | `type: "queue-operation"`, `operation: "enqueue"` | Full text of what you said mid-task. Real signal, needs judgment to interpret |
| Task label | `type: "custom-title"` | Model-generated free text, not a controlled taxonomy. A hint, not a key |
| Context cost | `claude plugin details <name>` | Always-on vs on-invoke, per component |
| Verification result | `memory/verification.log`, written by the completion gate | **Has no native source.** Exists only because Felix writes it |
| Which capabilities were loaded | `settings.json` `enabledPlugins` + `claude plugin list` | Changes rarely; read on config change, not per session |

### The human-time problem

`AskUserQuestion` shows a median latency of 125 seconds. That is not tool cost.
That is a person deciding.

`Agent` shows 338 seconds, which *is* machine time. The two are indistinguishable
in the raw timestamps, and a ledger that added them together would conclude that
consulting the founder is the most expensive operation in the system — and then
optimise it away.

So latency is recorded **segregated, never aggregated**: tools that block on a
human (`AskUserQuestion`, permission prompts, elicitation) go in their own column
and are excluded from any cost figure. Wall-clock session duration is recorded
but never treated as a cost signal for the same reason.

### What is not measurable

- **Task success.** No native field exists. The closest honest proxy is the
  completion gate's verification record plus whether the work reached a merged
  PR. Both are Felix's own instrumentation. Neither is "success."
- **MCP tool-schema token cost.** `claude plugin details` says explicitly:
  "tool schemas resolved at runtime; not counted." The cost of mounting an MCP
  server is invisible to the tool that reports costs. Counting it means counting
  tokens in the server's own `tools/list` response.
- **Per-session loaded-set, reliably.** Claude Code computes this internally
  (`tengu_plugin_enabled_for_session`) but only writes it to disk when telemetry
  upload *fails*. Do not depend on it. Derive the loaded set from configuration.

## Revision: record it as it happens, and let the map be the context

The section above describes reading session transcripts after the fact. That
was wrong twice, and both corrections came from outside this document.

**It breaks the constitution.** Felix's second invariant is bash and git only —
no jq, no python, no node in the engine. A transcript is 1.7MB of JSONL, and
general JSON parsing in pure bash is not practical at that size. The spec
assumed a reader it is not allowed to have.

**It reconstructs what could simply have been recorded.** Every fact the ledger
wants exists at a moment when a hook is already running. A `PostToolUse` hook
receives `tool_name` in its payload and can append one line. That yields
capabilities-used, per-tool counts, and MCP server usage directly, with no
transcript involved and no parser. The completion gate already proves the shape:
verification has no native record anywhere in Claude Code, so Felix writes it
down at the moment it happens.

So the pipeline inverts:

| | Old: reconstruct | New: record |
|---|---|---|
| what was used | parse `attributionSkill` out of 1.7MB JSONL | `PostToolUse` appends `tool_name` |
| what was loaded | infer | read config at `SessionStart` |
| verification | not available at all | already written by the completion gate |
| cost | parse `usage` blocks | `claude plugin details`, unchanged |

Transcript parsing remains available as a *reconciliation* path — something run
occasionally and out of band, never in a hook — but nothing depends on it.

**And the map, not the files, is what the next session reads.** Graphify is
already installed here, `graphify update` runs without an LLM, and `graphify
query` answers against the graph under a token budget. Felix's memory is
currently a pile of files that a session is handed whole: lessons, devlog,
handoff, and now routes and verification too. That pile only grows, and mounting
more of it every session is the exact failure the lessons matcher was built to
avoid, arriving by a different road.

Treating the graph as the context surface changes what Felix's records are *for*.
They stop being documents to be read and become material to be graphed:
`felix lessons --for X` and a budgeted graph query are the same operation, and
the second scales. Felix keeps writing plain TSV and markdown, because those are
what it can promise with bash and git; graphify turns them into the thing a
session actually consults.

This stays inside the constitution because graphify is a **declared capability**,
not an engine dependency — the same treatment `database` or `observability` gets.
Felix's engine requires nothing new, the graph-backed reading path is dormant
where graphify is absent, and `felix doctor` surfaces it the day a
`graphify-out/` appears. A project without it falls back to the files.

What this does not solve: graphify does entity and relationship extraction, not
arithmetic. "How many times was this invoked, and what did it cost" is a sum over
a structured log, and that log is Felix's own TSV. The map is for reading; the
ledger is for counting. Conflating them would give a beautiful graph that cannot
answer the one question the slice exists for.

## Records

`projects/<p>/memory/ledger.tsv`, one row per session per capability, committed:

```
# session	date	route	capability	kind	loaded	invocations	mcp_calls	tokens_alwayson
91c15299	2026-08-09	build	superpowers:brainstorming	skill	yes	97	0	70
91c15299	2026-08-09	build	context7	mcp	yes	0	0	0
91c15299	2026-08-09	build	playwright	mcp	yes	0	0	0
```

Written by a `SessionEnd` hook that parses the transcript it is handed. Nothing
is computed live; the transcript is complete by then and parsing it costs
nothing at that point.

`loaded` is derived from configuration at session start, not from the transcript
— that is what makes "loaded but unused" expressible at all. Without it, a
capability that contributed nothing is indistinguishable from one that was never
there, and the whole ledger collapses into a usage counter.

## What Felix proposes, and when

**Retirement.** A capability is proposed for retirement when, across the last
`FELIX_LEDGER_WINDOW` sessions (default 40) in which it was **loaded and its
capability was in the active profile**, it recorded zero invocations.

The profile condition matters. A billing plugin that goes unused during forty
sessions of frontend work has proved nothing — it was never in scope. Retiring
it would be punishing a tool for the work not arriving.

Retirement is **per project, at project scope**, and reversible. It is a proposal
in `felix ledger`, applied only by an explicit command, and the reconciliation
that applies it is bounded by the same rules that bound `felix stack apply`:
nothing high-risk, ever, at any flag.

**Never automatic mounting.** There is no rule anywhere in this design that
mounts a capability because usage suggested it. Mounting is what `routes.tsv`
and `profiles.tsv` are for.

**Everything else is a report.** "Playwright has been loaded in 40 sessions and
used in 3" is printed as a fact with its confound stated, not as a
recommendation.

## Trials, and why they are rare

For the genuinely marginal cases — does loading `impeccable` actually improve
frontend work? — observation cannot answer, because loading is not randomised.
Only an intervention can, and Felix is the thing that decides what loads, so it
can run one: withhold the capability for a random half of matching sessions and
compare.

**The honest arithmetic:** at roughly five sessions a day, of which perhaps two
match a given route, a trial arm accumulates one session per day. Detecting
anything short of a large effect on a noisy binary outcome needs dozens per arm.
**A trial takes months.**

So trials are:

- **Explicitly started**, never silent. `felix ledger --trial <capability>`.
- **Reported with their power**, so "no difference detected" is never mistaken
  for "no difference exists" — with n this small it almost always means the
  former.
- **Reserved for capabilities with real cost.** Running a months-long trial to
  justify a 40-token skill is not worth the complexity. Trials are for expensive
  things.

Most decisions never need one. Zero-use retirement handles the common case, and
context cost is a fact requiring no inference at all.

## Project-agnostic by construction

Nothing here reads project source, infers a language, or assumes a toolchain.
The inputs are a Claude Code transcript, Claude Code configuration, and Felix's
own records. A Rust project and a Django project produce identical ledger shapes.

The one project-specific input is `profiles.tsv`, which each project already
owns and which the harness never interprets beyond matching capability names.

## Error handling

| Condition | Behaviour |
|---|---|
| Transcript missing or unreadable | Skip the session, record nothing, exit 0 |
| Transcript malformed mid-file | Parse what is parseable, mark the row `partial` |
| `claude plugin details` fails or is slow | Omit the token column; never block session end |
| No project resolves | Silent, exit 0 |
| `ledger.tsv` unwritable | Silent, exit 0 |
| Window contains fewer than the required sessions | Report the count, propose nothing |

A `SessionEnd` hook that fails must never be visible. It records history; it has
no authority over anything.

## Testing

1. A fixture transcript with two skills attributed and three loaded produces three rows, one with zero invocations.
2. `mcp__server__tool` calls are attributed to `server`, not dropped.
3. Human-blocking tools are recorded in a separate latency column and excluded from cost.
4. A capability loaded but out-of-profile is excluded from the retirement window.
5. Zero invocations across the window, in-profile, yields a retirement proposal.
6. Zero invocations across the window, out-of-profile, yields nothing.
7. One invocation in the window suppresses the proposal.
8. A high-risk capability is never proposed for automatic action, only reported.
9. A malformed transcript line does not abort the row.
10. A missing transcript exits 0 silently.
11. `loaded` is derived from configuration, so a capability absent from the transcript entirely still produces a row.
12. Rows are append-only; re-running on the same session does not duplicate.
13. `felix ledger --trial` refuses to start a second trial on the same capability.
14. A trial report states its sample size and does not use the word "no effect".

Test 11 is the one that matters. If `loaded` were derived from the transcript,
every row would have a non-zero invocation count by construction, and the ledger
would silently become the usage counter this design exists to avoid.

## Files

New:

```
engine/harness/hooks/session-end
engine/harness/lib/ledger.sh
```

Changed:

```
engine/hooks/hooks.json     + SessionEnd
engine/harness/felix        + cmd_ledger
engine/harness/tests/run
```

Depends on the completion gate for `verification.log`, which is why it is built
second.

## Known limits

- **Retirement can be wrong.** A capability legitimately used twice a year looks
  identical to dead weight. Retirement is per-project and reversible, and the
  proposal names how long the window was, so the judgment stays with a person.
- **Attribution covers skills, not everything.** A plugin whose value is a hook
  or a subagent leaves no `attributionSkill` trace. Its contribution is invisible
  and it will look unused. Hook-only plugins must be excluded from retirement
  proposals until there is a signal for them.
- **The window is sessions, not time.** Forty sessions in a week and forty over
  six months mean very different things about a capability, and the ledger
  cannot tell them apart. The proposal prints both counts; the reading is human.
- **Nothing here measures whether the work was any good.** It measures whether a
  tool was reached for, what it cost, and whether verification passed. Those are
  not quality. Any wording implying otherwise is a bug in the report.
