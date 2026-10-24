# tests/trace.sh: the tracer (audit b30, contract B7 to B14). The runner of a traced
# run (tests/run -j N with FELIX_TEST_TRACE_DIR set: part 0007 and tests/select.sh)
# starts every unit with BASH_ENV naming this file, so each bash process a unit starts
# reads it before its first command. It has no #! line and is not executable: part 0720
# judges executables by shebang, and part 1510 wants the scrub block in every one, which
# a BASH_ENV file must not run. Nothing here is loaded in an untraced run.
#
# It writes one file a process, $FELIX_TEST_TRACE_AT/<pid>.trace, where FELIX_TEST_TRACE_AT
# is the unit's own directory below FELIX_TEST_TRACE_DIR, pinned by the first process of the
# unit and exported, so what a process records after it sets FELIX_TEST_UNIT itself, or what
# the units of a -j run started inside the unit record, lands in the unit's directory (B12).
# A pin that is not below this FELIX_TEST_TRACE_DIR is another run's and is not trusted.
# Lines, tab separated, each beginning with a lowercase letter (B20):
#   fn  PATH NAME   a function entered, and the file it was defined in
#   top PATH        a file whose top level ran
#   cmd PATH TEXT   a command that might leave the tracer behind (B13), for compile to read
#   ps  PATH        a command that reads PIPESTATUS right after a pipeline (B14, bash 3.2 to 4.0)
# Under bash 4.1 and later it is xtrace on a descriptor above 9, and a line is
#   x...<TAB>PATH<TAB>FUNCNAME[0]<TAB>the command
# (the first character is repeated for each level of indirection): compile reads both.
#
# Under bash 3.2 to 4.0 it is a DEBUG trap under functrace, with xtrace off. bash 3.2 resets
# PIPESTATUS after every DEBUG trap, so the handler reads the length of PIPESTATUS before
# anything else and restores $_ last; $? is restored by bash itself, and the handler ends with
# a command that succeeds, so extdebug skips nothing and set -e stops nothing. A file sourced
# by a relative path is named by where it was when sourced (BASH_FT_rel).
# Every variable it keeps begins BASH, which part mode's shell comparison (part 0007) leaves
# alone; every function begins _tm_trace_, a name tests/select.sh does not use. Nothing it
# writes reaches stdout or stderr, and it opens no descriptor from 0 to 9.
_tm_trace_abs() {   # BASH_FT_s -> the absolute path it names, when that can be known
  local t
  if [[ $BASH_FT_rel == *"|$BASH_FT_s="* ]]; then
    t=${BASH_FT_rel#*"|$BASH_FT_s="}; BASH_FT_s=${t%%|*}
  elif [[ -f $PWD/$BASH_FT_s ]]; then BASH_FT_s=$PWD/$BASH_FT_s
  fi
  return 0
}
# KIND PATH [NAME]: once a process, one line in the process's file. A key's record is looked
# for in a variable of its own length, so the lookup scans a hundredth of what was written.
_tm_trace_rec() {
  local k v
  BASH_FT_s=$2
  case $2 in /*) ;; *) _tm_trace_abs ;; esac
  k="$1 $BASH_FT_s ${3-}"; v=BASH_FT_t${#k}
  [[ ${!v-} == *"|$k|"* ]] && return 0
  printf -v "$v" '%s' "${!v-}|$k|"
  case $1 in
    top) printf 'top\t%s\n' "$BASH_FT_s" ;;
    fn)  printf 'fn\t%s\t%s\n' "$BASH_FT_s" "$3" ;;
    ps)  printf 'ps\t%s\n' "$BASH_FT_s" ;;
    cmd) printf 'cmd\t%s\t%s\n' "$BASH_FT_s" "$3" ;;
  esac 2>/dev/null >> "$BASH_FT_f"
  return 0
}
# A new context, one level above the handler: a function entered or a file's top level. The
# bottom frame, main, is top level, and a function of that name is not (it has a frame under it).
_tm_trace_new() {
  local s="${BASH_SOURCE[2]-}" c="${FUNCNAME[2]-}"
  BASH_FT_last=$BASH_FT_k
  [[ -n $s ]] || return 0
  case $c in
    ""|source) _tm_trace_rec top "$s" ;;
    main) if [[ -z ${FUNCNAME[3]+x} ]]; then _tm_trace_rec top "$s"; else _tm_trace_rec fn "$s" main; fi ;;
    *) _tm_trace_rec fn "$s" "$c" ;;
  esac
  return 0
}
# A command that mentions what compile reads for B13 and B14. BASH_FT_n is the length of PIPESTATUS.
# Only its first 400 characters are kept and read: bash 3.2 takes minutes over ${c//$'\n'/ } on a
# command of tens of kilobytes (an assignment of an awk program), and what leaves the tracer behind
# is in a command's first words.
_tm_trace_cmd() {
  local c="${BASH_COMMAND:0:400}" s="${BASH_SOURCE[2]-}" a
  case $c in
    .\ *|source\ *)
      a=${c#* }; a=${a#"${a%%[! ]*}"}
      case $a in \"*) a=${a#\"}; a=${a%%\"*} ;; \'*) a=${a#\'}; a=${a%%\'*} ;; *) a=${a%% *} ;; esac
      case $a in /*|*\$*|*\`*|"") ;; */*) [[ ! -f $PWD/$a ]] || BASH_FT_rel="$BASH_FT_rel$a=$PWD/$a|" ;; esac
      return 0 ;;
  esac
  if [[ $BASH_COMMAND == *PIPESTATUS* ]]; then
    [[ $BASH_FT_n -lt 2 ]] || _tm_trace_rec ps "$s"
    return 0
  fi
  c=${c//$'\t'/ }; c=${c//$'\n'/ }; c=${c//$'\r'/ }
  _tm_trace_rec cmd "$s" "$c"
  return 0
}
_tm_trace_dbg() {
  BASH_FT_n=${#PIPESTATUS[@]}; BASH_FT_u=${1-}
  case $BASH_COMMAND in
    *PIPESTATUS*|*BASH_ENV*|env\ *|*\ env\ *|*/env\ *|exec\ *|*\ exec\ *|trap\ *DEBUG*|*\ trap\ *DEBUG*|set\ *+*|*\ set\ *+*|.\ *|source\ *) _tm_trace_cmd ;;
  esac
  BASH_FT_k=${BASH_SOURCE[1]-}\|${FUNCNAME[1]-}\|${FUNCNAME[2]+f}
  [[ $BASH_FT_k == "$BASH_FT_last" ]] || _tm_trace_new
  : "$BASH_FT_u"
}

if [ -n "${FELIX_TEST_TRACE_DIR-}" ] && [ -z "${BASH_FT_f-}" ] && [ -n "${BASH_VERSINFO-}" ]; then
  case "${FELIX_TEST_TRACE_AT-}" in "$FELIX_TEST_TRACE_DIR"/?*) ;; *) FELIX_TEST_TRACE_AT="" ;; esac
  if [ -z "$FELIX_TEST_TRACE_AT" ] && [ -n "${FELIX_TEST_UNIT-}" ]; then
    FELIX_TEST_TRACE_AT="$FELIX_TEST_TRACE_DIR/$FELIX_TEST_UNIT"; export FELIX_TEST_TRACE_AT
  fi
  if [ -n "$FELIX_TEST_TRACE_AT" ]; then
    BASH_FT_f="$FELIX_TEST_TRACE_AT/$$.trace"; BASH_FT_rel="|"; BASH_FT_last=""; BASH_FT_n=1; BASH_FT_u=""; BASH_FT_k=""; BASH_FT_s=""
    if [ "${BASH_VERSINFO[0]}" -lt 4 ] || { [ "${BASH_VERSINFO[0]}" -eq 4 ] && [ "${BASH_VERSINFO[1]}" -eq 0 ]; }; then
      set -T
      trap '_tm_trace_dbg "$_"' DEBUG
    elif : >> "$BASH_FT_f" 2>/dev/null; then
      eval 'exec {BASH_FT_x}>>"$BASH_FT_f"' 2>/dev/null && BASH_XTRACEFD=$BASH_FT_x && PS4=$'x\t${BASH_SOURCE[0]-}\t${FUNCNAME[0]-}\t' && set -x
    fi
  fi
fi
