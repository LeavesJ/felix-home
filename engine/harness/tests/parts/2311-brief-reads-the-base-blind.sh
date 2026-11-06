printf '\nthe brief reads the base: felix brief and felix incident read project.json at main, as felix evidence and felix merge take it, HEAD the fallback (contract 2026-11-06, amendments Q1 to Q9, blind)\n'
# Blind, written on 2026-11-06 from docs/2026-11-06-brief-reads-the-declaration-contract.md alone: D4 as amended and the
# section "Amendments (2026-11-06, after the adversarial review of the first part)", Q1 to Q9. No engine code was read:
# felix, lib/, hooks/ and bin/ were not opened and their history was not read. Every command is driven as a black box.
# The test code read: tests/run and its fixture helpers (parts 0002, 0004, 0007, 1040, lib/widget-repo.sh) and part
# 2310, whose fixture ideas and helpers are copied here, since parts run alone. Every name starts "brief-base " and is
# emitted on every run; a state that cannot be built skips its names and says why. On 26b918d9, the engine that reads
# the declaration at HEAD, the contract's red ones fail: Q1 and Q2 (brief, incident and the agreement of the four) and
# Q5 (brief and incident). Every Q9 arm and every Q3, Q4, Q6, Q7 and Q8 assertion holds there.
#
# Readings, where the contract leaves room:
# - H is a Felix home that is the repository the commands run in (FELIX_HOME at its root, as part 2310's H):
#   projects/widget holds the widget's tables, an evidence.tsv of one row, unit, whose when cell ^src/ the path
#   src/thing.js meets, and a project.json; .felix names widget; WIDGET.txt and src/thing.js stand at the root. Its
#   first commit is on main; the branch work is cut from it and one commit there changes src/thing.js (Q2's commit also
#   puts R4 over the declaration, as Q2 says). The good declaration is D2's G1, evidence_vendored vendor/; the bad one
#   is R4, evidence_vendored the number 3. W, for Q6 only, is the suite's widget project, outside the widget checkout
#   and in no repository, so its declaration is read from the disk; its change is on a branch of this part's own,
#   bbase-work, with refs/heads/bbase-base at its first commit, both removed after.
# - What a state holds is read from git (git show REV:projects/widget/project.json for main, HEAD, origin/main) and
#   from the disk, and named R4, G1, N (neither key), other, or none (no such file at that commit).
# - The reason is the text after "[?] project.json" and its blanks on felix evidence's line, read at the base the
#   assertion names: --base main for Q1, Q6 H, Q7 and Q8 (main resolves to the local main, there being no remote);
#   --base HEAD for Q3; --base origin/main for Q5; --base refs/heads/bbase-base in W. A section is the lines after its
#   heading (what a fix must prove; the fix will have to prove) up to the first blank line, a row its first word and
#   the rest after the blanks, as in 2310; "exactly the project.json row" is the section being that one row, so no
#   heading, a heading over nothing, a second row or another reason fails it. "The ordinary rows" is unit alone.
# - felix merge --base main --dry-run is read for Q1, Q2, Q6 H and Q8, by its lines whose first word is evidence and
#   nothing else, given no receipt. It is not read on an unborn HEAD (Q4, Q5), where it cannot name the branch to merge
#   (D6's last sentence); Q3 has no main to merge against. Every branch read is a named branch.
# - Q7 runs felix brief and felix incident from src/ and from the top, and says both. Q6 names W and H both.
# - Q5 is skipped by name when git cannot fetch the commit; Q4 when git init cannot run.
#
# Every part runs alone: this one makes the widget checkout's first commit with _widget_repo_build, keeps the widget's
# evidence.tsv and project.json and puts them back, returns the checkout to the branch it found and deletes its refs,
# and makes every other fixture under $TMP/bbase, which it removes.

BB="$TMP/bbase"; mkdir -p "$BB"
_widget_repo_build
_bb_wp="$FROOT/projects/widget"
for _bb_f in evidence.tsv project.json; do
  rm -f "$BB/$_bb_f.keep"; [ -f "$_bb_wp/$_bb_f" ] && cp "$_bb_wp/$_bb_f" "$BB/$_bb_f.keep"
done
_bb_TT="$(printf 'unit\t^src/\t^tests/\tcode changes need a test')"
_bb_U="$(printf 'unit\tcode changes need a test')"
_bb_why=""; BB_D=""; BB_E=""; BB_EH=""; BB_ML=""; BB_B=""; BB_I=""; BB_R=""; BB_RH=""

