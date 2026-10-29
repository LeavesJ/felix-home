# The capability lane's first three slices

**The lane counter, what a change owes, and come-backs.** A design to build
from, written 2026-10-29 on branch `claude/lane-situations-owed`.

Nothing here is built until the founder approves this document. After that,
the order is a plan, then one engine build per slice: spec, blind assertions
shown red first, implementation, review, gate.

## 1. Why this, and why now

The capability lane stalled. Direction row 15 gives it about one session in
four, but nothing counted that share. For weeks the audit and the trust-plane
hardening took every session. Because nobody counted the share, it fell to zero
without anyone noticing.

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
    already records, and makes a short or empty lane impossible to miss. This is
    Felix's own discipline, so the stall cannot repeat silently.
- **Slice 1, what a change owes.** This is the *check*. For any change, it lists
    the situation rows the change owes, the rows it blinds, the rows already
    standing, and what Felix could not look at. The change is the unit because a
    team's unit of work is the pull request.
- **Slice 2, come-backs.** This is the *record*: which merged changes came back
    within 30 days, counted mechanically and joined to what slice 1 said each one
    owed. A change comes back when it is reverted, fixed or has its issue
    reopened. Run over a team's last 30 to 50 merged changes, this is what an
    engineering manager would see in Felix's first week.

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
    admit it, as §9 wrote it. Admitting stays the founder's commit, and admission
    by class is slice 4.
- **No new GitHub writes,** and no file in anyone's CI.
- **Not a time-allocation tool for teams.** Slice 0 counts Felix's own lane.
- **Not the outcome record by provider** (lane item 7). Come-back records carry
    no provider or model field.

**Anti-goals.** Any of these makes the work a failure, even if it runs:

- **A project score, level or readiness grade.** That would copy Factory's
    Agent Readiness, and one number hides what was not looked at.
- **Anything a person chats with.**
- **"Could not look" shown as anything else.** It is never printed or counted
    as DORMANT, as absent, or as "owes nothing".
- **A bare come-back rate.** It is always shown with its denominator, its open
    windows and its measured precision.
- **A model on any of these paths.** The precision sample's labels are sample
    labels, and the engine never reads them.
- **Dispatching agents or choosing models.**

## 4. Constraints

- **Kernel.** Felix v3.2 with its conformance amendments governs. These slices
    are report-only, and still no model, key or network sits on their paths.
- **Engine language.**
    - Bash 3.2 and git only: no jq, no python.
    - Only awk that both BWK awk (local) and gawk (CI) run. Part 1497's
        `_awk_names` lints `lib/`.
    - `LC_ALL=C` on every sort, comm, join and uniq (part 0992).
    - `[[ =~ ]]` only inside a function that declares `local LC_ALL=C` (part 0996).
    - Flags go through `need_value` (`felix:388-390`), never a bare `shift 2`.

- **The engine names no project** (constitution invariant 1). The gate's
    independence and ecosystem sections fail on it. Everything project-specific
    lives in a `projects/<p>/` table or arrives as an argument.
- **Offline and deterministic** (invariant 2). Two runs with the network off and
    no key print identical bytes. The only network use in this design is slice
    2's issue lookup. It is off unless asked for, and when GitHub is unreachable it
    reads "could not look".
- **A check that cannot fail is not a check** (invariant 5). Every new check is
    shown failing first.
- **Never delete a home or a memory root** (invariant 6).
- **Where state goes.**
    - Records go under the memory root (`felix_mem_dir`, `lib/resolve.sh:270-273`)
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
    - the `felix merge` and `felix land` code paths.

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
    - Each PR bumps the patch version in the PR and puts it in the title. The
        carrier gives out the next free slot; 0.49.310 to 0.49.313 are claimed.
    - Every new `felix` command appears in `usage()`. Part 0480 asserts it.
    - The suite manners recorded in memory apply:
        - commit everything before the record;
        - red and gate never share a worktree;
        - at most four part runs at once, across the Mac;
        - no whole-suite run while another session's record or gate holds the queue.

## 5. Decided by the founder

1. **The share.** "The lane's share is half until intake lands, then one in
    four."
    - Felix counts the share.
    - When the lane is short, the first open lane item goes to the next session
        that starts without a task from him, and trust work gets the other half.
    - "Intake lands" means the intent design's §9 slice merges on main.
    - (10-29)

