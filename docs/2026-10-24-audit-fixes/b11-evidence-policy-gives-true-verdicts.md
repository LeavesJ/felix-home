# Audit b11: the evidence policy gives true verdicts

Batch b11 of the 2026-10-24 audit register: C024 (high), C074 (low) and C078
(low). Branch `claude/audit-b11-evidence-policy-gives-true-verdicts`, cut from
origin/main at 69b51a61. This file is the whole specification the blind
assertions are written from. It says what must be true, not how.

The batch ships as two pull requests:

- **The engine PR** (this branch): B1 to B19, part 1830. Felix lands it.
- **The founder PR**: B20 and B21, part 1831, and the new rows of the seeded
  template. It edits an escape table, so only the founder merges it
  (section 7). The two are independent and can land in either order.

Terms used below:

- **The check** is `felix_evidence_check PROJ BASE ROOT` (lib/evidence.sh,
  sourced after lib/resolve.sh). It prints one line per result,
  `status<TAB>name<TAB>reason`.
- **A row-level unknown** is a line of the check whose status is `unknown`
  because one row, or the table, could not be judged (B1 to B4).
- **A whole-scan unknown** is one of the two `unknown` lines that exist today:
  a base that names nothing, and a change git cannot list in full (B5).
- **A cell cannot compile** when `LC_ALL=C grep -E -e CELL </dev/null` exits
  with a status above 1.
- `<TAB>` in a fixture row is one tab character.

## 1. Defects

**C024** (high, kept by both skeptics). The seeded evidence policy is copied
unchanged into seven of the eight product projects, and its verdicts are
wrong in both directions. `felix merge` enforces those verdicts.

- A test beside its code gives a false gap.
- Code under a nested `src/` gives n/a.
- Any file under `tests/`, a README included, gives met.
- A cell grep cannot read gives n/a or gap, and grep's error is thrown away.

Scenario: a Go change to `internal/handlers/auth.go` plus `auth_test.go`
reads `gap unit` and `gap api`. The merge refuses it, and only the founder
can clear it, because the fix is an edit to an escape table. Meanwhile a
change that deletes `packages/server/src/middleware/ratelimit.ts` reads n/a
on all five rules, and `felix evidence` prints "No evidence gaps". A change
to `src/auth/session.ts` that also touches `tests/README.md` reads `met
unit`. A `when` cell of `^(src|lib/` reads n/a for a change under src/, and
the merge sends grep's complaint to /dev/null.

Two parts of the same defect are fixed here as well:

- `felix_brief_evidence` (intake.sh:28-39) and `felix incident`
  (felix:4794-4803) drop an unreadable row without a word.
- `felix evidence` tells the agent a pull request note answers a gap, but
  felix merge never reads one (felix:4180).

Corrections from the skeptics, followed here:

- A Rust workspace is not blocked. It reads n/a everywhere.
- The land-on-green tick clause does not apply (section 6).
- The empty-cell column shift is mostly guarded by table.sh at the gate.
- A bad regex comes only from a person's edit.

**C074** (low; the kind is incomplete, not naive). The final-filter rule
refuses a judged column only when a final filter is the reason it cannot
fail. So a text that runs a check and then discards its status is admitted:
`pytest || true`, `make test; exit 0`, `make test || :`. Such a text reads
SATISFIED or done whatever the check does.

Scenario: an obligation is added with evidence `pytest || true`. The tests
fail and it reads ACTIVE SATISFIED. Adding a row costs nothing at the merge
boundary. Loosening an existing row in place escapes to the verifier channel,
so only an added row slips through. No real table holds one today.

**C078** (low). `felix review --pass` records a pass in each of these cases:

- there is no `--in` at all;
- the `--in` path does not exist;
- the `--in` path is a directory inside the reviewed checkout;
- the `--in` path is a work tree at another commit.

So the isolation check fires only for a reviewer who volunteers the exact
path of the reviewed checkout. The printed usage never mentions `--in`.

Scenario: a reviewer runs pytest in the live tree while someone keeps editing
it, then records `felix review --pass --by x` as the usage text shows.
escape.sh:409 reads that as a pass, and the `reviewed` escape on an Elenchus
rubric clears. A reviewer who honestly says `--in <the live tree>` is
refused, so stating where it ran is the only thing penalised.

## 2. Required behaviour

The unknown and failure paths are B1 to B4, B6, B8 to B13, B16 and B17.

### The check (lib/evidence.sh)

- **B1.** A row whose `when` cell cannot compile, for example
  `unit<TAB>^(src|lib/<TAB>^tests/<TAB>code changes need a test`.
  - The check prints `unknown<TAB>unit<TAB>R` in that row's place in file
    order.
  - R contains `when cell` and `not judged`. It should also carry grep's own
    message, with any tab or newline turned into a space.
  - The same line is printed whatever the change touches: a change that adds
    src/a.ts and a change that adds only docs/x.md both get it.
  - That row never prints `n/a`, `met` or `gap`.
  - The function's exit status stays 0, as today.
- **B2.** A row whose `when` cell compiles and whose `requires` cell does not,
  for example `unit<TAB>^src/<TAB>^(tests/<TAB>code changes need a test`.
  - The check prints `unknown<TAB>unit<TAB>R`, where R contains
    `requires cell` and `not judged`.
  - This holds whatever the change touches, with or without a test file.
- **B3.** A row that does not split on tabs into exactly four non-empty
  cells: a doubled tab, a leading tab, a trailing tab, three cells or five.
  - The check prints `unknown<TAB>NAME<TAB>R`, where R contains `cells` and
    `not judged`.
  - NAME is the row's first cell when that cell is non-empty. Otherwise it is
    `evidence.tsv:N`, where N is the row's 1-based line number in the file,
    counting comment and blank lines.
  - No cell is ever read as the column after it. In particular,
    `unit<TAB><TAB>^tests/<TAB>code changes need a test` is never judged with
    `^tests/` as its `when`.
- **B4.** An evidence.tsv that exists but cannot be read (mode 000, as a user
  who is not root).
  - The check prints exactly one line, `unknown<TAB>evidence.tsv<TAB>R`, where
    R contains `not judged`. Today it prints nothing, which reads as "no rules
    declared".
  - A missing evidence.tsv still prints nothing, since schemas.tsv allows the
    table to be absent.
