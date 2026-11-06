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
# The --at and --change reports, human and --tsv, are built here, and so are the --propose drafts.
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

# One section's rows of the human report (C9), from the class lines CLASSES (a file) of the report function: those whose verdict
# is SECTION, in byte order of class name. MODE is at or change. In --change a row is the id, the class and BASE -> HEAD, then
# the grounds and readings of each side, a witness line for each side where the class is DORMANT and C7 gives one (base first),
# and the owes cell; in --at it is the id, the class and ACTIVE, the grounds, the readings and the owes cell. Prints a single
# "  none" when the section holds no row.
_felix_situations_section() {   # MODE SECTION CLASSES
  local body tab=$'\t'
  body="$(LC_ALL=C awk -F'\t' -v s="${2-}" '$4 == s' "${3-}" | LC_ALL=C sort -t "$tab" -k3,3 | LC_ALL=C awk -F'\t' -v m="${1-}" '
    m == "change" {
      printf "  %s  %s  %s -> %s\n    grounds  base: %s; head: %s\n    readings  base: %s; head: %s\n", $2, $3, $5, $6, $7, $8, $10, $11
      if ($5 == "DORMANT" && $12 != "-") printf "    witness  base: %s\n", $12
      if ($6 == "DORMANT" && $13 != "-") printf "    witness  head: %s\n", $13
      printf "    owes  %s\n", $9
      next
    }
    { printf "  %s  %s  ACTIVE\n    grounds  %s\n    readings  %s\n    owes  %s\n", $2, $3, $8, $11, $9 }')"
  if [ -n "$body" ]; then printf '%s\n' "$body"; else printf '  none\n'; fi
}

