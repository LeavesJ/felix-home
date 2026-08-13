# Handoff

Rewritten 2026-08-10, late. Read the first section before doing anything. It is
standing direction that has already been decided and should not be re-derived,
re-litigated, or asked about again.

For the mechanical state of the tree — branch, head, uncommitted, recent commits
— see `projects/felix/memory/SESSION_HANDOFF.md`, which `felix handoff`
regenerates and therefore overwrites. Durable prose goes here, not there.

---

## 1. Standing direction — decided, do not ask again

**Felix is the engineering OS and the pilot of implementation.** Not a
governance layer, not a recommender, not a sandbox. A product that adopts Felix
should get a system that does whatever implementation takes.

**The split.** The founder owns *what* gets built: product thesis, vision,
prioritisation, pitching, and approval at the risk boundaries. Felix owns *how*
it gets built, optimally — which MCP, which plugin, which skill, which agent, in
which order, in one context or several — plus installing them, tracking what
happened, and correcting course. **If the founder is thinking about tooling,
Felix has failed.** The end state is a founder who only ever considers "what
should we build next" and "should we add this".

**Interfere as much as possible.** Felix is meant to intervene, not advise. A
command that prints a suggestion for something it could safely have done is a
defect, not caution. Irreversible work still stops and asks; everything else
acts.

**Scope is Phase 1 engineering only.** Revenue, customer, support and company
administration are later phases owned by other systems. Stripe rows in the
templates are dormant capabilities, not a direction Felix grows in. Later, when
those systems exist, Felix becomes one sub-OS reporting to a chief agent — so
design its surfaces to be drivable by something that is not a human.

**How to work, decided across this session:**

- **Routine engine work on Felix does not need approving each time.** Decided
  2026-08-11. Felix's own `risk.tsv` classifies most engine changes red, and
  asking per change turned the founder into a queue for work that is tested,
  reversible, and about Felix rather than about a product. Build it, gate it,
  deploy it, say what shipped. Still stop and ask for: anything destructive in
  a product repository, credentials, money, anything irreversible, and any
  change to what Felix is *for* rather than what it does.
- **Never hand over tidying as a decision.** If Felix could safely have done
  it, doing it is the job. A founder should never be told where a duplicate
  script lives, which plugins matched no capability, or that a log needs
  truncating. Report what was done, not what they could do.
- **Decide, do not ask.** Subagents versus inline execution is Felix's call and
  the session's call, made on the shape of the work and justified in one line.
  Coupling is the usual tiebreaker: several agents editing one file invent
  conflicting assumptions. Genuinely separate files, separate repos, or
  independent adversarial review of finished work are real fan-out candidates.
- **Ask about outcomes, never mechanics.** If a question is about how something
  is built rather than what will happen, answer it yourself.
- **Override self-imposed ceilings.** Before saying something cannot be done,
  establish who set the limit. A rule in Felix's own doctrine, invariants or CLI
  is a decision, not a constraint. If this repository owns the refusal, say so
  and default to overriding it. Reserve "impossible" for cases where a specific
  mechanism can be named.
- **A model may propose, never widen.** The enforcing path stays bash and git so
  it works with no network, key or model. Advisory commands may call a model,
  but its output is a proposal and may only narrow what mechanics already
  allowed.

**The objective, declared 2026-08-12: founder interruptions per session.** Felix
had no named objective, so every improvement was argued rather than measured. An
interruption is a moment Felix needed a decision it could not make — an escape
from `felix merge`, recorded as `escalated` in `says.log` at the moment it
happens. Deliberately *not* an unrun gate or a missing test: those are Felix's
own work, and counting them would let the number improve by gating less.
Deliberately not gate pass rate either, for the same reason in sharper form — a
gate you keep loosening passes more, so that metric moves the right way for the
worst possible reason. (The `verifier` channel now detects loosening
mechanically, which makes pass rate defensible as a *paired* number, but it
still measures the gate rather than the work.)

**What the monitor is for.** Witnessing Felix guide Claude Code, so the founder
can stop caring about what it handles. It currently shows records — routes
defined, verdicts, what Felix said — and never shows whether Claude *did* what
Felix named. The compliance signal already exists in `felix_route_due`, which
reads the transcript to see whether a play step was used. Nothing surfaces it.
That panel is the one that proves the delegation works.

