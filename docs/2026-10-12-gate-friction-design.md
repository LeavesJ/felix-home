# Gate friction: from three whole-suite passes to five minutes

Row 0 of the carrier queue (~/.felix/memory/felix/audits/2026-10-08-carrier/state.md),
designed with the founder on 2026-10-12. Engineering design, not direction:
it changes how felix-home verifies its own engine, and nothing about what
Felix is or the order of the roadmap.

**Decided by the founder in this session.**
- **Target.** An engine change, once built, gets through record, red and gate
  in about five minutes on a quiet machine. That is all three steps below,
  including running the suite across cores.
- **Reuse.** A tree whose full suite already passed may be gated again without
  running it again. The gate says that it reused the run, and GitHub CI still
  runs everything before a merge.

**Constraints carried from the queue row.** Weaken no check. Anything that
skips work says what it skipped and why the change cannot reach it, or it is a
gate that cannot fail. Savings are claimed from CPU measured on a quiet
machine, never from wall time under load.

---

## 1. What a landing pays today

Measured 2026-10-10 on a quiet machine (audits/2026-10-10-gate-time): the
gate takes 1565 s, of which the suite is 1429 s (91%), `qualified` 125 s and
the other thirteen checks about 11 s. The suite is serial and fork-bound:
1298 s of CPU, 639 s of it system time.

An engine change pays for the suite three times:

1. **Record.** `tests/run --record-assertions` runs the whole suite to write
   `tests/assertions.tsv`, the list of assertions the suite must reach. In
   record mode three assertions skip (`_rtn1` to `_rtn3` in part 1010, which
   read the record about to be rewritten) and the end-of-suite comparison
   against the list is not made. Everything else is the same work the gate
   does.
2. **Red.** `tests/red`, which record mode calls after its own suite, runs
   this tree's suite again against the engine origin/main holds, to write
   `tests/red.tsv`: the assertions that fail without the change.
3. **Gate.** The gate's `tests` check runs the suite a third time.

All three come back whenever main's engine moves. Part 1010 asks that red.tsv
was recorded against the engine origin/main held where the branch left it
(`_rtn3`, which compares engine trees, so a docs-only or projects-only move of
main costs nothing). Every engine PR that lands moves it for every open one.

