# Contract A3: a suite run stands across the one commit that records it

Addendum to contract A (docs/2026-10-12-gate-friction-contract-a.md) and A2.
Found by the orchestrator on 2026-10-12, while starting PR A's own record run.
Its own pull request, version 0.49.282, engine tier, built on PR A.

**Why.** The receipt's tree id is `felix_tree_id`: a hash of the commit HEAD
names, the diff of the working tree against it, and the untracked files'
names, sizes and times. A record run ends with the manifest and red.tsv
changed and not committed. The landing order is record, commit, gate, because
the gate's receipt and `felix merge` judge the tree that is pushed. The commit
changes HEAD, so the tree id moves, and the gate's `--reuse` finds `another
tree` and runs the whole suite again. As built, PR A's reuse never fires in the
one flow it was designed for, and the third suite pass is still paid. The
content the gate would test is byte for byte the content the run passed; only
the commit naming it is new.

## C10. The bridged tree id

1. **What it is.** For a checkout whose HEAD has exactly one parent, the
   bridged id is the id `felix_tree_id` would print for the checkout as it is
   now if HEAD named that parent instead: the same exclusions, the diff of the
   working tree against the parent, the same untracked files and metadata, the
   same hashing. A HEAD with no parent (a root commit, an unborn HEAD) or with
   two or more (a merge) has no bridged id.
2. **When it is asked.** In `_sr_check`, only where the tree id as it is now
   differs from the receipt's, and in the place of the `another tree` refusal.
   A receipt that matches as it is now is answered as today and the bridged id
   is never computed.
3. **When the receipt stands on it.** All of these hold:
   a. HEAD has exactly one parent;
   b. the bridged id equals the receipt's tree id. Since the id hashes the
      commit, this says the parent is the commit the run had at HEAD, and the
      working tree now holds, against it, what the run left: tracked changes
      and untracked files alike. A file the run saw untracked and the commit
      added is tracked now, so the ids differ and the suite runs. That is the
      intended strictness, not a defect;
   c. the parent is not an ancestor of the commit the receipt recorded for
      `refs/remotes/origin/main`. Part 1010's judge skips `_rtn3` and `_rtn4`
      for a tree that holds no commits origin/main lacks, and asks them of
      one that does. A run whose HEAD origin/main already held was not asked
      what the committed tree is asked. A receipt that recorded no origin/main
      (`-`) is not held by this condition, since the judge skips both in
      either state;
   d. every later check in `_sr_check` holds, in the order it has today:
      environment, origin/main, twelve hours.
   One commit only. Two commits since the run is `another tree`.
4. **What it says.** Where the receipt stands on the bridged id, `_sr_check`
   prints `reuse <passed> <failed> <skipped> <end> <mode> <HEAD's full sha>`:
   the line it prints today and a seventh field. Where it stands on the id as
   it is now, the line is exactly today's six fields. `tests/run --reuse` then
   prints
   `reused the suite run that ended <HH:MM> on this tree (<mode>, then committed as <first 8 of HEAD>), not run again`
   in place of today's first line, and the summary line unchanged. That
   sentence still matches what `projects/felix/gate.sh` searches for, so the
   gate reports `tests reused` and the receipt it writes carries
   `tests:reused`, and rule C9 (contract A2) asks GitHub for the gate workflow
   on the exact head before `felix merge` lets it through.
5. **What it refuses with.** Where 3b holds and 3c does not:
   `run another tree (committed since the run, and origin/main already held the commit the run was on)`.
   In every other case where the bridge does not apply: `run another tree`, as
   today.
6. **What does not change.** The receipt's format and every rule of writing
   it (C4), `felix_tree_id`'s output for every caller that exists (it may be
   refactored to share its code with the bridged id, and must print the same
   id for the same state before and after), the gate's search pattern, rule
   C9, the record run and red.

## The claim this rests on, to be checked, not assumed

The run's verdict depends on the commit HEAD names only through part 1010's
judge (`_rt_judge` on the real checkout: merge-base and ancestry against
origin/main). The build must search every part, the driver, receipt.sh and
red for any other read of the real checkout's git state (`git -C` on the
checkout's root, `$REAL_HARNESS/../..`, `git log`, `rev-parse HEAD`, commit
messages, branch names, reflog) and list each one found. Reads of a fixture
repository do not count. If any other read exists whose answer can differ
between the parent with the change uncommitted and HEAD with it committed,
stop and report it: the condition list in 3 is then incomplete.

## What the build must show

The block red on PR A's head (2e4d3b33) and green after. Mutants:
- accept a merge commit (bridge through the first parent);
- drop 3c;
- bridge two commits (the grandparent);
- compute the bridged id from the parent's sha alone, with no diff;
- compute the bridged id against the parent's tree with the diff taken against
  HEAD (the commit's own change dropped);
- print the six-field line when bridged (the commit undisclosed);
- `felix_tree_id` changed for an existing caller by the refactor.
