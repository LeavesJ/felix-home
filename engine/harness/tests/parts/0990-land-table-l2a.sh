printf '\nland table (L2a)\n'
# The landing actor's recipe book, and the two checks that will one day stop a
# landing, before either stops anything. projects/<name>/land.tsv says how each
# path lands: a resolver kind (version-above, keyed-union, insertions-union,
# rerun) is a path the actor may settle without a session, and a narrowing
# kind (session, founder) is one it may not. So the schema refuses a resolver
# on any path whose change is an escape, a commission, an authority grant, an
# exception or the trust base: a table that let the actor settle risk.tsv by
# itself would be a quiet way round everything else in this file. The table is
# read only from refs/remotes/origin/main, because a pull request must not
# rewrite the recipe that lands it, and any change to it escapes to a person.
#
# `owed` and `behind` only report in this step. Each writes a would-refuse row
# to says.log and prints nothing, refuses nothing and moves no exit status, so
# how a session lands is unchanged; a dry run writes nothing at all.
#
# Written blind against the contract (the landing-actor design §4 and §11 step
# 3, through the L2a spec), before the implementation was read. Every positive
# assertion here fails against an engine with no lib/land-table.sh; each
# negative one sits beside a positive sibling in the same fixture. The
# assertions the three reviews added (the exact exemption comparison, every
# says.log row counted, uncommitted and behind owed cases, narrowed, the skip
# pattern and functions from the environment, only 0 writing, the land-table
# row, schema-check) were written by the implementer, not blind. Each was shown
# failing for the reason its name gives: against the unfixed branch engine
# where that engine had the defect, and against a one-line mutation of the
# fixed one where it did not (an extra says.log row, a committed-only or a
# two-dot diff).

LT_LIB="$FROOT/harness/lib/land-table.sh"
LT_T="$TMP/lt-table.tsv"
# One library call in a subshell, so nothing it defines leaks into the suite,
# and an engine without the library answers with nothing rather than aborting.
_lt()        { ( . "$LT_LIB" 2>/dev/null; "$@" ) 2>/dev/null; }
_lt_row()    { local IFS=$'\t'; printf '%s\n' "$*"; }
_lt_ed()     { awk "$1" "$2" > "$2.lt" && mv "$2.lt" "$2"; }   # <awk program> <file>: rewrite in place
_lt_lacks()  { case "$2" in *"$3"*) bad "$1" "[$2] holds [$3]" ;; *) ok "$1" ;; esac; }
_lt_state()  { git -C "$1" merge-base --is-ancestor refs/remotes/origin/main HEAD >/dev/null 2>&1 && echo current || echo behind; }
# What the schema says of the table in <file>, as one string: how many rows
# felix_land_rows_in accepts, each refusal as line:reason (a protected one with
# the category word its detail begins with), and felix_land_malformed_in's exit
# status. Against an engine without the library it reads rows=0 refused= rc=127.
_lt_verdict() {
  printf 'rows=%s refused=%s rc=%s' \
    "$(_lt felix_land_rows_in < "$1" | awk 'END { print NR }')" \
    "$(_lt felix_land_malformed_in < "$1" | awk -F'\t' '{ w = ""; if ($2 == "protected") { split($3, d, "[^a-z-]"); w = ":" d[1] }
                                                        printf "%s%s:%s%s", s, $1, $2, w; s = "," }')" \
    "$( ( . "$LT_LIB" 2>/dev/null; felix_land_malformed_in < "$1" >/dev/null 2>&1; echo $? ) )"
}

# ------------------------------------------------------- rows and kinds ----
# felix-home's seven rows, exactly as the design gives them (§4). The hash is
# the design's, so a typo here cannot quietly weaken every assertion that reads
# this file.
{ _lt_row engine/.claude-plugin/plugin.json   version-above    engine/ -
  _lt_row engine/harness/tests/assertions.tsv keyed-union      -       2
  _lt_row engine/harness/tests/red.tsv        rerun            engine/ 'engine/harness/tests/red <B>'
  _lt_row engine/harness/tests/run            insertions-union -       -
  _lt_row HANDOFF.md                          session          -       -
  _lt_row 'projects/[^/]+/CLAUDE\.md'         founder          -       -
  _lt_row 'docs/.*roadmap.*'                  founder          -       -
} > "$TMP/lt-seven.tsv"
LT_SEVEN="$TMP/lt-seven.tsv"
is  "the land-table fixture's seven rows are the design's, byte for byte, by their hash" \
    "$(git hash-object "$LT_SEVEN" 2>/dev/null)" "3dc2dcb4612f4bb0226ef5a5b9f30ba173619d60"

# A reader that drops, reorders or rewrites a row fails the first; a schema
# that refuses one of the design's own rows fails the second.
is  "felix_land_rows_in prints felix-home's seven rows exactly as written, or the landing actor would read a table the founder never armed" \
    "$(_lt felix_land_rows_in < "$LT_SEVEN")" "$(cat "$LT_SEVEN")"
is  "and felix_land_malformed_in refuses none of them and exits 0, or the design's own table would read as broken" \
    "$(_lt_verdict "$LT_SEVEN")" "rows=7 refused= rc=0"

