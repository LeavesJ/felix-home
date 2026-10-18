# Judge refs and residue: the contract

Two holes the security reviews of land on green (#442) found in the code that
says a deploy is exactly main's. Both feed `felix merge`'s judge check, the
gate's `installed` check, and the land trampoline. The carrier recorded them
on 2026-10-15 as new slot class entries
(`audits/2026-10-08-carrier/state.md` under the memory root).

This file is the whole specification the blind assertions are written from.
It says what must be true, not how.

## Part A. Which commit "main" names

**The hole.** `felix_base_ref` returns the short name `origin/main`. Git
resolves a short name by trying, in order, `$GIT_DIR/<name>`,
`refs/<name>`, `refs/tags/<name>`, `refs/heads/<name>`, then
`refs/remotes/<name>`. Every worktree shares one ref store, so any session
can create `refs/tags/origin/main`, `refs/heads/origin/main` or
`refs/origin/main`. Each redirects every reader of the short name. One of
those readers is `felix merge`, which reads main's judge code with
`git show "$base:engine/harness/lib/resolve.sh"`. The decoy can therefore
replace the judge itself, as well as the base, staleness and changed paths.
The felix project's own gate (`projects/felix/gate.sh`) resolves its base
with its own `for GREF in origin/main main` loop and has the same hole.
`felix_kernel_dir` has a third copy of the loop.

NAME is the base argument, ROOT a repository. A "decoy" is a ref at a
different commit from the one meant: `refs/tags/X`, `refs/heads/X` or
`refs/X`, for X the short name a reader would otherwise pass to git.

- **A1.** `felix_base_ref ROOT NAME`, for a NAME that starts with neither
  `refs/` nor `origin/`. When a ref of exactly the name
  `refs/remotes/origin/NAME` exists and names a commit, it prints exactly
  `refs/remotes/origin/NAME` and exits 0. Decoys for `origin/NAME`, and for
  NAME itself, change nothing, whether one at a time or all at once.
- **A2.** NAME of the form `origin/X`, which a caller may pass. When
  `refs/remotes/origin/X` names a commit, it prints exactly that and exits 0.
  Otherwise it exits non-zero and prints nothing. It never prints, and never
  resolves through, any of these:
  - `refs/tags/origin/X`
  - `refs/heads/origin/X`
  - `refs/origin/X`
  - `refs/remotes/origin/origin/X`
- **A3.** NAME as in A1, with no such remote-tracking ref. When a ref of
  exactly the name `refs/heads/NAME` names a commit, it prints exactly
  `refs/heads/NAME`. A tag named NAME, `refs/NAME` or `refs/remotes/NAME`
  changes nothing. (The last one must not win over the local branch, as it
  does not in git's own order.)
- **A4.** Otherwise NAME is taken as given (a sha, `HEAD~1`, a tag's name).
  When `NAME^{commit}` resolves, it prints NAME unchanged. When it does not,
  it exits non-zero and prints nothing on stdout. A1 and A3 look up refs of
  exactly those names. A NAME that carries a revision suffix is not such a
  ref. So `HEAD~1` means this repository's `HEAD~1` even when
  `refs/remotes/origin/HEAD` exists, which a clone always has.
- **A5.** NAME starting `refs/` is unchanged from today. It is printed as
  given when it names a commit; otherwise the function exits non-zero and
  prints nothing.
- **A6.** An empty NAME means `main`, which is today's runtime behaviour. An
  empty ROOT exits non-zero and prints nothing: `git -C ""` would read the
  current directory.
- **A7.** Every definition of `felix_base_ref` under `engine/harness`
  satisfies A1–A6 on its own. `lib/resolve.sh` holds two today, and the
  later one wins when the file is sourced, so a fixed first definition
  proves nothing. The lib as `felix` sources it satisfies them as well.
- **A8.** `felix_kernel_dir ROOT NAME` reads main's version from the commit
  A1–A4 name. Take a decoy `refs/tags/origin/main` whose `plugin.json`
  declares another version, with cache entries for both versions present.
  It prints the entry for the version `refs/remotes/origin/main` declares.
- **A9.** `felix merge` in a self-governed checkout, the suite's existing
  judge fixture (#260). The decoy is `refs/tags/origin/main`, and separately
  `refs/heads/origin/main`. It points at a commit whose
  `engine/harness/lib/resolve.sh` defines a `felix_accepted_deploy_diff`
  that prints an entry and exits 0. Take a state in which, without the
  decoy, `felix merge --dry-run` refuses with `judge` because the cache
  entry differs from main's engine. With the decoy present, it refuses for
  that same reason.
- **A10.** The `installed` check in `projects/felix/gate.sh`. The decoy
  `refs/tags/origin/main` points at a commit whose `resolve.sh` always
  accepts. The check reads the same verdict as with no decoy: it fails when
  the cache entry differs from `refs/remotes/origin/main`'s engine.
- **A11.** At least one other CLI reader that resolves its base through
  `felix_base_ref` (`felix receipt`, `felix next`, `felix pr`'s tier,
  evidence or classify) compares against `refs/remotes/origin/main`'s commit
  while a decoy is present. Its changed paths are those of the real base,
  not the decoy's.

- **A12.** Added after the blind round. Today, when `felix_base_ref` fails,
  `felix merge` falls back to the name as given: `|| printf '%s' "$base"`.
  For `origin/X` with no remote-tracking ref, that name is exactly what a
  decoy answers to. So when `felix_base_ref` cannot resolve the base,
  `felix merge` refuses. It never reads judge code, version or changed paths
  through the name as given. The report-only readers (pr, next, receipt,
  evidence, classify) keep their fallback.
  `felix merge` also refuses a base `felix_base_ref` resolves only as given
  (A4): it judges and merges against a full ref name or not at all, because an
  expression such as `main~1` still reaches git's short-name order.

A message that prints the base may now print `refs/remotes/origin/main`.
That is accepted.

## Part B. What counts as residue when the judge compares the deploy

**The hole.** `felix_accepted_deploy_diff` compares main's engine with the
cache entry, and treats a differing path as residue when an ignore rule
matches it. It reads those rules from the checkout's working tree
(`$root/engine`) and from `.git/info/exclude`. Take an untracked `.gitignore`
holding `*` under the home's `engine/`. With it present, any extra file in a
cache entry counts as residue, and so does content drift in a file main
ships, because `check-ignore "$p/"` answers for a tracked file as if it were
a directory (#360). `felix merge`'s judge check and the land trampoline then
accept a cache entry that is not exactly main's. An extra `commands/*.md`
becomes a live slash command.

M is main's commit as Part A names it. E is the cache entry for the version M
declares. The comparison is over `engine/{harness,hooks,commands}`.

- **B1.** The verdict of `felix_accepted_deploy_diff ROOT [NAME]` depends on
  M and E only. ROOT's working tree, index, `.git/info/exclude` and config do
  not enter, and neither does the branch checked out. Each variant below runs
  on its own:
  - (a) untracked `ROOT/engine/.gitignore` holding `*`;
  - (b) the same under `engine/commands/`;
  - (c) the same under `engine/harness/`;
  - (d) `ROOT/.gitignore` edited in the working tree, uncommitted, to add `*`;
  - (e) `.git/info/exclude` holding `*`;
  - (f) a commit on the checked-out branch, not on M, adding `*` to `.gitignore`;
  - (g) `core.excludesFile` in the repository's config naming a file that
    holds `*`;
  - (h) `ROOT/.gitignore` deleted from the working tree.

  In each variant, two results hold:
  - An E that is M plus one extra file exits 1, and the line names that
    file. The extra file goes under `harness/`, `hooks/` and `commands/` in
    turn.
  - An E equal to M exits 0 and prints E.
- **B2.** A path M ships is never residue. E with different content at that
  path exits 1 and names it. This holds when M's own committed rules match
  the path (M force-added `harness/keep.log` under `*.log`), and under every
  variant (a)–(g). The same holds for a path M ships that E lacks.
- **B3.** A path only E holds is residue only when M's committed ignore rules
  match it. Residue means exit 0 with that line not printed.
  - The rules are every `.gitignore` M holds: the root's, `engine/`'s, and
    any nested below.
  - They apply as git applies them: directory-only patterns match a file
    beneath a directory of that name, and negations hold.
  - Controls:
    - M's root holds `.claude-flow/` and `*.log`. E-only
      `harness/tests/.claude-flow/x.json` and `harness/tests/x.log` exit 0.
    - An E-only path no M rule matches exits 1.
    - A rule in a nested `.gitignore` that M holds, such as
      `engine/harness/tests/.gitignore` with `scratch/`, makes
      `harness/tests/scratch/y` residue.
- **B4.** Under `commands/`, no path only E holds is residue, whatever M's
  rules say. A Markdown file there is a slash command. Claude Code also
  namespaces commands by subdirectory; that is documented for project
  commands and not measured for a plugin's cache. So the rule treats an
  extra file anywhere under `commands/` as behaviour, not residue. Each of E-only `commands/data/evil.md`,
  `commands/.claude-flow/evil.md` and `commands/x.log` exits 1 and is named.
- **B5.** One call reads one commit. The version, the archive and the rules
  all come from the same commit. If `refs/remotes/origin/NAME` moves during
  the call, after the version is read, the verdict is the verdict for the
  commit first read. A shim of git that moves the ref after the first read
  is how the suite pins it.
- **B6.** M's rules are read with no machine-local input: no global excludes
  file, no `info/exclude`, no `core.excludesFile`. The machine's global git
  config is set to name an excludes file holding `*`, and nothing changes.
- **B7.** Every temporary directory the call makes is gone after every
  return, whether 0, 1 or 2. The call reads nothing from stdin.
- **B8.** Shapes are unchanged:
  - Exit 0 prints the entry path.
  - Exit 1 prints each differing line, in diff's own shapes
    (`Files A and B differ`, `Only in <dir>: <name>`), or the one line
    "declares X and nothing is installed at that version".
  - Exit 2 prints `cannot examine: …`.
- **B9.** `felix_deploy_diff SRC LIVE [IGROOT]` is the working-tree form, and
  `felix install`'s verify and `felix next` read it. A path the IGROOT
  repository tracks is never residue there, even when an ignore rule matches
  it only through the directory form of the query. #360's case: tracked,
  force-added `harness/keep.log` under `*.log`, with different content in
  LIVE, exits 1. Untracked, ignored strays in SRC or LIVE stay residue there,
  as before (#86): `harness/tests/.claude-flow/x` exits 0.
- **B10.** The callers judge as the function does. Take an E that is M plus
  `commands/extra.md`, in a home whose `engine/` holds an untracked
  `.gitignore` of `*`. The gate's `installed` check fails, and
  `felix merge --dry-run` refuses with `judge`.

## Out of scope, said so the next reader does not assume it

- `lib/bootstrap.sh` (`origin/HEAD:` and `origin/main:` workflow probes)
  reads short names. So does `lib/inventory.sh`'s default-branch read. Both
  are advisory or reporting reads, not judge paths.
- `felix_exceptions_ref` returns the short name `origin/main`, but its one
  reader, `felix_exceptions_at_base`, reads `refs/remotes/$ref`, so grants
  are already read by full name. Only the listing's heading shows the short
  name.

## Constraints

- bash 3.2, git and coreutils only. No network, no model, no project named
  under `engine/harness`.
- `lib/resolve.sh` is read from main by the gate and by `felix merge`. So the
  code that binds after this lands is the version on main, and the suite pins
  it by building fixtures whose main holds this tree's engine.
