### 2026-10-02: every hook stands where the payload's cwd says, not where Claude Desktop started it

**Defect closed.** Claude Desktop launches every session with
`--project-config-root <the main checkout>`. Every Desktop session on this
machine shows it in `ps`, worktree sessions included. On 2.1.286 the hook
runner then spawns every command hook with that root as its cwd, and as
`CLAUDE_PROJECT_DIR`: in the binary, `cwd = launchOptions.projectConfigRoot()
?? <session cwd>`. The payload's top-level `"cwd"` is the session's own
directory, and it follows a Bash-tool `cd`. Every Felix hook resolved from
`$PWD`, so in a Desktop worktree session every one of them judged the main
checkout:
- The Stop hook read `~/Documents/Felix`'s gate receipt. #392's session was
  told "The gate passed on this exact tree at 2026-10-01T20:59:51Z, but the
  grounded facts moved" (the main checkout's receipt, `state/gate/f351c978…`)
  ninety seconds after its own worktree went green at 00:17:40Z
  (`state/gate/2c2f9b37…`). Earlier the same session was told "on a different
  tree".
- #392's unrecorded-catch guard read the main checkout's branch.
- session-start, user-prompt, subagent-start, subagent-stop and session-end
  all recorded and resolved against the main checkout.

The session transcript's `cwd` field never showed the main checkout, which is
how the cause hid.

**Measured, not read.** The real 2.1.286 binary was driven against a local
Messages API stand-in, with probe hooks on every event Felix uses. With the
flag, every event's `$PWD` and `CLAUDE_PROJECT_DIR` were the main checkout,
and the payload's `cwd` was the worktree (`wt/sub` after a Bash `cd sub`).
Without the flag (the CLI), `$PWD` equals the payload's `cwd` and follows the
`cd`. The rig, its README and both logs are kept at
`~/.felix/memory/felix/audits/2026-10-02-hook-payload-cwd/rig/`.

**The change.** `felix_hook_enter` (lib/resolve.sh) is called by stop,
session-start, user-prompt, pre-tool, session-end, subagent-start and
subagent-stop, before their first read of `$PWD`. It reads the leftmost
`"cwd": "<string>"` in pure bash and moves the hook's shell there. From then
on every `$PWD` read is the session's directory, in the hook and in every
library default. post-tool resolves nothing and is unchanged. user-prompt now
reads its payload before resolving the project. subagent-start reads one for
the first time, guarded like session-start against a terminal on stdin.

**What changes for a directory Felix does not govern: nothing.** The payload's
`cwd` is used only when Felix has something to say about it: its repository
root carries a `.felix` marker (healthy or broken), or a project's
`remote_match` resolves it. Otherwise the hook stays at the platform's cwd,
exactly as today. That covers a directory nothing governs, a cwd that does not
exist, a relative cwd, and one holding a JSON escape (escapes are not
decoded). So no hook governs less than it did before this change. When the
payload's `cwd` equals `$PWD`, as in the CLI, the helper returns before
resolving anything.

**pre-tool keeps two things from the launch directory.**
- If the session's directory resolves no project (a broken marker),
  `PROJ` falls back to the launch directory's project, so its deny rows still
  apply.
- When the launch directory resolves the same project as the session's, rows
  scoped to the checkout are judged against the launch directory, as before.
  lib/where.sh counts every worktree of the governed repository as the
  checkout, so a Desktop worktree is still covered, and a scratch clone under
  /tmp still lifts, which is what #308 asked.

**Built as spec, blind assertions, implementation, review.**
- The spec is at `~/.felix/memory/felix/audits/2026-10-02-hook-payload-cwd/spec.md`.
- An Opus author wrote 64 assertions from the spec alone (commit caeea5ad).
  Against main's engine 42 are red, each for the reason it names, and the 22
  controls (unchanged behaviour) are green.
- A Sonnet implementer made all 64 green. Mutations: switching off each rule of
  the helper and each hook's call fails at least one assertion. The directory
  check is an equivalent mutant (an absent path finds no marker and resolves
  nothing anyway); it stays as the cheap early exit.
- The `_p264` fixture put `"cwd":"$REPO"` in a payload it fed to a hook running
  in `$P264R`, which is a Desktop-shaped mismatch no CLI sends. `_p264_prompt`
  now writes the directory it runs the hook in. No count moved.
