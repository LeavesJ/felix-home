# ---------------------------------------------------------------- behind ----
# main at c1, feat at c3 off c1, and origin/main moved to c2, a child of c1
# that feat does not hold. Checked out on feat.
_lt_mkb() {  # <dir> <proj>
  mkdir -p "$1" "$MEM/$2" && ( _fx_cd "$1" && git init -q -b main && git config user.email t@t && git config user.name t \
    && mkdir -p "projects/$2" && printf '{ "name": "%s" }\n' "$2" > "projects/$2/project.json" \
    && printf 'one\n' > one.txt && git add -A && git commit -qm c1 \
    && git checkout -q -b feat && printf 'three\n' > three.txt && git add -A && git commit -qm c3 \
    && git checkout -q --detach main && printf 'two\n' > two.txt && git add -A && git commit -qm c2 \
    && git update-ref refs/remotes/origin/main HEAD && git checkout -q feat ) >/dev/null 2>&1; }
_lt_behind() {  # <root> <base>: felix_merge_behind's status, then what it printed
  ( . "$LT_LIB" 2>/dev/null; _lto="$(felix_merge_behind "$1" "$2" 2>/dev/null)"; _ltr=$?; printf '%s|%s' "$_ltr" "$_lto" ) </dev/null; }
_lt_mkb "$TMP/lt-behind" ltbh; LT_B="$(cd "$TMP/lt-behind" && pwd -P)"
LT_BC2="$(git -C "$LT_B" rev-parse -q --verify 'refs/remotes/origin/main^{commit}' 2>/dev/null)"
LT_BC3="$(git -C "$LT_B" rev-parse -q --verify 'HEAD^{commit}' 2>/dev/null)"
is  "the behind fixture stands where it says: feat does not hold origin/main's commit" \
    "$(git -C "$LT_B" merge-base --is-ancestor "$LT_BC2" HEAD >/dev/null 2>&1 && echo current || echo behind) $(git -C "$LT_B" rev-parse --abbrev-ref HEAD 2>/dev/null)" "behind feat"
is  "a branch that does not hold origin/main's commit is behind, status 0, naming the base and both commits, or a stale branch would land unannounced" \
    "$(_lt_behind "$LT_B" origin/main)" "$(printf '0|origin/main\t%s\t%s' "$LT_BC2" "$LT_BC3")"
_lt_mkb "$TMP/lt-merged" ltmg; LT_B2="$(cd "$TMP/lt-merged" && pwd -P)"
( _fx_cd "$LT_B2" && git merge -q --no-edit refs/remotes/origin/main ) >/dev/null 2>&1
is  "the merged behind fixture holds origin/main once it has merged it" "$(_lt_state "$LT_B2")" "current"
is  "and a branch that has merged origin/main is not behind, status 1 and nothing printed, or every current branch would be reported" \
    "$(_lt_behind "$LT_B2" origin/main)" "1|"
is  "a base that names nothing, or no base at all, cannot be told, status 2 and nothing printed, or a typo would read as current" \
    "$(_lt_behind "$LT_B" no-such) $(_lt_behind "$LT_B" '')" "2| 2|"
LT_B3="$TMP/lt-unborn"; mkdir -p "$LT_B3"
( _fx_cd "$LT_B3" && git init -q -b main && git config user.email t@t && git config user.name t \
  && printf 'one\n' > one.txt && git add -A && git commit -qm c1 && git update-ref refs/remotes/origin/main HEAD \
  && git checkout -q --orphan unborn ) >/dev/null 2>&1
is  "the unborn fixture has no HEAD commit while origin/main resolves" \
    "$(git -C "$LT_B3" rev-parse -q --verify 'HEAD^{commit}' >/dev/null 2>&1 && echo head || echo no-head) $(git -C "$LT_B3" rev-parse -q --verify refs/remotes/origin/main >/dev/null 2>&1 && echo base || echo no-base)" "no-head base"
is  "and a checkout whose HEAD holds no commit cannot be told either, status 2, or a fresh branch would read as current" \
    "$(_lt_behind "$LT_B3" origin/main)" "2|"

# ------------------------------------------------------------------ owed ----
# origin/main carries felix-home's seven rows for projects/ltow, and one row
# with a file trigger for projects/ltc. One branch per case, each cut from
# origin/main and rewriting the files it names.
LT_F="$TMP/lt-owed"; mkdir -p "$LT_F" "$MEM/ltow" "$MEM/ltc"
( _fx_cd "$LT_F" && git init -q -b main && git config user.email t@t && git config user.name t \
  && mkdir -p projects/ltow projects/ltc engine/.claude-plugin engine/harness/tests engine/harness/lib docs src \
  && cp "$LT_SEVEN" projects/ltow/land.tsv && _lt_row out.txt insertions-union src/a.c - > projects/ltc/land.tsv \
  && printf '{ "version": "0.0.1" }\n' > engine/.claude-plugin/plugin.json \
  && printf 'base\n' > engine/harness/tests/red.tsv && printf 'x\n' > engine/harness/lib/x.sh \
  && printf 'a\n' > docs/a.md && printf 'c\n' > src/a.c && printf 'cc\n' > src/a.cc && printf 'out\n' > out.txt \
  && git add -A && git commit -qm c1 && git update-ref refs/remotes/origin/main HEAD ) >/dev/null 2>&1
LT_F="$(cd "$LT_F" && pwd -P)"; LT_FP="$LT_F/projects/ltow"
_lt_fbr() {  # <branch> <file>...
  local b="$1" f; shift
  ( _fx_cd "$LT_F" && git checkout -q -f -B "$b" refs/remotes/origin/main && git clean -qfd \
      && for f in "$@"; do printf 'changed on %s\n' "$b" >> "$f"; done \
      && git add -A && git commit -qm "$b" ) >/dev/null 2>&1; }
