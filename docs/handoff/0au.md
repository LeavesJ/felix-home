## 0au. Verified at session close, 2026-09-10 — the graph was built three times and asked once, and the reason was a table

| | |
|---|---|
| head | branch `claude/felix-v3-2-graphify-191042`, cut from `main` 54b0341; one pull request, tier **red** on `lib/verify.sh` |
| suite | **1818** passed, 0 failed, on the final tree; 13 assertions added and recorded |
| gate | **red on `installed` alone**, structural in a worktree; ten checkers ok, `commission` reads stale (the home-side run in Next 1) |
| graph | 1909 nodes, 2494 edges, 183 communities; refreshed at the home, recorded |

**The founder asked two things: is the graph refresh owed, and have we been
using graphify.** The first was yes — six merges on the 9th and a graph from
the 6th. The second is a number, not an impression, and it was measured before
anything was built: across 116 session transcripts on disk and 72 sessions in
the ledger, the graph was built or refreshed three times (Sep 4, 5, 6) and
queried in exactly one session — three `graphify query` calls on 2026-09-03,
the same session in which the founder said the tool was being set up and not
used. Zero queries in the six days after that feedback, which sits in a memory
file every session loads. The ledger already knew why: `graphify` had
`named 0` in every session. No route in `projects/felix/routes.tsv` named it,
so Felix never pointed a session at it, and a zero in the `reached` column of a
capability nothing names measures the table, not the tool. A reminder did not
change behaviour. §0ap item 10 said the same about `installed`: a lesson that
is advice about a behaviour is not working; build the mechanism.

**Three mechanisms shipped, one pull request.**

1. **An `orient` route** (`orient graphify trace caller callers calls
   architecture codebase` → `graphify`), placed above the subsystem rows so a
   question about the harness's shape beats the play for changing it, and a
   `skill graphify` row in `stack.tsv` so `felix ready` can find it — the row
   Elenchus already carried. Measured with the worktree engine: a plain
   how-does-it-fit question routes to graphify; "add a dependency to the
   stack" still routes to tooling; a traceback still ties toward debug by file
   order. A question naming a subsystem twice ("gate receipt") still wins on
   typed count; that is the router's design, not a defect here.

2. **The graphify maintenance check looks beside the repository's `.git`.** It
   looked in the current directory, and a worktree has no `graphify-out/` of
   its own, so the row read due in every worktree session whatever the graph's
   age. Sixteen of the seventeen session roots recorded for this project are
   worktrees. A due that is on almost always carries no information, which is
   the defect class §0ap named for this row and left standing.
   `dirname "$(git rev-parse --git-common-dir)"` is `.` in the checkout that
   holds the graph and that checkout's path from any worktree. Shipped in the
   template and in all three project tables, as §0aq did. Shown failing first
   on a fixture worktree with a fresh graph: old check `due`, new check `ok`;
   and a commit in the worktree the graph has not seen is due there while the
   holding checkout stays ok. Four assertions.

3. **`felix_qualify_ungoverned` has a caller.** §0at's item 2. The gate's
   output was a `mktemp` file the command threw away after reading the skip
   list, so the only roster of what the gate checks was the one a session typed
   into §0at by hand. The receipt now carries a sixth field, `name:verdict` for
   every check the gate printed, appended after the skip list so every
   positional reader is undisturbed — the argument the fifth field made.
   `felix qualify` (not `--gate`, because this is a gap report and not a
   verdict) reads it and prints `reported by the last gate and qualified by no
   row: …`, or says the receipt has no roster, or that there is no receipt for
   this tree. Shown failing first: the deployed 0.49.109 engine writes no sixth
   field, the worktree engine writes `syntax:ok,tests:skipped`. Nine assertions
   across the receipt, the extractor, the lib and the command.

   And the first real gate run caught the extractor. It listed three verdict
   words — ok, FAIL, skipped — and the gate printed `commission stale`, a
   checker that ran, reported, and would have been absent from the roster;
   the source prints `waits` too. Both readers now take the line's shape
   instead: two spaces, a lowercase name, a word. Sub-lines start deeper or
   with a number, the header's first token carries a colon or a slash. This
   is the lesson already on file — a reader that has never been given real
   input is not known to work, however many tests it has — and the suite's
   twelve green assertions had not been given one.

**The refresh, and what it can and cannot answer.** 32 files had changed since
the 6th: 23 code through AST in seconds, 9 documents through three extraction
subagents (HANDOFF.md alone; the four handover docs; the small ones), 676,222
input tokens, health OK, +510 nodes and +800 edges against the old graph. 131
of 183 communities kept their previous names by majority overlap and 52 were
named this session. The session's own question was asked before and after: the
Sep 6 graph had no node for `felix_qualify_ungoverned` and drifted to
`ready.sh`; the refreshed graph places it at `qualify.sh:L119` with one edge
and no caller, which is right for `main`. Then the known blind spot,
re-measured: `who calls felix_maint_status` returns no caller and grep finds
five, every one inside `$(…)`. On this harness the graph is the tool for what
a function calls and how the pieces group, and grep is the oracle for who
calls it. That is a lesson now, and it matches the orient route.

**Found, not fixed.**

- `projects/webapp/` sits untracked in the home, created 2026-09-09 19:00 by
  nothing any transcript names — a `felix new`-shaped scaffold whose gate is
  `npm run verify`. The independence scan enumerates it and passes; the graph
  now carries a "webapp constitution" node. It is a stray, and removing it is
  the founder's call, not a session's.
- The two provider requests read stale against a topology the request files
  themselves do not carry: `felix commission` has to run in the home to rewrite
  them before any session can answer. It was not run from this worktree,
  because a run declares into the home's `stack.tsv`, and a dirty home file
  under a pull request that edits the same file is the trap §0at's merge
  instructions exist to avoid.
- The graph will be due again the moment this branch merges — the row says
  "after a merge" and means it — and the refresh models the home's `main`, so
  this section is not in it until then.
- This session opened in a worktree, again, against the constitution's
  Non-obvious patterns entry, for the reason §0at gives: the app chose the
  root. The cost is the same. `installed` is red here structurally, and no
  receipt in this session can be green.

**Next, in order.** (1) *Done the same evening, and the order first written
here was wrong.* #218 merged with `gh pr merge --merge`, `felix install` in
the home bumped to 0.49.110, and the founder ran `felix commission` and then
re-granted `commission`. Grant last, not first: the grant is stamped over
twelve tables and `stack.tsv` is one of them, and a commission run can add
rows to it, so a grant taken before the run is stale the moment the run
declares. With the deployed engine matching the tree, the gate in this
worktree went green on all twelve checkers and its receipt carries the
roster. What remained for a session was the two provider requests, rewritten
by that run for topology `00565f52…`; §0av says how they were answered. The
graph is due again after the merge, as the row says. (2) The next checker
through the six controls, blind — `executable` or
`syntax` — with its assertions blind-authored as well; `felix qualify` now
prints the eight to choose from once a gate has run in that tree. (3)
find-skills item one, the content hash. (4) Step 2's epochs as hashes.

