# >>> evidence-readers-agree
printf '\nthe evidence readers agree with the judge: a path that stands and is no table is not judged, never absent (contract 2026-11-05, blind)\n'
# Blind, written on 2026-11-05 from docs/2026-11-05-evidence-readers-agree-contract.md alone. No engine code was
# read: felix, lib/, hooks/, templates/ and the project gates were not opened. Every command is driven as a black
# box, lib/evidence.sh is sourced in subshells to call its functions, and D3 greps the engine's tracked text for a
# pattern as its target. Each assertion is named by its contract number and the behaviour, and every name is
# emitted on every run; a state that cannot be built skips its names and says why. The controls (C1 to C6, each
# "R armed", "A4 armed", "D2 armed", "D3 armed" and the control halves of A5) hold before the fix; D1, D2, D3, A1 to
# A4 and the state halves of A5 fail on the tree the contract was cut from.
#
# Readings, where the contract leaves room:
# - Each state's change is written in the widget checkout and committed by _stage, and undone by _reset, as 1830
#   F2 does; every file it writes holds a line no earlier commit held. The base is refs/heads/era-base, a branch at
#   HEAD~1, the commit the change was cut from, made before the readers run and removed after. felix incident
#   reads a trace, not a diff, so it takes no base; the trace names src/thing.js, which a commit of this part's
#   own puts in the checkout first and which is undone at the end.
# - The green change touches README.md only (the shipped risk table's documentation row, green). C2 and C4's
#   change touches src/a.ts, which the rule code (^src/, wants ^tests/) reaches and does not meet.
# - felix merge --dry-run runs over a green gate receipt and a fresh commission receipt (1830 A21), and only the
#   lines whose first word is evidence are read.
# - "not judged" in felix receipt is read as evidence listed under unknown, as the contract's Words say the
#   receipt marks the reference case; its JSON never carries the words, the reference case C5 included.
# - A5's "the three controls" are read as C1, C3 and C5: the controls whose change is green, so that felix
#   classify on a green change can be read in them. C2 and C4's merge lists a gap as an evidence blocker with no
#   "not judged", which A5's agreement is not about.
# - C1's clause that felix_evidence_table_present exits 1 cannot hold before the fix, since the function does not
#   exist there; it is asserted as D1's case for the widget project in C1's state, and fails red with D1.
# - A1's "a [?] row" is exactly one row; "a line saying 1 row not judged" and A2's "1 evidence row was not judged"
#   are the reference case's own words, 1 row(s) not judged and 1 evidence row(s) not judged, as C5 shows them.
#   A4's section is its heading's following lines up to the first blank line, a row's name first on each; "one
#   row named evidence.tsv" is one of them whose first word is evidence.tsv and whose reason holds cannot be read
#   and not judged.
# - C6's file holds C2's table at mode 000 and its change is green; it skips where a mode-000 file is still
#   readable (root).
# - D1 runs on project directories of its own. Every call runs in the background under a 30 s watchdog, so a
#   function that opens the FIFO fails D1 instead of hanging the suite; "it reads no file" is asserted by the FIFO.
#   "Prints nothing" is read on stdout and stderr together.
# - D2 drives the judge through felix_evidence_check PROJ BASE REPO, which runs it (1830 F1), in a repository of
#   its own; "prints nothing" is read on stdout.
# - D3's "tests evidence.tsv" is a line where [, [[ or test is followed by -f, -e, -L, -s, -r or -d, an optional
#   ! between, and an operand word that holds evidence.tsv. The files are what git ls-files lists under felix and
#   lib/ in the checkout the suite runs from. "Every reader asks felix_evidence_table_present" is read as the
#   consequence of the first sentence, shown by A1 to A4 and D2, not as a second grep.
#
# Arming: a negative assertion here never stands alone. A1, A2 and A3's "does not print" and "no gap" clauses
# share one assertion with their positive claim on the same output; each state of R has an "R armed" assertion
# that the path was built and felix merge --dry-run lists the not-judged row, so the judge saw the state. C1's
# "no evidence line" and "no unknown" are paired with C2 and C5, which list them over the same base and fixture;
# C3's are paired with C2 and share their assertions with "No evidence gaps" and "nothing is unproven". A4 is
# paired with "A4 armed": the same trace reaches the section in C5's state. D2's "prints nothing" is paired with
# "D2 armed": as shipped, the same checks print the gap and the met row. D3 is paired with "D3 armed": the pattern
# finds each form in a planted text, and the file list holds felix and lib/evidence.sh.
#
# Every part runs alone: this one makes the widget checkout's first commit with _widget_repo_build, moves aside
# whatever stands at the widget's evidence.tsv and puts it back at the end, leaves nothing it made at that path,
# and makes every other fixture under $TMP/era.

