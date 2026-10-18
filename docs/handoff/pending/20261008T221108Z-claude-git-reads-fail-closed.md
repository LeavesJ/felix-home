### 2026-10-08: a git read of the working tree that did not finish is unknown, never an answer

Found 2026-10-02 by the completeness review of
claude/table-readers-keep-unended-line, and not fixed there. Rebuilt and fixed
as a class on claude/git-reads-fail-closed.

**What git does.** Measured on git 2.54.0, macOS, bash 3.2.57.
- At a tracked named pipe, `git diff` and `git diff HEAD` print every path that
  sorts before the pipe, then exit 128 with "cannot hash". A mode-000 file does
  the same. A corrupt index stops every diff and `status` before they print.
- `git add -A`, `add -u`, `update-index` and `stash create` fail and stage
  nothing.
- `git hash-object` on a pipe, `--stdin-paths` included, blocks forever.
- `status`, `diff --name-only`, `ls-files` and `diff-index` exit 0 and list the
  pipe.
- An untracked pipe is invisible to all of them.
- `git diff base...HEAD` on a branch with no merge base exits 128 too.

Every engine caller sent stderr to /dev/null and kept whatever git had printed.

**Defects closed.** All reproduced on origin/main 6fe5f986 before the fix.
- `felix_tree_id`, with a pipe at projects/x/deny.tsv and an edit to src.txt,
  returned exactly the clean commit's id.
  - A green receipt for the clean tree then read `current` over the edit.
  - The Stop hook let the session go.
  - A corrupt index did the same, and `felix_tree_dirty` called it clean.
- On an unborn HEAD the id hashed index against tree only, so two different
  staged contents shared the id of an empty `git init`.
- An untracked name past ASCII (every macOS screenshot) never counted in the id.
- `felix_added_lines` returned nothing for the pipe tree.
  - felix_escapes and felix_classify_diff scanned an empty change.
  - `felix scope` said "In scope", `felix pr` gave a tier, and `felix merge`
    closed with "The rest escapes nothing".
- `secret-scan` exited 1 on an added key, and 0 once A.txt was a pipe.
  - It never scanned a key staged in a repository with no commit.
  - It skipped every file whose name git quoted, so a key in `clé.env` passed.
- `felix_pulse_backup` read a corrupt index as "nothing new to commit", then
  pushed and stamped the backup verified. Its `git add -A` failed over a pipe
  unread, and a mktemp failure in its gitlink check read as "no nested
  repository".
- `felix_discover_digest` hashed an unreadable file as an empty field.

**Mechanism.**
- One reader, `_felix_git_read VAR cmd...` in lib/resolve.sh.
  - It sets VAR to what git printed.
  - It returns 0 only when git exited 0 and a mark line (newline,
    `\037ok`) followed.
  - A bare trailing `.` was tried first. A partial diff ending in `+foo.`
    read as finished.
  - Its trailing-newline strip is a case-guarded loop. `${v%$'\n'}` on a string
    that does not end in one is quadratic in bash 3.2: 1.9 s of CPU on a 400 KB
    diff in the C locale, 39.8 s under UTF-8.
  - bin/secret-scan carries a twin, `_read`, since it sources no library.
- `felix_change_why root base` quotes git's own first error line, so each
  message names the real cause: a path git cannot hash, an index it cannot read,
  or no merge base. The first draft blamed a path for all three.
- `felix_tree_id` returns 2 with nothing printed for a tree it cannot read
  (1 still means not a repository). For a tree git reads, the bytes hashed are
  unchanged, so no receipt goes stale on deploy, except the two trees whose old
  id left something out: an unborn HEAD with something staged, and an untracked
  name past ASCII.
- `felix_tree_why` gives git's first error line for the Stop hold.
- Each caller says unknown in its own words:
  - Stop holds the way it holds any tree no receipt matches, naming the path.
  - SubagentStop nudges.
  - felix_escapes, classify and evidence emit an `unknown` row named
    CHANGED-PATHS or ADDED-LINES, with git's reason.
  - The receipt lists `tree`, `changed`, `risk` and `escapes` in `unknown`, and
    asks no founder.
  - felix_land_owed exits 2.
  - `felix scope`, `felix pr` and `felix classify` refuse, quoting git.
  - `felix merge` and `felix evidence` choose their closing paragraph by the
    row's subject, and merge keeps the escape paragraph beside it.
  - next.sh tells the reader to fix what git names.
  - secret-scan exits 2. Its listings are `ls-files -z` through a scratch file
    it removes, it reads bytes under LC_ALL=C (BSD sed exits 1 on a binary file
    under UTF-8), and it skips a symlink whose target is not a readable file.
  - pulse refuses the backup, with git's reason.
  - The digest returns nothing.
  - `felix gate` says on stderr that it wrote no receipt.
