# The reads behind escape.sh's channels that are neither a path constant nor a
# table: the names git hands over, destructive SQL in the added lines, what a
# workflow holding credentials runs, and docs/direction.md.
#
# They live here because escape.sh has a ceiling of 799 lines and these are the
# channels audit batch b10 widened. escape.sh loads this file itself. A copy of
# the lib directory without it is refused, not trusted: felix_escapes prints an
# `unknown` row naming CHANGED-PATHS (escape.sh). classify.sh loads it for
# _felix_escape_names, so the two read a change's paths one way.
#
# Every function here either prints rows in the shape felix_escapes prints
# (channel <TAB> path <TAB> reason) or answers by its status, and none of them
# decides that nothing is wrong when it could not read: a git read that fails is
# an `unknown` row, said once, and never an empty answer.

# The changed paths, read as the names they are (audit b10, C015).
#
# felix_changed_paths runs `git diff --name-only` under whatever core.quotePath
# the caller, the repository or the machine holds. By default git then writes a
# name holding a byte past ASCII as "d\303\251ploy.yml", with the quotes, and
# every anchored channel and every basename test missed it: a workflow named
# .github/workflows/déploy.yml merged with nothing asked. The read is done here
# with core.quotePath off, appended the way `git -c` appends, which beats the
# repository's config, GIT_CONFIG_PARAMETERS and GIT_CONFIG_COUNT alike, in a
# subshell, so the caller's environment is the caller's after the return.
#
# Git still quotes a name with a double quote, a backslash or a control
# character (tab, line feed, DEL) in it, and every such name starts with `"`.
# That cannot be handed to a channel as a path, and cannot be waved through
# either, so each is said as an unknown row naming CHANGED-PATHS, with the name
# as git writes it, and is left out of the list. A name that is only non-ASCII
# is not unknown. felix_changed_paths is in resolve.sh, which is batch 12's file
# and is not edited here; moving it to -z would make this unnecessary, and then
# must still flag a name holding a line feed or a tab, which git's quoting flags
# today.
#
# Assigns the readable paths, newline separated, to the variable named by the
# first argument, prints the unknown rows, and returns 1 when felix_changed_paths
# did not read every source to the end, as it does.
_felix_escape_names() {   # VAR ROOT BASE
  local _fen_var="$1" _fen_all _fen_q _fen_line _fen_rc=0
  _fen_all="$( export GIT_CONFIG_PARAMETERS="${GIT_CONFIG_PARAMETERS:+$GIT_CONFIG_PARAMETERS }'core.quotepath=false'"
               felix_changed_paths "$2" "$3" )" || _fen_rc=1
  printf -v "$_fen_var" '%s' "$(printf '%s\n' "$_fen_all" | LC_ALL=C grep -v '^"')"
  _fen_q="$(printf '%s\n' "$_fen_all" | LC_ALL=C grep '^"')"
  while IFS= read -r _fen_line; do
    [ -n "$_fen_line" ] || continue
    printf 'unknown\tCHANGED-PATHS\ta changed path is named with a quote, a backslash or a control character, which git writes as an escape, so it was not scanned as a path; rename it: %s\n' "$_fen_line"
  done <<EOF
$_fen_q
EOF
  return "$_fen_rc"
}

