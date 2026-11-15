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
- each takes the next id (after 0gl comes 0gm);
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

### 0gl. 2026-11-13: the authority that holds main is built in shadow, first slice: its store, standing, door, the reading of his word, a reader's check and the reach test (trust step 4, stage 1, 0.49.343)

**What this is.** The first engine slice of the hosted authority (the 11-09 design, on main since 2026-11-13 as pull request 504) and of the founder's door (`docs/2026-11-10-trust-door-design.md`, §5 and §7). Five libraries (`lib/authority.sh`, `authority-paths.sh`, `authority-tick.sh`, `door.sh`, `door-read.sh`), two programs (`bin/reach-witness`, `bin/reach-probe`) and two commands: `felix authority init|status|tick|decide|log|verify` and `felix door`, with `felix door stop` as the brake. The document is `docs/2026-11-13-trust-step4-shadow-slice1.md`, with its PDF. The contract the tests were written from (revision 3), the review, the blind author's report and the logs are in the memory root, `audits/2026-11-13-trust-step4-shadow/`.

**His decision, 2026-11-13: "Build now, login this week".** The authority is built now and runs in shadow under his own login. It judges and records. Nothing it says counts and it holds nothing until three things are true: it runs as its own login, the reach test has passed, and he has given the first start at that login's desktop. The engine reads those as five conditions, and `felix authority status` prints a `why` line for each that does not hold: its own login (a), its files its alone (b), the code it runs out of a worker's reach (e), a first start at the console (c), a reach pass at the console (d).

**What is shadow.** Each line a tick prints starts with the standing. No other command reads the authority's store, log or ledger: the gate, the lander and the merge judge are as they were. In shadow the store's main follows the source's main forward, and a statement given under his own login is kept, marked `given: shadow`, and does not count. **A store started in shadow stays a rehearsal:** the authority's login runs `init` in its own home, and the shadow store is not carried over.

**What waits for the login,** and is his: making the authority's login and enrolling its fingerprint, the restart, the sharing settings, sitting at the screen for the reach test, and the first start. None was done. No login, account, key, token or App was made and no system setting was changed. Moving the authority to that login is a change of `FELIX_AUTHORITY_HOME` and of the rows of `authority.conf`, and of nothing in the code. That login also needs a copy of the engine and a `PATH` no worker can write: under his own login the `git` on his `PATH` sits in a directory he owns, and condition e says so.

**What it does not do yet.** Nothing lands, in either standing. A tick ends where the judge would begin. The judge, landing and the spending of a permission, a forge connector, and the signer with its keys are later slices, listed in the document's §7.

**Fixed from the mocks, and not copied.** His word is read in its order (V5f). A hold given after an authorization or an override takes it back, and a release after that hold does not bring it back (V6f). An override names the tree he was shown and holds for that tree alone (V31f). One function reads the founder-path policy for the door and for the decision, and a path with a newline is his (V43). A reader with a memory notices a dropped statement (V62). The confirmation's characters are two pairs at places the statement's nonce picks, with one try and a record of a refused one (the no-key run's VD3).

**The review.** One reviewer attacked the first build and reported fifteen findings, each with a script: a candidate that replaced `.felix` read `eligible`; a blind guess of the confirmation was kept on run 31; the user's attributes reached the merge; "console" was read once and from a `ps` that could fail; "the authority's alone" read three modes; the reader took a second start and a reused nonce. Each is fixed in the build or listed as open, and the reviewer's scripts were run again on the fixed code. The record is `review/findings-and-responses.md` in the audit folder.

**Measured,** on this Mac under a load average of 60 to 92. The four blind parts (2186 to 2189, 301 assertions) were red on main with no build (282 fail, 18 fixture controls pass, 1 skips) and pass on the build but the one skip, the probe's run on macOS. They found four lines of the door and the tick that were not the spec's, each fixed. The whole suite then found a fifth: the reader said `unverified`, a word the engine's wording contract (C18) refuses in a printed line, so the spec, the reader and part 2189 now say `not ok`. A rehearsal against this repository's main checkout decided 146 candidates in 52 to 54 s a tick (115 `conflict`, 22 `eligible`, 8 `nothing`, 1 `waits`); the door opened in 40 s and the brake reached its confirm line in 2 s.

**Not shown.** A second login, a switch of desktop, a fingerprint, a restart, a lock that works on this macOS, or a person. The reach test's probe was never run. "Live" was reached in a fixture where one login played both sides.

**Open.** Which copy of the engine the authority's login runs. What condition e does not read (the directories above the ones it reads, where a link's target sits, libraries a program loads, a login not named in `workers`). A source that login can read. The lock program for this macOS. The cost of a tick and of the door grows with the candidates, and no cache is built. A fetch's size is the source's to set, and one object the checked fetch refuses pauses each decision. A hand-written entry by the authority's own login reads `ok`: no statement is signed. The typed confirmation is one blind try in 361. The document's §7 has the list, and it is the items found so far.

