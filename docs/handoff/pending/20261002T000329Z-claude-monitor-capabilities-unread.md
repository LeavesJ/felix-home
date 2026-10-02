### 2026-10-01: the monitor says a declared-capabilities list it could not read, and never shows it as empty

Waits on claude/commission-lookup-fails-unknown (8d508021) and
claude/declared-unread-readers, which adds `felix_declared_into`. Both land
first, in the carrier's order. This branch then merges main. The engine change
is in lib/monitor.sh and templates/monitor.html. The rest is in tests/run.

**Defect.** `_felix_mon_project` (lib/monitor.sh) writes the project's
capabilities into the monitor JSON itself:
`[ -f "$proj/capabilities" ] && grep -v '^$' ... | _felix_mon_json_list`.
That bypasses `felix_declared` and gets four things wrong:

- A `capabilities` link whose target is gone, a directory, or a pipe fails
  `-f`, so it reads as `[]`, a project that declares nothing.
- A file grep cannot read is also `[]`, or a partial list.
- Comment lines are listed as capabilities.
- Under EAGAIN, or on bash 3.2 when a substitution cannot make its pipe, the
  list comes back empty with status 0. That is the case the sentinel behind
  `felix_declared_into` guards against. It was a `.` when this was written,
  and the readers branch's after-review pass moves it into `felix_capture`
  as `\n.`, with the same statuses.

The page's script has never read `capabilities`. Only `cur()`'s fallback
project named it, until bf12b9d1 (2026-08-10) dropped it from there. So the
field is written and never shown. An unread list is `[]` in the
payload and says nothing on the page.

**Decision.** The page says it. Dropping the field, as the `plugins` array
was dropped, would leave the page unable to say anything false. It would also
leave the capability accounting the file's header names as the monitor's job
behind glass. The payload keeps the array for a list that was read, and holds
an object for one that was not. The memory panel gains a row for it. The page
counts only an array, so `null`, a missing key, or `p.capabilities||[]` can
never turn "not known" back into zero.

**Contract.** Written before any code, and the only thing the blind assertion
author was given. WHY is the exact phrase
`the capabilities this project declares could not be read`.

"Unread" means any of the following:
- `felix_declared_into` returned nonzero, or is not defined;
- `felix_declared` returned nonzero, whether or not it printed lines first;
- the substitution that ran `felix_declared` ended before anything was printed
  after it returned 0.

In-process, these are modelled by redefining, after the libraries are sourced,
`felix_declared_into() { return 2; }`, `felix_declared() { return 2; }`,
`felix_declared() { printf 'billing\n'; return 2; }` and
`felix_declared() { exit 0; }`. Out of process, they are modelled by a
`capabilities` that is a link whose target is gone, a directory, a named pipe,
or a regular file mode 000 (run as a user other than root).

"Read" means the list was read. That includes a file of only comments and
blank lines, an empty file, and no `capabilities` at all.

1. `_felix_mon_project PROJ HOME` (lib/monitor.sh), with lib/resolve.sh,
   lib/detect.sh and lib/monitor.sh sourced. It prints one JSON object, and
   that object is valid JSON in every case below.
   - Read: its `capabilities` member is an array of the declared lines as
     `felix_declared` prints them, in file order, one string each. Comment
     lines (`#` after optional whitespace) and blank or whitespace-only lines
     are not in it. It is `[]` only when the list was read and declares
     nothing, or when there is no file.
   - Unread: `capabilities` is exactly
     `{"unknown":"the capabilities this project declares could not be read"}`.
     It is never an array, never `[]`, never `null`, and never absent.
   - A named pipe is not opened: the call returns without a writer on the
     pipe.
   - Every other member (`name`, `gate`, `routes`, `stack`, the logs, their
     totals, `compliance`, `lessons`) is the same as for the same project with
     a read list.
2. `felix_monitor_render TPL HOME OUT` and `felix monitor`. The rendered page
   carries that same `capabilities` value for each project, and the render
   succeeds and writes the page when a project's list is unread.
3. The page (templates/monitor.html), run with the payload in place. The
   memory panel (`#mem`) holds its existing rows in their existing order, with
   their existing values: `lessons on file`, `gate failures`,
   `tools declared`, `things said`. Directly after `tools declared` it holds a
   key `capabilities declared` and its value cell.
   - When the project's `capabilities` is an array, the value is its length
     as a decimal string, such as `0` or `2`.
   - When it is anything else, the value is `not known` and the cell carries
     the class `warn`. That covers the unread object, `null`, a missing key, a
     string and a number. Its title (set as a property or with `setAttribute`)
     is the object's `unknown` string when there is one. Otherwise it is
     `this page's data does not say which capabilities this project declares`.
   - A read list's cell does not carry `warn`.
   - With no projects at all, the row reads `0`, as the other counts in that
     panel do for the placeholder project.
   - The script runs to the end without throwing in every case above.

