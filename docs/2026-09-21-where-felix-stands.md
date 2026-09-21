# Where Felix stands, 2026-09-21

Four outside reviews arrived in one day. The reviewer had read the design
documents and an analysis of the founder's Claude Code usage. The first two
reviews were about session lifetime. The third was an opinion of Felix. The
fourth set out a "10x-better-model" test and was supplied as two PDFs: an
assessment of Felix as a control plane, and a usage analysis. This document
checks what they said against the transcripts, the code and the binding
architecture. It records where Felix actually is, and places what the
analysis found into the queue that was already decided.

Nothing here changes v3.2, the conformance amendments, or the queue order of
[direction-decisions](2026-09-19-direction-decisions.md) §5. The work was five
multi-agent workflows (24 agents). Four ended with a skeptic told to break the
lead's position. The README study ended with a claim-checker and a cold
reader. A sixth workflow fact-checked this document and the README before
either merged. Several of my own positions did not survive, and the
corrections are recorded where they happened.

## 1. Bottom line

- **The idea holds up.** Felix is aimed at what has been proven, against
  which revision, what is unknown, and who may authorise. Those are the
  questions most likely to survive better models. That is argued here, not
  measured (§2).
- **What the 10x test found.** The inventory's lead classed 53 of the
  engine's 98 mechanisms as durable, 31 mixed and 14 compensatory. By code
  that is 53% durable, 30% mixed and 10% compensatory, with 7% shared
  infrastructure, out of 19,016 lines. The skeptic disputed about a dozen
  labels. Most were durable rows whose in-session carrier is compensatory. So
  53 counts durable intent, not durable enforcement.
- **Enforcement does not hold up yet.** The durable logic mostly runs on the
  agent's side of the line. The hooks inside the session, the local unsigned
  receipts and a client-side `felix merge` are a floor against a careless
  agent. The wall is a required server-side check that re-runs the gate. It
  exists on 1 of the 5 repositories Felix governs on this machine, and not on
  Felix itself. On the one repository that had it, Elenchus, it has probably
  been broken since 2026-09-13 (§5.1).
- **The usage data cannot show that Felix makes work better.** Governance is
  collinear with time: no ungoverned human session starts after 2026-08-25.
  What it shows is that governed work fans out far more per human prompt,
  mostly through Workflow subagents. Coordinator context rose; it did not
  fall. No outcome measure exists in the data.
- **The biggest defects are in handoff and state, not long context.** Long
  sessions showed no measured quality loss. Handoffs produced the recorded
  failures, and the analysis found more latent ones (§5).
- **Measuring our own usage found material improvements**, all inside the
  v3.2 path:
    - repair the handoff before encouraging restarts;
    - record session lifecycle before the ECC hooks go off;
    - put the judging engine's identity on the receipt;
    - stop resuming large idle sessions;
    - split or index the engine's large files and HANDOFF.md. Reading them is
      about half the growth in Bash calls, and the three largest alone are
      about a fifth to a quarter of it;
    - move the wall to where the agent cannot write.

## 2. What the reviews got right, and what they got wrong

