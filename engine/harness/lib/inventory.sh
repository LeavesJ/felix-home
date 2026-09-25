# felix inventory: where unlanded work is, derived from disk, git and gh, and
# from the host's session records through one adapter.
#
# Work is lost before it reaches a pull request, and a landing actor sees only
# open ones. The sweep of 2026-09-24 found every stage, from edits left in
# stopped worktrees to a branch checked out twice whose idle index held a
# staged revert of the other's merge. A session that dies registers nothing,
# and SessionEnd fired for 13 of 60, so this is derived, every time.
#
# Read-only by construction. Every git call (_fi_git) takes no optional lock,
# runs no fsmonitor, reads pathspecs literally (a directory named k* is not a
# glob) and fetches nothing a partial clone lacks (GIT_NO_LAZY_FETCH, git
# 2.44; on an older git a partial clone is refused, not read). git is never
# asked to write: no merge-tree --write-tree, stash create, write-tree,
# update-index or fetch, and hash-object without -w or filters. git status
# runs with every configured filter driver switched off, since a clean filter
# runs on each stat-dirty file and may store what it is handed (git-lfs
# does), and with submodules compared by commit only, so no git runs inside
# one. Remote-tracking refs are taken as they stand; gh is asked `pr list`
# and nothing else, with its own state pointed into the scratch. Scratch is
# one mktemp -d outside every repository (inside a worktree it would read as
# that worktree's changes), removed on exit and on HUP, INT, QUIT and TERM;
# no here-document, which bash 3.2 backs with a file outside it. Advisory:
# nothing on the enforcing path reads it (invariant 2), and it exits 0
# unless a repository cannot be read at all, 2 on a bad argument.
#
# Everything here is git and GitHub, with lib/inventory-gh.sh (what gh says)
# and lib/inventory-orphans.sh (what sits beside the worktrees); what only a
# host's records say (live, question, blocked, chips) is asked of
# lib/inventory-host.sh, question after Felix's own record (_fi_left), and
# lib/inventory-view.sh draws the human view.
# What cannot be read prints unknown, never absent, and a row with an
# unknown state other than live is never landed.
#
# One row per item: a worktree, an orphan, a local branch checked out
# nowhere, a remote branch no local branch covers (one at its tip or ahead of
# it) or open PR does, an open PR whose head no local branch proposes, a
# chip, a pending handoff section; a branch's PR states ride on its own row,
# looked up by the name it has on origin. Whether a branch is the default
# one is told by its name, never by its upstream: a feature branch made with
# --track origin/main tracks the default branch and is not it. States print in
# _FI_ORDER, the first the headline; landed means none holds but live. A list
# that could not be read (open PRs, chips) or a fact about the whole
# repository (gh's list at its limit) is a row of kind repo with ref -, never
# an item's. A worktree or orphan in a temporary directory ($TMPDIR, /tmp,
# /private/tmp, /private/var/folders, or instead the colon-separated
# FELIX_INVENTORY_TEMP_ROOTS when set, which tests use) says temp in its
# detail and is read as any other; the human view lists it apart from what
# needs action.
# Content is on the default branch (origin/HEAD's target, else origin/main,
# else origin/master) when the branch reaches the tip, or a merged PR's head
# is the tip or descends from it, since squash merges defeat ancestry;
# otherwise each path the tip changed since its merge-base is compared with
# the default branch's blob: all equal landed, none not, some partly. A dirty
# path compares its working file. Three gaps in the spec are filled: a pushed
# branch whose PRs all merged before its newest commits is unproposed, not
# landed; a staged revert's earlier tip must not descend from HEAD, or a
# reset --soft reads as one, and a detached worktree reads its HEAD's reflog;
# and a branch never pushed heads no PR, so under --no-gh its PR states are no.
#
# A worktree git lists is read only when git, asked there, names that
# directory as the top of a working tree of this repository: a directory
# whose .git file is gone would otherwise be read as the checkout enclosing
# it, and a path holding a line break is not read at all.
#
# Every fact per item is joined once, by awk, into one line of $T/items, and
# the loop only reads fields: a lookup in a bash string of a few thousand
# refs costs seconds a time on bash 3.2, and a fork per helper, minutes.

_FI_ORDER='hazard:shared-branch hazard:staged-revert live question blocked uncommitted unpushed unproposed pr-open pr-closed-unlanded orphan chip-unstarted handoff-pending'
_FI_TAB=$'\t'
_FI_NL=$'\n'
_FI_PENDING="docs/handoff/pending"   # the layout lib/handoff.sh writes

