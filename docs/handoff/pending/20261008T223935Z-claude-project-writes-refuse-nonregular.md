### 2026-10-08: overwrites and non-table opens under projects/<name>/ refuse what is not a regular file

Branch claude/project-writes-refuse-nonregular, on claude/adopt-newline-before-append
(ea68ed86). That branch made every append to a project table, and every read of
one, refuse a pipe, a dangling link or a directory. Engine only: it touches no
table under projects/, no commissioning table and no escape, and bumps no
version. The record and the bump are taken at the slot. The commits are
squash-merged, so the `wip:` ones are working history.

**Defect closed.** The completeness review of claude/table-readers-keep-unended-line
(2026-10-02) left three sites that overwrite a project file or open a non-table
one. The class, enumerated, held seven. Measured on the base engine, each one:
- `felix obligations --seed` copied through the `[ -f ]` refusal. On a pipe
  it blocked. Through a dangling link it created the target. Into a directory
  it copied inside. Both of the last two said "seeded".
- `felix autonomy --allow commission` wrote the stamp `autonomy.commission`
  with `>`. On a pipe it blocked after the grant was written. Through a
  dangling link it created the target. On a directory the write failed and it
  still said "stamped". Through a symlink or a hard link to `autonomy` it
  overwrote the grant file with the hash, so it said "allowed" and "stamped"
  while neither tidy nor commission held (found by the review of
  claude/autonomy-allow-fails-closed). That last case is the same on main.
- `felix gate` ran `projects/<p>/<gate>` when `-x` held. A pipe at mode 755
  blocked: bash waits on it even with a writer present. At 644, or as a
  dangling link or a directory, it fell through to `bash -c gate.sh`, and the
  126 or 127 was recorded as the project's own failure.
- `_felix_rival_gates` (lib/detect.sh) took the declared gate on `-x`. It then
  ran `cmp -s`, which blocked on a 755 pipe. That held `felix doctor`, and
  session start through `felix_tidy_safe` when tidy is granted. On the
  checkout side, a tracked rival replaced by a 755 pipe, or an untracked
  symlink to one, blocked doctor and tidy the same way. git lists both. A
  directory there read as "differs from the copy Felix holds".
- adopt's runbook (`sed > projects/<p>/setup/<id>.md` in lib/adopt.sh) blocked
  on a pipe. Session start runs it for every capability the checkout grew, so
  one pipe held every session start of that project. Through a dangling link
  it created the target, and through a link to a file it overwrote that file.
  On a directory it failed and still counted the step.
- `felix new` refused an existing `projects/<name>` with `[ -e ]`, which a
  dangling link passes. mkdir then failed and every write failed, while the
  marker still bound the checkout. It printed "created" and exited 0.

