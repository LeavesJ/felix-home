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
harness/          the engine. names no project, assumes no language
  felix           CLI: which / gate / new
  lib/resolve.sh  project resolution, shared by the CLI and the hook
  hooks/          SessionStart binding
  tests/run       self-test, run it before trusting a change
projects/         doctrine, gate, and memory, one directory per project
  elenchus/
```

## Governing a project

Adding a project is creating a directory and a JSON file. It is never an edit to
harness code. If governing something new ever requires changing the harness, the
harness has a project-specific assumption baked into it, and that is a bug.

```bash
harness/felix new veldra
```

Then set `gate` in its `project.json` to whatever proves that project correct.
It is a shell command, so it can be `npm run verify`, `cargo test`,
`dotnet test`, `make check`, or a script Felix stores. Bind the project either by
declaring `remote_match`, or by dropping a `.felix` file naming it into the
checkout. The marker path is what makes Felix work on a repo with no remote, a
fork, or code you do not own.

Dependencies are bash and git. Felix governs projects in languages it must not
require, so it does not drag a runtime along.

## Verification

`harness/tests/run` builds a throwaway Felix root governing an invented project
with a one-line shell gate, in a checkout with no git remote, and drives the real
CLI and the real hook against it. It never touches Elenchus. It asserts, among
other things, that a failing gate propagates a non-zero exit, because a gate that
cannot fail is not a gate.

## Status

Phase 1 of the founder autonomous engineering OS. What exists today is the
tracked home. What comes next is CI that runs the gate independently of the
model, which is the first thing in the stack able to say no.
