# Trust-plane step 3, slice 2: is what the merge judges what the provider squashes?

2026-11-08. Slice 1 (`docs/2026-11-08-trust-step3-measurement.md`) moved what P holds to P, and left P itself as an argument and a local ref (residual R2). Slice 2 binds P to the commit the provider names as the pull request's base. It also makes what git returns for P and for the subject what their object names say. The spec is `audits/2026-11-08-trust-plane-step3/spec-slice2.md` in the memory root. The inventory's labels (A1 to G2, R1 to R6) are those of `docs/2026-11-08-trust-step3-inventory.md`.

**Scope.** `felix merge`, as the lander and a session run it, for the repository being merged, at two versions:
- **main:** `origin/main` 460074d5 (0.49.332);
- **slice 2:** this branch (0.49.333), spec rules S5 and S6, in `engine/harness/lib/bind.sh` and its callers, after the review in section 3 and its fixes.

Not measured: the hosted authority, which does not exist; the lander against a live pull request, which would land it; CI's bash 5.3 and gawk, which run this branch in CI and not on this Mac; products beyond the two replayed in section 2.

**This is an open set.** Every count below says what one test part, one replay window or one review counted. None of them is the size of the space. A route found later is a new row, and it moves when it is found (design §11).

## Answer

**Through the base: refused on slice 2.** On main, `felix merge --base refs/heads/evil`, or `refs/remotes/origin/main` moved to `evil`, squashes a candidate that deletes `MARKER`, when `evil` makes P's checker pass. These are slice 1's OB1b and OB2b, with an instrument in place of a table. On slice 2 the provider names `main` at its own commit as the base, and both are refused with a `base` line before anything is merged.

**Through git's object store: refused on slice 2.** On main, each of these lands the same defect:
- a replace ref;
- a graft;
- a loose object rewritten under its old name;
- the caller's `GIT_OBJECT_DIRECTORY` naming a store where P's library is rewritten.

On slice 2 the first two are switched off, the third is refused by the object's name, and the fourth is unset before git reads anything.

A fifth member was found after the pull request opened (section 3, round 2): a loose file in the checkout rewritten after the copy is checked, while the run reads. On this branch as first built (defe075e) that landed the defect, because git 2.56 read the checkout's loose file before the copy's pack. It is refused since round 2.

**What still lands.** Slice 2 does not change residual R1. The `gh` that answers for the provider runs as the worker's user. A worker who puts its own `gh` first on `PATH` can answer both reads with the base it chose, and then pass `pr merge` to the real one. The deny floor was not probed for that route. The other open members are in section 4.

## 1. The battery: part 2178

Part 2178 was written from spec sections 1 and 2 without the implementation in view. It drives `felix merge` from an installed entry, over a scratch repository shaped like felix-home, against a `gh` stub. The stub answers the two reads the spec allows: A (`gh pr view`: state, base, head) and Q (`gh api .../git/ref/heads/<base>`). The fixture's one RELEASE_BLOCKING obligation, `fx`, runs P's `tools/check-fx`. That checker sources `tools/lib.sh` and passes only while `MARKER` exists. Every case records its gate and commission receipts directly, as any session can (R4).

| Case | What the run does | main (0.49.332) | slice 2 |
|---|---|---|---|
| control | an honest candidate, provider defaults | merged | merged |
| control (S5.5) | deletes `MARKER` | refused (`obligations`), provider not asked | refused (`obligations`), provider not asked |
| another base | `--base refs/heads/tpb-evil`, where `tpb-evil` makes `fx_check` true; deletes `MARKER` | **merged** | refused (`base`) |
| another base, dry run | the same, `--dry-run` | **would squash** | refused (`base`) |
| the local ref moved | `refs/remotes/origin/main` moved to `tpb-evil`, no `--base` | **merged** | refused (`base`) |
| the head differs | A names a head that is not the checkout's `HEAD` | merged (in the stub; GitHub's `--match-head-commit` would refuse) | refused (`moved`) |
| no answer from Q | Q exits 1, honest candidate | merged | refused (`base`) |
| no answer from A | A exits 1 | merged | refused (`base`) |
| A says CLOSED | the pull request is not open | merged | refused (`base`) |
| no answer, dry run | Q exits 1, `--dry-run` | would squash, no note | would squash, with the "not compared with the provider" note, exit 0 |
| the last moment (S5.4) | Q answers main, then a commit one ahead | merged, Q never asked | refused (`moved`) after asking Q twice |
| a stale local ref | the provider's main is one ahead of the local ref | merged | refused (`base`, naming both commits) |
| a stale local ref, the remedy | the local ref brought up, fresh receipts | merged | merged |
| a rewritten loose object (S6.3) | the loose file for P's `tools/lib.sh` rewritten so `fx_check` is true; deletes `MARKER` | **merged** | refused (`objects`, naming the blob) |
| the caller's environment (S6.1) | `GIT_OBJECT_DIRECTORY` names a store where P's `tools/lib.sh` is rewritten; deletes `MARKER` | **merged** | refused (the part accepts the `fx` obligation or an `objects` line, and does not record which) |
| a replace ref (S6.2) | the candidate's head replaced by a commit holding main's tree; adds `danger/x` | **merged** | refused (`escape`) |
| a graft (S6.2) | the candidate's parent grafted onto a commit that held `danger/x`; adds it back | **merged** | refused (`escape`) |
| packed objects | after `git gc`, an honest candidate | merged | merged |
| nothing left (S6.5) | after every run | (no copy is made) | no `felix-objects.*` entry left |