felix_inventory_usage() {
  printf 'usage: felix inventory [--repo DIR]... [--tsv] [--live MIN] [--blocked MIN] [--days N] [--no-gh] [--no-host]\n'
  printf '  read-only: where unlanded work is, derived from git, gh and the host'"'"'s session records\n'
  printf '  --repo DIR     a repository to read, repeatable (default: the one holding this directory)\n'
  printf '  --tsv          one row per item: kind repo ref states owner age_h detail\n'
  printf '  --live MIN, --blocked MIN, --days N   live: a session active within MIN (60); blocked: a tool call\n'
  printf '                 unanswered for MIN (20); chips: from sessions active within N days (14)\n'
  printf '  --no-gh        do not ask gh: PR states become unknown\n'
  printf '  --no-host      do not read session records: live, question, blocked and chips become unknown\n'
}
_fi_refuse() { printf 'felix inventory: %s\n' "$1" >&2; felix_inventory_usage >&2; return 2; }
_fi_git() { GIT_NO_LAZY_FETCH=1 git --no-optional-locks --literal-pathspecs -c core.fsmonitor=false "$@"; }
_fi_git_244() { git version 2>/dev/null | awk '{ split($3, v, "."); exit !(v[1] > 2 || (v[1] == 2 && v[2] >= 44)) }'; }
# A row: kind ref states owner age detail sig branch, the repository second; no tab or line break in a field, - for empty.
_fi_row() {
  local a line=""
  for a in "$1" "$_FI_REPO" "${@:2}"; do a="${a//$_FI_TAB/ }"; a="${a//$_FI_NL/ }"; line="$line${a:--}$_FI_TAB"; done
  printf '%s\n' "${line%"$_FI_TAB"}" >> "$_FI_T/rows"
}
_fi_age() { case "${1:-}" in ''|0|-|*[!0-9]*) _FI_A=- ;; *) _FI_A=$(( (_FI_NOW - $1) / 3600 )) ;; esac; }
_fi_add() { _FI_DET="${_FI_DET:+$_FI_DET; }$1"; }
# name=yes|no|unknown pairs, in _FI_ORDER, as the states field.
_fi_states() {
  local a held="" unk="" open=0
  for a in "$@"; do
    case "${a#*=}" in yes) held="$held,${a%%=*}" ;; unknown) unk="$unk,unknown:${a%%=*}" ;; *) continue ;; esac
    [ "${a%%=*}" = live ] || open=1
  done
  [ "$open" = 1 ] || held="$held,landed"
  held="$held$unk"; _FI_S="${held#,}"
}
# What an item changed, as one checksum, for possible-duplicate.
_fi_sig() { _FI_SIG=-; if [ -s "$T/sig" ] || [ -s "$T/dsig" ]; then _FI_SIG="$(cat "$T/sig" "$T/dsig" | cksum | tr ' ' :)"; fi; }
# Scratch outside every repository, else under /tmp, else none.
_fi_scratch() {
  local b
  for b in "${TMPDIR:-/tmp}" /tmp; do
    _FI_T="$(mktemp -d "${b%/}/felix-inventory.XXXXXX" 2>/dev/null)" || { _FI_T=""; continue; }
    _fi_git -C "$_FI_T" rev-parse --git-dir >/dev/null 2>&1 || return 0
    rmdir "$_FI_T"; _FI_T=""
  done
  return 1
}

felix_inventory() {
  local tsv=0 repos="" d rc=0
  _FI_LIVE=60; _FI_BLOCKED=20; _FI_DAYS=14; _FI_GH=1; _FI_HOST=1
  while [ $# -gt 0 ]; do
    case "$1" in
      --repo) [ $# -ge 2 ] && [ -n "$2" ] || { _fi_refuse "--repo needs a directory"; return; }; repos="$repos$2$_FI_NL"; shift 2 ;;
      --live|--blocked|--days)
              case "${2:-}" in ''|*[!0-9]*|???????*) _fi_refuse "$1 needs a whole number of at most six digits"; return ;; esac
              case "$1" in --live) _FI_LIVE=$((10#$2)) ;; --blocked) _FI_BLOCKED=$((10#$2)) ;; *) _FI_DAYS=$((10#$2)) ;; esac; shift 2 ;;
      --tsv) tsv=1; shift ;;  --no-gh) _FI_GH=0; shift ;;  --no-host) _FI_HOST=0; shift ;;
      -h|--help) felix_inventory_usage; return 0 ;;  *) _fi_refuse "unknown argument: $1"; return ;;
    esac
  done
  # The repositories read are the ones named, never one an inherited GIT_DIR names.
  unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY
  export LC_ALL=C; [ -n "$repos" ] || repos="$PWD$_FI_NL"; _fi_tmps
  _FI_T=""; trap '[ -z "$_FI_T" ] || rm -rf "$_FI_T"' EXIT
  trap 'exit 129' HUP; trap 'exit 130' INT; trap 'exit 131' QUIT; trap 'exit 143' TERM
  _fi_scratch || { printf 'felix inventory: no scratch directory outside every repository\n' >&2; return 1; }
  _FI_NOW="$(date +%s)"; T="$_FI_T/r"; : > "$_FI_T/rows"; : > "$_FI_T/meta"; printf '%s' "$repos" > "$_FI_T/repos"
  while IFS= read -r d <&3; do [ -n "$d" ] && { _fi_repo "$d" || rc=1; }; done 3< "$_FI_T/repos"
  _fi_out "$tsv"; return "$rc"
}

