### 2026-10-08: a pull request's default title is the newest commit the branch made itself, not a merge of main or what the landing wrote

**Defect closed.** `felix pr` titled a pull request with HEAD's subject when no
`--title` was given. The landing protocol merges main in, then commits the
version slot, the suite's record and the handoff section, so HEAD is almost
never the branch's own work. #395 reached main as "Merge remote-tracking branch
'origin/main' into claude/red-counts-unreached". `felix merge` had the same
defect where gh gives no title: its squash subject fell back to the newest
commit that is not a merge.

**Measured on history before deciding.** I replayed the rules over the sixty
pull requests merged before this. The base was each squash commit's parent, and
every head was already in the local object store.

| rule | merge | version or record | handoff section |
|---|---|---|---|
| old: HEAD's subject | 31 | 16 | — |
| new | 0 | 2 | 6 |

- The two records are commits that also changed tests/run.
- The six handoff sections are on pull requests that were themselves handoffs.

**The rule** is felix_pr_title in lib/intake.sh, beside felix_pr_body.
`felix pr` and `felix merge`'s fallback both call it. It takes the newest commit
of `git log --first-parent --no-merges <base>..HEAD` whose paths are not all
among:
- engine/.claude-plugin/plugin.json, the version slot;
- engine/harness/tests/assertions.tsv and red.tsv, the record;
- `$FELIX_HANDOFF_PENDING/*`, the handoff section.

Why each part:
- **--first-parent.** A branch that merges another branch's head before that
  one lands holds its commits, and after a squash merge main never does. It
  changes 12 of the 60 titles. #404 merged carrier/unattended-pin, which
  carried other pull requests' heads.
- **Named by path, not subject.** Record and version commits carry five subject
  prefixes in the history: test(record), test(red), chore(tests),
  chore(version) and chore(engine). Their paths never vary.
- **The version slot is in the set.** With records alone skipped, seven titles
  moved from a record subject to `chore(version): 0.49.x`.
- **The handoff section is in the set.** It was left out at first, and the
  adversarial review pointed at #395 itself: its title would have been its
  pending note. With sections skipped, 16 titles change, and 14 of them move
  to a fix or test commit of the branch's own. #395's becomes a docs(red)
  commit of its own. #369, itself a handoff, moves to a handoff commit outside
  the pending directory.
- **Fallbacks.** If every commit the branch made is the landing's, the newest
  of them is the title. If the branch made none, or the base cannot be read,
  HEAD's subject is the title, as before. An empty commit counts as the
  branch's own.
- **Read defensively.** `--no-show-signature` on both reads, and `--` after
  the title's revision. The branch's read takes no `--`: git never reads a range
  as a path, so no tracked file can make it ambiguous. A `--` there was tried,
  and the mutant that dropped it lived.

**Built red first, then reviewed.**
- **Red first.** Eight assertions first, in a repository of their own with
  fixed commit dates. Six were red against main 6fe5f986.
- **Review.** The adversarial review (Opus) confirmed the replay numbers, bash
  3.2 behaviour, shallow clones, octopus merges, an unreadable base and a dozen
  git configs. Invariant 1 holds: independence-scan exits 0, and
  felix_self_governed already defines the engine's home by
  engine/.claude-plugin/plugin.json. The review found:
  - the handoff-section titles above;
  - five mutants the first tests let live: `engine/*`, basename matching, a
    subject-keyed rule, no `--root`, and the oldest record instead of the
    newest;
  - an empty title under log.showSignature with a signed newest commit;
  - an empty title when a tracked file is named HEAD;
  - the `felix merge` sibling;
  - a wrong example for --first-parent (#392, where the flag changes nothing).

  All of these are fixed.
- **Final count.** 13 assertions in the pr block and one in the L1 merge
  harness (gh stubbed, so its title fallback fires).
  - Against main: 10 of the 13 and the L1 one are red. The other three pin
    behaviour main already had: the no-own-commit fallback, `--title`, and the
    tracked file named HEAD.
  - With the fix, the pr block passes 13/13 and the L1 section 26/26.
- **Mutation.** 18 mutants, each killed by at least one assertion:
  - no --first-parent, and no --no-merges;
  - no skip, the red record alone, the set without plugin.json, and the set
    without assertions.tsv;
  - `engine/*`, basename matching, and a subject-keyed rule;
  - no --root, the oldest record, no handoff section, and empty commits
    skipped;
  - no newest-own fallback;
  - either `--no-show-signature` dropped, and the title's `--` dropped;
  - felix merge's old fallback.

**Handed on, not done here.**
- **Signature lines in two other reads.** felix_pr_body and felix merge's
  squash body read `git log` without `--no-show-signature`. Under
  log.showSignature, signature lines would enter a body. Neither reads a title,
  and this machine does not set it.