_lt_fon() { ( _fx_cd "$LT_F" && git checkout -q -f "$1" && git clean -qfd ) >/dev/null 2>&1; }
_lt_owed() {  # <proj dir> <root> [base]: felix_land_owed's status, then what it printed
  ( unset FELIX_MERGE_DRY_RUN; . "$LT_LIB" 2>/dev/null
    _lto="$(felix_land_owed "$1" "$2" "${3-origin/main}" 2>/dev/null)"; _ltr=$?; printf '%s|%s' "$_ltr" "$_lto" ) </dev/null; }
_lt_fbr f-all  engine/harness/lib/x.sh engine/.claude-plugin/plugin.json engine/harness/tests/red.tsv
_lt_fbr f-docs docs/a.md
_lt_fbr f-ver  engine/.claude-plugin/plugin.json
_lt_fbr f-dash engine/harness/lib/x.sh engine/.claude-plugin/plugin.json engine/harness/tests/red.tsv -
_lt_fbr f-c    src/a.c
_lt_fbr f-cc   src/a.cc
_lt_fbr feat   engine/harness/lib/x.sh
LT_OWED2="$(printf 'engine/.claude-plugin/plugin.json\tversion-above\tengine/\nengine/harness/tests/red.tsv\trerun\tengine/')"
is  "the owed fixture's feat changes engine/harness/lib/x.sh alone against origin/main" \
    "$(git -C "$LT_F" diff --name-only refs/remotes/origin/main HEAD 2>/dev/null)" "engine/harness/lib/x.sh"
is  "a change under engine/ that bumps no version and reruns nothing owes both rows, in table order, or the landing that forgot them goes unnamed" \
    "$(_lt_owed "$LT_FP" "$LT_F")" "0|$LT_OWED2"
_lt_fon f-all
is  "the same change with the version bumped and red.tsv rewritten owes nothing, or a row would stay owed after it was paid" \
    "$(_lt_owed "$LT_FP" "$LT_F")" "0|"
_lt_fon f-docs
is  "a change outside every trigger owes nothing, or a docs branch would be told it owes a version" \
    "$(_lt_owed "$LT_FP" "$LT_F")" "0|"
_lt_fon f-ver
is  "a version bump alone still owes red.tsv, since plugin.json is itself under engine/, or the bump would excuse the rerun" \
    "$(_lt_owed "$LT_FP" "$LT_F")" "0|$(printf 'engine/harness/tests/red.tsv\trerun\tengine/')"
_lt_fon f-c
is  "a trigger naming a file owes its row when that very file changes, or file triggers would bind nothing" \
    "$(_lt_owed "$LT_F/projects/ltc" "$LT_F")" "0|$(printf 'out.txt\tinsertions-union\tsrc/a.c')"
_lt_fon f-cc
is  "but not when a file it merely prefixes changes, since only a trigger ending in a slash names a directory" \
    "$(_lt_owed "$LT_F/projects/ltc" "$LT_F")" "0|"
_lt_fon f-dash
is  "the dash fixture's branch changes a file named - and leaves assertions.tsv and tests/run alone" \
    "$(git -C "$LT_F" diff --name-only refs/remotes/origin/main HEAD 2>/dev/null | awk '$0 == "-" || /assertions\.tsv$/ || /tests\/run$/' | tr '\n' ' ')" "- "
is  "a row whose trigger is - is never owed, not even when a file named - changes and its path is untouched, or the dash would read as a path" \
    "$(_lt_owed "$LT_FP" "$LT_F")" "0|"
( _fx_cd "$LT_F" && git checkout -q -f -B f-tree refs/remotes/origin/main && git clean -qfd \
  && printf 'changed\n' >> engine/harness/lib/x.sh && _lt_row docs/a.md version-above engine/ - >> projects/ltow/land.tsv \
  && git add -A && git commit -qm f-tree && _lt_row out.txt version-above engine/ - >> projects/ltow/land.tsv ) >/dev/null 2>&1
is  "a row that exists only on the branch or only in the working tree is never owed, or a pull request could invent a debt the base does not hold" \
    "$(_lt_owed "$LT_FP" "$LT_F")" "0|$LT_OWED2"
is  "an empty base or one that names nothing cannot be computed, status 2 and nothing printed, or a typo would read as nothing owed" \
    "$(_lt_owed "$LT_FP" "$LT_F" '') $(_lt_owed "$LT_FP" "$LT_F" no-such)" "2| 2|"
# What merging would change includes what is not yet committed: x.sh edited
# on a branch that is origin/main itself, first unstaged, then staged. A reader
# of committed changes only, three dots or two, owes nothing here.
( _fx_cd "$LT_F" && git checkout -q -f -B f-wt refs/remotes/origin/main && git clean -qfd \
  && printf 'edited, not committed\n' >> engine/harness/lib/x.sh ) >/dev/null 2>&1
is  "the uncommitted-change fixture's HEAD is origin/main's commit, and x.sh differs only in the working tree" \
    "$(git -C "$LT_F" rev-parse -q --verify HEAD 2>/dev/null | cut -c1-12) $(git -C "$LT_F" diff --name-only 2>/dev/null) $(git -C "$LT_F" diff --cached --name-only 2>/dev/null | awk 'END { print NR }')" \
    "$(git -C "$LT_F" rev-parse -q --verify refs/remotes/origin/main 2>/dev/null | cut -c1-12) engine/harness/lib/x.sh 0"
