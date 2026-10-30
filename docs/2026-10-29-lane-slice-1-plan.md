# Situations Owed Implementation Plan

> **For agentic workers:** run this plan as the founder's engine-build Workflow: spec, blind assertions, red first, implementation, adversarial review, gate. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** Ship `felix situations`, which says, for a recorded tree or for a change, which situation rows the project owes, which rows the change brings in, blinds or retires, and what Felix could not look at, with no model, no key and no network.

**Architecture:** A new engine table, `engine/harness/templates/situations.tsv`, holds the classes. Three new libraries do the work. `lib/situations-read.sh` reads one side: either the recorded facts in `facts.log`, or a fresh reading of a scratch clone. `lib/situations.sh` evaluates each class with three values and compares base against head. `lib/situations-report.sh` prints the human report, the `--tsv` form that slice 2 reads, or the `--propose` drafts. `felix` gains one command, `cmd_situations`, which parses the flags and wires these together. Nothing is written anywhere.

**Tech stack:** Bash 3.2, git, and awk that both BWK awk and gawk run. The tests are the suite's parts, run with `tests/run --part`.

**Spec:** `docs/2026-10-29-capability-lane-first-slices-design.md`: §7 (slice 1), with §1 to §5, §9 and §10. Through §7, also `docs/2026-10-19-intent-to-build-design.md` §9 and §10.

## Global Constraints

- "Bash 3.2 and git only: no jq, no python." (§4)
- "Only awk that both BWK awk (local) and gawk (CI) run. Part 1497's `_awk_names` lints `lib/`." (§4)
- "`LC_ALL=C` on every sort, comm, join and uniq (part 0992)." (§4)
- "`[[ =~ ]]` only inside a function that declares `local LC_ALL=C` (part 0996)." (§4)
- "Flags go through `need_value` (`felix:388-390`), never a bare `shift 2`." (§4; `need_value` is at `felix:389-391` today.)
- "The engine names no project (constitution invariant 1). The gate's independence and ecosystem sections fail on it. Everything project-specific lives in a `projects/<p>/` table or arrives as an argument." (§4)
- The ecosystem section reads its words from every `_felix_dep_grep` token in `lib/detect.sh` (`:74-78`, `:87-89`) and from the `word` rows of `engine/harness/ecosystem.tsv`, less the `mute` row (`next`). So no new line in `felix` or in `lib/situations*.sh` may say python, pip, pytest, node, npm, rust, cargo, fastapi, anthropic or any other of those words. `rust` is also a capability name, so the libraries hard-code no capability name at all. (Engine rule, `projects/felix/gate.sh:412-555`. It scans the paths `bin/independence-scan --paths` prints, `felix`, `lib`, `hooks` and `bin`, so `templates/` is not scanned for these words.)
- "Offline and deterministic (invariant 2). Two runs with the network off and no key print identical bytes." (§4)
- "A check that cannot fail is not a check (invariant 5). Every new check is shown failing first." (§4)
- "Never delete a home or a memory root (invariant 6)." (§4)
- "Records go under the memory root (`felix_mem_dir`, `lib/resolve.sh:270-273`) or under `state/`." (§4; `felix_mem_dir` is at `lib/resolve.sh:269-272` today.)
- "Nothing is written into a governed repository: its refs, index, config and worktree list stay as they were." (§4)
- "`--change` never writes `facts.log`." (§4)
- "The lane never touches `lib/qualify.sh`, `lib/obligations.sh`, `lib/receipt.sh` or the landing actor's files": "`lib/automerge.sh`, `lib/green-*.sh`, `lib/land-table.sh`, `lib/notify.sh`, `lib/own.sh` and `lib/status-land.sh`; the `felix merge` and `felix land` code paths." (§4) Calling `felix_obligation_rows` is reading, not touching.
- "Each new table is a new file with one new `schemas.tsv` row, which is an addition and free. No column is added to an existing table, because that is a founder stop." (§4)
- "Nothing here blocks a merge, holds a release, comments on a pull request or writes an enforcing table." "No new GitHub writes, and no file in anyone's CI." (§3)
- Anti-goals (§3): "A project score, level or readiness grade." "Anything a person chats with." "'Could not look' shown as anything else. It is never printed or counted as DORMANT, as absent, or as 'owes nothing'." "A model on any of these paths."
- "No new engine branch while more than 10 engine PRs are open (direction row 17). The engine does not count this, so the builder checks `gh pr list` first." (§4)
- "Each PR bumps the patch version in the PR and puts it in the title. The carrier gives out the next free slot; 0.49.310 to 0.49.313 are claimed." (§4)
- "Every new `felix` command appears in `usage()`. Part 0480 asserts it." (§4; the assertion is at `tests/parts/0480-the-one-line-git-cannot-reconstruct.sh:406-417`.)
- Suite manners (§4): "commit everything before the record; red and gate never share a worktree; at most four part runs at once, across the Mac; no whole-suite run while another session's record or gate holds the queue." Today the queue owner is the "Inventory next steps" session.
- Engine rules met by the new files: every `mktemp` names a template under `TMPDIR` (part 1000). Each new library stays under 500 lines. `tests/run` stays at or under 500 lines (part 1040; it has 453 now). A part has at most 1,000 lines and is named `NNNN-[a-z0-9-].sh`.
- Commit messages carry no `Co-Authored-By` trailer and no attribution line. The lane's mark is the whole line `Felix-Lane: capability` (§6.2), which ends every commit message this plan makes.

## Contracts

The blind author reads the design, this section, and the seed table that Task 1 commits (`engine/harness/templates/situations.tsv`, which is data and part of the spec). Nothing else of the plan. Where this section says "decided in the plan", the design left the choice to the builder.

Notation: `\t` is one tab byte. Every output line ends in one newline. STATE words are `ACTIVE`, `DORMANT` and `UNKNOWN`. A side is `base`, `head`, or, in `--at` mode, `at`.

### C1. The command

```
felix situations [--at <tree> | --change [<base>..<head>]] [--tsv | --propose]
```

- With neither `--at` nor `--change`, it runs as `--at` on the newest recorded tree.
- `--at` takes a value through `need_value`.
- `--change` takes an optional range. The next argument is the range when it exists and does not begin with `-`.
- A range is split at its first `..`. It is a usage error when either half is empty, when the value holds `...`, or when the head half holds `..`. `HEAD~1..HEAD`, `main..HEAD` and `v1.2..v1.3` are ranges.
- `--tsv` and `--propose` may not both be given. Neither may `--at` and `--change`. No flag may be given twice. Any other argument is a usage error.
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
| no project governs the directory | 2 | empty | `resolve_or_die`'s existing sentence, beginning `felix: no project governs` |
| a side, or the situation table, could not be read at all | 3 | empty | one line: `felix situations: <what> could not be read: <why>` |
| TERM, HUP or INT during a run | 143, 129, 130 | (not judged) | (not judged) |

The exit-3 lines, decided in the plan. `<rev>` is the text as given, `<memdir>` is `felix_mem_dir` of the project (`$FELIX_MEMORY/<project>`), and `<sha40>` is a full commit id.

