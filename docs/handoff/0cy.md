### 0cy. 2026-10-02: lib/qualify.sh is split along its run/read seam, and a later qualify run sweeps the scratch trees a SIGKILLed run left, and nothing else

Carries the split "Split lib/qualify.sh along its run/read seam" (0.49.256 in
the carrier's order). Its owner session died without pushing, so this branch
took it over by the carrier's offer. It was stacked on
claude/qualify-rows-fresh-shell, which carried claude/qualify-scratch-cleanup
and squash-landed as #394 (a7873475). 0e2fe828 merges that main in. It lands
after claude/engine-mktemp-tmpdir.

**The split** (8ce83681, alone in its commit): `_felix_qualify_drop`,
`_felix_qualify_arm`, `_felix_qualify_sh`, `_felix_qualify_errfile` and
`_felix_qualify_one` move byte for byte into lib/qualify-run.sh. lib/qualify.sh
sources the new file where the block was, so every caller (felix,
lib/obligations.sh, tests/run) still sources lib/qualify.sh alone.

The move was checked mechanically:
- the moved lines equal the removed ones;
- the rest of the old file equals the new lib/qualify.sh minus its four
  sourcing lines;
- the three qualification sections give identical verdicts before and after.

f0ddd0d2 then takes engine-mktemp-tmpdir's four `felix-qualify.XXXXXX` template
lines byte for byte. Whichever branch lands second keeps the template; grep for
it after the merge.

**The main merge** (0e2fe828). main's lib/qualify.sh is byte-identical to the
split's parent 9b30ad0c, so the split side was taken. tests/run took the
branch side in its five conflicts and main's clean hunks everywhere else. The
merge differs from main in four harness paths and plugin.json. The four are
this branch's own, and their changed lines are the same as the branch's own
since 9b30ad0c.

**Defect closed.** `_felix_qualify_arm` traps INT, TERM and HUP in the row's own
process, but no trap reaches SIGKILL: `kill -9`, or a tool's TERM-then-KILL. A
row killed that way left its worktree on disk in TMPDIR and registered in the
user's repository. Three such trees were found in the home checkout on
2026-09-25.

**Fix.**
- **Each row writes an owner record before anything else.** It is a symlink,
  `$base/owner`, whose text is `<pid> <start>`. The pid is the row's own
  process, not the CLI's `$$`. On bash 3.2 it comes from /bin/sh by its path
  and must pass kill -0 when read. The start is ps lstart under TZ=UTC0 on
  macOS. On Linux it is the start ticks, the pid namespace and the boot id,
  from /proc.
- **The record is written before the traps and before `git worktree add`.** A
  row whose record cannot be made does not run. It reads unrunnable and says
  so.
- **The drop removes the record last.** A base that cannot be emptied, or a
  drop killed half way, still names a process a later sweep can judge. The
  drop empties and removes a base from inside it, entered and checked to be
  the base. It hands git a tree's path exactly as the root lists it, and
  nothing when the root lists none.
- **`_felix_qualify_sweep root` (lib/qualify-sweep.sh) runs once per run,
  before the first row, from `_felix_qualify_run_rows`.** So `felix qualify`,
  `felix gate` and `felix_qualify_run` all get it.
  - It looks only at `${TMPDIR:-/tmp}/felix-qualify.<six alnum>` directories
    that are real directories, the user's own, and hold a record that parses.
  - A base is removed only when its process is *shown* dead: kill -0 says "No
    such process", or the pid now has another start. A dead base is claimed
    from inside it with a lock link (`ln -n` at a name never taken, then mv's
    no-follow flag over owner), so two sweeps never drop it together. Then
    `_felix_qualify_drop` drops it.
  - It then removes, one `git worktree remove -f -f` each, the registrations of
    `<T>/felix-qualify.<six>/w` whose base is shown absent.
  - It never runs `git worktree prune` and prints nothing on stdout. It says
    only what is really left.
- **A column's stderr file is no longer removed by its path after the column**
  (b66e03a7). The next column's errfile or the drop takes it, so a row that
  swapped its base for a symlink no longer has a file named err deleted
  outside.

**Decided, not left.**
- **Owner pid, not a lock or an age.** The user named kill -0. The start time
  was added because a pid is handed to another process once its owner is
  gone. kill -0 alone would read that pid alive, and the tree would wait until
  that process ends too. That is a leak, not a removal.
  - Every check that cannot be completed reads alive: a fork that fails,
    another user's pid (EPERM), or a ps that prints nothing. So the failure
    direction is a leak, never a live tree removed.
- **Linux records name the boot id beside the pid namespace.** The initial
  pid namespace has the same inode on every kernel, so the namespace alone
  does not tell machines apart. A Linux sweep judges no record that names
  neither. The cost is in the header: a base left by a row killed before a
  reboot, or before a container restart over a TMPDIR that persists, reads
  alive for good.
- **git gets the listed path or nothing.** A reviewer's alternative,
  `git --git-dir=... worktree remove ./w` from inside the base, was rejected:
  it was measured to remove the other worktree when the tree, rather than the
  base, is swapped as git starts.
- **Silent on success.** The sweep's lines would land in `felix gate`'s qout,
  where `felix: ` lines are lifted under FAIL, and in every test that reads
  felix qualify's stderr. The drop's convention already holds: say only what
  is left.
- **TMPDIR only.** On this Mac every session shares
  /var/folders/…/T (`getconf DARWIN_USER_TEMP_DIR`), so nothing is lost. A
  base in another TMPDIR is in the header's "cannot reach" list.
- **Orphans only under T.** A registration whose base is gone elsewhere could
  belong to a live run on another machine sharing the .git (the home is in
  iCloud Documents). Another repository's registration of a base swept here
  is removed by that repository's own next sweep.
- **The existing scratch-tree section now pins TMPDIR.** From now on another
  session's sweep could remove a dead base there before that section checks
  it, which would mask a defect.

**What still follows a name.** The sweep's claim and the drop's clear follow
no symlink in a base, and git is handed only a path the root lists. Three
instants remain, each named in a header:
- the drop's chmod of a base it cannot enter, by name;
- each chmod of the drop's find walk;
- the instant between git's worktree list and git's own read of it.

A running process that swaps in a symlink at one of those instants leads the
chmod, or git, to its target.

**Built by the engine-build workflow.** Every stage ran on Opus 5.5: lib/qualify
is race and authority code under the report-v5 prior.
- **Spec** (lead session): the contract, written before any code. Each fix
  round amended it, and each amendment is marked with its round.
- **Blind assertions** (xhigh): 63, from the contract alone. Red on origin/main
  63/63 and on f0ddd0d2 61/63. The two green on f0ddd0d2 are behaviour the
  contract keeps (a row that runs to its end, or whose caller alone was killed,
  removes its own tree).
- **Implementation** (high): one red round. A record ending in a newline read
  as a bare pid until `readlink -n` and a sentinel were used. Then 63/63.
- **Three adversarial reviews** (xhigh: safety, races, tests) raised 26
  findings: 6 blockers, 11 majors and 9 minors. The blockers:
  - a forking `sh` on PATH made a live row record a dead pid;
  - the drop's new clear followed a base swapped for a symlink mid-drop;
  - a caller's failglob or noglob broke the sweep and the drop;
  - a sweep killed mid-claim left a base no later sweep could take;
  - Linux lstart moved with a stepped clock;
  - the owner link changed an existing fresh-shell assertion's entry count.
- **Fix round 1** (high, 463a2798..7c537488): every blocker and major was
  reproduced, pinned by an assertion shown red on 3fdfcbb0 or on the
  reviewer's named wrong engine, then fixed. Two minors were rejected with
  reasons.
  - The tests reviewer built 31 named wrong engines. The fix round showed
    noclaim, emptyps and dollar caught by new assertions. The lead then
    rebuilt the three claim mutants against the lock-link claim: noclaim fails
    6 assertions and claimignored 1. noverify, which renames its claim over
    owner without checking that owner still holds the record judged dead,
    passed them all. bdf8c01a stages that window: a sweep held after its chmod
    while another stands in its drop's git. It is red on noverify (owner
    changed, one worktree remove) and green on the head.
  - physonly and onceunown still survive, by decision: git records physical
    paths, and the second clear only leaves an empty base for the next run.
