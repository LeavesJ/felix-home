# Come-backs (`felix retro`) Implementation Plan

> **For agentic workers:** run this plan as the founder's engine-build Workflow: spec, blind assertions, red first, implementation, adversarial review, gate. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** `felix retro` counts which merged changes came back within 30 days (revert, strong fix, reopened issue), over the changes whose window has closed as of the main ref's last fetch, and files each come-back against what `felix situations --change` said it owed.

**Architecture:** A read-only command over git history. Two sealed libraries hold every rule (`lib/retro-rules.sh`, `lib/retro-lines.sh`). Their hash, with the project's tables and slice 1's seed, goes into every record. An unsealed library (`lib/retro.sh`) runs the walk, prints the report and writes one record under the memory root. The replay (`lib/retro-replay.sh`) is the last piece: it calls slice 1's `felix situations --change C^1..C --tsv` per change and hands the output to the sealed filing rule.

**Tech stack:** bash 3.2, git, BWK-and-gawk awk; `gh` only behind `--issues`.

**Spec:** `docs/2026-10-29-capability-lane-first-slices-design.md` (the design as corrected after the fact-check: the version Task 0 Step 6 copies from `claude/lane-situations-owed`; this plan's engine line numbers were re-read at `01e24cfc`). The founder approved the design on 10-29, before the fact-check. The corrections that change a rule are listed in its §11, for him to check while reading. This plan implements §8 (slice 2), under §1 to §5, §7.6, §7.7 and §9 to §12. The §11 calls that bind this slice are items 2, 3, 13 to 16, 21, 22, 33 to 41 and 43, each cited where it changes what is built. Item 37 changes nothing built: this slice measures come-backs.

## Global Constraints

- Bash 3.2 and git only: no jq, no python.
- Only awk that both BWK awk (local) and gawk (CI) run. Part 1497's `_awk_names` lints `lib/`. No `{n,m}` intervals in awk regexes.
- `LC_ALL=C` on every sort, comm, join and uniq (part 0992).
- `[[ =~ ]]` only inside a function that declares `local LC_ALL=C` (part 0996). So does a function where a bracket range in bash's own pattern syntax, such as `[0-9a-f]`, judges bytes the engine did not write (Rule 1, above `felix_json_str` in `lib/resolve.sh`).
- No bracket over digits alone in bash's own pattern syntax: a `case` arm, the right side of `[[ == ]]` or `[[ != ]]`, `${v#p}` and its kin, or a glob word. Spell it out, `[0123456789]`, not `[0-9]` (part 0998). An ERE after `[[ =~`, and awk, sed and grep programs, are outside this rule.
- Flags go through `need_value` (`engine/harness/felix:394-396`), never a bare `shift 2`.
- The engine names no project (invariant 1). `bin/independence-scan` greps `felix`, `lib`, `hooks` and `bin` case-insensitively for every governed name: bazaar, behaviorchangebench, elenchus, elenchus-capital-research, sv2-apps, team1, veldra, webapp. None may appear, even inside a word or a comment.
- The engine names no ecosystem without a declared reason. The gate's ecosystem section (`projects/felix/gate.sh:412-555`) fails on a whole-word, case-insensitive hit in `felix`, `lib`, `hooks` or `bin` of a word from `lib/detect.sh`'s `_felix_dep_grep` calls or from `engine/harness/ecosystem.tsv`'s `word` rows, less the muted `next`. It does not fail when an `allow` row of that table names the file and the word: `felix` may say npm, cargo, dotnet and rust, and no row names a `lib/retro*.sh` file. This plan is stricter than the gate, so no line of `felix` or `lib/retro*.sh`, comments included, says Cargo.lock, package-lock, express, python, node, npm, rust, cargo or any other of those words. C4's lock-file rows live only in `projects/veldra/retro.tsv`. Part 0650 (`0650-ecosystem.sh`) runs the gate's check over the suite's copy of `felix`, `lib`, `hooks` and `bin`, and that copy includes untracked files. Part 0650 passes `felix`'s allowed words, so each implementation task runs it (Task 4 Step 4) and also the ecosystem word check over the lines the branch adds to `felix`: `git -C <worktree> diff origin/main -- engine/harness/felix | command grep '^+' | command grep -wniE '<words>'`, where `<words>` is `sentry|opentelemetry|datadog|stripe|playwright|cypress|selenium|puppeteer|supabase|prisma|alembic|sqlalchemy|drizzle|typeorm|fastapi|flask|django|express|fastify|starlette|anthropic|openai|langchain|llama-?index|mistralai|cohere|ollama|google-generativeai|litellm|instructor|dspy|transformers|python|pip|poetry|pipenv|pytest|node|npm|yarn|pnpm|rust|cargo|dotnet|gradle|maven|composer|bundler|rubygems`. Expected: no output.
- Offline (invariant 2) and deterministic (the intent design's §9 (d) and falsifier 2): two runs with the network off and no key print identical bytes. The only network use is `--issues`. It is off unless asked for, and when GitHub is unreachable it reads "could not look".
- A check that cannot fail is not a check (invariant 5). Every new check is shown failing first.
- Never delete a home or a memory root (invariant 6).
- Records go under the memory root (`felix_mem_dir`, `lib/resolve.sh:253-256`). Nothing is written into a governed repository: its refs, index, config and worktree list stay as they were.
- Lane exclusions: never touch `lib/qualify.sh`, `lib/obligations.sh`, `lib/receipt.sh`, `lib/automerge.sh`, `lib/green-*.sh`, `lib/land-table.sh`, `lib/notify.sh`, `lib/own.sh`, `lib/status-land.sh`, or the `felix merge` and `felix land` code paths.
- Tables before code. Each new table is a new file with one new `schemas.tsv` row. No column is added to an existing table.
- Every engine line that runs porcelain `git diff` carries `--no-ext-diff` and `--no-textconv` on the same line (part 1530).
- Every new `felix` command appears in `usage()`. Part 0480 checks that only for the main dispatch block (`felix:6594`). `felix retro` is dispatched there, after the libraries load, so part 0480 covers it and it needs no usage assertion of its own (design §4, §11 item 21). Part 2310 checks the line as well.
- Each new file stays under 500 lines, as slices 0 and 1 state. If `lib/retro-rules.sh` would pass 500, stop and amend C7 before splitting it, because the seal names its files.
- Parts are `NNNN-name.sh`, at most 1,000 lines, sourced once by the driver in name order; the driver stays at or under 500 lines (part 1040). It had 475 at `origin/main` `01e24cfc`, and the lane's three slices add 22 (slice 0: 7, slice 1: 8, this slice: 7 with part 2360). Task 0 adds this slice's 7 to `origin/main`'s count and to the part and lib lines every open engine PR adds; if the total passes 500, stop before the blind stage and tell the queue owner. A `tests/lib` file defines functions and nothing else (part 0006). Fixture git writes go through `_fx_cd` and `_fx_git` (part 0002).
- Anti-goals: no project score, level or grade; nothing a person chats with; "could not look" never printed or counted as anything else; no bare come-back rate (always with its denominator, its open count and `precision: unmeasured`; only the sealed report carries measured precision); no model on any path; the engine never reads the sample labels.
- Non-goals: nothing blocks, holds, comments or enforces; no new GitHub writes; no file in anyone's CI; come-back records carry no provider or model field; no dispatching agents and no choosing models.
- Models: each task names its model and effort. An implementation stage (Tasks 3 to 7 and 9, and Task 10's fixes) whose part goes red twice moves up to Opus 5.5 at xhigh. No stage runs at max.
- How it lands: one engine PR. No new engine branch while more than 10 engine PRs are open (`gh pr list`). The PR bumps the patch version in `engine/.claude-plugin/plugin.json` and puts it in its title, taking the next free patch slot at landing. No slot is named here: on 10-29, 0.49.310 to 0.49.314 were claimed.
- Suite manners: commit everything before the record; red and gate never share a worktree; at most four part runs at once across the Mac; no whole-suite run while another session's record or gate holds the queue (ask the queue owner first; today that is the "Inventory next steps" session).
- Lane mark (design §6.2, §11 item 2): every commit of the branch that is not a merge ends its message with the whole line `Felix-Lane: capability`. `felix merge` copies only non-merge messages (`felix:2106-2107`), and a GitHub squash keeps them only with GitHub's default message, so a mark on a merge commit is lost.

## Contracts

The blind authors read the design and this section, and nothing else of the plan. The author of part 2350 also reads slice 1's plan's C2, C5, C6, C8 and C12, the table and `--tsv` contract this slice consumes. That author also reads slice 1's C3.3 (scratch readings), C4 (terms and class states), and C13's Home, Probe states and Detector facts bullets. These say how a fixture project's `probes.tsv` (`predicate\tgrounds\twhen\tprobe\twitness`) makes a class ACTIVE, DORMANT or UNKNOWN on each side of `--change`. The author of part 2360 reads the finding Task 10 Step 2 hands over, restated as required behaviour (C13). The implementer never writes or edits a blind part (parts 2310 to 2360 and `tests/lib/retro.sh`). A part the implementer thinks wrong goes back to its blind author with the reason. Everything here is decided in the plan unless it quotes the design.

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
- `-h` or `--help` anywhere: prints `felix help`'s stdout byte for byte, with stderr empty, and exits 0. It wins over every other argument, a bad one included, so `--last -h` is help.
- Flags and the one positional may come in any order. A flag's value is the next word, whatever it is, so `--last --tsv` is a bad N (2). need_value refuses a flag that ends the arguments or whose value is empty (1). A flag given twice is a usage error (2).
- `felix help` holds the line `felix retro [<repo>] [--last N | --since YYYY-MM-DD] [--window D] [--issues] [--no-replay] [--tsv]` as a line of its own, after leading blanks. Its description goes on the lines below it, as `felix cost`'s does.

### C2. Exit status and refusals

Every refusal is one line on stderr starting `felix: retro: `, except need_value's own line, `felix: felix: <flag> needs a value`. On exit 0, stderr is empty: nothing from git or gh reaches it.

| Status | When | Stdout | Record |
|---|---|---|---|
| 0 | a report was printed and its record written | the report | written |
| 1 | a flag was given with no value (need_value; stderr holds `--last needs a value`, with the flag's own name) | nothing | none |
| 2 | any other usage error: an unknown flag, a second positional, a flag given twice, a bad N, date or D, `--last` with `--since`, a `<repo>` that is not a directory | nothing | none |
| 1 | `<repo>` is in no git work tree: `felix: retro: <repo as given> is in no git work tree` | nothing | none |
| 1 | no project governs the repository: `felix: retro: no project governs <root>` | nothing | none |
| 1 | no main ref (C3): `felix: retro: <root> has no main ref: neither refs/remotes/origin/HEAD nor refs/remotes/origin/main names a commit` | nothing | none |
| 1 | no as-of (C3): `felix: retro: neither <main ref> nor refs/remotes/origin/HEAD has a reflog entry, so when the main ref was last fetched is not known; nothing was counted` | nothing | none |
| 1 | `retro.tsv` refused (C4): `felix: retro: <table path>:<line>: <why>`. `<line>` is the physical line of the first refusal, or `-` for one about the whole file. `<why>` is felix_table_check's reason token (for example `cells`) for a shape refusal, `kind '<k>' is not exclude or fix` for a bad kind, and `pattern '<p>' is not an ERE` for a pattern grep -E refuses | nothing | none |
| 1 | the record could not be written: `felix: retro: the record could not be written: <path>` | the report | none |

- **Order.** Help is checked first (C1). Then the arguments are read left to right, and the first bad one stops the run: an unknown flag, a second positional, a flag given twice, or a bad N, date or D (2), or a flag that ends the arguments or has an empty value (1). Then, in this order: `--last` with `--since` (2); `<repo>` is not a directory (2); no git work tree (1); no project governs it (1); `retro.tsv` refused (1); no main ref (1); no as-of (1). The first check that fails is the one line printed. A part's fixture for one refusal makes every check before it pass.
- **Placeholders.** `<main ref>` is the full ref name, as in `neither refs/remotes/origin/main nor refs/remotes/origin/HEAD has a reflog entry`. `<repo as given>` is the argument byte for byte, and `.` when none was given. `<root>` is the repository's physical root path. `<table path>` is `<home>/projects/<p>/retro.tsv`, with `<home>` as `FELIX_HOME` gives it.

### C3. The main ref, the as-of time and the selection

- **Main ref.** The target of `refs/remotes/origin/HEAD` when it is a symbolic ref to a `refs/remotes/origin/<x>` that names a commit. Otherwise `refs/remotes/origin/main` when it names a commit. Otherwise exit 1 (C2).
- **As-of time.** The time of the newest reflog entry of the main ref. The newest entry is the last one written, `<ref>@{0}`, whatever its time. When the main ref has no reflog entry, the newest reflog entry of `refs/remotes/origin/HEAD`. A fresh `git clone` (git 2.56, measured 10-29) writes a reflog entry for `origin/HEAD` and none for `origin/main`. When neither has one, exit 1 (C2). The as-of time is never the wall clock and never `FETCH_HEAD`'s mtime. The entry may be a fetch or a push (Veldra's newest is a push): either way it is when the ref last moved, which is what the engine can read. Decided in the plan.
- **The clock.** `felix retro` reads no wall clock. A suite pins time only through commit dates (`GIT_AUTHOR_DATE`, `GIT_COMMITTER_DATE` as `@<epoch> +0000`) and through reflog entries, which git dates by `GIT_COMMITTER_DATE` when a ref is written. In a non-bare repository git writes a reflog entry for every `refs/remotes/*` update, `git symbolic-ref` included, with or without `--create-reflog` (git 2.56, measured 10-29). So `_fx_git <repo> update-ref -m <msg> refs/remotes/origin/main <sha>`, or a `git fetch` from a second local repository, gives the main ref an entry at that time. `git clone` dates origin/HEAD's entry the same way, which is how R1 pins the clone's time. A fixture that needs a ref with no reflog writes it with `_fx_git <repo> -c core.logAllRefUpdates=false update-ref <ref> <sha>` (the same `-c` for `symbolic-ref`), and checks that `git reflog exists <ref>` fails before it asserts.
- **The chain.** First-parent commits of the main ref, newest first. A change's time `ct` is its committer time. A commit with no parent is not a change: the walk stops there, the commit is not listed, and the stop row names it (stop `root`). A commit whose first parent is not in the repository is not a change either: the walk stops there, it is not listed, and the stop row names it (stop `shallow`). So a history of k commits ending at the root offers at most k-1 changes.
- **Closed and open.** A change C is closed when `ct(C) + D·86400 ≤ as-of`, and open otherwise. Exactly `D·86400` before the as-of time is closed; one second later is open.
- **`--last N`.** Walk the chain newest first. Each open change met is listed with status `open`. Each closed change is taken. Stop after the Nth closed change (stop `last`). The rule is sealed (§11 item 14).
- **`--since`.** Walk the chain newest first and stop at the first change whose `ct` is before the date (stop `since`; that change is not listed). Every closed change met is taken, and every open one listed. When the walk reaches the root or a shallow boundary before any change dated before the date, the stop is `root` or `shallow`, whatever the boundary commit's time.
- **The window of a closed change C.** Walk the chain from the commit after C toward the tip and stop at the first commit whose `ct` is over `ct(C) + D·86400`. T is the last commit walked before it. The window is every chain commit after C up to and including T, so its end is inclusive. A later commit back under the limit is outside the window, as `--since` stops at the first change past its date.
- **An empty window.** When no chain commit follows C within the limit, the window is empty: no blame runs (git refuses a blame of `C..C`), and no commit reverted, fixed or edited C (§8.3, §11 item 35). With `--issues`, a reopened issue (C8) can still make C come back.
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
- It is first checked with `lib/table.sh`'s `felix_table_check` against `<harness>/templates/schemas.tsv`, the schema table beside the `felix` that runs (C7's `<harness>`), never a copy in the home. So a fixture home needs no `schemas.tsv`. Any refusal stops the run (C2), naming the first refusal's line.
- `kind` is `exclude` (an ERE over a path as git names it, relative to the repository root, case-sensitive) or `fix` (an ERE over a subject). Any other kind, or a pattern grep -E cannot compile, stops the run.
- A line starting `#` and an empty line are skipped, as `felix_table_check` skips them, and they count in the physical line numbers.
- Every subject is lowercased (A-Z to a-z, `LC_ALL=C`) before the fix EREs and the `revert` prefix test. C8's naming by subject is not lowercased.
- When the table holds at least one `fix` row, those rows replace the default. Otherwise the default fix ERE is §8.3's, `^(fix|hotfix|revert)`, matched on the lowercased subject. It is a bare prefix, which admits an optional scope (`fix(parser): ...`) and also `fixtures: ...`, `fixed ...`, `fixes ...` and `revertible ...`. A project whose subjects start so without being fixes narrows it with its own `fix` rows. It is sealed with the rest (C7).
- The project rows this PR adds (sealed with it), as each file's exact bytes, one tab between cells and a newline after every line.

`projects/felix/retro.tsv`:

```
exclude	^engine/\.claude-plugin/plugin\.json$	the version file
exclude	^engine/harness/tests/(assertions|red)\.tsv$	generated record tables
exclude	^(HANDOFF\.md|docs/handoff/)	handoff notes and their rotation
```

`projects/veldra/retro.tsv`:

```
exclude	^VERSION$	the version file
exclude	^CHANGELOG\.md$	release notes
exclude	(^|/)Cargo\.lock$	generated lock file
exclude	(^|/)package-lock\.json$	generated lock file
```

Elenchus gets no table: its tree holds no version file, changelog, lock file or handoff notes.

### C5. The record and `--tsv`

`--tsv` prints the record's bytes, and the record file holds exactly what `--tsv` would print for the same arguments. Cells are tab-separated, every line ends in a newline, and lines come in this order. In every row the kind is cell 1, as in the change row. So `counts` cells 2 to 6 are taken, came back, open, edited and unread; `kinds` cells 2 to 5 are revert, strong, reopened and could not look; the `sealed` row's cell 2 is the seal and cells 3 to 7 are its five inputs.

Header, eight rows:

| Row | Cells after the kind |
|---|---|
| `retro` | project name; repository root, physical path |
| `main` | the main ref, in full (`refs/remotes/origin/main`); its sha, 40 hex |
| `as_of` | `YYYY-MM-DDTHH:MM:SSZ`; the ref whose reflog gave it, in full |
| `sealed` | the seal, 40 hex (C7); then C7's five inputs in its order (rules, lines, table, seed, probes), each 40 hex or `-` |
| `select` | `last` and N, or `since` and the date as given |
| `window` | D; `sealed` when D is 30, else `unsealed` (§11 item 38) |
| `issues` | `on` or `off` |
| `replay` | `on` or `off` |

Then four summary rows:

| Row | Cells after the kind |
|---|---|
| `counts` | closed changes taken; came back (status `came-back`); open; edited again (status `edited`: weak edits and no come-back, so a came-back change that also has weak edits counts only as came back); changes with unread lines (cell 9 above 0) |
| `kinds` | changes with a revert; changes with a strong fix; changes with a reopened issue; changes whose issue kind could not look. Each counts the closed changes whose cell 5, 6 or 10 holds that kind, so one change can count in several. The last two are `-` when issues are off |
| `split` | over came-back changes only: owed; no row; could not look; unread. All four `-` when replay is off |
| `stop` | `last`, `since`, `root` or `shallow`; the sha (40 hex) of the commit the walk stopped at |

Then one `change` row per listed change, in chain order, newest first, 13 cells:

| # | Cell | Values |
|---|---|---|
| 1 | `change` | |
| 2 | sha | 40 hex |
| 3 | time | committer time, `YYYY-MM-DDTHH:MM:SSZ` |
| 4 | status | `came-back` (a revert, a strong fix or a reopened issue); `edited` (weak edits only); `quiet`; `open` |
| 5 | revert | revert commits, 12-hex shas, comma-joined, in chain order, nearest C first; `-` |
| 6 | strong | strong-fix commits, same form; `-` |
| 7 | weak | weak-edit commits, same form; `-` |
| 8 | excluded | how many of C's added lines are excluded |
| 9 | unread | how many of C's added lines the blame could not read |
| 10 | issue | `-` (off); `reopened #<i>[,#<j>]` (ascending); `not reopened`; `none closed`; `could not look` |
| 11 | replay | `-` (off); `owed`; `no row`; `could not look`; `unread` |
| 12 | owed ids | slice 1's ids, `owed:<12 hex>`, `LC_ALL=C` sorted, unique, comma-joined; `-` |
| 13 | subject | the subject (C8), each tab and each CR replaced by one space |

An open change's cells 5 to 12 are `-`. A commit appears in at most one of cells 5, 6 and 7 for one change.

Then the sample rows (C9): `sample`, then `strong` or `weak`, then C's sha and X's sha, both 40 hex. Strong rows first.

- **Path.** `<memory root>/<p>/retro/<as-of as YYYYMMDDTHHMMSSZ>-<key>.tsv`. `<memory root>/<p>` is `felix_mem_dir` of the project directory. `<key>` is the first 12 hex of `git hash-object --no-filters --stdin` over the eight header rows, each with its newline.
- Two runs with the same arguments write the same path. The write goes to a temporary file in the same directory, then `mv -f`.
- Nothing else is written in the home, the memory root or the repository. Scratch files go under TMPDIR, each made by `mktemp` with a template under `${TMPDIR:-/tmp}` (part 1000), and TMPDIR holds afterwards exactly what it held before, on every exit status, slice 1's scratch clones included.

### C6. The human report

Pinned lines, in this order, one per item. Only the per-change detail lines are the builder's layout.

1. `felix retro: <project>, <repository root>`
2. `main: <ref without refs/remotes/> at <sha12>, as of <YYYY-MM-DD HH:MM:SS> UTC, from the reflog of <reflog ref without refs/remotes/>`
3. `sealed <seal12>; window <D> days[, unsealed: the sealed window is 30]; <the newest N closed changes | closed changes since YYYY-MM-DD>; issues <asked | not asked>; replay <on | off>`
4. an empty line
5. `came back: <K> of <N> closed changes (<O> open, not counted); precision: unmeasured here, a headline needs 0.7 on the blind sample`
6. `by kind: revert <a>, strong fix <b>, reopened issue <c | not asked>[, issue could not look <d>]`
7. `edited again, not counted: <E>; changes the blame could not read whole: <U>`
8. `<replay of the K: owed <x>, no row <y>, could not look <z>, unread <u> | replay: not run>`
9. `stopped: <took the newest N closed changes | reached a change before YYYY-MM-DD | reached the first commit | reached a shallow boundary at <sha12>>`

- The `came back:` line is how §8.6 and §11 item 40 print the rate: with its denominator, its open count and `precision: unmeasured`. The 0.7 is the sealed bound (C7).
- `, issue could not look <d>` appears only when issues are asked.
- Then four sections, in this order, each after one empty line: `came back (<K>)`, `edited again (<E>)`, `open, not counted (<O>)` and `sample for blind labels: <s> strong, <w> weak`. A section is its header, then its change or sample lines. A header is printed even with a count of 0. A section ends at the next empty line.
- Each change under a header is one line `  <sha12> <YYYY-MM-DD> <subject>`. The date is cell 3's date, the committer date in UTC, and the subject is cell 13's text. Its detail lines follow, each starting with four spaces. No detail line is empty.
- `edited again (<E>)` lists exactly the changes whose status is `edited`.
- Each sample row prints as `  strong <C sha12> <X sha12>` or `  weak <C sha12> <X sha12>`.
- After the last section come one empty line and `record: <record path>`, the last line. Nothing else is printed: `felix retro` prints none of C12's limits.
- No line holds a `%` outside a commit subject it quotes. The rate is only ever printed as "K of N".

### C7. The seal

The seal covers the code of `lib/retro-rules.sh` and `lib/retro-lines.sh`, the project's `retro.tsv`, and by hash the slice-1 seed and the project's `probes.tsv` that the replay reads (§8.5, §11 item 39).

- Every rule of §8.2, §8.3, §8.4's filing and §8.6 lives in the two libraries: the defaults (window 30, last 50, sample sizes 20 and 10, the 0.7 bound), the main-ref and as-of rule, the selection walk, the window, exclusion, revert, strong and weak, which commits fill a change's revert, strong and weak cells, the status (`came-back`, `edited`, `quiet`), the issue rule, the filing rule and the sampling rule.
- `lib/retro.sh` and `lib/retro-replay.sh` decide no cell: they call these functions and print what they print. Output, records and running slice 1 live outside the seal, so a change there leaves it alone. Decided in the plan.

```
printf 'rules\t%s\nlines\t%s\ntable\t%s\nseed\t%s\nprobes\t%s\n' \
  "<hash of <harness>/lib/retro-rules.sh>" \
  "<hash of <harness>/lib/retro-lines.sh>" \
  "<hash of <home>/projects/<p>/retro.tsv>" \
  "<hash of <harness>/templates/situations.tsv>" \
  "<hash of <home>/projects/<p>/probes.tsv>" \
  | git hash-object --no-filters --stdin
```

- `<harness>` is the directory holding the `felix` that runs. Each `<hash of F>` is `git hash-object --no-filters F`, or `-` when F is absent.
- The seed and probes lines are hashed whether or not replay runs, so `--no-replay` and a replayed run over the same files share one seal and one sample. Decided in the plan.
- Changing any of the five inputs changes the seal.
- The replay column uses only a seed sealed before the come-backs were first counted (§8.5). The engine cannot tell when that was, so Task 12 keeps the rule from its records' `sealed` rows.

### C8. The come-back rules (§8.3)

The rules read subjects, and for issues closing keywords, through sealed patterns with no model (§11 item 36).

- **C's added lines.** From `git -c core.quotePath=false diff --no-ext-diff --no-textconv --no-color --src-prefix=a/ --dst-prefix=b/ --ignore-submodules=none --diff-algorithm=myers --indent-heuristic -U0 -M <C^1> <C> --`. Renames are detected, so a file C only moved adds no lines (§8.2, §11 item 33). Each `+c,d` hunk gives lines c to c+d-1 of C's file (`+c` alone is one line; d = 0 is none).
    - A path git prints as binary is read again with `--text` when each side present is text by git's content rule (at most 512 MiB, no NUL in the first 8000 bytes), as `_felix_git_patch` does (`lib/resolve.sh:1095`). An absent side (a file C adds, or one it deletes) counts as text, so a new file marked `-diff` is read with `--text`. A path that is binary by content gives no lines.
    - A path whose mode at C is 160000 (a submodule pointer) or 120000 (a symlink) gives no lines. The symlink is decided in the plan.
    - A path git still quotes, such as one holding a double quote, is read as unread.

- **Outcome of each line.** A path matching an `exclude` row: every line excluded, nothing blamed. When C's window is empty (C3), no blame runs and every other line survived. Otherwise one `git -c core.quotePath=false blame --no-textconv --ignore-revs-file '' --diff-algorithm=myers --indent-heuristic --reverse <C>..<T> --first-parent --porcelain -L <a,b> [-L ...] -- <path>` per file, with all its ranges together. The line's outcome:
    - blamed to T, and T's tree holds the path: survived;
    - blamed to T, and T's tree lacks the path (renamed or deleted whole): excluded;
    - blamed to X, which is C or a window commit other than T: Y is the chain commit after X. If Y's tree holds the path, Y changed the line. If not, the line is excluded;
    - blamed to anything else, or the blame failed: unread.

- git blame follows a whole-file rename, so a renamed file's lines read survived at its new path. The tree tests above are what make "renamed whole" excluded, which §8.3 states as this design's choice and §8.8 as a limit.
- **A commit's subjects.** A commit's subject is what `git log -1 --format=%s <sha>` prints: the message's first paragraph, its lines joined by one space. A window commit with one parent has one subject. A merge (two or more parents) also has the subjects of the commits it merged: every commit of `git rev-list <X>^1..<X>` other than X (§8.3, §11 item 34).
- **Revert of C.** A window commit X one of whose lowercased subjects starts `revert`, and that either names C or changed one of C's lines. X names C when either holds, for X's own message or, for a merge, any merged commit's:
    - the full message holds a run of 7 to 40 lowercase hex digits, with no hex digit of either case on either side, that is a prefix of C's sha or of a commit in `git rev-list C^1..C`;
    - the subject, as git prints it and not lowercased, is exactly `Revert "<C's subject>"`, optionally followed by ` (#<digits>)`.

- Body lines never make a revert: the subject test is on subjects alone.
- **Strong.** A window commit that changed one of C's lines, is not a revert of C, and one of whose lowercased subjects matches a fix ERE (C4). So a merge is strong when a commit it merged has a fix subject, even one that did not touch the line (C12).
- **Weak.** Any other window commit that changed one of C's lines. Reported as edited again. Never a come-back.
- Excluded lines count for no rule.
- **Reopened issue** (`--issues` only, closed changes only):
    - C's PR number is `n` from a subject ending `(#n)`, or a subject starting `Merge pull request #n `. A change with neither has no PR number. The issues that closing keywords in its message name (below) are still looked up through gh, and each reads reopened or not as for any other change (§8.3, §8.8, §11 item 43). A change with no PR number and no such keyword reads `could not look`, and gh is not called for it.
    - The repository's slug comes from the origin URL: `https://github.com/<o>/<r>[.git]`, `git@github.com:<o>/<r>[.git]` or `ssh://git@github.com/<o>/<r>[.git]`. Any other URL reads `could not look` for every change, and gh is never called.
    - gh's calls, in this order, with `GH_PROMPT_DISABLED=1` and `GH_NO_UPDATE_NOTIFIER=1`: when C has a PR number, `gh pr view <n> --repo <o>/<r> --json closingIssuesReferences --jq '.closingIssuesReferences[].number'`, which prints one issue number a line; then for each issue i that C closed, ascending, `gh api repos/<o>/<r>/issues/<i>/events --paginate --jq '.[] | select(.event == "reopened") | .created_at'`, which prints one `YYYY-MM-DDTHH:MM:SSZ` a line. A change with no PR number gets no `pr view` call.
    - The issues C closed are the PR's list together with every `#i` that a closing keyword names in C's lowercased message. For a change with no PR number, they are only the issues its keywords name. The keywords are close, closes, closed, fix, fixes, fixed, resolve, resolves and resolved, each followed by an optional `:`, then blanks, then `#<digits>`, with no letter just before the keyword.
    - An issue reopened at t with `ct(C) < t ≤ ct(C) + D·86400` makes the cell `reopened #i` and C a came-back change. No such event: `not reopened`. No issue: `none closed`, which only a change with a PR number can read.
    - gh missing from PATH, any gh exit other than 0, or a line of gh's output not of the shape above: `could not look`, never `not reopened`.

- **Came back** means a revert, a strong fix or a reopened issue. Weak edits alone never are (§11 item 13).

### C9. The sample (§8.6)

- **Candidates.** Each pair (C, X) of a taken closed change and one commit in its revert or strong cell is a strong candidate. Each pair of C and one commit in its weak cell is a weak candidate.
- **Key.** `git hash-object --no-filters --stdin` over `<seal40>\t<C40>\t<X40>\n`.
- **Draw.** The first 20 strong candidates and the first 10 weak candidates, by key ascending (`LC_ALL=C`). Strong rows are printed first, then weak, each in key order.
- **Labels** are made outside the engine (Task 12). The engine never reads them.

### C10. The replay join (§8.4)

- For each taken closed change, with replay on, run `( cd <root> && <harness>/felix situations --change <C^1 sha>..<C sha> --tsv )` with the same environment.
- A class line is a line whose first cell is `owed:` and 12 hex. Its verdict is cell 3. A `residual` line is never a class line.
- The verdict tokens are the set slice 1's plan pins (`docs/2026-10-29-lane-slice-1-plan.md`, its C5 and C8): `owed` (which also carries §7.5's "owed (base could not look)"), `standing`, `blinded`, `could-not-look`, `retired`, `none`. The join reads the set, not the order lines come in.
- Filing, by the sealed rule (§8.5, C7), per change and not per surface (§11 item 15):
    - `owed`: at least one class line whose verdict is `owed` or `blinded`;
    - else `could not look`: at least one class line whose verdict is `could-not-look`;
    - else `no row`;
    - `unread`: situations exited other than 0, or printed no class line.

- Only class verdicts file, as §8.4 reads them. A class whose verdict is `none`, even one whose base was UNKNOWN, adds nothing toward `could not look`, and a `residual` line never files.
- The owed ids cell holds the ids of the lines that filed `owed`.
- When slice 1 lands with other tokens than its plan's, the join and part 2350 follow slice 1's landed `--tsv`, and the blind author is told before writing part 2350.
- `felix retro` never writes `facts.log`. Slice 1's `--change` never does.

### C11. How a fixture points the engine at a repository

- `FELIX_HOME=<home>` with `<home>/projects/<p>/project.json` and `CLAUDE.md`. The home needs no `schemas.tsv` (C4). `project.json` is `{"name":"<p>","remote_match":"example.invalid/<p>","gate":"true"}` and `CLAUDE.md` is `# <p>`. The project's name, in the `retro` row and in C6, is its directory name under `projects/`.
- `FELIX_MEMORY=<memory root>`.
- The repository's root holds an untracked `.felix` file naming `<p>`.
- Run `"$FELIX" retro <repo> ...`, or `( cd <repo> && "$FELIX" retro ... )`. `$FELIX` is the suite's copy. Part 2350 runs its own copy (C13).
- `_fx_cd` runs only inside `( ... )`. `_fx_git <dir> ...` accepts `-c k=v` before the subcommand and refuses `-C`, `--git-dir` and `--work-tree`.
- The main ref is written inside a part with `_fx_git`. The project's deny row refuses `update-ref` on a remote-tracking ref when a session types it, so never try a fixture command by hand in a session.

### C12. Stated limits (the sealed report repeats them; `felix retro` prints none of them)

- A real merge reads strong when any commit it merged has a fix subject, even one that did not touch the edited line (§8.8).
- A revert-subject commit that deletes a file C created, and names nothing, is not seen: those lines are excluded.
- Lines whose file is later renamed or deleted whole are excluded, so edits to them are not counted, and a renamed file counts as excluded churn (§8.3's choice).
- Every subject that starts with fix, hotfix or revert is strong under the default fix ERE, `fixtures: ...` and `fixed ...` included. A project's `fix` rows can narrow it.
- The as-of time is when the main ref last moved, by a fetch or a push.
- Only the `origin` remote is read.
- Where committer times on the chain go backwards, the window and `--since` follow chain order as C3 says.
- Veldra's changes, and 38 of Elenchus's newest 50 closed ones, carry no PR number: they are direct commits or plain merges. For each of them, the issue lookup reads only the issues a closing keyword in its message names (C8), and a change whose message names none reads `could not look`.
- For a plain merge, the issue lookup reads the merge commit's own message, not the messages of the commits it merged (design §8.8). On 10-29, no commit under Veldra's 16 or Elenchus's one such merge named an issue that way.

### C13. The blind parts

The blind authors write these files. For conventions, an author also reads the driver `engine/harness/tests/run`, `tests/lib/*.sh` and existing parts. An author never reads `lib/retro*.sh` or `cmd_retro`. Felix runs as a black box. The suite gives `ok NAME`, `bad NAME [WHY]`, `is NAME GOT WANT`, `has NAME TEXT PART` and `skip NAME WHY`; `_fx_cd` and `_fx_git` (part 0002); `_copy_content` (part 0004); `$FELIX`, `$TMP` and `$REAL_HARNESS`. Assertion names are prefixed `retro:`, and the Review Focus names R1 to R5 are the ones given below.

**`engine/harness/tests/lib/retro.sh`, the builders.** Functions only, all named `_retro_*`. They are free of clashes with `_rt_*`, which parts 1010, 1220, 1230 and 1240 define, and with `_rcp_*` and `_sr_*`, which `tests/receipt.sh` defines; the driver's `_lib_clashes` check refuses any name defined before `tests/lib` loads. The file sets no variable when it loads. If it needs one, it defines `_retro_vars`, and each part that needs it calls it first, as part 0998 calls `_locale_bytes_vars`. It needs builders for:

- a home with one project and a memory root (C11);
- a repository whose commits carry pinned author and committer dates, written through `_fx_git`;
- setting `refs/remotes/origin/main` (and optionally `origin/HEAD`) with a reflog entry at a pinned time (C3, the clock);
- running `felix retro` with the fixture's environment, keeping stdout, stderr and status apart;
- a stub directory first on PATH for `gh`, `curl`, `wget` and `date`, each logging its argv, one call a line. The `gh` stub also logs the values of `GH_PROMPT_DISABLED` and `GH_NO_UPDATE_NOTIFIER` on the same line.

Manners, for every part:

- The author of a part adds its driver line, `. "$HERE/parts/<name>"`, in name order. Task 1's author also adds `. "$HERE/lib/retro.sh"` among the lib lines, in name order.
- Part NNNN's fixtures live under `$TMP/r<NNNN>`, whose physical path the part takes once at its start, in a subshell (`cd -P`). A part does not depend on another part.
- Every assertion that would pass against an engine with no `retro` command (a usage status, no record, nothing changed, TMPDIR empty, an empty stub log) also compares a value only `felix retro` gives. That is the exit status together with stderr's line as C2 gives it (starting `felix: retro: `, or need_value's own line), or exit 0 together with stdout's first line starting `felix retro: ` (or `retro` and a tab under `--tsv`). The one exception is `felix retro --help`, which main's dispatcher already answers: that assertion is a control.
- An assertion that pins a Review Focus item has a name starting `retro: R<n> `, for example `retro: R1b no reflog exits 1`. No other assertion name holds `R<n> `. Part 2350's names start `retro: replay`, and part 2360's `retro: review`.

**Part 2310, `engine/harness/tests/parts/2310-retro-selection-and-as-of-blind.sh`** (selection, as-of, output, record, CLI). Every run passes `--no-replay`. Status is asserted only as `open` or not `open`. Assertions:

- §8.7: "A change whose window runs past the as-of time is open, and left out of the rate". Check the C3 edges: exactly `D·86400` before the as-of time is taken, one second later is listed `open`, and `counts` excludes it.
- §8.7: "`--last 3` on a history whose two newest changes are open selects the three newest closed changes, and lists the two open ones apart". Check the `change` row order, `select last 3`, `counts` N=3 O=2, and `stop last <sha of the third>`.
- `--since`: takes the closed changes on or after the date, with `stop since <sha>` naming the first change before it. `select since <date>`.
- A history of k commits that reaches its root before N closed changes: the root commit is not listed, the stop row is `stop root <root sha>`, and `counts` takes at most k-1.
- `--window 14`: a change 14·86400 s before the as-of time is closed and one a second later is open, and the header reads `window 14 unsealed`. With `--window 30` it reads `window 30 sealed`. The human report's third line holds `, unsealed: the sealed window is 30` under `--window 14` and `--window 45`, and not under `--window 30` or with no `--window`. On a separate change E at least 30·86400 s before the as-of time, a `fix:` commit at `ct(E)+14·86400+1` that edits one of E's added lines leaves E's cell 6 `-` under `--window 14`, and puts the fix's sha12 in cell 6 under `--window 30` (the control, on the same repository). This is the one 2310 assertion that reads a come-back cell.
- The as-of row: the newest reflog time of `origin/main`, its ref in cell 3. A newer `FETCH_HEAD` does not move it.
- **R1:** a clone made with `git clone` and never fetched since reads `as_of` at the clone's time, with `refs/remotes/origin/HEAD` in cell 3.
- **R1b:** a repository where neither `origin/main` nor `origin/HEAD` has a reflog entry exits 1 with C2's sentence, prints nothing, and writes no record.
- **R5:** `origin/HEAD` names `origin/master` and there is no `origin/main`. The `main` row names `refs/remotes/origin/master`.
- No main ref: exit 1 with C2's sentence.
- Not bound: exit 1, `felix: retro: no project governs <root>`.
- Each row of C2 gives its status, stdout and stderr, and C1's argument rules hold (help anywhere, a value that starts with `-`, a flag given twice). That includes `<repo>` in no git work tree (a directory under the part's fixture dir with no `.git`), and a record that cannot be written: `<memory root>/<p>/retro` made at mode 555, skipped by name when `_unwritable_probe` (`tests/lib/unwritable.sh`) finds this user writes through a mode. That run exits 1, prints the report on stdout and C2's line on stderr, and leaves no file under `<memory root>/<p>/retro`. Neither a usage error nor a missing value writes a record.
- `retro.tsv` refusals: a row whose kind is `include`, a row whose pattern is `(`, and a row with two cells each exit 1 with stderr starting `felix: retro: <table path>:<line>: `, print nothing on stdout, and write no record.
- `felix help` holds C1's usage line, and `felix retro --help` and `felix retro --tsv --help` both exit 0 with `felix help`'s text.
- The record: its path follows C5, its bytes equal `--tsv` stdout, and a human run with the same arguments writes the same file.
- §8.7: "The rate prints with its denominator, its open count and `precision: unmeasured`, never alone." The `came back:` line is C6's, with K, N and O from `counts`. The other pinned lines (C6) hold the counts from `--tsv`, `edited again (<E>)` lists exactly the `edited` changes, the last line is `record: <path>`, and no line holds a `%` outside a quoted subject.
- Read-only: every file under the repository's work tree and `.git` keeps its bytes and mtime, and so do the outputs of `git for-each-ref`, `git worktree list --porcelain`, the config file and the index. Nothing under the home or the memory root changes except the one record file and the directories `<memory root>/<p>` and `<memory root>/<p>/retro` that hold it, which the run may create. The part compares `find <root> -type f` listings and each file's bytes. TMPDIR, pointed at an empty fixture directory, is empty again after every run.
- §8.7: "Two runs with the network off, and without `--issues`, give identical bytes." A run with a `date` stub that prints `2099-01-01` gives the same bytes. The bytes compared are the `--tsv` stdout and the human stdout, each run twice. The `date` stub's log stays empty: no process `felix retro` starts runs `date`. Without `--issues`, the `gh`, `curl` and `wget` stub logs stay empty.

