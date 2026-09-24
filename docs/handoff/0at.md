## 0at. Verified at session close, 2026-09-09 — the §0as queue built end to end, then reviewed, and every pull request in it changed

**Nothing landed on main.** Six stacked pull requests, #212 through #217 —
five of code and this section — each branch cut from the one before it,
each gate green on the runner and red here on `installed` alone: the
structural line a worktree cannot clear, because clearing it means running
`felix install` in the home and the marketplace is pinned there. The
session was opened in a worktree despite the constitution's Non-obvious
patterns entry saying the home; the cost is this shape, and it is why no
gate receipt in this session is green. (§0as says nothing about the home:
an earlier draft of this section cited it, and it does not.) No PR bumps plugin.json; the merger runs
`felix install` once in the home, which bumps. The founder's `commission`
grant is stamped over a set of tables that already moved — #210 changed
risk.tsv, so it reads stale on main today, before any of this — and #212
(probes.tsv), #214 (commissioning.tsv and, now, obligations.tsv) move it
again. Re-grant once, after the stack lands.

**How they merge, measured rather than reasoned.** Squash-merging the stack
in order conflicts at #214 on tests/assertions.tsv: every PR re-records the
manifest, the file is sorted, and adjacent insertions from two PRs are one
overlapping hunk to git. Merge commits and rebase merges in order are both
clean, all six, in a fresh clone of the remote. `felix merge` squashes, so
it is not the tool for these; `gh pr merge --merge` in order is, and the
one-merge-then-rebase-the-rest alternative is a person's work six times
over.

**#212, hook_binding reads keys.** `bin/hooks-events` sources the scanner
coverage.sh grew in #210 and prints the keys of the hooks object, exit 2
with nothing to read. The probe row names it by a bare path and
felix_probe_source records a size token for a path under the checkout,
which is the one instrument whose token should move with the tree. The
decoupled copy is the control: not an event to hooks-events, an event to
the grep it replaced. felix_coverage_events, the roster of what anything on
this machine binds, read the same grep and goes through the scanner too.

**#213, an unreadable catalogue is not an empty one.**
felix_discover_candidates exits 3 when the CLI is absent, fails, or answers
with something that is not a listing; cmd_discover checks before the stamp,
so the quiet form writes nothing and every cache writer's `&&` leaves the
last real answer standing. --adopt says the catalogue was never seen rather
than "nothing to adopt", and the background refresh no longer leaves a
half-written file beside the cache.