# ---------------------------------------------------------------- facts ----
# Scratch for one repository is $T; every loop reads its file on fd 3, since
# git and awk inside a loop would otherwise read what the loop is reading.
_fi_repo() {
  local d="$1" c f w k ref sha br dt cl rr op num st fl sh
  [ -d "$T" ] && rm -rf "$T"; mkdir "$T" || return 1
  # -z, since a path may hold a line break (git 2.36; before it, plain).
  c="$(_fi_git -C "$d" rev-parse --git-common-dir 2>/dev/null)" && c="$(cd "$d" && cd "$c" && pwd -P)" \
    && { { _fi_git -C "$d" worktree list --porcelain -z > "$T/wtz" 2>/dev/null && tr '\n\000' '\001\n' < "$T/wtz" > "$T/wtp"; } \
         || _fi_git -C "$d" worktree list --porcelain > "$T/wtp" 2>/dev/null; } \
    || { printf 'felix inventory: %s is not a git repository it can read\n' "$d" >&2; return 1; }
  _FI_D="$d"; _FI_COMMON="$c"; _FI_PARTIAL=0
  if _fi_git -C "$d" config --get extensions.partialClone >/dev/null 2>&1 \
     || _fi_git -C "$d" config --bool --get-regexp '^remote\..*\.promisor$' 2>/dev/null | grep -q ' true$'; then
    _fi_git_244 || { printf 'felix inventory: %s is a partial clone, and a git before 2.44 would fetch what it lacks\n' "$d" >&2; return 1; }
    _FI_PARTIAL=1
  fi
  # path head branch flags, one line per worktree, the main one first; a
  # path holding a line break or a tab is flagged linebreak and never read.
  awk 'function out() { if (p != "") print p "\t" h "\t" b "\t" (s == "" ? "-" : s) }
       function esc(x, c, r,    i) { while (i = index(x, c)) x = substr(x, 1, i - 1) r substr(x, i + 1); return x }
       /^worktree / { out(); p = substr($0, 10); h = "-"; b = "-"; s = ""
         if (index(p, "\001") || index(p, "\t")) { p = esc(esc(p, "\001", "\\n"), "\t", "\\t"); s = "linebreak," } next }
       /^HEAD / { h = $2 } /^branch / { b = substr($0, 8); sub(/^refs\/heads\//, "", b) }
       /^(bare|detached|locked|prunable)/ { s = s $1 "," }
       END { out() }' "$T/wtp" > "$T/wt"
  _FI_REPO="$(head -1 "$T/wt" | cut -f1)"; _FI_MAIN="$_FI_REPO"
  case "$(head -1 "$T/wt" | cut -f4)" in *bare*|*linebreak*) _FI_MAIN="" ;; esac
  _FI_DEF="$(_fi_git -C "$d" rev-parse --abbrev-ref origin/HEAD 2>/dev/null)" || _FI_DEF=""
  case "$_FI_DEF" in origin/HEAD|origin/) _FI_DEF="" ;; origin/*) ;; *) _FI_DEF="" ;; esac
  for f in origin/main origin/master; do
    [ -z "$_FI_DEF" ] && _fi_git -C "$d" rev-parse -q --verify "refs/remotes/$f^{commit}" >/dev/null 2>&1 && _FI_DEF="$f"
  done
  _FI_DEFSHA=""; : > "$T/deftree"
  if [ -n "$_FI_DEF" ]; then
    _FI_DEFSHA="$(_fi_git -C "$d" rev-parse -q --verify "refs/remotes/$_FI_DEF^{commit}")" || _FI_DEFSHA=""
    # A tree the clone lacks leaves the default branch unknown, not empty.
    if [ -n "$_FI_DEFSHA" ] && _fi_git -C "$d" ls-tree -r -z --full-tree "$_FI_DEFSHA" > "$T/deftz" 2>/dev/null; then
      tr '\000' '\n' < "$T/deftz" | awk '{ i = index($0, "\t"); split(substr($0, 1, i - 1), m, " "); print substr($0, i + 1) "\t" m[3] }' > "$T/deftree"
    else _FI_DEF=""; _FI_DEFSHA=""; fi
  fi
  _fi_git -C "$d" for-each-ref --format='%(refname)%09%(objectname)%09%(committerdate:unix)%09%(upstream)%09%(symref)' \
    refs/heads refs/remotes | awk -F'\t' -v OFS='\t' '{ for (i = 1; i <= 5; i++) if ($i == "") $i = "-"; print }' > "$T/refs"
  if _fi_gh "$d"; then _FI_GHOK=1; else _FI_GHOK=0; fi
  _fi_sets; _fi_orphan_find
  if [ "$_FI_HOST" = 1 ]; then f="read from $FELIX_INV_HOST_NAME's session records"; w="proposed in sessions active in the last $_FI_DAYS days (--days)"
  else f="unknown (--no-host)"; w="$f"; fi
  printf '%s\tdefault\t%s\n%s\tPR facts\t%s\n%s\tsessions\t%s\n%s\tchips\t%s\n' "$_FI_REPO" "${_FI_DEF:-unknown: no origin/HEAD, origin/main or origin/master whose tree this clone holds}" \
    "$_FI_REPO" "$_FI_GHSTATE" "$_FI_REPO" "$f" "$_FI_REPO" "$w" >> "$_FI_T/meta"
  [ "$_FI_PARTIAL" = 0 ] || printf '%s\tobjects\ta partial clone: nothing it lacks was fetched, so content in no object here may be the remote'"'"'s\n' "$_FI_REPO" >> "$_FI_T/meta"
  while IFS="$_FI_TAB" read -r k ref sha br dt cl rr op num st fl sh <&3; do _fi_item; done 3< "$T/items"
  if [ "$_FI_GHOK" = 0 ]; then _fi_row repo - unknown:pr-open - - "open PRs not listed: $_FI_GHSTATE" - -
  elif [ "$_FI_GHTRUNC" = 1 ]; then _fi_row repo - unknown:unproposed - - "PR facts $_FI_GHSTATE" - -; fi
  _fi_orphan_rows; _fi_handoff; _fi_chips
  return 0
}

# The items: kind ref sha branch date class rr open num state flags shared.
# Class RXM: R the default branch reaches the tip, X it holds a commit on no
# remote-tracking ref, M a merged PR's head is it or descends from it; --- it
# is not here, and is kept out of every rev-list, which one would fail.
_fi_sets() {
  local t="$T/tips" have='%(objectname) %(objecttype)' r rs ls
  { cut -f2 "$T/wt"; awk -F'\t' '$1 ~ /^refs\/heads\// { print $2 }' "$T/refs"; } | awk '$1 != "-"' | sort -u > "$t.l"
  awk -F'\t' '$2 == "MERGED" { print $4 }' "$T/prs" > "$T/mh"
  { cat "$t.l"; awk -F'\t' '$1 ~ /^refs\/remotes\// && $5 == "-" { print $2 }' "$T/refs"; awk -F'\t' '$2 == "OPEN" { print $4 }' "$T/prs"; } \
    | sort -u | _fi_git -C "$_FI_D" cat-file --batch-check="$have" 2>/dev/null | awk '$2 == "commit" { print $1 }' > "$t"
  : > "$T/ahead"; : > "$T/merged"
  [ -n "$_FI_DEFSHA" ] && { cat "$t"; printf '^%s\n' "$_FI_DEFSHA"; } | _fi_git -C "$_FI_D" rev-list --stdin > "$T/ahead" 2>/dev/null
  { grep -xF -f "$t" "$t.l"; awk -F'\t' '$1 ~ /^refs\/remotes\// && $5 == "-" { print "^" $2 }' "$T/refs"; } \
    | _fi_git -C "$_FI_D" rev-list --stdin > "$T/unpushed" 2>/dev/null
  _fi_git -C "$_FI_D" cat-file --batch-check="$have" < "$T/mh" 2>/dev/null | awk '$2 == "commit" { print $1 }' > "$T/mheads"
  [ -s "$T/mheads" ] && [ -n "$_FI_DEFSHA" ] && { cat "$T/mheads"; printf '^%s\n' "$_FI_DEFSHA"; } | _fi_git -C "$_FI_D" rev-list --stdin > "$T/merged" 2>/dev/null
  cut -f2 "$T/wt" | grep -xF -f "$t" | _fi_git -C "$_FI_D" log --no-walk=unsorted --stdin --format='%H %ct' > "$T/dates" 2>/dev/null
  # The remote branch each local branch covers: origin/<its name>, else its
  # upstream unless that is the default branch. Covered means its tip is the
  # local tip or behind it; one ahead or apart gets a row of its own.
  awk -F'\t' -v def="$_FI_DEF" '$1 ~ /^refs\/heads\// { L[substr($1, 12)] = $2; U[substr($1, 12)] = $4; next }
    $1 ~ /^refs\/remotes\// && $5 == "-" { R[substr($1, 14)] = $2 }
    END { for (n in L) { r = "origin/" n; u = substr(U[n], 14)
            if (!(r in R)) { if (U[n] ~ /^refs\/remotes\// && u != def && (u in R)) r = u; else continue }
            print r "\t" R[r] "\t" L[n] } }' "$T/refs" > "$T/covp"
  : > "$T/cov"
  while IFS="$_FI_TAB" read -r r rs ls <&3; do
    { [ "$rs" = "$ls" ] || _fi_git -C "$_FI_D" merge-base --is-ancestor "$rs" "$ls" 2>/dev/null; } && printf '%s\n' "$r" >> "$T/cov"
  done 3< "$T/covp"
  awk -F'\t' -v OFS='\t' -v r="$_FI_DEFSHA" -v def="$_FI_DEF" -v dn="${_FI_DEF#origin/}" '
    FILENAME ~ /ahead$/ { A[$1] = 1; next } FILENAME ~ /unpushed$/ { X[$1] = 1; next }
    FILENAME ~ /(merged|mheads)$/ { M[$1] = 1; next }
    FILENAME ~ /tips$/ { C[$1] = (r != "" && !($1 in A)) ($1 in X) ($1 in M); next }
    FILENAME ~ /dates$/ { split($0, x, " "); D[x[1]] = x[2]; next }
    FILENAME ~ /prh$/ { O[$1] = $2; NUM[$1] = $3; ST[$1] = $4; next }
    FILENAME ~ /prs$/ { if ($2 == "OPEN") P[++np] = $0; next }
    FILENAME ~ /cov$/ { CV[$1] = 1; next }
    FILENAME ~ /refs$/ { if ($1 ~ /^refs\/heads\//) { n = substr($1, 12); LB[n] = $2; LD[n] = $3; UP[n] = $4; LO[++nl] = n }
      else if ($1 ~ /^refs\/remotes\// && $5 == "-") { n = substr($1, 14); RB[n] = $2; RD[n] = $3; RO[++nr] = n }; next }
    { W[++nw] = $0; if ($3 != "-") CO[$3] = CO[$3] "\n" $1 }
    function rr(n,    u) { if (("origin/" n) in RB) return "origin/" n
      u = substr(UP[n], 14); return (UP[n] ~ /^refs\/remotes\// && (u in RB) && u != def) ? u : "-" }
    function pk(b, rrr) { return rrr ~ /^origin\// ? substr(rrr, 8) : b }
    function out(k, ref, sha, b, d, rrr, fl, sh,    p) { p = pk(b, rrr)
      print k, ref, sha, b, (d == "" ? "-" : d), ((sha in C) ? C[sha] : "---"), rrr, \
        (b == "-" || b == dn || !(p in NUM) ? "-\t-\t-" : O[p] "\t" NUM[p] "\t" ST[p]), fl, (sh == "" ? "-" : sh) }
    END {
      for (i = 1; i <= nw; i++) { split(W[i], w, "\t"); if (w[4] ~ /bare/) continue
        m = split(CO[w[3]], S, "\n"); o = ""; for (j = 2; j <= m; j++) if (S[j] != w[1]) o = o " " S[j]
        out("worktree", w[1], w[2], w[3], D[w[2]], (w[3] == "-" ? "-" : rr(w[3])), w[4], (w[3] == "-" ? "" : substr(o, 2))) }
      for (i = 1; i <= nl; i++) { n = LO[i]; if (!(n in CO)) out("branch", n, LB[n], n, LD[n], rr(n), "-", ""); PB[pk(n, rr(n))] = 1 }
      for (i = 1; i <= nr; i++) { n = RO[i]; b = substr(n, 8)
        if (n !~ /^origin\// || n == def || (n in CV) || (O[b] != "" && O[b] != "-")) continue
        out("remote", n, RB[n], b, RD[n], n, "-", "") }
      for (i = 1; i <= np; i++) { split(P[i], p, "\t"); if (!(p[3] in PB)) out("pr", "#" p[1], p[4], p[3], p[5], "-", "-", "") } }' \
    "$T/ahead" "$T/unpushed" "$T/merged" "$T/mheads" "$t" "$T/dates" "$T/prh" "$T/prs" "$T/cov" "$T/refs" "$T/wt" > "$T/items"
}

# Whether a tip's content is on the default branch, as _FI_L: landed, unknown,
# or how much is not. What it changed since its merge-base, "path blob", goes
# to $T/sig. Arguments: the tip and its class.
_fi_land() {
  local mb
  : > "$T/sig"; _FI_L=unknown
  [ -n "$_FI_DEFSHA" ] || return 0
  case "$2" in 1??|??1) _FI_L=landed; return 0 ;; esac
  mb="$(_fi_git -C "$_FI_D" merge-base "$_FI_DEFSHA" "$1" 2>/dev/null)" || return 0
  _fi_git -C "$_FI_D" diff-tree -r --no-renames -z "$mb" "$1" > "$T/dtz" 2>/dev/null || return 0
  _FI_L="$(tr '\000' '\n' < "$T/dtz" | awk -v df="$T/deftree" -v sig="$T/sig" -v def="$_FI_DEF" '
    BEGIN { while ((getline l < df) > 0) { i = index(l, "\t"); B[substr(l, 1, i - 1)] = substr(l, i + 1) } }
    /^:/ { split($0, m, " "); dst = m[4]; next }
    { n++; print $0 "\t" dst > sig; if (dst ~ /^0+$/ ? !($0 in B) : B[$0] == dst) eq++ }
    END { if (!n || eq == n) printf "landed"; else printf "%s on %s (%s%d changed path%s)", (eq ? "partly" : "not"), def, (eq ? eq " of " : ""), n, (n > 1 ? "s" : "") }')"
}

# How a worktree's changed paths stand, as _FI_DD: "differ changed innoobject
# filtered", or unknown. Each changed path's working blob, "path blob", goes
# to $T/dsig. A path under a filter driver, switched off here, is compared
# raw against a cleaned blob, so it is counted apart, as not known. In the
# main worktree, what lies inside a linked worktree or an orphan ($T/nest) is
# theirs, not its.
_fi_dirty() {
  local wt="$1" p k d; local -a nf=()
  : > "$T/dsig"; : > "$T/dfl"; : > "$T/fp"; _FI_DD=unknown
  _fi_git -C "$wt" config --name-only --get-regexp '^filter\.' > "$T/fk" 2>/dev/null
  while IFS= read -r k <&3; do d="${k#filter.}"; d="${d%.*}"
    grep -qxF -- "$d" "$T/dfl" || { printf '%s\n' "$d" >> "$T/dfl"; nf=(${nf[@]+"${nf[@]}"} -c "filter.$d.clean=" -c "filter.$d.process=" -c "filter.$d.required=false"); }
  done 3< "$T/fk"
  _fi_git -C "$wt" ${nf[@]+"${nf[@]}"} status --porcelain=v1 -z --no-renames --untracked-files=all --ignore-submodules=dirty > "$T/stz" 2>/dev/null || return 0
  tr '\000' '\n' < "$T/stz" | if [ "$wt" = "$_FI_MAIN" ] && [ -s "$T/nest" ]; then
    awk 'NR == FNR { N[++n] = $0; next } { p = substr($0, 4); sub(/\/$/, "", p); for (i = 1; i <= n; i++) if (p == N[i] || index(p, N[i] "/") == 1) next; print }' "$T/nest" -
  else cat; fi > "$T/st"
  [ -s "$T/st" ] || { _FI_DD="0 0 0 0"; return 0; }
  [ -n "$_FI_DEFSHA" ] || return 0; : > "$T/hp"; : > "$T/dx"
  while IFS= read -r p <&3; do
    p="${p:3}"
    if [ -L "$wt/$p" ]; then printf '%s\t%s\n' "$p" "$(printf '%s' "$(readlink "$wt/$p")" | _fi_git hash-object --stdin)" >> "$T/dx"
    elif [ -f "$wt/$p" ]; then printf '%s\n' "$p" >> "$T/hp"
    elif [ -e "$wt/$p" ]; then printf '%s\t(a repository)\n' "${p%/}" >> "$T/dx"
    else printf '%s\t0\n' "$p" >> "$T/dx"; fi
  done 3< "$T/st"
  _fi_git -C "$wt" hash-object --no-filters --stdin-paths < "$T/hp" > "$T/hh" 2>/dev/null || : > "$T/hh"
  { paste "$T/hp" "$T/hh"; cat "$T/dx"; } | sort > "$T/dsig"
  [ -s "$T/dfl" ] && cut -f1 "$T/dsig" | tr '\n' '\000' | _fi_git -C "$wt" check-attr -z --stdin filter 2>/dev/null | tr '\000' '\n' \
    | awk -v fl="$T/dfl" 'BEGIN { while ((getline l < fl) > 0) F[l] = 1 } NR % 3 == 1 { p = $0 } NR % 3 == 0 && ($0 in F) { print p }' > "$T/fp"
  _FI_DD="$(awk -F'\t' -v df="$T/deftree" -v fp="$T/fp" -v db="$T/db" 'BEGIN { printf "" > db
      while ((getline l < df) > 0) { i = index(l, "\t"); B[substr(l, 1, i - 1)] = substr(l, i + 1) }; while ((getline l < fp) > 0) F[l] = 1 }
    { n++; if ($2 == "0" ? !($1 in B) : B[$1] == $2) next
      if ($2 != "0" && ($1 in F)) { f++; next }
      d++; if ($2 ~ /^[0-9a-f]+$/) print $2 > db }
    END { printf "%d %d %d", d, n, f }' "$T/dsig")"
  k="$(_fi_git -C "$wt" cat-file --batch-check < "$T/db" 2>/dev/null | grep -c ' missing$')"
  set -- $_FI_DD; _FI_DD="$1 $2 ${k:-0} $3"
}
# The host's answer for a directory, as _FI_H: owner mtime live question
# blocked note replied; the note, if any, joins the detail.
_fi_host() {
  local x="unknown${_FI_TAB}-${_FI_TAB}unknown${_FI_TAB}unknown${_FI_TAB}unknown${_FI_TAB}-"
  [ "$_FI_HOST" = 1 ] && x="$(felix_inv_host_dir "$1" "$_FI_NOW" "$_FI_LIVE" "$_FI_BLOCKED")"
  local IFS="$_FI_TAB"; set -f; _FI_H=($x); set +f
  [ "${#_FI_H[@]}" -ge 6 ] || _FI_H=(unknown - unknown unknown unknown "the host adapter answered nothing")
  _fi_left "$1"; [ "${_FI_H[5]}" = - ] || _fi_add "${_FI_H[5]}"
}
# Felix's record of how the newest session left a directory (lib/left.sh),
# found by its id in any project's memory and taken when its dir is this one:
# its asked decides question ahead of the adapter, whose text a no drops, but
# a yes yields to the founder speaking after the final text (replied); the
# adapter stays the reading for a session older than it or with no message.
_fi_left() {
  local s="${_FI_H[0]}" p f l d a="" n="${_FI_H[5]}" w=""
  case "$s" in ''|-|unknown|.|..|-*|*[!A-Za-z0-9._-]*) return 0 ;; esac
  p="$(cd "$1" 2>/dev/null && pwd -P)" || p=""
  for f in "${FELIX_MEMORY:-${HOME:-}/.felix/memory}"/*/left/"$s".tsv; do
    l=""; [ -f "$f" ] && { IFS= read -r l < "$f"; } 2>/dev/null
    d="${l#*"$_FI_TAB"*"$_FI_TAB"}"; d="${d%%"$_FI_TAB"*}"
    [ -n "$d" ] && { [ "$d" = "$1" ] || [ "$d" = "$p" ]; } && { a="${l##*"$_FI_TAB"}"; break; }
  done
  case "$a,${_FI_H[6]:-}" in yes,yes) return 0 ;; yes,*|no,*) ;; *) return 0 ;; esac
  [ "$a" = yes ] || case "$n" in "ended on: "*"; waiting on "*) n="waiting on ${n##*; waiting on }" ;; "ended on: "*) n=- ;; esac
  [ "$n" = - ] || w="; $n"
  _FI_H[3]="$a"; if [ "$a" = yes ]; then _FI_H[5]="question from Felix's record$w"; else _FI_H[5]="no question, from Felix's record$w"; fi
}

