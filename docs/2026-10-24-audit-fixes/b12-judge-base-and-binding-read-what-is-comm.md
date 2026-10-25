# Audit fix b12: judge base and binding read what is committed (contract)

Batch 12 of the 2026-10-24 audit register (`docs/2026-10-24-audit-register.md`, on `claude/audit-fixes`). Branch `claude/audit-b12-judge-base-and-binding-read-what-is-comm`, cut from origin/main at 69b51a61. The brief lists these files: `engine/harness/lib/resolve.sh`, `lib/exceptions.sh`, `lib/ready.sh`, `lib/stack.sh`, `lib/commission-provider.sh` and `docs/2026-09-21-where-felix-stands.md`. Three more files, owned by no batch in the register, are added for C098 because its scenario cannot be fixed without them: `lib/toolbox.sh`, `lib/coverage.sh` and `bin/deploy-check`. Line numbers below are from 69b51a61. Where a skeptic corrected a claim or a severity, this contract follows the correction.

## 1. Defects

- **C009** (high, kept at high by the register; one skeptic said low). The exception reader takes the local ref `refs/remotes/origin/main` as what the remote holds. But `git config` of a fetch refspec or of the origin URL, or a plain file write into the ref, moves that ref, and no deny row refuses any of these. So a session can make a grant it wrote itself read as merged, while `lib/exceptions.sh:9-22,85-97`, the Stop hold and the README say it cannot. *Scenario, as corrected:* in felix-home a session pushes a branch that carries a grant row. It sets `remote.origin.fetch` to `+refs/heads/forged:refs/remotes/origin/main` and runs a plain `git fetch`; later plain fetches keep the forged ref. Or it runs `cp .git/refs/heads/mine .git/refs/remotes/origin/main`. After either, `felix_exception_for` clears the TASK_BLOCKING `engine_deployed` hold at the task moment. Not part of the defect: the merge boundary never reads a grant, because release mode carries no clearance. And a forged base that blinds `felix merge` adds nothing beyond plain `gh pr merge`, which no row refuses (both skeptics).
- **C010** (medium). The enforcing tables and `gate.sh` are read from the home checkout's working tree. For the tables in `FELIX_COMMISSION_TABLES`, an uncommitted home edit stales the commission receipt and `felix merge` refuses (the headline is refuted; see §6). `gate.sh` and `qualification.tsv` are outside that set, though. So a home-only edit to `gate.sh` changes every worktree's local verdict and stales nothing, and a `deny.tsv` edit reaches every session's hooks at once with nothing saying the home is dirty. *Scenario:* a session "fixes" a failing check by editing `~/Documents/Felix/projects/felix/gate.sh`. Every worktree's `felix gate` then passes, and a manual `felix merge` accepts the `tests:ok` receipt. Separately, `docs/2026-09-21-where-felix-stands.md` §4 says obligation admission is read from `refs/remotes/origin/main`, which is false.
- **C031** (medium). A checkout bound only by `remote_match` goes silently ungoverned when its project's `project.json` goes missing, gets renamed or cannot be read, because `felix_binding_broken` (resolve.sh:673-674) reports nothing whenever there is no marker. *Scenario, as corrected:* on this laptop, Documents/Elenchus, Documents/Retnovation and the marker-less worktrees bind by remote. Say iCloud leaves `projects/elenchus/project 2.json` and no `project.json`. Every session there then runs with no banner, no deny rows (Elenchus's force-push row included) and no Stop hold, and nothing is recorded. ReserveGrid is not affected: it has a marker.
- **C046** (medium). `felix_resolve_project` rule 2 (resolve.sh:483-493) binds the first project, in byte order, whose `remote_match` is a case-sensitive substring of the origin URL. *Scenario:* an origin of `acme/webapp` binds to the project `web` (`acme/web`). A clone of `LeavesJ/Elenchus-docs` binds to Elenchus. A lowercase clone of `leavesj/elenchus`, which GitHub accepts, binds to nothing. Each happens silently.
- **C061** (low). `felix_repo_root` (resolve.sh:340-344) loops forever when the path it walks does not start with `/`. When that text does start with `/`, it returns a wrong root instead. Under bash 3.2, a printf that failed leaves its text in the stdout buffer, and the next `$( )` child flushes it ahead of `pwd -P`'s output. *Trigger, as corrected:* a closed pipe kills bash with SIGPIPE first, and the land tick's stdout is a file, so neither triggers it. What triggers it is stdout closed by the caller (or a full disk), then a failed write, then a later `felix_repo_root` in the same process: for example `felix which >&-`.
- **C098** (medium). `CLAUDE_CONFIG_DIR` is honoured by status, inventory, cost and audit. It is ignored by the plugin registry, the plugin cache, the marketplace registry, the skills directory and the `~/.claude.json` readers. *Scenario:* under `CLAUDE_CONFIG_DIR=~/.claude-work`:
  - `felix ready` and `felix stack plan` report every skill missing;
  - commission provenance reads `?`;
  - `felix merge` refuses with "no installed copy of the engine main declares";
  - `bin/deploy-check --applies` finds no cache and exits 1, so the TASK_BLOCKING `engine_deployed` row reads DORMANT and stops blocking. This last effect is permissive; the skeptic's "every effect fails closed" missed it. The CLI sources toolbox.sh, which sets `FELIX_PLUGIN_CACHE` to `$HOME/.claude/plugins/cache`, so fixing resolve.sh alone does not fix the merge.

## 2. Required behaviour

Conventions. Every fixture lives under one `mktemp -d` inside the suite's `$TMP`. It sets `HOME` and `FELIX_MEMORY` there, `GIT_CONFIG_NOSYSTEM=1`, and a git identity through `-c`. Libraries are sourced from `$FROOT/harness/lib` in a subshell, `resolve.sh` first. "Prints nothing" means empty stdout. `<TAB>` is one tab. LIVE is `<this year + 1>-06-01T00:00:00Z`.

### C009: the grant reader asks whether the ref is what a fetch wrote

