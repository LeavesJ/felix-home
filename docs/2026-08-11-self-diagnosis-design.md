# Self-diagnosis — design

Written 2026-08-11, after two coverage gaps were found by a person noticing.
Every number below was computed on this machine, against the tree at `d8e2a17`
and the Claude Code build actually installed here. Nothing is assumed.

The question: **how does Felix find the gaps in its own coverage without a human
noticing first?**

---

## 1. What already exists, and the one thing wrong with it

`0.24.0` shipped `engine/harness/templates/lifecycle.tsv` and
`engine/harness/lib/coverage.sh`. One row per lifecycle moment, a stance of
`wired` or `declined`, and `felix_coverage_check` comparing that stance against
`engine/hooks/hooks.json`. Four states, each asserted in the suite. It is the
right shape and this design keeps all of it.

It has one load-bearing weakness, and it is demonstrable right now.

`felix coverage` on this tree prints:

```
Every moment has a stance, and the wiring matches it.
```

Meanwhile, on this same machine:

| Source | Events named |
|---|---|
| `~/.claude/settings.json` + `settings.local.json` | Notification, PostToolUse, **PreCompact**, PreToolUse, SessionEnd, SessionStart, Stop, **SubagentStart**, SubagentStop, UserPromptSubmit |
| every non-Felix `hooks.json` under `~/.claude/plugins` | PostToolUse, PreToolUse, SessionEnd, SessionStart, Stop, UserPromptSubmit |
| the `claude` executable, 2.1.226 | the nine in `lifecycle.tsv`, plus **SubagentStart** (13 occurrences), **TeammateIdle** (10), **PostCompact** (6) |
| `lifecycle.tsv` | nine |

The founder's own settings file binds `SubagentStart`, an event `lifecycle.tsv`
has never heard of. Two more exist that nothing on this machine binds at all.
`felix coverage` reports full coverage anyway.

The reason is `FELIX_LIFECYCLE_EVENTS` in `coverage.sh:62`: a hardcoded list of
nine, with a second copy of the same nine inlined as an alternation at
`coverage.sh:50`, free to drift from the first.

> A check whose notion of *everything* is a constant a human maintains cannot
> find what that human has not noticed. It converts "notice a gap" into "notice
> a gap once" — which is real progress — and then regenerates the dependency at
> its own boundary.

That boundary is what this design moves.

---

## 2. Where the line actually is

### Mechanically knowable

Each row names the exact files compared. All of it is bash, grep, awk and git.

| # | Question | Compare | Evidence today |
|---|---|---|---|
| 1 | Which lifecycle events exist | every non-Felix `hooks.json` under `~/.claude/plugins`, `~/.claude/settings*.json`, and a fixed-alternation grep of the `claude` executable | 12 found; `lifecycle.tsv` has 9 |
| 2 | Which Felix binds | `engine/hooks/hooks.json` keys | 7 |
| 3 | Whether a binding resolves | the `command` string in `hooks.json` vs `engine/harness/hooks/*`, and the executable bit | 7/7 resolve; `projects/felix/gate.sh:40` only checks 3 of the 7 for `+x` |
| 4 | What is live *here* vs *next* | the running plugin's cached `hooks.json` vs the tree's | 0.23.0 cache lacked `SubagentStop`; the tree has it |
| 5 | What share of real tool traffic can reach a decision | `projects/*/memory/ledger.tsv` tool names vs the `PreToolUse` matcher | matcher is `Bash`; ledger holds Bash, Edit, Read, TaskStop, ToolSearch |
| 6 | Whether a refusal rule is reachable | `projects/*/deny.tsv` column 1 vs the same matcher | both projects only use `Bash`, so nothing dead **today** |
| 7 | Which per-project tables a project lacks | paths the engine reads (`stack.tsv` 22 sites, `routes.tsv` 16, `project.json` 10, `setup.tsv` 7, `risk.tsv` 7, `evidence.tsv` 7, `profiles.tsv` 5, `maintenance.tsv` 4, `deny.tsv` 3) vs `$FELIX_HOME/projects/*/` | a project without `deny.tsv` makes `pre-tool` a silent no-op |
| 8 | Whether a `declined` reason is still true | only if the row names a dependency it rests on | not currently possible; §3 adds it |
| 9 | Machinery nothing consults | `felix_*` definitions in `lib/*.sh` vs references in `hooks/*` and `felix` | 1 of 161: `felix_toolbox_skills`, referenced only by `tests/run` |