# The one definition of a row is table.sh's. A reader that takes a comment,
# a commented-out row or a blank line for a row fails the first; one that
# numbers refusals by data row instead of by line fails the second.
{ printf '# x\n'; printf '# path\tkind\ttrigger\targ\n'
  _lt_row a.txt version-above engine/ -
  printf '\n'
  printf '#b.txt\tversion-above\t-\t-\n'
  _lt_row c.txt merge-ours - -
  printf '   \n'
  _lt_row d.txt insertions-union - -
} > "$LT_T"
is  "comments, a commented-out row and blank lines are not rows, or a note in the table would bind a path" \
    "$(_lt felix_land_rows_in < "$LT_T")" "$(printf 'a.txt\tversion-above\tengine/\t-\nd.txt\tinsertions-union\t-\t-')"
is  "and a refusal carries its line in the file, comments counted, or the founder is sent to the wrong line" \
    "$(_lt_verdict "$LT_T")" "rows=2 refused=6:kind rc=1"
# The judge's child shell inherits the session's environment and never loads
# table.sh, so a skip pattern read from there would be the session's choice.
is  "which lines are rows does not follow a FELIX_TABLE_SKIP the session exported, or the environment would choose the rows the judge reads" \
    "$( ( FELIX_TABLE_SKIP='^(engine|projects|docs|HANDOFF)'; export FELIX_TABLE_SKIP
          . "$LT_LIB" 2>/dev/null; felix_land_rows_in < "$LT_SEVEN" ) 2>/dev/null | awk 'END { print NR }' )" "7"

# A last row the editor left without a newline is still a row, and it is
# printed with one, or the next reader glues it to whatever follows.
printf 'a.txt\tversion-above\t-\t-' > "$LT_T"
is  "a final row with no newline is read, and printed ending in one, or the last recipe in a table would vanish or run into the next line" \
    "$(_lt felix_land_rows_in < "$LT_T"; printf x)" "$(printf 'a.txt\tversion-above\t-\t-\nx')"

# cells: the shape two readers split differently. Each is refused for that
# alone, read by no one, and fails the table.
printf 'a.txt\tversion-above\t-\n' > "$LT_T"
is  "a three-cell row is refused as cells alone and read by no one, or a reader would invent its missing arg" \
    "$(_lt_verdict "$LT_T")" "rows=0 refused=1:cells rc=1"
printf 'a.txt\tversion-above\t-\t-\textra\n' > "$LT_T"
is  "a five-cell row is refused as cells alone, or a stray tab would carry a column past the schema" \
    "$(_lt_verdict "$LT_T")" "rows=0 refused=1:cells rc=1"
printf 'a.txt\t\tengine/\t-\n' > "$LT_T"
is  "a row with an empty cell is refused as cells alone and not as a kind, or a reader collapsing the empty cell would shift every cell after it" \
    "$(_lt_verdict "$LT_T")" "rows=0 refused=1:cells rc=1"
printf 'a.txt\tversion-above\t-\t-\r\n' > "$LT_T"
is  "a row ending in a CR is refused as cells alone, or a reader keeping the CR would bind an arg no other reader sees" \
    "$(_lt_verdict "$LT_T")" "rows=0 refused=1:cells rc=1"
printf 'a.txt\tversion\r-above\t-\t-\n' > "$LT_T"
is  "and a CR inside a cell is cells too, never kind, or the reason would depend on where the CR fell" \
    "$(_lt_verdict "$LT_T")" "rows=0 refused=1:cells rc=1"

# kind: the kinds are the engine's. A kind the engine does not define is one
# reason on its own, since no column rule applies without one; duplicate is the
# only reason it does not hide.
printf 'a.txt\tmerge-ours\t-\t-\n' > "$LT_T"
is  "a kind the engine does not define is refused as kind, or a table could invent its own way to land a path" \
    "$(_lt_verdict "$LT_T")" "rows=0 refused=1:kind rc=1"
printf '/abs\tmerge-ours\ta b\t-\n' > "$LT_T"
is  "and an unknown kind is that row's only reason, its bad path and trigger unsaid, or the refusal would judge columns no kind defines" \
    "$(_lt_verdict "$LT_T")" "rows=0 refused=1:kind rc=1"
{ _lt_row a.txt version-above - -; _lt_row a.txt merge-ours - -; } > "$LT_T"
is  "but an unknown kind on a path an earlier row binds is a duplicate as well, or a second recipe for one path would go unnamed" \
    "$(_lt_verdict "$LT_T")" "rows=1 refused=2:kind,2:duplicate rc=1"
is  "the kinds are engine constants, the design's six, with session and founder the narrowing two, or a kind could be added without an engine change" \
    "$( . "$LT_LIB" 2>/dev/null; printf '%s|%s' "${FELIX_LAND_KINDS:-}" "${FELIX_LAND_NARROWING:-}" )" \
    "version-above keyed-union insertions-union rerun session founder|session founder"