- **B5.** These stay as they are today:
  - A row whose cells all compile and that has four non-empty cells is judged
    exactly as now:
    - `n/a` with reason `this change does not touch that surface` when no
      changed path matches `when`;
    - `met` when some changed path matches `requires`;
    - `gap` otherwise.
    `met` and `gap` carry the row's own reason, and the lines come out in file
    order.
  - A table holding both broken and valid rows prints a line for every row,
    and the valid rows are judged as above.
  - Cells are compiled and matched under LC_ALL=C, whatever the caller's
    locale. The row `api-tests<TAB>^src/api/|^caf\351/<TAB>^tests/<TAB>...`,
    whose `when` cell holds a Latin-1 byte, gives `gap` for a change adding
    src/api/x.py in a UTF-8 locale. It never gives `unknown`.
  - Comment lines are skipped, whatever byte follows the `#`.
  - An exported GREP_OPTIONS changes nothing.
  - A base that names nothing gives exactly one line,
    `unknown<TAB>BASE<TAB>...no rule was consulted`. A change git cannot list
    gives exactly one line, `unknown<TAB>CHANGED-PATHS<TAB>...`. In both
    cases no row is consulted.
  - With no evidence.tsv, nothing is printed.

### felix evidence

- **B6.** When the check returns a row-level unknown:
  - Each one is printed in the existing `[?]` layout, as a line beginning
    `  [?] NAME`.
  - The other rows are printed as today, as `[x]`, `[!]` or `[-]`.
  - The exit status is 1, with or without `--strict`.
  - The output contains neither `No evidence gaps` nor `Nothing was compared`.

  The output for a whole-scan unknown stays exactly as it is today.
- **B7.** When there is at least one gap:
  - The advice printed after the count contains `felix merge`, saying that it
    refuses while a gap stands.
  - The advice does not contain `pull request`.
  - With no row-level unknown, the exit status stays 0 without `--strict` and
    1 with it. With a row-level unknown, B6's exit status of 1 applies.

### felix merge

- **B8.** `felix_merge_blockers PROJ BASE ROOT HOME` (lib/escape.sh):
  - For each row-level unknown it prints exactly one line,
    `evidence<TAB>NAME<TAB>R`, where R is the check's reason and contains
    `not judged`.
  - Gap lines are unchanged: `evidence<TAB>NAME<TAB>`, then the row's reason.
  - For a base that names nothing, no line has `evidence` as its first field.
    The base is reported once, by the `unknown<TAB>BASE<TAB>...` line that
    felix_escapes prints today.
  - `felix merge` over a tree with a row-level unknown exits 3. It prints
    `not merging`, the row's name and `not judged`. It does not print
    `Nothing was compared`, which is the paragraph for a base that names
    nothing.

### felix classify, felix receipt, felix next

- **B9.** `felix classify` at tier green, with a row-level unknown and no
  gap:
  - It prints `tier:  green`, `Not auto-merge eligible` and `not judged`.
  - It never prints `Eligible for auto-merge` or `nothing is unproven`.
  - The exit status is unchanged.
  - With no gap and no unknown it still prints `Eligible for auto-merge`.
- **B10.** `felix receipt` (`felix_receipt`) with a row-level unknown:
  - The `"unknown"` array contains `"evidence"`.
  - `"status"` is `"indeterminate"`.
  - `"autonomous"` is `false`.
  - The row's name is in neither `evidence.met` nor `evidence.gap`.

  Without a row-level unknown, the receipt is unchanged.
- **B11.** `felix next` (`felix_next`) with a row-level unknown:
  - It prints a rank-1 row owned by `felix` whose text names the row and
    contains `not judged`.
  - The command prints it under `the change in hand`, on a line beginning
    with the owner `felix`.
  - Gap rows are unchanged: `the change owes evidence: NAME — reason`.

### The forward question: felix brief and felix incident

- **B12.** `felix_brief_evidence PROJ PATHS` (lib/intake.sh):
  - For every row the check would report as a row-level unknown (B1 to B4),
    it prints `NAME<TAB>T`, where T contains `not judged`, whatever PATHS
    holds.
  - A valid row is printed as today: `NAME<TAB>reason`, once, when some path
    in PATHS matches its `when`, and nothing otherwise.
  - Cells are matched under LC_ALL=C, so in a UTF-8 locale B5's Latin-1 row
    is printed as matched for src/api/x.py. Today grep fails in that locale
    and the row is dropped.
  - It works when the caller sources lib/intake.sh but not lib/evidence.sh.
    0070's `_brief` sources only classify, incident, route and intake.
  - `felix brief` prints these rows under `what a fix must prove`.
- **B13.** `felix incident` prints every row that B12's rule gives under
  `the fix will have to prove`, with the row's name. A row-level unknown is
  printed with `not judged`. Valid rows are printed as today.

### C074: a judged command that discards its status

- **B14.** This applies to the four judged columns:
  - a commissioning check, on a row whose answer is not `provider:`;
  - an obligation's evidence;
  - a setup check;
  - a maintenance event row's check.

  A text in one of these columns is refused when all three of these hold:
  1. it runs at least one command that can fail;
  2. no path through it ends in failure;
  3. no final filter is why (that case keeps its own reason).

  `felix_final_filter_table FILE`, and every runner through it, reports such a
  row as `LINE<TAB>WHO` followed by
  `cannot fail: it runs something that can fail, and no path through it ends in failure`.
  WHO is `the evidence contract ` for obligations.tsv and `check ` for the
  other three tables.

  These are refused, for example:
  - `pytest || true`
  - `make test; exit 0`
  - `make test || :`
  - `make test > /dev/null 2>&1 || echo failed`
  - `npm test | tail -5; true`
  - `gh auth status || true`
  - `command -v jq || true`
  - `if make test; then echo ok; fi`
  - `touch FILE; pytest || true`
