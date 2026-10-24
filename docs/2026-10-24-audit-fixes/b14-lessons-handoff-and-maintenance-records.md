# Audit fix b14: lessons, handoff and maintenance records stay true

This is the contract for batch b14 of the 2026-10-24 audit. It covers four defects: C026 (high), C118 (medium), C058 (low, as a skeptic corrected it) and C105 (low, as a skeptic corrected it). It is written for a blind test author: every B item can be checked from outside, and section 4 gives each assertion its fixture. The branch is `claude/audit-b14-lessons-handoff-and-maintenance-records`, cut from origin/main 69b51a61 (0.49.307). Where a skeptic corrected the audit, this contract follows the correction and says so.

**What this contract decides.**
- **C026.** A lesson whose first bold span is a date is mounted as the date plus the first sentence after it. Lessons that start any other way are mounted exactly as they are today.
- **C058.** The handoff reads the tree with porcelain status through the fail-closed reader. When that read fails, the handoff says it does not know whether the tree is clean.
- **C118.** The template's graphify row is not due when there is no graph to keep current. Felix's own row keeps its present meaning.
- **C105** is not fixed here (section 6). Its sound fix needs a new column, which is a founder stop, or a cloud mode the engine does not have.

## Readings this rests on

All of these were measured on 2026-10-24 against 69b51a61, in scratch `mktemp -d` homes (`FELIX_HOME`, `FELIX_MEMORY`), with nothing real touched.

- **The lesson writer.** `felix lesson "T"` appends `\n- **YYYY-MM-DD** T\n` (lib/memory.sh:72), and it is the only writer of lessons.md. `_felix_lessons_headline` (lib/lessons.sh:76-78) keeps `^- \*\*[^*]*\*\*` and drops the rest. For these entries that span is the date.
  - Three lessons written by `felix lesson` were each mounted by `felix lessons --for` as `  - **2026-10-24**`.
  - The prompt hook's lessons block (hooks/user-prompt:246-256) held only `  - **2026-10-24**`.
  - The real ~/.felix/memory/felix/lessons.md has 220 entries. 171 of them start `- **YYYY-MM-DD**`, and 2 of those put a bold claim after the date (`- **D** **Claim.** ...`). One repeats the date in bold (`- **D** **D** Claim. ...`).
- **Selection is not the defect.** Scoring reads the whole entry (lessons.sh:58-68). The right entries are picked, and only what is printed is wrong.
- **The handoff's tree read.**
  - felix:5259 and lib/memory.sh:177 both run `git -C "$root" status --short 2>/dev/null | grep -v '^??' || true`.
  - With the repository's own `status.branch=true`, a clean tree printed `[ ] the tree is dirty`, and SESSION_HANDOFF.md's Uncommitted block held a fenced `## main`. An edited tree's block held `## main` above ` M a.txt`.
  - With `.git/index` overwritten by 7 bytes, `git status` exited 128 (`fatal: .git/index: index file smaller than expected`). `felix handoff` still printed `[x] tree is clean`, wrote `Nothing. The tree is clean.`, and exited 0.
  - A directory bound by `.felix` with no `.git` also printed `[x] tree is clean`.
  - `git status --porcelain --untracked-files=no` prints no branch line under `status.branch=true` (git 2.54.0).
  - Through `_felix_git_read` (lib/resolve.sh:894), the corrupt-index read returns 1. `felix_tree_why` (lib/verify.sh:462) gives `fatal: .git/index: index file smaller than expected` there, and nothing outside git.
- **The template's graphify row.**
  - templates/maintenance.tsv:84 is `graphify 0 always ...`, with a check that finds `$G/graphify-out/graph.json` beside the common git dir, newer than the last commit outside `projects/*/maintenance.log` and `*.md`. felix:1243 copies the template into every new project.
  - For a cadence-0 checked row, felix_maint_status runs the check and never reads the log (lib/maintenance.sh:221-245), so `felix maintenance --ran graphify` prints `recorded a run of graphify` and the row stays `DUE ... check failed`.
  - A fresh project made from the template printed `6 routine(s) due` with graphify among them. The session start said `Maintenance due: dead-code dependencies docs-drift constitution architecture graphify` and `Felix: hof · 6 due`.
  - Each repository below was read by `felix_maint_status` with the template's row as shipped:

    | Repository | Status |
    |---|---|
    | committed, no graph | `due ... check` |
    | unborn, no graph | `due` |
    | outside git | `due` |
    | graph dated 2000 | `due` |
    | graph dated 2099 | `ok` |
    | worktree of a checkout holding a 2000 graph | `due` |
    | worktree of a checkout with no graph | `due` |
    | unborn, holding a graph written just now | `ok` |
    | outside git, holding a graph written just now | `ok` |
    | only commit touches `notes.md`, graph dated 2000 | `due` |

  - The last three come from BSD find. `/usr/bin/find F -newermt ""` exits 0 and compares F against some time of its own choosing, so a graph written today reads as newer. GNU find, which CI uses, refuses an empty `-newermt`, so CI reads all three as `due`.