# path: a resolver is compared to a changed path by string equality, so its
# path must be a plain repository-relative literal. Each line is one shape a
# looser check lets through.
{ for _ltp in 'engine/[a-z]+.sh' /abs/x ../x a/../b -x dir/ a//b -; do _lt_row "$_ltp" version-above - -; done; } > "$LT_T"
is  "a resolver path that is an ERE, absolute, dot-dot, dash-led, slash-ended, double-slashed or the dash itself is refused as path, or it would bind a path no change can equal" \
    "$(_lt_verdict "$LT_T")" "rows=0 refused=1:path,2:path,3:path,4:path,5:path,6:path,7:path,8:path rc=1"
printf 'docs/(\tsession\t-\t-\n' > "$LT_T"
is  "a narrowing path that is not a valid ERE is refused as path, or grep would match it against nothing and the narrowing row would narrow nothing" \
    "$(_lt_verdict "$LT_T")" "rows=0 refused=1:path rc=1"
_lt_row 'projects/[^/]+/CLAUDE\.md' founder - - > "$LT_T"
is  "while an ERE on a founder row is accepted and printed as written, backslash included, or the design's own founder row would be lost" \
    "$(_lt felix_land_rows_in < "$LT_T")|$(_lt_verdict "$LT_T")" "$(cat "$LT_T")|rows=1 refused= rc=0"

# trigger: a literal, which may end in a slash to name a directory; and only
# the dash on a narrowing row, since nothing is owed on a path the actor may
# never write.
{ _lt_row a.txt version-above 'engine//' -; _lt_row b.txt version-above ../x -; _lt_row c.txt version-above 'a b' -; } > "$LT_T"
is  "a trigger with a doubled slash, a dot-dot or a space is refused as trigger, or it would match changes nobody meant" \
    "$(_lt_verdict "$LT_T")" "rows=0 refused=1:trigger,2:trigger,3:trigger rc=1"
{ _lt_row HANDOFF.md session engine/ -; _lt_row docs/x founder engine/ -; } > "$LT_T"
is  "any trigger on a session or founder row is refused as trigger, or a path the actor may never write could be owed" \
    "$(_lt_verdict "$LT_T")" "rows=0 refused=1:trigger,2:trigger rc=1"
{ _lt_row a.txt version-above engine/ -; _lt_row b.txt version-above engine/harness/felix -; } > "$LT_T"
is  "while a directory trigger ending in a slash and a file trigger are accepted on a version-above row, or felix-home's own rows could not be written" \
    "$(_lt_verdict "$LT_T")" "rows=2 refused= rc=0"

# arg: each kind's column rule.
{ _lt_row k1.txt keyed-union - -; _lt_row k2.txt keyed-union - 0; _lt_row k3.txt keyed-union - x; } > "$LT_T"
is  "a keyed-union arg that is not a positive integer is refused as arg, or the union would key on a column that does not exist" \
    "$(_lt_verdict "$LT_T")" "rows=0 refused=1:arg,2:arg,3:arg rc=1"
_lt_row r1.txt rerun - - > "$LT_T"
is  "a rerun row whose command is the dash is refused as arg, or the actor would settle the path by running nothing" \
    "$(_lt_verdict "$LT_T")" "rows=0 refused=1:arg rc=1"
{ _lt_row v1.txt version-above - 2; _lt_row i1.txt insertions-union - 2; _lt_row s1.txt session - 2; _lt_row f1.txt founder - 2; } > "$LT_T"
is  "an arg on a version-above, insertions-union, session or founder row is refused as arg, or a cell the kind never reads would pass as meaningful" \
    "$(_lt_verdict "$LT_T")" "rows=0 refused=1:arg,2:arg,3:arg,4:arg rc=1"
{ _lt_row k.txt keyed-union - 2; _lt_row r.txt rerun - 'a b <B>'; } > "$LT_T"
is  "while keyed-union on column 2 and a rerun command with spaces and <B> are accepted, or felix-home's own rows could not be written" \
    "$(_lt_verdict "$LT_T")" "rows=2 refused= rc=0"

# duplicate: one path, one recipe, and the first stands.
{ _lt_row a.txt version-above - -; _lt_row a.txt insertions-union - -; } > "$LT_T"
is  "a second row on the same path is refused as duplicate and the first is the one read, or one path would have two recipes" \
    "$(_lt felix_land_rows_in < "$LT_T")|$(_lt_verdict "$LT_T")" "$(printf 'a.txt\tversion-above\t-\t-')|rows=1 refused=2:duplicate rc=1"
{ printf 'a.txt\tversion-above\t-\n'; _lt_row a.txt insertions-union - -; } > "$LT_T"
is  "but a row refused as cells claims no path, so the next row on that path stands, or a broken line would disable a good one" \
    "$(_lt_verdict "$LT_T")" "rows=1 refused=1:cells rc=1"
# narrowed: a resolver never overrides a session or founder row, whichever
# comes first, and a narrowing ERE covers the literal paths it matches.
{ _lt_row HANDOFF.md version-above - -; _lt_row HANDOFF.md session - -; } > "$LT_T"
is  "a resolver above a session row on the same path is refused as narrowed and the session row stands, or a row placed first would take a path back from a session" \
    "$(_lt felix_land_rows_in < "$LT_T")|$(_lt_verdict "$LT_T")" "$(printf 'HANDOFF.md\tsession\t-\t-')|rows=1 refused=1:narrowed rc=1"
{ _lt_row 'docs/.*roadmap.*' founder - -; _lt_row docs/2026-roadmap.md version-above - -; _lt_row docs/notes.md version-above - -; } > "$LT_T"
is  "a resolver on a path a founder row's ERE matches is refused as narrowed, while one on a path it does not match stands, or a literal row could carve a path out of the founder's" \
    "$(_lt_verdict "$LT_T")" "rows=2 refused=2:narrowed rc=1"
# Every applicable reason, in the contract's order, once cells and kind pass.
{ _lt_row /abs version-above - -; _lt_row /abs keyed-union 'a b' 0
  _lt_row projects/p/risk.tsv version-above - 2; _lt_row projects/p/risk.tsv version-above - 2; } > "$LT_T"
is  "a row with several faults reports each of them in the order path, trigger, arg, protected, duplicate, or a fixed fault would uncover another one round later" \
    "$(_lt_verdict "$LT_T")" \
    "rows=0 refused=1:path,2:path,2:trigger,2:arg,2:duplicate,3:arg,3:protected:escape-table,4:arg,4:protected:escape-table,4:duplicate rc=1"

# ------------------------------------------ the schema rule, the trust base ----
# Only a session or the founder may bind a path whose change is an escape, a
# commission, an authority grant, an exception or the trust base. Each path
# below is refused for a resolver with the category its detail names, and
# felix_land_protected prints that same word; the order of the categories is
# pinned by projects/p/land.tsv (also an escape table, said as land-table) and
# projects/p/risk.tsv (also a commission table, said as escape-table).
LT_PROT='projects/p/risk.tsv|escape-table
projects/p/qualification.tsv|escape-table
engine/harness/templates/schemas.tsv|escape-table
projects/p/stack.tsv|commission-table
projects/p/capabilities|commission-table
.github/workflows/gate.yml|execute
.github/actions/a/action.yml|execute
projects/p/autonomy|authority
projects/p/autonomy.commission|authority
projects/p/exceptions.tsv|exception
exceptions.tsv|exception
projects/p/land.tsv|land-table
engine/harness/lib/escape.sh|trust-base
engine/harness/lib/land-table.sh|trust-base
engine/harness/felix|trust-base
engine/hooks/hooks.json|trust-base
engine/harness/hooks/pre-tool|trust-base
projects/p/gate.sh|trust-base'
_lt_prot() {  # <path> [kind] [arg]: felix_land_protected's word and status, then the schema's verdict on one row of that kind there
  local w r
  w="$( ( . "$LT_LIB" 2>/dev/null; felix_land_protected "$1" ) </dev/null 2>/dev/null )"
  r="$( ( . "$LT_LIB" 2>/dev/null; felix_land_protected "$1" >/dev/null 2>&1; echo $? ) </dev/null )"
  _lt_row "$1" "${2:-version-above}" - "${3:--}" > "$LT_T"
  printf '%s %s | %s' "$w" "$r" "$(_lt_verdict "$LT_T")"
}
while IFS='|' read -r _ltp _ltc; do
  is "a version-above row on $_ltp is refused as protected, $_ltc, or the landing actor could settle that path without a session" \
     "$(_lt_prot "$_ltp" </dev/null)" "$_ltc 0 | rows=0 refused=1:protected:$_ltc rc=1"
done <<EOF
$LT_PROT
EOF
# The rule is about resolvers, not about version-above: each other resolver
# kind, on one path of every category.
_lt_cat7() {  # <kind> <arg>
  { _lt_row projects/p/risk.tsv "$1" - "$2"; _lt_row projects/p/stack.tsv "$1" - "$2"
    _lt_row .github/workflows/gate.yml "$1" - "$2"; _lt_row projects/p/autonomy "$1" - "$2"
    _lt_row projects/p/exceptions.tsv "$1" - "$2"; _lt_row projects/p/land.tsv "$1" - "$2"
    _lt_row engine/harness/felix "$1" - "$2"; } > "$LT_T"
  _lt_verdict "$LT_T"; }
LT_CAT7='rows=0 refused=1:protected:escape-table,2:protected:commission-table,3:protected:execute,4:protected:authority,5:protected:exception,6:protected:land-table,7:protected:trust-base rc=1'
is  "a keyed-union row is refused on a path of every protected category, or the rule would bind one resolver kind and leave the others open" \
    "$(_lt_cat7 keyed-union 2)" "$LT_CAT7"
is  "and so is an insertions-union row, or a protected table could be landed by concatenation" \
    "$(_lt_cat7 insertions-union -)" "$LT_CAT7"
is  "and so is a rerun row, or a command would rewrite a protected path unattended" \
    "$(_lt_cat7 rerun x)" "$LT_CAT7"
# Narrowing rows are the point of those paths, so they are never refused there.
_lt_narrow() {  # <kind>: a row of that kind on every protected path
  while IFS='|' read -r _ltp _ltc; do _lt_row "$_ltp" "$1" - -; done > "$LT_T" <<EOF
$LT_PROT
EOF
  _lt_verdict "$LT_T"; }
is  "a session row on every protected path is accepted, or a table could not route those paths to a session at all" \
    "$(_lt_narrow session)" "rows=18 refused= rc=0"
is  "and so is a founder row on every one of them, or the founder could not keep them" \
    "$(_lt_narrow founder)" "rows=18 refused= rc=0"
# The rule names paths, not their neighbours: a check by prefix, by directory
# or by extension fails here.
LT_NEAR='engine/harness/lib/say.sh engine/harness/lib/table.sh engine/harness/lib/island.sh projects/p/q/gate.sh projects/p/gate.sh.bak docs/gate.sh .github/CODEOWNERS projects/p/notes.tsv engine/.claude-plugin/plugin.json'
{ for _ltp in $LT_NEAR; do _lt_row "$_ltp" version-above - -; done; } > "$LT_T"
is  "a version-above row on a near neighbour of a protected path is accepted, or the rule would refuse by resemblance and not by the list" \
    "$(_lt_verdict "$LT_T")" "rows=9 refused= rc=0"
is  "and felix_land_protected prints nothing and exits 1 for each of those neighbours, or it could not say a path is ordinary" \
    "$( ( . "$LT_LIB" 2>/dev/null; for _ltp in $LT_NEAR; do _ltw="$(felix_land_protected "$_ltp" 2>&1)"; _ltr=$?
          [ "$_ltr:$_ltw" = "1:" ] || printf '%s(%s:%s) ' "$_ltp" "$_ltr" "$_ltw"; done ) </dev/null )" ""

