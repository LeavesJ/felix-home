<!-- Design, 2026-09-16, drafted by a read-only research agent from v3.2, its amendments and the engine at 36b0afc; reviewed and landed by the session that built #243, #245 and #247. Not yet built: HANDOFF §0bf item 1. -->

# Obligation discovery, first increment: a baseline pass that proposes and admits nothing

Design only. No tracked file was edited and no writing command was run. Engine
read at main `36b0afc`, plugin 0.49.116. Spec = `felix_v32_architecture_spec.md`
(line numbers as read); Amend = `felix_v32_conformance_amendments.md`.

## 1. What the increment is and is not

**Is.** One provider request for one product (elenchus) asking a session's model
to propose candidate obligations grounded on the product's declared probes; an
engine reader that validates the answer offline and appends accepted rows, with
provenance and the epoch they were proposed under, to
`~/.felix/memory/elenchus/candidates.tsv` (the memory root, Amend §1.3:77-80,
`resolve.sh:252-255`); and a `felix obligations` section that shows them. Every
row is lifecycle CANDIDATE (Spec §3:140). Nothing reaches `obligations.tsv`, so
nothing moves applicability, discharge, the gate (`felix:602-612`) or the merge
boundary (`escape.sh:424-460`).

**Is not**, each deferred with its section:

- No schedule. Amend §1.3:91-92 says the founder grants one; until then a person
  runs `felix commission`, or a session runs `felix obligations --request`.
- No budget classes beyond B0 (Spec §10:381): one pass, no situation triggers,
  no independent second angle (B2, §10:383), no constructed witness (B3, §10:384).
- No stop rule (§10:389-394): with one pass there is nothing to stop.
- No admission kernel classification (§1:60, §4:188-192). Every candidate is
  pathway 4, "single probabilistic discovery: advisory only" (§4:191).
- No risk envelope (§4:196-206). Elenchus's `project.json` declares no
  `maturity`, so its `envelope` commissioning row is held; severity cannot be
  weighed and is not.
- No corroboration (§4:190), no dispute protocol (§6), no open-world pass
  (§9:361), no other product, no template row for every project.

## 2. The mechanism, step by step

**Which command.** A commissioning row, not `felix discover --obligations`.
`felix discover` dies without the `claude` CLI (`felix:2132`), reads
marketplaces, and its cache, rules and adopt path are about plugins; obligation
discovery shares none of that. The provider protocol is the only legal
model-calling surface (constitution invariant 2; `commission-provider.sh:1-11`)
and already supplies the request writer (`:98-113`), the topology-keyed answer
state awaiting/stale/partial/answered (`:117-135`), shape refusal (`:162-202`),
provenance from the plugin registry (`:214-225`), idempotent INFERRED recording
(`:232-254`, hash guard `:240`), and the session-start reminder that repeats
until an answer exists (`session-start:452-462, 475-482`). Spec §8 step 4,
"compile baseline engineering coverage from content providers", is the row's
step; the two existing provider rows already carry it (`commissioning.tsv:51-52`).
The constitution says ask which table answers before adding a library.

Row, in `projects/elenchus/commissioning.tsv` only:

    obligations_surveyed	-	-	-	provider:felix:obligations	-	4

The plugin named is `felix`, because the request template is the worker's
prompt and the template's engine version is the worker's identity;
`felix_commission_provider_provenance felix` reads `felix@0.49.116/36b0afc…`
from the registry (`:214-225`). The model's identity is not recorded: its own
report of it would be MODEL_CLAIM (Spec §11:432).

**Two writers of the request, one function.** `felix commission` writes every
provider request on a real run (`commission.sh:319-327`), and that command is
the founder's (HANDOFF §0bc). A pass that must be re-run when the epoch moves
needs a writer Felix may run: `felix obligations --request` calls the same
`felix_commission_request` for this one need, writes one file under the memory
root, touches no table, and is therefore reversible (invariant 3). It refuses
when `felix_epoch` returns nothing (`epoch.sh:160-165`): a proposal about a
topology the probes could not read grounds on nothing, and unknown holds (Amend
§1.3:82-86). `felix_commission_request` gains one placeholder, `{{EPOCH}}`,
beside `{{TOPOLOGY}}` (`:107-111`).

**The request file**, rendered from
`engine/harness/templates/commission/obligations_surveyed.md` to
`~/.felix/memory/elenchus/commission/requests/obligations_surveyed.md`:

1. The product: `{{PROJECT}}`, `{{ROOT}}`, and `{{PROJ_DIR}}/CLAUDE.md` to read.
2. The grounded facts: every `probes.tsv` row as predicate, state, count and
   probe command (`felix_probes_run`, `probes.sh:362-378`), with leave to run
   those commands read-only for members. Relations ground topology and
   discovery reasons over it (§2:113-115): a candidate may ground only on a
   predicate listed.
