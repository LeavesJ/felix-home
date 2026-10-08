### 2026-10-08: what the engine reads from a patch is the repository's, not a diff setting's

Found 2026-10-08 by the session that pinned git colour off
(claude/no-git-colour-in-parsed-output). Fixed on
claude/no-diff-drivers-in-parsed-diffs, stacked on claude/git-reads-fail-closed.
Contract, blocks, runners and logs: ~/.felix/memory/felix/audits/2026-10-08-diff-drivers/.

**What git does.** Measured on git 2.54.0, macOS, bash 3.2.57, on a branch
adding `api_key = "sk-…"` to creds.py. Four engine readers parse or hash
porcelain `git diff`: bin/secret-scan, felix_added_lines, _felix_escape_confined
and felix_tree_id. Each of these made `secret-scan main` exit 0:
- an external diff: `diff.external`, GIT_EXTERNAL_DIFF, or `diff=<driver>`
  with `diff.<driver>.command`;
- a textconv: `diff=<driver>` with `diff.<driver>.textconv 'sed d'`;
- a binary marking: `-diff` or `binary` in a committed .gitattributes, in
  info/attributes or in core.attributesFile's file, `diff.<driver>.binary`, or
  core.bigFileThreshold below the file's size;
- colour: color.ui or color.diff set to always;
- paths: `diff.dstPrefix=b/fixtures/` (every file read as a fixture's), and
  `diff.relative` with the scan run from a subdirectory.

A committed .gitattributes needs no config, so a branch could blind its own
scan. felix_added_lines read none of the line, so felix_escapes and classify
judged an empty change. Under an external diff or an empty textconv,
felix_tree_id hashed an edited tree as the clean one. A textconv printing
`liba>=1.0`/`liba>=2.0` made _felix_escape_confined demote a risk row over an
unconfined change. `diff.noprefix` alone changed no verdict.

The second defect handed over, secret-scan exiting 0 when git refused to run
(malformed GIT_CONFIG_PARAMETERS), was already closed by the stacked base: it
exits 2. Restated as U1 so this branch cannot lose it. GIT_EXTERNAL_DIFF is
also unset at the entry points by claude/no-caller-env-in-tool-output; not
duplicated, since --no-ext-diff covers it here whatever the environment holds.

**Mechanism.** The full reasoning is the dated comment above
`_felix_git_patch` in lib/resolve.sh; bin/secret-scan holds a copy.
- Per-call pins, since a driver's name is anyone's to choose and no config key
  turns every textconv off: `--no-ext-diff --no-textconv --no-color
  --src-prefix=a/ --dst-prefix=b/ --ignore-submodules=none`.
  - felix_added_lines adds `-M`, git's default, so diff.renames=copies cannot
    hide a copied file.
  - secret-scan adds `--no-renames`, because its fixture rule is a property of
    the path, so a key moved out of fixtures/ is a new key where it lands.
    This is the one change to what a default configuration reads.
  - felix_tree_id also pins `-c core.abbrev=auto`. The `index` line is all it
    sees of a binary edit, and core.abbrev=4 cut that to 16 bits of a blob id,
    so a second edit sharing them hashed as the first.
- Every read runs from the top of the work tree, so diff.relative cannot
  narrow it, and ends its revisions with `--`, so a tracked file named HEAD is
  not taken for one.
- A binary marking has no switch. `--text` on everything cost 6.75 s CPU
  against 0.08 s for a branch adding a 20 MB random binary. So:
  - numstat `-z` names the paths git printed as binary;
  - `--raw -z --no-abbrev` gives their blob ids;
  - a pair is read again with `--text` only when each side present is at most
    512 MiB with no NUL in its first 8000 bytes. That is git's rule when no
    attribute speaks.
  - A pair with a binary side stays unread, as git's default leaves it.
- The read again names its paths under `--literal-pathspecs`. It is whole only
  when it prints a distinct `diff --git` header for every path it named, since
  a type change prints two for one path. GIT_GLOB_PATHSPECS and
  GIT_ICASE_PATHSPECS make git refuse the option, so they fail closed, exit 2.
- Each extra read ends in a `\037ok` record, so one that did not finish makes
  secret-scan exit 2 and felix_added_lines return non-zero.
- _felix_escape_confined and felix_tree_id take the pins without the binary
  read again. The confine check sees no ± line for a binary-marked file and
  fires. The tree id still sees a binary edit's blob ids on the `index` line.
- N1: under a default configuration every pinned read prints git's bytes.
  Across 11 tree states, felix_tree_id matched 34a1bc3a byte for byte, so no
  receipt goes stale on deploy.
- L: tests/run refuses an engine line (felix, bin/*, lib/*.sh, hooks/*,
  tests/red) that runs porcelain `git diff` without both --no-ext-diff and
  --no-textconv, after any of git's global options. A line asking only
  --name-only or --name-status is exempt.

**Built as spec, blind assertions, fix, review, blind assertions again, mutation.**
- Blind block, 255 assertions, written from the contract alone with each
  setting in the fixture repository's own config. Red on origin/main: 165. Red
  on the stacked base 34a1bc3a: 158. The rest are controls and guards.
  - The first fix ran 241/14. The blind author had asserted colour (12) and a
    key moved out of fixtures/ (2) under the rule, which the contract had not
    spelled out. Both are now in the fix, and in a dated amendment to the
    contract.
  - The fix runs 255/0.
- Adversarial review found:
  - a binary-marked file named `-c1` handed to `head` as an option;
  - a binary-to-text pair re-read in full, breaking N1 and the cost bound;
  - diff.ignoreSubmodules and a committed .gitmodules `ignore = all` hiding a
    moved pointer from the tree id;
  - a comment claiming a colour pin that has not landed.

  All four are fixed. Its untested leads were measured: core.abbrev (fixed,
  above), the type change (the count check counts distinct headers), a ROOT
  below the top (reads run from the top), working-tree-encoding (documented as
  out of scope).
- Post-review block, not blind: 20 assertions, Q1 to Q8.
  - Red: 14 on 34a1bc3a, and 2 on the fix before the core.abbrev pin.
  - The fix runs 20/0.
- Blind round on the review's findings. The findings were rewritten as
  behaviour-only clauses (contract-review.md, R1 to R7), and a second blind
  author wrote 473 assertions from them, without reading the fix.
  - On 34a1bc3a: 145 passed, 328 failed. On the fix: 470 passed, 3 failed.
  - The 3 were one case: a tracked file named `HEAD`. secret-scan's
    `git diff HEAD` refused it as ambiguous, so it exited 2. That fails closed,
    but such a repository could never scan clean. It happens on the base with
    no setting at all.
  - Fixed here: every patch read ends its revisions with `--`.
  - The author's own extra names (`-`, `:/x`, `:(glob)…`, `:!x`, quotes, a
    backslash, a tab, a newline, a trailing space, `main`) all passed.
- Mutation: 24 mutants, each reverting one piece of the fix.
  - The blind block killed 12. The post-review block killed 9 of the rest:
    submodules, both old-side checks, the dash-led name, both literal reads
    (once Q8 added a second file the glob matches), -M, both distinct-header
    counts, and core.abbrev.
  - 3 survive, by design:
    - M13: secret-scan's old-side check only shows as a key it misses on a
      binary-to-text pair, and that miss is handed on, not asserted.
    - M18: the count check backs up the literal read. With literal pathspecs
      on, no git this suite drives makes a read miss a path.
    - M21: the 512 MiB size rule. No fixture can afford a file that large.
- Differential sections, the base 34a1bc3a against the final fix, identical:
  secret scanning 46/0, scope 16/0, fail-closed block 130/0/1. N1 was re-run
  after each engine change.

**Not done here, handed on.**
- An added line beginning `++ ` prints as `+++` and is dropped as a header,
  with no setting needed. Its own task.
- A key in a text file that replaced a binary one passes secret-scan (exit 0
  on origin/main and here), as git's default reads the pair as binary. Also,
  a real binary's edit reaches the tree id only through a 7 to 9 hex prefix.
  One task: "Close binary-file gaps in secret-scan and tree id".
- status.branch colouring `felix handoff` belongs to the colour session's
  handoff. GIT_*_PATHSPECS at the entry points went to the caller-environment
  session.
- lib/verify.sh is 557 lines, past the 500-line rule. The base handed the split
  on; this branch adds 13 lines to the same functions.
- Not covered, by design: clean filters, core.fsmonitor, assume-unchanged and
  skip-worktree change what `git add` commits the same way. `git show`,
  `git grep` and `git diff --quiet` run no driver by default (measured).

**Landing.** Carrier slot 13b, after 13 (claude/git-reads-fail-closed). Once 13
lands, merge main in (no rebase), then record, red and gate on the head that
lands. If 3b (suite-git-proof) lands first, the blocks' raw
`( cd "$X" && git ... )` shapes become `_fx_cd`/`_fx_git`.
tests/assertions.tsv is regenerated at the slot.