- **Sizes on the base.**
  - These are already past 500 lines and must not get longer: lib/memory.sh 592, felix 6734, hooks/session-start 780, lib/verify.sh 663, lib/resolve.sh 1872.
  - These stay under 500: lib/lessons.sh 88, templates/maintenance.tsv 84, hooks/user-prompt 316.
  - tests/run is 497 lines and part 1040 holds it to 500. Batch b00 makes room, and this batch adds exactly two part lines.

## 1. Defects

**C026 (high, kept high by both verifiers).** The lessons mount reduces every lesson written by `felix lesson` to a bare date.
*Scenario.* A session's prompt matches three lessons the gate has been teaching since 10-13. The prompt hook mounts three lines reading only a date under "Lessons this project already paid for", so the session learns nothing and repeats the mistake. On another person's project, `felix lesson` is the only writer, so every lesson mounted there is a bare date. README.md:553 ("Mounts recorded lessons that match the prompt") is then false for the product's own lesson path.

**C058 (low; the verifier lowered it from medium).** `felix handoff` says "tree is clean" when `git status` fails, and calls a clean tree dirty under `status.branch`.
*Scenario, as corrected.* A session ends on a worktree whose index git cannot read. `felix handoff` prints `[x] tree is clean` and writes `Nothing. The tree is clean.` into SESSION_HANDOFF.md, which the next session's start names for reading. The Stop hook is not let go by this: `felix_tree_dirty` reads fail-closed (verify.sh:279), and stop:218-238 holds with git's reason. What is left is the false record in the handoff and the checklist. Under `status.branch=true`, every clean tree is called dirty and `## main` is written as its uncommitted list, a false alarm in the cautious direction.

**C118 (medium, kept by the verifier).** Every new project is seeded with a graphify upkeep row that is due forever without the founder's own tool.
*Scenario.* A stranger's every session shows `· N due` with graphify in it, and is told to "do them on one branch" and refresh a graph with a tool nobody installed. `felix maintenance --ran graphify` cannot clear it, so the badge never reaches zero, and the line meant to carry real upkeep is learned to be ignored.

**C105 (low; the verifier lowered it from medium).** A cloud session is told to run maintenance it cannot do, and `felix maintenance --ran` puts a false "done" into the tracked log the Mac reads.
*Scenario, as corrected.* Felix's own graphify row is due at every cloud session start, because a clone holds no graph. A cloud session that "rereads" an empty lessons.md and runs `felix maintenance --ran lessons` would, once its PR lands, mark the Mac's lessons routine ok for 30 days. The verifier found the other "false done" outcomes covered elsewhere (section 6).

## 2. Required behaviour

Terms used by every item:
- **A fixture home** is a directory H holding `projects/<p>/project.json` (`{"name":"<p>","remote_match":"example.invalid/<p>-marker-only","gate":"true"}`) and `projects/<p>/CLAUDE.md`, with a memory root M.
- **A bound repository** is a directory R made with `git init -b main`, holding `.felix` (the line `<p>`) and `a.txt`, and one commit of both.
- **Run felix** means `cd R && env -u CLAUDE_CODE_REMOTE -u CLAUDE_CODE_SESSION_ID FELIX_HOME=H FELIX_MEMORY=M "$FELIX" ARGS`, with stdout and stderr captured together and the exit status kept. **Run a hook** is the same with `"$FROOT/harness/hooks/<name>"` and a payload on stdin.
- **D** is the date `felix lesson` wrote, read back from M/<p>/lessons.md, never computed by the test.
- **A matched line** is a line `felix lessons --for` prints under `matched to this change`, with its two-space indent.
- **The Uncommitted block** is the lines of M/<p>/SESSION_HANDOFF.md from `## Uncommitted` up to, but not including, `## Recent`.

### C026: a dated lesson mounts its claim

**B1.** An entry whose first bold span is exactly a date (`- **` then four digits, `-`, two digits, `-`, two digits, then `**`) is mounted as that span, one space, and the first sentence of the text after it, and nothing after that sentence.
- The first sentence runs up to and including the first `.`, `!` or `?` that is followed by a space or by the end of the entry. A `**` that closes a bold span directly after the mark belongs to the sentence.
- This holds for every matched line of `felix lessons --for` and for every line of the prompt hook's lessons block.

**B2.** A `.` that is not followed by a space does not end the sentence. A version such as `3.2` and a path such as `lib/lessons.sh` stay inside it.

**B3.** When the text after the date opens with a bold claim (`- **D** **Claim.** Evidence`), the mounted line is `- **D** **Claim.**`.

**B4.** When the text after the date opens with a date in bold, its own or another (`- **D** **D2** Claim. Evidence`), the mounted line holds `Claim.` and not the evidence.