is  "an engine change left unstaged owes both rows, or a landing that commits it later would never have been told" \
    "$(_lt_owed "$LT_FP" "$LT_F")" "0|$LT_OWED2"
( _fx_cd "$LT_F" && git add engine/harness/lib/x.sh ) >/dev/null 2>&1
is  "and staged, it owes both rows still, or the index would hide a debt the working tree showed" \
    "$(git -C "$LT_F" diff --cached --name-only 2>/dev/null)|$(_lt_owed "$LT_FP" "$LT_F")" "engine/harness/lib/x.sh|0|$LT_OWED2"

# ---------------------------------------------------- the report-only rows ----
_lt_said()  { awk -F'\t' '$2 == "would-refuse"' "$MEM/$1/says.log" 2>/dev/null; }
_lt_nsaid() { _lt_said "$1" | awk 'END { print NR }'; }
_lt_nall()  { awk 'END { print NR }' "$MEM/$1/says.log" 2>/dev/null || echo 0; }   # every row, whatever its kind
_lt_wr() {  # <proj dir> <root> <session, or - for none> <FELIX_MERGE_DRY_RUN: 1, 0, or - for unset> [base]: felix_land_would_refuse's status, then all it printed
  ( if [ "$3" = - ]; then unset CLAUDE_CODE_SESSION_ID; else CLAUDE_CODE_SESSION_ID="$3"; export CLAUDE_CODE_SESSION_ID; fi
    if [ "$4" = - ]; then unset FELIX_MERGE_DRY_RUN; else FELIX_MERGE_DRY_RUN="$4"; export FELIX_MERGE_DRY_RUN; fi
    . "$LT_LIB" 2>/dev/null
    _lto="$(felix_land_would_refuse "$1" "${5-origin/main}" "$2" 2>&1)"; _ltr=$?; printf '%s|%s' "$_ltr" "$_lto" ) </dev/null; }
# A behind branch, nothing owed: one row, and nothing said anywhere else.
LT_BP="$LT_B/projects/ltbh"
_ltn0="$(_lt_nsaid ltbh)"; _lta0="$(_lt_nall ltbh)"
is  "felix_land_would_refuse on a behind branch prints nothing on stdout or stderr and returns 0, or it could not sit inside the merge boundary unseen" \
    "$(_lt_wr "$LT_BP" "$LT_B" lt-s1 0)" "0|"
_ltn1="$(_lt_nsaid ltbh)"; _lta1="$(_lt_nall ltbh)"
# Counted twice: the would-refuse rows, and every row of any kind. A held or
# refused row beside it would move a figure the report must not move.
is  "and it adds exactly one row to that project's says.log, a would-refuse row and nothing of another kind, or the behind branch would leave no record or move another count" \
    "$((_ltn1 - _ltn0)) $((_lta1 - _lta0))" "1 1"
is  "recorded under the session it ran in, with felix merge as its cause, or the row could not be joined to the attempt" \
    "$(_lt_said ltbh | tail -1 | cut -f3,4)" "$(printf 'lt-s1\tfelix merge')"
has "saying which branch is behind which base, by both commits, or the row would not say what to merge" \
    "$(_lt_said ltbh | tail -1 | cut -f5)" "feat: behind: origin/main $LT_BC2 is not in HEAD $LT_BC3"
_lt_wr "$LT_BP" "$LT_B" - 0 >/dev/null
is  "with no session variable the would-refuse row says unknown in the session column, or it would carry an empty cell" \
    "$(_lt_said ltbh | tail -1 | cut -f3)" "unknown"
_ltn0="$(_lt_nsaid ltbh)"; _lt_wr "$LT_BP" "$LT_B" lt-s1 1 >/dev/null; _ltn1="$(_lt_nsaid ltbh)"
is  "a dry run on the same behind branch adds no row, or says.log would record merges nobody attempted" \
    "$((_ltn1 - _ltn0))" "0"
# Only 0 is a real attempt: cmd_merge sets 0 or 1, and a CLI from before this
# library sets nothing, so unset is what that CLI's --dry-run looks like.
_ltn0="$(_lt_nsaid ltbh)"; _lt_wr "$LT_BP" "$LT_B" lt-s1 - >/dev/null
_ltn1="$(_lt_nsaid ltbh)"; _lt_wr "$LT_BP" "$LT_B" lt-s1 0 >/dev/null; _ltn2="$(_lt_nsaid ltbh)"
is  "with FELIX_MERGE_DRY_RUN unset it adds no row, and with it 0 it adds one, or an older CLI's dry run would write the report" \
    "$((_ltn1 - _ltn0)) $((_ltn2 - _ltn1))" "0 1"
# The owed fixture's feat: owing, not behind.
_lt_fon feat
LT_FH="$(git -C "$LT_F" rev-parse -q --verify HEAD 2>/dev/null)"
is  "the owed fixture's feat is not behind origin/main" "$(_lt_state "$LT_F") $(git -C "$LT_F" rev-parse --abbrev-ref HEAD 2>/dev/null)" "current feat"
_ltn0="$(_lt_nsaid ltow)"; _lta0="$(_lt_nall ltow)"; _lt_wr "$LT_FP" "$LT_F" lt-s1 0 >/dev/null
_ltn1="$(_lt_nsaid ltow)"; _lta1="$(_lt_nall ltow)"
is  "a branch that owes rows and is not behind adds exactly one row, a would-refuse row and nothing of another kind, or the debt would leave no record or move another count" \
    "$((_ltn1 - _ltn0)) $((_lta1 - _lta0))" "1 1"
has "naming each owed path with its kind and trigger, in table order, at HEAD, or the row would not say what is owed" \
    "$(_lt_said ltow | tail -1 | cut -f5)" \
    "feat: owed: engine/.claude-plugin/plugin.json (version-above on engine/); engine/harness/tests/red.tsv (rerun on engine/) at HEAD $LT_FH"
