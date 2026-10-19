# >>> stuck-pr-page-amendments
printf '\nthe stuck-PR page: amendments R1-R6, the default branch with no checkout, one billing call, the origin row, how old main is, the repo cell, one repository read once (spec v2, blind)\n'
# Blind, written on 2026-10-17 from spec v2 and its section "Amended after
# review, 2026-10-17" (audits/2026-10-01-report-v5-review/specs/stuck-pr/
# spec-v2.md), without reading lib/pr-status*.sh or felix_land. Parts 1300 and
# 1330 were read only for how their fixture and stubs are built. Self-contained
# after the preamble: it builds its own fixture under $TMP and removes it.
#
# The fixture: a bare origin whose path ends github.com/fixture/home.git and a
# clone of it that is also the Felix home. The home holds projects felix
# (remote_match github.com/fixture/home), two (github.com/fixture/two, cloned
# nowhere), three (github.com/fixture/three, a clone with no origin/main and
# no origin/HEAD) and zeta (Fixture/Home: the home's repository again, in
# another case and without the host). gh and launchctl are stubs first on PATH,
# each logging its argv. gh answers pr list from ctl/prs.<key>.json, the key
# being the repository from -R or --repo, else from the origin of the directory
# it runs in, lowercased, with every byte but a letter or digit made _ (GitHub
# folds case). It answers a GET of repos/<owner>/<name> with the default branch
# in ctl/dflt.<key>, else main, and the billing GETs of users/ and orgs/ as
# ctl/bill.users.* and ctl/bill.orgs.* say, else with minutes.
SA="$TMP/stuck-pr-amend"; mkdir -p "$SA"; SA="$(cd "$SA" && pwd -P)"
SAO="$SA/github.com/fixture/home.git"; SAH="$SA/home"; SA3O="$SA/github.com/fixture/three.git"; SA3="$SA/three"
SAM="$SA/mem"; SAU="$SA/user"; SAB="$SA/bin"; SAK="$SA/ctl"; SAL="$SA/log"; SAX="$SA/out"; SAT="$SA/tmp"
SATAB="$(printf '\t')"
mkdir -p "$SAO" "$SA3O" "$SAM" "$SAU/.config/gh" "$SAB" "$SAK" "$SAL" "$SAX" "$SAT" "$SA/cache"
_sa_put() { mkdir -p "$(dirname "$1")" && LC_ALL=C sed "s#@SA@#$SA#g" > "$1" && chmod +x "$1"; }
_sa_put "$SAB/gh" <<'SASTUB'
#!/bin/bash
SA='@SA@'; K="$SA/ctl"
printf '%s\n' "$*" >> "$SA/log/gh.log"
jqx=""; repo=""; prev=""; bill=""; rget=""
for a in "$@"; do
  case "$prev" in -q|--jq) jqx="$a" ;; -R|--repo) repo="$a" ;; esac
  case "$a" in --jq=*) jqx="${a#--jq=}" ;; --repo=*) repo="${a#--repo=}" ;; esac
  case "$a" in
    *users/*/settings/billing/actions*) bill=users ;;
    *orgs/*/settings/billing/actions*) bill=orgs ;;
    repos/*|/repos/*) rget="${a#/}"; rget="${rget#repos/}" ;;
  esac
  prev="$a"
done
key() { printf '%s' "$1" | LC_ALL=C tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz' | LC_ALL=C tr -c 'abcdefghijklmnopqrstuvwxyz0123456789' '_'; }
out() { if [ -n "$jqx" ] && command -v jq >/dev/null 2>&1; then jq -r "$jqx"; else cat; fi; }
if [ "${1:-} ${2:-}" = "pr list" ]; then
  if [ -z "$repo" ]; then
    u="$(git config --get remote.origin.url 2>/dev/null)"; u="${u%/}"; u="${u%.git}"
    n="${u##*/}"; o="${u%/*}"; o="${o##*/}"; [ -n "$n" ] && [ -n "$o" ] && repo="$o/$n"
  fi
  repo="${repo#https://}"; repo="${repo#github.com/}"; repo="${repo%.git}"
  k="$(key "$repo")"
  [ -f "$K/prs.$k.json" ] || { printf 'stub: no answer for repository [%s]\n' "$repo" >&2; exit 4; }
  out < "$K/prs.$k.json"; exit 0
