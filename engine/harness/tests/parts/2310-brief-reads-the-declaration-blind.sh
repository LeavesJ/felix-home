printf '\nthe brief reads the declaration: felix brief and felix incident print the project.json row felix merge refuses on (contract 2026-11-06, blind)\n'
# Blind, written on 2026-11-06 from docs/2026-11-06-brief-reads-the-declaration-contract.md alone. No engine code was
# read: felix, lib/, hooks/ and bin/ were not opened and their history was not read. Every command is driven as a black
# box, and felix_brief_evidence is called in a shell that sources lib/resolve.sh and lib/intake.sh and nothing else, as
# part 1832's A148 calls it. Every name starts "brief-decl " and is emitted on every run; a state that cannot be built
# skips its names and says why. On main (4c4c0b3d) every arm, every D2, every C1 to C3 assertion, D4 and D5 over an
# uncommitted bad edit, D5 over a good declaration, and D6 over each control hold; D1, D4 and D5 over a bad declaration,
# D6 over each bad declaration, and C4 fail. Part 1832's A149 states the old behaviour (D7) and nothing here leans on it.
#
# Readings, where the contract leaves room:
# - Two fixtures. W is the suite's widget project. Its directory, $FROOT/projects/widget, is not inside the widget
#   checkout the commands run in, so its declaration is read from the disk (D4's second case, and C4's project). H is a
#   Felix home that is itself a repository: projects/widget holds the widget's tables, everything is committed, the
#   commands run at its root with FELIX_HOME at it, so the declaration is read from the commit (D4's first case). R6, a
#   committed symbolic link, can only be built in H. W runs R1 to R5 over every table kind; H runs R1 to R5 over the
#   reach kind and R6 over every kind.
# - W's change is on a branch of this part's own, bdecl-work, cut from the checkout's HEAD: one commit adds src/thing.js
#   and vendor/acme/src/a.go, refs/heads/bdecl-base names it, and one commit on top changes both. Each H repository has
#   the same two commits, refs/heads/bd-base at the first. No change edits project.json (D6). felix evidence and felix
#   merge --dry-run read --base that ref; merge is given no receipt, since only its lines whose first word is evidence
#   are read and it lists them whatever else blocks. Merge, the slowest reader (about 2 s), is read once a state, over
#   the reach kind; the other kinds read felix evidence, felix brief and felix incident.
# - felix brief reads on stdin an issue naming PATH, felix incident a trace naming /home/runner/work/x/x/PATH, as part
#   1830 drives them. A section is the lines after its heading (what a fix must prove; the fix will have to prove) up
#   to the first blank line; a row is its first word, the name, and what follows the blanks after it, the reason. D1's
#   "exactly one row named project.json with felix evidence's reason" is the section being exactly that one row, so a
#   heading with nothing under it, or no heading, fails it. The reason is the text after "[?] project.json" and its
#   blanks on felix evidence's line.
# - Table kinds: reach, one row whose when cell src/thing.js meets; noreach, that table and the path WIDGET.txt, which
#   no row reaches; zero, comments and a blank line only; four, the reach row and a row of three cells.
# - D2's good declarations: G1, evidence_vendored vendor/; G2, that and evidence_reads_vendored deps over a table V whose
#   deps row reads ^vendor/. "Changes nothing" is the whole output, byte for byte, against the output with no
#   declaration (N) over the same fixture. D5's "the same lines felix brief puts under its heading" is the function's
#   lines, NAME<TAB>REASON, against the section's rows read as above.
# - C4 is W's R4: the contract lists it among the controls that hold on main, but the brief reads no project.json on
#   main (B11R3-11), so it is red there; it is written as the contract states it.
# - Arming: every state over every kind has an assertion that the declaration is what it says (its text in the file,
#   in the commit for H, mode 120000 in the commit for R6) and that felix evidence prints [?] project.json saying not
#   judged; over the reach kind the same assertion also has felix merge --dry-run list an evidence line naming
#   project.json. Each control's negative follows an arm of its own.
#
# Every part runs alone: this one makes the widget checkout's first commit with _widget_repo_build, keeps the widget's
# evidence.tsv and project.json and puts them back, returns the checkout to the branch it found and deletes its refs,
# and makes every other fixture under $TMP/bdecl.

BD="$TMP/bdecl"; mkdir -p "$BD"
_widget_repo_build
_bd_wp="$FROOT/projects/widget"
for _bd_f in evidence.tsv project.json; do
  rm -f "$BD/$_bd_f.keep"; [ -f "$_bd_wp/$_bd_f" ] && cp "$_bd_wp/$_bd_f" "$BD/$_bd_f.keep"