ERA="$TMP/era"; mkdir -p "$ERA"
_widget_repo_build
_era_wp="$FROOT/projects/widget"; _era_ev="$_era_wp/evidence.tsv"
_era_kept=""
if [ -e "$_era_ev" ] || [ -L "$_era_ev" ]; then mv "$_era_ev" "$ERA/evidence.keep" && _era_kept=1; fi
_era_T="$(printf 'code\t^src/\t^tests/\tbehaviour needs a test')"
_era_T3="$(printf 'unit\t^src/\t^tests/')"
_era_trace="$(printf 'Error: boom\n    at run (/home/runner/work/x/x/src/thing.js:44:9)')"
_era_k=0; _era_why=""; ERA_CH=""

# NAME GOT WANT [TEXT]: is, with TEXT shown on a failure; a skip by NAME while _era_why says why it cannot run.
_era_is() {
  if [ -n "$_era_why" ]; then skip "$1" "$_era_why"
  elif [ "$2" = "$3" ]; then ok "$1"
  else bad "$1" "expected [$3] got [$2]${4:+ in [$4]}"; fi
}
# NAME TEXT +PHRASE|-PHRASE...: one assertion that TEXT holds every +PHRASE and no -PHRASE.
_era_hl() {
  local n="$1" t="$2" p miss=""
  shift 2
  for p in "$@"; do
    case "$p" in
      +*) case "$t" in *"${p#+}"*) ;; *) miss="$miss lacks [${p#+}];" ;; esac ;;
      -*) case "$t" in *"${p#-}"*) miss="$miss holds [${p#-}];" ;; esac ;;
    esac
  done
  if [ -n "$_era_why" ]; then skip "$n" "$_era_why"
  elif [ -z "$miss" ]; then ok "$n"; else bad "$n" "it$miss in [$t]"; fi
}
# TEXT AWK-CONDITION: how many non-empty lines of TEXT meet the condition, fields split on blanks.
_era_c() { printf '%s\n' "$1" | LC_ALL=C awk 'NF && ('"$2"') { n++ } END { print n + 0 }'; }

# ---- D1: felix_evidence_table_present -----------------------------------------------------------------------
printf '\n  felix_evidence_table_present says whether anything stands at PROJ/evidence.tsv, and reads nothing (D1)\n'
# PROJ: felix_evidence_table_present PROJ in a background subshell under a 30 s watchdog, as rc=N out=[its stdout
# and stderr], or a phrase saying it did not return.
_era_tp() {
  local i=0 j
  rm -f "$ERA/tp.out" "$ERA/tp.rc"
  ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/evidence.sh"
    felix_evidence_table_present "$1" > "$ERA/tp.out" 2>&1; printf '%s\n' "$?" > "$ERA/tp.rc" ) </dev/null >/dev/null 2>&1 &
  j=$!
  while [ ! -s "$ERA/tp.rc" ] && [ "$i" -lt 300 ] && kill -0 "$j" 2>/dev/null; do sleep 0.1; i=$((i + 1)); done
  if [ ! -s "$ERA/tp.rc" ]; then
    if kill -0 "$j" 2>/dev/null; then kill "$j" 2>/dev/null; wait "$j" 2>/dev/null; printf 'did not return within 30 s'
    else wait "$j" 2>/dev/null; printf 'ended before it wrote a status'; fi
    return 0
  fi
  wait "$j" 2>/dev/null
  printf 'rc=%s out=[%s]' "$(cat "$ERA/tp.rc")" "$(cat "$ERA/tp.out")"
}
# KIND: $ERA/d1-KIND, a project directory whose evidence.tsv is KIND; _era_why empty when it was built.
_era_d1() {
  local d="$ERA/d1-$1" p="$ERA/d1-$1/evidence.tsv"
  mkdir -p "$d"; _era_why="evidence.tsv could not be made $1 here"
  case "$1" in
    file)     printf '%s\n' "$_era_T" > "$p"; [ -f "$p" ] && [ ! -L "$p" ] && _era_why="" ;;
    dir)      mkdir -p "$p"; [ -d "$p" ] && [ ! -L "$p" ] && _era_why="" ;;
    link)     printf '%s\n' "$_era_T" > "$ERA/d1-target.tsv"; ln -s "$ERA/d1-target.tsv" "$p"
              [ -L "$p" ] && [ -f "$p" ] && _era_why="" ;;
    linkdir)  mkdir -p "$ERA/d1-target-dir"; ln -s "$ERA/d1-target-dir" "$p"; [ -L "$p" ] && [ -d "$p" ] && _era_why="" ;;
    dangling) ln -s "$ERA/d1-no-such-name-anywhere" "$p"; [ -L "$p" ] && [ ! -e "$p" ] && _era_why="" ;;
    fifo)     mkfifo "$p" 2>/dev/null; [ -p "$p" ] && [ ! -L "$p" ] && _era_why="" ;;
    none)     [ -e "$p" ] || [ -L "$p" ] || _era_why="" ;;
  esac
  return 0
}
for _era_x in "file|a regular file" "dir|a directory" "link|a link that resolves to a file" \
              "linkdir|a link that resolves to a directory" "dangling|a dangling link"; do
  _era_d1 "${_era_x%%|*}"
  _era_is "D1 felix_evidence_table_present (${_era_x#*|}): exits 0 and prints nothing" \
          "$(_era_tp "$ERA/d1-${_era_x%%|*}")" "rc=0 out=[]"
