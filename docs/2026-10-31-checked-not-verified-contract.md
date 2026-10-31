# Checked, not verified: the engine's own words

Contract for the text the engine prints and commits, under the founder's
decision 1 of 2026-10-31 ("Checked, in every text"; direction row 36 in draft
#481). Adversarial tier: it changes `hooks/stop`, `hooks/subagent-stop`,
`lib/receipt.sh`, `lib/verify.sh` and the land tick's sentences.

## What happened

On 2026-10-31 the founder chose "Checked, in every text": receipts, pitches and
applications say a change was checked against a stated list of faults, over a
printed number of cases, with what stayed unchecked listed. Felix never says
"verified" or "proven". Until the evidence engine exists, by Felix's interim
reading, a text says what ran (the gate, its suite) and names no fault list or
case count. The direction fold (#481) changed the README and the constitution
and left the engine's texts to this change.

On main 0.49.319 (deca9fdc), 32 lines of the files git tracks under `engine/`,
outside `engine/harness/tests/` and not starting with `#`, hold verified,
unverified, proven or unproven as a whole word. Twenty-one of them say it to a
person; the other eleven are names (below, "What keeps its name").

## Who reads what changes

Found by grep over the engine, its hooks, its CI, `projects/*/gate.sh` and the
suite, before anything was changed.

- **The receipt's `status`** (`lib/receipt.sh`). `felix receipt` prints it.
  Nothing in the engine, its hooks, its CI or any project gate reads it back:
  `felix merge`, `felix land` and the gate read the gate receipt that
  `lib/verify.sh` writes, a different file. The suite reads it in part 0370
  (three refusals of `verified`) and parts 1830 and 1832 (`indeterminate`).
  Draft #476, doc only, describes `/1`'s four values for the March in-toto work.
- **The Stop hook's reason** (`detail` in `hooks/stop`). Written to the
  verification log, the session's held-tree record, the overnight charge, and
  the cloud debt message. One reader compares it: `felix_hold_tree_seen`
  (`lib/verify.sh`), an exact-line match against the same session's held-tree
  record, which a person's prompt and SessionEnd clear.
- **The pulse's success line.** Readers of the pulse record key on
  "NOT backed up" alone (`lib/status.sh`, `lib/pulse-stage.sh`).
- **`felix install`'s line.** No engine reader. The land tick reads the
  command's exit status.
- **The notifier's sentences** (`lib/notify.sh`). Fixed text for each kind;
  nothing keys on them.
- **The tick's deploy-owed reason** (`lib/green-tick.sh`). The ledger's free
  text. `_gt_row_once` compares it with the last row, so a changed sentence
  writes at most one more row.
- **`templates/unattended.yml`.** `felix unattended` compares a governed
  repository's deployed copy with this template, comments aside.

## What must hold

Each clause quotes the exact text after the change. `\t` is a tab and `\n` a
line break. Text the clause does not quote is unchanged.

- **C1 The help line.** `felix help` prints the line
  `    felix receipt          what changed, its risk, and whether anything checked it`.
- **C2 `felix install`.** Where it printed
  `  verified   the installed engine matches this tree`, on both of its paths
  (the first comparison, and the one after a bump), it prints
  `  checked    the installed engine matches this tree`. The label column stays
  eleven characters wide. When the installed engine does not match, neither
  line is printed, as before.
- **C3 `felix merge`, a moved checkout.** The two lines are
  `The checkout moved while this ran, so what was checked is not what` and
  `would be merged. Nothing was merged.`
- **C4 `felix classify`, a green tier that owes no evidence.** The lines are
  `Reversible, and no evidence is owed. Eligible for auto-merge once` and
  `every required check passes.`
- **C5 `felix classify`, a green tier that owes evidence.** The lines are
  `Reversible, but <why>. Not auto-merge eligible: a green`,
  `tier means no risky path was touched, not that the change was tested.` and
  `Run felix evidence.`
- **C6 The Stop hook's reason for a checkout with no gate receipt** is
  `never checked`, wherever the reason goes: the held-tree record
  (`<tid>\tnever checked\t<checkout>`), the verification log (field 4, the
  reason, for the `blocked` row and as the start of the `debt` row's
  `never checked; held once on this tree already (session <8 chars>)`), the
  overnight charge, and the cloud debt message. The hold's text
  (`The gate has never run in this checkout.` and what follows) is unchanged.
- **C7 A hold recorded under the old word is the same hold.** For the reason
  `never checked`, `felix_hold_tree_seen HOME SID TID REASON CHECKOUT` returns 0
  when the record holds the line `TID\tnever checked\tCHECKOUT` or the line
  `TID\tnever verified\tCHECKOUT`. For every other reason it returns 0 only for
  its own exact line, as before. Through the hook, where it holds once (not
  inside a night's chain or a held night, a tree id that is not `coarse:`, a
  HEAD that exists): a session whose record holds `TID\tnever verified\tCHECKOUT`
  stops again on that tree, in that checkout, with no gate receipt; the hook
  lets it go and records the debt, exactly as for a record of `never checked`.
  A record of the same tree and checkout with another reason (`failed`,
  `stale receipt`) still holds.
- **C8 The receipt.** `felix receipt` prints `"schema": "felix.receipt/2"`.
  Its `status` is `checked` where `/1` said `verified` (the gate receipt is
  current for this exact tree, its result green, and no evidence gap), and
  `unchecked` where `/1` said `unverified` (every other case that is neither
  `blocked` nor `indeterminate`). `blocked`, `indeterminate`, their precedence,
  and every other field are unchanged. No receipt's `status` is `verified` or
  `unverified`, and the receipt's own fixed text (its keys and its `limits`
  sentences) holds neither word.
- **C9 The pulse's backup line after a push the remote reads back.**
  - network: `backup\tpushed and read back: <remote> holds <12 hex>`
  - disk: `backup\tpushed and read back: <remote> holds <12 hex>; <remote> is a path on this machine, so this copy is only as far from this disk as whatever syncs that path`
  - not known: `backup\tpushed and read back: <remote> holds <12 hex>; where <remote> is could not be read`

  The stamp is written on exactly these paths, as before. A push the remote
  does not read back still prints `backup\tpushed, but ... reads back ...`.
- **C10 The notifier.** `_fn_sentence deployed` prints exactly
  `The engine on main was installed and passed its deploy checks.`, and
  `_fn_sentence deployed-unverified` prints exactly
  `A deploy of main stopped at a failed step or check, and landing is paused.`
  Every other kind's sentence is unchanged.
- **C11 The tick's deploy-owed reason**, when the cache entry is main's and the
  home is not at main: `the home checkout is not at origin/main: the engine it holds has not been deployed and checked`.
- **C12 The unattended template's commit.** The subject of the commit the
  workflow makes is `fix: unattended repair, checked by the gate`. Its body is
  unchanged.
- **C13 `templates/moments.tsv`.** The row is
  `pre-conclude\tbefore work is called done: what was checked, recorded, and handed over`.
- **C14 `templates/lifecycle.tsv`.** The row is
  `Stop\twired\trefuse completion on a tree the gate has not passed, then ask that the claims be checked`.
- **C15 The cloud debt message** (`felix_stop_debt`, `CLAUDE_CODE_REMOTE=true`)
  ends its third sentence `so nothing outside it says this work went unchecked.`
  The rest is unchanged, the reason in parentheses included (C6).
- **C16 The SubagentStop message** says
  `must say so plainly: partial, or unchecked — not done, working, or passing.`
- **C17 The `/felix` command** (`engine/commands/felix.md`) ends
  `this is a tool whose entire value is that it refuses to report success it has`
  / `not checked.`
- **C18 The class, not the instance.** A check in the suite reads every file
  under the engine directory under test (the parent of `REAL_HARNESS`), except
  `harness/tests/`; inside a git work tree, only the files git tracks there.
  It skips each line whose first character that is not a space or tab is `#`.
  From every other line it removes each allowed name below (exact,
  case-sensitive substrings), lower-cases what is left, and fails on any match
  of the ERE `(^|[^a-z0-9_])(un)?(verified|proven)([^a-z0-9_]|$)`, naming each
  file and line. The allowed names:
  - `state/verified`, the Stop hook's per-session marker directory;
  - `deployed-unverified`, the land ledger's event kind;
  - `subagent-unverified`, a `felix_say` kind;
  - `'unverified\t`, `lib/escape.sh`'s merge blocker kind as its printf
    spells it (here `\t` is the two characters backslash and t, not a tab);
  - `== "unverified"`, the same kind as `lib/green-install.sh` reads it;
  - `never verified`, in `harness/lib/verify.sh` only: the reason before this
    change, which C7 has `felix_hold_tree_seen` still accept. (Round 2,
    2026-10-31: C7 cannot accept the old reason without naming it, which the
    blind part's lint, written from round 1, flags.)

  The check is shown to fail: run over a fixture directory holding a printed
  line with "Verified" or "unproven", it fails and names that line; over one
  holding only a `#` comment with the word and a line with an allowed name, it
  passes.
- **C19 What a hold, a deploy and a landing decide is unchanged.** Only words
  change, and the one comparison C7 widens.

## What keeps its name, and why

These are names, not sentences. Each has readers, records on disk or both, and
none claims that anything was checked:

- `lib/escape.sh`'s blocker kind `unverified` (`unverified\ttree\t...`,
  `unverified\ttests\t...`). `felix merge` prints it; `lib/green-install.sh`
  parses it; the land ledger records it, and the session-start list of waiting
  pull requests reprints those rows. Renaming it moves the merge path and every
  reader of recorded rows.
- The ledger kind `deployed-unverified` and the function `_gt_unverified`
  (`lib/green-tick.sh`, `lib/notify.sh`, the ledger's rows).
- The say kind `subagent-unverified`.
- The directory `state/verified/`.
- Comments, function names and file names, the task's own exclusion
  (`.github/workflows/reuse-verified-tree.sh` among them). A comment that names a
  value this change renames is updated with it.

## Stated limits

- **L1, high-stakes (`lib/receipt.sh`).** A reader outside this repository that
  parses `felix.receipt/1` and keys on `verified` now gets `felix.receipt/2`.
  None is known: nothing in the engine, its CI or a project gate reads the
  receipt, and the in-toto mapping (#476) is a draft document. No automatic
  check can show an outside reader harmless, so the pull request opens as a
  draft labelled `needs-founder` (decision 5, Felix's interim reading).
- **L2, a template.** A governed repository that copied
  `templates/unattended.yml` keeps "verified by the gate" in its copy, and
  `felix unattended` there reports the copy as differing at the commit line
  until a person copies the template again. No gate reads that report.
- **L3, records.** Verification logs, held-tree records and ledger rows written
  before the deploy keep the old words, and readers print them as recorded.

## How it is tested

- **Blind.** One part, `tests/parts/2300-checked-not-verified-blind.sh`, written
  from this contract alone before the change, red against main. Its assertion
  names start `cnv A`. Each clause C1-C18 has at least one assertion. A clause
  that forbids a word asserts both the old and the new word, so a check cannot
  pass by finding neither.
- **Existing parts.** Every assertion that matches a changed string matches the
  new one. Every negative check that refused an old string refuses the new
  string too (0370's receipt refusals, 0470's and 1741's "no success line",
  0630's and 0640's "not certified"); none may go vacuous.
- **The record and the gate** at the head the pull request carries.
