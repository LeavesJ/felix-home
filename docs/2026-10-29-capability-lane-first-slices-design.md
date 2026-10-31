# The capability lane's first three slices

**The lane counter, what a change owes, and come-backs.** A design to build
from, written 2026-10-29 on branch `claude/lane-situations-owed`.

The founder approved this design on 2026-10-29. A fact-check afterwards
corrected it, and each correction that changes a rule is marked "(My call.)"
and listed in §11. After that, the order is a plan, then one engine build per
slice: spec, blind assertions shown red first, implementation, review, gate.

## 1. Why this, and why now

The capability lane stalled. Direction row 15 gives it about one session in
four, but nothing counted that share. From row 25's note (10-19 07:18 UTC,
"build intake now") to `e54e31f3` (10-29), 17 landings reached main, and one of
them was a lane item: the mods round's report (#451, lane item 2), that same day.
The engine landings went to the audit, gate and suite work, a discovery test,
the lost-work page and inventory, and the pattern-kill deny row. The rest were
direction and decision documents, a branch register, research, the pitch and a
commission re-stamp. The founder did notice the gap: he raised it on 09-25,
10-18 and 10-29. What was missing was a count and a warning.

On 10-29 the founder set the share and the direction these slices serve:

- **The share.** The lane gets half of the sessions until intake lands, then
    one in four. Felix counts the share. When the lane is short, the first open
    lane item goes to the next session that starts without a task from him, and
    trust work gets the other half in the meantime. "Intake lands" means the
    intent design's §9 slice merges on main.
- **Enterprise first.** Felix's first edition is for software teams. Its first
    champion is the engineering manager, and the target is the whole engineering
    department.
- **Underneath, not a bot.** In a team, Felix starts underneath the work, on
    engineering ground: it briefs the agents, checks the changes and keeps the
    record. It is not a chat bot: "I don't want to make it so this becomes another
    Claude duet, ChatGPT bots."

The three slices:

- **Slice 0, the lane counter.** It counts the lane's share from what main
    already records, and makes a short or empty lane hard to miss. This is
    Felix's own discipline, so the stall cannot repeat silently.
- **Slice 1, what a change owes.** This is the *check*. For any change, it lists
    the situation rows the change owes, the rows it blinds, the rows already
    standing, and what Felix could not look at. The change is the unit because a
    team's unit of work is the pull request.
- **Slice 2, come-backs.** This is the *record*: which merged changes came back
    within 30 days, counted mechanically and joined to what slice 1 said each one
    owed. A change comes back when it is reverted, fixed or has its issue
    reopened. Run over a team's newest 30 to 50 changes whose 30-day window has
    closed, with newer changes listed apart as open, this is what an engineering
    manager would see in Felix's first week.

The *brief*, which hands the owed rows to an agent before it writes, is slice 5.
It is outside this design.

## 2. Who it serves

- **The founder, now.** Slice 0 runs on felix-home. Slices 1 and 2 run on his
    three repositories: felix-home (bash), Elenchus (Python web and LLM) and
    Veldra (Rust).
- **An engineering manager, next.** Slice 1's report is what Felix's check on a
    pull request will say. Slice 2's replay is the first-week view. In these
    slices, neither writes anything into a team's repository.
- **The agents a team already uses, later.** Slice 1's rows are what slice 5
    will brief them with.

## 3. Goals, non-goals and anti-goals

**Goals**

1. A lane share counted from main's own history, which reaches the founder when
    the lane is empty.
2. For any change, what it owes, derived with no model, no key and no network.
    "Could not look" is never read as "owes nothing".
3. For any repository, which merged changes came back, with the denominator,
    and whether slice 1 pointed at them.

**Non-goals**

- **No force.** Nothing here blocks a merge, holds a release, comments on a
    pull request or writes an enforcing table. Those come later: the shadow run
    (slice 3), admission (slice 4), the brief (slice 5) and supply (slice 6).
- **No admission.** `--propose` prints a draft row and the command that would
    admit it, as the intent design's §9 wrote it. Admitting stays the founder's
    commit, and admission by class is slice 4.
- **No new GitHub writes,** and no file in anyone's CI.
- **Not a time-allocation tool for teams.** Slice 0 counts Felix's own lane.
- **Not the outcome record by provider** (lane item 7). Come-back records carry
    no provider or model field.
- **No dispatching agents and no choosing models, in these slices.** The
    founder's 10-29 decisions (the handoff's items 2 and 4, in Sources) put
    dispatch in Felix's role later, under row 25's gates.

**Anti-goals.** Any of these makes the work a failure, even if it runs:

- **A project score, level or readiness grade.** That would copy Factory's
    Agent Readiness, and one number hides what was not looked at.
- **Anything a person chats with.**
- **"Could not look" shown as anything else.** It is never printed or counted
    as DORMANT, as absent, or as "owes nothing".
- **A bare come-back rate.** `felix retro` always prints it with its
    denominator, its open count and `precision: unmeasured`. The sealed report
    carries the measured precision (§8.6).
- **A model on any of these paths.** The precision sample's labels are sample
    labels, and the engine never reads them.

## 4. Constraints

- **Kernel.** Felix v3.2 with its conformance amendments governs. These slices
    are report-only. No model or key sits on their paths. The network is used
    only by slice 2's `--issues`, which is off unless asked for.
- **Engine language.**
    - Bash 3.2 and git only: no jq, no python.
    - Only awk that both BWK awk (local) and gawk (CI) run. Part 1497's
        `_awk_names` lints `lib/`.
    - `LC_ALL=C` on every sort, comm, join and uniq (part 0992).
    - `[[ =~ ]]` only inside a function that declares `local LC_ALL=C` (part 0996).
    - Flags go through `need_value` (`felix:394-396`), never a bare `shift 2`.

- **The engine names no project** (constitution invariant 1). The gate's
    independence and ecosystem sections fail on it. Everything project-specific
    lives in a `projects/<p>/` table or arrives as an argument.
- **Offline** (invariant 2) **and deterministic** (the intent design's §9 (d)
    and falsifier 2). Two runs with the network off and no key print identical
    bytes. The only network use in this design is slice 2's issue lookup. It is
    off unless asked for, and when GitHub is unreachable it reads "could not
    look".
- **A check that cannot fail is not a check** (invariant 5). Every new check is
    shown failing first.
- **Never delete a home or a memory root** (invariant 6).
- **Where state goes.**
    - Records go under the memory root (`felix_mem_dir`, `lib/resolve.sh:253-256`)
        or under `state/`.
    - Nothing is written into a governed repository: its refs, index, config and
        worktree list stay as they were.
    - `--change` never writes `facts.log`. An extra tree there would change what
        `felix_probes_drift` takes as "the last different tree" (`lib/facts.sh:170`).

- **Lane exclusions** (direction row 15). The lane never touches
    `lib/qualify.sh`, `lib/obligations.sh`, `lib/receipt.sh` or the landing
    actor's files. *My reading of the landing actor's files:*
    - `lib/automerge.sh`, `lib/green-*.sh`, `lib/land-table.sh`, `lib/notify.sh`,
        `lib/own.sh` and `lib/status-land.sh`;
    - the `felix merge` and `felix land` code paths, which include the
        shared project resolver and the table validator `lib/table.sh`
        (§11 items 46 to 48). They are the code that decides what lands,
        how a project resolves and whether a table passes. `felix land`'s
        deploy check also runs the session-start hook and the gate on the
        installed engine, as a test of it. The lane changes the hook and
        `templates/schemas.tsv`, as §6.5 and the tables rule require
        (§11 item 49).

- **Tables before code.** Each new table is a new file with one new
    `schemas.tsv` row, which is an addition and free. No column is added to an
    existing table, because that is a founder stop.
- **How it is built.** This follows the founder's 09-24 rule for engine builds.
    - `lib/`, the hooks, `felix` and `tests/run` are the adversarial tier.
    - Each slice goes through this document as its spec, then assertions written
        blind from this document alone and shown red on main, then the
        implementation, an adversarial review and the gate.
    - One engine PR per slice.

- **How it lands.**
    - No new engine branch while more than 10 engine PRs are open (direction row
        17). The engine does not count this, so the builder checks `gh pr list`
        first.
    - Each PR bumps the patch version in the PR and puts it in the title. Each
        PR takes the next free patch slot at landing; on 10-29, 0.49.310 to
        0.49.314 were claimed.
    - Every new `felix` command appears in `usage()`. Part 0480 (lines 400-417)
        asserts it only for commands in the main dispatch block (`felix:6594`).
        A command dispatched before the libraries load, as the read-only
        `audit`, `inventory` and `cost` commands are (`felix:249-272`), needs
        its own usage assertion, and each slice's plan says which. *(My call.)*
    - The suite manners recorded in memory apply:
        - commit everything before the record;
        - red and gate never share a worktree;
        - at most four part runs at once, across the Mac;
        - no whole-suite run while another session's record or gate holds the queue.

