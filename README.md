# Felix

The engineering OS, and the pilot of implementation.

You own *what* gets built: the product thesis, the priorities, the approvals
that involve money or identity or anything irreversible. Felix owns *how* it
gets built — which plugin, which skill, which MCP, in what order, in one
context or several — and the loop around that choice: verify, classify, ship,
repair, remember.

If you find yourself thinking about tooling, Felix has failed at its job.

Felix holds no product code. It holds the constitution each project is governed
by, the gate that can reject a change regardless of how confident a model
sounds, and the memory of what earlier sessions learned.

## What it does without being asked

This is the part worth reading before installing, because most of Felix is not
commands you type. It wires six of Claude Code's nine hooks, and they run in
every session of every project it governs.

| When | What happens |
|---|---|
| Session starts | Binds the session to its project, names the constitution and handoff as required reading, reports capability drift and upkeep that is due, and tidies what it is permitted to tidy |
| You submit a prompt | Decides what kind of work it is, names the one tool that is due next, and mounts the lessons this project already paid for that match it |
| Before a Bash command | Refuses the ones this project has forbidden, with the reason |
| After any tool call | Records what was reached for, so unused capabilities can be found later |
| Session ends | Folds that into the ledger, including a zero for everything mounted and never touched |
| You stop | Checks the gate ran and passed on this exact tree, and says so if it did not |

Nothing there needs you to remember a command.

## Install

Requires `bash`, `git`, and the `claude` CLI. The engine deliberately needs no
runtime beyond bash and git, because it governs projects in languages it must
not require.

```bash
git clone <your-felix-remote> ~/Documents/Felix
~/Documents/Felix/engine/harness/felix install
```

That creates your home, registers the engine as a local Claude Code
marketplace, installs the plugin, and — importantly — **verifies that what is
deployed matches the tree**. Claude Code caches plugins by version, so a changed
engine at an unchanged version silently does not deploy while reporting success.
`felix install` refuses to lie about that; when it finds drift it tells you to
bump the version in `engine/.claude-plugin/plugin.json`.

Put it on your PATH so the command is available anywhere:

```bash
ln -s ~/Documents/Felix/engine/harness/felix /usr/local/bin/felix
```

`felix install --home <path>` puts your doctrine and memory somewhere else.
`felix install --uninstall` removes the plugin and **never** touches the home,
because that holds everything you have written.

## Govern your first project

Adding a project is a directory and a JSON file. It is never an edit to engine
code — if governing something new ever required that, the engine would have a
project-specific assumption baked into it, which the gate treats as a bug.

```bash
cd ~/code/your-project
felix new your-project
```

Then set `gate` in its `project.json` to whatever proves that project correct.
It is a shell command, so `npm run verify`, `cargo test`, `pytest`,
`make check`, or a script Felix stores for you all work.

Felix binds a checkout to a project either by `remote_match` in `project.json`,
or by a `.felix` file naming the project in the checkout. The marker is what
makes it work on a repo with no remote, a fork, or code you do not own.

Then run `felix` with no arguments. Every command is grouped and described.

## What it will never do on its own

Felix acts on what is reversible and stops at what is not.

- **It never installs anything risky.** `felix discover` fetches a candidate at
  its pinned commit and *reads what it ships* before saying anything. Only
  low-risk ones can be adopted automatically; anything shipping hooks, a
  floating version, or an interpolated secret is refused by every flag from
  every caller.
- **It never deletes from your repository unless you grant it.** `felix
  autonomy` shows what is permitted and grants nothing by default. Felix does
  not write that file for a project — a permission a system grants itself is
  not a permission. Even once granted, a file is removed only when Felix
  already holds a copy of that exact name, git does not track it, it is not the
  declared gate, and a backup has been written and confirmed readable.
- **It never decides your product.** Prioritisation, pricing, anything
  irreversible, and any change to what Felix is *for* stop and ask.
- **It cannot mount an MCP server or enable a plugin mid-session.** Claude Code
  binds those at session start. Felix names what to reach for within a session
  and writes configuration between them.

## Verification

```bash
felix gate                    # this project's gate, recorded
engine/harness/tests/run      # the engine's own suite
```

The suite builds a throwaway Felix home governing an invented project with a
one-line shell gate, in a checkout with no git remote, and drives the real CLI
and the real hooks against it. It never touches a real project. It asserts,
among other things, that a failing gate propagates a non-zero exit — because a
gate that cannot fail is not a gate — and that every command which dispatches
appears in the help text, because twenty-six of them once did not.

Run it from where it lives. It computes its own path from `$0`, so running it
from elsewhere makes it copy the wrong tree.

## Layout

```
engine/
  harness/felix       the CLI. names no project, assumes no language
  harness/lib/        resolution, routing, risk, evidence, ledger, shape
  harness/hooks/      the six hooks above
  harness/tests/run   the suite; run it before trusting a change
  harness/templates/  what a new project is seeded with
  .claude-plugin/     the version. bumping it is what deploys
projects/
  <name>/CLAUDE.md    that project's constitution
  <name>/*.tsv        its routes, risk tiers, evidence policy, stack, denials
  <name>/memory/      lessons, devlog, handoff, and every verdict recorded
```

Your doctrine and memory live in the home, not in the repositories being
governed. That is deliberate: a public repo cannot hold a private constitution,
and a gate stored in the tree it judges can be edited by the change it is
judging.

## Status

Phase 1 of the founder autonomous engineering OS: intent to code to CI to
telemetry to repair. Revenue, customer and company operations are later phases
owned by other systems.

Honest about what is unfinished: Felix does not yet read a GitHub issue or open
a pull request, and nothing yet consults `felix shape` automatically. See
`HANDOFF.md` for the current state, the standing direction, and the traps that
have each cost real time.