- `felix situations: base could not be read: <rev> is not a commit here`. The same with `head`. When no range is given and HEAD is unborn, `<rev>` is `HEAD`.
- `felix situations: the change could not be read: no main ref here: neither refs/remotes/origin/main nor refs/heads/main`
- `felix situations: the change could not be read: <ref> and HEAD share no merge base`, where `<ref>` is the full ref name.
- `felix situations: base could not be read: the scratch checkout of <sha40> could not be made`. The same with `head`.
- `felix situations: the recorded tree could not be read: no run is recorded for tree <tree> in <memdir>/facts.log`
- `felix situations: the recorded tree could not be read: <memdir>/facts.log records no tree`. This covers an absent log, an empty one, and one whose only trees are `unknown-tree`.
- `felix situations: the situation table could not be read: <path>: <why>`. The `<why>` is one of the following, where `<n>` is the physical line number:
    - `it is absent or unreadable`
    - `it holds no row`
    - `line <n>: <k> fields where a row has 5`
    - `line <n>: class '<c>' is not [a-z][a-z0-9_]*`
    - `line <n>: class '<c>' appears twice`
    - `line <n>: class_by_maturity '<v>' does not name each of prototype internal public-beta production once with a class of INFO ADVISORY TASK_BLOCKING RELEASE_BLOCKING AUTHORITY_BLOCKING`
    - `line <n>: source '<v>' is not miss:<12 hex> or cite:<12 hex>`

### C3. Readings

#### C3.1 Recorded readings (`--at`)

- The log is `<memdir>/facts.log`. A row is `stamp\ttree\tpredicate\tclass\tstate\tcount\tgrounds\tprobe` with an optional ninth field, `source` (`lib/facts.sh:94-96`). Rows of 8 and of 9 fields are both read. A line with fewer than 8 fields is ignored. Columns 4, 8 and 9 are not read.
- The newest recorded tree is the tree field of the last line, in file order, that has 8 or more fields and whose tree is not `unknown-tree`.
- The run read for tree `T` is decided by the last line, in file order, whose tree is `T`: its stamp and `T` name the run. The run's rows are every line with that stamp and that tree, in file order. An older run of the same tree is never read.
- A predicate that appears more than once in the run is read from its first line.
- The reading's probe rows are (predicate, grounds, state, count) from the run. The probe's own sentence is not in the log, so a recorded reading has none. This is decided in the plan; see the mismatch noted in Task 1.

#### C3.2 The detector at a recorded tree

- The detector (`felix_detect`) runs on the live checkout only when the live checkout's tree id equals `T`. The live tree id is the one `felix probes` records for this checkout as it stands.
- When it runs, the header's commit is the live checkout's HEAD.
- Otherwise the detector is not run, and the commit is `-`.

#### C3.3 Scratch readings (`--change`)

- **The range.** A given `<base>..<head>` has each half resolved in the live repository to a commit. With no range, head is HEAD, and base is the merge base of the main ref and HEAD. The main ref is `refs/remotes/origin/main` when it exists, and otherwise `refs/heads/main`.
- **The method, decided in the plan.**
    1. One scratch directory is made, `mktemp -d "${TMPDIR:-/tmp}/felix-situations.XXXXXX"`.
    2. Each side gets its own clone under it, `<scratch>/base` and `<scratch>/head`.
    3. Each clone is made with `git clone --shared --no-checkout --template=` from the repository's common git directory. So a linked worktree and a main checkout clone alike.
    4. Then `git checkout --detach -q <sha>` runs in the clone.
    5. Both commands run with no global and no system git config, with `GIT_NO_LAZY_FETCH=1`, and with stdin from `/dev/null`. So no hook, template, filter driver or lazy fetch from the person's git config runs.

- **The tree id.** A side's tree id is `felix_tree_id_on <clone> <sha> <home>`, taken right after the checkout and before anything runs in the clone. It equals the id that `felix probes` records for a clean checkout of the same commit with no untracked file.
- **What is read.** The detector and every row of the project's current `probes.tsv` (from the Felix home) then run in the clone (`felix_probes_run <proj> <clone>`). Each probe row keeps its detail sentence (`lib/probes.sh:255-357`).
- **Tracked content only.** The live checkout's uncommitted edits and untracked files are read by neither side.
- **Removal.** The scratch directory is removed before the first byte of the report is written. It is also removed on exit 3 after it was made, and on TERM, HUP and INT, which then exit 143, 129 and 130.

#### C3.4 What never changes, in every mode

- Nothing under the governed checkout has an mtime newer than a marker touched before the run. That covers its working tree and its `.git`, and for a linked worktree also the repository's common git directory. `felix situations` runs its git reads of the live checkout with `GIT_OPTIONAL_LOCKS=0` (decided in the plan), so even the index's stat cache is left alone.
- `git for-each-ref`, every worktree's HEAD, `git worktree list --porcelain`, the config file's bytes, `git ls-files -s` and `git status --porcelain` are unchanged.
- Nothing under the memory root changes, `facts.log` included, byte for byte.
- Nothing under the Felix home changes.
- `TMPDIR` holds afterwards exactly what it held before. That is true on exit 0, on exit 3, on 129, 130 and 143, and when the reader closes the pipe early (`| head -1`).
- No `gh`, `curl`, `wget`, `ssh`, `nc` or `claude` process is started. A command named in a project's own `probes.tsv` is the project's.

### C4. Terms and class states

A class's `applies` is a space-separated list of terms, and all of them must hold. At one reading, each term is true, false or undecided.

- **`probe:<p>=<s>`**, where `<s>` is `found`, `empty` or `not-applicable`. This is decided in the plan: under §7.4 a term on `blind` or `unknown` would be true and undecided at once. Its reading is p's first row in the reading.
    - It is true when that row's state is `<s>`.
    - It is undecided when the state is `blind` or `unknown`, or when there is no row for p.
    - Otherwise it is false. That includes `not-applicable` when `<s>` is not `not-applicable`.

- **`cap:<c>`**. Its grounding rows are the reading's probe rows whose grounds field is exactly `<c>`, in reading order. It is decided in this order:
    1. Any grounding row reads `found`: true.
    2. Otherwise, any reads `blind` or `unknown`: undecided.
    3. Otherwise, any reads `empty`: false.
    4. Otherwise, when there is no grounding row or every one reads `not-applicable`, the detector decides. True when it ran and names `<c>`. Undecided when it ran and does not name it, and undecided when it did not run. Detector silence is never false.

- **`env:maturity>=<v>`**, where `<v>` is a maturity.
    - The declared value is project.json's `"maturity"` string, read from the Felix home's `projects/<p>/project.json` with `felix_json_str`. It is the same value on both sides.
    - The order is `prototype < internal < public-beta < production`. This is decided in the plan from `felix:1196` and `felix:1199`: the design listed three of these four values.
    - True or false by rank. Undecided when nothing is declared, or when the declared value is not one of the four. Such a term is then also listed as unbound, because §7.8 counts an axis with no value as an unbound predicate.

- **Unbound terms.** These are undecided, and are listed in the residual as unbound:
    - any term in another form: a `probe:` state outside the three, an `env:` axis other than `maturity`, an `env:maturity>=` value outside the four, an empty `cap:` name, or no known prefix;
    - a well-formed `probe:<p>=<s>` whose p no row of the project's current `probes.tsv` defines. It is evaluated from the reading as above, and listed as unbound as well.

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

- A `probe:` term differs when p's first row has a different (state, count) on the two sides. A row on one side only also differs.
- A `cap:` term differs when the sequence of its grounding rows' (predicate, state, count), not-applicable rows included, differs. It also differs when the detector's answer differs on a side where step 4 decided: names it, does not, or was not run.
- An `env:` term never differs.

