# >>> stuck-pr-page
printf '\nthe stuck-PR page: felix land --prs and --queue, the fixture, usage and the unread readings (spec v2, blind)\n'
# Blind, written from the stuck-PR spec v2 (audits/2026-10-01-report-v5-review/
# specs/stuck-pr/spec-v2.md) alone on 2026-10-17, before lib/pr-status.sh
# existed. No engine code was read for an expected value: lib/green-tick.sh was
# read only for where the spec's ledger, lock, paused file and job plist live.
# Parts 1310 and 1320 run on the fixture this part builds; 1320 removes it.
#
# The fixture: three bare origins whose paths end github.com/fixture/home.git,
# two.git and three.git, so each slug is fixture/<name> and the governed
# account is fixture. home is cloned from the first and is also the Felix home:
# it holds projects/felix (remote_match github.com/fixture/home), projects/two,
# projects/three and projects/loose (no remote_match). Its origin/main is the
# second of two commits, so a ledger row can name the current main or an older
# one. two is a clone with a pushed main; three is a clone of an empty origin
# with an unpushed main, so it has no origin/main and no origin/HEAD. Memory is
# a fixture directory, so each project's land/ directory is $SPM/<p>/land.
#
# gh and launchctl are stubs first on PATH, each logging its argv. gh answers
# pr list from ctl/prs.<owner>_<name>.json, the repository taken from -R or
# --repo, else from the origin of the directory it runs in, and fails as
# ctl/prs.<key>.rc says; it answers api GETs of the Actions billing from a
# fixed body, or fails as ctl/api.rc says. It logs the XDG state and cache
# directories and GH_CONFIG_DIR it was handed. launchctl print succeeds only
# while ctl/loaded exists. ps is the real one: a lock names this shell's pid.
# The home's engine/harness/felix is a tripwire that logs if anything runs it.
# HOME is a fixture directory on every run, so nothing reaches ~/Library.
SP="$TMP/stuck-pr"; mkdir -p "$SP"; SP="$(cd "$SP" && pwd -P)"
SPO="$SP/github.com/fixture/home.git"; SPH="$SP/home"
SP2O="$SP/github.com/fixture/two.git"; SP2="$SP/two"
SP3O="$SP/github.com/fixture/three.git"; SP3="$SP/three"
SPM="$SP/mem"; SPU="$SP/user"; SPB="$SP/bin"; SPK="$SP/ctl"; SPL="$SP/log"; SPX="$SP/out"; SPT="$SP/tmp"
SPLAND="$(FELIX_MEMORY="$SPM" felix_mem_dir felix)/land"; SP2LAND="$(FELIX_MEMORY="$SPM" felix_mem_dir two)/land"
mkdir -p "$SPO" "$SP2O" "$SP3O" "$SPM" "$SPU/.config/gh" "$SPB" "$SPK" "$SPL" "$SPX" "$SPT" "$SP/norepo" "$SP/cache"
_sp_put() { mkdir -p "$(dirname "$1")" && LC_ALL=C sed "s#@SP@#$SP#g" > "$1" && chmod +x "$1"; }

