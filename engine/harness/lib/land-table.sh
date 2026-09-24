# The land table: how each path is landed, and the two checks that report
# what a landing still owes before either of them stops anything.
#
# projects/<name>/land.tsv says, for a path, how the landing actor settles it
# (the landing-actor design §4). Four columns, tab-separated:
#
#   path     the path the row binds
#   kind     how it lands; the kinds are the engine constants below and name
#            no project (invariant 1)
#   trigger  `-`, or a path whose change means this row's path must change
#            too; a trigger ending in `/` names a directory
#   arg      the kind's argument, or `-`
#
# A resolver kind (version-above, keyed-union, insertions-union, rerun) is a
# path the actor may settle without a session. A narrowing kind (session,
# founder) is one it may not, and its path is an ERE, since narrowing more is
# the safe direction. This file reads and checks the table; it settles
# nothing. The actor that acts on the rows comes later, and nothing here is
# wired to it.
#
# READ FROM THE BASE, NEVER THE TREE. The table is read from
# refs/remotes/origin/main of the repository that holds projects/<name>/, the
# way exceptions.sh reads its grants: the checkout itself when Felix governs
# itself, the Felix home for a governed product. A session can write any file
# in its tree, and a recipe read from there would be a pull request rewriting
# the recipe that lands it. A local main is the session's to move, so it is
# not read either. Any change to the table escapes to a person (escape.sh), so
# the only table this ever reads is one somebody merged.
#
# THE SCHEMA RULE. Only session or founder may bind a path whose change is an
# escape, a commission, an authority grant, an exception, the trust base, or a
# land table itself. A table that let the actor settle risk.tsv by itself
# would be a quiet way round everything the merge boundary checks.
#
# OWED AND BEHIND, REPORT-ONLY. `owed` is a landing that touches a row's
# trigger and not its path: an engine change with no version bump, say.
# `behind` is a HEAD that lacks the base's tip. In this step both only write a
# `would-refuse` row to says.log. They print nothing, refuse nothing and move
# no exit status, so how a session lands does not change, and a dry run writes
# nothing at all.
#
# Bash 3.2. Lists are split by awk, never by an unquoted expansion: the trust
# base holds `*`, and an unquoted expansion would glob it against whatever
# directory the caller stands in.

# The helpers this file calls, loaded only when the caller has not. The judge's
# child shell sources resolve, verify, review, classify, evidence and escape,
# and nothing else: say.sh and table.sh are not in it, so without these the
# report would be a command not found, swallowed.
if ! command -v felix_changed_paths >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh" 2>/dev/null
fi
if [ -z "${FELIX_TABLE_SKIP:-}" ]; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/table.sh" 2>/dev/null
fi
if ! command -v felix_say >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/say.sh" 2>/dev/null
fi

FELIX_LAND_KINDS='version-above keyed-union insertions-union rerun session founder'
FELIX_LAND_NARROWING='session founder'

# The authority category. A superset of escape.sh's own authority channel,
# which names autonomy and autonomy.<word>: anything beside the grant that
# starts with its name is refused as well, which refuses more, the safe way.
FELIX_LAND_AUTHORITY='(^|/)projects/[^/]+/autonomy[^/]*$'

# The trust base: the files that decide what stops a merge and who judges it.
# No such constant existed before this one. This is the minimal list the
# landing-actor design gives (§2 step 6, repeated in §7 and in its step 11,
# T1), and this file only reads it, in the schema rule. T1 owns extending it,
# refusing to land a pull request that touches it unattended, and the verifier
# on a list that shrinks.
#
# Each entry is a whole repository-relative path. A `*` matches a run of
# characters other than `/`; every other character is literal; the match is
# anchored at both ends. `land*.sh` covers this file.
FELIX_TRUST_BASE='engine/harness/lib/escape.sh engine/harness/lib/commission.sh engine/harness/lib/autonomy.sh engine/harness/lib/land*.sh engine/harness/lib/resolve.sh engine/harness/lib/verify.sh engine/harness/lib/deny.sh engine/harness/lib/deny-read.sh engine/harness/lib/where.sh engine/harness/lib/where-read.sh engine/harness/hooks/pre-tool engine/hooks/hooks.json engine/harness/felix projects/*/gate.sh'