# The branch-borne states of a tip, into _FI_UNP _FI_UNPROP _FI_PRO _FI_PRC.
# Arguments: tip, branch or -, its remote-tracking ref or -, class, open PRs
# or -, newest PR number and state or -.
_fi_branch() {
  local tip="$1" br="$2" rr="$3" cl="$4" op="$5" num="$6" st="$7" n
  _FI_UNP=no; _FI_UNPROP=no; _FI_PRO=no; _FI_PRC=no; _FI_L=""; : > "$T/sig"
  case "$cl" in ?1?) _fi_land "$tip" "$cl"
    case "$_FI_L" in landed) ;; unknown) _FI_UNP=unknown ;;
      # 0 means it was pushed after the classes were read: the newer fact wins.
      *) n="$(_fi_git -C "$_FI_D" rev-list --count "$tip" --not --remotes 2>/dev/null)"
         [ "${n:-1}" = 0 ] || { _FI_UNP=yes; _fi_add "${n:-some} commit(s) on no remote; content $_FI_L"; } ;; esac ;;
  esac
  [ "$br" != - ] && [ "$br" != "${_FI_DEF#origin/}" ] || return 0   # the default branch heads no PR
  if [ "$_FI_GHOK" = 0 ]; then
    [ "$rr" != - ] || return 0
    _FI_PRO=unknown; [ -n "$_FI_L" ] || _fi_land "$tip" "$cl"
    [ "$_FI_L" = landed ] && return 0
    _FI_UNPROP=unknown; _FI_PRC=unknown
    [ "$_FI_L" = unknown ] || [ "$_FI_UNP" = yes ] || _fi_add "on $rr; content $_FI_L"
    return 0
  fi
  [ "$num" != - ] || [ "$rr" != - ] || return 0
  [ -n "$_FI_L" ] || _fi_land "$tip" "$cl"
  [ "$op" = - ] || { _FI_PRO=yes; _fi_add "$op"; return 0; }
  [ "$_FI_L" != landed ] || return 0
  if [ "$st" = CLOSED ]; then
    if [ "$_FI_L" = unknown ]; then _FI_PRC=unknown; else _FI_PRC=yes; _fi_add "#$num closed without merge; content $_FI_L"; fi
  elif [ "$rr" != - ]; then
    if [ "$_FI_L" = unknown ]; then _FI_UNPROP=unknown
    elif [ "$num" != - ]; then _FI_UNPROP=yes; _fi_add "on $rr, no PR since #$num merged; content $_FI_L"
    elif [ "$_FI_GHTRUNC" = 1 ]; then _FI_UNPROP=unknown; _fi_add "on $rr, no PR among the $_FI_GHN gh listed, which may not be all; content $_FI_L"
    else _FI_UNPROP=yes; _fi_add "on $rr with no PR; content $_FI_L"; fi
  fi
}