# The trust base: fourteen entries, two of them patterns. A star spans no
# slash, and the match is whole-path.
LT_TB14='engine/harness/lib/escape.sh engine/harness/lib/commission.sh engine/harness/lib/autonomy.sh engine/harness/lib/landing.sh engine/harness/lib/resolve.sh engine/harness/lib/verify.sh engine/harness/lib/deny.sh engine/harness/lib/deny-read.sh engine/harness/lib/where.sh engine/harness/lib/where-read.sh engine/harness/hooks/pre-tool engine/hooks/hooks.json engine/harness/felix projects/p/gate.sh'
_lt_tbrc() {  # <path>...: felix_land_trust_base's status for each, space-separated
  ( . "$LT_LIB" 2>/dev/null; _lts=""
    for _ltp in "$@"; do felix_land_trust_base "$_ltp" >/dev/null 2>&1; _lts="$_lts${_lts:+ }$?"; done
    printf '%s' "$_lts" ) </dev/null; }
is  "felix_land_trust_base exits 0, printing nothing, for an instance of each of the fourteen trust-base entries, or the schema could not refuse a resolver there" \
    "$( ( . "$LT_LIB" 2>/dev/null; for _ltp in $LT_TB14; do _ltw="$(felix_land_trust_base "$_ltp" 2>&1)"; _ltr=$?
          [ "$_ltr:$_ltw" = "0:" ] || printf '%s(%s:%s) ' "$_ltp" "$_ltr" "$_ltw"; done ) </dev/null )" ""
