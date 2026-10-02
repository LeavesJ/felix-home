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
  list comes back empty with status 0. That is the case the `.` sentinel in
  `felix_declared_into` guards against.

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
  (`_felix_json_esc`). Under EAGAIN, any of them, including a capability name,
  can come back as `""`. The count the page shows still holds. A blank name is
  a different lookup, and it is shared by every member of the payload.
- `felix_detect` is not on the monitor page at all.