Row 5 deserves emphasis because it needs no roster at all. The ledger is written
from real traffic by `post-tool`; comparing it against the one matcher Felix
binds measures **the fraction of what actually happens that Felix is in a
position to refuse**. Nobody has to think of the tools first.

Row 9 is included with its measured yield rather than its promise. One hit out of
161 is a cheap check, not a discovery engine, and it should be described that way.

### Genuinely needs judgment

- **Whether an unoccupied moment deserves occupying.** `SubagentStop` mattered;
  `Notification` plausibly does not. Nothing in a file decides that.
- **What to say at a moment already occupied.** See §6.1. This is the larger
  half and the mechanism does not touch it.
- **Whether what a hook says is correct.** Wired is not right.
- **Whether a `declined` reason still holds**, when the reason rests on
  something no file records.

`coverage.sh` already states this limit in its header and it is right to. The
worst outcome available here is a green report that reads as "this is handled"
when it means "somebody thought about this once."

---

## 3. The mechanism

Three parts. Only the middle one blocks, and it works with no network, no key,
no model and no machine beyond the checkout.

### Part 1 — discovery, which proposes

A pass that reads the environment and writes **one receipt**, never the tree.

Reads:

- `~/.claude/plugins/**/hooks/hooks.json`, excluding paths under `.../felix/felix/`
- `~/.claude/settings.json`, `~/.claude/settings.local.json`
- `$(command -v claude)`, if it resolves to a regular file

Candidate rule, in two steps because either alone is wrong:

1. From the config files: every key matching `"[A-Z][A-Za-z]+"[[:space:]]*:[[:space:]]*\[`.
   The initial capital is what rejects `hooks`, `allow` and
   `enabledMcpjsonServers`, which sit at the same nesting depth and would
   otherwise be proposed as events.
2. Confirm each candidate, plus every name already in `lifecycle.tsv`, with a
   **single fixed alternation** pass over the executable. A name that appears in
   no config and no table is never confirmed, because it is never asked about.

Writes `$FELIX_HOME/state/coverage/surface`, TSV:

```
# 2026-08-11T09:14:02Z	claude 2.1.226	sources=3
event	SessionStart	  settings,plugin,binary
event	SubagentStart	settings,binary
event	TeammateIdle	binary
event	PostCompact	  binary
```

`state/**` is already excluded from `felix_tree_id` by `_felix_tree_excludes`,
so writing this never dirties the tree and never invalidates a gate receipt.

### Part 2 — the check, which blocks

Reads: `templates/lifecycle.tsv`, `engine/hooks/hooks.json`,
`engine/harness/hooks/*`, the surface receipt, `$FELIX_HOME/projects/*/deny.tsv`,
`$FELIX_HOME/projects/*/memory/ledger.tsv`.

Emits `state <TAB> subject <TAB> detail`, one per line, and a non-zero exit if
anything is not `ok`. The existing four states stay; four are added, plus one
that exists purely to stop this design failing the way it is meant to prevent.

| State | Meaning | Kept from 0.24.0 |
|---|---|---|
| `ok` | stance and reality agree | yes |
| `gap` | the receipt names a moment `lifecycle.tsv` does not | yes, but sourced from the receipt instead of a constant |
| `missing` | declared `wired`, nothing wires it | yes |
| `undeclared` | wired, no row explains it | yes |
| `dangling` | a binding whose script is absent or not executable | new |
| `stale-reason` | a `declined` row whose named dependency is gone | new |
| `unreachable` | a `deny.tsv` row for a tool no matcher delivers | new |
| `blind` | a tool in the ledger, above threshold, that no matcher delivers | new |
| `cold` | no receipt, or one older than `FELIX_SURFACE_MAX_AGE` (default 14 days) | new, and the one that must block |