is  "and exits 1 for a sibling of an entry and for a gate.sh one directory too deep, or a star would span a slash and the base would swallow its neighbours" \
    "$(_lt_tbrc engine/harness/lib/island.sh projects/p/q/gate.sh)" "1 1"
# An unquoted expansion of the list globs its two starred entries against the
# caller's directory. This directory holds one file for each, so a list split
# that way turns both into those files and misses every other instance.
LT_G="$TMP/lt-glob"; mkdir -p "$LT_G/projects/zz" "$LT_G/engine/harness/lib"
: > "$LT_G/projects/zz/gate.sh"; : > "$LT_G/engine/harness/lib/landzz.sh"
is  "the glob fixture would turn both starred trust-base entries into its own files if they were expanded unquoted" \
    "$( cd "$LT_G" && set -- projects/*/gate.sh engine/harness/lib/land*.sh; printf '%s ' "$@" )" \
    "projects/zz/gate.sh engine/harness/lib/landzz.sh "
is  "and from inside it both starred entries still match as patterns, or the trust base would depend on the caller's directory" \
    "$( cd "$LT_G" && _lt_tbrc projects/p/gate.sh engine/harness/lib/landing.sh )" "0 0"
is  "and the schema still refuses a resolver on projects/p/gate.sh from there, or a table checked in the wrong directory would pass" \
    "$( cd "$LT_G" && _lt_prot projects/p/gate.sh </dev/null )" "trust-base 0 | rows=0 refused=1:protected:trust-base rc=1"

# Fail closed: when a list the rule reads is missing, every path is protected,
# said as unknown. Blanked after the library loaded, so the question is what
# the function does with what it finds, not what loading does.
_lt_fc() {  # <what to blank>: felix_land_protected engine/x afterwards, as [word] status
  ( . "$LT_LIB" 2>/dev/null
    case "$1" in
      commission) FELIX_COMMISSION_TABLES='' ;;
      tables)     FELIX_ESCAPE_TABLES='' ;;
      execute)    FELIX_ESCAPE_EXECUTE='' ;;
      lister)     unset -f _felix_escape_listed ;;
    esac
    _ltw="$(felix_land_protected engine/x 2>/dev/null)"; _ltr=$?; printf '[%s] %s' "$_ltw" "$_ltr" ) </dev/null; }
is  "felix_land_protected finds an ordinary engine path unprotected while its lists are loaded, exit 1 and no word" \
    "$(_lt_fc none)" "[] 1"
is  "but with the commission list blanked it says unknown and exits 0, or a missing list would let a resolver through" \
    "$(_lt_fc commission)" "[unknown] 0"
is  "and the schema then refuses a version-above row on that path as protected, unknown, or the fail-closed word would protect nothing" \
    "$( ( . "$LT_LIB" 2>/dev/null; FELIX_COMMISSION_TABLES=''
          _lt_row engine/x version-above - - | felix_land_malformed_in 2>/dev/null \
            | awk -F'\t' '{ split($3, d, "[^a-z-]"); printf "%s%s:%s", s, $2, d[1]; s = "," }' ) </dev/null )" "protected:unknown"
is  "and it fails closed the same way with the escape list or the execute list blanked, or with the lister gone" \
    "$(_lt_fc tables) $(_lt_fc execute) $(_lt_fc lister)" "[unknown] 0 [unknown] 0 [unknown] 0"