- **B1. `felix_exceptions_doubt PROJ`** is new, in `lib/exceptions.sh`. REPO is `felix_exceptions_repo PROJ`. When something below doubts REPO's `refs/remotes/origin/main`, it prints one printable line naming the first cause found, in the order (a)-(e). Otherwise it prints nothing, and it prints nothing when that ref does not exist. It exits 0 either way.
  - (a) The ref is a symbolic ref. The line contains `symbolic`.
  - (b) REPO has no `remote.origin.url`. The line contains `no remote named origin`.
  - (c) The fetch configuration. Read every `remote.<r>.fetch` value of every remote. A refspec *writes* the ref when its destination (after one optional leading `+`) equals `refs/remotes/origin/main`, or holds one `*` and matches it. Refspecs starting with `^` and refspecs with no `:` write nothing. The ref is doubted when any writer belongs to a remote other than `origin`, or maps a source other than `refs/heads/main` onto it (for a pattern, the source the `*` yields). It is also doubted when no refspec of `origin` writes it. The line contains `fetch`, and also the key of the offending writer, or `remote.origin.fetch` when nothing writes it.
  - (d) The origin URL. When `PROJ/project.json` declares a non-empty `remote_match`, the output of `git remote get-url origin` (which applies `url.*.insteadOf`) must match it under the binding rule of B21. Otherwise the line contains `remote_match`. The URL itself is never printed.
  - (e) The reflog. When `git reflog exists refs/remotes/origin/main` says a reflog exists, its newest entry must name the ref's current commit. Its message (`%gs`) must also begin with `fetch`, `pull`, `clone` or `update by push`. Otherwise the line contains `reflog`. A ref with no reflog at all is not doubted by (e); that is what `git clone` leaves, and it is a stated limit.
  - Unknown: where git answers one of these questions with an exit status the question does not define (for example 128), the line names that check's word and contains `cannot be read`. It never reads as fine.
  - Read only: it runs no `fetch`, `pull`, `ls-remote`, `remote update` or `gh`, and it changes no ref, reflog or config.
- **B2.** `felix_exception_for` prints nothing and exits 1 whenever `felix_exceptions_doubt` prints a line, whatever the table at the ref holds. With no doubt, its behaviour is unchanged.
- **B3.** Under doubt, `felix_exceptions_judge` prints malformed rows as before. Every well-formed row at the ref is printed as `refused<TAB><obligation><TAB><expires><TAB><granted_by><TAB>not honoured: <the doubt line>`. With no doubt, its output is unchanged.
- **B4.** For a TASK_BLOCKING row whose only grant sits at a doubted ref, `felix_obligations_run PROJ ROOT` (where PROJ and ROOT share a repository) prints column 8 as `-`. With no doubt it prints `excepted|LIVE|the-founder`. In `release` mode column 8 is `-` in both cases, as before.
- **B5.** Doubt does not change these: `felix_exceptions_at_base` still prints the table at the ref, `felix_exceptions_count` still counts its well-formed rows, `felix_exceptions_unmerged` still lists no row the ref holds, and `felix_exceptions_ref` still prints `origin/main`.
- **B6.** Fixture G is a repository R on `main` holding `projects/x/` with these files:
  - `project.json`: `{ "name": "x", "remote_match": "acme/x", "gate": "true" }`;
  - `obligations.tsv`: the single line `ob1<TAB>TASK_BLOCKING<TAB>deterministic<TAB>-<TAB>false<TAB>-<TAB>the fixture's one blocking row`;
  - `exceptions.tsv`: a header comment and `ob1<TAB><first 16 hex of the line's hash><TAB>LIVE<TAB>the-founder<TAB>fixture grant`. The hash is `printf '%s\n' "$line" | git hash-object --stdin`.

  It is committed, then `git config remote.origin.url $T/srv/acme/x.git` (a bare repository) and `remote.origin.fetch +refs/heads/*:refs/remotes/origin/*` are set, `main` is pushed, and R fetches. That is the baseline: the grant clears.

  Each change below, applied alone and undone afterwards, is doubted with the word given:
  - `--replace-all remote.origin.fetch +refs/heads/forged:refs/remotes/origin/main` (`fetch`);
  - `--add remote.origin.fetch +refs/heads/x/*:refs/remotes/origin/*` (`fetch`);
  - a remote `evil` with `remote.evil.fetch +refs/heads/*:refs/remotes/origin/*` (`fetch`);
  - `--unset-all remote.origin.fetch` (`fetch`);
  - `remote.origin.url` pointed at `$T/srv/other/x.git`, a second bare repository holding the same `main` (`remote_match`);
  - `url.$T/srv/other/.insteadOf $T/srv/acme/` (`remote_match`);
  - the ref file `$(git rev-parse --git-common-dir)/refs/remotes/origin/main` overwritten by a shell redirect with a local, unpushed commit that adds the grant, starting from an origin `main` that holds no grant (`reflog`);
  - the same commit written by `printf 'update refs/remotes/origin/main <sha>\n' | git update-ref --stdin` (`reflog`);
  - `git symbolic-ref refs/remotes/origin/main refs/heads/main`, where local `main` carries the grant (`symbolic`);
  - a git that exits 128 on any `reflog` subcommand and runs the real git otherwise, first on PATH (`reflog` and `cannot be read`).

  A repository with no remote, whose `refs/remotes/origin/main` was made by `git update-ref` and holds a grant, is doubted, and its judge line begins `not honoured:`.
- **B7.** In each of these the grant clears and `felix_exceptions_doubt` prints nothing:
  - the baseline;
  - `+refs/heads/main:refs/remotes/origin/main` as origin's only fetch refspec;
  - the default refspec plus `+refs/pull/*/head:refs/remotes/origin/pr/*`;
  - the default plus a remote `upstream` with `+refs/heads/*:refs/remotes/upstream/*`;
  - `remote_match` emptied in R's working-tree `project.json` with the URL pointed elsewhere (no URL check);
  - a fresh `git clone` of the origin (which has no reflog for the ref) whose `main` holds the grant.

  After the forged-ref-file case, one plain `git fetch` removes the doubt. The origin's `main` holds no grant, so the grant then clears nothing.
- **B8.** `lib/exceptions.sh` no longer says the ref "moves only when" something is fetched. Its header says three things: the ref is local; the reader checks its symbolic state, the fetch configuration, the URL and the reflog; and a session that also rewrites the reflog gets past it.

### C010: the status document says where each rule is read from

