printf '\na reused tests verdict merges only on a green CI gate (contract A2, blind)\n'
# Written from docs/2026-10-12-gate-friction-contract-a2.md alone, C9.1 to
# C9.5. felix-home has no branch protection and `felix merge` asks CI nothing:
# its boundary is the receipt. Contract A lets the receipt's tests verdict come
# from a reused suite run (`tests:reused` in the sixth field), so a merge on
# such a receipt also needs the gate workflow to have passed on the exact head.
#
# Everything here is this part's own: a project, a checkout, a stub gh first
# on PATH that records every call and answers from a file, and nothing that
# reaches a network. The checkout's origin names github.com so a slug can be
# read from it, and GIT_ALLOW_PROTOCOL keeps git itself from ever going there.
# The judge is loaded the way the merge boundary loads it for felix-home
# (_felix_kernel_blockers): six libraries, set -uo pipefail, a child bash.
_gfcP="$FROOT/projects/gfcw"
_gfcR="$TMP/gfc-repo"
_gfcG="$TMP/gfc-gh"
mkdir -p "${_gfcP:?}" "${_gfcR:?}" "${_gfcG:?}/bin" "$MEM/gfcw"
cp "$TMP/probes.keep" "$_gfcP/probes.tsv"
cp "$TMP/obligations.keep" "$_gfcP/obligations.tsv"
cp "$TMP/commissioning.keep" "$_gfcP/commissioning.tsv"
cp "$REAL_HARNESS/templates/risk.tsv" "$_gfcP/risk.tsv"
printf '# gfcw\n' > "$_gfcP/CLAUDE.md"
# A gate workflow that is not the default, so a call that names gate.yml, or
# no workflow at all, is told apart from one that asks felix_gate_workflow.
cat > "$_gfcP/project.json" <<'EOF'
{
  "name": "gfcw",
  "remote_match": "example.invalid/gfcw",
  "gate": "true",
  "gate_workflow": "ci-gate.yml"
}
EOF
( cd "${_gfcR:?}" && git init -q -b main && printf 'gfcw\n' > .felix && printf 'one\n' > NOTES.txt \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm base \
  && git checkout -q -b gfc-topic && printf 'two\n' >> NOTES.txt \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm change \
  && git remote add origin https://github.com/gfc-owner/gfcw.git ) >/dev/null 2>&1
_gfcR="$(cd "${_gfcR:?}" && pwd -P)"
_gfcH="$(git -C "${_gfcR:?}" rev-parse HEAD 2>/dev/null)"
_gfcO="$(git -C "${_gfcR:?}" rev-parse HEAD~1 2>/dev/null)"
_gfcH8="$(printf '%s' "$_gfcH" | cut -c1-8)"
_gfcPre="the gate reused a suite run for this tree (tests:reused), and the gate workflow has not passed on $_gfcH8:"

# The stub. Every call is one line in calls. mode decides the answer: runs
# answers `gh run list` from runs.json the way gh does (filtered by
# --workflow, --commit, --branch and --status, newest first, cut to --limit,
# --json fields checked against the ones gh knows and kept, --jq applied by
# jq -r), fail exits 1 with nothing on stdout, empty prints nothing and exits
# 0, garbage prints a page that is not JSON and exits 0. `auth status` and
# `repo view` are answered so a preflight does not read as GitHub failing.
cat > "$_gfcG/bin/gh" <<'GFCSTUB'
#!/usr/bin/env bash
d="$(cd "$(dirname "$0")/.." && pwd)"
printf '%s\n' "$*" >> "$d/calls"
mode="$(cat "$d/mode" 2>/dev/null)"
case "$mode" in
  fail)    printf 'HTTP 502: Bad Gateway (https://api.github.com/graphql)\n' >&2; exit 1 ;;
  empty)   exit 0 ;;
  garbage) printf '<html><body><h1>502 Bad Gateway</h1></body></html>\n'; exit 0 ;;