_sp_put "$SPB/gh" <<'SPSTUB'
#!/bin/bash
SP='@SP@'; K="$SP/ctl"
printf '%s\n' "$*" >> "$SP/log/gh.log"
printf '%s\t%s\t%s\n' "${XDG_STATE_HOME-unset}" "${XDG_CACHE_HOME-unset}" "${GH_CONFIG_DIR-unset}" >> "$SP/log/gh.env"
jqx=""; repo=""; prev=""; bill=0; user=0
for a in "$@"; do
  case "$prev" in -q|--jq) jqx="$a" ;; -R|--repo) repo="$a" ;; esac
  case "$a" in --jq=*) jqx="${a#--jq=}" ;; --repo=*) repo="${a#--repo=}" ;; esac
  case "$a" in *settings/billing/actions*) bill=1 ;; users/*|/users/*) user=1 ;; esac
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
    [ -f "$K/prs.$key.json" ] || { printf 'stub: no answer for repository [%s]\n' "$repo" >&2; exit 4; }
    out < "$K/prs.$key.json"; exit 0 ;;
esac
if [ "${1:-}" = api ]; then
  if [ "$bill" = 1 ]; then
    if [ -f "$K/api.rc" ]; then cat "$K/api.err" >&2; exit "$(cat "$K/api.rc")"; fi
    printf '{"total_minutes_used":123,"total_paid_minutes_used":0,"included_minutes":2000,"minutes_used_breakdown":{"UBUNTU":123}}\n' | out; exit 0
  fi
  if [ "$user" = 1 ]; then printf '{"login":"fixture","id":1,"type":"User"}\n' | out; exit 0; fi
  printf 'gh: Not Found (HTTP 404)\n' >&2; exit 1
fi
printf 'stub: gh %s is not served\n' "$*" >&2
exit 1
SPSTUB
_sp_put "$SPB/launchctl" <<'SPSTUB'
#!/bin/bash
SP='@SP@'
printf '%s\n' "$*" >> "$SP/log/launchctl.log"
case "${1:-}" in print) [ -f "$SP/ctl/loaded" ] && exit 0; exit 113 ;; esac
exit 0
SPSTUB

# ---- the repositories -------------------------------------------------------
_sp_commit() { _fx_git "$1" add -A >/dev/null 2>&1; _fx_git "$1" -c user.name=t -c user.email=t@t commit -qm "$2" >/dev/null 2>&1; }
for _spo in "$SPO" "$SP2O" "$SP3O"; do
  _fx_git "$_spo" init -q --bare >/dev/null 2>&1
  _fx_git "$_spo" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
done
_fx_git "$SP" clone -q "$SPO" home >/dev/null 2>&1
_fx_git "$SPH" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
mkdir -p "$SPH/projects/felix" "$SPH/projects/two" "$SPH/projects/three" "$SPH/projects/loose" \
         "$SPH/engine/harness" "$SPH/notes" "$SPH/landdir" "$SPH/riskdir"
printf '{\n  "name": "felix",\n  "remote_match": "github.com/fixture/home",\n  "gate": "true"\n}\n' > "$SPH/projects/felix/project.json"
printf '{\n  "name": "two",\n  "remote_match": "github.com/fixture/two",\n  "gate": "true"\n}\n' > "$SPH/projects/two/project.json"
printf '{\n  "name": "three",\n  "remote_match": "github.com/fixture/three",\n  "gate": "true"\n}\n' > "$SPH/projects/three/project.json"
printf '{\n  "name": "loose",\n  "gate": "true"\n}\n' > "$SPH/projects/loose/project.json"
for _spo in felix two three loose; do printf '# %s\n' "$_spo" > "$SPH/projects/$_spo/CLAUDE.md"; done
# The land table at origin/main: one founder row. The risk table at origin/main:
# a path row naming a channel with no confine, and one with a content confine.
printf 'landdir/.*\tfounder\t-\t-\n' > "$SPH/projects/felix/land.tsv"
{ printf 'red\tpath\t^riskdir/plain/\ta person reads these\treviewed\t-\n'
  printf 'red\tpath\t^riskdir/confined/\tonly some lines matter\treviewed\t^[-+]zz\n'; } > "$SPH/projects/felix/risk.tsv"
_sp_put "$SPH/engine/harness/felix" <<'SPSTUB'
#!/bin/bash
printf '%s\n' "$*" >> '@SP@/log/trip.log'
exit 0
SPSTUB
printf 'home\n' > "$SPH/README.md"; printf 'keep\n' > "$SPH/notes/keep.md"
_sp_commit "$SPH" base
_fx_git "$SPH" push -q -u origin main >/dev/null 2>&1
SPOLD="$(git -C "$SPH" rev-parse HEAD 2>/dev/null)"
printf 'second\n' > "$SPH/notes/second.md"; _sp_commit "$SPH" second
_fx_git "$SPH" push -q origin main >/dev/null 2>&1
_fx_git "$SPH" fetch -q origin >/dev/null 2>&1
_fx_git "$SPH" remote set-head origin main >/dev/null 2>&1
SPMAIN="$(git -C "$SPH" rev-parse refs/remotes/origin/main 2>/dev/null)"
# Rows that exist only in the working tree, never at origin/main.
printf 'wtonly/.*\tfounder\t-\t-\n' >> "$SPH/projects/felix/land.tsv"
printf 'red\tpath\t^riskdir/wt/\tonly in the working tree\treviewed\t-\n' >> "$SPH/projects/felix/risk.tsv"

_fx_git "$SP" clone -q "$SP2O" two >/dev/null 2>&1
_fx_git "$SP2" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
printf 'two\n' > "$SP2/README.md"; _sp_commit "$SP2" base
_fx_git "$SP2" push -q -u origin main >/dev/null 2>&1
_fx_git "$SP2" fetch -q origin >/dev/null 2>&1
_fx_git "$SP2" remote set-head origin main >/dev/null 2>&1
_fx_git "$SP" clone -q "$SP3O" three >/dev/null 2>&1
_fx_git "$SP3" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
printf 'three\n' > "$SP3/README.md"; _sp_commit "$SP3" base

# ---- pull requests as gh lists them ---------------------------------------
# A head is 40 hex digits led by the number, so its first 7 characters differ
# from every other head's: _sp_sha the current head, _sp_old an older one,
# _sp_two the heads of two's pull requests.
_sp_sha() { printf '%04d%s' "$1" c0ffeec0ffeec0ffeec0ffeec0ffeec0ffee; }
_sp_old() { printf '%04d%s' "$1" deadbedeadbedeadbedeadbedeadbedeadbe; }
_sp_two() { printf '%04d%s' "$1" abcdefabcdefabcdefabcdefabcdefabcdef; }
_sp_ago() { local t; t=$(( $(date +%s) - $1 )); date -u -r "$t" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$t" +%Y-%m-%dT%H:%M:%SZ; }
SP_UPD="$(_sp_ago 180000)"   # fifty hours ago
_sp_cr() { printf '{"__typename":"CheckRun","name":"%s","workflowName":"%s","status":"%s","conclusion":"%s","startedAt":"%s","completedAt":"%s","detailsUrl":"https://example.invalid/%s"}' \
             "$1" "$1" "$2" "$3" "$SP_UPD" "$SP_UPD" "$1"; }
_sp_sc() { printf '{"__typename":"StatusContext","context":"%s","state":"%s","startedAt":"%s","targetUrl":"https://example.invalid/%s"}' "$1" "$2" "$SP_UPD" "$1"; }
_sp_roll() {
  case "$1" in
    green)   printf '[%s,%s]' "$(_sp_cr gate COMPLETED SUCCESS)" "$(_sp_sc ci/other SUCCESS)" ;;
    mixed)   printf '[%s,%s,%s]' "$(_sp_cr gate COMPLETED SUCCESS)" "$(_sp_cr lint COMPLETED SKIPPED)" "$(_sp_cr docs COMPLETED NEUTRAL)" ;;
    red)     printf '[%s,%s]' "$(_sp_cr gate COMPLETED SUCCESS)" "$(_sp_cr lint COMPLETED FAILURE)" ;;
    running) printf '[%s,%s]' "$(_sp_cr gate COMPLETED SUCCESS)" "$(_sp_cr lint IN_PROGRESS '')" ;;
    ctxerr)  printf '[%s,%s]' "$(_sp_cr gate COMPLETED SUCCESS)" "$(_sp_sc ci/other ERROR)" ;;
    ctxpend) printf '[%s,%s]' "$(_sp_cr gate COMPLETED SUCCESS)" "$(_sp_sc ci/other PENDING)" ;;
    *)       printf '[]' ;;
  esac
}
# FILES is "path:deleted-lines ..." or @100 for exactly one hundred files.
_sp_files() {
  local s="" f i=1
  if [ "$1" = @100 ]; then
    while [ "$i" -le 100 ]; do printf '%s{"path":"notes/many/f%03d.md","additions":1,"deletions":0}' "$s" "$i"; s=","; i=$((i+1)); done
    return 0
  fi
  for f in $1; do printf '%s{"path":"%s","additions":1,"deletions":%s}' "$s" "${f%:*}" "${f##*:}"; s=","; done
}
_sp_labels() { ( IFS=,; s=""; for l in $1; do printf '%s{"id":"LA_%s","name":"%s","description":"","color":"ededed"}' "$s" "$l" "$l"; s=","; done ); }
_sp_pr() {   # N FILES ROLL [title= branch= sha= base= draft= cross= author= labels= mergeable= mss= repo=]
  local n="$1" fs="$2" ro="$3" kv t="Change $1" br="b$1" sha="" base=main dr=false cr=false au=fixture lb="" mg=MERGEABLE ms=CLEAN rp=fixture/home
  shift 3
  for kv in "$@"; do case "$kv" in
    title=*) t="${kv#title=}" ;; branch=*) br="${kv#branch=}" ;; sha=*) sha="${kv#sha=}" ;; base=*) base="${kv#base=}" ;;
    draft=*) dr="${kv#draft=}" ;; cross=*) cr="${kv#cross=}" ;; author=*) au="${kv#author=}" ;; labels=*) lb="${kv#labels=}" ;;
    mergeable=*) mg="${kv#mergeable=}" ;; mss=*) ms="${kv#mss=}" ;; repo=*) rp="${kv#repo=}" ;;
  esac; done
  [ -n "$sha" ] || sha="$(_sp_sha "$n")"
  printf '{"number":%s,"title":"%s","headRefName":"%s","headRefOid":"%s","baseRefName":"%s","isDraft":%s,"isCrossRepository":%s,' "$n" "$t" "$br" "$sha" "$base" "$dr" "$cr"
  printf '"author":{"id":"U_%s","is_bot":false,"login":"%s","name":""},"labels":[%s],"mergeable":"%s","mergeStateStatus":"%s",' "$au" "$au" "$(_sp_labels "$lb")" "$mg" "$ms"
  printf '"statusCheckRollup":%s,"files":[%s],"updatedAt":"%s","url":"https://github.com/%s/pull/%s"}' "$(_sp_roll "$ro")" "$(_sp_files "$fs")" "$SP_UPD" "$rp" "$n"
}
_sp_prs() {   # KEY OBJECT... -> ctl/prs.KEY.json, a JSON array of the objects
  local k="$1" s="" o; shift
  { printf '['; for o in "$@"; do printf '%s%s' "$s" "$o"; s=","; done; printf ']\n'; } > "$SPK/prs.$k.json"
  rm -f "$SPK/prs.$k.rc" "$SPK/prs.$k.err"
}
_sp_ghfail() { printf '1\n' > "$SPK/prs.$1.rc"; printf '%s\n' "$2" > "$SPK/prs.$1.err"; }

# ---- the ledgers, the lock and the paused file -----------------------------
_sp_ledger() {
  rm -rf "$SPLAND" "$SP2LAND"; mkdir -p "$SPLAND/lock" "$SP2LAND"
  { printf '2026-10-16T09:00:00Z\tpaused\t-\t-\t-\t0\theld for a while\n'
    printf '2026-10-16T09:10:00Z\trefused\t130\t%s\t%s\t3\tblocker one: the receipt is stale [main %s]\n' "$(_sp_sha 130)" "$SPH" "$SPMAIN"
    printf '2026-10-16T09:11:00Z\trefused\t131\t%s\t%s\t3\tblocker two: on an older main [main %s]\n' "$(_sp_sha 131)" "$SPH" "$SPOLD"
    printf '2026-10-16T09:12:00Z\trefused\t132\t%s\t%s\t3\tblocker three: an older head [main %s]\n' "$(_sp_old 132)" "$SPH" "$SPMAIN"
    printf '2026-10-16T09:13:00Z\tsession\t133\t%s\t-\t1\tno checkout holds the gated head\n' "$(_sp_sha 133)"
    printf '2026-10-16T09:14:00Z\tlanded\t134\t%s\t%s\t2\tmerged\n' "$(_sp_old 134)" "$SPH"
    printf '2026-10-16T09:15:00Z\trefused\t1340\t%s\t%s\t3\tblocker four: another pull request [main %s]\n' "$(_sp_sha 134)" "$SPH" "$SPMAIN"
    printf '2026-10-16T09:16:00Z\trefused\t135\t%s\t%s\t3\tblocker five: refused first [main %s]\n' "$(_sp_sha 135)" "$SPH" "$SPMAIN"
    printf '2026-10-16T09:17:00Z\tskip\t135\t%s\t-\t0\twaiting on its gate run\n' "$(_sp_sha 135)"
    printf '2026-10-16T09:18:00Z\tsession\t202\t%s\t-\t1\tthe home ledger speaks of two\n' "$(_sp_two 202)"
  } > "$SPLAND/ledger.tsv"
  printf '2026-10-16T09:20:00Z\tsession\t201\t%s\t-\t1\tthe gated head is in no checkout of two\n' "$(_sp_two 201)" > "$SP2LAND/ledger.tsv"
  sh -c 'exit 0' & _spdead=$!; wait "$_spdead"
  printf '%s\n' "$_spdead" > "$SPLAND/lock/pid"; printf 'Thu Jan  1 00:00:00 1970\n' > "$SPLAND/lock/started"
  printf 'held for a while\nthe second line of the reason\n' > "$SPLAND/paused"
}
_sp_ledger

# ---- running the page --------------------------------------------------------
# felix land ARGS in directory D. stdout to out/out, stderr to out/err, status
# in SPRC; out/both holds the two together for usage text.
_sp_land() {   # D ARGS...
  local d="$1"; shift
  ( cd "$d" || exit 97
    exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE -u CLAUDE_CODE_SESSION_ID \
      HOME="$SPU" FELIX_HOME="$SPH" FELIX_HOME_DIR="$SPH" FELIX_MEMORY="$SPM" FELIX_PLUGIN_CACHE="$SP/cache" \
      XDG_STATE_HOME="$SPU/.state-caller" XDG_CACHE_HOME="$SPU/.cache-caller" GH_CONFIG_DIR="$SPU/.config/gh" \
      TMPDIR="$SPT" PATH="$SPB:$PATH" "$FELIX" land "$@" ) > "$SPX/out" 2> "$SPX/err"
  SPRC=$?
  cat "$SPX/out" "$SPX/err" > "$SPX/both"
}
_sp_keep() { cp "$SPX/out" "$SPX/$1"; printf '%s\n' "$SPRC" > "$SPX/$1.rc"; }
_sp_logs0() { rm -rf "$SPL"; mkdir -p "$SPL"; }
_sp_prl() { if [ -f "$1" ]; then LC_ALL=C awk 'index($0, "pr list") == 1 { n++ } END { print n + 0 }' "$1"; else echo 0; fi; }
_sp_cnt() { if [ -f "$SPL/$1.log" ]; then LC_ALL=C awk 'END { print NR }' "$SPL/$1.log"; else echo 0; fi; }
# Readers of a --tsv page. The pr row of #N, a field of it, its state (the
# states cell before its first comma), its flags (what follows), a source row.
_sp_row()   { LC_ALL=C awk -F'\t' -v r="#$2" '$1 == "pr" && $3 == r' "$1" 2>/dev/null; }
_sp_nrow()  { _sp_row "$1" "$2" | LC_ALL=C awk 'END { print NR }'; }
_sp_f()     { _sp_row "$1" "$2" | LC_ALL=C awk -F'\t' -v k="$3" 'NR == 1 { printf "%s", $k }'; }
_sp_state() { _sp_f "$1" "$2" 4 | LC_ALL=C sed 's/,.*//'; }
_sp_flags() { _sp_f "$1" "$2" 4 | LC_ALL=C awk '{ i = index($0, ","); if (i) printf "%s", substr($0, i); }'; }
_sp_src()   { LC_ALL=C awk -F'\t' -v r="$2" '$1 == "source" && $3 == r' "$1" 2>/dev/null; }
_sp_srcf()  { _sp_src "$1" "$2" | LC_ALL=C awk -F'\t' -v k="$3" 'NR == 1 { printf "%s", $k }'; }
_sp_prn()   { LC_ALL=C awk -F'\t' '$1 == "pr" { n++ } END { print n + 0 }' "$1" 2>/dev/null; }
# The line of a text page that begins "#N ", and its line number.
_sp_tline() { LC_ALL=C awk -v p="#$2 " 'index($0, p) == 1' "$1" 2>/dev/null; }
_sp_tno()   { LC_ALL=C awk -v p="#$2 " 'index($0, p) == 1 { print NR; exit }' "$1" 2>/dev/null; }
_sp_lacks() { case "$2" in *"$3"*) bad "$1" "[$2] holds [$3]" ;; *) ok "$1" ;; esac; }
# State and needs of #N in FILE, as one assertion each.
_sp_is() {   # LABEL FILE N STATE NEEDS
  is "$1: #$3 is in state $4" "$(_sp_state "$2" "$3")" "$4"
  [ -z "$5" ] || is "$1: #$3 needs $5" "$(_sp_f "$2" "$3" 5)" "$5"
}
_sp_not() {   # LABEL FILE N STATE
  local s; s="$(_sp_state "$2" "$3")"
  if [ -n "$s" ] && [ "$s" != "$4" ]; then ok "$1"; else bad "$1" "#$3 is in state [$s]"; fi
}
# The read-only snapshot: refs, packed refs, HEAD, index, config, FETCH_HEAD,
# the object count, any worktree, and every path and file under a land/ dir.
_sp_snap() {   # REPO LANDDIR
  printf 'refs\n'; git -C "$1" for-each-ref --format='%(objectname) %(refname)' 2>&1
  printf 'packed %s\n' "$(cksum < "$1/.git/packed-refs" 2>/dev/null)"
  printf 'head %s\n' "$(cat "$1/.git/HEAD" 2>&1)"
  printf 'index %s\n' "$(cksum < "$1/.git/index" 2>/dev/null)"
  printf 'config %s\n' "$(cksum < "$1/.git/config" 2>&1)"
  printf 'fetch-head %s\n' "$(cksum < "$1/.git/FETCH_HEAD" 2>/dev/null)"
  git -C "$1" count-objects -v 2>&1 | LC_ALL=C grep -E '^(count|in-pack|packs):'
  printf 'worktrees\n'; ls -a "$1/.git/worktrees" 2>/dev/null
  printf 'land\n'
  if [ -d "$2" ]; then ( cd "$2" && find . -print | LC_ALL=C sort && find . -type f -exec cksum {} + | LC_ALL=C sort ) 2>&1; fi
}
_sp_snapall() { _sp_snap "$SPH" "$SPLAND"; _sp_snap "$SP2" "$SP2LAND"; _sp_snap "$SP3" "$SPM/three/land"; }

