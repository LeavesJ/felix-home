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

## Always

Be honest about what Felix does not do. It does not open pull requests, deploy
anything, or read issues. It does not mount MCP servers mid-session, and it
cannot enable a plugin that is switched off without a restart. Its completion
gate interrupts once per chain and is a speed bump with a record, not a barrier;
the barrier is CI.

If a command fails, say what failed and what it printed. Do not paper over it —
this is a tool whose entire value is that it refuses to report success it has
not verified.