_ltn0="$(_lt_nsaid ltow)"; _lt_wr "$LT_FP" "$LT_F" lt-s1 1 >/dev/null; _ltn1="$(_lt_nsaid ltow)"
is  "and a dry run on that owing branch adds none, or a triage session's dry run would write a report" \
    "$((_ltn1 - _ltn0))" "0"
_lt_fon f-docs
_ltn0="$(_lt_nsaid ltow)"; _lt_wr "$LT_FP" "$LT_F" lt-s1 0 >/dev/null; _ltn1="$(_lt_nsaid ltow)"
is  "a branch neither behind nor owing adds no row, or every clean landing would leave a refusal on record" \
    "$(_lt_state "$LT_F") $((_ltn1 - _ltn0))" "current 0"
# Behind and owing at once: two rows, behind first. origin/main moved the way
# it does on felix-home, by an engine landing that bumped the version and
# rewrote red.tsv, so a two-dot diff against it names both files as changed
# and would read the branch as having paid what it owes.
_lt_mkbo() {  # <dir> <proj>: origin/main carries the seven rows for projects/<proj>; feat changes x.sh and is behind
  mkdir -p "$1" "$MEM/$2" && ( _fx_cd "$1" && git init -q -b main && git config user.email t@t && git config user.name t \
    && mkdir -p "projects/$2" engine/.claude-plugin engine/harness/tests engine/harness/lib docs \
    && cp "$LT_SEVEN" "projects/$2/land.tsv" && printf '{ "version": "0.0.1" }\n' > engine/.claude-plugin/plugin.json \
    && printf 'base\n' > engine/harness/tests/red.tsv && printf 'x\n' > engine/harness/lib/x.sh && printf 'a\n' > docs/a.md \
    && git add -A && git commit -qm c1 \
    && git checkout -q -b feat && printf 'y\n' > engine/harness/lib/x.sh && git commit -qam work \
    && git checkout -q --detach main && printf 'b\n' > docs/b.md \
    && printf '{ "version": "0.0.2" }\n' > engine/.claude-plugin/plugin.json && printf 'main\n' > engine/harness/tests/red.tsv \
    && git add -A && git commit -qm c2 \
    && git update-ref refs/remotes/origin/main HEAD && git checkout -q feat ) >/dev/null 2>&1; }
_lt_mkbo "$TMP/lt-both" ltbo; LT_BO="$(cd "$TMP/lt-both" && pwd -P)"
is  "the behind-and-owing fixture is behind origin/main and changes engine/harness/lib/x.sh alone since the merge-base" \
    "$(_lt_state "$LT_BO") $(git -C "$LT_BO" diff --name-only refs/remotes/origin/main...HEAD 2>/dev/null)" "behind engine/harness/lib/x.sh"
is  "while a two-dot diff against origin/main also names plugin.json and red.tsv, which main's own landing changed" \
    "$(git -C "$LT_BO" diff --name-only refs/remotes/origin/main HEAD 2>/dev/null | tr '\n' ' ')" \
    "docs/b.md engine/.claude-plugin/plugin.json engine/harness/lib/x.sh engine/harness/tests/red.tsv "
_ltn0="$(_lt_nsaid ltbo)"; _lt_wr "$LT_BO/projects/ltbo" "$LT_BO" lt-s1 0 >/dev/null
is  "a branch both behind and owing adds two rows, behind first and then owed, or one of the two reports would be lost" \
    "$(_lt_said ltbo | tail -n +"$((_ltn0 + 1))" | cut -f5 | awk -F': ' '{ printf "%s%s", s, $2; s = " " }')" "behind owed"
has "and the owed row names the version and the record, which main changed and the branch did not, or a behind branch would read as having paid them" \
    "$(_lt_said ltbo | tail -1 | cut -f5)" \
    ": owed: engine/.claude-plugin/plugin.json (version-above on engine/); engine/harness/tests/red.tsv (rerun on engine/) at HEAD "
# A row the schema refuses at the base is not a clean table, and it is not a
# debt either: it is said on its own row, by line, never folded into owed.
LT_RF="$TMP/lt-refused"; mkdir -p "$LT_RF" "$MEM/ltrf"
( _fx_cd "$LT_RF" && git init -q -b main && git config user.email t@t && git config user.name t \
  && mkdir -p projects/ltrf docs && printf 'a\n' > docs/a.md \
  && { printf '# a table with one row the schema refuses\n'; _lt_row a.txt version-above - -
       _lt_row projects/p/risk.tsv version-above - -; } > projects/ltrf/land.tsv \
  && git add -A && git commit -qm c1 && git update-ref refs/remotes/origin/main HEAD \
  && git checkout -q -b feat && printf 'b\n' >> docs/a.md && git commit -qam docs ) >/dev/null 2>&1
LT_RF="$(cd "$LT_RF" && pwd -P)"
_ltn0="$(_lt_nsaid ltrf)"; _lt_wr "$LT_RF/projects/ltrf" "$LT_RF" lt-s1 0 >/dev/null
is  "a row the schema refuses at the base is reported on a land-table row of its own, by line and reason, and in no owed row, or a broken table would pass for a clean one or read as a debt" \
    "$(_lt_said ltrf | tail -n +"$((_ltn0 + 1))" | cut -f5)" "feat: land-table: line 3 refused: protected at HEAD $(git -C "$LT_RF" rev-parse -q --verify HEAD 2>/dev/null)\\n"

