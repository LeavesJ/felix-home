# >>> land-on-green
printf '\nland on green: felix land, its preflight, candidates and merge (contract G1, G2, G4-G6, G8, G9, blind)\n'
# Blind, written from docs/2026-10-15-land-on-green-contract.md alone on
# 2026-10-15, before lib/green-tick.sh or any felix land existed. Nothing here
# was read off an implementation of it. Part 1281 carries G3, G7 and --install
# on the fixture this part builds, and 1282 review round 1 and A1-A7.
#
# The fixture: a bare origin whose path ends github.com/fixture/lgh.git, so the
# slug the engine derives is fixture/lgh and git fetch works offline; a home
# cloned from it holding engine/ and projects/lgh/, bound to project lgh by
# remote_match; a worktree of the home per pull request; a plugin cache whose
# felix/felix/9.0.0/harness is a copy of the home's engine/harness. The home's
# engine/harness/felix is a stub, and so is the cache's copy: it logs its own
# physical path, its working directory, its arguments and whether
# FELIX_ALLOW_RED, FELIX_KERNEL and FELIX_KERNEL_CACHE are set, and answers
# merge, install and gate as the files under ctl/ say. gh, pgrep, osascript and
# launchctl are stubs first on PATH, each logging its argv. git is real. HOME is
# a fixture directory on every call, so nothing reaches ~/Library.
#
# Where the contract leaves a shape open (the ledger's time format, the words
# of a skip row, which felix runs gate --quick), these assert only what it
# states: a skip row's detail is held to a word naming its check, and the hour
# is aged by moving the year back, or an epoch back two hours.
LG="$TMP/land-g"; mkdir -p "$LG"; LG="$(cd "$LG" && pwd -P)"
LGO="$LG/github.com/fixture/lgh.git"; LGH="$LG/home"; LGW="$LG/wt"; LGC="$LG/cache"
LGM="$LG/mem"; LGU="$LG/user"; LGB="$LG/bin"; LGK="$LG/ctl"; LGL="$LG/log"
LAND="$LGM/lgh/land"; LGE="$LGC/felix/felix/9.0.0/harness/felix"
mkdir -p "$LGO" "$LGW" "$LGC" "$LGM" "$LGU" "$LGB" "$LGK" "$LGL"
_lg_put() { mkdir -p "$(dirname "$1")" && sed "s#@LG@#$LG#g" > "$1" && chmod +x "$1"; }

_lg_put "$LGB/gh" <<'LGSTUB'
#!/bin/bash
LG='@LG@'; K="$LG/ctl"
printf '%s\n' "$*" >> "$LG/log/gh.log"
jqx=""; commit=""; prev=""
for a in "$@"; do
  case "$prev" in -q|--jq) jqx="$a" ;; --commit) commit="$a" ;; esac
  case "$a" in --jq=*) jqx="${a#--jq=}" ;; --commit=*) commit="${a#--commit=}" ;; esac
  prev="$a"
done
out() { if [ -n "$jqx" ] && command -v jq >/dev/null 2>&1; then jq -r "$jqx"; else cat; fi; }
case "${1:-} ${2:-}" in
  "auth status")
    if [ -f "$K/gh-block" ] && mkdir "$K/gh-block-taken" 2>/dev/null; then
      n=0; while [ -f "$K/gh-block" ] && [ "$n" -lt 300 ]; do sleep 0.1; n=$((n+1)); done
    fi
    rc=0; [ -f "$K/gh-auth.rc" ] && rc="$(cat "$K/gh-auth.rc")"; exit "$rc" ;;
  "pr list") out < "$K/prs.json"; exit 0 ;;
  "pr view")
    fl="$K/files.${3:-}"; [ -f "$fl" ] || fl="$K/files.default"
    { printf '{"number":%s,"files":[' "${3:-0}"; s=""
      while IFS= read -r f; do [ -n "$f" ] || continue
        printf '%s{"path":"%s","additions":1,"deletions":0}' "$s" "$f"; s=","; done < "$fl"
      printf ']}\n'; } | out; exit 0 ;;
  "run list")
    f="$K/runs.$commit"
    if [ -f "$f.rc" ]; then echo "HTTP 502: Bad Gateway" >&2; exit "$(cat "$f.rc")"; fi
    if [ -n "$jqx" ]; then
      if [ -f "$f" ]; then awk 'END { print NR }' "$f"; cat "$f"; else echo 0; fi
    else
      printf '['; s=""
      if [ -f "$f" ]; then while IFS="$(printf '\t')" read -r st co sh; do
        [ "$co" = - ] && co=""
        printf '%s{"status":"%s","conclusion":"%s","headSha":"%s"}' "$s" "$st" "$co" "$sh"; s=","; done < "$f"; fi
      printf ']\n'
    fi; exit 0 ;;
