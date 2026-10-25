# Audit b13: felix CLI trust and binding, the contract

Batch 13 of the 2026-10-24 audit register: C067, C063, C116, C117 and C064. The skeptics'
corrections are followed. Everything below was read on `origin/main` at 69b51a61. This file is the
whole specification the blind assertions are written from. It says what must be true, not how,
except where a constraint names a how.

Terms used throughout:

- **Self-governed checkout**: a git checkout whose index tracks `engine/.claude-plugin/plugin.json`.
  Anything else is a **governed product**.
- **M**: the commit `felix merge` resolves its base to (`--base B`, default `main`, as a full ref
  name, as today). **V**: the version M's `engine/.claude-plugin/plugin.json` declares.
- **The entry**: `<cache>/<V>`. `<cache>` is `$FELIX_KERNEL_CACHE` when set, else
  `${FELIX_PLUGIN_CACHE:-$HOME/.claude/plugins/cache}/felix/felix`.
- **The run felix**: the `felix` file the command was started as, symlinks followed. It **runs as
  the entry** when its directory is `<entry>/harness` (the same directory by `-ef`). That is how
  the land tick starts it.
- **A copy**: a directory `$TMPDIR/felix-merge-main.XXXXXX` (TMPDIR defaults to `/tmp`).
- **Pre-hand-off refusals**: every refusal `felix merge` makes today before it computes blockers:
  arguments and base, the unnamed branch, `FELIX_KERNEL is set`, no installed copy at V, `judging
  itself`, M with no `lib/resolve.sh` or no `felix_accepted_deploy_diff`, `cannot tell whether the
  judge is main's engine`, `the judge is not the engine main accepted`, and the entry not being the
  directory main's comparison accepted.

## 1. Defects

- **C067 (high).** A self-governed `felix merge` forms its verdict with the code of whichever
  `felix` was run, so a branch's own CLI judges and merges itself. README.md:181 says that cannot
  happen. *Scenario:* a session in a Felix worktree runs `engine/harness/felix merge` from a branch
  whose cmd_merge has a bug, such as an inverted `[ -n "$blockers" ]`. The candidate's prologue
  decides the verdict and calls `gh pr merge`, and main has no branch protection to stop it. Only
  `felix_merge_blockers`, and `felix_accepted_deploy_diff` read from M, come from main. The land
  tick is pinned (green-tick.sh:328-331); a session is not.
- **C063 (low; the skeptic lowered it from medium).** `felix merge` compares the entry with M byte
  for byte. It then sources the judge's libraries from that same writable directory, and they load
  more files from their own directory when they are called. *Scenario:* a session races the
  comparison. It keeps main's bytes in `<entry>/harness/lib/escape.sh` while the `felix-deploy.*`
  scratch directory exists, then swaps in a permissive copy before the source. Only a deliberately
  hostile session can do this, and it has easier bypasses. The gap is already recorded as a
  follow-up in docs/2026-10-18-judge-refs-residue-contract.md:258-262.
- **C116 (medium).** `felix new` refuses only an existing `projects/<name>`. It then rewrites a
  `.felix` that binds the git root to another live project, and says nothing. *Scenario:* in a
  monorepo, `felix new web apps/web` and then `felix new api apps/api` leave `.felix` reading
  `api`. `projects/web` binds nothing, and its sessions are judged as api's.
- **C117 (medium).** `felix new` writes `remote_match` once, from the origin as it is then, and it
  never says to commit `.felix`. Its own comment says a remote usually does not exist yet.
  *Scenario:* a stranger runs `felix new` on a fresh `git init` and adds a GitHub remote the next
  day. `remote_match` stays `""`, so no checkout is the project's own and nothing runs unattended.
  The untracked marker reaches no worktree, so Desktop judges those sessions at the main checkout.
  A non-GitHub origin goes whole into the tracked `project.json`, userinfo included (for example
  `https://user:token@gitlab.example/...`).
- **C064 (low; the skeptic narrowed it).** A hand `felix install` copies any untracked or ignored
  file under the home's `engine/` into the cache entry, such as a Finder `.DS_Store`. It then
  prints `verified` while the gate's `installed` check fails, and the remedy both print ("felix
  install on main") does not clear it. *Scenario:* `engine/.DS_Store` exists in the home, and a
  hand install at a new version turns `installed` red. The unattended deploy already refuses this
  case (A24, green-install.sh:32-50). Removing the file from the entry restores identity, so no
  version bump is needed; the brief's "red until a bump lands" is not what happens.

## 2. Required behaviour

### Part A. felix merge hands the verdict to main's engine (C067, C063)