**The founder's acts,** in order, for the day the login exists: the document's §8. A release needs him by name (direction row 49). The pull request is labelled needs-founder.

---

## Index of earlier sections

Newest first. Each file is the section exactly as it stood.

| § | Section |
|---|---|
| [0](docs/handoff/0.md) | DECIDED 2026-08-14, AMENDED 2026-09-13 — this repository is private, and a snapshot of the engine is public |
| [0gk](docs/handoff/0gk.md) | 2026-11-06: an owed engine deploy gets its window; new suites and gates wait for it (0.49.342) |
| [0gj](docs/handoff/0gj.md) | 2026-11-07: the two kinds #482 kept say what is true: `not-green` and `deploy-failed` (0.49.341) |
| [0gi](docs/handoff/0gi.md) | 2026-11-13: step 1's pre-registered rerun ran, and the method does not advance (trust step 1, a measurement; nothing in the engine or the specification changes) |
| [0gh](docs/handoff/0gh.md) | 2026-11-12: the budget row reads GitHub's usage report (stuck-PR spec R13, 0.49.340) |
| [0gg](docs/handoff/0gg.md) | 2026-11-13: the door's cases were run at a door with no key, and each ended as written beforehand (trust step 4, documents only) |
| [0gf](docs/handoff/0gf.md) | 2026-11-09: the hosted trust authority, designed around Felix holding main and tried on a local mock (trust-plane step 4, documents only) |
| [0ge](docs/handoff/0ge.md) | 2026-11-10: the founder's door is designed, its protocol tried on a mock, and his choice of surface recorded (trust step 4, documents only) |
| [0gd](docs/handoff/0gd.md) | 2026-11-09: slice 3's units read the bytes and names that land, and so do the base-side copies (trust step 3, A22 and A23, 0.49.338) |
| [0gc](docs/handoff/0gc.md) | 2026-11-09: the readers' merge detects no directory renames, as GitHub's merge does (S6.7, 0.49.337) |
| [0gb](docs/handoff/0gb.md) | 2026-11-09: P's instrument parts judge the candidate (trust-plane step 3, slice 3, 0.49.336) |
| [0ga](docs/handoff/0ga.md) | 2026-11-08: part 1495 compares two page runs with the ages they print put aside, so a minute boundary between the runs is not a failure (suite only, 0.49.335) |
| [0fz](docs/handoff/0fz.md) | 2026-11-08: the change readers' merge ignores the checkout's merge configuration (S6.6, 0.49.334) |
| [0fy](docs/handoff/0fy.md) | 2026-11-08: what the merge judges is what the provider squashes (trust-plane step 3, slice 2, 0.49.333) |
| [0fx](docs/handoff/0fx.md) | 2026-11-08: the merge boundary reads its policy and its instruments from P (trust-plane step 3, slice 1, 0.49.332) |
| [0fw](docs/handoff/0fw.md) | 2026-11-08: the trust-plane specification, revision 1: a model for each need, spec oracles, and a review packet without findings; the step 1 rerun is pre-registered |
| [0fv](docs/handoff/0fv.md) | 2026-11-07: the trust-plane design is final, releases fail closed, and trust rework goes first |
| [0fu](docs/handoff/0fu.md) | 2026-11-07: who authorizes a change that removes what a need checks |
| [0ft](docs/handoff/0ft.md) | 2026-11-06 to 11-07: the founder's decisions in the trust-plane revisit |
| [0fs](docs/handoff/0fs.md) | 2026-11-06: the shared resolver, the CLI, the table check and the status rows say could not tell when a read did not finish (0.49.330) |
| [0fr](docs/handoff/0fr.md) | 2026-11-06: felix cost makes one reading at a time and serves every caller from it (load slice 0, 0.49.329) |
| [0fq](docs/handoff/0fq.md) | 2026-10-29: the capability lane restarted, and the founder's decisions on what Felix is |
| [0fp](docs/handoff/0fp.md) | 2026-10-31: the engine says checked, never verified or proven (decision 1, 0.49.327) |
| [0fo](docs/handoff/0fo.md) | 2026-11-06: the evidence readers ask the judge's own question about evidence.tsv (0.49.322) |
| [0fn](docs/handoff/0fn.md) | 2026-11-06: the suite passes on bash 5.3, so the gate can pass on ubuntu-26.04 again (0.49.321) |
| [0fm](docs/handoff/0fm.md) | 2026-10-29: the knowledge graph's answer is handed to every prompt, and the ledger counts whether it was used (0.49.320) |
| [0fl](docs/handoff/0fl.md) | 2026-10-31: felix lane counts the capability lane's share of engine landings (slice 0, 0.49.319) |
| [0fk](docs/handoff/0fk.md) | 2026-10-29: the pipe lint reads every project script, and Felix's cloud check looks its entries up in a here-string |
| [0fj](docs/handoff/0fj.md) | 2026-10-28: contract D's blind parts hold their time windows under a loaded full gate (0.49.315) |
| [0fi](docs/handoff/0fi.md) | 2026-10-28: the audit's second wave, eight batches combined (0.49.313) |
| [0fh](docs/handoff/0fh.md) | 2026-10-28: the suite's two blocks that read the discovery cache no longer share a home with a hook's refresh |
| [0fg](docs/handoff/0fg.md) | 2026-10-28: the audit's first wave, nine batches combined (0.49.308) |
| [0ff](docs/handoff/0ff.md) | 2026-10-27: the founder's decisions of 10-23 to 10-27, and the documents that lived only on this Mac |
| [0fe](docs/handoff/0fe.md) | 2026-10-23: helper worktrees placed apart, in `felix inventory` and on the lost-work page (step 6 follow-up) |
| [0fd](docs/handoff/0fd.md) | 2026-10-19: Felix refuses a pattern kill |
| [0fc](docs/handoff/0fc.md) | 2026-10-22: the gate's N is measured, and D's cost clause is missed |
| [0fb](docs/handoff/0fb.md) | 2026-10-21: the parallel suite runner, `tests/run -j N` (gate friction D) |
| [0fa](docs/handoff/0fa.md) | 2026-10-19: the capability lane stays; need intake is built now, and capability authority waits on the trust milestones |
| [0ez](docs/handoff/0ez.md) | 2026-10-19: the lost-work page's awk failing exits 1, and a lint for gawk builtin names in lib's awk |
| [0ey](docs/handoff/0ey.md) | 2026-10-19: the mods round (#417) was measured, and what it changes for capability items 4, 6 and 8 and the input-rewriting floor |
| [0ex](docs/handoff/0ex.md) | 2026-10-18: the lost-work page, `felix monitor`, and three inventory fixes (Phase 0b step 6) |
| [0ew](docs/handoff/0ew.md) | 2026-10-18: the judge's base is a full ref name, and the deploy comparison reads main's stored tree against the whole cache entry, raw |
| [0ev](docs/handoff/0ev.md) | 2026-10-18: slot 3f, a child of the suite took its EXIT trap and emptied $TMP |
| [0eu](docs/handoff/0eu.md) | 2026-10-17: the stuck-PR page, `felix land --prs` and `--queue` (Phase 0b step 5) |
| [0et](docs/handoff/0et.md) | 2026-10-08: what the engine reads from a patch is the repository's, not a diff setting's |
| [0es](docs/handoff/0es.md) | 2026-10-08: a git read of the working tree that did not finish is unknown, never an answer |
| [0er](docs/handoff/0er.md) | 2026-10-08: a person's git colour settings never reach what the engine parses |
| [0eq](docs/handoff/0eq.md) | 2026-10-08: no engine entry point lets the caller's environment change what its tools print, nor how its shell runs |
| [0ep](docs/handoff/0ep.md) | 2026-10-08 — the setup step bootstrap renders runs on Node 24, and the suite holds each pinned commit to the runtime read for it |
| [0eo](docs/handoff/0eo.md) | 2026-10-08 — a Felix home whose path holds a space resolves through the pointer |
| [0en](docs/handoff/0en.md) | 2026-10-02: felix commission names every row that differs from the template's row for the same need |
| [0em](docs/handoff/0em.md) | 2026-10-08: a cache prune no longer stales a green receipt |
| [0el](docs/handoff/0el.md) | 2026-10-08: a commissioning check says it could not be asked by exiting 2 |
| [0ek](docs/handoff/0ek.md) | 2026-10-08: felix_declared refuses a capabilities file that is not a list of names, and reads one that is byte for byte |
| [0ej](docs/handoff/0ej.md) | 2026-10-01: the monitor says a declared-capabilities list it could not read, and never shows it as empty |
| [0ei](docs/handoff/0ei.md) | 2026-10-01: every other reader of the declared capabilities says the list could not be read, never that it is empty |
| [0eh](docs/handoff/0eh.md) | 2026-10-08: a pull request's default title is the newest commit the branch made itself, not a merge of main or what the landing wrote |
| [0eg](docs/handoff/0eg.md) | 2026-10-08: the second review of #401's tests, closed in tests only |
| [0ef](docs/handoff/0ef.md) | 2026-10-14: the autonomy chain (slots 4-6), carried onto the split suite and the locale rule |
| [0ee](docs/handoff/0ee.md) | 2026-10-08: `felix autonomy` has one writer at a time |
| [0ed](docs/handoff/0ed.md) | 2026-10-08: `felix autonomy --allow` says allowed only when the reader then grants it |
| [0ec](docs/handoff/0ec.md) | 2026-10-08: `felix autonomy --revoke` takes away what any reader honours, and fails closed |
| [0eb](docs/handoff/0eb.md) | 2026-10-14: the locale sweep (slot 3c, was 21+22), carried onto the split suite after 3+3b |
| [0ea](docs/handoff/0ea.md) | 2026-10-08: bash's own collation and the BSD text tools decide nothing by locale |
| [0dz](docs/handoff/0dz.md) | 2026-10-08: every engine sort, comm, join and uniq reads bytes in the C locale |
| [0dy](docs/handoff/0dy.md) | 2026-10-13: the fixture floor and the fixture git proof (slots 3+3b), carried onto the split suite |
| [0dx](docs/handoff/0dx.md) | 2026-10-08: a fixture git write in tests/run proves its repository sits under $TMP, a lint refuses the raw shape, and a moved remote is never green |
| [0dw](docs/handoff/0dw.md) | 2026-10-08: no fixture git command in tests/run can reach a repository outside $TMP |
| [0dv](docs/handoff/0dv.md) | 2026-10-13: unattended work runs only in the project's own checkout |
| [0du](docs/handoff/0du.md) | 2026-10-13: gate friction step 1, one suite pass per landing (PR A #432, A3) |
| [0dt](docs/handoff/0dt.md) | 2026-10-12: declared tools' reach, the pulse's settings and reach lines, and felix status |
| [0ds](docs/handoff/0ds.md) | 2026-10-11: every uses: in felix-home's own workflows is a commit sha, and the suite holds every workflow beside the harness to it |
| [0dr](docs/handoff/0dr.md) | 2026-10-10: a guide that narrows Felix is ignored, and the commercial radar adds two lines to specs not yet written |
| [0dq](docs/handoff/0dq.md) | 2026-10-11: the Stop hook holds once for each tree, reason and checkout in a session, and then records the unrun gate as a debt (slot 2a, part B) |
| [0dp](docs/handoff/0dp.md) | 2026-10-11: felix cost reads what a week of Claude Code cost, as input-equivalent tokens against the weekly cap (slot 2a, part A) |
| [0do](docs/handoff/0do.md) | 2026-10-09: the interface is built slowly and later, and until then every report Felix writes is shaped to become one of its surfaces |
| [0dn](docs/handoff/0dn.md) | 2026-10-01 to 10-02: a declared-capabilities list that could not be read is said as unknown by setup, maintenance, the stack plan, next, pulse and session start, never as dormant or owed |
| [0dm](docs/handoff/0dm.md) | 2026-10-07: a mods round for capability item 1, on 2.1.293, before any function hook is planned on |
| [0dl](docs/handoff/0dl.md) | 2026-10-01: readers of a project's hand-edited tables keep a last row with no newline, and never open a pipe |
| [0dk](docs/handoff/0dk.md) | 2026-10-01: a row appended onto a last line with no newline lands on a line of its own, in every engine writer that something else also writes |
| [0dj](docs/handoff/0dj.md) | 2026-10-01: adopting refuses a capabilities list it cannot read and write, and writes nothing anywhere |
| [0di](docs/handoff/0di.md) | 2026-10-01: a seeded commissioning check reads done only when its lookups ran to the end |
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