The blind part holds 28 assertions, the rows above and their fixture controls. On main 14 fail, each one a row that slice 2 changes, and 14 pass. On slice 2 all 28 pass. After the review (section 3), the part also holds 14 assertions that are not blind, labelled `ts3b-x`: 7 cases from the mutant run, the colour pin, and round 2's three cases with two fixture controls and a restore check. Each case was run against the mutant or the unfixed code it was written for, and failed there. The logs are filed beside the spec, in `slice2/`.

Six of main's merges above land a defect: the two through the base and the four through the object store. The other main merges are of honest candidates that slice 2 now refuses because it fails closed. When the provider gives no answer, says the pull request is closed, or names a base that moved, nothing is known about what would land.

One fixture change came after the blind draft. The draft's `tpb-evil` emptied `obligations.tsv`, as the spec's own draft fixture did. A ledger that admits no obligation is refused before any base is compared, so the base was not what stopped the candidate. `tpb-evil` now makes `fx_check` true instead, and the spec's section 2 says so. The assertions did not change.

## 2. False blocks and cost

**The copy, replayed.** `felix_bind_objects` (S6.3, S6.4) ran over each first-parent commit C on `origin/main` since 2026-10-09, with B = C's parent and H = C, in felix-home's own checkout:
- **felix-home:** 62 commits, none refused.
- **Two product repositories found on this Mac:** black-box-bazaar (29 commits, every commit with a parent) and veldra (39 commits since 2026-08-01). None refused.
- **Again after round 2's fix** (section 3), which also writes V loose: felix-home's 62, none refused; black-box-bazaar's 29, none refused; and 66 commits since 2026-08-01 of a veldra checkout at `veldra-ref/build`, none refused. That is not the veldra checkout replayed first, which was not found again. Each repository's root commit has no parent, is refused with `objects copy`, and is not counted.
- **Not replayed:** the other products governed from felix-home, whose checkouts were not found on this Mac.

A squash commit stands in for the pull request's head, so H's tree is the one that landed. The replay script and its output are in `slice2/measure/`.

**CPU per judgement** (user plus sys, one fresh bash per commit, on this Mac while other work ran):
- the copy as first built: 0.21 to 0.70 s on felix-home, mean 0.33 s; 0.08 to 0.64 s on black-box-bazaar, mean 0.23 s; 0.12 to 0.14 s on the first veldra checkout;
- the copy after round 2, packed and loose: 0.51 to 1.47 s on felix-home, mean 0.83 s; 0.09 to 1.18 s on black-box-bazaar, mean 0.42 s; 0.19 to 0.37 s on `veldra-ref/build`, mean 0.32 s;
- the same bash without the copy: 0.00 to 0.01 s.

Round 2 roughly doubles the copy's cost on felix-home, because every object under three trees is written loose as well. Writing loose only the names the checkout holds loose would cost less, and is not done: a loose file the run's own children write later, under a name the checkout held only packed, would then be read before the checked pack.

The copy uses `pack-objects --window=0`, which skips delta search. With it on, one run over felix-home cost 1.55 s user against 0.53 s.

**The two provider reads.** Each was timed three times against GitHub from this Mac. A took 0.40 to 0.52 s wall, Q 0.30 to 0.31 s, and each about 0.03 s CPU. A merge asks A once and Q twice, about 1.1 s wall in all. A dry run asks each once.

