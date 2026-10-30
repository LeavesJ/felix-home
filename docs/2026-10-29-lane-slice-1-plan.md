# Situations Owed Implementation Plan

> **For agentic workers:** run this plan as the founder's engine-build Workflow: spec, blind assertions, red first, implementation, adversarial review, gate. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** Ship `felix situations`, which says, for a recorded tree or for a change, which situation rows the project owes, which rows the change brings in, blinds or retires, and what Felix could not look at, with no model, no key and no network.

**Architecture:** A new engine table, `engine/harness/templates/situations.tsv`, holds the classes. Three new libraries do the work. `lib/situations-read.sh` reads one side: either the recorded facts in `facts.log`, or a fresh reading of a scratch clone. `lib/situations.sh` evaluates each class with three values and compares base against head. `lib/situations-report.sh` prints the human report, the `--tsv` form that slice 2 reads, or the `--propose` drafts. `felix` gains one command, `cmd_situations`, which parses the flags and wires these together. Nothing is written outside its own scratch directory under `TMPDIR`, which it removes before it prints.

**Tech stack:** Bash 3.2, git, and awk that both BWK awk and gawk run. The tests are the suite's parts, run with `tests/run --part`.

**Spec:** `docs/2026-10-29-capability-lane-first-slices-design.md`, as corrected after the fact-check: §7 (slice 1), with §1 to §5, §6.3, §9, §10, §11 and §12. Through §7, also `docs/2026-10-19-intent-to-build-design.md` §9 and §10. The §11 calls this slice carries are cited where they change what is built: items 6 to 12, 21 to 32.

## Global Constraints

Line numbers in this plan are those at `01e24cfc` (0.49.313). Where code has moved since, follow the anchor the line names.

- "Bash 3.2 and git only: no jq, no python." (§4)
- "Only awk that both BWK awk (local) and gawk (CI) run. Part 1497's `_awk_names` lints `lib/`." (§4)
- "`LC_ALL=C` on every sort, comm, join and uniq (part 0992)." (§4)
- "`[[ =~ ]]` only inside a function that declares `local LC_ALL=C` (part 0996)." (§4)
- A function whose answer can depend on bash's own collation declares `local LC_ALL=C`, and a bracket of digits alone in bash's own pattern syntax is spelled out, `[0123456789]` (Rule 1, parts 0994 to 0998). So the class and source checks of C2 use `[[ =~ ]]` under `local LC_ALL=C`, or awk, never a `case` bracket with a range: under `en_US.UTF-8`, `case B in [a-z])` matches.
- "Flags go through `need_value` (`felix:394-396`), never a bare `shift 2`." (§4)
- "The engine names no project (constitution invariant 1). The gate's independence and ecosystem sections fail on it. Everything project-specific lives in a `projects/<p>/` table or arrives as an argument." (§4)
- The ecosystem section reads its words from every `_felix_dep_grep` token in `lib/detect.sh` (`:84-88`, `:97-99`) and from the `word` rows of `engine/harness/ecosystem.tsv`, less the `mute` row (`next`). So no new line in `felix` or in `lib/situations*.sh` may say python, pip, pytest, node, npm, rust, cargo, fastapi, anthropic or any other of those words. `rust` is also a capability name, so the libraries hard-code no capability name at all. (Engine rule, `projects/felix/gate.sh:412-555`. It scans the paths `bin/independence-scan --paths` prints, `felix`, `lib`, `hooks` and `bin`, so `templates/` is not scanned for these words.)
- "Offline (invariant 2) and deterministic (the intent design's §9 (d) and falsifier 2). Two runs with the network off and no key print identical bytes." (§4)
- "A check that cannot fail is not a check (invariant 5). Every new check is shown failing first." (§4)
- "Never delete a home or a memory root (invariant 6)." (§4)
- "Records go under the memory root (`felix_mem_dir`, `lib/resolve.sh:253-256`) or under `state/`." (§4)
- "Nothing is written into a governed repository: its refs, index, config and worktree list stay as they were." (§4)
- "`--change` never writes `facts.log`." (§4)
- "The lane never touches `lib/qualify.sh`, `lib/obligations.sh`, `lib/receipt.sh` or the landing actor's files": "`lib/automerge.sh`, `lib/green-*.sh`, `lib/land-table.sh`, `lib/notify.sh`, `lib/own.sh` and `lib/status-land.sh`; the `felix merge` and `felix land` code paths." (§4) Calling `felix_obligation_rows` is reading, not touching.
- "Each new table is a new file with one new `schemas.tsv` row, which is an addition and free. No column is added to an existing table, because that is a founder stop." (§4)
- "Nothing here blocks a merge, holds a release, comments on a pull request or writes an enforcing table." "No new GitHub writes, and no file in anyone's CI." (§3)
- Anti-goals (§3): "A project score, level or readiness grade." "Anything a person chats with." "'Could not look' shown as anything else. It is never printed or counted as DORMANT, as absent, or as 'owes nothing'." "A model on any of these paths."
- "No new engine branch while more than 10 engine PRs are open (direction row 17). The engine does not count this, so the builder checks `gh pr list` first." (§4)
- "Each PR bumps the patch version in the PR and puts it in the title. Each PR takes the next free patch slot at landing; on 10-29, 0.49.310 to 0.49.314 were claimed." (§4) This plan names no slot.
- "Every new `felix` command appears in `usage()`. Part 0480 (lines 400-417) asserts it only for commands in the main dispatch block (`felix:6594`)." (§4, §11 item 21) `felix situations` is dispatched in that block, not before the libraries load (as `audit`, `inventory` and `cost` are, `felix:249-272`), so part 0480 covers its usage line. Part 2400 asserts it as well.
- The suite also lints `felix` and every `lib/*.sh` for these, so the new code meets them:
    - no `$(git ... rev-parse ... HEAD ... || echo|printf ...)` fallback (part 0370);
    - no `local` line whose assignment reads a name declared earlier on that same line (part 0590);
    - no pipe into `grep -q`, `-m`, `-l` or `-L`, or into a grep whose stdout is `/dev/null` (part 0960);
    - every read of a `$proj/*.tsv` keeps an unended last row and is guarded by `[ -f ]` in its function (part 1030);
    - every porcelain `git diff` line carries `--no-ext-diff` and `--no-textconv` (part 1530).

- Suite manners (§4): "commit everything before the record; red and gate never share a worktree; at most four part runs at once, across the Mac; no whole-suite run while another session's record or gate holds the queue." On 10-29 the queue owner was the "Inventory next steps" session; Task 12 finds the current one.
- Engine rules met by the new files: every `mktemp` names a template under `TMPDIR` (part 1000). Each new library stays under 500 lines. `tests/run` stays at or under 500 lines (part 1040). It had 475 at `origin/main` `01e24cfc`; the lane's three slices add 22 (slice 0: 7, this slice: 8, slice 2: 7 with part 2360), and open PR #452 adds 2. Task 1 adds this slice's 8 to `origin/main`'s count and to the part and lib lines every open engine PR adds; if the total passes 500, stop before the blind stage and tell the queue owner: the driver needs room first. A part has at most 1,000 lines and is named `NNNN-[a-z0-9-].sh`.
- Commit messages carry no `Co-Authored-By` trailer and no attribution line. The lane's mark is the whole line `Felix-Lane: capability` (§6.2), which ends the body of every commit this plan makes, after a blank line below the subject. Every one is a non-merge commit, because `felix merge` copies only non-merge messages into the landing (`felix:2106-2107`). The branch takes `origin/main` by rebase, never by a merge. A landing whose message is replaced by hand drops the mark and counts as non-lane (§6.2).

## Contracts

The blind author reads the design, this section, and the seed table that Task 1 commits (`engine/harness/templates/situations.tsv`, which is data and part of the spec). Nothing else of the plan. The blind stage starts only once Task 1's commit holds that table and C12's seed list. The blind author is given that commit's id and reads both at it. Where this section says "decided in the plan", the design left the choice to the builder.

Notation: `\t` is one tab byte. Every output line ends in one newline. STATE words are `ACTIVE`, `DORMANT` and `UNKNOWN`. A side is `base`, `head`, or, in `--at` mode, `at`.

### C1. The command

```
felix situations [--at <tree> | --change [<base>..<head>]] [--tsv | --propose]
```

- With neither `--at` nor `--change`, it runs as `--at` on the newest recorded tree.
- `--at` takes a value through `need_value`, which refuses a missing or empty value only. So `--at --tsv` reads the tree `--tsv`.
- `--change` takes an optional range. The next argument is the range when it exists and does not begin with `-`.
- A range is split at its first `..`. It is a usage error when the value holds no `..`, when either half is empty, when the value holds `...`, or when the head half holds `..`. `HEAD~1..HEAD`, `main..HEAD` and `v1.2..v1.3` are ranges; `--change main` is a usage error.
- `--tsv` and `--propose` may not both be given. Neither may `--at` and `--change`. No flag may be given twice. Any other argument is a usage error, except `-h` or `--help` given first, which `felix` answers for every command but `monitor` and `help`: it prints `usage()` on stdout and exits 0 (`felix:6590-6592`). Main's `felix` already does this for `situations`, so a part's `-h` assertion compares stdout with `felix help`'s and also asserts that it holds C1's three usage lines; that reads red on main.
- Arguments are read left to right. A flag given twice, or one that conflicts with a flag before it, fails where it is read, before its value is looked at. The first argument that fails decides the exit and the message.
- The usage entry goes in `usage()` under "the toolbox", after the `felix obligations` line, as these lines (decided in the plan):

```
    felix situations [--at T | --change [B..H]] [--tsv | --propose]
                           what a change owes: the situation rows it owes, blinds and retires,
                           the rows already standing, and what could not be looked at; writes nothing
```

### C2. Exit status and messages