Settled after the blind author's questions (2026-10-01), before any code:
- `felix_declared` here is the one claude/commission-lookup-fails-unknown
  leaves. It returns 0 for an empty or only-comments file, where main's
  returned grep's 1. The read cases above assume that.
- lib/monitor.sh does not source lib/detect.sh. Whoever sources the monitor
  sources detect.sh, as `felix` does, so an undefined `felix_declared_into` at
  call time is unread.
- An `unknown` that is not a string, such as `{"unknown":5}`, takes the
  fallback title.
- A read list's cell has no title and no `warn`. The no-projects row is `0`
  without `warn`.
- A declared line keeps whatever leading whitespace `felix_declared` keeps.

Settled after the adversarial review (2026-10-01):
- An empty `unknown` string takes the fallback title too, and its cell carries
  `warn`. The first fix keyed the class on the title, so `{"unknown":""}` was
  a plain `not known` with no title.

Not in this change, and why:
- Every string in the payload is escaped through a substitution
  (`_felix_json_esc`), and any of them can come back as `""`. One cause is
  EAGAIN. The other is a byte that is not UTF-8 under a UTF-8 locale, where
  `sed` stops with "illegal byte sequence" (the writer review, 2026-10-01).
  The count the page shows still holds. A blank name is a different lookup,
  and every member of the payload shares it.
- `_felix_json_esc` escapes only tab, CR and newline. Any other control
  character (`\x01`, form feed, ESC) passes into the payload raw, so
  `JSON.parse` refuses it, though the page still runs, because it embeds the
  payload as a script literal. This predates the change and applies to every
  member.
- `felix_declared` has these defects, and the writer prints faithfully what it
  hands back. They went to the claude/declared-unread-readers session on
  2026-10-01, since detect.sh is theirs:
  - A file macOS grep takes for binary (a NUL byte, UTF-16) returns 0 and
    prints `Binary file ... matches` as a capability.
  - `GREP_OPTIONS` (macOS grep honours it) rewrites every line.
  - A BOM before a comment makes the comment a capability.
- The walk is quadratic in the list's length: 2000 lines took 1 s of CPU,
  measured. Real lists are tens of lines.
- `felix_detect` is not on the monitor page at all.

**Procedure and evidence (2026-10-01).** Every count below is from the
section runner: tests/run lines 1-152, with REAL_HARNESS pointed at the engine
under test, then only the marked block. None is from a suite run.
- Contract: written in this session (Opus 5.5) before any code.
- Blind assertions: one Opus agent given only the contract. It made 113 and
  then 9 more after the contract settled its questions. Against origin/main,
  74 of 122 failed. Against claude/declared-unread-readers alone
  (1e0197ca, fd5528f7), the same 74 failed: that branch does not fix the
  monitor.
- Implementation: in this session (Opus 5.5), not a Sonnet stage. It was
  about 30 lines with the design settled, and the blind author was already a
  different agent from the implementer. Against fd5528f7 plus the fix, 122 of
  122 passed on bash 3.2 (/bin/bash, which is the suite's bash on this Mac).
- Adversarial review: two Opus agents, read-only.
  - Page and tests. One should-fix: an empty `unknown` was drawn plain.
    Fixed. All 8 named mutants were killed, and 5 weaker ones survived. The
    escape mutant, whitespace and duplicates, `felix monitor`'s read half, an
    empty name and the amber rule are now asserted, marked "after review, not
    blind".
  - Writer. No blocker. The fork comment was untrue, and is rewritten.
    `_felix_mon_json_list` lost its last caller, and is removed. The rest is
    out of scope above.
- After review: 138 assertions. origin/main fails 83, fd5528f7 alone fails
  83, the first fix fails 2 (the empty reason), a no-escape mutant fails 3,
  and the fix passes 138.
- Not yet run:
  - the full suite;
  - `tests/run --record-assertions` (assertions.tsv gains these names);
  - `felix gate`.
  All three wait for the carrier's weekly batch slot. It is registered in
  the order after claude/commission-lookup-fails-unknown and
  claude/declared-unread-readers, and it is not folded into either.

**After both prerequisites are on main**, whoever carries this branch:
1. Merge origin/main in. Do not force-push. Expect conflicts only in
   tests/run, where both prerequisites add blocks. Keep every block.
2. Show it still red. Export origin/main's engine/harness. Then run tests/run
   lines 1-152, with REAL_HARNESS set to that export after line 23, followed
   by the block between `# >>> monitor-capabilities-unread` and
   `# <<< monitor-capabilities-unread`. 83 assertions should fail.
3. Show it green. Run the same block against this branch's own engine: all
   should pass. If felix_declared_into changed signature or statuses on the
   way in, the in-process models in the block say so first.
4. Then, in the carrier's slot only: the full suite,
   `tests/run --record-assertions`, `felix gate`, the PR, the merge.