esac
exit 0
LGSTUB
_lg_put "$LGB/pgrep" <<'LGSTUB'
#!/bin/bash
LG='@LG@'
printf '%s\n' "$*" >> "$LG/log/pgrep.log"
pat=""; for a in "$@"; do case "$a" in -*) ;; *) pat="$a" ;; esac; done
[ -n "$pat" ] && [ -f "$LG/ctl/procs" ] || exit 1
hits="$(LC_ALL=C grep -nE -- "$pat" "$LG/ctl/procs" 2>/dev/null | cut -d: -f1)"
[ -n "$hits" ] || exit 1
for h in $hits; do printf '4%04d\n' "$h"; done
exit 0
LGSTUB
_lg_put "$LGB/osascript" <<'LGSTUB'
#!/bin/bash
LG='@LG@'
last="$(tail -1 "$LG/mem/lgh/land/ledger.tsv" 2>/dev/null | tr '\t' '|')"
printf '%s\t%s\n' "$*" "$last" >> "$LG/log/osa.log"
rc=0; [ -f "$LG/ctl/osa.rc" ] && rc="$(cat "$LG/ctl/osa.rc")"; exit "$rc"
LGSTUB
_lg_put "$LGB/launchctl" <<'LGSTUB'
#!/bin/bash
LG='@LG@'
printf '%s\n' "$*" >> "$LG/log/launchctl.log"
case "${1:-}" in print|list) [ -f "$LG/ctl/loaded" ] && exit 0; exit 113 ;; esac
exit 0
LGSTUB

