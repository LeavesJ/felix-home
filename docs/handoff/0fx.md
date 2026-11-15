### 0fx. 2026-11-08: the merge boundary reads its policy and its instruments from P (trust-plane step 3, slice 1, 0.49.332)

**What this is.** Design step 3, "separate the authority" (`docs/2026-11-07-trust-plane-design.md` §4.1, §9), slice 1, on branch `LeavesJ/distracted-hellman-58e0fa`.
- The inventory of what the landing authority reads is `docs/2026-11-08-trust-step3-inventory.md`.
- The measurement is `docs/2026-11-08-trust-step3-measurement.md`.
- PDFs of both are in `docs/pdf/`.
- The spec and the review records are in the memory root, `audits/2026-11-08-trust-plane-step3/`.

**What changed.**
- **`lib/policy.sh` (new).** `felix_merge_blockers` reads every table from a snapshot of the project directory as P holds it (S1).
  - P is BASE when the directory sits in a worktree of the merged repository, by that repository's own worktree list, never the index.
  - P is BASE's `projects/<name>` whenever the merged repository is the engine's own, wherever `FELIX_HOME` points, with `<name>` read from BASE's `.felix` (S1.7).
  - Otherwise the path is classified as the home names it: the home directory's physical path, and the rest as written, so a link at `projects/<name>` or a `.git` planted under the home does not choose P (S1.8).
  - A home whose commission tables differ from P's gets an `unverified home` line naming the remedy, because a receipt written there cannot be current (S1.9).
  - An empty or unresolvable base is judged as before; a missing policy library gives a `policy` line (S1.10).
  - For a product's home in another repository, P is that repository's `origin/main`, or its HEAD.
  - A BASE without the directory refuses with a `policy` line.
- **P's commands run P's instruments (S2).** A command-position word of an obligation or probe command that names a file BASE holds runs as BASE's copy, with its whole top-level directory beside it. The working directory stays the candidate's.
  - The rewrite reads a small grammar and stops at the first construct outside it: a substitution, a brace, `[[`, `case`, an array, a here-document, an option or redirection after an interpreter, a wrapper (S2.1).
  - It fails closed. The rest of a command that stopped is read again as bash reads it, and a path P holds that sits where a command, an interpreter's script or a wrapper's argument runs refuses the merge with a `policy` line. None of the 110 commands in the home's tables today lists one.
- **`lib/escape.sh`.** The old body is `_felix_merge_blockers_at`. A trailing comma is forgiven only in `*.json` (S3): appending `,` to a TSV count confine read as no change, and landed on green.
- **`felix` and `lib/resolve.sh`.** Self-governance is asked of BASE as well (`felix_self_governed_at`, S4).
- **Tests.** Parts 2176 and 2177 (one group, `ts3`) were written blind from the spec, a round per amendment: 54 assertions, 25 red-first, which fail on main and pass here. Part 0100 holds a non-blind table of 38 commands over the scan, so CI's gawk runs the reader. Mutants: m8 survives (the worktree-list rule: S1.7 answers first for Felix's own repository, and for a product the next rule reaches the same ref in every case built); the rest are in the report.
- **Reviews.** The first-build review, then four security reviews of the command reader, five rounds in all, each fixed (the fifth round found a regression in the fourth's fix). No further round is taken: the reader models bash, and the structural answer is the partition (spec E5).

**Measured** (details in the report).
- **Battery:** 25 cases were run at both versions: 17 landed on main and 5 land on slice 1. Five review cases more, reproduced against the first cut, are refused on slice 1. Every one that still lands is a stated residual:
  - R5: a cwd-relative read, a mixed file, a runner the scan does not know executing its argument;
  - R2 with R4: `--base`, and a moved local `origin/main`, each with forged receipts and the loosened table copied into the home.
- **Deny floor (0.49.330):** `gh pr merge` in 10 shapes passes it, and push to main is refused in 4.
- **False blocks:** 6 of 59 main commits since 10-08 touched the instrument closure, and none changed output under P's instruments. Two of the three instruments were replayed.
- **Cost:** CPU per judgement on felix-home's tables, interleaved under one load, went from 1.64–1.75 s to 1.99–2.09 s.

**Open, for whoever takes step 3 next.**
- **The partition (spec E5)** before any more work on the command reader: five review rounds each found a parser differential in it. Judge with P's instruments by construction, and read the candidate's tree only as the subject.
- **R2:** bind P to the PR's base as the provider holds it (inventory A6, A7, G1). Since slice 1 the base names the tables too, so this is now the route a receipt forger takes.
- **The stance table.** `lifecycle_wired` hands its checker the candidate's stance table, `engine/harness/templates/lifecycle.tsv`, a yellow path. Moving it to P needs the partition (spec E5) or a change to the row.
- **The suite (R3):** running P's suite over the candidate.
- **Products** whose home is a plain directory still supply their own tables.
- `deploy-check`'s false-block replay, and a fault-injection round on `lib/policy.sh`'s own reads.
- **Replace refs and grafts** (inventory A8): `git replace` in the merged repository changes what git returns for P and the subject. By reading, only the directory snapshot is cut where no replace ref is held; the other reads are made in the checkout. Not run.
- **The rewriter's open forms:** a wrapper S2.1 does not name (`caffeinate tools/check-fx`), an instrument named through a variable, a glob, a path built at run time, a runner defined in the command (`f() { "$@"; }`). The fail-closed reader has run only under BWK awk on this Mac; CI's gawk run of parts 0100 and 2176 is its first there.

**Gate.** `felix gate` was run on this branch's final tree. Its result is in the pull request's body.
