# Lane Counter (Slice 0) Implementation Plan

> **For agentic workers:** run this plan as the founder's engine-build Workflow: spec, blind assertions, red first, implementation, adversarial review, gate. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** Count each lane's share of the engine landings on a project's `origin/main`, offline. Put a short or empty lane in front of the next session that has no task, and an empty one on the founder's screen line.

**Architecture:** One new library, `engine/harness/lib/lane.sh`, reads two per-project tables as the Felix home has them committed, and walks the first-parent history of `refs/remotes/origin/main` in the checkout, writing nothing. One function, `felix_lane_rows`, gives every surface its lines: `felix lane [--tsv]`, a new last `felix status` row, a session-start paragraph and screen token, and one pulse line per lane. felix-home gets its two tables and two `schemas.tsv` rows in the same PR.

**Tech stack:** Bash 3.2 and git; awk that BWK awk and gawk both run; the suite's `tests/run` parts.

**Spec:** `docs/2026-10-29-capability-lane-first-slices-design.md`, §6 (slice 0), read with §1 to §5 and §9 to §12, as corrected after the fact-check; and this plan's Contracts section. Code was read on 2026-10-29 at `e54e31f3` (engine 0.49.309). `origin/main` has since moved to `01e24cfc` (0.49.313, #475), which added a ninth status row, `icloud`, after `alerts`. Task 0 re-reads every line number below on `origin/main`; the anchors named beside them stand.

## Global Constraints

