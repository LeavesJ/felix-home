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
- **An escape stops the merge. It does not stop the session.** Noticed
  2026-08-13, by the founder, about this session. `felix merge` refusing on an
  `execute` or `verifier` channel is correct — the mechanical path fires on a
  path because it cannot read intent. What followed was not: the escape was
  forwarded verbatim as "the founder's call", twice, and both times a single
  command settled it (the new jobs referenced zero existing secrets; the two
  they did name do not exist). Same for the Stop-hook gap, deferred as needing a
  decision and then answered in twenty minutes once asked.
  **When a channel escalates, do the analysis and arrive with a recommendation.**
  The founder's input should be a yes or no on a resolved question, never a
  research task handed back. Reserve the open question for things that turn on
  their preference or authority — which credit pool to spend, what gets built —
  not for facts a command can establish.
  This is the charter's own defect worn as prose. `felix promote` had the
  finding and printed `felix lesson "..."`; `felix install` knew the fix and
  printed "bump the version"; both were called defects and fixed this session by
  the same session that was doing it in conversation. And it moves the declared
  objective the wrong way: forwarding a mechanical stop *is* a founder
  interruption, which is the number Felix exists to reduce.
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
reads the transcript to see whether a play step was used. **Built 2026-08-12**,
though not from that: the ledger's `named` beside `calls` is the same question
answered from committed rows instead of a transcript, so the panel is arithmetic
rather than a parser. It reports "no data" until sessions accumulate under the
new column, and refuses to read an absence as compliance.

### The shape Felix is growing into

Named by the founder 2026-08-13. The middle is becoming strong; **both ends are
missing**, and they are the ends that make it autonomous rather than assistive.

| Stage a mature Felix needs | What exists today |
|---|---|
| INTENT | **absent.** Nothing initiates. Every session begins with a human prompt. |
| PLAN | partial. `felix brief` scopes an issue and says what a fix must prove; routes name `superpowers:writing-plans`. Felix does not plan. |
| CHOOSE EXECUTION SHAPE | `felix shape` — computes coupling, refuses the unsafe half, records the choice. |
| ASSEMBLE CAPABILITIES | `stack.tsv`, `felix ready`, `felix toolbox`. Bounded: **cannot mount mid-session**, so it writes config the next session boots with. |
| DISPATCH | **absent.** Felix names the tool; the session dispatches it. |
| IMPLEMENT | the session. |
| TEST | `felix gate`. |
| DIAGNOSE | partial. `felix next` rank 5 reads `mistakes.log` and distinguishes "no lesson yet" from "the lesson is not working". |
| REPAIR ↺ | `unattended.yml` — wired, and off. Never run for real. |
| VERIFY | gate receipts keyed on tree identity, plus the `Stop` hook. |
| REVIEW | `felix review` and the `reviewed` channel. Built 2026-08-13. |
| SHIP | `felix pr`, `felix merge`. Merge only started working 2026-08-13. |
| OBSERVE PRODUCTION | **absent.** Sentry is declared and unconfigured; nothing is deployed. |
| REPAIR / LEARN | `lessons.md` matched into prompts, the ledger, `felix promote`, `felix next`. |

Where Felix actually sits, in its own vocabulary: UNDERSTAND → ROUTE → CONFIGURE
→ GUIDE EXECUTION → OBSERVE → VERIFY → CLASSIFY → PR/MERGE → REMEMBER.

**The two gaps are not the same size.** *Autonomous initiation* is blocked on a
design question nobody has answered — what may wake Felix, and on whose
authority. *Production feedback* is blocked on a fact: nothing is deployed, so
there is nothing to observe. The second unblocks itself the day there is a
deploy target; the first will not unblock on its own.

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