**In `--at` mode**, the token follows the one state: ACTIVE is `standing`, UNKNOWN is `could-not-look`, and DORMANT is `none`.

The token order is the order in which each token first appears in §7.5's table: `owed`, `standing`, `blinded`, `could-not-look`, `retired`, `none`.

### C6. Ids

- A class's id is `owed:` followed by the first 12 hex digits that `git hash-object --stdin` prints, run outside any repository, for the bytes `<class>\t<project>\t*` with no trailing newline. `<project>` is the basename of the project directory, the name under `projects/`.
- A part computes the expected id the same way from `$TMP`: `printf '%s\t%s\t%s' paid_ingress web1 '*' | git hash-object --stdin | cut -c1-12`.
- The id is the same in `--at`, in `--change` and across runs.

### C7. Grounds, readings and witness

**The grounds string.** One item per term, in applies order, joined by `, ` (comma and space).

- `probe:<p>=<s>` gives `<p> <state>` from p's first row, or `<p> no reading`.
- `cap:<c>`, when some grounding row is not `not-applicable`, gives every such row in reading order as `<pred> <state> (<c>)`, joined by `, `. Otherwise it gives `<c> detected`, `<c> not detected` or `<c> detector not run`.
- `env:maturity>=<v>` gives `maturity <declared>`, or `maturity undeclared`.
- An unbound term in another form gives `<term> unbound`.
- For fixture (a), whose class applies `cap:api cap:llm`, the string is exactly `http_route found (api), llm detected`.

**The readings string.** `<pred>=<state>/<count>` for each probe row the class's terms consult: probe terms' first rows, and every grounding row of a `cap:` term, not-applicable ones included. The items are in first-use order, without repeats, joined by one space. It is `-` when there are none.

**The witness.** When a class is DORMANT on a side, look at its first false term in applies order.

- A `probe:` term gives a witness of `<p> <state>`, p's first row's reading.
- A `cap:` term made false at step 3 gives `<pred> empty`, from the first grounding row in reading order that reads `empty`.
- An `env:` term gives no witness.

### C8. `--tsv`

- One line per class in the table, every class:

```
<id>\t<class>\t<verdict>\t<base>\t<head>\t<base_grounds>\t<head_grounds>\t<owes>
```

- `<base>` and `<head>` are STATE words. In `--at` mode `<base>` and `<base_grounds>` are `-`, and `<head>` and `<head_grounds>` are the reading's. `<owes>` is the table's cell, byte for byte.
- Then the residual lines (C10): `residual\t<kind>\t<name>\t<why>`.
- **Order.** Class lines first, by token order (C5), then by class name compared as bytes. Then residual lines, by kind order (C10), then by name, then by why, compared as bytes. Residual lines are unique.
- No header line, no count line, no blank line.
- Identical bytes under `LC_ALL=C` and under `LANG=en_US.UTF-8` with `LC_ALL` unset.

### C9. The human report

```
situations for <project>
  base  <sha40>  tree <tid>  scratch
  head  <sha40>  tree <tid>  scratch

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

- **Header.** In `--change` it is the two lines shown. In `--at` it is one line: `  at  <sha40 or ->  tree <tid>  recorded <stamp>`.
- **Sections.** In `--change`: `owed`, `blinded`, `retired`, `standing`, `residual`, in that order. In `--at`: `active`, `dormant`, `residual`. The `--at` sections and every line's layout are decided in the plan; the design gives only the `--change` order.
    - Each section header is preceded by one blank line.
    - A section with no row prints `  none`.
    - In `--change`, classes whose token is `could-not-look` or `none` are in no section. In `--at`, UNKNOWN classes are in no section. These appear only in the residual and the count.
    - Rows within a section are ordered by class name, compared as bytes.

- **A row.**
    - In `--change` the row line is `  <id>  <class>  <BASE> -> <HEAD>`, then the lines `    grounds  `, `    readings  `, zero to two `    witness  <side>: <witness>` lines (base first; one for each side where the class is DORMANT and C7 gives a witness), and `    owes  <owes>`.
    - In `--at` the row line is `  <id>  <class>  <STATE>`, with `    grounds  <grounds>`, `    readings  <readings>`, `    witness  <witness>` when C7 gives one, and `    owes  <owes>`.

- **Residual.** The residual section lists the same lines as `--tsv`, in the same order, as `  <kind>  <name>  <why>`.
- **Count line.** `<N>` is the number of classes in the table, and `<A>`, `<D>` and `<U>` count them by state at head, or at the reading. It is preceded by one blank line. It is the last line unless `--propose` was given.

### C10. The residual

The kinds, in this order:

**1. `could-not-look`.**

- Name: the class. Why: `<side>: <term>: <reason>`.
- There is one line per side on which the class is UNKNOWN, per undecided term, in applies order. So `blinded` gives head lines, `owed` with base `UNKNOWN` gives base lines, and `could-not-look` gives both.
- The reasons:
    - A `probe:` term, or a `cap:` term at step 2 (taking the first grounding row in reading order that reads `blind` or `unknown`):
        - from a scratch reading, `<pred> read <state>: <the probe's own sentence>`;
        - from a recorded reading, `<pred> read <state> when recorded; the fact log keeps no sentence`.
    - A `probe:` term with no row: `no reading of <p> on this side`.
    - A `cap:` term at step 4:
        - no grounding row, detector silent: `no probe grounds <c> and the detector does not name it`;
        - every grounding row not-applicable, detector silent: `every probe grounding <c> is not-applicable and the detector does not name it`;
        - the same two with `the detector could not be run at this tree` in place of `the detector does not name it`, when the detector did not run.
    - An `env:` term:
        - `project.json declares no maturity`;
        - `project.json declares maturity '<m>', which is not one of prototype internal public-beta production`.
    - An unbound term in another form: `not a term this slice can evaluate`.

**2. `unbound`.**

- Name: the term as written.
- Why:
    - for a well-formed `probe:<p>=<s>` whose p no row of `probes.tsv` defines, `no row of probes.tsv defines <p>`;
    - for an `env:` term on another axis, `only env:maturity can be evaluated in this slice`;
    - for a well-formed `env:maturity>=<v>` while nothing is declared, `project.json declares no maturity`;
    - for the same while the declared value is not one of the four, `project.json declares maturity '<m>', which is not one of prototype internal public-beta production`;
    - for any other form, `not a term this slice can evaluate`.

- There is one line per distinct term across all classes.

**3. `no-row`.**

- Name: a capability that the detector named on a side read, or that some probe row of a side read grounds, and that no class's applies uses as `cap:<c>`.
- Why: `named by <sources>`. The sources are `the detector` first, when it named the capability, then `probe <pred>` for each grounding predicate in byte order, joined by `, `.

**4. `read`.**

- Name: the side.
- Why:
    - in `--change`: `scratch checkout of <sha40>, tree <tid>, tracked content only`;
    - in `--at`: `recorded <stamp>, tree <tid>, detector run on this checkout at <sha40>`, or `recorded <stamp>, tree <tid>, detector not run: no checkout stands at this tree`.

- So the residual is never empty.

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
- **The `row` line.** Its seven cells are separated by real tab bytes. The pathway `unknown`, the applies `-` and the evidence `exit 2` are decided in the plan: no checker exists in this slice, so the draft says so. Admitted at a blocking class, the row holds on authority until someone writes an evidence contract. The founder decides that at admission.
- **`<preds>`.** The predicates the class's true terms rest on: each `probe:` term's predicate, and for a `cap:` term made true at step 1, its grounding rows that read `found`. They are in first-use order, without repeats, and only those the project's current `probes.tsv` defines. Joined by `,`, or `-` when there are none. For fixture (a) it is `http_route`.
- **`<command>`.** One line, where `P` is the project directory's absolute path, `H` the Felix home's absolute path, and every quoted value has each `'` written as `'\''`:

```
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' '<class>' '<CLASS>' 'unknown' '-' 'exit 2' '<preds>' '<owes>' >> 'P/obligations.tsv' && git -C 'H' add -- 'P/obligations.tsv' && git -C 'H' commit -q -m 'obligations: admit <class>' -- 'P/obligations.tsv'
```

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
- `applies` holds one or more terms, every one in a form C4 evaluates.
- `class_by_maturity` names each of `prototype`, `internal`, `public-beta` and `production` exactly once, as `maturity=CLASS` pairs joined by `,`. Each CLASS is one of `obligations.tsv`'s classes, and the classes do not decrease as maturity rises. Both rules are decided in the plan: the design's example names three maturities, and the engine has four (`felix:1196`, `felix:1199`).
- `source` is `miss:<12 hex>` or `cite:<12 hex>`: the first 12 hex digits of `git hash-object --stdin` over the recorded miss or the cited passage. The passage itself is kept in the branch's handoff note, never in the table.
- No name of a directory under the home's `projects/`, other than `felix`, appears anywhere in the file, comments included, compared without regard to case. (`felix` is the engine's own name, which `bin/independence-scan` exempts too.)

**The seed** holds six to eight rows. The rows are drafted in Task 1, within §7.2's rules, from the three projects' recorded misses and v3.2 §10. Task 1 commits them before the blind stage. They must contain:

- **R1 (paid ingress).** A class named `paid_ingress` whose applies is exactly `cap:api cap:llm`, and whose owes names a request bound and a spend bound.
- **R2 (a second HTTP class).** At least one more class whose applies holds `cap:api`. A class is HTTP-keyed when its applies holds `cap:api`.
- **R3 (loopback binding).** At least one class whose owes is a bind to loopback only. Its applies holds a `probe:<p>=found` term on a predicate that enumerates a listener meant for one machine's own use, and it holds no `cap:api` term. So a node that serves a cluster on every interface reads that predicate `empty` and leaves the class DORMANT.
- **R4 (no web term).** At least one class whose applies holds no `cap:api` and no probe term on a route or listener predicate, and which a bash repository and a cargo workspace can both make ACTIVE and DORMANT.

**Siblings (falsifier 6).** For every row the shipped table holds, part 1960 builds, in a fixture project with an invented name, one repository with two commits that differ only in the surface the row stands on.

- The project's `probes.tsv` defines every predicate the row names. Each `cap:` term is grounded either by a probe row or by a root-level manifest the detector reads. `project.json` declares a maturity when the row has an `env:` term.
- `--change <with>..<without>` reads the class `retired`, with a `    witness  head:` line.
- `--change <without>..<with>` reads it `owed`.
- A ledger in the part asserts that every class in the shipped table, at least six, was read both ways.

### C13. Fixtures: pointing the engine at a fixture

- **Engine.** Use `$FROOT/harness/felix` (`$FELIX`) for parts that use the shipped seed. For a substituted table, use a copy: `cp -R "$FROOT/harness" "$X/harness"`, then write `$X/harness/templates/situations.tsv`.
- **Home `H`.** `H/projects/<p>/project.json` as `{"name":"<p>","remote_match":"example.invalid/<p>","gate":"true"}`, plus `"maturity":"<m>"` when a part needs one. Then `H/projects/<p>/CLAUDE.md`, `H/projects/<p>/probes.tsv` (`predicate\tgrounds\twhen\tprobe\twitness`), and an optional `obligations.tsv`.
- **Checkout `C`.** Made with `git init -q -b main`, holding a committed `.felix` whose content is `<p>`. Commits may pin `GIT_AUTHOR_DATE` and `GIT_COMMITTER_DATE`. The main ref is `refs/heads/main`. A feature branch makes the default range.
- **Memory root `M`.** The facts are at `M/<p>/facts.log`. A part may write rows by hand, in the C3.1 format, or record them with `felix probes`, which records the live tree.
- **A run.** `( cd C && env FELIX_HOME=H FELIX_MEMORY=M TMPDIR=T <engine> situations ... ) >out 2>err; rc=$?`, where `T` is a fresh empty directory per run. A run that compares the live tree runs `felix probes` first, in the same environment, with nothing changed between the two.
- **The clock.** Slice 1 reads no clock. No current date or time appears in any output, and the only time printed is a recorded stamp. The suite pins no clock for this slice.
- **The network.** Stubs for `gh`, `curl`, `wget`, `ssh`, `nc` and `claude` go first on `PATH`. Each appends its argv to a log and exits 1. `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GH_TOKEN` and `GITHUB_TOKEN` are unset. The log must stay empty.
- **Detector facts** (existing engine behaviour, `lib/detect.sh`), for fixture design:
    - `api` is named when a root-level manifest holds, as a case-insensitive substring, one of `fastapi flask django express next fastify starlette`. `llm` is named for one of `anthropic openai langchain llama-index llamaindex mistralai cohere ollama google-generativeai litellm instructor dspy transformers`.
    - The manifests read are `pyproject.toml`, `requirements.txt`, `requirements/*.txt`, `setup.cfg`, `Pipfile`, `package.json`, `Cargo.toml`, `go.mod`, `Gemfile`, `composer.json`, `build.gradle`, `pom.xml` and `*.csproj`, at the root only. A workspace member's manifest is never read, and `axum` is no token.
    - `ci`: `.github/workflows/*.yml` or `*.yaml`, `.gitlab-ci.yml`, `azure-pipelines.yml`. `tests`: a `tests`, `test`, `spec` or `__tests__` entry at the root. `rust`: a root `Cargo.toml`. `secrets`: `.env.example` or `.env.sample`. `frontend`: `package.json`, or three tracked web-asset files.
    - Avoid incidental tokens: `nextest` names api.

- **Probe states** (`lib/probes.sh:255-357`), for fixture design:
    - `when` exits 1: `not-applicable`.
    - The probe exits 0 with at least one non-blank line: `found`, with the count of non-blank lines and the sentence `<n> member(s) enumerated`.
    - The probe exits 127: `unknown`, `a command in the probe does not exist here, so nothing could be looked at`.
    - Lines and a non-zero exit: `unknown`, partial.
    - Nothing, and no witness: `unknown`.
    - Nothing, and the witness exits 0: `blind`, `the witness proves this surface exists and the probe enumerated none of it`. When the probe exited `<rc>`: `the witness proves this surface exists and the probe exited <rc>`.
    - Nothing, and the witness exits 1: `empty`.

- **Suite helpers.**
    - `ok NAME`, `bad NAME [DETAIL]`, `is NAME GOT WANT`, `has NAME HAYSTACK NEEDLE` and `skip NAME WHY`.
    - `_fx_cd DIR` (in a subshell) and `_fx_git DIR ARGS...` for every fixture git write; `_copy_content SRC DEST`.
    - `$TMP`, `$REAL_HARNESS`, `$FROOT` and `$FELIX`.
    - `_locale_bytes_vars` (`tests/lib/locale-bytes.sh`, sourced at `tests/run:146`), which sets `LCB_U8` to the installed `en_US` UTF-8 locale, or empty, and `LCB_NONE` to the skip reason. A part calls it before reading either.

