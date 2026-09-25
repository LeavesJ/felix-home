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
- each takes the next id (after 0cf comes 0cg);
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

### 0cf. 2026-09-23 — the public README rewritten for a general reader first, with the Felix mark, and checked against the code three times

**No engine change.** `README.md`, a new `assets/` and
`projects/felix/snapshot.sh`, on `claude/public-readme-styling-e3d61b`.

**What changed.**

- **One README, layered by depth.** The founder asked whether a README can
  offer versions for different readers. GitHub renders one README with no
  toggle; the only in-page switch is an exclusive `<details name>` accordion,
  which hides what it doesn't show. The READMEs he named (OpenClaw, Hermes
  Agent, Stratum V2) keep one README and send depth elsewhere, and Hermes'
  parallel translations have already drifted. So: one file, general reader
  first, reference collapsed.
- **Order, from his brief** (keep the causal structure, drop the specialist
  words, story before vocabulary): the failure; how the Stop hold works, with a
  diagram of its real exit; "One change, start to finish", a money-transfer
  story with each step marked built or not, closing on the loop that is the
  trust plane and the part of the capability plane that exists; then guards,
  glossary, Try it, the CI comparison (couldn't-check and staleness first, as
  the market map says), limits, Status, direction, Install, Reference.
- **`assets/`.** The mark and the mark-plus-name lockup, light and dark, redrawn
  as vector from his brand sheet. The wordmark is outlined from Montserrat
  (OFL), with the sheet's square i-dot. The generator was session scratch and
  is not committed. The sheet's "Intelligence under control." and "Resolver"
  labels were left out: an unsourced slogan is what the README's register
  rules out.
- **`snapshot.sh` publishes `assets/`** where the source has it, and stages it
  only where one side has it, so both historic self-tests still MATCH. A full
  dry run from a scratch home whose main was this branch staged `assets/` and
  the README; audit clean (8 acknowledged, none open), no new secret.

**True of the engine, found by the review and now stated in the README:**

- The platform's `stop_hook_active` is shared by every Stop hook, so another
  hook's block spends Felix's one hold, and the release after a hold is not
  recorded.
- security-guidance, which commissioning installs, runs an `asyncRewake` Stop
  hook whose source says Claude Code sets `stop_hook_active` while it runs.
  Untested; a chip was raised to measure it.
- Exceptions are read only for Felix's own project; a product's rules live in
  the home, where no merge of the product sees an edit.
- `felix automerge --enable` turns on GitHub auto-merge, which skips
  `felix merge`. `ready --fix` re-enables plugins a route names.
- An edit to a gate script, or a skipped test, is not an escape.
- A probe's value changing at the same count and state does not stale a pass.

**Traps paid for this session.**

- **The suite reads the README.** `tests/run` near the audit section pins the
  Try it section: "held" exactly once there, `felix gate` with "straight away"
  only beside a condition, and several phrases verbatim. A reviewer said
  nothing reads the README; the snapshot dry run failed on it.
- `gh api markdown`: `mode=gfm` renders alerts and hard line breaks,
  `mode=markdown` renders anchors and no alerts, and neither runs mermaid or
  the themed `<picture>`.
- A plain-language rewrite drifts into overclaim. Three rounds of a
  fact-checker reading the engine found about thirty sentences that said more
  than the code does, most of them written to be simpler.

**Open.**

- **Publishing** is the snapshot command after the merge (§0bm), then a pull
  request on LeavesJ/Felix.
- **The social preview** (1280x640, made in the session) is set by hand in
  LeavesJ/Felix's settings.
- **Numbers the reviewers asked for:** what followed the roughly 76 holds with
  no rerun, the 3 holds outside the three causes, and how many deny firings
  were in earnest ("a handful").

---

## Index of earlier sections

Newest first. Each file is the section exactly as it stood.

| § | Section |
|---|---|
| [0](docs/handoff/0.md) | DECIDED 2026-08-14, AMENDED 2026-09-13 — this repository is private, and a snapshot of the engine is public |
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