2. **Enterprise first, underneath the team.** "we should really stick with the
    engineering ground first, and later use the engineering leverage to
    introduce the departmental liaison." Interaction between managers and
    engineers, and Slack, come "once we ship the MCP later on". (10-29)
3. **The champion.** The first champion is the engineering manager, and the
    target is the whole engineering department. (10-29)
4. **Visible value.** Felix's value has to be visible inside a team: "how we
    reflect inside an engineering team will need careful positioning". How it
    shows is not decided. My proposal, unconfirmed, has four parts: slice 2's
    replay, the pull-request check, a weekly view for the manager and an audit
    trail. (10-29)
5. **§9 and §10 stand.** The intent design's §9 slice, its acceptance tests (a)
    to (e) and its §10 falsifiers stand, re-cut as below. (Design of 10-19)

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
- **A landing counts only if it changed engine code.** At least one path it
    changed must match the lane row's `counts` pattern.
    - Direction §5 counts a lane session only if it lands engine code or
        produces a sealed, measured number. So a docs-only landing from the lane
        does not count.
    - Sealed numbers that live only in the memory root are not counted in this
        slice. *(My call; a stated gap.)*

- **A lane landing** is a counted landing whose message has the whole line
    `Felix-Lane: <lane>`, for example `Felix-Lane: capability`. *(My call.)*
    - A lane session ends at least one commit message on its branch with that
        line.
    - The line survives both ways a change lands. `felix merge` and a squash
        merge on GitHub both copy the branch's commit messages into the landing.
        PR #455, which the founder merged on GitHub, carries every one of its
        branch's commit messages. So a lane PR he merges by hand still counts.
    - For a real merge commit, the commits it merged are read as well.

- **The total** is every counted landing in the window, lane or not, however it
    landed.

The share is counted in landings, not in sessions. *(My call.)* There are two
reasons:

- §5 counts a lane session only when it lands something.
- Nothing durable records which sessions were lane sessions. The machine marker
    is cleared when a session ends (`hooks/session-end:52-56`).

### 6.3 The tables

The target and the pointer to the next item live in two tables, so that one can
be protected without stopping the other.

**`projects/<p>/lanes.tsv`**, the target:

| Column | Meaning |
|---|---|
| `lane` | a name; the lane's mark is `Felix-Lane: <lane>` |
| `counts` | an ERE over changed paths; a landing counts when one matches |
| `share` | the target, as `n/d` |
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
    lane, and nothing is printed.
- **Who changes what.**
    - The PR that lands a lane item moves `next` in the same change. That lands
        on green.
    - The PR that lands intake (slice 1) also changes `share` from `1/2` to
        `1/4`, so "then one in four" happens in the change that makes it true.
    - Whether a change to `lanes.tsv` waits for the founder's merge is his
        decision. §12 records his answer.

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
    - the window and the target;
    - the date of the last lane landing;
    - the mark, and `next`.

    `--tsv` prints the same fields, tab-separated. The carrier can read it when
    it picks work.

2. **`felix status`.** One new row, `lane`, goes after the eight existing rows
    (`lib/status.sh:341-354`). Consumers ignore rows they do not know.
    - The row's value is the state word. Its detail reads "L of T engine
        landings in W days, target n/d".
    - The dash mod posts any change in a row's state or value
        (`~/.claude/mods/dash/hooks/register.tsx:68-72`). So "felix lane: ok →
        short" appears in the dash with no change to the dash. Drawing the row is
        not part of this slice.

3. **Session start, in the session's context.** When the state is `short` or
    `zero`, one paragraph gives the counts and says: "If the founder has not
    given this session a task, take the first open lane item: `<next>`. End a
    commit message on its branch with `Felix-Lane: capability`. Trust work takes
    the other half." *(My call.)*
    - Only the session knows whether it was given a task, so the session that
        reads the paragraph is the one that carries out the rule.
    - A session that takes the item first checks that no live session is
        already on that branch, as sessions do now.

4. **The founder's screen line** (`systemMessage`,
    `hooks/session-start:756-761`). When the state is `zero`, the line gets the
    token `· lane: 0 in 14 days`. A `short` state stays in the session's context
    only. *(My call.)*
