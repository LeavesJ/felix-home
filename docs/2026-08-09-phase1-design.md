# Felix, Phase 1

Design record, 2026-08-09. Written after the work rather than before it, because
implementation ran ahead of the spec at the founder's direction. It records what
was decided and why, and separates what was verified from what was assumed.

Source: `founder_autonomous_engineering_os_v2_expanded.pdf`, 43 pages. v1.1
baseline (p1-17) plus a v2.0 Claude-centric expansion (p18-43).

## The problem, as found

The guidebook proposes an engineering OS whose premise is one sentence on p37:
**data can inform Claude; data cannot grant Claude authority.** Everything else
is machinery for making that structurally true rather than merely instructed.

Elenchus turned out to be ahead of the guidebook on doctrine and behind it on
enforcement. Its `CLAUDE.md` is a better constitution than the sample on p30: it
has risk tiers, ten invariants, an abstraction-police section, and delivery
rules. What it did not have was anything able to enforce them.

Verified at the start of the work:

* `.claude/CLAUDE.md`, `scripts/gate.sh`, `scripts/prepush.sh`,
  `docs/lessons.md`, `docs/DEVLOG.md`, `docs/SESSION_HANDOFF.md` were all
  untracked. 182 tracked files, none of them doctrine.
* No CI. No `.github/` directory at all.
* The gate was unreachable from the worktrees doctrine mandates working in. The
  constitution instructed every tier to run `./scripts/gate.sh` from a directory
  that did not contain it.
* Six copies of the constitution existed across main and five worktrees, five of
  them already diverged from the sixth.

So the constitution, the memory, and the enforcement all lived on one laptop,
outside version control. Nothing survived the machine, no CI could read the
rules, and the only thing that could reject a change was a human choosing to
check.

## Decision 1: a separate private repo

Three constraints collided. Doctrine must be tracked to be durable and
CI-enforceable. The Elenchus repo is public. The doctrine is the asset: its own
first line says the durable value is the loop, the gates, and the owned context.

Tracking doctrine in Elenchus would publish the moat. Leaving it untracked kept
it mortal. So governance moved to a private repo, `LeavesJ/felix`, and the public
repo gained exactly one file: `.github/workflows/gate.yml`.

The split is product versus governance, not public versus private-by-audience.
Elenchus remains where Elenchus is built.

**Rejected:** tracking doctrine publicly (publishes the moat); a git submodule
(`.gitmodules` leaks the private repo's existence and breaks clones for anyone
else); vendoring the gate into the public repo (the gate's own header says its
checks are encoded lessons, so it is doctrine too).

## Decision 2: generic before a second project existed

This one overrode the founder's own rule. `CLAUDE.md` §2 says no registry with
one entry, and rule of three. Building a portable harness while exactly one
project consumed it is what that rule exists to prevent.

An early justification that Retnovation was the second caller was wrong:
verified, it has the same remote and the same HEAD as Elenchus. It is a second
checkout.

The override was taken on explicit instruction, twice, and is recorded here as
§2 requires. What makes it defensible is that durability justified the repo
independently of portability, and keeping `harness/` free of project facts is a
discipline rather than a layer. Nothing was built to serve a hypothetical second
project except the templates, whose value was demonstrated by onboarding a real
stranger project in a test.

## Decision 3: earned autonomy, not granted

The guidebook's final principle (p21) is a ladder: observe, recommend, act in
sandbox, act reversibly, act with approval, act autonomously within policy.

Phase 1 sits at "act with approval". Claude implements, runs the gate, pushes
branches, and opens PRs. CI re-runs the gate independently. A human merges.
Auto-merge was deliberately not enabled, because granting it on day one skips
rungs the guidebook wants climbed and no CI had ever run on this repo before.

## Architecture

```
harness/            the engine. names no project, assumes no language
  felix             CLI: which, gate, doctor, profile, stack, setup, repair, adopt, new
  lib/resolve.sh    project resolution, shared by CLI and hook
  lib/detect.sh     capability probes and gate guessing
  lib/stack.sh      desired-state diff and provisioning
  lib/setup.sh      human steps and their proofs
  lib/repair.sh     CI failure retrieval and the attempt ceiling
  hooks/            SessionStart binding
  templates/        catalogue, profiles, and runbooks for onboarding
  tests/run         54 assertions
projects/
  elenchus/         doctrine, gate, memory, stack, setup runbooks
```

Dependencies are bash and git. Felix governs projects in languages it must not
require, so it does not drag a runtime along. That is why `project.json` is read
with `sed` rather than `jq`, and the limits of that reader are stated in the
source.

### Resolution

A `.felix` marker file wins; a git remote match is the fallback. The marker is
what makes Felix work on a repo with no remote, a fork, a rename, or code we do
not own. Remote matching is convenience, not the contract.

### The gate