# Whether the added lines hold a destructive SQL statement (audit b10, C021).
# Exit 0 when one does. The argument is felix_added_lines' output, each line
# still carrying the diff's leading +.
#
# The statements are DROP of a TABLE, SCHEMA, DATABASE or COLUMN; ALTER TABLE
# with a DROP after the name; TRUNCATE; DELETE FROM a name; and UPDATE a name
# SET a column =. DELETE and UPDATE count only on a line with no word WHERE, in
# any case and as a whole word, so `nowhere` is not one. A statement written in
# capitals fires anywhere on a line, which is what the channel did for DROP
# TABLE, TRUNCATE and DELETE FROM before. Written in any other case it fires
# only as the first text on the line, because prose and code say "we drop
# tables" and "update the set of rules"; a lower-case truncate must then be
# followed by an optional table and one name and the end of the statement.
# Blanks are spaces and tabs, and a carriage return counts as one at the end of
# a line.
#
# Not matched, and said in the contract: lower-case SQL in the middle of a line
# of code, ORM verbs, and a statement whose name is on the next line.
_felix_escape_sql() {   # ADDED-LINES
  LC_ALL=C awk '
    function wherew(s) { return s ~ /(^|[^A-Za-z0-9_])[Ww][Hh][Ee][Rr][Ee]($|[^A-Za-z0-9_])/ }
    function caps(s) {
      if (s ~ /DROP[ \t]+(TABLE|SCHEMA|DATABASE|COLUMN)([ \t\r;]|$)/) return 1
      if (s ~ /ALTER[ \t]+TABLE[ \t]+[^ \t]+[ \t]+(.*[ \t])?DROP([ \t\r;]|$)/) return 1
      if (s ~ /TRUNCATE[ \t]/) return 1
      if (s ~ /DELETE[ \t]+FROM[ \t]+[^ \t]/ && !wherew(s)) return 1
      if (s ~ /UPDATE[ \t]+[^ \t]+[ \t]+SET[ \t]+[^ \t=]+[ \t]*=/ && !wherew(s)) return 1
      return 0
    }
    function first(t,   u) {
      u = tolower(t)
      if (u ~ /^drop[ \t]+(table|schema|database|column)([ \t\r;]|$)/) return 1
      if (u ~ /^alter[ \t]+table[ \t]+[^ \t]+[ \t]+(.*[ \t])?drop([ \t\r;]|$)/) return 1
      if (u ~ /^truncate[ \t]+(table[ \t]+)?[^ \t;]+[ \t\r]*;?[ \t\r]*$/) return 1
      if (u ~ /^delete[ \t]+from[ \t]+[^ \t]/ && !wherew(u)) return 1
      if (u ~ /^update[ \t]+[^ \t]+[ \t]+set[ \t]+[^ \t=]+[ \t]*=/ && !wherew(u)) return 1
      return 0
    }
    { s = $0; sub(/^\+/, "", s)
      t = s; sub(/^[ \t\r]+/, "", t)
      if (caps(s) || first(t)) { hit = 1; exit } }
    END { exit !hit }' <<<"$1"
}

# docs/direction.md, however the file system spells it (audit b10, C006). The
# row is the founder's: the file says what Felix builds and for whom, and a
# change to it binds every session after it. Case is folded because a case
# folding file system, this Mac's, names one file with every spelling.
FELIX_ESCAPE_DIRECTION='^[Dd][Oo][Cc][Ss]/[Dd][Ii][Rr][Ee][Cc][Tt][Ii][Oo][Nn]\.[Mm][Dd]$'
_felix_escape_direction() {   # PATH
  LC_ALL=C grep -qE "$FELIX_ESCAPE_DIRECTION" <<<"$1" || return 0
  printf 'direction\t%s\tthis document says what Felix builds and for whom, and a change to it binds every session after it; only the founder changes it, by a yes\n' "$1"
}

