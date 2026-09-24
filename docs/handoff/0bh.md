## 0bh. Verified at session close, 2026-09-16 (closing) — the session's own record, audited: eleven claims false, twenty-six stale, and what six sections left out

| | |
|---|---|
| merged | nothing new; origin/main is `741d0f4` (#251), the home is clean at it, and **0.49.117** is deployed byte-identical to main's engine |
| suite | **2358 passed, 0 failed**, unchanged since #250 |
| commission | **current.** The founder ran it at 2026-09-17T01:25:02Z; the receipt reads held (envelope, discover and baseline hold, on the maturity elenchus has not declared), and `felix merge --dry-run` in this worktree reads "nothing escapes this tree, and the gate is green on it" |
| this section | §0bb–§0bg handed to read-only agents forbidden the suite and the gate: **250 claims, 11 false, 26 stale, 36 unverifiable**, and twelve things the sections left out |

**Why this section exists.** The six sections above were written by the
sessions they describe, and a record checked only against the tree by the
hand that wrote it is self-report. Before closing, every claim in §0bb–§0bg
was handed to agents with the tree, the home, the memory root, the plugin
cache and GitHub to read and nothing to run. Their verdicts are here; the
sections above are left as they were written, so the corrections stand
beside the claims rather than over them. Every false claim was about the
world outside the tree — which checkouts exist on this machine, how many
sessions a ledger counted, how many hours had passed — and the tree was
right every time. That is the same finding as the memory note "claims about
state are read, not recalled", now measured on the handoff itself.

**Eleven claims that were false when written.**

- §0bb: "the code-review plugin pointed at in 83 of 86 sessions" — the
  ledger counted 82 of 85 through 2026-09-13, and `felix ledger` today
  prints code-review in 91 sessions, named 15, reached 1: mounted nearly
  everywhere, reached once.
- §0bb: "its deadline had passed 26 hours earlier" — about 27, from 11:26
  PDT on 2026-09-12 to 14:29 PDT on 2026-09-13.
- §0bc: "the next session merged #222–#235 itself" — #222–#232, #234 and
  #235; #233 is an issue, not a pull request.
- §0bd: "SIGPIPE would read as unknown on every true yes" — only when the
  producer is still writing when `grep -q` exits; the `ls-files | grep -q`
  shape felix and elenchus declare returned 0 under `pipefail` here. The
  limit stands — a pipeline reports its last stage — and the frequency was
  overstated.
- §0bd: "probes was the one gate check qualification.tsv could not name" —
  the one *checker-shaped* check; syntax, installed, tests, ecosystem and
  qualified have no row either, and are not checkers.
- §0bd and §0bg: "neither elenchus nor veldra is checked out on this
  machine" and "elenchus is not checked out" — both are: elenchus at
  `/Users/a14808/Documents/Elenchus`, veldra at
  `/Users/a14808/ReserveGrid-OS`, each resolving to its project by remote
  match. Run there at this close: `probes-check` reads 5 probes found, 0
  unknown, 0 blind on each, in 1.1 s and 0.4 s; `obligations-check` reads
  `lifecycle_wired` dormant on each, "1 ground on no probe". What elenchus
  lacks is the `gate.sh` its `project.json` declares, so its gate cannot run
  there yet — a fact about the product, and the founder's.
- §0bd: "every ask their tables declare is `test`, `grep -q` or `ls | grep
  -q`" — all but one; veldra's `http_service` witness is `git grep -q`.
- §0be: "63 assertions were added" — 66.
- §0be: "the cost was not measured for governed products because those
  checkouts are not on this machine" — they are; it was not measured. The
  two timings above are that measurement.
- §0bf: "both now ask main's question through one function" — `deploy-check`
  does, through `felix_accepted_deploy_diff`; the gate's `installed` block
  asks it through its own inline copy. Two readers of one question is the
  shape #245 took out of the receipt, and it is worth folding.

**Twenty-six stale, in three kinds.** Every "Next" item marked Felix's in
§0bc, §0bd, §0be and §0bf is built — #243, #245, #247, #249/#250 — and
§0bg says so. "Commission is stale until the founder runs it", carried from
§0bd through §0bg, ended at 2026-09-17T01:25:02Z, and the merge boundary's
commission blocker no longer fires. And the state figures moved under the
sections: 0.49.111 and 0.49.116 are 0.49.117; 38 controls across 5 checkers
are 47 across 6; "the home has sat at #232" is the home at main; and Felix's
own obligations, "one active and one dormant" in §0bd, are both active since
#247, because `engine_deployed` applies wherever a plugin cache exists and a
base ref resolves, which a worktree satisfies.

**Thirty-six unverifiable, and the shape of that.** Everything the sections
say about *method* — that the assertions were authored blind, the red-run
counts (19, 9, 11, 38, 30, 72), the five reviewers and their four-to-one,
`felix merge` refusing on the stale receipt, the hook denying one edit in
three, the sweep's 120 statements — leaves no artifact on this machine. The
pull request bodies and commit messages repeat each one, and those are the
same author's record. Everything about the *tree* — merges, CI verdicts,
cache entries, assertion totals, which files a pull request changed — was
checkable and checked. A claim about method that nothing but its author can
confirm is the thing this project refuses from a model's column, and the
handoff has been making it about itself for six sections. The cheapest fix
is Felix's: the suite already regenerates `assertions.tsv`, and a red run
against the base ref could write its failed count beside it, so "shown red"
becomes a number in the tree.

**What the six sections left out.**

1. **#240 was the 0.49.112 bump**, the last version-only pull request.
   #236–#239 merged before #239's rule was live and none carried a version;
   the home pulled, `felix install` bumped 0.49.111 to 0.49.112, and the bump
   went back as its own pull request. §0bb's "no second version pull request"
   describes the rule from #241 on, not the four merges before it.
2. **#241 amended `projects/felix/CLAUDE.md`.** The non-obvious pattern that
   said engine *work* happens in the home checkout — the deadlock #2 was
   filed about — now says engine *deploys* do, and states the workflow #239
   made possible. The same pull request dropped
   `superpowers:finishing-a-development-branch` from the ship play: its
   procedure ends by handing a person a menu of what to do with the branch,
   and that menu is the thing the founder's direction removes. The reason is
   a comment above the row in `routes.tsv`, so the next session does not
   re-add it.
3. **#243 changed two templates.** `templates/obligations.tsv` and
   `templates/probes.tsv` carry the column documentation a new project
   starts from, and both now say what the code says: exit 1 is the only no,
   and anything else is unknown and blocks. A project commissioned before
   #243 keeps the old header text with the new reading — three of them do —
   which is a drift for the next template sweep.
4. **#250's row landed in one table.** `projects/elenchus/commissioning.tsv`
   gained `obligations_surveyed`; felix and veldra did not, so the only
   project whose commissioning writes a discovery request is elenchus.
   Decided here, not deferred: it stays that way until one real run has
   been read. A template row asks every future project to spend model time
   on a surface with no run behind it; the answer shape earns the template
   by surviving contact once.
5. **The devlog stopped at 2026-09-13 with #229–#234.** `felix log` was not
   run after that morning. Two entries backfilled at this close cover
   #236–#242 and #243–#251, and five lessons were recorded: a pipeline
   cannot be made to fail closed; `&` in an awk replacement is the matched
   text; a parallel edit batch loses roughly one first-touch edit in three;
   a verdict that can stop something failing needs a check beside it that
   something still fails; and claims about the machine and the calendar
   are read, not recalled.
6. **Issue #2 had no comment since 2026-08-14** although §0bc observed
   `felix merge` working from a worktree, the thing it was filed for. A
   comment now records that, and that step 5 is what keeps it open. And a
   finding from §0bc's v3.2 assessment that no later section carried — session
   start adopts capability rows on its own, which is policy produced by a
   relation — is filed as #252, with the dropped clause beside it: a
   gate that refuses a `stack.tsv` risk below the risk an inspection assigned.
7. **The public snapshot is sixteen pull requests behind.** `LeavesJ/Felix`
   last moved at 2026-09-13T10:33Z, at `3091a76`, before #236: every change
   in §0bb through §0bg is absent from the one thing other people can see.
   Updating it is a publish and the founder's; §0bb listed it and the four
   sections after did not.
8. **graphify is current, and the log does not say so.** The critic read
   `maintenance.log`'s last graphify row, 2026-09-12, as sixteen merges of
   drift. The check keys on `graph.json`'s modification time against the
   home head's commit date, and the graph (2026-09-16 18:24) is newer than
   main's head (18:15:54): the session-start refresh keeps it current, and
   the log records only recorded runs. Two things §0bb prescribed and no
   section confirmed: the home was pulled and reinstalled, and stands clean
   at main with ten untracked paths, unchanged by this session.
9. The personal memory index described the fact-gate note without its
   parallel-batch half; the line is updated. `SESSION_HANDOFF.md` is
   regenerated at this close with a note that is this session's.

**Next, in order.** The founder's: (1) the first real discovery run, which
this machine can now host — `felix commission` in the elenchus checkout
writes the request, a session there answers it, and `felix obligations`
shows what was proposed; commission and the spend are his. (2) The public
snapshot, a publish. (3) CI enforcement of `felix merge`'s blockers, which
needs GitHub Pro or an accepted advisory CI. (4) Grants for the high-risk
plugins whose hooks run in every session with no record. (5) Issue #2, step
5. (6) #252, the adoption issue: what session start may write on its own. Felix's,
in a next session: fold the gate's inline `installed` comparison onto
`felix_accepted_deploy_diff`; sweep the three projects' `probes.tsv` and
`obligations.tsv` headers to #243's wording; record the red-run count beside
the assertions so blind testing stops being self-report. Standing:
`projects/bazaar` and `projects/webapp` stay untracked, and elenchus's
missing `gate.sh` is the product's to write before its gate can run.

