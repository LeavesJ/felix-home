# tests/select.sh: the unit facts and the tracer's setup (audit b30, contract B1 to B9), the
# part of the test selector that the -j runner uses. Part 0007 sources it from _par_run when it
# is beside the suite (no copy has it, so a copy keeps no facts and cannot be traced), and calls
# _tm_begin before any unit starts, _tm_cpu in each unit's wrapper and _tm_end once the last unit
# is judged. The maps and the report are in the select-*.sh beside it, which `felix testmap`
# loads and the runner does not. It has no #! line and is not executable, and it defines
# functions and nothing else (part 0006's _lib_runs_nothing). Every function begins _tm_.
#
# Report only: nothing here changes a verdict, a receipt, the gate or what a run prints. A run
# with FELIX_TEST_TRACE_DIR set refuses (exit 2, one line) when it cannot be traced; a run that
# cannot keep its facts says so in one line on stderr and goes on as it would have.

_tm_plat() { uname -s 2>/dev/null | LC_ALL=C tr ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz; }
_tm_run_die() { printf 'tests/run: FELIX_TEST_TRACE_DIR %s\n' "$1" >&2; exit 2; }
# DIR -> 0 and the physical path in _tm_ph, or 1.
_tm_run_phys() { _tm_ph="$(cd -P "$1" 2>/dev/null && pwd -P)" && [ -n "$_tm_ph" ]; }
# TOP ARGS...: git in the checkout, writing no index.
_tm_run_git() { local t="$1"; shift; ( cd "$t" 2>/dev/null && GIT_OPTIONAL_LOCKS=0 git "$@" ); }
# TOP -> clean, dirty or unknown (B9): git status --porcelain, untracked files listed.
_tm_run_state() {
  local o
  if o="$(_tm_run_git "$1" status --porcelain 2>/dev/null)"; then [ -n "$o" ] && echo dirty || echo clean; else echo unknown; fi
}
# TOP -> HEAD's full id, or -.
_tm_run_head() {
  local o
  o="$(_tm_run_git "$1" rev-parse --verify --quiet 'HEAD^{commit}' 2>/dev/null)" && [ -n "$o" ] || o=-
  printf '%s\n' "$o"
}
# D: B8's refusals, each before anything is written; then the unit directories, the top and HEAD.
_tm_run_trace() {
  local d="$1" top f p u pd n=0 dirs tab=$'\t'
  dirs=()
  case "$d" in /*) ;; *) _tm_run_die "[$d] is not an absolute path" ;; esac
  [ ! -L "$d" ] || _tm_run_die "[$d] is a symbolic link"
  [ -d "$d" ] || _tm_run_die "[$d] is not an existing directory"
  { [ -w "$d" ] && [ -x "$d" ]; } || _tm_run_die "[$d] cannot be written"
  for f in "$d"/* "$d"/.[!.]* "$d"/..?*; do
    if [ -e "$f" ] || [ -L "$f" ]; then _tm_run_die "[$d] is not empty: it holds [${f##*/}]"; fi
  done
  _tm_run_phys "$REAL_HARNESS/../.." && top="$_tm_ph" || _tm_run_die "[$d]: the checkout's top cannot be read"
  p="$(_tm_run_git "$top" rev-parse --show-toplevel 2>/dev/null)" && _tm_run_phys "$p" && top="$_tm_ph"
  _tm_run_phys "$d" || _tm_run_die "[$d] cannot be resolved"
  pd="$_tm_ph"
  case "$pd/" in "$top"/*) _tm_run_die "[$d] is the checkout's top or lies below it [$top]" ;; esac
  [ -z "${BASH_ENV-}" ] || _tm_run_die "[$d]: BASH_ENV is set, and the tracer is loaded through it"
  [ -f "$HERE/trace.sh" ] || _tm_run_die "[$d]: this suite has no tests/trace.sh"
  while IFS="$tab" read -r u f; do [ -z "$u" ] || dirs[n++]="$d/$u"; done <<< "$_sj_units"
  mkdir -p -- ${dirs[@]+"${dirs[@]}"} 2>/dev/null || _tm_run_die "[$d]: the unit directories cannot be made"
  _tm_top="$top"; _tm_h0="$(_tm_run_head "$top")${tab}$(_tm_run_state "$top")"
}
# Called by _par_run after _par_order, before any unit: decides whether this run is traced
# (B8), keeps facts (B2) or neither. Sets _tm_on (the wrappers and _tm_end act only then), _tm_be
# (BASH_ENV for the units), _tm_dir (the trace directory) and _tm_wk and _tm_v (per unit, set by
# _par_fin and _par_show).
_tm_begin() {
  _tm_on=""; _tm_be=""; _tm_dir=""; _tm_wk=(); _tm_v=()
  if [ -n "${FELIX_TEST_TRACE_DIR-}" ] && [ -z "${FELIX_TEST_UNIT-}" ] && [ "${FELIX_TEST_RECORD:-0}" != 1 ] && [ "${FELIX_TEST_NO_MANIFEST:-0}" != 1 ]; then
    _tm_run_trace "$FELIX_TEST_TRACE_DIR"
    _tm_on=1; _tm_dir="$FELIX_TEST_TRACE_DIR"; _tm_be="$HERE/trace.sh"
    _rcp_on=0; _pj_df=""   # B9: a traced run leaves no receipt and no durations
  elif [ "${_rcp_on:-0}" = 1 ] && [ -n "${_pj_df:-}" ] && [ "${FELIX_TEST_NO_MANIFEST:-0}" != 1 ]; then
    _tm_on=1
  fi
  return 0
}
# XmY.ZZZs -> _tm_ms, in milliseconds; fails on anything else.
_tm_run_ms() {
  local m r s f
  case "$1" in [0123456789]*m[0123456789]*.[0123456789][0123456789][0123456789]s) ;; *) return 1 ;; esac
  case "$1" in *[!0123456789ms.]*) return 1 ;; esac
  m="${1%%m*}"; r="${1#*m}"; r="${r%s}"; s="${r%.*}"; f="${r#*.}"
  _tm_ms=$(( (10#$m * 60 + 10#$s) * 1000 + 10#$f ))
}
# I, in the unit's wrapper once its holder has ended: the user plus system CPU of every process
# the wrapper waited for, which is the holder and the unit below it, to cpu.I as two decimals.
# The holder's own few milliseconds are in it. Nothing is written when `times` cannot be read.
_tm_cpu() {
  local f="$_pj_dir/cpu.$1" x u s a
  times > "$f.t" 2>/dev/null || return 0
  { read -r x; read -r u s; } < "$f.t" 2>/dev/null
  rm -f "$f.t" 2>/dev/null
  _tm_run_ms "${u:-}" || return 0
  a="$_tm_ms"
  _tm_run_ms "${s:-}" || return 0
  a=$(( (a + _tm_ms + 5) / 10 ))
  printf '%d.%02d\n' $((a / 100)) $((a % 100)) > "$f" 2>/dev/null
  return 0
}
# DEST BODY: the file whole, a temporary file beside it and one mv. Says why on failure.
_tm_run_put() {
  local dest="$1" t="$1.tmp.$$"
  if printf '%s' "$2" > "$t" 2>/dev/null && mv -f "$t" "$dest" 2>/dev/null; then return 0; fi
  rm -f "$t" 2>/dev/null
  _tm_why="cannot write $dest"
  return 1
}
# BODY: C/felix-testmap/runs/T.tsv (B2, B5). Sets _tm_why when it cannot.
_tm_run_keep() {
  local t="${_rcp_t0:-}" r="${_rcp_root:-}" c d
  [ -n "$t" ] || { _tm_why="the tree has no id"; return 1; }
  case "$t" in *[!0123456789abcdef]*) _tm_why="the tree id [$t] is not a hex id"; return 1 ;; esac
  [ -n "$r" ] && c="$(_tm_run_git "$r" rev-parse --git-common-dir 2>/dev/null)" && [ -n "$c" ] || { _tm_why="the common git directory cannot be read"; return 1; }
  case "$c" in /*) ;; *) c="${r%/}/$c" ;; esac
  [ -d "$c" ] || { _tm_why="the common git directory [$c] is not a directory"; return 1; }
  for d in "$c/felix-testmap" "$c/felix-testmap/runs"; do
    if [ -L "$d" ]; then _tm_why="$d is a symbolic link"; return 1; fi
    if [ -e "$d" ] && [ ! -d "$d" ]; then _tm_why="$d is not a directory"; return 1; fi
    [ -d "$d" ] || mkdir "$d" 2>/dev/null || { _tm_why="$d cannot be made"; return 1; }
  done
  _tm_run_put "$c/felix-testmap/runs/$t.tsv" "$1"
}
# Called by _par_run once the last unit is judged, before it does anything else (B2, B9).
_tm_end() {
  local i=0 tab=$'\t' b w c v t="${_rcp_t0:-}" cf
  b="run${tab}v1${tab}${t:--}${tab}${_suite_jobs}${tab}${BASH_VERSION}"$'\n'
  [ -z "$_tm_dir" ] || b="${b}top${tab}${_tm_top}"$'\n'"head${tab}${_tm_h0}"$'\n'
  while [ "$i" -lt "$_pj_n" ]; do
    v=fail; [ "${_tm_v[$i]:-1}" != 0 ] || v=pass
    w=unknown; [ "${_tm_wk[$i]:-}" != 1 ] || w="${_pj_t[$i]}"
    c=unknown; cf=""; { read -r cf < "$_pj_dir/cpu.$i"; } 2>/dev/null
    case "$cf" in ""|*[!0123456789.]*) ;; *.[0123456789][0123456789]) case "${cf%.*}" in ""|*[!0123456789]*) ;; *) c="$cf" ;; esac ;; esac
    b="${b}unit${tab}${_pj_nm[$i]}${tab}${v}${tab}${w}${tab}${c}"$'\n'
    i=$((i + 1))
  done
  if [ -n "$_tm_dir" ]; then
    b="${b}end${tab}$(_tm_run_head "$_tm_top")${tab}$(_tm_run_state "$_tm_top")"$'\n'
    _tm_run_put "$_tm_dir/units.tsv" "$b" || printf 'tests/run: the traced run could not keep its facts: %s\n' "$_tm_why" >&2
  else
    _tm_run_keep "$b" || printf 'tests/run: the unit facts were not kept: %s\n' "$_tm_why" >&2
  fi
  return 0
}