**Where a refusal now comes from that did not before:**
- **The provider moved between the lander's fetch and its judgement.** The lander fetches at the start of each tick, and a hand merge in between moves `main`. The candidate is refused with a `base` line, and the next tick fetches again. The cost is one tick, five minutes. That is read from the lander's code, not run.
- **No answer from `gh`** (no network, an expired login, a rate limit). A merge is refused, and a dry run passes with the note. Before slice 2, a failed `gh pr view` let a merge go through with its title falling back.
- **A tree git's fsck rejects** (`index-pack --fsck-objects`). None did in the replay. A repository with old objects, such as zero-padded file modes in a tree that is still current, would be refused until they are rewritten.
- **Another repository read inside the merge.** The copy's environment reaches every child, so a P command that ran git in a third repository would read that repository's objects through the copy and fail. felix-home's tables at main were searched for one. Of their 110 commands across nine projects, 59 name git, and none points it elsewhere (`git -C`, `--git-dir`, `GIT_DIR` or a `cd`). The three engine instruments they run, by reading their git calls, use only the checkout's top level. So no instance today, by that search.

## 3. The review

One round, three lenses at once, each finding of medium or higher then given to a skeptic told to refute it:
- a fail-open reviewer;
- a regression and portability reviewer;
- a mutant run against part 2178.

The implementer's seven recorded open points were handed to the reviewers as known, to say whether each was worse than recorded.

