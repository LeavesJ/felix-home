# felix situations, the report (slice 1 of the capability lane; contracts C8 to C11 of
# docs/2026-10-29-lane-slice-1-plan.md). Loaded by cmd_situations in felix, after lib/situations.sh. Definitions only.
#
# It prints one of three things, all from the evaluation the other two libraries make and none from a clock, a model or
# the network:
#
#   the human report   situations for <project>, how each side was read, the sections owed, blinded, retired, standing
#                      and residual in --change (standing and residual in --at), and the count line (C9)
#   --tsv              one line per class, then the residual lines, in an order that does not depend on the caller's
#                      locale (C8); slice 2 reads this form
#   --propose          after the count line, a drafted obligations row and the command that would admit it for each
#                      class that is ACTIVE and not yet admitted (C11); it writes nothing
#
# Built here so far: the --at report, human and --tsv. The --change sections and --propose come with the tasks that follow.
# Every file the report needs is made inside the run's scratch directory, and every sort runs under LC_ALL=C.

# FILE KEY -> the second cell of the first line of a reading file whose first cell is KEY.
_felix_situations_field() {
  LC_ALL=C awk -F'\t' -v k="${2-}" '$1 == k { print $2; exit }' "${1-}"
}

# The residual lines (C10) of one side's evaluation EVAL, as residual<TAB>kind<TAB>name<TAB>why, unsorted, less the cells with no
# row: a could-not-look line for each undecided term of each class that is UNKNOWN on that side, whose why begins with SIDE (base,
# head, or at), and an unbound line for each unbound term.
_felix_situations_residual() {   # SIDE EVAL
  LC_ALL=C awk -F'\t' -v side="${1-}" '
    $1 == "class" { st[$2] = $3 }
    $1 == "undecided" { n++; uc[n] = $2; ut[n] = $3; uw[n] = $4 }
    $1 == "unbound" { printf "residual\tunbound\t%s\t%s\n", $2, $3 }
    END {
      for (i = 1; i <= n; i++)
        if (st[uc[i]] == "UNKNOWN") printf "residual\tcould-not-look\t%s\t%s: %s: %s\n", uc[i], side, ut[i], uw[i]
    }' "${2-}"
}

# The cells with no row (C10): a no-row line for each capability that no class uses and that some EVAL names, from the detector
# or from a probe row's grounds cell. The sources are the union over every EVAL given: the detector first, then the probes by
# byte order of the predicate.
_felix_situations_norow() {   # EVAL...
  cat "$@" | LC_ALL=C awk -F'\t' '$1 == "seen"' | LC_ALL=C sort -u | LC_ALL=C awk -F'\t' '
    function flush() {
      if (cur == "") return
      printf "residual\tno-row\t%s\tnamed by %s\n", cur, (det ? "the detector" (srcs == "" ? "" : ", " srcs) : srcs)
    }
    ($2 "") != (cur "") { flush(); cur = $2 ""; det = 0; srcs = "" }
    $3 == "the detector" { det = 1; next }
    { srcs = srcs ((srcs == "") ? "" : ", ") $3 }
    END { flush() }'
}