`lifecycle.tsv` gains a fourth column, `holds`: a literal that must be present in
`hooks.json` for the row's reason to remain true.

```
# event	stance	reason	holds
PreCompact	declined	SessionStart matches on compact, so doctrine is re-mounted afterwards	compact
Notification	declined	fires when Claude wants attention; Felix has nothing to add	-
```

This is what makes a decline falsifiable. Today `PreCompact` is declined
*because* the `SessionStart` matcher contains `compact`; if somebody narrows that
matcher, the decline silently becomes false and nothing says so. With `holds`,
that edit turns the row red. A `-` is allowed and is not an error, but the count
of `-` rows is reported, so "N declines rest on nothing checkable" is visible
instead of the excuses being invisible.

The two hardcoded rosters in `coverage.sh` collapse into one derived list: the
union of the receipt's events and `lifecycle.tsv`'s own rows.

### Part 3 — what gets said, and to whom

Nothing new is said mid-session. §5.

---

## 4. Where it runs, and why that moment

**Discovery: `SessionStart`, backgrounded, staleness-gated.** Exactly the shape
`session-start:160-173` already uses for `felix_discover_stale` /
`felix_discover_refresh_bg`. It costs nothing when the receipt is fresh, and a
session is the only moment Felix is running in the environment it needs to read.
It writes only under `state/`.

**The check: `felix gate`.** A gate is already the thing that blocks, already
runs on every engine change, and coverage only changes when the engine or the
environment changes. This is the whole answer to "not a one-off audit": the check
is a gate check, so a coverage gap goes red the same way a failing assertion does.

The check ships in the engine and self-scopes by content, never by name — it runs
only when the checkout being gated contains `engine/hooks/hooks.json`. A governed
product's gate must never go red for a gap in Felix. Invariant 1 is preserved:
the engine names no project, and `projects/felix/gate.sh` — project data, not
engine — is what calls it.

While there: `gate.sh:40` hardcodes three hook scripts for its `executable`
check and has been stale since Felix grew seven. Derive that list from
`hooks.json` and the `dangling` state subsumes it. Deleting a class of gap beats
reporting it.

**One line: the `SessionStart` banner, engine checkout only, only when not
green.** The same slot `maint_line`, `retire_line` and `tidy_line` already
occupy. That is the session which can fix it.

**The table: `felix coverage`, and the monitor.** Status belongs where somebody
can go and look.

**Deliberately nowhere in the middle.** Constraint 3 makes a mid-session report
worse than useless here: hooks bind at session start, so a coverage fix cannot
reach the session that found the gap. Interrupting a session for something only
its successor can benefit from is pure cost.

**The one thing the check states in two tenses.** Because of that same
constraint, `bound here` and `bound next` are different facts. The running
plugin's cached `hooks.json` is what this session actually loaded; the tree's is
what the next one gets. The check reports both, labelled. This is HANDOFF §3's
first trap made mechanical — the trap that cost a routing fix three false
verifications in one day.

---

## 5. Failing safe, and not becoming wallpaper

**Fail safe.**

- Every environment source is optional and each is allowed to be absent. What is
  *not* allowed is passing because they all were: no receipt, or a stale one,
  is `cold` and blocks. `lessons.md` already carries the rule — "a check that
  skips absent files passes by finding nothing" — and this design is exactly the
  shape that would repeat it.
- Discovery never writes to the tree. Appending a discovered row during a gate
  run would change the tree the gate is verifying, and the Stop hook would then
  compute a different `felix_tree_id` and block on "stale receipt". That is the
  receipt-invalidates-itself failure from `lessons.md`, one file over.
- The blocking half never touches the machine: roster against `hooks.json`
  against the scripts on disk. The environment half can only ever *add*
  candidate rows.
- **Fixed alternation only, against the executable.** Measured here: an
  alternation of 13 names over the 267MB binary returns in under a second. The
  same grep written as `.{0,120}"SubagentStart".{0,120}` did not finish in 120
  seconds and had to be killed. Context matching over a binary of this size is
  not a slower version of the same thing; it is a different cost class. This
  belongs in `lessons.md` when the code lands.
- No model anywhere in the enforcing path.