- **Manners.**
    - Fixtures live under `$TMP/s<part number>`. No `cd` happens in the suite's own shell. No `cmd | grep -q`; use `case` or `has`.
    - Each part is self-contained, so it needs no `groups.tsv` row, and runs alone under `tests/run --part <name>`.
    - Every assertion that could pass against an engine without the command, such as "nothing changed", includes the run's exit status in the value it compares.
    - Assertion names begin with the part's number and are unique in the suite.

### C14. Pinned assertions for the review focus

Each is pinned by assertions in part 1970 whose names begin `1970 rf1` to `1970 rf7`, one prefix per item.

- **RF1, a linked worktree.**
    - Fixture: a repository with a linked worktree `W`, made with `git worktree add`.
    - `--change` run from `W`, with the default range and with an explicit one, exits 0.
    - Its head commit is `W`'s HEAD.
    - `git worktree list --porcelain`, the refs, every worktree's HEAD and the config bytes are unchanged.
    - Nothing under the main checkout, under `W`, or under the common git directory is newer than a marker.

- **RF2, an untracked environment.**
    - Fixture: a probe that reads `found` only while an ignored, untracked file is present (for example `.ready`), with a witness on a tracked file.
    - After `felix probes` in the live checkout, `--at` reads the class ACTIVE.
    - `--change HEAD~1..HEAD`, over a commit that does not touch the surface, reads it `could-not-look`: UNKNOWN on both sides, never DORMANT, `retired` or `none`. The residual has `could-not-look` lines for `base:` and `head:` naming the term.

- **RF3, the caller's locale.**
    - Fixture: a substituted table whose classes include `ab` and `a_c`, and owes that differ in case.
    - `--tsv` and the human report are byte-identical under `LC_ALL=C` and under `LANG=$LCB_U8` with `LC_ALL` unset, in both modes.
    - `a_c` comes before `ab`.
    - Skipped by name with `$LCB_NONE` when no such locale is installed.

- **RF4, an interrupted run and an early close.**
    - Fixture: a `--change` whose head-side probe runs `sleep 3` first.
    - TERM sent to the felix process during the sleep: exit 143, and `T` is empty afterwards.
    - The same with HUP: 129.
    - The same with INT: 130. The run must be started with INT at its default disposition (`perl -e '$SIG{INT}=q(DEFAULT); exec @ARGV' ...`), since a script's background job ignores INT.
    - `felix situations --change ... | head -1` leaves `T` empty.

- **RF5, quoting in the admit command.**
    - Fixture: a substituted table whose ACTIVE, unadmitted class has owes `don't drop 100% of the \n bound`, with a literal backslash and n. The fixture home is a git repository with one commit.
    - `--propose` exits 0 and leaves `obligations.tsv` and the home's `git status --porcelain` unchanged.
    - Running the printed `admit` command with `bash -c` appends exactly the `row` line's bytes to `P/obligations.tsv`, and makes one commit that touches only that file.
    - A second `--propose` no longer lists the class.

- **RF6, the caller's git config.**
    - Fixture: `HOME` names a directory whose `.gitconfig` sets `init.templateDir` (a template whose `hooks/post-checkout` writes a marker), `core.hooksPath` (a directory whose `post-checkout` writes a marker), and `filter.fx.smudge` (which writes a marker). The repository's `.gitattributes` holds `* filter=fx`.
    - `--change` exits 0 and evaluates its classes, and no marker exists.

- **RF7, a facts log shared by worktrees.**
    - Fixture: two worktrees `W1` and `W2` of one project at different trees. `felix probes` runs in `W1`, then in `W2`.
    - `felix situations` in `W1` reads `W2`'s tree, the newest. Its header names that tree. Its `read` line says `detector not run: no checkout stands at this tree`.
    - `--at` with `W1`'s tree id runs the detector.

### C15. The lane rows this PR sets

The tables are slice 0's. Their formats come from design §6.3, and slice 0's plan fixes them: `projects/<p>/lanes.tsv` is `lane counts share window`, and `projects/<p>/lane-next.tsv` is `lane next`. No part checks felix-home's own rows. This PR sets:

- `projects/felix/lanes.tsv`: `capability\t^engine/\t1/4\t14`
- `projects/felix/lane-next.tsv`: `capability\tcome-backs, slice 2: felix retro (docs/2026-10-29-capability-lane-first-slices-design.md, section 8)`. The wording is decided in the plan, in the shape of the slice 1 row §6.3 gives.

### C16. The blind parts

The driver lines go after `tests/run:378` (`1800-...`) and before `2030-...`, one line per part, in number order. Each part's first line is `printf '\n%s\n' 'situations: <topic> (blind)'`.

| Part | Covers | Fixtures |
|---|---|---|
| `1900-situations-table-blind.sh` | C12: format, schema row, cells, R1 to R4, six to eight rows, no project name. C1: `felix help` holds `felix situations`. Every `engine/harness/lib/situations*.sh` has under 500 lines, and at least one exists. | the shipped table, `templates/schemas.tsv`, the home's `projects/` names |
| `1910-situations-recorded-blind.sh` | §7.3 recorded, §7.4, C3.1, C3.2, C4 (every term rule, the maturity order with `internal`, unbound terms), C3.4 for `--at`, C2's `--at` exits, C10 recorded reasons | a substituted table; hand-written `facts.log` with 8- and 9-field rows, two runs of one tree, a newer tree, `unknown-tree` rows, a short line; `felix probes` for the live tree |
| `1920-situations-change-blind.sh` | §7.3 scratch, §7.5, C3.3, C3.4 for `--change`, C5 (every row of the table, both kinds of "differs"), the default range, C2's `--change` exits, the current `probes.tsv` on both sides, tracked content only, the scratch tree id equal to the recorded one for a clean checkout | a substituted table; one repository whose commits produce each verdict |
| `1930-situations-output-blind.sh` | §7.6 to §7.8, C6 to C10, (c), (d), (i), falsifier 2, usage errors, `need_value`, stderr empty on success | a substituted table; a bash-harness fixture (scripts, `tests/`, a CI workflow, no manifests); network stubs |
| `1940-situations-web-fixture-blind.sh` | (a), (f), (g), (h); C11 | the shipped seed; `requirements.txt` naming fastapi and anthropic; one POST route; an `http_route` probe grounding api (a shell command over tracked files, with a witness) |
| `1950-situations-cargo-fixture-blind.sh` | (b), falsifier 5 | the shipped seed; a cargo workspace whose member depends on axum, with no probe grounding api; every other term of each HTTP-keyed class made true by a probe row (for `paid_ingress`, one grounding `llm` that reads found), so that adding a probe row that grounds api makes every HTTP-keyed class ACTIVE; a node that binds every interface |
| `1960-situations-seed-siblings-blind.sh` | §7.2's siblings rule, falsifier 6 (C12) | the shipped seed; one invented project per row |
| `1970-situations-review-focus-blind.sh` | C14, RF1 to RF7 | as each RF says |

No fixture needs python, fastapi, an SDK or a cargo toolchain: probes are shell commands over tracked files, and the detector reads manifest text.

## Review Focus

The five input classes most likely to bite a person that no acceptance bullet exercises, most likely first. Each is pinned in C14.