fi
if [ "${1:-}" = api ]; then
  if [ -n "$bill" ]; then
    if [ -f "$K/bill.$bill.rc" ]; then
      [ -f "$K/bill.$bill.out" ] && cat "$K/bill.$bill.out"
      cat "$K/bill.$bill.err" >&2; exit "$(cat "$K/bill.$bill.rc")"
    fi
    printf '{"total_minutes_used":77,"total_paid_minutes_used":0,"included_minutes":2000}\n' | out; exit 0
  fi
  if [ -n "$rget" ]; then
    k="$(key "$rget")"; d=main; [ -f "$K/dflt.$k" ] && d="$(cat "$K/dflt.$k")"
    printf '{"full_name":"%s","default_branch":"%s"}\n' "$rget" "$d" | out; exit 0
  fi
  printf 'gh: Not Found (HTTP 404)\n' >&2; exit 1
fi
printf 'stub: gh %s is not served\n' "$*" >&2
exit 1
SASTUB
_sa_put "$SAB/launchctl" <<'SASTUB'
#!/bin/bash
printf '%s\n' "$*" >> '@SA@/log/launchctl.log'
case "${1:-}" in print) exit 113 ;; esac
exit 0
SASTUB

# ---- the repositories ----------------------------------------------------------
_sa_commit() { _fx_git "$1" add -A >/dev/null 2>&1; _fx_git "$1" -c user.name=t -c user.email=t@t commit -qm "$2" >/dev/null 2>&1; }
_sa_proj() { mkdir -p "$SAH/projects/$1"; printf '{\n  "name": "%s",\n  "remote_match": "%s",\n  "gate": "true"\n}\n' "$1" "$2" > "$SAH/projects/$1/project.json"; printf '# %s\n' "$1" > "$SAH/projects/$1/CLAUDE.md"; }
for _sao in "$SAO" "$SA3O"; do
  _fx_git "$_sao" init -q --bare >/dev/null 2>&1
  _fx_git "$_sao" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
done
_fx_git "$SA" clone -q "$SAO" home >/dev/null 2>&1
_fx_git "$SAH" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
_sa_proj felix github.com/fixture/home; _sa_proj two github.com/fixture/two
_sa_proj three github.com/fixture/three; _sa_proj zeta Fixture/Home
mkdir -p "$SAH/notes"; printf 'home\n' > "$SAH/README.md"; printf 'keep\n' > "$SAH/notes/keep.md"
_sa_commit "$SAH" base
_fx_git "$SAH" push -q -u origin main >/dev/null 2>&1
_fx_git "$SAH" fetch -q origin >/dev/null 2>&1
_fx_git "$SAH" remote set-head origin main >/dev/null 2>&1
_fx_git "$SA" clone -q "$SA3O" three >/dev/null 2>&1
_fx_git "$SA3" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
printf 'three\n' > "$SA3/README.md"; _sa_commit "$SA3" base

# ---- pull requests as gh lists them --------------------------------------------
_sa_sha() { printf '%04d%s' "$1" c0ffeec0ffeec0ffeec0ffeec0ffeec0ffee; }
SA_UPD="$(date -u -r "$(( $(date +%s) - 7200 ))" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$(( $(date +%s) - 7200 ))" +%Y-%m-%dT%H:%M:%SZ)"
SA_GREEN='[{"__typename":"CheckRun","name":"gate","workflowName":"gate","status":"COMPLETED","conclusion":"SUCCESS"}]'
_sa_pr() {   # N BASE [LABEL]: green, MERGEABLE, not a draft, its own head branch, one plain path
  local lb=""; [ -z "${3:-}" ] || lb="{\"name\":\"$3\"}"
  printf '{"number":%s,"title":"Change %s","headRefName":"b%s","headRefOid":"%s","baseRefName":"%s","isDraft":false,"isCrossRepository":false,' "$1" "$1" "$1" "$(_sa_sha "$1")" "$2"
  printf '"author":{"login":"fixture"},"labels":[%s],"mergeable":"MERGEABLE","mergeStateStatus":"CLEAN","statusCheckRollup":%s,' "$lb" "$SA_GREEN"
  printf '"files":[{"path":"notes/%s.md","additions":1,"deletions":0}],"updatedAt":"%s"}' "$1" "$SA_UPD"
}
_sa_prs() { local k="$1" s="" o; shift; { printf '['; for o in "$@"; do printf '%s%s' "$s" "$o"; s=","; done; printf ']\n'; } > "$SAK/prs.$k.json"; }
_sa_prs fixture_home "$(_sa_pr 501 main)" "$(_sa_pr 502 trunk)" "$(_sa_pr 601 main needs-founder)" "$(_sa_pr 602 main Felix:Founder)" "$(_sa_pr 603 main)"
_sa_prs fixture_two "$(_sa_pr 701 trunk needs-founder)" "$(_sa_pr 702 main needs-founder)"
printf 'trunk\n' > "$SAK/dflt.fixture_two"
_sa_prs fixture_three "$(_sa_pr 901 main)"
_sa_prs fixture_ta_by "$(_sa_pr 801 main needs-founder)"

