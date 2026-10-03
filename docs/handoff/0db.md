### 0db. 2026-10-01: a fresh repository commissions clean. The mistakes log writes one row per failure and heals split ones, the gate records the project's own failure, a gate that could not run is not a shown failure, and GitHub-only setup rows wait for a GitHub remote

#378 carries #265 (a915bec8) and #267 (1b0074ac) in one slot, by agreement with the queue carrier. Both close as contained when it lands.

**What was reported.** Riyan, on a `git init` repository with no commits, found that commissioning never finished. The chain:
- The first `felix gate` failed.
- `felix_mem_mistake` wrote `$(git rev-parse --abbrev-ref HEAD || echo '?')`. On an unborn HEAD that prints `HEAD`, fails, and gets `?` appended, so a newline was embedded in the row.
- The row split in two, and `gate_shown_failing`'s `cut -f4` never found a fourth field, so commissioning stayed held.

**The class, not the instance.** `$(cmd || echo X)` appends its fallback whenever cmd prints and then fails. The 2026-09-25 sweep found 68 claims of this class and its neighbours: `~/.felix/memory/felix/audits/2026-09-25-fresh-repo-sweep/`, tracked as #366. This PR fixes the commissioning chain and the parts of the sweep that block it:
- **One row, four fields.** The branch and commit come from `felix_head_branch` and `felix_head_commit` in resolve.sh. Each assigns its fallback rather than appending it. A tab or newline in `what` becomes a space.
- **Split rows heal (U44).** `felix_mem_mistakes_heal` rejoins legacy split rows under `<memory>/.mistakes.lock`, which the writer takes too. session-start runs the heal.
- **The project gate is recorded apart from the engine's checks (G5.2, G1.8).** cmd_gate takes the project gate's own status and the byte offset where its output ends before any engine probe runs. A project gate that fails without naming a check is recorded as `exit-<rc>`, where before a failing probe beside it could swallow it.
- **A gate that could not run is not a shown failure (G1.3 stopgap).** On rc 126 or 127, with no failure named first, a line saying so is printed after the recorder, and the status is not recorded as the project gate failing. The full fix changes a commissioning table row, so it waits for the founder's table batch.
- **Setup rows read in three states (G5.1, U19).** `{{REPO}}` is filled in when a row is read, never when it is written; adopt.sh keeps it literal. The remote decides the state:
  - **slug:** the row runs.
  - **unread:** a GitHub remote Felix can't read; the row holds.
  - **none:** there is no GitHub remote; the row waits.

**How it was built.** Red-first against blind tests, then three adversarial reviews, all of whose findings were fixed (a8d5b78f). After main's #376 pipefail lint landed, one test line was converted to a here-string (f2a0d1dd).

**Handed on, not done here:**
- PR-B and PR-C (tree identity before the first commit, and gate-written output) are pushed as `claude/fresh-repo-tree-identity`, stacked on this branch. The carrier registers them after #378.
- #366 clusters 5 to 11 have no owner: diffs blind to the index, felix new's detection, the default branch named master, raw HEAD reads, records and messages, suite coverage.
- The public snapshot must be republished after these land. Until then Riyan's copy still has the bug.
- #387: the Stop hook holds a session the landing queue has told not to run a suite.