# --------------------------------------------- read from the base ref only ----
# A repository R holding projects/lt/, whose table is committed on local main
# before any origin/main exists. Its fourth line is a row the schema refuses.
LT_C="$TMP/lt-base"; mkdir -p "$LT_C"
( cd "$LT_C" && git init -q -b main && git config user.email t@t && git config user.name t \
  && mkdir -p projects/lt projects/ltnone \
  && printf '{ "name": "lt" }\n' > projects/lt/project.json && printf '{ "name": "ltnone" }\n' > projects/ltnone/project.json \
  && { printf '# the table origin/main holds\n'; _lt_row a.txt version-above engine/ -
       _lt_row b.txt insertions-union - -; _lt_row c.txt merge-ours - -; } > projects/lt/land.tsv \
  && _lt_row top.txt version-above - - > land.tsv \
  && git add -A && git commit -qm c1 ) >/dev/null 2>&1
LT_C="$(cd "$LT_C" && pwd -P)"
LT_CP="$LT_C/projects/lt"
LT_CROWS="$(printf 'a.txt\tversion-above\tengine/\t-\nb.txt\tinsertions-union\t-\t-')"
_lt_at()  {  # <proj dir>: felix_land_table_at_base's status, then what it printed
  ( . "$LT_LIB" 2>/dev/null; _lto="$(felix_land_table_at_base "$1" 2>/dev/null)"; _ltr=$?; printf '%s|%s' "$_ltr" "$_lto" ) </dev/null; }
_lt_mal() {  # <proj dir>: felix_land_malformed's status, then each refusal as line:reason
  ( . "$LT_LIB" 2>/dev/null; _lto="$(felix_land_malformed "$1" 2>/dev/null)"; _ltr=$?
    printf '%s|%s' "$_ltr" "$(printf '%s' "$_lto" | awk -F'\t' '{ printf "%s%s:%s", s, $1, $2; s = "," }')" ) </dev/null; }
_lt_count() { awk -v r="$1" 'index($0, r) == 1 { n++ } END { print n+0 }'; }   # <row prefix>: rows on stdin that begin with it

is  "the base-read fixture has its table committed on local main and no origin/main yet" \
    "$(git -C "$LT_C" show main:projects/lt/land.tsv >/dev/null 2>&1 && echo on-main || echo missing)|$(git -C "$LT_C" rev-parse -q --verify refs/remotes/origin/main >/dev/null 2>&1 && echo origin || echo no-origin)" \
    "on-main|no-origin"
# A reader that falls back to local main, as felix_base_ref does, fails here.
is  "with no origin/main the table is not read at all, local main's copy included, or a local branch could stand in for the base" \
    "$(_lt_at "$LT_CP") rows=[$(_lt felix_land_rows "$LT_CP")]" "1| rows=[]"
git -C "$LT_C" update-ref refs/remotes/origin/main HEAD >/dev/null 2>&1
is  "once origin/main holds the table, felix_land_table_at_base prints it as that ref holds it, or the base could not be read at all" \
    "$(_lt_at "$LT_CP")" "0|$(git -C "$LT_C" show refs/remotes/origin/main:projects/lt/land.tsv 2>/dev/null)"
is  "and felix_land_rows prints its accepted rows and leaves out the one refused, or a broken row would bind a path" \
    "$(_lt felix_land_rows "$LT_CP")" "$LT_CROWS"
is  "and felix_land_malformed reports that refused row by its line and exits 1, or a table that cannot be read would pass for a clean one" \
    "$(_lt_mal "$LT_CP")" "1|4:kind"
is  "a project with no land.tsv at origin/main has no table: status 1, no rows and nothing malformed, or an absent table would read as a broken one" \
    "$(_lt_at "$LT_C/projects/ltnone") rows=[$(_lt felix_land_rows "$LT_C/projects/ltnone")] $(_lt_mal "$LT_C/projects/ltnone")" "1| rows=[] 0|"
is  "the repository's toplevel is not a project, so a land.tsv at the root of origin/main is never read as one" \
    "$(_lt_at "$LT_C")" "1|"
is  "a project path spelled through a dot-dot is resolved before its table is looked up, or the same project would read two ways" \
    "$(_lt felix_land_rows "$LT_C/projects/ltnone/../lt")" "$LT_CROWS"

# A row the base does not hold, in each place a session can put one. Reading
# the working tree, HEAD or the local branch fails one of these three.
_lt_row d.txt version-above - - >> "$LT_CP/land.tsv"
is  "a row added in the working tree only is not read, or an uncommitted edit would rewrite the recipe" \
    "$(_lt felix_land_rows "$LT_CP")" "$LT_CROWS"
( cd "$LT_C" && git checkout -q -b feat && git add -A && git commit -qm 'a row on the branch' ) >/dev/null 2>&1
is  "the base-read fixture's branch commit holds a row origin/main lacks" \
    "$(git -C "$LT_C" show feat:projects/lt/land.tsv 2>/dev/null | _lt_count d.txt)|$(git -C "$LT_C" show refs/remotes/origin/main:projects/lt/land.tsv 2>/dev/null | _lt_count d.txt)" "1|0"
is  "and that row, committed on a branch origin/main does not hold, is not read, or a pull request could rewrite the recipe that lands it" \
    "$(_lt felix_land_rows "$LT_CP")" "$LT_CROWS"
( cd "$LT_C" && git checkout -q main && _lt_row e.txt version-above - - >> projects/lt/land.tsv \
  && git commit -qam 'a row on local main' && git checkout -q feat ) >/dev/null 2>&1
