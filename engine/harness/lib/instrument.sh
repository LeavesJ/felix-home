# P's instrument parts judge the candidate (trust-plane step 3, slice 3).
#
# The spec is in the memory root, audits/2026-11-08-trust-plane-step3/spec-slice3.md. Slices 1 and 2 (policy.sh,
# bind.sh) moved the tables, their instruments and the commit they are read at to P. This file is about the suite
# that judges Felix's own engine, which was the candidate's: a candidate supplied the instrument that judged it.
# Members of that class found so far, as examples and not the set: a part's assertion loosened, renamed or
# deleted; a part deleted, or no longer sourced by the driver; a helper's body in tests/run or tests/lib changed so
# that bad() passes; gate.sh or a workflow run differently; the partition table moving a part to subject.
#
# THE RULE (spec S7, S8), for Felix's own repository only (felix_self_governed_at), called by cmd_merge after
# slice 2's binding and only when no blocker of kind base, moved, objects, policy or unknown stands.
#   - S7: which parts are subject is read from P's projects/<name>/partition.tsv (the name is B's .felix), never
#     H's. A part H's table marks subject and P's does not is one escape line. A part P's driver sources that
#     P's table does not mark subject, in every row naming it, is instrument; a table that cannot be read whole
#     marks nothing subject (D28).
#   - S8.1: an instrument part is changed when H lacks it, holds other bytes for it, or H's driver does not
#     source it. S8.4: the machinery (tests/run without its part lines, tests/lib/, tests/canary/, receipt.sh,
#     red, groups.tsv, the project's gate.sh, .github/workflows/) is compared between B and H. A changed prelude
#     part (0001 to 0009, 9990), which no unit runs and every unit sources, counts as the machinery (a reading).
#   - S8.2: each unit (a part, or its group in P's groups.tsv) holding a changed instrument part runs, as P holds
#     it, in T: H's tracked files with engine/harness/tests, the gate and the workflows replaced by P's, as a git
#     repository whose objects are the checked copy's. With the machinery changed, every instrument unit runs,
#     and P's canary runs under H's own driver, in a copy of H's tree, under a part name made for this run.
#   - S8.3: every assertion name a changed instrument part's P version reached must be listed by H's manifest at
#     least as many times as it was reached.
#   - S8.10: the runs are children in process groups of their own, with the copy's object variables and bind's
#     other settings unset, at the gate's job count; everything lives in one felix-instrument.* directory under
#     TMPDIR, removed on any exit, a signal included, by the process that made it.
#
# WHAT THIS DOES NOT BIND, as examples and not the set (spec section 3): a part's body weakened under the same
# name; machinery that lies only for some names or outside part mode; the candidate's code redefining P's helpers
# inside P's run; the gate and CI, which still run the candidate's suite. A unit that never ends holds the merge:
# nothing here times it out.
#
# Sourced by escape.sh and by felix beside bind.sh. Needs bind.sh's copy (_FELIX_BIND_DIR, _FELIX_BIND_HOME).

# Set only here, in the shell that merges: an inherited value names no run directory and no verdict.
unset _FELIX_INSTR_BLOCK _FELIX_INSTR_NOTE _FELIX_INSTR_J _FELIX_INSTR_OWNER _FELIX_INSTR_SUB _FELIX_INSTR_U
unset _FELIX_INSTR_INST _FELIX_INSTR_CHG _FELIX_INSTR_TP

# One blocker line into _FELIX_INSTR_BLOCK, once: KIND SUBJECT REASON (tabs and newlines in REASON become blanks).
_felix_instr_add() {
  local r="$3" l
  r="${r//$'\t'/ }"; r="${r//$'\n'/ }"
  l="$1"$'\t'"$2"$'\t'"$r"
  case $'\n'"$_FELIX_INSTR_BLOCK"$'\n' in *$'\n'"$l"$'\n'*) return 0 ;; esac
  _FELIX_INSTR_BLOCK="${_FELIX_INSTR_BLOCK:+$_FELIX_INSTR_BLOCK$'\n'}$l"
}
_felix_instr_in() { case $'\n'"$1"$'\n' in *$'\n'"$2"$'\n'*) return 0 ;; esac; return 1; }   # LIST NAME

# A file of SHA, read through the run's objects (bind.sh's copy first), or nothing when it is not a blob there.
_felix_instr_cat() {   # ROOT SHA PATH
  [ "$(git -C "$1" cat-file -t "$2:$3" 2>/dev/null </dev/null)" = blob ] || return 1
  git -C "$1" cat-file blob "$2:$3" 2>/dev/null </dev/null
}
_felix_instr_id() { git -C "$1" rev-parse --verify --quiet "$2:$3" 2>/dev/null </dev/null; }   # ROOT SHA PATH

