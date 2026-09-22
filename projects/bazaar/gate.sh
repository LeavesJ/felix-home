#!/usr/bin/env bash
# The Black Box Bazaar gate. Gates the tree it is standing in, not the tree
# this file lives in, and refuses any tree that is not the bazaar.
set -uo pipefail
if ! ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  echo "gate: $PWD is not inside a git worktree." >&2; exit 2
fi
cd "$ROOT" || exit 2
[ "$(cat .felix 2>/dev/null)" = "bazaar" ] || { echo "gate: $ROOT is not the bazaar (.felix does not say so). Refusing." >&2; exit 2; }
export PATH="$HOME/.foundry/bin:$PATH"
FAILED=""
pass() { printf '  %-12s ok\n' "$1"; }
fail() { printf '  %-12s FAIL\n' "$1"; FAILED="$FAILED $1"; }
echo "gate: $ROOT"
echo "      $(git rev-parse --abbrev-ref HEAD) @ $(git rev-parse --short HEAD)"

# ---- secret: .env must never be tracked, and no 64-hex value may sit in a tracked
# file other than the anvil defaults, which are public by design; the Foundry suite
# and the plan, which carry those defaults and fixed salts; and the one commit-hash
# vector asserted on both sides of the seam (see the constitution), which is a keccak
# output and not a key, so it is allowed by value wherever it appears. agents/test/
# is scanned on purpose: agents/ is yellow and wallets.ts writes role keys nearby.
#
# The hit list is captured and tested for emptiness, never read off the pipeline's
# exit status. `git ls-files` also lists the gitlink lib/forge-std; grep on a
# directory exits 2; and under pipefail that made the whole `if` false whatever the
# last grep had matched, so this check passed on every tree it ever saw. Gitlinks
# are dropped from the list as well. On a hit only path:line is printed, never the
# matched text, which is the thing the check exists to keep out of a log.
HEX64='(^|[^0-9a-fA-F])0x[0-9a-fA-F]{64}([^0-9a-fA-F]|$)'
SEAM_VECTOR=0xe42ef964f458bf6a7f29035d0d681389f65fe8e1462a4346c7ee63f087a9f67f
if git ls-files --error-unmatch .env >/dev/null 2>&1; then fail secret; else
  hits="$(git ls-files -s | awk -F'\t' '$1 !~ /^160000 / { print $2 }' \
    | grep -vE '^agents/src/config\.ts$' \
    | xargs grep -nHsE "$HEX64" \
    | sed "s/$SEAM_VECTOR//g" | grep -E "$HEX64" \
    | grep -vE '^(docs/superpowers/|test/|README)' \
    | cut -d: -f1,2)"
  if [ -n "$hits" ]; then fail secret; printf '%s\n' "$hits" | sed 's/^/    /'; else pass secret; fi
fi

# ---- contracts: every Foundry test, and the count must be what the project says it is.
if command -v forge >/dev/null 2>&1; then
  OUT="$(forge test 2>&1)"; RC=$?
  N="$(printf '%s\n' "$OUT" | grep -oE '[0-9]+ tests passed' | tail -1 | grep -oE '^[0-9]+')"
  if [ $RC -eq 0 ] && [ -n "$N" ] && [ "$N" -ge 27 ]; then pass contracts; else fail contracts; printf '%s\n' "$OUT" | tail -5; fi
else
  fail contracts; echo "  forge is not installed"
fi

# ---- agents: the TypeScript unit tests, including the cross-seam commit-hash vector.
if [ -f agents/package.json ]; then
  if (cd agents && npm test >/tmp/bazaar-agents-test.log 2>&1); then pass agents; else fail agents; tail -8 /tmp/bazaar-agents-test.log; fi
else
  fail agents; echo "  agents/package.json missing"
fi

# ---- abi: the ABI beside the agents and the page must match the compiled contract.
if command -v forge >/dev/null 2>&1 && [ -f out/RefutationMarket.sol/RefutationMarket.json ]; then
  if python3 - <<'PY'
import json,sys
art=json.load(open("out/RefutationMarket.sol/RefutationMarket.json"))["abi"]
ok=all(json.load(open(p))==art for p in ("agents/src/abi.json","docs/abi.json"))
sys.exit(0 if ok else 1)
PY
  then pass abi; else fail abi; echo "  run scripts/export-abi.sh after changing the contract"; fi
else
  fail abi
fi

if [ -n "$FAILED" ]; then echo "gate: FAIL:$FAILED"; exit 1; fi
echo "gate: ok"
