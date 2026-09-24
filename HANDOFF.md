# Handoff

Durable prose between sessions: what was decided, what shipped, and where the
next session starts. The mechanical state of a tree (branch, head, uncommitted,
recent commits) is `felix handoff`'s, in `SESSION_HANDOFF.md` under the memory
root, not here.

**How this file is laid out, since 2026-09-22.** It holds three things: §0,
the standing decision every session must know; the current state; and an index
of every earlier section, each kept verbatim in `docs/handoff/<id>.md`. The
file had grown to 6,445 lines, and reading it was a large share of the growth
in Bash calls (docs/2026-09-21-where-felix-stands.md §3). The split moved text
and changed none of it: the archive files concatenated in index order, after
`docs/handoff/_preamble.md`, reproduce the old file byte for byte (the sixty
files the split made; later sections join the index above them, below §0).

**The rule for the next session.** Write your section at the top of "Current
state", with the next id (after 0bw comes 0bx). Move the section it replaces
into `docs/handoff/<id>.md`, unchanged, and add its row to the top of the
index. A reference like "HANDOFF §0bm" means `docs/handoff/0bm.md`.

---

## 0. DECIDED 2026-08-14, AMENDED 2026-09-13 — this repository is private, and a snapshot of the engine is public

Unchanged; read [docs/handoff/0.md](docs/handoff/0.md). In one line: this
repository (`felix-home`) stays private because its history carries the memory
tree; the engine is published as a snapshot with no history at
`github.com/LeavesJ/Felix`, and never by flipping this repository public.

---

## Current state

### 0bw. 2026-09-23 — building Felix, measured as Felix's own workload; direction-level documents wait for the founder

**Nothing deployed from this session; no engine change.** The founder's point:
the founder brings an idea, sharpens it and judges it, the agent does the rest,
and that exchange is the model for how Felix works with every user. So the
history of building Felix is a record of that whole pipeline, from intent
through the work in between and the delivery to the outcome.

| PR | What |
|---|---|
| #316 | The episode pilot. Twenty episodes, weighted to the big decisions, reconstructed from the transcripts with each record checked and the report critiqued: `docs/2026-09-23-episode-pilot.md`, data and method in `docs/episodes/`. |
| #319 | **DECIDED by the founder.** Documents that change what Felix is, who it is for or its build order wait for his yes, and he rates each delivery in one word. Nothing else waits. Written into the split in `projects/felix/CLAUDE.md`. |
| #327 | Batch 2: the five episodes the pilot missed, plus two control sessions, with a second blind reader per turn: `docs/2026-09-23-episode-batch-2.md`. The prompt index and transcript reader now tell the founder apart from notifications and other sessions. |

**What the harvest found, briefly.**
- About a third of the founder's effort went into the agent's job. The pilot's
  figure is 31% by strict majority, but on turns both batches read the rate
  runs 42 to 49%. Selection moves the figure more than the counting rule does,
  so state both beside any rate.
- The largest kinds are needless stops, restated decisions and answering
  questions the agent should have decided. Report them as shares, with their
  label splits.
- The two readers agreed on 70% of labels. Their most common split was "go":
  an approval, or a push past a stop that should not have happened.
- The agent originated 60 decisions across batch 2's records. Several became
  the founder's chores: a twelve-table hash under the commission receipt and
  grant, per-project overnight state, and "the commission run is his".
- The new thing is checks fired at moments, not advice: pilot §7 as amended by
  batch 2 §6.

**Waiting on the founder.**
- Carried from §0bv: the Elenchus and Veldra candidates' admission, then #310's
  verifier escape, then #304 (all open on 2026-09-23).

**DECIDED 2026-09-23 by the founder (batch 2 §8), landed as #332 and rated
"good." (yes).** Status reaches the founder in the session's closing notice. The monitor stays as the deeper page. The
charter's stealth paragraph now says so. **The notice itself is not built yet,
and it is the first item below.** Until it ships, the charter describes
something the engine does not do, which is the failure the pilot found most
often.

