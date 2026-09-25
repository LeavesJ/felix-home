### 2026-09-25: a `qualification.tsv` holding a NUL byte is refused as a whole, through the one read

Built on #382 (claude/qualify-read-fails-closed), which made `felix qualify
--gate` read the table once. This is the NUL row its section handed on.

**Defect closed.** macOS ships the BSD awk (20200816). It keeps a record as a
C string, so a NUL byte ends the line there. `qualification.tsv` was read by
that awk:
- `\000demo<TAB>true<TAB>violation<TAB>fail<TAB>true` read as a blank line. It
  was skipped, never run and never called MALFORMED, and `felix qualify
  --gate` exited 0 over the held control on it.
- A NUL later in a row cut the row there, dropping a premise or the end of a
  mutation.

mawk and gawk keep the byte, so the same table read two ways on two machines.
git calls a file with a NUL in its first 8000 bytes binary, so the diff showed
a reviewer no row of the table. Now a table holding a NUL anywhere is refused
whole:
- `felix qualify [--gate]` runs nothing and exits 2, with a `felix:` line
  naming the table and the byte.
- `felix gate` shows that line under `qualified FAIL`.
- The library readers and `felix_obligations_needs` refuse the same way.

**Mechanism, and why this one.** The awk cannot be asked: the byte never
reaches it. The one read is now `cat -- "$f"` into the shell
(`_felix_qualify_bytes`). There `IFS= read -r -d ''` succeeds only on reaching
a NUL, and awk parses the body the shell captured. That keeps
#382's one read. A NUL scan before the parse would
be a second open, and the table could change between the two.

The file is opened by cat, by name, rather than by a redirect, for the suite.
Its one-read and fault-sweep assertions count and fail reads by PATH-shimming
the command that names the table. They shimmed awk alone. They now shim awk,
cat, grep, sed, head, tail, wc, od, cut, sort and cmp, so a second look added
later is a count of two. A redirect is the one read no shim can see.

**Built as spec, blind assertions, fix, review.**
- A blind author wrote 32 assertions from the spec alone, in their own
  worktree. 19 were red against the unfixed engine, and the controls and
  one-read counts were green.
- The adversarial review found one fail-open. bash 4 to 5.2 in a UTF-8 locale
  reads the byte after a UTF-8 lead byte as part of the character without
  checking it against the delimiter. So `\303\000` hid the NUL from `read`, and
  every row after it was dropped with status 0. That is ubuntu CI's bash 5.2.
  The read now runs in the C locale, in a `( )` subshell. The suite covers the
  case in a UTF-8 locale, but only a bash newer than macOS's 3.2 can fail it,
  so it bites in CI.
- The review also removed an overclaim: the message said git calls the table
  binary, but git only checks the first 8000 bytes.

**Cost.** bash reads a pipe one byte per syscall. For the engine's own 64 KB
table that is about 30 ms of CPU per read, against 4 ms before. A 4 MB table
costs 3.3 s. `felix gate` reads the table about five times: once for
qualified, and in obligations twice plus once per declared checker a need
names (two in the engine's own table). No hook reads it.

**Already there, and why it was not enough.** `bin/schema-check` (lib/table.sh)
refuses a NUL in any tracked table. So felix-home's own gate went red on
`schema` while still printing `qualified ok`. But schema-check runs only in
felix-home's gate, by a second read of its own, and every other project's
`qualified` check passed.

**Handed on, not done here:**
- `felix_obligations_needs` reads the table several times. A NUL that appears
  between its reads is said as "could not be read", because
  `felix_qualify_missing_controls` maps every failure to 2. The summary line
  `felix obligations` prints, "what would discharge them could not be read", is
  the same for a NUL table. The stderr line above it names the NUL.
- On bash 3.2, a caller with `set -T` and a DEBUG trap that runs a pipeline
  overwrites PIPESTATUS before `_felix_qualify_bytes` reads it. The engine sets
  no DEBUG trap.
- escape.sh reads the table's blobs through `git show | grep -v`. If both
  sides hold an early NUL, BSD grep prints one "Binary file matches" line, and
  a removed control is not seen. That needs a NUL table already on main, which
  this refusal and schema-check now keep off.
- Other tables' readers (deny.tsv, probes, commissioning, obligations) are
  NUL-blind the same way. schema-check refuses a NUL in any of them in
  felix-home's tree.

**Traps paid:**
- In a Bash call, `rm -rf` and `--amend` trip the fact-forcing gate whatever
  facts come first. A fresh `mktemp -d` and a new commit get past without
  either.
- The deny hook refuses a heredoc that writes a `.felix` marker, even into a
  temp fixture. Bind a scratch fixture by git remote instead.