# ---- running the page and reading it --------------------------------------------
_sa_land() {   # ARGS... in the home; stdout to out/out, status in SARC; the gh log starts empty
  rm -rf "$SAL"; mkdir -p "$SAL"
  ( cd "$SAH" || exit 97
    exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE -u CLAUDE_CODE_SESSION_ID \
      HOME="$SAU" FELIX_HOME="$SAH" FELIX_HOME_DIR="$SAH" FELIX_MEMORY="$SAM" FELIX_PLUGIN_CACHE="$SA/cache" \
      GH_CONFIG_DIR="$SAU/.config/gh" TMPDIR="$SAT" PATH="$SAB:$PATH" "$FELIX" land "$@" ) > "$SAX/out" 2> "$SAX/err"
  SARC=$?
}
_sa_keep() { cp "$SAX/out" "$SAX/$1"; printf '%s\n' "$SARC" > "$SAX/$1.rc"; [ -f "$SAL/gh.log" ] && cp "$SAL/gh.log" "$SAX/$1.gh" || : > "$SAX/$1.gh"; }
_sa_row()   { LC_ALL=C awk -F'\t' -v r="#$2" '$1 == "pr" && $3 == r' "$1" 2>/dev/null; }
_sa_nrow()  { _sa_row "$1" "$2" | LC_ALL=C awk 'END { print NR }'; }
_sa_f()     { _sa_row "$1" "$2" | LC_ALL=C awk -F'\t' -v k="$3" 'NR == 1 { printf "%s", $k }'; }
_sa_state() { _sa_f "$1" "$2" 4 | LC_ALL=C sed 's/,.*//'; }
_sa_srcf()  { LC_ALL=C awk -F'\t' -v r="$2" -v k="$3" '$1 == "source" && $3 == r { printf "%s", $k; exit }' "$1" 2>/dev/null; }
_sa_lacks() { case "$2" in *"$3"*) bad "$1" "[$2] holds [$3]" ;; *) ok "$1" ;; esac; }
_sa_cols()  { LC_ALL=C awk -F'\t' 'NF != 8 { print NR ": " NF " columns" }' "$1" | head -3; [ -s "$1" ] || echo empty; }
# Lines of a gh log: api calls naming a word W exactly, with or without its
# leading slash; and api calls holding a substring S.
_sa_apiw() { LC_ALL=C awk -v w="$2" '$1 == "api" { for (i = 2; i <= NF; i++) if ($i == w || $i == "/" w) { n++; break } } END { print n + 0 }' "$1" 2>/dev/null; }
_sa_apis() { LC_ALL=C awk -v s="$2" '$1 == "api" && index($0, s) { n++ } END { print n + 0 }' "$1" 2>/dev/null; }
# The age in "origin/main last moved <age> ago", and that age in whole hours:
# the first number and the unit after it (s, m, h, d, w, mo, y, or the words).
_sa_moved() { printf '%s' "$1" | LC_ALL=C awk '{ i = index($0, "origin/main last moved "); if (!i) exit
  r = substr($0, i + 23); j = index(r, " ago"); if (j) printf "%s", substr(r, 1, j - 1) }'; }
_sa_hours() { printf '%s' "$1" | LC_ALL=C awk '{ if (!match($0, /[0123456789]+/)) { print "unparsed"; exit }
  n = substr($0, RSTART, RLENGTH) + 0; u = tolower(substr($0, RSTART + RLENGTH)); sub(/^ +/, "", u)
  c = substr(u, 1, 1); c2 = substr(u, 1, 2)
  if (c2 == "mo") h = n * 720; else if (c == "s") h = n / 3600; else if (c == "m") h = n / 60
  else if (c == "h") h = n; else if (c == "d") h = n * 24; else if (c == "w") h = n * 168; else if (c == "y") h = n * 8760
  else { print "unparsed"; exit }
  print int(h) }'; }
