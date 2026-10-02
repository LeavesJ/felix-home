# behaviorchangebench

Governed by Felix. This file is the project constitution: what is true
about behaviorchangebench and nothing else.

## Verification

Run the gate before claiming anything is done.

```bash
felix gate
```

It runs `make check` in this checkout.

## What this project has

Detected at onboarding. `felix doctor` keeps this honest as it changes.


## Invariants

Empty on purpose, and not for long.

These are the things no linter can catch, and they are earned rather
than invented. The gate records what it catches in `memory/mistakes.log`.
Anything it catches twice shows up in `felix promote`. A mistake that
keeps happening becomes a lesson; a lesson that keeps being violated
has outgrown the lessons file and belongs here, where the gate can see
it.

Write them down as they arrive. A constitution invented on day one is
either empty or borrowed.

## Risk

Tiers live in `risk.tsv`, evidence requirements in `evidence.tsv`, both
beside this file. `felix classify` and `felix evidence` read them, and
nothing red is ever touched unattended.
