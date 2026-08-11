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
$(git ls-files 'engine/harness/*' 'projects/*/*.sh' | grep -vE '\.(json|tsv|md|ya?ml|html|css|txt)$')
EOF
[ -z "$BAD" ] && pass syntax || { fail syntax; printf '    %s\n' $BAD; }

# ------------------------------------------------------------- executable ----
# A hook or a tool that lost its executable bit fails at the worst moment, in
# somebody else's session, with no output.
#
# Enumerated, never listed. This named three hooks by hand and there were seven:
# the four newest were never checked, and would have failed silently in somebody
# else's session while this printed ok. A list of things to check is a list that
# stops matching what exists, which is the same defect the coverage table exists
# to catch — found in the check that was supposed to be catching it.
NOX=""
for f in engine/harness/felix engine/harness/tests/run engine/harness/bin/secret-scan \
         engine/harness/hooks/*; do
  [ -e "$f" ] || continue
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

# ------------------------------------------------------------- installed -----
# Written is not installed. The lessons hook existed in the repository, passed
# its tests, and was absent from the plugin cache, so it ran nowhere. A harness
# change that is not deployed governs nothing, and nothing else would have said
# so.
#
# Compared against the version actually active, not merely the first one found.
# The cache keeps every version it has ever installed, so after a bump from
# 0.1.0 to 0.2.0 the old copy is still sitting there and `head -1` picks it:
# the check then fails permanently against a directory nothing loads, while a
# genuinely stale deployment would look identical. Ask the CLI, which knows
# which one is live; fall back to the highest version when it is absent.
#
# Skipped when no plugin is installed, which is the normal state in CI.
PLUG="$(claude plugin list --json 2>/dev/null \
        | sed -n '/"felix@felix"/,/}/p' \
        | sed -n 's/.*"installPath"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
if [ -n "$PLUG" ]; then
  PLUG="$PLUG/harness"
else
  PLUG="$(ls -d "$HOME"/.claude/plugins/cache/felix/felix/*/harness 2>/dev/null | sort -V | tail -1)"
fi
if [ -n "$PLUG" ] && [ -d "$PLUG" ]; then
  if diff -rq engine/harness "$PLUG" >/tmp/felix-install-drift.log 2>&1; then
    pass installed
  else
    fail installed
    head -5 /tmp/felix-install-drift.log | sed 's/^/    /'
    printf '    reinstall with: felix install\n'
  fi
else
  printf '  %-18s skipped (no plugin installed here)\n' installed
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

# ------------------------------------------------------------- memory --------
# Felix exists so that doctrine and memory survive the machine. A gitignore rule
# that swallows them is precisely the failure this repository was created to
# prevent, and it is invisible: every command works, every test passes, and
# nothing is kept. When this check was written, `git ls-files` reported zero
# tracked .log files, so mistakes.log and maintenance.log had never survived.
#
# Checked against the paths rather than against files that happen to exist. The
# first version of this loop skipped anything absent, which made it vacuous in a
# worktree — where these files are untracked and therefore not present — so it
# passed by finding nothing. git check-ignore evaluates a path whether or not
# anything is there, which is the property that makes this a real check.
MISSED=""
for d in projects/*/; do
  [ -d "$d" ] || continue
  for f in "${d}memory/mistakes.log" "${d}memory/verification.log" "${d}maintenance.log"; do
    git check-ignore -q "$f" 2>/dev/null && MISSED="$MISSED $f"
  done
done
[ -z "$MISSED" ] && pass memory || { fail memory; printf '    ignored:%s\n' "$MISSED"; }

echo
if [ -z "$FAILED" ]; then echo "gate: pass"; exit 0; fi
echo "gate: FAIL ($(echo "$FAILED" | tr -s ' ' | sed 's/^ //'))"
exit 1
