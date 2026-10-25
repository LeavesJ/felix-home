# Evidence policy.
#
# The guidebook's table on p7 says what a change must prove before it counts as
# done: code needs tests, a schema change needs database tests, user-facing
# behaviour needs browser coverage, a bug fix needs a regression test that failed
# before the fix. None of it was enforced, so a comment edit and a schema
# migration were gated identically.
#
# What is checkable here is narrow and deliberately so: this diff touched X and
# did not touch Y. That is a heuristic about coverage, not proof of it. A test
# file being edited says nothing about whether the test is any good. What it does
# catch is the common and consequential case, changing behaviour and shipping no
# test at all, which is the failure the table exists to prevent.
#
# Reports by default and exits 0. `--strict` exits non-zero so CI can gate on it.
# Defaulting to hard failure would have blocked legitimate work on day one, and
# a gate that has to be routinely bypassed teaches people to bypass gates.
#
# evidence.tsv rows: name <TAB> when-regex <TAB> requires-regex <TAB> reason
#
# A row this cannot judge is `unknown`, never n/a and never a pass: a cell grep
# cannot compile, a row that is not four non-empty cells, a table that exists
# and cannot be read. n/a is a claim about the diff, and a row that was never
# read cannot make it. (Audit b11: a `when` of `^(src|lib/` read n/a for every
# change under src/, and the merge threw grep's complaint away.) The reason of
# every such line says `not judged`, which is how a caller tells it from the two
# whole-scan unknowns below, whose reason says `no rule was consulted` and whose
# line, for a base name that holds a newline, is not even one line.

# felix_changed_paths lives in resolve.sh, which every hook and the CLI source
# first. Sourced here too rather than assumed: a lib whose helper is missing
# returns an empty path list, which reads as "nothing changed" and silently
# stops enforcing. That is the same shape as a test that is green because it
# cannot reach the branch it names, and it cost 15 assertions to notice.
if ! command -v felix_changed_paths >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh"
fi

# Every row of PROJ's evidence.tsv as five lines, so no cell is split by a read
# that collapses empty ones: `ok`, name, when, requires, reason for four
# non-empty cells set apart by tabs; `bad`, name, why, -, - for any other row.
# A row with no first cell is named evidence.tsv:N, N its line in the file with
# comments and blank lines counted.
_felix_evidence_rows() {
  LC_ALL=C awk -F'\t' '
    /^[ \t\r]*#/ || /^[ \t\r]*$/ { next }
    NF == 4 && $1 != "" && $2 != "" && $3 != "" && $4 != "" { print "ok"; print $1; print $2; print $3; print $4; next }
    { print "bad"; print ($1 != "" ? $1 : "evidence.tsv:" NR)
      print "this row is not four non-empty cells set apart by tabs (it has " NF "), so its cells were not judged"
      print "-"; print "-" }
  ' "$1/evidence.tsv"
}

# 0 when some path of the list PATHS matches PATTERN, 1 when none does, 2 when
# grep could not read the pattern. A here-string and not a pipe, because grep -q
# quits at the first match and pipefail reads the printf it cut off as none.
_felix_any_match() {
  local rc
  [ -n "$1" ] || return 1
  LC_ALL=C grep -qE -e "$2" <<<"$1"; rc=$?
  [ "$rc" -le 1 ] && return "$rc"
  return 2
}

# Whether grep can read CELL as a pattern: an exit above 1 is a pattern it
# cannot, and its own complaint is printed, a line, for the reason of the row.
_felix_evidence_cell() {
  local out rc
  out="$(LC_ALL=C grep -E -e "$1" </dev/null 2>&1)"; rc=$?
  [ "$rc" -gt 1 ] || return 0
  printf 'grep exit %s: %s' "$rc" "$(printf '%s' "$out" | LC_ALL=C tr '\t\n' '  ')"
  return 1
}

# One line of a verdict: the check's `status<TAB>name<TAB>reason`, or the brief's
# `name<TAB>reason`, which says nothing of a row this change does not reach.
_felix_evidence_say() {   # MODE STATUS NAME REASON
  case "$1" in
    check) printf '%s\t%s\t%s\n' "$2" "$3" "$4" ;;
    *)     [ "$2" = "n/a" ] || printf '%s\t%s\n' "$3" "$4" ;;
  esac
}