**#214, step 8 has a row.** `obligations`, answered by `felix:obligations
--seed`, done when the ledger has rows, none refused, none orphaned. The
answer writes the template's row where no ledger exists and never over
one; `felix new` seeds the same file. The step that had had nothing
answering it since the pipeline was written reads `rows` in steps.tsv.

**#215, the second obligation.** `engine_deployed`, TASK_BLOCKING,
evidence `bin/deploy-check`, applies where a plugin cache exists and the
marketplace serves this tree. DORMANT in every worktree and on every CI
runner, reported and never waived; in the served checkout it fails beside
`installed` until `felix install` runs. Not RELEASE_BLOCKING, because at
the merge boundary the tree judged is a branch main has not taken and
never matches the deployment. Not in qualification.tsv, because every
control runs in a detached worktree where the row is dormant by
construction; the suite shows it failing on a fixture deployment. The
gate's `executable` check now covers every script under bin/ rather than
the one somebody listed.

**#216, memory-scan, and what blind controls found in a check that had
passed since August.** Invariant 6's readable half is a command now. The
twelve mutations were written by an agent given the property in prose and
forbidden the checker, and run against the inline form as the gate carried
it, one held: the same lessons.md tracked one level up passed, because
memory was a path. The second hole came from reading why a control that
was MET had been met — the violation row failed only because the project
whose maintenance.log does not exist was reported, and `git check-ignore`
never reports a TRACKED file, so the two logs that existed were invisible
to that half by construction. A control can be met for a reason that is
itself a defect, and only reading says so. The scanner asks with --no-index and looks for the
canonical memory files by name under projects/, and says that the second
is a heuristic with the residual §6 names. All twelve declared, all twelve
met on the real runner. Qualified checkers: four of twelve. In passing:
`felix qualify` printed printf's usage in the middle of its report because
its closing sentence began with `--gate`; fixed in the same PR.

**Then the same stack was reviewed, and every PR in it changed.** Fourteen
agents — one per pull request, three cross-cutting lenses (test
reachability, constitution invariants and portability, exit-code
semantics), each finding then put to three refuters told to default to
refuted. Thirty-one findings. What it caught is worth stating plainly,
because most of it is the same shape:

- **#213 shipped its own inverse.** `felix_discover_candidates` ended in a
  pipeline whose status was the scoring loop's, and a `while` loop's status
  is its last body command's — so it returned 1 whenever the LAST entry in
  the listing did not match, which is most listings. That was harmless on
  main, where nobody read the status. #213 started reading it and mapped
  every non-zero to "could not be read": a catalogue read perfectly well,
  reported unreadable. Measured against the real CLI, 265 names parsed and
  the function returned 1. `head -N` closing the pipe was a second path to
  the same thing. The status is stated now, not inherited, and the caller
  tests the declared code rather than "non-zero".
- **A hooks.json that does not parse read as fully wired.** The scanner
  printed the keys it had reached and returned 0, so a truncated file made
  lifecycle_wired — RELEASE_BLOCKING — read SATISFIED. Keys are held until
  the scan ends at depth 0 outside a string; otherwise nothing is printed
  and the status is cannot-examine.
- **The seeded ledger blocked a stranger on day one.** The template row
  applied to any tracked path ending in `hooks.json`, so a web app with
  `src/config/hooks.json` got an ACTIVE obligation whose evidence exits 2 —
  UNKNOWN, blocking — the day `felix new` ran. It asks for a plugin
  manifest and a hooks file at a plugin's path now, and both fixtures are
  in the suite.
- **memory-scan could not see the file it exists for.** Its list of memory
  filenames was written from recollection rather than from the directory,
  and omitted `routes.log`, which stores the founder's prompt text
  verbatim. Also decisions.log, the ledger shards, and a rotated ledger.
- **deploy-check answered "does not apply" for three ways of failing to
  look**, and DORMANT is a row that stops blocking. It resolves itself
  before the cd now and answers 126 or 127, which are UNKNOWN.
- **Seven assertions could not fail for the reason they named.** The
  roster fixture was green under both implementations; `has ... "rc=1"`
  is satisfied by rc=126 and rc=127; the "gate runs memory-scan" guard
  matched a comment in gate.sh; the "cache untouched" case ran a path with
  no cache writer in it; "felix new seeds the ledger" was true either way
  because the commissioning answer seeds the same file; the swallowed-rule
  case got its exit 1 from an untracked log the old form also reported.

Each fix is a commit on the PR it belongs to, and each was shown failing
on the code before it. The lesson is one this repository already carries in
another form: a test written from the same understanding as the code
inherits its blind spot, which is why the blind-authorship rule exists for
controls — and it should extend to the assertions around a change, not
only to the mutations that qualify a checker.

**Found, not fixed.** felix_qualify_ungoverned — the function that names a
gate check no row qualifies — has no caller anywhere in the engine, so the
gap it was written to print has never been printed. The eight unqualified
checkers are known only because this session counted them by hand:
syntax, executable, installed, tests, ecosystem, probes, qualified,
commission.

**Two mechanics learned.** The fact-forcing hook keys on removal and force
tokens inside heredocs too, so a test block that undoes its own fixture
cannot be written through Bash; copy the seed per case and write the block
with the Write tool. And the gate in a worktree does run the suite — the
structural `installed` branch does not skip it — so a red gate here is one
line, not a skipped verification.

**Distance, corrected.** Build step 2 has two admitted obligations, one
with a dormancy that is real; step 8 of commissioning has a row; four of
twelve checkers are through the six controls. Still absent from step 2:
epochs as hashes, leases, enforcement classes beyond blocking, the
candidate lifecycle. Still unbuilt: control 7 as a report the gate reads,
and the find-skills items one and two — a content hash of the copy Felix
read against the copy it installed, and announced install drift.

**What this session got wrong.** It said twice, in a memory note and in
the first draft of this section, that the stack squash-merges cleanly,
from reasoning about three-way merges rather than from running one; a
clone showed the conflict at the third PR in under a minute. It reported
the five PRs as finished work with a green CI gate, and a review of that
same work found thirty-one findings, six of them defects that would have
shipped — including one that inverted the fix it was part of. And in
reproducing that one it first ran a bash library under zsh and read the
result, which this project has a lesson about. The rule the handoffs keep
recording — claims about state are read, not recalled — covers what git
will do, what a shell will do, and above all a green suite: 1767
assertions passed over every one of those defects.

**Next session's first actions, in order.** (1) Open in the home. Merge
#212 through #217 in that order with `gh pr merge --merge`, not `felix
merge`, then `felix install` once, then re-grant `commission`. (2) Give felix_qualify_ungoverned a caller: `felix qualify`
reads the last gate receipt's lines and prints the checkers no row
qualifies, so the count above stops being a thing somebody did by hand.
(3) The next checker, blind: `executable` or `syntax`, both already
commands in shape. Give its ASSERTIONS to a blind author as well, not just
its mutations; that is what this round argues for. (4) find-skills item one, the content hash. (5) Step 2's
epochs as hashes, which the amendment counted twice and nothing has
started.