esac
case "${1:-} ${2:-}" in
  "auth status") printf 'github.com\n  Logged in to github.com account gfc-owner\n'; exit 0 ;;
  "repo view")   printf 'gfc-owner/gfcw\n'; exit 0 ;;
  "run list")    shift 2 ;;
  *) printf 'gh stub: not answered here: %s\n' "$*" >&2; exit 1 ;;
esac
wf=""; c=""; b=""; s=""; n=20; json=""; q=""; jsonset=0
while [ $# -gt 0 ]; do
  case "$1" in
    -w|--workflow) wf="${2:-}"; shift 2 ;;  --workflow=*) wf="${1#*=}"; shift ;;
    -c|--commit)   c="${2:-}"; shift 2 ;;   --commit=*)   c="${1#*=}"; shift ;;
    -b|--branch)   b="${2:-}"; shift 2 ;;   --branch=*)   b="${1#*=}"; shift ;;
    -s|--status)   s="${2:-}"; shift 2 ;;   --status=*)   s="${1#*=}"; shift ;;
    -L|--limit)    n="${2:-}"; shift 2 ;;   --limit=*)    n="${1#*=}"; shift ;;
    --json)        json="${2:-}"; jsonset=1; shift 2 ;; --json=*) json="${1#*=}"; jsonset=1; shift ;;
    -q|--jq)       q="${2:-}"; shift 2 ;;   --jq=*)       q="${1#*=}"; shift ;;
    -R|--repo|-e|--event|-u|--user|--created) shift 2 ;;
    *) shift ;;
  esac
done
case "$n" in ''|*[!0-9]*) printf 'invalid value for --limit: %s\n' "$n" >&2; exit 1 ;; esac
[ -z "$q" ] || [ "$jsonset" -eq 1 ] || { printf 'cannot use `--jq` without specifying `--json`\n' >&2; exit 1; }
for f in $(printf '%s' "$json" | tr ',' ' '); do
  case " attempt conclusion createdAt databaseId displayTitle event headBranch headSha name number startedAt status updatedAt url workflowDatabaseId workflowName " in
    *" $f "*) ;;
    *) printf 'Unknown JSON field: "%s"\n' "$f" >&2; exit 1 ;;
  esac
done
sel="$(jq -c --arg wf "$wf" --arg c "$c" --arg b "$b" --arg s "$s" --argjson n "$n" --arg f "$json" '
  [ .[] | select(($wf == "" or ._wf == $wf or .workflowName == $wf)
             and ($c == "" or .headSha == $c) and ($b == "" or .headBranch == $b)
             and ($s == "" or .status == $s or .conclusion == $s)) ] | .[:$n]
  | if $f == "" then . else map(with_entries(select(.key as $k | ($f | split(",")) | index($k)))) end
' "$d/runs.json")" || exit 1
if [ "$jsonset" -eq 0 ]; then
  printf '%s\n' "$sel" | jq -r '.[] | "\(.status)\t\(.conclusion)\t\(.displayTitle)\t\(.workflowName)\t\(.headBranch)\t\(.event)\t\(.databaseId)\t1m0s\t\(.createdAt)"'
elif [ -n "$q" ]; then
  printf '%s\n' "$sel" | jq -r "$q"
else
  printf '%s\n' "$sel"
fi
GFCSTUB
chmod +x "$_gfcG/bin/gh"

