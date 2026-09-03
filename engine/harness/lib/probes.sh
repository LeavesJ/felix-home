# Ground truth: what this checkout actually contains, asked of the thing that
# knows rather than of a table somebody wrote.
#
# The rule this file exists to obey is one level stricter than the one
# procedures.tsv obeys. There, Felix may hold stances and may never author the
# enumeration. Here:
#
#   Felix may declare which question to ask reality.
#   Felix may never author the answer.
#
# A row names a predicate and the command that enumerates its members. The
# members come back from the command. Nothing in this file can add one, and a
# row that returns nothing is never quietly treated as a row that returned
# nothing to worry about — which is the entire failure class this is for.
#
# That class stood at five instances by 2026-09-03. Three of them: a security
# audit named a missing request ceiling and the command built to answer it
# dropped the finding; a governed project WROTE the ceiling check and ended it
# with
# `exit 0`, so its scanner printed "All gates passed" while naming four
# unlimited services; a vocabulary grep reported a ceiling absent that was
# shipping and armed. Every one of those is a check that reported clean by
# finding nothing, and no amount of adding checks fixes it. What fixes it is
# refusing to let "found nothing" and "could not look" render the same.
#
# ----------------------------------------------------------------- states ---
#
# Five, and exactly one of them is a claim that nothing is there.
#
#   not-applicable   the `when` command says this probe does not apply here.
#                    No fact, no claim, silent.
#   found            the probe ran and returned members. OBSERVED.
#   empty            the probe ran, returned nothing, AND an independent
#                    witness agrees the surface is absent. OBSERVED, and
#                    still printed every time: empty is never clean.
#   blind            the probe returned nothing while the witness proves the
#                    surface EXISTS. The probe is wrong about reality. BLOCKS.
#   unknown          nothing could be established: the probe failed and no
#                    witness proves the surface either way, the row carries no
#                    witness at all so `empty` was never available to it, or a
#                    command in the probe does not exist on this machine.
#                    BLOCKS.
#
# The last one is the load-bearing one and it is deliberately expensive. A row
# with no witness can never report `empty`, because a probe with nothing to
# check it against has no way to tell an absent surface from a broken command,
# and every system that guesses there guesses "absent" — which is the
# permissive direction. Supply a witness or accept that the row blocks. That
# is also why the witness cannot be dropped to quiet a row: dropping it turns
# a green `empty` into a blocking `unknown`.
#
# `unknown` is the engine's reserved word for "nothing was scanned" and
# escape.sh already holds it under the same contract: no table may declare it
# and nothing may demote it.
#
# ---------------------------------------------------------------- residual --
#
# Stated here because this is where the system reports its own trustworthiness.
# A probe that FABRICATES members reads as `found` and nothing here can tell.
# The witness catches a probe that sees too little; nothing catches a probe
# that claims too much. Enumeration is the weakest joint of any checker, and it
# cannot be made behavioural — an entrypoint never found is never executed.
# What contains it is that rows are founder-authored, live in an enforcing
# table, and shrinking that table escapes to a person.
#
# And one level up, because the same joint exists there and the report would
# otherwise imply it does not. What says a probe is MISSING is
# felix_probes_gaps,
# whose enumeration comes from felix_detect — patterns somebody wrote. A surface
# no pattern matches produces no capability, so it produces no gap and nobody is
# ever told to probe it. This reports the probes nobody wrote for surfaces Felix
# can already name, and says nothing whatever about a surface Felix cannot name.
# That is the same joint moved one level, not a joint that was removed.

# Sourced rather than assumed, and for the reason escape.sh records at the same
# point: a lib whose helper is missing does not error, it returns empty — and an
# empty answer reads as "nothing to report", which is always the permissive
# direction. felix_has_line and felix_mem_dir come from resolve.sh, felix_detect
# and felix_declared from detect.sh, and the gap report is silently wrong
# without either.
if ! command -v felix_has_line >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh"
fi
if ! command -v felix_detect >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/detect.sh"
fi