# ---- fixture controls -------------------------------------------------------
_spo="$(printf '%s %s' "$SPMAIN" "$SPOLD" | LC_ALL=C awk '{ for (i = 1; i <= 2; i++) if ($i ~ /^[0123456789abcdef]+$/ && length($i) == 40) n++ } END { print n + 0 }')"
is "the stuck-PR fixture: origin/main and the older main are two commits (fixture control)" "$_spo|$([ "$SPMAIN" != "$SPOLD" ] && echo two)" "2|two"
is "the stuck-PR fixture: origin/HEAD names main, and three has no origin/main and no origin/HEAD (fixture control)" \
   "$(git -C "$SPH" symbolic-ref -q refs/remotes/origin/HEAD 2>&1)|$(git -C "$SP3" rev-parse -q --verify refs/remotes/origin/main 2>/dev/null)|$(git -C "$SP3" symbolic-ref -q refs/remotes/origin/HEAD 2>/dev/null)" \
   "refs/remotes/origin/main||"
is "the stuck-PR fixture: the landdir founder row is on origin/main and the wtonly row only in the working tree (fixture control)" \
   "$(git -C "$SPH" show refs/remotes/origin/main:projects/felix/land.tsv 2>&1 | LC_ALL=C cut -f1 | LC_ALL=C tr '\n' ' ')|$(LC_ALL=C cut -f1 "$SPH/projects/felix/land.tsv" | LC_ALL=C tr '\n' ' ')" \
   "landdir/.* |landdir/.* wtonly/.* "