5. **The daily pulse.** Each record gets one line,
    `lane<TAB><lane><TAB><state><TAB><L><TAB><T>`, written from `cmd_pulse`
    (`felix:6640-6644`). That puts the share's history on disk in
    `state/pulse.log`.
6. **No push alert.** The alert channel has never delivered: all 32 rows in
    `land/alerts.tsv` are `failed`, and `felix-alert.yml` is not on main. Also,
    `notify.sh` belongs to the landing actor. So the founder sees an empty lane
    on his screen line at every session start, and in the dash.

### 6.6 Acceptance

These assertions are written blind from this document and shown red on main
first.

- **The counts.** A fixture repository holds these landings:
    - a marked engine change landed through `felix merge`;
    - a marked engine change squash-merged the way GitHub does, with the mark
        inside a copied commit message;
    - a marked docs-only change;
    - an unmarked engine change;
    - an unmarked docs-only change;
    - a real merge commit whose merged commits carry the mark;
    - a commit whose message mentions `Felix-Lane: capability` inside a sentence,
        not as a whole line;
    - a landing just outside the window.

    With the clock pinned, L and T must come out exactly as §6.2 defines them,
    at each edge of the window.

- **The state edges.**
    - L·d = n·T reads `ok`, and one lane landing fewer reads `short`.
    - L = 0 with T > 0 reads `zero`.
    - T = 0 reads `idle`.
    - An unreadable ref reads `unknown`, never `ok`.

- **What shows where.**
    - The session-start paragraph appears only for `short` and `zero`.
    - The screen token appears only for `zero`.
    - Neither appears for a project with no `lanes.tsv`.

- **`felix status --tsv`.** It gains exactly one row, at the end. The eight rows
    before it are byte-identical.
- **Determinism.** Two runs print identical bytes.
- **Real data.** On felix-home's main at `e54e31f3`, with the clock pinned to
    that commit's time (2026-10-29 21:26 UTC), the capability lane reads `zero`.
    None of the 27 landings in the window carries the mark, and 18 of them
    changed `engine/`.
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
    - `probe:<predicate>=<state>`: a probe row's reading. The states are found,
        empty, blind, unknown and not-applicable (`lib/probes.sh`).
    - `cap:<name>`: a capability. The name is one `felix_detect` uses (ci,
        deploy, iac, observability, billing, e2e, database, api, llm, rust,
        frontend, tests, secrets; `lib/detect.sh:62-110`), or one a probe's
        `grounds` column grounds.
    - `env:<axis>>=<value>`: only `maturity` can be evaluated in this slice. It
        comes from `project.json` and is ordered prototype < public-beta <
        production; the builder confirms the order against the engine. Any other
        axis is an unbound predicate.

- **`owes`.** What the situation owes, in plain words.
- **`class_by_maturity`.** Comma-separated `maturity=CLASS` pairs that use
    `obligations.tsv`'s class names, for example
    `prototype=INFO,public-beta=ADVISORY,production=TASK_BLOCKING`. It is printed
    only, and nothing reads it for force. *(The format is my call.)*
- **`source`.** A digest of the recorded miss or the cited text, never a
    project name.
- **The seed.** About six rows, drafted against all three ecosystems at once.
    - They are drawn from two sources:
        - the failure modes recorded in the projects' `candidates.tsv`:
            uncontrolled cost, untested route, unbounded storage, undeclared surface,
            false green, supply-chain compromise, signing-key exfiltration and
            privilege escalation;
        - v3.2 §10.

    - The seed must contain:
        1. **Paid ingress.** Public ingress plus a paid outbound call owes a
            request bound and a spend bound. This is §9's example, and it is
            Elenchus's second entrypoint.
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
        tree, a capability that only the detector could decide reads undecided,
        and the residual says the detector could not be run there. *(My call.)*
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

- **`probe:p=s`** is true when p's state is s. It is undecided when p's state is
    blind or unknown, or p has no reading. Otherwise it is false, including when
    p is not-applicable.