done
_era_d1 fifo
_era_is "D1 felix_evidence_table_present (a FIFO): exits 0, prints nothing, and returns without reading it" \
        "$(_era_tp "$ERA/d1-fifo")" "rc=0 out=[]"
_era_d1 none
_era_is "D1 felix_evidence_table_present (nothing at the path): exits 1 and prints nothing" \
        "$(_era_tp "$ERA/d1-none")" "rc=1 out=[]"
_era_why=""

# ---- D2: the judge asks that function and nothing else ----------------------------------------------------
printf '\n  the judge asks felix_evidence_table_present whether to say anything (D2)\n'
# NAME PATH...: a fresh repository $ERA/NAME, main holding README, work one commit on top adding each PATH.
_era_g() {
  local d="$ERA/$1" p
  shift
  mkdir -p "$d"; printf 'a readme\n' > "$d/README"
  ( _fx_cd "$d" && git init -q -b main && git add -A && git -c user.name=t -c user.email=t@t commit -qm main \
    && git checkout -q -b work ) >/dev/null 2>&1
  for p in "$@"; do mkdir -p "$(dirname "$d/$p")"; printf 'x\n' > "$d/$p"; done
  ( _fx_cd "$d" && git add -A && git -c user.name=t -c user.email=t@t commit -qm work ) >/dev/null 2>&1
}
# MODE PROJ REPO: felix_evidence_check PROJ main REPO, its stdout; MODE 0 or 1 replaces felix_evidence_table_present,
# after lib/evidence.sh is sourced and inside this subshell only, by one that always exits MODE; MODE - leaves it.
_era_chk() {
  ( cd "$3" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/evidence.sh"
    case "$1" in
      0) felix_evidence_table_present() { return 0; } ;;
      1) felix_evidence_table_present() { return 1; } ;;
    esac
    felix_evidence_check "$2" main "$3" ) </dev/null 2>/dev/null
}
_era_g d2-unmet src/a.ts; _era_g d2-met src/a.ts tests/a_test.py
_era_GU="$(cd "$ERA/d2-unmet" && pwd -P)"; _era_GM="$(cd "$ERA/d2-met" && pwd -P)"
mkdir -p "$ERA/d2-p" "$ERA/d2-p0"; printf '%s\n' "$_era_T" > "$ERA/d2-p/evidence.tsv"
_era_is "D2 armed (control): as shipped, the check prints the gap row for the unmet change, the met row for the met one, and nothing for a project with no evidence.tsv" \
        "$(_era_chk - "$ERA/d2-p" "$_era_GU" | cut -f1,2)|$(_era_chk - "$ERA/d2-p" "$_era_GM" | cut -f1,2)|[$(_era_chk - "$ERA/d2-p0" "$_era_GU")]" \
        "$(printf 'gap\tcode|met\tcode|[]')"