# One run as gh's JSON knows it. _wf is the workflow's file, which gh matches
# --workflow against and never prints. conclusion is "" until a run completes.
_gfcRun() {   # id sha status conclusion workflow-file
  printf '{"databaseId":%s,"number":%s,"attempt":1,"status":"%s","conclusion":"%s","headSha":"%s","headBranch":"gfc-topic","event":"pull_request","displayTitle":"gfc change","name":"%s","workflowName":"%s","workflowDatabaseId":7,"_wf":"%s","createdAt":"2026-10-12T20:%02d:00Z","startedAt":"2026-10-12T20:%02d:00Z","updatedAt":"2026-10-12T20:%02d:30Z","url":"https://github.com/gfc-owner/gfcw/actions/runs/%s"}' \
    "$1" "$1" "$3" "$4" "$2" "${5%.yml}" "${5%.yml}" "$5" "$1" "$1" "$1" "$1"
}
_gfcCase() {  # mode [run...]: what gh answers, newest run first; empties the record
  local IFS=,
  printf '%s\n' "$1" > "${_gfcG:?}/mode"; shift
  printf '[%s]\n' "$*" > "$_gfcG/runs.json"
  : > "$_gfcG/calls"
}
_gfcCalls() { cat "${_gfcG:?}/calls" 2>/dev/null; }

# A receipt for this exact tree, reporting what the gate reported. The
# commission receipt beside it, which every green merge fixture has, is keyed
# to the tables and the checkout, neither of which moves here, so it is
# stamped once.
_gfcRcpt() {  # rc reported [tree id]
  ( cd "${_gfcR:?}" && . "$FROOT/harness/lib/verify.sh"
    felix_verify_record "$_gfcR" "$FROOT" "$1" "gate.sh" "${3:-$(felix_tree_id "$_gfcR" "$FROOT")}" "" "$2" ) >/dev/null 2>&1
}
( cd "${_gfcR:?}" && FELIX_HOME_DIR="$FROOT"; . "$FROOT/harness/lib/commission.sh"
  _o="$(felix_commission_run "$_gfcP" "$_gfcR" -)"
  felix_commission_receipt_write "$FROOT" "$_gfcP" "$_gfcR" "$_o" "" ) >/dev/null 2>&1

