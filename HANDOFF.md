# Handoff

Rewritten 2026-08-10. The previous version was a Phase 1 verification dated
2026-08-09 and several of its rows have since stopped being true. Every row
below was checked by running something today, not by reading code.

For the mechanical state of the tree — branch, head, uncommitted, recent
commits — see `projects/felix/memory/SESSION_HANDOFF.md`, which `felix handoff`
regenerates. This file is for the things a command cannot tell you.

## Exit criteria (guidebook p41)

| Promised | Status | Evidence |
|---|---|---|
| take an issue | **no** | nothing reads an issue; only `gh issue create`, for incidents |
| create code | yes | |
| run tests | yes | `felix gate` → `gate: pass`; 293 in Felix, 1229 in Elenchus |
| deploy preview | **no** | no deploy target in the repo, and no catalogue row keyed on `deploy` |
| test it | partial | 0 files matching `e2e\|playwright` in Elenchus |
| open PR | **Felix does not** | it labels and merges existing ones; there is no `gh pr create` |
| report confidence | yes | `felix classify`, `felix evidence` |

Four met, one partial, two not. Unchanged from yesterday except that "open PR"
is now stated accurately: Felix never opened one.

## Build list (guidebook p41)

| Promised | Status |
|---|---|
| CLAUDE.md | yes |
| GitHub integration | yes, `main` protected, `gate` required |
| PR workflow | yes |
| tests | yes |
| Sentry | **no**, declared in `stack.tsv`, absent from `claude mcp list` |
| Playwright | plugin installed, still 0 e2e tests |
| Strix | **does not exist as a plugin**: 0 of 273 marketplace entries, no binary, no skill |
| basic audit | **yes, and real now** — see below |

## What changed since the last handoff

**The p3 router promise is largely met.** The previous handoff said it could not
be, because "Claude Code has no runtime API for it." That was too strong. A
skill from an enabled plugin *is* invokable mid-turn, which is exactly how the
router works: it names the one tool that is due, and names the next only once
the transcript shows the first was used. What genuinely cannot change
mid-session is connecting an MCP server and switching on a plugin that is off.

**The completion gate exists.** p7's rule — never declare a task complete while
a deterministic verification step is failing — was doctrine and is now a `Stop`
hook. It decides on tree state, compares a receipt rather than re-running, and
blocks once per chain, which is a speed bump with a permanent record rather
than a barrier. The barrier is still CI.

**There is a per-action audit trail.** 21 gate verdicts and 29 routing decisions
recorded so far, plus mistakes and maintenance, all tracked in git. Verification
has no native record anywhere in Claude Code; this is the only place it exists.

**Felix governs Felix.** It had no `risk.tsv`, no `evidence.tsv` and no
`maintenance.tsv` — the three things it demanded of every project it governed.
It has them now, and the first thing they said was that its own recent work
classifies `red`.

**Felix can see the whole toolbox.** It could see 14 plugins; there are 30. The
ones bundled into the Claude Code binary appear in no plugin list and no
on-disk registry, and their skills are live in every session.

**Discovery exists.** `felix discover --inspect` fetches a candidate at its
pinned sha and reads what it ships before recommending it, because
`claude plugin validate` checks schema only and the plugin format has no
permission model at all.

## Open decisions

- **Unattended switch.** Still off. `gh variable set FELIX_UNATTENDED --body true
  --repo LeavesJ/Elenchus`. Everything else is ready; `felix unattended` reports
  readiness and will not flip it.
- **Auto-merge.** `felix automerge` reads 0 of 5. Unlocks itself once five
  consecutive green pull requests merge without CI disagreeing.
- **Felix's own red tier.** Now that `risk.tsv` exists here, changes to
  `engine/harness/lib` and the hooks classify red. Recent work merged to `main`
  without the approval gate Felix enforces elsewhere. Either honour it or say
  plainly that Felix exempts itself.

## Buildable now

1. **Playwright e2e tests** — the plugin is installed, the web surface exists,
   and the count is still zero.
2. **Issue intake** — `gh` is authenticated and can read issues. An issue could
   become a branch, a brief and a PR through the same gate and classifier.
3. **The capability ledger** — specced, deliberately unbuilt. It measures which
   capabilities earn their place, and there was nothing to measure. There is
   now: 29 routing decisions and 21 verdicts.

## Still unproven

The router has never run against a real session that nobody was watching. Every
routing decision in the log so far was produced by a verification run, not by
work. `felix route --promote` cannot help until real prompts have missed the
table. The same caveat the last handoff made about `risk.tsv` applies to
`routes.tsv`: it was written in one sitting and is exactly as good as that.

## The failure mode this project keeps having

Three times now, correct and tested code did nothing because of where it was or
was not installed: a hook absent from the plugin cache, an engine that never
deployed because its version had not changed, and a receipt written inside the
tree it described. Each was found by running the deployed thing against a real
repository, never by the suite.

A fourth variant appeared today: a fix explained in a commit message rather than
in `lessons.md`, and therefore repeated within the day. The lesson mounts; the
commit message does not.