- **B15.** These stay as they are today:
  - A text that runs nothing that can fail is admitted: `true`, `:`,
    `echo ok`, `exit 0`.
  - A text with a path that ends in failure is admitted: `pytest`,
    `make test || exit 1`, `cd d && make test | tail -20`.
  - A final filter keeps its own reason: `make test | tail -20` is refused,
    naming `tail` and saying it `succeeds whatever it is fed`.
  - Every admit-when-unsure condition in final-filter.sh's header still
    admits, the nounset one included:
    - `set -o pipefail; make test || true` is admitted.
    - The commissioning check `test -n "$SOME_UNSET_NAME" || true` is
      admitted. Commissioning evaluates under `set -u`, where that name ends
      the shell in failure.
  - Columns that are not judged stay unjudged: commissioning `when`,
    obligations `applies`, and probes.
  - `felix_final_filter TEXT` prints and exits exactly as today for every
    text, because it answers only which final filter a text ends in.
    `felix_final_filter 'make test || true'` and `felix_final_filter 'true'`
    each exit 1 and print nothing. Every line of 0681's corpus still holds.
  - When the awk pass fails, every line is still led by
    `check could not be judged`.
- **B16.** A runner never runs a row that B14 refuses, and lists it as
  refused. Take an obligation whose evidence is `touch FILE; pytest || true`:
  - felix_obligations_run does not run it, so FILE is never created;
  - felix_obligation_malformed names it, with B14's reason;
  - `felix obligations` prints it under `rows refused`.

  The existing paths for refused rows do the same for commissioning
  (`felix commission --status` counts the row as malformed), setup (the row
  reads todo) and maintenance.

### C078: where a passing review ran

The reviewed checkout is the repository root felix resolves from the current
directory, the root whose tree id the verdict is keyed to.

- **B17.** `felix review --pass --by R [--note N]` exits non-zero, prints why,
  and leaves the tree's verdict as it was (none, or the earlier one) in each
  of these cases:
  - a. There is no `--in`. The message contains `--in`.
  - b. `--in` names a path that does not exist.
  - c. `--in` names a directory that is in no git work tree.
  - d. `--in` resolves into the reviewed checkout's own work tree: the
    checkout itself, a symlink to it, or a directory inside it.
  - e. `--in` names a work tree whose HEAD commit is not the reviewed
    checkout's HEAD commit. The message contains `commit`.
  - f. Either HEAD cannot be read: an `--in` repository with no commit yet,
    or a reviewed checkout with none. The message contains `commit`.
- **B18.** `felix review --pass --by R --in WT`, where WT is a separate work
  tree (made by `git worktree add`, or a clone) whose HEAD is the reviewed
  checkout's HEAD:
  - It exits 0 and prints `recorded: pass by R`.
  - `felix review` then prints `verdict:  pass`.
  - The record's sixth field names WT.
  - felix_review_passed is true for the tree, so the `reviewed` channel clears
    as it does today.

  These are unchanged:
  - `--block` is recorded with or without `--in`, whatever directory it
    names. A block is never refused for where it ran.
  - felix_review_record, called directly, keeps its contract. A pass with no
    `where` is recorded, and a pass whose `where` resolves to the root is
    refused with status 1 (0100, 0340).
- **B19.** `felix review` with no verdict flag, on a tree with no verdict,
  prints a usage line for `felix review --pass` that contains `--in`.

### The seeded template (founder PR)

- **B20.** Copy engine/harness/templates/evidence.tsv byte for byte as a
  project's evidence.tsv. Build each fixture repository from a `main` commit
  holding a README and any file the change deletes. The check then gives the
  verdicts below, and every row not named reads `n/a`. `+P` adds P; `-P`
  deletes P, which was committed on main.

  | change | verdicts |
  |---|---|
  | +internal/handlers/auth.go +internal/handlers/auth_test.go | unit met, api met |
  | +internal/handlers/auth.go | unit gap, api gap |
  | +src/auth/session.ts +src/auth/session.test.ts | unit met |
  | +src/auth/session.ts +src/auth/\_\_tests\_\_/session.test.ts | unit met |
  | +src/pkg/core.py +src/pkg/tests/test_core.py | unit met |
  | +crates/core/src/lib.rs +crates/core/tests/it.rs | unit met |
  | +crates/core/src/lib.rs | unit gap |
  | -packages/server/src/middleware/ratelimit.ts | unit gap |
  | -apps/api/src/middleware/ratelimit.ts | unit gap, api gap |
  | +src/auth/session.ts +tests/README.md | unit gap |
  | +agents/src/a.ts | unit gap |
  | +cmd/server/main.go | unit gap |
  | +src/main/java/com/x/Foo.java +src/test/java/com/x/FooTest.java | unit met |
  | +migrations/001.sql +internal/db/store_test.go | unit met, database met |
  | +services/api/Dockerfile | config gap |
  | +apps/web/src/components/Button.tsx | unit gap, e2e gap |
  | +src/api/users.ts +tests/api/README.md | unit gap, api gap |
  | +src/thing.js +tests/thing.test.js | unit met |
  | +app/models/user.rb +spec/models/user_spec.rb | unit met |
  | +src/api/users.ts +tests/api/users.test.ts | unit met, api met |
  | +migrations/001.sql | database gap |
  | +README.md | every row n/a |
  | +book/src/chapter.md | every row n/a |

  These are the verdicts the proposed rows gave when run through the check
  of this tree on 2026-10-24.
- **B21.** The template is a valid table:
  - felix_table_check against templates/schemas.tsv exits 0 and prints
    nothing;
  - it has exactly five rows, named unit, database, e2e, api and config, in
    that order;
  - every `when` and `requires` cell compiles.

## 3. What must not change

These behaviours are pinned by existing parts, which the fix must keep green.
All parts are under engine/harness/tests/parts/.

- **The whole-scan unknown and its texts.** An unresolvable base:
  - `felix evidence` names the base, says nothing was compared, never says
    "No evidence gaps" or "does not touch that surface", and exits 1;
  - the check prints `unknown`;
  - classify reports unknown, and `felix pr` never labels the branch green.

  A corrupt index gives exactly one unknown row (E5). A base too large for a
  pipe is handled.

  Pinned by `0110-a-base-ref-that-is-behind-its-remote.sh`,
  `1520-git-readers-fail-closed.sh`, `0100-merging.sh` (the unknown base is
  not an escape) and `0970-membership-in-a-list-larger-than-a-pipe-cove.sh`.
