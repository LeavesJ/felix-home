# Handoff sections that cannot collide

*2026-09-24. Engineering, so Felix's to decide, and it merges on green (#319).
The code is `engine/harness/lib/handoff.sh`. The rule a session follows is in
HANDOFF.md's preamble.*

## What went wrong

The rule was: write your section at the top of HANDOFF.md's "Current state"
with the next id, move the section it replaces into `docs/handoff/<id>.md`, and
add its index row. That gives every session one slot and one counter to share,
and it has them claim both while writing, before anybody knows what will land
first.

With ten or more sessions at once, it broke on 2026-09-23/24:
- **Four pull requests claimed §0bw within an hour:** #327, which landed, and
  #325, #330 and #326.
- **#312 claimed a §0bv that main already had.**
- **Landing #325 and #326 took cross-session messages and a hand re-cut.** A
  scratch script (`land_handoff.py`) assigned the ids against main at landing
  time, and the merge commit was 64ed7018.

Each collision is a textual conflict at best. At worst, a careless resolution
re-archives a section or drops one.

History shows the same slot failing even without concurrency. The six
rotations on main since the split (#283) were replayed through the new fold,
and three of them come out byte-identical. The other three were hand slips:
- **#287** edited the preamble in the same commit. That was a real change, and
  its archive matches.
- **#295** moved the section and not the marker. Main's marker then named a
  section that was not there until #302 fixed it by hand. The new check refuses
  that tree.
- **#317** left out the blank line before `---`, which every other rotation
  has.

## The cause

The class, not the instance: an authored thing and a derived thing were in the
same place. The session writes the section, and that part is its own. The id,
the archive move, the index row and the marker are different: they are only
true against the main the section lands on. That is the class the landing actor
design names for the engine version, `red.tsv` and the assertion manifest ("files
only valid against current main"), and the remedy is the same: the author
writes what it owns, and the rest is derived once, where there is one writer.

## Options

**(a) Pending files, folded at landing.** A session writes its section to
`docs/handoff/pending/` with no id. Something at landing assigns the ids and
rotates.

**(b) Ids collision-free by construction, and HANDOFF.md generated.** Ids of
date and session, or PR number, never collide. But a generated HANDOFF.md fails
either way:
- If it is committed, every PR regenerates it, and the PRs conflict on the
  generated file. That is the same collision, moved.
- If it is not committed, the file the session start names is gone.

Getting out of this means generating at landing, which is (a). Taken from (b):
the pending file's name is collision-free by construction, a UTC time plus the
branch name.

**(c) `felix handoff --section FILE` rotating against origin/main at merge
time.** This still claims an id before landing. A pull request that rotates,
then gates, then merges races every other one in that window, and the gate
takes ten minutes to an hour at this machine's load. `felix merge` cannot
rotate after the gate either. It merges the tree its receipt was keyed to, and
a rotation commit is a new tree that nobody gated. The landing actor design
calls this hole A2. Taken from (c): the command, as the fold's surface.

**Decided: (a), with (c) as its command and (b)'s naming.**

## The design

**A session adds a file.**
- `felix handoff --section FILE` writes the section to
  `docs/handoff/pending/<UTC time>-<branch>.md`, headed `### <title>`.
- An id in the heading is dropped, and the command says so. That is how a
  section cut under the old rule comes over.
- A second call on the same branch rewrites that branch's file.
- Two pull requests that each add one touch no path in common, so they land in
  either order without a conflict.

**The fold is one function of main.**
- `felix handoff --rotate` orders the pending files by the first-parent commit
  that added each on the base ref: the order main accepted them, not the order
  anyone claimed. A file the base does not hold yet comes last, by name.
- Each takes the next id.
- The current section is archived verbatim, its trailing blank line dropped.
- All folded sections but the last are archived, and the last becomes current.
- Their rows go in newest first, above the newest numbered row.
- The marker moves on, and the folded files are removed.
- It is built aside and written only whole. It refuses to overwrite an archive
  file that holds other bytes.
- It reads its work back through the check before it reports.

**Waiting is harmless.** A pending section is a complete handoff already. The
session start names the pending sections after HANDOFF.md, newest five and a
count. So the fold can lag without any session missing a section. The upkeep
row `handoff` in `projects/felix/maintenance.tsv` falls due when origin/main
holds three.

**Two folds at once.** Folds of the same main write the same bytes, and git
merges identical changes cleanly; the suite lands two and checks the second
changes nothing. Folds of different mains conflict on HANDOFF.md, and the
loser folds again on current main. This is rare, because folding is upkeep and
not every session's job.

**A fold in flight is named, not asked for again.** *Added 2026-10-01.* It was
less rare than that. Every session reads the upkeep row at its start, so with
about twenty at once several started the same fold: #347, #351 and #377 each
folded overlapping sections, and only #377 landed. Nothing was corrupted,
because the check refuses a stale fold, but the work and the queue slots were
wasted. So with three sections waiting, the row's check asks
`engine/harness/bin/handoff-in-flight` before it fails.
- **Which branch counts.** One under the same remote as main whose marker is
  past main's in fold order, and whose merge-base with main holds main's
  marker. Every merge-base counts, since a criss-cross merge can leave two.
  The second condition means main's marker has not moved since the branch was
  cut: no fold has landed since, so the sections it folded are still the
  oldest waiting on main. Main may hold more that landed since, and an edit to
  HANDOFF.md in place on main can still make the two conflict. A fold cut
  from a main whose handoff has moved since is stale: it conflicts with main
  on HANDOFF.md and cannot land as it stands, although handoff-check, reading
  against its own merge-base, passes it at its tip.
- **What it reads.** Only the remote-tracking refs, as last fetched, with git
  and no network. Each branch's HANDOFF.md is one blob; a branch sharing
  main's blob has folded nothing, and the rest are read for their markers in
  one `git grep`, by commit rather than ref name, so a branch pruned
  meanwhile cannot blank the read. That took about 0.2 s of CPU (0.13 s user)
  over 178 branches on 2026-10-01, and it runs only when three sections wait.
- **Abandoned folds.** A fold whose tip commit is older than 48 hours by
  committer time counts as abandoned, and the row is due again. A tip dated
  more than an hour ahead of the clock is not trusted as fresh either. Without the network nothing here
  can tell a closed pull request from a waiting one. A fold that silenced the
  row for as long as its branch exists would cost more than a second fold.
  #377 landed about eleven hours after it was cut.
- **What a session sees.** The check passes and prints the branch. A passing
  check that prints reads `inflight` (lib/maintenance.sh), so the session
  start says `Already in flight, so not due: handoff on
  claude/handoff-fold-1001 (folded to 0cn; tip 2h old)` in place of
  `Maintenance due: handoff`. `felix maintenance` says the same, and the
  overnight stop, `felix next` and the pulse keep only `due`, so none of them
  asks for the fold either.
- **What output can never do.** A failing check is due whatever it printed,
  so a broken script, or one this engine does not have, leaves the row due.
- **Why not a new column.** A sixth column would have changed
  maintenance.tsv's row in `templates/schemas.tsv`, an escape table, and
  stopped the merge for the founder over an upkeep notice.

On real input on 2026-10-01 it named #386 (`claude/handoff-fold-1001`, cut
from main 5772afac, marker 0cn) and nothing else. Left out: the branches of
#347 and #351 (marker 0cc, behind main's 0cg), #377's (landed), the
`claude/handoff-0b*` branches (markers 0br to 0bz, behind main's), and the
`docs/handoff-0a*` and `docs/handoff-0b*` branches from before the split,
which carry no marker.

**The check makes the fold the only way.** `engine/harness/bin/handoff-check`
runs in the gate as `handoff`.

In the tree, it requires:
- one marker, above the current section, naming the current section and the id
  after it;
- the current section headed once and closed by `---`, and no other section
  headed with an id beside it;
- archive files and index rows one to one, with the titles agreeing;
- the current id neither archived nor indexed;
- pending sections well formed.

Against the merge-base with origin/main, it requires:
- no archive file changed or removed;
- when the current id is unchanged, an unchanged heading for it;
- when the current section changes, the branch must have removed the
  oldest-landed pending files the base held, and the result must be exactly
  what the fold of the base writes, part by part.

A section written into HANDOFF.md by hand is refused however correct its id,
because that shared slot is what collided. So is a pending section removed
without being folded in, since that drops it.

Two more shapes lose a section without a sign. A peer session found both
live on 2026-09-24, and both are refused:
- **Another section put in place under the current id.** A carrier's merge
  into #312 renamed #312's section to 0bw, the id main's current section
  already had. An edit in place keeps the section's heading, so a changed
  heading under an unchanged id is refused.
- **A hand rotation cut from an older main.** It archives its own stale copy
  of the section. #326's head before d9d8a106 archived an 85-line §0bw against
  main's 101; the carrier has since re-cut it from main. The refusal names the
  archive and what it drops.

Allowed without comment:
- adding or editing a pending file;
- editing the current section in place, keeping its heading;
- editing the preamble or §0.

Where the check file is absent from the gated tree, the gate says `skipped`
rather than failing. `gate.sh` is read from the home, so a branch cut before
this change would otherwise go red for a file it never had. The suite calls the
check, so a tree that deletes it still fails.

## Checked on real input

- **The replay of main's six rotations**, above.
- **The check on this tree:** clean.
- **The check on the four open branches that edit HANDOFF.md** (2026-09-24):
  - #312, #326 and #330 are hand rotations, and each is refused with the
    instruction to use `--section`.
  - #332, which has since landed, edited the current section in place, and it
    was clean.
- **Qualification:** six controls in `projects/felix/qualification.tsv`, each
  written by a subagent that had the obligation in prose and was barred from
  reading the checker, its tests and this note. On their first run, five held
  and `violation` did not. A section written in above the current one, with
  the marker, rows and archive left alone, passed the check, because nothing
  counted id-headed sections. The fixture tests shared that blind spot. The
  check now refuses a second one, the suite carries the same shape, and all
  six are met through `felix qualify`.

## With the landing actor

The design draft is at
`~/.felix/memory/felix/audits/2026-09-23-landing-actor/design-synthesis-DRAFT.md`.
Its §4 bound `HANDOFF.md` to `session` because the HANDOFF.md conflicts of #305
and #312 had non-empty bases.

*2026-10-01.* The final design beside it (`design.md`, 2026-09-24) settles
this differently from the bullets below. Folding stays upkeep in the actor's
first version: the actor would otherwise write HANDOFF.md, a `session` path,
so the fold stays with this row, and the draft's fold at landing is
superseded. The actor lands a fold pull request like any other. Naming the
fold in flight (above) is what keeps two sessions from making one, and it
lands nothing. Once the actor keeps its queue, that queue would be a better
witness of a fold in flight than branch age, since it knows which pull
requests are open. Until then, branch age stands in for it. The bullets below
are the draft's reading, kept for the record.

- **Those conflicts no longer arise.** An authoring pull request does not touch
  HANDOFF.md. The `session` row stays for the rare edit to §0 or the preamble.
- **When the actor exists, the fold moves to landing.** After step 5
  integrates M, bookkeeping at step 8 runs `felix handoff --rotate --base B` in
  the actor's clone, before the gate. The pending file then lands already
  folded, and `pending/` is only ever transient. The fold is a function of B
  and the PR's own file, and the actor lands one pull request at a time, so it
  needs no upkeep row.
- **It must not arm `owed`.** An unfolded pending file is a valid state, and
  the check passes it, so a fallback `felix merge` must not refuse an authoring
  pull request for lacking a fold. As a `land.tsv` row, it is a `rerun` keyed on
  `docs/handoff/pending/` and exempt from `owed`.
- **Nothing here lands anything.** The upkeep row is a prompt to a session.
  `--rotate` edits a working tree, and the merge is the ordinary one. There is
  one lander, and it is the actor, once it is built.

## A branch cut before this

A branch that wrote its section into HANDOFF.md by hand:
1. Save the section's text to a file.
2. Take HANDOFF.md and `docs/handoff/` back to main's copy.
3. Run `felix handoff --section FILE`. It drops the id.
4. Commit.

A branch that carries another session's section too, as #326 carries #325's,
writes that one by hand as a second file under `docs/handoff/pending/`, named
with that session's branch. The check accepts any well-formed pending file.
Files added in one commit fold in name order, so give the earlier section the
earlier time.

## Not done

- **Two sessions editing the current section or §0 in place still conflict.**
  That is authored text, and it is rare. It is not this class.
- **Before the actor exists, nothing folds on its own.** A session folds when
  upkeep says so.
- **A fold not pushed yet is invisible.** Two sessions that start within the
  minutes before either pushes can still both fold. Only remote-tracking refs
  are read, so a local branch another worktree committed but did not push is
  not seen either. Closing that window would take a claim written before the
  fold, and the fold is cheap; the waste measured was folds that sat pushed
  for hours.
- **Abandonment is guessed from age.** A fold waiting in a stopped queue for
  more than two days reads as abandoned, and a second session may fold
  again. Two folds of the same sections write the same bytes and both land.
  If the second took in sections that landed since, the two conflict on
  HANDOFF.md, and whichever lands second folds again on the new main.
- **Without a fetched origin/main, the check runs only its tree-local half.**
  It says so.
