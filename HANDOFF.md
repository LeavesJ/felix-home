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
state", with the next id (after 0bt comes 0bu). Move the section it replaces
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

### 0bt. 2026-09-22/23 — the table validator (queue item 2, step 1) shipped, and a rename that hid an escape

**Deployed: engine 0.49.150**, from the home checkout, verified against
the tree. Both merges passed `felix gate` on their exact trees and CI, and
were landed with `felix merge` from fresh clones.

| PR | What | Engine |
|---|---|---|
| #291 | `felix_changed_paths` lists a rename's old path (`--no-renames`), so renaming an enforcing table away fires `verifier` | 0.49.144 |
| #298 | `lib/table.sh`, `templates/schemas.tsv`, `bin/schema-check`, and the gate's `schema` check | 0.49.150 |

**What exists now.**

- **One row definition.** A row is any line not matching `^[[:space:]]*(#|$)`
  in the C locale, split into exact tab cells. It is byte-identical to the 42
  reader sites that already filter that way. The validator refuses the shapes
  on which two reader families in the engine read different rows or split
  cells differently:
  - `indented-comment`, `whitespace-line`, `nonascii-lead`;
  - `carriage-return`, `no-final-newline`, `nul-byte`;
  - `encoding`: strict RFC 3629, byte by byte, because macOS `iconv` passes
    code points above U+10FFFF, which macOS awk cannot read;
  - `symlink`, `empty-cell`, `cells`;
  - `empty`, where the table's row says emptiness is never legitimate.
- **`schemas.tsv`, engine-only.** It has 29 rows of `table lives columns
  empty`, 27 for the tree and 2 for memory: every tracked table kind; `maintenance.log`, `capabilities` and
  `autonomy` under their own names; `procedures.tsv`, which nothing has
  written yet; and the owed memory rows for `lifecycle.log` and
  `decisions.log`. Emptiness and absence meanings are comments that cite
  functions, not lines, so keeping them true costs no escalation.
- **The `schema` check.** It enumerates tracked files plus untracked files
  that are not ignored. A `.tsv` with no row fails. A declared table that
  nothing carries is a note and does not fail, because the public snapshot
  leaves `.snapshot-ack.tsv` behind. The check fails when absent.
- **Protection.**
  - The engine's `schemas.tsv` is in `FELIX_ESCAPE_TABLES` by its path, so a
    product's own `schemas.tsv` is not touched.
  - `count:` verifier rows guard `table.sh` (23 refusal sites) and
    `schema-check` (7).
  - 15 qualification controls are kept from 42 authored blind. All six types
    are met under #296's type rule, and `qualified` now reads 69 controls
    across 7 checkers.
- **Fixed on the way.**
  - `felix route --ack` folds tab, CR and LF in the reason to spaces.
  - `bin/memory-scan` knows `lifecycle.log`.
  - `lib/lifecycle.sh`'s dated exception to rows-first is closed.

**How it was checked.**

- **The map.** Eight agents mapped every table and 507 parsing sites.
- **Contract review.** Four refuters took the contract before code:
  - trust found the rename hole, now #291;
  - false-pass found locale and encoding splits;
  - portability found that stale rows would have turned the published
    snapshot red;
  - omission found non-`.tsv` tables and the memory-scan gap.
- **Blind review.** Three agents worked without reading the source:
  - a qualification author, 42 controls, 41 met;
  - an assertion author, 592 assertions, 576 passing first time;
  - a black-box adversary. It found that awk took `k=v/` and `-` for an
    assignment and for stdin, that `tail` took `-d/` for an option (each
    skipped a table in silence), the iconv range, a NUL last byte hiding a
    missing newline, and an unreadable schema reading as exit 1. All are
    fixed and pinned in the suite.

