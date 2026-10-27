# Audit fix batch b08: change-scoped verification and receipt freshness

Contract, 2026-10-24. Branch `claude/audit-b08-change-scoped-verification-and-receipt-f`,
cut from origin/main 69b51a61 (0.49.307); line numbers are for that tree. It covers
C003, C045 and C110 of the 2026-10-24 audit register. C044 (choosing tests by reach)
is a separate design waiting for the founder and is not here.

## 1. Defects

**C003** (high; one skeptic confirmed high, the other refuted it only as known and
scheduled). `felix merge` lands a tree whose green gate receipt says the suite was skipped.
Scenario: a session runs `felix gate --quick`. `projects/felix/gate.sh:317-318` prints
`tests skipped (--quick)` and the gate exits 0. cmd_gate writes field 5 `tests`
(`felix:1097-1098`) into a green receipt, and `felix_verify_current`
(`lib/verify.sh:578-635`) never reads field 5. `felix_merge_blockers`
(`lib/escape.sh:641-669`) asks CI only when field 6 holds `tests:reused`, and the
repository has no branch protection. So `felix merge` squash-merges an engine change
that no suite ran on anywhere, and part 0100 pins this ("a receipt carrying a skip list
still clears every blocker", `0100-merging.sh:93`). This is the direction's trust item 2
(`docs/direction.md:210-215`): "merge refuses a receipt that skipped checks". Its spec,
in the memory root at `audits/2026-10-01-report-v5-review/specs/skipped-receipt/spec.md`,
is followed here where the code has not moved since: §2.2 (what counts as skipped), §2.4
(Stop stays a speed bump), §2.6 (CI does not clear it) and the reason texts in §3. Its
scope is narrowed to the merge boundary (section 6 says why).

**C045** (low, as the skeptic corrected it). The suite receipt is keyed on the commit
`refs/remotes/origin/main` names, but the suite's only reader of that ref (part 1010's
`_rt_judge`) reads much less of it.
Scenario: a docs-only pull request lands while branch B's record run is going. The home's
land tick fetches every 300 s (`lib/green-tick.sh:423`), and every worktree shares
refs/remotes, so the ref moves under all of them. `_rcp_finish` (`tests/receipt.sh:321-336`)
then drops B's receipt and prints nothing. The gate's `tests/run --reuse` logs
`not reused: no receipt`, runs the whole suite again, and prints only `tests ok` and the
summary (`gate.sh:341-351`). Every other open worktree's receipt answers
`run origin/main moved` (`receipt.sh:255`). Since 10-13, five landings (#437, #451, #453,
#457, #459) touched nothing under `engine/`, and each one cost every worktree its receipt.

**C110** (medium). The gate's `cloud` check compares only event-to-hook pairs.
Scenario: the PreToolUse matcher in `engine/hooks/hooks.json` widens (it has before:
1a8b3b66), and `.claude/settings.json` keeps the old one. `_cloud_pairs`
(`gate.sh:612-616`) reads the same eight pairs from both files, so the gate prints
`cloud ok`. Meanwhile every cloud session runs pre-tool, and with it every deny row, for
fewer tools than a local session does. Today the two files agree.

## 2. Required behaviour

### C003: the merge boundary refuses a green that reports a check skipped

Terms. *Field 5* is the receipt's skip list, `-` when there is none. An *item* is the text
between commas, byte for byte. An item is *check-shaped* when, under `LC_ALL=C`, it
matches `^[abcdefghijklmnopqrstuvwxyz][abcdefghijklmnopqrstuvwxyz-]*$`; every other item
(`-`, `--`, `○`, `1`, ` tests`, `Tests`, `%s%n`) is *off-shape*. *The judge* is
`felix_merge_blockers <project dir> <base ref> <root> <home>`, run in a child bash under
`set -uo pipefail` after sourcing `resolve verify review classify evidence escape` from
the engine's `lib/`, as `_felix_kernel_blockers` loads main's kernel.

The two reasons:
- R_SKIP(NAMES) = `the gate reported NAMES as skipped on this tree, and a green with a
  check reported skipped does not land, so run the full gate, and if a check still
  reports skipped, its own line in the gate output says why`
- R_UNSTATED = `the receipt is not one green line stating what the gate skipped, so it
  cannot show that no check was reported skipped, and the remedy is the full gate`

**B1.** Take a receipt that `felix_verify_current` answers `current` for, whose field 5
holds at least one check-shaped item. The judge prints exactly one line for it:
`unverified<TAB>skipped<TAB>`R_SKIP(NAMES). NAMES is the check-shaped items in field 5's
order, joined with `,`. The reason text is printed as data and never used as a printf
format. If nothing else blocks, that line is the judge's whole output.

**B2.** Off-shape items never refuse and never appear in NAMES. Field 5 `-`, `--` or
only off-shape items (`○,1`) gives no line; `○,1,tests`, `-,tests` and `%s%n,tests`
each give NAMES `tests`.

**B3.** A current receipt whose field 5 is empty yields exactly one line:
`unverified<TAB>skipped<TAB>`R_UNSTATED. This is unknown, never "nothing skipped".

**B4.** The rule judges only a current receipt. A stale receipt naming `tests` prints its
`unverified<TAB>tree<TAB>the tree changed since the receipt` line and no skipped line; a
red one prints `unverified<TAB>tree<TAB>no green receipt for this exact tree; run felix
gate` and no skipped line.

**B5.** Field 6 is not read by the rule. Field 5 `-` with field 6
`syntax:ok,tests:skipped` gives no line.

**B6.** No CI evidence clears the skipped line, and the rule calls nothing. A `gh` stub
first on PATH records no call for any receipt whose field 6 does not hold `tests:reused`.

**B7.** Take a current receipt whose field 6 holds `tests:reused` and whose field 5 names
a check, in a checkout with no github remote. The judge prints exactly two lines: first
the skipped line, then rule C9's line, which begins `unverified<TAB>tests<TAB>the gate
reused a suite run for this tree (tests:reused)`. C9 itself is unchanged.

**B8.** On a current receipt with field 5 `tests`, `felix merge --base <ref> --dry-run`
exits 3. Its output holds `not merging`, the line `printf '  %-11s %-22s %s' unverified
skipped "R_SKIP(tests)"` makes, `Nothing here escapes the tree, so none of it is a founder
decision.` and `It is work Felix owes: run the gate, or write the test that is missing,`;
it does not hold `nothing escapes this tree, and the gate is green on it.`

**B9.** If the same tree is recorded again with field 5 `-`, the same command exits 0
and prints `felix merge would squash this now.`

**B10.** The gate's report decides, not its flags. Take a project whose gate, run by
`felix gate` with no flag, prints `  tests              skipped (no suite here)` and exits
0. Its receipt carries field 5 `tests`, and `felix merge --dry-run` then exits 3 with the
B8 line.

**B11.** The engine's own skip lines stay out of field 5. Take a project with
`probes.tsv`, `obligations.tsv` and `commissioning.tsv`, no `qualification.tsv`, and a
gate that prints only `  syntax             ok`. `felix gate` there prints the engine's
`qualified` line saying `skipped`, writes field 5 `-`, and `felix merge --dry-run` exits 0.

**B12.** `felix_verify_current` still answers `current` for an epoched green receipt
whose field 5 is `tests`. The Stop hook's hold does not change.

### C045: the receipt keys on what the suite reads of origin/main

*The reading* is taken in `<root>`, with HEAD as it stands when it is taken, and only
while `refs/remotes/origin/main` names a commit. It is three values, each mirroring a read
that part 1010's judge makes:
- `e`: what `git rev-parse -q --verify refs/remotes/origin/main:engine` prints, else `-`
  (`_rt_engine_same`, and main's plugin.json version, which lives under `engine/`);
- `a`: `yes` when `git merge-base --is-ancestor HEAD refs/remotes/origin/main` exits 0,
  else `no`;
- `m`: what `git rev-parse -q --verify <mb>:engine` prints, where `<mb>` is what
  `git merge-base HEAD refs/remotes/origin/main` prints, else `-` (`_rt_record_holds`).

When origin/main names no commit, there is no reading.

**B13.** The receipt stays one line of nine tab-separated fields: `v1 <tree id> <mode>
<passed> <failed> <skipped> <env> <start> <end>`. When the run began with an origin/main,
field 7 is `<_sr_env>;reads=<e>,<a>,<m>;origin=<commit>`. The reading and the commit are
the ones taken when the run began, so the commit stays the field's tail. With no
origin/main, field 7 is `<_sr_env>` alone, as it is today.

**B14.** Before the twelve-hour check and after the environment check, which is the
order today, `_sr_check <root>` answers `run origin/main moved` for a receipt carrying
`;reads=` unless a reading taken now equals the recorded one. A move of origin/main that
changes none of `e`, `a` and `m` therefore leaves the receipt standing: a commit that only
touches `docs/` or `projects/` is one such move.

**B15.** Each of these is refused with `run origin/main moved`: origin/main's `engine/`
tree changed; HEAD became an ancestor of origin/main; the engine tree at the merge base
changed, even when origin/main's own `engine/` tree did not; origin/main named a commit
when the receipt was written and names none now; or the receipt recorded none and
origin/main names a commit now.

**B16.** A receipt in today's form keeps today's rule. That form is field 7
`<_sr_env>;origin=<commit>` with no `;reads=`, as the old engine and part 1260's
hand-written receipts write it. Such a receipt is reused only while origin/main names that
same commit.

**B17.** A receipt is `run malformed receipt` when field 7 holds `;reads=` and no
`;origin=<commit>` tail follows the reading, or the reading is not three comma-separated
values, or `e` or `m` is neither `-` nor 40 or 64 lowercase hex digits, or `a` is neither
`yes` nor `no`.

**B18.** The order of checks stays: a receipt aged past twelve hours whose reading moved
answers `run origin/main moved`; one whose reading did not move answers `run older than
12 hours`.

**B19.** `_rcp_finish` writes the receipt when the reading at the run's end equals the
one at its start, or there was none at either point, even if the commit moved during the
run. The receipt names the start reading and the start commit, and `_sr_check` then
reuses it.

**B20.** Every time `_rcp_finish` writes no receipt, it prints exactly one line to
stdout, before the summary: `  receipt not written: <reason>`, the first that applies:
(1) `the run had failures`; (2) `the manifest was not compared`; (3) `the tree could not
be read when the run began`; (4) `the environment changed during the run`; (5)
`origin/main moved during the run` (the reading changed, appeared or went away); (6)
`the record this run wrote was not judged` (record mode); (7) `the tree could not be read
when the run ended`; (8) `the tree changed during the run` in normal mode, or `the tree
changed during the run, beyond the manifest and red.tsv` in record mode.

A run that writes its receipt prints no such line. The existing `receipt not written:
<path> is not a regular file` and `could not write <path>` lines are unchanged.

**B21.** The bridge (C10) stands across a move of origin/main that leaves the reading
alone. Take a receipt written with an uncommitted change to a tracked file. That change
is then committed, and origin/main moves by a docs-only commit. `_sr_check` answers
`reuse <passed> <failed> <skipped> <end> <mode> <HEAD's full sha>`.

**B22.** The header of `tests/receipt.sh` no longer says `GitHub CI still runs the whole
suite on Linux before anything merges`. A true sentence replaces it: `felix merge` asks
CI's gate run for a reused verdict (C9) and refuses a receipt that reports a check
skipped. The header names the three reads that the reading mirrors, and this contract
next to contract A's C4 and C5.

### C045: the gate says why the suite was not reused

**B23.** Take `tests/run --reuse` exiting 0 with a log that holds a line containing
`not reused: `. projects/felix/gate.sh prints `  tests              ok`, then the log's last
line indented 21 spaces (directly under `ok`, as today), then 21 spaces and that line's
text from `not reused: ` to its end. The first such line counts, including one where a
stderr fragment with no newline sits in front of it.

**B24.** A reused log (`reused the suite run that ended ...`) is reported `reused`, as
today, and the gate prints no `not reused:` line.

**B25.** If the log holds no `not reused: ` line, the gate prints `tests ok` and the
summary only. On `--quick`, it prints `tests skipped (--quick)` and does not run the suite.

### C110: the cloud check compares each binding whole

*A binding* is one hook object, inside an event's group, whose command names
`harness/hooks/<name>`. It has five parts: the event key; the group's matcher (the value
on its `"matcher"` line, or `-` when the group has none); the hook name; its `async` value
(`true`, `false`, or `-` when absent); and its `timeout` value (digits, or `-`).