- **B1. The hand-off.** Take a self-governed checkout where no pre-hand-off refusal applies and the
  run felix does not run as the entry. There `felix merge` forms no verdict with the run felix's
  code, with `--dry-run`, `--base B`, both or neither. It makes a copy and writes into `<copy>/<V>/`
  every path M tracks under `engine/`, so `<copy>/<V>/harness/felix` is M's
  `engine/harness/felix`. It runs `<copy>/<V>/harness/felix merge` from the same working directory,
  with exactly the arguments it was given. The copy gets the caller's environment with three
  changes. `FELIX_HOME` is set to the home the run felix resolved. `FELIX_MERGE_HANDED` is set to
  `1`. `FELIX_KERNEL_CACHE` points at the copy, but only if the implementation needs it. Every
  other variable reaches the copy unchanged. The command's stdout, stderr and exit status are the
  copy's (B11 adds one case). The run felix itself writes nothing on this path, except under B11
  or B12.
- **B2. The copy is M's bytes.** Each regular file in `<copy>/<V>/` is byte-identical to the blob M
  holds at that path under `engine/`. A `100755` entry is executable by its owner; a `100644` entry
  is not. The copy holds no path M does not track: no ignored residue from the entry, and nothing
  from the working tree. No byte of the copy changes for the checkout's `.git/info/attributes`
  (for example `* text eol=crlf`), its `core.autocrlf`, or a global git config.
- **B3. The entry is compared and never run.** On a run that hands off, no file under the entry is
  executed or sourced; it is only read, to compare it with M. Every library the verdict uses is
  sourced from the copy.
- **B4. The verdict is main's, and it names the installed entry.** On a run that hands off, M's
  code prints the verdict. Suppose the run felix's own dry-run sentence differs from M's. A passing
  dry run then prints M's `felix merge would squash this now.`, never the run felix's. It prints
  `byte-identical to main` exactly once, and the line `judged by <entry>, the engine main declares,
  byte-identical to main.`, where `<entry>` is the path composed above. A merge that goes ahead
  calls `gh pr merge` exactly once, with `--match-head-commit <HEAD's sha>` and with
  `Felix-Judge: <V> @ <M's full sha>` in the body. It prints `merged. nothing in it escaped the
  tree.` and then the judged-by line, and leaves in says.log a `merged` row naming `<entry>`. On
  these paths, and on a refusal for blockers, no line on stdout or stderr and no says.log row
  contains `felix-merge-main`.
- **B5. In place, as the land tick runs it.** When the run felix runs as the entry, it forms the
  verdict itself, as it does today. It makes no copy, and its output is as in B4.
- **B6. Refusals after the hand-off are recorded once.** A run that hands off and is refused for
  blockers exits 3 and prints `not merging` and the blocker lines. It leaves in says.log exactly
  the rows an in-place run (B5) of the same checkout state leaves: one `escalated` row per escape
  blocker and one `refused` row per kind. The run felix writes no row after it hands off.
- **B7. The marker refuses and never skips.** Suppose `FELIX_MERGE_HANDED` is non-empty and the run
  felix would hand off (B1). Then `felix merge` refuses instead. It exits 1, and stderr starts
  `felix: ` and names `FELIX_MERGE_HANDED`. It makes no copy and does not call gh. Without
  `--dry-run`, it writes one `refused` row whose text contains `: judge: `. When the run felix runs
  as the entry, the variable changes nothing (B5).
- **B8. Pre-hand-off refusals as today.** Every pre-hand-off refusal keeps its text, exit status and
  says.log row, and happens before any copy exists.
- **B9. A copy that cannot be made or run.** When M's engine cannot be copied out of git,
  `felix merge` refuses. It exits 1, stderr contains `could not copy main's engine`, it does not
  call gh, and TMPDIR is left as it was. Without `--dry-run` it writes one `refused` row with
  `: judge: `. The causes include a blob M's engine tracks that is missing from the object store,
  and a copy directory that cannot be made or written. When the copy holds no executable
  `harness/felix` because M's engine has none, it refuses the same way, with stderr containing
  `no harness/felix`.
- **B10. Nothing is left behind.** After `felix merge` ends, TMPDIR holds no `felix-merge-main.*`,
  and, as today, no `felix-judge.*` or `felix-deploy.*`. That holds however the run ends: the copy
  succeeding, refusing or ending with any status, or under B7, B9, B11 or B12. SIGKILL is out of
  scope (§6).
- **B11. A status felix merge never returns.** When the copy exits 0, 1, 2, 3 or 4, that is the
  command's status, and nothing is added. Any other status N is also the command's status, and the
  run felix adds one stderr line. The line contains `status N` and `not known`: whether anything
  was merged is not known, because the copy ended in a way felix merge never does.
