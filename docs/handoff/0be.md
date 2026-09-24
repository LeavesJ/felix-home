## 0be. Verified at session close, 2026-09-16 (later) — the receipt carries the epoch, and a fact that moves outside the tree stales it

| | |
|---|---|
| merged | **#245**, red tier, on green CI; `felix merge` refused it on the stale commission receipt alone |
| deployed | **0.49.115**, carried in the pull request; the home's `felix install` deployed it byte-identical and wrote no bump |
| suite | **2223 passed, 0 failed**; 63 assertions added, blind, of which 38 fail against the previous engine |
| commission | still **stale** since #241; re-running it is the founder's, and until then every pull request merges through `gh` on green rather than through `felix merge` |

**§0bc item 2, done.** A gate receipt was keyed on the tree id alone, so an
ignored file a probe counts, a `$HOME`-dependent probe — the deployed engine,
the marketplace registration — or a table in the Felix home for a governed
product could all move while an old green rode on. v3.2 §5 binds a receipt to
what its verdict rests on; #227 computed the decision epoch and changed no
verdict. The gate now records the epoch and its four component hashes as
receipt fields 7 and 8, and one reader, `felix_verify_current`, answers
"current, red, none, or stale and why" for the five places that used to
compare two fields by hand: the merge boundary, the Stop hook, `felix pr`'s
draft decision, `felix receipt`, and `felix next`. Stale is named — the
grounded facts moved, the table set moved, the subject or the release target
moved, the receipt predates the epoch or carries none — because "run felix
gate" on a tree that did not change reads as the hook being broken.

**The blind author overruled two softenings, and was right both times.** The
first draft let a six-field receipt from the old engine stay current until the
next gate run, and let a writer called without the epoch arguments leave a
receipt with none; both were argued as "one gate run per checkout on deploy
day". The assertions, written from the contract in prose with the
implementation forbidden, refused both as the old engine's receipts riding on.
The design followed the assertions: a six-field receipt is stale, and
`felix_verify_record` computes the epoch from the checkout's own binding when
a caller omits it, so an epoch-less receipt cannot be written by accident.
The one place the author's expectation was amended rather than followed — a
writer without arguments now carries the binding's epoch instead of `-` — is
the stricter of the two readings, and a checkout with no binding still gets
`-` and reads stale.

**A project that declares no probes cannot be confirmed, and is told what to
write.** A green gate over a project with no `probes.tsv` records `-` for its
epoch, because there is nothing Felix reads from reality for the verdict to
rest on. The first draft read that as current ("the gate announces the missing
table; a stop that blocked as well would be stricter than the gate"). It is
stale now, and the reason names the remedy — write the table — rather than a
gate run that would write the same `-`. The self-governed test fixture gained
one probe for it.

**Two fixtures were written on the old assumption.** One edited `stack.tsv`
between its gate and its stop, which is in the epoch's policy set, so the stop
blocked on "the table set moved" — correctly. One read a receipt with a project
other than the one the repository's marker names, so the epoch was written for
one project and read for another. Both are corrected as fixtures; neither
changed the design. A first attempt to fix the first was silently denied by a
hook and the suite ran the old ordering, which cost one run before the
reproduction in the scratchpad showed the design was sound.

**Cost, measured on the engine's own project.** The epoch is recomputed only on
the path that would otherwise say "verified", and it runs the project's
probes: 0.3s here. A governed product with a slow probe — elenchus's route
probe imports its application — pays that at the same moment; not measured,
those checkouts are not on this machine.

**Next, in order.** (1) Re-point `deploy-check` and the `engine_deployed`
obligation at #239's question, so the ledger and the gate agree. Felix's.
(2) A baseline obligation-discovery pass on one governed product that writes
candidates and admits nothing — Felix builds it; the schedule and model spend
are the founder's. (3) CI enforcement of `felix merge`'s blockers, which needs
the founder to choose GitHub Pro or accept that CI is advisory. (4) Grants for
high-risk plugins whose hooks run in every session with no record. (5) Issue
#2 stays open for spec step 5. Standing: `projects/bazaar` and
`projects/webapp` stay untracked.