# At the merge boundary, called the way _blk calls it. The two rows are the
# only difference a real attempt makes; the blocker lines, byte for byte, and
# the exit status are what they were.
_lt_blk() {  # <proj dir> <root> <stdout file> <FELIX_MERGE_DRY_RUN: 1 or 0>: felix_merge_blockers' status
  ( cd "$2" && FELIX_MERGE_DRY_RUN="$4" && export FELIX_MERGE_DRY_RUN
    . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"
    . "$FROOT/harness/lib/evidence.sh"; . "$FROOT/harness/lib/verify.sh"
    felix_merge_blockers "$1" origin/main "$2" "$FROOT" > "$3" 2>/dev/null; echo "$?" ) </dev/null 2>/dev/null; }
_ltn0="$(_lt_nsaid ltbo)"; _lta0="$(_lt_nall ltbo)"; _ltbr="$(_lt_blk "$LT_BO/projects/ltbo" "$LT_BO" "$TMP/lt-blk-real" 0)"
_ltn1="$(_lt_nsaid ltbo)"; _lta1="$(_lt_nall ltbo)"; _ltbd="$(_lt_blk "$LT_BO/projects/ltbo" "$LT_BO" "$TMP/lt-blk-dry" 1)"
_ltn2="$(_lt_nsaid ltbo)"; _lta2="$(_lt_nall ltbo)"
is  "felix_merge_blockers on a behind and owing branch writes both would-refuse rows and no row of another kind on a real attempt, and nothing on a dry run, or the boundary never reports them or reports more than them" \
    "$((_ltn1 - _ltn0)) $((_lta1 - _lta0)) $((_ltn2 - _ltn1)) $((_lta2 - _lta1))" "2 2 0 0"
is  "while it prints no line whose kind is behind or owed, or cmd_merge would refuse on a check that is only meant to report" \
    "$(awk -F'\t' '$1 == "behind" || $1 == "owed"' "$TMP/lt-blk-real" 2>/dev/null)" ""
is  "and prints byte for byte what the dry run printed, its unverified blocker included, or reporting would change what blocks" \
    "$(grep -q '^unverified' "$TMP/lt-blk-real" 2>/dev/null && cmp -s "$TMP/lt-blk-real" "$TMP/lt-blk-dry" && echo same || echo differs)" "same"
is  "and exits 0 on both, or the judge would take its own library for one that could not be loaded" \
    "$_ltbr $_ltbd" "0 0"