- **B12. TERM and INT.** While the copy runs, TERM or INT may be sent to the `felix merge` process
  alone (its pid, not its process group). Within 5 seconds the copy stops and does nothing further,
  so no gh call follows. Within the same 5 seconds `felix merge` exits non-zero, and B10 holds. The
  INT case is tested on a `felix merge` started with INT not ignored.
- **B13. The same home and memory.** The copy resolves the same home and project as the run felix,
  and writes says.log rows to the same memory root. That holds even when `FELIX_HOME` is unset and
  the run felix found its home from its own location (`<engine>/../projects`).
- **B14. A governed product is unchanged.** In a checkout that does not track
  `engine/.claude-plugin/plugin.json`, `felix merge` never hands off and never makes a copy. The
  run felix forms the verdict whether or not `FELIX_MERGE_HANDED` is set, and, as today, with
  `FELIX_KERNEL` set and no cache.

### Part B. What the README claims (C067)

- **B15.** README.md's row that begins `| **The judge on main**` is a single table row reading:

  > | **The judge on main** (Felix's own repository) | At merge, the verdict on a change to Felix itself is formed by the engine main holds, not by the candidate's ([merge-judge.sh](engine/harness/lib/merge-judge.sh)). `felix merge` first checks that the installed copy of main's version is byte-identical to main. Then, unless it is that installed copy (as on the land-on-green job), it copies main's engine out of git for that one run, and the copy decides. This binds every `felix` that still hands off. A branch that edits its own engine so that its `felix merge` no longer hands off, and is run from that branch, judges itself. The rule came from one day on which nine engine changes in a row were each deployed before being judged, so each one judged itself |

  The row no longer contains `never by the candidate (`, and the file it links exists.

### Part C. felix new does not rebind (C116)

The **root** is the directory `felix new NAME [PATH]` binds: the nearest one at or above PATH that
holds `.git`, or PATH itself outside git (as today).

- **B16.** Suppose the root holds a `.felix` regular file whose content, with whitespace removed, is
  a valid project name X, and `<home>/projects/X/` is a directory. Then `felix new` refuses. It
  exits 1. stderr contains `already governed by X` and `felix new does not rebind`, and names
  `<root>/.felix`. Nothing is made: no `<home>/projects/NAME`, no memory directory for NAME, and the
  marker is byte-identical. No `claude` command runs, with or without `--no-commission`. The check
  runs after `felix new`'s existing refusals (arguments, flags, the name, a missing directory, an
  existing `projects/NAME`). It runs before anything is made and before the marker-writability
  refusal. The monorepo case is this case: after `felix new web apps/web`, a
  `felix new api apps/api` in the same repository is refused, and `.felix` still reads `web`.
- **B17.** The same refusal applies when the root has no `.felix` and its `origin` URL contains the
  non-empty `remote_match` of some `<home>/projects/X/project.json` (the remote binding Felix
  already resolves). stderr then contains `already governed by X` and `remote_match`, and no
  `.felix` is written.
- **B18.** A marker that binds nothing does not stop `felix new`. That covers a valid name X with no
  `projects/X` directory, an empty marker, and content that is not a valid name. `felix new` binds
  (exit 0, the marker now NAME). stdout carries one line that begins `  replaced ` and contains
  `<root>/.felix`. The line also contains X when X is a valid name, or `named no project`
  otherwise. With no marker before, no `  replaced ` line is printed.
- **B19.** When PATH is not physically the root, stdout carries a line that begins `  checkout `,
  containing the root's path and `the git root holding`. When PATH is the root, no such line is
  printed.

### Part D. felix new says what binds and what runs unattended (C117)

- **B20. The commit line.** Suppose the root is a git work tree and the marker just written is not
  what `HEAD:.felix` holds: it is untracked, HEAD is unborn, or the committed marker names another
  project. Then stdout carries a line that begins `  commit ` and contains `.felix` and `worktree`,
  with and without `--no-commission`. The line is not printed when `HEAD:.felix` already holds
  NAME, or when the root is not in git.
- **B21. remote_match carries no credential.** For an origin that is not GitHub's, `felix new`
  computes the value this way. If the URL holds an `@`, drop everything through its last `@`;
  otherwise drop a leading `<scheme>://`. Then drop one trailing `/`, then one trailing `.git`. An
  origin is GitHub's when it contains `github.com/` or `github.com:`; its value is as today. The
  value is therefore always a substring of the origin URL, so the checkout still resolves by its
  remote once the marker is removed. The `  repo ` line of felix new's output shows the same value.
  Neither `project.json` nor felix new's output holds any of the URL's userinfo.

  | origin | remote_match |
  |:---|:---|
  | `https://user:SECRETTOKEN@gitlab.example/grp/proj.git` | `gitlab.example/grp/proj` |
  | `git@gitlab.example:grp/proj.git` | `gitlab.example:grp/proj` |
  | `ssh://git@gitlab.example:2222/grp/proj.git` | `gitlab.example:2222/grp/proj` |
  | `https://github.com/Acme/Widget.git` (as today) | `Acme/Widget` |
  | `https://x-access-token:SECRETTOKEN@github.com/Acme/Widget.git` (as today) | `Acme/Widget` |
  | `git@github.com:Acme/Widget.git` (as today) | `Acme/Widget` |
  | no origin (as today) | `` (empty) |