# The judge, loaded as the merge boundary loads it. $1 is the PATH it runs on.
_gfcBlk() {
  ( cd "${_gfcR:?}" && GIT_ALLOW_PROTOCOL=file PATH="$1" bash -c '
      set -uo pipefail
      k="$1"
      for f in resolve verify review classify evidence escape; do . "$k/lib/$f.sh" 2>/dev/null || exit 3; done
      felix_merge_blockers "$2" HEAD~1 "$3" "$4"
    ' _ "$FROOT/harness" "$_gfcP" "$_gfcR" "$FROOT" ) 2>/dev/null
}
_gfcPATH="$_gfcG/bin:$PATH"

# A PATH with no gh on it at all: every directory that holds one is replaced
# by a copy of its entries, as links, without gh.
_gfcNoGh=""; _gfci=0
_gfcIFS="$IFS"; IFS=:
for _gfcd in $PATH; do
  [ -n "$_gfcd" ] || continue
  if [ -e "$_gfcd/gh" ] || [ -L "$_gfcd/gh" ]; then
    _gfci=$((_gfci+1)); mkdir -p "${_gfcG:?}/nogh$_gfci"
    ln -s "$_gfcd"/* "$_gfcG/nogh$_gfci/" 2>/dev/null; rm -f "$_gfcG/nogh$_gfci/gh"
    _gfcNoGh="${_gfcNoGh:+$_gfcNoGh:}$_gfcG/nogh$_gfci"
  else
    _gfcNoGh="${_gfcNoGh:+$_gfcNoGh:}$_gfcd"
  fi
done
IFS="$_gfcIFS"

# What a reused receipt's blockers came to: `held` when they are exactly one
# row, unverified/tests, whose reason begins with the contract's sentence and
# then says what held; otherwise what came instead.
_gfcHeld() {  # blockers tail
  local n r
  n="$(printf '%s\n' "$1" | LC_ALL=C awk 'NF { c++ } END { print c + 0 }')"
  r="$(printf '%s\n' "$1" | LC_ALL=C awk -F'\t' '$1 == "unverified" && $2 == "tests" { print $3; exit }')"
  if [ "$n" != 1 ] || [ -z "$r" ]; then printf 'rows=%s [%s]' "$n" "$(printf '%s' "$1" | LC_ALL=C tr '\t\n' ' |')"; return 0; fi
  case "$r" in
    "$_gfcPre"*"$2"*) printf 'held' ;;
    *) printf 'reason [%s]' "$r" ;;
  esac
}
_gfcLacks() { case "$2" in *"$3"*) bad "$1" "[$2] holds [$3]" ;; *) ok "$1" ;; esac; }

_gfcRO="syntax:ok,tests:reused,secret:ok"
_gfcFail="$(_gfcRun 41 "$_gfcH" completed failure ci-gate.yml)"

is "the A2 fixture has two commits and a head sha to name" \
   "$(printf '%s %s' "${#_gfcH}" "${#_gfcO}")" "40 40"
is "the A2 fixture's PATH without gh finds no gh" \
   "$(PATH="$_gfcNoGh" command -v gh >/dev/null 2>&1 && echo found || echo none)" "none"

# The stub answers a run list through jq. Where there is none, every
# assertion that needs an answered run list is a skip, by name, and the rest
# still run.
_gfcJq=0; command -v jq >/dev/null 2>&1 && _gfcJq=1
_gfcIs()  { if [ "$_gfcJq" = 1 ]; then is "$@";  else skip "$1" "no jq here for the gh stub"; fi; }
_gfcHas() { if [ "$_gfcJq" = 1 ]; then has "$@"; else skip "$1" "no jq here for the gh stub"; fi; }

# The stub itself, asked directly: on today's engine nothing else reaches its
# run-list answer, so a stub that answered wrongly would hold a correct rule.
_gfcCase runs "$(_gfcRun 40 "$_gfcH" completed success ci-gate.yml)" "$(_gfcRun 39 "$_gfcO" completed failure ci-gate.yml)" \
              "$(_gfcRun 38 "$_gfcH" completed failure lint.yml)"
_gfcIs "the A2 stub answers the gate workflow's runs on one commit as gh would" \
   "$(PATH="$_gfcPATH" gh run list --repo gfc-owner/gfcw --workflow ci-gate.yml --commit "$_gfcH" \
        --json status,conclusion,headSha -q '.[] | "\(.status) \(.conclusion) \(.headSha)"' 2>&1)" "completed success $_gfcH"

# Each judge call costs two to three seconds of CPU, so each case below is
# one call, and the cases are the contract's: one per bullet of C9.3 (in
# progress stands for every status that is not completed), the two that C9.1
# and C9.4 name, the three ways gh cannot answer, and one dry run.

# ---- C9.4: a receipt without tests:reused asks nothing ---------------------
# gh is set to fail, so a rule that asked would show it twice: in the
# blockers and in the record.
_gfcRcpt 0 "syntax:ok,tests:ok,secret:ok"; _gfcCase fail
is "C9.4: a green receipt reading tests:ok clears every blocker, as today" "$(_gfcBlk "$_gfcPATH")" ""
is "C9.4: and gh is not called at all" "$(_gfcCalls)" ""

# ---- C9.1, C9.2: a completed success on the exact head ---------------------
_gfcRcpt 0 "$_gfcRO"
_gfcCase runs "$(_gfcRun 40 "$_gfcH" completed success ci-gate.yml)"
_gfcIs "C9.2: a reused receipt with the gate workflow's success on the head clears every blocker" \
   "$(_gfcBlk "$_gfcPATH")" ""
_gfcC="$(_gfcCalls)"
_gfcHas "C9.1: and that was asked of gh run list" "$_gfcC" "run list"
_gfcHas "C9.1: for the workflow felix_gate_workflow names (ci-gate.yml here)" "$_gfcC" "ci-gate.yml"

# ---- C9.3: each way the head has no passing gate run -----------------------
_gfcCase runs
_gfcB="$(_gfcBlk "$_gfcPATH")"
_gfcIs "C9.3: no gate run at all holds the merge: no run on this commit" "$(_gfcHeld "$_gfcB" "no run on this commit")" "held"
_gfcIs "C9.3: the reason begins with the contract's sentence and the head's first 8" \
   "$(printf '%s\n' "$_gfcB" | LC_ALL=C awk -F'\t' '$2 == "tests" { print substr($3, 1, length(p)) }' p="$_gfcPre")" "$_gfcPre"

# A gate success on another commit, and another workflow's success on this
# one: neither is the gate workflow passing on the head.
_gfcCase runs "$(_gfcRun 41 "$_gfcH" completed success lint.yml)" "$(_gfcRun 40 "$_gfcO" completed success ci-gate.yml)"
_gfcIs "C9.3: a gate success on another commit only (and lint's on this one) is no run on this commit" \
   "$(_gfcHeld "$(_gfcBlk "$_gfcPATH")" "no run on this commit")" "held"

_gfcCase runs "$(_gfcRun 40 "$_gfcH" in_progress "" ci-gate.yml)"
_gfcIs "C9.3: a gate run in progress on the head holds: its run is in_progress" \
   "$(_gfcHeld "$(_gfcBlk "$_gfcPATH")" "its run is in_progress")" "held"

_gfcCase runs "$(_gfcRun 40 "$_gfcH" completed failure ci-gate.yml)"
_gfcIs "C9.3: a failed gate run on the head holds: its run concluded failure" \
   "$(_gfcHeld "$(_gfcBlk "$_gfcPATH")" "its run concluded failure")" "held"

# ---- C9.3: GitHub could not be asked: unreadable is never no runs, never a pass
# The runs file holds a success on the head each time, so a rule that read
# past the failure to it would pass.
_gfcCase runs "$(_gfcRun 40 "$_gfcH" completed success ci-gate.yml)"
_gfcB="$(_gfcBlk "$_gfcNoGh")"
is "C9.3: gh missing holds the merge: GitHub could not be asked (...)" \
   "$(_gfcHeld "$_gfcB" "GitHub could not be asked (")" "held"
_gfcLacks "C9.3: and gh missing is not read as no run" "$_gfcB" "no run on this commit"
for _gfcm in fail empty; do
  _gfcCase "$_gfcm" "$(_gfcRun 40 "$_gfcH" completed success ci-gate.yml)"
  _gfcB="$(_gfcBlk "$_gfcPATH")"
  is "C9.3: gh answering $_gfcm holds the merge: GitHub could not be asked (...)" \
     "$(_gfcHeld "$_gfcB" "GitHub could not be asked (")" "held"
  _gfcLacks "C9.3: and gh answering $_gfcm is not read as no run" "$_gfcB" "no run on this commit"
done

# ---- C9.5: felix merge --dry-run reports it as it reports the others --------
# The dry run also carries the cancelled conclusion, so it is judged once,
# through the CLI, and not again through the judge.
_gfcCase runs "$(_gfcRun 40 "$_gfcH" completed cancelled ci-gate.yml)"
_gfcOut="$( cd "${_gfcR:?}" && GIT_ALLOW_PROTOCOL=file PATH="$_gfcPATH" "$FELIX" merge --base HEAD~1 --dry-run 2>&1 )"; _gfcRc=$?
_gfcIs "C9.5: felix merge --dry-run refuses a reused receipt whose head's gate run was cancelled" "$_gfcRc" "3"
_gfcHas "C9.5: and prints the blocker on its own line, as the others are printed" "$_gfcOut" \
    "$(printf '  %-11s %-22s %s' unverified tests "$_gfcPre")"
_gfcHas "C9.3/C9.5: saying what held: its run concluded cancelled" "$_gfcOut" "its run concluded cancelled"

rm -rf "${_gfcP:?}" "${MEM:?}/gfcw"