# The judge's own shell: set -u, and only the six libraries it sources. The
# rows prove escape.sh brings land-table.sh with it, and that brings say.sh
# (the row is written) and reads the table by its own scan in that shell,
# which needs nothing from table.sh and nothing from the environment.
_lt_mkbo "$TMP/lt-judge" ltjd; LT_JD="$(cd "$TMP/lt-judge" && pwd -P)"
LT_MARK="$TMP/lt-judge.reached"
_lt_judge() {  # <stdout file> [redefine] [FELIX_MERGE_DRY_RUN: 0 (the default), 1, or - for unset] [FELIX_TABLE_SKIP] [stub]: felix_merge_blockers' status in the judge's shell and load order
  ( cd "$LT_JD" && if [ "${3:-0}" = - ]; then unset FELIX_MERGE_DRY_RUN; else FELIX_MERGE_DRY_RUN="${3:-0}"; export FELIX_MERGE_DRY_RUN; fi
    if [ -n "${4:-}" ]; then FELIX_TABLE_SKIP="$4"; export FELIX_TABLE_SKIP; fi
    if [ -n "${5:-}" ]; then felix_land_rows() { :; }; felix_say() { :; }; export -f felix_land_rows felix_say; fi
    CLAUDE_CODE_SESSION_ID=lt-judge LT_REDEF="${2:-}" LT_MARK="$LT_MARK" \
    bash -c 'set -uo pipefail; k="$1"
      for f in resolve verify review classify evidence escape; do . "$k/lib/$f.sh" 2>/dev/null || exit 3; done
      if [ -n "$LT_REDEF" ]; then felix_land_would_refuse() { : > "$LT_MARK"; : "$lt_never_set"; }; fi
      felix_merge_blockers "$2" "$3" "$4" "$5"' _ "$FROOT/harness" "$LT_JD/projects/ltjd" origin/main "$LT_JD" "$FROOT" \
      > "$1" 2>/dev/null; echo "$?" ) </dev/null; }
_ltn0="$(_lt_nsaid ltjd)"; _ltjr="$(_lt_judge "$TMP/lt-judge-control")"
is  "the judge's own shell still judges a behind and owing branch and exits 0, or the merge boundary would die on the new library" \
    "$_ltjr" "0"
has "and writes the behind row there, or escape.sh does not bring land-table.sh and say.sh into the judge's shell" \
    "$(_lt_said ltjd | tail -n +"$((_ltn0 + 1))" | cut -f5)" "feat: behind: origin/main "
has "and the owed row, or land-table.sh cannot read the table in the judge's shell" \
    "$(_lt_said ltjd | tail -n +"$((_ltn0 + 1))" | cut -f5)" \
    ": owed: engine/.claude-plugin/plugin.json (version-above on engine/); engine/harness/tests/red.tsv (rerun on engine/) at HEAD "
# The session's environment reaches the judge's child shell: a skip pattern
# exported there must not change which rows the judge reads.
_ltn0="$(_lt_nsaid ltjd)"; _lt_judge "$TMP/lt-judge-skip" '' 0 '.' >/dev/null
has "and with FELIX_TABLE_SKIP exported as a pattern every line matches, the judge's owed row is the same, or a session could empty the table the judge reads" \
    "$(_lt_said ltjd | tail -n +"$((_ltn0 + 1))" | cut -f5)" \
    ": owed: engine/.claude-plugin/plugin.json (version-above on engine/); engine/harness/tests/red.tsv (rerun on engine/) at HEAD "
# Functions travel the same way: the child shell imports what the session
# exported, so a library loaded only when its function is missing would give
# way to the session's own felix_land_rows and felix_say.
_ltn0="$(_lt_nsaid ltjd)"; _lt_judge "$TMP/lt-judge-stub" '' 0 '' stub >/dev/null
is  "and with felix_land_rows and felix_say exported by the session as functions that do nothing, the judge still writes both rows, or a session could stand in for the library" \
    "$(_lt_said ltjd | tail -n +"$((_ltn0 + 1))" | cut -f5 | awk -F': ' '{ printf "%s%s", s, $2; s = " " }')" "behind owed"
# Self-governed, a dry run reaches the report only through this environment:
# FELIX_MERGE_DRY_RUN=1, or nothing at all from a CLI older than the library.
_ltn0="$(_lt_nsaid ltjd)"; _ltjd1="$(_lt_judge "$TMP/lt-judge-dry1" '' 1)"; _ltn1="$(_lt_nsaid ltjd)"
_ltjdu="$(_lt_judge "$TMP/lt-judge-dryu" '' -)"; _ltn2="$(_lt_nsaid ltjd)"
_ltjd0="$(_lt_judge "$TMP/lt-judge-dry0" '' 0)"; _ltn3="$(_lt_nsaid ltjd)"
is  "in the judge's shell a dry run and an unset variable write no row, and a real attempt writes two, each exiting 0, or a self-governed dry run would write the report" \
    "$_ltjd1 $((_ltn1 - _ltn0)) $_ltjdu $((_ltn2 - _ltn1)) $_ltjd0 $((_ltn3 - _ltn2))" "0 0 0 0 0 2"
_ltn0="$(_lt_nsaid ltjd)"; _ltjr="$(_lt_judge "$TMP/lt-judge-broken" 1)"; _ltn1="$(_lt_nsaid ltjd)"
is  "a report writer that dies on an unset variable is still reached from the judge's shell, or the containment asserted next is never exercised" \
    "$([ -e "$LT_MARK" ] && echo reached || echo never)" "reached"
is  "and the judge still exits 0 with stdout byte for byte the control's and no row written, or a failing report could fail a merge" \
    "$_ltjr $(cmp -s "$TMP/lt-judge-control" "$TMP/lt-judge-broken" && echo same || echo differs) $((_ltn1 - _ltn0))" "0 same 0"

# Through the real CLI, on a governed product checkout that is behind and has
# no gate receipt, so it stops at unverified before any gh call.
_lt_blockerish() { printf '%s\n' "$1" | awk '{ t = $1; sub(/^[-*]+/, "", t); sub(/:$/, "", t) }
                                             t == "behind" || t == "owed" || index($0, "behind\t") || index($0, "owed\t")'; }
LT_P="$TMP/lt-product"; mkdir -p "$LT_P"
( _fx_cd "$LT_P" && git init -q -b main && git config user.email t@t && git config user.name t \
  && printf 'widget\n' > .felix && printf 'contents\n' > WIDGET.txt && git add -A && git commit -qm c1 \
  && git checkout -q -b feat && printf 'work\n' > work.txt && git add -A && git commit -qm c3 \
  && git checkout -q --detach main && printf 'moved\n' > moved.txt && git add -A && git commit -qm c2 \
  && git update-ref refs/remotes/origin/main HEAD && git checkout -q feat ) >/dev/null 2>&1
LT_P="$(cd "$LT_P" && pwd -P)"
is  "the product checkout is bound to the widget, tracks no plugin.json and is behind origin/main" \
    "$(cat "$LT_P/.felix" 2>/dev/null) $(git -C "$LT_P" ls-files engine/.claude-plugin/plugin.json 2>/dev/null | awk 'END { print NR }') $(_lt_state "$LT_P")" \
    "widget 0 behind"
_ltn0="$(_lt_nsaid widget)"
_ltout="$( cd "$LT_P" && unset FELIX_MERGE_DRY_RUN && "$FELIX" merge --base main 2>&1 )"; _ltrc=$?
_ltn1="$(_lt_nsaid widget)"
is  "a real felix merge on a behind product checkout with no receipt still refuses with exit 3, or reporting changed how it lands" \
    "$_ltrc" "3"
has "and still names the unverified tree, or reporting displaced the blocker that stops it" "$_ltout" "unverified"
is  "and shows no behind or owed blocker, or a report-only check would be read as a refusal" \
    "$(_lt_blockerish "$_ltout")" ""
is  "while it adds exactly one would-refuse row to the widget's says.log, or cmd_merge never reaches the report" \
    "$((_ltn1 - _ltn0))" "1"
has "saying the branch is behind origin/main, or the CLI hands the report a base other than the one it compared" \
    "$(_lt_said widget | tail -1 | cut -f5)" ": behind: origin/main "
_ltn0="$(_lt_nsaid widget)"; ( cd "$LT_P" && "$FELIX" merge --base main --dry-run >/dev/null 2>&1 ); _ltn1="$(_lt_nsaid widget)"
is  "a felix merge --dry-run on the same checkout adds no would-refuse row, or cmd_merge does not tell the report that a dry run is one" \
    "$((_ltn1 - _ltn0))" "0"
_ltn0="$(_lt_nsaid widget)"; ( cd "$LT_P" && FELIX_MERGE_DRY_RUN=1 "$FELIX" merge --base main >/dev/null 2>&1 ); _ltn1="$(_lt_nsaid widget)"
is  "and a real attempt still writes its row when the session exported FELIX_MERGE_DRY_RUN=1, or a session could silence the report by its environment" \
    "$((_ltn1 - _ltn0))" "1"
( _fx_cd "$LT_P" && git merge -q --no-edit refs/remotes/origin/main ) >/dev/null 2>&1
is  "the product checkout holds origin/main once it has merged it" "$(_lt_state "$LT_P")" "current"
_ltn0="$(_lt_nsaid widget)"
_ltout="$( cd "$LT_P" && unset FELIX_MERGE_DRY_RUN && "$FELIX" merge --base main 2>&1 )"; _ltrc=$?
_ltn1="$(_lt_nsaid widget)"
is  "and a real attempt there still refuses on the unverified tree and adds no would-refuse row, or every current branch would be reported behind" \
    "$_ltrc $((_ltn1 - _ltn0))" "3 0"

# -------------------------------------------------------- the table itself ----
# felix-home's own table, where Felix's own repository keeps it. The red run
# stands in the base's tree, which has projects/felix/project.json and no
# land.tsv, and fails these; a tree that is not Felix's own skips them.
LT_HOME="$(cd "$REAL_HARNESS/../.." && pwd)"
LT_FL="$LT_HOME/projects/felix/land.tsv"
_lth1="felix-home's land.tsv holds the design's seven rows, by the hash of its data rows, or the table the founder arms is not the one designed"
_lth2="and its data rows are those seven, verbatim and in order, so a drifted row is shown by name and not only by a hash"
_lth3="and felix_land_malformed_in refuses none of them and exits 0, or the home's own table would bind nothing"
_lth4="and the table validator accepts it under its schemas.tsv row, or schema-check would fail the gate"
if [ -f "$LT_HOME/projects/felix/project.json" ]; then
  if [ -f "$LT_FL" ]; then
    is "$_lth1" "$( ( . "$REAL_HARNESS/lib/table.sh" 2>/dev/null; felix_table_rows "$LT_FL" ) 2>/dev/null | git hash-object --stdin )" \
       "3dc2dcb4612f4bb0226ef5a5b9f30ba173619d60"
    is "$_lth2" "$( ( . "$REAL_HARNESS/lib/table.sh" 2>/dev/null; felix_table_rows "$LT_FL" ) 2>/dev/null )" "$(cat "$LT_SEVEN")"
    is "$_lth3" "$(_lt_verdict "$LT_FL")" "rows=7 refused= rc=0"
    is "$_lth4" "$( ( . "$REAL_HARNESS/lib/table.sh" 2>/dev/null
                      felix_table_check "$REAL_HARNESS/templates/schemas.tsv" "$LT_FL" >/dev/null 2>&1; echo $? ) )" "0"
  else
    for _ltn in "$_lth1" "$_lth2" "$_lth3" "$_lth4"; do bad "$_ltn" "no projects/felix/land.tsv in Felix's own repository"; done
  fi
else
  for _ltn in "$_lth1" "$_lth2" "$_lth3" "$_lth4"; do skip "$_ltn" "not Felix's own repository: no projects/felix/project.json"; done
fi
is  "schemas.tsv declares land.tsv a tree table of path, kind, trigger and arg that may be empty, or every land.tsv would be an undeclared table" \
    "$( ( . "$REAL_HARNESS/lib/table.sh" 2>/dev/null; felix_table_schema "$REAL_HARNESS/templates/schemas.tsv" land.tsv ) 2>/dev/null )" \
    "$(printf 'land.tsv\ttree\tpath kind trigger arg\tallowed')"
mkdir -p "$TMP/lt-schema"; { cat "$LT_SEVEN"; printf 'a.txt\tversion-above\t-\n'; } > "$TMP/lt-schema/land.tsv"
is  "and the validator refuses a three-cell row in a land table as cells, exit 1, or schema-check would pass a row the reader splits wrong" \
    "$( ( . "$REAL_HARNESS/lib/table.sh" 2>/dev/null
          _lto="$(felix_table_check "$REAL_HARNESS/templates/schemas.tsv" "$TMP/lt-schema/land.tsv" 2>/dev/null)"; _ltr=$?
          printf '%s|%s' "$_ltr" "$(printf '%s\n' "$_lto" | cut -f2 | LC_ALL=C sort -u | awk 'NF { printf "%s%s", s, $0; s = " " }')" ) )" "1|cells"
