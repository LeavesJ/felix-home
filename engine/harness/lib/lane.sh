# The lane counter (slice 0 of the lane design, section 6; the Contracts it was built to are C1 to C9 of
# docs/2026-10-29-lane-slice-0-plan.md).
#
# WHAT IT READS. Two per-project tables, lanes.tsv and lane-next.tsv, as the Felix home has them committed: the
# files at HEAD of the git repository holding the project directory, never the working tree. And the first-parent
# history of refs/remotes/origin/main in the checkout it is asked about, as last fetched. It counts each lane's
# share of the engine landings there, offline: no fetch, no network, no model, no key.
#
# WHAT IT WRITES. Nothing. No ref, index, config or worktree entry of any repository, no file of the home or the
# memory root. Its scratch files sit in one directory made under ${TMPDIR:-/tmp} and removed on the way out. Every
# git read runs with --no-optional-locks and without lazy fetches. git diff, git status and git add are never run:
# they rewrite an index under a stat-dirty file even with GIT_OPTIONAL_LOCKS=0.
#
# felix_lane_rows PROJ ROOT [FULL]  C5's thirteen-column lines, one per data row of lanes.tsv, on stdout, and nothing
#                                   when it holds no row. Unless FULL is 1, columns 7, 10 and 11 read - and their
#                                   searches are not run. Prints nothing on stderr; returns 0.
# felix_lane_command PROJ ROOT TSV  felix lane: those lines (TSV 1) or C5's human lines (TSV 0).
# felix_lane_status_row PROJ ROOT   felix status's last row, the first lane's (C6).
# felix_start_lane PROJ ROOT        session start's lane paragraphs and screen token, in two globals (C7).
# felix_lane_pulse HOME             felix pulse's last lines, one per lane of the home's own project (C8).
#
# A read that did not finish never yields a count: the lane reads unknown with the reason. Bash 3.2; LC_ALL=C on
# every text tool; awk that BWK awk and gawk both run.

