# Intent router — design

Slice 1 of four in automatic tuning of MCP servers and plugins. Written
2026-08-09. Every capability claim below was checked by running it on Claude
Code 2.1.226, not by reading documentation.

## The problem

Felix knows what a project has installed (`stack.tsv`), what a kind of work
needs (`profiles.tsv`), and what this change risks (`risk.tsv`). It does not
know what *this prompt* is about, so none of that knowledge reaches the session
at the moment it would change what happens.

The result is that choosing tools is manual. There are too many options to hold
in your head, so the good ones go unused: `impeccable` exists and never fires,
`frontend-design` is installed and forgotten. A capability nobody remembers to
invoke is indistinguishable from one that was never installed.

## What changed since the Phase 1 handoff

`HANDOFF.md` states the p3 router promise "cannot be met as written" because
"Claude Code has no runtime API for it." That is now only partly true. Verified
on 2.1.226:

| Capability | How | Verified by |
|---|---|---|
| Per-project plugin activation | `claude plugin disable <p> --scope project` | `--help` |
| Per-project MCP activation | `~/.claude.json` → `projects.<path>.disabledMcpServers`, `enabledMcpjsonServers`, `disabledMcpjsonServers` | reading the file |
| Token cost per component | `claude plugin details <p>` | ran it: superpowers `~715 tok` always-on |
| Usage telemetry | `~/.claude.json` → `pluginUsage`, `skillUsage` | ran it: superpowers 1962 uses |
| Per-session mounting | `--mcp-config`, `--strict-mcp-config`, `--plugin-dir`, `--settings` | `--help` |
| Per-turn gating | `PreToolUse` deny, `permissions.deny` on `mcp__*` | existing hooks |

What remains genuinely impossible is **mid-session** mount and unmount. So there
are three tuning granularities — per-project (persisted), per-session (at
launch), per-turn (deny only, no token saving) — and Felix should stop claiming
otherwise in either direction.

This slice does not touch mounting. It routes *skills and attention*, which is
the only layer that can respond within a single turn.

## Scope

In scope: deciding what kind of work a prompt is, and telling the session which
of its already-available capabilities apply, in what order.

Out of scope, deliberately, and each its own later slice:

1. **Cost and usage ledger** — what each plugin costs in always-on tokens and
   how often it is actually used, per project.
2. **Session-boundary reconciler** — enabling and disabling plugins and MCP
   servers at project scope based on that ledger.
3. **Discovery** — keeping the catalogue fresh from marketplaces and registries.

This slice deliberately produces the usage signal the other three need.

## Architecture

One new link in a chain that is otherwise already built:

```
your prompt ─┐
changed files├─→ routes.tsv ─→ profiles.tsv ─→ stack.tsv ─→ concrete tools
branch name ─┘      NEW          exists         exists       + mounted?
```

`profiles.tsv` answers "what capabilities are in scope for this kind of work".
`stack.tsv` answers "what concrete tools does that capability mean here, and is
each one mounted". Both already work and neither changes.

Context comes from `felix_lessons_context` (`lib/lessons.sh:82`), which already
assembles prompt text, changed file paths, and the branch name. It is reused
unchanged.

## Decisions, and what was rejected

**Rules table, not a model.** A model fallback was designed and then rejected on
measured evidence:

| Variant | Latency | Cost/call | Turns |
|---|---|---|---|
| `claude -p` plain | 6.9s | — | — |
| `+ --json-schema` | 8.6s | $0.056 | 3 |
| `+ --tools "" --system-prompt` | 4.1–6.0s | $0.0018 | 1 |
| `+ --effort low`, three runs | 4.9s / 7.7s / 6.7s | $0.0018 | 1 |

Classification quality was good — 3/3 correct, and "the checkout page is
throwing a 500 in production" routed to `incident` rather than `debug`. Cost was
acceptable at roughly $2/month against a 40/day ceiling. **Latency killed it.**
About 2s of every call is `claude` CLI startup before a request is sent, which
`--effort low` does not affect, so a sub-second router is not reachable through
the CLI. `--json-schema` additionally costs 31× more because it forces a
tool-use round trip.

A direct Messages API call would plausibly reach 300–600ms, but
`ANTHROPIC_API_KEY` is unset and no `apiKeyHelper` is configured, so it would
require a human setup step to enable something the rules table mostly does for
free.

Recorded so nobody rebuilds it: **a model in the UserPromptSubmit path is not
viable through the CLI at any effort level, and the reason is process startup,
not inference.**

