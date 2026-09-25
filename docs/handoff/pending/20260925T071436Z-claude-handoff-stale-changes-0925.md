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
  "merge 359 when ready", and #349 landed at 07:31Z as 4a3dcf37 on "merge
  349 after re-stamp". Every approval is recorded as a comment on its PR.
- *The printf|grep -q pipefail class.* Split with the carrier: the engine
  sites went to session 1de88e as #376 (43d3e444, 0.49.227), with four extra
  sites from this session's sweep that its branch lacked. The suite sites are
  #364 (dc854d2c, 0.49.228), recorded red against #376's head before #376
  landed, so it merged straight after. Both are deployed.

**In flight, and who carries it.**

- **Carrier chain ("Carry felix-home queue once Actions runs again"):** the
  fold (#377) has landed. Still queued: founder-note docs, #369, #373,
  persist-credentials, #339, #338, #361 (BehaviorChangeBench tracked), #343
  (the deny widening), #350 (landing-actor L1), and #360 and #365 (the
  stranded engine fixes). Read the carrier's order, not this list.
- **Founder's lane:** #340, #358 (L2a) and #304 wait for his yes.
- **#361's home step, at merge.** Move the home's untracked
  `projects/behaviorchangebench` to
  `~/.felix/backups/2026-09-25-behaviorchangebench-untracked/` and keep it.
  Then `git pull --ff-only`, check the tracked copy is byte-identical, and
  tell the carrier.
- **ReserveGrid:**
  - The founder landed `claude/land-local-branches-0925` (main e044908),
    which carries the PB-14 runbook fix and the gateway warning fix.
  - The rate-limits merge was redone on that main as `469e53f` (rate
    limits plus D5 enforce). Its diff from the old `14b1216` is exactly
    main's new commits, and it is gated green (superscan 18/0, D5 PASS). It
    sits in `/Users/a14808/ReserveGrid-OS/.claude/worktrees/land-rate-limits`
    and needs the founder's push, because felix-home's deny row 99 fires on
    it: the hook takes the project from the session's cwd (#362).
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
- **A red record is keyed to the whole `engine/` tree, `tests/run`
  included.** When #376's head moved by a fixture change alone, #364's
  record against the old head stopped holding. Watch the base PR's head
  until it lands.
- **A workflow that finishes late still pushes.** An engine sweep this
  session had already superseded landed on #364's branch hours later. It was
  folded in with `git merge -s ours`, which keeps the tree exact with no
  force-push.
- **`felix merge` merges the checked-out branch by name.** A local branch
  named differently from the PR's head branch cannot be merged until the
  PR's name points at the verified head.
