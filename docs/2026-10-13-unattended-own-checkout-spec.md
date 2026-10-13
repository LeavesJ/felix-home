# Unattended work runs only in the project's own checkout: the specification

Written 2026-10-13 against main at 5fd58110 (engine 0.49.283). The design brief
was decided by the orchestrating session; this makes it exact and does not
reopen it. Every behaviour is numbered, says what is observable, and is meant to
become one or more assertions in `engine/harness/tests/parts/`. Decisions taken
where the brief left a choice are in section 7, each with its evidence.

Tier: adversarial. `engine/harness/lib`, the `felix` CLI and the hooks run in
every session of every governed project.

Notation: `\t` is one tab byte. Paths are relative to `engine/harness/` unless
they start with `projects/` or `docs/`. Line numbers are main at 5fd58110.

---

## 0. The threat, restated in one paragraph

`felix_resolve_project` (lib/resolve.sh:405) binds a checkout to a project by
its `.felix` marker first and by a substring of its origin URL second. A
`.felix` is part of the tree, so a repository's authors choose it, and a
project name such as the one Felix governs itself under is public. Once bound,
`hooks/session-start` starts work with nobody present, in the checkout. This
change keeps the binding and everything a present person gets, and withholds
only the unattended work, unless the checkout is not a submodule and its origin
remote names the project's own repository.

---

## 1. Every unattended path, traced in the code

"Unattended" here: started by a hook or by a child a hook detached, with no
person having typed the command. Every hook under `hooks/` was read
(session-start, session-end, stop, subagent-start, subagent-stop, pre-tool,
post-tool, user-prompt). A search for a detaching `) ... &` across `hooks/*`,
`lib/*.sh` and `felix` finds exactly four: lib/commission.sh:261,
lib/discover.sh:1490, lib/graph.sh:136, lib/reach.sh:267. All four are started
from `hooks/session-start` only. No other hook detaches anything.

### P1. The commissioning resume (brief item 1): confirmed, and wider than listed

- Launch: hooks/session-start:631-635, inside `if [ -f "$PROJ/commissioning.tsv" ]`,
  calls `felix_commission_resume_bg "$PROJ" "$FELIX_HOME_DIR" "${SCRIPT_DIR}/../felix"`.
- lib/commission.sh:244-264: returns unless `felix_autonomy_commission_current`
  (lib/autonomy.sh:47: `commission` named in `projects/<p>/autonomy` AND
  `projects/<p>/autonomy.commission` equal to `felix_commission_policy_version`,
  a hash over the twelve tables in `FELIX_COMMISSION_TABLES`, commission.sh:50).
  Then `root="$(felix_repo_root "$PWD")"`, and a detached subshell
  `cd "$root"; "$bin" commission`, writing `<ts>\tran\t<root>` or
  `<ts>\tdeclined-or-failed\t<root>` to
  `$home/state/commission/<project>.bg.log`.
- What `felix commission` then does in that checkout (felix:5223-5538):
  - adopts every undeclared capability the checkout shows (felix:5303-5317,
    `felix_adopt_capability`), writing the project's tables;
  - `felix_commission_run` asks every row: `felix_commission_ask`
    (commission.sh:308-327) does `cd <root>` and `eval` of the row's `when` and
    `check`, with the checkout as working directory;
  - answer stages (felix:5212-5221): `cmd_discover --adopt` (installs plugins,
    `felix_stack_install`), `cmd_stack apply --yes` (lib/stack.sh:305-312:
    `claude plugin marketplace add`, `claude plugin install --scope user`,
    `claude mcp add`), `cmd_ready --fix`, `cmd_toolbox --route` (rewrites
    routes.tsv), `cmd_obligations --seed`;
  - checks that reach tools whose behaviour depends on the checkout:
    the `stack` row's check calls `felix_stack_plan` (stack.sh:138), whose
    `_felix_load_state` (stack.sh:39-42) runs `claude plugin list`,
    `claude mcp list` and `claude plugin marketplace list` in the checkout
    (`claude mcp list` starts the servers it lists); the `probes` row runs
    `felix_probes_run`, which is `cd <root>; bash -c <probe>` (lib/probes.sh:176,
    271); the `baseline` row's check runs `cmd_bootstrap` (felix:3562), which
    writes `.github/workflows/<gate workflow>` into the checkout and runs
    `gh label create ... --repo <slug>` where the slug is parsed from the
    checkout's own origin (`felix_repo_slug`, lib/detect.sh:233);
  - the admit phase fetches nominations at pinned shas (network).
- Grant on disk today: `projects/felix/autonomy` names `commission`.
- Verdict: refuse unless own (section 3, B10-B13).

### P2. The discovery refresh (brief item 2): confirmed; the checkout is needed only to bind

- Launch: hooks/session-start:580-583, for any project with `routes.tsv` when
  `claude` is on PATH and `felix_discover_stale` (discover.sh:1457, home state
  only) says so.
- lib/discover.sh:1470-1492: takes `$home/state/discover/.lock`, detaches,
  `cd "$(felix_repo_root "$PWD")"` (discover.sh:1480, the only line in
  discover.sh that reads `$PWD` or a repository root), then
  `"$felix_bin" discover --inspect --quiet > <cache>.new.$$` and renames it
  over `$home/state/discover/<project>.tsv`.
- `felix discover --inspect --quiet` (felix:2870-3058): `resolve_or_die`
  (felix:336, binds from `$PWD`), then `felix_discover_candidates`
  (discover.sh:161: `claude plugin list --json --available`), per candidate
  `felix_discover_source` (discover.sh:247: the same listing again),
  `felix_discover_fetch` into `mktemp -d "${TMPDIR:-/tmp}/felix-discover.XXXXXX"`
  (git with `-C <scratch>` only), `felix_discover_inspect`, `felix_discover_risk`,
  `felix_discover_digest`, `felix_plugin_description`, `felix_capability_match`,
  and `_felix_discover_stamp_line` (`git hash-object --stdin`, which works
  outside any repository: checked 2026-10-13, git 2.54.0). Rules come from
  `templates/discover-rules.tsv` and the project's `capabilities`. Nothing in
  that path reads a file of the checkout.