| Claim | Verdict |
|---|---|
| Felix is aiming at governance, not agent execution; Capability and Trust planes | Right as direction ([direction](2026-09-19-direction-decisions.md):8-19). Not built: no `felix dispatch`, no leases |
| Large coordinator context is not shown to be harmful | Right. Late-session tool errors are lower (2.98 → 1.59 per 100 calls). Forgetting-type re-reads are near zero. Pushback per human message is flat |
| Handoff is a bigger risk than long context | Right. Every direct-strength recorded failure is a handoff failure |
| Don't resume large sessions after the cache has expired | Right. 211 resumes after more than 1h idle rewrote the whole context, 131 of them over 400K. That is about 12% of coordinator input cost |
| An engine promotion should end a session's life | Right in substance. The design is narrower than the review; see §6 |
| The routing mechanism was measured at about 2% and demoted | Right, with caveats: n=8 applicable, and the role was re-scoped, not deleted ([advisory redesign](2026-08-30-advisory-redesign.md):36-49) |
| Situation triggers and the stopping rule should own coordinator lifecycle | Wrong. Spec §10 governs discovery depth over the subject, per epoch. The session belongs to the Execution Coordinator and, for leases, to the Capability Manager |
| v3.2 treats evaluator promotion as an explicit trust transition | Wrong as a statement of v3.2. It is true of Felix's own design notes ([promotion-spec](2026-08-18-promotion-spec.md):121-143), which scope running sessions out (:212-222) |
| Felix cut main context from 462K to 436K and improved context per output | Wrong. The drop is an artifact of automated review sessions in the denominator; human sessions went 462 → 450 → 479K. The context-per-output gain is composition; coordinator context per output did not fall |
| Commissioned Felix: +34% turns and +91% Bash per human prompt | Understated. The report's "prompts" include task notifications, Felix's own Stop-hook messages, and 158 automated sessions. On real prompts it is +177% and +304% |
| Evidence bound to exact repository state is a differentiator | Not novel (AI-SDLC, Entire, GitHub stale approvals). The novel part is staleness on inputs outside the tree |
| An agent cannot grant itself authority | True only where main is server-protected. False on felix-home today |
| Better models make Felix more relevant | Plausible for the rules and the judge, but not measured. The durable parts have never been tested against a capable or adversarial worker |

## 3. The usage, measured

The data is Claude Code transcripts from 2026-06-22 to 2026-09-21. There were
24.9K coordinator turns averaging 450K of context, and 62.3K subagent turns
averaging 110K. That is about 18.1B accounted tokens, 96% of them cache reads.
An independent parser reproduces the outside figures to within 0.3%. These
figures are private and stay out of the public README.

**Session lifetime.**

- Restarting at the first clean boundary past about 500K saves an estimated
  18-28% of coordinator input cost, about 9-15% of the total. That estimate
  uses the measured cost of a fresh start: 95K at call 1, +85K over 20 calls.
- A 350K line saves anywhere from 34% to nothing, depending on how long
  re-orientation takes.
- Every compaction was automatic, at about 967K. ECC's compact nudge fired 88
  times and nothing followed it.
- Plan limits do not publish how cache reads count, so none of this converts
  to usage limits.

**The phase comparison, re-tested.** The comparison used strict human
prompts, human sessions only, and Opus 5 as the dominant model. The phases
are P0 (to 08-10), P1 (08-11 to 09-03) and P2 (09-04 to 09-21).

| Opus 5, per human prompt | P0 | P1 | P2 |
|---|---|---|---|
| model turns | 68.9 | 71.6 | 214.9 |
| tool calls | 75.3 | 92.3 | 277.5 |
| subagent share | 73.1% | 65.4% | 82.4% |
| output tokens | 55.9K | 80.8K | 211.7K |
| main context, mean | 439K | 449K | 496K |

**What survives:**

- Output per prompt rises under every test: model fixed, same project, same
  period.
- Bash per turn rises from 0.70 to about 1.0.
- Aggregate context per output falls, but as composition, not coordinator
  efficiency.

**What does not survive:**

- The rise in subagent share. It falls when governance arrives and is flat
  within projects.
- The report's fall in main context.

**Why the jump happened.** The P1 → P2 jump is the Workflow tool.
Workflow-subagent turns per prompt went from 43.6 to 132.3, which is most of
the rise. As a share of all turns that is 63% to 77% (32% in P0). The Workflow
tool is a Claude Code capability, not a Felix one. The phase with no ungoverned human sessions is
also the phase in which Felix was mostly building itself: 81% of its prompts.

**Where the Bash went.** Of the increase, 69% is reading.

- About two-thirds of that is reads of Felix's engine files and HANDOFF.md,
  mostly subagent `sed -n` windows.