# Rows a project has written. predicate <TAB> grounds <TAB> when <TAB> probe
# <TAB> witness
#
# Read with awk rather than `IFS=$'\t' read`, for the reason procedures.sh
# records: tab is an IFS *whitespace* character, so bash coalesces runs of it
# and strips trailing ones. `a<TAB><TAB>c` would parse as two fields and shift
# every later column left — silently, and in the direction that turns a
# witness into a probe.
#
# Five fields, and SIX is malformed rather than generously truncated. A tab
# inside a probe command splits it in two: awk would hand back a command cut
# off at the tab and read the remainder as the witness, so the row would run
# something nobody wrote and check it against something else nobody wrote. A
# row that cannot be read is not a row to read half of.
felix_probe_rows() {
  local proj="$1"
  [ -f "$proj/probes.tsv" ] || return 0
  grep -vE '^[[:space:]]*(#|$)' "$proj/probes.tsv" 2>/dev/null \
    | awk -F'\t' 'NF >= 4 && NF <= 5 { printf "%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, (NF == 5 ? $5 : "-") }'
  return 0
}

# Rows that name a predicate and then fail to say what to run. The same defect
# procedures.sh found inside its own fix: a row that records no judgement still
# looked like one, closed a gap, and rendered nowhere. Here a malformed row
# must not be able to stand in for a probe, so it is reported separately and
# counts toward nothing.
felix_probe_malformed() {
  local proj="$1"
  [ -f "$proj/probes.tsv" ] || return 0
  grep -vE '^[[:space:]]*(#|$)' "$proj/probes.tsv" 2>/dev/null \
    | awk -F'\t' 'NF < 4 || NF > 5 || $1 == "" || $4 == "" { print ($1 == "" ? "(unnamed)" : $1) }'
  return 0
}

# Run one command in the checkout being examined and say only whether it
# succeeded. Used for `when` and for the witness, both of which are yes/no.
#
# Never in the harness directory. A probe that inspects "the tree it lives in"
# instead of "the tree it was pointed at" answers about the wrong code, which
# is the mistake cmd_gate already documents at length.
#
# stdin is /dev/null, here and for the probe itself. A command that reads input
# and finds a terminal WAITS, and this runs inside a gate — so one row spelt
# `grep foo` instead of `grep foo file` would hang every gate run on the
# project forever, with no output and nothing to read. Closing stdin turns that
# into an immediate empty result, which the witness then correctly calls blind.
#
# It is not a timeout, and there is no timeout. `timeout(1)` is GNU coreutils
# and is absent from a stock macOS, so a wall-clock limit here would mean either
# a dependency the enforcing path must not have or a background-kill dance
# inside the one code path that has to be boring. A probe that genuinely loops
# still hangs the gate. That is a known limit rather than a solved problem, and
# closing stdin removes the overwhelmingly common cause of it.
_felix_probe_ask() {
  local root="$1" cmd="$2"
  [ -n "$cmd" ] && [ "$cmd" != "-" ] || return 2
  ( cd "$root" 2>/dev/null || exit 127
    bash -c "$cmd" felix-probe </dev/null >/dev/null 2>&1 )
}

