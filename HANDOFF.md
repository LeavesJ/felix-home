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
state", with the next id (after 0br comes 0bs). Move the section it replaces
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

### 0br. 2026-09-22, closing — six pull requests shipped and deployed, the public snapshot is a command and was brought forward, Elenchus has a working required check again

**Deployed: engine 0.49.140**, from the home checkout, verified against the
tree. Every merge below passed `felix gate` on its exact tree and CI.

| PR | What | Engine |
|---|---|---|
| #281 | The session lifecycle recorder: `lifecycle.log`, nine columns, a row per start, resume, clear, compact, handoff and summary | 0.49.136 |
| #282 | #264 closed: the platform's summary request is its own session and recorded as nothing; Stop, SessionEnd and the ledger pass over it | 0.49.137 |
| #283 | HANDOFF.md split into this file and `docs/handoff/<id>.md`, byte-identical on reassembly | — |
| #284 | `projects/felix/snapshot.sh` with an audit that is not its scrub; `secret-scan` reads `ASIA` keys; the unattended template commits as `github-actions[bot]` | 0.49.138 |
| #285 | `felix audit` (read-only, from a plain clone) and `felix new --no-commission` | 0.49.139 |
| #286 | The red.tsv base check skips where its base is no commit in the repository, as in a published snapshot | 0.49.140 |

**Founder decisions, 2026-09-22:**

- #285 was stopped by `felix merge` on the `verifier` escape
  (`engine/harness/ecosystem.tsv`: two `allow` rows for `lib/audit.sh` and
  `lib/audit-read.sh`, the default runner roster). The founder approved it in
  session; it was merged with the same `gh pr merge --squash` felix merge
  uses, and the decision is on the PR.
- Elenchus's `main` now requires 0 approving reviews (the founder's change);
  the required `gate` check and admin enforcement stay. So Elenchus's wall is
  the server-side gate alone, and Felix merges its own Elenchus PRs on it.
- "Every time you decline something, record it": each declined Felix
  suggestion goes through `felix route --ack`, and each is counted as a
  failure of the routing layer v3.2 should remove (memory:
  `record-every-decline`).

**Also done:**

- Queue item 1 is complete: all 23 ids of direction-decisions §2 are in
  `ECC_DISABLED_HOOKS`, the last two added only after the deployed recorder
  wrote a correct row.
- The 78 phantom summary sessions' `ledger.d` files were moved aside (backup
  `~/.felix/memory.cleanup-264.20260922T181324Z`); `felix ledger` folded 0 back.
- LeavesJ/Elenchus#20 merged (CI checks out Felix from felix-home); the first
  main-path gate since 2026-09-13 passed on `4716cb2`. LeavesJ/Elenchus#21
  merged (its copied workflow no longer commits as a stranger; it never had).
- The public snapshot was brought forward by the command it now is:
  LeavesJ/Felix#3, engine 0.49.122 to 0.49.140, merged on green CI as
  `d6b16e8` (home source `437005e`). Before it: 13 names audited, 8 lines
  acknowledged, none open; no new secret hits; the suite on the public commit
  2,957 passed, 0 failed. A fresh public clone runs `felix audit` and stays
  clean, so the README's first instruction is true. The first build had failed
  the suite on a check #285 added (fixed in #286), which is the snapshot
  command catching a defect before publishing. `felix maintenance --ran
  snapshot` is recorded.
- The agent-written `~/.felix/memory/felix/snapshot-ack.tsv` (inert since the
  tracked `.snapshot-ack.tsv` landed) was moved to the session scratchpad.

**Open, in queue order:**

1. Queue item 2: `lib/table.sh` as a validator, `schemas.tsv`, a gate
   `schema` check, then `coverage.tsv`. It owes schema rows for
   `lifecycle.log`, the handoff stamp, and `decisions.log`, whose decline rows
   lack the declined play and the session id, so declines cannot be tallied
   per route yet. The split of `tests/run` and `felix` rides with it.
2. A defect found this session: `deny.tsv` rows read heredoc bodies and
   quoted text as commands. Row 30 refused a commit message and a memory note
   that only mentioned the project marker file after a `<name>` placeholder.
   `felix audit`'s reader (`lib/audit-read.sh`) already sets such text aside.
3. Queue item 3, the harvest rows, after which the founder sets ECC's
   `hooks_enabled` false.

**Traps paid for this session** (memory: `workflow-agents-die-together`,
`fact-gate-keys-on-command-tokens`): an API stall and then the weekly usage
limit each killed workflow agents mid-run; the desktop app refuses a session's
writes to worktrees it did not start in, so agents work in scratch clones;
land from a fresh GitHub clone, because gate receipts are per checkout and
the deny table refuses rewriting a remote or force-pushing; check
`git log origin/main..main` in the home before a deploy (another session had
committed `projects/sv2-apps` there unpushed); every deploy stales the
receipts of every open checkout, so gate once, last.

---

## Index of earlier sections

Newest first. Each file is the section exactly as it stood.

| § | Section |
|---|---|
| [0](docs/handoff/0.md) | DECIDED 2026-08-14, AMENDED 2026-09-13 — this repository is private, and a snapshot of the engine is public |
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
