# Felix

The governance layer for the projects we build. Private by design.

Felix holds the things that decide whether a change is acceptable: the
constitution each project is governed by, the mechanical gate that can reject a
change regardless of how confident a model sounds, and the memory of what
previous sessions learned.

It does not hold product code. Elenchus stays in the Elenchus repo. Felix holds
the rules about how work on Elenchus gets done, and eventually the same for
whatever comes next.

## Why this exists

Before Felix, all three lived only in one untracked directory on one laptop:

* `.claude/CLAUDE.md`, the constitution, gitignored
* `scripts/gate.sh`, the gate, untracked and unreachable from the worktrees
  doctrine tells you to work in
* `docs/lessons.md`, `DEVLOG.md`, `SESSION_HANDOFF.md`, the memory, gitignored

The Elenchus repo is public and the doctrine is the moat, so tracking them there
was not an option. Felix is the private tracked home instead.

## Layout

```
harness/          generic. holds no facts about any specific project
projects/         per project doctrine, gate, and memory
  elenchus/
```

`harness/` is deliberately thin right now. There is one project, so anything
built to serve "all projects" would be a registry with a single entry. It grows
when a second project makes a seam necessary, not before.

## Status

Phase 1 of the founder autonomous engineering OS. What exists today is the
tracked home. What comes next is CI that runs the gate independently of the
model, which is the first thing in the stack able to say no.