_sp_prs fixture_home "$(_sp_pr 7 notes/7.md:0 green)"
is "the stuck-PR fixture: the gh stub serves the home's pull requests from the home's directory (fixture control)" \
   "$( cd "$SPH" && PATH="$SPB:$PATH" gh pr list --state open --limit 1000 --json number 2>&1 | LC_ALL=C grep -o '"number":7,' )" '"number":7,'
_sp_prs fixture_two "$(_sp_pr 8 notes/8.md:0 green repo=fixture/two)"
is "the stuck-PR fixture: and two's from -R fixture/two, whatever directory it runs in (fixture control)" \
   "$( cd "$SPH" && PATH="$SPB:$PATH" gh pr list -R fixture/two --state open 2>&1 | LC_ALL=C grep -o '"number":8,' )" '"number":8,'
if command -v jq >/dev/null 2>&1; then
  is "the stuck-PR fixture: every pull request object the builder writes is JSON gh could have printed (fixture control)" \
     "$(_sp_pr 9 'a.md:0 b.md:2' red labels=felix:hold,needs-founder title='a\ttab' | jq -r '[.number, .labels[1].name, .files[1].deletions, .statusCheckRollup[1].conclusion, (.title | length)] | @tsv' 2>&1)" \
     "$(printf '9\tneeds-founder\t2\tFAILURE\t5')"
