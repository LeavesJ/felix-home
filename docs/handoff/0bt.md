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