- **B22. The unattended line.** Right after binding, the checkout may not be its project's own by
  lib/own.sh's rule (`felix_checkout_is_own` returns non-zero). That happens with no origin, a
  non-github.com origin, a submodule, or git unable to answer. stdout then carries a line that
  begins `  unattended `, contains `nothing runs for NAME unattended`, and names
  `<home>/projects/NAME/project.json`. When the checkout is its own (a github.com origin), no such
  line is printed.

### Part E. felix install refuses what git does not track (C064)

- **B23.** On `felix install` and `felix install --no-bump`, install asks the repository holding the
  source for `git ls-files --others --directory -- engine/`. It asks after the `engine:` line names
  the source, and before any `claude` command or version bump. That listing covers every untracked
  file, every ignored file, and each wholly untracked directory once, empty ones included. If it
  lists anything, install refuses with exit 1. Its output (stdout and stderr together) contains
  `engine/ holds N path(s) git does not track` and lists up to five paths as git names them. Its
  last line contains `the first is <first path>`. No `claude` command runs, nothing is bumped, and
  `engine/.claude-plugin/plugin.json` is byte-identical. Any path counts, not only those the
  installed check would call drift. That matches A24's guard on the unattended deploy, and the
  tick reads the last line.
- **B24.** With nothing untracked or ignored under `engine/`, install does what it does today.
- **B25. Unknown is said.** When git cannot answer, install goes on as today and prints one line
  containing `could not ask git` and `engine/`. That covers a source outside any git work tree, and
  git exiting non-zero.
- **B26.** `felix install --uninstall` asks git nothing and refuses nothing.

## 3. What must not change

`felix merge`, and the parts that pin it:

- The pre-hand-off refusals, with their texts, status and rows (B8):
  0340-the-line-that-does-the-work.sh, 0360-what-felix-merge-records-and-what-it-hands-g.sh,
  0970-membership-in-a-list-larger-than-a-pipe-cove.sh, 1400-judge-refs-residue-blind.sh,
  1401-judge-refs-residue-b-blind.sh, 1402-judge-refs-residue-a12-blind.sh and
  1403-judge-refs-residue-c.sh.
- The byte-identity rule: ignored residue under `harness/` is accepted, and `.claude-flow` is named
  when refused. Pinned by 0340 (section f), 1400, 1401 and 1403.
- The self-judgement guard, and the prose-only and bump-only branches that must not trip it: 0340
  and 0970.
- A self-governed branch merges, and a reviewer's pass clears the reviewed channel through the
  judge's review.sh: 0340.
- Line order (judged-by before would-squash; merged before judged-by) and the pattern
  `judged by [^ ]*/1\.0\.0, the engine main declares, byte-identical to main\.`: 0340. 1400 and
  1402 count `byte-identical to main` exactly once.
- 0360 pins the trailers `Felix-Judge` and `Felix-Gate`, `--match-head-commit`, skip-marker
  defusing and the subject fallback. It also pins one `refused` row per kind, `escalated` rows
  only on real attempts, and no rows from a dry run.
- A governed product needs no engine, and `FELIX_KERNEL` is ignored there: 0100-merging.sh, 0340,
  and 0350-what-it-verified-and-what-it-merges-are-the.sh (the moved-checkout guard). The
  reused-tests rule C9 is pinned by 1250-gate-friction-a2-blind.sh.
- The land tick runs `<cache>/<V>/harness/felix merge` from the worktree with `FELIX_ALLOW_RED`,
  `FELIX_KERNEL` and `FELIX_KERNEL_CACHE` unset (G6): 1280-land-on-green-blind.sh. That is B5's
  in-place path.

`felix new`, and the parts that pin it:

- 0010-resolution.sh: onboarding a stranger with no remote, the refusal of an existing project, and
  the kept-memory lines. 0190-continued.sh: `{{REPO}}` rows with no remote.
  0200-generated-constitution.sh: the generated constitution.
- 0220-the-binding-itself.sh: names refused as the marker refuses them, and a flag refused as a
  name. 0450-memory-scan-memory-stays-out-doctrine-stays.sh: probe and maturity seeding.
- Commissioning and obligations: 0700-continued.sh and
  0710-commissioning-a-seeded-check-reads-done-only.sh. The tables seeded in a home of its own:
  0720-the-engine-manifest.sh. The exceptions table:
  0780-exceptions-the-scoped-exception-channel.sh.