1. `felix situations --change` run from a linked worktree, which is how every felix-home session works. Pinned by `1970 rf1`.
2. A probe that needs the live checkout's untracked environment reads blind in a scratch clone. It must land as `could-not-look`, never as DORMANT, `retired` or `none` (§7.10). Pinned by `1970 rf2`.
3. A person's Terminal locale, `en_US.UTF-8`, reorders the `--tsv` lines that slice 2 reads. Pinned by `1970 rf3`.
4. A run stopped part way, or a reader that closes the pipe early, leaves scratch clones under `TMPDIR`. Pinned by `1970 rf4`.
5. Owes text holding `'` or `%` breaks the printed admit command when the founder pastes it. Pinned by `1970 rf5`.

Also pinned: the caller's git config running hooks or filters in a scratch checkout (`1970 rf6`), and the newest recorded tree belonging to another worktree (`1970 rf7`).

## Tasks

### Task 1: Pre-flight, the seed and its schema row

**Stage:** spec. Opus 5.5, high.

**Files:**

- Create `engine/harness/templates/situations.tsv`.
- Modify `engine/harness/templates/schemas.tsv`: insert after line 130 (`discover-rules.tsv`).
- Modify `docs/handoff/pending/20261029T213800Z-claude-lane-situations-owed.md`: append a "Slice 1 build" section.
- Test: part 1900 (Task 2).

**Interfaces:**

- Consumes: the three projects' `probes.tsv` (`/Users/a14808/Documents/Felix/projects/{elenchus,veldra,felix}/probes.tsv`), the recorded misses in `/Users/a14808/.felix/memory/{elenchus,veldra}/candidates.tsv`, and v3.2 §10.
- Produces: the shipped seed, which every later blind part reads.

**Steps:**

- [ ] Check the queue.
    - Count open engine PRs: `gh pr list --state open --limit 100 --json number,files --jq '[.[] | select(any(.files[]; .path | startswith("engine/")))] | length'`. It must be 10 or fewer, or stop and wait.
    - Run `ListAgents` and confirm that no live session is on branch `claude/lane-situations-owed`.
    - Note whether slice 0 has landed on `origin/main`. Task 9 needs it, and Task 12 rebases on it.

- [ ] Draft six to eight rows meeting C12.
    - Draft against all three ecosystems at once. Derive each `source` from the passage it cites.
    - Each row goes under its own comment line saying what it is for.
    - The comments name no project.

- [ ] Add the schema row from C12, with its comment, after `schemas.tsv:130`.
- [ ] Run `engine/harness/bin/schema-check` from the worktree root. Expect exit 0.
- [ ] In the pending handoff note, record each source digest with its passage, and which row meets R1 to R4. The note may name projects, since it is not under `engine/harness`.
- [ ] Commit `docs(situations): the seed table and its schema row, the spec for slice 1`, ending with `Felix-Lane: capability`, and push.

A seed row found wrong later comes back to this task's author, and the blind author updates the parts that name it.

### Task 2: Blind parts

**Stage:** blind assertions. Opus 5.5, high. The author reads only the design, the Contracts section and the shipped seed, and never `lib/situations*.sh`, `felix` or any other code under test.

**Files:**

- Create the eight parts in C16.
- Modify `engine/harness/tests/run`: insert eight lines after line 378.
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

- [ ] Run each part alone, one at a time. First count running part runs (`pgrep -fl 'tests/run'`), and keep the Mac-wide total at four or fewer.
    - `( cd "$(mktemp -d)" && bash "$RT/base/engine/harness/tests/run" --part <part> ) > "$RT/<part>.log" 2>&1`

- [ ] Judge each log. Part mode exits 0 whatever it counted, so read the log, not the status.
    - Expected: `@@part-done <part>` is present.
    - No `  FAIL` line comes before `@@prelude-done`.
    - At least one `  FAIL` line comes after it.
    - The part's last assertion name is printed.
    - The usual failure is `felix: unknown command: situations`, and in 1900, the table being absent.
    - An assertion that passes on main is either an invariance check that includes the exit status, so it fails there, or a defect to send back to the blind author.

- [ ] Record each part's FAIL count and the base sha in the note.
- [ ] Remove the red worktree: `git -C "$WT" worktree remove --force "$RT/base"`.
- [ ] Commit `test(situations): red on main for the slice 1 parts`, ending with `Felix-Lane: capability`, and push.

### Task 4: The command, its arguments, the table and ids

**Stage:** implementation. Sonnet 5.5, high or xhigh, never max. Two red rounds move the task to Opus.

**Files:**

- Modify `engine/harness/felix`:
    - after line 365 (`. "${SCRIPT_DIR}/lib/facts.sh"`), add three source lines for `lib/situations.sh`, `lib/situations-read.sh` and `lib/situations-report.sh`;
    - after line 444 (the `felix obligations` usage line), add C1's usage entry;
    - before line 6548 (the comment above `cmd_pulse`), add `cmd_situations`;
    - after line 6688 (`obligations) shift; cmd_obligations "$@" ;;`), add `  situations) shift; cmd_situations "$@" ;;`.

- Create `engine/harness/lib/situations.sh`.
- Create `engine/harness/lib/situations-read.sh` and `engine/harness/lib/situations-report.sh`, each with its header comment.
- Test: parts 1900 and 1930, for usage, exits and the table.

**Interfaces:**

- `cmd_situations "$@"`: parses C1 with `need_value` for `--at` and `die "usage: felix situations [--at <tree> | --change [<base>..<head>]] [--tsv | --propose] (got: <arg>)" 2`; runs `resolve_or_die`; runs `export GIT_OPTIONAL_LOCKS=0`; reads the table; exits as C2 says.
- `felix_situations_table <file>`: prints the table's rows verbatim, in file order. Status 0, or status 3 with `<file>: <why>` (C2's list) on stderr.
- `felix_situations_id <class> <project>`: prints `owed:<12 hex>` (C6).

**Steps:**

- [ ] Implement the interfaces above.
- [ ] Run parts 1900 and 1930 alone, as in Task 3, against `$WT`. Expect 1900 to have no FAIL. In 1930, expect the usage, `need_value`, table-refusal and id-format assertions to pass.
- [ ] Commit `feat(situations): the command, its flags and the situation table`, ending with `Felix-Lane: capability`, and push.

### Task 5: Recorded readings, evaluation and the `--at` report

**Stage:** implementation. Sonnet 5.5, high or xhigh.

**Files:**

- Modify `engine/harness/lib/situations-read.sh` (recorded readings).
- Modify `engine/harness/lib/situations.sh` (evaluation).
- Modify `engine/harness/lib/situations-report.sh` (human and `--tsv`).
- Modify `engine/harness/felix` (`cmd_situations`, the `--at` path).
- Test: parts 1910, 1930 and 1940, the `--at` assertions.

**Interfaces:**

- **The reading file**, one per side. Its lines are tab-separated and come in this order:
    - `how\trecorded|scratch`
    - `commit\t<sha40>|-`
    - `tree\t<tid>`
    - `stamp\t<stamp>|-`
    - `detector\trun|not-run`
    - zero or more `cap\t<capability>` lines: the detector's names, sorted and unique, present only when it ran
    - then `probe\t<pred>\t<grounds>\t<state>\t<count>\t<detail>|-`, in reading order