_era_is "D2 the judge, felix_evidence_table_present replaced by one that always exits 1: prints nothing for a readable table whose rule is unmet" \
        "$(_era_chk 1 "$ERA/d2-p" "$_era_GU")" ""
_era_is "D2 the judge, felix_evidence_table_present replaced by one that always exits 1: prints nothing for a readable table whose rule is met" \
        "$(_era_chk 1 "$ERA/d2-p" "$_era_GM")" ""
_era_v="$(_era_chk 0 "$ERA/d2-p0" "$_era_GU")"
_era_is "D2 the judge, felix_evidence_table_present replaced by one that always exits 0: prints the not-judged row, unknown evidence.tsv cannot be read not judged, for a project with no evidence.tsv" \
        "lines $(printf '%s' "$_era_v" | awk 'END { print NR }'), row $(printf '%s\n' "$_era_v" | LC_ALL=C awk -F'\t' 'NR == 1 { printf "%s %s %s %s", $1, $2, (index($3, "cannot be read") ? "cannot-be-read" : "-"), (index($3, "not judged") ? "not-judged" : "-") }')" \
        "lines 1, row unknown evidence.tsv cannot-be-read not-judged" "$_era_v"

# ---- D3: no second copy of the question --------------------------------------------------------------------
printf '\n  no engine file but lib/evidence.sh asks its own file test of evidence.tsv (D3)\n'
_era_re='(\[\[?|test)[[:space:]]+(![[:space:]]+)?-[feLsrd][[:space:]]+[^[:space:]]*evidence\.tsv'
_era_fl="$(cd "$REAL_HARNESS" 2>/dev/null && git ls-files -- felix lib 2>/dev/null)"
{ printf '%s\n' '[ -f "$p/evidence.tsv" ] || exit 1'
  printf '%s\n' 'if [ ! -e "$d/evidence.tsv" ] && [ ! -L "$d/evidence.tsv" ]; then :; fi'
  printf '%s\n' '[[ -s $pd/evidence.tsv ]] && echo y'
  printf '%s\n' 'test -r "$x/evidence.tsv" || :'
  printf '%s\n' '[ -d "${p}/evidence.tsv" ] && :'
  printf '%s\n' 'felix_evidence_table_present "$p" || exit 1'
  printf '%s\n' "printf 'declares no evidence.tsv\\n'"
} > "$ERA/d3-plant.txt"
_era_v="$(LC_ALL=C grep -nE "$_era_re" "$ERA/d3-plant.txt" 2>/dev/null | cut -d: -f1 | tr '\n' ' ')"
_era_a=no; _era_b=no
while IFS= read -r _era_x; do
  case "$_era_x" in felix) _era_a=yes ;; lib/evidence.sh) _era_b=yes ;; esac
done <<ERA_FILES_EOF
$_era_fl
ERA_FILES_EOF
_era_is "D3 armed (control): the pattern finds -f, -e, -L, -s, -r and -d on evidence.tsv under [, [[ and test in a planted text and nothing else there, and git lists felix and lib/evidence.sh among the files read" \
        "lines $_era_v| felix $_era_a, lib/evidence.sh $_era_b" "lines 1 2 3 4 5 | felix yes, lib/evidence.sh yes"
_era_v=""
while IFS= read -r _era_x; do
  [ -n "$_era_x" ] && [ "$_era_x" != lib/evidence.sh ] && [ -f "$REAL_HARNESS/$_era_x" ] || continue
  _era_y="$(LC_ALL=C grep -nE "$_era_re" "$REAL_HARNESS/$_era_x" 2>/dev/null)"
  [ -z "$_era_y" ] || _era_v="$_era_v$(printf '%s\n' "$_era_y" | sed "s|^|$_era_x:|") / "
done <<ERA_FILES_EOF
$_era_fl
ERA_FILES_EOF
_era_is "D3 no tracked file under engine/harness/felix or engine/harness/lib/ but lib/evidence.sh tests evidence.tsv with -f, -e, -L, -s, -r, -d, test, [[ or [" \
        "$_era_v" ""

