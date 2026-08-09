#!/usr/bin/env bash
# Pre-push guard for the PUBLIC repo. Run from the repo root or any worktree.
#
#   ./scripts/prepush.sh [<upstream-ref>]      default upstream: origin/main
#
# UNTRACKED BY DESIGN, same status as scripts/gate.sh. Adding either to the tracked set changes
# what the public repo contains, which is a founder call.
#
# What this can and cannot do. It checks the TRACKED SET and the DIFF you are about to publish:
# paths that should never be public, secrets, absolute local paths, private context, and that the
# tree is green. It cannot tell you whether prose in a tracked file is something you want public.
# Read the diff. This narrows what you have to read; it does not replace reading it.

set -uo pipefail

# Reads candidate lines on stdin, prints the ones that look like a real secret VALUE.
#
# The old pattern was `... |token *[=:]| ...`, which flagged the IDENTIFIER regardless of what it
# held: `token: str = ""`, `token = secrets.token_urlsafe(9)`, `{text:text,token:token}` all
# tripped it. That is not conservatism, it is a false-positive surface wide enough that the guard
# stops being read -- and a guard nobody reads is how a real key ships. It is also how this repo's
# own author came to pipe the guard into `tail`, masking its exit status, and push against a
# failure. Categories preserved: provider keys, private keys, bearer tokens, and any credential
# keyword ASSIGNED A QUOTED LITERAL. Excluded: declarations, empty and near-empty strings,
# runtime-generated values, environment lookups, and object property names.
secret_hits() {
  grep -inE \
    'sk-ant-[A-Za-z0-9_-]{16,}|BEGIN [A-Z ]*PRIVATE KEY|[Bb]earer [A-Za-z0-9._-]{20,}|(api[_-]?key|secret|password|passwd|token|credential)[a-z_]*[[:space:]]*[=:][[:space:]]*["'"'"'][^"'"'"']{8,}["'"'"']' \
  | grep -viE 'ANTHROPIC_API_KEY|os\.environ|getenv|environ\[|secrets\.[a-z_]+\(|token_urlsafe|token_hex|uuid4|<[^>]*>|example|placeholder|redacted|xxx+|\.\.\.' \
  || true
}

# `./scripts/prepush.sh --self-test` -- explicit positive and negative cases for the detector.
# A guard whose own behaviour is untested is a guess about what it catches.
if [ "${1:-}" = "--self-test" ]; then
  fails=0
  must_flag() { printf '%s\n' "$1" | secret_hits | grep -q . || { echo "  MISS  $1"; fails=$((fails+1)); }; }
  must_pass() { printf '%s\n' "$1" | secret_hits | grep -q . && { echo "  FALSE $1"; fails=$((fails+1)); } || true; }

  echo "positives (must flag):"
  must_flag '+api_key = "sk-ant-api03-AAAAAAAAAAAAAAAAAAAAAAAA"'
  must_flag '+-----BEGIN RSA PRIVATE KEY-----'
  must_flag '+headers = {"Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6"}'
  must_flag '+password = "hunter2-correct-horse"'
  must_flag '+SECRET = "s3cr3t-value-not-a-name"'
  must_flag "+token = 'abcd1234efgh5678ijkl'"
  echo "negatives (must NOT flag):"
  must_pass '+    token: str = ""'
  must_pass '+                    token = secrets.token_urlsafe(9)'
  must_pass '+  post(url,{text:text,token:token})'
  must_pass '+    def record_expectation(self, session_id: str, text: str, token: str = ""):'
  must_pass '+  d.dataset.expToken = token;'
  must_pass '+api_key = os.environ["ANTHROPIC_API_KEY"]'
  must_pass '+password = "<redacted>"'
  must_pass '+# the secret: never hardcode a credential here'
  echo
  [ "$fails" -eq 0 ] && { echo "self-test: PASS"; exit 0; } || { echo "self-test: $fails FAILURE(S)"; exit 1; }
fi

UPSTREAM="${1:-origin/main}"
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT" || exit 2