done
_bd_TT="$(printf 'unit\t^src/\t^tests/\tcode changes need a test')"
_bd_TZ="$(printf '# no evidence rule yet\n\n# a comment and a blank line only')"
_bd_TM="$_bd_TT"$'\n'"$(printf 'deps\t^vendor/\t^vendor/modules\\.txt$')"
_bd_TV="$(printf 'unit\t(^|/)src/\t^tests/\tcode changes need a test\ndeps\t^vendor/\t^vendor/modules\\.txt$\ta vendored change names its modules')"
_bd_U="$(printf 'unit\tcode changes need a test')"
_bd_UD="$_bd_U"$'\n'"$(printf 'deps\ta vendored change names its modules')"
_bd_KINDS="reach noreach zero four"
_bd_ARMED='declaration yes, felix evidence [?] project.json 1 (not judged yes), felix merge --dry-run evidence project.json 1'
_bd_n=0; _bd_why=""; BD_H=""; BD_E=""; BD_M=""; BD_ML=""; BD_B=""; BD_I=""; BD_R=""

# NAME GOT WANT: is, or a skip by NAME while _bd_why says why the state could not be built.
_bd_is() { if [ -n "$_bd_why" ]; then skip "$1" "$_bd_why"; else is "$1" "$2" "$3"; fi; }
# NAME TEXT +PHRASE|-PHRASE...: one assertion that TEXT holds every +PHRASE and no -PHRASE, or a skip as _bd_is.
_bd_hl() {
  local n="$1" t="$2" p miss=""
  shift 2
  for p in "$@"; do
    case "$p" in
      +*) case "$t" in *"${p#+}"*) ;; *) miss="$miss lacks [${p#+}];" ;; esac ;;
      -*) case "$t" in *"${p#-}"*) miss="$miss holds [${p#-}];" ;; esac ;;
    esac
  done
  if [ -n "$_bd_why" ]; then skip "$n" "$_bd_why"
  elif [ -z "$miss" ]; then ok "$n"; else bad "$n" "it$miss in [$t]"; fi
}
# TEXT AWK-CONDITION: how many lines of TEXT, split on blanks, meet the condition.
_bd_c() { printf '%s\n' "$1" | LC_ALL=C awk "$2"' { n++ } END { print n + 0 }'; }
# KIND: the table, the path and the words of a table kind; V is D2's vendor table and path.
_bd_kt() { case "$1" in reach|noreach) printf '%s' "$_bd_TT" ;; zero) printf '%s' "$_bd_TZ" ;; four) printf '%s' "$_bd_TM" ;; V) printf '%s' "$_bd_TV" ;; esac; }
_bd_kp() { case "$1" in noreach) printf 'WIDGET.txt' ;; V) printf 'vendor/acme/src/a.go' ;; *) printf 'src/thing.js' ;; esac; }
_bd_kd() {
  case "$1" in
    reach)   printf 'a table whose row the path src/thing.js reaches' ;;
    noreach) printf 'a table whose one row the path WIDGET.txt does not reach' ;;
    zero)    printf 'a table of zero rows, comments and a blank line only' ;;
    four)    printf 'a table holding a row that is not four cells beside a row the path reaches' ;;
  esac
}
# STATE: the line(s) STATE writes after project.json's opening brace (nothing for N and R6), and its words.
_bd_key() {
  case "$1" in
    R1) printf '%s' '"evidence_reads_vendored": "nosuch"' ;;
    R2) printf '%s' '"evidence_vendored": "/vendor/"' ;;
    R3) printf '%s\n  %s' '"evidence_vendored": "third_party/",' '"evidence_vendored": "x/"' ;;
    R4) printf '%s' '"evidence_vendored": 3' ;;
    R5) printf '%s' '"evidence_vendored": "../shared/"' ;;
    G1) printf '%s' '"evidence_vendored": "vendor/"' ;;
    G2) printf '%s' '"evidence_vendored": "vendor/", "evidence_reads_vendored": "deps"' ;;
  esac
}
_bd_sd() {
  case "$1" in
    R1) printf 'evidence_reads_vendored naming nosuch, no row of evidence.tsv' ;;
    R2) printf 'an evidence_vendored entry that begins with /' ;;
    R3) printf 'evidence_vendored given twice' ;;
    R4) printf 'evidence_vendored a number, not one JSON string' ;;
    R5) printf 'an evidence_vendored entry with a .. component' ;;
    R6) printf 'project.json committed as a symbolic link' ;;
  esac
}
# STATE: the widget's project.json as this part found it, STATE's line(s) and a comma after its opening brace.
_bd_pj() {
  local k
  k="$(_bd_key "$1")"
  if [ -z "$k" ]; then cat "$BD/project.json.keep"; return 0; fi
  BD_K="$k" LC_ALL=C awk '!d && index($0, "{") { i = index($0, "{"); print substr($0, 1, i); print "  " ENVIRON["BD_K"] ","
                            r = substr($0, i + 1); if (r != "") print r; d = 1; next } { print }' "$BD/project.json.keep"
}
# TEXT STATE: yes when TEXT holds STATE's first line.
_bd_has() { local k; k="$(_bd_key "$2" | sed -n 1p)"; case "$1" in *"$k"*) printf yes ;; *) printf no ;; esac; }
# DIR HOME BASE PATH WHICH: the readers WHICH names (e m b i), run in DIR with FELIX_HOME HOME: e, felix evidence over
# BASE (BD_E); m, felix merge --dry-run over BASE (BD_M, and BD_ML its evidence lines); b, felix brief given an issue
# naming PATH (BD_B); i, felix incident given a trace naming it (BD_I). BD_R: the reason felix evidence gives on its
# [?] project.json line, or nothing. felix merge, the slowest, is read once a state, over the reach kind.
_bd_read() {
  BD_E=""; BD_M=""; BD_ML=""; BD_B=""; BD_I=""; BD_R=""
  case "$5" in *e*) BD_E="$(cd "$1" && FELIX_HOME="$2" "$FELIX" evidence --base "$3" </dev/null 2>&1)" ;; esac
  case "$5" in *m*) BD_M="$(cd "$1" && FELIX_HOME="$2" "$FELIX" merge --base "$3" --dry-run </dev/null 2>&1)"
                    BD_ML="$(printf '%s\n' "$BD_M" | LC_ALL=C awk '$1 == "evidence"')" ;; esac
  case "$5" in *b*) BD_B="$(cd "$1" && printf '%s throws when it loads\n' "$4" | FELIX_HOME="$2" "$FELIX" brief --from - --title t 2>&1)" ;; esac
  case "$5" in *i*) BD_I="$(cd "$1" && printf 'Error: boom\n    at run (/home/runner/work/x/x/%s:44:9)\n' "$4" \
                              | FELIX_HOME="$2" "$FELIX" incident 2>&1)" ;; esac
  BD_R="$(printf '%s\n' "$BD_E" | LC_ALL=C awk '!d && $1 == "[?]" && $2 == "project.json" {
            r = substr($0, index($0, "project.json") + 12); sub(/^ +/, "", r); print r; d = 1 }')"
}
# KIND: the readers a state reads over KIND: all four over reach, and every one but felix merge over the others.
_bd_rk() { if [ "$1" = reach ]; then printf embi; else printf ebi; fi; }
# TEXT HEADING: the rows of TEXT's section under HEADING, NAME<TAB>REASON a line, or a line saying it has no heading.
_bd_sec() {
  case "$1" in
    *"$2"*) printf '%s\n' "$1" | LC_ALL=C awk -v h="$2" 'f == 1 && !NF { f = 2 }
              f == 1 { sub(/^[ \t]+/, ""); n = $1; sub(/^[^ \t]+[ \t]*/, ""); printf "%s\t%s\n", n, $0 }
              !f && index($0, h) == 1 { f = 1 }' ;;
    *) printf '(no heading %s)' "$2" ;;
  esac
}
_bd_bs() { _bd_sec "$BD_B" 'what a fix must prove'; }
_bd_isec() { _bd_sec "$BD_I" 'the fix will have to prove'; }
_bd_pjr() { printf 'project.json\t%s' "$BD_R"; }
# ROWS: yes when a row of ROWS is named project.json.
_bd_yn() { case "$(_bd_c "$1" '$1 == "project.json"')" in 0) printf no ;; *) printf yes ;; esac; }
# DECLARED KIND: the arm's reading of the current state, felix merge's clause over the reach kind only; _bd_aw KIND is
# what it must read, and _bd_an KIND the words of the arm's name after felix evidence's.
_bd_arm() {
  local j=no
  case "$BD_R" in *"not judged"*) j=yes ;; esac
  printf 'declaration %s, felix evidence [?] project.json %s (not judged %s)' "$1" "$(_bd_c "$BD_E" '$1 == "[?]" && $2 == "project.json"')" "$j"
  [ "$2" != reach ] || printf ', felix merge --dry-run evidence project.json %s' "$(_bd_c "$BD_ML" '$2 == "project.json"')"
}
_bd_aw() { if [ "$1" = reach ]; then printf '%s' "$_bd_ARMED"; else printf '%s' "${_bd_ARMED%%, felix merge*}"; fi; }
_bd_an() { [ "$1" != reach ] || printf ', and felix merge --dry-run lists an evidence line naming project.json'; }
# NAME: D6 over the current readings: brief, incident and felix evidence name project.json exactly when merge does.
_bd_agree() {
  local m e
  m="$(_bd_yn "$(printf '%s\n' "$BD_ML" | LC_ALL=C awk '{ print $2 }')")"
  e="$(_bd_yn "$(printf '%s\n' "$BD_E" | LC_ALL=C awk '$1 == "[?]" { print $2 }')")"
  _bd_is "$1" "merge $m: brief $(_bd_yn "$(_bd_bs)"), incident $(_bd_yn "$(_bd_isec)"), evidence $e" \
         "merge $m: brief $m, incident $m, evidence $m"
}
# DIR PROJ PATHS [ROOT]: felix_brief_evidence PROJ PATHS [ROOT] in DIR, only lib/resolve.sh and lib/intake.sh sourced.
_bd_lib() {
  local d="$1"
  shift
  ( cd "$d" && bash -c '. "$1/lib/resolve.sh"; . "$1/lib/intake.sh"; shift; felix_brief_evidence "$@"' _ "$FROOT/harness" "$@" ) \
    </dev/null 2>/dev/null
}