# NAME GOT WANT: is, or a skip by NAME while _bb_why says why the state could not be built.
_bb_is() { if [ -n "$_bb_why" ]; then skip "$1" "$_bb_why"; else is "$1" "$2" "$3"; fi; }
# TEXT AWK-CONDITION: how many lines of TEXT, split on blanks, meet the condition.
_bb_c() { printf '%s\n' "$1" | LC_ALL=C awk "$2"' { n++ } END { print n + 0 }'; }
# STATE: the line STATE writes after project.json's opening brace (nothing for N).
_bb_key() {
  case "$1" in
    R4) printf '%s' '"evidence_vendored": 3' ;;
    G1) printf '%s' '"evidence_vendored": "vendor/"' ;;
  esac
}
# STATE: the widget's project.json as this part found it, with STATE's line and a comma after its opening brace.
_bb_pj() {
  local k
  k="$(_bb_key "$1")"
  if [ -z "$k" ]; then cat "$BB/project.json.keep"; return 0; fi
  BB_K="$k" LC_ALL=C awk '!d && index($0, "{") { i = index($0, "{"); print substr($0, 1, i); print "  " ENVIRON["BB_K"] ","
                            r = substr($0, i + 1); if (r != "") print r; d = 1; next } { print }' "$BB/project.json.keep"
}
# TEXT: which declaration TEXT, a project.json, holds: R4, G1, N (neither key), other, or none when TEXT is empty.
_bb_dw() {
  case "$1" in
    "") printf none ;;
    *'"evidence_vendored": 3'*) printf R4 ;;
    *'"evidence_vendored": "vendor/"'*) printf G1 ;;
    *evidence_vendored*|*evidence_reads_vendored*) printf other ;;
    *) printf N ;;
  esac
}
# DIR REV: the declaration REV's projects/widget/project.json holds in DIR's repository; DIR: the one on DIR's disk.
_bb_at() { _bb_dw "$(_fx_git "$1" show "$2:projects/widget/project.json" 2>/dev/null)"; }
_bb_disk() { _bb_dw "$(cat "$1/projects/widget/project.json" 2>/dev/null)"; }
# DIR: the branch HEAD names, or (none); DIR REV: yes when REV names a commit in DIR's repository.
_bb_br() { _fx_git "$1" symbolic-ref -q --short HEAD 2>/dev/null || printf '(none)'; }
_bb_rv() { if _fx_git "$1" rev-parse -q --verify "$2^{commit}" >/dev/null 2>&1; then printf yes; else printf no; fi; }
_bb_anc() { if _fx_git "$1" merge-base --is-ancestor main HEAD >/dev/null 2>&1; then printf yes; else printf no; fi; }
# STDIN lines -> one line, blank-separated.
_bb_j() { LC_ALL=C awk '{ printf "%s%s", (NR > 1 ? " " : ""), $0 }'; }
# DIR [PREFIX]: the refs under PREFIX (every ref without one), short names; DIR: its remotes.
_bb_refs() { _fx_git "$1" for-each-ref --format='%(refname:short)' ${2:+"$2"} 2>/dev/null | _bb_j; }
_bb_rem() { _fx_git "$1" remote 2>/dev/null | _bb_j; }
# DIR: the paths the change on HEAD names against main.
_bb_chg() { _fx_git "$1" diff --name-only main...HEAD 2>/dev/null | _bb_j; }
# DIR STATE: projects/widget of a home in DIR, the widget's tables, the one-row evidence.tsv and STATE's project.json.
_bb_proj() {
  local f
  mkdir -p "$1/projects/widget"
  for f in CLAUDE.md commissioning.tsv obligations.tsv probes.tsv risk.tsv; do
    [ ! -f "$_bb_wp/$f" ] || cp "$_bb_wp/$f" "$1/projects/widget/$f"
  done
  printf '%s\n' "$_bb_TT" > "$1/projects/widget/evidence.tsv"
  _bb_pj "$2" > "$1/projects/widget/project.json"
}
# DIR STATE: the H tree in DIR, uncommitted: _bb_proj, .felix naming widget, WIDGET.txt and src/thing.js.
_bb_tree() {
  _bb_proj "$1" "$2"; mkdir -p "$1/src"
  printf 'widget\n' > "$1/.felix"; printf 'contents\n' > "$1/WIDGET.txt"; printf 'bb base\n' > "$1/src/thing.js"
}
# MSG: everything in the current directory committed with MSG (run inside a _fx_cd subshell).
_bb_ci() { git -c core.excludesFile=/dev/null add -A && git -c user.name=t -c user.email=t@t commit -qm "$1"; }
# NAME: a fresh state: BB_D is $BB/NAME, made, every reading and _bb_why cleared.
_bb_new() {
  _bb_why=""; BB_D="$BB/$1"; rm -rf "$BB_D"; mkdir -p "$BB_D"
  BB_E=""; BB_EH=""; BB_ML=""; BB_B=""; BB_I=""; BB_R=""; BB_RH=""
}
# WHY: after a build, _bb_why says WHY when the build failed (status 1), else BB_D is its physical path.
_bb_built() { if [ "$1" -ne 0 ]; then _bb_why="$2"; else BB_D="$(cd "$BB_D" && pwd -P)"; fi; }
# TEXT: the reason on TEXT's [?] project.json line, or nothing.
_bb_reason() {
  printf '%s\n' "$1" | LC_ALL=C awk '!d && $1 == "[?]" && $2 == "project.json" {
    r = substr($0, index($0, "project.json") + 12); sub(/^ +/, "", r); print r; d = 1 }'
}
# DIR HOME BASE PATHS WHICH: the readers WHICH names, run in DIR with FELIX_HOME HOME, each setting only its own: e,
# felix evidence --base BASE (BB_E, BB_R its reason); h, felix evidence --base HEAD (BB_EH, BB_RH); m, felix merge
# --base BASE --dry-run's evidence lines (BB_ML); b, felix brief given an issue naming PATHS (BB_B); i, felix incident
# given a trace naming them (BB_I). PATHS is one (src/thing.js) or two (src/thing.js and WIDGET.txt).
_bb_read() {
  local iss trc
  if [ "$4" = two ]; then iss='src/thing.js and WIDGET.txt throw when they load'
    trc='Error: boom\n    at run (/home/runner/work/x/x/src/thing.js:44:9)\n    at main (/home/runner/work/x/x/WIDGET.txt:1:1)\n'
  else iss='src/thing.js throws when it loads'; trc='Error: boom\n    at run (/home/runner/work/x/x/src/thing.js:44:9)\n'; fi
  case "$5" in *e*) BB_E="$(cd "$1" && FELIX_HOME="$2" "$FELIX" evidence --base "$3" </dev/null 2>&1)"
                    BB_R="$(_bb_reason "$BB_E")" ;; esac
  case "$5" in *h*) BB_EH="$(cd "$1" && FELIX_HOME="$2" "$FELIX" evidence --base HEAD </dev/null 2>&1)"
                    BB_RH="$(_bb_reason "$BB_EH")" ;; esac
  case "$5" in *m*) BB_ML="$(cd "$1" && FELIX_HOME="$2" "$FELIX" merge --base "$3" --dry-run </dev/null 2>&1 \
                             | LC_ALL=C awk '$1 == "evidence"')" ;; esac
  case "$5" in *b*) BB_B="$(cd "$1" && printf '%s\n' "$iss" | FELIX_HOME="$2" "$FELIX" brief --from - --title t 2>&1)" ;; esac
  case "$5" in *i*) BB_I="$(cd "$1" && printf "$trc" | FELIX_HOME="$2" "$FELIX" incident 2>&1)" ;; esac
  return 0
}
# TEXT HEADING: the rows of TEXT's section under HEADING, NAME<TAB>REASON a line, or a line saying it has no heading.
_bb_sec() {
  case "$1" in
    *"$2"*) printf '%s\n' "$1" | LC_ALL=C awk -v h="$2" 'f == 1 && !NF { f = 2 }
              f == 1 { sub(/^[ \t]+/, ""); n = $1; sub(/^[^ \t]+[ \t]*/, ""); printf "%s\t%s\n", n, $0 }
              !f && index($0, h) == 1 { f = 1 }' ;;
    *) printf '(no heading %s)' "$2" ;;
  esac
}
_bb_bs() { _bb_sec "${1-$BB_B}" 'what a fix must prove'; }
_bb_isec() { _bb_sec "${1-$BB_I}" 'the fix will have to prove'; }
# REASON: the one row project.json with REASON.
_bb_pjr() { printf 'project.json\t%s' "$1"; }
# TEXT: how many [?] project.json lines felix evidence's TEXT holds; REASON: yes when it says not judged.
_bb_pjc() { _bb_c "$1" '$1 == "[?]" && $2 == "project.json"'; }
_bb_nj() { case "$1" in *"not judged"*) printf yes ;; *) printf no ;; esac; }
_bb_mpj() { _bb_c "$BB_ML" '$2 == "project.json"'; }
# TEXT: how many of src/thing.js and WIDGET.txt TEXT lists as a line of their own (the brief's files, the incident's
# implicated files).
_bb_fl() { _bb_c "$1" 'NF == 1 && ($1 == "src/thing.js" || $1 == "WIDGET.txt")'; }
# ROWS: yes when a row of ROWS is named project.json.
_bb_yn() { case "$(_bb_c "$1" '$1 == "project.json"')" in 0) printf no ;; *) printf yes ;; esac; }
# NAME WANT: the four over the current readings, felix evidence's at BASE (BB_E), each yes or no as WANT says.
_bb_agree() {
  _bb_is "$1" "brief $(_bb_yn "$(_bb_bs)"), incident $(_bb_yn "$(_bb_isec)"), evidence $(_bb_yn "$(printf '%s\n' "$BB_E" | LC_ALL=C awk '$1 == "[?]" { print $2 }')"), merge $(_bb_yn "$(printf '%s\n' "$BB_ML" | LC_ALL=C awk '{ print $2 }')")" \
         "brief $2, incident $2, evidence $2, merge $2"
}

