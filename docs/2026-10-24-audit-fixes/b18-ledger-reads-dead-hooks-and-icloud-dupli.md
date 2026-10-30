# Audit fix b18: the ledger reads dead hooks, and iCloud copies are named

This is the whole specification for batch b18. The blind assertions are written from it alone. It
says what must be true, not how. It was written against `origin/main` 69b51a61 (0.49.307). It covers
two defects from the register and one more that the C101 skeptic found in the same lines. Each was
confirmed, and the skeptics' corrections are used. The claims that do not hold are in section 6.

Words used below.

- **H** is a Felix home: a directory the test makes and names to the engine as `FELIX_HOME=H`.
  **P** is a project directory, `H/projects/NAME`. **M** is the memory root (`FELIX_MEMORY=M`), so
  P's memory is `M/NAME`. **U** is a fixture user home (`HOME=U`).
- The **state file** of session SID is `H/state/ledger/SID.tsv`, made of lines `KIND<TAB>NAME`.
  - `named` lines come from the prompt hook (`felix_ledger_note_named`).
  - Every other kind (`tool`, `skill`, `agent`, `mcp`) is a **call line**. PostToolUse
    (`hooks/post-tool`) writes these through `felix_ledger_record`.
  - The **alive line** is new. It is exactly `alive<TAB>post-tool`.
- The **fold** of SID is `M/NAME/ledger.d/SID.tsv`, written by `felix_ledger_rollup P H SID DATE`.
  Its rows are `SID<TAB>DATE<TAB>KIND<TAB>NAME<TAB>CALLS<TAB>NAMED`. "The fold is exactly" below
  means: fields 3 to 6 of each row, sorted with `LC_ALL=C sort`, are exactly the lines shown.
- A ledger row is **unknown** when its CALLS field is `-` (one hyphen). Every other row is
  **known**. No row is unknown today.
- In a state file, A is the number of alive lines, and C is the number of call lines with a
  non-empty NAME. The record is **incomplete** when A > C, or when A = 0 and C = 0. Otherwise it is
  **complete**.

## 1. Defects

- **C101** (medium; the skeptic kept it). When a PostToolUse hook fails, the ledger folds the
  failure in as a measured zero.
  - post-tool exits 0 and writes nothing at each of its silent exits. These are the guarded sources
    at `hooks/post-tool:35-36` and the exits at `:39`, `:42`, `:46` and `:49`. The register cites
    `:18-32`, which predates #447's environment block.
  - `felix_ledger_rollup` reads only the state file (`lib/ledger.sh:421-422`). It writes
    `named NAME 0 N` for every play that was named and has no call line (`:465-476`). It writes
    `KIND NAME 0 N` for every declared row that nothing reached (`:489-517`). Nothing checks
    whether PostToolUse recorded anything at all.
  - *Scenario:* in a session that really used the play the router named, post-tool cannot fork or
    cannot load its library. The fold then says the session never reached for the play.
    `felix_monitor_compliance` counts it as ignored, and the row reaches retire and the reconciler
    as evidence of disuse.
  - On this machine, sessions 2ca31540 and 31f621f8 each launched
    `superpowers:test-driven-development`, yet each fold holds
    `named superpowers:test-driven-development 0 1`. 7 of 269 sessions recorded fewer than half of
    their main-thread calls, and an async post-tool run leaves no trace in the transcript.