# The bare origin, and the home cloned from it.
_fx_git "$LGO" init -q --bare >/dev/null 2>&1
_fx_git "$LGO" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
_fx_git "$LG" clone -q "$LGO" home >/dev/null 2>&1
_fx_git "$LGH" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
mkdir -p "$LGH/engine/.claude-plugin" "$LGH/engine/harness/lib" "$LGH/projects/lgh" "$LGH/notes"
printf '{ "name": "felix", "version": "9.0.0" }\n' > "$LGH/engine/.claude-plugin/plugin.json"
printf 'core 0\n' > "$LGH/engine/harness/lib/core.sh"
printf '{\n  "name": "lgh",\n  "remote_match": "github.com/fixture/lgh",\n  "gate": "true"\n}\n' > "$LGH/projects/lgh/project.json"
printf '# lgh\n' > "$LGH/projects/lgh/CLAUDE.md"; printf 'home\n' > "$LGH/README.md"
_lg_put "$LGH/engine/harness/felix" <<'LGSTUB'
#!/bin/bash
LG='@LG@'; K="$LG/ctl"
p="$0"; case "$p" in /*) ;; *) p="$PWD/$p" ;; esac
d="$(cd -P "$(dirname "$p")" 2>/dev/null && pwd -P)"; here="$(pwd -P)"
ar="${FELIX_ALLOW_RED+set}"; kn="${FELIX_KERNEL+set}"; kc="${FELIX_KERNEL_CACHE+set}"
printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$d/${p##*/}" "$here" "$*" "${ar:-unset}" "${kn:-unset}" "${kc:-unset}" >> "$LG/log/felix.log"
case "${1:-}" in
  merge)
    b="${here##*/}"
    [ -f "$K/merge.$b.out" ] && cat "$K/merge.$b.out"
    if [ -f "$K/merge.$b.push" ]; then
      case "$here/" in "$LG"/*) git push -q "$LG/github.com/fixture/lgh.git" HEAD:refs/heads/main >/dev/null 2>&1 ;; esac
    fi
    rc=0; [ -f "$K/merge.$b.rc" ] && rc="$(cat "$K/merge.$b.rc")"; exit "$rc" ;;
  install)
    [ "$d" = "$LG/home/engine/harness" ] || exit 9
    v="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$d/../.claude-plugin/plugin.json" 2>/dev/null | head -1)"
    [ -n "$v" ] || exit 8
    rm -rf "$LG/cache/felix/felix/$v"; mkdir -p "$LG/cache/felix/felix/$v"
    cp -R "$d" "$LG/cache/felix/felix/$v/harness" || exit 7
    [ ! -f "$K/install.taint" ] || printf 'taint\n' > "$LG/cache/felix/felix/$v/harness/taint"
    exit 0 ;;
  gate) rc=0; [ -f "$K/gate.rc" ] && rc="$(cat "$K/gate.rc")"; exit "$rc" ;;
esac
exit 0
LGSTUB
_lg_put "$LGH/engine/harness/hooks/session-start" <<'LGSTUB'
#!/bin/bash
LG='@LG@'
{ printf '%s\t%s\t' "$(cd -P "$(dirname "$0")" && pwd -P)" "$(pwd -P)"; tr '\n' ' '; printf '\n'; } >> "$LG/log/hook.log"
rc=0; [ -f "$LG/ctl/hook.rc" ] && rc="$(cat "$LG/ctl/hook.rc")"; exit "$rc"
LGSTUB
# Main's own acceptance check (A1) is real, so the trampoline has an engine it
# accepts: the base commit holds the real lib/resolve.sh, as 1282's A1 does.
cp "$REAL_HARNESS/lib/resolve.sh" "$LGH/engine/harness/lib/resolve.sh"
_fx_git "$LGH" add -A >/dev/null 2>&1
_fx_git "$LGH" -c user.name=t -c user.email=t@t commit -qm base >/dev/null 2>&1
_fx_git "$LGH" push -q -u origin main >/dev/null 2>&1
mkdir -p "$LGC/felix/felix/9.0.0"; cp -R "$LGH/engine/harness" "$LGC/felix/felix/9.0.0/harness"
mkdir -p "$LGU/.claude/plugins"; ln -s "$LGC" "$LGU/.claude/plugins/cache"

# A worktree of the home per pull request, on branch bN from main, with one
# commit touching the files named. Their heads are kept as N<TAB>sha.
: > "$LG/shas"
_lg_branch() {   # NAME FILE... -> prints the new head
  local f
  _fx_git "$LGH" worktree add -q -b "$1" "$LGW/$1" main >/dev/null 2>&1 || return 1
  for f in "${@:2}"; do mkdir -p "$(dirname "$LGW/$1/$f")"; printf '%s %s\n' "$1" "$f" >> "$LGW/$1/$f"; done
  _fx_git "$LGW/$1" add -A >/dev/null 2>&1
  _fx_git "$LGW/$1" -c user.name=t -c user.email=t@t commit -qm "$1" >/dev/null 2>&1
  git -C "$LGW/$1" rev-parse HEAD
}
_lg_more() {   # NAME FILE -> one more commit on worktree NAME; prints the new head
  printf 'more\n' >> "$LGW/$1/$2"
  _fx_git "$LGW/$1" add -A >/dev/null 2>&1
  _fx_git "$LGW/$1" -c user.name=t -c user.email=t@t commit -qm more >/dev/null 2>&1
  git -C "$LGW/$1" rev-parse HEAD
}
_lg_sha() { LC_ALL=C awk -F'\t' -v n="$1" '$1 == n { print $2 }' "$LG/shas"; }
for _lgn in 21 22 23 24 25 26 27 29 30 40 41 42 43; do
  printf '%s\t%s\n' "$_lgn" "$(_lg_branch "b$_lgn" "notes/b$_lgn.md")" >> "$LG/shas"
done
printf '28a\t%s\n' "$(_lg_branch b28 notes/b28.md)" >> "$LG/shas"
printf '28\t%s\n' "$(_lg_more b28 notes/b28.md)" >> "$LG/shas"
printf '31\t%s\n' "$(_lg_branch b31 notes/b31.md)" >> "$LG/shas"
_fx_git "$LGH" worktree remove --force "$LGW/b31" >/dev/null 2>&1
printf '32a\t%s\n' "$(_lg_branch b32 notes/b32.md)" >> "$LG/shas"
printf '32\t%s\n' "$(_lg_more b32 notes/b32.md)" >> "$LG/shas"
_fx_git "$LGW/b32" reset -q --hard "$(_lg_sha 32a)" >/dev/null 2>&1
printf '33\t%s\n' "$(_lg_branch b33 notes/b33.md)" >> "$LG/shas"
_fx_git "$LGW/b33" checkout -q --detach >/dev/null 2>&1
printf '34\t%s\n' "$(_lg_branch b34 projects/someone-else/CLAUDE.md)" >> "$LG/shas"
printf '35\t%s\n' "$(_lg_branch b35 docs/2026-10-15-roadmap.md)" >> "$LG/shas"
_lgn="$(LC_ALL=C awk -F'\t' '$2 ~ /^[0123456789abcdef]+$/ && length($2) == 40 { n++ } END { print n + 0 }' "$LG/shas")"
is "the land fixture: every pull request's head is a commit (fixture control)" "$_lgn" "21"

LGX=()
_lg_land() {   # ARGS -> felix land ARGS from the home; output in $LG/out, status in LGRC
  ( cd "$LGH" || exit 97
    exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE ${LGX[@]+"${LGX[@]}"} \
      HOME="$LGU" FELIX_HOME="$LGH" FELIX_HOME_DIR="$LGH" FELIX_MEMORY="$LGM" FELIX_PLUGIN_CACHE="$LGC" \
      PATH="$LGB:$PATH" "$FELIX" land "$@" ) > "$LG/out" 2>&1
  LGRC=$?
}
_lg_reset() {
  rm -rf "$LAND" "$LGL" "$LGK"; mkdir -p "$LGL" "$LGK"
  printf '[]\n' > "$LGK/prs.json"; printf 'README.md\n' > "$LGK/files.default"; LGX=()
}
_lg_rows() { if [ -f "$LAND/ledger.tsv" ]; then awk 'END { print NR }' "$LAND/ledger.tsv"; else echo 0; fi; }
_lg_cnt() { if [ -f "$LGL/$1.log" ]; then awk 'END { print NR }' "$LGL/$1.log"; else echo 0; fi; }
_lg_logs() { cat "$LGL/$1.log" 2>/dev/null; }
_lg_n() {   # EVENT [PR] -> how many ledger rows
  [ -f "$LAND/ledger.tsv" ] || { echo 0; return; }
  LC_ALL=C awk -F'\t' -v e="$1" -v p="${2-}" '$2 == e && (p == "" || $3 == p) { n++ } END { print n + 0 }' "$LAND/ledger.tsv"
}
_lg_f() {   # EVENT PR FIELD -> that field of the last such row (PR empty: any)
  [ -f "$LAND/ledger.tsv" ] || return 0
  LC_ALL=C awk -F'\t' -v e="$1" -v p="$2" -v k="$3" '$2 == e && (p == "" || $3 == p) { v = $k } END { printf "%s", v }' "$LAND/ledger.tsv"
}
_lg_lc() { printf '%s' "$1" | LC_ALL=C tr '[:upper:]' '[:lower:]'; }
_lg_merges() { [ -f "$LGL/felix.log" ] || return 0
  LC_ALL=C awk -F'\t' '$3 == "merge" || index($3, "merge ") == 1 { n = $2; sub(/.*\//, "", n); printf "%s%s", s, n; s = " " }' "$LGL/felix.log"; }
_lg_pr() {   # N [draft] [labels] [mergeable] [cross] [base] -> one pull request as gh lists it
  printf '{"number":%s,"headRefName":"b%s","headRefOid":"%s","isDraft":%s,"labels":%s,"mergeable":"%s","isCrossRepository":%s,"baseRefName":"%s"}' \
    "$1" "$1" "$(_lg_sha "$1")" "${2:-false}" "${3:-[]}" "${4:-MERGEABLE}" "${5:-false}" "${6:-main}"
}
_lg_prs() { local IFS=,; printf '[%s]\n' "$*" > "$LGK/prs.json"; }
_lg_green() { local n s; for n in "$@"; do s="$(_lg_sha "$n")"; printf 'completed\tsuccess\t%s\n' "$s" > "$LGK/runs.$s"; done; }
_lg_osa() { case "$(_lg_logs osa)" in *"$1"*) ok "$2" ;; *) bad "$2" "osascript was called with: $(_lg_logs osa | cut -f1 | head -8 | tr '\n' '|')" ;; esac; }
LGHOLD='[{"id":"L1","name":"felix:hold","description":"","color":"ededed"}]'
LGTAG='[{"id":"L2","name":"needs-review","description":"","color":"ededed"}]'

# --------------------------------------------------------------------- G1 ---
_lgt="$REAL_HARNESS/lib/green-tick.sh"
if [ -f "$_lgt" ]; then ok "G1: the tick lives in lib/green-tick.sh, outside the lib/land*.sh glob"
else bad "G1: the tick lives in lib/green-tick.sh, outside the lib/land*.sh glob" "no $_lgt"; fi
_lgn="$(awk 'END { print NR }' "$_lgt" 2>/dev/null)"
if [ -f "$_lgt" ] && [ "${_lgn:-0}" -lt 500 ]; then ok "G1: lib/green-tick.sh stays under 500 lines"
else bad "G1: lib/green-tick.sh stays under 500 lines" "it has [${_lgn:-no}] lines"; fi

# --------------------------------------------------------------------- G9 ---
_lg_reset
_lg_land; is "G9: felix land with no argument exits 2" "$LGRC" 2
has "G9: and prints a usage that names --tick" "$(cat "$LG/out")" "--tick"
_lg_land --sideways; is "G9: felix land with an unknown argument exits 2" "$LGRC" 2
has "G9: and prints a usage that names --tick" "$(cat "$LG/out")" "--tick"
_lg_land --tick --resume; is "G9: two commands at once is another argument, and exits 2" "$LGRC" 2
_lg_land --pause; is "G9: --pause exits 0" "$LGRC" 0
is "G9: --pause with no reason writes paused reading \"paused by hand\"" "$(cat "$LAND/paused" 2>/dev/null)" "paused by hand"
_lg_land --pause "the deploy window"
is "G9: --pause with a reason writes the reason into paused" "$(cat "$LAND/paused" 2>/dev/null)" "the deploy window"
_lg_land --resume; is "G9: --resume exits 0" "$LGRC" 0
[ -e "$LAND/paused" ] && bad "G9: --resume removes paused" "it is still there" || ok "G9: --resume removes paused"
_lg_reset; mkdir -p "$LAND"; printf 'held for the test\n' > "$LAND/paused"
{ printf '2026-10-15T00:00:00Z\tskip\t5\t%s\t-\t0\tdraft\n' "$(_lg_sha 21)"
  printf '2026-10-15T00:05:00Z\tsession\t5\t%s\t-\t1\tno checkout holds the gated head\n' "$(_lg_sha 21)"
  printf '2026-10-15T00:06:00Z\tlanded\t6\t%s\t%s\t3\tmerged\n' "$(_lg_sha 22)" "$LGW/b22"
  printf '2026-10-15T00:07:00Z\tpaused\t-\t-\t-\t0\theld for the test\n'; } > "$LAND/ledger.tsv"
_lgsnap() { ( cd "$LAND" 2>/dev/null && find . -exec cksum {} + 2>/dev/null | LC_ALL=C sort ); ls -la "$LGU/Library/LaunchAgents" 2>/dev/null; }
_lgs0="$(_lgsnap)"
_lg_land --status --tsv; _lgo="$(cat "$LG/out")"
is "G9: --status --tsv exits 0" "$LGRC" 0
is "G9: --status --tsv says installed no before --install, as key<TAB>value" "$(sed -n 1p "$LG/out")" "$(printf 'installed\tno')"
case "$(sed -n 2p "$LG/out")" in "$(printf 'loaded\t')"yes|"$(printf 'loaded\t')"no) ok "G9: --status --tsv's second line is loaded<TAB>yes or no" ;;
  *) bad "G9: --status --tsv's second line is loaded<TAB>yes or no" "[$(sed -n 2p "$LG/out")]" ;; esac
is "G9: --status --tsv says paused yes while paused exists" "$(sed -n 3p "$LG/out")" "$(printf 'paused\tyes')"
_lgr="$(sed -n '4,$p' "$LG/out")"
case "$_lgr" in *"$(sed -n 2p "$LAND/ledger.tsv")"*) ok "G9: --status --tsv prints a pull request's last ledger row as the ledger has it" ;;
  *) bad "G9: --status --tsv prints a pull request's last ledger row as the ledger has it" "[$_lgr]" ;; esac
case "$_lgr" in *"$(sed -n 3p "$LAND/ledger.tsv")"*) ok "G9: and the last row of every other pull request seen" ;;
  *) bad "G9: and the last row of every other pull request seen" "[$_lgr]" ;; esac
case "$_lgr" in *"$(sed -n 1p "$LAND/ledger.tsv")"*) bad "G9: and not a pull request's earlier rows" "[$_lgr]" ;;
  *) ok "G9: and not a pull request's earlier rows" ;; esac
_lg_land --status
_lgo="$(sed -n 1,3p "$LG/out" | LC_ALL=C awk '{ k = $1; gsub(/[^a-z]/, "", k); printf "%s %s|", k, $NF }')"
case "$_lgo" in "installed no|loaded "*"|paused yes|") ok "G9: plain --status prints installed, loaded and paused, each yes or no, first" ;;
  *) bad "G9: plain --status prints installed, loaded and paused, each yes or no, first" "[$_lgo]" ;; esac
is "G9: --status writes nothing: the land directory and LaunchAgents are as they were" "$(_lgsnap)" "$_lgs0"
is "G9: --status bootstraps and boots out nothing" "$(_lg_logs launchctl | grep -cE '^(bootstrap|bootout|load|unload)')" "0"

# --------------------------------------------------------------------- G2 ---
# The hour is aged by moving every row's time back: the current UTC year one
# earlier where the time holds it, or two hours where it is a bare epoch. The
# contract names no time format, so this is the least it could be read as.
_lg_age() {
  [ -f "$LAND/ledger.tsv" ] || return 0
  LC_ALL=C awk -F'\t' -v OFS='\t' -v y="$(date -u +%Y)" '
    { if (index($1, y)) sub(y, y - 1, $1); else if ($1 ~ /^[0123456789]+$/) $1 = $1 - 7200; print }' \
    "$LAND/ledger.tsv" > "$LAND/ledger.aged" && mv "$LAND/ledger.aged" "$LAND/ledger.tsv"
}
_lg_reset; mkdir -p "$LAND"; printf 'maintenance window\n' > "$LAND/paused"
_lg_prs "$(_lg_pr 42)"; _lg_green 42
_lg_land --tick
is "G2: a paused tick exits 0" "$LGRC" 0
is "G2: a paused tick, with no paused row yet, writes one paused row" "$(_lg_n paused)" 1
is "G2: and does nothing else: it asks gh nothing" "$(_lg_cnt gh)" 0
is "G2: and merges nothing" "$(_lg_merges)" ""
_lg_osa 'with title "Felix: paused' "G8: a paused row is also sent as a notification titled Felix: paused"
_lg_land --tick
is "G2: a second paused tick within the hour writes no row" "$(_lg_n paused)" 1
_lg_age; _lg_land --tick
is "G2: once the newest paused row is older than an hour, a paused tick writes one more" "$(_lg_n paused)" 2
[ -d "$LAND/lock" ] && bad "G2: a paused tick leaves no lock behind" "lock/ is there" || ok "G2: a paused tick leaves no lock behind"

_lg_reset; printf '1\n' > "$LGK/gh-auth.rc"; _lg_prs "$(_lg_pr 42)"; _lg_green 42
_lg_land --tick
is "G2: a tick whose gh auth status fails exits 0" "$LGRC" 0
is "G2: and writes one gh row" "$(_lg_n gh)" 1
is "G2: and lists no pull request" "$(_lg_logs gh | grep -c '^pr list')" "0"
is "G2: and merges nothing" "$(_lg_merges)" ""
is "G8: a row with no pull request has - for its number, head and worktree" \
   "$(_lg_f gh - 3)|$(_lg_f gh - 4)|$(_lg_f gh - 5)" "-|-|-"

# The live lock is the tick's own: one tick is held inside gh auth status, and
# what it wrote under lock/ is read while it waits. The started line's format
# is the implementation's, so the dead-lock cases reuse the one it wrote.
_lg_reset; : > "$LGK/gh-block"
[ "$SECONDS" -ge 3 ] || sleep 3
( cd "$LGH" || exit 97
  exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE HOME="$LGU" FELIX_HOME="$LGH" \
    FELIX_HOME_DIR="$LGH" FELIX_MEMORY="$LGM" FELIX_PLUGIN_CACHE="$LGC" PATH="$LGB:$PATH" \
    "$FELIX" land --tick ) > "$LG/out.bg" 2>&1 &
LGBG=$!
_lgi=0
while [ "$_lgi" -lt 80 ]; do
  { [ -s "$LAND/lock/pid" ] && [ -s "$LAND/lock/started" ] && [ -d "$LGK/gh-block-taken" ]; } && break
  kill -0 "$LGBG" 2>/dev/null || break
  sleep 0.1; _lgi=$((_lgi+1))
done
LGPID="$(cat "$LAND/lock/pid" 2>/dev/null)"; LGSTART="$(cat "$LAND/lock/started" 2>/dev/null)"
if [ -n "$LGPID" ] && [ -n "$LGSTART" ] && kill -0 "$LGPID" 2>/dev/null; then
  ok "G2: a running tick holds lock/ with the pid of a live process and its started line"
else bad "G2: a running tick holds lock/ with the pid of a live process and its started line" "pid [$LGPID] started [$LGSTART]"; fi
_lg_land --tick
is "G2: a tick that finds the lock held by a live tick exits 0" "$LGRC" 0
is "G2: and writes no row" "$(_lg_rows)" "0"
is "G2: and does not ask gh anything" "$(_lg_logs gh | grep -c '^auth status')" "1"
kill -TERM "$LGBG" 2>/dev/null; rm -f "$LGK/gh-block"; wait "$LGBG" 2>/dev/null
if [ -z "$LGPID" ]; then bad "G2: a tick ended by TERM still releases its lock, through its trap" "no lock was seen to release"
elif [ -d "$LAND/lock" ]; then bad "G2: a tick ended by TERM still releases its lock, through its trap" "lock/ is left"
else ok "G2: a tick ended by TERM still releases its lock, through its trap"; fi
sh -c 'exit 0' & _lgdead=$!; wait "$_lgdead"
_lg_reset; mkdir -p "$LAND/lock"; printf '%s\n' "$_lgdead" > "$LAND/lock/pid"; printf '%s\n' "$LGSTART" > "$LAND/lock/started"
_lg_land --tick
is "G2: a lock whose pid is dead is taken: the tick goes on to ask gh" "$(_lg_logs gh | grep -c '^auth status')" "1"
[ -d "$LAND/lock" ] && bad "G2: and released when the tick ends" "lock/ is left" || ok "G2: and released when the tick ends"
_lg_reset; mkdir -p "$LAND/lock"; printf '%s\n' "$$" > "$LAND/lock/pid"; printf '%s\n' "$LGSTART" > "$LAND/lock/started"
_lg_land --tick
is "G2: a lock whose pid is alive but started at another time is dead, and taken" "$(_lg_logs gh | grep -c '^auth status')" "1"
[ -d "$LAND/lock" ] && bad "G2: and released when the tick ends" "lock/ is left" || ok "G2: and released when the tick ends"

# ------------------------------------------------------- G4, G5, G6, G8 ---
# One tick over every kind of pull request, listed by gh in descending order:
# 21-30 each fail one check of G4; 31-33 have no worktree at their head; 34 and
# 35 touch a direction document; felix merge refuses 40 and 41; 42 lands; 43
# would land and must not be tried. The caller exports the three variables
# felix merge must not see. 41's worktree holds an untracked file and 42's a
# tripwire felix, so a tick that cleans, resets or runs a worktree's engine
# shows it.
_lg_filter_runs() {
  _lg_green 21 22 23 24 28a
  printf 'in_progress\t-\t%s\n' "$(_lg_sha 25)" > "$LGK/runs.$(_lg_sha 25)"
  printf 'completed\tfailure\t%s\n' "$(_lg_sha 26)" > "$LGK/runs.$(_lg_sha 26)"
  printf 'completed\tfailure\t%s\ncompleted\tsuccess\t%s\n' "$(_lg_sha 29)" "$(_lg_sha 29)" > "$LGK/runs.$(_lg_sha 29)"
  printf '1\n' > "$LGK/runs.$(_lg_sha 30).rc"
}
_lg_filter_prs() {   # [object for 21] -> the ten pull requests that fail one check each
  printf '%s\n' "$(_lg_pr 30)" "$(_lg_pr 29)" "$(_lg_pr 28)" "$(_lg_pr 27)" "$(_lg_pr 26)" "$(_lg_pr 25)" \
    "$(_lg_pr 24 false '[]' CONFLICTING)" "$(_lg_pr 23 false '[]' MERGEABLE true)" "$(_lg_pr 22 false "$LGHOLD")" \
    "${1:-$(_lg_pr 21 true)}" | LC_ALL=C awk '{ printf "%s%s", s, $0; s = "," }'
}
_lg_reset; _lg_filter_runs; _lg_green 31 32 33 34 35 40 41 42 43
printf 'projects/someone-else/CLAUDE.md\n' > "$LGK/files.34"; printf 'docs/2026-10-15-roadmap.md\n' > "$LGK/files.35"
printf 'felix merge: refused\nno blocker on this one\nfinal words of forty\n' > "$LGK/merge.b40.out"; printf '1\n' > "$LGK/merge.b40.rc"
printf 'felix merge: refused\n  blocker\tone: the receipt is stale\n  second blocker\nlast words of forty-one\n' > "$LGK/merge.b41.out"
printf '1\n' > "$LGK/merge.b41.rc"; printf 'merged\n' > "$LGK/merge.b42.out"
printf 'scratch\n' > "$LGW/b41/untracked-scratch.txt"
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s/trip.log"\nexit 0\n' "$LGL" > "$LGW/b42/engine/harness/felix"
_lg_prs "$(_lg_pr 43 false "$LGTAG")" "$(_lg_pr 42 false '[]' UNKNOWN)" "$(_lg_pr 41)" "$(_lg_pr 40)" \
  "$(_lg_pr 35)" "$(_lg_pr 34)" "$(_lg_pr 33)" "$(_lg_pr 32)" "$(_lg_pr 31)" "$(_lg_filter_prs)"
# Fixture controls: the gh stub answers rule C9's own function as the contract
# reads it, and git's worktree list holds the shapes G5 names.
_lgo=""
for _lgk in 21 22 23 24 25 26 27 28 29 30 40 41 42; do
  ( PATH="$LGB:$PATH"; . "$FROOT/harness/lib/escape.sh" 2>/dev/null
    _felix_merge_gate_held "$LGH/projects/lgh" "$LGW/b$_lgk" "$(_lg_sha "$_lgk")" >/dev/null 2>&1 ) && _lgo="$_lgo $_lgk"
done
is "the land fixture: C9's own function passes the gate of 21-24 and 40-42 and of none of 25-30 (fixture control)" \
   "$_lgo" " 21 22 23 24 40 41 42"
if command -v jq >/dev/null 2>&1; then
  is "the land fixture: the gh stub lists the pull requests and honours --jq (fixture control)" \
     "$(PATH="$LGB:$PATH" gh pr list --state open --json number --jq '.[].number' | LC_ALL=C sort -n | tr '\n' ' ')" \
     "21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 40 41 42 43 "
else skip "the land fixture: the gh stub lists the pull requests and honours --jq (fixture control)" "no jq"; fi
_lgo="$(git -C "$LGH" worktree list --porcelain | LC_ALL=C awk -v w="$LGW/" '
  /^worktree / { p = substr($0, 10); sub(/.*\//, "", p); h = ""; b = "" }
  /^HEAD / { h = $2 } /^branch / { b = $2 } /^detached/ { b = "detached" }
  /^$/ { if (p ~ /^b3[123]$/) printf "%s:%s:%s ", p, substr(h, 1, 7), b; p = "" }
  END { if (p ~ /^b3[123]$/) printf "%s:%s:%s ", p, substr(h, 1, 7), b }')"
is "the land fixture: no worktree holds b31, b32 sits behind its head, b33 is detached at it (fixture control)" "$_lgo" \
   "b32:$(_lg_sha 32a | cut -c1-7):refs/heads/b32 b33:$(_lg_sha 33 | cut -c1-7):detached "
: > "$LGL/gh.log"
_lg_wsnap() { local w
  for w in "$LGW"/*; do [ -d "$w" ] || continue
    printf '== %s %s %s\n' "${w##*/}" "$(git -C "$w" rev-parse HEAD 2>&1)" "$(git -C "$w" rev-parse --abbrev-ref HEAD 2>&1)"
    git -C "$w" status --porcelain 2>&1
    ( cd "$w" && find . -path ./.git -prune -o -type f -exec cksum {} + | LC_ALL=C sort )
  done
  git -C "$LGO" for-each-ref 2>&1; }