- `--no-commission` anywhere on the line, every other flag refused before anything is made, the
  unwritable-marker retry, and the usage naming `--no-commission`. Pinned by
  0820-felix-new-no-commission-governed-not-commiss.sh,
  0840-felix-audit-what-the-third-review-found.sh and
  0850-felix-audit-what-the-fourth-review-found.sh.
- The existing output labels `detected`, `gate guess`, `repo`, `bound via` and `memory`, and the
  synopsis text, which 0840 matches.
- The withheld line's exact text: 1130-unattended-work-runs-only-in-its-own-checkout.sh (B32).
  lib/own.sh is not edited.

`felix install`, and the parts that pin it:

- 0630-the-subject-of-a-large-payload.sh pins install from the cache. It never certifies the cache
  against itself, names the source, and registers from the directory holding marketplace.json. It
  verifies a matching tree, reports a checkout mismatch, and writes the pointer. 0630 runs through
  tests/lib/install-fixture.sh, whose source is not a git repository, so B25's line appears there.
- 0640-the-deployed-surface-is-three-directories.sh: the three-directory surface and
  felix_deploy_diff's residue rules. 0250-on-path-via-a-symlink.sh: the CLI on PATH through a
  symlink. 1281-land-on-green-deploy-blind.sh: the tick's deploy shape (its home felix is a stub).

Constraints on the change:

- The hand-off lives in a new library, `engine/harness/lib/merge-judge.sh`, under 500 lines.
  `engine/harness/felix` grows by at most 60 lines net. `lib/resolve.sh` (1872 lines) gets no
  longer, and `lib/detect.sh` (368) and `lib/own.sh` (291) stay under 500.
- `engine/harness/tests/run` (497 lines) gains exactly the two part lines and stays at 500 or fewer
  (1040-the-suite-is-cut-into-parts.sh). Each part is at most 1,000 lines. Every new `mktemp` has a
  template under TMPDIR (1000-the-engine-makes-its-scratch-under-tmpdir.sh). No gawk-only awk
  (1497-lib-awk-gawk-names-blind.sh). The engine names no project.
- Do not touch assertions.tsv, red.tsv, plugin.json, HANDOFF.md or docs/handoff/. Bash 3.2 and 5,
  BWK awk and gawk, and `LC_ALL=C` for sorts and comparisons all apply. Spell digit brackets out,
  and put no `case` inside `$( )`.
- Traps in this change:
  - `git archive` and `checkout-index` in the checkout's own repository apply its attributes (eol,
    filters, export-ignore), which B2 forbids. Use one git process for the whole tree, run against
    a scratch repository that borrows the checkout's objects and reads no machine-local config.
    That keeps both B2 and the cost low. One `git cat-file` per file measured 10.7 s wall (6.5 s
    CPU) for the 381 files of `engine/` on 2026-10-24, under load. The copy is about 9.4 MB.
  - bash defers a trap while a foreground child runs, and `cmd &` in a non-interactive shell starts
    with INT ignored. So for B12 the copy must be waited on in a way a signal interrupts, and
    stopped with TERM.
  - For B4 to name the entry while B3 holds, the copy must know the entry the run felix verified,
    or check the real entry itself. Either way it sources only its own libraries.
  - Measure part 0340's time before and after, and say it in the PR.

## 4. Assertions

Fixtures. Every run gets its own empty TMPDIR inside the part's directory, and paths are compared
physically (`pwd -P`). gh is a stub on PATH that logs its arguments. Projects in `$FROOT` are named
`b13s`, `b13m` and `b13p`, and are removed at the part's end. Receipts are recorded as
tests/lib/judge-refs.sh's `_jr_record` records them.

- **Fixture S (a stub main).** A checkout R with `.felix` `b13s`, origin
  `https://github.com/example/b13s.git`, and `.gitignore` `*.log` and `.DS_Store`. M (=
  `refs/remotes/origin/main`) holds, under `engine/`, `.claude-plugin/plugin.json` at 1.0.0,
  `harness/felix` (the stub below, mode 755), the real `harness/lib/resolve.sh`,
  `harness/lib/zz-only-main.txt` and `harness/tests/keep.txt`. The branch `b13s-candidate`,
  checked out, holds the real harness at version 2.0.0. The entry `KC/1.0.0` is cut from M's
  `engine/` as `_js_entry` cuts one, plus a residue `harness/zz.log`. Runs use
  `R/engine/harness/felix merge --dry-run --base refs/remotes/origin/main` with
  `FELIX_KERNEL_CACHE=KC` and `FELIX_HOME=$FROOT`.

  The stub appends to `$B13_STUBLOG` the lines `self=<its directory, physical>`, `cwd=`,
  `args=<$*>`, `home=<FELIX_HOME or unset>`, `handed=<FELIX_MERGE_HANDED or unset>` and `pid=`.
  Then, for each regular file under its version directory, sorted, it appends
  `file<TAB><path relative to it><TAB><git hash-object --no-filters><TAB><x or ->`. With
  `B13_STUB_SLEEP` set, it appends `started`, traps TERM and INT to append `signal <name>` and
  exit, and loops on `sleep 1` up to 30 times. It prints `MAIN-STUB ran` to stdout and
  `MAIN-STUB err` to stderr, and exits `${B13_STUB_RC:-7}`.