- **B9.** In `docs/2026-09-21-where-felix-stands.md`, §2's table row "An agent cannot grant itself authority" gets this verdict cell: `False on felix-home today. The grant is read from a local ref, refs/remotes/origin/main, which server protection does not reach. Since 2026-10-24 the reader refuses that ref when its fetch configuration, its reflog or its origin URL shows it was not fetched from the declared remote; that stops an accident and the simple forgeries, not a worker that also rewrites the reflog`. In §4 "Floor and wall", the first list keeps only "model proposals never becoming authority" and "a verdict recomputed by a required check". The second list gains two bullets, first: "exception grants, which are read from `refs/remotes/origin/main`, a local ref: the reader refuses it when the repository's fetch configuration, its reflog or its origin URL shows a hand-made value, which a worker that also rewrites the reflog gets past (corrected 2026-10-24, audit C009)"; and "obligation admission and every table the gate reads, which are read from the home's working tree, uncommitted edits included (corrected 2026-10-24, audit C010)". Nothing else in the document changes.

### C098: one config directory for every reader

- **B10.** `felix_claude_dir` (resolve.sh) prints `${CLAUDE_CONFIG_DIR:-$HOME/.claude}` with no newline, so a set-but-empty variable reads as unset. The global config file is `${CLAUDE_CONFIG_DIR:-$HOME}/.claude.json`, where Claude Code keeps it. A library that may be sourced without resolve.sh (toolbox.sh, coverage.sh) writes the expansion inline.
- **B11.** Every default below goes through B10. An explicit override still wins, in its existing order: a path argument, `FELIX_KERNEL_CACHE`, `FELIX_PLUGIN_CACHE`. When the variable is set, only the moved location is read, never both.
  - In resolve.sh: `felix_registry_field`'s default registry; `felix_kernel_dir`'s and `felix_accepted_deploy_diff`'s cache; `felix_marketplace_root`'s registry.
  - In ready.sh: `felix_ready_inventory`'s registry, `.claude.json` and skills, and `felix_ready_report`'s skill check.
  - In stack.sh: `_FELIX_INLINE` and `_felix_have skill`.
  - In commission-provider.sh: `_felix_commission_installed`'s registry.
  - In toolbox.sh: the `FELIX_PLUGIN_CACHE` default.
  - In `bin/deploy-check`: the `--applies` cache test.
  - In coverage.sh: `felix_coverage_events`'s settings, local settings and plugin `hooks/hooks.json` glob.
- **B12.** Fixture K has two locations. The config directory X holds `skills/sx/`; `plugins/installed_plugins.json` naming `px@m` (version `1.2.3`, gitCommitSha `abc123`); `.claude.json` with `"bx@inline": {}`; `plugins/known_marketplaces.json` with a `felix` entry whose installLocation is `/from/ccd`; `plugins/cache/m/px/1.0.0/`; `settings.json` binding `Stop`; and `plugins/cache/m/px/1.0.0/hooks/hooks.json` binding `PreCompact`. HOME holds `.claude/skills/sh/`, a registry naming `ph@m` (version `9.9.9`), `.claude.json` with `"bh@inline": {}`, a marketplace entry `/from/home`, and `.claude/settings.json` binding `SessionEnd`. A `claude` stub first on PATH prints nothing and exits 0. Every call unsets `FELIX_KERNEL_CACHE` and `FELIX_PLUGIN_CACHE` unless it names them. With `CLAUDE_CONFIG_DIR=X`:
  - `felix_registry_field px version` prints `1.2.3`, and the same call for `ph` prints nothing;
  - `felix_commission_provider_provenance px` prints `px@1.2.3/abc123`;
  - `_felix_commission_installed px` exits 0 and `_felix_commission_installed ph` exits 1;
  - `felix_marketplace_root` prints `/from/ccd`;
  - after sourcing toolbox.sh, `FELIX_PLUGIN_CACHE` is `X/plugins/cache`, and `felix_toolbox_path px` prints `X/plugins/cache/m/px/1.0.0`;
  - `felix_ready_inventory` lists `skill<TAB>sx`, `plugin<TAB>px` and `plugin<TAB>bx`, and none of `sh`, `ph` or `bh`;
  - with a project whose `routes.tsv` row plays `sx` and whose `stack.tsv` declares `skill<TAB>sx<TAB>-<TAB>low<TAB>always`, `felix_ready_report` prints `usable<TAB>sx<TAB>skill, always available`;
  - `felix_stack_plan` over `skill sx` and `plugin bx` rows prints `present<TAB>skill<TAB>sx<TAB>-` and `present<TAB>plugin<TAB>bx<TAB>-`;
  - `felix_coverage_events` lists `Stop` and `PreCompact`, and not `SessionEnd`.

  A repository R2 on `main` commits `engine/.claude-plugin/plugin.json` declaring version `7.7.7`. Then:
  - with `X/plugins/cache/felix/felix/7.7.7/harness/` present, `felix_kernel_dir R2 main` prints that path;
  - `FELIX_PLUGIN_CACHE=P` or `FELIX_KERNEL_CACHE=K` still wins, giving `P/felix/felix/7.7.7/harness` or `K/7.7.7/harness`;
  - with no cache under X, `felix_accepted_deploy_diff R2 main` exits 2 and prints `cannot examine: no felix cache at X/plugins/cache/felix/felix`;
  - run in R2, `bin/deploy-check --applies` exits 0 when `X/plugins/cache/felix/felix/` exists, and 1 when neither X nor HOME has it.

  With the variable unset or empty, each of these reads HOME's copy, as today.
- **B13.** A lint covers `engine/harness/felix` and every file directly under `engine/harness/lib/`, `bin/` and `hooks/`. It counts every line that, after leading blanks, does not start with `#`, contains `$HOME/.claude`, `"$HOME"/.claude` or `${HOME}/.claude`, and does not contain `CLAUDE_CONFIG_DIR`. Only six files may hold a counted line. Four are other batches' files: `felix`, `lib/green-tick.sh`, `lib/green-install.sh` and `lib/discover.sh`. Two honour the variable on the line above: `lib/cost.sh` and `lib/audit.sh`.

### C046: binding by the remote is exact on GitHub, anchored elsewhere, and refuses a tie