**B5.** An entry whose text continues on the next line (the continuation line indented, with no blank line between) is one entry, as it is today. Its first sentence may cross the line break, is mounted on one line, and what follows the sentence is not mounted.

**B6.** A dated entry whose text has no sentence end is mounted from its first words. The line is cut to at most 240 characters, as every mounted line is today.

**B7.** No mounted line is longer than 240 characters.

**B8.** An entry whose first bold span is anything other than exactly a date is mounted as that span alone, exactly as today. That covers the L-numbered entries (`- **L-7 Claim.** Evidence` mounts as `- **L-7 Claim.**`). In one call, each entry is mounted by its own rule. (control)

**B9.** Which entries are mounted, their order, and how many stays as today: at most 4 in the hook and at most 8 for `--for`. An entry the context does not match is not mounted. A context that matches nothing still prints `nothing matched this context`. (control)

**B10.** The prompt hook, given `{"prompt":"why do background jobs ignore signals"}` in a bound repository whose lessons include the B1 entry:
- exits 0;
- prints JSON whose `hookSpecificOutput.additionalContext` holds that entry's mounted line, indented two spaces;
- holds no sentence after it.

**B11.** `felix lesson "T"` still appends `- **D** T` as its own paragraph, prints `recorded in <M>/<p>/lessons.md`, and exits 0. The writer does not change, because 171 recorded entries and the `written.log` owner rows rely on that shape. (control)

**B12.** With no lessons.md, or an empty one, the hook adds no lessons block and `felix lessons` says `no lessons recorded yet`, as today. (control: part 0200 pins it, and this batch adds no assertion for it)

### C058: the handoff says what git said, or that it does not know

**B13.** Take a bound repository whose only change is an untracked file. `felix handoff` prints `  [x] tree is clean`. The Uncommitted block holds `Nothing. The tree is clean.` and does not name the untracked file. (control)

**B14.** Take a bound repository with an unstaged edit to `a.txt` and a staged new file `n.txt`. `felix handoff` prints `  [ ] the tree is dirty; commit it or say in the devlog why not`. The Uncommitted block holds a fenced list with the lines ` M a.txt` and `A  n.txt`. (control)

**B15.** In a clean repository whose own config sets `status.branch` to true, `felix handoff` prints `  [x] tree is clean` and not the dirty line. The Uncommitted block holds `Nothing. The tree is clean.`, and no line in it is `## main`.

**B16.** In the same configuration with `a.txt` edited, the dirty line is printed. The Uncommitted block lists ` M a.txt`, and no line in it is `## main`.

**B17.** When git cannot read the tree (`.git/index` overwritten with the 7 bytes `garbage` after `a.txt` was edited):
- `felix handoff` prints a line beginning `  [?] whether the tree is clean is not known: ` followed by REASON.
- REASON is git's own words when git gave any: the first line it printed that begins `error: ` or `fatal: `. Otherwise REASON is the words `git status did not finish`. For this fixture, REASON contains `fatal:` and `index`.
- It prints neither `[x] tree is clean` nor `the tree is dirty`.
- The Uncommitted block has a line beginning `Whether the tree is clean is not known: ` followed by REASON. It holds no ``` fence (no partial list is presented as the list) and not `Nothing. The tree is clean.`.
- The file is still written in the generated shape (line 1 `# Handoff`, line 3 beginning `Regenerated `), and the command exits 0.

**B18.** When `git status` fails and prints nothing, REASON is exactly `git status did not finish`. In the fixture, `git` is a wrapper first on PATH that exits 1, printing nothing, when any argument is `status`, and passes every other call to the real git. The tree itself is clean.

**B19.** In a directory bound by `.felix` that is not inside any git repository, `felix handoff` prints the `[?] whether the tree is clean is not known` line, never `[x] tree is clean`, and the Uncommitted block does not say `Nothing. The tree is clean.`.

**B20.** Everything else the handoff does stays as today (control):
- it exits 0 in B13-B19;
- the `before you stop` list and its other lines;
- the note carried from the last handoff;
- a handoff felix did not write is refused;
- the lifecycle row it records.

### C118: the seeded graphify row is due only when there is a graph to keep current

These items concern the graphify row of `templates/maintenance.tsv` as shipped. The tests read it from `$FROOT/harness/templates/maintenance.tsv` and copy it whole into the fixture project as `maintenance.tsv`. That project declares no capabilities. "Status" means the first two fields of the row's line from `felix_maint_status <project dir> <root>` (lib/maintenance.sh, after resolve.sh and detect.sh). "felix maintenance" means that command run in the root.

**B21.** In a committed repository with no `graphify-out/graph.json` beside its common git dir, the status is `ok graphify`. `felix maintenance` prints a line beginning `  ok      graphify` that contains `check passed`, and no line beginning `  DUE     graphify`. An unborn repository (`git init`, no commit) with no graph reads `ok` too.

