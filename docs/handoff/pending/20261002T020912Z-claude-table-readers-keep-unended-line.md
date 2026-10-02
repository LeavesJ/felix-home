### 2026-10-01: readers of a project's hand-edited tables keep a last row with no newline, and never open a pipe

Branch claude/table-readers-keep-unended-line, on claude/adopt-newline-before-append
(1dd58ae2), which fixed the writer side of this class. Engine only. It touches no
table under projects/, no commissioning table and no escape, and bumps no
version. The record and the bump are taken at the slot. The commits are squash-merged, so
the `wip:` ones are working history.

**Defect closed.** Two reader shapes over the tables a person edits under
projects/<name>/:
- `while IFS=$'\t' read -r a b; do ...; done < "$proj/x.tsv"` drops a last
  line with no newline. `read` returns 1 on that line with the fields filled,
  so the body never runs for it. On origin/main, a stack.tsv whose last row is
  `plugin<TAB>lastone<TAB>...` with no newline made `_felix_route_kind` print
  `not declared`. A deny.tsv whose only Bash row was its unended last line let
  every Bash call through hooks/pre-tool.
- An unconditional open of such a path (`grep ... "$proj/stack.tsv"`,
  `cat "$proj/$f"`, `sed ... project.json`) blocks forever when a FIFO is at
  the path, and it reads without end when the path is a link to a device.
  felix_resolve_project reads every project's project.json, so one pipe there
  held every hook of every project. A pipe at any commissioning table held the
  policy-version hash, and so the commission grant, the epoch and merge.

