# Contract: a git that cannot run is not a fact about the repository (rev 2, 2026-11-14)

**Scope.** How the engine's readers of a base (`felix_base_resolves`) and of the
gate receipt (`felix_verify_current`) tell a git that could not run apart from a
base that names nothing and from a tree that changed, and what each reader that
prints a reason says then. Also the one sentence `felix merge` prints before it
reaches either of them. Open, and not answered here: the other readers of git
failure (listed at the end), and whether `felix gate` itself is exposed.

## Why

On 2026-11-14 the App Store replaced Xcode during a full gate. Between the swap
and the licence being accepted, `/usr/bin/git` (Apple's shim, which runs
`xcrun`) exited 69 on every call. `felix next`, run with that git, printed "this
base names nothing here, so nothing was scanned" and "this tree has no green
gate receipt". Both were untrue: the ref and the receipt existed. The cause
write-up is `docs/handoff/pending/20261114T105408Z-LeavesJ-jolly-robinson-049cab.md`.

`felix_base_resolves` fails for any failure of `git rev-parse`, so a git that
never ran reads as a base that names nothing. The gate receipt's path is a hash
`git hash-object` computes (`_felix_receipt_path`), so with a git that cannot
run `felix_verify_current` finds no receipt and says `none`; and over a receipt
it does find, it reads an empty tree id as "the tree changed since the
receipt", whatever emptied it.

Words. *The clause* is the text GR1 defines. *Runs* means the first `git` on
`PATH`, in the environment the engine was given, the way every engine call
already runs it.

## GR1. Whether git runs, and the clause

Git **could not run** here when `git --version`, run as the engine runs git,
exits non-zero. Its exit status is N. The clause is exactly:

    git could not run here (git --version exited N)

Nothing else reads as git not running. A git that answers `--version` and then
refuses a command has run, and its refusal is read as before. The probe is made
only after a git call has already failed, so a git that works costs nothing.

## GR2. `felix_base_resolves ROOT BASE [VAR]`

- 0: BASE peels to a commit in ROOT, as today.
- 1: ROOT or BASE is empty, or git ran and BASE names nothing there. Exactly 1:
  today a base that names nothing gives git's own status, 128.
- 2: the lookup failed and git could not run (GR1). When VAR is given, the
  variable it names holds the clause. With any other status VAR is not set.

A caller that only asks "did it resolve" (`if`, `||`, `!`) reads 2 as it read 1.

## GR3. The rows that name an unresolved base

`felix_evidence_check`, `felix_escapes` and `felix_classify_diff` each print one
row and nothing else when BASE is non-empty and does not resolve, as today. When
the reason is GR2's 2, the row is

    unknown <TAB> GIT <TAB> <clause>, so the base <BASE> was not looked up and <tail>

where `<tail>` is the text that function's row already ends in:
- evidence: `no rule was consulted`
- escapes: `nothing was scanned; no channel was consulted`
- classify: `nothing was compared`

`GIT` is a pseudo-subject like `CHANGED-PATHS` and `ADDED-LINES`, so a reader
tells this row from a base that names nothing by kind and subject, never by the
reason's wording. When git runs and BASE names nothing, each row is
byte-for-byte what it is today.

## GR4. `felix_verify_current ROOT HOME PROJ [RECEIPT]`

When git could not run and the answer rests on it, it prints

    stale <TAB> <clause>, so this tree cannot be identified and no receipt can be confirmed for it

and returns 2. The answer rests on git in two places:
- **Finding the receipt.** With no fourth argument the receipt is read from a
  path git hashes. When that hash cannot be made and git could not run, this is
  the answer, whatever the file on disk holds: green, red or absent.
- **The tree id.** A green receipt (read from disk or handed in) over a tree
  whose id is empty because git could not run.

Read without git, and unchanged: a fourth argument that is empty (`none`) or not
green (`red`). With a git that runs, every answer is unchanged, status 1 for
each that is not `current`, including `stale <TAB> the tree changed since the
receipt` when the id is empty for another reason.