**`--bare` cannot be used for subprocess isolation.** Its help states OAuth and
keychain are never read; it returns `Not logged in · Please run /login` on a
normal session. `--safe-mode` is the correct isolation flag — it disables hooks,
plugins, MCP and CLAUDE.md while auth continues to work. Recorded because this
is non-obvious and cost real time to discover.

**Silence on no match.** Not a menu, not a map. The existing hook's own comment
is correct: a hook that speaks every turn is one people learn to skim.

**Speaks only when the route changes.** Twenty turns of frontend work produce
one block, not twenty.

## Data

### `routes.tsv`

Per project, seeded from `templates/routes.tsv` by `felix new`. Read top-down;
specific routes sit above general ones because file order breaks ties.

```
# name	keywords	profile	play
incident	production outage down sev alert pager	incident	systematic-debugging
debug	broken failing crash regression traceback	core	systematic-debugging
frontend	page component layout styling render view	frontend	frontend-design impeccable playwright
backend	endpoint handler schema query migration	backend	-
release	release shipping version changelog	release	verification-before-completion
build	build implement feature create	core	brainstorming writing-plans
```

- `name` — the route, and the key used in the log and session state.
- `keywords` — space-separated. A keyword matches when it appears as a substring
  of a context token, so `page` matches `pages` and `render` matches `rendering`.
  Each distinct keyword scores at most once per decision, however many times it
  occurs, so a repeated word cannot dominate.
- `profile` — must name a row in `profiles.tsv`. Determines what "in scope" and
  "not mounted, would help" are measured against.
- `play` — ordered sequence of skills or plugins to use, or `-` for none. The
  order is the point: build with `frontend-design`, *then* critique with
  `impeccable`.

### Scoring

Context tokens come from `felix_lessons_context`: lowercased, split on
non-alphanumerics, minimum 4 characters, stopwords dropped — the same filter
`felix_lessons_for` already applies.

**Prompt tokens score 2, branch and changed-path tokens score 1.** Without this
weighting, a dirty frontend tree drags a backend question toward `frontend`. The
prompt is what you just said; the tree is only where you happen to be standing.

Highest total wins. Ties break by file order, which is why the table is ordered
specific-to-general.

Minimum score to speak is `FELIX_ROUTE_MIN_SCORE`, default **2**. The weighting
makes that threshold mean something precise: *one keyword you actually typed, or
two corroborating tokens from the branch and the working tree.* A threshold of 1
was rejected because a single path token would be enough to route, which is the
tree deciding what you meant — exactly the drag the weighting exists to prevent.

Worked example. "let's build the results page" yields prompt tokens `build`,
`results`, `page` after the ≥4-character and stopword filters. `page` hits the
frontend route and `build` hits the build route, both at 2. Frontend sits higher
in the file, so frontend wins. That is the intended answer: the noun you named is
a stronger signal than the verb.

### `routes.log`

`projects/<p>/memory/routes.log`, tab-separated, appended one line per decision,
committed:

```
2026-08-09T14:22:10Z	frontend	7	let us build the results page
2026-08-09T15:01:44Z	-	0	rework how the ingest worker backs off
```

Hits and misses both. Misses carry a `-` route and score 0, and are the raw
material for `felix route --promote`.

### Session state

`$FELIX_HOME/state/route/<key>` holds the last route spoken, so the hook can stay
quiet until the route changes. Ephemeral and gitignored.

`<key>` is the `session_id` from the hook's stdin JSON. If it cannot be
extracted — the JSON is tokenised rather than parsed, deliberately, per
`hooks/user-prompt:9-12` — the key falls back to a hash of the repository root.
That degrades correctly: two concurrent sessions in one checkout would share a
key and one of them would occasionally stay quiet when it should have spoken,
which is a missed suggestion rather than a wrong one.

## Required precondition: the gitignore defect

`.gitignore:3` is `*.log`. Verified with `git check-ignore` and `git ls-files`:
**zero `.log` files are tracked**, and the pattern silently swallows

- `projects/felix/memory/mistakes.log` — what `felix promote` reads to find
  recurring mistakes, described in `felix` itself as "the strongest promotion
  signal there is"
- `projects/elenchus/maintenance.log` — which `felix:861` explicitly instructs
  you to commit "so the cadence survives this machine"

Neither survives this machine today. This is the same class as the lessons-hook
defect in `HANDOFF.md`: code correct, tests green, behaviour absent where it
matters. `routes.log` would have inherited it.

Fix: narrow the pattern so Felix's own memory is tracked while project runtime
logs stay ignored.

```
*.log
!projects/*/memory/*.log
!projects/*/maintenance.log
```

## Behaviour

### What the hook injects

```
Felix routed this to: frontend

Use, in order:
  frontend-design    plugin   mounted
  impeccable         skill    mounted
  playwright         plugin   mounted

Not mounted, would help: none.
Working tree touches a red path: src/auth/session.py — a person decides here.
```

