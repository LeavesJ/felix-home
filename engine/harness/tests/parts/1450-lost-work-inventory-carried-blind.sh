# >>> lost-work-inventory-carried
printf '\nthe lost-work page, step 6: the shared fixture, and felix inventory carried (contract A1, B9.1-12, blind)\n'
# Blind, written from docs/2026-10-18-lost-work-page-contract.md alone on
# 2026-10-17, before lib/lost-work.sh and the A1-A3 inventory changes existed.
# No engine code was read for an expected value: engine/harness/felix was read
# only for how inventory, land and monitor are dispatched. Parts 1460, 1470
# and 1480 use the stubs, builders, runner and readers this part defines; each
# builds its own repositories under $LW and none reads another's fixture.
#
# The shared fixture. Every repository is a clone of a bare origin at
# $LW/github.com/fixture/NAME.git, so its slug is fixture/NAME. gh, launchctl,
# open and xdg-open are stubs first on PATH, each logging its argv under
# $LW/log. gh answers pr list from ctl/prs.<owner>_<name>.<state>.json (the
# repository from -R, else from the origin of the directory it runs in; state
# open unless --state says all, closed or merged), fails as ctl/prs.<key>.rc
# says, and answers the api GETs step 5 makes (the Actions billing, a user, a
# repository's default branch) from fixed bodies. launchctl print fails (the
# lander job is not loaded). open is stubbed so that no run of the page before
# it exists, where `monitor --open` still opens, can open a window. Every felix
# run has a fixture HOME (its .claude/projects is the records root), TMPDIR
# $LW/tmp, an empty FELIX_INVENTORY_TEMP_ROOTS (the suite's $TMP is under the
# real temporary roots), FELIX_MEMORY $LW/mem and FELIX_HOME $LW_FH.
LW="$TMP/lost-work"; mkdir -p "$LW"; LW="$(cd "$LW" && pwd -P)"
LWB="$LW/bin"; LWK="$LW/ctl"; LWL="$LW/log"; LWX="$LW/out"; LWT="$LW/tmp"; LWM="$LW/mem"
mkdir -p "$LWB" "$LWK" "$LWL" "$LWX" "$LWT" "$LWM" "$LW/fxhome/.config" "$LW/cache" "$LW/temproot" \
         "$LW/norepo" "$LW/cwd" "$LW/nohome/projects" "$LW/hA/.claude/projects"
LW_FH="$LW/nohome"
_lw_put() { mkdir -p "${1%/*}" && LC_ALL=C sed "s#@LW@#$LW#g" > "$1" && chmod +x "$1"; }
_lw_put "$LWB/gh" <<'LWSTUB'
#!/bin/bash
LW='@LW@'; K="$LW/ctl"
printf '%s\n' "$*" >> "$LW/log/gh.log"
jqx=""; repo=""; prev=""; st=open; bill=0; user=0; dflt=""; deep=0
for a in "$@"; do
  case "$prev" in -q|--jq) jqx="$a" ;; -R|--repo) repo="$a" ;; -s|--state) st="$a" ;; esac
  case "$a" in --jq=*) jqx="${a#--jq=}" ;; --repo=*) repo="${a#--repo=}" ;; --state=*) st="${a#--state=}" ;; esac
  case "$a" in *settings/billing/actions*) bill=1 ;; users/*|/users/*) user=1 ;; esac
  case "${a#/}" in repos/fixture/*/*) deep=1 ;; repos/fixture/*) dflt="${a#/}" ;; esac
  prev="$a"
done
if [ -z "$repo" ]; then
  u="$(git config --get remote.origin.url 2>/dev/null)"; u="${u%/}"; u="${u%.git}"
  n="${u##*/}"; o="${u%/*}"; o="${o##*/}"; [ -n "$n" ] && [ -n "$o" ] && repo="$o/$n"
fi
repo="${repo#https://}"; repo="${repo#github.com/}"; repo="${repo%.git}"
key="$(printf '%s' "$repo" | LC_ALL=C tr '/' '_')"
out() { if [ -n "$jqx" ] && command -v jq >/dev/null 2>&1; then jq -r "$jqx"; else cat; fi; }
case "${1:-} ${2:-}" in
  "pr list")
    if [ -f "$K/prs.$key.rc" ]; then cat "$K/prs.$key.err" >&2; exit "$(cat "$K/prs.$key.rc")"; fi
    case "$st" in open|all|closed|merged) ;; *) st=all ;; esac
    [ -f "$K/prs.$key.$st.json" ] || { printf 'stub: no answer for repository [%s]\n' "$repo" >&2; exit 4; }
    out < "$K/prs.$key.$st.json"; exit 0 ;;
  "auth status") exit 0 ;;
