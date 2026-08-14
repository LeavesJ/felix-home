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

# Moved above `tests` on 2026-08-13. This check had failed 8 times, every one of
# them discovered after a full suite run, because the loop is edit -> gate ->
# find it never deployed -> bump -> install -> gate again. `felix next` surfaced
# it as a lesson that was written down and kept being violated anyway, which is
# the signal that prose was never the fix. Nothing is removed and nothing is
# weakened: the same checks run, and the one that answers in a second now
# answers before the one that takes minutes.
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
    # A worktree can never satisfy this. The felix marketplace is a directory
    # marketplace pinned to one path, so a worktree's engine is not the one being
    # served and no amount of installing will make the cache match it. The gate
    # still fails — the tree genuinely does not match, and quieting that would be
    # loosening a gate to improve a number — but the failure is marked so it is
    # not written down as a mistake somebody made. Every gate run in a worktree
    # used to add an `installed` row, which is how that check reached 11 and
    # became the top entry of `felix next` rank 5: it manufactured the evidence
    # that ranked it. See issue #3.
    MROOT=""
    if [ -r "$HOME/.claude/plugins/known_marketplaces.json" ]; then
      MROOT="$(sed -n '/"felix"[[:space:]]*:[[:space:]]*{/,/^  }/p' \
                 "$HOME/.claude/plugins/known_marketplaces.json" 2>/dev/null \
               | sed -n 's/.*"installLocation"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
    fi
    if [ -n "$MROOT" ] && [ "$MROOT" != "$ROOT" ]; then
      printf '  %-18s FAIL (structural: the marketplace serves %s)\n' installed "$MROOT"
      FAILED="$FAILED installed"
      printf '    this tree cannot deploy; merge it and run felix install there\n'
    else
      fail installed
      head -5 /tmp/felix-install-drift.log | sed 's/^/    /'
      printf '    reinstall with: felix install\n'
    fi
  fi
else
  printf '  %-18s skipped (no plugin installed here)\n' installed
fi

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

# ------------------------------------------------------------- memory --------
# Two opposite properties, and until 2026-08-14 they were one.
#
# Doctrine must survive the machine, which is what this check was built for. A
# gitignore rule that swallows maintenance.log is invisible: every command works,
# every test passes, and nothing is kept. When it was first written `git
# ls-files` reported zero tracked .log files, so it had never survived once.
#
# Memory must not survive *into this repository*. It holds verbatim founder
# prompts and whatever a governed project's work happens to be about, which
# includes material belonging to somebody who never agreed to be published — so
# a repository storing every governed project's memory can never be public. The
# check that once demanded memory be tracked now demands the reverse. That
# reversal is the point and not a relaxation: this is the only thing that
# notices the old layout creeping back one project at a time, which is exactly
# how it would come back, since `felix adopt` is what creates the directory.
#
# Doctrine is checked against the path rather than against files that happen to
# exist. The first version of that loop skipped anything absent, which made it
# vacuous in a worktree — where these files are untracked and therefore not
# present — so it passed by finding nothing. git check-ignore evaluates a path
# whether or not anything is there, which is what makes it a real check.
MISSED=""
for d in projects/*/; do
  [ -d "$d" ] || continue
  git check-ignore -q "${d}maintenance.log" 2>/dev/null && MISSED="$MISSED ${d}maintenance.log"
done
# Tracked, not merely present. A checkout that has not migrated still has these
# files sitting on disk, and a check that read the disk would fail there forever
# while a check that reads the index says the only thing that matters: whether
# this repository is carrying them.
LEAKED="$(git ls-files -- 'projects/*/memory/*' | tr '\n' ' ')"
if [ -n "$MISSED" ]; then
  fail memory; printf '    doctrine ignored:%s\n' "$MISSED"
elif [ -n "$LEAKED" ]; then
  fail memory
  printf '    memory tracked in this repository: %s\n' "$LEAKED"
  printf '    it belongs under felix_mem_root, outside any checkout.\n'
else
  pass memory
fi

echo
if [ -z "$FAILED" ]; then echo "gate: pass"; exit 0; fi
echo "gate: FAIL ($(echo "$FAILED" | tr -s ' ' | sed 's/^ //'))"
exit 1
