# The lane's own resolution of the project a directory is bound to (design section 11 items 46 and 47; C2's bullet "The lane's
# resolution" in docs/2026-10-29-lane-slice-0-plan.md).
#
# WHY IT EXISTS. felix_resolve_project, _felix_resolve_remote and felix_binding_broken (lib/resolve.sh) and resolve_or_die
# (felix) are run by felix merge and felix land (resolve_or_die; lib/green-install.sh and lib/status-land.sh), so the lane
# exclusions of the plan's Global Constraints keep them byte for byte as main has them, and the lane cannot change them. They
# answer a read that did not finish as they answer an empty one: a fork that fails in one of their substitutions leaves an
# empty name, an empty origin or an empty remote_match, so the directory reads as one no project governs, status 1, or a
# remote_match left out of the comparison lets a shorter one bind, status 0 with a project. Here the lane checks the answer
# itself, a found project as it checks a miss, and says the resolution did not finish where it did not; every other surface
# still reads such a resolution as the resolver gives it, a limit of the shared resolver whose change lies outside the lane.
#
# felix_lane_resolve START HOME  Prints the project directory felix_resolve_project prints for START under HOME, returns 0.
#                                Returns 1 for a miss that stands, printing nothing, or, when the repository root's .felix is a
#                                file that cannot be opened, that root (felix_lane_miss says so; every other caller reads a
#                                stdout with a status other than 0 as nothing). Returns 2 when the resolution did not finish:
#                                its process ended with a status other than 0 and 1, or it returned 0 and printed nothing, or
#                                the check did not finish, or it binds where the resolver found nothing, or binds nothing or
#                                another project where the resolver found one. Any other status of a caller's substitution
#                                (128 for a fork that failed, 137 for a signal) is a resolution that did not finish too.
# felix_lane_miss [ROOT]         The sentence for a miss that stands, and exit 2: felix lane's, below.
#
# WHAT THE CHECK DOES. It makes every read the answer stands on again, each ending in a sentinel line as felix_capture does
# (lib/detect.sh), so a substitution that ended early reads as a check that did not finish, never as an empty answer: the
# repository root of START (felix_repo_root); the .felix marker; the origin remote's URL in that root; each project.json's
# remote_match, by a sed of its own and no pipe (felix_json_str's pipe ends in head, so its status is head's, and a sed that
# cannot run reads as a read that found no field). It then binds as felix_resolve_project binds, through the unchanged helpers
# _felix_name_ok, _felix_lc, _felix_remote_slug and _felix_remote_match: a marker that is a file decides alone, and binds when
# it names an existing project directory; a marker that exists and cannot be opened names nothing; else the one longest
# remote_match that names the origin binds, and none does on a tie. A miss stands only when every read finished and none binds.
# A project stands only when every read finished and the binding is that same project directory.
# WHAT IT DOES NOT SEE. The GitHub slug read that _felix_remote_slug makes for an owner/repo remote_match (it sources
# lib/own.sh: no lane file calls into it), which is read through that function as the resolver reads it, so a fault in it
# changes both bindings alike. That is a stated limit (C2).
# It runs in a subshell with its stderr off, so a fork that fails or a signal that ends a read, and bash's note of it, leave
# nothing on the surface's stderr; the surface says what it found. Bash 3.2; LC_ALL=C on every text tool.