esac
case "${1:-}" in --version|version) echo 'gh version 2.99.0 (stub)'; exit 0 ;; esac
if [ "${1:-}" = api ]; then
  if [ "$bill" = 1 ]; then printf '{"total_minutes_used":123,"total_paid_minutes_used":0,"included_minutes":2000,"minutes_used_breakdown":{"UBUNTU":123}}\n' | out; exit 0; fi
  if [ "$user" = 1 ]; then printf '{"login":"fixture","id":1,"type":"User"}\n' | out; exit 0; fi
  if [ -n "$dflt" ] && [ "$deep" = 0 ]; then printf '{"full_name":"%s","default_branch":"main"}\n' "${dflt#repos/}" | out; exit 0; fi
  printf 'gh: Not Found (HTTP 404)\n' >&2; exit 1
fi
printf 'stub: gh %s is not served\n' "$*" >&2
exit 1
LWSTUB
_lw_put "$LWB/launchctl" <<'LWSTUB'
#!/bin/bash
printf '%s\n' "$*" >> '@LW@/log/launchctl.log'
case "${1:-}" in print) exit 113 ;; esac
exit 0
LWSTUB
_lw_put "$LWB/open" <<'LWSTUB'
#!/bin/bash
printf '%s\n' "$*" >> '@LW@/log/open.log'
exit 0
LWSTUB
cp "$LWB/open" "$LWB/xdg-open"

# ---- the fixture's git ------------------------------------------------------
# Every git command goes through _fx_git, with a fixture HOME and author.
_lwg() { local d="$1"; shift
         HOME="$LW/fxhome" XDG_CONFIG_HOME="$LW/fxhome/.config" GIT_CONFIG_NOSYSTEM=1 \
         GIT_AUTHOR_NAME=Fixture GIT_AUTHOR_EMAIL=fixture@example.invalid \
         GIT_COMMITTER_NAME=Fixture GIT_COMMITTER_EMAIL=fixture@example.invalid \
         _fx_git "$d" -c init.defaultBranch=main -c advice.detachedHead=false "$@"; }
