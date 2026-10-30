# Lane Counter (Slice 0) Implementation Plan

> **For agentic workers:** run this plan as the founder's engine-build Workflow: spec, blind assertions, red first, implementation, adversarial review, gate. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** Count each lane's share of the engine landings on a project's `origin/main`, offline, and put a short or empty lane in front of the next session that has no task and on the founder's screen line.

**Architecture:** One new library, `engine/harness/lib/lane.sh`, reads two per-project tables and walks the first-parent history of `refs/remotes/origin/main` in the checkout, writing nothing. One function, `felix_lane_rows`, gives every surface its lines: `felix lane [--tsv]`, a ninth `felix status` row, a session-start paragraph and screen token, and one pulse line per lane. felix-home gets its two tables and two `schemas.tsv` rows in the same PR.

**Tech stack:** Bash 3.2 and git; awk that BWK awk and gawk both run; the suite's `tests/run` parts.

**Spec:** `docs/2026-10-29-capability-lane-first-slices-design.md`, §6 (slice 0), read with §1 to §5, §9 and §10; and this plan's Contracts section. All code was read on 2026-10-29 at `e54e31f3` (engine 0.49.309), which is `origin/main`.

## Global Constraints

- Bash 3.2 and git only: no jq, no python.
- Only awk that both BWK awk (local) and gawk (CI) run. Part 1497's `_awk_names` lints `lib/`.
- `LC_ALL=C` on every sort, comm, join and uniq (part 0992).
- `[[ =~ ]]` only inside a function that declares `local LC_ALL=C` (part 0996).
- Flags go through `need_value` (`felix:389-391`), never a bare `shift 2`.
- The engine names no project (constitution invariant 1). Everything project-specific lives in a `projects/<p>/` table or arrives as an argument. No lane name is a literal in engine code either.
- Offline and deterministic (invariant 2): two runs with the network off and no key print identical bytes. The counter never fetches.
- A check that cannot fail is not a check (invariant 5): every new check is shown failing first.
- Never delete a home or a memory root (invariant 6).
- Records go under the memory root or under `state/`. Nothing is written into a governed repository: its refs, index, config and worktree list stay as they were.
- The lane never touches `lib/qualify.sh`, `lib/obligations.sh`, `lib/receipt.sh`, `lib/automerge.sh`, `lib/green-*.sh`, `lib/land-table.sh`, `lib/notify.sh`, `lib/own.sh`, `lib/status-land.sh`, or the `felix merge` and `felix land` code paths.
- Each new table is a new file with one new `schemas.tsv` row. No column is added to an existing table.
- No force: nothing here blocks a merge, holds a release, comments on a pull request or writes an enforcing table. No push alert.
- No model, key or network on any path.
- `unknown` is never printed or counted as `ok`.
- One engine PR for this slice. No new engine branch while more than 10 engine PRs are open; the builder checks `gh pr list` first.
- The PR bumps the patch version in `engine/.claude-plugin/plugin.json` and puts it in its title. 0.49.310 to 0.49.313 are claimed.
- Every new `felix` command appears in `usage()` (part 0480).
- Suite manners: commit everything before the record; red and gate never share a worktree; at most four part runs at once, across the Mac; no whole-suite run while another session's record or gate holds the queue.
- Files stay under 500 lines, `lib/lane.sh` included. A part stays under the 1,000 lines part 1040 allows.

## Contracts

The blind author reads the design and this section, and nothing else of the plan. Every name, sentence, column and exit status here is exact. Where the design left a choice to the builder, the choice is made here and listed in C12.

In this section, `<p>` is a project name, `<PROJ>` is `<home>/projects/<p>` with `<home>` as `FELIX_HOME` names it, `<repo>` is the physical path of the checkout's top directory (what `pwd -P` prints there), a date is UTC in the form `YYYY-MM-DDTHH:MM:SSZ`, and TAB is one tab byte.

### C1. The two tables

**`<PROJ>/lanes.tsv`**, schema columns `lane counts share window`, one row per lane.

- `lane`: matches `^[A-Za-z0-9][A-Za-z0-9._-]*$`. The lane's mark is the line `Felix-Lane: <lane>`.
- `counts`: an ERE over changed paths. It is valid when `LC_ALL=C grep -E -e '<counts>'` accepts it (on empty input, any exit status but 2).
- `share`: `n/d`. Each of n and d matches `^[123456789][0123456789]{0,3}$`, and n ≤ d. So `0/2`, `1/0`, `3/2`, `01/2` and `1/2/3` are invalid.
- `window`: days, matching `^[123456789][0123456789]{0,3}$`. So `0`, `014` and `14d` are invalid.
- A lane named on more than one row makes every one of those rows invalid.

**`<PROJ>/lane-next.tsv`**, schema columns `lane next`.

- `next` is the lane's first open item, any text a cell can hold.
- A lane with no row reads next `none`. A lane with more than one row reads next `unknown`. A row naming a lane that `lanes.tsv` does not hold is ignored.
- This table never changes a lane's state.

**The shape check.** Each table is read only when the engine's table validator (`lib/table.sh`, `felix_table_check`) accepts it against `engine/harness/templates/schemas.tsv`, the same check `bin/schema-check` runs on every gate. It refuses, among others: a CR byte anywhere; a last byte that is not a newline; a NUL; a leading, trailing or doubled tab; a row with the wrong number of cells; whitespace before `#`; a line of only whitespace; a line that is not UTF-8; a line starting with a non-ASCII byte; a symlink; a path that is not a readable regular file. Comment lines start with `#` in column 1, and blank lines are skipped.

- A `lanes.tsv` the check refuses reads `unknown` on every surface (reason R4 in C5).
- A `lane-next.tsv` the check refuses makes every lane's next read `unknown`.
- Absent, or present with no row, `lanes.tsv` means the project counts no lane.

**felix-home's files.** `projects/felix/lanes.tsv`, exactly these bytes (TAB between cells, a newline after every line):

```
# The lanes this project counts (lib/lane.sh), from docs/2026-10-29-capability-lane-first-slices-design.md §6.3.
# lane, counts (an ERE over changed paths), share (n/d), window (days). A change here lands on green;
# felix lane names the commit that last changed this file.
capability	^engine/	1/2	14
```

`projects/felix/lane-next.tsv`, exactly these bytes:

```
# Each lane's first open item, on one line (lib/lane.sh, design §6.3). The pull request that lands a
# lane item moves its row in the same change.
capability	obligation intake, slice 1: felix situations --change (branch claude/lane-situations-owed)
```

Slice 1's PR will change `1/2` to `1/4` in the first file and replace the data row of the second; both edits keep these shapes.

**`schemas.tsv` rows.** Inserted after the `land.tsv` row (`engine/harness/templates/schemas.tsv:85`). Columns are tab-separated, and the column list is space-separated inside its cell, as every row there is:

