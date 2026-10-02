### 2026-10-02: `felix autonomy --revoke` takes away exactly what the reader honours, and fails closed

Found by the adversarial review of claude/adopt-newline-before-append, where it
was not fixed. This is that defect, plus what two adversarial reviews of the
fix found in the reader it leans on.

**Defect closed.** `cmd_autonomy --revoke` ran
`grep -vxF cap autonomy > autonomy.new && mv -f autonomy.new autonomy`, which
failed in three ways:
- **A file holding only the grant** (no comment header). `grep -v` selected no
  line and exited 1, and the `&&` skipped the mv. The grant stayed in force,
  but the command printed `revoked: commission`, deleted the stamp
  `autonomy.commission`, and left an empty `autonomy.new` behind.
- **An unreadable file.** The same happened through grep's exit 2.
- **A grant with extra whitespace.** `grep -x` matches whole lines exactly,
  while the reader, `felix_autonomy_allows`, trims whitespace. A hand-edited
  `commission ` stayed granted after a revoke that said otherwise.

**What the first review found in the reader.** These are also closed here:
- **Locale.** The reader trimmed `[[:space:]]`, which matches U+00A0, U+2003
  and a lone `\240` under a UTF-8 locale and none of them under C. A revoke
  run under C (this desktop app's shell) said `revoked: tidy` over a
  `tidy<NBSP>` line. A UTF-8 session-start still honoured it, and the reviewer
  reproduced `felix_tidy_safe` deleting a file because of it.
- **bash 5.2 read.** In a UTF-8 locale, bash 5.2's `read` swallows the newline
  after a stray lead byte (bash-5.2 `read.def`, read from source; CI's bash).
- **NUL.** A NUL byte ends a line on bash 3.2 and is skipped on bash 5.2, so
  `tidy\0x` was a grant to one and not the other. A bash 3.2 revoke could
  rewrite it into a grant for 5.2.
- **Unchecked `--revoke` value.** `--revoke` took any string. `Commission`
  printed `revoked:` and, on case-insensitive APFS, deleted the real
  commission stamp under a grant that stayed. A second `--revoke` silently
  replaced the first.
- **Temp file.** The temp name was predictable, and `>` follows a planted link.

**Mechanism.**
- **One reading of a grant, for every caller.** `felix_autonomy_allows` reads
  the file inside a subshell with `LC_ALL=C`, in one read
  (`IFS= read -r -d ''`). A NUL stops that read with status 0, and the file is
  then refused whole: it grants nothing. Lines are the bytes between newlines.
  `_felix_autonomy_grants` trims C-locale `[[:space:]]` (ASCII space, tab, CR,
  VT, FF). A grant typed with a non-ASCII space no longer acts in UTF-8
  sessions. That fails closed: the status page shows `[ ]`.
- **Revoke goes through the same read and the same filter**
  (`_felix_autonomy_filter`). It drops every line the reader counts as the
  grant and keeps every other byte, an unended last line staying unended. It
  checks the read's byte count against `wc -c`, writes into a `mktemp` file
  with one printf in a subshell whose output is discarded (bash 3.2 can leak a
  failed write's buffer), then mv's it and reads it back through the reader.
- **Revoke's return codes.** 0 means no line grants the capability now. 1 means
  the file could not be read whole or the rewrite failed. 2 means the file
  holds a NUL. 3 means the file was rewritten but the reader still finds the
  grant.
- **cmd_autonomy.** It takes one `--allow` and one `--revoke`, validates both
  against `tidy|commission` before writing anything, and on any non-zero code
  dies with a message of its own, before deleting the stamp and before saying
  `revoked:`.

**Decided: trailing whitespace.** Revoke removes exactly the lines the reader
counts as the grant, so trailing and leading ASCII whitespace and CRs are
included. Matching exactly instead would leave a revoke that cannot take back a
grant the reader honours. This is recorded in a dated comment above
`felix_autonomy_revoke`.

**Built as contract, blind assertions, fix, review, twice.**
- **Round 1.** An Opus agent wrote 40 assertions ("revoke is the inverse of the
  reader") from the contract alone. On the section runner (preamble lines
  1-154, REAL_HARNESS = `git archive origin/main engine/harness`), 18 fail
  against main 27573cbe and all 40 pass on the first fix. The author's
  contract questions caught the first refusal message, which contained
  `revoked:`.
- **Review 1.** It had two Opus reviewers: a fail-open hunt and a mutation
  test. It found the locale, NUL, argument and temp-name defects above. The
  mutation test showed that no fixture failed after the temp file existed, so
  a write failing partway through would have moved a truncated file into
  place and said `revoked:`.
- **Round 2.** A second blind author wrote 52 assertions ("revoke and the
  reader agree in every locale, and refuse what they cannot read") from the
  added contract. Of the 92 assertions in both blocks, 52 fail on main, 27 fail
  on the first fix, and all 92 pass on revision 2.
- **What could not be shown locally.** The stray-lead-byte case passes on
  bash 3.2 for every engine. Only CI's bash 5.2 can show it red against main.

REVIEW 2: started 2026-10-02 as workflow run wf_c798d231-9c9 (fail-open attack and mutation test on daedd559). It was cut off by the usage limit before reporting. Resume it with Workflow resumeFromRunId wf_c798d231-9c9 (completed agents replay from cache), or re-run it, before the slot.

**Handed on, not done here** (each one is a session task):
- **No lock on concurrent writers.** Two `felix autonomy` runs at once can
  interleave, and the later mv puts back a grant the other run reported
  revoked. This predates the fix (main's grep && mv had it too). Only a person
  writes this file, and the comment above `felix_autonomy_revoke` says it is
  not covered.
- **`--allow` appending onto an unended last line.** It writes
  `tidycommission`, which loses tidy, and still prints `allowed: commission`.
  Same class as claude/adopt-newline-before-append.
- **Kept file mode.** Revoke's rewrite is created by mktemp at mode 0600 and
  replaces the file, so the mode changes. Main's rewrite took the umask's mode.
  Git tracks only the executable bit.

**Landing.** At the head of the weekly batch (carrier, 2026-10-02). No
commission table, no escape and no projects/ table is touched. The version is
assigned at the carrier's call, and the record and gate run only after it.