## 5. Decided by the founder

1. **The share.** He chose the option "Half until intake lands" over "One in
    four, enforced" and "Felix sets the share": the lane's share is half until
    intake lands, then one in four.
    - Felix counts the share.
    - When the lane is short, the first open lane item goes to the next session
        that starts without a task from him, and trust work gets the other half
        in the meantime.
    - "Intake lands" means the intent design's §9 slice merges on main.
    - (10-29)

2. **Enterprise first, underneath the team.** "we should really stick with the
    engineering ground first, and later use the engineering leverage to
    introduce the departmental liaison." More interaction between managers and
    engineers, and a better Slack presence, come "once we ship the MCP later
    on". (10-29)
3. **The champion.** The first champion is the engineering manager, and the
    target is the whole engineering department. (10-29)
4. **Visible value.** Felix's value has to be visible inside a team: "how we
    reflect inside an engineering team will need careful positioning". How it
    shows is not decided. My proposal, unconfirmed, has four parts: slice 2's
    replay, the pull-request check, a weekly view for the manager and an audit
    trail. (10-29)
5. **The share lands on green.** A change to the lane's share does not wait for
    his merge. He chose "No, it lands on green" over "Yes, it waits for me".
    (10-29)

One thing here is not his decision: this design builds on the intent design's
§9 slice and its §10 falsifiers (design of 10-19, on file), and marks each
departure from them.

Below, a bare §9 or §10 is the intent design's. This design's own are written
"this design's §9" and "this design's §10".

## 6. Slice 0: the lane counter

### 6.1 What it answers

It answers one question: of the engine changes that landed in the last two
weeks, how many came from the capability lane, against the share the founder
set? It also tells the next session that has no task to take the lane's first
open item. When the lane is empty, it puts that on the founder's own screen
line.

### 6.2 What counts

- **A landing** is a first-parent commit on the project's main ref. That is
    `origin/main` as last fetched; the counter never fetches, and it prints the
    ref's date. A landing's time is its committer date.
- **The window** is the half-open interval (now − window × 86400 s, now], in
    seconds, by committer time. A landing exactly `window` days before now is
    outside it. Now is the current time, pinned in tests. *(My call.)*
- **A landing counts only if it changed engine code.** At least one path it
    changed must match the lane row's `counts` pattern.
    - Direction §5 counts a lane session that lands engine code or produces a
        sealed, measured number. This slice counts only the first.
    - So a docs-only landing does not count, and neither does a sealed number,
        wherever it lives. Slice 2's sealed report, which lands as a document,
        will not count. *(My call; a stated gap.)*

- **A lane landing** is a counted landing whose message has the whole line
    `Felix-Lane: <lane>`, for example `Felix-Lane: capability`. *(My call.)*
    - A lane session puts that line in the body of a commit on its branch that
        is not a merge. *(My call.)*
    - `felix merge` copies every non-merge commit message on the branch into the
        landing's body, and none of the merge commits' messages
        (`felix:2106-2107`).
    - A squash merge on GitHub keeps those messages only when it keeps GitHub's
        default message. The founder merged PR #455 on GitHub that way, and its
        landing carries every non-merge commit message from its branch (11 of
        its 16 commits) and none of its five merges of main.
    - A hand merge that replaces the message drops the mark, and that landing
        counts as non-lane. The error runs toward `short`, which gives the lane
        more sessions, not fewer. This is a stated limit.
    - For a real merge commit on main, the commits it merged are read as well.

- **The total** is every counted landing in the window, lane or not, however it
    landed.

The share is counted in landings, not in sessions. *(My call.)* There are two
reasons:

- Direction §5 counts a lane session when it lands engine code or produces a
    sealed, measured number. This slice counts only the first, so it counts
    landings.
- Nothing durable records which sessions were lane sessions. The machine marker
    is cleared when a session ends (`hooks/session-end:53-55`, with its comment
    at `:48-52`).

### 6.3 The tables

The target and the pointer to the next item live in two tables. *(My call.)* The
target is the lane's row: its counts, share and window together. It changes
only when the founder decides, and the pointer changes with every lane PR. Kept
apart, a later guard on the target would need no change to either table.

**`projects/<p>/lanes.tsv`**, the target:

| Column | Meaning |
|---|---|
| `lane` | a name; the lane's mark is `Felix-Lane: <lane>` |
| `counts` | an ERE over changed paths; a landing counts when one matches |
| `share` | the target share, as `n/d`, with n at least 1 *(my call)* |
| `window` | days |

**`projects/<p>/lane-next.tsv`**, the pointer:

| Column | Meaning |
|---|---|
| `lane` | a lane named in `lanes.tsv` |
| `next` | the first open lane item, on one line |

felix-home's rows:

- `lanes.tsv`: lane `capability`, counts `^engine/`, share `1/2`, window `14`.
- `lane-next.tsv`: lane `capability`, next `obligation intake, slice 1: felix
    situations --change (branch claude/lane-situations-owed)`.

- **Schema.** Two `schemas.tsv` rows are added:
    `lanes.tsv tree lane counts share window allowed` and
    `lane-next.tsv tree lane next allowed`. A project with no `lanes.tsv` has no
    lane: `felix lane`, session start and the pulse print nothing for it, and
    its `felix status` row reads `none` (§6.5 item 2).
- **Who changes what.**
    - The PR that lands a lane item moves `next` in the same change. That lands
        on green.
    - The PR that lands intake (slice 1) also changes `share` from `1/2` to
        `1/4`, so "then one in four" happens in the change that makes it true.
    - A change to `lanes.tsv` lands on green, like any other change. The
        founder decided this on 10-29 (§5). `felix lane` names the commit that
        last changed the lane's row, so a lowered share shows. *(My call.)*
    - `felix lane` reads `lanes.tsv` as committed in the Felix home, never from
        its working tree, so an uncommitted edit changes nothing. *(My call.)*

### 6.4 States

Each lane row has L lane landings and T counted landings in its window, against
a target share of n/d:

| State | When |
|---|---|
| `ok` | T > 0 and L·d ≥ n·T |
| `short` | L > 0 and L·d < n·T |
| `zero` | L = 0 and T > 0: engine work landed through the whole window and none of it came from the lane |
| `idle` | T = 0: nothing counted landed at all |
| `unknown` | the main ref or a table could not be read; never printed as `ok` |

### 6.5 Where it shows

1. **`felix lane [--tsv]`.** Read-only and offline. It prints one line per lane
    with these fields:
    - the state, L and T;
    - the window and the target share;
    - the date of the last lane landing;
    - the mark, and `next`;
    - the Felix home's last commit that changed the lane's row in `lanes.tsv`,
        with its date;
    - the date of the main ref it read, since it never fetches (§6.2).

    `--tsv` prints the same fields, tab-separated. The carrier can read it when
    it picks work.

2. **`felix status`.** One new row, `lane`, goes after the nine existing rows
    (`felix_status_rows`, `lib/status.sh:463-477`), so it follows `icloud`.
    Four existing parts pin the list at nine rows ending in `icloud`: 1100
    (`:409-411`, and the nine-row guard at `:429-437`), 1690 (A1 at `:184-190`,
    A2 at `:347-356`), 1720 (A33 at `:376-379`) and 1980 (A41 at `:145-147`).
    None of their fixture homes has a `lanes.tsv`, and each still gains the
    row, so each list grows to ten rows ending in `lane`.
    - The row's state is `value`, its value is the state word, and its detail
        reads "L of T engine landings in W days, target n/d".
    - The `unknown` lane state is written the way an unreadable status row
        already is: state `unknown`, value `-`, and a detail naming what could
        not be read (`lib/status.sh:10-13` and `:26-27`). It is never a calm
        value. *(My call.)*
    - In a project with no `lanes.tsv`, the row still prints, as state `none`,
        value `-` and a detail saying no lane is counted, because the status
        contract is one line per row in a fixed order (`lib/status.sh:10-13`).
        *(My call.)*
    - The dash, the one consumer, keeps a row it does not know
        (`~/.claude/mods/dash/hooks/parse.ts:8-9`). It draws every row in its
        /dash pane (`register.tsx:355-362`), shows state `unknown` as a warning
        (`parse.ts:101-102`), and posts any change in a row's state or value
        (`register.tsx:68-73`). So "felix lane: ok → short" appears in the dash
        with no change to the dash. Putting the row on the dash's band is not
        part of this slice.