is  "the base-read fixture's local main holds a row origin/main lacks, and the checkout stands on its branch" \
    "$(git -C "$LT_C" show main:projects/lt/land.tsv 2>/dev/null | _lt_count e.txt)|$(git -C "$LT_C" show refs/remotes/origin/main:projects/lt/land.tsv 2>/dev/null | _lt_count e.txt)|$(git -C "$LT_C" rev-parse --abbrev-ref HEAD 2>/dev/null)" "1|0|feat"
is  "a row committed on local main while origin/main is behind it is not read, or the base would be whatever the local branch says" \
    "$(_lt felix_land_rows "$LT_CP")" "$LT_CROWS"
# Outside any repository there is no base at all, whatever the directory holds.
LT_O="$TMP/lt-outside/projects/lt"; mkdir -p "$LT_O"; _lt_row a.txt version-above engine/ - > "$LT_O/land.tsv"
_ltn="a project outside any repository has no base table: status 1, and nothing on stdout or stderr, or a file on disk would pass for the base"
if git -C "$LT_O" rev-parse --show-toplevel >/dev/null 2>&1; then
  skip "$_ltn" "the suite's temporary directory is inside a git repository"
else
  is "$_ltn" "$( ( . "$LT_LIB" 2>/dev/null; felix_land_table_at_base "$LT_O" 2>&1; printf '|%s' "$?" ) </dev/null )" "|1"
fi

# ------------------------------------------------------ escape membership ----
# land.tsv joins the exemption tables beside ecosystem.tsv: a resolver row is a
# path the actor may settle without a session and a narrowing row is one it
# may not, so adding a row widens, removing one widens, and no edit is free
# but a comment. felix_escapes on a project with no risk.tsv, so only the
# engine's own channels speak. Each case is one commit on top of the base.
LT_E="$TMP/lt-escape"; LT_EP="$TMP/lt-escape-proj"; mkdir -p "$LT_E" "$LT_EP"
( cd "$LT_E" && git init -q -b main && git config user.email t@t && git config user.name t \
  && mkdir -p projects/anyproj some/dir && printf 'notes\n' > README.md \
  && { printf '# how each path lands\n'; _lt_row a.txt version-above engine/ -; _lt_row b.txt insertions-union - -
       printf '#c.txt\tversion-above\t-\t-\n'; _lt_row 'docs/.*roadmap.*' founder - -
       _lt_row e.txt session - -; _lt_row e.txt founder - -; } > projects/anyproj/land.tsv \
  && _lt_row a.txt version-above - - > some/dir/land.tsv \
  && { printf '# kind\tpath\twords\tnote\n'; _lt_row allow lib/y.sh npm prose; } > ecosystem.tsv \
  && git add -A && git commit -qm base ) >/dev/null 2>&1
LT_E="$(cd "$LT_E" && pwd -P)"
LT_EB="$(git -C "$LT_E" rev-parse -q --verify HEAD 2>/dev/null)"
LT_EL=projects/anyproj/land.tsv
_lt_esc() { ( cd "$LT_E" && . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"
              felix_escapes "$LT_EP" "$LT_EB" "$LT_E" ) </dev/null 2>/dev/null; }
# The channels felix_escapes names for <path> once the edit is committed on
# the base, or `unchanged` when the edit left the tree as the base had it, so
# a quiet answer is never a fixture that did nothing.
_lt_echan() {  # <path> <edit command...>, run at the repository root
  local p="$1"; shift
  ( cd "$LT_E" && git reset -q --hard "$LT_EB" && git clean -qfd && "$@" && git add -A \
      && git -c user.name=t -c user.email=t@t commit -qm edit ) >/dev/null 2>&1
  if git -C "$LT_E" diff --quiet "$LT_EB" HEAD 2>/dev/null; then printf 'unchanged'; return 0; fi
  _lt_esc | awk -F'\t' -v p="$p" '$2 == p { print $1 }' | LC_ALL=C sort -u | awk '{ printf "%s%s", s, $0; s = " " }'
}
_lt_e_new() { mkdir -p projects/newproj && _lt_row a.txt version-above - - > projects/newproj/land.tsv; }
is  "adding a row to a land table escapes as verifier, or a branch could grant the actor a path and merge green" \
    "$(_lt_echan "$LT_EL" _lt_ed '1; END { print "d.txt\tversion-above\t-\t-" }' "$LT_EL")" "verifier"
has "and says why: its rows exempt things from a check, which is why growth is not free there" \
    "$(_lt_esc | awk -F'\t' -v p="$LT_EL" '$2 == p { print $3 }')" "exempt"
is  "removing a row escapes as verifier, or dropping a narrowing row would hand its path to the actor unseen" \
    "$(_lt_echan "$LT_EL" _lt_ed '!/^b\.txt\t/' "$LT_EL")" "verifier"
is  "commenting a row out escapes as verifier, or a hash mark would remove a row unseen" \
    "$(_lt_echan "$LT_EL" _lt_ed '/^a\.txt\t/ { $0 = "#" $0 } 1' "$LT_EL")" "verifier"
is  "turning a comment into a row escapes as verifier, or deleting a hash mark would add a row unseen" \
    "$(_lt_echan "$LT_EL" _lt_ed '/^#c\.txt\t/ { sub(/^#/, "") } 1' "$LT_EL")" "verifier"
is  "editing one cell of a row in place escapes as verifier, or a narrowing row could be turned into a resolver unseen" \
    "$(_lt_echan "$LT_EL" _lt_ed '/^b\.txt\t/ { sub(/insertions-union/, "version-above") } 1' "$LT_EL")" "verifier"
