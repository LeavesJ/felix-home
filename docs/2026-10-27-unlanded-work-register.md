# Work not on main, 2026-10-27

## What this is

This is every branch on origin whose work is not on main, and what should
happen to each one, read on 2026-10-27 against main 69b51a61 (0.49.307). The
founder asked for it because his CSO reads only main. In his words: "it
won't know the full picture of felix if work that's passed are not landed in
main".

This is a snapshot. To see where things stand today, run `felix inventory`
and `felix land --prs`.

**How it was made.**
- **Listing.** 221 branches on origin had commits that `git cherry` could not
  find on main. Main squash-merges, so cherry misses landed work. 125 of the
  221 were PR branches whose head is exactly the head their PR merged at, so
  their work is on main.
- **Triage.** That left 96: 75 with no PR, 16 with a closed PR, 4 with an
  open PR, and 1 with a merged PR whose merged head is unknown. Eight
  read-only agents triaged them, one per group of related branches. Each
  verdict had to cite a commit, PR, file and line, or a quoted record.
- **Checking.** A skeptic then re-checked 31 of the verdicts:
  - every "passed, not landed" and every "unfinished";
  - every "on main" or "replaced" that would lose more than a little work if
    it were wrong;
  - a sample of the rest.

  It overturned one. The Mac-only report backup is now carried by
  `claude/main-picture-2026-10-27`.
- **Nothing was run.** No test, part or gate ran. A "passed" below means that
  a record of the pass exists: CI, a green gate, or red then green on a
  section runner.
- **Not in this list.** The audit's own branches (`claude/audit-b00` to
  `claude/audit-b30`, `claude/audit-combined`,
  `claude/plan-a-unit-facts-and-map`) and today's two docs branches. They
  are in flight, and the next section covers them.

| Verdict | Branches | What it means |
|---|---|---|
| On main | 71 | The behaviour landed, often through a later PR that carried this branch. |
| Replaced | 13 | Main solved the same problem differently, or a later branch replaced it. |
| Drop | 3 | Probes and a throwaway census script. Nothing to keep. |
| Passed, not landed | 5 | Finished, with a record that it passed, but not on main. |
| Unfinished | 3 | Worth finishing. Each line below says what is left. |
| His | 1 | Only the founder can decide it. |

No branch holds work that this list fails to account for. Two copies are
safe to drop only after `claude/main-picture-2026-10-27` lands:
`salvage/home-reports-2026-10-03` and
`salvage/2026-10-27/felix-linkedin-post-2790bc`.

## In flight, not yet on main

- **The audit of 2026-10-23.**
  - The register is `docs/2026-10-24-audit-register.md`: 96 defects in 23
    batches.
  - They are being built in worktrees `audit-bNN`.
  - Three batches are final and merged into `claude/audit-combined`: b04,
    b21 and b23.
  - The rest are in review, in a second build round, or finishing their
    build.
  - The non-founder batches land together as one PR. Batches 10, 16 and 17,
    and the alert workflow, open as drafts for the founder.
- **Plan A** (`docs/2026-10-24-reach-checks-design.md`) is approved. Steps 5
  and 6 are being built as audit batch b30.
- **`claude/main-picture-2026-10-27`** brings onto main:
  - his reports and decks;
  - the audit register and design;
  - the LinkedIn post;
  - a pending section recording his decisions of 10-23 to 10-27.

  It lands on green.
- **#462** folds those decisions into `docs/direction.md`. It is a draft
  that waits for his yes.

## Passed, not landed

Each of these must be brought up to date with main, re-recorded, gated and
landed. All five are engine changes, so they land one at a time: each merge
leaves every other engine PR behind main. Several touch files the audit
batches also change, which is why the order below puts them after the
combined audit PR.