# ---- W: the widget project, its declaration on the disk ----------------------------------------------------------
printf '\n  the widget project, outside the checkout, its declaration on the disk (D1, D2, D3, D5, D6, C1 to C4)\n'
_bd_wb="$(_fx_git "$REPO" symbolic-ref -q HEAD 2>/dev/null)"; _bd_wh="$(_fx_git "$REPO" rev-parse -q --verify HEAD 2>/dev/null)"
_bd_wok=""
( _fx_cd "$REPO" && git checkout -q -b bdecl-work && mkdir -p src vendor/acme/src \
  && printf 'bdecl base\n' > src/thing.js && printf 'bdecl base\n' > vendor/acme/src/a.go \
  && git add -- src/thing.js vendor/acme/src/a.go && git -c user.name=t -c user.email=t@t commit -qm 'bdecl base' \
  && git update-ref refs/heads/bdecl-base HEAD \
  && printf 'bdecl change\n' > src/thing.js && printf 'bdecl change\n' > vendor/acme/src/a.go \
  && git add -- src/thing.js vendor/acme/src/a.go && git -c user.name=t -c user.email=t@t commit -qm 'bdecl change' ) \
  >/dev/null 2>&1 && _bd_wok=1
_bd_wy=""; [ -n "$_bd_wok" ] || _bd_wy="the widget checkout's change could not be committed on a branch of this part's own"
# STATE KIND [WHICH]: the widget's project.json STATE's and its evidence.tsv KIND's table, then the readers WHICH names
# (by default _bd_rk's) over KIND's path.
_bd_w() {
  _bd_why="$_bd_wy"; BD_E=""; BD_M=""; BD_ML=""; BD_B=""; BD_I=""; BD_R=""
  _bd_pj "$1" > "$_bd_wp/project.json"
  printf '%s\n' "$(_bd_kt "$2")" > "$_bd_wp/evidence.tsv"
  [ -n "$_bd_why" ] || _bd_read "$REPO" "$FROOT" refs/heads/bdecl-base "$(_bd_kp "$2")" "${3:-$(_bd_rk "$2")}"
}