_lwq() { _lwg "$1" rev-parse -q --verify "$2" 2>/dev/null; }
_lw_repo() {  # NAME: $LW/github.com/fixture/NAME.git and $LW/NAME cloned from it, main pushed with one commit
  local n="$1" o="$LW/github.com/fixture/$1.git"
  mkdir -p "$o"
  _lwg "$o" init -q --bare >/dev/null 2>&1; _lwg "$o" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
  _lwg "$LW" clone -q "$o" "$n" >/dev/null 2>&1
  _lwg "$LW/$n" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
  printf '%s\n' "$n" > "$LW/$n/README.md"
  _lwg "$LW/$n" add -A >/dev/null 2>&1; _lwg "$LW/$n" commit -qm "the first $n" >/dev/null 2>&1
  _lwg "$LW/$n" push -q -u origin main >/dev/null 2>&1
  _lwg "$LW/$n" remote set-head origin main >/dev/null 2>&1
}
_lw_mainwt() { _lwg "$1" worktree list --porcelain 2>/dev/null | LC_ALL=C awk 'NR == 1 { sub(/^worktree /, ""); print }'; }
# A commit no checkout holds: the parent's top-level tree with NAME set to
# CONTENT for each pair, made with mktree and commit-tree. -> LWC
LWC=""
_lw_mk() {  # REPO PARENT MESSAGE NAME CONTENT [NAME CONTENT]...
  local r="$1" p="$2" m="$3" b t; shift 3
  _lwg "$r" ls-tree "$p" > "$LW/mk.tree" 2>/dev/null
  while [ $# -ge 2 ]; do
    b="$(printf '%s\n' "$2" | _lwg "$r" hash-object -w --stdin)"
    LC_ALL=C awk -F'\t' -v n="$1" '$2 != n' "$LW/mk.tree" > "$LW/mk.tmp"; mv "$LW/mk.tmp" "$LW/mk.tree"
    printf '100644 blob %s\t%s\n' "$b" "$1" >> "$LW/mk.tree"
    shift 2
  done
  t="$(_lwg "$r" mktree < "$LW/mk.tree")"
  LWC="$(_lwg "$r" commit-tree "$t" -p "$p" -m "$m")"
}
_lw_anc() { if _lwg "$1" merge-base --is-ancestor "$2" "$3" >/dev/null 2>&1; then printf y; else printf n; fi; }

# ---- pull requests as gh lists them -------------------------------------------
_lw_ago() { local t; t=$(( $(date +%s) - $1 )); date -u -r "$t" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$t" +%Y-%m-%dT%H:%M:%SZ; }
LW_UPD="$(_lw_ago 181800)"; LW_CRE="$(_lw_ago 216000)"   # 50.5 and 60 hours ago
_lw_cr() { printf '{"__typename":"CheckRun","name":"%s","workflowName":"%s","status":"%s","conclusion":"%s","startedAt":"%s","completedAt":"%s","detailsUrl":"https://example.invalid/%s"}' \
             "$1" "$1" "$2" "$3" "$LW_UPD" "$LW_UPD" "$1"; }
_lw_roll() {
  case "$1" in
    green)   printf '[%s]' "$(_lw_cr gate COMPLETED SUCCESS)" ;;
    red)     printf '[%s,%s]' "$(_lw_cr gate COMPLETED SUCCESS)" "$(_lw_cr lint COMPLETED FAILURE)" ;;
    running) printf '[%s,%s]' "$(_lw_cr gate COMPLETED SUCCESS)" "$(_lw_cr lint IN_PROGRESS '')" ;;
    *)       printf '[]' ;;
  esac
}
_lw_files() {  # "path ..." or @100 for exactly one hundred files
  local s="" f i=1
  if [ "$1" = @100 ]; then
    while [ "$i" -le 100 ]; do printf '%s{"path":"notes/many/f%03d.md","additions":1,"deletions":0}' "$s" "$i"; s=","; i=$((i+1)); done
    return 0
  fi
  for f in $1; do printf '%s{"path":"%s","additions":1,"deletions":0}' "$s" "$f"; s=","; done
}
_lw_labels() { ( IFS=,; s=""; for l in $1; do printf '%s{"id":"LA_%s","name":"%s","description":"","color":"ededed"}' "$s" "$l" "$l"; s=","; done ); }
_lw_pr() {  # N HEAD-BRANCH HEAD-OID ROLL FILES [state=OPEN|CLOSED|MERGED] [labels=a,b] [repo=fixture/x]
  local n="$1" br="$2" oid="$3" ro="$4" fs="$5" kv st=OPEN lb="" rp=fixture/x me=null cl=null; shift 5
  for kv in "$@"; do case "$kv" in state=*) st="${kv#state=}" ;; labels=*) lb="${kv#labels=}" ;; repo=*) rp="${kv#repo=}" ;; esac; done
  [ "$st" = OPEN ] || cl="\"$LW_UPD\""
  [ "$st" = MERGED ] && me="\"$LW_UPD\""
  printf '{"number":%s,"title":"Change %s","state":"%s","isDraft":false,"isCrossRepository":false,"headRefName":"%s","headRefOid":"%s","baseRefName":"main",' "$n" "$n" "$st" "$br" "$oid"
  printf '"headRepositoryOwner":{"login":"fixture"},"headRepository":{"name":"%s"},"author":{"id":"U_fixture","is_bot":false,"login":"fixture","name":""},"labels":[%s],' "${rp#*/}" "$(_lw_labels "$lb")"
  printf '"mergeable":"MERGEABLE","mergeStateStatus":"CLEAN","statusCheckRollup":%s,"files":[%s],"createdAt":"%s","updatedAt":"%s","mergedAt":%s,"closedAt":%s,"reviewDecision":"","url":"https://github.com/%s/pull/%s"}' \
    "$(_lw_roll "$ro")" "$(_lw_files "$fs")" "$LW_CRE" "$LW_UPD" "$me" "$cl" "$rp" "$n"
}
_lw_prs() {  # KEY OBJECT...: ctl/prs.KEY.{all,open,closed,merged}.json
  local k="$1" o a="" op="" cl="" mg="" s1="" s2="" s3="" s4=""; shift
  for o in "$@"; do
    a="$a$s1$o"; s1=","
    case "$o" in
      *'"state":"OPEN"'*) op="$op$s2$o"; s2="," ;;
      *'"state":"MERGED"'*) cl="$cl$s3$o"; s3=","; mg="$mg$s4$o"; s4="," ;;
      *) cl="$cl$s3$o"; s3="," ;;
    esac
  done
  printf '[%s]\n' "$a" > "$LWK/prs.$k.all.json"; printf '[%s]\n' "$op" > "$LWK/prs.$k.open.json"
  printf '[%s]\n' "$cl" > "$LWK/prs.$k.closed.json"; printf '[%s]\n' "$mg" > "$LWK/prs.$k.merged.json"
  rm -f "$LWK/prs.$k.rc" "$LWK/prs.$k.err"
}
_lw_ghfail() { printf '1\n' > "$LWK/prs.$1.rc"; printf '%s\n' "$2" > "$LWK/prs.$1.err"; }