# The report (C8, C9) for MODE at, in FORMAT human or tsv, to stdout. ROWS is the table's rows (a file), HEAD-EVAL the evaluation
# of the one reading (felix_situations_eval), HEAD-READING its reading file. BASE-EVAL and BASE-READING are - in --at. Files
# it makes live in the scratch directory. Returns 1 when it cannot make them, and for a mode this file does not build yet.
felix_situations_report() {   # MODE FORMAT PROJ ROWS BASE-EVAL|- HEAD-EVAL BASE-READING|- HEAD-READING
  local mode="${1-}" fmt="${2-}" proj="${3-}" rows="${4-}" heval="${6-}" hread="${8-}"
  local w="${_FELIX_SITUATIONS_SCRATCH:-}" name line class body det tab=$'\t'
  [ "$mode" = at ] && [ -n "$w" ] || return 1
  proj="${proj%/}"; name="${proj##*/}"

  # One id per class (C6), then one line per class: rank, id, class, verdict, base, head, base grounds, head grounds, owes,
  # base readings, head readings, base witness, head witness. In --at the verdict follows the one state (C5).
  : > "$w/ids" || return 1
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    class="${line%%"$tab"*}"
    printf '%s\t%s\n' "$class" "$(felix_situations_id "$class" "$name")" >> "$w/ids" || return 1
  done < "$rows"
  FELIX_SIT_ROWS="$rows" FELIX_SIT_IDS="$w/ids" LC_ALL=C awk -F'\t' '
    BEGIN {
      while ((getline l < ENVIRON["FELIX_SIT_ROWS"]) > 0) {
        if (split(l, f, "\t") >= 5) { nr++; CL[nr] = f[1] ""; OW[f[1] ""] = f[3] "" }
      }
      while ((getline l < ENVIRON["FELIX_SIT_IDS"]) > 0) { split(l, f, "\t"); ID[f[1] ""] = f[2] "" }
    }
    $1 == "class" { ST[$2] = $3; GR[$2] = $4; RD[$2] = $5 }
    END {
      for (i = 1; i <= nr; i++) {
        c = CL[i]; s = ST[c]
        v = "none"; k = 6
        if (s == "ACTIVE") { v = "standing"; k = 4 }
        else if (s == "UNKNOWN") { v = "could-not-look"; k = 5 }
        printf "%d\t%s\t%s\t%s\t-\t%s\t-\t%s\t%s\t-\t%s\t-\t-\n", k, ID[c], c, v, s, GR[c], OW[c], RD[c]
      }
    }' "$heval" > "$w/classes" || return 1
  { _felix_situations_residual at "$heval"; _felix_situations_norow "$heval"; } | LC_ALL=C sort -u > "$w/residual" || return 1

  if [ "$fmt" = tsv ]; then
    LC_ALL=C sort "$w/classes" | LC_ALL=C cut -f2-9
    cat "$w/residual"
    return 0
  fi

  printf 'situations for %s\n' "$name"
  det="$(_felix_situations_field "$hread" detector)"
  if [ "$det" = run ]; then
    printf '  at  %s  tree %s  recorded %s  detector run on this checkout\n' \
      "$(_felix_situations_field "$hread" commit)" "$(_felix_situations_field "$hread" tree)" "$(_felix_situations_field "$hread" stamp)"
  else
    printf '  at  -  tree %s  recorded %s  detector not run: this checkout is not at this tree\n' \
      "$(_felix_situations_field "$hread" tree)" "$(_felix_situations_field "$hread" stamp)"
  fi
  printf '\nstanding\n'
  body="$(LC_ALL=C awk -F'\t' '$4 == "standing"' "$w/classes" | LC_ALL=C sort -t "$tab" -k3,3 | LC_ALL=C awk -F'\t' '
    { printf "  %s  %s  ACTIVE\n    grounds  %s\n    readings  %s\n    owes  %s\n", $2, $3, $8, $11, $9 }')"
  if [ -n "$body" ]; then printf '%s\n' "$body"; else printf '  none\n'; fi
  printf '\nresidual\n'
  body="$(LC_ALL=C awk -F'\t' '{ printf "  %s  %s  %s\n", $2, $3, $4 }' "$w/residual")"
  if [ -n "$body" ]; then printf '%s\n' "$body"; else printf '  none: nothing undecided, unbound or without a row\n'; fi
  LC_ALL=C awk -F'\t' '
    { n++; if ($6 == "ACTIVE") a++; else if ($6 == "DORMANT") d++; else u++ }
    END { printf "\nexamined %d, active %d, dormant %d, could not look %d\n", n, a, d, u }' "$w/classes"
  return 0
}