- **Fixture M (a real main).** A checkout Q built as `_js_build` builds its checkout, with project
  `b13m`. M's `lib/escape.sh` ends with this line:
  ``[ -z "${B13_ESCLOG:-}" ] || printf '%s\n' "${BASH_SOURCE[0]}" >> "$B13_ESCLOG"``.
  The branch `b13m-candidate` bumps to 2.0.0. In `engine/harness/felix` and
  `engine/harness/lib/*.sh` it replaces `felix merge would squash this now.` with
  `CANDIDATE-VERDICT would squash this now.`. The entry `KC/1.0.0` is cut from M, plus a residue
  `harness/zz.log`. A green receipt is recorded before each run.
- **Fixture P (a product).** A governed product checkout with project `b13p` and a green receipt,
  built as 0340's MR is.

Part 1870:

- **A1 (B1).** S, one dry run. The exit status is 7, stdout holds `MAIN-STUB ran`, and stderr holds
  `MAIN-STUB err`. The log has exactly one `self=`, which begins `$TMPDIR/felix-merge-main.` and
  ends `/1.0.0/harness`. `cwd=` is R, `args=` is `merge --dry-run --base
  refs/remotes/origin/main`, and `handed=1`. The gh log is empty.
- **A2 (B2).** S, after A1. The stub's `file` lines equal the paths, blob ids and modes of
  `git ls-tree -r M -- engine/` (paths without `engine/`, and `x` for 100755). They include
  `harness/lib/zz-only-main.txt` and `harness/tests/keep.txt`, and no `zz.log` appears.
- **A3 (B2).** S with three settings: `* text eol=crlf` in `R/.git/info/attributes`,
  `core.autocrlf true` in R, and a `GIT_CONFIG_GLOBAL` file with `core.autocrlf=true`. The `file`
  lines are the same as in A2, and the exit status is 7. Every setting is undone afterwards.
- **A4 (B11).** S, three runs. `B13_STUB_RC=0` exits 0, `3` exits 3 and `7` exits 7. stderr has a
  line containing `status 7` and `not known` in the third run, and only there.
- **A5 (B9).** S. As a fixture control, the loose object of `zz-only-main.txt`'s blob exists and a
  dry run reaches the stub. Delete that object. A dry run then exits 1 with stderr containing
  `could not copy main's engine`, adds no new `self=` to the log, and does not call gh. The same
  run without `--dry-run` adds one `refused` row with `: judge: ` to `$MEM/b13s/says.log`. Restore
  the object with `hash-object -w`.
- **A6 (B9).** S, with `--base refs/heads/b13s-nofelix`. That commit's engine, at version 3.0.0, has
  a `lib/` and no `harness/felix`; `KC/3.0.0` is cut from it. The exit status is 1, and stderr
  contains `no harness/felix`.
- **A7 (B12).** S with `B13_STUB_SLEEP=1`, started in the background. Wait up to 20 s for the log to
  say `started` (a fixture control), then send TERM to the felix merge pid. Within 5 s that pid is
  gone with a non-zero status, and the stub's recorded pid is gone or the stub logged `signal`.
  TMPDIR is empty.
- **A8 (B12).** As A7, with felix merge started through `perl -e '$SIG{INT}="DEFAULT"; exec @ARGV'`
  and sent INT.
- **A9 (B13).** S with `FELIX_HOME` unset, a scratch HOME with no `.felix-home`, and
  `R/projects/b13s/` holding a copy of the project. The log says `home=` R.
- **A10 (B7).** S with `FELIX_MERGE_HANDED=1`. The exit status is 1, and stderr names
  `FELIX_MERGE_HANDED`. The log has no new `self=`, and gh is not called.
- **A11 (B10).** After every run of A1 to A10, its TMPDIR listing is empty. This is one assertion,
  and it names each run that left something.
- **A12 (B4).** M, the candidate's felix, dry run. The exit status is 0. stdout has
  `felix merge would squash this now.` once, no `CANDIDATE-VERDICT`, `byte-identical to main`
  once, and `judged by KC/1.0.0, the engine main declares, byte-identical to main.`. Nothing
  contains `felix-merge-main`. As a fixture control, the candidate's engine holds
  `CANDIDATE-VERDICT` and M's does not.