# ---- host records -------------------------------------------------------------
# Session files where Claude Code files them: LW_RR is the records root (a
# fixture HOME's .claude/projects), and a working directory's sessions sit in
# a directory named by it with every character outside [A-Za-z0-9-] made -.
# Every user and assistant record carries a timestamp MIN minutes ago; _lw_age
# sets the file's mtime to its last record's age. A user record puts
# "type":"user" before its message, an assistant record its message first.
LW_F=""; LW_SID=""; LW_RR=""
_lw_enc() { printf '%s' "$1" | LC_ALL=C sed 's/[^A-Za-z0-9-]/-/g'; }
_lw_open() { LW_F="$1"; LW_SID="$2"; mkdir -p "${1%/*}"; : > "$1"; }
_lw_sess() { _lw_open "$LW_RR/$(_lw_enc "$1")/$2.jsonl" "$2"; }
_lw_ts() { local e; e=$(( $(date +%s) - $1 * 60 )); date -u -r "$e" '+%Y-%m-%dT%H:%M:%S.000Z' 2>/dev/null || date -u -d "@$e" '+%Y-%m-%dT%H:%M:%S.000Z'; }
_lw_age() { local e; e=$(( $(date +%s) - $2 * 60 )); touch -t "$(date -r "$e" '+%Y%m%d%H%M.%S' 2>/dev/null || date -d "@$e" '+%Y%m%d%H%M.%S')" "$1"; }
_lw_raw() { printf '%s\n' "$1" >> "$LW_F"; }
_lw_u() {  # MIN CONTENT-JSON
  local l; printf -v l '{"parentUuid":"p","isSidechain":false,"userType":"external","sessionId":"%s","version":"2.1.286","type":"user","message":{"role":"user","content":%s},"uuid":"u-%s","timestamp":"%s"}' \
    "$LW_SID" "$2" "$RANDOM" "$(_lw_ts "$1")"
  printf '%s\n' "$l" >> "$LW_F"; }
_lw_ax() {  # MIN ITEMS-JSON STOP-REASON
  local l; printf -v l '{"parentUuid":"p","isSidechain":false,"userType":"external","sessionId":"%s","version":"2.1.286","message":{"model":"claude-test","id":"msg_%s","type":"message","role":"assistant","content":[%s],"stop_reason":"%s","stop_sequence":null,"usage":{"input_tokens":1,"output_tokens":1}},"requestId":"req_%s","type":"assistant","uuid":"a-%s","timestamp":"%s"}' \
    "$LW_SID" "$RANDOM" "$2" "$3" "$RANDOM" "$RANDOM" "$(_lw_ts "$1")"
  printf '%s\n' "$l" >> "$LW_F"; }
_lw_h()  { _lw_u "$1" "\"$2\""; }
_lw_a()  { local b; printf -v b '{"type":"text","text":"%s"}' "$2"; _lw_ax "$1" "$b" end_turn; }
_lw_tu() { local b; printf -v b '{"type":"tool_use","id":"%s","name":"%s","input":%s}' "$2" "$3" "$4"; _lw_ax "$1" "$b" tool_use; }
_lw_tr() { local b; printf -v b '[{"tool_use_id":"%s","type":"tool_result","content":[{"type":"text","text":"%s"}]}]' "$2" "$3"; _lw_u "$1" "$b"; }
_lw_spawn() {  # MIN TOOL-ID TASK-ID TITLE PROMPT: a spawn_task proposal and the result naming its task
  local i; printf -v i '{"title":"%s","prompt":"%s","tldr":"Noticed in passing."}' "$4" "$5"
  _lw_tu "$1" "$2" mcp__ccd_session__spawn_task "$i"
  _lw_tr "$1" "$2" "Noted (position 1, task_id: $3). A chip is showing for the user."; }
_lw_title() { local l; printf -v l '{"type":"custom-title","customTitle":"%s","sessionId":"%s"}' "$1" "$LW_SID"; _lw_raw "$l"; }
# A3 cause 1: a first user record of two text items, the worktree reminder
# ending in a blank line, then the human text. The \n are JSON escapes.
LW_REM='<system-reminder>\nYou are operating in a git worktree.\nEdit files only under it.\n</system-reminder>\n\n'
_lw_h2() { local c; printf -v c '[{"type":"text","text":"%s"},{"type":"text","text":"%s"}]' "$LW_REM" "$2"; _lw_u "$1" "$c"; }
# A prompt of N characters cut from a repeated seed.
_lw_p() { local s="$1 $1 $1 $1 $1"; printf '%s' "${s:0:$2}"; }