Values are compared exactly as written, and absence is a value of its own. A settings
binding the plugin does not have, such as the provision hook with its `timeout`, is
allowed, as it is today.

**B26.** If every plugin binding has a settings binding with the same five parts, the
`cloud` line is `ok`. That holds for the two files in this tree, and when only a
`statusMessage`, `shell` or `type` differs.

**B27.** Take a plugin binding whose event and hook name the settings also bind, but not
with all five parts equal. The `cloud` line is `FAIL`, and the line under it holds
`bound differently for the cloud: <Event>/<hook> (<fields>);`. `<fields>` lists the parts
that differ from the first such settings binding in the file, out of `matcher`, `async`
and `timeout`, in that order, joined with `, `. There is one clause per binding.

**B28.** A plugin binding whose event and hook the settings do not bind at all still
gives `not bound for the cloud: <Event>/<hook>` as today, and so do the guard count, the
toolbox rows, the `unreadable: no event-to-hook pairs` case and the `skipped (no
.claude/settings.json in this tree)` case.

**B29.** Some lines put the check outside the layout it reads. In either file, that is
a line holding `"matcher"` that is not exactly 8 spaces, `"matcher": "`, a value with no
`"` or `\`, `"` and an optional `,`. It is also a line holding `"async"` or `"timeout"`
that is not exactly 12 spaces, the key, `: `, `true`/`false` (for async) or digits (for
timeout), and an optional `,`. Any such line makes the line under `FAIL` hold
`unreadable:` and that file's path. This is the case today for a file that is read in
the same way: a reformatted file fails and never reads as agreement.