for _bd_s in R1 R2 R3 R4 R5; do
  for _bd_k in $_bd_KINDS; do
    _bd_w "$_bd_s" "$_bd_k"; _bd_l="$_bd_s, $(_bd_sd "$_bd_s"), $(_bd_kd "$_bd_k")"
    _bd_is "brief-decl arm W $_bd_s ($_bd_k): the widget's project.json holds $(_bd_sd "$_bd_s"), felix evidence prints [?] project.json saying not judged$(_bd_an "$_bd_k")" \
           "$(_bd_arm "$(_bd_has "$(cat "$_bd_wp/project.json")" "$_bd_s")" "$_bd_k")" "$(_bd_aw "$_bd_k")"
    _bd_is "brief-decl D1 W brief ($_bd_l): under what a fix must prove felix brief prints exactly one row, project.json, whose reason is felix evidence's byte for byte" \
           "$(_bd_bs)" "$(_bd_pjr)"
    _bd_is "brief-decl D1 W incident ($_bd_l): under the fix will have to prove felix incident prints exactly one row, project.json, whose reason is felix evidence's byte for byte" \
           "$(_bd_isec)" "$(_bd_pjr)"
    [ "$_bd_k" = reach ] || continue
    _bd_agree "brief-decl D6 W $_bd_s ($(_bd_sd "$_bd_s")): felix brief, felix incident and felix evidence name project.json exactly when felix merge --dry-run lists an evidence line naming it"
    _bd_is "brief-decl D5 W $_bd_s two arguments: felix_brief_evidence PROJ PATHS, cwd the widget checkout, only lib/resolve.sh and lib/intake.sh sourced, prints the one line project.json, a tab and felix evidence's reason, the row felix brief prints under its heading" \
           "lib [$(_bd_lib "$REPO" "$_bd_wp" src/thing.js)] brief [$(_bd_bs)]" "lib [$(_bd_pjr)] brief [$(_bd_pjr)]"
  done
done

_bd_w R4 reach eb
_bd_x="inside the checkout no"; case "$_bd_wp/" in "$REPO/"*) _bd_x="inside the checkout yes" ;; esac
_bd_is "brief-decl arm C4 W R4: the widget's project directory is not inside the checkout the commands run in nor in any repository, its declaration on the disk is R4's, and felix evidence prints the row" \
       "$_bd_x, a repository [$(_fx_git "$_bd_wp" rev-parse --show-toplevel 2>/dev/null)], $(_bd_arm "$(_bd_has "$(cat "$_bd_wp/project.json")" R4)" -)" \
       "inside the checkout no, a repository [], $(_bd_aw -)"
_bd_is "brief-decl C4 W R4: a bad declaration on the disk of a project outside the repository: felix brief and felix evidence agree, a row project.json in both" \
       "brief $(_bd_yn "$(_bd_bs)"), evidence $(_bd_yn "$(printf '%s\n' "$BD_E" | LC_ALL=C awk '$1 == "[?]" { print $2 }')")" \
       "brief yes, evidence yes"

