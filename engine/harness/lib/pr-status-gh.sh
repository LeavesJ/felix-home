# The stuck-PR page, GitHub half: what gh says about the open pull requests of a
# repository, and about the account's Actions minutes (lib/pr-status.sh).
#
# gh is asked `pr list` once per repository and `api` (a GET) for the budget,
# and nothing else. It keeps state of its own (a device id on first use, update
# checks), so its state and cache directories point into the page's scratch
# directory, which the run removes; its configuration, which holds how it is
# logged in, is left alone. Its output is flattened by the inventory's own
# reader (_FI_JSON, lib/inventory-gh.sh, which the caller sources) and cut into
# two tables by the awk below: one row per pull request, and one row per
# changed file. A time is turned into an epoch by the inventory's _FI_EPOCH.
#
# Bash 3.2. LC_ALL=C on every text tool; digit brackets spelled out.

# gh, in directory $1, with its own state and cache in the scratch.
_ps_ghc() {   # DIR ARGS...
  local d="$1"; shift
  ( cd "$d" 2>/dev/null || exit 1
    GH_NO_UPDATE_NOTIFIER=1 GH_PROMPT_DISABLED=1 XDG_STATE_HOME="$_PS_T/gh-state" XDG_CACHE_HOME="$_PS_T/gh-cache" gh "$@" )
}

# A slug is owner/name: one slash, nothing else that splits it.
_ps_slug_ok() {
  local tab; tab="$(printf '\t')"
  case "${1:-}" in ""|*" "*|*"$tab"*|*$'\r'*|*$'\n'*|/*|*/|*/*/*) return 1 ;; */*) return 0 ;; esac
  return 1
}

# The first line of a file, tabs and carriage returns as spaces, cut at 120
# characters; a cut never leaves half of a UTF-8 character behind.
_ps_err1() {   # FILE
  LC_ALL=C sed -n 1p "$1" 2>/dev/null | LC_ALL=C tr '\t\r' '  ' | LC_ALL=C awk '{
    s = substr($0, 1, 120); c = substr($0, 121, 1)
    if (c >= "\200" && c < "\300") { while (s != "" && substr(s, length(s)) >= "\200" && substr(s, length(s)) < "\300") s = substr(s, 1, length(s) - 1)
      if (s != "" && substr(s, length(s)) >= "\300") s = substr(s, 1, length(s) - 1) }
    print s }'
}

