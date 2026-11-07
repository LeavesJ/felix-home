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
- **The tick's quiet check** (added after the first review). `_gt_refuse`
  (`lib/green-tick.sh`) builds a refused row's detail from the first block line,
  kind and its column padding included, and stays silent (no desktop banner, no
  notifier attempt) when the pull request's previous row (any event, `waiting`
  rows read past) is a refused row with the same head and the same detail up to
  ` [main `, whatever main was. It reads the kind's name (K14). The notifier's `_fn_same` (`lib/notify.sh`, B8) compares an
  event's kind, pull request and detail with the newest dispatched record; it is
  reached only for an event the tick did not keep quiet (L7).
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
- **Readers of `alerts.tsv`** (added after the first review): `_fn_missed`
  (the dispatched comment's "Not delivered before this one" line), `felix
  status`'s alerts row and the session-start alert line print a record's kind as
  recorded (K10).
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
  unchanged. Pinned whole (Round 2): for a receipt that is stale because the tree
  changed, and for one that is stale because a fact it rests on moved, the reason
  is `felix_verify_current`'s second field, whole and including any text after a
  `;`; for a red receipt for this exact tree, and for no receipt, it is
  `no green receipt for this exact tree; run felix gate`.
- **K2 The blocker, tests.** Where it printed `unverified\ttests\t<reason>` it
  prints `not-green\ttests\t<reason>`. The reason, which begins
  `the gate reused a suite run for this tree (tests:reused), and the gate workflow has not passed on `,
  and the condition (a current green receipt that reports `tests:reused` while
  the gate workflow has not passed on the head) are unchanged. Only a current
  green receipt raises the line (Round 2): a red receipt for this exact tree, and
  a stale receipt, each reporting `tests:reused` with the gate workflow failed on
  the head, print the one `not-green tree` line and no `tests` line, and
  `felix merge` makes no `gh` call for either.
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
  head and main at its end, not the kind. This holds on each of the three
  clauses (Round 2), a refused row of either name being held on the head and
  main it records: an hourly row for an hour; a receipt-clause row while the
  retry record holds its head, its main and the receipts' sums from before its
  run, and run again when a receipt is written or when the record is missing or
  names another head or main; a final row until the head or main moves. A row
  written before the deploy records a main the deploy has passed, so the first
  tick after the deploy runs it again whatever its clause.
- **K7 The ledger kind.** Each of the five calls of `_gt_unverified` (pull,
  install, diff, hook check, gate) writes a `deploy-failed` row instead, with the same detail (its `pull:`,
  `install:`, `diff:`, hook-check or `gate:` text), the same wall time, and the
  same `paused` row and `paused` file holding the same reason. The detail is
  the failing step's message whole, as before (Round 2): `pull: git pull --ff-only
  failed: ` and git's first line; `install: felix install --no-bump failed: ` and
  the install's last line; `gate: felix gate --quick exited <rc> in the home`.
  No path writes
  a row of kind `deployed-unverified`. A deploy whose steps and checks pass
  still writes `deployed`, and one that is owed still writes `deploy-owed`.
- **K8 The notification.** A `deploy-failed` row raises the desktop
  notification titled `Felix: deploy-failed`, and starts a notifier attempt, as
  the old kind did. The kinds a person is notified of are otherwise the same
  (Round 2): each kind on `_gt_say`'s list on main 0.49.328 other than the renamed
  one (landed, refused, founder, waiting, deployed, paused, resumed, installed,
  uninstalled, timeout, stuck, unaged, gh, fetch, deploy-owed, unresolved) still
  raises the banner titled `Felix: <kind>` when a row of it is written (except a
  refused row the tick's quiet check holds back, K14);
  `resumed`, `installed` and `uninstalled` start no notifier attempt; a kind not
  on the list raises neither.
- **K9 The notifier.** `_fn_sentence deploy-failed` prints exactly
  `A deploy of main stopped at a failed step or check, and landing is paused.`
  and returns 0. `_fn_sentence deployed-unverified` prints exactly the same
  sentence and returns 0, so an event of the old kind recorded before the
  deploy is still sent. Every other kind's sentence is unchanged (Round 2, word
  for word: founder `A green pull request changes a direction document and waits for your yes.`;
  deployed `The engine on main was installed and passed its deploy checks.`;
  stuck `A tick has held the lock for more than 45 minutes.`;
  timeout `A tick ran past its time limit and was stopped.`;
  unresolved `The tick resolved no project, so nothing lands.`;
  fetch `The home could not fetch its origin, so nothing lands.`), and a kind
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
  part read it). No reader drops or reorders a row for its kind. The readers of
  `alerts.tsv` do the same (Round 2): `felix status`'s alerts row, the
  session-start alert line and the dispatched comment's count line name a
  `deployed-unverified` record as recorded, as they name a `deploy-failed` one,
  and none decides anything by which of the two names a record holds.
- **K11 What is decided is unchanged.** Which trees `felix merge` refuses, which
  paragraph closes a block, which refusals the lander retries and when, which
  deploys complete, which ones pause landing, and which events a person is
  notified of do not change. Only the two names change, and three places
  widen to accept the old name: K5's `_gt_class`, K9's `_fn_sentence` and K14's
  quiet check in `_gt_refuse`.
- **K12 The class, not the instance.** After this change the two old names
  appear in the engine directory under test (as C18 of the 2026-10-31
  contract reads it: tracked files outside `harness/tests/`, comments
  skipped except in Markdown) only in these places, and only as shown:
  - `deployed-unverified)`, the case label that accepts the old ledger kind, in
    `harness/lib/notify.sh`;
  - `$1 == "unverified"`, the clause that accepts the old blocker kind, in
    `harness/lib/green-install.sh`;
  - `  unverified  ` (the name between two blanks on each side: the kind in its
    column as a block line prints it), as the one line of `harness/lib/green-tick.sh`
    by which the quiet check builds the old form of a refusal from the new one
    (K14). No other line of that file, and no other file, holds the name between
    two blanks.

  `_gt_unverified` appears nowhere. `deployed-unverified` appears nowhere else
  (`green-tick.sh` no longer holds it). `unverified\t` appears nowhere
  (`escape.sh` no longer holds it; `unverified` followed by a tab, or by the two
  characters backslash and t, as a printf spells it). Part 2300's and part 2301's allowed lists
  are narrowed to match: the entries `deployed-unverified` (in `green-tick.sh`
  and `notify.sh`), `'unverified\t` (in `escape.sh`) and `== "unverified"` (in
  `green-install.sh`) are gone, and the three entries above replace them. The
  class check is shown to fail on each removed entry in the file that used to
  allow it, and to pass on each new entry in its own file; part 2300's check and
  part 2301's model of it both show it (Round 2). Run over the real engine the
  check reads at least fifty files and ends with status 0, so a check that read
  nothing cannot pass (Round 2).