# The report (C8, C9) for MODE at or change, in FORMAT human or tsv, to stdout. ROWS is the table's rows (a file). BASE-EVAL and
# HEAD-EVAL are the evaluations of the two readings (felix_situations_eval), BASE-READING and HEAD-READING the reading files;
# in --at the base ones are - and the head ones are the one reading. Files it makes live in the scratch directory. In --change
# each class gets its verdict token from its two states and whether a grounding reading differs between the sides (C5): the
# differs test compares the key of the class's two class lines, which holds, term by term, the grounding rows' predicate, state
# and count, and, for a capability decided by the detector, its answer. In --at the token follows the one state. Returns 1 when
# it cannot make its files.
felix_situations_report() {   # MODE FORMAT PROJ ROWS BASE-EVAL|- HEAD-EVAL BASE-READING|- HEAD-READING
  local mode="${1-}" fmt="${2-}" proj="${3-}" rows="${4-}" beval="${5-}" heval="${6-}" bread="${7-}" hread="${8-}"
  local w="${_FELIX_SITUATIONS_SCRATCH:-}" name line class bs hs df sec det tab=$'\t'
  [ -n "$w" ] || return 1
  case "$mode" in at|change) ;; *) return 1 ;; esac
  proj="${proj%/}"; name="${proj##*/}"

  # One id per class (C6).
  : > "$w/ids" || return 1
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    class="${line%%"$tab"*}"
    printf '%s\t%s\n' "$class" "$(felix_situations_id "$class" "$name")" >> "$w/ids" || return 1
  done < "$rows"

  # In --change, the token of every class from its two states and whether they differ.
  : > "$w/verdicts" || return 1
  if [ "$mode" = change ]; then
    LC_ALL=C awk -F'\t' '
      $1 != "class" { next }
      FILENAME == ARGV[1] { BS[$2 ""] = $3 ""; BK[$2 ""] = $7 ""; next }
      { printf "%s %s %s %d\n", $2, BS[$2 ""], $3, (BK[$2 ""] != $7 "") }' "$beval" "$heval" > "$w/pairs" || return 1
    while read -r class bs hs df; do
      printf '%s\t%s\n' "$class" "$(felix_situations_verdict "$bs" "$hs" "$df")" >> "$w/verdicts" || return 1
    done < "$w/pairs"
  fi

  # One line per class: rank, id, class, verdict, base, head, base grounds, head grounds, owes, base readings, head readings,
  # base witness, head witness. In --at the base cells are - and the verdict follows the one state.
  FELIX_SIT_MODE="$mode" FELIX_SIT_ROWS="$rows" FELIX_SIT_IDS="$w/ids" FELIX_SIT_VERD="$w/verdicts" \
    FELIX_SIT_BEVAL="$beval" FELIX_SIT_HEVAL="$heval" LC_ALL=C awk '
    function rank(v) {
      return (v == "owed") ? 1 : (v == "blinded") ? 2 : (v == "retired") ? 3 : (v == "standing") ? 4 : (v == "could-not-look") ? 5 : 6
    }
    BEGIN {
      mode = ENVIRON["FELIX_SIT_MODE"]
      while ((getline l < ENVIRON["FELIX_SIT_ROWS"]) > 0) {
        if (split(l, f, "\t") >= 5) { nr++; CL[nr] = f[1] ""; OW[f[1] ""] = f[3] "" }
      }
      while ((getline l < ENVIRON["FELIX_SIT_IDS"]) > 0) { split(l, f, "\t"); ID[f[1] ""] = f[2] "" }
      if (mode == "change") {
        while ((getline l < ENVIRON["FELIX_SIT_VERD"]) > 0) { split(l, f, "\t"); VD[f[1] ""] = f[2] "" }
        while ((getline l < ENVIRON["FELIX_SIT_BEVAL"]) > 0) {
          split(l, f, "\t")
          if (f[1] == "class") { c = f[2] ""; BS[c] = f[3] ""; BG[c] = f[4] ""; BR[c] = f[5] ""; BW[c] = f[6] "" }
        }
      }
      while ((getline l < ENVIRON["FELIX_SIT_HEVAL"]) > 0) {
        split(l, f, "\t")
        if (f[1] == "class") { c = f[2] ""; HS[c] = f[3] ""; HG[c] = f[4] ""; HR[c] = f[5] ""; HW[c] = f[6] "" }
      }
      for (i = 1; i <= nr; i++) {
        c = CL[i]
        if (mode == "change") { v = VD[c]; b = BS[c]; bg = BG[c]; br = BR[c]; bw = BW[c] }
        else {
          v = (HS[c] == "ACTIVE") ? "standing" : (HS[c] == "UNKNOWN") ? "could-not-look" : "none"
          b = "-"; bg = "-"; br = "-"; bw = "-"
        }
        printf "%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", rank(v), ID[c], c, v, b, HS[c], bg, HG[c], OW[c], br, HR[c], bw, HW[c]
      }
    }' </dev/null > "$w/classes" || return 1

  # The residual (C10), unique, as whole lines in bytes: the undecided terms of each side, the unbound terms, the cells with no row.
  if [ "$mode" = change ]; then
    { _felix_situations_residual base "$beval"; _felix_situations_residual head "$heval"; _felix_situations_norow "$beval" "$heval"; } \
      | LC_ALL=C sort -u > "$w/residual" || return 1
  else
    { _felix_situations_residual at "$heval"; _felix_situations_norow "$heval"; } | LC_ALL=C sort -u > "$w/residual" || return 1
  fi

  if [ "$fmt" = tsv ]; then
    LC_ALL=C sort "$w/classes" | LC_ALL=C cut -f2-9
    cat "$w/residual"
    return 0
  fi

  printf 'situations for %s\n' "$name"
  if [ "$mode" = change ]; then
    printf '  base  %s  tree %s  scratch checkout, tracked content only, current probes.tsv\n' \
      "$(_felix_situations_field "$bread" commit)" "$(_felix_situations_field "$bread" tree)"
    printf '  head  %s  tree %s  scratch checkout, tracked content only, current probes.tsv\n' \
      "$(_felix_situations_field "$hread" commit)" "$(_felix_situations_field "$hread" tree)"
  else
    det="$(_felix_situations_field "$hread" detector)"
    if [ "$det" = run ]; then
      printf '  at  %s  tree %s  recorded %s  detector run on this checkout\n' \
        "$(_felix_situations_field "$hread" commit)" "$(_felix_situations_field "$hread" tree)" "$(_felix_situations_field "$hread" stamp)"
    elif [ "$det" = no-tree ]; then
      printf '  at  -  tree %s  recorded %s  detector not run: the tree id of this checkout could not be taken\n' \
        "$(_felix_situations_field "$hread" tree)" "$(_felix_situations_field "$hread" stamp)"
    else
      printf '  at  -  tree %s  recorded %s  detector not run: this checkout is not at this tree\n' \
        "$(_felix_situations_field "$hread" tree)" "$(_felix_situations_field "$hread" stamp)"
    fi
  fi
  if [ "$mode" = change ]; then
    for sec in owed blinded retired standing; do
      printf '\n%s\n' "$sec"
      _felix_situations_section change "$sec" "$w/classes"
    done
  else
    printf '\nstanding\n'
    _felix_situations_section at standing "$w/classes"
  fi
  printf '\nresidual\n'
  line="$(LC_ALL=C awk -F'\t' '{ printf "  %s  %s  %s\n", $2, $3, $4 }' "$w/residual")"
  if [ -n "$line" ]; then printf '%s\n' "$line"; else printf '  none: nothing undecided, unbound or without a row\n'; fi
  LC_ALL=C awk -F'\t' '
    { n++; if ($6 == "ACTIVE") a++; else if ($6 == "DORMANT") d++; else u++ }
    END { printf "\nexamined %d, active %d, dormant %d, could not look %d\n", n, a, d, u }' "$w/classes"
  return 0
}

