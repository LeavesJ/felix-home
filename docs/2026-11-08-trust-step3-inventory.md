# Trust-plane step 3: what the landing authority reads

2026-11-08. Design step 3 (`docs/2026-11-07-trust-plane-design.md` §4.1, §9) asks for every input the authority reads, where it is read from, whether the judged branch can change it, and where it moves. This is that inventory, for the authority as it stands today: `felix merge` and the land tick.

**Scope.** The merge boundary and the land tick on felix-home, at `origin/main` 4b3179ff (0.49.330), and the two engine slices that move inputs to P: slice 1 (0.49.332, spec rules S1 to S4, including S1.7 to S1.10 and S2.1 as amended after its reviews) and slice 2 (0.49.333, spec rules S5 and S6 in `audits/2026-11-08-trust-plane-step3/spec-slice2.md`, measured in `docs/2026-11-08-trust-step3-slice2-measurement.md`). The gate, the hooks and the capability plane are not the landing authority, and they appear only where the authority reads something they wrote. The hosted authority (design §4.8) does not exist yet. Its identity, and the routes it would close, are listed as residual, not designed here.

**This list is open.** It holds what two methods found (below). The design's own words apply: "any other input the authority turns out to read. This list is enumerated from what the authority actually reads, not written down in advance". An input found later moves to P when it is found (design §11). The row numbers are labels, not a count of the space.

## How it was found

1. **Reading.** The merge path and the land path were read end to end:
   - `cmd_merge` (`engine/harness/felix`), `felix_merge_handoff` (`lib/merge-judge.sh`) and `felix_merge_blockers`;
   - every function the blockers call: `felix_escapes`, `felix_verify_current`, `_felix_merge_gate_held`, `felix_evidence_check`, the probe and obligation runners, the commission receipt check, `felix_land_would_refuse`, `lib/exceptions.sh`;
   - `_gt_tick`, `_gt_candidate`, `_gt_merge` and `_gt_deploy` (`lib/green-tick.sh`), and the launchd job.
2. **A traced run.** `felix merge --dry-run` ran from an installed entry, as the lander runs it, under `set -x`. The fixture was shaped like felix-home: a home checkout that tracks `projects/<name>/`, and a candidate in a worktree of it. Every path the verdict touched was classified by location.
   - The prose-only candidate's verdict touched 22 distinct paths. The traced run reached no C9 branch (the receipt reported `tests:ok`), no refusal branch, and no product fixture. Inputs on those branches come from the reading alone.
   - The fixture builder and trace runner are in this session's scratchpad. They are not shipped.

## The inventory

Key to the columns:
- **Branch?** Can a commit on the judged branch change this input, so that it changes that branch's own verdict?
- **Worker?** Can a process on this Mac, running as the same user, change it without going through review?
- **Moves to.** Where design §4.1 puts it.
- **After slices 1 and 2.** What 0.49.332 (slice 1) and 0.49.333 (slice 2) do about it. A row slice 2 changed says so.

### A. The judge