- **B21. The rule.** The marker rule is unchanged and still wins. Without a marker, U is `git remote get-url origin` of the checkout root. For each project whose `project.json` declares a non-empty `remote_match` M:
  - Suppose M has the form owner/repo (exactly two non-empty parts of `[A-Za-z0-9._-]` joined by one `/`) and `felix_remote_github_slug U` (lib/own.sh) prints a slug S. Then the project matches exactly when M, lowercased, equals S. There is no other way to match in that case.
  - Otherwise, let U′ be U with one trailing `/` and then one trailing `.git` removed, and M′ be M with one trailing `.git` removed. The project matches when U′ equals M′, or U′ ends with M′ and the character before M′ is `/`, `:` or `@`. This comparison is case-sensitive.
  - Among the matching projects the longest M′ wins. When two or more share the longest length, nothing is bound: `felix_resolve_project` prints nothing and exits 1, and B23 reports it.
  - The result is the same in C and in UTF-8 locales. Reading each `project.json` costs what it does today and adds no process per project.

  The binding reads GitHub URLs exactly as `felix_remote_github_slug` does, by calling it or by a copy that A-items 76 and 77 pin to it.
- **B22.** Fixture B is a home with these projects: `web` (`acme/web`), `webapp` (`acme/webapp`), `el` (`LeavesJ/Elenchus`), `gl` (`https://gitlab.example/acme/api`), `s1` (`team/svc`), `s2` (`gitlab.example/team/svc`), `ex` (`example.invalid/pcwd-remote`), `dup1` and `dup2` (both `acme/dup`), and `nomatch` (`""`). Checkouts are made by `git init` plus `git config remote.origin.url U`, with no marker. Each U binds as shown (`none` means exit 1 and nothing printed):

  | U | binds |
  |---|---|
  | `https://github.com/acme/webapp.git` | webapp |
  | `git@github.com:acme/web.git` | web |
  | `ssh://git@github.com/acme/webapp.git` | webapp |
  | `https://github.com/LeavesJ/Elenchus-docs.git` | none |
  | `https://github.com/leavesj/elenchus.git` | el |
  | `https://github.com/LeavesJ/Elenchus.git` | el |
  | `https://b12tok:SECRET-b12@github.com/LeavesJ/Elenchus.git` | el |
  | `https://gitlab.example/acme/api-gateway.git` | none |
  | `https://gitlab.example/acme/api.git` | gl |
  | `git@gitlab.example:team/svc.git` | s1 |
  | `https://gitlab.example/team/svc.git` | s2 |
  | `https://gitlab.example/xteam/svc.git` | none |
  | `https://example.invalid/pcwd-remote.git` | ex |
  | `https://github.com/acme/dup.git` | none (a tie) |

  A checkout whose `.felix` names `web` and whose origin is `acme/webapp` binds to `web`.
- **B23.** For the tie, `felix_binding_broken CHECKOUT HOME` prints a sentence that names `dup1` and `dup2` and contains `remote_match`. Run in that checkout, `hooks/session-start` with a startup payload prints output containing `binding broken`, and `hooks/stop` with a Stop payload (`stop_hook_active` false, a session id) prints a `"decision": "block"` object.
- **B24.** Take a home whose only project declares `OWNERX/OWNP-REPO`, and run each URL that part 1130 lists as own or not own (1130:144-155). `felix_resolve_project` binds exactly when `felix_remote_github_slug U` prints `ownerx/ownp-repo`.

### C031: a remote binding that was there and went missing is reported

- **B25.** `felix_binding_broken START HOME` records bindings. When the checkout has no marker and binds by B21 to project P, it makes sure the last line of `$(felix_mem_root)/bindings.tsv` keyed to this binding names P. The key is `printf '%s\n%s\n' "$HOME_ARG" "$U" | git hash-object --stdin`, where `$HOME_ARG` is its second argument. A line is `<key><TAB><P><TAB><UTC stamp YYYY-MM-DDTHH:MM:SSZ>`, and is appended only when the last line for that key does not already name P. It still prints nothing and exits 0 for a bound checkout. No file under the memory root holds any part of U. `felix_resolve_project` writes nothing anywhere.
- **B26.** Suppose a checkout with no marker, with origin U and not resolving, has its last line for the key under HOME naming P, and `HOME/projects/P/` is a directory whose `project.json` is missing, not a regular file, or unreadable. Then `felix_binding_broken` prints a sentence. The sentence names P and `project.json`, and the path of `bindings.tsv`. When the directory holds a regular file named `project*.json` other than `project.json`, the sentence names the first one in C order. It never holds U's userinfo.

  It says, roughly: the origin bound this tree to P, recorded at the stamp, and P no longer resolves; nothing is checking it; restore the file, or add a marker; if the project is retired, delete `projects/P/` or its line in `bindings.tsv`.
- **B27.** In that state, `hooks/session-start` (startup payload) prints output containing `binding broken` and P. `hooks/stop` prints a block object whose reason names P. `$(felix_mem_root)/unresolved.log` gains a line. A resume payload stays silent, as for every broken binding.
- **B28.** Each of these prints nothing, exits 0, and the Stop hook says nothing:
  - a checkout whose origin was never bound;
  - a checkout with no origin;
  - P's `remote_match` emptied or changed by hand, or `projects/P/` removed, all of which are deliberate;
  - the same URL under a different home;
  - a memory root that cannot be written, with the checkout bound;
  - an unreadable `bindings.tsv`, which reads as no record (stated limit: a hold in every ungoverned repository would make Felix unusable where it is not adopted);
  - a hand-written line whose project is not a project name (`../x`).
- **B29.** When `projects/el/` is renamed to `projects/el2/`, the checkout binds to `el2`, `felix_binding_broken` prints nothing, and the last line for the key names `el2`.
- **B30.** The marker path is unchanged. A marker naming a missing project prints the existing sentence beginning `The .felix marker in`, and no `bindings.tsv` line changes that.

### C061: the root walk ends

- **B31.** `felix_repo_root` walks only an absolute path. With `pwd` redefined as a shell function printing `stale/Users`, `felix_repo_root DIR` returns within 5 s, run under `perl -e 'alarm 5; exec @ARGV' "$BASH"`. For DIR inside a git repository it prints that repository's `git rev-parse --show-toplevel`, computed before the stub. For DIR outside any repository it prints DIR as given.
- **B32.** Text a failed write left in the shell's stdout buffer does not reach its answer. In a child `"$BASH"` with stdout closed (`exec 1>&-`), after `printf 'felix: something\n'` and, separately, after `printf '/x\n'`, `root="$(felix_repo_root DIR)"` returns within 5 s. Its value equals the top level computed before stdout was closed. This is red on bash 3.2 only; bash 5 discards the buffer.

### Constraints on the fix