# D2 and C1: no declaration, and a good one, over every kind.
for _bd_k in $_bd_KINDS; do
  _bd_x=bi; [ "$_bd_k" != reach ] || _bd_x=embi
  _bd_w N "$_bd_k" "$_bd_x"; _bd_nb="$BD_B"; _bd_ni="$BD_I"
  if [ "$_bd_k" = reach ]; then
    _bd_is "brief-decl arm C1 W N: the widget's project.json, as this part found it, holds neither evidence_vendored nor evidence_reads_vendored, and felix evidence prints no [?] row" \
           "$(_bd_c "$(cat "$_bd_wp/project.json")" 'index($0, "evidence_vendored") || index($0, "evidence_reads_vendored")') keys, [?] $(_bd_c "$BD_E" '$1 == "[?]"')" \
           "0 keys, [?] 0"
    _bd_is "brief-decl C1 W N (reach) brief: with no declaration felix brief prints the table's row as it did, unit alone, and no project.json row" \
           "$(_bd_bs)" "$_bd_U"
    _bd_is "brief-decl C1 W N (reach) incident: with no declaration felix incident prints the table's row as it did, unit alone, and no project.json row" \
           "$(_bd_isec)" "$_bd_U"
    _bd_agree "brief-decl D6 W N (no declaration, control): felix brief, felix incident and felix evidence name project.json exactly when felix merge --dry-run lists an evidence line naming it"
  fi
  _bd_w G1 "$_bd_k"
  _bd_is "brief-decl arm W G1 ($_bd_k): the widget's project.json declares evidence_vendored vendor/, and felix evidence prints no [?] project.json, a [?] row only for a row that is not four cells" \
         "declaration $(_bd_has "$(cat "$_bd_wp/project.json")" G1), [?] project.json $(_bd_c "$BD_E" '$1 == "[?]" && $2 == "project.json"'), [?] $(_bd_c "$BD_E" '$1 == "[?]"')" \
         "declaration yes, [?] project.json 0, [?] $( [ "$_bd_k" = four ] && printf 1 || printf 0 )"
  _bd_is "brief-decl D2 W G1 brief ($(_bd_kd "$_bd_k")): a good declaration changes nothing felix brief prints, its output byte for byte the output with no declaration" \
         "$BD_B" "$_bd_nb"
  _bd_is "brief-decl D2 W G1 incident ($(_bd_kd "$_bd_k")): a good declaration changes nothing felix incident prints, its output byte for byte the output with no declaration" \
         "$BD_I" "$_bd_ni"
  [ "$_bd_k" != reach ] || _bd_agree "brief-decl D6 W G1 (a good declaration, control): felix brief, felix incident and felix evidence name project.json exactly when felix merge --dry-run lists an evidence line naming it"
done

# D2: a path under the declared vendor/, and a row that opts back in (G2).
_bd_w N V bi; _bd_nb="$BD_B"; _bd_ni="$BD_I"
for _bd_s in G1 G2; do
  _bd_x=ebi; [ "$_bd_s" = G1 ] || _bd_x=embi
  _bd_w "$_bd_s" V "$_bd_x"
  _bd_x='so no rule read them'; [ "$_bd_s" = G1 ] || _bd_x='so only deps read them'
  _bd_is "brief-decl arm W $_bd_s (vendor): the declaration is read and good: felix evidence sets the change under vendor/ aside, $_bd_x, and prints no [?] project.json" \
         "declaration $(_bd_has "$(cat "$_bd_wp/project.json")" "$_bd_s"), VENDORED $(_bd_c "$BD_E" '$1 == "[-]" && $2 == "VENDORED" && index($0, "under vendor/, '"$_bd_x"'")'), [?] project.json $(_bd_c "$BD_E" '$1 == "[?]" && $2 == "project.json"')" \
         "declaration yes, VENDORED 1, [?] project.json 0"
  _bd_is "brief-decl D2 W $_bd_s brief (vendor/acme/src/a.go): a path under the declared vendor/ still meets the when cells of unit and deps, each row printed once, the output byte for byte the output with no declaration" \
         "rows [$(_bd_bs)], $( [ "$BD_B" = "$_bd_nb" ] && printf same || printf 'not the output with no declaration' )" "rows [$_bd_UD], same"
  _bd_is "brief-decl D2 W $_bd_s incident (vendor/acme/src/a.go): a path under the declared vendor/ still meets the when cells of unit and deps, each row printed once, the output byte for byte the output with no declaration" \
         "rows [$(_bd_isec)], $( [ "$BD_I" = "$_bd_ni" ] && printf same || printf 'not the output with no declaration' )" "rows [$_bd_UD], same"
done
_bd_agree "brief-decl D6 W G2 (a good declaration that opts deps back in, control): felix brief, felix incident and felix evidence name project.json exactly when felix merge --dry-run lists an evidence line naming it"
_bd_is "brief-decl D5 W G2 two arguments: felix_brief_evidence PROJ PATHS, cwd the widget checkout, only lib/resolve.sh and lib/intake.sh sourced, prints the lines felix brief puts under its heading, unit and deps for a path under vendor/" \
       "lib [$(_bd_lib "$REPO" "$_bd_wp" vendor/acme/src/a.go)] brief [$(_bd_bs)]" "lib [$_bd_UD] brief [$_bd_UD]"

