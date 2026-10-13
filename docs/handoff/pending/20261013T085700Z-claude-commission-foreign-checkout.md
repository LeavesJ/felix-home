### 2026-10-13: unattended work runs only in the project's own checkout

**Engine 0.49.285**, branch claude/commission-foreign-checkout, from main at 0.49.283.
The spec is docs/2026-10-13-unattended-own-checkout-spec.md (B1-B42, decisions D1-D9).
Tier adversarial: lib/, the hook and the felix CLI run in every session of every
governed project. No table under projects/, no escape, no deny row, no change to the
felix CLI.

**Why.** `felix_resolve_project` binds a checkout to a project by its `.felix` marker
first and by a substring of its origin URL second. A `.felix` is part of the tree, so a
repository's authors choose it, and the name of a project such as Felix itself is public.
Once bound, `hooks/session-start` starts work with nobody present, in that checkout. The
founder opens hostile repositories for bounty work, so a repository that holds `felix` in
`.felix` got a detached `felix commission` (under the `commission` grant that
projects/felix has), whose checks `eval` and `cd` into the checkout, whose answer stage
installs plugins and runs `claude mcp list` there (which starts the servers it lists),
and whose baseline check writes a workflow into the tree and calls `gh` against its
origin. The previous handoff (declared tools' reach) named this as its next item and
said it was read from the code and not run end to end. This change traced every
unattended path, ran them, and closes them.

**The paths found.** Every hook was read, and a search for a detaching `) ... &` across
hooks/, lib/ and the felix CLI finds four, all started from `hooks/session-start`; a fifth
unattended act (adoption) is synchronous and was missed by the brief.
- P1 commissioning resume (`felix_commission_resume_bg`): `cd <checkout>; felix commission`.
- P2 discovery refresh (`felix_discover_refresh_bg`): `cd <checkout>; felix discover
  --inspect --quiet`. The checkout contributes only the binding, plus whatever `claude`
  reads from the working directory when it lists plugins.
- P3 graph refresh (`felix_graph_refresh_bg`): `graphify update` over the checkout's files.
- P4 tidying (`felix_tidy_safe`): `rm -f` of an untracked executable in the checkout, with
  a copy of its bytes into the home's state.
- P5 reach refresh: already runs in a private empty directory (previous change). Untouched.
- P6 adoption at session start (`felix_adopt_capability`): writes `capabilities`,
  `stack.tsv`, `setup.tsv` of the bound project from what an unowned tree contains. Those
  three are in the commission policy hash, so the write also lapses a commission grant
  stamped over the old tables.
- P7 the offline record phase and the `.seen` files: left (D4). The answer files are in the
  memory root, which a checkout cannot write.

**The rule.** Unattended work runs only in the bound project's own checkout. A checkout
is own when the project declares a `remote_match` that is exactly `owner/repo`, the
checkout is not a submodule, and its `origin` remote names `github.com/<owner>/<repo>` by
exact equality (lib/own.sh `felix_checkout_is_own`; the slug parser
`felix_remote_github_slug` refuses a `?`, `#` or `\` anywhere in the URL, because git
resolves `https://evil.invalid#@github.com/o/r` to evil.invalid while its message prints
github.com, and refuses a lookalike host, a fork suffix, a third path segment, http, file
and a local path). The `.felix` marker is never read by the predicate. Only an answer of
0 runs anything: 1 is not own and 2 is unread (git missing, a licence exit 69), and both
are withheld, the second said differently. The origin URL is never printed or written
(an https URL can carry a token).

**What changed per path, in an unowned checkout.**
- P1: `felix commission` is not started. `bg.log` gains one `refused-not-own` line, in the
  same three columns, only when the project was granted and the table current (an
  ungranted project stays silent, as before).
- P2: still runs, for every project, own or not (D1), but from a fresh empty directory
  under a private `TMPDIR` that holds a `.felix` naming the project
  (`felix_neutral_run`), never from the checkout. With no private directory it runs
  nothing and the previous cache stands.
- P3: not started. The graph line (`behind this checkout`) is still in the context.
- P4: nothing is removed or copied; the untracked file stays byte-identical.
- P6: nothing is adopted and no `Not adopted` line is said; the tables are byte-identical.
- One line, the context's last paragraph, said at most once per checkout and set of kinds
  (`$home/state/own/<project>.seen`): `Nothing ran here unattended: <project> is bound to
  this checkout <by its .felix marker | by an origin that only contains X>, and <why>.
  Withheld: <adoption, graph refresh, tidying, commissioning>.` In additionalContext only;
  the status line is unchanged.
- A submodule is never own (D9, found in review): git writes a submodule's `origin` from
  the superproject's tracked `.gitmodules`, so a hostile repository could name the
  project's own GitHub repository and be own. Reproduced before the fix: adoption, tidying
  and commissioning all ran in it.
- Own checkouts (a plain clone, its linked worktrees, a superproject): each of P1, P3, P4,
  P6 runs exactly as on main, same command, directory, log lines and context lines.

**Files.** New lib/own.sh (291 lines: the slug parser, the predicate, the gate, the line,
and `felix_commission_resume_bg` moved from lib/commission.sh, which sources it so a caller
of commission.sh alone still finds it). lib/reach-read.sh gains `felix_neutral_dir`,
`felix_neutral_rm`, `felix_neutral_run`, extracted from `felix_reach_read`, whose sentences
are byte for byte as before (parts 1100-1120 pass with no edit). hooks/session-start gates
four call sites (726 lines, the same as before); lib/discover.sh (1516) routes the refresh
through `felix_neutral_run`. If lib/own.sh cannot be sourced every gated path fails closed
(B42). New part 1130 (449 lines), sourced from tests/run. Parts 0030 and 0060 change their
fixture only: their checkout is now the project's own (an origin that names its
remote_match); no assertion renamed or re-expected.