- `felix_situations_newest_tree <log>`: prints the tree (C3.1). Status 0, or 3.
- `felix_situations_read_recorded <log> <tree> <out>`: writes the reading's `how`, `tree`, `stamp` and `probe` lines. Status 0, or 3 when no run is recorded.
- `felix_situations_live_detect <root> <home> <tree> <out>`: appends `commit`, `detector` and `cap` lines (C3.2).
- `felix_situations_eval <rows> <reading> <defined-preds> <maturity>`: prints these lines:
    - `class\t<class>\t<STATE>\t<grounds>\t<readings>\t<witness>|-\t<key>`, one per class in table order. `<key>` is the comparison C5 defines, as one string.
    - `undecided\t<class>\t<term>\t<reason>`, for every undecided term. `<reason>` is C10's reason.
    - `unbound\t<term>\t<why>`.
    - `seen\t<capability>\tthe detector|probe <pred>`.

- `felix_situations_report <mode> <format> <proj> <rows> <base-eval>|- <head-eval> <base-reading>|- <head-reading>`: prints C8 or C9. `<mode>` is `at` or `change`; `<format>` is `human` or `tsv`.

**Steps:**

- [ ] Implement the interfaces, following C3.1, C3.2, C4, C7 and C8 to C10.
    - Every `sort` and `uniq` runs under `LC_ALL=C`.
    - The awk uses no gawk-only name.
    - Any `[[ =~ ]]` sits in a function with `local LC_ALL=C`.

- [ ] Run parts 1910, 1930 and 1940 alone. Expect 1910 to have no FAIL. In 1930 and 1940, expect every `--at` assertion to pass.
- [ ] Commit `feat(situations): recorded readings, three values and the --at report`, ending with `Felix-Lane: capability`, and push.

### Task 6: Scratch readings, verdicts and the `--change` report

**Stage:** implementation. Sonnet 5.5, xhigh. This task touches the repository-untouched rule, so a red round here goes to Opus at once.

**Files:**

- Modify `engine/harness/lib/situations-read.sh` (the range and scratch readings).
- Modify `engine/harness/lib/situations.sh` (verdicts).
- Modify `engine/harness/lib/situations-report.sh` (the `--change` sections).
- Modify `engine/harness/felix` (the `--change` path).
- Test: parts 1920, 1930, 1940 (f) to (h), 1950 and 1970 (RF1 to RF4, RF6, RF7).

**Interfaces:**

- `felix_situations_range <root> [<range>]`: prints `<base-sha40>\t<head-sha40>`. Status 0, or 3 with C2's sentence.
- `felix_situations_scratch_begin`: sets the global `_FELIX_SITUATIONS_SCRATCH` to an empty string, installs the traps, then makes the directory. Status 0, or 3. The traps:
    - EXIT removes the directory;
    - TERM, HUP and INT remove it and exit 143, 129 and 130.

- `felix_situations_read_scratch <proj> <home> <src-gitdir> <sha> <side> <out>`: clones, checks out, takes the tree id, runs the detector, runs the probes, and writes a reading with `how scratch`. Status 0, or 3.
- `felix_situations_scratch_end`: removes the directory and puts the traps back.
- `felix_situations_verdict <base-state> <head-state> <differs 0|1>`: prints a C5 token.

**Steps:**

- [ ] Implement the scratch method exactly as C3.3 lists it.
    - The global holding the path is set empty before the trap is installed, because a trap body is read when it fires and a `local` is gone by then (precedent: `felix:3413-3417`).
    - The clone source is the repository's common git directory, made absolute.
    - Use `_felix_git_rules` (`lib/resolve.sh:1538-1544`) for the clone and the checkout, with `GIT_NO_LAZY_FETCH=1` added. It already runs git with no global or system config and no repository-pointing environment.

- [ ] In `cmd_situations`, build the whole report into a variable, call `felix_situations_scratch_end`, and only then print it (C3.3).
- [ ] Run parts 1920, 1930, 1940, 1950 and 1970 alone, at most four at once. Expect no FAIL in 1920, 1930 or 1950. In 1940, expect only the `--propose` assertions to fail. In 1970, expect only RF5 to fail.
- [ ] Commit `feat(situations): scratch readings, verdicts and the --change report`, ending with `Felix-Lane: capability`, and push.

### Task 7: `--propose`

**Stage:** implementation. Sonnet 5.5, high.

**Files:**

- Modify `engine/harness/lib/situations-report.sh`.
- Modify `engine/harness/felix` (the `--propose` path).
- Test: part 1940, and part 1970 (RF5).

**Interfaces:**

- `felix_situations_propose <proj> <home> <rows> <eval> <maturity>`: prints C11's section, from its blank line on.
- It consumes `felix_obligation_rows <proj>` (`lib/obligations.sh:119`) and `felix_probe_rows <proj>` (`lib/probes.sh:109`).

**Steps:**

- [ ] Implement C11, including the `'\''` quoting.
- [ ] Run parts 1940 and 1970 alone. Expect no FAIL.
- [ ] Commit `feat(situations): --propose drafts a row and the command that would admit it`, ending with `Felix-Lane: capability`, and push.

### Task 8: The seed through its siblings, and every part together

**Stage:** implementation check. Sonnet 5.5, high. A seed row that fails goes back to Task 1's author (Opus). A part that is wrong goes back to the blind author. Code that is wrong goes back to the implementer.

**Files:** none new.

**Interfaces:** consumes Tasks 4 to 7; produces all eight parts and the lint parts green.

**Steps:**

- [ ] Run part 1960 alone. Expect no FAIL, and the ledger names every shipped class read both ways.
- [ ] Run all eight parts alone, at most four at once. Expect no FAIL in any.
- [ ] Run the existing lint parts that judge new libraries and the driver, each alone: `0480-the-one-line-git-cannot-reconstruct.sh`, `0992-sort-comm-join-and-uniq-read-bytes-in-the-c-l.sh` with `0996-continued.sh` (adjacent, in one run), `1000-the-engine-makes-its-scratch-under-tmpdir.sh`, `1040-the-suite-is-cut-into-parts.sh` and `1497-lib-awk-gawk-names-blind.sh`. Expect no FAIL.
- [ ] Where a gawk is installed, run the eight parts once more with gawk first on `PATH`. CI runs gawk.
- [ ] Run `engine/harness/bin/independence-scan` from the worktree root. Expect exit 0.
- [ ] Check for ecosystem words: `command grep -nwiE 'python|pip|poetry|pipenv|pytest|node|npm|yarn|pnpm|rust|cargo|dotnet|gradle|maven|composer|bundler|rubygems|sentry|opentelemetry|datadog|stripe|playwright|cypress|selenium|puppeteer|supabase|prisma|alembic|sqlalchemy|drizzle|typeorm|fastapi|flask|django|express|fastify|starlette|anthropic|openai|langchain|llamaindex|mistralai|cohere|ollama|litellm|instructor|dspy|transformers' engine/harness/lib/situations*.sh`. Expect no line. Run the same over the lines this branch added to `felix` (`git -C "$WT" diff origin/main -- engine/harness/felix`).
- [ ] Commit any fix, ending with `Felix-Lane: capability`, and push.

### Task 9: The lane rows

**Stage:** implementation. Sonnet 5.5, high. It needs slice 0 on `origin/main`. Until then, rebase this branch onto it first.

**Files:**

- Modify `projects/felix/lanes.tsv`: in the `capability` row, change the share from `1/2` to `1/4`.
- Modify `projects/felix/lane-next.tsv`: change the `capability` row's `next` to C15's text.

**Interfaces:** consumes slice 0's `felix lane --tsv`.

**Steps:**

