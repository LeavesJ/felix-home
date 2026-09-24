# felix inventory's GitHub facts: what gh says about a repository's pull
# requests, for lib/inventory.sh, which sources nothing else about GitHub.
#
# gh is asked `pr list` twice and nothing else, in the repository, with -R
# where origin names a host, so it asks the repository origin points to. It
# keeps state of its own (a device id on first use, update checks), so its
# state and cache directories point into the scratch, where they are removed
# with it; its configuration, which holds how it is logged in, is left alone.
# A list of 1000, gh's limit here, may not be every PR: then a pushed branch
# with none seen is unknown, not unproposed. No JSON parser: the flattener
# below reads gh's output one character at a time, as every awk can.

# PR facts from gh into $T/prs, one line per PR: number state head oid updated
# mergeable labels ready; and $T/prh, per head: the open PRs in the landing
# actor's words, then the newest PR's number and state. Status 1, with the
# reason in _FI_GHSTATE, when there are none to be had.
_fi_gh() {
  local url r="" e
  : > "$T/prs"; : > "$T/prh"; _FI_GHSTATE="unknown (--no-gh)"; _FI_GHTRUNC=0; _FI_GHN=0
  [ "$_FI_GH" = 1 ] || return 1
  command -v gh >/dev/null 2>&1 || { _FI_GHSTATE="unknown (gh not found)"; return 1; }
  url="$(_fi_git -C "$1" config --get remote.origin.url 2>/dev/null)"
  case "$url" in git@*:*/*) r="${url#git@}"; r="${r%%:*}/${r#*:}" ;; ssh://*|https://*|http://*) r="${url#*://}"; r="${r#*@}" ;; esac
  r="${r%.git}"; case "$r" in github.com/*/*) r="${r#github.com/}" ;; */*/*) ;; *) r="" ;; esac
  _fi_ghc "$1" pr list ${r:+-R "$r"} --state all --limit 1000 --json number,state,headRefName,headRefOid,updatedAt > "$T/all.json" 2> "$T/gh.err" \
    && _fi_ghc "$1" pr list ${r:+-R "$r"} --state open --limit 1000 --json number,labels,mergeable,statusCheckRollup > "$T/open.json" 2>> "$T/gh.err" \
    || { e="$(head -1 "$T/gh.err" | awk '{ s = substr($0, 1, 120); while (s != "" && substr(s, length(s)) >= "\200") s = substr(s, 1, length(s) - 1); print s }')"
         _FI_GHSTATE="unknown (gh failed: ${e:-no output})"; return 1; }
  { awk "$_FI_JSON" "$T/all.json"; printf '\001\n'; awk "$_FI_JSON" "$T/open.json"; } | awk -F'\t' "$_FI_EPOCH"'
    $0 == "\001" { o = 1; next }
    !o { A[$1, $2] = $3; if ($2 == "number") N[++n] = $1; next }
    $2 == "number" { ON[$1] = $3 } $2 == "mergeable" { OM[$1] = $3 }
    $2 ~ /^labels[.][0-9]+[.]name$/ { OL[$1] = OL[$1] "," $3 }
    $2 ~ /^statusCheckRollup[.][0-9]+[.](context|state)$/ { split($2, k, "."); S[$1, k[2], k[3]] = $3; if (k[2] >= SN[$1]) SN[$1] = k[2] + 1 }
    END {
      for (j in ON) { r = 0; for (i = 0; i < SN[j]; i++) if (S[j, i, "context"] == "felix/ready" && S[j, i, "state"] == "SUCCESS") r = 1
        X[ON[j]] = (OM[j] == "" ? "-" : OM[j]) "\t" (OL[j] == "" ? "-" : substr(OL[j], 2)) "\t" (r ? "ready" : "-") }
      for (i = 1; i <= n; i++) { x = N[i]; m = A[x, "number"]
        printf "%s\t%s\t%s\t%s\t%s\t%s\n", m, A[x, "state"], A[x, "headRefName"], (A[x, "headRefOid"] == "" ? "-" : A[x, "headRefOid"]), \
          ep(A[x, "updatedAt"]), ((m in X) ? X[m] : "-\t-\t-") } }' > "$T/prs"
  awk -F'\t' -v now="$_FI_NOW" '
    $2 == "OPEN" { v = $8 == "ready" ? "ready" : ""; if ($7 ~ /(^|,)felix:hold(,|$)/) v = v ",hold"
      if ($7 ~ /(^|,)(felix:founder|needs-founder)(,|$)/) v = v ",founder"; if ($6 == "CONFLICTING") v = v ",conflicting"
      sub(/^,/, "", v); O[$3] = O[$3] (O[$3] == "" ? "" : ", ") "#" $1 " open" (v == "" ? "" : " " v) ($5 ~ /^[0-9]+$/ ? ", " int((now - $5) / 3600) "h since update" : "") }
    $1 + 0 > NUM[$3] + 0 { NUM[$3] = $1; ST[$3] = $2 }
    END { for (h in NUM) printf "%s\t%s\t%s\t%s\n", h, (h in O ? O[h] : "-"), NUM[h], ST[h] }' "$T/prs" > "$T/prh"
  _FI_GHN="$(awk 'END { print NR }' "$T/prs")"
  _FI_GHSTATE="read with gh${r:+ from $r}"
  [ "$_FI_GHN" -lt 1000 ] || { _FI_GHTRUNC=1; _FI_GHSTATE="$_FI_GHSTATE, which listed its limit of 1000: older PRs are not seen, so a pushed branch with none is unknown"; }
  return 0
}
# gh, in directory $1, with its own state and cache in the scratch.
_fi_ghc() {
  ( cd "$1" && shift && GH_NO_UPDATE_NOTIFIER=1 GH_PROMPT_DISABLED=1 XDG_STATE_HOME="$_FI_T/gh-state" XDG_CACHE_HOME="$_FI_T/gh-cache" gh "$@" )
}
# A JSON document flattened, one line per value: top-level index, path, value.
# shellcheck disable=SC2016
_FI_JSON='{ s = s $0 "\n" }
  END { n = split(s, C, ""); d = 0; key = 0
    for (i = 1; i <= n; i++) { c = C[i]
      if (c == "{" || c == "[") { d++; T[d] = c; K[d] = c == "[" ? 0 : ""; key = c == "{"; continue }
      if (c == "}" || c == "]") { d--; key = 0; continue }
      if (c == ",") { if (T[d] == "[") { K[d]++; key = 0 } else key = 1; continue }
      if (c == ":") { key = 0; continue }
      if (index(" \n\t\r", c)) continue
      if (c == "\"") { for (j = i + 1; j <= n && C[j] != "\""; j++) if (C[j] == "\\") j++; v = substr(s, i + 1, j - i - 1); i = j
        gsub(/\\"/, "\"", v); gsub(/\\[nrt]/, " ", v); gsub(/\t/, " ", v) }
      else { for (j = i; j <= n && !index(",}] \n\t\r", C[j]); j++) ; v = substr(s, i, j - i); i = j - 1 }
      if (key) { K[d] = v; continue }
      p = ""; for (k = 2; k <= d; k++) p = p (k > 2 ? "." : "") K[k]
      if (d >= 1) print K[1] "\t" p "\t" v } }'
# An ISO 8601 time as an epoch, by arithmetic every awk has.
# shellcheck disable=SC2016
_FI_EPOCH='function ep(t,    y, mo, e, z) {
    if (t !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/) return "-"
    y = substr(t, 1, 4) + 0; mo = substr(t, 6, 2) + 0; if (mo <= 2) { y--; mo += 12 }
    e = 365 * y + int(y / 4) - int(y / 100) + int(y / 400) + int((153 * (mo - 3) + 2) / 5) + substr(t, 9, 2) - 719469
    e = e * 86400 + substr(t, 12, 2) * 3600 + substr(t, 15, 2) * 60 + substr(t, 18, 2)
    z = substr(t, 20); sub(/^[.][0-9]+/, "", z)
    if (z ~ /^[+-][0-9][0-9]:?[0-9][0-9]$/) { gsub(/:/, "", z); e -= (substr(z, 1, 1) == "-" ? -1 : 1) * (substr(z, 2, 2) * 3600 + substr(z, 4, 2) * 60) }
    return e }'