_lgw0="$(_lg_wsnap)"
LGX=(FELIX_ALLOW_RED=1 FELIX_KERNEL=/nonexistent/kernel "FELIX_KERNEL_CACHE=$LGC/felix/felix")
_lg_land --tick; LGX=()
is "G4: a tick over open pull requests exits 0" "$LGRC" 0
is "G4: it lists them with one gh pr list call" "$(_lg_logs gh | grep -c '^pr list')" "1"
_lgo="$(_lg_logs gh | grep '^pr list' | head -1)"
for _lgk in "--state open" number headRefName headRefOid isDraft labels mergeable isCrossRepository; do
  has "G4: the gh pr list call carries $_lgk" "$_lgo" "$_lgk"
done
_lg_skip() {   # N WORD WHAT -> one skip row for N, its detail naming the check by WORD
  is "G4: $3 is skipped with one skip row" "$(_lg_n skip "$1")" "1"
  [ -z "$2" ] || has "G4: and the skip row for $3 names the check" "$(_lg_lc "$(_lg_f skip "$1" 7)")" "$2"
}
_lg_skip 21 draft "a draft"
_lg_skip 22 "felix:hold" "a pull request labelled felix:hold"
_lg_skip 23 cross "a cross-repository pull request"
_lg_skip 24 conflict "a CONFLICTING pull request"
_lg_skip 25 "" "a pull request whose gate run has not completed"
_lg_skip 26 "" "a pull request whose gate run failed"
_lg_skip 27 "" "a pull request with no gate run on its head"
_lg_skip 28 "" "a pull request green only on an older head"
_lg_skip 29 "" "a pull request whose newest run failed after an older one passed"
_lg_skip 30 "" "a pull request whose gh run list fails"
is "G4, G6: felix merge is tried in ascending order, 40 and 41 refused, 42 landed, and nothing after the first landing" \
   "$(_lg_merges)" "b40 b41 b42"
