### 2026-11-06: felix cost makes one reading at a time and serves every caller from it (load slice 0, 0.49.329)

**Why.** The founder, 2026-11-06: "as we're developing and making felix more
sophisticated, think about optimization. Overloading issue should easily be
managed by a dynamic optimization issue". The design is
`docs/2026-11-06-load-governor-design.md` (PDF in `docs/pdf/`). It has three
slices: `felix cost` first, then a governor that admits work against
measured headroom, then a cap derived from its own records. Its section 8
proposed a direction row, and he said yes the same day.

**Founder decision, binding from this section.** On 2026-11-06 he was asked
"Add the proposed load row to docs/direction.md §4?" and answered "Yes, add
it". The row, word for word as section 8 proposed it: **Load on this Mac is
managed, not capped.** Heavy Felix work asks for a slot and is admitted
against measured headroom: the load against the cores, and memory pressure.
No fixed count is set in advance. The founder's own commands are never gated.
Background work gives way first and runs at background QoS. Every job runs as
a process group with a deadline under a supervisor, so a timeout never orphans
work. Every admission decision is recorded with the load it saw, and caps are
derived from those records: the concurrency at which throughput stops rising.
No new fixed concurrency cap is added to Felix. Under `docs/direction.md` §10
it binds from this section. The fold into §4, as row 41, waits for his merge
in draft #489, which is stacked on #481's fold of rows 34 to 40.

**What landed (branch `claude/load-governor-cost`).** Slice 0, built to the
contract's clauses C1 to C13 (design section 5).
- `lib/cost.sh`: the scan and the totals are now two awk stages, cut at
  `settle()`.
  - Stage 1's rows are a reading.
  - Stage 2 prints every view of a window from one reading. It prints
    nothing, status 3, when the rows do not end with stage 1's E row.
  - New: `--max-age SECONDS` and `FELIX_COST_DEADLINE`.
- `lib/cost-cache.sh`, new.
  - **Where readings live:** `$HOME/.cache/felix/cost`, not under
    `~/.felix`, which the pulse adds whole.
  - **When a reading is current:** while no `*.jsonl` and no directory under
    the root has changed status since the reading's scan began, and no
    `*.jsonl` is a dangling link.
  - **One scan at a time:** behind a kernel flock that a perl supervisor
    holds for the run's life. The supervisor runs the scan in its own process
    group, kills the group at the deadline and whatever of it is left at the
    end, and holds none of the caller's streams.
  - **No caller waits behind another's run:** it gets the last reading
    (`cover served last`) or unknown (`cover served none`).
- Part 1075, written blind from the contract. Part 1060's creates-nothing
  check now excludes the cache directory, which is C12's one exception.

**Review** (the first-build review: 13 findings, each verified). Fixed:
- **Blocker, a lost CHLD.** On macOS a CHLD whose action is the default is
  discarded even while blocked. A scan that ended before the handler was set
  left the supervisor waiting for good, holding the lock. Reproduced 3 in
  300 at load 49. The handler is now set before the fork, and the child is
  reaped by WNOHANG once KILL has gone out.
- **Major, coarse filesystems.** A root on a filesystem with coarse times
  (HFS+, FAT) let a change made just after the scan began pass as "before
  it". Reproduced on HFS+. When the root's own ctime has no fraction of a
  second, the reading is now dated two seconds before its scan's second.
  APFS never takes that branch.
- **Minor, the rest:**
  - the lock file stamps the scan start, and the rows are held in memory, so
    while a scan runs the directory holds no file but `lock` and the
    readings;
  - temporary files are removed on any failed status;
  - the supervisor closes descriptors 3 to 255, and ignores TSTP as well as
    INT, QUIT and HUP;
  - a reading that cannot be written falls back to the inline scan;
  - the root is resolved again before the write, and nothing is written if
    it has moved;
  - pruning is by minutes, 14 days;
  - an empty `FELIX_COST_DEADLINE` means the default.

**Measured, 2026-11-06** (child CPU by getrusage, at load 45 to 160 on 18
cores):
- **Before.** One `felix cost --week --tsv` took 15.7 s of CPU over 140
  transcripts (1236 MB), 18.7 hours into the week. grep was 9.3 s of it.
- **The mod's two defects, reproduced.**
  - Its store lock is check-then-set: three sessions scanned in one second
    at 07:11Z.
  - Its timeout kills `felix` alone. A 3 s execFile timeout left the
    pipeline's subshell, grep and awk at ppid 1, still scanning 13 s later.
- **The freshness check** walks the whole records root: 0.14 s of CPU over
  11,567 entries.

**Known limits** (design section 5):
- without perl, nothing is coalesced;
- a root find cannot read cleanly is never current;
- any directory change under the root means a rescan;
- the inline fallback has no deadline;
- a supervisor killed with KILL leaves its scan without a deadline;
- a network filesystem whose clock runs behind this Mac's can pass a stale
  reading as current;
- a person's own call still waits for a full scan (slice 0b);
- there is no QoS until slice 1.

**The dash mod** is not in this repository. Its change is built and tested in
the dev copy `~/.claude/dev-mods/c80faf4c-3940-4f47-b97d-f980502a56de/dash`.
- `readSpend` calls `felix cost --week --tsv --max-age 840` from every
  session.
- It keeps the value shown on a timeout, or on `served none`.
- While the deployed engine refuses `--max-age`, it falls back to the old
  store-guarded call.

Install it over `~/.claude/mods/dash` once 0.49.329 is deployed.

**Next.** Slice 1, the governor, report-only first: `lib/load.sh`,
`felix load`, rows in `$FELIX_MEMORY/load.tsv`, and the existing slot holders
calling it.