- **Re-review 1** (xhigh): 1 blocker, 1 major, 2 minors.
  - The blocker: the claim's `ln -s` and `mv -f` followed a symlink out of a
    dead base, writing outside it on every sweep.
  - The major: through a base swapped for a symlink under a TMPDIR given
    through one (the macOS default), `git worktree remove "$base/w"` could
    delete another worktree of the root.
- **Fix round 2** (high, c55783c7..0ed6ca10): the claim moved inside the base;
  git gets the listed path; the boot id; record-removed-last pinned by an rm
  hold where chflags is absent.
- **Re-review 2** (xhigh): 1 major, 4 minors.
  - The major: the "nothing when the root lists none" rule was unpinned, and
    a mutant giving git `$base/w` there deleted another worktree and its work.
  - The minors: the unown's `ln -s` without `-n`; the runner's `rm -f "$3"`
    (older than this branch); the Linux reboot cost unsaid; pid 1 on Linux
    passing without reaching kill -0.
- **Fix round 3** (high, 71448670..f7327bdb): case 9d pins the major (red on
  the mutant: `removes:1 file:gone registered:no`). The unown uses `ln -s -n`.
  The `rm -f "$3"` is gone (9e, red on 0ed6ca10). The header names the reboot
  cost. On a namespaced host case 6 plants pid 1 with its own start.
  - The `ln -n` is not pinned: the only staging is a PATH shim keyed on how
    the restore is spelled, which would pass vacuously on an equally correct
    rewrite.
  - The lead re-ran the reviewer's three probes on the final head: no remove
    and the decoy's work intact (the mutant deletes it); outside/ empty after
    the unown (0ed6ca10 put the record there); outside/err intact (0ed6ca10
    deleted it).
  - The lead re-ran the whole section with the final tests: the mutant fails
    both 9d cases and 9e (96/3/3), 0ed6ca10 fails 9e alone (98/1/3), and
    nothing else fails on either.
