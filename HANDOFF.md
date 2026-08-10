# Handoff — Phase 1 verification

Temporary. Delete once the open decisions are made.

Verified 2026-08-09 against `founder_autonomous_engineering_os_v2_expanded.pdf`.
The attached copy extracts byte-identical to the one this work was built from, so
these are the same promises. Every row below was checked by running something,
not by reading code.

## Exit criteria (guidebook p41)

| Promised | Status | Evidence |
|---|---|---|
| take an issue | **no** | only `gh issue create` exists, for incidents. Nothing reads an issue and starts work |
| create code | yes | |
| run tests | yes | `felix gate` → `gate: pass`; 1229 local, 1225 CI |
| deploy preview | **no** | no Dockerfile/Procfile/fly/vercel; no deploy capability in the harness |
| test it | partial | gate plus `tests/test_web_api.py`; **0 committed e2e tests** |
| open PR | yes | PRs #1, #2, #3; one deliberately failed, two merged |
| report confidence | yes | `classify` → `tier: red`; `evidence` → `No evidence gaps` |

Four met, one partial, two not.

## Build list (guidebook p41)

| Promised | Status |
|---|---|
| CLAUDE.md | yes, tracked, 10,549 bytes |
| GitHub integration | yes, `main` protected, `gate` required |
| PR workflow | yes |
| tests | yes, Felix 185/185, Elenchus 1229 |
| Sentry | **no**, declared in `stack.tsv`, 0 mounted, runbook only |
| Playwright | partial, plugin installed, 0 e2e tests |
| Strix | **not built**, not referenced anywhere |
| basic audit | partial: maintenance, mistakes and budget logs; no per-action trail |

## The one promise that cannot be met as written

p3: *"Plugins and MCPs can remain installed. The router decides what becomes
active for a task."*

Felix automates provisioning. It does not mount or unmount per task, and cannot:
Claude Code has no runtime API for it. `felix profile` reports what should be
active and prints "Everything else stays unmounted", which is advisory. A router
claiming otherwise would be theatre.

This is a gap against the literal promise, not a design preference.

## Why three of the gaps are blocked rather than skipped

Sentry, deploy preview, and Strix all need a deployed product. Elenchus has none.
`felix doctor` surfaces `deploy` and `observability` automatically the day a
Dockerfile or a Sentry dependency appears, and `felix adopt` backfills the
tooling and human steps they imply. Nothing needs remembering.

## Buildable now

1. **Playwright e2e tests** — the plugin is installed and the web surface exists
   at `src/elenchus/web/`. Nothing is stopping this.
2. **Issue intake** — `gh` is authenticated and can read issues. An issue could
   become a branch, a brief, and a PR through the same gate, classifier and
   evidence policy as any other change.

## Defect found during this verification

The lessons hook was written, passed its tests, and was **absent from the plugin
cache**. It ran nowhere. Every test passed, the repository was correct, and the
behaviour did not exist on this machine.

Fixed, and the class is fixed: Felix's gate now compares the installed engine
against the repository and fails on drift. Verified red by editing a library file
without reinstalling.

Same shape as the earlier breakage where moving the engine broke Elenchus's CI.
Both were changes whose callers lived outside the tree the suite examines. The
suite tests the code; only the gate can test the deployment.

## Open decisions

- **Unattended switch.** `gh variable set FELIX_UNATTENDED --body true --repo LeavesJ/Elenchus`.
  Everything else is ready: key set, scope bound, budget ceiling, guards
  exercised. `felix unattended` reports readiness and will not flip it.
- **Auto-merge.** `felix automerge` reads 0 of 5. Unlocks itself once five
  consecutive green PRs merge without CI disagreeing. Nothing to do but merge.

## Still unproven

The risk rules have judged two workflow changes and got both right. That is the
easy case: `.github/workflows/` is an obvious red. Whether `green` is trustworthy
is unanswered, and only ordinary PRs answer it. `felix scope` and `felix classify`
are exactly as good as `risk.tsv`, which was written in one sitting.