3. The admitted rows of `obligations.tsv`, not to be re-proposed (§9:361).
4. The answer shape, the ceilings, and that admission is a person moving a row.

No new skill. The request is self-contained, as the two existing ones are
(`templates/commission/automation_surveyed.md`), and `engine/commands/felix.md:27-31`
already tells a session to answer awaiting requests. The session runs it as one
subagent, free to use any installed methodology skill (§9:346-350); the output
is constrained, not the reasoning.

**The answer file**, `~/.felix/memory/elenchus/commission/obligations_surveyed.tsv`:

    # topology {{TOPOLOGY}}
    # epoch {{EPOCH}}
    <obligation>	<class>	<applies>	<evidence>	<grounds>	<failure_mode>	<reason>
    done	<n>

Seven fields, aligned with `obligations.tsv` (`obligations.sh:22-23`) so that
admission is a copy. `class` is INFO or ADVISORY; `applies` a command or `-`;
`evidence` a command, never `-`; `grounds` comma-separated probe predicates;
`failure_mode` a token in the spec's idiom (§4:169); `reason` one sentence,
≤300 characters (the log ceiling, `:57-64`). There is no pathway column: the
engine stamps `probabilistic`, because a column the model writes is a claim.

**Ingestion**, in a new `lib/candidates.sh`, run by `felix obligations` on every
read, offline, idempotent per answer-file hash (the pattern of `:232-254`):

- The generic reader first: `_felix_commission_provider_shape` gains the case
  `obligations_surveyed) 7` (`:143-145`) and the classifier index 2 (`:154-156`),
  so `felix commission --status` and the hook's record phase read the file
  rather than refusing every row as "7 fields where the shape has 5".
- Then the candidate rules, each a printed refusal, never a silent skip:
  line 2 is `# epoch <40 hex>`; name matches `^[a-z][a-z0-9_]*$` and is not in
  `felix_obligation_names` (else `already`, as `:356-358`); class in
  {INFO, ADVISORY}; evidence non-empty and not `-` (`obligations.sh:63-64`);
  every ground names a predicate in `felix_probe_rows` (`probes.sh:109-115`),
  and `-` is refused although the ledger only counts it (`obligations.sh:179-185`),
  because an ungrounded model proposal is the fabrication §2:103 forbids; a tab
  inside a command fails the field count (`probes.sh:104-108`).
- No candidate column is ever passed to `bash -c`. The provider rows' ban on
  `;`, `|`, `&` (`:175`) is not applied to `applies` and `evidence`, or no
  evidence could be proposed; the suite asserts the non-execution instead.
- Accepted rows are appended to `candidates.tsv` as
  `stamp tree epoch proposed_by answer@hash obligation class probabilistic applies evidence grounds failure_mode reason`,
  provenance first like `facts.log` (`facts.sh:92-94`), append-only, counted
  after the write (`facts.sh:99-104`).

## 3. How a candidate becomes admitted

By a person copying the row into `projects/elenchus/obligations.tsv`, changing
the pathway from `probabilistic` to what they can defend, and committing. That
commit is the supersession event (Amend §1.1:52-55) and moves the
`policy_version`, so it opens a new epoch (`epoch.sh:36-39`).

The engine may not do it. Invariant 2 says a model's output is a proposal and
never a verdict, and may only narrow; Spec §12:445 reserves the obligation
ledger to admission, applicability and policy paths, and §1:59 says discovery
workers cannot write blocking state. An engine path that appended to the ledger
on a model's word would be the widening #28 exists to detect and #5 decided is
never earnable. The existing `--seed` already refuses to touch a ledger that
exists (`felix:4334-4338`). Amend §3:184-186 asks for three counts so that
"never admitting" is visible; this increment supplies the first two.

