### 0fv. 2026-11-07: the trust-plane design is final, releases fail closed, and trust rework goes first

This section records three decisions the founder made in the trust-plane revisit. It changes no code. Under direction point 3 it binds from this section until the fold (#490, rows 49 to 51) lands.

**1. Releases fail closed until the release subsystem exists.** The design's §4.6 keeps landing apart from releasing. Until a release subsystem is built, a release or deployment transition goes ahead only when the founder authorizes that release by name. This includes a merge that reaches a release. Merge authorization never stands in for release authorization. His answer: "Yes, as proposed".

**2. The trust-plane design is final.** Draft 5 of the 11-06 revisit is the trust plane's design. It is filed as `docs/2026-11-07-trust-plane-design.md`, with its PDF in `docs/pdf/`. Drafts 2 to 4 stay in the memory root, under `designs/2026-11-06-trust-plane-revisit/`, as history. His words: "ok i think v5's directions can be final". The design keeps these parts of the 10-31 design (rows 36 to 40):
- the claim catalogue;
- the fault model;
- discrimination by mutation;
- per-claim receipts;
- the judge pin.

It replaces two parts of the 10-31 design:
- its serial review rounds;
- its evidence engine's place in direction §5.

**3. Trust rework goes first in the queue.** The founder asked: "should trust rework be top of our queue now". Felix answered yes, in this order:
- Intake (#484) lands first (row 42).
- The design's step 1 (replaying slice 0 against a blind held-out set) and step 2 (the specification) start at once. Neither touches an engine file.
- Fixes already open finish. No new audit batch starts ahead of the design's engine steps.
- Then the design's engine steps 3 to 9 run, in the design's order.
  - They replace the 10-31 evidence engine's place in §5.
  - Where a trust-track step of §5 does what a design step does, the design step replaces it. Step 2's specification writes down which steps those are.
  - The kernel refactor (step 1b) waits for that specification.

He answered "Yes, land it" to the fold that carries this order.

**Not decided here.** The capability plane's design is still open (row 42). So is the language of the engine, which the design's Rust spike informs. The spike is not built.
