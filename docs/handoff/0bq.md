### 0bq. 2026-09-22 — the recorder and #264 deployed, ECC step 1 complete, two branches in repair

**Deployed: engine 0.49.137**, from the home checkout, verified against the
tree.

- **#281**, the session lifecycle recorder (queue §6 "before item 1").
  `~/.felix/memory/<project>/lifecycle.log`, nine columns: time, kind
  (`startup|resume|clear|compact|handoff|summary`), session, bound engine,
  installed engine, HEAD, handoff hash, transcript, note. A dated exception to
  rows-first; its `schemas.tsv` row is owed with queue item 2.
- **#282**, fixing #264: the platform's summary request is matched on its
  fixed opening and closing and recorded as nothing; Stop, SessionEnd and the
  ledger pass over it; it writes one `summary` row to lifecycle.log. The 78
  phantom sessions' `ledger.d` files were moved aside with a backup at
  `~/.felix/memory.cleanup-264.20260922T181324Z`; `felix ledger` on the
  deployed engine folded 0 of them back. The matched day in
  `lib/route.sh` is 2026-09-24.
- **Queue item 1 is done.** `~/.claude/settings.json` now carries
  `GATEGUARD_BASH_ROUTINE_DISABLED=1` and all 23 ids of direction-decisions
  §2 in `ECC_DISABLED_HOOKS`; the four guards stay on. The last two ids went
  in only after the deployed recorder was driven once and wrote a correct row.

**In repair, on GitHub as WIP branches** (their work was done in scratch
clones, because the desktop app refuses a session's writes to worktrees it
did not start in):

- `claude/cheap-trial`: `felix audit` and `felix new --no-commission`. 19
  refuted-and-confirmed review findings, the high one a misspelled flag that
  ran full commissioning.
- `claude/snapshot-command`: `projects/felix/snapshot.sh` with its audit and
  scrub, rebuilding public f5a4d6f byte for byte. Two engine fixes ride with
  it: `secret-scan` learns the `ASIA` key prefix, and
  `templates/unattended.yml` stops committing as
  `felix@users.noreply.github.com`, a stranger's real account.
- After the snapshot branch merges: publish to LeavesJ/Felix (founder
  approved 2026-09-21).

**The founder's:**

- LeavesJ/Elenchus#20 cannot merge on a click from its author: one approval
  is required, admins included, and GitHub does not count an author's own.
  InsertWittyCommentHere can approve it, or the required count goes to 0.
- `projects/sv2-apps` (4c65a97) is committed on the home's main and not
  pushed; it was rebased, identical content, when #282 deployed.
- `~/.felix/memory/felix/snapshot-ack.tsv` was written by an agent,
  unreviewed; delete it once the tracked `.snapshot-ack.tsv` lands.
- Repositories that already copied `unattended.yml` keep the stranger's
  address until changed there.

**Next, in queue order:** item 2, `lib/table.sh` as a validator,
`schemas.tsv`, a gate `schema` check, then `coverage.tsv`; it owes schema
rows for `lifecycle.log` and the handoff stamp. The split of `tests/run` and
`felix` rides with it. Then item 3, the harvest rows, after which the founder
sets ECC's `hooks_enabled` false.

**Traps paid for this session** (in memory as `workflow-agents-die-together`):
an API stall killed every workflow agent in the same minutes; the weekly usage
limit killed the last agent of two workflows; land a scratch clone's work from
a fresh GitHub clone, because gate receipts are per checkout and the deny
table refuses rewriting a remote; check `git log origin/main..main` in the
home before a deploy.