# D3 and C2: a bad declaration and nothing at evidence.tsv.
_bd_why="$_bd_wy"; _bd_pj R4 > "$_bd_wp/project.json"; rm -f "$_bd_wp/evidence.tsv"
[ -n "$_bd_why" ] || _bd_read "$REPO" "$FROOT" refs/heads/bdecl-base src/thing.js embi
_bd_is "brief-decl arm C2 W R4: the widget's project.json holds R4's declaration and nothing stands at its evidence.tsv" \
       "declaration $(_bd_has "$(cat "$_bd_wp/project.json")" R4), evidence.tsv $( [ -e "$_bd_wp/evidence.tsv" ] || [ -L "$_bd_wp/evidence.tsv" ] && printf stands || printf absent )" \
       "declaration yes, evidence.tsv absent"
_bd_hl "brief-decl D3 C2 W R4 brief: with nothing at evidence.tsv felix brief, naming src/thing.js, prints no what a fix must prove section, a bad declaration beside it" \
       "$BD_B" '+src/thing.js' '-what a fix must prove'
_bd_hl "brief-decl D3 C2 W R4 incident: with nothing at evidence.tsv felix incident, naming src/thing.js, prints no the fix will have to prove section, a bad declaration beside it" \
       "$BD_I" '+src/thing.js' '-the fix will have to prove'
_bd_is "brief-decl D3 C2 W R4 merge: with nothing at evidence.tsv felix merge --dry-run lists no evidence blocker" "$(_bd_c "$BD_ML" NF) [$BD_ML]" "0 []"
_bd_hl "brief-decl D3 C2 W R4 evidence: with nothing at evidence.tsv felix evidence says the project declares no evidence.tsv and prints no project.json row" \
       "$BD_E" '+declares no evidence.tsv' '-[?] project.json'
_bd_is "brief-decl D3 C2 W R4 two arguments: with nothing at evidence.tsv felix_brief_evidence prints nothing" \
       "[$(_bd_lib "$REPO" "$_bd_wp" src/thing.js)]" "[]"
_bd_agree "brief-decl D6 C2 W R4 (nothing at evidence.tsv, control): felix brief, felix incident and felix evidence name project.json exactly when felix merge --dry-run lists an evidence line naming it"

# D3 and C3: a bad declaration beside a table that cannot be read.
_bd_why="$_bd_wy"; BD_E=""; BD_M=""; BD_ML=""; BD_B=""; BD_I=""; BD_R=""
_bd_pj R4 > "$_bd_wp/project.json"; printf '%s\n' "$_bd_TT" > "$_bd_wp/evidence.tsv"; chmod 000 "$_bd_wp/evidence.tsv"
if [ -r "$_bd_wp/evidence.tsv" ]; then _bd_why="a mode-000 file is still readable here (root)"
else [ -n "$_bd_why" ] || _bd_read "$REPO" "$FROOT" refs/heads/bdecl-base src/thing.js embi; fi
_bd_is "brief-decl arm C3 W R4: beside R4's declaration a table of mode 000 is the one row: felix evidence prints [?] evidence.tsv and no [?] project.json, and felix merge --dry-run's evidence line names evidence.tsv, none project.json" \
       "declaration $(_bd_has "$(cat "$_bd_wp/project.json")" R4), evidence [?] evidence.tsv $(_bd_c "$BD_E" '$1 == "[?]" && $2 == "evidence.tsv"') project.json $(_bd_c "$BD_E" '$2 == "project.json"'), merge evidence.tsv $(_bd_c "$BD_ML" '$2 == "evidence.tsv"') project.json $(_bd_c "$BD_ML" '$2 == "project.json"')" \
       "declaration yes, evidence [?] evidence.tsv 1 project.json 0, merge evidence.tsv 1 project.json 0"
_bd_is "brief-decl D3 C3 W R4 brief: a table that cannot be read is judged first: felix brief's section holds one row, evidence.tsv, and no project.json row" \
       "$(_bd_bs | cut -f1)" "evidence.tsv"
_bd_is "brief-decl D3 C3 W R4 incident: a table that cannot be read is judged first: felix incident's section holds one row, evidence.tsv, and no project.json row" \
       "$(_bd_isec | cut -f1)" "evidence.tsv"
_bd_agree "brief-decl D6 C3 W R4 (a table of mode 000, control): felix brief, felix incident and felix evidence name project.json exactly when felix merge --dry-run lists an evidence line naming it"
chmod 644 "$_bd_wp/evidence.tsv" 2>/dev/null
_bd_why=""

