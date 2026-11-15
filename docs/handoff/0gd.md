### 0gd. 2026-11-09: slice 3's units read the bytes and names that land, and so do the base-side copies (trust step 3, A22 and A23, 0.49.338)

**What this is.** A fix to trust step 3's slice 3 (0.49.336), on branch `claude/trust-run-tree-bytes`. The finding came from the hosted-authority spike's review (`audits/2026-11-09-trust-hosted-authority/review/round1.md` in the memory root) and was reproduced in plain git 2.56. The spec is section 8 of `audits/2026-11-08-trust-plane-step3/spec-slice3.md`, amended three times. The base-side copies were added at a side session's request, made on the same finding.

**What changed.**
- **`lib/instrument-run.sh`.** The run tree T and the canary's copy were written by `checkout-index`, which obeys the tree's own `.gitattributes`. `working-tree-encoding`, `ident` and `eol=crlf` changed the bytes P's units read, while GitHub's squash lands the blob's bytes.
  - A22: the copy's `info/attributes` unsets the six attributes git's checkout converts by (`text`, `eol`, `crlf`, `ident`, `filter`, `working-tree-encoding`). After the checkout, every entry's file is hashed as a blob, and its kind and executable bit are compared with its mode.
  - A23: the filesystem T sits on decides which names are one, not a table. Beside T, each directory's names in T are made exclusively in a scratch directory, and a name refused as existing is one with the name made before it: two such names of T, paths or directory prefixes, are unknown SUITE.
  - A23, walked: each path of B, and each symbolic link's target from the link's directory, is walked through T as the filesystem resolves it, following T's links. A name T lacks that the filesystem answers with another of T's names is unknown SUITE, and so is an answer that names none.
  - The first version folded with Perl's tables, which are Unicode 13. This Mac's APFS folds by Unicode 17, and a plain-git check found 115 pairs (U+2C2F and U+2C5F, for one) that the table kept apart. The first filesystem version compared names only, and a review showed a link let the base's `MARKER` answer through the candidate's `marker`.
  - Each difference names its paths with bytes outside printable ASCII, and the backslash, as `\xNN`. No unit runs. The check runs in a process group of its own, so a TERM during it is handled at once.
- **`lib/policy.sh` and `lib/merge-judge.sh`.** `_felix_policy_copy` (P's tables, and the instruments they name) and `_mj_make` (the copy of main's engine that `felix merge` hands its verdict to) wrote with `checkout-index` and obeyed a `.gitattributes` inside the copied subtree, and the machine's attributes file. Each scratch repository now has A22's `info/attributes` line. A candidate's own attributes did not reach them at its merge, since both copy the base; one that landed would have at every merge after.
- **`lib/instrument.sh`.** The blocker names A22 or A23's reason, and carries no control byte from any source.
- **Parts 0480, 0580 and 0590 (A24).** The land tick's first full run refused this pull request: these parts assert on the machine's installed plugins through the real `claude` CLI, and a unit's own `HOME`, under the lander job's environment, leaves the CLI listing none (`slice3/release/r338/lander-refusal.md`). By the reproduction, these three lines would refuse any machinery change the tick judged on this Mac. Their real-CLI checks now run only where the CLI lists a plugin. P's versions still judge this change, so it lands from a session, by the founder's choice.
- **Tests.** Blind part 2185, in four passes from the spec and its amendments, each red first on this Mac:
  - the first pass: 5 of its assertions fail on 0.49.336;
  - the second (directory prefixes, escaping): 3 new assertions fail on the first fix, 6ab2d37e;
  - the third (case 6, the Glagolitic pair as a file and as a directory): 2 fail on e7dc3a23, where Perl's table decided;
  - the fourth (cases 8 to 10: links, the backslash, the base-side copies): 5 fail on 32792d05.

  Here it has 35 ok, 0 FAIL and 1 skip on this Mac. The skip is case 3's branch for a filesystem that does not fold. Parts that drive the changed files, run alone on the fix (2176 and 2177 together, as their group runs), none failing: 0100, 1870, 2170, 2173, 2176 with 2177, 2178, 2179, and 2180 to 2183 (106, 102, 78 and 93 lines).

**Open.**
- **Reach.** The run tree's check acts only when T is made: a candidate that changes an instrument part or the machinery. A candidate that changes an engine file and a `.gitattributes`, and no test, is judged by its own suite in the gate's and CI's checkouts, which obey the attributes too (R3, R4).
- **Not driven by a test:** the Unicode-decomposition fold, a name the filesystem refuses, the canary's copy, the kind, symbolic-link and gitlink checks, and the machine's attributes file.
- **Not checked:** a symbolic link in T that points outside it (units run candidate code anyway, E4); attributes read by tools other than git's checkout; the filesystem's other behaviours, such as length limits; a hash of the base-side copies.
- **Found, not changed:** `lib/qualify-run.sh`, `lib/situations-read.sh` and `lib/discover.sh` write trees that obey attributes. Whether any runs under `felix merge` was not traced; the merge boundary loads the obligations library, which reaches qualification.
- **Parts that fail as units under load:** 0660 and 1292 failed in the tick's run, near load 30 to 40, and passed alone near 12. Other parts of P that read what a unit cannot see may remain; these three were found by running, not by reading.
- **False blocks of A23 on this Mac:** a case-only rename, a rename that changes only Unicode normalization, and every candidate that keeps either name of a pair the base already holds (main holds none today).
- **Cost:** the name check took about 0.08 s on this repository's 984 paths with main's 982 as B (three runs; Perl's table took 0.03 s). On 50,000 files the whole check took 4.7 s in one run; in another, a TERM 0.5 s into it was handled within 0.01 s, and the check's group was gone 0.22 s after it. The review measured A23 at 16 s and 173 MB on 200,000 paths, before the walk replaced B's scratch names with lookups.

**Release.** 0.49.338 fails closed until the founder authorizes it by name (direction row 49).