_sa_ge() { case "$2" in ''|*[!0123456789]*) bad "$1" "no age in hours: [$2] from [$4]" ;; *) [ "$2" -ge "$3" ] && ok "$1" || bad "$1" "age $2 h is under $3 h: [$4]" ;; esac; }
_sa_lt() { case "$2" in ''|*[!0123456789]*) bad "$1" "no age in hours: [$2] from [$4]" ;; *) [ "$2" -lt "$3" ] && ok "$1" || bad "$1" "age $2 h is not under $3 h: [$4]" ;; esac; }

# ---- fixture controls ------------------------------------------------------------
is "the amendments fixture: origin/HEAD names main, and three has no origin/main and no origin/HEAD (fixture control)" \
   "$(git -C "$SAH" symbolic-ref -q refs/remotes/origin/HEAD 2>&1)|$(git -C "$SA3" rev-parse -q --verify refs/remotes/origin/main 2>/dev/null)|$(git -C "$SA3" symbolic-ref -q refs/remotes/origin/HEAD 2>/dev/null)" \
   "refs/remotes/origin/main||"
is "the amendments fixture: no checkout of fixture/two exists under the fixture (fixture control)" \
   "$(find "$SA" -name config -path '*.git*' -exec grep -l 'fixture/two' {} + 2>/dev/null)" ""
is "the amendments fixture: the gh stub answers -R Fixture/Home as fixture/home, and repos/fixture/two with trunk (fixture control)" \
   "$( cd "$SA" && PATH="$SAB:$PATH" gh pr list -R Fixture/Home --state open 2>&1 | LC_ALL=C grep -o '"number":601,' )|$( cd "$SA" && PATH="$SAB:$PATH" gh api repos/fixture/two 2>&1 | LC_ALL=C grep -o '"default_branch":"[a-z]*"' )" \
   '"number":601,|"default_branch":"trunk"'

# ---- R3: the origin row names the default branch and where it came from ----------
_sa_land --prs --tsv; _sa_keep r3head.tsv
T="$SAX/r3head.tsv"
is "R3: the page with origin/HEAD naming main exits 0" "$(cat "$T.rc")" 0
has "R3: origin/HEAD names main: the origin row says default branch main (origin/HEAD)" "$(_sa_srcf "$T" origin 8)" "default branch main (origin/HEAD)"
_sa_lacks "R3: and does not say the default branch is not read" "$(_sa_srcf "$T" origin 8)" "not read"
is "R3: and a plain green pull request into main was decided: #501 is ready (control)" "$(_sa_state "$T" 501)" ready
is "R3: and one into trunk is stacked (control)" "$(_sa_state "$T" 502)" stacked
_fx_git "$SAH" remote set-head origin -d >/dev/null 2>&1
is "the amendments fixture: origin/HEAD is gone and origin/main stays (fixture control)" \
   "$(git -C "$SAH" symbolic-ref -q refs/remotes/origin/HEAD 2>/dev/null)|$(git -C "$SAH" rev-parse -q --verify refs/remotes/origin/main >/dev/null 2>&1 && echo main)" "|main"
