### 2026-10-08 — the setup step bootstrap renders runs on Node 24, and the suite holds each pinned commit to the runtime read for it

**Engine 0.49.282 (provisional; the queue slot renumbers).** #354 pinned every
`uses:` in the rendered gate workflow to a full sha, but the three setup
actions it pinned run on Node 20, while the same file says its checkouts are
on v5 because that is "the lowest major that runs on Node 24". Read
2026-10-08 with `gh api repos/OWNER/NAME/contents/action.yml?ref=SHA`:

| Was | Now | action.yml |
|---|---|---|
| `actions/setup-node@49933ea5… # v4.4.0` (node20) | `@a0853c24544627f65ddf259abe73b1d18a591444 # v5.0.0` | node24 |
| `actions/setup-python@a26af69b… # v5.6.0` (node20) | `@ece7cb06caefa5fff74198d8649806c4678c61a1 # v6.3.0` | node24 |
| `actions/setup-go@40f1582b… # v5.6.0` (node20) | `@924ae3a1cded613372ab5595356fb5720e22ba16 # v6.5.0` | node24 |
| `dtolnay/rust-toolchain@02cb101e… # v1` | `@7e38f4b43b4db5c8dd498af069a4f6196df1d067 # v1` | composite |

Each is the newest release of the lowest major whose action.yml says node24.
All four are lightweight tags pointing at commits, and each sha equals the
floating major tag (v5, v6, v6, v1) today. setup-python v6.3.0 is the sha
LeavesJ/Elenchus#29 pins for its own gate.yml, so once both land they agree,
and #29's note explaining the divergence from the renderer goes stale.

**Traps paid:**
- **setup-go v6.0.0's release notes and v6.1.0's README say Node 24, and
  both say node20 in action.yml.** v6.2.0 (#691, "Update Node.js version in action.yml") is
  the first that runs on it. A major is the wrong unit to check; the sha is.
- **dtolnay's v1 moved on 2026-10-01** to master's new head 7e38f4b4, which
  wraps `rustup toolchain install` in up to five tries on a release-server
  checksum failure (+16 −1 in action.yml, read in full). The old pin is still
  on master, so it was not at risk of collection, but `# v1` after it had
  become false.
- **The workflow is an unquoted heredoc.** A backquoted `using:` in a new
  rendered comment ran as a command at render time and left a hole in the
  adopter's file. The error reached the suite's output and nothing failed on
  it. Two assertions now hold the render: silent on stderr for every stack,
  and every `$` and backquote in the heredoc's source escaped or one of its
  three meant expansions, since one that succeeds (`pwd`, `$HOME`) prints
  nothing on stderr. The adversarial review demonstrated that second case.

**What changes for an adopting repository** (both action.yml files and the
release notes, read for each major):
- setup-node v5 caches by itself when package.json's `packageManager` names
  npm, yarn or pnpm.
  It reads `$GITHUB_WORKSPACE/package.json`; the rendered workflow checks the
  repository out under `repo/`, so nothing is cached, as under v4.
- setup-python v6 adds `pip-version` and `pip-install`, both left unset.
  Caching stays opt-in; `python-version: "3.12"` is explicit, so the
  `.python-version` and Pipfile reading changes do not apply.
- setup-go v6 exports `GOTOOLCHAIN=local` to every later step, the gate
  included, so `go` never fetches a newer toolchain a go.mod asks for and
  fails instead. With `go-version: stable` only a go.mod naming a release newer
  than stable is refused. Its cache key moved from go.sum to go.mod (v6.3.0),
  looked for at the workspace root, where neither is, so it warns and caches
  nothing, as v5 did.
- All three need runner v2.327.1 or later, which `actions/checkout` v5
  already required; `ubuntu-latest` has it.

**The tests.** Three assertions after #354's loop.
1. Every `uses:` the gate workflow renders for every stack, and the
   unattended template's, is listed in tests/run as a commit whose runtime was
   read, with its release and `using:`. The runtime is node24 or composite, and
   the comment after the sha names the listed release. A `uses:` in a shape
   the reader does not parse (`uses :`, a flow mapping) fails, and so does a
   render or reader that exits non-zero. Moving a pin fails until the new
   commit's runtime is read and listed.
2. Every stack's render is silent on stderr.
3. Every `$` and backquote in the heredoc's source is escaped or is one of
   `${felix_repo}`, `${felix_ref}`, `$(_felix_bs_setup_block "$eco")`, and
   the setup block's printf formats hold no `%`.

Section runner (preamble through the line before `resolution`, then the
section), against main 6fe5f986: 1 is red on the four setup pins ("has no
runtime read for it"), and 2 and 3 pass. Mutants, each red on the assertion
meant to catch it:
- 1: go's comment `# v6.2.0` on the v6.5.0 sha; the v6.1.0 sha (node20);
  node's comment removed; unattended's second checkout commented `# v5.0.1`;
  the list recording setup-node as node20; the node step as a flow mapping
  `- {uses: …@49933ea5…}`; `uses :`; an awk shim that exits 2 on any program
  containing ENVIRON, with main's engine.
- 2 and 3: the backquoted `using:` put back.
- 3: `` `pwd` ``; `$HOME`; `node-version: "%s"`.

The adversarial review (one Opus reader, no suite) found the `pwd`/`$HOME`,
flow-mapping, `uses :`, awk-failure and CRLF holes in the first cut, and
three sentences that claimed more than the actions' source. All are fixed
above. It confirmed every sha, tag, runtime and adopter-facing claim, and
that no lower major of any of the five actions runs on Node 24.

**Seen while working, not this change:** at 12:47 the shared
`~/Documents/Felix/.git/config` lost origin and gained
`origin = https://github.com/acme/widget.git`, a tests/run fixture value, and
every `refs/remotes/origin/*` and `branch.*.remote` went with it. About twenty
suites were running at 12:51. `( cd "$VAR" && git remote ... )` in tests/run
acts on the enclosing repository when `$VAR` is empty, since `cd ""`
succeeds. The deny table refused this session's `git remote set-url`; origin
was restored outside this session soon after, and the branch upstreams were
not. A suggested task carries the fixture fix.