## GR5. The readers that print a reason

Each says the clause wherever it would have said the base names nothing, or that
the tree changed, and none of them says either of those then.

1. **`felix next`.** The GR4 answer is a rank-1 `felix` row whose text is the
   GR4 reason and whose action is `make git run here, then run this again`. The
   GR3 escapes row is a rank-1 `felix` row whose text holds the row's reason and
   whose action is the same. With a green receipt present, next prints neither
   "this tree has no green gate receipt" nor "names nothing".
2. **`felix evidence`.** It prints the GIT row as an unknown row, says nothing
   was compared, and in place of "Check --base" says
   `git could not run here; make it run, then run this again.` Exit 1, as for
   any unknown.
3. **`felix classify`.** After the unknown row, in place of the paragraph about
   a base this repository cannot resolve:
   `Nothing was compared. This is not a green change and not a risky one; git`
   `could not run here, and the unknown row above says how it exited. Make git`
   `run, then run this again.` Exit 1.
4. **`felix scope`** with no paths: `<clause>, so nothing was compared and no`
   `tier can be given. Make git run here, then scope it.` Exit 1.
5. **`felix pr`.** It stops with a message holding the clause and saying no pull
   request was opened, in place of "names nothing this repository holds".
6. **`felix status`.** The gate row is in state `unknown`, not a value (today
   it reads `value none-run`), with the GR4 reason as its detail.
7. **`felix merge`.** Where it cannot read which commit the base names and git
   could not run, it stops with a message holding the clause, in place of
   "Fetch the remote, or name a base that exists".

## GR6. The Stop hook

When the tree id is empty and git could not run, the hold names the clause and
does not give the usual cause of an unreadable tree (a named pipe, a socket, a
device). Its recorded detail stays `tree unknown`, and when it holds is
unchanged. This is reached when git stops running after the hook's own
`git rev-parse --git-dir` check: a git that refuses from the hook's first call
ends the hook there, holding nothing and saying nothing, as today (left open
below).

## GR7. Nothing else moves

With a git that runs, every output above is byte-for-byte what it is today. No
caller of `felix_base_resolves` that only tests success changes behaviour:
`felix_land_owed` still returns 2 and `felix_land_would_refuse` still writes
nothing when the base does not resolve, whichever the reason.

## GR8. The instruments

Two ways to make git refuse, both with no sudo:
- **Portable.** A directory first on `PATH` holding an executable `git` that
  prints the licence sentence to stderr and exits 69 (or any other non-zero
  status the test chooses). The fixture is built with the real git before the
  directory goes on `PATH`.
- **macOS.** Where `/usr/bin/git` is Apple's shim, `DEVELOPER_DIR` set to a
  directory whose `usr/bin/xcrun` prints "You have not agreed to the Xcode
  license agreements" and exits 69 makes `/usr/bin/git` exit 69. Elsewhere this
  is skipped, by name.

## Left open

- Other readers that read a git failure as a fact: the Stop hook allows a stop
  unchecked when its `git rev-parse --git-dir` check fails, which a git that
  cannot run makes it do; the receipt document leaves `tree` out of `unknown`
  and reads its verification as `none` when git cannot run (`receipt.sh`); the
  merge boundary hands `felix_verify_current` a receipt it read itself, so an
  unfound one reads `none` there (`escape.sh`); `felix next` under the exit-69 stand-in listed "upkeep due:
  graphify", which a working git did not (seen once, in this checkout, not
  traced); `felix_tree_id`'s other callers.
- A git that answers `--version` and fails every other call (a missing
  `git-core`) reads as before.
- A git that starts or stops running between the failed call and the probe is
  read by the probe.
- The 22 test files that narrow `PATH` to `/usr/bin:/bin` (the 2300 write-up).
- Whether `felix gate`'s own checks outside the suite are exposed.