_sa_land --prs --tsv; _sa_keep r3main.tsv
T="$SAX/r3main.tsv"
is "R3: the page with origin/main alone exits 0" "$(cat "$T.rc")" 0
has "R3: origin/main alone: the origin row says default branch main (origin/main)" "$(_sa_srcf "$T" origin 8)" "default branch main (origin/main)"
_sa_lacks "R3: and does not say the default branch is not read" "$(_sa_srcf "$T" origin 8)" "not read"
_sa_lacks "R3: and does not credit origin/HEAD" "$(_sa_srcf "$T" origin 8)" "(origin/HEAD)"
is "R3: and #501 into main was decided against it: ready (control)" "$(_sa_state "$T" 501)" ready
is "R3: and #502 into trunk is stacked (control)" "$(_sa_state "$T" 502)" stacked
_fx_git "$SAH" push -q origin main:refs/heads/trunk >/dev/null 2>&1
_fx_git "$SAH" fetch -q origin >/dev/null 2>&1
_fx_git "$SAH" remote set-head origin trunk >/dev/null 2>&1
is "the amendments fixture: origin/HEAD now names trunk (fixture control)" "$(git -C "$SAH" symbolic-ref -q refs/remotes/origin/HEAD 2>&1)" refs/remotes/origin/trunk
_sa_land --prs --tsv; _sa_keep r3trunk.tsv
T="$SAX/r3trunk.tsv"
has "R3: origin/HEAD naming trunk: the origin row says default branch trunk (origin/HEAD)" "$(_sa_srcf "$T" origin 8)" "default branch trunk (origin/HEAD)"
_sa_lacks "R3: and does not say the default branch is not read" "$(_sa_srcf "$T" origin 8)" "not read"
is "R3: origin/HEAD wins over origin/main: #502 into trunk is ready" "$(_sa_state "$T" 502)" ready
is "R3: and #501 into main is stacked" "$(_sa_state "$T" 501)" stacked
_fx_git "$SAH" remote set-head origin main >/dev/null 2>&1
_sa_land --prs --tsv --repo "$SA3"; _sa_keep r3none.tsv
T="$SAX/r3none.tsv"
is "R3: a repository with neither origin/HEAD nor origin/main: the page exits 0 (control)" "$(cat "$T.rc")" 0
has "R3: and its origin row says default branch not read (control)" "$(_sa_srcf "$T" origin 8)" "default branch not read"
is "R3: and its pull request was not decided: #901 is unknown (control)" "$(_sa_state "$T" 901)" unknown

# ---- R2: one billing call --------------------------------------------------------
B=users/fixture/settings/billing/actions; BO=orgs/fixture/settings/billing/actions
rm -f "$SAK"/bill.*
_sa_land --prs --tsv; _sa_keep r2ok.tsv
is "R2: the billing GET answers: the gh log holds exactly one billing GET" "$(_sa_apis "$SAX/r2ok.tsv.gh" settings/billing/actions)" 1
is "R2: and it is the users/ GET" "$(_sa_apis "$SAX/r2ok.tsv.gh" "$B")" 1
is "R2: and no orgs/ GET follows" "$(_sa_apis "$SAX/r2ok.tsv.gh" "$BO")" 0
is "R2: and the budget row says read (control)" "$(_sa_srcf "$SAX/r2ok.tsv" budget 4)" read
_sa_lacks "R2: and says nothing of the user scope" "$(_sa_srcf "$SAX/r2ok.tsv" budget 8)" "user scope"
printf '1\n' > "$SAK/bill.users.rc"; printf 'gh: Not Found (HTTP 404)\n' > "$SAK/bill.users.err"
printf '{"message":"Not Found","documentation_url":"https://docs.github.com/rest","status":"404"}\n' > "$SAK/bill.users.out"
cp "$SAK/bill.users.rc" "$SAK/bill.orgs.rc"; cp "$SAK/bill.users.err" "$SAK/bill.orgs.err"; cp "$SAK/bill.users.out" "$SAK/bill.orgs.out"
_sa_land --prs --tsv; _sa_keep r2404.tsv
is "R2: users/ answers 404: the page exits 0" "$(cat "$SAX/r2404.tsv.rc")" 0
is "R2: after a 404 the gh log holds one users/ GET" "$(_sa_apis "$SAX/r2404.tsv.gh" "$B")" 1
is "R2: and then one orgs/ GET" "$(_sa_apis "$SAX/r2404.tsv.gh" "$BO")" 1
is "R2: and no more billing GETs than those two" "$(_sa_apis "$SAX/r2404.tsv.gh" settings/billing/actions)" 2
is "R2: both answering 404: the budget row says unread" "$(_sa_srcf "$SAX/r2404.tsv" budget 4)" unread
has "R2: and adds the scope hint after the 404" "$(_sa_srcf "$SAX/r2404.tsv" budget 8)" "the token may lack the user scope"
rm -f "$SAK"/bill.orgs.*
_sa_land --prs --tsv; _sa_keep r2org.tsv
is "R2: users/ 404 then orgs/ answering: two billing GETs, users/ then orgs/" \
   "$(_sa_apis "$SAX/r2org.tsv.gh" "$B")$(_sa_apis "$SAX/r2org.tsv.gh" "$BO")" 11
