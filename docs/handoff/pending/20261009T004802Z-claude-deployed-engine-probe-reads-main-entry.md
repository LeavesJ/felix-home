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

**A new stale window, and the only way out of it.** When origin/main
declares a version nothing is installed at, the row goes from found to
empty. Any session's fetch does this, between an engine merge and its deploy.
- That stales every green felix-home receipt. It is the honest reading: in
  the same window the gate's `installed` check fails in every checkout.
- From a worktree, only the deploy clears it. A re-gate there is red on
  `installed`, and the structural branch does not stop early, so it runs the
  full suite to reach that red.
- The deploy makes the old receipts current again, where under the old row
  a deploy staled them for good. Prunes and candidate installs stale nothing.
- Follow-up, an engine change kept out of this table PR: name the moved
  predicate in felix_verify_current's stale reason, so "the grounded facts
  moved" says which fact.

**Evidence** (section runner: the suite preamble plus the two blocks, from
an empty temp directory):
- My block, before the blind one existed: 10 of 17 fail on main's row, the
  prune pair among them. The test commit e69afae01 precedes the fix
  c48d29225.
- Both blocks, 48 assertions: all pass on the fix; 35 fail on main's row.
- Eight mutants of the row each fail at least one:

  | mutant | fail |
  |---|---|
  | the old row | 35 |
  | the registry's installPath as the probe | 23 |
  | the new probe with the old witness | 16 |
  | the witness without its no-version guard | 5 |
  | local main only | 4 |
  | every cached harness/ | 34 |
  | the witness matching a prefix (0.49.27 in 0.49.270) | 1 |
  | the probe stopping at `<version>/`, not `harness/` | 2 |

  The last two are the reviewer's. My block alone passes both of them, and
  only the blind block catches them.
- The real home after the change: `probes-check projects/felix` reads
  deployed_engine found 1, with 0 blocking.

**Blind round.** The second block (30 assertions) was authored from the
contract in prose, never shown the row or my block. It passed 30 of 30 on the
fix the first time it ran against it.

**Review** (Opus, adversarial): no blockers. Both governance claims were
confirmed from the code (the `verifier` escape fires, and the stamp hash
moves). What it found, and what was done:
- **A `cd` into an empty fixture path stays in the suite's own checkout.**
  Under fork failure the fixture's `git update-ref refs/heads/main main~1`
  would then rewind the real main, through the refs a worktree shares with
  the home. Every fixture `cd` is now `${X:?}`, and the blind block's
  `git -C` helper refuses an empty path. Measured: bash 3.2 exits 127
  before any git runs.
- **The two reviewer mutants above.** Pinned by the blind block.
- **Two equality checks could pass with both sides empty.** A non-empty
  baseline assertion was added. The fixture commits now pin
  `commit.gpgsign=false` and `core.hooksPath=/dev/null`.
- **The row reads the default cache only.** The comment now says so: the
  gate also honours FELIX_KERNEL_CACHE and FELIX_PLUGIN_CACHE, and the old
  row did not read them either.
- **Left as they are:**
  - With no main ref, deploy-check reads the obligation dormant while this
    row reads unknown. The gate fails that checkout either way.
  - A fetch landing between the probe and its witness can give one blind
    reading.
  - The first facts drift report after the home pulls says 39 to 1 members.
  - GREP_OPTIONS predates this change; slot 14's branch handles it.

**Version bump at "you are next".** tests/run ships in the cache, so landing
without a bump leaves main's engine apart from main's entry, and `installed`
fails everywhere.

**For the founder.** This is a table change, and it escapes.
- probes.tsv is in FELIX_ESCAPE_TABLES. An in-place row edit removes a line,
  so `_felix_escape_shrank` fires `verifier projects/felix/probes.tsv`. It
  lands as a draft marked needs-founder, by `gh pr merge` on his yes.
- probes.tsv is in FELIX_COMMISSION_TABLES, so the policy hash moves. The
  felix commission grant (projects/felix/autonomy.commission) goes stale and
  needs `felix autonomy --allow commission` again.
- Queued by the 10-08 carrier as 11b, last in the batch, beside 11
  (commission-unasked-rows), so one sitting and one re-stamp cover both.
  - Agreed with 11's session: 11 lands first, then 11b, then the re-stamp.
  - If 11b is ready and the founder sits before 11's prerequisites (.277,
    then slot 10) have landed, 11b goes first and 11 merges main after it.
  - The two branches share only tests/run, and in different regions.
- When the home pulls this, every felix-home receipt goes stale once, on
  topology and policy. Land it when no gated receipt is waiting to merge.

**After 3b lands**, convert the block's four git-write subshells to
`_fx_cd`.