# Every row of PROJ's table read against PATHS, in file order, one line each.
# MODE check judges met, gap or n/a; MODE brief asks only whether a row's `when`
# reaches PATHS, because there is no diff yet and so nothing to have proved. A
# row it cannot judge is unknown in both, whatever PATHS holds. No table is
# nothing to say (schemas.tsv allows it); a table that is there and cannot be
# read is one unknown line, since silence would read as "no rules declared".
_felix_evidence_judge() {   # PROJ PATHS check|brief
  local proj="$1" paths="$2" mode="$3" rows kind name when requires reason why rc status
  [ -e "$proj/evidence.tsv" ] || [ -L "$proj/evidence.tsv" ] || return 0
  if [ ! -f "$proj/evidence.tsv" ] || [ ! -r "$proj/evidence.tsv" ] || ! rows="$(_felix_evidence_rows "$proj" 2>/dev/null)"; then
    _felix_evidence_say "$mode" unknown evidence.tsv "evidence.tsv exists but cannot be read, so its rules were not judged"
    return 0
  fi
  while IFS= read -r kind && IFS= read -r name && IFS= read -r when && IFS= read -r requires && IFS= read -r reason; do
    if [ "$kind" != ok ]; then _felix_evidence_say "$mode" unknown "$name" "$when"; continue; fi
    status=unknown
    if ! why="$(_felix_evidence_cell "$when")"; then
      reason="the when cell does not compile ($why), so this row was not judged"
    elif ! why="$(_felix_evidence_cell "$requires")"; then
      reason="the requires cell does not compile ($why), so this row was not judged"
    else
      _felix_any_match "$paths" "$when"; rc=$?
      if [ "$rc" -eq 1 ]; then status="n/a"; reason="this change does not touch that surface"
      elif [ "$rc" -ne 0 ]; then reason="grep could not match the when cell (exit $rc), so this row was not judged"
      elif [ "$mode" != check ]; then status=met
      else
        _felix_any_match "$paths" "$requires"; rc=$?
        case "$rc" in
          0) status=met ;;
          1) status=gap ;;
          *) reason="grep could not match the requires cell (exit $rc), so this row was not judged" ;;
        esac
      fi
    fi
    _felix_evidence_say "$mode" "$status" "$name" "$reason"
  done <<EOF
$rows
EOF
}

# Emits: status <TAB> name <TAB> reason.  status is met | gap | n/a | unknown
felix_evidence_check() {
  local proj="$1" base="$2" root="$3"
  local paths

  # Before any row, because `n/a` is a claim about the diff — "this change does
  # not touch that surface" — and a base git cannot name produces no diff to
  # make it about. felix_changed_paths sends git's exit-128 to /dev/null, so
  # every row fell to n/a and the command signed off with "No evidence gaps."
  # #56 closed this on the merge path; this is the same emptiness read one
  # layer up, where a person reads it.
  #
  # One row, not one per rule. The rules were never consulted, so reporting
  # each of them as unknown would imply they were each considered and found
  # unanswerable. Nothing was considered.
  if [ -n "$base" ] && ! felix_base_resolves "$root" "$base"; then
    printf 'unknown\t%s\tthis base names nothing here, so no rule was consulted\n' "$base"
    return 0
  fi

  # The same one row when git could not list the change to the end (2026-10-08).
  # A list it broke off would read every rule it missed as n/a, which is the
  # claim "this change does not touch that surface" about paths never seen.
  # Named CHANGED-PATHS, as escape.sh names it, so a caller can tell it from a
  # base that names nothing, and it carries git's reason.
  if ! paths="$(felix_changed_paths "$root" "$base")"; then
    printf 'unknown\tCHANGED-PATHS\tgit could not list every path this change touches (%s), so no rule was consulted\n' \
      "$(felix_change_why "$root" "$base")"
    return 0
  fi

  _felix_evidence_judge "$proj" "$paths" check
  return 0
}
