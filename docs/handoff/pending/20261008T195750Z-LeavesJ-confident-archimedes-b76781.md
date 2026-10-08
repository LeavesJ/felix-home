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
- **setup-go v6.0.0 and v6.1.0 say Node 24 in their release notes and node20
  in action.yml.** v6.2.0 (#691, "Update Node.js version in action.yml") is
  the first that runs on it. A major is the wrong unit to check; the sha is.
- **dtolnay's v1 moved on 2026-10-01** to master's new head 7e38f4b4, which
  wraps `rustup toolchain install` in up to five tries on a release-server
  checksum failure (+16 −1 in action.yml, read in full). The old pin is still
  on master, so it was not at risk of collection, but `# v1` after it had
  become false.
- **The workflow is an unquoted heredoc.** A backquoted `using:` in a new
  rendered comment ran as a command at render time and left a hole in the
  adopter's file; the #354 loop discarded stderr, so nothing failed. A new
  assertion holds every stack's render silent on stderr.

**What changes for an adopting repository** (both action.yml files and the
release notes, read for each major):
- setup-node v5 caches by itself when package.json names a `packageManager`.
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

**The test.** One assertion after #354's loop reads every `uses:` the gate
workflow renders for every stack, and the unattended template's. Each
`owner/repo@sha` must appear in a list in tests/run of commits whose runtime
was read (release, `using:`), the runtime must be node24 or composite, and the
comment after the sha must name the listed release. Moving a pin fails until
the new commit's runtime is read and listed. Section runner, against main
6fe5f986: red on the four setup pins ("has no runtime read for it"). Mutants,
each red with its own reason: go comment `# v6.2.0` on the v6.5.0 sha; the
v6.1.0 sha (node20); node's comment removed; unattended's second checkout
commented `# v5.0.1`; the list recording setup-node as node20. The stderr
assertion is red with the backquote put back and green on the tree.

**Seen while working, not this change:** at 12:47 the shared
`~/Documents/Felix/.git/config` lost origin and gained
`origin = https://github.com/acme/widget.git`, a tests/run fixture value, and
every `refs/remotes/origin/*` and `branch.*.remote` went with it. About twenty
suites were running at 12:51. `( cd "$VAR" && git remote ... )` in tests/run
acts on the enclosing repository when `$VAR` is empty, since `cd ""`
succeeds. The deny table refused this session's `git remote set-url`; origin
was restored outside this session soon after, and the branch upstreams were
not. A suggested task carries the fixture fix.
