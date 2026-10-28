### 2026-10-28: the audit's second wave, eight batches combined (0.49.309)

**Engine 0.49.309 (branch `claude/audit-wave-2`, on origin/main 78f0268f).**
The second landing of the 2026-10-23 audit (direction row 29; the register is
`docs/2026-10-24-audit-register.md`), after wave 1 (#469, 78f0268f, 0.49.308).
It carries eight batches whose finals were green, or red only on part 1010's
two record checks, b11's engine half among them, and one fix found live on
10-28 (`wave-2-docs.md`), with contracts in `docs/2026-10-24-audit-fixes/`.
Each was built red first from blind assertions, reviewed, and given a blind
review round; b11 and b12 had a round 3 as well.

**Why one PR.** These batches share session start, `felix`, lib/status.sh,
lib/route.sh, lib/monitor.sh, lib/detect.sh, README.md and `tests/run`, so
they are combined and checked together before the record. Landing them one by
one would stale every other open engine PR's version and red.tsv at each merge
(see `landing-engine-prs-under-concurrency`). Wave 2 took wave 1's gated tip
(000a9636) at 444a707e, then main after #469 (cec500e7, tree unchanged).
The escape scan found nothing once b11's founder half left (e503da40).

**The batches.**
- **b06, pulse and discovery promise nothing that cannot happen.**
  - The discovery refresh records whether it ran, ran nothing or failed; the
    pulse says which on a stale cache, and session start says once when it ran
    nothing or failed. A lock over 30 minutes old is broken (B1-B9). The cache
    stamp hashes what writes the rows, not the version, so a release that
    leaves those files alone no longer makes every cache read as not current
    (C055, B10).
  - The memory backup leaves out a nested repository or a file that gained a
    credential, names it, and backs up the rest unless a person staged a
    selection by hand. It commits exactly the tree it scanned, and backs up
    nothing when the scan cannot run (B12-B17, B28-B30). The pulse row says
    when the verified copy is on this disk (B19, B20). Session start says on
    day one that a pulse left memory out, and tells a cloud session that
    nothing backs up its memory from there (B21, B22). says.log and
    routes.log redact credential shapes (B23-B26).
- **b07, the Stop hook and the cloud session never let go silently.**
  - When project.json cannot be read, the stop says `Felix could not judge
    this stop` and writes an `unjudged` row, and session start says
    `Gate: unknown`, not `none declared`. When a library the stop needs is
    missing, the stop says the same and names the library (B1-B6).
  - In a cloud session the hold names the gate by path, with `nohup`, and a
    later debt stop says the record ends with the VM (B8-B10). A prompt hook
    that is cut off is said once at the next stop (C102, B13-B16). A skill used
    under its bare name counts as used (C106, B19-B21). Cloud provision says
    what did not arrive, inside one time budget, 90 s by default (C107,
    B22-B27).
- **b11's engine half, the evidence policy gives true verdicts.**
  - A row that cannot compile or does not split into four cells, or an
    unreadable evidence.tsv, reads `unknown` and `not judged`, never n/a.
    `felix evidence` exits 1 and `felix merge` refuses (B1-B8).
  - A judged command that discards its status, such as `pytest || true`, is
    refused (C074, B14-B16). `felix review --pass` needs `--in` naming a
    separate work tree at the same commit (C078, B17-B19).
  - Round 3: only what project.json declares in `evidence_vendored`, or root
    `vendor/` beside a root go.mod, is set aside, and the verdict says how
    many paths (B11R3-1 to B11R3-8). Its section 6 leaves the founder a call:
    a project's first `evidence_vendored` line escapes nothing today.
- **b12, the judge's base and the binding read what is committed.**
  - A grant at `refs/remotes/origin/main` is not honoured when the ref is
    symbolic, origin is missing, a fetch refspec of another remote or another
    branch writes it (or none of origin's does), origin's URL does not name
    the `remote_match`, or its newest reflog entry is not a fetch, pull, clone
    or push of its commit (C009, B1-B8). Round 3: the project whose
    `remote_match` origin must name is the one the `.felix` marker names, or
    the project itself with no marker, never one the URL picks (B12R3-1 to
    B12R3-7).
  - With no marker, binding by remote is exact on GitHub and anchored
    elsewhere; a tie binds nothing and is reported (C046, B21-B24, B39), as is
    a remote binding that went missing (C031, B25-B30). `CLAUDE_CONFIG_DIR`
    reaches the plugin, skill and config readers in resolve.sh, ready.sh,
    stack.sh, commission-provider.sh, toolbox.sh, coverage.sh and
    bin/deploy-check; `felix`, discover.sh, green-tick.sh and green-install.sh
    still read `$HOME/.claude` (C098, B10-B13). The root walk ends, and stale
    output never reaches its answer (C061, B31-B34).
- **b13, the felix CLI trusts what it should and binds what it says.**
  - In Felix's own checkout, `felix merge` copies main's engine out of git and
    hands it the verdict, so the verdict is main's, not the branch's. A branch
    that edits its own `felix merge` so it no longer hands off, run from that
    branch, still judges itself, as the README now says (C067, C063, B1-B15).
  - `felix new` does not rebind a root whose marker or origin already binds an
    existing project (C116), says to commit `.felix`, keeps credentials out of
    `remote_match`, and says when the checkout will not run unattended (C117,
    B16-B22). `felix install` refuses untracked or ignored files under
    `engine/`, and says when git cannot tell (C064, B23-B26).
- **b14, lessons, handoff and maintenance records stay true.** A dated lesson
  mounts with its first sentence (C026). `felix handoff` says when it does not
  know whether the tree is clean (C058). The seeded graphify row is not due in
  a repository with no graph (C118). C105 is not fixed (section 6).
- **b15, bootstrap protects the right branch with a passable gate.** It
  protects the default branch GitHub reports, never the checked-out one, and
  holds protection back while the workflow CI runs cannot resolve the project.
  A failed protection read is unknown, and on a branch already protected
  `gate` is added with one POST, never a whole-body PUT. `--yes` exits 1 after
  a `FAILED` line, an unread row or a hold, but not while it waits for the
  workflow to reach the default branch (C040, C095).
- **b18, the ledger reads dead hooks, and iCloud copies are named.** A session
  whose PostToolUse recorded fewer calls than runs folds as unknown, not zero,
  and an unknown row is not evidence of disuse (C101). `felix status` gains an
  `icloud` row: names shaped like iCloud's copies, and whether the home sits
  in a synced folder (C052).
- **wave-2-docs, documentation and presentations are not a frontend.** A file
  under a `docs`, `doc`, `documentation`, `deck`, `decks` or `slides`
  directory, in any case, is not a web asset (F1). Nothing else in detection
  changes, except that outside git a symlinked root is now read through its
  link (F2, F2e, F2f). Felix's own tree detects no frontend (F3, part 2160).

**What combining changed.**
- b04 and b07 both spoke for an unreadable project.json in the session-start
  line (`no gate` and `gate unknown`). It now says `gate unknown` alone
  (5e3e87aa), pinned by 1750 A25b (7a07bedd, red on the naive merge).
- b18's `icloud` row follows b05's `alerts`, so `felix status` has nine rows.
  1690 A1, A2 and 1720 A33 are restated for nine (1f1289b3) and keep wave 1's
  C8 citation (444a707e). status.sh is 490 lines; the next row needs a split.
- Part 1030's lint caught b11 reading evidence.tsv's opted-in names with no
  `-f` guard; e91eb283 guards it (c166fabb). Since wave 1's record found a lint
  no combine check had run, the rule is that every combine check adds the
  whole-engine lint parts, whatever a batch touched.
- `tests/run` conflicted on part lines at every batch merge (b06, b07, b14,
  b18, b15, b11, b13 and b12's round 3), settled by part number.

**The docs fix and the commission.**
- On 10-28 #467 landed a deck whose `deck.css`, with two documentation files,
  made Felix's own tree read as a frontend.
- At 07:28:04Z a session start in the home adopted `frontend` into the
  commission tables, uncommitted: `capabilities`, a stack.tsv row and a
  header-only setup.tsv. The policy hash moved off the founder's grant
  (2798bb0f), the receipt went stale, and `felix merge` refused #468 and #469.
  Session start adopts in any checkout of the home whose origin is the home's
  own, worktrees included; a worktree's did it again at 19:20:47Z.
- The founder re-commissioned (receipt 19:41Z), and #469 landed.
- Once this lands, the three adopted files in the home are reverted, so the
  tables match 2798bb0f, which the grant was stamped over. The next session
  start in the home then runs `felix commission` unattended under that grant
  and logs the outcome in `state/commission/felix.bg.log`
  (`felix_commission_resume_bg`, lib/own.sh).

**Not in this wave.**
- Wave 3: `wave-2-combine.md`'s notifier fixes on `claude/audit-wave-2-lows`
  (part 2140), none live until `felix-alert.yml` merges; and b08's half that
  lands on green (C003 and C110), whose cloud check is still in review rounds.
- Founder drafts:
  - b10 (escape rows), b16 (deny floor on every tool), b17 (commission grant);
  - b19, which must carry wave-2-docs F1 into its counting before it lands;
  - b01, whole; b30, after a PR that adds its risk.tsv row;
  - b11's template half (templates/evidence.tsv, part 1831, its driver line);
  - b08's receipt half (tests/receipt.sh, part 1780);
  - b12's deny rows for remote-tracking refs and `git config` of remote keys
    (its section 7);
  - the workflows PR: `felix-alert.yml` with b01's `gate.yml` timeouts.

**Found while combining.** The first, second and fourth are each owed as a
batch of its own. Lows the reviews of b11, b12 and wave-2-docs left are in the
memory root's `audits/2026-10-24-audit-fixes/combine-followups.md`.
- Adoption moves policy unasked: any detection change or new file pattern can
  stale the commission and stop all landing, with no decline (wave-2-docs
  section 5).
- projects/felix/gate.sh is 652 lines on main and 817 at b08's tip
  (9801aa12). Moving the cloud check into its own file needs its own risk
  row, a founder stop.
- At wave 1's gate the secret scan flagged a quoted `${{ github.token }}`.
  The founder's `felix-alert.yml` must write it in block style, unquoted, as
  gate.yml does, or its PR's scan goes red.
- Detection's `git ls-files` quotes non-ASCII paths, so such assets never
  count in the git listing (they do in the fallback). The remedy named is
  `git -c core.quotePath=false`.