# git in a repository this run made: none of the copy's object variables, no machine-local configuration, an
# identity of its own. Reads of the copy go through the repository's alternates file instead.
_felix_instr_git() {   # DIR git-args...
  local d="$1"; shift
  env -u GIT_OBJECT_DIRECTORY -u GIT_ALTERNATE_OBJECT_DIRECTORIES -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
      -u GIT_COMMON_DIR HOME="$d" XDG_CONFIG_HOME="$d" GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 \
      GIT_AUTHOR_NAME=felix GIT_AUTHOR_EMAIL=felix@localhost GIT_COMMITTER_NAME=felix GIT_COMMITTER_EMAIL=felix@localhost \
      git -C "$d" -c core.excludesFile=/dev/null -c core.ignoreCase=false -c core.autocrlf=false -c core.hooksPath=/dev/null \
      "$@" </dev/null
}

# The parts a driver sources (stdin), as tests/run's own _sj_order reads them, part file names only.
_felix_instr_sourced() {
  LC_ALL=C awk 'index($0, ". \"$HERE/parts/") == 1 && length($0) > 16 && substr($0, length($0)) == "\"" {
    n = substr($0, 16, length($0) - 16); if (n ~ /^[abcdefghijklmnopqrstuvwxyz0123456789.-]+$/) print n }'
}
# S7. The parts a partition (stdin) marks subject. MODE p (P's): subject when every row naming it says subject,
# and nothing when a line is not part<TAB>class<TAB>why. MODE h (H's): subject when any row says so.
_felix_instr_subjects() {   # MODE
  LC_ALL=C awk -F'\t' -v m="$1" '
    /^#/ || /^[[:space:]]*$/ { next }
    NF < 3 || $1 == "" { bad = 1; next }
    { s = ($2 == "subject")
      if (!($1 in c)) { o[++n] = $1; c[$1] = s }
      else if (m == "p") { if (!s) c[$1] = 0 } else if (s) c[$1] = 1 }
    END { if (m == "p" && bad) exit 0; for (i = 1; i <= n; i++) if (c[o[i]]) print o[i] }'
}
# A tree listing (stdin, ls-tree -r) -> NAME SHA for each blob directly under PREFIX.
_felix_instr_under() {   # PREFIX
  LC_ALL=C awk -v pre="$1" '{ t = index($0, "\t"); if (!t) next; path = substr($0, t + 1); split(substr($0, 1, t - 1), m, " ")
    if (m[2] != "blob" || index(path, pre) != 1) next; n = substr(path, length(pre) + 1); if (n !~ /\//) print n " " m[3] }'
}
# A tree listing (stdin) -> MODE SHA PATH for the machinery paths other than the driver (spec section 0).
_felix_instr_mach() {   # TESTS-DIR GATE-PATH
  LC_ALL=C awk -v tp="$1" -v gp="$2" '{ t = index($0, "\t"); if (!t) next; p = substr($0, t + 1); split(substr($0, 1, t - 1), m, " ")
    if (index(p, tp "/lib/") == 1 || index(p, tp "/canary/") == 1 || p == tp "/receipt.sh" || p == tp "/red" \
        || p == tp "/groups.tsv" || (gp != "" && p == gp) || index(p, ".github/workflows/") == 1) print m[1] " " m[3] " " p }'
}
# A driver (stdin) without its part lines, for the comparison of the machinery.
_felix_instr_strip() { LC_ALL=C awk 'index($0, ". \"$HERE/parts/") == 1 && substr($0, length($0)) == "\"" { next } { print }'; }
# P's units, from stdin: @G, then P's groups.tsv, then @S, then P's sourced parts in its order. One a line, members
# blank-separated, the prelude parts and 9990 left out, as tests/run's _sj_mkunits makes them.
_felix_instr_units() {
  LC_ALL=C awk '$0 == "@G" || $0 == "@S" { sec = $0; next }
    sec == "@G" { if ($0 ~ /^#/ || $0 == "" || index($0, "\t") == 0) next
                  g[substr($0, index($0, "\t") + 1)] = substr($0, 1, index($0, "\t") - 1); next }
    sec != "@S" || $0 == "" || $0 ~ /^000[0123456789]-/ || $0 ~ /^9990-/ { next }
    { k = ($0 in g) ? "g " g[$0] : "p " $0; if (!(k in at)) { at[k] = ++n }; i = at[k]; u[i] = u[i] (u[i] == "" ? "" : " ") $0 }
    END { for (i = 1; i <= n; i++) print u[i] }'
}

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

# S8.2. Unit N's verdict, for its instrument members: each FAIL one line, a unit that did not finish one line for
# its first instrument member. What its changed instrument members reached goes to u/reached for S8.3.
_felix_instr_verdict() {   # N
  local n="$1" u="$_FELIX_INSTR_J/u" mem="${_FELIX_INSTR_U[$1]}" m first="" rc="" why="" tag a b dn=" " pd="" ed=""
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
  [ "$rc" = 0 ] || why="its process ended with status ${rc:-unknown}${why:+, and $why}"
  [ -n "$pd" ] || why="${why:-it printed no @@prelude-done}"
  for m in $mem; do case "$dn" in *" $m "*) ;; *) why="${why:-$m did not finish}" ;; esac; done
  [ -n "$ed" ] || why="${why:-it printed no @@part-done mark}"
  [ -n "$en" ] || why="${why:-it left no end record that says it ended}"
  [ "$fl" = ok ] || why="${why:-its floor check read ${fl:-nothing}}"
  case "$og" in ok|skip) ;; *) why="${why:-its origin check read ${og:-nothing}}" ;; esac
  [ "$sh" = ok ] || why="${why:-it left the shell ${sh:-unread}${shm:+: $shm}}"
  case "$pf" in 0) ;; *) why="${why:-its prelude counted ${pf:-unread} failure(s)}" ;; esac
  [ -z "$rf" ] || why="${why:-the fixture guard refused: $rf}"
  [ -z "$why" ] || _felix_instr_add escape "$tp/$first" "P's version did not finish on this tree: $why"
}