- So the checkout contributes exactly two things: the binding, and whatever
  `claude` reads from the working directory when it lists plugins (a checkout's
  `.claude/settings.json` can name marketplaces and plugins, per the brief; not
  re-measured here). The second is the hazard: the cache is per project, not
  per checkout, and `felix discover --adopt` (attended, or the P1 answer stage)
  installs the low-tier rows of it.
- Verdict: run from a private empty directory, for every project, own or not
  (section 3, B14-B17; decision D1).

### P3. The graph refresh (brief item 3): confirmed

- Launch: hooks/session-start:323-325, when `felix_graph_line "$_repo_root"`
  says `behind this checkout`.
- lib/graph.sh:124-137: returns unless `graphify` is on PATH and
  `<graph home>/graphify-out` exists, where the graph home is the parent of the
  checkout's `git rev-parse --git-common-dir` (graph.sh:30); takes
  `graphify-out/.felix-refresh.lock`, detaches, `cd <graph home>;
  graphify update <graph home>`. graphify reads the checkout's files. A
  repository can ship `graphify-out/graph.json` with a `built_at_commit` stamp
  that makes it read as behind.
- An unbound checkout never gets here: session-start:203 is
  `[ -n "$PROJ" ] || exit 0` (confirmed).
- Verdict: refuse unless own (B18-B19).

### P4. Tidying (brief item 4): confirmed

- Launch: hooks/session-start:331-336, every session.
- lib/autonomy.sh:93-134 `felix_tidy_safe`: returns unless `tidy` is named in
  `projects/<p>/autonomy`; lists rivals with `_felix_rival_gates`
  (detect.sh:170: `git ls-files` and `git ls-files --others` in the checkout);
  for each untracked executable rival whose basename Felix holds in
  `projects/<p>/`, copies it into `$home/state/rivals/<project>-<path>` and
  `rm -f`s it from the checkout. Unattended deletion in a checkout, and a copy
  of the checkout's bytes into the home's state.
- Grant on disk today: `projects/elenchus/autonomy` names `tidy`.
- Verdict: refuse unless own (B20-B21).

### P5. The reach refresh (brief item 5): confirmed safe, untouched

hooks/session-start:610-614, lib/reach.sh:253-269, lib/reach-read.sh:164-225:
`claude mcp list` runs in a fresh `felix-reach.XXXXXX` directory under a
private `TMPDIR`. Unchanged by this work except that the directory-making half
of `felix_reach_read` is extracted for reuse (B15), with every sentence and the
directory name unchanged.

### P6. Missed by the brief: adoption at session start

- hooks/session-start:225-244: `felix_undeclared "$_repo_root" "$PROJ"`
  (detect.sh:128: `felix_detect` over the checkout's files minus the project's
  `capabilities`), and for each capability `felix_adopt_capability`
  (lib/adopt.sh:35), which appends to `projects/<p>/capabilities`, appends
  `DECLARED` rows from `templates/catalog.tsv` to `projects/<p>/stack.tsv`,
  rows to `setup.tsv`, and copies `templates/setup/<id>.md`.
- Nobody typed it. It writes the bound project's durable, tracked tables from
  what an unowned tree contains. `capabilities`, `stack.tsv` and `setup.tsv` are
  three of `FELIX_COMMISSION_TABLES`, so the write also rotates the policy
  version and lapses a commission grant stamped over the old tables
  (autonomy.sh:47-60): an unowned checkout bound to a granted project disarms
  the grant and dirties the home's tracked files, with nothing on any surface
  but one context line.
- Verdict: the same rule; refuse unless own (B22-B23; decision D3).

### P7. The offline commissioning block at session start (brief "also in scope")

- hooks/session-start:636-702: per provider row, `felix_commission_provider_state`
  and, when `answered`, `felix_commission_record_provider`
  (commission-provider.sh:291), which appends rows to
  `$(felix_mem_dir <p>)/commissioning.log`; and the once-per-topology
  all-clear, which appends a topology hash to
  `$home/state/commission/<project>.seen`.
- The answer files are `felix_commission_answer_path`
  (commission-provider.sh:102): `$(felix_mem_dir <p>)/commission/<need>.tsv`,
  in the memory root, which is computed from `$HOME` and is never inside a
  checkout (resolve.sh `felix_mem_root`). The checkout reaches this block only
  through `felix_commission_topology` (commission-provider.sh:90: `felix_detect`
  over the checkout plus the declared list plus commissioning.tsv, hashed),
  which decides whether a memory-root answer reads `answered` or `stale`, and
  through the tree id stamped into the log row.
- Verdict: leave it (decision D4).

### Synchronous hook work, read and left, with why

| Where | What runs in or over the checkout | Why it is not gated |
|---|---|---|
| session-start:270-293, stop:127 | `felix_maint_status` runs each cadence-0 row's check as `cd <root>; bash -c <check>` (maintenance.sh:228) | The text is the home's `maintenance.tsv`; every row on disk today calls `git`, `find`, `test` or the engine's `bin/handoff-in-flight`, none of which executes checkout content. Its output is the context line a session reads. Residual, stated: a row whose check ran a checkout's own tool (`npm`, `make`) would be unattended tree code; no such row exists. |
| session-start:636 | `felix_commission_topology`, `felix_commission_receipt_valid` | File reads and hashes (`felix_detect` greps manifests; it executes nothing). |
| session-start:155-164 | `felix_lifecycle_session`, `felix_mem_mistakes_heal` | Memory-root records; git `rev-parse` only. |
| session-start:542, 472-474, 593 | overnight sweep, reconcile and discovery `mark_seen` | Home and memory state only. |
| stop, subagent-stop | `felix_tree_dirty`, `felix_tree_id`, receipts, `felix_say` | git only; this is the Stop hold a present session gets. |
| stop (overnight) | continues a session with direction | A night is granted to one session by a person typing `felix overnight --start` in it; not a hook's own launch. |
| user-prompt | route context, `felix_shape_brief` reads a plan file in the checkout | A person typed the prompt. |
| pre-tool | deny rows | Out of scope by the brief. |
| post-tool, session-end, subagent-start | ledger records, rollup, a context paragraph | Home and memory only. |

