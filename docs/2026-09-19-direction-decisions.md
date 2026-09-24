# Direction decisions, 2026-09-19

The founder affirmed an endgame on 2026-09-18 and delegated how to get there:
"we'll go with what's best… whether keeping or turning off the hooks is better
for 'more omni felix', whether we incorporate other tools outside of bash".
This records what was decided, on what evidence, and what was not established.

**The endgame, adopted.** Felix is an autonomous engineering control plane, not
a better coding agent and not only a trust kernel. The user says what they
want; Felix determines what engineering must exist for that intent to become
reality, assembles it, operates it, proves it, and returns to the human only
when judgment or authority is genuinely irreducible. Two planes: a Capability
Plane (what the project needs, who provides it, how well it worked, when to
retire it) and a Trust Plane (facts, unknowns, obligations, who proved what
against which revision, release authority). They map onto v3.2's authority
split, so v3.2 and its amendments stay the governing architecture. The thesis
under it: engineering expertise as infrastructure — what to ask, what to check,
what is abnormal, what is unproven — so a student supplies idea, taste and the
important choices.

**How it was decided.** Three workflows, 39 agents: fact-gatherers, independent
proposals that never saw each other, one adversarial refuter per proposal, and
judges with different lenses. Every proposal in both design panels was judged
fatal as written by its refuter and survived in a reduced form; the decisions
below are the reduced forms. A rate limit cut all three runs part-way; they
were resumed from cache the next day and completed.

## 1. The engine's language: rows first, in bash

**Decision.** The enforcing path stays bash, git and the POSIX userland,
offline. No new runtime joins it. The typed-runtime question is closed until a
measurement and a founder's dated amendment of invariant 2 reopen it.

This reverses the position I gave the founder on 2026-09-18 (move the
typed-record kernel before v3.2 step 3). The evidence did not support it.

**The evidence.**
- *How much of the pain is the language.* All 159 lessons were classified by
  root cause: design 44, tests that cannot fail 30, shell semantics 26, method
  21, platform 18, stringly-typed records 10, state recalled not read 7, other
  3. Language-caused, strictly: 36 (23%). A typed kernel would eliminate 26
  (16%). The rest is whether a check can fail for the right reason, whether a
  claim was read, whether silence means ok — which is the expertise the thesis
  wants turned into machinery, and no rewrite buys it. `shellcheck` would have
  caught one lesson of 159.
- *But the quarter is heavier than its count.* Six of the eleven lessons that
  record their own recurrence are language-class; four of the six defects
  reviewers found in #261 were record or shell errors; and the engine parses
  tab-separated rows at 509 sites in 50 of 67 files with no shared reader.
- *Where §12's property actually comes from.* v3.2 §12 asks for typed stores
  with separate mutation rights. In Felix those rights are enforced by where a
  store is read from and which commit authored it — exceptions from
  `refs/remotes/origin/main`, the risk table at base and head with the
  stricter winning, the judge byte-identical to main's engine — not by a type.
  A struct cannot stop a session writing a file. A ref can.
