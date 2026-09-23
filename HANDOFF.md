# Handoff

Durable prose between sessions: what was decided, what shipped, and where the
next session starts. The mechanical state of a tree (branch, head, uncommitted,
recent commits) is `felix handoff`'s, in `SESSION_HANDOFF.md` under the memory
root, not here.

**How this file is laid out, since 2026-09-22.** It holds three things: §0,
the standing decision every session must know; the current state; and an index
of every earlier section, each kept verbatim in `docs/handoff/<id>.md`. The
file had grown to 6,445 lines, and reading it was a large share of the growth
in Bash calls (docs/2026-09-21-where-felix-stands.md §3). The split moved text
and changed none of it: the archive files concatenated in index order, after
`docs/handoff/_preamble.md`, reproduce the old file byte for byte (the sixty
files the split made; later sections join the index above them, below §0).

**The rule for the next session.** Write your section at the top of "Current
state", with the next id (after 0bv comes 0bw). Move the section it replaces
into `docs/handoff/<id>.md`, unchanged, and add its row to the top of the
index. A reference like "HANDOFF §0bm" means `docs/handoff/0bm.md`.

---

## 0. DECIDED 2026-08-14, AMENDED 2026-09-13 — this repository is private, and a snapshot of the engine is public

Unchanged; read [docs/handoff/0.md](docs/handoff/0.md). In one line: this
repository (`felix-home`) stays private because its history carries the memory
tree; the engine is published as a snapshot with no history at
`github.com/LeavesJ/Felix`, and never by flipping this repository public.

---

## Current state

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
---

## Index of earlier sections

Newest first. Each file is the section exactly as it stood.