is "R2: and the budget row says read" "$(_sa_srcf "$SAX/r2org.tsv" budget 4)" read
rm -f "$SAK"/bill.*
printf '1\n' > "$SAK/bill.users.rc"; printf 'gh: HTTP 502: Bad Gateway (https://api.github.com/%s)\n' "$B" > "$SAK/bill.users.err"
_sa_land --prs --tsv; _sa_keep r2502.tsv
is "R2: users/ answers 502: the page exits 0" "$(cat "$SAX/r2502.tsv.rc")" 0
is "R2: after a 502 the gh log holds exactly one billing GET" "$(_sa_apis "$SAX/r2502.tsv.gh" settings/billing/actions)" 1
is "R2: and no orgs/ GET" "$(_sa_apis "$SAX/r2502.tsv.gh" "$BO")" 0
is "R2: the budget row says unread (control)" "$(_sa_srcf "$SAX/r2502.tsv" budget 4)" unread
has "R2: and gives gh's first error line (control)" "$(_sa_srcf "$SAX/r2502.tsv" budget 8)" "502"
_sa_lacks "R2: and never the scope hint after a 502" "$(_sa_srcf "$SAX/r2502.tsv" budget 8)" "user scope"
printf 'error connecting to api.github.com\n' > "$SAK/bill.users.err"
_sa_land --prs --tsv; _sa_keep r2net.tsv
is "R2: a network error: one billing GET and no orgs/ GET" \
   "$(_sa_apis "$SAX/r2net.tsv.gh" settings/billing/actions)$(_sa_apis "$SAX/r2net.tsv.gh" "$BO")" 10
is "R2: the budget row says unread (control)" "$(_sa_srcf "$SAX/r2net.tsv" budget 4)" unread
_sa_lacks "R2: and never the scope hint after a network error" "$(_sa_srcf "$SAX/r2net.tsv" budget 8)" "user scope"
rm -f "$SAK"/bill.*

# ---- R1, R6: the queue over a project with no checkout and a repository named twice
_sa_land --queue --tsv; _sa_keep q.tsv
_sa_land --queue; _sa_keep q.txt
Q="$SAX/q.tsv"
is "R1: --queue exits 0, with --tsv and without" "$(cat "$Q.rc")$(cat "$SAX/q.txt.rc")" 00
is "R1: two has no checkout: the gh log holds exactly one GET of repos/fixture/two" "$(_sa_apiw "$Q.gh" repos/fixture/two)" 1
is "R1: and the home's project, whose checkout is the home, asks gh for no default branch" "$(_sa_apiw "$Q.gh" repos/fixture/home)" 0
is "R1: and zeta, read under felix, asks for none either" "$(_sa_apis "$Q.gh" "epos/Fixture/Home")" 0
is "R1, §2: gh is asked nothing but pr list, a GET of repos/<owner>/<name> and the billing GETs" \
   "$(LC_ALL=C awk '!(index($0, "pr list") == 1 || ($1 == "api" && (index($0, "repos/") || index($0, "settings/billing/actions"))))' "$Q.gh" | head -3)" ""
is "R1: two's default branch is trunk, from gh: #701 into trunk, founder, is listed once" "$(_sa_nrow "$Q" 701)" 1
is "R1: under fixture/two (control)" "$(_sa_f "$Q" 701 2)" fixture/two
is "R1: and #702 into main, founder by label, is stacked, so not in --queue" "$(_sa_nrow "$Q" 702)" 0
is "R5: every line of --queue --tsv has eight columns (control)" "$(_sa_cols "$Q")" ""
is "R6: felix and zeta name one repository: founder #601 is listed exactly once" "$(_sa_nrow "$Q" 601)" 1
is "R6: and founder #602 exactly once" "$(_sa_nrow "$Q" 602)" 1
is "R6: and the plain #603 not at all (control)" "$(_sa_nrow "$Q" 603)" 0
is "R6: gh listed fixture/home once, not once per project: one pr list besides two's and three's" \
   "$(LC_ALL=C awk 'index($0, "pr list") == 1 && tolower($0) !~ /fixture\/(two|three)/' "$Q.gh" | LC_ALL=C awk 'END { print NR }')" 1