# Three edits a comparison of sorted, comma-stripped lines reads as no change,
# while the reader sees each: a comma on the last cell is an arg it refuses, so
# the founder row is dropped; of two rows on one path the first stands, so a
# swap changes which; and a repeated line is a duplicate it refuses.
is  "appending a comma to a founder row's last cell escapes as verifier, or the reader would drop that founder row with nobody asked" \
    "$(_lt_echan "$LT_EL" _lt_ed '/^docs\/\.\*roadmap/ { $0 = $0 "," } 1' "$LT_EL")" "verifier"
is  "swapping two rows that bind the same path escapes as verifier, or which of them stands could change with nobody asked" \
    "$(_lt_echan "$LT_EL" _lt_ed '/^e\.txt\tsession\t/ { held = $0; next } { print } /^e\.txt\tfounder\t/ { print held }' "$LT_EL")" "verifier"
is  "repeating a row exactly escapes as verifier, or a line the reader refuses as a duplicate would arrive unseen" \
    "$(_lt_echan "$LT_EL" _lt_ed '{ print } /^a\.txt\t/ { print }' "$LT_EL")" "verifier"
is  "and a comma added to an ecosystem.tsv row escapes as verifier too, since every exemption table is compared as its reader reads it" \
    "$(_lt_echan ecosystem.tsv _lt_ed '/^allow\tlib\/y\.sh\t/ { $0 = $0 "," } 1' ecosystem.tsv)" "verifier"
# The control for the five above, in the same fixture: prose stays free.
is  "rewording only a comment line in it escapes nothing, or every note about the table would go to the founder" \
    "$(_lt_echan "$LT_EL" _lt_ed '/^# how each path lands$/ { $0 = "# how each path is landed" } 1' "$LT_EL")" ""
is  "creating a land table with a row where the base had none escapes as verifier, or a new project's first recipe would land unseen" \
    "$(_lt_echan projects/newproj/land.tsv _lt_e_new)" "verifier"
is  "deleting a land table that had rows escapes as verifier, or every narrowing row in it would go at once unseen" \
    "$(_lt_echan "$LT_EL" git rm -q "$LT_EL")" "verifier"
is  "a land.tsv in any directory is one by its basename, and a row added to some/dir/land.tsv escapes as verifier" \
    "$(_lt_echan some/dir/land.tsv _lt_ed '1; END { print "b.txt\tversion-above\t-\t-" }' some/dir/land.tsv)" "verifier"
is  "and a row added to ecosystem.tsv still escapes as verifier, or land.tsv replaced the exemption table it was meant to join" \
    "$(_lt_echan ecosystem.tsv _lt_ed '1; END { print "allow\tlib/x.sh\tcargo\tprose" }' ecosystem.tsv)" "verifier"
( cd "$LT_E" && git reset -q --hard "$LT_EB" && git clean -qfd ) >/dev/null 2>&1
is  "the exemption tables are exactly ecosystem.tsv and land.tsv, or any change to a land table would not reach a person" \
    "$( . "$FROOT/harness/lib/escape.sh" 2>/dev/null; printf '%s' "${FELIX_ESCAPE_EXEMPTION_TABLES:-}" )" "ecosystem.tsv land.tsv"
is  "and land.tsv is named once among the escape tables, as a basename, or a project's table under a name the engine does not know would be missed" \
    "$( . "$FROOT/harness/lib/escape.sh" 2>/dev/null
        printf '%s\n' "${FELIX_ESCAPE_TABLES:-}" | awk '{ for (i = 1; i <= NF; i++) if ($i == "land.tsv") n++ } END { print n+0 }' )" "1"
# Not a commission table: the policy hash covers every listed name whether or
# not the file exists, so joining that list would move every governed
# project's hash on deploy. The pair above is the red sibling of these two.
is  "but the commission tables stay byte-identical with land.tsv loaded, or every governed project's policy hash would move on deploy" \
    "$( . "$FROOT/harness/lib/detect.sh" 2>/dev/null; . "$FROOT/harness/lib/commission.sh" 2>/dev/null; . "$LT_LIB" 2>/dev/null
        printf '%s' "${FELIX_COMMISSION_TABLES:-}" )" \
    "project.json capabilities commissioning.tsv stack.tsv profiles.tsv routes.tsv setup.tsv probes.tsv risk.tsv evidence.tsv deny.tsv obligations.tsv"
LT_PV="$TMP/lt-policy"; mkdir -p "$LT_PV"
printf 'marker\t-\t-\t-\t-\ttest -f .felix\t9\n' > "$LT_PV/commissioning.tsv"
_lt_pv() { ( . "$FROOT/harness/lib/detect.sh" 2>/dev/null; . "$FROOT/harness/lib/commission.sh" 2>/dev/null
             . "$LT_LIB" 2>/dev/null; felix_commission_policy_version "$LT_PV" 2>/dev/null ) </dev/null; }
_ltpv0="$(_lt_pv)"; _lt_row a.txt version-above - - > "$LT_PV/land.tsv"; _ltpv1="$(_lt_pv)"
is  "and a project's commission policy version is the same with and without a land.tsv beside its tables, or writing one would stale its receipt" \
    "$([ -n "$_ltpv0" ] && [ "$_ltpv0" = "$_ltpv1" ] && echo same || echo "moved: [$_ltpv0] [$_ltpv1]")" "same"