| Case | Exit | stdout | stderr |
|---|---|---|---|
| a report was printed, whatever it says | 0 | the report | empty |
| `--at` with no value, or an empty one | 1 | empty | `felix: felix: --at needs a value` (`need_value`'s own sentence) |
| any other usage error | 2 | empty | first line begins `felix: usage: felix situations` |
| no project governs the directory | 2 | empty | `resolve_or_die`'s existing sentence; with no binding at all it begins `felix: no project governs` |
| a side, or the situation table, could not be read at all | 3 | empty | one line: `felix situations: <what> could not be read: <why>` |
| the scratch directory could not be made | 3 | empty | one line: `felix situations: the scratch directory could not be made: mktemp -d failed under <tmpdir>` |
| TERM, HUP or INT during a run | 143, 129, 130 | (not judged) | (not judged) |

Design §7.7 names two non-zero cases, a usage error and a side that cannot be read. This plan adds three, decided here: a directory no project governs (2, `resolve_or_die`'s default, which every command but `felix repair` uses), a situation table that cannot be read (3), and a scratch directory that cannot be made (3). In none of them is there anything to report. `<tmpdir>` is `${TMPDIR:-/tmp}` as given.

**Order.** Usage errors are found first, then the governing project, then the situation table, then, in both modes, the scratch directory (C3.3). The first check that fails is the one line printed. After the scratch directory:

- In `--change` with a range: the base half, then the head half, then the scratch checkouts, base first.
- In `--change` with no range: HEAD (an unborn HEAD gives `felix situations: head could not be read: HEAD is not a commit here`), then the main ref, then the merge base, then the scratch checkouts, base first.
- In `--at`: the recorded tree.

The exit-3 lines, decided in the plan. `<rev>` is the text as given, `<memdir>` is `felix_mem_dir` of the project (`${FELIX_MEMORY:-$HOME/.felix/memory}/<project>`, with `FELIX_MEMORY` as given), and `<sha40>` is a full commit id.

- `felix situations: base could not be read: <rev> is not a commit here`. The same with `head`.
- `felix situations: the change could not be read: no main ref here: neither refs/remotes/origin/HEAD, refs/remotes/origin/main nor refs/heads/main names a commit`
- `felix situations: the change could not be read: <ref> and HEAD share no merge base`, where `<ref>` is the main ref itself, as a full ref name: for `refs/remotes/origin/HEAD`, its target `refs/remotes/origin/<x>`.
- `felix situations: base could not be read: the scratch checkout of <sha40> could not be made`. The same with `head`.
- `felix situations: the recorded tree could not be read: no run is recorded for tree <tree> in <memdir>/facts.log`. With `--at <tree>` given, this is always the sentence, an absent or empty log included. Rows whose tree is `unknown-tree` are never read, so `--at unknown-tree` gives this sentence too.
- `felix situations: the recorded tree could not be read: <memdir>/facts.log records no tree`. Printed only when no `--at` is given. This covers an absent log, an empty one, and one whose only trees are `unknown-tree`.
- `felix situations: the situation table could not be read: <path>: <why>`. `<path>` is the directory of the `felix` that runs, as `cd` into it and `pwd` print it, followed by `/templates/situations.tsv`. The `<why>` is one of the following, where `<n>` is the physical line number. The first failing line is named, with the first reason in this list that fits it:
    - `it is absent or unreadable`
    - `it holds no row`
    - `line <n>: <k> fields where a row has 5`
    - `line <n>: cell <k> is empty`
    - `line <n>: class '<c>' is not [a-z][a-z0-9_]*`
    - `line <n>: class '<c>' appears twice`
    - `line <n>: applies holds no term`
    - `line <n>: class_by_maturity '<v>' does not name each of prototype internal public-beta production once with a class of INFO ADVISORY TASK_BLOCKING RELEASE_BLOCKING AUTHORITY_BLOCKING`
    - `line <n>: source '<v>' is not miss:, candidate: or cite: and 12 lowercase hex digits`

**Reading the table**, decided in the plan.

- A line that matches `^[[:space:]]*(#|$)` in the C locale is not a row, as `lib/table.sh` defines one. So an empty line, a line of only spaces and tabs, and a comment, indented or not, are skipped. Every other line is a row, a last line with no newline included.
- Cells are split at each tab, and nothing is trimmed. `<k>` in `<k> fields` is their number.
- In `cell <k> is empty`, `<k>` counts from 1 and names the first empty cell. A cell of spaces is not empty.
- `applies` is split on runs of spaces, so no term is empty. A cell with no term left is `applies holds no term`.
- `class_by_maturity` is refused unless it is exactly four `maturity=CLASS` pairs joined by `,` with no space, naming each maturity once, in any order, and each CLASS is one of the five in upper case.

### C3. Readings

#### C3.1 Recorded readings (`--at`)

- The log is `<memdir>/facts.log`. A row is `stamp\ttree\tpredicate\tclass\tstate\tcount\tgrounds\tprobe` with an optional ninth field, `source` (`lib/facts.sh:94-96`). Rows of 8 and of 9 fields are both read. A line with fewer than 8 fields is ignored. Columns 4, 8 and 9 are not read.
- The newest recorded tree is the tree field of the last line, in file order, that has 8 or more fields and whose tree is not `unknown-tree`.
- The run read for tree `T` is decided by the last line, in file order, whose tree is `T`: its stamp and `T` name the run. The run's rows are every line with that stamp and that tree, in file order. An older run of the same tree is never read.
- A predicate that appears more than once in the run is read from its first line.
- The reading's probe rows are (predicate, grounds, state, count) from the run. The probe's own sentence is not in the log: `felix_probes_record` writes no detail field (`lib/facts.sh:94-96`). So a recorded reading has none, and C10 gives a fixed reason in its place. This is decided in the plan.

#### C3.2 The detector at a recorded tree

- The detector (`felix_detect`) runs on the live checkout only when the live checkout's tree id equals `T` (§11 item 9). The live tree id is the one `felix probes` records for this checkout as it stands.
- When it runs, the header's commit is the live checkout's HEAD. With an unborn live HEAD the commit is `-`, and the detector still runs.
- Otherwise the detector is not run, and the commit is `-`.

#### C3.3 Scratch readings (`--change`)

- **The range.** A given `<base>..<head>` has each half resolved in the live repository to a commit. With no range, head is HEAD, and base is the merge base of the main ref and HEAD. The main ref is the target of `refs/remotes/origin/HEAD` when it is a symbolic ref to a `refs/remotes/origin/<x>` that names a commit, as slice 2's plan reads it; otherwise `refs/remotes/origin/main` when it names a commit; otherwise `refs/heads/main`.
- **The method, decided in the plan.**
    1. In both modes, one scratch directory is made, `mktemp -d "${TMPDIR:-/tmp}/felix-situations.XXXXXX"`, with the traps under **Removal**. Every reading and evaluation file the run writes lives in it. Only `--change` clones into it.
    2. Each side gets its own clone under it, `<scratch>/base` and `<scratch>/head`.
    3. Each clone is made with `git clone --shared --no-checkout --template=` from the repository's common git directory. So a linked worktree and a main checkout clone alike.
    4. Then `git checkout --detach -q <sha>` runs in the clone.
    5. Both commands run with no global and no system git config, with `GIT_NO_LAZY_FETCH=1`, and with stdin from `/dev/null`. So no hook, template, filter driver or lazy fetch from the person's git config runs.

- **The tree id.** A side's tree id is `felix_tree_id_on <clone> <sha> <home>`, taken right after the checkout and before anything runs in the clone. It equals the id that `felix probes` records for a clean checkout of the same commit with no untracked file.
- **What is read.** The detector and every row of the project's current `probes.tsv` (from the Felix home) then run in the clone (`felix_probes_run <proj> <clone>`), the same on both sides (§11 item 8). Each probe row keeps its detail sentence (`lib/probes.sh:255-357`). Each side's probes and detector run with `TMPDIR=<scratch>/tmp-<side>`, a directory made inside the scratch directory, so what a project's probe leaves in its temporary directory is removed with the scratch.
- **Tracked content only.** The live checkout's uncommitted edits and untracked files are read by neither side.
- **Removal.** The scratch directory is removed before the first byte of the report is written, in both modes. It is also removed on exit 3 after it was made, and on TERM, HUP and INT, which then exit 143, 129 and 130.

#### C3.4 What never changes, in every mode

- Nothing under the governed checkout has an mtime newer than a marker touched before the run. That covers its working tree and its `.git`, and for a linked worktree also the repository's common git directory. `felix situations` runs its git reads of the live checkout with `GIT_OPTIONAL_LOCKS=0` (decided in the plan), so even the index's stat cache is left alone.
- `git for-each-ref`, every worktree's HEAD, `git worktree list --porcelain`, the config file's bytes, `git ls-files -s` and `git status --porcelain` are unchanged.
- Nothing under the memory root changes, `facts.log` included, byte for byte.
- Nothing under the Felix home changes.
- `TMPDIR` holds afterwards exactly what it held before. That is true on exit 0, on exit 3, on 129, 130 and 143, and when the reader closes the pipe early (`| head -1`).
- No `gh`, `curl`, `wget`, `ssh`, `nc` or `claude` process is started. A command named in a project's own `probes.tsv` is the project's.

### C4. Terms and class states

A class's `applies` is a space-separated list of terms, and all of them must hold. At one reading, each term is true, false or undecided.

- **Grounding probes.** For a capability `<c>` on one side, the grounding rows are the reading's probe rows whose grounds field is exactly `<c>`, one per predicate (its first row), in reading order. A predicate that the project's current `probes.tsv` grounds at `<c>`, and that has no grounding row for `<c>` in the reading, is a grounding probe with no reading. That includes a predicate whose recorded row grounds another capability. A grounds cell of `-` or empty grounds nothing.

- **`probe:<c>=<s>`** (§7.2, §11 item 23). `<c>` is the text between `probe:` and the first `=`, and is not empty. `<s>` is one of `found`, `empty`, `blind`, `unknown` and `not-applicable`. It is decided in this order:
    1. Any grounding row reads `<s>`: true.
    2. Otherwise, any grounding row reads `blind` or `unknown`, or a grounding probe has no reading, or no probe grounds `<c>` at all: undecided.
    3. Otherwise: false. That includes every grounding row reading `not-applicable` when `<s>` is not `not-applicable`.

- **`cap:<c>`** (§11 items 10 and 24). It is decided in this order:
    1. Any grounding row reads `found`: true.
    2. Otherwise, any reads `blind` or `unknown`, or a grounding probe has no reading: undecided. The probe with no reading is decided in the plan, as §7.4 decides it for probe terms: a probe that grounds `<c>` and was not read is never left to the detector.
    3. Otherwise, any reads `empty`: false.
    4. Otherwise, when there is no grounding row or every one reads `not-applicable`, the detector decides. True when it ran and names `<c>`. Undecided when it ran and does not name it, and undecided when it did not run. Detector silence is never false.

- **`env:maturity>=<v>`**, where `<v>` is a maturity.
    - The declared value is project.json's `"maturity"` string, read from the Felix home's `projects/<p>/project.json` with `felix_json_str`. It is the same value on both sides.
    - The order is `prototype < internal < public-beta < production`, as v3.2's risk envelope lists them; no engine code orders them (§7.2, §11 item 25).
    - True or false by rank. Undecided when nothing is declared, or when the declared value is not one of the four. Such a term is then also listed as unbound, because §7.8 counts an axis with no value as an unbound predicate. An empty or absent `"maturity"` string is "declares no maturity".

- **Unbound terms.** These are undecided, and are listed in the residual as unbound:
    - any term in another form: a `probe:` term with no `=`, an empty `<c>` or a state outside the five, an `env:` axis other than `maturity`, an `env:maturity>=` value outside the four, an empty `cap:` name, or no known prefix;
    - a well-formed `probe:<c>=<s>` whose `<c>` no row of the project's current `probes.tsv` grounds (§7.8). It is evaluated from the reading as above, and listed as unbound as well.

- **The class.** It is ACTIVE when every term is true. It is DORMANT when any term is false. Otherwise it is UNKNOWN. A false term settles the class even when another term is undecided.

### C5. Verdicts

In `--change`, each class gets one verdict token from its two states. The tokens are decided in the plan, with "owed (base could not look)" carried as `owed`, base `UNKNOWN`.

| Head | Base | Token |
|---|---|---|
| ACTIVE | DORMANT | `owed` |
| ACTIVE | ACTIVE, and a grounding reading differs | `owed` |
| ACTIVE | ACTIVE, and the readings are equal | `standing` |
| ACTIVE | UNKNOWN | `owed` |
| UNKNOWN | ACTIVE or DORMANT | `blinded` |
| UNKNOWN | UNKNOWN | `could-not-look` |
| DORMANT | ACTIVE | `retired` |
| DORMANT | DORMANT or UNKNOWN | `none` |

**When a grounding reading differs.** Compare base and head term by term, in applies order. Any term that differs makes the class differ.

- A `probe:` or `cap:` term differs when the sequence of its grounding rows' (predicate, state, count), not-applicable rows included, differs between the sides (§7.5). A grounding row on one side only also differs.
- A `cap:` term also differs when step 4 decided it on either side and the detector's answer (names it, does not, or was not run) differs between the sides.
- An `env:` term never differs.
- In `--change` the second kind never decides a verdict alone: both sides run the same `probes.tsv`, and the detector always runs. So a `cap:` term true on both sides is either decided at step 4 on both, where the detector names it on both, or at step 1 on one side and step 4 on the other, where the first kind already differs. Part 2420 covers the first kind, with one `probe:` case and one `cap:` case, and asserts nothing about the second.

**In `--at` mode**, the token follows the one state (§7.7, §11 item 27): ACTIVE is `standing`, UNKNOWN is `could-not-look`, and DORMANT is `none`.

The token order is the one §7.7 sorts by: `owed`, `blinded`, `retired`, `standing`, `could-not-look`, `none`.

### C6. Ids

- A class's id is `owed:` followed by the first 12 hex digits that `git hash-object --stdin` prints, run outside any repository, for the bytes `<class>\t<project>\t*` with no trailing newline. `<project>` is the basename of the project directory, the name under `projects/`.
- A part computes the expected id the same way from `$TMP`: `printf '%s\t%s\t%s' paid_ingress web1 '*' | git hash-object --stdin | cut -c1-12`.
- The id is the same in `--at`, in `--change` and across runs.

### C7. Grounds, readings and witness

**The grounds string.** One item per term, in applies order, joined by `, ` (comma and space).

- `probe:<c>=<s>` gives every grounding row in reading order as `<pred> <state> (<c>)`, not-applicable ones included, then `<pred> no reading (<c>)` for each grounding probe with no reading, in `probes.tsv` order, all joined by `, `. With neither, it gives `<c> no probe`.
- `cap:<c>` gives the same items, less the not-applicable rows. When none is left, it gives `<c> detected`, `<c> not detected` or `<c> detector not run`.
- `env:maturity>=<v>` gives `maturity <declared>`, or `maturity undeclared`.
- An unbound term in another form gives `<term> unbound`.
- For fixture (a), whose class applies `cap:api cap:llm`, the string is exactly `http_route found (api), llm detected`.
- So the grounds string names every term, the undecided ones included (`<pred> blind (<c>)`, `<pred> unknown (<c>)`, `<pred> no reading (<c>)`, `<c> no probe`, `<c> not detected`, `<c> detector not run`, `maturity undeclared`). That is how the report names an undecided term beside a DORMANT class (§7.4): always in `--tsv`, and in the human report only for a class that C9 puts in a section, which is in `--change`, on `owed`, `blinded` and `retired` rows. In `--at` a DORMANT class is in no human section, so it is named in `--tsv` only.

**The readings string.** `<pred>=<state>/<count>` for each grounding row of the class's `probe:` and `cap:` terms, not-applicable ones included. The items are in first-use order, without repeats, joined by one space. It is `-` when there are none.

**The witness.** When a class is DORMANT on a side, look at its first false term in applies order.

- A `probe:` term gives `<pred> <state>` of the first grounding row in reading order that reads `empty`, or else of the first grounding row.
- A `cap:` term made false at step 3 gives `<pred> empty`, from the first grounding row in reading order that reads `empty`.
- An `env:` term gives no witness.

### C8. `--tsv`

- One line per class in the table, every class:

```
<id>\t<class>\t<verdict>\t<base>\t<head>\t<base_grounds>\t<head_grounds>\t<owes>
```

- `<base>` and `<head>` are STATE words. In `--at` mode `<base>` and `<base_grounds>` are `-`, and `<head>` and `<head_grounds>` are the reading's. `<owes>` is the table's cell, byte for byte.
- Then the residual lines (C10): `residual\t<kind>\t<name>\t<why>`.
- **Order** (§7.7, §11 item 27). Class lines first, by token order (C5), then by id, compared as bytes. Then the residual lines, unique, compared as whole lines in bytes, which orders them by kind, then name, then why.
- No header line, no count line, no blank line.
- Identical bytes under `LC_ALL=C` and under `LANG=en_US.UTF-8` with `LC_ALL` unset.

### C9. The human report

```
situations for <project>
  base  <sha40>  tree <tid>  scratch checkout, tracked content only, current probes.tsv
  head  <sha40>  tree <tid>  scratch checkout, tracked content only, current probes.tsv

owed
  <id>  <class>  <BASE> -> <HEAD>
    grounds  base: <grounds>; head: <grounds>
    readings  base: <readings>; head: <readings>
    witness  base: <witness>
    owes  <owes>

blinded
  none

retired
  none

standing
  none

residual
  <kind>  <name>  <why>

examined <N>, active <A>, dormant <D>, could not look <U>
```

- **Header.** `<project>` is the basename of the project directory, as in C6. How each side was read is in the header only (§7.8, §11 item 28). In `--change` it is the two lines shown. In `--at` it is one line, `  at  <sha40>  tree <tid>  recorded <stamp>  detector run on this checkout` when the detector ran (`<sha40>` is the live HEAD, or `-` when it is unborn, C3.2), and otherwise `  at  -  tree <tid>  recorded <stamp>  detector not run: this checkout is not at this tree`.
- **Sections.** In `--change`: `owed`, `blinded`, `retired`, `standing`, `residual`, in that order (§7.7). In `--at`: `standing`, then `residual`. ACTIVE prints as standing, UNKNOWN as could not look, and DORMANT is counted (§7.7, §11 item 27). Every line's layout is decided in the plan.
    - Each section header is preceded by one blank line.
    - A section with no row prints `  none`. A residual with no line prints `  none: nothing undecided, unbound or without a row`, since the residual is never empty without saying why (§7.8).
    - In `--change`, classes whose token is `could-not-look` or `none` are in no section. In `--at`, UNKNOWN and DORMANT classes are in no section. These appear only in `--tsv`, in the count, and, when UNKNOWN, in the residual.
    - Rows within a section are ordered by class name, compared as bytes.

- **A row.**
    - In `--change` the row line is `  <id>  <class>  <BASE> -> <HEAD>`, then the lines `    grounds  `, `    readings  `, zero to two `    witness  <side>: <witness>` lines (base first; one for each side where the class is DORMANT and C7 gives a witness), and `    owes  <owes>`.
    - In `--at` the row line is `  <id>  <class>  ACTIVE`, with `    grounds  <grounds>`, `    readings  <readings>` and `    owes  <owes>`.

- **Residual.** The residual section lists the same lines as `--tsv`, in the same order, as `  <kind>  <name>  <why>`.
- **Count line.** `<N>` is the number of classes in the table, and `<A>`, `<D>` and `<U>` count them by state at head, or at the reading. It is preceded by one blank line. It is the last line unless `--propose` was given.

### C10. The residual

Three kinds, which sort in this order as bytes (C8). How each side was read is not a residual line; it is in the header (§7.8, §11 item 28).

**1. `could-not-look`.**

- Name: the class. Why: `<side>: <term>: <reason>`.
- There is one line per side on which the class is UNKNOWN, per undecided term. They print in C8's order, as whole lines in bytes, not in applies order. So `blinded` gives head lines, `owed` and `none` with base `UNKNOWN` give base lines, and `could-not-look` gives both.
- The reasons:
    - A `probe:` or `cap:` term with a grounding row that reads `blind` or `unknown` (the first in reading order):
        - from a scratch reading, `<pred> read <state>: <the probe's own sentence>`;
        - from a recorded reading, `<pred> read <state> when recorded; the fact log keeps no sentence`.

    - Otherwise, a `probe:` or `cap:` term with a grounding probe that has no reading (the first in `probes.tsv` order): `no reading of <pred> on this side`.
    - A `probe:` term that no probe grounds: `no probe grounds <c>`.
    - A `cap:` term at step 4:
        - no grounding row, detector silent: `no probe grounds <c> and the detector does not name it`;
        - every grounding row not-applicable, detector silent: `every probe grounding <c> is not-applicable and the detector does not name it`;
        - the same two with `the detector was not run: this checkout is not at this tree` in place of `the detector does not name it`, when the detector did not run.

    - An `env:maturity>=<v>` term with `<v>` one of the four:
        - `project.json declares no maturity`;
        - `project.json declares maturity '<m>', which is not one of prototype internal public-beta production`.

    - An unbound term in another form, an `env:` term on another axis included: `not a term this slice can evaluate`.

**2. `no-row`.**

- Name: a capability that no class's applies uses, and that the detector named on a side read, or that the grounds cell of some probe row of a side read names exactly, whatever that row's state.
- Only a well-formed `probe:<c>=<s>` or `cap:<c>` term uses `<c>`. A term in another form uses no capability.
- There is one line per capability. Why: `named by <sources>`. The sources are the union over every side read: `the detector` first, when it named the capability on any side, then `probe <pred>` for each grounding predicate, in byte order, joined by `, `.

**3. `unbound`.**

- Name: the term as written.
- Why:
    - for a well-formed `probe:<c>=<s>` whose `<c>` no row of `probes.tsv` grounds, `no row of probes.tsv grounds <c>`;
    - for an `env:` term on another axis, `only env:maturity can be evaluated in this slice`;
    - for a well-formed `env:maturity>=<v>` while nothing is declared, `project.json declares no maturity`;
    - for the same while the declared value is not one of the four, `project.json declares maturity '<m>', which is not one of prototype internal public-beta production`;
    - for any other form, `not a term this slice can evaluate`.

- There is one line per distinct term across all classes.

### C11. `--propose`

**Placement.** In the human report, after the count line, `--propose` adds one blank line and a `proposed` section. The section lists every class that is ACTIVE at head, or at the reading, and whose name is not an obligation name that the project's `obligations.tsv` admits. Admitted means the first cell of a row `felix_obligation_rows` returns. The classes are in byte order of name. With none, the section prints `  none`.

**Each proposal:**

```
  <id>  <class>  <grounds>
    class  <CLASS>  <note>
    row  <class>\t<CLASS>\tunknown\t-\texit 2\t<preds>\t<owes>
    admit  <command>
```

- **`<CLASS>`.** The class that `class_by_maturity` pairs with the declared maturity. The `<note>` is then `maturity <m>`. When no maturity is declared, or the declared one is not one of the four, it is the strictest class the cell names, in the order `INFO < ADVISORY < TASK_BLOCKING < RELEASE_BLOCKING < AUTHORITY_BLOCKING`. The `<note>` is then `maturity undeclared: the strictest class this row names`, or `maturity '<m>' is not one of prototype internal public-beta production: the strictest class this row names`.
- **The `row` line.** Its seven cells are separated by real tab bytes. The pathway `unknown`, the applies `-` and the evidence `exit 2` are decided in the plan: no checker exists in this slice, so the draft says so. Admitted at a blocking class, the row holds on authority: its pathway `unknown` blocks whatever its evidence reads, before any exception is consulted (`lib/obligations.sh:249`). So it keeps blocking until someone writes an evidence contract and also changes the pathway. The founder decides that at admission.
- **What admitting the draft as printed does**, stated here and in the PR body. The applies `-` makes the row apply at every tree (`lib/obligations.sh:27-29`), so it does not go dormant when the class's surface is removed (intent design §10, falsifier 10). Its pathway `unknown` makes it block at any blocking class at every tree, and its evidence `exit 2` reads cannot-examine (`lib/obligations.sh:160`). A TASK_BLOCKING exception does not clear it. The draft is a starting row the founder edits at admission (slice 4), not a row to admit unchanged.
- **`<preds>`.** The predicates the class's true terms rest on: for a `probe:<c>=<s>` term, its grounding rows that read `<s>`; for a `cap:` term made true at step 1, its grounding rows that read `found`. They are in first-use order, without repeats, and only those the project's current `probes.tsv` defines. Joined by `,`, or `-` when there are none. For fixture (a) it is `http_route`.
- **`<command>`.** One line, where `H` is `FELIX_HOME` as given, `P` is `H` followed by `/projects/<p>`, and every quoted value has each `'` written as `'\''`. Parts give `FELIX_HOME` as an absolute path. The line: `printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' '<class>' '<CLASS>' 'unknown' '-' 'exit 2' '<preds>' '<owes>' >> 'P/obligations.tsv' && git -C 'H' add -- 'P/obligations.tsv' && git -C 'H' commit -q -m 'obligations: admit <class>' -- 'P/obligations.tsv'`

**Limits.**

- `--propose` writes nothing. C3.4 holds for it.
- `--propose` with `--tsv` is a usage error.
- In `--change`, proposals read the head side.

### C12. The situation table, its schema row, the seed and its siblings

**The file.** `engine/harness/templates/situations.tsv`.

- Comment lines begin with `#` at column 0. One comment line is `# class\tapplies\towes\tclass_by_maturity\tsource`.
- Each row has exactly five non-empty cells, in printable ASCII, and the file ends in a newline. It passes `lib/table.sh`'s shapes (`engine/harness/bin/schema-check`).
- `felix situations` reads it from the `templates/` directory beside the `felix` that runs.

**The schema row**, inserted after the `discover-rules.tsv` row (`templates/schemas.tsv:130`), with a comment above it saying that, empty or absent, `felix situations` exits 3:

```
situations.tsv\ttree\tclass applies owes class_by_maturity source\trefused
```

**The cells.**

- `class` matches `^[a-z][a-z0-9_]*$` and is unique, so it can serve as an obligation name.
- `applies` holds one or more terms, every one in a form C4 evaluates, and no `probe:` term on `blind` or `unknown`: a class must never be ACTIVE because Felix could not look (§3). It holds at least one `probe:` or `cap:` term, since only such a term can be made false by a commit (siblings, below).
- `class_by_maturity` names each of `prototype`, `internal`, `public-beta` and `production` exactly once, as `maturity=CLASS` pairs joined by `,`, as the design's example does (§7.2). Each CLASS is one of `obligations.tsv`'s classes, and the classes do not decrease as maturity rises. That each is named once, and that the classes do not decrease, are decided in the plan.
- `source` is `miss:`, `candidate:` or `cite:`, then the first 12 hex digits of `git hash-object --stdin` over the recorded miss, the survey candidate's row or the cited passage. The prefix says which of the three it is (§7.2, §11 item 26). The passage itself is kept in the branch's handoff note, never in the table.
- No name of a directory under the home's `projects/`, other than `felix`, appears anywhere in the file, comments included, compared without regard to case. (`felix` is the engine's own name, which `bin/independence-scan` exempts too.)
- At run time the engine refuses exactly C2's list. The other rules here (no `probe:` term on `blind` or `unknown`, at least one `probe:` or `cap:` term, classes that do not decrease with maturity, printable ASCII, no project name) are checked by part 2400 on the shipped seed only. A substituted table that breaks one of them is read, not refused: a term in another form is unbound (C4), and a decreasing cell is printed as written.

**The seed** holds six to eight rows. The rows are drafted in Task 1, within §7.2's rules, from the obligation candidates the survey proposed (Elenchus's and Veldra's `candidates.tsv`; proposals, not recorded misses), any recorded miss, and v3.2 §10. Task 1 commits them before the blind stage. Slice 2 seals this file by hash before its first count (§8.5), so a row changed after that is a new sealed version. The seed must contain:

- **R1 (paid ingress).** A class named `paid_ingress` whose applies is exactly `cap:api cap:llm`, so it has no `env:` term (§7.2, §11 item 25), and whose owes names a request bound and a spend bound, in words that hold `request` and `spend`.
- **R2 (a second HTTP class).** At least one more class whose applies holds `cap:api`. A class is HTTP-keyed when its applies holds `cap:api`.
- **R3 (loopback binding).** At least one class whose owes is a bind to loopback only, in words that hold `loopback`. Its applies holds a `probe:<cap3>=found` term, where `<cap3>` is a capability whose grounding probe enumerates listeners meant for one machine's own use, and it holds no `cap:api` term. So in a node that serves a cluster on every interface, that probe reads `empty` and the class is DORMANT.
- **R4 (no web term).** At least one class whose applies holds no term on `api` or on `<cap3>`, and which a bash repository and a cargo workspace can both make ACTIVE and DORMANT. Task 1 names one of them as the R4 class, the one parts 2430 and 2450 read.

**The seed as committed.** Task 1 fills this list in the commit that adds the table, before the blind stage:

- `<cap3>`: (filled by Task 1)
- each class, by name, with the items of R1 to R4 it meets, and which one is the R4 class: (filled by Task 1)

**Part 2400 checks R1 to R4 as follows**, comparing owes without regard to case:

- R1: a row whose class is `paid_ingress`, whose applies is exactly `cap:api cap:llm`, and whose owes holds `request` and `spend`.
- R2: another row whose applies holds the term `cap:api`.
- R3: a row whose applies holds `probe:<cap3>=found` and no `cap:api`, and whose owes holds `loopback`.
- R4: the named R4 class's applies holds no term on `api` or on `<cap3>`.

**Siblings (falsifier 6).** For every row the shipped table holds, part 2460 builds, in a fixture project with an invented name, one repository with two commits that differ only in the surface the row stands on.

- The project's `probes.tsv` grounds every capability the row's `probe:` terms name. Each `cap:` term is grounded either by a probe row or by a root-level manifest the detector reads. `project.json` declares a maturity when the row has an `env:` term.
- The surface the commit removes is one `probe:` or `cap:` term, grounded in the fixture's `probes.tsv` by a probe that reads `empty` at `<without>` (it prints nothing and its witness exits 1), never by a manifest alone. Detector silence is never false (C4), and the maturity is the same on both sides.
- `--change <with>..<without>` reads the class `retired`, with a `    witness  head:` line.
- `--change <without>..<with>` reads it `owed`.
- A ledger in the part asserts that every class in the shipped table, at least six, was read both ways.

### C13. Fixtures: pointing the engine at a fixture

- **Engine.** Use `$FROOT/harness/felix` (`$FELIX`) for parts that use the shipped seed. For a substituted table, use a copy: `cp -R "$FROOT/harness" "$X/harness"`, then write `$X/harness/templates/situations.tsv`.
- **Home `H`.** `H/projects/<p>/project.json` as `{"name":"<p>","remote_match":"example.invalid/<p>","gate":"true"}`, plus `"maturity":"<m>"` when a part needs one. Then `H/projects/<p>/CLAUDE.md`, `H/projects/<p>/probes.tsv` (`predicate\tgrounds\twhen\tprobe\twitness`), and an optional `obligations.tsv`. `H` needs nothing more: no `harness/` directory, and no git repository except where RF5 makes one. `felix` sets `FELIX_HOME_DIR` from `FELIX_HOME` itself (`felix:377`), so a run sets only `FELIX_HOME`. C2's empty stderr is asserted of `felix situations`; no part judges `felix probes`'s stderr.
- **Checkout `C`.** Made with `git init -q -b main`, holding a committed `.felix` whose content is `<p>`. Commits may pin `GIT_AUTHOR_DATE` and `GIT_COMMITTER_DATE`. The main ref is `refs/heads/main`. A feature branch makes the default range.
- **Memory root `M`.** The facts are at `M/<p>/facts.log`. A part may write rows by hand, in the C3.1 format, or record them with `felix probes`, which records the live tree.
    - A hand-written stamp has the form `2026-10-29T12:00:00Z` and is printed as written. A tree id is any text without a tab, compared as bytes.
    - `felix probes` records one row per `probes.tsv` row it reads, `blind` and `unknown` rows included, and exits 0 when not given `--gate`. With no `probes.tsv`, or none it reads, it records nothing and exits 1. So a fixture read with `--at` after `felix probes` holds at least one probe row.

- **A run.** `( cd C && env FELIX_HOME=H FELIX_MEMORY=M TMPDIR=T <engine> situations ... ) >out 2>err; rc=$?`, where `T` is a fresh empty directory per run. A run that compares the live tree runs `felix probes` first, in the same environment, with nothing changed between the two.
- **The clock.** Slice 1 reads no clock. No current date or time appears in any output, and the only time printed is a recorded stamp. The suite pins no clock for this slice.
- **The network.** Stubs for `gh`, `curl`, `wget`, `ssh`, `nc` and `claude` go first on `PATH`. Each appends its argv to a log and exits 1. `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GH_TOKEN` and `GITHUB_TOKEN` are unset. The log must stay empty.
- **Detector facts** (existing engine behaviour, `lib/detect.sh:17-113`), for fixture design. The detector reads manifests for some capabilities and only file or directory presence for the rest (§7.4). C10's `no-row` lines name what it names, so a fixture holds no file below unless the assertion means it to.
    - Manifest tokens, matched as case-insensitive substrings. `api`: `fastapi flask django express next fastify starlette`. `llm`: `anthropic openai langchain llama-index llamaindex mistralai cohere ollama google-generativeai litellm instructor dspy transformers`. `database`: `supabase prisma alembic sqlalchemy drizzle typeorm`. `observability`: `sentry opentelemetry datadog`. `billing`: `stripe`. `e2e`: `playwright cypress selenium puppeteer`.
    - The manifests read are `pyproject.toml`, `requirements.txt`, `requirements/*.txt`, `setup.cfg`, `Pipfile`, `package.json`, `Cargo.toml`, `go.mod`, `Gemfile`, `composer.json`, `build.gradle`, `pom.xml` and `*.csproj`, at the root only. A workspace member's manifest is never read, and `axum` is no token.
    - Paths at the root. `ci`: `.github/workflows/*.yml` or `*.yaml`, `.gitlab-ci.yml`, `azure-pipelines.yml`. `deploy`: `Dockerfile`, `Dockerfile.*`, `docker-compose.yml`, `Procfile`, `fly.toml`, `vercel.json`, `render.yaml`, `railway.json`, `app.yaml`, `k8s`, `kubernetes` or `helm`. `iac`: `*.tf`, `terraform`, `infra/*.tf` or `pulumi.yaml`. `database`: `migrations`, `supabase/migrations`, `alembic.ini` or `prisma/schema.prisma`. `tests`: a `tests`, `test`, `spec` or `__tests__` entry. `rust`: a `Cargo.toml`. `secrets`: `.env.example` or `.env.sample`.
    - `frontend`: `package.json`, or three or more tracked files (`FELIX_FRONTEND_MIN`) ending `.js`, `.jsx`, `.ts`, `.tsx`, `.vue`, `.svelte`, `.sass`, `.scss` or `.css`, case-insensitively, that are not under a `doc`, `docs`, `documentation`, `deck`, `decks` or `slides` directory (as `origin/main` has it since #475).
    - Avoid incidental tokens: `nextest` names api.

- **Probe states** (`lib/probes.sh:255-357`), for fixture design.
    - A `when`, a probe and a witness each run as `bash -c` from the checkout root (the clone's, in a scratch reading), with stdin from `/dev/null`, stderr discarded and no time limit. A scratch reading runs `probes.tsv`'s rows in file order, skipping a row with fewer than 4 or more than 5 fields, or an empty predicate or probe cell.
    - The count is the number of non-blank lines for `found` and for a partial `unknown`, and 0 for every other state.
    - `when` exits 1: `not-applicable`. `when` exits 127: `unknown`, ``a command in the `when` test does not exist here, so whether this row applies is not known``. Any other non-zero `<rc>` but 126: `unknown`, ``the `when` command exited <rc>, which is neither yes nor no, so whether this row applies is not known``.
    - The probe or its `when` exits 126: `unknown`, `the checkout could not be entered, so nothing was asked`.
    - The probe exits 0 with at least one non-blank line: `found`, `<n> member(s) enumerated`.
    - The probe exits 127: `unknown`, `a command in the probe does not exist here, so nothing could be looked at`.
    - `<n>` lines and a non-zero exit `<rc>` other than 126 and 127: `unknown`, `the probe printed <n> member(s) and then exited <rc>, so the enumeration is partial`.
    - Nothing, and no witness: `unknown`, `the probe found nothing and no witness says whether that is true`, or, when the probe exited `<rc>`, `the probe exited <rc> and no witness says whether the surface exists`.
    - Nothing, and the witness exits 0: `blind`, `the witness proves this surface exists and the probe enumerated none of it`. When the probe exited `<rc>`: `the witness proves this surface exists and the probe exited <rc>`.
    - Nothing, and the witness exits 1: `empty`.
    - Nothing, and the witness exits 126 or 127: `unknown`, `a command in the witness does not exist here, so absent and blind cannot be told apart`. Any other `<rc>`: `unknown`, `the witness exited <rc>, which is neither yes nor no, so absent and blind cannot be told apart`.

- **Suite helpers.**
    - `ok NAME`, `bad NAME [DETAIL]`, `is NAME GOT WANT`, `has NAME HAYSTACK NEEDLE` and `skip NAME WHY`.
    - `_fx_cd DIR` (in a subshell) and `_fx_git DIR ARGS...` for every fixture git write; `_copy_content SRC DEST`.
    - `$TMP`, `$REAL_HARNESS`, `$FROOT` and `$FELIX`.
    - `_locale_bytes_vars` (`tests/lib/locale-bytes.sh`, sourced at `tests/run:146`), which sets `LCB_U8` to the installed `en_US` UTF-8 locale, or empty, and `LCB_NONE` to the skip reason. A part calls it before reading either.

- **Manners.**
    - Fixtures live under `$TMP/s<part number>`. Parts make every fixture root with `pwd -P`, so the paths printed in C2 and C11 have one spelling. No `cd` happens in the suite's own shell. No `cmd | grep -q`; use `case` or `has`.
    - Each part is self-contained, so it needs no `groups.tsv` row, and runs alone under `tests/run --part <name>`.
    - Every assertion that could pass against an engine without the command, such as "nothing changed", includes the run's exit status in the value it compares.
    - Assertion names begin with the part's number and are unique in the suite.

### C14. Pinned assertions for the review focus

Each is pinned by assertions in part 2470 whose names begin `2470 rf1` to `2470 rf7`, one prefix per item.

- **RF1, a linked worktree.**
    - Fixture: a repository with a linked worktree `W`, made with `git worktree add`.
    - `--change` run from `W`, with the default range and with an explicit one, exits 0.
    - Its head commit is `W`'s HEAD.
    - `git worktree list --porcelain`, the refs, every worktree's HEAD and the config bytes are unchanged.
    - Nothing under the main checkout, under `W`, or under the common git directory is newer than a marker.

- **RF2, an untracked environment.**
    - Fixture: a probe grounding the capability of the class's `probe:<c>=found` term, which reads `found` only while an ignored, untracked file is present (for example `.ready`), with a witness on a tracked file.
    - After `felix probes` in the live checkout, `--at` reads the class ACTIVE.
    - `--change HEAD~1..HEAD`, over a commit that does not touch the surface, reads it `could-not-look`: UNKNOWN on both sides, never DORMANT, `retired` or `none`. The residual has `could-not-look` lines for `base:` and `head:` naming the term.

- **RF3, the caller's locale.**
    - Fixture: a substituted table whose classes include `ab` and `a_c`, and owes that differ in case.
    - `--tsv` and the human report are byte-identical under `LC_ALL=C` and under `LANG=$LCB_U8` with `LC_ALL` unset, in both modes.
    - The ordering case is asserted in `--change`, with both classes blinded: they share the `blinded` section and the residual's `could-not-look` lines, and in each `a_c` comes before `ab`. In `--at`, only byte identity across the two locales is asserted.
    - Skipped by name with `$LCB_NONE` when no such locale is installed.

- **RF4, an interrupted run and an early close.**
    - Fixture: a `--change` whose head-side probe touches `$TMPDIR/started`, then runs `sleep 3`.
    - The part starts felix in the background, polls for at most 30 s for `T/felix-situations.*/tmp-head/started`, sends the signal to the felix process, and waits for it.
    - TERM: exit 143. `T` is empty as soon as felix has exited, and again 4 s later, after the probe's sleep would have ended.
    - The same with HUP: 129.
    - The same with INT: 130. The run must be started with INT at its default disposition (`perl -e '$SIG{INT}=q(DEFAULT); exec @ARGV' ...`), since a script's background job ignores INT.
    - `felix situations --change ... | head -1` leaves `T` empty.

- **RF5, quoting in the admit command.**
    - Fixture: a substituted table whose ACTIVE, unadmitted class has owes `don't drop 100% of the \n bound`, with a literal backslash and n. The fixture home is a git repository with one commit.
    - `--propose` exits 0 and leaves `obligations.tsv` and the home's `git status --porcelain` unchanged.
    - Running the printed `admit` command (the text after `    admit  `) as `env GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t bash -c "$cmd"`, since the suite sets no git identity, appends to `P/obligations.tsv` exactly the `row` line's text after its `    row  ` prefix, then one newline. It makes one commit that touches only that file.
    - A second `--propose` no longer lists the class.

- **RF6, the caller's git config.**
    - Fixture: `HOME` names a directory whose `.gitconfig` sets `init.templateDir` (a template whose `hooks/post-checkout` writes a marker), `core.hooksPath` (a directory whose `post-checkout` writes a marker), and `filter.fx.smudge` (which writes a marker). The repository's `.gitattributes` holds `* filter=fx`.
    - `--change` exits 0 and evaluates its classes, and no marker exists.

- **RF7, a facts log shared by worktrees.**
    - Fixture: two worktrees `W1` and `W2` of one project at different trees. `felix probes` runs in `W1`, then in `W2`.
    - `felix situations` in `W1` reads `W2`'s tree, the newest. Its header names that tree and ends `detector not run: this checkout is not at this tree`.
    - `--at` with `W1`'s tree id runs the detector.

### C15. The lane rows this PR sets

The tables are slice 0's. Their formats come from design §6.3, and slice 0's plan fixes them: `projects/<p>/lanes.tsv` is `lane counts share window`, and `projects/<p>/lane-next.tsv` is `lane next`. No part checks felix-home's own rows. This PR sets:

- `projects/felix/lanes.tsv`: `capability\t^engine/\t1/4\t14`. This PR is "intake lands", so the share goes to one in four (§6.3, §9, §11 item 6). Only the share cell changes; the comment lines stay.
- `projects/felix/lane-next.tsv`: `capability\tcome-backs, slice 2: felix retro, pending the direction fold (branch claude/lane-retro)`. It replaces the data row. Putting slice 2 ahead of direction §5's next lane items is the founder's to settle at the direction fold, so the row says so (§9, §12, §11 item 22). The branch is the one slice 2's plan cuts (its Task 0), so a session that takes the item can check that no live session is already on it (§6.5 item 3). The rest of the wording is decided in the plan, in the shape of the slice 1 row §6.3 gives.

### C16. The blind parts

The eight driver lines go in name order, as part 1040 requires, directly after the `2160-docs-are-not-a-frontend-blind.sh` line (the `2250-lane-pulse-blind.sh` line once slice 0 is in the branch) and before the line `! alias . >/dev/null 2>&1 || { unalias .; shopt -u expand_aliases; }`. That line turns part lines back on in the main shell under `-j N`, so that 9990 runs there; nothing is added between it and 9990. Each part's first line is `printf '\n%s\n' 'situations: <topic> (blind)'`.

| Part | Covers | Fixtures |
|---|---|---|
| `2400-situations-table-blind.sh` | C12: format, schema row, cells, the three source kinds, R1 to R4, six to eight rows, no project name. C1: `felix help` holds `felix situations`. Every `engine/harness/lib/situations*.sh` has under 500 lines, and at least one exists. | the shipped table, `templates/schemas.tsv`, the names under the `projects/` beside the harness (see below) |
| `2410-situations-recorded-blind.sh` | §7.3 recorded, §7.4, C3.1, C3.2, C4 (every term rule: a probe term over two probes grounding one capability, a grounding probe with no reading, no probe grounding it; the maturity order with `internal`; unbound terms), the undecided term named beside a DORMANT class (C7), C3.4 for `--at`, C2's `--at` exits, C10 recorded reasons, the `--at` header both ways | a substituted table; hand-written `facts.log` with 8- and 9-field rows, two runs of one tree, a newer tree, `unknown-tree` rows, a short line; `felix probes` for the live tree |
| `2420-situations-change-blind.sh` | §7.3 scratch, §7.5, C3.3, C3.4 for `--change`, C5 (every row of the table; the first kind of "differs", for a `probe:` and a `cap:` term), the default range, C2's `--change` exits, the current `probes.tsv` on both sides, tracked content only, the scratch tree id equal to the recorded one for a clean checkout | a substituted table; one repository whose commits produce each verdict |
| `2430-situations-output-blind.sh` | §7.6 to §7.8, C6 to C10, (d), (i), usage errors, `need_value`, C2's table refusals and order, stderr empty on success. (c) on the shipped seed, in the bash-harness fixture: the residual names at least one could-not-look class, unbound term or `no-row` capability; `paid_ingress` reads UNKNOWN, with a `could-not-look` line whose why names `cap:api`; the count line's U is at least 1; the seed's R4 class reads ACTIVE where its surface is, and `--change` over a commit that removes the surface, as C12's siblings remove it, reads it `retired`, with a `    witness  head:` line. Falsifier 2 in §10's clean-machine form (§11 item 32): two fresh clones of one fixture repository, each with its own fresh memory root holding the same `facts.log` bytes and its own `TMPDIR`, print identical bytes in `--at` and in `--change`, every verdict included (see below). | the shipped seed for (c), a substituted table for the rest; a bash-harness fixture (scripts, `tests/`, a CI workflow, no manifests, and a `probes.tsv` that grounds the R4 class's surface and grounds neither `api` nor `llm`); network stubs |
| `2440-situations-web-fixture-blind.sh` | (a), (f), (g), (h); C11 | the shipped seed; `requirements.txt` naming fastapi and anthropic; one POST route; an `http_route` probe grounding api (a shell command over tracked files, with a witness) |
| `2450-situations-cargo-fixture-blind.sh` | (b), falsifier 5 with its qualifier, no other term false (§11 item 31); the seed's R4 class reads ACTIVE in the cargo workspace, and `retired` with a witness over a commit that removes its surface as C12's siblings remove it | the shipped seed; a cargo workspace whose member depends on axum, with no probe grounding api; every other term of each HTTP-keyed class made true by a probe row, or for an `env:` term by `project.json`'s maturity (for `paid_ingress`, one grounding `llm` that reads found), so that adding a probe row that grounds api makes every HTTP-keyed class ACTIVE; a node that binds every interface |
| `2460-situations-seed-siblings-blind.sh` | §7.2's siblings rule, falsifier 6 (C12) | the shipped seed; one invented project per row |
| `2470-situations-review-focus-blind.sh` | C14, RF1 to RF7 | as each RF says |

No fixture needs python, fastapi, an SDK or a cargo toolchain: probes are shell commands over tracked files, and the detector reads manifest text.

**Part 2400's other checks.**

- Each row's `source` matches `^(miss|candidate|cite):[0-9a-f]{12}$`. No kind is required to appear, and the digest's passage is not checked.
- The project names are the directories under `$REAL_HARNESS/../../projects`, other than `felix`, matched as literal substrings without regard to case, as `bin/independence-scan` matches them. When that directory is absent, the assertion is skipped by name with the reason `no projects/ beside this harness`.
- `schema-check` runs as part 0730 runs it: from a fixture git tree that holds only `engine/harness/templates/schemas.tsv` and `situations.tsv`, both copied from `$REAL_HARNESS`, with `$REAL_HARNESS/bin/schema-check`. It exits 0. The schema row is the first non-comment line after the `discover-rules.tsv` row; its comment's wording is not asserted.

**Part 2430's falsifier 2.** "Every verdict included" means the `--change` runs use an explicit range over which the fixture yields `owed`, `blinded`, `retired`, `standing`, `could-not-look` and `none`, and the compared bytes hold all six. A fresh clone sits on its main branch, so the default range would be empty.

## Review Focus

The five input classes most likely to bite a person that no acceptance bullet exercises, most likely first. Each is pinned in C14.

1. `felix situations --change` run from a linked worktree, which is how every felix-home session works. Pinned by `2470 rf1`.
2. A probe that needs the live checkout's untracked environment reads blind in a scratch clone. It must land as `could-not-look`, never as DORMANT, `retired` or `none` (§7.10). Pinned by `2470 rf2`.
3. A person's Terminal locale, `en_US.UTF-8`, reorders the `--tsv` lines that slice 2 reads, or the report's sections. Pinned by `2470 rf3`.
4. A run stopped part way, or a reader that closes the pipe early, leaves scratch clones under `TMPDIR`. Pinned by `2470 rf4`.
5. Owes text holding `'` or `%` breaks the printed admit command when the founder pastes it. Pinned by `2470 rf5`.

Also pinned: the caller's git config running hooks or filters in a scratch checkout (`2470 rf6`), and the newest recorded tree belonging to another worktree (`2470 rf7`).

## Tasks

### Task 1: Pre-flight, the seed and its schema row

**Stage:** spec. Opus 5.5, high.

**Files:**

- Create `engine/harness/templates/situations.tsv`.
- Modify `engine/harness/templates/schemas.tsv`: insert after line 130 (`discover-rules.tsv`).
- Modify `docs/handoff/pending/20261029T213800Z-claude-lane-situations-owed.md`: append a "Slice 1 build" section.
- Modify this plan, `docs/2026-10-29-lane-slice-1-plan.md`: fill C12's seed list.
- Test: part 2400 (Task 2).

**Interfaces:**

- Consumes: the three projects' `probes.tsv` (`/Users/a14808/Documents/Felix/projects/{elenchus,veldra,felix}/probes.tsv`), the obligation candidates the survey proposed in `/Users/a14808/.felix/memory/{elenchus,veldra}/candidates.tsv` (22 failure modes, privacy exposure among them; proposals, not recorded misses), any recorded miss a row cites, and v3.2 §10.
- Produces: the shipped seed, which every later blind part reads.

**Steps:**

- [ ] Check the queue.
    - Count open engine PRs: `gh pr list --state open --limit 100 --json number,files --jq '[.[] | select(any(.files[]; .path | startswith("engine/")))] | length'`. It must be 10 or fewer, or stop and wait.
    - Run `ListAgents` and confirm that no live session other than the one running this workflow is on branch `claude/lane-situations-owed`.
    - Note whether slice 0 has landed on `origin/main`. Task 9 needs it, and Task 12 rebases on it.
    - Check the part numbers are free: for `origin/main` and the head of every open PR, `git ls-tree --name-only <ref> engine/harness/tests/parts/` shows none of 2400 to 2470. If one is used, take the next free block of ten and rename the parts everywhere in this plan.
    - Check the driver has room (Global Constraints): `origin/main`'s `tests/run` line count, plus the part and lib lines every open engine PR adds to it, plus this slice's 8, is at most 500. If not, stop before the blind stage and tell the queue owner: the driver needs room first.

- [ ] Draft six to eight rows meeting C12.
    - Draft against all three ecosystems at once. Derive each `source` from the passage it cites, with the prefix of its kind: `miss:`, `candidate:` or `cite:`.
    - A `probe:` term names a capability a project's probes can ground, never a predicate: predicate names are each project's own (§7.2).
    - Each row goes under its own comment line saying what it is for.
    - The comments name no project.

- [ ] Add the schema row from C12, with its comment, after `schemas.tsv:130`.
- [ ] Run `engine/harness/bin/schema-check` from the worktree root. Expect exit 0.
- [ ] In the pending handoff note, record each source digest with its passage, and which row meets R1 to R4. The note may name projects, since it is not under `engine/harness`.
- [ ] Fill C12's seed list in this plan: `<cap3>`, and each class by name with the items of R1 to R4 it meets, naming one R4 class. The list names no project.
- [ ] Commit `docs(situations): the seed table and its schema row, the spec for slice 1`, ending with `Felix-Lane: capability`, and push. Give the blind author this commit's id.

A seed row found wrong later comes back to this task's author, and the blind author updates the parts that name it.

### Task 2: Blind parts

**Stage:** blind assertions. Opus 5.5, high. The author reads the design, the Contracts section and the shipped seed, all at Task 1's commit, plus the suite's own harness: `tests/run`, `tests/parts/000*.sh`, `tests/parts/0730-schema-check-every-table-declared-every-row.sh` and `tests/lib/*.sh`. It never reads `lib/situations*.sh`, `felix`, or any other file under `engine/harness/lib`, `hooks` or `bin`.

**Files:**

- Create the eight parts in C16.
- Modify `engine/harness/tests/run`: insert eight lines where C16 places them.
- Test: the parts themselves.

**Interfaces:**

- Consumes: C1 to C16 and the shipped seed.
- Produces: assertion names, each beginning with its part's number.

**Steps:**

- [ ] Write each part to cover its row of C16, with the fixtures C13 describes.
- [ ] Check that every pinned output in C2 and C7 to C11 that a part checks is compared exactly with `is`, or with `has` on a whole pinned line.
- [ ] Check that `bash -n` prints nothing for each part, that each has at most 1,000 lines, and that `tests/run` has at most 500.
- [ ] Commit `test(situations): blind parts for slice 1, written from the design and the contracts`, ending with `Felix-Lane: capability`, and push.

### Task 3: Red on main

**Stage:** red. Sonnet 5.5, high.

**Files:** Modify the pending handoff note: add a red record.

**Interfaces:** consumes the eight parts from Task 2 and `origin/main`; produces the red record, a FAIL count per part and the base sha.

**Steps:**

- [ ] Build a red tree: the base engine with this branch's tests. Name the directory exactly; never pick one by glob.
    - `WT=/Users/a14808/Documents/Felix/.claude/worktrees/agent-beacon-drift-481a64`
    - `git -C "$WT" fetch origin main`
    - `RT="$(mktemp -d "${TMPDIR:-/tmp}/s1-red.XXXXXX")"`
    - `git -C "$WT" worktree add --detach -q "$RT/base" origin/main`
    - `git -C "$WT" archive HEAD engine/harness/tests | tar -x -C "$RT/base"`

- [ ] Run each part alone, one at a time. First count running part runs by process group, as slice 0's plan does, since every subshell of a run keeps its command line: `ps -Ao pgid=,command= | LC_ALL=C awk '/tests\/run --part/ { print $1 }' | LC_ALL=C sort -u | wc -l`, or use a Mac-wide four-slot helper when the session has one. Start a run only while the count is under four.
    - `( cd "$(mktemp -d)" && bash "$RT/base/engine/harness/tests/run" --part <part> ) > "$RT/<part>.log" 2>&1`

- [ ] Judge each log. Part mode exits 0 whatever it counted, so read the log, not the status.
    - Expected: `@@part-done <part>` is present.
    - No `  FAIL` line comes before `@@prelude-done`.
    - At least one `  FAIL` line comes after it.
    - The part's last assertion name is printed.
    - The usual failure is `felix: unknown command: situations`, and in 2400, the table being absent.
    - Every assertion should fail here. One that passes on main is a defect to send back to the blind author: an invariance check must include the exit status (C13), so it fails on an engine without the command.

- [ ] Record each part's FAIL count and the base sha in the note.
- [ ] Remove the red worktree: `git -C "$WT" worktree remove --force "$RT/base"`.
- [ ] Commit `test(situations): red on main for the slice 1 parts`, ending with `Felix-Lane: capability`, and push.

### Task 4: The command, its arguments, the table and ids

**Stage:** implementation. Sonnet 5.5, high or xhigh, never max. Two red rounds move the task to Opus 5.5, high.

**Files:**

- Modify `engine/harness/felix`. The line numbers are those at `01e24cfc`. Place each edit by its anchor, because slice 0 also edits these blocks:
    - after line 369 (`. "${SCRIPT_DIR}/lib/facts.sh"`), add three source lines for `lib/situations.sh`, `lib/situations-read.sh` and `lib/situations-report.sh`;
    - after line 449 (the `felix obligations` usage line), add C1's usage entry;
    - before line 6463 (the comment above `cmd_pulse`), add `cmd_situations`;
    - after line 6603 (`obligations) shift; cmd_obligations "$@" ;;`), add `  situations) shift; cmd_situations "$@" ;;`.

- Create `engine/harness/lib/situations.sh`.
- Create `engine/harness/lib/situations-read.sh` and `engine/harness/lib/situations-report.sh`, each with its header comment.
- Test: parts 2400 and 2430, for usage, exits and the table.

**Interfaces:**

- `cmd_situations "$@"`: parses C1 with `need_value` for `--at` and `die "usage: felix situations [--at <tree> | --change [<base>..<head>]] [--tsv | --propose] (got: <arg>)" 2`; runs `resolve_or_die`; runs `export GIT_OPTIONAL_LOCKS=0`; reads the table; exits as C2 says.
- `felix_situations_table <file>`: prints the table's rows verbatim, in file order. Status 0, or status 3 with `<file>: <why>` (C2's list) on stderr.
- `felix_situations_id <class> <project>`: prints `owed:<12 hex>` (C6).

**Steps:**

- [ ] Implement the interfaces above.
- [ ] Run parts 2400 and 2430 alone, as in Task 3, against `$WT`. Expect 2400 to have no FAIL. In 2430, expect the usage, `need_value` and table-refusal assertions to pass. The id assertions wait for Task 5's report.
- [ ] Commit `feat(situations): the command, its flags and the situation table`, ending with `Felix-Lane: capability`, and push.

### Task 5: Recorded readings, evaluation and the `--at` report

**Stage:** implementation. Sonnet 5.5, high or xhigh, never max. Two red rounds move the task to Opus 5.5, high.

**Files:**

- Modify `engine/harness/lib/situations-read.sh` (recorded readings).
- Modify `engine/harness/lib/situations.sh` (evaluation).
- Modify `engine/harness/lib/situations-report.sh` (human and `--tsv`).
- Modify `engine/harness/felix` (`cmd_situations`, the `--at` path).
- Test: parts 2410, 2430 and 2440, the `--at` assertions.

**Interfaces:**

- **The reading file**, one per side. Its lines are tab-separated, and each is named by its first cell. Only the order of the `probe` lines matters: they are in reading order. The lines are:
    - `how\trecorded|scratch`
    - `commit\t<sha40>|-`
    - `tree\t<tid>`
    - `stamp\t<stamp>|-`
    - `detector\trun|not-run`
    - zero or more `cap\t<capability>` lines: the detector's names, sorted and unique, present only when it ran
    - `probe\t<pred>\t<grounds>\t<state>\t<count>\t<detail>|-`, in reading order

- `felix_situations_scratch_begin`: sets the global `_FELIX_SITUATIONS_SCRATCH` to an empty string, installs the traps, then makes the directory (C3.3). Status 0, or 3 with C2's scratch-directory sentence. The traps:
    - EXIT removes the directory;
    - TERM, HUP and INT remove it and exit 143, 129 and 130.

- `felix_situations_scratch_end`: removes the directory and puts the traps back.
- `cmd_situations` calls `felix_situations_scratch_begin` right after the table is read, in both modes (C2's order), and `felix_situations_scratch_end` before printing. Every `<out>` below is a path inside `$_FELIX_SITUATIONS_SCRATCH`.
- `felix_situations_newest_tree <log>`: prints the tree (C3.1). Status 0, or 3.
- `felix_situations_read_recorded <log> <tree> <out>`: writes the reading's `how`, `tree`, `stamp` and `probe` lines. Status 0, or 3 when no run is recorded.
- `felix_situations_live_detect <root> <home> <tree> <out>`: appends `commit`, `detector` and `cap` lines (C3.2).
- `felix_situations_eval <rows> <reading> <probe-grounds> <maturity>`: `<probe-grounds>` is the current `probes.tsv`'s `predicate\tgrounds` pairs, from `felix_probe_rows`, which C4 needs for a grounding probe with no reading and for unbound terms. It prints these lines:
    - `class\t<class>\t<STATE>\t<grounds>\t<readings>\t<witness>|-\t<key>`, one per class in table order. `<key>` is the comparison C5 defines, as one string.
    - `undecided\t<class>\t<term>\t<reason>`, for every undecided term. `<reason>` is C10's reason.
    - `unbound\t<term>\t<why>`.
    - `seen\t<capability>\tthe detector|probe <pred>`.

- `felix_situations_report <mode> <format> <proj> <rows> <base-eval>|- <head-eval> <base-reading>|- <head-reading>`: prints C8 or C9. `<mode>` is `at` or `change`; `<format>` is `human` or `tsv`.

**Steps:**

- [ ] Implement the interfaces, following C3.1, C3.2, C4, C7 and C8 to C10.
    - The global holding the scratch path is set empty before the trap is installed, because a trap body is read when it fires and a `local` is gone by then (precedent: `felix:3432-3436`).
    - Every `sort` and `uniq` runs under `LC_ALL=C`.
    - The awk uses no gawk-only name.
    - Any `[[ =~ ]]` sits in a function with `local LC_ALL=C`.

- [ ] In `cmd_situations`, build the whole report into a variable, call `felix_situations_scratch_end`, and only then print it (C3.3).
- [ ] Run parts 2410, 2430 and 2440 alone. Expect 2410 to have no FAIL. In 2430 and 2440, expect every `--at` assertion to pass.
- [ ] Commit `feat(situations): recorded readings, three values and the --at report`, ending with `Felix-Lane: capability`, and push.

### Task 6: Scratch readings, verdicts and the `--change` report

**Stage:** implementation. Sonnet 5.5, xhigh, never max. This task touches the repository-untouched rule, so a red round here moves it to Opus 5.5, high at once.

**Files:**

- Modify `engine/harness/lib/situations-read.sh` (the range and scratch readings).
- Modify `engine/harness/lib/situations.sh` (verdicts).
- Modify `engine/harness/lib/situations-report.sh` (the `--change` sections).
- Modify `engine/harness/felix` (the `--change` path).
- Test: parts 2420, 2430, 2440 (f) to (h), 2450 and 2470 (RF1 to RF4, RF6, RF7).

**Interfaces:**

- `felix_situations_range <root> [<range>]`: prints `<base-sha40>\t<head-sha40>`. Status 0, or 3 with C2's sentence.
- `felix_situations_read_scratch <proj> <home> <src-gitdir> <sha> <side> <out>`: clones into `$_FELIX_SITUATIONS_SCRATCH/<side>`, checks out, takes the tree id, then runs the detector and the probes with `TMPDIR=$_FELIX_SITUATIONS_SCRATCH/tmp-<side>`, and writes a reading with `how scratch`. Status 0, or 3.
- `felix_situations_verdict <base-state> <head-state> <differs 0|1>`: prints a C5 token.

**Steps:**

- [ ] Implement the scratch method exactly as C3.3 lists it.
    - The clone source is the repository's common git directory, made absolute.
    - Use `_felix_git_rules` (`lib/resolve.sh:1557-1563`) for the clone and the checkout, with `GIT_NO_LAZY_FETCH=1` added. It already runs git with no global or system config and no repository-pointing environment.

- [ ] Run parts 2420, 2430, 2440, 2450 and 2470 alone, at most four at once. Expect no FAIL in 2420, 2430 or 2450. In 2440, expect only the `--propose` assertions to fail. In 2470, expect only RF5 to fail.
- [ ] Commit `feat(situations): scratch readings, verdicts and the --change report`, ending with `Felix-Lane: capability`, and push.

### Task 7: `--propose`

**Stage:** implementation. Sonnet 5.5, high, never max. Two red rounds move the task to Opus 5.5, high.

**Files:**

- Modify `engine/harness/lib/situations-report.sh`.
- Modify `engine/harness/felix` (the `--propose` path).
- Test: part 2440, and part 2470 (RF5).

**Interfaces:**

- `felix_situations_propose <proj> <home> <rows> <eval> <maturity>`: prints C11's section, from its blank line on.
- It consumes `felix_obligation_rows <proj>` (`lib/obligations.sh:119`) and `felix_probe_rows <proj>` (`lib/probes.sh:109`).

**Steps:**

- [ ] Implement C11, including the `'\''` quoting.
- [ ] Run parts 2440 and 2470 alone. Expect no FAIL.
- [ ] Commit `feat(situations): --propose drafts a row and the command that would admit it`, ending with `Felix-Lane: capability`, and push.

### Task 8: The seed through its siblings, and every part together

**Stage:** implementation check. Sonnet 5.5, high. A seed row that fails goes back to Task 1's author (Opus). A part that is wrong goes back to the blind author. Code that is wrong goes back to the implementer.

**Files:** none new.

**Interfaces:** consumes Tasks 4 to 7; produces all eight parts and the lint parts green.

**Steps:**

- [ ] Run part 2460 alone. Expect no FAIL, and the ledger names every shipped class read both ways.
- [ ] Run all eight parts alone, at most four at once. Expect no FAIL in any.
- [ ] Run the existing lint parts that judge `felix`, the new libraries and the driver, each alone, at most four at once, counted as Task 3 counts them: `0370-a-receipt-that-cannot-claim-more-than-it-kno.sh`, `0480-the-one-line-git-cannot-reconstruct.sh`, `0590-the-pre-flight.sh`, `0960-no-engine-test-reads-a-pipe-through-a-grep-t.sh`, `1000-the-engine-makes-its-scratch-under-tmpdir.sh`, `1030-a-pipe-at-stack-tsv-read-by-the-stop-hook-in.sh`, `1040-the-suite-is-cut-into-parts.sh`, `1497-lib-awk-gawk-names-blind.sh`, `1530-patch-reads-the-repository-not-a-diff-setting.sh` and `1610-driver-room-blind.sh`. Run `0992-sort-comm-join-and-uniq-read-bytes-in-the-c-l.sh`, `0994-bash-s-own-collation-and-the-bsd-text-tools.sh`, `0996-continued.sh` and `0998-continued.sh` in one `--part` run, or each alone: each is self-contained, and `groups.tsv` joins none of them. Expect no FAIL.
- [ ] Where a gawk is installed, run the eight parts once more with gawk first on `PATH`. CI runs gawk.
- [ ] Run `engine/harness/bin/independence-scan` from the worktree root. Expect exit 0.
- [ ] Check for ecosystem words with the gate's whole vocabulary: `command grep -nwiE 'python|pip|poetry|pipenv|pytest|node|npm|yarn|pnpm|rust|cargo|dotnet|gradle|maven|composer|bundler|rubygems|sentry|opentelemetry|datadog|stripe|playwright|cypress|selenium|puppeteer|supabase|prisma|alembic|sqlalchemy|drizzle|typeorm|fastapi|flask|django|express|fastify|starlette|anthropic|openai|langchain|llama-?index|mistralai|cohere|ollama|google-generativeai|litellm|instructor|dspy|transformers' engine/harness/lib/situations*.sh`. Expect no line. Run the same over the lines this branch added to `felix` (`git -C "$WT" diff origin/main -- engine/harness/felix`).
- [ ] Commit any fix, ending with `Felix-Lane: capability`, and push.

### Task 9: The lane rows

**Stage:** implementation. Sonnet 5.5, high, never max. Two red rounds move the task to Opus 5.5, high. It needs slice 0's `lanes.tsv` and `lane-next.tsv`. When slice 0 is on `origin/main`, rebase on `origin/main`. When it is not, rebase on slice 0's pushed branch (design §9), open this PR as a draft whose base is that branch and record in the pending handoff note the slice-0 commit this branch now sits on (again after every later rebase on that branch), and retarget it to `main` once slice 0 lands. Resolve conflicts in `felix`, `templates/schemas.tsv` and `tests/run` by keeping both sides' lines. A conflict in `docs/2026-10-29-capability-lane-first-slices-design.md` or `docs/2026-10-29-lane-slice-0-plan.md`, which slice 0's branch copied from this one, takes the replayed commit's version (`git checkout --theirs -- <file>`, `git add <file>`, `git rebase --continue`; in a rebase, theirs is this branch's commit), so the last replayed commit leaves this branch's newest text. A document never keeps both sides' lines.

**Files:**

- Modify `projects/felix/lanes.tsv`: in the `capability` row, change the share from `1/2` to `1/4`.
- Modify `projects/felix/lane-next.tsv`: change the `capability` row's `next` to C15's text.

**Interfaces:** consumes slice 0's `felix lane --tsv`.

**Steps:**

- [ ] Edit the two rows to read exactly as C15 says.
- [ ] Run `engine/harness/bin/schema-check` from the worktree root. Expect exit 0.
- [ ] Commit `data(lane): intake lands: the capability lane's share goes to 1/4, and next is slice 2, pending the direction fold`, ending with `Felix-Lane: capability`.
- [ ] Run `FELIX_HOME="$WT" "$WT/engine/harness/felix" lane --tsv` in the worktree. Without `FELIX_HOME`, the engine reads the home that `~/.felix-home` names, the main checkout, which still says `1/2`. Expect the target `1/4`, the new `next`, and, as the commit that last changed the lane's row in `lanes.tsv` (§6.3), this commit's sha and date. Push with `git -C "$WT" push --force-with-lease origin claude/lane-situations-owed`, since the rebase rewrote commits already pushed.

### Task 10: Real data (§7.9 e)

**Stage:** measurement. Sonnet 5.5, high. The runs name real projects, so they are recorded measurements outside the suite, and no engine file names either project (§7.9 (e), §11 items 11 and 30).

**Files:**

- Create `/Users/a14808/.felix/memory/veldra/measurements/` and `/Users/a14808/.felix/memory/elenchus/measurements/`: plain files, no git repository.
- Modify the pending handoff note.

**Interfaces:** consumes `felix situations` as built; produces the measurement files and the summary the PR body carries.

**Steps:**

- [ ] Run every `felix` command in this task with `FELIX_HOME="$WT"`, so the branch's `projects/<p>/probes.tsv`, `project.json` and `obligations.tsv` are the tables read. Without it the engine reads the main checkout's tables.
- [ ] Run Veldra from its checkout.
    - `cd /Users/a14808/ReserveGrid-OS`
    - Run `"$WT/engine/harness/felix" situations --at 7901ad88fd5e3857e61d51c672105ad140637a60`, and again with `--tsv`.
    - Save each to `situations-<UTC stamp>-at.txt` in Veldra's measurements directory. The first lines say, as `#` comments, the engine commit, `FELIX_HOME`, the checkout path, its HEAD and the command.
    - Expect exit 0. Expect no HTTP-keyed class DORMANT unless its grounds show a false term resting on a witness (falsifier 5, checked by hand).

- [ ] Run Elenchus from its checkout.
    - `cd /Users/a14808/Documents/Elenchus`. It has `.venv`, `scripts/serve_invitee.py` and `src/elenchus/web/__main__.py` at `e625a88`.
    - Note `git status --porcelain` before and after; Elenchus is read-only to this work.
    - Run `"$WT/engine/harness/felix" probes`, which records facts for this tree. Then run `"$WT/engine/harness/felix" situations --propose`, and `"$WT/engine/harness/felix" situations --tsv`, saved the same way.
    - Expect `paid_ingress` ACTIVE with grounds `http_route found (api), llm detected`, and its proposed row printed.
    - If it does not read ACTIVE, fix the seed (back to Task 1), or add a row to `$WT/projects/elenchus/probes.tsv` on this branch, which is free, and run again with `FELIX_HOME="$WT"`. Do not change the Elenchus checkout or its environment. If the only cause is that environment, record it in the pending note and in the PR body as the finding design §9 names: the spend gap did not read ACTIVE, so slice 2's first real count (its Task 12 Step 1) waits until a fresh reading finds it ACTIVE (design §7.9 (e), §8.5).

- [ ] Put the summary lines in the pending note: commands, trees, each class's state, the residual's counts by kind, and the file paths.
- [ ] Commit the note, ending with `Felix-Lane: capability`, and push.

### Task 11: Adversarial review and fixes

**Stage:** review. Opus 5.5, high. Fixes: Sonnet 5.5, high or xhigh, never max; a fix that goes red twice moves to Opus 5.5, high. Part fixes: the blind author, Opus 5.5, high.

**Files:** only those Tasks 1 to 9 name. A mutant lives in its scratch worktree and is never committed.

**Interfaces:** consumes the branch diff against `origin/main`, the design and the Contracts; produces fixes, and parts for any mutant that stayed green.

**Steps:**

- [ ] The reviewers get the branch diff against `origin/main`, the design and the Contracts. They look first at the Review Focus. They also check:
    - that no write path exists, against C3.4;
    - every exit path of the scratch;
    - that no file names a project or an ecosystem word;
    - the lane exclusions;
    - the `need_value` use;
    - the 500-line limits;
    - that "could not look" never reaches a DORMANT, absent or "owes nothing" reading.

- [ ] Run mutants, each in a scratch worktree (`git -C "$WT" worktree add --detach "$M/w" HEAD`) and never on the branch. Each must turn its part red; a mutant that stays green is a missing assertion, and goes back to the blind author. Each assertion added that way is shown failing on the mutant and on `origin/main`, run as Task 3 runs it in a red worktree of its own. Its part's new FAIL count goes into the red record in the pending note, which is committed and pushed.
    - Detector silence read as false: 2450 and 2410.
    - A `probe:` term read from one predicate instead of every probe grounding its capability: 2410.
    - An UNKNOWN head with an ACTIVE base read as `none`: 2420.
    - The scratch made with `git worktree add`: 2420 and RF1.
    - The trap removed: RF4.
    - `felix_probes_record` called in `--change`: 2420.
    - `sort` without `LC_ALL=C`: RF3, where the locale is installed.
    - The commit hashed into the id: 2430.
    - No `'\''` quoting: RF5.
    - The oldest run of a tree read: 2410.
    - `not-applicable` read as undecided: 2410.

- [ ] Apply fixes, re-run the affected parts alone, and commit each fix ending with `Felix-Lane: capability`. Push.

### Task 12: Version, record, gate and PR

**Stage:** landing. Sonnet 5.5, high.

**Files:**

- Modify `engine/.claude-plugin/plugin.json`: the version, `0.49.313` on `origin/main` at `01e24cfc`.
- Modify `engine/harness/tests/assertions.tsv` and `engine/harness/tests/red.tsv`, through the record.

**Interfaces:** consumes the finished branch; produces the record, a passing gate and the PR.

**Steps:**

- [ ] Wait until slice 0 is on `origin/main`, because the version, the record and the gate are taken once, on a tree based on `origin/main` (design §9). Then rebase on `origin/main`. When this branch sits on slice 0's branch, run `git -C "$WT" rebase --onto origin/main <S0>`, where `<S0>` is the slice-0 commit Task 9 recorded. That replays only this branch's own commits, and none of slice 0's, which landed as one squash. Resolve conflicts in `felix`, `templates/schemas.tsv` and `tests/run` by keeping both sides' lines. A conflict in `docs/2026-10-29-capability-lane-first-slices-design.md` or `docs/2026-10-29-lane-slice-0-plan.md`, which slice 0's branch copied from this one, takes the replayed commit's version (`git checkout --theirs -- <file>`, `git add <file>`, `git rebase --continue`; in a rebase, theirs is this branch's commit), so the last replayed commit leaves this branch's newest text. A document never keeps both sides' lines. The version, `tests/assertions.tsv` and `tests/red.tsv` are rewritten below, not merged.
- [ ] Set the version to the next free patch slot at landing time (§4: on 10-29, 0.49.310 to 0.49.314 were claimed). Read the titles of open PRs and the version on `origin/main`, and take the next slot none of them holds. Commit `chore(version): 0.49.<n>` ending with `Felix-Lane: capability`.
- [ ] Commit everything, so `git status --porcelain` is empty. Find the session whose record or gate holds the queue with `ListAgents` (on 10-29 it was the "Inventory next steps" session). Ask it through `SendMessage` whether the queue is free, and wait for a yes. If no session holds the queue, check that no record or gate is running (`pgrep -fl 'tests/run'`) before starting. Keep the Mac awake.
- [ ] Run the record detached, with INT and QUIT reset and `FELIX_TEST_JOBS` unset (so at `-j 1`, which leaves a receipt the gate can reuse), from the worktree root: `nohup perl -e 'use POSIX (); POSIX::setsid(); $SIG{INT}=$SIG{QUIT}="DEFAULT"; exec @ARGV' bash -c 'unset FELIX_TEST_JOBS; engine/harness/tests/run --record-assertions' > <log> 2>&1 &`. A bare `&` from a non-interactive shell runs the suite with INT and QUIT ignored, and part 1295 then fails. Poll the log, because background Bash dies at ten minutes.
    - Expect the summary `<n> passed, 0 failed`. Compare the skip count with the last known-good record before trusting it.
    - Expect `assertions.tsv` and `red.tsv` rewritten, with `red.tsv`'s `run` row showing failed above 0, including every new part's assertions.

- [ ] Commit `assertions.tsv` and `red.tsv` with `test(situations): the record`, ending with `Felix-Lane: capability`.
- [ ] With the record finished, since red and gate never run at once in one worktree, run the gate the same way, from the same shell: `nohup perl -e 'use POSIX (); POSIX::setsid(); $SIG{INT}=$SIG{QUIT}="DEFAULT"; exec @ARGV' bash -c 'engine/harness/felix gate' > <log> 2>&1 &`. Poll it. Expect it to reuse the record's receipt and pass, with its header naming this worktree.
- [ ] Push with `git -C "$WT" push --force-with-lease origin claude/lane-situations-owed`, since the rebase rewrote commits already pushed. Then, if Task 9 opened a draft PR, set its base to `main`, retitle it `situations: what a change owes, report-only (0.49.<n>)`, write the body below and mark it ready. Otherwise open it with that title. The body holds:
    - what it adds;
    - that it lands intake, so the lane's share goes to `1/4`, and that `next` names slice 2 pending the direction fold (§12);
    - the red counts per part (Task 3, with any Task 11 added);
    - the seed rows, with their sources and which meet R1 to R4;
    - what admitting a `--propose` draft as printed does (C11);
    - the four limits of design §7.10, word for word, including that on Elenchus every class needing api reads could-not-look in `--change` until scratch trees get an environment;
    - the real-data summary (Task 10).

- [ ] Label the PR `needs-founder` only if he asked to read the seed first (§7.2, §11 item 12). Otherwise it lands on green.
- [ ] Turn on the CI monitor, and hand the PR to the landing queue, whose `felix merge` copies every non-merge commit message, and so the mark, into the landing.

## Coverage

| Spec item | Contract | Part | Task |
|---|---|---|---|
| §7.2 file, columns, schema row, cells | C12 | 2400 | 1 |
| §7.2 seed R1 to R4 | C12 | 2400, 2430, 2440, 2450 | 1, 8 |
| §7.2 siblings, falsifier 6 | C12 | 2460 | 8 |
| §7.2 authorization | none | none | 12 |
| §7.3 recorded readings | C3.1, C3.2 | 2410, RF7 | 5 |
| §7.3 scratch readings, an untouched repository, no `facts.log` write | C3.3, C3.4 | 2420, RF1, RF4, RF6 | 6 |
| §7.4 three values, probe terms keyed by capability | C4 | 2410 | 5 |
| §7.4 the undecided term named beside a DORMANT class | C7, C9 | 2410 (`--tsv`), 2420 | 5, 6 |
| §7.5 verdicts, "differs" | C5 | 2420 | 6 |
| §7.6 ids, (i) | C6 | 2430 | 4 to 6 |
| §7.7 human, `--tsv`, exit status | C2, C8, C9 | 2430, RF3 | 4 to 6 |
| §7.7 `--propose` | C11 | 2440, RF5 | 7 |
| §7.8 residual, how each side was read in the header, (c) on the shipped seed | C9, C10 | 2430, 2410, 2420 | 5, 6 |
| §7.9 (a), (f), (g), (h) | C7, C11 | 2440 | 5 to 8 |
| §7.9 (b), falsifier 5 | C4, C12 | 2450 | 5 to 8 |
| §7.9 (d), falsifier 2 in its clean-machine form | C3.4, C13, C16 | 2430 | 5, 6 |
| §7.9 (e) | none | none | 10 |
| §7.10 limits | C3.3, C10 | RF2 | 6; stated in the PR body, 12 |
| §6.3, §9 lane rows | C15 | none | 9 |
| §4 how it lands | Global Constraints | none | 1, 3, 12 |