- **Review 4** (xhigh, round 3 only): no blocker or major. Every round-3
  claim reproduced.
  - On its own mutant, which gives git `$base/w` when the root lists nothing,
    exactly the two 9d cases fail (97/2/3).
  - It traced the err file's life: each column's errfile removes and
    recreates it before the column, so no column reads another's.
  - Its one minor is the unpinned `ln -n`, decided above. Its first two
    structured answers failed the schema, and the third was a placeholder
    (`"summary":"test"`). The findings above are read from its transcript
    (wf_3c37b2bf-0be).

**Section results on this machine** (bash 3.2.57), on the merged head
0e2fe828:
- the new section: 99 passed, 0 failed, 3 skipped;
- the scratch-tree section: 33 of 33;
- the shell-of-its-own section: 60 of 62.

The 3 skips are the namespace case that applies only to Linux, a failed fork
and a second user, which this suite cannot stage. The 2 failures in the
shell-of-its-own section are section-runner artifacts: those blocks read
fixtures made earlier in the suite. They fail the same way on 9b30ad0c and on
0ed6ca10. The record and the gate wait for the carrier's slot call.

**Not run here.**
- The Linux /proc path for real; it was staged through `_felix_qualify_proc`.
  The CI runner is the first real Linux run. Read from the code, 10 of the
  section's assertions should skip on a runner that is not root:
  - the pid-alone case, since a namespaced host leaves such a record, and the
    ps-prints-nothing case, which it leaves before ps is asked;
  - the failed fork and the second user, as here;
  - the empty symlink, which symlink(2) refuses on Linux;
  - five chflags cases.
- The 82-row projects/felix/qualification.tsv under the new runner; the gate
  runs it at the slot.
- bash 4+'s BASHPID path, outside CI.
