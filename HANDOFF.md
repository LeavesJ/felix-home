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

**The rule for the next session, since 2026-09-24.** Do not write your section
into this file. Write it as a file of its own, headed `### <title>` with no id,
and run `felix handoff --section FILE`. It lands at
`docs/handoff/pending/<UTC time>-<branch>.md`, a path no other session writes,
so two sessions' handoffs cannot collide in whatever order they land. The
session start names every section waiting there. Each is newer than the
current section below. `felix handoff --rotate`, on a branch cut from main
when upkeep says it is due, folds them in, oldest-landed first:
- each takes the next id (after 0di comes 0dj);
- the section it replaces moves into `docs/handoff/<id>.md`, unchanged;
- their rows go in at the top of the index.

The gate's handoff check refuses any other change to what the fold owns,
including a section written in by hand. Why:
`docs/2026-09-24-handoff-sections.md`. A reference like "HANDOFF §0bm" means
`docs/handoff/0bm.md`.

---

## 0. DECIDED 2026-08-14, AMENDED 2026-09-13 — this repository is private, and a snapshot of the engine is public

Unchanged; read [docs/handoff/0.md](docs/handoff/0.md). In one line: this
repository (`felix-home`) stays private because its history carries the memory
tree; the engine is published as a snapshot with no history at
`github.com/LeavesJ/Felix`, and never by flipping this repository public.

---

## Current state

Sections newer than this one may be waiting in `docs/handoff/pending/`. The
session start names them.

### 0di. 2026-10-01: a seeded commissioning check reads done only when its lookups ran to the end

Found by the adversarial review of claude/commission-lookup-fails-unknown,
and reproduced there with `ulimit -u 1` inside a check's own substitution.

**Defect closed.** Ten of the template's fourteen rows decided from what an
engine lookup printed. They read `done` when the lookup never finished.
Measured on macOS bash 3.2.57:
- `[ -z "$(lookup)" ]` (probes, obligations, reach) is true when the lookup
  cannot fork inside the substitution, which prints nothing with status 128.
  It is also true when the substitution cannot make its pipe
  (`ulimit -n 3`), which prints nothing with status **0**. So
  `out="$(lookup)" && [ -z "$out" ]` would not close it.
- `[ "$(lookup | grep -c bad)" -eq 0 ]` (stack, preflight, discover,
  human_steps) is true when the lookup dies inside the pipe, with pipefail
  or without.
- `[ -n "$(lookup)" ]` (gate_declared) is true on what a lookup printed
  before it died.
- `lookup | grep -q good` (envelope, baseline) is true on what a lookup
  printed before it died when pipefail is off. With pipefail on, it holds on
  a lookup that answered and returned non-zero.

The rows are in engine/harness/templates/commissioning.tsv and in every
governed project's copy: bazaar, behaviorchangebench, elenchus, felix,
sv2-apps, veldra and webapp.

**Mechanism, and why this one.** Each lookup is read alone with a mark after
it, `x="$(lookup; [ $? -lt 128 ] && printf .)" && [ "${x%.}" != "$x" ]`.
The row then decides by `grep -c` over `${x%.}`, never over a pipe from the
lookup. Probes feeds felix_probes_blocking from the value it read, through
`{ felix_probes_blocking; [ $? -lt 128 ] && printf .; }`.
- **Status 128 or more is a death.** A dead last pipeline stage returns 128
  or 129 (felix_stack_plan, felix_setup_status), so the mark is not written.
- **A lower status is an answer.** felix_stack_plan returns grep's 1 under
  pipefail on a stack.tsv holding only comments. A shape that carries any
  status holds that row.
- **Blank lines read as before.** The count, rather than `[ "$x" = . ]` or
  `[ -n "${x%.}" ]`, keeps the old reading of blank lines. felix_json_str
  prints an empty line for `"gate": ""`.
