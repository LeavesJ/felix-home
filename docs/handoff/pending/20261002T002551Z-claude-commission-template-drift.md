### 2026-10-02: felix commission names every row that differs from the template's row for the same need

**Spec (written before any code; the blind assertions were written from this
section alone).**

**The gap.** A project's `commissioning.tsv` is cut from
`engine/harness/templates/commissioning.tsv` by `felix new`. After that it is
compared to the template only by need id: `felix_commission_template_missing`
names needs the template has and the project lacks. Nothing names a need both
tables carry whose row differs. So when the template corrects a row — as
`claude/commission-checks-read-to-end` does for seven checks that read `done`
when their lookup's substitution aborted — every table cut before the fix
keeps the old row, and nothing says so. That includes a table in a repository
Felix governs elsewhere, and a table added later from an old copy.

A project may change a row on purpose. So this is a report, never a refusal,
and it never writes a table: any change to `commissioning.tsv` moves the
policy hash (`FELIX_COMMISSION_TABLES`), stales the receipt, and lapses a
commission grant.

**Where it surfaces: `felix commission`, and nowhere else.** The section goes
directly after "questions the template asks that this table lacks". That
part of the output is shared by `--status` and the full run.
- Not the session-start notice. "Stealth in the middle" allows a line at the
  start, and the hook already says "Commissioning: receipt ..." once per
  topology from a seen-store that a drift line could share (corrected after
  review: the first draft said a new store would be needed). Two reasons
  decide against it. A session told about drift cannot act on it, because
  the remedy is a table edit, which waits for the founder's re-stamp. And an
  edit to the hook is red tier: it runs in every session of every governed
  project.
- Not `felix maintenance`. A maintenance row is either due or not. A row kept
  on purpose would be due forever, with no way to clear it.
- `felix commission` is the run that follows any change to the table. A
  person makes it after re-arming a stale grant with `felix autonomy --allow
  commission`, and it already prints the sibling report (missing needs).
  Re-granting is the consent, and this run comes after it, so the report
  reaches the person who changed the table, and anyone who asks with
  `--status` before then.

**Known limits, stated rather than built.**
- An engine upgrade that changes the template changes nothing a project's
  receipt or topology is keyed to, so nothing prompts the `felix commission`
  run that would print this. A table in another repository is named the next
  time a person runs `felix commission` there, and not before. Closing that
  means keying something to the template, for instance the hook's seen-store
  key. That would be a red-tier change of its own.
- Under a current commission grant, the run that re-commissions is the
  unattended one `felix_commission_resume_bg` starts at session start, and
  it sends its output to /dev/null. Drift is then seen only when a person
  runs `felix commission` by hand.

**Contract.**

1. `felix_commission_template_drift PROJ TPL` is a new function in
   `engine/harness/lib/commission.sh`. `PROJ` is a project directory and
   `TPL` is a templates directory; the tables read are `PROJ/commissioning.tsv`
   and `TPL/commissioning.tsv`.
2. Both tables are read through `felix_commission_rows`, the well-formed rows
   the engine actually runs. A malformed project row is not compared: it is
   `felix_commission_malformed`'s to name, and the engine never runs it.
3. For each project row whose need also has a row in the template, compare
   the six columns other than `need`: grounds, instrument, when, answer,
   check, step. When any differ, print one line:
   `need<TAB>columns`. `columns` names each differing column, separated by
   single spaces, in table order (`grounds instrument when answer check
   step`). The brief named check and answer; the other four are compared
   because `when` is eval'd like `check`, and grounds, instrument and step
   each change what state a row can reach. Comparing all six costs nothing
   more.
4. The comparison is exact, byte for byte, on the fields as
   `felix_commission_rows` emits them. (Corrected after the blind pass: the
   draft said an empty grounds, instrument or when reads as `-`. It cannot,
   because a read with IFS set to a tab folds an empty cell into its
   neighbour. Such a row reads shifted, is malformed, and is not compared.)
5. Lines come out in the project table's order. A need found only in the
   project prints nothing (a project may add needs). A need found only in the
   template prints nothing here (`felix_commission_template_missing` names it).
6. If the template carries a need twice, its first row is the template's row
   for that need. If the project carries a need twice, each row is compared
   on its own, because the engine runs each.
7. Exit status: 0 when the comparison was made, whether or not anything
   differs. 1, printing nothing, when the template table is absent or yields
   no rows. "Nothing differs" and "nothing was compared" must not read the
   same. An absent or empty project table prints nothing and exits 0. (The
   command never reaches this section then: it has refused such a table
   already.)
8. It writes nothing anywhere: no table, no state, no memory.
9. It must work when its caller has `IFS` set to a tab, and under `set -o
   pipefail`. It may not name a project (invariant 1).

**Rendering in `cmd_commission`.** When the function prints lines, show the
heading, then one line per row: two spaces, the need padded to 22, the
columns. Then a short note covering three things:
- a project may keep its own row on purpose, so this refuses nothing;
- a row cut from an older template keeps what that template had, and the
  template table's path is shown;