- **K13 Comments and the older contract.** A comment in the files this change
  edits that names a renamed value is updated with it. The 2026-10-31
  contract's "What keeps its name, and why" says the two kinds moved, and names
  this contract.
- **K14 A refusal that stands across the deploy stays quiet (Round 2).** The
  tick's quiet check in `_gt_refuse` reads a previous row (as the quiet check
  always has: the pull request's last row of any event but `waiting`) that is a
  refused row whose detail begins `  unverified  ` (two blanks, the old name, two blanks: the old kind in
  its column) as one that begins `  not-green   ` (two blanks, the new name,
  three blanks), when the rest of the detail, the head and the clause are the
  same. So a pull request refused before the deploy and refused again after it,
  on the same head, for the same blocker and the same clause, with no row of
  another event between the two refusals, raises no desktop banner and starts
  no notifier attempt, as when main moves and no name changes. A refusal whose
  blocker, head or clause differs is announced as before; so is a refusal after
  a row of another event (a skip, a session or a founder row), as before; and a
  previous row of any other kind is read as before. The notifier's own check
  (B8) is not widened (L7).

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
  would have answered `receipt` or `hourly` (an hourly block as well as a
  receipt block). The tick runs `felix merge` from the cache entry of main's
  version (`_GT_VER`, read after the tick's own fetch), and the code that reads
  its output is the engine the tick itself runs from. A tick that finds a
  deploy owed deploys and stops, and a tick that lands a change to `engine/`
  deploys it and stops (A11), so no tick reads this change's block with an
  older engine except one started from the old entry that finds, after its
  fetch, main's new entry accepted and the home already at main. The tick that
  deploys this change is not that window. A refusal classed `final` there stays
  `final` after the deploy, because the hold reads the clause, until the head
  or main moves. It decides no merge.
- **L3, records.** Ledger rows, `says.log` rows and `alerts.tsv` rows written
  before the deploy keep the old kinds, and readers print them as recorded
  (K10). A re-measurement over ledgers written across the deploy has to fold
  `unverified` with `not-green` and `deployed-unverified` with `deploy-failed`.
- **L4, the notifier accepts a kind nothing sends.** `_fn_sentence` keeps
  `deployed-unverified` for rows recorded before the deploy. No caller of the
  notifier passes an old row's kind back to it today. The label is a reader
  kept for the instruction that every reader accept old rows.
- **L6, the deploy of this change runs the engine before it.** The trampoline
  runs the entry of the version `origin/main` last had when the home fetched,
  and the handmerge path runs the home's own engine. So a failed step or check
  of the deploy that installs this change is written, notified and dispatched
  by the older engine, as `deployed-unverified`, unless `origin/main` was
  fetched by any worktree (the refs are shared) and main's new entry was
  already installed and accepted, in which case the new engine writes
  `deploy-failed`. A retry the handmerge path runs after a resume is the older
  engine's again, so more than one `deployed-unverified` row can be written.
  Every deploy after that writes `deploy-failed`, and the readers list each
  such row as recorded (K10).
- **L7, the notifier's no-repeat check, and the trampoline's copy.** B8 is not
  widened: a `refused` event whose detail names `not-green`, announced while the
  newest dispatched record holds the same event under `unverified`, is
  dispatched once more. The tick's quiet check (K14) keeps the usual case from
  reaching the notifier; what B8 would still see is a refusal the tick announces
  although the newest dispatched record holds the same event under `unverified`
  (for example after a row of another event between two refusals). The same
  holds for the ledger kind: a `deploy-failed` event whose newest dispatched
  record is the same failure under `deployed-unverified` is dispatched once
  more. Each is at most one extra comment, once, for the pull request or the
  deploy.
  Separately, the installed trampoline holds the copy of `lib/notify.sh` that
  the last `felix land --install` wrote, and no deploy rewrites it. It starts
  attempts only for `deploy-owed` and `unreadable`, whose sentences this change
  leaves alone, so K8 and K9 are claims about the tick's `lib/notify.sh`, and
  the trampoline's copy carries `deploy-failed` after the next `felix land
  --install`.
- **L5, what the class check cannot see.** It reads five words (verified,
  unverified, proven, unproven, proves) by the rules of the 2026-10-31
  contract. `not-green` and `deploy-failed` are not in it, and it cannot say
  that a name is true.

## How it is tested

- **Blind.** Two parts, written from this contract alone, red against the
  code they were written before: `tests/parts/2320-not-green-deploy-failed-blind.sh`
  (K1 to K12, before the change, red against main; its assertion names start
  `ngd A`) and `tests/parts/2321-not-green-deploy-failed-round2-blind.sh` (the
  Round 2 sentences of K1, K2, K6 to K10 and K14, red against the head that
  carried K1 to K13; its names start `ngd2 A`). Each clause has at least one
  assertion. A clause that forbids a name asserts both the old and the new
  name, so a check cannot pass by finding neither.
- **Existing parts.** The parts that read the two kinds (0100, 0360, 0510, 0990,
  1250, 1650, 1665; 1281 to 1289, 1660, 2120) match the new names, in their
  data and in the names of their assertions. The negative checks the first
  review found that refused an old name or counted its rows at zero (1284, 1285,
  1286, 1665) count the new name's rows too, so those do not go vacuous. Part 0100 reads the blocker kinds out of `escape.sh` with a pattern
  that admits lower-case letters only, which would skip `not-green`; it admits
  the hyphen. Parts 2300 and 2301 follow K12.
- **Count.** No edited part has fewer lines matching
  `projects/felix/risk.tsv`'s assertion count (`^[[:space:]]*(ok|is|has|bad) `)
  than it had at base.
- **Review.** An adversarial review of the change, then its fixes go to a
  blind author who has this contract and not the review. Round 2 is the
  contract's answer to that review; the edits to existing parts that the review
  asked for and that need no new behaviour (the checks that counted an old
  kind's rows at zero count the new kind's rows too, assertion names say the
  kind they assert, part 2301 shows K12 on its own fixtures, part 2320's scan of
  the real engine ends with status 0 over at least fifty files) are made by the
  author of the change and named as such in the pull request.
- **The record and the gate** at the head the pull request carries.
