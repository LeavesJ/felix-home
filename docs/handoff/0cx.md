### 0cx. 2026-10-02: a hook in a Desktop worktree session judges the worktree, not the main checkout

**Defect closed.** Claude Desktop launches every session with
`--project-config-root <the main checkout>`. Every Desktop session on this
machine shows it in `ps`, worktree sessions included. On 2.1.284 and 2.1.286
the hook runner then spawns every command hook with that root as its cwd, and
as `CLAUDE_PROJECT_DIR`: in the binary, `cwd = launchOptions.projectConfigRoot()
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

**Measured, not read.** The real binary was driven against a local Messages
API stand-in, with probe hooks on every event Felix uses. With the flag, every
event's `$PWD` and `CLAUDE_PROJECT_DIR` were the main checkout, and the
payload's `cwd` was the worktree (`wt/sub` after a Bash `cd sub`). Without the
flag (the CLI), `$PWD` equals the payload's `cwd` and follows the `cd`. The rig,
its README and both logs are kept at
`~/.felix/memory/felix/audits/2026-10-02-hook-payload-cwd/rig/`.

**The change.** stop, session-start, user-prompt, session-end, subagent-start
and subagent-stop call `felix_hook_enter` (lib/resolve.sh) before their first
read of `$PWD`. It moves the hook's shell into the session's directory, and
then every `$PWD` read, in the hook and in every library default, is that
directory. The hook leaves the directory it was started in for three reasons
only:
- the payload's `cwd` is another checkout or worktree of the project that
  governs the launch directory: the Desktop worktree, which is what this
  change exists for;
- the payload's `cwd` is governed and the launch directory has no `.felix`
  marker and resolves no project;
- the payload's `cwd` holds a broken `.felix` marker, which is then reported
  where the session stands.

The payload is read in pure bash, from its first 4096 characters, and only the
first `"cwd"` key's string value counts. A candidate that is the same directory
as `$PWD` (`-ef`: a symlinked launch path, a trailing slash) costs nothing and
forks nothing, which is the CLI on every call. post-tool resolves nothing and
is unchanged. user-prompt now reads its payload before resolving the project.
subagent-start reads one for the first time, guarded like session-start
against a terminal on stdin.

**What changes for an ungoverned payload cwd: nothing.** When nothing governs
the payload's `cwd` (no marker, no `remote_match`), the hook stays at the
platform's cwd and judges what it judged before. The same holds for a `cwd`
another project governs, one that does not exist, a relative one and one
holding a JSON escape (escapes are not decoded). No hook governs less than it
did, and none trades the launch project's rules for another project's.

**pre-tool is main's whenever the launch directory is governed.** It resolves
the project from `$PWD` first, exactly as main, and calls `felix_hook_enter`
only when that resolves nothing. In Desktop the launch directory is the main
checkout, and lib/where.sh already counts every worktree of it as the
checkout, so worktree sessions were never misjudged there. It asks for the
project a second time only if the hook moved, so a repository nothing governs
costs one `git remote` per call, as on main.

**Known limits, not fixed here.**
- A session that cd's into a same-project scratch clone is judged as that
  clone's tree, as the CLI already does.
- A session that cd's into a directory nothing governs is judged at the launch
  directory, which in Desktop is the main checkout, as before.
- Fixing either needs a per-session record of where the session stood.

**Open: SessionStart named the worktree's HANDOFF.** In the session that found
this, SessionStart on 2.1.280 (09-25) and on a 2.1.284 compact (10-01) named the
worktree's HANDOFF.md, which the measured hook cwd cannot explain. An older
Desktop launch or the compact path may spawn hooks differently. Not measured.

**Built as spec, blind assertions, implementation, review, twice.** The spec
and its Amendment 1 are at
`~/.felix/memory/felix/audits/2026-10-02-hook-payload-cwd/spec.md`.
- Round one: an Opus author wrote 64 assertions from the spec alone
  (caeea5ad). Against main 42 were red, each for the reason it names, and the
  22 controls were green. A Sonnet implementer made them green (19f63246).
- Round one's review showed a payload `cwd` in another project's checkout
  traded rules: pre-tool let through a forced push main refuses, and Stop
  judged a project with no gate and exited 0. Amendment 1 narrowed when the
  hook moves, bounded the read and returned pre-tool to main's order.
- Round two: blind assertions from the amendment (f823182d). Against round
  one's engine 15 of 89 are red, against main 56. The implementation
  (466526c4) made all 89 green.
- Round two's review found pre-tool resolving twice in a repository nothing
  governs (about 45 ms a call), and a launch directory with a broken marker
  being stepped over. Both are fixed, with three pins written after the
  review rather than blind: each is red on 466526c4 or on a forking mutant of
  the shortcut, and green on the branch (92 of 92).
- Mutations: switching off each rule of the helper and each hook's call fails
  at least one assertion. The directory check is an equivalent mutant (an
  absent path finds no marker and resolves nothing anyway); it stays as the
  cheap early exit.
- The `_p264` fixture put `"cwd":"$REPO"` in a payload it fed to a hook running
  in `$P264R`, which is a Desktop-shaped mismatch no CLI sends. `_p264_prompt`
  now writes the directory it runs the hook in. No count moved.