fails=0
pass() { printf '  PASS  %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; fails=$((fails + 1)); }
note() { printf '  ..    %s\n' "$1"; }

if ! git rev-parse --verify --quiet "$UPSTREAM" >/dev/null; then
  echo "No upstream ref '$UPSTREAM'. Pass one explicitly, or push a first branch by hand."
  exit 2
fi
RANGE="$UPSTREAM..HEAD"
COUNT=$(git rev-list --count "$RANGE")
BRANCH=$(git rev-parse --abbrev-ref HEAD)
# State the tree first, loudly. This guard operates on whatever working tree you launch it from,
# and the main checkout and each worktree sit on different branches: run it from the wrong one and
# it will pass every check against code you did not mean to publish.
echo "Pre-push guard"
echo "  tree   : $ROOT"
echo "  branch : $BRANCH  @ $(git rev-parse --short HEAD)"
echo "  range  : $RANGE  ($COUNT commit(s))"
if [ "$COUNT" -eq 0 ]; then
  echo
  echo "  NOTHING TO PUSH on this branch. If you expected commits here, you are in the wrong tree."
  exit 1
fi
echo

# ---------------------------------------------------------------- the tracked set

echo "TRACKED SET"
CONFIDENTIAL='berkeley|guidebook|blueprint|brief|founderceo|judgmentloop|lifttest|mvp_scope|\.pdf|^docs/|^\.claude|^\.superpowers|^data/|^\.env'
hits=$(git ls-files | grep -iE "$CONFIDENTIAL" || true)
if [ -z "$hits" ]; then pass "no confidential or machine-local path is tracked"
else fail "these are TRACKED and would be published:"; printf '        %s\n' $hits; fi

# The tracked .gitignore must stay generic: a pattern naming a secret is itself a leak.
if git diff --quiet "$UPSTREAM" HEAD -- .gitignore; then
  pass ".gitignore unchanged in this range"
else
  note ".gitignore CHANGED in this range - read it, a pattern that names a secret is itself a leak:"
  git diff "$UPSTREAM" HEAD -- .gitignore | sed 's/^/        /'
fi

added=$(git diff --name-only --diff-filter=A "$RANGE" || true)
if [ -z "$added" ]; then pass "no new files join the tracked set"
else note "new files joining the tracked set - confirm each belongs in public:"; printf '        %s\n' $added; fi
echo

# ---------------------------------------------------------------- the diff's content

echo "DIFF CONTENT"
plus() { git diff "$RANGE" | grep '^+' | grep -v '^+++'; }


s=$(plus | secret_hits || true)
[ -z "$s" ] && pass "no secret-shaped literal in added lines" || { fail "possible secret in added lines:"; printf '        %s\n' "$s"; }

p=$(plus | grep -nE '/Users/|/home/[a-z]|C:\\\\' || true)
[ -z "$p" ] && pass "no absolute local path in added lines" || { fail "absolute local path in added lines:"; printf '        %s\n' "$p"; }

# Private context. Widen this list as the private surface grows; it is cheap and it is the check
# most likely to catch something a path guard cannot.
c=$(plus | grep -inE 'jarron|riyan|deng|berkeley|stripe|y combinator|\byc\b|investor|cap table|valuation' || true)
[ -z "$c" ] && pass "no private-context term in added lines" || { fail "private context in added lines:"; printf '        %s\n' "$c"; }
echo

# ---------------------------------------------------------------- the tree

echo "TREE"
git diff --quiet && git diff --cached --quiet && pass "working tree clean" || fail "working tree is dirty - commit or stash first"

t=$(git log "$RANGE" --format='%b' | grep -ci 'co-authored' || true)
[ "$t" = "0" ] && pass "no Co-Authored-By trailer in the range" || fail "$t commit(s) carry a Co-Authored-By trailer"

VENV="$ROOT/.venv/bin"
[ -x "$VENV/python" ] || VENV="$(git rev-parse --git-common-dir)/../.venv/bin"
if [ -x "$VENV/python" ]; then
  if PYTHONPATH=src "$VENV/python" -m pytest -q -m "not live" >/tmp/prepush-pytest.log 2>&1; then
    pass "suite green ($(tail -1 /tmp/prepush-pytest.log | tr -d '\n'))"
  else
    fail "suite RED - see /tmp/prepush-pytest.log"; tail -5 /tmp/prepush-pytest.log | sed 's/^/        /'
  fi
  "$VENV/python" -m ruff check . >/dev/null 2>&1 && pass "ruff check clean" || fail "ruff check FAILED"
  "$VENV/python" -m ruff format --check . >/dev/null 2>&1 && pass "ruff format clean" || fail "ruff format FAILED"
else
  fail "no .venv found - cannot run the suite, and a push should not go out unverified"
fi
echo

# ---------------------------------------------------------------- verdict

if [ "$fails" -eq 0 ]; then
  echo "ALL GUARDS PASS. Now read the diff before you push:"
  echo "    git diff $RANGE --stat"
  echo "    git log --oneline $RANGE"
  exit 0
fi
echo "$fails GUARD(S) FAILED. Do not push."
exit 1