# The gate holds a land table to the schema rule as well as to its cells: a
# row the reader would refuse at landing never merges green. The fixture's
# own schemas.tsv declares land.tsv, so only the rule itself can fail it.
LT_SC="$TMP/lt-schemacheck"; mkdir -p "$LT_SC/engine/harness/templates" "$LT_SC/projects/p"
printf 'schemas.tsv\ttree\ttable lives columns empty\trefused\nland.tsv\ttree\tpath kind trigger arg\tallowed\n' \
  > "$LT_SC/engine/harness/templates/schemas.tsv"
cp "$LT_SEVEN" "$LT_SC/projects/p/land.tsv"
( _fx_cd "$LT_SC" && git init -q -b main && git add -A && git -c user.name=t -c user.email=t@t commit -qm seed ) >/dev/null 2>&1
_lt_sc() { ( cd "$LT_SC" && "$REAL_HARNESS/bin/schema-check" 2>&1; echo "rc=$?" ) </dev/null; }
_ltsc0="$(_lt_sc)"
_lt_row projects/p/risk.tsv version-above - - >> "$LT_SC/projects/p/land.tsv"
_ltsc1="$(_lt_sc)"
is  "schema-check passes a tree whose land table holds felix-home's seven rows, and fails one whose resolver row binds risk.tsv, or a row the reader refuses would merge green" \
    "${_ltsc0##*rc=} ${_ltsc1##*rc=}" "0 1"
