### 0bv. 2026-09-23 (night) — overnight mode belongs to a session, #307 and #303 landed, the runner probe answered from a runner's own log, Veldra's blind request

**Deployed from this session: engine 0.49.156 (#307) and 0.49.157 (#303)**, each
from the home checkout, where `felix install` verified the installed engine
against the tree. The engine queue ran #301, #313 (the deny floor fix), #306,
the linear deny payload read (which landed out of the agreed order and took
.155), #307, then #303, which this session carried because its owner had
closed. **#304 was deliberately not merged**: its own description asks to land
after the founder's Elenchus admission, because it stales every receipt and
all 22 open candidates once. It is in `felix overnight --report`'s queue with
the exact unblock steps.

| PR | What | Engine |
|---|---|---|
| #307 | Overnight mode: a night per session, carried through the platform's chain on its own bounds, quiet read from the transcript, a clean tree no longer ends the night; `lib/overnight-stop.sh` is new. An adversarial review found one high defect (a session could re-grant itself from inside the chain), one medium and five low, plus three assertions that could not fail. All were fixed in the second commit, and each fixed assertion is shown failing under a mutation that removes its fix | 0.49.156, deployed |
| #303 | The repair ceiling and the auto-merge streak read the gate workflow alone (another session's work, carried to merge: main merged in, manifest merged mechanically, red re-run) | 0.49.157, deployed |
| #310 | Phase 1 item 1, draft: `obligations.tsv` gains an optional `needs` column, each capability resolved against `qualification.tsv` as complete, short or absent; report-only. Built by a subagent in its own worktree from a design fixed first; its mini suite reaches 41, all pass, and main's engine fails exactly the 27 new-behaviour assertions. Merging fires the `verifier` escape (rows of `obligations.tsv` and `schemas.tsv` edited in place), so it waits for the founder; land it before #304 | 0.49.160 provisional |

**Why overnight had to change before it could be switched on.** The founder
asked for overnight mode while about ten Felix sessions were running. A night
was one file per project, with the session id written and never read, so
switching it on would have held every one of those sessions at every stop on
one shared budget. It also left at `stop_hook_active`, so the session it was
for would have had one continuation. This session therefore never started a
night: it worked through its own turn, re-invoked by background tasks. It also
cannot use the fix, because hooks bind at session start and it started on
0.49.151. A session started from now on runs `! felix overnight --start` and
holds that session only (memory: `overnight-mode-is-per-session`).

**The runner probe (roadmap Phase 0), answered from a run that already
happened.** Elenchus's required `gate` check has run `felix gate` on
ubuntu-24.04 with no `claude` CLI since LeavesJ/Elenchus#20. Run 35779335006 on
`a45a985`: gate pass, 1439 tests, probes 5 found, obligations 1 dormant,
`qualified` skipped (no table), and `commission: never commissioned on this
machine`. Nothing on the gate path needs the CLI. What a runner lacks is
machine-local state (the commission receipt, the ledger, facts), which lives
under `$HOME/.felix/memory` and is empty there, so the merge-point check cannot
lean on the commission receipt until receipts live in the repository (Phase 2).
The image carries jq 1.7 and sqlite3 3.45.1. Go 1.24-1.26 are in the tool
cache, which puts them on PATH only through setup-go (unverified). Felix is
checked out from felix-home `main` at run time, not a pinned sha.

**Veldra's obligations request (roadmap Phase 0, the second ecosystem).**
- **The clone.** A durable clone at `~/.felix/clones/veldra-main`, origin/main
  `2430b1f`. The founder's `~/ReserveGrid-OS` backs the live soak and was only
  read.
- **The probes.** workspace_member 16, http_service 7, container_image 14,
  ci_workflow 2, env_template 1, all found.
- **The answer.** A Plan subagent answered, given the request and nothing
  else, verbatim to `commission/obligations_surveyed.tsv`. Read back: 15
  proposed, 15 current, 0 refused, 0 admitted.
- **Against main.** All fifteen apply, and 13 evidence commands fail on main.
- **The check.** Three agents took five candidates each, checking the code and
  every record Veldra keeps; there was no refuting second agent this time.
  - Nine candidates are recorded nowhere, so on Veldra this is recall and not
    only calibration.
  - Twelve are worth deciding and three are weak as written.
  - Every checker can pass with its hole still open, as on Elenchus.
  - The strongest are on the desktop release path: the updater signing key in
    workflow-level env, and an update manifest that publishes empty
    signatures.
- **The founder's copy** is `~/.felix/memory/veldra/commission/pdf/candidates-checked.pdf`,
  with the source, the verbatim verdicts and the answer file beside it. Roadmap
  §5's signal (a second project yielding nothing a person would admit) did not
  fire.
- **A gap in the request itself.** The answerer could not read the doctrine:
  Veldra's `.claude/CLAUDE.md` is gitignored, so a clone lacks it.

**Waiting on the founder** (`felix overnight --report`): the Elenchus and
Veldra candidates' admission, then #310's verifier escape, then #304.

**Next, unowned:**
- control 7 (the coverage report) after #310;
- the request naming a gitignored doctrine;
- #308 and #309 (deny scope), still with their own session.

**Traps paid for this session:**

- A mode that changes what a stop does must be keyed by the session that
  asked for it; per-project state was harmless only while sessions were one.
- The deny row that refuses a hand-written `.felix` marker refuses one in a
  scratch clone too; a clone resolves by `remote_match` without one.
- A background suite copies the harness when it starts, so it tests the code
  as it was then. Restart it after an edit, or it records a stale manifest.
- A queued engine PR's `red.tsv` goes stale at every merge ahead of it, and
  an out-of-order merge takes your version silently. Record after the last
  merge ahead lands, and read main again immediately before `felix merge`.
- The Workflow tool needs the founder's explicit opt-in. Three Agent calls do
  the same fan-out without it.
- `git merge --abort` refused on a file iCloud had touched: `git update-index
  --refresh` first.
