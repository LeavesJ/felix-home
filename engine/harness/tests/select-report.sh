# tests/select-report.sh: felix testmap --report (audit b30, contract B22 to B29). From a git
# checkout it says which of the suite's units a change would run and why, using the newest map of an
# ancestor of the base, and when the answer is "all of them". It runs no suite, fetches nothing and
# writes nothing: git runs with GIT_OPTIONAL_LOCKS=0, the scratch files are in a temporary
# directory, and the checkout, its git directory and the maps are only read. It has no #! line, is
# not executable and defines functions and nothing else. Loaded by lib/testmap.sh after
# select-parse.sh, whose readers of the tree's units, a file's functions and an added line it uses.

_tm_rp_git() { GIT_OPTIONAL_LOCKS=0 git -C "$_tm_rtop" -c core.quotepath=off "$@"; }
# EPOCH -> YYYY-MM-DD in UTC (proleptic Gregorian, from days since 1970-01-01).
_tm_rp_day() {
  local z era doe yoe y doy mp d m
  z=$(( $1 / 86400 + 719468 ))
  era=$(( (z >= 0 ? z : z - 146096) / 146097 ))
  doe=$(( z - era * 146097 ))
  yoe=$(( (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365 ))
  y=$(( yoe + era * 400 )); doy=$(( doe - (365 * yoe + yoe / 4 - yoe / 100) ))
  mp=$(( (5 * doy + 2) / 153 )); d=$(( doy - (153 * mp + 2) / 5 + 1 ))
  m=$(( mp < 10 ? mp + 3 : mp - 9 )); [ "$m" -gt 2 ] || y=$((y + 1))
  printf '%04d-%02d-%02d' "$y" "$m" "$d"
}
# BASEID PLATFORM COMMONDIR -> _tm_cid and _tm_cct: the newest map (by its commit's committer date)
# whose directory is a full commit id that exists here and is the base or an ancestor of it.
_tm_rp_choose() {
  local root="$3/felix-testmap/$2" d id ct best="" bct=0
  _tm_cid=""; _tm_cct=""
  [ ! -L "$3/felix-testmap" ] && [ -d "$root" ] && [ ! -L "$root" ] || return 1
  for d in "$root"/*; do
    id="${d##*/}"
    case "$id" in ""|*[!0123456789abcdef]*) continue ;; esac
    [ "${#id}" -eq 40 ] || [ "${#id}" -eq 64 ] || continue
    [ -d "$d" ] && [ ! -L "$d" ] && [ -f "$d/map.tsv" ] || continue
    _tm_rp_git cat-file -e "$id^{commit}" 2>/dev/null || continue
    _tm_rp_git merge-base --is-ancestor "$id" "$1" 2>/dev/null || continue
    ct="$(_tm_rp_git cat-file commit "$id" 2>/dev/null | LC_ALL=C awk 'NF == 0 { exit } /^committer / { print $(NF - 1); exit }')"
    case "$ct" in ""|*[!0123456789]*) continue ;; esac
    if [ -z "$best" ] || [ "$ct" -gt "$bct" ] || { [ "$ct" -eq "$bct" ] && [ "$id" \< "$best" ]; }; then best="$id"; bct="$ct"; fi
  done
  [ -n "$best" ] || return 1
  _tm_cid="$best"; _tm_cct="$bct"
}
# FILE ID PLATFORM: the map in tagged lines (M unit status seconds reason; F unit path function;
# T unit path), then `~OK source` or `~ERR why` (B18's shape, or not).
_tm_rp_mapread() {
  LC_ALL=C awk -F'\t' -v OFS='\t' -v id="$2" -v pl="$3" '
  function cl(s) { gsub(/[^ -~]/, "?", s); return s }
  function bad(m) { why = m; exit 1 }
  NR == 1 {
    if ($1 != "map" || NF != 6) bad("line 1 is not a map line of six fields")
    if ($2 != "v1") bad("the version is [" cl($2) "], not v1")
    if ($3 != id) bad("line 1 names the commit [" cl($3) "], not " id)
    if ($4 != pl) bad("line 1 names the platform [" cl($4) "], not " pl)
    if ($5 !~ /^[0-9]+$/) bad("the time made [" cl($5) "] is not a number of seconds")
    if ($6 != "untraced" && $6 != "traced") bad("the source [" cl($6) "] is neither untraced nor traced")
    src = $6; next
  }
  $1 == "unit" {
    if (NF != 5) bad("line " NR " is a unit line without five fields")
    if (rows) bad("line " NR " is a unit line after a function or top line")
    if ($2 !~ /^[A-Za-z0-9][A-Za-z0-9._-]*$/) bad("line " NR ": [" cl($2) "] is not a unit name")
    if ($3 != "complete" && $3 != "incomplete" && $3 != "unfaithful") bad("line " NR ": the status [" cl($3) "] is not complete, incomplete or unfaithful")
    if ($4 != "unknown" && $4 !~ /^[0-9]+\.[0-9][0-9]$/) bad("line " NR ": the seconds [" cl($4) "] are not two decimals or unknown")
    if ($5 == "") bad("line " NR " has no reason")
    if ($2 in SEEN) bad("line " NR ": the unit [" cl($2) "] is listed twice")
    SEEN[$2] = 1; nu++; print "M", $2, $3, $4, $5; next
  }
  $1 == "fn" && NF == 4 && $2 != "" && $3 != "" && $4 != "" { rows++; print "F", $2, $3, $4; next }
  $1 == "top" && NF == 3 && $2 != "" && $3 != "" { rows++; print "T", $2, $3; next }
  { bad("line " NR " is not a map line") }
  END {
    if (why == "" && NR == 0) why = "the file is empty"
    if (why == "" && nu == 0) why = "it has no unit line"
    if (why != "") print "~ERR", why; else print "~OK", src
  }
  ' "$1" 2>/dev/null
}
# PATH -> out (code outside the units), part (a unit's part), record or other.
_tm_rp_kind() {
  case "$1" in
    engine/harness/tests/parts/[0123456789][0123456789][0123456789][0123456789]-*.sh)
      case "${1##*/}" in 000[0123456789]-*|9990-*) echo out ;; *) echo part ;; esac ;;
    engine/harness/tests/run|engine/harness/tests/red|engine/harness/tests/receipt.sh|engine/harness/tests/groups.tsv|engine/harness/tests/trace.sh|engine/harness/tests/select.sh|engine/harness/tests/select-*.sh|engine/harness/lib/testmap.sh|.github/*) echo out ;;
    engine/harness/tests/assertions.tsv|engine/harness/tests/red.tsv) echo record ;;
    *) echo other ;;
  esac
}
# BASE-COMMIT OUT: the change since the commit as lines `KIND STATUS PATH`, by path: tracked files
# that differ (staged or not), added or deleted with no rename detection, and untracked files that
# are not ignored (status ?). Fails when git cannot say.
_tm_rp_changes() {
  local m="$1" o="$2" st p k tab=$'\t'
  { _tm_rp_git diff --name-status --no-renames --no-ext-diff "$m" && _tm_rp_git ls-files --others --exclude-standard | LC_ALL=C awk -v OFS='\t' '{ print "?", $0 }'; } > "$o.raw" 2>/dev/null || return 1
  : > "$o.cls"
  while IFS="$tab" read -r st p; do
    [ -n "$p" ] || continue
    k="$(_tm_rp_kind "$p")"
    printf '%s\t%s\t%s\n' "$p" "$k" "${st:0:1}" >> "$o.cls"
  done < "$o.raw"
  LC_ALL=C sort -u "$o.cls" | LC_ALL=C awk -F'\t' -v OFS='\t' '!($1 in S) { S[$1] = 1; print "C", $1, $2, $3 }' > "$o"
}
# TOP BASE-COMMIT CHANGES TAGGED OUT: for each changed path of kind other that a map row reads, both
# versions read as functions (B28): R path ok; D path fn (defined); X path fn (body differs);
# Y path (top level differs). The file is read as text and never run.
_tm_rp_parse() {
  local top="$1" m="$2" t="$5" k st p w tab=$'\t' x y
  : > "$t.R"; : > "$t.rp"
  LC_ALL=C awk -F'\t' '$1 == "F" { print $3 } $1 == "T" { print $3 }' "$4" | LC_ALL=C sort -u > "$t.rp"
  while IFS="$tab" read -r x p k st; do
    [ "$k" = other ] || continue
    grep -qxF -e "$p" "$t.rp" || continue
    : > "$t.old"; : > "$t.new"; w=1
    case "$st" in A|"?") ;; *) _tm_rp_git cat-file blob "$m:$p" > "$t.old" 2>/dev/null || w=0 ;; esac
    case "$st" in D) ;; *) if [ -f "$top/$p" ] && [ -r "$top/$p" ]; then cat "$top/$p" > "$t.new" 2>/dev/null || w=0; else w=0; fi ;; esac
    if [ "$w" -eq 0 ]; then printf 'R\t%s\t0\n' "$p" >> "$t.R"; continue; fi
    _tm_ps_fn "$t.old" "$t.new" > "$t.fn"
    { read -r x y < "$t.fn"; } 2>/dev/null
    if [ "$y" = 1 ]; then
      printf 'R\t%s\t1\n' "$p" >> "$t.R"
      LC_ALL=C awk -F'\t' -v OFS='\t' -v p="$p" '$1 == "def" { print "D", p, $2 } $1 == "fn" { print "X", p, $2 } $1 == "top" { print "Y", p }' "$t.fn" >> "$t.R"
    else printf 'R\t%s\t0\n' "$p" >> "$t.R"; fi
  done < "$3"
}
# TOP BASE-COMMIT CHANGES OUT: `PATH LINE` for each line the change adds that makes a computed call
# (B26), in every changed file that is not a part file.
_tm_rp_calls() {
  local top="$1" m="$2" st p k x
  { _tm_rp_git diff -U0 --no-renames --no-ext-diff --no-textconv --no-color --src-prefix=a/ --dst-prefix=b/ "$m" 2>/dev/null | _tm_ps_calls diff
    while IFS=$'\t' read -r x p k st; do
      [ "$st" = "?" ] && [ -f "$top/$p" ] && [ -r "$top/$p" ] || continue
      case "$p" in engine/harness/tests/parts/[0123456789][0123456789][0123456789][0123456789]-*.sh) continue ;; esac
      TM_PATH="$p" _tm_ps_calls whole < "$top/$p"
    done < "$3"
  } | LC_ALL=C awk -F'\t' -v OFS='\t' '$1 !~ /^engine\/harness\/tests\/parts\/[0-9][0-9][0-9][0-9]-.*\.sh$/' > "$4"
}
# IN (tagged lines: U unit parts; M unit status seconds reason; F unit path function; T unit path;
# C path kind status; P part-in-the-map; R path ok; D path function; X path function; Y path) -> the
# selection (B27, B29): `E text` for each file a map does not read, `S unit reasons` in the tree's
# order, then `N k n percent anychange`, with ? for a share that is not known.
_tm_rp_select() {
  LC_ALL=C awk -F'\t' -v OFS='\t' '
  function cs(s,   a) { split(s, a, "."); return a[1] * 100 + a[2] }
  function join(a, b) { return a == "" ? b : (b == "" ? a : a "; " b) }
  function isother(p) { return (p in CK) && CK[p] == "other" }
  function parsed(p) { return (p in RK) && RK[p] == 1 }
  function unparsed(u, p) {
    if ((u, p) in PFS) return
    PFS[u, p] = 1; R4[u] = join(R4[u], p " could not be parsed into functions")
  }
  $1 == "U" { nu++; UN[nu] = $2; UP[$2] = $3; TREE[$2] = 1; next }
  $1 == "M" { MU[$2] = 1; MS[$2] = $3; MC[$2] = $4; MR[$2] = $5; next }
  $1 == "F" { nf++; FU[nf] = $2; FP[nf] = $3; FN[nf] = $4; ROWP[$3] = 1; next }
  $1 == "T" { nt++; TU[nt] = $2; TP[nt] = $3; ROWP[$3] = 1; next }
  $1 == "C" { nc++; CP[nc] = $2; CK[$2] = $3; next }
  $1 == "P" { MP[$2] = 1; next }
  $1 == "R" { RK[$2] = $3; next }
  $1 == "D" { DF[$2, $3] = 1; next }
  $1 == "X" { XF[$2, $3] = 1; next }
  $1 == "Y" { YT[$2] = 1; next }
  END {
    for (i = 1; i <= nu; i++) { n = split(UP[UN[i]], a, " "); for (j = 1; j <= n; j++) if (index(a[j], "1010-") == 1) HOLD[UN[i]] = 1 }
    hold = 0; for (u in HOLD) hold = 1
    for (i = 1; i <= nc; i++) {
      p = CP[i]
      if ((CK[p] == "other" && !(p in ROWP)) || (CK[p] == "record" && !hold)) print "E", p " changed and no map reads it"
    }
    for (f = 1; f <= nf; f++) {
      p = FP[f]; u = FU[f]
      if (!(u in TREE) || !isother(p)) continue
      if (!parsed(p)) unparsed(u, p)
      else if (((p, FN[f]) in XF) || !((p, FN[f]) in DF)) R3[u] = join(R3[u], "function " FN[f] " in " p)
    }
    for (f = 1; f <= nt; f++) {
      p = TP[f]; u = TU[f]
      if (!(u in TREE) || !isother(p)) continue
      if (!parsed(p)) unparsed(u, p)
      else if (p in YT) R5[u] = join(R5[u], "top level of " p)
    }
    k = 0; tot = 0; sel = 0; unk = 0
    for (i = 1; i <= nu; i++) {
      u = UN[i]; r = ""
      if (nc > 0) {
        if (!(u in MU)) r = join(r, "new unit")
        n = split(UP[u], a, " ")
        for (j = 1; j <= n; j++) {
          q = "engine/harness/tests/parts/" a[j]
          if (!(a[j] in MP)) r = join(r, "new part " a[j])
          else if ((q in CK) && CK[q] == "part") r = join(r, "changed part " a[j])
        }
        r = join(r, R3[u]); r = join(r, R4[u]); r = join(r, R5[u])
        if (u in HOLD) for (m = 1; m <= nc; m++) if (CK[CP[m]] == "record") r = join(r, "record file " CP[m])
        if ((u in MU) && MS[u] != "complete") r = join(r, MS[u] " in the map: " MR[u])
      }
      if ((u in MU) && MC[u] == "unknown") unk = 1
      else if (u in MU) tot += cs(MC[u])
      if (r != "") { print "S", u, r; k++; if ((u in MU) && MC[u] != "unknown") sel += cs(MC[u]) }
    }
    pct = "?"
    if (!unk && tot > 0) pct = (sel * 100 - (sel * 100) % tot) / tot
    print "N", k, nu, pct, (nc > 0) ? 1 : 0
  }
  ' "$1" 2>/dev/null
}
# TOP BASE TMP: lines 2 to 8 once the checkout is known (B22).
_tm_rp_main() {
  local top="$1" base="$2" t="$3" bid="" pl c now mf last why src x y k n pct any tab=$'\t'
  local ro='report only: nothing was run, and no verdict, receipt or gate changes'
  printf 'testmap: %s\n' "$top"
  case "$base" in -*) ;; *) bid="$(_tm_rp_git rev-parse --verify --quiet "$base^{commit}" 2>/dev/null)" || bid="" ;; esac
  if [ -z "$bid" ]; then
    printf 'base: %s unknown\nmap: none\neverything runs: the base [%s] is not a commit here\nresult: everything runs\n%s\n' "$base" "$base" "$ro"
    return 0
  fi
  printf 'base: %s %s\n' "$base" "$bid"
  pl="$(_tm_plat)"; c="$(_tm_rp_git rev-parse --git-common-dir 2>/dev/null)"
  case "$c" in ""|/*) ;; *) c="$top/$c" ;; esac
  if [ -z "$pl" ] || [ -z "$c" ] || ! _tm_rp_choose "$bid" "$pl" "$c"; then
    printf 'map: none\neverything runs: no map for %s here whose commit is an ancestor of %s\nresult: everything runs\n%s\n' "$pl" "$base" "$ro"
    return 0
  fi
  mf="$c/felix-testmap/$pl/$_tm_cid/map.tsv"
  _tm_rp_mapread "$mf" "$_tm_cid" "$pl" > "$t/map.in"
  last="$(sed -n '$p' "$t/map.in")"; why="${last#*$tab}"
  case "$last" in
    "~OK"*) src="$why" ;;
    *) [ "${last#\~ERR}" != "$last" ] || why="the file could not be read"
       printf 'map: none\neverything runs: the map %s cannot be read: %s\nresult: everything runs\n%s\n' "$mf" "$why" "$ro"
       return 0 ;;
  esac
  sed '$d' "$t/map.in" > "$t/map.tag"
  now="$(date +%s)"
  printf 'map: %s %s dated %s, unit time from %s runs\n' "$_tm_cid" "$pl" "$(_tm_rp_day "$_tm_cct")" "$src"
  : > "$t/E"
  if [ $((now - _tm_cct)) -ge 1209600 ]; then
    printf "the map's commit %s is %d days old (the limit is 14)\n" "$_tm_cid" $(( (now - _tm_cct) / 86400 )) >> "$t/E"
  fi
  _tm_ps_units "$top/engine/harness/tests/run" "$top/engine/harness/tests/groups.tsv" > "$t/units.raw"
  x=""; y=""; { IFS="$tab" read -r x y < "$t/units.raw"; } 2>/dev/null
  [ "$x" != ERR ] || printf 'the units of this tree could not be read: %s\n' "$y" >> "$t/E"
  LC_ALL=C awk -F'\t' -v OFS='\t' '$1 != "ERR" { print "U", $1, $2 }' "$t/units.raw" > "$t/units.tag"
  if _tm_rp_changes "$_tm_cid" "$t/chg"; then
    LC_ALL=C awk -F'\t' '$3 == "out" { print $2 " is code outside the units" }' "$t/chg" >> "$t/E"
    _tm_rp_calls "$top" "$_tm_cid" "$t/chg" "$t/calls"
    LC_ALL=C awk -F'\t' '{ print $1 ":" $2 " adds a computed call" }' "$t/calls" >> "$t/E"
  else
    printf 'the change since %s could not be read\n' "$_tm_cid" >> "$t/E"; : > "$t/chg"
  fi
  _tm_rp_parse "$top" "$_tm_cid" "$t/chg" "$t/map.tag" "$t/p"
  _tm_rp_git ls-tree --name-only "$_tm_cid" engine/harness/tests/parts/ 2>/dev/null | LC_ALL=C awk -F/ -v OFS='\t' '{ print "P", $NF }' > "$t/parts"
  cat "$t/units.tag" "$t/map.tag" "$t/chg" "$t/parts" "$t/p.R" > "$t/in"
  _tm_rp_select "$t/in" > "$t/sel"
  LC_ALL=C awk -F'\t' '$1 == "N"' "$t/sel" > "$t/N"
  x=""; k=""; n=""; pct=""; any=""; { IFS="$tab" read -r x k n pct any < "$t/N"; } 2>/dev/null
  if [ "$x" != N ]; then k=0; n=0; pct="?"; any=0; echo 'the selection could not be worked out' >> "$t/E"; fi
  LC_ALL=C awk -F'\t' '$1 == "E" { print $2 }' "$t/sel" >> "$t/E"
  if [ "$any" = 1 ]; then
    if [ "$pct" = "?" ]; then printf "the selection's share of unit time is not known\n" >> "$t/E"
    elif [ "$pct" -ge 70 ]; then printf 'the selection is %s%% of unit time (the limit is 70%%)\n' "$pct" >> "$t/E"; fi
  fi
  LC_ALL=C awk '!S[$0]++ { print "everything runs: " $0 }' "$t/E"
  LC_ALL=C awk -F'\t' '$1 == "S" { print "selected " $2 ": " $3 }' "$t/sel"
  if [ "$pct" = "?" ]; then printf 'summary: %s of %s units selected, share of unit time not known\n' "$k" "$n"
  else printf 'summary: %s of %s units selected, %s%% of unit time\n' "$k" "$n" "$pct"; fi
  if [ -s "$t/E" ]; then echo 'result: everything runs'
  elif [ "$k" -gt 0 ]; then echo 'result: the selection runs'
  else echo 'result: nothing to run'; fi
  echo "$ro"
}
# [BASE] -> the report. Lines 1 to 8 of B22, or one line when there is no checkout or no suite.
_tm_report() {
  local base="${1:-origin/main}" top t rc
  top="$(GIT_OPTIONAL_LOCKS=0 git rev-parse --show-toplevel 2>/dev/null)" && [ -n "$top" ] || {
    printf 'testmap: %s is not in a git checkout, so there is nothing to select\n' "$PWD"; return 0; }
  [ -f "$top/engine/harness/tests/run" ] || {
    printf 'testmap: %s has no engine/harness/tests/run, so there is no suite to select from\n' "$top"; return 0; }
  t="$(mktemp -d "${TMPDIR:-/tmp}/felix-testmap.XXXXXX" 2>/dev/null)" && [ -d "$t" ] || {
    printf 'felix testmap: cannot make a scratch directory\n' >&2; return 1; }
  _tm_rtop="$top"
  _tm_rp_main "$top" "$base" "$t"; rc=$?
  rm -rf "$t"
  return "$rc"
}