has "naming the table's line and the rule it breaks" "$_ltsc1" "projects/p/land.tsv:8	land-protected	escape-table"
# Invariant 1: the kinds are constants, and felix-home's rows live in its own
# table and nowhere in the engine. The first is red while the library does not
# exist; the second is its control.
if [ -f "$REAL_HARNESS/lib/land-table.sh" ]; then
  _ltg="$(grep -Fxf "$LT_SEVEN" "$REAL_HARNESS/lib/land-table.sh" 2>/dev/null)"
else
  _ltg="(no lib/land-table.sh)"
fi
is  "lib/land-table.sh exists and no line of it is one of felix-home's rows, or the engine would name a project's recipe" "$_ltg" ""
is  "and no file among the engine's libraries, CLI, hooks or templates carries one of those rows either, or a project's recipe would live in the engine" \
    "$(grep -rlFxf "$LT_SEVEN" "$REAL_HARNESS/lib" "$REAL_HARNESS/felix" "$REAL_HARNESS/hooks" "$REAL_HARNESS/templates" 2>/dev/null)" ""

printf '\nthe engine makes its scratch under TMPDIR\n'
# Measured 2026-09-24 on macOS 26.3.1: a bare `mktemp` or `mktemp -d` makes its
# file in the per-user /var/folders/.../T whatever TMPDIR says (set, unset, or
# naming a missing directory), while a template under TMPDIR, or -p, honours
# it. GNU mktemp on the Linux runner honours TMPDIR either way. So on a Mac a
# block that points TMPDIR at a fixture and counts what is left there read 0
# for any engine path with a bare mktemp, whether or not that path cleaned up.
# Thirteen such calls sat in felix and six libraries, and one in Felix's gate.
#
# The class, read from the text, since most of those paths (merge, discover,
# the gate's installed check) no fixture here drives cheaply. A call spelled
# some other way than $(mktemp ...) or `mktemp ...` is not seen by it. The
# drive below shows the reading matches what runs. Read from this harness and
# not from a checkout root, so a copy with no checkout around it still has
# its own text read rather than none; the gate is read where there is one.
_mkt_read=0
_mkt_bare="$(for f in "$REAL_HARNESS/felix" "$REAL_HARNESS"/lib/*.sh "$REAL_HARNESS"/bin/* "$REAL_HARNESS"/hooks/* \
               "$REAL_HARNESS/../../projects/felix/gate.sh"; do
               [ -f "$f" ] && grep -nE '\$\(mktemp|`mktemp' "$f" | sed "s|^|${f#"$REAL_HARNESS"/}:|"
             done | grep -vE '^[^:]*:[0-9]+:[[:space:]]*#' | grep -v 'XXXXXX')"
grep -q 'mktemp' "$REAL_HARNESS/felix" && _mkt_read=1
is "every mktemp the engine and Felix's gate run is given a template, so none lands outside TMPDIR on a Mac" \
   "$_mkt_read $_mkt_bare" "1 "

# Driven: a mktemp first on PATH that writes down what it was given and hands
# on to the real one, around the four paths a fixture reaches cheaply. Each
# must name a template under the TMPDIR it was given, and nothing may be left
# there after. The second half is the count that could not fail on a Mac while
# the first half did not hold. Measured with a copy of pulse.sh that keeps its
# scratch index: this count read 1 with the templates and 0 with the bare
# calls, whose index went to /var/folders instead.
MKT="$TMP/mktemp-drive"; mkdir -p "$MKT/bin" "$MKT/tmp" "$MKT/proj" "$MKT/repo" "$MKT/nohandoff"
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s"\nexec "%s" "$@"\n' "$MKT/calls" "$(command -v mktemp)" > "$MKT/bin/mktemp"
chmod +x "$MKT/bin/mktemp"; : > "$MKT/calls"
printf '{\n  "name": "x",\n  "version": "1.2.3"\n}\n' > "$MKT/plugin.json"
printf 'web\tendpoint handler\tbackend\tplaywright\n' > "$MKT/proj/routes.tsv"
( _fx_cd "$MKT/repo" && git init -q -b main && : > f && git add f \
  && git -c user.name=t -c user.email=t@t commit -qm s ) >/dev/null 2>&1
( PATH="$MKT/bin:$PATH"; export TMPDIR="$MKT/tmp"
  . "$FROOT/harness/lib/resolve.sh"; felix_version_bump "$MKT/plugin.json"
  . "$FROOT/harness/lib/route.sh";   felix_route_append_play "$MKT/proj" web deepeval
  . "$FROOT/harness/lib/pulse.sh";   _felix_pulse_new_gitlinks "$MKT/repo"
  . "$FROOT/harness/lib/handoff.sh"; felix_handoff_rotate "$MKT/nohandoff" ) >/dev/null 2>&1
is "each engine mktemp driven here names a template under the TMPDIR it was given" \
   "$(awk -v t="$MKT/tmp/" '{ n = $NF; if (index(n, t) == 1 && n ~ /\.XXXXXX$/) { sub(/^.*\//, "", n); sub(/\.XXXXXX$/, "", n); printf "%s ", n } else printf "[%s] ", $0 }' "$MKT/calls")" \
   "felix-bump felix-routes felix-pulse felix-handoff "
is "and none of them leaves anything there" "$(ls -A "$MKT/tmp" | wc -l | tr -d ' ')" "0"
is "and each did its work: the version bumped and the tool wired in" \
   "$(grep -o '"version": "[^"]*"' "$MKT/plugin.json") $(cut -f4 "$MKT/proj/routes.tsv")" '"version": "1.2.4" playwright deepeval'

