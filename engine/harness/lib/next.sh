# What to do next, ranked.
#
# Felix tracked maintenance, drift, setup gaps, evidence gaps, coverage and
# retirement in six separate commands and never once said which of them
# mattered. A founder reading six reports to work out the order is doing the job
# Felix exists to take.
#
# The ranking is not a taste ordering. It is anchored on the declared objective
# — founder interruptions per session — and then on what is blocking now:
#
#   1  work Felix owes on the change in hand. Nobody else can be waiting on it.
#   2  an escape. This is literally the number the objective counts, so it is
#      never buried under upkeep.
#   3  a tool a route names and cannot reach. Plugins bind at session start, so
#      this can only be fixed BETWEEN sessions — it is the highest-leverage
#      preventive row there is, and invisible until the turn it was needed.
#   4  upkeep past its cadence.
#   5  something that has already cost time more than once.
#   6  rot that will quietly mislead: a deny rule too broad to enforce.
#   7  routing gaps. Costs context in every session and points at routes.tsv.
#
# Emits: rank <TAB> owner <TAB> what <TAB> do
# owner is `felix` or `founder`. Empty output means nothing is due.
#
# This ranks and does not act, which is worth defending because the charter
# calls printing a suggestion for something Felix could have done a defect.
# Almost nothing here is safely auto-doable: running the gate costs minutes and
# should not fire implicitly, writing a missing test is not mechanical, and
# fixing a route is a judgement about words. The one genuinely reversible item —
# tidying — already happens at SessionStart where a project has granted it. So
# this is a ranking of work that needs time or judgement, not a list of things
# Felix is being shy about.

_felix_next_row() { printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4"; }

felix_next() {
  local proj="$1" home="$2" root="$3" base="${4:-main}"
  local tid receipt line kind subject reason

  # 1 — the change in hand.
  tid="$(felix_tree_id "$root" "$home" 2>/dev/null)" || tid=""
  receipt="$(felix_verify_receipt "$root" "$home" 2>/dev/null)"
  if [ -z "$tid" ] \
       || [ "$(printf '%s' "$receipt" | cut -f1)" != "$tid" ] \
       || [ "$(printf '%s' "$receipt" | cut -f2)" != "green" ]; then
    _felix_next_row 1 felix "this tree has no green gate receipt" "felix gate"
  fi

  if command -v felix_evidence_check >/dev/null 2>&1; then
    while IFS=$'\t' read -r kind subject reason; do
      [ "${kind:-}" = "gap" ] || continue
      _felix_next_row 1 felix "the change owes evidence: $subject — $reason" \
        "write the test, then felix evidence"
    done <<EOF
$(felix_evidence_check "$proj" "$base" "$root" 2>/dev/null)
EOF
  fi

  # 2 — the founder's, and never buried.
  if command -v felix_escapes >/dev/null 2>&1; then
    while IFS=$'\t' read -r kind subject reason; do
      [ -n "${kind:-}" ] || continue
      # `unknown` is the one row here that is not the founder's. It means the
      # base named nothing this repository holds, so no channel was consulted
      # and there is no diff to show them the reversal path for. Ranked 1 and
      # Felix's, because until it is corrected every row above and below it was
      # computed against a comparison that never happened.
      if [ "$kind" = "unknown" ]; then
        _felix_next_row 1 felix "nothing was scanned: $subject — $reason" \
          "name a base that exists here, with --base, then run this again"
        continue
      fi
      _felix_next_row 2 founder "$kind: $subject — $reason" \
        "show the diff and its reversal path; a green gate is not the question"
    done <<EOF
$(felix_escapes "$proj" "$base" "$root" "$home" 2>/dev/null)
EOF
  fi

  # 3 — a named tool that is not reachable. Between sessions or never.
  #
  # felix_ready_report emits five states, and two of them mean NOT MEASURED
  # rather than reachable: `undeclared` (a route names it, no manifest declares
  # it, so the inventory is never consulted at all) and `unknown` (no claude
  # CLI here, which ready.sh refuses to call `absent` precisely because it
  # cannot tell "not installed" from "installed where I cannot look"). Keeping
  # only absent|disabled dropped both on the floor, and an empty rank-3 list is
  # what cmd_next renders as "every tool a route names is reachable" — putting
  # back exactly the guess ready.sh had refused, one layer up, in prose.
  #
  # Each of the four gets the action that actually answers it, and `unknown`
  # gets none, because there is nothing the reader can do about a machine that
  # cannot look. Saying it is the whole point: this project's recorded lesson
  # is that "nothing due" and "nothing is being checked" render identically.
  if command -v felix_ready_report >/dev/null 2>&1; then
    while IFS=$'\t' read -r kind subject reason; do
      case "${kind:-}" in
        absent|disabled)
          _felix_next_row 3 felix "$subject is $kind — $reason" \
            "install or enable it before the next session; plugins bind at start" ;;
        undeclared)
          _felix_next_row 3 felix "$subject is named by a route and declared nowhere — $reason" \
            "declare it in stack.tsv, or drop it from the play that names it" ;;
        unknown)
          _felix_next_row 3 felix "$subject could not be checked — $reason" \
            "nothing to do here: this is a limit of this machine, not of the project" ;;
        *) continue ;;
      esac
    done <<EOF