**Part 2320, `engine/harness/tests/parts/2320-retro-come-back-rules-blind.sh`** (rules 1 and 2, exclusions, merges). Every run passes `--no-replay`. One scripted history, all windows closed, unless a bullet builds its own. Assertions on the `change` rows' cells 4 to 9:

- §8.7: "A squash merge reverted by a commit whose subject starts "Revert" and names it is a revert come-back". Check both naming forms of C8: `This reverts commit <sha>.` and `Revert "<subject>" (#n)`.
- §8.7: "A lowercase `revert(x):` subject that names nothing, but edits the change's lines, is a revert".
- §8.7: "A commit with an ordinary subject and a body line starting "Reverting" is not a revert". It reads weak if it edits a line, and the change is not `came-back`.
- §8.7: "A later `fix:` commit editing an added line is strong. A `docs:` commit editing one is weak, and not a come-back."
- §8.7: "A real merge whose merged commits include a `fix:` commit that edits an added line makes that edit strong." The merge's own subject is `Merge branch ...`.
- §8.7: "A change with no first-parent commit after it inside its window runs no blame and has no edits." Its status is `quiet`, cells 5 to 7 are `-`, and cell 9 is 0 (a blame of `C..C` fails, which would read its lines unread).
- §8.7: "A change that only moves a file adds no lines for that file." Its cells 8 and 9 are 0, and a later `fix:` of a line in the moved file does not make it `came-back`.
- §8.7: "An added file renamed whole is excluded. So is a version file bumped, through `retro.tsv`". Control: the same bump without the row reads strong. A file deleted whole is excluded too.
- C4's `fix` rows: with a `retro.tsv` holding `fix<TAB>^chore\(repair\):<TAB>repairs`, a later `chore(repair):` commit editing an added line is strong, and a later `fix:` commit editing one is weak. The table's fix rows replace the default.
- The window's end is inclusive: a `fix:` at exactly `ct(C) + D·86400` is strong; one at one second more is not counted.
- A later commit that edits only lines C did not add is not counted.
- §8.7: "A history of real merge commits with no PR numbers is read through `C^1`". Use `git merge --no-ff`. The merge is one change row and its merged commits are none. A later direct `fix:` on a line the merge added is strong, and a revert naming one of the merged commits' shas is a revert of the merge.
- An added file whose path holds a double quote (`a"b.txt`), which git quotes even with `core.quotePath=false`: its lines are counted in cell 9, `counts` cell 6 counts the change, and the human line reads `changes the blame could not read whole: 1`.
- **R2:** a change adds lines to `dir one/é b.txt` and its subject holds a tab. A later `fix:` of one line is strong, every `change` row has 13 cells, and the subject prints with a space where the tab was.
- **R3:** with `diff.external`, a `.gitattributes` textconv driver on `*.txt` (the driver configured), `blame.ignoreRevsFile` naming the fix commit, `log.showSignature=true`, `diff.noprefix=true`, `core.quotePath=true`, `diff.algorithm=patience`, `diff.indentHeuristic=false`, and `*.md -diff` in `.git/info/attributes` over a change that adds a new `.md` file and appends lines to an existing one, all set in the fixture repository, `--tsv` is byte-identical to the run without them. The part first checks that `git -c diff.algorithm=myers diff -U0` and `git -c diff.algorithm=patience diff -U0` differ for the change, and that `-c diff.indentHeuristic=true` and `-c diff.indentHeuristic=false` differ, each with `--no-ext-diff --no-textconv`, so neither setting is vacuous. The change also adds a line to a file with a non-ASCII name, so `core.quotePath=true` is not vacuous. `log.showSignature` is accepted as vacuous, since fixture commits are unsigned.
- **R4:** a change adds a binary file, bumps a submodule pointer, adds a symlink and appends a line to a file with no final newline. Inside the window, three later `fix:` commits rewrite the binary file, bump the submodule pointer again and retarget the symlink, one each, and one more `fix:` edits the appended line. The run exits 0, the change's cells 8 and 9 are 0, and its cell 6 holds exactly the appended line's fix.

