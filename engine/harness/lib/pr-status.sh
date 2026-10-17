# The stuck-PR page: felix land --prs and --queue.
#
# Why each open pull request has not landed, and who has to act. The landing
# design asked for it (audits/2026-09-23-landing-actor/design.md section 3),
# the contract of land on green left it to this step, and the spec is
# audits/2026-10-01-report-v5-review/specs/stuck-pr/spec-v2.md. Nothing here
# acts: the page writes to no repository, to none of the tick's files and posts
# nothing to GitHub. It reads origin/main as it stands (never a fetch, never
# merge-tree --write-tree, never a checkout) and says how old the last fetch is.
# gh is asked `pr list` and `api` (GET) and nothing else, launchctl `print`
# and nothing else, and gh keeps its state in a scratch directory that the run
# removes.
#
# UNREAD IS UNKNOWN, NEVER ZERO. A fact that could not be read is said so, in a
# source row and in the state of every pull request that depended on it. "No
# open pull requests" is said only when gh answered an empty list.
#
# It sits outside the lib/land*.sh trust-base glob on purpose, as lib/green-tick.sh
# does: it holds no rule, only the order in which the existing ones are asked.
# The GitHub reader is lib/pr-status-gh.sh and the deciding half is
# lib/pr-status-state.sh. Sourced by felix_land (lib/green-tick.sh), which has
# the tick's constants (_GT_MAIN) and functions (_gt_holder_live, _gt_direction,
# _gt_job_state) and the library of the land table and of the escape rules.
#
# Bash 3.2. LC_ALL=C on every text tool; digit brackets spelled out.

. "${BASH_SOURCE[0]%/*}/inventory-gh.sh" || return 1
. "${BASH_SOURCE[0]%/*}/pr-status-gh.sh" || return 1
. "${BASH_SOURCE[0]%/*}/pr-status-state.sh" || return 1

# felix land --prs [--tsv] [--repo DIR] [--no-gh] | --queue [--tsv]. Status 1
# when the arguments are anything else; --repo once, and only on --prs.
_ps_args() {   # --prs|--queue ARGS...
  local seen=0
  _PS_MODE="${1#--}"; shift
  _PS_TSV=0; _PS_NOGH=0; _PS_REPO=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --tsv) _PS_TSV=1 ;;
      --no-gh) [ "$_PS_MODE" = prs ] || return 1; _PS_NOGH=1 ;;
      --repo) [ "$_PS_MODE" = prs ] && [ "$seen" = 0 ] && [ $# -ge 2 ] && [ -n "$2" ] || return 1
              _PS_REPO="$2"; seen=1; shift ;;
      *) return 1 ;;
    esac
    shift
  done
  return 0
}

# A source row: REF, STATE and DETAIL in FILE, one line, no tab or newline.
_ps_srow() {   # FILE REF STATE DETAIL
  printf '%s\t%s\t%s\n' "$2" "$3" "$(printf '%s' "$4" | LC_ALL=C tr '\t\r\n' '   ')" > "$1"
}

