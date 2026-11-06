# An owed engine deploy gets its window (docs/2026-11-06-deploy-window-contract.md, DW1 to DW7).
#
# The lander deploys the engine main declares only when no gate or suite runs, and replaces
# nothing beneath a run that has started. On 2026-11-06 sessions kept records and gates going
# back to back, so a deploy owed from 11:29Z found no such moment by 14:40Z, every gate ended
# red on `installed`, and the tick merged nothing. The only way to a window that signals no one
# is that nothing new starts while a deploy is owed: what runs drains, and the next tick deploys.
#
# Three parts, one file, because they share one format:
#   the hold      <memory root>/<project>/land/deploy-hold, one line: LEASE SINCE VERSION (tabs).
#                 The tick writes it (_dh_assert, _dh_clear); a reader looks at */land/deploy-hold.
#   the doors     tests/run (_dh_enter_run) and `felix gate` (_dh_wait_gate) wait while the
#                 machine is held, say why on stderr, and go ahead at a bound.
#   the filter    the tick does not count a waiter, or a shell around one, as running (_dh_unwaiting).
#
# A waiter must not look like work. The tick finds work by `pgrep -f` on a command line that holds
# engine/harness/tests/run or gate.sh, and a bash waiting in tests/run has exactly that. So the run
# door replaces itself with a perl that sleeps, with the script's path in its environment and not in
# its argv, and starts the script again; the gate door sleeps in a child. Either way the table holds
# a process with the token below, and the tick drops it and every process above it.
#
# Every failure here reads as "nothing is held" (DW7): a command is never refused, and never waits
# past its bound, because of a damaged file, a clock or a table that would not read.
#
# Sourced by felix and by tests/run, which is `set -u` and runs under bash 3.2, so: no [[ =~ ]],
# no ${a[@]} of an empty array, no arithmetic on a number with a leading zero.

_DH_TOKEN="felix-deploy-hold-wait"   # in the command line of whatever sleeps at the hold (DW3, DW6)
_DH_LEASE_TTL=1200                   # a lease older than this is not in force (DW1.3); a tick runs every 300 s

_dh_dec() { case "${1:-}" in ""|*[!0123456789]*) return 1 ;; esac; [ "${#1}" -le 12 ]; }   # plain decimal, no overflow

_dh_now() {   # prints the epoch second; fails when the clock will not say
  local n; n="$(date +%s 2>/dev/null)" || return 1
  _dh_dec "$n" || return 1
  printf '%s' "$((10#$n))"
}

_dh_limit() {   # DW1.4, DW5: FELIX_DEPLOY_HOLD_LIMIT when a plain decimal of at least 1, else 7200
  local v="${FELIX_DEPLOY_HOLD_LIMIT:-}"
  if _dh_dec "$v" && [ "$((10#$v))" -ge 1 ]; then printf '%s' "$((10#$v))"; else printf '7200'; fi
}
_dh_say_every() {   # DW5: FELIX_DEPLOY_HOLD_SAY, default 300
  local v="${FELIX_DEPLOY_HOLD_SAY:-}"
  if _dh_dec "$v" && [ "$((10#$v))" -ge 1 ]; then printf '%s' "$((10#$v))"; else printf '300'; fi
}
_dh_poll() {   # DW5: a positive number, fractions allowed, default 5
  local v="${FELIX_DEPLOY_HOLD_POLL:-}"
  case "$v" in ""|*[!0123456789.]*|*.*.*|.) printf '5'; return 0 ;; esac
  case "$v" in *[123456789]*) printf '%s' "$v" ;; *) printf '5' ;; esac
}

