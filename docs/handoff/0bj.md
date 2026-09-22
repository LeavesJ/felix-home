## 0bj. Verified at session close, 2026-09-17 (late) — the exception channel exists, read from the remote-tracking main, and six readers of the design found what one author could not

| | |
|---|---|
| merged | **#261** (red tier: `lib/exceptions.sh`, the eighth column of the obligation run, the `exception` escape channel, the deny rows, the Stop hook's sentence, three templates, 0.49.121), through `felix merge` on green CI; nothing in it escaped, because the deployed kernel that judged it predates the channel and the pull request carries no grant row |
| deployed | **0.49.121**, carried in the pull request; the home's `felix install` deployed it byte-identical and wrote no bump |
| suite | **2443 passed, 0 failed, 1 skipped**, 2444 reached; 45 assertions authored blind, on fixture repositories with their own bare origins |
| red.tsv | **39 of 2444** fail against `fd2635c` at 0.49.120; the six that hold there are behaviour the old engine already had — one release-mode rule, one authority hold, two checks that unexcepted rows still block, one negative path on the escape, one summary sentence |
| filed | **#260**, `felix merge` honours `FELIX_KERNEL`, so a session can choose its own judge — a hole over every escape channel, found on the way |
| design | `docs/2026-09-17-exception-channel-design.md`, corrected on this branch for the bar separator, the anchored `now` and the calendar-year horizon |

**What §3 says and what now exists.** A row in `projects/<name>/exceptions.tsv`
clears one admitted `TASK_BLOCKING` obligation at the task moment — the gate
and therefore the Stop hook — and nothing else: never a `RELEASE_BLOCKING`
or `AUTHORITY_BLOCKING` row, never an authority hold (pathway `unknown`),
never the merge boundary, which passes `release` to the run and the filter
both. The grant is keyed to the ledger line by content hash, so a rewritten
obligation voids it; it carries an absolute UTC expiry compared as text
against a `now` that is the later of the clock and the base commit's own
date, no later than the end of the next calendar year; missing, malformed, expired, moved, a
second live row, all read as no clearance or the earliest expiry. `felix
obligations` prints each row's hash so nobody computes one, lists the grants
at the remote-tracking main as live, armed or refused with the reason, lists
what was written here and not yet merged, and counts `discovered, admitted,
granted`. The gate's line reads `excepted` when a green rests on a grant,
and each clearance is said to `says.log`.

**Where it is read from is the whole design.** The session can write any
file, so a grant read from the working tree is one it gives itself. The
reader reads `refs/remotes/origin/main` of the repository that holds the
tables — and nothing else: not `felix_base_ref`'s fallback to a local
`main`, because a local branch is the session's to move, which an
adversarial refuter demonstrated with `git update-ref` and a commit built
with `commit-tree`. A row becomes a grant only by being merged and fetched,
and merging it fires the `exception` escape, a path channel like
`authority`, that `felix merge` hands to a person. `projects/felix/deny.tsv`
refuses the named commands that would move the ref from a session —
`update-ref` and `symbolic-ref` on `refs/remotes/`, a `fetch` with a refspec
into one, `remote set-url` and `add`, a push whose refspec targets main —
global options tolerated; and the design says plainly that a regex over
command text is a floor and branch protection on the remote is the wall,
which this repository does not have (the founder's item 3 since §0bh).

**Scoped to Felix governing itself, and said so.** A product's tables live in
the Felix home, whose diff the product's boundary never examines, so the
channel could not fire on a grant written there, and the home checkout sits
on `main`, so a commit there lands with no boundary at all. The reader
therefore clears nothing when the tables and the governed tree are in
different repositories, and `felix obligations` says why. The second
increment is the boundary reading the home's diff as a second (root, base)
pair; the reader then serves products unchanged.

**Six readers of the design, and what each found.** A read-only understand
phase (six subsystem maps and a critic) put the blocking rule below the
authority-hold arm before the code was written; the critic also established
that the obligations fixture's project directory is not a repository, which
is why the blind assertions build their own homes with bare origins. Three
design refuters, before the build: the local-main forgery; the product case
above; `FELIX_KERNEL` at the boundary (#260); a `date` shim on PATH reviving
an expired grant, answered by anchoring `now` to the base commit; a stamp of
the right shape with impossible values, answered by range checks and the
horizon; and the colon inside the eighth column's separator, which would
have truncated every printed expiry. Three code reviewers, after: `git fetch`
with an explicit refspec moves the ref (deny row); `--date=format:` ignores
`TZ` and glues a `Z` onto the commit's own zone, found by all three; a grant
on a row that has since passed still labelled the gate `excepted` (the
column exists only where the grant clears something now); the unmerged
listing read the home's tree instead of the worktree's; and "adding a row
can only narrow" was true at any instant and false across time, so the
comment says what it guarantees. The code reviewers' findings were outside
the contract the blind author was given; the refuters' were written into it
before the build, and the blind block asserts them. The same finding as §0bi's: blind
authorship tests the sentence, review tests what the sentence left out.

**What this increment does not do.** It does not touch `FELIX_ALLOW_RED`,
the founder's launch-time act over the whole gate. It does not add
`exceptions.tsv` to the commission's policy tables (#254 is where that is
decided). It adds no qualification controls: they run in a detached
worktree that shares the repository's refs, so a mutation cannot stage a
different remote-tracking main — a limit of the substrate, recorded in the
design. It seeds an empty table for new projects and for felix; elenchus and
veldra get none, and none would be read.

**Next, in order.** The founder's list stands from §0bi, with branch
protection on `main` now carrying a second reason. Felix's, in a next
session: (1) the boundary reading the home's diff, so the channel reaches
products; (2) #260, the judge chosen by the environment; (3) qualification
control 7 and the author column; (4) #259, option 1 or 3, for the graph row.

