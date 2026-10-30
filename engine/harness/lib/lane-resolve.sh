# The lane's own resolution of the project a directory is bound to (design section 11 item 46; C2's bullet "The lane's
# resolution" in docs/2026-10-29-lane-slice-0-plan.md).
#
# WHY IT EXISTS. felix_resolve_project, _felix_resolve_remote and felix_binding_broken (lib/resolve.sh) and resolve_or_die
# (felix) are run by felix merge and felix land (resolve_or_die; lib/green-install.sh and lib/status-land.sh), so the lane
# exclusions of the plan's Global Constraints keep them byte for byte as main has them, and the lane cannot change them. They
# answer a read that did not finish as they answer a miss: a fork that fails in one of their substitutions leaves an empty
# name, an empty origin or an empty remote_match, and the directory reads as one no project governs, status 1. Here the lane
# checks the miss itself, and says the resolution did not finish where it did not; every other surface still reads such a
# resolution as no project, a limit of the shared resolver whose change lies outside the lane.
#
# felix_lane_resolve START HOME  Prints the project directory felix_resolve_project prints for START under HOME, returns 0.
#                                Returns 1 for a miss that stands, and 2 when the resolution did not finish: its process
#                                ended with a status other than 0 and 1, or it returned 0 and printed nothing, or the check
#                                of its miss did not finish, or found a binding. Any other status of a caller's substitution
#                                (128 for a fork that failed, 137 for a signal) is a resolution that did not finish too.
# felix_lane_miss                resolve_or_die's sentence for a miss that stands, and exit 2: felix lane's, below.
#
# WHAT THE CHECK DOES. Only on a miss: it makes every read the miss stands on again, each ending in a sentinel line as
# felix_capture does (lib/detect.sh), so a substitution that ended early reads as a check that did not finish, never as an
# empty answer: the repository root of START (felix_repo_root); the .felix marker; the origin remote's URL in that root; each
# project.json's remote_match (felix_json_str). It then binds as felix_resolve_project binds, through the unchanged helpers
# _felix_name_ok, _felix_lc, _felix_remote_slug and _felix_remote_match: a marker that is a file decides alone, and binds when
# it names an existing project directory; a marker that exists and cannot be opened names nothing; else the one longest
# remote_match that names the origin binds, and none does on a tie. The miss stands only when every read finished and none
# binds. A binding found means the resolver's miss was a read that did not finish.
# WHAT IT DOES NOT SEE. The GitHub slug read that _felix_remote_slug makes for an owner/repo remote_match (it sources
# lib/own.sh: no lane file calls into it), which is read through that function as the resolver reads it, and a resolver that
# returned 0 with a project a failed read left shorter than it should have been. Both are stated limits (C2).
# It runs in a subshell with its stderr off, so a fork that fails or a signal that ends a read, and bash's note of it, leave
# nothing on the surface's stderr; the surface says what it found. Bash 3.2; LC_ALL=C on every text tool.

_LANE_RLIB="${BASH_SOURCE[0]:-$0}"
case "$_LANE_RLIB" in */*) _LANE_RLIB="${_LANE_RLIB%/*}" ;; *) _LANE_RLIB=. ;; esac

# The reads of the check, each run by felix_capture and returning 0 whenever the read itself finished, whatever it found.
_lane_marker() { [ -r "$1" ] || return 0; LC_ALL=C tr -d '[:space:]' 2>/dev/null < "$1"; }   # FILE: a marker that cannot be opened names nothing
_lane_origin() { cd "$1" || return 0; git remote get-url origin 2>/dev/null; return 0; }      # ROOT: no origin, or no repository, is no URL
_lane_remote_match() { felix_json_str "$1" remote_match; return 0; }                          # PROJECT.JSON: a path that is no file reads as no field

# START HOME -> 0 when every read finished and none binds START, else 1: a binding found, or a read that did not finish.
_lane_bind() {
  local start="$1" home="$2" root name url ul meta m m2 n best=0 sdone=0 best_p="" tie="" LC_ALL=C
  felix_capture root felix_repo_root "$start" && [ -n "$root" ] || return 1
  if [ -f "$root/.felix" ]; then
    felix_capture name _lane_marker "$root/.felix" || return 1
    ! { _felix_name_ok "$name" && [ -d "$home/projects/$name" ]; }
    return
  fi
  felix_capture url _lane_origin "$root" || return 1
  [ -n "$url" ] || return 0
  _felix_lc "$url"; ul="$_FELIX_LC"
  for meta in "$home"/projects/*/project.json; do
    [ -e "$meta" ] || continue
    felix_capture m _lane_remote_match "$meta" || return 1
    [ -n "$m" ] || continue
    m2="${m%/}"; _felix_lc "${m2%.git}"; case "$ul" in *"$_FELIX_LC"*) ;; *) continue ;; esac
    [ "$sdone" = 1 ] || { sdone=1; _felix_remote_slug "$url"; }
    _felix_remote_match "$m" "$url" "$_FELIX_RS" || continue
    n="${meta%/project.json}"; n="${n##*/}"
    if [ "$_FELIX_RM_LEN" -gt "$best" ]; then best="$_FELIX_RM_LEN"; best_p="$n"; tie=""
    elif [ "$_FELIX_RM_LEN" -eq "$best" ]; then tie="${tie:-$best_p} $n"; fi
  done
  [ -z "$best_p" ] || [ -n "$tie" ]
}

_lane_resolve() {   # START HOME
  local out rc
  out="$(felix_resolve_project "$1" "$2")"; rc=$?
  case "$rc" in
    0) [ -n "$out" ] || return 2; printf '%s' "$out"; return 0 ;;
    1) ;;
    *) return 2 ;;
  esac
  [ "$(type -t felix_capture)" = function ] || . "$_LANE_RLIB/detect.sh"
  _lane_bind "$1" "$2" && return 1
  return 2
}

felix_lane_resolve() {   # START HOME
  ( exec 2>/dev/null; _lane_resolve "${1:-}" "${2:-}" )
}

# felix_lane_miss  A miss that stands, said by resolve_or_die as main has it: no project governs the directory, or the binding
# that is broken, and exit 2. The resolver it runs lets the shell's own note of a marker it cannot open (and sed's of a
# project.json it cannot read) reach stderr ahead of that sentence, so felix lane (C5) runs it with stderr taken and says
# its sentence from the first line that starts "felix: ". A resolve_or_die that found a project this time, or ended some
# other way, found a binding after two misses: the resolution did not finish.
felix_lane_miss() {
  local msg rc=0 nl=$'\n'
  msg="$(resolve_or_die 2>&1)" || rc=$?
  [ "$rc" -eq 2 ] && [ -n "$msg" ] || die "the project that governs $PWD could not be resolved: a read it stands on did not finish." 2
  case "$msg" in "felix: "*) ;; *"${nl}felix: "*) msg="felix: ${msg#*"${nl}felix: "}" ;; esac
  printf '%s\n' "$msg" >&2
  exit 2
}
