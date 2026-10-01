### 2026-10-01: a qualification row's scratch tree never outlives the row: its permissions come back before it is removed, and a row stopped by INT, TERM or HUP removes it on the way out

Rides in claude/qualify-rows-fresh-shell's PR, by its owner's and the queue
carrier's agreement, and is stacked on that branch. The engine change is in
lib/qualify.sh: three new helpers (`_felix_qualify_drop`,
`_felix_qualify_arm` and `_felix_qualify_errfile`), three changed lines in
`_felix_qualify_one`, and two in `_felix_qualify_sh`. Tests are one section
of tests/run, authored blind from a written contract that grew by the
adversarial review's findings.

**Defects closed.** Two ways the scratch worktree survived its row, both
measured 2026-09-25 on bash 3.2 and macOS, and measured again before this
change:
- A mutation that takes a write bit away (`mkdir -p d && touch d/f && chmod
  a-w d`) beat `git worktree remove --force`, so the `rmdir` after it failed
  and the checkout stayed in TMPDIR. On git 2.54 the failed remove drops the
  registration and leaves the directory. A retry then says "not a working
  tree", so only restoring the bits *before* the first remove helps.
- Nothing trapped INT, TERM or HUP. A row stopped mid-column died where it
  stood, with its tree on disk and registered. Three such trees were in the
  home checkout's worktree list (…/T/tmp.0babp7IssN/w, tmp.nPNMWAEHUR/w,
  tmp.wBGa0w3UjL/w, about 01:20 on 2026-09-25). They were gone, both
  directory and registration, when this session checked on 2026-10-01, so
  nothing was removed by hand.

**Decided, not left.**
- **The traps sit in the row's own process, not in cmd_qualify or the row
  loop.** A caller's trap is deferred until the `$(...)` it waits on returns.
  Measured: a TERM trap on the caller ran six seconds late, after the row had
  finished, so it could never stop a row in flight. The row's process is in
  the group that Ctrl-C, timeout and a tool's kill all signal, and it carries
  the CLI's command line, so a pattern kill reaches it too.
- **Directory bits only, then the remove, then the base removed whole.**
  The first draft ran `chmod -R u+rwX` over the base. Adversarial review
  showed it changing modes outside the base through hard links: a mutation
  `git clone -q . sub` hard-links the root's object files, and they went
  from 0444 to 0644. The drop now runs `find "$base" -type d ! -perm -0700
  -exec chmod u+rwx {} \;`, one directory at a time from the top, so a 000
  directory is opened before find reads it. Deleting a file needs the bits
  on its directory, not on the file itself, and no user can hard-link a
  directory.
- **A swapped tree or base is unlinked, never followed.** Review showed
  `git worktree remove` resolving a `$base/w` the mutation had replaced with
  a symlink to another worktree of the root. It deleted that worktree,
  uncommitted file and all, and printed nothing. That was true of b75e80ff
  too. A missing base is made again so `$base/w` resolves to the registered
  path. `-f -f` removes a tree the mutation locked. A remove git refuses
  (the tree's `.git` gone) is retried once the directory is gone, since git
  drops a registration whose directory is missing.
- **Each column's stderr file is made new before the column runs**
  (`_felix_qualify_errfile`, in qualify-rows' `_felix_qualify_sh`, which
  that branch's owner agreed to). Review found that `chmod -R a-w ..` made
  the redirection fail. The column then never ran and returned 1, so the
  command read `fail`, `met` on a fail control with no checker run. It also
  found that a planted `../err` symlink sent the next column's stderr into
  a file outside the base. Both were true of b75e80ff. A file that cannot be
  made new, plain and empty now reads as a column that ran nothing.
- **A stopped row prints `unrunnable` before it exits 128+N**, with PIPE
  ignored for that one write. A row loop that the signal did not reach is
  still reading, and a row that printed nothing was counted `held`: a claim
  about a checker that never finished.
- **What is left is said on stderr, judged from what is there rather than
  from an exit status.** That means the base still on disk, or this row's
  entry still in `git worktree list`. The first draft spoke on git's status,
  which gave false alarms (a group signal during the add, a tree past
  PATH_MAX) and the wrong advice for a locked entry. No repo-wide prune is
  run: other sessions' stale entries are not Felix's to remove.

**Not reached, and said so in the code.**
- SIGKILL. Filed as a task: a later run sweeps trees whose run is dead.
- A signal sent to the CLI's process alone. The row it leaves runs to its
  end and removes its tree there, as rows always have.
- A signal to the row's process alone waits for the column in flight to end
  before the trap runs.
- A process a mutation leaves running, which can write into the base after
  the drop has removed it.

**Traps paid:**
- The tool shell is zsh. `for c in "TERM group"` passes one word, and
  `$t:engine/...` is a modifier. Smoke scripts go in files run by /bin/bash.
- `git commit --amend` trips the fact-forcing gate. Add a commit instead.
- `claude/engine-mktemp-tmpdir` already conflicts with qualify-rows at the
  `local`/`scratch=` lines. This branch puts the `_felix_qualify_arm` call
  right after them, inside the same conflict block. Resolution: qualify-rows'
  `local ... err got rc` and `scratch=...; err=...` lines, the mktemp
  branch's `felix-qualify.XXXXXX` template, then the arm call and its
  two-line comment.