3. **Session start, in the session's context.** When the state is `short`,
    `zero` or `idle`, one paragraph gives the counts and the window and says:
    "If the founder has not given this session a task, take the first open lane
    item: `<next>`. End the body of a commit on its branch that is not a merge
    with the line `Felix-Lane: <lane>`." The lane name and the window come from
    the table. While the share is `1/2`, the paragraph ends "Trust work takes
    the other half."; otherwise it ends "The rest goes to trust work."
    *(My call.)*
    - Only the session knows whether it was given a task, so the session that
        reads the paragraph is the one that carries out the rule.
    - A session that takes the item first checks that no live session is
        already on that branch, as sessions do now.
    - The paragraph tells a session to start work nobody asked for, so it is
        said only in the project's own checkout: one whose origin remote is
        `github.com/<remote_match>` exactly and that is not a submodule
        (`lib/own.sh`, `felix_checkout_is_own`). Session start already holds
        adoption, the graph refresh and tidying to that rule. A `.felix`
        marker is a file of the tree, so any repository can name a governed
        project. Elsewhere, and wherever ownership cannot be read, the
        paragraph is withheld, and the hook's line about withheld work names
        `lane item` (`felix_own_gate`). *(My call.)*

4. **The founder's screen line** (`systemMessage`). The hook builds it at
    `hooks/session-start:747-755` and emits it at `:760` through `_felix_emit`
    (`:101-112`). When the state is `zero` or `idle`, the line gets the token
    `· lane: 0 in <window> days`. A `short` state stays in the session's
    context only. *(My call.)* Neither the token nor the paragraph shows on a
    resumed Claude Code session: the hook exits before either is built
    (`hooks/session-start:184-185`). Neither shows in a checkout that is not
    the project's own (item 3).
5. **The daily pulse.** Each record gets one line per lane,
    `lane<TAB><lane><TAB><state><TAB><L><TAB><T>`, written from `cmd_pulse`
    (`felix:6555-6559`). That puts the share's history on disk in
    `state/pulse.log`. The last run's line also lands in
    `state/pulse.status.tsv`, which every run rewrites.
6. **No push alert.** The alert channel has never delivered: every row in
    `land/alerts.tsv` is `failed`, and `felix-alert.yml` is on no branch, main
    included. Also, `notify.sh` belongs to the landing actor. So an empty lane
    is on the founder's screen line whenever a Claude Code session starts,
    other than a resume, in the own checkout of a project with a `lanes.tsv`,
    and the lane row is in the dash's /dash pane. Copilot CLI and Cursor have
    no screen line in
    this hook (`_felix_emit` drops it, `hooks/session-start:97-112`). There the
    lane shows in the context paragraph only, and their resumes run the whole
    hook: the exit at `:184-185` is for Claude Code alone.

### 6.6 Acceptance

These assertions are written blind from this document and shown red on main
first.

- **The counts.** A fixture repository holds these landings:
    - a marked engine change landed through `felix merge`;
    - a marked engine change squash-merged the way GitHub does with its default
        message, with the mark inside a copied commit message;
    - a marked docs-only change;
    - an unmarked engine change;
    - an unmarked docs-only change;
    - a real merge commit whose merged commits carry the mark;
    - a squash landing built the way `felix merge` builds one, from a branch
        whose only mark is on a merge commit: it carries no mark and counts as
        non-lane;
    - a commit whose message mentions `Felix-Lane: capability` inside a sentence,
        not as a whole line;
    - a landing exactly `window` days before the pinned clock, which is outside,
        one a second later, which is inside, and one at the clock itself, which
        is inside.

    With the clock pinned, L and T must come out exactly as §6.2 defines them.

- **The state edges.**
    - With L ≥ 2 and a share below one, L·d = n·T reads `ok`, and one lane
        landing fewer reads `short`.
    - At L = 1, one lane landing fewer reads `zero`.
    - L = 0 with T > 0 reads `zero`.
    - T = 0 reads `idle`.
    - An unreadable ref reads `unknown`, never `ok`.

- **What shows where.**
    - The session-start paragraph appears only for `short`, `zero` and `idle`.
    - The screen token appears only for `zero` and `idle`.
    - Neither appears for a project with no `lanes.tsv`, or on a resumed
        Claude Code session.
    - Neither appears in a checkout that is not the project's own (no
        `remote_match`, another origin, or no origin), and there the hook's
        line about withheld work names `lane item`. The same fixture made the
        project's own shows both.
    - While the share is `1/2`, the paragraph ends "Trust work takes the other
        half."; at `1/4` it ends "The rest goes to trust work."
    - The paragraph and the token take the lane name and the window from the
        table.

- **`felix status --tsv`.** It gains exactly one row, at the end, after
    `icloud`, and the nine rows before it are byte-identical: they take the
    shared resolver's answer, and only the lane row reads the lane's own
    (§11 item 49). An unreadable ref
    gives the row state `unknown` and value `-`, and a project with no
    `lanes.tsv` gives state `none`.
- **The last change.** After a commit that changes a lane's row, `felix lane`
    names that commit and its date. An uncommitted edit to `lanes.tsv` changes
    nothing it prints.
- **Determinism.** Two runs print identical bytes.
- **The pulse.** With the clock pinned and one lane, a pulse run appends the
    line `lane<TAB><lane><TAB><state><TAB><L><TAB><T>` to `state/pulse.log`,
    with the state, L and T that `felix lane` prints.
- **Real data**, a recorded measurement outside the suite, because it names a
    real project and commit (invariant 1, as for §7.9 (e)). On felix-home's
    main at `e54e31f3`, with the clock pinned to that commit's time
    (2026-10-29 21:26 UTC), the capability lane reads `zero`. None of the 27
    landings in the window carries the mark, and 18 of them changed `engine/`.
- **Falsified if** a hand check of what it prints for felix-home's last 60 days
    finds a landing it miscounted.

## 7. Slice 1: what a change owes

### 7.1 What it answers

For a given change, it answers four questions:

- Which situation rows does the change owe?
- Which rows does it blind?
- Which rows were already standing?
- What could Felix not look at?

The answer comes from probes and the detector, with no model, no key and no
network. This is the intent design's §9 slice, `--propose` included, with one
addition: the change mode.

### 7.2 The situation table

The table follows §9, unchanged except where marked.

- **The file.** It is `engine/harness/templates/situations.tsv`, with the
    columns `class applies owes class_by_maturity source`. One `schemas.tsv` row
    is added: `situations.tsv tree class applies owes class_by_maturity source
    refused`. The table is engine knowledge, read from the engine's templates.
    Per-project rows are not in this slice.
- **`applies`.** A space-separated conjunction of terms:
    - `probe:<cap>=<state>`: true when some probe that grounds `<cap>` reads
        `<state>`. The states are found, empty, blind, unknown and
        not-applicable (`lib/probes.sh`). Predicate names are each project's
        own, so an engine seed row cannot name one. *(My call: this restores
        §9's grammar, keyed by capability.)*
    - `cap:<name>`: a capability. `felix_detect` names thirteen (ci, deploy,
        iac, observability, billing, e2e, database, api, llm, rust, frontend,
        tests, secrets; `lib/detect.sh:72-113`), and a probe's `grounds` column
        can ground others. It keeps §7.4's precedence.
    - `env:<axis>>=<value>`: only `maturity` can be evaluated in this slice. It
        comes from `project.json`, where the engine accepts four values
        (`felix:1207`, `templates/commissioning.tsv:79`). No engine code orders
        them, so this slice orders them prototype < internal < public-beta <
        production, as v3.2's risk envelope lists them. *(My call.)* None of the
        three projects declares a maturity, so every `env:maturity` term reads
        undecided on all three. Any other axis is an unbound predicate.

- **`owes`.** What the situation owes, in plain words.
- **`class_by_maturity`.** Comma-separated `maturity=CLASS` pairs that use
    `obligations.tsv`'s class names, for example
    `prototype=INFO,internal=INFO,public-beta=ADVISORY,production=TASK_BLOCKING`.
    It is printed only, and nothing reads it for force. *(The format is my
    call.)* While a project declares no maturity, it prints with "maturity
    undeclared". *(My call.)*
- **`source`.** A digest of the recorded miss, the survey candidate or the
    cited text, never a project name. It says which of the three it is.
- **The seed.** About six rows, drafted against all three ecosystems at once.
    - They are drawn from two sources:
        - the obligation candidates the survey proposed, in Elenchus's and
            Veldra's `candidates.tsv` under the memory root (felix-home has
            none). These are proposals, not recorded misses. They carry 22
            failure modes, among them uncontrolled cost, untested route,
            unbounded storage, undeclared surface, false green, privacy exposure
            (Elenchus's launcher bound to every interface, the source of the
            loopback-binding class), supply-chain compromise, signing-key
            exfiltration and privilege escalation;
        - v3.2 §10.

    - *(My call: §9 seeds from recorded misses. Each seed row's `source` says
        whether it comes from a recorded miss, a survey candidate or v3.2's
        text.)*
    - The seed must contain:
        1. **Paid ingress.** Public ingress plus a paid outbound call owes a
            request bound and a spend bound. This is §9's example, and it is
            Elenchus's second entrypoint. It carries no `env:` term: no project
            declares a maturity, and (e) needs the class ACTIVE on Elenchus.
        2. **At least one more HTTP-keyed class**, so that (b)'s "HTTP classes" has
            more than one member.
        3. **A loopback-binding class**, for (b)'s negative fixture.
        4. **At least one class with no web term**, so the bash harness and the
            Rust node are tested on something other than HTTP.

    - Each row passes blind sibling fixtures without naming a project
        (falsifier 6).

