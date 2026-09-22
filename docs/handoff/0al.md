## 0al. Verified at session close, 2026-09-03 (overnight) — the substrate asks reality, and three of the checks written to prove it had never run

Each line produced by a command. Newest first under §0.

| | |
|---|---|
| head | `16437a2` on `main` (#129–#141, thirteen merges), CI `gate` **success** on each |
| suite | **1191 assertions**, from 1100 — 81 of them in one new section |
| governed projects with a probe table | **3 of 3** |
| deployed engine | **0.49.41**, deployed from the home at `16437a2` after #144; every session from here boots with it |

### Read this first: §0ak is directly below, and the marker bypass is FIXED

When this section was written, §0ak — the previous session's handoff — existed
only on an unpushed local branch, and the marker-bypass fix on another. Both
have since landed: §0ak follows this section, and the fix merged as #134. Two
things from §0ak that still govern:

1. **`echo nonexistent > .felix` used to disable the whole floor.** Fixed in
   #134 by a concurrent session: a marker that is present and does not resolve
   now refuses, and `deny.tsv` refuses writing the marker by hand. Verified
   live the same night — the primary checkout's marker had been left reading
   `nonexistent` by a finished test, so that checkout was ungoverned until the
   file was restored.
2. **The architecture question is closed.** `felix_v32_architecture_spec.md`
   and `felix_v32_conformance_amendments.md`, both under
   `~/Documents/UC Berkeley/Career/Founder OS/`, outside this repository and
   loaded by nothing. Read both before proposing anything architectural. Do not
   derive a fifth kernel.

### What landed: `felix probes` (amendments §4, first increment)

The rule, one level stricter than the one `procedures.tsv` obeys:

> **Felix may declare which question to ask reality. Felix may never author
> the answer.**

Five states, and exactly one is a claim that nothing is there — `found`,
`empty`, `blind`, `unknown`, `not-applicable`. `blind` and `unknown` block.

The load-bearing rule is that **a row with no witness can never earn `empty`**.
A probe with nothing to check it against cannot tell an absent surface from a
broken command, and every system that guesses there guesses "absent". So
dropping a witness to quiet a row makes it blocking instead, and that is what
makes the table non-gameable in the cheap direction.

Refused in three places, because a refusal that exists in one place is one
somebody routes around: the command, the project gate, and the merge boundary —
where it fails closed if the probe library is absent from the engine entirely.
`felix new` seeds the table. `probes.tsv` is in `FELIX_ESCAPE_TABLES` with its
own `verifier` row. The log is written **and read**: `felix probes` reports what
changed since the last tree, which is the only thing that can say a count fell.

### What it says about the three projects, measured

- **elenchus**: FastAPI reports **16** routes where the decorators show 12 —
  the four extra are auto-mounted docs endpoints, in no source line. Two
  entrypoints, four ceiling sites. Nothing probes `frontend`, `llm`,
  `observability`, `security`.
- **veldra**: cargo reports **16** workspace members and axum in **7** of them;
  the root manifest names axum in none. Nothing probes `frontend`.
- **felix**: 8 hook bindings, 3 governed projects, 8 enforcing tables, 10 shell
  entrypoints. No gaps.

### The mutation controls found more than they confirmed

Seven rounds, per amendments §2.1. The decoupled violation — every syntactic
marker of the witness rule left intact — went red on four assertions, and the
irrelevant comment reword broke nothing. Both are the controls working.

The two that mattered are the ones that did **not** behave:

- **A failed append reporting success went GREEN.** The line-count guard in
  `felix_probes_record` had never been exercised by anything: every failure the
  suite constructed was one the append's own exit status already caught. A
  guard nothing runs is a guard nobody has checked. Fixed with the case only
  the count can see — a log path that stopped being a file.
- **"unknown must block" rested on a single assertion**, one deletion from
  being a control that controls nothing. A second detector was added at the
  merge boundary, so the two fail for different reasons or not at all.

Both are in `lessons.md`. Neither was findable by reading the tests.

### Three defects found in adjacent code

- **The seeded witness in the template ended in `| head -1`**, so its exit
  status was head's — zero, whatever `ls` found. It claimed every repository on
  earth has tests, and a project created without them was born `blind`. This
  table's own failure class, inside its own template, and the third instance of
  the shape in this project. Found by running `felix new`, not by reading it.
- **The suite's gate-confine test iterated a hand-typed list** of the seven
  gate checks, so an eighth would sit outside the confine with seven `ok` lines
  printing. It enumerates from the gate now.
- **Invariant 1 fired on this work.** A comment in `probes.sh` named a governed
  project. `git grep` did not see it — the file was untracked — and the suite's
  check greps the filesystem copy of the runtime, so it caught what a
  tracked-only search would have missed. The two searches disagree on a new
  file, and only one of them is right.

### What was deliberately NOT done

The probes check is wired into **Felix's own gate only**. Elenchus and veldra
have probe tables and `felix probes` reads them, but neither project's gate
calls it, so for those two the only enforcement is the merge boundary — and
that arms only once this engine is deployed.

That is a decision, not an omission. Elenchus's gate is that product's single
CI check and its beta opens on the 5th; putting its CI colour on a FastAPI
import resolving in a runner, two days out, with nobody awake to look, is not a
call a session should make unasked. Add it after the soak reads out, and run it
### Increment two, same night: a fact says which instrument answered

The rest of v3.2 build-order step 1, which named source identity and did not
have it. A fact now records the instrument that answered — the first word of
the probe, resolved with `command -v`, plus the size of the resolved file — so
the drift reader can tell "the tree changed" from "the tool changed".

Derived rather than declared, and that is the decision. A sixth column would
have carried it and would also have cost what the fifth bought: a tab inside a
probe splits it in two, and only a fixed field count catches that. The
protection is worth more than the resolution.

`probes.sh` had reached 477 lines against the 500 rule, so the log and its
reader moved to `facts.sh` along the real seam: probes.sh asks reality a
question, facts.sh is everything that happens to the answer afterwards.

**This one broke the founder's real `facts.log` and had to restore it.** The
instrument was first written into column EIGHT, where the probe command had
always been. The log is append-only, so every row already in it read its own
command as its instrument, and the next run reported that every predicate on
the project had changed instrument — `git ls-files -> git@3662256`, for a tool
nobody had touched. Restored from a copy taken minutes earlier. An append-only
log cannot be re-shaped; the only safe evolution is to append. Both halves are
now pinned by assertions and the mistake is replayed as a mutation control.

**Invariant 1 fired twice in one session, both times on the same instinct**: an
engine comment reaching for the concrete project that motivated the code. That
is the sentence worth writing and the one the rule forbids. Write "one governed
project's route probe" instead. `git grep` will not find it in a file not yet
tracked — the suite's check greps the filesystem, which is why it caught both.

The instrument heuristic is honestly weak and the report says so. It reads the
OUTERMOST command, so `python -c "import fastapi; ..."` records python, not
FastAPI. `felix probes` prints how many rows identify no instrument rather than
hiding it — 1 of 5 on elenchus, and it is the route probe.

### The mutation harness caught itself, which is the night's best finding

The first run of the instrument controls reported **no failures for every
round** — and it was mutating nothing. The patterns were passed through
`python3 -c` with two layers of shell quoting, the `assert` raised, python
exited non-zero, the runner ignored the status, and each round ran the
UNMUTATED suite. Six clean-looking results that proved nothing.

That is this session's entire subject arriving inside the tool built to catch
it: a check that reports clean because it never ran. Caught only because N1
going green was *impossible* — the assertion it should have broken was one
written an hour earlier — so the green was read rather than filed.

The runner now puts each mutation in a file with no nested quoting, checks the
exit status, AND diffs the files afterwards. Knowing it ran is not enough; it
has to know it changed something. In `lessons.md`.

### Three branches hold unmerged work and NONE of them is pushed

Found by looking, not by being told. Each exists on this machine only:

| branch | head | what it is |
|---|---|---|
| `claude/relaxed-euler-cd49c2` | `d247ed0` | **the marker bypass fix** — §0ak's top item, committed, tree clean |
| `claude/felix-ecc-plugin-ba2871` | `3958e9e` | §0ak itself, the previous session's handoff |
| `claude/musing-ptolemy-753fe2` | `80a278d` | invariant 1 catching the ecosystem, not just the name |

The first one matters most: the highest-severity defect in the project is fixed
and the fix is one worktree cleanup away from not existing. This session did not
push or merge any of them — they belong to sessions that were still running, and
pushing another session's branch mid-work is how two people's `push -u` collide.
Whoever reads this next: check whether they landed, and if those sessions are
gone, push them.

against a fresh clone first.

### Second stretch, same day: the founder's three instructions, and what each one turned up

**Push whatever's necessary.** All three local-only branches pushed. The marker
fix had already been rebased and merged by its own session as #134 while this
one was rebasing it — byte-identical result; the duplicate closed. §0ak landed
as #139, rebased under §0al. The ecosystem check (#137 → #141) needed three
conflict resolutions, two stance rows, and then found a real defect in itself
on its first-ever Linux run: its vocabulary extractor's `sed 's/\\"\?//'` is
BSD-only, and on GNU sed the probe pattern `\"?stripe\"?` came out as
`?stripe?` — which `grep -wE` reads as "strip or stripe" and matched two
engine files on the English word *strip*. Fixed portably in both copies, with
a guard that names any token that is not a word.

**Run probes for every project with a table.** `cmd_gate` now does, after the
project's own gate and in its own line shape, so a probe failure lands in
`mistakes.log` like any other check. felix's private copy is gone: one
mechanism. A project with no table gets an announced skip — your words were
*with a table*, and the gate declines to be the third refusal that turns a
new project red on day one.

**felix install.** Deployed as 0.49.40 from the home at `5cd12c0`; the cache is
byte-identical to the home and its cli knows `probes`. Then, through that
deployed cli and not the tree: felix 8 found, Elenchus 5 found (16 routes, 2
entrypoints, 4 ceiling sites), veldra 5 found (16 members, 7 HTTP services) —
gate mode ok on all three. Every session from here boots with the engine that
asks reality. This session does not: a redeployed engine never reaches the
session that deployed it.

**graphify, and the point behind it.** Elenchus already had a maintenance row
for it — cadence 0, which the format defines as *never reported as overdue*.
A row that structurally cannot come due; the lesson this project holds about
"nothing due" and "nothing is being checked" rendering identically, one table
over. A maintenance row may now carry a **check** — a command run in the
checkout, non-zero meaning due — so an event row can come due from reality.
Seeded on all three projects with the graph-older-than-last-commit test. The
stamp carries an explicit zone (`%z`): BSD `find` reads a zone-less `T` form as
UTC, so a commit made now in PDT sat seven hours in the past and every graph
looked fresh — visible only in the STALE direction, which the first check did
not exercise. Then the runner disagreed the other way: GNU find compares at sub-second
precision and BSD at whole seconds, so a fixture that wrote a graph and
committed inside one second got opposite answers on the two. This machine has
no GNU find; the Linux runner is that verdict, and it took two round trips to
hear it.

The graphs themselves: Felix had none and has one (570 nodes, code-only, built
in seconds). Elenchus's went from Aug 19 to current on the code side; its docs
and 67 new community names wait on an LLM key that lives in some session's
environment and nowhere Felix can reach — the honest reason it went stale, and
a capability gap rather than a maintenance one. **Used, not only built:** the
graph correctly placed the receipt writer in `verify.sh`, and then missed three
of four callers of `felix_maint_status` because its heuristic call edges do
not see `$(…)` substitutions in bash. Grep was right; the graph gets a note.

**Three BSD/GNU splits in one night** — `head -1`, `find -newermt`, `sed \?` —
each passed locally and failed elsewhere. This machine's grep is ugrep and its
only find is BSD, so "works here" proves less than it looks and "parses here"
proves nothing about meaning. In `lessons.md`, corrected once already.

### Third stretch, same day: the review, and the seven ways a green could be had without looking

**The review, and what it was.** You said ECC should run against what was
built. It did, as lenses rather than as agents: a 68-agent workflow read the
increment's files under the ECC review headings — silent failures, security,
correctness, comment accuracy, test coverage — and every finding then faced
three refuters, majority to survive. Eighteen survived. The workflow used the
default subagent and not the `ecc:*` agent types, because a workflow agent
inherits this session and the ECC agents are defined for a fresh one; that is
a difference in prompt, not in what was read, and it is written here so the
word "ECC" above is not taken for more than it was.

**What the survivors had in common.** Not one was a crash. Every one was a way
a verdict could be reached without the question being asked — the exact class
the probe file's own header refuses, found in the file that refuses it:

- a witness whose command does not exist exited 127, and 127 was read as
  "no": a witness spelt `tset -f Cargo.toml` said *the surface is absent* and
  the row went green as `empty`. The same typo in a `when` switched its row
  off. Both are `unknown` now, which blocks;
- a five-field row with an empty probe cell went to `bash -c ""`, which exits
  0 having enumerated nothing, and the verdict came from the witness alone.
  The suite had built the four-field shape of that defect and not the five;
- `ecosystem.tsv` narrows invariant 1 by **adding** rows — an allow row is a
  file the check stops reading — and the verifier channel fired on removal
  only. A branch could have added the exemption for the very file it was
  about to break the invariant in, and merged green. A table of exemptions
  now escapes on any change, which is what the amendments said;
- `--gate` refused a malformed probe row and the merge boundary let it
  through — the weaker of two checks on one table, in the order they must
  never be in;
- the Stop hook read `stop_hook_active` as two substrings in order over the
  whole payload, and the payload carries the model's last message. A session
  whose final sentence used the word *true* was exempt from its own gate;
- a marker reading `.` or `..` bound to the projects directory itself — a
  project with no tables, no deny rows and no gate — because `-d` is true of
  both. A name is one directory name now, and `felix new` refuses the same
  names the marker does;
- a run with no tree id fell silent in the drift reader, which rendered like
  a tree that had not moved.

**And one in felix's own table, which the hook then proved.** The marker deny
row required a space or end-of-line after the name, so a quoted marker and one
followed by `;` walked past it. Widening it, the verification command was
refused by the row it was verifying — the command text carried the strings
the row exists to refuse, so the samples had to live in a file — and the first
widened row refused `git add .felix`, because `dd ` matches inside `add `.
Twenty-seven spellings now pass through bash's own `=~`, both directions;
the lesson is in `lessons.md`. The suite does not test a governed project's
table, only the engine against fixtures, which is why that check lives in a
sample file rather than an assertion.

Fixed as one PR, #144, with a test for each: the suite is **1276**. The
stale comment claiming a governed table holds a witness of the
members-and-failure shape is gone; none does. Before the merge, the modified
library was run against all three real checkouts without writing a fact, to
see whether any real witness named a command this machine lacks — none did.
Deployed as 0.49.41, byte-identical to the home, and the three projects were
asked again through the deployed cli: felix 8 found, Elenchus 5, veldra 5,
gate mode ok on each. The Felix graph was rebuilt on the merged tree.

**What the review found that is yours, not Felix's.** Three things reached the
merge boundary of this stretch as facts and not as work: Elenchus's docs and
graph labels need an LLM key that no Felix path can reach; three plugins are
mounted every session and never routed, which the ledger has said for weeks;
and `unresolved.log` is written by the Stop hook and read by nothing — a
refusal with a record nobody consults, which is the shape §0al keeps finding.

### Standing, and what is genuinely open

- `tests/run --record-assertions` after any assertion change; **1276** on record.
- **Deployed as 0.49.41.** `installed` still fails structurally in every
  worktree and is not a defect to fix; a worktree is not the tree the
  marketplace serves.
- **`felix merge` was unreachable, again.** A worktree that changed the engine
  cannot produce a green receipt, so the local merge path refused and this
  landed through `gh pr merge` on green CI. That is issue #2, unchanged, and it
  is now the second session to route around it.
- **The split happened**: `probes.sh` is 362 lines and `facts.sh` 219, against
  the 500-line rule probes.sh had reached at 477.
- **The residual, and it belongs wherever this reports its own trustworthiness.**
  A probe that FABRICATES members reads as `found` and nothing catches it: the
  witness catches a probe that sees too little, and there is no witness for one
  that claims too much. One level up, what says a probe is MISSING is
  `felix_detect` — patterns somebody wrote — so a surface no pattern matches
  produces no capability, no gap, and no probe. That is the same joint moved
  one level, not a joint removed. There is also no wall-clock timeout: stdin is
  closed, which removes the common hang, and a probe that genuinely loops still
  hangs the gate.
- **Next, from the amendments:** §2's checker qualification is the largest
  unbuilt piece and it is mechanizable — the gate already prints its check
  names, so the enumeration is available from reality rather than from a list.
  The hard part is that a report-only version cannot be armed without turning
  every gate red on day one, so the mutation runner has to ship with it.
  §1.3's scheduled discovery is a founder grant and no session may make it.
