## 0an. Verified at session close, 2026-09-04 (overnight) — the provider protocol was exercised on real answers, and the admit phase grounds what a model names

| | |
|---|---|
| head | `237a2b9` on `main` (#158–#168, eleven merges), CI `gate` **success** on each |
| suite | **1470** passed, 0 failed, manifest re-recorded |
| deployed engine | **0.49.60**, deployed from the home checkout after each merge |
| provider rows | **all six answered, 0 awaiting on all three projects** |
| the audits | felix 69/100 C, elenchus 89/100 B, veldra 87/100 B |
| open, and the founder's | one, below. It is what stopped the next increment rather than a preference |

### PAUSED mid-change, 2026-09-05 — read this before the list below

**RESOLVED the same day, and the branch is gone.** #172 merged it at 09:28
(`bc8fb8d`, an ancestor of `main`), and the ref was deleted in the 2026-09-12
branch cleanup; its commits are kept at `refs/pull/172/head`. The paragraph
below is left standing because it is what the session that paused actually
wrote, but nothing in it is work to pick up — do not go looking for the branch.

One branch holds unmerged work: **`feat/stack-rows-carry-their-grounding`**,
pushed, one WIP commit, **three assertions red and each diagnosed in the
commit message**. It is the founder's decision from this morning built out —
`stack.tsv` rows carry a sixth column saying who grounded them, and the admit
phase writes its declares — and it is not on `main`, so nothing described in
its commit is true of the engine any session boots with. Finish it by fixing
the two fixtures the commit names, running the suite green, and merging
through the usual chain. Do not rebuild it.

Deployed engine is `main`'s, verified. Working tree clean.

### Start here, if you are the next session

0. **The six provider requests are answered. That queue is empty.** §0am's
   headline outstanding item is discharged on felix, elenchus and veldra, and
   every one of them now reads `0 awaiting a session`. What the protocol found
   in the doing is below.
1. **Read the open decision below before touching the admit phase.** It is not
   a preference and it does not have a safe default: applying a `declare` to
   `stack.tsv` would quietly change what `DECLARED` means to the policy that
   #159 just built, and the policy's whole load is that `DECLARED` means a
   person decided. That is why the increment stopped there rather than
   guessing.
2. **Answer the four remaining provider requests**, on elenchus and veldra.
   The protocol works — it was exercised end to end on felix — and §0am's
   instructions for it are still exactly right. Two checkouts:
   `/Users/a14808/Documents/Elenchus` and `/Users/a14808/ReserveGrid-OS`.
   Expect the admit phase to say something about those projects' nominations
   that it could not say about felix's.
3. **Then PR 4**, the autonomy grant and the background resume. §0am's
   standing rule about engine work and the 5th/6th still reads as it did; the
   founder's live instruction covered the sessions of 09-03 and 09-04.

### What landed

**#158 — the protocol's first real answers, and the defect they found.** Both
of felix's provider rows were answered by running the skills they name. The
constitution audit scored `projects/felix/CLAUDE.md` **69/100 (C)**: the two
weakest criteria were the two heaviest, and both for the same reason — the
file carried the *conceptual* architecture completely and the *physical* one
not at all. Architecture and Non-obvious patterns were added and the
invariants were left alone, because they accrete from `felix promote`. The
recommender returned 8 rows and **zero mcp rows**, which is the honest answer
for a stack with no database, no frontend and no external API — the two
candidates that exist are both closed questions.

The defect: the provider report read each row's classifier out of field 4,
which is the *automation* shape's capability column. A score row has three
fields and its third is the grade, so the grade rendered as 25 spaces of
padding. `commissioning.log` kept it, which is why no check that reads the log
could see the loss, and the report is the only surface that lists what a
provider named. The shape registry already knew a score row has three fields;
nothing had ever asked it *where the classifier is*.

**#159 — one install policy.** `felix_admit(tier, grounding)`. Three places
decided whether something may be mounted with nobody present and two of them
disagreed about medium. The disagreement is **not** collapsed, because it was
never a bug: a person who writes a medium row into `stack.tsv` has decided
something the engine's own tiering has not. So grounding is the second
argument and both answers are stated once:

```
             DECLARED   OBSERVED   INFERRED
  low        install    install    hold
  medium     install    hold       hold
  high       refuse     refuse     refuse
```

No cell was derived. high everywhere is invariant 4; low and medium DECLARED
are `stack.sh`'s existing behaviour and §0am's recorded decision; medium
OBSERVED holding is that decision's other half, and amendments §1.2 is why
nothing better is available. INFERRED never installs at any tier.

Found by the routing itself, not by looking for it: the old plan tested
`[ "$risk" = "high" ]`, so **every value that was not that exact word fell
through to install** — an empty tier column, a typo, and `HIGH` in capitals
were all installable unattended. Nothing exploited it and nothing would have
reported it either.

**#160 — the log holds what the reader accepted.** An accepted row went into
`commissioning.log` through a flat `cut -c1-160`, and the first real answer
carried a 238-character sentence, stored cut mid-word at "…has actually ship".
That is worse than clipping: the log is append-only and outlives the answer
file the next topology rewrites, so the reason was lost rather than shortened.
The rule it broke is #156's — the request states every constraint the reader
enforces — and a 160-character ceiling was enforced and stated nowhere. The
three free-text fields are now bounded (source 200, capability 64, why 300),
all three are stated in the request, and the log's own limit is **derived from
them** rather than written down again.

**#161 — the admit phase.** `felix_commission_admit` grounds a nomination so
it can reach the policy at all. Source the plugin, fetch at its pinned sha,
read the three files discovery already reads, tier what was found: that is
what turns INFERRED into OBSERVED. **Both** of the provider's claims are
refused as evidence, not one — the tier is never claimed and always read, and
the capability *is* claimed by the row, so it is matched again against what
the copy on disk actually ships. An `mcp` row is refused on its kind before
anything is fetched (spec §7 T3, the row that would have been activated
unattended); `hook`, `skill` and `subagent` rows are recorded, because Felix
authors none of those. Ungroundable is `unknown`, not `refuse`.

### What running it found that reading it would not have

The protocol had never been exercised on real answers, and §0am said to expect
it to find something. It found four things, and three of them only appeared
when the phase was pointed at the eight actual nominations:

- **The score answer was being admitted.** Its row is `score 69/100 C` — three
  fields, no kind, no name — so the phase read `score` as a kind and went
  looking for a plugin called `69/100`. The shape registry already knew which
  needs carry rows that name something.
- **An installed plugin read `unknown`, "nothing could be read".** An installed
  plugin is absent from the *available* list, because that list is what is left
  to install. The honest verdict is that it is already here. This is exactly
  the case the recommender named: `github`, installed and undeclared, which is
  why no route can reach it.
- **42 of the marketplace's 269 available plugins cannot be fetched at all.**
  Their `source` is a path relative to the marketplace repo with no url and no
  sha of their own; `hookify` is one. The other 227 carry a nested url and sha
  and resolve fine. `unknown` is the correct verdict and it holds — but it
  means the admit phase can never ground a first-party plugin of that
  marketplace, and no amount of retrying changes that. Whether Felix should
  learn to fetch the marketplace repo and read a subdirectory is unanswered
  and was not guessed at.
- **The suite's own structural check caught a bug in new code**: a `local`
  statement that read a variable declared beside it, which made every rules
  lookup miss and turned every verdict into a silent `unknown`. It is the one
  failure mode the phase has that looks exactly like correct caution.

### The ledger was counting only the sessions that exited cleanly (#163)

Not planned, and the largest single correction of the night. The session
banner named `claude-md-management` as *mounted and never once reached for*,
and this session had just invoked it — so the number was checked instead of
believed.

The recording path turned out to be fine end to end: `felix_ledger_signal`
extracts the skill name and `felix_ledger_record` appends it, which ruled out
the first hypothesis. The loss was entirely in the fold. `felix_ledger_rollup`
runs from exactly one place, the `SessionEnd` hook, so a session killed, put
to sleep, or torn down with its process never folded and its appends sat in
`state/ledger/` uncounted. **31 stranded sessions from 2026-08-11 onward
against 12 that had folded**, several carrying thousands of reaches.

So the ledger was reporting whichever sessions happened to exit cleanly, while
calling itself the only unconfounded signal here and recommending capabilities
be retired for a zero that was an artefact of how their sessions ended.

`felix_ledger_catchup` folds every session nothing folded, from `felix ledger`
and from no hook — it is several greps per distinct signal per stranded
session, and that cost belongs to a person asking for a report. It is safe for
the reason the rollup already documented about itself: it rewrites its own file
rather than appending, so folding twice cannot double. On the real memory: 35
folded, 49 sessions to **82**, Bash reaches 16,590 to **31,879**.
`claude-md-management` left the retire list. `semgrep` stayed on it — 82
sessions, named 3, reached 0 — which is what the list is actually for.

### The graph was refreshed, and it holds this session (#164)

`graphify` has a cadence of `0`, so six merges made it due. Refreshed
incrementally rather than rebuilt: 62 changed files, 24 code through AST and 38
documents through two extraction agents. 1363 nodes, 1725 edges, 130
communities, health OK. `graphify-out/` is gitignored so only the cadence
record is in the tree.

One thing to look at later: 11 nodes were dropped to ID collisions where the
same entity was minted once from a relative `source_file` and once from an
absolute one. The extraction spec requires absolute paths and says the engine
relativizes downstream; both forms coexisted anyway. graphify warns and keeps
one, so nothing is silently wrong — but the two conventions are not
reconciling the way the spec describes.

### The other two projects, and what answering them found (#166)

**elenchus, 89/100 B.** Its module map is accurate and was verified symbol by
symbol rather than read, because the file's own §2 forbids inferring a symbol
from a doc — `run_session`, `ASSESSORS`, `STATE_UPDATERS`, `veldra_ingest`, the
`assessment/` trio and the `web/` package all exist where claimed. The gap was
one level up: `content/` holds **fourteen** directories of what invariant 1
calls first-class doctrine, and the file named two of them. A repository map
was added and the `web/` list corrected — it also ships `runtime` and
`__main__`.

The survey returned five rows and **zero hooks**, because Felix already
enforces both hooks worth having: elenchus's `deny.tsv` refuses
`git add -A|.|-f` and force push, and its gate runs `lint`, `secret`,
`confidential` and `ignore-leak`. Recommending them would have been noise.

**And then the admit phase refused one of my own recommendations, which is the
best thing that happened all night.** The survey nominated `logfire` under
observability — a defensible call: elenchus is FastAPI and pydantic, logfire
auto-instruments both, and the declared observability tools are two error
trackers and an LLM tracer that never touch the web layer. The engine sourced
it, fetched it at its pinned sha, read it, and refused it:

```
refuse  plugin  logfire@...  high  interpolates an environment variable,
                                   check what it sends where, talks to a
                                   remote endpoint
```

A model named a plugin and what the engine read on disk overrode the
nomination. That is the entire argument for grounding, demonstrated on a real
recommendation rather than a fixture.

**It also found a defect in the phase built four hours earlier.** The first
run reported `logfire` as `unknown`, "nothing it ships matches a capability
this project declares", because the capability gate ran before the risk gate
and returned first. Both statements were true and the weak one got made: a
capability mismatch is answerable by declaring a capability, and a high tier
is not answerable at all. Risk is asked first now.

**veldra, 87/100 B.** The strongest of the three on non-obvious patterns — a
green checkmark reported over a red D12, a reviewer worktree without `gate.sh`
silently downgrading to a reader three times in one session, `fmt` failing for
any uncommitted `.rs`, and a "proven to fail, not assumed to" probe table that
is invariant 5 discharged with numbers. Every verifiable claim in it checks
out: `scripts/gate.sh` really is a symlink to `projects/veldra/gate.sh`,
`superscan.sh` exists, `gate.sh` honours `FELIX_GATE_ROOT`.

**Nothing was added to veldra's file, deliberately.** The request says to add
architecture. That file's own rule is that it carries only what Felix needs and
the checkout cannot carry, and a crate map is something the checkout can carry
— adding it there would create exactly the second, drifting copy the file
argues against. So it is recorded here instead:

> **Nothing maps veldra's sixteen crates.** Not `projects/veldra/CLAUDE.md`,
> and not the checkout's 166-line `.claude/CLAUDE.md`, which has no
> Architecture section at all. They exist only in `Cargo.toml`. The right home
> is the checkout, which is a different repository, so it was not edited unasked.

veldra's survey returned five rows and **zero plugins**, with a number behind
it: the only Rust-named plugin in the marketplace is `rust-analyzer-lsp`,
already declared, and there is no Docker plugin at all. The rows that matter
are grounded in counts — 21 `unsafe` blocks and 831 `unwrap`/`expect` sites
across 109 Rust files, in a long-running gateway where a panic is an
availability fault.

### The ledger fix was itself wrong, and an audit caught it (#168)

**Read this before trusting anything else in this section.** #163 fixed a real defect —
sessions that end uncleanly never fold, so the ledger was reporting whichever
sessions happened to exit cleanly. The fix was correct in intent and **wrong in
scope**, and it shipped that way for several hours.

`state/ledger/` carries no project namespace, deliberately: the PostToolUse hook
refuses to resolve the project because resolution touches git, and that would put
a git invocation behind every Read, Edit and Bash in every session on this
machine. SessionEnd resolves `PWD` and folds to the right project. The catch-up
had nothing to resolve with, so it folded **every** unfolded session into whichever
project asked.

Measured before anything was changed: ten session ids sat in two projects'
`ledger.d` at once, and `playwright` reached felix's retire list built entirely out
of elenchus sessions — felix's `routes.tsv` and `stack.tsv` have never contained the
word. The CLI was instructing removal of a stack row and a play that do not exist,
under the heading "the one signal here worth acting on".

Attribution needed no new record: the user-prompt hook already writes the governed
repository's HEAD to `state/session/<id>`, and governed repositories have disjoint
histories, so `git cat-file -e` decides it with bash and git alone. A session with
no mark, or a mark this repository does not contain, is not folded.

Data repaired: 15 foreign records removed from `felix/ledger.d` (9 elenchus, 6
veldra), plus three hand-made `probe` fixtures the catch-up had also claimed.
Copies are outside the memory root. felix now reads **65 sessions**, no duplicated
session id across projects, and a retire list of `semgrep` alone. `semgrep`'s named
count fell 3 to 2, because one of the three was an elenchus session.

**And the guarantee written beside the new banner qualifier was unsound**, falsified
the same night it was written. It claimed folding "can only ADD reaches, and a reach
can only take a capability OFF this list". A retire row needs three things — calls
at zero, named above zero, sessions at or above the threshold — and folding raises
the last two as well. The comment now says hedged, not guaranteed.

### The audit that found it, and the twenty-two findings still open

Four independent lenses over the measurement surfaces — identity, zero-versus-absent,
aggregation completeness, and the wording of founder-facing claims — with every
finding then put to three adversarial refuters on distinct angles. 79 agents,
0 errors, **23 findings survived and 2 were killed**. Three separate lenses found the
catch-up regression independently, which is the main reason to believe the rest.

Everything is written up with its evidence, its verifier corrections, and the two
killed findings, at:

    ~/.felix/memory/felix/audits/2026-09-04-measurement-audit.md

The catch-up cluster is fixed. **The remaining high-severity four, none of them
touched:**

1. **`felix next` asserts "every tool a route names is reachable" from fifteen
   answers that say "cannot check"** (`engine/harness/felix:1289`). It drops the
   `unknown` and `undeclared` states and then makes a positive claim over what is
   left. This is the "Nothing due / nothing is being checked" lesson, one surface
   over.
2. **`felix_ledger_signal` can name only three shapes of thing**
   (`engine/harness/lib/ledger.sh:191`) — tool, mcp server, skill. A plugin whose
   contribution is hooks, commands or agents is pinned to zero reaches **by
   construction**, and can therefore never leave the retire list. semgrep may be
   exactly that artefact, which would leave the retire list empty of true positives.
3. **The gate receipt is one bit** (`engine/harness/hooks/stop:285`), so
   `felix gate --quick` — which skips the test suite — is indistinguishable from a
   full run, while the Stop hook says green "means the suite passed". A verification
   claim stronger than its evidence, which is the one kind this project treats as
   serious.
4. **The MCP name never joins to the plugin name.** `felix_ledger_summary` strips
   `@suffix` and `:suffix` but not the `plugin_<plugin>_<server>` tool prefix, so
   routes naming `playwright` and reaches recorded as `plugin_playwright_playwright`
   are two different capabilities. Measured: **773 reaches across the three projects**
   attributed to a name no table contains. The fix is one `sub()` in that awk —
   diagnosed, designed, deliberately not applied, because the session was already
   three changes deep into the ledger and a fourth unreviewed one is how tonight's
   regression happened in the first place.

Eleven medium and low findings follow in the same file — the monitor rendering a
tail window as a lifetime total, the reconciler proposing mounts for things that
cannot be mounted, `felix_maint_unreachable` called by nothing but the suite, and
others.

**The method note worth keeping.** Every one of tonight's five real defects was found
by running something and comparing it against its source, never by reading. The
audit was pointed at a surface that had just been changed twice, and it found that
the second change was wrong.

### Decided — the manifest row carries who grounded it

The founder's direction, 2026-09-05: *avoid person-written notes as much as
possible, to avoid inconsistency.* Read as: the engine writes `stack.tsv`
rows itself, and a row it wrote must read back as what it is. That is option
2 from the earlier draft of this section, and it rules out option 3.

`stack.tsv` has a sixth column, `grounding`. A catalogue row — seeded by
`felix new` or backfilled by `felix adopt` — is `DECLARED`: the catalogue's
tiers are a person's judgment, and the engine writing them down does not
make them the engine's. A row `discover --adopt` or the admit phase writes
after reading a plugin is `OBSERVED`. A row with no sixth column is a person's,
`DECLARED`, which is what every row was before the column existed, so nothing
already in any manifest changes meaning. `felix_stack_plan` and `ready --fix`
read the column and hand it to `felix_admit`; an `OBSERVED` medium now waits
for a person where a `DECLARED` one installs, which is the whole reason the
column exists and the whole reason the admit phase could not write until it
did.

**And the admit phase writes.** A `declare` becomes a row carrying `OBSERVED`
and a `commissioning.log` line carrying the sha the copy was read at. It runs
before the receipt so the receipt's hashes cover the rows it writes; nothing
installs in that run, and `stack apply --yes` installs what the policy allows
on the next. On this machine no nomination has yet reached `declare` — the two
plugin rows on felix are `already` and `unknown`, elenchus's is `refuse` — so
the path is exercised by the suite and by nothing real yet. Expect the first
real declare to find something.

### Standing

- `tests/run --record-assertions` after any assertion change; **1450** on record.
- Engine work happens in the **home checkout**, never a worktree. This session
  started in one, and moving was the founder's first instruction. The session's
  own cwd could not be moved — the harness pins it — so every command was run
  from `/Users/a14808/Documents/Felix` explicitly. `lessons.md` already carried
  the structural reason; `projects/felix/CLAUDE.md` now carries it too.
- `felix merge` needs a gate receipt for the **committed** tree. Running the
  gate before committing and then merging refuses, and the refusal reads as a
  missing test rather than a stale receipt.

