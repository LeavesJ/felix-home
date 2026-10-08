### 2026-10-01: every other reader of the declared capabilities says the list could not be read, never that it is empty

Stacked on claude/cap-unread-callers (0534ee25), which merges
claude/commission-lookup-fails-unknown (8d508021). Both land first, in the
carrier's order; this branch merges main after they do. The engine change is
in lib/detect.sh, lib/probes.sh, lib/discover.sh, lib/toolbox.sh,
lib/procedures.sh, lib/commission-provider.sh, lib/commission.sh,
lib/candidates.sh, felix and hooks/session-start; the rest is in tests/run.

**Defect.** After lookup-fails, `felix_declared` returns 0 for a list it read
(empty or not) and 2 when something is at `capabilities` and could not be read
(a link whose target is gone, a directory, a pipe, a grep that failed). And a
substitution around it can come back empty with no failure at all: a fork that
fails with EAGAIN inside it (kern.maxprocperuid 2666, machine load 100-300), or
on bash 3.2 a substitution that cannot make its pipe, which expands to nothing
with status 0. `_felix_cap_active` guards that with a `.` written only after
`felix_declared` returned 0. Every other reader still read an unread list as
an empty one, and each made a false claim from it:

- `felix recommend` printed `declared: none` and `waits for <cap>`.
- `felix doctor` printed an empty `declared:` line, and `felix_undeclared`
  called every detected capability undeclared drift. Session start adopts
  whatever `felix_undeclared` prints, so it adopted capabilities that may
  already be declared.
- `felix_probes_gaps` dropped every declared-only capability from the gaps,
  and `felix_probes_orphans` called a probe grounding one an orphan.
- `_felix_discover_rules` dropped every declared capability, so discovery
  scored nothing and the quiet form cached "nothing matches" for seven days.
  `felix_capabilities_unruled` said no capability lacked a rule.
- `felix_procedures_items` dropped the declared items, so the gap list shrank
  and the report could say every item had a stance.
- `felix_commission_topology` hashed a different list, so every provider
  answer read stale, and `felix_commission_request` wrote a request naming
  the wrong capabilities under the wrong topology.
- `felix_commission_gaps` (lib/commission.sh, not in the brief, same shape)
  dropped declared capabilities from "surfaces nothing serves".

**Contract.** Written before any code, and the only thing the blind
assertion author was given. WHY below is the exact phrase
`the capabilities this project declares could not be read`, the one
claude/cap-unread-callers already prints. "Unread" means any of:
`felix_declared` returned nonzero; it printed capabilities and then returned
nonzero; or the substitution that ran it ended before anything was printed
after it returned 0 (modelled in-process by `felix_declared() { exit 0; }`).
Out of process (the CLI, the hook) it is modelled by a `capabilities` link
whose target is gone. "Read" means the list was read, including an empty list
or no file at all, and on a read list every function and command below
behaves exactly as before this change.

1. `felix_declared_into NAME PROJ` (new, lib/detect.sh). Read: assigns the
   variable named NAME the declared lines, one per line, with no trailing
   newline (the empty string when nothing is declared or there is no file),
   and returns 0. Unread: returns 2 and does not assign NAME.
2. `felix_undeclared ROOT PROJ`. Unread: prints nothing, returns 2.
3. Session start. When `felix_undeclared` returned nonzero or its output did
   not come back whole, it adopts nothing and its context carries the line
   `Capability drift was not checked: WHY.`
4. `felix doctor`. Unread: the declared line is
   `declared:     not known: WHY`, the undeclared line is
   `undeclared:   not known: WHY`, and neither `undeclared:   none`, the
   detected surfaces, the paragraph beneath them nor `adopt with:` is printed.
   The unruled section is the line
   `capabilities with no discovery rule: not known: WHY`. Exit 0, as before.
5. `felix recommend` (no `--want`). Unread: the header line is
   `declared:   not known: WHY`, never `none`; a catalogue row whose
   capability is not `always` reads `not known whether <cap> is active here`,
   never `waits for <cap>` nor `<cap> is active here`; the handoff line says
   `Felix already detected: not known: WHY`. Exit 0.
