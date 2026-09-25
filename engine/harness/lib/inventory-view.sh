# felix inventory's human view: the rows lib/inventory.sh wrote, grouped for
# a person, what needs action first. --tsv, which the UI and the landing actor
# read, is the rows themselves and never passes through here.
#
# Per repository, first what was read: its default branch, where its PR facts
# came from, its sessions and the chip window. A later line of one name
# replaces an earlier one, so a list found unreadable while the rows were
# built (the chips) says so there. Then a group per headline, in _FI_ORDER,
# and "undecided, content not landed" for an item undecided only because a
# fact is unknown whose content is known not to be landed, listing every
# state it could not decide. A live item is counted live, and listed as well
# under question or blocked when it holds one: a session asking or stuck is
# not one to leave because another in the same directory is running. A row
# in a temporary directory that would be listed is listed after all of
# those, in the same order, its headline shown with its other states. Last,
# the counts: live, landed, orphans holding nothing unique, and items nothing
# was decided about but that a fact is unknown. A row of kind repo is none of
# these: it says a list was not read, or a fact about the whole repository,
# and the header says the same.

# The human view of $_FI_T/out, headed by $_FI_T/meta.
_fi_view() {
  printf 'felix inventory: read-only. It wrote nothing into a repository and fetched nothing; gh, if asked, only listed pull requests.\n'
  [ -s "$_FI_T/meta" ] || return 0
  awk -F'\t' -v order="${_FI_ORDER/ live / } undecided" '
    NR == FNR { r = $1; if (!(r in S)) { S[r] = 1; RP[++nr] = r }
      if (!((r, $2) in MV)) MK[r, ++mk[r]] = $2
      MV[r, $2] = $3; next }
    $1 == "repo" { next }
    { m = split($4, st, ","); h = st[1]; hi = 1; r = $2; ref = $3; if (index(ref, r "/") == 1) ref = substr(ref, length(r) + 2)
      if (h ~ /^unknown:/) { if ($7 !~ /(^|; )(on [^;]*; )?content (not|partly) on /) { U[r]++; next }; h = "undecided"; hi = 0 }
      if (h == "live") { LV[r]++; if ($4 ~ /(^|,)blocked(,|$)/) LB[r]++
        if (st[2] != "question" && st[2] != "blocked") next
        h = st[2]; hi = 2 }
      if (h == "landed") { LD[r]++; next }
      if (h == "orphan" && $7 ~ /^0 of / && $7 !~ /not read/ && ($7 !~ /ignored files hold/ || $7 ~ /; 0 of [0-9]+ ignored files hold/)) { OZ[r]++; next }
      # The states shown beside it: all but its headline, which the group of
      # temporary directories has no heading for, so there it leads them.
      tp = $7 ~ /(^|; )temp(;|$)/; a = (tp && hi) ? h : ""; u = ""
      for (j = 1; j <= m; j++) {
        if (j == hi) continue
        if (st[j] ~ /^unknown:/) u = u (u == "" ? "" : ",") substr(st[j], 9)
        else if (st[j] != "landed") a = a (a == "" ? "" : ",") st[j]
      }
      if (u != "") a = a (a == "" ? "" : "; ") "unknown: " u
      if (tp) { TN[r]++; h = "~" h }
      G[r, h] = G[r, h] sprintf("    %-8s %s%s\n             %s (%sh%s)\n", $1, ref, (a == "" ? "" : "  [" a "]"), $7, $6, \
        ($5 ~ /^(-|unknown)$/ ? "" : ", session " substr($5, 1, 8))); N[r, h]++ }
    END { n = split(order, O, " ")
      for (i = 1; i <= nr; i++) { r = RP[i]; printf "\n%s\n", r
        for (k = 1; k <= mk[r]; k++) printf "  %-9s %s\n", MK[r, k], MV[r, MK[r, k]]
        for (j = 1; j <= n; j++) if (N[r, O[j]]) printf "\n  %s  %d\n%s", (O[j] == "undecided" ? "undecided, content not landed" : O[j]), N[r, O[j]], G[r, O[j]]
        if (TN[r]) { printf "\n  in temporary directories  %d\n", TN[r]; for (j = 1; j <= n; j++) printf "%s", G[r, "~" O[j]] }
        printf "\n  live %d%s, landed %d, orphans holding nothing unique %d, nothing decided but unknown %d\n", LV[r], \
          (LB[r] ? " (" LB[r] " blocked on a tool call)" : ""), LD[r], OZ[r], U[r] } }' "$_FI_T/meta" "$_FI_T/out"
}