A shell command declared per project, so Felix can gate an ecosystem it has never
heard of: `npm run verify`, `cargo test`, `dotnet test`, `make check`. It always
runs from the checkout being gated, never from Felix, because a gate that
inspects the tree it lives in returns a verdict about the wrong code.

### Capability detection

Probes the checkout for surfaces (ci, deploy, iac, observability, billing, e2e,
database, api, frontend, tests, secrets) and reports what exists but has not been
declared. Detection reports and never enables. A gate that switched itself on
would block a pull request for a reason nobody chose.

### Stack provisioning

A project declares its marketplaces, plugins, MCP servers, and skills. Felix
diffs against what is installed and classifies each row present, install,
dormant, manual, or blocked.

Risk tiers carry the safety property: low and medium apply unattended with
`--yes`; **high never applies, at any flag, from any caller**, because high means
the tool can reach production, move money, or hold a credential. That is a test,
not a promise.

The human decision did not disappear, it moved earlier. You approve the policy
once, in a file reviewed and committed in git, and automation executes inside it.

### Human setup

Some things an agent should not do: create accounts, complete a consent screen,
hold a live key. The failure mode worth designing against is not that Felix
cannot do them, it is that nobody wrote down what to do instead. Each step
carries a check that proves whether it is done, so the list is derived rather
than maintained.

### Repair

Felix supplies scaffolding and refuses to supply judgment: fetch the failure,
trim the log, count attempts, enforce the ceiling. Diagnosis is the agent's job.
Attempts are counted from CI history rather than a local counter, because a
counter that resets when the agent restarts cannot bound anything. Past three,
the answer stops being retry and becomes escalate.

## Guidebook coverage

| Section | Status |
|---|---|
| v1.1 §1 session bootstrap, capability profiles | done |
| v1.1 §2 repo memory hierarchy | done |
| v1.1 §3 MCP / plugin / skill management | done |
| v1.1 §4 subagent organization | partial: agents not yet defined |
| v1.1 §5 deterministic verification | done |
| v1.1 §6 PR, repair, merge loop | done except auto-merge, deliberately |
| v1.1 §7 production telemetry | dormant: nothing deployed |
| v1.1 §8 scheduled maintenance | not started |
| v1.1 §9 risk boundaries, permissions | done |
| v1.1 §10 Stripe revenue layer | dormant: pre-revenue |
| v2.0 Part I autonomy ladder | done, as a promotion criterion |
| v2.0 Part II tool gateway, brokers | deferred: no vendor APIs to gate |
| v2.0 Part III constitution, MCP registry | done |
| v2.0 Part IV cloud, Stripe, voice, multi-model | dormant |
| v2.0 Part V prompt injection, Strix | partial: gate has confidential and ignore-leak checks |
| v2.0 Part VI model broker, evals, credits | deferred |

Dormant differs from deferred. Dormant items have no surface in this project yet
and will surface automatically when `felix doctor` sees one. Deferred items were
judged premature: a Tool Gateway today would be a registry with zero entries.

## Verification

Claims here were executed, not reasoned about.

* The gate runs from a worktree holding no `gate.sh`, gates that worktree rather
  than main, and passes: format, lint, confidential, lift-bank, ignore-leak,
  inversion, 1229 tests.
* CI green on PR #1 in 1m8s, 1225 tests.
* CI **red** on a deliberate `F821`: `lint FAIL`, `gate: FAIL (lint)`, exit 1. A
  gate that has only ever passed is decorative, so it was made to fail on
  purpose and then the branch was deleted.
* `--yes` installed four low-risk plugins and refused the high-risk GitHub row.
  Confirmed afterwards by an independent `claude plugin list`.
* A stranger Node project with no git remote was onboarded end to end:
  capabilities detected from its manifest, gate guessed as `npm run verify`,
  15 files seeded, gate observed passing and failing.
* 54 harness assertions, all executed against a throwaway Felix root governing an
  invented project. The suite never touches Elenchus.

Two bugs were found by these tests rather than by review. `resolve_or_die`
printed its result, forcing callers into a command substitution where `exit`
kills only the subshell, so an ungoverned directory sailed past a failed
resolution and died later with the wrong status. And the session hook keyed its
output shape off `CLAUDE_PLUGIN_ROOT`, which only the plugin install path sets;
as a settings hook it ran, exited 0, and injected nothing.

**Assumed, not verified:** CI runs 1225 tests against 1229 locally. The four are
almost certainly `tests/test_content_loader.py` reading the gitignored lift
banks, which exist locally and not on a fresh clone. Inferred from the file list;
not confirmed by re-running CI with skip reasons.

## Open

* Subagent definitions (§4).
* Scheduled maintenance routines (§8).
* Auto-merge for T0, once the promotion criterion is met.
* `ANTHROPIC_API_KEY` as a repo secret, which is the switch to unattended
  autonomy and the only outstanding item with an ongoing cost.
* A recommender bridge that drafts `stack.tsv` from an unfamiliar codebase. The
  template path covers the common case; this would cover the rest.
