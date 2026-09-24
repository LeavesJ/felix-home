### 2026-09-23/24 — the unattended template left two credentials for the model to read, measured on the pinned binary and closed upstream of the model

**Engine change: `templates/unattended.yml`, `tests/run`, 0.49.183.** The
open items of §0bz and §0by stand. Read
[docs/handoff/0bz.md](docs/handoff/0bz.md).

**The finding.** Both checkouts in the unattended repair job persisted what
they fetched with: the job's token as an `http.extraheader` in
`repo/.git/config`, the deploy key as a file under `$RUNNER_TEMP` named by
`felix/.git/config`. The model step runs `claude -p --allowedTools
"Read,Edit"`. Measured on the real 2.1.37 against a scripted Messages API
(the rig from §0bx, with its traps now in auto-memory):
- with `Read` allowed, all three files read, and Edit put both credentials
  into a tracked file that `git commit -am` would push;
- without `Read` in `--allowedTools`, the two paths outside the working
  directory were refused, and `repo/.git/config` still read;
- `bin/secret-scan` passed the diff: it knows `ghp_` and `github_pat_`, not
  `ghs_`, and no base64 header.

**What changed.** Neither checkout persists; the push step carries
`GITHUB_TOKEN` in its own env and hands it to git through a credential
helper, in no file and no argument; and the model's tools are
`Read(./**),Edit(./**)` with `.git/**` denied, after a peer session (3faa7f)
named the vector a bare `Edit` leaves: `core.hooksPath` in `repo/.git/config`
runs code in the verify step's own git, with the token in its env. Measured:
the `.git/**` deny alone still let `../felix/.git/config` be edited (a
bare-path deny matches only under cwd); the scoped allow refuses everything
outside cwd. Session f19a22 adds `Read(//proc/**)` on the same line
(`/proc/self/environ` returns `ANTHROPIC_API_KEY` on ubuntu-latest); the two
fold at whichever merge is second. Invariant 4 was weighed in the PR: no
credential is created, rotated or re-scoped, and §0ac's read-only key stands.
The loop has never been on, so nothing needs rotating.

**Left as chips, not done:** `ghs_` and basic-auth shapes for the scanner;
`/proc/self/environ` on a Linux runner; `lib/bootstrap.sh`'s gate workflow
persisting the same key; Elenchus's copy to re-copy from the new pin.

**Trap paid for:** a test that could not fail. The checkout-enumeration
assertion passed against the unfixed template because its ternary was
inverted; the red run caught it only because the run was actually done.
