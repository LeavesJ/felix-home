#!/usr/bin/env bash
# The sv2-apps gate: upstream CI, reproduced locally, in the tree it is standing in.
#
# Mirrors .github/workflows/{ci,tests,lockfiles,msrv,semver-check}.yaml at the commit
# this was written (sv2-apps main 37be0fb, 2026-09-22). When upstream CI changes, this
# file is wrong until someone re-reads those workflows: `felix maintenance` names it.
#
# Not here, on purpose:
#   integration-tests   need bitcoind and a template provider; CI runs them. Pass
#                       --integration to run them anyway (slow, needs the network).
#   semver-checks       once a crate's version is bumped enough it SKIPS every check
#                       and passes vacuously ("0 checks, N skip"), so a green run at
#                       HEAD proves nothing. Run it at the commit BEFORE the bump to
#                       see the real verdict:  scripts/contrib semver <sha>
#   openapi validation  only when stratum-apps/src/monitoring/** changes; the gate
#                       runs it if that path is in the diff.
set -uo pipefail
if ! ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  echo "gate: $PWD is not inside a git worktree." >&2; exit 2
fi
cd "$ROOT" || exit 2
[ "$(cat .felix 2>/dev/null)" = "sv2-apps" ] || { echo "gate: $ROOT is not the sv2-apps clone (.felix does not say so). Refusing." >&2; exit 2; }
grep -q 'stratum-mining/sv2-apps' <(git remote get-url origin 2>/dev/null) || { echo "gate: origin is not stratum-mining/sv2-apps. Refusing." >&2; exit 2; }

INTEGRATION=0; QUICK=0
for a in "$@"; do case "$a" in
  --integration) INTEGRATION=1 ;;
  --quick) QUICK=1 ;;   # clippy + fmt + the tests only; skips --locked builds and MSRV --no-run
  *) echo "gate: unknown flag $a" >&2; exit 2 ;;
esac; done

FAILED=""
pass() { printf '  %-14s ok\n' "$1"; }
fail() { printf '  %-14s FAIL\n' "$1"; FAILED="$FAILED $1"; }
run()  { local name="$1"; shift; if "$@" >"$LOG/$name.log" 2>&1; then pass "$name"; else fail "$name"; tail -n 25 "$LOG/$name.log" | sed 's/^/    /'; fi; }
LOG="$(mktemp -d)"
echo "gate: $ROOT"
echo "      $(git rev-parse --abbrev-ref HEAD) @ $(git rev-parse --short HEAD)   logs: $LOG"

# ---- tree: the marker must never be tracked, and the diff must not carry it, an
# AGENTS_CUSTOM.md, or anything Felix wrote. A PR is opened from this tree.
if git ls-files --error-unmatch .felix AGENTS_CUSTOM.md >/dev/null 2>&1; then fail tree; else pass tree; fi

# ---- toolchains: CI pins 1.88 (rust-toolchain.toml) and nightly rustfmt. cargo
# without +toolchain honours rust-toolchain.toml, so plain `cargo` below is 1.88.
if rustup run 1.88.0 rustc --version >/dev/null 2>&1 && cargo +nightly fmt --version >/dev/null 2>&1 \
   && command -v capnp >/dev/null 2>&1; then pass toolchains; else
  fail toolchains; echo "    need: rustup toolchain install 1.88.0; rustup toolchain install nightly --profile minimal --component rustfmt; brew install capnp" ; fi

# ---- fmt (ci.yaml "Format Check", nightly)
fmt_all() { local w; for w in stratum-apps pool-apps miner-apps integration-tests bitcoin-core-sv2; do
  cargo +nightly fmt --all --manifest-path="$w/Cargo.toml" -- --check || return 1; done; }
run fmt fmt_all

# ---- clippy (ci.yaml "Clippy Check", -D warnings)
clippy_all() {
  cargo clippy --manifest-path=stratum-apps/Cargo.toml --all-features -- -D warnings || return 1
  cargo clippy --manifest-path=pool-apps/Cargo.toml -- -D warnings || return 1
  cargo clippy --manifest-path=miner-apps/Cargo.toml -- -D warnings || return 1
  cargo clippy --manifest-path=integration-tests/Cargo.toml -- -D warnings || return 1
  cargo clippy --manifest-path=bitcoin-core-sv2/Cargo.toml -- -D warnings || return 1
}
run clippy clippy_all