else skip "the stuck-PR fixture: every pull request object the builder writes is JSON gh could have printed (fixture control)" "no jq"; fi
is "the stuck-PR fixture: the land directory holds the ledger, a dead lock and paused (fixture control)" \
   "$(cd "$SPLAND" && find . -type f | LC_ALL=C sort | LC_ALL=C tr '\n' ' ')" "./ledger.tsv ./lock/pid ./lock/started ./paused "
_sp_logs0; : > "$SPL/gh.log"

# ------------------------------------------------- usage and exit status (§1, §7) -
_sp_land "$SPH"
is "case 19: felix land alone exits 2" "$SPRC" 2
has "case 19: and its usage names --prs" "$(cat "$SPX/both")" "--prs"
has "case 19: and --queue" "$(cat "$SPX/both")" "--queue"
_sp_land "$SPH" --prs --queue
is "case 19: felix land --prs --queue exits 2" "$SPRC" 2
has "case 19: and prints the usage, which names --prs" "$(cat "$SPX/both")" "--prs"
_sp_land "$SPH" --prs --tick
is "case 19: felix land --prs --tick exits 2" "$SPRC" 2
has "case 19: and prints the usage, which names --prs" "$(cat "$SPX/both")" "--prs"
_sp_land "$SPH" --queue --repo x
is "case 19: felix land --queue --repo x exits 2: --repo belongs to --prs" "$SPRC" 2
has "case 19: and prints the usage, which names --prs" "$(cat "$SPX/both")" "--prs"
_sp_land "$SPH" --prs --repo "$SPH" --repo "$SP2"
is "§1: two --repo options exit 2: one --repo only" "$SPRC" 2
_sp_land "$SPH" --prs --sideways
is "§1: --prs with an argument it does not know exits 2" "$SPRC" 2
is "§2: no usage run asked gh or launchctl anything" "$(_sp_cnt gh)$(_sp_cnt launchctl)" "00"
_sp_land "$SPH" --status
_spo="$(LC_ALL=C sed -n 1,3p "$SPX/out" | LC_ALL=C awk '{ k = $1; gsub(/[^a-z]/, "", k); printf "%s ", k }')"
is "case 19: felix land --status still exits 0" "$SPRC" 0
is "case 19: and still prints installed, loaded and paused, first and in that order" "$_spo" "installed loaded paused "
_sp_land "$SP/norepo" --prs
is "§7: --prs where no repository holds the directory exits 1" "$SPRC" 1
_sp_land "$SPH" --prs --repo "$SP/norepo"
is "§7: --prs --repo naming a directory no repository holds exits 1" "$SPRC" 1

