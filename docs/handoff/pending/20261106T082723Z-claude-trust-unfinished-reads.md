### 2026-11-06: the shared resolver, the CLI, the table check and the status rows say could not tell when a read did not finish (0.49.329)

**What landed (branch `claude/trust-unfinished-reads`).** This is step 1 of the trust-plane verification design
(`~/.felix/memory/felix/designs/2026-10-31-trust-plane-verification/`, §10). It was built red-first from the cells
that fail in the replay's P2 case. The spec, review records and logs are in
`~/.felix/memory/felix/audits/2026-10-31-trust-plane-replay/step1/`.

- **`lib/resolve.sh`.** Every read the project resolution stands on now goes through `felix_capture`
  (lib/detect.sh), which is loaded lazily from beside the file. A read that did not finish gives status 2, never
  "no project". `_felix_resolve_remote` gives 3, because its 2 already means a tie. `felix_repo_root`,
  `_felix_remote_slug` and `felix_binding_broken` follow the same rule. The origin URL is taken only from a git that
  exited 0.
- **`felix`.** Where a read did not finish, `resolve_or_die` and `felix which` used to say no project governs. They
  now refuse with cmd_lane's sentence: "the project that governs <PWD> could not be resolved: a read it stands on did
  not finish".
- **`lib/table.sh`.** `felix_table_check` says cannot-examine (2) when one of its own reads did not finish. This
  fixes R2-F4 and R2-F9; the prior art is 33875863. Its number and byte tests now run in the shell.
- **`lib/status.sh`.** The project rows say unknown when the resolution or the checkout root did not finish.
- **`hooks/stop`.** When lib/detect.sh is missing, the resolver's 2 holds the stop, as main held it. This covers an
  unflagged stop, and a flagged stop in another hook's chain or in a night. Felix's own chain still ends.
- **`hooks/pre-tool`.** It now loads lib/detect.sh. When that does not load, it takes the path every missing library
  takes: the call is allowed and recorded in hook-faults.log. Before this, the resolver's 2 would have read as
  nothing governs, which turns the deny rows off with nothing said.
- **Tests.** Parts 2170-2174 were written blind and red-first, P1-P50, with `tests/lib/trust-probes.sh`.

**Measured.**
- **Red on main.** At 1fca9559, the blind parts as first written fail 176 of their 255 assertions under bwk. Each
  failure is a defect the spec names.
- **P2, harness q5.** This was run at 00ee0d09; the later commits touch only the two hooks, which P2 does not sweep.
  - The four step-1 surfaces go from 132 violations to 36: resolve 47 to 11, which 68 to 20, table 12 to 0, and
    slug 5 to 5.
  - The 36 that remain are below, under the stated limits and the follow-ups. In short: own.sh's `tr` (15 cells, L2),
    git exiting 128 or a failed cd at the origin read, which R5 counts as a finished "no origin" (11), and the CLI's
    load-time `dirname` at felix:121 (10).
  - deploy-owed (29), merge-blockers (65) and obligations (23) are unchanged.
- **Clean runs** give main's bytes on every layout where every read finishes.
- **Risk row 47** counts 24, against 23 at base.
- **Review.** Two capped rounds, with contract and fault lenses and an adversarial verifier. Of 14 findings, 3 were
  confirmed, then 1 of 3. Each confirmed finding went back to the blind author as an assertion before it was fixed.
  The session's own review of the fix rounds found P50, which is fixed here red-first.

**Decisions.** Three places depart from the spec's wording, each to keep an existing part green:
- **D1.** A non-empty relative `pwd -P` keeps status 0 and lets git decide (part 1860 A79-A80).
- **D2.** felix_json_str's `sed | head -1` stays, with both statuses read (part 2220 V3R1-F1).
- **D3.** The table's NUL count must be at most the file's size.

The table guards T3 and T4 were not applied: those cells are now read in the shell, and the guards would change
main's clean output.

**Stated limits.**
- **L1.** A marker or remote_match reader that exits 0 with nothing reads as empty.
- **L2.** own.sh's own `tr` failing reads as not GitHub.
- **L3.** An unreadable `~/.felix-home` reads as empty.
- **A night with a missing lib/detect.sh.** Suppose Felix held a night's previous stop with the whole engine, and
  lib/detect.sh then went missing. That night ends quietly at its flagged stop, because without the project it
  cannot be told from Felix's own chain.

**Follow-ups.**
- **Spec section 3's callers.** Each of these reads a 2 from a read fault as it read a 1:
  - pre-tool :130 and :135;
  - stop :113, :185 and :194;
  - user-prompt, subagent-start, subagent-stop and session-end;
  - session-start;
  - status-land, waiting, pulse and pr-status;
  - exceptions.sh's `_felix_remote_slug`;
  - bin/schema-check's own reads;
  - W1, the bindings record's `$(date)`.

  The pre-tool and stop ones come next.
- **R5's finished statuses.** Inside a known root, git exiting 128 and a failed cd are not a finished "no origin".
  This needs a decision on the spec first.
- **The lane's `_lane_origin`** takes the URL from a git that exited 2 or 128 (lane files were out of bounds).
- **own.sh's L2.**
- **The CLI's load-time reads,** felix:121 and :236.

**Gate.** `felix gate` was run on this branch's final tree. Its result is in the pull request's body.
