### 2026-11-13: main can be cut as the public snapshot again (0.49.346; suite fixtures, acknowledgements and one README link)

**What this is.** The public snapshot was due (47 days against 14), and
`projects/felix/snapshot.sh` could not cut it from main at 0.49.340. This branch
carries what it stopped on, so the next run from main gets through. The staging,
the audit and what was not checked are in
`docs/2026-11-13-public-snapshot-0.49.340.md` (PDF beside it). The publish itself
is a pull request on LeavesJ/Felix after this lands.

**Scope.** This covers the snapshot's stops and the README link. It does not
change the scrub, the audit or their rules. Whether the audit's address rule
should read the user part of an SSH remote as an address is open, and belongs to
a design session.

**What stopped the cut, and what changed.**
- Part 1860 (#475) used `webapp` as a fixture project's name in shell code.
  `webapp` has been a governed project on main since #388, so the scrub put its
  phrase into code and `snapshot.sh` stopped, as designed. The fixture is
  `website` now. It begins with `web` as `webapp` did, so A45, A47, A59 and A93
  keep their meaning.
- Part 1860 also used a governed project's private remote for fixture `el`. The
  scrub rewrote the repository part and left the owner beside it, and the run
  stopped. The remote is `Acme/Atlas` now, or `acme/atlas` for the lowercase
  clone (A48 to A51).
- The audit then stopped on 92 lines and on `zz`, an empty directory under the
  memory root that is too short to search for. `.snapshot-ack.tsv` carries a row
  for each line and an `@name` row for `zz`. The snapshot session proposed them
  commented out, and the founder's answer "Land fixes, then publish" turned them
  on. The file's own header tallies them.
- README: the "Designed, not built" row linked a file under `docs/`, which the
  snapshot withholds. That would have been a broken link on the public page,
  naming a private document. The link is gone and the sentence is unchanged.

**Order.** The founder put this after the three releases queued ahead of it by
number, #494, #509 and #511, on 2026-11-13. Once they land, merge main here
again and record. They landed as 0.49.341 to 0.49.343, with 0.49.345 (#513) after them, so the fix took 0.49.346.
Then gate alone and run `felix merge --dry-run`, which runs main's part 1860
over the tree as suite work. Its dry run on `3624a0d5`, alone at 20:58Z,
printed eight escape lines and nothing else that blocks besides the missing
receipt. All eight are "drops assertion" on part 1860, one for each renamed
assertion (A45, A47 to A51, A59, A93), with no failure and no unknown. Each of
the eight changed what it asserts, not only its name: its input remote, or the
binding it expects, moved with the fixture, and the old names carry the strings
that stopped the snapshot. The founder was shown each old name beside its new
one and answered "Yes, land when green". If the landing dry run shows any line
beyond these eight, he is asked again.
`.snapshot-ack.tsv` is in none of the escape tables, so `felix merge` does not
stop on its rows, though its header says each row is a person's judgment,
reviewed in the pull request that adds it.

**Next.** Once this lands, run `snapshot.sh` from the home on main (it runs the
suite on the snapshot). Audit what differs from the staged preview, test the
install in a scratch HOME, and open the public pull request, merged with
`--merge` on green CI. Then `felix maintenance --ran snapshot`.
