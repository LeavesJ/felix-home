# Felix

The governance layer. It holds the constitution, the gate, and the memory for
the projects we build, and it holds no product code.

## What must stay true

1. **The engine names no project.** Anything under `engine/harness` that
   mentions a specific project is a bug, and the gate fails on it. Governing
   something new is a directory and a JSON file, never an edit to the engine.
2. **Bash and git only.** Felix governs projects in languages it must not
   require. No jq, no python, no node in the engine.
3. **The plan changes; the machine does not.** Detection, adoption and
   recommendation may run unattended, because they only ever edit manifests.
   Installing is separate and deliberate, and `risk=high` is refused by every
   flag from every caller.
4. **A gate that cannot fail is not a gate.** Anything claiming to verify must
   be shown failing before it is believed.
5. **Uninstalling never deletes a home.** It holds doctrine and memory.

## Tiers

Editing `engine/harness/lib` or the hook is adversarial: those run in every
session of every governed project, and a mistake there is silent. Templates and
per-project data under `projects/` are ordinary changes.

## Delivery

Run the suite and commit as one chain. A piped test run masks the exit status
and will commit a red tree.