# The proposed section (C11), from its blank line on, to stdout: for each class that is ACTIVE in EVAL (the head side, or the
# reading in --at) and whose name no row of the project's obligations.tsv admits, in byte order of name, the line
# "  <id>  <class>  <grounds>", then a class line, the drafted row (seven cells joined by real tab bytes) and the one-line
# command that would append it to the table and commit it. With none, "  none". MATURITY is project.json's string, empty when
# none is declared; READING is the reading file EVAL was made from; HOME is the Felix home as given. The class is the one
# class_by_maturity pairs with the declared maturity, else the strictest class the cell names. The preds cell lists the
# predicates the class's true terms rest on that the current probes.tsv defines (the grounds file of the scratch directory).
# Every quoted value has each apostrophe written as the four characters quote, backslash, quote, quote. The command begins
# with a guard that ends the table's last row when it has none (C17.1), then C11's command. The ids file is the
# one felix_situations_report made in the same scratch directory. Writes only inside that directory, and no apostrophe may
# stand in the awk text: it is one shell word.
felix_situations_propose() {   # PROJ HOME ROWS EVAL MATURITY READING
  local proj="${1-}" home="${2-}" rows="${3-}" eval="${4-}" mat="${5-}" reading="${6-}"
  local w="${_FELIX_SITUATIONS_SCRATCH:-}" name tab=$'\t'
  [ -n "$w" ] && [ -f "$w/ids" ] && [ -f "$w/grounds" ] || return 1
  proj="${proj%/}"; name="${proj##*/}"
  felix_obligation_rows "$proj" | LC_ALL=C cut -f1 > "$w/admitted" || return 1
  LC_ALL=C sort -t "$tab" -k1,1 "$rows" > "$w/prop.rows" || return 1
  FELIX_SIT_ROWS="$w/prop.rows" FELIX_SIT_EVAL="$eval" FELIX_SIT_ADM="$w/admitted" FELIX_SIT_IDS="$w/ids" \
    FELIX_SIT_READING="$reading" FELIX_SIT_GROUNDS="$w/grounds" FELIX_SIT_MATURITY="$mat" FELIX_SIT_HOME="$home" \
    FELIX_SIT_NAME="$name" LC_ALL=C awk '
    function isst(s) { return s == "found" || s == "empty" || s == "blind" || s == "unknown" || s == "not-applicable" }
    function ismat(m) { return m == "prototype" || m == "internal" || m == "public-beta" || m == "production" }
    function crank(c) {
      return (c == "INFO") ? 1 : (c == "ADVISORY") ? 2 : (c == "TASK_BLOCKING") ? 3 : (c == "RELEASE_BLOCKING") ? 4 : (c == "AUTHORITY_BLOCKING") ? 5 : 0
    }
    # S single-quoted for a shell, each apostrophe written as quote, backslash, quote, quote.
    function q(s,   n, p, i, o) {
      n = split(s, p, SQ); o = p[1]
      for (i = 2; i <= n; i++) o = o SQ "\\" SQ SQ p[i]
      return SQ o SQ
    }
    # Sets CW and CN: the class for the declared maturity and the note that says why.
    function pick(cell,   n, pr, i, e, m, c, best, br) {
      CW = ""; br = 0; best = ""
      n = split(cell, pr, ",")
      for (i = 1; i <= n; i++) {
        e = index(pr[i], "="); m = substr(pr[i], 1, e - 1); c = substr(pr[i], e + 1)
        if (ismat(MAT) && m == MAT) CW = c
        if (crank(c) > br) { br = crank(c); best = c }
      }
      if (CW != "") { CN = "maturity " MAT; return }
      CW = best
      CN = (MAT == "") ? "maturity undeclared: the strictest class this row names" : "maturity " SQ MAT SQ " is not one of prototype internal public-beta production: the strictest class this row names"
    }
    # The grounding rows of capability c: GI[1..NG] index the reading, one per predicate, its first row, in reading order.
    function ground(c,   i) {
      NG = 0; split("", SP)
      if (c == "" || c == "-") return
      for (i = 1; i <= np; i++) if (PG[i] == c && !(PP[i] in SP)) { SP[PP[i]] = 1; GI[++NG] = i }
    }
    function addp(i) {
      if (!(PP[i] in DEF) || (PP[i] in GOT)) return
      GOT[PP[i]] = 1; PL = PL ((PL == "") ? "" : ",") PP[i]
    }
    # Sets PL to the predicates the true terms of an applies cell rest on, in first-use order, without repeats.
    function preds(ap,   nt, tm, t, k, rest, e, c, s, fo) {
      PL = ""; split("", GOT)
      nt = split(ap, tm, / +/)
      for (t = 1; t <= nt; t++) {
        if (substr(tm[t], 1, 6) == "probe:") {
          rest = substr(tm[t], 7); e = index(rest, "=")
          if (e < 2 || !isst(substr(rest, e + 1))) continue
          c = substr(rest, 1, e - 1); s = substr(rest, e + 1)
          ground(c)
          for (k = 1; k <= NG; k++) if (PS[GI[k]] == s) addp(GI[k])
        } else if (substr(tm[t], 1, 4) == "cap:" && length(tm[t]) > 4) {
          ground(substr(tm[t], 5)); fo = 0
          for (k = 1; k <= NG; k++) if (PS[GI[k]] == "found") fo = 1
          if (fo) for (k = 1; k <= NG; k++) if (PS[GI[k]] == "found") addp(GI[k])
        }
      }
      if (PL == "") PL = "-"
    }
    BEGIN {
      SQ = "\047"; TB = "\t"; MAT = ENVIRON["FELIX_SIT_MATURITY"] ""; H = ENVIRON["FELIX_SIT_HOME"] ""
      P = H "/projects/" ENVIRON["FELIX_SIT_NAME"]; TBL = q(P "/obligations.tsv")
      GUARD = "{ [ ! -s " TBL " ] || [ -z \"$(tail -c 1 " TBL ")\" ] || printf " SQ "\\n" SQ "; } >> " TBL " && "
      while ((getline l < ENVIRON["FELIX_SIT_EVAL"]) > 0) {
        split(l, f, "\t")
        if (f[1] == "class") { ST[f[2] ""] = f[3] ""; GR[f[2] ""] = f[4] "" }
      }
      while ((getline l < ENVIRON["FELIX_SIT_ADM"]) > 0) ADM[l ""] = 1
      while ((getline l < ENVIRON["FELIX_SIT_IDS"]) > 0) { split(l, f, "\t"); ID[f[1] ""] = f[2] "" }
      while ((getline l < ENVIRON["FELIX_SIT_GROUNDS"]) > 0) { split(l, f, "\t"); DEF[f[1] ""] = 1 }
      while ((getline l < ENVIRON["FELIX_SIT_READING"]) > 0) {
        split(l, f, "\t")
        if (f[1] == "probe") { np++; PP[np] = f[2] ""; PG[np] = f[3] ""; PS[np] = f[4] "" }
      }
      printf "\nproposed\n"
      while ((getline l < ENVIRON["FELIX_SIT_ROWS"]) > 0) {
        if (split(l, f, "\t") < 4) continue
        c = f[1] ""
        if (ST[c] != "ACTIVE" || (c in ADM)) continue
        shown++
        pick(f[4] ""); preds(f[2] "")
        print "  " ID[c] "  " c "  " GR[c]
        print "    class  " CW "  " CN
        print "    row  " c TB CW TB "unknown" TB "-" TB "exit 2" TB PL TB f[3]
        print "    admit  " GUARD "printf " SQ "%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n" SQ " " q(c) " " q(CW) " " q("unknown") " " q("-") " " q("exit 2") " " q(PL) " " q(f[3] "") " >> " TBL " && git -C " q(H) " add -- " TBL " && git -C " q(H) " commit -q -m " q("obligations: admit " c) " -- " TBL
      }
      if (!shown) printf "  none\n"
      exit 0
    }' </dev/null
}
