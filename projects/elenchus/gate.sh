#!/usr/bin/env bash
# Elenchus mechanical gate.
#
# Every check here used to be a prose rule in docs/lessons.md that the model was
# asked to remember. It is a script now so it fails loudly instead.
#
#   ./scripts/gate.sh           full gate (format, lint, test, guards)
#   ./scripts/gate.sh --quick   skip the test suite
#
# Gates THE TREE YOU ARE STANDING IN, worktree or main checkout. Exit 0 means every
# check passed. Exit 1 lists what did not. Exit 2 means it refused to run at all.
#
# L-23: never let a piped pytest stand in for "tests passed". Every command here
# writes to a log and the gate branches on the real captured status.

set -uo pipefail

# The tree to gate is the one you are STANDING IN, never the one this file lives in.
# This script is untracked, so it exists only in the main checkout while doctrine says
# to work from a worktree. Deriving REPO_ROOT from BASH_SOURCE made an absolute
# invocation from a worktree cd into the main checkout and gate THAT instead. Verified
# 2026-08-05 from the e4d54e worktree: it printed "gate: /Users/.../Elenchus", ran every
# check against main @ aa950bf, and passed, about a tree holding none of the branch's
# four commits. A false pass is worse than no gate, because it is believed.
if ! REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  echo "gate: $PWD is not inside a git worktree. cd into the tree you want gated." >&2
  exit 2
fi
cd "$REPO_ROOT" || exit 2

# Standing in the WRONG repo is worse than standing outside one: every check below would
# run over someone else's tree and return a verdict in Elenchus's name.
if [ ! -d src/elenchus ]; then
  echo "gate: $REPO_ROOT is a git repo but not Elenchus (no src/elenchus). Refusing." >&2
  exit 2
fi

QUICK=0
for arg in "$@"; do
  case "$arg" in
    --quick) QUICK=1 ;;
    -h|--help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

# L-19: the setuptools editable install is unreliable on this Python 3.14 venv.
# PYTHONPATH=src does not depend on it at all, so it cannot recur.
export PYTHONPATH="src${PYTHONPATH:+:$PYTHONPATH}"
COMMON_ROOT="$(cd "$(git rev-parse --git-common-dir)/.." 2>/dev/null && pwd)"
if [ -x .venv/bin/python ]; then
  PY=.venv/bin/python
elif [ -n "$COMMON_ROOT" ] && [ -x "$COMMON_ROOT/.venv/bin/python" ]; then
  # A worktree created without the .venv symlink has no interpreter of its own. The main
  # checkout's has the dependencies and the system python3 does not, so falling through to
  # python3 turns a green tree red for a reason that has nothing to do with the code.
  PY="$COMMON_ROOT/.venv/bin/python"
else
  PY="$(command -v python3 || true)"
fi

FAILED=""
pass() { printf '  %-18s ok\n' "$1"; }
fail() { printf '  %-18s FAIL\n' "$1"; FAILED="$FAILED $1"; }
note() { printf '  %-18s %s\n' "" "$1"; }

# Say WHICH tree, WHICH commit and WHICH interpreter before any check runs. The old banner
# printed the root alone, so a gate pointed at the wrong tree looked identical to a correct
# one. Two trees on two branches is the normal state here, not the exception.
echo "gate: $REPO_ROOT"
echo "      $(git rev-parse --abbrev-ref HEAD 2>/dev/null) @ $(git rev-parse --short HEAD 2>/dev/null)"
echo "      python: ${PY:-none}"

if [ -z "$PY" ]; then
  echo "  no python interpreter found (.venv/bin/python or python3)" >&2
  exit 2
fi

# --------------------------------------------------------------- format ------
# Ask the formatter what it WOULD rewrite, then rewrite, and report only what IT named.
#
# This used to run the formatter and then report `git diff --name-only -- '*.py'`, which
# conflates "ruff rewrote this" with "this file has uncommitted work". Mid-task that is every
# file you are editing, so the check went red and said "rewrote 3 file(s)" about three files
# ruff had not touched. Verified 2026-08-05: with three edited files in the tree it failed while
# `ruff format --check .` reported "141 files already formatted". A red signal that does not mean
# what its name says is worse than no signal, because it trains you to skip the one gate that
# exists to catch real format drift before a push.
"$PY" -m ruff format --check . >/tmp/ret-gate-format-check.log 2>&1
FMT_CHECK_STATUS=$?
WOULD_FMT="$(sed -n 's/^[[:space:]]*--> \(.*\):[0-9][0-9]*:[0-9][0-9]*$/\1/p' /tmp/ret-gate-format-check.log)"
if ! "$PY" -m ruff format . >/tmp/ret-gate-format.log 2>&1; then
  fail format
  tail -20 /tmp/ret-gate-format.log | sed 's/^/    /'
elif [ "$FMT_CHECK_STATUS" -eq 0 ]; then
  pass format
elif [ -n "$WOULD_FMT" ]; then
  fail format
  note "ruff rewrote $(printf '%s\n' "$WOULD_FMT" | wc -l | tr -d ' ') file(s); review and stage them"
  printf '%s\n' "$WOULD_FMT" | sed 's/^/    /'
