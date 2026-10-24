printf '\nb10: escape channels see names as they are, docs/direction.md, project.json and a missing secret scan (blind)\n'
# Written blind on 2026-10-24 from the contract
# docs/2026-10-24-audit-fixes/b10-escape-channels-see-what-they-claim.md alone:
# C015, C006, C075, C077 and the structure items (B1-B9, B25-B38; its A1-A40). No
# engine code was read. The calls are the contract's ESC, BLK, CLS with TIER, and
# PROT, each in a child of this suite's bash under set -uo pipefail (the suite's
# own options), standing in the fixture repository, stdin from /dev/null, under
# perl's alarm so no call can stall the suite. E is "$FROOT/harness"; P is an
# empty directory; R (B10R here) is a repository with one base commit on main and
# the change committed on feat, B = main, unless an item says otherwise.
#
# Readings, where the contract leaves room:
# - every fixture repository sets core.quotePath true in its own config (git's
#   default), so what git quotes never rests on the caller's global config;
# - "prints nothing" also wants exit 0, and "no such row" wants exit 0, so a call
#   that never ran, timed out or found no function fails rather than passing;
# - a CLS finding is a line of tier, a tab, then the path; PROT "does not print
#   escape-table" also wants status 0 or 1, so an undefined function fails;
# - A8 also refuses a line whose first field is l.yml, the shape a raw line feed
#   in a path field leaves; A23 reads <reason> as some text after the colon;
# - A33's "no escape line for it" is no line of kind escape at all, since the
#   branch changes only notes/a.txt; A38 sees escape.sh load the new file by a
#   marker line put first in a copy of that file; A40 asks both functions defined
#   and the unknown row in one assertion.
B10N="$(mktemp -d "$TMP/b10-XXXXXX" 2>/dev/null)" && B10N="$(cd "$B10N" && pwd -P)" || B10N=""
_b10n_all=""
if [ -z "$B10N" ] || [ ! -d "$B10N" ]; then B10N="$TMP/b10-n"; mkdir -p "$B10N"; _b10n_all="no directory for this part could be made under $TMP"; fi
_b10n_E="$FROOT/harness"; _b10n_P="$B10N/p"; _b10n_PT="$B10N/pt"; mkdir -p "$_b10n_P" "$_b10n_PT"
_b10n_ptw=""; cp "$_b10n_E/templates/risk.tsv" "$_b10n_PT/risk.tsv" 2>/dev/null || _b10n_ptw="templates/risk.tsv could not be copied out of $_b10n_E"
_b10n_e="$(printf '\303\251')"; _b10n_T="$(printf '\t')"; _b10n_nl=$'\n'