`felix obligations` prints, after the ledger, a `candidates` section: N proposed
(current under this epoch / stale), one line per row with name, class, grounds
and its epoch's status, then refused rows with reasons, then a footer line
"discovered N, admitted M". Report only, never in `--gate` output (`felix:4398-4404`
gives the reason: the gate's copy is parsed). The north-star row is seen because
every row is; nothing in the engine names it (invariant 1).

## 4. The north-star walk

Elenchus facts as last recorded (`facts.log`, 2026-09-04, tree `a042f38`):
`http_route` found 16, `ceiling_site` found 3, `entrypoint` found 2. The probes
table itself records why: two serving processes, one of which for a while did
not arm the ceiling (`projects/elenchus/probes.tsv:22-28`). The expected
candidate:

    route_behind_ceiling	ADVISORY	-	<check every http_route member is served only by an entrypoint that arms ELENCHUS_MAX_CALLS; print a verdict per route>	http_route,ceiling_site	uncontrolled_cost_or_service_abuse	a route reachable by a stranger with a link is unbounded unless the process serving it arms the ceiling

Spec §15:507 has three steps. **Step one now passes**: an obligation nobody
named exists in a store the engine reads and shows, with the epoch it was
proposed under. **Step two still breaks**: ADVISORY cannot block
(`obligations.sh:153-162`), and cannot be made to by the engine. It blocks only
after a person admits it with a pathway that may carry RELEASE_BLOCKING and an
evidence command that has passed the six controls (Amend §2.1). **Step three is
not reachable by a candidate**: dormancy is derived from `applies` on an admitted
row (`obligations.sh:94-106`) and never stored (Amend §1.4). A candidate whose
epoch has moved is reported stale, which is a prompt to re-run the pass, not a
waiver. Elenchus is not checked out on this machine (HANDOFF §0bd), so this walk
is reasoned from its tables and log, not run.

## 5. What must be shown failing first

Invariant 5. Assertions in the suite's `is`/`has` idiom (`tests/run:38-41`),
authored from this prose before the reader exists:

- A malformed answer is refused row by row: six fields, eight fields, a capital
  in the name, a `-` evidence; each prints its reason, `candidates.tsv` gains
  nothing.
- A candidate grounded on `paid_model_path`, which `probes.tsv` does not
  declare, is refused; one grounded on `http_route,ceiling_site` is accepted.
- A `RELEASE_BLOCKING` candidate is refused, not downgraded: a downgrade turns
  an overclaim into an accepted row and hides it; refusal keeps it visible, as
  `obligations.sh:69-70` and the template's "refused, not shortened" do.
- A row accepted under epoch E0 reads `stale` from `felix obligations` after a
  probe count moves; a row whose `# epoch` differs from the request's is still
  ingested, the mismatch being provenance, and reads stale at once.
- `obligations.tsv` is byte-identical before and after `felix obligations`,
  `--request` and `felix commission` over an answered file; no candidate column
  reaches `bash -c`.
- The request's `Epoch` line changes after a probe count moves and `--request`
  runs; `--request` writes nothing when `felix epoch` reports `-`.
- An answer whose `done` count disagrees with its rows is `partial` and ingests
  nothing (`:127-133`, re-asserted for this need).

The reader is not an enforcing verifier (it blocks nothing), so it needs no
`qualification.tsv` controls; the evidence command a person later admits does.

## 6. Founder decisions this needs

Felix's: the row, the template, the reader, the columns, refusal over
downgrade, report-only in the gate, ingestion in the reader rather than the hook.

The founder's, per HANDOFF §0be item 2 and Amend §1.3:91-92:

1. **Schedule.** Per epoch, per commissioning, or on a grant in
   `projects/elenchus/autonomy`. Elenchus's `test_file` probe counts tracked
   tests, so nearly every test-adding commit is a new epoch; per-epoch means a
   model run per such commit.
2. **Spend.** Each request is one subagent session over the product's tree, one
   that may run five probe commands including a FastAPI import. No ceiling is
   proposed because no budget class above B0 is built.
3. **Product.** Elenchus, argued for: the north-star surface (`ceiling_site`,
   `http_route`), five witnessed probes, the case §0bc records. Against: it is
   not on this machine, so the first real run is his or on a checkout he
   provides. Veldra is the alternative.
4. **Maturity.** Whether to declare `maturity` in elenchus's `project.json`,
   on which the envelope row is held; without it no later increment can weigh
   severity, and the spec says that fact is his to state (§4:196-206).

## 7. Files touched, with tiers from `projects/felix/risk.tsv`

| file | change | tier |
|---|---|---|
| `engine/harness/lib/candidates.sh` | new: rules, record, read, stale | red (`risk.tsv:34`) |
| `engine/harness/lib/commission-provider.sh` | shape case 7, classifier 2, `{{EPOCH}}` | red (`:34`) |
| `engine/harness/felix` | `cmd_obligations --request`, candidates section | yellow (`:36`) |
| `engine/harness/templates/commission/obligations_surveyed.md` | new request template | yellow (`:37`) |
| `projects/elenchus/commissioning.tsv` | one provider row | yellow, verifier confine (`:43`) |
| `engine/harness/tests/run`, `tests/assertions.tsv` | the assertions above | yellow, verifier confine (`:39`) |
| `engine/.claude-plugin/plugin.json` | version bump riding in the PR (§0bc) | red (`:35`) |
| `HANDOFF.md` | session-close section | yellow by default (#5) |

Not touched: `hooks/session-start` (its provider loop is generic and already
records this need), `obligations.tsv` anywhere, `escape.sh`, the gate.
