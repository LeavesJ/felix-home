## 0aq. Verified at session close, 2026-09-06 — three items the founder ordered, and a checker that does not catch what it protects

| | |
|---|---|
| head | `main` (#200–#204, five merges), CI `gate` **success** on each |
| suite | **1639** passed, 0 failed |
| graph | 1449 nodes, 1819 edges, 149 communities, refreshed and recorded |
| the founder's order | graphify, then PR 4, then checker qualification — all three |

### 1. graphify: the founder was right, and the fix is structural

The row was due, refreshed, recorded, due again inside one PR. The founder read
that as an ordering problem. Measured in a scratch repository: refresh → record
→ commit gives `due`; record → commit → refresh gives `ok`. So yes.

Shipping only the ordering would leave a procedure nobody encodes, so the check
is fixed instead and both orders now work. A cadence-0 row records its run in
`maintenance.log`, and that write must be committed — so the commit saying "the
graph was refreshed" was itself a commit the graph had not seen. The check now
excludes that cadence record, which is sound rather than convenient: **the log
is not in the graph's corpus at all** — 103 entries, no `.log`, no `.tsv` — so a
commit touching only it changes nothing the graph models.

Shipped in the template, since the engine seeds this row for every project and
all three governed ones carried it. Proven end to end on real data afterwards:
refresh, record, commit, still `ok`.

### 2. PR 4: granted, and it is not what §0ap said it was

An adversarial review of the design **before it was built** (29 agents, 21
findings refuted, 5 survived) changed it twice.

**What it is honest about.** The design rested on admit.sh's "install: proceed
with nobody present" and argued the grant merely made an existing column
reachable. That reads as a no-op and is not — every install path in the engine
is downstream of a command a person typed. The doctrine now states the thing
itself: the pipeline evaluates two columns of `commissioning.tsv` as shell, and
granting this puts them on a hook path.

I checked the review rather than taking it, and **one half of it is wrong for
this code path**: it claimed a granted run would `stack apply --yes` in the
same run. It would not. `felix_commission_apply_declares` writes a row and a
log line; no installer is downstream. A run *declares*. That is now asserted
where an install would have to happen, with a positive control, rather than
argued.

**What it is bound to.** The half that stands, and it is structural. Every
other grant names an action the engine defines; this one names a pipeline whose
steps come from an ORDINARY-tier project table. So the grant is stamped with
the policy version when a person types the command, and a background run
refuses when the table has changed since. `felix autonomy` renders that as
`[!]`. Re-granting is a person's act of reading what changed.

**It is ungranted, and this session did not grant it to Felix.** One command,
and it is the founder's: `felix autonomy --allow commission`.

Two defects that existed all along came out of the same review and shipped
first, on their own merit (#202): `cmd_commission` held no mutex, so two runs
could interleave appends into one manifest; and the fetch had no deadline and
no `GIT_TERMINAL_PROMPT=0`, so it could hang or prompt where nobody was
watching.

### 3. Checker qualification found two real holes on its first run

`felix qualify` runs six controls per checker — a mutation into a throwaway
worktree of HEAD, then the checker, then the verdict a checker worth having
must give. Report only; **arming is still the founder's call** and turns every
gate red the day it lands.

Felix's only credential check:

```
  violation                fail  fail  ok
  restoration              pass  pass  ok
  irrelevant               pass  pass  ok
  alternate                fail  pass  HELD
  decoupled_violation      fail  pass  HELD
  decoupled_satisfaction   pass  pass  ok
```

Both verified by hand, because a held control can also mean a mutation that
never landed. **`secret-scan` does not catch a token in a GitHub Actions
workflow** (its keyword pattern requires a *quoted* value, and YAML's is
unquoted), and **it has no pattern for `scheme://user:password@host` at all** —
a live-shaped Postgres password in a tracked library passes cleanly. Exactly
what amendments §2.1 says control 5 is for.

Fixing the scanner is deliberately the next PR: the file's own header says the
exclusions are the load-bearing half, and it now has a regression test waiting.

The mutations were authored blind, per §2.2 — a subagent given the obligation
in prose and forbidden the checker's source. Unverifiable from inside, so the
table records the method rather than claiming the property.

### What this session got wrong, and how it showed

Three times, and each was caught by something rather than noticed.

- An assertion that "a commissioning run installs nothing" **passed over an
  empty stub log** — it meant only that the run never reached the CLI. Its own
  positive control caught it. Moved to the function that applies a verdict.
- The qualification table was **flagged by the checker it qualifies**, correctly:
  a table of credential mutations is credential-shaped. Worse, once committed
  it poisoned every worktree the runner made, so all six controls read `fail` —
  a poisoned baseline does not make a suite noisy, it makes it meaningless.
- A scratch fixture reported `due` where the code was right; it was BSD `find`
  comparing `-newermt` at whole seconds, the trap this repo already documents.

### For the next session

**Fix `secret-scan`'s two holes.** The qualification table is the regression
test; both controls must turn from HELD to ok without the other four moving,
and without regressing the exclusions that stop it crying wolf.

**Arming qualification** and **granting commission** are both the founder's,
and both are one line.

