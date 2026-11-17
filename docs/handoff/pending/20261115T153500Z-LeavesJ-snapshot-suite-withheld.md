### 2026-11-15: the suite passes on the public snapshot again (0.49.352; six parts that read what the snapshot leaves out)

**What this is.** After #514 landed (0.49.346), `projects/felix/snapshot.sh`
cut the snapshot from main at `c9bff19b`. Its scrub, audit and credential scan
passed ("98 acknowledged, none open"; 4 secret hits, every one on the public
main too). Then it ran the suite on the staged public commit, as it is built
to, and stopped there: 17546 passed, 25 failed, 88 skipped. No push command was
printed. This branch fixes the parts that failed, so the next cut from main
gets through.

**Scope.** The six parts that failed on that one commit, in that one run. This
does not change the scrub, the audit or what the snapshot withholds. It is not
a search of the suite for every part that reads what the snapshot leaves out:
a part that reads one only on a path this run did not take would not have
failed here. That class of question is open, and belongs to a design session,
along with the open question in the 2026-11-13 snapshot section.

**What failed, and the change.** Each part read something the snapshot does
not carry, or a project name the scrub rewrote.

| Part | Failed | What it read | Change |
|---|---|---|---|
| 0940 | A112, 1 | two governed projects' names as literals in a word list; the scrub made each a phrase of several words, and one of them, `a`, is on every line it searched | the literals are gone; the folders under `projects/`, which the next line already reads, name them in the home |
| 1230 | A1, 2 | `docs/2026-10-12-gate-friction-contract-a.md` | skipped, saying so, when that document is not beside the harness, as part 1850 does for its own |
| 1760 | b07 A65 to A83, 19 | `.claude/cloud/provision` | skipped, saying so, when `.claude/cloud` is absent, as part 2070 does; a directory without the script is still bad |
| 1850 | b12 A85, 1 | `docs/2026-09-21-where-felix-stands.md`, for a route `felix_exception_for` does not doubt | skipped, saying so, only when the document is absent and some route is not doubted; asked as before otherwise |
| 2301 | cnv3 A38, 1 | `HANDOFF.md` and `docs/handoff/` | skipped, saying so, when neither is beside the harness |
| 2400 | manifest, 1 | its name carried the count of folders under `projects/`, "(8 name(s) read)", which is 0 in the snapshot | the count is out of the name, which is now the one its own skip branch already gave |

In the home every one of these is asked as it was, since the home holds each
file and every folder; only 2400's name changes.

**Escape: one, answered by the founder.** Part 2400's rename drops the
assertion "2400 the table names no project under the projects/ beside this
harness but felix, comments included, without regard to case (8 name(s)
read)" and adds the same name without " (8 name(s) read)". `felix merge`
prints that as one "drops assertion" line. The founder was shown the old name
beside the new and answered "Rename it, land all six" (2026-11-15). If the
landing check shows any other line, he is asked again.

**Order.** #515 landed as 0.49.348 during the cut. While this waited, #516
landed as 0.49.349 and #518 as 0.49.351; main was merged in after each, and
this takes 0.49.352.

**Next.** Once this lands and deploys, run `snapshot.sh` from the home on main
again. Audit what differs from this cut, test the install in a scratch HOME,
and open the public pull request, merged with `--merge` on green CI. Then
`felix maintenance --ran snapshot`.