- **Authorization.** *(My call.)* §9 says the founder's commit authorizes the
    seed: under amendments §1.1, the authorizing party is the commit.
    - The seed carries no force in this slice. So his reading of each class rides
        slice 4's admission batch, where a class first carries force, and slice 1
        waits on no one.
    - If he wants to read the seed before it lands, slice 1's PR takes the
        `needs-founder` label instead.

### 7.3 Readings

Every reading is labelled with where it came from.

- **Recorded readings.** `felix situations --at <tree-id>` evaluates the rows
    `facts.log` holds for that tree.
    - If the tree has several runs, it uses the newest.
    - It accepts both 8-field and 9-field rows (`lib/facts.sh:46-54`).
    - With no flag, it uses the newest recorded tree.
    - The gate took these readings in the live checkout, together with its
        untracked environment.
    - `facts.log` holds probe readings only; the detector's answer is not
        recorded. So in `--at` mode the detector runs on the live checkout only
        when that checkout's tree id equals the tree asked for. At any other
        tree, a capability that only the detector could decide reads undecided.
        The header says the detector was not run, and each class that could not
        look for that reason names the detector as its why in the residual
        (§7.8). *(My call.)*
    - Recording the detector's answer beside the facts, so that any recorded
        tree can later be read in full, is a later choice: it changes what the
        gate writes.

- **Scratch readings.** `felix situations --change [<base>..<head>]` takes fresh
    readings of both sides.
    - Each side is a real git checkout in an owned scratch directory, because
        probes run git commands.
    - The checkout must leave the repository untouched. A shared clone
        (`git clone --shared --no-checkout`, then a detached checkout) does that.
        A detached worktree, as in `lib/qualify-run.sh:440-462`, would add to the
        repository's worktree list while it exists.
    - Each side is read with `felix_probes_run` and `felix_detect` rooted there,
        and named by `felix_tree_id_on <root> <commit>` (`lib/verify.sh:367-372`).
    - Without a range, it reads from the merge base of the main ref and HEAD, to
        HEAD. *(My call.)*
    - Both sides are read the same way, with the current `probes.tsv` from the
        Felix home. So any difference between them is a difference in the tree, not
        in the instrument. *(My call.)*
    - Nothing is written to `facts.log`.

- **What scratch trees cannot see.** A scratch tree holds tracked content only.
    - A probe that needs an untracked environment reads blind or unknown there.
        For example, Elenchus's route probe falls back from `.venv/bin/python` to
        the system python3, which cannot import the app. Its witness file is
        tracked, so it reads blind.
    - That probe's classes land in the residual as could-not-look. That is a
        result, not a failure.
    - Giving scratch trees an environment is a later choice.

### 7.4 Three values per class

At one reading, each term is true, false or undecided:

- **`probe:c=s`** is true when some probe that grounds c reads s. It is
    undecided when none does and some probe grounding c reads blind or unknown
    or has no reading, or when no probe grounds c at all. Otherwise it is false,
    including when every probe grounding c is not-applicable.
- **`cap:c`** is decided by the probes that ground c, and by the detector only
    when no probe does. *(My call.)* In order:
    1. If any probe grounding c reads found, it is true.
    2. Otherwise, if any reads blind or unknown, it is undecided.
    3. Otherwise, if any reads empty, it is false: an empty reading means the
        witness agrees the surface is absent.
    4. Otherwise, when no probe grounds c or every one reads not-applicable, the
        detector decides: true if it names c, undecided if it does not. Detector
        silence is never false.

    The probe outranks the detector because it looks at the surface itself. The
    detector reads dependency manifests for some capabilities (observability,
    billing, e2e, api, llm and part of database) and looks only at which files
    or directories exist for the rest (`lib/detect.sh:72-113`). For api it reads
    only the manifests (`:88`, through `_felix_dep_grep` at `:17-37`), so a
    project whose dependencies name fastapi is detected as api whether or not it
    serves a route.

    *(My call, departing from §9.)* §9 says: "A capability with no grounded
    probe, or one the detector does not name, reads could-not-look." Read
    literally, that contradicts §9's own tests (a) and (b): (a) counts
    `llm detected` as a ground with no probe grounding llm, and (b) goes ACTIVE
    once a probe grounds api, which the detector does not name for axum. Here a
    capability with no grounding probe reads true when the detector names it,
    and could-not-look only when neither a probe nor the detector decides.

- **`env:a>=v`** is true or false from the declared value. It is undecided when
    no value is declared.

A class's state follows from its terms:

- It is **ACTIVE** when every term is true.
- It is **DORMANT** when any term is false.
- Otherwise it is **UNKNOWN**, which means could not look.

A false term settles the class even when another term is undecided. That is
safe because "false" always rests on a witness or a declared value, never on
silence. The report still names the undecided term beside a DORMANT class.

### 7.5 What a change owes: base against head

Each class gets a state at the base and at the head. The pair decides the
verdict:

| At head | At base | Verdict | Meaning |
|---|---|---|---|
| ACTIVE | DORMANT | owed | the change brings the situation in |
| ACTIVE | ACTIVE, and a grounding reading differs | owed | the change touches a surface the row stands on |
| ACTIVE | ACTIVE, and the readings are equal | standing | the project owes it, and this change did not touch it |
| ACTIVE | UNKNOWN | owed (base could not look) | the cautious reading |
| UNKNOWN | ACTIVE or DORMANT | blinded | the change left Felix unable to look; never DORMANT |
| UNKNOWN | UNKNOWN | could not look | reported in the residual |
| DORMANT | ACTIVE | retired | the change removed the surface; the deciding witness is named |
| DORMANT | DORMANT or UNKNOWN | none | counted only |

"A grounding reading differs" means one of two things:

- for some probe term, the (state, count) pairs of the probes that ground its
    capability differ between base and head;
- for some cap term, what decided it differs: the (state, count) pairs of the
    probes that ground it, or the detector's answer when no probe does.

Facts record counts, not members. So "touches" means a reading changed.

### 7.6 One id per owed row

- **The id** is `owed:` followed by the first 12 hex digits of
    `git hash-object --stdin` over `<class>\t<project>\t<surface>`.
- **The surface is `*` in these slices.** That makes one row per class per
    project, because facts record counts, not members. Once probes record
    members, a per-member row gets its own surface, and the `*` row stays.
- **The id never changes.** The same class in the same project has the same id
    at every tree, in `--at` and in `--change`. Every later record carries it:
    - come-backs (slice 2);
    - would-holds (slice 3);
    - admission (slice 4);
    - briefs (slice 5);
    - qualification runs (slice 6).

- *(My call.)*

### 7.7 Output

- **The human report** (the default).
    - In `--change`, the header gives the project, the base and head commits,
        their tree ids and how each side was read: in a scratch checkout, with
        the current `probes.tsv` (§7.3).
    - In `--at`, the header gives the project, the tree and the recorded run its
        readings came from. There is one reading, so each class has one state:
        ACTIVE prints as standing, UNKNOWN as could not look, and DORMANT is
        counted. *(My call.)*
    - The sections follow in a fixed order: owed, blinded, retired, standing,
        residual. A count line follows them: examined N, active A, dormant D, could
        not look U.
    - Each row shows:
        - its id and class;
        - its base and head states;
        - the grounding readings on each side, as state and count;
        - the witness, when a probe term decided the class;
        - `owes`.

- **`--tsv`.**
    - One line per class: `id class verdict base head base_grounds head_grounds
        owes`. In `--at`, the verdict is standing, could not look or none, `head`
        holds the class's one state, and `base` and `base_grounds` are `-`.
    - Then residual lines: `residual kind name why`.
    - Class lines are sorted by verdict, in the order owed (both forms), blinded,
        retired, standing, could not look, none; then by id; with `LC_ALL=C`.
        Residual lines follow, sorted with `LC_ALL=C`. *(My call.)*
    - Slice 2 reads this form, and the id and verdict columns are its contract.
    - *(The shape is my call.)*

- **`--propose`** (§9, unchanged). For each ACTIVE class with no admitted row
    in the project's `obligations.tsv`, it prints an `obligations.tsv`-shaped
    row with its grounds, and the command that would admit it. It writes
    nothing. Admission stays the founder's commit: no session commits a proposed
    row on its own, because an addition to `obligations.tsv` would land on green.
- **Exit status.** It is 0 whenever a report was produced, whether or not
    anything is owed. It is non-zero only on a usage error, or when a side could
    not be read at all, such as a base that is not a commit.

### 7.8 The residual

The residual is never empty without saying why. It lists:

- the classes that could not look, each with its undecided term and why: the
    probe's own sentence (`lib/probes.sh` prints one), or that the detector
    could not be run at that tree;
- unbound predicates: probe terms whose capability no probe in the project
    grounds, and env terms whose axis cannot be evaluated or has no value;
- cells with no row: capabilities the detector names, or probes ground, that no
    class's `applies` uses.

How each side was read is in the header, not in the residual, so no residual is
non-empty by that line alone. *(My call.)* The bash harness fixture's residual
must name at least one could-not-look class, unbound predicate or cell with no
row (§7.9 (c)).

### 7.9 Acceptance

These assertions are written blind from this document and shown red on main
first.

- **(a) Python web fixture** (from §9).
    - The fixture has a `requirements.txt` naming fastapi and anthropic, one POST
        route, and an `http_route` probe that grounds api.
    - Paid ingress reads ACTIVE, with grounds `http_route found (api), llm
        detected`.
    - `--propose` prints its row with its grounds and the command that would
        admit it, and writes nothing.
    - Deleting the route makes it DORMANT, with the witness named, even though
        `requirements.txt` still names fastapi: the probe decides (§7.4).

- **(b) Rust fixture** (from §9).
    - A cargo workspace member depends on axum. No probe grounds api, and no
        other term is false. The HTTP classes read "could not look", never DORMANT.
    - Adding a probe row that grounds api makes them ACTIVE.
    - A cluster node that binds every interface activates no loopback-binding
        class.

- **(c) Bash harness.** The residual names at least one could-not-look class,
    unbound predicate or cell with no row. Never an empty report with exit 0.
    *(My call.)*
- **(d) Determinism.** Two runs give identical bytes, with the network off and
    no key, in both `--at` and `--change`.
- **(e) Real data.** *(My call, replacing §9's "on recorded facts" for
    Elenchus.)*
    - Veldra: run `--at` on its newest recorded tree (09-25).
    - Elenchus: take a fresh reading. In an Elenchus checkout at a tree that has
        the second entrypoint and its `.venv`, run `felix probes`, which records
        facts for that tree. Then run `felix situations --propose` in the same
        checkout, so the probes and the detector read the same tree. The spend
        gap must read ACTIVE, and its proposed row must print.
    - Why fresh: Elenchus's 09-24 facts hold no probe that grounds `llm`, and the
        detector cannot be run on a tree no checkout is at. Read at 09-24, paid
        ingress is honestly "could not look".
    - If the gap does not read ACTIVE, the seed or the probes are wrong, and that
        is fixed before slice 2's replay means anything.
    - The runs name real projects, so they are recorded measurements outside
        the suite (invariant 1). *(My call, departing from §9's "done means
        (a)-(e) are green in the suite": here (a) to (d) and (f) to (i) are suite
        fixtures, and (e) is a recorded measurement.)*

- **(f) A route added in the diff** is owed by that change.
- **(g) An unrelated diff** owes no row, and the project's ACTIVE rows still
    print as standing. After the run, the repository's refs, index, config and
    worktree list, and the project's `facts.log`, are byte-identical to before.
- **(h) A diff that breaks the probe's instrument** while the routes stay reads
    blinded at head, never DORMANT or retired. For example, it renames what the
    probe imports. The detector still names api, and the blind probe still
    decides (§7.4).
- **(i) Stable ids and order.** The same class and project get the same id in
    `--at`, in `--change` and across runs. `--tsv` class lines come in the
    order owed (both forms), blinded, retired, standing, could not look, none,
    then by id. In `--at`, ACTIVE prints as standing and UNKNOWN as could not
    look; the verdict is standing, could not look or none, `head` holds the
    class's one state, and `base` and `base_grounds` are `-`.
- **Falsified if** either of these happens:
    - a stack the detector cannot see reads DORMANT on an HTTP-keyed class with
        no other term false (falsifier 5). *(My call: the qualifier refines §10's
        falsifier 5, since a DORMANT that rests on another false term is not
        detector silence. (b) carries the same qualifier.)*
    - two runs from two fresh clones, each with a fresh memory root, do not
        give identical bytes, every verdict included (falsifier 2, in §10's
        clean-machine form). *(My call.)*

### 7.10 Limits the slice states about itself

- Classes that need a capability tag that does not exist, such as plugin hooks
    or peer listeners, read could-not-look when a row names the tag, unless
    another of their terms is false, and show nowhere otherwise. *(My call: §9
    states this gap as "cells with no row", but a tag that nothing names or
    grounds cannot be such a cell, §7.8.)*
- Scratch readings see tracked content only. A probe that imports the
    application reads blind or unknown in a scratch checkout, as Elenchus's
    `http_route` does (§7.3). So on Elenchus, every class that needs api reads
    "could not look" in `--change`, unless another of its terms is false. That
    lasts until scratch trees get an environment.
- A change is seen only through readings. A change on a surface no probe reads
    shows nowhere unless it changes what the detector names at head. A
    capability the detector newly names shows as an owed row, or as a cell with
    no row when no class uses it.
- A probe that does not look where a change moved its surface reports the
    surface gone. The defence is a witness that looks wider than its probe
    (`lib/probes.sh`), not this slice.

## 8. Slice 2: come-backs

Every date in this section is UTC.

### 8.1 What it answers

Of the changes that merged, which came back within 30 days, and how? And did
slice 1 say they owed anything? No person and no model does the counting, which
runs over the repository's own history. Over a team's newest 30 to 50 changes
whose 30-day window has closed, with newer changes listed apart as open, this is
the engineering manager's first-week view. It runs first on the founder's three
repositories.

### 8.2 Which changes, and as of when

- **The command.**
    `felix retro [<repo-path>] [--last N | --since <date>] [--window 30] [--issues] [--tsv]`.
    *(The command's shape is my call. §9 named it `felix retro`.)*
    - *(My call.)* The intent design's next slice under that name (miss records,
        the first gap kinds, a replay at the miss tree) stays on file. This
        slice measures come-backs.
    - It is read-only on the repository: it never fetches, and it never touches
        the checkout. It makes scratch checkouts only for slice 1's readings, as
        §7.3 does.
    - The repository must belong to a bound project, because slice 1 needs that
        project's probes.

- **The window** is 30 days. *(My call.)* Come-backs (reverts, fixes, reopened
    issues) take longer to show than the intent design's 14-day lag window (its
    §7, set to match `felix_mem_recurring_mistakes`). The window is sealed
    (§8.5). `--window` stays a flag, and a run with any other window prints as
    unsealed.
- **The changes.** The command walks first-parent commits on the main ref,
    newest first. *(The selection rule is my call, and it is sealed, §8.5.)*
    - `--last N`, 50 by default, takes the newest N changes whose window has
        closed. `--since <date>` takes every closed change from that date on.
        Changes whose window is still open are listed apart, and never counted.
    - Taking the newest N, open or not, would give felix-home no rate at all.
        As of each clone's last fetch, all of felix-home's newest 50 changes are
        open. Elenchus has 7 open and 43 closed, and Veldra 24 open and 26
        closed.
    - Each change C has its base at `C^1`. That works for squash merges, direct
        commits and real merge commits alike. felix-home's changes are squash
        merges. Elenchus's 50 measured changes are mostly direct commits (37),
        with 8 squash merges and 5 real merges; its newer changes are all squash
        merges. Veldra's are merge commits and direct commits.
    - Its added lines come from `git diff -U0 -M C^1 C`, so a file C only moved
        does not count as added. *(My call.)* felix-home's `f1eee4c3` moves six
        handoff notes and changes one line in each. With renames detected those
        six files add 6 lines; with `--no-renames` they would add 337.

- **As of when.** Results are as of the time the main ref was last fetched. That
    is neither the last commit's date nor the current time.
    - A stale clone gives empty windows. Veldra's clone was last fetched on 10-01,
        and Elenchus's on 10-08.
    - A change whose 30-day window ends after that time is **open**. It is listed
        apart, and left out of the rate.

### 8.3 What counts as a come-back

The rules are sealed before the first real run (§8.5). They read commit
subjects, and for issues closing keywords, through a sealed pattern with no
model. *(My call.)* That departs from the intent design's rule that labels come
only from mechanical joins, never from commit or PR text (its §7 and §12). The
pattern's precision is measured on a blind sample (§8.6).

For a first-parent merge commit, the subjects of the commits it merged
(`<merge>^1..<merge>`) are read too, for the revert and fix rules, as slice 0
reads merged commits for the mark. *(My call.)*

1. **A revert.** A later first-parent commit within 30 days whose *subject*
    starts with "revert", in any case. That includes `revert(...)`. It must also
    do one of two things:
    - name C or one of C's commits ("This reverts commit `<sha>`");
    - edit lines C added.

    A body line never makes a commit a revert: only the subject does, and the
    body is read only for the line that names C. felix-home's `a8c7f504`, a
    first-parent squash merge (PR 113), has a body line starting "reverted", and
    it is not a revert.