**Founder, and it blocks every merge until done.** #298 added two rows to
`projects/felix/risk.tsv`, which is a commissioning table, so the commission
policy hash moved. The grant reads `[!]` and the receipt reads stale, and
`felix merge` refuses every felix-home pull request on it; this section's own
PR waits behind it. The gate itself still passes. The act is the founder's
(§0aq, §0bl; roadmap §6): in the home checkout, `felix autonomy --allow
commission`, then `felix commission`, then commit the new
`projects/felix/autonomy.commission`. Discovery has nothing to adopt for felix
tonight, so the run declares nothing and installs nothing. It was scheduled
for Sep 26-27; with four engine branches queued in other sessions, sooner
unblocks them.

**Open, in roadmap order** (Phase 0 of `docs/2026-09-23-roadmap.md`).

- **Owned by other sessions tonight:**
  - the Felix development session has `claude/deny-reads-the-command` (deny
    rows that read prose and heredocs, carried from §0br),
    `claude/gate-workflow-filter` and `claude/epoch-portable`;
  - #300 fixes the facts log's concurrent-writer check;
  - the audit-decode fix and the deny-scope column (`deny.tsv` gains a
    column, so its schema row changes with it) are on their own branches.
- **Unowned:** the obligations request on a project in a second ecosystem;
  the probe of `felix gate` on a runner with no `claude` CLI; checking the
  five unverified Elenchus candidates against what Elenchus already records,
  before the founder admits or refuses them.
- **Phase 1** then carries `coverage.tsv`, born on this validator.

**Recorded, not done** (each needs a decision or a row to force it):

- Per-project table validation inside `cmd_gate`. A stranger's own tables are
  unchecked until the roadmap's ledger relocation moves them into their
  repository, and that is where this belongs.
- Typed row shapes, for `red.tsv`'s three kinds and the provider answer files.
- Duplicate keys, and glob characters in space-separated cells.
- An inventory of reader arities: a narrower read folds the extra cells into
  its last variable, by design.
- `decisions.log` decline rows still lack a session and a route. The Stop hook
  consumes the ack and knows both.

**Chips raised for other sessions:** the commission IFS trap (landed as
#289); qualification hardening (landed as #296); red.tsv comparing engine
trees rather than commits (#294); concurrent gates failing each other's
`probes` through `facts.log`'s whole-file line count (#300, open).

**Traps paid for this session** (memory: `landing-engine-prs-under-concurrency`,
`fact-gate-keys-on-command-tokens`):

- **Main moved nine times while two PRs were in flight** (#289, #290, #292,
  #293, #295, #296, #297, #294, #299), and six of those took an engine
  version. Every move staled the open PRs' version and red.tsv. #298 lost
  four cycles of about 40 minutes each under a load average near 100.
- **What ended it was asking.** `ListAgents` showed four busy sessions with
  engine work. Each agreed to hold its engine merges until #298 landed, two
  paused their suites to cut load, and #298 merged on the next cycle.
- **Update a pushed branch by merging main in, not rebasing**, since the deny
  table refuses a force-push. When the merge conflicts in `plugin.json`,
  start from main's copy and set the version there. Rewriting the version
  line in the conflicted file committed both sides with their markers once.
- **From a worktree, `felix gate` runs the home's `gate.sh` and
  `qualification.tsv`.** The branch's own block runs only with
  `FELIX_HOME=<tree>`. This is lessons.md 2026-09-02, paid again because no
  route matched and it was never surfaced. `felix merge` needs the
  commissioning receipt in the real home, so gate and merge from a fresh
  clone without the override.
- **Two gates at once on one project** fail each other's `probes`, through
  `facts.log`.
- **The race test injects on `diff --name-only`.** A flag placed between
  those words silenced it.
- **The command guard keys on words in the command line.** A scratch script
  run with bash avoided it three times of three.

---

## Index of earlier sections

Newest first. Each file is the section exactly as it stood.

| § | Section |
|---|---|
| [0](docs/handoff/0.md) | DECIDED 2026-08-14, AMENDED 2026-09-13 — this repository is private, and a snapshot of the engine is public |
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
