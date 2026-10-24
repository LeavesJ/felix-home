# tests/select-compile.sh: felix testmap --compile (audit b30, contract B16 to B20). It turns the
# directory a traced run left (D/units.tsv, and D/<unit>/<pid>.trace for each bash process the
# unit started) into a map: C/felix-testmap/<platform>/<M>/map.tsv, where M is the commit the
# traced run was made at. Nothing in D is run, sourced or evaluated; it is read as text. It has no
# #! line, is not executable and defines functions and nothing else. Loaded by lib/testmap.sh.
#
# The map is tab separated: a line `map v1 M P epoch source`; a line `unit NAME STATUS SECONDS REASON`
# for each unit of the traced run, in its order; then, in byte order with none twice, a line
# `fn UNIT PATH FUNCTION` for each function a unit entered and `top UNIT PATH` for each file whose
# top level it ran. A function entered implies its file's top level ran, so it has a top row too.
# STATUS is complete, incomplete (a command ran that the tracer could not follow, or there is no
# trace) or unfaithful (the unit failed in the traced run, or read PIPESTATUS right after a pipeline
# under bash 3.2, which resets it after every DEBUG trap). A path is made relative to the traced
# checkout, or to engine/harness for a copy of the harness a fixture made, and kept only when it is
# a file in M.

