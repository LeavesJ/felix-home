# The evidence readers agree with the judge: the contract

The adversarial review of #482 found that `felix classify`, `felix receipt` and
`felix evidence` ask `[ -f evidence.tsv ]` before they consult the evidence
judge, while the judge (`_felix_evidence_judge`, which `felix_evidence_check`
and `felix merge` run) first asks `-e || -L`. Something that is not a regular
file stands at the path for the judge and is not there for the reader. The
reader then says no evidence is owed, and `felix merge` refuses. This predates
#482 and does not depend on it.

This file is the whole specification the blind assertions are written from. It
says what must be true, not how.

## Measured on main (1fca9559)

A widget-style project, a change on a branch, `evidence.tsv` in each state.
Reproduced with a fixture in the session scratchpad, not read off the code:

| `evidence.tsv` is | `felix merge --dry-run` | `felix classify` (green change) | `felix evidence` | `felix receipt` |
|---|---|---|---|---|
| absent | no evidence line | nothing is unproven | dies: declares no evidence.tsv | no unknown |
| a directory | `evidence evidence.tsv ... cannot be read, so its rules were not judged` | **nothing is unproven, eligible for auto-merge** | **dies: declares no evidence.tsv** | **no unknown** |
| a dangling link | same blocker | **same false all-clear** | **same false absence** | **no unknown** |
| a FIFO | same blocker | **same false all-clear** | **same false absence** | **no unknown** |

`felix incident` has the same `-f` test and prints no "the fix will have to
prove" section. `felix next` and the brief path (`felix_brief_evidence`) call
the judge without a file test and already agree with it.

## Words

- **The path**: `evidence.tsv` directly under the project directory.
- **Stands**: anything is at the path: a regular file, a directory, a link that
  resolves, a link that dangles, a FIFO. Nothing stands only where `-e` and
  `-L` are both false.
- **A table**: a regular file, or a link that resolves to one, that is
  readable. A link to a directory, a directory, a dangling link and a FIFO
  stand and are not a table.
- **Not judged**: the judge's own row for a path that stands and is not a
  readable table: status `unknown`, name `evidence.tsv`, a reason that holds
  "cannot be read" and "not judged". `felix merge` turns it into an `evidence`
  blocker. The readers already know that wording: `felix classify` says
  "evidence row(s) not judged" for it, `felix evidence` counts "row(s) not
  judged", and `felix receipt` lists `evidence` under unknown for it. Today a
  table that is a regular file with a row that is not four cells already
  reaches all three readers through the judge. That case is the reference: the
  new cases must read as it does.

## The one definition

**D1.** `lib/evidence.sh` defines `felix_evidence_table_present PROJ`. It
exits 0 when something stands at `PROJ/evidence.tsv` and exits 1 when nothing
does. It prints nothing. A regular file, a directory, a link that resolves,
a link that dangles and a FIFO are all 0. It reads no file.

**D2.** `_felix_evidence_judge` asks `felix_evidence_table_present` and nothing
else whether to say anything. Showing that: with the function replaced, after
`lib/evidence.sh` is sourced, by one that always exits 1, the judge prints
nothing for a table that is a readable file whose rule is met or unmet; with
it replaced by one that always exits 0, the judge prints the not-judged row
for a project that has no `evidence.tsv` at all. (In both, the judge still
reads the file itself in the ordinary way once it is past the question.)

**D3.** No file under `engine/harness/felix` or `engine/harness/lib/` other
than `lib/evidence.sh` tests `evidence.tsv` with `-f`, `-e`, `-L`, `-s`, `-r`,
`-d`, `test`, `[[` or `[`. Every reader asks `felix_evidence_table_present`.
(This is a source check on the tracked text; it is the only assertion that
reads the engine's text, and it exists because the bug was a second copy of
the question.)

## Readers

For each of three states of the path, **R**: a directory, a dangling link, a
link that resolves to a directory. Each reader below is run with the project's
base given as the branch the change was cut from.

**A1. `felix evidence`.** Exits 1. Prints a `[?]` row named `evidence.tsv`
whose reason holds "cannot be read" and "not judged", and a line saying
1 row not judged. It does not print "declares no evidence.tsv".

