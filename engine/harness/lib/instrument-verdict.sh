# The verdicts behind lib/instrument.sh (trust-plane step 3, slice 3, spec S8.2, S8.3, S8.5): what a unit of P's
# suite reported in T, what its changed members reached against the manifest of what the squash would land, and
# what the candidate's own driver reported for P's canary. Split from instrument.sh for its length; that file says
# what is judged and why, and instrument-run.sh how the runs are made. Every file read here is in the run's records
# directory (_FELIX_INSTR_R), which no unit is told about (A7.8), and each unit's status there is the judge's own.

# A unit's log (stdin) -> one record a line: P (prelude done), Q NAME (a FAIL before it), D MEMBER (member done),
# E (the part-done mark), R MEMBER NAME for each assertion reached after the prelude, F MEMBER NAME for each FAIL.
# An assertion belongs to the member whose @@member-done follows it. Names come from the ran file when it lists
# the same assertions in the same order, which keeps a skip's name whole; else from the lines, a skip's reason cut.
_felix_instr_aw='BEGIN { nm = split(mem, M, " "); k = 1; n = 0
  if (ranf != "") { while ((getline l < ranf) > 0) R[++n] = l; close(ranf) } }
{ l = $0 }
l == "@@prelude-done" { if (!s) { s = 1; print "P" }; next }
substr(l, 1, 14) == "@@member-done " { if (s) { print "D\t" substr(l, 15); k++ }; next }
substr(l, 1, 12) == "@@part-done " { if (s) print "E"; next }
{ h = substr(l, 1, 8) }
h != "  ok    " && h != "  FAIL  " && h != "  skip  " { next }
!s { if (h == "  FAIL  ") print "Q\t" substr(l, 9); next }
{ a++; T[a] = h; X[a] = substr(l, 9); W[a] = (k <= nm) ? M[k] : M[nm] }
END { use = (a == n)
  for (j = 1; use && j <= a; j++) if (T[j] != "  skip  " && X[j] != R[j]) use = 0
  for (j = 1; j <= a; j++) { x = use ? R[j] : X[j]
    if (!use && T[j] == "  skip  ") { for (c = length(x) - 1; c >= 1; c--) if (substr(x, c, 2) == " (") { x = substr(x, 1, c - 1); break } }
    gsub(/\t/, " ", x); print "R\t" W[j] "\t" x; if (T[j] == "  FAIL  ") print "F\t" W[j] "\t" x } }'

# What a status the judge wrote says, when it is not 0 (instrument-run.sh: 124 the time limit, 125 stopped).
_felix_instr_rcwhy() {   # RC LIMIT
  case "$1" in
    124) printf 'it had not ended after %s s, its time limit, and was stopped' "$2" ;;
    125) printf 'it was stopped before it ended' ;;
    *)   printf 'its process ended with status %s' "${1:-unknown}" ;;
  esac
}