else
  # ruff wanted changes but this parse did not recognise its output. The `-->` shape is coupled
  # to the ruff version, so its failure mode must be a loud gate, never a silent green one.
  fail format
  note "ruff format --check exited $FMT_CHECK_STATUS but no filename parsed"
  note "read /tmp/ret-gate-format-check.log; the --> parse above needs updating for this ruff"
fi

# ----------------------------------------------------------------- lint ------
if "$PY" -m ruff check . >/tmp/ret-gate-lint.log 2>&1; then
  pass lint
else
  fail lint
  head -20 /tmp/ret-gate-lint.log | sed 's/^/    /'
  note "full log: /tmp/ret-gate-lint.log"
fi

# ----------------------------------------------------------------- test ------
# Offline only. @live tests are skipif(no ANTHROPIC_API_KEY) and cost money, so
# they are never part of the gate. L-22: a @live test rots silently through a
# signature change precisely because this run does not execute it. When you
# change a signature, grep tests/ for the symbol including the live files.
if [ "$QUICK" -eq 1 ]; then
  printf '  %-18s skipped (--quick)\n' test
else
  if "$PY" -m pytest -q >/tmp/ret-gate-test.log 2>&1; then
    pass test
    note "$(grep -Eo '[0-9]+ passed[^,]*' /tmp/ret-gate-test.log | tail -1)"
  else
    fail test
    grep -E '^(FAILED|ERROR)' /tmp/ret-gate-test.log | head -20 | sed 's/^/    /'
    note "full log: /tmp/ret-gate-test.log"
  fi
fi

# --------------------------------------------------------- confidential ------
# L-2 / L-26. The design docs and the Berkeley Guidebook are personal and
# internal. docs/ and .claude/ are ignored wholesale. Gitignore does not help a
# file that is already tracked, so git ls-files is the authoritative check.
TRACKED_PRIVATE="$(git ls-files | grep -iE 'berkeley|guidebook|blueprint|brief|founderceo|judgmentloop|lifttest|mvp_scope|\.pdf$|^docs/|^\.claude')"
if [ -z "$TRACKED_PRIVATE" ]; then
  pass confidential
else
  fail confidential
  printf '%s\n' "$TRACKED_PRIVATE" | sed 's/^/    /'
  note "git rm -r --cached <path> to untrack"
fi

# -------------------------------------------------------------- secret -------
# The secret scanner existed in prepush.sh and ran only on a local push, so CI
# had no credential detection at all: the one place an accidental key becomes
# permanently public was the one place nothing was looking.
#
# Added lines only, and it degrades to a loud skip rather than a silent pass when
# the tool is missing, because a check that quietly does nothing is worse than an
# absent one.
if [ -n "${FELIX_BIN:-}" ] && [ -x "$FELIX_BIN/secret-scan" ]; then
  if SCAN_OUT="$("$FELIX_BIN/secret-scan" 2>&1)"; then
    pass secret
  else
    fail secret
    printf '%s\n' "$SCAN_OUT" | head -10 | sed 's/^/    /'
  fi
else
  printf '  %-18s skipped (run through felix gate to enable)\n' secret
fi

# ------------------------------------------------------------ lift-bank ------
# The real lift banks stay local. Only the *.example.yaml stubs are tracked.
TRACKED_BANKS="$(git ls-files | grep -E 'content/lift/(scenarios|candidates)\.yaml$')"
if [ -z "$TRACKED_BANKS" ]; then
  pass lift-bank
else
  fail lift-bank
  printf '%s\n' "$TRACKED_BANKS" | sed 's/^/    /'
fi

# --------------------------------------------------------- ignore-leak -------
# L-26. A tracked ignore pattern that names a confidential file leaks the
# existence and nature of exactly what it hides. Those names belong in
# .git/info/exclude, which is local only and never uploaded.
if [ -f .gitignore ]; then
  NAMING="$(grep -iE 'berkeley|guidebook|blueprint|founderceo|judgmentloop|lifttest|mvp_scope' .gitignore)"
  if [ -z "$NAMING" ]; then
    pass ignore-leak
  else
    fail ignore-leak
    printf '%s\n' "$NAMING" | sed 's/^/    /'
    note "move these to .git/info/exclude and keep .gitignore generic"
  fi
fi

# ----------------------------------------------------------- inversion -------
# A dirty tree after a completion claim is a bug, not a todo.
DIRTY="$(git status --short | grep -v '^??')"
if [ -z "$DIRTY" ]; then
  pass inversion
else
  printf '  %-18s dirty\n' inversion
  printf '%s\n' "$DIRTY" | sed 's/^/    /'
  note "fine mid-task; before claiming done, commit these or write a named hold reason in docs/DEVLOG.md"
fi

# ------------------------------------------------------------- verdict -------
echo
if [ -z "$FAILED" ]; then
  echo "gate: pass"
  exit 0
fi
echo "gate: FAIL ($(echo "$FAILED" | tr -s ' ' | sed 's/^ //'))"
exit 1