- **`unknown` lines hold their rows.**
  - stack counts an `unknown` action.
  - human_steps counts an `unknown` step.
  - preflight counts an `unknown` line, which felix_ready_report already
    prints when it cannot list plugins.

  claude/cap-unread-callers makes felix_stack_plan and felix_setup_status
  print theirs. With that engine and these rows, an unreadable capabilities
  file holds the stack row. Old rows read done there, and on main's engine
  both still do.
- **No lint.** #375 tried a validator for the check column and reverted it:
  a correct one needs a quote-, redirect- and list-aware parser.

**Built as spec, blind assertions, fix, review.**
- **Blind assertions.** A blind author wrote 115 assertions from the contract
  alone, in its own worktree on origin/main. 37 were red there. The
  reachability and old-finding cases were green.
- **First fix and its gaps.** The first fix (e8bb0029) covered seven rows.
  The blind block found envelope, gate_declared and baseline, plus a status
  read on the probes stage (521e0757).
- **Adversarial review.** The review of e8bb0029 confirmed the fix where it
  claims to work. It found the 128/129 loop deaths and the missing `unknown`
  in felix_stack_plan, and corrected three sentences of the header (eb2d8374).
- **Assertions after review.** Eight not-blind assertions were added after
  review (7e4e429c). They are red against 521e0757, so they pin the status rule.
- **Final count.** 123 assertions: 123/123 against the template and against
  the bazaar, behaviorchangebench, felix, sv2-apps and webapp tables.
  origin/main fails 45. Elenchus and
  veldra fail only six named obligations cases, because neither table has an
  obligations row.
- **Mutation.** Reverting any one row to main's text reds only that need's
  assertions, 2 to 8 each, 45 in all.
- **Normal states.** `felix commission --status` reads the same done and held
  rows under old and new tables in all six checkouts found here (every
  project but webapp).
  - One state changes on purpose: preflight, when the claude CLI is present
    and its plugin list is empty, goes from done to held, and the routed
    plugins really are absent.
  - Provider answers read `stale`, because their topology hashes
    commissioning.tsv.

**What landing costs.**
- **It escapes.** commissioning.tsv is in FELIX_ESCAPE_TABLES, so
  `felix merge` refuses it. It lands by `gh pr merge` on the founder's yes.
- **Every policy hash moves.**
  - Felix's commission grant and receipt go stale. `felix merge` refuses
    every PR until the founder runs `felix autonomy --allow commission`, then
    `felix commission`.
  - Each other project's receipt goes stale until a `felix commission` run in
    its checkout.
  - The provider skills (constitution_audited, automation_surveyed, and
    obligations_surveyed on elenchus) read `stale` until they run again.
- **Slot.** The carrier placed this at 0.49.265, after #340 (.263) and #385
  (.264), which also change felix's tables, so one re-stamp covers all three.
- **#388's two tables are done.** #388 brought projects/webapp and
  projects/behaviorchangebench with the old checks, unchanged from the old
  template. Main was merged at ea865e82, and both tables now carry the
  template's check cell for all ten needs. Each passes 123/123 and fails 45
  on main. behaviorchangebench's checkout reads the same states under old and
  new rows. No checkout here is bound to webapp. A table added after this
  must be given the same cells.

**Handed on, not done here:**
- **Nested deaths.** A fork failure nested inside a lookup can still leave a
  short answer, a status under 128 and the mark. The review reproduced it for:
  - preflight, in felix_ready_wanted;
  - probes, in felix_probe_state;
  - obligations, in felix_obligations_orphans' row read;
  - preflight again with `ulimit -n 11`, a redirection failing inside
    felix_ready_report.

  Each is the lookup's to report. Most lookups end in `return 0`.
- **preflight's `unknown` cannot be cleared by its answer.**
  felix_ready_report prints `unknown` ("no claude CLI here") for an empty
  plugin list even when the CLI is present, and `felix ready --fix` acts only
  on absent and disabled. The row reads held rather than unknown. It ignores
  `undeclared`, which `felix ready` itself counts.
- **The mark is only a trailing `.`.** A lookup that exits 0 mid-line after a
  `.` would pass. No lookup calls exit.