_LANE_LIB="${BASH_SOURCE[0]:-$0}"
case "$_LANE_LIB" in */*) _LANE_LIB="${_LANE_LIB%/*}" ;; *) _LANE_LIB=. ;; esac

# Every lane git read runs in a subshell of its own, for two reasons. A fork that fails ends bash 3.2's shell that was
# forking, with status 128 and nothing printed; here it ends that one read, which the caller sees as a status that is
# not 0 and reads as unknown, where felix itself would have ended (C3). And the repository is the one -C names, not the
# one the caller's GIT_DIR, GIT_WORK_TREE, GIT_OBJECT_DIRECTORY and their kin name (C2).
_lane_git() {
  ( unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_NAMESPACE GIT_PREFIX
    GIT_NO_LAZY_FETCH=1; export GIT_NO_LAZY_FETCH
    git --no-optional-locks --literal-pathspecs -c core.fsmonitor=false -c log.showSignature=false "$@" )
}
_lane_iso() { date -u -r "$1" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$1" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null; }
_lane_line() { printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$@"; }

# PROJ NAME OUT -> the committed regular file copied to OUT: 0. No such entry at HEAD: 1. An entry that is no regular
# file (a link, a submodule): 2. PROJ in no repository, HEAD naming no commit or a git read not finishing, while a
# file or link of that name stands in PROJ: 3 (1 when none does). Sets _LANE_REPO and _LANE_REL.
_lane_blob() {
  local pd repo rel ent mode r no=1
  if [ -e "$1/$2" ] || [ -L "$1/$2" ]; then no=3; fi
  pd="$(CDPATH='' cd -- "$1" 2>/dev/null && pwd -P)" || pd=""
  [ -n "$pd" ] || return "$no"
  repo="$(_lane_git -C "$pd" rev-parse --show-toplevel 2>/dev/null)" || repo=""
  case "$repo" in /*) ;; *) return "$no" ;; esac
  case "$pd" in "$repo") rel="$2" ;; "$repo"/*) rel="${pd#"$repo"/}/$2" ;; *) return "$no" ;; esac
  _LANE_REPO="$repo"; _LANE_REL="$rel"
  _lane_git -C "$repo" rev-parse --verify -q 'HEAD^{commit}' >/dev/null 2>&1 || return "$no"
  ent="$(_lane_git -C "$repo" ls-tree HEAD -- "$rel" 2>/dev/null)" || return "$no"
  [ -n "$ent" ] || return 1
  ent="${ent%%$'\n'*}"; mode="${ent%% *}"; r="${ent#* }"; r="${r#* }"
  case "$mode" in 100644|100755) ;; *) return 2 ;; esac
  [ -n "${_LANE_W:-}" ] || return 3
  _lane_git -C "$repo" cat-file blob "${r%%$'\t'*}" > "$3" 2>/dev/null || return 3
  return 0
}

# PROJ NAME OUT -> _lane_blob's status, with 2 also for a table the engine's table check refuses.
_lane_table() {
  local rc
  _lane_blob "$1" "$2" "$3"; rc=$?
  [ "$rc" -eq 0 ] || return "$rc"
  command -v felix_table_check >/dev/null 2>&1 || . "$_LANE_LIB/table.sh"
  felix_table_check "$_LANE_LIB/../templates/schemas.tsv" "$3" "$2" >/dev/null 2>&1 || return 2
  return 0
}

# ROOT -> 0 when ROOT is a partial clone and git is older than 2.44, which ignores GIT_NO_LAZY_FETCH and would fetch.
# Also 0 when git could not say whether ROOT is a partial clone: a read that did not finish is not "no".
_lane_partial_old() {
  local rc
  _lane_git -C "$1" config --get extensions.partialClone >/dev/null 2>&1; rc=$?
  [ "$rc" -le 1 ] || return 0
  if [ "$rc" -eq 1 ]; then
    _lane_git -C "$1" config --bool --get-regexp '^remote\..*\.promisor$' > "$_LANE_W/pc" 2>/dev/null; rc=$?
    [ "$rc" -le 1 ] || return 0
    LC_ALL=C awk '/ true$/ { f = 1 } END { exit !f }' "$_LANE_W/pc" || return 1
  fi
  _lane_git --version 2>/dev/null | LC_ALL=C awk '{ split($3, v, "."); exit !(v[1] > 2 || (v[1] == 2 && v[2] >= 44)) }' || return 0
  return 1
}

# ROOT -> 0 when ROOT is a shallow repository, 1 when it is not, 2 when git did not say.
_lane_shallow() {
  local s
  s="$(_lane_git -C "$1" rev-parse --is-shallow-repository 2>/dev/null)" || return 2
  case "$s" in true) return 0 ;; false) return 1 ;; *) return 2 ;; esac
}

# FILE "lane ..." SHA -> sha<TAB>lane for each lane that some message line of FILE marks. FILE is what git cat-file
# --batch printed for commits: "<sha> commit <size>", then the commit's <size> bytes, then a newline. The message is what
# follows the first empty line of those bytes (the headers have none). The bytes are counted, never delimited, so no byte
# in a message can end a record or credit its lines to another commit (C3, "Marked"). The line, once its trailing spaces,
# tabs and CRs are gone, is byte for byte "Felix-Lane: <lane>". With SHA, that commit is named instead of each record's
# own. 1 when a record is missing or does not add up: a read that did not finish yields no mark.
_lane_marks() {
  LC_ALL=C awk -v lanes="$2" -v force="$3" '
    BEGIN { nl = split(lanes, ls, " "); st = 0 }
    st == 0 {
      if (NF != 3 || $2 != "commit" || $3 !~ /^[0123456789]+$/) { bad = 1; exit }
      who = (force != "" ? force : $1); rem = $3 + 0; hd = 1; st = (rem > 0 ? 1 : 2); next }
    st == 1 {
      rem -= length($0) + 1
      if (hd) { if ($0 == "") hd = 0 }
      else { s = $0; sub(/[ \t\r]+$/, "", s)
        for (q = 1; q <= nl; q++) if (s == "Felix-Lane: " ls[q] && !((who SUBSEP ls[q]) in seen)) { seen[who SUBSEP ls[q]] = 1; print who "\t" ls[q] } }
      if (rem == 0) st = 2; else if (rem < 0) st = 0
      next }
    st == 2 { if ($0 != "") { bad = 1; exit }; st = 0; next }
    END { exit (bad || st != 0) }' "$1"
}

# ROOT SHA PARENTS FIRST-PARENT -> $_LANE_W/dt/SHA holds the commit's changed paths against its first parent, NUL
# separated, renames off, unquoted. A commit with no parent changed every path in its tree. 1 when git did not finish.
_lane_paths() {
  local f="$_LANE_W/dt/$2" rc
  [ -f "$f" ] && return 0
  if [ "$3" -eq 0 ]; then
    _lane_git -C "$1" -c core.quotePath=false diff-tree --root --no-commit-id -r -z --no-renames --name-only "$2" > "$f" 2>/dev/null < /dev/null
  else
    _lane_git -C "$1" -c core.quotePath=false diff-tree -r -z --no-renames --name-only "$4" "$2" > "$f" 2>/dev/null < /dev/null
  fi
  rc=$?
  [ "$rc" -eq 0 ] || { rm -f "$f"; return 1; }
}

# LANE -> the lane's next text, none, or unknown (lane-next.tsv refused, unreadable, or two rows for the lane).
_lane_next() {
  case "$_LANE_NRC" in
    0) LC_ALL=C awk -F'\t' -v lane="$1" '$1 == lane { n++; v = $2 } END { if (n == 0) print "none"; else if (n > 1) print "unknown"; else print v }' "$_LANE_W/nrows" ;;
    1) printf 'none\n' ;;
    *) printf 'unknown\n' ;;
  esac
}

# OID LANE OUT -> the lanes.tsv lines of the blob OID whose first cell is LANE, in OUT (none for the OID -). 1 when the
# blob cannot be read: the lines are read from a file git finished writing, never through a pipe whose status is awk's.
_lane_cells() {
  : > "$3"
  [ "$1" = - ] && return 0
  _lane_git -C "$_LANE_HREPO" cat-file blob "$1" > "$_LANE_W/cb" 2>/dev/null || return 1
  LC_ALL=C awk -F'\t' -v lane="$2" '$1 == lane' "$_LANE_W/cb" > "$3"
}

# Once per run: every first-parent commit of the home's HEAD whose lanes.tsv entry differs from its first parent's,
# in $_LANE_W/hcand as "commit blob parent parent-blob" (a blob is - where the file is absent). One git diff-tree reads
# the trees along the file's path and no blob, so an entry whose blob is gone is still an entry, and a tree that cannot be
# read ends the search with a status git reports: a missing object never reads as an absent file. _LANE_HOK 0 when
# the home is shallow, or a partial clone read by a git that would fetch (C3), or git did not finish.
_lane_hprep() {
  local W="$_LANE_W" r="$_LANE_HREPO"
  _LANE_HOK=0
  ! _lane_partial_old "$r" || return 0
  _lane_shallow "$r"; [ $? -eq 1 ] || return 0
  _lane_git -C "$r" rev-list --first-parent HEAD > "$W/hchain" 2>/dev/null || return 0
  LC_ALL=C awk 'NR > 1 { print prev " " $1 } { prev = $1 } END { if (NR > 0) print prev }' "$W/hchain" > "$W/hpairs"
  _lane_git -C "$r" -c core.quotePath=false diff-tree --stdin --root -r --no-renames --no-abbrev -- "$_LANE_HREL" < "$W/hpairs" > "$W/hraw" 2>/dev/null || return 0
  LC_ALL=C awk -v rel="$_LANE_HREL" '
    FILENAME == ARGV[1] { par[$1] = (NF > 1 ? $2 : "-"); next }
    /^:/ { if (split($0, f, "\t") != 2 || f[2] != rel) next
           split(f[1], g, " ")
           o = g[3]; w = g[4]
           if (o ~ /^0+$/ || g[1] == ":160000") o = "-"
           if (w ~ /^0+$/ || g[2] == "160000") w = "-"
           print cur, w, par[cur], o; next }
    { cur = $1 }' "$W/hpairs" "$W/hraw" > "$W/hcand" || return 0
  _LANE_HOK=1
}

# LANE -> _LANE_C the first commit, walking first parents from the home's HEAD, whose lanes.tsv holds other lines for
# LANE than its first parent's (a parent without the file holds none), or unknown; _LANE_CD its committer date.
_lane_changed() {
  local W="$_LANE_W" c co p po ct
  _LANE_C=unknown; _LANE_CD=-
  [ "$_LANE_HOK" = 1 ] || return 0
  while read -r c co p po <&3; do
    _lane_cells "$co" "$1" "$W/l1" || return 0
    _lane_cells "$po" "$1" "$W/l2" || return 0
    cmp -s "$W/l1" "$W/l2" && continue
    ct="$(_lane_git -C "$_LANE_HREPO" log -1 --no-show-signature --format=%ct "$c" -- 2>/dev/null)" || return 0
    case "$ct" in ''|*[!0123456789]*) return 0 ;; esac
    _LANE_C="$c"; _LANE_CD="$(_lane_iso "$ct")"
    return 0
  done 3< "$W/hcand"
}

# Marks, for the landings of $_LANE_W/CAND (sha ct parents first-parent): singles through one git cat-file --batch,
# merges one by one over the commits their range p1..sha holds. -> sha<TAB>lane lines on stdout; 1 when git did not finish.
_lane_markall() {   # ROOT CAND "lane ..." TAG
  local W="$_LANE_W" sha ct np p1
  LC_ALL=C awk '$3 <= 1 { print $1 }' "$W/$2" > "$W/$4-single"
  if [ -s "$W/$4-single" ]; then
    _lane_git -C "$1" cat-file --batch < "$W/$4-single" > "$W/$4-msg" 2>/dev/null || return 1
    _lane_marks "$W/$4-msg" "$3" "" || return 1
  fi
  while read -r sha ct np p1 <&3; do
    [ "$np" -ge 2 ] || continue
    _lane_git -C "$1" rev-list "$p1..$sha" -- > "$W/$4-mm" 2>/dev/null < /dev/null || return 1
    _lane_git -C "$1" cat-file --batch < "$W/$4-mm" > "$W/$4-mc" 2>/dev/null || return 1
    _lane_marks "$W/$4-mc" "$3" "$sha" || return 1
  done 3< "$W/$2"
  return 0
}

# The window: L and T of every valid row (Rs empty), by C3. Sets Ls, Ts; Fl 1 where a read did not finish.
_lane_window() {   # NOW ROOT
  local now="$1" root="$2" W="$_LANE_W" k names="" maxw=0 sha ct np p1 need c rc nm
  for ((k = 1; k <= nrows; k++)); do
    [ -z "${Rs[$k]}" ] || continue
    names="$names ${Nm[$k]}"; Ls[$k]=0; Ts[$k]=0
    [ "${Wi[$k]}" -le "$maxw" ] || maxw="${Wi[$k]}"
  done
  [ -n "$names" ] || return 0
  mkdir "$W/dt" 2>/dev/null; : > "$W/counted"; : > "$W/wmarks"
  if _lane_git -C "$root" log --first-parent --no-show-signature --format='%H %ct %P' refs/remotes/origin/main -- > "$W/chain" 2>/dev/null \
     && LC_ALL=C awk -v now="$now" -v lo="$((now - maxw * 86400))" '
          $2 !~ /^[0123456789]+$/ { bad = 1 }
          $2 + 0 <= now + 0 && $2 + 0 > lo + 0 { print $1, $2, NF - 2, (NF > 2 ? $3 : "-") }
          END { exit bad }' "$W/chain" > "$W/cand" \
     && _lane_markall "$root" cand "$names" w > "$W/wmarks"; then :; else
    for ((k = 1; k <= nrows; k++)); do [ -n "${Rs[$k]}" ] || Fl[$k]=1; done
    return 0
  fi
  while read -r sha ct np p1 <&3; do
    need=""
    for ((k = 1; k <= nrows; k++)); do
      [ -z "${Rs[$k]}" ] || continue
      [ "$ct" -gt "$((now - Wi[k] * 86400))" ] && need="$need $k"
    done
    [ -n "$need" ] || continue
    if ! _lane_paths "$root" "$sha" "$np" "$p1"; then for k in $need; do Fl[$k]=1; done; continue; fi
    for k in $need; do
      LC_ALL=C grep -z -E -e "${Cn[$k]}" "$W/dt/$sha" > /dev/null 2>&1; rc=$?
      if [ "$rc" -ge 2 ]; then Fl[$k]=1
      elif [ "$rc" -eq 0 ]; then printf '%s\t%s\n' "$sha" "${Nm[$k]}" >> "$W/counted"; fi
    done
  done 3< "$W/cand"
  LC_ALL=C awk 'FILENAME == ARGV[1] { m[$1 "\t" $2] = 1; next }
                { t[$2]++; if (($1 "\t" $2) in m) l[$2]++ } END { for (x in t) print x "\t" (l[x] + 0) "\t" t[x] }' "$W/wmarks" "$W/counted" > "$W/lt"
  while IFS=$'\t' read -r nm c rc <&3; do
    for ((k = 1; k <= nrows; k++)); do [ "${Nm[$k]}" = "$nm" ] && [ -z "${Rs[$k]}" ] && { Ls[$k]=$c; Ts[$k]=$rc; }; done
  done 3< "$W/lt"
}

# The last lane landing of each valid row whose count stands: its date, none, or unknown. Sets La. A read that does
# not finish here changes nothing but this column.
_lane_search() {   # NOW ROOT
  local now="$1" root="$2" W="$_LANE_W" k names="" ct sha np p1 rc
  for ((k = 1; k <= nrows; k++)); do
    [ -z "${Rs[$k]}" ] && [ "${Fl[$k]}" = 0 ] || continue
    names="$names ${Nm[$k]}"; La[$k]=none
  done
  [ -n "$names" ] || return 0
  if ! { LC_ALL=C awk -v now="$now" '$2 + 0 <= now + 0 { print $1, $2, NF - 2, (NF > 2 ? $3 : "-") }' "$W/chain" > "$W/scand" \
         && _lane_markall "$root" scand "$names" s > "$W/smarks"; }; then
    for ((k = 1; k <= nrows; k++)); do [ -z "${La[$k]:-}" ] || La[$k]=unknown; done
    return 0
  fi
  for ((k = 1; k <= nrows; k++)); do
    [ -n "${La[$k]:-}" ] || continue
    LC_ALL=C awk -v lane="${Nm[$k]}" 'FILENAME == ARGV[1] { if ($2 == lane) h[$1] = 1; next } ($1 in h) { print $2, $1, $3, $4 }' "$W/smarks" "$W/scand" \
      | LC_ALL=C sort -k1,1nr > "$W/lc" || { La[$k]=unknown; continue; }
    while read -r ct sha np p1 <&3; do
      if ! _lane_paths "$root" "$sha" "$np" "$p1"; then La[$k]=unknown; break; fi
      LC_ALL=C grep -z -E -e "${Cn[$k]}" "$W/dt/$sha" > /dev/null 2>&1; rc=$?
      if [ "$rc" -ge 2 ]; then La[$k]=unknown; break; fi
      if [ "$rc" -eq 0 ]; then La[$k]="$(_lane_iso "$ct")"; break; fi
    done 3< "$W/lc"
  done
}

_lane_rows() {   # PROJ ROOT FULL
  local proj="$1" root="$2" full="$3" W="$_LANE_W" rc ct refd=- now glob="" r2 shl k nrows=0 lv cv dup nm cnt shr win n d
  local state lane chg chgd nx last
  local -a Nm Cn Sh Wi Rs Ls Ts Fl La Lv
  _lane_table "$proj" lanes.tsv "$W/lanes"; rc=$?
  [ "$rc" -ne 1 ] || return 0
  _LANE_HREPO="$_LANE_REPO"; _LANE_HREL="$_LANE_REL"
  # The ref by its full name only: git reads the short name refs/remotes/origin/main as a tag or a branch spelled that
  # way when the remote-tracking ref is missing, and show-ref --verify does not (C2). With the ref there, git reads
  # that exact name first, so the walks below, which spell it the same way, read it.
  ct=""
  if _lane_git -C "$root" show-ref --verify -q refs/remotes/origin/main; then
    ct="$(_lane_git -C "$root" log -1 --no-show-signature --format=%ct 'refs/remotes/origin/main^{commit}' -- 2>/dev/null)" || ct=""
  fi
  case "$ct" in ''|*[!0123456789]*) ct="" ;; *) refd="$(_lane_iso "$ct")"; refd="${refd:--}" ;; esac
  if [ "$rc" -eq 3 ]; then _lane_line - unknown - - - - - - - - - "$refd" "$proj/lanes.tsv cannot be read as committed in the Felix home"; return 0; fi
  if [ "$rc" -eq 2 ]; then _lane_line - unknown - - - - - - - - - "$refd" "$proj/lanes.tsv cannot be read as lanes.tsv"; return 0; fi
  felix_table_rows "$W/lanes" > "$W/rows"
  LC_ALL=C awk -F'\t' '
    { k++; l[k] = $1; s[k] = $3; w[k] = $4; seen[$1]++; row[k] = $0 }
    END { for (i = 1; i <= k; i++) {
            n = split(s[i], p, "/")
            c = (n == 2 && p[1] ~ /^[123456789][0123456789]*$/ && p[2] ~ /^[123456789][0123456789]*$/ && length(p[1]) <= 4 && length(p[2]) <= 4 && p[1] + 0 <= p[2] + 0)
            c = (c && w[i] ~ /^[123456789][0123456789]*$/ && length(w[i]) <= 4)
            print i "\t" (l[i] ~ /^[A-Za-z0-9][A-Za-z0-9._-]*$/ ? 1 : 0) "\t" (c ? 1 : 0) "\t" (seen[l[i]] > 1 ? 1 : 0) "\t" row[i] } }' "$W/rows" > "$W/meta"
  _lane_table "$proj" lane-next.tsv "$W/next"; _LANE_NRC=$?
  [ "$_LANE_NRC" -ne 0 ] || felix_table_rows "$W/next" > "$W/nrows"
  while IFS=$'\t' read -r k lv cv dup nm cnt shr win <&3; do
    nrows="$k"; Nm[$k]="$nm"; Cn[$k]="$cnt"; Sh[$k]="$shr"; Wi[$k]="$win"; Lv[$k]="$lv"; Rs[$k]=""; Fl[$k]=0; Ls[$k]=-; Ts[$k]=-; La[$k]=""
    if [ "$lv" = 0 ] || [ "$cv" = 0 ]; then Rs[$k]="row $k of lanes.tsv is not a lane name, an ERE, a share n/d and a window in days"
    elif [ "$dup" = 1 ]; then Rs[$k]="lane $nm is named on more than one row of lanes.tsv"
    else
      LC_ALL=C grep -E -e "$cnt" < /dev/null > /dev/null 2>&1
      [ $? -ne 2 ] || Rs[$k]="the counts pattern of lane $nm is not an ERE grep accepts"
    fi
  done 3< "$W/meta"
  [ "$nrows" -gt 0 ] || return 0
  now="${FELIX_LANE_NOW:-}"
  if [ -z "$now" ]; then now="$(date -u +%s)"
  else case "$now" in 0) ;; 0*|*[!0123456789]*|?????????????*) glob="FELIX_LANE_NOW is not a whole number of seconds" ;; esac; fi
  r2="git could not read the landings on refs/remotes/origin/main in $root"
  if [ -n "$glob" ]; then :
  elif [ -z "$ct" ]; then glob="refs/remotes/origin/main cannot be read in $root"
  else
    _lane_shallow "$root"; shl=$?
    if [ "$shl" -eq 0 ]; then glob="$root is a shallow clone, so its landings cannot all be read"
    elif [ "$shl" -ne 1 ] || _lane_partial_old "$root"; then glob="$r2"
    else
      _lane_window "$now" "$root"
      [ "$full" != 1 ] || _lane_search "$now" "$root"
    fi
  fi
  [ "$full" != 1 ] || _lane_hprep
  for ((k = 1; k <= nrows; k++)); do
    nm="${Nm[$k]}"; lane=-; chg=-; chgd=-; nx=-; last=-
    [ "${Lv[$k]}" = 0 ] || lane="$nm"
    [ "$full" != 1 ] || [ "$lane" = - ] || { _lane_changed "$nm"; chg="$_LANE_C"; chgd="$_LANE_CD"; }
    if [ -n "${Rs[$k]}" ]; then
      _lane_line "$lane" unknown - - - - - - - "$chg" "$chgd" "$refd" "${Rs[$k]}"; continue
    fi
    nx="$(_lane_next "$nm")"
    if [ -n "$glob" ] || [ "${Fl[$k]}" = 1 ]; then
      _lane_line "$lane" unknown - - "${Wi[$k]}" "${Sh[$k]}" - "Felix-Lane: $nm" "$nx" "$chg" "$chgd" "$refd" "${glob:-$r2}"; continue
    fi
    n="${Sh[$k]%/*}"; d="${Sh[$k]#*/}"
    if [ "${Ts[$k]}" -eq 0 ]; then state=idle
    elif [ "${Ls[$k]}" -eq 0 ]; then state=zero
    elif [ "$((Ls[k] * d))" -ge "$((n * Ts[k]))" ]; then state=ok
    else state=short; fi
    [ "$full" != 1 ] || last="${La[$k]:-none}"
    _lane_line "$lane" "$state" "${Ls[$k]}" "${Ts[$k]}" "${Wi[$k]}" "${Sh[$k]}" "$last" "Felix-Lane: $nm" "$nx" "$chg" "$chgd" "$refd" -
  done
}

