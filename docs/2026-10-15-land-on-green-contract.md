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

## Amended after review, 2026-10-15

Two Opus reviews and an automated security review of the first build found
gaps this contract left open. These amendments bind, and where one differs
from a clause above, the amendment wins.

- **A1 (G9, the trampoline runs only main's accepted engine).** The
  trampoline reads the version `origin/main` declares, without a fetch. It runs
  that cache entry's `felix land --tick` only when main's own acceptance check
  says the entry is main's engine. The check is `felix_accepted_deploy_diff`,
  read out of `origin/main`'s `engine/harness/lib/resolve.sh` with
  `git show` and sourced in a subshell, as `cmd_merge` does for its judge.
    - In every other case it runs nothing: the version is unreadable, the
      entry is missing, the entry is not executable, the check cannot be
      loaded, or the check says the entry differs. It then writes one
      `deploy-owed` row naming which case it was, deduplicated against the
      ledger's last row, sends one notification, and exits 1.
    - It never runs the newest cache entry, another version, or any working
      tree. A cache entry at main's version number that a branch installed is
      not main's engine, and this check is what tells the two apart.
- **A2 (G3, a home behind main owes a deploy).** A deploy is owed also when
  `$FELIX_HOME_DIR`'s HEAD is not `origin/main` after the fetch. That covers a
  landing whose cache entry the author's gate had already installed: the home
  is still behind and nothing verified the deploy. G7 then requires HEAD to
  equal `origin/main` after the pull, before anything is installed. A home
  ahead of or diverged from `origin/main` is a `deploy-owed` row plus `paused`,
  and nothing is installed.
- **A3 (G5, direction documents, matched without case and across renames).**
  Paths are compared after folding A-Z to a-z under `LC_ALL=C`, because this
  Mac's file system folds case: `projects/felix/claude.md` is the founder's
  `CLAUDE.md` once it is checked out.
    - A rename counts under both its old path and its new one.
    - A list that cannot be read is not an empty list: the pull request is
      skipped, with a row saying the files could not be read.
- **A4 (G2, the tick is bounded and a stuck lane is said).**
    - **Fetch and pull.** `git fetch` and `git pull` run with
      `GIT_TERMINAL_PROMPT=0`, `GIT_HTTP_LOW_SPEED_LIMIT=1000` and
      `GIT_HTTP_LOW_SPEED_TIME=60`.
    - **A watchdog.** The tick runs under a watchdog. After 30 minutes it sends
      TERM to the tick's own process group, and the tick's trap writes a
      `timeout` row, sends a notification and releases the lock.
    - **A stuck lock.** A tick that finds a live lock older than 45 minutes
      writes one `stuck` row and one notification, and does not take the lock
      or signal its holder.
- **A5 (G2, the lock is taken atomically).** The lock's `pid` and `started`
  are written into a fresh directory, which is then renamed to `lock/`. A dead
  lock is first renamed aside to a unique name, and only the tick whose rename
  succeeds goes on to take it. No tick reads a half-written lock as dead.
- **A6 (G4-G6, rows for a waiting pull request).** `skip`, `session`,
  `founder` and `refused` rows, and their notifications, are written only when
  the event, head or detail differs from that pull request's previous row.
- **A7 (G9, arguments).** `--pause` takes at most one reason. More arguments
  print usage and exit 2.

## Amended after the second review, 2026-10-15

- **A8 (the remote branch by its full name).** Every read of main in the job
  names `refs/remotes/origin/main`, never the short `origin/main`. That covers
  the trampoline, the version read, the acceptance check, the owed-deploy
  check, the home's HEAD comparison and the deploy. Git resolves a tag or local
  branch named `origin/main` first, and every worktree shares those refs. A tag
  or branch with that name changes nothing the job does. `felix merge`'s own
  `felix_base_ref` has the same weakness, and it is a separate queue item.
- **A9 (paths outside plain ASCII wait for a person).** The file system folds
  Unicode case as well as A-Z, so `projectſ/felix/CLAUDE.md` is the founder's
  file once it is checked out.
    - A pull request any of whose changed paths, old or new, holds a byte
      outside printable ASCII gets a `founder` row and is not merged.
    - Paths are read from `git diff -z --no-renames --name-only`, so git's
      quoting never hides a byte.
- **A10 (nothing stops silently).** Each of these writes a row and sends a
  notification:
    - the trampoline unable to enter `$FELIX_HOME_DIR`;
    - the tick unable to resolve its project;
    - `gh auth status` failing;
    - a fetch failing;
    - a deploy owed.

  The ledger path is written into the trampoline, so it does not depend on the
  home. Each of these rows, like A6's, is written and notified only when it
  differs from the previous row of the same event.
- **A11 (a tick that deploys does not merge).** A tick that runs G7's deploy,
  whether it succeeds or not, merges nothing in that tick. The next tick merges
  with the engine just deployed, and that engine runs it.
- **A12 (only pull requests into main).** A candidate's `baseRefName` must be
  `main`. A pull request into any other branch gets a `skip` row.
- **A13 (`felix merge` is not re-run on a known refusal).** A pull request
  whose newest row is `refused` is passed to `felix merge` again only when its
  head or `refs/remotes/origin/main` has moved since that row. The row records
  both. Every real `felix merge` run writes says.log rows, and re-running a
  refused one every five minutes would inflate the founder-interruption count.
- **A14 (seeing a running suite, and failing closed).**
    - G7.1's process check matches `engine/harness/tests/run` with or without a
      leading slash, since `tests/red` starts it relatively, and `gate.sh`.
    - A `pgrep` that exits with anything but 0 or 1 counts as "a suite is
      running".
- **A15 (signal only what it still owns).**
    - The watchdog compares its tick's start time before it signals, and stops
      without signalling if the pid now names another process.
    - The lock takeover compares the pid it judged dead with the pid it moved
      aside.
- **A16 (the job's PATH).** The plist's `PATH` is
  `$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin`,
  with `$HOME` expanded when it is written. `claude`, which `felix install`
  needs, lives in `~/.local/bin`.

## Amended after the final review, 2026-10-15

- **A17 (the acceptance check judges the full ref).**
    - **The defect.** `felix_accepted_deploy_diff` resolves its base through
      `felix_base_ref`, which puts `origin/` in front of whatever it is given.
      Passed `refs/remotes/origin/main`, it judged
      `origin/refs/remotes/origin/main` first, and any session can create that
      name.
    - **The fix.** `felix_base_ref` returns a base that already begins with
      `refs/` as it is, when it resolves to a commit, and tries nothing else.
      Every existing caller passes a short name, so none of them changes.
    - **What is asserted.** A tag or branch named
      `origin/refs/remotes/origin/main` changes nothing the trampoline or the
      tick does. The short-name weakness in the other callers stays its own
      queue item.
- **A18 (every ledger column is cleaned).** Tabs and newlines become spaces in
  every column, not only the detail. A worktree whose path holds a tab or a
  newline is never used: its pull request gets a `session` row.
- **A19 (one pull request per head branch).** `felix merge` picks its pull
  request by branch name. A candidate whose `headRefName` is also the head of
  another open pull request gets a `skip` row.
- **A20 (an unfinished verify owes a deploy).** The deploy writes
  `land/verifying` before its verify starts, and removes it only when it writes
  `deployed`. A tick that finds `land/verifying` treats the deploy as owed, so
  a verify cut off by the watchdog, a logout or a reboot is run again before
  anything merges.
- **A21 (the verify compares against main, not the home's files).** G7.4's
  first check is `felix_accepted_deploy_diff "$FELIX_HOME_DIR"
  refs/remotes/origin/main` returning 0, not a `diff -rq` against the home's
  working tree. An untracked file in the home's `engine/` then cannot pass as
  main's engine.
- **A22 (an unresolved project leaves a row).** The trampoline exports the
  ledger path it carries as `FELIX_LAND_LEDGER`. A tick that cannot resolve its
  project writes its row there, deduplicated as in A10, and notifies. The tick
  reads that variable only in this case.

## Amended after the fourth review, 2026-10-15

**What the guards are for.** Every session on this Mac holds the founder's
GitHub token. A hostile session can therefore merge directly, and this job gives
it nothing it lacks. Like the rest of Felix's floor, these guards stop a
careless session or a damaged checkout, not a hostile one. Where a check is
cheap and closes a case a careless session could create, it is in. Hostile-only
cases are recorded and are not chased further.

- **A23 (the checkout is the one the pull request names).**
    - `git worktree list --porcelain -z` is read one NUL-ended field at a time
      (`read -r -d ''`), and a record ends at its empty field. No byte inside a
      field is ever used as a separator.
    - The tick then asks the chosen directory itself. It must report all of
      these, or the pull request gets a `session` row:
        - `git symbolic-ref HEAD` equal to `refs/heads/<headRefName>`;
        - `git rev-parse HEAD` equal to `headRefOid`;
        - a `git rev-parse --git-common-dir` that names the home's own `.git`.
- **A24 (the home is main, byte for byte, before any of its code runs).**
  Before the deploy runs anything from the home (`felix install`,
  `session-start`, `felix gate --quick`), all three of these must hold for
  `engine/` and `projects/<p>/`:
    - every tracked path hashes, with `git hash-object` over the working-tree
      file and not through `git status`, to the blob
      `refs/remotes/origin/main` holds;
    - no index entry carries assume-unchanged or skip-worktree (`git ls-files
      -v`);
    - no untracked or ignored file exists under `engine/` (`git ls-files
      --others` with no exclude rules).

  If any of them fails, the deploy writes a `deploy-owed` row naming the path,
  writes `paused`, and runs nothing. The trampoline applies the third check to
  `engine/` before its A1 check, so an untracked `.gitignore` there cannot
  widen what that check calls residue.
- **A25 (the watchdog signals the tick first).** It sends TERM to the tick's
  pid first, and only then to the tick's descendants. It never signals its own
  pid or its own process group.

## Amended after the fifth review, 2026-10-15

- **A26 (the owed marker comes first).** The deploy writes `land/verifying`
  before its `git pull` and before A24's checks, not just before the install.
  A deploy that A24 stops is still owed after `--resume`, so the next tick
  re-runs the whole deploy before anything merges. The marker is removed only
  when `deployed` is written.
- **A27 (byte-exact hashing).** A24's hash is `git hash-object --no-filters
  --stdin-paths`, so `core.autocrlf` and attributes cannot make different bytes
  hash to main's blob.
- **A28 (scope and seams).**
    - A24's third check (no untracked or ignored file) covers `engine/` only.
      Its first two cover `engine/` and `projects/<p>/`.
    - `_GT_WDSECS`, the watchdog's bound in seconds, defaults to 1800. A test
      may set it after sourcing the library, and nothing else sets it.
    - Every `sed`, `sort`, `cut` and `awk` in the job runs under `LC_ALL=C`.

## Amended after the record of 2026-10-16

- **A29 (main's engine is read whole, on every run).** Every tick, and every
  verify, asks `felix_accepted_deploy_diff`. It used to read main's engine
  through `git archive | tar -x` under felix's `pipefail`. bsdtar stops reading
  at the end-of-archive marker. If `git archive` is still writing its trailing
  padding at that moment, it dies of SIGPIPE, and the check answered "cannot
  examine" for an entry that is main's. Measured on a fixture-sized engine, ten
  loops at once: 192 of 1,500 runs. A tick then deploys instead of merging, and
  a verify writes `deployed-unverified` and pauses the lane.
    - For an entry that is main's, `felix_accepted_deploy_diff` exits 0 however
      late `git archive` writes bytes after the end-of-archive marker, and
      however early the reader of the archive stops.
    - It still exits 2 when `git archive` itself fails, and 1 when the entry
      differs. A reader that stops early never turns a failure into a pass.

## Amended before install, 2026-10-16

- **A30 (the founder's labels hold, as felix:hold does).** A founder-only pull
  request is marked as a draft and labelled `needs-founder`. `felix inventory`
  already reads both `needs-founder` and `felix:founder` as the founder's. The
  tick held only `felix:hold`, so the label half of that hold did nothing.
  GitHub will not merge a draft, so the founder runs `gh pr ready` and then
  `gh pr merge`, and a live tick between the two would hand the pull request
  to `felix merge`. That merge does not reliably refuse it: an escape table
  that only gains rows passes, and new escape rows are not applied to their
  own pull request. Found asking whether the job could merge the 7-11b escape
  batch, before it was installed.
    - A pull request carrying a label named `felix:hold`, `felix:founder` or
      `needs-founder` gets one `skip` row and is never handed to `felix
      merge`, whatever its gate run says. Names match without regard to case,
      as GitHub's do.
    - The skip row's detail names the label as the pull request carries it.
    - A label whose name only contains one of these, such as
      `not-needs-founder`, holds nothing.

## Amended after install, 2026-10-18

- **A31 (the job runs where macOS lets it read the home).** The job was
  installed on felix-home at 0.49.295, and its first tick looked at nothing.
  macOS's privacy control refuses a launchd job every read under `~/Documents`
  unless the program launchd started has been given Full Disk Access. The
  trampoline began `#!/bin/sh`, and `/bin/sh` has no such grant. Its `cd` into
  the home succeeded, because entering a directory is not a read, so A10's row
  for an unenterable home never fired. The tick then could not read `.felix`
  ("Operation not permitted") and wrote an `unresolved` row. The founder gave
  `/bin/bash` Full Disk Access on 2026-10-02, for the pulse job. Two transient
  launchd jobs measured the difference on 2026-10-18: under `/bin/sh` neither
  `.felix` nor `git` could read the home, and under `/bin/bash` both could.
    - **The program.** The plist's `ProgramArguments` are `/bin/bash`, then the
      trampoline's path. The trampoline's first line is `#!/bin/bash`.
    - **A read, not an entry.** After it enters `$FELIX_HOME_DIR`, and before
      anything else, the trampoline opens the home's
      `engine/.claude-plugin/plugin.json` for reading. Opening a file is what
      the privacy control refuses, and the file is tracked in every Felix home.
      A permission test (`[ -r ]`) is not enough: it passes where the open is
      refused.
    - **What it writes.** When that open fails, the trampoline writes one row of
      kind `unreadable` whose detail names `$FELIX_HOME_DIR` and says that
      macOS may be refusing the read, and that `/bin/bash` needs Full Disk
      Access (System Settings > Privacy & Security > Full Disk Access). It sends
      a notification titled `Felix: unreadable` and exits 1. It runs no engine.
      The row and the notification are written only when they differ from the
      previous row, as A10's are.
    - **The status says so.** `--status` prints a fourth line after `paused`:
      `last`, then the ledger's newest row of any kind, or `none` when the
      ledger has no row. Plain, the line shows that row's time, kind and
      detail. With `--tsv` it is `last`, a tab, then the row as the ledger has
      it, or `none`. The rows of each pull request seen follow it, as before.
      An install whose job cannot run therefore shows it at the next status,
      without anyone reading the ledger.

## Not in this

- Integration, re-gating, version and record bookkeeping, the clone, the arming
  streak, shadow runs, rollback and the stuck-PR page. They are the roadmap's
  Phase 0b steps.
- Waking on a sleeping Mac. launchd fires a missed interval on wake.
- Other projects. The job is installed per project. It is installed and
  measured here on felix-home first.