# How long ago the repository was last fetched, from FETCH_HEAD's mtime.
_ps_fetch_age() {   # DIR
  local gd f mt s
  gd="$(git -C "$1" rev-parse --git-common-dir 2>/dev/null)" || { printf 'the last fetch is not recorded'; return 0; }
  case "$gd" in /*) ;; *) gd="$1/$gd" ;; esac
  f="$gd/FETCH_HEAD"
  [ -f "$f" ] || { printf 'the last fetch is not recorded'; return 0; }
  mt="$(stat -c %Y "$f" 2>/dev/null || stat -f %m "$f" 2>/dev/null)"
  case "$mt" in ""|*[!0123456789]*) printf 'the last fetch is not recorded'; return 0 ;; esac
  s=$(( $(date +%s) - mt )); [ "$s" -ge 0 ] || s=0
  if [ "$s" -lt 3600 ]; then printf 'last fetch %s min ago' $(( s / 60 ))
  elif [ "$s" -lt 172800 ]; then printf 'last fetch %s h ago' $(( s / 3600 ))
  else printf 'last fetch %s days ago' $(( s / 86400 )); fi
}

# origin/main and the default branch (spec 4.2): the target of origin/HEAD, else
# main when refs/remotes/origin/main exists. Sets _PS_MAIN and _PS_DEF. With no
# local checkout (the queue) the default branch is GitHub's.
_ps_origin() {   # DIR SLUG W
  local d="$1" slug="$2" w="$3" ref
  _PS_MAIN=""; _PS_DEF=""
  if [ -z "$d" ]; then
    if [ "${_PS_NOGH:-0}" != 1 ] && _ps_slug_ok "$slug"; then _PS_DEF="$(_ps_gh_default "$slug" "$FELIX_HOME_DIR")"; fi
    if [ -n "$_PS_DEF" ]; then _ps_srow "$w/s.origin" origin read "no local checkout; the default branch $_PS_DEF is GitHub's"
    else _ps_srow "$w/s.origin" origin unread "no local checkout; the default branch is not read"; fi
    return 0
  fi
  _PS_MAIN="$(git -C "$d" rev-parse --verify --quiet "$_GT_MAIN^{commit}" 2>/dev/null)" || _PS_MAIN=""
  ref="$(git -C "$d" symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null)" || ref=""
  case "$ref" in refs/remotes/origin/?*) _PS_DEF="${ref#refs/remotes/origin/}" ;; esac
  [ -n "$_PS_DEF" ] || [ -z "$_PS_MAIN" ] || _PS_DEF=main
  if [ -z "$_PS_MAIN" ]; then
    _ps_srow "$w/s.origin" origin unread "no origin/main${_PS_DEF:+; origin/HEAD names $_PS_DEF}; the default branch is not read, and no ledger row can be on the current main"
    return 0
  fi
  _ps_srow "$w/s.origin" origin read "origin/main ${_PS_MAIN%"${_PS_MAIN#???????}"}, default branch ${_PS_DEF:-not read}, $(_ps_fetch_age "$d")"
}

# The tick's own state, as felix land --status reads it, and whether a tick
# holds the lock (spec 4.3).
_ps_lander() {   # NAME LANDDIR W
  local st=not-live det first
  _gt_job_state "$1" "$2"
  _gt_holder_live "$2/lock" && st=live
  det="installed $_GT_INS; loaded $_GT_LOD; paused $_GT_PAU"
  if [ "$_GT_PAU" = yes ]; then
    first="$(LC_ALL=C sed -n 1p "$2/paused" 2>/dev/null | LC_ALL=C tr '\t\r' '  ')"
    det="$det: ${first:-no reason given}"
  fi
  _ps_srow "$3/s.lander" lander "$st" "$det"
}

# Everything one repository's page rests on, into $5: its sources (s.*) and its
# rows. DIR is the local checkout, empty when there is none.
_ps_collect() {   # DIR PROJDIR SLUG NAME W
  local d="$1" pd="$2" slug="$3" name="$4" w="$5" owner=""
  _PS_PROJDIR="$pd"; mkdir -p "$w"
  _ps_slug_ok "$slug" && owner="${slug%%/*}"
  _ps_origin "$d" "$slug" "$w"
  _ps_land "$pd" "$d" "$w"
  _ps_srow "$w/s.land" land "$_PS_LAND" "$_PS_LANDWHY"
  _ps_ledger "$(felix_mem_dir "$name")/land/ledger.tsv" "$w"
  _ps_srow "$w/s.ledger" ledger "$_PS_LEDGER" "$_PS_LEDGERWHY"
  : > "$w/rows"
  if _ps_gh_list "${d:-$FELIX_HOME_DIR}" "$slug" "$w"; then
    _ps_pathattr "$w"
    _ps_decide "$w" "$owner" "$_PS_DEF" "$_PS_MAIN"
  fi
  _ps_srow "$w/s.gh" gh "$_PS_GHST" "$_PS_GHWHY"
}

# --- the pages -----------------------------------------------------------------
# A pull request's line: #N state title (cut at 60): detail, then its flags.
# shellcheck disable=SC2016
_PS_LINE='function line(   t, f) { t = substr($6, 1, 60); f = $3; gsub(/^,/, "", f); gsub(/,/, ", ", f)
    return "#" $1 " " $2 " " t ": " $5 (f == "" ? "" : " (flags: " f ")") }'

# The groups of the text page, founder first (spec 6.2).
_ps_groups() {   # ROWS
  LC_ALL=C awk -F'\t' "$_PS_LINE"$'\n''
    { G[$4] = G[$4] + 1; L[$4, G[$4]] = line(); C[$2] = C[$2] + 1; N++ }
    END {
      split("founder session lander nobody unknown", g, " ")
      split("needs the founder|needs a session|waits for the lander|waits for nobody|is unknown", h, "|")
      for (i = 1; i <= 5; i++) if (G[g[i]] > 0) { print h[i] " (" G[g[i]] "):"; for (j = 1; j <= G[g[i]]; j++) print L[g[i], j] }
      split("founder held needs-session red needs-attended refused unready ready pending stacked outside unknown", s, " ")
      for (i = 1; i <= 12; i++) if (C[s[i]] > 0) t = t (t == "" ? "" : ", ") s[i] " " C[s[i]]
      print N " open pull requests: " t }' "$1"
}

_ps_prs_text() {   # SLUG NAME W
  local w="$3" ref st det
  printf 'felix land --prs: %s (project %s)\n' "$1" "$2"
  for ref in gh land ledger lander budget origin; do
    IFS=$'\t' read -r ref st det < "$w/s.$ref"
    printf '  %-8s %s: %s\n' "$ref" "$st" "$det"
  done
  case "$(LC_ALL=C cut -f2 "$w/s.gh")" in
    unread) printf 'pull requests not read: %s\n' "$(LC_ALL=C cut -f3 "$w/s.gh")" ;;
    none) printf 'no open pull requests\n' ;;
    truncated) printf 'the list may be incomplete: %s\n' "$(LC_ALL=C cut -f3 "$w/s.gh")"; _ps_groups "$w/rows" ;;
    *) _ps_groups "$w/rows" ;;
  esac
}

_ps_prs_tsv() {   # SLUG W
  local ref
  for ref in gh land ledger lander budget origin; do
    LC_ALL=C awk -F'\t' -v r="$1" '{ printf "source\t%s\t%s\t%s\t-\t-\t-\t%s\n", r, $1, $2, $3 }' "$2/s.$ref"
  done
  LC_ALL=C awk -F'\t' -v r="$1" '{ gsub(/[\t\r\n]/, " ", $5); printf "pr\t%s\t#%s\t%s%s\t%s\t%s\t%s\t%s\n", r, $1, $2, $3, $4, $7, $8, $5 }' "$2/rows"
}

_ps_prs_cmd() {
  local d="${_PS_REPO:-$PWD}" dir proj name slug w landd owner repo
  [ -d "$d" ] || die "no such directory: $d" 1
  d="$(CDPATH='' cd -- "$d" 2>/dev/null && pwd -P)" || die "cannot enter $d" 1
  dir="$(git -C "$d" rev-parse --show-toplevel 2>/dev/null)" && [ -n "$dir" ] || die "no repository holds $d" 1
  proj="$(felix_resolve_project "$d" "$FELIX_HOME_DIR")" && [ -n "$proj" ] || die "no project governs $d: add a .felix file naming one, or declare remote_match in a project.json" 1
  name="${proj##*/}"; landd="$(felix_mem_dir "$name")/land"
  slug="$(felix_repo_slug "$dir" 2>/dev/null)"; repo="$slug"
  _ps_slug_ok "$slug" || repo="${dir##*/}"
  owner=""; _ps_slug_ok "$slug" && owner="${slug%%/*}"
  _ps_scratch || return 1
  w="$_PS_T/p"
  _ps_collect "$dir" "$proj" "$slug" "$name" "$w"
  _ps_lander "$name" "$landd" "$w"
  if _ps_budget "$owner" "$dir"; then :; fi
  _ps_srow "$w/s.budget" budget "$_PS_BST" "$_PS_BWHY"
  if [ "$_PS_TSV" = 1 ]; then _ps_prs_tsv "$repo" "$w"; else _ps_prs_text "$repo" "$name" "$w"; fi
  _ps_scratch_gone
  return 0
}

