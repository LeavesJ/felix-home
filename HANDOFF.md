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
state", with the next id (after 0bu comes 0bv). Move the section it replaces
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

### 0bu. 2026-09-23 — Phase 0: the Elenchus candidates checked, deny rows read the command the shell runs, three small items

**Deployed from this session: engine 0.49.149 (#299).** Three more are gated,
recorded and waiting, behind #300 (another session's, 0.49.151): **every
felix-home merge is refused until the founder re-stamps the commission**,
because #298 added rows to `projects/felix/risk.tsv`, a commissioning table.
Recording and gating still work. The queue after the re-stamp, agreed between
the sessions by message: #300, #301, the audit-decode fix, #303, #304. Each
merge owes everyone behind it a red re-run.

| PR | What | Engine |
|---|---|---|
| #299 | The `granted` count in the obligations sentence is asserted every run, against a fixture that makes the sentence print; the suite's standing skip | 0.49.149, deployed |
| #301 | Deny rows are refused only when they still match the command the shell runs: heredoc bodies, quoted messages, comments and line breaks stop being read as commands; `lib/deny-read.sh` | 0.49.152, gate pass, waiting |
| #303 | The repair ceiling and the auto-merge streak read the gate workflow's runs alone (`gate_workflow` in project.json, default gate.yml); the unattended template proceeds only when `felix repair` exits 0 | 0.49.153, waiting |
| #304 | The decision epoch is the same under any PATH: the instrument token is provenance and leaves the topology hash. Lands last: every receipt and the Elenchus candidates read stale once after it deploys | 0.49.154, waiting |

**The Elenchus candidates, checked (roadmap Phase 0, for Sep 26-27).** The six
unverified rows of the 2026-09-22 blind request were checked against the code
at `a45a985` and against every place Elenchus keeps a record, one agent each,
each verdict attacked by a second. The founder has
`~/.felix/memory/elenchus/commission/pdf/candidates-checked.pdf`; source and
the full verdicts are beside it (`candidates-checked.md`, `.json`). In short:
all six evidence commands fail on main for the reason they name and flip on
the obvious fix, and all six checkers are flawed (each can pass with its hole
open, or fail a reasonable fix). The launcher's `0.0.0.0` default was found by
Elenchus's own security audit of 2026-08-31 and dropped: it reached no report,
no DEVLOG item, no table. The untested forecast route is the strongest new
one: renaming it leaves 1,439 tests green. The roadmap listed five candidates;
`served_route_has_http_test` was the sixth, left off. After the epoch change
deploys, these rows read `stale` in `felix obligations` once; that is the hash
definition moving, not the facts.

**The deny change, and what measuring it found.** 175 refusals had been logged
(`says.log`, felix and elenchus). Replayed: 38 are now allowed, every one read
and confirmed prose or data; 132 still refused. Of those 132, more than 100
are real commands in scratch fixture repos (a marker written by `printf`,
`git remote add`, `update-ref refs/remotes`), the largest source of false
blocks, which no regex can tell from the governed checkout. 140 cases written
blind: the new reading agrees on 128, the old on 82. Three adversarial
reviewers found ten defects between them, all fixed: the semantic ones are
assertions, the performance ones measured. Their out-of-scope findings are
filed below. The
reader was run under macOS's BWK awk here, and its assertions passed on CI's
Ubuntu runner; mawk and gawk were not run locally.

**Filed as separate tasks, several already running in their own sessions:**
deny rows scoped to the governed checkout; the widening direction (commands a
row names that the raw string never matched); three rows that refuse reads and
dry runs (escape tables, a person's); `felix_deny_subject`'s bash 3.2 cost on
large payloads (12-45 s on some 31K payloads, every call); `lib/audit-read.sh`'s
one-character `split` on BWK awk; Elenchus's copy of the unattended step.

**Still open in Phase 0:** the marker deny rows for Elenchus and Veldra (after
#301, so the prose refusals do not spread; Veldra has no deny.tsv); the
obligations request on a second project, answered blind; the GitHub runner
probe with no `claude` CLI. The founder admits or refuses the Elenchus
candidates on Sep 26-27 and re-stamps the commission after #298.

**Traps paid for this session:**

- BWK awk splits on every line break when `split()` is given a
  one-character string separator, whatever RS is. Use a regex separator.
- bash 3.2's `${s//pat/rep}` is quadratic: 14 s over a 31K command. A hook's
  per-call work is `[[ =~ ]]` or one awk process, never parameter expansion.
- An awk program held in a bash single-quoted string may hold no apostrophe,
  not even in a comment; one silently disabled the hook in a working copy.
- An "allowed" assertion whose payload the old matcher already allowed tests
  nothing: check every such payload is refused by main's library first.
- A PR with conflicts gets no `pull_request` CI at all; merge main and push.
- `felix pr --create` opens a draft when the gate has not passed on that
  tree; `gh pr ready` after the landing gate, then `felix merge`.
- zsh reads `$var:e` in `git show $mb:engine/...` as a modifier; brace it.
- Engine merges went through one queue agreed between sessions by message
  (#298, #300, #301, the audit-decode fix); each merge costs everyone behind
  it a red re-run.

---

## Index of earlier sections

Newest first. Each file is the section exactly as it stood.

| § | Section |
|---|---|
| [0](docs/handoff/0.md) | DECIDED 2026-08-14, AMENDED 2026-09-13 — this repository is private, and a snapshot of the engine is public |
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
