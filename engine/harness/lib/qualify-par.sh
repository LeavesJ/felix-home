# The rows of checker qualification run in parallel: how many at once, the
# scheduler, and what a signal does to the rows in flight.
#
# Split out of lib/qualify.sh, which sources it. Each row already runs in a
# process, a scratch base and a worktree of its own (_felix_qualify_one,
# lib/qualify-run.sh), and nothing a row does is read by the next, so rows can
# overlap; felix-home's 296 took 125 s of the gate in sequence. What stays as
# it was is what a caller sees: the verdict lines in the table's order, each
# row's stderr whole and in that order, the status. FELIX_QUALIFY_JOBS=1 does
# not come here at all (_felix_qualify_run_rows).

# How many rows may be in flight at once, in _felix_qualify_nj: the positive
# integer FELIX_QUALIFY_JOBS holds; the machine's online CPUs when it is unset;
# 1 for anything else it may hold (empty, 0, a sign, a space, letters), and 1
# when the machine will not say. Digits only, so no value is ever read as octal
# or as a sign, and past six digits it is "more than there are rows" anyway.
_felix_qualify_njobs() {
  local j="${FELIX_QUALIFY_JOBS-}"
  if [ "${FELIX_QUALIFY_JOBS+set}" != set ]; then
    j="$(getconf _NPROCESSORS_ONLN 2>/dev/null)"
    case "$j" in ''|*[!0123456789]*) j="$(sysctl -n hw.ncpu 2>/dev/null)" ;; esac
  fi
  case "$j" in ''|*[!0123456789]*) j=1 ;; esac
  [ "${#j}" -le 6 ] || j=999999
  _felix_qualify_nj="$((10#$j))"
  [ "$_felix_qualify_nj" -ge 1 ] || _felix_qualify_nj=1
}

# git worktree add or remove (the rest of the arguments), and, in a parallel
# run, again when it fails, up to _felix_qualify_tries times with a short
# pause between (1 outside one, which is one call, as before). Rows add and
# remove worktrees of one repository at once, and git reads every worktree's
# record while it does: an add that meets another row's record half written
# dies with "failed to read .git/worktrees/w1/commondir", and a remove that
# meets one just removed with "Invalid path". Measured 2026-10-13 on git
# 2.54, 10 rows at once over the 0570 table: an add failed in 4 runs of 30,
# so a row read unrunnable that had nothing wrong with it. A pause rather than
# a lock: the add is 0.2 s of a row, and a lock on it caps the run at one add
# at a time.
_felix_qualify_wt() {   # root, add|remove, args...
  local root="$1" n="${_felix_qualify_tries:-1}" k=1
  shift
  while ! git -C "$root" worktree "$@" >/dev/null 2>&1; do
    [ "$k" -lt "$n" ] || return 1
    k=$((k + 1)); sleep "0.0$((RANDOM % 9 + 1))" 2>/dev/null || sleep 1
  done
}

# Whether row $1 has ended: it left its `.fin` (the last thing a row does, after
# its verdict is whole in `.v`), or its process is gone. Gone without `.fin` is
# a row that was killed, or died, before giving a verdict.
_felix_qualify_par_ended() {
  [ -e "$d/$1.fin" ] || ! kill -0 "${pid[$1]}" 2>/dev/null
}

# Row $1 started as a process of its own, in a group of its own. The group is
# the point: a background job in a non-interactive bash 3.2 ignores SIGINT, and
# so does everything it starts (measured 2026-10-13, bash 3.2.57: a trap on INT
# in such a job never runs, TERM and HUP traps do), so a Ctrl-C reaches none of
# the row's processes, and the loop has to stop them itself. Under `set -m` the
# job leads a group, and one kill of that group reaches the row, its column's
# bash, the checker and git. The group is why the loop forwards TERM to it and
# the row's own trap (_felix_qualify_arm) then runs at once, rather than at the
# end of the column.
#
# `set +m` first thing in the job: with monitor mode on, bash 3.2 gives every
# command the job runs a group of its own, out of the group's reach.
#
# The fork is made with the loop's stderr away: bash 3.2 sometimes says "child
# setpgid (N to N): Operation not permitted" there (once in 12 runs of 18 rows),
# and the row then runs in the loop's group, which stop still reaches by pid.
#
# The job is disowned, because a job killed outright (SIGKILL) is otherwise
# reported by bash on the loop's stderr, "line N: PID Killed: 9", and the row
# is already reported on stdout, as unrunnable. The loop reads its end from the
# process and `.fin`, not from `wait`.
#
# Its stdout and stderr are files in the loop's directory, replayed in the
# table's order (_felix_qualify_par_emit), and its stdin is empty, as every
# column's is. `started` counts a row only once its pid is kept: a signal
# arriving between the fork and that assignment finds the row unknown, so it
# is not stopped, and it runs to its end and throws its own tree away.
_felix_qualify_par_start() {   # row
  local i="$1" mon=0
  case $- in *m*) mon=1 ;; esac
  {
    set -m
    ( set +m
      exec >"$d/$i.v" 2>"$d/$i.e" </dev/null
      _felix_qualify_tries=8
      _felix_qualify_one "$root" "${_fq_cmd[$i]}" "${_fq_mut[$i]}" "${_fq_pre[$i]}"
      : > "$d/$i.fin" ) &
    pid[$i]=$!
    disown "${pid[$i]}" 2>/dev/null
    [ "$mon" -eq 1 ] || set +m
  } 2>/dev/null
  started=$i
}

