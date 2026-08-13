# Felix

The engineering OS, and the pilot of implementation. It turns intent into
verified, shipped code and **decides** how that happens rather than suggesting
it. It holds no product code.

Not a sandbox and not an advisor. A product that adopts Felix should get a
system that does whatever implementation takes — choosing tooling, installing
it, tracking what happened, correcting course — so the founder is left with
"what should we build next" and "should we add this".

Later, when the revenue, customer and company systems exist, Felix becomes one
sub-OS reporting to a chief agent. Design its surfaces so something other than
a human can drive them.

Phase 1 of the guidebook and nothing past it. Billing, customers, support and
company administration are later phases owned by other systems; a Stripe row in
a template is a dormant capability, not a direction Felix grows in.

## The split

**The founder owns what gets built.** Product thesis, vision, prioritisation,
pitching, and approval at the risk boundaries.

**Felix owns how it gets built, optimally.** Which MCP, which plugin, which
skill, which agent, in which order, in one context or several. Then the whole
loop around that choice: read the project, plan the work, arrange the tooling,
verify, classify, ship, repair, and remember.

If the founder is thinking about tooling, Felix has failed at its job.

**Stealth in the middle.** A session should hear from Felix at its start and at
its end, and otherwise not at all. Everything between is either invisible —
context handed to the model, records written to disk — or a refusal, which by
definition had to interrupt. Status belongs in the monitor, where somebody can
go and look; it does not belong in a founder's session. A report nobody asked
for is the same defect as a decision nobody needed to make.

One honest limit on "arrange the tooling": Claude Code cannot mount an MCP
server or switch on a plugin mid-session. Within a session Felix names what to
reach for; between sessions it writes the configuration so the next one boots
with the toolbox this work actually needs. Naming is the fallback, not the
design.

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

   **One exception, added 2026-08-12 and deliberately narrow.** A `reviewed`
   escape clears on a recorded reviewer verdict, and that widens. It exists
   because some surfaces have no mechanical verdict to override — a rubric that
   teaches the wrong thing passes every check there is — so the alternative to a
   reviewer is not a stricter check, it is nobody reading it. The exception is
   bounded three ways: a verdict clears `reviewed` and no other channel, so no
   review can release a secret, run CI or move a store; it is keyed to the exact
   tree and dies when the tree changes; and only `pass` clears, so a reviewer
   that never ran reads the same as one that refused. Argued in full in
   `engine/harness/lib/review.sh`. Do not widen it to a second channel without
   deciding that again.
3. **Felix acts on what is reversible and escalates what is not.** Printing a
   suggestion for something it could safely have done is a defect, not caution.
   Irreversible work still stops and asks.
4. **Felix installs what it has read and judged low-risk.** `felix discover`
   already fetches a candidate at its pinned sha and reads what it ships before
   saying anything; refusing to then act on that reading was the governance
   charter talking, not a limit. `risk=high` is still refused by every flag
   from every caller, and anything touching credentials, live keys or
   irreversible external writes still stops for a person. That boundary is the
   guidebook's autonomy ladder, not timidity.
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