# Whether a path is in the trust base. Exit 0 when some entry matches, 1
# otherwise, printing nothing. Each entry is turned into an anchored regex one
# character at a time, so no entry is ever a glob and no character but `*` is
# ever special.
felix_land_trust_base() {
  printf '%s\n' "${FELIX_TRUST_BASE:-}" | P="${1:-}" LC_ALL=C awk '
    BEGIN { plain = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/" }
    { for (i = 1; i <= NF; i++) {
        e = $i; re = "^"
        for (j = 1; j <= length(e); j++) {
          c = substr(e, j, 1)
          if (c == "*")                                     re = re "[^/]*"
          else if (index(plain, c))                         re = re c
          else if (c == "\\" || c == "^" || c == "]" || c == "[") re = re "\\" c
          else                                              re = re "[" c "]"
        }
        if (ENVIRON["P"] ~ (re "$")) found = 1 } }
    END { exit !found }'
}

# Why a resolver may not bind this path, as one word: the first category that
# holds, in a fixed order. Exit 0 with the word when the path is protected; 1,
# printing nothing, when it is not.
#
# Fails closed. The categories are read from escape.sh's and commission.sh's
# lists, and a list that is not loaded has not shown that the path is outside
# it, so a missing lister or an empty list says `unknown` and protects every
# path. The opposite mistake would let a resolver settle a table the rule
# exists for.
felix_land_protected() {
  local p="${1:-}" b
  if ! command -v _felix_escape_listed >/dev/null 2>&1 \
       || [ -z "${FELIX_ESCAPE_TABLES:-}" ] || [ -z "${FELIX_COMMISSION_TABLES:-}" ] \
       || [ -z "${FELIX_ESCAPE_EXECUTE:-}" ]; then
    printf 'unknown\n'; return 0
  fi
  b="${p##*/}"
  if [ "$b" = "land.tsv" ]; then printf 'land-table\n'; return 0; fi
  if _felix_escape_listed "$p" "$FELIX_ESCAPE_TABLES"; then printf 'escape-table\n'; return 0; fi
  if _felix_escape_listed "$p" "$FELIX_COMMISSION_TABLES"; then printf 'commission-table\n'; return 0; fi
  if printf '%s' "$p" | grep -qE -- "$FELIX_ESCAPE_EXECUTE"; then printf 'execute\n'; return 0; fi
  if printf '%s' "$p" | grep -qE -- "$FELIX_LAND_AUTHORITY"; then printf 'authority\n'; return 0; fi
  if [ "$b" = "exceptions.tsv" ]; then printf 'exception\n'; return 0; fi
  if felix_land_trust_base "$p"; then printf 'trust-base\n'; return 0; fi
  return 1
}

# One scan decides both the rows and the refusals, the way exceptions.sh and
# the obligation ledger do, so the two can never disagree about what a row is.
#
# A data row is table.sh's: any line not matching FELIX_TABLE_SKIP, a final
# line with no newline included. Line numbers count every line of the text,
# comments too, so a refusal names the line an editor shows.
#
# Two answers need more than awk: whether a narrowing path is a valid ERE, which
# only grep can say, and whether a resolver path is protected, which is
# felix_land_protected's alone so that the rule has one definition. Both are
# asked first, per candidate path, and handed to the scan through the
# environment, which awk reads without processing backslashes.
#
# The reasons, in the order they are reported for one row:
#   cells      not four tab-separated cells, an empty cell, or a CR. Alone:
#              a row whose cells cannot be told apart has no path to judge
#   kind       not an engine kind. Alone but for duplicate, since no column
#              rule applies without a kind
#   path       a resolver path that is not a plain literal; a narrowing path
#              that is not a valid ERE; or `-`
#   trigger    neither `-` nor a literal (which may end in `/`); or not `-` on
#              a narrowing row, since nothing is owed on a path the actor may
#              never write
#   arg        keyed-union: a positive column number; rerun: a command, not
#              `-`; every other kind: `-`
#   protected  a resolver on a path the schema rule reserves; the detail begins
#              with felix_land_protected's word
#   duplicate  a path an earlier row already binds. The earlier row stands, and
#              a row refused as cells claims no path
_felix_land_scan() {   # rows|bad <- table text
  local mode="$1" text k p ere_bad="" prot="" w
  text="$(cat; printf .)"; text="${text%.}"
  while IFS=$'\t' read -r k p; do
    [ -n "$k" ] && [ -n "$p" ] || continue
    case " ${FELIX_LAND_NARROWING:-} " in
      *" $k "*)
        printf '' | grep -E -- "$p" >/dev/null 2>&1
        [ "$?" -eq 2 ] && ere_bad="$ere_bad$p"$'\n'
        ;;
      *)
        case " ${FELIX_LAND_KINDS:-} " in
          *" $k "*)
            w="$(felix_land_protected "$p" 2>/dev/null)" && prot="$prot$p"$'\t'"$w"$'\n' ;;
        esac ;;
    esac
  done <<EOF