# ---- the widget: the readers over each state ----------------------------------------------------------------
printf '\n  felix evidence, classify, receipt and incident read a path that stands and is no table as the judge does (A1 to A5, C1 to C6)\n'
_era_head() { ( _fx_cd "$REPO" && git rev-parse -q --verify HEAD ) 2>/dev/null; }
# PATH...: each written in $REPO with a line no earlier commit held, committed by _stage; 1 when HEAD did not move.
_era_ch() {
  local p h
  h="$(_era_head)"; _era_k=$((_era_k + 1))
  for p in "$@"; do mkdir -p "$(dirname "$REPO/$p")"; printf 'era change %s\n' "$_era_k" > "$REPO/$p"; done
  _stage
  [ -n "$(_era_head)" ] && [ "$(_era_head)" != "$h" ]
}
# nothing at the path: a file or a link goes with rm -f, a directory with rmdir; 1 when something still stands.
_era_clear() {
  rm -f "$_era_ev" 2>/dev/null; rmdir "$_era_ev" 2>/dev/null
  if [ -e "$_era_ev" ] || [ -L "$_era_ev" ]; then return 1; fi
  return 0
}
# KIND ROWS: the path made KIND from nothing (ROWS the rows of a table KIND writes); _era_why empty when it was.
_era_put() {
  _era_why="the widget's evidence.tsv could not be cleared"
  _era_clear || return 0
  _era_why="the widget's evidence.tsv could not be made $1 here"
  case "$1" in
    none)     _era_why="" ;;
    file)     printf '%s\n' "$2" > "$_era_ev"; [ -f "$_era_ev" ] && [ ! -L "$_era_ev" ] && [ -r "$_era_ev" ] && _era_why="" ;;
    linkfile) printf '%s\n' "$2" > "$ERA/c4-table.tsv"; ln -s "$ERA/c4-table.tsv" "$_era_ev"
              [ -L "$_era_ev" ] && [ -f "$_era_ev" ] && [ -r "$_era_ev" ] && _era_why="" ;;
    mode000)  printf '%s\n' "$2" > "$_era_ev"; chmod 000 "$_era_ev"
              if [ -r "$_era_ev" ]; then _era_why="a mode-000 file is still readable here (root)"
              elif [ -f "$_era_ev" ] && [ ! -L "$_era_ev" ]; then _era_why=""; fi ;;
    dir)      mkdir "$_era_ev"; [ -d "$_era_ev" ] && [ ! -L "$_era_ev" ] && _era_why="" ;;
    dangling) rm -f "$ERA/no-such-name-anywhere"; ln -s "$ERA/no-such-name-anywhere" "$_era_ev"
              [ -L "$_era_ev" ] && [ ! -e "$_era_ev" ] && _era_why="" ;;
    linkdir)  mkdir -p "$ERA/a-directory"; ln -s "$ERA/a-directory" "$_era_ev"
              [ -L "$_era_ev" ] && [ -d "$_era_ev" ] && _era_why="" ;;
  esac
  return 0
}
# JSON: four lines, yes or no for evidence under unknown, then unknown, evidence.gap and evidence.met as compact JSON.
_era_rj() {
  printf '%s' "$1" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    print("not json\nnot json\nnot json\nnot json"); sys.exit(0)
u = d.get("unknown")
e = d.get("evidence") if isinstance(d.get("evidence"), dict) else {}
c = lambda o: json.dumps(o, separators=(",", ":"))
print("yes" if isinstance(u, list) and "evidence" in u else "no")
print(c(u)); print(c(e.get("gap"))); print(c(e.get("met")))' 2>&1
}
# N: line N of the receipt's _era_rj.
_era_rf() { printf '%s\n' "$ERA_RJ" | sed -n "${1}p"; }
# READER...: the change at HEAD read by each READER (evidence classify receipt merge incident) over the base
# refs/heads/era-base at HEAD~1, after a green gate receipt and a fresh commission receipt (1830 A21).
_era_read() {
  local x b=refs/heads/era-base
  ERA_E=""; ERA_ERC=""; ERA_C=""; ERA_R=""; ERA_RJ=""; ERA_M=""; ERA_ML=""; ERA_I=""
  _fx_git "$REPO" update-ref "$b" HEAD~1 >/dev/null 2>&1
  ( cd "$REPO" && . "$FROOT/harness/lib/verify.sh"
    felix_verify_record "$REPO" "$FROOT" 0 "gate.sh" "$(felix_tree_id "$REPO" "$FROOT")" >/dev/null 2>&1 )
  _cm_stamp
  for x in "$@"; do
    case "$x" in
      evidence) ERA_E="$(cd "$REPO" && "$FELIX" evidence --base "$b" </dev/null 2>&1)"; ERA_ERC=$? ;;
      classify) ERA_C="$(cd "$REPO" && "$FELIX" classify --base "$b" </dev/null 2>&1)" ;;
      receipt)  ERA_R="$(cd "$REPO" && "$FELIX" receipt --base "$b" </dev/null 2>/dev/null)"; ERA_RJ="$(_era_rj "$ERA_R")" ;;
      merge)    ERA_M="$(cd "$REPO" && "$FELIX" merge --base "$b" --dry-run </dev/null 2>&1)"
                ERA_ML="$(printf '%s\n' "$ERA_M" | LC_ALL=C awk '$1 == "evidence"')" ;;
      incident) ERA_I="$(cd "$REPO" && printf '%s\n' "$_era_trace" | "$FELIX" incident 2>&1)" ;;
    esac
  done
  _fx_git "$REPO" update-ref -d "$b" >/dev/null 2>&1
}
# KIND ROWS PATH -- READER...: the path made KIND, then, when it was, PATH changed and committed and the READERs run.
_era_begin() {
  local k="$1" r="$2" p="$3"
  shift 4
  ERA_CH=""; ERA_E=""; ERA_ERC=""; ERA_C=""; ERA_R=""; ERA_RJ=""; ERA_M=""; ERA_ML=""; ERA_I=""
  _era_put "$k" "$r"
  [ -z "$_era_why" ] || return 0
  if _era_ch "$p"; then ERA_CH=1; else _era_why="the change to $p could not be committed"; return 0; fi
  _era_read "$@"
}
_era_end() { [ -z "$ERA_CH" ] || _reset; ERA_CH=""; _era_clear; _era_why=""; }
# The rows of felix incident's section the fix will have to prove: the lines after its heading up to the first blank
# line, each a row's name and its reason; or a line saying the output has no such heading.
_era_isec() {
  case "$ERA_I" in
    *"the fix will have to prove"*)
      printf '%s\n' "$ERA_I" | LC_ALL=C awk 'f == 1 && !NF { f = 2 } f == 1 { print } !f && index($0, "the fix will have to prove") { f = 1 }' ;;
    *) printf '(no heading the fix will have to prove)' ;;
  esac
}
# NAME: A5 over the current state: felix evidence, felix classify and felix receipt (evidence under unknown) say not
# judged exactly when felix merge --dry-run lists an evidence blocker.
_era_agree() {
  local e c m
  case "$ERA_E" in *"not judged"*) e=yes ;; *) e=no ;; esac
  case "$ERA_C" in *"not judged"*) c=yes ;; *) c=no ;; esac
  if [ -n "$ERA_ML" ]; then m=yes; else m=no; fi
  _era_is "$1" "merge $m: evidence $e, classify $c, receipt $(_era_rf 1)" "merge $m: evidence $m, classify $m, receipt $m"
}
_era_A5='felix evidence, felix classify (green change) and felix receipt (evidence under unknown) say not judged exactly when felix merge --dry-run lists an evidence blocker'