_LANE_RLIB="${BASH_SOURCE[0]:-$0}"
case "$_LANE_RLIB" in */*) _LANE_RLIB="${_LANE_RLIB%/*}" ;; *) _LANE_RLIB=. ;; esac

# The reads of the check, each run by felix_capture and returning 0 whenever the read itself finished, whatever it found.
_lane_marker() { [ -r "$1" ] || return 0; LC_ALL=C tr -d '[:space:]' 2>/dev/null < "$1"; }   # FILE: a marker that cannot be opened names nothing
_lane_origin() { cd "$1" || return 0; git remote get-url origin 2>/dev/null; return 0; }      # ROOT: no origin, or no repository, is no URL
# PROJECT.JSON: felix_json_str's sed for the key remote_match, on the file and with no pipe, so its status is sed's own. A path
# that is no regular file, or cannot be opened, has no field, and that read finished. The caller takes the first line printed.
_lane_remote_match() { [ -f "$1" ] && [ -r "$1" ] || return 0; LC_ALL=C sed -n 's/.*"remote_match"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1"; }

# START HOME -> 0 when every read finished, whatever it found, and 1 when one did not. Sets _LANE_BP, the project directory the
# reads bind START to (the one felix_resolve_project prints), empty when they bind none, and _LANE_BU, the repository root when
# its .felix is a file that cannot be opened, else empty.
_lane_bind() {
  local start="$1" home="$2" root name url ul meta m m2 n best=0 sdone=0 best_p="" tie="" LC_ALL=C
  _LANE_BP=""; _LANE_BU=""
  felix_capture root felix_repo_root "$start" && [ -n "$root" ] || return 1
  if [ -f "$root/.felix" ]; then
    [ -r "$root/.felix" ] || { _LANE_BU="$root"; return 0; }
    felix_capture name _lane_marker "$root/.felix" || return 1
    if _felix_name_ok "$name" && [ -d "$home/projects/$name" ]; then _LANE_BP="$home/projects/$name"; fi
    return 0
  fi
  felix_capture url _lane_origin "$root" || return 1
  [ -n "$url" ] || return 0
  _felix_lc "$url"; ul="$_FELIX_LC"
  for meta in "$home"/projects/*/project.json; do
    [ -e "$meta" ] || continue
    felix_capture m _lane_remote_match "$meta" || return 1
    m="${m%%$'\n'*}"
    [ -n "$m" ] || continue
    m2="${m%/}"; _felix_lc "${m2%.git}"; case "$ul" in *"$_FELIX_LC"*) ;; *) continue ;; esac
    [ "$sdone" = 1 ] || { sdone=1; _felix_remote_slug "$url"; }
    _felix_remote_match "$m" "$url" "$_FELIX_RS" || continue
    n="${meta%/project.json}"; n="${n##*/}"
    if [ "$_FELIX_RM_LEN" -gt "$best" ]; then best="$_FELIX_RM_LEN"; best_p="$n"; tie=""
    elif [ "$_FELIX_RM_LEN" -eq "$best" ]; then tie="${tie:-$best_p} $n"; fi
  done
  if [ -n "$best_p" ] && [ -z "$tie" ]; then _LANE_BP="$home/projects/$best_p"; fi
  return 0
}

_lane_resolve() {   # START HOME
  local out rc
  out="$(felix_resolve_project "$1" "$2")"; rc=$?
  case "$rc" in
    0) [ -n "$out" ] || return 2 ;;
    1) ;;
    *) return 2 ;;
  esac
  [ "$(type -t felix_capture)" = function ] || . "$_LANE_RLIB/detect.sh"
  _lane_bind "$1" "$2" || return 2
  if [ "$rc" -eq 0 ]; then [ "$_LANE_BP" = "$out" ] || return 2; printf '%s' "$out"; return 0; fi
  [ -z "$_LANE_BP" ] || return 2
  printf '%s' "$_LANE_BU"
  return 1
}

felix_lane_resolve() {   # START HOME
  ( exec 2>/dev/null; _lane_resolve "${1:-}" "${2:-}" )
}

# felix_lane_miss [ROOT]  The sentence for a miss that stands, and exit 2. ROOT, which felix_lane_resolve printed, is the
# repository root whose .felix marker is a file the check could not open: the lane's own sentence, "felix: The .felix marker in
# <ROOT> cannot be read, so it does not resolve to a project." (felix_binding_broken reads such a marker as empty). Otherwise
# resolve_or_die's, as main has it: no project governs the directory, or the binding that is broken. The resolver it runs lets
# the shell's own note of a marker it cannot open (and sed's of a project.json it cannot read) reach stderr ahead of that
# sentence, so felix lane (C5) runs it with stderr taken and says its sentence from the first line that starts "felix: ". A
# resolve_or_die that found a project this time, or ended some other way, found a binding after two misses: the resolution did
# not finish.
felix_lane_miss() {
  local msg rc=0 nl=$'\n'
  [ -z "${1:-}" ] || die "The .felix marker in $1 cannot be read, so it does not resolve to a project." 2
  msg="$(resolve_or_die 2>&1)" || rc=$?
  [ "$rc" -eq 2 ] && [ -n "$msg" ] || die "the project that governs $PWD could not be resolved: a read it stands on did not finish." 2
  case "$msg" in "felix: "*) ;; *"${nl}felix: "*) msg="felix: ${msg#*"${nl}felix: "}" ;; esac
  printf '%s\n' "$msg" >&2
  exit 2
}
