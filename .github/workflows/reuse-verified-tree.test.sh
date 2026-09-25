#!/usr/bin/env bash
# Shows reuse-verified-tree.sh refusing everything it must refuse. A step that
# lets a push to main skip the gate is only believed once it has been seen
# saying no.
#
#   reuse-verified-tree.test.sh <path to reuse-verified-tree.sh>
#
#   exit 0  every case gave the exit it must
#   exit 1  a case did not
#
# GitHub is replaced by a stand-in `gh` that answers each read from a fixture,
# so no case touches the network. The commits are real: #357 landed as
# 174a1435 on f6cc3bc9, from head 27d61d70, so the checkout must hold main's
# history, as the gate's full-depth checkout does.
set -u
STEP="${1:-}"
[ -f "$STEP" ] || { printf 'usage: reuse-verified-tree.test.sh <reuse-verified-tree.sh>\n' >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { printf 'reuse test: no jq on PATH\n' >&2; exit 1; }
tmp="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/reuse-test.XXXXXX")" || exit 1
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"
cat > "$tmp/bin/gh" <<'GH'
#!/usr/bin/env bash
# gh api <url> --jq <filter>, answered from $FX/<which read>.json
[ "$1" = api ] || exit 9
url="$2"; shift 2; f=""
while [ $# -gt 0 ]; do case "$1" in --jq) f="$2"; shift 2 ;; *) shift ;; esac; done
case "$url" in
  */commits/*/pulls) k=pulls ;; */compare/*) k=compare ;;
  */git/commits/*) k=headcommit ;; */actions/workflows/*) k=runs ;; *) exit 9 ;;
esac
[ -f "$FX/$k.fail" ] && { printf 'HTTP 502\n' >&2; exit 1; }
jq -r "$f" "$FX/$k.json"
GH
chmod +x "$tmp/bin/gh"

R=LeavesJ/felix-home; C=174a1435cd3c2a08e18565a163167cf57ece5b5e
H=27d61d704c4d762c68dbcecc3783173d62dc1726; T=ff5a2103b4bf468d0defecb001994d6699a422c1
W=.github/workflows/gate.yml; Z=0000000000000000000000000000000000000000
pass=0; fail=0; n=0

case_() { # name, the exit the step must give
  out="$(PATH="$tmp/bin:$PATH" FX="$FX" GITHUB_REPOSITORY="${GR-$R}" GITHUB_SHA="${GS-$C}" \
    GITHUB_WORKFLOW_REF="${GW-$R/$W@refs/heads/main}" GITHUB_STEP_SUMMARY= bash "$STEP" 2>&1)"
  rc=$?
  if [ "$rc" = "$2" ]; then pass=$((pass+1)); printf 'ok    %-58s exit %s\n' "$1" "$rc"
  else fail=$((fail+1)); printf 'FAIL  %-58s exit %s, want %s: %s\n' "$1" "$rc" "$2" "$out"; fi
}
row() { # id, conclusion, status, created, workflow path, head repository
  printf '{"id":%s,"conclusion":"%s","status":"%s","run_attempt":1,"html_url":"u%s","created_at":"%s","path":"%s","head_repository":{"full_name":"%s"}}' \
    "$1" "$2" "$3" "$1" "$4" "$5" "$6"
}
runs() { printf '{"workflow_runs":[%s]}' "$(IFS=,; printf '%s' "$*")" > "$FX/runs.json"; }
pulls() { # merge commit, merged_at (JSON), head repository (JSON)
  printf '[{"number":357,"merge_commit_sha":"%s","merged_at":%s,"head":{"sha":"%s","repo":%s}}]' "$1" "$2" "$H" "$3" > "$FX/pulls.json"
}
# Every case starts from the one where all four conditions hold.
fresh() {
  n=$((n+1)); FX="$tmp/fx$n"; mkdir -p "$FX"; unset GR GS GW
  pulls "$C" '"2026-09-25T00:51:39Z"' "{\"full_name\":\"$R\"}"
  printf '{"status":"ahead"}' > "$FX/compare.json"
  printf '{"tree":{"sha":"%s"}}' "$T" > "$FX/headcommit.json"
  runs "$(row 1 success completed 2026-09-25T00:26:37Z $W $R)"
}

fresh; case_ "all four hold: reuse" 0
fresh; printf '{"status":"identical"}' > "$FX/compare.json"
       case_ "head identical to main's previous tip: reuse" 0
fresh; runs "$(row 2 failure completed 2026-09-25T00:30:00Z $W $R)" "$(row 1 success completed 2026-09-25T00:26:37Z $W $R)"
       case_ "green, then red on a later run: no" 1
fresh; runs "$(row 1 failure completed 2026-09-25T00:20:00Z $W $R)" "$(row 2 success completed 2026-09-25T00:30:00Z $W $R)"
       case_ "red, then green on a later run: reuse" 0
fresh; runs "$(row 1 cancelled completed 2026-09-25T00:26:37Z $W $R)"
       case_ "latest run cancelled: no" 1
fresh; runs "$(row 1 '' in_progress 2026-09-25T00:26:37Z $W $R)"
       case_ "only an unfinished run: no" 1
fresh; runs "$(row 1 success completed 2026-09-25T00:26:37Z .github/workflows/other.yml $R)"
       case_ "green run of another workflow file: no" 1
fresh; runs "$(row 1 success completed 2026-09-25T00:26:37Z $W someone/fork)"
       case_ "green run from a fork's head: no" 1
fresh; runs
       case_ "no run on the head at all: no" 1
fresh; printf '{"status":"behind"}' > "$FX/compare.json"
       case_ "head behind main's previous tip: no" 1
fresh; printf '{"status":"diverged"}' > "$FX/compare.json"
       case_ "head diverged from main's previous tip: no" 1
fresh; printf '{"tree":{"sha":"%s"}}' "$Z" > "$FX/headcommit.json"
       case_ "head tree is not the landed tree: no" 1
fresh; printf '[]' > "$FX/pulls.json"
       case_ "no pull request landed it (a direct push): no" 1
fresh; pulls "$C" null "{\"full_name\":\"$R\"}"
       case_ "pull request not merged: no" 1
fresh; pulls "$Z" '"2026-09-25T00:51:39Z"' "{\"full_name\":\"$R\"}"
       case_ "commit is in a pull request but is not its merge: no" 1
fresh; pulls "$C" '"2026-09-25T00:51:39Z"' null
       case_ "head repository gone: no" 1
for k in pulls compare headcommit runs; do
  fresh; : > "$FX/$k.fail"; case_ "GitHub read of $k fails: cannot examine" 2
done
fresh; GS=0123456789abcdef0123456789abcdef01234567
       case_ "landed commit not in the checkout: cannot examine" 2
fresh; GW=""; case_ "no workflow ref: cannot examine" 2
fresh; GW="$R/scripts/x.sh@refs/heads/main"
       case_ "workflow ref outside .github/workflows: cannot examine" 2
fresh; GR=""; case_ "no repository: cannot examine" 2

printf '\nreuse test: %s passed, %s failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