2. **An edit to an added line.**
    - **The window** runs from C to T, where T is the last first-parent commit
        within 30 days of C and before the as-of time. When no first-parent
        commit follows C in that span, nothing in the window could have edited
        C's lines, and no blame is run. *(My call.)* Veldra's `2623f9a` is one:
        its next first-parent commit came 40 days later.
    - **Finding changed lines.** Run `git blame --reverse C..T --first-parent`
        over the line ranges C added, one blame per file, with all its ranges
        passed together.
    - A line not attributed to T was changed or removed in the window. The
        first-parent commit after the one blame names brought the change onto
        main. After a squash merge or a direct commit, that commit made it. After
        a real merge, the merge's subject and the subjects of the commits it
        merged are read, as above.
    - **Excluded** lines do not count. A line is excluded when its file was later
        deleted or renamed whole, or when its path matches an `exclude` row of the
        project's `retro.tsv`: version files, generated tables, handoff notes. On
        felix-home, most of one large change's "gone" lines were handoff rotation,
        version bumps, a split test file and moved table rows, not come-backs.
    - Excluding a file that is later renamed whole is this design's choice, not
        a limit of git: `git blame --reverse` follows a whole-file rename.
        *(My call.)*
    - **Strong:** the changing commit's subject, or for a merge the subject of a
        commit it merged, matches the project's `fix` row. The default is
        `^(fix|hotfix|revert)`, with an optional scope, in any case.
    - **Weak:** any other edit. It is reported as "edited again", and never
        counted as a come-back.

3. **A reopened issue** (only with `--issues`). An issue that C closed, then
    reopened within 30 days. C closed an issue if its pull request lists it as
    closed, or if a closing keyword in C's message names it. When GitHub is
    unreachable, that kind reads "could not look" for that change, never "not
    reopened".

A change **came back** if it has a revert, a strong fix or a reopened issue.
Weak edits alone are not come-backs. *(My call.)*

- **The table.** `projects/<p>/retro.tsv` has the columns `kind pattern reason`.
    Its kinds are `exclude`, an ERE over paths, and `fix`, an ERE over subjects.
- **Schema.** One `schemas.tsv` row is added. An absent table means no
    exclusions and the default fix pattern.

### 8.4 The replay against slice 1

For each change, the command runs `felix situations --change C^1..C --tsv`. Each
change that came back is then filed in one of three ways:

- **Owed:** slice 1's `--tsv` for that change has at least one class line whose
    verdict is owed (either form) or blinded.
- **No row:** every class line is standing, retired or none. The change is
    filed in the record as a class candidate.
- **Could not look:** no class line is owed or blinded, and at least one is
    could not look.

The join is per change, not per surface. "Owed" means Felix would have said
something about that change, not that the row pointed at what came back. A join
per surface waits until probes record members' paths. Every record carries the
owed ids slice 1 printed, so later slices join on them.

### 8.5 Sealing

Before the first real run, these are committed:

- the rules in §8.3;
- the window;
- the selection rule in §8.2;
- each project's `retro.tsv` rows;
- the filing rule in §8.4;
- the sampling rule and the 0.7 bound in §8.6;
- by hash, the slice-1 seed (`situations.tsv`) and the `probes.tsv` the replay
    reads.

*(My call.)* Their hash goes into every record's header. The replay column uses
only a seed sealed before the come-backs were first counted; a seed sealed after
that first count is not used for the replay. Changing a rule after seeing a
result means a new sealed version and a re-run, and the report says so.

### 8.6 Measures

These numbers are sealed. They are recorded per repository under the memory
root, and published as a PDF report from slice 2's branch.

- **Come-backs per change.** The rate is the changes that came back over the
    changes whose window has closed. The open count and the weak-edit count sit
    beside it.
    - `felix retro` prints the rate with its denominator, its open count and
        `precision: unmeasured`. The engine never reads the sample's labels, so
        the measured precision appears only in the sealed report, once the
        labels exist. *(My call.)*

- **The split.** Come-backs are divided into owed, no row and could not look.
- **The rule's precision,** on a blind-labelled sample.
    - The sample has up to 20 strong come-backs and 10 weak edits per repository.
        They are drawn by a fixed rule sealed in advance.
    - Each label comes from a reader who did not write the rules and sees only
        the two commits. That reader is a person, or a model whose output is marked
        as a sample label. The engine never reads the labels.
    - If the strong rule's precision is under 0.7, the report says the rate is
        not yet usable as a headline.
    - *(The sample size and the 0.7 bound are my calls.)*

### 8.7 Acceptance

These assertions are written blind from this document and shown red on main
first. A fixture repository with scripted history must show the following:

- A squash merge reverted by a commit whose subject starts "Revert" and names
    it is a revert come-back.
- A lowercase `revert(x):` subject that names nothing, but edits the change's
    lines, is a revert.
- A commit with an ordinary subject and a body line starting "Reverting" is not
    a revert.
- A later `fix:` commit editing an added line is strong. A `docs:` commit
    editing one is weak, and not a come-back.
- A real merge whose merged commits include a `fix:` commit that edits an added
    line makes that edit strong.
- A change with no first-parent commit after it inside its window runs no blame
    and has no edits.
- A change that only moves a file adds no lines for that file.
- An added file renamed whole is excluded. So is a version file bumped, through
    `retro.tsv`.
- A change whose window runs past the as-of time is open, and left out of the
    rate.
- `--last 3` on a history whose two newest changes are open selects the three
    newest closed changes, and lists the two open ones apart.
- A history of real merge commits with no PR numbers is read through `C^1`.
- The rate prints with its denominator, its open count and
    `precision: unmeasured`, never alone.
- Two runs with the network off, and without `--issues`, give identical bytes.
- `--issues` with `gh` stubbed as unreachable reads "could not look" for that
    kind, never "not reopened".
- With slice 1's `--tsv` from a harness whose seed holds fixture classes, a
    come-back with an owed or blinded line is filed owed. One with no owed or
    blinded line and at least one could not look line is filed could not look.
    One with neither is filed no row, as a class candidate. Each record carries
    the owed ids slice 1 printed.
- A run with `--window 45` prints as unsealed, and a run with the default
    window does not.

**Real data**, recorded as measurements. Each run gives its denominator and open
count, and states the clone's fetch time:

- felix-home's newest 50 closed changes, 09-23 to 09-26 as of its 10-29 fetch;
- Elenchus's newest 50 closed changes, 08-03 to 09-02 as of its 10-08 fetch;
- Veldra's newest 50 closed changes, 05-01 to 08-29 as of its 10-01 fetch.
    They are merge commits and direct commits, with no PR numbers.

### 8.8 Limits

- Veldra's changes, and 38 of Elenchus's 50 measured changes, carry no PR
    number. For each of them, the issue lookup reads only the issues a closing
    keyword in the change's message names (§8.3), and a change whose message
    names none reads "could not look". *(My call.)*
- For a plain merge, the issue lookup reads the merge commit's own message,
    not the messages of the commits it merged. On 10-29, no commit under
    Veldra's 16 or Elenchus's one such merge named an issue that way, so this
    changes no count yet.
- The clones are stale. Fetching is the operator's step, and it changes the
    as-of time.
- A closed change is at least 30 days old. felix-home's newest 50 closed
    changes fall in four days of late September, so its rate describes that
    week, not this one.
- Lines whose file is later renamed or deleted whole are excluded, so edits to
    them are not counted, and a renamed file counts as excluded churn. That is
    §8.3's choice: felix-home's `f92b8ed7` adds a handoff note that `f1eee4c3`
    later renames to `docs/handoff/0ca.md`, and `git blame --reverse` follows it
    through to T.
- A real merge reads strong when any commit it merged has a fix subject, even
    one that did not touch the edited line.
- The replay joins per change.
- The replay's run time on Elenchus and Veldra is not measured yet. It takes two
    scratch checkouts and a probe run per change.

## 9. Build order

1. **Slice 0.** One engine PR, about one session *[guess]*. It goes first,
    because without it the share is invisible again. It contains:
    - `lib/lane.sh` and `felix lane`;
    - the status row;
    - the session-start paragraph and the screen token;
    - the pulse line;
    - `lanes.tsv` and `lane-next.tsv`, with their schemas rows and felix-home's
        rows;
    - blind parts.

2. **Slice 1.** One engine PR, one to two sessions *[guess]*. It contains:
    - `templates/situations.tsv` with its schemas row;
    - `lib/situations.sh` and `felix situations`, with `--at`, `--change` and
        `--propose`;
    - fixtures (a) to (d) and (f) to (i), and the (e) measurement.

    This PR is "intake lands". It also sets felix-home's share in `lanes.tsv`
    to `1/4`, and moves its row in `lane-next.tsv` on to slice 2, marked
    "pending the direction fold". *(My call.)* That departs from direction §5's
    lane order after intake (item 4, then item 11, then item 3), which the
    founder settles at the direction fold (§12).

