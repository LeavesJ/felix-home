### 2026-09-24 — bootstrap's rendered gate workflow keeps no credential after its checkouts

**One engine PR from this session, #379, version 0.49.229.** It changes
`lib/bootstrap.sh` and `tests/run`, and landed behind #331 in the queue
carrier's order. The open items of §0bz and §0by stand.

**The finding.** `felix_bs_render_workflow` writes the `gate.yml` a governed
project commits. Both of its checkouts kept the default persist-credentials:
- the Felix checkout left the deploy key in a file under `$RUNNER_TEMP`, named
  by `felix/.git/config`'s `core.sshCommand`;
- the project checkout left the job token in `repo/.git/config`.

Meanwhile `felix gate` runs the pull request's own test code in the same job.
It is the hole #344 closed in `templates/unattended.yml`, and #344's handoff
left it as a chip.

**The fix.** Both checkouts set `persist-credentials: false`. Nothing after
the fetch needs either credential:
- the job has `contents: read` and pushes nothing;
- the engine is read from disk;
- no gate path fetches, pulls or pushes. The engine's one network git call is
  in `discover.sh`, and project gates read refs already fetched.

**Tests.** Three assertions, written blind by an agent that never saw the
change. They read the rendered workflow for node, python, rust, go and an
unrecognised ecosystem, and they enumerate every checkout step:
- a key in a comment, in another step or in the header does not count;
- a render with no checkout fails.

Each of nine mutants turns at least one assertion red. All three fail
against main's renderer (see red.tsv).

**Not done here:**
- **Consumers keep their old workflow until someone re-renders it.** Elenchus
  commits its own `.github/workflows/gate.yml`, and a workflow change in a
  governed repository is the founder's to merge.
- **felix-home's own `.github/workflows/gate.yml` had the same hole, and #346
  closed it** before #379 landed. Its checkouts set `persist-credentials:
  false` on main. The first version of this section said otherwise, and was
  corrected after the merge.
- **Sha-pinning the rendered workflow's actions is #354, open.** Its title
  says every `uses:` in the rendered gate workflow names a full commit sha,
  for every stack. Pinned by sha, `dtolnay/rust-toolchain` needs
  `with: toolchain: stable`.