felix_lane_rows() {   # PROJ ROOT [FULL]
  local LC_ALL=C _LANE_W="" _LANE_REPO="" _LANE_REL="" _LANE_HREPO="" _LANE_HREL="" _LANE_NRC=3 _LANE_HOK=0 _LANE_C=unknown _LANE_CD=-
  _LANE_W="$(mktemp -d "${TMPDIR:-/tmp}/felix-lane.XXXXXX" 2>/dev/null)" || _LANE_W=""
  _lane_rows "${1:-}" "${2:-}" "${3:-0}" 2>/dev/null
  case "$_LANE_W" in "${TMPDIR:-/tmp}"/felix-lane.??????) rm -rf "$_LANE_W" ;; esac
  return 0
}

# felix status's last row, the first lane's (C6). One row through _felix_status_row; returns 0. An empty PROJ is the
# not-governed row; no line at all (no committed row) the none row; an unknown line its reason, never a calm value.
felix_lane_status_row() {   # PROJ ROOT
  local rows c1 c2 c3 c4 c5 c6 c7 c8 c9 c10 c11 c12 c13
  if [ -z "${1:-}" ]; then _felix_status_row lane none - "this directory is not a governed checkout"; return 0; fi
  rows="$(felix_lane_rows "$1" "${2:-}" 0)"
  if [ -z "$rows" ]; then _felix_status_row lane none - "$1/lanes.tsv has no committed row, so no lane is counted"; return 0; fi
  rows="${rows%%$'\n'*}"
  IFS=$'\t' read -r c1 c2 c3 c4 c5 c6 c7 c8 c9 c10 c11 c12 c13 <<< "$rows"
  if [ "$c2" = unknown ]; then _felix_status_row lane unknown - "$c13"
  else _felix_status_row lane value "$c2" "$c3 of $c4 engine landings in $c5 days, target $c6"; fi
  return 0
}

