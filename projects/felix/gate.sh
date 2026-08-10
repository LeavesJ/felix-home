#!/usr/bin/env bash
# Felix's own gate.
#
# Felix had 140 assertions and nothing that ran them, which is the same gap it
# was built to close in every other project. A governance layer that is not
# itself governed is an argument nobody has to take seriously.
#
# Gates the tree it is standing in, not the tree this file lives in.

set -uo pipefail

if ! ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  echo "gate: $PWD is not inside a git worktree." >&2; exit 2
fi
cd "$ROOT" || exit 2
[ -d engine/harness ] || { echo "gate: $ROOT is not Felix (no engine/harness). Refusing." >&2; exit 2; }

FAILED=""
pass() { printf '  %-18s ok\n' "$1"; }
fail() { printf '  %-18s FAIL\n' "$1"; FAILED="$FAILED $1"; }

echo "gate: $ROOT"
echo "      $(git rev-parse --abbrev-ref HEAD) @ $(git rev-parse --short HEAD)"

# ------------------------------------------------------------- syntax --------
# Every shell file must parse. A harness that fails to source is a harness that
# silently governs nothing, and that failure is invisible in a session hook.
BAD=""
while IFS= read -r f; do
  bash -n "$f" 2>/dev/null || BAD="$BAD $f"
done <<EOF
$(git ls-files 'engine/harness/*' 'projects/*/*.sh' | grep -vE '\.(json|tsv|md|ya?ml)$')
EOF
[ -z "$BAD" ] && pass syntax || { fail syntax; printf '    %s\n' $BAD; }

# ------------------------------------------------------------- executable ----
# A hook or a tool that lost its executable bit fails at the worst moment, in
# somebody else's session, with no output.
NOX=""
for f in engine/harness/felix engine/harness/hooks/session-start \
         engine/harness/tests/run engine/harness/bin/secret-scan; do
  [ -x "$f" ] || NOX="$NOX $f"
done
[ -z "$NOX" ] && pass executable || { fail executable; printf '    %s\n' $NOX; }

# ------------------------------------------------------------- tests ---------
if [ "${1:-}" = "--quick" ]; then
  printf '  %-18s skipped (--quick)\n' tests
elif ./engine/harness/tests/run >/tmp/felix-gate-tests.log 2>&1; then
  pass tests
  printf '                     %s\n' "$(tail -1 /tmp/felix-gate-tests.log)"
else
  fail tests
  grep '^  FAIL' /tmp/felix-gate-tests.log | head -10 | sed 's/^/  /'
  printf '                     full log: /tmp/felix-gate-tests.log\n'
fi

# ------------------------------------------------------------- secret --------
if [ -x engine/harness/bin/secret-scan ]; then
  if OUT="$(engine/harness/bin/secret-scan 2>&1)"; then pass secret
  else fail secret; printf '%s\n' "$OUT" | head -8 | sed 's/^/    /'; fi
fi

# ------------------------------------------------------------- independence --
# The engine must name no specific project. Restated here rather than left to
# the suite alone, because this is the property that makes Felix portable and it
# is the one most easily lost to a well-meant comment.
if git grep -qniE 'elenchus' -- engine/harness/felix engine/harness/lib engine/harness/hooks 2>/dev/null; then
  fail independence
  git grep -niE 'elenchus' -- engine/harness/felix engine/harness/lib engine/harness/hooks | head -5 | sed 's/^/    /'
else
  pass independence
fi

echo
if [ -z "$FAILED" ]; then echo "gate: pass"; exit 0; fi
echo "gate: FAIL ($(echo "$FAILED" | tr -s ' ' | sed 's/^ //'))"
exit 1