**Part 2330, `engine/harness/tests/parts/2330-retro-reopened-issues-blind.sh`** (rule 3). origin's URL is `https://github.com/example/widget.git`, set as config only. Every run passes `--no-replay`: only part 2350 runs the replay. Assertions:

- §8.7: "`--issues` with `gh` stubbed as unreachable reads "could not look" for that kind, never "not reopened"". The stub exits 1 and logs. The cell reads `could not look`, the stub log shows `pr view <n>`, and `kinds` counts it in cell 5. A direct commit with no PR number whose message says `fixes #8` reads `could not look` under that stub too, and the log shows `api repos/example/widget/issues/8/events` for it.
- gh missing from PATH: `could not look`. The part builds that PATH as one directory of symlinks to every executable on the suite's PATH except `gh`, because gh and git share a directory (`/opt/homebrew/bin` here). It checks that `command -v gh` fails under that PATH before asserting.
- A reachable stub, matched on argv as C8 pins it:
    - PR 12 closes issue 7, reopened 5 days after C: `reopened #7`, status `came-back`;
    - PR 13 closes none, message `fixes #9`, no reopen event: `not reopened`;
    - PR 14 closes none, no keyword: `none closed`;
    - a reopen at `ct(C) + D·86400 + 1`: `not reopened`;
    - a direct commit with no PR number, message `fixes #8`, issue 8 reopened 5 days after C: `reopened #8`, status `came-back`;
    - a direct commit with no PR number, message `closes #10`, no reopen event: `not reopened`.