# ---- Q1 and Q2: main and HEAD hold different declarations ---------------------------------------------------------
printf '\n  a home on work, cut from main, main and HEAD holding different declarations (Q1, Q2)\n'
_bb_new q1; _bb_tree "$BB_D" G1
( _fx_cd "$BB_D" && git init -q -b main && _bb_ci base && git checkout -q -b work \
  && printf 'bb change\n' > src/thing.js && _bb_ci change && git checkout -q main \
  && _bb_pj R4 > projects/widget/project.json && _bb_ci 'main commits a bad declaration' && git checkout -q work ) >/dev/null 2>&1
_bb_built $? "the home whose main moves on to commit R4 could not be built under $BB"
[ -n "$_bb_why" ] || _bb_read "$BB_D" "$BB_D" main one ehmbi
_bb_is "brief-base Q9 arm Q1: the home is on work, cut from main, whose change names src/thing.js alone; main has moved on to commit R4 and HEAD holds a good declaration; felix evidence --base main prints [?] project.json saying not judged and --base HEAD none, and felix merge --base main --dry-run lists an evidence line naming project.json" \
       "on $(_bb_br "$BB_D"), main $(_bb_at "$BB_D" main), HEAD $(_bb_at "$BB_D" HEAD), disk $(_bb_disk "$BB_D"), the change names [$(_bb_chg "$BB_D")], main an ancestor of HEAD $(_bb_anc "$BB_D"), evidence --base main [?] project.json $(_bb_pjc "$BB_E") (not judged $(_bb_nj "$BB_R")), --base HEAD [?] project.json $(_bb_pjc "$BB_EH"), merge evidence project.json $(_bb_mpj)" \
       "on work, main R4, HEAD G1, disk G1, the change names [src/thing.js], main an ancestor of HEAD no, evidence --base main [?] project.json 1 (not judged yes), --base HEAD [?] project.json 0, merge evidence project.json 1"
