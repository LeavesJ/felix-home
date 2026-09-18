# The exception channel: amendments §3, first increment

Design, 2026-09-17. Conformance to `felix_v32_conformance_amendments.md` §3,
built against the engine as it stands at `fd2635c` (0.49.120). Nothing here
derives a kernel; it puts one clause of the governing text into the tables and
the one function that already decides what stops.

## What §3 requires, and what exists

| §3 clause | Today | This increment |
|---|---|---|
| Task-blocking only; never RELEASE_BLOCKING | `felix_obligations_blocking` (`lib/obligations.sh:153`) is the one funnel; `release` mode already drops TASK_BLOCKING | the clearance is applied inside that funnel, only when mode is empty, only to `TASK_BLOCKING` rows |
| One channel | escape channels are engine constants named by shape (`lib/escape.sh:60–100`) | a grant clears an obligation and nothing else; it touches no escape channel's verdict |
| Not reachable by the session | `FELIX_ALLOW_RED` is safe because nothing the model runs consumes it (`hooks/stop:118–126`) | the reader reads the exception table from the **base ref** of the repository that holds it, never the working tree; a grant becomes effective only by merging, and merging it escapes |
| Any change fires, additions included | `FELIX_ESCAPE_AUTHORITY` (#207) is a path channel: any byte of `projects/<p>/autonomy*` changing escapes | `FELIX_ESCAPE_EXCEPTION`, the same shape, over `projects/<p>/exceptions.tsv` |
| Keyed to the obligation by content hash | `git hash-object --stdin` is the engine's hash (`lib/verify.sh:25`, `lib/epoch.sh:76`); `felix_obligation_rows` prints the ledger line verbatim (`lib/obligations.sh:71–77`) | the grant carries the hash of the exact ledger line; a reason edit voids it, which is the clause |
| Absolute expiry, refused when passed | `felix_overnight_expired` compares integers (`lib/overnight.sh:103`) | expiry is a UTC stamp in the engine's own format, compared lexically against `date -u`; no date parsing, so no GNU/BSD split |
| Missing, malformed, expired, moved → no clearance | `felix_review_passed` (`lib/review.sh:90`) reads empty, malformed and mismatched keys identically | the reader has one success path and every other path prints nothing |
| Three numbers counted | `discovered N, admitted M` (`felix:4443`) | `granted K` joins them; the gate's summary line gains `E excepted` |

## The table

`projects/<name>/exceptions.tsv`, five tab-separated columns, comments and
blank lines ignored:

```
obligation	row_hash	expires	granted_by	reason
```

- `obligation`: the ledger name the grant is for.
- `row_hash`: `git hash-object --stdin` of that row's exact line in
  `obligations.tsv`, tabs and reason included; at least twelve hex characters
  of it. `felix obligations` prints each admitted row's hash so a person can
  copy it. The grant is void the moment the row changes, in any column.
- `expires`: `YYYY-MM-DDTHH:MM:SSZ`, UTC, absolute, with the month, day,
  hour, minute and second range-checked. The reader compares it as a string
  against `now`, which is the later of the machine clock and the committer
  date of `refs/remotes/origin/main` in the same shape, so a `date` shim on
  PATH cannot revive a grant that had expired by the time the ref was last
  fetched. An expiry later than the end of the next calendar year is refused
  (the horizon is a calendar year, not a rolling twelve months). Among
  several live rows for one obligation the earliest expiry wins.
- `granted_by`: the person, as text. The commit that merged the row is the
  attestation (§1.1); the row's text is the intent.
- `reason`: why, for the reader of the ledger.

A row clears exactly one obligation, and only if that obligation's class is
`TASK_BLOCKING` and its pathway is not `unknown`. A row naming a
`RELEASE_BLOCKING` or `AUTHORITY_BLOCKING` obligation, or an authority hold
(pathway `unknown`, which amendments §1.3 says no table can declare away),
is refused by name, never downgraded, never silently ignored. In the
blocking filter the rule sits below the authority-hold arm, so the order of
the code is the second lock on that door.

`granted K` counts the well-formed rows at the base ref, whatever their
state: a refused grant was still granted, and the number the amendment asks
for is how many a person wrote, not how many the engine honoured today.

## Where the grant is read from, and why

The session can write any file in the tree, so a grant read from the working
tree is a grant the session can give itself. The reader therefore resolves
the repository that holds `projects/<name>/` — the checkout itself when Felix
governs itself, the Felix home for a governed product — and reads
`exceptions.tsv` from that repository's **remote-tracking main**,
`refs/remotes/origin/main`, verified by its full name, with `git show`. Not
`felix_base_ref`'s fallback to a local `main`: a local branch is the
session's to move (`git update-ref`, or a commit on the home checkout, which
sits on main), and an adversarial review of this design showed exactly that.
The remote-tracking ref moves only when something is fetched from the
remote, which is where the person is. A file in the working tree, on a
branch, on a local `main`, or in a repository with no remote clears nothing;
a project with no remote has no person-side of a merge either. `felix obligations` still lists what the working tree
holds, marked as not yet a grant, so a person can see what they wrote before
merging it.

Merging it is where a person decides: the path channel fires on any change
to the file, additions included, so `felix merge` refuses it unattended and
records `escalated`. That is the amendment's "not reachable by the session"
without an environment variable: the session can write the grant, cannot
make it effective, and the act that makes it effective is one the boundary
hands to a person.