3. **Slice 2.** One engine PR, then the sealed report, one to two sessions
    *[guess]*. The PR contains:
    - `lib/retro.sh` and `felix retro`;
    - `retro.tsv`, with its schemas row;
    - fixtures.

    Its come-back half needs nothing from slice 1, so it can be built and tested
    on fixtures while slice 1 waits to land. Its first real run waits until
    slice 1's seed and the `probes.tsv` the replay reads are sealed (§8.5),
    because a seed sealed after the come-backs were first counted is never used
    for the replay.

Both slice 0's and slice 1's PRs edit `felix` (dispatch and `usage()`),
`templates/schemas.tsv`, the version in `engine/.claude-plugin/plugin.json`, the
suite's runner, which sources every part by name (`tests/run`), and the suite's
manifest and red record (`tests/assertions.tsv`, `tests/red.tsv`), as every
engine PR does. Beyond those, they share felix-home's two lane tables, and two
documents: slice 0's branch carries copies of this design and slice 0's plan,
taken from `claude/lane-situations-owed`, so slice 1's rebase meets them. So two
sessions can build them at once. Slice 1 rebases on slice 0 and rewrites its
version, manifest and red record at landing. felix-home's `land.tsv` resolves
`tests/run` as an insertions union.

One finding would change the order:

- If slice 1's fresh Elenchus reading does not find the spend gap ACTIVE
    (§7.9 e), fix the seed or the probes before slice 2's replay.

The approved design also let a finding of misread intent move slice 5's
questions ahead of slice 3. Nothing in slice 2 measures intent, so that trigger
is gone. *(My call.)*

## 10. Left to the builder

- Function names, and the human layout of each report.
- Which other existing helpers to reuse. §4 already requires `need_value` for
    flags, and §7.3 requires `felix_probes_run`, `felix_detect` and
    `felix_tree_id_on` for scratch readings.
    `felix_changed_paths <root> [<base>]` (`lib/resolve.sh:995-1020`) does not
    list one landing's paths: it unions `<base>...HEAD` with the checkout's
    staged and unstaged edits, with `--no-renames`. So it cannot give a
    landing's paths against its first parent, and its `--no-renames` differs
    from slice 2's `git diff -U0 -M` (§8.2).
- The scratch-checkout method, within §7.3's rule that the repository stays
    untouched.
- The exact seed rows, within §7.2's rules, and their sibling fixtures.
- How the suite pins the clock.
- Where the real-data measurements are recorded: slice 0's felix-home count,
    slice 1's (e) and slice 2's three repositories. All sit outside the suite
    (§6.6, §7.9 and §8.7).

## 11. Calls I made, for the founder to check while reading

1. *Slice 0.* The lane's share is counted in engine landings, not in sessions.
2. *Slice 0.* A lane landing is marked by the line `Felix-Lane: <lane>` in the
    body of a commit on its branch that is not a merge. `felix merge` copies
    every non-merge commit message into the landing, and a GitHub squash does so
    only when it keeps GitHub's default message. A hand merge that replaces the
    message drops the mark, and that landing counts as non-lane, so the error
    runs toward `short`.
3. *Slice 0.* A lane landing that changes no engine path does not count,
    following direction §5. Direction §5 also counts a sealed, measured number;
    this slice counts none, wherever it lives, so slice 2's sealed report will
    not count. A stated gap.
4. *Slice 0.* The target and the next item live in two tables. The target, the
    lane's row, changes only when he decides, and the next item with every lane
    PR, so a later guard on the target would need no change to either table.
5. *Slice 0.* The window is 14 days. A short or empty lane (`short`, `zero` or
    `idle`) goes into the next session's context. An empty one (`zero` or
    `idle`) also goes on his screen line. Neither shows on a resumed Claude Code
    session. There is no push alert, because the alert channel has never
    delivered.
6. *Slice 1.* The PR that lands intake also lowers the share to one in four.
7. *Slice 1.* `--propose` stays in, so slice 1 is the intent design's whole §9
    slice, and its landing is "intake lands".
8. *Slice 1.* `--change` reads both sides in scratch checkouts, with the current
    probes, and never writes `facts.log`.
9. *Slice 1.* `--at` runs the detector only when a checkout stands at that tree.
    Anywhere else, the detector's side is undecided.
10. *Slice 1.* When a probe and the detector disagree, the probe decides.
11. *Slice 1.* Elenchus's real-data check takes a fresh reading, because its
    09-24 facts cannot ground `llm`.
12. *Slice 1.* The seed's authorization rides slice 4's admission batch, unless
    he wants to read the seed first.
13. *Slice 2.* Only reverts, fixes and reopened issues count as come-backs.
    Other later edits are "edited again".
14. *Slice 2.* `--last N` takes the newest N changes whose window has closed,
    and lists open ones apart. The rule is sealed with the others.
15. *Slice 2.* The replay joins per change, not per surface.
16. *Slice 2.* A headline come-back rate needs precision of at least 0.7 on the
    blind sample.
17. *Slice 0.* The window is the half-open interval (now − window × 86400 s,
    now], by committer time, and a share's n is at least 1.
18. *Slice 0.* An unreadable lane is written in the status row as state
    `unknown` and value `-`, the form an unreadable status row already uses, so
    the dash shows it as a warning.
19. *Slice 0.* `felix lane` names the commit that last changed the lane's row,
    and reads `lanes.tsv` as committed, never from the working tree.
20. *Slice 0.* The session-start paragraph takes the lane name and the window
    from the table, and says "Trust work takes the other half" only while the
    share is `1/2`.
21. *Slices 0 to 2.* A command dispatched before the libraries load gets its own
    usage assertion, because part 0480 checks only the main dispatch block.
22. *Slice 1.* After slice 1, `lane-next.tsv` names slice 2 "pending the
    direction fold", because putting slice 2 ahead of direction §5's next lane
    items is his to settle (§12).
23. *Slice 1.* A probe term is `probe:<cap>=<state>`, keyed by capability as §9
    wrote it, because predicate names are each project's own.
24. *Slice 1.* A capability with no grounding probe reads true when the detector
    names it, and could-not-look only when neither a probe nor the detector
    decides. Read literally, §9's sentence would contradict its own tests (a)
    and (b).
25. *Slice 1.* Maturity has four values, ordered prototype < internal <
    public-beta < production as v3.2's risk envelope lists them. No project
    declares one yet, so `class_by_maturity` prints with "maturity undeclared",
    and the paid-ingress row carries no `env:` term.
26. *Slice 1.* The seed draws on the survey's proposed candidates and on v3.2
    §10, not on recorded misses as §9 says. Each row's `source` says whether it
    is a recorded miss, a survey candidate or v3.2's text.
27. *Slice 1.* In `--at`, ACTIVE prints as standing, UNKNOWN as could not look,
    and DORMANT is counted. `--tsv` sorts by verdict (owed, blinded, retired,
    standing, could not look, none), then by id.
28. *Slice 1.* How each side was read is in the header only, and (c) asserts at
    least one could-not-look class, unbound predicate or cell with no row.
29. *Slice 1.* A class that needs a capability tag that does not exist reads
    could-not-look when a row names the tag, unless another of its terms is
    false, and shows nowhere otherwise, not as a cell with no row as §9 says.
30. *Slice 1.* (e) names real projects, so it is a recorded measurement outside
    the suite, and (a) to (d) and (f) to (i) are the suite's fixtures.
31. *Slice 1.* Falsifier 5 fires only when no other term is false: a DORMANT
    that rests on another false term is not detector silence.
32. *Slice 1.* Falsifier 2 takes §10's clean-machine form again: two runs from
    two fresh clones with fresh memory roots give identical bytes, every verdict
    included.
33. *Slice 2.* Added lines come from `git diff -U0 -M`, so a file a change only
    moved adds nothing. Lines whose file is later renamed or deleted whole stay
    excluded, by choice.
34. *Slice 2.* For a first-parent merge, the subjects of the commits it merged
    are read too, for the revert and fix rules.
35. *Slice 2.* When no first-parent commit follows a change inside its window,
    no blame runs.
36. *Slice 2.* Come-backs are read from commit subjects and closing keywords by
    a sealed pattern with no model. That departs from the intent design's
    "labels only from mechanical joins"; the pattern's precision is measured on
    a blind sample.
37. *Slice 2.* This slice 2 measures come-backs. The intent design's next slice
    under the name `felix retro` (miss records, gap kinds, a replay at the miss
    tree) stays on file.
38. *Slice 2.* The window is 30 days, not the intent design's 14-day lag window,
    because come-backs take longer to show. It is sealed, and a run with
    another `--window` prints as unsealed.
39. *Slice 2.* The sealed set also holds §8.4's filing rule, the 0.7 bound, and
    by hash the slice-1 seed and probes the replay reads. The replay uses only a
    seed sealed before the come-backs were first counted.