# The file the trace names, committed once under every state's change and undone at the end.
_era_thing=""
_era_ch src/thing.js && _era_thing=1

# C1: nothing at the path.
_era_begin none - README.md -- evidence classify receipt merge
_era_l="nothing at the path, control"
_era_hl "C1 evidence ($_era_l): says the project declares no evidence.tsv" "$ERA_E" '+declares no evidence.tsv'
_era_hl "C1 classify ($_era_l): on a green change says nothing is unproven" "$ERA_C" '+tier:  green' '+nothing is unproven'
_era_is "C1 receipt ($_era_l): lists no unknown" "$(_era_rf 2)" "[]" "$ERA_R"
_era_is "C1 merge --dry-run ($_era_l): lists no evidence line, where C2 and C5 list one over the same base" \
        "$(_era_c "$ERA_ML" 1)" 0 "$ERA_M"
_era_agree "A5 agreement (C1, $_era_l): $_era_A5"
_era_is "D1 felix_evidence_table_present (C1, nothing at the widget project's path): exits 1 and prints nothing" \
        "$(_era_tp "$_era_wp")" "rc=1 out=[]"
_era_end

# C2: a readable table whose rule the change touches and does not meet.
_era_begin file "$_era_T" src/a.ts -- evidence receipt merge
_era_l="a readable table, a rule the change touches and does not meet, control"
_era_hl "C2 evidence ($_era_l): names the gap, [!] code, and not not judged" "$ERA_E" '+[!] code' '-not judged'
_era_is "C2 receipt ($_era_l): lists the gap code, and evidence not under unknown" \
        "gap $(_era_rf 3), evidence under unknown $(_era_rf 1)" 'gap ["code"], evidence under unknown no' "$ERA_R"