**B22.** In that committed repository, the session-start hook still prints a `Maintenance due:` line (the template's clock rows have never run), and that line does not name graphify. The number in the badge (`· N due` in `systemMessage`) equals the count of lines beginning `  DUE ` that `felix maintenance` prints there: 5 with the template as shipped. Only the graphify part is red; the count matching is a control.

**B23.** A graph beside the common git dir that is older than the last commit is due: the status is `due`, and `felix maintenance` says `check failed`. The last commit here is the last one touching anything but `projects/*/maintenance.log` and `*.md`. (control)

**B24.** A graph newer than that commit is `ok`. (control)

**B25.** The graph is looked for beside the common git dir, never in the directory the check stands in:
- a worktree of a checkout holding a stale graph is `due` (control);
- a worktree of a checkout holding no graph is `ok`.

**B26.** When the check cannot ask git, the row is due, because a check that cannot ask is loud:
- a directory outside any git repository is `due`, with or without a graph in it;
- an unborn repository that holds a graph is `due`, because there is no commit to compare the graph with.

This holds on BSD and GNU find alike. On macOS the cases with a fresh graph read `ok` before this fix, and CI reads them `due`.

**B27.** When git answers and no commit touches what the graph models, the graph is behind nothing and the row is `ok`. The fixture is a repository whose only commit adds `notes.md`, holding a graph dated 2000.

**B28.** The row stays one row named `graphify`, with exactly five tab-separated fields: cadence `0`, capability `always`, a description, and a check. Its description names `graphify-out/graph.json`, so `ok, check passed` reads true where there is no graph. `felix maintenance` in the B21 repository prints no `Checks refused` section.

**B29.** `projects/felix/maintenance.tsv` and `projects/felix/maintenance.log` do not change. Felix's own graphify row stays due on a checkout with no graph, by the design part 0450 pins (section 6).

## 3. What must not change

**The lessons mount.**
- L-numbered entries mount as their bold span alone.
- The always-applicable part before the first entry is shown.
- An unrelated context matches nothing.
- The hook emits the UserPromptSubmit shape, stays at 20 lines or fewer, is silent in an ungoverned repository, and is silent with no lessons.

Pinned by `0200-generated-constitution.sh` and its fixture `tests/lib/router.sh` (`_lessons_build`), and by `0230-the-intent-router.sh` ("the words those messages carry still bring a lesson when a person types them"). The selection, scoring, `FELIX_LESSONS_MAX` and `felix_lessons_context` do not change. Only `_felix_lessons_headline` does.

**The lesson writer and its owner rows.** Pinned by `0120-scheduled-maintenance.sh` ("lesson is recorded"), `0260-a-failure-nobody-wrote-down.sh`, `0270-unrecorded-catches-per-checkout-blind.sh`, `0280-unrecorded-catches-settled-by-their-writer-b.sh` and `0290-noticing-when-another-plugin-breaks-the-sess.sh`.

**The handoff.**
- Its generated header, and the refusal of a foreign handoff: `0480-the-one-line-git-cannot-reconstruct.sh`.
- The note given as words or `--was`, and an unknown flag refusing: `0120`.
- Its lifecycle rows: `0800-the-lifecycle-recorder.sh`.
- Untracked files kept out, and colour forced by the repository's config changing nothing, with no escape byte in the file: `1500-git-colour-never-reaches-what-the-engine-parses.sh` ("... prints that the tree is clean", "its Uncommitted block reads exactly as it does with no colour configuration").
- The Stop hook's fail-closed tree read (`felix_tree_dirty`, stop:218-238): `1520-git-readers-fail-closed.sh`. It is not touched.

**Maintenance.**
- Event rows and checks: `0450-memory-scan-memory-stays-out-doctrine-stays.sh`. Its graphify fixture is a printf copy of Felix's own row, and every one of its assertions keeps passing unchanged.
- In-flight rows: `0460-maintenance-a-check-that-names-work-already.sh`.
- The badge count and `--ran`: `0120`.
- Every judged command in templates/maintenance.tsv is admitted by the final filter: `0681-continued.sh`.
- Unreachable and unknown rows: `0590-the-pre-flight.sh` and `0671-continued.sh`.
- Pulse's due list: `0470-the-pulse-the-heartbeat-that-does-not-wait-f.sh`.
- The graph line is silent without a graph: `0760-the-graph-nothing-ever-mentioned.sh`.
- The schema checks: `0730-schema-check-every-table-declared-every-row.sh`, and `bin/schema-check` over the tree.
- `felix new` copies the template verbatim (felix:1243). That does not change.

**Recorded names.** No existing assertion is renamed or removed, and nothing is added to part 0200. Every new assertion lives in the two new parts. assertions.tsv and red.tsv are not edited by hand.

**Sizes.**
- lib/memory.sh, felix, hooks/session-start and lib/verify.sh are past 500 lines and do not get longer. Changes there replace lines, and comments may be tightened.
- lib/lessons.sh and templates/maintenance.tsv stay under 500.
- tests/run gains exactly the two part lines.

**Portability.**
- Everything works under bash 3.2 with BSD tools and BWK awk, and under bash 5 with GNU tools and gawk.
- Sort and compare under `LC_ALL=C`, and spell digits as `[0123456789]`.
- No gawk-only builtins, and no `case` inside `$( )`.

## 4. Assertions

Each assertion names its B item. "Control" means it holds before and after the fix. Every other assertion fails on 69b51a61 and passes after the fix. Every assertion is emitted on every run, whatever the command printed; a fixture that could not be built makes each assertion resting on it a FAIL that says so. Every felix or hook call runs under a 120 s limit (`perl -e 'alarm shift; exec @ARGV' 120 ...`, since macOS ships no timeout).

### Part 1890: dated lessons mount their claim

**Fixture L.**
- `L="$(mktemp -d "$TMP/b14l.XXXXXX")"`, resolved with `pwd -P`.
- Home `L/home`, project `lsn`, memory `L/mem` (with `L/mem/lsn/` made).
- Bound repository `L/repo`. Every git write goes through `_fx_git`/`_fx_cd`, as part 0200's lint requires.
- Lessons are written in this order with `felix lesson`:
  - E1 `Background jobs ignore INT and QUIT signals. Evidence: on 2026-10-22 a gate started with an ampersand skipped the signal tests.`
  - E2 `Version 3.2 of bash reads lib/lessons.sh slowly. Second sentence about quadratic expansions.`
  - E3 `**A record written inside the tree it describes invalidates itself.** The gate wrote it there.`
  - E4 `**2026-09-21** A raise-only reader fails open through its own failure. The walker printed nothing when awk failed.`
  - E5 `Overflowing claims keep going ` repeated twelve times (no `.`, `!` or `?`; more than 300 characters).
  - E6 `Quantum widgets need a teleport check before merging. Nobody needs this evidence.`
- Then these are appended by hand, each after a blank line:
  - H1 `- **L-7 Rollbacks need a dry run.** Long evidence about rollbacks that nobody needs mounted.`
  - H2 is two lines: `- **2026-09-01** Multi-line claims carry their sentence` and `  across a line break. Trailing evidence stays in the file.`
- D is read from the file's E1 line.
- No lesson text contains `prompt` or `main`, which the hook's context always carries.

| | B | Assertion (name, then what is checked) |
|---|---|---|
| A1 | B1 | `dated lesson: felix lessons --for mounts a felix lesson entry as its date and its first sentence`. `--for "background jobs signals"` has a matched line exactly `  - **D** Background jobs ignore INT and QUIT signals.` |
| A2 | B1 | `dated lesson: and not the evidence after that sentence`. The same output has no `Evidence:`. **Control.** |
| A3 | B9 | `dated lesson: and not a lesson the context does not match`. The same output has no `Quantum widgets`. **Control.** |
| A4 | B2 | `dated lesson: a period inside a version or a file name does not end the sentence`. `--for "version slowly"` has a matched line exactly `  - **D** Version 3.2 of bash reads lib/lessons.sh slowly.` |
| A5 | B3 | `dated lesson: a bold claim after the date is mounted with its bold, and nothing after it`. `--for "record written inside invalidates"` has a matched line exactly `  - **D** **A record written inside the tree it describes invalidates itself.**`, and the output has no `The gate wrote it there`. |
| A6 | B4 | `dated lesson: a date repeated in bold after the date still mounts the claim sentence`. `--for "raise-only reader fails open"` has a matched line beginning `  - **D** ` that contains `A raise-only reader fails open through its own failure.`, and the output has no `The walker printed nothing`. |
| A7 | B5 | `dated lesson: a sentence that crosses a line break is mounted whole on one line, without what follows it`. `--for "multi-line claims carry"` has a matched line beginning `  - **2026-09-01** ` that contains both `Multi-line claims carry their sentence` and `across a line break.`, and the output has no `Trailing evidence`. |
| A8 | B6 | `dated lesson: a text with no sentence end is mounted from its first words, cut to 240 characters`. `--for "overflowing"` has a matched line beginning `  - **D** Overflowing claims keep going`. Without its two-space indent, that line is at least 200 and at most 240 characters. |
| A9 | B8 | `dated lesson: an L-numbered entry is still mounted as its bold span alone`. `--for "rollbacks"` has a matched line exactly `  - **L-7 Rollbacks need a dry run.**`, and no `Long evidence`. **Control.** |
| A10 | B1, B8 | `dated lesson: an L-numbered and a dated entry matched together are each mounted by their own rule`. `--for "rollbacks background jobs signals"` has both exact lines from A1 and A9. |
| A11 | B9 | `dated lesson: a context that matches nothing still says nothing matched`. `--for "zebra xylophone"` contains `nothing matched this context`. **Control.** |
| A12 | B10 | `dated lesson: the prompt hook mounts the dated lesson's claim sentence`. user-prompt is given `{"prompt":"why do background jobs ignore signals"}` in L/repo. Its `hookSpecificOutput.additionalContext`, read with python3's json, has a line exactly `  - **D** Background jobs ignore INT and QUIT signals.` |
| A13 | B10 | `dated lesson: and the hook exits 0 with no evidence sentence in its context`. Exit status 0, and the context has no `Evidence:`. **Control.** |
| A14 | B7 | `dated lesson: every mounted line is at most 240 characters`. Across the outputs of A1 to A12, every matched line and every line of the hook's lessons block is at most 242 characters with its indent. **Control.** |
| A15 | B11 | `dated lesson: felix lesson still writes the entry as a bold date and the text`. lessons.md has a line exactly `- **D** ` followed by E1's text. D has the shape `[0123456789]{4}-[0123456789]{2}-[0123456789]{2}`, and the E1 call exited 0. **Control.** |

### Part 1891: the handoff's tree and the seeded graph row

**Fixture H.**
- `H="$(mktemp -d "$TMP/b14h.XXXXXX")"`, resolved with `pwd -P`.
- Home `H/home`, project `hof`, memory `H/mem`.
- Each case gets a bound repository of its own under H, with its fixture set up after the commit, and M/hof/SESSION_HANDOFF.md removed (it lives inside H) before its `felix handoff`:

| Case | Fixture |
|---|---|
| HC | untracked `u.txt` |
| HD | `a.txt` edited, and `n.txt` staged with `_fx_git "$r" add n.txt` |
| HB | `_fx_git "$r" config status.branch true`, nothing changed |
| HBD | HB's config, and `a.txt` edited |
| HX | `a.txt` edited, then `printf garbage > "$r/.git/index"` |
| HW | clean; `PATH="H/bin:$PATH"`, where `H/bin/git` is `#!/bin/sh`, exits 1 printing nothing when any argument is exactly `status`, and otherwise execs the real git found by `command -v git` before PATH changed |
| HN | `H/plain`, a directory holding only `.felix` (`hof`), outside any repository |

| | B | Assertion (name, then what is checked) |
|---|---|---|
| A16 | B13 | `handoff tree: a tree whose only change is untracked is clean on the list and in the file`. HC prints `  [x] tree is clean`. Its block holds `Nothing. The tree is clean.` and not `u.txt`. **Control.** |
| A17 | B14 | `handoff tree: a tracked edit and a staged new file are dirty on the list and listed in the file`. HD prints the dirty line. Its block has lines ` M a.txt` and `A  n.txt`. **Control.** |
| A18 | B15 | `handoff tree: with status.branch on, a clean tree is clean on the list`. HB prints `  [x] tree is clean` and not `the tree is dirty`. |
| A19 | B15 | `handoff tree: and its file says the tree is clean, with no branch line`. HB's block holds `Nothing. The tree is clean.`, and no line in it is `## main`. |
| A20 | B16 | `handoff tree: with status.branch on, an edited tree's file lists the edit and no branch line`. HBD's block has ` M a.txt`, and no line `## main`. |
| A21 | B17 | `handoff tree: with an index git cannot read, the list says whether the tree is clean is not known, with git's reason`. HX's output has a line beginning `  [?] whether the tree is clean is not known: ` whose rest contains `fatal:` and `index`. |
| A22 | B17 | `handoff tree: and claims neither clean nor dirty`. HX's output has neither `[x] tree is clean` nor `the tree is dirty`. |
| A23 | B17 | `handoff tree: and its file says not known, with no list and no clean claim`. HX's block has a line beginning `Whether the tree is clean is not known: `, has no line beginning ```` ``` ````, and has no `Nothing. The tree is clean.`. |
| A24 | B17, B20 | `handoff tree: and felix handoff still writes the file and exits 0`. HX exits 0. Line 1 of the file is `# Handoff`, and line 3 begins `Regenerated `. **Control.** |
| A25 | B18 | `handoff tree: a status that fails with no words is not known, because git status did not finish`. HW's output has a line exactly `  [?] whether the tree is clean is not known: git status did not finish`, and no `[x] tree is clean`. |
| A26 | B19 | `handoff tree: a bound directory outside git is not known, never clean`. HN's output has a line beginning `  [?] whether the tree is clean is not known`, and no `[x] tree is clean`. Its block has no `Nothing. The tree is clean.`. |
| A27 | B20 | `handoff tree: felix handoff exits 0 in every case above`. The exit statuses of HC, HD, HB, HBD, HW and HN, joined by spaces, are `0 0 0 0 0 0`. **Control.** |

**Fixture G.**
- `G="$(mktemp -d "$TMP/b14g.XXXXXX")"`, resolved with `pwd -P`.
- Home `G/home`, project `gro`, whose `maintenance.tsv` is a copy of `$FROOT/harness/templates/maintenance.tsv`, and which has no `capabilities` file. Memory `G/mem`.
- Repositories, each committed through `_fx_git` with its own user and email. Graph means `graphify-out/graph.json` holding `{}`, with its mtime set by `touch -t`: `200001010000` for stale and `209901010000` for fresh.

| Repository | Fixture |
|---|---|
| G1 | bound (`.felix` committed) |
| G2 | bound, with a graph |
| G3 | holds a stale graph, with worktree G3w (`git worktree add`, new branch) |
| G4 | no graph, with worktree G4w |
| GU | `git init` only |
| GUg | `git init` only, then a graph written with no `touch -t` |
| GN | a plain directory, not in any repository |
| GNg | GN with a graph written with no `touch -t` |
| GD | one commit adding only `notes.md`, then a stale graph |

The library status is read as part 0450's `_mst` reads it, with `GIT_DIR` and `GIT_WORK_TREE` unset.

| | B | Assertion (name, then what is checked) |
|---|---|---|
| A28 | B21 | `seeded graph row: in a repository with no graph, felix maintenance reads graphify ok, check passed`. In G1, `felix maintenance` has a line beginning `  ok      graphify` that contains `check passed`. |
| A29 | B21 | `seeded graph row: and prints no DUE line for it`. That output has no line beginning `  DUE     graphify`. |
| A30 | B21 | `seeded graph row: an unborn repository with no graph reads ok too`. The library status for GU begins `ok<TAB>graphify<TAB>`. |
| A31 | B22 | `seeded graph row: the session start's due line does not name graphify there`. session-start is given `{"session_id":"b14g","source":"startup"}` in G1, with `CLAUDE_PLUGIN_ROOT="$FROOT"`. Its `additionalContext` has a line beginning `Maintenance due: `, and that line has no `graphify`. |
| A32 | B22 | `seeded graph row: and the badge counts what felix maintenance calls due`. The N in `systemMessage`'s `· N due` equals the count of lines beginning `  DUE ` in A28's output. **Control.** |
| A33 | B23 | `seeded graph row: a graph older than the last commit is due, check failed`. G2 with a stale graph: `felix maintenance` has a line beginning `  DUE     graphify` that contains `check failed`. **Control.** |
| A34 | B24 | `seeded graph row: a graph newer than the last commit is ok`. G2 with a fresh graph: a line beginning `  ok      graphify`. **Control.** |
| A35 | B25 | `seeded graph row: a worktree of a checkout holding a stale graph is due`. The library status for G3w begins `due<TAB>graphify<TAB>`. **Control.** |
| A36 | B25 | `seeded graph row: a worktree of a checkout with no graph is ok`. The library status for G4w begins `ok<TAB>graphify<TAB>`. |
| A37 | B26 | `seeded graph row: a directory outside git is due, since the check cannot ask`. The library statuses for GN and GNg both begin `due<TAB>graphify<TAB>`. Red on macOS for GNg; control on GNU find. |
| A38 | B26 | `seeded graph row: an unborn repository holding a graph is due`. The library status for GUg begins `due<TAB>graphify<TAB>`. Red on macOS; control on GNU find. |
| A39 | B27 | `seeded graph row: a graph no modelled commit is newer than is ok`. The library status for GD begins `ok<TAB>graphify<TAB>`. |
| A40 | B28 | `seeded graph row: its description names graphify-out/graph.json`. Field 4 of the template's `graphify` row contains `graphify-out/graph.json`. |
| A41 | B28 | `seeded graph row: it is still one five-column row, cadence 0, capability always`. Exactly one data row is named `graphify`. It has exactly 5 tab-separated fields, field 2 `0` and field 3 `always`. **Control.** |
| A42 | B28 | `seeded graph row: and felix maintenance refuses no check of the template`. A28's output has no `Checks refused`. **Control.** |

## 5. Parts

There are two new parts, written blind from this contract. Their lines go in tests/run, in this order, directly after `. "$HERE/parts/1600-felix-refuses-a-pattern-kill-blind.sh"` and before the `! alias .` line:

- `1890-dated-lessons-mount-their-claim-blind.sh`: fixture L, A1 to A15.
- `1891-handoff-tree-and-seeded-graph-row-blind.sh`: fixtures H and G, A16 to A42.

Each builds everything under its own `mktemp -d` in `$TMP`, and reads nothing another part leaves. Each runs alone and as a pair:
- `alone.sh <worktree> bwk 1890-... 1891-...`
- `alone.sh <worktree> gawk 1890-... 1891-...`

Each stays under 1,000 lines (part 1040). No assertion name may already be in assertions.tsv. The prefixes `dated lesson:`, `handoff tree:` and `seeded graph row:` appear nowhere in it today.

**Notes for the implementer.** These bind the fix, not the tests.
- **C026** changes `_felix_lessons_headline` alone, in lib/lessons.sh. It uses sed -E, POSIX awk, or bash `[[ =~ ]]` with the pattern in a variable, and digits spelled out.
- **C058** reads both places, felix:5259 and lib/memory.sh:177, through `_felix_git_read` with `status --porcelain --untracked-files=no`.
  - REASON comes from `felix_tree_why` or from the status call's own stderr. Its fallback is `git status did not finish`.
  - lib/memory.sh and felix must end no longer than they began.
- **C118** changes only the template row's check and description, plus the template's comment above it, which says why a project with no graph is not due.
  - An empty comparison time must never reach `find`. BSD find accepts `-newermt ""` and compares against a time of its own.
  - A failed `git rev-parse --git-common-dir`, or a failed `git log` for the comparison, makes the check fail. An empty answer from a `git log` that succeeded makes it pass.
- **Part 0450's comment** at lines 290-294 says its fixture mirrors the template's row. After this fix it mirrors `projects/felix/maintenance.tsv`'s row. Correct that comment and nothing else in 0450.

## 6. Out of scope

**C105, not fixed here.** Four reasons:
1. **Its sound fix needs a per-row fact this table does not hold.** That fact is what a routine reads: memory, the install, the graph or the network. A sixth column changes maintenance.tsv's row in `engine/harness/templates/schemas.tsv`, which is an escape table (lib/escape.sh:78), so the merge stops for the founder. This batch is declared founder-stop none.
2. **Extending an existing column does not hold either.**
   - Using the capability column would mean declaring a capability in `projects/felix/capabilities`. That is a commission table (lib/commission.sh:52), so it needs a grant re-stamp.
   - The check column runs only on cadence-0 rows (maintenance.sh:221). Giving it a meaning on clock rows changes every project's table format.
3. **No maintenance code knows it is in a cloud session.** No lib, hook, bin or CLI file reads `CLAUDE_CODE_REMOTE`. Batch b07 adds that to the Stop hook only. A blanket refusal of `--ran` in a cloud session would also refuse the routines a cloud session can do and truthfully record: all of the template's clock rows (dead-code, dependencies, docs-drift, constitution, architecture) read only the repository.
4. **The residue is narrow, and only one cloud run is recorded.**
   - Felix's own graphify row is due at every cloud start. It stays due on a checkout with no graph by the design part 0450:296 pins for the founder's home.
   - A landed cloud `--ran lessons` would read `ok` on the Mac for 30 days.

   It goes back to the founder as a decision on a "reads" column, to be carried as a batch of its own.

**Not fixed: not a defect.** These are the parts of C105's claim the verifier found already handled, each with its evidence:
- **deployed.** A cloud `--ran deployed` hides nothing. Every Mac gate runs the `deployed_engine` probe (projects/felix/probes.tsv:72) and the TASK_BLOCKING `engine_deployed` obligation (projects/felix/obligations.tsv:42), and both read the Mac's own install.
- **promote.** Recurring mistakes reach a session without the log: `felix next` rank 5 (lib/next.sh:182-204) and the Stop hook's `felix_guard_unrecorded` (hooks/stop:336) read the Mac's own mistakes.log.
- **graphify.** A cloud `--ran graphify` changes nothing, because a checked cadence-0 row never reads the log (maintenance.sh:221-245).
- **snapshot.** It is due on the Mac too, and each publish needs the founder's yes. A cloud session's inability to do it is not this defect.

**Left as they are, with why.**
- **`--ran graphify` wording.** It still prints `recorded a run of graphify` for a row its check decides. Once B21 holds, a project with no graph has no due graphify to clear, and changing what `--ran` says about checked rows is a wording change no defect here asks for.
- **The fix sketch's new case in part 0200 is not added.** The new assertions live in part 1890, so no name recorded for 0200 moves.
- **README.md:553 needs no edit.** It is true once B1 holds.
- **Abbreviations.** A claim containing an abbreviation followed by a space, such as `e.g. `, is cut there. The mounted line is still the start of the claim, and the file is one grep away. No recorded lesson was measured to lose its claim this way, and a dictionary of abbreviations is not worth its noise.
- **Handoff bookkeeping exclusions.** The handoff keeps not excluding Felix's own bookkeeping paths from its uncommitted list, unlike `felix_tree_dirty`. No defect here asks for that.

## 7. Founder PR

None. This batch changes no `.github/workflows` file, no deny or escape row, no commission grant and nothing published. `templates/maintenance.tsv` and `projects/felix/maintenance.*` are not escape or commission tables (lib/escape.sh:78, lib/commission.sh:52), and `templates/schemas.tsv` does not change.
