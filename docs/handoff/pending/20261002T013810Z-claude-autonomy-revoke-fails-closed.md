### 2026-10-08: `felix autonomy --revoke` takes away what any reader honours, and fails closed

Found by the adversarial review of claude/adopt-newline-before-append, where it
was not fixed. This is that defect, plus what four adversarial reviews of the
fix, and one of the writer lock, found in the reader it leans on and in the fix
itself.

**Defect closed.** `cmd_autonomy --revoke` ran
`grep -vxF cap autonomy > autonomy.new && mv -f autonomy.new autonomy`:
- **A file holding only the grant** (no comment header). `grep -v` selected no
  line and exited 1, and the `&&` skipped the mv. The grant stayed in force,
  but the command printed `revoked: commission`, deleted the stamp
  `autonomy.commission`, and left an empty `autonomy.new` behind.
- **An unreadable file.** The same happened through grep's exit 2.
- **A grant with extra whitespace.** `grep -x` matches whole lines exactly,
  while the reader, `felix_autonomy_allows`, trims. A hand-edited
  `commission ` stayed granted after a revoke that said otherwise.

**What the reviews found in the reader and around it.** These are also closed
here:
- **Locale.** The reader trimmed `[[:space:]]`, whose meaning depends on the
  locale and the C library. macOS's UTF-8 locales take U+00A0, U+2003 and a
  lone `\240`; glibc's take U+2003 but not U+00A0; C takes none of them. A
  revoke run under C said `revoked: tidy` over a `tidy<NBSP>` line that a
  UTF-8 session-start still honoured. The reviewer reproduced
  `felix_tidy_safe` deleting a file because of it.
- **bash 5.2's read.** In a UTF-8 locale it swallows the newline after a
  stray UTF-8 lead byte (read from source: bash-5.2 builtins/read.def).
- **NUL bytes.** bash 3.2 cuts a line's value at a NUL, while 5.2 skips the
  byte.
- **Engines already deployed.** Plugin caches up to 0.49.273, and every
  session started before a deploy, keep the old reader. A revoke that matched
  only the new reader still left them a grant.
- **The revoke argument.** `--revoke` took any string. `Commission` printed
  `revoked:` and, on case-insensitive APFS, deleted the real stamp under a
  grant that stayed. A second `--revoke`, or a stray word, was dropped
  without a word.
- **The rewrite itself.** The temp file had a predictable name, opened through
  a following `>`. A write cut short could leak file text to stdout on bash
  3.2. Every revoke rewrote the file (mode 0600, links replaced, a read-only
  directory refused a no-op). And splitting the text in shell made the reader
  quadratic on the session-start path: 80 KB cost 2.4 s of CPU, against about
  0.01 s on main.
- **Revision 3's own rewrite** (review 3). Its line loop read a here-string,
  which bash 3.2 writes to a temp file in /tmp or /var/tmp. When that write
  failed (a full disk, a sandbox, a file-size limit), the loop never ran and
  the pass said "nothing to remove". Over `tidy<NBSP>`, a line only older
  engines grant, the CLI printed `revoked: tidy` with the file untouched. Over
  a plain grant it refused, falsely blaming "another writer". The kept text,
  built up in one string, made revoke quadratic: 1 MB took 111 s of CPU.
- **Revision 4's match** (review 4). It cut the line at the capability with
  `%%`, which bash runs from every position of the line, measuring the rest
  each time. That is quadratic in a line's length: one 512 KB line cost 8.8 s.
