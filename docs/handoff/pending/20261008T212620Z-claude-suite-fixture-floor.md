### 2026-10-08: no fixture git command in tests/run can reach a repository outside $TMP

**Incident.** At 12:47 local (19:47Z) on 2026-10-08 felix-home's shared
.git/config lost its origin. It read `https://github.com/acme/widget.git`,
packed-refs held no refs/remotes/origin, and every `branch.*.remote` was gone.
Every worktree's fetch and push failed until the founder restored the origin.

**Cause, measured.** A section runner (one session's scratch runblock.sh)
took tests/run's preamble and the setup block, but not the `_fh_proj` and
`_fh_root` helpers the block calls. So `$TMP/fr-setupwait` was never made,
and `_fs_wr` and `_fs_lr` came back empty. In bash 3.2, `( cd "" && git ... )`
exits 0 where it stands. The runner stood in its worktree, and every worktree
shares one config. The setup block's sixteen remote-editing lines then ran
against felix-home:
- `set-url` to gitlab, then to the shell-text URL;
- `remote remove origin`, which rewrote packed-refs at 12:47:15;
- `add` and `remove` of upstream;
- `add origin https://github.com/acme/widget.git`, which wrote the config at
  12:47:41.

Root-caused from that session's transcript by the session "Stop tests/run
rewriting the real checkout's remote". It found a second path into the same
lines: under load, a fork that fails inside `$(_fh_root ...)` leaves an empty
root, and the suite, which does not check that assignment's status, carries
on.

Reproduced in a scratch clone with a linked worktree. main's own sixteen
lines, extracted from tests/run and run with both roots empty, leave
origin=acme/widget, 0 origin refs (was 376) and 0 upstreams (was 4).

**Fix: the class, not the lines.** Right after `$TMP` is made, the preamble
calls `_fixture_floor "$TMP"`. It:
- stands the suite in `$TMP/cwd`, so an empty root resolves inside `$TMP`;
- exports `GIT_CEILING_DIRECTORIES` as `$TMP`'s **parent**;
- unsets the GIT_DIR family and OLDPWD;
- refuses to start if git still finds a repository from there.

Section runners take lines 1 to the `resolution` header, so they inherit it.

Two things that look sufficient and are not, both measured in scratch clones:
- **A ceiling alone does nothing.** With the suite left in the worktree, the
  same sixteen lines did the full damage, because the worktree is not below
  any ceiling under `$TMP`.
- **A ceiling at `$TMP` itself leaks.** A ceiling is a directory git will not
  climb into, so a cwd of exactly `$TMP`, which `cd "$TMP/$empty"` reaches,
  still climbs out. With `$TMP` inside a checkout,
  `git rev-parse --show-toplevel` from there printed the checkout.

**The ceiling binds git, not Felix.** `felix_repo_root` climbs the physical
path for a `.git` by itself, so a fixture that runs the CLI from an empty root
would reach any checkout enclosing `$TMP`, past the ceiling. Found by the
adversarial review. The preamble now does that same walk, fork-free, from
where it stands, and refuses to start if any directory at or above `$TMP`
holds a `.git`. On macOS `mktemp -d` ignores TMPDIR and nothing above
/private/var/folders is a checkout. Elsewhere, a TMPDIR inside a checkout now
stops the suite with a message saying so.

**What the second review caught.** One finding was critical, and this
branch had introduced it. Normalising a relative `$TMP` turned an empty one
into `$PWD/`, so a `mktemp -d` that printed nothing (a failed inner fork under
load) set the exit trap to remove the directory the suite was started from.
main was safe here only because removing an empty name does nothing. The
suite now stops before the trap exists. The floor also takes git's own words,
not its status, since git exits 128 for a repository it refuses to open as
well.

**Assertions.** The section `fixture floor` is now the suite's first section,
and one more assertion sits just before the `reached` marker.
- 55 of them were written blind, from a contract and origin/main alone, by an
  agent that never saw the implementation. They cover:
  - where the suite stands;
  - an empty root from the suite's shell;
  - four fixture shapes inside a stand-in checkout: an empty variable, a cwd
    of DIR itself, a directory `git init` never reached, and an inherited
    GIT_DIR;
  - the floor's refusals;
  - the end-of-suite check.
- Eight more cover what two adversarial reviews found:
  - GIT_CONFIG;
  - the walk, twice, and once more with the directory gone from under it;
  - the preamble refusing a `$TMP` inside a checkout, run as a child;
  - an empty `mktemp -d` stopping the suite with nothing removed, also run
    as a child;
  - a git that cannot run;
  - a `.git` git cannot open, where it exits 128 all the same.

Every mutating probe first asks git which repository it would touch, and runs
only inside `$TMP`.

Each mutant was run on the section runner, from a linked worktree of a
scratch clone, whose config was unchanged after every run:

| tree | floor section (63) |
|---|---|
| this branch | 63 passed |
| M0 no floor at all, run from the worktree | 50 failed |
| M1 ceiling = $TMP, not its parent | 13 failed |
| M2 no ceiling | 37 failed |
| M3 no cd | the suite refuses to start |
| M4 GIT_DIR kept | 10 failed |
| M5 an empty or missing DIR not refused | 4 failed |
| M6 GIT_CONFIG kept | 1 failed |
| M7 the preamble ignores the walk | 1 failed |
| M8 the walk never finds a checkout | 3 failed |
| M9 git's status 128 read as no repository | 1 failed |
| M10 an empty `mktemp -d` not stopped | 1 failed |
| M11 an empty PWD read as / by the walk | 1 failed |

**Limits, said plainly.**
- The floor covers fixtures that name their repository by the directory they
  stand in. A root with a suffix, `cd "$empty/x"`, lands at /x.
- The end-of-suite check reads where the suite ends up, so a top-level
  `cd "$X"; ...; cd "$TMP/cwd"` passes it.
- Section runners never reach the `reached` marker, though they do inherit
  the floor.
- tests/red, which `--record-assertions` runs, still adds and removes worktrees
  of the real checkout on purpose. It is not a fixture.

**Section runners.** The first `printf '\n` header is now `fixture floor`,
not `resolution`.
- A runner cut at the first header gets the floor, but not its assertions.
- A runner cut before `resolution` gets both, which is about 60 assertions
  and a few seconds.

**State after the restore, read at 13:25 local.** Origin is
`https://github.com/LeavesJ/felix-home.git`, with 222 origin refs. Every
local branch that has a same-name origin ref has its upstream again. 179 of
the 375 local branches have no origin counterpart and no upstream. Which of
those had one before 12:47 is not recoverable from the config.