# ---- H: a Felix home that is a repository, its declaration read from the commit -------------------------------------
printf '\n  a Felix home that is the repository, its declaration read from the commit (D1, D4, D5, D6, R6)\n'
# STATE KIND: a fresh repository in BD_H that is a Felix home: projects/widget holds the widget's tables, KIND's
# evidence.tsv and STATE's project.json (R6: a symbolic link to real.json, the widget's own), .felix names widget, and
# WIDGET.txt, src/thing.js and vendor/acme/src/a.go stand at its root. All of it is committed on main, refs/heads/bd-base
# names that commit, and a second commit changes src/thing.js and vendor/acme/src/a.go. _bd_why says why when it could
# not be built.
_bd_home() {
  local d f
  _bd_n=$((_bd_n + 1)); d="$BD/h$_bd_n"; BD_H=""; _bd_why=""; BD_E=""; BD_M=""; BD_ML=""; BD_B=""; BD_I=""; BD_R=""
  mkdir -p "$d/projects/widget" "$d/src" "$d/vendor/acme/src"
  for f in CLAUDE.md commissioning.tsv obligations.tsv probes.tsv risk.tsv; do
    [ ! -f "$_bd_wp/$f" ] || cp "$_bd_wp/$f" "$d/projects/widget/$f"
  done
  printf '%s\n' "$(_bd_kt "$2")" > "$d/projects/widget/evidence.tsv"
  if [ "$1" = R6 ]; then _bd_pj N > "$d/projects/widget/real.json"; ln -s real.json "$d/projects/widget/project.json" 2>/dev/null
  else _bd_pj "$1" > "$d/projects/widget/project.json"; fi
  printf 'widget\n' > "$d/.felix"; printf 'contents\n' > "$d/WIDGET.txt"
  printf 'bd base\n' > "$d/src/thing.js"; printf 'bd base\n' > "$d/vendor/acme/src/a.go"
  if ! ( _fx_cd "$d" && git init -q -b main && git -c core.excludesFile=/dev/null add -A \
         && git -c user.name=t -c user.email=t@t commit -qm base && git update-ref refs/heads/bd-base HEAD \
         && printf 'bd change\n' > src/thing.js && printf 'bd change\n' > vendor/acme/src/a.go \
         && git -c core.excludesFile=/dev/null add -A && git -c user.name=t -c user.email=t@t commit -qm change ) >/dev/null 2>&1
  then _bd_why="the Felix home repository $d could not be built"; return 0; fi
  BD_H="$(cd "$d" && pwd -P)"
  if [ "$1" = R6 ] && [ "$(_bd_hhas R6)" != yes ]; then _bd_why="project.json could not be committed as a symbolic link here"; fi
}
# STATE: yes when HEAD's projects/widget/project.json is STATE's (R6: an entry of mode 120000); no without a home.
_bd_hhas() {
  if [ -z "$BD_H" ]; then printf no
  elif [ "$1" = R6 ]; then
    case "$(_fx_git "$BD_H" ls-tree HEAD projects/widget/project.json 2>/dev/null)" in 120000*) printf yes ;; *) printf no ;; esac
  else _bd_has "$(_fx_git "$BD_H" show HEAD:projects/widget/project.json 2>/dev/null)" "$1"; fi
}
# KIND: the readers over the home, as _bd_rk names them for KIND.
_bd_hr() { [ -n "$_bd_why" ] || _bd_read "$BD_H" "$BD_H" refs/heads/bd-base "$(_bd_kp "$1")" "$(_bd_rk "$1")"; }

for _bd_s in R1 R2 R3 R4 R5 R6; do
  _bd_ks=reach; [ "$_bd_s" != R6 ] || _bd_ks="$_bd_KINDS"
  for _bd_k in $_bd_ks; do
    _bd_home "$_bd_s" "$_bd_k"; _bd_hr "$_bd_k"; _bd_l="$_bd_s, $(_bd_sd "$_bd_s"), $(_bd_kd "$_bd_k")"
    _bd_is "brief-decl arm H $_bd_s ($_bd_k): the home's commit holds $(_bd_sd "$_bd_s"), felix evidence prints [?] project.json saying not judged$(_bd_an "$_bd_k")" \
           "$(_bd_arm "$(_bd_hhas "$_bd_s")" "$_bd_k")" "$(_bd_aw "$_bd_k")"
    _bd_is "brief-decl D1 H brief ($_bd_l): under what a fix must prove felix brief prints exactly one row, project.json, whose reason is felix evidence's byte for byte" \
           "$(_bd_bs)" "$(_bd_pjr)"
    _bd_is "brief-decl D1 H incident ($_bd_l): under the fix will have to prove felix incident prints exactly one row, project.json, whose reason is felix evidence's byte for byte" \
           "$(_bd_isec)" "$(_bd_pjr)"
    [ "$_bd_k" = reach ] || continue
    _bd_agree "brief-decl D6 H $_bd_s ($(_bd_sd "$_bd_s")): felix brief, felix incident and felix evidence name project.json exactly when felix merge --dry-run lists an evidence line naming it"
    [ "$_bd_s" = R4 ] || continue
    _bd_is "brief-decl D5 H R4 three arguments: felix_brief_evidence PROJ PATHS ROOT, ROOT the home's repository and cwd in none, prints the one line project.json, a tab and felix evidence's reason" \
           "$(_bd_lib "$BD" "$BD_H/projects/widget" src/thing.js "$BD_H")" "$(_bd_pjr)"
    _bd_is "brief-decl D5 H R4 two arguments: felix_brief_evidence PROJ PATHS, cwd the home's repository, prints the one line project.json, a tab and felix evidence's reason" \
           "$(_bd_lib "$BD_H" "$BD_H/projects/widget" src/thing.js)" "$(_bd_pjr)"
  done
done

