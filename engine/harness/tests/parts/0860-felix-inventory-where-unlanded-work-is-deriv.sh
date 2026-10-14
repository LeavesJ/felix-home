printf '\nfelix inventory: where unlanded work is, derived from disk, git, gh and the host\n'

# One scratch root holds everything the command may read: a bare origin, a
# main clone whose origin names GitHub (pushes are rewritten to the bare one
# and fetches are not, so a fetch fails rather than reaching anything),
# worktrees and orphans beside the clone, a second small repository for
# --repo, gh and git behind stand-ins that log every call, and a scratch HOME
# with Claude Code transcripts. The engine is a plain copy laid out the way a
# clone lays it out, with no install, as the audit section's is.
IV="$TMP/inventory"; mkdir -p "$IV"; IV="$(cd "$IV" && pwd -P)"
IVW="$IV/work"; IVM="$IVW/widget"; IVO="$IV/origin.git"
IVW2="$IV/work2"; IVG="$IVW2/gadget"; IVO2="$IV/origin2.git"
IVH="$IV/home"; IVP="$IVH/.claude/projects"; IVT="$IV/tmp"
IVGH="$IV/gh"; IVSTUB="$IV/stub"; IVGH_LOG="$IV/gh.log"; IVGIT_LOG="$IV/git.log"; IV_ERR="$IV/stderr"
mkdir -p "$IVW" "$IVW2" "$IVH/.config" "$IVP" "$IVT" "$IVGH" "$IVSTUB" "$IV/cwd" "$IV/clone/felix/engine"
: > "$IVGH_LOG"; : > "$IVGIT_LOG"; : > "$IV_ERR"
_copy_content "$REAL_HARNESS" "$IV/clone/felix/engine/harness"
IVF="$IV/clone/felix/engine/harness/felix"
IV_REALGIT="$(command -v git)"
IV_JQ=0; command -v jq >/dev/null 2>&1 && IV_JQ=1
IV_ORDER='hazard:shared-branch hazard:staged-revert live question blocked uncommitted unpushed unproposed pr-open pr-closed-unlanded orphan chip-unstarted handoff-pending landed'
IV_WTS='wt-squash wt-same wt-dirty wt-unpushed wt-unproposed wt-closed wt-sharea wt-shareb wt-revert wt-live wt-query wt-bold wt-answered wt-blocked wt-unread'

# The fixture's own git: a scratch HOME, no system config, a fixed author. Its
# reads take no optional lock, so checking the fixture cannot refresh an index
# the read-only assertion watches. Commits no worktree holds are built in a
# temporary index outside every repository.
_ivg() { HOME="$IVH" XDG_CONFIG_HOME="$IVH/.config" GIT_CONFIG_NOSYSTEM=1 \
         GIT_AUTHOR_NAME=Fixture GIT_AUTHOR_EMAIL=fixture@example.invalid \
         GIT_COMMITTER_NAME=Fixture GIT_COMMITTER_EMAIL=fixture@example.invalid git "$@"; }