- changing a row here changes the table set. The receipt reads stale until
  `felix commission` runs again, each provider row's answer goes stale (the
  topology hashes the table), and a commission grant, where there is one,
  stops covering the table until `felix autonomy --allow commission` is run
  again. The grant clause was made conditional after review: three of the
  five projects here have no grant, and the engine's merge text already
  declines to ask for a consent a project never gave.

When the function returns 1, say that the template could not be read or
holds no row this engine runs, so no row here was compared with it. When it
prints nothing and returns 0, print nothing. `felix commission`'s exit
status does not change for any of this.

```
rows that differ from the template's row for the same need

  probes                 check
  stack                  answer check
```

**Built as spec, blind assertions, implementation shown red, mutations,
adversarial review.** One workflow, five agents. The red, green and mutation
runs used a section runner: the suite's preamble, the claude stub and the
commissioning fixture, then the block, run against any engine in about a
second. No suite was run, by the carrier's rule.
- Blind (Opus, xhigh): 42 assertions, written from the spec alone before any
  code existed. Against main's engine (27573cbe), 30 fail and the 12 controls
  pass. The author ran 16 mutants of a scratch oracle, and every one was
  caught. Two first drafts could not fail for the reason they named, and
  both were fixed: the writes-nothing check reused dirty directories, and a
  900-row pipefail template lost its race on some runs.
- Implementation (Sonnet, high): 42 of 42 green, no disputes.
- Mutations (Sonnet, high): 35 mutants, 31 caught. The four that got
  through:
  - a write into the memory root;
  - a write into the home's state;
  - a full run exiting 1 on drift;
  - one equivalent mutant.
- Review, defeat lens (Opus): ship with fixes. It found:
  - awk compared numeric-looking fields as numbers, so `1` matched `1.0`;
  - the full run was never asserted, and three full-run mutants passed,
    one of them rewriting the table;
  - one assertion's name claimed an empty-equals-dash case that cannot
    occur;
  - the unattended run's output goes to /dev/null.
- Review, simpler lens (Opus): ship with fixes. It found:
  - the grant clause was printed to projects that have no grant;
  - the "could not be read" line also fires for a template that is readable
    but has no row the engine runs;
  - the note left out that provider answers go stale;
  - the template path pointed at the directory, not the table;
  - the comment gave the wrong reason for capturing the tables;
  - the spec's case against the session-start notice overstated the cost.

  It upheld the separate function, all six columns, and `felix commission`
  as the only surface.

**What changed after review.**
- Fields are compared as strings.
- The note is reworded on the engine's own facts: the grant clause is
  conditional and names the re-arming command, provider answers going stale
  is added, and the table's path is printed.
- The rc=1 sentence covers both causes.
- The comment says what the capture is for.
- Nine assertions were added and two renamed, giving 51:
  - one numeric case;
  - the empty-cell row now asserted malformed, under a name that says so;
  - the writes-nothing check run against a fresh memory root and home;
  - three note phrases;
  - full-run assertions on a project fixture of their own, removed
    afterwards: the section appears, the exit status matches the same run
    without drift, the table is unchanged, and a control that the run with
    no drift prints no section;
  - a control that the fixture leaves no file behind.

**Evidence, final head.**
- Section runner: 51 passed and 0 failed on the branch, under /bin/bash
  3.2.57. Against main, 34 fail and the 17 controls pass.
- Every mutant that got through before is now caught: the memory-root write,
  the home-state write, the full run printing nothing, the full run exiting
  1, the full run rewriting the table, and the grant command dropped. The
  numeric case is caught when both string conversions are reverted. Either
  one alone already forces a string comparison.
- independence-scan is clean.
- The block costs about 4.3 s of CPU, against a 0.4 s baseline for the
  fixture alone. Most of it is reading the 2000-row pipefail template twice.

**On real tables** (the function called directly, nothing written):
- Against this branch's template, every table under projects/ prints
  nothing. So do #388's webapp and behaviorchangebench tables.
- Against the template on `claude/commission-checks-read-to-end` (521e0757),
  each table that branch has not yet rewritten reports 10 rows, all `check`:
  envelope, gate_declared, probes, obligations, discover, stack, preflight,
  reach, baseline and human_steps. elenchus and veldra report 9, because
  they have no obligations row; that need shows as missing, not as
  differing.

**Landing (weekly batch, after the re-stamp tail; the carrier's call).**
- No commission table changes, so it does not stale any commission and
  needs no re-stamp.
- At the slot:
  1. Merge main.
  2. Run `tests/run --record-assertions`. The 51 new assertions are not yet
     in assertions.tsv.
  3. Run `tests/red <base>`, then `felix gate`, then `felix merge`.
- Likely conflict: tests/run only, since every queued branch appends tests.
  The engine hunks sit at the end of lib/commission.sh and at about
  felix:4940, where no queued branch touches.
- After it lands and is deployed, `felix commission --status` in a project
  whose table predates a template fix names the rows. Once read-to-end has
  landed and #388's tables have been rewritten, there should be none here.