# ---- machete (ci.yaml "Unused Dependencies")
if command -v cargo-machete >/dev/null 2>&1; then run machete cargo machete; else fail machete; echo "    need: cargo install cargo-machete --locked"; fi

# ---- tests (tests.yaml, per workspace exactly as CI lists them)
tests_all() {
  cargo test --manifest-path=stratum-apps/Cargo.toml --all-features || return 1
  cargo test --manifest-path=pool-apps/pool/Cargo.toml || return 1
  cargo test --manifest-path=pool-apps/jd-server/Cargo.toml || return 1
  cargo test --manifest-path=miner-apps/Cargo.toml || return 1
  cargo test --manifest-path=bitcoin-core-sv2/Cargo.toml || return 1
}
run tests tests_all

if [ "$QUICK" -eq 0 ]; then
  # ---- lockfiles (lockfiles.yaml): --locked fails if a lockfile would change
  locked_all() {
    cargo build --manifest-path=stratum-apps/Cargo.toml --all-features --locked || return 1
    cargo build --manifest-path=pool-apps/Cargo.toml --locked || return 1
    cargo build --manifest-path=miner-apps/Cargo.toml --locked || return 1
    cargo build --manifest-path=integration-tests/Cargo.toml --locked || return 1
  }
  run lockfiles locked_all

  # ---- msrv (msrv.yaml): tests compile on 1.88 with all features
  msrv_all() {
    cargo test --manifest-path=stratum-apps/Cargo.toml --all-features --no-run || return 1
    cargo test --manifest-path=pool-apps/Cargo.toml --all-features --no-run || return 1
    cargo test --manifest-path=miner-apps/Cargo.toml --all-features --no-run || return 1
    cargo test --manifest-path=integration-tests/Cargo.toml --no-run || return 1
    cargo test --manifest-path=bitcoin-core-sv2/Cargo.toml --no-run || return 1
  }
  run msrv msrv_all
fi

# ---- version bumps (semver-check.yaml, pull_request only): every changed crate
# must be above its crates.io version. Compared against origin/main like CI.
if git rev-parse --verify -q origin/main >/dev/null; then
  if [ -n "$(git diff --name-only "$(git merge-base origin/main HEAD)" HEAD)" ]; then
    run version-bumps ./scripts/check-version-bumps.sh origin/main
  else printf '  %-14s skipped (no diff against origin/main)\n' version-bumps; fi
else fail version-bumps; echo "    origin/main is missing: git fetch origin main"; fi

# ---- openapi (validate-openapi.yaml, only when monitoring code changes)
if git diff --name-only "$(git merge-base origin/main HEAD 2>/dev/null || echo HEAD)" HEAD \
   | grep -qE '^stratum-apps/src/(monitoring/|bin/generate-openapi\.rs)'; then
  openapi_check() {
    (cd stratum-apps && cargo run --bin generate-openapi --features monitoring,asic-rs-telemetry > "$LOG/openapi-fresh.json") || return 1
    diff -q "$LOG/openapi-fresh.json" stratum-apps/src/monitoring/openapi.json
  }
  run openapi openapi_check
fi

# ---- integration (integration-tests.yaml), only on request
if [ "$INTEGRATION" -eq 1 ]; then
  if command -v cargo-nextest >/dev/null 2>&1; then
    run integration env RUST_BACKTRACE=1 cargo nextest run --manifest-path=integration-tests/Cargo.toml
  else fail integration; echo "    need: cargo install cargo-nextest@0.9.100 --locked"; fi
else printf '  %-14s not run (CI runs them; pass --integration)\n' integration; fi

echo
if [ -n "$FAILED" ]; then echo "gate: FAIL:$FAILED"; exit 1; else echo "gate: ok"; exit 0; fi