The red-path line appears only when uncommitted changes match a `red` row in
`risk.tsv`, reusing `felix_incident_severity`. Two lines of code, and it is the
difference between a router that helps and one that hands you fast tools while
you edit the authorization model.

Route and lessons are gathered and emitted as **one block**. The existing hook
returns early when there are no lessons (`hooks/user-prompt:30`); that early
exit must move, or routing would be suppressed by an unrelated absence.

### Commands

```
felix route                  route the current context (branch + dirty files)
felix route --for "<text>"   route a hypothetical prompt
felix route --explain        per-route scores, for debugging the table
felix route --list           show the table
felix route --promote        recurring words in prompts that matched nothing
```

`--promote` is the learning path. It tokenises the miss lines in `routes.log`
with the same filter the matcher uses, counts words appearing in three or more
distinct misses, and prints each with its count and the misses it came from. It
does not guess which route the word belongs to — word frequency is not
understanding, the same caveat `felix promote` already prints about the devlog.
You add the row. Felix does not edit `routes.tsv` itself, for the same reason
`felix lesson` is a command rather than an inference.

## Error handling

Every failure mode resolves to silence and exit 0. The router must never be
capable of breaking a session it exists to help.

| Condition | Behaviour |
|---|---|
| No `routes.tsv` | Hook silent. `felix route` dies with a clear message. |
| Malformed row (wrong column count) | Skipped. Other rows still match. Reported by `--explain`. |
| `profile` names no row in `profiles.tsv` | Route still fires; the scope report is omitted; `--explain` warns. |
| `play` entry absent from `stack.tsv` | Listed as `not declared`, not hidden. |
| Score below threshold | Silent. Logged as a miss. |
| State dir missing | Created. |
| State dir unwritable | Speak anyway. A repeated block is a smaller harm than a broken hook. |
| `routes.log` unwritable | Speak anyway; drop the record. |
| No project resolves | Silent, exit 0 (existing behaviour). |

## Testing

All in `harness/tests/run`, against a throwaway Felix root governing an invented
project, as the existing suite already does. Every one of these is deterministic
— there is no model in this design, so there is nothing the gate cannot assert.

1. `felix route --for "build the results page"` produces the exact expected block.
2. Prompt tokens outweigh path tokens: a backend prompt in a dirty frontend tree routes to backend.
3. A tie is broken by file order.
4. A score below the threshold — including a lone path token at score 1 — produces no output and exit 0.
5. The hook emits exactly one block containing both route and lessons.
6. The hook is silent when `routes.tsv` is absent.
7. The hook exits 0 when the state directory is unwritable.
8. The same route twice in one session speaks once.
9. A route change within a session speaks again.
10. A malformed row is skipped and the remaining rows still match.
11. A `play` entry absent from `stack.tsv` is reported as `not declared`.
12. A red path in the dirty tree adds the caution line.
13. `routes.log` gains exactly one line per decision, hits and misses alike.
14. `felix route --promote` surfaces a word repeated across three misses.
15. `git check-ignore` reports `projects/*/memory/*.log` as **not** ignored.

Test 15 is the regression guard for the gitignore defect. The class of bug it
covers — correct code whose effect is cancelled outside the tree the suite
examines — has now occurred three times in this project.

## Files

New:

```
engine/harness/lib/route.sh
engine/harness/templates/routes.tsv
projects/felix/routes.tsv
projects/elenchus/routes.tsv
```

Changed:

```
engine/harness/felix              + cmd_route, dispatch, usage line, source
engine/harness/felix              cmd_new copies the routes template
engine/harness/hooks/user-prompt  route + lessons as one block
engine/harness/tests/run          the assertions above
.gitignore                        stop ignoring Felix's own memory
```

## Known limits

- **The table is hand-written.** Novel phrasing misses. Missing is silent and
  costs nothing, and `--promote` converts repeated misses into rows, but the
  table is only as good as its curation. This was chosen over a model on
  measured latency, not on principle.
- **Routing is a suggestion.** The hook injects text; nothing forces the session
  to follow it. There is no mechanism in Claude Code that would, and claiming
  otherwise would be the same theatre `HANDOFF.md` accuses `felix profile` of.
- **Skills only, within a turn.** Plugins and MCP servers cannot be mounted
  mid-session. When a route names something unmounted, Felix reports it and the
  reconciler slice acts on it at the next session boundary.
- **`profiles.tsv` is untested against real use.** Like `risk.tsv` before it, it
  was written in one sitting. The log is what will show whether the profiles
  carve the work up the way the work actually divides.