# ---- fixtures ----------------------------------------------------------------
_b10n_repo() {  # NAME: B10R is a new repository $B10N/NAME on main holding README.txt; _b10n_why is empty, or why it could not be made
  B10R="$B10N/$1"; _b10n_why="$_b10n_all"; [ -z "$_b10n_why" ] || return 0
  { mkdir "$B10R" && ( _fx_cd "$B10R" && git init -q -b main && git config core.quotePath true ) >/dev/null 2>&1 \
      && printf 'base\n' > "$B10R/README.txt"; } || _b10n_why="the repository $1 could not be made"
}
_b10n_ci() {  # MESSAGE: B10R's tree staged and committed
  ( _fx_cd "$B10R" && git add -A \
      && git -c user.name=b10 -c user.email=b10@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm "$1" ) >/dev/null 2>&1
}
_b10n_base() {  # [main]: the one base commit on main, then B10R on a new branch feat unless main is given
  [ -z "$_b10n_why" ] || return 0
  _b10n_ci base || { _b10n_why="the base commit in $B10R failed"; return 0; }
  [ "${1-}" = main ] || ( _fx_cd "$B10R" && git checkout -q -b feat ) >/dev/null 2>&1 || _b10n_why="no branch feat could be made in $B10R"
}
_b10n_feat() { [ -z "$_b10n_why" ] || return 0; _b10n_ci change || _b10n_why="the change on feat in $B10R could not be committed"; }
_b10n_put() {  # PATH TEXT: B10R/PATH holds TEXT and a line feed
  [ -z "$_b10n_why" ] || return 0
  case "$1" in */*) mkdir -p "$B10R/${1%/*}" 2>/dev/null ;; esac
  printf '%s\n' "$2" > "$B10R/$1" 2>/dev/null || _b10n_why="$1 could not be written in $B10R"
}
_b10n_add() { [ -z "$_b10n_why" ] || return 0; printf '%s\n' "$2" >> "$B10R/$1" 2>/dev/null || _b10n_why="$1 could not be appended to in $B10R"; }
_b10n_rm() { [ -z "$_b10n_why" ] || return 0; rm -f "$B10R/$1" 2>/dev/null; [ ! -e "$B10R/$1" ] || _b10n_why="$1 could not be removed in $B10R"; }
# Git's own quoting of the changed names that it quotes with core.quotePath off.
_b10n_quoted() { _fx_git "$B10R" -c core.quotePath=false diff --name-only main...HEAD 2>/dev/null | LC_ALL=C grep '^"'; }

# ---- calls -------------------------------------------------------------------
# SECS DIR SNIPPET ENGINE ARG...: SNIPPET run by this suite's bash in DIR with
# set -uo pipefail, stdin from /dev/null, ENGINE as $1 and ARG... after it, under
# a time limit. _b10n_out is its stdout, _b10n_rc its status (125: nothing ran).
_b10n_sh() {
  local s="$1" d="$2" c="$3"; shift 3
  _b10n_out=""; _b10n_rc=125
  [ -d "$d" ] || return 0
  _b10n_out="$( ( _fx_cd "$d" || exit 125
      exec perl -e 'alarm shift; exec @ARGV or exit 127' "$s" "$BASH" -c "set -uo pipefail; $c" _ "$@" ) </dev/null 2>/dev/null )"
  _b10n_rc=$?
}
_b10n_esc() {  # [BASE [ENGINE]]: ESC on B10R, B = main unless given
  _b10n_out=""; _b10n_rc=125; [ -z "$_b10n_why" ] || return 0
  _b10n_sh 90 "$B10R" '. "$1/lib/escape.sh"; felix_escapes "$2" "$3" "$4" ""' "${2:-$_b10n_E}" "$_b10n_P" "${1-main}" "$B10R"
}
_b10n_blk() {  # [ENGINE]: BLK on B10R, B = main
  _b10n_out=""; _b10n_rc=125; [ -z "$_b10n_why" ] || return 0
  _b10n_sh 180 "$B10R" 'for f in resolve verify review classify evidence escape; do . "$1/lib/$f.sh"; done
    felix_merge_blockers "$2" main "$3" "$4"' "${1:-$_b10n_E}" "$_b10n_P" "$B10R" "$FROOT"
}
_b10n_cls() {  # CLS on B10R, P holding the template risk.tsv: _b10n_out the findings, _b10n_tier TIER
  _b10n_tier=""; _b10n_why="${_b10n_why:-$_b10n_ptw}"; _b10n_out=""; _b10n_rc=125; [ -z "$_b10n_why" ] || return 0
  _b10n_sh 90 "$B10R" '. "$1/lib/classify.sh"; type felix_classify_diff >/dev/null 2>&1 || exit 126
    f="$(felix_classify_diff "$2" main "$3")"; printf "%s\n--\n%s\n" "$f" "$(felix_classify_tier "$f")"' "$_b10n_E" "$_b10n_PT" "$B10R"
  [ "$_b10n_rc" -eq 0 ] || return 0
  _b10n_tier="${_b10n_out##*"$_b10n_nl"}"; _b10n_out="${_b10n_out%"$_b10n_nl"--"$_b10n_nl"*}"
}
_b10n_prot() { _b10n_why="$_b10n_all"; _b10n_sh 30 "$B10N" '. "$1/lib/escape.sh"; felix_land_protected "$2"' "$_b10n_E" "$1"; }

# ---- readings ----------------------------------------------------------------
# CHANNEL PATH [NEEDLE [prefix]]: how many lines of _b10n_out have CHANNEL as the
# first field and PATH as the second, byte for byte ("-": any), and NEEDLE inside
# the text after the second tab (at its start, with more after it, for prefix).
# Read through ENVIRON, since awk -v would turn a backslash in a name into an escape.
_b10n_n() {
  printf '%s\n' "$_b10n_out" | B10_C="$1" B10_P="$2" B10_S="${3-}" B10_M="${4-}" LC_ALL=C awk '
    BEGIN { c = ENVIRON["B10_C"]; p = ENVIRON["B10_P"]; s = ENVIRON["B10_S"]; m = ENVIRON["B10_M"] }
    { i = index($0, "\t"); f1 = i ? substr($0, 1, i - 1) : $0; r = i ? substr($0, i + 1) : ""
      j = index(r, "\t"); f2 = j ? substr(r, 1, j - 1) : r; f3 = j ? substr(r, j + 1) : ""
      k = index(f3, s)
      if ((c == "-" || f1 == c) && (p == "-" || f2 == p) && (s == "" || (m == "prefix" ? k == 1 && length(f3) > length(s) : k > 0))) n++ }
    END { print n + 0 }'
}
_b10n_fx() { [ -z "$_b10n_why" ] || { bad "$1" "the fixture could not be built: $_b10n_why"; return 1; }; }
_b10n_said() { printf 'exit %s, output [%s]' "$_b10n_rc" "$_b10n_out"; }
_b10n_row() {  # NAME CHANNEL PATH [NEEDLE]: the last call printed such a row
  _b10n_fx "$1" || return 0
  if [ "$(_b10n_n "$2" "$3" "${4-}")" -gt 0 ]; then ok "$1"
  else bad "$1" "no [$2] row for [$3]${4:+ whose reason holds [$4]}: $(_b10n_said)"; fi
}
_b10n_norow() {  # NAME CHANNEL PATH: the last call exited 0 and printed no such row
  _b10n_fx "$1" || return 0
  if [ "$_b10n_rc" -eq 0 ] && [ "$(_b10n_n "$2" "$3")" -eq 0 ]; then ok "$1"; else bad "$1" "$(_b10n_said)"; fi
}
_b10n_none() {  # NAME: the last call exited 0 and printed nothing
  _b10n_fx "$1" || return 0
  if [ "$_b10n_rc" -eq 0 ] && [ -z "$_b10n_out" ]; then ok "$1"; else bad "$1" "$(_b10n_said)"; fi
}

# ---- C015: path names reach every channel as the names they are ----------------
_b10n_w1=".github/workflows/d${_b10n_e}ploy.yml"
_b10n_repo a1; _b10n_base; _b10n_put "$_b10n_w1" 'on: push'; _b10n_feat
_b10n_R1="$B10R"; _b10n_W1="$_b10n_why"
_b10n_on1() { B10R="$_b10n_R1"; _b10n_why="$_b10n_W1"; _b10n_out=""; _b10n_rc=125; }
_b10n_esc
_b10n_row "b10 A1: a workflow named with a byte past ASCII gets an execute row under its own name, core.quotePath true in the repository" execute "$_b10n_w1"
_b10n_repo a2; _b10n_base main; _b10n_put "$_b10n_w1" 'on: push'
[ -n "$_b10n_why" ] || ( _fx_cd "$B10R" && git add -A ) >/dev/null 2>&1 || _b10n_why="the workflow could not be staged in $B10R"
_b10n_esc
_b10n_row "b10 A2: the same workflow staged on main and not committed gets the same execute row" execute "$_b10n_w1"
_b10n_on1
[ -n "$_b10n_why" ] || _b10n_sh 90 "$B10R" 'export GIT_CONFIG_PARAMETERS="$4"; . "$1/lib/escape.sh"; felix_escapes "$2" main "$3" ""' \
  "$_b10n_E" "$_b10n_P" "$B10R" "'core.quotepath=true'"
_b10n_row "b10 A3: a caller exporting GIT_CONFIG_PARAMETERS core.quotepath=true still gets the execute row under the raw name" execute "$_b10n_w1"
_b10n_on1
[ -n "$_b10n_why" ] || _b10n_sh 90 "$B10R" 'export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.quotepath GIT_CONFIG_VALUE_0=true
  . "$1/lib/escape.sh"; felix_escapes "$2" main "$3" ""' "$_b10n_E" "$_b10n_P" "$B10R"
_b10n_row "b10 A4: a caller exporting GIT_CONFIG_COUNT, KEY_0 and VALUE_0 for core.quotepath=true still gets the execute row under the raw name" execute "$_b10n_w1"
_b10n_on1
[ -n "$_b10n_why" ] || _b10n_sh 90 "$B10R" 'export GIT_CONFIG_PARAMETERS="$4"; . "$1/lib/escape.sh"
  type felix_escapes >/dev/null 2>&1 || { echo "felix_escapes is not defined"; exit 0; }
  felix_escapes "$2" main "$3" "" >/dev/null 2>&1; printf "%s\n" "${GIT_CONFIG_PARAMETERS-(unset)}"' "$_b10n_E" "$_b10n_P" "$B10R" "'x.y=z'"
_b10n_nm="b10 A5: after felix_escapes returns, called directly, the caller's GIT_CONFIG_PARAMETERS still reads 'x.y=z' (control)"
_b10n_fx "$_b10n_nm" && is "$_b10n_nm" "$_b10n_out" "'x.y=z'"
_b10n_on1; _b10n_why="${_b10n_why:-$_b10n_ptw}"
[ -n "$_b10n_why" ] || _b10n_sh 90 "$B10R" 'export GIT_CONFIG_PARAMETERS="$4"; . "$1/lib/classify.sh"
  type felix_classify_diff >/dev/null 2>&1 || { echo "felix_classify_diff is not defined"; exit 0; }
  felix_classify_diff "$2" main "$3" >/dev/null 2>&1; printf "%s\n" "${GIT_CONFIG_PARAMETERS-(unset)}"' "$_b10n_E" "$_b10n_PT" "$B10R" "'x.y=z'"
_b10n_nm="b10 A6: after felix_classify_diff returns, called directly, the caller's GIT_CONFIG_PARAMETERS still reads 'x.y=z' (control)"
_b10n_fx "$_b10n_nm" && is "$_b10n_nm" "$_b10n_out" "'x.y=z'"

# B4: names git quotes even with core.quotePath off, one branch each.
_b10n_o8=""; _b10n_w8=""; _b10n_k8=0; _b10n_Sq=""; _b10n_Rq=""; _b10n_Wq="A7.1 did not run"
_b10n_a7() {  # INDEX WHAT FILE
  local w=".github/workflows/$3" q="" nm="b10 A7.$1: a workflow named with $2 gets an unknown CHANGED-PATHS row whose reason holds the name as git quotes it"
  _b10n_repo "a7-$1"; _b10n_base
  if [ -z "$_b10n_why" ]; then
    mkdir -p "$B10R/.github/workflows"; printf 'on: push\n' > "$B10R/$w" 2>/dev/null
    if [ ! -f "$B10R/$w" ]; then
      skip "$nm" "the file system refused the name"
      [ "$1" != 1 ] || _b10n_Sq="the file system refused the name q\"uote.yml"
      return 0
    fi
    _b10n_feat
  fi
  [ -n "$_b10n_why" ] || q="$(_b10n_quoted)"
  case "$q" in '"'?*) ;; *) [ -n "$_b10n_why" ] || _b10n_why="git did not quote the name: it printed [$q]" ;; esac
  _b10n_esc
  _b10n_row "$nm" unknown CHANGED-PATHS "$q"
  [ "$1" != 1 ] || { _b10n_Rq="$B10R"; _b10n_Wq="$_b10n_why"; }
  case "$1" in 3|4) _b10n_k8="$((_b10n_k8 + 1))"; _b10n_o8="$_b10n_o8$_b10n_out$_b10n_nl"; _b10n_w8="$_b10n_w8$_b10n_why" ;; esac
}
_b10n_a7 1 'a double quote' 'q"uote.yml'
_b10n_a7 2 'a backslash' 'b\ack.yml'
_b10n_a7 3 'a tab' "t${_b10n_T}ab.yml"
_b10n_a7 4 'a line feed' "n${_b10n_nl}l.yml"
_b10n_a7 5 'DEL' "d$(printf '\177')el.yml"
_b10n_nm="b10 A8: no row's path field is a piece of the tab or the line-feed name (.github/workflows/t, .github/workflows/n, l.yml) (control)"
if [ "$_b10n_k8" -eq 0 ]; then skip "$_b10n_nm" "the file system refused both names"
elif [ -n "$_b10n_w8" ]; then bad "$_b10n_nm" "the fixture could not be built: $_b10n_w8"
else
  _b10n_out="$_b10n_o8"
  _b10n_c="$(( $(_b10n_n - .github/workflows/t) + $(_b10n_n - .github/workflows/n) + $(_b10n_n - l.yml) + $(_b10n_n l.yml -) ))"
  is "$_b10n_nm" "$_b10n_c rows" "0 rows"
fi
_b10n_nm="b10 A9: one branch with q\"uote.yml and plain.yml gives the unknown CHANGED-PATHS row and an execute row for .github/workflows/plain.yml"
if [ -n "$_b10n_Sq" ]; then skip "$_b10n_nm" "$_b10n_Sq"
else
  _b10n_repo a9; _b10n_base; _b10n_put '.github/workflows/q"uote.yml' 'on: push'; _b10n_put .github/workflows/plain.yml 'on: push'; _b10n_feat
  _b10n_q=""; [ -n "$_b10n_why" ] || _b10n_q="$(_b10n_quoted)"
  case "$_b10n_q" in '"'?*) ;; *) [ -n "$_b10n_why" ] || _b10n_why="git did not quote q\"uote.yml: it printed [$_b10n_q]" ;; esac
  _b10n_esc
  if _b10n_fx "$_b10n_nm"; then
    if [ "$(_b10n_n unknown CHANGED-PATHS "$_b10n_q")" -gt 0 ] && [ "$(_b10n_n execute .github/workflows/plain.yml)" -gt 0 ]; then ok "$_b10n_nm"
    else bad "$_b10n_nm" "$(_b10n_said)"; fi
  fi
fi
_b10n_onq() { B10R="$_b10n_Rq"; _b10n_why="$_b10n_Wq"; }
_b10n_nm="b10 A10: BLK on the double-quote branch prints a line of kind unknown, subject CHANGED-PATHS"
_b10n_nm2="b10 A11: BLK on the double-quote branch prints no line of kind escape, subject unknown (control)"
if [ -n "$_b10n_Sq" ]; then skip "$_b10n_nm" "$_b10n_Sq"; skip "$_b10n_nm2" "$_b10n_Sq"
else _b10n_onq; _b10n_blk; _b10n_row "$_b10n_nm" unknown CHANGED-PATHS; _b10n_norow "$_b10n_nm2" escape unknown; fi
_b10n_w12="projects/f${_b10n_e}/deny.tsv"
_b10n_repo a12; _b10n_put "$_b10n_w12" "Bash${_b10n_T}rm -rf${_b10n_T}a${_b10n_nl}Bash${_b10n_T}git push --force${_b10n_T}b"; _b10n_base
_b10n_put "$_b10n_w12" "Bash${_b10n_T}rm -rf${_b10n_T}a"; _b10n_feat; _b10n_esc
_b10n_row "b10 A12: a deny table under a project directory named past ASCII that loses a row gets a verifier row" verifier "$_b10n_w12"
_b10n_cls_is() {  # NAME TIER PATH: CLS printed a finding TIER<TAB>PATH and TIER is TIER
  _b10n_fx "$1" || return 0
  if [ "$_b10n_rc" -eq 0 ] && [ "$(_b10n_n "$2" "$3")" -gt 0 ] && [ "$_b10n_tier" = "$2" ]; then ok "$1"
  else bad "$1" "tier [$_b10n_tier], findings [$_b10n_out], exit $_b10n_rc"; fi
}
_b10n_on1; _b10n_cls
_b10n_cls_is "b10 A13: CLS with the template risk.tsv gives the workflow named past ASCII a red finding under its own name, and TIER is red" red "$_b10n_w1"
_b10n_nm="b10 A14: CLS with the template on the double-quote branch gives a finding unknown CHANGED-PATHS, and TIER is unknown"
if [ -n "$_b10n_Sq" ]; then skip "$_b10n_nm" "$_b10n_Sq"; else _b10n_onq; _b10n_cls; _b10n_cls_is "$_b10n_nm" unknown CHANGED-PATHS; fi
_b10n_repo a15; _b10n_base; _b10n_put .github/workflows/plain.yml 'on: push'; _b10n_feat; _b10n_esc
_b10n_c="$(_b10n_n execute .github/workflows/plain.yml)"; _b10n_cls
_b10n_nm="b10 A15: a plain workflow gets an execute row, and CLS with the template gives TIER red (control)"
if _b10n_fx "$_b10n_nm"; then
  if [ "$_b10n_c" -gt 0 ] && [ "$_b10n_tier" = red ]; then ok "$_b10n_nm"; else bad "$_b10n_nm" "$_b10n_c execute rows; tier [$_b10n_tier], $(_b10n_said)"; fi
fi
_b10n_repo a16; _b10n_base; _b10n_put "docs/caf${_b10n_e}.md" '# notes'; _b10n_feat; _b10n_esc
_b10n_none "b10 A16: docs/cafe.md, its e with an acute accent, alone gives ESC nothing (control)"
_b10n_cls; _b10n_nm="b10 A17: and CLS with the template prints no unknown finding for it, a name merely past ASCII not being unknown (control)"
if _b10n_fx "$_b10n_nm"; then
  if [ "$_b10n_rc" -eq 0 ] && [ -n "$_b10n_tier" ] && [ "$(_b10n_n unknown -)" -eq 0 ]; then ok "$_b10n_nm"
  else bad "$_b10n_nm" "tier [$_b10n_tier], findings [$_b10n_out], exit $_b10n_rc"; fi
fi

# ---- C006: a change to docs/direction.md escapes to the founder ------------------
_b10n_repo a18; _b10n_put docs/direction.md '# direction'; _b10n_base; _b10n_add docs/direction.md 'a decision folded in'; _b10n_feat
_b10n_R18="$B10R"; _b10n_W18="$_b10n_why"; _b10n_esc
_b10n_row "b10 A18: a line appended to docs/direction.md gives a direction row whose reason names the founder" direction docs/direction.md founder
_b10n_repo a19; _b10n_base; _b10n_put docs/direction.md '# direction'; _b10n_feat; _b10n_esc
_b10n_row "b10 A19: docs/direction.md created where the base has none gives the same direction row" direction docs/direction.md founder
_b10n_repo a20; _b10n_put docs/direction.md '# direction'; _b10n_base; _b10n_rm docs/direction.md; _b10n_feat; _b10n_esc
_b10n_row "b10 A20: docs/direction.md deleted where the base has it gives the same direction row" direction docs/direction.md founder
_b10n_repo a21; _b10n_base; _b10n_put DOCS/Direction.md '# direction'; _b10n_feat; _b10n_esc
_b10n_row "b10 A21: DOCS/Direction.md created in a base with no docs/ gives a direction row under that name" direction DOCS/Direction.md
_b10n_k=0
for _b10n_p in docs/direction-notes.md docs/directions.md sub/docs/direction.md; do
  _b10n_k="$((_b10n_k + 1))"
  _b10n_repo "a22-$_b10n_k"; _b10n_base; _b10n_put "$_b10n_p" '# notes'; _b10n_feat; _b10n_esc
  _b10n_none "b10 A22.$_b10n_k: $_b10n_p created on a branch gives ESC nothing (control)"
done
B10R="$_b10n_R18"; _b10n_why="$_b10n_W18"; _b10n_blk
_b10n_nm="b10 A23: BLK on the appended-line branch prints escape, direction, then docs/direction.md: and its reason"
if _b10n_fx "$_b10n_nm"; then
  if [ "$(_b10n_n escape direction 'docs/direction.md: ' prefix)" -gt 0 ]; then ok "$_b10n_nm"; else bad "$_b10n_nm" "$(_b10n_said)"; fi
fi

# ---- C075: project.json is an enforcing table only where Felix keeps one ----------
_b10n_nx() {  # NAME: B10R on feat over a product base with apps/web, libs/ui and a root project.json
  _b10n_repo "$1"
  _b10n_put apps/web/project.json "$(printf '{\n  "name": "web",\n  "outputPath": "dist/apps/web"\n}')"
  _b10n_put libs/ui/project.json "$(printf '{\n  "name": "ui",\n  "outputPath": "dist/libs/ui"\n}')"
  _b10n_put project.json "$(printf '{\n  "name": "root",\n  "targets": "x"\n}')"
  _b10n_base
}
_b10n_nx a24-1; _b10n_put apps/web/project.json "$(printf '{\n  "name": "web",\n  "outputPath": "dist/web"\n}')"; _b10n_feat; _b10n_esc
_b10n_none "b10 A24.1: an Nx app's project.json with its outputPath changed gives ESC nothing"
_b10n_nx a24-2; _b10n_rm libs/ui/project.json; _b10n_feat; _b10n_esc
_b10n_none "b10 A24.2: an Nx lib's project.json deleted gives ESC nothing"
_b10n_nx a24-3; _b10n_put project.json "$(printf '{\n  "name": "root"\n}')"; _b10n_feat; _b10n_esc
_b10n_none "b10 A24.3: a root project.json losing its targets key and the comma before it gives ESC nothing"
_b10n_noesc() {  # NAME PATH: PROT ran (status 0 or 1) and did not print escape-table
  _b10n_prot "$2"
  if _b10n_fx "$1"; then
    case "$_b10n_rc:$_b10n_out" in [01]:*escape-table*) bad "$1" "$(_b10n_said)" ;; [01]:*) ok "$1" ;; *) bad "$1" "$(_b10n_said)" ;; esac
  fi
}
_b10n_noesc "b10 A25: PROT apps/web/project.json does not print escape-table" apps/web/project.json
_b10n_noesc "b10 A26: PROT project.json does not print escape-table" project.json
_b10n_prot projects/p/project.json; _b10n_nm="b10 A27: PROT projects/p/project.json prints escape-table and exits 0 (control)"
_b10n_fx "$_b10n_nm" && is "$_b10n_nm" "exit $_b10n_rc [$_b10n_out]" "exit 0 [escape-table]"
_b10n_repo a28-1; _b10n_put projects/web/project.json "$(printf '{\n  "name": "web",\n  "targets": "x"\n}')"; _b10n_base
_b10n_put projects/web/project.json "$(printf '{\n  "name": "web"\n}')"; _b10n_feat; _b10n_esc
_b10n_row "b10 A28.1: projects/web/project.json with a key removed still gets a verifier row (control)" verifier projects/web/project.json
_b10n_repo a28-2; _b10n_put some/dir/land.tsv "a.txt${_b10n_T}version-above${_b10n_T}-${_b10n_T}-"; _b10n_base
_b10n_add some/dir/land.tsv "b.txt${_b10n_T}version-above${_b10n_T}-${_b10n_T}-"; _b10n_feat; _b10n_esc
_b10n_row "b10 A28.2: some/dir/land.tsv with a row added still gets a verifier row (control)" verifier some/dir/land.tsv
_b10n_repo a28-3; _b10n_put config/risk.tsv "green${_b10n_T}path${_b10n_T}^docs/${_b10n_T}documentation${_b10n_nl}red${_b10n_T}path${_b10n_T}^src/${_b10n_T}source"
_b10n_base; _b10n_put config/risk.tsv "green${_b10n_T}path${_b10n_T}^docs/${_b10n_T}documentation"; _b10n_feat; _b10n_esc
_b10n_row "b10 A28.3: config/risk.tsv with one of its two rows removed still gets a verifier row (control)" verifier config/risk.tsv
_b10n_repo a28-4; _b10n_put projects/web/project.json "$(printf '{\n  "name": "web"\n}')"; _b10n_base
_b10n_put projects/web/project.json "$(printf '{\n  "name": "web",\n  "outputPath": "dist"\n}')"; _b10n_feat; _b10n_esc
_b10n_none "b10 A28.4: projects/web/project.json with a key added, the line above gaining a comma, gives ESC nothing (control)"

# ---- C077: a missing secret scan is said, never skipped ---------------------------
_b10n_x() {  # NAME MODE: B10X is a copy of the engine, lib/ and bin/secret-scan at MODE; gone leaves bin/ empty, nobin leaves no bin/
  B10X="$B10N/$1"; _b10n_xw="$_b10n_all"; [ -z "$_b10n_xw" ] || return 0
  if ! { mkdir "$B10X" && cp -R "$_b10n_E/lib" "$B10X/lib"; } 2>/dev/null; then _b10n_xw="the engine copy $1 could not be made"; return 0; fi
  if [ "$2" = nobin ]; then return 0; fi
  mkdir "$B10X/bin" 2>/dev/null || { _b10n_xw="$B10X/bin could not be made"; return 0; }
  if [ "$2" = gone ]; then return 0; fi
  { cp "$_b10n_E/bin/secret-scan" "$B10X/bin/" && chmod "$2" "$B10X/bin/secret-scan"; } 2>/dev/null \
    || _b10n_xw="bin/secret-scan could not be copied into $B10X at mode $2"
}
_b10n_repo a29; _b10n_base; _b10n_put notes/a.txt hello; _b10n_feat; _b10n_R29="$B10R"; _b10n_W29="$_b10n_why"
_b10n_on29() { B10R="$_b10n_R29"; _b10n_why="${_b10n_W29:-$_b10n_xw}"; }
_b10n_x x644 644; _b10n_X644="$B10X"; _b10n_XW644="$_b10n_xw"; _b10n_on29; _b10n_esc main "$B10X"
_b10n_row "b10 A29: an engine copy whose bin/secret-scan is not executable prints unknown ADDED-LINES naming the secret scan" unknown ADDED-LINES 'secret scan'
_b10n_norow "b10 A30: and prints no disclose row (control)" disclose -
_b10n_x xgone gone; _b10n_on29; _b10n_esc main "$B10X"
_b10n_row "b10 A31: an engine copy with no bin/secret-scan prints the same unknown ADDED-LINES row" unknown ADDED-LINES 'secret scan'
_b10n_x xnobin nobin; _b10n_on29; _b10n_esc main "$B10X"
_b10n_row "b10 A32: an engine copy with no bin/ prints the same unknown ADDED-LINES row" unknown ADDED-LINES 'secret scan'
_b10n_xw="$_b10n_XW644"; _b10n_on29; _b10n_blk "$_b10n_X644"
_b10n_nm="b10 A33: BLK from that copy's six libs prints unknown ADDED-LINES and no line of kind escape"
if _b10n_fx "$_b10n_nm"; then
  if [ "$(_b10n_n unknown ADDED-LINES)" -gt 0 ] && [ "$(_b10n_n escape -)" -eq 0 ]; then ok "$_b10n_nm"; else bad "$_b10n_nm" "$(_b10n_said)"; fi
fi
_b10n_x x755 755; _b10n_on29; _b10n_esc main "$B10X"
_b10n_norow "b10 A34: an engine copy whose scanner is executable prints no unknown row on the same branch (control)" unknown -
_b10n_repo a35; _b10n_base; _b10n_why="${_b10n_why:-$_b10n_XW644}"; _b10n_esc main "$_b10n_X644"
_b10n_none "b10 A35: the copy whose scanner is not executable, on a branch that changes nothing, gives ESC nothing (control)"

# ---- structure -----------------------------------------------------------------
_b10n_lines() {  # NAME FILE MAX
  local n="no file"; [ ! -f "$2" ] || n="$(awk 'END { print NR }' "$2")"
  case "$n" in ''|*[!0123456789]*) bad "$1" "[$2]: $n" ;; *) if [ "$n" -le "$3" ]; then ok "$1"; else bad "$1" "it has $n lines"; fi ;; esac
}
_b10n_lines "b10 A36: engine/harness/lib/escape.sh has at most 799 lines (control)" "$REAL_HARNESS/lib/escape.sh" 799
_b10n_lines "b10 A37: engine/harness/lib/classify.sh has at most 500 lines (control)" "$REAL_HARNESS/lib/classify.sh" 500
_b10n_n38="b10 A38: escape.sh loads lib/escape-channels.sh itself"
_b10n_n39="b10 A39: felix_land_trust_base engine/harness/lib/escape-channels.sh exits 0"
_b10n_n40="b10 A40: without lib/escape-channels.sh, escape.sh still defines felix_escapes and felix_merge_blockers, and the deploy fixture gets unknown CHANGED-PATHS"
if [ ! -f "$_b10n_E/lib/escape-channels.sh" ]; then
  for _b10n_nm in "$_b10n_n38" "$_b10n_n39" "$_b10n_n40"; do skip "$_b10n_nm" "the build added no lib/escape-channels.sh"; done
else
  _b10n_why="$_b10n_all"; _b10n_out=""; _b10n_rc=125
  if [ -z "$_b10n_why" ]; then
    { mkdir "$B10N/x38" && cp -R "$_b10n_E/lib" "$B10N/x38/lib" \
        && { printf 'B10N_MARK=loaded\n'; cat "$_b10n_E/lib/escape-channels.sh"; } > "$B10N/x38/lib/escape-channels.sh"; } 2>/dev/null \
      || _b10n_why="the marked copy of lib could not be made"
  fi
  [ -n "$_b10n_why" ] || _b10n_sh 30 "$B10N" '. "$1/lib/escape.sh" >/dev/null 2>&1; printf "%s\n" "${B10N_MARK-unset}"' "$B10N/x38"
  _b10n_fx "$_b10n_n38" && is "$_b10n_n38" "$_b10n_out" "loaded"
  _b10n_why="$_b10n_all"; _b10n_sh 30 "$B10N" '. "$1/lib/land-table.sh" >/dev/null 2>&1
    felix_land_trust_base engine/harness/lib/escape-channels.sh >/dev/null 2>&1; printf "%s\n" "$?"' "$_b10n_E"
  _b10n_fx "$_b10n_n39" && is "$_b10n_n39" "$_b10n_out" "0"
  _b10n_repo a40
  _b10n_put .github/workflows/deploy.yml "$(printf 'on:\n  push:\n    branches: [main]\njobs:\n  deploy:\n    runs-on: ubuntu-latest\n    environment: production\n    steps:\n      - uses: actions/checkout@v4\n      - run: ./scripts/deploy.sh')"
  _b10n_put scripts/deploy.sh 'echo deploy'; _b10n_base; _b10n_add scripts/deploy.sh 'echo deploy to production'; _b10n_feat
  if [ -z "$_b10n_why" ]; then
    { mkdir "$B10N/x40" && cp -R "$_b10n_E/lib" "$B10N/x40/lib" && rm -f "$B10N/x40/lib/escape-channels.sh"; } 2>/dev/null \
      && [ ! -e "$B10N/x40/lib/escape-channels.sh" ] || _b10n_why="the copy of lib without escape-channels.sh could not be made"
  fi
  _b10n_out=""; _b10n_rc=125
  [ -n "$_b10n_why" ] || _b10n_sh 90 "$B10R" '. "$1/lib/escape.sh" >/dev/null 2>&1
    { type felix_escapes && type felix_merge_blockers; } >/dev/null 2>&1 || { echo "a function is not defined"; exit 0; }
    felix_escapes "$2" main "$3" ""' "$B10N/x40" "$_b10n_P" "$B10R"
  _b10n_row "$_b10n_n40" unknown CHANGED-PATHS
fi
