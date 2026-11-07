# Not green, deploy failed: the two kinds that kept their names

Contract for the two event kinds that
`docs/2026-10-31-checked-not-verified-contract.md` ("What keeps its name, and
why") left for a change of their own, under the founder's decision 1 of
2026-10-31 ("Checked, in every text"; direction row 36 in draft #481). Both
kinds are printed to a person, so they move together. Adversarial tier: it
changes `lib/escape.sh` (the merge boundary's judge), `lib/green-install.sh`,
`lib/green-tick.sh` and `lib/notify.sh`.

Scope: the merge blocker kind `unverified`, and the land ledger kind
`deployed-unverified` with the function `_gt_unverified`. Any other name the
2026-10-31 contract kept (`subagent-unverified`, `state/verified/`) is outside
this change and stays open there.

## What happened

#482 changed the sentences the engine prints to a person that said verified,
unverified, proven or unproven (its contract counts them), and kept two kinds
because each has readers, recorded rows and ledger history. A person reads
both:

- `felix merge` prints the blocker kind, and so does the session-start list of
  waiting pull requests, which reprints the ledger's `refused` rows;
- `felix land --status` lists ledger rows by kind, and the comment the notifier
  sends to the standing issue starts `@<owner> Felix land: deployed-unverified`.

On main 0.49.328 these four places still say `unverified`.

## The new names, and why

- The merge blocker kind is **`not-green`**. The kind means "no green receipt
  for this exact tree" (the comment above `felix_merge_blockers` said so). It
  is raised when `felix_verify_current` answers anything but `current`: no
  receipt, a stale one (the tree changed, or a fact the receipt rests on
  moved), or a red one (it answers `red` before it compares trees, so a red
  receipt for this exact tree is among them). It is also raised for a current
  green receipt that reused a suite run when the gate workflow has not passed.
  `unchecked` would be false for the red case, where the gate ran and failed.
  That is the fault round 3 of the 2026-10-31 contract found in the receipt's
  `unverified` (its C8). `not-green` is true in each of these cases, and
  "green" and "red" are the words the gate's own result already uses.
- The ledger kind is **`deploy-failed`**, and the function is
  **`_gt_deploy_failed`**. The row is written when a step of a deploy (the
  pull, the install, the comparison of the cache entry with main's engine, the
  hook check, `felix gate --quick`) failed or a check of it failed, and landing
  pauses. The notifier's fixed sentence already says it
  (`A deploy of main stopped at a failed step or check, and landing is paused.`).
  `deployed-unchecked` would be false: the checks ran and failed, or the step
  never reached them.

## Who reads what changes

Found by grep over the engine, its hooks, `.github/`, `projects/*/gate.sh`,
`templates/`, the suite and `~/.claude/mods`, before anything was changed.

**The blocker kind `unverified`**

- **Producer.** `felix_merge_blockers` (`lib/escape.sh`): two printf calls for
  `tree` (the `stale*` branch and the default branch) and one for `tests`.
- **The one machine reader of the printed block.** `_gt_class`
  (`lib/green-install.sh`). It reads the output of `felix merge` that the tick
  runs from the cache entry of main's version, and keys on the first field of
  each block line: `unverified` (and its second field `tests`), or
  `commission receipt`; any other line makes the class `final`.
- **Printers, by kind, not by name.** `cmd_merge` (`felix`) prints each block
  line through `'  %-11s %-22s %s'` and records one `refused` say row per kind
  (`<branch>: <kind>: <reasons joined>`). A kind it does not name counts as
  work Felix owes (`owed=1`). `_gt_detail` (`lib/green-tick.sh`) copies the
  first block line into the ledger's `refused` row. `lib/waiting.sh` and
  `felix land --status` / `--prs` print that detail as recorded.
- **`_gt_held`** reads the clause at the end of a refused row's detail and the
  head and main it records. It never reads the kind.
- The grep found nothing in `.github/`, `projects/*/gate.sh`, `templates/`, a
  hook or `~/.claude/mods` that names the kind. The suite reads it: parts 0100, 0360, 0510,
  0990, 1250, 1650 and 1665.

**The ledger kind `deployed-unverified` and `_gt_unverified`**

- **Producer.** `_gt_unverified` (`lib/green-tick.sh`), called by the deploy at
  five places (pull, install, diff, hook check, gate), writes the row and
  pauses landing.
- **`_gt_say`** (`lib/green-tick.sh`) holds the list of kinds a person is
  notified of. The kind is on it. It is a filter on a row being written; its
  two callers (`_gt_row`, and the trampoline's `unresolved`) pass a row being
  written now.
- **`_fn_sentence`** (`lib/notify.sh`) is the notifier's table of fixed
  sentences by kind. `_fn_attempt` refuses a kind it has no sentence for.
  The callers found pass the kind of an event being written now.
- **Readers of rows by kind** (`felix land --status`, `--prs`, `lib/waiting.sh`,
  `lib/status-land.sh`, `lib/pr-status.sh`, `lib/green-wait.sh`): none names the
  kind. They print the second field as recorded. `felix land --status` prints it
  with `%-19s`, which was sized for `deployed-unverified`; the new kind is
  shorter, so the layout holds.
- The grep found no other reader: `.github/` and the project gates hold neither
  name.
- The suite reads it: parts 1281, 1282, 1283, 1284, 1285, 1286, 1288, 1289,
  1660, 1665 and 2120.

## What must hold

`\t` is a tab. Text a clause does not quote is unchanged.

- **K1 The blocker, tree.** Where `felix_merge_blockers` printed
  `unverified\ttree\t<reason>` it prints `not-green\ttree\t<reason>`, in both of
  the branches that printed it. The reason and the condition that raises it are
  unchanged.
- **K2 The blocker, tests.** Where it printed `unverified\ttests\t<reason>` it
  prints `not-green\ttests\t<reason>`. The reason, which begins
  `the gate reused a suite run for this tree (tests:reused), and the gate workflow has not passed on `,
  and the condition (a current green receipt that reports `tests:reused` while
  the gate workflow has not passed on the head) are unchanged.
- **K3 What `felix merge` prints.** The block's lines for K1 and K2 are laid
  out as before, for example
  `  not-green   tree                   no green receipt for this exact tree; run felix gate`.
  No line of the block begins with `unverified` once blanks are skipped. The
  kinds `felix_merge_blockers` can print are `commission`, `escape`,
  `evidence`, `obligations`, `probes`, `unknown` and `not-green`. The exit
  status, the closing paragraphs, the count of escapes and the choice of which
  paragraph closes the block are unchanged. A dry run and a real run print the
  same block.
- **K4 The refusal row.** A real `felix merge` that refuses for K1 or K2 writes
  the `refused` say row `<branch>: not-green: <subject>: <reason>` (the reasons
  of the kind's lines joined with `; `), where it wrote
  `<branch>: unverified: <subject>: <reason>`.
- **K5 The lander's class of a refusal.** `_gt_class STATUS OUTPUT` answers as
  before with `not-green` where `unverified` stood: with status 3 and a block
  of `not-green` and `commission receipt` lines only, `receipt`; with a
  `not-green tests` line among them, `hourly`; with status 3 and any other
  line, or no block, `final`; with any other status, `hourly`. **A block written
  by an engine older than this change is classed the same:** the same blocks
  with `unverified` in place of `not-green`, and blocks that mix the two names,
  get the same class.
- **K6 Rows recorded under the old blocker kind.** A `refused` ledger row whose
  detail begins `unverified` (written before the deploy) is held and lifted
  exactly as one that begins `not-green`: the hold reads the clause and the
  head and main at its end, not the kind.
- **K7 The ledger kind.** Each of the five calls of `_gt_unverified` (pull,
  install, diff, hook check, gate) writes a `deploy-failed` row instead, with the same detail (its `pull:`,
  `install:`, `diff:`, hook-check or `gate:` text), the same wall time, and the
  same `paused` row and `paused` file holding the same reason. No path writes
  a row of kind `deployed-unverified`. A deploy whose steps and checks pass
  still writes `deployed`, and one that is owed still writes `deploy-owed`.
- **K8 The notification.** A `deploy-failed` row raises the desktop
  notification titled `Felix: deploy-failed`, and starts a notifier attempt, as
  the old kind did. The kinds a person is notified of are otherwise the same.
- **K9 The notifier.** `_fn_sentence deploy-failed` prints exactly
  `A deploy of main stopped at a failed step or check, and landing is paused.`
  and returns 0. `_fn_sentence deployed-unverified` prints exactly the same
  sentence and returns 0, so an event of the old kind recorded before the
  deploy is still sent. Every other kind's sentence is unchanged, and a kind
  with none still returns 1. The comment the notifier dispatches for a
  `deploy-failed` event begins `@<owner> Felix land: deploy-failed` and holds
  the sentence below it, before the details line.
- **K10 Rows recorded under the old ledger kind.** `felix land --status`
  (both forms), `felix land --prs` and the session-start list of waiting pull
  requests list a ledger that holds `deployed-unverified` rows exactly as they
  list one that holds the same rows under `deploy-failed`: the kind as
  recorded, in the same columns, with the same detail. These readers name a
  ledger's newest row and the last row of each pull request, not every row, so
  a ledger that holds both kinds lists whichever row is newest as recorded,
  whichever kind it has and whichever came first (clarified after the blind
  part read it). No reader drops or reorders a row for its kind.
- **K11 What is decided is unchanged.** Which trees `felix merge` refuses, which
  paragraph closes a block, which refusals the lander retries and when, which
  deploys complete, which ones pause landing, and which events a person is
  notified of do not change. Only the two names change, and the two places K5
  and K9 widen to accept the old name.
- **K12 The class, not the instance.** After this change the two old names
  appear in the engine directory under test (as C18 of the 2026-10-31
  contract reads it: tracked files outside `harness/tests/`, comments
  skipped except in Markdown) only in these places, and only as shown:
  - `deployed-unverified)`, the case label that accepts the old ledger kind, in
    `harness/lib/notify.sh`;
  - `$1 == "unverified"`, the clause that accepts the old blocker kind, in
    `harness/lib/green-install.sh`.

  `_gt_unverified` appears nowhere. `deployed-unverified` appears nowhere else
  (`green-tick.sh` no longer holds it). `unverified\t` appears nowhere
  (`escape.sh` no longer holds it; `unverified` followed by a tab, or by the two
  characters backslash and t, as a printf spells it). Part 2300's and part 2301's allowed lists
  are narrowed to match: the entries `deployed-unverified` (in `green-tick.sh`
  and `notify.sh`), `'unverified\t` (in `escape.sh`) and `== "unverified"` (in
  `green-install.sh`) are gone, and the two entries above replace them. The
  class check is shown to fail on each removed entry in the file that used to
  allow it, and to pass on each new entry in its own file.
- **K13 Comments and the older contract.** A comment in the files this change
  edits that names a renamed value is updated with it. The 2026-10-31
  contract's "What keeps its name, and why" says the two kinds moved, and names
  this contract.

## What keeps its name

- The say kind `subagent-unverified` and the directory `state/verified/`, as the
  2026-10-31 contract kept them.
- Rows already on disk. The ledger, `says.log` and `alerts.tsv` are
  append-only. Their old rows keep the old kinds (L3).
- The ledger kinds `deployed` and `deploy-owed`, and the blocker kinds other
  than `unverified`.
- The names of functions the 2026-10-31 contract kept, other than `_gt_unverified`.

## Stated limits

- **L1, high-stakes (`lib/escape.sh`).** A reader outside this repository that
  parses `felix merge`'s printed block, the `refused` say rows or the ledger
  and keys on `unverified` or `deployed-unverified` now meets `not-green` or
  `deploy-failed`. None is known: the grep above found nothing in the engine,
  its hooks, its CI, `templates/`, a project gate or `~/.claude/mods` that
  reads either name except the readers this change widens, and the memory
  notes that name them are prose. No automatic check can show an outside reader harmless, and the
  change reaches the merge boundary's judge, so the pull request opens as a
  draft labelled `needs-founder` (decision 5, Felix's interim reading).
- **L2, an older engine reading this one.** An engine older than this change,
  reading a block of `not-green` lines, does not know the name: its
  `_gt_class` counts the line as another kind and answers `final` where it
  would have answered `receipt` or `hourly`. The tick runs `felix merge` from
  the cache entry of main's version (`_GT_VER`), and the code that reads its
  output is the engine the tick itself runs from. The two can be different
  versions while the tick runs from an engine older than main's, which is the
  deploy of this change itself. A refusal in that window is held until the head
  or main moves, instead of until a receipt is written. It decides no merge.
- **L3, records.** Ledger rows, `says.log` rows and `alerts.tsv` rows written
  before the deploy keep the old kinds, and readers print them as recorded
  (K10). A re-measurement over ledgers written across the deploy has to fold
  `unverified` with `not-green` and `deployed-unverified` with `deploy-failed`.
- **L4, the notifier accepts a kind nothing sends.** `_fn_sentence` keeps
  `deployed-unverified` for rows recorded before the deploy. No caller of the
  notifier passes an old row's kind back to it today. The label is a reader
  kept for the instruction that every reader accept old rows.
- **L5, what the class check cannot see.** It reads five words (verified,
  unverified, proven, unproven, proves) by the rules of the 2026-10-31
  contract. `not-green` and `deploy-failed` are not in it, and it cannot say
  that a name is true.

## How it is tested

- **Blind.** One part, `tests/parts/2320-not-green-deploy-failed-blind.sh`,
  written from this contract alone before the change, red against main. Its
  assertion names start `ngd A`. Each clause K1 to K12 has at least one
  assertion. A clause that forbids a name asserts both the old and the new
  name, so a check cannot pass by finding neither.
- **Existing parts.** The parts that read the two kinds (0100, 0360, 0510, 0990,
  1250, 1650, 1665; 1281 to 1289, 1660, 2120) match the new names, in their
  data and in the names of their assertions. Every negative check that refused
  an old name or counted its rows at zero refuses the new name too, so none goes
  vacuous. Part 0100 reads the blocker kinds out of `escape.sh` with a pattern
  that admits lower-case letters only, which would skip `not-green`; it admits
  the hyphen. Parts 2300 and 2301 follow K12.
- **Count.** No edited part has fewer lines matching
  `projects/felix/risk.tsv`'s assertion count (`^[[:space:]]*(ok|is|has|bad) `)
  than it had at base.
- **Review.** An adversarial review of the change, then its fixes go to a
  blind author who has this contract and not the review.
- **The record and the gate** at the head the pull request carries.
