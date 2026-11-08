### 2026-11-08: the trust-plane specification, revision 1: a model for each need, spec oracles, and a review packet without findings; the step 1 rerun is pre-registered

**Why.** Step 1 of the trust-plane design replayed slice 0 against a blind held-out set on 11-07, and its verdict was **do not advance**. Recall was 18 of 18, but 5 of the 18 clean twins drew a false block against a limit of 4. Of the 18 catches, 10 were class checks (an oracle swept over inputs) and 8 were a single scenario. None came from a fault tier at enumerated sites or from a mutant. The report (`~/.felix/memory/felix/audits/2026-11-07-trust-plane-step1/report/step1-report.md`, §6) names three method changes and calls them Felix's to make. The specification (#493) was written in parallel and had none of them. The founder accepted the design (row 50) and put trust rework first (row 51). This work makes no founder decision, since design questions are Felix's.

**Where the trust plane stands now.**
- **Design step 1 did not advance the method.** A rerun on a fresh blind set has to pass the same bars first.
- **The prospective trial (row 39) and the catalogue (design step 6) wait for that rerun to pass.**
- **Design steps 3 to 5 do not depend on the method** (separating the authority, the queue owning landing, sharding the suite) and can go ahead.
- **Nothing is built or armed.** The specification binds the method's tooling and the catalogue, and no blocker rests on it.

**What the specification says now** (`docs/2026-11-07-trust-plane-spec.md`, `-spec-evidence.md` and `-spec-mappings.md`, revision 1; PDFs in `docs/pdf/`).
- **A model for each need** (change 1; part 2 §1.8, MD1 to MD9).
  - A need may state which faults and inputs its deployment meets. A failing case counts `outside` only by a positive reading: a fault class read `not_met`, or a domain predicate that rejects the value. Anything unreadable counts inside and blocks.
  - The authority derives the result from the cases and the model. A failure whose every failing case is `outside` is advisory, and is printed and counted.
  - A model needs an author who did not produce the change, a ground, and a passing model control. An unqualified model reads as not stated.
  - Removing a model or an exclusion tightens, and any other edit loosens. A proven outside case suspends the model at the new scope `model`.
  - A model arms nothing by itself: until the founder's arming rules hold, the receipt prints the result both ways and the one without the model decides.
- **Spec oracles** (change 2; part 2 §5.2, SO1 to SO7).
  - A spec oracle is a checker kind written from the requirement alone, with a `blind` author context read from the dispatch and not from the author's word.
  - A kind is read from the qualification's seeds, not from a label: it takes seeded violations at two or more distinct sites. Step 1 found that the labels often misdescribed the checks.
  - Until leases exist, no checker has a verified `blind` context.
- **The review packet carries no findings** (change 3; part 2 §5.3, PK1 to PK5). A program refuses a packet that holds one, the review is advisory, and its own contribution is measured apart.
- **Status** (part 2 §5.4). The method does not advance until a pre-registered rerun passes. Fault tiers and mutants stay in the method with their contribution unmeasured: they ran on a fraction of step 1's subjects.
- **Part 3:** a new mapping (§1.6), three changed rows in §2.2, decisions D31 to D37, eight open questions and four risks.

**The rerun is pre-registered and not run.** The pre-registration is `~/.felix/memory/felix/audits/2026-11-08-trust-plane-step1-rerun/prereg.md` (PDF beside it), written before any case exists.
- **Bars:** step 1's H1 to H6 and its scoring rules, unchanged.
- **Set:** 18 new cases from six fresh authors, two for each of bash, Python and TypeScript. They are told which 17 defect families to avoid. Each case's spec gains an Interface and a Deployment section.
- **Method under test:** blind oracles and a model for each case, written by separate agents from the spec alone, and a packet that a program checks.
- **Budget:** an estimate of 20.5M input-equivalent tokens (range about 16M to 25M), a budget of 24M, and a stop at 26M. Stage checkpoints are read from `felix cost` between waves, and a missed checkpoint halts the run and asks. Step 1 spent 24.4M against 20M.
- **The historical set is not rerun.** Its gaps belong to the catalogue.

**Context hygiene, tested on 11-08.** The founder asked that his memory index stay out of the authors' context.
- A child `claude -p` process cannot log in from the app's shell.
- An `Explore` subagent showed neither of two memory-index phrases, but refuses to write files. Its hook text is untested.
- A `general-purpose` subagent showed the memory index, and it is the route step 1 used.
- The planned route, untested, is a coordinator session started from a scratch working directory outside `~/Documents/Felix` and `$HOME`. A canary gates the run (prereg §6).

**What the next fold should carry** (do not edit `docs/direction.md` in this pull request; any change to it waits for the founder's yes):
- A line that design step 1 did not advance the method, and that row 39's prospective trial waits for a rerun that passes.
- The rerun's budget, once the founder has seen it.
- The mappings that #493's part 3 §2 already says are owed to the next fold.

**Follow-ups, not started.** The rerun itself, from a coordinator session on a clean working directory. Design steps 3 to 5.
