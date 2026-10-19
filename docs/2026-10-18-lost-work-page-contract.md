# The lost-work page, `felix monitor`, and three inventory fixes (Phase 0b step 6)

*Written 2026-10-18 in session "Spec the lost-work page and fix inventory false
rows" against `claude/stuck-pr-page` at `6627e2ba` (step 5, built, not landed),
which sits on felix-home `origin/main` `e95e5d3b`; `origin/main` has since moved
to `248d9c7e` (#443, 0.49.294). Inputs: roadmap Phase 0b step 6, the inventory
spec (`audits/2026-10-01-report-v5-review/specs/inventory/spec.md` under the
memory root, here "the inventory spec"), the stuck-PR spec v2 beside it ("the
step 5 spec"), and measurements of `felix inventory` on felix-home taken for
this contract (§10).*

**This document is the whole contract for assertions.** An assertion author
needs nothing else, apart from the existing suite's fixtures and stubs, which
may be reused. §9 is for the implementer only.

Part A changes `felix inventory`. Part B adds the page. They land as one engine
PR because the page would otherwise open with dozens of false rows.

---

# Part A: three inventory fixes

Every clause of the inventory spec stands except where this part changes it.
Section numbers in this part (§4.1, §6.6 and so on) are the inventory spec's.

## A1. `carried`: work another pushed branch already holds

**Defect.** On 2026-10-18, 10 rows `felix inventory` called `unproposed`, and
17 rows it left undecided with content `not` (states `-`), were commits that a
pushed branch or an open PR's head already holds. A carry branch or a stacked PR
made each look like lost work twice: once for itself, once for every branch it
holds.

**The state.** `carried` is a new held state. In §4.1's fixed order it comes
right after `pr-closed-unlanded` and before `orphan`:

```
hazard:shared-branch hazard:staged-revert live question blocked uncommitted
unpushed unproposed pr-open pr-closed-unlanded carried orphan chip-unstarted handoff-pending
```

**Carriers.** The carriers of a repository are its remote-tracking refs
`refs/remotes/origin/<name>`, except `origin/HEAD` and the default branch
(§3). Nothing else carries: not a local branch (unpushed work can still be
lost), not a tag, not another remote's refs.

**When it holds.** A `worktree`, `branch` or `remote` row holds `carried` when
all of these hold:

1. its tip's own content (§4.3, the tip alone, never counting uncommitted
   changes) is not `landed`;
2. it holds no `pr-open`;
3. some carrier reaches its tip, where "reaches" means:
    - for a `branch` or `worktree` row: the carrier's tip equals the item's tip
      or descends from it, and the carrier is not the item's own name on origin
      (§3 Proposes: its own name, or its upstream's short name); but when the
      item's own name or its upstream stands at its tip on origin, the work is
      already pushed under its own name, and only a strict descendant carries
      it, as for a `remote` row (review round, finding 2);
    - for a `remote` row: the carrier's tip strictly descends from the item's
      tip (equal tips do not count), and the carrier is not the item itself.

    A worktree on a detached HEAD has no own name; its tip is `HEAD`.

Two remote refs at one commit therefore carry neither each other: each stays
`unproposed`, and §4.7 marks them `possible-duplicate`. The same holds for two
pushed names at one commit that each have a local branch or worktree: the
local rows are strict too (above), so neither is carried by the other's name.
A strict ancestry relation has no cycles, so some row always remains to say the
work needs a PR.

**What it replaces.** When `carried` holds, the row holds neither `unproposed`
nor `pr-closed-unlanded`, nor their `unknown:` entries. A closed PR's number may
stay in the detail as prose. `carried` never removes `uncommitted`, `live`,
`question`, `blocked` or a hazard; a worktree with uncommitted changes on a
carried tip is `uncommitted,carried`. `unpushed` cannot hold beside it: a tip a
carrier reaches has its commits on a remote-tracking ref.

**Kinds.** §4.2 gains `carried` for `branch` and `remote`; `worktree` already
takes every state from `hazard:shared-branch` to `orphan`, which now includes
it. §4.7 is unchanged: `carried` is not one of the states that make a
`possible-duplicate`.

**`--no-gh`.** `carried` is decided by git alone, so it holds under `--no-gh`
too. Condition 2 then reads `pr-open` as not held, and the row keeps
`unknown:pr-open` as §5.1 says.

**Detail.** The row's detail gains one element:

```
carried by <c>[, <c>]...[, and <k> more]
```

- Only the outermost carriers are named: a carrier is left out when another
  carrier of the same row has a tip that strictly descends from its tip.
- A carrier `origin/<b>` is written `#<n>` when gh listed an open
  same-repository PR whose head ref name is `<b>` (the newest, by number, if
  several). Otherwise it is written `origin/<b>`. Under `--no-gh`, every carrier
  is written `origin/<b>`.
- Order: the `#<n>` carriers by ascending number, then the `origin/<b>` carriers
  by name, compared bytewise. At most three are named; the rest are counted in
  `, and <k> more`.

Example: a branch holding commits of `origin/claude/batch-18-carry` reads
`carried by origin/claude/batch-18-carry`, and a worktree whose detached HEAD
is inside #444's head reads `carried by #444`.

## A2. Chips proposed through `start_session`

**Defect.** `felix_inv_host_chips` reads a proposal only from a `tool_use`
named `mcp__ccd_session__spawn_task`. The desktop app now proposes the same
card through `mcp__ccd_session__start_session` with `initiation` set to
`own_initiative`. Measured 2026-10-18: four such proposals in the records, none
read. Every new chip is invisible.

**Proposed** (§6.6) now reads two kinds of assistant `tool_use` item:

| tool_use `"name"` | is a proposal when | title, prompt |
|---|---|---|
| `mcp__ccd_session__spawn_task` | always | `input.title`, `input.prompt` |
| `mcp__ccd_session__start_session` | its `input` holds `"initiation":"own_initiative"`, at any position among the input's keys | `input.title`, `input.prompt` |

- A `start_session` call with any other `initiation` (`user_asked`, `offer`), or
  with none, is not a proposal. A call carrying `proposal_id` is not a
  proposal either; it may start one (A3).
- Several `tool_use` items in one assistant record are read one by one; each
  is a proposal or not on its own input.
- A proposal is recognised whatever else its record holds: neither its title
  nor its prompt need contain any particular word.

**The task id** is unchanged in form: the `task_[0-9a-f]+` that follows the
first `task_id: ` in the `tool_result` for that `tool_use` id. A
`start_session` result goes on to name other cards still waiting
(`Also still waiting: task_7d7cee05 "..."`); those ids follow no `task_id: `
and make no chip.

**A result that made no card.** When the `tool_result` for a proposal's
`tool_use` id is present and holds no `task_id: task_`, no card was made (for
example `Permission to use mcp__ccd_session__spawn_task has been denied.`). That
`tool_use` makes no row. When no `tool_result` for it is in the file at all,
whether a card exists is unknown: the row's ref is the `tool_use` id, its
states are `unknown:chip-unstarted`, and its detail is the title followed by
the element `no result recorded for the proposal`.

**Withdrawn** is unchanged: `mcp__ccd_session__dismiss_task` naming the task id
in the same session file removes the chip, whichever tool proposed it.

**An expired card.** The desktop app says a `start_session` card expires seven
days after it was proposed. A chip proposed through `start_session` whose age
is 168 hours or more gains the detail element `card expired`. A chip proposed
through `spawn_task` never does; no expiry was observed for those.

## A3. What "started" really is

**Defect.** 35 of the 62 `chip-unstarted` rows on felix-home on 2026-10-18 were
chips a session had started and finished, several landed (#418, #439, #440,
#441; the carrier table names the sessions). Two causes, both measured:

1. **A reminder item ending in blank lines.** A worktree session's first user
   record is written as two text items: the first holds only the worktree
   `<system-reminder>` block followed by `\n\n`, the second holds the prompt:

    ```
    "content":[{"type":"text","text":"<system-reminder>\nYou are operating in a git worktree.\n...\n</system-reminder>\n\n"},{"type":"text","text":"In felix-home (LeavesJ/felix-home), the Stop hook ..."}]
    ```

    The reader looked for the next text item before it set aside the blank
    lines after `</system-reminder>`, found a quote, and passed the record
    over. The session's "first human text" became a later one, usually a
    continued-session summary, and no prompt matched. All 35 rows had this
    shape.
2. **A framed prompt.** A session started from a `start_session` card with a
   fresh context receives the prompt framed:

    ```
    Background (from the session that started this one):
    <background>

    Task:
    <prompt>

    Shared notes folder for this group of sessions ...
    ```

    Its first 120 characters are the framing, never the prompt.

Five more rows were the denied proposals A2 now drops.

**Human text** (§6.2) is restated for the reminder blocks: after leading blanks
and any number of leading `<system-reminder>...</system-reminder>` blocks are
set aside, **with the blanks that follow each block**, a text item that holds
nothing more ends there, and the human text is the next text item of the same
record, read the same way. This applies wherever human text is used: the
`question` rule's "no human text follows" and the chip rules alike.

**Started** (§6.6) is replaced. A chip is started when any of these holds:

- **S1, its prompt.** Some session file under the records root, modified after
  the proposal and not the file that proposed it, has a first human text whose
  start, read as below, begins with the chip prompt's first 120 decoded
  characters (all of the prompt when it is shorter). The start is read after
  setting aside leading `<system-reminder>` blocks as above. When that text
  begins with `Background (from the session that started this one):`, the
  start is instead read from just after the first `Task:` line that follows a
  blank line; with no such line, the text is read from its beginning.
- **S2, its title.** Some session file under the records root, modified after
  the proposal and not the file that proposed it, holds a record of type
  `custom-title` whose decoded `customTitle` equals the chip's decoded title
  exactly, byte for byte, uncut. Any such record in the file counts, not only
  the last.
- **S3, its start call.** Some session file under the records root, modified
  after the proposal, holds an assistant `tool_use` of
  `mcp__ccd_session__start_session` whose input holds
  `"proposal_id":"<the chip's task id>"`, and a `tool_result` for that
  `tool_use` id is present.

"Decoded" is as §6.6 reads the prompt today: JSON escapes read, line breaks and
tabs as spaces. The unread-file rule (§5.2, §6.6 Unread files) is unchanged and
still applies after S1 to S3: a chip none of them starts, proposed before the
mtime of a session file the run could not read, is `unknown:chip-unstarted`.

**Classes** (§5.2). S1 and S2 are INFERRED (a matching prompt or title), S3 is
OBSERVED. `chip-unstarted` stays OBSERVED in the table: it is the absence of all
three.

## A4. A pending listing that failed is in the states (review round)

The inventory spec §5.2 says a failed listing of `docs/handoff/pending/` in
the `default` cover row's detail (`handoff sections not read`). The page reads
no detail, so the row now also carries `unknown:handoff-pending` in its states,
after its first word, which stays `read` (or `unknown`). Added by the review
round's fix for its finding 1, which B4's `handoff` row relies on.

---

# Part B: the lost-work page

## B0. Scope

Roadmap Phase 0b step 6: `felix monitor` rebuilt as a read-only view over
`felix inventory` and step 5's pull request states. What needs the founder
comes first: hazards, blocked sessions, open questions, work that never reached
a PR, and PRs by landing state. Running and landed work is collapsed. **Nothing
on it acts**, and consent stays the founder's GitHub merge. An unread source is
said, and a count it decided reads `unknown`, never `0`.

The page derives no fact of its own. Every row it shows is a row one of its two
sources printed, and the only thing the page adds is which group the row is in
and how many rows each group holds.

## B1. Command line

```
felix monitor [--tsv] [--repo DIR]... [--no-gh] [--no-host] [--days N] [--live MIN] [--blocked MIN]
felix monitor --log [--open] [--watch] [--every N]
felix monitor -h | --help
```

- **The page** is `felix monitor` without `--log`. `--repo`, `--no-gh`,
  `--no-host`, `--days`, `--live` and `--blocked` mean what they mean to
  `felix inventory` (inventory spec §2). The page checks the numeric ones as
  the inventory does (whole numbers of one to six digits) and hands every one
  to it unchanged. With no `--repo`, the page reads the repository holding the
  current directory.
- **The log page** is `felix monitor --log`: the HTML page `felix monitor`
  rendered before this change, rendered by the same code to the same file
  (`state/monitor.html` under the home), with the same output. `--open`,
  `--watch` and `--every N` belong to it and each implies `--log`, so
  `felix monitor --open` keeps opening it.
- **Usage errors** (exit 2, a one-line reason and the usage on stderr, nothing
  on stdout): an argument not listed above; a page option (`--tsv`, `--repo`,
  `--no-gh`, `--no-host`, `--days`, `--live`, `--blocked`) together with a log
  option (`--log`, `--open`, `--watch`, `--every`); a value the inventory would
  refuse; an option missing its value. The usage names `--log`.
- **Help.** `-h` or `--help` prints the usage to stdout and exits 0. The line
  for `monitor` in `felix help` names the page and `--log`.

## B2. Sources, and the read-only contract

| Source | Run as |
|---|---|
| the inventory | `felix inventory --tsv --repo DIR` with the page's other inventory options |
| the PR states | `felix land --prs --tsv --repo DIR`, with `--no-gh` when the page was given it |

Each repository is read by both, one `--repo` at a time, in the order given.
Both are run as child processes of the same `felix` entry point the page runs
from, with the page's environment.

**Read-only.** The page itself writes nothing outside one scratch directory of
its own, made with `mktemp -d` outside every repository and removed on exit and
on HUP, INT, QUIT and TERM. It inherits both sources' read-only contracts and
adds no write: a run of `felix monitor` without `--log` leaves every repository
it reads byte-identical (refs, index, config, `HEAD`, object store), leaves the
memory root and the home unchanged, and writes no `state/monitor.html`. Only
`--log` writes that file, as before. gh is asked only what the sources ask
(`pr list`, and `api` GETs), and launchctl only `print`.

**Nothing on it acts.** It prints no command to run and asks nothing. It posts
nothing, labels nothing, merges nothing, starts no session.

## B3. Groups

Every row of either source belongs to exactly one group.

**Source rows.** The inventory's `cover` rows and land's `source` rows are in
group `cover`.

**Land's `pr` rows** go by their owner column, which is step 5's "needs" value:

| owner | group |
|---|---|
| `founder` | `pr-founder` |
| `session` | `pr-session` |
| `lander` | `pr-lander` |
| `unknown` | `pr-unknown` |
| `nobody` | `pr-nobody` |

**The inventory's other rows** take the first group in this table whose
condition holds:

| # | group | the row |
|---|---|---|
| 1 | `hazard` | holds `hazard:shared-branch` or `hazard:staged-revert` |
| 2 | `blocked` | holds `blocked` |
| 3 | `question` | holds `question` |
| 4 | `running` | holds `live` |
| 5 | `never-proposed` | holds `uncommitted`, `unpushed`, `unproposed`, `pr-closed-unlanded` or `chip-unstarted`; or holds `orphan` and its content is not `landed` |
| 6 | `proposed` | holds `pr-open` |
| 7 | `carried` | holds `carried` |
| 8 | `handoff` | holds `handoff-pending` |
| 9 | `undecided` | carries an `unknown:` entry other than `unknown:live`, or its content is `not` or `partly` |
| 10 | `landed` | holds `landed` |
| 11 | `quiet` | anything else |

"Holds" means the state appears in the states column as itself, not as
`unknown:<state>`.

Why this order: hazards and blocked sessions can lose work today; a question
waits on a person; a live session is doing its work and needs nobody; what
never reached a PR is the lost work; the inventory's open-PR rows are the same
pull requests land lists with their states, so they are collapsed here, and the
PR groups list them once. A live session with a question or a blocked call is
listed, not collapsed.

**Listed and collapsed.** These groups are listed, each row on its own line, in
this order: `hazard`, `blocked`, `question`, `never-proposed`, `pr-founder`,
`pr-session`, `pr-lander`, `pr-unknown`, `undecided`. These are collapsed to a
count: `running`, `pr-nobody`, `proposed`, `carried`, `handoff`, `landed`,
`quiet`.

## B4. Unknown is said, never 0

Each group except `cover` has a count and a completeness, `complete` or
`incomplete`. A group is `incomplete` when a condition in this table holds:

| group | incomplete when |
|---|---|
| `hazard` | some row carries `unknown:hazard:shared-branch` or `unknown:hazard:staged-revert` |
| `blocked` | the inventory's `sessions` cover row is not `read`, or some row carries `unknown:blocked` |
| `question` | the `sessions` cover row is not `read`, or some row carries `unknown:question` |
| `running` | the `sessions` cover row is not `read`, or some row carries `unknown:live` |
| `never-proposed` | the `default`, `prs` or `chips` cover row is not `read`, or some row carries `unknown:` of `uncommitted`, `unpushed`, `unproposed`, `pr-closed-unlanded`, `orphan` or `chip-unstarted` |
| `pr-founder`, `pr-session`, `pr-lander` | land's `gh` source row is not `read` or `none`, or land printed no `gh` source row, or some `pr` row is in group `pr-unknown` |
| `pr-unknown`, `pr-nobody` | land's `gh` source row is not `read` or `none`, or land printed no `gh` source row |
| `proposed` | the inventory's `prs` cover row is not `read`, or some row carries `unknown:pr-open` |
| `handoff` | the inventory's `default` cover row carries `unknown:handoff-pending` in its states (the listing of the pending directory failed) |
| `carried`, `undecided`, `landed`, `quiet` | never |

A `pr` row in `pr-unknown` makes the three groups above it incomplete because
step 5 decides `unknown` before `founder`, `needs-attended`, `refused` and
`ready`: the PR could have been any of them.

**The count as said.** A complete group says its number. An incomplete group
with rows says `at least <n>`. An incomplete group with no rows says `unknown`.
So no group whose source was unread ever says `0`.

**Why it is incomplete.** Each reason is one element, joined by `; `:

- a cover row that is not `read`: `<ref> <first word of its states>: <its detail>`
  (for example `sessions unknown: --no-host`);
- land's `gh` row that is not `read` or `none`: `gh <its states>: <its detail>`;
- no `gh` row from land: `felix land --prs exited <status>` followed by `: <its
  first stderr line>` when it wrote one;
- rows carrying an `unknown:` entry the table names: `<k> rows not decided`;
- PRs in `pr-unknown`, for the three groups above it: `<k> pull requests not
  decided`.

## B5. Output: `--tsv`

Nine tab-separated columns, no header:

```
group  kind  repo  ref  states  owner  age_h  content  detail
```

**Source rows.** For each row a source printed, `group` is its group (B3) and
the other eight columns are the source row's own eight, in its order, after the
terminal filter (B7). So, apart from the filter, cutting the first column off
the page's non-summary rows gives back exactly the rows `felix inventory --tsv`
and `felix land --prs --tsv` print when run alone with the same options:
nothing dropped, nothing added, nothing printed twice.

**Summary rows.** One per group other than `cover`, per repository:

| column | value |
|---|---|
| group | the group |
| kind | `summary` |
| repo | the inventory's repo cell for the repository (its main worktree path) |
| ref | the group |
| states | `complete` or `incomplete` |
| owner, age_h | `-` |
| content | the number of rows in the group, or `unknown` when it is incomplete with none |
| detail | `-` when complete, else the reasons (B4) |

**Order.** Repositories in the order given. For each: its 16 summary rows
in the group order `hazard blocked question never-proposed pr-founder
pr-session pr-lander pr-unknown undecided running pr-nobody proposed carried
handoff landed quiet`; then the `cover` rows, the inventory's then land's, each
in its source's order; then the other rows by group in the same group order,
the inventory's rows in its order and land's `pr` rows by ascending number.

The `repo` cell of a source row is its source's own: the inventory gives the
main worktree path, land the `owner/name` slug. A tab, carriage return or line
break in any cell becomes a space.

## B6. Output: the text page

```
felix monitor: read-only. It wrote nothing, fetched nothing and acted on nothing; it read felix inventory and felix land --prs.
<repository path>
  read <ref> <states>: <detail>
  ...
  needs you
    hazards: <count>[ (<reasons>)]
      <row line>
    blocked sessions: ...
    open questions: ...
    work that never reached a PR: ...
    pull requests waiting on the founder: ...
    pull requests waiting on a session: ...
    pull requests ready for the lander: ...
    pull requests not decided: ...
    rows not decided: ...
  collapsed: running <count>, pull requests waiting on nobody <count>, proposed <count>, carried <count>, handoff sections <count>, landed <count>, quiet <count>
```

- The first line is printed once. Then one block per repository, headed by its
  path, then one `read` line per cover row, the inventory's then land's.
- **`needs you`** prints every listed group's heading, in the B3 order, even
  when it holds no row, so a reader sees each was checked. `<count>` is said as
  B4 says. `(<reasons>)` follows an incomplete group.
- **Row lines** sit under their group's heading, in the B5 order:
    - an inventory row: `<ref> <states>[, <age_h>h][, session <owner, first 8 characters>]: <detail>`, with the age left out when it is `-` and the session left out when the owner is `-` or `unknown`;
    - a land `pr` row: `<ref> <states>[, <age_h>h]: <detail>`.
- **Collapsed** groups are not listed: no row line of theirs is printed, and
  their counts, said as B4 says, are on the `collapsed:` line, last in the
  block.
- With no repository read at all, the page prints the first line only.

## B7. The terminal filter

On both pages, every byte below 0x20 except tab and line feed, the byte 0x7f,
and every byte 0x80 to 0x9f that follows 0xc2 (the UTF-8 C1 controls) becomes
`?`, in every cell and every line the page prints from either source. This is
step 5's R8, applied to the inventory's rows as well: chip titles and question
text come from transcripts.

## B8. Exit status

- 0: every named repository was read, including when sources inside it were
  unread.
- 1: a named repository could not be read: the inventory exited 1 for it, or
  the page's own awk, which groups and counts its rows, exited non-zero. Its
  line goes to stderr, and every other repository is still printed. For the
  awk the line is `felix monitor: <the directory as given>: the page could not
  be made from its rows (awk exited <status>)`, and nothing of that
  repository reaches stdout: no block on the text page and no row in `--tsv`,
  not even the part the awk printed before it stopped.
- 2: usage.

The log page's exit status is unchanged.

*Amended 2026-10-19.* On the Linux CI runner, whose awk is gawk, the page's awk
stopped at its first land row on an array named `RT`, a gawk builtin scalar.
The page exited 0 with nothing on stdout: a silent 0, which B4 forbids. The
array is `RTAG` since 8d181f37; this clause makes any later failure of the
same kind exit 1 and say which repository it was, and B12 adds the lint that
would have caught the name.

## B9. What the assertions must cover

The suite stubs gh for the inventory and gh and launchctl for step 5; host
records are fixture files under a fixture `CLAUDE_CONFIG_DIR` or `HOME`. Each
case names what it pins.

**Part A, `carried`.**

1. A branch whose tip is a proper ancestor of a pushed branch `origin/carry`
   (no PR anywhere), content not landed: states `carried` and no `unproposed`;
   detail `carried by origin/carry`. The carrier's own row (a local branch
   `carry` covering it, or the remote row `origin/carry`) stays `unproposed`.
2. The same with an open same-repository PR #7 whose head is `carry`: detail
   `carried by #7`. Under `--no-gh`: still `carried`, detail
   `carried by origin/carry`, and `unknown:pr-open` is kept.
3. A local branch whose tip equals `origin/other`'s (another name, not its
   upstream): `carried`. Two remote rows `origin/a` and `origin/b` at one
   commit: neither is `carried`; both `unproposed`.
4. A remote row `origin/x` whose tip `origin/y` strictly descends from:
   `carried`, detail names `origin/y`.
5. A branch whose tip `origin/main` reaches: `landed`, never `carried`.
6. A detached worktree whose HEAD an open PR's head descends from: `carried`,
   detail `carried by #<n>`.
7. A worktree with an uncommitted change on a carried tip: `uncommitted,carried`.
8. A tip in both `origin/mid` and `origin/outer`, `origin/outer` descending from
   `origin/mid`: only `origin/outer` is named. Four outermost carriers:
   three named, then `, and 1 more`.
9. A branch whose newest PR was closed unmerged and whose tip a carrier
   reaches: `carried`, not `pr-closed-unlanded`.
10. A branch with its own open PR, inside another PR's head: `pr-open`, not
    `carried`.
11. A branch with one unpushed commit on a carried base: `unpushed`, not
    `carried` (control).
12. `carried` sits between `pr-closed-unlanded` and `orphan` in the states
    order (a worktree holding `uncommitted` and `carried` lists them in that
    order).

**Part A, chips.**

13. A `start_session` with `"initiation":"own_initiative"` and a result
    holding `(task_id: task_<hex>)`: a `chip` row with that ref, the title as
    detail and the proposing session as owner.
14. The same with `initiation` after `title` and `prompt` in the input: still
    a chip. With `user_asked`, with `offer`, or with `proposal_id`: no chip.
15. A result that goes on `Also still waiting: task_<other> "..."`: no row for
    `task_<other>`.
16. A proposal record holding the substring `task` nowhere outside its result
    (title and prompt free of it): still a chip.
17. `dismiss_task` naming a `start_session` chip's id: no row.
18. A `start_session` chip 168 hours old or more: detail holds `card expired`.
    A `spawn_task` chip of the same age: no `card expired`.
19. A `spawn_task` whose result is `Permission to use mcp__ccd_session__spawn_task
    has been denied.`: no row. A `spawn_task` with no `tool_result` in its
    file: a row whose ref is the `tool_use` id, states `unknown:chip-unstarted`,
    detail ending `no result recorded for the proposal`.

**Part A, started.**

20. A chip whose started session's first user record is the two-item form of
    A3 (reminder item ending `</system-reminder>\n\n`, prompt in the next item):
    started, no row.
21. A `start_session` chip whose started session's first text is framed
    (`Background (from the session that started this one):` ... blank line,
    `Task:`, the prompt, then a `Shared notes folder` paragraph): started.
22. A prompt shorter than 120 characters, started with text following it in
    the same item: started.
23. A session file (not the proposer's), modified after the proposal, holding a
    `custom-title` record equal to the chip's title, whose first text is
    unrelated: started. The same title only in the proposer's own file: not
    started. A title differing by one character: not started.
24. A `start_session` call carrying `"proposal_id":"<task id>"` with a result,
    in any session file modified after the proposal: started. The same call
    with no result in the file: not started by that call.
25. A session whose final assistant text asks, followed by a user record in the
    two-item reminder form holding a human reply: not `question`.

**Part B.**

26. **Groups.** One fixture repository holding a shared-branch hazard, a
    blocked worktree, a question worktree, a live worktree with uncommitted
    work, an unproposed branch, a carried branch, a landed branch, a pending
    handoff section and an unstarted chip; and open PRs in step 5's states
    founder (label `needs-founder`, green), session (a failed check), lander
    (green, nothing else), nobody (a check still running) and unknown (exactly
    100 files, green). Each row's group in `--tsv` is the one B3 gives.
27. **Nothing dropped or added.** With the same options and stubs, the page's
    non-summary rows with the first column cut equal, as a multiset, the rows of
    `felix inventory --tsv` plus `felix land --prs --tsv`. Every page row has
    nine columns.
28. **Counts.** Each summary row's content equals the number of rows in its
    group, and there are 16 summary rows per repository, in B5's order.
29. **`--no-host`.** The `blocked`, `question` and `running` summaries are
    `incomplete`; with no rows, their content is `unknown`; the text says
    `blocked sessions: unknown` and never `blocked sessions: 0`, and its
    reason names `sessions unknown: --no-host`.
30. **`--no-gh`.** Every `pr-` summary is `incomplete`, content `unknown`; the
    text says `pull requests waiting on the founder: unknown`.
    `never-proposed`, holding an uncommitted row, says `at least <n>` with a
    reason naming the `prs` cover row.
31. **gh failing** (the stub exits non-zero): the same readings as 30, and
    exit 0.
32. **An unknown PR.** With one PR in `pr-unknown`, `pr-founder` is
    `incomplete` and its reason says `1 pull requests not decided`.
33. **Text order and collapse.** The headings appear in B6's order; the
    `collapsed:` line comes after them; the refs of the running, carried,
    landed and handoff rows appear on no line of the text page, while the
    hazard, blocked, question, unproposed, chip and PR refs each appear once.
34. **Read-only.** After `felix monitor` and after `felix monitor --tsv`: the
    repository's refs, index, config, `HEAD` and object count are unchanged;
    the memory root and the home hold the same files with the same contents;
    `state/monitor.html` does not exist; the gh stub's log holds only `pr list`
    and `api` calls, and the launchctl stub's only `print`.
35. **The log page.** `felix monitor --log` writes `state/monitor.html` as the
    old command did, and `felix monitor --every 5` does too (a log option
    implies `--log`; without `--watch` it renders once and exits). No test
    runs `--open` past argument checking: `/usr/bin/open` would open a window.
    `felix monitor --log --tsv`, `felix monitor --open --repo x` and
    `felix monitor --bogus`: exit 2, nothing on stdout, and the usage on
    stderr names `--log`.
36. **Exit 1.** `felix monitor --repo <a directory that is no repository>
    --repo <the fixture>`: exit 1, a stderr line names the first, and the
    fixture's block is printed.
37. **Two repositories.** Two `--repo` options: two blocks in that order, and
    each source row's repo cell is its own source's.
38. **No project.** A repository no project governs: the page prints, land's
    `land`, `ledger` and `lander` rows are unread with step 5's detail, and
    exit 0.
39. **The filter.** A chip title holding ESC (0x1b) and BEL (0x07): the text
    page and the TSV print `?` for each.
40. **The existing assertions that ran `felix monitor` to render the HTML
    page** (part 0590 around lines 200-215 and part 0600 around lines 266-305
    on this branch) are restated to run `felix monitor --log`. No assertion is
    deleted, and their names stay.
41. **The page's awk failing** (added 2026-10-19, B8). An `awk` ahead of the
    real one on PATH exits 2 when one of its arguments begins `order=` and
    otherwise runs the real awk. `order=` is the page's own call: neither
    `felix inventory --tsv` nor `felix land --prs --tsv` passes an argument
    so spelled. With it, `felix monitor --repo <fixture>` exits 1, its stdout
    is the first line alone, and a stderr line holds the fixture's directory as
    given and `awk exited 2`; `felix monitor --tsv --repo <fixture>` exits 1
    with nothing on stdout and the same stderr line. With a stub that fails
    only the first `order=` call it sees (the page reads the repositories one
    at a time, in the order given): `--repo <A> --repo <B>` exits 1, the
    stderr line names A and no stderr line names B, and stdout is exactly what
    `felix monitor --repo <B>` prints with the real awk; the same with `--tsv`
    against `felix monitor --tsv --repo <B>`. The same runs with the real awk
    exit 0 (control).
42. **The gawk-name lint** (added 2026-10-19, B12): what B12 lists under
    "Tests".

## B10. Measured on felix-home, 2026-10-18

`felix inventory --tsv` on `~/Documents/Felix`, origin/main `248d9c7e`, 636
rows, 79 s wall and 62 s CPU.

- **Carried.** Of 66 rows holding `unproposed` (40) or `pr-closed-unlanded`
  (9), or undecided with content not landed (17), 27 are carried under A1:
    - 9 inside `claude/batch-18-carry`: the 7 the carrier named
      (`git-reads-fail-closed`, `no-diff-drivers-in-parsed-diffs`,
      `no-git-colour-in-parsed-output`, `no-caller-env-in-tool-output`,
      `commission-template-drift`, `quirky-heisenberg-fc2149`, and the remote
      `origin/claude/setup-actions-node24`), plus
      `LeavesJ/confident-archimedes-b76781` and the worktree
      `agent-a6d9abeb9c0de24ba`;
    - 9 `gf-c-*` worktrees inside #444's head;
    - 3 inside #360's head (`residue-rule-fix`, `residue-tracked-w5`, and
      `residue-tracked-w11` at its tip) and 1 inside #365's
      (`deny-followups-w6`);
    - 5 aliases, a local branch or worktree at the tip of a pushed branch of
      another name: `deny-343-landing-prep`, `~/felix-handover`, and
      `claude/lifecycle-recorder`, `claude/snapshot-command` and
      `fix/the-fold-count-says-what-it-folded` at the tips of
      `origin/salvage/*`, whose remote rows stay `unproposed`.

  `git for-each-ref --contains` over 272 remote refs answered all 66 in 4.7 s
  wall. The six branches inside #443's head are already `landed`: #443 merged
  at 0.49.294, and §4.3 rule 2 covers a tip a merged PR's head descends from.
- **Chips.** 62 `chip-unstarted` rows: 35 started (A3 cause 1; every one also
  matched by title), 5 denied proposals (A2), 22 with no started session found
  by prompt or title, and none of the 22 named in the carrier table. Over all
  time, 166 proposals: 127 matched by prompt and title, 3 by title only (the
  `start_session` cards, A3 cause 2), 36 by neither.
- **Not measured.** S3 has no example: no `start_session` call carrying a
  `proposal_id` is in the records yet, so the result it returns is unread, and
  S3 counts any result. The seven-day expiry is what the desktop app's result
  text says, not observed.

## B11. For the implementer

- **Where.** The page is a new `engine/harness/lib/lost-work.sh`, under 500
  lines, sourced by `cmd_monitor` in `engine/harness/felix`, which parses the
  arguments, sends `--log` (and `--open`, `--watch`, `--every`) to the existing
  render code unchanged, and the rest to the page. `lib/monitor.sh` and
  `templates/monitor.html` are not changed. The page runs `"$SCRIPT_DIR/felix"
  inventory --tsv ...` and `"$SCRIPT_DIR/felix" land --prs --tsv ...` and reads
  their stdout; it reads states, owner, content and kind, and never parses a
  detail. `lib/lost-work.sh` must not hold the strings `inventory.sh`,
  `inventory-` or `felix_inventory`, not even in a comment: part 0940's lint
  "inventory A111" fails any library outside `inventory*.sh` that names them.
  (Step 5's `lib/pr-status.sh:27` and `lib/pr-status-gh.sh:9` trip that lint
  on `claude/stuck-pr-page` at `6627e2ba`; that is step 5's to settle, and this
  branch inherits whatever it decides.)
- **Inventory.** A1 belongs in `lib/inventory.sh` (or `inventory-items.sh` if
  the 500-line limit needs it): one `git for-each-ref --contains=<tip>
  --format='%(refname) %(objectname)' refs/remotes/origin` per candidate row,
  through `_fi_git`'s prefix. A2 and A3 are `felix_inv_host_chips` and the awk
  `human()` in `lib/inventory-host.sh`: the file prefilter (`grep -l -F` on the
  spawn_task name) and the line filter (`grep -F -e task`) both have to admit a
  `start_session` line that does not hold `task`; the reminder loop strips the
  blanks after `</system-reminder>` before it tests for `K_NXT`; S2 and S3 read
  the same file set S1 reads. `lib/inventory-host.sh` is at 484 lines: move
  the chip reader to a new `lib/inventory-chips.sh` and add it to
  `cmd_inventory`'s source list.
- **Bash 3.2, the C locale** for every grep, awk, sort, tr and cut; digit
  brackets spelled out; no here-string; no pipe into a grep that can stop early
  (inventory spec §1); no string append that grows with input.
- **Tests** in new parts numbered from 1450 (step 5 holds 1300 to 1360, #446
  1400 to 1403 and slot 18 1500 to 1540). Fixture git commands through `_fx_cd` or `_fx_git`.
- **Help and docs.** `felix help`'s monitor line, the header comment of
  `engine/harness/felix`, and `engine/commands/felix.md`'s `felix monitor
  --open` bullet change to name the page and `--log`.
- **Lands as one engine PR**, risk-red (new lib files and lib edits). Version
  above main at "you are next": 0.49.299 as a placeholder (.294 #443 landed,
  .295 A30, .296 slot 18, .297 gate friction C, .298 step 5). Pipeline: blind
  assertions from this file alone (Opus), the implementation shown red first
  (Sonnet, high), one Opus review of the read-only contract, the unknown
  readings and A3 if the week's tokens allow, fixes, gate, PR, handoff section.

## B12. No gawk builtin name in lib's awk (added 2026-10-19)

**Defect.** The Linux CI runner's awk is gawk; macOS ships BWK awk. gawk
reserves names the other two leave free, so a program that uses one as its own
identifier passes every local run and fails, or reads differently, on Linux.
The page's row-tag array was named `RT`; gawk stopped on it (B8's amendment).
No check in the suite reads for such a name.

**The names**, exact case. Variables: `RT FPAT FIELDWIDTHS IGNORECASE PROCINFO
ERRNO ARGIND BINMODE LINT PREC ROUNDMODE SYMTAB FUNCTAB TEXTDOMAIN`. Functions:
`and or xor compl lshift rshift gensub asort asorti patsplit isarray typeof
strtonum strftime systime mktime`.

**Where.** `engine/harness/tests/lib/awk-names.sh` defines `_awk_names FILE...`
and runs nothing at source time (contract C2). It reads the files given as one
set: an assignment or a call in any of them resolves a reference in any.

**Output**, tab-separated, one row each, in any order but `programs` last:

| row | when |
|---|---|
| `name FILE LINE IDENT` | a listed name used as an identifier in an awk program's text, or as the variable of a `-v NAME=...` option or a `NAME=...` operand of an awk command |
| `unread FILE LINE WHAT` | a part of a program the lint cannot read (below), WHAT saying which |
| `open FILE LINE WHAT` | a quote, `$(`, `${` or here-document still open at the end of FILE, LINE where it opened |
| `programs N` | the number of program texts it read: program words, assignments and call arguments |

FILE is the path as given. LINE is the line of FILE the identifier stands on;
for a `-v` or operand variable, the line of that word; for `unread`, the line
of the word it could not read. Exit 0 when it printed no `name`, `unread` or
`open` row and N is above 0; else 1. A lint that read nothing does not pass.

**Reading a file as bash does.** Words are split at blanks, and commands at a
newline, `;`, `&`, `|`, `(` and `)`. A word may join unquoted characters, a
backslash and the character it escapes, `'...'`, `$'...'` and `"..."` (inside
which a backslash escapes `$`, a backtick, `"` and itself). `#` at the start
of a word begins a comment to the end of the line. A backslash at the end of a
line, outside single quotes, joins the next. `$(` opens a command of its own,
inside a word or inside double quotes, closed by its matching `)`; `${` opens
an expansion closed by its matching `}`. `<<WORD` and `<<-WORD` open a
here-document whose body begins on the next line and ends at a line holding
WORD alone (after leading tabs, for `<<-`); a body whose WORD was quoted in
any way is skipped whole, and in any other body only its `$( )` commands are
read. `<<<` is a here-string, not a here-document.

**An awk command.** In a simple command, skip in any order the assignments
`NAME=value` and the words `! { } if then elif else while until do`; then a
wrapper, `xargs env nice nohup command exec time builtin`, with the words
after it that begin with `-` or are assignments, as often as one follows. The
next word is the command word. If it is `awk`, or a path ending in `/awk`,
the command is an awk command, and its program is the first word after awk
that is none of: `-F` and its argument (attached or the next word), `-v` and
its argument (likewise), `--` (the program is the word after it), another word
beginning with `-`, or a redirection (a word beginning with digits or nothing,
then `<` or `>`; the next word too when the operator stands alone). `-f` and
its argument make the program a file: an `unread` row.

**A program's text** is its word's characters, quoted or not, with each
expansion taken as a placeholder that is no identifier. Each expansion in the
word is followed:

- `$NAME` or `${NAME...}`: a program variable. Its text is the value of every
  assignment of NAME in the files, bare, as a command's prefix, or after
  `local readonly export declare typeset`, each read like a program word, its
  own expansions followed in turn. A NAME nothing assigns is `unread`.
- `$1`-`$9`, `${N}` or `${N...}` inside a function F (defined `F()` or
  `function F`): F's Nth argument, whose text is the Nth argument word of
  every simple command whose command word is F, each read like a program word.
  An F nothing calls with N arguments is `unread`.
- `${#...}`, a length: a placeholder, nothing to follow.
- a command substitution, or any other special or positional parameter
  (`$@ $* $# $? $$ $! $- $0`, `${!...}`, `$1` outside a function): `unread`.

**An identifier** in program text is a maximal `[A-Za-z_][A-Za-z0-9_]*` that
stands outside a string, a regular-expression literal, a comment and a number,
so `RTAG` holds no `RT` and `"RT"` is no identifier. A string is `"..."`, in
which a backslash escapes the next character. A comment runs from `#` to the
end of the line. A number begins with a digit, or a `.` before a digit, and
runs over letters, digits, `_` and `.`. A `/` opens a regular-expression
literal unless the last thing before it on its line, blanks aside, is an
identifier other than `return`, `print` and `printf`, a number, `)` or `]`, in
which case it divides. A backslash inside a literal escapes the next
character, and a bracket expression inside it may hold `/`. Strings and
literals end at the end of the line at the latest.

**Tests**, in a new part:

1. On `engine/harness/lib/*.sh`, read together, `_awk_names` exits 0, prints
   no `name`, `unread` or `open` row, and reads at least 200 programs.
2. The defect, replayed: the same files with `RTAG` written `RT` in a copy of
   `lib/lost-work.sh`: exit 1, and `name` rows for that copy and `RT`, one of
   them on the line that copy's `n = ++NG[g]` stands on.
3. Each form, in a fixture file, is caught: an inline program; one across
   lines; one after `LC_ALL=C` and after `!`, `if`, `then` and `{`; one under
   `xargs -0`; one in `$(...)` inside double quotes; one in a `$( )` in an
   unquoted here-document body; a program variable assigned in another file
   given in the same call; one assigned with `local`; a program joined from a
   variable and a single-quoted part; a variable assigned from another; a
   function's `$2` passed by its callers; `-v RT=1`; `ERRNO` as an awk
   variable, `PROCINFO` as an array, `and(` and `mktime(` as calls, `or` as a
   parameter name. Each gives its `name` row on the identifier's line.
4. None of these is a `name` row: the names inside an awk string, a regex
   literal and an awk comment; `RTAG`, `PRT`, `ORT_`, `and_x`; a name in a bash
   comment, in a printf format, in a `sed` or `grep` argument, in a
   single-quoted string assigned to a variable no awk command reads, in a
   quoted here-document body, and as a bash variable `$RT` outside awk.
5. `unread` for a program in `$(...)`, for `awk -f`, for a variable nothing
   assigns, and for `$@` as a program; `open` for a file ending inside a
   single quote and for one ending inside a here-document.
6. Exit 1 and `programs 0` for a file with no awk command at all.

**Measured on this branch (origin/main ff592e55, step 6 as #450, with the B8
fix).** `_awk_names` over the 83 files of `lib/*.sh` reads 280 program texts
and prints no other row, under BWK awk and gawk 5.4.1. Every awk command a grep
finds outside comment lines is read, the eight whose program starts on a
continuation line included; the 19 program variables resolve to awk programs,
and `_felix_qualify_read`'s `$2` to its three callers' actions. Run on
`lib/lost-work.sh` at 17230ff3, before the rename, it prints six `name` rows
for `RT`. Over `lib/*.sh` with `felix`, `hooks/*` and `bin/*` added (21 more
files) it reads 366 and prints no other row; the part reads `lib/*.sh` only, as
this section asks.