On 2026-10-12, at load 100 to 160 with six sessions' suites running at once,
each pass took about 45 minutes. A 60-line fix (#425) spent about two hours of
machine time after main moved under it.

## 2. What five minutes requires

The machine has 10 cores, 8 of them performance cores. Record and red are two
suites of about 1300 s of CPU each. Five minutes for both, at once, is about
2600 s of CPU in 300 s of wall: nine cores busy the whole time with no
duplicated work. That is not reachable by any one lever.

- **Pay once per tree (step 1)** removes the third suite and runs the other two
  at once. It does not shorten either.
- **Cutting the slow assertions (step 2)** lowers the 1300 s.
- **Running parts in parallel (step 3)** is the only lever that turns CPU into
  less wall. It needs every part to run alone, which today almost none do
  (section 5).

The gate's own overhead must also fit: `qualified` is 125 s alone today.

**Measured for this design, 2026-10-12** (scripts and results in
audits/2026-10-12-gate-friction/ under the memory root):
- Each of the 109 parts was run alone, eight at a time, on main 2fc0c671. Each
  run was the driver's prelude plus that one part, in a clone of its own whose
  origin points nowhere.
  - **40 parts** reach their end with no FAIL.
  - **21 parts** reach their end with failures: 526 FAIL lines between them.
  - **48 parts** die before their end: 36 on a variable an earlier part sets,
    12 on a function an earlier part defines.
- A static count agrees: 106 of 109 parts use a name an earlier part defines.
- Per-part CPU and wall, from one instrumented serial run on the same commit
  at load 40 to 120 and nice 10 (parttime.tsv in the audit folder): 2035 s
  wall, 1710 s CPU. One part is a quarter of it: 0580, "tidying, with the
  checks that make it safe", 405 s of CPU. After it come 0700 (94 s), 0920
  (49 s of CPU in 140 s of wall), 0440 (42 s) and 0010 (39 s). No other part
  takes more than 32 s.
- That run also printed nine FAILs with exit status 126 in parts 0430 and
  0710, which pass on main's own gate. 126 is a command that could not be
  executed, as a script being written while it is started gives. These are
  read as a race under load and are owed a look in step 2. A tenth FAIL, in
  part 1040 ("the driver itself is under 500 lines"), was the
  instrumentation's own: it added 110 lines to the driver.

## 3. Step 1: pay once per tree

No restructure of the suite. Three changes.

### 1a. Record and red run at once

`tests/run --record-assertions` starts `tests/red` at its own start rather than
after its suite. Red's suite runs against the base engine and does not need the
new manifest until its comparison, which comes after its own suite ends.

- Red is told where the record run will write the manifest, and that run writes
  a completion mark beside it with its own exit status. Red waits for the mark
  after its suite ends, then reads the manifest once, as it reads it today.
- If the record run stops, fails before writing, or writes a manifest that is
  not one, red writes the two retraction rows and exits 2, as it does today for
  a manifest it cannot read.
- `tests/red` run by hand, with a manifest already in the tree, behaves as
  today.

Saving: one suite's wall time per record. CPU is unchanged.

### 1b. A passed suite leaves a receipt, and the gate reuses it

A suite run that reached its end writes a receipt to the checkout's git
directory (`git rev-parse --git-path felix-suite`), outside the tree, so
writing it changes no tree id. One receipt per checkout, overwritten.

The receipt holds:
- the tree id (`felix_tree_id`) of the tree the run leaves behind, which for a
  record run includes the record files it wrote (why that is sound is below);
- the mode (normal or record), the counts of ok, FAIL and skip lines, and the
  ran counts the suite produced (the file the manifest is written from);
- what the run cannot see from the tree: the host, the bash version, whether a
  `claude` CLI was on PATH (it turns some assertions into skips), and when the
  run started and ended.

The gate's `tests` check reads it first. It reuses the run when all of these
hold, and otherwise runs the suite as today:
- the receipt's tree id equals the current tree's, computed the same way;
- no FAIL line, and the run reached its end;
- the host, bash version and `claude` presence match;
- it is less than 12 hours old, so a change outside the tree (a tool upgraded,
  a plugin removed) cannot ride on it for long.

What a record run skipped is made up before it writes its receipt, on the
tree it leaves behind:
- **The real-record checks.** After red has finished and the manifest is
  written, the record run judges its own checkout's record once more, as a
  normal run does (`_rt_judge`, part 1010, with record mode off), so `_rtn1`
  to `_rtn3` are asked of the files it just wrote. The judge stays where seven
  reviews put it. One assertion that counts its calls is restated.
- **The manifest comparison** is made after that, against the manifest just
  written, as a normal run makes it.

So the receipt is keyed to the full tree as the record run leaves it, record
files included, and says that tree passed everything a normal run asks.
`--record-assertions` now exits 1 when the record it wrote fails that judge,
as a red run that could not be made does. That is what the gate would say of
the same tree, so it is said at the record rather than discovered at the gate.

What the gate prints when it reuses:

```
  tests              ok (reused the suite run of 14:02 on this tree: 7520 passed, 5 skipped)
```

and the gate receipt's reported field reads `tests:reused`, not `tests:ok`, so
`felix merge`, the monitor and qualify can tell the two apart.

**Why the record files may change under the run.** A record run's parts run
while red.tsv holds red's retraction and the manifest holds the old list, and
the receipt names the tree after both are rewritten. That is sound only if no
assertion but the re-judged ones reads those two files' content. Every other
mention of red.tsv or assertions.tsv in the suite reads a fixture (checked
2026-10-12: parts 0440, 0720, 0730, 0740, 0990 and 1000). The run checks the
rest of the tree did not move: its tree id with the two record files left out
is taken at its start and again before the receipt, and a difference writes no
receipt. The build shows the claim with a differential: the suite run twice on
one tree with two different valid record files gives the same verdict on every
name.

**What reuse cannot catch, said plainly.** The receipt is a file a session can
write. So is the gate receipt `felix merge` already trusts, and the hold-once
record #426 added (its forging finding has no slot yet). Reuse adds no new
kind of trust. GitHub CI runs the full gate on Linux before any merge, and
nothing here changes that.

### 1c. One order for every change, merges included

With 1a and 1b a record run costs one suite, the same as a plain run, and the
gate reuses it. So there is one order after any change, a main merge
included: `tests/run --record-assertions` (the suite and red at once), then
the gate. The manifest the record writes after a merge is git's union of both
sides (the `keyed-union` row in land.tsv) unless main renamed or removed an
assertion, and then the record corrects it.

About 28 minutes on a quiet machine, from 78: one suite's wall time, then
`qualified` and the other checks.

## 4. Step 2: the slow assertions

4% of assertions take 60% of the suite. Each is made cheaper without changing
what it asserts, and each change is shown with the assertion's own verdict on
the old and new code. First, from the 2026-10-12 per-part table: part 0580,
tidying, 405 s of the suite's 1710 s of CPU. Then, named on 2026-10-10:
- three signal tests in the inventory block that wait 30 s each, about 90 s of
  wall and no CPU: wait on the event, with the same bound;
- the inventory blind contract, 177 s;
- commissioning, 111 s, 799 assertions;
- `qualified`, 125 s in the gate: its rows already run each in a shell and
  scratch tree of their own (0cq), so they run in parallel.

The per-part table from the timing run (section 2) decides the final list.

## 5. Step 3: every part runs alone, then in parallel

### 3a. A part runs alone

The property: run with only the driver's prelude before it (the helpers and
the fixture every part shares), a part gives the same verdict on every name as
it does in the serial run. Today it holds for at most 40 of 109 parts
(section 2). The 40 are confirmed against the serial run's names per part
before any is counted as done.