# The computed state of one row, as: state <TAB> count <TAB> detail
#
# The order of questions is the design. Applicability first, because a probe
# that does not apply must never be run — running it would spend time and, for
# a row whose command only makes sense in the presence of the surface, produce
# a failure that reads as blindness. Then the probe. Then, only when the probe
# came back with nothing, the witness — which is the one question that decides
# between "there is nothing here" and "I cannot see".
felix_probe_state() {
  local root="$1" when="$2" probe="$3" witness="$4"
  local out rc n

  if [ -n "$when" ] && [ "$when" != "-" ]; then
    if ! _felix_probe_ask "$root" "$when"; then
      printf 'not-applicable\t0\tthe `when` command says this does not apply here\n'
      return 0
    fi
  fi

  out="$( cd "$root" 2>/dev/null || exit 127
          bash -c "$probe" felix-probe </dev/null 2>/dev/null )"
  rc=$?
  # Blank lines are not members. A command that prints a trailing newline and
  # nothing else has enumerated nothing, and counting it as one member is how a
  # probe passes by finding nothing while looking like it found something.
  n="$(printf '%s\n' "$out" | grep -c '[^[:space:]]')"
  [ -n "$n" ] || n=0

  if [ "$rc" -eq 0 ] && [ "$n" -gt 0 ]; then
    printf 'found\t%s\t%s member(s) enumerated\n' "$n" "$n"
    return 0
  fi

  # 127 is never evidence about the surface. bash returns it when a command in
  # the probe does not exist on this machine, which says the probe could not
  # look and says nothing at all about what is there. Deciding this before the
  # witness is consulted matters, because the obvious witness for a tool-shaped
  # probe is that same tool — `cargo metadata` witnessed by `cargo --version` —
  # and on a machine without it both fail together and agree the surface is
  # absent. Two failures with one cause are one failure.
  if [ "$rc" -eq 127 ]; then
    printf 'unknown\t0\ta command in the probe does not exist here, so nothing could be looked at\n'
    return 0
  fi

  # Members AND a failure. `ls -1 a.txt missing` prints a.txt and exits 1, and
  # that is a real shape rather than a corner — a witness in one governed
  # project's own table has exactly that form. The enumeration is partial, so
  # it cannot be `found`, and every sentence below this point would say the
  # probe returned nothing, which is false. A report
  # that states something untrue about what it saw is the failure this whole
  # file exists to refuse, so the partial case gets its own words.
  #
  # `unknown` rather than `blind`: blind means the probe saw NONE of a surface
  # the witness proves is there, and this one saw some. How much it missed is
  # exactly what nothing here can say.
  if [ "$n" -gt 0 ]; then
    printf 'unknown\t%s\tthe probe printed %s member(s) and then exited %s, so the enumeration is partial\n' \
      "$n" "$n" "$rc"
    return 0
  fi

  # Nothing came back, one way or the other. Everything from here is about
  # which kind of nothing it was, and the witness is the only thing that can
  # say. A row with none has already lost that argument.
  if [ -z "$witness" ] || [ "$witness" = "-" ]; then
    if [ "$rc" -ne 0 ]; then
      printf 'unknown\t0\tthe probe exited %s and no witness says whether the surface exists\n' "$rc"
    else
      printf 'unknown\t0\tthe probe found nothing and no witness says whether that is true\n'
    fi
    return 0
  fi

  if _felix_probe_ask "$root" "$witness"; then
    if [ "$rc" -ne 0 ]; then
      printf 'blind\t0\tthe witness proves this surface exists and the probe exited %s\n' "$rc"
    else
      printf 'blind\t0\tthe witness proves this surface exists and the probe enumerated none of it\n'
    fi
    return 0
  fi

  # The witness itself may be unaskable — an empty string reaches _felix_probe_ask
  # as a refusal rather than a verdict. Guarded above, so a non-zero here is the
  # witness genuinely reporting the surface absent.
  printf 'empty\t0\tthe probe found nothing and the witness agrees the surface is absent\n'
  return 0
}

# Every row, run. Emits:
#   predicate <TAB> grounds <TAB> state <TAB> count <TAB> detail <TAB> probe
felix_probes_run() {
  local proj="$1" root="$2" line pred grounds when probe witness st
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    pred="$(printf '%s\n' "$line" | cut -f1)"
    grounds="$(printf '%s\n' "$line" | cut -f2)"
    when="$(printf '%s\n' "$line" | cut -f3)"
    probe="$(printf '%s\n' "$line" | cut -f4)"
    witness="$(printf '%s\n' "$line" | cut -f5)"
    st="$(felix_probe_state "$root" "$when" "$probe" "$witness")"
    printf '%s\t%s\t%s\t%s\n' "$pred" "$grounds" "$st" "$probe"
  done <<EOF
$(felix_probe_rows "$proj")
EOF
  return 0
}

# The states that stop work. Named once, here, so that a caller cannot quietly
# disagree about which ones they are.
felix_probes_blocking() {
  awk -F'\t' '$3 == "unknown" || $3 == "blind"'
  return 0
}

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

# Append the run to the project's fact log, with provenance.
#
# Append-only and never rewritten. A log a command can rewrite is a log that
# can be made to agree with whatever ran last, and the whole point of keeping
# facts over time is to be able to see one change.
#
# Provenance is the four things a later reader needs in order to decide whether
# this fact still means anything: when it was taken, which tree it was taken
# from, what state was computed, and the exact command that produced it. v3.2
# §2 asks for freshness and dependencies as well; the tree id is what this
# increment can honestly supply for both, and saying so is better than a column
# holding a guess.
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
  local dir log stamp line pred grounds state count detail probe before after n
  dir="$(felix_mem_dir "$proj")"
  mkdir -p "$dir" 2>/dev/null || return 1
  log="$dir/facts.log"
  [ -f "$log" ] || : > "$log" 2>/dev/null || return 1

  stamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  [ -n "$tid" ] || tid="unknown-tree"
  before="$(wc -l < "$log" 2>/dev/null | tr -dc '0-9')"; [ -n "$before" ] || before=0
  n=0

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    pred="$(printf '%s\n' "$line" | cut -f1)"
    grounds="$(printf '%s\n' "$line" | cut -f2)"
    state="$(printf '%s\n' "$line" | cut -f3)"
    count="$(printf '%s\n' "$line" | cut -f4)"
    detail="$(printf '%s\n' "$line" | cut -f5)"
    probe="$(printf '%s\n' "$line" | cut -f6)"
    n=$((n + 1))
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$stamp" "$tid" "$pred" "$(felix_probe_class "$state")" \
      "$state" "$count" "${grounds:--}" "$probe" >> "$log" || return 1
  done <<EOF
$rows
EOF

  [ "$n" -gt 0 ] || return 0
  after="$(wc -l < "$log" 2>/dev/null | tr -dc '0-9')"; [ -n "$after" ] || after=0
  # Counted rather than trusted. `>>` on a full disk, a read-only volume or a
  # path that stopped being a file reports through an exit status this loop can
  # miss inside a subshell; the line count cannot be misread.
  [ "$((after - before))" -eq "$n" ]
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
felix_probes_drift() {
  local proj="$1" tid="$2" rows="$3"
  local log key when tree line pred state count was seen_now=""
  log="$(felix_mem_dir "$proj")/facts.log"
  [ -f "$log" ] || return 0
  [ -n "$tid" ] || return 0

  # One run is one timestamp and one tree together. The timestamp alone would
  # merge two runs that happened inside the same second on different trees,
  # which is not hypothetical: a gate and a merge check can land together.
  key="$(awk -F'\t' -v t="$tid" '$2 != "" && $2 != t { k = $1 "\t" $2 } END { if (k != "") print k }' "$log")"
  [ -n "$key" ] || return 0
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
    seen_now="$seen_now
$pred"
    was="$(awk -F'\t' -v w="$when" -v tr="$tree" -v p="$pred" \
             '$1 == w && $2 == tr && $3 == p { print $5 "\t" $6 }' "$log" | head -1)"
    if [ -z "$was" ]; then
      printf '%s\t-\t%s\tnothing had been recorded for this predicate\n' "$pred" "$state"
      continue
    fi
    local wstate wcount
    wstate="$(printf '%s' "$was" | cut -f1)"
    wcount="$(printf '%s' "$was" | cut -f2)"
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
      *[!0-9]*|'')
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

# Surfaces this checkout has that no probe reads.
#
# The enumeration is felix_detect's, not this file's, which is the same
# borrowing procedures.tsv does and for the same reason: a gap list Felix wrote
# cannot report the gap Felix did not think of. A capability is a claim about
# what exists here that was reached by pattern-matching filenames and manifests.
# A probe grounding it is the difference between believing that claim and having
# asked the thing that knows.
felix_probes_gaps() {
  local proj="$1" root="$2" grounded cap
  grounded="$(felix_probe_rows "$proj" | cut -f2 | grep -v '^-\?$' | LC_ALL=C sort -u)"
  while IFS= read -r cap; do
    [ -n "$cap" ] || continue
    felix_has_line "$grounded" "$cap" && continue
    printf '%s\n' "$cap"
  done <<EOF
$( { felix_detect "$root" 2>/dev/null; felix_declared "$proj" 2>/dev/null; } | LC_ALL=C sort -u )
EOF
  return 0
}

# And the other direction: a probe claiming to ground a capability that nothing
# enumerates any more. The precedent checks both, because a table is wrong when
# it lacks a row reality has and equally wrong when it keeps one reality
# dropped.
felix_probes_orphans() {
  local proj="$1" root="$2" caps cap
  caps="$( { felix_detect "$root" 2>/dev/null; felix_declared "$proj" 2>/dev/null; } \
           | LC_ALL=C sort -u )"
  while IFS= read -r cap; do
    [ -n "$cap" ] || continue
    felix_has_line "$caps" "$cap" && continue
    printf '%s\n' "$cap"
  done <<EOF
$(felix_probe_rows "$proj" | cut -f2 | grep -v '^-\?$' | LC_ALL=C sort -u)
EOF
  return 0
}