# S8.2. Unit N's verdict, for its instrument members: each FAIL one line, a unit that did not finish one line for
# its first instrument member. What its changed instrument members reached goes to reached for S8.3.
_felix_instr_verdict() {   # N
  local n="$1" u="$_FELIX_INSTR_R" mem="${_FELIX_INSTR_U[$1]}" m first="" rc="" why="" tag a b dn=" " pd="" ed=""
  local fl="" og="" sh="" shm="" pf="" en="" rf="" tp="$_FELIX_INSTR_TP/parts"
  for m in $mem; do _felix_instr_in "$_FELIX_INSTR_INST" "$m" && { first="$m"; break; }; done
  [ -n "$first" ] || return 0
  { read -r rc < "$u/$n.rc"; } 2>/dev/null
  # Files, not process substitutions, which bash 3.2 leaves to be reaped at a later fork.
  LC_ALL=C awk -v mem="$mem" -v ranf="$u/$n.ran" "$_felix_instr_aw" "$u/$n.log" > "$u/$n.rec" 2>/dev/null
  while IFS=$'\t' read -r tag a b; do
    case "$tag" in
      P) pd=1 ;; E) ed=1 ;; D) dn="$dn$a " ;;
      Q) [ -n "$why" ] || why="its prelude failed: $a" ;;
      F) _felix_instr_in "$_FELIX_INSTR_INST" "$a" && _felix_instr_add escape "$tp/$a" "P's version fails on this tree: $b" ;;
      R) _felix_instr_in "$_FELIX_INSTR_CHG" "$a" && printf '%s\t%s\n' "$a" "$b" >> "$u/reached" ;;
    esac
  done < "$u/$n.rec"
  [ ! -f "$u/$n.end" ] || while IFS=$'\t' read -r tag a; do
    case "$tag" in floor) fl="$a" ;; og) og="$a" ;; shell) sh="$a" ;; shellmsg) [ -n "$shm" ] || shm="$a" ;;
      prefail) pf="$a" ;; refused) [ -n "$rf" ] || rf="$a" ;; end) en=1 ;; esac
  done < "$u/$n.end"
  [ "$rc" = 0 ] || why="$(_felix_instr_rcwhy "$rc" "${_FELIX_INSTR_ULIM:-1800}")${why:+, and $why}"
  [ -n "$pd" ] || why="${why:-it printed no @@prelude-done}"
  for m in $mem; do case "$dn" in *" $m "*) ;; *) why="${why:-$m did not finish}" ;; esac; done
  [ -n "$ed" ] || why="${why:-it printed no @@part-done mark}"
  [ -n "$en" ] || why="${why:-it left no end record that says it ended}"
  [ "$fl" = ok ] || why="${why:-its floor check read ${fl:-nothing}}"
  case "$og" in ok|skip) ;; *) why="${why:-its origin check read ${og:-nothing}}" ;; esac
  [ "$sh" = ok ] || why="${why:-it left the shell ${sh:-unread}${shm:+: $shm}}"
  case "$pf" in 0) ;; *) why="${why:-its prelude counted ${pf:-unread} failure(s)}" ;; esac
  [ -z "$rf" ] || why="${why:-the fixture guard refused: $rf}"
  [ -z "$why" ] || { _FELIX_INSTR_KEEP=""; _felix_instr_add escape "$tp/$first" "P's version did not finish on this tree: $why"; }
}

# S8.3. Each name a changed instrument part's P version reached more often than the manifest of what the squash
# would land lists it.
_felix_instr_names() {   # MANIFEST-FILE
  local p nm
  [ -s "$_FELIX_INSTR_R/reached" ] || return 0
  _felix_instr_drops "$1" > "$_FELIX_INSTR_R/drops" 2>/dev/null
  while IFS=$'\t' read -r p nm; do
    [ -n "$p" ] && _felix_instr_add escape "$_FELIX_INSTR_TP/parts/$p" "drops assertion $nm"
  done < "$_FELIX_INSTR_R/drops"
}
_felix_instr_drops() {   # MANIFEST-FILE -> PART<TAB>NAME, each name reached more often than listed
  LC_ALL=C awk 'FILENAME == ARGV[1] { c = $0; sub(/^\t+/, "", c); x = c; if (!sub(/^[^\t]*\t+/, "", x)) next
                           sub(/\t+$/, "", x); sub(/\t.*$/, "", c); if (c ~ /^[0123456789]+$/) m[x] += c; next }
                         { if (!($0 in k)) o[++n] = $0; k[$0]++ }
                         END { for (i = 1; i <= n; i++) { nm = substr(o[i], index(o[i], "\t") + 1); if (k[o[i]] > m[nm] + 0) print o[i] } }' \
             "$1" "$_FELIX_INSTR_R/reached"
}