_ivq() { _ivg --no-optional-locks "$@"; }
_ivi() { GIT_INDEX_FILE="$IV/idx" HOME="$IVH" XDG_CONFIG_HOME="$IVH/.config" GIT_CONFIG_NOSYSTEM=1 git "$@"; }
IVC=""
_ivc() {  # repo parent message path content [path content]... -> IVC
  local r="$1" par="$2" msg="$3" blob tree; shift 3
  _ivi -C "$r" read-tree "$par"
  while [ $# -ge 2 ]; do
    blob="$(printf '%s\n' "$2" | _ivg -C "$r" hash-object -w --stdin)"
    _ivi -C "$r" update-index --add --cacheinfo "100644,$blob,$1"
    shift 2
  done
  tree="$(_ivi -C "$r" write-tree)"
  IVC="$(_ivg -C "$r" commit-tree "$tree" -p "$par" -m "$msg")"
}
_ivwc() { _ivg -C "$1" add -A && _ivg -C "$1" commit -q -m "$2"; }
_ivwt() { _ivg -C "$IVM" worktree add -q "$@"; }
_ivrepo() {  # bare clone owner/name
  _ivg -c init.defaultBranch=main init -q --bare "$1"
  _ivg -C "$1" symbolic-ref HEAD refs/heads/main
  _ivg -c init.defaultBranch=main -c "url.$1.insteadOf=https://github.com/$3.git" \
       clone -q "https://github.com/$3.git" "$2" 2>/dev/null
  _ivg -C "$2" symbolic-ref HEAD refs/heads/main
  _ivg -C "$2" config "url.$1.pushInsteadOf" "https://github.com/$3.git"
}
# A time N minutes ago, as a transcript timestamp or as touch -t wants it.
_ivago() {
  local t f u=-u
  t=$(( $(date +%s) - $1 * 60 ))
  if [ "$2" = touch ]; then f='+%Y%m%d%H%M.%S'; u=""; else f='+%Y-%m-%dT%H:%M:%S.000Z'; fi
  date $u -r "$t" "$f" 2>/dev/null || date $u -d "@$t" "$f"
}
_ivtouch() { touch -t "$(_ivago "$2" touch)" "$1"; }
# The host's directory for a working directory: every character outside
# [A-Za-z0-9-] becomes -, as the spec's adapter section says.
_ive() { printf '%s/' "$IVP"; printf '%s' "$1" | sed 's/[^A-Za-z0-9-]/-/g'; }
_ivopen() { _au_open "$(_ive "$1")/$2.jsonl" "$2"; }

# ---- widget: main, and the branches cut from it --------------------------
_ivrepo "$IVO" "$IVM" acme/widget
mkdir -p "$IVM/src"
printf 'widget\n' > "$IVM/README.md"; printf 'core line\n' > "$IVM/src/core.txt"
printf 'old\n' > "$IVM/src/old.txt"; printf 'base\n' > "$IVM/src/conflict.txt"
printf '*.log\n' > "$IVM/.gitignore"
_ivwc "$IVM" 'the first widget'; IV_C0="$(_ivg -C "$IVM" rev-parse HEAD)"
_ivc "$IVM" "$IV_C0" 'the squash feature' src/squash.txt 'squash feature'; IV_S1="$IVC"
_ivc "$IVM" "$IV_C0" 'the superseded file' src/superseded.txt 'superseded'; IV_X1="$IVC"
_ivc "$IVM" "$IV_C0" 'two files, one of them main'"'"'s' src/partly-a.txt 'A' src/partly-b.txt 'B'; IV_PA="$IVC"
_ivc "$IVM" "$IV_C0" 'the branch side' src/conflict.txt 'branch side' src/plain.txt 'plain'; IV_PL="$IVC"
_ivc "$IVM" "$IV_C0" 'precedes, first' src/precedes.txt 'one'; IV_P1="$IVC"
_ivc "$IVM" "$IV_P1" 'precedes, second' src/precedes.txt "$(printf 'one\ntwo')"; IV_P2="$IVC"
# Main takes #4101 by squash (same content, no ancestry), a second edition
# that deletes old.txt, holds superseded.txt and partly-a.txt as the branches
# have them and changes conflict.txt, then #4102 squashed with an edit made
# in review, and one handoff section waiting in pending/.
printf 'squash feature\n' > "$IVM/src/squash.txt"
_ivwc "$IVM" 'the squash feature (#4101)'
rm -f "$IVM/src/old.txt"
printf 'widget, second edition\n' > "$IVM/README.md"; printf 'superseded\n' > "$IVM/src/superseded.txt"
printf 'A\n' > "$IVM/src/partly-a.txt"; printf 'main side\n' > "$IVM/src/conflict.txt"
_ivwc "$IVM" 'the second edition'
printf 'one\ntwo, as edited in review\n' > "$IVM/src/precedes.txt"
mkdir -p "$IVM/docs/handoff/pending"
cat > "$IVM/docs/handoff/pending/20260920T101010Z-frobnicator.md" <<'IVEOF'
### 2026-09-20 - the frobnicator waits

The frobnicator was designed here and not built.

**Next:**
- Build the frobnicator.
- Measure the frobnicator.

**Traps paid:**
- Ignore this trap line.
IVEOF
_ivwc "$IVM" 'precedes, squashed with an edit (#4102), and a pending handoff'
IV_C3="$(_ivg -C "$IVM" rev-parse HEAD)"
_ivg -C "$IVM" push -q origin main
_ivg -C "$IVM" remote set-head origin main

# ---- worktrees beside the clone, and two orphans -------------------------
_ivg -C "$IVM" branch topic/squash "$IV_S1"
_ivwt "$IVW/wt-squash" topic/squash
_ivwt -b topic/same "$IVW/wt-same" "$IV_C0"
for _ivn in dirty unpushed unproposed closed revert live query bold answered blocked unread; do
  _ivwt -b "topic/$_ivn" "$IVW/wt-$_ivn" "$IV_C3"
done
_ivg -C "$IVM" branch topic/shared "$IV_C3"
_ivwt "$IVW/wt-sharea" topic/shared
_ivwt -f "$IVW/wt-shareb" topic/shared
_ivwt --detach "$IVW/orphan-edit" "$IV_C3"
_ivwt --detach "$IVW/orphan-clean" "$IV_C3"
printf 'unpushed\n' > "$IVW/wt-unpushed/src/unpushed.txt"; _ivwc "$IVW/wt-unpushed" 'work nobody pushed'
printf 'unproposed\n' > "$IVW/wt-unproposed/src/unproposed.txt"; _ivwc "$IVW/wt-unproposed" 'work pushed with no pull request'
printf 'closed\n' > "$IVW/wt-closed/src/closed.txt"; _ivwc "$IVW/wt-closed" 'work whose pull request was closed'
IV_CL="$(_ivg -C "$IVW/wt-closed" rev-parse HEAD)"
# The staged revert, as the sweep found it: wt-revert commits its tip, then
# another checkout moves the branch on. wt-revert's HEAD follows the branch,
# and its index still holds the first tip.
printf 'revert one\n' > "$IVW/wt-revert/src/revert-one.txt"; _ivwc "$IVW/wt-revert" 'the first tip'
IV_R1="$(_ivg -C "$IVW/wt-revert" rev-parse HEAD)"
_ivc "$IVM" "$IV_R1" 'adopted by another checkout' src/revert-two.txt 'revert two'; IV_R2="$IVC"
_ivg -C "$IVM" update-ref -m 'adopted by another checkout' refs/heads/topic/revert "$IV_R2" "$IV_R1"
# Branches with no worktree: pull request heads (hold's felix/ready status
# sits on its parent, not its head), one pushed with no pull request, and
# local ones never pushed, two of them making the same change.
_ivc "$IVM" "$IV_C3" 'hold, first' src/hold.txt 'hold one'; IV_H0="$IVC"
_ivc "$IVM" "$IV_H0" 'hold, second' src/hold.txt 'hold two'; IV_H1="$IVC"
_ivc "$IVM" "$IV_C3" 'ready' src/ready.txt 'ready'; IV_Y1="$IVC"
_ivc "$IVM" "$IV_C3" 'needs the founder' src/needs.txt 'needs'; IV_N1="$IVC"
_ivc "$IVM" "$IV_C3" 'remote only' src/remote-only.txt 'remote only'; IV_RO="$IVC"
_ivc "$IVM" "$IV_C3" 'the duplicate, once' src/dup.txt 'duplicate'; IV_D1="$IVC"
_ivc "$IVM" "$IV_C3" 'the duplicate, twice' src/dup.txt 'duplicate'; IV_D2="$IVC"
_ivg -C "$IVM" branch topic/superseded "$IV_X1"
_ivg -C "$IVM" branch topic/partly "$IV_PA"
_ivg -C "$IVM" branch topic/precedes "$IV_P1"
_ivg -C "$IVM" branch topic/dup-one "$IV_D1"
_ivg -C "$IVM" branch topic/dup-two "$IV_D2"
_ivg -C "$IVM" push -q origin topic/squash topic/superseded topic/unproposed topic/closed topic/revert \
  "$IV_P2:refs/heads/topic/precedes" "$IV_PL:refs/heads/topic/pr-plain" "$IV_H1:refs/heads/topic/pr-hold" \
  "$IV_Y1:refs/heads/topic/pr-ready" "$IV_N1:refs/heads/topic/pr-needs" "$IV_RO:refs/heads/topic/remote-only"
# Uncommitted: a staged edit, an untracked file and an ignored one. Landed
# though dirty: an untracked file and an edit that both hold main's content,
# a deletion main made too, and an ignored file.
printf 'dirty edit\n' >> "$IVW/wt-dirty/src/core.txt"; _ivg -C "$IVW/wt-dirty" add src/core.txt
printf 'fresh\n' > "$IVW/wt-dirty/src/untracked-new.txt"; printf 'noise\n' > "$IVW/wt-dirty/build.log"
printf 'squash feature\n' > "$IVW/wt-same/src/squash.txt"; rm -f "$IVW/wt-same/src/old.txt"
printf 'widget, second edition\n' > "$IVW/wt-same/README.md"; printf 'noise\n' > "$IVW/wt-same/debug.log"
# The orphans: git's record of them goes and the files stay, .git link too.
# One holds two files whose content is in no object; the other holds none.
printf 'orphan-only line\n' >> "$IVW/orphan-edit/src/core.txt"
mkdir -p "$IVW/orphan-edit/notes"; printf 'only here\n' > "$IVW/orphan-edit/notes/orphan-new.txt"
rm -rf "$IVM/.git/worktrees/orphan-edit" "$IVM/.git/worktrees/orphan-clean"

# ---- gadget: a second repository, for --repo ----------------------------
_ivrepo "$IVO2" "$IVG" acme/gadget
printf 'gadget\n' > "$IVG/README.md"; _ivwc "$IVG" 'the first gadget'
_ivg -C "$IVG" push -q origin main
_ivg -C "$IVG" remote set-head origin main
_ivc "$IVG" "$(_ivg -C "$IVG" rev-parse HEAD)" 'gadget work nobody pushed' src/gadget.txt 'gadget'
_ivg -C "$IVG" branch topic/gadget-only "$IVC"

# Every index goes stale: a file's mtime moves and its content does not, so a
# git status that refreshes the index would rewrite it, and the read-only
# assertion sees any git read taken without --no-optional-locks.
for _ivn in widget $IV_WTS; do _ivtouch "$IVW/$_ivn/README.md" 1440; done
_ivtouch "$IVG/README.md" 1440

# ---- GitHub, as the stand-in answers it ----------------------------------
# One JSON object per pull request, in gh's field names. #4101 and #4102
# merged, #4107 and #4108 closed unmerged, five open.
: > "$IVGH/prs.lines"
_ivpr() {  # number branch state head updated-min labels mergeable rollup merged-min closed-min
  local lab="" l one up cr me=null cl=null ms=CLEAN
  for l in $6; do
    printf -v one '{"id":"LA_%s","name":"%s","description":"","color":"ededed"}' "$l" "$l"
    lab="$lab${lab:+,}$one"
  done
  up="$(_ivago "$5" iso)"; cr="$(_ivago 6000 iso)"
  [ "$9" = - ] || me="\"$(_ivago "$9" iso)\""
  [ "${10}" = - ] || cl="\"$(_ivago "${10}" iso)\""
  [ "$7" = CONFLICTING ] && ms=DIRTY
  printf -v one '{"number":%s,"title":"Change %s","state":"%s","isDraft":false,"headRefName":"%s","headRefOid":"%s","baseRefName":"main","createdAt":"%s","updatedAt":"%s","mergedAt":%s,"closedAt":%s,"labels":[%s],"mergeable":"%s","mergeStateStatus":"%s","statusCheckRollup":[%s],"url":"https://github.com/acme/widget/pull/%s","author":{"login":"fixture"},"headRepositoryOwner":{"login":"acme"},"reviewDecision":""}' \
    "$1" "$1" "$3" "$2" "$4" "$cr" "$up" "$me" "$cl" "$lab" "$7" "$ms" "$8" "$1"
  printf '%s\n' "$one" >> "$IVGH/prs.lines"
}
printf -v IV_ROLL '{"__typename":"StatusContext","context":"felix/ready","state":"SUCCESS","targetUrl":"","description":"ready","startedAt":"%s"}' "$(_ivago 100 iso)"
_ivpr 4101 topic/squash     MERGED "$IV_S1" 2880 ''              UNKNOWN     ''         2880 2880
_ivpr 4102 topic/precedes   MERGED "$IV_P2" 2400 ''              UNKNOWN     ''         2400 2400
_ivpr 4103 topic/pr-hold    OPEN   "$IV_H1" 1800 'felix:hold'    MERGEABLE   ''         -    -
_ivpr 4104 topic/pr-ready   OPEN   "$IV_Y1" 120  'felix:founder' MERGEABLE   "$IV_ROLL" -    -
_ivpr 4105 topic/pr-plain   OPEN   "$IV_PL" 300  ''              CONFLICTING ''         -    -
_ivpr 4106 topic/pr-needs   OPEN   "$IV_N1" 480  'needs-founder' MERGEABLE   ''         -    -
_ivpr 4107 topic/closed     CLOSED "$IV_CL" 1200 ''              UNKNOWN     ''         -    1200
_ivpr 4108 topic/superseded CLOSED "$IV_X1" 1500 ''              UNKNOWN     ''         -    1500
_ivpr 4109 topic/revert     OPEN   "$IV_R2" 60   ''              MERGEABLE   ''         -    -
LC_ALL=C awk 'BEGIN { printf "[" } NR > 1 { printf "," } { printf "%s", $0 } END { print "]" }' "$IVGH/prs.lines" > "$IVGH/prs.json"
printf -v _ivst '{"context":"felix/ready","state":"success","description":"ready","target_url":"","created_at":"%s","updated_at":"%s","creator":{"login":"felix"}}' "$(_ivago 100 iso)" "$(_ivago 100 iso)"
printf '{"%s":[%s],"%s":[%s]}\n' "$IV_H0" "$_ivst" "$IV_Y1" "$_ivst" > "$IVGH/statuses.json"

# The gh stand-in: pr list/view/checks, repo view, auth status and api GETs
# for commit statuses and pulls, from the files above, in gh's shapes, with
# --json fields, --jq, --state, --head and --search head: honoured. Every call
# is logged first. It serves no graphql and no write.
printf '#!/bin/bash\nD=%s\nL=%s\n' "'$IVGH'" "'$IVGH_LOG'" > "$IVSTUB/gh"
cat >> "$IVSTUB/gh" <<'IVGHEOF'
set -f
printf '%s\n' "$*" >> "$L"
KEEP='def pr_keep($f): if $f == "" then . else ($f | split(",")) as $k | with_entries(select(.key as $x | any($k[]; . == $x))) end;'
SEL='def pr_sel($st; $hd): select(($st == "all") or ($st == "open" and .state == "OPEN") or ($st == "closed" and (.state == "CLOSED" or .state == "MERGED")) or ($st == "merged" and .state == "MERGED")) | select($hd == "" or .headRefName == $hd);'
REST='def pr_rest: {number, title, state: (if .state == "OPEN" then "open" else "closed" end), draft: .isDraft, merged_at: .mergedAt, closed_at: .closedAt, created_at: .createdAt, updated_at: .updatedAt, head: {ref: .headRefName, sha: .headRefOid, label: ("acme:" + .headRefName)}, base: {ref: .baseRefName}, labels: [.labels[] | {name}], user: {login: .author.login}, html_url: .url, mergeable: (if .mergeable == "CONFLICTING" then false elif .mergeable == "MERGEABLE" then true else null end), mergeable_state: (if .mergeable == "CONFLICTING" then "dirty" elif .mergeable == "MERGEABLE" then "clean" else "unknown" end)};'
FIND='def pr_find($p): [.[] | select((.number | tostring) == $p or .headRefName == $p)] | sort_by([(if .state == "OPEN" then 1 else 0 end), .updatedAt]) | last;'
CHECKS='def pr_checks($l): [$l[] | {name: .context, state: (.state | ascii_upcase), bucket: (if .state == "success" then "pass" elif .state == "pending" then "pending" else "fail" end), link: .target_url, description, workflow: ""}];'
COMB='(.[$s] // []) as $l | {sha: $s, total_count: ($l | length), statuses: $l, state: (if ($l | length) == 0 then "pending" elif all($l[]; .state == "success") then "success" elif any($l[]; .state == "failure" or .state == "error") then "failure" else "pending" end)}'
PLIST=' [.[] | pr_sel($st; $hd) | pr_keep($f)]'
PTSV=' .[] | pr_sel($st; $hd) | [(.number | tostring), .title, .headRefName, .state, .createdAt] | @tsv'
PVIEW=' pr_find($p) | if . == null then empty else pr_keep($f) end'
PSHA=' pr_find($p) | if . == null then empty else .headRefOid end'
PCHK=' pr_checks(.[$s] // [])'
PBYSHA=' [.[] | select(.headRefOid == $s) | pr_rest]'
PBYNUM=' [.[] | select((.number | tostring) == $n) | pr_rest] | .[0] // empty'
PREST=' [.[] | pr_sel($st; $hd) | pr_rest]'
KEEPALL=' [.[] | pr_keep($f)]'
KEEPONE=' pr_keep($f)'
REPO='{"nameWithOwner":"acme/widget","name":"widget","owner":{"login":"acme"},"defaultBranchRef":{"name":"main"},"url":"https://github.com/acme/widget","isPrivate":false}'
RREPO='{"full_name":"acme/widget","name":"widget","owner":{"login":"acme"},"default_branch":"main","private":false,"html_url":"https://github.com/acme/widget"}'
NF='{"message":"Not Found","status":"404"}'
out() { if [ -n "$q" ]; then jq -r "$q"; else jq -cS .; fi; }
nf()  { printf '%s\n' "$NF"; echo 'gh: Not Found (HTTP 404)' >&2; exit 1; }
no()  { echo 'gh: the stand-in serves reads only' >&2; exit 1; }
qv()  { printf '%s' "&$qs&" | tr '&' '\n' | sed -n "s/^$1=//p" | head -n 1; }
cmd="${1:-}"; [ $# -gt 0 ] && shift
sub=""
case "$cmd" in pr|repo|auth) sub="${1:-}"; [ $# -gt 0 ] && shift ;; esac
j=""; q=""; st=open; hd=""; se=""; me=""; fq=""; pos=""
while [ $# -gt 0 ]; do
  a="$1"; v="${2:-}"; n=2
  case "$a" in --*=*) v="${a#*=}"; a="${a%%=*}"; n=1 ;; esac
  case "$a" in
    --json) j="$v" ;;
    -q|--jq) q="$v" ;;
    -s|--state) st="$v" ;;
    --head) hd="$v" ;;
    -H) [ "$cmd" = api ] || hd="$v" ;;
    -S|--search) se="$v" ;;
    -X|--method) me="$v" ;;
    -f|-F|--field|--raw-field) fq="$fq&$v" ;;
    --input) fq="$fq&input" ;;
    --header|-R|--repo|-L|--limit|-t|--template|-B|--base|-A|--author|-l|--label|-a|--assignee|--hostname|--cache|-p|--preview) : ;;
    -*) n=1 ;;
    *) n=1; [ -n "$pos" ] || pos="$a" ;;
  esac
  if [ "$n" -eq 2 ] && [ $# -ge 2 ]; then shift 2; else shift; fi
done
for w in $se; do
  case "$w" in
    head:*) hd="${w#head:}" ;;
    is:open|state:open) st=open ;;
    is:closed|state:closed) st=closed ;;
    is:merged) st=merged ;;
  esac