- Bash 3.2 and git only: no jq, no python.
- Only awk that both BWK awk (local) and gawk (CI) run. Part 1497's `_awk_names` lints `lib/`.
- `LC_ALL=C` on every sort, comm, join and uniq (part 0992).
- `[[ =~ ]]` only inside a function that declares `local LC_ALL=C` (part 0996).
- Flags go through `need_value` (`felix:389-391`), never a bare `shift 2`.
- The engine names no project (constitution invariant 1). Everything project-specific lives in a `projects/<p>/` table or arrives as an argument. No lane name is a literal in engine code either.
- Offline (invariant 2) and deterministic (the intent design's §9 (d) and falsifier 2): two runs with the network off and no key print identical bytes. The counter never fetches.
- A check that cannot fail is not a check (invariant 5): every new check is shown failing first.
- Never delete a home or a memory root (invariant 6).
- Records go under the memory root or under `state/`. Nothing is written into a governed repository: its refs, index, config and worktree list stay as they were.
- The lane never touches `lib/qualify.sh`, `lib/obligations.sh`, `lib/receipt.sh`, `lib/automerge.sh`, `lib/green-*.sh`, `lib/land-table.sh`, `lib/notify.sh`, `lib/own.sh`, `lib/status-land.sh`, or the `felix merge` and `felix land` code paths.
- Each new table is a new file with one new `schemas.tsv` row. No column is added to an existing table.
- No force: nothing here blocks a merge, holds a release, comments on a pull request or writes an enforcing table. No push alert.
- No model, key or network on any path.
- `unknown` is never printed or counted as `ok`.
- One engine PR for this slice. No new engine branch while more than 10 engine PRs are open; the builder checks `gh pr list` first.
- The PR bumps the patch version in `engine/.claude-plugin/plugin.json` and puts it in its title. It takes the next free patch slot at landing time (design §4); on 10-29, 0.49.310 to 0.49.314 were claimed.
- Every new `felix` command appears in `usage()`. `felix lane` dispatches in the main dispatch block, which part 0480 checks (design §4, §11 item 21).
- Suite manners: commit everything before the record; red and gate never share a worktree; no whole-suite run while another session's record or gate holds the queue; at most four part runs at once, across the Mac. Count part runs by process group, not by process, since every subshell of a run keeps its command line: `ps -Ao pgid=,command= | LC_ALL=C awk '/tests\/run --part/ { print $1 }' | LC_ALL=C sort -u | wc -l`, or use a Mac-wide four-slot helper when the session has one. Start a run only while the count is under four.
- Files stay under 500 lines, `lib/lane.sh` included. A part stays under the 1,000 lines part 1040 allows.
- `tests/run` stays at or under 500 lines (part 1040). It had 475 at `origin/main` `01e24cfc`; this slice adds 7, and slices 1 and 2 add 15 more. Task 0 checks `origin/main`'s count plus the part and lib lines every open engine PR adds, and stops if this slice's 7 would pass 500.

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

**The shape check.** Each table is read only when the engine's table validator (`lib/table.sh`, `felix_table_check`) accepts it against `engine/harness/templates/schemas.tsv`, the same check `bin/schema-check` runs on every gate. It refuses, among others: a CR byte anywhere; a last byte that is not a newline; a NUL; a leading, trailing or doubled tab; a row with the wrong number of cells; whitespace before `#`; a line of only whitespace; a line that is not UTF-8; a line starting with a non-ASCII byte; a symlink. Comment lines start with `#` in column 1, and blank lines are skipped.

- A `lanes.tsv` the check refuses reads `unknown` on every surface (reason R4 in C5).
- A `lane-next.tsv` the check refuses makes every lane's next read `unknown`.
- Absent (C2), or present with no row, `lanes.tsv` means the project counts no lane.

**felix-home's files.** `projects/felix/lanes.tsv`, exactly these bytes (TAB between cells, a newline after every line):

```
# The lanes this project counts (lib/lane.sh), from docs/2026-10-29-capability-lane-first-slices-design.md §6.3.
# lane, counts (an ERE over changed paths), share (n/d), window (days). Read as committed, never from the
# working tree. A change here lands on green; felix lane names the commit that last changed a lane's row.
capability	^engine/	1/2	14
```

`projects/felix/lane-next.tsv`, exactly these bytes:

```
# Each lane's first open item, on one line (lib/lane.sh, design §6.3). Read as committed. The pull
# request that lands a lane item moves its row in the same change.
capability	obligation intake, slice 1: felix situations --change (branch claude/lane-situations-owed)
```

Slice 1's PR will change `1/2` to `1/4` in the first file and move the second's row on to slice 2, marked "pending the direction fold" (design §9); both edits keep these shapes.

**`schemas.tsv` rows.** Inserted after the `land.tsv` row (`engine/harness/templates/schemas.tsv:85`). Columns are tab-separated, and the column list is space-separated inside its cell, as every row there is:

```
# The lanes a project counts (lib/lane.sh). Read only as committed at HEAD of
# the repository holding projects/<name>/, never the working tree. Absent there,
# or with no row, the project counts no lane: felix lane prints nothing, the lane
# row of felix status reads none, and session start and the pulse say nothing.
# Refused by this check, every lane reads unknown. A change to it lands on green.
lanes.tsv	tree	lane counts share window	allowed
# Each lane's first open item (lib/lane.sh), read as committed, like lanes.tsv.
# Absent, or with no row for a lane, that lane's next reads none; refused by this
# check, every next reads unknown. It never changes a lane's state.
lane-next.tsv	tree	lane next	allowed
```

Neither name joins `FELIX_ESCAPE_TABLES`: a change to either lands on green (design §5 item 5). Adding a `schemas.tsv` row is free at the merge boundary.

### C2. What is read, and from where

- **The project** is the one Felix binds the directory to: the `.felix` marker first, then a `project.json` `remote_match`.
    - `felix lane` and `felix status`: the current directory.
    - Session start: the session's directory.
    - The pulse: only the project the Felix home's own checkout is bound to. A home that is not a git checkout, or binds no project, gets no lane line. No other project's lane is counted by the pulse, because no project records where its checkout is.

- **The tables** are `lanes.tsv` and `lane-next.tsv` as the Felix home has them committed: the files at `HEAD` of the git repository that holds `<PROJ>`, never the working tree (design §6.3, §11 item 19). In a home git can read, an uncommitted edit, a touched file or a deleted working file changes nothing any surface prints.
    - `HEAD` holds no such file: the table is absent. An entry there that is not a regular file (a symlink or a submodule) is refused (R4 for `lanes.tsv`), as the shape check refuses a symlink.
    - `<PROJ>` is in no git repository, or its `HEAD` names no commit, or a git read of it does not finish: when a file or link `<PROJ>/lanes.tsv` exists, every lane reads `unknown` with R9; when none exists, the table is absent. `lane-next.tsv` in the same case: every next reads `unknown` when the file exists, `none` when it does not.

- **The repository** is the git repository holding the current directory: the checkout or worktree it stands in. For the pulse, it is the home checkout.
- **The ref** is `refs/remotes/origin/main` in that repository, by its full name. It is never fetched. There is no fallback to a local `main`, to another remote or to another branch name. A worktree reads the refs it shares with its main checkout.
- **For felix-home**, every surface run in the home checkout or any worktree of it counts that repository's `origin/main` as last fetched, with the tables from the Felix home's `HEAD`.
- **The last change** (C5 columns 10 and 11) is read from the first-parent history of the repository that holds `<PROJ>`, from its `HEAD`.
- **Nothing is written.** No surface changes a ref, the index, config, the worktree list or any file of the repository or the home. `felix lane` exports `GIT_OPTIONAL_LOCKS=0`, as `felix status` already does. Scratch files go under `${TMPDIR:-/tmp}` and are removed. The pulse writes only what it writes today (`state/pulse.log`, `state/pulse.status.tsv`).

### C3. What counts

Design §6.2, as the engine applies it.

- **A landing** is a commit on the first-parent chain of `refs/remotes/origin/main`. Its time is its committer time.
- **The clock.** `now` is `FELIX_LANE_NOW` when that is set and not empty, else the machine clock (C9).
- **The window** of a lane with window W is the half-open interval (now − W·86400, now], in seconds, by committer time (design §11 item 17). A landing exactly W·86400 seconds before now is outside it; one a second later is inside; one at now is inside; one after now is in no window. The whole first-parent chain is walked: the walk does not stop at the first landing older than the window, so an out-of-order date cannot hide a later landing.
- **Changed paths.** A landing's changed paths are those between it and its first parent, with rename detection off, so a move lists both paths. They are the names `git diff-tree -r -z --no-renames --name-only <C>^1 <C>` prints, as bytes and unquoted, whatever `core.quotePath` or `log.showSignature` the caller set. A real merge is compared with its first parent only. A commit with no parent, in a repository that is not shallow, changed every path in its tree.
- **Counted.** A landing is counted for a lane when at least one changed path matches the lane's `counts` ERE, as `LC_ALL=C grep -E` matches. A landing that changes no matching path is not counted, whatever its message says, and a sealed number counts nowhere (design §11 item 3).
- **Marked.** A landing is marked for a lane when some commit in `<C>^1..<C>` has a message line that, after its trailing spaces, tabs and CRs are removed, is byte for byte `Felix-Lane: <lane>`. For a single-parent landing that set is the landing alone. For a real merge it is the merge and every commit it brought in. For a commit with no parent it is that commit.
    - Not marked: a line with leading whitespace, another case (`felix-lane: <lane>`), no space after the colon, two spaces, more text after the lane name, or the words inside a sentence.
    - How a squash was made does not matter to the rule, only what its message holds. `felix merge` writes each non-merge commit of the branch as `* <subject>`, a blank line, then its body at column 0, with runs of blank lines collapsed, and copies no merge commit's message (`felix:2088-2089`). GitHub's default squash message has the same shape after its title line. So a mark that is a body line of a non-merge commit on the branch survives. A mark that is a commit's subject (it lands as `* Felix-Lane: <lane>`), or that sits only in a merge commit on the branch, does not.
    - A hand merge that replaces the message drops the mark, and that landing counts as non-lane. This is the design's stated limit; the error runs toward `short` (§6.2, §11 item 2).

- **L** is the number of landings in the window that are counted and marked. **T** is the number counted, marked or not. L ≤ T always.
- **The last lane landing** is the latest committer time, at or before `now`, among landings that are counted and marked, at any age on the whole first-parent chain. It prints as a date, or `none` when there is none. Its search never changes a lane's state: when a read only this search needs does not finish, C5 column 7 reads `unknown` and every other column stands, so `felix lane` column 2, the status row, the paragraph and the pulse line always agree.
- **A shallow repository** (`git rev-parse --is-shallow-repository` prints `true`) cannot be counted: every lane reads `unknown`, reason R3.
- **Any git read that does not finish** (a missing object, a corrupt repository, a fork that fails, an object a partial clone would have to fetch) makes the lane `unknown`, reason R2. A read that did not finish never yields a count.

### C4. States

For each lane row, with L and T from C3 and its share n/d, decided in this order:

| State | When |
|---|---|
| `unknown` | any reason of C5 applies |
| `idle` | T = 0 |
| `zero` | L = 0 (and T > 0) |
| `ok` | L·d ≥ n·T |
| `short` | otherwise (L > 0 and L·d < n·T) |

This is the design's table (§6.4). Because n ≥ 1, the rows never overlap. The edges, with share `1/2`: L = 2 and T = 4 reads `ok`; L = 1 and T = 4 reads `short`; L = 1 and T = 2 reads `ok`; L = 0 and T = 2 reads `zero` (design §6.6).

### C5. `felix lane`

```
felix lane [--tsv]
```

- **Read-only and offline.** It writes nothing (C2) and takes no network.
- **Arguments.** None, or exactly `--tsv`. Anything else (`--json`, `--tsv --tsv`, `x`) is a usage error: nothing on stdout, `felix: usage: felix lane [--tsv]` on stderr, exit 2. `felix lane --help` prints the general usage and exits 0.
- **Not governed.** In a directory no project governs, it exits 2 with Felix's usual "no project governs" message on stderr and nothing on stdout.
- **No lane.** When `lanes.tsv` is absent (C2), or present with no row, it prints nothing and exits 0.
- **Otherwise** it prints one line per data row of `lanes.tsv`, in file order, and exits 0, whatever the states. When `lanes.tsv` gives R9 or R4, it prints exactly one line, whose lane is `-`.
- **`usage()`** gains, in its "every day" block right after the `felix status` line: `    felix lane [--tsv]     read-only: each lane's share of engine landings on origin/main, against its target` (four spaces, the command, five spaces, the text, so the text starts where `felix which`'s does).

**`--tsv`**: no header; thirteen tab-separated columns per line.

| # | Column | Value |
|---|---|---|
| 1 | lane | the lane name; `-` when the row's first cell is not a valid lane name, or on an R9 or R4 line |
| 2 | state | `ok`, `short`, `zero`, `idle` or `unknown` |
| 3 | L | a whole number; `-` when unknown |
| 4 | T | a whole number; `-` when unknown |
| 5 | window | W from the row; `-` on an R9, R4, R5, R6 or R7 line |
| 6 | share | `n/d` from the row; `-` on an R9, R4, R5, R6 or R7 line |
| 7 | last | the last lane landing's date, or `none`; `unknown` when its search could not finish (C3); `-` when the state is unknown |
| 8 | mark | `Felix-Lane: <lane>`; `-` on an R9, R4, R5, R6 or R7 line |
| 9 | next | the lane's next text, unchanged, `none` or `unknown`; `-` on an R9, R4, R5, R6 or R7 line |
| 10 | changed | the full object name of the newest commit on the first-parent chain from the home's `HEAD` whose `lanes.tsv` holds other lines for this lane than its first parent's does (the lines whose first cell is the lane, compared as bytes and in order; a parent without the file holds none; a commit with no parent changed every line it holds); `unknown` when git could not finish that search or the home's repository is shallow; `-` when column 1 is `-` |
| 11 | changed_date | that commit's committer date; `-` unless column 10 is a commit |
| 12 | ref_date | the committer date of the commit `refs/remotes/origin/main` names; `-` when the ref cannot be read |
| 13 | detail | `-`, unless the state is `unknown`; then the reason below |

Columns 10, 11 and 12 are filled on every line, including `unknown` ones. A commit that changes only a comment line of `lanes.tsv`, or another lane's row, does not move a lane's column 10. Column 12 is the ref commit's own date, not the fetch time, so two runs print the same bytes.

**Reasons**, exact text, in the order they are tried. R9 and R4 are about the table and give the single `-` line; the others are per row.

| | Reason (column 13, and the status row's detail) |
|---|---|
| R9 | `<PROJ>/lanes.tsv cannot be read as committed in the Felix home` |
| R4 | `<PROJ>/lanes.tsv cannot be read as lanes.tsv` |
| R5 | `row <k> of lanes.tsv is not a lane name, an ERE, a share n/d and a window in days` (k counts data rows from 1) |
| R6 | `lane <lane> is named on more than one row of lanes.tsv` |
| R7 | `the counts pattern of lane <lane> is not an ERE grep accepts` |
| R8 | `FELIX_LANE_NOW is not a whole number of seconds` |
| R1 | `refs/remotes/origin/main cannot be read in <repo>` |
| R3 | `<repo> is a shallow clone, so its landings cannot all be read` |
| R2 | `git could not read the landings on refs/remotes/origin/main in <repo>` |

Which row reason applies: R5 when the row's lane, share or window cell breaks C1's rule for that cell, whatever its counts cell holds; otherwise R6 when its lane cell is also the lane cell of another data row; otherwise R7 when `LC_ALL=C grep -E` refuses its counts cell. So counts `(` in a row whose other cells are valid and whose lane is named once gives R7, never R5. A row that hits R5 or R6 still prints its first cell in column 1 when that cell is a valid lane name.

**Human form** (no flag): one line per TSV line, built from it.

- A known state:

```
<lane>: <state>, <L> of <T> engine landings in <W> days, target <n>/<d>; last lane landing <last>; mark Felix-Lane: <lane>; next: <next>; <changed>; refs/remotes/origin/main at <ref_date>
```

- An unknown state:

```
<lane>: unknown, <reason>; <changed>; refs/remotes/origin/main at <ref_date>
```

- `<changed>` is `its lanes.tsv row last changed by <first 12 characters of column 10> at <changed_date>` when column 10 is a commit, and `its lanes.tsv row's last change cannot be read` when it is `unknown`. When column 10 is `-`, the `; <changed>` part is left out.
- `<last>`, `<next>` and `<ref_date>` are columns 7, 9 and 12 as printed there.

Example, felix-home at `e54e31f3` with the clock at that commit (design §6.6):

```
capability: zero, 0 of 18 engine landings in 14 days, target 1/2; last lane landing none; mark Felix-Lane: capability; next: obligation intake, slice 1: felix situations --change (branch claude/lane-situations-owed); its lanes.tsv row last changed by <sha12> at <date>; refs/remotes/origin/main at 2026-10-29T21:26:13Z
```

### C6. `felix status`: the lane row

- `felix status --tsv` prints one row more than `origin/main` prints: ten rows at `01e24cfc`, `settings schedule pulse reach gate land hooks alerts icloud lane`. Every row before the lane row is byte-identical to what it prints without the lane row's input (for example, with no `lanes.tsv` committed). The lane row is last. The design's "eight existing rows" (§6.5 item 2, §6.6) predates `icloud`; read it as "the existing rows".
- The row keeps the status shape: `lane<TAB><state><TAB><value><TAB><detail>`. state is `value`, `none` or `unknown`; value is `-` unless state is `value`; detail is one line, never empty.
- The row speaks for the **first data row** of `lanes.tsv` (or the single R9 or R4 line).

| Case | Row |
|---|---|
| no project governs the directory | `lane<TAB>none<TAB>-<TAB>this directory is not a governed checkout` |
| `lanes.tsv` absent (C2), or present with no row | `lane<TAB>none<TAB>-<TAB><PROJ>/lanes.tsv has no committed row, so no lane is counted` |
| first lane `ok`, `short`, `zero` or `idle` | `lane<TAB>value<TAB><state><TAB><L> of <T> engine landings in <W> days, target <n>/<d>` |
| first lane `unknown` | `lane<TAB>unknown<TAB>-<TAB><the C5 reason>` |

- So an unreadable ref gives `lane<TAB>unknown<TAB>-<TAB>refs/remotes/origin/main cannot be read in <repo>`: the form an unreadable status row already has (design §6.5 item 2, §11 item 18), never a calm value.
- Plain `felix status` aligns it as it aligns every row: `printf '%-9s %-12s %s\n'` of row, value (the state word when state is not `value`) and detail.
- `felix status` stays read-only, offline, and exit 0 for any report.

### C7. Session start

- **The paragraph.** For each data row of `lanes.tsv` whose state is `short`, `zero` or `idle`, in file order, the session's context (`hookSpecificOutput.additionalContext`) gains this paragraph, a newline before it:

```
Lane <lane> is <state>: <L> of <T> engine landings in <W> days, target <n>/<d>.
If the founder has not given this session a task, take the first open lane item: <next>. End the body of a commit on its branch that is not a merge with the line `Felix-Lane: <lane>`. <closing>
```

- `<closing>` is `Trust work takes the other half.` when 2·n = d, and `The rest goes to trust work.` otherwise (design §6.5 item 3, §11 item 20). The backticks around the mark are literal.
- `<next>` is the next text; `(lane-next.tsv names none)` when it reads `none`; `(lane-next.tsv cannot be read)` when it reads `unknown`. Before the next text enters the paragraph, every byte 0x01 to 0x08, 0x0B to 0x1F and 0x7F in it is replaced by `?`, as `lib/waiting.sh` cleans the waits text; every other byte is kept. `felix lane --tsv` column 9 prints the cell unchanged.
- **Where.** The paragraphs sit right after the "what waits" paragraphs and before the capability-drift ones, in the block that follows `Memory: <dir>/`.
- **The screen token.** When the first data row's state is `zero` or `idle`, the screen line (`systemMessage`) ends with ` · lane: 0 in <W> days` (a space, a middle dot U+00B7, a space). It is the last token on the line. No other state adds a token: `short` stays in the context only.
- **Silence.** Neither the paragraph nor the token appears for `ok` or `unknown`, for a project with no committed `lanes.tsv` or none with a row, on a `resume` start (the hook exits before either is built), or in a directory no project governs.
- **Robust.** The hook exits 0 and prints valid JSON whatever the tables hold, whatever `next` contains, and when `lib/lane.sh` is missing from the engine (then no lane text appears).

### C8. The pulse

- Each `felix pulse` run (no flag) prints, appends to `<home>/state/pulse.log` and writes into `<home>/state/pulse.status.tsv` one line per data row of the home project's `lanes.tsv`, in file order:

```
lane<TAB><lane><TAB><state><TAB><L><TAB><T>
```

- L and T are `-` when the state is `unknown`. A `lanes.tsv` that gives R9 or R4 gives one line, `lane<TAB>-<TAB>unknown<TAB>-<TAB>-`.
- The lane lines are the last lines of the run: after the backup, settings, report and reach lines.
- No lane line when the home project has no committed `lanes.tsv`, or it has no row, or the home is not a git checkout bound to a project (C2).
- The pulse still exits 0, and writes nothing it did not write before.

### C9. The clock, and how a fixture points the engine at a repository

- **The clock.** `FELIX_LANE_NOW`, when set and not empty, is the instant taken as now: whole seconds since 1970-01-01T00:00:00Z, matching `^(0|[123456789][0123456789]{0,11})$`. Anything else, a leading zero included, reads `unknown` on every lane (R8). Unset or empty, now is `date -u +%s`. Every surface honours it: `felix lane`, `felix status`, session start and `felix pulse`.
- **Commit times.** A fixture pins each commit's committer time with `GIT_COMMITTER_DATE="<epoch> +0000"` (and `GIT_AUTHOR_DATE` the same). To keep trailing spaces or a CR in a message, commit with `git commit --cleanup=verbatim -F <file>`; git's default cleanup strips them.
- **The ref.** A fixture makes `refs/remotes/origin/main` with `git update-ref refs/remotes/origin/main <commit>`. No remote needs to exist. A repository without that ref reads R1.
- **Binding.** A checkout is bound to a fixture project by a `.felix` file holding the project's name, with `FELIX_HOME` naming a fixture home that holds `projects/<p>/project.json` (for example `{"name":"<p>","gate":"true"}`) and `projects/<p>/CLAUDE.md`. Build fixtures under physical paths (`pwd -P`), because reasons and details print physical paths.
- **Tables are committed.** Every surface reads the tables from the home's `HEAD` (C2). A fixture commits each table state it tests in the home's repository, a broken one (L-RF3) included; an edit left in the working tree is the "uncommitted" case, and changes nothing.
- **Two layouts.**
    - *Home apart:* a home H (a git repository holding the tables) and a checkout C bound by `.felix`. Status and session start are best tested here: committing H's tables does not change C's history.
    - *Self-governed:* one repository that is both the home and the checkout, with `.felix` at its top, as felix-home is. The pulse needs this layout (C2).

- **Memory.** `FELIX_MEMORY` must name a directory outside every fixture repository. A memory root inside a repository the home owns makes `felix pulse` commit and push there.
- **The engine under test** is the suite's copy: `$FELIX` for the CLI, `$FROOT/harness/hooks/session-start` with `CLAUDE_PLUGIN_ROOT="$FROOT"` for the hook, a startup payload `{"session_id":"…","source":"startup","cwd":"<C>"}` on stdin, run from C. Stub `claude`, `gh` and `graphify` first on PATH, as part 1670 does. Read `systemMessage` and `hookSpecificOutput.additionalContext` with python3 on the test side, skipping with a reason when python3 is absent.
- **Suite helpers.** `ok`, `bad`, `is`, `has` and `skip` from `tests/run`; `_fx_cd` for every fixture git command (part 0002); `$TMP`, `$FROOT`, `$FELIX`. A part opens with `# >>> <marker>` and closes with `# <<< <marker>`. A `tests/lib` file defines functions and nothing else (part 0006). A `[[ =~ ]]` in a part runs in a subshell (part 1690's `_lnd_like` says why).

### C10. Assertions the blind parts must carry

Beyond the design's §6.6 bullets, these are required. The names are the IDs the review and the PR cite.

- **L-RF1, the mark as people write it.** A lane landing whose mark line ends in spaces, a tab or a CR counts in L. One whose mark line has leading whitespace, reads `felix-lane: <lane>`, has no space after the colon, or has text after the lane name does not count in L, and still counts in T when it changed a counted path.
- **L-RF2, next is free text.** With `next` holding a double quote, a backslash and a non-ASCII character (for example `fix "a\b" — now`), and the lane `zero`: session start exits 0, its output parses as JSON, the context holds the next text byte for byte, and `felix lane --tsv` prints it unchanged in column 9. With `next` holding an ESC (0x1B) and a form feed (0x0C), the output still parses and the context holds `?` in their places.
- **L-RF3, a table broken by hand.** Each of these, committed, reads `unknown` in `felix lane --tsv` column 2 with the C5 reason, makes the status row `lane unknown -` when it is the first row, and leaves session start exiting 0 with valid JSON and neither paragraph nor token: share `1/0`, `3/2`, `0/2`, `1/2/3`; window `0`, `14d`, `014`; counts `(`; a lane named twice; a CR in a row; no final newline; an empty cell; a row of three cells. So does `FELIX_LANE_NOW=0123` with a valid table (R8).
- **L-RF4, a broken pointer never silences a stall.** With the lane `zero`: no committed `lane-next.tsv` gives next `none`, the paragraph with `(lane-next.tsv names none)`, and the token; `lane-next.tsv` refused (a CR in it) gives next `unknown` and `(lane-next.tsv cannot be read)`; two rows for the lane give `unknown`. The state stays `zero` in all three.
- **L-RF5, a shallow clone.** A `git clone --depth 2 file://<repo>` of a fixture, whose `refs/remotes/origin/main` the clone holds, reads `unknown` with R3 in `felix lane`, the status row, and session start (no paragraph, no token). It never reads a count.
- **L-NEVER-OK.** In every `unknown` case any part provokes, no surface prints `ok`: not `felix lane` column 2, not the status row's value.
- **L-DET.** Two runs of `felix lane`, `felix lane --tsv` and `felix status --tsv`, same fixture and same `FELIX_LANE_NOW`, print identical bytes.
- **L-RO.** `felix lane` and `felix status` leave nothing newer under the home, the memory root or the checkout (`.git` included) than a marker touched before the run, and `git for-each-ref` and `git worktree list` in the checkout print the same before and after. This holds after `touch <PROJ>/lanes.tsv` with its content unchanged, and after an uncommitted edit to it. After a session start in the home-apart layout with `<PROJ>/lanes.tsv` touched, the home's `.git/index` is no newer than the marker.

### C11. Blind parts

| File | Covers |
|---|---|
| `engine/harness/tests/lib/lane-fixture.sh` | Builders only, for the parts below: a home with committed tables, a checkout, a landing at a pinned time with a given message and paths, a squash message in `felix merge`'s shape (C3), a real merge, publishing `origin/main`. |
| `tests/parts/2200-lane-counts-blind.sh` | §6.2 and §6.6 "The counts": the worked expectation below, with L and T exact at the clock and a second before it; L-RF1; a real merge read through its merged commits; a merge whose marked commits change no counted path; a rename out of a counted path; L-RF5. |
| `tests/parts/2210-lane-states-blind.sh` | §6.4 and §6.6 "The state edges": C4's four edges, `idle`, an unreadable ref `unknown`; R1 to R9 (R9: a home that is not a git repository and holds `lanes.tsv`); L-RF3; L-NEVER-OK. |
| `tests/parts/2220-lane-command-blind.sh` | §6.5 item 1 and §6.6 "The last change" and "Determinism": usage line and exits; the thirteen columns and the human line; last lane landing, and column 7 `unknown` with the state unchanged when a tree only that search reads is missing; next `none`/`unknown`; after a commit that changes a lane's row, `felix lane` names that commit and its date; a later commit that changes only a comment line or another lane's row does not move it; an uncommitted edit to `lanes.tsv` changes nothing it prints; L-DET; L-RO; no committed `lanes.tsv` prints nothing. |
| `tests/parts/2230-lane-status-row-blind.sh` | §6.5 item 2 and §6.6 `felix status --tsv`: exactly one row more, at the end, every row before it byte-identical; every C6 case, an unreadable ref giving state `unknown` and value `-`; the status shape; L-DET and L-RO for status. |
| `tests/parts/2240-lane-session-start-blind.sh` | §6.5 items 3 and 4 and §6.6 "What shows where": paragraph only for `short`, `zero` and `idle`, token only for `zero` and `idle`, neither without a committed `lanes.tsv`; exact paragraph text with share `1/2` and with `1/4`; a resume; L-RF2; L-RF4; the session-start half of L-RO; the hook with `lib/lane.sh` removed from a harness copy still exits 0 with valid JSON. |
| `tests/parts/2250-lane-pulse-blind.sh` | §6.5 item 5: the pulse lines, in the log and in the record, last; `unknown` with `-`; no line without a committed `lanes.tsv`; no line for a project other than the home's. |
| edits to parts 1100, 1690 and 1720 | Their nine-row assertions (`... hooks alerts icloud`) become ten, `lane` last (C6). |

The design's two real-data bullets (§6.6 "Real data" and "Falsified if") are measurements on felix-home, not suite parts: a suite part may not depend on one project's history. They run in Task 8.

A worked expectation for "The counts", with `counts` `^engine/`, lane `capability`, window 14 and the clock at NOW. Landings (a) to (h) sit well inside the window:

- (a) a marked engine change in a `felix merge` squash, the mark a body line of a branch commit;
- (b) a marked engine change in a GitHub default squash, the same;
- (c) a marked docs-only change;
- (d) an unmarked engine change;
- (e) an unmarked docs-only change;
- (f) a real merge whose merged commits carry the mark and change `engine/`;
- (g) an engine change in a `felix merge` squash of a branch whose only mark was on a merge commit, so the landing carries none;
- (h) an engine change whose message mentions `Felix-Lane: capability` inside a sentence;
- (i) a marked engine change at NOW − 14·86400, (j) one at NOW − 14·86400 + 1, and (k) one at NOW.

At `FELIX_LANE_NOW` = NOW, L = 5 (a, b, f, j, k) and T = 8 (a, b, d, f, g, h, j, k). At NOW − 1, (k) is after now and (i) is inside, so L = 5 (a, b, f, i, j) and T = 8 (a, b, d, f, g, h, i, j).

### C12. Decided in this plan

§11's slice-0 calls are built as the design writes them: items 1 and 3 in C3 (landings, not sessions; engine paths only; no sealed number counts), 2 in C3 and C7, 4 in C1, 5 in C7 and the Global Constraints, 17 in C1 and C3, 18 in C6, 19 in C2 and C5, 20 in C7, 21 in item 11 below and Task 4. The choices below are this plan's, where the design left one to the builder.

1. The counter reads the checkout's `refs/remotes/origin/main` by full name, with no fallback (C2). The pulse counts only the home's own project.
2. The window walks the whole first-parent chain, so an out-of-order date cannot hide a landing (C3).
3. The mark is a whole line in some commit of `<C>^1..<C>`; trailing spaces, tabs and CRs are ignored, and nothing else is forgiven (C3).
4. Changed paths are against the first parent, with renames off, read as unquoted bytes whatever the caller's git settings; a shallow repository reads `unknown` (C3).
5. Tables pass the engine's table check, then the value rules of C1, which add n ≤ d to the design's n ≥ 1. `lane-next.tsv` never changes a state: a broken pointer must not hide a stall, so "a table could not be read" in §6.4 is read as `lanes.tsv`.
6. The clock is `FELIX_LANE_NOW`, whole seconds with no leading zero (C9).
7. The last lane landing is searched over the whole first-parent chain, and that search never changes a state (C3).
8. Both tables are read as committed. §11 item 19 names only `lanes.tsv`; reading `lane-next.tsv` the same way keeps an uncommitted edit out of the paragraph too. The last change is the newest first-parent commit from the home's `HEAD` that changed the lane's lines. A home git cannot read gives R9 when a `lanes.tsv` file is there, and no lane when none is (C2, C5).
9. The status row and the screen token speak for the first lane row; `felix lane`, the paragraph and the pulse speak for every row.
10. "While the share is `1/2`" (§11 item 20) is read as 2·n = d.
11. `felix lane` dispatches after the libraries load, in the main dispatch block, not with `audit`, `inventory` and `cost`: it needs a home and a project. So part 0480 checks its `usage()` line (§4, §10), and part 2220 asserts the line's exact text as well.
12. The TSV's columns, the human line, the reason sentences and the status details are as written above. An absent `lanes.tsv` and one with no row share one status detail.
13. The real-data check and the 60-day hand check are recorded measurements outside the suite (Task 8).
14. Slice 0's own PR carries `Felix-Lane: capability`, in the body of its Task 1 commit, as the first of the capability lane's three slices (design title and §1). After it lands, felix-home reads `short`, not `zero`, until that landing leaves the 14-day window: the paragraph shows, and the screen token does not.
15. The dash is not changed. It draws every status row in its /dash pane (`~/.claude/mods/dash/hooks/register.tsx:355-362`) and shows `unknown` as a warning (`parse.ts:101-102`), so the lane row appears there. It posts a note only when a row it saw at the previous poll changes state or value (`register.tsx:70`), so a lane already empty at the first poll is drawn but not posted. The band is not this slice (§6.5 item 2).
16. The next text is cleaned of control bytes before it enters the session's context (C7), because the hook's JSON escape handles only backslash, quote, LF, CR and tab.

### C13. What the blind author does

- Reads the design, this Contracts section, `tests/run`, `tests/parts/000*.sh`, `tests/lib/*.sh`, and parts 1100, 1670, 1690 and 1720. Never reads `engine/harness/lib/`, `hooks/`, `bin/` or `felix`.
- Writes the files in C11's table. Adds `. "$HERE/lib/lane-fixture.sh"` after `tests/run:144` (`lib/land-on-green.sh`), and the six part lines in name order, as part 1040 requires: after the last part line whose name sorts before `2200-` (`2160-docs-are-not-a-frontend-blind.sh` at `01e24cfc`) and before the first that sorts after `2250-`.
- Marks each edit to parts 1100, 1690 and 1720 with the comment "Changed by the lane counter contract (docs/2026-10-29-lane-slice-0-plan.md, C6): the lane row was added at the end, as the status header allows."
- Puts "(control)" in the name of every assertion that should also pass on main. Any other assertion that passes on main goes back to the blind author.

## Review Focus

The five input classes the design implies and no design bullet exercises, most likely to bite a person first. Each is pinned by a named assertion in C10, and the reviewer re-runs it by hand in Task 9.

1. **A mark written slightly differently** (an editor's trailing space or CRLF, an indented line in a hand-written squash body, a lower-case key): L silently undercounts and the lane reads `zero` while lane work lands. Pinned by L-RF1.
2. **`next` text that JSON must escape** (a quote, a backslash, a non-ASCII dash, a control byte): a bad escape breaks the session-start JSON, and with it the whole banner. Pinned by L-RF2.
3. **A table broken by a hand edit and committed** (`1/0`, `14d`, an unbalanced `(`, CRLF, no final newline, a duplicated lane): it must read `unknown`, never `ok`, and never crash the hook. Pinned by L-RF3 and L-NEVER-OK.
4. **A missing or broken `lane-next.tsv` while the lane is empty**: if it made the state `unknown`, the stall would go silent again, which is the failure slice 0 exists to end. Pinned by L-RF4.
5. **A shallow clone** (CI with depth 1, a stranger's quick clone): its boundary commit looks parentless, and counting it as a root would call it an engine landing. Pinned by L-RF5.

## Tasks

The Workflow runs the tasks in this order. Each stage names its model and effort. Commit and push at the end of every stage, because workflow agents die together. A stage that goes red twice moves up to Opus 5.5. The implementer never writes or edits a blind part; a wrong blind part goes back to the blind author.

### Task 0: Open the build

Model: Sonnet 5.5, high.

**Files:** none changed.

**Interfaces:** Consumes the open PR list and the live sessions. Produces the worktree `<home>/.claude/worktrees/lane-counter` on branch `claude/lane-counter`, cut from `origin/main`.

- [ ] Confirm the spec is the corrected design the founder's approval covers: its opening paragraph records his approval of 2026-10-29 and the fact-check, and its §11 lists items 17 to 21. A copy without them is older; stop.
- [ ] Count open engine PRs: `gh pr list --state open --limit 200 --json number,files --jq '[.[] | select(any(.files[]; .path | startswith("engine/")))] | length'`. Expect a number of 10 or less. Above 10, stop and wait.
- [ ] List live sessions (`ListAgents`). Expect none on `claude/lane-counter`. A session on `claude/lane-situations-owed` is slice 1, which rebases on this branch and rewrites its version, manifest and red record at landing (design §9). Both branches edit `felix` (dispatch and `usage()`), `templates/schemas.tsv`, `plugin.json`'s version, `tests/assertions.tsv` and `tests/red.tsv`, and add part lines to `tests/run` (each in name order among the part lines, which part 1040 checks). Beyond those they share felix-home's two lane tables and the two documents brought in below.
- [ ] `git -C <home> fetch origin`, then `git -C <home> worktree add -b claude/lane-counter <home>/.claude/worktrees/lane-counter origin/main`. Check that `git -C <wt> rev-parse HEAD` equals `git -C <home> rev-parse origin/main`.
- [ ] Re-read in `<wt>` every line number this plan names. Where a line has moved, follow the anchor named beside it. Then check the driver's room: `wc -l < <wt>/engine/harness/tests/run`, plus the part and lib lines each open engine PR adds to that file (read from `gh pr diff <n>`), plus this slice's 7. Above 500, stop before the blind stage and tell the queue owner: the driver needs room first.
- [ ] Bring the spec in, once this plan is committed on `claude/lane-situations-owed` beside the design: `git -C <wt> checkout claude/lane-situations-owed -- docs/2026-10-29-capability-lane-first-slices-design.md docs/2026-10-29-lane-slice-0-plan.md`. Commit `docs(capability): the lane counter's design and plan, slice 0's spec`. Push with `-u origin claude/lane-counter`.

### Task 1: The two tables and their schema rows

Model: Sonnet 5.5, high.

**Files:**

- Create: `projects/felix/lanes.tsv`, `projects/felix/lane-next.tsv` (C1's exact bytes).
- Modify: `engine/harness/templates/schemas.tsv`, inserting C1's two commented rows after line 85 (the `land.tsv` row).
- Test: `engine/harness/bin/schema-check`, run from the worktree's top.

**Interfaces:** Produces the two tables every later task reads, committed, since every surface reads them from `HEAD`.

- [ ] Create both tables with C1's bytes.
- [ ] Run `engine/harness/bin/schema-check` from `<wt>`. Expect a non-zero exit naming `lanes.tsv` and `lane-next.tsv` as tables with no schema row.
- [ ] Insert the two `schemas.tsv` rows with their comments after line 85.
- [ ] Run `engine/harness/bin/schema-check` again. Expect exit 0.
- [ ] Commit with `-m "feat(capability): felix-home's lane tables, the capability lane at 1/2 over 14 days and its next item" -m 'Felix-Lane: capability'`, so the mark is a body line of a commit that is not a merge, and `felix merge` carries it into the landing (C3, C12 item 14). One marked commit on the branch is enough. Push.

### Task 2: Blind parts

Model: Opus 5.5, xhigh. A separate author, working as C13 says.

**Files:**

- Create: `engine/harness/tests/lib/lane-fixture.sh`, and parts `2200-lane-counts-blind.sh`, `2210-lane-states-blind.sh`, `2220-lane-command-blind.sh`, `2230-lane-status-row-blind.sh`, `2240-lane-session-start-blind.sh`, `2250-lane-pulse-blind.sh` under `engine/harness/tests/parts/`.
- Modify: `engine/harness/tests/run` (C13's two insertions); `tests/parts/1100-declared-tools-reach-the-pulse-and-felix-status.sh:410-411` and `:430-436`; `tests/parts/1690-status-lander-row-blind.sh:184-190` and `:352`; `tests/parts/1720-lander-alerts-reach-github-blind.sh:377-379` (lines at `01e24cfc`).

**Interfaces:** Consumes C1 to C13. Produces the failing assertions every implementation task must turn green.

- [ ] Write `tests/lib/lane-fixture.sh`: functions only, no assignment at source time, no name the suite already has (part 0006's two judges). It builds C9's two layouts, commits table states in the home, and commits landings at pinned times.
- [ ] Write parts 2200 to 2250, each covering its C11 row. Read L and T from `felix lane --tsv` columns 3 and 4. Part 2230 runs status with `lanes.tsv` committed, then with none, in the home-apart layout, to compare every row before the lane row. Part 2250 uses the self-governed layout, with `FELIX_MEMORY` outside it.
- [ ] Edit parts 1100, 1690 and 1720 as C13 says.
- [ ] Commit `test(lane): blind assertions for the lane counter, written from the design and the plan's Contracts (red)`. Push.

### Task 3: Red on main

Model: Sonnet 5.5, high. The worktree's engine is still main's: Task 1 added only tables.

**Files:** none changed.

- [ ] Before each run, count part runs by process group (Global Constraints). Start one only while fewer than four run on the Mac. Tasks 4 to 9 count the same way.
- [ ] `engine/harness/tests/run --part 2200-lane-counts-blind.sh 2210-lane-states-blind.sh 2220-lane-command-blind.sh` from `<wt>`. Expect `FAIL` on every assertion not marked "(control)", with `felix lane` exiting 1 and printing `felix: unknown command: lane. Try 'felix help'.` on stderr.
- [ ] `engine/harness/tests/run --part 2230-lane-status-row-blind.sh 2240-lane-session-start-blind.sh 2250-lane-pulse-blind.sh`. Expect `FAIL` where status prints no lane row, no paragraph or token appears, and the pulse prints no lane line.
- [ ] Run each edited part on its own: `--part 1100-declared-tools-reach-the-pulse-and-felix-status.sh`, then `--part 1690-status-lander-row-blind.sh`, then `--part 1720-lander-alerts-reach-github-blind.sh`. Expect `FAIL` only on the ten-row assertions.
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
    - after `cmd_status` (lines 6658-6662): `cmd_lane`;
    - the dispatch case (lines 6679-6734), after line 6684 (`status)`): `  lane)    shift; cmd_lane "$@" ;;`.

- Test: parts 2200, 2210, 2220; part 0480.

**Interfaces:**

- Consumes:
    - `felix_table_check SCHEMAS FILE [TABLE]` (`lib/table.sh:131`): exit 0 accepted, 1 refused, 2 cannot examine. `lib/lane.sh` sources `lib/table.sh` behind a guard (`command -v felix_table_check >/dev/null 2>&1 || . "$(dirname "${BASH_SOURCE[0]:-$0}")/table.sh"`), since only `bin/schema-check` loads it today.
    - `felix_table_rows FILE` (`lib/table.sh:102`): the data rows.
    - `_felix_git_read VAR COMMAND...` (`lib/resolve.sh:894`): 0 only when the command finished.
    - `resolve_or_die` (`felix:502`): sets `PROJ`, exits 2. `die MSG [STATUS]` (`felix:374`). `felix_repo_root DIR` (`lib/resolve.sh:333`).

- Produces:
    - `felix_lane_rows PROJ ROOT [FULL]`: on stdout, C5's TSV lines for `<PROJ>`'s tables counted in `ROOT`'s repository; nothing when `lanes.tsv` is absent or has no row; returns 0. It prints nothing on stderr. Unless FULL is 1, columns 7, 10 and 11 read `-` and their searches are skipped: status, session start and the pulse print none of the three.
    - `felix_lane_command PROJ ROOT TSV`: calls `felix_lane_rows` with FULL 1; TSV=1 prints its lines; TSV=0 prints C5's human lines; returns 0.
    - `cmd_lane [--tsv]`: parses as `cmd_status` does (`case "$#:${1:-}" in 0:) ;; 1:--tsv) tsv=1 ;; *) die "usage: felix lane [--tsv]" 2 ;; esac`), then `resolve_or_die`, `export GIT_OPTIONAL_LOCKS=0`, and `felix_lane_command "$PROJ" "$(felix_repo_root "$PWD")" "$tsv"`. It takes no flag with a value, so `need_value` has nothing to guard.

- [ ] Confirm parts 2200, 2210 and 2220 are red from Task 3.
- [ ] Write `lib/lane.sh`. The values are C1 to C5's; the body is open except for these choices, which the contract was written against:
    - read each table at the home's `HEAD`: find the repository holding `<PROJ>` and the path inside it as `_ps_blob` does (`lib/pr-status-state.sh:17-26`); take the entry with `git ls-tree HEAD -- <path>` (exit 0 and empty: absent; a mode other than 100644 or 100755: refused); copy its blob with `git cat-file blob` to a scratch file from `mktemp` under `${TMPDIR:-/tmp}` (part 1000); check it with `felix_table_check "<engine>/templates/schemas.tsv" <scratch> <table>`; remove it. Never run `git diff`, `git status` or `git add` on the home: they rewrite its index under a stat-dirty file (`lib/status.sh:220-227`);
    - then each row by C1's rules (R5 to R7, in C5's order), then the clock (R8);
    - check the ref with `git -C ROOT rev-parse --verify -q 'refs/remotes/origin/main^{commit}'` (R1) and shallowness with `git -C ROOT rev-parse --is-shallow-repository` (R3);
    - run every lane git read the way `_fi_git` does (`lib/inventory.sh:98`): `GIT_NO_LAZY_FETCH=1 git --no-optional-locks --literal-pathspecs -c log.showSignature=false`, so a partial clone reads R2 and never fetches; and pass `--no-show-signature` to every `log`, since GitHub signs the squashes it makes (`lib/intake.sh:100-107`);
    - walk the first-parent chain once with `git log --first-parent` and an explicit `--format` of object name, parents and committer time, read through `_felix_git_read` (R2 on failure);
    - read changed paths with `git -c core.quotePath=false diff-tree -r -z --no-renames --name-only`, NUL-separated and unquoted, matched with `LC_ALL=C grep -z -E`; one call per landing or one `--stdin` call, only for landings the window or the last-landing search needs;
    - read marks from `git log --format=%B <C>^1..<C>` (the landing alone when it has one parent); match lines in `LC_ALL=C awk` after `sub(/[ \t\r]+$/, "")`;
    - find the last change by walking the home's first-parent chain from `HEAD` and comparing the lane's lines in each commit's `lanes.tsv` with its first parent's; a merge is compared with its first parent only, so do not lean on `git log -- <path>`'s history simplification;
    - a failed last-landing or last-change search sets only its own column to `unknown` (C3, C5).

- [ ] Add the five `felix` edits listed under **Files**.
- [ ] Run `engine/harness/tests/run --part 2200-lane-counts-blind.sh 2210-lane-states-blind.sh 2220-lane-command-blind.sh`. Expect every assertion ok, with no skip but the python3 kind.
- [ ] Run `engine/harness/tests/run --part 0480-the-one-line-git-cannot-reconstruct.sh`. Expect "help covers every command that dispatches" ok.
- [ ] Commit `feat(lane): felix lane counts each lane's share of engine landings on origin/main, offline, with its target, next item and last change`. Push.

### Task 5: The status row

Model: Sonnet 5.5, xhigh.

**Files:**

- Modify `engine/harness/lib/status.sh`:
    - the header, lines 1-15: nine rows become ten, with `lane` last in the order on lines 10-11;
    - a new `_felix_status_lane PROJ ROOT` after `_felix_status_alerts` (lines 317-338);
    - `felix_status_rows` (lines 463-477 at `01e24cfc`): the comment above it says ten rows, and `_felix_status_lane "$proj" "$root"` follows its last call, `_felix_status_icloud "$home"`.

- Test: part 2230; parts 1100, 1690, 1720 as edited.

**Interfaces:**

- Consumes: `felix_lane_rows` (Task 4); `_felix_status_row ROW STATE VALUE DETAIL` (`lib/status.sh:150`); `_felix_status_need FUNCTION LIB` (`lib/status.sh:32`), used as `_felix_status_need felix_lane_rows lane`, because `lib/status.sh` is sourced alone in suite subshells.
- Produces: `_felix_status_lane PROJ ROOT`, which prints exactly one C6 row and returns 0. An empty `PROJ` gives the "not a governed checkout" row.

- [ ] Confirm part 2230 and the three edited parts are red from Task 3.
- [ ] Write `_felix_status_lane` with C6's four cases, reading only the first line `felix_lane_rows` prints. No line at all is the "no committed row" case, so the function reads no table itself.
- [ ] Add the call and the header edits.
- [ ] Run `--part 2230-lane-status-row-blind.sh`, then each of `1100-…`, `1690-…`, `1720-…` alone. Expect all ok.
- [ ] Commit `feat(status): felix status gains a last row, lane, the first lane's state and its share of engine landings`. Push.

### Task 6: Session start

Model: Sonnet 5.5, xhigh.

**Files:**

- Modify `engine/harness/hooks/session-start`:
    - after line 73 (`lib/waiting.sh`): `[ -f "${SCRIPT_DIR}/../lib/lane.sh" ] && . "${SCRIPT_DIR}/../lib/lane.sh"`;
    - after line 580 (`felix_start_waits …`): `lane_line=""; _felix_lane_tok=""`, then `command -v felix_start_lane >/dev/null 2>&1 && felix_start_lane "$PROJ" "$_repo_root" >/dev/null 2>&1`;
    - line 588: `${lane_line:-}` right after `${waits_line}`;
    - line 761: `_felix_line="${_felix_line}${_felix_wait_toks:-}${_felix_lane_tok:-}"`.

- Modify `engine/harness/lib/lane.sh`: add `felix_start_lane`.
- Test: part 2240.

**Interfaces:**

- Consumes: `felix_lane_rows`; `$PROJ` (`hooks/session-start:171`) and `$_repo_root` (`hooks/session-start:244`); `escape_for_json` (`hooks/session-start:80-88`), which escapes only backslash, quote, LF, CR and tab, so `felix_start_lane` cleans `<next>` by C7's rule first, as `_fw_clean` does (`lib/waiting.sh:32`).
- Produces: `felix_start_lane PROJ ROOT`, which sets `lane_line` (C7's paragraphs, each with its leading newline) and `_felix_lane_tok` (C7's token or empty), and returns 0. The call is redirected on both streams, as the hook's other calls in its own shell are (`hooks/session-start:181-185`): a stray byte would break the JSON, and the results travel in globals.

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

- Consumes: `felix_lane_rows`; `felix_repo_root` and `felix_resolve_project` (`lib/resolve.sh:333`, `:467`), to find the home's own project the way `felix_pulse_report` does (`lib/pulse.sh:392-394`), and only when `git -C <home> rev-parse --git-dir` succeeds. `felix_repo_root` prints a directory that is not in git as its own root, and `felix_resolve_project` would then bind a `.felix` there, so without that check a non-git home holding `lanes.tsv` would get an `unknown` lane line, against C2.
- Produces: `felix_lane_pulse HOME`, which prints C8's lines, or nothing, and returns 0.

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
- [ ] Green: `( cd "$S/r" && FELIX_HOME="<wt>" FELIX_LANE_NOW=1793309173 "<wt>/engine/harness/felix" lane --tsv )`. Expect columns 1 to 9 and 12 to be `capability`, `zero`, `0`, `18`, `14`, `1/2`, `none`, `Felix-Lane: capability`, the next text of C1, and `2026-10-29T21:26:13Z`, and column 10 to name the Task 1 commit. The clone's tracked `.felix` binds it to `felix`, `<wt>`'s `HEAD` holds the committed tables, and `1793309173` is `e54e31f3`'s committer time. Save both outputs to the audits directory.
- [ ] The 60-day hand check, written without reading `lib/lane.sh`. Make a home whose committed `lanes.tsv` has a one-day window: `mkdir -p "$S/h/projects" && cp -R "<wt>/projects/felix" "$S/h/projects/"`, set the window cell of `$S/h/projects/felix/lanes.tsv` to `1`, then `git -C "$S/h" init -q && git -C "$S/h" add -A && git -C "$S/h" -c user.name=lane -c user.email=lane@localhost commit -qm 'one-day window'`. For k from 0 to 59, let e = 1793309173 − k·86400:
    - the counter: `( cd "$S/r" && FELIX_HOME="$S/h" FELIX_LANE_NOW=<e> "<wt>/engine/harness/felix" lane --tsv )`, columns 2, 3 and 4;
    - the independent count: the commits of `git -C "$S/r" log --no-show-signature --first-parent --format='%H %ct' e54e31f3` with e − 86400 < time ≤ e. T counts those for which `git -C "$S/r" -c core.quotePath=false diff-tree --no-commit-id -r --no-renames --name-only <C>^1 <C>` prints a path starting `engine/`. L counts those of T for which `git -C "$S/r" log --no-show-signature --format=%B <C>^1..<C>` has a line that reads `Felix-Lane: capability` once trailing spaces, tabs and CRs are removed.

    Expect all 60 days to agree on L and T, and column 2 to follow C4 from them; save the table to the audits directory. A day that disagrees falsifies the counter (design §6.6) and goes to the review as a finding.

- [ ] Measure CPU, not wall: `/usr/bin/time -p` user plus sys for `felix lane --tsv` in `$S/r`, three runs, the median; and for the session-start hook in `$S/r` with `$S/h` as the home, and with a home whose `HEAD` holds no `lanes.tsv`. Save the numbers; they go in the PR body.
- [ ] Remove `$S`. It is a scratch clone and a scratch home, never a real home or a memory root.

### Task 9: Adversarial review and fixes

Review: Opus 5.5, xhigh. Fixes: Sonnet 5.5, xhigh.

**Files:** whatever the findings touch, never a blind part.

- [ ] The reviewer reads the diff against `origin/main`, the design, the Contracts and the Review Focus, and re-runs each Review Focus case by hand in a scratch fixture.
- [ ] The reviewer also probes:
    - a fork that fails (`ulimit -u` low, as part 1670 does) during the walk: the lane must read `unknown`, never `idle` or `ok`;
    - a UTF-8 caller locale (`LANG=en_US.UTF-8`) with a non-UTF-8 byte in a commit message;
    - `log.showSignature=true` over a signed landing, and `core.quotePath` true and false over a non-ASCII engine path: identical TSV bytes;
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
- [ ] Take the next free patch slot at this moment: above every version in `origin/main`'s `plugin.json` and in open PR titles. On 10-29, 0.49.310 to 0.49.314 were claimed. Set it in `plugin.json`.
- [ ] Write the handoff section: what landed, the C12 decisions, the measurements, and that slice 1 moves `lanes.tsv` to `1/4` and `lane-next.tsv` on to slice 2, pending the direction fold. Add it with `felix handoff --section <file>`.
- [ ] Commit `chore(release): the lane counter takes 0.49.<n>`. Commit everything before the record.
- [ ] Keep the Mac awake. Start the record detached, with INT and QUIT at their defaults and `FELIX_TEST_JOBS` unset (so it runs at -j 1 and leaves a receipt the gate can reuse), from `<wt>`, and poll its log, since a background shell dies at ten minutes: `nohup perl -e 'use POSIX (); POSIX::setsid(); $SIG{INT}=$SIG{QUIT}="DEFAULT"; exec @ARGV' bash -c 'unset FELIX_TEST_JOBS; engine/harness/tests/run --record-assertions' > <log> 2>&1 &`. A bare `&` from a non-interactive shell runs the suite with INT and QUIT ignored, and part 1295 then fails. Expect `0 failed`, `recorded <n> assertions`, and red written against `origin/main` naming the new and edited parts' assertions.
- [ ] Commit `test(suite): record at 0.49.<n>: <p> passed, 0 failed, <s> skipped; red against origin/main <sha> names <k>`. Red ran in its own worktree under a temporary directory; the gate runs here, after this commit.
- [ ] `nohup perl -e 'use POSIX (); POSIX::setsid(); $SIG{INT}=$SIG{QUIT}="DEFAULT"; exec @ARGV' bash -c 'engine/harness/felix gate' > <log> 2>&1 &`, polled. Expect a green gate whose header names `<wt>`.
- [ ] Push. Open the PR with `felix pr --create`. The title carries the version, for example `feat(lane): felix lane counts the capability lane's share of engine landings, with a status row, a session-start paragraph and a pulse line (slice 0, 0.49.<n>)`. The body gives the red counts, the record line, the real-data line, the hand-check result, the CPU numbers and C12. It is not a draft and carries no hold label, so land on green can take it. No attribution trailer.
- [ ] Turn on the CI monitor for the PR.

## Coverage

Every requirement of §6, and §9's slice-0 list, maps to a task and a part.

| Spec | Where |
|---|---|
| §6.1 the one question, the next item, the empty lane on the screen line | C5, C7; Tasks 4 and 6 |
| §6.2 landings, the window, counted, marked, total | C3; Task 4; part 2200 |
| §6.3 the two tables, schema rows, felix-home rows, read as committed, who changes what | C1, C2; Task 1; parts 2210, 2220 |
| §6.4 states | C4; Task 4; part 2210 |
| §6.5.1 `felix lane [--tsv]` and its fields | C5; Task 4; part 2220 |
| §6.5.2 the status row, `unknown` as an unreadable row | C6; Task 5; part 2230, parts 1100, 1690, 1720 |
| §6.5.3 the session-start paragraph | C7; Task 6; part 2240 |
| §6.5.4 the screen token, and silence on a resume | C7; Task 6; part 2240 |
| §6.5.5 the pulse line | C8; Task 7; part 2250 |
| §6.5.6 no push alert; the lane row in the dash | Global Constraints; Task 9's exclusions probe; C12 item 15 |
| §6.6 the counts, at each edge | part 2200 |
| §6.6 the state edges | part 2210 |
| §6.6 what shows where | part 2240 |
| §6.6 `felix status --tsv` one row, every row before it identical, `unknown` and `-` | part 2230 |
| §6.6 the last change, and an uncommitted edit | part 2220 |
| §6.6 determinism | L-DET in parts 2220, 2230 |
| §6.6 real data at `e54e31f3` | Task 8 |
| §6.6 falsified if, 60 days | Task 8 |
| §4 constraints | Global Constraints; Task 8's lints; Task 9 |
| §9 slice 0's contents, and the files slice 1 shares | Tasks 0, 1 and 4 to 7 |
| §10 left to the builder | C12 |
| §11 items 1 to 5 and 17 to 21 | C12's opening line |
