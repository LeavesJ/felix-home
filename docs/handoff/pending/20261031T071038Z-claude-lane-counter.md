### 2026-10-31: felix lane counts the capability lane's share of engine landings (slice 0, 0.49.319)

**What landed (branch `claude/lane-counter`).** Slice 0 of the lane design
(`docs/2026-10-29-capability-lane-first-slices-design.md` §6, built to the
Contracts of `docs/2026-10-29-lane-slice-0-plan.md`).
- Two per-project tables, `lanes.tsv` and `lane-next.tsv`, each a new file
  with one new `schemas.tsv` row. felix-home's `projects/felix/` commits one
  lane, `capability ^engine/ 1/2 14`, and its first open item.
- `lib/lane.sh`: the count, read-only and offline. It reads the tables as the
  Felix home has them committed, and the first-parent history of the
  checkout's `refs/remotes/origin/main` as last fetched. A landing is a lane
  landing when its commits carry a whole `Felix-Lane: <lane>` line.
  `lib/lane-resolve.sh`: the lane's own check of the project resolution, and
  its sentence for a directory no project governs.
- Four surfaces:
  - `felix lane [--tsv]`: thirteen columns per lane;
  - `felix status`: a tenth row, `lane`, last;
  - session start: a paragraph for a short, zero or idle lane in the
    project's own checkout, and ` · lane: 0 in <W> days` on the screen line
    when the first lane reads zero or idle;
  - `felix pulse`: one line per lane of the home's own project.

**Decisions** are the plan's C12, items 1 to 22. Design §11 items 44 to 50
came from reviews of the build: a security review, then three adversarial
ones, the last in four rounds.
- 44: the paragraph and the token show only in the project's own checkout.
- 45: a count that cannot finish reads unknown on every surface, and
  `felix lane` exits 1. A scratch directory that cannot be made is R10. A
  next text that is exactly none or unknown is a stated limit. One day reads
  `1 day`.
- 46: the shared resolver that `felix merge` and `felix land` run stays as
  main has it. The lane checks the resolution itself, a found project as it
  checks a miss.
- 47: the table validator, a verifier the gate runs, stays as main has it
  too. The lane takes anything its check leaves on stderr as a check that
  did not finish. A `.felix` marker that cannot be opened has the lane's own
  sentence.
- 48: `felix lane` says a miss from what its own check read, in main's
  words, and runs neither `resolve_or_die` nor `felix_binding_broken`, which
  can append to `bindings.tsv`.
- 49: status's rows before the lane row take the shared resolver's answer,
  and only the lane row reads the lane's. `felix land`'s deploy check runs
  the hook and the gate as a test of the installed engine; the exclusions
  mean the code that decides, and the lane's text never stands alone in the
  hook's output.
- 50: round 4 was the last. From it on, only a regression of the previous
  round's fixes or a wrong answer in normal use is fixed, and anything else
  is a stated limit and a follow-up. It found neither: two limits in the
  lane's own code (below), and `tests/run`'s arithmetic: this slice adds
  nine lines, which leaves slices 1 and 2 fourteen, not fifteen.

**Measured** (audits in `~/.felix/memory/felix/audits/2026-10-30-lane-slice-0/`):
- Real data, felix-home at `e54e31f3` with the clock at that commit:
  `capability zero 0 of 18 in 14 days, target 1/2`. It is the same row byte
  for byte on the first build, the second final and this one.
- The 60-day hand check: the counter agrees with an independent
  classification of the same commits on 60 of 60 days.
- CPU, user plus sys, median of three runs: `felix lane --tsv` takes 1.04 s
  over 18 landings in a 14-day window (1.07 s on both earlier builds) and
  0.86 s in a one-day window; the session-start hook takes 0.77 s with a
  `lanes.tsv` and 0.81 s without one.

**Known limits:**
- Every surface other than the lane's reads a project resolution that did
  not finish as no project. That includes `felix merge`, `felix land` and
  status's other rows. The fix belongs to the shared resolver, outside the
  lane.
- The lane's check reads the GitHub slug through `_felix_remote_slug`,
  unchecked, as the resolver does. No lane file calls into `lib/own.sh`.
- The table validator's own reads are unchecked on main. A signal that ends
  a read inside the check and leaves nothing on stderr can still be taken
  for its verdict.
- A broken Felix home pointer, and a remembered binding whose
  `project.json` was renamed, are said as the layout the lane's check read.
  A project directory whose name ends in LF reads as a resolution that did
  not finish.
- Under an open-file limit low enough that felix's own load cannot save a
  descriptor, every subcommand loses its stdout, `felix which` on main too.
- `lib/own.sh` reads git under the caller's `GIT_DIR`, so the session-start
  half of the first review's F2 stays open there.
- A count that a signal ends leaves its `felix-lane.*` scratch directory, and
  nothing reads it again (C2).
- A process with more than nineteen of descriptors 10 to 31 open when felix
  starts reads as a count that did not finish on every surface, though the
  count could finish (V3R4-F1). Follow-up: `_lane_room` counts free
  descriptors up to the soft limit and stops at three.
- A TAB or LF in a path a reason names breaks `felix lane --tsv`'s line, and
  an LF in the home's path makes the pulse print and record a lane line no
  row produced (V3R4-F2). Follow-up: clean column 13 as `_felix_status_row`
  cleans a detail.

**Found on main, outside the lane:**
- Part 1860's `_n12timed` (lines 46 to 50) ends the timed bash on its alarm
  and not the subshell it forked, so an engine that hangs under test leaves
  that child spinning: three of block b12's ran at full CPU for about 12
  hours on 2026-10-30.
- A table check whose own read does not finish can return a verdict on main
  (R2-F4, R2-F9), so the gate's schema check can pass on such a read. This
  branch's 33875863 fixed it before `lib/table.sh` went back to main's
  bytes; it is the start of a PR of its own.
- Under an open-file limit low enough that felix's load cannot save a
  descriptor, main's session-start hook can leave a subshell whose stdout is
  its own stdin pipe, so its `cat` never sees end of file and it never
  exits. The reviews' sweeps left such hooks from main's engine, from a copy
  without `lib/lane.sh` and from the branch alike; 32 processes were stopped
  by pid on 2026-10-30.
- Part 2210 line 588 runs `head -c 0`, which BSD head refuses on stderr; the
  assertion's result does not change.

**Next.** Slice 1 (`felix situations --change`, branch
`claude/lane-situations-owed`) moves `lanes.tsv` to `1/4` and `lane-next.tsv`
on to slice 2, pending the direction fold. `tests/run` has 486 lines here, so
slices 1 and 2 have 14 between them while `main` stays at 477; each counts
again at its start. Their plans take the review budget: the first-build
review and at most two fault-injection rounds, probes limited to the slice's
own new reads, and fault classes in shared code routed to the trust plane.