$(printf '%s' "$text" | S="${FELIX_TABLE_SKIP:-^[[:space:]]*(#|$)}" LC_ALL=C awk -F'\t' '
    $0 ~ ENVIRON["S"] || /\r/ || NF != 4 || $1 == "" || $2 == "" { next }
    { print $2 "\t" $1 }')
EOF
  printf '%s' "$text" | S="${FELIX_TABLE_SKIP:-^[[:space:]]*(#|$)}" K="${FELIX_LAND_KINDS:-}" \
    N="${FELIX_LAND_NARROWING:-}" B="$ere_bad" PR="$prot" LC_ALL=C awk -F'\t' -v mode="$mode" '
    function literal(s, dir,   n, seg, i) {
      if (s !~ "^[A-Za-z0-9._][-A-Za-z0-9._/]*$" || index(s, "//")) return 0
      if (!dir && substr(s, length(s)) == "/") return 0
      n = split(s, seg, "/")
      for (i = 1; i <= n; i++) if (seg[i] == "." || seg[i] == "..") return 0
      return 1
    }
    function refuse(reason, detail) {
      nbad++; if (mode == "bad") printf "%d\t%s\t%s\n", NR, reason, detail
    }
    BEGIN {
      n = split(ENVIRON["K"], a, " "); for (i = 1; i <= n; i++) kind[a[i]] = 1
      n = split(ENVIRON["N"], a, " "); for (i = 1; i <= n; i++) narrow[a[i]] = 1
      n = split(ENVIRON["B"], a, "\n"); for (i = 1; i <= n; i++) if (a[i] != "") badere[a[i]] = 1
      n = split(ENVIRON["PR"], a, "\n")
      for (i = 1; i <= n; i++) { t = index(a[i], "\t"); if (t) prot[substr(a[i], 1, t - 1)] = substr(a[i], t + 1) }
    }
    $0 ~ ENVIRON["S"] { next }
    {
      if (/\r/ || NF != 4 || $1 == "" || $2 == "" || $3 == "" || $4 == "") {
        refuse("cells", NF " cell(s), an empty cell or a CR; a land row is exactly path, kind, trigger and arg"); next
      }
      p = $1; k = $2; t = $3; g = $4; bad = 0
      dup = (p in seen); if (!dup) seen[p] = NR
      if (!(k in kind)) {
        refuse("kind", "\"" k "\" is not one of: " ENVIRON["K"])
        if (dup) refuse("duplicate", "line " seen[p] " already binds this path")
        next
      }
      nar = (k in narrow)
      if (p == "-") pathok = 0
      else if (nar) pathok = !(p in badere)
      else pathok = literal(p, 0)
      if (!pathok) { bad = 1; refuse("path", nar ? "a " k " path is an ERE that grep accepts, and never -" \
                                                 : "a " k " path is a plain repository-relative path, compared by equality") }
      if (nar ? t != "-" : (t != "-" && !literal(t, 1))) {
        bad = 1; refuse("trigger", nar ? "a " k " row takes no trigger, since nothing is owed on a path the actor may never write" \
                                       : "a trigger is - or a repository-relative path; ending in / names a directory")
      }
      if (k == "keyed-union") argok = (g ~ /^[1-9][0-9]*$/)
      else if (k == "rerun") argok = (g != "-")
      else argok = (g == "-")
      if (!argok) { bad = 1; refuse("arg", k == "keyed-union" ? "keyed-union takes the key column, a positive number" \
                                         : (k == "rerun" ? "rerun takes the command it runs, not -" : k " takes no argument, so it is -")) }
      if (!nar && pathok && (p in prot)) {
        bad = 1; refuse("protected", prot[p] ": only a session or founder row may bind this path")
      }
      if (dup) { bad = 1; refuse("duplicate", "line " seen[p] " already binds this path") }
      if (!bad && mode == "rows") print
    }
    END { exit (mode == "bad" && nbad > 0) }'
}