# S8.3. Each name a changed instrument part's P version reached more often than H's manifest lists it.
_felix_instr_names() {   # MANIFEST-FILE
  local p nm
  [ -s "$_FELIX_INSTR_J/u/reached" ] || return 0
  _felix_instr_drops "$1" > "$_FELIX_INSTR_J/u/drops" 2>/dev/null
  while IFS=$'\t' read -r p nm; do
    [ -n "$p" ] && _felix_instr_add escape "$_FELIX_INSTR_TP/parts/$p" "drops assertion $nm"
  done < "$_FELIX_INSTR_J/u/drops"
}
_felix_instr_drops() {   # MANIFEST-FILE -> PART<TAB>NAME, each name reached more often than listed
  LC_ALL=C awk 'FILENAME == ARGV[1] { c = $0; sub(/^\t+/, "", c); x = c; if (!sub(/^[^\t]*\t+/, "", x)) next
                           sub(/\t+$/, "", x); sub(/\t.*$/, "", c); if (c ~ /^[0123456789]+$/) m[x] += c; next }
                         { if (!($0 in k)) o[++n] = $0; k[$0]++ }
                         END { for (i = 1; i <= n; i++) { nm = substr(o[i], index(o[i], "\t") + 1); if (k[o[i]] > m[nm] + 0) print o[i] } }' \
             "$1" "$_FELIX_INSTR_J/u/reached"
}