# D4: an uncommitted bad edit over a good commit, then an uncommitted fix over a bad one.
_bd_home N reach; [ -n "$_bd_why" ] || _bd_pj R4 > "$BD_H/projects/widget/project.json"; _bd_hr reach
_bd_is "brief-decl arm D4 H uncommitted bad edit: the working tree's project.json holds R4's declaration, HEAD's does not, and felix evidence, reading the commit, prints no [?] project.json" \
       "working tree $(_bd_has "$(cat "$BD_H/projects/widget/project.json" 2>/dev/null)" R4), HEAD $(_bd_hhas R4), [?] project.json $(_bd_c "$BD_E" '$1 == "[?]" && $2 == "project.json"')" \
       "working tree yes, HEAD no, [?] project.json 0"
_bd_is "brief-decl D4 H uncommitted bad edit, brief: the declaration is read from the commit, so felix brief prints the row as with no declaration, unit alone" \
       "$(_bd_bs)" "$_bd_U"
_bd_is "brief-decl D4 H uncommitted bad edit, incident: the declaration is read from the commit, so felix incident prints the row as with no declaration, unit alone" \
       "$(_bd_isec)" "$_bd_U"
_bd_agree "brief-decl D6 H uncommitted bad edit (control): felix brief, felix incident and felix evidence name project.json exactly when felix merge --dry-run lists an evidence line naming it"
_bd_is "brief-decl D5 H uncommitted bad edit, three arguments: felix_brief_evidence PROJ PATHS ROOT reads the commit and prints the unit row alone" \
       "$(_bd_lib "$BD" "$BD_H/projects/widget" src/thing.js "$BD_H")" "$_bd_U"
_bd_is "brief-decl D5 H uncommitted bad edit, two arguments: felix_brief_evidence PROJ PATHS, cwd the home's repository, reads the commit and prints the unit row alone" \
       "$(_bd_lib "$BD_H" "$BD_H/projects/widget" src/thing.js)" "$_bd_U"
_bd_home R4 reach; [ -n "$_bd_why" ] || _bd_pj N > "$BD_H/projects/widget/project.json"; _bd_hr reach
_bd_is "brief-decl arm D4 H uncommitted fix: HEAD's project.json holds R4's declaration, the working tree's does not, felix evidence, reading the commit, prints [?] project.json saying not judged, and felix merge --dry-run lists an evidence line naming project.json" \
       "working tree $(_bd_has "$(cat "$BD_H/projects/widget/project.json" 2>/dev/null)" R4), HEAD $(_bd_hhas R4), $(_bd_arm yes reach)" \
       "working tree no, HEAD yes, $_bd_ARMED"
_bd_is "brief-decl D4 H uncommitted fix, brief: an uncommitted fix leaves the committed declaration bad: felix brief prints exactly the project.json row, felix evidence's reason" \
       "$(_bd_bs)" "$(_bd_pjr)"
_bd_is "brief-decl D4 H uncommitted fix, incident: an uncommitted fix leaves the committed declaration bad: felix incident prints exactly the project.json row, felix evidence's reason" \
       "$(_bd_isec)" "$(_bd_pjr)"
_bd_agree "brief-decl D6 H uncommitted fix: felix brief, felix incident and felix evidence name project.json exactly when felix merge --dry-run lists an evidence line naming it"
_bd_is "brief-decl D5 H uncommitted fix, three arguments: felix_brief_evidence PROJ PATHS ROOT reads the commit and prints the project.json row" \
       "$(_bd_lib "$BD" "$BD_H/projects/widget" src/thing.js "$BD_H")" "$(_bd_pjr)"
_bd_is "brief-decl D5 H uncommitted fix, two arguments: felix_brief_evidence PROJ PATHS, cwd a directory below the home's root, reads the repository holding it and prints the project.json row" \
       "$(_bd_lib "$BD_H/src" "$BD_H/projects/widget" src/thing.js)" "$(_bd_pjr)"
_bd_why=""

# The widget checkout and tables, as this part found them.
if [ -n "$_bd_wb" ]; then ( _fx_cd "$REPO" && git checkout -q "${_bd_wb#refs/heads/}" ) >/dev/null 2>&1
elif [ -n "$_bd_wh" ]; then ( _fx_cd "$REPO" && git checkout -q --detach "$_bd_wh" ) >/dev/null 2>&1; fi
_fx_git "$REPO" branch -q -D bdecl-work >/dev/null 2>&1
_fx_git "$REPO" update-ref -d refs/heads/bdecl-base >/dev/null 2>&1
for _bd_f in evidence.tsv project.json; do
  if [ -f "$BD/$_bd_f.keep" ]; then cp "$BD/$_bd_f.keep" "$_bd_wp/$_bd_f"; else rm -f "$_bd_wp/$_bd_f"; fi
done
unset -f _bd_is _bd_hl _bd_c _bd_kt _bd_kp _bd_kd _bd_key _bd_sd _bd_pj _bd_has _bd_read _bd_rk _bd_sec _bd_bs _bd_isec \
         _bd_pjr _bd_yn _bd_arm _bd_aw _bd_an _bd_agree _bd_lib _bd_w _bd_home _bd_hhas _bd_hr