- [ ] Edit the two rows to read exactly as C15 says.
- [ ] Run `engine/harness/bin/schema-check` from the worktree root. Expect exit 0.
- [ ] Commit `data(lane): intake lands: the capability lane's share goes to 1/4, and next is slice 2`, ending with `Felix-Lane: capability`.
- [ ] Run `engine/harness/felix lane --tsv` in the worktree. Expect the target `1/4`, the new `next`, and, as the last change to `lanes.tsv`, this commit's sha and date. Push.

### Task 10: Real data (§7.9 e)

**Stage:** measurement. Sonnet 5.5, high. The runs are never part of the suite, and no engine file names either project.

**Files:**

- Create `/Users/a14808/.felix/memory/veldra/measurements/` and `/Users/a14808/.felix/memory/elenchus/measurements/`: plain files, no git repository.
- Modify the pending handoff note.

**Interfaces:** consumes `felix situations` as built; produces the measurement files and the summary the PR body carries.

**Steps:**

- [ ] Run Veldra from its checkout.
    - `cd /Users/a14808/ReserveGrid-OS`
    - Run `"$WT/engine/harness/felix" situations --at 7901ad88fd5e3857e61d51c672105ad140637a60`, and again with `--tsv`.
    - Save each to `situations-<UTC stamp>-at.txt` in Veldra's measurements directory. The first lines say, as `#` comments, the engine commit, the checkout path, its HEAD and the command.
    - Expect exit 0. Expect no HTTP-keyed class DORMANT unless its grounds show a false term resting on a witness (falsifier 5, checked by hand).

- [ ] Run Elenchus from its checkout.
    - `cd /Users/a14808/Documents/Elenchus`. It has `.venv`, `scripts/serve_invitee.py` and `src/elenchus/web/__main__.py` at `e625a88`.
    - Note `git status --porcelain` before and after; Elenchus is read-only to this work.
    - Run `"$WT/engine/harness/felix" probes`, which records facts for this tree. Then run `felix situations --propose`, and `felix situations --tsv`, saved the same way.
    - Expect `paid_ingress` ACTIVE with grounds `http_route found (api), llm detected`, and its proposed row printed.
    - If it does not read ACTIVE, fix the seed (back to Task 1) or `projects/elenchus/probes.tsv` in felix-home, adding a row, which is free. Do not change the Elenchus checkout or its environment. If the only cause is that environment, record it and say so in the PR.

- [ ] Put the summary lines in the pending note: commands, trees, each class's state, the residual's counts by kind, and the file paths.
- [ ] Commit the note, ending with `Felix-Lane: capability`, and push.

### Task 11: Adversarial review and fixes

**Stage:** review. Opus 5.5, high. Fixes: Sonnet 5.5. Part fixes: the blind author.

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

- [ ] Run mutants, each in a scratch worktree (`git -C "$WT" worktree add --detach "$M/w" HEAD`) and never on the branch. Each must turn its part red; a mutant that stays green is a missing assertion, and goes back to the blind author.
    - Detector silence read as false: 1950 and 1910.
    - An UNKNOWN head with an ACTIVE base read as `none`: 1920.
    - The scratch made with `git worktree add`: 1920 and RF1.
    - The trap removed: RF4.
    - `felix_probes_record` called in `--change`: 1920.
    - `sort` without `LC_ALL=C`: RF3, where the locale is installed.
    - The commit hashed into the id: 1930.
    - No `'\''` quoting: RF5.
    - The oldest run of a tree read: 1910.
    - `not-applicable` read as undecided: 1910.

- [ ] Apply fixes, re-run the affected parts alone, and commit each fix ending with `Felix-Lane: capability`. Push.

### Task 12: Version, record, gate and PR

**Stage:** landing. Sonnet 5.5, high.

**Files:**

- Modify `engine/.claude-plugin/plugin.json`: the version, now `0.49.309`.
- Modify `engine/harness/tests/assertions.tsv` and `engine/harness/tests/red.tsv`, through the record.

**Interfaces:** consumes the finished branch; produces the record, a passing gate and the PR.

**Steps:**

- [ ] Rebase on `origin/main`. Resolve conflicts in `felix` and `tests/run` by keeping both sides' lines.
- [ ] Set the version to the next free patch slot. That is after 0.49.313 and after whatever slice 0 and other open PRs claim, so read the titles of open PRs and the version on `origin/main`. Commit `chore(version): 0.49.<n>` ending with `Felix-Lane: capability`.
- [ ] Commit everything, so `git status --porcelain` is empty. Ask the queue owner (the "Inventory next steps" session, through `ListAgents` and `SendMessage`) whether the queue is free, and wait for a yes. Keep the Mac awake.
- [ ] Run `nohup engine/harness/tests/run --record-assertions > <log> 2>&1 &` from the worktree root and poll the log. Background Bash dies at ten minutes.
    - Expect the summary `<n> passed, 0 failed`.
    - Expect `assertions.tsv` and `red.tsv` rewritten, with `red.tsv`'s `run` row showing failed above 0, including every new part's assertions.

- [ ] Commit `assertions.tsv` and `red.tsv` with `test(situations): the record`, ending with `Felix-Lane: capability`.
- [ ] With the record finished, since red and gate never run at once in one worktree, run `nohup engine/harness/felix gate > <log> 2>&1 &` and poll. Expect the gate to pass, with its header naming this worktree.
- [ ] Push, and open the PR titled `situations: what a change owes, report-only (0.49.<n>)`. The body holds:
    - what it adds;
    - that it lands intake, so the lane's share goes to `1/4`;
    - the red counts per part (Task 3);
    - the seed rows, with their sources and which meet R1 to R4;
    - the real-data summary (Task 10).

- [ ] Label the PR `needs-founder` only if he asked to read the seed first (§7.2). Otherwise it lands on green.
- [ ] Turn on the CI monitor, and hand the PR to the landing queue.

## Coverage

| Spec item | Contract | Part | Task |
|---|---|---|---|
| §7.2 file, columns, schema row, cells | C12 | 1900 | 1 |
| §7.2 seed R1 to R4 | C12 | 1900, 1940, 1950 | 1, 8 |
| §7.2 siblings, falsifier 6 | C12 | 1960 | 8 |
| §7.2 authorization | none | none | 12 |
| §7.3 recorded readings | C3.1, C3.2 | 1910, RF7 | 5 |
| §7.3 scratch readings, an untouched repository, no `facts.log` write | C3.3, C3.4 | 1920, RF1, RF4, RF6 | 6 |
| §7.4 three values | C4 | 1910 | 5 |
| §7.5 verdicts, "differs" | C5 | 1920 | 6 |
| §7.6 ids, (i) | C6 | 1930 | 4 to 6 |
| §7.7 human, `--tsv`, exit status | C2, C8, C9 | 1930, RF3 | 4 to 6 |
| §7.7 `--propose` | C11 | 1940, RF5 | 7 |
| §7.8 residual, (c) | C10 | 1930, 1910, 1920 | 5, 6 |
| §7.9 (a), (f), (g), (h) | C7, C11 | 1940 | 5 to 8 |
| §7.9 (b), falsifier 5 | C4, C12 | 1950 | 5 to 8 |
| §7.9 (d), falsifier 2 | C3.4, C13 | 1930 | 5, 6 |
| §7.9 (e) | none | none | 10 |
| §7.10 limits | C3.3, C10 | RF2 | 6 |
| §6.3, §9 lane rows | C15 | none | 9 |
| §4 how it lands | Global Constraints | none | 1, 3, 12 |