# S8.5. P's canary (tests/canary/part.sh, its expectations in its own `# expect WHICH VERDICT` lines) written into a
# copy of H's tree under a part name made for this run, with a driver line, and run by H's driver in part mode.
_felix_instr_canary() {   # ROOT B H GATE-PATH BRANCH
  local root="$1" b="$2" h="$3" c="$_FELIX_INSTR_J/c" body exp id pn w want ok fl got rc="" last t="$_FELIX_INSTR_TP"
  body="$(_felix_instr_cat "$root" "$b" "$t/canary/part.sh")" \
    || { _felix_instr_add unknown SUITE "P holds no canary at $t/canary/part.sh, so the machinery this tree changes cannot be checked"; return 0; }
  exp="$(printf '%s\n' "$body" | LC_ALL=C awk '$1 == "#" && $2 == "expect" && NF == 4 && ($4 == "ok" || $4 == "FAIL") && $3 ~ /^[abcdefghijklmnopqrstuvwxyz]+$/ { print $3 " " $4 }')"
  [ -n "$exp" ] || { _felix_instr_add unknown SUITE "P's canary $t/canary/part.sh declares no expectation"; return 0; }
  id="$(od -An -N8 -tx1 /dev/urandom 2>/dev/null | LC_ALL=C tr -cd '0123456789abcdef')"
  [ -n "$id" ] || id="$$$(date +%s)"
  id="canary-$id"; pn="9989-$id.sh"
  if ! _felix_instr_tree "$root" "$c" "$h" "$b" "$4" 0 "$5"; then
    _felix_instr_add unknown SUITE "no copy of this tree could be made under $_FELIX_INSTR_J for the canary"; return 0
  fi
  if [ ! -f "$c/$t/run" ]; then
    _felix_instr_add escape machinery "the canary could not run under this tree's driver: this tree has no $t/run"; return 0
  fi
  printf '%s\n' "${body//@ID@/$id}" > "$c/$t/parts/$pn" 2>/dev/null \
    && LC_ALL=C awk -v l=". \"\$HERE/parts/$pn\"" -v nm="$pn" '!d && index($0, ". \"$HERE/parts/") == 1 && substr($0, length($0)) == "\"" {
         if (substr($0, 16, length($0) - 16) > nm) { print l; d = 1 } } { print } END { if (!d) print l }' "$c/$t/run" > "$c/run.t" \
    && cat "$c/run.t" > "$c/$t/run" && rm -f "$c/run.t" \
    && _felix_instr_git "$c" add -- "$t/parts/$pn" "$t/run" >/dev/null 2>&1 \
    && _felix_instr_git "$c" commit -q --no-verify -m "felix merge: the canary" >/dev/null 2>&1 \
    || { _felix_instr_add unknown SUITE "the canary could not be written into the copy of this tree"; return 0; }
  _felix_instr_launch 0 "$c" "$pn"
  while [ ! -f "$_FELIX_INSTR_J/u/0.rc" ]; do sleep 0.1; done
  wait "${_FELIX_INSTR_SUB[0]}" 2>/dev/null; unset "_FELIX_INSTR_SUB[0]"
  { read -r rc < "$_FELIX_INSTR_J/u/0.rc"; } 2>/dev/null
  if ! LC_ALL=C awk -v id="$id: " 'index($0, "  ok    " id) == 1 || index($0, "  FAIL  " id) == 1 { f = 1 } END { exit !f }' "$_FELIX_INSTR_J/u/0.log" 2>/dev/null; then
    last="$(LC_ALL=C awk 'NF { l = $0 } END { print substr(l, 1, 200) }' "$_FELIX_INSTR_J/u/0.log" 2>/dev/null)"
    _felix_instr_add escape machinery "the canary could not run under this tree's driver: it reported none of its assertions (status ${rc:-unknown}${last:+; its last line: $last})"
    return 0
  fi
  while read -r w want; do
    ok="$(LC_ALL=C awk -v x="  ok    $id: $w" '$0 == x { n++ } END { print n + 0 }' "$_FELIX_INSTR_J/u/0.log")"
    fl="$(LC_ALL=C awk -v x="  FAIL  $id: $w" '$0 == x { n++ } END { print n + 0 }' "$_FELIX_INSTR_J/u/0.log")"
    case "$ok:$fl" in 1:0) got=ok ;; 0:1) got=FAIL ;; 0:0) got="not at all" ;; *) got="$ok times ok and $fl times FAIL" ;; esac
    [ "$got" = "$want" ] || _felix_instr_add escape machinery "the canary's $w was reported $got, where P's canary expects $want"
  done <<EOF
$exp
EOF
}

