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

**Mechanism.** `command cat -- <proj>/capabilities | ( LC_ALL=C; ... ) 2>/dev/null`,
with the status taken from both halves of PIPESTATUS. The subshell reads the
bytes with `read -d ''`, which stops only at a NUL (exit 3). It cuts a leading
`\357\273\277` by offset, splits on newlines with `set -f`, and skips blank and
comment lines by `[[:space:]]` in the C locale. A kept line holding anything
but tab and `[[:print:]]` is exit 4. The kept lines go into an array and are
printed with one `printf '%s\n'`. This follows #383's one-read shape:
- One open, by a named command whose status says whether a read failed. The
  read builtin returns a read error as end of input, so a redirect would not.
- The C locale is set inside a ( ) subshell, so the caller's locale, IFS and
  set -f stay its own. Bash 4 to 5.2 in a UTF-8 locale also hides a NUL that
  follows a UTF-8 lead byte from `read -d ''` unless the locale is C.

**Built as spec, blind assertions, fix, review.**
- **Blind block (b7e264bc, Opus).** 50 assertions written from the contract
  alone, under LC_ALL=C and a UTF-8 locale, with pipefail on and off. 31 were
  red against origin/main 6fe5f986 and against the base, under both locales.
  The 19 green ones guard rules 0, 5 and 6 and the caller's state. The old
  `declared-grep2` assertion was restated against a cat stub; it is red
  against both.
- **Fix (a48ce174, Sonnet).** 50/50 under C, en_US.UTF-8 and C.UTF-8. The
  neighbouring cmlf, dura and durc blocks stayed green. Six mutations each
  reddened 3 to 9 assertions.
- **Review (two Opus reviewers).** No blocker. Both found that the block
  passed a fix with `set -f` removed: `*` then read as the files in the
  caller's directory. They also found:
  - output through echo was not caught;
  - a mark stripped after the split or after leading whitespace was not caught;
  - a name check that stopped at an inline `#` was not caught;
  - a NUL decided by a second open (a redirect) was not caught;
  - the BOM strip `${x#mark}` and the string appends were quadratic, 5.66 s of
    CPU on 670 KB and 1.95 s for 8,000 names;
  - `cat` could be shadowed by a function;
  - a readonly LC_ALL leaked a bash message on stderr;
  - the comment stated GNU grep's behaviour as measured;
  - the positional-parameter clause in two assertion names could not fail.
- **After review (5936b4cd, 454142ae).**
  - The mark is cut by offset and the names kept in an array: 0.18 s and
    0.10 s, with output byte-identical to before.
  - `command cat` is used, the subshell's stderr is discarded, and the comment
    says GNU grep's behaviour was not run.
  - Eight not-blind assertions were added, each red only against the mutant it
    names: noglob, echoout, bomaftersplit, bomafterws, remarkunchecked and
    secondopen. Each reddened 2 and nothing else.
  - The two names were corrected.
- **Final count, block alone, section runner.** 58 assertions: 58/0 on the
  branch under C and en_US.UTF-8, and 21/37 against origin/main and against
  the base. Not yet recorded: no full suite has been run.

**Cost, measured on /bin/bash 3.2 here.** One process more per call: a cat
and a subshell where one grep was, and no extra exec. `_felix_cap_active`
took about 3.0 ms of child CPU per call before and 3.7 ms after, over 200
calls, at load 400.

**Not run here, and why.**
- GNU grep's binary mode was not run; there is no Linux machine here.
- The bash 4 to 5.2 lead-byte NUL case is pinned by the `\303\000` assertions
  under a UTF-8 locale, which only CI's bash 5 can make red.
- A { } group in place of the ( ) differs only under lastpipe (bash 4.2 and
  later), which no bash here can show red, so it is not asserted. The engine
  sets no lastpipe.
- A caller's readonly LC_ALL makes every list 2. It fails closed, and no caller
  sets one.

**Landing.** Position 8 in the 2026-10-08 carrier queue
(~/.felix/memory/felix/audits/2026-10-08-carrier/state.md), behind .277
claude/declared-unread-readers, on whose head 4ccc9e09 this branch is merged.
At "you are next":
1. merge that slot's gated head;
2. record, then `tests/red` against it;
3. gate after it lands.
No table under projects/ is touched.

**Seen in passing, not this branch's.** At 12:47:41 local on 2026-10-08,
`remote.origin.url` in the home's shared .git/config was set to
https://github.com/acme/widget.git, a fixture URL that main's tests/run
holds and this branch's tests/run never wrote. By 12:55 it was restored.
Sessions "Stop tests/run rewriting the real repo's origin" and its siblings
took it up.