# Row $1's stderr whole, then its verdict line. A row with no `.fin` ended
# without a verdict, and is unrunnable, never held: what it printed before it
# was killed says nothing about the checker.
_felix_qualify_par_emit() {   # row
  local i="$1" got=unrunnable
  if [ -e "$d/$i.fin" ]; then got="$(cat "$d/$i.v" 2>/dev/null)"; else died=1; fi
  if [ -s "$d/$i.e" ]; then cat "$d/$i.e" >&2; fi
  _felix_qualify_say "${_fq_chk[$i]}" "${_fq_ctl[$i]}" "${_fq_exp[$i]}" "$got"
}

# The loop was signalled (the trap, with the status to leave by). Nothing more
# starts, because this never returns to the scheduler. Every row still in
# flight is sent TERM, its group and itself, and its own trap throws its tree
# away; then the loop waits until each is gone, so that when it exits, every
# base and worktree is, and so is this directory. TERM for all three signals:
# a row's INT trap cannot run (_felix_qualify_par_start), and its TERM trap
# does the same thing. Further signals are ignored while it waits, as a row
# ignores them while it drops its tree.
_felix_qualify_par_stop() {   # status
  local i p
  trap '' INT TERM HUP
  i=1
  while [ "$i" -le "$started" ]; do
    p="${pid[$i]}"
    [ -e "$d/$i.fin" ] || { kill -TERM -- "-$p"; kill -TERM "$p"; } 2>/dev/null
    i=$((i + 1))
  done
  i=1
  while [ "$i" -le "$started" ]; do
    while [ ! -e "$d/$i.fin" ] && kill -0 "${pid[$i]}" 2>/dev/null; do
      sleep 0.05 2>/dev/null || sleep 1
    done
    i=$((i + 1))
  done
  rm -rf -- "$d"
  exit "$1"
}

# The scheduler: at most `jobs` rows in flight, started in the table's order,
# printed in it too, each when it and every row before it has ended. Returns 0;
# 1 when a row ended without a verdict; 98 when it could not make its scratch
# directory, having started nothing, and the caller runs the rows in turn.
#
# Its scratch is a directory of its own under TMPDIR, felix-qrows. and six: not
# a name the sweep looks at (lib/qualify-sweep.sh takes felix-qualify. and six,
# each holding an owner record of a row's), so a sweep run by another process
# in this TMPDIR cannot remove what the loop is still reading. It is made after
# this run's own sweep, and it is removed when the loop returns and when the
# signals below end it. SIGKILL leaves it, a few files with no tree in them,
# and the rows leave their bases for the next sweep, as before.
#
# No `wait -n` in bash 3.2, so it polls: rows and processes checked every 50 ms
# with builtins, the fork being the sleep. Waiting on the oldest row instead
# would hold a slot for every row that finished before it.
#
# The caller's traps on the three signals are put back on the way out. They are
# read into a file, because a $(...) of trap -p shows the subshell's own.
_felix_qualify_par() {   # root, jobs, rows; the row arrays are the caller's
  local root="$1" jobs="$2" n="$3" tmpd="${TMPDIR:-/tmp}" d="" saved="" died=0
  local started=0 next=1 i live emitted
  local -a pid
  d="$(mktemp -d "${tmpd%/}/felix-qrows.XXXXXX" 2>/dev/null)" || return 98
  trap -p INT TERM HUP > "$d/traps" 2>/dev/null
  saved="$(cat "$d/traps" 2>/dev/null)"
  trap '_felix_qualify_par_stop 130' INT
  trap '_felix_qualify_par_stop 143' TERM
  trap '_felix_qualify_par_stop 129' HUP
  while [ "$next" -le "$n" ]; do
    live=0; i="$next"
    while [ "$i" -le "$started" ]; do
      _felix_qualify_par_ended "$i" || live=$((live + 1))
      i=$((i + 1))
    done
    while [ "$started" -lt "$n" ] && [ "$live" -lt "$jobs" ]; do
      _felix_qualify_par_start $((started + 1))
      live=$((live + 1))
    done
    emitted=0
    while [ "$next" -le "$started" ] && _felix_qualify_par_ended "$next"; do
      _felix_qualify_par_emit "$next"
      next=$((next + 1)); emitted=1
    done
    if [ "$next" -le "$n" ] && [ "$emitted" -eq 0 ]; then sleep 0.05 2>/dev/null || sleep 1; fi
  done
  trap - INT TERM HUP
  [ -z "$saved" ] || eval "$saved"
  rm -rf -- "$d"
  return "$died"
}