# DW1. Reads one hold file into _DH_LEASE, _DH_SINCE and _DH_VER; fails when it is not a regular
# file holding exactly three tab-separated fields, the first two plain decimals. Not yet "in force".
_dh_read() {   # FILE
  local f="$1" line="" rest rest2 a b c
  _DH_LEASE=""; _DH_SINCE=""; _DH_VER=""
  [ -f "$f" ] && [ ! -L "$f" ] || return 1
  { IFS= read -r line || [ -n "$line" ]; } 2>/dev/null < "$f" || return 1
  a="${line%%$'\t'*}"; rest="${line#*$'\t'}"; [ "$rest" != "$line" ] || return 1
  b="${rest%%$'\t'*}"; rest2="${rest#*$'\t'}"; [ "$rest2" != "$rest" ] || return 1
  c="$rest2"
  case "$c" in ""|*$'\t'*) return 1 ;; esac
  _dh_dec "$a" && _dh_dec "$b" || return 1
  _DH_LEASE="$((10#$a))"; _DH_SINCE="$((10#$b))"; _DH_VER="$c"
}

# DW1. Whether a file is in force at NOW, for LIMIT.
_dh_inforce() {   # FILE NOW LIMIT
  _dh_read "$1" || return 1
  [ "$_DH_LEASE" -le "$(( $2 + 60 ))" ] || return 1
  [ "$(( $2 - _DH_LEASE ))" -lt "$_DH_LEASE_TTL" ] || return 1
  [ "$(( $2 - _DH_SINCE ))" -lt "$3" ]
}