## 3. What must not change

Behaviour, and the parts that pin it:
- **Receipt fields 5 and 6**, cmd_gate's extractors and the qualify roster:
  `0100-merging.sh` (the field-5 and field-6 block, both extractor assertions) and
  `0500-continued.sh`.
- **The single exception in 0100.** "a receipt carrying a skip list still clears every
  blocker" (`0100-merging.sh:93`) becomes false on purpose. It is restated, not deleted.
- **Other merge blockers and the CLI's merge output**: a green with field 5 `-` clears
  every blocker, a red receipt or one for another tree blocks, the dry-run paragraphs
  stay, and "felix_merge_blockers emits exactly the kinds cmd_merge places" (kinds
  `commission escape evidence obligations probes unknown unverified`, so every new
  printf in that function starts `printf 'unverified\t`). All in `0100-merging.sh`, plus
  `0360-what-felix-merge-records-and-what-it-hands-g.sh` and the self-governed kernel
  dry runs in `0340-the-line-that-does-the-work.sh`.
- **Rule C9, whole**, including "C9.4: a green receipt reading tests:ok clears every
  blocker, as today" with no gh call, and the C9-R4 gate stubs:
  `1250-gate-friction-a2-blind.sh`. The rule reads field 5 from the receipt text that
  was already read once for C9 (review finding C9-R3), not from a second read.