- **K1.** `resolve.sh` must end at or under 1872 lines and `commission-provider.sh` at or under 633; the other files stay under 500. Room in resolve.sh is made by condensing comments, keeping every claim that still holds.
- **K2.** No new library file. resolve.sh stays sourceable on its own from a temporary directory, which is how felix:1868 and the gate read it out of the base ref. So `felix_accepted_deploy_diff` and everything it calls stay in resolve.sh.
- **K3.** The code runs under bash 3.2 and 5, with no associative arrays and no `case` inside `$( )`. Digit brackets are spelled `[0123456789]`. `LC_ALL=C` goes on every tool reading bytes the engine did not write (project.json, git config, reflog and URL output), and on a `local` line where collation decides. No gawk-only builtins are used. `shopt` changes are put back before return.
- **K4.** No network on any path. Do not edit `tests/assertions.tsv`, `tests/red.tsv`, `engine/.claude-plugin/plugin.json`, `HANDOFF.md` or `docs/handoff/`. The engine names no project.

## 3. What must not change

- **The marker binding, broken-marker and pointer sentences, and the silence of an absent binding** (no marker, no matching remote, never bound) in hooks and CLI. Pinned by 0010-resolution.sh, 0220-the-binding-itself.sh and 0204-hooks-stand-where-the-session-stands.sh, which also pins felix_hook_dir and its CPU bounds.
- **Remote-bound fixtures keep their project:**
  - 0204 (`example.invalid/pcwd-remote`);
  - 0994-bash-s-own-collation-and-the-bsd-text-tools.sh (`example.com/lgbb-caf` against `git@example.com:acme/example.com/lgbb-caf.git`);
  - 0996-continued.sh (G1: Web and web-admin; its locale-invariance assertions still hold, and it now binds web-admin);
  - 0050-appends-that-fail-paths-that-are-not-files-a.sh (a FIFO at a project.json is skipped);
  - 0060, 0750, 1020, 1130-unattended-work-runs-only-in-its-own-checkout.sh and 1340-stuck-pr-page-amendments-blind.sh;
  - the reach fixture, 1100-1120.
- **Bases and the judge:** `felix_base_ref`, `felix_kernel_dir` with its overrides, `felix_accepted_deploy_diff` and its exit codes, and `deploy-check` exits 0/1/2/126/127. Pinned by:
  - 0110-a-base-ref-that-is-behind-its-remote.sh;
  - 0340, 0090 and 0440-gate-installed-the-deployed-engine-is-the-on.sh;
  - 0430, 0640 and 0720;
  - 0004-the-widget-fixture.sh;
  - 1282-1285;
  - 1400-1403 (judge-refs residue).
- **Grants:**
  - every assertion in 0780-exceptions-the-scoped-exception-channel.sh (push-and-fetch grants clear, a local unpushed grant clears nothing, the report heads and counts, unmerged rows, release mode);
  - 0970-membership-in-a-list-larger-than-a-pipe-cove.sh, whose `felix_exceptions_at_base` and `felix_exceptions_unmerged` read an `update-ref`-made ref in a repository with no remote, so those two functions must not apply the doubt;
  - 1080-the-stop-hook-holds-once-per-session-per-tre.sh, which pins the Stop text this batch leaves alone.
- **Readers with explicit overrides or default HOME:**
  - 0590-the-pre-flight.sh, 0580, 0600 and 0710;
  - 0070, 0670 and 0671 (stack plan);
  - 0996 G2 (`felix_toolbox_path` with `FELIX_PLUGIN_CACHE` set) and 0310;
  - 0330 (registry field);
  - 0380 and 0430 (coverage events);
  - 1100 (status D12) and 1050 (cost).
- **felix_repo_root's roots:** a `.git` file, a `GIT_DIR` fallback, and a directory outside git returned as given. Pinned by 0001, 0005, 0200, 0204, 0110 and 0340.
- **9990-the-run-stayed-inside-its-temporary-directory.sh.** `bindings.tsv` goes under `FELIX_MEMORY`, which the suite points into `$TMP`. Also the locale and awk lints (0992-0996, 1497).

## 4. Assertions

[red] fails on 69b51a61. [control] holds before and after. Unless named otherwise, each runs under bwk and gawk.

**Part 1850 (fixture G: B6; fixture K: B12)**

