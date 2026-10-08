### 2026-10-08: felix_declared refuses a capabilities file that is not a list of names, and reads one that is byte for byte

Stacked on claude/declared-unread-readers (c23ec7d1), which routes every
reader of the declared list but `_felix_cap_active` through
`felix_declared_into` and trusts its 0. That branch has no pull request yet;
this one merges main after it lands, and does not land before it.
claude/commission-lookup-fails-unknown landed as #401.

**Defect.** `felix_declared` read `<proj>/capabilities` with
`grep -vE '^\s*(#|$)'` in the caller's locale and took grep's 0 or 1 as a
list read. Measured on macOS /bin/bash 3.2.57 and BSD grep 2.6.0-FreeBSD:

1. `printf 'storage\nau\000th\nbilling\n'` printed
   `Binary file <proj>/capabilities matches` on stdout and returned 0: the list
   read was one invented capability, an absolute path, and the real ones were
   lost. A UTF-16 file did the same, and so did `\303\000storage`. GNU grep
   3.5+ sends that message to stderr, stops printing at the first binary line
   and exits 0, so on Linux the list comes back empty or partial and still
   counts as read (inferred from GNU grep's documentation, not run). Under a
   UTF-8 locale GNU grep also takes a byte that is not valid UTF-8 as binary.
2. `\357\273\277# a comment` (a UTF-8 byte-order mark before a comment) was
   listed as a capability, and so was a BOM before a name, with the BOM in it.
3. A line of only a no-break space (`\302\240`) was listed under the C locale
   and dropped under UTF-8, so one file was two lists on one machine.

Also measured, same shape: `storage\r\nbilling\r\n` listed `storage\r` and
`billing\r`, names no table holds, so every reader called them undeclared.

**Contract.** Written before any code, and the only thing the blind assertion
author was given. "Prints nothing" means nothing on stdout. Every rule holds
under `LC_ALL=C` and under a UTF-8 locale (`en_US.UTF-8` on macOS,
`C.UTF-8` on Linux), and with the caller's pipefail on and off.

0. Unchanged. No file at the path: nothing, 0. Something there that is not a
   regular file (a directory, a pipe, a link whose target is gone): nothing,
   2, not opened. A file that cannot be opened (mode 000, as anyone but root):
   nothing, 2. A link to a regular file is read as that file.
1. **A NUL byte makes it no list.** A regular file holding a NUL byte anywhere
   is not read as a list: nothing printed, 2. Anywhere means the first byte,
   inside a name, inside a comment, inside a blank line, in a last line with
   no newline, right after a UTF-8 lead byte (`\303\000`), and past the first
   64 KiB. UTF-16 (either byte order, with or without its BOM) and UTF-32
   files hold one for every ASCII character, so each is no list.
2. **Byte for byte, in the C locale.** The file is read in the C locale
   whatever the caller's `LC_ALL`, `LC_CTYPE` and `LANG`, so one file gives
   one stdout and one status under every locale. No byte sends a reader into
   a binary mode: no line printed says `Binary file`, and none is a path.
   After a call made in the current shell (not in a substitution), the
   caller's `LC_ALL`, `LC_CTYPE`, `LANG`, `IFS`, positional parameters and
   `set -f` state are as they were.
3. **A leading byte-order mark is not part of the first line.** The three
   bytes `\357\273\277` at the very start of the file are dropped before the
   first line is read, once. So `\357\273\277# c\nstorage\n` prints
   `storage`; `\357\273\277\nstorage\n` prints `storage`;
   `\357\273\277storage\nbilling\n` prints `storage` and `billing`; each 0.
   The same bytes anywhere else are bytes of their line (rule 4), so
   `\357\273\277\357\273\277storage\n` and `storage\n\357\273\277billing\n`
   are each 2.
4. **What the list holds is names, and a name is tab and printable ASCII.**
   Every line the list would hold (any line that is not blank and not a
   comment, rule 5) consists only of tab (`\011`) and the bytes `\040` to
   `\176`. A file in which any such line holds any other byte is not read as
   a list: nothing printed, 2, the whole file and not only that line. That
   covers a line of only a no-break space, which is neither blank nor a
   comment; a name ending in a CR (`storage\r\nbilling\r\n`); a byte from
   `\200` up in a name (`caf\303\251`); DEL (`\177`); and any other control
   byte (`\001`, `\033`, VT or FF inside a name).
5. **Blank and comment lines are skipped, byte-wise, whatever they hold but
   a NUL.** A blank line holds nothing but space, tab, CR, VT and FF. A
   comment is a line whose first byte after any of those is `#`. So
   `# caps \342\200\224 the founder` is a comment, so are `  # x\r` and
   `#\302\240x`, and a line of only `\r`, of only VT or of only FF is blank.
6. **Everything else is as before.** Each remaining line is printed verbatim,
   leading and trailing spaces and tabs kept and an inline remark kept
   (`deploy   # only staging` prints as it stands), one per line in file
   order, each ending in a newline, the last line too when the file does not
   end in one; 0. A file with no such line (empty, or only comments and
   blanks) prints nothing, 0. A file past 64 KiB with no NUL is read whole.
7. **One read, by cat.** The file is opened once, by `cat` found on PATH, and
   no other command `felix_declared` runs (grep, sed, awk, head, tail, wc,
   od, tr, cut) names it. A cat that fails makes `felix_declared` return 2:
   one that prints nothing and returns nonzero prints nothing; one that
   prints part of the file and then returns nonzero returns 2 whatever was
   printed. The assertion that modelled grep's failure with a `grep` stub
   (`felix_declared returns nonzero and prints nothing when its grep fails`)
   is restated against cat, as any user.
8. **Its readers follow.** A file that is no list under rule 1 or 4 makes
   `_felix_cap_active` return 2, a stack-plan row grounded on a capability
   the file names read `unknown`, and `felix_declared_into` return 2 with its
   variable as the caller had it. A file read under rule 3 is a list:
   `_felix_cap_active storage` returns 0 for `\357\273\277storage\n`.
9. **Cost.** No more than one process more per call than the grep it
   replaces. Not asserted by the blind block; the review measures it.