- **A13 (B3).** M, after A12. No `B13_ESCLOG` line begins with `KC/`, and at least one begins
  `$TMPDIR/felix-merge-main.`.
- **A14 (B5; control).** M, `KC/1.0.0/harness/felix merge --dry-run`. The exit status is 0, with M's
  sentence, and every `B13_ESCLOG` line begins with `KC/1.0.0/`.
- **A15 (B14; control).** P, the candidate's felix, dry run. It prints
  `CANDIDATE-VERDICT would squash this now.`, with and without `FELIX_MERGE_HANDED=1`.
- **A16 (B4).** M, the candidate's felix, a real merge. The exit status is 0. The gh log has exactly
  one `pr merge`, with `--match-head-commit` equal to Q's HEAD and a body holding
  `Felix-Judge: 1.0.0 @ <M's sha>`. stdout has `merged. nothing in it escaped the tree.` and then
  the judged-by line naming `KC/1.0.0`. The newest `merged` row for `b13m` contains `KC/1.0.0`.
  Nothing contains `felix-merge-main`.
- **A17 (B6; control).** M with a red `execute` row in `projects/b13m/risk.tsv` for a file the
  branch adds. The candidate's felix and `KC/1.0.0/harness/felix` each run once without
  `--dry-run`. Both exit 3 with `not merging`, and neither calls `pr merge`. The `escalated` and
  `refused` rows each run adds match in number by kind, with at least one of each.
- **A18 (B7).** M, the candidate's felix with `FELIX_MERGE_HANDED=1`, without `--dry-run`. The exit
  status is 1, stderr names `FELIX_MERGE_HANDED`, and there is no `pr merge`. One `refused` row
  with `: judge: ` is added, and `B13_ESCLOG` has no `felix-merge-main` line.
- **A19 (B7, B5; control).** M, `KC/1.0.0/harness/felix merge --dry-run` with
  `FELIX_MERGE_HANDED=1`. The result is as in A14.
- **A20 (B8; control).** M, the candidate's felix. With `FELIX_KERNEL` set it refuses with
  `FELIX_KERNEL is set`. With `KC/1.0.0/harness/lib/say.sh` one comment off, it refuses with `the
  judge is not the engine main accepted`. Neither run puts `felix-merge-main` in `B13_ESCLOG`.
