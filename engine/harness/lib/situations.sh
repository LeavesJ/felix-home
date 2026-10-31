# felix situations: the entry, its flags, the situation table and the ids (slice 1 of the capability lane; the design is
# docs/2026-10-29-capability-lane-first-slices-design.md section 7, the contracts C1 to C16 of
# docs/2026-10-29-lane-slice-1-plan.md).
#
# WHAT IT DOES. It says which situation rows a project owes, for a recorded tree (--at) or for a change (--change): the
# rows the change brings in, blinds and retires, the rows already standing, and what could not be looked at. Report-only:
# no model, no key, no network, and nothing is written outside one scratch directory under ${TMPDIR:-/tmp}, which is
# removed before the report is printed.
#
# HOW IT IS LOADED. cmd_situations in felix sources this file and its two siblings inside its own body, the way cmd_audit,
# cmd_inventory and cmd_cost load theirs, so felix gate, felix merge and felix land never parse or run any of it. Nothing
# in these three files runs when it is sourced: they define functions and set nothing.
#
#   lib/situations.sh         this file: felix_situations (flags, project, table, scratch, the run), the table reader,
#                             the ids
#   lib/situations-read.sh    one side read: the scratch directory, and the recorded readings of facts.log
#   lib/situations-report.sh  the human report, the --tsv form, the --propose drafts
#
# THE ORDER OF A RUN (C2). Usage errors first, then the governing project, then the situation table, then the scratch
# directory, then the rest. The first check that fails is the one line printed. The status is 2 for a usage error or a
# directory no project governs, 1 for a flag with no value (need_value), and 3 for a table, a scratch directory or a side
# that could not be read, with one line on stderr and nothing on stdout.

# One usage error: the status is 2 and the first stderr line begins felix: usage: felix situations. ARG is the argument
# that failed, as given.
_felix_situations_usage() {   # ARG
  die "usage: felix situations [--at <tree> | --change [<base>..<head>]] [--tsv | --propose] (got: ${1-})" 2
}

# Status 0 when $1 is a range as C1 defines it: split at its first .., neither half empty, no ... anywhere, and no .. in
# the head half. HEAD~1..HEAD, main..HEAD and v1.2..v1.3 are ranges; main alone is not.
_felix_situations_range_ok() {   # RANGE
  local r="${1-}" b h
  case "$r" in *..*) ;; *) return 1 ;; esac
  case "$r" in *...*) return 1 ;; esac
  b="${r%%..*}"; h="${r#*..}"
  [ -n "$b" ] && [ -n "$h" ] || return 1
  case "$h" in *..*) return 1 ;; esac
  return 0
}

# The situation table (C2, C12): prints its rows verbatim, in file order, and returns 0. A row is a line that does not
# match ^[[:space:]]*(#|$) in the C locale, a last line with no newline included; its cells are split at each tab, and
# nothing is trimmed. Returns 3 with "<file>: <why>" on stderr and nothing on stdout when the file cannot be read or its
# first failing line breaks a rule, the first reason in C2's order that fits that line:
#   it is absent or unreadable | it holds no row | line N: K fields where a row has 5 | line N: cell K is empty
#   | line N: class 'C' is not [a-z][a-z0-9_]* | line N: class 'C' appears twice | line N: applies holds no term
#   | line N: class_by_maturity 'V' does not name each of ... | line N: source 'V' is not miss:, candidate: or cite: ...
# N is the physical line number, comments and blank lines counted. The rules C12 adds beyond this list are checked of the
# shipped seed by part 2400 and are not refused here: a term in another form is unbound at run time, and a cell that
# decreases with maturity is printed as written.
felix_situations_table() {   # FILE
  local f="${1-}" out rc=0
  if [ ! -f "$f" ] || [ ! -r "$f" ]; then
    printf '%s: it is absent or unreadable\n' "$f" >&2
    return 3
  fi
  out="$(LC_ALL=C awk -F'\t' '
    function fail(why) { msg = "line " NR ": " why; failed = 1; exit }
    BEGIN {
      SQ = "\047"
      split("INFO ADVISORY TASK_BLOCKING RELEASE_BLOCKING AUTHORITY_BLOCKING", cls, " ")
      for (i = 1; i <= 5; i++) CLS[cls[i]] = 1
      split("prototype internal public-beta production", mat, " ")
      for (i = 1; i <= 4; i++) MAT[mat[i]] = 1
    }
    /^[[:space:]]*(#|$)/ { next }
    {
      rows++
      if (NF != 5) fail(NF " fields where a row has 5")
      for (k = 1; k <= 5; k++) if ($k == "") fail("cell " k " is empty")
      if ($1 !~ /^[a-z][a-z0-9_]*$/) fail("class " SQ $1 SQ " is not [a-z][a-z0-9_]*")
      if ($1 in SEEN) fail("class " SQ $1 SQ " appears twice")
      SEEN[$1] = 1
      nt = split($2, tm, / +/); terms = 0
      for (i = 1; i <= nt; i++) if (tm[i] != "") terms++
      if (terms == 0) fail("applies holds no term")
      np = split($4, pr, ","); good = (np == 4); split("", got)
      for (i = 1; i <= np; i++) {
        e = index(pr[i], "=")
        if (e < 2) { good = 0; continue }
        m = substr(pr[i], 1, e - 1); c = substr(pr[i], e + 1)
        if (!(m in MAT) || (m in got) || !(c in CLS)) good = 0
        got[m] = 1
      }
      if (!good) fail("class_by_maturity " SQ $4 SQ " does not name each of prototype internal public-beta production once with a class of INFO ADVISORY TASK_BLOCKING RELEASE_BLOCKING AUTHORITY_BLOCKING")
      e = index($5, ":"); kind = substr($5, 1, e - 1); hex = substr($5, e + 1)
      good = (e > 0 && (kind == "miss" || kind == "candidate" || kind == "cite") && length(hex) == 12 && hex ~ /^[0-9a-f]+$/)
      if (!good) fail("source " SQ $5 SQ " is not miss:, candidate: or cite: and 12 lowercase hex digits")
      R[rows] = $0
    }
    END {
      if (!failed && rows == 0) { msg = "it holds no row"; failed = 1 }
      if (failed) { print msg; exit 3 }
      for (i = 1; i <= rows; i++) print R[i]
    }' "$f")" || rc=$?
  case "$rc" in
    0) printf '%s\n' "$out" ;;
    3) printf '%s: %s\n' "$f" "$out" >&2; return 3 ;;
    *) printf '%s: it is absent or unreadable\n' "$f" >&2; return 3 ;;
  esac
}

