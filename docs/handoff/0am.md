## 0am. Verified at session close, 2026-09-04 — the first-encounter moment is a table, the two setup skills are rows in it, and the rows are waiting for a session

| | |
|---|---|
| head | `b07b294` on `main` (#146–#157, twelve merges), CI `gate` **success** on each |
| suite | **1395** passed, 0 failed, manifest re-recorded |
| deployed engine | **0.49.49**, deployed from the home the moment this landed; every session from here boots with it, the one that built it did not |
| governed projects | felix, elenchus, veldra each carry `commissioning.tsv` and were commissioned by hand through the deployed cli; receipts under `state/commission/`, all `held` |
| waiting on a session | six provider requests, two per project, none answered; the banner names them every session until they are (#155) |

### Start here, if you are the next session

Felix can now decide a repository's toolbox on first encounter, and there is
exactly one thing built for you that no session has yet done.

1. **Answer the two provider requests.** On each of the three governed
   checkouts — `felix commission` resolves the project from the directory it
   runs in, and two of them are not where a guess would put them:

   ```
   /Users/a14808/Documents/Felix        felix
   /Users/a14808/Documents/Elenchus     elenchus
   /Users/a14808/ReserveGrid-OS         veldra
   ```

   `felix commission --status` ends with two rows reading `awaiting`, each
   naming a request file:

   ```
   ~/.felix/memory/<project>/commission/requests/constitution_audited.md
   ~/.felix/memory/<project>/commission/requests/automation_surveyed.md
   ```

   Read one to the end. It names a skill to run, the exact shape to write —
   a byte-exact topology header, tab-separated rows, a terminal `done <count>`,
   and every constraint the reader enforces — and the **answer file to write,
   which is a different file** in the parent directory:
   `~/.felix/memory/<project>/commission/<need>.tsv`. An answer written beside
   the request is never read. Run the skill, write the file, then
   `felix commission`.

   Two things about that last command. **`--status` and the full run count
   differently**: `--status` runs no engine stage, so the four `felix:` rows
   (discover, stack, preflight, reach) read `held` there whenever their check
   does not pass on its own, while a full run executes each stage and then
   re-checks — 7 done / 4 held in `--status` and 8 done / 3 held after a run
   is the same project, not a drift. And **the full run is not read-only**: it
   runs `discover --adopt`, `stack apply --yes`, `ready --fix` and
   `toolbox --route`, which install low and declared-medium rows, adopt low
   discoveries, and rewrite `routes.tsv` and `stack.tsv` in the home — commit
   what it writes, as #150 did — and it re-renders every request with the
   current topology, which is also how a request goes stale-proof after
   `commissioning.tsv` or the detected surfaces change.

   The row moves from awaiting to answered, accepted rows land in
   `commissioning.log` as INFERRED with the file's hash and the provider's
   version and commit, and the report lists what the provider named and
   what it refused, row by row — the only surface that does. **Nothing it
   names is installed**: the admit phase is PR 3 and is not built. This
   protocol has never been exercised on real answers — expect it to find
   something, and write down what it finds.

2. **Do not re-derive the architecture.** Two files govern, and only two:
   `felix_v32_architecture_spec.md` and `felix_v32_conformance_amendments.md`
   under `~/Documents/UC Berkeley/Career/Founder OS/`. The addendum PDF and the
   authority-kernel PDF beside them are earlier drafts and bind nothing.
   Nothing loads them for you. The question is closed; work conformance.

3. **Then PR 3**, from "Not done, in order" below — **but read the standing
   rule first.** §0ak's "no engine work before 2026-09-06" (beta opens the 5th,
   soak reads out the 6th) was overridden for the sessions of 09-03/04 by the
   founder's live instruction, not repealed. If you are reading this on the 5th
   or 6th, PR 3 is engine work and waits for the founder to say so; the
   provider requests are not, and step 1 stands.

After a full run, three rows are `held` on every project and each is the
founder's, not yours: the `maturity` key in `project.json`,
`felix bootstrap --yes`, and one outstanding `setup.tsv` step. Do not answer
them on their behalf. In `--status` a fourth may show held for the phase
reason above; that one is the engine's, and a run clears it.

### Read this first: what the founder asked, and what was built to it

The instruction, verbatim: *"felix will and should have the ability to decide
what are the tools needed upon first encountering a repo/codebase, and that
'skill' and the 'setup' we can use the preexisting claude md setup as backbone
then build on top of it."* Then, later: *"gracefully pause"*, and *"continue"*.

v3.2 already names this work. §8 is a ten-step commissioning pipeline; §7 is
the capability manager; §9 the baseline coverage compiler; and line 330 says
setup skills are *commissioning instruments, not Felix's constitution*. So the
claude-md-management skill is an instance of a class the architecture already
has, and the standing method rule (§0aj, "build the class, not the instance")
decided the shape before any design did: a moment, a table of what must be
answered at it, and a selector — with rows that can be missing and be said to
be missing.

### What the map showed before anything was designed

Six readers over the engine, the tables, the hooks, the handoff, the lessons
and the machine (`understand_map.json` in the session scratchpad). Every stage
of §8 already existed as a separate, person-invoked command: `felix new`
(detects 13 capabilities, seeds from a 15-row catalogue), `discover
--inspect/--adopt` (fetch at a pinned sha, read never execute, tier by shape),
`stack apply --yes` and `ready --fix` (install low and medium), `toolbox
--route`, `bootstrap`, and a session-start hook that auto-adopts. Four things
were missing: a moment that chains them (`felix new` *printed* the sequence,
which invariant 3 calls a defect); any way to ingest the two setup providers
(both were paste-into-session prompts, and by invariant 2 can never be engine
calls); a record of the toolbox decision itself; and one install policy
(`--adopt` refuses medium, `stack apply --yes` installs it).

### The design, judged before it was built

Three designs from three angles (compose, provider-protocol-first,
admission-first), each judged by three refuters, then synthesised: 13 agents.
"Compose" won on reuse and testability; the panel's 26 fatals were resolved
or rejected one by one. The ones worth knowing: a provider-written `mcp` row
would have executed unattended (spec §7 T3) — never fetched, tiered or
installed now; an INFERRED capability would have been consumed as DECLARED —
grounding is required; two seed checks passed vacuously against the real CLI
output — rewritten against the libraries' own TSV; the Stop hook was wired
after all, through the gate receipt — so the gate line is announce-only; and
`felix new` would have run `bootstrap --yes` into a stranger's tree — the
baseline row is a person's.

### What landed (#146)

`projects/<p>/commissioning.tsv`: `need grounds instrument when answer check
step`. A row names a need, the capability it serves, the **instrument** the
question needs on this machine, a `when`, the engine stage that answers it
(`felix:discover --adopt`, `felix:stack apply --yes`, `felix:ready --fix`,
`felix:toolbox --route`, `provider:<plugin>:<skill>`, or `-` for a person),
an independent check, and the §8 step. `lib/commission.sh` computes five
states on every run and stores none: done, held, not-applicable, unknown,
malformed; provider rows are `awaiting`, a class that holds nothing. Unknown
is reachable by construction — an absent instrument, a `when` or check whose
command does not exist, an engine function a check names that this process
has not loaded, an unenterable checkout — and blocks the receipt.
`commissioning.log` is append-only with provenance; the
`project_commissioned` receipt (§8 step 10) carries the table-set hash and the
detected-surface hash, and its validity is derived on every read, never
stored. `felix commission [--status]` runs it; `felix new` runs it instead of
printing next steps and asks maturity on a TTY; the gate has an announce-only
`commission` line that fails only on an empty or malformed table; the merge
boundary refuses an absent table, a malformed row, a missing or stale or
indeterminate receipt, and never a held row. `templates/commission/steps.tsv`
enumerates the ten §8 steps so the report names the step nothing answers —
today, 8. Two setup providers are rows: `constitution_audited`
(claude-md-improver) and `automation_surveyed` (claude-automation-recommender),
awaiting until a session answers them; the request-file protocol that ingests
those answers (amendments §1.3 shape) is PR 2.

Found while building, by running rather than reading: a state line captured
inside `IFS=$'\t' read … <<EOF $(…)` inherits the tab IFS, so the function
guard saw four names as one and the report cut the message at the first line;
and a check naming no engine function made `grep -o` exit 1, which under
pipefail read as "function '' is missing". Both fixed and both asserted.

### The first live run, and what it found (#147)

Commissioned once by hand on this machine, through the deployed cli, all
three projects: felix 7 done / 4 held, elenchus 7 / 4, veldra 8 / 3 on the
first run, every receipt `held` and none indeterminate. The held rows are the person's:
maturity, the bootstrap baseline, a human step. Three findings, all engine
defects, all fixed the same night:

- **A keyword is a word.** On elenchus, `discover --adopt` declared and
  installed `google-cloud-storage` under **llm**, because the llm rule's
  keyword `rag` is a substring of *sto-rag-e* and a name hit scores 3, which
  is the adoption threshold. The matcher now tokenises on everything that is
  not a letter or digit and matches whole words; `eval` no longer matches
  `evaluation` either, and two suite expectations that had encoded that
  double count were corrected. The plugin was uninstalled and its row
  dropped. `datadog` under observability was a correct adoption and stays,
  wired into elenchus's incident route by `toolbox --route`.
- **A bundled plugin is present.** `anthropic-skills` is `@inline`, appears
  in no `claude plugin list`, and the stack inventory read it as absent —
  so `stack apply --yes` tried to install it on every run, the cli said
  "not found in any configured marketplace", and felix and elenchus held on
  a plugin that is live in every session. The stack inventory now reads the
  same `@inline` keys ready.sh already did.
- **The cache carries the provenance of its verdicts** (#148). The second
  run, on the engine that had just learned that a keyword is a word, adopted
  the storage plugin under llm *again*: `discover --adopt` reads
  `state/discover/<p>.tsv`, written on 2026-08-29 by the old matcher, and a
  row there was a verdict with no record of which rules or matcher produced
  it. The cache's first line is now a stamp over the rules table and the
  engine version; every reader treats a cache without the current stamp as
  absent, and the command refills it before adopting. This is v3.2's
  `depends_on` rule applied to Felix's own derived state, found the only way
  it could have been: by a fix that changed nothing the adopt path read.

After the fixes, all three read 8 done / 3 held / 0 unknown, the held rows
being maturity, the bootstrap baseline and a human step — a person's, each.

The third run, under the word matcher and the stamped cache, adopted two more
plugins for elenchus — `sentry-cli` under observability and
`42crunch-api-security-testing` under its declared `security` capability,
both low, both matched on a whole word of their names — and wired
`sentry-cli` into the incident route. Those rows are committed with this
section. Every `felix commission` re-runs `discover --adopt`, so the toolbox
grows as the marketplaces do; what it may install is bounded by the tiers,
and what it did is in `commissioning.log` and `stack.tsv`, not in a session.

### What the seven governed answers say about felix, measured

`felix commission --status` on felix, on the first run of the night and
before the three fixes below: 6 done, 5 held, 2 awaiting, 0 unknown. Held
then: the maturity key (nobody has written one), the discovery cache, stack
rows not yet installed, the bootstrap baseline, and one human step. After
the fixes and a full run it is 8 done, 3 held; see the start-here block for
why `--status` reads 7 and 4. Surfaces
nothing serves, reaches or grounds: `ci` and `tests` — no catalogue row, no
profile — which is what the printed next-steps used to drop.

### Decisions that are the founder's, defaults taken

- An engine-tiered medium plugin (ships an MCP server, read from three files,
  never sandboxed) is **not** installed unattended; it waits as a person's
  step. Person-declared medium rows keep installing as today.
- `felix new` writes only the marker into the product repository; labels,
  branch protection and the baseline workflow stay `felix bootstrap --yes`.
- No autonomy `commission` grant exists yet (PR 4); Felix grants itself
  nothing.
- No record of ungoverned repositories the hook passes through.

### PR 2 landed the same night (#151, deployed as 0.49.46)

The provider protocol, in the amendments' §1.3 shape. `felix commission` now
writes a request for each provider row under the project's memory root at
`commission/requests/<need>.md`, keyed to a topology hash over the detected
and declared surfaces and the table — inputs ingestion never writes. A session
reads the request, runs the skill it names, and writes the answer file it
names; the engine reads that file with no model and no network and calls it
`stale` (another topology), `partial` (no terminal `done` row, or a count that
disagrees) or `answered`. Rows are accepted by shape and kind, a risk column
is refused because risk is not the model's to assign, and every accepted row
goes to `commissioning.log` as INFERRED with the file's hash and the provider
plugin's version and commit, once per file hash. An answered row holds nothing
and installs nothing — asserted: the receipt, the gate line and the merge
boundary are byte-identical before and after an answer appears. The
session-start hook runs the record phase offline every session and names
what a session still owes — every session, until an answer file exists,
since #155; the first version spoke once per topology, and a fresh session
was then told nothing, which was the last finding of the night. The `/felix`
command tells the session what to run and what to write.

**And one incident, owned.** PR 2's version bump was written as
`open(p, "w").write(open(p).read()…)`, which truncates before it reads, so
the engine manifest landed on main empty. `felix install` deployed under a
commit-sha directory, reported the cache as matching the tree (it did), and
Claude Code reported the plugin as *failed to load* — every session started
on this machine between that deploy and the fix booted without the floor.
Neither the gate nor the suite had ever asked whether the manifest parses.
Restored as #152 at 0.49.46, with the four assertions the deploy loop had been
missing since `felix install` was written.

**What this means for you, now.** On each governed project the two requests
exist. The next session that runs `/felix` on felix, Elenchus or veldra will
be told to run the two skills and write two files; after that,
`felix commission` moves the rows to answered and lists what the recommender
named. Nothing it names is installed until PR 3.

### Not done, in order

1. PR 3: `felix_admit(tier, provenance)`, one install policy for every caller,
   and the admit phase for grounded provider nominations.
2. PR 4: the autonomy grant and the background resume.
3. The Elenchus model step is the founder's: graphify has a `claude-cli`
   backend billed to the plan, and headless `claude` here reports "OAuth
   session expired", so it is `claude login` in a terminal, then
   `graphify label <path> --backend=claude-cli`. Every community already
   carries a heuristic name; only the semantic relabel and the docs pass wait.

### Standing

- §0ak's "Next, in order" item 3 said no engine work before 2026-09-06; the
  founder's instructions on the 3rd and 4th overrode it, deliberately, for
  those sessions. Whether it binds the 5th and 6th is stated in the start-here
  block above: it does, for engine work, until the founder says otherwise.
- `tests/run --record-assertions` after any assertion change; **1395** on record.
- A waiter that names the process it waits for never exits (`pgrep -f` self-match);
  eight background shells sat thirteen hours on it. Wait on a PID, a done-file,
  or an exit status, with a ceiling. In `lessons.md`.