$(felix_ready_report "$proj" 2>/dev/null)
EOF
  fi

  # 4 — upkeep.
  if command -v felix_maint_status >/dev/null 2>&1; then
    local st nm age cad desc
    while IFS=$'\t' read -r st nm age cad desc; do
      [ "${st:-}" = "due" ] || continue
      _felix_next_row 4 felix "upkeep due: $nm — $desc" "felix maintenance"
    done <<EOF
$(felix_maint_status "$proj" "$(felix_repo_root "$PWD" 2>/dev/null)" 2>/dev/null)
EOF
  fi

  # 5 — what has already cost time twice.
  #
  # `felix promote` computed this and then asked a person to type
  # `felix lesson "..."`, which is the charter's defect exactly: it had the
  # finding and handed back the work. Writing the prose is not the conversion —
  # a lesson is judgement and a fabricated one pollutes the file that gets
  # matched into every prompt. What is mechanical is the distinction promote's
  # own closing line draws and never acts on: a recurrence with no lesson behind
  # it needs one written, and a recurrence that already HAS one means the lesson
  # is not working, and the answer is a mechanism or the constitution rather
  # than more prose nobody is reading.
  if command -v felix_mem_recurring_mistakes >/dev/null 2>&1; then
    local cnt term last
    while IFS=$'\t' read -r cnt term last; do
      [ -n "${term:-}" ] || continue
      # The date is not decoration. It is the only thing on the row that says
      # whether this is a habit or a story, and it is what makes the claim
      # falsifiable by anyone reading it.
      if felix_mem_lesson_names "$proj" "$term"; then
        _felix_next_row 5 felix \
          "the gate caught '$term' $cnt times, last $last, and a lesson already says so — the lesson is not working" \
          "it has outgrown lessons.md: put it where the gate can see it, or build the mechanism"
      else
        _felix_next_row 5 felix \
          "the gate caught '$term' $cnt times, last $last, and no lesson mentions it" \
          "felix lesson \"...\" — what would change what someone does next time"
      fi
    done <<EOF
$(felix_mem_recurring_mistakes "$proj" 2>/dev/null)
EOF
  fi

  # 6 — rot that misleads. A stance nobody wrote and a rule that silently does
  # nothing both read as "checked" from the outside, which is the failure this
  # project keeps having in different costumes.
  if command -v felix_deny_overbroad_rows >/dev/null 2>&1; then
    local t p r
    while IFS=$'\t' read -r t p r; do
      [ -n "${p:-}" ] || continue
      _felix_next_row 6 felix "a deny rule for $t refuses everything and is skipped" \
        "narrow the pattern in $proj/deny.tsv, or drop the row"
    done <<EOF
$(felix_deny_overbroad_rows "$proj" 2>/dev/null)
EOF
  fi

  # A maintenance row whose capability nothing can satisfy is dormant forever,
  # and dormant renders exactly like "not due". This rank is named for that
  # collision, and the guard for it was written and then called by nothing but
  # the suite — every surface that reads maintenance keeps only `^due`, so a
  # typo in the capability column is invisible on all of them, permanently.
  if command -v felix_maint_unreachable >/dev/null 2>&1; then
    local mname mcap
    while IFS=$'\t' read -r mname mcap; do
      [ -n "${mname:-}" ] || continue
      _felix_next_row 6 felix "upkeep '$mname' waits on a capability nothing declares: $mcap" \
        "fix the capability in $proj/maintenance.tsv, or declare it — it can never come due as written"
    done <<EOF
$(felix_maint_unreachable "$proj" 2>/dev/null)
EOF
  fi

  # 7 — routing. Mounted, never pointed at. Not the same as "no route names it":
  # the table may name it while its keywords never match the work anybody does,
  # which is the row worth finding. Weak while few sessions are recorded.
  if command -v felix_ledger_unrouted >/dev/null 2>&1; then
    local nm sessions
    while IFS=$'\t' read -r nm sessions; do
      [ -n "${nm:-}" ] || continue
      # Two causes, opposite fixes, and this said the same sentence for both.
      # Half the rows on Felix's own project named plugins that appear in no
      # play at all, so "check the keywords" was advice nobody could follow —
      # no keyword reaches a capability no route mentions. The ledger already
      # separates these one layer down; this never inherited it.
      if command -v felix_route_names_capability >/dev/null 2>&1 \
           && ! felix_route_names_capability "$proj" "$nm"; then
        _felix_next_row 7 felix \
          "$nm is mounted and no route names it, so no keyword can reach it" \
          "felix toolbox --route to wire it, or stop mounting it — its zero says nothing about the capability"
      else
        _felix_next_row 7 felix "$nm is mounted and no route pointed at it in $sessions recorded session(s)" \
          "check the keywords in $proj/routes.tsv match real work, or stop mounting it"
      fi
    done <<EOF
$(felix_ledger_unrouted "$proj" 2>/dev/null)
EOF
  fi
}