| Branch | What it does | Passed | What landing takes |
|---|---|---|---|
| #452 `claude/direction-read-first` | Session start names `docs/direction.md` first. Amendment A32 makes the land job hold any PR that touches it. | Section runner: part 1550 had 66 failures on main and 0 on the branch, part 1560 had 23 and 0. Mutants all killed. Opus review "ship after fixes". | Merge main (conflicts only in `plugin.json` and the part list), record, red, gate, then mark ready. It is the engine half of the "direction currency" loop in direction §3. |
| #425 `LeavesJ/stop-reports-each-block-once` | The Stop hook reports another plugin's blocked calls once, and again only when the count grows. | CI gate passed on head e6024e04 (2026-10-12). | Merge main: `plugin.json`, `assertions.tsv` and `red.tsv` conflict; `hooks/stop` merges clean. New version, record, red, gate. |
| `salvage/2026-10-27/secret-scan-ref` (fix 3dd7dfd0) | `secret-scan` reads a quoted value that starts with `$` as a reference, so the GitHub MCP runbook that `felix new` writes no longer fails Felix's own scan. | Red then green: 49 passed and 4 failed, then 53 and 0. No gate or CI. | Cherry-pick onto main. It should apply clean. A blind assertion round is owed, because its tests were written by the fix's author. Then record, gate and PR. Its original branch is gone from origin, so this is the only copy. |
| #365 `claude/deny-hook-followups-314` | The pre-tool hook reads its keys from a 2K head. A refused command's echo is capped at 2K. The deny decoder runs in linear time. | A trimmed runner: 325 passed and 0 failed on the branch, against 48 failures on main. Six mutants killed. | Merge main. Expect conflicts in `lib/deny.sh`, `lib/deny-read.sh` and `pre-tool`. Port 585 lines of tests into `tests/parts/`, re-check equivalence against #343's reader, then record, red and gate. |
| `claude/project-writes-refuse-nonregular` (carrier slot 12) | Writes under `projects/<name>/` refuse a pipe, a dangling link, a directory or a link to another file, instead of hanging or writing through. | Recorded gate-ready on 10-08: 428 of 428 assertions, red on the base. No full gate or CI. | Engine work. Merge from its base ea68ed86, move four test blocks into `tests/parts/`, redo the commission stamp write under main's writer lock (#439), then blind round, record and gate. |

## Unfinished

| Branch | What it is | What is left |
|---|---|---|
| `claude/fresh-repo-tree-identity` | The tree id before a repository's first commit, and a gate that writes its own untracked output still counting as current. | Carry its five commits (not the #378 half, which landed) onto main. Reconcile with #447, which already covers part of U1. Review again, record, gate. Landing it unblocks 0cw item 7. |
| `claude/left-record` | Each Stop writes how the session left its tree (clean, dirty, unpushed, or ended on a question), and SessionEnd adds an end row. | 105 commits behind main. Rebase onto #397's inventory, port about 870 test lines into parts, refit `hooks/stop` and `session-end`, then record and gate. The inventory spec names it as "the next PR". |
| `claude/gf-b3` | Gate friction contract B3: `qualified` rows run in parallel. B1 and B2 landed as #438. | A revised contract first. The review found five blocking defects, among them a design flaw in sharing `.git/worktrees`. Then rebuild over main, blind tests, review, gate. |

## His

- **`claude/elenchus-handover-riyan-g36e9a`.** The Elenchus handover pack
  for Riyan: a runbook, guides, an engagement letter and an acknowledgment.
  Only the founder decides whether it belongs in felix-home, goes to another
  repository, or goes.
- **Also his.**
  - Closing draft #360. Main replaced it in #446, but it is still open.
  - Posting the LinkedIn post.

## The order Felix will take

This is Felix's plan, not a decision. It follows the build order in
direction §5.
1. `claude/main-picture-2026-10-27` (docs, lands on green).
2. The audit's combined PR, then each founder batch as its own draft.
3. #452, then #425, then the secret-scan fix, then #365, then slot 12. Each
   one is brought up to date with main after the previous one lands.
4. The three unfinished branches, as build items in their own right.
5. Delete the branches marked on main, replaced or drop.
   - It waits until the copies above have landed.
   - It never touches a branch the founder has not cleared.
   - Each deletion is first archived under `refs/archive/`, as on
     2026-10-23.

