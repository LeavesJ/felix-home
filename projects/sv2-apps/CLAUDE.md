# sv2-apps

Governed by Felix. This file is the project constitution: what is true
about the sv2-apps clone at `~/Documents/cash-ops-work/sv2-apps` and nothing else.

This is an **upstream clone**. `origin` is `stratum-mining/sv2-apps`, which J does not
own. Everything here is a contribution to somebody else's repository, made under their
CONTRIBUTING.md and AGENTS.md, which win over anything in this file when they disagree.
The contribution routine lives in the private cash-ops repo (`ops/contribute.md`,
`ops/contrib.py`), and that is where records, drafts and the ledger go. Nothing about a
contribution is written into this tree except the code.

## Boundaries

- Never push to `origin`. Never push anywhere from a Claude session: pushing, forking,
  opening PRs, commenting and replying are J's, and J writes every outward word.
- `.felix` and `AGENTS_CUSTOM.md` are excluded in `.git/info/exclude`. If either shows up
  in `git status`, the exclude was lost; fix it before anything else.
- One local branch per issue, `fix/<issue>-<slug>`, cut from a fresh `origin/main`.
  Review findings are folded into the original commits with fixup + autosquash, never
  added as "address review" commits (CONTRIBUTING.md).
- Commit messages: Conventional Commits, Chris Beams subjects, issue URL in the body of
  the closing commit, no Co-Authored-By trailer. Fix, tests, docs and version bumps are
  separate commits.
- Comments describe the code as it is now, never the bug's history (AGENTS.md).

## Verification

Run the gate before claiming anything is done.

```bash
felix gate            # upstream CI reproduced locally; --quick skips --locked and MSRV
felix gate --integration   # also the integration tests (needs bitcoind on PATH; slow)
```

The gate mirrors `.github/workflows/{ci,tests,lockfiles,msrv,semver-check}.yaml` as of
main `37be0fb`. When upstream edits a workflow, `gate.sh` is stale until re-read.

Two checks the gate cannot make honest on its own:

- `cargo semver-checks` skips every lint once a crate's version is bumped far enough,
  and reports "0 checks, N skip" as a pass. Run it at the commit *before* the bump
  (`python3 ~/Documents/cash-ops/ops/contrib.py semver stratum-mining/sv2-apps <sha>`)
  to see what the API change actually is.
- Integration tests run in CI on every PR and need a running bitcoind; a green gate says
  nothing about them.

## What this project has

- Cargo workspaces: `stratum-apps` (library), `pool-apps`, `miner-apps`,
  `integration-tests`, `bitcoin-core-sv2`. Toolchain 1.88.0 pinned; rustfmt needs
  nightly (`rustfmt.toml` uses nightly-only options); `capnp` from Homebrew.
- Tools CI uses, installed here: cargo-semver-checks 0.44.0, cargo-machete, cargo-nextest
  0.9.100.
- Version discipline: a changed crate must be above its crates.io version
  (`scripts/check-version-bumps.sh origin/main`); dependents that expose its types get a
  bump too; bumps are recorded on the open "version bumps for x.y.z" issue.
- Upstream auto-rebases PRs carrying the `ready-to-be-merged` label (`auto-rebase.yaml`).

## Invariants

1. A claim about upstream behaviour is pinned to a command run in this tree, at a named
   commit. "The binary refuses X" means the binary was run with X and its stderr read.
2. Before writing a test into a file, check open PRs for the same hunk
   (`contrib.py overlap`). Put new tests where the fewest open PRs will collide.
3. Any `#[cfg(test)]` that sets process env vars can race the whole test binary; new
   config-load tests use an unused env prefix.
4. Lockfile diffs are checked line by line: a bump commit changes only the version lines
   of the crates it names.

## Risk

Tiers live in `risk.tsv`, evidence requirements in `evidence.tsv`, both beside this file.
Everything that leaves this machine is J's and is not unattended work.
