## 0av. Verified at session close, 2026-09-11 — the two provider rows answered, and a verify phase that ran out of session

| | |
|---|---|
| head | `main` 63133e0; this section on `docs/handoff-0au-order`, docs only |
| commissioning | 9 done, 3 held, **0 awaiting a session**; receipt `held` on the three a person owes |
| constitution | **64/100, C** — three independent scorers at 64, 64, 60, median taken in code |
| survey | 19 rows accepted, from 32 candidates through 7 finders and 3 refuters each |

**Both rows are answered, for topology `00565f52…`.** The founder merged #218,
installed 0.49.110, ran `felix commission` and re-granted `commission`; the run
rewrote both requests and this session answered them. `felix commission
--status` reads back 19 survey rows and the score, and `0 awaiting a session`.
Nothing is installed by being written there: a plugin row is still fetched at
its pinned sha, read and tiered before anything is declared.

**The constitution scores C, and the score is all Felix reads.** Three scorers
with different emphases — currency, actionability, architecture — returned 64,
64 and 60 without seeing each other. The previous answer, for another topology,
was 69. The findings worth acting on are all currency, and each was checked
against the tree rather than read: `lib/` is described as "forty-one sourced
libraries" and `ls` counts 44 (true when written on 2026-09-04, three libraries
since); the per-project table list names nine and omits `obligations.tsv` and
`qualification.tsv`; "the matching file under `engine/harness/templates/`" is
false for three tables that have no template — `stack.tsv` is cut from
`catalog.tsv` by `felix new`, `deny.tsv` is optional, `qualification.tsv` is
written by hand; Tiers says "the hook" where there are eight plus `hooks.json`;
and the `lessons.md` bullet describes mounting "per matched route", while
`hooks/user-prompt` mounts by word overlap on every prompt, outside the
route-matched branch — inaccurate on the day it was written. It also names
`felix promote` as the write path, and that command only reports what has
recurred; `felix lesson` is what appends.

**`CLAUDE.md` was not edited.** The improver skill edits only under its own
approval flow, the request says Felix does not read those edits, and doctrine is
the founder's. The audit is above; the score is on record.

**The survey, and what the refuters were for.** Seven finders with one lens each
— hooks, subagents, skills, plugins, MCP, what the gate cannot catch, what is
mounted and never reached — produced 32 distinct candidates; each went to three
refuters told to default to refuted, on existence, fit with the invariants, and
whether a session here would actually reach for it. Two were killed on premises
that were false about this tree: a TSV column guard argued "only commission.sh
counts fields" when `probes.sh` already refuses a malformed row, and a workflow
invariant guard that nothing would ever make fire. No MCP row survived — the
`github` row argued against itself in its own sentence, since `gh` already does
that work in `repair.sh`.

**What this cannot say.** The run hit the account's session limit partway
through verification: 64 of 106 agents died, so only 9 rows carry three
independent verdicts. The other 10 were judged by this session alone, against
the catalogues for existence — all four plugin names resolve in
`claude-plugins-official` — and against the tree for fit. Near-duplicates of a
verified row were dropped rather than kept, which is the conservative direction
but not the same thing as a panel. A later session re-running the verify phase
from the run id would know more than this one does.

**Found, not fixed.** `felix commission` can append an OBSERVED row to
`stack.tsv`, and `stack.tsv` is one of the twelve tables the autonomy grant is
stamped over — so a grant taken before a run that declares is stale the moment
it declares. Grant last. §0au's Next said the opposite and is corrected in this
branch.