1. B6/B7 [control]: on the baseline, `felix_exception_for` prints `excepted|LIVE|the-founder` and exits 0.
2. B1 [control]: on the baseline, `felix_exceptions_doubt` prints nothing.
3. B4 [control]: on the baseline, `felix_obligations_run` prints column 8 `excepted|LIVE|the-founder`.
4. B2 [red]: with origin's refspec replaced by `forged`, `felix_exception_for` prints nothing and exits 1.
5. B3 [red]: in that state, `felix_exceptions_judge` prints `refused<TAB>ob1<TAB>LIVE<TAB>the-founder<TAB>not honoured: …` and the why contains `fetch`.
6. B4 [red]: in that state, column 8 is `-`.
7. B2/B6 [red]: the added glob `refs/heads/x/*` doubts the ref (exit 1, judge why contains `fetch`).
8. B2/B6 [red]: so does a remote `evil` that writes into `refs/remotes/origin/*`; the doubt line names `remote.evil.fetch`.
9. B2/B6 [red]: so does an origin with no fetch refspec.
10. B7 [control]: each of the four benign refspec sets clears the grant.
11. B2/B6 [red]: with the ref file overwritten by a local grant commit, `felix_exception_for` exits 1 (it cleared on 69b51a61) and the judge why contains `reflog`.
12. B7 [control]: after one plain fetch, `felix_exceptions_doubt` prints nothing and `felix_exception_for` exits 1.
13. B2/B6 [red]: `update-ref --stdin` doubts the ref, with `reflog`.
14. B7 [control]: in a fresh clone whose main holds the grant, the grant clears.
15. B2/B6 [red]: the URL pointed at `srv/other` doubts the ref, with `remote_match`.
16. B2/B6 [red]: the `insteadOf` rewrite doubts the ref, with `remote_match`.
17. B7 [control]: with `remote_match` emptied in the working tree and the URL elsewhere, the grant clears.
18. B2/B6 [red]: the symbolic ref doubts the ref, with `symbolic`.
19. B2/B6 [red]: in the repository with no remote and an update-ref'd origin/main holding a grant, `felix_exception_for` exits 1 and the judge why begins `not honoured:`.
20. B1 [red]: with git failing on `reflog`, `felix_exception_for` exits 1 and the doubt line contains `reflog` and `cannot be read`.
21. B1 [control]: a logging git wrapper records no `fetch`, `pull`, `ls-remote` or `remote update` (and a gh stub records no call) while `felix_exception_for`, `felix_exceptions_judge` and `felix_exceptions_doubt` run, both on the baseline and on the forged refspec.
22. B1 [control]: `git for-each-ref`, `git reflog show refs/remotes/origin/main` and `git config --list --local` are byte-identical before and after those calls.
23. B5 [control]: on the forged refspec, `felix_exceptions_at_base` prints the table, `felix_exceptions_count` prints 1, and `felix_exceptions_unmerged` prints nothing.
24. B4 [control]: release mode prints column 8 `-` on the baseline and on the forged refspec.
25. B8 [red]: `lib/exceptions.sh` does not contain `moves only when`, and does contain `reflog`.
26. B9 [red]: the where-stands document does not contain `exception grants and obligation admission, which are read from`.
27. B9 [red]: the document, with its blanks and newlines squeezed to one space, contains `obligation admission and every table the gate reads, which are read from the home's working tree`.
28. B9 [red]: the document does not contain `True only where main is server-protected`.
29. B10 [red]: `felix_claude_dir` prints X under `CLAUDE_CONFIG_DIR=X`, and `HOME/.claude` when the variable is unset or empty (three cases).
30. B12 [red]: under X, `felix_registry_field px version` prints `1.2.3`, the same call for `ph` prints nothing, and provenance prints `px@1.2.3/abc123`.
31. B12 [control]: unset, `felix_registry_field ph version` prints `9.9.9`.
32. B12 [red]: under X, `_felix_commission_installed px` exits 0 and `ph` exits 1. [control]: unset, `ph` exits 0.
33. B12 [red]: under X, `felix_kernel_dir R2 main` prints `X/plugins/cache/felix/felix/7.7.7/harness`.
34. B12 [control]: `FELIX_PLUGIN_CACHE=P` gives P's path even with X set, and `FELIX_KERNEL_CACHE=K` gives K's.
35. B12 [red]: with no cache under X, `felix_accepted_deploy_diff` exits 2 and names `X/plugins/cache/felix/felix`.
36. B12 [red]: under X, `felix_marketplace_root` prints `/from/ccd`. [control]: unset, it prints `/from/home`.
37. B12 [red]: under X, toolbox.sh's `FELIX_PLUGIN_CACHE` and `felix_toolbox_path px` point under X. [control]: a preset `FELIX_PLUGIN_CACHE` is kept.
38. B12 [red]: under X, `deploy-check --applies` exits 0. [control]: it exits 1 with neither location, and 0 with HOME's cache and the variable unset.
39. B12 [red]: under X, `felix_ready_inventory` lists sx, px and bx and none of sh, ph and bh. [control]: unset, it lists sh, ph and bh.
40. B12 [red]: under X, `felix_ready_report` prints `usable<TAB>sx<TAB>skill, always available`. [control]: unset, it prints `absent<TAB>sx<TAB>skill directory not present`.
41. B12 [red]: under X, `felix_stack_plan` prints both `present` lines. [control]: unset, it prints neither.
42. B12 [red]: under X, `felix_coverage_events` lists Stop and PreCompact and not SessionEnd. [control]: unset, it lists SessionEnd.
43. B13 [red]: the lint counts no line outside the six files.
44. B13 [control]: the lint's scanner, run on a fixture file, counts `x="$HOME/.claude/y"` and skips `# $HOME/.claude` and `${CLAUDE_CONFIG_DIR:-$HOME/.claude}`.

**Part 1860 (fixture B: B22; fixture L: the B25 home with `el` = `acme/el` and `other` = `acme/other`, checkout CO with origin `https://b12tok:SECRET-b12@github.com/acme/el.git`; fixture R: B31)**

45-58. B22: one assertion per row of the table, in table order. Rows 1, 3, 4, 5, 8, 11, 12 and 14 are [red]; the rest are [control].
59. B22 [control]: the marker checkout binds to `web`.
60. B23 [red]: on the tie, `felix_binding_broken` names dup1 and dup2 and contains `remote_match`.
61. B23 [red]: on the tie, session-start prints `binding broken`.
62. B23 [red]: on the tie, stop prints a block object.
63. B25 [control]: the first `felix_binding_broken CO` prints nothing and exits 0.
64. B25 [red]: `bindings.tsv` then holds exactly one line, `<key><TAB>el<TAB><stamp>`, with the key computed as B25 says.
65. B25 [red]: a second call leaves exactly one line.
66. B25 [control]: no file under the memory root contains `SECRET-b12` or `github.com/acme`.
67. B25 [control]: `felix_resolve_project` alone leaves a fresh memory root empty.
68. B26 [red]: with `project.json` renamed to `project 2.json`, the sentence names `el`, `project.json`, `project 2.json` and the `bindings.tsv` path, and lacks `SECRET-b12`.
69. B26 [red]: with `project.json` deleted, the sentence names `el` and `project.json`.
70. B26 [red]: with `project.json` at mode 000, the same holds (skipped when `id -u` is 0).
71. B26 [red]: with `project.json` a FIFO, the same holds, and the call returns within 5 s.
72. B26 [control]: in every case of 68-71, `felix_resolve_project` exits 1 and prints nothing.
73. B27 [red]: in the rename state, session-start prints `binding broken` and `el`; stop blocks with `el`; `unresolved.log` gains a line. [control]: a resume payload prints nothing.
74. B28 [control]: never bound, no origin, `remote_match` emptied, `remote_match` changed, `projects/el` removed, a different home, an unwritable memory root, an unreadable `bindings.tsv` and a `../x` line each print nothing; stop is silent for the never-bound case.
75. B29 [red]: after the rename to `el2`, the checkout binds to `el2`, nothing is printed, and the last line names `el2`.
76. B24 [red]: each own URL from 1130 binds to the `OWNERX/OWNP-REPO` project.
77. B24 [control]: each not-own URL from 1130 binds to nothing.
78. B30 [control]: a marker naming `gone` prints the sentence beginning `The .felix marker in`, unchanged when a `bindings.tsv` line names `el` for the same URL.
79. B31 [red]: under the `pwd` stub, the call in the repository returns within 5 s with the top level.
80. B31 [red]: under the stub, the call outside any repository returns DIR within 5 s.
81. B32 [red on bash 3.2, control on bash 5]: after the stale `felix: something`, the call returns within 5 s with the top level.
82. B32 [red on bash 3.2, control on bash 5]: after the stale `/x`, the root is exactly the top level.
83. B31 [control]: without the stub, a subdirectory, a worktree with a `.git` file, and a directory outside git give the same roots as on 69b51a61.

