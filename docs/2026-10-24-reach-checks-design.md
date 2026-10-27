> **felix-home was public until 2026-10-24.** GitHub reported `LeavesJ/felix-home` as public from its creation on 2026-08-09 (0 forks, 0 stars). The founder had it made private on 2026-10-24, so the CI figures below hold: 2-core runners and a binding minutes quota.

# Checks chosen by reach, essentials derived by breaking them

**Decided by the founder, 2026-10-24:** plan A is approved, to be built in section 5's order, report-only first. The off-Mac channel is a GitHub issue, and the land job may post one comment per new event on that one issue and nothing else on GitHub. felix-home was made private the same day, so the CI figures' private-repository assumption holds.

Paths are relative to the worktree. `eh/` is `engine/harness/`, and a bare four-digit number is `eh/tests/parts/<n>-*.sh`. "contract", "design" and "direction" are `docs/2026-10-15-land-on-green-contract.md`, `docs/2026-10-12-gate-friction-design.md` and `docs/direction.md`. "spec" and "amend" are v3.2 and its amendments.

## 1. What changes for the founder

**Size stops mattering.** Every change gets four answers, each measured:
1. **Reach.** Which tests run the code it touches, read from recorded runs.
2. **Essentials.** Whether the essential tests pass. These are the tests that notice when a guard is broken on purpose in a scratch copy. For Felix, a guard is a deny row, land condition, receipt check or hook hold; for your users, a rate limiter, auth, a retry or a fallback. Essential tests run on every change.
3. **New code.** New code no test runs is named, and on the riskiest paths must gain a test.
4. **Visibility.** Whether the reach can be seen at all. If not, everything runs, as today.

A one-line edit to a helper every command calls runs nearly everything; a new command runs its own tests plus the essentials. A guard no test notices is named, because no amount of running tests vouches for it: that answers "do auth and rate limits still work?"

**First, nothing stalls silently.** Every wait gets a deadline, notices reach you off the Mac, and the land job gets a heartbeat (steps 1-4).

**Your decisions:**
- **A.** Local checks run only what a change reaches. CI still runs everything on every PR, so your 10-12 rule holds (design:12-14). The home checkout does not advance until the whole suite passes on main on both Mac and Linux. One gap stays open: today a worktree's own `felix install` can make its branch's engine live in the plugin cache before any of that (gate.sh:240-245), so until that is closed, release green holds back only the home, not every session.
- **B.** CI also runs only what a change reaches, and the whole suite runs on main after merges. This reverses design:12-14, and comes only if measurement shows CI still sets the pace or minutes still run out.

**Estimated times, one engine change on this Mac (8 performance cores):**

| | today | after A | after B |
|---|---|---|---|
| record, red, gate | 35-40 min (71 loaded) | 5-15 min | 5-15 min |
| CI on the PR | 34-39 min serial | 34-39 min | 5-15 min |
| last commit to merged | 75-90 min | 45-60 min | 15-35 min |
| re-cycle after an engine landing | ~75 min | ~40 min | 10-20 min |
| landed to deployed | 6-7 min | 20-45 min | 20-45 min |