- **The Stop hook's hold and its "it skipped: tests" sentence**:
  `0210-the-completion-gate.sh`. `felix_verify_current`'s answers:
  `0510-the-receipt-carries-the-epoch-and-a-fact-tha.sh`.
- **The land-on-green tick**: `1280` to `1288`.
- **Receipt format, `_sr_env`, the malformed rules, nine fields, and `not reused: no
  receipt` as the first line**: `1200-gate-friction-a-blind.sh` and
  `1220-gate-friction-a-blind.sh`.
- **The gate's tests line shapes**: `1230-gate-friction-a-blind.sh`. This includes "a
  suite that exits 0 having run is reported ok with its last line, as today (control)",
  which is why B23 keeps the summary directly under `ok`.
- **The A addendum**: `1230-gate-friction-a-addendum-blind.sh`, all of A1 to A10 except
  two A1 assertions that become false by design, because its `_gfb_c1` and `_gfb_c2`
  share HEAD's tree, ancestry and merge base: "(A1) a receipt whose origin/main now names
  another commit is refused: run origin/main moved" and "(A1) aged past 12 hours with
  origin/main moved, the origin/main check answers first". Restate both, not blind
  (b08), by making `_gfb_c2` a commit whose `engine/` tree differs. Their meaning then stays "a move the suite can see is refused". The tail
  assertion "(A1) the receipt a passing run leaves names ... the commit origin/main
  named when the run began" must hold as written.
- **No-receipt cases and the not-a-regular-file line**:
  `1240-gate-friction-a-survivors-blind.sh`.
- **The bridge, C10, whole**: `1260-gate-friction-a3-blind.sh`. That includes line 258,
  which stays true because its receipts are hand-written in today's form (B16). Its
  `_gfd_rec` calls `_sr_origin`, which must keep printing the commit or `-`.
- **Part 1010**, which is untouched, and the part 1040 limits.

Limits the build must keep:
- **Line counts.** `lib/escape.sh` (799), `lib/verify.sh` (663), `projects/felix/gate.sh`
  (652), `engine/harness/felix` and `hooks/stop` may not end longer than now;
  `tests/receipt.sh` (499) and `tests/run` (497, plus two part lines) stay at 500 or less.
- **Escape confines** in `projects/felix/risk.tsv`. In gate.sh, lines matching
  `^[[:space:]]*(pass|fail|check) ` may not drop below 26 (row 41). In every changed
  part, the `ok|is|has|bad` count may not drop (row 42). Either drop is an escape.
- **Where the C003 code goes.** It stays in a file that the kernel child sources
  (escape.sh or verify.sh). A new lib file would reach `_felix_kernel_blockers` only
  through a new source line.
- **Where the C045 code goes.** It goes in `tests/receipt.sh`, or in a new
  `engine/harness/lib/` file that it sources, which parts 1230 and 1260 copy whole.
  Never put it in a new file beside receipt.sh: those fixtures copy receipt.sh alone, so
  the run would read as `no tests/receipt.sh beside this suite`.
- **Shells and fixtures.** Bash 3.2 and 5, BWK awk and gawk: no `case` inside `$( )`,
  digits spelled out in brackets, `LC_ALL=C`, no gawk-only awk (part 1497). New parts
  write fixture git only through `_fx_git` and `_fx_cd` (part 0002). assertions.tsv,
  red.tsv and plugin.json are written by the record run and the carrier, not by hand.

## 4. Assertions