**What did not change.**
- Attended commissioning: `felix commission` typed by a person runs in any checkout with
  today's output and exit codes (D2: no attended line added, the CLI is 6,179 lines).
- The binding (`felix_resolve_project`, marker first, substring second), every context
  line, every deny row, the gate and the Stop hold in an unowned checkout.
- The reach refresh, the record phase, `felix_tidy_safe`, `felix_graph_refresh_bg`,
  `felix_adopt_capability`, `felix_undeclared`: libraries unchanged (the gates sit at the
  call sites, except the commissioning gate, which is inside the function that has no
  attended caller).
- The synchronous `felix_maint_status` checks read and left: every maintenance row on disk
  calls git, find, test or the engine's own tool. A row whose check ran a checkout's own
  tool (npm, make) would be unattended tree code; none exists.
- git itself in the checkout: what git runs is chosen by `.git` and config, not the
  tracked tree. A checkout whose `.git` came from an attacker (a tarball carrying `.git`)
  is out of Felix's reach and is not claimed.

**Cost, stated.** A project with no `remote_match` (behaviorchangebench, webapp,
elenchus-capital-research on disk; the BehaviorChangeBench checkout has no origin) no
longer adopts at session start, refreshes its graph or tidies in any checkout until it
declares a `remote_match` and its checkout an origin. A project whose own repository is
consumed as a submodule of another gets no unattended work inside that submodule. Not
claimed: a linked worktree made with `git worktree add` from inside a submodule shares its
gitdir and origin and is not refused.

**Record.** Written at ship; see the end of this section for the numbers once the
manifest and the red run are recorded.

**Not built.**
- No attended notice in `felix commission` (D2).
- The project-less `remote_match` projects above are not given one; that is a table edit
  for each, and a founder's call about which hosts they are on.
- Version: 0.49.285. Read 2026-10-13 at ship time: main 0.49.283; worktree
  charming-bartik-58e065 and open PR #432 (claude/gf-a) hold 0.49.284; no other worktree
  or open PR holds a number above 0.49.283. Renumber if another engine PR lands first.