is "R6: the text lists #601 on one line" "$(LC_ALL=C awk 'index($0, "#601 ") == 1 { n++ } END { print n + 0 }' "$SAX/q.txt")" 1
is "R6: and #602 on one line" "$(LC_ALL=C awk 'index($0, "#602 ") == 1 { n++ } END { print n + 0 }' "$SAX/q.txt")" 1
_saz="$(LC_ALL=C awk 'index($0, "zeta")' "$SAX/q.txt" | LC_ALL=C awk -v p="$SA" '{ while ((i = index($0, p))) $0 = substr($0, 1, i - 1) substr($0, i + length(p)); print }')"
is "R6: zeta, second in name order, has a block of its own (control)" "$([ -n "$_saz" ] && echo yes)" yes
has "R6: and zeta's block names felix, whose block lists its pull requests" "$_saz" felix
_saf="$(LC_ALL=C awk 'index($0, "felix") == 1' "$SAX/q.txt")"
_sa_lacks "R6: and felix's block does not send the reader to zeta" "$_saf" zeta

# ---- R5: a tab in the repo cell --------------------------------------------------
_sa_proj maple "github.com/fixture/ta${SATAB}by"
_sa_commit "$SAH" maple; _fx_git "$SAH" push -q origin main >/dev/null 2>&1; _fx_git "$SAH" fetch -q origin >/dev/null 2>&1
is "the amendments fixture: maple's remote_match holds a tab (fixture control)" \
   "$(LC_ALL=C grep -c "fixture/ta${SATAB}by" "$SAH/projects/maple/project.json")" 1
_sa_land --queue --tsv; _sa_keep r5q.tsv
T="$SAX/r5q.tsv"
is "R5: --queue with a remote_match holding a tab exits 0" "$(cat "$T.rc")" 0
# A remote_match holding a tab is no owner/name slug: R5, clarified, makes its
# gh source row unread with that reason, and lists no pull request of it. First
# written as either-or (read, #801 one row of eight columns); restated
# 2026-10-18 at the carry to the clarified contract alone, because the two
# branches gave a tree without the page assertion names this tree never
# reaches, and the record's red run may name only what the manifest lists.
_sat="$(LC_ALL=C awk -F'\t' '$1 == "source" && $3 == "gh" && index($2, "ta by") { print $4; exit }' "$T")"
is "R5: maple has a gh source row whose repo cell holds a space where the tab was" "$([ -n "$_sat" ] && echo yes)" yes
is "R5: maple's gh source row is unread, as R5 clarified says" "$_sat" unread
is "R5: maple not read: no pr row of its repository" "$(LC_ALL=C awk -F'\t' '$1 == "pr" && index($2, "ta")' "$T" | LC_ALL=C grep -c 'ta by')" 0
is "R5: and its gh source row says why" "$(LC_ALL=C awk -F'\t' '$1 == "source" && $3 == "gh" && index($2, "ta by") { print ($8 != "" && $8 != "-") ? "why" : "silent"; exit }' "$T")" why
is "R5: every line of that --queue --tsv has eight columns" "$(_sa_cols "$T")" ""
is "R5: and the other projects still list theirs: #601 once (control)" "$(_sa_nrow "$T" 601)" 1
mkdir -p "$SA/tabrepo"; _fx_git "$SA/tabrepo" init -q >/dev/null 2>&1
_fx_git "$SA/tabrepo" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
printf 'tab\n' > "$SA/tabrepo/README.md"; _sa_commit "$SA/tabrepo" base
_fx_git "$SA/tabrepo" remote add origin "$SA/github.com/fixture/ta${SATAB}by.git" >/dev/null 2>&1
_fx_git "$SA/tabrepo" update-ref refs/remotes/origin/main HEAD >/dev/null 2>&1
_fx_git "$SA/tabrepo" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main >/dev/null 2>&1
is "the amendments fixture: tabrepo's origin URL holds a tab, and origin/HEAD names main (fixture control)" \
   "$(git -C "$SA/tabrepo" config --get remote.origin.url 2>/dev/null | LC_ALL=C grep -c "ta${SATAB}by")|$(git -C "$SA/tabrepo" symbolic-ref -q refs/remotes/origin/HEAD 2>&1)" "1|refs/remotes/origin/main"
_sa_land --prs --tsv --repo "$SA/tabrepo"; _sa_keep r5p.tsv
T="$SAX/r5p.tsv"
is "R5: --prs in a repository whose slug holds a tab exits 0" "$(cat "$T.rc")" 0
is "R5: its #801 is one pr row" "$(_sa_nrow "$T" 801)" 1
is "R5: of exactly eight columns" "$(_sa_row "$T" 801 | LC_ALL=C awk -F'\t' '{ print NF }')" 8
_sac="$(_sa_f "$T" 801 2)"
is "R5: its repo cell is not empty and holds no carriage return" "$([ -n "$_sac" ] && echo set)$(printf '%s' "$_sac" | LC_ALL=C tr -d -c '\r' | LC_ALL=C awk '{ printf "%s", length($0) ? "cr" : "" }')" set
is "R5: every line of that page, source rows too, has eight columns" "$(_sa_cols "$T")" ""

