## 0ai. Verified at session close, 2026-08-31 — Felix has a pulse, and three review rounds on it

Each line produced by a command. Newest first under §0.

| | |
|---|---|
| head | `57cf390` on `main` (#120), CI `gate` **success** |
| deployed engine | **0.49.35**, gate `installed ok`, full gate **pass** in the served checkout |
| suite | **1055 assertions**, from 975 |
| merged this session | #115, #116, #119, #120 — every one on green CI |
| open issues | **10** — #117 filed here |

**The diagnosis came first, and it is the map for what follows.** Asked where
Felix stands against its own documents, the answer was: the mechanical spine
is at Phase-1 ideal and battle-tested on itself; the judgment layers were
rebuilt this week to stop overclaiming and are honest but young; and the
autonomy layer is designed, guarded, and **switched off**. Five leverage
items came out of it — two are founder decisions (a watched unattended run,
the red-tier enforcement cost), one is time (B's 20-session clock), and two
were engineering. Both engineering items shipped.

### #86, and the wrong diagnosis it fired with

The `installed` check called a byte-identical deploy a drift over one
gitignored 4KB stray a claude-flow hook dropped mid-suite, then — because
the tree was a worktree — reported "structural: this tree cannot deploy",
advice already followed, with the one line naming the real cause suppressed
in a log. **This session repeated that message as a limit without reading
the check**, which is the mounted lesson about establishing who set a limit,
ignored in the moment. Both halves fixed at both sites (lib and the gate's
deliberately-independent inline copy): a path git ignores is residue, and
the worktree branch now prints the drift before its advice.

### `felix pulse` — the heartbeat, and what it cost to make safe

Backup and discovery no longer wait for a session to start. `felix pulse`
commits and pushes the memory repository, **verifies by re-reading the
remote**, reports maintenance due and stale discovery caches, and
`--install` writes a launchd agent daily at 09:07 — a grant a person makes,
never a default.

**Three adversarial review rounds before merge, 35 confirmed findings, nine
red.** The rounds are the story:

- Round 1 (10): an unattended committer could conclude a person's merge and
  push conflict markers as verified memory; could commit and publish an
  entire dotfiles-tracked `$HOME`; picked its push target alphabetically.
- Round 2 (15): the repairs tested *symptoms*. `merge --squash`,
  `cherry-pick -n` and `stash pop` conflicts leave an unmerged index and no
  state file, so all three walked straight through the merge guard. A failed
  commit still ended the run on "pushed and verified".
- Round 3 (10): **its red was a defect introduced by round two's own
  repair** — an awk that rebuilt the record and collapsed runs of whitespace,
  so `a b` and `a  b` were one key and a genuinely new nested repository was
  committed as a bare gitlink.

That progression is the finding worth keeping, and it is in `lessons.md`:
when each round of guards needs guards, the primitive is wrong rather than
the guards incomplete. Round three's fix **deleted machinery** — no
`.gitmodules` matching, no record-rebuilding awk, no reset-after-stage, a
scratch index so asking the question cannot destroy the answer — and that is
the version that held.

### The one the suite could not see

After deploying, `felix pulse` refused the real setup: *"memory sits inside a
repository that is not its own (`/Users/a14808/.felix`)"* — about the very
repository the backup has always used. **1054 assertions were green while
this was true.** Every fixture built only the shapes the rule already named,
so they agreed with it by construction. Fixed in #119 with a regression test
that builds the shipped layout from the outside. Second lesson recorded.

### Standing

- `tests/run --record-assertions` after any assertion change; **1055** on
  record.
- **#117 holds three known pulse limits, deliberately unfixed**: the
  verification asks about the local branch name rather than a
  differently-named upstream; `status --porcelain` can hide new memory from
  the dirtiness check; an exported `GIT_DIR` overrides every `git -C`. All
  three fail toward *not backing up while reporting success* — which is
  exactly what the new staleness alarm surfaces, and that is why they can
  wait.
- **The staleness alarm is the thing to watch.** It reads a stamp written
  only on verified push, says `never` when the pulse has run and never once
  succeeded, and session start speaks both. If it never appears, it is
  either working or broken in the one way nothing here can distinguish —
  check `felix pulse` output directly at least once.
- **Nothing schedules the pulse yet.** `felix pulse --install` is the grant
  and no session may make it. Until somebody runs it, the heartbeat only
  beats when a session types the command — which is the gap it was built to
  close, still open by one deliberate step.
- Reusing a squash-merged branch for a follow-up diverges from `main` and
  conflicts (#118, closed for this). Branch follow-ups off current `main`.

