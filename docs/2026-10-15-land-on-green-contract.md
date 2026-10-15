# Land on green: contract, 2026-10-15

## Why

CI went green on #433, #435, #438 and #439, and nothing merged until the founder
asked. #438 passed at 23:05Z on 10-14 and merged at 00:59Z. #439 passed at 04:35Z
on 10-15 and merged at 21:02Z, 16.5 hours later. Both author sessions were alive.
The desktop app wakes a session on a CI failure, a conflict or a comment, and
never on a pass. A session may not poll CI. So a green pull request waits for
whoever looks next, and that has been the founder.

The founder decided on 2026-10-15 at about 01:00Z: "Felix lands them, built
next". A scheduled job of Felix's own watches the project's open pull requests.
When CI is green it runs `felix merge`, with every check `felix merge` makes. He
added that it goes on whichever Mac Felix runs on, and that it may later be an
on/off setting in the interface.

## What it is, and what it is not

It is not the landing actor of the 2026-09-24 design. The actor integrates main,
writes the version and test records at landing, gates the merged result and
lands from a clone of its own. This job does none of that.

It runs the one command a session would have run, `felix merge`, in the checkout
the session would have run it in, at the moment no session was woken for. Every
judgement stays where it is today:

- the author's gate wrote the receipt, in the author's checkout;
- CI judged the head;
- `felix merge` judges escapes, commission tables, the receipt, rule C9 and
  staleness, with main's installed engine.

A pull request `felix merge` refuses stays with its session, as today.

**One departure from the design, decided.** Design §5 says a change to the code
that judges never lands with nobody present. That rule protects an actor that
re-gates in its own clone, where the candidate's code would judge itself. Here
nothing is re-gated. A judge-changing pull request lands on exactly the evidence
a session's merge on green uses today, so holding it would add no check and
would only bring the wait back. What a present session adds is noticing a broken
deploy, and G6's verify and pause cover that.

## The clauses

**G1. Where it lives.**

- **Code.** `lib/green-tick.sh` holds the tick. It sits outside the `lib/land*.sh`
  trust-base glob and stays under 500 lines.
- **Command.** `felix land` dispatches to it. It resolves its project the way
  every `felix` command does, from the working directory. The trampoline
  changes into `$FELIX_HOME_DIR` before it runs.
- **State.** The job's state lives in `$(felix_mem_dir <project>)/land/`:
    - `ledger.tsv`, append-only;
    - `paused`, whose content is the reason;
    - `lock/`, a directory holding `pid` and `started`.
- **Seams for tests.** Every outside command is called by name through `PATH`:
  `gh`, `git`, `pgrep`, `osascript`, `launchctl`. The home checkout is
  `$FELIX_HOME_DIR`. The plugin cache is `${FELIX_PLUGIN_CACHE:-$HOME/.claude/plugins/cache}`,
  the same root `felix merge` composes its judge path from.

**G2. Preflight.** `felix land --tick` exits 0 and does nothing else unless all of
these hold:

- **Not paused.** If `land/paused` exists, the tick exits 0. It writes one
  `paused` ledger row when the newest `paused` row is older than an hour, or there
  is none, and otherwise writes nothing.
- **The lock is free or dead.**
    - It is free when `lock/` does not exist.
    - It is held by a live tick when its `pid` is alive (`kill -0`) and its
      `started` line matches that process's start time. The tick then exits 0
      with no row.
    - Any other held lock is dead, and the tick takes it. A `pid` that is alive
      but names a different process, by start time, is a dead lock.
    - The lock is taken with `mkdir`, and released on every exit path through a
      trap.
- **`gh auth status` exits 0.** If it does not, the tick writes one `gh` row and
  exits 0. A `gh` that fails never reads as a green run, anywhere in the tick.

**G3. Deploy what main already holds.** Before any merge, the tick compares the
version `origin/main` declares (`engine/.claude-plugin/plugin.json`, read with
`git -C "$FELIX_HOME_DIR" show origin/main:...` after a `git fetch`) with the
installed cache entry for that version. If that entry is missing, or `diff -rq`
finds it differs from `origin/main`'s `engine/harness`, a deploy is owed, and G6
runs before anything else. While a deploy is owed and not completed, the tick
merges nothing, because `felix merge` would refuse every candidate for want of an
installed judge.

**G4. Candidates.** One call:

```
gh pr list --state open --json number,headRefName,headRefOid,isDraft,labels,mergeable,isCrossRepository
```

A pull request is a candidate only when all of these hold:

- `isDraft` is false;
- no label is `felix:hold`;
- `isCrossRepository` is false;
- `mergeable` is not `CONFLICTING`;
- `_felix_merge_gate_held <project-dir> <worktree> <headRefOid>` returns 0. That
  is rule C9's own function in `lib/escape.sh`, so the job and the merge
  boundary cannot disagree about what a passed gate run is. The newest run on
  the head counts, and anything unreadable is not a pass.

Candidates are taken in ascending PR number. A pull request that fails a check
gets a `skip` row naming the check. The row is written only when it differs
from that pull request's previous row, so a waiting pull request does not
write a row every five minutes.

**G5. Direction documents and the checkout.**

- **Direction documents.** For each candidate, the tick reads
  `gh pr view <n> --json files`. If any path matches `projects/*/CLAUDE.md` or
  `docs/*roadmap*`, the tick skips it with a `founder` row: those merge on the
  founder's yes. The two patterns are an engine constant and name no project.