- *What every alternative costs.* Scores out of ten across the three lenses
  (trust base, v3.2 delivery, the student's chair): bash hardened 7.5 / 7 / 7;
  sqlite as evaluator 3 / 3.5 / 5; python standard library 2.5 / 3 / 4; a
  tracked Go binary 2 / 2 / 3. Each non-bash option puts a host-supplied,
  unpinned or unreadable program on the floor, needs the founder to amend
  invariant 2 and amendments §1, and spends 9 to 25 sessions before the first
  new v3.2 row. On a stock Mac only `sqlite3`, BWK `awk` and bash 3.2 exist;
  `jq`, `python3` and `go` do not. Hook latency is not a reason to leave: the
  one synchronous per-tool-call hook measures 21–27 ms.

**What to build, in order.**
1. *The validator, not a migration* (about two sessions). `lib/table.sh` as a
   validator before it is a reader; an engine-only `templates/schemas.tsv`
   declaring each table's columns and what that table's emptiness means; a
   gate `schema` check that enumerates every tracked `*.tsv` and fails on a
   table with NO schema row as well as on a refused row, so it can report its
   own gap. `schemas.tsv` joins `FELIX_ESCAPE_TABLES`. `hooks/pre-tool` and
   `lib/deny.sh` are not touched. Kill test: old readers against the new one,
   byte-identical over every real table and a mutated corpus. A newborn
   `felix new` project must gate exactly as it does today.
2. *New v3.2 stores are born on that layer*, where there is no legacy reader
   and so no migration cost. First: `coverage.tsv` with the offline citation
   check from `docs/2026-09-18-ecc-against-v32.md` §5.1, which the north-star
   eval needs first. An existing reader moves only when a row forces it.
3. `jq`, `sqlite3`, `python3` and `shellcheck` may be used as suite-side or
   CI-only cross-checks, recorded as skipped where absent. None answers on the
   enforcing path: a judge whose verdict varies by machine is not a judge.
4. The one constitutional edit proposed is a correction of fact, for the
   founder to make: invariant 2 reads "bash and git only", and the accurate
   sentence is "bash, git and the POSIX userland; no runtime, no network, no
   model". The architecture section says forty-one libraries; there are 49.

## 2. ECC's hooks: off, in two steps

**Decision.** End state: every ECC hook off at user scope, ECC's skills,
agents and commands kept as content and workers. One voice: Felix is the only
thing that refuses or speaks inside a session. Reached in two steps, because
the steelman for keeping them found four guards Felix has no equivalent for.

**Evidence.** Of 23 hook entries (40 leaf behaviours, all live: the profile is
`strict`), the proposal kept none and harvested five ideas; the steelman kept
four: `pre:bash:block-no-verify`, `pre:config-protection`, the destructive
branch of `pre:bash:gateguard-fact-force`, and `pre:bash:commit-quality`. Each
acts before an irreversible or check-weakening act and works in any directory,
including ones Felix does not govern — which is where the thesis's student
starts. Felix covers hook-bypass for one spelling in one project, linter-config
weakening nowhere, and working-tree destruction nowhere. The one hook with
measured harm is the first-touch edit gate: it reads nothing, passes on a bare
retry, skips subagents, refused about one parallel first-touch edit in three,
and refused this session a dozen times.

**The mechanism, corrected and measured.** The ground report's mechanism was
wrong twice. ECC's plugin options live at `pluginConfigs["ecc@ecc"].options`
in the USER settings file (today `hooks_enabled: true`, `hook_profile:
"strict"`), and project settings are not read for plugin options. ECC exposes
only those two options; selective disabling is the `ECC_DISABLED_HOOKS`
environment variable. Measured on CLI 2.1.260: an `env` entry supplied through
settings reaches ECC's hook process — with `ECC_HOOKS_ENABLED=false` its
SessionStart hook went from "Found 17 recent session(s)" to a pass-through.

**Step 1, now — the founder's edit to `~/.claude/settings.json`.** Add to the
existing `env` block: `GATEGUARD_BASH_ROUTINE_DISABLED` = `1`, and
`ECC_DISABLED_HOOKS` = the ids of everything except the four guards:
`pre:edit-write:gateguard-fact-force, pre:edit-write:suggest-compact,
pre:observe, pre:observe:continuous-learning, pre:compact,
pre:mcp-health-check, post:mcp-health-check, pre:governance-capture,
pre:write:doc-file-warning, session:start, post:dispatcher:sync,
post:dispatcher:async, post:skill:track, stop:session-end,
stop:evaluate-session, stop:cost-tracker, stop:desktop-notify,
stop:format-typecheck, stop:check-console-log, stop:plan-canvas-pending,
pre:bash:auto-tmux-dev, pre:bash:git-push-reminder, pre:bash:tmux-reminder`.
Validate the file afterwards: a settings file the CLI rejects disables every
plugin silently, Felix included. It is a persistent change to the founder's
own configuration across every project, so it is handed over, not made.

**Step 2, after Felix's equivalents land — set `hooks_enabled` to `false`.**
The harvest, each as a row or invisible context, never a second gate:
- a NEW `templates/deny.tsv` seeded by `felix new` (none exists): hook-bypass
  in all its spellings, working-tree destruction, history rewrite on shared
  refs, each row carrying a must-refuse / must-allow spelling list;
- `verifier` rows in the `risk.tsv` template for linter, formatter, type and
  test configs, so weakening the judge stops for a person at the merge
  boundary, where it also sees edits made through Bash;
- dependents handed to the model at the first touch of a file, from the
  knowledge graph, as PreToolUse `additionalContext` — GateGuard's idea
  inverted: Felix supplies the facts and never refuses;
- formatting and type-checking inside `gate.sh`, never after the receipt.

**Two findings about Felix itself.** `lib/guard.sh` detects another plugin's
refusal only as `hook_blocking_error`; GateGuard refuses through JSON
`permissionDecision: deny`, so Felix's ledger has never seen one of its
refusals. And switching ECC off stops growth but removes nothing: about 49 MB
of captured tool calls and command logs stay on disk in plaintext; deleting
them is the founder's act.

## 3. Control plane v0: the lease and its record

**Decision.** Build on the bash dispatcher's spine as a sequenced hybrid, and
do not build the schedule first. Both judges chose it (6.5 of 10 under each
lens, against 5 and 4 for an Agent SDK orchestrator and 3.5 and 3 for CI plus
cloud agents). All three designs were fatal as written.

**What v0 is.** `felix dispatch --dry-run` and `felix dispatch`: one tick,
typed by a person. A lease is one headless session launched `--bare` and
`--restricted`, with `--strict-mcp-config`, no plugin, no Bash, no setting
source, a dollar cap, and exactly one allow rule — an Edit on the answer file.
Because no hook runs inside such a session, a dispatch cannot touch a
trust-plane file even by side effect: closure by construction, not by a rule
somebody must remember. It crosses into the trust plane only through the
provider protocol, unchanged, and a person's commit is still the only
admission. It records a lease row, a result row, and a hold a person can read.
It does NOT close amendments §1.3 ("nothing schedules discovery") and should
say so. Invariant 2 never bound this layer: it proposes and executes, it never
judges.

**Measured.** A launcher chooses a session's toolbox per dispatch: a default
launch here loaded 27 plugins, 12 MCP servers and 434 skills; a leased launch
loaded one plugin, no MCP servers and 17 skills. So the constitution's "cannot
mount mid-session" limit, and the distance table's claim that leases and
revocation need a platform that activates mid-session, are limits of living
inside a session. A lease is one dispatched session's launch configuration;
revocation is that session ending. Unattended dispatch needs its own
credential — the CLI's OAuth session was expired and is separate from the
desktop app's — and supplying one is a person's act.

**Before any scheduler, four things the refuters found in the engine today.**
1. *The decision epoch is not single-valued across environments.* The hashed
   topology includes an instrument token that depends on which `git` is on
   PATH, so a launchd job or a CI runner computes a different epoch from the
   founder's shell and every scheduled answer would read stale on the laptop.
   An engine-level decision, with an assertion that computes the epoch under
   two PATHs.
2. `lib/automerge.sh:54` and `lib/repair.sh:43,51` read the latest run of any
   workflow. A second workflow would dirty the auto-merge streak and spend the
   repair ceiling. Filter to the gate workflow before a second one exists.
3. *The discovery protocol has never produced a file on this machine.* None
   of twelve project memory directories holds an obligations request, answer
   or `candidates.tsv`. Run it once by hand on elenchus first, and record
   accepted, refused and admitted counts, so the first lease is not also the
   protocol's first answer.
4. `--setting-sources project` is unsafe in CI: a same-repo pull request can
   add a hook or an `env` block that runs in the step holding the API key.

**Later, and gated on measurements:** execution leases in a detached worktree;
the schedule; the release half in CI on `deployment_status`; and a TypeScript
supervisor on the Agent SDK only once two real adapters and a queue exist, its
first assertion being that it writes record rows byte-identical to the bash
tick's.

## 4. The market, verified

An outside LLM's market map was checked at primary sources by thirteen agents,
one of which only tried to refute the claimed gap. Every "does not" below is
absence of documentation, not proof of absence.

- **The gap is real.** No product, project or paper treats the whole loop —
  intent, reality, missing engineering, persistent obligations and unknowns,
  required capabilities, discovery, admission, composition, observation,
  independent evidence, deterministic release, telemetry, reconciliation — as
  one system. The ends are crowded. Nobody derives required capabilities from
  obligations, reconciles capabilities against obligations, holds a blocking
  UNKNOWN in a standing project ledger, has receipts that go stale when a
  dependency changes, or retires a capability on observed value.
- **The map missed the two closest neighbours.** AI-SDLC (Apache-2.0, one
  maintainer) already commits SHA-bound signed attestations into the adopter's
  repository and has a gate that refuses undecided work: repo-owned,
  revision-bound receipts are NOT novel, and it is the likeliest ally. Tessl
  ships most of a skills lifecycle and deliberately removed need-derivation.
- **Overstated rows.** Factory's "risk tiers, validation gates, audit" is
  marketing wording, and the "autonomy ratio" it ships is tool calls per user
  message. Factory remains the largest threat to the narrative (USD 200M at
  5B, 2026-09-15); its validation is user-skippable, not commit-bound, and its
  state lives on its platform. Anthropic's Claude Code Setup is read-only by
  its own README, and the platform's stated stance is that it "never installs
  a plugin automatically".
- **What to lead with.** Not repo-owned receipts. A derived, blocking UNKNOWN;
  receipts that go stale; need-driven capability lifecycle. Codex CLI is
  Apache-2.0 with repo-level hooks: the second harness that would prove the
  ledger survives a change of agent.
- **The wedge.** One obligation's whole life in a public git history a
  stranger can replay offline with no model and no vendor. Its irreducible
  core: a derived, blocking UNKNOWN plus a receipt that goes stale on a
  dependency change. That is the north-star eval, made public.

## 5. The order this implies

**Superseded 2026-09-23** by [the roadmap](2026-09-23-roadmap.md), after the
founder made Felix a commercial product (#290). The list below is kept as it
was decided.

1. The founder's step-1 settings edit (§2).
2. `table.sh`, `schemas.tsv` and the `schema` gate check; in the same sessions
   `coverage.tsv` with the offline citation check (§1).
3. The harvest rows (§2), after which the founder sets `hooks_enabled` false.
4. The obligations request run once by hand on elenchus; the two engine
   narrowings, epoch portability and the workflow filter (§3).
5. `felix dispatch`: the lease and its record (§3).
6. The public wedge (§4), which needs 2, 4 and 5.

## 6. Not established

Whether `--restricted` with `dontAsk` permits in-directory reads with no Read
allow rule (the v0 dry run must measure it). The Agent SDK's launch surface
and whether Anthropic offers managed scheduled agents: not fetched. Whether a
stock ubuntu runner carries `sqlite3`, `jq` and `go`: recollection only. Which
grounded fact moved between two gate runs on an unchanged tree on 2026-09-18
and 19; the gate says that one moved and not which. Every market figure is a
point-in-time reading of vendors that ship weekly.