- **gate_shown_failing can hold falsely.** It ends in `grep -q .` behind
  three filters. Under pipefail, a mistakes.log that fills the pipe after
  grep quits reads held. That fails closed.
- **Tables copied from older templates.** Tables outside this repository, or
  copied from an older template, keep the old rows. A drift report is being
  built as claude/commission-template-drift.

**Traps paid:**
- **C3 cannot go through felix_commission_ask.** Its `</dev/null` needs fd 3,
  which `ulimit -n 3` refuses. The block evaluates the check text directly.
- **The fact-forcing gate.** In a Bash call, `rm -rf` trips it whatever facts
  come first. Create a fresh `mktemp -d` instead.
- **"Held on every fresh project" was wrong.** `felix new` seeds the
  catalogue's `always` rows into stack.tsv, so a manifest of only comments
  comes from a hand edit, not from `felix new`.

---

## Index of earlier sections

Newest first. Each file is the section exactly as it stood.

| § | Section |
|---|---|
| [0](docs/handoff/0.md) | DECIDED 2026-08-14, AMENDED 2026-09-13 — this repository is private, and a snapshot of the engine is public |
| [0dh](docs/handoff/0dh.md) | 2026-09-28 — Felix governs a Claude Code cloud session of felix-home, and carries the toolbox its routes name |
| [0dg](docs/handoff/0dg.md) | 2026-09-24/10-01 — a binding refusal cut at eighty characters could name the parent directory; the middle is cut now, and marked |
| [0df](docs/handoff/0df.md) | 2026-10-01 — handoff-check, lifecycle-check and obligations-check find their libraries before moving to the top, so a relative call from a subdirectory no longer ends 127 |
| [0de](docs/handoff/0de.md) | 2026-10-01 — a handoff fold already pushed is named at session start, so a second session does not fold the same sections |
| [0dd](docs/handoff/0dd.md) | 2026-09-24 — the engine makes its scratch under TMPDIR, because a bare mktemp on a Mac does not, and no count of what a path left behind could see it |
| [0dc](docs/handoff/0dc.md) | 2026-09-24 — every uses: in the gate workflow bootstrap renders is a commit sha, for every stack it can render |
| [0db](docs/handoff/0db.md) | 2026-10-01: a fresh repository commissions clean. The mistakes log writes one row per failure and heals split ones, the gate records the project's own failure, a gate that could not run is not a shown failure, and GitHub-only setup rows wait for a GitHub remote |
| [0da](docs/handoff/0da.md) | 2026-10-01: a table check that cannot fail because a final filter hides its status is refused, by one classifier every runner and schema-check share |
| [0cz](docs/handoff/0cz.md) | 2026-10-02: felix inventory (Phase 0b step 4), revised against the settled spec |
| [0cy](docs/handoff/0cy.md) | 2026-10-02: lib/qualify.sh is split along its run/read seam, and a later qualify run sweeps the scratch trees a SIGKILLed run left, and nothing else |
| [0cx](docs/handoff/0cx.md) | 2026-10-02: a hook in a Desktop worktree session judges the worktree, not the main checkout |
| [0cw](docs/handoff/0cw.md) | 2026-10-01: the systems report v5, reviewed and decided. What Felix builds next, in what order, and what starts each step |
| [0cv](docs/handoff/0cv.md) | 2026-10-01: a receipt over a run that reported fewer rows than its table lists, or over counts that are not numbers, is indeterminate, and the reader refuses a receipt whose counts or result no run writes |
| [0cu](docs/handoff/0cu.md) | 2026-09-25 to 10-01: a commissioning state line that comes back empty, names no state, or was never read makes its row unknown, so the receipt no longer reads commissioned over it |
| [0ct](docs/handoff/0ct.md) | 2026-10-02: an assertion the base run never reached is recorded red, and the gate fails a record that counts fewer assertions than the manifest lists (#371's follow-up) |
| [0cs](docs/handoff/0cs.md) | 2026-10-01: a red run whose suite died is refused, not recorded as zero red, and the gate fails a record that shows no red run for an engine change (#371) |
| [0cr](docs/handoff/0cr.md) | 2026-10-01: a qualification row's scratch tree never outlives the row: its permissions come back before it is removed, and a row stopped by INT, TERM or HUP removes it on the way out |
| [0cq](docs/handoff/0cq.md) | 2026-10-01: a qualification row's premise, mutation and command each run in a bash of their own, and a column that ran nothing reads unrunnable wherever the runner can hear it |
| [0cp](docs/handoff/0cp.md) | 2026-09-25 — a lesson or devlog entry settles only its writer's catches: `felix lesson` and `felix log` record who wrote each entry in written.log, and the unrecorded-catch prompt reads nothing else |
| [0co](docs/handoff/0co.md) | 2026-09-25: a `qualification.tsv` holding a NUL byte is refused as a whole, through the one read |
| [0cn](docs/handoff/0cn.md) | 2026-09-25: `felix qualify --gate` fails closed. One read of the table, a failed read refuses with exit 2, a short run refuses, and the gate always says why under `qualified FAIL` |
| [0cm](docs/handoff/0cm.md) | 2026-09-25 — the needs-count flake was printf into grep -q under pipefail, not a failed read; qualify's membership is a case in the shell now, and an unreadable qualification.tsv is said, not resolved |
| [0cl](docs/handoff/0cl.md) | 2026-09-25 — the project scripts read a pipe's answer from the whole list: a README change under --public-readme and a monitoring change in sv2-apps are no longer read as absent |
| [0ck](docs/handoff/0ck.md) | 2026-09-24 — bootstrap's rendered gate workflow keeps no credential after its checkouts |
| [0cj](docs/handoff/0cj.md) | 2026-09-23/25 — stranded work audited and backed up, the landing actor designed and put first, the founder's batch landed |
| [0ci](docs/handoff/0ci.md) | 2026-09-25 — the context cap the founder counted on did not exist, and a session started from now on summarizes at 500K |
| [0ch](docs/handoff/0ch.md) | 2026-09-25 — no engine test reads a pipe through a grep that can stop early: fifty sites converted, and a suite lint refuses the shape |
| [0cg](docs/handoff/0cg.md) | 2026-09-24 — the Actions outage measured: a spending cap, not capacity; a push to main now reuses its pull request's green run of the same tree |
| [0cf](docs/handoff/0cf.md) | 2026-09-23 — the public README rewritten for a general reader first, with the Felix mark, and checked against the code three times |
| [0ce](docs/handoff/0ce.md) | 2026-09-24 — the 44 red rows every Mac recorded since #308 were tests/red moving TMPDIR, which macOS's mktemp ignores; red now runs the suite in the caller's TMPDIR |
| [0cd](docs/handoff/0cd.md) | 2026-09-24 — the megabyte-line audit assertion timed by CPU and shown red, then handed to the session that already had it |
| [0cc](docs/handoff/0cc.md) | 2026-09-23/24 — the unattended template left two credentials for the model to read, measured on the pinned binary and closed upstream of the model |
| [0cb](docs/handoff/0cb.md) | 2026-09-24 — the unattended model step could read its own API key from /proc, measured on ubuntu-latest, and the template now denies it |
| [0ca](docs/handoff/0ca.md) | 2026-09-24 — handoff sections cannot collide: a session adds a file, and one fold of main gives the ids |
| [0bz](docs/handoff/0bz.md) | 2026-09-23/24 — restart moments scoped and placed: step 1 names a session running an older engine, and the founder allowed one line mid-session |
| [0by](docs/handoff/0by.md) | 2026-09-23/24 — every stuck PR triaged, why the night went stale, and the landing actor designed (not built) |
| [0bx](docs/handoff/0bx.md) | 2026-09-23 (day) — a turn another hook woke ended unchecked, measured on the real binary, and the Stop hold now knows its own chain |
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