```
# The lanes a project counts (lib/lane.sh). Absent, or present with no row, the
# project counts no lane: felix lane prints nothing, the lane row of felix status
# reads none, and session start and the pulse say nothing. Present and refused by
# this check, every lane reads unknown. A change to it lands on green.
lanes.tsv	tree	lane counts share window	allowed
# Each lane's first open item (lib/lane.sh). Absent, or with no row for a lane,
# that lane's next reads none; refused by this check, every next reads unknown.
# It never changes a lane's state.
lane-next.tsv	tree	lane next	allowed
```

Neither name joins `FELIX_ESCAPE_TABLES`: a change to either lands on green (design §5.6). Adding a `schemas.tsv` row is free at the merge boundary.

### C2. What is read, and from where

- **The project** is the one Felix binds the directory to: the `.felix` marker first, then a `project.json` `remote_match`.
    - `felix lane` and `felix status`: the current directory.
    - Session start: the session's directory.
    - The pulse: only the project the Felix home's own checkout is bound to. A home that is not a git checkout, or binds no project, gets no lane line. No other project's lane is counted by the pulse, because no project records where its checkout is.

- **The tables** are `<PROJ>/lanes.tsv` and `<PROJ>/lane-next.tsv` in the Felix home's working tree, as every project table is read.
- **The repository** is the git repository holding that directory: the checkout or worktree it stands in. For the pulse, it is the home checkout.
- **The ref** is `refs/remotes/origin/main` in that repository, by its full name. It is never fetched. There is no fallback to a local `main`, to another remote or to another branch name. A worktree reads the refs it shares with its main checkout.
- **For felix-home**, every surface run in the home checkout or any worktree of it counts that repository's `origin/main` as last fetched, with the tables from the Felix home.
- **The last change** (C5 columns 10 and 11) is read from the history of the git repository that holds `<PROJ>`, at its `HEAD`.
- **Nothing is written.** No surface changes a ref, the index, config, the worktree list or any file of the repository or the home. `felix lane` exports `GIT_OPTIONAL_LOCKS=0`, as `felix status` already does. The pulse writes only what it writes today (`state/pulse.log`, `state/pulse.status.tsv`).

### C3. What counts

Design §6.2, as the engine applies it.

- **A landing** is a commit on the first-parent chain of `refs/remotes/origin/main`. Its time is its committer time.
- **The clock.** `now` is `FELIX_LANE_NOW` when that is set and not empty, else the machine clock (C9).
- **The window** of a lane with window W holds every landing whose committer time t has `now − W·86400 ≤ t ≤ now`. Both ends are inclusive. A landing dated after `now` is in no window. The whole first-parent chain is walked: the walk does not stop at the first landing older than the window, so an out-of-order date cannot hide a later landing.
- **Changed paths.** A landing's changed paths are those between it and its first parent, with rename detection off, so a move lists both paths. That is what `git diff-tree -r --no-renames --name-only <C>^1 <C>` prints. A real merge is compared with its first parent only. A commit with no parent, in a repository that is not shallow, changed every path in its tree.
- **Counted.** A landing is counted for a lane when at least one changed path matches the lane's `counts` ERE, as `LC_ALL=C grep -E` matches.
- **Marked.** A landing is marked for a lane when some commit in `<C>^1..<C>` has a message line that, after its trailing spaces, tabs and CRs are removed, is byte for byte `Felix-Lane: <lane>`. For a single-parent landing that set is the landing alone. For a real merge it is the merge and every commit it brought in. For a commit with no parent it is that commit.
    - Not marked: a line with leading whitespace, another case (`felix-lane: <lane>`), no space after the colon, two spaces, more text after the lane name, or the words inside a sentence.
    - How the landing was made does not matter. A squash written by `felix merge` and one written by GitHub are both single-parent commits whose messages hold the branch's commit messages.

- **L** is the number of landings in the window that are counted and marked. **T** is the number counted, marked or not. L ≤ T always.
- **The last lane landing** is the latest committer time, at or before `now`, among landings that are counted and marked, at any age on the whole first-parent chain. It prints as a date, or `none` when there is none.
- **A shallow repository** (`git rev-parse --is-shallow-repository` prints `true`) cannot be counted: every lane reads `unknown`, reason R3.
- **Any git read that does not finish** (a missing object, a corrupt repository, a fork that fails) makes the lane `unknown`, reason R2. A read that did not finish never yields a count.

### C4. States

For each lane row, with L and T from C3 and its share n/d, decided in this order:

| State | When |
|---|---|
| `unknown` | any reason R1 to R8 of C5 applies |
| `idle` | T = 0 |
| `zero` | L = 0 (and T > 0) |
| `ok` | L·d ≥ n·T |
| `short` | otherwise (L > 0 and L·d < n·T) |

This is the design's table (§6.4); because n ≥ 1, the rows never overlap. So L·d = n·T reads `ok`, and one lane landing fewer reads `short`.

### C5. `felix lane`

```
felix lane [--tsv]
```