- A change with no PR number and no closing keyword reads `could not look`, and the stub log has no call for it. The two direct commits that name issues 8 and 10 are looked up with no `pr view` call: the log holds `api repos/example/widget/issues/8/events` and `api repos/example/widget/issues/10/events`, and every `pr view` call in it names a PR number that a fixture subject carries.
- Each logged gh call carries `GH_PROMPT_DISABLED` and `GH_NO_UPDATE_NOTIFIER` as 1, and the calls for one change come in C8's order: `pr view <n>` first when C has a PR number, then `api repos/<o>/<r>/issues/<i>/events` with i ascending.
- origin set to a non-GitHub URL: every closed change reads `could not look`, and the stub is never called.
- Without `--issues`: cell 10 is `-`, `kinds` cells 4 and 5 are `-`, and the stub log is empty.
- Open changes are never asked about.

**Part 2340, `engine/harness/tests/parts/2340-retro-seal-and-sample-blind.sh`** (seal and sample). Every run passes `--no-replay`: only part 2350 runs the replay. Assertions:

- The `sealed` row's cell 2 equals C7's formula, recomputed by the part over the harness that ran, the fixture's `retro.tsv` and `probes.tsv`, and that harness's `templates/situations.tsv`. Its cells 3 to 7 are those five hashes, `-` for each file absent.
- Adding one `exclude` row changes the seal, and removing it gives the old seal back. Writing a `probes.tsv` into the fixture project changes it, and so does writing a `templates/situations.tsv` into a harness copy (`_copy_content "$REAL_HARNESS" <dir>/harness`).
- One change adding 37 lines: 25 of them each changed by its own `fix:` commit, and the other 12 each changed by its own `docs:` commit, all inside the change's window. Exactly 20 strong and 10 weak `sample` rows. They are the first by C9's key, recomputed by the part with `git hash-object`, in key order, strong first. Every pair is in its change row's cells.
- Fewer candidates than the cap: every candidate appears.
- No pair from an open change appears.
- The human report shows `sample for blind labels: 20 strong, 10 weak`.

