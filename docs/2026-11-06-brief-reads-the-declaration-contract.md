# The brief reads the declaration: the contract

`felix merge` reads `project.json`'s `evidence_vendored` and
`evidence_reads_vendored` before it judges any evidence row, and refuses with an
`evidence project.json ... so the rules were not judged` blocker when it cannot
read them (audit b11 round 3, B11R3-8). `felix incident` and `felix brief` (its
"what a fix must prove" section) never read `project.json` (B11R3-11), so for
the same project they print ordinary rows, or a heading with nothing under it
when `evidence.tsv` holds no row, while `felix merge` refuses. This is the
species of disagreement #488 closed for the path itself: a reader that tells a
person ahead of time something the merge judge does not say.

This file is the whole specification the blind assertions are written from. It
says what must be true, not how. Found by the adversarial review of #488, which
left it out of scope.

## Words

- **A bad declaration**: `project.json` at the commit `HEAD` names, in the
  repository the command runs in, holds a declaration `felix merge` cannot
  read. These are the states, **R**:
  - **R1** `evidence_reads_vendored` names a row that is no row of `evidence.tsv`.
  - **R2** `evidence_vendored` holds an absolute path (an entry that begins with `/`).
  - **R3** `evidence_vendored` is given twice.
  - **R4** `evidence_vendored` is not one JSON string (`"evidence_vendored": 3`).
  - **R5** an `evidence_vendored` entry has a `..` component.
  - **R6** `project.json` is committed as a symbolic link, not a regular file
    (skipped by name, with the reason, if the fixture cannot make one).
- **A good declaration**: neither key present, or both well formed and every
  `evidence_reads_vendored` name a row of `evidence.tsv`.
- **The row**: the one line `felix evidence --base <base>` prints as
  `[?] project.json <reason>` for a bad declaration. The reason holds
  "not judged".
- **A table**: `evidence.tsv` directly under the project directory, a readable
  regular file. It may hold rows, or none (comments and blank lines only).

## Decisions

**D1. The brief prints the row.** With a table and a bad declaration, the
section of `felix brief` ("what a fix must prove") and of `felix incident`
("the fix will have to prove") holds **exactly one row**: its name is
`project.json` and its reason is **byte for byte the reason `felix evidence`
prints for the row** for the same project. It holds no other row, whatever the
implicated paths are, whatever rows the table holds, even none, and even a row
the table holds that is not four cells. The declaration stands for every row
here as it does for `felix merge`, which prints that one unknown and judges no
row. The section is never a heading with nothing under it.

**D2. The brief reads the declaration, and sets nothing aside.** A good
declaration changes nothing the brief prints. A path under a declared
`evidence_vendored` directory still meets a row's `when` cell in the brief, and
a row named in `evidence_reads_vendored` is printed once, like any row.
(Existing assertion A148 of part 1832 holds unchanged.)

**D3. The order is the check's.** A path at `evidence.tsv` that stands and is not
a readable table is judged first, exactly as today: the one row is
`evidence.tsv` and `project.json` is not read, so a bad declaration beside it
adds nothing. Nothing at `evidence.tsv`: the brief prints no row and no
"must prove" section at all, with a bad declaration or without (as today, and as
`felix merge` lists no `evidence` blocker).

**D4. Where it is read.** `project.json` is read as `felix evidence` reads it at
a base that is `HEAD`: from the commit, not the working tree, when the project
directory is inside the repository the command runs in; from the disk when it is
not. An uncommitted edit of `project.json` in the working tree neither makes the
declaration bad nor fixes a bad one. The repository is the one the command runs
in (the repository holding the current directory), as it is for `felix merge`.

**D5. The library call.** `felix_brief_evidence PROJ PATHS` (two arguments, a
shell that sources `lib/resolve.sh` and `lib/intake.sh` and nothing else, the
current directory the repository) prints the same lines `felix brief` puts
under its heading. It keeps working as the two-argument call; an optional third
argument ROOT names the repository to read the declaration from, and when it is
absent that repository is the one holding the current directory.

**D6. Agreement.** For each of R1 to R5 (R6 where built) and for the controls
below: `felix brief` prints a `project.json` row, `felix incident` prints one,
`felix evidence` prints `[?] project.json`, and `felix merge --dry-run` lists an
`evidence` blocker naming `project.json`, **all four or none of the four**.
The fixture's change does not edit `project.json`, so `HEAD` and the base hold
the same declaration.

**D7. A149 of part 1832 is reworded.** That assertion's name ("it never reads
project.json, so a declaration the check cannot read changes nothing") states
the old behaviour. Its fixture is a directory that is no repository, where no
commit holds a declaration, so its check (the brief prints the `unit` row)
still holds and stays; its name says what it now shows, and the section line
above it says the brief "sets nothing aside". Part 2310 has the brief read
the declaration. The implementer rewords them, and nothing else in 1832 or
1830 changes.

## Controls (these hold on main before the fix, except C4)

- **C1.** No declaration: the brief prints the table's rows as it did, and no
  `project.json` row. Same for a good declaration (D2).
- **C2.** A bad declaration and **no** `evidence.tsv`: neither reader prints a
  "must prove" section, and `felix merge --dry-run` lists no `evidence` blocker.
- **C3.** (Skipped when the suite runs as root.) A table of mode 000 and a bad
  declaration: the one row is `evidence.tsv`, in `felix brief`, and the section
  holds no `project.json` row.
- **C4.** (Red on main: the brief reads nothing there.) A bad declaration in
  a project whose directory is **not** inside the repository the command runs
  in, written to the disk: the brief and `felix evidence` agree with each other
  (a row `project.json` in both).

## Fixtures and limits

- The project is the suite's widget project with its shipped risk table; its
  `evidence.tsv` and `project.json` are put back as they were after each state,
  and any commit a state makes is on a ref of its own that is removed.
- `felix brief` is driven with `--from -` and an issue text that names a path
  that exists in the checkout; `felix incident` is driven with a trace that
  names one. Both read from stdin and neither needs `gh`.
- A state is **armed** by its own assertion: the fixture is the state it says
  (the declaration is what the state says, and `felix merge --dry-run` or
  `felix evidence` shows the row), so a pass is never a fixture that did
  nothing.
- No assertion may depend on how many other blockers `felix merge --dry-run`
  prints. It reads the lines that start with `evidence` and nothing else.
- Every name is emitted on every run; an assertion whose state could not be
  built skips by name and says why.

## Out of scope

Rewording any message. The path question (`evidence.tsv` standing as something
that is not a regular file: #488). Which base `felix merge` reads
`project.json` at on a branch that itself edits `project.json`: the brief reads
`HEAD` (D4) and does not look for a branch point, so a branch that fixes its own
bad declaration reads good in the brief and bad in the merge until it lands.
`felix next`, `felix classify`, `felix receipt` and `felix evidence`, which
already read the declaration through the check.
