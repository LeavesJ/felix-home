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
