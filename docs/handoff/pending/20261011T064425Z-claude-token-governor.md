### 2026-10-11: felix cost reads what a week of Claude Code cost, as input-equivalent tokens against the weekly cap (slot 2a, part A)

Branch claude/token-governor, cut from main b9929fe9, with main 9f614a5b (#424)
merged in. Slot 2a of the carrier
queue (audits/2026-10-08-carrier/state.md in the memory root), part A of the
brief in audits/2026-10-09-token-burn/BRIEF.md. Engine only: lib/cost.sh, the
dispatch and help line in felix, and three parts of the suite
(tests/parts/1050 to 1070, the block cut where each parses alone). No table under
projects/, no escape.

**What it does.** `felix cost [--week | --since D] [--by worktree|day|model]
[--top N] [--tsv]` reads the transcripts Claude Code keeps and prints the
input-equivalent tokens spent (input 1, cache write 1.25 or 2, cache read 0.1,
output 5) in the plan week, which opens Thursday 13:00Z, as a share of a 905M
cap (`FELIX_COST_CAP_M`). It breaks the total down by record directory, day and
model. It is a proxy for plan usage and says so. Read-only by construction,
dispatched before a home is resolved like audit and inventory. `--tsv` prints
cover rows (window, source, cap, files read and unread, responses unread,
coverage, as-of) and data rows, the shape the 2026-10-09 interface section asks
reports to take. No root, or a root with no transcript, reads unknown, never 0.
An unread file, directory or response makes the total a floor, and a floor of
nothing reads unknown.

**Measured against the oracle.** On a frozen copy of the week's 626
transcripts (1.2 GB), its totals equal the brief's Python oracle (burn.py)
exactly: 570,845,516.55 tokens over 16,694 responses. Per worktree (56), day
(4) and model (5), nothing differs. That is 63.1% of the cap at 2026-10-11T06:00Z.
A week reads in about 13 s on macOS. A month (`--since 2026-09-10`) takes
about 100 s, nearly all of it BSD grep.

**What the brief did not know.** A workflow's agents write their transcripts
two levels below `<sid>/subagents/`, in `workflows/<run>/`. That held 222 of
the week's 626 files and 152M of its 570M tokens. The first draft read only the
two shapes the brief named and reported 417M. Every `*.jsonl` under
`subagents/` is read now.

**How it was built.** Contract first, then three checks:
- **Blind assertions.** A blind author wrote 282 assertions from the contract
  alone in its own worktree; all 282 were red on origin/main. Against the first
  implementation 23 failed. Three defects were real:
  - attachment and progress records that nest an assistant message were
    counted;
  - the prune read a file modified a minute before the window;
  - "unknown:" was glued to its word.

  Six assertions were restated, not blind, to the amended read set, and are
  marked in place. The other two failures were the blind author's own reading
  that `--since` has no end, which stands as the contract.
- **Adversarial review.** An Opus review of the first implementation found one
  blocker and two majors, each reproduced:
  - a records root that is a symbolic link read as a measured 0;
  - a tool input holding an object-valued `usage` was weighed in place of the
    response's;
  - a tool input quoting a uuid and timestamp could set the response's time.

  It also found six minors, all fixed but the `--since` end: the largest
  usage across files now wins (a workflow's partial copy cost 13,175 tokens
  once in 21 days); a progress record whose own type follows its nested
  message is no longer counted; POSIXLY_CORRECT no longer breaks the run;
  untimed responses get a row; and the "any transcript" probe agrees with the
  walk. A line with two usage objects, or a usage after wireToolInputs, is now
  counted as unread rather than guessed. A response's own type and time are
  the last uuid/timestamp triple in its line, which the review checked on all
  432,371 real assistant lines.
- **Second blind round.** The ten-item addendum the review produced went back
  to a blind author, who wrote 152 assertions, 97 of them red on the
  pre-review commit d05ab829. Against the fixed code one failed, and it was a
  real defect: across files the comparison ran line by line, so a file whose
  smaller last line followed a larger one beat another file's final usage.
  Each file's last line is now settled when the file ends, then the largest
  across files wins. The block passes 434 of 434.
- **Mutation.** Nine mutants were run, and all nine are caught (100, 32, 27,
  11, 8, 5, 4, 3 and 3 reds). The ninth, largest across files, survived the
  first block and was caught only once the second round covered it.
- **Version.** 0.49.278. It was 0.49.277, pipelined on #421, until #424 took
  0.49.277 and carried #421's commits. Main was merged in, and the block moved
  into parts unchanged, byte for byte.
- **Record.** 7306 assertions, the suite 7298 passed, 0 failed and 8 skipped.
  425 of them are red against main 9f614a5 at engine 0.49.277.

**Not done here, and next in slot 2a.**
- **B.** The Stop hook holds once per (session, tree id), and afterwards
  records the unrun gate as a debt. This session met the case it fixes: it was
  held on a work-in-progress tree whose gate was known not to have run.
- **C.** Chips stay frozen by the deny row in ~/.claude/settings.json until the
  founder lifts it.
- Re-run the oracle after B lands, as the brief asks.