_era_is "C2 merge --dry-run ($_era_l): lists the gap as one evidence line named code, and no evidence line says not judged" \
        "$(_era_c "$ERA_ML" '$2 == "code"')|$(_era_c "$ERA_ML" 'index($0, "not judged")')" "1|0" "$ERA_M"
_era_end

# C3: the same table, a change the rule does not reach.
_era_begin file "$_era_T" README.md -- evidence classify receipt merge
_era_l="the same table, a change the rule does not reach, control"
_era_hl "C3 evidence ($_era_l): says No evidence gaps, with no [!] row and not not judged" "$ERA_E" '+No evidence gaps' '-[!]' '-not judged'
_era_hl "C3 classify ($_era_l): on a green change says nothing is unproven, and not not judged" \
        "$ERA_C" '+tier:  green' '+nothing is unproven' '-not judged'
_era_is "C3 receipt ($_era_l): lists no gap, and evidence not under unknown" \
        "gap $(_era_rf 3), evidence under unknown $(_era_rf 1)" "gap [], evidence under unknown no" "$ERA_R"
_era_is "C3 merge --dry-run ($_era_l): lists no evidence line, where C2 lists the gap over the same table" \
        "$(_era_c "$ERA_ML" 1)" 0 "$ERA_M"
_era_agree "A5 agreement (C3, $_era_l): $_era_A5"
_era_end

# C4: a link that resolves to the file of C2.
_era_begin linkfile "$_era_T" src/a.ts -- evidence receipt merge
_era_l="a link that resolves to C2's file, control"
_era_hl "C4 evidence ($_era_l): names the gap, [!] code, and not not judged" "$ERA_E" '+[!] code' '-not judged'
_era_is "C4 receipt ($_era_l): lists the gap code, and evidence not under unknown" \
        "gap $(_era_rf 3), evidence under unknown $(_era_rf 1)" 'gap ["code"], evidence under unknown no' "$ERA_R"
_era_is "C4 merge --dry-run ($_era_l): lists the gap as one evidence line named code, and no evidence line says not judged" \
        "$(_era_c "$ERA_ML" '$2 == "code"')|$(_era_c "$ERA_ML" 'index($0, "not judged")')" "1|0" "$ERA_M"
_era_end

# C5: a regular file with a row that is not four cells, the reference case.
_era_begin file "$_era_T3" README.md -- evidence classify receipt merge incident
_era_l="a row that is not four cells, the reference, control"
_era_hl "C5 evidence ($_era_l): prints the [?] unit row not judged and 1 row(s) not judged" \
        "$ERA_E" '+[?] unit' '+not judged' '+1 row(s) not judged'
_era_hl "C5 classify ($_era_l): on a green change says 1 evidence row(s) not judged and Not auto-merge eligible" \
        "$ERA_C" '+tier:  green' '+ 1 evidence row(s) not judged' '+Not auto-merge eligible' '-Eligible for auto-merge'
_era_is "C5 receipt ($_era_l): lists evidence under unknown" "$(_era_rf 1)" yes "$ERA_R"
_era_is "C5 merge --dry-run ($_era_l): lists one evidence line, named unit, saying not judged" \
        "$(_era_c "$ERA_ML" 1)|$(_era_c "$ERA_ML" '$2 == "unit" && index($0, "not judged")')" "1|1" "$ERA_M"
_era_v="$(_era_isec)"
_era_is "A4 armed (C5, control): felix incident given the trace that names src/thing.js prints the fix will have to prove section, with the unit row not judged" \
        "$(_era_c "$_era_v" '$1 == "unit" && index($0, "not judged")')" 1 "$ERA_I"