**Next, Felix's to do (none needs the founder):**
- **Build the closing notice.** The Stop hook speaks to the agent, as
  `additionalContext`, and the agent relays it in its closing report.
  - Claude Code gives no "last stop of the session" signal, so the design must
    choose which stop carries the notice. The candidate is the stop where the
    gate receipt first matches the tree, then again only if status changed.
  - Contents: gate state on this tree, owner acts waiting in the queue, Felix's
    own friction this session (holds, refusals), and what is due.
  - It must respect the #322 limit on mid-session lines, and carry a deadline
    assertion in `tests/run`.
  - This is adversarial tier (`hooks/stop`).
- **Capture.**
  - `says.log` keeps whole prompts, or a pointer to the transcript line.
  - Question-tool answers are indexed.
  - `escalated` rows carry the session id (`felix:1441`) and are not written
    on `--dry-run`.
- **#319 has no mechanism yet.** Build a merge stop on roadmap paths and the
  charter's split section only, and never on an engineering path.
- **The interaction layer's first moments.**
  - The Stop hook reads the closing report for work handed back, and for
    "next is X" when X is approved work.
  - An `asked` row per question.
  - A decisions table with the originator, whether the owner was asked, and
    the owner cost stated at the time.
- **Lessons-ladder fixes (batch 2 §6).**
  - Mount the full headline, not the bare date (132 of 181 entries mount as a
    date).
  - Match on the prompt, not the envelope.
  - Give `mistakes.log` rows a session id.
  - `projects/felix/CLAUDE.md:160-163` and `felix:930` describe the ladder
    wrongly.
- **The next episode batch.** Apply the four codebook rules in batch 2 §4 first,
  and sample every session in a fixed week rather than choosing episodes.
- **Carried from §0bv.**
  - Control 7 after #310.
  - The request that names a gitignored doctrine.
  - #308, #309 and #311 (deny scope) and #312 (README), all still open.

**Traps paid for this session:**
- **A docs-only branch passes the gate only while its engine equals
  `refs/remotes/origin/main`.** Worktrees share that ref, and other sessions
  fetch it mid-run. Merge main, check
  `git diff --quiet refs/remotes/origin/main -- :/engine`, and gate at once.
  Two gates failed on this before the third passed.
- **Any `*.tsv` in the tree needs a `schemas.tsv` row, or `schema-check` fails
  the gate.** Put data in as JSONL.
- **At a load average of 100 to 140 the suite took over an hour, not ten
  minutes.** Watch your own gate's PID: a watch keyed on "any `felix gate`"
  never fires while other sessions are gating.
- **A workflow dies with the session process.** Resuming it with the same
  arguments re-ran finished stages under new cache keys. The first run's
  `journal.jsonl` already held every result, so finish from the journal.
- **The transcript reader printed task notifications and other sessions'
  messages as FOUNDER,** and the old prompt index counted peer messages as
  founder prompts. Both are fixed. The pilot, re-checked, holds no peer turns.
- **The fact gate refuses a force-push whatever facts are given.** Add a commit
  instead of amending.
- **A plain `cd` into `docs/episodes` in one Bash call moved the working
  directory for the calls after it.** Use absolute paths.

---

## Index of earlier sections

Newest first. Each file is the section exactly as it stood.

