### 2026-11-08: the merge boundary reads its policy and its instruments from P (trust-plane step 3, slice 1, 0.49.332)

**What this is.** Design step 3, "separate the authority" (`docs/2026-11-07-trust-plane-design.md` §4.1, §9), slice 1, on branch `LeavesJ/distracted-hellman-58e0fa`.
- The inventory of what the landing authority reads is `docs/2026-11-08-trust-step3-inventory.md`.
- The measurement is `docs/2026-11-08-trust-step3-measurement.md`.
- PDFs of both are in `docs/pdf/`.
- The spec and the review records are in the memory root, `audits/2026-11-08-trust-plane-step3/`.

**What changed.**
- **`lib/policy.sh` (new).** `felix_merge_blockers` reads every table from a snapshot of the project directory as P holds it (S1).
  - P is BASE when the directory sits in a worktree of the merged repository, by that repository's own worktree list, never the index.
  - P is BASE's `projects/<name>` whenever the merged repository is the engine's own, wherever `FELIX_HOME` points (S1.7).
  - For a product's home in another repository, P is that repository's `origin/main`, or its HEAD.
  - A BASE without the directory refuses with a `policy` line.
- **P's commands run P's instruments (S2).** A command-position word of an obligation or probe command that names a file BASE holds runs as BASE's copy, with its whole top-level directory beside it. The working directory stays the candidate's.
- **`lib/escape.sh`.** The old body is `_felix_merge_blockers_at`. A trailing comma is forgiven only in `*.json` (S3): appending `,` to a TSV count confine read as no change, and landed on green.
- **`felix` and `lib/resolve.sh`.** Self-governance is asked of BASE as well (`felix_self_governed_at`, S4).
- **Tests.** Part 2176 was written blind from the spec: 27 assertions, 13 red-first, which fail on main and pass here. Eight mutants were run against it and seven were killed. m8 survives: the worktree-list rule, which S1.7 answers first for Felix's own repository. No assertion pins it for a product repository that holds its own home.

**Measured** (details in the report).
- **Battery:** of 17 attack cases, 9 landed on main and 5 land on slice 1. Every one that still lands is a stated residual:
  - R5: a cwd-relative read, a mixed file, a quoted word;
  - R2: `--base`, and a moved local `origin/main`, each with forged receipts.
- **Deny floor (0.49.330):** `gh pr merge` in 10 shapes passes it, and push to main is refused in 4.
- **False blocks:** 6 of 59 main commits since 10-08 touched the instrument closure, and none changed output under P's instruments. Two of the three instruments were replayed.
- **Cost:** CPU per judgement on felix-home's tables went from 3.2–3.6 s to 4.0–4.3 s.

**Open, for whoever takes step 3 next.**
- **R2:** bind P to the PR's base as the provider holds it (inventory A6, A7, G1). Since slice 1 the base names the tables too, so this is now the route a receipt forger takes.
- **The stance table.** `lifecycle_wired` hands its checker the candidate's stance table, `engine/harness/templates/lifecycle.tsv`, a yellow path. Moving it to P needs the partition (spec E5) or a change to the row.
- **The suite (R3):** running P's suite over the candidate.
- **Products** whose home is a plain directory still supply their own tables.
- `deploy-check`'s false-block replay, and a fault-injection round on `lib/policy.sh`'s own reads.

**Gate.** `felix gate` was run on this branch's final tree. Its result is in the pull request's body.
