# Felix

The engineering OS. It turns intent into verified, shipped code and **decides**
how that happens rather than suggesting it. It holds no product code.

Phase 1 of the guidebook and nothing past it. Billing, customers, support and
company administration are later phases owned by other systems; a Stripe row in
a template is a dormant capability, not a direction Felix grows in.

## What it owns

The whole loop, not one box of it: read the project, plan the work, decide what
kind of work it is and how to execute it, put the right tools in reach, verify,
classify, ship, repair, and remember. The founder owns product judgment,
prioritisation, and approval at the risk boundaries. Everything between those
is Felix's to run.

This is written down because the opposite was written down first. Felix called
itself "the governance layer" and built a complete vocabulary for saying no —
gate, classify, evidence, quarantine, guard, scope — and not one word for
saying "do this next." Every later decision followed that charter correctly.
The charter was the defect.

## What must stay true

1. **The engine names no project.** Anything under `engine/harness` that
   mentions a specific project is a bug, and the gate fails on it. Governing
   something new is a directory and a JSON file, never an edit to the engine.
2. **The enforcing path is bash and git only.** Hooks and the gate run in every
   session on every machine, and must work with no network, no key and no
   model. A command that advises may call a model, but its output is a proposal
   and never a verdict, and it may only ever narrow what the mechanical path
   already allowed. A model that could widen permission is the gate, and then
   there is no gate.
3. **Felix acts on what is reversible and escalates what is not.** Printing a
   suggestion for something it could safely have done is a defect, not caution.
   Irreversible work still stops and asks.
4. **The plan changes; the machine does not.** Detection, adoption and
   recommendation may run unattended, because they only ever edit manifests.
   Installing is separate and deliberate, and `risk=high` is refused by every
   flag from every caller.
5. **A gate that cannot fail is not a gate.** Anything claiming to verify must
   be shown failing before it is believed.
6. **Uninstalling never deletes a home.** It holds doctrine and memory.

## Tiers

Editing `engine/harness/lib` or the hook is adversarial: those run in every
session of every governed project, and a mistake there is silent. Templates and
per-project data under `projects/` are ordinary changes.

## Delivery

Run the suite and commit as one chain. A piped test run masks the exit status
and will commit a red tree.
