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

**D4. Where it is read (as amended after the review, below).** The brief reads
`project.json` at the base `felix evidence` and `felix merge` take when none is
given: `main`, resolved as they resolve it (`origin/main` when that exists, the
local `main` when it does not). The commit that base names, not the working
tree: an uncommitted edit of `project.json` neither makes a declaration bad nor
fixes a bad one. When `main` resolves to nothing, it reads the commit `HEAD`
names, and when there is none (an unborn `HEAD`) nothing is declared and the
brief prints the table's rows as it does with no declaration. When the project
directory is not inside the repository the command runs in, it reads the disk,
as the others do. The repository is the one holding the current directory (its
top, when the command runs from a subdirectory), not the one holding the
project directory.

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
The fixture's change does not edit `project.json`; `HEAD` and the base may hold
different declarations (D4), and then the four agree on the base's. Where
`felix merge` refuses before it reaches its evidence check (a detached `HEAD`
or an orphan branch: "cannot name the branch to merge"), "all four or none"
holds of the other three only.

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
that is not a regular file: #488). A brief or trace that
names no file in the checkout: neither prints the section (the brief says that
nothing can be scoped), as before. Outside any repository, where no commit holds
a declaration. `felix incident` printing its heading over nothing for a table
with no row the path reaches and a good declaration (as before).
`felix next`, `felix classify`, `felix receipt` and `felix evidence`, which
already read the declaration through the check.

## Amendments (2026-11-06, after the adversarial review of the first part)

The first part passed D1 to D7 with the brief reading `HEAD`. The review found
that `HEAD` is not the base the merge reads: when `main` moves after the branch
point, or a branch is cut from a stale local `main`, the brief and the merge
disagree with a change that never touches `project.json`. D4 above is the
amended text (the base is `main`, as `felix evidence` takes it, and `HEAD` is
the fallback). The mutation review also found shapes the part never built.
Each assertion below is new, says whether it holds on the engine that read
`HEAD` (red) or does and guards a regression (green), and is built where the
project directory is inside the repository the command runs in (the part's H
fixture) unless it says otherwise.

- **Q1 (D4, red).** A home on branch `work`, cut from `main`, with a change that
  is not `project.json`; then `main` commits a bad declaration (R4) and `HEAD`
  returns to `work`, whose `project.json` is good. `felix brief` and `felix
  incident` print exactly the `project.json` row, with `felix evidence`'s
  reason, and `felix merge --base main --dry-run` lists an `evidence` line
  naming `project.json`: all four. Armed by the last two.
- **Q2 (D4, red).** The reverse: `main` holds a good declaration, `work` commits
  a bad one over it (so `HEAD` is bad). `felix brief` and `felix incident` print
  the table's ordinary rows and no `project.json` row; `felix evidence` prints no
  `[?] project.json` and the merge lists no `evidence` line naming it. (The branch
  that fixes or breaks its own declaration is judged by the base's, as the merge
  does.)
- **Q3 (D4, green).** No `main` resolves (the only branch is named `work`, no
  remote): the brief reads `HEAD`. With a bad declaration committed the brief and
  incident print the `project.json` row with the reason of the same fixture read
  by `felix evidence --base HEAD`; with a good one, the ordinary rows.
- **Q4 (D4, green).** An unborn `HEAD` and no `main` (`git init`, nothing
  committed, a bad declaration on the disk): the brief and the incident print
  the table's ordinary rows, no `project.json` row. Built in H; skipped by name
  if it cannot be.
- **Q5 (D4, red; skipped by name if the fixture cannot build it).** An unborn
  `HEAD` whose `origin/main` resolves and holds a bad declaration (`git init`
  over the files on disk, `git fetch` from a repository that has the commit):
  the brief and the incident print the `project.json` row, as `felix evidence
  --base origin/main` does.
- **Q6 (D1, green).** Two implicated paths. A brief given an issue that names
  `src/thing.js` and `WIDGET.txt`, and an incident given a trace naming both,
  under R4 in W and in H, hold exactly the one row `project.json`, with `felix
  evidence`'s reason: not one per path, and not none because there are two.
- **Q7 (D4, green).** Run from a subdirectory of the repository (`src/`), `felix
  brief` and `felix incident` in H, with a bad declaration committed and the
  working tree's file fixed, print the `project.json` row; with a good
  declaration committed and an uncommitted bad edit, the ordinary rows: the same
  as from the top.
- **Q8 (D4, green).** The project directory is in a repository of its own (a
  Felix home with a good `project.json` committed and R4 written uncommitted on
  its disk) and the commands run in a different repository, `FELIX_HOME` naming
  the home. The brief and the incident print the `project.json` row with
  `felix evidence`'s reason (the disk is read, as the project is not inside the
  repository the command runs in), and `felix merge --dry-run` lists an
  `evidence` line naming `project.json`: all four.
- **Q9 (arming).** Every state above has an assertion that it is the state it says:
  which branch the commit is on, what `main` and `HEAD` each hold, and the row or
  the absence of one in `felix evidence --base main` or `--base HEAD`.