# ---- R4: how old main is ----------------------------------------------------------
# origin/main last moved nine days ago by its reflog; then a fetch of another
# branch only, so FETCH_HEAD is fresh and origin/main's reflog is not.
SARL="$SAH/.git/logs/refs/remotes/origin/main"; SAOLD=$(( $(date +%s) - 777600 ))
if [ -f "$SARL" ]; then
  LC_ALL=C awk -v t="$SAOLD" 'BEGIN { FS = OFS = "\t" } { n = split($1, w, " "); w[n - 1] = t; s = w[1]; for (i = 2; i <= n; i++) s = s " " w[i]; $1 = s; print }' "$SARL" > "$SARL.new" && mv "$SARL.new" "$SARL"
fi
# The reflog's file and the loose ref carry the same old time, as they would
# had main last moved then.
SAOLDT="$(date -r "$SAOLD" +%Y%m%d%H%M.%S 2>/dev/null || date -d "@$SAOLD" +%Y%m%d%H%M.%S)"
touch -t "$SAOLDT" "$SARL" "$SAH/.git/refs/remotes/origin/main" 2>/dev/null
touch -t 202601010000 "$SAH/.git/FETCH_HEAD" 2>/dev/null
_fx_git "$SAH" push -q origin main:refs/heads/other >/dev/null 2>&1
_fx_git "$SAH" fetch -q origin other >/dev/null 2>&1
is "the amendments fixture: origin/main's reflog last moved nine days ago (fixture control)" \
   "$(LC_ALL=C awk -F'\t' 'END { n = split($1, w, " "); print w[n - 1] }' "$SARL" 2>&1)" "$SAOLD"
is "the amendments fixture: FETCH_HEAD is fresh and names other, not main (fixture control)" \
   "$(find "$SAH/.git/FETCH_HEAD" -mmin -10 2>/dev/null | LC_ALL=C awk 'END { print NR }')|$(LC_ALL=C grep -c "'other'" "$SAH/.git/FETCH_HEAD" 2>/dev/null)|$(LC_ALL=C grep -c "'main'" "$SAH/.git/FETCH_HEAD" 2>/dev/null)" "1|1|0"
_sa_land --prs --tsv; _sa_keep r4old.tsv
D="$(_sa_srcf "$SAX/r4old.tsv" origin 8)"; P="$(_sa_moved "$D")"
is "R4: the page after a fetch of another branch exits 0" "$(cat "$SAX/r4old.tsv.rc")" 0
has "R4: the origin row says when origin/main last moved, from its reflog" "$D" "origin/main last moved "
_sa_ge "R4: and that is nine days ago, not the fresh fetch of another branch" "$(_sa_hours "$P")" 48 "$D"
case "$D" in
  *fetch*) has "R4: an age of FETCH_HEAD, if given, is labelled the last fetch of any ref" "$D" "any ref" ;;
  *) ok "R4: an age of FETCH_HEAD, if given, is labelled the last fetch of any ref" ;;
esac
has "R4: the row still names the default branch (control)" "$D" "default branch main"
printf 'moved\n' > "$SAH/notes/moved.md"; _sa_commit "$SAH" moved
_fx_git "$SAH" push -q origin main >/dev/null 2>&1; _fx_git "$SAH" fetch -q origin >/dev/null 2>&1
_sa_land --prs --tsv; _sa_keep r4new.tsv
D="$(_sa_srcf "$SAX/r4new.tsv" origin 8)"; P="$(_sa_moved "$D")"
has "R4: main moved just now: the origin row says when origin/main last moved (control)" "$D" "origin/main last moved "
_sa_lt "R4: and that is under an hour ago (control)" "$(_sa_hours "$P")" 1 "$D"

# ---- the fixture is removed ---------------------------------------------------------
chmod -R u+rwx "$SA" 2>/dev/null; rm -rf "$SA"
[ -e "$SA" ] && bad "the amendments fixture is removed when its part ends" "$SA is still there" || ok "the amendments fixture is removed when its part ends"
# <<< stuck-pr-page-amendments