# DW1. Is the machine held? Looks at every <memory root>/*/land/deploy-hold and names no project.
# Sets _DH_STATE to held, lapsed (a file is there and not in force) or gone (none is there), and,
# when held, _DH_HVER and _DH_HSINCE from the hold that began first. Returns 0 when held.
_dh_scan() {
  local root="${FELIX_MEMORY:-${HOME:-}/.felix/memory}" now lim f nf=0 nglob=0 hs="" hv=""
  _DH_STATE=gone; _DH_HVER=""; _DH_HSINCE=""
  case "$-" in *f*) nglob=1; set +f ;; esac
  now="$(_dh_now)" || { [ "$nglob" -eq 0 ] || set -f; return 1; }
  lim="$(_dh_limit)"
  for f in "$root"/*/land/deploy-hold; do
    [ -e "$f" ] || [ -L "$f" ] || continue
    nf=1
    if _dh_inforce "$f" "$now" "$lim" && { [ -z "$hs" ] || [ "$_DH_SINCE" -lt "$hs" ]; }; then hs="$_DH_SINCE"; hv="$_DH_VER"; fi
  done
  [ "$nglob" -eq 0 ] || set -f
  if [ -n "$hs" ]; then _DH_STATE=held; _DH_HSINCE="$hs"; _DH_HVER="$hv"; return 0; fi
  [ "$nf" -eq 0 ] || _DH_STATE=lapsed
  return 1
}

_dh_say() { printf '%s: %s\n' "$1" "$2" >&2; }   # WHO MESSAGE

_dh_since_iso() {   # EPOCH -> the UTC time, or the epoch when date cannot say
  local t; t="$(date -u -r "$1" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$1" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)" || t=""
  printf '%s' "${t:-epoch $1}"
}

_dh_first_line() {   # WHO -> the line a waiter says first (DW5)
  local v=""
  [ -z "$_DH_HVER" ] || [ "$_DH_HVER" = - ] || v="$_DH_HVER, "
  printf '%s: waiting for the engine deploy (%sheld since %s): a gate or suite was running when it became owed, and nothing new starts until the lander has deployed it; at most %s s. FELIX_DEPLOY_HOLD=off goes ahead now\n' \
    "$1" "$v" "$(_dh_since_iso "$_DH_HSINCE")" "$(_dh_limit)" >&2
}

_dh_admit() { FELIX_HOLD_PASSED=1; export FELIX_HOLD_PASSED; unset FELIX_HOLD_T0 FELIX_HOLD_SAID; }   # DW4

_dh_off() { [ -n "${FELIX_HOLD_PASSED:-}" ] || [ "${FELIX_DEPLOY_HOLD:-}" = off ]; }

_dh_nap() {   # SECONDS: sleeps in a process that carries the token, so the tick can tell a waiter (DW3, DW6)
  if command -v perl >/dev/null 2>&1; then
    perl -e 'select(undef, undef, undef, $ARGV[1])' "$_DH_TOKEN" "$1" 2>/dev/null && return 0
  fi
  sleep "$1" 2>/dev/null || sleep 1
}

# The gate door: waits in place, because `felix gate` is not a command line the tick looks for.
# Returns once the machine is not held or the bound is reached, with FELIX_HOLD_PASSED exported.
_dh_wait_gate() {   # WHO
  local who="$1" t0 now last lim say why
  if _dh_off; then _dh_admit; return 0; fi
  _dh_scan || { _dh_admit; return 0; }
  t0="$(_dh_now)" || { _dh_admit; return 0; }
  _dh_first_line "$who"
  last="$t0"; lim="$(_dh_limit)"; say="$(_dh_say_every)"
  while :; do
    _dh_nap "$(_dh_poll)"
    now="$(_dh_now)" || { _dh_admit; return 0; }
    if ! _dh_scan; then
      case "$_DH_STATE" in lapsed) why="the hold lapsed" ;; *) why="the hold ended" ;; esac
      _dh_say "$who" "went ahead after $((now - t0)) s: $why"; _dh_admit; return 0
    fi
    if [ "$((now - t0))" -ge "$lim" ]; then
      _dh_say "$who" "went ahead after $((now - t0)) s: the limit was reached"; _dh_admit; return 0
    fi
    if [ "$((now - last))" -ge "$say" ]; then
      _dh_say "$who" "still waiting for the engine deploy ($((now - t0)) s of at most $lim s)"; last="$now"
    fi
  done
}

# The run door: tests/run calls it first, before it makes anything. While the machine is held it
# does not return: it replaces itself with a perl that sleeps and starts the script again, which
# comes back here, and so on, with its state in two variables. The perl holds the script's path and
# arguments in its environment, so no process of the waiter has the lander's pattern in its command line.
_dh_enter_run() {   # SCRIPT ARGS...
  local script="$1" who="tests/run" t0 now last lim say why a argv
  shift
  if _dh_off; then _dh_admit; return 0; fi
  t0="${FELIX_HOLD_T0:-}"; _dh_dec "$t0" || t0=""
  if ! _dh_scan; then
    if [ -n "$t0" ]; then
      now="$(_dh_now)" || now="$t0"
      case "$_DH_STATE" in lapsed) why="the hold lapsed" ;; *) why="the hold ended" ;; esac
      _dh_say "$who" "went ahead after $((now - t0)) s: $why"
    fi
    _dh_admit; return 0
  fi
  now="$(_dh_now)" || { _dh_admit; return 0; }
  lim="$(_dh_limit)"; say="$(_dh_say_every)"
  if [ -z "$t0" ]; then
    t0="$now"; last="$now"; _dh_first_line "$who"
  else
    last="${FELIX_HOLD_LAST:-$t0}"; _dh_dec "$last" || last="$t0"
    if [ "$((now - t0))" -ge "$lim" ]; then
      _dh_say "$who" "went ahead after $((now - t0)) s: the limit was reached"; _dh_admit; return 0
    fi
    if [ "$((now - last))" -ge "$say" ]; then
      _dh_say "$who" "still waiting for the engine deploy ($((now - t0)) s of at most $lim s)"; last="$now"
    fi
  fi
  command -v perl >/dev/null 2>&1 || { _dh_say "$who" "not waiting for the engine deploy: there is no perl to wait in"; _dh_admit; return 0; }
  argv="${BASH:-bash}"
  for a in "$script" "$@"; do
    case "$a" in *$'\037'*) _dh_say "$who" "not waiting for the engine deploy: an argument holds a unit separator"; _dh_admit; return 0 ;; esac
    argv="$argv"$'\037'"$a"
  done
  FELIX_HOLD_T0="$t0"; FELIX_HOLD_LAST="$last"; export FELIX_HOLD_T0 FELIX_HOLD_LAST
  FELIX_HOLD_ARGV="$argv" exec perl -e '
    select(undef, undef, undef, $ARGV[1]);
    my @a = split /\037/, delete $ENV{FELIX_HOLD_ARGV}, -1;
    exec { $a[0] } @a;
    print STDERR "tests/run: cannot start again after waiting for the engine deploy: $!\n"; exit 127;
  ' "$_DH_TOKEN" "$(_dh_poll)"
}

# DW2. The tick writes the hold whole (a temporary file beside it, then a rename). SINCE is kept from
# the file already there when its lease is fresh and it is for the same VERSION; else it is now.
# Returns 1, having written nothing, when it cannot: that costs the machine its window and never a run.
_dh_assert() {   # LANDDIR VERSION
  local land="$1" ver="${2:-}" f now since tmp
  [ -n "$ver" ] || ver="-"
  case "$ver" in *$'\t'*|*$'\n'*) ver="-" ;; esac
  f="$land/deploy-hold"; tmp="$land/deploy-hold.$$"
  now="$(_dh_now)" || return 1
  since="$now"
  if _dh_read "$f" && [ "$_DH_VER" = "$ver" ] && [ "$_DH_LEASE" -le "$((now + 60))" ] \
     && [ "$((now - _DH_LEASE))" -lt "$_DH_LEASE_TTL" ] && [ "$_DH_SINCE" -le "$now" ]; then since="$_DH_SINCE"; fi
  mkdir -p "$land" 2>/dev/null || return 1
  [ ! -d "$f" ] || rmdir "$f" 2>/dev/null || return 1
  printf '%s\t%s\t%s\n' "$now" "$since" "$ver" > "$tmp" 2>/dev/null && mv -f "$tmp" "$f" 2>/dev/null || { rm -f "$tmp" 2>/dev/null; return 1; }
  _DH_ASOF="$now"; _DH_ASINCE="$since"
}

_dh_clear() { rm -f "$1/deploy-hold" "$1/deploy-hold.$$" 2>/dev/null; return 0; }   # LANDDIR

# DW3. PIDS, one per line, as pgrep printed them -> those that are not waiting. A pid is dropped when
# the process table shows it holding the token, or above a process that holds it. Anything the table
# does not show, or will not give, stays: it counts as running.
_dh_unwaiting() {   # PIDS
  local tbl out
  tbl="$(ps -axo pid=,ppid=,command= 2>/dev/null)" || { printf '%s\n' "$1"; return 0; }
  [ -n "$tbl" ] || { printf '%s\n' "$1"; return 0; }
  out="$(printf '%s\n' "$tbl" | LC_ALL=C PIDS="$1" TOKEN="$_DH_TOKEN" awk '
    BEGIN { n = split(ENVIRON["PIDS"], P, "\n"); tok = ENVIRON["TOKEN"] }
    $1 ~ /^[0-9]+$/ && $2 ~ /^[0-9]+$/ {
      c = $0; sub(/^[ \t]*[0-9]+[ \t]+[0-9]+[ \t]*/, "", c)
      seen[$1] = 1; par[$1] = $2
      if (index(c, tok) > 0) w[++nw] = $1
    }
    END {
      for (i = 1; i <= nw; i++) {
        p = w[i]; drop[p] = 1
        for (k = 0; k < 256 && (p in par) && par[p] > 1; k++) { p = par[p]; drop[p] = 1 }
      }
      for (i = 1; i <= n; i++) if (P[i] ~ /^[0-9]+$/ && !((P[i] in seen) && (P[i] in drop))) print P[i]
    }')" || { printf '%s\n' "$1"; return 0; }
  printf '%s' "$out"
}