| # | Input | Read from today | Branch? | Worker? | Moves to | After slices 1 and 2 |
|---|---|---|---|---|---|---|
| A1 | The engine that forms the verdict | The installed cache entry for main's version, byte-checked against main through main's own `resolve.sh`. A branch's own felix hands the whole command to a copy cut from git | No, through the entry. Yes, when the worker runs the branch's own felix and the branch removed the hand-off (`lib/merge-judge.sh`, "what this does not bind") | Can write the cache (a doctored entry is refused) and can run any felix it likes | P, then the hosted authority (§4.8) | Unchanged; residual R1 |
| A2 | Whether the checkout is the engine's own repository, which decides whether main's engine judges at all | The candidate's tree (`felix_self_governed`) | **Yes:** deleting `engine/.claude-plugin/plugin.json` made a branch be judged by the felix it carries | Yes, through A1 | P | **Moved:** read from BASE as well (S4) |
| A3 | The version that names the judge | `BASE:engine/.claude-plugin/plugin.json` | No | Through A6 and A7, until slice 2 moved them | P | Already P |
| A4 | The code that checks the judge | `BASE:engine/harness/lib/resolve.sh` | No | Through A6 and A7, until slice 2 moved them | P | Already P |
| A5 | Environment that chooses or loosens a judge (`FELIX_KERNEL`, `FELIX_MERGE_HANDED`, the cache variables, `TMPDIR`, `PATH`) | The caller's environment | No | Yes, for its own run of felix merge. The lander takes three of them out and runs under launchd's `PATH` | The authority's own environment | Unchanged (refusals and the byte check stand); residual R1 |
| A6 | The base the merge judges against, which names P | `--base`, or `main` resolved to `refs/remotes/origin/main` | No | **Yes:** a worker-run felix merge can name a ref the worker controls, and P is then the worker's | The PR's base on the provider | **Moved** (slice 2, S5): B is read once and compared with the base commit the provider names for the pull request, once nothing else blocks, and again just before the squash. Another base is refused with a `base` line. The provider's answer comes through the worker's `gh` (R1) |
| A7 | `refs/remotes/origin/main` itself | The local ref. The lander fetches at the start of each tick, and felix merge does not fetch | No | Yes (`git update-ref`) | The provider's ref, read by the authority's identity | **Moved** (slice 2, S5), as A6: a moved or stale local ref is refused with a `base` line that names both commits |
| A8 | What git returns for an object: the merged repository's replace refs (`refs/replace/`) and grafts | Every git read the merge makes in the checkout, of P and of the subject | No: a pull request carries no such ref | Yes (`git replace`, a graft file) | P read with replacement off, or the authority's own clone | **Moved** (slice 2, S6.2): replacement off and the graft file pointed at a path that does not exist, for the merge and every child |
| A9 | What git returns for an object from the checkout's own store: a loose object rewritten under its old name, the commit-graph, the multi-pack index, a planted pack | Every git read the merge makes | No | Yes (a file under `.git/objects`) | Objects checked against their names, or the authority's own clone | **Moved in part** (slice 2, S6.3, S6.4): the objects of B, H and M and their trees are copied through `index-pack`, which names each by hashing it, and the run reads the copy first (held packed and loose, since git 2.56 reads a loose object in any store before a packed one); the commit-graph and the multi-pack index are switched off. A planted pack is open: git serves an object from the pack it used last without hashing it again (slice 2 measurement, section 4) |
| A10 | The caller's git environment (`GIT_DIR`, `GIT_OBJECT_DIRECTORY`, `GIT_ALTERNATE_OBJECT_DIRECTORIES`, `GIT_CONFIG_*`, `GIT_EXEC_PATH` and others) | The caller of felix merge | No | Yes, for its own run | The authority's own environment | **Moved** (slice 2, S6.1): unset before anything is read, for the merge and every child |

### B. Policy tables

These are the files under `projects/<name>/`. Before slice 1, all of them were read from the project directory as the home's working tree holds it. The judged branch could change them when the home is the candidate's own checkout: a branch checked out in the home, a worker that points `FELIX_HOME` at its checkout, or CI, where the home is the checkout under test. A worker could change them by editing the home's working tree, or by pointing `FELIX_HOME` at a plain directory of its own.

| # | Input | Read by | Moves to | After slices 1 and 2 |
|---|---|---|---|---|
| B1 | `risk.tsv`: the project's escape rows and their confines | `felix_escapes` | P | **Moved** (S1) |
| B2 | `evidence.tsv` | `felix_evidence_check` | P | **Moved** (S1) |
| B3 | `project.json`: `gate_workflow`, which names the CI run C9 reads, and the evidence set-asides | `_felix_merge_gate_held`, `_felix_evidence_pj` (this one was already read at the base when the project directory is inside the repository) | P | **Moved** (S1) |
| B4 | `probes.tsv` | the probe runner and the receipt's epoch | P | **Moved** (S1) |
| B5 | `obligations.tsv` | the obligation runner | P | **Moved** (S1) |
| B6 | `commissioning.tsv`, and the commission policy version, which hashes `FELIX_COMMISSION_TABLES` (in the trace: `risk`, `evidence`, `probes`, `obligations`, `project.json`, `deny`, `profiles`, `routes`, `setup`, `stack`, `capabilities/`) | the commission receipt check | P | **Moved** (S1) |
| B7 | `land.tsv` (report-only at the merge) | `felix_land_would_refuse` | P | **Moved** (S1) |
| B8 | `exceptions.tsv` | `lib/exceptions.sh`, from `refs/remotes/origin/main`, and unused at the merge (release mode drops TASK_BLOCKING) | P | Already P |
| B9 | The policy-change rule for these tables: the `verifier` channel's row comparison | `_felix_escape_lines` | P's rule | **Fixed** (S3) |