**What that rests on, said plainly.** Named commands would let a session move
the remote-tracking ref itself — `git update-ref` or `symbolic-ref` on
`refs/remotes/`, a `git fetch` with a refspec into one, `git remote set-url`
or `add`, a `git push` whose refspec targets main — and `projects/felix/deny.tsv`
refuses each through the PreToolUse hook, global options tolerated. A regex
over command text refuses the spellings it names and no other: it is a floor,
not a wall; the wall is branch protection on the remote, which this repository
does not have (HANDOFF §0bh, the founder's item 3), and until it does the
clause holds against accident and against every session that uses Felix's
own commands, not against a session that sets out to forge a ref. The same
review found that `felix merge` honours `FELIX_KERNEL`, so a session can
choose its own judge — a pre-existing hole over every escape channel, filed
as #260 rather than patched here. And a grant revoked on the remote is
honoured locally until somebody fetches, because nothing on the enforcing
path fetches; `felix obligations` prints the ref's commit date beside the
grants so the lag is visible, and the expiry is what bounds it.

## Where it is consumed

`felix_obligations_run <proj> <root> [mode]` gains an eighth column: `-`, or
`excepted|<expires>|<granted_by>` — a bar, because the stamp carries colons —
when a valid grant exists for a
`TASK_BLOCKING` row and the mode is not `release`. `felix_obligations_blocking`
skips such a row when its mode is empty — the task moment — and never when
the mode is `release`. The merge boundary passes `release` to both, so the
release path never carries a clearance in its data and never honours one in
its filter: two locks, because the review showed that one awk literal is
not "by construction". Two more findings from the same review landed in
`obligations.sh` on their own merits: the run's detail column is stripped of
tabs and carriage returns, because an evidence command's last output line
could otherwise write the eighth column itself; and a ledger that admits one
name twice refuses the second row, because everything that reads the ledger
assumes the name identifies the row. The discharge column stays `UNSATISFIED`: the
obligation is still owed and still printed; what changed is that a person has
accepted it not blocking this task, until a date.

The library is sourced from `obligations.sh` behind a `command -v` guard.
The direction of failure decides the guard: a clearance widens, so a missing
library withholds it and every row reads unexcepted.

## What is printed, said and recorded

- `felix obligations`: the eighth column beside each row; each admitted row's
  hash; `N obligation(s): … ; B blocking, E excepted`; the grants at the base
  ref with their expiry, the refused rows with the reason, the working-tree
  rows that are not yet grants; and `discovered N, admitted M, granted K`.
- `felix obligations --gate`: the same summary line, which the gate reads;
  one `felix_say excepted` per row cleared, so `says.log` and the monitor
  carry the moment.
- The gate's obligations line reads `excepted` rather than `ok` when the
  green rests on a grant, and the verification receipt's per-check states
  carry that word, so a deferred obligation is never read as a discharged
  one. The receipt's `granted_by` is the release moment's authority field
  and stays what it was: exceptions never reach the release moment.
- The Stop hook's hold text names the narrower remedy beside the global one.

## What this increment does not do

- It reads grants only where the ledger and the governed tree share a
  repository — Felix governing itself. A product's tables live in the Felix
  home, and the product's merge boundary diffs the product, never the home;
  the `exception` escape could not fire on a grant written there, and the
  home checkout sits on `main`, so a commit there lands without a boundary
  at all. The review found this; the reader refuses such grants outright and
  `felix obligations` says why. The second increment is the boundary reading
  the home's diff as a second (root, base) pair, after which the same reader
  serves products unchanged.

- It does not touch `FELIX_ALLOW_RED`. That is the founder's launch-time act
  over the whole gate; this is a person's merged grant over one obligation.
- It does not add `exceptions.tsv` to `FELIX_COMMISSION_TABLES`: a grant would
  then move the decision epoch and stale the commission receipt (#254).
  Amendments §1.1 says the table set is the policy version, and a grant is a
  policy act; the tension is real and is resolved for now by the grant's own
  scoping — one row, one obligation, one date, escaping on merge — rather
  than by re-stamping three projects per grant. #254 is where that is
  decided.
- It does not add qualification controls for the reader. Controls run in a
  detached worktree sharing the repository's refs, so a mutation cannot stage
  a different base ref; the reader's refusal directions are asserted by the
  suite on fixture repositories with their own `main` instead. Recorded as a
  limit of the qualification substrate, not of the reader.
- It seeds an empty table for new projects and for felix; elenchus and veldra
  get none, and a missing table reads as no clearance.

## Refusals the reader must make, each shown failing in the suite's `exceptions:` block

missing file; file present in the working tree only; file on a branch only;
file on a local `main` with no remote; file committed on top of the fetched
main but not pushed; no remote-tracking main; malformed row (fewer than five fields, empty name); hash not
matching the current row; hash shorter than twelve characters; expiry
malformed; expiry passed; obligation not admitted; obligation
`RELEASE_BLOCKING` or `AUTHORITY_BLOCKING`; obligation `DORMANT` (nothing to
clear, and it is not counted as excepted); library missing (every row
unexcepted); and the merge boundary in `release` mode with a valid grant
present (still blocks).