# Session start's lane text (C7). hooks/session-start has no room to grow, so its lane lines are explained here:
# - it sources this file only when the file is there, and calls felix_start_lane only when it is defined, so an
#   engine without lib/lane.sh starts as it always did, with no lane text and valid JSON;
# - it sets lane_line and _felix_lane_tok empty first, then calls this with both streams sent to /dev/null, as the
#   lifecycle record and the mistakes-log heal are: a stray byte would break its JSON, so the results travel in the
#   two globals, as the waits' do (lib/waiting.sh);
# - when either is set, it holds them to the project's own checkout: it hands "lane item" and its _own to
#   felix_own_gate, as adoption and tidying are handed, and empties both unless the checkout is own, so the withheld
#   line names lane item instead (design §11 item 44). The paragraph tells an untasked session to work, and a .felix
#   marker is a file any repository can commit, so a checkout that only names the project must not steer one;
# - lane_line follows the "what waits" paragraphs in the context and comes before the capability-drift ones;
# - _felix_lane_tok follows the waits' tokens, last on the screen line (systemMessage).
# A Claude Code resume leaves the hook before any of this, and a directory no project governs never reaches it.
#
# Sets lane_line: for each row of felix_lane_rows whose state is short, zero or idle, in file order, a newline and
#   Lane <lane> is <state>: <L> of <T> engine landings in <W> days, target <n>/<d>.
#   If the founder has not given this session a task, take the first open lane item: <next>. End the body of a
#   commit on its branch that is not a merge with the line `Felix-Lane: <lane>`. <closing>
# as two lines (the second unbroken), where <closing> is "Trust work takes the other half." when 2n = d and "The rest
# goes to trust work." otherwise, and <next> reads "(lane-next.tsv names none)" for none and "(lane-next.tsv cannot be
# read)" for unknown. Sets _felix_lane_tok to " · lane: 0 in <W> days" when the first row is zero or idle, else empty.
# ok and unknown say nothing, nor does a project with no committed row. The next text is a cell anyone may commit, and
# the hook's JSON escape handles only backslash, quote, LF, CR and tab, so every control byte but tab and LF is
# replaced by ?, as _fw_clean does; a cell holds neither of those two. Returns 0.
felix_start_lane() {   # PROJ ROOT
  local rows lane state l t w shr nx x n d cl k=0
  lane_line=""; _felix_lane_tok=""
  [ -n "${1:-}" ] || return 0
  rows="$(felix_lane_rows "$1" "${2:-}" 0 | LC_ALL=C tr '\001-\010\013-\037\177' '?')" || rows=""
  while IFS=$'\t' read -r lane state l t w shr x x nx x; do
    k=$((k + 1))
    case "$state" in short|zero|idle) ;; *) continue ;; esac
    n="${shr%%/*}"; d="${shr#*/}"
    case "$l:$t:$w:$n:$d" in *::*|:*|*:|*[!0123456789:]*) continue ;; esac
    case "$nx" in none) nx="(lane-next.tsv names none)" ;; unknown) nx="(lane-next.tsv cannot be read)" ;; esac
    cl="The rest goes to trust work."
    [ "$((10#$n * 2))" -ne "$((10#$d))" ] || cl="Trust work takes the other half."
    lane_line="${lane_line}