**Found, and fixed on this branch:**
- **A failed provider read parked an honest pull request** (regression; the skeptic agreed, and rated it medium). No answer at S5.3 is a `base provider` refusal, exit 3. The lander classed it `final`, so it held the pull request until its head or main moved, however soon `gh` recovered. Before slice 2, the one `gh` failure that could stop an honest merge was `gh pr merge` itself, which the lander retries hourly. The lander now classes a block whose one line is `base provider` as hourly (`lib/green-install.sh`). A `base` line naming a commit stays final, because the next fetch moves main. Part 1650 holds both, as cases A25 and A26, not blind.
- **The engine's colour pin was dropped** (regression and the mutant run; the skeptic rated it low). S6.1 unset `GIT_CONFIG_PARAMETERS`. That is where felix's own pin lives, the one that keeps a person's git colour out of what the engine parses. So the merge and every child ran unpinned. No wrong verdict was found: each engine reader on the merge path that the skeptic read passes `--no-color` or reads only stderr. The pin is now put back alone after the scrub. Part 2178 checks that the `gh` that squashed saw it.
- **Two readings of the repository's name** (fail-open, low). S5 asked GitHub about the repository `_felix_bind_slug` names, while `gh pr merge` was handed `felix_repo_slug`'s reading, and the two differ on a trailing slash or a deeper path. No pair of origins was found where both succeed with different repositories. The merge now uses the one S5 asked about.
- **What the full suite found**, which the implementer had not run: two lints `bind.sh` broke (a `[[ =~ ]]` without `local LC_ALL=C`, digit ranges in bash patterns), a raw `git -C` write in part 2178, and the driver one line over its 500. Each is fixed. That run was made from an archive of the branch, with no `.git`, and seven more of its failures were assertions that need a checkout; the gate runs in one (its result is in the pull request's body).

**Not worse than recorded,** by both reviewers:
- **The planted pack (open point 1).** The fail-open reviewer reproduced git serving a forged pack without hashing it again. It could not make that answer for an object in V under `bind.sh`'s layout: the copy is the primary store and holds all of V, and git preferred it. That rests on git 2.56.0's lookup order, so it stays open.
- **The hand-off's pin (point 4).** A caller that sets the pin variables itself is refused on every path tried, and a forged B is still caught by S5.3.
- **Reads of another repository (point 5).** In every reader the reviewers checked, these fail closed: a spurious refusal, not a pass.
- **Tests that call the real `gh` (point 7).** A logging `gh` first on `PATH`, across about 9,000 of the suite's assertions (that run did not finish), saw two real calls, both from a fixture that is not a merge. No merge part among them reached the network.

**The mutant run.** 27 mutants, each one edit to `bind.sh` or `cmd_merge`:

| Result | Mutants |
|---|---|
| killed by the blind part as written | 12: the base comparison always passing; the head comparison skipped; no answer proceeding; the last read skipped, or its answer ignored; replace refs on; grafts on; the copy skipped; the copy left behind; the dry-run note dropped; the provider asked before the blockers; the comparison skipped in dry runs |
| killed by cases added to part 2178 from the run (labelled `ts3b-x`, not blind) | 8: the judge given the ref instead of the pinned B, and B re-read after the pin (both caught by moving the ref mid-run); the base comparison, and the last read, on seven digits; the last read with no answer passing; Q's object type, A's number and A's base name not checked |
| killed by cases added in round 2 (`ts3b-x`) | 3: M's tree left out of V; the commits since M left out of V; the copy never read after it is checked |
| killed by another part | 1: objects written during the run not moved back (part 0350) |
| survive, fixture not built | 2: the environment scrub skipped (S6.3 still catches the case the part builds); the commit-graph and multi-pack index left on |
| equivalent, by reading | 1: the merge base not recomputed under the copy |

The run shows one thing more. Under three of the mutants, a merge was still refused by the last read (S5.4), with a `moved` line where the spec wants `base`. Only the part's check of the line's kind caught them. A dry run has no last read, so for a dry run S5.3's comparison is the only guard. The mutant that made the comparison always pass let a dry run say "would squash" with another base.

**Round 2, after the pull request opened: fixtures for three survivors, and one defect.** Part 2178 gained a case for each of three surviving mutants, built before the part's `git gc` while the fixture's objects are loose:
- **M's tree:** a candidate cut from an older main, whose merge base alone holds an object that does not hash to its name. Refused with an `objects` line; the e4 mutant merges it.
- **The commits since M:** a candidate of two commits, the first of which does not hash to its name. Refused with an `objects` line; the e5 mutant merges it.
- **The copy is read:** a `git` ahead on `PATH` rewrites the checkout's loose file for P's `tools/lib.sh` after each copy is checked, and puts it back before each is made. A candidate that deletes `MARKER` must be refused by the `fx` obligation.

The third case failed on the branch as it stood (defe075e): the candidate was merged. A log of every git call in that run showed every read under the copy, except the land table's (below). A test outside the suite then showed why the copy's bytes were not what came back. On git 2.56, with the run's object directory holding V in a pack and the checkout as the alternate, `git cat-file` returned the checkout's rewritten loose file. With the same objects loose in the run's own store, it returned the checked bytes, and the order of the alternates decided between two loose stores. So, by that order, a name in V that the checkout held loose was read from the checkout, which is why the e6 mutant (the copy never read) survived: for such names it changed nothing the part could see.

The fix writes V loose as well, into a store inside the copy that is the first alternate, ahead of the checkout. The checked pack stays the object directory, for a git that reads packs first, and still takes what the run writes, so the exit's salvage is unchanged. A path holding `:` is refused, since git splits the list of stores there. All three cases pass on the fix, and each fails against its mutant. The logs and the lookup-order test are in `slice2/review/round2/`.

**Not checked:**
- CI's bash 5.3 and gawk, which run this branch in CI, not on this Mac;
- a merge driven end to end on a SHA-256 repository (the copy was run on one);
- a real GitHub rate-limit answer, which was simulated by a stub that exits non-zero;
- the launchd job itself, whose classification was simulated from the lander's code.

## 4. Open after slice 2

- **R1, `gh` itself.** The provider's answers come through the `gh` on `PATH`, run as the worker's user. Slice 2 narrows R2 to this.
- **The window after S5.4.** Between the last read of the base and GitHub's squash, another merge can move the base. `--match-head-commit` binds the head, and nothing binds the base.
- **A planted pack.** git serves an object from the most recently used pack that names it, without hashing it again. So a pack planted in the checkout could answer for an object in V once a read elsewhere has put that pack first. Since round 2, git 2.56 reads a name in V from the copy's loose store before it looks at any pack, by the lookup-order test above, so the route needs a git that reads packs first. No forged pack was built against the fix.
- **Reads that drop the copy.** The land table (`lib/land-table.sh`) is read with the copy's variables dropped, at `refs/remotes/origin/main` and not at B, because a product's home is another repository. For felix-home merging itself it is the same repository, so those reads take the checkout's objects unchecked. What they feed is report-only: the would-refuse rows in `says.log`, run in a subshell whose output and status the verdict does not read (`lib/escape.sh`). Seen in round 2's log, not changed.
- **The lookup order itself.** Round 2's fix rests on git reading stores in order and loose objects first, which was measured on git 2.56.0 on this Mac only. CI's git was not tested for it.
- **The subject beyond its objects (inventory E3).** The instruments read the checkout's index and working tree, and those do not land.
- **The checkout's config.** Repository-local config (`core.fsmonitor`, filter drivers, `core.excludesFile`) still reaches the reads.
- **A product's home.** Its tables come from that repository's own objects, which the copy does not check.
- **Hash strength.** S6.3 trusts that two contents do not share a name. felix-home's names are SHA-1.
