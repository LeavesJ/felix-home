## 0bb. Verified at session close, 2026-09-13 (afternoon) — #233 built, and a review reversed its central decision before it merged

| | |
|---|---|
| open at close, merged later the same session | **#236**, tier **red** (`lib/qualify.sh`); red is advice and no channel fired, so it was Felix's to merge — see §0bc |
| suite on the branch | **2096** passed, 0 failed; 39 assertions added, all authored blind |
| the same suite against main's engine | 19 failed, each on behaviour #236 adds |
| gate on the branch | every check ok except `installed`, the structural red of a worktree whose engine is not the deployed one |
| deployed engine | **0.49.111**, unchanged |

**A fourth verdict, and the exit status is read strictly.** A qualification
row may carry a sixth column, a premise, run in the worktree of HEAD before the
mutation. 0 applies the control. 1 makes it `inapplicable` and nothing runs.
Anything else is `unrunnable`, because reading 2 or 127 as "absent" is how a
typo in a premise would retire its control without anybody deciding to. The two
independence controls that plant `elenchus` and `veldra` carry premises naming
the project their own mutation writes.

**The first draft did not refuse, and it was wrong.** It named a checker whose
every fail-expecting control was inapplicable as "never shown failing in this
checkout" and let `felix qualify --gate` exit 0, reasoning from the ratchet: a
checker with no rows is not red. Four of five independent reviewers flagged it
as invariant 5 broken inside the one check that exists to enforce invariant 5,
and the reasoning did not transfer — rows that were written are a claim that the
checker catches something. It refuses now. The dilemma that had made refusal
look wrong (the public checkout would go red) dissolved with a better control
rather than a looser verdict: two independence rows that **stage their own
premise**, creating a governed project HEAD lacks and leaking its name, so they
apply in every checkout. Measured in a clone of this repository with the other
two projects removed — a stand-in for the public snapshot, not the snapshot —
on #236's exact files: independence four met and two n/a, 36 of 38 met overall,
`--gate` exit 0. Worth carrying
forward as a shape: **a verdict that stops something failing needs, beside it,
a check that something is still shown failing.**

**Blind, twice, with one lapse the author reported itself.** The 39 assertions
came from a subagent given the behaviour in prose and forbidden the
implementation, revised once when the refusal was added. The two self-staged
rows came from another, forbidden `bin/`. A zsh word-splitting slip in its
verification loop ran `git grep` for an empty string over `bin/`, and by its own
report what reached it was the first ten lines of `deploy-check` and none of
`independence-scan`. It said so unprompted, and the 2.7MB capture of that output was deleted unread.

**The gate's `qualified` line in a worktree is about the home, not the
branch.** It printed 36 controls met; the branch's table has 38. The deployed
engine resolves project tables through `~/.felix-home`, which is the home at
#232. That is lessons 2026-09-02 and 2026-09-03 exactly, and it was caught by
reading a count rather than a word. The 38 were run with the branch's engine and
table under `FELIX_HOME=$PWD` on `felix qualify --gate` alone, never on the
gate, because that override sends the gate receipt to a home nothing reads.

**Why the session opened with discover and promote due.** #235 recorded both,
but `felix maintenance` reads the home's log, and the home has sat at #232: it
holds two run records (`lessons`, `graphify`, 2026-09-12) written there and
never committed, and #235 appended after them on a branch, so the home cannot
fast-forward. #236 carries the two records in epoch order; the home's working
copy is byte-identical to the first sixteen lines of the result. After merging:
`git checkout -- projects/felix/maintenance.log`, `git pull --ff-only`,
`engine/harness/felix install`.

**The code-review plugin was reached for.** The ledger had it pointed at in 83
of 86 sessions and never used. It ran here adapted — no PR existed yet, so no
eligibility check, no confidence-scoring pass and no comment posted — as five
parallel reviews of the local diff, with findings checked by hand. Two are fixed
in #236: the refusal above, and
the gate's inapplicable count, which read a sentence where #206 had already
moved the met count to the verdict column.

Overnight state from 2026-09-12 was closed with `--end`; its deadline had
passed 26 hours earlier.

**Later the same session: two more, both yellow, both open.**

- **#238 closes #127.** `felix handoff "note"` dropped the note and printed
  success, and a bare `felix handoff` carried the previous session's note
  forward in silence — which happened to this session's own close, and was
  caught by reading the file. Words are the note now, an unknown flag refuses,
  and a bare call says which note it kept. Twelve assertions written before
  the change; nine fail against the old parser. 2069 passed, 0 failed.
- **#239 is #2's first increment**, `docs/2026-08-18-promotion-spec.md` steps
  2-4, decided on 2026-08-18 and never built until now. `installed` asks
  whether the cache entry for the version main declares is main's engine,
  both sides from the base, so any checkout can pass it and the gate certifies
  the judge `felix merge` uses. On #236's real tree: today's gate reads
  structural FAIL, this one reads ok. Fifteen assertions on the real
  `gate.sh` in a fixture; two passed against the old gate for the wrong reason
  and were tightened before they were believed. 2072 passed, 0 failed. It
  takes effect only once the home has pulled, because `felix gate` runs the
  home's working copy of `gate.sh`. Step 5, promotion after acceptance, is red tier with no channel: a separate
  pull request, reviewed hard, that Felix merges on green CI; `deploy-check` and the `engine_deployed` obligation
  still ask the old question and are the next re-point.

**Next, in order.** (1) Merge #236 on green CI (red is advice; no channel fires) — then
the three commands above in the home. `graphify` comes due again after the
merge. (2) `felix commission` and the re-grant, still only a person's. (3) The
public snapshot: in the stand-in above qualification no longer blocks the gate,
but neither that nor the rest of `felix gate` has been run on the snapshot, and updating that repository is
a publish, so it waits for the founder to say. (4) Merge #238 and #239 (yellow);
#239 needs the home to pull before it does anything. (5) Standing:
`projects/bazaar` and `projects/webapp` stay untracked.