**Mechanism.** Helpers in lib/resolve.sh, beside felix_line_ended:
- `felix_not_regular PATH` prints what is at a path that is not a regular
  file, in cmd_adopt's words: `a pipe`, `a directory`, `a link whose target is
  gone or cannot be reached`, `not a regular file`. It returns 1, printing
  nothing, for a regular file or for nothing there. It asks only what stat
  answers.
- `felix_not_replaceable PATH` does the same for a path the engine writes
  whole. It also refuses a symlink to a regular file, as `a link to another
  file`.
- `felix_replace_file PATH CMD...` writes PATH whole, so a hard link is cut
  rather than written through. It is two halves, for a caller with something
  to do between them:
  - `felix_replace_prepare` writes CMD's output to a temp file beside PATH and
    prints the temp file's name. The write itself is `felix_replace_fill TMP
    CMD...`, so a caller that must not leave the temp file on a signal can
    make it, name it to its own trap, and fill it after. The file is 0600 for
    the write and gets the umask's mode after it. CMD runs in a subshell that
    ignores SIGXFSZ, redirected as a whole, so a write past the file-size
    limit fails with a status, the temp file is removed, and bash 3.2's
    leftover buffer goes into the file rather than into the caller's `$( )`.
  - `felix_replace_commit` renames that file onto PATH. It returns 1 and
    removes it, including a copy the rename put inside a directory, unless
    PATH ends up a regular file that is not a link.

Each site refuses before it writes, runs or records anything:
- **CLI refusals exit 1** through `die`, as `felix autonomy --allow` already
  does for a grant it cannot write. This covers seed, stamp, gate and new. The
  stamp is checked before the grant, so a refusal writes nothing. `felix new`
  also checks its own mkdir before it writes the marker.
- **The runbook refusal is adopt's own 3.** The step is refused whole, row as
  well, because a row left without its runbook makes the next adopt skip the
  step. adopt refuses a setup/ that is not a plain directory, saying what it
  is (`a link to another directory` for a linked one). It prepares the runbook
  before writing the row and commits it after, so a failure at any point
  leaves no row. The rc-3 advice in cmd_adopt and session start now names
  setup/.
- **`felix setup <id>`** says what is at a runbook path that is not a regular
  file, rather than "No runbook written yet".
- **Rival detection** takes regular files only, on both sides. A declared gate
  that is not one is noted as "the gate Felix holds is <what>, so nothing was
  compared". With no gate declared, the note is "this project declares no
  gate, so nothing was compared".

**Beside the class, and owned elsewhere:**
- `--revoke`'s `autonomy.new`: claude/autonomy-revoke-fails-closed, mktemp.
- The `autonomy` grant file's own refusal: claude/autonomy-allow-fails-closed.
- The writer lock: claude/autonomy-writer-lock.
- git readers of the checkout: claude/git-reads-fail-closed.
- `felix_route_append_play`'s mv onto routes.tsv: `[ -f ]` first, and it
  replaces a symlink rather than blocking. Left.

**Tests.** Four tests/run blocks, before `reached`, each written blind by an
Opus agent that read only its contract and the two pre-fix engine exports
(base ea68ed86 and origin/main 6fe5f986). Every FIFO case is bounded by a
helper that kills only its own pid tree. The helper allows 8 s, extended while
the tree is still changing at load 380-700, and kills an idle tree at once.
- *non-table project paths refuse what is not a regular file, and open no
  pipe*: 182 assertions over S1-S6 and the helper, each refusal kind beside a
  control. Four 0444-stamp assertions were changed by the implementer after
  the blind pass, under an amendment. A rename needs the directory's write bit,
  not the file's, so the failing write became a mode-0555 project directory.
  The three that say what is reported go red against a mutant that drops the
  stamp's `|| die`.
- *the commission stamp and adopt's runbook replace their file, and never
  write through a link*: 59 assertions, from the link addendum.
- *adopt never leaves a step without its runbook, and the replace helper, felix
  new, felix setup and doctor say what is there*: 168 assertions, from the
  review addendum. Every recovery case shows the property the change exists
  for: once setup/ is cleared, a second adopt writes the row and its runbook
  together. On the old engines the row from the first adopt stayed, the
  second adopt skipped the step, and the runbook was never written. The
  author also checked its block against its own patched copy of the base
  engine (168/168) and 28 mutants of that copy. Every mutant was caught.
- *the replace helper leaves nothing behind when the file-size limit stops its
  write*: 19 assertions, from a fourth addendum. Under `ulimit -f 0`, each
  limit is set inside a subshell that reports through a pipe, because the
  limit also stops a report written to a file. Each helper case first asks
  whether the helper is a function. A missing helper also leaves PATH alone,
  so about seven cases would otherwise pass on the old engines. The author
  checked its own patched copy (19/19) and eight mutants, all caught. It has
  not been run under bash 5 on Linux; CI is the first run there.

The third block found the review's R1 fix incomplete. a21148ea moved the mode
change after the write, but mktemp's own 0600 is masked by the umask too.
Under umask 0222 the temp file was born 0400, and the write into it was
refused. So every stamp and runbook still failed there, where `>` had
succeeded. f25bf26c makes the file 0600 before the write. Nine assertions
were red on a21148ea and are green on f25bf26c.

The author of the second block was given one phrase from a code comment as if
it were in the contract. It noticed and asserted nothing on that phrase.

Section runner (tests/run through the line before `resolution`, then the
block, from a fresh mktemp -d outside every repository):

| block | this branch | base ea68ed86 | origin/main 6fe5f986 |
|---|---|---|---|
| 1 (182) | 182 pass | 139 red, 20 calls blocked | 137 red, 20 calls blocked |
| 2 (59) | 59 pass | 43 red | 43 red |
| 3 (168) | 168 pass | 86 red | 86 red |
| 4 (19) | 19 pass (a4d4d514: 4 red) | 17 red | 17 red |

**Review (Opus, 2026-10-08, workflow wf_92282b57-feb), three lenses.**
- **Completeness.** It enumerated the class independently. It found no site
  under projects/<name>/ that still blocks on a pipe. Every open of a
  non-table file there is one of this branch's sites, or is `[ -f ]`-guarded.
  It found:
  - **F1 (medium):** a setup/ that was a file, a pipe, a link or an
    unwritable directory left the step's row without its runbook, and the
    printed recovery could never write it. All three lenses found this.
  - **F2:** a runbook was written through a setup/ that is a link to another
    directory.
  - **F3:** `felix new`'s unchecked mkdir.
  - **F4:** `felix setup <id>` called a pipe "No runbook written yet".
  - **F5, handed on:** the template's `constitution` commissioning row
    (`test -s`) reads done when CLAUDE.md is a directory. commissioning.tsv is
    an escape table, so the change is the founder's.
- **Regressions.** 79 existing blocks gave the same verdicts on base and fix.
  It found:
  - **R1:** the helper set the temp file's mode before writing it, so under a
    umask without the owner's write bit every stamp failed where `>` had
    succeeded.
  - **R2:** the same stranded row as F1.
  - **R3:** doctor said "gates with a command" for a project with no gate.
- **Mutation and races.** 20 mutants. Every guard is pinned by block 1 or
  block 2, except the runbook-after-row branch (F2 of this lens). It found:
  - a directory or link appearing at the stamp path between the check and
    the rename took the file inside it, while the command said "stamped";
  - the same umask order as R1.

**Taken, all of them, in a21148ea:**
- adopt makes the runbook in a temp file before the row, and renames it after.
  It refuses a setup/ that is not a plain directory, in the class's words
  (`a link to another directory` for a linked one).
- The helper is split into felix_replace_prepare and felix_replace_commit. It
  sets the mode after writing, and the commit refuses a rename that does not
  land at the path.
- felix new checks its mkdir before the marker.
- felix setup and doctor say what is there.

f25bf26c then made the temp file 0600 before the write, after the third blind
block showed the umask order was still wrong.

18b65ca8 made the write ignore SIGXFSZ, after the writer lock's session asked
about `ulimit -f 0`. The stamp already failed closed there: unchanged, with
"the grant does not hold" and `[!]`. But the signal ended the subshell
before its cleanup ran, which left an empty `autonomy.commission.new.*` (or
`setup/<id>.md.new.*`) in the project. Block 4 is red on a4d4d514 on exactly
that: three leftovers, and prepare's own status 153.

Re-checked on the review-fix engine:
- blocks 1, 2 and 3 pass 409/409 at f25bf26c, standalone and chained in suite
  order, and blocks 1 to 4 pass 428/428 chained at 18b65ca8;
- the 18 existing blocks touching adopt, new, doctor, setup and gate give the
  same verdicts as base;
- the reviewer's chained `felix new` block passes 48/48. The blocks that fail
  standalone fail identically on base, on variables earlier sections set
  (CMSTUB, CMSTUB_LOG, GREPO).

**Other reviews, from sibling sessions, taken:**
- the stamp's link and hard-link case, from the review of
  claude/autonomy-allow-fails-closed;
- the refusal's wording beside a `--revoke`, from the writer lock's review.
  It now says "no commission grant or stamp was written".
- the stamp under `ulimit -f 0`, from the writer lock's fourth review; see
  18b65ca8 above.

**Carrying.** Position 12 in the 2026-10-08 carrier queue
(~/.felix/memory/felix/audits/2026-10-08-carrier/state.md), after
claude/adopt-newline-before-append, which it is built on. Merge main once that
lands. The squash of 1 reads as different history, so take main's side on
every hunk that branch changed after ea68ed86, and keep only this branch's.

cmd_autonomy --allow sits beside the autonomy chain, now one PR on
claude/autonomy-writer-lock (revoke, --allow and the lock). That chain is ahead
in the queue, so this branch lands second and takes its shape, which its
session has checked:
- keep its guard, lock, `felix_autonomy_grant` and revoke as they are;
- do not reintroduce this branch's seed of `autonomy`;
- send every status line, `stamped` included, through `felix_autonomy_say`;
- put the stamp pre-check at the top of `if [ -n "$allow" ]`, before
  `if felix_autonomy_allows`;
- write the stamp the way the lock writes the grant. mktemp runs in a `$( )`
  that ignores `$FELIX_AUTONOMY_SIGNALS` and execs, and its name goes into
  `_FELIX_AUTONOMY_TMP` before the write. Then come `felix_replace_fill` and
  `felix_replace_commit`, `|| die`, and the variable is cleared after.

Then a signal between mktemp and the rename leaves no file, because the lock's
release removes it. Pin that at the merge with a mktemp shim that pauses, and
an INT to the group, as the lock's `_lwmkt` does. It cannot be written before
the lock is in the tree.

adopt's runbook has no trap to name its temp file to. A Ctrl-C between
prepare's mktemp and its return can leave an empty `setup/<id>.md.new.*`, with
no row written. This is left, and noted here.

For claude/suite-git-proof (3b), the four blocks add five fixture subshells
of the shape `( cd "$X" && <git write> )`: block 1 three, through `_pw_git`;
blocks 2 and 3 one each; block 4 none. They add no `git -C "$X" <write>`. Whoever lands
second converts them.

**At the record.** assertions.tsv grows by 428 from this branch (182 + 59 +
168 + 19), on top of the writer and readers branches'.