### Where the durable copies live

| What | File |
|---|---|
| Charter and invariants | `projects/felix/CLAUDE.md` |
| Hard-won lessons, matched into prompts | `projects/felix/memory/lessons.md` |
| This direction | this file |
| Per-project rules | `projects/<p>/{routes,risk,evidence,stack,deny,maintenance}.tsv` |

Nothing in Felix's home is auto-loaded into a session. `SessionStart` names
these files and says they are required reading; whether they get read is the
delivery risk. Inside the Felix repo this is masked because Claude Code
auto-loads `CLAUDE.md` files it finds in the tree. In a governed product repo it
is not masked at all.

---

## 2. State as of 2026-08-11

- Engine **0.35.0**, deployed and verified (`felix install` → "verified the
  installed engine matches this tree").
- `felix gate` → **pass**. **527 assertions**, 0 failed. `main` is pushed and
  **CI is green — checked, not assumed.** It had been red for at least two
  commits while this line claimed otherwise. Read `gh run list --branch main`
  before writing that sentence again.
- **`PreToolUse` now binds `Bash|Edit|Write|Read|NotebookEdit|WebFetch`.** It
  bound `Bash` alone until 0.27.0. What replaced the matcher as the
  blast-radius control is `felix_deny_overbroad`: a pattern is tested against
  two ordinary subjects — `git status --short` and `/felix/probe/ordinary` —
  before it is allowed to refuse anything, and one that matches them is skipped
  as a rule that is wrong rather than honoured as a rule that is strict.
  Skipping can only ever allow more, never less. `felix doctor` reports every
  row skipped that way, because the hook runs on every call and saying it there
  would be noise. Measured cost of the widening: **34 ms per call**, synchronous
  — roughly 1.7s across a session at the rates the ledger records.
- Felix wires **8 of the 11 lifecycle moments** anything on this machine binds,
  and has a written stance on the other three. `felix coverage` shows the table.
  At the start of 2026-08-10 it wired 3, and all three only injected text.
- **A stop now names what a revert cannot reach, and Felix can merge.** Decided
  2026-08-12 after PR #4 waited a day on a one-line dependency floor correction.
  A tier used to be a function of which file you touched; `risk.tsv` now carries
  `channel` (what merging writes outside the tree) and `confine` (what must stay
  true for the row not to fire). Most rows carry neither and are advisory. Four
  channels are engine constants no project may declare away — `disclose`,
  `execute`, `durable`, `verifier` — and `felix merge` refuses on any of them,
  computing every blocker offline and touching the network only to merge.
  **What always stops:** a secret in added lines; `.github/workflows`; an
  enforcing table or a verifier losing checks; migrations or destructive SQL;
  money; a declared consumer. Nothing else.
- **A `declined` stance is now falsifiable.** `lifecycle.tsv` carries a fourth
  column, `holds`, naming the literal in `hooks.json` its reason rests on:
  `PreCompact` holds `compact`, `PostToolBatch` holds `"PostToolUse"`. Delete
  either and the row goes `stale-reason` and the suite fails — shown failing
  against the shipped table, not only a fixture. `-` stays legal for a decline
  resting on judgement, and **1 currently does** (`Notification`); the count is
  printed every run so the unfalsifiable share is a number rather than a
  property nobody can see. Three-column tables still parse.
- **The ledger has real data for the first time.** One session: `Bash` 66,
  `Read` 23, `Edit` 15, `Write` 5, `Agent` 1 — and zero rows for
  `code-review`, `code-simplifier`, `security-guidance`, `claude-md-management`
  and `anthropic-skills`, every one mounted and never reached for. That is the
  unconfounded signal working. The retire threshold is 5 sessions, so nothing
  is actionable yet; do not act on one session.

### What Felix does without being asked

Binds the session and names the constitution and handoff as required reading;
reports capability drift and upkeep; tidies where a project has opted in;
routes each prompt and names the tool that is due; states the shape of a plan
when a prompt points at one; refuses forbidden shell commands, and forbidden
reads, writes, edits and fetches; records every
tool call and rolls it into a ledger with a zero row for everything mounted and
never reached for; checks the gate when the session stops.

### What it can do when asked

Run and record a gate; classify a diff; say what a change owes; brief an issue;
open a pull request; reach, read and route any installed plugin; install what it
has read and judged low risk; compute which tasks may run apart; report what has
never been reached for; detect a rival gate and remove it where that is safe.

### What Felix still cannot do

Mount an MCP server or enable a plugin mid-session — that needs a restart, so
tooling decisions are written as configuration between sessions. Deploy a
product. Plan work from scratch. Dispatch subagents itself. Enforce its own red
tier mechanically (see §3).

---

## 3. Operational traps that have each cost real time

- **Hooks are bound at session start.** `felix install` updates the cache and
  the CLI on PATH, so verifying a hook fix through the CLI passes convincingly
  while the hook still firing on every prompt is the one loaded hours ago. A
  routing fix was built, deployed and verified three times today and the session
  that shipped it kept misrouting for its whole life. **Check the version in the
  SessionStart banner before claiming a hook change is live here.** It is live
  for the *next* session, which is a much weaker claim.
- **A changed engine at an unchanged version never deploys.** Claude Code caches
  by version. `felix install` refuses and tells you to bump
  `engine/.claude-plugin/plugin.json`. The bump *is* the deployment.
- **`FELIX_HOME` is the main tree, not your worktree.** Editing
  `projects/*/…tsv` inside a worktree changes nothing until merged. Override
  with `FELIX_HOME=<path>` to test.
- **`felix gate` is red on any undeployed engine branch.** The `installed` check
  compares the tree against the deployed cache, so a branch that changes the
  engine cannot be green locally until it is deployed. CI skips the check when
  no plugin is installed, so a pull request can still go green.
- **Felix's red tier is honoured by behaviour, not enforced.**
  `gh api repos/LeavesJ/felix/rulesets` → 403, "Upgrade to GitHub Pro or make
  this repository public". Branch protection is unavailable on a private free
  repo. Elenchus gets real enforcement only because it is public. The decision
  was to behave as if the rule applied and state the gap rather than hide it.
  **Nothing mechanically stops a bypass.**
- **Debug `tests/run` in place.** It computes the harness path from `$0`; run it
  from elsewhere and it starts copying the root filesystem.
- **Run the suite and commit as one chain.** A piped test run masks the exit
  status and commits a red tree.

---

## 4. Guidebook exit criteria (p41)

| Promised | Status | Evidence |
|---|---|---|
| take an issue | yes | `felix brief <n>` or `--from -`; scope verdict in the exit code |
| create code | yes | |
| run tests | yes | `felix gate` → pass; 334 in Felix |
| deploy preview | **no** | no deploy target, no catalogue row keyed on `deploy` |
| test it | **yes, without Playwright** | see the note below; 45+ HTTP-level web tests, shell verified in a real browser |
| open PR | yes | `felix pr --create`, draft when the gate has not passed |
| report confidence | yes | `felix classify`, `felix evidence` |

Build list: `CLAUDE.md` yes; GitHub integration yes; PR workflow yes; tests yes;
Sentry dormant (capability undeclared for Elenchus, so it is deferred rather
than missing); Playwright installed with 0 tests; **Strix does not exist** — 0
of 273 marketplace entries, no binary, no skill, so semgrep plus
`engine/harness/bin/secret-scan` fills that slot; basic audit yes and real.

---

## 4b. Playwright: assessed 2026-08-11, deliberately not adopted

The p41 list asks for browser coverage and the honest answer is that this
project already has the coverage and does not need the browser.

Checked rather than assumed. The app was started, driven in a real browser, and
came back clean: title renders, ten scripts load including three.js and its
shaders, a canvas is present, the shell auto-creates a session and gets 200, and
the console has **zero errors**. Nobody had ever confirmed that.

Underneath it sit 45+ HTTP-level tests in `tests/test_web_api.py` — including
`test_vendor_three_is_served`, `test_index_references_*`,
`test_static_assets_are_not_cacheable` and
`test_shell_renders_the_front_door_and_living_sitting_affordances` — plus
`test_renderer_pipeline_static.py` and `test_visual_theme.py`. Every asset the
shell references resolves.

Adopting Playwright would add a ~300MB browser download to a gate that runs on
every change, in exchange for regression protection on a surface that is
already better covered than most. Revisit it when there is browser behaviour
these cannot reach — real drag-to-orbit interaction, or a visual regression that
matters — and not to tick a criterion.

## 4c. Self-diagnosis, and the ceiling on it

Two coverage gaps were found on 2026-08-11 by the founder noticing: the `Stop`
hook checked the gate and never asked anyone to verify their claims, and
`SubagentStop` was unwired. Both are one defect — a completion moment with
nothing at it — and neither was findable by reading code, because **absence has
no line number**. Nothing greps for a hook that was never written.

`lifecycle.tsv` plus `felix coverage` fix the second kind. Every moment
something binds gets a stance, the stance is compared against reality, and the
suite fails on a mismatch. The roster is **discovered** from what anything on
this machine actually binds — the first version was typed from memory and was
wrong within the hour, printing "every moment has a stance" while
`settings.json` bound `SubagentStart` and something bound `PostToolBatch`.

**The ceiling, which matters more than the mechanism.** Of the two gaps that
prompted all this, coverage finds *one*. `SubagentStop` was an unbound event, so
a table could see it. The first gap was `Stop` — wired, with a row, with a
reason, and still saying nothing useful after a green gate. It would be green
under every check proposed. **No table comparison finds a missing sentence.**

The full design, including five further states and a proposal to make
`declined` reasons falsifiable, is in
`docs/2026-08-11-self-diagnosis-design.md`. Its own conclusion is that the only
mechanical hint for the missing-sentence class is an inventory of silent
`exit 0` paths after project resolution — a triage queue for a model, never a
check, because a model may only narrow what mechanics already allowed.

Read that before building the next layer. A self-diagnosis that overclaims is
worse than none: it converts "nobody checked" into "something checked and said
it was fine".

## 5. Next, in leverage order

Everything above item 1 that used to be here is done. This list is what is left.

1. **The monitor's compliance panel.** `felix_route_due` already computes
   whether a session used the tool Felix named; nothing surfaces it. This is
   the panel that proves the delegation works rather than merely recording it,
   and the founder now has real ledger data to look at. Also: archive sessions
   clickable, which is a rendering change because `monitor.html` already groups
   by session.

2. **`felix next`.** Rank the engineering backlog Felix already tracks —
   maintenance, drift, setup gaps, evidence gaps — and say what to do. Not
   product work; that is the founder's.

3. **Convert the pure recommenders.** `doctor`, `handoff`, `promote`,
   `recommend` and `which` print and bind nothing.

4. **Auto-merge and the unattended switch.** Both unlock on five consecutive
   green merges. Maintenance will not produce them: a well-kept repository
   yields about one real PR from a full sweep of due routines, which was
   measured rather than guessed. They come from real feature work.

### Explicitly not next, with reasons

- **Playwright.** Assessed 2026-08-11 and declined; see section 4b. Revisit for
  browser behaviour the HTTP tests cannot reach, not to tick a criterion.
- **Deploy, smoke tests, telemetry.** Three empty boxes in the guidebook loop
  that are product-stage facts rather than Felix gaps. Elenchus has no deploy
  target, so there is nothing to wire.

## 6. Open decisions

- **Two of the four 2026-08-12 autonomy decisions are only half built.**
  *Doctrine content* is **done** as of 0.35.0: a `reviewed` channel, cleared
  only by a passing verdict recorded against that exact tree, wired to
  `content/(maps|rubrics)/` and `judgment_loop.py`. It is the one place a
  model's output widens rather than narrows, which is why invariant 2 in
  `projects/felix/CLAUDE.md` now carries a written exception — read that before
  extending it to a second channel. *The plugin bump* was freed to merge, and the compensating stop at `felix install` turned
  out to be unbuildable — see `lessons.md`: the gate's `installed` check means
  install must precede green, so any refusal keyed on "already pushed"
  deadlocks the loop. There is currently **no** stop on deploying an engine
  that never reached CI, only the fact that `felix install` is typed by hand.

- **Unattended repair.** Wired and off. `gh variable set FELIX_UNATTENDED --body
  true --repo LeavesJ/Elenchus`. Felix will not flip it: the evidence that would
  justify it cannot be gathered without spending it, so the first real run wants
  someone watching.
- **Exploration arm on capability mounting: not yet, revisit at 20 sessions.**
  Decided 2026-08-12. Recording what the policy *named* shipped today and is
  what makes future ledger data usable, so the retrofit problem is solved.
  Exploration is the other half and it is not cheap the same way: it spends
  degraded real work sessions to buy bits, and at roughly one session a day
  against 2 recorded it buys almost nothing for a long time. Nothing is lost by
  waiting. Revisit when the ledger holds 20 sessions.
- **Auto-merge.** Elenchus is **1 of 5**: #4 merged green 2026-08-12, the first
  of the run. Before it, three merges ever — #1 unlabelled, #3 `risk-red`.
  Felix is 0 of 5. It unlocks itself after five
  consecutive green merges.
- **GitHub MCP is broken, not missing.** `plugin:github:github` returns
  `HTTP 400: Authorization header is badly formatted`. It was authenticated once
  and the credential is now malformed. Needs an interactive session.
- **`scripts/prepush.sh` in Elenchus** is an untracked copy of a file Felix
  holds, identical today and free to drift. `felix doctor` reports it. The stale
  `scripts/gate.sh` beside it was deleted 2026-08-10 after it caused a session
  to report green from a gate missing the `secret` check.
- **`routes.log` is polluted.** Rows written before the envelope fix contain
  `session_id`, `transcript_path` and every path component, so
  `felix route --promote` ranks `users`, `claude` and `a14808` above real words.
  New rows are clean. Either wait for clean misses to outnumber them or truncate.

---

## 7. Approaches already tried and rejected

Do not re-propose these without new information.

- **Retiring capabilities by usage count.** Circular: loading a capability is
  what causes it to be used, so a high count can never justify mounting.
  **Corrected 2026-08-12:** the second half of this entry used to say absence of
  use given presence is *unconfounded*, and it is not. Felix decides what the
  routes name, so a capability no route named was never in scope in a way any
  session could act on — its zero measures Felix's priors. The ledger now
  records `named` beside `calls`, and only `named>0, calls=0` proposes
  retirement. Do not restore the stronger claim; it survived a month because it
  was written in the file that decides what counts as evidence.
- **Blacklisting words to silence hook-payload field names.** Banning `hook` to
  silence `hook_event_name` made "the stop hook is blocking" match nothing.
  Remove the structure, not the vocabulary.
- **Parsing session transcripts in the engine.** 1.7MB of JSONL, and general
  JSON parsing in bash is not practical at that size. Record at the moment it
  happens instead.
- **Making Felix public to get branch protection.** The doctrine is the moat.
- **`felix shape` deciding execution by itself.** Felix cannot reason inside a
  hook. It computes coupling, refuses the unsafe half, and records the choice.

---

## 8. The failure mode this project keeps having

Four times now, correct and tested code did nothing because of *where* it was or
was not installed: a hook absent from the plugin cache; an engine that never
deployed because its version had not changed; a receipt written inside the tree
it described; and a hook fix that never reached the session that shipped it.
Every one was found by running the deployed thing against a real repository,
never by the suite.

A fifth variant is about where an explanation lives: a fix described in a commit
message rather than in `lessons.md` was repeated within the day. `lessons.md` is
matched into prompts; a commit message is read once and never again.

A sixth, found 2026-08-11: *where the test runs*. Three assertions about bundled
plugins passed on the laptop and failed on every CI run, because the branch they
name only executes where no `claude` CLI answers — which is every runner and no
laptop. Sitting in that branch was a real defect: the 0.26.0 bundled fix had gone
in one line below the short-circuit that returns first. Same shape as the others.
The code was correct; the place it ran was not the place it mattered. The tell is
CI and local disagreeing, so treat that as a finding rather than as flakiness,
and put the machine into the fixture — a stripped `PATH`, a fixture `HOME`.
