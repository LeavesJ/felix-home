### 2026-09-23/25 — stranded work audited and backed up, the landing actor designed and put first, the founder's batch landed

**Where to start.** The live ledger of every open item, with its owner and
what it waits on, is `~/.felix/memory/felix/audits/2026-09-24-batches/tracker.md`
(memory root, backed up by pulse). Re-check any row with gh before acting on
it.

**What the founder asked, and what came of it.**

- *"Are we all caught up?"* No. A 55-agent audit of 155 transcripts, every
  branch, worktree and PR found nothing lost at the PR stage (no PR closed
  unmerged, and nothing merged since 09-21 later dropped). The stranded work
  was outside PRs:
  - Unbuilt work that existed only in transcripts:
    - the deny widening;
    - #314's three promised follow-ups;
    - the felix_deploy_diff residue bug.
  - Local-only commits in ReserveGrid and Elenchus.
  - An unpushed BehaviorChangeBench primer.
  - An unbacked memory repo: pulse refused on the nested clone
    `~/.felix/clones/veldra-main`. Fixed with `~/.felix/.gitignore`, and
    backed up since.
- *Landing actor.* Three skeptics were run against the draft, and the design
  was finalised (memory root `audits/2026-09-23-landing-actor/design.md` plus
  its PDF).
  - **DECIDED 2026-09-24 by the founder:** F1, build it before the qualified
    judge; F2, nothing lands while the Mac sleeps.
  - The roadmap text is #348, merged on his yes and rated "yes". Phase 0b
    now includes `felix inventory` and the lost-work page, built by the
    "Felix engineering systems report" session.
- *His batch.* #310, #311 and #309 landed on his typed yes (00:35:40Z in
  7fe5f0a8), which he reconfirmed in this session. Each landed head was
  checked: #309's rebuild only adds the `checkout` scope. The re-stamp is
  done: the stamp and receipt are at 6153ef96, 07:08Z. #359 landed on his
  "merge 359 when ready". Every approval is recorded as a comment on its PR.

**In flight, and who carries it.**

- **Carrier chain ("Carry felix-home queue once Actions runs again"):**
  - #349 (after the re-stamp, per his words), then the fold and handover docs;
  - #364, the pipefail flake fix;
  - persist-credentials, #339, #338;
  - #361, BehaviorChangeBench tracked;
  - #343, the deny widening;
  - #350, landing-actor L1;
  - #360 and #365, the stranded engine fixes.
- **Founder's lane:** #340, #358 (L2a) and #304 wait for his yes.
- **#361's home step, at merge.** Move the home's untracked
  `projects/behaviorchangebench` to
  `~/.felix/backups/2026-09-25-behaviorchangebench-untracked/` and keep it.
  Then `git pull --ff-only`, check the tracked copy is byte-identical, and
  tell the carrier.
- **#364:**
  - The tests/run part is done.
  - The engine part was a workflow in this session. If it is gone, rebuild
    it from the branch. It covers:
    - `lib/escape.sh:300` and `lib/classify.sh:125`, which **fail open** on
      a large diff;
    - `lib/qualify.sh` and `lib/coverage.sh`, which fail closed;
    - a gate check that refuses the pattern.
- **ReserveGrid:**
  - Merge `14b1216` (rate limits plus D5 enforce, gated green) sits in
    `/Users/a14808/ReserveGrid-OS/.claude/worktrees/land-rate-limits` and
    needs the founder's push. Felix-home's deny row 99 fired on it because
    the hook takes the project from the session's cwd (#362).
  - Deploy the dashboard behind a proxy only after setting
    `[rate_limit] trusted_proxies`.
- **Undecided:** the untracked `projects/webapp/` in the home.

**Traps paid for.**

- **A PR that adds an escape rule is not caught by that rule.** Main's
  engine judges the PR. #358 is held by draft and `needs-founder`.
- **`printf … | grep -q` under pipefail takes SIGPIPE on large input,** and
  lib/ readers then return wrong verdicts.
- **Every deploy stales every gate receipt on the machine** (design E1).
  Gate a docs branch with main holding still, and never fetch in the middle
  of a run.
- **A workflow agent read the founder's latest message as its scope,** and
  refused ReserveGrid work that an earlier message had asked for. Quote the
  authority, with a timestamp, in every stage prompt.
- **The fact gate trips on its trigger words even inside a string.** It fires
  on `rm -rf`, and on "DROP TABLE" text inside a heredoc. Write exports to
  the scratchpad instead of deleting them.