_bb_is "brief-base Q1 brief: main holds R4 and HEAD a good declaration: under what a fix must prove felix brief prints exactly one row, project.json, whose reason is felix evidence --base main's byte for byte" \
       "$(_bb_bs)" "$(_bb_pjr "$BB_R")"
_bb_is "brief-base Q1 incident: main holds R4 and HEAD a good declaration: under the fix will have to prove felix incident prints exactly one row, project.json, whose reason is felix evidence --base main's byte for byte" \
       "$(_bb_isec)" "$(_bb_pjr "$BB_R")"
_bb_agree "brief-base Q1 agree: main holds R4 and HEAD a good declaration: felix brief, felix incident, felix evidence --base main and felix merge --base main --dry-run all four name project.json" yes

_bb_new q2; _bb_tree "$BB_D" G1
( _fx_cd "$BB_D" && git init -q -b main && _bb_ci base && git checkout -q -b work \
  && printf 'bb change\n' > src/thing.js && _bb_pj R4 > projects/widget/project.json && _bb_ci 'work commits a bad declaration' ) >/dev/null 2>&1
_bb_built $? "the home whose work commits R4 over main's good declaration could not be built under $BB"
[ -n "$_bb_why" ] || _bb_read "$BB_D" "$BB_D" main one ehmbi
_bb_is "brief-base Q9 arm Q2: the home is on work, cut from main, whose commit puts R4 over main's good declaration; felix evidence --base main prints no [?] project.json and --base HEAD one saying not judged, and felix merge --base main --dry-run lists no evidence line naming project.json" \
       "on $(_bb_br "$BB_D"), main $(_bb_at "$BB_D" main), HEAD $(_bb_at "$BB_D" HEAD), disk $(_bb_disk "$BB_D"), main an ancestor of HEAD $(_bb_anc "$BB_D"), evidence --base main [?] project.json $(_bb_pjc "$BB_E"), --base HEAD [?] project.json $(_bb_pjc "$BB_EH") (not judged $(_bb_nj "$BB_RH")), merge evidence project.json $(_bb_mpj)" \
       "on work, main G1, HEAD R4, disk R4, main an ancestor of HEAD yes, evidence --base main [?] project.json 0, --base HEAD [?] project.json 1 (not judged yes), merge evidence project.json 0"
_bb_is "brief-base Q2 brief: main holds a good declaration and HEAD R4: the branch is judged by the base's, so felix brief prints the table's row, unit alone, and no project.json row" \
       "$(_bb_bs)" "$_bb_U"
_bb_is "brief-base Q2 incident: main holds a good declaration and HEAD R4: the branch is judged by the base's, so felix incident prints the table's row, unit alone, and no project.json row" \
       "$(_bb_isec)" "$_bb_U"
_bb_agree "brief-base Q2 agree: main holds a good declaration and HEAD R4: none of felix brief, felix incident, felix evidence --base main and felix merge --base main --dry-run names project.json" no