- **C101 (b)** (from the C101 skeptic's note; same lines, same loss). post-tool takes the *last*
  `"session_id"` in the payload (`hooks/post-tool:44-45`, a greedy sed). A tool whose input or
  response carries a `session_id` key therefore sends its line to another session's file.
  - *Scenario:* the `mcp__ccd_session_mgmt__*` and `mcp__ccd_sidebar__*` tools return
    `"session_id":"local_<id>"`. On this machine 1,230 lines sit in 191 `state/ledger/local_<id>.tsv`
    files that no mark owns. Those lines are never folded and never counted as stranded, and the
    real session's file loses the reach.
  - It is fixed here because B1's alive line would go to the wrong file along with the call line.
    The real session's file would then still read as complete.
- **C052** (low, as corrected; it was medium). iCloud's conflict copies (`NAME 2`, `NAME 2.tsv`)
  sit in the Felix home's `state/` and `.git`. Nothing in the engine looks for them, or for a home
  inside an iCloud-synced folder.
  - Today there are 18 copies under the home's `state/`: `pulse.status 2.tsv`,
    `discover/felix 2.tsv`, 16 `discover/*.tsv N.new`, and `held-tree/347cd673-… 2`, whose
    original is gone. There are more under `.git/worktrees/quizzical-banach-e7a0e8/`:
    `felix-suite-receipt 2` and `index 2` to `index 5`.
  - `~/Library/Mobile Documents/com~apple~CloudDocs/Documents` is a symbolic link to `~/Documents`,
    so the home is synced.
  - *Scenario:* a macOS user with Desktop & Documents sync on keeps the home in `~/Documents`.
    Sync then copies a ref or a record in the middle of a write. On 10-14, `main 2` refs broke every
    clone, and 121 `* 2` copies turned part 1040 red. `felix status`, the gate and the monitor say
    nothing about why.

## 2. Required behaviour

### Recording (hooks/post-tool)

**B1. One alive line per run, written before the signal is extracted.** post-tool is run with
`FELIX_HOME=H` (H exists) and a payload whose session id is SID.
- Before it extracts the signal, it appends exactly one alive line to `H/state/ledger/SID.tsv`.
  It then appends the signal line, as today. It makes `H/state/ledger` when that is missing.
- With `{"session_id":"SID","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"ls"}}`
  the file is afterwards exactly two lines: `alive<TAB>post-tool`, then `tool<TAB>Bash`.
- Two such runs leave four lines: alive, tool Bash, alive, tool Bash.

**B2. A run that records no call still leaves its alive line.** A payload with a session id and no
`tool_name` (for which `felix_ledger_signal` prints nothing) leaves the single line
`alive<TAB>post-tool` and nothing else.

**B3. With no session or no home, nothing is written, as today.** When stdin is empty, when the
payload has no `session_id`, or when FELIX_HOME names a path that is not a directory, nothing is
created under H, and nothing is created at the missing path.

**B4. The payload's own session id.** The session id is the value of the *first* `"session_id"`
key in the payload. That is the top-level one, because Claude Code writes it first.
- The payload is
  `{"session_id":"s-top","hook_event_name":"PostToolUse","tool_name":"mcp__ccd_session_mgmt__get_session","tool_input":{"session_id":"local_in"},"tool_response":{"session_id":"local_out"}}`.
  Afterwards `H/state/ledger/s-top.tsv` is exactly `alive<TAB>post-tool` and
  `mcp<TAB>ccd_session_mgmt`, and neither `local_in.tsv` nor `local_out.tsv` exists.
- The signal's own extraction (`tool_name`, `skill`, `subagent_type`) is unchanged.

**B5. Still silent.** Every run in B1 to B4 exits 0 and prints nothing on stdout or stderr.
`felix_ledger_record` and `felix_ledger_note_named` are unchanged: they write no alive line.

### Folding (felix_ledger_rollup)

For B6 to B10, `P/stack.tsv` is the single line `plugin<TAB>other@x<TAB>-<TAB>low<TAB>always`.

**B6. A complete record folds as it does today, and an alive line is not a capability.** No fold
ever holds a row whose KIND is `alive`, or a row whose NAME is `post-tool` because of an alive line.
A state of `alive<TAB>post-tool`, `tool<TAB>Bash`, `named<TAB>superpowers:brainstorming` folds to
exactly:
```
named	superpowers:brainstorming	0	1
plugin	other@x	0	0
tool	Bash	1	0
```

**B7. A record with nothing from PostToolUse folds as unknown.** The state is the single line
`named<TAB>superpowers:brainstorming`. The fold is exactly:
```
named	superpowers:brainstorming	-	1
plugin	other@x	-	0
```

**B8. A record with fewer calls than alive lines folds as unknown wherever it would say zero.** In
an incomplete record, every row the fold writes because something was *not* reached carries `-` for
CALLS. That covers a named row with no call line and a declared row that nothing reached. NAMED is
counted as today, and call rows keep their counts.
- A state of `alive`, `alive`, `skill<TAB>superpowers:test-driven-development`,
  `named<TAB>code-review` folds to exactly:
  ```
  named	code-review	-	1
  plugin	other@x	-	0
  skill	superpowers:test-driven-development	1	0
  ```
- The same through the real writers: `felix_ledger_note_named H SID code-review`, then post-tool
  with a Bash payload, then post-tool with a payload that has no `tool_name`, then the rollup. The
  fold is exactly:
  ```
  named	code-review	-	1
  plugin	other@x	-	0
  tool	Bash	1	0
  ```

**B9. Records written before the alive line existed.**
- A state with no alive line and at least one call line is complete, so it folds as today, with
  `0`s.
- A state with more call lines than alive lines (a session resumed across the change) is complete.
  A state of `tool<TAB>Read`, `alive<TAB>post-tool`, `tool<TAB>Bash`, `named<TAB>code-review`
  folds to exactly:
  ```
  named	code-review	0	1
  plugin	other@x	0	0
  tool	Bash	1	0
  tool	Read	1	0
  ```
- Rolling the same state twice gives a byte-identical fold, complete or not, as today.

**B10. Unknown clears when the calls arrive.** An async post-tool run that is still going at
SessionEnd can leave an incomplete fold. Its line lands later, and the existing catch-up folds the
session again.
- Fixture: a git repository R with one commit. `H/state/session/SID` holds R's HEAD.
  `H/state/ledger/` holds only `SID.tsv`, which is `alive<TAB>post-tool` and `named<TAB>code-review`.
- After the rollup, the fold is exactly `named	code-review	-	1` and `plugin	other@x	-	0`.
- Then set the fold's mtime to 2026-01-01 (`touch -t 202601010000`) and append `tool<TAB>Bash` to
  `SID.tsv`. `felix_ledger_stranded P H R` prints `1`, `felix_ledger_catchup P H R` prints `1`, and
  the fold is then exactly:
  ```
  named	code-review	0	1
  plugin	other@x	0	0
  tool	Bash	1	0
  ```

### Reading (lib/ledger.sh, lib/monitor.sh, felix ledger)

The fixture for B11, B12 and B14 is a project Q whose basename is QN. Q has no `stack.tsv`, and
HOME is a fixture with no plugin registry. Rows are written by hand, one file per session, into
`M/QN/ledger.d/<sid>.tsv`, all dated 2026-10-01:

| capability | sessions and rows |
|---|---|
| alpha | k1 to k5, each `named alpha 0 1` |
| beta | u1 to u5, each `named beta - 1` |
| gamma | g1 to g4 `named gamma 0 1`; g5 `named gamma - 1` |
| delta | d1 and d2 `plugin delta@x 0 0`; d3 `named delta - 1` |
| epsilon | e1 `plugin epsilon@x 0 0`; e2 `plugin epsilon@x - 0` |
| ctx | m1 `mcp ctx - 1`; m2 `mcp ctx 3 0` |

**B11. An unknown row is not evidence of disuse.** `felix_ledger_summary Q` reads only known rows.
An unknown row adds nothing to a capability's sessions, invocations or named count, and a
capability with only unknown rows gets no line. The output is exactly:
```
alpha	5	0	5
ctx	1	3	0
delta	2	0	0
epsilon	1	0	0
gamma	4	0	4
```
The other readers follow:
- `FELIX_LEDGER_MIN=5 felix_ledger_retire Q` prints exactly `alpha	5	5`.
- With `FELIX_LEDGER_MIN=4` it prints exactly `alpha	5	5` and `gamma	4	4`.
- With `FELIX_LEDGER_MIN=3` it does not list delta.
- `felix_ledger_mcp Q` prints exactly `ctx	1	3	0`.
- `felix_ledger_sessions Q` still counts every session in the rows, unknown ones included, and
  prints `22`.

**B12. An unknown naming still counts as a naming.** `felix_ledger_unrouted Q` never lists a
capability that some unknown row names (NAMED above 0), with that row reduced to its owner the way
the summary reduces it. A capability whose unknown rows name it 0 times is judged on its known rows
alone. The output is exactly `epsilon	1`, and delta is not listed.

**B13. Compliance counts only what is known.** `felix_monitor_compliance Q2` runs with
`lib/monitor.sh` and `lib/ledger.sh` sourced. Project Q2's ledger holds only these rows:
- session c1, dated 2026-08-01: `plugin followed@x 4 2`, `plugin ign@x 0 3`, `named unk - 2`;
- session c2: `named onlyunk - 1`.

The output is exactly the one line `c1	2026-08-01	2	1	1`. An unknown row is neither named,
followed nor ignored, and a session whose only named rows are unknown prints no line.
`felix monitor`'s JSON keeps its shape. (Amended by R2 in section 9: c1 loses `named unk - 2`.)

**B14. felix ledger says what is unknown.** `felix_ledger_unknown Q` prints the number of distinct
sessions that hold at least one unknown row. For the B11 fixture that is `9`: u1 to u5, g5, d3, e2
and m1. It prints `0` when there is none.

`felix ledger` is run in a checkout bound to the project. In each of the cases below it exits 0.
- **(a)** With unknown rows, it prints exactly one line that begins `unknown, not zero: 9 session(s)`
  (the count is `felix_ledger_unknown`'s), and that line contains `incomplete`.
- **(b)** With none, it prints no line that begins `unknown, not zero:`.
- **(c)** A capability whose rows are all unknown is not a line of the table: no line begins
  `  beta `.
- **(d)** When every row is unknown, it prints no line `  nothing yet`. The unknown line says it
  instead.

### Status (lib/status.sh, felix status)

Below, CD is `U/Library/Mobile Documents/com~apple~CloudDocs`.

A name is **shaped like an iCloud copy** when its last path component matches the ERE
` [0123456789]+(\.[^ ]+)?$`. That is a space and one or more digits, followed either by the end of
the name or by a dot and one or more characters that are not spaces.
- These names match: `pulse.status 2.tsv`, `felix 2.tsv`, `felix.tsv 3.new`, `index 5`, `main 2`,
  `abc 2`.
- These do not: `unknown (2026-08-31 session, not found in transcript search).tsv`, `v2.tsv`, `a2`,
  `x 2y`, `b 2.`.

**B15. felix_icloud_state.** `felix_icloud_state HOME_DIR`, in `lib/status.sh`, prints one line
`STATE<TAB>VALUE<TAB>DETAIL`, returns 0 and writes nothing.

*The scan.* It scans `HOME_DIR/state` and `HOME_DIR/.git`, each when it is a directory, for names
shaped like an iCloud copy. It skips everything under `HOME_DIR/.git/objects`. N is the number of
paths it finds, files and directories alike, each counted once.

*The detail.* DETAIL is COPIES, then `; `, then SYNCED.

COPIES is one of:
- C0, when N = 0: `no name shaped like an iCloud copy under state/ and .git (objects not read)`
- CN, when N ≥ 1: `N name(s) shaped like an iCloud copy under state/ and .git (objects not read): LIST`.
  LIST is the first min(N, 3) of the found paths, relative to HOME_DIR, in `LC_ALL=C` order and
  joined by `, `. When K = N − 3 is above 0, ` and K more` follows.
- CU, when the walk reports an error: `the scan of state/ and .git could not read every directory, so how many names are shaped like an iCloud copy is not known`

SYNCED is one of:
- SI(F): `the home is inside iCloud-synced F, which renames files Felix writes; a home outside Desktop, Documents and iCloud Drive avoids it`.
  F is chosen by the first rule that holds:
  1. `iCloud Drive`, when the home's physical path lies under the physical path of
     `U/Library/Mobile Documents`;
  2. `Documents`, when `CD/Documents` is a symbolic link that leads to the same physical directory
     as `U/Documents`, and the home's physical path is that directory or lies under it;
  3. `Desktop`, by the same test with `Desktop`.
- SN: `the home is not inside iCloud Drive or an iCloud-synced Desktop or Documents`. This holds
  otherwise: CD is absent, `CD/Documents` is a plain directory, or the link leads somewhere else.
- SU: `whether the home is inside an iCloud-synced folder is not known: no home directory to look in`.
  This holds when HOME is unset or empty. (R3 in section 9 adds SX, a lookup that failed.)

"Physical" means with every symbolic link resolved, as `pwd -P` gives it. A home reached through a
link to `U/Documents/fh` is therefore inside Documents.

*STATE and VALUE.* The first matching row of this table decides:

| case | STATE | VALUE | DETAIL |
|---|---|---|---|
| HOME_DIR empty, or not a directory | `unknown` | `-` | exactly `no Felix home resolved` |
| the walk reported an error | `unknown` | `-` | CU; SYNCED |
| N ≥ 1 | `value` | `copies-N` | CN; SYNCED |
| N = 0 and SYNCED is SI | `value` | `synced` | C0; SI(F) |
| N = 0 and SYNCED is SN | `value` | `clear` | C0; SN |
| N = 0 and SYNCED is SU | `unknown` | `-` | C0; SU |

**B16. felix status shows it.** `felix status --tsv` prints an `icloud` row,
`icloud<TAB>STATE<TAB>VALUE<TAB>DETAIL`, built from `felix_icloud_state "$FELIX_HOME_DIR"`.
- It appears once, and it is the last row.
- The rows before it keep their order and their content. They begin `settings`, `schedule`,
  `pulse`, `reach`, `gate`.
- Plain `felix status` prints it aligned the way it prints the other rows.
- `felix status` still writes nothing and still runs no claude.
- Example: H is `U/Documents/fh`, `CD/Documents` links to `U/Documents`, and H/.git is a directory.
  H holds `state/pulse.status 2.tsv`, `state/discover/felix.tsv 3.new`, `state/held-tree/abc 2`,
  `.git/worktrees/w/index 2`, and `.git/objects/ab/cd 2`, which is not counted. The row is then:
  `icloud	value	copies-4	4 name(s) shaped like an iCloud copy under state/ and .git (objects not read): .git/worktrees/w/index 2, state/discover/felix.tsv 3.new, state/held-tree/abc 2 and 1 more; the home is inside iCloud-synced Documents, which renames files Felix writes; a home outside Desktop, Documents and iCloud Drive avoids it`

## 3. What must not change

| Behaviour | Pinned by |
|---|---|
| `felix_ledger_signal`'s extraction: tool, mcp server, skill, agent and Task, and nothing for an unparseable payload. `felix_ledger_record` appends one line per call. The rollup counts repeats once with a total, writes zero rows for declared rows nobody reached, and does not double a re-roll. Stranded and catch-up go by mtime and use the state file's own date. The banner and `felix ledger` hedge and report what they folded. | `0320-discovery-reads-a-download-piped-into-a-shel.sh` |
| One rollup, one file. Twelve concurrent folds. The legacy `ledger.tsv` is read, and a re-roll replaces its rows. The `plugin_` prefix fold and the agent join. Hook shapes only, mixed and none, and the retire, unobserved and partly lists with `felix ledger`'s proposals. The unrouted caveat. A marketplace is never unrouted. Rows without a NAMED column say nothing. `note_named` counts (`code-review 0 2`). | `0330-one-rollup-one-file.sh` |
| Summary sessions: a post-tool run in one, after which SessionEnd folds nothing and the marker goes. Stranded and catch-up skip old summary sessions and still fold a person's, with what it reached for. | `0230-the-intent-router.sh` |
| The owner-anchored NAMED column, built-in skill rows, the reconciler's mount and unmount | `0380-the-reconciler-reads-the-record-reached-besi.sh` |
| Compliance over known rows, and nothing for rows from before the column; the monitor page renders `"compliance":` | `0600-what-to-do-next.sh` |
| Membership in lists larger than a pipe holds, in stranded, catch-up, and the rollup's `seen` and `seen_owner`; `named spa-n:never-reached 0 1` in a session that has call lines | `0970-membership-in-a-list-larger-than-a-pipe-cove.sh`, `0980-qualification-commissioning-adoption-the-led.sh` |
| The zero row for an unended last `stack.tsv` line (`plugin lastone 0 0` beside a call line) | `1020-readers-keep-the-unended-last-line-of-a-hand.sh` |
| Every `[[ =~ ]]` in runtime code (hooks included) sits in a function that declares `local LC_ALL=C` (L1). `felix_ledger_summary`'s text tools are written `LC_ALL=C <tool>` (L2). F6: a summary over non-UTF-8 bytes. | `0996-continued.sh`, `0994-bash-s-own-collation-and-the-bsd-text-tools.sh` |
| `felix_ledger_retire` is defined for session-start, and session-start sources `ledger.sh` | `0010-resolution.sh` |
| `felix status` rows have four fields, a known state, a bare value, and `-` unless the state is value. The S2 aligned form. It writes nothing and runs no claude. The content of the settings, schedule, pulse, reach and gate rows. | `1100-declared-tools-reach-the-pulse-and-felix-status.sh`, `1110-found-after-the-blind-part-status-index-and-long-list.sh` |
| post-tool's environment prologue and git colour pin | `1500-git-colour-never-reaches-what-the-engine-parses.sh`, `1510-no-caller-environment-changes-a-tool-s-output.sh` |
| No bare mktemp (scratch goes under TMPDIR); no printf piped into `grep -q`; every part is a line of `tests/run` | `1000-the-engine-makes-its-scratch-under-tmpdir.sh`, `0960-no-engine-test-reads-a-pipe-through-a-grep-t.sh`, `1040-the-suite-is-cut-into-parts.sh` |

**The one existing pin this batch changes is in 1100.**
- The assertion "and prints exactly five rows: settings, schedule, pulse, reach, gate" (line 409)
  becomes "and prints exactly six rows: settings, schedule, pulse, reach, gate, icloud". It expects
  `settings schedule pulse reach gate icloud `.
- Its S4 guard (line 428, `= 5`) becomes `= 6`. The two `bad` details become "status did not answer
  six rows".
- b05 makes the same edit for its `alerts` row. Whichever of the two lands second makes the count
  seven, with `icloud` last. The record step re-records the renamed names.
- The reach spec's "five rows" (S1, S2) and `lib/status.sh`'s header are read as amended.

**Other constraints.**
- *Sizes.* post-tool stays far under 500 lines. `lib/status.sh` stays under 500 together with what
  b03, b04, b05 and b06 add. `lib/monitor.sh` stays under 500. `lib/ledger.sh` is 717 lines and is
  not on the must-not-grow list, but it grows only by what the change needs. `felix` gets no longer:
  `cmd_ledger`'s one `nothing yet` line can hand the choice to a function in `ledger.sh`.
  `lib/resolve.sh` is not touched.
- *Driver.* `tests/run` gains two part lines; b00 makes the room.
- *Cost.* post-tool runs after every tool call. It may add one append, and it forks nothing more
  than it does today.
- *Portability.* Everything works under bash 3.2 and bash 5, and under BWK awk and gawk. Use
  `LC_ALL=C` for sort and for comparisons. Spell digit brackets out. No associative arrays. No
  `case` inside `$( )`.

## 4. Assertions

**Fixture conventions.**
- Hook runs: `printf '%s' PAYLOAD | env FELIX_HOME=H HOME=U "$FROOT/harness/hooks/post-tool"`.
- Library runs: `( export FELIX_MEMORY=M; . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/ledger.sh"; … )`.
  `lib/monitor.sh` is also sourced for compliance, and `lib/status.sh` for B15.
- Each fixture is made under the suite's TMP, and each part leaves `$FROOT/state` and `$MEM` the way
  it found them.
- `(control)` marks an assertion that is true both before and after the fix. Every other assertion
  fails on today's tree.

### Part 1970: the ledger

- **A1 (B1).** H has no `state/`. After the Bash payload for `pt1`, `H/state/ledger/pt1.tsv` is
  exactly `alive<TAB>post-tool` and then `tool<TAB>Bash`.
- **A2 (B1).** Two runs of the Bash payload for `pt1b` leave four lines, alternating alive and
  `tool<TAB>Bash`.
- **A3 (B2).** `{"session_id":"pt2","hook_event_name":"PostToolUse"}` leaves `pt2.tsv` as exactly
  the one line `alive<TAB>post-tool`.
- **A4 (B3) (control).** Three runs, each with a fresh H: empty stdin;
  `{"hook_event_name":"PostToolUse","tool_name":"Bash"}`; and the A1 payload with FELIX_HOME set to
  `H/missing`. Each leaves no `H/state/ledger/*` entry, and `H/missing` does not exist.
- **A5 (B4).** After the B4 payload, `s-top.tsv` is exactly `alive<TAB>post-tool` and
  `mcp<TAB>ccd_session_mgmt`, and neither `local_in.tsv` nor `local_out.tsv` exists under
  `H/state/ledger`.
- **A6 (B5) (control).** Every run in A1 to A5 exits 0 with empty stdout and empty stderr.
- **A7 (B5) (control).** `felix_ledger_record H r1 "tool<TAB>Bash"` and
  `felix_ledger_note_named H r1 code-review` leave `r1.tsv` as exactly `tool<TAB>Bash` and
  `named<TAB>code-review`.
- **A8 (B6).** The B6 state, hand-written, gives the exact B6 fold. No row has KIND `alive`.
- **A9 (B7).** The B7 state gives the exact B7 fold.
- **A10 (B8).** The B8 hand-written state gives its exact fold.
- **A11 (B8).** The B8 run through the writers (note_named, the post-tool Bash payload, the post-tool
  payload with no `tool_name`, the rollup) gives its exact fold. No row has KIND `alive`.
- **A12 (B9) (control).** `tool<TAB>Bash` and `named<TAB>code-review` fold to
  `named code-review 0 1`, `plugin other@x 0 0`, `tool Bash 1 0`.
- **A13 (B9).** The B9 resumed state gives its exact fold. No row has KIND `alive`.
- **A14 (B9) (control).** Rolling the B7 state twice leaves a byte-identical fold.
- **A15 (B10).** The B10 sequence: the first fold is B7-shaped, then stranded prints `1`, catch-up
  prints `1`, and the final fold is exact.
- **A16 (B11).** `felix_ledger_summary Q` prints exactly the five B11 lines.
- **A17 (B11).** retire prints exactly `alpha	5	5` at MIN 5, and exactly the two lines
  `alpha	5	5` and `gamma	4	4` at MIN 4. At MIN 3 no line begins `delta`.
- **A18 (B11).** `felix_ledger_mcp Q` prints exactly `ctx	1	3	0`.
- **A19 (B11) (control).** `felix_ledger_sessions Q` prints `22`.
- **A20 (B12).** `felix_ledger_unrouted Q` prints exactly `epsilon	1`.
- **A21 (B12) (control).** No line of `felix_ledger_unrouted Q` begins `delta`. This holds today,
  and a fix that only dropped unknown rows would break it.
- **A22 (B13).** Compliance over Q2's rows prints exactly `c1	2026-08-01	2	1	1`.
- **A23 (B14).** `felix_ledger_unknown Q` prints `9`. Over a project whose only rows are alpha's,
  it prints `0`.
- **A24 (B14a).** Fixture: `$FROOT/projects/b18q`, holding the B11 rows in `$MEM/b18q/ledger.d`,
  and a git checkout whose root `.felix` reads `b18q` (as part 0330's scope fixture binds one).
  `felix ledger` there exits 0 and prints exactly one line that begins
  `unknown, not zero: 9 session(s)`, and that line contains `incomplete`.
- **A25 (B14b) (control).** The same with project `b18k`, which holds only alpha's rows: exit 0,
  and no line begins `unknown, not zero:`.
- **A26 (B14c).** In A24's output, no line begins `  beta `.
- **A27 (B14d).** Project `b18u`, which holds only beta's rows: exit 0, no line is `  nothing yet`,
  and one line begins `unknown, not zero: 5 session(s)`.

### Part 1980: the icloud row

The fixtures: U is a fresh directory. H is a Felix home with `projects/`, `state/` and a `.git`
directory, placed where each case says.

- **A28 (B15).** H under `U/plain/fh`, no CD: the output is exactly
  `value<TAB>clear<TAB>` C0 `; ` SN.
- **A29 (B15).** H under `U/Documents/fh`, `CD/Documents` a link to `U/Documents`: the output is
  exactly `value<TAB>synced<TAB>` C0 `; ` SI(Documents).
- **A30 (B15).** H under `U/Desktop/fh` with `CD/Desktop` linked to `U/Desktop` gives SI(Desktop).
  H under `CD/fh` gives SI(iCloud Drive). Both have VALUE `synced`.
- **A31 (B15).** The A29 layout with FELIX_HOME passed as `U/lnk`, a link to `U/Documents/fh`:
  the output is the A29 line.
- **A32 (B15).** `CD/Documents` as a plain directory, then `CD/Documents` as a link to `U/elsewhere`
  (H still under `U/Documents`): both give exactly the A28 line.
- **A33 (B15).** The A29 layout plus the five B16 example names: the output is exactly the
  B16 example's three fields after `icloud<TAB>`.
- **A34 (B15).** A28's layout plus `state/ledger/unknown (2026-08-31 session, not found in transcript search).tsv`,
  `state/v2.tsv`, `state/a2`, `state/x 2y` and `state/b 2.`: the output is exactly the A28 line.
- **A35 (B15).** A28's layout plus six copies, `state/a 1` to `state/f 6`: VALUE is `copies-6`, and
  DETAIL begins
  `6 name(s) shaped like an iCloud copy under state/ and .git (objects not read): state/a 1, state/b 2, state/c 3 and 3 more; `.
- **A36 (B15).** A28's layout plus `state/locked`, chmod 000 (skipped when EUID is 0, and the mode
  is restored afterwards): the output is exactly `unknown<TAB>-<TAB>` CU `; ` SN.
- **A37 (B15).** A28's layout with HOME unset (`env -u HOME`, FELIX_MEMORY set): the output is
  exactly `unknown<TAB>-<TAB>` C0 `; ` SU.
- **A38 (B15).** As A37, plus `state/x 2`: VALUE is `copies-1`, and DETAIL ends `; ` SU.
- **A39 (B15).** `felix_icloud_state ""` and `felix_icloud_state U/none` each print exactly
  `unknown<TAB>-<TAB>no Felix home resolved`.
- **A40 (B15) (control).** After A28 to A39, `find H U -newer MARKER` lists nothing. MARKER is
  touched before the calls; the mode changes of A36 are left out.
- **A41 (B16).** In the A33 layout, `felix status --tsv` (cwd an ungoverned directory, FELIX_HOME=H,
  HOME=U) exits 0. The first fields of its first five rows are `settings schedule pulse reach gate`,
  `icloud` is the first field of exactly one row, and that row is the last.
- **A42 (B16).** That row is `icloud<TAB>` followed by `felix_icloud_state H`'s line for the same
  layout.
- **A43 (B16).** Plain `felix status` prints that row as `printf '%-9s %-12s %s\n' icloud copies-4 DETAIL`.
- **A44 (B16) (control).** With the copies present, `felix status --tsv` writes nothing under H, U
  or the memory root.

## 5. Parts

- `engine/harness/tests/parts/1970-ledger-unknown-not-zero-blind.sh`: A1 to A27.
- `engine/harness/tests/parts/1980-icloud-copies-status-row-blind.sh`: A28 to A44.

Both are added to `tests/run` after the last 16xx to 19xx part line and before the `! alias .`
line that precedes 9990. Neither needs a `groups.tsv` entry.

## 6. Out of scope

**Not fixed in this batch.**
- **The transcript as a second witness.** It would correct partial losses that predate the fix,
  such as 2ca31540 and 31f621f8, whose state files have call lines and no alive lines and so read
  as complete. But SessionEnd's own header rules out reading the transcript, and the catch-up has
  no transcript path. That is a design change of its own.
- **Runs that die before the session id is known, and runs Claude Code never starts.** These cover
  the sources, the `cat`, `felix_home` and the session extraction under fork exhaustion. They leave
  no alive line. Such a loss reads as unknown only when the whole session recorded nothing. A
  fork-free prologue would narrow the gap. That is b03's C029 shape for pre-tool, and post-tool
  would follow it. (R1 in section 9 takes this back for post-tool.)
- **Correcting folds already on disk.** There is no migration. `ledger.sh`'s rule is that rows are
  data and are never rewritten to change their shape.
- **Last-occurrence extraction of `tool_name`, `skill` and `subagent_type`, and pre-tool's session
  extraction.** Nothing on disk shows a hijack of the first three (`ledger.sh:358-364` records the
  assumption), and pre-tool is not in this batch's files.
- **The unknown count on the monitor page or at session start.** Compliance drops unknown rows, so
  the page covers known rows only, and `felix ledger` says the count; `templates/monitor.html` is
  already 563 lines. Unknown rows only remove retire evidence, so the session-start banner can only
  shrink, and a line there would be a report nobody asked for.
- **C052: moving machine state out of the synced home** (for example `~/.felix/state`). That
  changes where every hook writes and needs a migration. It is its own design.
- **C052: the pulse report, the pulse row, a `felix install` warning and a README note.** `pulse.sh`
  is 476 lines and b06 rewrites the pulse row's detail; the pulse can call `felix_icloud_state`
  later. The clone location is chosen before install, the README already clones into the current
  directory, and the status row is the surface people poll.
- **C052: other sync tools (Dropbox, OneDrive and others) and a `.git` that is a file.** Only
  iCloud's ` N` shape and its layout were observed. When the home is a linked worktree, its git
  directory lives elsewhere and is not scanned.
- **The `resolve.sh:171-173` comment** calling iCloud's Documents "the ordinary place" for a home.
  It is a comment, not behaviour, and `resolve.sh` must not grow.

**Not fixed: not a defect.** These are the claims that do not hold when the code is read.
- **C052 claims felix status shows an older pulse run as the last one.** Not on this tree. The live
  `state/pulse.status.tsv` (Oct 24) is newer than `pulse.status 2.tsv` (Oct 18). `pulse.sh:437-447`
  rewrites the record whole every day with a temporary file and a rename, and `status.sh:172` reads
  the live one. The B16 row still names the copy.
- **C052 claims the README sends new users to `~/Documents`.** It does not. `README.md:212-215` and
  `:477-480` clone into the current directory.
- **C052 claims a `<sid> 2.tsv` ledger copy is silently dropped.** The mechanism is real
  (`ledger.sh:564-570`, `:684`, `:704`), but it has never been observed. `state/ledger` holds no sync
  copy: its one name with a space is the hand-named `unknown (…).tsv`. Ledger files are only ever
  appended to (`ledger.sh:384-404`), and every copy found came from writers that use a temporary
  file and a rename, or that delete and recreate. If such a copy appears, the icloud row names it.
- **C101's post-tool line numbers in the register.** They are 17 lines stale. The defect stands at
  the lines given in section 1.

## 7. Founder PR

None. The batch needs no `.github/workflows` change, no deny or escape row, no commission grant and
no publishing. The alive line lives in `state/ledger`, as the call lines do today.

## 8. Red

Run on 69b51a61 plus the two blind parts, before any engine change: `alone.sh <worktree> bwk 1970-ledger-unknown-not-zero-blind.sh 1980-icloud-copies-status-row-blind.sh` (bash 3.2.57, macOS awk). The two parts print 44 assertion lines, one for each of A1 to A44. **34 failed and 10 passed.** The 62 other `ok` lines of that run are the driver's preamble (the fixture-floor checks), not this batch.

Every one of the 10 that passed is a (control) the contract names. They split two ways.

- **Already true on 69b51a61 (the behaviour the fix must keep):** A4 (B3: no session or no home, nothing written), A6 (B5: the hook is silent and exits 0), A7 (B5: `felix_ledger_record` and `felix_ledger_note_named` write only their own lines), A12 and A14 (B9: a record with a call line folds with zeros, and a re-roll is byte-identical; A14 is the B7 state, which today folds to the zero shape), A19 (the sessions count of 22) and A21 (`delta` is not unrouted, because the unknown `named delta - 1` row already counts as a naming).
- **Vacuous on 69b51a61:** A25 passes because no `unknown, not zero:` line exists to print, and A40 and A44 pass because `felix_icloud_state` is missing (the A28 to A39 calls exit 127 and write nothing) and `felix status --tsv` does not yet read the home for copies, so neither shows that the new code writes nothing. They pin the new code only after the fix.

The 34 that failed: A1 to A3, A5, A8 to A11, A13, A15 to A18, A20, A22 to A24, A26 to A39, A41 to A43. A23 prints nothing because `felix_ledger_unknown` is missing; A28 to A39 return 127 for the same reason; A41 to A43 miss the `icloud` row.

## 9. Review round

The review of 942ca2db found three gaps. Each is restated here as required behaviour, and this section
wins where sections 2 to 6 differ. Its assertions are in
`engine/harness/tests/parts/1985-ledger-icloud-review-round-blind.sh`, the line after 1980 in `tests/run`.

**R1 (M1). A run that fails early never leaves a measured zero.** B1 fixes C101 only in part. The
alive line comes after both library sources, `$(cat)` and `$(felix_home)`, so a run that cannot load a
library or cannot fork leaves no trace. The record then reads complete, and the play folds as
`named superpowers:test-driven-development 0 1`, the register's own scenario. 942ca2db's title ("a dead
PostToolUse reads as unknown not zero") holds only once R1 does.
- When the payload names a session and FELIX_HOME names a directory whose `state/ledger` exists,
  post-tool appends its alive line before it sources any library and before its first fork (a command
  substitution, pipe, subshell or external command). Section 6's second bullet still covers a run
  Claude Code never starts and one killed before that append, but no longer the rest for post-tool.
- Each case: `P/stack.tsv` is B6's line. `felix_ledger_note_named H SID superpowers:test-driven-development`
  runs, then one real post-tool Bash run, then the failing run with
  `{"session_id":"SID","hook_event_name":"PostToolUse","tool_name":"Skill","tool_input":{"skill":"superpowers:test-driven-development"}}`,
  then the rollup. The fold holds a row whose NAME is the play, none of those rows has CALLS `0`, and
  `tool Bash 1 0` stays. A hook that records the call anyway, so that the play folds as reached, also
  meets R1.
- **R1 (control):** the Skill run from a whole copy of the harness (every entry but `tests/`).
- **R1a:** the same copy without `lib/ledger.sh`. **R1b:** the same copy without `lib/resolve.sh`.
- **R1c:** the real post-tool, exec'd under `ulimit -u 1` so it cannot fork, and waited for 60 s at
  most. It is skipped as root, or where a process held to one cannot exec a command. Its exit status
  and stderr are not asserted.
- Not asserted: a kill in the first half of a run, which no fixture can place.

**R2 (M2). An incomplete session is not a compliance session.** In an incomplete fold every unreached
row is `-`. B13 drops `-` rows one at a time, so only the followed rows are left, and the session reads
named = followed, ignored 0: `S2 2026-10-26 1 1 0` (100%), where the same session complete reads `2 1 1`.
- `felix_monitor_compliance` prints no line for a session that has any unknown row, whatever its known
  rows say. A complete session prints as today. The monitor's figure then covers complete sessions only.
  It never rises because a session's unreached rows were unknown. `felix ledger`'s unknown line (B14)
  still counts those sessions. The page gains no count (section 6 stands), and the JSON keeps its shape.
- B13 is amended. c1 holds only `plugin followed@x 4 2` and `plugin ign@x 0 3`, and A22 expects the same
  line. Part 1970's fixture is changed to match, and the mixed shape moves to R2a.
- **R2a:** rows by hand, all dated 2026-10-01. x1 has `skill superpowers:brainstorming 1 1` and
  `named code-review 0 1`. x2 is the same with `named code-review - 1`. x3 has `plugin followed@x 4 2`,
  `plugin ign@x 0 3` and `named unk - 2`. x4 has `named onlyunk - 1`. The output is exactly
  `x1	2026-10-01	2	1	1`.
- **R2b:** through the rollup, with an empty `stack.tsv`. S3's state is `named superpowers:brainstorming`,
  `named code-review`, alive, `skill superpowers:brainstorming`, alive, `tool Read`. S2's is S3's plus one
  alive line. S2's fold, `tool` rows aside, is `named code-review - 1` and
  `skill superpowers:brainstorming 1 1`. The compliance output is exactly `S3	2026-10-01	2	1	1`.

**R3 (M3). A lookup that failed is not a clear answer.** Take a home under `U/Documents`, with
`CD/Documents` linked there and `U/Library/Mobile Documents` at mode 000. It reads `value clear` and SN.
- SYNCED gains SX: `whether the home is inside an iCloud-synced folder is not known: the iCloud Drive folder could not be read`.
  SX holds when three things are true:
  - the home's physical path lies under that of `U/Documents` or `U/Desktop`;
  - `U/Library/Mobile Documents` exists;
  - rules 1 to 3 need an entry that cannot be read, because `U/Library/Mobile Documents` or CD cannot
    be searched.

  For such a home, a failed lookup is never SN. For a home under neither folder, SN and SX both meet
  this round.
- In B15's table SX takes SU's rows. N = 0 gives `unknown - C0; SX`, and N ≥ 1 gives
  `value copies-N CN; SX`. The status row follows (B16).
- **R3a:** the A29 layout with `U/Library/Mobile Documents` at mode 000 gives exactly
  `unknown<TAB>-<TAB>` C0 `; ` SX.
- **R3b:** the same with CD at mode 000 instead gives the R3a line.
- **R3c:** the A30 Desktop layout with `U/Library/Mobile Documents` at mode 000 gives the R3a line.
- **R3d:** R3a plus `state/x 2` gives
  `value<TAB>copies-1<TAB>1 name(s) shaped like an iCloud copy under state/ and .git (objects not read): state/x 2; ` SX.
- R3a to R3d are each skipped as root, and every mode is restored after its call.
- **R3e (control):** a home under `U/Documents`, and a readable `U/Library/Mobile Documents` holding
  no `com~apple~CloudDocs`, gives the A28 line.
- Not verified, and not asserted:
  - whether macOS privacy controls fail this lookup the same way for a process that may read
    Documents but not iCloud Drive;
  - whether the lookup raises a privacy prompt where `felix status` is polled.

**Red.** Run on 942ca2db plus part 1985 and the c1 change:
`alone.sh <worktree> bwk 1985-ledger-icloud-review-round-blind.sh` (bash 3.2.57, macOS awk). The run
prints 11 assertion lines (the other 62 `ok` lines are the driver's preamble). **9 failed and 2
passed**, and the 2 that passed are the controls, R1 and R3e.
- R1a to R1c each fold the play at 0 calls.
- R2a prints x2 (`1 1 0`) and x3 (`2 1 1`) beside x1, and R2b prints `S2	2026-10-01	1	1	0`.
- R3a to R3d read SN.

Part 1970 alone then passes all 27 of its assertions, A22 among them.
