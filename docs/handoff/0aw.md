## 0aw. Verified at session close, 2026-09-12 — the upkeep ran, a fifth project appeared, and the graph dropped twelve edges without saying so

| | |
|---|---|
| head | `main` 7642e09; this section and the records on `chore/maintenance-2026-09-12` |
| maintenance | `deployed` and `graphify` both recorded; every row now reads ok |
| graph | 1970 nodes, 2546 edges, 200 communities; 411,984 input tokens, health OK |
| projects | five directories under `projects/`, and **two of them are untracked** |

**Both due routines ran on one branch, which is what the table asks for.**
`graphify` came due because #219 merged, exactly as the row is designed to
behave. The refresh took 8 code files through AST and 2 documents through
extraction agents — `HANDOFF.md`, and the constitution of a project this
session had never heard of. `deployed` came due on its seven-day cadence and
the thing it asks is true: `engine/harness` is byte-identical to the deployed
0.49.110 copy, checked with `diff -rq` before the run was recorded rather than
after. Recording is a tracked write, so both lines are in this branch's commit.

**A fifth governed project exists and is not in this repository.** `bazaar`
appeared under `projects/` on 2026-09-10, pointing at `LeavesJ/black-box-bazaar`
with a real marker at `~/Documents/BlackBoxBazaar`, its own `gate.sh` that
refuses a tree that is not the bazaar, capabilities `frontend tests`, and a
`maturity` key in `project.json` that no other project carries. Read from its
own checkout it is in better shape than Felix: 11 of 12 commissioning rows done,
one held, and both provider rows answered by an earlier session. Its own
`graphify` row is due there, along with `dead-code` and `dependencies`. Two
things about it are Felix's business and neither is a session's to decide.
`projects/bazaar/` is **untracked**, so a constitution, a gate and ten tables
that govern real work exist on one disk and in no commit — and `projects/webapp/`,
the stray §0au named, is still untracked beside it with an empty `remote_match`.
The independence check enumerates both and passes, because it reads the working
tree rather than the index.

**The graph dropped twelve edges and every instrument said fine.** The bazaar
extraction was told to point at the sibling constitutions, and produced 18
cross-file edges. Six are in the graph. The other twelve named node ids no
sibling extraction had ever minted — `projects_felix_claude_gate` does not
exist, while `projects_veldra_claude_invariants` does — and they are simply
gone. Measured on a two-edge fixture rather than argued: `build_from_json`
takes two edges and returns one, creates no ghost node for the unknown
endpoint, and prints nothing to stderr. `diagnose_extraction` on the raw
extraction counts the dangling edge; on the post-build extraction it counts
zero. The update runbook rewrites `.graphify_extract.json` from the built graph
before the health step reads it, so the check runs on the file the drop already
cleaned, and reports OK. This repository has a name for that shape — the place
it ran was not the place it mattered — and it is now in `lessons.md`.

**What this says about using the graph, not only refreshing it.** The orient
route sent a structure question at the graph and the graph answered two ways.
Asked narrowly — explain one node — it was exact and cited line ranges. Asked
broadly, "how does bazaar relate to the fleet", it started from seven nodes,
reached 565, and truncated to 19 at the token budget, which is an answer nobody
can act on. The narrow question is the one to ask, and `felix qualify`'s habit
of naming a specific checker is the shape to copy.

**Next, in order.** (1) The founder decides whether `projects/bazaar/` and
`projects/webapp/` are committed; until then the fleet is four projects in git
and five on disk. (2) The next checker through the six controls, blind —
`executable` or `syntax` — with its assertions blind-authored as well;
`felix qualify` now reads the receipt roster and names the eight that no row
qualifies. (3) find-skills item one, the content hash. (4) Step 2's epochs as
hashes. (5) The §0av audit findings are unapplied on purpose: the constitution
is the founder's to edit, and the score is what Felix reads.