# A class's id (C6): owed: and the first 12 hex digits that git hash-object --stdin prints for the bytes
# <class><TAB><project><TAB>* with no trailing newline, run from / with no repository, global or system configuration in
# reach. The same in --at, in --change and across runs: it holds neither a commit nor a tree.
felix_situations_id() {   # CLASS PROJECT
  local h
  h="$(printf '%s\t%s\t%s' "${1-}" "${2-}" '*' \
    | env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u GIT_COMMON_DIR \
        GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git -C / hash-object --stdin 2>/dev/null)" || return 1
  [ "${#h}" -ge 12 ] || return 1
  printf 'owed:%s' "${h:0:12}"
}

# felix situations [--at <tree> | --change [<base>..<head>]] [--tsv | --propose] (C1). Arguments are read left to right,
# and one that repeats a flag, conflicts with a flag before it, or is not a flag at all fails where it is read, before its
# value is looked at; -h and --help given first never reach here, felix answers them for every command. The report itself
# is built in the sibling libraries.
felix_situations() {
  local mode="" at="" range="" fmt="" a
  while [ $# -gt 0 ]; do
    a="$1"
    case "$a" in
      --at)
        [ -z "$mode" ] || _felix_situations_usage "$a"
        need_value "$@"
        mode=at; at="$2"; shift 2 ;;
      --change)
        [ -z "$mode" ] || _felix_situations_usage "$a"
        mode=change; shift
        if [ $# -gt 0 ]; then
          case "$1" in
            -*) ;;
            *) _felix_situations_range_ok "$1" || _felix_situations_usage "$1"
               range="$1"; shift ;;
          esac
        fi ;;
      --tsv|--propose)
        [ -z "$fmt" ] || _felix_situations_usage "$a"
        fmt="${a#--}"; shift ;;
      *) _felix_situations_usage "$a" ;;
    esac
  done
  [ -n "$mode" ] || mode=at

  # Exported before the project is resolved, so that no git read of the live checkout, the resolution's included, refreshes
  # an index as a side effect (C3.4).
  export GIT_OPTIONAL_LOCKS=0
  resolve_or_die

  local tpath trows trc=0 log tree sides
  tpath="${SCRIPT_DIR}/templates/situations.tsv"
  trows="$(felix_situations_table "$tpath" 2>&1)" || trc=$?
  if [ "$trc" -ne 0 ]; then
    printf 'felix situations: the situation table could not be read: %s\n' "$trows" >&2
    return 3
  fi

  felix_situations_scratch_begin || return $?

  if [ "$mode" = change ]; then
    if [ -n "$range" ]; then
      sides="$(felix_situations_range "$(felix_repo_root "$PWD")" "$range")" || return 3
    fi
  else
    log="$(felix_mem_dir "$PROJ")/facts.log"
    tree="$at"
    if [ -z "$tree" ]; then
      if ! tree="$(felix_situations_newest_tree "$log")"; then
        printf 'felix situations: the recorded tree could not be read: %s records no tree\n' "$log" >&2
        return 3
      fi
    fi
    if ! felix_situations_read_recorded "$log" "$tree" "$_FELIX_SITUATIONS_SCRATCH/at.reading"; then
      printf 'felix situations: the recorded tree could not be read: no run is recorded for tree %s in %s\n' "$tree" "$log" >&2
      return 3
    fi
  fi

  # Slice 1's later tasks continue here: the detector at the live tree, the evaluation, the scratch readings of --change,
  # the report. Nothing is printed until they are in.
  felix_situations_scratch_end
  printf 'felix situations: the readings and the report are not built yet\n' >&2
  return 1
}
