### 2026-11-07: the two kinds #482 kept say what is true: `not-green` and `deploy-failed` (0.49.334)

**What changed.** #482 rewrote the sentences the engine prints that said
verified, unverified, proven or unproven (its contract counts them), and kept two kinds because each had
readers and recorded rows. Both are printed to a person, so they moved together:
- the merge blocker kind `unverified` is **`not-green`** (`lib/escape.sh`: two
  `tree` printfs and one `tests`);
- the ledger kind `deployed-unverified` is **`deploy-failed`**, and
  `_gt_unverified` is `_gt_deploy_failed` (`lib/green-tick.sh`, five call sites,
  `lib/notify.sh`'s sentence table).

**Why those names, and why not `unchecked`.** `not-green` is raised when
`felix_verify_current` answers anything but `current`: no receipt, a stale one,
or a red one. It answers `red` before it compares trees, so a red receipt for
this exact tree is among them, and `unchecked` would be false there (the gate
ran and failed). That is the fault round 3 of the 2026-10-31 contract found in
the receipt's `unverified`. `deploy-failed` is true for a deploy whose step
failed or whose check failed; `deployed-unchecked` would be false (the checks
ran and failed, or the step never reached them), and the notifier's own
sentence already said it. Contract:
`docs/2026-11-07-not-green-deploy-failed-contract.md` (K1 to K14, L1 to L7).

**Readers, found first (grep over the engine, hooks, `.github/`,
`projects/*/gate.sh`, `templates/`, the suite and `~/.claude/mods`).**
- Blocker kind: one machine reader, `_gt_class` (`lib/green-install.sh`), now
  reads either name, or both mixed, the same. `cmd_merge`, `_gt_detail`,
  `lib/waiting.sh` and `felix land --status`/`--prs` print the kind as recorded.
- Ledger kind: `_gt_say`'s list and `_fn_sentence`'s table. `_fn_sentence` still
  answers `deployed-unverified` with the same sentence.
- Found by the first adversarial review, not by the first survey: the tick's
  quiet check (`_gt_refuse`) compares the detail with the previous refused row
  byte for byte, kind and column padding included, so a refusal that stood
  across the deploy would have raised a second banner and a second notifier
  attempt (K14 reads `  unverified  ` as `  not-green   ` there). And the
  readers of `alerts.tsv` print a record's kind as recorded (K10).
- Rows already on disk keep their kinds: the ledger, `says.log` and
  `alerts.tsv` are append-only, and the readers found accept the old names (K5,
  K6, K9, K10). A re-measurement over ledgers across the deploy has to fold
  `unverified` with `not-green` and `deployed-unverified` with `deploy-failed`.

**What keeps its name.** `subagent-unverified`, `state/verified/`, the ledger
kinds `deployed` and `deploy-owed`, and the blocker kinds other than
`unverified`.

**Old names left in the engine, by design (K12, class lint C18 in parts 2300
and 2301).** Three places only: `deployed-unverified)` in `lib/notify.sh`,
`$1 == "unverified"` in `lib/green-install.sh`, and `  unverified  ` in
`lib/green-tick.sh` (the quiet check). Each is a reader kept so old rows read.

**Stated limits.** L1: this reaches `lib/escape.sh`, the merge boundary's
judge, and no automatic check can show an outside reader of `felix merge`'s
block harmless; none is known. The pull request therefore opens as a draft
labelled `needs-founder`. L2: an older engine reading a `not-green` block
classes it `final` (a narrow window; decides no merge). L6: the deploy of this
change is run by the engine before it, so a failed step of that one deploy
writes `deployed-unverified`. L7: the notifier's no-repeat check is not
widened, and the installed trampoline's copy of `notify.sh` carries
`deploy-failed` only after the next `felix land --install`.

**Built.** Method: contract, blind red-first part, implementation, adversarial
review, fixes through a blind author, record, gate.
- Survey, contract, implementation, edits to the 17 existing parts and the
  lint parts: this session (Sonnet 5.5).
- Blind part 2320 (K1 to K12, 71 assertions, red against main): Opus 5.5,
  xhigh, isolated worktree (`wf_757fff4d-980`).
- Adversarial review of the first build: three lenses at Opus 5.5 xhigh, seven
  skeptics at Opus 5.5 high (`wf_debd3e01-ef0`). Seven findings confirmed in
  four themes, none refuted, twelve low. The one design finding was K14; the
  rest were assertions that did not pin the clauses (reasons whole, `tests`
  line only for a current receipt, the hold clauses, every kind on `_gt_say`'s
  list) and part 2301's model of the class check.
- Round 2 contract and blind part 2321 (42 assertions): Opus 5.5, xhigh,
  isolated worktree (`wf_5f7ad5e2-314`). Shown red at the head without K14 (the
  two K14 assertions fail, the rest pass), green at the head with it (104 ok).
  The pins that already held on the first build were checked by mutation: the
  review's three `sed` mutants (`stuck` dropped from `_gt_say`'s list, the stale
  reason cut at its `;`, the `tests:reused` condition widened) each fail it, and
  the author listed a mutation for each pin and ran them in batches (for the six
  sentence pins A9 to A14, only A11's).
- Round 2 review (fault round 1 of the two the lane budget allows): two lenses at
  Opus 5.5 xhigh, two skeptics at Opus 5.5 high (`wf_9411d430-a28`). Two
  findings confirmed, both low, both contract wording: K11's closing sentence
  named two readers of the old name where three exist, and the quiet check
  compares with the pull request's previous row of any event but `waiting`,
  not its previous refused row. Six low: K8 and K6 wording, L6's window, B8 for
  the ledger kind (all now in the contract), and the class lint's allowance,
  which is now the quiet check's one line rather than the text anywhere in
  `green-tick.sh` (with fixtures in 2300, 2301 and 2320 that fail on any other
  line or file). No third round: the next fault class would live in shared code.
- Mechanical edits made by the author of the change, from the review: the
  zero-count checks in 1284, 1285, 1286 and 1665 count both ledger kinds; four
  assertion names say `not-green`; part 2301 shows K12 on its own fixtures;
  part 2320's scan of the real engine has a read control (status 0 over at
  least fifty files).
- Merged `origin/main` into the branch four times while it was open: #487
  (0.49.329), then #493 (docs) and #486 (0.49.330), then #496 (trust-plane step 3,
  0.49.332), then #497 (step 3, slice 2, 0.49.333). The driver stays at 500 lines
  (blank lines removed). #496 brought a `home` blocker into `lib/escape.sh` and
  part 2176 that named the old kind; both say `not-green` here. #497 rewrote
  `_gt_class` in `lib/green-install.sh` to hold a `base provider` block hourly; it
  keeps that rule and reads `not-green` and the old `unverified` the same (version
  0.49.334). Parts 0100 and 2320 read the merge boundary's kinds from
  `felix_merge_blockers`, the body it calls and `lib/policy.sh`, as main's 0100
  does; part 2320's A8 was edited by the author of the change for that, not by a
  blind author, as were the two call sites in 2176.