# ---- Q3: no main resolves, HEAD the fallback ------------------------------------------------------------------------
printf '\n  a home whose only branch is work, no remote, so no main resolves (Q3)\n'
for _bb_s in R4 G1; do
  _bb_new "q3$_bb_s"; _bb_tree "$BB_D" "$_bb_s"
  ( _fx_cd "$BB_D" && git init -q -b work && _bb_ci base && printf 'bb change\n' > src/thing.js && _bb_ci change ) >/dev/null 2>&1
  _bb_built $? "a home whose only branch is work could not be built under $BB"
  [ -n "$_bb_why" ] || _bb_read "$BB_D" "$BB_D" main one ehbi
  _bb_x="on $(_bb_br "$BB_D"), branches [$(_bb_refs "$BB_D" refs/heads)], remotes [$(_bb_rem "$BB_D")], main resolves $(_bb_rv "$BB_D" main), origin/main resolves $(_bb_rv "$BB_D" origin/main), HEAD $(_bb_at "$BB_D" HEAD)"
  _bb_y="--base main [?] main $(_bb_c "$BB_E" '$1 == "[?]" && $2 == "main"') [?] project.json $(_bb_pjc "$BB_E")"
  if [ "$_bb_s" = R4 ]; then
    _bb_is "brief-base Q9 arm Q3 bad: the only branch is work and there is no remote, so neither main nor origin/main resolves; HEAD holds R4; felix evidence --base HEAD prints [?] project.json saying not judged, and --base main says main names nothing" \
           "$_bb_x, evidence --base HEAD [?] project.json $(_bb_pjc "$BB_EH") (not judged $(_bb_nj "$BB_RH")), $_bb_y" \
           "on work, branches [work], remotes [], main resolves no, origin/main resolves no, HEAD R4, evidence --base HEAD [?] project.json 1 (not judged yes), --base main [?] main 1 [?] project.json 0"
    _bb_is "brief-base Q3 bad brief: no main resolves and HEAD holds R4: felix brief reads HEAD and prints exactly the project.json row, whose reason is felix evidence --base HEAD's byte for byte" \
           "$(_bb_bs)" "$(_bb_pjr "$BB_RH")"
    _bb_is "brief-base Q3 bad incident: no main resolves and HEAD holds R4: felix incident reads HEAD and prints exactly the project.json row, whose reason is felix evidence --base HEAD's byte for byte" \
           "$(_bb_isec)" "$(_bb_pjr "$BB_RH")"
  else
    _bb_is "brief-base Q9 arm Q3 good: the only branch is work and there is no remote, so neither main nor origin/main resolves; HEAD holds a good declaration; felix evidence --base HEAD prints no [?] project.json, and --base main says main names nothing" \
           "$_bb_x, evidence --base HEAD [?] project.json $(_bb_pjc "$BB_EH"), $_bb_y" \
           "on work, branches [work], remotes [], main resolves no, origin/main resolves no, HEAD G1, evidence --base HEAD [?] project.json 0, --base main [?] main 1 [?] project.json 0"
    _bb_is "brief-base Q3 good brief: no main resolves and HEAD holds a good declaration: felix brief prints the table's row, unit alone" \
           "$(_bb_bs)" "$_bb_U"
    _bb_is "brief-base Q3 good incident: no main resolves and HEAD holds a good declaration: felix incident prints the table's row, unit alone" \
           "$(_bb_isec)" "$_bb_U"
  fi
done

# ---- Q4 and Q5: an unborn HEAD ------------------------------------------------------------------------------------
printf '\n  a home with an unborn HEAD, with no main and with an origin/main (Q4, Q5)\n'
_bb_new q4; _bb_tree "$BB_D" R4
( _fx_cd "$BB_D" && git init -q -b main ) >/dev/null 2>&1
_bb_built $? "git init could not make a repository with an unborn HEAD under $BB"
[ -n "$_bb_why" ] || _bb_read "$BB_D" "$BB_D" main one ehbi
_bb_is "brief-base Q9 arm Q4: git init and nothing committed: HEAD is unborn, no ref and no remote exist, the disk holds R4, and felix evidence prints no [?] project.json over --base main or --base HEAD" \
       "HEAD resolves $(_bb_rv "$BB_D" HEAD), refs [$(_bb_refs "$BB_D")], remotes [$(_bb_rem "$BB_D")], disk $(_bb_disk "$BB_D"), evidence --base main [?] project.json $(_bb_pjc "$BB_E"), --base HEAD [?] project.json $(_bb_pjc "$BB_EH")" \
       "HEAD resolves no, refs [], remotes [], disk R4, evidence --base main [?] project.json 0, --base HEAD [?] project.json 0"
_bb_is "brief-base Q4 brief: an unborn HEAD and no main, R4 on the disk: nothing is declared, so felix brief prints the table's row, unit alone, and no project.json row" \
       "$(_bb_bs)" "$_bb_U"
_bb_is "brief-base Q4 incident: an unborn HEAD and no main, R4 on the disk: nothing is declared, so felix incident prints the table's row, unit alone, and no project.json row" \
       "$(_bb_isec)" "$_bb_U"

_bb_new q5s; _bb_tree "$BB_D" R4
( _fx_cd "$BB_D" && git init -q -b main && _bb_ci 'origin commits a bad declaration' ) >/dev/null 2>&1
_bb_built $? "the repository origin/main is fetched from could not be built under $BB"; _bb_src="$BB_D"; _bb_sw="$_bb_why"
_bb_new q5; _bb_why="$_bb_sw"; _bb_tree "$BB_D" G1
if [ -z "$_bb_why" ]; then
  ( _fx_cd "$BB_D" && git init -q -b main && git remote add origin "$_bb_src" && git fetch -q origin ) >/dev/null 2>&1
  _bb_built $? "git could not init a repository and fetch origin/main into it under $BB"