**A2. `felix classify`** on a change that touches only a markdown file (the
shipped risk table's green tier). Says that 1 evidence row was not judged and
that the change is not auto-merge eligible. It does not print "nothing is
unproven" and does not print "Eligible for auto-merge".

**A3. `felix receipt`** (its JSON). Lists `evidence` under `unknown`, and
lists no evidence gap and no met row.

**A4. `felix incident`** given an issue or trace that names a path. Prints the
"the fix will have to prove" section with one row named `evidence.tsv` whose
reason holds "cannot be read" and "not judged".

**A5. Agreement.** For each state in R and for the three controls below, the
words "not judged" appear in the output of `felix evidence`, `felix classify`
(green change) and `felix receipt` if and only if `felix merge --dry-run`
lists an `evidence` blocker for the same project and base.

## Controls (these hold on main before the fix)

- **C1.** Nothing at the path: `felix evidence` says the project declares no
  evidence.tsv; `felix classify` on a green change says nothing is unproven;
  `felix receipt` lists no unknown; `felix merge --dry-run` lists no
  `evidence` line. `felix_evidence_table_present` exits 1.
- **C2.** A readable regular file with one rule that the change touches and
  does not meet: all of `felix evidence`, `felix receipt` and
  `felix merge --dry-run` name the gap and not "not judged".
- **C3.** The same file, for a change the rule does not reach: no gap and no
  "not judged" anywhere; `felix classify` on a green change says nothing is
  unproven.
- **C4.** A link that resolves to the file of C2 stands at the path: the same
  verdicts as C2.
- **C5.** A regular file with a row that is not four cells: "not judged" in
  all four of `felix evidence`, `felix classify`, `felix receipt` and
  `felix merge --dry-run` (the reference case above).
- **C6.** (Skipped when the suite runs as root.) A regular file with mode 000:
  the same as C5.

## Fixtures and limits

- The project is the suite's widget project with its shipped risk table; its
  `evidence.tsv` is put back as it was after each state, and a link or
  directory made for a state is removed.
- A dangling link points at a name that exists nowhere. A link to a directory
  points at a directory made in the fixture.
- A FIFO is made with `mkfifo` and is never read, by the engine or by the
  test. It appears in D1 and, by amendment 1, in R. Every command run over a
  FIFO runs under a watchdog, and the watchdog ends the command's children
  too, not only the shell that started them: a child that opened the FIFO and
  stays blocked in it is a leak that outlives the suite's temporary directory.
- No assertion may depend on how many other blockers `felix merge --dry-run`
  prints. It reads the lines that start with `evidence` and nothing else.
- Every name is emitted on every run; an assertion whose state could not be
  built skips by name and says why.

## Amendments (2026-11-06, after the adversarial review of the first part)

The first part passed the contract above, and a reviewer who mutated the
engine one change at a time found what the contract had left out: three
mutants that no assertion caught (a FIFO-only carve-out in two readers and in
the judge, and `felix incident` printing its section with nothing at the
path), and two readers the part never ran. These amendments close them. Each
assertion below is new, and each says whether it holds on main before the
fix. The part keeps every assertion above.

**Amendment 1. R gains a fourth state: a FIFO.** Every reading of R above
(A1 to A5, and the arming assertion that the state stands and that
`felix merge --dry-run` lists the not-judged row) is run for the FIFO too,
under the watchdog the fixtures section describes. The engine never opens the
path, so none of these may hang. Red on main, like the other three.

**Amendment 2. C1 runs `felix incident`.** With nothing at the path,
`felix incident`, given a trace that names a path, prints its implicated files
and does not print the heading "the fix will have to prove". Holds on main.

**Amendment 3. A6, `felix next`.** For each state in R, `felix next` prints a
row saying an evidence row cannot be judged, naming `evidence.tsv`, and with
nothing at the path (C1) or a readable table (C3) it prints no such row. A5
extends to it: that row is there if and only if `felix merge --dry-run` lists
an `evidence` blocker. Holds on main; it guards the reader against a
regression.

**Amendment 4. A7, `felix brief`.** For each state in R, `felix brief`
given an issue that names a path prints a "what a fix must prove" section
with one row named `evidence.tsv` whose reason holds "cannot be read" and
"not judged"; with nothing at the path (C1) it prints no such section. A5
extends to it as for A6. Holds on main.

**Amendment 5. D3 reads every unary file test.** In D3 the operators are
every unary file operator the shell has (`-a -b -c -d -e -f -g -h -k -L -N -O
-p -r -S -s -t -u -w -x -G` and the others a `[`, `[[` or `test` takes), not
the six listed, so a reader that adds a `-p` or a `-h` test is found. Its
armed control plants one of the new operators and finds it.

**Amendment 6. D4, `receipt.sh` sourced alone.** A shell that sources
`lib/receipt.sh` and nothing else of the evidence code (it may source
`lib/resolve.sh` first, which `receipt.sh` already loads for itself) and calls
`felix_receipt` for the widget project and a base: (a) with nothing at the path
and with a readable table, prints nothing on stderr; (b) with a directory at
the path lists `evidence` under `unknown`, as the CLI's `felix receipt` does.
(a) holds on main; (b) is red on main, where the receipt takes a directory for
no table.

## Out of scope

Rewording any message the readers print. Changing what the judge says. The
`-f` question inside `_felix_evidence_declared`, which runs only after the
judge has found a regular file. Brief mode (`felix incident`, `felix brief`)
not reading `project.json`, so a bad `evidence_*` declaration that makes
`felix merge` refuse reads in the brief as ordinary rows: a different
disagreement, recorded for a later change.