Fixtures (the shapes; every external run is bounded, and an assertion that cannot run
skips by name with its reason):
- **FM**, for merges, built the way part 1250 builds `gfcw`: tables copied from
  `$TMP/probes.keep`, `obligations.keep` and `commissioning.keep`; `risk.tsv` from the
  templates; project.json with gate `true`; a repository with `.felix`, a base commit and
  a change commit, and no git remote; a base branch at HEAD~1; the commission receipt
  stamped once. Receipts are written by `felix_verify_record <root> $FROOT <rc> gate.sh <tree id>
  <field 5> <field 6>`. A `gh` stub first on PATH appends its arguments to a file and
  exits 1. Asserted lines are compared with tabs shown.
- **FG**, a second project like FM with no qualification.tsv. Its project.json says
  `"gate": "gate.sh"`, and that executable prints what a mode file says.
- **FC** and **FT**, for gate runs, built the way part 1250's C9-R4 block builds its
  checkout: schema-check and independence-scan stubs, a `lib/detect.sh` stub, an
  ecosystem.tsv header, a copy of `projects/felix/gate.sh`, and a `tests/run` stub that
  writes a marker file and prints what a mode file says. FC adds copies of the tree's `engine/hooks/hooks.json` and `.claude/settings.json`,
  edited for each case, and runs `bash projects/felix/gate.sh --quick`. FT has no
  settings file and runs `bash projects/felix/gate.sh`. Both run with
  `FELIX_KERNEL_CACHE` set to a missing directory and HOME and TMPDIR under `$TMP`,
  and both stop at 60 s.