- **Gaps and how they are rendered.**
  - An untested change blocks the merge, naming `evidence` and `unit`
    (`0100-merging.sh`).
  - `felix evidence` prints `[!] unit` and the row's reason, `[x] unit` once
    the test is added, `[-] db`, and "No evidence gaps" for a docs-only
    change. `--strict` exits 1 on a gap, and a plain run exits 0.
  - Green plus a gap prints "Not auto-merge eligible".
  - `felix incident` prints "the fix will have to prove".

  Pinned by `0110-a-base-ref-that-is-behind-its-remote.sh`.
- **The rest of the evidence surface.**
  - Staged changes and staged tests count:
    `0360-what-felix-merge-records-and-what-it-hands-g.sh`.
  - The brief says what a fix must prove: `0070-stack-provisioning.sh`.
  - `felix next`'s evidence row: `0600-what-to-do-next.sh`.
  - The receipt's refusal to claim more than it knows:
    `0370-a-receipt-that-cannot-claim-more-than-it-kno.sh`.
  - evidence.tsv belongs to the policy table set:
    `0510-the-receipt-carries-the-epoch-and-a-fact-tha.sh`.
- **Locale and environment.**
  - A commented row whose second byte is Latin-1 is skipped, and the same row
    uncommented gaps, in C and in UTF-8 (`0998-continued.sh`, F8).
  - A `when` cell holding byte \351 still gives `gap` in a UTF-8 locale
    (`0994-bash-s-own-collation-and-the-bsd-text-tools.sh`, E13). The new
    compile check must run under LC_ALL=C, or this goes `unknown`.
  - `felix evidence` is unchanged under an exported GREP_OPTIONS
    (`1510-no-caller-environment-changes-a-tool-s-output.sh`).
- **Felix's own table.** No row requires a pattern that matches everything
  (`0240-continued.sh`).
- **The final filter.**
  - `felix_final_filter`'s outputs, including `true`, `x | tail &` and
    `! x | tail` admitted, are pinned by `0681-continued.sh`.
  - The table-level refusals and admissions are pinned by `0681-continued.sh`
    and `0690-continued.sh`: `ffs_true` (`true`) reads done, `ffo_headsub`
    and `ffo_headmid` hold, and `ffc_neg` (`! true`) is not refused.
  - The widget fixture's obligation, whose evidence is `true`, holds
    (`0004-the-widget-fixture.sh:131`).
  - Fixtures that use `true` as the check that holds:
    `0400-candidates-what-a-model-proposed-and-nothing.sh`,
    `0410-an-answer-that-is-neither-yes-nor-no.sh`,
    `0420-obligations-what-would-discharge-each-by-nam.sh`,
    `0490-qualification-does-a-check-fail-when-what-it.sh`,
    `0710-commissioning-a-seeded-check-reads-done-only.sh` and
    `0980-qualification-commissioning-adoption-the-led.sh`.
  - A commissioning `when` of `cat >/dev/null; true` is not judged
    (`0660-continued.sh`).
- **The review library.** Pinned by `0100-merging.sh` and
  `0340-the-line-that-does-the-work.sh`:
  - a verdict for another tree does not clear;
  - a block does not clear;
  - a pass with no `where` clears;
  - a pass whose `where` is the root is refused with status 1, and the
    earlier verdict stays;
  - a pass whose `where` names a directory that does not exist is recorded
    and names that place;
  - a block from the live tree is recorded;
  - a verdict never clears a durable escape;
  - the kernel's pass clears.

Constraints on the fix:

- **Line budgets.**
  - lib/escape.sh (799 lines) and engine/harness/felix (6734 lines) must not
    get longer.
  - lib/final-filter.sh (441) must stay at 500 or fewer.
  - lib/evidence.sh, lib/intake.sh, lib/review.sh, lib/next.sh and
    lib/receipt.sh stay under 500.

  Two edits make room:
  - Fold cmd_incident's own loop over the table (felix:4794-4803) into
    felix_brief_evidence. That frees the lines the other edits to felix need,
    and B13 then follows from B12.
  - Change the merge filter at escape.sh:672-676 in place.

  Put the C078 checks in a lib/review.sh function that cmd_review calls.
- **Reading the table.**
  - Every grep and awk that reads evidence.tsv runs as `LC_ALL=C`.
  - A cell reaches grep through `-e`, so a cell that begins with `-` is a
    pattern, not an option.
  - No evidence row is split by a tab-IFS read, which collapses empty cells.
- **Portability.** The fix must work under bash 3.2 and bash 5, and with BWK
  awk and gawk. There is no `case` inside `$( )` and no associative array.
- **Felix's own rules.** The felix project's evidence.tsv applies to the
  engine PR: a suite part, and the version slot its deploy row asks for. The
  slot is carried by whoever lands the PR, not by this contract.
- **Overlap with other batches.** b10 edits escape.sh and b19 edits next.sh.
  Expect small conflicts at escape.sh:672-676 and next.sh:82-90.

## 4. Assertions

### Fixtures

- **F1, the library check.**
  - A directory P holding evidence.tsv with the rows given.
  - A git repository G with one commit on main (README) and a branch `work`
    whose one commit adds the files named.
  - The check runs as `felix_evidence_check P main G` in a subshell that
    sources lib/resolve.sh and lib/evidence.sh, with cwd G and stdin
    /dev/null.
- **F2, the commands.**
  - The widget fixture: `$FROOT/projects/widget` and its checkout `$REPO`,
    from 0004-the-widget-fixture.sh.
  - Widget's evidence.tsv is replaced by the rows given and restored
    afterwards.
  - The change is staged as 0110's evidence section stages it.
  - Each command runs from `$REPO` with `--base HEAD~1`, except felix merge,
    which takes the base 0100 passes it.
- **F3, the merge library.** F2, then `felix_merge_blockers` with the
  libraries that 0100's `_blk` sources.
