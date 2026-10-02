### 2026-10-01: a row appended onto a last line with no newline lands on a line of its own, in every engine writer that something else also writes

Branch claude/adopt-newline-before-append, on claude/adopt-refuses-unread-capabilities
(de4037ef). The carrier chose one PR for both adopt fixes, carried from this
branch, in the weekly batch after lookup-fails (0.49.244). Engine only: no
table under projects/, no escape, no version bump yet. The record and the bump
are taken at the slot. Squash-merged, so the `wip:` commits are working history.

**Defect closed.** Writers appended a row with `printf '...\n' >> F`. When F's
last line had no newline, the row fused onto it. Measured on macOS:
`printf api > f; printf '%s\n' obs >> f` gives `apiobs\n`. felix_declared then
read one capability, `apiobs`, so both were lost, while the stack.tsv and
setup.tsv rows for `obs` were written all the same.

**The class, and how it was drawn.** The 70 `>>` appends to a variable path
under engine/harness (lib, felix, hooks, templates) were read, and the review
then hunted `tee -a`, `cat >>`, `echo >>`, heredoc and `sed -i` appends. Each
was sorted by who else writes the file. These are in, because a person, a merge, a routine or a
project's own gate also writes them:
- `capabilities`, stack.tsv and setup.tsv in felix_adopt_capability;
- `autonomy` in felix autonomy --allow;
- stack.tsv in felix discover --adopt and felix_commission_apply_declares;
- maintenance.log (felix_maint_record) and budget.log (felix_budget_record),
  which are committed and can be hand-merged;
- the gate log in cmd_gate, which holds the project gate's own output before
  Felix appends its checker lines;
- mistakes.log (felix_mem_mistake), which a maintenance routine curates.

Out: the memory-root and state/ logs only the engine writes, temp files Felix
creates and fills itself, and `$GITHUB_OUTPUT`. routes.tsv is rewritten
through a temp file that already ends every line. lessons.md and DEVLOG.md
appends start with `\n`, so they were already safe.

**Mechanism.** One pair of functions in lib/resolve.sh, beside felix_count:
- `felix_line_ended F` returns 0 for absent, empty or newline-ended, 1 for an
  unended last line, and 2 when F is not a regular file or its last byte
  cannot be read. Something that is not a regular file is never opened.
- `felix_end_line F` writes the newline on 1, and returns 1 on 2 or on a
  newline it could not write.

The last byte is read through `od`, as lib/table.sh reads it. A command
substitution drops a NUL the way it drops a newline, so the guard
commission-provider.sh already had (`[ -n "$(tail -c 1 f)" ]`) read a
NUL-ended stack.tsv as ended and fused the row. That guard now goes through
the helper too.

At each writer, the newline and the append are one failure: a row that cannot
be written on a line of its own is not written, and is not counted, announced,
stamped or installed.
- felix adopt prints `felix: could not add <row> to <proj>/stack.tsv`, and
  exits 3 when a row the capability implies was left unwritten.
  felix_adopt_capability returns 3 then, after the counts. A second adopt
  answers "already declared" and never writes those rows, so the session-start
  hook, which drops the function's stderr, says
  `Adopted, but not every row each implies could be written`.
- felix autonomy dies before `allowed:` and before the stamp.
- felix discover --adopt prints `unwritten`, installs nothing for that row, and
  sums up `N adopted, M refused, K unwritten.`
- felix maintenance --ran dies, where it used to print `recorded` over a
  failed write.
- felix_budget_record returns 1, so felix budget refuses the run.

Pipes, dangling links and directories at these paths:
- The tables are seeded with a header only when nothing is at the path
  (`[ -e ] || [ -L ]`, where it was `[ -f ]`). `[ -f ]` seeded through a
  dangling link, creating its target, and waited forever on a pipe.
- adopt's duplicate checks and apply's read of the declared names open the
  table only as a regular file.

Two readers dropped an unended last line before any append happened, because
`while read ... done <` skips it:
- felix_budget_used counted one run short;
- _felix_maint_last read a routine as due.

Both now take `|| [ -n ... ]`, as felix_autonomy_allows already did. The
review measured why it belongs here: with the writer fixed and the reader not,
the newline this fix writes made a recorded run at the ceiling re-read as two
and refuse as a lost race.

On a checkout with no commit, felix_mem_mistake split its row across two
lines: `$(git rev-parse ... || echo '?')` kept both rev-parse's `HEAD` and the
`?`. It now captures and then tests.

**Built as blind assertions, fix, review, four times.** One author, who never
saw the fix, wrote every assertion from contracts. Each block was shown red
against origin/main and the base, and green on this branch, with the one-block
section runner:

| block | about | assertions | red on main | red on the base |
|---|---|---|---|---|
| 1 | the newline itself, 8 writers, ended, unended, NUL, empty, absent | 44 | 17 | 17 |
| 2 | a last line that cannot be ended (read-only, write-only) | 58 | 37 | 32 |
| 3 | the first review: failed appends, non-regular paths, readers, gate log, mistakes.log | 74 | 47 | 47 |
| 4 | the second review: status 3, pipes, an unborn checkout | 17 | 11 | 11 |

