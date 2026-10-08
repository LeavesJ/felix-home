### 2026-10-08: `felix autonomy --allow` says allowed only when the reader then grants it

Found 2026-10-02 while fixing --revoke on claude/autonomy-revoke-fails-closed,
which handed it on unfixed. Stacked on that branch (85ab3f7a, main 6fe5f986
merged in).

**Defect closed.** `cmd_autonomy --allow` ran `[ -f autonomy ] || printf
header > autonomy; printf '%s\n' cap >> autonomy; printf 'allowed: %s\n'`, and
for commission wrote the stamp. Three ways it went wrong:
- **An unended last line.** A hand-written `tidy` with no final newline took
  the grant onto it as `tidycommission`. That line grants neither, so tidy was
  lost and commission never held, yet it printed `allowed: commission` and
  stamped.
- **An unended comment.** `# note` swallowed the grant the same way.
- **A NUL byte.** The file took the append and the stamp, but the reader on the
  revoke branch refuses such a file whole.

**Mechanism.** `felix_autonomy_grant` in lib/autonomy.sh writes a grant the way
`felix_autonomy_revoke` takes one back.
- It takes only `tidy` or `commission`.
- It refuses a path that is not a regular file (directory, dangling link,
  FIFO, never opened) and a read-only file.
- It reads the file once in the C locale through `_felix_autonomy_read` and
  checks the byte count against `wc -c`.
- It appends a newline if the last line is unended, then `cap\n`. A missing
  file gets the old header line.
- It writes the text into a `mktemp` file with stdout thrown away, mv's it into
  place, and reads it back through `felix_autonomy_allows`.

Its return codes are 0 granted, 1 refused or unwritable, 2 NUL, and 3 written
but not found on read-back. `cmd_autonomy` dies on any non-zero code with
"CAP is not allowed, because …", before `allowed:` and before the stamp block.
The stamp lines themselves are unchanged.

**Built as contract, blind assertions, fix, review.**
- **Blind.** An Opus agent wrote 117 assertions from the contract alone, without
  reading lib/autonomy.sh or the CLI. The block is "allow says allowed only when
  the grant holds", between `# ---- allow-grant block begin/end`. On the
  section runner (preamble through the line before `printf '\nresolution\n'`,
  REAL_HARNESS set to a `git archive origin/main engine` export), 71 of 117
  fail against main 6fe5f986 and 69 fail against the revoke base 920ccdb8. All
  117 pass on the fix (1c347cbb).
- **Review: a fail-open hunt (Opus).** It found no false `allowed:` through
  the fix's path in any locale. Locales tried: C, UTF-8, ISO8859-1, SJIS,
  GB18030, bogus. It also tried short writes under `ulimit -f`, odd `$proj`
  paths, CR and empty files, and planted temp names. Its findings and what was
  done with each:
  1. **Two runs at once.** The rewrite lets a slow grant put back a grant that
     a revoke has just removed, which main's append could not. This is left to
     claude/autonomy-writer-lock, whose lock spans the read, the mv, the
     read-back and the stamp. The writer-lock must land before this branch or
     with it, never after. The comment above `felix_autonomy_grant` says so.
  2. **The stamp is written through a link.** A symlink or hard link at
     `autonomy.commission` pointing to the grant file let the stamp overwrite
     it after `allowed:`. Main does the same. This is taken by
     claude/project-writes-refuse-nonregular, which owns the stamp lines.
  3. **A signal between mktemp and mv leaves `autonomy.new.*` behind.** Revoke
     has the same window. Handed to the writer-lock session, which plans an
     exact-path cleanup in its EXIT trap.
  4. **The file mode.** The rewrite leaves mode 0600 and replaces a link at the
     path with a file, as revoke's does. Handed on, under "Kept file mode".
  5. **A refusal where main appended.** A writable file in a read-only
     directory, and a `uappnd` file, are now refused. This fails closed, and
     the contract allows it.
  6. **Any capability string was taken.** A value with a newline in it wrote a
     second line and returned 3. Fixed: only tidy or commission (0b5a7c52).
  7. **A stale comment reason.** Fixed.
- **Review: a mutation test (Opus).** Of 19 mutants, 5 survived the blind
  block: a dropped byte-count check, a dropped `-w` check, stdout not
  discarded (bash 3.2 leaks a failed write's tail), the read-back returning 1
  instead of 3, and an in-place append that Linux cuts mid-write. Six
  assertions now kill them; each was re-run and fails its mutant, and the
  capability check adds two more. These are marked in the block as from the
  review, not blind. With them the block is 140 assertions:
  - all 140 pass on the merged head;
  - 89 fail against main 6fe5f986;
  - the two capability assertions fail against 1c347cbb.
  The reader and revoke blocks pass 96/96 on the merged head.
- **What could not be shown locally.**
  - Only bash 3.2 is installed. The reviewer reasoned bash 5.2 from source and
    found no difference.
  - The 2040-byte cut-short case kills the in-place mutant on macOS only.
    Linux's partial write is reasoned, not measured.
  - The merge-advice assertions that run `--allow commission` (the "stale
    commission receipt" section) go through the new-file and re-arm paths,
    which the block pins. They were not run alone and wait for the suite.

**Landing.**
- **Order.** After claude/adopt-newline-before-append (.274) and
  claude/autonomy-revoke-fails-closed (.275). The batch is carried by "Fix
  adopt gluing a capability onto a last line"; its state is in
  audits/2026-10-08-carrier/state.md under the memory root. The carrier ruled
  2026-10-08 that writer-lock and this branch land as one PR, carried by the
  lock's session on claude/autonomy-writer-lock. That session merges this
  branch (no rebase, no squash), gives red evidence per block against
  85ab3f7a, and asks before resolving any conflict in felix_autonomy_grant or
  the allow block. It may go ahead of .276/.277, but never ahead of revoke.
  The version is the carrier's call. No projects/ table, no escape and no
  commission table is touched.
- **Conflict with adopt-newline.** That branch also rewrites these --allow
  lines (`felix_end_line ... >> ... || die`). Resolve to
  `felix_autonomy_grant`. Its block-1 assertion "felix autonomy --allow onto a
  grant ending in a NUL byte writes a newline after the NUL first" pins
  `allowed: tidy` over a file the reader refuses whole. It becomes refused and
  byte-identical here. Its other --allow cases (read-only, write-only,
  dangling, directory, header, empty, unended) agree with this fix as written.
- **Conflict with writer-lock.** Textual only. Its lock sits above the
  --revoke block, and its rule "callers hold felix_autonomy_lock" gets one line
  above `felix_autonomy_grant` at the merge.
- **Conflict with project-writes-refuse-nonregular.** It adds a stamp-path
  check just above `if felix_autonomy_allows`, so the two touch adjacent lines.
  There is no semantic overlap.
- **Suite.** The full suite, the record and the gate run only in the
  carrier's slot.
