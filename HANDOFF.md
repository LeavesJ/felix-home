# Handoff

Rewritten 2026-08-10. The previous version was a Phase 1 verification dated
2026-08-09 and several of its rows have since stopped being true. Every row
below was checked by running something today, not by reading code.

For the mechanical state of the tree — branch, head, uncommitted, recent
commits — see `projects/felix/memory/SESSION_HANDOFF.md`, which `felix handoff`
regenerates. This file is for the things a command cannot tell you.

## Direction, corrected 2026-08-10

Read this before the tables below. They measure progress against a charter that
was wrong, so a row can be green and still be pointed the wrong way.

**The split.** The founder owns *what* gets built: thesis, vision,
prioritisation, pitching, and approval at the risk boundaries. Felix owns *how*
it gets built, optimally — which MCP, which plugin, which skill, which agent,
in which order, in one context or several — and the whole loop around that
choice. If the founder is thinking about tooling, Felix has failed.

**The drift.** Felix's constitution opened with "the governance layer" and Felix
built exactly that. It has a complete vocabulary for saying no — gate, classify,
evidence, quarantine, guard, scope — and had none for saying "do this next".
Against the guidebook's loop (p2), six of fourteen boxes are strong and the one
at the centre, *plan / route / dispatch subagents*, is a third built with that
third only printing advice. The p2 ownership table gives the OS "implementation
planning and execution"; Felix owned none of it. The charter has been rewritten;
see `projects/felix/CLAUDE.md`.

**Scope.** Phase 1 engineering only. Revenue, customer and company are later
phases owned by other systems. Stripe rows in the templates are dormant
capabilities, not a direction.

**What the monitor is for.** Witnessing Felix guide Claude Code, so the founder
can stop caring about the things it handles. It currently shows records —
routes defined, verdicts, what Felix said — and never shows whether Claude did
what Felix named. The compliance signal already exists in `felix_route_due`,
which reads the transcript to see whether a play step was used. Nothing
surfaces it. That panel is the one that proves the delegation works.

**Why Felix guides instead of acting.** Not a limit of Claude Code. Felix wires
3 of the 9 available hooks — `SessionStart`, `UserPromptSubmit`, `Stop` — and
all three only inject text. `PreToolUse`, the one hook that can deny an action
before it happens, has never been wired. Neither has `PostToolUse`, which is
where live tracking and the capability ledger were both specced to record.
Guidance was a consequence of the old charter, not of the platform.

**Next, in leverage order.**

0. Wire `PreToolUse`. It is the difference between a harness that advises and
   one that enforces: deny an edit to a red path without approval, deny a push
   to main, deny running a rival gate. Adversarial tier — it runs before every
   tool call in every governed session, and a mistake denies everything.
0b. Wire `PostToolUse` and `SessionEnd`. Live tracking, and the capability
   ledger that has been specced since 2026-08-09 and blocked on nothing else.
0c. Amend invariant 4 so Felix installs low-risk tooling itself. Today
   `felix discover` refuses outright: "there is no --yes". The end state has
   Felix recommending *and installing* what a project needs. Keep the refusal
   for anything touching credentials or irreversible writes; that is the
   autonomy ladder (p20) applied to tooling.
1. `felix route` upgraded from naming to deciding: tools, execution shape, tier
   and evidence up front, order, and the configuration the next session boots
   with. Mounting cannot happen mid-session; writing config between sessions can.
2. Execution shape. Coupling computed mechanically from shared files, which is a
   refusal and binds. A model may narrow it and may never widen it.
3. Convert the pure recommenders: `doctor`, `handoff`, `promote`, `recommend`
   and `which` print and bind nothing.
4. `felix next` for the engineering backlog Felix already tracks — maintenance,
   drift, setup gaps, evidence gaps. Not for product work: that is the founder's.
5. The issue-to-PR verbs, specced and planned in `docs/2026-08-10-issue-pr-loop-plan.md`.
   No longer a standalone feature; it is the loop's *branch + PR* box.

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
- **Felix's own red tier — decided 2026-08-10: honoured by behaviour, not
  enforced.** Changes to `engine/harness/lib` and the hooks classify red here.
  Felix cannot enforce that on itself: `gh api repos/LeavesJ/felix/rulesets`
  returns 403, "Upgrade to GitHub Pro or make this repository public", so both
  branch protection and rulesets are unavailable on a private free repository.
  Elenchus gets real enforcement only because it is public.

  The decision was to behave as if the rule applied — branch, classify, founder
  approval before merge — and to state the gap here rather than leave it looking
  like an oversight. **Nothing mechanically stops a bypass.** The rival-gate
  change went through that flow: classified red, approval asked and given,
  merged, deployed, gate green afterwards.

  A second obstacle is worth naming because it is not a plan limit. `felix gate`
  runs an `installed` check comparing the tree against the deployed plugin cache,
  so on any engine-changing branch the local gate is red until the branch is
  deployed — and deploying is the red-tier act that needs approval first. CI
  skips the check when no plugin is installed, so a pull request can still go
  green; only the local gate is affected. It is a plausible reason engine work
  has always gone straight to `main`.

## Buildable now

1. **Playwright e2e tests** — the plugin is installed, the web surface exists,
   and the count is still zero.
2. **Issue intake** — `gh` is authenticated and can read issues. An issue could
   become a branch, a brief and a PR through the same gate and classifier.
3. **The capability ledger** — specced, deliberately unbuilt. It measures which
   capabilities earn their place, and there was nothing to measure. There is
   now: 29 routing decisions and 21 verdicts.

## Still unproven

~~The router has never run against a real session.~~ **Stale as of 2026-08-10.**
It has: `routes.log` carries decisions from real Elenchus and Felix worktree
sessions, and they scored 2 — weak matches — with one prompt scoring 0 and
matching nothing at all. The table was thin: nine routes naming eight tools
against fifty-five installed plugins, so `dispatching-parallel-agents` was
unreachable and an attached PDF never reached the `pdf` skill. Four rows were
added to each project and verified by routing real sentences through them.

`felix route --promote` still cannot help, for a different reason than assumed:
it reads the raw JSON envelope. `felix_route_log` stores the prompt verbatim, so
every miss carries `session_id`, `transcript_path` and every component of the
transcript path, and `--promote` ranks `users`, `claude` and `a14808` above
anything a person typed. The scoring path was fixed for this; the write path was
not. The pollution is already on disk. The same caveat the last handoff made about `risk.tsv` applies to
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
