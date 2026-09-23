# Restart moments, step 1: scope

Proposed 2026-09-23. Nothing here is built. Line numbers are at origin/main
`5110ca64` unless a line says otherwise. Its base, #307 (per-session overnight
nights), merged as `78ea7485` and is deployed as 0.49.156.

## The short version

The question was whether Claude or Felix can start a new session on its own.
Not today. Step 1 was to be Felix naming the moment when a restart is worth it,
so that restarting takes one approval from you. Scoping that against the code,
the platform and the usage data changed what step 1 should be.

| Moment | Verdict for step 1 | Why |
|---|---|---|
| **Engine behind.** The session's hooks run an older Felix than the one installed | **Named** | Detectable at Stop in bash with no git. The fix is `/reload-plugins`, which keeps the conversation, so it is not a restart and needs no handoff. It happens at most Stops this week, and it caused one of the three known misses |
| **Idle resume.** A large session is resumed after its prompt cache expired | **Recorded only** | Nothing said at a resume arrives before the cost is paid. On desktop the resume fires with your prompt already sent |
| **Past 500K at a clean boundary** | **Deferred to step 2** | This is the one real restart, and it runs through the handoff, which is not yet repaired. As it stands the remedy is two actions, not one |

So step 1 does not restart anything, and it does not offer to. It makes Felix
notice when a session is running old engine code. It points the model at the
current CLI straight away. Once you allow it, it tells you once per session
that `/reload-plugins` switches the session. It also measures whether anyone
acts on that, and that measurement is the evidence step 2 needs before Felix
suggests real restarts.

