### 0bz. 2026-09-23/24 — restart moments scoped and placed: step 1 names a session running an older engine, and the founder allowed one line mid-session

**No engine change from this session, and nothing deployed.** The installed
engine was 0.49.172 when this was written. A session's start banner can name an
older one (see Traps). The open items of §0by, #325's section, stand: the
landing actor, and the carrier session's no-escape queue. Read
[docs/handoff/0by.md](docs/handoff/0by.md).

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
  has. Its section takes the next free id when it lands (§0ca or later).
  It is in the carrier's queue.

**Traps paid for this session:**

- **Four sessions claimed the same handoff id within an hour.** #327
  (landed), #325, #330 and this one all wrote §0bw; this one was drafted 27
  seconds after #325 opened. #325's section landed here as §0by and this
  one as §0bz, each unchanged but for its heading. Their ids were assigned
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
  one began on 0.49.150 and ended with 0.49.172 installed. Run gate and merge
  as `<installPath>/harness/felix`, taking `installPath` from the user-scope
  `felix@felix` entry in `~/.claude/plugins/installed_plugins.json`.
- **Stop's `additionalContext` makes the model take another turn.** See
  transcript `19161025` under
  `~/.claude/projects/-Users-a14808-Documents-Felix--claude-worktrees-felix-v3-2-rearchitecture-dd90dc/`:
  the verify nudge lands at 07:20:47Z and model work follows with no human
  prompt. The docs say `systemMessage` starts no turn; that stays untested
  until S0(a).