fi
[ -n "$_bb_why" ] || [ "$(_bb_rv "$BB_D" refs/remotes/origin/main)" = yes ] || _bb_why="the fetch left no origin/main"
[ -n "$_bb_why" ] || _bb_read "$BB_D" "$BB_D" origin/main one ebi
_bb_is "brief-base Q9 arm Q5: HEAD is unborn and no local branch exists, origin/main resolves and holds R4, the disk holds a good declaration, and felix evidence --base origin/main prints [?] project.json saying not judged" \
       "HEAD resolves $(_bb_rv "$BB_D" HEAD), branches [$(_bb_refs "$BB_D" refs/heads)], remotes [$(_bb_rem "$BB_D")], origin/main resolves $(_bb_rv "$BB_D" refs/remotes/origin/main), origin/main $(_bb_at "$BB_D" refs/remotes/origin/main), disk $(_bb_disk "$BB_D"), evidence --base origin/main [?] project.json $(_bb_pjc "$BB_E") (not judged $(_bb_nj "$BB_R"))" \
       "HEAD resolves no, branches [], remotes [origin], origin/main resolves yes, origin/main R4, disk G1, evidence --base origin/main [?] project.json 1 (not judged yes)"
_bb_is "brief-base Q5 brief: an unborn HEAD whose origin/main holds R4: felix brief reads origin/main and prints exactly the project.json row, whose reason is felix evidence --base origin/main's byte for byte" \
       "$(_bb_bs)" "$(_bb_pjr "$BB_R")"
_bb_is "brief-base Q5 incident: an unborn HEAD whose origin/main holds R4: felix incident reads origin/main and prints exactly the project.json row, whose reason is felix evidence --base origin/main's byte for byte" \
       "$(_bb_isec)" "$(_bb_pjr "$BB_R")"

# ---- Q6 H and Q7: two paths, and a subdirectory ---------------------------------------------------------------------
printf '\n  a home on work, main and HEAD holding one declaration: two paths, and from src/ (Q6 H, Q7)\n'
for _bb_s in R4 G1; do
  _bb_new "q67$_bb_s"; _bb_tree "$BB_D" "$_bb_s"
  ( _fx_cd "$BB_D" && git init -q -b main && _bb_ci base && git checkout -q -b work \
    && printf 'bb change\n' > src/thing.js && _bb_ci change ) >/dev/null 2>&1
  _bb_built $? "the home on work with $_bb_s committed could not be built under $BB"
  if [ "$_bb_s" = R4 ]; then
    [ -n "$_bb_why" ] || _bb_read "$BB_D" "$BB_D" main two embi
    _bb_is "brief-base Q9 arm Q6 H: the home is on work, main, HEAD and the disk each hold R4, felix evidence --base main prints [?] project.json saying not judged, felix merge --base main --dry-run lists an evidence line naming project.json, and felix brief and felix incident each implicate both src/thing.js and WIDGET.txt" \
           "on $(_bb_br "$BB_D"), main $(_bb_at "$BB_D" main), HEAD $(_bb_at "$BB_D" HEAD), disk $(_bb_disk "$BB_D"), evidence --base main [?] project.json $(_bb_pjc "$BB_E") (not judged $(_bb_nj "$BB_R")), merge evidence project.json $(_bb_mpj), brief files $(_bb_fl "$BB_B"), incident files $(_bb_fl "$BB_I")" \
           "on work, main R4, HEAD R4, disk R4, evidence --base main [?] project.json 1 (not judged yes), merge evidence project.json 1, brief files 2, incident files 2"
    _bb_is "brief-base Q6 H brief: an issue naming src/thing.js and WIDGET.txt under R4 committed: felix brief prints exactly one row, project.json, whose reason is felix evidence --base main's byte for byte, not one a path and not none" \
           "$(_bb_bs)" "$(_bb_pjr "$BB_R")"
    _bb_is "brief-base Q6 H incident: a trace naming src/thing.js and WIDGET.txt under R4 committed: felix incident prints exactly one row, project.json, whose reason is felix evidence --base main's byte for byte, not one a path and not none" \
           "$(_bb_isec)" "$(_bb_pjr "$BB_R")"
    [ -n "$_bb_why" ] || _bb_pj G1 > "$BB_D/projects/widget/project.json"
    _bb_q=bad; _bb_qd='with R4 committed and the working tree'"'"'s file fixed'
  else
    [ -n "$_bb_why" ] || _bb_pj R4 > "$BB_D/projects/widget/project.json"
    _bb_q=good; _bb_qd='with a good declaration committed and R4 an uncommitted edit'
  fi
  # Q7: from src/, then from the top.
  BB_E=""; BB_B=""; BB_I=""; BB_R=""; _bb_sb=""; _bb_si=""
  if [ -z "$_bb_why" ]; then
    _bb_read "$BB_D/src" "$BB_D" main one bi; _bb_sb="$BB_B"; _bb_si="$BB_I"
    _bb_read "$BB_D" "$BB_D" main one ebi
  fi
  _bb_x="on $(_bb_br "$BB_D"), main $(_bb_at "$BB_D" main), HEAD $(_bb_at "$BB_D" HEAD), disk $(_bb_disk "$BB_D"), the top from src/ is the home $( [ -n "$_bb_why" ] || [ "$(_fx_git "$BB_D/src" rev-parse --show-toplevel 2>/dev/null)" != "$BB_D" ] && printf no || printf yes ), evidence --base main [?] project.json $(_bb_pjc "$BB_E")"
  if [ "$_bb_q" = bad ]; then
    _bb_is "brief-base Q9 arm Q7 bad: the home is on work, main and HEAD hold R4 and the working tree's project.json is fixed, src/ is a subdirectory whose repository top is the home, and felix evidence --base main prints [?] project.json saying not judged" \
           "$_bb_x (not judged $(_bb_nj "$BB_R"))" \
           "on work, main R4, HEAD R4, disk G1, the top from src/ is the home yes, evidence --base main [?] project.json 1 (not judged yes)"
    _bb_w="$(_bb_pjr "$BB_R")"; _bb_wd='exactly the project.json row, felix evidence --base main'"'"'s reason byte for byte'
  else
    _bb_is "brief-base Q9 arm Q7 good: the home is on work, main and HEAD hold a good declaration and the working tree's project.json holds R4 uncommitted, src/ is a subdirectory whose repository top is the home, and felix evidence --base main prints no [?] project.json" \
           "$_bb_x" \
           "on work, main G1, HEAD G1, disk R4, the top from src/ is the home yes, evidence --base main [?] project.json 0"
    _bb_w="$_bb_U"; _bb_wd="the table's row, unit alone"
  fi
  _bb_is "brief-base Q7 $_bb_q brief: from src/, $_bb_qd, felix brief prints $_bb_wd, the same as from the top" \
         "from src/ [$(_bb_bs "$_bb_sb")] from the top [$(_bb_bs)]" "from src/ [$_bb_w] from the top [$_bb_w]"
  _bb_is "brief-base Q7 $_bb_q incident: from src/, $_bb_qd, felix incident prints $_bb_wd, the same as from the top" \
         "from src/ [$(_bb_isec "$_bb_si")] from the top [$(_bb_isec)]" "from src/ [$_bb_w] from the top [$_bb_w]"
