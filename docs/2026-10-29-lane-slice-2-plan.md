# Come-backs (`felix retro`) Implementation Plan

> **For agentic workers:** run this plan as the founder's engine-build Workflow: spec, blind assertions, red first, implementation, adversarial review, gate. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** `felix retro` counts which merged changes came back within 30 days (revert, strong fix, reopened issue), over the closed changes as of the main ref's last fetch, and files each come-back against what `felix situations --change` said it owed.

**Architecture:** A read-only command over git history. Two sealed libraries hold every rule (`lib/retro-rules.sh`, `lib/retro-lines.sh`) and their hash goes into every record. An unsealed library (`lib/retro.sh`) runs the walk, prints the report and writes one record under the memory root. The replay join (`lib/retro-replay.sh`) is the last piece and calls slice 1's `felix situations --change C^1..C --tsv` per change.

**Tech stack:** bash 3.2, git, BWK-and-gawk awk; `gh` only behind `--issues`.

**Spec:** `docs/2026-10-29-capability-lane-first-slices-design.md` (branch `claude/lane-situations-owed` at `52c1bdd7`). This plan implements §8 (slice 2), under §1 to §5, §7.6, §7.7, §9 and §10.

## Global Constraints

- Bash 3.2 and git only: no jq, no python.
- Only awk that both BWK awk (local) and gawk (CI) run. Part 1497's `_awk_names` lints `lib/`. No `{n,m}` intervals in awk regexes.
- `LC_ALL=C` on every sort, comm, join and uniq (part 0992).
- `[[ =~ ]]` only inside a function that declares `local LC_ALL=C` (part 0996).
- Flags go through `need_value` (`engine/harness/felix:389-391`), never a bare `shift 2`.
- The engine names no project (invariant 1). `bin/independence-scan` greps `felix`, `lib`, `hooks` and `bin` case-insensitively for every governed name: bazaar, behaviorchangebench, elenchus, elenchus-capital-research, sv2-apps, team1, veldra, webapp. None may appear, even inside a word or a comment.
- Offline and deterministic (invariant 2): two runs with the network off and no key print identical bytes. The only network use is `--issues`. It is off unless asked for, and when GitHub is unreachable it reads "could not look".
- A check that cannot fail is not a check (invariant 5). Every new check is shown failing first.
- Never delete a home or a memory root (invariant 6).
- Records go under the memory root (`felix_mem_dir`, `lib/resolve.sh:269-272`). Nothing is written into a governed repository: its refs, index, config and worktree list stay as they were.
- Lane exclusions: never touch `lib/qualify.sh`, `lib/obligations.sh`, `lib/receipt.sh`, `lib/automerge.sh`, `lib/green-*.sh`, `lib/land-table.sh`, `lib/notify.sh`, `lib/own.sh`, `lib/status-land.sh`, or the `felix merge` and `felix land` code paths.
- Tables before code. Each new table is a new file with one new `schemas.tsv` row. No column is added to an existing table.
- Every engine line that runs porcelain `git diff` carries `--no-ext-diff` and `--no-textconv` on the same line (part 1530).
- Every new `felix` command appears in `usage()` (part 0480).
- Parts are `NNNN-name.sh`, at most 1,000 lines, sourced once by the driver in name order; the driver stays at or under 500 lines (part 1040; it is 453 now). A `tests/lib` file defines functions and nothing else (part 0006). Fixture git writes go through `_fx_cd` and `_fx_git` (part 0002).
- Anti-goals: no project score, level or grade; nothing a person chats with; "could not look" never printed or counted as anything else; no bare come-back rate (always with its denominator, its open windows and its measured precision); no model on any path; the engine never reads the sample labels; no dispatching agents or choosing models.
- Non-goals: nothing blocks, holds, comments or enforces; no new GitHub writes; no file in anyone's CI; come-back records carry no provider or model field.
- How it lands: one engine PR. No new engine branch while more than 10 engine PRs are open (`gh pr list`). The PR bumps the patch version in `engine/.claude-plugin/plugin.json` and puts it in its title, taking the next free slot at landing time. 0.49.310 to 0.49.314 are claimed today (0.49.314 by open PR #477).
- Suite manners: commit everything before the record; red and gate never share a worktree; at most four part runs at once across the Mac; no whole-suite run while another session's record or gate holds the queue (ask the queue owner first; today that is the "Inventory next steps" session).
- Lane mark: at least one commit message on the branch ends with the whole line `Felix-Lane: capability`.

## Contracts

The blind authors read the design and this section, and nothing else of the plan. Everything here is decided in the plan unless it quotes the design.

### C1. The command

```
felix retro [<repo>] [--last N | --since YYYY-MM-DD] [--window D] [--issues] [--no-replay] [--tsv]
```

- `<repo>`: a directory. Default: the current directory. The repository is the git work tree holding it, named by its physical root path.
- `--last N`: N is 1 to 9999, written without a leading zero. Default 50.
- `--since YYYY-MM-DD`: a real calendar date, read as 00:00:00 UTC that day.
- `--last` and `--since` together are a usage error.
- `--window D`: D is 1 to 365 days, written without a leading zero. Default 30.
- `--issues`: asks GitHub about reopened issues (rule 3). Off by default.
- `--no-replay`: does not run `felix situations`. Decided in the plan, for the suite's cost and so the come-back half can be measured alone.
- `--tsv`: prints the record (C5) instead of the human report (C6).
- `-h` or `--help` anywhere: prints `felix help`'s text, exit 0.
- Flags and the one positional may come in any order.
- `felix help` lists the line `felix retro [<repo>] [--last N | --since YYYY-MM-DD] [--window D] [--issues] [--no-replay] [--tsv]`.

### C2. Exit status and refusals

Every refusal is one line on stderr starting `felix: retro: `, except need_value's own line.

| Status | When | Stdout | Record |
|---|---|---|---|
| 0 | a report was printed and its record written | the report | written |
| 1 | a flag was given with no value (need_value; stderr holds `--last needs a value`, with the flag's own name) | nothing | none |
| 2 | any other usage error: an unknown flag, a second positional, a bad N, date or D, `--last` with `--since`, a `<repo>` that is not a directory | nothing | none |
| 1 | `<repo>` is in no git work tree | nothing | none |
| 1 | no project governs the repository: `felix: retro: no project governs <root>` | nothing | none |
| 1 | no main ref (C3): `felix: retro: <root> has no main ref: neither refs/remotes/origin/HEAD nor refs/remotes/origin/main names a commit` | nothing | none |
| 1 | no as-of (C3): `felix: retro: neither <main ref> nor refs/remotes/origin/HEAD has a reflog entry, so when the main ref was last fetched is not known; nothing was counted` | nothing | none |
| 1 | `retro.tsv` refused (C4): `felix: retro: <table path>:<line>: <why>` | nothing | none |
| 1 | the record could not be written: `felix: retro: the record could not be written: <path>` | the report | none |

### C3. The main ref, the as-of time and the selection

- **Main ref.** The target of `refs/remotes/origin/HEAD` when it is a symbolic ref to a `refs/remotes/origin/<x>` that names a commit. Otherwise `refs/remotes/origin/main` when it names a commit. Otherwise exit 1 (C2).
- **As-of time.** The time of the newest reflog entry of the main ref. When the main ref has no reflog entry, the newest reflog entry of `refs/remotes/origin/HEAD`. A fresh `git clone` (git 2.56, measured 10-29) writes a reflog entry for `origin/HEAD` and none for `origin/main`. When neither has one, exit 1 (C2). The as-of time is never the wall clock and never `FETCH_HEAD`'s mtime.
- **The clock.** `felix retro` reads no wall clock. A suite pins time only through commit dates (`GIT_AUTHOR_DATE`, `GIT_COMMITTER_DATE` as `@<epoch> +0000`) and through the main ref's reflog entry, which git dates by `GIT_COMMITTER_DATE` when the ref is written (`git update-ref --create-reflog -m <msg> refs/remotes/origin/main <sha>`, or a `git fetch` from a second local repository).
- **The chain.** First-parent commits of the main ref, newest first. A change's time `ct` is its committer time. A commit with no parent ends the walk (stop `root`). A commit whose first parent is not in the repository ends it too (stop `shallow`).
- **Closed and open.** A change C is closed when `ct(C) + D·86400 ≤ as-of`, and open otherwise. Exactly `D·86400` before the as-of time is closed; one second later is open.
- **`--last N`.** Walk the chain newest first. Each open change met is listed with status `open`. Each closed change is taken. Stop after the Nth closed change (stop `last`).
- **`--since`.** Walk the chain newest first and stop at the first change whose `ct` is before the date (stop `since`; that change is not listed). Every closed change met is taken, and every open one listed.
- **The window of a closed change C.** Walk the chain from C toward the tip. T is the last commit met whose `ct ≤ ct(C) + D·86400`. The window is every chain commit after C up to and including T. When there is none, the window is empty and nothing came back. The end is inclusive.
- **The base** of every change is `C^1`. A real merge commit is one change; the commits it merged are never change rows.

### C4. `projects/<p>/retro.tsv`

Columns `kind pattern reason`. The `schemas.tsv` row, inserted after the `.snapshot-ack.tsv` row (`engine/harness/templates/schemas.tsv:134`), with its comment:

```
# Present and empty, or absent: no path is excluded and the default fix
# pattern applies (felix retro, felix_retro_table). A row whose kind is not
# exclude or fix, or whose pattern is not an ERE, stops felix retro with exit 1.
retro.tsv	tree	kind pattern reason	allowed
```

- The file is read from the Felix home: `<home>/projects/<p>/retro.tsv`.
- It is first checked with `lib/table.sh`'s `felix_table_check` against `schemas.tsv`; any refusal stops the run (C2), naming the first refusal's line.
- `kind` is `exclude` (an ERE over a path as git names it, relative to the repository root, case-sensitive) or `fix` (an ERE over a subject). Any other kind, or a pattern grep -E cannot compile, stops the run.
- Every subject is lowercased (A-Z to a-z, `LC_ALL=C`) before any fix or revert test.
- When the table holds at least one `fix` row, those rows replace the default. Otherwise the default fix ERE is `^(fix|hotfix|revert)(\([^)]*\))?!?:`. That is §8.3's `^(fix|hotfix|revert)` with its optional scope, closed by the colon so that a subject like `fixtures: ...` stays out. On the three repositories, every first-parent subject that starts with one of the three words already has this form (measured 10-29).
- The project rows this PR adds (sealed with it):

| Project file | kind | pattern | reason |
|---|---|---|---|
| `projects/felix/retro.tsv` | exclude | `^engine/\.claude-plugin/plugin\.json$` | the version file |
| | exclude | `^engine/harness/tests/(assertions\|red)\.tsv$` | generated record tables |
| | exclude | `^(HANDOFF\.md\|docs/handoff/)` | handoff notes and their rotation |
| `projects/veldra/retro.tsv` | exclude | `^VERSION$` | the version file |
| | exclude | `^CHANGELOG\.md$` | release notes |
| | exclude | `(^\|/)Cargo\.lock$` | generated lock file |
| | exclude | `(^\|/)package-lock\.json$` | generated lock file |

Elenchus gets no table: its tree holds no version file, changelog, lock file or handoff notes.

### C5. The record and `--tsv`

`--tsv` prints the record's bytes, and the record file holds exactly what `--tsv` would print for the same arguments. Cells are tab-separated, every line ends in a newline, and lines come in this order.

Header, eight rows:

| Row | Cells after the kind |
|---|---|
| `retro` | project name; repository root, physical path |
| `main` | the main ref, in full (`refs/remotes/origin/main`); its sha, 40 hex |
| `as_of` | `YYYY-MM-DDTHH:MM:SSZ`; the ref whose reflog gave it, in full |
| `sealed` | the seal, 40 hex (C7) |
| `select` | `last` and N, or `since` and the date as given |
| `window` | D; `sealed` when D is 30, else `unsealed` |
| `issues` | `on` or `off` |
| `replay` | `on` or `off` |

Then four summary rows:

| Row | Cells after the kind |
|---|---|
| `counts` | closed changes taken; came back; open; edited again; changes with unread lines |
| `kinds` | changes with a revert; changes with a strong fix; changes with a reopened issue; changes whose issue kind could not look. The last two are `-` when issues are off |
| `split` | over came-back changes only: owed; no row; could not look; unread. All four `-` when replay is off |
| `stop` | `last`, `since`, `root` or `shallow`; the sha (40 hex) of the commit the walk stopped at |

Then one `change` row per listed change, in chain order, newest first, 13 cells:

| # | Cell | Values |
|---|---|---|
| 1 | `change` | |
| 2 | sha | 40 hex |
| 3 | time | committer time, `YYYY-MM-DDTHH:MM:SSZ` |
| 4 | status | `came-back` (a revert, a strong fix or a reopened issue); `edited` (weak edits only); `quiet`; `open` |
| 5 | revert | revert commits, 12-hex shas, comma-joined, oldest first; `-` |
| 6 | strong | strong-fix commits, same form; `-` |
| 7 | weak | weak-edit commits, same form; `-` |
| 8 | excluded | how many of C's added lines are excluded |
| 9 | unread | how many of C's added lines the blame could not read |
| 10 | issue | `-` (off); `reopened #<i>[,#<j>]` (ascending); `not reopened`; `none closed`; `could not look` |
| 11 | replay | `-` (off); `owed`; `no row`; `could not look`; `unread` |
| 12 | owed ids | slice 1's ids, `owed:<12 hex>`, `LC_ALL=C` sorted, unique, comma-joined; `-` |
| 13 | subject | the subject, each tab and each CR replaced by one space |

An open change's cells 5 to 12 are `-`. A commit appears in at most one of cells 5, 6 and 7 for one change.

Then the sample rows (C9): `sample`, then `strong` or `weak`, then C's sha and X's sha, both 40 hex. Strong rows first.

- **Path.** `<memory root>/<p>/retro/<as-of as YYYYMMDDTHHMMSSZ>-<key>.tsv`. `<memory root>/<p>` is `felix_mem_dir` of the project directory. `<key>` is the first 12 hex of `git hash-object --no-filters --stdin` over the eight header rows, each with its newline.
- Two runs with the same arguments write the same path. The write goes to a temporary file in the same directory, then `mv -f`.
- Nothing else is written anywhere: not in the home, not in the memory root, not in the repository.

### C6. The human report

Pinned lines, in this order. Later lines and the per-change detail lines are the builder's layout.

```
felix retro: <project>, <repository root>
main: <ref without refs/remotes/> at <sha12>, as of <YYYY-MM-DD HH:MM:SS> UTC, from the reflog of <reflog ref without refs/remotes/>
sealed <seal12>; window <D> days[, unsealed: the sealed window is 30]; <the newest N closed changes | closed changes since YYYY-MM-DD>; issues <asked | not asked>; replay <on | off>

came back: <K> of <N> closed changes (<O> open, not counted); precision: unmeasured here, a headline needs 0.7 on the blind sample
by kind: revert <a>, strong fix <b>, reopened issue <c | not asked>[, issue could not look <d>]
edited again, not counted: <E>; changes the blame could not read whole: <U>
<replay of the K: owed <x>, no row <y>, could not look <z>, unread <u> | replay: not run>
stopped: <took the newest N closed changes | reached a change before YYYY-MM-DD | reached the first commit | reached a shallow boundary at <sha12>>
```

- `, issue could not look <d>` appears only when issues are asked.
- Then, each after one empty line, the headers `came back (<K>)`, `edited again (<E>)`, `open, not counted (<O>)` and `sample for blind labels: <s> strong, <w> weak`. A header is printed even with a count of 0. Each change under a header is one line `  <sha12> <YYYY-MM-DD> <subject>`; its details follow on lines indented four spaces.
- Each sample row prints as `  strong <C sha12> <X sha12>` or `  weak <C sha12> <X sha12>`.
- The last line is `record: <record path>`.
- No line holds a `%`. The rate is only ever printed as "K of N".

### C7. The seal

The sealed rules are exactly the code in `lib/retro-rules.sh` and `lib/retro-lines.sh`, plus the project's `retro.tsv`. Every rule of §8.2, §8.3 and §8.6 lives in those two files: the defaults (window 30, last 50, sample sizes 20 and 10), the main-ref and as-of rule, the selection walk, the window, exclusion, revert, strong and weak, the issue rule and the sampling rule. Output, records and the replay join live outside them, so a change there leaves the seal alone. Decided in the plan.

```
printf 'rules\t%s\nlines\t%s\ntable\t%s\n' \
  "$(git hash-object --no-filters <harness>/lib/retro-rules.sh)" \
  "$(git hash-object --no-filters <harness>/lib/retro-lines.sh)" \
  "<git hash-object --no-filters <home>/projects/<p>/retro.tsv, or - when the file is absent>" \
  | git hash-object --no-filters --stdin
```

`<harness>` is the directory holding the `felix` that runs. Changing either library or the table changes the seal.

### C8. The come-back rules (§8.3)

- **C's added lines.** From `git -c core.quotePath=false diff --no-ext-diff --no-textconv --no-color --src-prefix=a/ --dst-prefix=b/ --ignore-submodules=none -U0 --no-renames <C^1> <C> --`. Each `+c,d` hunk gives lines c to c+d-1 of C's file (`+c` alone is one line; d = 0 is none). A binary file gives no lines. A path whose mode at C is 160000 (a submodule pointer) gives no lines. A path git still quotes is read as unread.
- **Outcome of each line.** A path matching an `exclude` row: every line excluded, nothing blamed. Otherwise one `git -c core.quotePath=false blame --no-textconv --ignore-revs-file '' --reverse <C>..<T> --first-parent --porcelain -L <a,b> [-L ...] -- <path>` per file, with all its ranges together. The line's outcome:
    - blamed to T, and T's tree holds the path: survived;
    - blamed to T, and T's tree lacks the path (renamed or deleted whole): excluded;
    - blamed to X, which is C or a window commit other than T: Y is the chain commit after X. If Y's tree holds the path, Y changed the line. If not, the line is excluded;
    - blamed to anything else, or the blame failed: unread.

- git blame follows a whole-file rename, so a renamed file's lines read survived at its new path. The tree tests above are what make "renamed whole" excluded, as §8.3 and §8.8 require.
- **Revert of C.** A window commit X whose lowercased subject starts `revert`, and that either names C or changed one of C's lines. X names C when either holds:
    - its full message holds a run of 7 to 40 lowercase hex digits, with no hex digit of either case on either side, that is a prefix of C's sha or of a commit in `git rev-list C^1..C`;
    - its subject is exactly `Revert "<C's subject>"`, optionally followed by ` (#<digits>)`.

- Body lines never make a revert: the subject test is on the subject alone.
- **Strong.** A window commit that changed one of C's lines, is not a revert of C, and whose lowercased subject matches a fix ERE (C4).
- **Weak.** Any other window commit that changed one of C's lines. Reported as edited again. Never a come-back.
- Excluded lines count for no rule.
- **Reopened issue** (`--issues` only, closed changes only):
    - C's PR number is `n` from a subject ending `(#n)`, or a subject starting `Merge pull request #n `. A change with neither reads `could not look`, and gh is not called for it.
    - The repository's slug comes from the origin URL: `https://github.com/<o>/<r>[.git]`, `git@github.com:<o>/<r>[.git]` or `ssh://git@github.com/<o>/<r>[.git]`. Any other URL reads `could not look` for every change, and gh is never called.
    - gh's calls, in this order, with `GH_PROMPT_DISABLED=1` and `GH_NO_UPDATE_NOTIFIER=1`: `gh pr view <n> --repo <o>/<r> --json closingIssuesReferences --jq '.closingIssuesReferences[].number'`, which prints one issue number a line; then for each issue i, ascending, `gh api repos/<o>/<r>/issues/<i>/events --paginate --jq '.[] | select(.event == "reopened") | .created_at'`, which prints one `YYYY-MM-DDTHH:MM:SSZ` a line.
    - The issues C closed are the PR's list together with every `#i` that a closing keyword names in C's lowercased message. The keywords are close, closes, closed, fix, fixes, fixed, resolve, resolves and resolved, each followed by an optional `:`, then blanks, then `#<digits>`, with no letter just before the keyword.
    - An issue reopened at t with `ct(C) < t ≤ ct(C) + D·86400` makes the cell `reopened #i` and C a came-back change. No such event: `not reopened`. No issue: `none closed`.
    - gh missing from PATH, any gh exit other than 0, or a line of gh's output not of the shape above: `could not look`, never `not reopened`.

- **Came back** means a revert, a strong fix or a reopened issue.

### C9. The sample (§8.6)

- **Candidates.** Each pair (C, X) of a taken closed change and one commit in its revert or strong cell is a strong candidate. Each pair of C and one commit in its weak cell is a weak candidate.
- **Key.** `git hash-object --no-filters --stdin` over `<seal40>\t<C40>\t<X40>\n`.
- **Draw.** The first 20 strong candidates and the first 10 weak candidates, by key ascending (`LC_ALL=C`). Strong rows are printed first, then weak, each in key order.
- **Labels** are made outside the engine (Task 12). The engine never reads them.

### C10. The replay join (§8.4)

- For each taken closed change, with replay on, run `( cd <root> && <harness>/felix situations --change <C^1 sha>..<C sha> --tsv )` with the same environment.
- A class line is a line whose first cell is `owed:` and 12 hex. Its verdict is cell 3. A `residual` line is never a class line.
- The verdict tokens are the ones slice 1's plan pins (`docs/2026-10-29-lane-slice-1-plan.md`, its C5 and C8): `owed` (which also carries §7.5's "owed (base could not look)"), `standing`, `blinded`, `could-not-look`, `retired`, `none`.
- Filing:
    - `owed`: at least one class line whose verdict is `owed` or `blinded`;
    - else `could not look`: at least one class line whose verdict is `could-not-look`;
    - else `no row`;
    - `unread`: situations exited other than 0, or printed no class line.

- The owed ids cell holds the ids of the lines that filed `owed`.
- When slice 1 lands with other tokens than its plan's, the join and part 2350 follow slice 1's landed `--tsv`, and the blind author is told before writing part 2350.
- `felix retro` never writes `facts.log`. Slice 1's `--change` never does.

### C11. How a fixture points the engine at a repository

- `FELIX_HOME=<home>` with `<home>/projects/<p>/project.json` and `CLAUDE.md`.
- `FELIX_MEMORY=<memory root>`.
- The repository's root holds an untracked `.felix` file naming `<p>`.
- Run `"$FELIX" retro <repo> ...`, or `( cd <repo> && "$FELIX" retro ... )`. `$FELIX` is the suite's copy. Part 2350 runs its own copy (Task 8).
- The main ref is written inside a part with `_fx_git`. The project's deny row refuses `update-ref` on a remote-tracking ref when a session types it, so never try a fixture command by hand in a session.

### C12. Stated limits (the report repeats them)

- A fix merged through a real merge commit is judged by the merge's subject (`Merge branch ...`), so it reads weak.
- A revert-subject commit that deletes a file C created, and names nothing, is not seen: those lines are excluded.
- Line edits are not followed across renames: the lines are excluded.
- Only the `origin` remote is read.
- Where committer times on the chain go backwards, the window and `--since` follow chain order as C3 says.
- A change with no PR number reads `could not look` for issues. That is all of Veldra's changes and 38 of Elenchus's newest 50 closed ones, which are direct commits or plain merges.

## Review Focus

Each of these is pinned by a named assertion in the owning task's blind part.

1. **A fresh clone never fetched since.** git writes no reflog for `origin/main` on clone, so the as-of time must come from `origin/HEAD`'s clone entry. This is the engineering manager's first run. Pinned: R1 and R1b in part 2310 (Task 1).
2. **Paths with spaces and non-ASCII bytes, and subjects holding a tab.** A real repository has them, and they break blame arguments and TSV cells. Pinned: R2 in part 2320.
3. **A repository whose git configuration changes git's output.** This covers a textconv driver in `.gitattributes`, `diff.external`, `blame.ignoreRevsFile`, `log.showSignature`, `diff.noprefix` and `core.quotePath`. The record must not change. Pinned: R3 in part 2320.
4. **A change holding a binary file, a submodule pointer, a symlink and a file with no final newline.** The run must finish, count correctly and still find a later fix. Pinned: R4 in part 2320.
5. **A default branch not named main.** `origin/HEAD` names `origin/master` and there is no `origin/main`. Pinned: R5 in part 2310.

## Tasks

### Task 0: Preflight and the branch

**Files:**
- Create: none yet. The branch carries copies of the design and this plan.

**Interfaces:**
- Consumes: nothing.
- Produces: a worktree on branch `claude/lane-retro`, cut from `origin/main`.

- [ ] **Step 1: Check the gates on starting.** Run `gh pr list --repo LeavesJ/felix-home --state open --json number,title,files` and count the PRs that touch `engine/`. Expected: 10 or fewer. If there are more, stop and wait.
- [ ] **Step 2: Check no live session holds this work.** Run `ListAgents`, and `git -C <home> for-each-ref refs/heads refs/remotes --format='%(refname)'`, looking for a retro branch. Expected: none.
- [ ] **Step 3: Check the part numbers are free.** For every ref, run `git ls-tree --name-only <ref> engine/harness/tests/parts/` and look for 2310 to 2360. Expected: none used. Slice 0's plan takes 2200 to 2240 and slice 1's takes 1900 to 1970. If any of 2310 to 2360 is used, take the next free block of ten, and rename the parts everywhere in this plan.
- [ ] **Step 4: Make the worktree** from `origin/main` (`git worktree add -b claude/lane-retro <path> origin/main`). Copy the design and this plan from `claude/lane-situations-owed` (`git checkout <lane sha> -- docs/2026-10-29-capability-lane-first-slices-design.md docs/2026-10-29-lane-slice-2-plan.md`). Commit, ending the message with `Felix-Lane: capability`, and push.

### Task 1: Blind parts for the come-back half (Opus 5.5)

The blind author reads the design and this plan's Contracts, the driver `engine/harness/tests/run`, `tests/lib/*.sh` and existing parts for conventions. The author never reads `lib/retro*.sh` or `cmd_retro`. Felix runs as a black box.

**Files:**
- Create: `engine/harness/tests/lib/retro.sh`, the builders. Functions only, all named `_retro_*`. They are free of clashes with `_rt_*`, which `receipt.sh` holds.
- Create: `engine/harness/tests/parts/2310-retro-selection-and-as-of-blind.sh`
- Create: `engine/harness/tests/parts/2320-retro-come-back-rules-blind.sh`
- Create: `engine/harness/tests/parts/2330-retro-reopened-issues-blind.sh`
- Create: `engine/harness/tests/parts/2340-retro-seal-and-sample-blind.sh`
- Modify: `engine/harness/tests/run:156`, adding `. "$HERE/lib/retro.sh"` after `lib/recon.sh`.
- Modify: `engine/harness/tests/run:384`, adding the four part lines after `2120-wave-1-combine-blind.sh`.

**Interfaces:**
- Consumes: the suite helpers `ok NAME`, `bad NAME [WHY]`, `is NAME GOT WANT`, `has NAME TEXT PART` and `skip NAME WHY`; `_fx_cd` and `_fx_git` (part 0002); `_copy_content` (part 0004); `$FELIX`, `$TMP` and `$REAL_HARNESS`.
- Produces: assertion names prefixed `retro:`, and the Review Focus names R1 to R5 as given below.

- [ ] **Step 1: Write `tests/lib/retro.sh`.** It needs builders for:
    - a home with one project and a memory root (C11);
    - a repository whose commits carry pinned author and committer dates, written through `_fx_git`;
    - setting `refs/remotes/origin/main` (and optionally `origin/HEAD`) with a reflog entry at a pinned time;
    - running `felix retro` with the fixture's environment, keeping stdout, stderr and status apart;
    - a stub directory first on PATH for `gh`, `curl`, `wget` and `date`, each logging its argv.

    Each part builds its own fixture under `$TMP/<its own dir>`, uses physical paths, and does not depend on another part.

- [ ] **Step 2: Write part 2310** (selection, as-of, output, record, CLI). Every run passes `--no-replay`. Status is asserted only as `open` or not `open`. Assertions:
    - §8.7: "A change whose window runs past the as-of time is open, and left out of the rate". Check the C3 edges: exactly `D·86400` before the as-of time is taken, one second later is listed `open`, and `counts` excludes it.
    - §8.7: "`--last 3` on a history whose two newest changes are open selects the three newest closed changes, and lists the two open ones apart". Check the `change` row order, `select last 3`, `counts` N=3 O=2, and `stop last <sha of the third>`.
    - `--since`: takes the closed changes on or after the date, with `stop since <sha>` naming the first change before it. `select since <date>`.
    - A history shorter than N: `stop root`, with N the number taken.
    - The as-of row: the newest reflog time of `origin/main`, its ref in cell 3. A newer `FETCH_HEAD` does not move it.
    - **R1:** a clone made with `git clone` and never fetched since reads `as_of` at the clone's time, with `refs/remotes/origin/HEAD` in cell 3.
    - **R1b:** a repository where neither `origin/main` nor `origin/HEAD` has a reflog entry exits 1 with C2's sentence, prints nothing, and writes no record.
    - **R5:** `origin/HEAD` names `origin/master` and there is no `origin/main`. The `main` row names `refs/remotes/origin/master`.
    - No main ref: exit 1 with C2's sentence.
    - Not bound: exit 1, `felix: retro: no project governs <root>`.
    - Usage: each case in C2 gives its status. Neither a usage error nor a missing value writes a record.
    - `felix help` holds C1's usage line, and `felix retro --help` exits 0.
    - The record: its path follows C5, its bytes equal `--tsv` stdout, and a human run with the same arguments writes the same file.
    - The human report's pinned lines (C6) hold the counts from `--tsv`, the last line is `record: <path>`, and no line holds `%`.
    - Read-only: every file under the repository's work tree and `.git` keeps its bytes and mtime, and so do the outputs of `git for-each-ref`, `git worktree list --porcelain`, the config file and the index. Nothing under the home or the memory root changes except the one record file.
    - Determinism: two runs give identical bytes. A run with a `date` stub that prints `2099-01-01` gives the same bytes. Without `--issues`, the `gh`, `curl` and `wget` stub logs stay empty.
    - `window 14` prints `window 14 unsealed`, and `window 30` prints `sealed`.

- [ ] **Step 3: Write part 2320** (rules 1 and 2, exclusions, merges). Every run passes `--no-replay`. One scripted history, all windows closed. Assertions on the `change` rows' cells 4 to 9:
    - §8.7: "A squash merge reverted by a commit whose subject starts "Revert" and names it is a revert come-back". Check both naming forms of C8: `This reverts commit <sha>.` and `Revert "<subject>" (#n)`.
    - §8.7: "A lowercase `revert(x):` subject that names nothing, but edits the change's lines, is a revert".
    - §8.7: "A commit with an ordinary subject and a body line starting "Reverting" is not a revert". It reads weak if it edits a line, and the change is not `came-back`.
    - §8.7: "A later `fix:` commit editing an added line is strong. A `docs:` commit editing one is weak, and not a come-back."
    - §8.7: "An added file renamed whole is excluded. So is a version file bumped, through `retro.tsv`". Control: the same bump without the row reads strong. A file deleted whole is excluded too.
    - The window's end is inclusive: a `fix:` at exactly `ct(C) + D·86400` is strong; one at one second more is not counted.
    - A later commit that edits only lines C did not add is not counted.
    - §8.7: "A history of real merge commits with no PR numbers is read through `C^1`". Use `git merge --no-ff`. The merge is one change row and its merged commits are none. A later direct `fix:` on a line the merge added is strong, and a revert naming one of the merged commits' shas is a revert of the merge.
    - **R2:** a change adds lines to `dir one/é b.txt` and its subject holds a tab. A later `fix:` of one line is strong, every `change` row has 13 cells, and the subject prints with a space where the tab was.
    - **R3:** with `diff.external`, a `.gitattributes` textconv driver on `*.txt` (the driver configured), `blame.ignoreRevsFile` naming the fix commit, `log.showSignature=true`, `diff.noprefix=true` and `core.quotePath=true` set in the fixture repository, `--tsv` is byte-identical to the run without them.
    - **R4:** a change adds a binary file, bumps a submodule pointer, adds a symlink and appends a line to a file with no final newline. The run exits 0, the binary and the pointer add to no count, and a later `fix:` of the appended line is strong.

- [ ] **Step 4: Write part 2330** (rule 3). origin's URL is `https://github.com/example/widget.git`, set as config only. Assertions:
    - §8.7: "`--issues` with `gh` stubbed as unreachable reads "could not look" for that kind, never "not reopened"". The stub exits 1 and logs. The cell reads `could not look`, the stub log shows `pr view <n>`, and `kinds` counts it in cell 5.
    - gh missing from PATH: `could not look`.
    - A reachable stub, matched on argv as C8 pins it:
        - PR 12 closes issue 7, reopened 5 days after C: `reopened #7`, status `came-back`;
        - PR 13 closes none, message `fixes #9`, no reopen event: `not reopened`;
        - PR 14 closes none, no keyword: `none closed`;
        - a reopen at `ct(C) + D·86400 + 1`: `not reopened`.

    - A change with no PR number reads `could not look`, and the stub log has no call for it.
    - origin set to a non-GitHub URL: every closed change reads `could not look`, and the stub is never called.
    - Without `--issues`: cell 10 is `-`, `kinds` cells 4 and 5 are `-`, and the stub log is empty.
    - Open changes are never asked about.

- [ ] **Step 5: Write part 2340** (seal and sample). Assertions:
    - The `sealed` cell equals C7's formula, recomputed by the part over the harness that ran and the fixture's table. With the table absent, the third line is `table\t-`.
    - Adding one `exclude` row changes the seal, and removing it gives the old seal back.
    - One change adding 25 lines, each changed by its own `fix:` commit, and 12 weak edits of other lines. Exactly 20 strong and 10 weak `sample` rows. They are the first by C9's key, recomputed by the part with `git hash-object`, in key order, strong first. Every pair is in its change row's cells.
    - Fewer candidates than the cap: every candidate appears.
    - No pair from an open change appears.
    - The human report shows `sample for blind labels: 20 strong, 10 weak`, and the `came back:` line holds `precision: unmeasured here, a headline needs 0.7 on the blind sample`.

- [ ] **Step 6: Commit and push.** Message `test(retro): blind parts for come-backs, written from the design and the contracts`, ending with `Felix-Lane: capability`.

### Task 2: Show the come-back parts red on main (Sonnet 5.5, high)

**Files:**
- Test: parts 2310 to 2340, against the engine as main holds it (the branch has no engine change yet).

**Interfaces:**
- Consumes: Task 1's parts.
- Produces: the red counts for the PR body and the handoff note.

- [ ] **Step 1: Run the four parts alone, from an empty directory.**

```
( cd "$(mktemp -d)" && bash <worktree>/engine/harness/tests/run --part 2310-retro-selection-and-as-of-blind.sh 2320-retro-come-back-rules-blind.sh 2330-retro-reopened-issues-blind.sh 2340-retro-seal-and-sample-blind.sh ) > <scratch>/red-1.log 2>&1
command grep -c '^  FAIL' <scratch>/red-1.log
```

Expected: every assertion about retro's output fails, because main prints `felix: unknown command: retro. Try 'felix help'.` and exits 1. Fixture controls pass. Part mode exits 0 whatever fails, so read the counts from the log.

- [ ] **Step 2: Sort the passes.** List every assertion that passed on main. Each must be a fixture control, or vacuous on main for a stated reason, as `docs/2026-10-24-audit-fixes/b09-*.md` §8 does. Any other pass goes back to the blind author.
- [ ] **Step 3: Write the counts into the branch's handoff note** under `docs/handoff/pending/`. Commit and push.

### Task 3: The table (Sonnet 5.5, high)

**Files:**
- Create: `projects/felix/retro.tsv`, `projects/veldra/retro.tsv` (C4's rows).
- Modify: `engine/harness/templates/schemas.tsv:134`, inserting C4's comment and row after the `.snapshot-ack.tsv` row.

**Interfaces:**
- Consumes: nothing.
- Produces: `retro.tsv`, readable by `felix_table_check` (`lib/table.sh:131`).

- [ ] **Step 1: Add the two project tables first, and see schema-check fail.** Run `engine/harness/bin/schema-check` from the worktree root. Expected: exit 1, naming both `retro.tsv` files as having no schema row.
- [ ] **Step 2: Add the `schemas.tsv` row** exactly as C4 gives it.
- [ ] **Step 3: Run schema-check again.** Expected: exit 0.
- [ ] **Step 4: Commit and push**, `feat(retro): the retro.tsv table and its schema row, with the rows sealed for two projects`, ending `Felix-Lane: capability`.

### Task 4: The walk, the header, the record and the command (Sonnet 5.5, xhigh)

**Files:**
- Create: `engine/harness/lib/retro-rules.sh` (sealed): defaults, main ref, as-of, table, selection, window, seal.
- Create: `engine/harness/lib/retro.sh` (unsealed): the run, both reports, the record.
- Modify: `engine/harness/felix:459`, adding C1's usage line after `felix qualify [check]` in `usage()` (`:399-490`).
- Modify: `engine/harness/felix:6663`, adding `cmd_retro` after `cmd_status` (`:6658-6663`).
- Modify: `engine/harness/felix:6700`, adding `retro)     shift; cmd_retro "$@" ;;` after `qualify)`.
- Test: part 2310.

Slices 0 and 1 edit `felix` first. Re-read the file and place the lines by their neighbours, not by these numbers.

**Interfaces:**
- Consumes: `need_value`, `die`, `FELIX_HOME_DIR`, `SCRIPT_DIR` (felix); `felix_resolve_project START HOME`, `felix_repo_root START` and `felix_mem_dir PROJDIR` (`lib/resolve.sh`); `felix_table_check SCHEMAS FILE` and `felix_table_rows FILE` (`lib/table.sh`).
- Produces, in `lib/retro-rules.sh`:
    - `FELIX_RETRO_WINDOW=30`, `FELIX_RETRO_LAST=50`, `FELIX_RETRO_SAMPLE_STRONG=20`, `FELIX_RETRO_SAMPLE_WEAK=10`, `FELIX_RETRO_FIX='^(fix|hotfix|revert)(\([^)]*\))?!?:'`, set when the file is sourced;
    - `felix_retro_main_ref ROOT` prints `REF<TAB>SHA40`, or returns 1;
    - `felix_retro_as_of ROOT REF` prints `EPOCH<TAB>LOGREF`, or returns 1;
    - `felix_retro_table TABLE SCHEMAS` prints `KIND<TAB>PATTERN` rows, or returns 1 with C2's line on stderr;
    - `felix_retro_select ROOT TIP ASOF WINDOW LAST SINCE` (LAST or SINCE `-`) prints `pick<TAB>SHA40<TAB>CT<TAB>closed|open<TAB>SUBJECT` rows, newest first, then one `stop<TAB>REASON<TAB>SHA40` line;
    - `felix_retro_window ROOT TIP C WINDOW` prints `SHA40<TAB>CT<TAB>SUBJECT` per window commit, oldest first, T last;
    - `felix_retro_seal HARNESS TABLE` prints the seal.

- Produces, in `lib/retro.sh`: `felix_retro ROOT PROJDIR LAST SINCE WINDOW ISSUES REPLAY TSV`. LAST, SINCE and WINDOW may be `-` (use the defaults); ISSUES, REPLAY and TSV are 0 or 1. It prints the report, writes the record and returns C2's status.
- Produces, in `felix`: `cmd_retro "$@"`. It parses C1 with `need_value`, exits 2 through `die "retro: <why>" 2`, exports `GIT_OPTIONAL_LOCKS=0`, sources `lib/table.sh`, `lib/retro-rules.sh` and `lib/retro.sh` with `|| exit 1` (lazily, as `cmd_inventory` does), resolves the project from `<repo>`, and calls `felix_retro`.

- [ ] **Step 1: See part 2310 red** with Task 2's command, naming the one part. Expected: the same failures as Task 2.
- [ ] **Step 2: Implement** the functions above, to C1 to C7. Every closed change reads `quiet` until Task 5. Replay reads `off` whatever the flag until Task 9. Every `git log` carries `--no-show-signature`. Times print as UTC, through `TZ=UTC0` with `--date=format-local:`, or by days-from-civil arithmetic as `lib/cost.sh`'s `_fc_epoch` does. Never through `date -d` or `date -j`.
- [ ] **Step 3: Run part 2310.** Expected: no `  FAIL` line.
- [ ] **Step 4: Run the lints this touches.** Run `--part` for `1497-lib-awk-gawk-names-blind.sh`, then for `0992-sort-comm-join-and-uniq-read-bytes-in-the-c-l.sh 0994-bash-s-own-collation-and-the-bsd-text-tools.sh 0996-continued.sh`, then for `1530-patch-reads-the-repository-not-a-diff-setting.sh`. Then run `engine/harness/bin/independence-scan`. Expected: no `  FAIL`, and exit 0.
- [ ] **Step 5: Commit and push**, `feat(retro): felix retro walks the closed changes as of the main ref's last fetch and records them`, ending `Felix-Lane: capability`.

### Task 5: Lines and the come-back rules (Sonnet 5.5, xhigh)

**Files:**
- Create: `engine/harness/lib/retro-lines.sh` (sealed).
- Modify: `engine/harness/lib/retro-rules.sh`, adding the rule functions.
- Modify: `engine/harness/lib/retro.sh`, applying them per closed change.
- Modify: `engine/harness/felix`, where `cmd_retro` also sources `lib/retro-lines.sh` with `|| exit 1`.
- Test: part 2320.

**Interfaces:**
- Consumes: `felix_retro_window`, `felix_retro_table`, `FELIX_RETRO_FIX`.
- Produces, in `lib/retro-lines.sh`:
    - `felix_retro_added ROOT C` prints `PATH<TAB>START<TAB>COUNT` per added hunk, skipping submodule pointers, and returns 1 on a failed read;
    - `felix_retro_outcomes ROOT C T WINDOWFILE ADDEDFILE ROWSFILE` prints `PATH<TAB>LINE<TAB>survived|changed|excluded|unread<TAB>SHA40|-` per added line. The sha is Y for `changed`.

- Produces, in `lib/retro-rules.sh`:
    - `felix_retro_is_revert SUBJECT` returns 0 or 1;
    - `felix_retro_names ROOT X C` returns 0 when X names C (C8);
    - `felix_retro_is_fix SUBJECT ROWSFILE` returns 0 or 1;
    - `felix_retro_excluded PATH ROWSFILE` returns 0 or 1.

- [ ] **Step 1: See part 2320 red** against Task 4's head. Expected: every change reads `quiet`, so the revert, strong, weak and excluded assertions fail, and R3's identity holds vacuously.
- [ ] **Step 2: Implement** C8's line reading and rules 1 and 2. The `-L` ranges for one file go to one blame call. A path is passed after `--`, never as an option. `core.quotePath=false` goes on each diff and blame. git ends a `+++ b/<path>` line with a tab when the path holds a space (measured on git 2.56), so strip one trailing tab before reading the path.
- [ ] **Step 3: Run part 2320, then part 2310 again.** Expected: no `  FAIL` line in either.
- [ ] **Step 4: Run Task 4's lint parts and `bin/independence-scan`.** Expected: clean.
- [ ] **Step 5: Commit and push**, `feat(retro): reverts, strong fixes and weak edits read by reverse blame over each change's added lines`, ending `Felix-Lane: capability`.

### Task 6: Reopened issues (Sonnet 5.5, xhigh)

**Files:**
- Modify: `engine/harness/lib/retro-rules.sh`, adding the issue rule.
- Modify: `engine/harness/lib/retro.sh`, for the issue cell and the `kinds` cells.
- Test: part 2330.

**Interfaces:**
- Consumes: `felix_retro_select`'s rows.
- Produces:
    - `felix_retro_slug ROOT` prints `OWNER/NAME` or nothing;
    - `felix_retro_issue ROOT C CT WINDOW SLUG` prints the issue cell (C5, cell 10) by C8's rule 3.

- [ ] **Step 1: See part 2330 red** against Task 5's head. Expected: the issue cells read `-` with `--issues`.
- [ ] **Step 2: Implement** C8's rule 3, with the gh argv exactly as pinned, and each line of gh's output checked for its shape before use.
- [ ] **Step 3: Run parts 2310 to 2330.** Expected: no `  FAIL` line.
- [ ] **Step 4: Commit and push**, `feat(retro): --issues asks GitHub which closed issues reopened, and reads could not look when it cannot`, ending `Felix-Lane: capability`.

### Task 7: The sample (Sonnet 5.5, high)

**Files:**
- Modify: `engine/harness/lib/retro-rules.sh`, adding the draw.
- Modify: `engine/harness/lib/retro.sh`, for the sample rows and the human section.
- Test: part 2340.

**Interfaces:**
- Consumes: the revert, strong and weak cells from Task 5; `felix_retro_seal`.
- Produces: `felix_retro_sample SEAL PAIRSFILE` (rows `strong|weak<TAB>C40<TAB>X40`), which prints C9's `sample` rows.

- [ ] **Step 1: See part 2340 red** against Task 6's head. Expected: the sample assertions fail and the seal assertions pass (Task 4 built the seal).
- [ ] **Step 2: Implement** C9.
- [ ] **Step 3: Run parts 2310 to 2340.** Expected: no `  FAIL` line. The come-back half is complete. It can be measured now with `--no-replay` (Task 12, step 1); the seal stays valid as long as review leaves the two sealed files alone.
- [ ] **Step 4: Commit and push**, `feat(retro): a fixed, sealed draw of strong and weak pairs for blind labels`, ending `Felix-Lane: capability`.

### Task 8: The replay part, once slice 1 is on main (Opus 5.5)

**Files:**
- Create: `engine/harness/tests/parts/2350-retro-replay-blind.sh`
- Modify: `engine/harness/tests/run`, adding its line after 2340's.
- Modify: `engine/harness/tests/lib/retro.sh`, when builders are needed.

**Interfaces:**
- Consumes: slice 1's landed `felix situations --change <base>..<head> --tsv` contract (design §7.7 and slice 1's plan's Contracts), and C10.
- Produces: assertions prefixed `retro: replay`.

- [ ] **Step 1: Rebase `claude/lane-retro` on `origin/main`** once slice 1 has landed. Run parts 2310 to 2340. Expected: no `  FAIL`.
- [ ] **Step 2: Compare slice 1's landed `--tsv` with C10.** Check the verdict tokens and the id cell against `felix situations --change HEAD~1..HEAD --tsv` run in the worktree. If they differ, tell the blind author before Step 3, and change C10 in this plan in the same commit.
- [ ] **Step 3: Have the blind author write part 2350.** It makes its own harness copy with `_copy_content "$REAL_HARNESS" <dir>/harness`, replaces that copy's `templates/situations.tsv` with fixture classes that slice 1's table check accepts, and gives the fixture project a `probes.tsv`. Assertions:
    - §8.4: three came-back changes filed `owed`, `no row` and `could not look`. The filing order is owed, then could not look, then no row, so the `no row` change must sit where no class is undecided on either side. `split` counts each once.
    - A change slice 1 blinded at head files `owed`.
    - §8.4: "Every record carries the owed ids slice 1 printed". Cell 12 equals the ids of the lines that filed `owed` in the part's own run of `felix situations --change C^1..C --tsv`.
    - Every closed change, came back or not, has a replay cell. Open changes have `-`.
    - A fixture where situations cannot run, for example a refused `probes.tsv`: every closed change reads `unread`, and the run still exits 0.
    - `--no-replay`: header `replay off`, cells 11 and 12 `-`, and `split - - - -`.
    - With replay on, two runs give identical bytes (§8.7, §7.9 d).
    - `facts.log` under the memory root is unchanged, and the repository is untouched, as in part 2310.

- [ ] **Step 4: Show 2350 red twice.** First on a branch commit holding only the part, with main's engine (unknown command). Then against Task 7's head, where replay reads `off`. Record both counts in the handoff note.
- [ ] **Step 5: Commit and push**, ending `Felix-Lane: capability`.

### Task 9: The replay join (Sonnet 5.5, xhigh)

**Files:**
- Create: `engine/harness/lib/retro-replay.sh` (unsealed).
- Modify: `engine/harness/lib/retro.sh`, calling the join per closed change when REPLAY is 1.
- Modify: `engine/harness/felix`, where `cmd_retro` also sources `lib/retro-replay.sh` with `|| exit 1`.
- Test: part 2350.

**Interfaces:**
- Consumes: slice 1's `felix situations --change ... --tsv`.
- Produces: `felix_retro_replay ROOT BASE40 C40 FELIX` prints `<owed|no row|could not look|unread><TAB><ids|->`.

- [ ] **Step 1: Implement** C10. Run it in a subshell, so the cwd and the variables of `felix_retro` stay as they were.
- [ ] **Step 2: Check that the seal did not move.** `git diff <Task 7 head> -- engine/harness/lib/retro-rules.sh engine/harness/lib/retro-lines.sh` must be empty.
- [ ] **Step 3: Run parts 2310 to 2350**, five names in one `--part` run. Expected: no `  FAIL`.
- [ ] **Step 4: Commit and push**, `feat(retro): each change is filed against what felix situations said it owed`, ending `Felix-Lane: capability`.

### Task 10: Adversarial review and fixes (Opus 5.5, then the implementer)

**Files:**
- Test, when needed: `engine/harness/tests/parts/2360-retro-review-fixes-blind.sh`

**Interfaces:**
- Consumes: the branch diff against `origin/main`, the design and this plan.
- Produces: findings, and the fixes.

- [ ] **Step 1: Review.** The reviewer reads the diff, the design and the Contracts, and checks at least:
    - every rule C7 names lives in the two sealed files;
    - no governed name and no lane-excluded file is touched;
    - nothing writes into the repository, the home or `facts.log`;
    - "could not look" is never turned into "not reopened", `no row` or 0;
    - the Review Focus items.

- [ ] **Step 2: Fix.** A code finding goes to the implementer, and red twice moves the fix to Opus. A finding that needs a new assertion goes to a blind author, who writes part 2360 from the finding restated as required behaviour. The part is shown red on the pre-fix head, and its line goes in the driver.
- [ ] **Step 3: Run parts 2310 to 2360.** Expected: no `  FAIL`. If a sealed file changed, say so in the handoff note: a come-back measurement from Task 7 is void and is taken again in Task 12.
- [ ] **Step 4: Commit and push.**

### Task 11: Version, handoff, record, gate and PR (Sonnet 5.5, high)

**Files:**
- Modify: `engine/.claude-plugin/plugin.json:4`, the next free patch slot at this moment.
- Create: `docs/handoff/pending/<UTC stamp>-claude-lane-retro.md`, through `felix handoff --section FILE`.
- Modify: `projects/felix/lane-next.tsv` (slice 0's table, columns `lane next`; slice 1's PR leaves the `capability` row naming this slice). Set that row's `next` to `come-backs, slice 2: the sealed report from felix retro on the three repositories (branch claude/lane-retro)`.
- Modify: `engine/harness/tests/assertions.tsv`, `engine/harness/tests/red.tsv` (written by the record).

**Interfaces:**
- Consumes: the whole branch.
- Produces: a PR in the landing queue.

- [ ] **Step 1: Rebase on `origin/main`** and run parts 2310 to 2360. Expected: no `  FAIL`.
- [ ] **Step 2: Commit everything the PR carries** before the record: the version bump, the handoff section (its gate line pointing at the PR to be opened), and the `lane-next.tsv` move. Push.
- [ ] **Step 3: Ask the queue owner** (today the "Inventory next steps" session) for the record slot. Wait for a yes.
- [ ] **Step 4: Record.** Run `engine/harness/tests/run --record-assertions` under `nohup`, logging to a file, and poll the log. Expected: `0 failed` and a written `red.tsv`. Commit `assertions.tsv` and `red.tsv`, and push.
- [ ] **Step 5: Gate**, after the record has finished, in the same worktree: `~/Documents/Felix/engine/harness/felix gate`. Expected: pass. The result goes in the PR body, not a commit.
- [ ] **Step 6: Open the PR** with `engine/harness/felix pr --create --title "feat(retro): felix retro counts the merged changes that came back, sealed, and files them against what each owed (0.49.<N>)"`. Turn on the CI monitor. The lander merges it on green. If the slot was taken meanwhile, take the next one and go back to Step 2.

### Task 12: The sealed report (Opus 5.5 for the labels' brief; any model for the runs)

**Files:**
- Create: `docs/<date>-come-backs-report.md`, and `docs/pdf/<date>-come-backs-report.pdf` rendered from it.
- Records, outside the tree: `~/.felix/memory/{felix,elenchus,veldra}/retro/*.tsv`.

No engine file changes. The three runs are the operator's and stay out of the suite.

**Interfaces:**
- Consumes: the landed engine (`felix install` from the home after landing, per the constitution).
- Produces: the report PDF, sent to the founder.

- [ ] **Step 1: Run the come-backs on the three clones** without fetching, so each as-of time is the clone's own last fetch:
    - `felix retro /Users/a14808/Documents/Felix --tsv`
    - `felix retro /Users/a14808/Documents/Elenchus --tsv`
    - `felix retro /Users/a14808/ReserveGrid-OS --tsv`

    Expected, as of the 10-29 reflogs: felix-home takes 50 closed changes from 2026-09-23 to 09-26 (UTC), with 81 open. Elenchus takes 50 from 08-03 to 09-02 (UTC), with 7 open. Veldra takes 50 from 05-01 to 08-29, with 24 open. Each record states its seal, its as-of time and its fetch source.

- [ ] **Step 2: Run each once with `--issues`.** Report that kind apart, with its could-not-look counts.
- [ ] **Step 3: Label the samples blind.** For each `sample` row, a labeller that never saw the rules gets only `git show C` and `git show X`. The labeller is a person, or a model whose output is marked as a sample label. The question: "Does X undo, repair or correct something C introduced? yes or no." Labels live only in the report.
- [ ] **Step 4: Write the report.** Per repository:
    - the rate as K of N, with the open count and the fetch time;
    - the weak count;
    - the split (owed, no row, could not look);
    - the strong rule's precision on its labels, and the weak sample's yes rate;
    - the seal and the engine version;
    - C12's limits.

    If the strong precision is under 0.7, the report says the rate is not yet usable as a headline. If a sealed rule changed after a result was seen, the report says so and gives the re-run. If most come-backs trace to misread intent rather than an engineering class, the report says that slice 5's questions move ahead of slice 3 (design §9).
- [ ] **Step 5: Render the PDF** with the renderer `~/Documents/BehaviorChangeBench/scripts/pdfs.py` uses (Markdown to HTML to headless Chrome), into `docs/pdf/`.
- [ ] **Step 6: Commit and PR.** Commit the report, its PDF and the `lane-next.tsv` move, setting `next` to slice 3's item or slice 5's, per Step 4. The commits end with `Felix-Lane: capability`. Push, and open the docs PR, which merges on green. Send the PDF to the founder.

## Coverage

| Design requirement | Contract | Part | Task |
|---|---|---|---|
| §8.1, §8.2 command, read-only, bound project | C1, C2, C5, C11 | 2310 | 4 |
| §8.2 selection, open apart, `C^1` base | C3 | 2310, 2320 | 4, 5 |
| §8.2 as of the last fetch | C3 | 2310 (R1, R5) | 4 |
| §8.3 rule 1 (revert) | C8 | 2320 | 5 |
| §8.3 rule 2 (strong, weak, exclusions) | C4, C8 | 2320 (R2 to R4) | 3, 5 |
| §8.3 rule 3 (reopened issue) | C8 | 2330 | 6 |
| §8.3 the table and its schema row | C4 | schema-check | 3 |
| §8.4 replay, filed per change, ids carried | C10 | 2350 | 8, 9 |
| §8.5 sealing | C7 | 2340 | 4 |
| §8.6 measures, sample, 0.7 bound | C5, C6, C9 | 2340 | 7, 12 |
| §8.7 acceptance, all ten bullets | C3, C8 | 2310 to 2330 | 4 to 6 |
| §8.7 real data | C12 | none (operator runs) | 12 |
| §8.8 limits | C12 | none | 12 |
| §3 anti-goals: no bare rate, could not look | C6, C8, C10 | 2310, 2330, 2340, 2350 | 4, 6, 7, 9 |
| §4 offline, deterministic, nothing written to the repository | C3, C5 | 2310, 2350 | 4, 9 |
| §4 how it lands | Global Constraints | none | 0, 11 |
