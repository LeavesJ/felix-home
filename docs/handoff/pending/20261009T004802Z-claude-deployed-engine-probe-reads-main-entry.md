### 2026-10-08: a cache prune no longer stales a green receipt

**Defect.** On 2026-10-08 a gate on main 6fe5f9868 passed after about four
and a half hours, with 6328 passed, 0 failed and 7 skipped. Two minutes later
the Stop hook called its receipt stale: "the grounded facts moved".
- The receipt's topology hash is reproduced exactly by that day's probe rows
  with one change: deployed_engine counting 40 instead of 39.
- Claude Code had pruned one old cached Felix version. Nothing else moved.
- The row ran `ls -1d "$HOME"/.claude/plugins/cache/felix/felix/*/`, and
  felix_epoch_topology hashes each row's member count. So any prune, and any
  install of another version, staled every green receipt on the machine.

**Decided: option (a), the row and not the epoch.** The row now enumerates
one entry: the cache directory of the version main declares, down to its
`harness/`.
- That entry is the one the gate's `installed` check and the merge judge
  read. felix_accepted_deploy_diff calls an entry without `harness/` "nothing
  installed", and the row agrees with it.
- Main is read the way the gate reads it, origin/main before main.
- (b), teaching the epoch to skip that row's count, was rejected. The engine
  must not name the row, so (b) needed one of two things:
  - a probes.tsv column, which is a schemas.tsv row and an escape anyway;
  - or no member counts in the epoch for every project, which breaks "a
    probe count moving IS the topology moving" (epoch.sh) everywhere to fix
    one row.

**The witness asks the registry** (installed_plugins.json), not the
filesystem.
- Registry names main's version, entry missing: `blind`, which blocks. The
  registry points at nothing.
- Registry names another version: `empty`. Main's engine is not deployed
  yet, and the `installed` check names the remedy. The old witness
  (`test -d` on the cache) would read that window as blind.
- Main's version cannot be read: the witness exits 2, so the row is
  `unknown`. The gate fails that checkout too.

**What the epoch rests on now.** Main's entry being present, not which
version it is and not what else the cache holds.
- Main advancing to an undeployed version stales receipts (found to empty).
  Deploying it makes them current again (back to found, 1).
- A receipt's verdict about a branch tree does not depend on main's version
  number. Main moving is what tree ids and merge's own checks are for.

**Evidence** (section runner: the suite preamble plus the block, from an
empty temp directory):
- Main's row: 10 of 17 fail, the prune pair among them. The test commit
  e69afae01 precedes the fix c48d29225.
- The fix: 17 of 17.
- Six mutants of the row each fail at least one assertion:
  - the old row;
  - the registry's installPath as the probe;
  - the new probe with the old witness;
  - the witness without its no-version guard;
  - local main only;
  - every cached harness/.
- The real home after the change: `probes-check projects/felix` reads
  deployed_engine found 1, with 0 blocking.

**For the founder.** This is a table change, and it escapes.
- probes.tsv is in FELIX_ESCAPE_TABLES. An in-place row edit removes a line,
  so `_felix_escape_shrank` fires `verifier projects/felix/probes.tsv`. It
  lands as a draft marked needs-founder, by `gh pr merge` on his yes.
- probes.tsv is in FELIX_COMMISSION_TABLES, so the policy hash moves. The
  felix commission grant (projects/felix/autonomy.commission) goes stale and
  needs `felix autonomy --allow commission` again.
- Proposed: beside slot 11 (commission-unasked-rows) and last in the batch,
  so one session and one re-stamp cover both.
- When the home pulls this, every felix-home receipt goes stale once, on
  topology and policy. Land it when no gated receipt is waiting to merge.

**After 3b lands**, convert the block's four git-write subshells to
`_fx_cd`.
