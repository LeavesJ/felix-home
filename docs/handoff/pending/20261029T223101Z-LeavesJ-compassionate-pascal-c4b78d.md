### 2026-10-29: the pipe lint reads every project script, and Felix's cloud check looks its entries up in a here-string

**What failed.** At about 22:00Z, at load near 190, `felix gate` on
`claude/lane-situations-owed` @ 3306d4e2 printed `cloud FAIL` with
"code-review has no entry in .claude/cloud/toolbox.json". The entry is there
(`"carry": "builtin"`), and the same extraction run by hand found it 400 times
in 400. The cloud check #385 wrote into `projects/felix/gate.sh` (2026-10-02)
looked up each hook pair and each stack name with
`printf '%s\n' "$VAR" | grep -qxF "$x"` under the gate's `set -uo pipefail`.
That is #376's class: grep matches and exits, printf's next write takes
SIGPIPE, and pipefail reads the match as a miss. #381 had converted the
project scripts by hand a week earlier, and no lint read `projects/`.

**What changed (this branch, `LeavesJ/compassionate-pascal-c4b78d`).**
- Part 0960 runs `_spl_scan` a second time, over every file git tracks under
  `projects/` that starts with `#!` (part 0790's definition of a project
  script; all eleven set pipefail). It fails when git lists none. New name:
  "no project script pipes into a grep that can stop reading early". Before
  the fix it named `projects/felix/gate.sh:625` and `:638` and nothing else.
- Both lookups read `grep -qxF "$x" <<<"$VAR"`, with the same input, flags and
  pattern.

**Shown red.** The cloud block lifted from origin/main's gate.sh and from
this tree, 10 runs per row, haystacks past 64 KB (S_PAIRS 320,022 bytes,
TOOLBOX 180,013), each fixture padding only the site under test:

| row | before | after |
|---|---|---|
| pair sorted first of 20,002 | 0/10 | 10/10 |
| pair sorted last (control) | 10/10 | 10/10 |
| pair that settings never names | 0/10 | 0/10 |
| stack name first of 20,002 | 0/10 | 10/10 |
| stack name last (control) | 10/10 | 10/10 |
| stack name the toolbox never lists | 0/10 | 0/10 |

The scan's own refusals were checked in fixtures: no `projects/`, a tree that
is no repository and an untracked script each fail with the reason named; a
tracked script with the shape is named by line; a tracked non-script is not
read.

**Binds after landing.** `felix gate` runs the home's `projects/felix/gate.sh`,
so this branch's own gate still runs the old cloud check, and the fix starts
when main reaches the home. The lint runs from the branch's suite.

**Still outside the lint, unchanged from #376's list.** `head`, `sed q`,
`awk` that exits, and `tar -x` at the end of a pipeline whose status is read,
and a grep inside a brace group or subshell fed by a pipe. The rest of
`projects/felix/gate.sh` was read for these by hand: its `head -N` and
`sed | head -1` sites print or assign, and none has its status read.
