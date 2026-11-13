### 0fg. 2026-10-28: the audit's first wave, nine batches combined (0.49.308)

**Engine 0.49.308 (branch `claude/audit-wave-1`, on origin/main 5c5d2208).**
This is the first landing of the 2026-10-23 audit (direction row 29; the
register is `docs/2026-10-24-audit-register.md`). It carries nine batches whose
finals went green alone, merged into one tree, plus the fixes that the combined
tree needed. Each batch's contract is in `docs/2026-10-24-audit-fixes/`, and
each was built red first from blind assertions, then reviewed, then given a
blind review round.

**Why one PR.** Each batch passed on its own branch from 69b51a61. Twenty-odd
batches touch the same driver, the same lander and the same session start, so
they are combined and checked together before the record. Landing them one by
one would re-gate every other engine PR each time (see
`landing-engine-prs-under-concurrency`).

**The batches.**
- **b00, room in the test driver.** `tests/run` was 497 lines against part
  1040's 500. Its comments move next to the code they explain, and part 1610
  holds the driver to its shape.
- **b02, the land tick never refuses or waits silently.** A refusal is held
  until its blocker can lift, the deploy-owed wait is said and aged each hour,
  and job rows (no pull request) are said once and then hourly.
- **b03, session start names what waits.** A paused lander, pull requests the
  lander has aged four hours (`waiting` rows, lib/green-wait.sh), decisions
  deferred overnight, and calls PreToolUse could not judge.
- **b04, status shows a stopped lander and hooks off.** `felix status` gains
  the land row (paused, not-loaded, not-ticking, from launchd and a heartbeat
  each tick writes) and the hooks row. Session start gets a landing badge, and
  `felix doctor` gets the gate, settings and hooks lines.
- **b05, the lander's install guard and its off-Mac alerts.**
  - `felix land` runs only where the home resolves the checkout's project
    (C013).
  - With no `launchctl` on PATH, `felix land --install` refuses and writes
    nothing (C042).
  - An alert is dispatched to `.github/workflows/felix-alert.yml`, so it comes
    from github-actions[bot] (founder decision 10-26), with enumerated text only
    and no free-text detail.
  - `felix status` gains the alerts row.
  - Until the founder merges the workflow file, alerts read
    `no-alert-workflow` and nothing reaches the phone.
- **b09, inventory speed and true owners.** The chip reader reads windows,
  not whole session files. SDK sessions are not the worktree's owner. An
  unreadable records root is unknown, not empty.
- **b21, README claims match the engine.** It also fixes `felix install`'s
  closing lines (C099).
- **b22, the snapshot builds and is tested.** Part 2050 runs
  snapshot-audit.sh and snapshot-scrub.sh on fixtures, and part 2051 runs
  snapshot.sh on a fixture home (C114). The scrub reports each halves and
  stand-in rewrite. Every owner a manifest declares is searched whole, not only
  beside its repository name (C039). Four dead acknowledgements are dropped,
  and four ordinary lines that the halves rule garbled are reworded (C113).
  Publishing the snapshot, which ships main's Stop fix to LeavesJ/Felix (C037),
  stays the founder's act. Section 7 of the b22 contract lists the three steps.
- **b23, the cloud kit says what is true.** `bin/secret-scan` no longer says
  ok over commits it never read when there is no base ref (C108). The cloud
  toolbox no longer claims to run what a local session runs while a pin lags
  the local install (C111).

**What combining changed.** The contract is
`docs/2026-10-24-audit-fixes/wave-1-combine.md`, and it wins over the batch
contracts where they differ.
- **Found by running every affected part under BWK awk and gawk** (S1-S6):
  - `felix status` is eight rows: settings, schedule, pulse, reach, gate,
    land, hooks, alerts. Parts 1100, 1690 and 1720 pin eight.
  - A `waiting` row no longer lifts a held refusal. b02's `_gt_held` reads
    past it, as `_gt_last` does.
  - A paused lander is said once at session start, by b04's badge, which
    gains b03's "felix land --resume ends the pause." (pin 1690 A32b).
  - 1690's fixture home resolves its project, as b05's home-only lander
    requires.
  - The tick's lock and watchdog move unchanged into `lib/green-lock.sh`, so
    green-tick.sh stays under 500 lines (1280 G1).
  - In the trampoline's `owed()`, b05's alert carries b02's aged detail,
    inside b02's hourly guard.
- **Found by a four-lens review of the combined tree, each finding verified**
  (W1-W5), fixed by C1-C8 and pinned by the new blind part 2120:
  - **C1.** A hand pause (`felix land --pause R`) is the pause event, said
    once. Its alert detail drops b02's `; by session` suffix, so the tick's
    hourly paused row for the same reason sends nothing more. Part 1720's
    paused-event assertions are restated for this.
  - **C2, C5.** `resumed`, `installed` and `uninstalled` alert nothing, and
    only kinds with a sentence alert. Before this, each wrote a false
    `failed` record.
  - **C3.** A `waiting` row reaches the phone: "A green pull request has waited
    more than four hours to land."
  - **C4.** b03's two "could not age what waits" rows are kind `unaged`, with
    their own sentence. `stuck` now means the lock only.
  - **C6, C7.** In a checkout outside the home, the land row reads `none` (no
    lander, and no advice to install one b05 refuses) or `not-home` when a
    plist was left behind, naming `felix land --uninstall`. Session start
    names no paused lander there.

**Not in this wave.**
- Founder drafts after this lands, one CI run each: b17 (commission grant) and
  b10 (escape rows). b16 (deny floor on every tool) follows after its round 3.
  One workflows draft is also owed: `felix-alert.yml` with b01's `gate.yml`
  timeouts.
- Held for a round-3 fix through a blind author, each from a security review
  of its review-round commit:
  - b11: evidence set aside under any vendor/ directory.
  - b16: terminal tools judged by exact name only.
  - b08: gate.sh's JSON reader passes escapes and duplicate keys.
  - b12: the remote_match check resolves its project from origin's own URL.
- Wave 2 (`claude/audit-wave-2`) holds b07, b06 and b14 so far. It takes this
  branch's tip once this lands.
- Owed to the wave 2 combine round. These are four low findings from the fix
  round's review; none of them is live until `felix-alert.yml` is merged.
  - With two or more waiting pull requests, B8 compares only the newest
    dispatched record, so each is sent again daily.
  - A second hand pause with the same reason after a resume does not reach the
    phone.
  - 1720's restated A26 and A27 no longer have a tick meet a hanging gh.
  - A31's wording still names the tick.

**Found while combining.** A part run killed at its time limit can leave its
nested `-j` fixture runs behind. Two such groups from parts 1292 and 1293 ran
3.5 hours with parent pid 1. They were stopped by explicit pid. Owed: those
parts end their nested runs on every way out. The details are in the audit
folder's `combine-followups.md` in the memory root.