- Where a read fails for want of a commit, the read is not asked, and an empty
  answer stays right: an unborn HEAD, an orphan branch, or an empty base.

**Decided not to change, and why.**
- handoff.sh:444 and lifecycle.sh:109 hash only after `[ -f ]`. A failure
  reads "rewritten" or records an empty field.
- inventory-items and inventory-orphans: git lists no untracked pipe, a failed
  hash counts as differing, and fewer hashed than given is already counted.
- lessons.sh and route.sh read status or name-only for advice only.
- epoch.sh, exceptions.sh and verify.sh `_felix_hash` hash stdin, not the tree.
- qualify-run (`worktree add HEAD`), `merge-tree` and inventory's diff-index
  `--cached` read commits or the index only.
- felix_merge_checkout compares empty with empty, but an unknown tree is
  already refused as unverified by felix_verify_current.
- felix:1613's judge-itself check relies on the same refusal.
- templates/unattended.yml reads name-only and status, which do not fail on a
  pipe.
- lib/verify.sh is now about 544 lines, past the 500-line rule (462 on main).
  Not split here, because claude/no-diff-drivers-in-parsed-diffs is stacked on
  this branch and edits those exact functions. The split is handed on.

**Built as spec, blind assertions, fix, review, mutation.**
- Blind block: 101 assertions, written from the contract alone on origin/main.
  53 red there, 47 green by design (guards and controls), 1 skipped (a device
  node needs root).
- The blind author found three of the contract's "today" claims wrong:
  - R1's own example exits 1 on main, so only a pipe after a read line shows
    it.
  - P1 holds only with something staged.
  - S4's silence came from a matching receipt, not a failed id.
- One blind assertion amended after the review, with a dated note: T5 pinned
  main's id for an unborn HEAD with something staged, which was the defect H3.
- Adversarial review: H1 to H5, M1 to M3, L1 to L4. All fixed here but H5 and
  L3, which are handed on.
- Mutation: each of the fix's 59 hunks reverted to origin/main in turn, the
  blind block run against each. 29 killed, 4 could not stand alone (partial
  reverts of interleaved rewrites in resolve.sh), 26 survived. Of those, 14 are
  equivalent or redundant (h04, h05, h08, h09, h24, h25, h50, h52, h55 to h58,
  and h35 and h37, which back each other up on the same pipe), and 12 were real
  gaps (h07, h11, h12, h13, h14, h17, h33, h39, h41 to h44), now pinned.
- Post-review block, not blind: 29 assertions, 23 red on origin/main. The
  other 6 are guards: three against an earlier draft of the fix (H1, M2, L1),
  three paired with a red one.
- The whole block on 34a1bc3a: 130 passed, 0 failed, 1 skipped. On origin/main:
  53 passed, 77 failed.
- Differential sections, main vs fix, identical verdicts on 34a1bc3a: secret
  scanning 46/0, pulse 66/2, stop 94/1, receipt 46/7, next 6/0, epoch 66/0,
  land table 164/0, digest 44/0, prefix 225-3009 509/0. The pulse, stop and
  receipt failures are the same on both sides: they come from running one
  section without the sections before it.

**Not done here, handed on** (one follow-up task):
- H5: `diff --name-only` C-quotes names past ASCII, so path rules miss them.
- independence-scan reads `git grep`'s 128 as no leak, and `git grep` skips a
  tracked pipe with exit 0.
- memory-scan reads an ls-files failure as nothing leaked.
- `felix handoff` and SESSION_HANDOFF print "clean" when `git status` fails.
- felix_file_at's HEAD fallback for a non-regular path. The shell-open half is
  claude/project-writes-refuse-nonregular's.
- L3: felix_merge_blockers swallows felix_land_owed's exit 2.
- Splitting the tree identity out of lib/verify.sh.

**Landing.** Position 13 in the 2026-10-08 carrier queue, behind
claude/adopt-newline-before-append, which also changes felix cmd_gate,
hooks/stop and lib/resolve.sh. Merge main after that lands; record, red and
gate run on the head that lands, when the carrier gives the slot.
- Merging main after position 1 conflicts in felix cmd_gate and lib/resolve.sh
  (its gate-log ending, felix_end_line and felix_line_ended beside
  felix_count). Keep both sides.
- Once 3b (the fixture floor's git-proof lint) lands, every raw
  `( cd "$X" && git ... )` in this branch's tests/run block becomes `_fx_cd`.
- claude/no-diff-drivers-in-parsed-diffs (13b) is stacked on 34a1bc3a, at
  331a030b.