# ------------------------------------------- gh failing, gh empty, --no-gh (§5) ---
_sp_logs0; _sp_ghfail fixture_home "HTTP 502: Bad Gateway (https://api.github.com/graphql)"
_sp_land "$SPH" --prs --tsv; _sp_keep ghfail.tsv
_sp_land "$SPH" --prs; _sp_keep ghfail.txt
is "case 12: gh failing still exits 0 with --tsv" "$(cat "$SPX/ghfail.tsv.rc")" 0
is "case 12: and without it" "$(cat "$SPX/ghfail.txt.rc")" 0
is "case 12: gh failing prints no pr row" "$(_sp_prn "$SPX/ghfail.tsv")" 0
is "case 12: the gh source row says unread" "$(_sp_srcf "$SPX/ghfail.tsv" gh 4)" "unread"
has "case 12: and gives gh's reason" "$(_sp_srcf "$SPX/ghfail.tsv" gh 8)" "HTTP 502"
has "case 12: the text page says pull requests not read, with the reason" "$(cat "$SPX/ghfail.txt")" "pull requests not read: "
_sp_lacks "case 12: and never no open pull requests" "$(cat "$SPX/ghfail.txt")" "no open pull requests"
is "case 12: the page asked gh for the list once in each run" "$(_sp_prl "$SPL/gh.log")" 2