6. `felix_probes_gaps PROJ ROOT` and `felix_probes_orphans PROJ ROOT`.
   Unread: each prints nothing and returns 2. `felix probes`: in place of the
   gap section, `surfaces nothing probes: not known: WHY`; in place of the
   orphan section, `probes for surfaces nothing enumerates: not known: WHY`.
   Exit as before.
7. `_felix_discover_rules TPL PROJ` and `felix_capabilities_unruled PROJ TPL`.
   Unread: each prints nothing and returns 2 (the latter still returns 0,
   printing nothing, when the template has no discover-rules.tsv).
   `felix_discover_candidates PROJ TPL`: 3 when there is no `claude` (checked
   first, as before); 2 when the rules could not be read, printing nothing and
   without asking the marketplace. `felix discover`: on 2, prints
   `Nothing was scored for <project>: WHY.` and that this is not "nothing
   matches", caches nothing, adopts nothing, exits 2; `--quiet` prints nothing
   at all (no stamp) and exits 2. `felix discover --adopt` whose cache is not
   current checks the list before filling the cache, and on unread prints the
   same sentence, fills nothing, adopts nothing and exits 2. The `--quiet`
   form reads the rules once and re-scores every fetched candidate against
   that one read; an unread read there prints nothing and exits 2.
8. `felix toolbox` (with or without `--route`). Unread: after
   `toolbox for <project>`, prints `Nothing was matched or wired for
   <project>: WHY.`, prints no plugin table and no `reachable` count, wires
   nothing, exits 2. `felix_toolbox_unwired PROJ [TPL]`: unread prints the
   one line `?<TAB>WHY` and returns 2, so a check asking only whether it
   printed anything does not read an unread list as nothing left to wire.
9. `felix_commission_admit PROJ HOME NEED [TPL]` for a five-field need.
   Unread: prints the one row
   `unknown<TAB>-<TAB>-<TAB>-<TAB>-<TAB>-<TAB>WHY, so no nomination was matched to one`,
   fetches nothing, returns 2. Other shapes return 0 before reading, as
   before.
10. `felix_procedures_items PROJ ROOT`, `felix_procedures_gaps PROJ ROOT TPL`
    and `felix_procedures_orphans PROJ ROOT`. Unread: each prints nothing and
    returns 2. `felix procedures`: prints a line holding `not known: WHY`, and
    neither `nothing answers these`, `stances for things nothing enumerates`
    nor `Every item has a stance`. The stance, malformed-row and
    unknown-moment sections, which do not read the list, print as before.
    Exit 0.
11. `felix_commission_topology PROJ ROOT`. Unread: prints nothing, returns 2.
    `felix_commission_provider_state` over an answer file that exists, when
    the topology could not be computed: prints
    `unknown<TAB>the topology the answer at <file> is keyed to could not be computed: WHY`,
    never `stale`, `partial` or `answered`. No answer file is still
    `awaiting`. Session start then names that row among the unread ones and
    says no all-clear.