- The three largest files account for roughly half of those reads:
  engine/harness/tests/run at 15,243 lines, HANDOFF.md at 6,373 and
  engine/harness/felix at 4,944. Reads of lib/, bin/ and hooks/ account for
  the rest.

The other shares:

- Felix governance subcommands and gh calls together add about 11% (the
  subcommands alone about 5%).
- Gate friction (ECC GateGuard) adds about 6% on the same basis, or about 2%
  on strict human prompts.
- Project test and build calls fell, plausibly because they moved behind
  `felix gate`.

The Bash error rate stays near 2%, and exact repeats fell (0.61, 0.22 and 0.28
per prompt), so this is not churn. It is reading that a smaller file layout
would shrink.

## 4. Where Felix actually is

**Durable and compensatory.** Expected to die with better models:

- the keyword routing stack (route.sh, 645 lines, routes.tsv, profiles.tsv,
  the route block in user-prompt, the skipped-play branch in Stop);
- the lessons mount by keyword;
- the graph line;
- the subagent notes;
- the verify-before-done nudge.

Each has a deletion signal recorded in the workflow output. The data already
leans that way. In 418 sessions where Felix named a capability, it was
reached in the same session 24 times. MCP reaches were 44 of 44 without
Felix naming them.

Deleting the router is a charter change: [the constitution](../projects/felix/CLAUDE.md):22-27
claims "which MCP, which plugin, which skill" as Felix's job. It goes to the
founder at Decision B's 20-session review.

**Floor and wall.** The following hold against a worker that ignores Felix,
and only where main is server-protected:

- exception grants and obligation admission, which are read from
  `refs/remotes/origin/main`;
- model proposals never becoming authority;
- a verdict recomputed by a required check.

The following depend on the host calling the hooks and the worker not being
hostile:

- every `deny.tsv` refusal (fail-open by design);
- the Stop hold ("a speed bump");
- local receipts and review verdicts, which are unsigned files that any
  same-user process can write, and no deny row covers `state/`;
- `felix merge`, which runs client-side and which `gh pr merge` skips;
- the audit trail itself: a host that skips the hooks leaves no rows, and no
  rows looks like nothing happened.

**Host coupling.**

- 36 of 49 libraries carry no Claude-specific marker, and most Trust Plane
  libraries are among them. commission.sh is the exception: it binds the
  claude CLI's identity into the commission receipt.
- About 520 hook lines carry the durable parts, and would become a lease's
  allowlist, completion condition and launch context.
- Codex's hooks are close to drop-in, about 3-5 sessions of adapter work.
  Its `apply_patch` silently bypasses today's Write and Edit deny rows.
- The Capability Plane is v3.2 step 5 sized for any second host.

**Status.** The README's status section is the public version. The honest
short form:

- the Stop hold, receipts and epochs, the merge escapes, blocking UNKNOWN and
  commissioning are built and exercised;
- exceptions, model-proposed obligations and unattended repair are built but
  never exercised on real input;
- dispatch and promotion as its own step are designed;
- sandbox, leases, revocation, situation triggers and the stopping rule are
  absent.

## 5. Defects found

1. **Elenchus's only required check is probably broken.** gate.yml on
   Elenchus main checks out `repository: LeavesJ/felix` with no ref.
   - Since the 2026-09-13 rename, that name resolves to the public
     LeavesJ/Felix. The public repository carries no Elenchus binding, so the
     deploy-key clone or `felix which` fails. The deploy key is felix-home's.
   - This is inferred: no main-path gate has run since 2026-09-04. The next
     Elenchus PR that does not change gate.yml cannot merge.
   - LeavesJ/Elenchus#20 repoints the checkout at felix-home. Its gate is
     green, and it awaits the required review.
   - A local, unpushed branch pins `561b998`, which LeavesJ/Felix does not
     have (HTTP 422).