The "today" column is measured (the verification sweep, #456's CI logs). The rest rests on three unmeasured numbers:
- **Typical reach.** It is small only with a function-level map: 114 of 193 parts drive the CLI, which loads about 55 files at start (eh/felix:269-370).
- **CI's cores.** The log records none, and gate friction D missed its CPU bound, so `-j` may not help in CI.
- **Test cost.** The 8341 s durations total is 8 slots times 1048 s. It measures contention, not CPU.

A 4-core laptop roughly doubles local times.

Engine PRs share one version line (engine/.claude-plugin/plugin.json:4), so cycles get cheaper, not fewer; roadmap step 11 cuts their number (direction:223).

Deploy waits for the release run. PRs keep landing meanwhile unless what landed changed the engine or the project's tables; then they wait, as they wait for a deploy today.

## 2. The mechanism

### 2a. The map

A **unit** is what `-j` runs as one process: a part, or a group in groups.tsv (0001:15-20). `-j 1` sources every part (eh/tests/run:226 on), so selection needs `-j` of 2 or more.

**Recorded** per unit, per platform, at main commit M: the functions entered, the files whose top level ran, the files opened (Linux only), the assertion names reached (0007:833), the verdict, CPU time, and bash processes started against processes traced.

**How it is traced.** The tracer is loaded through `BASH_ENV` (eh/felix:120-124) and exported only into units (0007:749-751).
- **Linux, bash 5:** xtrace writes to `BASH_XTRACEFD` on a descriptor above 9 and not 63 (0007:284-291, 0007:801). `strace -f -e trace=openat,execve` runs alongside, because xtrace never shows a redirected read such as `done < "$proj/deny.tsv"` (eh/lib/deny.sh:59).
- **macOS, bash 3.2:** it has no `BASH_XTRACEFD`, and assertions capture `2>&1`, so a `DEBUG` trap under functrace writes a file per process.

`bash -c` table code (probes.sh:177, obligations.sh:151, qualify-run.sh:414) is charged to its table. A unit with an untraced child always runs: `BASH_ENV` is cleared at qualify-run.sh:408,413 and commission.sh:352,399, and 14 parts use `env -i`.

**Where it lives.** `$(git rev-parse --git-common-dir)/felix-testmap/<platform>/<M>`: shared by worktrees, outside every tree and the memory backup.

**Refresh (Felix's call).** macOS traces each main commit that passed release, newest first, in idle slots. Linux runs a `testmap` job that reuse cannot skip (gate.yml:61-65), at a cadence set once its minutes are measured.

**Everything runs when:**
- there is no map, M is not an ancestor of the base, or M is 14 days old;
- the change touches code outside units: tests/run, red, receipt.sh, 0001-0009, 0007, 9990, groups.tsv, the tracer, the selector or `.github/` (units skip receipt.sh and `_par_run`, tests/run:133-135, 223);
- a hunk adds a computed call: `eval`, `bash -c`, `source "$x"`, a variable used as a command, a trap string, `declare -f`, `export -f` or `compgen -A function` (`_pm_snap` at 0007:304 is exempt);
- a changed tracked file has no reader in any map;
- the selection reaches 70% of unit time.

Diffing against M, not the base, means an old map selects more, never less.

### 2b. Selection

Main's installed engine selects, never the branch (amend §2.3). felix merge already runs from the cache (contract:132-136), so it recomputes the selection and refuses a receipt or CI notice covering less.

**What is selected:**
- units that entered a function whose body differs between M and the tree; a name defined twice maps by file;
- units that ran a changed file's top level;
- units that opened a changed data file. With no Linux map, a data change runs everything except the record files, read only by 1010 (receipt.sh:312-316);
- new or changed parts;
- the essential set;
- units whose traces are incomplete or unfaithful;
- units touching a file that branches on platform.

**Per-unit results.** A pass at T0 stands at T if nothing the unit reached differs among M, T0 and T, the environment matches (receipt.sh:115-127), and it is under 12 h old (receipt.sh:256). Keyed by content in the common dir, results let worktrees reuse main's release run, and after a merge from main only units whose reach moved rerun (row 21, direction:166; spec:259). This is a new eh/tests/select.sh; receipt.sh is at 499 lines.

**Red and the manifest.** Red runs only new or edited units against the base (eh/tests/red:15-23), and records a `scope` row within red.tsv's four columns (eh/templates/schemas.tsv:137). `_rtn1`, which counts the whole manifest (1010:13, 30-40), accepts a scoped run. The manifest is compared for selected units only; the map carries unit-to-name, so no new column (schemas.tsv:141). No selective run prints "every assertion in the manifest was reached" (tests/run:478-480).

### 2c. Essentials, by breaking guards

A **guard** is a line emitting a refusal an engine reader acts on, with its condition. Guards appear in:
- the merge blockers (escape.sh:605-784);
- `_gt_candidate`'s `why=` (green-tick.sh:353-366);
- `_sr_check` (receipt.sh:202-258);
- the stale verdicts (verify.sh:578-635);
- gate `fail` calls;
- hook denies and holds;
- deny.tsv rows.

**Mutants** delete the refusal, invert it, return allow early, or drop the row.
- Operators are written blind: amend §2.2 asks for an author who has not seen the tests, and a model qualifies.
- Mutants failing `bash -n` are dropped, and an irrelevant edit (amend control 3) drops units that fail on any edit.
- They run in idle slots, in a scratch worktree of main, against units mapped to the site.

**What comes out:**
- **The essential set:** for each guard, the two cheapest units that notice it, so that one flaky or weakened unit cannot leave it bare.
- **Unguarded essentials:** guards no unit notices, each shown with its mutant (an equivalent mutant looks the same), notified and listed in `felix status` and `felix next`.
- **Recall:** a tenth of mutants also run units outside the mapped reach; one that notices marks its file unknown.

A PR editing an essential unit reruns its mutants first: a deterministic LOCAL_MEASUREMENT (spec:428) that only adds units, and the discrimination evidence amend §2.4 requires.

**User projects.** `projects/<p>/testmap.tsv` names list, run and record commands over coverage.py contexts, V8 coverage or `go test -coverprofile`. Guards are rate limits, auth decorators, retry, timeout and fallback wrappers, and 401 and 429 returns. Models may propose sites, never decide (candidates.sh:18-21, 104-106). The output is "of M guards, R unguarded", the denominator for I1. The table joins `FELIX_ESCAPE_EXEMPTION_TABLES` (escape.sh:112), and a project without a row gets the whole gate. It starts report-only, on Elenchus and one npm project (direction:114-115).

### 2d. New and untested

The first traced run over a PR names the added or changed lines that no selected unit executed, in the receipt and the PR; until then the receipt says "not yet known", never zero. They are not routed to the whole suite, which would run them no more. On red-tier paths (projects/felix/risk.tsv:25-38), the light path refuses until a test runs them. It is reported, then shadowed (direction:294-298), then armed.

### 2e. Release run and culprit

**R_mac.** A full, untraced `-jN` run at the newest main commit, in its own main worktree, never in the home, under `caffeinate -i -w`, ended by pid.

**R_linux.** Under A, the PR's run counts when reuse-verified-tree.sh proves the landed tree is the gated one (reuse-verified-tree.sh:20-30); otherwise main's push run counts. Under B, reuse refuses selective runs.

**CI changes.** Main stops cancelling in-progress runs (gate.yml:24-26). The serial run, the only place parts share a shell (design:243-246), stays in CI under A and moves to idle local slots under B.

**Release green.** Both runs pass on commit C. The home advances only to such a commit, and G7.4 verifies that commit, not `gate --quick` (green-tick.sh:269).

**Culprit.** The suspects are landings since the last release-green commit that the map says reach the failing units F. Each is confirmed by running F at the suspect and its parent from local history, since listing runs needs `actions:read`, which only the reuse job holds (gate.yml:38-42). If the map names none, the miss is recorded and F is bisected. Red at the suspect and green at its parent convicts; anything else is a flake. A notified `main-red` row names the culprit, F and the evidence.

**H1 (new).** While main is red on F, the tick lands only a PR whose CI on current main passed all of F: a revert or a fix. After 2 h a notified `stuck` row is written; the tick never pushes (contract:143-144), so the author session and founder are told.

**Bounds.**
- Each unit gets max(5× its last duration, 900 s); the holder has none (0007:112-118).
- The record's wait for red gets one; tests/run:438 passes none to receipt.sh:486-494.
- The gate prints its log path first, then a heartbeat; gate.sh:322 is silent until it ends.
- CI gets `timeout-minutes`, and a notified row fires after N commits or T hours with no release verdict.

## 3. What green means, and what changes

**Today:**
- A local green means the whole suite passed on this tree, or did in the same environment within 12 h (receipt.sh:202-258).
- The tick also needs CI's full run on the head merged into its base (green-tick.sh:362).
- `--quick` clears felix merge with no suite at all, because C9 asks only about `tests:reused` (gate.sh:317-318; escape.sh:659-669; 0100:93).
- Deploy follows within a tick on `gate --quick` alone (green-tick.sh:269, 431-438), so a PR that was behind main goes live without any full run.

**Proposed: v3.2's two verdicts.**
- **Task green decides merge.** Every selected unit passed on this exact tree, here or as a standing result. The receipt names the maps, the selection hash with each unit's reason, the essential set, the untested lines, and whether everything ran. CI must also pass on the exact head: everything under A, the selection under B.
- **Release green decides deploy.** The whole suite passed on that main commit, on both platforms. No exception clears it; exceptions clear only task-blocking rows (amendments item 4; obligations.sh:243-252).

This is invariant 6, receipt-driven release (spec:20). A receipt proves only its claim (spec:456).

**Rules touched.**
- **Waits on A:**
  - **The suite receipt (receipt.sh:28).** v2 adds `selected`, the maps and the hash. `_sr_check` accepts only v1's nine fields (receipt.sh:212-223).
  - **G3/A2 (green-tick.sh:204-218, 431).** Merges continue while the home lags, but only outside `engine/` and `projects/<p>/`.
  - **G7.3/G7.4 (green-tick.sh:250, 269).** The deploy pulls and verifies the release-green commit.
- **Waits on B:**
  - **Row 24 (direction:169).** CI green comes to mean the selection.
- **Waits on nothing:**
  - **The gate receipt.** Field 6 records `tests:selected` (eh/felix:1113).
  - **C9.** It covers `tests:selected`, `tests:skipped` is refused (direction:210-216), and 0100:93 flips.
  - **G7.1/A14 (green-tick.sh:231).** It matches only the home's or the cache's engine.
  - **A13 (green-tick.sh:375).** A refusal blocked only by the receipt is retried.
  - **H1, plus an overlap check** for PRs behind main. Both are new, and report-only first (land-table.sh:48-53).
- **Waits on the channel:** A6/A10/G8 (green-tick.sh:52, 56) notify the new rows off the Mac.
- **Unchanged:** the Stop hook (verify.sh:578-635).

**The founder's:**
1. A, then B, each by a direction PR.
2. Placement in §5 (direction:488-492).
3. Hand merges. 0007, red, receipt.sh and groups.tsv fire the verifier on any change (risk.tsv:43-45). tests/run fires it only when an assertion line goes (risk.tsv:42). Workflows are the execute channel (escape.sh:116).
4. A re-stamp. New verifier rows are free to add (escape.sh:384-392), but risk.tsv is a commission table (commission.sh:52), so they are batched.
5. The notifier. You chose the GitHub app on 2026-10-24. That makes one comment on one standing issue a new write the tick may do, which G6 forbade (contract:143-144); his yes of 2026-10-24 widens G6 for exactly that. Comments carry enumerated text only, never a ledger row's free text.
6. Holds from unguarded essentials stay within row 27's bounds (direction:172).

**Felix's calls:** the backends, the map's place and refresh, the 14-day and 70% bounds, the two-unit cover, the 10% sample, the deadlines, H1, selection by main, per-unit results, the red scope row, and the name `testmap` (eh/lib/reach.sh means tool reach).

## 4. Measured before anything is claimed

1. **Tracer.** Verdicts and wall time, traced against untraced, on both platforms, with completeness counts.
2. **Reach.** Units per function, and the selected share of the last 60 merged PRs replayed at their merge bases.
3. **History.** Whether each past red run's failing units would have been selected.
4. **Fault injection,** needing no tracer, so it runs on macOS: sampled functions exit 97 and units outside their reach run; misses are reported out of n with the rule-of-three bound.
5. **Shadow,** for the longer of 30 PRs or two weeks; arming requires zero misses.
6. **CI.** `nproc`, `-j` against serial, and minutes per merged PR.
7. **Local.** Walls at `FELIX_TEST_SLOTS` 8, 4 and 2, plus getrusage CPU (design:16-19).
8. **Essentials.** Guards found and unguarded, the cover's cost, and drops from the irrelevant control.
9. **Release.** Latency, and how long merges waited.
10. **Bounds.** Each fires on a seeded hang.

## 5. Build order

Each step is one PR and is useful alone. No step starts while more than 10 engine PRs are open (direction:162).

1. **Trust item 2.** Refuse `tests:skipped`, and run C9 on `tests:ok` session merges. Both only tighten (direction:215-216). Lands on green.
2. **Bounds,** in one hand-merge sitting (0007, receipt.sh, gate.yml): limits, the heartbeat, `timeout-minutes`, and an uncancelled main. 1010's judge also runs as a gate pre-step.
3. **Tick signals,** on green: aged waits, a lander heartbeat, A14 narrowed, the A13 retry, `caffeinate`, and recorded sleep.
4. **Notifier,** once he picks the channel.
5. **Runner facts,** by hand merge with the re-stamp: per-unit verdict, CPU and id.
6. **Tracer and maps,** report-only.
7. **Shadow selection.** A selective run takes the Mac-wide suite slots that `-j` units hold (`$TMPDIR/felix-suite-slots`). `--part` takes none today, and on 2026-10-25 about thirty part runs at once put the load at 351 on 10 cores.
8. **Mutation sweep,** report-only; it finds omissions alone.
9. **Release run,** in shadow.
10. **Arm A** (his yes).
11. **CI at `-j`,** if measurement 6 shows a gain.
12. **Arm B** (his yes), only if CI time or minutes still bind.
13. **New-and-untested:** report, then shadow, then armed.
14. **Product adapters,** report-only.

## 6. Ways it can be wrong

- **macOS-only paths** (sysctl, skipped under Actions at gate.sh:302-314; scutil, receipt.sh:130; `has_claude`). Caught by the macOS map, the platform rule, and R_mac before deploy.
- **Inputs outside the tree** (receipt.sh:48-60). Caught by the environment fields, the 12 h limit, and R_mac.
- **Order dependence.** Caught by the serial run.
- **`eval` (0007:802), the `.` alias (tests/run:225).** Caught by the computed-call rule and recall.
- **A weakened selector or essential test.** Caught because main selects and merge recomputes, the verifier rows, the two-unit cover, mutant rechecks and the count confine (risk.tsv:42).
- **A blamed flake.** Conviction needs red at the suspect and green at its parent.
- **No release verdict.** Deploy is held, safely, and the hold is notified with its age.
- **A broken felix merge on main.** It needs the founder, as today, but is no longer already deployed.
- **A worktree `felix install` makes a branch engine live (gate.sh:240-245).** Not closed.
- **A regression everything misses.** Main is red for one batch; nothing deploys.

## 7. Left to the builder

- The tracer formats.
- A function-extent parser for bash 3.2 and BWK awk.
- A unit id that 0001 does not unset (0001:129-130).
- Mapping fixture paths back to source (0004:106).
- Map format, retention and the result key.
- At most three new lines in tests/run (497).
- Guard patterns, operators, budgets and slot priority.
- What else felix merge reads from a lagging home.
- Later, judge staging without `claude plugin update` (eh/felix:629-630), leaving the deployed-engine probe alone; the carrier owns the cache (direction:162).
## 8. Calls made after the builder check

A fresh reader asked what a builder would still need. Its questions that the project already answers are folded in above. The rest are Felix's calls, recorded here:

- **Judge staging moves before step 10.** Main's engine is placed in the cache as felix merge's judge without `claude plugin update` (eh/felix:629-630), so the judge stays main's engine while sessions keep the release-green one. Until a worktree install stops making a branch engine live, section 1 says release green holds back only the home.
- **A red that local history cannot reproduce is "unconvicted", never "flake".** It keeps main red on the failing units, holds deploy and is notified. A later push's green Linux run clears it. Letting the tick re-run CI would be a new GitHub write, so it is the founder's decision and is not assumed.
- **Mutation operators are written once per guard class, by a blind author in an attended session, and stored as data.** The sweep only applies them, in bash, and never calls a model, because a model call from an unattended job is dispatch (direction rows 17 and 25).
- **The release run on the Mac uses the PATH and `claude=` value of the newest session receipt on this host,** so worktrees can reuse its per-unit results. The hit rate is measured in shadow (step 7).
- **The per-unit result key includes a hash of every file outside units** (the runner, tests/run, 0007, receipt.sh, the selector). A result written under a runner that differs from main's is never read by another worktree.
- **The Linux tracer is built first.** The Mac selects from the Linux map, always running units that touch a file that branches on platform. The bash 3.2 tracer is built only if a traced full run fits one night of idle slots.
- **The tick fetches the Linux map itself,** from the testmap artifact of main's push run on M: event push, branch main, the exact headSha, the gate workflow, the same filter as `_felix_merge_gate_held` (escape.sh:536). It never takes an artifact from a pull_request run, because on a public repository fork PRs run this workflow too. With no network there is no Linux map, and everything runs.
- **Deploys and background suites share one lock.** A release run that overlapped a deploy does not count. G7.4 keeps session-start and `gate --quick` as the smoke test after install, and adds the release-green check before the pull.
- **A selective `--record-assertions` rewrites only the selected units' manifest rows,** keeps every other row byte for byte, and records in full when the base's manifest has rows the map cannot place in a unit. The red.tsv `scope` row is shaped so that `_rt_record_whole` (1010:30-40) still totals.
- **The measurements belong on the machine that will run the tick,** the new 48 GB laptop. The "today" column is measured again there before any saving is claimed.
