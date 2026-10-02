### 2026-09-24 — every uses: in the gate workflow bootstrap renders is a commit sha, for every stack it can render

**Engine 0.49.203 (the queue carrier's number), after #331, the tests/red fix,
the persist-credentials PR and #343.** `lib/bootstrap.sh` renders both
`actions/checkout` steps and each stack's setup step pinned to a full commit
sha with the release after it, read from the tags on 2026-09-24:

| Was | Now |
|---|---|
| `actions/checkout@v5` (both, after #331) | `@fbc6f3992d24b796d5a048ff273f7fcc4a7b6c09 # v5.1.0` |
| `actions/setup-node@v4` | `@49933ea5288caeca8642d1e84afbd3f7d6820020 # v4.4.0` |
| `actions/setup-python@v5` | `@a26af69be951a213d495a4c3e4e4022e16d87065 # v5.6.0` |
| `actions/setup-go@v5` | `@40f1582b2485089dde7abd97c1529aa768e1baff # v5.6.0` |
| `dtolnay/rust-toolchain@stable` | `@02cb101ec7c40f2c49e1d9714d64511d8e1b74de # v1`, with `toolchain: stable` |

The rendered workflow says why, beside Felix's own pin: moving an action pin
is the same one-change review as moving the Felix pin, a pull request a person
merges, graded by the action code it names. semgrep 1.175 `p/github-actions`
reads 14 `github-actions-mutable-action-tag` findings across main's five
renders and none across these.

**The test** ("generated CI runs the action code its pins name, and no
other") reads every `uses:` key with the unattended section's reader, over
every stack bootstrap can render. The stacks come from bootstrap, not a list:
the arms of `_felix_bs_setup_block` (alternations split) and the values
`felix_guess_ecosystem` echoes, which is how `none` reaches the fall-through
arm. A scratch copy with an unpinned `java | kotlin` arm failed it untouched.
A second assertion holds the rust step to `toolchain: stable`.

**Traps paid:**
- **dtolnay/rust-toolchain's `stable` is a branch, not a release, and its head
  is not on master.** Its README says a pinned sha outside master's history is
  garbage-collected, so pinning `@stable`'s commit works until it does not. Pin
  master's head and name the toolchain: at master `toolchain` is required.
- **#331's "every checkout ... is v5" counted the literal `actions/checkout@v5`**,
  which a pin turns to 0/2. It now reads the release from the comment after
  the sha; the comment is a claim a reviewer checks when the pin moves.

**Out of scope, and a person's:** felix-home's own `.github/workflows/gate.yml`
still runs `actions/checkout@v4`. It is a workflow file, so a person merges any
change to it.