| § | Section |
|---|---|
| [0](docs/handoff/0.md) | DECIDED 2026-08-14, AMENDED 2026-09-13 — this repository is private, and a snapshot of the engine is public |
| [0bv](docs/handoff/0bv.md) | 2026-09-23 (night) — overnight mode belongs to a session, #307 and #303 landed, the runner probe answered from a runner's own log, Veldra's blind request |
| [0bu](docs/handoff/0bu.md) | 2026-09-23 — Phase 0: the Elenchus candidates checked, deny rows read the command the shell runs, three small items |
| [0bt](docs/handoff/0bt.md) | 2026-09-22/23 — the table validator (queue item 2, step 1) shipped, and a rename that hid an escape |
| [0bs](docs/handoff/0bs.md) | 2026-09-22/23 — Felix is a product for other people's projects, built first; the first obligations request answered blind; the roadmap |
| [0br](docs/handoff/0br.md) | 2026-09-22, closing — seven pull requests shipped and deployed, the public snapshot is a command and was brought forward, Elenchus has a working required check again |
| [0bq](docs/handoff/0bq.md) | 2026-09-22 — the recorder and #264 deployed, ECC step 1 complete, two branches in repair |
| [0bp](docs/handoff/0bp.md) | DECIDED 2026-09-21 — `projects/bazaar` is tracked, and its gate keeps its own log |
| [0bo](docs/handoff/0bo.md) | 2026-09-21 — four outside reviews checked against the transcripts, and where Felix stands |
| [0bn](docs/handoff/0bn.md) | 2026-09-19 — the endgame affirmed, and three direction decisions taken on evidence |
| [0bm](docs/handoff/0bm.md) | 2026-09-18 — the public snapshot brought forward and found uninstallable, and ECC read against v3.2 |
| [0bl](docs/handoff/0bl.md) | The session of 2026-09-17/18, whole — what shipped, what waits on one command, and where the next session starts |
| [0bk](docs/handoff/0bk.md) | Verified at session close, 2026-09-17 (night; 2026-09-18 UTC) — the judge is pinned outside the tree it judges, and a fixture that modelled the hole had to be rebuilt honest |
| [0bj](docs/handoff/0bj.md) | Verified at session close, 2026-09-17 (late) — the exception channel exists, read from the remote-tracking main, and six readers of the design found what one author could not |
| [0bi](docs/handoff/0bi.md) | Verified at session close, 2026-09-17 — the red count is a file in the tree, the gate has one reader of the deploy question, and the distance to v3.2 re-measured off the tree |
| [0bh](docs/handoff/0bh.md) | Verified at session close, 2026-09-16 (closing) — the session's own record, audited: eleven claims false, twenty-six stale, and what six sections left out |
| [0bg](docs/handoff/0bg.md) | Verified at session close, 2026-09-16 (late) — an obligation nobody named can exist now, and nothing admits it but a person |
| [0bf](docs/handoff/0bf.md) | Verified at session close, 2026-09-16 (night) — the ledger asks what main accepted, the same question as the gate |
| [0be](docs/handoff/0be.md) | Verified at session close, 2026-09-16 (later) — the receipt carries the epoch, and a fact that moves outside the tree stales it |
| [0bd](docs/handoff/0bd.md) | Verified at session close, 2026-09-16 — an ask that crashes is unknown, and the probe gate is a checker |
| [0bc](docs/handoff/0bc.md) | Verified at session close, 2026-09-13 (night) — Felix merges its own pull requests, and the engine stopped saying otherwise |
| [0bb](docs/handoff/0bb.md) | Verified at session close, 2026-09-13 (afternoon) — #233 built, and a review reversed its central decision before it merged |
| [0ba](docs/handoff/0ba.md) | Verified at session close, 2026-09-13 — the engine is public, and the repository it came from is not |
| [0az](docs/handoff/0az.md) | Verified at session close, 2026-09-12 (overnight) — seven branches, and three things that were false before anybody checked |
| [0ay](docs/handoff/0ay.md) | Verified at session close, 2026-09-12 (night) — the standing direction became a mechanism, and two probes caught what reading could not |
| [0ax](docs/handoff/0ax.md) | Verified at session close, 2026-09-12 (late) — the history was cleaned, and the sweep found one commit that existed on one disk |
| [0aw](docs/handoff/0aw.md) | Verified at session close, 2026-09-12 — the upkeep ran, a fifth project appeared, and the graph dropped twelve edges without saying so |
| [0av](docs/handoff/0av.md) | Verified at session close, 2026-09-11 — the two provider rows answered, and a verify phase that ran out of session |
| [0au](docs/handoff/0au.md) | Verified at session close, 2026-09-10 — the graph was built three times and asked once, and the reason was a table |
| [0at](docs/handoff/0at.md) | Verified at session close, 2026-09-09 — the §0as queue built end to end, then reviewed, and every pull request in it changed |
| [0as](docs/handoff/0as.md) | Verified at session close, 2026-09-06 (late) — the first admission rule exists, and a blind control found the hole before anyone believed the checker |
| [0ar](docs/handoff/0ar.md) | Verified at session close, 2026-09-06 — the checker night: two grants, one caught at the boundary, and the distance to v3.2 measured |
| [0aq](docs/handoff/0aq.md) | Verified at session close, 2026-09-06 — three items the founder ordered, and a checker that does not catch what it protects |
| [0ap](docs/handoff/0ap.md) | Verified at session close, 2026-09-05 (overnight) — the measurement audit is closed, and one of the findings I closed it with was false |
| [0ao](docs/handoff/0ao.md) | Verified at session close, 2026-09-05 — the four high-severity audit findings are closed, and the manifest row says who grounded it |
| [0an](docs/handoff/0an.md) | Verified at session close, 2026-09-04 (overnight) — the provider protocol was exercised on real answers, and the admit phase grounds what a model names |
| [0am](docs/handoff/0am.md) | Verified at session close, 2026-09-04 — the first-encounter moment is a table, the two setup skills are rows in it, and the rows are waiting for a session |
| [0al](docs/handoff/0al.md) | Verified at session close, 2026-09-03 (overnight) — the substrate asks reality, and three of the checks written to prove it had never run |
| [0ak](docs/handoff/0ak.md) | Verified at session close, 2026-09-03 — the architecture is closed, and the floor has a one-line hole |
| [0aj](docs/handoff/0aj.md) | Verified at session close, 2026-08-31 (day) — the correction that matters is about method, not code |
| [0ai](docs/handoff/0ai.md) | Verified at session close, 2026-08-31 — Felix has a pulse, and three review rounds on it |
| [0ah](docs/handoff/0ah.md) | Verified at session close, 2026-08-30 (afternoon) — Decision C shipped, and the first review that ran before the merge |
| [0ag](docs/handoff/0ag.md) | Verified at session close, 2026-08-30 (day) — three decisions taken, and the new voice is live |
| [0af](docs/handoff/0af.md) | Verified at session close, 2026-08-30 (overnight) — the advisory layer measured, and the redesign on the table |
| [0ae](docs/handoff/0ae.md) | Verified at session close, 2026-08-30 — the review that was outstanding, and the gate that could not fail |
| [0ad](docs/handoff/0ad.md) | Verified at session close, 2026-08-29 (late) — a defect found, and the instrument that nearly hid it |
| [0ac](docs/handoff/0ac.md) | Verified at session close, 2026-08-29 — a second project, and what it broke the same day |
| [0ab](docs/handoff/0ab.md) | Verified at session close, 2026-08-28 — the backlog was verified, and a third of it was wrong |
| [0aa](docs/handoff/0aa.md) | Verified at session close, 2026-08-27 — nine fixes, and what finding them taught |
| [0z](docs/handoff/0z.md) | Verified at session close, 2026-08-25 — the instrument was broken, and every number below it |
| [0a](docs/handoff/0a.md) | Verified at session close, 2026-08-18 |
| [0b](docs/handoff/0b.md) | DECIDED 2026-08-18 — issue #2 is "make promotion real", and the spec is unwritten |
| [0d](docs/handoff/0d.md) | DECIDED 2026-08-18 — the streak reads "Earned." and the founder says not yet |
| [0c](docs/handoff/0c.md) | What this session established about how Felix should work |
| [1](docs/handoff/1.md) | Standing direction — decided, do not ask again |
| [2](docs/handoff/2.md) | State as of 2026-08-11 |
| [3](docs/handoff/3.md) | Operational traps that have each cost real time |
| [4](docs/handoff/4.md) | Guidebook exit criteria (p41) |
| [4b](docs/handoff/4b.md) | Playwright: assessed 2026-08-11, deliberately not adopted |
| [4c](docs/handoff/4c.md) | Self-diagnosis, and the ceiling on it |
| [5](docs/handoff/5.md) | Next, in leverage order |
| [5a](docs/handoff/5a.md) | Session of 2026-08-13/14 — what shipped, and what it cost |
| [5b](docs/handoff/5b.md) | What is now tracked as an issue |
| [6](docs/handoff/6.md) | Open decisions |
| [7](docs/handoff/7.md) | Approaches already tried and rejected |
| [8](docs/handoff/8.md) | The failure mode this project keeps having |
