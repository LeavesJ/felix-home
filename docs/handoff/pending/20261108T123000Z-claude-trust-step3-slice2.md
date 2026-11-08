### 2026-11-08: what the merge judges is what the provider squashes (trust-plane step 3, slice 2, 0.49.333)

**What this is.** Design step 3, slice 2, on branch `claude/trust-step3-slice2`. It closes inventory rows A6, A7 and A8 and narrows G1.
- The spec is in the memory root, `audits/2026-11-08-trust-plane-step3/spec-slice2.md`, with the run logs beside it in `slice2/`.
- The measurement is `docs/2026-11-08-trust-step3-slice2-measurement.md`.
- The inventory, `docs/2026-11-08-trust-step3-inventory.md`, now has an "After slices 1 and 2" column and rows A9, A10 and E3.
- PDFs of the three are in `docs/pdf/`.

**What changed.**
- **`lib/bind.sh` (new).** First thing in `felix merge`, the caller's git variables that choose a repository, an object store, config or a helper are unset (S6.1). Replacement and grafts are switched off, as are the commit-graph and the multi-pack index (S6.2). The engine's own colour pin is put back after the scrub. The base ref is read once, to B (S5.1).
  - The objects of B, H and M, with their trees and the commits since M, are copied through `index-pack --fsck-objects` into a `felix-objects.*` directory. A name the copy lacks is an `objects` refusal. The rest of the run reads the copy first, with the checkout behind it (S6.3, S6.4). The copy holds them packed and loose: git 2.56 reads a loose object in any store before a packed one, so with the pack alone the checkout's loose files were read first (found in round 2, after the pull request opened).
  - Once nothing else blocks, the provider is asked two things through `gh`: the pull request's state, base and head (A), and the base branch's commit (Q). The merge stands only when they are H and B (S5.2, S5.3). Q is asked again just before `gh pr merge` (S5.4).
  - With no answer, a merge refuses with `base provider`, and a dry run passes with a "not compared with the provider" note. The copy is removed on exit, after any object written during the run is moved back to the checkout (S6.5).
- **`felix`.** cmd_merge calls the above. The squash uses the repository name S5 asked about.
- **`lib/policy.sh`, `lib/land-table.sh`.** A read of another repository (a product's home) drops the copy's object variables.
- **`lib/green-install.sh`.** A `base provider` refusal (no answer) is retried hourly, not held as final.
- **Tests.**
  - Part 2178 holds 28 blind assertions, from spec sections 1 and 2: 14 fail on 0.49.332 and all pass here. It also holds 14 `ts3b-x` assertions, not blind: 7 from the mutant run's added cases, 1 for the colour pin, and 6 from round 2 (three cases, two fixture controls, one restore check).
  - Part 1650 gains A25 and A26, not blind.
  - The provider stubs in `tests/lib/merge.sh` and `tests/lib/judge-refs.sh` answer A and Q.
  - Parts 0360 and 1870 changed what they expect: a missing GitHub remote is now a `base` line, and a missing blob an `objects` line.

**Measured** (details in the report).
- **Battery:** on 0.49.332, another base, a moved local ref, a replace ref, a graft, a rewritten loose object and a caller's `GIT_OBJECT_DIRECTORY` each land a defect. Here each is refused.
- **False blocks:** the copy refused none of 62 felix-home landings since 10-09, 29 black-box-bazaar commits or 39 veldra commits. No table command at main runs git in another repository.
- **Cost:** the copy takes 0.51 to 1.47 s CPU per judgement on felix-home, mean 0.83 s, since round 2 writes V loose as well (0.21 to 0.70 s before). The provider reads take about 1.1 s wall per merge, about 0.1 s CPU.
- **Review:** three lenses and two skeptics, with three real findings (the lander's hold, the colour pin, two readings of the slug), each fixed. 27 mutants: 23 killed by part 2178 as it now stands, 1 by part 0350, 2 survive for want of fixtures, and 1 is equivalent. Round 2 built fixtures for three survivors, and the one for "the copy never read" exposed the lookup-order defect above, now fixed.

**Open, for whoever takes step 3 next.**
- **R1, `gh` itself.** A `gh` first on `PATH` answers for the provider. The hosted authority's own identity is what closes it.
- **The window after S5.4,** until the merge queue (design step 4).
- **A planted pack**, the two surviving mutants' fixtures (the scrub, the commit-graph), git's lookup order on a git other than this Mac's 2.56, and the subject beyond its objects (E3). These are the measurement's section 4.
- **The partition (spec E5), slice 3.** A sample of main's landings, in the slice 3 notes beside the spec, shows how often P's version of a modified test part fails on the landing's engine. The candidate rule needs that number before it can bind.

**Release.** 0.49.333 fails closed until the founder authorizes it by name (direction row 49). The pull request is labelled needs-founder.
