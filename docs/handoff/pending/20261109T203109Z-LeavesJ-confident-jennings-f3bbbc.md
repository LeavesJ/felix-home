### 2026-11-09: the hosted trust authority, designed and tried on a local mock (trust-plane step 4, documents only)

**What this is.** The design for the hosted authority of design §4.8 and direction row 43, and a spike of the claim it rests on most. Nothing in `engine/` changes, nothing was built at GitHub, and no setting, token or key was changed.
- The design is `docs/2026-11-09-trust-hosted-authority-design.md`. The measurement is `docs/2026-11-09-trust-hosted-authority-spike.md`. Both have a PDF in `docs/pdf/`.
- The spike's code and logs are in the memory root, `audits/2026-11-09-trust-hosted-authority/` (its `README.md` lists each file).

**What the design says.**
- **Today there is no wall.** The token a session uses is the founder's admin token, felix-home's plan offers no rule on main (both APIs answer 403), and the lander's job file, the first directory on its PATH, the installed engine and the receipts are each writable by a worker (`logs/today.tsv`).
- **Ten rules** for the authority (design §4): one identity moves main; no worker holds the founder's identity; the decision reads the provider and no worker file; nothing that reads candidate bytes holds the credential; what is judged is what lands; and five more.
- **Seven decisions** that are Felix's (design §5.4). The first: the authority lands the commit it judged by fast-forward, and does not call GitHub's merge.
- **Budget** (design §6): about $0.73 for each landed change on GitHub's runners at the measured rates, with the judging job taking the place of the pull request's gate run.
- **Migration** in five stages (design §7). The identity split comes before the wall.
- **Nine calls are the founder's** (design §9). None is answered. A repository, an App, tokens, a ruleset, a plan, a host and keys each wait for his explicit yes.

**Measured, on the mock** (45 cases, written by one author and one reviewer on one day; an open set).
- **Wall on:** no worker's request moved main except through the authority, and no forged or replayed record was accepted. 23 refused, 13 held, 3 honest controls landed, 2 stopped the authority.
- **Wall off:** the six pushes to main landed and one moved main back. The verifier called each of those mains unverified, in both modes.
- **The review found a break** (X1): the kernel made the units' copy with `git archive`, which obeys the tree's own `.gitattributes`, so a hidden file landed unjudged with a genuine record. Fixing it found a second (X7): this Mac's filesystem folds case. Both are closed in the mock and are rule 5 of the design.
- **Still landing in the mock:** an instrument that takes candidate code into its own process (E7), and a label hold shed by sending the same commit up under a new branch name (H6).

**Not shown.** Whether GitHub refuses what the mock's provider refuses. `spike/wall-test.sh` asks GitHub, on a sandbox repository the founder would make, and has never run. Confinement on a Linux runner, Felix's own suite as the judge, and custody of the credential are not measured either.

**Follow-ups, not done here.**
- **The engine's run tree obeys the candidate's `.gitattributes`.** `lib/instrument-run.sh` (`_felix_instr_repo`) writes it with `read-tree` and `checkout-index`. On git 2.56.0 a blob under `working-tree-encoding=UTF-16LE` was written out as UTF-16, and a byte search of the copy missed text the blob holds. Whether a guard of Felix's suite can be passed that way is not measured. This Mac's filesystem also folds case under those units. Both belong to step 3.
- **The 11-07 design's §5** names GitHub's merge queue for the final merge. For a private repository that needs Enterprise Cloud (design §10 lists this and three smaller corrections).

**Release.** None: documents only. The pull request is labelled needs-founder for the nine calls.