B9 is a defect in the rule itself. The comparison stripped a trailing comma from every row, for `project.json`'s sake. So appending `,` to a TSV row read as no change: appending it to a `count:` confine in `risk.tsv` stops that row counting anything, and that edit landed on green. It did not loosen its own merge, which read P's table. It loosened every merge after it, which is the same kind of loss in two steps.

Tables the merge does not read at all (`qualification.tsv`, `deny.tsv` beyond the commission hash, `gate.sh`, `templates/schemas.tsv`) are read by the gate and the hooks, on the worker side.

### C. Instruments that P's commands execute

| # | Input | Read from today | Branch? | Moves to | After slices 1 and 2 |
|---|---|---|---|---|---|
| C1 | An obligation's `applies` command, and the executable it names (felix-home: `engine/harness/bin/deploy-check`) | `bash -c` in the candidate's checkout, so a script it names was the candidate's | **Yes:** rewriting the script retired the need as DORMANT | P's instrument over the candidate's subject (§4.4) | **Moved** (S2) |
| C2 | An obligation's evidence contract (felix-home: `engine/harness/bin/lifecycle-check`, RELEASE_BLOCKING, run at every merge) | the same | **Yes:** a branch could make its own checker exit 0 | the same | **Moved** (S2) |
| C3 | A probe's `when`, command and witness (felix-home: `engine/harness/bin/hooks-events`) | the same | **Yes** | the same | **Moved** (S2) |
| C4 | The closure of those scripts: what they source beside themselves (`lib/coverage.sh`, `lib/resolve.sh`) | the candidate's copy, beside the candidate's script | **Yes:** the checker unchanged and its library rewritten | P | **Moved** (S2.3: P's whole top-level directory) |
| C5 | What a P script reads by a path relative to the working directory; a mixed file (`make`, `npm test`); an instrument named through a variable (`$D/check`), a glob, or a wrapper S2.1 does not name | the candidate's checkout | Yes, where such a script or word exists. felix-home's tables hold one: `lifecycle_wired` hands its checker `engine/harness/templates` by path, so the stance table `lifecycle.tsv` it judges hooks against is the candidate's (a `yellow` path). Removing a hook binding itself escapes through the `red` rows on `engine/hooks/` and `engine/harness/hooks/` | P, through the partition (spec E5) and the gateway (E4) | Residual R5. A path P holds that a P command names where the rewrite cannot place it (in quotes in command position, after an interpreter's option, after a wrapper S2.1 names, inside a substitution, group or `case` body) is refused (S2.1, fail closed) |
| C6 | `bin/secret-scan`, the `disclose` channel's scanner | the judge's own copy (P) | No | P | Already P |

### D. Evidence the merge accepts