2. **`felix handoff` truncates hand-written handoffs.** Elenchus's 212,864-byte
   hand-written SESSION_HANDOFF.md would be truncated to a generated file of
   about 1.3 KB (565 bytes in the scratch reproduction). The command keeps no
   backup (lib/memory.sh:77); only the pulse history in `~/.felix` still holds
   the original. The fix must land before queue item 4, which runs by hand on
   Elenchus. A task was spawned.
3. **Session start calls the handoff "standing direction that has already
   been decided"** (session-start:402-403). That is the opposite of the
   doctrine, and it plausibly helped a stale blocker get copied forward.
   HANDOFF §0bm records that blocker as copied from §0bl, recalled rather
   than read. Covered by the same task.
4. **SessionStart does not fire on resume** (hooks.json:54, unchanged since
   cce90c0). A resumed process rebinds hooks, but Felix never hears of it.
   Covered by the same task.
5. **SESSION_HANDOFF.md names its writer's checkout, and twelve checkouts read
   it.** Today's copy says `branch: HEAD`, because the writer was on a
   detached HEAD. It also names the writer's worktree
   (felix-v3-2-rearchitecture-dd90dc), because `tree` records whichever
   checkout ran `felix handoff`. The note is carried forward with no origin. Its "only #124 open" was false when written: #265
   and #267 were open. Issue #31 is still open. Its scope note forbids keying
   memory per tree.
6. **Receipts and review verdicts can be forged by any same-user process.**
   The deny table does not cover `$FELIX_HOME/state/`. Inside a session this
   is a floor against carelessness, not a guarantee.
7. **Queue item 1 removes ECC's resume markers and its cost file.** Item 1 is
   finished by item 3. It turns off ECC's `session:start` and `cost-tracker`
   hooks, which removes ECC's resume markers and its costs.jsonl. Ruflo's
   SessionStart hook supplies most resume markers (159 of 195), and no queue
   item turns it off. Felix records neither today.
8. **The Stop hook's comment says the inescapable barrier is CI, which Felix
   already sets up** (stop:18-19). That is true for 1 of 5 governed
   repositories. `felix bootstrap` writes protection with
   `enforce_admins:false`.
9. `felix new` wrote invalid project.json whenever FELIX_MATURITY was set, on
   any bash. #268 fixed it; it merged on 2026-09-21 and was deployed as
   0.49.125.
10. **The Stop refusal offers `exceptions.tsv` to every project** (stop:461-463),
    but grants work only when Felix governs itself. Its wording also says
    "the founder" to every adopter. `qualify.sh`'s header still says "REPORT
    ONLY", although the gate refuses on an unmet control.

## 6. Decisions: where the improvements go

The queue order stands. Items whose substance is a new table wait for the
table validator (queue item 2). Small fixes to existing code do not.

**Now, before queue item 2:**

- the handoff overwrite guard, the session-start wording and resume in the
  matcher (defects 2-4);
- review and merge LeavesJ/Elenchus#20 (defect 1).

**Before queue item 1 takes effect:**

- A minimal lifecycle recorder. It is a new store, so rows-first would
  otherwise hold it for item 2. Either the founder leaves ECC's
  `session:start` and `stop:cost-tracker` out of the step-1
  ECC_DISABLED_HOOKS list until the recorder lands, or the recorder lands as
  a dated exception to rows-first.
- The recorder writes `~/.felix/memory/<project>/lifecycle.log`, separate from
  the ledger, with two kinds of row:
    - a start or resume row: session, source, bound engine, installed engine,
      HEAD, handoff hash, transcript path;
    - a `felix handoff` row: hash and reason.

    Everything else a later evaluation needs can be derived from transcripts.

- Fix #264 before computing any per-session rate.
- The analysis scripts behind this document were copied to
  `~/.felix/memory/felix/audits/2026-09-21-usage/`, which pulse commits. They
  belong on the suite's side once the recorder exists.

**With queue item 2 (table validator, schemas.tsv, coverage.tsv):**