- **Read-only and offline.** It writes nothing (C2) and takes no network.
- **Arguments.** None, or exactly `--tsv`. Anything else (`--json`, `--tsv --tsv`, `x`) is a usage error: nothing on stdout, `felix: usage: felix lane [--tsv]` on stderr, exit 2. `felix lane --help` prints the general usage and exits 0.
- **Not governed.** In a directory no project governs, it exits 2 with Felix's usual "no project governs" message on stderr and nothing on stdout.
- **No lane.** When `<PROJ>/lanes.tsv` is absent, or present with no row, it prints nothing and exits 0.
- **Otherwise** it prints one line per data row of `lanes.tsv`, in file order, and exits 0, whatever the states. When `lanes.tsv` is refused by the shape check, it prints exactly one line, whose lane is `-`.
- **`usage()`** gains, in its "every day" block right after the `felix status` line: `    felix lane [--tsv]     read-only: each lane's share of engine landings on origin/main, against its target` (four spaces, the command, five spaces, the text, so the text starts where `felix which`'s does).

**`--tsv`**: no header; thirteen tab-separated columns per line.

| # | Column | Value |
|---|---|---|
| 1 | lane | the lane name; `-` when the row's first cell is not a valid lane name, or the table was refused |
| 2 | state | `ok`, `short`, `zero`, `idle` or `unknown` |
| 3 | L | a whole number; `-` when unknown |
| 4 | T | a whole number; `-` when unknown |
| 5 | window | W from the row; `-` when the row is invalid |
| 6 | share | `n/d` from the row; `-` when the row is invalid |
| 7 | last | the last lane landing's date, or `none`; `-` when unknown |
| 8 | mark | `Felix-Lane: <lane>`; `-` when the row is invalid |
| 9 | next | the lane's next text, `none` or `unknown`; `-` when the row is invalid |
| 10 | changed | the full object name of the last commit at the home's `HEAD` that changed `<PROJ>/lanes.tsv`; `uncommitted` when the working file differs from `HEAD`'s copy or `HEAD` has none; `unknown` when git cannot answer (the home is not a repository, or has no `HEAD`) |
| 11 | changed_date | that commit's committer date; `-` unless column 10 is a commit |
| 12 | ref_date | the committer date of the commit `refs/remotes/origin/main` names; `-` when the ref cannot be read |
| 13 | detail | `-`, unless the state is `unknown`; then the reason below |

Columns 10, 11 and 12 are filled on every line, including `unknown` ones. Column 12 is the ref commit's own date, not the fetch time, so two runs print the same bytes.

**Reasons**, exact text, in the order they are tried for a row. The table-level R4 gives the single `-` line; the others are per row.

| | Reason (column 13, and the status row's detail) |
|---|---|
| R4 | `<PROJ>/lanes.tsv cannot be read as lanes.tsv` |
| R5 | `row <k> of lanes.tsv is not a lane name, an ERE, a share n/d and a window in days` (k counts data rows from 1) |
| R6 | `lane <lane> is named on more than one row of lanes.tsv` |
| R7 | `the counts pattern of lane <lane> is not an ERE grep accepts` |
| R8 | `FELIX_LANE_NOW is not a whole number of seconds` |
| R1 | `refs/remotes/origin/main cannot be read in <repo>` |
| R3 | `<repo> is a shallow clone, so its landings cannot all be read` |
| R2 | `git could not read the landings on refs/remotes/origin/main in <repo>` |

A row that hits R5 or R6 still prints its first cell in column 1 when that cell is a valid lane name.

**Human form** (no flag): one line per TSV line, built from it.

- A known state:

```
<lane>: <state>, <L> of <T> engine landings in <W> days, target <n>/<d>; last lane landing <last>; mark Felix-Lane: <lane>; next: <next>; <changed>; refs/remotes/origin/main at <ref_date>
```

- An unknown state:

```
<lane>: unknown, <reason>; <changed>; refs/remotes/origin/main at <ref_date>
```

- `<changed>` is one of: `lanes.tsv last changed by <first 12 characters of column 10> at <changed_date>`; `lanes.tsv has uncommitted changes`; `lanes.tsv's last change cannot be read`.
- `<last>`, `<next>` and `<ref_date>` are columns 7, 9 and 12 as printed there.

Example, felix-home at `e54e31f3` with the clock at that commit (design §6.6):

```
capability: zero, 0 of 18 engine landings in 14 days, target 1/2; last lane landing none; mark Felix-Lane: capability; next: obligation intake, slice 1: felix situations --change (branch claude/lane-situations-owed); lanes.tsv last changed by <sha12> at <date>; refs/remotes/origin/main at 2026-10-29T21:26:13Z
```

### C6. `felix status`: the lane row

- `felix status --tsv` prints nine rows: `settings schedule pulse reach gate land hooks alerts lane`. The first eight are byte-identical to what they print without the lane row's input (for example, with `lanes.tsv` absent). The lane row is last.
- The row keeps the status shape: `lane<TAB><state><TAB><value><TAB><detail>`. state is `value`, `none` or `unknown`; value is `-` unless state is `value`; detail is one line, never empty.
- The row speaks for the **first data row** of `lanes.tsv` (or the single R4 line).

| Case | Row |
|---|---|
| no project governs the directory | `lane<TAB>none<TAB>-<TAB>this directory is not a governed checkout` |
| `lanes.tsv` absent | `lane<TAB>none<TAB>-<TAB><PROJ>/lanes.tsv does not exist, so no lane is counted` |
| `lanes.tsv` present with no row | `lane<TAB>none<TAB>-<TAB><PROJ>/lanes.tsv has no row, so no lane is counted` |
| first lane `ok`, `short`, `zero` or `idle` | `lane<TAB>value<TAB><state><TAB><L> of <T> engine landings in <W> days, target <n>/<d>` |
| first lane `unknown` | `lane<TAB>unknown<TAB>-<TAB><the C5 reason>` |

- Plain `felix status` aligns it as it aligns every row: `printf '%-9s %-12s %s\n'` of row, value (the state word when state is not `value`) and detail.
- `felix status` stays read-only, offline, and exit 0 for any report.

### C7. Session start

- **The paragraph.** For each data row of `lanes.tsv` whose state is `short` or `zero`, in file order, the session's context (`hookSpecificOutput.additionalContext`) gains this paragraph, a newline before it:

```
Lane <lane> is <state>: <L> of <T> engine landings in <W> days, target <n>/<d>.
If the founder has not given this session a task, take the first open lane item: <next>. End a commit message on its branch with `Felix-Lane: <lane>`. Trust work takes the other half.
```

- `<next>` is the next text; `(lane-next.tsv names none)` when it reads `none`; `(lane-next.tsv cannot be read)` when it reads `unknown`. The backticks around the mark are literal.
- The sentence `Trust work takes the other half.` (and the space before it) appears only when 2·n = d. Otherwise the second line ends after the mark sentence.
- **Where.** The paragraphs sit right after the "what waits" paragraphs and before the capability-drift ones, in the block that follows `Memory: <dir>/`.
- **The screen token.** When the first data row's state is `zero`, the screen line (`systemMessage`) ends with ` · lane: 0 in <W> days` (a space, a middle dot U+00B7, a space). It is the last token on the line. No other state adds a token.
- **Silence.** Neither the paragraph nor the token appears for `ok`, `idle` or `unknown`, for a project with no `lanes.tsv` or none with a row, on a `resume` start (which prints nothing, as today), or in a directory no project governs.
- **Robust.** The hook exits 0 and prints valid JSON whatever the tables hold, whatever `next` contains, and when `lib/lane.sh` is missing from the engine (then no lane text appears). When `lanes.tsv` is absent, the hook runs no git command for the lane.

### C8. The pulse

- Each `felix pulse` run (no flag) prints, appends to `<home>/state/pulse.log` and writes into `<home>/state/pulse.status.tsv` one line per data row of the home project's `lanes.tsv`, in file order:

```
lane<TAB><lane><TAB><state><TAB><L><TAB><T>
```

- L and T are `-` when the state is `unknown`. A refused `lanes.tsv` gives one line, `lane<TAB>-<TAB>unknown<TAB>-<TAB>-`.
- The lane lines are the last lines of the run: after the backup, settings, report and reach lines.
- No lane line when the home project has no `lanes.tsv`, or it has no row, or the home is not a checkout bound to a project (C2).
- The pulse still exits 0, and writes nothing it did not write before.

### C9. The clock, and how a fixture points the engine at a repository

- **The clock.** `FELIX_LANE_NOW`, when set and not empty, is the instant taken as now: whole seconds since 1970-01-01T00:00:00Z, 1 to 12 digits, nothing else. Any other value reads `unknown` on every lane (R8). Unset or empty, now is `date -u +%s`. Every surface honours it: `felix lane`, `felix status`, session start and `felix pulse`.
- **Commit times.** A fixture pins each commit's committer time with `GIT_COMMITTER_DATE="<epoch> +0000"` (and `GIT_AUTHOR_DATE` the same). To keep trailing spaces or a CR in a message, commit with `git commit --cleanup=verbatim -F <file>`; git's default cleanup strips them.
- **The ref.** A fixture makes `refs/remotes/origin/main` with `git update-ref refs/remotes/origin/main <commit>`. No remote needs to exist. A repository without that ref reads R1.
- **Binding.** A checkout is bound to a fixture project by a `.felix` file holding the project's name, with `FELIX_HOME` naming a fixture home that holds `projects/<p>/project.json` (for example `{"name":"<p>","gate":"true"}`) and `projects/<p>/CLAUDE.md`. Build fixtures under physical paths (`pwd -P`), because reasons and details print physical paths.
- **Two layouts.**
    - *Home apart:* a home H (a git repository, so the last change can be read) and a checkout C bound by `.felix`. Status and session start are best tested here: editing H's tables does not change C's tree.
    - *Self-governed:* one repository that is both the home and the checkout, with `.felix` at its top, as felix-home is. The pulse needs this layout (C2).

- **Memory.** `FELIX_MEMORY` must name a directory outside every fixture repository. A memory root inside a repository the home owns makes `felix pulse` commit and push there.
- **The engine under test** is the suite's copy: `$FELIX` for the CLI, `$FROOT/harness/hooks/session-start` with `CLAUDE_PLUGIN_ROOT="$FROOT"` for the hook, a startup payload `{"session_id":"…","source":"startup","cwd":"<C>"}` on stdin, run from C. Stub `claude`, `gh` and `graphify` first on PATH, as part 1670 does. Read `systemMessage` and `hookSpecificOutput.additionalContext` with python3 on the test side, skipping with a reason when python3 is absent.
- **Suite helpers.** `ok`, `bad`, `is`, `has` and `skip` from `tests/run`; `_fx_cd` for every fixture git command (part 0002); `$TMP`, `$FROOT`, `$FELIX`. A part opens with `# >>> <marker>` and closes with `# <<< <marker>`. A `tests/lib` file defines functions and nothing else (part 0006). A `[[ =~ ]]` in a part runs in a subshell (part 1690's `_lnd_like` says why).

### C10. Assertions the blind parts must carry

Beyond the design's §6.6 bullets, these are required. The names are the IDs the review and the PR cite.

- **L-RF1, the mark as people write it.** A lane landing whose mark line ends in spaces, a tab or a CR counts in L. One whose mark line has leading whitespace, reads `felix-lane: <lane>`, has no space after the colon, or has text after the lane name does not count in L, and still counts in T when it changed a counted path.
- **L-RF2, next is free text.** With `next` holding a double quote, a backslash and a non-ASCII character (for example `fix "a\b" — now`), and the lane `zero`: session start exits 0, its output parses as JSON, the context holds the next text byte for byte, and `felix lane --tsv` prints it unchanged in column 9.
- **L-RF3, a table broken by hand.** Each of these reads `unknown` in `felix lane --tsv` column 2 with the C5 reason, makes the status row `lane unknown -` when it is the first row, and leaves session start exiting 0 with valid JSON and neither paragraph nor token: share `1/0`, `3/2`, `0/2`, `1/2/3`; window `0`, `14d`, `014`; counts `(`; a lane named twice; a CR in a row; no final newline; an empty cell; a row of three cells.
- **L-RF4, a broken pointer never silences a stall.** With the lane `zero`: `lane-next.tsv` absent gives next `none`, the paragraph with `(lane-next.tsv names none)`, and the token; `lane-next.tsv` refused (a CR in it) gives next `unknown` and `(lane-next.tsv cannot be read)`; two rows for the lane give `unknown`. The state stays `zero` in all three.
- **L-RF5, a shallow clone.** A `git clone --depth 2 file://<repo>` of a fixture, whose `refs/remotes/origin/main` the clone holds, reads `unknown` with R3 in `felix lane`, the status row, and session start (no paragraph, no token). It never reads a count.
- **L-NEVER-OK.** In every `unknown` case any part provokes, no surface prints `ok`: not `felix lane` column 2, not the status row's value.
- **L-DET.** Two runs of `felix lane`, `felix lane --tsv` and `felix status --tsv`, same fixture and same `FELIX_LANE_NOW`, print identical bytes.
- **L-RO.** `felix lane` and `felix status` leave nothing newer under the home, the memory root or the checkout (`.git` included) than a marker touched before the run, and `git for-each-ref` and `git worktree list` in the checkout print the same before and after.

### C11. Blind parts

| File | Covers |
|---|---|
| `engine/harness/tests/lib/lane-fixture.sh` | Builders only, for the parts below: a home, a checkout, a landing at a pinned time with a given message and paths, a real merge, publishing `origin/main`. |
| `tests/parts/2200-lane-counts-blind.sh` | §6.2 and §6.6 "The counts": the eight landings, with L and T exact at each edge (a landing at now − W·86400 counts; one a second earlier does not; one at now counts; one a second after now does not); L-RF1; a real merge read through its merged commits; a merge whose marked commits change no counted path; a rename out of a counted path; L-RF5. |
| `tests/parts/2210-lane-states-blind.sh` | §6.4 and §6.6 "The state edges": L·d = n·T reads `ok`, one fewer `short`, `zero`, `idle`, an unreadable ref `unknown`; R1 to R8; L-RF3; L-NEVER-OK. |
| `tests/parts/2220-lane-command-blind.sh` | §6.5 item 1 and §6.6 "The last change" and "Determinism": usage line and exits; the thirteen columns and the human line; last lane landing; next `none`/`unknown`; changed as a commit, `uncommitted` and `unknown`; after a commit that changes a lane's share, `felix lane` names that commit and its date; L-DET; L-RO; no `lanes.tsv` prints nothing. |
| `tests/parts/2230-lane-status-row-blind.sh` | §6.5 item 2 and §6.6 `felix status --tsv`: exactly one row more, at the end, the eight before it byte-identical; every C6 case; the status shape; L-DET and L-RO for status. |
| `tests/parts/2240-lane-session-start-blind.sh` | §6.5 items 3 and 4 and §6.6 "What shows where": paragraph only for `short` and `zero`, token only for `zero`, neither without `lanes.tsv`; exact paragraph text with share `1/2` and with `1/4`; a resume; L-RF2; L-RF4; the hook with `lib/lane.sh` removed from a harness copy still exits 0 with valid JSON. |
| `tests/parts/2250-lane-pulse-blind.sh` | §6.5 item 5: the pulse lines, in the log and in the record, last; `unknown` with `-`; no line without `lanes.tsv`; no line for a project other than the home's. |
| edits to parts 1100, 1690 and 1720 | Their eight-row assertions become nine, `lane` last (C6). |

The design's two real-data bullets (§6.6 "Real data" and "Falsified if") are measurements on felix-home, not suite parts: a suite part may not depend on one project's history. They run in Task 8.

A worked expectation for "The counts": with landings (a) a marked engine change in a `felix merge` squash, (b) a marked engine change in a GitHub squash, (c) a marked docs-only change, (d) an unmarked engine change, (e) an unmarked docs-only change, (f) a real merge whose merged commits carry the mark and change `engine/`, (g) an engine change whose message mentions the mark inside a sentence, all in the window, and (h) a marked engine change one second before the window, `counts` `^engine/` gives L = 3 (a, b, f) and T = 5 (a, b, d, f, g).

### C12. Decided in this plan

1. The counter reads the checkout's `refs/remotes/origin/main` by full name, with no fallback (C2). The pulse counts only the home's own project.
2. The window is inclusive at both ends, excludes landings after now, and walks the whole first-parent chain (C3).
3. The mark is a whole line, trailing spaces, tabs and CRs ignored, nothing else forgiven (C3).
4. Changed paths are against the first parent with renames off; a shallow repository reads `unknown` (C3).
5. Tables pass the engine's table check, then the value rules of C1. n ≥ 1, so `ok` and `zero` never overlap. `lane-next.tsv` never changes a state: a broken pointer must not hide a stall, so "a table could not be read" in §6.4 is read as `lanes.tsv`.
6. The clock is `FELIX_LANE_NOW`, whole seconds (C9).
7. The last lane landing is searched over the whole first-parent chain, not only the window.
8. The last change is read from the home's `HEAD` history; `uncommitted` when the working file differs.
9. The status row and the screen token speak for the first lane row; `felix lane`, the paragraph and the pulse speak for every row.
10. `Trust work takes the other half.` prints only when the share is one half, so the sentence stays true after slice 1 sets `1/4`.
11. `felix lane` dispatches after the libraries load, not with `audit`, `inventory` and `cost`: it needs a home and a project.
12. The TSV's columns, the human line, the reason sentences and the status details are as written above.
13. The real-data check and the 60-day hand check are recorded measurements outside the suite (Task 8).

## Review Focus

The five input classes the design implies and no design bullet exercises, most likely to bite a person first. Each is pinned by a named assertion in C10, and the reviewer re-runs it by hand in Task 9.

1. **A mark written slightly differently** (an editor's trailing space or CRLF, an indented line in a hand-written squash body, a lower-case key): L silently undercounts and the lane reads `zero` while lane work lands. Pinned by L-RF1.
2. **`next` text that JSON must escape** (a quote, a backslash, a non-ASCII dash): a bad escape breaks the session-start JSON, and with it the whole banner. Pinned by L-RF2.
3. **A table broken by a hand edit** (`1/0`, `14d`, an unbalanced `(`, CRLF, no final newline, a duplicated lane): it must read `unknown`, never `ok`, and never crash the hook. Pinned by L-RF3 and L-NEVER-OK.
4. **A missing or broken `lane-next.tsv` while the lane is empty**: if it made the state `unknown`, the stall would go silent again, which is the failure slice 0 exists to end. Pinned by L-RF4.
5. **A shallow clone** (CI with depth 1, a stranger's quick clone): its boundary commit looks parentless, and counting it as a root would call it an engine landing. Pinned by L-RF5.

## Tasks

The Workflow runs the tasks in this order. Each stage names its model and effort. Commit and push at the end of every stage, because workflow agents die together. A stage that goes red twice moves up to Opus 5.5. The implementer never writes or edits a blind part; a wrong blind part goes back to the blind author.

### Task 0: Open the build

Model: Sonnet 5.5, high.

**Files:** none changed.

**Interfaces:** Consumes the open PR list and the live sessions. Produces the worktree `<home>/.claude/worktrees/lane-counter` on branch `claude/lane-counter`, cut from `origin/main`.

- [ ] Count open engine PRs: `gh pr list --state open --limit 200 --json number,files --jq '[.[] | select(any(.files[]; .path | startswith("engine/")))] | length'`. Expect a number of 10 or less. Above 10, stop and wait.
- [ ] List live sessions (`ListAgents`). Expect none on `claude/lane-counter`. A session on `claude/lane-situations-owed` is slice 1; it rebases on this branch later, and only the two lane tables overlap.
- [ ] `git -C <home> fetch origin`, then `git -C <home> worktree add -b claude/lane-counter <home>/.claude/worktrees/lane-counter origin/main`. Check that `git -C <wt> rev-parse HEAD` equals `git -C <home> rev-parse origin/main`.
- [ ] Bring the spec in, once this plan is committed on `claude/lane-situations-owed` beside the design: `git -C <wt> checkout claude/lane-situations-owed -- docs/2026-10-29-capability-lane-first-slices-design.md docs/2026-10-29-lane-slice-0-plan.md`. Commit `docs(capability): the lane counter's design and plan, slice 0's spec`. Push with `-u origin claude/lane-counter`.

### Task 1: The two tables and their schema rows

Model: Sonnet 5.5, high.

**Files:**

- Create: `projects/felix/lanes.tsv`, `projects/felix/lane-next.tsv` (C1's exact bytes).
- Modify: `engine/harness/templates/schemas.tsv`, inserting C1's two commented rows after line 85 (the `land.tsv` row).
- Test: `engine/harness/bin/schema-check`, run from the worktree's top.

**Interfaces:** Produces the two tables every later task reads.

- [ ] Create both tables with C1's bytes.
- [ ] Run `engine/harness/bin/schema-check` from `<wt>`. Expect a non-zero exit naming `lanes.tsv` and `lane-next.tsv` as tables with no schema row.
- [ ] Insert the two `schemas.tsv` rows with their comments after line 85.
- [ ] Run `engine/harness/bin/schema-check` again. Expect exit 0.
- [ ] Commit `feat(capability): felix-home's lane tables, the capability lane at 1/2 over 14 days and its next item`. End the message with the line `Felix-Lane: capability`; this PR is the lane's first item, and one marked commit on the branch is enough. Push.

### Task 2: Blind parts

Model: Opus 5.5, xhigh. A separate author who reads the design, this plan's Contracts section, `tests/run`, `tests/parts/000*.sh`, `tests/lib/*.sh`, and the three existing parts to edit, and never `engine/harness/lib/`, `hooks/`, `bin/` or `felix`.

**Files:**

- Create: `engine/harness/tests/lib/lane-fixture.sh`, and parts `2200-lane-counts-blind.sh`, `2210-lane-states-blind.sh`, `2220-lane-command-blind.sh`, `2230-lane-status-row-blind.sh`, `2240-lane-session-start-blind.sh`, `2250-lane-pulse-blind.sh` under `engine/harness/tests/parts/`.
- Modify: `engine/harness/tests/run`, adding `. "$HERE/lib/lane-fixture.sh"` after line 144 (`lib/land-on-green.sh`) and the six part lines, in order, after line 384 (`2120-wave-1-combine-blind.sh`).
- Modify: `tests/parts/1100-declared-tools-reach-the-pulse-and-felix-status.sh:409-411` and `:427-436`; `tests/parts/1690-status-lander-row-blind.sh:184-189` and `:350-355`; `tests/parts/1720-lander-alerts-reach-github-blind.sh:366` and `:376-378`. Each becomes nine rows ending `lane`, with a comment in the shape those parts already use: "Changed by the lane counter contract (docs/2026-10-29-lane-slice-0-plan.md, C6): the lane row was added at the end, as the status header allows."

**Interfaces:** Consumes C1 to C11. Produces the failing assertions every implementation task must turn green.

- [ ] Write `tests/lib/lane-fixture.sh`: functions only, no assignment at source time, no name the suite already has (part 0006's two judges). It builds C9's two layouts and commits landings at pinned times.
- [ ] Write part 2200 (C11 row): the eight-landing fixture of §6.6 with C11's worked expectation; the four window edges, each by moving `FELIX_LANE_NOW` one second; L-RF1; merges; a rename; L-RF5. Read L and T from `felix lane --tsv` columns 3 and 4.
- [ ] Write part 2210: each state from C4 through `felix lane --tsv` column 2 and the status row; R1 to R8 with their exact sentences; L-RF3; L-NEVER-OK.
- [ ] Write part 2220: C5 whole, the last change, L-DET, L-RO, the `usage()` line, exits 0 and 2.
- [ ] Write part 2230: C6 whole, including the byte-identical first eight rows (status run with `lanes.tsv` present, then absent, in the home-apart layout).
- [ ] Write part 2240: C7 whole, L-RF2, L-RF4, the missing-library case.
- [ ] Write part 2250: C8 whole, in the self-governed layout, with `FELIX_MEMORY` outside it.
- [ ] Edit parts 1100, 1690 and 1720 as listed under **Files**.
- [ ] Name every assertion that should pass on main as well with "(control)" in its name.
- [ ] Commit `test(lane): blind assertions for the lane counter, written from the design and the plan's Contracts (red)`. Push.

### Task 3: Red on main

Model: Sonnet 5.5, high. The worktree's engine is still main's: Task 1 added only tables.

**Files:** none changed.

- [ ] Before each run, count running part runs: `pgrep -fl 'tests/run'`. Start one only while fewer than four run on the Mac.
- [ ] `engine/harness/tests/run --part 2200-lane-counts-blind.sh 2210-lane-states-blind.sh 2220-lane-command-blind.sh` from `<wt>`. Expect `FAIL` on every assertion not marked "(control)", with `felix lane` exiting 1 and printing `felix: unknown command: lane. Try 'felix help'.` on stderr.
- [ ] `engine/harness/tests/run --part 2230-lane-status-row-blind.sh 2240-lane-session-start-blind.sh 2250-lane-pulse-blind.sh`. Expect `FAIL` where status prints eight rows, no paragraph or token appears, and the pulse prints no lane line.
- [ ] Run each edited part on its own: `--part 1100-declared-tools-reach-the-pulse-and-felix-status.sh`, then `--part 1690-status-lander-row-blind.sh`, then `--part 1720-lander-alerts-reach-github-blind.sh`. Expect `FAIL` only on the nine-row assertions.
- [ ] Any assertion not marked "(control)" that passes here goes back to the blind author (Task 2), with the output.
- [ ] Commit, empty: `git commit --allow-empty -m "test(lane): red on main: <failed> failed, <passed> passed in 2200-2250; 1100, 1690 and 1720 fail on the row list"`. Push.

### Task 4: The counter and `felix lane`

Model: Sonnet 5.5, xhigh.

**Files:**

- Create: `engine/harness/lib/lane.sh`.
- Modify `engine/harness/felix`:
    - the header comment, a line after line 26: `#   felix lane [--tsv]   read-only: each lane's share of engine landings, against its target`;
    - the library list, after line 353 (`lib/pulse.sh`): `. "${SCRIPT_DIR}/lib/lane.sh"`;
    - `usage()` (lines 399-491), after line 421: C5's usage line;
    - after `cmd_status` (lines 6654-6662): `cmd_lane`;
    - the dispatch case (lines 6679-6734), after line 6684 (`status)`): `  lane)    shift; cmd_lane "$@" ;;`.

- Test: parts 2200, 2210, 2220; part 0480.

**Interfaces:**

- Consumes:
    - `felix_table_check SCHEMAS FILE [TABLE]` (`lib/table.sh:131`): exit 0 accepted, 1 refused, 2 cannot examine. `lib/lane.sh` sources `lib/table.sh` behind the house guard (`command -v felix_table_check >/dev/null 2>&1 || . "$(dirname "${BASH_SOURCE[0]:-$0}")/table.sh"`), since nothing else loads it.
    - `felix_table_rows FILE` (`lib/table.sh:102`): the data rows.
    - `_felix_git_read VAR COMMAND...` (`lib/resolve.sh:894`): 0 only when the command finished.
    - `resolve_or_die` (`felix:502`): sets `PROJ`, exits 2. `die MSG [STATUS]` (`felix:374`). `felix_repo_root DIR` (`lib/resolve.sh:333`).

- Produces:
    - `felix_lane_rows PROJ ROOT`: on stdout, C5's TSV lines for `<PROJ>`'s tables counted in `ROOT`'s repository; nothing when `lanes.tsv` is absent or has no row; returns 0. It prints nothing on stderr.
    - `felix_lane_command PROJ ROOT TSV`: TSV=1 prints `felix_lane_rows`' lines; TSV=0 prints C5's human lines; returns 0.
    - `cmd_lane [--tsv]`: parses as `cmd_status` does (`case "$#:${1:-}" in 0:) ;; 1:--tsv) tsv=1 ;; *) die "usage: felix lane [--tsv]" 2 ;; esac`), then `resolve_or_die`, `export GIT_OPTIONAL_LOCKS=0`, and `felix_lane_command "$PROJ" "$(felix_repo_root "$PWD")" "$tsv"`. It takes no flag with a value, so `need_value` has nothing to guard.

- [ ] Confirm parts 2200, 2210 and 2220 are red from Task 3.
- [ ] Write `lib/lane.sh`. The values are C1 to C5's; the body is open except for these choices, which the contract was written against:
    - validate each table with `felix_table_check "<engine>/templates/schemas.tsv" <file>`, then each row by C1's rules (R4 to R7), then the clock (R8);
    - check the ref with `git -C ROOT rev-parse --verify -q 'refs/remotes/origin/main^{commit}'` (R1) and shallowness with `git -C ROOT rev-parse --is-shallow-repository` (R3);
    - walk the first-parent chain once with `git log --first-parent` and an explicit `--format` of object name, parents and committer time (a `--format` keeps a person's `log` settings out of what is parsed), read through `_felix_git_read` (R2 on failure);
    - read changed paths with `git diff-tree -r --no-renames --name-only`, one call per landing or one `--stdin` call, only for landings the window or the last-landing search needs;
    - read marks from `%B` of the landing, and for a merge from `git log --format=%B <C>^1..<C>`; match lines in `LC_ALL=C awk` after `sub(/[ \t\r]+$/, "")`;
    - session start, status and the pulse do not use column 7; `felix_lane_rows` may skip the last-landing search behind an internal argument, as long as `felix lane` prints it.

- [ ] Add the five `felix` edits listed under **Files**.
- [ ] Run `engine/harness/tests/run --part 2200-lane-counts-blind.sh 2210-lane-states-blind.sh 2220-lane-command-blind.sh`. Expect every assertion ok, with no skip but the python3 kind.
- [ ] Run `engine/harness/tests/run --part 0480-the-one-line-git-cannot-reconstruct.sh`. Expect "help covers every command that dispatches" ok.
- [ ] Commit `feat(lane): felix lane counts each lane's share of engine landings on origin/main, offline, with its target, next item and last change`. Push.

### Task 5: The status row

Model: Sonnet 5.5, xhigh.

**Files:**

- Modify `engine/harness/lib/status.sh`:
    - the header, lines 1-15: eight rows become nine, with `lane` last in the order on line 10-11;
    - a new `_felix_status_lane PROJ ROOT` after `_felix_status_alerts` (lines 317-338);
    - `felix_status_rows` (lines 340-354): the comment says nine rows, and `_felix_status_lane "$proj" "$root"` follows line 353 (`_felix_status_alerts "$home"`).

- Test: part 2230; parts 1100, 1690, 1720 as edited.

**Interfaces:**

- Consumes: `felix_lane_rows` (Task 4); `_felix_status_row ROW STATE VALUE DETAIL` (`lib/status.sh:150`); `_felix_status_need FUNCTION LIB` (`lib/status.sh:32`), used as `_felix_status_need felix_lane_rows lane`, because `lib/status.sh` is sourced alone in suite subshells.
- Produces: `_felix_status_lane PROJ ROOT`, which prints exactly one C6 row and returns 0. An empty `PROJ` gives the "not a governed checkout" row.

- [ ] Confirm part 2230 and the three edited parts are red from Task 3.
- [ ] Write `_felix_status_lane` with C6's five cases, reading only the first line `felix_lane_rows` prints. It tells "absent" from "no row" by testing `<PROJ>/lanes.tsv` itself (`-e` or `-L`).
- [ ] Add the call and the header edits.
- [ ] Run `--part 2230-lane-status-row-blind.sh`, then each of `1100-…`, `1690-…`, `1720-…` alone. Expect all ok.
- [ ] Commit `feat(status): felix status gains a ninth row, lane, the first lane's state and its share of engine landings`. Push.

### Task 6: Session start

Model: Sonnet 5.5, xhigh.

**Files:**

- Modify `engine/harness/hooks/session-start`:
    - after line 73 (`lib/waiting.sh`): `[ -f "${SCRIPT_DIR}/../lib/lane.sh" ] && . "${SCRIPT_DIR}/../lib/lane.sh"`;
    - after line 580 (`felix_start_waits …`): `lane_line=""; _felix_lane_tok=""`, then `command -v felix_start_lane >/dev/null 2>&1 && felix_start_lane "$PROJ" "$_repo_root" 2>/dev/null`;
    - line 588: `${lane_line:-}` right after `${waits_line}`;
    - line 761: `_felix_line="${_felix_line}${_felix_wait_toks:-}${_felix_lane_tok:-}"`.

- Modify `engine/harness/lib/lane.sh`: add `felix_start_lane`.
- Test: part 2240.

**Interfaces:**

- Consumes: `felix_lane_rows`; `$PROJ` and `$_repo_root` (`hooks/session-start:244`); `escape_for_json` (`hooks/session-start:80`), which already escapes the whole context.
- Produces: `felix_start_lane PROJ ROOT`, which sets `lane_line` (C7's paragraphs, each with its leading newline) and `_felix_lane_tok` (C7's token or empty), prints nothing on stdout or stderr, and returns 0. It returns at once, with no git command, when `<PROJ>/lanes.tsv` is absent.

- [ ] Confirm part 2240 is red from Task 3.
- [ ] Write `felix_start_lane` with C7's exact text.
- [ ] Add the four hook edits.
- [ ] Run `--part 2240-lane-session-start-blind.sh`. Expect all ok.
- [ ] Run `--part 1670-session-start-names-what-waits-blind.sh` and `--part 1690-status-lander-row-blind.sh`. Expect all ok: the screen line and context of a project with no `lanes.tsv` do not change.
- [ ] Commit `feat(session-start): a short or empty lane tells an untasked session to take the lane's next item, and an empty one shows on the screen line`. Push.

### Task 7: The pulse line

Model: Sonnet 5.5, xhigh.

**Files:**

- Modify `engine/harness/felix`, `cmd_pulse` (lines 6554-6652): one line after line 6643 (`felix_pulse_report "$FELIX_HOME_DIR"`), inside the braces: `felix_lane_pulse "$FELIX_HOME_DIR"`.
- Modify `engine/harness/lib/pulse.sh`, the duties comment (lines 11-29): name the lane line as a read-only duty.
- Modify `engine/harness/lib/lane.sh`: add `felix_lane_pulse`.
- Test: part 2250; part 0470.

**Interfaces:**

- Consumes: `felix_lane_rows`; `felix_repo_root` and `felix_resolve_project` (`lib/resolve.sh:333`, `:467`), to find the home's own project the way `felix_pulse_report` does (`lib/pulse.sh:392-394`).
- Produces: `felix_lane_pulse HOME`, which prints C8's lines and returns 0.

- [ ] Confirm part 2250 is red from Task 3.
- [ ] Write `felix_lane_pulse` and the `cmd_pulse` line.
- [ ] Run `--part 2250-lane-pulse-blind.sh`, then `--part 0470-the-pulse-the-heartbeat-that-does-not-wait-f.sh`. Expect all ok.
- [ ] Commit `feat(pulse): the daily pulse records each lane's state, L and T`. Push.

### Task 8: Lints and the real-data measurements

Model: Sonnet 5.5, high.

**Files:** none in the repository. Measurements go under `${FELIX_MEMORY:-$HOME/.felix/memory}/felix/audits/<date>-lane-slice-0/`, a directory of the memory root, so no project name enters an engine file.

- [ ] Run the lint parts, at most four runs at once. `--part` takes one to six names that are contiguous in the driver's order, and refuses the prelude parts 0001 to 0009, which run with every part run anyway. So: `--part 0960-no-engine-test-reads-a-pipe-through-a-grep-t.sh`; `--part 0992-sort-comm-join-and-uniq-read-bytes-in-the-c-l.sh 0994-bash-s-own-collation-and-the-bsd-text-tools.sh 0996-continued.sh 0998-continued.sh`; `--part 1000-the-engine-makes-its-scratch-under-tmpdir.sh`; `--part 1497-lib-awk-gawk-names-blind.sh 1500-git-colour-never-reaches-what-the-engine-parses.sh 1510-no-caller-environment-changes-a-tool-s-output.sh`; `--part 1530-patch-reads-the-repository-not-a-diff-setting.sh`. Expect all ok. Run `engine/harness/bin/independence-scan` from `<wt>`; expect exit 0.
- [ ] Make the scratch clone of felix-home at `e54e31f3`:

```
S="$(mktemp -d "${TMPDIR:-/tmp}/lane-real.XXXXXX")"
git clone -q --shared --no-checkout "<wt>" "$S/r"
git -C "$S/r" update-ref refs/remotes/origin/main e54e31f35c567cd9b32c430525069e13cf1e8a6e
git -C "$S/r" checkout -q --detach e54e31f35c567cd9b32c430525069e13cf1e8a6e
```

- [ ] Red on main for the real data: `( cd "$S/r" && FELIX_HOME="<wt>" FELIX_LANE_NOW=1793309173 "$S/r/engine/harness/felix" lane --tsv )`. Expect exit 1 and `felix: unknown command: lane. Try 'felix help'.`: that engine is main's.
- [ ] Green: `( cd "$S/r" && FELIX_HOME="<wt>" FELIX_LANE_NOW=1793309173 "<wt>/engine/harness/felix" lane --tsv )`. Expect columns 1 to 9 and 12 to be `capability`, `zero`, `0`, `18`, `14`, `1/2`, `none`, `Felix-Lane: capability`, the next text of C1, and `2026-10-29T21:26:13Z`. The clone's tracked `.felix` binds it to `felix`, and `1793309173` is `e54e31f3`'s committer time. Save both outputs to the audits directory.
- [ ] The 60-day hand check, written without reading `lib/lane.sh`. Make a home copy with a one-day window: `mkdir -p "$S/h/projects" && cp -R "<wt>/projects/felix" "$S/h/projects/"`, then set the window cell of `$S/h/projects/felix/lanes.tsv` to `1`. For k from 0 to 59, let e = 1793309173 − k·86400:
    - the counter: `( cd "$S/r" && FELIX_HOME="$S/h" FELIX_LANE_NOW=<e> "<wt>/engine/harness/felix" lane --tsv )`, column 4;
    - the independent count: the commits of `git -C "$S/r" log --first-parent --format='%H %ct' e54e31f3` with e − 86400 ≤ time ≤ e, each kept when `git -C "$S/r" diff-tree --no-commit-id -r --no-renames --name-only <C>^1 <C>` prints a path starting `engine/`.

    Expect all 60 days to agree; save the table to the audits directory. A day that disagrees falsifies the counter (design §6.6) and goes to the review as a finding.

- [ ] Measure CPU, not wall: `/usr/bin/time -p` user plus sys for `felix lane --tsv` in `$S/r`, three runs, the median; and for the session-start hook in `$S/r` with and without `lanes.tsv` in the home copy. Save the numbers; they go in the PR body.
- [ ] Remove `$S`. It is a scratch clone, never a home or a memory root.

### Task 9: Adversarial review and fixes

Review: Opus 5.5, xhigh. Fixes: Sonnet 5.5, xhigh.

**Files:** whatever the findings touch, never a blind part.

- [ ] The reviewer reads the diff against `origin/main`, the design, the Contracts and the Review Focus, and re-runs each Review Focus case by hand in a scratch fixture.
- [ ] The reviewer also probes:
    - a fork that fails (`ulimit -u` low, as part 1670 does) during the walk: the lane must read `unknown`, never `idle` or `ok`;
    - a UTF-8 caller locale (`LANG=en_US.UTF-8`) with a non-UTF-8 byte in a commit message;
    - `refs/remotes/origin/main` pointing at an annotated tag object;
    - a partial (blobless or treeless) clone: the counter must not fetch;
    - `GIT_DIR` or `GIT_WORK_TREE` exported by the caller;
    - the lane exclusions: no edit to the files the Global Constraints name, and no call into `lib/notify.sh`.

- [ ] Each finding goes to a fix by the implementer, or, when it shows a blind part asserting something the Contracts do not say, back to the blind author with the evidence.
- [ ] Re-run every part a fix touches, and the lints of Task 8 when `lib/` changed. Expect all ok.
- [ ] Commit each fix as `fix(lane): <what the review found>`. Push.

### Task 10: Version, record, gate and PR

Model: Sonnet 5.5, high.

**Files:**

- Modify: `engine/.claude-plugin/plugin.json`, `"version"`.
- Create: this branch's handoff section, through `felix handoff --section <file>`.
- Modify (written by the record): `engine/harness/tests/assertions.tsv`, `engine/harness/tests/red.tsv`.

- [ ] Ask the queue owner (today the "Inventory next steps" session) whether a record or gate holds the queue. Wait while one does.
- [ ] Take the next free patch slot: above 0.49.313, and above every version in `origin/main`'s `plugin.json` and in open PR titles. Set it in `plugin.json`.
- [ ] Write the handoff section: what landed, the C12 decisions, the measurements, and that slice 1 moves `lanes.tsv` to `1/4` and `lane-next.tsv` on to slice 2. Add it with `felix handoff --section <file>`.
- [ ] Commit `chore(release): the lane counter takes 0.49.<n>`. Commit everything before the record.
- [ ] Keep the Mac awake. Start the record in the background and poll its log, since a background shell dies at ten minutes: `nohup engine/harness/tests/run --record-assertions > <log> 2>&1 &`. Expect `0 failed`, `recorded <n> assertions`, and red written against `origin/main` naming the new and edited parts' assertions.
- [ ] Commit `test(suite): record at 0.49.<n>: <p> passed, 0 failed, <s> skipped; red against origin/main <sha> names <k>`. Red ran in its own worktree under a temporary directory; the gate runs here, after this commit.
- [ ] `nohup engine/harness/felix gate > <log> 2>&1 &`, polled. Expect a green gate whose header names `<wt>`.
- [ ] Push. Open the PR with `felix pr --create`. The title carries the version, for example `feat(lane): felix lane counts the capability lane's share of engine landings, with a status row, a session-start paragraph and a pulse line (slice 0, 0.49.<n>)`. The body gives the red counts, the record line, the real-data line, the hand-check result, the CPU numbers and C12. It is not a draft and carries no hold label, so land on green can take it. No attribution trailer.
- [ ] Turn on the CI monitor for the PR.

## Coverage

Every requirement of §6, and §9's slice-0 list, maps to a task and a part.

| Spec | Where |
|---|---|
| §6.1 the one question, the next item, the empty lane on the screen line | C5, C7; Tasks 4 and 6 |
| §6.2 landings, counted, marked, total | C3; Task 4; part 2200 |
| §6.3 the two tables, schema rows, felix-home rows, who changes what | C1; Task 1; parts 2210, 2220 |
| §6.4 states | C4; Task 4; part 2210 |
| §6.5.1 `felix lane [--tsv]` and its fields | C5; Task 4; part 2220 |
| §6.5.2 the status row | C6; Task 5; part 2230, parts 1100, 1690, 1720 |
| §6.5.3 the session-start paragraph | C7; Task 6; part 2240 |
| §6.5.4 the screen token | C7; Task 6; part 2240 |
| §6.5.5 the pulse line | C8; Task 7; part 2250 |
| §6.5.6 no push alert | Global Constraints; Task 9's exclusions probe |
| §6.6 the counts, at each edge | part 2200 |
| §6.6 the state edges | part 2210 |
| §6.6 what shows where | part 2240 |
| §6.6 `felix status --tsv` one row, eight identical | part 2230 |
| §6.6 the last change | part 2220 |
| §6.6 determinism | L-DET in parts 2220, 2230 |
| §6.6 real data at `e54e31f3` | Task 8 |
| §6.6 falsified if, 60 days | Task 8 |
| §4 constraints | Global Constraints; Task 8's lints; Task 9 |
| §9 slice 0's contents | Tasks 1 and 4 to 7 |
| §10 left to the builder | C12 |