_tm_cmp_die() { printf 'felix testmap: %s\n' "$1" >&2; }
# DIR -> the map, or one line on stderr and status 1.
_tm_compile() {
  local t rc
  t="$(mktemp -d "${TMPDIR:-/tmp}/felix-testmap.XXXXXX" 2>/dev/null)" && [ -d "$t" ] || { _tm_cmp_die "cannot make a scratch directory"; return 1; }
  _tm_cmp_run "$1" "$t"; rc=$?
  rm -rf "$t"
  return "$rc"
}
# D/units.tsv in a normal form, one line a fact: V run T; V top PATH; V head ID STATE; V end ID STATE;
# U NAME VERDICT WALL CPU. A line that is not one of those makes it BAD.
_tm_cmp_units() {
  LC_ALL=C awk -F'\t' -v OFS='\t' '
    $1 == "run" && NF == 6 && $2 == "v1" { r++; print "V", "run", $3; next }
    $1 == "top" && NF == 2 { p++; print "V", "top", $2; next }
    ($1 == "head" || $1 == "end") && NF == 3 { if ($1 == "head") h++; else e++; print "V", $1, $2, $3; next }
    $1 == "unit" && NF == 5 && ($3 == "pass" || $3 == "fail") && $2 ~ /^[A-Za-z0-9][A-Za-z0-9._-]*$/ { u++; print "U", $2, $3, $4, $5; next }
    { bad = 1 }
    END { if (bad || r != 1 || p != 1 || h != 1 || e != 1 || u < 1) print "BAD" }
  ' "$1" 2>/dev/null
}
# The trace files of one unit: each line is classified on its own, and the output is
# UNIT KIND ...: F PATH FUNCTION (a function entered), T PATH (a top level), I REASON (a command
# the tracer could not follow, B13), U REASON (B14), B (a line that is not a record).
_tm_cmp_classify() {   # FILE...  (the unit is TM_UNIT in the environment)
  LC_ALL=C awk '
  function push(w, v, x) { TN++; TW[TN] = w; TV[TN] = v; TX[TN] = x }
  function tokenize(s,   i, n, c, w, v, x, st, j, d) {
    TN = 0; n = length(s); i = 1; w = ""; v = ""; x = 0; st = 0
    while (i <= n) {
      c = substr(s, i, 1)
      if (c == " " || c == "\t") { if (st) { push(w, v, x); w = ""; v = ""; x = 0; st = 0 } i++; continue }
      if (c == ";" || c == "|" || c == "&" || c == "(" || c == ")" || c == "<" || c == ">") break
      st = 1
      if (c == "\047") {
        j = index(substr(s, i + 1), "\047")
        if (j == 0) { w = w substr(s, i); v = v substr(s, i + 1); i = n + 1; break }
        w = w substr(s, i, j + 1); v = v substr(s, i + 1, j - 1); i += j + 1; continue
      }
      if (c == "$" && substr(s, i + 1, 1) == "\047") {
        j = i + 2; d = ""
        while (j <= n && substr(s, j, 1) != "\047") { if (substr(s, j, 1) == "\\") { d = d substr(s, j, 2); j += 2 } else { d = d substr(s, j, 1); j++ } }
        w = w substr(s, i, j - i + 1); v = v d; i = j + 1; continue
      }
      if (c == "\"") {
        j = i + 1; d = ""
        while (j <= n && substr(s, j, 1) != "\"") {
          if (substr(s, j, 1) == "\\" && j < n) { d = d substr(s, j + 1, 1); j += 2; continue }
          if (substr(s, j, 1) == "$" || substr(s, j, 1) == "`") x = 1
          d = d substr(s, j, 1); j++
        }
        w = w substr(s, i, j - i + 1); v = v d; i = j + 1; continue
      }
      if (c == "\\") { w = w substr(s, i, 2); v = v substr(s, i + 1, 1); i += 2; continue }
      if (c == "$" || c == "`") x = 1
      w = w c; v = v c; i++
    }
    if (st) push(w, v, x)
  }
  function isasg(w) { return w ~ /^[A-Za-z_][A-Za-z0-9_]*\+?=/ }
  function shortc(s) { gsub(/[\t\r\n]/, " ", s); return substr(s, 1, 160) }
  # Mode 3: bash 3.2 to 4.0, a DEBUG trap, which sees every command whole; mode 5: xtrace.
  # The reason names the command; "" when the tracer is left in place.
  function analyze(s, mode,   k, n, w, j, cw, nm, o) {
    if (index(s, "BASH_ENV") == 0 && index(s, "env") == 0 && index(s, "exec") == 0 && index(s, "trap") == 0 && index(s, "set") == 0 && index(s, "PS4") == 0 && index(s, "XTRACEFD") == 0) return ""
    tokenize(s); n = TN; k = 1
    while (k <= n && isasg(TW[k])) {
      nm = TW[k]; sub(/\+?=.*$/, "", nm)
      if (nm == "BASH_ENV" || (mode == 5 && (nm == "PS4" || nm == "BASH_XTRACEFD"))) return "a command started with " nm " set: " shortc(s)
      k++
    }
    while (k <= n && !TX[k] && (TV[k] == "command" || TV[k] == "builtin" || TV[k] == "nohup" || TV[k] == "nice" || TV[k] == "time" || TV[k] == "exec")) {
      if (TV[k] == "exec" && k < n && TV[k + 1] ~ /^-[A-Za-z]*c[A-Za-z]*$/) return "a command started without the tracer: " shortc(s)
      k++
    }
    if (k > n || TX[k]) return ""
    cw = TV[k]; sub(/^.*\//, "", cw)
    o = "a command started without the tracer: " shortc(s)
    if (cw == "env") {
      for (j = k + 1; j <= n; j++) {
        w = TV[j]
        if (w == "--") break
        if (w == "-" || w == "--ignore-environment" || w ~ /^-[A-Za-z]*i[A-Za-z]*$/) return o
        if ((w == "-u" || w == "--unset") && TV[j + 1] == "BASH_ENV") return o
        if (w == "-uBASH_ENV" || w == "--unset=BASH_ENV") return o
        if (w == "-u" || w == "--unset") { j++; continue }
        if (substr(w, 1, 1) == "-" || isasg(TW[j])) continue
        break
      }
      return ""
    }
    if (cw == "unset") { for (j = k + 1; j <= n; j++) if (TV[j] == "BASH_ENV") return o; return "" }
    if (cw == "export" || cw == "declare" || cw == "typeset" || cw == "readonly" || cw == "local") {
      for (j = k + 1; j <= n; j++) {
        nm = TV[j]; sub(/\+?=.*$/, "", nm)
        if (nm == "BASH_ENV" || (mode == 5 && (nm == "PS4" || nm == "BASH_XTRACEFD"))) return "a command started with " nm " set: " shortc(s)
      }
      return ""
    }
    if (cw == "trap" && mode == 3) {
      for (j = k + 1; j <= n; j++) if (TV[j] ~ /^-[a-z]*[pl][a-z]*$/) return ""
      for (j = k + 1; j <= n; j++) if (TV[j] == "DEBUG") return "the tracer was switched off: " shortc(s)
      return ""
    }
    if (cw == "set") {
      for (j = k + 1; j <= n; j++) {
        w = TV[j]
        if (mode == 3 && (w ~ /^\+[A-Za-z]*T[A-Za-z]*$/ || (w == "+o" && TV[j + 1] == "functrace"))) return "the tracer was switched off: " shortc(s)
        if (mode == 5 && (w ~ /^\+[A-Za-z]*x[A-Za-z]*$/ || (w == "+o" && TV[j + 1] == "xtrace"))) return "the tracer was switched off: " shortc(s)
      }
    }
    return ""
  }
  function emit(line) { if (!(line in SEEN)) { SEEN[line] = 1; print u "\t" line } }
  BEGIN { FS = "\t"; u = ENVIRON["TM_UNIT"] }
  {
    if ($0 !~ /^[a-z]/) { emit("B"); next }
    if ($1 == "fn" && NF == 3 && $2 != "" && $3 != "") { emit("F\t" $2 "\t" $3); next }
    if ($1 == "top" && NF == 2 && $2 != "") { emit("T\t" $2); next }
    if ($1 == "ps" && NF == 2 && $2 != "") { emit("U\tPIPESTATUS is read right after a pipeline in " $2); next }
    if ($1 == "cmd" && NF >= 3) {
      t = $3; for (j = 4; j <= NF; j++) t = t " " $j
      r = analyze(t, 3); if (r != "") emit("I\t" r)
      next
    }
    if ($1 ~ /^x+$/ && NF >= 4) {
      t = $4; for (j = 5; j <= NF; j++) t = t " " $j
      if ($2 != "") { if ($3 == "" || $3 == "source") emit("T\t" $2); else emit("F\t" $2 "\t" $3) }
      r = analyze(t, 5); if (r != "") emit("I\t" r)
      next
    }
    emit("B")
  }
  ' "$@"
}
# UNIT DIR OUT: the classified lines of every trace file in DIR, appended to OUT, in batches
# of 400 files so that no command line grows past what exec allows. Sets _tm_nf, the files.
_tm_cmp_unit() {
  local f chunk n=0
  chunk=(); _tm_nf=0
  for f in "$2"/*.trace; do
    { [ -f "$f" ] && [ ! -L "$f" ]; } || continue
    chunk[n++]="$f"; _tm_nf=$((_tm_nf + 1))
    if [ "$n" -ge 400 ]; then TM_UNIT="$1" _tm_cmp_classify "${chunk[@]}" >> "$3"; chunk=(); n=0; fi
  done
  [ "$n" -eq 0 ] || TM_UNIT="$1" _tm_cmp_classify "${chunk[@]}" >> "$3"
  return 0
}
# The map's unit lines and rows, written to $TM_OUT/map.body and $TM_OUT/rows, and the sums to
# $TM_OUT/sums. Files in order: the normal form of units.tsv, the files of M, the untraced run's
# facts (or an empty file), the classified records of every unit, and the units that have a trace.
# The environment holds TM_TOP and TM_TOPP (the traced checkout's top as units.tsv names it, and
# with links resolved), TM_SRC (untraced or traced) and TM_OUT.
_tm_cmp_assemble() {
  LC_ALL=C awk '
  function norm(p,   n, a, i, o, k, r) {
    if (p == "") return ""
    n = split(p, a, "/"); k = 0
    for (i = 1; i <= n; i++) {
      if (a[i] == "" || a[i] == ".") continue
      if (a[i] == "..") { if (k > 0) k--; continue }
      k++; o[k] = a[i]
    }
    r = ""
    for (i = 1; i <= k; i++) r = r (i > 1 ? "/" : "") o[i]
    if (substr(p, 1, 1) == "/") r = "/" r
    return r
  }
  function rel(p,   q, i, j, last, s) {
    q = norm(p)
    if (substr(q, 1, 1) != "/") return ""
    if (top1 != "" && (q == top1 || index(q, top1 "/") == 1)) s = substr(q, length(top1) + 2)
    else if (top2 != "" && (q == top2 || index(q, top2 "/") == 1)) s = substr(q, length(top2) + 2)
    else {
      last = 0; i = 1
      while ((j = index(substr(q, i), "/harness/")) > 0) { last = i + j - 1; i = last + 1 }
      if (last == 0) return ""
      s = "engine/harness/" substr(q, last + 9)
    }
    if (s == "" || !(s in LS) || s == "engine/harness/tests/trace.sh") return ""
    return s
  }
  function centi(s,   a) { split(s, a, "."); return a[1] * 100 + a[2] }
  function clean(s) { gsub(/[\t\r\n]/, " ", s); return substr(s, 1, 400) }
  function add(arr, u, r) { if (index(arr[u] "; ", r "; ") == 0) arr[u] = (arr[u] == "" ? "" : arr[u] "; ") r }
  BEGIN {
    FS = "\t"; OFS = "\t"; top1 = norm(ENVIRON["TM_TOP"]); top2 = norm(ENVIRON["TM_TOPP"]); src = ENVIRON["TM_SRC"]; od = ENVIRON["TM_OUT"]
    rows = od "/rows"; sums = od "/sums"; body = od "/map.body"; printf "" > rows
  }
  FILENAME == ARGV[1] { if ($1 == "U") { nu++; UN[nu] = $2; VD[$2] = $3; TC[$2] = $5 } next }
  FILENAME == ARGV[2] { LS[$0] = 1; next }
  FILENAME == ARGV[3] { if ($1 == "unit" && $5 ~ /^[0-9]+\.[0-9][0-9]$/) UC[$2] = $5; next }
  FILENAME == ARGV[5] { HAVE[$1] = 1; next }
  {
    u = $1; k = $2
    if (k == "F") { r = rel($3); if (r != "") { print "fn", u, r, $4 > rows; print "top", u, r > rows } }
    else if (k == "T") { r = rel($3); if (r != "") print "top", u, r > rows }
    else if (k == "I") add(IR, u, $3)
    else if (k == "U") add(UR, u, $3)
    else if (k == "B") BAD[u] = 1
  }
  END {
    for (i = 1; i <= nu; i++) {
      u = UN[i]; st = "complete"; why = "-"
      if (VD[u] == "fail" || (u in UR)) {
        st = "unfaithful"; why = ""
        if (VD[u] == "fail") why = "failed under tracing"
        if (u in UR) why = (why == "" ? "" : why "; ") UR[u]
        nuf++
      } else if (!(u in HAVE) || (u in IR) || (u in BAD)) {
        st = "incomplete"; why = ""
        if (!(u in HAVE)) why = "no trace was written"
        if (u in IR) why = (why == "" ? "" : why "; ") IR[u]
        if (u in BAD) why = (why == "" ? "" : why "; ") "a trace line could not be read"
        ninc++
      } else ncp++
      sec = "unknown"
      if (src == "untraced") { if (u in UC) sec = UC[u] }
      else if (TC[u] ~ /^[0-9]+\.[0-9][0-9]$/) sec = TC[u]
      if ((u in UC) && TC[u] ~ /^[0-9]+\.[0-9][0-9]$/) { nb++; tsum += centi(TC[u]); usum += centi(UC[u]) }
      print "unit", u, st, sec, clean(why) > body
    }
    print nu, ncp + 0, ninc + 0, nuf + 0 > sums
    print nb + 0, tsum + 0, usum + 0 > sums
  }
  ' "$@"
}
# DIR (a trace directory), the scratch directory T: the map, three lines on stdout.
_tm_cmp_run() {
  local d="$1" t="$2" top="" topp="" m="" hs="" es="" eid="" tid="" bad="" pl c u v w cf src map dir x y n ncp ninc nuf nb ts us r
  [ -f "$d/units.tsv" ] && [ -r "$d/units.tsv" ] || { _tm_cmp_die "the traced run did not reach its end: [$d/units.tsv] is missing or unreadable"; return 1; }
  _tm_cmp_units "$d/units.tsv" > "$t/u.norm" || :
  while IFS=$'\t' read -r x y u v w; do
    case "$x" in
      BAD) bad=1 ;;
      V) case "$y" in run) tid="$u" ;; top) top="$u" ;; head) m="$u"; hs="$v" ;; end) eid="$u"; es="$v" ;; esac ;;
    esac
  done < "$t/u.norm"
  [ -z "$bad" ] || { _tm_cmp_die "[$d/units.tsv] is not a traced run's facts: a line is wrong, or the run, top, head or end line is missing, or there is no unit"; return 1; }
  [ "$hs" = clean ] && [ "$es" = clean ] && [ -n "$m" ] && [ "$m" = "$eid" ] || { _tm_cmp_die "a map is made only from a traced run of one clean commit: it began at [$m] $hs and ended at [$eid] $es"; return 1; }
  case "$m" in *[!0123456789abcdef]*|"") _tm_cmp_die "[$m] is not a commit id"; return 1 ;; esac
  [ "${#m}" -eq 40 ] || [ "${#m}" -eq 64 ] || { _tm_cmp_die "[$m] is not a full commit id"; return 1; }
  x="$(GIT_OPTIONAL_LOCKS=0 git rev-parse --show-toplevel 2>/dev/null)" && [ -n "$x" ] || { _tm_cmp_die "$PWD is not in a git checkout"; return 1; }
  GIT_OPTIONAL_LOCKS=0 git cat-file -e "$m^{commit}" 2>/dev/null || { _tm_cmp_die "the commit $m is not in this checkout"; return 1; }
  pl="$(_tm_plat)"; [ -n "$pl" ] || { _tm_cmp_die "the platform cannot be read"; return 1; }
  c="$(GIT_OPTIONAL_LOCKS=0 git rev-parse --git-common-dir 2>/dev/null)" && [ -n "$c" ] || { _tm_cmp_die "the common git directory cannot be read"; return 1; }
  case "$c" in /*) ;; *) c="${x%/}/$c" ;; esac
  dir="$c/felix-testmap/$pl/$m"
  for x in "$c/felix-testmap" "$c/felix-testmap/$pl" "$dir"; do
    if [ -L "$x" ]; then _tm_cmp_die "[$x] is a symbolic link"; return 1; fi
    if [ -e "$x" ] && [ ! -d "$x" ]; then _tm_cmp_die "[$x] is not a directory"; return 1; fi
  done
  topp="$(cd -P "$top" 2>/dev/null && pwd -P)" || topp=""
  GIT_OPTIONAL_LOCKS=0 git -c core.quotepath=off ls-tree -r --name-only "$m" > "$t/ls" 2>/dev/null || { _tm_cmp_die "the files of $m cannot be listed"; return 1; }
  src=traced; : > "$t/runs"
  x="$c/felix-testmap/runs/$tid.tsv"
  if [ -f "$x" ] && [ ! -L "$x" ] && [ -r "$x" ]; then
    { read -r y; } < "$x" 2>/dev/null
    case "$y" in "run"$'\t'"v1"$'\t'"$tid"$'\t'*) cat "$x" > "$t/runs" 2>/dev/null && src=untraced ;; esac
  fi
  : > "$t/all"; : > "$t/have"
  while IFS=$'\t' read -r x u v w cf; do
    [ "$x" = U ] || continue
    _tm_nf=0
    if [ -d "$d/$u" ] && [ ! -L "$d/$u" ]; then _tm_cmp_unit "$u" "$d/$u" "$t/all"; fi
    [ "$_tm_nf" -eq 0 ] || printf '%s\n' "$u" >> "$t/have"
  done < "$t/u.norm"
  LC_ALL=C sort -u "$t/all" > "$t/all.s" 2>/dev/null
  TM_TOP="$top" TM_TOPP="$topp" TM_SRC="$src" TM_OUT="$t" _tm_cmp_assemble "$t/u.norm" "$t/ls" "$t/runs" "$t/all.s" "$t/have" || { _tm_cmp_die "the map could not be made"; return 1; }
  mkdir -p "$dir" 2>/dev/null || { _tm_cmp_die "[$dir] cannot be made"; return 1; }
  map="$dir/map.tsv"
  { printf 'map\tv1\t%s\t%s\t%s\t%s\n' "$m" "$pl" "$(date +%s)" "$src"; cat "$t/map.body"; LC_ALL=C sort -u "$t/rows"; } > "$map.tmp.$$" 2>/dev/null && mv -f "$map.tmp.$$" "$map" 2>/dev/null || { rm -f "$map.tmp.$$" 2>/dev/null; _tm_cmp_die "[$map] cannot be written"; return 1; }
  { read -r n ncp ninc nuf; read -r nb ts us; } < "$t/sums"
  printf 'testmap: map for %s (%s) written to %s\n' "$m" "$pl" "$map"
  printf 'testmap: %s units: %s complete, %s incomplete, %s unfaithful\n' "$n" "$ncp" "$ninc" "$nuf"
  if [ "$src" = untraced ] && [ "${nb:-0}" -gt 0 ] && [ "${us:-0}" -gt 0 ]; then
    r=$(( (ts * 100 + us / 2) / us ))
    printf 'testmap: unit time from untraced runs: traced CPU %d.%02d s against untraced %d.%02d s for the same tree, %d.%02dx\n' \
      $((ts / 100)) $((ts % 100)) $((us / 100)) $((us % 100)) $((r / 100)) $((r % 100))
  elif [ "$src" = untraced ]; then
    printf 'testmap: unit time from the traced run: the untraced run of tree %s has no CPU time to set against it, so the tracer overhead is not known\n' "$tid"
  else
    printf 'testmap: unit time from the traced run: no untraced run of tree %s is recorded here, so the tracer'"'"'s overhead is not known\n' "$tid"
  fi
  return 0
}