has "G5: a pull request whose branch no worktree holds gets a session row reading no checkout holds the gated head" "$(_lg_f session 31 7)" "no checkout holds the gated head"
has "G5: so does one whose worktree is on the branch at another head" "$(_lg_f session 32 7)" "no checkout holds the gated head"
has "G5: so does one whose worktree is at the head but not on its branch" "$(_lg_f session 33 7)" "no checkout holds the gated head"
is "G5: a pull request touching another project's projects/*/CLAUDE.md is held with a founder row" "$(_lg_n founder 34)" "1"
is "G5: a pull request touching docs/*roadmap* is held with a founder row" "$(_lg_n founder 35)" "1"
is "G5: no worktree is checked out, reset, cleaned or written, and origin's refs did not move" "$(_lg_wsnap)" "$_lgw0"
is "G6: exit 0 from felix merge writes one landed row" "$(_lg_n landed 42)" "1"
is "G6: and 43, after the landing, is never tried" "$(_lg_n landed 43)$(_lg_n refused 43)" "00"
is "G6: each refusal writes a refused row" "$(_lg_n refused 40)$(_lg_n refused 41)" "11"
has "G6, G8: a refused row's detail is the first output line that begins with two spaces, its tab made a space" \
    "$(_lg_f refused 41 7)" "blocker one: the receipt is stale"