# The scratch directory: gh's state and cache live in it, and the run removes it
# whichever way it ends.
_ps_scratch() {
  _PS_T="$(mktemp -d "${TMPDIR:-/tmp}/felix-prs.XXXXXX" 2>/dev/null)" || { printf 'felix: could not make a scratch directory under %s\n' "${TMPDIR:-/tmp}" >&2; return 1; }
  trap 'rm -rf "$_PS_T"' EXIT
  return 0
}
_ps_scratch_gone() { rm -rf "$_PS_T"; trap - EXIT; }

# --- the queue ---------------------------------------------------------------------
# The founder's queue: the pull requests in state founder, for every project in
# the home whose project.json names a remote_match. Each project is read from
# its own repository, so no pull request is listed under two (spec 6.3). A
# project whose checkout is the home is read as --prs reads it; another is read
# from GitHub alone, which can say its default branch and not its fetch.
_ps_queue_cmd() {
  local meta pd name rm slug dir hs n=0 w nf nu ref st det tot=0 LC_ALL=C
  _ps_scratch || return 1
  : > "$_PS_T/q.src"; : > "$_PS_T/q.pr"; : > "$_PS_T/q.txt"
  hs="$(felix_repo_slug "$FELIX_HOME_DIR" 2>/dev/null | LC_ALL=C tr 'A-Z' 'a-z')"
  for meta in "$FELIX_HOME_DIR"/projects/*/project.json; do
    [ -f "$meta" ] || continue
    rm="$(felix_json_str "$meta" remote_match)"; [ -n "$rm" ] || continue
    pd="${meta%/project.json}"; name="${pd##*/}"
    slug="${rm#https://}"; slug="${slug#http://}"; slug="${slug#git@}"; slug="${slug#github.com[:/]}"; slug="${slug%.git}"
    w="$_PS_T/q$n"; n=$(( n + 1 ))
    if _ps_slug_ok "$slug"; then
      dir=""
      if [ "$(printf '%s' "$slug" | LC_ALL=C tr 'A-Z' 'a-z')" = "$hs" ] && git -C "$FELIX_HOME_DIR" rev-parse --show-toplevel >/dev/null 2>&1; then
        dir="$(git -C "$FELIX_HOME_DIR" rev-parse --show-toplevel 2>/dev/null)"
      fi
      _ps_collect "$dir" "$pd" "$slug" "$name" "$w"
    else
      slug="$rm"; mkdir -p "$w"; : > "$w/rows"
      _ps_srow "$w/s.gh" gh unread "remote_match $rm is not an owner/name slug"
    fi
    IFS=$'\t' read -r ref st det < "$w/s.gh"
    printf 'source\t%s\tgh\t%s\t-\t-\t-\t%s\n' "$slug" "$st" "$det" >> "$_PS_T/q.src"
    LC_ALL=C awk -F'\t' -v r="$slug" '$2 == "founder" { gsub(/[\t\r\n]/, " ", $5); printf "pr\t%s\t#%s\t%s%s\t%s\t%s\t%s\t%s\n", r, $1, $2, $3, $4, $7, $8, $5 }' "$w/rows" >> "$_PS_T/q.pr"
    nf="$(LC_ALL=C awk -F'\t' '$2 == "founder" { n++ } END { print n + 0 }' "$w/rows")"
    nu="$(LC_ALL=C awk -F'\t' '$2 == "unknown" { n++ } END { print n + 0 }' "$w/rows")"
    tot=$(( tot + nf ))
    if [ "$st" = unread ]; then printf '%s: not read: %s\n' "$name" "$det" >> "$_PS_T/q.txt"
    elif [ "$nf" -eq 0 ]; then
      printf '%s: no founder entries%s\n' "$name" "$([ "$nu" -eq 0 ] || printf ' (%s pull requests are unknown, not zero)' "$nu")" >> "$_PS_T/q.txt"
    else
      printf '%s: %s founder entries%s\n' "$name" "$nf" "$([ "$nu" -eq 0 ] || printf ' (and %s unknown)' "$nu")" >> "$_PS_T/q.txt"
      LC_ALL=C awk -F'\t' "$_PS_LINE"$'\n'' $2 == "founder" { print line() }' "$w/rows" >> "$_PS_T/q.txt"
    fi
  done
  if [ "$_PS_TSV" = 1 ]; then cat "$_PS_T/q.src" "$_PS_T/q.pr"
  else
    cat "$_PS_T/q.txt"
    [ "$n" -gt 0 ] || printf 'no project names a remote_match: nothing to read\n'
    printf '%s founder entries across %s projects\n' "$tot" "$n"
  fi
  _ps_scratch_gone
  return 0
}

_ps_run() {
  case "$_PS_MODE" in
    prs) _ps_prs_cmd ;;
    queue) _ps_queue_cmd ;;
  esac
}