- **A subshell stopped by `set -u`** (the writer lock's third review, and
  revoke's fifth). Under bash 3.2, in a script such as felix, a subshell that
  `set -u` stops inside an arithmetic expansion exits with the status of the
  command before the stop: 0, or any other. Revoke's passes computed
  `$(( $(wc -c) ))`. A stale stdout buffer flushed into that wc stopped the
  pass with wc's 0, which read as written, and the mv put an empty file over
  the grants. The reader's subshell answered 0 for a grant, so a stop could
  read as one.
- **A stale stdout buffer** (review 6). When a printf to a closed stdout
  fails, bash 3.2 keeps its text in the buffer, and every subshell inherits
  it. Pass 2's first write into the temp file flushed it there, so a NUL or a
  newline, which `$( )` had dropped from wc's answer, went into the grant
  file. With a NUL, this engine then read no grant from it at all.
- **Revision 5's match order** (review 5). Its test tried "a letter before a
  copy" first, from every letter: quadratic when letters follow the
  capability (`tidy` plus 64 KB of letters cost 5.5 s).
- **Shift-JIS** (review 3). Revision 3 trimmed whitespace and bytes from `\200`
  up. The Shift-JIS ideographic space is `\201@`, so an older engine under
  ja_JP.SJIS still tidied by `tidy\201@` after `revoked: tidy`.

**Mechanism.**
- **The reader.** `felix_autonomy_allows` runs in an `LC_ALL=C` subshell. It
  reads the whole file once (`IFS= read -r -d ''`), and a NUL stops that read,
  refusing the file whole: it grants nothing. Then a line loop answers on the
  first grant. `_felix_autonomy_grants` skips empty and `#` lines and trims C
  `[[:space:]]` (ASCII space, tab, CR, VT, FF). A 424 KB file costs about
  0.5 s of CPU.
  - Against the old reader this narrows the trim everywhere, so a grant typed
    with a non-ASCII space shows `[ ]`.
  - It widens one case: on bash 5.2 in a UTF-8 locale, a line after a stray
    lead byte is read as its own line.
- **Revoke is wider than every reader.** `_felix_autonomy_names` matches a
  line that holds the capability once, where nothing else in the line is an
  ASCII letter or `#`. No whitespace character, in any encoding a macOS or
  glibc locale runs in, holds either byte:
  - UTF-8's and the EUC encodings' are bytes from `\200` up.
  - Shift-JIS's ideographic space is `\201@` and Big5's is `\241@`.
  - GB18030's four-byte spaces hold digits.
  Python's codecs and every LC_CTYPE on this Mac were checked. The encodings
  that do put a letter in a space are ones no locale reads with it: EBCDIC,
  ISO-2022, UTF-7, and Shift_JIS-2004's `\205A` no-break space (macOS has no
  such locale, and glibc's space class leaves out U+00A0). So no older engine, in any locale, finds the
  grant afterwards. A 4,000-line fuzz across 14 macOS locales found no miss. A
  line that only looks like the grant (`tidy.`, `- tidy`, `tidy=0`) goes too.
  The test is two `case` matches: no `#` and the capability present, then no
  letter after a copy (tried first, as it fails at most once per line) and no
  letter before one. It is linear in a line's length.
- **Two passes**, each `_felix_autonomy_rewrite` in a C-locale subshell with
  its output discarded. Each checks for a NUL, then reads the lines straight
  from the file and counts the bytes they account for against `wc -c`. A loop
  that never ran, or a read cut short, is a refusal, never "nothing to
  remove".
  - The first pass writes nothing, not even a temp file. It stops at the first
    named line. With nothing to remove, the file is not touched and no
    writable directory is needed.
  - Otherwise revoke takes a `mktemp` name and runs a second pass. That pass
    streams every kept line to the temp file with the newline it had, so an
    unended last line stays unended. A failed write is a refusal. Revoke is
    linear: 512 KB costs about 1.5 s of CPU and 1 MB about 2.9 s, and one
    512 KB line about 1 s.
  - Revoke first empties the shell's stdout buffer (`printf '%s' '' >
    /dev/null`), so no subshell inherits stale output.
  - `wc`'s answer must be one count, digits with blanks around them, and goes
    straight to test's `-eq`, never through `$(( ))`. So no pass does
    arithmetic on text it reads, and none can be stopped that way.
  - As defence in depth, a pass's status comes back offset by 20, and nothing
    a pass runs exits from 20 to 25, so a stop is refused whatever status it
    leaves. The reader's subshell answers a grant with 10, which nothing it
    runs exits with.
  - The file's mode is copied (`stat -L -c %a`, falling back to
    `stat -L -f %Lp`), then the mv. The result is read back through the
    reader.
  - A linked file is replaced by a regular one, and the link's target keeps
    what it had.
- **cmd_autonomy.**
  - It takes one `--allow` and one `--revoke`, refuses any other argument,
    and validates both capabilities against `tidy|commission` before
    anything is written.
  - Each failure code from revoke dies with its own message before the stamp
    and the word. The message mentions the stamp only when one exists.

**Decided.**
- **Trailing and leading whitespace.** Revoke removes every line any reader
  could count as the grant, and keeps every other byte. Matching exactly
  would leave a revoke that cannot take back a grant a reader honours.
- **Narrowing the reader** to ASCII whitespace fails closed, and the status
  page shows it.

**Built as contract, blind assertions, fix, review, three times.**
- **Round 1.** 40 blind assertions ("revoke is the inverse of the reader"): 18
  fail on main 27573cbe, and all pass on the first fix.
- **Review 1.** It found the locale, NUL, argument and temp-name defects. Its
  mutation test showed that nothing exercised a write failing after the temp
  file existed.
- **Round 2.** 52 blind assertions ("revoke and the reader agree in every
  locale, and refuse what they cannot read").
- **Review 2** (on 85ab3f7a, main 6fe5f986 merged in):
  - Revision 2 held in its own engine: 6,400 fuzzed reader files and 3,000
    revokes matched a reference under C and UTF-8.
  - It found the older-engine window, a false NUL message, the quadratic
    reader, the rewrite on a no-op, and ten surviving mutants (the worst: the
    CLI treating the read-back's code 3 as success, and a reader without
    `-r`).
- **Round 3.** 43 blind assertions ("revoke reaches every reader, and leaves
  alone what it does not change"), with fixes to the earlier blocks' fixtures
  and comments.
- **Totals after round 3.** Across the 136 assertions in the three blocks, 75
  fail on main 6fe5f986, 20 fail on revision 2, and all 136 pass on revision
  3 (4f42ec68).
  The round-3 block caught one bug in revision 3 before it was committed: the
  newline of a kept line was dropped when the unended last line was the one
  removed.
- **Review 3** (on 4f42ec68):
  - It found the here-string fail-open (a blocker), the Shift-JIS miss, the
    quadratic revoke, and the revoke-then-allow glue.
  - It also found three nits: a temp file left by Ctrl-C, BSD stat dropping
    setuid, and mutation gaps (a mode copy without `-L`, an unended grant
    read, an unreadable file blamed on a NUL, a refused rename).
- **Round 4.** 37 blind assertions ("revoke reads every line it judges, and
  names a grant the way every encoding writes it"). It runs under a sandbox
  that denies writes outside the Felix home, and under a file-size limit.
  22 fail on revision 3. All 173 assertions in the four blocks pass on
  revision 4 (7495a319).
- **Round 5.** 11 blind assertions for revoke then `--allow` on an unended
  last line (247a7afa).
  - On revision 4, 4 fail: the glued bytes and the lost grants.
  - With .274's `felix_end_line` and `felix_line_ended` patched into a scratch
    copy of revision 4, all 184 pass.
  - On main, the 2 that pin the unended line between the steps fail, because
    main's revoke always wrote a final newline. The final bytes and the
    grants pass there.
- **Review 4** (on 7495a319): no blocker or major in the code.
  - It found the quadratic match on a long line, and docblocks and a codec
    survey that said more than the code.
  - It found five checks no assertion pinned: the byte count, a write
    failing on the last line, a refused rename off macOS, upper-case
    neighbours, and a file past bash 5.2's pipe buffer.
- **Round 6.** 23 blind assertions ("revoke refuses what it could not read or
  write, and stays linear in a long line", 7e3f745d). Two fail on revision 4:
  a 512 KB line at 8.9 s and one of `\201` bytes at 8.5 s.
- **Revision 5** (d95596a7): the `case` match, and the 10-for-success codes.
  Blocks 1-6 give 203 pass on it. The 4 that fail are block 5's, which wait
  on .274.
- **Round 7.** 9 blind assertions for the `set -u` stop, run as a script as
  felix runs (8b14bde2): a revoke pass, the reader, and the CLI with a `wc`
  shim. 6 fail on revision 4; all pass on revision 5. Across the seven
  blocks revision 5 gives 212 pass, and the 4 that fail are block 5's. On
  bash 5.2 the stop exits non-zero, so the block is green on every revision
  there.
- **Review 5** (on d95596a7): two majors.
  - The `set -u` premise was wrong: a stop leaves the last command's status,
    not 0. A `wc` that printed text and exited 10 made revoke empty the file.
  - The match order was quadratic when letters follow the capability.
  - Four one-letter narrowings of the letter class survived the blocks.
- **Round 8.** 19 blind assertions ("revoke knows every letter, stays linear
  after the capability, and takes no stop for an answer", ee1edec2): every
  ASCII letter on both sides of both capabilities, three 256-512 KB
  capability-then-letters lines, and `wc` stops leaving 10, 5, 4 and 2. 10
  fail on revision 5.
- **Revision 6:** the digit check and the swapped order. Blocks 1-8 give 231
  pass on it; the 4 that fail are block 5's, which wait on .274.
- **Review 6** (on 715f6381): no fault in the match or the digit check
  (240,000 fuzzed lines, linear on every shape).
  - It found the stale buffer reaching the temp file (major).
  - The one check refusing a true count with text after it was unpinned.
  - The 10 code guarded success only: a stop leaving 4 still read as
    "nothing to remove".
  - The strip joined `2 0` into 20.
- **Round 9.** 23 blind assertions ("revoke writes no stale output, takes one
  count from wc, and no stop for an answer", 007e902d): four stale buffers,
  four `wc` answers, and a names test stopped after each status 0-5 and 10 in
  either pass. 11 fail on revision 6.
- **Revision 7:** the flush, the offset, and no strip. Blocks 1-9 give 254
  pass on it, and the 4 that fail are block 5's.
- **Review 7:** on revision 7.
- **What could not be shown locally.** The stray-lead-byte case passes on
  bash 3.2 for every engine. Only CI's bash 5.2 can show it red against main.
- **The section runner.** It is preamble lines 1 to 224 (the line before the
  first `resolution` header, since #324), then the three blocks, with
  REAL_HARNESS set to a `git archive` export.

**Handed on, not done here:**
- **Revoke then `--allow` on an unended last line.** Revoke keeps the line
  unended, and `--allow` appended onto it, writing `commissiontidy`. .274's
  `felix_end_line` ends the line first, and claude/autonomy-allow-fails-closed
  does too. So this branch lands after .274, never before. Block 5 pins the
  sequence.
- **A temp file left by Ctrl-C** during the second pass. The writer lock's
  EXIT trap removes it.
- **Known and left:** the reader costs about 3x main's on a large file
  (bash 3.2's `read -d ''` takes a byte per call), and its trim is quadratic
  in a long run of whitespace, as on main. Grant files are a few lines.
- **The writer lock.** Two `felix autonomy` runs at once can interleave, and
  the later mv puts back what the other removed. This predates the fix. It is
  claude/autonomy-writer-lock, stacked on this branch.
- **`--allow` claiming a grant it did not make.** Appending onto an unended
  last line writes `tidycommission` and still prints `allowed:`.
  claude/adopt-newline-before-append ends the line, and
  claude/autonomy-allow-fails-closed adds the read-back.

**Landing.** The weekly batch's carrier (the adopt session, 2026-10-08) set
the order: .274 adopt-newline, then .275 this branch (after .274, never
before: see block 5), then the writer lock
and --allow, then .276 and .277. The fold rule: one PR for all three autonomy
branches at .275, carried from this branch, if the lock and --allow branches
are reviewed and merged onto this head within about 3 hours of review 3
finishing. Otherwise this branch lands alone. No commission table, no escape
and no projects/ table is touched. The carrier deploys.