# ---------------------------------------------------------------- items ----
# One line of $T/items, its fields read by _fi_repo's loop.
_fi_item() {
  _FI_DET=""; : > "$T/dsig"
  case "$k" in
    worktree) _fi_worktree; return 0 ;;
    pr) _FI_DET="head $br @ ${sha:0:8}"; _fi_add "$op"; : > "$T/sig"; [ "$cl" = --- ] || _fi_land "$sha" "$cl"; _FI_S=pr-open ;;
    *) _FI_DET="@ ${sha:0:8}"; _fi_branch "$sha" "$br" "$rr" "$cl" "$op" "$num" "$st"
       _fi_states unpushed=$_FI_UNP unproposed=$_FI_UNPROP pr-open=$_FI_PRO pr-closed-unlanded=$_FI_PRC ;;
  esac
  _fi_sig; _fi_age "$dt"; _fi_row "$k" "$ref" "$_FI_S" - "$_FI_A" "$_FI_DET" "$_FI_SIG" "$br"
}
# Whether ref (a directory) is the top of a working tree of this repository:
# 0 it is, 1 it holds none of its own (git would read an enclosing one), 2 it
# is now another repository's.
_fi_own() {
  local x
  x="$(_fi_git -C "$1" rev-parse --show-toplevel --git-common-dir 2>/dev/null)" || return 1
  [ "${x%%"$_FI_NL"*}" = "$(cd "$1" 2>/dev/null && pwd -P)" ] || return 1
  [ "$(cd "$1" && cd "${x#*"$_FI_NL"}" 2>/dev/null && pwd -P)" = "$_FI_COMMON" ] || return 2
}
_fi_worktree() {
  local shd=no rev=no unc=no orph=no x when="$dt"
  if [ "$br" != - ]; then _fi_add "branch $br @ ${sha:0:8}"; else _fi_add "detached @ ${sha:0:8}"; fi
  x="${fl//detached,/}"; x="${x//linebreak,/}"; x="${x%,}"; [ "$x" = - ] || [ -z "$x" ] || _fi_add "git marks it ${x//,/ and }"
  [ "$sh" = - ] || { shd=yes; _fi_add "$br is also checked out in $sh"; }
  _FI_H=(unknown - unknown unknown unknown -)
  case "$fl" in
    *linebreak*) unc=unknown; _fi_add "its path holds a line break or a tab, so it is not read" ;;
    *) if [ ! -d "$ref" ]; then _fi_add "the directory is gone"
       else _fi_own "$ref"; x=$?
         if [ "$x" = 2 ]; then unc=unknown; _fi_add "it is now a checkout of another repository, so it is not read"
         elif [ "$x" = 1 ]; then orph=yes; _fi_add "git lists it, but it holds no working tree of this repository: $(_fi_uniq "$ref")"
         else _fi_revert; _fi_dirty "$ref"; _fi_dd; fi
       fi
       _fi_host "$ref" ;;
  esac
  _fi_branch "$sha" "$br" "$rr" "$cl" "$op" "$num" "$st"
  _fi_sig; ! _fi_temp "$ref" || _fi_add temp
  case "$when" in *[!0-9]*|'') when=0 ;; esac
  case "${_FI_H[1]}" in *[!0-9]*|'') ;; *) [ "${_FI_H[1]}" -gt "$when" ] && when="${_FI_H[1]}" ;; esac
  _fi_states hazard:shared-branch=$shd hazard:staged-revert=$rev live="${_FI_H[2]}" question="${_FI_H[3]}" blocked="${_FI_H[4]}" \
    uncommitted=$unc unpushed=$_FI_UNP unproposed=$_FI_UNPROP pr-open=$_FI_PRO pr-closed-unlanded=$_FI_PRC orphan=$orph
  _fi_age "$when"; _fi_row worktree "$ref" "$_FI_S" "${_FI_H[0]}" "$_FI_A" "$_FI_DET" "$_FI_SIG" "$br"
}
# _FI_DD as the worktree's uncommitted state (unc) and detail.
_fi_dd() {
  [ "$_FI_DD" != unknown ] || { unc=unknown; return 0; }
  set -- $_FI_DD
  if [ "$1" -gt 0 ]; then unc=yes
    _fi_add "uncommitted: $1 of $2 changed paths differ from $_FI_DEF, $3 of them holding content in no object$([ "$_FI_PARTIAL" = 0 ] || echo ' this clone holds')"
  elif [ "$4" -gt 0 ]; then unc=unknown
  elif [ "$2" -gt 0 ]; then _fi_add "$2 changed paths, all as $_FI_DEF has them"; fi
  [ "$4" = 0 ] || _fi_add "$4 changed-looking paths under a filter driver not compared, since the filter would have to run"
}
# The index differs from HEAD (status 1; 128 is an unborn HEAD): does it hold
# the tree of an earlier tip of the branch, or, detached, of an earlier HEAD?
_fi_revert() {
  local lr=HEAD w="HEAD here" c t
  [ "$br" = - ] || { lr="refs/heads/$br"; w="$br"; }
  _fi_git -C "$ref" diff-index --cached --quiet HEAD -- 2>/dev/null; [ $? = 1 ] || return 0
  _fi_git -C "$ref" reflog exists "$lr" 2>/dev/null || { rev=unknown; return 0; }
  _fi_git -C "$ref" log -g --format='%H %T' "$lr" -- 2>/dev/null \
    | awk -v t="$(_fi_git -C "$ref" rev-parse -q --verify 'HEAD^{tree}' 2>/dev/null)" '$2 != t && !s[$2]++' | head -100 > "$T/rl"
  while read -r c t <&3; do
    _fi_git -C "$ref" diff-index --cached --quiet "$t" -- 2>/dev/null || continue
    _fi_git -C "$ref" merge-base --is-ancestor HEAD "$c" 2>/dev/null && continue
    rev=yes; _fi_add "the index is the tree of ${c:0:8}, an earlier tip of $w: a commit here undoes what came after it"; break
  done 3< "$T/rl"
}