_era_agree "A5 agreement (C5, $_era_l): $_era_A5"
_era_end

# C6: a regular file at mode 000.
_era_begin mode000 "$_era_T" README.md -- evidence classify receipt merge
_era_l="a regular file at mode 000, control"
_era_hl "C6 evidence ($_era_l): says not judged" "$ERA_E" '+not judged'
_era_hl "C6 classify ($_era_l): on a green change says not judged and Not auto-merge eligible" \
        "$ERA_C" '+tier:  green' '+not judged' '+Not auto-merge eligible'
_era_is "C6 receipt ($_era_l): lists evidence under unknown" "$(_era_rf 1)" yes "$ERA_R"
_era_is "C6 merge --dry-run ($_era_l): lists an evidence line saying not judged" \
        "$(_era_c "$ERA_ML" 'index($0, "not judged")')" 1 "$ERA_M"
_era_end

# R: a directory, a dangling link, a link that resolves to a directory.
for _era_x in "dir|directory" "dangling|dangling link" "linkdir|link to a directory"; do
  _era_l="${_era_x#*|}"
  _era_begin "${_era_x%%|*}" - README.md -- evidence classify receipt merge incident
  _era_is "R armed ($_era_l, control): the path is a $_era_l, and felix merge --dry-run lists one evidence line, named evidence.tsv, saying cannot be read and not judged" \
          "$(_era_c "$ERA_ML" 1)|$(_era_c "$ERA_ML" '$2 == "evidence.tsv" && index($0, "cannot be read") && index($0, "not judged")')" "1|1" "$ERA_M"
  _era_n="$(_era_c "$ERA_E" '$1 == "[?]" && $2 == "evidence.tsv" && index($0, "cannot be read") && index($0, "not judged")')"
  _era_m="$(_era_c "$ERA_E" '$1 == "1" && $2 == "row(s)" && $3 == "not" && $4 ~ /^judged/')"
  case "$ERA_E" in *"declares no evidence.tsv"*) _era_s=yes ;; *) _era_s=no ;; esac
  _era_is "A1 evidence ($_era_l): exits 1, prints one [?] row named evidence.tsv whose reason holds cannot be read and not judged and a line saying 1 row(s) not judged, and does not print declares no evidence.tsv" \
          "exit $ERA_ERC, [?] evidence.tsv rows $_era_n, 1 row(s) not judged lines $_era_m, declares no evidence.tsv $_era_s" \
          "exit 1, [?] evidence.tsv rows 1, 1 row(s) not judged lines 1, declares no evidence.tsv no" "$ERA_E"
  _era_hl "A2 classify ($_era_l): on a green change says 1 evidence row(s) not judged and Not auto-merge eligible, and prints neither nothing is unproven nor Eligible for auto-merge" \
          "$ERA_C" '+tier:  green' '+ 1 evidence row(s) not judged' '+Not auto-merge eligible' '-nothing is unproven' '-Eligible for auto-merge'
  _era_is "A3 receipt ($_era_l): lists evidence under unknown, and no evidence gap and no met row" \
          "evidence under unknown $(_era_rf 1), gap $(_era_rf 3), met $(_era_rf 4)" "evidence under unknown yes, gap [], met []" "$ERA_R"
  _era_v="$(_era_isec)"
  _era_is "A4 incident ($_era_l): given a trace that names src/thing.js, prints the fix will have to prove section with one row named evidence.tsv whose reason holds cannot be read and not judged" \
          "$(_era_c "$_era_v" '$1 == "evidence.tsv" && index($0, "cannot be read") && index($0, "not judged")')" 1 "$ERA_I"
  _era_agree "A5 agreement ($_era_l): $_era_A5"
  _era_end
done

# The widget as this part found it: the trace's file undone, nothing this part made at the path, the original back.
[ -z "$_era_thing" ] || _reset
_era_clear
[ -z "$_era_kept" ] || mv "$ERA/evidence.keep" "$_era_ev"
unset -f _era_is _era_hl _era_c _era_tp _era_d1 _era_g _era_chk _era_head _era_ch _era_clear _era_put _era_rj _era_rf \
         _era_read _era_begin _era_end _era_isec _era_agree
# <<< evidence-readers-agree