## 5. Parts

- `engine/harness/tests/parts/1850-grant-base-and-config-dir-blind.sh` holds assertions 1-44 (C009, C010, C098).
- `engine/harness/tests/parts/1860-binding-match-and-record-blind.sh` holds assertions 45-83 (C046, C031, C061).

Each is written blind from this contract. Each builds its own fixtures under one `mktemp -d` in `$TMP`, uses only the driver's helpers (`ok`, `bad`, `is`, `has`, `skip`, `$FROOT`, `$TMP`), and is registered in `tests/run` by one line each, directly after 1600's line, 1850 first. Neither joins a group in `groups.tsv`. The `pwd` stub, closed stdout and failing git each run in a child shell, so the part's own output is untouched.

## 6. Out of scope, with why

- **C009, the merge half.** It lives in `cmd_merge` in `engine/harness/felix`, which is batch 13's file. Both skeptics found it adds nothing beyond the recorded floor: `gh pr merge` is refused by no row, and the tick fetches first (green-tick.sh:423) and takes only PRs based on main (:359). The change, for b13 or a follow-up: before judging, refuse when `felix_exceptions_doubt` doubts the base. Before `gh pr merge`, read `gh pr view --json baseRefName,baseRefOid`. Refuse unless `refs/remotes/origin/<baseRefName>` is the judged base and `git merge-base --is-ancestor <base> <baseRefOid>` holds; when `baseRefOid` is not present locally, say "fetch first".
- **C009, the Stop text and README.** `hooks/stop:601-603` is batch 7's file and is pinned by 1080. README:109-110 is batch 21's. Both still say "a session cannot grant itself one". The replacement, in both: "merged by a person. Felix reads it from refs/remotes/origin/main and refuses that ref when its fetch configuration, reflog or origin URL shows it was not fetched, which stops an accident, not a session set on forging one." Part 1080's pinned phrase moves with it.
- **C009, the deny rows.** See §7.
- **C010, everything but §4 of the status document.** The rules are read in files other batches own. The changes:
  - (1) Bind `gate.sh` and `qualification.tsv` to the receipt. Either add them to `FELIX_COMMISSION_TABLES` (`lib/commission.sh`, b17), which moves the policy hash so the commission grant needs the founder's re-stamp, or record the gate script's blob hash in the receipt (`lib/verify.sh`, b8).
  - (2) Report a dirty home. When `git -C <home> status --porcelain --untracked-files=no -- projects/<name>/` is non-empty, `felix gate` and the Stop hold say "the home holds uncommitted edits to <files>; every session on this machine reads them", and `felix merge` refuses for a self-governed project (`felix` b13, `hooks/stop` b7).
  - (3) README:323-329 (b21).
  - (4) The stale-commission blocker's "run felix commission" (`escape.sh` b10, `commission.sh` b17).
- **C098, the sites in other batches' files:**
  - felix:719-720 and :1855 (b13);
  - green-tick.sh:197 (b2);
  - green-install.sh:104, plus the plist, which must capture `CLAUDE_CONFIG_DIR` at install because launchd has none (b5);
  - discover.sh:797 (b6);
  - projects/felix/gate.sh:178 and :248-250 (b8);
  - `tests/run` should `unset CLAUDE_CONFIG_DIR` before any part, so a suite run by a person who sets it cannot read their real config (b1). The lint (B13) allows the four owned code files by name.
- **lib/own.sh's comment** (b17) calls resolution step 2 "a substring test" (own.sh:23-25). After this batch that is an anchored or exact match; the comment needs one line.
- **A marker-bound project whose `project.json` is missing.** Skeptics noted it. The Stop exits at the empty gate, and the banner says "Gate: none declared". It is not this batch's defect, and reporting it changes every marker fixture that has no `project.json`; it needs its own contract.
- **The stale-buffer class beyond `felix_repo_root`.** Every `$( )` after a failed write in a bash 3.2 process inherits the text. A flush at hook and CLI entry would close the class, and that lives in other batches' files.

**Not fixed: not a defect.**
- *C009, "felix merge then reads the forged grants".* Release mode never carries a clearance (obligations.sh:185-187, :212, :247).
- *C009, "the hold text tells the founder this cannot happen".* README:321-325 already says a session can add the row itself; the Stop text is the remaining claim, listed above.
- *C010, "felix merge sees nothing" and "surfaces only at deploy", for obligations.tsv, deny.tsv, risk.tsv and probes.tsv.* All four are in `FELIX_COMMISSION_TABLES` (commission.sh:52). A home edit moves `felix_commission_policy_version` (commission.sh:541-555) and stales the commission receipt (:686-688), so `felix merge` emits a `commission receipt` blocker (escape.sh:779-781) and waits for the founder (felix:2016-2022). The tick notifies (green-tick.sh:48-56).
- *C031, "five of nine projects bind this way" and the ReserveGrid scenario.* ReserveGrid-OS, BlackBoxBazaar, team1 and sv2-apps carry markers.
- *C061, the closed-pipe and land-tick triggers.* bash 3.2 dies of SIGPIPE at the failed write (exit 141). The tick writes to launchd.log through a freshly exec'd felix (green-install.sh:151, :180).

## 7. Founder PR

`projects/felix/deny.tsv` rows are the founder's to merge, and C009's floor needs them: the existing rows refuse `git remote set-url` but not `git config` of the same keys. Each row's four fields are joined by single tabs, and the rows go after the `git remote` row (line 134). The reason given for each row is the reason field.