**Size:** about 4 sessions (3.75 to 4.75), in two stages, plus a probe.
**Your part:**
- a 10-minute look at a test line in the desktop app and the CLI;
- one yes or no on whether Felix may put a line on your screen mid-session (if you don't answer, it stays off);
- where this goes on the roadmap.

## 1. The facts that decided it

**How Felix can speak at Stop.** The hooks documentation says two things about
Stop. A `decision: block` and a Stop `additionalContext` both make the model
take another full-context turn. A `systemMessage` is shown to you and does
not. The first half was confirmed on a real transcript: after Felix's verify
nudge at 07:20:47 on 2026-09-23, the model went on working with no human
prompt in between. Felix has never emitted a Stop `systemMessage`, so the
second half (that it is displayed and does not continue the turn) is untested
on your surfaces. A notice meant to let a session stop can only use
`systemMessage`.

**Engine behind.**
- The fix is `/reload-plugins`. The plugin docs say it moves a copied plugin's
  hooks to the new install mid-session and keeps the conversation. In the
  desktop app that works when typed, since v2.1.260; you have 2.1.280. It does
  not work over Remote Control.
- How often: 25 promotions in about 2.4 days this week. By one reader's count,
  57-78% of Stops ran an engine older than the one installed.
- Where it shows: a new process rebinds its hooks, so the mismatch is
  invisible at startup and resume (0 of 45 rows differ). It shows at Stop,
  compact and handoff.
- It is live: this session's subagents were handed `0.49.150/harness/felix`
  while 0.49.151 is installed.

**The model keeps calling the old CLI.** The session-start banner hands the
model `Gate: <old path>/felix gate` (session-start:192). A reload moves the
hooks, not the path the model already holds. So gate, handoff and merge keep
running old code. Eight of eleven handoff rows so far ran an older CLI.

**Idle resume.**
- The documented SessionStart(resume) fields (`seconds_since_last_response`,
  `context_tokens`, `prompt_cache_likely_expired`, `estimated_cache_write_usd`,
  since v2.1.251) have never been seen in a real payload.
- On desktop the resume hook runs 1-17 s after your prompt has been sent.
- 60-80% of costly idle events have no SessionStart at all.
- Pro and Max already get a resume-from-summary dialog.
- The silent resume exit (#270) is pinned by four suite assertions.

**Past 500K.**
- The saving (a modelled 18-28% of coordinator input) assumes every restart
  is taken. ECC's compact nudge was followed 0 times in 88.
- Restarting means going through `SESSION_HANDOFF.md`, and none of the
  handoff repairs 09-21 §6 listed exist: a stamp, `felix handoff --check`,
  and a start-of-session reader.
- The 2026-09-23 roadmap schedules none of them, and no document records that
  they were dropped.
- Two of the three known misses were handoff failures.
- Whether `/clear` rebinds hooks or keeps the session id has never been
  observed. There are 0 clear rows.

**Moments as procedures rows.** 09-21 §6 "Later" put these moments in
`moments.tsv` and `procedures.tsv`. That home does not fit:
- they are conditions seen at moments that already exist, not new moments;
- `procedures.tsv` holds "a person's stances" (schemas.tsv:105), and engine
  staleness carries no per-project judgement;
- nothing speaks procedures today.

A table of its own, checked in the gate, keeps the class without breaking
that doctrine (§4.4).

## 2. Step 1a: record and point (nothing on your screen)

### 2.1 The detector

`felix_engine_state ROOT` goes in a library, with no git calls. `ROOT` is the
running engine's plugin root.

1. **Registry.** Read the `felix@` entries in
   `~/.claude/plugins/installed_plugins.json` (version 2: one array entry per
   scope). With more than one entry, or when the entry's marketplace is not
   the running copy's cache segment, say nothing and write no row. A
   stranger's project-scope pin must never be told to reload into their
   user-scope copy. `felix_registry_field` today returns the first match
   whatever its scope (resolve.sh:28-43), so the detector does not reuse it
   as is.
2. **Sibling rule.** `ROOT`'s physical parent must be the parent of the
   registry's `installPath`. If not, this is a checkout, a settings.json
   install, a fixture or CI: silent.
3. **Current or behind.** Same basename means current. Otherwise compare this
   engine's own `plugin.json` version with the registry version; if they
   differ, the session is behind. Versions are compared for difference only,
   never order, so a rollback is named too.
4. **Unmerged install.** If `~/.claude/plugins/known_marketplaces.json` shows
   the felix marketplace as a directory under `.claude/worktrees/`, or
   anywhere other than the Felix home, the installed engine is an unmerged
   build. Record `unsaid:unmerged` and never point anyone at it. This needs
   no git.

Cost per Stop: about 20-30 ms after the project resolves. That is two small
reads of a 10 KB file and two `pwd -P` calls, next to a green path of about
16 git processes.

### 2.2 The CLI points the model at the current engine

When `felix gate`, `felix handoff` or `felix merge` runs from a copy the
detector calls behind, it prints one line to stderr and changes nothing else:

    felix: this is 0.49.150; 0.49.151 is installed. Use <installPath>/harness/felix.

This is output of a command the model ran, so the doctrine counts it as
invisible. It needs no person and covers subagents and forks. It is the part
of step 1 that protects the known miss, a session that deployed and kept
misrouting.

Considered and declined:
- A `user-prompt` line after each engine change: it misses forks and sessions
  started before it shipped.
- A stable shim path such as `~/.felix/bin/felix`: it adds install footprint,
  which Phase 3 is removing.
- A merge refusal on a superseded CLI: still the founder's decision from 09-21
  §6. Step 1 only supplies the rows.

### 2.3 Records

Four new kinds go in `lifecycle.log`. Each needs a writer, a header line and
assertions, and no schema change, because the validator checks cell count and
encoding, not values.

| Kind | Written | Note |
|---|---|---|
| `behind` | at a Stop that detects it: at most one transient row and one final row per session | `<outcome>;entry=;att=;rc=;bt=`. Outcome is `shadow`, `said`, `deferred`, `unsaid:headless`, `unsaid:off`, `unsaid:cloud`, `unsaid:unmerged` or `unsaid:night` |
| `rebound` | the first Stop whose bound engine differs from the one named | `after=<outcome>`. Counted even if another promotion landed in between |
| `still-behind` | the first later quiet Stop with the same bound engine | evidence the session kept working on old code |
| `end` | SessionEnd, only when `state/behind/<session>` exists (a file test) | the payload's `reason` |

Resume rows also gain `idle=;ctx=;expired=;usd=` from the payload's cost
fields. This is the first check that those documented fields exist. The
resume still prints nothing.

`entry`, `att`, `rc` and `bt` record `CLAUDE_CODE_ENTRYPOINT`,
`CLAUDE_CODE_SESSION_ATTENDED`, whether `CLAUDE_CODE_BRIDGE_SESSION_ID` is set
(Remote Control), and whether `background_tasks` was absent, empty or not.
Each of these is an assumption about the platform, and recording it makes the
assumption checkable.

### 2.4 Shadow period

Step 1a ships with speech off. It runs for at least 7 days and at least 10
`behind` rows, and costs no sessions. Felix then checks three things:
- every row has sibling cache paths;
- no row came from a checkout, a fixture or CI;
- `rebound` rows follow resumes.

The shadow rows are also the baseline: how often people reload with nobody
telling them.

The first deploy carrying the detector warns nobody, because live sessions are
bound to older engines. Rows begin at the next promotion.

## 3. The probe (S0)

About 0.25 session, plus about 10 minutes of your time. None of it is engine
code. It uses a scratch directory whose only Stop hook prints
`{"systemMessage":"probe"}`.

| Check | Who | If it fails |
|---|---|---|
| (a) The line appears in the desktop app and in the CLI, and no extra assistant turn follows | you look | Speech never ships; engine behind stays recorded-only; step 2 has no channel either |
| (b) The probe session's model is asked to quote the last system message | Felix | If it can, the notice is also model-facing, and its imperative wording is re-read |
| (c) Whether the app prefixes hook messages with a name, which decides whether "Felix:" is kept | Felix | wording only |
| (d) Typing `/reload-plugins` once in each app, in a session known to be behind, gives a `rebound` row with no resume between | you type, Felix reads | The words promise nothing; the remedy is re-checked before any speech |
| (e) `CLAUDE_CODE_ENTRYPOINT`, `…_SESSION_ATTENDED`, `…_BRIDGE_SESSION_ID`, `…_REMOTE` in the desktop app, the CLI, `claude -p`, a scheduled task, Remote Control and a teammate | Felix | Decides which sessions count as nobody-there |

Claude cannot see or type into the desktop prompt box, which is why (a) and
(d) need you.

## 4. Step 1b: say it once

### 4.1 Where and when

A quiet stop is a main-agent Stop where all of these hold:
- the turn really ends: `stop_hook_active` is false and, since #307, `CHAIN`
  is 0;
- the checkout is governed, there is a session id, and it is not the
  platform's summary session;
- Felix said nothing else at this stop;
- `background_tasks` is absent or empty.

This includes the clean-tree, nothing-committed exit (stop:117-118), which
is the only boundary a read-only session reaches.

Mechanism: the moments library installs an `EXIT` trap right after the
project resolves, and `felix_say` sets a flag. Every Stop emitter already
calls `felix_say` before it prints. At exit:
- if the flag is set, or tasks are in flight, the trap writes `deferred`;
- otherwise it writes the marker and then prints.

No emitter region is touched, #307's included. A future emitter is covered as
long as it uses `felix_say`. `hooks/stop` gains a source line and the trap,
and stays under 500 lines (it is 496 on main since #307).

### 4.2 The words, the rule, the suppressions

    Felix: this session runs 0.49.150; 0.49.151 is installed.
    Type /reload-plugins to switch. You keep this conversation.

The versions are read at that stop. The words name no project and never say
"the founder". They promise the conversation is kept, not the cache.

**Once per session, for the life of the session.** The marker
`state/behind/<session>` is written before the line is printed. If it cannot
be written, nothing is said. This keeps a line on your screen within the
constitution's "at its end". Without the cap, at this machine's deploy rate a
person who complies would be told again after every promotion.

| Suppressed | How it is recorded |
|---|---|
| `stop_hook_active`, or a #307 night chain (`CHAIN=1`) | nothing (not reached) |
| a session that owns a live night | `unsaid:night`, retried after the night |
| machine or summary session, broken binding, no project, no session id, not a cache copy | nothing |
| Copilot CLI or Cursor | nothing. Neither host has the input or the remedy, and `felix lifecycle` says "Claude Code only" |
| headless: entry `sdk-*`, or attended=0 if S0(e) shows that value is reliable | `unsaid:headless` |
| Remote Control (bridge id set; `/reload-plugins` declines there) | `deferred`, retried at a later local stop |
| cloud session (`CLAUDE_CODE_REMOTE=true`) | `unsaid:cloud` |
| `FELIX_MOMENTS=0` in the launch environment | `unsaid:off`, a recorded decline the model cannot set |
| Felix said anything else at this stop (the hold, a block, verify, skipped, plugin-blocked, unrecorded, overnight) | `deferred`. The notice never competes with a refusal |

### 4.3 Acceptance and deletion

`felix lifecycle` is a read-only report over every project's `lifecycle.log`
under the memory root. It names no project. For engine behind it counts:
- the population: said rows from sessions where someone could act;
- how each ended: reloaded (a rebound with no resume between), resumed,
  continued behind, ended or cleared, or unknown;
- the same classes for the shadow baseline;
- starved sessions (deferred, never said);
- unsaid rows, by reason.

It also prints the gaps it cannot see: any SessionStart source seen with no
stance, and that `fork` is not in the SessionStart matcher.

The first read comes at 20 said rows or 3 weeks after speech is switched on,
whichever is first. The verdict goes to HANDOFF (`decisions.log` holds route
declines only). The thresholds are judgement, written in the library header so
later sessions apply them rather than re-argue them:

1. **The channel fails** (from S0(a), or a live continuation clearly caused
   by Felix's line rather than another plugin's Stop hook): speech off for
   good.
2. **Nobody acts:** at 20 said rows, fewer than 3 reloaded and no better than
   the baseline. The words go. The rows stay 30 days, and the result counts as
   evidence against step 2's notice.
3. **Keep:** 50% or more reloaded. That rate becomes the bar step 2 must
   approach. Between the two, read again at 40.
4. **The remedy is broken, not ignored:** `/reload-plugins` was typed and no
   rebound followed. The words go, the platform claim is re-checked, and this
   never counts toward trigger 2.
5. **The platform overtakes it:** Claude Code starts prompting for updates
   made outside the session. Delete after one observed session confirms it.
6. **Starvation:** more than 30% of detected sessions starve. Reconsider the
   lowest-rung rule, as a recorded decision.

### 4.4 The class

A new engine table, `templates/restart-moments.tsv`, has the columns `moment`,
`stance` (named | recorded | deferred | declined), `records` (the lifecycle
kind), `hosts`, `remedy` and `reason`. It has three rows:
- engine-behind: named;
- idle-resume: recorded;
- context-large: deferred.

A new moment is a row plus a detector. A row nobody has decided on is the gap.
It is checked **in the gate**, through the existing path (the `lifecycle_wired`
obligation, then `bin/lifecycle-check`, then `lib/coverage.sh`), not by
`felix coverage`, which the gate never calls. The check looks for a writer call for the kind in
`lib/` or `hooks/`, not a header line, so a deleted writer fails. Adding a
schema row for a new table is free. If the build finds that extending the
checker changes a qualification row, that part goes to a person under #296.

## 5. Tests shown failing first

The assertions are written blind from this scope by an author who has not read
the implementation. Each is shown red before the change and green after, and
one that would pass anyway is shown red against a named mutant. Every silence
assertion is paired with a positive control in the same fixture. The main
ones:

- A behind session at a quiet stop, with speech on, prints exactly one JSON
  object: the two lines as `systemMessage`, with no `decision` and no
  `hookSpecificOutput`. It writes one `behind said` row, and `says.log` holds
  the same words.
- The same with speech off prints nothing and writes `behind shadow`.
- A stop where verify (or skipped) is due prints only that message, and
  writes `deferred`. The next quiet stop prints the notice. (Mutant: printing
  at every exit.)
- A second quiet stop is silent; the row count stays 1. After a newer
  promotion it is still silent: once per session, not per version.
- The hook runs from a newer copy after a said row: one `rebound` row and no
  output, even if the registry has moved again. (Mutant: rebound only when the
  root equals the install path.)
- Each suppression in §4.2 against its positive control: headless, off,
  Remote Control, cloud, night, host, unwritable marker, red tree, broken
  binding, `stop_hook_active`, background tasks.
- A two-entry registry (user and project scope) and a worktree marketplace are
  both silent.
- A checkout-shaped copy at version 9.9.9 is silent (mutant: comparing
  versions only).
- `felix gate` from a behind copy prints the stderr line and keeps its exit
  code; from a current copy, nothing.
- A resume payload with the four cost fields writes
  `idle=4000;ctx=812345;expired=true;usd=1.23` and prints nothing. The four
  existing silent-resume pins still pass.
- The report classifies each class from a fixture log that spans two
  projects.
- `restart-moments.tsv` passes the schema check. A row whose kind has no
  writer fails the gate.
- Static checks: `hooks/stop` has one `systemMessage` emitter; no new string
  says "founder"; no jq, python or node in hook code; no project named.
- Unchanged: "a session that changed nothing stops silently"
  (tests/run:3289) and the rest of the completion-gate section.

## 6. Decisions

**Felix's, taken here and recorded:**
- Step 1 names only engine behind. Idle resume is recorded only. Past 500K is
  deferred, and nothing is built for it in step 1.
- The channel is a Stop `systemMessage`, never Stop `additionalContext` or a
  block.
- The remedy is `/reload-plugins`. This revises 09-21 §6, which said Stop
  should say "hand off" when the engine is the reason.
- The CLI stderr line is chosen over a `user-prompt` repoint or a shim.
- Detection needs no git and never compares version order. When the
  install's scope or marketplace is ambiguous, it is silent.
- Once per session for life, with the marker written before printing. The
  notice is the lowest rung, deferred and never dropped.
- The class is its own table, checked in the gate, not procedures. This
  departs from 09-21 §6 "Later" for the reasons in §1.
- Shadow first. Speech only after S0 passes and you say yes.
- The words, the thresholds and the report name.

**Yours:**
1. **May Felix put one line on your screen mid-session?** At most once per
   session, at a stop where it says nothing else, only to say that a newer
   Felix is installed and that `/reload-plugins` switches to it. Today the
   constitution allows only refusals in the middle of a session. With no
   answer, speech stays off. Step 1a still ships and still protects the gate,
   handoff and merge calls.
2. **Placement,** because prioritisation is yours. The proposal:
   - 1a in the last days of Phase 0 or the first of Phase 1. It touches none
     of the judge files, and this week most Stops ran an engine older than the
     one installed, so every Phase 0-1 engine fix reaches running sessions
     late.
   - 1b when S0 has passed and you have answered question 1.
   - Fallback: Phase 3 "Defects".
3. **Ten minutes** for S0(a) and (d).
4. **For step 2:** whether the 09-21 §6 handoff repair goes back on the
   roadmap, and where. The 09-23 roadmap has none of it, and nothing records
   whether that was on purpose.
5. **Later, because it changes what Felix is:** whether Felix may ever call
   the desktop's `clear_session("self")` itself. In bypass and auto permission
   modes that restarts a session without asking you.

Still yours from 09-21, and not changed here: a merge refusal for a session
bound to a superseded engine.

## 7. Step 2, the restart itself: prerequisites only

These come first, in this order:
1. **The handoff repair:**
   - a stamp block in `SESSION_HANDOFF.md`;
   - `felix handoff --check`;
   - the note's origin;
   - a start-of-session reader that never blocks. It compares session and
     checkout only when the source is `clear`, because at startup a fresh
     worktree reading a project-wide handoff mismatches by design.
2. **A probe of `/clear`:** does it rebind hooks, does it keep the session id,
   does SessionEnd(clear) come before SessionStart(clear)? The docs suggest
   hooks change only through `/reload-plugins` or a restart of Claude Code.
3. **The evidence in the tree:**
   - the 09-21 known-miss list, which exists only in a `/private/tmp`
     workflow output;
   - the idle-resume count (211/131) and the corrected fresh-start replay.
   The audit folder holds an earlier replay (`sim.py`) but neither of these.
4. **Step 1's acceptance verdict.**
5. **A restart-grade boundary:** a quiet stop, plus background tasks and
   crons both present and empty, no untracked files, and either nothing
   committed or a green receipt on this exact tree.
6. **A one-action remedy.** As things stand it takes two actions: ask for
   `felix handoff`, wait a full-context turn, then type `/clear`.

Then comes the alternating continue/restart/compact experiment, judged on the
known misses, and only after that the compaction window.

## 8. Excluded, risks, unverified

**Excluded from step 1:**
- any restart, clear, compact or reload that Felix performs;
- any `clear_session` call;
- the transcript context reader and the 500K line;
- the handoff repair;
- speech at a resume;
- a SessionStart banner or compact badge for engine behind;
- `fork` in the matcher;
- speech on Copilot or Cursor;
- cleaning the `state/` marker families, which are never cleaned today;
- the three existing Stop strings that say "the founder" (a Phase 3 item).

**Risks:**
- In hold-heavy engine sessions the notice may starve. Felix's
  `verification.log` has 173 blocked stops against 75 allowed since 09-16,
  read on 09-23. This is measured, and trigger 6 covers it.
- In the CLI, `/reload-plugins` can sit behind `--force` when another plugin
  has a pending MCP change.
- Old version directories are marked `.orphaned_at` and may be cleaned, so a
  session whose hook path vanishes fails open.
- `state/` lives in the iCloud-synced home, so a renamed marker costs at most
  one repeated line.
- Step 1 is written against the Stop hook as #307 left it. Any later change
  to `hooks/stop` means re-cutting it.
- On this machine, most long sessions will see the line once. A stranger's
  deploy rate is far lower.

**Unverified, and each with a check:**

| Assumption | Checked by |
|---|---|
| A Stop `systemMessage` is shown to you, starts no turn, and may or may not reach the model | S0(a), (b) |
| `/reload-plugins` rebinds Felix's hooks mid-session | S0(d) |
| The runtime `ROOT` and `installPath` share a physical parent | the shadow week |
| `background_tasks` is present, and empty when idle | the `bt=` field |
| The resume cost fields exist | the resume rows |
| What the environment variables mean across session kinds | S0(e) |
| 57-78% of Stops were superseded, and about 20 first-stale stops a week per bind | cannot be reproduced from the tree |

**Side note, not in scope:** Stop's `plugin-blocked` and `unrecorded` messages
have no once-marker and repeat as `additionalContext` at every green stop. Each
repeat costs a full-context turn. They are rare in practice: 1 and 7 rows in
Felix's `says.log`.

## 9. Sequence and size

| Stage | Sessions | Gate to the next |
|---|---|---|
| #307 (the overnight rework) | done: merged `78ea7485`, deployed 0.49.156 | step 1 branches from main |
| S0 probe | 0.25 + about 10 min of yours | (a) and (d) gate the speech, not 1a |
| 1a: detector, CLI line, the four row kinds, resume fields, SessionEnd row | 1.5-2 | merged on green CI and deployed from the home |
| Shadow period | 0 (at least 7 days and 10 rows) | three shadow checks clean |
| 1b: moments library and trap, `felix_say` flag, report, class table and gate check, speech on | 1.75-2.25 | S0 passed and your yes |
| Acceptance read | 0.25 | at 20 said rows or 3 weeks |

Every change except templates, docs and the version bump is in the adversarial
tier: `lib/`, `hooks/`, the CLI, and the gate-run checker. The sizes include a
separate author for the blind assertions, a review pass, mutant runs,
`red.tsv` regeneration and merging main in under concurrency.

## How this was made

- **Five readers** worked in parallel: the Stop hook; session start and the
  lifecycle recorder; the moments and procedures tables; the platform docs
  checked against real transcripts; and the usage data.
- **Three independent scopes** were written from different angles: smallest
  step, class not instance, and handoff first. A skeptic attacked each one
  against the code and the docs.
- **A judge** merged them. It took the smallest-step scope as the base, at 7
  of 10 against 5 and 5.
- **A completeness critic** then found the problems fixed here:
  - `deferred` rows the first design could not write (now the exit trap);
  - Remote Control and cloud sessions going undetected;
  - no check of the remedy itself (now S0(d));
  - an acceptance join that could not tell "ignored" from "ended";
  - a registry read that ignored scope;
  - an unguarded worktree install;
  - a class check that never ran in the gate;
  - a file over 500 lines;
  - an undersized estimate.
- **Checked by hand before writing:**
  - `hooks/stop` is 496 lines on main after #307;
  - `gate.sh` never calls `felix coverage`;
  - `decisions.log` has one appender;
  - the registry is version 2, one entry per scope;
  - the marketplace path is readable without git;
  - the attended variable is present;
  - the audit folder holds `sim.py`.

**What changed from the first answer in chat:**
- "Restart when the engine was deployed" became `/reload-plugins`, which is
  not a restart.
- "Past 500K at a clean point" moved from step 1 to step 2.
- The home named by 09-21 §6 "Later", rows in `moments.tsv` and
  `procedures.tsv`, was replaced by a table of its own.