**The class, and how it was drawn.** All 241 `while ... read` loops in felix,
lib/*.sh and hooks/* were paired with their `done` and classified by input. A
heredoc or a `<<<` ends its last line. So do grep, cut, awk and sort, which
every feed of a project table already passes through (measured on macOS bash
3.2). sed, cat, tail, head, tr and uniq keep a missing newline, and none of
them feeds a loop over a project table. That leaves twelve loops reading a project table straight from the file.
Every one now keeps the row with `|| [ -n "${first:-}" ]`, the shape
felix_autonomy_allows and felix_budget_used already use:
- hooks/pre-tool (the deny precheck) and lib/deny.sh `_felix_deny_rows`;
- lib/route.sh `_felix_route_rows`, `_felix_route_kind`,
  `felix_route_names_capability`;
- lib/ready.sh `felix_ready_wanted`; lib/toolbox.sh `felix_toolbox_route_for`
  (profiles.tsv and routes.tsv);
- lib/maintenance.sh `felix_maint_unreachable`; lib/ledger.sh's zero rows;
- lib/monitor.sh's routes and stack loops.

The shape is exact here. With IFS=tab, leading tabs are trimmed, so the first
field is empty only on a blank or all-tab line, and every one of these loops
skips such a line anyway.

Every read of a project table was then listed (156 lines naming one, plus
helpers that return a project path), and the ones with no `-f` test ahead of
the open got `[ -f ]`. A non-regular path now reads as an absent table, which
is how every guarded reader already read it:
- stack.tsv in felix (recommend twice, ready --fix), commission-provider
  (felix_commission_request and the admit path), discover (candidates and the
  cached adopt), ready (unused and report), recommend, and the Stop hook twice;
- the monitor's routes and stack loops;
- felix_commission_policy_version (every commissioning table) and
  felix_commission_topology (commissioning.tsv). cat printed nothing for an
  absent table, and a skipped one prints nothing too. So the hash of any
  regular or absent table set is byte-identical to origin/main (checked:
  81138780 and 0dd49b31 on a fixture, the same on both), and no receipt goes
  stale;
- felix_json_str, which resolution calls on every project.json. It returns 2,
  printing nothing, for an existing non-regular path, and leaves an absent one
  to sed as before;
- felix_autonomy_commission_current's stamp (autonomy.commission).

Out of scope: templates/lifecycle.tsv (engine-owned, schema-checked by this
home's gate), state/ caches and handoff temp files (engine-written), and the
memory-root answer files (grep-fed).

**Tests.** Two tests/run blocks, before `reached`:
- *readers keep the unended last line of a hand-edited table, and open no
  pipe*. 76 assertions written blind by an Opus agent that read only the
  contract and the two pre-fix engine exports. Each unended-line case has a
  newline-ended control. Each FIFO case is bounded at 8 s by a helper that
  kills only its own pid tree, and is compared with the absent-table answer.
  The policy and topology hashes of a regular table set are pinned as
  literals (git hash-object, so the same on macOS and Linux).
- *no engine reader drops the unended last row of a project table, or opens
  one unguarded*. A lint, not blind: one awk pass over felix, lib and hooks
  that names either shape. It checks itself on samples first, and its comment
  says what it cannot see.

Section runner (tests/run 1-154 and the two blocks):

| engine | pass | fail |
|---|---|---|
| this branch | 81 | 0 |
| origin/main 27573cbe | 43 | 38 |
| writer tip c1024e5f | 43 | 38 |

On the old engines the 22 FIFO cases each time out at 8 s. On this branch the
block takes about 15 s.

**Review (Opus, 2026-10-02, workflow wf_bd5ede7f-56c).**
- Regressions: none. Policy and topology hashes byte-identical to origin/main
  for ordinary, absent, empty, directory, symlinked, dangling and unreadable
  tables; monitor stdout unchanged (only main's stderr noise is gone); all 13
  felix_json_str callers use the output only; pre-tool adds no subprocess;
  bash 3.2.57 runs the blocks 81/81.
- Mutation, four low findings, taken by the carrier (claude/adopt-newline-before-append's
  session) on 2026-10-02. T4 was in the truncated part of the notification and
  was read from the workflow journal:
  - T1: no blind case reached hooks/stop's stack.tsv guard inside the
    overnight branch. Closed by a fifth blind block (7 assertions, red 3 of 7
    on origin/main). Removing only that guard turns its three pipe assertions
    red.
  - T2: felix:2984's guard cannot be reached by a static pipe. Its comment now
    calls it defensive against a swap, held by the lint.
  - T3: the lint credits a guard in a sibling branch. Its comment now says so
    and names the two sites, both held by blind assertions.
  - T4: the lint's comment claimed it judged felix_json_str's open of "$1". It
    does not, nor "$proj/$f" opens. The comment now says so, and the blind
    block holds those sites.
- Completeness lens, re-run 2026-10-02 by the carrier session. It found no
  reader of a project table that this branch missed:
  - A pipe at each of 21 project paths, across 44 commands and all 8 hooks:
    924 runs, none blocked. The base blocked in 8 of the 18 runs it was given.
  - An unended last line on each of 16 tables, across 44 commands: 704 output
    pairs and no difference.
  - A pipe at each of 12 tables, across 11 bin/ scripts: 132 runs, none blocked.
  Beside the class:
  - git readers lose every diff after a pipe at a tracked path, which blinds
    felix_tree_id, felix_added_lines and bin/secret-scan. Spun off as its own
    task.
  - autonomy --revoke of a file's only grant. Already its own task.
  - obligations --seed, the autonomy commission stamp and detect.sh's cmp of
    an executable-pipe gate file still block on a pipe. Spun off as one task.
  - gate.sh's ecosystem.tsv loop and coverage.sh's lifecycle.tsv loops drop an
    unended row of an engine-owned table. Both fail closed, since the home's
    schema check refuses that shape. Left.

**Carrying.** The carrier (2026-10-02) folds this branch into one PR with
claude/adopt-newline-before-append, carried by that branch's session: one
record, one gate, weekly batch after the main order. Nothing runs before its
call.

**At the record.** assertions.tsv grows by 81 from this branch, on top of the
writer branch's.