| # | Input | Read from today | Branch? | Worker? | Moves to | After slices 1 and 2 |
|---|---|---|---|---|---|---|
| D1 | The gate receipt (`<home>/state/gate/<hash of the checkout path>`) | A file the worker's own gate wrote. The gate runs the home's `gate.sh`, and through it the candidate's suite | **Yes**, within the suite's count guards (R3) | **Yes:** the file is the session's to write | An authority run (§4.4, `authority_run`) | Unchanged; residuals R3 and R4 |
| D2 | The suite: `tests/run`, `tests/parts`, `tests/lib`, `assertions.tsv`, `red`, `receipt.sh`, `groups.tsv` | The candidate's tree, guarded only by `risk.tsv` rows: some count lines, some fire on any change | **Yes:** a helper's body (`bad()` in `tests/run`, a part's own helpers) can change without changing any counted line | Through D1 | P's suite over the candidate (E7) | Unchanged; residual R3 |
| D3 | The CI gate run on the head (rule C9, and the lander's precondition) | GitHub. A `pull_request` run uses the candidate's workflow file (any change to it escapes `execute`), and it runs the candidate's `./engine/harness/felix gate` | **Yes:** for an engine change, CI is the candidate judging itself, so it is never `provider_read` under CI4 | No | An authority run, or `provider_read` only under CI4 | Which workflow is asked is now P's (B3); the rest is residual R4 |
| D4 | Review verdicts (`state/review/<name>-<tree>`), which clear the `reviewed` channel | A file | No | Yes | An authority record | Unchanged; residual R4 |
| D5 | The commission receipt (`state/commission/<name>`) | A file | No | Yes | An authority record | Unchanged; residual R4 |
| D6 | The epoch's grounded facts | Computed at the merge | Through B4 and C3 | Through B4 | P | Computed from P's tables and P's instruments (S1, S2) |

### E. The subject

These are rightly the candidate's:
- E1: the changed paths and the added lines (`base...HEAD`, the index and the working tree), the tree id, the head and the branch name;
- E2: the detected surfaces that the commission caps hash reads.

One input here is not what lands:
- E3: the checkout's index and working tree, which the instruments read and the squash does not carry. Slice 2 checks the objects of H, not these (spec-slice2 §3); open.

### F. The land tick

| # | Input | Read from today | Worker? | After slices 1 and 2 |
|---|---|---|---|---|
| F1 | The open pull requests, their labels, draft state, mergeability and base | `gh pr list`, with the tick's login | Yes: a worker's token can remove `felix:hold` or `needs-founder` | Unchanged; residual R6 |
| F2 | The direction-document check (`projects/*/claude.md`, `docs/*roadmap*`) | the PR's files from git and gh | It does not match `docs/direction.md` (direction, header: held only once A32, draft #452, lands) | Unchanged; open, owned by #452 |
| F3 | The CI gate run | `_felix_merge_gate_held` with the home's `project.json` | As D3 | Unchanged |
| F4 | The checkout the tick merges from | `git worktree list` of the home: the worktree on the PR's branch at the gated head | Yes: the worker chooses it, and it is the subject | Unchanged (it is the subject) |
| F5 | Which home the tick governs | `felix_home`: `FELIX_HOME`, which the launchd job does not set, then the `~/.felix-home` pointer. The job's `FELIX_HOME_DIR` is overwritten at startup (`felix:386`) | Yes: the pointer is a file the user owns | For Felix's own repository the tables come from BASE whatever directory the home names (S1.1, S1.7). For a product governed from a home, a home that no repository holds still supplies the tables (spec §3). Receipts follow the home; residual R4 |
| F6 | Deploy state: origin/main's version, the cache entry, the home's HEAD | git and the cache | Through A7 and the cache | Unchanged |
| F7 | Its own ledger, pause, lock and heartbeat | the memory root | Yes | Operational; not part of a verdict |

### G. The merge act and the routes around it

| # | Input | Today | After slices 1 and 2 |
|---|---|---|---|
| G1 | `gh pr merge --squash --match-head-commit`. The PR is chosen by branch name, and the squash lands on the PR's base as GitHub holds it | the worker's or the tick's `gh` login | **Narrowed** (slice 2, S5.3, S5.4): that base is compared with the one judged, and asked again just before the squash. Open: the window between that last read and GitHub's squash, and the `gh` that answers (R1) |
| G2 | Landing without the authority: raw `gh pr merge`, `gh api`, `git push origin HEAD:main`, the web UI | felix-home's plan has no branch protection on a private repository (`lib/escape.sh`, C9's header). The PreToolUse deny rows are the floor (direction §5 item 4, step 18) | Residual R1 |

## Residuals named above

R1 to R6 are this inventory's labels for what slice 1 left open. They are measured in `docs/2026-11-08-trust-step3-measurement.md`, and slice 2's changes to them in `docs/2026-11-08-trust-step3-slice2-measurement.md`.

- **R1:** the authority runs as the worker's user, on the worker's machine, and the worker's tokens can push to main. Closing it needs the hosted authority with its own identity, and a repository where worker tokens are kept off main (direction row 43).
- **R2:** the authority's idea of P was a local ref and an argument, and since slice 1 that ref names the tables and instruments as well as the judge. Slice 2 binds P to the base the provider names (A6, A7, G1). What is left of R2 is the `gh` that answers for the provider, which is R1, and the window after the last read.
- **R3:** the suite that judges Felix's engine is the candidate's.
- **R4:** the receipts and verdict files that the merge accepts are files the worker can write. This covers the gate, review and commission receipts, and the home pointer they follow.
- **R5:** the instrument partition and the I/O gateway are not built.
- **R6:** a worker's token can change the labels the tick holds on.