43 mutants of the fix were run through the blocks, and 42 were caught. Each
call-site mutant failed only its own writer's assertions. The one survivor is
equivalent: `felix_end_line "$list" || true` in adopt.sh. The base already
refuses an unreadable list at its grep and an unwritable one at its append, so
that branch cannot be reached alone.

tests/run's first 2521 lines, through all four blocks and so after the real
fixture state the earlier sections build, passed 483 of 483 against an export
of this branch's engine/ (0a4ae724). That is a prefix, not the record.

**Review.** Two adversarial rounds.
- The first found:
  - M1: append failures were still counted;
  - M2: the gate log;
  - M3: mistakes.log;
  - M4: the two readers;
  - M5: the failure branches were untested;
  - L1: non-regular paths were seen as having nothing to end.
- The second found:
  - the M1 response was unpinned until block 3;
  - pipes still blocked adopt's and apply's reads, which two comments
    overclaimed;
  - the hook dropped a partial backfill silently.

All are fixed here and pinned by blocks 3 and 4.

**Left, and where.**
- Readers of other hand-edited tables (route.sh, deny.sh, monitor.sh,
  ledger.sh and others) dropped an unended last line, and some opened
  stack.tsv unguarded. Fixed by claude/table-readers-keep-unended-line, which
  the carrier folded into this PR on 2026-10-02. Its own note is
  20261002T020912Z-claude-table-readers-keep-unended-line.md. Its open items
  are taken here:
  - T2-T4 are comment-only (d5a76bff). felix:2984's guard is called
    defensive. The lint's comment now names the opens it does not judge and
    the sibling-branch guards it credits.
  - T1 is closed by a fifth blind block (7 assertions, red 3 of 7 on
    origin/main and on 1dd58ae2). Its night fixture enters hooks/stop's
    overnight branch, and removing only that branch's stack.tsv guard turns
    its three pipe assertions red. Its author also found that main blocks
    earlier, in the policy-version hash, which the readers branch had already
    guarded.
  - The completeness re-run (2026-10-02) found no reader of a project table
    left unguarded: 924 pipe runs over 21 paths, 44 commands and all 8 hooks,
    with none blocked, and 704 unended-table output pairs with no difference.
    Its findings outside the class are in the readers note, and are left as
    below.
- git readers lose every diff after a pipe at a tracked path, because git
  fails "cannot hash" and every caller discards the error. felix_tree_id then
  reads a receipt as current after an edit, and bin/secret-scan passes an
  added key. Pre-existing and not an append. Spun off as its own task.
- `felix obligations --seed`, the stamp written by
  `felix autonomy --allow commission`, and detect.sh's `cmp` of an
  executable-pipe gate file still block on a pipe. These are overwrites and an
  open, not appends to a table. Spun off as one task.
- felix autonomy --revoke of a file's only grant leaves it granted while
  printing `revoked:`. Spun off as its own task.
- `_felix_mem_stamp` (lib/memory.sh:22) has the same print-then-fail fallback,
  which splits a DEVLOG.md heading on a checkout with no commit. A heading,
  not a table row, so not built here.
- felix discover --adopt still exits 0 when a row is unwritten. The summary
  line says so.

**Main merged in, 2026-10-02,** for #386, #388, #389 and #392, with no
force-push.
- One conflict, in felix_mem_mistake against #392, which widened the
  mistakes.log row to six fields, adding the epoch and the session. The
  merged function keeps #392's row and its `_felix_mem_branch`/`_sha`/`_sid`
  helpers, and ends the line first.
  - This branch's own branch/sha capture is gone. #392's helpers already keep
    the row on one line on a checkout with no commit.
  - The five blind assertions that pinned the four-field row (three in
    block 3 E, two in block 4 H, one of them renamed) now expect six. That
    follows #392's format, and widens nothing they accept.
- Against an export of the merged engine/:
  - tests/run lines 1-9579, which take in blocks 1-4 and #392's
    unrecorded-catch sections over the real fixture state, passed 1580, failed
    0 and skipped 5;
  - the readers blocks, block 5 and the lint passed 88 of 88.

  Prefixes, not the record.

**The verifier escape was a stale base.** risk.tsv:39 confines tests/run with
`count:^[[:space:]]*(ok|is|has|bad) `, and escape.sh counts at the origin/main
tip, not at the merge-base. Main had gained 215 such lines since the fork. The
branch adds 126 and removes none, so before the merge it read 2953 against
main's 3042, and `felix receipt` named a founder_required escape. Merged, it
reads 3168 against 3042, and the receipt says `"founder_required": false,
"escapes": []`. Re-merge and re-count at the slot if main has moved again.

**At the record.** assertions.tsv grows by 204 from the base's block, 193
from this branch's four, 81 from the readers branch, and 7 from the fifth
block.