# The rows the schema accepts, byte for byte and in file order, one per line.
felix_land_rows_in() { _felix_land_scan rows; return 0; }

# One line per refusal: <line> TAB <reason> TAB <detail>. Exit 1 when there is
# any, 0 when there is none.
felix_land_malformed_in() { _felix_land_scan bad; }

# The text of a project's land.tsv as refs/remotes/origin/main holds it.
# Exit 1, printing nothing on either stream, when the project is not inside a
# repository, is the repository's own toplevel, when there is no such ref, or
# no table at it. Only that ref: not felix_base_ref's fallback to a local main,
# not a branch, not the tree. cat-file, so no filter the tree could declare
# stands between the blob and what is read.
felix_land_table_at_base() {   # proj -> text
  local proj repo rel
  [ -n "${1:-}" ] || return 1
  proj="$(CDPATH='' cd -- "$1" >/dev/null 2>&1 && pwd -P)" || return 1
  repo="$(git -C "$proj" rev-parse --show-toplevel 2>/dev/null)" || return 1
  [ -n "$proj" ] && [ -n "$repo" ] && [ "$proj" != "$repo" ] || return 1
  case "$proj" in "$repo"/*) rel="${proj#"$repo"/}/land.tsv" ;; *) return 1 ;; esac
  git -C "$repo" rev-parse --verify --quiet 'refs/remotes/origin/main^{commit}' >/dev/null 2>&1 || return 1
  git -C "$repo" cat-file -e "refs/remotes/origin/main:$rel" >/dev/null 2>&1 || return 1
  git -C "$repo" cat-file blob "refs/remotes/origin/main:$rel" 2>/dev/null
}

# A project's accepted rows at the base. Nothing, and still 0, with no table:
# an absent table binds no path, and that is not a fault.
felix_land_rows() {
  local t
  t="$(felix_land_table_at_base "${1:-}")" || return 0
  printf '%s\n' "$t" | felix_land_rows_in
  return 0
}

# A project's refusals at the base, as felix_land_malformed_in says them.
# Exit 1 when there is any; 0 when there is none or no table.
felix_land_malformed() {
  local t
  t="$(felix_land_table_at_base "${1:-}")" || return 0
  printf '%s\n' "$t" | felix_land_malformed_in
}

# owed: the rows this landing owes. One line per row, <path> TAB <kind> TAB
# <trigger>, in table order, for each accepted row at the base whose trigger
# the landing touches and whose path it does not. What the landing touches is
# felix_changed_paths: what merging would change, staged and unstaged edits
# included. A row whose trigger is `-` is never owed. Exit 0 when computed,
# output possibly empty; 2, printing nothing, when the base is empty or names
# nothing here.
felix_land_owed() {   # proj root base
  local proj="${1:-}" root="${2:-}" base="${3:-}" changed rows
  [ -n "$base" ] || return 2
  felix_base_resolves "$root" "$base" || return 2
  changed="$(felix_changed_paths "$root" "$base" 2>/dev/null)"
  rows="$(felix_land_rows "$proj" 2>/dev/null)"
  [ -n "$rows" ] || return 0
  printf '%s\n' "$rows" | C="$changed" LC_ALL=C awk -F'\t' '
    BEGIN { n = split(ENVIRON["C"], c, "\n") }
    NF < 3 || $3 == "-" { next }
    { hit = 0; done = 0; dir = (substr($3, length($3)) == "/")
      for (i = 1; i <= n; i++) {
        if (c[i] == "") continue
        if (c[i] == $3 || (dir && index(c[i], $3) == 1)) hit = 1
        if (c[i] == $1) done = 1
      }
      if (hit && !done) printf "%s\t%s\t%s\n", $1, $2, $3 }'
  return 0
}

# behind: whether HEAD lacks the base's tip. When it does, prints
# <base> TAB <base sha> TAB <head sha> and exits 0; exits 1 when HEAD holds it;
# 2, printing nothing, when it cannot tell: an empty base, one that names
# nothing, no HEAD commit, or git failing some other way. Local refs only, no
# fetch: this is as current as the last fetch, which is why it only reports.
felix_merge_behind() {   # root base
  local root="${1:-}" base="${2:-}" bsha hsha rc
  [ -n "$root" ] && [ -n "$base" ] || return 2
  bsha="$(git -C "$root" rev-parse --verify --quiet "$base^{commit}" 2>/dev/null)" || return 2
  hsha="$(git -C "$root" rev-parse --verify --quiet 'HEAD^{commit}' 2>/dev/null)" || return 2
  [ -n "$bsha" ] && [ -n "$hsha" ] || return 2
  git -C "$root" merge-base --is-ancestor "$bsha" "$hsha" >/dev/null 2>&1; rc=$?
  case "$rc" in
    0) return 1 ;;
    1) printf '%s\t%s\t%s\n' "$base" "$bsha" "$hsha"; return 0 ;;
    *) return 2 ;;
  esac
}

# What owed and behind would refuse, written to says.log as `would-refuse`
# rows, at most two and behind first, and nothing else: nothing on stdout or
# stderr, and exit 0 whatever happens, because this runs inside the merge
# boundary and must not change what it says or how it exits.
#
# Written in every project, with a land table or without one, since behind
# needs none; and whether or not other blockers fire, since the rows record
# what these two checks alone would say. The refused and merged rows say what
# happened, joined to these by branch and time. A dry run writes nothing,
# whatever it would have found: FELIX_MERGE_DRY_RUN=1, which cmd_merge sets
# from its own flag, reaches the judge's child shell through the environment.
#
# A row the schema refuses at the base is an owed item, by line and reason: a
# table that cannot be read is not a clean one.
felix_land_would_refuse() {   # proj base root
  local proj="${1:-}" base="${2:-}" root="${3:-}" branch head behind items bb bs bh
  [ "${FELIX_MERGE_DRY_RUN:-}" = "1" ] && return 0
  [ -n "$base" ] || return 0
  command -v felix_say >/dev/null 2>&1 || return 0
  felix_base_resolves "$root" "$base" >/dev/null 2>&1 || return 0
  branch="$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null)"
  [ -n "$branch" ] || branch=HEAD
  head="$(git -C "$root" rev-parse 'HEAD^{commit}' 2>/dev/null)"
  if behind="$(felix_merge_behind "$root" "$base" 2>/dev/null)"; then
    IFS=$'\t' read -r bb bs bh <<EOF
$behind
EOF
    felix_say "$proj" "would-refuse" "$(printf '%s: behind: %s %s is not in HEAD %s' "$branch" "$bb" "$bs" "$bh")" \
      "felix merge" "${CLAUDE_CODE_SESSION_ID:-}" >/dev/null 2>&1
  fi
  items="$( { felix_land_owed "$proj" "$root" "$base" 2>/dev/null \
                | awk -F'\t' 'NF >= 3 { printf "%s (%s on %s)\n", $1, $2, $3 }'
              felix_land_malformed "$proj" 2>/dev/null \
                | awk -F'\t' 'NF >= 2 { printf "land.tsv line %s refused: %s\n", $1, $2 }'
            } | awk 'NF { printf "%s%s", s, $0; s = "; " }' )"
  if [ -n "$items" ]; then
    felix_say "$proj" "would-refuse" "$(printf '%s: owed: %s at HEAD %s' "$branch" "$items" "$head")" \
      "felix merge" "${CLAUDE_CODE_SESSION_ID:-}" >/dev/null 2>&1
  fi
  return 0
}

# Loaded after every function above, so escape.sh, which loads this file from
# its own last lines, finds felix_land_rows defined and does not load it again.
# escape.sh brings _felix_escape_listed and the escape lists the schema rule
# reads; commission.sh brings the commission list, when escape.sh did not.
if ! command -v felix_escapes >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/escape.sh" 2>/dev/null
fi
if [ -z "${FELIX_COMMISSION_TABLES:-}" ]; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/commission.sh" 2>/dev/null
fi
:
