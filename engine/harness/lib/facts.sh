# The fact log: what a probe saw, kept, and read back.
#
# Split out of probes.sh when that file reached the 500-line limit, and the
# split is along the real seam rather than at a convenient line. probes.sh asks
# reality a question and computes a state. This file is everything that happens
# to the answer afterwards: what class of knowledge it is, how it is written
# down, and what can be said by holding two of them side by side.
#
# A log nothing reads is `procedures.tsv` one level down — a surface that
# accumulates rows forever while nothing ever consults them — so the reader
# lives here beside the writer, and neither ships without the other.

# Sourced rather than assumed. felix_mem_dir and felix_has_line come from
# resolve.sh, and a lib whose helper is missing does not error — it returns
# empty, which reads as "nothing to report" and is always the permissive
# direction.
if ! command -v felix_mem_dir >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh"
fi

# The epistemic class of a state, in v3.2's vocabulary. A probe can only ever
# produce two of the four: it observes, or it fails to. It never declares and
# never infers, and writing either into this log would be the fabrication the
# header refuses.
felix_probe_class() {
  case "${1:-}" in
    found|empty)     printf 'OBSERVED' ;;
    unknown|blind)   printf 'UNKNOWN' ;;
    *)               printf 'n/a' ;;
  esac
}

# Where a run was taken, as fields 10 to 12 of its rows (audit b19, C056): the
# HEAD of the checkout (40 hex digits), an identity for the checkout itself, and
# whether its working tree was clean. Each is - when it could not be read: no
# commit, no checkout, or git that would not answer.
#
# The identity is the checkout's git directory, which differs between a
# repository and its linked worktrees and between two clones, and is the same
# for every call in one of them. It is read through git, so two spellings of one
# path agree; a tab or a newline in it, which would split the row, is a space.
_felix_probes_identity() {
  local id
  id="$(git -C "$1" rev-parse --absolute-git-dir 2>/dev/null)" || id=""
  printf '%s' "$id" | LC_ALL=C tr '\t\n\r' '   '
}

_felix_probes_provenance() {
  local root="$1" head id st
  head="$(git -C "$root" rev-parse --verify -q HEAD 2>/dev/null)" || head=""
  case "$head" in *[!0123456789abcdef]*) head="" ;; esac
  [ "${#head}" -eq 40 ] || head=""
  id="$(_felix_probes_identity "$root")"
  # Untracked files count and ignored ones do not, whatever the user's config says.
  if st="$(git --no-optional-locks -C "$root" status --porcelain --untracked-files=normal 2>/dev/null)"; then
    if [ -z "$st" ]; then st=clean; else st=dirty; fi
  else
    st=""
  fi
  printf '%s\t%s\t%s' "${head:--}" "${id:--}" "${st:--}"
}

# The stamp and tree of the last run in LOG that can stand in for the checkout
# at ROOT, whose git directory is IDENT, when its tree is not TID (see
# felix_probes_drift); nothing when there is none. One git and one awk however
# many runs the log holds: the ancestors of HEAD are read first, from stdin, then
# the log. Non-zero when either could not complete.
_felix_probes_baseline() {
  git -C "$3" rev-list HEAD 2>/dev/null | LC_ALL=C awk -F'\t' -v t="$2" -v id="$4" '
    FNR == NR { anc[$1] = 1; next }
    NF >= 12 && $2 != "" && $2 != t && length($10) == 40 && $10 !~ /[^0123456789abcdef]/ && ($10 in anc) \
      && ($12 == "clean" || ($11 != "" && $11 == id)) { k = $1 "\t" $2 }
    END { if (k != "") print k }' - "$1"
  set -- "${PIPESTATUS[@]}"
  [ "${1:-1}" -eq 0 ] && [ "${2:-1}" -eq 0 ]
}

# Append the run to the project's fact log, with provenance.
#
# Append-only and never rewritten. A log a command can rewrite is a log that
# can be made to agree with whatever ran last, and the whole point of keeping
# facts over time is to be able to see one change.
#
# Provenance is what a later reader needs in order to decide whether this fact
# still means anything: when it was taken, which tree it was taken from, what
# state was computed, which INSTRUMENT answered, and the exact command that
# produced it. v3.2 §2 asks for freshness and dependencies as well; the tree id
# is what this increment can honestly supply for both, and saying so is better
# than a column holding a guess.
#
# Columns 10 to 12 (HEAD, checkout identity, clean or dirty) were appended the
# same way, so a row without them is simply not placed on any history.
#
# The instrument column was APPENDED rather than inserted, and that is the whole
# reason it is column nine rather than eight. This log is append-only, so rows
# written before instruments were identified are still in it and always will be
# — and inserting a column would have made every one of those read its probe
# command as its instrument, so the first run after the change reported that
# every single predicate had changed instrument. Reproduced, not reasoned:
# inserting it printed `git ls-files -> git@3662256` for a tool nobody touched.
# Appended, an old row simply has no ninth field, the comparison is skipped,
# and the log says nothing rather than something false.
#
# It grows, and by design. The gate calls this on every run, so the file gains
# one line per row per gate — a few hundred lines a week on a project worked on
# daily. Nothing rotates it, and nothing should yet: the whole value of an
# append-only record is that the old rows are still there, and a rotation
# written before anybody has read a year of it would be deciding what to forget
# before knowing what was worth keeping. When it needs bounding it belongs in
# maintenance.tsv, which is where this project already puts upkeep with a
# cadence.
#
# Returns non-zero when the append did not happen. That is issue #84's shape
# exactly — `felix budget --record` reported success when its append failed and
# the ceiling silently became no ceiling — and a fact log that can lose a row
# while reporting a clean run is worse than no log, because it is trusted.
felix_probes_record() {
  local proj="$1" root="$2" tid="${3:-}" rows="$4"
  local dir log stamp line pred grounds state count detail probe source before row mine="" n prov
  dir="$(felix_mem_dir "$proj")"
  mkdir -p "$dir" 2>/dev/null || return 1
  log="$dir/facts.log"
  [ -f "$log" ] || : > "$log" 2>/dev/null || return 1

  stamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  [ -n "$tid" ] || tid="unknown-tree"
  prov="$(_felix_probes_provenance "$root")"
  # A byte offset, not a line count: it is where this call's rows begin, since
  # the log only grows, and it is what the confirmation below reads from.
  before="$(wc -c < "$log" 2>/dev/null | LC_ALL=C tr -dc '0-9')"; [ -n "$before" ] || before=0
  n=0

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    pred="$(printf '%s\n' "$line" | LC_ALL=C cut -f1)"
    grounds="$(printf '%s\n' "$line" | LC_ALL=C cut -f2)"
    state="$(printf '%s\n' "$line" | LC_ALL=C cut -f3)"
    count="$(printf '%s\n' "$line" | LC_ALL=C cut -f4)"
    detail="$(printf '%s\n' "$line" | LC_ALL=C cut -f5)"
    probe="$(printf '%s\n' "$line" | LC_ALL=C cut -f6)"
    source="$(printf '%s\n' "$line" | LC_ALL=C cut -f7)"
    n=$((n + 1))
    printf -v row '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
      "$stamp" "$tid" "$pred" "$(felix_probe_class "$state")" \
      "$state" "$count" "${grounds:--}" "$probe" "${source:--}" "$prov"
    # One row per append, so each lands whole beside another writer's rows.
    printf '%s\n' "$row" >> "$log" || return 1
    mine="$mine$row
"
  done <<EOF
$rows
EOF

  [ "$n" -gt 0 ] || return 0
  # Confirmed rather than trusted. `>>` on a full disk, a read-only volume or a
  # path that stopped being a file reports through an exit status this loop can
  # miss inside a subshell. A symlink to /dev/null misses it entirely: the append
  # succeeds and nothing arrives.
  #
  # So every row this call wrote must be found in the bytes appended since it
  # began, as many times as it wrote it. This used to count the file's growth
  # instead, and growth is not this call's to own: a second `felix gate` on
  # the same project, from another worktree or clone, appends to this log at
  # the same time, and its rows made a clean run of each read as a failed write.
  # Nor do the stamp and tree id identify a call. Two gates on one tree
  # in one second write the same values in both columns.
  #
  # One limit, stated because it is real: a row that another writer also wrote,
  # identical in every column, cannot be told from this call's own. Such a row
  # records the same fact at the same second on the same tree, so the log holds
  # that fact either way.
  { printf '%s\n' "$mine"; tail -c "+$((before + 1))" "$log" 2>/dev/null; } \
    | LC_ALL=C awk -v n="$n" '
        !sep { if ($0 == "") sep = 1; else want[$0]++; next }
        want[$0] > 0 { want[$0]--; got++ }
        END { exit !(got == n) }'
}

# What changed since the last tree this was asked about.
#
# The fact log exists to be read, and a log nothing reads is `procedures.tsv`
# one level down: a surface that accumulates rows forever while nothing ever
# consults them. So this is the reader, and it is the whole reason the log
# carries a tree id and a count rather than a verdict.
#
# It reports and never blocks, and that is the specification rather than
# timidity: relations produce facts, not obligations. A member disappearing can
# be somebody deleting a file on purpose, and a stop that fires on every
# ordinary deletion is one people learn to route around — which is worse than
# no stop, because it teaches them to route around the ones that matter. The
# states already block where blocking is right: a surface that could be seen
# and now cannot is `blind`, and that is not a drift, it is a refusal.
#
# What it catches that nothing else does: a count that fell. `hook_binding`
# going from eight to six is a floor that stopped running for two events, and
# no check anywhere greps for a hook that was deleted — absence has no line
# number. The predicate had eight members yesterday and has six today, and that
# sentence is only available to something holding both numbers.
#
# Compared against the last run on a DIFFERENT tree. Comparing against the last
# run of any kind would compare a tree with itself the second time anybody runs
# the command in one sitting, and report that nothing ever changes.
#
# With a fourth argument, the checkout's root, "the last run" is the last run on
# this branch's own history (audit b19, C056). The log is shared by every worktree
# and clone of the project, so the last run written was as often another
# checkout's, and untouched worktree B read worktree A's two deleted hooks as its
# own. A run stands in only when its commit is HEAD or an ancestor of it, and it
# was taken in a clean tree or in this very checkout; rows from before the
# provenance columns (fewer than twelve fields) place nothing and never qualify.
# With three arguments it is what it was.
felix_probes_drift() {
  local proj="$1" tid="$2" rows="$3"
  local log key when tree line pred state count source was seen_now="" hc
  # No tree id is not "no drift". It is a run that cannot be placed against
  # any other, and a reader that fell silent here rendered exactly like a tree
  # that had not moved — the one shape this file's own header refuses.
  if [ -z "$tid" ]; then
    printf -- '-\t-\t-\tthis run has no tree id, so nothing was compared against the last tree\n'
    return 0
  fi
  log="$(felix_mem_dir "$proj")/facts.log"
  if [ "$#" -ge 4 ]; then
    hc="$(git -C "$4" rev-parse --verify -q HEAD 2>/dev/null)" || hc=""
    if [ -z "$hc" ]; then
      printf -- '-\t-\t-\tthis checkout has no commit to place the run on, so nothing was compared\n'
      return 0
    fi
    key=""
    if [ -f "$log" ]; then
      key="$(_felix_probes_baseline "$log" "$tid" "$4" "$(_felix_probes_identity "$4")")" \
        || { printf -- '-\t-\t-\tthis branch'"'"'s history could not be read, so nothing was compared\n'; return 0; }
    fi
    if [ -z "$key" ]; then
      printf -- '-\t-\t-\tno earlier run on another tree in this branch'"'"'s history is recorded, so nothing was compared\n'
      return 0
    fi
  else
    [ -f "$log" ] || return 0
    # One run is one timestamp and one tree together. The timestamp alone would
    # merge two runs that happened inside the same second on different trees,
    # which is not hypothetical: a gate and a merge check can land together.
    key="$(awk -F'\t' -v t="$tid" '$2 != "" && $2 != t { k = $1 "\t" $2 } END { if (k != "") print k }' "$log")"
    [ -n "$key" ] || return 0
  fi
  when="$(printf '%s' "$key" | cut -f1)"
  tree="$(printf '%s' "$key" | cut -f2)"

  # Iterated in table order rather than with awk's `for (p in array)`, whose
  # order is unspecified — a report whose lines move between runs cannot be
  # diffed, and being diffable is the entire point of a log.
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    pred="$(printf '%s\n' "$line" | cut -f1)"
    state="$(printf '%s\n' "$line" | cut -f3)"
    count="$(printf '%s\n' "$line" | cut -f4)"
    source="$(printf '%s\n' "$line" | cut -f7)"
    seen_now="$seen_now
$pred"
    was="$(awk -F'\t' -v w="$when" -v tr="$tree" -v p="$pred" \
             '$1 == w && $2 == tr && $3 == p { print $5 "\t" $6 "\t" (NF >= 9 ? $9 : "-") }' \
             "$log" | head -1)"
    if [ -z "$was" ]; then
      printf '%s\t-\t%s\tnothing had been recorded for this predicate\n' "$pred" "$state"
      continue
    fi
    local wstate wcount wsource
    wstate="$(printf '%s' "$was" | cut -f1)"
    wcount="$(printf '%s' "$was" | cut -f2)"
    wsource="$(printf '%s' "$was" | cut -f3)"

    # The instrument, before anything about the numbers. A count that moved
    # because the tool was replaced is a different fact from one that moved
    # because the project did, and reporting the second when it was the first
    # sends somebody looking for a route that was never added. Said first
    # because it is the explanation for whatever follows it.
    if [ -n "$wsource" ] && [ "$wsource" != "-" ] && [ -n "$source" ] \
         && [ "$source" != "-" ] && [ "$wsource" != "$source" ]; then
      printf '%s\t%s\t%s\tthe instrument changed, so any count below it may be the tool rather than the tree\n' \
        "$pred" "$wsource" "$source"
    fi
    if [ "$wstate" != "$state" ]; then
      printf '%s\t%s\t%s\tthe state changed\n' "$pred" "$wstate" "$state"
      continue
    fi
    # Both sides have to be numbers before they can be compared, and a pair
    # that is not says so. `[ a -gt b ]` on a non-number errors, the error is
    # redirected, and the false status then falls through every branch — so a
    # count nothing could read renders exactly like a count that did not move.
    # That is this whole file's failure class appearing inside its own reader.
    case "${wcount}${count}" in
      *[!0123456789]*|'')
        printf '%s\t%s\t%s\tone of these counts is not a number, so nothing was compared\n' \
          "$pred" "${wcount:-?}" "${count:-?}"
        continue ;;
    esac
    if [ "$wcount" -gt "$count" ]; then
      printf '%s\t%s members\t%s members\t%s fewer than on the last tree\n' \
        "$pred" "$wcount" "$count" "$((wcount - count))"
    elif [ "$wcount" -lt "$count" ]; then
      printf '%s\t%s members\t%s members\t%s more than on the last tree\n' \
        "$pred" "$wcount" "$count" "$((count - wcount))"
    fi
  done <<EOF
$rows
EOF

  # The other direction: a predicate this project was reading and no row reads
  # now. Reported rather than blocked, because the table it was removed from is
  # in the escape set and shrinking it already stops a merge for a person to
  # look at. A second stop here would be one that can be waited out — the log
  # only remembers the last run, so running the command twice would clear it.
  awk -F'\t' -v w="$when" -v tr="$tree" '$1 == w && $2 == tr { print $3 "\t" $5 }' "$log" \
    | while IFS= read -r line; do
        [ -n "$line" ] || continue
        pred="$(printf '%s\n' "$line" | cut -f1)"
        felix_has_line "$seen_now" "$pred" && continue
        printf '%s\t%s\tnot read\tthis was being read here and no row reads it now\n' \
          "$pred" "$(printf '%s\n' "$line" | cut -f2)"
      done
  return 0
}

# What the gate shows under its probes counts (audit b19, C089 and C056), passed
# from felix probes in a file the gate names (FELIX_PROBES_NOTES) so that it need
# not read them off the report's columns, which a long name pushes out of place.
# One line per drift row, d <TAB> predicate <TAB> was <TAB> now <TAB> detail, and
# one g line: the surfaces nothing probes, joined, or ? when that was not known.
# Arguments: FILE, the drift rows, whether the gap list was unread (0 or 1), the
# gaps one to a line.
felix_probes_notes_write() {
  {
    printf '%s\n' "$2" | LC_ALL=C awk -F'\t' 'NF >= 4 { print "d\t" $1 "\t" $2 "\t" $3 "\t" $4 }'
    if [ "$3" -eq 1 ]; then
      printf 'g\t?\n'
    elif [ -n "$4" ]; then
      printf '%s\n' "$4" | LC_ALL=C awk 'NF { s = s (s == "" ? "" : ", ") $0 } END { print "g\t" s }'
    fi
  } > "$1" 2>/dev/null
}

# The lines themselves, in the counts line's 21-space indent: at most ten drift
# rows, then how many more there were, then the surfaces nothing probes. Printed
# only when the probes step passed (STATUS 0, the default), since a failed one
# prints its own report and ends on its own verdict. The file is removed either
# way, and nothing is said when there is no file.
felix_probes_notes_print() {
  [ -n "${1:-}" ] || return 0
  [ "${2:-0}" -eq 0 ] || { rm -f "$1"; return 0; }
  LC_ALL=C awk -F'\t' -v ind='                     ' '
    function trim(x) { sub(/^ +/, "", x); sub(/ +$/, "", x); return x }
    $1 == "d" { n++
      if (n <= 10) {
        if ($2 == "-") print ind "not compared with an earlier tree: " $5
        else print ind "changed since the last tree: " $2 " " trim($3) " -> " trim($4) ", " $5
      } }
    $1 == "g" { g = $2 }
    END {
      if (n > 10) print ind "changed since the last tree: and " (n - 10) " more; felix probes lists them"
      if (g == "?") print ind "surfaces nothing probes: not known: the capabilities this project declares could not be read"
      else if (g != "") print ind "surfaces nothing probes: " g
    }' "$1" 2>/dev/null
  rm -f "$1"
  return 0
}

# The changed-since-the-last-tree section of felix probes, from the drift rows
# (felix_probes_drift): what moved, and why it is read rather than enforced.
felix_probes_drift_print() {
  printf '\nchanged since the last tree\n\n'
  printf '%s\n' "$1" | while IFS= read -r line; do
    [ -n "$line" ] || continue
    printf '  %-22s %-14s -> %-14s %s\n' \
      "$(printf '%s\n' "$line" | cut -f1)" \
      "$(printf '%s\n' "$line" | cut -f2)" \
      "$(printf '%s\n' "$line" | cut -f3)" \
      "$(printf '%s\n' "$line" | cut -f4)"
  done
  printf '\nRead rather than enforced, and that is the specification rather than\n'
  printf 'timidity: relations produce facts, not obligations. A member that went\n'
  printf 'away can be somebody deleting a file on purpose. What nothing else can\n'
  printf 'say is that there used to be more of them — nothing greps for a hook\n'
  printf 'that was deleted, because absence has no line number.\n'
}