- **FR1**: commit A (`engine/x`, `docs/y`), then B, a child of A changing `docs/y`, at
  HEAD; origin/main at A. Made with commit-tree and never checked out: A_docs (A plus a
  docs change), A_eng (A plus an `engine/x` change), Z (a child of B with A's tree).
- **FR2**: A (`engine/x` = e1), A1 (`engine/x` = e2), then B, a child of A1 changing
  `docs/y`, at HEAD; origin/main at A; X, a child of A1 whose `engine/x` is e1 again, so
  X's `engine/` tree is A's but the merge base moves to A1.
- **Receipt calls.** Each FR scenario runs in one `( )` subshell of the part. The
  subshell sources the tree's `tests/receipt.sh` and calls `_rcp_begin`. Any mid-run move
  happens next, through `_fx_git`. Then it calls `_rcp_finish <root> <record> <compared>
  <judged> 5 <failed> 0` and `_sr_check`.

Controls are marked **(control)**: they are true before and after the fix. Every other
assertion fails on origin/main 69b51a61.

Part 1770:
- A1 (B1) FM, field 5 `tests`: the judge's whole output is the skipped line with
  NAMES `tests`.
- A2 (B1) Field 5 `tests,installed`: one line, NAMES `tests,installed`.
- A3 (B2) Field 5 `-`: no output. (control)
- A4 (B2) Field 5 `○,1`: no output.
- A5 (B2) Field 5 `○,1,tests`: NAMES `tests`.
- A6 (B2) Field 5 `-,tests`: NAMES `tests`.
- A7 (B2) Field 5 `--`: no output. (control)
- A8 (B1, B2) Field 5 `%s%n,tests`: NAMES `tests`, and the line holds no `%`.
- A9 (B3) Field 5 emptied by hand in the receipt file (the one under `$FROOT/state/gate/`
  whose content `felix_verify_receipt` prints): the R_UNSTATED line only.
- A10 (B4) A `tests` receipt, then a tracked file edited: the output holds the
  tree-changed line and no `<TAB>skipped<TAB>` line. (control)
- A11 (B4) A red `tests` receipt: the no-green-receipt line and no skipped line. (control)
- A12 (B5) Field 5 `-` with field 6 `syntax:ok,tests:skipped`: no output. (control)
- A13 (B6) Over A1 to A12, the gh stub's file stays empty. (control)
- A14 (B7) Field 5 `installed` with field 6 `syntax:ok,tests:reused`: exactly two lines,
  the skipped line (NAMES `installed`) first and C9's line second.
- A15 (B8) A1's receipt with `felix merge --dry-run`: exit 3.
- A16 (B8) The output holds `not merging` and the skipped CLI line.
- A17 (B8) It holds both closing lines and not `nothing escapes this tree, and the gate is
  green on it.`
- A18 (B9) Recorded again with `-`: exit 0 and `felix merge would squash this now.`
  (control)
- A19 (B10) FG, with a gate printing `tests skipped (no suite here)`: after `felix gate`,
  the receipt's field 5 is `tests`. (control)
- A20 (B10) Then `felix merge --dry-run` exits 3 with the skipped line.
- A21 (B11) FG, with a gate printing only `syntax ok`: the `qualified` line says
  `skipped`, field 5 is `-`, and the dry run exits 0. (control)
- A22 (B12) A1's receipt: `felix_verify_current` prints `current`. (control)
- A23 (B26) FC with the tree's own two files: `cloud ok`. (control)
- A24 (B26) FC, settings with the Stop hook's `statusMessage` changed: `cloud ok`.
  (control)
- A25 (B27) FC, plugin PreToolUse matcher widened by `|Glob|Grep`: `cloud FAIL`, and the
  detail holds `bound differently for the cloud: PreToolUse/pre-tool (matcher);`.
- A26 (B27) FC, five edits at once: the plugin matcher widened as in A25, settings
  pre-tool `async` set to `true`, the settings SessionStart `matcher` line removed, the
  plugin stop hook given `"timeout": 30`, and the settings SubagentStart entry removed.
  The detail holds `PreToolUse/pre-tool (matcher, async);`,
  `SessionStart/session-start (matcher);` and `Stop/stop (timeout);`.
- A27 (B28) The same run also says `not bound for the cloud:` and
  `SubagentStart/subagent-start`. (control)
- A28 (B29) FC, plugin SessionStart line written `"matcher":"startup|resume|clear|compact",`:
  `cloud FAIL`, and the detail holds `unreadable:` and `engine/hooks/hooks.json`.
- A29 (B25) In A23's run, the tests line is `skipped (--quick)` and the marker is
  absent. (control)
- A30 (B23) FT, stub prints `not reused: another tree`, a part line and
  `5 passed, 0 failed`, then exits 0: the three lines after the `tests ok` line, in order.
- A31 (B23) FT, stub writes `warning: x` to stderr with no newline, then
  `not reused: no receipt`: the line after the summary is 21 spaces and
  `not reused: no receipt`.
- A32 (B24) FT, reused stub: `tests reused`, and no line holds `not reused:`. (control)
- A33 (B25) FT, stub with no `not reused` line: the line after the summary is not
  indented 21 spaces. (control)

Part 1780:
- A34 (B13) FR1 at A, written by `_rcp_begin` and `_rcp_finish`: field 7 is
  `<_sr_env>;reads=<e>,<a>,<m>;origin=<A>`, with e, a and m computed by the git
  commands above.
- A35 (B14) origin/main to A_docs: `reuse 5 0 0 <end> normal`.
- A36 (B15) origin/main to A_eng: `run origin/main moved`. (control)
- A37 (B15) origin/main to Z: `run origin/main moved`. (control)
- A38 (B15) FR2, origin/main to X: `run origin/main moved`. (control)
- A39 (B15) The origin/main ref deleted: `run origin/main moved`. (control)
- A40 (B13, B15) Written with no origin/main, then the ref set to A: field 7 is
  `_sr_env` alone (control), and then `run origin/main moved` (control).
- A41 (B16) A today-form receipt written by hand as part 1260 writes one, with origin
  at A: reuse. (control)
- A42 (B16) The same receipt with origin at A_docs: `run origin/main moved`. (control)
- A43 (B17) A34's field 7 with `e` set to `zz`: `run malformed receipt`.
- A44 (B17) The same with `a` set to `maybe`: `run malformed receipt`.
- A45 (B17) The same with the `;origin=` tail cut: `run malformed receipt`.
- A46 (B18) A34's receipt with fields 8 and 9 moved back 50000 s and origin at A_docs:
  `run older than 12 hours`.
- A47 (B18) The same, aged, with origin at A_eng: `run origin/main moved`. (control)
- A48 (B19) origin moved to A_docs between begin and finish: the receipt exists, field 7
  ends `;origin=<A>`, and `_sr_check` reuses it.
- A49 (B20, reason 5) Moved to A_eng between begin and finish: stdout is exactly
  `  receipt not written: origin/main moved during the run`, and there is no receipt.
- A50 (B20, reason 1) Finish with failed set to 2: `the run had failures`.
- A51 (B20, reason 2) Finish with compared set to 0: `the manifest was not compared`.
- A52 (B20, reason 3) `FELIX_UNTRACKED_CAP=1` with two untracked files:
  `the tree could not be read when the run began`.
- A53 (B20, reason 4) PATH extended between begin and finish:
  `the environment changed during the run`.
- A54 (B20, reason 6) Record mode with judged set to 0:
  `the record this run wrote was not judged`.
- A55 (B20, reason 8) Normal mode, an untracked file added during the run:
  `the tree changed during the run`.
- A56 (B20, reason 8) Record mode, judged, with `docs/y` edited:
  `the tree changed during the run, beyond the manifest and red.tsv`.
- A57 (B20) Failed set to 2 and PATH changed: only `the run had failures`.
- A58 (B20) A clean pass prints no `receipt not written` line and leaves a receipt.
  (control)
- A59 (B21) FR1: `docs/y` edited, the receipt written, the change committed, origin/main
  moved to A_docs; `_sr_check` then answers `reuse 5 0 0 <end> normal <HEAD sha>`.
- A60 (B22) `grep -cF 'GitHub CI still runs the whole suite on Linux before anything
  merges'` over `$REAL_HARNESS/tests/receipt.sh` prints `0`.

## 5. Parts

- `engine/harness/tests/parts/1770-merge-and-gate-say-what-ran-blind.sh`: A1 to A33
  (C003, C110, and the gate's not-reused line), and A61 to A68 (section 9).
- `engine/harness/tests/parts/1780-the-receipt-keys-on-what-the-suite-reads-blind.sh`:
  A34 to A60 (C045's receipt).

Both are sourced from `tests/run` in numeric order, after 1600 and before 9990.

## 6. Out of scope

- **C044**, choosing tests by reach. It is the founder's design to approve.
- **`felix next` rank 1 and `felix receipt`'s status reading the skip** (spec §2.1, §2.7).
  They label a tree and land nothing, so a session learns of the refusal at `felix merge
  --dry-run`. This is a follow-up, and the binding on later readers stays the spec's.
- **The Stop hold on a skipped green.** The spec decided in §2.4 that it stays a speed
  bump: a session may end on an honest partial green, and the merge is where the claim
  crosses into main.
- **Letting CI's gate run clear a skipped green, as C9 does for a reused one.** Rejected
  by spec §2.6: only CI's exit status leaves the runner, felix-home's CI gate itself
  reports `installed` skipped on every run, and direction.md:212 calls the tick's C9
  check a narrowing, not the fix. The consequence is accepted and stated. After this lands and is installed (main's
  installed kernel judges felix-home), a `--quick` green no longer merges. A docs-only
  branch pays one full local suite before `felix merge`, and the land tick records
  `refused` for such a pull request until its head or main moves. This PR's own merge is
  judged by the old kernel.
- **Moving the cloud check into a bin command so that felix qualify can pin it.** That
  is a new tool plus a qualification row: a change of its own.
- **Comparing `shell`, `type`, `statusMessage`, and settings bindings the plugin lacks**
  (a hook firing twice in the cloud). Neither is the deny path.
- **Editing the dated design and contract documents.** The design doc's line 13 records
  the founder's own words. The live comment is corrected instead (B22).

Not fixed, because they are not defects:
- **C045's README-typo half.** Part 0840 reads the branch's README.md (lines 93, 187,
  227, 256, 311), and parts 0400, 0620 and 0730 read projects/felix files from the
  checkout. A README or projects edit can therefore change the verdict, and `another
  tree` is the right answer.
- **C045's missing change-to-part map.** It is a recorded scope choice
  (gate-friction-design.md:294-296, "Skipping parts a diff cannot reach"), and C044
  carries it.
- **C045's citation of gate-friction-design.md:45.** That sentence is about red.tsv, not
  the receipt.
- **C003's README.md:139.** "unless the gate passed on exactly this tree" is literally
  true of a `--quick` pass, and README:353-357 states the limit.

## 7. Founder PR

**The receipt change only the founder may merge.** Every change to
`engine/harness/tests/receipt.sh` fires risk.tsv row 45:
`yellow path ^engine/harness/tests/(red|receipt\.sh)$ ... verifier`. That row has no
confine, so `felix merge` refuses the pull request as an escape and the land tick will
not land it.

Exact change, as its own pull request: `tests/receipt.sh` (and any lib file it sources
for this) per B13 to B22, part 1780, the two restated assertions in
`1230-gate-friction-a-addendum-blind.sh`, the tests/run line for 1780, the record, and
the carrier's version. It merges main in after the first pull request lands, records again, and is merged by
the founder by hand.

**Everything else lands on green**: C003, C110, B23 to B25, part 1770, the restated 0100
assertion, and the tests/run line for 1770. Gate.sh's pass, fail and check count stays
at 26 or more. No .github/workflows, deny row, escape row or commission grant is needed.

## 8. Red

Run on the blind-parts commit d3395df2 (the origin/main 69b51a61 tree plus the two new
parts and their tests/run lines, no code changed), under macOS awk and bash 3.2, with
`tools/alone.sh <worktree> bwk 1770-... 1780-...` from a fresh temporary directory.
The run exited 0 with 88 `ok`, 34 `FAIL` and 0 `skip`. Of the 88, 62 are the driver's
fixture-floor lines (part 0002, which `--part` always runs), so the 60 assertions A1 to
A60 are **34 failed and 26 passed**.

Failed (34): A1, A2, A5, A6, A8, A9, A14, A15, A16, A17, A20, A25, A26, A28, A30, A31,
A34, A35, A43, A44, A45, A46, A48, A49, A50, A51, A52, A53, A54, A55, A56, A57, A59, A60.
Each failed for the reason its contract line gives: no skipped line from the judge, `cloud
ok` for a matcher that differs, no `not reused:` line under the gate's `tests ok`, field 7
without `;reads=`, `run origin/main moved` for a docs-only move, `run another environment`
where `run malformed receipt` is due, and no `receipt not written:` line.

Passed (26), and why:
- **Controls, true before and after (25):** A3, A7, A10, A11, A12, A13, A18, A19, A21,
  A22, A23, A24, A27, A29, A32, A33, A36, A37, A38, A39, A40, A41, A42, A47, A58. Each is
  marked (control) in section 4, and each passed on the unfixed tree, as that mark says.
- **Already true, not marked as a control (1):** A4 (field 5 `○,1` gives no output). It
  passes only because the judge on this tree prints no skipped line for any field 5, so it
  holds for the wrong reason. A5 and A6 are the assertions that make an off-shape item
  mean something, and both failed.
- **Vacuous:** none found. A13 (the gh stub's file stays empty over A1 to A12) is the
  nearest. It is a control that cannot fail until the judge may call gh, and A14, which
  records a `tests:reused` receipt, fails for the right reason.

## 9. Review round

Two review findings against fix commit 318e32e3. Both are C110, and they land with the
first pull request (section 7). Their assertions are A61 to A68, in part 1770, over FC.

**M1.** A binding was recorded only when its hook object opened at exactly
`^          {` and closed at `^          },?$`, and B29 looks only at matcher, async and
timeout lines. A plugin hook written on one line, or indented 12 spaces, was dropped, so
a plugin hook missing from settings read `cloud ok` where origin/main 69b51a61 says
`not bound for the cloud: PreCompact/pre-compact`: B28 broke. A PreToolUse group closed by
a line with trailing spaces, in both files, took the next group's matcher in both, so a
widened plugin matcher read `cloud ok`.

**B30.** Every hook command naming `harness/hooks/<name>` is a binding of the event and
group it sits in, whatever the layout of the lines B29 does not name (braces, brackets,
`type`, `command`, `shell`, `statusMessage`). A hook object on one line, or at another
indentation, is read. Its matcher is its own group's, however that group's lines end;
its `async` and `timeout` are `-` when it has none. A plugin binding that settings lack
gives `not bound for the cloud: <Event>/<hook>` (B28), and one bound under another
matcher gives B27's clause. Neither reads `cloud ok`.

**M2.** A hooks.json identical to the tree's except for its final newline, which is
exactly what Python's `json.dump(indent=2)` writes, failed the check with `unreadable: no
event-to-hook pairs read from one of the two files`. The two files were read as one
stream, which joined the plugin's last `}` to the settings' opening `{`. Origin/main
reads each file separately and finds them agreeing.

**B31.** Each file is read on its own, and a missing final newline changes nothing read
from it. The tree's two files give `cloud ok` with either or both lacking it, a
difference in such a file is still found, and nothing is called unreadable for it.

Assertions (FC, run as A23 is):
- A61 (B30) The plugin gains `PreCompact` before `SubagentStart`: one group, no matcher,
  its hook the single line `          { "type": "command", "command":
  "\"${CLAUDE_PLUGIN_ROOT}/harness/hooks/pre-compact\"" }`. Settings are unchanged.
  `cloud FAIL`, and the detail holds `not bound for the cloud:` and `PreCompact/pre-compact`.
- A62 (B30) The same hook as four lines, braces at 12 spaces, no async: the same.
- A63 (B30) Both files' PreToolUse group close `      }` gains two trailing spaces, and
  the plugin matcher gains `|Glob|Grep`: `cloud FAIL`, with A25's clause.
- A64 (B30) Both files gain a PreCompact group with a one-line hook (settings' carries its
  guard), under `"matcher": "manual"` in the plugin and `"auto"` in settings: `cloud
  FAIL`, with `bound differently for the cloud: PreCompact/pre-compact (matcher);`.
- A65 (B31) hooks.json with no final newline: `cloud ok`.
- A66 (B31) settings.json with no final newline: `cloud ok`. (control)
- A67 (B31) Both files with no final newline: `cloud ok`.
- A68 (B31) hooks.json widened as in A25 and with no final newline: `cloud FAIL`, with
  A25's clause and no `unreadable:`.

Red, 2026-10-26: 18658554 plus this block, `tools/alone.sh <worktree> bwk 1770-...`.
The run exited 0 with 96 `ok`, 7 `FAIL` and 0 `skip`. That is 62 floor lines and A1 to
A33 all passing. Of A61 to A68, **7 failed and 1 passed**. The pass is A66, the control:
settings.json comes second in the joined read, so its missing newline joins nothing. A61 to
A64 failed with `cloud ok`; A65, A67 and A68 failed with the `unreadable:` line above.
gawk 5.4.1 gave the same counts.