40. *Slice 2.* `felix retro` prints the rate with its denominator, its open
    count and `precision: unmeasured`; only the sealed report carries measured
    precision.
41. *Slice 2.* A finding of misread intent no longer moves slice 5's questions
    ahead of slice 3, because nothing in slice 2 measures intent.
42. *Slice 0.* `felix status` prints the lane row in every project, as `none`
    when the project has no `lanes.tsv`, because the status contract is one
    line per row in a fixed order. `felix lane`, session start and the pulse
    print nothing for such a project.
43. *Slice 2.* A change with no PR number still has the issues that a closing
    keyword in its message names looked up, as §8.3 says. Only a change with
    neither a PR number nor such a keyword reads "could not look".
44. *Slice 0.* The session-start paragraph and the screen token show only in
    the project's own checkout (`lib/own.sh`). Elsewhere they are withheld, and
    the hook's line about withheld work names `lane item`. A security review
    of the first build found the gap: any repository can name a governed
    project in a `.felix` marker, and the paragraph would then point an
    untasked session at a lane item by name, in a tree its authors choose
    (§6.5 items 3 and 4).
45. *Slice 0.* The adversarial review of the first build (findings F1 to
    F10, and F11 from its real-data run) changed four rules. A count that
    cannot finish, because a fork fails in it or a signal ends it, is never
    read as a count or as no lane: the count runs in a process of its own,
    the status row reads `unknown`, the pulse prints one `unknown` line,
    session start says nothing, and `felix lane` prints nothing and exits 1.
    A scratch directory that cannot be made has a reason of its own (R10)
    instead of reading as a home git cannot read. A next text that is
    exactly `none` or `unknown` reads as that word, a limit the plan states.
    A window of one day reads `1 day`. The other findings were defects
    against rules already written, and the build fixes them.
46. *Slice 0.* The second adversarial review found that a project
    resolution that does not finish reads as a directory no project
    governs. The first fixes for it changed the shared resolver, which
    `felix merge` and `felix land` run, and the lane exclusions (§4) forbid
    that. The resolver stays as `main` has it. The lane checks a miss
    itself: it makes every read the miss stands on again, each checked, and
    the miss stands only when they all finished and none binds the
    directory. Otherwise the resolution did not finish: `felix lane` exits
    2 and says so, the status row reads `unknown`, and the pulse prints its
    one `unknown` line. Every other surface, `felix merge` and `felix land`
    included, still reads such a resolution as no project. That is a limit
    of the shared resolver, and the change for it lies outside the lane.
47. *Slice 0.* The third adversarial review found three more places where
    a read that did not finish was taken for an answer, and a shared file
    the lane had changed. The table validator, `lib/table.sh`, is a verifier:
    the gate's schema check runs it, and `felix land`'s deploy check and
    `felix qualify` run that check, so it stays as `main` has it, like the
    resolver. The lane runs the check with its error stream taken: a check
    that left anything there, as bash does when a fork fails inside it, did
    not finish, and the table reads as one that cannot be read, never as
    accepted or refused. The lane now checks a resolution that found a
    project as it checks a miss, since a read that failed under the resolver
    can leave a shorter `remote_match` to bind: the check must finish and
    bind the same project. It reads `remote_match` with no pipe, because the
    shared reader's status is the status of its last command. A `.felix`
    marker that cannot be opened is called unreadable, in the lane's own
    sentence, where the shared one calls it empty. Two limits are stated: a
    signal inside the shared check that leaves no sign, and an open-file
    limit low enough that felix's own load loses its output stream, which
    every subcommand, `felix which` included, loses alike. Other surfaces,
    session start among them, still take the shared resolver's answer as it
    comes.
48. *Slice 0.* The third review's second round found that `felix lane`
    still took its sentence for a miss that stands from `resolve_or_die`,
    which runs a third resolution whose reads the lane never checked.
    Under a fault there it said the wrong thing, and `felix_binding_broken`,
    which it runs, can append to the memory root's `bindings.tsv`, though
    the lane writes nothing. `felix lane` now says a miss from what its own
    check read, in the words `resolve_or_die` uses on `main` for that
    layout, and runs neither. The check takes the origin URL as the
    resolver does, with its trailing LFs dropped. Stated limits: a broken
    Felix home pointer and a remembered binding whose `project.json` was
    renamed, which `felix_binding_broken` reports and the check does not
    read, are said as the layout the check read. A project directory whose
    name ends in LF, which no command substitution can carry, reads as a
    resolution that did not finish.
49. *Slice 0.* The third review's third round found that `felix status`
    gave the lane's own resolution to four of `main`'s rows: reach, gate,
    land and hooks. Wherever the lane's check and the shared resolver
    disagree, as under a fault in a read only the check makes, or for a
    project directory whose name ends in LF, those rows read "not a
    governed checkout" where `main` prints the project's. They take the
    shared resolver's answer again, as `main`'s do, and only the lane row
    reads the lane's resolution. The round also asked what the lane
    exclusions (§4) mean for `felix land`'s deploy check. That check runs
    the session-start hook and the gate on the installed engine as a test
    of it, so every engine change alters what it exercises. The exclusions
    mean the code that decides: what lands, how a project resolves, whether
    a table passes. The lane changes the hook and `templates/schemas.tsv`
    as §6.5 and the tables rule require. What it adds can make neither
    check pass where `main`'s would fail: the lane's text never stands
    alone in the hook's output, and two more schema rows only add checks.

Items 1 to 16 are the calls the approved design listed here, and items 2, 3, 4
and 5 were corrected after the fact-check. Items 17 to 41 are corrections from
the fact-check that change a rule. Items 42 and 43 settle two places where the
corrected text could be read two ways. Items 44 to 49 came from reviews of
slice 0's build: a security review, then three adversarial ones.

## 12. Not decided here, and whose

- **His, before slice 3:**
    - the false-block bound;
    - a yes to a nightly job, if the pulse cannot carry the shadow run.

- **His, before a team pilot:**
    - the v3.2 wording amendment that makes "founder" a role;
    - client consent for anything Felix writes into a client's repository;
    - his reading of the "team concurrency" deferral.

- **His, at the direction fold:** whether slice 2 goes ahead of direction §5's
    next lane items after intake: item 4 (Codex read-only), item 11 (the second
    host) and item 3 (the seeded-omission corpus). Until then, the pointer after
    slice 1 names slice 2 "pending the direction fold" (this design's §9).
- **His, open:**
    - whether Felix ships as software beyond the plugin. My three-layer
        proposal is unconfirmed;
    - how Felix's value shows inside a team. My four-part proposal (§5 item 4)
        is unconfirmed.

- **Folding the 10-29 decisions** into `docs/direction.md` happens in a draft PR
    that waits for his yes.

## Sources

- `docs/2026-10-19-intent-to-build-design.md`: §7 (lines 299-308), §9 (lines
    382-422), §10 (lines 424-435) and §12 (line 474).
- `docs/direction.md`: the noticing row (:98), row 15 (:161), row 17 (:163),
    row 25 (:171), and §5 (:247-283).
- `docs/handoff/pending/20261029T213800Z-claude-lane-situations-owed.md`: the
    founder's 10-29 decisions. His words on visible value (§5 item 4) are in its
    item 7.
- The founder's Founder OS folder, outside the repository:
    `felix_v32_conformance_amendments.md`, §1.1, and
    `felix_v32_architecture_spec.md`, the project risk envelope (:198).
- Code read on 10-29 at `e54e31f3`, with line numbers as read again at
    `01e24cfc` (0.49.313):
    - `lib/probes.sh`, `lib/facts.sh`, `lib/detect.sh` (`:17-37` reads the
        dependency manifests, `:88` keys api, `:97-99` key llm);
    - `lib/escape.sh:60-78`, the tables whose changes wait for a person's
        merge, and why an added `obligations.tsv` row does not (§7.7);
    - `lib/verify.sh:354-372`, `lib/qualify-run.sh:440-462`;
    - `lib/status.sh`, `lib/pulse.sh`, `hooks/session-start`;
    - `felix:2106-2107`, what `felix merge` copies, and `felix:6555-6559`;
    - the dash mod, `~/.claude/mods/dash/hooks/parse.ts` and `register.tsx`.

- PR #455, which the founder merged on GitHub with GitHub's default squash
    message. Its landing carries the message of every non-merge commit on its
    branch (11 of 16), and none of its five merges of main.
- Measured on 10-29:
    - against felix-home's main at `e54e31f3`: no commit on main carries a
        `Felix-Lane:` line, and 18 of the 27 landings in the 14 days before it
        changed `engine/`;
    - at each clone's last fetch: the open and closed counts and merge styles
        in §8.2, the PR numbers in §8.8 and the spans in §8.7.

- A reverse-blame trial on five changes per repository took 0.5 to 2.3 seconds
    per repository. Most of one large change's raw count was churn.
