#!/usr/bin/env bash
# Elenchus Capital research gate.
#
# Gates THE TREE YOU ARE STANDING IN. Exit 0 means every check passed, exit 1
# means a check failed, exit 2 means the gate refused to run at all.
#
# Runs the package's own portable check: package integrity, case records and
# contracts, screen arithmetic, case constraints, the 35 synthetic unit tests,
# and both frozen synthetic receipts. Qualified 2026-10-02 against four planted
# defects (changed fact, tampered receipt output, disabled balance-sheet
# identity, invalid finding verdict): each one failed it, the clean copy passed.
#
# Scope: this protects the baseline records and reference code. It does not yet
# check a company model, because none exists. Extend it when the workbook does.

set -uo pipefail

if ! REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  echo "gate: $PWD is not inside a git worktree. cd into the tree you want gated." >&2
  exit 2
fi
cd "$REPO_ROOT" || exit 2

if [ ! -f codex_ready.py ]; then
  echo "gate: no codex_ready.py at $REPO_ROOT; this is not the Elenchus Capital starter." >&2
  exit 2
fi

PY="$(command -v python3 || true)"
if [ -z "$PY" ]; then
  echo "gate: python3 not found." >&2
  exit 2
fi

# macOS hands out /var/... temp dirs that resolve to /private/var/...; two
# synthetic tests compare resolved and unresolved paths and error on the
# mismatch. Resolving TMPDIR fixes the environment without editing test_desk.py,
# which the v2 receipt binds.
TMPDIR="$(cd "${TMPDIR:-/tmp}" && pwd -P)" || exit 2
export TMPDIR

log="$(mktemp "${TMPDIR%/}/elenchus-gate.XXXXXX")" || exit 2
"$PY" codex_ready.py check --full >"$log" 2>&1
rc=$?

if [ "$rc" -ne 0 ]; then
  echo "gate: FAIL (codex_ready.py check --full exited $rc)" >&2
  "$PY" - "$log" <<'EOF' >&2 || cat "$log" >&2
import json, sys
d = json.load(open(sys.argv[1]))
for c in d.get("checks", []):
    if c.get("status") != "PASS":
        print(f"  {c.get('check')}: {c.get('status')}")
for e in d.get("errors", []):
    print("  " + str(e).splitlines()[0])
EOF
  exit 1
fi

echo "gate: PASS (package, records, screen arithmetic, 35 tests, both receipts)"
exit 0
