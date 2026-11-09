# The runs behind lib/instrument.sh (trust-plane step 3, slice 3, spec S8.2, S8.5, S8.10, A7): where they run, the
# run tree T and the canary's copy, the units of P's suite in part mode at the gate's job count, their time limits,
# and their removal on any exit. Split from instrument.sh for its length; that file says what is judged and why.
#
# - A7.5: T and the canary's copy are made under the caller's TMPDIR only when it is absolute and outside the
#   checkout, and under /tmp otherwise; the units are given that TMPDIR. A7.8: the records (each unit's log, ran
#   file, end record, group and status) are in a second directory, outside that TMPDIR and outside the checkout,
#   which no unit is told about; only the judge writes a unit's status, from the exit status the kernel hands it.
# - A7.6: T and the copy each hold the objects they need, history with it, copied in through one pack, and name no
#   other store: neither the checked copy nor the checkout's objects are handed to the candidate's code in a unit.
# - A7.2, A7.3: each unit runs under a supervisor of the judge's (perl), in a process group of its own. The
#   supervisor ends that group, TERM then KILL, when the unit ends, when its time is up (30 minutes, 5 for the
#   canary, lowered only by FELIX_INSTRUMENT_UNIT_SECONDS and FELIX_INSTRUMENT_CANARY_SECONDS), when it is told
#   to, and when the judge is gone. The judge ends what is left of the group too, and of every group at the end.
# - A7.4: TERM, INT, HUP and QUIT end the judgement with T and the records removed, within about two seconds.
#
# Not bound: a unit's process that leaves its process group (setsid) is not ended by any of this; the unit runs as
# the same user, so a store or a directory it finds by other means is still open to it (spec section 3).

# The gate's job count (projects/<name>/gate.sh, contract D1 as R51 and R52 replace it), computed the same way.
_felix_instr_jobs() {
  local n=""
  if [ "${GITHUB_ACTIONS:-}" != true ]; then
    n="$(sysctl -n hw.perflevel0.logicalcpu 2>/dev/null)"
    case "$n" in ''|*[!0123456789]*) n="" ;; esac
    n="${n#"${n%%[!0]*}"}"
    if [ -z "$n" ]; then
      n="$(sysctl -n hw.ncpu 2>/dev/null)"
      case "$n" in ''|*[!0123456789]*) n="$(getconf _NPROCESSORS_ONLN 2>/dev/null)" ;; esac
      case "$n" in ''|*[!0123456789]*) n=1 ;; esac
      n="${n#"${n%%[!0]*}"}"
    fi
  fi
  case "$n" in '') n=1 ;; ?|??) ;; *) n=64 ;; esac
  [ "$n" -le 64 ] || n=64
  printf '%s' "$n"
}

# A7.2. The time limit: DEFAULT seconds, or the caller's VALUE when it is a whole number below it. Never above.
_felix_instr_limit() {   # DEFAULT VALUE
  local v="$2"
  case "$v" in ''|*[!0123456789]*) printf '%s' "$1"; return 0 ;; esac
  v="${v#"${v%%[!0]*}"}"; [ -n "$v" ] || v=1
  if [ "${#v}" -le 9 ] && [ "$v" -lt "$1" ]; then printf '%s' "$v"; else printf '%s' "$1"; fi
}