# What a workflow holding credentials runs (audit b10, C081).
#
# A job that declares an environment, asks for an OIDC token or holds
# write-all permissions has, on its first run on the default branch, credentials
# a branch's own run never held. The workflow file is an execute row already.
# The files it runs are not, and a push-to-main deploy job that runs
# ./scripts/deploy.sh let a branch rewrite that script and merge with no escape.
#
# A workflow counts when it is a top-level .github/workflows/*.yml or *.yaml
# at the base (HEAD when there is no base) and one of its lines starts, after
# blanks, with `environment:`, `id-token: write` or `permissions: write-all`.
# Its text is split at every byte but an ASCII letter, digit, `.`, `_`, `/` and
# `-`; leading `./` and `/` come off each word; a changed path that equals a
# word is run by it, and so is every changed path under a directory a
# `uses: ./dir` line names. Repository secrets alone do not count: a branch's
# own CI run reads them before any merge, so the merge is not where they are
# held.
#
# Read from git objects, by the blob, never from the working tree, so a named
# pipe where a workflow was cannot stall it and an edited workflow cannot vouch
# for itself. A path .github/workflows or .github/actions already names gets no
# second row, and a path gets one row however many workflows name it. A read
# that fails is an unknown row naming CHANGED-PATHS and .github/workflows,
# never an empty answer. Prints rows; returns 0.
_felix_escape_wfruns() {   # ROOT BASE PATHS
  local root="$1" ref="$2" paths="$3" listing line meta name rest type sha mode text facts hits p seen="" nl=$'\n' tab=$'\t'
  if [ -z "$ref" ]; then
    git -C "$root" rev-parse -q --verify HEAD >/dev/null 2>&1 || return 0
    ref=HEAD
  fi
  if ! listing="$( export GIT_CONFIG_PARAMETERS="${GIT_CONFIG_PARAMETERS:+$GIT_CONFIG_PARAMETERS }'core.quotepath=false'"
                   git -C "$root" ls-tree --full-tree "$ref" -- .github/workflows/ 2>/dev/null )"; then
    printf 'unknown\tCHANGED-PATHS\tgit could not list .github/workflows at %s, so the files a workflow runs were not checked\n' "$ref"
    return 0
  fi
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    name="${line#*"$tab"}"; meta="${line%%"$tab"*}"
    mode="${meta%% *}"; rest="${meta#* }"; type="${rest%% *}"; sha="${rest#* }"
    [ "$type" = blob ] || continue
    case "$mode" in 100644|100755) ;; *) continue ;; esac
    case "$name" in
      '"'*) printf 'unknown\tCHANGED-PATHS\ta workflow under .github/workflows is named with a character git writes as an escape (%s), so the files it runs were not checked\n' "$name"; continue ;;
      .github/workflows/*.yml|.github/workflows/*.yaml) ;;
      *) continue ;;
    esac
    if ! _felix_git_read text git -C "$root" cat-file blob "$sha"; then
      printf 'unknown\tCHANGED-PATHS\tgit could not read %s at %s (blob %s), so the files it runs were not checked\n' "$name" "$ref" "$sha"
      continue
    fi
    if ! facts="$(LC_ALL=C awk '
      { t = $0; sub(/^[ \t\r]+/, "", t)
        if (t ~ /^environment:/ || t ~ /^id-token:[ \t]+write([ \t\r#]|$)/ || t ~ /^permissions:[ \t]+write-all([ \t\r#]|$)/) cred = 1
        u = t; sub(/^-[ \t]+/, "", u)
        if (u ~ /^uses:[ \t]*["\047]?\.\//) {
          sub(/^uses:[ \t]*["\047]?\.\//, "", u); match(u, "^[A-Za-z0-9._/-]*"); u = substr(u, 1, RLENGTH); sub(/\/+$/, "", u)
          if (u != "") dir[u] = 1 }
        n = split($0, part, "[^A-Za-z0-9._/-]+")
        for (i = 1; i <= n; i++) {
          w = part[i]
          while (w != "") { if (substr(w, 1, 2) == "./") w = substr(w, 3); else if (substr(w, 1, 1) == "/") w = substr(w, 2); else break }
          if (w != "") word[w] = 1 } }
      END { if (cred) { for (w in word) print "W\t" w; for (u in dir) print "D\t" u } }' <<<"$text")"; then
      printf 'unknown\tCHANGED-PATHS\tthe text of %s could not be read here, so the files it runs were not checked\n' "$name"
      continue
    fi
    [ -n "$facts" ] || continue
    if ! hits="$(printf '%s\n' "$paths" | F="$facts" LC_ALL=C awk '
      BEGIN { n = split(ENVIRON["F"], fl, "\n")
              for (i = 1; i <= n; i++) {
                if (substr(fl[i], 1, 2) == "W\t") word[substr(fl[i], 3)] = 1
                else if (substr(fl[i], 1, 2) == "D\t") dir[substr(fl[i], 3)] = 1 } }
      { if ($0 in word) { print; next }
        for (d in dir) if (index($0, d "/") == 1) { print; next } }')"; then
      printf 'unknown\tCHANGED-PATHS\tthe files %s runs could not be matched against the change, so they were not checked\n' "$name"
      continue
    fi
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      case "$nl$seen" in *"$nl$p$nl"*) continue ;; esac
      seen="$seen$p$nl"
      LC_ALL=C grep -qE "$FELIX_ESCAPE_EXECUTE" <<<"$p" && continue
      printf 'execute\t%s\tmerging changes a file that %s runs, and that workflow holds credentials only a run on the default branch gets\n' "$p" "$name"
    done <<EOF
$hits
EOF
  done <<EOF
$listing
EOF
  return 0
}

# The verifier channel's readers. They were in escape.sh, and moved here
# unchanged, comments included, to keep escape.sh under its ceiling.
# felix_escapes calls them.

# Non-comment, non-blank lines present at base and gone at HEAD.
#
# Static blobs on both sides, never two live runs. Running the gate twice to
# compare is nondeterministic against the plugin cache and the two runs clobber
# each other's log; a comparison whose inputs move is not a comparison.
#
# Trailing commas are stripped before comparing, and that is not cosmetic. JSON
# has no trailing comma, so adding a key rewrites the line above it — meaning a
# literal comparison reads every addition to project.json as a removal and fires
# on the most ordinary edit there is. Caught on the commit that declared
# `consumers`, which added two keys and removed nothing. A genuine removal takes
# its whole line with it and is still caught.
# Locale, 2026-10-08: sed stopped at a byte that was not UTF-8 and hid every
# removal below it. The rules are above felix_json_str in resolve.sh.
_felix_escape_lines() {
  felix_file_at "$1" "$2" "$3" \
    | LC_ALL=C grep -vE '^[[:space:]]*(#|$)' \
    | LC_ALL=C sed -E 's/[[:space:]]*,[[:space:]]*$//' \
    | LC_ALL=C sort -u
}

_felix_escape_shrank() {
  local root="$1" base="$2" f="$3" before after
  before="$(_felix_escape_lines "$root" "$base" "$f")"
  [ -n "$before" ] || return 1
  after="$(_felix_escape_lines "$root" HEAD "$f")"
  # 2026-10-08: comm compares in its locale's collation, and both sides are
  # sorted in C. Under LANG=en_US.UTF-8, an added row that sorts before an
  # existing one in bytes and after it in the locale (Zulu and _under) made
  # comm print a row nobody removed, so a pure addition read as a removal.
  # Every sort, comm, join and uniq in the engine runs as LC_ALL=C <tool>,
  # which tests/run lints.
  [ -n "$(LC_ALL=C comm -23 <(printf '%s\n' "$before") <(printf '%s\n' "$after"))" ]
}

# Any change to the rows of an exemption table: the non-comment, non-blank
# lines of the two sides, in file order and byte for byte, differ. Same static
# blobs and the same comment stripping, so a reworded comment is still free.
#
# Deliberately not _felix_escape_lines. Its comma stripping is for project.json,
# which is no exemption table, and its sort -u makes order and repetition
# invisible, while the readers of these tables see both. A land table's reader
# refuses a row whose last cell gained a comma, so the row it bound is gone;
# and it keeps the first of two rows on one path, so swapping them changes the
# row that stands. Compared as sets, both edits read as no change, and a
# founder or session row could be dropped or overridden with nobody asked.
# grep -a and the C locale, so a byte that is not text is compared as a byte
# and never turns one side into grep's "Binary file matches".
_felix_escape_rows_exact() {
  felix_file_at "$1" "$2" "$3" | LC_ALL=C grep -avE '^[[:space:]]*(#|$)'
}

_felix_escape_changed() {
  local root="$1" base="$2" f="$3" before after
  before="$(_felix_escape_rows_exact "$root" "$base" "$f"; printf .)"
  after="$(_felix_escape_rows_exact "$root" HEAD "$f"; printf .)"
  [ "$before" != "$after" ]
}