Lane ${lane} is ${state}: ${l} of ${t} engine landings in ${w} days, target ${shr}.
If the founder has not given this session a task, take the first open lane item: ${nx}. End the body of a commit on its branch that is not a merge with the line \`Felix-Lane: ${lane}\`. ${cl}"
    [ "$k" -ne 1 ] || case "$state" in zero|idle) _felix_lane_tok=" · lane: 0 in ${w} days" ;; esac
  done <<< "$rows"
  return 0
}

# felix pulse's last lines (C8): lane<TAB><lane><TAB><state><TAB><L><TAB><T> for each data row of the Felix home's own
# project, columns 1 to 4 of felix_lane_rows (L and T read - when the state is unknown). Only the project the home
# checkout is bound to is counted: no project records where its checkout is. The git-dir check comes first because
# felix_repo_root prints a directory outside git as its own root and felix_resolve_project would then bind a .felix
# there, so a plain home holding a lanes.tsv would get an unknown line against C2. Prints nothing otherwise; returns 0.
felix_lane_pulse() {   # HOME
  local home="${1:-}" root proj
  [ -n "$home" ] || return 0
  _lane_git -C "$home" rev-parse --git-dir >/dev/null 2>&1 || return 0
  root="$(felix_repo_root "$home" 2>/dev/null)" || root=""
  [ -n "$root" ] || return 0
  proj="$(felix_resolve_project "$root" "$home" 2>/dev/null)" || proj=""
  [ -n "$proj" ] || return 0
  felix_lane_rows "$proj" "$root" 0 | LC_ALL=C awk -F'\t' '{ print "lane\t" $1 "\t" $2 "\t" $3 "\t" $4 }'
  return 0
}

# felix lane: the lines of felix_lane_rows, as TSV or in words (C5).
felix_lane_command() {   # PROJ ROOT TSV
  if [ "${3:-0}" = 1 ]; then felix_lane_rows "$1" "$2" 1; return 0; fi
  felix_lane_rows "$1" "$2" 1 | LC_ALL=C awk -F'\t' '
    { ch = ""
      if ($10 == "unknown") ch = "its lanes.tsv row\047s last change cannot be read"
      else if ($10 != "-") ch = "its lanes.tsv row last changed by " substr($10, 1, 12) " at " $11
      if ($2 == "unknown") s = $1 ": unknown, " $13
      else s = $1 ": " $2 ", " $3 " of " $4 " engine landings in " $5 " days, target " $6 "; last lane landing " $7 "; mark " $8 "; next: " $9
      if (ch != "") s = s "; " ch
      print s "; refs/remotes/origin/main at " $12 }'
  return 0
}