**Part 2350, `engine/harness/tests/parts/2350-retro-replay-blind.sh`** (the replay), written once slice 1 is on main. It makes its own harness copy with `_copy_content "$REAL_HARNESS" <dir>/harness`, replaces that copy's `templates/situations.tsv` with fixture classes that slice 1's table check accepts, and gives the fixture project a `probes.tsv`. Its assertion names are prefixed `retro: replay`. Assertions:

- §8.4: three came-back changes filed `owed`, `no row` and `could not look`. The filing order is owed, then could not look, then no row, so the `no row` change must sit where no class is undecided on either side. `split` counts each once.
- A change slice 1 blinded at head files `owed`.
- §8.4: "Every record carries the owed ids slice 1 printed". Cell 12 equals the ids of the lines that filed `owed` in the part's own run of `felix situations --change C^1..C --tsv`.
- Every closed change, came back or not, has a replay cell. Open changes have `-`.
- A fixture where situations cannot run: the harness copy's `templates/situations.tsv` holds no row, which slice 1 refuses with exit 3 (slice 1's plan, C2, `it holds no row`). Every closed change reads `unread`, and the run still exits 0. A malformed `probes.tsv` does not do this: `felix_probes_run` returns 0 whatever the table holds (`lib/probes.sh:367-383`).
- `--no-replay`: header `replay off`, cells 11 and 12 `-`, and `split - - - -`.
- With replay on, two runs give identical bytes (§8.7, §7.9 d).
- `facts.log` under the memory root is unchanged, and the repository is untouched, as in part 2310.