- **The checkout.** The tick reads `git -C "$FELIX_HOME_DIR" worktree list
  --porcelain` and looks for a worktree whose branch is `refs/heads/<headRefName>`
  and whose HEAD is `headRefOid`.
    - If none matches, the tick writes a `session` row reading "no checkout
      holds the gated head".
    - The tick never checks out, fetches into, resets, cleans or writes to any
      worktree.

**G6. Merge.** The merge runs only through the installed engine's `felix`:

```
<cache>/felix/felix/<origin/main's version>/harness/felix merge
```

- **How it is called.**
    - It runs with the matched worktree as its working directory and with no
      arguments.
    - Its environment has `FELIX_ALLOW_RED`, `FELIX_KERNEL` and
      `FELIX_KERNEL_CACHE` unset, whatever the caller set.
    - The tick never runs any worktree's `engine/harness/felix`, never passes
      `--base`, and never writes a label, pushes or comments.
- **Outcomes.**
    - Exit 0 writes a `landed` row.
    - Anything else writes a `refused` row whose detail is the first line of its
      output that begins with two spaces (a blocker line), or else its last
      line. The tick then moves on to the next candidate.
    - The first `landed` ends the candidate loop: one landing per tick.

**G7. Deploy.** Deploy runs after a landing whose changed paths include
`engine/`, and whenever G3 finds one owed.

1. **A gate is running.** If `pgrep -f` finds a process whose command line
   contains `/engine/harness/tests/run` or `/gate.sh`, the tick writes a
   `deploy-owed` row ("a gate or suite is running") and exits 0. The next tick
   tries again. Nothing is ever signalled.
2. **The home is not ready.** If `$FELIX_HOME_DIR` is not on branch `main`, or
   `git status --porcelain` shows a tracked change, the tick writes a
   `deploy-owed` row with the reason, writes `paused` with the same reason, and
   exits 0.
3. **Install.** The tick runs `git -C "$FELIX_HOME_DIR" pull --ff-only`, then
   the home's `engine/harness/felix install --no-bump`, from the home. The
   home's engine is main's, because main has just been verified.
4. **Verify.** All three of these must hold:
    - `diff -rq` of the cache entry for the new version against
      `$FELIX_HOME_DIR/engine/harness` is empty;
    - the home's `engine/harness/hooks/session-start`, given a stub payload
      `{"session_id":"felix-land-verify","source":"startup","cwd":"$FELIX_HOME_DIR"}`
      on stdin, exits 0;
    - `felix gate --quick`, run in the home, exits 0.

   If they hold, the tick writes a `deployed` row. If any fails, it writes a
   `deployed-unverified` row naming the check, and writes `paused` with the same
   reason. Nothing is rolled back; that is roadmap step 12.

**G8. Say it.**

- Every `landed`, `refused`, `founder`, `deployed`, `deployed-unverified`
  and `paused` row is also sent as one
  `osascript -e 'display notification "<detail>" with title "Felix: <event> #<n>"'`.
- A failing `osascript` is ignored, and the ledger row has already been
  written. The ledger is the record.
- The ledger's columns are, tab-separated: UTC time, event, PR number (`-` when
  none), head SHA (`-`), worktree path (`-`), wall seconds, detail. Tabs and
  newlines in the detail become spaces.

**G9. Commands.** `felix land` takes exactly one of:

- `--tick`;
- `--pause [reason]`, which writes `paused`, with "paused by hand" when no
  reason is given;
- `--resume`, which removes `paused`;
- `--install`, which writes a static trampoline, the plist, and bootstraps the
  plist. Details:
    - The trampoline is `~/Library/Application Support/felix/land/<p>/tick`. It
      runs the installed engine's `felix land --tick` for the project, resolving
      main's version at run time, so it never runs a working tree.
    - The plist is `~/Library/LaunchAgents/felix.land.<p>.plist`, with label
      `felix.land.<p>`, `StartInterval` 300, `RunAtLoad` true and `ProcessType`
      `Interactive`. It sets no `LowPriorityIO`, an explicit
      `PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin`, and
      `EnvironmentVariables` naming `FELIX_HOME_DIR`. Its stdout and stderr go
      to `land/launchd.log`.
    - The tick bootstraps it with `launchctl bootstrap gui/<uid> <plist>`.
- `--uninstall`, which runs `launchctl bootout gui/<uid>/felix.land.<p>` and
  removes the plist and the trampoline. A missing one is not an error;
- `--status [--tsv]`, which is read-only. It prints three lines, `installed`,
  `loaded` and `paused`, each `yes` or `no`, then the last ledger row of each
  pull request seen. With `--tsv` the lines are `key<TAB>value` and the rows are
  the ledger's own.

Any other argument, or none, prints usage and exits 2. Installing is persistent
configuration, so a session runs `--install` only on the founder's yes in chat.
Those four commands are the whole backend of a future interface toggle.

## Not in this

- Integration, re-gating, version and record bookkeeping, the clone, the arming
  streak, shadow runs, rollback and the stuck-PR page. They are the roadmap's
  Phase 0b steps.
- Waking on a sleeping Mac. launchd fires a missed interval on wake.
- Other projects. The job is installed per project. It is installed and
  measured here on felix-home first.