done

# ---- Q8: the home a repository of its own, the commands in another ------------------------------------------------
printf '\n  a home that is a repository of its own, the commands run in another (Q8)\n'
_bb_new q8h; _bb_proj "$BB_D" G1
( _fx_cd "$BB_D" && git init -q -b main && _bb_ci 'the home commits a good declaration' ) >/dev/null 2>&1
_bb_built $? "the home repository could not be built under $BB"; _bb_hh="$BB_D"; _bb_sw="$_bb_why"
[ -n "$_bb_why" ] || _bb_pj R4 > "$_bb_hh/projects/widget/project.json"
_bb_new q8c; _bb_why="$_bb_sw"; mkdir -p "$BB_D/src"
printf 'widget\n' > "$BB_D/.felix"; printf 'contents\n' > "$BB_D/WIDGET.txt"; printf 'bb base\n' > "$BB_D/src/thing.js"
if [ -z "$_bb_why" ]; then
  ( _fx_cd "$BB_D" && git init -q -b main && _bb_ci base && git checkout -q -b work \
    && printf 'bb change\n' > src/thing.js && _bb_ci change ) >/dev/null 2>&1
  _bb_built $? "the checkout repository could not be built under $BB"
fi
[ -n "$_bb_why" ] || _bb_read "$BB_D" "$_bb_hh" main one embi
_bb_x="inside the checkout no"; case "$_bb_hh/projects/widget/" in "$BB_D/"*) _bb_x="inside the checkout yes" ;; esac
_bb_is "brief-base Q9 arm Q8: the home is a repository of its own whose HEAD holds a good declaration and whose disk holds R4 uncommitted, the commands run on work in another repository, which does not hold the project directory, felix evidence --base main prints [?] project.json saying not judged, and felix merge --base main --dry-run lists an evidence line naming project.json" \
       "home top the home $( [ "$(_fx_git "$_bb_hh" rev-parse --show-toplevel 2>/dev/null)" = "$_bb_hh" ] && printf yes || printf no ), home HEAD $(_bb_at "$_bb_hh" HEAD), home disk $(_bb_disk "$_bb_hh"), checkout top the checkout $( [ -n "$BB_D" ] && [ "$(_fx_git "$BB_D" rev-parse --show-toplevel 2>/dev/null)" = "$BB_D" ] && printf yes || printf no ), project directory $_bb_x, on $(_bb_br "$BB_D"), evidence --base main [?] project.json $(_bb_pjc "$BB_E") (not judged $(_bb_nj "$BB_R")), merge evidence project.json $(_bb_mpj)" \
       "home top the home yes, home HEAD G1, home disk R4, checkout top the checkout yes, project directory inside the checkout no, on work, evidence --base main [?] project.json 1 (not judged yes), merge evidence project.json 1"