case "$(_lg_f refused 41 7)" in *"second blocker"*|*"last words"*) bad "G6: and only that line" "[$(_lg_f refused 41 7)]" ;;
  *) ok "G6: and only that line" ;; esac
has "G6: with no such line, the detail is the output's last line" "$(_lg_f refused 40 7)" "final words of forty"
_lgml="$(LC_ALL=C awk -F'\t' '$3 == "merge" || index($3, "merge ") == 1' "$LGL/felix.log" 2>/dev/null)"
_lgm() { printf '%s\n' "$_lgml" | LC_ALL=C awk -F'\t' -v k="$1" 'NF { printf "%s%s", s, $k; s = " " }'; }
is "G6: every felix merge run is the installed engine's, at main's version in the cache" "$(_lgm 1)" "$LGE $LGE $LGE"
is "G6: each runs in the matched worktree" "$(_lgm 2)" "$LGW/b40 $LGW/b41 $LGW/b42"
is "G6: each with no argument but merge" "$(_lgm 3)" "merge merge merge"
is "G6: with FELIX_ALLOW_RED, FELIX_KERNEL and FELIX_KERNEL_CACHE unset though the caller exported them" \
   "$(_lgm 4) $(_lgm 5) $(_lgm 6)" "unset unset unset unset unset unset unset unset unset"