# gh's JSON with its escapes decoded where the page has to tell them apart,
# before the shared flattener (which turns \t, \n and \r into spaces and leaves
# \\ doubled) reads it. A control character in a string (the escapes \b \f \n
# \r \t, and \u00XX below 0x20 or 0x7f) becomes byte 001, a backslash byte 002,
# and an escaped printable ASCII character the character itself, so that a
# changed path holding a tab is seen as holding a byte outside printable ASCII
# and a path holding a backslash is not. Any other \uXXXX is outside printable
# ASCII too. \" stays for the flattener.
# shellcheck disable=SC2016
_PS_UNESC='BEGIN { c1 = sprintf("%c", 1); c2 = sprintf("%c", 2); hx = "0123456789abcdef" }
  { gsub(/\\\\/, c2); gsub(/\\[nrtbf]/, c1); gsub(/\\\//, "/")
    while (match($0, /\\u[0123456789abcdefABCDEF][0123456789abcdefABCDEF][0123456789abcdefABCDEF][0123456789abcdefABCDEF]/)) {
      h = tolower(substr($0, RSTART + 2, 4)); r = c1
      if (substr(h, 1, 2) == "00") {
        v = (index(hx, substr(h, 3, 1)) - 1) * 16 + (index(hx, substr(h, 4, 1)) - 1)
        if (v == 34) r = "\\\""; else if (v == 92) r = c2; else if (v >= 32 && v < 127) r = sprintf("%c", v) }
      $0 = substr($0, 1, RSTART - 1) r substr($0, RSTART + RLENGTH) }
    print }'

# One row per pull request, from the flattened list: number, title, head
# branch, head SHA, base, draft, cross-repository, author, labels (lower case,
# each preceded and followed by byte 003, which no label name holds, and a
# single 003 for none), mergeable, mergeStateStatus,
# updatedAt as an epoch, files listed, checks, failed, unfinished, and the names
# of the failed and of the unfinished ones. Tabs and carriage returns in a value
# are spaces. A check's result is its conclusion, else its state, else its
# status; SUCCESS, SKIPPED and NEUTRAL are green and FAILURE, CANCELLED,
# TIMED_OUT, ACTION_REQUIRED, STARTUP_FAILURE, STALE and ERROR failed, and
# anything else has not finished. The files table is number, path, deleted lines.
# shellcheck disable=SC2016
_PS_TABLES='function nz(s) { return s == "" ? "-" : s }
  BEGIN { pf = ENVIRON["PS_PF"]; ff = ENVIRON["PS_FF"]; bs = sprintf("%c", 92); c1 = sprintf("%c", 1); c2 = sprintf("%c", 2); sep = sprintf("%c", 3) }
  function un(x, keep,   k, e) { e = ""; k = 0
    while ((k = index(x, c2)) > 0) x = substr(x, 1, k - 1) bs substr(x, k + 1)
    if (!keep) gsub(c1, " ", x)
    return x }
  { i = $1; p = $2; v = $3; gsub(/[\t\r]/, " ", v); v = un(v, p ~ /^files[.][0123456789]+[.]path$/)
    if (!(i in S)) { S[i] = 1; O[++n] = i }
    if (p == "number") NUM[i] = v
    else if (p == "title") TI[i] = v
    else if (p == "headRefName") HB[i] = v
    else if (p == "headRefOid") HO[i] = v
    else if (p == "baseRefName") BS[i] = v
    else if (p == "isDraft") DR[i] = v
    else if (p == "isCrossRepository") CR[i] = v
    else if (p == "author.login") AU[i] = v
    else if (p == "mergeable") MG[i] = v
    else if (p == "mergeStateStatus") MS[i] = v
    else if (p == "updatedAt") UP[i] = v
    else if (p ~ /^labels[.][0123456789]+[.]name$/) LB[i] = LB[i] (LB[i] == "" ? sep : "") tolower(v) sep
    else if (p ~ /^statusCheckRollup[.][0123456789]+[.]/) { split(p, k, "."); CK[i, k[2], k[3]] = v; if (k[2] + 1 > CN[i]) CN[i] = k[2] + 1 }
    else if (p ~ /^files[.][0123456789]+[.]/) { split(p, k, "."); if (k[3] == "path") FP[i, k[2]] = v; else if (k[3] == "deletions") FD[i, k[2]] = v
      if (k[2] + 1 > FC[i]) FC[i] = k[2] + 1 } }
  END {
    for (x = 1; x <= n; x++) { i = O[x]; if (NUM[i] !~ /^[0123456789]+$/) continue
      nfail = 0; npend = 0; failn = ""; pendn = ""
      for (c = 0; c < CN[i]; c++) {
        r = CK[i, c, "conclusion"]; if (r == "") r = CK[i, c, "state"]; if (r == "") r = CK[i, c, "status"]; r = toupper(r)
        nm = CK[i, c, "name"]; if (nm == "") nm = CK[i, c, "context"]; if (nm == "") nm = "check " c
        if (r ~ /^(FAILURE|CANCELLED|TIMED_OUT|ACTION_REQUIRED|STARTUP_FAILURE|STALE|ERROR)$/) { nfail++; failn = failn (failn == "" ? "" : ", ") nm " " r }
        else if (r !~ /^(SUCCESS|SKIPPED|NEUTRAL)$/) { npend++; pendn = pendn (pendn == "" ? "" : ", ") nm " " (r == "" ? "no result" : r) } }
      u = ep(UP[i])
      printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%d\t%d\t%d\t%d\t%s\t%s\n", NUM[i], nz(TI[i]), nz(HB[i]), nz(HO[i]), nz(BS[i]), nz(DR[i]), nz(CR[i]), \
        nz(AU[i]), (LB[i] == "" ? sep : LB[i]), nz(MG[i]), nz(MS[i]), u, FC[i] + 0, CN[i] + 0, nfail, npend, nz(failn), nz(pendn) > pf
      for (c = 0; c < FC[i]; c++) if ((i, c) in FP) printf "%s\t%s\t%d\n", NUM[i], FP[i, c], FD[i, c] + 0 > ff } }'

# gh's open pull requests of SLUG, asked from directory $1, into $3/prs (sorted
# by number) and $3/files. The state is _PS_GHST (read, none, truncated or
# unread), with the reason or the count in _PS_GHWHY; status 1 when unread.
_ps_gh_list() {   # DIR SLUG W
  local d="$1" slug="$2" w="$3" rc first n k
  : > "$w/prs"; : > "$w/files"; _PS_GHST=unread; _PS_GHN=0
  if [ "${_PS_NOGH:-0}" = 1 ]; then _PS_GHWHY="--no-gh: gh was not asked"; return 1; fi
  command -v gh >/dev/null 2>&1 || { _PS_GHWHY="gh not found"; return 1; }
  _ps_slug_ok "$slug" || slug=""
  _ps_ghc "$d" pr list ${slug:+-R "$slug"} --state open --limit 1000 \
    --json number,title,headRefName,headRefOid,baseRefName,isDraft,isCrossRepository,author,labels,mergeable,mergeStateStatus,statusCheckRollup,files,updatedAt \
    > "$w/gh.json" 2> "$w/gh.err"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    _PS_GHWHY="$(_ps_err1 "$w/gh.err")"; [ -n "$_PS_GHWHY" ] || _PS_GHWHY="gh pr list exited $rc with no output"
    return 1
  fi
  first="$(LC_ALL=C awk 'NF { print substr($0, 1, 1); exit }' "$w/gh.json" 2>/dev/null)"
  if [ "$first" != "[" ]; then _PS_GHWHY="gh pr list answered something that is not a list"; return 1; fi
  LC_ALL=C awk "$_PS_UNESC" "$w/gh.json" 2>/dev/null | LC_ALL=C awk "$_FI_JSON" 2>/dev/null \
    | PS_PF="$w/prs.u" PS_FF="$w/files" LC_ALL=C awk -F'\t' "$_FI_EPOCH"$'\n'"$_PS_TABLES" 2>/dev/null
  [ -e "$w/prs.u" ] || : > "$w/prs.u"
  LC_ALL=C sort -t "$(printf '\t')" -k1,1n "$w/prs.u" > "$w/prs" 2>/dev/null
  n="$(LC_ALL=C awk 'END { print NR }' "$w/prs")"
  _PS_GHN="$n"
  # An empty array flattens to nothing, so a list that left out the checks or the
  # files could not be told from one whose pull requests have none: unread.
  if [ "$n" -gt 0 ]; then
    for k in statusCheckRollup files; do
      [ "$(LC_ALL=C grep -c "\"$k\"" "$w/gh.json" 2>/dev/null)" -gt 0 ] && continue
      : > "$w/prs"; : > "$w/files"; _PS_GHN=0
      _PS_GHWHY="gh pr list left out $k"; return 1
    done
  fi
  if [ "$n" -eq 0 ]; then
    # Only an empty list is "none": a list whose objects held no number is unread.
    if [ "$(LC_ALL=C tr -d ' \t\r\n' < "$w/gh.json" 2>/dev/null)" != "[]" ]; then
      _PS_GHWHY="gh pr list answered a list with no pull request numbers in it"; return 1
    fi
    _PS_GHST=none; _PS_GHWHY="no open pull requests"
  elif [ "$n" -ge 1000 ]; then _PS_GHST=truncated; _PS_GHWHY="$n listed, gh's limit: the list may be incomplete"
  else _PS_GHST=read; _PS_GHWHY="$n open pull requests"; fi
  return 0
}

# The account's Actions minutes this month, one gh api GET (spec 4.4):
# users/<owner>/settings/billing/actions, and orgs/<owner>/... when that answers
# 404 (an organisation). States budget as _PS_BST and _PS_BWHY. On 2026-10-13 the
# endpoint answered 404 for a user, because the token lacks the user scope;
# widening it is the founder's, so the row says so and nothing asks him.
_ps_budget() {   # OWNER DIR
  local o="$1" d="$2" used inc e w="$_PS_T/budget"
  _PS_BST=unread
  if [ "${_PS_NOGH:-0}" = 1 ]; then _PS_BWHY="--no-gh: gh was not asked"; return 1; fi
  command -v gh >/dev/null 2>&1 || { _PS_BWHY="gh not found"; return 1; }
  [ -n "$o" ] || { _PS_BWHY="the repository names no owner"; return 1; }
  # One GET for a user's account. Only a 404 (an organisation's account has no
  # such path, and a token without the user scope gets one too) asks the orgs
  # path as well, and only a 404 says the token may lack the scope.
  if ! _ps_ghc "$d" api "users/$o/settings/billing/actions" > "$w.json" 2> "$w.err"; then
    e="$(_ps_err1 "$w.err")"; [ -n "$e" ] || e="gh api exited with no output"
    case "$e" in *404*|*"Not Found"*)
      if ! _ps_ghc "$d" api "orgs/$o/settings/billing/actions" > "$w.json" 2> "$w.err2"; then
        _PS_BWHY="$e; the token may lack the user scope, and widening it is the founder's"; return 1
      fi ;;
    *) _PS_BWHY="$e"; return 1 ;;
    esac
  fi
  used="$(LC_ALL=C sed -n 's/.*"total_minutes_used"[[:space:]]*:[[:space:]]*\([0123456789.]*\).*/\1/p' "$w.json" 2>/dev/null | LC_ALL=C sed -n 1p)"
  inc="$(LC_ALL=C sed -n 's/.*"included_minutes"[[:space:]]*:[[:space:]]*\([0123456789.]*\).*/\1/p' "$w.json" 2>/dev/null | LC_ALL=C sed -n 1p)"
  if [ -z "$used" ] || [ -z "$inc" ]; then _PS_BWHY="the billing answer holds no minutes used or included"; return 1; fi
  _PS_BST=read; _PS_BWHY="$used of $inc minutes used this month"
  return 0
}

# The repository's default branch from GitHub, for a project whose checkout is
# not at hand (the queue): one gh api GET. Prints it, or nothing.
_ps_gh_default() {   # SLUG DIR
  _ps_ghc "$2" api "repos/$1" 2>/dev/null \
    | LC_ALL=C sed -n 's/.*"default_branch"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | LC_ALL=C sed -n 1p
}
