### 2026-10-09: the interface is built slowly and later, and until then every report Felix writes is shaped to become one of its surfaces

The founder's direction, taken in the session that reviewed the two-week queue.
It changes no code, opens no branch and takes no slot. It is a standing
instruction about shape. The design of the interface itself is later work.

**Decided by the founder, 2026-10-09 (his words, condensed).**
- Felix gets an interface, built slowly and without hurry. It is not one
  dashboard. It is an OS-style set of interactive surfaces: the inventory and
  the console (what is in, waiting, out), the spend governor, and later the
  dispatch worker chain and distribution.
- Its job is to bring the offline work onto the table so a person can see what
  Felix is doing. It is the plane people will see running the
  from-nothing-to-production-ready pipeline.
- A chat interface in the manner of Claude Code and ChatGPT comes later.
- Everything that matters should be visualizable. What counts as "matters" is
  a later conversation, and nothing here settles it.
- **Until then, formats and structure are worked and modified with this in
  mind.** That sentence is the instruction this section carries.

**What it does not conflict with.** The constitution's "stealth in the middle"
rule is about a session being interrupted. A surface a person goes to is not
that. Anything drawn on the screen of a running session is still that rule's
case, and still needs its own decision.

**Proposed, not yet answered by the founder.** These are how "keep it in mind"
reads to the session that wrote this. Treat each as a default to follow or
argue with, not as settled.
- **A surface is a view over a command.** The command is read-only and prints
  rows (`felix inventory --tsv` is the model). The surface renders those rows
  and computes nothing of its own.
- **Unread is unknown, never zero.** Every cell has three readings: a value,
  none, and "not measured yet". This is already the rule for the lost-work page
  (0cw, closure C1) and for `felix cost` (slot 2a's brief). A pretty surface
  makes "nothing due" and "nothing is being checked" harder to tell apart, so
  the contract carries it.
- **A row names what a reader needs without reading prose.** A stable key, when
  it was read (as-of), the source it came from, and whether it needs a person.
  A status that exists only as a sentence in a handoff cannot be drawn.
- **No shell before surfaces.** The windowing layer waits until about three
  surfaces exist, and then adopts an existing framework instead of inventing one.
- **Read-only first.** The console is read-only by roadmap decision (Phase 0b
  step 6), and consent stays the founder's GitHub merge. A chat that acts,
  or a toggle that writes (the 2026-09-25 per-function on/off idea), is a
  console that acts: the founder's open item. A read-only chat that answers
  "what is waiting and why" needs no such decision.
- **Two audiences.** The founder sees his own real data, locally. An outside
  screen is outside text, so the claims rules in 0cw bind it and it runs on
  synthetic or redacted data. #350 has landed since 0cw named it; the step 15
  judge pin has not.

**Where it touches the queue now.** Nowhere new.
- Slot 2a, `felix cost`: give it a `--tsv` form beside the text one, as
  inventory has. The brief is the founder's order and is not edited here.
- Phase 0b steps 5 and 6, the stuck-PR and lost-work pages: they are the first
  surfaces. They read rows, and say "not measured yet" in place of a missing
  source.
- Capability items 4 and 6, the dispatch lease and the outcome record: write the
  rows a worker chain surface will need later, with the keys above.

**Not in this section.** No interface design, no framework choice, no chat
design, no list of what matters, and no change to the roadmap text. Each waits
for the founder.
