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

## 2. State as of 2026-08-10

- Engine **0.14.1**, deployed and verified (`felix install` → "verified the
  installed engine matches this tree").
- `felix gate` → **pass**. **334 assertions**, 0 failed.
- `main` is **well ahead of `origin/main` and unpushed**. Pushing triggers CI.
- Felix wires **4 of 9 hooks**: `SessionStart`, `UserPromptSubmit`, `Stop`, and
  as of today `PreToolUse`.

### What Felix can do today

Resolve which project governs a checkout; run and record a gate; classify a diff
into green/yellow/red; say what evidence a change owes; route a prompt to a play
and name the tool that is due; detect undeclared capabilities; detect a rival
gate; refuse a Bash command; report maintenance, setup gaps, budget, auto-merge
readiness and unattended readiness; write handoffs, lessons and devlog entries;
render the monitor.

### What Felix cannot do

Mount an MCP server or enable a plugin mid-session — that needs a restart, so
tooling decisions must be written as configuration between sessions. Read a
GitHub issue. Open a pull request. Deploy anything. Plan work. Dispatch
subagents. Decide execution shape. Install tooling (a self-imposed refusal, due
to be lifted — see §5).

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
| take an issue | **no** | nothing reads an issue; planned in `docs/2026-08-10-issue-pr-loop-plan.md` |
| create code | yes | |
| run tests | yes | `felix gate` → pass; 334 in Felix |
| deploy preview | **no** | no deploy target, no catalogue row keyed on `deploy` |
| test it | **partial** | still 0 files matching `e2e\|playwright` in Elenchus |
| open PR | **no** | Felix labels and merges; there is no `gh pr create` |
| report confidence | yes | `felix classify`, `felix evidence` |

Build list: `CLAUDE.md` yes; GitHub integration yes; PR workflow yes; tests yes;
Sentry dormant (capability undeclared for Elenchus, so it is deferred rather
than missing); Playwright installed with 0 tests; **Strix does not exist** — 0
of 273 marketplace entries, no binary, no skill, so semgrep plus
`engine/harness/bin/secret-scan` fills that slot; basic audit yes and real.

---

## 5. Next, in leverage order

1. **`PostToolUse` and `SessionEnd`.** Unblocks live tracking and the capability
   ledger, specced in `docs/2026-08-09-capability-ledger-design.md` since
   2026-08-09 and blocked on nothing else. The deny hook established the
   contract and the fail-open discipline, so this is smaller than it looks.
   Note the ledger spec contradicts itself: the body argues transcript parsing
   breaks the bash-and-git invariant and inverts to `PostToolUse` recording, and
   its `## Records` section still says a `SessionEnd` hook parses the
   transcript. Resolve that first.
2. **Close the adoption loop into `routes.tsv`.** *Done 2026-08-10:* installing
   works. `felix discover --adopt` declares low-risk candidates into `stack.tsv`
   and installs them through the existing path; it ran live against Elenchus and
   adopted `deepeval`, `langfuse` and `togetherai-skills` while refusing `figma`
   (medium) and two high ones. `felix stack apply --yes` had always been able to
   install *declared* tooling, so the real gap was discovered-to-declared, not
   installation.

   **What is left is the half that matters.** No route names any of the three.
   They sit among the 46 installed-but-never-reached-for, so no session is ever
   told to use them while their skills cost context in every session — which is
   precisely the signal the ledger design calls the retire condition. Adoption
   must also reach `routes.tsv`: a candidate carries the capability it matched,
   `profiles.tsv` maps profiles to capabilities, so the route whose profile
   covers that capability is the one whose play should gain the tool. Until
   that exists, `--adopt` makes a project's toolbox bigger and no more useful.
3. **`felix route` from naming to deciding**: tools, execution shape, tier and
   evidence up front, order, and the configuration the next session boots with.
   Better once the ledger exists, since choosing tools is far better informed by
   knowing which ones actually got used.
4. **Execution shape.** *Done 2026-08-11:* `felix shape <plan>` computes
   connected components over the `Files:` blocks `writing-plans` mandates and
   reproduces, mechanically, the split that had been made by taste — tasks 1–4
   of the issue-to-PR plan share files, task 5 does not. The refusal half binds;
   the permission half is stated as necessary-not-sufficient, because a caller
   and the signature it consumes share no file at all.

   What is left: nothing consults it. `felix route` still names tools without
   reference to shape, and no hook mentions it. A model may narrow a "separable"
   and may never widen a "one context".
5. **Convert the pure recommenders.** `doctor`, `handoff`, `promote`,
   `recommend` and `which` print and bind nothing.
6. **`felix next`** for the engineering backlog Felix already tracks —
   maintenance, drift, setup gaps, evidence gaps. Not for product work; that is
   the founder's.
7. **The issue-to-PR verbs.** Spec `docs/2026-08-10-phase1-gaps-design.md`, plan
   `docs/2026-08-10-issue-pr-loop-plan.md`, both written and self-reviewed. It
   is the loop's *branch + PR* box, not a standalone feature.
8. **Monitor: the compliance panel**, plus making archive sessions clickable.
   `monitor.html` already groups by session (`liveSession`, `sessionSays`,
   `pastSays`), so it is a rendering change. It cannot show the transcript:
   parsing JSONL breaks the invariant and a `file://` page cannot fetch a
   sibling. Show Felix's own record plus `claude --resume <id>`.

---

## 6. Open decisions

- **Unattended repair.** Wired and off. `gh variable set FELIX_UNATTENDED --body
  true --repo LeavesJ/Elenchus`. Felix will not flip it: the evidence that would
  justify it cannot be gathered without spending it, so the first real run wants
  someone watching.
- **Auto-merge.** 0 of 5 on both repos. Elenchus has exactly two merged pull
  requests ever, #1 unlabelled and #3 `risk-red`. It unlocks itself after five
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
  what causes it to be used. Only *absence* of use given presence is
  unconfounded. See the ledger design.
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
