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
state", with the next id (after 0by comes 0bz). Move the section it replaces
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

### 0by. 2026-09-23/24 — restart moments scoped and placed: step 1 names a session running an older engine, and the founder allowed one line mid-session

**No engine change from this session, and nothing deployed.** The installed
engine was 0.49.162 when this was written. A session's start banner can name an
older one (see Traps). The open items of §0bx, #325's section, stand: the
landing actor, and the carrier session's no-escape queue. Read
[docs/handoff/0bx.md](docs/handoff/0bx.md).

| PR | What |
|---|---|
| #318 | `docs/2026-09-23-restart-moments-scope.md`, the step-1 scope. Five readers; three independent scopes, each attacked by a skeptic; a judge; a completeness critic |
| #322 | The roadmap places step 1, and the constitution's stealth paragraph carries a narrow exception. Under #319, direction-level documents wait for the founder's yes; he said yes, and then #322 merged |

**The question, and the answer.** The founder asked whether Claude or Felix
can start a new session on its own. The answer is not today, and step 1 does
not either. Measured against the code and the platform:

- **Engine behind** is step 1. A session's hooks run an older Felix than the
  one installed.
  - The remedy is `/reload-plugins`, which keeps the conversation. It is not
    a restart and crosses no handoff.
  - One reader counted 57-78% of Stops this week running a superseded
    engine. This is scope §1's figure, and not reproducible from the tree.
  - It reaches one of the three known misses, a session that deployed and
    kept misrouting. They are listed in
    `~/.felix/memory/felix/audits/2026-09-21-usage/known-misses.md`.
- **Idle resume** is recorded only. On desktop the resume hook runs after the
  prompt is sent, so nothing said then saves the cache write.
- **A restart past about 500K** is step 2. Scope §7 lists six prerequisites.
  The first is the handoff repair from
  `docs/2026-09-21-where-felix-stands.md` §6 (a stamp, `felix handoff
  --check`, a start-of-session reader). It is still unscheduled; roadmap §6
  lists it as the founder's open question. The third, the evidence in the
  tree, is now on disk (below).

**Founder decisions, 2026-09-23:**

- **One line on his screen mid-session is allowed.**
  - Once per session, at a stop where Felix says nothing else.
  - As a `systemMessage` that starts no model turn, naming
    `/reload-plugins`.
  - It stays off until he has seen the line render.
  - The constitution's stealth paragraph carries the exception. Any other
    mid-session line needs the decision again.
- **He left placement to Felix** (roadmap Phases 0 and 1):
  - **Step 1a is at the end of Phase 0** (Sep 23 to Oct 4). It detects the
    moment in shadow, and a stderr line points `felix gate`, `handoff` and
    `merge` at the installed CLI.
  - **Step 1b is in Phase 1**, outside the forced-order judge items listed
    there. It comes after at least 7 days and 10 `behind` rows of 1a in
    shadow, and after #310, which is CONFLICTING and waits on his verifier
    escape.
  - **Step 2 is unscheduled.**
- **Still his:**
  - the 10-minute probe look (scope §3, checks a and d); his word was
    "later", and "before Oct 12" is the roadmap's suggestion;
  - whether the handoff repair is scheduled;
  - later, whether Felix may ever call the desktop's `clear_session("self")`;
  - from 09-21, a merge refusal for a session bound to a superseded engine.

**The 09-21 evidence is on disk and not yet committed.** A spawned session
copied it out of `/private/tmp` into `~/.felix/memory/felix/audits/2026-09-21-usage/`.
It survived today's reboot. Its `README.txt` gives the cutoffs that reproduce
the runs published in `where-felix-stands` §3:
- `known-misses.md`;
- `idle.py`: 211 resumes after more than an hour idle, 131 of them over 400K,
  12% of coordinator input;
- `replay.py`: a fresh start measured at 95K on its first call and +85K over
  20 calls. Restart savings with 20 re-orientation calls are 350K -34%, 500K
  -28% and 700K -18%; with 40 calls they are 0%, -18% and -12%.

`felix pulse` commits that folder but is not scheduled on this machine. The
check is `git -C ~/.felix/memory status -- felix/audits/2026-09-21-usage`.

**Agreed with the session that built #307.** Step 1's Stop code will record
nothing inside a night's chain. `CHAIN=1` is #307's mark for the platform's
continuation after a hold. While the session owns a live night, it will
record `unsaid:night` and retry after the night (scope §4.2).

**Next, unowned:**
- **Step 1a:** 1.5-2 sessions, adversarial tier, with assertions written blind
  from scope §5. `hooks/stop` is 496 lines on main, so the Stop detector goes
  in a library (scope §4.1).
- **S0 checks b, c and e are Felix's** (about 0.25 session), and can run
  before the founder's look.
- **#312 (public README) is CONFLICTING.** It writes a §0bv that main already
  has. Its section takes the next free id when it lands (§0bz or later).
  It is in the carrier's queue.

**Traps paid for this session:**

- **Four sessions claimed the same handoff id within an hour.** #327
  (landed), #325, #330 and this one all wrote §0bw; this one was drafted 27
  seconds after #325 opened. #325's section landed here as §0bx and this
  one as §0by, each unchanged but for its heading. Their ids were assigned
  at landing by re-reading main. Take the id at merge time: re-read main and
  `gh pr list` for PRs touching `HANDOFF.md` right before merging. Stack on
  an open handoff PR rather than beside it.
- **Local gates are slow under load.** Under a one-minute load average of
  50-400, three local gates took 56, 75 and 142 minutes, where CI took 5-6.5.
  Start the gate in the background as soon as the commit exists, and budget
  about two hours before a merge.
- **The red.tsv base check can fail a docs branch.** The check is
  tests/run:20925-20945 at `bd740748`, with its helpers `_rt_engine_same` at
  :20864 and `_rt_record_holds` at :20889-20894. It calls a branch an engine
  change whenever the branch's engine differs from origin/main's. So an engine
  PR landing while a docs branch's gate runs fails that branch with "re-record
  with tests/run --record-assertions". Merge main in instead of re-recording:
  the engines then match and the check skips.
- **A session keeps its start banner's CLI path after every deploy.** This
  one began on 0.49.150 and ended with 0.49.162 installed. Run gate and merge
  as `<installPath>/harness/felix`, taking `installPath` from the user-scope
  `felix@felix` entry in `~/.claude/plugins/installed_plugins.json`.
- **Stop's `additionalContext` makes the model take another turn.** See
  transcript `19161025` under
  `~/.claude/projects/-Users-a14808-Documents-Felix--claude-worktrees-felix-v3-2-rearchitecture-dd90dc/`:
  the verify nudge lands at 07:20:47Z and model work follows with no human
  prompt. The docs say `systemMessage` starts no turn; that stays untested
  until S0(a).

---

## Index of earlier sections

Newest first. Each file is the section exactly as it stood.

| § | Section |
|---|---|
| [0](docs/handoff/0.md) | DECIDED 2026-08-14, AMENDED 2026-09-13 — this repository is private, and a snapshot of the engine is public |
| [0bx](docs/handoff/0bx.md) | 2026-09-23/24 — every stuck PR triaged, why the night went stale, and the landing actor designed (not built) |
| [0bw](docs/handoff/0bw.md) | 2026-09-23 — building Felix, measured as Felix's own workload; direction-level documents wait for the founder |
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
