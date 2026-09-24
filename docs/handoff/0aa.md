## 0aa. Verified at session close, 2026-08-27 — nine fixes, and what finding them taught

Each line produced by a command. The letters on these sections are positional,
not alphabetical: newest first, directly under §0. `0aa` follows `0z` because
the scheme ran out, and dates are what actually order them.

| | |
|---|---|
| head | `b51d0ed` on `main`, CI `gate` **success** |
| deployed engine | **0.49.15** — `main` is at **0.49.17**, so two versions behind |
| suite | **831 assertions**, up from 765 at session start |
| open issues | **6** — #2, #28, #29, #31, #58, #77 |
| open PRs | **none** |

**Start here, and it is one command.** The machine runs 0.49.15; `main` carries
0.49.17. Asked of the CLI rather than the directory listing, and the live cache
differs from `main` in five files — #75 and #76 are merged and running nowhere.

```
cd /Users/a14808/Documents/Felix && git pull && ./engine/harness/felix install
```

The bootstrap trap that made this dangerous is gone: #55 landed at 0.49.9, so
the cached CLI no longer compares the cache with itself. Running it from the
checkout is still the habit worth keeping.

### What merged

Nine pull requests and one direct commit, all with CI green:

| | |
|---|---|
| #62 | `felix merge` cleared every escape channel on an unresolvable base |
| #64 | `felix install` from the deployed CLI compared the cache with itself |
| #68 | evidence, classify and `felix pr` all still answered on an unresolvable base |
| #69 | `cmd_bootstrap` resolved Felix's CI slug from the script's own directory |
| #70 | the marketplace was registered from the engine; its manifest is one level up |
| #71 | the suite could not tell an assertion that failed from one that never ran |
| #72 | a stacked branch inherited every path its base had already merged |
| #73 | the maintenance badge counted a variable nothing assigns; the deploy evidence rule required `.` |
| #75 | commands compared against a local `main` a worktree can never advance |
| #76 | `granted_by` was a string literal on the field that names where authority came from |

### The thing worth carrying, which is not any single fix

**Every one of these was an emptiness reported as an all-clear, and §8 already
names that family.** What this session adds is that the family is larger than it
looked and that its members hide inside each other.

Four came from one root — a value read from where the code *is* rather than from
what it was *asked about*. #64 and #69 read the script's own location; #62, #68,
#72 and #75 read the wrong base. Fixing one exposed the next, in every case.

**Three defects were found in the suite itself, not in the engine.** An L-25
guard that could not fail because the fixture was at its root commit; a `felix
pr` assertion previewing against an unborn `main` and matching the label `tier`
rather than any value; and two assertions that ran on macOS and silently did not
exist on Linux. The last needed a mechanism to find at all — #71 — and that
mechanism then found six more assertion names carrying machine-dependent values,
four of which embedded the credential samples they test.

**The check that matters is neutering the CALL SITE, not the library.** #69
nearly shipped with five library assertions passing while the caller stayed
broken — 806 green against the defect. Every fix after it was reverse-tested at
the caller. This is now a lesson and it should be standard.

### What is deliberately not built

- **#29 — routing.** Its own text says it is design rather than a patch, and
  there are now **four distinct causes** on one issue: the kickoff-play
  assumption, the recording-shape gap, a topic-vs-task keyword collision, and
  the router scoring quoted material. Two live misroutes from this session are
  recorded there: a merge sent to `systematic-debugging` because `gate` was the
  *object* of the sentence, and a pasted terminal transcript routed on
  `engine/harness/felix` appearing inside tool output. **Split it before
  designing**, or the design will be scoped to whichever cause is read first.
- **#77** — two checks whose *coverage* is too narrow rather than whose value is
  constant. Split out of #57 rather than fixed cheaply, because the cheap fix
  makes the check pass and leaves the coverage question open, which is the
  failure mode the whole family is about.
- **#57's six "completeness critic" entries** were never verified and are still
  listed there. Each needs the treatment the issue prescribes: construct the
  input that makes it fail, and run it.

### Standing, new this session

**`engine/harness/tests/assertions.tsv` must be re-recorded** by any change that
adds or removes assertions — `tests/run --record-assertions`. Otherwise the
suite fails naming what did not run. That is deliberate friction and the diff it
produces is the point: it says which assertions appeared and which vanished.

### Carried over, still unmeasured

**The follow-through baseline has still not been re-derived** against the
instrument #54 fixed, and no number should be produced before it is. One data
point from this session, directional only and not a baseline: Felix spoke on 2
of roughly 12 turns and was wrong both times; the other ten routed to the
default with no play and were correctly silent. Consistent with the ≈2%
precision in §0z, and nowhere near enough to settle anything.

**This bears on the gate §0z records.** The founder's condition for building the
deliberation layer was repeated confirmation that Felix has no role in routing.
Two more misroutes is not that confirmation — it is evidence the routing role is
real and currently mis-aimed, which is what the blind study already said. The
gate holds.