**Not wallpaper.**

- Nothing is said to a session that cannot act on it. The engine's coverage is
  one fact, identical in every session on the machine; repeating it everywhere is
  the definition of noise.
- One line, only when not green, in the checkout that owns the fix.
- A new row is red exactly once. Closing it costs one word and a reason.
- `blind` carries a threshold so a single stray tool call raises nothing.
- `holds` stops `declined` becoming a place to write "no" once and never return.
- Anything Felix can fix itself is fixed, not reported. The `gate.sh` executable
  list is the first instance and there will be others; the doctrine already says
  a suggestion for something Felix could safely have done is a defect.

---

## 6. What this cannot detect

This section matters more than the others. A self-diagnosis that overclaims is
worse than none, because it converts an open question into a settled one.

**6.1 — What to say at a moment it already occupies. This is the big one.**

Of the two gaps that started this design, the mechanism finds one.

`SubagentStop` was an unbound event: a roster comparison finds it, and would
have found it months ago. But the founder's *first* gap was that the `Stop` hook
checked the gate and never asked anyone to verify their claims. `Stop` was
bound. It had a row. It had a reason. Every check in §3 would have been green on
the day that gap was live. **No comparison of tables finds a missing sentence.**

There is a weak mechanical hint available and it should be built as advisory,
never as a check: enumerate every `exit 0` in a hook that occurs *after* project
resolution and emits nothing — the moments Felix is reached, knows it governs
this session, and says nothing. In `stop` alone there are several, and most are
correct fail-open behaviour. That list is a triage queue for a person or, under
constraint 2, for a model that may only narrow it. It is a candidate generator.
Calling it coverage would be the overclaim this section exists to prevent.

**6.2 — Whether a wired hook does the right thing.** Unchanged from 0.24.0's own
statement, and still true.

**6.3 — An event nothing on this machine uses and no roster names.** Discovery
sees the union of what other configurations already bind plus what a table
already proposes. `TeammateIdle` is visible today only because somebody typed
that string into an alternation. A thirteenth event that no plugin binds and
nobody guesses is invisible to all three sources.

Prefix enumeration was tried and is not a check. Grepping the binary for
`"(Pre|Post|Session|Subagent|User|Teammate|Notification)[A-Za-z]{0,16}"` returns
`PostCompact` and `SessionSubmit` alongside `PostgreSQL`, `Precision`,
`Prestidigitating` and fifty more. It is a fine input to an advisory command and
would be a catastrophic input to a blocking one.

**6.4 — Any extension surface that is not hooks.** Skills, slash commands,
output styles, statusline, MCP servers, settings keys, agent definitions. The
roster covers hooks because hooks are what Felix binds. A design claiming to
cover Claude Code would be lying by scope.

**6.5 — Whether a check can fail.** Invariant 6 is not made mechanical here.
The `holds` column makes one specific class of claim falsifiable; it says
nothing about whether any given assertion in `tests/run` is capable of going
red. Mutation testing is the honest mechanism and it is out of budget for a gate
that already runs a full suite. The existing discipline — show it failing before
believing it — remains a human obligation, and §8 is how this design discharges
its own.

**6.6 — A governed product's coverage.** This diagnoses the engine only.

**6.7 — A gap in the diagnosis itself.** The surface receipt has no receipt. If
discovery silently reads zero sources forever, `cold` is the only thing between
that and a permanent green. That is why `cold` blocks rather than warns, and why
the receipt records `sources=N` rather than only its contents.

**6.8 — Matcher semantics.** `blind` and `unreachable` compare a matcher string
against tool names. Felix does not evaluate that regex the way the platform
does, so both states can be wrong in both directions. They are reported with the
matcher quoted, so a wrong call is arguable rather than mysterious.

---

## 7. Rejected alternatives

**Generate `lifecycle.tsv` from `hooks.json`.** The obvious way to keep the
table honest, and it destroys the whole point: a roster derived from the wiring
can never disagree with the wiring. It would have been green on the day
`SubagentStop` was missing. Invariant 6 — a check that cannot fail is not a
check. The table has to be able to be wrong, which means something other than
the code has to write it.