# S8.5, A7.7. P's canary (tests/canary/part.sh, its expectations in its own `# expect WHICH VERDICT` lines) and the
# driver of what the squash would land, read into the records before any unit runs, and the canary's part and the
# driver with a line for it made from them, under a part name made for this run. Sets _FELIX_INSTR_CANARY to yes
# when the canary is to run, and no (with the line that says why) when it cannot. 1 only when a read failed.
_felix_instr_canary_prep() {   # ROOT LB LM TESTS-DIR
  local root="$1" lb="$2" lm="$3" t="$4" r="$_FELIX_INSTR_R" body exp id pn
  _FELIX_INSTR_CANARY=no
  [ -n "$(_felix_instr_sha "$lb" "$t/canary/part.sh")" ] \
    || { _felix_instr_add unknown SUITE "P holds no canary at $t/canary/part.sh, so the machinery this tree changes cannot be checked"; return 0; }
  _felix_instr_tofile "$root" "$lb" "$t/canary/part.sh" "$r/canary.body" || return 1
  exp="$(LC_ALL=C awk '$1 == "#" && $2 == "expect" && NF == 4 && ($4 == "ok" || $4 == "FAIL") && $3 ~ /^[abcdefghijklmnopqrstuvwxyz]+$/ { print $3 " " $4 }' "$r/canary.body")"
  [ -n "$exp" ] || { _felix_instr_add unknown SUITE "P's canary $t/canary/part.sh declares no expectation"; return 0; }
  printf '%s\n' "$exp" > "$r/canary.exp" || return 1
  [ -n "$(_felix_instr_sha "$lm" "$t/run")" ] \
    || { _felix_instr_add escape machinery "the canary could not run under this tree's driver: this tree has no $t/run"; return 0; }
  _felix_instr_tofile "$root" "$lm" "$t/run" "$r/canary.drv0" || return 1
  _FELIX_INSTR_CDMODE="$(printf '%s\n' "$lm" | LC_ALL=C awk -v p="$t/run" '{ i = index($0, "\t") } i && substr($0, i + 1) == p { print $1; exit }')"
  case "$_FELIX_INSTR_CDMODE" in 100644|100755) ;; *) _FELIX_INSTR_CDMODE=100755 ;; esac
  id="$(od -An -N8 -tx1 /dev/urandom 2>/dev/null | LC_ALL=C tr -cd '0123456789abcdef')"
  [ -n "$id" ] || id="$$$(date +%s)"
  id="canary-$id"; pn="9989-$id.sh"; _FELIX_INSTR_CID="$id"
  body="$(cat "$r/canary.body" && printf x)" || return 1
  body="${body%x}"
  printf '%s' "${body//@ID@/$id}" > "$r/canary.part" || return 1
  LC_ALL=C awk -v l=". \"\$HERE/parts/$pn\"" -v nm="$pn" '!d && index($0, ". \"$HERE/parts/") == 1 && substr($0, length($0)) == "\"" {
      if (substr($0, 16, length($0) - 16) > nm) { print l; d = 1 } } { print } END { if (!d) print l }' "$r/canary.drv0" > "$r/canary.drv" || return 1
  _FELIX_INSTR_CANARY=yes
}

# S8.5. The canary run by the candidate's own driver in part mode, in its copy, and what it reported.
_felix_instr_canary() {
  local r="$_FELIX_INSTR_R" id="$_FELIX_INSTR_CID" lim rc="" last w want ok fl got
  lim="$(_felix_instr_limit 300 "${FELIX_INSTRUMENT_CANARY_SECONDS:-}")"
  _felix_instr_launch 0 "$_FELIX_INSTR_J/c" "$lim" "9989-$id.sh"
  while ! _felix_instr_ended 0 "$lim"; do sleep 0.2; done
  { read -r rc < "$r/0.rc"; } 2>/dev/null
  case "$rc" in 124|125)
    _FELIX_INSTR_KEEP=""
    _felix_instr_add escape machinery "the canary could not run under this tree's driver: $(_felix_instr_rcwhy "$rc" "$lim")"
    return 0 ;;
  esac
  if ! LC_ALL=C awk -v id="$id: " 'index($0, "  ok    " id) == 1 || index($0, "  FAIL  " id) == 1 { f = 1 } END { exit !f }' "$r/0.log" 2>/dev/null; then
    last="$(LC_ALL=C awk 'NF { l = $0 } END { print substr(l, 1, 200) }' "$r/0.log" 2>/dev/null)"
    _felix_instr_add escape machinery "the canary could not run under this tree's driver: it reported none of its assertions (status ${rc:-unknown}${last:+; its last line: $last})"
    return 0
  fi
  while read -r w want; do
    ok="$(LC_ALL=C awk -v x="  ok    $id: $w" '$0 == x { n++ } END { print n + 0 }' "$r/0.log")"
    fl="$(LC_ALL=C awk -v x="  FAIL  $id: $w" '$0 == x { n++ } END { print n + 0 }' "$r/0.log")"
    case "$ok:$fl" in 1:0) got=ok ;; 0:1) got=FAIL ;; 0:0) got="not at all" ;; *) got="$ok times ok and $fl times FAIL" ;; esac
    [ "$got" = "$want" ] || _felix_instr_add escape machinery "the canary's $w was reported $got, where P's canary expects $want"
  done < "$r/canary.exp"
}