# Sections waiting in the pending directory of the default branch (else of
# HEAD), each with its "Next" items; a section this clone cannot read says so.
_fi_handoff() {
  local tree="${_FI_DEFSHA:-HEAD}" f next when
  _fi_git -C "$_FI_D" ls-tree --name-only "$tree" -- "$_FI_PENDING/" 2>/dev/null | grep '\.md$' > "$T/pend"
  while IFS= read -r f <&3; do
    if _fi_git -C "$_FI_D" cat-file -p "$tree:$f" > "$T/hsec" 2>/dev/null; then next="$(awk '
      function add(x) { I[++n] = x; st = 1 }
      { t = $0; sub(/^[#*_ ]+/, "", t) }
      t ~ /^Next([^A-Za-z]|$)/ { on = 1; st = 0; if (sub(/^[^:]*:[*_ ]*/, "", t) && t != "") add(t); next }
      on && /^[ \t]*$/ { if (st) on = 0; next }
      on && /^ ? ? ?([-*+]|[0-9]+[.)]) / { l = $0; sub(/^ *([-*+]|[0-9]+[.)]) +/, "", l); add(l); next }
      on && st && /^  / { l = $0; sub(/^ +/, "", l); I[n] = I[n] " " l; next }
      { on = 0 }
      END { if (n) printf "%d Next item%s: ", n, (n > 1 ? "s" : ""); for (i = 1; i <= n; i++) printf "%s%s", (i > 1 ? " | " : ""), I[i] }' "$T/hsec")"
      next="${next:-no Next lines}"
    else next="its Next lines are unknown: this clone cannot read the section"; fi
    when="$(_fi_git -C "$_FI_D" log -1 --format=%ct "$tree" -- "$f" 2>/dev/null)"; _fi_age "$when"
    _fi_row handoff "$f" handoff-pending - "$_FI_A" "$next" - -
  done 3< "$T/pend"
}

# Chips from sessions in every worktree, every orphan, and every directory
# under a directory inside the main worktree that holds worktrees.
_fi_chips() {
  local -a a=("$_FI_REPO"); local d id s e title
  [ "$_FI_HOST" = 1 ] || { _fi_row repo - unknown:chip-unstarted - - "chips not listed: session records not read (--no-host)" - -; return 0; }
  while IFS= read -r d <&3; do a[${#a[@]}]="$d"; done 3< <(awk -F'\t' '$4 !~ /bare|linebreak/ { print $1 }' "$T/wt"; cut -f1 "$T/orph"; cat "$T/scope")
  # The header's chips line is replaced when they cannot be read, since the
  # human view states a repository's own unknowns there and counts no repo row.
  felix_inv_host_chips "$_FI_NOW" "$_FI_DAYS" "${a[@]}" > "$T/chips" \
    || { _fi_row repo - unknown:chip-unstarted - - "chips not listed: no $FELIX_INV_HOST_NAME session records to read" - -
         printf '%s\tchips\tunknown: no %s session records to read\n' "$_FI_REPO" "$FELIX_INV_HOST_NAME" >> "$_FI_T/meta"; return 0; }
  while IFS="$_FI_TAB" read -r id s e title <&3; do _fi_age "$e"; _fi_row chip "$id" chip-unstarted "$s" "$_FI_A" "$title" - -; done 3< "$T/chips"
}

# ---------------------------------------------------------------- output ----
# Two rows of one repository holding unlanded content whose changed paths and
# blobs are the same, on different branches, are each a possible-duplicate.
# Then the rows: as TSV, or as lib/inventory-view.sh groups them for a person.
_fi_out() {
  awk -F'\t' -v OFS='\t' '{ R[NR] = $0 }
    $8 != "-" && $4 ~ /(^|,)(uncommitted|unpushed|unproposed|pr-open|pr-closed-unlanded)(,|$)/ {
      k = $2 SUBSEP $8; D[NR] = k; if (!((k, $9) in B)) { B[k, $9] = 1; NB[k]++ }; W[k] = W[k] "\n" $3 }
    END { for (i = 1; i <= NR; i++) { split(R[i], f, "\t")
        if ((i in D) && NB[D[i]] > 1) { m = split(W[D[i]], L, "\n"); o = ""; for (j = 2; j <= m; j++) if (L[j] != f[3]) o = o " " L[j]
          p = index(f[4], "unknown:"); f[4] = p ? substr(f[4], 1, p - 1) "possible-duplicate," substr(f[4], p) : f[4] ",possible-duplicate"
          f[7] = f[7] "; possible duplicate of" o }
        print f[1], f[2], f[3], f[4], f[5], f[6], f[7] } }' "$_FI_T/rows" > "$_FI_T/out"
  if [ "$1" = 1 ]; then cat "$_FI_T/out"; else _fi_view; fi
}
