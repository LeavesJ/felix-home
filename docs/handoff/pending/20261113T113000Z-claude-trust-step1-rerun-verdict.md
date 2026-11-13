### 2026-11-13: step 1's pre-registered rerun ran, and the method does not advance (trust step 1, a measurement; nothing in the engine or the specification changes)

**What this is.** The rerun that the trust-plane specification's revision 1 defers to (part 2 §5.4), asked for by step 1's report. It answers one question: whether the method as revised (a model for each need, spec oracles written blind, a review packet without findings) advances to the prospective trial of direction row 39. It was pre-registered on 2026-11-08 and run on 2026-11-13, 02:55Z to 10:42Z, from a folder outside the founder's home so that no agent in it saw Felix's memory index. The founder chose that day to run it ("Now, from a clean folder (Recommended)"). The pre-registration, ledger, frozen tools, cases, runs, scoring and report are in the memory root, `audits/2026-11-08-trust-plane-step1-rerun/`; the report is `report/step1-rerun-report.md`, with its PDF beside it.

**Scope.** This section records the verdict and what the pre-registration says follows from it. It does not say what the method's next revision is, and it does not change `docs/direction.md` or the specification.

**The verdict: the method does not advance.** Four of the five gating bars held and one missed, on 18 fresh cases (36 subjects: a defective variant and its clean twin) in bash, Python and TypeScript, one run per subject, one executor model.

| Bar | Result | Threshold |
|---|---|---|
| H1 recall, by a part of the method | 18/18 | at least 11/18 |
| H2 caught by a mechanical part with a failing run | 18/18 | at least 7/18 |
| **H3 clean subjects with a false block** | **8/18** | **at most 4/18** |
| H4 recall in each ecosystem | 6/6, 6/6, 6/6 | at least 2/6 each |
| H5 omissions caught | 9/9 | at least 2/9 |

- No seeded defect was waived by a model. H2-strict (a class or tier check, reported and not gating) was 18/18 by the scorer's reading of each check.
- The coordinator reads five of the eight false blocks as false without doubt and three as arguable, so the miss does not rest on the arguable calls. The count comes from one scorer's calls, 27 of them marked unsure, and the report puts it between 5 and 8.
- Step 1 had 5 of 18 against the same bar. The two runs differ in set, authors and method together, so the two counts are not a trend.

**What the rows show about the miss** (the report's §3 and §4). This describes this set. The three method changes, the new set and the new authors moved together, so it attributes nothing.
- The blind oracle blocked six of the eight clean subjects, and rule rows the executors wrote blocked seven. Five were blocked by both.
- Examples of what a false block looked like: an oracle stricter than the spec's letter (s17, where it counts a line break after `<br>` as body text); a fault the case's Deployment text does not meet (s26, s20); an input no caller produces (s02, s24).
- s26's three rows inject faults its model does not mention. They read `unknown`, and `unknown` blocks under MD5.
- Without the model three more clean subjects would have been blocked, for 11 of 18.
- Of 77 blocking rows in the run, 35 were false and 42 were hits.

**What follows, by the pre-registration's §11.**
- The prospective trial (direction row 39) and the class-rule catalogue (design step 6) keep waiting.
- A further revision of the method needs a new pre-registration and a new fresh set, because this set has been seen.

**Not shown** (the pre-registration's §12 and the report's §8).
- A rate: at these counts the intervals are wide.
- Which of the three changes moved a number.
- Recall where the trigger is not handed over. In 12 of the 18 cases the Deployment text states the triggering input as a fact, so recall may be flattered. The 6 cases without that were also caught.
- Executor variance, a second scorer, or a second model.
- That qualification stops a wrong oracle: it is the writer's own reference and seeds, and it did not stop oracles that fail the author's clean variant.
- The review arm: it was not blind to the findings and was starved on nine packets, so its 11 of 18 is not read.

**Cost.** 46.45M input-equivalent tokens at the ledger's last row, against an estimate of 20.5M and a first budget of 24M. The run held at 17.4M in stage 2; the founder raised the ceiling to 50M and kept the briefs as frozen ("Finish now, as planned", 2026-11-13T06:59:48Z). The oracle writers and the executors took 28.0M of it between them. 2,473 CPU-seconds were metered, against a limit of 1.5 CPU-hours. The pre-registration priced the run as "2.7% of a 905M week"; by the plan's own meter that day a point of the weekly window was about 2.7M tokens, which puts the run near 17 points.

**Deviations from the pre-registration** are listed in the report's §7. Among them: the budget, by the founder; a timeout rule added before any official run (a run that ends in a timeout, a status 2 or an error case is rerun alone before it counts); two oracle writers started under a cost note, stopped 3 min 45 s later and replaced by fresh agents on the frozen brief; one writer resumed after a network error; an app quit between the review and the scoring, with no agent running.

**Open.**
- The method's next revision and its pre-registration. Felix's design call; not made here.
- Whether the false-block bar is read from one scorer again. The count's range (5 to 8) comes from that.
- `docs/direction.md` row 39 and the design's step 6 are unchanged by this section. They read as waiting on a rerun pass, which did not come.
- The design's steps 4 and 5 do not read this result and go on.