| § | Section |
|---|---|
| [0](docs/handoff/0.md) | DECIDED 2026-08-14, AMENDED 2026-09-13 — this repository is private, and a snapshot of the engine is public |
| [0bu](docs/handoff/0bu.md) | 2026-09-23 — Phase 0: the Elenchus candidates checked, deny rows read the command the shell runs, three small items |
| [0bt](docs/handoff/0bt.md) | 2026-09-22/23 — the table validator (queue item 2, step 1) shipped, and a rename that hid an escape |
| [0bs](docs/handoff/0bs.md) | 2026-09-22/23 — Felix is a product for other people's projects, built first; the first obligations request answered blind; the roadmap |
| [0br](docs/handoff/0br.md) | 2026-09-22, closing — seven pull requests shipped and deployed, the public snapshot is a command and was brought forward, Elenchus has a working required check again |
| [0bq](docs/handoff/0bq.md) | 2026-09-22 — the recorder and #264 deployed, ECC step 1 complete, two branches in repair |
| [0bp](docs/handoff/0bp.md) | DECIDED 2026-09-21 — `projects/bazaar` is tracked, and its gate keeps its own log |
| [0bo](docs/handoff/0bo.md) | 2026-09-21 — four outside reviews checked against the transcripts, and where Felix stands |
| [0bn](docs/handoff/0bn.md) | 2026-09-19 — the endgame affirmed, and three direction decisions taken on evidence |
| [0bm](docs/handoff/0bm.md) | 2026-09-18 — the public snapshot brought forward and found uninstallable, and ECC read against v3.2 |
| [0bl](docs/handoff/0bl.md) | The session of 2026-09-17/18, whole — what shipped, what waits on one command, and where the next session starts |
| [0bk](docs/handoff/0bk.md) | Verified at session close, 2026-09-17 (night; 2026-09-18 UTC) — the judge is pinned outside the tree it judges, and a fixture that modelled the hole had to be rebuilt honest |
| [0bj](docs/handoff/0bj.md) | Verified at session close, 2026-09-17 (late) — the exception channel exists, read from the remote-tracking main, and six readers of the design found what one author could not |
| [0bi](docs/handoff/0bi.md) | Verified at session close, 2026-09-17 — the red count is a file in the tree, the gate has one reader of the deploy question, and the distance to v3.2 re-measured off the tree |
| [0bh](docs/handoff/0bh.md) | Verified at session close, 2026-09-16 (closing) — the session's own record, audited: eleven claims false, twenty-six stale, and what six sections left out |
| [0bg](docs/handoff/0bg.md) | Verified at session close, 2026-09-16 (late) — an obligation nobody named can exist now, and nothing admits it but a person |
| [0bf](docs/handoff/0bf.md) | Verified at session close, 2026-09-16 (night) — the ledger asks what main accepted, the same question as the gate |
| [0be](docs/handoff/0be.md) | Verified at session close, 2026-09-16 (later) — the receipt carries the epoch, and a fact that moves outside the tree stales it |
| [0bd](docs/handoff/0bd.md) | Verified at session close, 2026-09-16 — an ask that crashes is unknown, and the probe gate is a checker |
| [0bc](docs/handoff/0bc.md) | Verified at session close, 2026-09-13 (night) — Felix merges its own pull requests, and the engine stopped saying otherwise |
| [0bb](docs/handoff/0bb.md) | Verified at session close, 2026-09-13 (afternoon) — #233 built, and a review reversed its central decision before it merged |
| [0ba](docs/handoff/0ba.md) | Verified at session close, 2026-09-13 — the engine is public, and the repository it came from is not |
| [0az](docs/handoff/0az.md) | Verified at session close, 2026-09-12 (overnight) — seven branches, and three things that were false before anybody checked |
| [0ay](docs/handoff/0ay.md) | Verified at session close, 2026-09-12 (night) — the standing direction became a mechanism, and two probes caught what reading could not |
| [0ax](docs/handoff/0ax.md) | Verified at session close, 2026-09-12 (late) — the history was cleaned, and the sweep found one commit that existed on one disk |
| [0aw](docs/handoff/0aw.md) | Verified at session close, 2026-09-12 — the upkeep ran, a fifth project appeared, and the graph dropped twelve edges without saying so |
| [0av](docs/handoff/0av.md) | Verified at session close, 2026-09-11 — the two provider rows answered, and a verify phase that ran out of session |
| [0au](docs/handoff/0au.md) | Verified at session close, 2026-09-10 — the graph was built three times and asked once, and the reason was a table |
| [0at](docs/handoff/0at.md) | Verified at session close, 2026-09-09 — the §0as queue built end to end, then reviewed, and every pull request in it changed |
| [0as](docs/handoff/0as.md) | Verified at session close, 2026-09-06 (late) — the first admission rule exists, and a blind control found the hole before anyone believed the checker |
| [0ar](docs/handoff/0ar.md) | Verified at session close, 2026-09-06 — the checker night: two grants, one caught at the boundary, and the distance to v3.2 measured |
| [0aq](docs/handoff/0aq.md) | Verified at session close, 2026-09-06 — three items the founder ordered, and a checker that does not catch what it protects |
| [0ap](docs/handoff/0ap.md) | Verified at session close, 2026-09-05 (overnight) — the measurement audit is closed, and one of the findings I closed it with was false |
| [0ao](docs/handoff/0ao.md) | Verified at session close, 2026-09-05 — the four high-severity audit findings are closed, and the manifest row says who grounded it |
| [0an](docs/handoff/0an.md) | Verified at session close, 2026-09-04 (overnight) — the provider protocol was exercised on real answers, and the admit phase grounds what a model names |
| [0am](docs/handoff/0am.md) | Verified at session close, 2026-09-04 — the first-encounter moment is a table, the two setup skills are rows in it, and the rows are waiting for a session |
| [0al](docs/handoff/0al.md) | Verified at session close, 2026-09-03 (overnight) — the substrate asks reality, and three of the checks written to prove it had never run |
| [0ak](docs/handoff/0ak.md) | Verified at session close, 2026-09-03 — the architecture is closed, and the floor has a one-line hole |
| [0aj](docs/handoff/0aj.md) | Verified at session close, 2026-08-31 (day) — the correction that matters is about method, not code |
| [0ai](docs/handoff/0ai.md) | Verified at session close, 2026-08-31 — Felix has a pulse, and three review rounds on it |
| [0ah](docs/handoff/0ah.md) | Verified at session close, 2026-08-30 (afternoon) — Decision C shipped, and the first review that ran before the merge |
| [0ag](docs/handoff/0ag.md) | Verified at session close, 2026-08-30 (day) — three decisions taken, and the new voice is live |
| [0af](docs/handoff/0af.md) | Verified at session close, 2026-08-30 (overnight) — the advisory layer measured, and the redesign on the table |
| [0ae](docs/handoff/0ae.md) | Verified at session close, 2026-08-30 — the review that was outstanding, and the gate that could not fail |
| [0ad](docs/handoff/0ad.md) | Verified at session close, 2026-08-29 (late) — a defect found, and the instrument that nearly hid it |
| [0ac](docs/handoff/0ac.md) | Verified at session close, 2026-08-29 — a second project, and what it broke the same day |
| [0ab](docs/handoff/0ab.md) | Verified at session close, 2026-08-28 — the backlog was verified, and a third of it was wrong |
| [0aa](docs/handoff/0aa.md) | Verified at session close, 2026-08-27 — nine fixes, and what finding them taught |
| [0z](docs/handoff/0z.md) | Verified at session close, 2026-08-25 — the instrument was broken, and every number below it |
| [0a](docs/handoff/0a.md) | Verified at session close, 2026-08-18 |
| [0b](docs/handoff/0b.md) | DECIDED 2026-08-18 — issue #2 is "make promotion real", and the spec is unwritten |
| [0d](docs/handoff/0d.md) | DECIDED 2026-08-18 — the streak reads "Earned." and the founder says not yet |
| [0c](docs/handoff/0c.md) | What this session established about how Felix should work |
| [1](docs/handoff/1.md) | Standing direction — decided, do not ask again |
| [2](docs/handoff/2.md) | State as of 2026-08-11 |
| [3](docs/handoff/3.md) | Operational traps that have each cost real time |
| [4](docs/handoff/4.md) | Guidebook exit criteria (p41) |
| [4b](docs/handoff/4b.md) | Playwright: assessed 2026-08-11, deliberately not adopted |
| [4c](docs/handoff/4c.md) | Self-diagnosis, and the ceiling on it |
| [5](docs/handoff/5.md) | Next, in leverage order |
| [5a](docs/handoff/5a.md) | Session of 2026-08-13/14 — what shipped, and what it cost |
| [5b](docs/handoff/5b.md) | What is now tracked as an issue |
| [6](docs/handoff/6.md) | Open decisions |
| [7](docs/handoff/7.md) | Approaches already tried and rejected |
| [8](docs/handoff/8.md) | The failure mode this project keeps having |