# ---- running felix, and reading its rows -----------------------------------------
# _lw_run NAME HOME CWD ARGS...: $FELIX ARGS in CWD, stdout and stderr in
# $LWX/NAME.out and .err, the status in .rc.
_lw_run() {
  local n="$1" h="$2" d="$3"; shift 3
  ( cd "$d" || exit 97
    exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CONFIG_DIR \
      -u CLAUDE_PLUGIN_ROOT -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u GIT_COMMON_DIR -u GIT_OBJECT_DIRECTORY -u GIT_OPTIONAL_LOCKS \
      HOME="$h" FELIX_HOME="$LW_FH" FELIX_HOME_DIR="$LW_FH" FELIX_MEMORY="$LWM" FELIX_PLUGIN_CACHE="$LW/cache" \
      FELIX_INVENTORY_TEMP_ROOTS="$LW/temproot" XDG_CONFIG_HOME="$h/.config" XDG_STATE_HOME="$h/.state" XDG_CACHE_HOME="$h/.cache" \
      GH_CONFIG_DIR="$h/.config/gh" GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 GIT_CEILING_DIRECTORIES="$LW" \
      TMPDIR="$LWT" PATH="$LWB:$PATH" "$FELIX" "$@" ) > "$LWX/$n.out" 2> "$LWX/$n.err"
  printf '%s\n' "$?" > "$LWX/$n.rc"
}
_lw_o()  { printf '%s' "$LWX/$1.out"; }
_lw_rc() { cat "$LWX/$1.rc" 2>/dev/null; }
# OFF is 0 for a source's own --tsv (kind in column 1) and 1 for the page's
# (its group first); a column N is numbered as the source numbers it. LW_REPO,
# when set, keeps only rows whose repo cell is it.
LW_REPO=""
_lw_row() { LC_ALL=C awk -F'\t' -v k="$2" -v r="$3" -v o="${4:-0}" -v p="$LW_REPO" \
              '$(1+o) == k && $(3+o) == r && (p == "" || $(2+o) == p) { print; exit }' "$1" 2>/dev/null; }
_lw_col() {  # FILE KIND REF N [OFF] -> that cell, or "no row"
  local l; l="$(_lw_row "$1" "$2" "$3" "${5:-0}")"
  if [ -z "$l" ]; then printf 'no row'; else printf '%s\n' "$l" | LC_ALL=C awk -F'\t' -v n="$4" -v o="${5:-0}" '{ printf "%s", $(n+o) }'; fi; }
_lw_st() { _lw_col "$1" "$2" "$3" 4 "${4:-0}"; }
_lw_holds() {  # FILE KIND REF STATE [OFF] -> yes, no or "no row"
  local s; s="$(_lw_st "$1" "$2" "$3" "${5:-0}")"
  if [ "$s" = "no row" ]; then printf 'no row'; else case ",$s," in *",$4,"*) printf yes ;; *) printf no ;; esac; fi; }
_lw_many() {  # FILE KIND REF OFF STATE... -> "S1=yes S2=no ..."
  local f="$1" k="$2" r="$3" o="$4" s out=""; shift 4
  for s in "$@"; do out="$out${out:+ }$s=$(_lw_holds "$f" "$k" "$r" "$s" "$o")"; done; printf '%s' "$out"; }
_lw_elem() {  # FILE KIND REF ELEMENT [OFF] -> yes, no or "no row": the detail holds ELEMENT whole (elements joined by "; ")
  local d; d="$(_lw_col "$1" "$2" "$3" 8 "${5:-0}")"
  [ "$d" != "no row" ] || { printf 'no row'; return; }
  printf '%s\n' "$d" | LC_ALL=C awk -v w="$4" '{ n = split($0, e, "; "); for (i = 1; i <= n; i++) if (e[i] == w) f = 1 } END { printf "%s", (f ? "yes" : "no") }'; }