The restructure, part by part:
- a helper defined in one part and used in a later one moves into
  `tests/lib/`, which the prelude sources. Two parts that define one name
  differently get two names;
- a fixture a part needs (a commit in `$REPO`, a file in `$FROOT`) is built by
  that part, or by a named fixture function in `tests/lib/`, never inherited
  from whatever ran before it.

This also ends the hazard behind the 2026-10-08 remote rewrite: a block run
without the definitions it silently needed, whose fixture roots came back
empty.

### 3b. The parallel runner

`tests/run -j N` runs each part in its own bash process: the prelude, then that
part, with its output to a file of its own. A pool of N processes takes parts
longest first, by the durations the last receipt recorded.

- **One log, in order.** The driver prints each part's output in part order as
  soon as every part before it is done, so the log reads as a serial log does
  and `tests/red` parses it unchanged.
- **Counts from lines.** PASS, FAIL and SKIP are summed from the ok, FAIL and
  skip lines, which is what `tests/red` already counts, since a part's
  variables no longer reach the driver.
- **A part that dies is loud.** Each part process ends by printing a mark of
  its own. A part with no mark prints `FAIL  part did not finish: <name>`, and
  its unreached names fail the manifest comparison. `reached` is printed only
  after every part process has exited.
- **`-j 1` is today's run**, one shell with the parts sourced in order, and it
  stays what CI runs. A part that passes alone and fails in order, or the
  reverse, shows as a local gate and CI that disagree, and nothing merges
  without both.
- **Machine-wide slots.** Every part process takes one of `ncpu` slots under
  `$TMPDIR` before it starts and gives it back when it exits, so six sessions'
  suites share the cores rather than each running a full suite at once. A part
  that waited says how long.

`tests/red` runs this tree's driver against the base, so it inherits `-j`.
The gate runs `tests/run -j` with N from the machine.

### 3c. What step 3 will not do

It does not change CI. The Linux runner runs `-j 1`, so the Actions minutes do
not move. Running CI with `-j` is a later decision, once local and CI have
agreed for long enough to trust it.

## 6. How each part is shown failing

Invariant 5: nothing here is believed until it is shown failing.
- **Reuse.** A changed tree, a FAIL in the receipt, an unfinished run, another
  host, another bash, `claude` added or removed, a receipt 12 hours old, and a
  receipt that is not a file each make the gate run the suite. A record run
  whose re-judged record fails, or whose tree moved outside the record files
  while it ran, writes no receipt.
- **1a.** A record run stopped part way, failing, or writing a malformed
  manifest each leave red's retraction rows and exit 2.
- **3b.** A part killed mid-run, a part that exits before its mark, and a part
  whose output holds a stray `reached` each fail the run.
- **3a.** For each restructured part, its names' verdicts alone equal its
  verdicts in the serial run, and on the old engine its red names are the same.

## 7. Build order

Each step is one pull request, built through the engine pipeline (spec, blind
assertions from the spec, implementation shown red first, Opus adversarial
review, gate). Engine tier: `tests/run`, `tests/red` and the gate decide what
counts as verified. Step 1 lands first, so steps 2 and 3 already pay one suite
instead of three.

| PR | what | lands after |
|---|---|---|
| A | step 1: 1a and 1b | - |
| B | step 2: the slow assertions, `qualified` rows in parallel | A |
| C | step 3a: every part runs alone (tests only, large) | A |
| D | step 3b: `-j`, slots, red with `-j` | C |

**Measured after each.** Gate CPU and wall on a quiet machine, with the
2026-10-10 scripts, against 1565 s and 1298 s.

**Not in this design.** CI with `-j`. A cache of suite results across trees.
Skipping parts a diff cannot reach: once a part runs in seconds there is no
need to argue which parts a change can reach.