**Part 2360, `engine/harness/tests/parts/2360-retro-review-fixes-blind.sh`** (Task 10's findings). It is written after the adversarial review, by an author who is neither the reviewer nor the implementer. The author reads the design, C1 to C12, this section, and the finding Task 10 Step 2 hands over, restated as required behaviour with the fixture it needs. Its assertion names are prefixed `retro: review`. Every run passes `--no-replay` unless the finding concerns the replay. If Task 10 hands over no finding that needs an assertion, part 2360 is not written.

**The Review Focus items, with their pins.**

1. **A fresh clone never fetched since.** git writes no reflog for `origin/main` on clone, so the as-of time must come from `origin/HEAD`'s clone entry. This is the engineering manager's first run. Pinned: R1 and R1b in part 2310 (Task 1).
2. **Paths with spaces and non-ASCII bytes, and subjects holding a tab.** A real repository has them, and they break blame arguments and TSV cells. Pinned: R2 in part 2320.
3. **A repository whose git configuration changes git's output.** This covers a textconv driver in `.gitattributes`, `diff.external`, `blame.ignoreRevsFile`, `log.showSignature`, `diff.noprefix`, `core.quotePath`, `diff.algorithm`, `diff.indentHeuristic` and a `-diff` attribute. The record must not change. Pinned: R3 in part 2320.
4. **A change holding a binary file, a submodule pointer, a symlink and a file with no final newline.** The run must finish, count correctly and still find a later fix. Pinned: R4 in part 2320.
5. **A default branch not named main.** `origin/HEAD` names `origin/master` and there is no `origin/main`. Pinned: R5 in part 2310.

## Review Focus

The five items, and the assertions that pin each, are listed at the end of C13. The reviewer reads them there (Task 10 Step 1).

## Tasks

### Task 0: Preflight and the branch (Sonnet 5.5, high)

**Files:**

- Create: none yet. The branch carries copies of the design, this plan and slice 1's plan.

**Interfaces:**

- Consumes: nothing.
- Produces: a worktree on branch `claude/lane-retro`, cut from `origin/main`.

- [ ] **Step 1: Check the gates on starting.** Run `gh pr list --repo LeavesJ/felix-home --state open --limit 200 --json number,title,files` and count the PRs that touch `engine/`. Expected: 10 or fewer. If there are more, stop and wait.
- [ ] **Step 2: Check no live session holds this work.** Run `ListAgents`, and `git -C <home> for-each-ref refs/heads refs/remotes --format='%(refname)'`, looking for a retro branch. Expected: none.
- [ ] **Step 3: Check the lane pointer.** On `origin/main`, `projects/felix/lane-next.tsv`'s `capability` row names slice 2, which slice 1's PR sets, marked "pending the direction fold" (design §9, §11 item 22). Or slice 1 has not landed, and this branch builds the come-back half while it waits (design §9). If the direction fold has put another item ahead of slice 2 (design §12), stop: that item comes first.
- [ ] **Step 4: Check the part numbers are free.** For every ref, run `git ls-tree --name-only <ref> engine/harness/tests/parts/` and look for 2310 to 2360. Expected: none used. Slice 0's plan takes 2200 to 2250 and slice 1's takes 2400 to 2470. If any of 2310 to 2360 is used, take the next free block of ten, and rename the parts everywhere in this plan.
- [ ] **Step 5: Check the driver has room.** Part 1040 caps `engine/harness/tests/run` at 500 lines. Add three numbers: `git -C <home> show origin/main:engine/harness/tests/run | wc -l`; the net lines the open PRs add to that file, `gh pr list --repo LeavesJ/felix-home --state open --limit 200 --json files --jq '[.[].files[] | select(.path == "engine/harness/tests/run") | .additions - .deletions] | add'` (`null` is 0); and this slice's 7. Expected: 500 or fewer. If the total passes 500, stop before the blind stage (Task 1) and tell the queue owner: the driver needs room first.
- [ ] **Step 6: Make the worktree** from `origin/main` (`git worktree add -b claude/lane-retro <path> origin/main`). First check that the design and the slice plans are committed on `claude/lane-situations-owed` with no edit pending: `git -C <lane worktree> status --short -- docs/` lists none of them, and `git log -1 -- docs/2026-10-29-lane-slice-2-plan.md` prints a commit. If not, stop and ask the lane branch's owner to commit them. Then copy them (`git checkout <lane sha> -- docs/2026-10-29-capability-lane-first-slices-design.md docs/2026-10-29-lane-slice-1-plan.md docs/2026-10-29-lane-slice-2-plan.md`). Task 8 reads slice 1's plan. Commit, ending the message with `Felix-Lane: capability`, and push.

### Task 1: Blind parts for the come-back half (Opus 5.5, xhigh)

The blind author reads the design and this plan's Contracts, and nothing else of the plan, and writes each file to C13's list for it. For conventions, the author also reads the driver `engine/harness/tests/run`, `tests/lib/*.sh` and existing parts. The author never reads `lib/retro*.sh` or `cmd_retro`. Felix runs as a black box.

**Files:**

- Create: `engine/harness/tests/lib/retro.sh`, the builders. Functions only, all named `_retro_*`, free of clashes with the `_rt_*` functions of parts 1010, 1220, 1230 and 1240, and with `tests/receipt.sh`'s `_rcp_*` and `_sr_*` (C13).
- Create: `engine/harness/tests/parts/2310-retro-selection-and-as-of-blind.sh`
- Create: `engine/harness/tests/parts/2320-retro-come-back-rules-blind.sh`
- Create: `engine/harness/tests/parts/2330-retro-reopened-issues-blind.sh`
- Create: `engine/harness/tests/parts/2340-retro-seal-and-sample-blind.sh`
- Modify: `engine/harness/tests/run:156`, adding `. "$HERE/lib/retro.sh"` after `lib/recon.sh`.
- Modify: `engine/harness/tests/run`, adding the four part lines in name order, as part 1040 requires: after the last part line whose name sorts before `2310-` (`2250-lane-pulse-blind.sh` once slice 0 has landed, `2160-docs-are-not-a-frontend-blind.sh` before) and before the first that sorts after `2340-`.

**Interfaces:**

- Consumes: the suite helpers `ok NAME`, `bad NAME [WHY]`, `is NAME GOT WANT`, `has NAME TEXT PART` and `skip NAME WHY`; `_fx_cd` and `_fx_git` (part 0002); `_copy_content` (part 0004); `$FELIX`, `$TMP` and `$REAL_HARNESS`.
- Produces: assertion names prefixed `retro:`, and the Review Focus names R1 to R5 as C13 gives them.

- [ ] **Step 1: Write `tests/lib/retro.sh`** to C13's list for it.
- [ ] **Step 2: Write part 2310** to C13's list for it.
- [ ] **Step 3: Write part 2320** to C13's list for it.
- [ ] **Step 4: Write part 2330** to C13's list for it.
- [ ] **Step 5: Write part 2340** to C13's list for it.
- [ ] **Step 6: Commit and push.** Message `test(retro): blind parts for come-backs, written from the design and the contracts`, ending with `Felix-Lane: capability`.

### Task 2: Show the come-back parts red on main (Sonnet 5.5, high)

**Files:**

- Test: parts 2310 to 2340, against the engine as main holds it (the branch has no engine change yet).

**Interfaces:**

- Consumes: Task 1's parts.
- Produces: the red counts for the PR body and the handoff section.

- [ ] **Step 1: Run the four parts alone, from an empty directory.**

```
( cd "$(mktemp -d)" && bash <worktree>/engine/harness/tests/run --part \
    2310-retro-selection-and-as-of-blind.sh 2320-retro-come-back-rules-blind.sh \
    2330-retro-reopened-issues-blind.sh 2340-retro-seal-and-sample-blind.sh ) \
    > <scratch>/red-1.log 2>&1
command grep -c '^  FAIL' <scratch>/red-1.log
```

Expected: every assertion about retro's output fails, because main prints `felix: unknown command: retro. Try 'felix help'.` and exits 1. Fixture controls pass. Part mode exits 0 whatever fails, so read the counts from the log. `felix retro --help` exits 0 on main too, because the dispatcher answers a second-word `--help` for every subcommand (`felix:6590-6592`). That assertion is a control; `felix retro --tsv --help` is the one that fails on main.

- [ ] **Step 2: Sort the passes.** List every assertion that passed on main. Each must be a fixture control, or vacuous on main for a stated reason, as `docs/2026-10-24-audit-fixes/b09-*.md` §8 does. Any other pass goes back to the blind author.
- [ ] **Step 3: Commit the counts, so a workflow that dies keeps them:** `git commit --allow-empty -m "test(retro): red on main: <failed> failed, <passed> passed in 2310-2340" -m "Felix-Lane: capability"`, and push. Also write them into the handoff section file, `<scratch>/retro-handoff-section.md`, which Task 11 hands to `felix handoff --section`. Tasks 8 and 10 add to it and commit their red counts the same way.

### Task 3: The table (Sonnet 5.5, high)

**Files:**

- Create: `projects/felix/retro.tsv`, `projects/veldra/retro.tsv` (C4's rows).
- Modify: `engine/harness/templates/schemas.tsv:134`, inserting C4's comment and row after the `.snapshot-ack.tsv` row. Slices 0 and 1 insert rows above it, so place it by that neighbour, not by the number.

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
- Create: `engine/harness/lib/retro-lines.sh` (sealed), holding only its header comment, so C7's seal reads both files from this task's first commit. Task 5 fills it.
- Create: `engine/harness/lib/retro.sh` (unsealed): the run, both reports, the record.
- Modify: `engine/harness/felix:464`, adding C1's usage line after `felix qualify [check]` in `usage()` (`:404-496`).
- Modify: `engine/harness/felix:6578`, adding `cmd_retro` after `cmd_status` (`:6573-6578`).
- Modify: `engine/harness/felix:6615`, adding `  retro)     shift; cmd_retro "$@" ;;` (indented two spaces, as its neighbours are) after `qualify)` in the main dispatch block, so part 0480 checks the usage line.
- Test: part 2310.

Slices 0 and 1 edit `felix` first. Re-read the file and place the lines by their neighbours, not by these numbers.

**Interfaces:**

- Consumes: `need_value`, `die`, `FELIX_HOME_DIR`, `SCRIPT_DIR` (felix); `felix_resolve_project START HOME`, `felix_repo_root START` and `felix_mem_dir PROJDIR` (`lib/resolve.sh`); `felix_table_check SCHEMAS FILE` and `felix_table_rows FILE` (`lib/table.sh`).
- Produces, in `lib/retro-rules.sh`:
    - `FELIX_RETRO_WINDOW=30`, `FELIX_RETRO_LAST=50`, `FELIX_RETRO_SAMPLE_STRONG=20`, `FELIX_RETRO_SAMPLE_WEAK=10`, `FELIX_RETRO_BOUND=0.7`, `FELIX_RETRO_FIX='^(fix|hotfix|revert)'`, set when the file is sourced;
    - `felix_retro_main_ref ROOT` prints `REF<TAB>SHA40`, or returns 1;
    - `felix_retro_as_of ROOT REF` prints `EPOCH<TAB>LOGREF`, or returns 1;
    - `felix_retro_table TABLE SCHEMAS` prints `KIND<TAB>PATTERN` rows, or returns 1 with C2's line on stderr. SCHEMAS is `<harness>/templates/schemas.tsv`;
    - `felix_retro_select ROOT TIP ASOF WINDOW LAST SINCE` (LAST or SINCE `-`) prints `pick<TAB>SHA40<TAB>CT<TAB>closed|open<TAB>SUBJECT` rows, newest first, then one `stop<TAB>REASON<TAB>SHA40` line;
    - `felix_retro_window ROOT TIP C WINDOW` prints `SHA40<TAB>CT<TAB>SUBJECT` per window commit, oldest first, T last, and nothing for an empty window;
    - `felix_retro_seal HARNESS TABLE PROBES` prints the `sealed` row's cells (C5): the seal, then C7's five input hashes.

- Produces, in `lib/retro.sh`: `felix_retro ROOT PROJDIR LAST SINCE WINDOW ISSUES REPLAY TSV`. LAST, SINCE and WINDOW may be `-` (use the defaults); ISSUES, REPLAY and TSV are 0 or 1. It prints the report, writes the record and returns C2's status.
- Produces, in `felix`: `cmd_retro "$@"`. It parses C1 with `need_value`, exits 2 through `die "retro: <why>" 2`, exports `GIT_OPTIONAL_LOCKS=0`, sources `lib/table.sh`, `lib/retro-rules.sh`, `lib/retro-lines.sh` and `lib/retro.sh` with `|| exit 1` (lazily, as `cmd_inventory` does), resolves the project from `<repo>`, and calls `felix_retro`.

- [ ] **Step 1: See part 2310 red** with Task 2's command, naming the one part. Expected: the same failures as Task 2.
- [ ] **Step 2: Implement** the functions above, to C1 to C7. Every closed change reads `quiet` until Task 5. Replay reads `off` whatever the flag until Task 9. Every `git log` carries `--no-show-signature`. Times print as UTC, through `TZ=UTC0` with `--date=format-local:`, or by days-from-civil arithmetic as `lib/cost.sh`'s `_fc_epoch` does. Never through `date -d` or `date -j`.
- [ ] **Step 3: Run part 2310.** Expected: no `  FAIL` line.
- [ ] **Step 4: Run the lints this touches.** First, from the worktree root, run `git add engine/harness/lib/retro-rules.sh engine/harness/lib/retro-lines.sh engine/harness/lib/retro.sh engine/harness/felix`, because `bin/independence-scan` and `git grep` read tracked files only and never search an untracked one. Then run `--part` for `1497-lib-awk-gawk-names-blind.sh`; then for `0992-sort-comm-join-and-uniq-read-bytes-in-the-c-l.sh 0994-bash-s-own-collation-and-the-bsd-text-tools.sh 0996-continued.sh 0998-continued.sh 1000-the-engine-makes-its-scratch-under-tmpdir.sh`; then for `1530-patch-reads-the-repository-not-a-diff-setting.sh`; then for `0480-the-one-line-git-cannot-reconstruct.sh`; then for `0650-ecosystem.sh`; then for `1040-the-suite-is-cut-into-parts.sh`. One `--part` run takes one to six names that follow one another in the driver's order, or `tests/run` exits 2 and runs nothing (part 0001). Part 0480 checks the new usage line, part 0650 the ecosystem words, and part 1040 the driver's order and length and each part's length. Then run `engine/harness/bin/independence-scan` and the ecosystem word check over `felix` (Global Constraints). Expected: no `  FAIL`, exit 0, and no word-check output.
- [ ] **Step 5: Commit and push**, `feat(retro): felix retro walks the closed changes as of the main ref's last fetch and records them`, ending `Felix-Lane: capability`.

### Task 5: Lines and the come-back rules (Sonnet 5.5, xhigh)

**Files:**

- Modify: `engine/harness/lib/retro-lines.sh` (sealed).
- Modify: `engine/harness/lib/retro-rules.sh`, adding the rule functions.
- Modify: `engine/harness/lib/retro.sh`. For each closed change it calls `felix_retro_window`, `felix_retro_added`, `felix_retro_outcomes`, `felix_retro_classify` and `felix_retro_status`, passing their output through files under TMPDIR, and prints their cells.
- Test: part 2320.

**Interfaces:**

- Consumes: `felix_retro_window`, `felix_retro_table`, `FELIX_RETRO_FIX`.
- Produces, in `lib/retro-lines.sh`:
    - `felix_retro_added ROOT C` prints `PATH<TAB>START<TAB>COUNT` per added hunk, skipping submodule pointers and symlinks, and returns 1 on a failed read;
    - `felix_retro_outcomes ROOT C T WINDOWFILE ADDEDFILE ROWSFILE` prints `PATH<TAB>LINE<TAB>survived|changed|excluded|unread<TAB>SHA40|-` per added line. The sha is Y for `changed`.

- Produces, in `lib/retro-rules.sh`:
    - `felix_retro_is_revert SUBJECT` returns 0 or 1;
    - `felix_retro_names ROOT X C` returns 0 when X names C (C8);
    - `felix_retro_is_fix SUBJECT ROWSFILE` returns 0 or 1;
    - `felix_retro_excluded PATH ROWSFILE` returns 0 or 1;
    - `felix_retro_classify ROOT C OUTCOMESFILE WINDOWFILE ROWSFILE` prints `REVERT<TAB>STRONG<TAB>WEAK<TAB>EXCLUDED<TAB>UNREAD`, C5's cells 5 to 9, by C8's rules 1 and 2, reading a merge's merged subjects itself;
    - `felix_retro_status REVERT STRONG WEAK ISSUE` prints C5's cell 4 for a closed change. ISSUE is cell 10, `-` until Task 6.

- [ ] **Step 1: See part 2320 red** against Task 4's head. Expected: every change reads `quiet`, so the revert, strong, weak and excluded assertions fail, and R3's identity holds vacuously.
- [ ] **Step 2: Implement** C8's line reading and rules 1 and 2. The `-L` ranges for one file go to one blame call, and an empty window runs none. A path is passed after `--`, never as an option. `core.quotePath=false` goes on each diff and blame. git ends a `+++ b/<path>` line with a tab when the path holds a space (measured on git 2.56), so strip one trailing tab before reading the path.
- [ ] **Step 3: Run part 2320, then part 2310 again.** Expected: no `  FAIL` line in either.
- [ ] **Step 4: Run Task 4's lint parts, `bin/independence-scan` and the ecosystem word check**, as Task 4 Step 4 runs them. Expected: clean.
- [ ] **Step 5: Commit and push**, `feat(retro): reverts, strong fixes and weak edits read by reverse blame over each change's added lines`, ending `Felix-Lane: capability`.

### Task 6: Reopened issues (Sonnet 5.5, xhigh)

**Files:**

- Modify: `engine/harness/lib/retro-rules.sh`, adding the issue rule.
- Modify: `engine/harness/lib/retro.sh`, for the issue cell and the `kinds` cells.
- Test: part 2330.

**Interfaces:**

- Consumes: `felix_retro_select`'s rows; `felix_retro_status`.
- Produces, in `lib/retro-rules.sh`:
    - `felix_retro_slug ROOT` prints `OWNER/NAME` or nothing;
    - `felix_retro_issue ROOT C CT WINDOW SLUG` prints the issue cell (C5, cell 10) by C8's rule 3.

- [ ] **Step 1: See part 2330 red** against Task 5's head. Expected: the issue cells read `-` with `--issues`.
- [ ] **Step 2: Implement** C8's rule 3, with the gh argv exactly as pinned, and each line of gh's output checked for its shape before use. `felix_retro_status` now receives the issue cell.
- [ ] **Step 3: Run parts 2310 to 2330.** Then run Task 4's lint parts, `bin/independence-scan` and the ecosystem word check, as Task 4 Step 4 runs them. Expected: no `  FAIL` line, and exit 0.
- [ ] **Step 4: Commit and push**, `feat(retro): --issues asks GitHub which closed issues reopened, and reads could not look when it cannot`, ending `Felix-Lane: capability`.

### Task 7: The sample (Sonnet 5.5, high)

**Files:**

- Modify: `engine/harness/lib/retro-rules.sh`, adding the draw.
- Modify: `engine/harness/lib/retro.sh`, for the sample rows and the human section.
- Test: part 2340.

**Interfaces:**

- Consumes: the revert, strong and weak cells from Task 5; `felix_retro_seal`.
- Produces: `felix_retro_sample SEAL CELLSFILE`. CELLSFILE holds one `revert|strong|weak<TAB>C40<TAB>X40` row for each commit in a taken closed change's cells 5 to 7, as `lib/retro.sh` read them. The function forms C9's candidates, counting revert and strong rows as strong, and prints C9's `sample` rows, so the candidate rule stays sealed (C7).

- [ ] **Step 1: See part 2340 red** against Task 6's head. Expected: the sample assertions fail and the seal assertions pass (Task 4 built the seal).
- [ ] **Step 2: Implement** C9.
- [ ] **Step 3: Run parts 2310 to 2340.** Then run Task 4's lint parts, `bin/independence-scan` and the ecosystem word check, as Task 4 Step 4 runs them. Expected: no `  FAIL` line, and exit 0. The come-back half is complete. It is not run on real data yet: Task 12 Step 1 is the first count, made after slice 1's seed is on main, because the replay column may use only a seed sealed before the come-backs were first counted (design §8.5, §9).
- [ ] **Step 4: Commit and push**, `feat(retro): a fixed, sealed draw of strong and weak pairs for blind labels`, ending `Felix-Lane: capability`.

### Task 8: The replay part, once slice 1 is on main (Opus 5.5, xhigh)

**Files:**

- Create: `engine/harness/tests/parts/2350-retro-replay-blind.sh`
- Modify: `engine/harness/tests/run`, adding its line after 2340's.
- Modify: `engine/harness/tests/lib/retro.sh`, when builders are needed.

**Interfaces:**

- Consumes: slice 1's landed `felix situations --change <base>..<head> --tsv` contract (design §7.7 and slice 1's plan's Contracts), and C10.
- Produces: assertions prefixed `retro: replay`.

- [ ] **Step 1: Bring `claude/lane-retro` up to `origin/main` with `git merge --no-edit origin/main`** once slice 1 has landed. Use a merge, not a rebase: the branch is pushed, and a merge brings main in without rewriting it, so this plan needs no force push of any kind (deny.tsv:19 refuses `--force` and `-f`; part 0610 allows `--force-with-lease`, which slice 1's plan uses after its rebase). Resolve conflicts this way. In `engine/harness/tests/run`, keep both sides' lines, with the part lines in name order (2310 to 2360 before 2400 to 2470). In `felix` and `templates/schemas.tsv`, keep both sides' lines. In `docs/2026-10-29-capability-lane-first-slices-design.md` and `docs/2026-10-29-lane-slice-1-plan.md`, take origin/main's version (`git checkout --theirs -- <file>`; in a merge, theirs is origin/main), because slice 1's landing carries the newest text. In this plan, keep this branch's version (`git checkout --ours -- <file>`), after reading `git diff <lane sha> origin/main -- docs/2026-10-29-lane-slice-2-plan.md`, where `<lane sha>` is the commit Task 0 Step 6 copied from. A change that diff shows was made on the lane branch after the copy; make it in this branch's version too, before `git add`. A document never keeps both sides' lines. Then `git add` each resolved file and finish with `git commit --no-edit`. Run parts 2310 to 2340. Expected: no `  FAIL`.
- [ ] **Step 2: Compare slice 1's landed `--tsv` with C10.** Check the verdict tokens and the id cell against `felix situations --change HEAD~1..HEAD --tsv` run in the worktree. If they differ, tell the blind author before Step 3, and change C10 and C13's list for part 2350 in this plan in the same commit.
- [ ] **Step 3: Have the blind author write part 2350** to C13's list for it.
- [ ] **Step 4: Show 2350 red twice.** First on main: make a scratch worktree from `origin/main` (`git worktree add --detach <dir> origin/main`), copy in part 2350, `tests/lib/retro.sh` and their two driver lines, and run the part there (unknown command). Then remove that worktree. Second, on this branch after Step 1's merge, where slice 1 is present and replay still reads `off`. Record both counts in the handoff section file (Task 2 Step 3), and commit the counts as Task 2 Step 3 does.
- [ ] **Step 5: Commit and push**, ending `Felix-Lane: capability`.

### Task 9: The replay join (Sonnet 5.5, xhigh)

**Files:**

- Create: `engine/harness/lib/retro-replay.sh` (unsealed).
- Modify: `engine/harness/lib/retro-rules.sh`, adding the filing rule, which §8.5 seals.
- Modify: `engine/harness/lib/retro.sh`, calling the join per closed change when REPLAY is 1.
- Modify: `engine/harness/felix`, where `cmd_retro` also sources `lib/retro-replay.sh` with `|| exit 1`.
- Test: part 2350.

**Interfaces:**

- Consumes: slice 1's `felix situations --change ... --tsv`.
- Produces, in `lib/retro-rules.sh`: `felix_retro_file RC TSVFILE` prints `<owed|no row|could not look|unread><TAB><ids|->` by C10's filing rule, from situations' exit status and its stdout.
- Produces, in `lib/retro-replay.sh`: `felix_retro_replay ROOT BASE40 C40 FELIX`, which runs slice 1 and prints what `felix_retro_file` prints.

- [ ] **Step 1: Implement** C10. Run slice 1 in a subshell, so the cwd and the variables of `felix_retro` stay as they were.
- [ ] **Step 2: Check that this task moved no come-back rule.** `git diff <Task 7 head> -- engine/harness/lib/retro-lines.sh` must be empty, and the diff of `engine/harness/lib/retro-rules.sh` must only add `felix_retro_file`.
- [ ] **Step 3: Run parts 2310 to 2350**, five names in one `--part` run. Then `git add engine/harness/lib/retro-replay.sh`, and run Task 4's lint parts, `bin/independence-scan` and the ecosystem word check, as Task 4 Step 4 runs them. Expected: no `  FAIL`, and exit 0.
- [ ] **Step 4: Commit and push**, `feat(retro): each change is filed against what felix situations said it owed`, ending `Felix-Lane: capability`.

### Task 10: Adversarial review and fixes (review: Opus 5.5, xhigh; part 2360's blind author, who is neither the reviewer nor the implementer: Opus 5.5, xhigh; fixes by the implementer at Sonnet 5.5, xhigh)

**Files:**

- Test, when needed: `engine/harness/tests/parts/2360-retro-review-fixes-blind.sh`

**Interfaces:**

- Consumes: the branch diff against `origin/main`, the design and this plan.
- Produces: findings, and the fixes.

- [ ] **Step 1: Review.** The reviewer reads the diff, the design and the Contracts, and checks at least:
    - every rule C7 names lives in the two sealed files, and `lib/retro.sh` decides no cell;
    - no governed name, no ecosystem word and no lane-excluded file is touched;
    - nothing writes into the repository, the home or `facts.log`, and TMPDIR is left as it was;
    - "could not look" is never turned into "not reopened", `no row` or 0;
    - the Review Focus items.

- [ ] **Step 2: Fix.** A code finding goes to the implementer, and red twice moves the fix to Opus. A finding that needs a new assertion goes to a blind author, who writes part 2360 from the finding restated as required behaviour. The part is shown red on the pre-fix head. Write its red counts into the handoff section file (Task 2 Step 3), and commit the counts as Task 2 Step 3 does. Its line goes in the driver.
- [ ] **Step 3: Run parts 2310 to 2360.** When a fix touched `lib/`, `felix` or the driver, also run Task 4's lint parts, `bin/independence-scan` and the ecosystem word check, as Task 4 Step 4 runs them. Expected: no `  FAIL`, and exit 0. If a sealed file changed, say so in the handoff section file. No real-data count exists yet (Task 12 Step 1 is the first), so nothing is void.
- [ ] **Step 4: Commit and push.**

### Task 11: Version, handoff, record, gate and PR (Sonnet 5.5, high)

**Files:**

- Modify: `engine/.claude-plugin/plugin.json:4`, the next free patch slot at this moment.
- Create: `docs/handoff/pending/<UTC stamp>-claude-lane-retro.md`, through `felix handoff --section FILE`, with FILE the section file of Task 2 Step 3.
- Modify: `projects/felix/lane-next.tsv` (slice 0's table, columns `lane next`). Slice 1's PR leaves the `capability` row naming slice 2, marked "pending the direction fold" (design §9, §11 item 22). Set that row's `next` to `come-backs, slice 2: the sealed report from felix retro on the three repositories (branch claude/lane-retro)`, or, while the row slice 1 left carries the words `pending the direction fold`, to `come-backs, slice 2: the sealed report from felix retro on the three repositories, pending the direction fold (branch claude/lane-retro)`.
- Modify: `engine/harness/tests/assertions.tsv`, `engine/harness/tests/red.tsv` (written by the record).

**Interfaces:**

- Consumes: the whole branch.
- Produces: a PR in the landing queue.

- [ ] **Step 1: Bring the branch up to `origin/main` with `git merge --no-edit origin/main`**, not a rebase (Task 8 Step 1 says why), and run parts 2310 to 2360. Resolve conflicts as Task 8 Step 1 says. Expected: no `  FAIL`.
- [ ] **Step 2: Commit everything the PR carries** before the record: the version bump, the handoff section (its gate line pointing at the PR to be opened), and the `lane-next.tsv` move. Push.
- [ ] **Step 3: Ask the queue owner** (today the "Inventory next steps" session) for the slot for the record and then the gate. Wait for a yes.
- [ ] **Step 4: Record.** From the worktree root, start it detached through perl, which resets INT and QUIT to their defaults. A bare `&` from a non-interactive shell leaves them ignored, and part 1295 then fails. Keep `FELIX_TEST_JOBS` unset so it runs at -j 1 and leaves a receipt the gate can reuse, and poll its log: `nohup perl -e 'use POSIX (); POSIX::setsid(); $SIG{INT}=$SIG{QUIT}=q(DEFAULT); exec @ARGV' bash -c 'unset FELIX_TEST_JOBS; engine/harness/tests/run --record-assertions' > <scratch>/record.log 2>&1 &`. Expected: `0 failed` and a written `red.tsv`. Commit `assertions.tsv` and `red.tsv`, and push.
- [ ] **Step 5: Gate**, after the record has finished, from the same worktree root, under the same yes: `nohup perl -e 'use POSIX (); POSIX::setsid(); $SIG{INT}=$SIG{QUIT}=q(DEFAULT); exec @ARGV' ~/Documents/Felix/engine/harness/felix gate > <scratch>/gate.log 2>&1 &`, then poll the log. Expected: pass. The result goes in the PR body, not a commit.
- [ ] **Step 6: Open the PR** with `engine/harness/felix pr --create --title "feat(retro): felix retro counts the merged changes that came back, sealed, and files them against what each owed (0.49.<N>)"`. Turn on the CI monitor. The lander merges it on green. If the slot was taken meanwhile, take the next one and go back to Step 2.

### Task 12: The sealed report (Opus 5.5, high for the labels' brief and the report; Sonnet 5.5, high for the runs; the labeller is a person, or a fresh Opus 5.5 session at high that has read neither the design nor this plan)

**Files:**

- Create: `docs/<date>-come-backs-report.md`, and `docs/pdf/<date>-come-backs-report.pdf` rendered from it.
- Records, outside the tree: `~/.felix/memory/{felix,elenchus,veldra}/retro/*.tsv`.

No engine file changes. The three runs are the operator's and stay out of the suite.

**Interfaces:**

- Consumes: the landed engine (`felix install` from the home after landing, per the constitution).
- Produces: the report PDF, sent to the founder.

- [ ] **Step 1: Check slice 1's (e), then run the come-backs on the three clones.** First read slice 1's PR body and its handoff note. Its fresh Elenchus reading must have found `paid_ingress` ACTIVE and printed its proposed row (design §7.9 (e)). If it did not, stop and say so. Before this count, either the seed or the probes are fixed and the fix lands (design §9), or, when slice 1's note records the Elenchus checkout's environment as the only cause (slice 1's plan, Task 10), a fresh reading taken as that task takes it, with the landed engine, finds `paid_ingress` ACTIVE, prints its proposed row, and is recorded beside slice 1's. Either way it comes first, because a seed sealed after the come-backs were first counted is never used for the replay (§8.5). Then run without fetching, so each as-of time is the clone's own last fetch. This is the first count of come-backs on real data (§8.5): no real-data run of `felix retro`, with or without `--no-replay`, comes before it. Note each record's seed hash from its `sealed` row.
    - `felix retro /Users/a14808/Documents/Felix --tsv`
    - `felix retro /Users/a14808/Documents/Elenchus --tsv`
    - `felix retro /Users/a14808/ReserveGrid-OS --tsv`

    Expected: Elenchus, if not fetched since 10-08, takes 50 closed changes from 08-03 to 09-02 (UTC) with 7 open. Veldra, if its origin/main has not moved since 10-01, takes 50 from 05-01 to 08-29 with 24 open. felix-home's as-of is later than 10-29, because pulling the home to deploy the engine moves its origin/main reflog, so its 10-29 figures (50 closed from 09-23 to 09-26, 81 open) do not repeat. Each record states its seal, its as-of time and the ref its reflog came from.

- [ ] **Step 2: Run each once with `--issues`.** Report that kind apart, with its could-not-look counts. Expected, at the fetches Step 1 names: no message among Elenchus's 38 and Veldra's 50 changes with no PR number names an issue by a closing keyword (measured 10-29), so all 88 read `could not look` (C8, C12).
- [ ] **Step 3: Label the samples blind.** For each `sample` row, a labeller that never saw the rules gets only `git show C` and `git show X`. The labeller is a person, or a model whose output is marked as a sample label. The question: "Does X undo, repair or correct something C introduced? yes or no." Labels live only in the report.
- [ ] **Step 4: Write the report.** Per repository:
    - the rate as K of N, with the open count and the fetch time;
    - the weak count;
    - the split (owed, no row, could not look, unread), only from records whose seed hash is the one Step 1 noted (§8.5);
    - the strong rule's precision on its labels, and the weak sample's yes rate;
    - the seal and the engine version;
    - C12's limits, and the rest of §8.8's (stale clones, a closed change at least 30 days old, the replay joining per change and not per surface, the replay's unmeasured run time).

    If the strong precision is under 0.7, the report says the rate is not yet usable as a headline. If a sealed rule changed after a result was seen, the report says so and gives the re-run.

- [ ] **Step 5: Render the PDF** with the renderer `~/Documents/BehaviorChangeBench/scripts/pdfs.py` uses (Markdown to HTML to headless Chrome), into `docs/pdf/`.
- [ ] **Step 6: Commit and PR.** On `claude/lane-retro`, first brought up to `origin/main` with `git merge --no-edit origin/main` as Task 8 Step 1 says, commit the report, its PDF and the `lane-next.tsv` move. Set `next` to the first open item of direction §5's order after intake (item 4, Codex read-only), unless the direction fold (design §12) has set another order; then to that order's first open item. Slice 3 waits on the founder's false-block bound (design §12), and a finding of misread intent no longer moves slice 5 ahead (design §9, §11 item 41). The commits end with `Felix-Lane: capability`. This docs PR changes no engine path, so it is not a lane landing (design §6.2, §11 item 3). Push, and open the docs PR, which merges on green. Send the PDF to the founder.

## Coverage

| Design requirement | Contract | Part | Task |
|---|---|---|---|
| §8.1, §8.2 command, read-only, bound project | C1, C2, C5, C11 | 2310 | 4 |
| §8.2 selection, open apart, `C^1` base (§11 item 14) | C3 | 2310, 2320 | 4, 5 |
| §8.2 as of the last fetch | C3 | 2310 (R1, R5) | 4 |
| §8.2 the 30-day window, sealed, a flag (§11 item 38) | C3, C5 | 2310 | 4 |
| §8.2 added lines with renames detected (§11 item 33) | C8 | 2320 | 5 |
| §8.3 rule 1 (revert) | C8 | 2320 | 5 |
| §8.3 rule 2 (strong, weak, exclusions) | C4, C8 | 2320 (R2 to R4) | 3, 5 |
| §8.3 a merge's merged subjects (§11 item 34) | C8 | 2320 | 5 |
| §8.3 an empty window runs no blame (§11 item 35) | C3, C8 | 2320 | 5 |
| §8.3 rule 3 (reopened issue; a change with no PR number keeps its keyword issues, §11 item 43) | C8 | 2330 | 6 |
| §8.3 the table and its schema row | C4 | schema-check, 2310, 2320 | 3 |
| §8.4 replay, filed per change, ids carried (§11 item 15) | C10 | 2350 | 8, 9 |
| §8.5 sealing, with the filing rule, the bound, the seed and the probes (§11 item 39) | C7 | 2340 | 4, 9, 12 |
| §8.6 measures, sample, 0.7 bound (§11 items 16, 40) | C5, C6, C9 | 2310, 2340 | 7, 12 |
| §8.7 acceptance, every bullet | C3, C6, C8, C10 | 2310 to 2330, 2350 | 4 to 6, 9 |
| §8.7 real data | C12 | none (operator runs) | 12 |
| §8.8 limits | C12 | none | 12 |
| §3 anti-goals: no bare rate, could not look | C6, C8, C10 | 2310, 2330, 2340, 2350 | 4, 6, 7, 9 |
| §4 offline, deterministic, nothing written to the repository | C3, C5 | 2310, 2350 | 4, 9 |
| §4 how it lands (§11 items 2, 21) | Global Constraints | 0480 | 0, 4, 11 |
| §9 slice 2, its replay after slice 1's seed (§11 items 3, 22, 41) | C7 | none | 0, 7, 11, 12 |