_bb_is "brief-base Q8 brief: the project directory is not inside the repository the command runs in, so the disk's R4 is read: felix brief prints exactly the project.json row, whose reason is felix evidence's byte for byte" \
       "$(_bb_bs)" "$(_bb_pjr "$BB_R")"
_bb_is "brief-base Q8 incident: the project directory is not inside the repository the command runs in, so the disk's R4 is read: felix incident prints exactly the project.json row, whose reason is felix evidence's byte for byte" \
       "$(_bb_isec)" "$(_bb_pjr "$BB_R")"
_bb_agree "brief-base Q8 agree: the home's disk holds R4 and its commit a good declaration: felix brief, felix incident, felix evidence --base main and felix merge --base main --dry-run all four name project.json" yes

# ---- Q6 W: the widget project, two paths, its declaration on the disk -----------------------------------------------
printf '\n  the widget project, outside the checkout, its declaration on the disk: two paths (Q6 W)\n'
_bb_new w; BB_D="$REPO"
_bb_wb="$(_fx_git "$REPO" symbolic-ref -q HEAD 2>/dev/null)"; _bb_wh="$(_fx_git "$REPO" rev-parse -q --verify HEAD 2>/dev/null)"
( _fx_cd "$REPO" && git checkout -q -b bbase-work && mkdir -p src && printf 'bbase base\n' > src/thing.js \
  && git add -- src/thing.js && git -c user.name=t -c user.email=t@t commit -qm 'bbase base' \
  && git update-ref refs/heads/bbase-base HEAD && printf 'bbase change\n' > src/thing.js \
  && git add -- src/thing.js && git -c user.name=t -c user.email=t@t commit -qm 'bbase change' ) >/dev/null 2>&1 \
  || _bb_why="the widget checkout's change could not be committed on a branch of this part's own"
_bb_pj R4 > "$_bb_wp/project.json"; printf '%s\n' "$_bb_TT" > "$_bb_wp/evidence.tsv"
[ -n "$_bb_why" ] || _bb_read "$REPO" "$FROOT" refs/heads/bbase-base two ebi
_bb_x="inside the checkout no"; case "$_bb_wp/" in "$REPO/"*) _bb_x="inside the checkout yes" ;; esac
_bb_is "brief-base Q9 arm Q6 W: the widget's project directory is not inside the checkout nor in any repository and its disk holds R4, felix evidence prints [?] project.json saying not judged, and felix brief and felix incident each implicate both src/thing.js and WIDGET.txt" \
       "$_bb_x, a repository [$(_fx_git "$_bb_wp" rev-parse --show-toplevel 2>/dev/null)], disk $(_bb_dw "$(cat "$_bb_wp/project.json" 2>/dev/null)"), evidence [?] project.json $(_bb_pjc "$BB_E") (not judged $(_bb_nj "$BB_R")), brief files $(_bb_fl "$BB_B"), incident files $(_bb_fl "$BB_I")" \
       "inside the checkout no, a repository [], disk R4, evidence [?] project.json 1 (not judged yes), brief files 2, incident files 2"
_bb_is "brief-base Q6 W brief: an issue naming src/thing.js and WIDGET.txt under R4 on the disk: felix brief prints exactly one row, project.json, whose reason is felix evidence's byte for byte, not one a path and not none" \
       "$(_bb_bs)" "$(_bb_pjr "$BB_R")"
_bb_is "brief-base Q6 W incident: a trace naming src/thing.js and WIDGET.txt under R4 on the disk: felix incident prints exactly one row, project.json, whose reason is felix evidence's byte for byte, not one a path and not none" \
       "$(_bb_isec)" "$(_bb_pjr "$BB_R")"
_bb_why=""

# The widget checkout and tables, as this part found them, and nothing of this part's left under $TMP.
if [ -n "$_bb_wb" ]; then ( _fx_cd "$REPO" && git checkout -q "${_bb_wb#refs/heads/}" ) >/dev/null 2>&1
elif [ -n "$_bb_wh" ]; then ( _fx_cd "$REPO" && git checkout -q --detach "$_bb_wh" ) >/dev/null 2>&1; fi
_fx_git "$REPO" branch -q -D bbase-work >/dev/null 2>&1
_fx_git "$REPO" update-ref -d refs/heads/bbase-base >/dev/null 2>&1
for _bb_f in evidence.tsv project.json; do
  if [ -f "$BB/$_bb_f.keep" ]; then cp "$BB/$_bb_f.keep" "$_bb_wp/$_bb_f"; else rm -f "$_bb_wp/$_bb_f"; fi
done
rm -rf "$BB"
unset -f _bb_is _bb_c _bb_key _bb_pj _bb_dw _bb_at _bb_disk _bb_br _bb_rv _bb_anc _bb_j _bb_refs _bb_rem _bb_chg _bb_proj \
         _bb_tree _bb_ci _bb_new _bb_built _bb_reason _bb_read _bb_sec _bb_bs _bb_isec _bb_pjr _bb_pjc _bb_nj _bb_mpj _bb_fl \
         _bb_yn _bb_agree