The triage's full record is in the memory root,
`audits/2026-10-27-unlanded-triage/triage-result.json`. Each verdict there
carries its evidence and, where a skeptic checked it, the skeptic's
reasoning.

## Every branch

| Branch | Verdict | What it is | PR, or where it went |
|---|---|---|---|
| `LeavesJ/stop-reports-each-block-once` | passed, not landed | PR #425: the Stop hook reports another plugin's blocked tool calls once per blocking row, and again only when the count grows, keyed by … | #425 (open) |
| `claude/deny-hook-followups-314` | passed, not landed | Draft PR #365, the three #314 follow-ups. pre-tool reads its envelope keys from a 2K head or with one awk. A refused command's echo is … | #365 (open) |
| `claude/direction-read-first` | passed, not landed | Draft PR #452. The session-start hook names a regular docs/direction.md first, as the standing direction. Land-on-green amendment A32 makes … | #452 (open) |
| `claude/project-writes-refuse-nonregular` | passed, not landed | Carrier slot 12: overwrites and non-table opens under projects/<name>/ (obligations --seed, the commission stamp, felix gate, rival-gate … | no PR |
| `salvage/2026-10-27/secret-scan-ref` | passed, not landed | bin/secret-scan reads a quoted value that begins with $ as a reference, so the GitHub MCP runbook that felix new writes into every project … | no PR |
| `claude/fresh-repo-tree-identity` | unfinished | Fresh-repo PR-B/PR-C: the tree id before the first commit (U1-U4: staged content, no coarse:<count> id, an unborn session mark, the ledger … | no PR |
| `claude/gf-b3` | unfinished | The first build of contract B in full: B1 and B2 (the slow assertions) plus B3, which runs `qualified` rows in parallel under … | no PR |
| `claude/left-record` | unfinished | Every Stop writes how the session left its tree (clean, dirty or unpushed, plus whether it ended on a question) to … | no PR |
| `claude/elenchus-handover-riyan-g36e9a` | his | The founder's Elenchus handover set for Riyan: a 1384-line runbook, onboarding and setup guides, an engagement letter, a beta … | no PR |
| `claude/cloud-toolbox-five-plugins` | replaced | Toolbox entries (one cloud decision per plugin) for the five plugins installed on 2026-10-12, so the gate's cloud check passes. | #427, #428, 7dcfa15d |
| `claude/deny-343-landing-prep` | replaced | The old carrier's landing prep for #343: main 5772afac merged into deny-reads-every-command, plus a9da94c7 making a quoted span that holds … | #343, 8044ad9c |
| `claude/deploy-diff-residue-tracked` | replaced | Draft PR #360: felix_deploy_diff stops calling a tracked file residue (_felix_residue: index, then base, then the #86 ignore queries), and … | #446, #360, 50601023 |
| `claude/handoff-fold-0ca` | replaced | The same first fold as handoff-rotate-0924 (§0bz archived, §0ca to §0cc), cut as a separate draft. | #351, #377, f1eee4c3 |
| `claude/handoff-fold-edit-in-place` | replaced | handoff-check holds a fold's new current section to its heading only, so a section amended in place reads clean. | #352, #349, 4a3dcf37 |
| `claude/handoff-rotate-0924` | replaced | Handoff fold: §0bz archived, and the pending sections from #336, #341 and #344 become §0ca, §0cb and §0cc. A qualification premise commit … | #347, #377, f1eee4c3 |
| `claude/handover-docs-into-home` | replaced | Copies the 14 docs/2026-09-06 Elenchus handover files for Riyan and the founder's Aug 15 note into docs/ on the home. | #372, f582fb6f |
| `claude/sharp-dubinsky-4a8d46` | replaced | The binding-marker refusal (d247ed0a), a main merge, and a further commit 44e9dca4 that adds felix_project_name_ok so a .felix marker like … | #134, #144, d247ed0a |
| `feat/preflight` | replaced | felix preflight, an engine command that hard-codes machine-state checks (stray listeners, file modes) from the Elenchus MVP incident. | #124, #125, a60653b9 |
| `salvage/2026-10-27/felix-linkedin-post-2790bc` | replaced | The draft LinkedIn post of 2026-10-22 (post.md) and its three HTML figures with their CSS, salvaged uncommitted from a worktree. | 2aab8900 |
| `salvage/home-reports-2026-10-03` | replaced | A byte-for-byte backup of four report PDFs (48h engineering systems report 09-24, the v5 second report 09-30, the claude_code_felix usage … | 4c6a65b0 |
| `salvage/mendeleev-uncommitted` | replaced | A preserved copy of uncommitted edits from worktree intelligent-mendeleev-61185a (on 5110ca64): felix merge picks its closing paragraph per … | #315, f738b395 |
| `salvage/review-agent-findings` | replaced | Parks edits that four review agents wrote into the tree during the #33 merge work, unreviewed: re-reading the checkout before felix merge … | #36, #42, 71ccbcd7 |
| `LeavesJ/cloud-probe-28d34d` | drop | A throwaway census script for a Claude Code cloud VM: environment names, tools, reach and skill discovery. It also wires Felix's context … | #385, eb835136 |
| `tmp/authority-probe` | drop | One-line probe that adds '# probe' to projects/felix/autonomy, to exercise the #207 rule that a grant of authority is an escape. | #207, 79ad7bea |
| `tmp/ratchet-probe` | drop | Probe that deliberately weakens secret-scan on top of #206's first commit, to check that the armed qualification gate catches the … | #206, ae9bc8a0 |
| `LeavesJ/gate-runtime-friction-04420b` | on main | Replaces the suite's last step (one awk per manifest row, about 88 s of the gate) with a one-pass manifest comparison, _manifest_short, at … | #421, #424, 9f614a5b |
| `LeavesJ/queue-based-build-7a2cda` | on main | The design and contract docs of the row 0 session, "Queue-based build system" [62efaa]: the gate-friction design, contract A, the per-part … | #432, 9b75ead0 |
| `blind/final-filter-assertions` | on main | Blind assertions and the fix for running a commissioning row's when and check without the CLI's pipefail, plus blind assertions for … | #375, #402, bb6b20f1 |
| `claude/adopt-refuses-unread-capabilities` | on main | Adopt reads and writes the capabilities list only as a regular file. It refuses with 2 (dangling link, directory, pipe, unreadable or … | #418, de4037ef |
| `claude/autonomy-allow-fails-closed` | on main | Slot 6: felix autonomy --allow says allowed only when the reader then grants it, through felix_autonomy_grant, failing closed on NUL, … | #439, 82c4df2d |
| `claude/autonomy-revoke-fails-closed` | on main | Slot 4: felix autonomy --revoke removes exactly what the reader honours and fails closed. Revision 8, after seven adversarial reviews. | #439, 82c4df2d |
| `claude/cheap-trial` | on main | 29 wip commits building felix audit (stops after an edit sorted into passed, failed, stale or never) and felix new --no-commission. | #285, f4b68c2b |
| `claude/commission-check-unasked` | on main | Slot 10: a commissioning check that exits 2 or does not parse reads unknown instead of held, and a real run still runs its felix answer. | #443, 248d9c7e |
| `claude/commission-empty-state-unknown` | on main | A commissioning state line that comes back empty, names no state, or was never read makes its row unknown, not blank and not the previous … | #375, 3a5c86e4 |
| `claude/commission-receipt-complete-run` | on main | A commission receipt over a run that reported fewer rows than its table lists, or over counts that are not numbers, is indeterminate … | #375, 6fc85e76 |
| `claude/commission-template-drift` | on main | felix commission names each row whose columns differ from the template's row for the same need. It reports and never refuses. | #447, 0db47b70 |
| `claude/commission-unasked-rows` | on main | Carrier slot 11: the commissioning template's and every governed project's reach and discover rows read unknown when their check could not … | #443, eceff4aa |
| `claude/commission-when-crash-unknown` | on main | A commissioning `when` that answers neither yes nor no reads unknown, and a `when` that ends the shell is not read as no; merged with … | #375, 6978524d |
| `claude/competent-albattani-674980` | on main | Fixes felix_mem_mistake so a failing gate on an unborn HEAD writes one mistakes.log row, not a row split across two lines. | #265, #378, 32769ee6 |
| `claude/declared-not-text` | on main | Carrier slot 8, stacked on 7: felix_declared refuses a capabilities file that is not a list of names (a NUL, UTF-16/32, non-printable … | #443, 7fd4bb6e |
| `claude/declared-unread-readers` | on main | Carrier slot 7: every felix_declared reader (setup, maintenance, procedures, probes, stack, toolbox, next, pulse, commission topology) says … | #443, 08649fb1 |
| `claude/deny-remote-refs-written-muf8f9` | on main | #340: the refs/remotes deny row refuses a remote-tracking ref written, not one read, stacked on #343. This name is the cloud session's push … | #340, 3c9f0a89 |
| `claude/deployed-engine-probe-reads-main-entry` | on main | Slot 11b: the deployed_engine probe reads only the cache entry for the version main declares, so a plugin-cache prune or an unrelated … | #443, 248d9c7e |
| `claude/felix-dev-continuation-4577cc` | on main | Fixes felix_route_step_used so that one skill no longer satisfies every step its plugin ships. Owner-level matches now apply only to a bare … | #54, 68ac70b6 |
| `claude/felix-ecc-plugin-ba2871` | on main | Handoff §0ak for 2026-09-03 (the architecture is closed, and the floor has a one-line hole), plus exact paths to the governing documents. | #138, #139, 2cc3b124 |
| `claude/gf-a-blind` | on main | Contract A's first blind block: receipt helpers, red --after, the record run and the gate's reuse (parts 1100-1130). | #432, 8b6b36f9 |
| `claude/gf-a-blind2` | on main | Gate-friction A's addendum A1-A10, written blind (part 1130), with one unguarded cd guarded. | #432, c1463c7d |
| `claude/gf-a-blind3` | on main | Blind round 3 for gate-friction A: assertions for the eleven rules that no block held yet (C2.2, C2.6, C3.2, C4.2, C4.3, A8), plus the … | #432, e7bc96dc |
| `claude/gf-a-impl` | on main | PR A's first implementation: a record run starts red with itself, and a passed run leaves a suite receipt that the gate reuses. | #432, 7d2e3bdf |
| `claude/gf-a2` | on main | Contract A2 integrated: rule C9, its blind block (C9.1-C9.5), the review fixes C9-R1 to C9-R4, and three mutants killed, stacked on PR A. | #432, 541717f6 |
| `claude/gf-a2-blind` | on main | Contract A2's blind block, C9.1 to C9.5, which was red on the engine before C9. | #432, d7ee4e02 |
| `claude/gf-a2-impl` | on main | The implementation subagent branch for contract A2: rule C9, under which a gate receipt that reused a suite run merges only after the gate … | #432, fd508dab |
| `claude/gf-a3-blind` | on main | Contract A3's blind assertions (C10.1-C10.6) for the bridged tree id, on top of PR A with A2. | #433, c7c4228f |
| `claude/gf-a3-impl` | on main | Contract A3's implementation: a suite receipt stands across the one commit that records it, using a bridged tree id (rule C10). | #433, a3872088 |
| `claude/git-reads-fail-closed` | on main | Carrier slot 13: git reads of the working tree that do not finish (a FIFO, a failed read) are unknown, never an answer, across resolve, … | #447, c9a0fd36 |
| `claude/handoff-check-relative-path` | on main | bin/handoff-check, lifecycle-check and obligations-check find their libraries before cd-ing to the checkout top, so a relative call from a … | #405, d36ebd60 |
| `claude/locale-c-sort-comm` | on main | Carrier slot 21: sort and comm in route, inventory, ledger, memory and others run under LC_ALL=C so that comparisons agree with each other. | #436, #447, b434425f |
| `claude/magical-tharp-dd951e` | on main | Unattended repair fix: a repaired commit gets a gate verdict, the ceiling counts across pushes, and a workflow edit is refused before the … | #335, #391, 44c0e869 |
| `claude/monitor-capabilities-unread` | on main | Slot 9: the monitor's JSON and page say when the declared-capabilities list could not be read, never [] or 0. | #443, 248d9c7e |
| `claude/musing-ptolemy-753fe2` | on main | Extends gate invariant 1 so it catches ecosystem-specific code in the engine, not just project names. | #137, #141, 8228b101 |
| `claude/no-caller-env-in-tool-output` | on main | Carrier slot 14: every hook and the felix entry unset the caller variables that change tool output (GREP_OPTIONS, CDPATH, … | #447, 76213181 |
| `claude/no-diff-drivers-in-parsed-diffs` | on main | Carrier slot 13b, stacked on 13: diff.external, textconv and the other diff settings can no longer blind secret-scan or felix_tree_id … | #447, 34a4c77c |
| `claude/no-git-colour-in-parsed-output` | on main | Carrier slot 15, which carries 14 whole: GIT_CONFIG_PARAMETERS pins every color.* key to never for each git call the engine and hooks make, … | #447, 76213181 |
| `claude/pensive-goldstine-f2e04c` | on main | Moves the unborn-HEAD branch and commit readers into resolve.sh, so the receipt subject names the branch and says 'unborn' instead of 'HEAD … | #378, #267, 1b0074ac |
| `claude/qualify-nul-row-draft` | on main | An early draft of felix qualify refusing a qualification.tsv that holds a NUL byte, read once through cat, ending in a wip commit 8190f558 … | #383, 27573cbe |
| `claude/qualify-nul-row-tests` | on main | The blind test commit 1eedb8df: a NUL anywhere in qualification.tsv is refused whole by every qualify reader, by felix qualify and by felix … | #383, b5820d10 |
| `claude/qualify-scratch-cleanup` | on main | A qualification row's scratch tree never outlives the row (dropped with its bits restored, also on INT/TERM/HUP), riding on … | #394, #396, 494f7689 |
| `claude/quirky-heisenberg-fc2149` | on main | _felix_home_pointer trims only the two ends of the home pointer, so a home under a path with a space (iCloud Mobile Documents) resolves. | #447, 0db47b70 |
| `claude/recent-prs-commission-check-1429ca` | on main | Handoff section §0bw for the session of 2026-09-23/24: every stuck PR triaged, and the landing actor designed but not built. | #325, #326, 3c960522 |
| `claude/red-requires-reached` | on main | #371: tests/red refuses a suite that never printed `reached` instead of recording zero red, and _rt_judge decides the record checks … | #395, #371, f8442ff7 |
| `claude/relaxed-euler-cd49c2` | on main | A .felix marker that is present but does not resolve must refuse rather than read as ungoverned. | #136, #134 |
| `claude/setup-actions-node24` | on main | Moves the setup-node, setup-python and setup-go pins (and dtolnay's v1 sha) in bootstrap's rendered gate workflow to releases that run on … | #447, a0853c24 |
| `claude/slot-3f-exit-trap` | on main | The slot 3f fix (EXIT traps in parts 0001 and 0003 act only in the pid that made $TMP), blind part 0575, and its handoff note. | #449, 5ab64574 |
| `claude/snapshot-command` | on main | The unsquashed 28-commit history of the public-snapshot command: the audit is separate from the scrub, acknowledgements live in … | #284, 7a4e037b |
| `claude/strange-montalcini-e54797` | on main | Times the megabyte-line felix audit assertion in CPU seconds (5 s) instead of wall clock (15 s), so machine load cannot turn it red. | #355, f6cc3bc9 |
| `claude/suite-fixture-floor` | on main | Carrier slot 3: a tests/run fixture floor so that an empty fixture root under fork failure cannot run git writes on the real checkout (the … | #435, 59dcec28 |
| `claude/table-readers-keep-unended-line` | on main | Readers of a project's hand-edited tables keep an unended last row and open no pipe (done-< loops, [ -f ] before opens), with blind … | #418, 2f4cb396 |
| `claude/track-behaviorchangebench` | on main | Tracks projects/behaviorchangebench (constitution, project.json, tables) in the home, byte for byte as it stood untracked. | #361, #388, 2dc171de |
| `claude/youthful-lamarr-1c21f2` | on main | Base-version evaluation of enforcing tables, so a branch cannot add the green row that judges it (#5). Also carries the ^docs/ prefix fix … | #39, #42, 33627b82 |
| `docs/handoff-0ad` | on main | Handoff §0ad (the Stop hook's skipped-skills message names the play wrongly, and a shell word-split nearly produced a false bigger defect), … | #95, #29, 3e909b36 |
| `feat/pulse` | on main | felix pulse, a heartbeat and backup that runs without a session, through three review rounds, plus a follow-up fix so the shipped ~/.felix … | #116, #119, c37c9130 |
| `salvage/2026-10-27/agent-a15b8785c910d2bd2` | on main | Blind assertions (round 1) that the Stop hook holds a session once per tree (cf69588d). | #426, 97cdd50a |
| `salvage/2026-10-27/agent-a6b62cc893ccbe84c` | on main | A subagent's blind assertions (101, contract T1-T8/S/R/E/X/P/D) for slot 13: tree readers fail closed when git cannot read the tree. | #447, 653aab63 |
| `salvage/2026-10-27/agent-aa5026727973f189d` | on main | Blind assertions for felix cost, written from its contract while another agent wrote the command (one commit, 30a02ed7). | #423, 82999a84 |
| `salvage/2026-10-27/agent-abcdce6e7a5348484` | on main | A subagent's 20 blind assertions (O1-O6) for slot 14: no caller environment (GREP_OPTIONS, SHELLOPTS, CDPATH and the like) changes what an … | #447, 6cbc8301 |
| `salvage/2026-10-27/agent-ad44e156157efdd82` | on main | claude/qualify-rows-fresh-shell (each qualification column runs in a bash of its own, and a column that ran nothing reads unrunnable), plus … | #394, #396, a7873475 |
| `salvage/2026-10-27/agent-ad4cc59f499274ac9` | on main | A subagent's blind assertions (C1-C6, C8) for slots 10 and 11: a commissioning check that exits 2 could not be asked, so it reads unknown … | #443, 8f9644da |
| `salvage/2026-10-27/agent-af8f461d31fa6530a` | on main | The hold-once blind assertions plus the addendum round (reason, checkout, night, mark after print, person's prompt, link), in commits … | #426, 97cdd50a |
| `salvage/2026-10-27/agent-afc133b4976fdc7cb` | on main | Blind, red-first part 0575 for slot 3f: the suite's EXIT trap removes $TMP only in the shell that set it. | #449, 96074341 |
| `salvage/2026-10-27/carry-3c-locale` | on main | A half-finished merge, from an early attempt to carry slot 3c (locale sweep) onto 3+3b's carry (60565c23); the wip(salvage) commit 79f6883d … | #435, #436, b0ea2150 |
| `salvage/2026-10-27/wf_09de129d-71a-1` | on main | A locale workflow worktree: slot 21's commits plus 3c's bash collation, BSD tools, verdict-site and digit-bracket fixes. | #436, 568da303 |
| `salvage/2026-10-27/wf_6e4f8fea-6c8-2` | on main | The fullest locale workflow worktree: slot 21 plus 3c's blind blocks, digit brackets, pointers and the review round (deny reader, gate … | #436, 568da303 |
| `salvage/2026-10-27/wf_c65a24cb-ab3-1` | on main | A locale workflow worktree: slot 21's C-locale sort/comm/join/uniq commits, plus one fix so bash collation and the BSD text tools read … | #436, 11038e4c |
| `salvage/fold-count-read-not-grepped` | on main | Rewords the ledger fold count and the session-start qualifier to describe what is actually counted, and adds assertions that read the … | #185, #226, 7c3b924d |
| `salvage/lifecycle-recorder` | on main | Two wip commits (blind assertions, then lib/lifecycle.sh) for the lifecycle.log recorder, written at every SessionStart and every felix … | #281, d0b162f0 |
| `salvage/snapshot-command` | on main | The first commit of the public-snapshot command (projects/felix/snapshot.sh), pushed today from a local worktree. | #284, 2d0e86ac |
