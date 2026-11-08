# The runs behind lib/instrument.sh (trust-plane step 3, slice 3, spec S8.2, S8.5, S8.10): the run tree T, the
# units of P's suite in part mode, at the gate's job count, and their removal on any exit. Split from instrument.sh
# for its length; that file says what is judged and why. Sourced by instrument.sh.

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

# S8.10. Every unit still running is stopped by its process group, TERM and then KILL after three seconds, and
# the subshell that waits for it; then the run's directory goes. Only the process that made it removes it (the
# owner is read as bind.sh reads its own, never $$).
_felix_instr_kill() {
  local f pg i=0 live s
  for s in TERM wait KILL; do
    if [ "$s" = wait ]; then
      while [ "$i" -lt 30 ]; do
        live=""
        for f in "$_FELIX_INSTR_J"/u/*.pid; do
          [ -f "$f" ] && [ ! -f "${f%.pid}.rc" ] && { read -r pg < "$f"; } 2>/dev/null || continue
          case "$pg" in ''|*[!0123456789]*) continue ;; esac
          kill -0 -- "-$pg" 2>/dev/null && live=1
        done
        [ -n "$live" ] || break
        sleep 0.1; i=$((i + 1))
      done
      continue
    fi
    # A unit whose status is written has ended, and its group's number may be another process's by now.
    for f in "$_FELIX_INSTR_J"/u/*.pid; do
      [ -f "$f" ] && [ ! -f "${f%.pid}.rc" ] && { read -r pg < "$f"; } 2>/dev/null || continue
      case "$pg" in ''|*[!0123456789]*) continue ;; esac
      kill "-$s" -- "-$pg" 2>/dev/null
    done
    [ "$s" != TERM ] || for pg in ${_FELIX_INSTR_SUB[@]+"${_FELIX_INSTR_SUB[@]}"}; do kill -TERM "$pg" 2>/dev/null; done
  done
  for pg in ${_FELIX_INSTR_SUB[@]+"${_FELIX_INSTR_SUB[@]}"}; do wait "$pg" 2>/dev/null; done
  _FELIX_INSTR_SUB=()
}
_felix_instr_clean() {
  [ -n "${_FELIX_INSTR_J:-}" ] || return 0
  [ "${BASHPID:-$(exec /bin/sh -c 'echo "$PPID"')}" = "${_FELIX_INSTR_OWNER:-}" ] || return 0
  _felix_instr_kill
  rm -rf "$_FELIX_INSTR_J" 2>/dev/null
  _FELIX_INSTR_J=""
}
_felix_instr_stop() {   # EXIT-STATUS: a signal reached felix merge while P's suite ran
  trap '' TERM INT HUP
  _felix_instr_clean
  exit "$1"
}

# T, or the canary's copy: a git repository at DEST whose index and files are H's tree, with engine/harness/tests,
# the gate and the workflows replaced by B's when REPLACE is 1, committed on BRANCH with H as its parent. Its
# objects are read through the checked copy (bind.sh), loose store first, and the checkout's behind it.
_felix_instr_tree() {   # ROOT DEST H B GATE-PATH REPLACE BRANCH
  local root="$1" dest="$2" h="$3" b="$4" gp="$5" rep="$6" br="$7" objs p t line c
  objs="${_FELIX_BIND_HOME:-}"
  [ -n "$objs" ] || objs="$(env -u GIT_OBJECT_DIRECTORY -u GIT_ALTERNATE_OBJECT_DIRECTORIES git -C "$root" rev-parse --path-format=absolute --git-path objects 2>/dev/null </dev/null)"
  mkdir -p "$dest" && _felix_instr_git "$dest" init -q --template= >/dev/null 2>&1 && mkdir -p "$dest/.git/objects/info" || return 1
  { [ -z "${_FELIX_BIND_DIR:-}" ] || printf '%s\n' "$_FELIX_BIND_DIR/v" "$_FELIX_BIND_DIR/objects"; printf '%s\n' "$objs"; } \
    > "$dest/.git/objects/info/alternates" || return 1
  _felix_instr_git "$dest" read-tree "$h^{tree}" >/dev/null 2>&1 || return 1
  if [ "$rep" = 1 ]; then
    _felix_instr_git "$dest" rm --cached -r -q --ignore-unmatch -- "$_FELIX_INSTR_TP" ${gp:+"$gp"} .github/workflows >/dev/null 2>&1 || return 1
    for p in "$_FELIX_INSTR_TP" .github/workflows; do
      t="$(git -C "$root" cat-file -t "$b:$p" 2>/dev/null </dev/null)"
      [ "$t" != tree ] || _felix_instr_git "$dest" read-tree --prefix="$p/" "$b:$p" >/dev/null 2>&1 || return 1
    done
    if [ -n "$gp" ]; then
      line="$(git -C "$root" ls-tree "$b" -- "$gp" 2>/dev/null </dev/null)"
      case "$line" in
        "100644 blob "*|"100755 blob "*) t="${line#* blob }"; t="${t%%$'\t'*}"
          _felix_instr_git "$dest" update-index --add --cacheinfo "${line%% *},$t,$gp" >/dev/null 2>&1 || return 1 ;;
      esac
    fi
  fi
  t="$(_felix_instr_git "$dest" write-tree 2>/dev/null)" || return 1
  c="$(_felix_instr_git "$dest" commit-tree "$t" -p "$h" -m "felix merge: P's suite over $h" 2>/dev/null)" || return 1
  _felix_instr_git "$dest" check-ref-format "refs/heads/$br" >/dev/null 2>&1 || br=felix-run
  _felix_instr_git "$dest" update-ref "refs/heads/$br" "$c" >/dev/null 2>&1 \
    && _felix_instr_git "$dest" symbolic-ref HEAD "refs/heads/$br" >/dev/null 2>&1 \
    && _felix_instr_git "$dest" checkout-index -a -f >/dev/null 2>&1 || return 1
  _felix_instr_git "$dest" update-index -q --refresh >/dev/null 2>&1
  return 0
}

# One unit of a suite in part mode, in the background, in a process group of its own: the copy's object variables,
# bind's other settings and felix merge's own variables unset, and TMPDIR as felix merge was given it, as the gate
# hands it to the suite (a TMPDIR of the run's own made the suite's fixture checks fail where mktemp does not read
# TMPDIR, under sandbox-exec). N 0 is the canary, which writes no end or ran file. Its status lands in u/N.rc on
# every path.
_felix_instr_pl='$SIG{INT} = "DEFAULT"; $SIG{QUIT} = "DEFAULT"; setpgrp(0, 0); my $f = shift @ARGV;
if (open(my $h, ">", $f)) { print $h "$$\n"; close $h } exec { $ARGV[0] } @ARGV; exit 127'
_felix_instr_launch() {   # N DIR MEMBER...
  local n="$1" dir="$2" u="$_FELIX_INSTR_J/u"
  shift 2
  local -a ev=("FELIX_TEST_PART_LOG=$u/$n.log")
  [ "$n" = 0 ] || ev=("${ev[@]}" "FELIX_TEST_PART_RAN=$u/$n.ran" "FELIX_TEST_PART_END=$u/$n.end")
  ( rc=1
    if cd "$dir" 2>/dev/null; then
      env -u GIT_OBJECT_DIRECTORY -u GIT_ALTERNATE_OBJECT_DIRECTORIES -u GIT_GRAFT_FILE -u GIT_NO_REPLACE_OBJECTS \
          -u GIT_CONFIG_COUNT -u GIT_CONFIG_KEY_0 -u GIT_CONFIG_VALUE_0 -u GIT_CONFIG_KEY_1 -u GIT_CONFIG_VALUE_1 \
          -u FELIX_MERGE_DRY_RUN -u FELIX_MERGE_BASE_AT -u FELIX_MERGE_BASE_REF -u FELIX_MERGE_HANDED -u FELIX_KERNEL \
          -u FELIX_TEST_JOBS -u FELIX_TEST_PART_RECORD -u FELIX_TEST_PART_RAN -u FELIX_TEST_PART_END \
          "${ev[@]}" \
          perl -e "$_felix_instr_pl" "$u/$n.pid" "${BASH:-bash}" engine/harness/tests/run --part "$@" \
          >> "$u/$n.log" 2>&1 </dev/null
      rc=$?
    fi
    printf '%s\n' "$rc" > "$u/$n.rc.t" 2>/dev/null && mv -f "$u/$n.rc.t" "$u/$n.rc" 2>/dev/null ) &
  _FELIX_INSTR_SUB[n]=$!
}
# Units 1 to COUNT of _FELIX_INSTR_U in DIR, JOBS at a time; returns when each has written its status.
_felix_instr_runall() {   # JOBS DIR COUNT
  local jobs="$1" dir="$2" n="$3" next=1 run=0 i live=" "
  while :; do
    while [ "$run" -lt "$jobs" ] && [ "$next" -le "$n" ]; do
      # shellcheck disable=SC2086
      _felix_instr_launch "$next" "$dir" ${_FELIX_INSTR_U[next]}
      live="$live$next "; run=$((run + 1)); next=$((next + 1))
    done
    [ "$run" -gt 0 ] || break
    sleep 0.1
    for i in $live; do
      [ -f "$_FELIX_INSTR_J/u/$i.rc" ] || continue
      wait "${_FELIX_INSTR_SUB[i]}" 2>/dev/null; unset "_FELIX_INSTR_SUB[i]"
      live="${live/ $i / }"; run=$((run - 1))
    done
  done
}