12. `felix_commission_request PROJ ROOT NEED TPL`. No template is still 1,
    checked first. Unread: returns 2, prints nothing, and leaves any request
    file already there as it was. `felix_commission_run` with a runner: a
    provider row whose request returned 2 is `unknown`, its detail
    `the request for <need> could not be written: WHY`, not "no request
    template". `felix_candidates_request` returns 3 when the request returned
    2 (2 stays the epoch's refusal), and `felix obligations --request` then
    prints `no request written: WHY.` and exits 1.
13. `felix_commission_gaps PROJ ROOT`. Unread: prints nothing, returns 2.
    `felix commission` and `--status`: in place of the gap section,
    `surfaces nothing serves, reaches, or grounds: not known: WHY`.
14. Added 2026-10-08, when the merge of main brought in #378, which gave
    `felix commission` a reader of its own: before a full run asks any row,
    it adopts every capability the checkout shows and the project has not
    declared, from `felix_undeclared` through a here-document nobody checked.
    Unread (out of process, a dangling `capabilities` link): it adopts
    nothing, leaving `capabilities`, `stack.tsv` and `setup.tsv` as they
    were; prints no `adopted before this run` line; prints
    `Capability drift was not checked: WHY.` after `commissioning for
    <project>` and before the first row; and still asks and prints the rows
    and the summary. Read: as before, including the adoption line, and never
    the drift line. `--status` adopts nothing and prints neither line. The
    exit status is not part of this item.

Not in this change, and why:
- `felix_adopt_capability` (lib/adopt.sh) `touch`es `capabilities` before
  reading it, which writes through a dangling link. Session start no longer
  reaches it on an unread list; `felix adopt <cap>` by hand still does.
- `_felix_mon_project` (lib/monitor.sh) reads `capabilities` itself with
  `-f`, so the monitor page shows `[]` for a dangling link. It is a JSON
  shape the page's script reads, and a change there is the monitor's.
- `felix_detect` fails the same way under EAGAIN and reads as nothing
  detected. That is the other half of every union above, and a separate
  lookup.

**After review: what changes.** Three Opus reviewers (defeat, simpler,
omission) read fd5528f7 and 1e0197ca and demonstrated each finding with the
section runner. Taken:

R1. Blocker, found by all three. On a project with no commissioning.tsv,
    `felix_commission_topology` took its status from the `cat` of that table,
    so under pipefail (the CLI and the hooks) it returned 1 over a list that
    was read. Its new callers read that as unread: `felix obligations
    --request` refused with a false reason and an answered obligations
    request read `unknown` and was never taken in. Fixed: the topology's
    status is 2 only from the declared read and otherwise the hash's; a
    missing table is `|| :`, and the bytes hashed are unchanged.
R2. `felix discover --adopt` read the list only when the cache was stale; a
    current cache over an unread list adopted rows and asked claude to
    install. Fixed: every `--adopt` reads the list first. The fill's own read
    can still fail after that check, so the quiet form now exits with the
    status it refused with (2 rules unread, 3 catalogue unreadable) and the
    fill says which.
R3. Once read, the list still reached its claim through here-documents (a
    temporary file on bash 3.2) and nested substitutions whose status nobody
    checked, so a fork that failed there (EAGAIN, the case this branch is
    about) or a here-document that could not be written dropped a list that
    was read, and the function still returned 0. Fixed: one capture helper,
    `felix_capture NAME CMD [ARGS...]`, holds the sentinel test once (it
    replaces the eighteen copies the first pass wrote out, and
    felix_declared_into is one line over it); the unions of detected and
    declared capabilities are one function whose status is its pipeline's,
    with the declared half printed first; and the loops over a list that was
    read walk the string in the shell, with membership by `case`, never a
    here-document or felix_has_line.
R4. `felix_commission_policy_version` reads every table with `cat`, so a
    `capabilities` link whose target is gone hashed as no file, and a pipe
    by that name hung every receipt check (622 s measured). Fixed: a table
    that is there and is not a regular file hashes as a marker line and is
    never opened.
R5. The sentinel was `.`, which a failed felix_declared could forge with a
    last line ending in a dot (`billing.`), because a substitution strips the
    trailing newline. Now `\n.`, forgeable only by a last line that is
    exactly `.`.
R6. Smaller: session start says why a provider row's topology could not be
    computed; `felix obligations --request` stops blaming the epoch for a
    missing request template; the dead `|| x=""` clauses go with the helper.

Not taken, and why:
- The commissioning `reach` row over an unread list now reads `held` (the
  check `[ -z "$(felix_toolbox_unwired ...)" ]` sees the `?` line and fails),
  where `unknown` would be the honest state. It no longer reads `done`. The
  check text is in projects/*/commissioning.tsv, a founder's table, so the
  change to an `unknown` is queued, not made here.
- felix_detect's own failures under EAGAIN, the rules table's and the probe
  rows' reads: other lookups, unchanged, named above.
- _felix_cap_active keeps its own `.` read: it is the dependency's, with
  shape assertions of its own, and moving it onto the helper belongs there.
- felix_declared reading a binary file as a list, GREP_OPTIONS, a BOM:
  felix_declared's own input, queued separately.

**After the second review.** On 2026-10-08 two Opus reviewers read the
after-review delta 739ac3bd..c23ec7d1f, one looking for defeats and one for
simplicity and truth. R1, R2 and R5 held. R3 held in the libraries but not
in the CLI. R4 held except for a regular table that cannot be read. R6 held
only when the failure persists. A Sonnet implementer fixed what follows,
tests first (17 of 35 red against 4ccc9e09). An Opus checker then read that
round and found one regression in it, fixed by hand (3 of 40 red against
8b3a6ae9). Taken:

R7. Blocker. `felix procedures` captured its gaps whole, then counted them
    with `$(printf ... | grep -c .)` and keyed the gap section and the
    all-clear on the count. A `grep -c` whose fork failed printed `Every
    item has a stance` over real gaps. `felix recommend` (`declared: none`)
    and `felix doctor` (an empty `declared:` line) joined a list they had
    read through `tr` in an unchecked substitution in the same way. Fixed:
    the sections key on the captured strings, the counts are taken in the
    shell, and the joins are parameter expansions, byte-identical on a read
    list.
R8. The stances still reached the report through here-documents and
    `felix_has_line`: in felix_procedures_effective, in
    felix_procedures_unknown_moments, and in the CLI's stance section. The
    round fixed only the first. The checker showed that this made one case
    worse: where a here-document could not be written, a stance at a moment
    nobody declared vanished, and the report closed on `Every item has a
    stance`, which the code before the round did not print. Fixed: all three
    walk the stances in the shell. `felix procedures` captures each list it
    speaks from once, and withholds the closing claim when one did not come
    back whole, saying so. The `_durc` assertion meant to catch this ran
    before any stance existed, so it could not fail; it now writes one first.
R9. The policy version hashed a regular table that cannot be read
    (mode 000) exactly like no table. It now hashes as `<unreadable>`.
R10. Session start took its reason for an unknown provider row from its own
    topology capture, a second computation that can disagree with the
    row's. Now each unknown row is printed with its own detail,
    `<need> (unknown: <detail>)`, and the separate sentence is gone.
R11. `felix_commission_request` read the list and built the union twice:
    once for the names, and again inside the topology. One read now serves
    both (`_felix_commission_topology_of UNION PROJ`), and the topology's
    bytes are pinned to a literal hash that the base engine (f2d0e6a5) and
    main (6fe5f986) agree on.
R12. Comments that said the opposite of what was measured (the probe gaps
    and orphans, the unruled list, the commissioning gaps), or claimed more
    than the code guards (felix_capture, the union, felix_undeclared, the
    _durc header, session start's topology), now say what is true. The test
    of felix_capture's trailing newline can now tell one newline from all of
    them.

Assertions restated, not only added: R10 changed the text session start
prints for an unknown row. So one assertion in the blind `_durb` block, three
in cap-unread-callers' block (`cucr_unread (unknown: the rows of the answer
could not be counted)` among them) and one in `_durc` now expect the row's
detail; one more `_durc` assertion was changed by R8. Each was red against the
code before its fix and green after it. The
`_durb` one was written blind; it is restated, not reinterpreted. Its row is
still named, and its control still matches any `(unknown`.

Not taken in the second review:
- felix_commission_topology's `cat` of commissioning.tsv hangs on a pipe.
  That predates this branch, and claude/adopt-newline-before-append (which
  carries table-readers-keep-unended-line) already guards it. That branch
  also guards felix_commission_policy_version, but hashes a non-regular
  table as absent where this one hashes `<not a regular file>`. Its carrier
  agreed on 2026-10-08 to keep the marker: a dangling `capabilities` link
  must not hash like no file, since felix_declared returns 2 for one and 0
  for the other. Order agreed that day without a carrier: adopt-newline
  0.49.274, autonomy-revoke .275, cap-unread-callers .276, this branch .277,
  with landing order deciding. Landing step: restate that branch's three
  `rkl` FIFO assertions to expect `<not a regular file>`, keeping the 8 s
  bound and the never-opened pipe. They are stack.tsv a FIFO, stack.tsv a
  link to a FIFO, and commissioning.tsv a FIFO (tests/run 42756-42762 on its
  e5ab42be). The two regular-table neighbours stay as they are.
- Keeping each failure's status through felix_capture. The reviewers wanted
  3 for a union that could not be made. felix_capture and
  felix_declared_into are what claude/monitor-capabilities-unread and
  claude/declared-not-text build on, so their signatures and statuses stay.
  A union or hash that could not be made is reported in the declared list's
  words, and the comments say so. The one test that pinned that phrase as
  the cause over a list that was read (session start, `_dure`) now asserts
  only the row and its topology.
- One helper for the in-shell string walks. The copies are identical. A
  helper that pops a line through `${!2}` would not make its callers
  smaller, and the lists are a few dozen lines.
- Flagged as tasks of their own, all predating this branch:
  - felix_repo_root spins forever on bash 3.2 when a write fails at the head
    of its path.
  - Session start walks the commissioning rows through a here-document
    nobody checks, so a read that came back empty gives the receipt
    all-clear over owed rows.
  - recommend's "Already declared" line and the request's {{DECLARED}} join
    stack.tsv through `tr` in a substitution.
  - Display loops over strings already read still pipe them, and only for
    display: the doctor unruled loop and the recommend missing-rows loop.

**Evidence.** Section runner: one tests/run block after the suite's
preamble, run from an empty temporary directory against an engine exported
with git archive. This is not the record, which is taken at the landing
slot. Taken 2026-10-08. The scratch directory was emptied by a reboot, so
the first-pass red was re-taken against these shas:

| block | assertions | red against | green at cc3283ac |
|---|---|---|---|
| blind, both halves (`_dura`, `_durb`) | 79 | 47 at origin/main 6fe5f986 and at the base f2d0e6a5 | 79 |
| after review, not blind (`_durc`) | 30 | 24 at the first pass 1e0197ca | 30 |
| item 14, blind (`_durd`) | 24 | 2 at the merge 5a8d0ff8, 5 at main | 24 |
| after the second review, not blind (`_dure`) | 40 | 17 of 35 at 4ccc9e09; 3 of 40 at 8b3a6ae9 | 40 |
| cap-unread-callers' own block | 43 | 21 at main | 43 |

The blind count was the same on 2026-10-01, against the main of that day. A
`_durc` or `_dure` assertion that makes here-documents unwritable fails only
where bash writes a small here-document to a temporary file (3.2 among them).
On a bash that pipes it, the defect it names cannot occur, and the assertion
passes. The suite's own sections for detection, rival gates,
recommendations, procedures and doctor gave identical results line for line
at 4ccc9e09 and after the second review's fixes, as did the procedures
section at 8b3a6ae9 and after the last fix. On a read list, the CLI output of
procedures, recommend and doctor over three declared lists was
byte-identical at 4ccc9e09 and after.

**Ruled in review.** `felix discover --inspect --quiet` now exits 3 when the
catalogue cannot be read, where it exited 2 before; 2 now means only that the
rules could not be read. The existing assertion that named the old status was
changed with it (2b38426a). No consumer reads the value: the background
refresh tests only for success, and `--adopt`, the one new reader, branches
on both.

**Outside the tree.** The first-pass implementer ran a command that rewrote
~/.felix/memory/felix/commission/requests/obligations_surveyed.md in real
memory. The bytes came out identical; only its mtime moved. On 2026-10-08 a
section-runner block cut short of its fixtures (`_fs_wr` empty) ran `git remote
set-url/remove/add origin` in this worktree. A worktree's .git/config is the
shared one, so felix-home's origin was removed and re-added as acme/widget,
and every branch lost its upstream. Another session repaired it. At 20:20Z
origin was LeavesJ/felix-home again, and all 196 local branches with a
branch of the same name on origin had their upstream back. The runner now
runs every block from an empty temporary directory and refuses one inside a
repository.