git itself: every gated or ungated path calls git in the checkout. What git
runs (hooks, fsmonitor, pager, filter and diff drivers) is chosen by `.git`
and the user's config, never by the tracked tree (an attribute can only name a
driver config defines). So a cloned repository cannot steer it. A checkout
whose `.git` itself came from an attacker (a tarball carrying `.git`) controls
its own config, its own `origin`, and code git runs; that is out of Felix's
reach and is not claimed.

The `origin` is the tree's to choose in one case, and it is claimed: a
submodule. git writes a submodule's `origin` from the superproject's tracked
`.gitmodules` url, so a hostile superproject names any GitHub repository it can
fork or open a pull request against, and the gitlink commit only has to be
fetchable from there (fork and pull-request commits are). A submodule is
therefore never own (section 3, `felix_checkout_is_own` rule 4, decision D9).
Found in review: the first version of this paragraph said the `origin` was
beyond the tree's reach, which is false for submodules.

---

## 2. Files

| File | Change | Lines before | Rule |
|---|---|---|---|
| `lib/own.sh` | new: the predicate, the gate, the withheld line, and `felix_commission_resume_bg` moved here | 0 | under 500 |
| `lib/commission.sh` | `felix_commission_resume_bg` and its comment removed; sources `own.sh` when `felix_commission_resume_bg` is missing | 731 | must not grow |
| `lib/discover.sh` | the refresh child runs through `felix_neutral_run`; sources `reach-read.sh` when `felix_neutral_run` is missing | 1516 | must not grow |
| `lib/reach-read.sh` | `felix_neutral_dir`, `felix_neutral_rm`, `felix_neutral_run`; `felix_reach_read` calls `felix_neutral_dir` | 225 | under 500 |
| `hooks/session-start` | gates at four call sites, one appended line | 726 | must not grow |
| `tests/parts/1130-unattended-work-runs-only-in-its-own-checkout.sh` | new | 0 | under 500 |
| `tests/run` | one `. "$HERE/parts/1130-..."` line after 1120 | 437 | under 500 |
| existing parts | fixture changes only (section 6.4) | | no assertion renamed or re-expected |
| `engine/.claude-plugin/plugin.json` | version | | section 8 |
| `tests/assertions.tsv`, `tests/red.tsv` | re-recorded at ship | | |

"Must not grow" is `wc -l` after ≤ `wc -l` before; a builder trims comments
that described the moved code (session-start:616-630 can point at `lib/own.sh`
in fewer lines). The `felix` CLI is not edited (decision D2).

---

## 3. Functions

### `felix_remote_github_slug <url>` (lib/own.sh)

Prints `owner/repo`, lowercased, and returns 0 when `<url>` names a github.com
repository in one of these spellings; prints nothing and returns 1 otherwise.

1. The whole URL is lowercased (`LC_ALL=C tr 'A-Z' 'a-z'`). Any byte outside
   printable ASCII, any space, and a `?`, `#` or `\` anywhere in it, returns 1.
   This is checked on the whole URL before it is split, because the split below
   takes the authority to end at the first `/` and drops everything up to its
   last `@` as userinfo, and by URL rules the authority ends at the first `?` or
   `#`. Measured 2026-10-13 on git 2.54.0: `git ls-remote
   'https://evil.invalid#@github.com/OwnerX/ownp-repo'` (and `?@`) resolves
   `evil.invalid`, while its error message prints
   `https://github.com/OwnerX/ownp-repo/`. A `\` is read as a path separator by
   some URL parsers and as userinfo by others (that git connected to
   github.com), so it refuses too: where parsers disagree about the host, no host
   is corroborated.
2. One trailing `/` is removed, then one trailing `.git`.
3. Accepted shapes (after 1-2), where `H` is a host and `P` a path:
   - `https://[userinfo@]H[:port]/P`
   - `ssh://[user@]H[:port]/P`
   - `git://H[:port]/P`
   - scp-style `[user@]H:P`: no `://`, and no `/` before the first `:`.
   Userinfo is everything up to the last `@` of the authority and is discarded.
   A port is `:` followed by digits only.
   Anything else (`http://`, `git+ssh://`, `file://`, a local path) returns 1.
4. `H` must equal `github.com` exactly (so `github.com.evil.example`,
   `evil.example`, `www.github.com` return 1).
