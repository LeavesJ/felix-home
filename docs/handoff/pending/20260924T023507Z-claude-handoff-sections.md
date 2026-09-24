### 2026-09-24 — handoff sections cannot collide: a session adds a file, and one fold of main gives the ids

**Engine 0.49.168 on branch `claude/handoff-sections`, not deployed at the
time of writing.** Why, and the options weighed:
`docs/2026-09-24-handoff-sections.md`.

**What changed for every session after this one.**
- Do not write your section into HANDOFF.md. Write it as a file headed
  `### <title>` with no id, and run `felix handoff --section FILE`. It lands at
  `docs/handoff/pending/<UTC time>-<branch>.md`, a path no other session
  writes.
- The session start names the pending sections after HANDOFF.md. Read them:
  they are newer than the current section.
- When upkeep says `handoff` is due (origin/main holds three), cut a branch
  from main, run `felix handoff --rotate` and land it. The ids follow the order
  the sections landed. Two folds of one main write the same bytes.
- The gate's `handoff` check refuses a section written into HANDOFF.md by
  hand, an archive rewritten or removed, and a pending section removed without
  being folded in.

**Branches that still rotate by hand** (checked 2026-09-24): #312 (claims
§0bv), #326 (§0bx and §0by) and #330 (§0bw). Each is refused once it merges
main. The design note's last section says how to convert one: take HANDOFF.md
and `docs/handoff/` back to main's copy, then add the section with `--section`.
#326 carries #325's section as well, so it writes that one by hand as a second
pending file. #332 edited the current section in place, and that is allowed.

**The landing actor** (draft in
`~/.felix/memory/felix/audits/2026-09-23-landing-actor/`) needs one change
when it is built: run `felix handoff --rotate --base B` as a bookkeeping
resolver before its gate, with no `owed`. The note's "With the landing actor"
section has the detail. Nothing here lands anything, so there is still one
lander to build.

**Next:**
- Deploy 0.49.168 from the home checkout once it merges.
- Convert #312, #326 and #330, or tell the sessions carrying them.
- The first real fold, when three sections have landed.

**Traps paid:**
- **`gate.sh` is read from the home, and the tree it gates is a worktree's.**
  A new gate check that fails when its script is absent turns every branch cut
  before it red. `handoff` skips out loud when absent. The suite still calls
  the script, so a tree that deletes it fails.
- **Main's marker was wrong for one pull request's life.** #295 moved the
  section and not the marker, and #302 fixed it by hand. The replay against
  main's history found it, and the new check refuses that tree.
