# veldra

ReserveGrid OS. Veldra, Inc. Rust verification and observability stack for
Bitcoin mining pool templates. Cargo workspace, 16 crates under `services/`,
Rust 2024.

## The doctrine is not here

`.claude/CLAUDE.md` in the checkout is canonical: the operating doctrine, the
T0 through T3 tiers, the ten Invariants, and the delivery rules. Read it there.

This file deliberately does not restate any of it. Two copies of a constitution
drift, and the copy that drifts is the one nobody edits, so a reader who
trusts it is worse off than one who had nothing. What lives here is only what
Felix itself needs and the checkout cannot carry.

## Verification

```bash
felix gate
```

Two checkers, not one. `.claude/CLAUDE.md` GOTCHAS says outright that
"gate.sh is not the only gate. Run `./scripts/superscan.sh --deep-only` too.
D12 asserts canonical counts and checks assertions, not prose." A green
checkmark has already been reported over a red D12 once. The stored `gate`
wrapper runs both and fails if either does.

The canonical `gate.sh` lives HERE, at `projects/veldra/gate.sh`, not in the
repository. That is the point of adopting Felix for this project. Standing
decision 1 keeps it untracked, which meant every fresh worktree lacked it, and
the handoff warns that a reviewer worktree without it "silently downgrades to
a reader". That happened three times in one session. The repo copies are
symlinks to this file, so there is one gate and no drift.

`gate.sh` honours `FELIX_GATE_ROOT`, which the wrapper sets to the checkout
being gated. Without it, `REPO_ROOT` would resolve from the script's own
location to the Felix projects directory and report a verdict about the wrong
tree. Felix's own source calls that out: a false pass is worse than no gate.

Proven to fail, not assumed to:

| probe | gate.sh | superscan | `felix gate` |
| --- | --- | --- | --- |
| baseline | pass | 16 / 0 | 0 |
| broken Rust | FAIL (fmt clippy test) | - | 1 |
| compose var no code reads | pass | FAIL: 1 | 1 |

The third is the load-bearing one: gate.sh passed and the composite still
failed. Re-run these if the wrapper changes.

`gate.sh`'s own `fmt` check reports FAIL for ANY uncommitted `.rs` change.
That is a known quirk, not a real failure; `cargo fmt --all --check` is the
honest oracle mid-task.

## What this project has

- ci, deploy, frontend, rust, secrets

The frontend is `services/rg-dashboard`, a served asset rather than an
application. Route accordingly; this is a backend.

## Invariants

Empty on purpose. The ten that bind this project are in the checkout's
`.claude/CLAUDE.md` and are not copied here for the reason given above.

This section is for lessons Felix earns from `memory/mistakes.log` via
`felix promote`, which are a different thing: things the gate caught twice.
Write them down as they arrive.

## Risk

Tiers live in `risk.tsv`, evidence requirements in `evidence.tsv`, both beside
this file. `felix classify` and `felix evidence` read them.

Note the checkout's doctrine already defines T0 through T3 with its own
meanings, and T3 there means "stop and ask J". Where the two vocabularies
disagree, the checkout wins, because that is the one a reviewer will read.
