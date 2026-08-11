---
description: Set up Felix on this project, or show what it is already doing
allowed-tools: Bash, Read
---

The one entry point. Felix is otherwise invisible on purpose — it works through
hooks and costs a session nothing — which means somebody who has never seen it
has no way in. This is that way in.

Run `felix which` first. Everything below branches on whether it answered.

## If it says a project governs this directory

Felix is already working here. Report, briefly and in plain language:

- which project governs this checkout, and where its constitution lives
- `felix ready` — whether every tool its routes can name is actually installed
  and switched on, because a plugin that is off is invisible until the turn it
  was needed
- `felix maintenance` — anything due
- `felix toolbox` — every installed plugin, what it actually ships, and whether
  any route can reach it; the last column is the one that matters
- `felix ledger` — what has been mounted and never once reached for, which is
  the only signal here that is not confounded
- `felix autonomy` — what this project has permitted Felix to do unattended,
  which is nothing until somebody grants it
- `felix monitor --open` — offer it, do not run it unasked; it is a page showing
  every routing decision and gate verdict, which is otherwise unobservable

Do not run `felix gate` unless asked. It can take minutes.

## If it says no project governs this directory

This is somebody bringing Felix to a project it has never seen. Do not scaffold
anything yet — find out what is here first, then propose.

1. Run `felix doctor` if it works, otherwise inspect the checkout directly:
   the language, whether there is a test suite, whether CI exists, whether
   anything is deployed.
2. Work out what would prove this project correct — the command that fails when
   the code is wrong. `npm test`, `cargo test`, `pytest`, `make check`, a script.
   Say what you think it is and ask, because a gate that cannot fail is worse
   than no gate at all, and guessing it silently is how that happens.
3. Then, and only then, offer:

   ```
   felix new <name>
   ```

   Explain what it creates before running it: a directory in the Felix home
   holding this project's constitution, its risk tiers, its evidence policy and
   its memory. Nothing is written into their repository except a `.felix` marker
   naming the project.

4. After it exists, walk through what now applies:
   - the gate runs before anything is called finished
   - routes.tsv decides which tools get named for which kind of work, and is
     seeded generic — it is worth rewriting against the words this project
     actually uses, because a generic table routes a backend bug to the frontend
   - `felix ready` before the next session, since a plugin that is switched off
     cannot be switched on mid-session

## What it does whether or not anybody asks

Say this plainly, because most of Felix is not commands anybody types. It binds
the session and names the constitution and handoff as required reading; it
routes each prompt and mounts the lessons that match; it **refuses** Bash
commands the project has forbidden, through `PreToolUse`; it records every tool
call and folds that into a ledger at session end, including a zero for
everything mounted and never reached for; and it checks the gate when you stop.

Where a project has opted in through `felix autonomy`, it also tidies — and
that is the only thing here that deletes, so it is the only one gated on an
explicit grant.

## Always

Be honest about what Felix does not do, and check the list before repeating it.

It **does** read an issue and open a pull request — `felix brief <n>` and
`felix pr --create`, both since 0.22.0. Anything saying otherwise is stale.

What it genuinely does not do: deploy a product. Mount an MCP server or enable a
switched-off plugin **mid-session** — Claude Code binds those at session start,
so the most Felix can do is write configuration that the *next* session boots
with, and that path is designed but has never been exercised. Enforce its own
red tier mechanically, on a private free repository.

Its completion gate interrupts once per chain and is a speed bump with a record,
not a barrier; the barrier is CI.

If a command fails, say what failed and what it printed. Do not paper over it —
this is a tool whose entire value is that it refuses to report success it has
not verified.