- **A21 (B10).** After every run of A12 to A20, its TMPDIR is empty.
- **A22 (B15).** README.md's `| **The judge on main**` row contains `copies main's engine out of
  git`, `no longer hands off` and `judges itself`, and not `never by the candidate (`.
  `engine/harness/lib/merge-judge.sh` exists.

Part 1880 runs in its own home, memory root and user HOME, through the claude stub, set up as
`_nc_build` (tests/lib/felix-new-nocommission.sh) sets them up.

- **A23 (B16).** A repository with `apps/web` and `apps/api`. As a fixture control,
  `felix new web apps/web --no-commission` exits 0. Then `felix new api apps/api --no-commission`
  exits 1, with stderr holding `already governed by web` and `felix new does not rebind`. `.felix`
  still reads `web`. There is no `projects/api`, no memory `api/`, and no claude call.
- **A24 (B16).** As A23, with the second command run without `--no-commission`. The exit status is
  1, and there are no claude calls.
- **A25 (B17).** The home holds `rx` with `remote_match` `example/rx-repo`. A checkout with origin
  `https://github.com/example/rx-repo.git` and no marker runs `felix new other --no-commission`.
  The exit status is 1, and stderr has `already governed by rx` and `remote_match`. Afterwards
  there is no `.felix` and no `projects/other`.
- **A26 (B18).** Three checkouts hold `.felix` `ghost` (with no `projects/ghost`), an empty
  `.felix`, and `.felix` `../bad`. Each `felix new fresh<n> --no-commission` exits 0, and the
  marker becomes `fresh<n>`. stdout has a `  replaced ` line holding `ghost` for the first, and
  `named no project` for the other two.
- **A27 (B18; control).** A fresh checkout with no marker. `felix new` exits 0 and prints no
  `  replaced ` line.
- **A28 (B19).** `felix new sub apps/x --no-commission` prints a `  checkout ` line with the root and
  `the git root holding`. Run from the root itself, it prints no such line.
- **A29 (B20).** A `  commit ` line containing `.felix` and `worktree` appears in a repository with
  one commit and an untracked marker, and on an unborn HEAD. Both cases are run with and without
  `--no-commission`. The line does not appear when `HEAD:.felix` already holds NAME (with no
  `projects/NAME`), or in a directory outside git.
- **A30 (B21).** The first three rows of the B21 table, each in its own checkout. `project.json`'s
  `remote_match` is the value shown. No `project.json`, stdout or stderr contains `SECRETTOKEN` or
  `user:`. After `rm .felix`, `felix which` there prints `project:      <name>`.
- **A31 (B21; control).** For the GitHub rows and the no-origin row, the value is as shown, and
  `SECRETTOKEN` appears nowhere.
- **A32 (B22).** A no-origin checkout and a GitLab-origin checkout each print a `  unattended ` line
  containing `nothing runs for <name> unattended` and `projects/<name>/project.json`.
- **A33 (B22; control).** A checkout with origin `https://github.com/Acme/b13own.git` prints no
  `  unattended ` line.
- **A34 (B23).** The install source is a git repository. It is built as
  tests/lib/install-fixture.sh builds one, then `git init` with everything committed, and a
  `.gitignore` holding `.DS_Store` and `.claude-flow/`. Three cases each hold one stray alone:
  `engine/.DS_Store`, `engine/harness/.claude-flow/data/x.jsonl`, or an empty
  `engine/commands/newdir/`. In each, `felix install --no-bump` exits 1. The claude stub log stays
  empty and `plugin.json` is unchanged. The output names the stray, and so does its last line.
  With all three strays together, the output says `3 path(s)`, and one plain `felix install`
  (bumping allowed) bumps nothing.
- **A35 (B24; control).** The same source with no stray. The exit status is 0, and the output has
  `verified   the installed engine matches this tree`.
- **A36 (B25).** tests/lib/install-fixture.sh's source as it is (not in git), with a matching cache.
  The output has a line containing `could not ask git` and `engine/`, and the `verified` line. The
  exit status is 0.
- **A37 (B26; control).** With `engine/.DS_Store` present, `felix install --uninstall` exits 0 and
  names no stray.

## 5. Parts

- `engine/harness/tests/parts/1870-merge-judge-handoff-blind.sh`: A1 to A22.
- `engine/harness/tests/parts/1880-new-binding-and-install-blind.sh`: A23 to A37.

Both go into tests/run after the 1600 line, in that order. Each runs alone under `--part`.

## 6. Out of scope, with why

- **A branch's own felix that no longer hands off.** The code before the hand-off is the
  candidate's, and nothing inside a CLI can bind that CLI. The pins outside it are the land tick
  (built) and roadmap step 15 (the judge pinned outside the change it judges). B15 says so.
- **`gh pr merge` typed directly.** The README discloses it. Deny rows on raw merges are roadmap
  step 18, which is the founder's.
- **A race against the entry when it runs in place** (the tick, or a session running the cache's
  felix directly). Only a same-user adversary can do this, and README.md:314-316 says Felix is a
  floor, not a wall. It belongs to roadmap step 15. So do a `git` shim and a BASH_ENV function,
  which engine/harness/felix:196-199 already documents as out of reach.
- **SIGKILL**, which leaves its copy under TMPDIR: nothing can run after it.
- **C117's session-start screen line and `felix rebind --remote`.** `remote_match` is the
  corroboration that unlocks unattended work (lib/own.sh). A hook or command that copied the
  current origin into it would let any marker-bound checkout make itself its own. And a token on
  every session's screen for a GitLab project would be permanent noise. The withheld line's text is
  pinned by 1130 (B32).
- **C117's Desktop hooks judging an unbound worktree at the main checkout**
  (resolve.sh:525-549). The cause is the uncommitted marker, which B20 now names. Moving where
  hooks stand belongs to the hooks tier, and resolve.sh must not grow.
- **Other readers of `felix_repo_slug`.** `felix pr`, bootstrap, setup's `{{REPO}}` and
  session-start adoption can still pass a non-GitHub URL whole. This was found while reading and is
  recorded as a follow-up, not fixed here.
- **C064, the rest.** Making install's own verify use the accepted comparison is separate work.
  Stripping strays would delete files in the home, which cannot be undone, so install refuses
  instead (invariant 3). Serving the engine from `git archive` is not possible, because Claude Code
  copies the directory marketplace as it lies on disk. `.gitignore` needs no change: `.DS_Store` is
  already ignored (line 2), and B23 reads ignored files as well.
- **The felix project's deny row** that says "use felix new or felix install --home" stays true for
  an unbound or broken checkout. Its table is the founder's.
- **The `felix new` synopsis** stays as it is, because every argument refusal quotes it. B16 and
  B19 say "one git root" where it matters.

Not fixed: not a defect. None. All five defects hold on this tree; two carry corrected severities.

## 7. Founder PR

None. No workflow, deny or escape row, commission grant or publish is needed. The public snapshot's
README changes at its next publish, the founder's act, and nothing here waits on it.
