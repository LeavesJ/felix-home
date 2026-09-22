## 0bg. Verified at session close, 2026-09-16 (late) — an obligation nobody named can exist now, and nothing admits it but a person

| | |
|---|---|
| merged | **#249** (the design, green) and **#250** (the build, red tier), on green CI; `felix merge` refused #250 on the stale commission receipt alone |
| deployed | **0.49.117**, carried in the pull request; the home's `felix install` deployed it byte-identical and wrote no bump |
| suite | **2358 passed, 0 failed**; 102 assertions added, blind, of which 72 fail against the previous engine |
| this session, in all | four engine changes (#243 #245 #247 #250), one design (#249), four handoff sections; every engine change blind-tested, shown red, merged and deployed the same hour |

**§0bf item 1, built.** v3.2 §3 gives an obligation a lifecycle — CANDIDATE,
ADMITTED, REJECTED, SUPERSEDED — and the engine had one state of it: a row in
`obligations.tsv` is admitted, and nothing anywhere proposed a row. That is
why the north-star eval broke at its first step. `felix obligations --request`
now writes a provider request under the memory root — the decision epoch,
every probe with its state and count, the admitted ledger, and a seven-field
answer shape — for a session's model to answer, through the commissioning
provider protocol, which is the only surface on which a model may answer the
engine (invariant 2). `lib/candidates.sh` reads the answer back offline:
each row is accepted or refused with its own reason — field count, name,
already admitted, a blocking class, no evidence, a ground that is not a
declared probe, a reason over 300 characters — and accepted rows land in
`candidates.tsv` with a stamp, the tree id, the epoch the answer named, the
engine's registry provenance, the answer file at its hash, and the pathway
`probabilistic` stamped by the engine, never read from the model. `felix
obligations` ingests on every read and prints them, current or stale by
epoch, with "discovered N, admitted M". Never under `--gate`.

**Refused, not downgraded, and nothing admitted by the engine.** A
RELEASE_BLOCKING candidate is refused rather than quietly made ADVISORY,
because a downgrade hides an overclaim inside an accepted row; a single model
finding is advisory only (§4), and a person admits it with the class they can
defend, by copying the row into `obligations.tsv` and committing — the
supersession event that opens a new epoch. Nothing here writes that file and
nothing runs a candidate's `applies` or `evidence`; the blind assertions
plant marker commands in both and check that no marker fires. The design is
in `docs/2026-09-16-discovery-baseline-design.md`, drafted by a read-only
research agent from the spec, the amendments and the engine, and reviewed
before it was landed.

**The north-star walk, after this.** Step one — an obligation nobody named
exists in a store the engine reads and shows, with the epoch it was proposed
under — passes. Step two still breaks: a candidate cannot block, and cannot
be made to by the engine; it blocks only after a person admits it with a
blocking class on an evidence command that has passed the six controls.
Step three is reachable only after admission, since dormancy is derived from
`applies` on an admitted row. Reasoned on elenchus from its tables and fact
log; elenchus is not checked out on this machine, so the first real run is a
session in its checkout answering the request `felix commission` or `felix
obligations --request` writes.

**The blind assertions found the library's one defect on their first run.**
A guard at the top of `candidates.sh` sourced `commission.sh` for a function
that lives in `commission-provider.sh`, so every path the reader computed
came back empty and 55 assertions failed at once; the same session's own
hand demonstration had passed because the CLI sources everything. The lesson
is the standing one, a reader that has never been given real input is not
known to work, and the fix was one guard.

**Three placeholders, spliced by index.** Probe commands carry backslashes
and `&`, and neither `awk -v` nor a `gsub` replacement survives those intact
— `&` in a replacement is the matched text — so the request writer passes the
epoch, the probe listing and the admitted ledger through the environment and
splices them with `index`/`substr`. Worth knowing before the next template
placeholder is added with `gsub`.

**Founder's decisions, unchanged from the design's §6.** The schedule (per
epoch, per commissioning, or on a grant), the spend per run, whether elenchus
or veldra is the first product, and whether to declare elenchus's `maturity`
in its `project.json`, on which its envelope row is held. Nothing in #250
decides any of them.

**Next, in order.** (1) The first real run: a session in a product's
checkout answers `obligations_surveyed`, and `felix obligations` shows the
candidates — the founder's, because the product and the spend are his.
(2) CI enforcement of `felix merge`'s blockers, which needs GitHub Pro or an
accepted advisory CI. (3) Grants for high-risk plugins whose hooks run in
every session with no record. (4) Issue #2 stays open for spec step 5.
Standing: `projects/bazaar` and `projects/webapp` stay untracked, and
commission is stale until the founder runs it — which he can now do knowing
that on elenchus it will also write the discovery request.