```
Bash	(>[>|]?|(^|[ ;&|(])(cp|mv|tee|ln|install|dd|rm|rsync|ditto|truncate)( +[^;&|]*)?) *[^ ;&|]*\.git/(refs/remotes/|logs/refs/remotes/|packed-refs)	a remote-tracking ref, its reflog and packed-refs are what the remote said, and the exception table is read from them; only a plain fetch may move them. Read one with git rev-parse	checkout
Write	(^|/)\.git/(refs/remotes/|logs/refs/remotes/|packed-refs$|(worktrees/[^/]+/)?config(\.worktree)?$)	the remote-tracking refs, their reflogs, packed-refs and the repository config decide what refs/remotes/origin/main means, and the exception table is read from it	checkout
Edit	(^|/)\.git/(refs/remotes/|logs/refs/remotes/|packed-refs$|(worktrees/[^/]+/)?config(\.worktree)?$)	the remote-tracking refs, their reflogs, packed-refs and the repository config decide what refs/remotes/origin/main means, and the exception table is read from it	checkout
Bash	git( +-[^ ]+( +[^ ]+)?)* +config( +[^ ;&|]+)* +(([Rr][Ee][Mm][Oo][Tt][Ee]\.[^ ;&|]+\.([Uu][Rr][Ll]|[Ff][Ee][Tt][Cc][Hh])|[Uu][Rr][Ll]\.[^ ;&|]+\.([Ii][Nn][Ss][Tt][Ee][Aa][Dd][Oo][Ff]))( +[^ ;&|]+)|(--unset(-all)?|unset|--remove-section|remove-section|--rename-section|rename-section)( +[^ ;&|]+)* +([Rr][Ee][Mm][Oo][Tt][Ee]|[Uu][Rr][Ll])\.[^ ;&|]+)	the remote's url and fetch refspecs decide what refs/remotes/origin/main means, and the exception table is read from it; git config may read them, not write them	checkout
Bash	git( +-[^ ]+( +[^ ]+)?)* +(-c *|--config-env[= ]*)([Rr][Ee][Mm][Oo][Tt][Ee]|[Uu][Rr][Ll])\.	a one-shot remote or url setting chooses what a fetch writes into refs/remotes/origin/main, which the exception table is read from	checkout
```

These rows were probed with `felix_deny_match` on a scratch project (2026-10-24).

*Refused:*
- `cp .git/refs/heads/mine .git/refs/remotes/origin/main`
- `git rev-parse mine > .git/refs/remotes/origin/main`
- `echo x >>.git/packed-refs`
- `… | tee .git/refs/remotes/origin/main`
- `rm .git/logs/refs/remotes/origin/main`
- `git config remote.origin.fetch '+refs/heads/x:refs/remotes/origin/main'`
- `git -C /x config --add remote.origin.url /y`
- `git config --replace-all remote.origin.fetch …`
- `git config url./forged.insteadOf …`, including with `--global`
- `git config set remote.origin.url /x`
- `git config --unset remote.origin.fetch`
- `git config unset remote.origin.url`
- `git config --remove-section remote.origin`
- `git config Remote.Origin.URL /x`
- `git -c remote.origin.url=/forged fetch`
- `git --config-env=remote.origin.url=X fetch`
- a Write to `…/.git/refs/remotes/origin/main`, `.git/packed-refs`, `.git/config` or `.git/worktrees/w/config.worktree`

*Allowed:*
- `git fetch` and `git fetch -q origin`
- `git config --get remote.origin.url`, `git config remote.origin.url` and `git config get remote.origin.url`
- `git config -l` and `git config --get-regexp remote\..*\.url`
- `git config user.name t`
- `git -c user.name=t … commit` and `git -c core.logAllRefUpdates=false add -A`
- `cat` or `ls` under `.git/refs/remotes/`, `git rev-parse refs/remotes/origin/main` and `git remote get-url origin`
- `diff a .git/packed-refs` and `grep x .git/packed-refs > /tmp/out`
- `git config remote.origin.prune true`
- Writes to `src/config`, `.git/hooks/pre-commit` and `.github/config`

*Stated limits.*
- The rows refuse `cp .git/refs/remotes/origin/main /tmp/backup` (read the ref with `git rev-parse` instead).
- They do not see `GIT_CONFIG_COUNT`/`GIT_CONFIG_KEY_n` environment settings, `sed -i` or interpreter writes.

`deny.tsv` is in `FELIX_COMMISSION_TABLES`, so the same PR re-stamps the felix commission grant over the new table set, as #459 did. Nothing else in this batch needs the founder: the code fix in §2 does not wait on these rows.

## 8. Red

Run on 69b51a61 plus the two blind parts, before any engine change: `alone.sh <worktree> bwk 1850-grant-base-and-config-dir-blind.sh 1860-binding-match-and-record-blind.sh` (bash 3.2.57, macOS awk). The two parts print 93 assertion lines for the 83 numbered assertions (ten control halves are lines of their own: A11 fixture, A32, A36, A37, A38, A39, A40, A41, A42 and A73 control). **54 failed and 39 passed.** The 62 other `ok` lines of that run are the driver's preamble, not this batch.

Every one of the 39 that passed is a [control] the contract names. They split three ways.

- **Already true on 69b51a61 (the behaviour the fix must keep):** A1, A3, A23, A24 (B4, B5 and the release-mode column), A31, A32 control, A36 control, A37 control, A38 control, A39 control, A40 control, A41 control, A42 control and A34 (the unset and overridden config directory reads HOME's copy, or the named override); A46, A50, A51, A53, A54, A57 and A59 (rows of fixture B that the substring rule already binds as B21 says); A77 (not-own URLs bind nothing); A78 (the marker sentence); A83 (the roots); A72, A73 control and A63 (no output yet); A44 (the lint scanner, which is the test's own code).
- **Vacuous on 69b51a61 in the half that matters, true in the other half:** A2, and the `doubt=[]` or `[…]` half of A10, A12, A14 and A17, pass because `felix_exceptions_doubt` does not exist: stdout is empty and its exit status is not read. The clear half of each is already true. A21 and A22 call the three readers, and the third is missing, so only `felix_exception_for` and `felix_exceptions_judge` are shown to run no network call and to change nothing. A11 fixture checks the fixture, not the engine.
- **Vacuous because nothing records yet:** A66 (no file holds the URL) and the "record untouched" half of A78 and A74 pass because 69b51a61 writes no `bindings.tsv`. A74's silence cases are also what 69b51a61 does for every unbound state; they pin the new code, not the old.

The 54 that failed: A4 to A9, A11, A13, A15, A16, A18 to A20, A25 to A30, A32 to A33, A35 to A43 (the red halves), A45, A47 to A49, A52, A55, A56, A58, A60 to A62, A64, A65, A68 to A71, A73, A75, A76, A79 to A82. A79 and A80 hang in the walk (the child is killed at 5 s, `child=142`), A81 hangs the same way, and A82 prints `/x` for the root; bash here is 3.2, so the B32 pair is red as the contract says.
