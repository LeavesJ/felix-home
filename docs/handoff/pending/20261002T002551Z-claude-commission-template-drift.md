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
  start, but a row a project keeps on purpose would be named in every
  session, a report nobody asked for. Once-only would need a new seen-store
  in the hook, which is the adversarial tier, and every session would pay
  for a rare case.
- Not `felix maintenance`. A maintenance row is either due or not. A row kept
  on purpose would be due forever, with no way to clear it.
- `felix commission` is where a person consents to a table. It is the run
  the founder makes to re-stamp after any table change, and it already
  prints the sibling report (missing needs). The difference shows at the
  moment someone is deciding about the table.

**Known limit, stated rather than built.** An engine upgrade that changes the
template changes nothing a project's receipt or topology is keyed to, so
nothing prompts the `felix commission` run that would print this. A table in
another repository is named the next time a person runs `felix commission`
there, and not before. Closing that means keying something to the template;
that is a separate decision.

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
   `felix_commission_rows` emits them. That function writes an empty
   grounds, instrument or when as `-`, so empty and `-` do not differ.
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
  template's path is shown;
- changing a row here changes the table set, so the receipt reads stale
  until `felix commission` runs again, and a commission grant has to be
  given again.

When the function returns 1, say that the template could not be read, so no
row here was compared with it. When it prints nothing and returns 0, print
nothing. `felix commission`'s exit status does not change for any of this.

```
rows that differ from the template's row for the same need

  probes                 check
  stack                  answer check
```