**Ask a model, each session, what Felix is missing.** Rejected on constraints 1
and 2 together. The enforcing path must work with no network, no key and no
model, and a non-deterministic input to a blocking check *is* the model being the
gate. It also fails in both directions at once: a model that invents a moment
produces a red gate nobody can argue with, and a model that forgets one produces
a green gate nobody can trust. A model may rank the §6.1 silent-exit list and may
only narrow it.

**Parse the session transcript for moments Felix stayed silent.** Already
rejected in this repository, twice, and the reasons have not changed: 1.7MB of
JSONL, general JSON parsing in bash is not practical at that size, and reaching
for a parser that is breaks the invariant. Recording at the moment it happens is
the standing answer and `post-tool` already does it.

**Block mid-session the moment a gap is found.** Violates stealth in the middle,
and constraint 3 makes it worse than a style violation: the fix cannot reach the
session that found the gap. An interruption whose only beneficiary is the next
session is pure cost.

**Report coverage in every governed project's session.** One fact about the
engine, repeated in every session of every project, is how a signal becomes
wallpaper — and it would hand the founder tidying in a repository where they
cannot act on it. It goes to the checkout that owns the engine, and to the
monitor.

**Auto-append discovered rows to `lifecycle.tsv`.** Tempting, and it matches the
`felix_adopt_capability` precedent at `session-start:64-71`. Rejected because
`lifecycle.tsv` is in the engine: a session-start write would be an untested
red-tier engine edit that also needs a version bump to deploy, and a gate-time
write would invalidate the receipt the gate is about to stamp. Discovery
proposes into `state/`; a person or an agent moves it into the table, which is
also the moment the stance gets decided.

---

## 8. Demonstrating it failing

Invariant 6 applied to this design. Each state gets a fixture producing it, and
the suite asserts both directions — green on a complete fixture, red on each of
these — or the check is the thing it was built to prevent.

| State | Smallest fixture that produces it |
|---|---|
| `gap` | receipt names `TeammateIdle`; table has no row |
| `missing` | table says `Stop wired`; fixture `hooks.json` binds nothing |
| `undeclared` | fixture `hooks.json` binds `Notification`; table has no row |
| `dangling` | a binding whose `command` points at `hooks/nope`, and one pointing at a file with no `+x` |
| `stale-reason` | row `PreCompact declined … compact`; fixture `SessionStart` matcher is `startup` only |
| `unreachable` | fixture `deny.tsv` row for `Write`; matcher is `Bash` |
| `blind` | fixture ledger with 40 `Edit` rows; matcher is `Bash` |
| `cold` | no receipt file; and a receipt dated 30 days back |
| `ok` | all of the above corrected, asserted green — a red-only suite proves the check is noisy, not that it works |

The `cold` pair is the assertion that matters most: it is the only one that
proves the design cannot pass by finding nothing.

---

## 9. What this finds today, on this machine

Run against `d8e2a17`, before any of the above is built:

1. `SubagentStart` is bound in `~/.claude/settings.json` and absent from
   `lifecycle.tsv`. → `gap`
2. `TeammateIdle` and `PostCompact` exist in the 2.1.226 executable and appear in
   no table. → `gap`
3. `projects/felix/gate.sh:40` checks the `+x` bit on 3 of 7 hook scripts.
   Losing it on `subagent-stop` passes the gate silently. → `dangling` class,
   fixed by derivation
4. `PreToolUse` binds `matcher: "Bash"`. The Elenchus ledger records Bash, Edit,
   Read, TaskStop and ToolSearch, so four of five tool kinds in real use cannot
   reach Felix's only refusal point, and `deny.tsv`'s `tool` column implies
   otherwise. → `blind`
5. `coverage.sh` holds the same nine-event roster twice, at line 50 and line 62,
   free to drift. → collapsed into one derived list
6. `felix_toolbox_skills` is defined in `lib/toolbox.sh` and referenced by
   nothing but `tests/run`. 1 of 161. → reported, low yield, stated as such

Items 1 and 2 are the point: `felix coverage` prints "Every moment has a stance"
while three moments have none, one day after the table was written to stop
exactly that.