5. `P` must be exactly two segments `owner/repo`, each matching
   `^[a-z0-9._-]+$` and neither `.` nor `..`; a leading `/` in the scp form or a
   third segment returns 1 (`?`, `#` and `\` already did, by rule 1).

Bash 3.2: case patterns or `[[ =~ ]]` with the pattern held in a variable; no
`${x,,}`; no loop of `${x#pat}` over input.

### `felix_checkout_is_own <proj> <root>` (lib/own.sh)

Returns 0 own, 1 not own, 2 unknown. Sets `_FELIX_OWN_WHY` to exactly one of
`own`, `no-match`, `no-origin`, `submodule`, `other`, `unread`.

1. `m="$(felix_json_str "$proj/project.json" remote_match)"`. Normalised the
   way a URL path is: lowercased, one trailing `/` then one trailing `.git`
   removed. If it is not exactly `owner/repo` by rule 5 above (empty and absent
   included): return 1, `no-match`. A project with no usable remote_match has
   no own checkout.
2. `git` not on PATH: return 2, `unread`.
3. `u="$(git -C "$root" remote get-url origin 2>/dev/null)"`, status `rc`.
   Measured 2026-10-13 on git 2.54.0: 2 when there is no `origin`, 128 outside
   a repository.
   - `rc` 2: return 1, `no-origin`.
   - `rc` other than 0 and 2 (128, 69 under an unaccepted Xcode licence, 127):
     return 2, `unread`.
   - `rc` 0: go on to rule 4.
4. `sp="$(git -C "$root" rev-parse --show-superproject-working-tree 2>/dev/null)"`.
   Measured 2026-10-13 on git 2.54.0: it prints the superproject's path for a
   submodule and nothing for a plain clone, for the superproject, and for a
   linked worktree of either of those. If it fails: return 2, `unread`. If `sp`
   is not empty: return 1, `submodule`, whatever the origin reads (decision D9).
   Else `felix_remote_github_slug "$u"` equal to the normalised `m`: return 0,
   `own`; else return 1, `other`.
5. The `.felix` marker is never read here. A substring match is never enough.
6. The origin URL is never printed, logged or written anywhere (an https URL
   can carry a token as userinfo).
7. The function's comment says, in substance: this corroborates the binding
   against the clone's own `origin`, which a plain clone's tree cannot choose;
   a submodule's `origin` comes from the superproject's tracked `.gitmodules`,
   so a submodule is refused; and it does not defend a checkout whose `.git` came
   from an attacker, which controls its own config and code git runs, and that
   is out of Felix's reach and not claimed.

### `felix_own_gate <kind> <status>` (lib/own.sh)

Returns 0 when `<status>` is `0`. Otherwise appends `<kind>` to the global
`_FELIX_OWN_WITHHELD` (`, `-joined, a kind already present not added twice)
and returns 1. Kinds used: `adoption`, `graph refresh`, `tidying`,
`commissioning`.

### `felix_own_withheld_line <proj> <root> <home>` (lib/own.sh)

Prints nothing when `_FELIX_OWN_WITHHELD` is empty. Otherwise calls
`felix_checkout_is_own "$proj" "$root"` for `_FELIX_OWN_WHY` and composes:

```
Nothing ran here unattended: <project> is bound to this checkout <B>, and <R>. Withheld: <K>.
```

- `<project>`: `basename "$proj"`.
- `<B>`: `by its .felix marker` when `$root/.felix` is a file; otherwise
  `by an origin that only contains <remote_match as written in project.json>`.
- `<R>` by `_FELIX_OWN_WHY`:
  - `other`: `its origin is not github.com/<remote_match as written>`
  - `no-origin`: `it has no origin remote`
  - `submodule`: `it is a submodule, whose origin the repository holding it chooses`
  - `no-match`: `<project> declares no remote_match naming a github.com owner/repo, so no checkout is its own`
  - `unread`: `its origin could not be read`
- `<K>`: `_FELIX_OWN_WITHHELD` as accumulated.

Said once per checkout and set of kinds: the key is `<root>\t<K>`, kept one a
line in `$home/state/own/<project>.seen`. When the key is already there it
prints nothing. Otherwise it prints a blank line, then the line (so the caller
appends it as a paragraph: `\n\n<line>`), and appends the key. A key whose
root or kinds hold a tab or a newline is not recorded, and the line is said
each time. A `.seen` that cannot be written does not stop the line.

### `felix_commission_resume_bg <proj> <home> <bin>` (moved to lib/own.sh)

Unchanged in its first five refusals and their order (no executable bin; no
`felix_autonomy_commission_current`; grant not current; no commissioning.tsv;
no root; no log directory), and all of them stay silent. Then, new:

```
felix_checkout_is_own "$proj" "$root"; [ $? -eq 0 ] || {
  printf '%s\trefused-not-own\t%s\n' "<UTC ts>" "$root" >> "$log"
  felix_own_gate commissioning 1; return 0; }
```

then the detached run exactly as today. It runs in the caller's shell up to the
`&`, so the `felix_own_gate` it calls reaches the session-start shell.
`lib/commission.sh` ends (or its loader loop gains) a source of `own.sh` when
`felix_commission_resume_bg` is not defined, so every caller that sources
commission.sh alone (part 0580) still finds it.

### `felix_neutral_dir <prefix>`, `felix_neutral_rm <path> <prefix>`, `felix_neutral_run <proj> <prefix> <cmd> [args...]` (lib/reach-read.sh)

- `felix_neutral_dir` is the directory-making half of `felix_reach_read`
  (reach-read.sh:170-195) moved into a function and called from there. It
  returns 0 with `_FELIX_NEUTRAL_DIR` set to the physical path of a fresh
  `"$phys/<prefix>.XXXXXX"` under `TMPDIR`; 1 when `TMPDIR` is not absolute;
  2 when it is not private (`_felix_reach_private`); 3 when the directory
  could not be made, entered or trusted (a `/` TMPDIR included); 4 when a
  `.mcp.json` sits at or above it (`_felix_reach_neutral`). `<prefix>` must
  match `^[a-z][a-z-]*$` or it returns 3. On 3 and 4 nothing it made is left.
- `felix_reach_read` maps 1-4 to its existing `_FELIX_REACH_WHY` sentences
  byte for byte and keeps the `felix-reach` prefix. `_felix_reach_rm "$x"`
  becomes `felix_neutral_rm "$x" felix-reach`. Parts 1100, 1110 and 1120 pass
  with no edit.
- `felix_neutral_rm` removes only an absolute `/*/<prefix>.??????` that is a
  directory and not a symlink; always returns 0.
- `felix_neutral_run`: `felix_neutral_dir <prefix>` or return 125; write
  `basename <proj>` and a newline to `<dir>/.felix`, or remove and return 125;
  `felix_repo_root <dir>` must print `<dir>` (no `.git` above it, no `GIT_DIR`
  answer), or remove and return 125; then `( cd <dir> && <cmd> [args...] </dev/null )`
  with stdout passed through; remove the directory; return the command's
  status. Never runs the command in any other directory.

---

## 4. Behaviours

Each says what is observable. "Unowned" means a checkout bound to the project
for which `felix_checkout_is_own` does not return 0. "The stubs" are section 6.

### The predicate

- **B1** `felix_remote_github_slug` prints `ownerx/ownp-repo` for each of:
  `https://github.com/OwnerX/ownp-repo`, `https://github.com/OwnerX/ownp-repo.git`,
  `https://GitHub.com/ownerx/OWNP-REPO.git/`, `https://tok@github.com/OwnerX/ownp-repo.git`,
  `https://github.com:443/OwnerX/ownp-repo`, `git@github.com:OwnerX/ownp-repo.git`,
  `github.com:OwnerX/ownp-repo`, `ssh://git@github.com/OwnerX/ownp-repo.git`,
  `ssh://git@github.com:22/OwnerX/ownp-repo`, `git://github.com/OwnerX/ownp-repo.git`.
- **B2** It prints nothing and returns 1 for each of:
  `git@evil.example:OwnerX/ownp-repo.git`, `https://github.com.evil.example/OwnerX/ownp-repo`,
  `https://evil.example/github.com/OwnerX/ownp-repo`,
  `https://github.com/OwnerX/ownp-repo/extra`, `https://github.com/OwnerX`,
  `http://github.com/OwnerX/ownp-repo`, `file:///tmp/ownp-repo`, `/tmp/ownp-repo`,
  `git@github.com:/OwnerX/ownp-repo`, `https://github.com/OwnerX/ownp-repo?x=1`,
  `https://github.com/Owner X/ownp-repo`, `https://evil.example#@github.com/OwnerX/ownp-repo`,
  `https://evil.example?@github.com/OwnerX/ownp-repo`,
  `https://evil.example\@github.com/OwnerX/ownp-repo` (found in review: a `?` or
  `#` ends the authority, so the host is `evil.example`), the empty string. The fork URL
  `https://github.com/OwnerX/ownp-repo-fork.git` is a valid slug: it prints
  `ownerx/ownp-repo-fork` and returns 0, and B4 is where it is refused.
- **B3** For a project whose remote_match is `OwnerX/ownp-repo`,
  `felix_checkout_is_own` returns 0 with `_FELIX_OWN_WHY=own` in checkouts
  whose origin is any B1 spelling, a worktree of such a checkout included.
- **B4** It returns 1 with `other` for origins `git@evil.example:OwnerX/ownp-repo.git`,
  `https://github.com/OwnerX/ownp-repo-fork.git`, `https://github.com.evil.example/OwnerX/ownp-repo`,
  `https://evil.example#@github.com/OwnerX/ownp-repo`;
  1 with `no-origin` for a repository with no origin; 1 with `no-match` for a
  project whose remote_match is empty, absent, `example.com`, or
  `a/b/c`, whatever the origin, a `.felix` naming the project included.
- **B5** It returns 2 with `unread` for a directory that is not a repository,
  and for a repository when `git` on PATH is a stub that exits 69.
- **B6** A `.felix` marker changes none of B3-B5: the same origin gives the
  same answer with and without a marker.
- **B7** Nothing the predicate writes (stdout, stderr, any file) contains the
  origin URL; asserted with origin `https://SECRETTOKEN@github.com/OwnerX/ownp-repo.git`
  by grepping every file the session start wrote under the scratch home and
  memory root, and the hook's output, for `SECRETTOKEN`.
- **B8** (found in review) A checkout that is a submodule is not own: the
  predicate returns 1 with `submodule` although its `origin` is exactly the
  project's. Asserted with a local superproject whose tracked `.gitmodules` url
  is `https://github.com/OwnerX/ownp-repo`, cloned with `--recurse-submodules`
  and an `insteadOf` that serves that url from a local bare repository (offline);
  first as a control, that the submodule's `origin` reads as the project's and
  `felix_remote_github_slug` accepts it. The superproject, once its own origin is
  the project's, is still own (0), as a plain clone and a linked worktree of an
  own checkout are (B3). When `git rev-parse --show-superproject-working-tree`
  fails, the predicate returns 2 with `unread`.
- **B9** (found in review) A session start in that submodule runs, in effect,
  none of the unattended work (it carries a `.felix` naming the project, a
  current `commission` and `tidy` grant, an untracked rival the project holds a
  copy of, and then an undeclared `Cargo.toml`): the `felix` stub is not run
  with `commission` and `bg.log` gains one `refused-not-own` line and no `ran`;
  the rival is kept byte-identical; nothing is adopted into the project's
  `capabilities`. The context's last paragraph is the one line, with `it is a
  submodule, whose origin the repository holding it chooses` as `<R>`, naming
  `tidying, commissioning`, and then `adoption, tidying, commissioning`. A graph
  refresh is never due in a submodule: `felix_graph_home` is the parent of its
  gitdir, which holds no graph, so that kind is never named there.

### Commissioning (P1)

- **B10** In an own checkout of a project whose `commission` grant is current,
  a session start runs the `felix` stub once with argument `commission` and
  working directory the checkout root, and `bg.log` gains `\tran\t<root>`.
- **B11** In each unowned checkout (lookalike host, fork suffix, no remote,
  substring-bound without `.felix`), the same session start does not run the
  `felix` stub with `commission` at all, and `bg.log` gains exactly one line
  `<YYYY-MM-DDTHH:MM:SSZ>\trefused-not-own\t<root>`.
- **B12** Ungranted, stale-stamped or tableless projects stay silent in an
  unowned checkout: no `bg.log` line of any kind (part 0580's "an ungranted
  project starts no background run" keeps passing unchanged).
- **B13** End to end with the real CLI: with a commissioning.tsv whose one row's
  check calls `gh` (for example `gh repo view >/dev/null 2>&1`; if the table's
  filter refuses that shape, any accepted check that calls `gh`), a granted
  session start in an own checkout makes the `gh` stub log the own root; in
  the lookalike checkout the `gh` stub logs nothing and the checkout gains no
  `.github/` directory.

### Discovery (P2)

- **B14** In an own checkout and in an unowned one alike, a session start with
  a stale or absent cache runs the `felix` stub with
  `discover --inspect --quiet`, from a working directory that matches
  `<TMPDIR>/felix-discover.??????`, where a `.felix` holds the project name,
  and never from the checkout.
- **B15** The cache `$home/state/discover/<project>.tsv` is the stub's stdout
  on success; on a non-zero stub exit the previous cache is unchanged and no
  `.new.*` file is left; the lock is gone and `TMPDIR` holds no
  `felix-discover.*` once the refresh ends.
- **B16** With `TMPDIR` unset, relative, non-private, or under a `.mcp.json`,
  the refresh runs no `felix` and no `claude`, writes no cache, and leaves no
  lock.
- **B17** The `claude` stub is never run with the checkout as its working
  directory by anything a session start launches (discovery, reach, or
  anything else), in own and unowned checkouts alike. (Commissioning in an own
  checkout is excluded: it runs `felix commission` there by design, and the
  stub felix does not call claude.)

### Graph refresh (P3)

- **B18** In an own checkout whose graph reads behind, with `graphify` on PATH,
  a session start runs the `graphify` stub once as `update <graph home>` with
  working directory the graph home.
- **B19** In an unowned checkout in the same state, the `graphify` stub is not
  run, and the graph line (`Knowledge graph: N commit(s) behind ...`) is still
  in the context.

### Tidying (P4)

- **B20** In an own checkout of a project granted `tidy`, an untracked
  executable `scripts/prepush.sh` whose name the project holds is removed,
  backed up under `$home/state/rivals/`, and the context says
  `Removed, as copies Felix already holds: scripts/prepush.sh`.
- **B21** In an unowned checkout in the same state the file is still there,
  byte-identical, and the context holds no `Removed, as copies` line.

### Adoption (P6)

- **B22** In an own checkout holding a file `felix_detect` maps to an
  undeclared capability (`Cargo.toml` -> `rust`), a session start appends
  `rust` to `projects/<p>/capabilities` and the context says
  `Adopted automatically, because the checkout grew them: rust(...)`.
- **B23** In an unowned checkout in the same state, `capabilities`, `stack.tsv`,
  `setup.tsv` and `setup/` are byte-identical before and after, and the
  context holds no `Adopted automatically` and no `Not adopted` line.

### The one line

- **B30** In an unowned checkout where one or more of B11, B19, B21, B23 was
  withheld, the context's last paragraph is exactly one line of section 3's
  shape, kinds in the order `adoption, graph refresh, tidying, commissioning`
  restricted to those withheld. Example, the `lookalike` ownp checkout
  (`.felix`-bound, origin `git@evil.example:OwnerX/ownp-repo.git`, graph
  behind, a held rival present, grant current, nothing undeclared):
  `Nothing ran here unattended: ownp is bound to this checkout by its .felix marker, and its origin is not github.com/OwnerX/ownp-repo. Withheld: graph refresh, tidying, commissioning.`
  And an ownq checkout with the same origin and an undeclared `Cargo.toml`
  (ownq granted nothing, its graph removed): `... Withheld: adoption.`
- **B31** The `substring` checkout (no `.felix`, same origin, same state as
  `lookalike`): `Nothing ran here unattended: ownp is bound to this checkout by an origin that only contains OwnerX/ownp-repo, and its origin is not github.com/OwnerX/ownp-repo. Withheld: graph refresh, tidying, commissioning.`
- **B32** No remote at all: `<R>` is `it has no origin remote`; a project with
  no remote_match: `<R>` is `ownq declares no remote_match naming a github.com owner/repo, so no checkout is its own`.
- **B33** A second session start in the same checkout with the same kinds
  withheld adds no line; a different checkout, or the same checkout with a
  different set of kinds, adds it again.
- **B34** An own checkout's context never holds `Nothing ran here unattended`;
  nor does an unowned one where nothing was due (no grant, nothing
  undeclared, graph current or absent).
- **B35** The line is in `additionalContext` only. The `systemMessage` status
  line (`Felix: <project>...`) is unchanged.

### Size and shape

- **B40** `wc -l` of `hooks/session-start`, `lib/commission.sh` and
  `lib/discover.sh` is no larger than 726, 731 and 1516; `lib/own.sh`,
  `lib/reach-read.sh` and the new part are under 500.
- **B41** `lib/own.sh` names no governed project (the gate's engine-names-no-
  project check passes) and runs under `/bin/bash` 3.2.
- **B42** If `lib/own.sh` cannot be sourced, every gated path fails closed:
  nothing in P1, P3, P4, P6 runs in any checkout and the hook still emits its
  JSON.

---

## 5. What must not change

- **Attended commissioning.** `felix commission` typed by a person runs in any
  checkout, unowned included, with today's output and exit codes. `--status`
  likewise. The CLI is not edited.
- **The binding.** `felix_resolve_project` (marker first, substring second),
  `felix_binding_broken`, `felix_hook_enter`: unchanged. An unowned checkout
  still resolves to its project and still gets every context line (gate,
  maintenance, graph, retire, reconcile, backup, read lines, overnight,
  discovery's `Worth a look`, every commissioning paragraph), every deny row,
  the gate, and the Stop hold.
- **Own checkouts.** Each of P1, P3, P4, P6 runs in an own checkout exactly as
  on main: same command, same working directory, same log lines, same context
  lines.
- **Discovery for everyone.** The refresh still runs for every project with
  `routes.tsv` and `claude`, own or not, with the same staleness rule, lock,
  cache path and stamp. Only its working directory changes.
- **The reach refresh.** Same directory prefix, same sentences, same cache;
  parts 1100-1120 unedited and passing.
- **The record phase and the `.seen` files** (decision D4).
- **The libraries the gates sit in front of.** `felix_tidy_safe`,
  `felix_graph_refresh_bg`, `felix_adopt_capability`, `felix_undeclared` are
  unchanged; parts 0580 and 0760 pass unedited. The gates are at the
  session-start call sites, except the commissioning gate, which is inside
  `felix_commission_resume_bg` because the brief puts its log line there.
- **No deny rows** of any kind are added or proposed. The pulse is untouched.

---

## 6. Tests

### 6.1 Where

New part `tests/parts/1130-unattended-work-runs-only-in-its-own-checkout.sh`,
sourced from `tests/run` after 1120. It may use what parts 1100-1120 leave in
the suite shell: `RXBASE` (a private base that is not under a world-writable
`/tmp` on a Linux runner), `_rx_wait`, `FROOT`, `FELIX`.

### 6.2 Fixtures

- `OW="$(mktemp -d "$RXBASE/ow.XXXXXX")"`, physical path; `OWT="$OW/tmp"` at
  0700 is the `TMPDIR` of every hook run.
- A harness copy `OW/h/harness` (`cp -R "$FROOT/harness"`), whose `felix` is
  replaced by the felix stub, so the hook's `${SCRIPT_DIR}/../felix` is the
  stub. The hook run is `OW/h/harness/hooks/session-start`, with
  `FELIX_HOME="$OW/home"`, `FELIX_MEMORY="$OW/mem"`, `HOME="$OW/user"`,
  `TMPDIR="$OWT"`, `PATH="$OW/bin:$PATH"`, stdin a SessionStart payload.
  B13 alone uses a second harness copy whose `felix` is the real CLI.
- Scratch home `OW/home/projects/`:
  - `ownp`: `project.json` with `"remote_match": "OwnerX/ownp-repo"` and a gate;
    `CLAUDE.md`; `autonomy` naming `commission` and `tidy`; `routes.tsv` (one
    valid row); `commissioning.tsv` the suite's minimal valid table
    (`marker\t-\t-\t-\t-\ttest -f .felix\t9`; for B13 a second copy whose check
    calls gh); `prepush.sh` (executable); `capabilities` listing every
    capability `felix_detect` reports for the ownp fixtures, so no session
    adopts and the commission stamp stays current; `autonomy.commission`
    written last from `felix_commission_policy_version`.
  - `ownq`: no grants, empty `capabilities`, for B22-B23 and the `no-match`
    wording a copy with no remote_match.
- Checkouts under `OW/co/<name>`, each `git init -b main`, `.felix` naming the
  project (except the substring case), two commits, an untracked executable
  `scripts/prepush.sh`, and `graphify-out/graph.json` whose tail carries
  `"built_at_commit": "<first commit sha>"` (so it reads 1 behind). The ownq
  checkouts also hold `Cargo.toml`. Origins, set with
  `git -C <dir> config remote.origin.url <url>` inside the part:
  `own-https` `https://github.com/OwnerX/ownp-repo`;
  `own-scp` `git@github.com:OwnerX/ownp-repo.git`;
  `own-case` `https://GitHub.com/ownerx/OWNP-REPO.git/`;
  `own-ssh` `ssh://git@github.com/OwnerX/ownp-repo.git`;
  `lookalike` `git@evil.example:OwnerX/ownp-repo.git`;
  `fork` `https://github.com/OwnerX/ownp-repo-fork.git`;
  `none` no origin;
  `substring` `git@evil.example:OwnerX/ownp-repo.git` with no `.felix`.
- The deny row in `projects/felix/deny.tsv` refuses a typed command carrying
  `remote add`, even in scratch; set origins inside the part file, which the
  suite runs and the hook does not judge.

### 6.3 Stubs (all in `OW/bin`, except felix in the harness copy)

Each appends `$(pwd -P)\t$*` to its own log and exits 0 unless taught
otherwise:

- `felix`: also appends `.felix=<contents of ./.felix or ->`; for
  `discover --inspect --quiet` prints one line `# stamp stub` (exit status from
  `OW_FELIX_RC`, default 0).
- `claude`: answers `plugin list --json --available` with `[]` and `mcp list`
  with nothing; any other shape exits 2 after logging.
- `gh`, `graphify`: log only.
- `git` failing (B5 only, on a PATH of its own): exits 69. A second one for B8
  exits 69 only for `--show-superproject-working-tree` and otherwise runs the
  real git.

Every detached launch is waited for with `_rx_wait` on its lock or log
(`$home/state/discover/.lock` gone; `graphify-out/.felix-refresh.lock` gone;
`bg.log` line present), never with a bare sleep; the negative cases wait on
the same conditions, plus the positive control run first in the same state, so
"nothing ran" cannot pass on a stub that was never reachable.

### 6.4 Existing parts whose fixtures change

Session-start adoption now needs an own checkout. Parts that assert
`Adopted automatically` or adoption's table writes from `hooks/session-start`
(0030, 0060 at its HOOKREPO and `_anl4` runs; 0200 asserts the negative and
should keep passing) get an origin in their fixture checkout that the bound
project's remote_match names (the widget fixture's `example.com/widget` is
own for `https://github.com/example.com/widget`, since a `.` is allowed in a
segment). Their assertion names and expected values do not change. Any other
part that compares a whole session-start output and now sees the B30 line gets
the same fixture change, not a new expectation. The builder runs the parts
that drive `hooks/session-start` (20 of them by `grep -l`) one at a time.

### 6.5 Red

Against the base engine: B11, B19, B21, B23 fail (main runs them in the
unowned checkouts), B14 fails (main runs discovery in the checkout), B1-B7 and
B30-B33 fail (no such functions or line). B10, B18, B20, B22 pass on main:
they are the positive controls, and must.

---

## 7. Decisions taken where the brief left a choice

### D1. Discovery runs from a private empty directory, for every project

Evidence (section 1, P2): the refresh needs the checkout only so that
`resolve_or_die` can bind (felix:2871); after that, every function on the
`--inspect --quiet` path reads the home, the templates, the user-scope plugin
listing, and a scratch fetch under `TMPDIR`. discover.sh:1480 is the only line
in that file that reads `$PWD`. What running in the checkout adds is
`claude`'s reading of the checkout's own settings, which is the hazard: the
cache is per project and feeds `felix discover --adopt`. So refusing would cost
every unowned checkout its refresh for nothing; a neutral directory keeps it
for every project and removes the checkout's influence. The binding is kept by
a `.felix` that `felix_neutral_run` writes into a directory it made itself,
which is the marker mechanism used as designed, not a change to resolution.
The directory comes from the same code that makes reach's
(`felix_neutral_dir`, extracted, not copied), under the same `TMPDIR` rules.

### D2. No attended line in `felix commission`

The brief allowed one. Not added: a person typing the command is the consent;
the session that person types into has already been told, once, by B30 that
the binding came from the checkout and that unattended work was withheld; the
`felix` CLI is 6,179 lines and the size rule forbids growing it; and every
`felix commission` the suite runs in its no-remote `.felix` fixture would grow
a line of output, for information the session start already gave. Exit codes
and output stay exactly as on main.

### D3. Adoption at session start is gated (found by this trace)

The brief's own test for the record phase decides it: adoption writes the
bound project's durable, tracked tables from what an unowned tree contains.
And it has a concrete cost today: the three tables it writes are hashed into
the commission policy version, so an unowned checkout bound to a granted
project lapses the grant and dirties the home's tracked files. Gated at the
call site; `felix adopt <capability>` and the adoption inside an attended
`felix commission` are unchanged. Cost, stated: a project with no remote_match
(behaviorchangebench, webapp, elenchus-capital-research on disk today; the
BehaviorChangeBench checkout has no origin) no longer adopts at session start
in any checkout, nor refreshes its graph or tidies; setting a remote_match and
an origin restores all three.

### D4. The record phase and the `.seen` files stay

The answer files live in the memory root, which is outside every checkout by
construction, and a checkout cannot write them; the rows recorded are the
file's, not the tree's. The checkout's influence is the topology hash, which
can only decide whether that memory-root answer is read as answered or stale,
and the tree id stamped in the log row. The residual, stated: an unowned
checkout whose detected surfaces match the own topology can be the session in
which an answer is recorded, stamped with its tree id. The `.seen` append can
only spend the once-per-topology all-clear for that checkout's own topology.
Neither runs anything or writes a table.

### D5. Unknown is refused, and said differently

Only 0 runs. A checkout git cannot answer for (not a repository, an
unaccepted Xcode licence, git missing) is withheld like an unowned one, but
the line says `its origin could not be read` rather than claiming a remote it
never read. `bg.log` says `refused-not-own` for both, keeping its three
columns.

### D6. The line is said once per checkout and set of kinds

The stealth rule: a session hears from Felix briefly. One line, at most once
per (checkout, kinds), so a project used daily from a `.felix` binding hears
it once per worktree, and hears it again only when what was withheld changes
(a grant added, a graph falling behind). `bg.log` keeps every refused
commissioning run for whoever reads it. The line is spent even on a summary
session, which session-start cannot tell apart (session-start:455-470).

### D7. Gates at the call sites, except commissioning

`felix_tidy_safe`, `felix_graph_refresh_bg` and `felix_adopt_capability` are
also reached by attended callers or tested as libraries; gating inside them
would refuse a present person or rewrite tests of logic that has not changed.
The commissioning gate is inside `felix_commission_resume_bg` because the brief
puts its log line in that function's `bg.log`, and because that function has
no attended caller.

### D8. Strict slug, permissive characters

A remote is own only by exact equality of `owner/repo` on `github.com`; the
loose `felix_repo_slug` (detect.sh:233, `.*github\.com[:/]`, which
`https://evil.example/github.com/a/b` satisfies) is not reused. Segments allow
`[a-z0-9._-]`, wider than GitHub's owner names, because equality is what
decides and the fixture remote_match `example.com/widget` should stay usable.

### D9. A submodule is never own (found in review)

`git remote get-url origin` is the corroboration because a plain clone's tree
cannot choose it. For a submodule that is false: git writes the submodule's
`origin` from the superproject's tracked `.gitmodules` url. A hostile repository
can therefore make a submodule own for any governed project whose GitHub repo it
can fork or send a pull request to, since the gitlink commit only has to be
fetchable from that url. Reproduced in a local fixture before the fix: a session
start in the submodule adopted `rust` into the project's `capabilities`, removed
an untracked `scripts/prepush.sh` the project holds a copy of (tidying backs it
up under `state/rivals/` first), and ran `felix commission` there.

Decided: a checkout with a superproject is not own, whatever its origin reads.
The cost is stated: a project whose own repository is consumed as a submodule of
another gets no unattended work inside that submodule; a person typing the
command still gets it. Not claimed: a linked worktree added with `git worktree
add` from inside a submodule shares the submodule's gitdir and its `origin`, and
`--show-superproject-working-tree` prints nothing for it, so it is not refused.
Making one is a person's act on a repository they already hold. Checking the
common gitdir for `.git/modules/` would close part of it and still miss a
superproject whose gitdir is elsewhere, so it is left unclaimed rather than
half-claimed.

---

## 8. Version and record

Main is 0.49.283. Worktree `charming-bartik-58e065` holds 0.49.284; open PRs
hold 0.49.222, 0.49.224 and 0.49.280 (checked 2026-10-13). The next free
version is **0.49.285**; the ship stage re-checks every worktree's
`engine/.claude-plugin/plugin.json` and every open PR's before bumping.
`tests/assertions.tsv` and `tests/red.tsv` are re-recorded with
`tests/run --record-assertions` at ship, under nohup, polled by pid.