- **F4, the final-filter tables.** A directory holding one table file, named
  obligations.tsv, commissioning.tsv, setup.tsv or maintenance.tsv, with the
  rows given. Run `felix_final_filter_table FILE` after sourcing
  lib/final-filter.sh. The row shapes are:

  ```
  obligations    oN<TAB>ADVISORY<TAB>deterministic<TAB>-<TAB>TEXT<TAB>-<TAB>a reason
  commissioning  need<TAB>-<TAB>-<TAB>-<TAB>-<TAB>TEXT<TAB>9
  setup          s1<TAB>a step<TAB>always<TAB>TEXT
  maintenance    m1<TAB>0<TAB>always<TAB>a check<TAB>TEXT
  ```
- **F5, the review.** The widget checkout `$REPO`, with at least two commits
  and a clean tree, plus:
  - WT, from `git -C "$REPO" worktree add --detach WT HEAD`;
  - WT1, the same at HEAD~1;
  - PLAIN, an empty directory in no git work tree (set GIT_CEILING_DIRECTORIES
    if the suite's temporary root could sit inside one);
  - UNBORN, a directory where `git init` ran and nothing was committed;
  - SUB, an empty directory `$REPO/sub` (an empty directory is no part of the
    tree id);
  - LINK, a symlink to `$REPO`.

  `felix review ...` runs from `$REPO`. "No verdict" means `felix review`
  prints `no verdict for this tree`. The refusals run before any pass is
  recorded.
- **F6, the template.** A directory P holding a byte copy of
  engine/harness/templates/evidence.tsv. Each scenario gets a fresh
  repository built as in F1, where `-PATH` means PATH is committed on main and
  deleted on `work`. The check runs as in F1.

Two tables are reused below:

- **T1** is the single row `unit<TAB>^(src|lib/<TAB>^tests/<TAB>code changes need a test`.
- **T2** has two lines: `code<TAB>^src/<TAB>^tests/<TAB>behaviour needs a test`,
  then T1's row.

An assertion marked **(control)** is true before the fix and after it. Every
other assertion fails on today's tree.

### Part 1830 (engine PR)

| A | B | Fixture | Expected |
|---|---|---|---|
| A1 | B1 | F1, T1; adds src/a.ts | exactly one line: `unknown`, `unit`, a reason containing `when cell` and `not judged` |
| A2 | B1 | F1, T1; adds only docs/x.md | field 1 is `unknown` |
| A3 | B2 | F1, `unit<TAB>^src/<TAB>^(tests/<TAB>code changes need a test`; adds src/a.ts | `unknown`, `unit`, a reason containing `requires cell` and `not judged` |
| A4 | B2 | A3's table; adds src/a.ts and tests/a_test.py | field 1 is `unknown` |
| A5 | B3 | F1, `unit<TAB><TAB>^tests/<TAB>code changes need a test`; adds tests/a.py | exactly one line: `unknown`, `unit`, a reason containing `cells` and `not judged` |
| A6 | B3 | F1, `unit<TAB>^src/<TAB>^tests/` (three cells); adds src/a.ts | `unknown`, `unit` |
| A7 | B3 | F1, line 1 `# a comment`, line 2 `<TAB>unit<TAB>^src/<TAB>^tests/<TAB>a reason`; adds src/a.ts | `unknown`, field 2 `evidence.tsv:2` |
| A8 | B3 | F1, `unit<TAB>^src/<TAB>^tests/<TAB>a reason<TAB>` (trailing tab); adds src/a.ts | `unknown` |
| A9 | B4 | F1, T2, evidence.tsv chmod 000; adds src/a.ts | exactly one line: `unknown`, `evidence.tsv`, a reason containing `not judged`. Skip (not pass) if the file is still readable; restore the mode |
| A10 | B5 (control) | F1, T2; adds src/a.ts | two lines, the first exactly `gap<TAB>code<TAB>behaviour needs a test` |
| A11 | B5 (control) | F1, T2; adds src/a.ts and tests/a_test.py | the first line exactly `met<TAB>code<TAB>behaviour needs a test` |
| A12 | B5 (control) | F1, T2; base `no-such-ref` | exactly one line: `unknown`, `no-such-ref`, a reason containing `no rule was consulted` |
| A13 | B6 | F2, T2; change src/a.ts; `felix evidence` | the output contains `[!] code` and `[?] unit` |
| A14 | B6 | A13's run | exit 1 without `--strict`; neither `No evidence gaps` nor `Nothing was compared` |
| A15 | B6 | F2, T1; change README only; `felix evidence` | exit 1, and no `No evidence gaps` |
| A16 | B7 | F2, T2's first line alone; change src/a.ts; `felix evidence` | contains `felix merge`, does not contain `pull request` |
| A17 | B7 (control) | A16's fixture | exit 0 without `--strict`, 1 with it |
| A18 | B8 | F3, T2; change src/a.ts | a line whose fields are `evidence`, `unit`, and a reason containing `not judged` |
| A19 | B8 (control) | A18's run | the line `evidence<TAB>code<TAB>behaviour needs a test` |
| A20 | B8 (control) | F3, T2; base `no-such-ref` | no line whose first field is `evidence`; one line beginning `unknown<TAB>no-such-ref<TAB>` |
| A21 | B8 | F2, T1; change src/a.ts; `felix merge` | exit 3; the output contains `unit` and `not judged`, and not `Nothing was compared` |
| A22 | B9 | F2, widget risk.tsv appended with `green<TAB>path<TAB>^src/safe/<TAB>declared safe by this project` (as 0110 does), T1; change src/safe/x.js; `felix classify` | contains `tier:  green`, `Not auto-merge eligible` and `not judged`, and not `Eligible for auto-merge` |
| A23 | B9 (control) | A22's fixture with the table `docs<TAB>^docs/<TAB>^docs/<TAB>docs prove themselves` | contains `Eligible for auto-merge` |
| A24 | B10 | F2, T2; change src/a.ts; `felix receipt` | `"unknown"` contains `"evidence"`; `"status": "indeterminate"`; `"autonomous": false`; `"gap"` does not contain `"unit"` |
| A25 | B11 | F2, T2; change src/a.ts; `felix next` | a line containing `felix`, `unit` and `not judged` |
| A26 | B11 (control) | A25's run | contains `the change owes evidence: code` |
| A27 | B12 | `felix_brief_evidence P src/a.ts`, sourcing only lib/resolve.sh and lib/intake.sh, P holding T1 | exactly one line: field 1 `unit`, field 2 containing `not judged` |
| A28 | B12 | A27 with PATHS `docs/x.md` | the same line |
| A29 | B12 | A27 with A3's row | field 1 `unit`, field 2 containing `not judged` |
| A30 | B12 | A27 with A5's row | field 1 `unit`, field 2 containing `not judged` |
| A31 | B12 (control) | A27 with T2's first line alone | PATHS `src/a.ts` gives exactly `code<TAB>behaviour needs a test`; PATHS `docs/x.md` gives nothing |
| A32 | B12 | A27 with `api<TAB>^src/api/\|^caf\351/<TAB>^tests/<TAB>an api change ships a test` (the byte written with printf); PATHS `src/api/x.py`; LC_ALL and LANG set to a UTF-8 locale the machine has, skipped as 0994's are when it has none | exactly `api<TAB>an api change ships a test` |
| A33 | B12 | F2, T1; `felix brief --from - --title t`, reading an issue text that names a file present under src/ in `$REPO` | contains `what a fix must prove` and `not judged` |
| A34 | B13 | F2, T2, src/thing.js present in `$REPO`; `felix incident` reading a trace that names src/thing.js | after `the fix will have to prove`, contains `unit` and `not judged` |
| A35 | B13 (control) | A34's run | after that heading, contains `code` |
| A36 | B14 | F4 obligations.tsv, lines 1 to 5 with TEXT `pytest \|\| true`, `make test; exit 0`, `make test \|\| :`, `make test > /dev/null 2>&1 \|\| echo failed`, `npm test \| tail -5; true` | exactly five lines, first fields 1 to 5, each second field exactly `the evidence contract cannot fail: it runs something that can fail, and no path through it ends in failure` |
| A37 | B14 | F4 obligations.tsv, TEXT `if make test; then echo ok; fi` | one line with A36's reason |
| A38 | B14 | F4 commissioning.tsv, TEXT `gh auth status \|\| true` | one line, second field exactly `check cannot fail: it runs something that can fail, and no path through it ends in failure` |
| A39 | B14 | F4 setup.tsv, TEXT `command -v jq \|\| true` | one line with A38's reason |
| A40 | B14 | F4 maintenance.tsv, TEXT `make lint \|\| true` | one line with A38's reason |
| A41 | B15 (control) | F4 obligations.tsv, eight rows with TEXT `true`, `:`, `echo ok`, `exit 0`, `pytest`, `make test \|\| exit 1`, `cd d && make test \| tail -20`, `set -o pipefail; make test \|\| true` | prints nothing, exit 0 |
| A42 | B15 (control) | F4 obligations.tsv, TEXT `make test \| tail -20` | one line containing `tail` and `succeeds whatever it is fed`, and not `runs something that can fail` |
| A43 | B15 (control) | F4 commissioning.tsv, TEXT `test -n "$FELIX_B11_UNSET" \|\| true`, with that name unset | prints nothing |
| A44 | B15 (control) | `felix_final_filter 'make test \|\| true'` and `felix_final_filter 'true'` | each exits 1 and prints nothing |
| A45 | B16 | obligations.tsv holding `ffx<TAB>ADVISORY<TAB>deterministic<TAB>-<TAB>touch "$TMP/b11-ffx-ran"; pytest \|\| true<TAB>-<TAB>a discard` ($TMP expanded when the row is written), run through felix_obligations_run as 0681 runs its rows | `$TMP/b11-ffx-ran` does not exist afterwards; felix_obligation_malformed has a line beginning `ffx: ` that contains `runs something that can fail` |
| A46 | B19 | F5, before any verdict; `felix review` | a line containing both `--pass` and `--in` |
| A47 | B17a | F5; `felix review --pass --by r1 --note n` | exits non-zero; stdout and stderr together contain `--in`; no verdict afterwards |
| A48 | B17b | F5; `--pass --by r1 --in "$TMP/b11-no-such-dir"` | exits non-zero; no verdict |
| A49 | B17c | F5; `--in PLAIN` | exits non-zero; no verdict |
| A50 | B17d | F5; `--in SUB` | exits non-zero; no verdict |
| A51 | B17d (control) | F5; `--in "$REPO"`, then `--in LINK` | each exits non-zero; no verdict |
| A52 | B17e | F5; `--in WT1` | exits non-zero; output contains `commit`; no verdict |
| A53 | B17f | F5; `--in UNBORN` | exits non-zero; output contains `commit`; no verdict |
| A54 | B18 (control) | F5; `--pass --by r1 --in WT` | exit 0; contains `recorded: pass by r1`; `felix review` then prints `verdict:  pass` |
| A55 | B18 (control) | after A54, `felix_review_verdict "$FROOT" <widget project dir> "$(felix_tree_id "$REPO" "$FROOT")"` | the sixth tab-separated field contains WT's last path component |
| A56 | B18 (control) | F5; `felix review --block --by r3 --note x`, with no `--in` | exit 0; contains `recorded: block by r3` |

### Part 1831 (founder PR, red until change A in section 7)

Each row below is F6. "Others n/a" means every row of the template not named
reads `n/a`.

| A | B | Change | Expected |
|---|---|---|---|
| A57 | B20 | +internal/handlers/auth.go +internal/handlers/auth_test.go | unit met, api met, others n/a |
| A58 | B20 (control) | +internal/handlers/auth.go | unit gap, api gap, others n/a |
| A59 | B20 | +src/auth/session.ts +src/auth/session.test.ts | unit met, others n/a |
| A60 | B20 | +src/auth/session.ts +src/auth/\_\_tests\_\_/session.test.ts | unit met, others n/a |
| A61 | B20 | +src/pkg/core.py +src/pkg/tests/test_core.py | unit met, others n/a |
| A62 | B20 | +crates/core/src/lib.rs +crates/core/tests/it.rs | unit met, others n/a |
| A63 | B20 | +crates/core/src/lib.rs | unit gap, others n/a |
| A64 | B20 | -packages/server/src/middleware/ratelimit.ts | unit gap, others n/a |
| A65 | B20 | -apps/api/src/middleware/ratelimit.ts | unit gap, api gap, others n/a |
| A66 | B20 | +src/auth/session.ts +tests/README.md | unit gap, others n/a |
| A67 | B20 | +agents/src/a.ts | unit gap, others n/a |
| A68 | B20 | +cmd/server/main.go | unit gap, others n/a |
| A69 | B20 | +src/main/java/com/x/Foo.java +src/test/java/com/x/FooTest.java | unit met, others n/a |
| A70 | B20 | +migrations/001.sql +internal/db/store_test.go | unit met, database met, others n/a |
| A71 | B20 | +services/api/Dockerfile | config gap, others n/a |
| A72 | B20 | +apps/web/src/components/Button.tsx | unit gap, e2e gap, others n/a |
| A73 | B20 | +src/api/users.ts +tests/api/README.md | unit gap, api gap, others n/a |
| A74 | B20 (control) | +src/thing.js +tests/thing.test.js | unit met, others n/a |
| A75 | B20 (control) | +app/models/user.rb +spec/models/user_spec.rb | unit met, others n/a |
| A76 | B20 (control) | +src/api/users.ts +tests/api/users.test.ts | unit met, api met, others n/a |
| A77 | B20 (control) | +migrations/001.sql | database gap, others n/a |
| A78 | B20 (control) | +README.md | every row n/a |
| A79 | B20 (control) | +book/src/chapter.md | every row n/a |
| A80 | B21 (control) | the template itself | felix_table_check against templates/schemas.tsv exits 0 and prints nothing; first cells exactly `unit database e2e api config`; for every `when` and `requires` cell, `LC_ALL=C grep -E -e CELL </dev/null` exits 1 |

## 5. Parts

- `engine/harness/tests/parts/1830-evidence-policy-true-verdicts-blind.sh`
  holds A1 to A56. It ships in the engine PR and is registered in tests/run
  after `1600-felix-refuses-a-pattern-kill-blind.sh`.
- `engine/harness/tests/parts/1831-evidence-template-layouts-blind.sh` holds
  A57 to A80. It ships in the founder PR (change A) and is registered after
  1830. It is red on today's template and green on the new one.

## 6. Out of scope, with why

- **Demoting evidence gaps from merge blockers to reports at the gate.** This
  is the last line of the auditor's sketch. The blocker is a recorded
  decision: escape.sh:469-473 says merging first ships the unproven thing and
  the debt is never collected. The harm in C024 came from false verdicts, and
  B20 removes them for every layout that was reproduced. A false gap that
  remains, such as an inline Rust test or a layout the template does not
  name, is cleared by a test file or by a new row, and both are visible.
  Turning a blocker into a report weakens the merge boundary, and no defect
  here needs it.
- **Per-path coverage.** `requires` is still met by a test anywhere in the
  change, so in a monorepo a test in packages/a counts for a change in
  packages/b. The rule is a set-level heuristic by design (evidence.sh:9-13).
  Tying a test to the path that fired the rule needs a new cell syntax or a
  new column, and a table column is a founder stop.
- **A test inside the file it tests** (Rust `#[cfg(test)]`, Python doctests).
  No path shows it. Reading the added lines for test markers would be a new
  capability for the table. Until then such a change reads gap (A63). That is
  the less wrong verdict, since n/a would claim the change touched no code.
- **Code outside the named directories**, such as a root-level main.go or a
  flat Python package mypkg/. These still read n/a. A pattern for root-level
  files would fire on every script and config file, and naming every layout
  from a path alone is not possible. A project with such a layout adds a row,
  and additions are free.
- **Refusing an uncompilable regex at gate time** (lib/table.sh,
  bin/schema-check). Until that exists, a broken row added to a project's
  table blocks every merge of that project. The blocker names the row and the
  cell (B8). Fixing or removing the row is a verifier escape, so the founder
  merges it. This deserves its own change; table.sh carries its own verifier
  count rule.
- **risk.tsv path patterns.** A pattern grep cannot read also counts as no
  match there: felix_escapes at escape.sh:436, and the classify and incident
  severity readers of the same table. A broken pattern silently drops an
  escape channel, which is worse than this batch's case. But it is the escape
  reader, not the evidence policy, and escape.sh cannot grow in this batch.
  No batch in this register covers it, and it needs one.
- **C074: constant texts that run nothing that can fail** (`true`, `:`,
  `echo ok`, `exit 0`). These stay admitted, for three reasons:
  - The suite's widget obligation is `true` (0004:131). 0681 pins "a setup
    check of one command is still done", and many fixtures use `true` as the
    check that holds. Refusing them would refuse the fixture every merge test
    stands on.
  - They run nothing, so they hide no failure.
  - No real table row is one: the skeptic's scan of nine projects and the
    templates found none.
- **C074: `felix_final_filter` keeps answering only which final filter a text
  ends in.** `x | tail &` stays admitted there (0681's corpus). B14 refuses
  it at the table level.
- **C078: the verdict record keeps six fields.** Recording the reviewer's
  HEAD adds nothing once B17e compares it at record time, because the tree id
  already names the reviewed commit. felix_review_passed and the judge kernel
  read the record by field.
- **C078: felix_review_record, the library, keeps accepting a pass with no
  `where`.** 0100 and 0340 record passes that way to exercise the channel.
  The library is not a boundary either: the record is a file any session can
  write. The command is the reviewer's path, and B17 closes the hole there.
- **Re-seeding the seven product projects with the new template.** This is
  the founder's call, project by project (section 7, change B).

### Not fixed: not a defect

- **"A Rust workspace whose code sits under crates/\*/src never merges"**
  (C024's scenario). Both skeptics reproduced n/a on every rule, not a block.
  That is the false all-clear, which B20 fixes (A62, A63). The "never merges"
  half does not exist.
- **The land-on-green tick clause** (C024). The tick runs only for the Felix
  home: green-tick.sh:470 takes the slug of FELIX_HOME_DIR, and that
  project's evidence table is tuned. The tick lands no product project today.
- **"The session that edited a rubric passes its own change, and nobody
  independent reviews it"** (C078's headline). Independence is declared
  uncheckable (review.sh:35-37, felix:2270-2273). Requiring `--in` cannot
  stop self-review either, since a session can name any separate work tree.
  The isolation half is real, and B17 to B19 fix it.
- **"The validator exists for exactly this class"** (C074). Its declared
  class is a final filter that hides the status (final-filter.sh:33-36), and
  it refuses that class in full: `npm test | tail -5 || true` and
  `x | tail || exit 1` are both refused. The gap is next to that class, a
  status discarded so the text always succeeds, and B14 fixes it.

## 7. Founder PR

The engine PR needs nothing from the founder: no workflow change, no deny or
escape row, no commission grant, and nothing published.

### Change A: the seeded template (the batch needs it)

Replace engine/harness/templates/evidence.tsv with the exact bytes this
generator prints. Their sha256 is
`7d9372df2da9a44acc0a809f7f3cb49c669993a9fe422666342db4fe891b9006`: 22 lines,
ASCII only. Ship part 1831 and its tests/run line with it.

Why only the founder can merge it: evidence.tsv is in FELIX_ESCAPE_TABLES
(escape.sh:78), matched by basename, and the change removes rows
(`_felix_escape_shrank`). felix merge therefore refuses it on the verifier
channel.

```bash
#!/bin/bash
# Writes the seeded evidence table to standard output, byte for byte.
CODE='(py|js|jsx|mjs|cjs|ts|tsx|go|rs|rb|java|kt|scala|swift|c|cc|cpp|cs|php|ex|exs|dart|sh|vue|svelte)'
TD='(tests?|specs?|__tests__)'
TS='(_test|_spec|\.test|\.spec|Test|Tests|Spec)'
TFILE="(^|/)${TD}/([^/]+/)*[^/]+\\.${CODE}\$|${TS}\\.${CODE}\$|(^|/)test_[^/]+\\.py\$"
kw() {
  printf '%s' "(^|/)${TD}/.*$1.*\\.${CODE}\$|$1.*/${TD}/.*\\.${CODE}\$|$1.*${TS}\\.${CODE}\$|$1.*/test_[^/]*\\.py\$|(^|/)test_[^/]*$1[^/]*\\.py\$"
}
cat <<'HDR'
# What a change must prove, from the guidebook's table on p7.
#
# A rule fires when the diff touches `when` and does not touch `requires`.
# That is a coverage heuristic, not proof: an edited test file says nothing
# about whether the test is good. It catches the case the table exists for,
# changing behaviour and shipping no test at all.
#
# Every cell is a grep -E pattern over each changed path, and every one reads
# at any depth, so packages/x/src and crates/y/src are code as src/ is. Code
# is named by its extension, so a page under book/src is not code. A test is a
# code file under a tests, test, specs, spec or __tests__ directory anywhere,
# or a file named as a test beside its code: x_test.go, x.test.ts, x.spec.ts,
# test_x.py, x_spec.rb, FooTest.java. A README under tests/ is neither, and
# proves nothing. A test written inside the file it tests, as Rust's
# #[cfg(test)] is, cannot be seen from a path, and that change reads as a gap.
#
HDR
printf '# name\twhen\trequires\treason\n'
printf 'unit\t%s\t%s\tcode changes need a test\n' \
  "(^|/)(src|lib|app|apps|internal|pkg|cmd|packages|services|crates|libs)/([^/]+/)*[^/]+\\.${CODE}\$" "$TFILE"
printf 'database\t%s\t%s\tschema changes need a database test\n' \
  '(^|/)(migrations|alembic)/|\.sql$|prisma/schema' "$(kw '(db|database|migration|rls|schema)')"
printf 'e2e\t%s\t%s\tuser-facing changes need browser coverage\n' \
  '(^|/)(src|app)/([^/]+/)*(web|ui|pages|components|views)/' '(e2e|browser|playwright|cypress)'
printf 'api\t%s\t%s\tserved surfaces need a contract test\n' \
  "(^|/)(routes?|api|handlers?|controllers?)/([^/]+/)*[^/]+\\.${CODE}\$" "$(kw '(api|route|handler|controller|contract)')"
printf 'config\t%s\t%s\tbuild and deploy config needs verification\n' \
  '(^|/)(Dockerfile|docker-compose|Procfile)[^/]*$|\.tf$' "${TFILE}|smoke"
```

What the rows change, row by row. Reasons and names are unchanged.

- **unit**
  - `when` reads at any depth and names code by its extension. Two
    directories are added for Go (pkg, cmd) and five for monorepos (apps,
    packages, services, crates, libs).
  - `requires` is a test file: either a code file under a test directory at
    any depth, or a test-named file beside its code. A README under tests/ no
    longer counts.
- **database** keeps its `when`. `requires` is a test file whose path names
  db, database, migration, rls or schema, in the same shapes as unit's.
- **e2e** reads its `when` at any depth. `requires` is unchanged.
- **api** names code files in its `when`, so a Dockerfile under services/api/
  is no longer an api change. `requires` is a test file whose path names api,
  route, handler, controller or contract.
- **config** reads its `when` at any depth. `requires` is a test file as in
  unit, or a path naming smoke.

The verdicts were checked in a scratch run against this tree's
felix_evidence_check (B20). felix_table_check accepts the file.

### Change B: re-seed the seven product projects (separable; the founder decides per project)

Copy the same bytes over each of these files. Each is byte-identical to
today's template.

- projects/bazaar/evidence.tsv
- projects/behaviorchangebench/evidence.tsv
- projects/elenchus-capital-research/evidence.tsv
- projects/sv2-apps/evidence.tsv
- projects/team1/evidence.tsv
- projects/veldra/evidence.tsv
- projects/webapp/evidence.tsv

Effects in those projects:

- False gaps on tests beside their code stop: Go, Jest, Python packages and
  Java.
- Code under a nested src/ starts to fire unit, for example bazaar's
  agents/src and veldra's services/\*/src. A change there with no test file
  now gaps, and that includes a Rust change whose only test is inline.
- A README under tests/ stops counting as a test.

Each copy moves that project's commission policy hash, because evidence.tsv
is in FELIX_COMMISSION_TABLES (commission.sh:52). So each project's
commission receipt goes stale and wants `felix commission`. The change
escapes on the verifier channel, as change A does.
