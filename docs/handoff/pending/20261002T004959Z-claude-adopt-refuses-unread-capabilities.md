### 2026-10-01: adopting refuses a capabilities list it cannot read and write, and writes nothing anywhere

Branch claude/adopt-refuses-unread-capabilities, four commits on 27573cbe. It
lands inside claude/adopt-newline-before-append's PR: the carrier chose one PR
for both adopt fixes, in the weekly batch, after lookup-fails (0.49.244).
Engine only: no table under projects/, no escape, and no version bump yet. The
record and the bump are taken at the slot.

**Defect closed.** `felix_adopt_capability` (lib/adopt.sh) ran `touch`, then
`grep -qxF`, then an append whose status nobody read. Then it appended the
stack.tsv and setup.tsv rows and reported the capability adopted. So:
- A link whose target was gone: `touch` created the target, or failed when the
  target's directory was gone too. Then the grep and the append failed, and
  the rows were written all the same.
- A directory: appended to in vain, with the rows written.
- A pipe: the grep opened it and waited for a writer, forever.
- A link to /dev/null: the append succeeded, into nothing, and the rows were
  written.
- A read-only list: the append failed, and the rows were written.

Through the session-start hook, every one of these was said as `Adopted
automatically`.

**Now.** The function reads and writes the list only as `felix_declared` (on
lookup-fails) reads it, as a regular file.
- Something at the path that is not a regular file is 2, without being opened.
- A grep status above 1 is 2.
- A failed append is 2.
- Nothing at all is still an empty list, which the append creates.

On 2 it prints nothing and writes nothing anywhere.
- `felix adopt` names what is at the path and exits 2, where before it said
  `already declared`.
- `felix adopt` also refuses a name that is not one ASCII word of letters,
  digits, `.`, `_` and `-`. grep -F reads a newline in its pattern as two
  patterns, so `felix adopt $'new\nci'` said `ci already declared`.
- The hook says a capability it could not adopt (`Not adopted, because
  <proj>/capabilities could not be read or written: <caps>`). It used to drop
  it like one already declared, so a surface on a read-only list went
  unmentioned every session.

**Built as contract, blind assertions, red, fix, review.**
- A blind author wrote 169 assertions from the contract alone, barred from
  adopt.sh and cmd_adopt. Against main they were 37 pass and 132 fail. The 37
  were preservation (A1-A4, E, the hook control) and clauses main already met,
  each named by the author. Against the fix: 169 of 169.
- One adversarial review (simpler, defeat, agreement, tests, with mutations)
  found no blocker and four should-fix items:
  - the hook's silence over a read-only list;
  - the missing-final-newline glue, which predates this change and which
    adopt-newline-before-append fixes in the same PR;
  - three "it found a directory" needles that matched the absent case's
    advice;
  - `[ "$rc" -eq 1 ] || return 2` pinned by nothing, so a write-only list
    gained the capability twice and its rows.

  All four are fixed or carried. 35 assertions were added after review, marked
  "not blind", and each was shown failing on the mutant or older head it
  names: M01 16, M13 1, M19 3, f312a3e9 7.
- The block is now 204 assertions. Main gives 40 pass and 164 fail, and the
  fix gives 204 of 204. HEAD merged with origin/claude/declared-unread-readers
  (which carries lookup-fails) also gives 204 of 204. Section runner, about
  20 s on the fix; never the full suite.

**Left as found, and why.**
- **Races.** A pipe swapped in between `[ -f ]` and the grep, or created
  between the absence test and the append, still blocks. Plain shell has no
  non-blocking open.
- **Unpinned lines.** The `--` on the grep, the brace-group `rc=2` form (kept
  to match `felix_declared`), and `felix adopt`'s fallback wording ("a file
  whose read or append failed") leave all 204 green under mutation. No caller
  can reach the first. The second differs only when /dev/null cannot be
  opened. The third needs a grep that fails on a readable, writable regular
  file, and the name check now refuses the one input that did that (a
  non-UTF-8 byte under BSD grep).
- **`felix discover --adopt`** does not call this function. It appends
  OBSERVED rows to stack.tsv itself.
- **Root skips.** As root, the C, D, write-only and absent cases are skipped,
  since root reads and writes whatever the mode. The names stay in the
  manifest as reached.