# A7.5. The TMPDIR T is made under and the units are given: the caller's when it is absolute and, physically,
# neither the checkout ROOT nor inside it; /tmp otherwise. Also read by bind.sh for slice 2's copy, which the
# same rule binds (a reading: spec A7.5 names T and the run directory).
felix_instr_tmpbase() {   # ROOT
  local t="${TMPDIR:-}" p r
  case "$t" in /*) ;; *) printf '/tmp'; return 0 ;; esac
  p="$(cd "$t" 2>/dev/null && pwd -P)" || p="$t"
  r="$(cd "${1:-/nonexistent}" 2>/dev/null && pwd -P)" || r=""
  if [ -n "$r" ]; then case "${p%/}/" in "${r%/}"/*) printf '/tmp'; return 0 ;; esac; fi
  printf '%s' "$t"
}
_felix_instr_inside() { case "${1%/}/" in "${2%/}"/*) return 0 ;; esac; return 1; }   # PATH DIR, both physical

# A7.5, A7.8, S8.10. The run directory J (T and the canary's copy) under the units' TMPDIR, and the records R
# outside it, both outside the checkout; the signal and exit traps for the run. 1, with one unknown SUITE line and
# nothing left behind, when either cannot be made.
felix_instr_dirs() {   # ROOT
  local root="$1" base pb r0 q rb="" j="" r=""
  base="$(felix_instr_tmpbase "$root")"
  pb="$(cd "$base" 2>/dev/null && pwd -P)" || pb="$base"
  r0="$(cd "$root" 2>/dev/null && pwd -P)" || r0="$root"
  for q in /tmp /var/tmp; do
    q="$(cd "$q" 2>/dev/null && pwd -P)" || continue
    [ "$pb" != / ] && ! _felix_instr_inside "$q" "$pb" && ! _felix_instr_inside "$q" "$r0" && { rb="$q"; break; }
  done
  j="$(mktemp -d "${base%/}/felix-instrument.XXXXXX" 2>/dev/null)" || j=""
  [ -z "$j" ] || j="$(cd "$j" 2>/dev/null && pwd -P)" || j=""
  [ -z "$rb" ] || r="$(mktemp -d "$rb/felix-instrument-r.XXXXXX" 2>/dev/null)" || r=""
  [ -z "$r" ] || r="$(cd "$r" 2>/dev/null && pwd -P)" || r=""
  if [ -z "$j" ] || [ -z "$r" ] || ! chmod 700 "$r" 2>/dev/null; then
    [ -z "$j" ] || rm -rf "$j" 2>/dev/null; [ -z "$r" ] || rm -rf "$r" 2>/dev/null
    _felix_instr_add unknown SUITE "no directory could be made under $base for the run tree, or outside it for the run's records"
    return 1
  fi
  _FELIX_INSTR_J="$j"; _FELIX_INSTR_R="$r"; _FELIX_INSTR_BASE="$base"; _FELIX_INSTR_T0=()
  _FELIX_INSTR_OWNER="${BASHPID:-$(exec /bin/sh -c 'echo "$PPID"')}"
  trap '_felix_instr_stop 143' TERM; trap '_felix_instr_stop 130' INT; trap '_felix_instr_stop 129' HUP; trap '_felix_instr_stop 131' QUIT
  if command -v _felix_bind_exit >/dev/null 2>&1; then trap '_felix_instr_clean 2>/dev/null; _felix_bind_exit' EXIT; else trap '_felix_instr_clean 2>/dev/null' EXIT; fi
}

# git in a repository this run made: none of the copy's object variables, no machine-local configuration, an
# identity of its own.
_felix_instr_git() {   # DIR git-args...
  local d="$1"; shift
  env -u GIT_OBJECT_DIRECTORY -u GIT_ALTERNATE_OBJECT_DIRECTORIES -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
      -u GIT_COMMON_DIR -u GIT_GRAFT_FILE HOME="$d" XDG_CONFIG_HOME="$d" GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 \
      GIT_AUTHOR_NAME=felix GIT_AUTHOR_EMAIL=felix@localhost GIT_COMMITTER_NAME=felix GIT_COMMITTER_EMAIL=felix@localhost \
      git -C "$d" -c core.excludesFile=/dev/null -c core.ignoreCase=false -c core.autocrlf=false -c core.hooksPath=/dev/null "$@"
}
# git in the checkout with an index of the run's own, writing what it makes into the store the merging shell writes
# to (bind.sh's copy when one is set): no hooks, no signing, an identity of its own.
_felix_instr_rg() {   # ROOT INDEX-FILE git-args...
  local root="$1" ix="$2"; shift 2
  GIT_INDEX_FILE="$ix" GIT_AUTHOR_NAME=felix GIT_AUTHOR_EMAIL=felix@localhost GIT_COMMITTER_NAME=felix \
    GIT_COMMITTER_EMAIL=felix@localhost git -C "$root" -c core.hooksPath=/dev/null -c commit.gpgSign=false \
    -c core.autocrlf=false -c core.safecrlf=false "$@"
}

# T (WANT-T 1): the merge's tree MT with engine/harness/tests, the gate and the workflows replaced by B's. The
# canary's copy (WANT-C 1): MT with the canary's part and driver from the records. Each is committed with H as its
# parent, and both, with their history, are copied into repositories of their own through one pack (A7.6).
_felix_instr_build() {   # ROOT MT B H GATE-PATH BRANCH LB WANT-T WANT-C
  local root="$1" mt="$2" b="$3" h="$4" gp="$5" br="$6" lb="$7" r="$_FELIX_INSTR_R" tp="$_FELIX_INSTR_TP" tc="" cc="" t p s d m
  if [ "$8" = 1 ]; then
    _felix_instr_rg "$root" "$r/t.idx" read-tree "$mt" >/dev/null 2>&1 </dev/null \
      && _felix_instr_rg "$root" "$r/t.idx" ls-files -z -- "$tp" ${gp:+"$gp"} .github/workflows > "$r/t.drop" 2>/dev/null </dev/null \
      && _felix_instr_rg "$root" "$r/t.idx" update-index -z --force-remove --stdin < "$r/t.drop" >/dev/null 2>&1 || return 1
    for p in "$tp" .github/workflows; do
      printf '%s\n' "$lb" | LC_ALL=C awk -v p="$p/" 'index($0, "\t" p) { f = 1 } END { exit !f }' || continue
      _felix_instr_rg "$root" "$r/t.idx" read-tree --prefix="$p/" "$b:$p" >/dev/null 2>&1 </dev/null || return 1
    done
    if [ -n "$gp" ] && s="$(_felix_instr_sha "$lb" "$gp")" && [ -n "$s" ]; then
      m="$(printf '%s\n' "$lb" | LC_ALL=C awk -v p="$gp" '{ i = index($0, "\t") } i && substr($0, i + 1) == p { print $1; exit }')"
      _felix_instr_rg "$root" "$r/t.idx" update-index --add --cacheinfo "$m,$s,$gp" >/dev/null 2>&1 </dev/null || return 1
    fi
    _felix_instr_rd t _felix_instr_rg "$root" "$r/t.idx" write-tree && [ -n "$t" ] || return 1
    _felix_instr_rd tc _felix_instr_rg "$root" "$r/t.idx" commit-tree "$t" -p "$h" -m "felix merge: P's suite over what the squash would land" \
      && [ -n "$tc" ] || return 1
  fi
  if [ "$9" = 1 ]; then
    _felix_instr_rg "$root" "$r/c.idx" read-tree "$mt" >/dev/null 2>&1 </dev/null || return 1
    _felix_instr_rd s _felix_instr_rg "$root" "$r/c.idx" hash-object -w --no-filters "$r/canary.part" && [ -n "$s" ] \
      && _felix_instr_rd d _felix_instr_rg "$root" "$r/c.idx" hash-object -w --no-filters "$r/canary.drv" && [ -n "$d" ] \
      && _felix_instr_rg "$root" "$r/c.idx" update-index --add --cacheinfo "100644,$s,$tp/parts/9989-$_FELIX_INSTR_CID.sh" >/dev/null 2>&1 </dev/null \
      && _felix_instr_rg "$root" "$r/c.idx" update-index --add --cacheinfo "$_FELIX_INSTR_CDMODE,$d,$tp/run" >/dev/null 2>&1 </dev/null \
      && _felix_instr_rd t _felix_instr_rg "$root" "$r/c.idx" write-tree && [ -n "$t" ] \
      && _felix_instr_rd cc _felix_instr_rg "$root" "$r/c.idx" commit-tree "$t" -p "$h" -m "felix merge: the canary" && [ -n "$cc" ] || return 1
  fi
  printf '%s\n' $tc $cc | _felix_instr_rg "$root" "$r/none.idx" pack-objects --revs --stdout -q --window=0 > "$r/v.pack" 2>/dev/null || return 1
  [ -z "$tc" ] || _felix_instr_repo "$_FELIX_INSTR_J/t" "$tc" "$br" "$r/v.pack" || return 1
  [ -z "$cc" ] || _felix_instr_repo "$_FELIX_INSTR_J/c" "$cc" "$br" "$r/v.pack" || return 1
  rm -f "$r/v.pack" "$r/t.idx" "$r/c.idx" "$r/t.drop" 2>/dev/null
  return 0
}
_felix_instr_repo() {   # DEST COMMIT BRANCH PACK: a repository of its own at DEST, checked out at COMMIT on BRANCH
  local d="$1" c="$2" br="$3"
  mkdir -p "$d" 2>/dev/null && _felix_instr_git "$d" init -q --template= >/dev/null 2>&1 </dev/null || return 1
  _felix_instr_git "$d" index-pack --stdin < "$4" >/dev/null 2>&1 || return 1
  _felix_instr_git "$d" check-ref-format "refs/heads/$br" >/dev/null 2>&1 </dev/null || br=felix-run
  _felix_instr_git "$d" read-tree "$c" >/dev/null 2>&1 </dev/null \
    && _felix_instr_git "$d" update-ref "refs/heads/$br" "$c" >/dev/null 2>&1 </dev/null \
    && _felix_instr_git "$d" symbolic-ref HEAD "refs/heads/$br" >/dev/null 2>&1 </dev/null \
    && _felix_instr_git "$d" checkout-index -a -f >/dev/null 2>&1 </dev/null || return 1
  _felix_instr_git "$d" update-index -q --refresh >/dev/null 2>&1 </dev/null
  return 0
}

# The supervisor of one unit (A7.2, A7.3, A7.8): LIMIT LOG GROUP-FILE J R COMMAND... It leaves the judge's process
# group, starts the unit in a group of its own with its output to LOG, writes that group's number, and waits. When
# the unit ends, its time is up, it is told to stop, or the judge is gone, it ends the unit's group, TERM and then
# KILL a second later, and exits with the unit's status (124: the time limit; 125: stopped). A judge that is gone
# was killed by a signal it could not trap (KILL, or one it does not trap): the supervisor then removes J and R.
_felix_instr_pl='use POSIX ();
my ($lim, $log, $pf, $jd, $rd, @cmd) = @ARGV; my $pp = getppid(); setpgrp(0, 0);
my $u = fork(); exit 125 unless defined $u;
if (!$u) { setpgrp(0, 0); $SIG{$_} = "DEFAULT" for qw(INT QUIT TERM HUP PIPE ALRM);
  open(STDIN, "<", "/dev/null"); open(STDOUT, ">>", $log) or POSIX::_exit(126); open(STDERR, ">&", \*STDOUT) or POSIX::_exit(126);
  exec { $cmd[0] } @cmd; POSIX::_exit(127) }
if (open(my $h, ">", $pf)) { print $h "$u\n"; close $h }
my ($stop, $st, $why) = (0, undef, 0); $SIG{$_} = sub { $stop = 1 } for qw(TERM HUP INT QUIT);
my $end = time + $lim;
while (1) { my $r = waitpid($u, POSIX::WNOHANG());
  if ($r == $u) { $st = $?; last } if ($r < 0) { $why = 125; last }
  if ($stop) { $why = 125; last } if (getppid() != $pp) { $why = 126; last } if (time >= $end) { $why = 124; last }
  select(undef, undef, undef, 0.2) }
kill "TERM", -$u;
for (1 .. 10) { last unless kill 0, -$u; select(undef, undef, undef, 0.1);
  if (!defined $st && waitpid($u, POSIX::WNOHANG()) == $u) { $st = $? } }
kill "KILL", -$u; waitpid($u, 0) unless defined $st;
if ($why == 126) { chdir "/"; require File::Path; File::Path::remove_tree($jd, $rd); exit 125 }
exit $why if $why; exit(($st & 127) ? 128 + ($st & 127) : ($st >> 8));'
# One unit of a suite in part mode, in DIR, under its supervisor, in the background: the copy's object variables,
# bind's other settings and felix merge's own variables unset, and the TMPDIR of A7.5. N 0 is the canary, which is
# given no end or ran file.
_felix_instr_launch() {   # N DIR LIMIT MEMBER...
  local n="$1" dir="$2" lim="$3" r="$_FELIX_INSTR_R"
  shift 3
  local -a ev=()
  [ "$n" = 0 ] || ev=("FELIX_TEST_PART_RAN=$r/$n.ran" "FELIX_TEST_PART_END=$r/$n.end")
  ( cd "$dir" 2>/dev/null || exit 1
    exec env -u GIT_OBJECT_DIRECTORY -u GIT_ALTERNATE_OBJECT_DIRECTORIES -u GIT_GRAFT_FILE -u GIT_NO_REPLACE_OBJECTS \
      -u GIT_CONFIG_COUNT -u GIT_CONFIG_KEY_0 -u GIT_CONFIG_VALUE_0 -u GIT_CONFIG_KEY_1 -u GIT_CONFIG_VALUE_1 \
      -u FELIX_MERGE_DRY_RUN -u FELIX_MERGE_BASE_AT -u FELIX_MERGE_BASE_REF -u FELIX_MERGE_HANDED -u FELIX_KERNEL \
      -u FELIX_TEST_JOBS -u FELIX_TEST_PART_RECORD -u FELIX_TEST_PART_RAN -u FELIX_TEST_PART_END -u FELIX_TEST_PART_LOG \
      -u FELIX_INSTRUMENT_UNIT_SECONDS -u FELIX_INSTRUMENT_CANARY_SECONDS TMPDIR="$_FELIX_INSTR_BASE" ${ev[@]+"${ev[@]}"} \
      perl -e "$_felix_instr_pl" "$lim" "$r/$n.log" "$r/$n.pid" "$_FELIX_INSTR_J" "$r" "${BASH:-bash}" engine/harness/tests/run --part "$@" \
      </dev/null >/dev/null 2>&1 ) &
  _FELIX_INSTR_SUB[n]=$!; _FELIX_INSTR_T0[n]=$SECONDS
}
# 0 when unit N has ended (its supervisor has exited, or outlived the unit's LIMIT by 20 s and is killed). The
# judge then writes N.rc from the exit status the kernel handed it, and ends what is left of the unit's group.
_felix_instr_ended() {   # N LIMIT
  local n="$1" p="${_FELIX_INSTR_SUB[$1]:-}" rc
  [ -n "$p" ] || return 0
  if kill -0 "$p" 2>/dev/null; then
    [ "$SECONDS" -ge $(( ${_FELIX_INSTR_T0[$n]:-0} + $2 + 20 )) ] || return 1
    kill -KILL "$p" 2>/dev/null
  fi
  wait "$p" 2>/dev/null; rc=$?
  _felix_instr_endgroup "$_FELIX_INSTR_R/$n.pid"
  printf '%s\n' "$rc" > "$_FELIX_INSTR_R/$n.rc" 2>/dev/null
  unset "_FELIX_INSTR_SUB[$n]"
  return 0
}
_felix_instr_endgroup() {   # GROUP-FILE: what is left of a unit's process group, killed
  local pg=""
  { read -r pg < "$1"; } 2>/dev/null
  case "$pg" in ''|*[!0123456789]*|0|1) return 0 ;; esac
  kill -0 -- "-$pg" 2>/dev/null || return 0
  kill -TERM -- "-$pg" 2>/dev/null; sleep 0.2; kill -KILL -- "-$pg" 2>/dev/null
  return 0
}
# Units 1 to COUNT of _FELIX_INSTR_U in DIR, JOBS at a time; returns when each has ended.
_felix_instr_runall() {   # JOBS DIR COUNT
  local jobs="$1" dir="$2" n="$3" next=1 run=0 i live=" " lim
  lim="$(_felix_instr_limit 1800 "${FELIX_INSTRUMENT_UNIT_SECONDS:-}")"; _FELIX_INSTR_ULIM="$lim"
  while :; do
    while [ "$run" -lt "$jobs" ] && [ "$next" -le "$n" ]; do
      # shellcheck disable=SC2086
      _felix_instr_launch "$next" "$dir" "$lim" ${_FELIX_INSTR_U[next]}
      live="$live$next "; run=$((run + 1)); next=$((next + 1))
    done
    [ "$run" -gt 0 ] || break
    sleep 0.2
    for i in $live; do
      _felix_instr_ended "$i" "$lim" || continue
      live="${live/ $i / }"; run=$((run - 1))
    done
  done
}

# A7.3, S8.10. Every supervisor still running is told to stop and given 1.5 s, which ends its unit's group; then
# every unit group still alive and every supervisor is killed. Then the run's directories go. Only the process that
# made them removes them (the owner is read as bind.sh reads its own, never $$).
_felix_instr_kill() {
  local p f i=0 live
  for p in ${_FELIX_INSTR_SUB[@]+"${_FELIX_INSTR_SUB[@]}"}; do kill -TERM "$p" 2>/dev/null; done
  while [ "$i" -lt 15 ]; do
    live=""; for p in ${_FELIX_INSTR_SUB[@]+"${_FELIX_INSTR_SUB[@]}"}; do kill -0 "$p" 2>/dev/null && { live=1; break; }; done
    [ -n "$live" ] || break
    sleep 0.1; i=$((i + 1))
  done
  for f in "$_FELIX_INSTR_R"/*.pid; do [ -f "$f" ] && _felix_instr_endgroup "$f"; done
  for p in ${_FELIX_INSTR_SUB[@]+"${_FELIX_INSTR_SUB[@]}"}; do kill -KILL "$p" 2>/dev/null; wait "$p" 2>/dev/null; done
  _FELIX_INSTR_SUB=()
}
_felix_instr_clean() {
  [ -n "${_FELIX_INSTR_J:-}${_FELIX_INSTR_R:-}" ] || return 0
  [ "${BASHPID:-$(exec /bin/sh -c 'echo "$PPID"')}" = "${_FELIX_INSTR_OWNER:-}" ] || return 0
  [ -z "${_FELIX_INSTR_R:-}" ] || _felix_instr_kill
  [ -z "${_FELIX_INSTR_J:-}" ] || rm -rf "$_FELIX_INSTR_J" 2>/dev/null
  [ -z "${_FELIX_INSTR_R:-}" ] || rm -rf "$_FELIX_INSTR_R" 2>/dev/null
  _FELIX_INSTR_J=""; _FELIX_INSTR_R=""
}
_felix_instr_stop() {   # EXIT-STATUS: a signal reached felix merge while P's suite ran
  trap '' TERM INT HUP QUIT
  _felix_instr_clean 2>/dev/null
  exit "$1"
}