# The judgement (spec S7, S8). Sets _FELIX_INSTR_BLOCK to the blocker lines it finds and _FELIX_INSTR_NOTE to the
# line felix merge prints when P's suite ran. Called in the merging shell, never in a substitution: the signal
# traps it sets for the run are this shell's. Returns 0.
felix_instrument_judge() {   # ROOT B H BRANCH
  local root="$1" b="$2" h="$3" br="$4" tp=engine/harness/tests bname pdir="" gp="" sp="" sh="" p lb lh pp hp
  local srcp srch plan mach=0 units k nu=0 i m hasc jobs unread=""
  _FELIX_INSTR_BLOCK=""; _FELIX_INSTR_NOTE=""; _FELIX_INSTR_TP="$tp"; _FELIX_INSTR_U=(); _FELIX_INSTR_SUB=()
  _FELIX_INSTR_INST=""; _FELIX_INSTR_CHG=""
  bname="$(_felix_instr_cat "$root" "$b" .felix | LC_ALL=C sed -n '1{s/[[:space:]]//g;p;}')"
  case "$bname" in ''|*/*|.|..) bname="" ;; esac
  if [ -n "$bname" ] && [ "$(git -C "$root" cat-file -t "$b:projects/$bname" 2>/dev/null </dev/null)" = tree ]; then
    pdir="projects/$bname"; gp="$pdir/gate.sh"
  fi
  # S7: a part H's table marks subject and P's does not.
  if [ -n "$pdir" ]; then
    sp="$(_felix_instr_cat "$root" "$b" "$pdir/partition.tsv" | _felix_instr_subjects p)"
    sh="$(_felix_instr_cat "$root" "$h" "$pdir/partition.tsv" | _felix_instr_subjects h)"
    while IFS= read -r p; do
      [ -n "$p" ] && ! _felix_instr_in "$sp" "$p" && _felix_instr_add escape "$pdir/partition.tsv" "marks $p subject"
    done <<EOF
$sh
EOF
  fi
  # S8.7: nothing an instrument holds changed, or P holds no suite: nothing runs and nothing is made.
  [ -n "$(_felix_instr_id "$root" "$b" "$tp")" ] || return 0
  if [ "$(_felix_instr_id "$root" "$b" "$tp")" = "$(_felix_instr_id "$root" "$h" "$tp")" ] \
     && { [ -z "$gp" ] || [ "$(_felix_instr_id "$root" "$b" "$gp")" = "$(_felix_instr_id "$root" "$h" "$gp")" ]; } \
     && [ "$(_felix_instr_id "$root" "$b" .github/workflows)" = "$(_felix_instr_id "$root" "$h" .github/workflows)" ]; then
    return 0
  fi
  # S8.9: an input that cannot be read is an unknown, not a founder decision.
  if [ "$(git -C "$root" cat-file -t "$b:$tp/run" 2>/dev/null </dev/null)" != blob ]; then
    _felix_instr_add unknown SUITE "P's driver $tp/run is not a file at $b, so nothing says which parts P sources and none of them was run"
    return 0
  fi
  lb="$(git -C "$root" -c core.quotePath=false ls-tree -r "$b" -- "$tp" ${gp:+"$gp"} .github/workflows 2>/dev/null </dev/null)" \
    && lh="$(git -C "$root" -c core.quotePath=false ls-tree -r "$h" -- "$tp" ${gp:+"$gp"} .github/workflows 2>/dev/null </dev/null)" \
    || { _felix_instr_add unknown SUITE "the trees of $b and $h under $tp could not be listed"; return 0; }
  srcp="$(_felix_instr_cat "$root" "$b" "$tp/run" | _felix_instr_sourced)"
  srch="$(_felix_instr_cat "$root" "$h" "$tp/run" | _felix_instr_sourced)"
  pp="$(printf '%s\n' "$lb" | _felix_instr_under "$tp/parts/")"; hp="$(printf '%s\n' "$lh" | _felix_instr_under "$tp/parts/")"
  # S0, S8.1: I instrument, C changed, U sourced by P and not a file at B.
  plan="$(printf '@PP\n%s\n@HP\n%s\n@SU\n%s\n@SH\n%s\n@SP\n%s\n' "$pp" "$hp" "$sp" "$srch" "$srcp" | LC_ALL=C awk '
    /^@/ { sec = $0; next } $0 == "" { next }
    sec == "@PP" { ps[$1] = $2; next } sec == "@HP" { hs[$1] = $2; next }
    sec == "@SU" { su[$0] = 1; next } sec == "@SH" { sh[$0] = 1; next }
    sec == "@SP" && !($0 in seen) { seen[$0] = 1; if ($0 in su) next; print "I\t" $0
      if (!($0 in ps)) print "U\t" $0; else if (!($0 in hs) || hs[$0] != ps[$0] || !($0 in sh)) print "C\t" $0 }')"
  while IFS=$'\t' read -r k p; do
    case "$k" in
      I) _FELIX_INSTR_INST="${_FELIX_INSTR_INST:+$_FELIX_INSTR_INST$'\n'}$p" ;;
      C) _FELIX_INSTR_CHG="${_FELIX_INSTR_CHG:+$_FELIX_INSTR_CHG$'\n'}$p"
         case "$p" in 000[0123456789]-*|9990-*) mach=1 ;; esac ;;
      U) unread=1; _felix_instr_add unknown SUITE "P's driver sources $tp/parts/$p, which is not a file at $b, so P's version of it cannot be read" ;;
    esac
  done <<EOF
$plan
EOF
  [ -z "$unread" ] || return 0
  # S8.4: the machinery, compared between B and H; the driver without its part lines.
  [ "$(printf '%s\n' "$lb" | _felix_instr_mach "$tp" "$gp")" = "$(printf '%s\n' "$lh" | _felix_instr_mach "$tp" "$gp")" ] || mach=1
  [ "$(_felix_instr_cat "$root" "$b" "$tp/run" | _felix_instr_strip | git hash-object --stdin 2>/dev/null)" \
    = "$(_felix_instr_cat "$root" "$h" "$tp/run" | _felix_instr_strip | git hash-object --stdin 2>/dev/null)" ] || mach=1
  # S8.2: the units that run, in P's driver order.
  units="$(printf '@G\n%s\n@S\n%s\n' "$(_felix_instr_cat "$root" "$b" "$tp/groups.tsv")" "$srcp" | _felix_instr_units)"
  while IFS= read -r k; do
    [ -n "$k" ] || continue
    hasc=""; for m in $k; do
      if [ "$mach" = 1 ]; then _felix_instr_in "$_FELIX_INSTR_INST" "$m" && hasc=1
      else _felix_instr_in "$_FELIX_INSTR_CHG" "$m" && hasc=1; fi
    done
    [ -z "$hasc" ] || { nu=$((nu + 1)); _FELIX_INSTR_U[nu]="$k"; }
  done <<EOF
$units
EOF
  [ "$nu" -gt 0 ] || [ "$mach" = 1 ] || return 0
  # S8.10: one directory for the whole run, removed on any exit by the process that made it.
  _FELIX_INSTR_OWNER="${BASHPID:-$(exec /bin/sh -c 'echo "$PPID"')}"
  i="${TMPDIR:-/tmp}"
  _FELIX_INSTR_J="$(mktemp -d "${i%/}/felix-instrument.XXXXXX" 2>/dev/null)" || _FELIX_INSTR_J=""
  [ -z "$_FELIX_INSTR_J" ] || _FELIX_INSTR_J="$(cd "$_FELIX_INSTR_J" 2>/dev/null && pwd -P)" || _FELIX_INSTR_J=""
  if [ -z "$_FELIX_INSTR_J" ] || ! mkdir -p "$_FELIX_INSTR_J/u"; then
    _FELIX_INSTR_J=""; _felix_instr_add unknown SUITE "no directory could be made under ${TMPDIR:-/tmp} for the run tree"; return 0
  fi
  trap '_felix_instr_stop 143' TERM; trap '_felix_instr_stop 130' INT; trap '_felix_instr_stop 129' HUP
  if command -v _felix_bind_exit >/dev/null 2>&1; then trap '_felix_instr_clean; _felix_bind_exit' EXIT; else trap '_felix_instr_clean' EXIT; fi
  if [ "$nu" -gt 0 ]; then
    if _felix_instr_tree "$root" "$_FELIX_INSTR_J/t" "$h" "$b" "$gp" 1 "$br"; then
      jobs="$(_felix_instr_jobs)"
      _felix_instr_runall "$jobs" "$_FELIX_INSTR_J/t" "$nu"
      i=1; while [ "$i" -le "$nu" ]; do _felix_instr_verdict "$i"; i=$((i + 1)); done
      _felix_instr_cat "$root" "$h" "$tp/assertions.tsv" > "$_FELIX_INSTR_J/h.manifest" 2>/dev/null
      _felix_instr_names "$_FELIX_INSTR_J/h.manifest"
    else
      _felix_instr_add unknown SUITE "the run tree T could not be made from $h and $b under $_FELIX_INSTR_J"
    fi
  fi
  [ "$mach" != 1 ] || _felix_instr_canary "$root" "$b" "$h" "$gp" "$br"
  _felix_instr_clean
  trap - TERM INT HUP
  if command -v _felix_bind_exit >/dev/null 2>&1; then trap '_felix_bind_exit' EXIT; else trap - EXIT; fi
  _FELIX_INSTR_NOTE="P's instrument parts ran over this tree as the base holds them: $nu unit(s) of its suite in part mode"
  [ "$mach" != 1 ] || _FELIX_INSTR_NOTE="$_FELIX_INSTR_NOTE, every instrument unit since this tree changes the machinery, and the canary under this tree's driver"
  _FELIX_INSTR_NOTE="$_FELIX_INSTR_NOTE."
  return 0
}

# The runs themselves: the run tree, the units, the job count and the removal.
# shellcheck source=lib/instrument-run.sh
. "$(dirname "${BASH_SOURCE[0]:-$0}")/instrument-run.sh" 2>/dev/null || :
