### 0br. 2026-09-22, closing — seven pull requests shipped and deployed, the public snapshot is a command and was brought forward, Elenchus has a working required check again

**Deployed: engine 0.49.141**, from the home checkout, verified against the
tree. Every merge below passed `felix gate` on its exact tree and CI.

| PR | What | Engine |
|---|---|---|
| #281 | The session lifecycle recorder: `lifecycle.log`, nine columns, a row per start, resume, clear, compact, handoff and summary | 0.49.136 |
| #282 | #264 closed: the platform's summary request is its own session and recorded as nothing; Stop, SessionEnd and the ledger pass over it | 0.49.137 |
| #283 | HANDOFF.md split into this file and `docs/handoff/<id>.md`, byte-identical on reassembly | — |
| #284 | `projects/felix/snapshot.sh` with an audit that is not its scrub; `secret-scan` reads `ASIA` keys; the unattended template commits as `github-actions[bot]` | 0.49.138 |
| #285 | `felix audit` (read-only, from a plain clone) and `felix new --no-commission` | 0.49.139 |
| #286 | The red.tsv base check skips where its base is no commit in the repository, as in a published snapshot | 0.49.140 |
| #288 | The red.tsv and version checks apply only to a branch that changes the engine; #285 had failed every docs-only pull request, this one's first | 0.49.141 |

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
receipts of every open checkout, so gate once, last; and a check that asks
something of every branch must say which branches it applies to (#285's
record checks failed every docs-only branch until #288).
