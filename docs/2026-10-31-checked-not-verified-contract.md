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

Round 3 (2026-10-31, after the first adversarial review) restates that
review's findings as sentences: each is marked "Round 3" where it lands. It
widens the class by one word, `proves`, which four lines said to a person.
It also gives the receipt's other cases words that are true, and it corrects
two sentences round 1 wrote that were false for some of the cases that print
them.

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
- **The tick's deploy-owed reason** (`lib/green-tick.sh`). No reader (round 3
  corrects round 1, which called it the ledger's free text). `_gt_deploy_owed`
  prints it, and its one caller keeps it in a variable it never reads:
  `_gt_deploy` writes rows with reasons of its own.
- **The probes' witness sentences** (round 3). The third field of a probe
  row, which `felix probes` and the gate print. Readers key on the state in
  the second field (`felix_probes_blocking`), never on the sentence.
- **The standing issue's body** (round 3). Written once, when the notifier
  creates the issue. Nothing reads it back: the notifier finds the issue by
  its title and author.
- **`templates/unattended.yml`.** `felix unattended` compares a governed
  repository's deployed copy with this template, comments aside.

## What must hold

Each clause quotes the exact text after the change. `\t` is a tab and `\n` a
line break. Text the clause does not quote is unchanged.

- **C1 The help lines.** `felix help` prints the line
  `    felix receipt          what changed, its risk, and whether anything checked it`,
  and its first line is
  `Felix. The engineering OS: it decides how work gets built, and runs the gate that checks it.`
  (Round 3: the first line ended `and proves it`.)
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
  current for this exact tree, its result green, and no evidence gap). Where
  `/1` said `unverified` (every other case that is neither `blocked` nor
  `indeterminate`), it says which of three things is true (round 3; one word,
  `unchecked`, was false where the gate had run on this exact tree):
  - `failed`: the gate receipt is for this exact tree and its result is red;
  - `evidence-owed`: the gate receipt is current for this exact tree, its
    result green, and the evidence check reports at least one gap;
  - `unchecked`: every other case, that is no gate receipt, or one that is
    stale (for another tree, or resting on facts that have moved).

  Each of the three carries `"evidence_quality": "low"`, as `/1`'s
  `unverified` did. `blocked`, `indeterminate`, their precedence over these,
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
  home is not at main: `the home checkout is not at origin/main, so main's engine has not been deployed from it and checked`.
  (Round 3: the engine the home holds was deployed; main's was not. Nothing
  prints this reason today, so the clause is a sentence in the source.)
- **C12 The unattended template's commit.** The subject of the commit the
  workflow makes is `fix: unattended repair, checked by the gate`. Its body is
  unchanged.
- **C13 `templates/moments.tsv`.** The row is
  `pre-conclude\tbefore work is called done: what was checked, recorded, and handed over`.
- **C14 `templates/lifecycle.tsv`.** The row is
  `Stop\twired\trefuse completion on a tree the gate has not passed, then ask that the claims be checked`.
- **C15 The cloud debt message** (`felix_stop_debt`, `CLAUDE_CODE_REMOTE=true`)
  ends its third sentence
  `so nothing outside it says the gate has not passed on this work.`
  The rest is unchanged, the reason in parentheses included (C6). (Round 3:
  `went unchecked` was false for the reasons `failed` and `epoch moved`, where
  the gate ran on this exact tree, and every reason reaches this message.)
- **C16 The SubagentStop message** says
  `must say so plainly: partial, failing, or unchecked — not done, working, or passing.`
  (Round 3: the hook also speaks on a tree the gate ran red on.)
- **C17 The `/felix` command** (`engine/commands/felix.md`) ends
  `this is a tool whose entire value is that it refuses to report success it has`
  / `not checked.`, and its step 2 for a new project begins
  `2. Work out what checks this project — the command that fails when` /
  `the code is wrong.` (Round 3: it began `Work out what would prove this
  project correct`.)
- **C18 The class, not the instance.** A check in the suite reads every file
  under the engine directory under test (the parent of `REAL_HARNESS`), except
  `harness/tests/`; inside a git work tree, only the files git tracks there.
  It skips each line whose first character that is not a space or tab is `#`.
  From every other line it removes each allowed name below (exact,
  case-sensitive substrings), lower-cases what is left, and fails on any match
  of the ERE `(^|[^a-z0-9_])((un)?(verified|proven)|proves)([^a-z0-9_]|$)`,
  naming each file and line. (Round 3 added `proves`, the claim form of
  `proven`, which `felix help`'s first line and the probes' witness sentences
  used; "What stays outside the class" says why `prove`, `proving` and `verify`
  are not in it.) The allowed names:
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
  line with "Verified", "unproven" or "Proves", it fails and names that line;
  over one holding only a `#` comment with the word and a line with an allowed
  name, it passes.
- **C19 What a hold, a deploy and a landing decide is unchanged.** Only words
  change, and the one comparison C7 widens.
- **C20 The probes' witness sentences** (round 3). A probe whose witness
  answers yes while the probe saw none of the surface reads
  `blind\t0\tthe witness says this surface exists and the probe exited <rc>`
  when the probe exited non-zero, and
  `blind\t0\tthe witness says this surface exists and the probe enumerated none of it`
  when it exited 0. `felix probes`, where any row is blind or unknown, prints
  `blind means the witness says a surface exists that the probe cannot see, and`
  / `unknown means nothing decided either way.` The states and their
  decisions are unchanged.