is "G6: no worktree's engine/harness/felix ever runs" \
   "$(_lg_logs felix | LC_ALL=C awk -F'\t' -v w="$LGW/" 'index($1, w) == 1' | wc -l | tr -d ' ')$(_lg_cnt trip)" "00"
is "G6: the tick writes no label, comment, review or merge through gh" \
   "$(_lg_logs gh | grep -cE '^(pr (merge|comment|edit|review|close|ready)|label|api|issue)')" "0"
is "G7: a landing that changes no engine/ path deploys nothing" \
   "$(_lg_logs felix | LC_ALL=C awk -F'\t' 'index($3, "install") == 1' | wc -l | tr -d ' ')$(_lg_n deployed)" "00"
_lgo="$(LC_ALL=C awk -F'\t' 'NF != 7' "$LAND/ledger.tsv" 2>/dev/null | wc -l | tr -d ' ')"
[ "$(_lg_rows)" -gt 0 ] && [ "$_lgo" = 0 ] && ok "G8: every ledger line is one row of seven tab-separated fields" \
  || bad "G8: every ledger line is one row of seven tab-separated fields" "$(_lg_rows) rows, $_lgo of another shape"
is "G4: rows are written in ascending pull request order" \
   "$(LC_ALL=C awk -F'\t' '$3 != "-" { if ($3 + 0 < l) b = 1; l = $3 + 0 } END { print b + 0 }' "$LAND/ledger.tsv" 2>/dev/null)" "0"
