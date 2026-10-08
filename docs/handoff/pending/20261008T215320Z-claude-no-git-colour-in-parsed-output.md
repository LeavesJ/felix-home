### 2026-10-08: a person's git colour settings never reach what the engine parses

Found by the caller-environment branch (claude/no-caller-env-in-tool-output).
That branch left git alone on purpose, because git takes colour from its
configuration, not from the variables it unsets. This work is stacked on it
and lands with it as one PR.

**Defect closed.** Told `always`, git writes colour escapes into a pipe. It
can be told through:
- any config file, including an include;
- GIT_CONFIG_COUNT;
- GIT_CONFIG_PARAMETERS, which git exports to every child of `git -c`;
- GIT_PAGER_IN_USE, when TERM is not dumb.

Measured on git 2.54 and bash 3.2.57, with `color.ui=always` in the
repository's own config:
- **bin/secret-scan** exited 0 on a branch that adds `api_key = "sk-QQ..."`.
  Its control exits 1, so this fails open.
- **felix_added_lines** read nothing. The durable added-lines escape and
  classify's content rules therefore saw nothing.
- **A confined risk row** fired on a confined change.
- **`felix handoff`** called an untracked-only tree dirty, because `status
  --short` colours `??` on a tree with changes. The census that found this
  work measured it on a clean tree, which prints nothing.
- **SESSION_HANDOFF.md** took the escapes into its Uncommitted block.
- **felix_tree_id** gave the same tree two fingerprints.

**Mechanism, and why this one.** Every executable file under engine/harness
appends thirteen entries to GIT_CONFIG_PARAMETERS, right after the
caller-environment unset line:
- `color.ui` and the ten `color.<family>` switches, set to never;
- `color.pager=false`;
- `blame.coloring=none`.

Why:
- **Family keys.** An explicit `color.diff=always` beats `color.ui=never`.
- **color.pager.** Plumbing and `%(color)` read no family key, so under
  GIT_PAGER_IN_USE they coloured a pipe until it was false.
- **GIT_CONFIG_PARAMETERS, not GIT_CONFIG_COUNT.** Git reads it after every
  config file and after GIT_CONFIG_COUNT.
- **Appended.** It goes after a space, and not again when the value already
  ends with it. It forks nothing, because post-tool runs on every tool call.
- **Not `--no-color` per call.** That reaches only the engine's own calls,
  never a project's gate, a table check or a provider.

The dated comment in engine/harness/felix carries the reasoning, the costs,
and what is out of reach.

**Built as contract, blind assertions, fix, review.**
- **Blind block.** An Opus author wrote 61 assertions from the contract alone,
  in a pristine export of the base, and checked them against a mock pin and
  eleven broken pins. An Opus critic found:
  - assertions that could pass for the wrong reason (an empty receipt, a gate
    that never ran);
  - a static parser that failed a pin carrying a trailing comment;
  - fixtures that inherited GIT_DIR.

  The revised block has 63 assertions: 30 red on dc27380c, 63/63 on the
  eleven-entry pin (e7c75ce3). It was committed verbatim as 9b4c8791.
- **Adversarial review of e7c75ce3.** Three Opus lenses, and an Opus skeptic
  re-ran each finding:
  - **Confirmed:**
    - GIT_PAGER_IN_USE still coloured plumbing;
    - blame.coloring was missing;
    - six comment sentences said more than was measured, among them "every
      colour switch git documents" and "one call can still choose".
  - **Refuted:** `unset -f git` against a BASH_ENV function. BASH_ENV can
    redefine `unset` too, so the line would claim a protection it cannot give.
    The base fails the same way.
  - **Fixed in 9cdec1b3:**
    - two more pin entries;
    - the comment rewritten;
    - the block amended, not blind, plus three behavioural rows for the new
      entries.
- **Counts.** 66/66 on 9cdec1b3. Against dc27380c 31 are red, and against the
  eleven-entry pin 17. Six existing sections (hooks with `ulimit -u 1`,
  secret scanning, risk classification, scope, receipt epoch, large-diff
  escape) give the same verdicts on base and final.

**Handed on, not done here:**
- **External diff and textconv.** `diff.external`, GIT_EXTERNAL_DIFF and
  textconv still make secret-scan pass an added credential.
  - "Stop diff.external and textconv blinding secret-scan" is building
    per-call `--no-ext-diff --no-textconv` (claude/no-diff-drivers-in-parsed-diffs).
  - GIT_EXTERNAL_DIFF and GIT_DIFF_OPTS go on the caller-environment unset
    line.
- **status.branch=true.** `git status --short` prints `## main` on a clean
  tree, so `felix handoff` (felix, `dirty=` in the before-you-stop list) and
  lib/memory.sh:177 call it dirty. The fix is `status --porcelain` or
  `--no-branch`, measured to print nothing. Filed as its own task
  ("Stop status.branch making felix handoff call a clean tree dirty").
- **Project scripts no entry point starts** still parse coloured output:
  - projects/elenchus/prepush.sh:116, `git diff | grep '^+'`. It feeds that
    project's secret check, so it fails open.
  - projects/elenchus/gate.sh:236 and projects/veldra/gate.sh:191,
    `git status --short | grep -v '^??'`.

  Under `felix gate` the pin reaches them. Run directly, it does not.
- **Out of reach by design:**
  - a `git` function from BASH_ENV or `export -f`;
  - a `git` earlier on PATH;
  - `%C(always,...)` in format.pretty, which no engine call reaches, since
    every one passes --format;
  - the far side of a local push.
- **Libraries sourced outside an entry point** are not pinned. CI has no
  person's colour config.

**Trap paid.** At 12:47 something ran `git remote remove origin`, then `git
remote add origin https://github.com/acme/widget.git`, in the real shared
repository. That deleted every remote-tracking ref and broke fetch for every
session.
- **Restored** at 12:54 from FETCH_HEAD. The per-branch upstream and Desktop
  PR-binding entries are lost.
- **Source not found.** The shape matches tests/run 4415 and 5606 with an
  empty fixture variable, because `cd ""` stays put.
- **Prevention:** suite-fixture-floor, carrier position 3.
- **The same session nearly paid it again.** A heredoc nested in a heredoc
  with the same delimiter ran the rest of a test fragment in the tool shell
  with empty variables. It did nothing only because `/` is read-only. Give an
  outer heredoc a delimiter no inner one uses.