_sp_logs0; _sp_prs fixture_home
_sp_land "$SPH" --prs --tsv; _sp_keep empty.tsv
_sp_land "$SPH" --prs; _sp_keep empty.txt
is "case 13: gh answering [] exits 0" "$(cat "$SPX/empty.tsv.rc")$(cat "$SPX/empty.txt.rc")" "00"
is "case 13: the gh source row says none" "$(_sp_srcf "$SPX/empty.tsv" gh 4)" "none"
is "case 13: and there is no pr row" "$(_sp_prn "$SPX/empty.tsv")" 0
has "case 13: the text page says no open pull requests" "$(cat "$SPX/empty.txt")" "no open pull requests"
_sp_lacks "case 13: and not that they were not read" "$(cat "$SPX/empty.txt")" "not read: "

_sp_logs0; _sp_prs fixture_home "$(_sp_pr 105 notes/105.md:0 green)"
_sp_land "$SPH" --prs --tsv --no-gh; _sp_keep nogh.tsv
_sp_land "$SPH" --prs --no-gh; _sp_keep nogh.txt
is "§1: --no-gh exits 0" "$(cat "$SPX/nogh.tsv.rc")$(cat "$SPX/nogh.txt.rc")" "00"
is "§1: --no-gh asks gh nothing" "$(_sp_cnt gh)" 0
is "§5: with --no-gh there is no pr row, though gh would have listed one" "$(_sp_prn "$SPX/nogh.tsv")" 0
is "§5: the gh source row says unread" "$(_sp_srcf "$SPX/nogh.tsv" gh 4)" "unread"
is "§4.4: and the budget row says unread, gh not asked" "$(_sp_srcf "$SPX/nogh.tsv" budget 4)" "unread"
has "§5: the text page says pull requests not read" "$(cat "$SPX/nogh.txt")" "pull requests not read: "
_sp_lacks "§5: and never no open pull requests" "$(cat "$SPX/nogh.txt")" "no open pull requests"
is "§6.1: --no-gh still prints the six source rows, in the order gh land ledger lander budget origin" \
   "$(LC_ALL=C awk -F'\t' '$1 == "source" { printf "%s ", $3 }' "$SPX/nogh.tsv")" "gh land ledger lander budget origin "
# <<< stuck-pr-page