- schema rows for `lifecycle.log` and the handoff stamp, so both sit on the
  validator.

**After item 3, before item 4:**

- A stamp block in the handoff: UTC time, repo, tree, branch or `detached`,
  full sha, tree id, engine, deployed engine, receipt state, note origin, and
  verify commands.
- One reader at SessionStart that reports stale reasons in the
  `felix_verify_current` idiom and never blocks, plus `felix handoff --check`.
- The banner states "Engine X (promoted Y)", and Stop says "hand off" when
  the engine is the reason.

**With queue item 4:**

- A validator field on the receipt, naming the engine that wrote it, with
  invalidation by selector (spec:243, 259).
- **Engine identity does not go into the decision epoch.** That would stale
  every project's receipts on every deploy and break spec:124-129. My draft
  proposed it, and the skeptic was right.
- From the next version on, product merges refuse when the invoking CLI is
  older than the promoted one. That narrows stale-judge exposure.
- It does not close the FELIX_KERNEL hole. That hole is in Felix's own merges
  run by an old CLI still in the plugin cache (0.49.121 and older), and new
  code cannot change what shipped code does. Removing or refusing superseded
  cache entries closes it, and so does the server-side check.

**Queue item 5 (`felix dispatch`), unchanged:**

- Leases run no hooks, so engine currency holds by construction. Dispatch
  does not widen stale-engine exposure, which my draft wrongly said it did.
- The lease and result record is the template the coordinator handoff stamp
  mirrors.
- The one legitimate §10 lifecycle is how many discovery leases run per
  epoch.

**New, and not in the queue before:** split or index engine/harness/tests/run,
engine/harness/felix and HANDOFF.md.

- Reading the engine's files and HANDOFF.md is about half the growth in Bash
  calls, and these three are about half of that. Each breaks the global
  500-line rule several times over.
- HANDOFF.md becomes a short current-state file plus an archive consulted by
  section. Sessions already only slice it (median about 4K tokens at start),
  so this is about staleness and reading cost, not the start-of-session read.
- The CLI and suite split rides with rows-first. It is mechanical, and the
  suite must show it changes nothing.

**Off the queue, habits now:**

- Start fresh instead of resuming a large session that has been idle over an
  hour.
- Restart after any engine deploy.
- Treat about 500K as the point where the next clean boundary is a candidate
  for a restart. It is not a rule.

**Later:**

- Coordinator moments (engine-promoted, resume-after-idle) as rows in
  moments.tsv and procedures.tsv, spoken only at session start and Stop.
- An alternating continue / restart / compact experiment at eligible moments,
  judged by recall on the known misses, not by what fired.
- Then the compaction-window setting.

**The founder's:**

- The step-1 ECC settings edit, still not made on 2026-09-21.
- The fail-closed merge refusal for a session bound to a superseded engine,
  with #2 step 5. It changes the deploy-then-continue habit and rests on
  undocumented CLAUDE_PID and `.in_use` behaviour.
- A wall for felix-home. The plan tier blocks branch protection. The options
  are GitHub Pro or running the gate somewhere the agent cannot write. Never
  flip felix-home public.
- The router's charter change, at the Decision B review.
- Publishing the new README to LeavesJ/Felix.

## 7. What would change this assessment

- **An outcome measure.** Verified milestones per human prompt, missed
  escalations, handoff defects and stale-governance incidents. The north-star
  eval, one obligation's whole life replayed offline, is the first.
- **A control arm.** Governance cannot be separated from time with the data
  that exists. Alternating governed and ungoverned sessions on matched tasks,
  or holding one project ungoverned for a period, would give one.
- **A forgery test against the floor.** A scripted worker that writes a
  receipt, moves `refs/remotes/origin/main`, and merges with `gh`. Then record
  which of those a governed repository with a wall refuses.
- **A second host.** One Codex session under the deny and Stop adapters. That
  would turn "above the harness" from direction into a property.
