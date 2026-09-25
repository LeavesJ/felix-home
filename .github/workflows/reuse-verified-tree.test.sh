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
# GitHub is replaced by a stand-in `gh` that answers only the exact reads the
# step should make, each from a fixture, and fails any other read. A first
# version answered by the shape of the URL alone, and three broken copies of
# the step passed it: one read main's runs instead of the head's, two read the
# landed commit where they meant the head. A case that expects reuse now
# fails when the step asks the wrong question. No case touches the network.
# The landed commit is real, 174a1435 from #357, so the checkout must hold
# main's history.
set -u
STEP="${1:-}"
[ -f "$STEP" ] || { printf 'usage: reuse-verified-tree.test.sh <reuse-verified-tree.sh>\n' >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { printf 'reuse test: no jq on PATH\n' >&2; exit 1; }
tmp="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/reuse-test.XXXXXX")" || exit 1
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"
cat > "$tmp/bin/gh" <<'GH'
#!/usr/bin/env bash
# gh api <url> --jq <filter>, answered from the fixture $FX/urls.tsv names for
# exactly that url. Any other read is the step asking the wrong question.
[ "$1" = api ] || exit 9
url="$2"; shift 2; f=""
while [ $# -gt 0 ]; do case "$1" in --jq) f="$2"; shift 2 ;; *) shift ;; esac; done
fx="$(awk -F'\t' -v u="$url" '$1 == u { print $2; exit }' "$FX/urls.tsv")"
[ -n "$fx" ] || { printf 'stand-in gh: unexpected read %s\n' "$url" >&2; exit 9; }
[ -f "$FX/$fx.fail" ] && { printf 'HTTP 502\n' >&2; exit 1; }
jq -r "$f" "$FX/$fx.json"
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
  if [ "$rc" = "$2" ]; then pass=$((pass+1)); printf 'ok    %-60s exit %s\n' "$1" "$rc"
  else fail=$((fail+1)); printf 'FAIL  %-60s exit %s, want %s: %s\n' "$1" "$rc" "$2" "$out"; fi
}
row() { # id, conclusion, status, started, workflow path, head repository[, created]
  printf '{"id":%s,"conclusion":"%s","status":"%s","run_attempt":1,"html_url":"u%s","created_at":"%s","run_started_at":"%s","path":"%s","head_repository":{"full_name":"%s"}}' \
    "$1" "$2" "$3" "$1" "${7:-$4}" "$4" "$5" "$6"
}
runs() { printf '{"workflow_runs":[%s]}' "$(IFS=,; printf '%s' "$*")" > "$FX/runs.json"; }
pulls() { # merge commit, merged_at (JSON), head repository (JSON)
  printf '[{"number":357,"merge_commit_sha":"%s","merged_at":%s,"head":{"sha":"%s","repo":%s}}]' "$1" "$2" "$H" "$3" > "$FX/pulls.json"
}
jobs() { printf '{"jobs":[%s]}' "$(IFS=,; printf '%s' "$*")" > "$FX/jobs.json"; }
notes() { # one message per "gated tree" annotation, beside an unrelated notice
  { printf '[{"title":"","message":"Node.js 20 is deprecated."}'
    for m in "$@"; do printf ',{"title":"gated tree","message":"%s"}' "$m"; done; printf ']'; } > "$FX/notes.json"
}
# The four reads the step makes when run 1 is the one that ran last on the head.
urls() {
  printf '%s\tpulls\n' "repos/$R/commits/$C/pulls"
  printf '%s\truns\n' "repos/$R/actions/workflows/gate.yml/runs?head_sha=$H&event=pull_request&per_page=100"
  printf '%s\tjobs\n' "repos/$R/actions/runs/${1:-1}/jobs?filter=latest"
  printf '%s\tnotes\n' "repos/$R/check-runs/70/annotations?per_page=100"
}
# Every case starts from the one where all three conditions hold.
fresh() {
  n=$((n+1)); FX="$tmp/fx$n"; mkdir -p "$FX"; unset GR GS GW
  urls > "$FX/urls.tsv"
  pulls "$C" '"2026-09-25T00:51:39Z"' "{\"full_name\":\"$R\"}"
  runs "$(row 1 success completed 2026-09-25T00:26:37Z $W $R)"
  jobs '{"id":69,"name":"reuse"}' '{"id":70,"name":"gate"}'
  notes "This run gates tree $T"
}

fresh; case_ "all three hold: reuse" 0
fresh; runs "$(row 2 failure completed 2026-09-25T00:30:00Z $W $R)" "$(row 1 success completed 2026-09-25T00:26:37Z $W $R)"
       case_ "green, then a later run red: no" 1
# Run 2 was created first and rerun last. Ordered by creation, run 1 would
# look like the latest, and it is green.
fresh; runs "$(row 2 failure completed 2026-09-25T00:43:29Z $W $R 2026-09-25T00:10:00Z)" "$(row 1 success completed 2026-09-25T00:30:00Z $W $R 2026-09-25T00:20:00Z)"
       case_ "an older run rerun red after a newer one went green: no" 1
fresh; urls 2 > "$FX/urls.tsv"
       runs "$(row 1 failure completed 2026-09-25T00:20:00Z $W $R)" "$(row 2 success completed 2026-09-25T00:30:00Z $W $R)"
       case_ "red, then a later run green: reuse" 0
fresh; runs "$(row 1 cancelled completed 2026-09-25T00:26:37Z $W $R)"
       case_ "the run that ran last was cancelled: no" 1
fresh; runs "$(row 1 '' in_progress 2026-09-25T00:26:37Z $W $R)"
       case_ "only an unfinished run: no" 1
fresh; runs "$(row 1 success completed 2026-09-25T00:26:37Z .github/workflows/other.yml $R)"
       case_ "green run of another workflow file: no" 1
fresh; runs "$(row 1 success completed 2026-09-25T00:26:37Z $W someone/fork)"
       case_ "green run from a fork's head: no" 1
fresh; runs
       case_ "no run on the head at all: no" 1
fresh; notes "This run gates tree $Z"
       case_ "the run gated another tree (another base, or main moved): no" 1
fresh; notes
       case_ "the run named no gated tree (it predates the step): no" 1
fresh; notes "This run gates tree $T" "This run gates tree $T"
       case_ "two gated-tree annotations: no" 1
fresh; notes "This run gates a tree"
       case_ "a gated-tree annotation with no tree in it: no" 1
fresh; jobs '{"id":69,"name":"reuse"}'
       case_ "the run has no gate job: no" 1
fresh; jobs '{"id":70,"name":"gate"}' '{"id":71,"name":"gate"}'
       case_ "the run has two jobs named gate: no" 1
fresh; printf '[]' > "$FX/pulls.json"
       case_ "no pull request landed it (a direct push): no" 1
fresh; pulls "$C" null "{\"full_name\":\"$R\"}"
       case_ "pull request not merged: no" 1
fresh; pulls "$Z" '"2026-09-25T00:51:39Z"' "{\"full_name\":\"$R\"}"
       case_ "commit is in a pull request but is not its merge: no" 1
fresh; pulls "$C" '"2026-09-25T00:51:39Z"' null
       case_ "head repository gone: no" 1
for k in pulls runs jobs notes; do
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