_lw_kind() { local k; k="$(LC_ALL=C awk -F'\t' -v r="$2" -v o="${3:-0}" '$(3+o) == r { print $(1+o); exit }' "$1" 2>/dev/null)"; printf '%s' "${k:-none}"; }
LW_ORDER='hazard:shared-branch hazard:staged-revert live question blocked uncommitted unpushed unproposed pr-open pr-closed-unlanded carried orphan chip-unstarted handoff-pending'
# FILE [OFF] -> "B|C": B rows whose states break the order above, C rows holding carried.
_lw_order() { LC_ALL=C awk -F'\t' -v o="${2:-0}" -v ord="$LW_ORDER" '
    BEGIN { n = split(ord, t, " "); for (i = 1; i <= n; i++) r[t[i]] = i }
    { k = split($(4+o), s, ","); last = 0; bad = 0
      for (i = 1; i <= k; i++) if (s[i] in r) { if (r[s[i]] < last) bad = 1; last = r[s[i]] }
      b += bad; if (index("," $(4+o) ",", ",carried,")) c++ }
    END { printf "%d|%d", b + 0, c + 0 }' "$1" 2>/dev/null; }

# ---- A1: the carried fixture ----------------------------------------------------
# ca: main is two commits; done5 sits at the first. Each case below is commits
# no checkout holds, pushed to the names given; "X child of Y" means X's parent
# is Y. No PR anywhere except #7 (open, head carry2), #60 (open, head pr6),
# #90 (closed unmerged, head b9), #100 (open, head b10), #101 (open, head c10).
_lw_repo ca; CA="$LW/ca"
LWCA0="$(_lwq "$CA" refs/heads/main)"
printf 'second\n' > "$CA/second.txt"; _lwg "$CA" add -A >/dev/null 2>&1; _lwg "$CA" commit -qm 'the second ca' >/dev/null 2>&1
_lwg "$CA" push -q origin main >/dev/null 2>&1
LWCAM="$(_lwq "$CA" refs/heads/main)"
_lw_mk "$CA" "$LWCAM" one c1.txt one;            LW1X="$LWC"; _lw_mk "$CA" "$LW1X" 'carries one' c1b.txt 'one b'; LW1Y="$LWC"
_lw_mk "$CA" "$LWCAM" two c2.txt two;            LW2X="$LWC"; _lw_mk "$CA" "$LW2X" 'carries two' c2b.txt 'two b'; LW2Y="$LWC"
_lw_mk "$CA" "$LWCAM" three c3.txt three;        LW3X="$LWC"
_lw_mk "$CA" "$LWCAM" 'twin tip' c3t.txt twin;   LW3Z="$LWC"
_lw_mk "$CA" "$LWCAM" four c4.txt four;          LW4X="$LWC"; _lw_mk "$CA" "$LW4X" 'carries four' c4b.txt 'four b'; LW4Y="$LWC"
_lw_mk "$CA" "$LWCAM" six c6.txt six;            LW6X="$LWC"; _lw_mk "$CA" "$LW6X" 'carries six' c6b.txt 'six b'; LW6Y="$LWC"
_lw_mk "$CA" "$LWCAM" seven c7.txt seven;        LW7X="$LWC"; _lw_mk "$CA" "$LW7X" 'carries seven' c7b.txt 'seven b'; LW7Y="$LWC"
_lw_mk "$CA" "$LWCAM" eight c8.txt eight;        LW8X="$LWC"; _lw_mk "$CA" "$LW8X" mid c8m.txt mid; LW8Y="$LWC"
_lw_mk "$CA" "$LW8Y" outer c8o.txt outer;        LW8Z="$LWC"
_lw_mk "$CA" "$LWCAM" 'eight b' c8b.txt 'eight b'; LW8B="$LWC"
for _lwi in 1 2 3 4; do _lw_mk "$CA" "$LW8B" "q$_lwi" "q$_lwi.txt" "q$_lwi"; eval "LW8Q$_lwi=\$LWC"; done
_lw_mk "$CA" "$LWCAM" nine c9.txt nine;          LW9X="$LWC"; _lw_mk "$CA" "$LW9X" 'carries nine' c9b.txt 'nine b'; LW9Y="$LWC"
_lw_mk "$CA" "$LWCAM" ten c10.txt ten;           LW10X="$LWC"; _lw_mk "$CA" "$LW10X" 'carries ten' c10b.txt 'ten b'; LW10Y="$LWC"
_lw_mk "$CA" "$LWCAM" eleven c11.txt eleven;     LW11X="$LWC"; _lw_mk "$CA" "$LW11X" 'carries eleven' c11b.txt 'eleven b'; LW11Y="$LWC"
_lw_mk "$CA" "$LW11X" 'eleven, unpushed' c11u.txt 'eleven u'; LW11W="$LWC"
_lwg "$CA" push -q origin "$LW1Y:refs/heads/carry" "$LW2Y:refs/heads/carry2" "$LW3X:refs/heads/other3" \
  "$LW3Z:refs/heads/twin-a" "$LW3Z:refs/heads/twin-b" "$LW4X:refs/heads/x4" "$LW4Y:refs/heads/y4" "$LW6Y:refs/heads/pr6" \
  "$LW7Y:refs/heads/c7" "$LW8Y:refs/heads/mid8" "$LW8Z:refs/heads/outer8" "$LW8Q1:refs/heads/q1" "$LW8Q2:refs/heads/q2" \
  "$LW8Q3:refs/heads/q3" "$LW8Q4:refs/heads/q4" "$LW9X:refs/heads/b9" "$LW9Y:refs/heads/c9" "$LW10X:refs/heads/b10" \
  "$LW10Y:refs/heads/c10" "$LW11Y:refs/heads/c11" "$LW2X:refs/heads/feat2" >/dev/null 2>&1   # feat2 is pushed under its own name: see the note on B9.2
_lwg "$CA" fetch -q origin >/dev/null 2>&1
for _lwi in "feat1 $LW1X" "feat2 $LW2X" "alias3 $LW3X" "done5 $LWCA0" "b8 $LW8X" "b8b $LW8B" "b9 $LW9X" "b10 $LW10X" "b11 $LW11W"; do
  _lwg "$CA" branch -q ${_lwi% *} ${_lwi#* } >/dev/null 2>&1
done
_lwg "$CA" branch -q --set-upstream-to=origin/b9 b9 >/dev/null 2>&1
_lwg "$CA" branch -q --set-upstream-to=origin/b10 b10 >/dev/null 2>&1
_lwg "$CA" worktree add -q --detach "$LW/ca-wt6" "$LW6X" >/dev/null 2>&1
_lwg "$CA" worktree add -q -b wt7 "$LW/ca-wt7" "$LW7X" >/dev/null 2>&1
printf 'not yet committed\n' > "$LW/ca-wt7/wip.txt"
_lw_prs fixture_ca "$(_lw_pr 7 carry2 "$LW2Y" green notes/7.md repo=fixture/ca)" "$(_lw_pr 60 pr6 "$LW6Y" green notes/60.md repo=fixture/ca)" \
  "$(_lw_pr 90 b9 "$LW9X" green notes/90.md state=CLOSED repo=fixture/ca)" "$(_lw_pr 100 b10 "$LW10X" green notes/100.md repo=fixture/ca)" \
  "$(_lw_pr 101 c10 "$LW10Y" green notes/101.md repo=fixture/ca)"
_lwo=""
for _lwi in "$LW1X:$LW1Y" "$LW2X:$LW2Y" "$LW4X:$LW4Y" "$LW6X:$LW6Y" "$LW7X:$LW7Y" "$LW8X:$LW8Y" "$LW8Y:$LW8Z" "$LW8B:$LW8Q4" \
             "$LW9X:$LW9Y" "$LW10X:$LW10Y" "$LW11X:$LW11Y" "$LW11X:$LW11W" "$LWCA0:$LWCAM"; do
  _lwo="$_lwo$(_lw_anc "$CA" "${_lwi%:*}" "${_lwi#*:}")"
done
_lwo="$_lwo$(_lw_anc "$CA" "$LW11W" "$LW11Y")$(_lw_anc "$CA" "$LW1X" refs/remotes/origin/main)"
is "A1 fixture: each carried tip is a proper ancestor of its carrier, the unpushed tip of none, and no case tip is on main (fixture control)" "$_lwo" "yyyyyyyyyyyyynn"
is "A1 fixture: origin holds every pushed name at its commit, and origin/HEAD is main (fixture control)" \
   "$(_lwq "$CA" refs/remotes/origin/carry)|$(_lwq "$CA" refs/remotes/origin/q4)|$(_lwg "$CA" symbolic-ref -q refs/remotes/origin/HEAD 2>/dev/null)" \
   "$LW1Y|$LW8Q4|refs/remotes/origin/main"
is "A1 fixture: b9 and b10 track their own names, and wt7 holds one untracked file (fixture control)" \
   "$(_lwg "$CA" rev-parse --abbrev-ref b9@{upstream} 2>/dev/null) $(_lwg "$CA" rev-parse --abbrev-ref b10@{upstream} 2>/dev/null) $(_lwg "$LW/ca-wt7" status --porcelain 2>/dev/null)" \
   "origin/b9 origin/b10 ?? wip.txt"

_lw_run CA1 "$LW/hA" "$LW/cwd" inventory --repo "$CA" --tsv
_lw_run CA2 "$LW/hA" "$LW/cwd" inventory --repo "$CA" --tsv --no-gh
is "A1: both inventory runs over ca exit 0 and print rows (control)" "$(_lw_rc CA1)$(_lw_rc CA2) $([ -s "$(_lw_o CA1)" ] && [ -s "$(_lw_o CA2)" ] && echo rows)" "00 rows"
T1="$(_lw_o CA1)"; T2="$(_lw_o CA2)"
# B9.1
is "B9.1: a branch whose tip a pushed branch strictly descends from, no PR anywhere, is carried and not unproposed" \
   "$(_lw_many "$T1" branch feat1 0 carried unproposed unknown:unproposed)" "carried=yes unproposed=no unknown:unproposed=no"
is "B9.1: its detail holds the element carried by origin/carry" "$(_lw_elem "$T1" branch feat1 'carried by origin/carry')" yes
is "B9.1: the carrier's own row, the remote origin/carry, stays unproposed and is not carried (control)" \
   "$(_lw_many "$T1" remote origin/carry 0 unproposed carried)" "unproposed=yes carried=no"
# B9.2. The review round (finding 3) pushed feat2 as origin/feat2 at its tip. Contract A1 says --no-gh
# "keeps unknown:pr-open as 5.1 says", and the inventory spec gives a branch never pushed under its own
# name no unknown:pr-* under --no-gh (it heads no PR), so only a branch with an origin ref of its own can
# keep the entry. feat2 is carried all the same, by origin/carry2, which strictly descends from it.
is "B9.2: with an open same-repository PR #7 headed carry2, the branch it holds is carried, not unproposed" \
   "$(_lw_many "$T1" branch feat2 0 carried unproposed pr-open)" "carried=yes unproposed=no pr-open=no"
is "B9.2: and its detail names the carrier as #7" "$(_lw_elem "$T1" branch feat2 'carried by #7')" yes
is "B9.2: under --no-gh it is still carried and keeps unknown:pr-open" "$(_lw_many "$T2" branch feat2 0 carried unknown:pr-open)" "carried=yes unknown:pr-open=yes"
is "B9.2: and under --no-gh the carrier is written origin/carry2" "$(_lw_elem "$T2" branch feat2 'carried by origin/carry2')" yes
# B9.3
is "B9.3: a local branch whose tip equals origin/other3's (another name, no upstream) is carried by it" \
   "$(_lw_holds "$T1" branch alias3 carried) $(_lw_elem "$T1" branch alias3 'carried by origin/other3')" "yes yes"
is "B9.3: two remote rows at one commit carry neither each other: both unproposed, neither carried (control)" \
   "$(_lw_many "$T1" remote origin/twin-a 0 carried unproposed) $(_lw_many "$T1" remote origin/twin-b 0 carried unproposed)" \
   "carried=no unproposed=yes carried=no unproposed=yes"
# B9.4
is "B9.4: a remote row origin/x4 that origin/y4 strictly descends from is carried, and the detail names origin/y4" \
   "$(_lw_many "$T1" remote origin/x4 0 carried unproposed) $(_lw_elem "$T1" remote origin/x4 'carried by origin/y4')" "carried=yes unproposed=no yes"
# B9.5
is "B9.5: a branch whose tip origin/main reaches is landed, never carried, though every carrier descends from it (control)" \
   "$(_lw_many "$T1" branch done5 0 landed carried)" "landed=yes carried=no"
# B9.6
is "B9.6: a detached worktree whose HEAD an open PR's head descends from is carried, by #60" \
   "$(_lw_holds "$T1" worktree "$LW/ca-wt6" carried) $(_lw_elem "$T1" worktree "$LW/ca-wt6" 'carried by #60')" "yes yes"
is "B9.6: under --no-gh the same worktree reads carried by origin/pr6 (A1 detail)" "$(_lw_elem "$T2" worktree "$LW/ca-wt6" 'carried by origin/pr6')" yes
# B9.7, B9.12
is "B9.7: a worktree with an uncommitted change on a carried tip reads uncommitted,carried" "$(_lw_st "$T1" worktree "$LW/ca-wt7")" "uncommitted,carried"
_lwo="$(_lw_order "$T1")"
is "B9.12: carried sits between pr-closed-unlanded and orphan: no row breaks the state order, and some row holds carried" \
   "${_lwo%|*} $([ "${_lwo#*|}" -gt 0 ] 2>/dev/null && echo carried || echo 'no carried row')" "0 carried"
# B9.8
is "B9.8: of two carriers, origin/outer8 descending from origin/mid8, only origin/outer8 is named" \
   "$(_lw_elem "$T1" branch b8 'carried by origin/outer8')" yes
is "B9.8: of four outermost carriers, three are named by name and the fourth counted" \
   "$(_lw_elem "$T1" branch b8b 'carried by origin/q1, origin/q2, origin/q3, and 1 more')" yes
# B9.9
is "B9.9: a branch whose newest PR was closed unmerged, and whose tip a carrier reaches, is carried and not pr-closed-unlanded" \
   "$(_lw_many "$T1" branch b9 0 carried pr-closed-unlanded unknown:pr-closed-unlanded)" "carried=yes pr-closed-unlanded=no unknown:pr-closed-unlanded=no"
# B9.10
is "B9.10: a branch with its own open PR, inside another PR's head, is pr-open and not carried (control)" \
   "$(_lw_many "$T1" branch b10 0 pr-open carried)" "pr-open=yes carried=no"
# B9.11
is "B9.11: a branch with one unpushed commit on a carried base is unpushed and not carried (control)" \
   "$(_lw_many "$T1" branch b11 0 unpushed carried)" "unpushed=yes carried=no"
# <<< lost-work-inventory-carried
