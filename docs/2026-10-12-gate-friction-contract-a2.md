# Contract A2: a reused tests verdict merges only on a green CI gate

Addendum to contract A (docs/2026-10-12-gate-friction-contract-a.md), from
the push security review of 2026-10-12 on `projects/felix/gate.sh`'s reuse
branch. Same branch, same version (0.49.281), same tier.

**Why.** felix-home has no branch protection (the plan does not allow it on a
private repository), and `felix merge` does not ask CI: its boundary,
`felix_merge_blockers` in `engine/harness/lib/escape.sh`, needs a current
green gate receipt for the exact tree and the evidence rows. "Merge on green
CI" has been a convention. Contract A lets the receipt's tests verdict come
from a suite receipt, a second file a session can write. Forging it grants
nothing that writing the gate receipt does not already grant, but a defect
that reuses a run it should not would reach a merge with nothing independent
behind it. So a reused verdict needs the independent one.

## C9. felix merge and tests:reused

In `felix_merge_blockers`, after the current-receipt check and only when the
receipt is current and green:

1. If the receipt's reported field (the sixth) holds the pair `tests:reused`,
   the merge needs the project's gate workflow (the one `felix_gate_workflow`
   names, as `lib/repair.sh` and `lib/automerge.sh` already ask it) to have a
   run on the exact head commit being merged whose status is `completed` and
   whose conclusion is `success`. Asked with `gh run list` for that workflow
   and that commit, as those two libraries ask it.

   **Which run counts: the newest run on the head commit.** `gh` lists runs
   newest first, and the first one that is on the head decides. An older
   success never stands in for a newer run that failed or has not finished,
   because a second run on one head tests it in a different base (a pull
   request reopened after main moved, or the same head in two of them). A run
   is on the head only when its own `headSha` is exactly the head sha; one
   whose `headSha` is another commit is not, and one whose `headSha` `gh` did
   not give (missing, null or empty) cannot be placed and is unreadable, never
   a run on this commit. (Review finding C9-R1 and C9-R2, 2026-10-12.)
2. When it has one: no blocker from this rule.
3. Otherwise one blocker row, kind `unverified`, subject `tests`, whose reason
   begins `the gate reused a suite run for this tree (tests:reused), and the
   gate workflow has not passed on <first 8 of the head sha>:` followed by
   which of these held:
   - `no run on this commit`;
   - `its run is <status>` when the newest run on the head has not completed;
   - `its run concluded <conclusion>` when the newest run on the head
     completed and did not succeed;
   - `GitHub could not be asked (<what failed>)` when `gh` is missing, fails,
     or prints nothing a run can be read from, or lists a run it cannot be
     read from or placed on a commit. Unreadable is never "no runs" and never
     a pass.
4. A receipt without `tests:reused`, `tests:ok` included, is judged exactly as
   today: this rule asks nothing of it and makes no call to `gh`.
5. `felix merge --dry-run` reports the blocker as it reports the others.
6. The receipt is read once. The text `felix_verify_current` judges is the text
   the reported field is read from, so a gate that rewrites the receipt while
   the merge is judged cannot make the rule read an empty or a different one
   and skip. (`felix_verify_current` takes the receipt's text as an optional
   fourth argument for this; review finding C9-R3.)
7. The input to this rule is the gate's report, and the gate reports `reused`
   (contract A, C7) for a log that shows reuse anywhere: the suite's reuse
   sentence on any line, including after a fragment that sits in front of it
   without a newline, or a summary line ending ` (reused)`. A log with no
   sign of reuse is `ok`. Reporting `ok` for a reused suite would write
   `tests:ok` and ask nothing of GitHub. (Review finding C9-R4.)

The judge is the engine main declares, so this rule binds from the deploy of
the commit that carries it. PR A itself is gated with a full suite run, not a
reused one, so it is not held by its own rule.

## What the build must show

The block red on the code before C9, then green. Mutants: drop the rule;
treat a gh failure as a pass; accept a run on another commit; accept
`in_progress`; ask gh when the receipt says `tests:ok`; match `tests:reused`
as a substring of another pair (`xtests:reused`, `tests:reusedx`).

Added after the review of the first build (2026-10-12): one assertion in
part 1150, marked "not blind", for each of C9-R1 to C9-R4, each red on the
first build (779d7f39) and green on the fix.