done
case "$cmd:$sub" in
  --version:*|version:*) echo 'gh version 2.99.0 (stand-in)' ;;
  auth:status) echo 'github.com: logged in as fixture (stand-in)' >&2 ;;
  pr:list)
    if [ -z "$j" ]; then jq -r --arg st "$st" --arg hd "$hd" "$SEL$PTSV" "$D/prs.json"
    else jq -c --arg st "$st" --arg hd "$hd" --arg f "$j" "$KEEP$SEL$PLIST" "$D/prs.json" | out; fi ;;
  pr:view)
    r=$(jq -c --arg p "$pos" --arg f "$j" "$KEEP$FIND$PVIEW" "$D/prs.json")
    [ -n "$r" ] || { echo "no pull requests found for branch \"$pos\"" >&2; exit 1; }
    printf '%s\n' "$r" | out ;;
  pr:checks)
    s=$(jq -r --arg p "$pos" "$FIND$PSHA" "$D/prs.json")
    [ -n "$s" ] || { echo "no pull requests found for branch \"$pos\"" >&2; exit 1; }
    c=$(jq -c --arg s "$s" "$CHECKS$PCHK" "$D/statuses.json")
    [ "$c" != "[]" ] || { echo "no checks reported on the '$pos' branch" >&2; exit 1; }
    if [ -n "$j" ]; then printf '%s\n' "$c" | jq -c --arg f "$j" "$KEEP$KEEPALL" | out
    else printf '%s\n' "$c" | jq -r '.[] | [.name, .bucket, "0", .link, .description] | @tsv'; fi ;;
  repo:view) printf '%s\n' "$REPO" | jq -c --arg f "$j" "$KEEP$KEEPONE" | out ;;
  api:*)
    case "$me" in ""|GET|get) ;; *) no ;; esac
    [ -z "$fq" ] || [ -n "$me" ] || no
    p="${pos#/}"; qs=""
    case "$p" in *\?*) qs="${p#*\?}"; p="${p%%\?*}" ;; esac
    qs="$qs$fq"
    case "$p" in
      graphql) echo 'gh: the stand-in serves no graphql' >&2; exit 1 ;;
      */commits/*/status) s="${p%/status}"; s="${s##*/}"; jq -c --arg s "$s" "$COMB" "$D/statuses.json" | out ;;
      */commits/*/statuses) s="${p%/statuses}"; s="${s##*/}"; jq -c --arg s "$s" '.[$s] // []' "$D/statuses.json" | out ;;
      */statuses/*) s="${p##*/}"; jq -c --arg s "$s" '.[$s] // []' "$D/statuses.json" | out ;;
      */commits/*/check-runs) printf '%s\n' '{"total_count":0,"check_runs":[]}' | out ;;
      */commits/*/pulls) s="${p%/pulls}"; s="${s##*/}"; jq -c --arg s "$s" "$REST$PBYSHA" "$D/prs.json" | out ;;
      */pulls/*) n="${p##*/}"; case "$n" in ''|*[!0-9]*) nf ;; esac
                 r=$(jq -c --arg n "$n" "$REST$PBYNUM" "$D/prs.json"); [ -n "$r" ] || nf
                 printf '%s\n' "$r" | out ;;
      */pulls) s2=$(qv state); h2=$(qv head); h2="${h2#*:}"
               jq -c --arg st "${s2:-open}" --arg hd "$h2" "$REST$SEL$PREST" "$D/prs.json" | out ;;
      repos/*/*/*) nf ;;
      repos/*/*) printf '%s\n' "$RREPO" | out ;;
      *) nf ;;
    esac ;;
  *) echo "gh: the stand-in does not answer $cmd $sub" >&2; exit 1 ;;
esac
IVGHEOF
# The git stand-in logs each call, with GIT_OPTIONAL_LOCKS as git itself sets
# it for its children, and runs the real git.
cat > "$IVSTUB/git" <<IVGITEOF
#!/bin/sh
printf '%s\t%s\n' "\${GIT_OPTIONAL_LOCKS:-}" "\$*" >> "$IVGIT_LOG"
exec "$IV_REALGIT" "\$@"
IVGITEOF
chmod +x "$IVSTUB/gh" "$IVSTUB/git"

# ---- the host's session records ------------------------------------------
IV_PA_PROMPT='Alpha task: make the parser treat a blank line as the end of a record, then add a test that feeds it two records split by one blank line and checks both.'
IV_PC_PROMPT='Gamma task: rename the config loader so it says what it loads, update every caller in the tree, and keep the old name as a thin alias for one release.'
IV_PD_PROMPT='Delta task: give the scheduler a dry-run mode that prints the jobs it would start and starts none, with a test that counts zero starts made by it.'
IV_PE_PROMPT='Epsilon task: move the retry budget into the settings file so it can change without a release, and assert the default stays at three attempts.'
IV_PF_PROMPT='Zeta task: make the export write its rows in a stable order so two runs over one input produce the same file, and test that twice in a row.'
_ivchip() {  # ts tool-id task-id title prompt
  local inp res
  printf -v inp '{"title":"%s","tldr":"%s","prompt":"%s"}' "$4" 'Noticed in passing.' "$5"
  _au_tool "$2" mcp__ccd_session__spawn_task "$inp"; _au_a "$1" "msg_$2" '"tool_use"' "$_AU_B"
  printf -v res '[{"tool_use_id":"%s","type":"tool_result","content":[{"type":"text","text":"Noted (position 1, task_id: %s). A chip is showing for the user."}]}]' "$2" "$3"
  _au_u "$1" "$res"
}
# wt-query: an older session ended on a statement, the newest on a question.
_ivopen "$IVW/wt-query" a1a1a1a1-0000-4000-8000-000000000001
_au_say  "$(_ivago 302 iso)" 'tidy the notes'
_au_stop "$(_ivago 300 iso)" msg_q0 'Tidied the notes.'
_ivtouch "$_AU_F" 300
_ivopen "$IVW/wt-query" a1a1a1a1-0000-4000-8000-000000000002
_au_say  "$(_ivago 182 iso)" 'prepare the push'
_au_stop "$(_ivago 180 iso)" msg_q1 'The branch is ready. Shall I push it?'
_ivtouch "$_AU_F" 180
# wt-bold: a question in bold, then only a system envelope.
_ivopen "$IVW/wt-bold" b2b2b2b2-0000-4000-8000-000000000001
_au_say  "$(_ivago 184 iso)" 'compare the two layouts'
_au_tool toolu_bold1 Bash '{"command":"ls","description":"List them"}'
_au_a    "$(_ivago 183 iso)" msg_b1 '"tool_use"' "$_AU_B"
_au_res  "$(_ivago 182 iso)" toolu_bold1 ok
_au_stop "$(_ivago 181 iso)" msg_b2 'Two layouts remain. **Which one do you want?**'
_au_say  "$(_ivago 180 iso)" '<system-reminder>A background task finished.</system-reminder>'
_ivtouch "$_AU_F" 180
# wt-answered: an older session ended on a question; the newest asked one and
# was answered. A fresh subagent transcript ending on a question is added
# just before the runs, under the newest session's subagents/ directory.
_ivopen "$IVW/wt-answered" c3c3c3c3-0000-4000-8000-000000000001
_au_say  "$(_ivago 302 iso)" 'clean up'
_au_stop "$(_ivago 300 iso)" msg_n0 'Shall I delete the scratch branch?'
_ivtouch "$_AU_F" 300
IV_NID=c3c3c3c3-0000-4000-8000-000000000002
_ivopen "$IVW/wt-answered" "$IV_NID"
_au_say  "$(_ivago 183 iso)" 'get it ready'
_au_stop "$(_ivago 182 iso)" msg_n1 'It is ready. Should I push?'
_au_say  "$(_ivago 180 iso)" 'yes, push it'
_ivtouch "$_AU_F" 180
# wt-blocked: the last record is a tool call with no result, two hours old.
_ivopen "$IVW/wt-blocked" d4d4d4d4-0000-4000-8000-000000000001
_au_say  "$(_ivago 125 iso)" 'run the daily watch'
_au_tool toolu_k1 Bash '{"command":"date","description":"Read the clock"}'
_au_a    "$(_ivago 124 iso)" msg_k1 '"tool_use"' "$_AU_B"
_au_res  "$(_ivago 123 iso)" toolu_k1 ok
_au_tool toolu_k2 Bash '{"command":"watch-the-ledger","description":"Watch the ledger"}'
_au_a    "$(_ivago 120 iso)" msg_k2 '"tool_use"' "$_AU_B"
_ivtouch "$_AU_F" 120
# wt-unread: the newest session cannot be read at all. Spec §5.2 and §6.6
# (R4, ruled 2026-10-02): an unreadable session file anywhere under the records
# root leaves every chip proposed before its mtime unknown:chip-unstarted. Its
# mtime, 14500 minutes ago, is older than every proposal read inside the
# 14-day window (wt-squash's at 2882-2884 minutes, Zeta's, Theta's, and
# doohickey's Kappa at 14401), so the chips below stay decided, and the file,
# inside that window, is still compared.
_ivopen "$IVW/wt-unread" e5e5e5e5-0000-4000-8000-000000000001
_au_say  "$(_ivago 14502 iso)" 'look around'
_au_stop "$(_ivago 14500 iso)" msg_u1 'Shall I go on?'
_ivtouch "$_AU_F" 14500
IV_UNREAD="$_AU_F"; chmod 000 "$IV_UNREAD"
# wt-squash: five chips. Epsilon's session is twenty days old, past the
# default window of 14 (decision D4 of 2026-09-24; it was ten days old
# against the old default of 7). Alpha, Gamma and
# Delta come two days ago; Gamma is dismissed there; Alpha is started a day
# later by a session whose first human message repeats its prompt's first 120
# characters; Delta's prompt opens a session from before it was suggested,
# which starts nothing. Zeta is suggested in a directory of no worktree here.
_ivopen "$IVW/wt-squash" f6f6f6f6-0000-4000-8000-000000000001
_au_say  "$(_ivago 28802 iso)" 'note what is left'
_ivchip  "$(_ivago 28801 iso)" toolu_ce task_e5e5e5e5 'Epsilon chip too old' "$IV_PE_PROMPT"
_au_stop "$(_ivago 28800 iso)" msg_e9 'Noted.'
_ivtouch "$_AU_F" 28800
_ivopen "$IVW/wt-squash" f6f6f6f6-0000-4000-8000-000000000002
_au_say  "$(_ivago 2885 iso)" 'file the follow-ups'
_ivchip  "$(_ivago 2884 iso)" toolu_ca task_a1a1a1a1 'Alpha chip started later' "$IV_PA_PROMPT"
_ivchip  "$(_ivago 2883 iso)" toolu_cc task_c3c3c3c3 'Gamma chip dismissed' "$IV_PC_PROMPT"
_ivchip  "$(_ivago 2882 iso)" toolu_cd task_d4d4d4d4 'Delta chip never started' "$IV_PD_PROMPT"
_au_tool toolu_cx mcp__ccd_session__dismiss_task '{"task_id":"task_c3c3c3c3","reason":"fixed in this session"}'
_au_a    "$(_ivago 2881 iso)" msg_cx '"tool_use"' "$_AU_B"
_au_res  "$(_ivago 2881 iso)" toolu_cx ok
_au_stop "$(_ivago 2880 iso)" msg_cz 'Filed the follow-ups.'
_ivtouch "$_AU_F" 2880
_au_open "$IVP/-elsewhere-started/a7a7a7a7-0000-4000-8000-000000000001.jsonl" a7a7a7a7-0000-4000-8000-000000000001
_au_raw  '{"type":"queue-operation","operation":"enqueue","sessionId":"a7a7a7a7-0000-4000-8000-000000000001"}'
_au_say  "$(_ivago 1442 iso)" "${IV_PA_PROMPT:0:120} - and say so in the changelog."
_au_stop "$(_ivago 1440 iso)" msg_sa 'Done, and noted.'
_ivtouch "$_AU_F" 1440
_au_open "$IVP/-elsewhere-early/a8a8a8a8-0000-4000-8000-000000000001.jsonl" a8a8a8a8-0000-4000-8000-000000000001
_au_say  "$(_ivago 4322 iso)" "$IV_PD_PROMPT"
_au_stop "$(_ivago 4320 iso)" msg_se 'Done.'
_ivtouch "$_AU_F" 4320
_au_open "$IVP/-elsewhere-other/a9a9a9a9-0000-4000-8000-000000000001.jsonl" a9a9a9a9-0000-4000-8000-000000000001
_au_say  "$(_ivago 2885 iso)" 'look around'
_ivchip  "$(_ivago 2884 iso)" toolu_cf task_f6f6f6f6 'Zeta chip elsewhere' "$IV_PF_PROMPT"
_au_stop "$(_ivago 2880 iso)" msg_so 'Noted.'
_ivtouch "$_AU_F" 2880

# ---- the fixture holds what the assertions below say it holds ------------
IV_FX="$IV/fx"
_ivfx=""
[ "$(_ivq -C "$IVW/wt-revert" rev-parse HEAD)" = "$IV_R2" ] || _ivfx="$_ivfx HEAD is not the adopted commit;"
_ivq -C "$IVW/wt-revert" diff-index --cached --quiet "$IV_R1" || _ivfx="$_ivfx the index is not the first tip;"
_ivq -C "$IVW/wt-revert" diff-index --cached --quiet "$IV_R2" && _ivfx="$_ivfx the index equals HEAD;"
_ivq -C "$IVM" reflog show --format=%H topic/revert > "$IV_FX" 2>&1
grep -qx "$IV_R1" "$IV_FX" || _ivfx="$_ivfx the branch reflog lacks the first tip;"
[ -z "$_ivfx" ] && ok  "the fixture: wt-revert's HEAD moved on while its index holds the branch's earlier tip, which the reflog records" \
                || bad "the fixture: wt-revert's HEAD moved on while its index holds the branch's earlier tip, which the reflog records" "$_ivfx"
_ivfx=""
_ivq -C "$IVM" worktree list --porcelain > "$IV_FX"
[ "$(grep -c '^branch refs/heads/topic/shared$' "$IV_FX")" = 2 ] || _ivfx="$_ivfx topic/shared is not in two worktrees;"
grep -q 'orphan-' "$IV_FX" && _ivfx="$_ivfx git still lists an orphan;"
{ [ -f "$IVW/orphan-edit/.git" ] && [ -f "$IVW/orphan-clean/README.md" ]; } || _ivfx="$_ivfx an orphan lost its files;"
[ "$(_ivq -C "$IVM" symbolic-ref refs/remotes/origin/HEAD)" = refs/remotes/origin/main ] || _ivfx="$_ivfx origin/HEAD is not origin/main;"
[ "$(_ivq -C "$IVM" remote get-url origin)" = https://github.com/acme/widget.git ] || _ivfx="$_ivfx origin does not name GitHub;"
[ -z "$_ivfx" ] && ok  "the fixture: one branch sits in two worktrees, git lists neither orphan, and origin names GitHub with origin/HEAD at main" \
                || bad "the fixture: one branch sits in two worktrees, git lists neither orphan, and origin names GitHub with origin/HEAD at main" "$_ivfx"
_ivfx=""
_ivq -C "$IVM" merge-base --is-ancestor "$IV_S1" origin/main && _ivfx="$_ivfx the squash is an ancestor;"
[ "$(_ivq -C "$IVM" rev-parse "$IV_S1:src/squash.txt")" = "$(_ivq -C "$IVM" rev-parse origin/main:src/squash.txt)" ] || _ivfx="$_ivfx main lacks the squash content;"
_ivq -C "$IVM" merge-base --is-ancestor "$IV_P1" "$IV_P2" || _ivfx="$_ivfx P1 does not precede P2;"
[ "$(_ivq -C "$IVM" rev-parse "$IV_P1:src/precedes.txt")" = "$(_ivq -C "$IVM" rev-parse origin/main:src/precedes.txt)" ] && _ivfx="$_ivfx main holds P1's content;"
[ "$(_ivq -C "$IVM" rev-parse "$IV_X1:src/superseded.txt")" = "$(_ivq -C "$IVM" rev-parse origin/main:src/superseded.txt)" ] || _ivfx="$_ivfx main lacks superseded.txt;"
_ivq -C "$IVM" cat-file -e origin/main:src/closed.txt 2>/dev/null && _ivfx="$_ivfx main holds closed.txt;"
[ "$(_ivq -C "$IVM" rev-parse origin/topic/pr-hold)" = "$IV_H1" ] || _ivfx="$_ivfx origin/topic/pr-hold is not the head;"
[ "$(_ivq -C "$IVM" rev-parse origin/topic/precedes)" = "$IV_P2" ] || _ivfx="$_ivfx origin/topic/precedes is not P2;"
[ "$(_ivq -C "$IVM" rev-parse origin/topic/revert)" = "$IV_R2" ] || _ivfx="$_ivfx origin/topic/revert is not the adopted commit;"
for _ivn in topic/unpushed topic/partly topic/dup-one topic/dup-two; do
  [ "$(_ivq -C "$IVM" rev-list --count "$_ivn" --not --remotes)" = 1 ] || _ivfx="$_ivfx $_ivn is not one commit on no remote;"
done
_ivq -C "$IVM" rev-parse -q --verify refs/heads/topic/remote-only >/dev/null && _ivfx="$_ivfx topic/remote-only has a local copy;"
[ -z "$_ivfx" ] && ok  "the fixture: squash, precedes, superseded and closed hold main's content as built, and each push and non-push is where it was meant" \
                || bad "the fixture: squash, precedes, superseded and closed hold main's content as built, and each push and non-push is where it was meant" "$_ivfx"
_ivfx=""
for _ivn in src/squash.txt README.md; do
  [ "$(_ivq -C "$IVW/wt-same" hash-object "$_ivn")" = "$(_ivq -C "$IVM" rev-parse "origin/main:$_ivn")" ] || _ivfx="$_ivfx wt-same's $_ivn is not main's;"
done
_ivq -C "$IVM" cat-file -e origin/main:src/old.txt 2>/dev/null && _ivfx="$_ivfx main still has old.txt;"
_ivq -C "$IVW/wt-same" check-ignore -q debug.log || _ivfx="$_ivfx debug.log is not ignored;"
_ivq -C "$IVW/wt-dirty" status --porcelain > "$IV_FX"
[ "$(tr '\n' ';' < "$IV_FX")" = 'M  src/core.txt;?? src/untracked-new.txt;' ] || _ivfx="$_ivfx wt-dirty's status is [$(tr '\n' ';' < "$IV_FX")];"
_ivq -C "$IVW/wt-squash" status --porcelain > "$IV_FX"
[ -s "$IV_FX" ] && _ivfx="$_ivfx wt-squash is not clean;"
[ -z "$_ivfx" ] && ok  "the fixture: wt-same's changes are main's content and an ignored file, and wt-dirty holds a staged edit and an untracked file only" \
                || bad "the fixture: wt-same's changes are main's content and an ignored file, and wt-dirty holds a staged edit and an untracked file only" "$_ivfx"
if [ "$IV_JQ" = 1 ]; then
  _ivfx="$(PATH="$IVSTUB:$PATH" gh pr list --state all --json number,headRefName --jq 'length') $(PATH="$IVSTUB:$PATH" gh api "repos/acme/widget/commits/$IV_Y1/status" --jq .state) $(PATH="$IVSTUB:$PATH" gh pr list --json number --jq 'length') $(PATH="$IVSTUB:$PATH" gh api "repos/acme/widget/commits/$IV_H1/status" --jq .state)"
  is "the fixture: the gh stand-in lists nine pull requests, five open, with felix/ready on one head and not on another" "$_ivfx" "9 success 5 pending"
else
  skip "the fixture: the gh stand-in lists nine pull requests, five open, with felix/ready on one head and not on another" "no jq for the gh stand-in"
fi
PATH="$IVSTUB:$PATH" git --no-optional-locks -C "$IVM" rev-parse HEAD >/dev/null
has "the fixture: the git stand-in logs its calls and runs the real git" "$(cat "$IVGIT_LOG")" "--no-optional-locks -C $IVM rev-parse HEAD"
: > "$IVGH_LOG"; : > "$IVGIT_LOG"