- Engine **0.47.5**, deployed and verified (`felix install` → "verified the
  installed engine matches this tree").
- `felix gate` → **pass**. **601 assertions**, 0 failed. `main` is pushed and
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
  **Corrected 2026-08-13:** `felix merge` could not merge at all until 0.42.0 —
  it built `gh pr merge --repo <slug> --squash` with no pull request named, and
  gh refuses that client-side. The refusal paths were all tested; the one line
  that reaches gh was not. It has still never merged anything, and now there is
  a reason rather than an absence of occasions. **It cannot be reached from a
  worktree that changed the engine.** Merge wants a green gate receipt for that
  exact tree; the gate's `installed` check compares the tree with the deployed
  cache; the marketplace is pinned to one directory, so a worktree's engine is
  never the served one and `installed` can never pass there. No receipt, no
  merge, permanently — the same cycle already recorded for install-versus-push,
  closing one stage later. PR #1 was merged through `gh` on green CI instead,
  and the gate was then run in the tree that can deploy, where `installed`
  passed. Loosening the gate was available and deliberately not done; the two
  candidate fixes are in `lessons.md`, and the better one leaves the verifier
  alone.
  **What always stops:** a secret in added lines; `.github/workflows`; an
  enforcing table or a verifier losing checks; migrations or destructive SQL;
  money; a declared consumer. Nothing else.
- **Several sessions at once is a supported case, and was checked rather than
  assumed.** People keep multiple terminals on one checkout. Receipts are safe
  by construction: `felix_tree_id` hashes every uncommitted byte, so a second
  session's edit changes the identity and no verdict or gate receipt can be
  inherited across it; the gate receipt is keyed on the root path and a review
  verdict on project plus tree, so two worktrees of one project never collide.
  The ledger was **not** safe and is now — `user-prompt`'s repo-derived fallback
  key exists for announce dedup, where a shared key costs one missed
  suggestion, and ledger data had been hung on it. No session id, no row.
- **A reviewer's isolation is checked; its independence is not.** `felix review
  --in <worktree>` refuses to record a *pass* that claims it ran in the tree
  under review, because a clean result from a tree being edited means nothing.
  A *block* is always recorded wherever it ran, or the check becomes a way to
  lose bad news. Independence remains unverifiable and the output says so.
- **`felix next` ranks the backlog, anchored on the objective.** Six commands
  reported upkeep, drift, setup gaps, evidence, coverage and retirement and
  none said which mattered. The order is: work Felix owes on the change in
  hand; an escape (the number the objective counts, never buried); a tool a
  route names and cannot reach (fixable only between sessions, since plugins
  bind at start); upkeep; checks that are not checking; routing. It ranks and
  does not act, and `next.sh` argues why rather than apologising.
- **Felix's own upkeep had never been able to fire.** `maintenance.tsv`'s third
  column takes `always` or a capability; Felix's used `-`, so all four routines
  were dormant from birth and `felix maintenance` printed "Nothing due" —
  identical to a well-kept repository. Found by `felix next` asking for due rows
  and getting none from a project with four overdue. Now **4 due**;
  `felix_maint_unreachable` guards it and the suite asserts no shipped row is
  unreachable.
- **Felix's own latency, measured 2026-08-13 and then halved.** `PreToolUse` is
  synchronous on every Bash/Edit/Write/Read/NotebookEdit/WebFetch call, so its
  cost is the session's cost. It was recorded at 34ms when it bound Bash alone;
  widening the matcher tripled the per-call cost to **105ms** and multiplied the
  calls paying it, and nobody re-measured because the handoff still said 34.
  Now **42ms** (Bash) / **37ms** (Read), by replacing process spawns with bash
  builtins — parameter expansion instead of a four-process sed pipeline,
  `[[ =~ ]]` instead of a grep per probe per rule, an upward walk for `.git`
  instead of `git rev-parse`, and an early exit when no row names the tool.
  **Re-measure whenever the matcher widens.** For scale: the full gate is
  **89s**, so a single verification run costs more than Felix does all session.
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

**Re-audited 2026-08-13 against the guide itself, every row re-run.** The guide
was decoded from the PDF rather than recalled; Phase 1 asks for Build: CLAUDE.md,
GitHub integration, PR workflow, tests, Sentry, Playwright, Strix, basic audit —
Exit: take an issue, create code, run tests, deploy preview, test it, open PR,
report confidence. The previous version of this table was hand-maintained and
wrong in nine places; do not edit a cell here without re-running its command.

| Promised | Status | Evidence, as of the audit |
|---|---|---|
| take an issue | **partial** | `felix brief` works on prose naming existing files, and tier now agrees with `classify` 19/19. Three defects fixed 2026-08-13: a path ending a sentence did not resolve; an unmatched path reported green; no risk.tsv reported green. Two remain: an issue asking for a file to be **created** silently drops it (`incident.sh` only emits paths that exist), and the `gh` body fetch has no `\|\| die`, so a rate limit renders as a confident "no file it names exists". **Zero issues have ever existed in either repo**, so the `<n>` path has never had real input. |
| create code | **supervised only** | All 547 Elenchus commits carry the founder's identity. `unattended.yml` has run 3 times, every one skipped in under a second because `FELIX_UNATTENDED` is unset. No model has written code here unattended. |
| run tests | **yes** | Elenchus `felix gate` → `1229 passed`, 32.8s. Felix → `577 passed`. |
| deploy preview | **yes, smallest honest version** | A `preview` job stands the real app up on :8123 against the scripted fake model. Verified in CI 2026-08-13: "preview answered after 3s". Not a deploy a stranger can reach; it is a real app on a real port over real HTTP. |
| test it | **yes** | `tests/test_preview.py`, marked `preview`, runs against that server in CI — **4 passed**, not skipped. Verified in all three states: skipped with no URL, FAILED against a dead port, passed against the real one. The two static suites no longer delegate their teeth to a manual habit. |
| open PR | **yes, opening only** | PR bodies, base, branch, tier label and `--draft`-unless-green all verified. **Merging: no.** See the correction in §2. |
| report confidence | **partial** | Fixed 2026-08-13: `scope` used a path-only reader and was blind to content rules, so a diff adding a credential to a `.md` printed "In scope … unattended attempt" while `classify` called it red. `scope` now classifies the diff, and says so when given bare paths. `classify` still exits 0 on red while `scope` exits 3. |
| DEFINITION OF DONE | **fixed 0.45.0** | A clean tree used to end the hook before the receipt was read, so committing your work — what you do at the end — skipped the check entirely. `UserPromptSubmit` now records the HEAD it first saw (SessionStart cannot: it never reads its payload), and Stop is silent on a clean tree only when the session also committed nothing. Unknown counts as unchanged, so a session with no mark behaves as before. |

Build list, re-checked: `CLAUDE.md` **on this Mac only** — gitignored, untracked,
absent from every clone including the CI runner that `unattended.yml` hands to
`claude -p`. GitHub integration **partial** — `gh` and Actions real, the MCP
returns HTTP 400 and `felix setup` already says so. PR workflow yes on Elenchus,
0 PRs ever on Felix. tests yes. Sentry **absent**, capability undeclared.
Playwright installed and routed, **0 browser tests**. **Strix does not exist** —
0 of 286 marketplace entries. basic audit **partial**: three gate checks are
real and semgrep is wired into nothing.

**Corrected 2026-08-13.** This row also said `secret-scan`'s exclusions apply to
the whole line, so a real key beside the word "example" exits 0. That was fixed
before the line was written and the line was never re-run. Re-checked by feeding
the scanner four cases: an AWS-shaped access key assigned to a variable on a
line whose trailing comment says "example config" exits 1; a private key header
wrapped in `<pre>` exits 1; a password assigned an angle-bracket placeholder
exits 0; and AWS's own documentation key exits 0, because there the exclusion
token sits inside the credential rather than beside it. Context exclusions read
whole-line and value exclusions read the matched credential, which is what the
lesson in `lessons.md` already described.

Written out longhand rather than quoted, because quoting the first case is what
a scanner reading added lines is for: the first draft of this paragraph pasted
the literal and the gate stopped the commit. Correct behaviour, and the cheapest
possible demonstration that this row is now true.

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

Everything that used to be above this is done. One item is left, and it is not
one anybody can sit down and build.

1. **Auto-merge and the unattended switch.** Elenchus is 1 of 5, Felix 0 of 5.
   Both unlock on five consecutive green merges, and maintenance will not
   produce them: a well-kept repository yields about one real PR from a full
   sweep of due routines, measured rather than guessed. They come from real
   feature work, so this advances as a side effect of building things.

**Closed 2026-08-13 — and the entry was wrong.** "Convert the pure recommenders:
`doctor`, `handoff`, `promote`, `recommend`, `which`" misfiled three of five.
`handoff` already writes `SESSION_HANDOFF.md`. `which` is a query with nothing
to do. `recommend` deliberately installs nothing and the suite asserts it, which
was a decision. `doctor` already acts through `--fix`. Only `promote` was pure:
it computed that the gate had caught the same check eight times and then asked a
person to type `felix lesson`. It is now rank 5 of `felix next`, carrying the
distinction it always printed and never acted on — a recurrence with no lesson
needs one written, and a recurrence that already has one means the lesson is not
working and the fix belongs where the gate can see it.

### Explicitly not next, with reasons

- **Playwright.** Assessed 2026-08-11 and declined; see section 4b. Revisit for
  browser behaviour the HTTP tests cannot reach, not to tick a criterion.
- **Deploy, smoke tests, telemetry.** Three empty boxes in the guidebook loop
  that are product-stage facts rather than Felix gaps. Elenchus has no deploy
  target, so there is nothing to wire.

## 6. Open decisions

- **Strix: wired, skipping, and deliberately unfunded. Decided 2026-08-13.**
  No Strix account is needed — verified against `docs.strix.ai` and the source,
  not a blog: the prerequisites are Docker and an LLM API key, Apache 2.0, no
  registration. So there is no signup to do, ever. The `pentest` job exists in
  Elenchus's gate.yml, is `continue-on-error`, and **skips entirely until
  `LLM_API_KEY` is set**, which is the state it should stay in for now.
  *Why not yet:* Elenchus has no deploy manifest, binds `127.0.0.1` everywhere,
  has no auth module and declares `consumers: none`. There is nothing reachable
  to attack, so findings would describe a threat model that does not exist.
  *Trigger to revisit:* a real deploy target.
  *Which provider is genuinely undecided, and the evidence does not settle it.*
  There is no published head-to-head; the one benchmark (XBEN, 96%) used
  `gemini-3-pro-preview`, and the README recommends OpenAI, Anthropic and
  Google equally. So choose on billing separation rather than capability, and
  prefer a pool that is NOT the Anthropic key the product and `unattended.yml`
  already share — commingled spend cannot be attributed, which is the same
  confounding this project spent a session removing from the ledger.
  *Cheapest first step, when curious:* one manual laptop run against the smoke
  server with `--max-budget 5`. `--max-budget` is a hard cumulative cap across
  every agent, so "activate or save the credit" was never binary. Note the
  upstream default scan mode is **deep, 1-4 hours** — always pass `--scan-mode
  quick` explicitly. `STRIX_TELEMETRY` is opt-out and already set to 0.

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
  Felix is **still 0 of 5 after merging its first pull request ever**, and that
  is the counter working rather than failing: the streak counts *green* merges,
  PR #1 was `risk-red`, and Felix's own `risk.tsv` calls anything under
  `engine/harness/lib` red by construction. **So engine work on Felix can never
  advance this number.** It will move on template, per-project and documentation
  changes, or not at all. Worth deciding whether that is the intended reading —
  the unlock exists to test whether a green classification is trustworthy, and
  a repository that rarely produces green changes never gathers that evidence.
  The five risk labels now exist on the repo; `felix pr` could not apply one
  before today because none had ever been created.
- **GitHub MCP is broken, not missing.** `plugin:github:github` returns
  `HTTP 400: Authorization header is badly formatted`. It was authenticated once
  and the credential is now malformed. Needs an interactive session.
- **`scripts/prepush.sh` in Elenchus** is an untracked copy of a file Felix
  holds, identical today and free to drift. `felix doctor` reports it. The stale
  `scripts/gate.sh` beside it was deleted 2026-08-10 after it caused a session
  to report green from a gate missing the `secret` check.
- **`routes.log` pollution: closed 2026-08-13, and "new rows are clean" was
  false when it was written.** The envelope fix went into `felix_route_tokens`
  and never into `felix_route_log`, which stripped the runtime's pairs but not
  the JSON keys — so every miss recorded the literal words `prompt` and
  `prompt_id`, and they were rows one and two of `felix route --promote`, above
  every word anybody had typed. The row from the session that found this still
  had them. Both now go through one `_felix_envelope_text`, applied on write and
  again on read, so rows already on disk clean up without truncating anything.
  Top misses after: `felix` 9, `continue` 7, `session` 5, `merge` 4.
  `merge` was the only one naming a kind of work and now has a `ship` route.

- **Three mounted plugins cannot be reached by any keyword, and `felix next`
  gives the wrong advice about them.** `code-simplifier`, `security-guidance`
  and `claude-plugins-official` show in the ledger as mounted-and-never-named,
  and rank 6 says to fix the keywords in `routes.tsv`. No keyword can reach
  them: they are among the 29 installed plugins matching no capability Felix
  declares, so `felix toolbox` does not list them and no route may name them.
  The fix is `felix adopt`, not a keyword — and whether those capabilities are
  worth declaring is a real question, not a typo. Not done here.

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