_lgo="$(_lg_f landed 42 4)"
case "$(_lg_sha 42)" in "$_lgo"*) [ "${#_lgo}" -ge 7 ] && ok "G8: the landed row carries the head SHA" || bad "G8: the landed row carries the head SHA" "[$_lgo]" ;;
  *) bad "G8: the landed row carries the head SHA" "[$_lgo]" ;; esac
is "G8: and the worktree path" "$(cd -P "$(_lg_f landed 42 5)" 2>/dev/null && pwd -P)" "$LGW/b42"
case "$(_lg_f landed 42 6)" in ""|*[!0123456789.]*) bad "G8: and wall seconds as a number" "[$(_lg_f landed 42 6)]" ;; *) ok "G8: and wall seconds as a number" ;; esac
case "$(_lg_f landed 42 1)" in ""|-) bad "G8: and a UTC time" "[$(_lg_f landed 42 1)]" ;; *) ok "G8: and a UTC time" ;; esac
_lg_osa '-e display notification "' "G8: a notification is one osascript -e display notification"
_lg_osa 'with title "Felix: landed #42"' "G8: the landed row is sent titled Felix: landed #42"
_lg_osa 'with title "Felix: refused #41"' "G8: a refused row is sent titled Felix: refused #41"
_lg_osa 'with title "Felix: founder #34"' "G8: a founder row is sent titled Felix: founder #34"
is "G8: one notification per row" "$(_lg_logs osa | grep -c 'Felix: landed #42')" "1"
[ -d "$LAND/lock" ] && bad "G2: the lock is released when the tick ends" "lock/ is left" || ok "G2: the lock is released when the tick ends"

_lg_reset; _lg_filter_runs; _lg_prs "$(_lg_filter_prs)"
_lg_land --tick; _lg_land --tick
is "G4: a second tick over the same waiting pull requests writes no new skip row" "$(_lg_n skip)" "10"
_lg_prs "$(_lg_filter_prs "$(_lg_pr 21 false "$LGHOLD")")"; _lg_land --tick
is "G4: a pull request whose failing check changed gets one new skip row" "$(_lg_n skip 21)" "2"
is "G4: and the others none" "$(_lg_n skip)" "11"

_lg_reset; printf '1\n' > "$LGK/osa.rc"; _lg_prs "$(_lg_pr 42)"; _lg_green 42; _lg_land --tick
is "G8: a failing osascript is ignored: the tick exits 0" "$LGRC" 0
is "G8: and the landed row stands" "$(_lg_n landed 42)" "1"
case "$(_lg_logs osa | grep 'Felix: landed #42' | head -1 | cut -f2)" in *"|landed|42|"*) ok "G8: the ledger row is written before its notification" ;;
  *) bad "G8: the ledger row is written before its notification" "$(_lg_logs osa | head -2)" ;; esac
_lg_reset; _lg_land --pause "$(printf 'first line\nsecond\tpart')"; _lg_land --tick
_lgo="$(LC_ALL=C awk -F'\t' 'NF != 7' "$LAND/ledger.tsv" 2>/dev/null | wc -l | tr -d ' ')"
[ "$(_lg_rows)" -eq 1 ] && [ "$_lgo" = 0 ] && ok "G8: a detail holding a newline and a tab is written as one row of seven fields" \
  || bad "G8: a detail holding a newline and a tab is written as one row of seven fields" "$(_lg_rows) lines, $_lgo of another shape"