- **C21 The standing issue's body** (round 3). The issue the notifier creates
  names, among the events that start the workflow,
  `a deploy that stopped at a failed step or check`, where it said
  `a deploy it could not verify`. The rest of the body, the title and the
  call that creates it are unchanged.
- **C22 The README's hook table** (round 3). Its `Subagent stop` row ends
  `tells the parent that a subagent's report must call its own changes partial, failing or unchecked |`
  where it said `...unverified |`, since C16 changed the words it describes.
- **C23 The schema the build queue reserved** (round 3).
  `docs/handoff/0cw.md` named a planned evidence packet `felix.receipt/2`.
  This change takes `/2`, so the packet is `felix.receipt/3` there, and no
  tracked document plans a `/2` other than this one.

## What keeps its name, and why

These are names, not sentences. Each has readers, records on disk or both, and
none claims that anything was checked:

- `lib/escape.sh`'s blocker kind `unverified` (`unverified\ttree\t...`,
  `unverified\ttests\t...`). `felix merge` prints it; `lib/green-install.sh`
  parses it; the land ledger records it, and the session-start list of waiting
  pull requests reprints those rows. Renaming it moves the merge path and every
  reader of recorded rows.
- The ledger kind `deployed-unverified` and the function `_gt_unverified`
  (`lib/green-tick.sh`, `lib/notify.sh`, the ledger's rows). A person reads
  the kind too (round 3): `felix land --status` lists ledger rows by kind, and
  the comment the notifier dispatches to the standing issue starts
  `@<owner> Felix land: deployed-unverified`, above C10's sentence. Both kinds
  named here are printed to a person, so they move together, with their
  readers and every recorded row, in a change of their own.
- The say kind `subagent-unverified`.
- The directory `state/verified/`.
- Comments, function names and file names, the task's own exclusion
  (`.github/workflows/reuse-verified-tree.sh` among them). A comment that names a
  value this change renames is updated with it.

## What stays outside the class, and why

Round 3. These use the same roots and claim nothing was checked or proven, so
C18's ERE leaves them out on purpose:

- Two obligations and a negation. `felix help`'s `what a fix must prove` and
  `felix brief`'s heading of the same words, `felix incident`'s heading
  `the fix will have to prove`, and `felix evidence`'s
  `with nothing proving it`. They name what a fix owes or what is missing.
  Part 1830 keys on both headings.
- The verb and noun `verify`, which name a step or ask for one: git's
  `--verify`, `felix audit --verify ERE`, the unattended template's step
  `Verify and push`, the overnight direction's `verify it` and
  `Verify everything`, the tick's `its verify did not finish`, and the memory
  file's `- verify:` line.

If decision 1 is read to reach them, they move with their readers, in a
change of their own.

## Stated limits

- **L1, high-stakes (`lib/receipt.sh`).** A reader outside this repository that
  parses `felix.receipt/1` and keys on `verified` now gets `felix.receipt/2`.
  None is known: nothing in the engine, its CI or a project gate reads the
  receipt, and the in-toto mapping (#476) is a draft document. No automatic
  check can show an outside reader harmless, so the pull request opens as a
  draft labelled `needs-founder` (decision 5, Felix's interim reading).
  `/2` also says only which tree the gate judged, its result and when. It
  does not name the gate's command, what the gate reported or what it
  skipped (the gate receipt's fields 4 to 6). The evidence packet, now
  `felix.receipt/3` (C23), is where those go.
- **L2, a template.** A governed repository that copied
  `templates/unattended.yml` keeps "verified by the gate" in its copy, and
  `felix unattended` there reports the copy as differing at the commit line
  until a person copies the template again. No gate reads that report.
- **L3, records.** Verification logs, held-tree records and ledger rows written
  before the deploy keep the old words, and readers print them as recorded.
  One reader outside the repository keys on the old reason: the hold replay
  script of the 2026-10-09 token-burn audit (`replay_holds.py` in the memory
  root) maps a never-ran hold to `never verified`. A re-measurement over logs
  written after the deploy has to fold the two reasons.
- **L4, an unreadable receipt** (round 3). A gate receipt that exists but
  cannot be read reads as none. The Stop hook then holds with "The gate has
  never run in this checkout." and records `never checked`, as main records
  `never verified`. Telling the two apart changes the hook's decision path,
  which this change leaves alone.

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
- **Round 3, blind.** A second part,
  `tests/parts/2301-checked-not-verified-round3-blind.sh`, written from the
  round-3 sentences alone (C1, C8, C11, C15-C18 as amended, and C20-C23),
  before the round-3 change, red against the head before it. Its assertion
  names start `cnv3 A`.
- **Round 3, the count.** No edited part has fewer lines matching
  `projects/felix/risk.tsv`'s assertion count (`^[[:space:]]*(ok|is|has|bad) `)
  than it had at base. A part that lost one reads to `felix merge` as a
  weakened suite, the verifier channel (round 1 turned one `has` in part 0470
  into a `case` block).
- **The record and the gate** at the head the pull request carries.