- **`cap:c`** is decided by the probes that ground c, and by the detector only
    when no probe does. *(My call.)* In order:
    1. If any probe grounding c reads found, it is true.
    2. Otherwise, if any reads blind or unknown, it is undecided.
    3. Otherwise, if any reads empty, it is false: an empty reading means the
        witness agrees the surface is absent.
    4. Otherwise, when no probe grounds c or every one reads not-applicable, the
        detector decides: true if it names c, undecided if it does not. Detector
        silence is never false.

    The probe outranks the detector because it looks at the surface itself,
    while the detector reads only the dependency list (`lib/detect.sh:17`): a
    project whose dependencies name fastapi is detected as api whether or not it
    serves a route. This keeps §9's rule: "A capability with no grounded probe,
    or one the detector does not name, reads could-not-look."

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

- for some probe term, the pair (state, count) differs between base and head;
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
    - The header gives the project, the base and head commits, their tree ids and
        how each side was read.
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
        owes`.
    - Then residual lines: `residual kind name why`.
    - Sorted with `LC_ALL=C`, with verdicts in the order of §7.5.
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

- the classes that could not look, each with its undecided term and the probe's
    own sentence for why (`lib/probes.sh` prints one);
- unbound predicates: terms that name a probe predicate no probe row defines,
    or an axis with no value;
- cells with no row: capabilities the detector names, or probes ground, that no
    class's `applies` uses;
- how each side was read: recorded or scratch.

The bash harness fixture must print a non-empty residual (§9 (c)).

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

- **(c) Bash harness.** A non-empty residual, never an empty report with exit 0.
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
    - The runs are recorded as measurements. The builder settles how they sit
        beside the suite without a project name tripping the independence check.

- **(f) A route added in the diff** is owed by that change.
- **(g) An unrelated diff** owes no row, and the project's ACTIVE rows still
    print as standing.
- **(h) A diff that breaks the probe's instrument** while the routes stay reads
    blinded at head, never DORMANT or retired. For example, it renames what the
    probe imports. The detector still names api, and the blind probe still
    decides (§7.4).
- **(i) Stable ids.** The same class and project get the same id in `--at`, in
    `--change` and across runs.
- **Falsified if** either of these happens:
    - a stack the detector cannot see reads DORMANT on an HTTP-keyed class with
        no other term false (falsifier 5);
    - a repeat run changes any id or any order (falsifier 2).

### 7.10 Limits the slice states about itself

- Classes that need a capability tag that does not exist, such as plugin hooks
    or peer listeners, read as cells with no row (§9).
- Scratch readings see tracked content only. A probe that imports the
    application reads blind or unknown in a scratch checkout, as Elenchus's
    `http_route` does (§7.3). So on Elenchus, every class that needs api reads
    "could not look" in `--change`, unless another of its terms is false. That
    lasts until scratch trees get an environment.
- A change is seen only through readings. A change on a surface no probe reads
    shows up only in the residual.
- A probe that does not look where a change moved its surface reports the
    surface gone. The defence is a witness that looks wider than its probe
    (`lib/probes.sh`), not this slice.

## 8. Slice 2: come-backs

### 8.1 What it answers

Of the changes that merged, which came back within 30 days, and how? And did
slice 1 say they owed anything? No person and no model does the counting, which
runs over the repository's own history. Over a team's last 30 to 50 merged
changes, this is the engineering manager's first-week view. It runs first on
the founder's three repositories.

### 8.2 Which changes, and as of when

- **The command.**
    `felix retro [<repo-path>] [--last N | --since <date>] [--window 30] [--issues] [--tsv]`.
    *(The command's shape is my call. §9 named it `felix retro`.)*
    - It is read-only on the repository: it never fetches, and it never touches
        the checkout. It makes scratch checkouts only for slice 1's readings, as
        §7.3 does.
    - The repository must belong to a bound project, because slice 1 needs that
        project's probes.

- **The changes.** The command walks first-parent commits on the main ref,
    newest first. *(The selection rule is my call, and it is sealed, §8.5.)*
    - `--last N`, 50 by default, takes the newest N changes whose window has
        closed. `--since <date>` takes every closed change from that date on.
        Changes whose window is still open are listed apart, and never counted.
    - Taking the newest N, open or not, would give felix-home no rate at all.
        As of each clone's last fetch, all of felix-home's newest 50 changes are
        open. Elenchus has 7 open and 43 closed, and Veldra 24 open and 26
        closed.
    - Each change C has its base at `C^1`. That works for squash merges (felix-home
        and Elenchus) and for real merge commits (Veldra).
    - Its added lines come from `git diff -U0 --no-renames C^1 C`.

- **As of when.** Results are as of the time the main ref was last fetched. That
    is neither the last commit's date nor the current time.
    - A stale clone gives empty windows. Veldra's clone was last fetched on 10-01,
        and Elenchus's on 10-08.
    - A change whose 30-day window ends after that time is **open**. It is listed
        apart, and left out of the rate.

### 8.3 What counts as a come-back

The rules are sealed before the first real run (§8.5).

1. **A revert.** A later first-parent commit within 30 days whose *subject*
    starts with "revert", in any case. That includes `revert(...)`. It must also
    do one of two things:
    - name C or one of C's commits ("This reverts commit `<sha>`");
    - edit lines C added.

    Body lines never count. Veldra's `a675b50` has a body line starting
    "Reverting", and it is not a revert.

2. **An edit to an added line.**
    - **The window** runs from C to T, where T is the last first-parent commit
        within 30 days of C and before the as-of time.
    - **Finding changed lines.** Run `git blame --reverse C..T --first-parent`
        over the line ranges C added, one blame per file, with all its ranges
        passed together.
    - A line not attributed to T was changed or removed in the window. The
        first-parent commit after the one blame names is the commit that changed
        it.
    - **Excluded** lines do not count. A line is excluded when its file was later
        deleted or renamed whole, or when its path matches an `exclude` row of the
        project's `retro.tsv`: version files, generated tables, handoff notes. On
        felix-home, most of one large change's "gone" lines were handoff rotation,
        version bumps, a split test file and moved table rows, not come-backs.
    - **Strong:** the changing commit's subject matches the project's `fix` row.
        The default is `^(fix|hotfix|revert)`, with an optional scope, in any
        case.
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

- **Owed:** slice 1 owed or blinded at least one row at that change.
- **No row:** slice 1 owed nothing, and there was nothing it could not look at.
    The change is filed in the record as a class candidate.
- **Could not look:** slice 1 owed nothing, but had classes it could not look at.

The join is per change, not per surface. "Owed" means Felix would have said
something about that change, not that the row pointed at what came back. A join
per surface waits until probes record members' paths. Every record carries the
owed ids slice 1 printed, so later slices join on them.

### 8.5 Sealing

Before the first real run, five things are committed:

- the rules in §8.3;
- the window;
- the selection rule in §8.2;
- each project's `retro.tsv` rows;
- the sampling rule in §8.6.

Their hash goes into every record's header. Changing a rule after seeing a
result means a new sealed version and a re-run, and the report says so.

### 8.6 Measures

These numbers are sealed. They are recorded per repository under the memory
root, and published as a PDF report from the lane branch.

- **Come-backs per change.** The rate is the changes that came back over the
    changes whose window has closed. The open count and the weak-edit count sit
    beside it.
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
- An added file renamed whole is excluded. So is a version file bumped, through
    `retro.tsv`.
- A change whose window runs past the as-of time is open, and left out of the
    rate.
- `--last 3` on a history whose two newest changes are open selects the three
    newest closed changes, and lists the two open ones apart.
- A history of real merge commits with no PR numbers is read through `C^1`.
- Two runs with the network off, and without `--issues`, give identical bytes.
- `--issues` with `gh` stubbed as unreachable reads "could not look" for that
    kind, never "not reopened".

**Real data**, recorded as measurements. Each run gives its denominator and open
count, and states the clone's fetch time:

- felix-home's newest 50 closed changes, 09-23 to 09-26 as of its 10-29 fetch;
- Elenchus's newest 50 closed changes, 08-02 to 09-02 as of its 10-08 fetch;
- Veldra's newest 50 closed changes, 05-01 to 08-29 as of its 10-01 fetch.
    They are merge commits and direct commits, with no PR numbers.

### 8.8 Limits

- Veldra's changes carry no PR numbers, so its issue lookup reads "could not
    look".
- The clones are stale. Fetching is the operator's step, and it changes the
    as-of time.
- A closed change is at least 30 days old. felix-home's newest 50 closed
    changes fall in four days of late September, so its rate describes that
    week, not this one.
- Line edits are not followed across renames. A renamed file counts as excluded
    churn.
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
    - fixtures (a) to (i).

    This PR is "intake lands". It also sets felix-home's share in `lanes.tsv`
    to `1/4`, and moves its row in `lane-next.tsv` on to slice 2.

3. **Slice 2.** One engine PR, then the sealed report, one to two sessions
    *[guess]*. The PR contains:
    - `lib/retro.sh` and `felix retro`;
    - `retro.tsv`, with its schemas row;
    - fixtures.

    Its come-back half needs nothing from slice 1. It can be built and measured
    while slice 1 waits to land. The replay column follows slice 1.

Slices 0 and 1 share only felix-home's two lane rows. So two sessions can build
them at once, with slice 1 rebased on slice 0.

Two findings would change the order:

- If slice 1's fresh Elenchus reading does not find the spend gap ACTIVE
    (§7.9 e), fix the seed or the probes before slice 2's replay.
- If slice 2 finds that most come-backs trace to misread intent rather than an
    engineering class, slice 5's questions move ahead of slice 3.

## 10. Left to the builder

- Function names, and the human layout of each report.
- Which existing helpers to reuse: `felix_changed_paths`, `felix_tree_id_on`,
    `felix_probes_run`, `felix_detect`, `need_value`.
- The scratch-checkout method, within §7.3's rule that the repository stays
    untouched.
- The exact seed rows, within §7.2's rules, and their sibling fixtures.
- How the suite pins the clock.
- Whether `felix lane` and `felix retro` dispatch before the libraries load, as
    the read-only `audit`, `inventory` and `cost` commands do (`felix:249-272`).
- Where the real-data runs sit relative to the suite: slice 1's (e) and slice
    2's three repositories.

## 11. Calls I made, for the founder to check while reading

1. *Slice 0.* The lane's share is counted in engine landings, not in sessions.
2. *Slice 0.* A lane landing is marked by the line `Felix-Lane: <lane>` in its
    commit message. Both `felix merge` and a GitHub squash copy it into the
    landing, so a lane PR he merges by hand still counts.
3. *Slice 0.* A lane landing that changes no engine path does not count,
    following §5. Sealed numbers that never land on main are not counted yet.
4. *Slice 0.* The share and the next item live in two tables, so the share can
    be protected without stopping the PRs that move the next item.
5. *Slice 0.* The window is 14 days. A short lane goes into the next session's
    context. An empty one also goes on his screen line. There is no push alert,
    because the alert channel has never delivered.
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

## 12. Not decided here, and whose

- **His, now:** whether a change to the lane's share waits for his merge
    (§6.3). Asked on 10-29; his answer goes here.

- **His, before slice 3:**
    - the false-block bound;
    - a yes to a nightly job, if the pulse cannot carry the shadow run.

- **His, before a team pilot:**
    - the v3.2 wording amendment that makes "founder" a role;
    - client consent for anything Felix writes into a client's repository;
    - his reading of the "team concurrency" deferral.

- **His, open:** whether Felix ships as software beyond the plugin. My
    three-layer proposal is unconfirmed.
- **Folding the 10-29 decisions** into `docs/direction.md` happens in a draft PR
    that waits for his yes.

## Sources

- `docs/2026-10-19-intent-to-build-design.md`, §9 (lines 382-422) and §10.
- `docs/direction.md`: row 15 (:161), row 17, and §5 (:247-283).
- `docs/handoff/pending/20261029T213800Z-claude-lane-situations-owed.md`: the
    founder's 10-29 decisions.
- `Founder OS/felix_v32_conformance_amendments.md`, §1.1.
- Code read on 10-29:
    - `lib/probes.sh`, `lib/facts.sh`, `lib/detect.sh` (`:17` keys api,
        `:27-28` key llm);
    - `lib/escape.sh:78`, the tables whose changes wait for a person's merge;
    - `lib/verify.sh:354-372`, `lib/qualify-run.sh:440-462`;
    - `lib/status.sh`, `lib/pulse.sh`, `hooks/session-start`;
    - `felix:6640-6644`.

- PR #455, which the founder merged on GitHub. Its landing carries every
    commit message from its branch.
- Measured on 10-29:
    - against felix-home's main at `e54e31f3`: no commit on main carries a
        `Felix-Lane:` line, and 18 of the 27 landings in the 14 days before it
        changed `engine/`;
    - at each clone's last fetch: the open and closed counts in §8.2 and the
        spans in §8.7.

- A reverse-blame trial on five changes per repository took 0.5 to 2.3 seconds
    per repository. Most of one large change's raw count was churn.
