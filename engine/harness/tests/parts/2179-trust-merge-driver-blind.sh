# >>> trust-merge-driver
printf '\ntrust plane step 3, S6.6: the merges the change readers take ignore the checkout config and attributes (blind)\n'
# Blind, written on 2026-11-08 from .felix/memory/felix/audits/2026-11-08-trust-plane-step3/checkout-merge-driver/spec.md
# and the finding beside it (README.md), before the fix. Not read: drv-case.sh, drv2-case.sh and probe-plain-git.sh in
# that folder, the earlier probe. Read: felix_added_lines, felix_changed_paths and _felix_merge_refs in lib/resolve.sh,
# for their arguments only; tests/run and parts 0002, 0460, 2070, 2176 and 2177 for the conventions.
#
# Scope: the spec's "What must be observable" list at the reader level. Each case calls felix_added_lines or
# felix_changed_paths with base main, from a subshell that stands in the fixture's checkout (_fx_cd) and sources
# $FROOT/harness/lib/resolve.sh, as part 0460 does.
#
# The fixture of the finding: R holds notes/f (eight lines), a/g and a/h. main moves after R by changing notes/f's
# last line; the candidate, cut from R and checked out on cand, puts a credential-shaped line after notes/f's first
# line, far enough from main's change that git's own merge is clean. The line is put together at run time from two
# halves, so this file holds no credential the secret scan reads (lessons.md 2026-11-05; part 2070 does the same). The
# driver is tmdkeep, the command true: it keeps main's side and exits 0. Every repository is under $TMP/tmd, and every
# git call into one goes through _fx_git or _fx_cd.
#
# Readings, where the spec leaves room:
# - "Holds the line" is the added lines holding +<line> at least once; "holds F" is notes/f among the changed paths.
#   The driver cases assert nothing else of the output, not even the exit status.
# - Global config is three cases: the driver in the file GIT_CONFIG_GLOBAL names, with the attribute in the checkout's
#   info/attributes (the checkout case with the driver moved); the driver and a core.attributesFile both in that file,
#   with nothing in the checkout; and the driver and attr.tree (naming the candidate, whose .gitattributes names the
#   driver) in that file. The third was added after a check: a throwaway merge in a scratch git directory that cleared
#   everything rule 1 lists except GIT_CONFIG_GLOBAL passed the other two, since -c core.attributesFile=/dev/null alone
#   stops the second, and failed the third. GIT_CONFIG_GLOBAL is set for the one subshell that runs the reader.
# - The recording driver's command writes $TMP/tmd/rec.marker and exits 0. The marker is removed before each reader
#   runs, and each reader is asked on its own.
# - Fallback: TMPDIR is a mode-555 directory, for the reader's subshell only; skipped where this user writes through a
#   mode (root). "At least what the three-dot diff returns" is every line of `git diff main...HEAD`'s names (changed
#   paths) and of its + lines without +++ (added lines) appearing in the reader's output. Two fixtures: the checkout
#   driver's, where a fallback that merged in the checkout would drop the line; and a stacked one, where the merge and
#   three-dot differ (main already holds the candidate's a/g change and gained main/only of its own), so only a real
#   fallback to three-dot holds a/g. Both fail on unfixed code by construction: today's readers need no TMPDIR, so
#   they merge in the checkout as before.
# - Byte-identical: the readers' whole output and exit status, for the no-driver control fixture and for the stacked
#   fixture (the merge route, which neither three-dot nor two-dot gives), pinned to literals today's code prints.
#
# Not covered:
# - The merge boundary (the spec's last bullet: felix merge refusing the credential form and the path form, and
#   merging an honest candidate). No merge fixture is cheap to reuse here: 2176's needs receipts, an entry and a gh
#   stub. Left for a part that builds one.
# - Parts of rule 1 the list does not name: the system config file and GIT_ATTR_NOSYSTEM, merge settings other than a
#   driver (merge.renames, merge.conflictStyle), and that the merge is named by commit ids and not by refs.
# - The spec's open items: other readers in the checkout, the built-in binary driver, lib/pr-status.sh, bin/secret-scan.
TMD="$TMP/tmd"; rm -rf "${TMD:?}"; mkdir -p "$TMD"
_tmd_cred="$(printf 'aws_access_key_id = %s%s' AKIA TMDQ3V8N2K7XW4PJ)"
_tmd_git() { _fx_git "$1" -c core.hooksPath=/dev/null -c commit.gpgsign=false "${@:2}"; }
_tmd_commit() { _tmd_git "$1" add -A >/dev/null 2>&1; _tmd_git "$1" commit -qm "$2" >/dev/null 2>&1; }
_tmd_init() {   # DIR: a repository on main whose one commit R holds notes/f, a/g and a/h
  mkdir -p "$1/notes" "$1/a"
  ( _fx_cd "$1" && git init -q -b main && git config user.name t && git config user.email t@example.invalid ) >/dev/null 2>&1
  mkdir -p "$1/.git/info"
  printf '%s\n' alpha bravo charlie delta echo foxtrot golf hotel > "$1/notes/f"
  printf '%s\n' g1 g2 > "$1/a/g"; printf '%s\n' h1 h2 > "$1/a/h"
  _tmd_commit "$1" R
}
_tmd_finding() {   # DIR [ATTR]: the finding's fixture, with ATTR as the candidate's own .gitattributes; cand checked out
  _tmd_init "$1"
  _tmd_git "$1" checkout -q -b cand >/dev/null 2>&1
  printf '%s\n' alpha "$_tmd_cred" bravo charlie delta echo foxtrot golf hotel > "$1/notes/f"
  [ -z "${2:-}" ] || printf '%s\n' "$2" > "$1/.gitattributes"
  _tmd_commit "$1" candidate
  _tmd_git "$1" checkout -q main >/dev/null 2>&1
  printf '%s\n' alpha bravo charlie delta echo foxtrot golf 'hotel on main' > "$1/notes/f"
  _tmd_commit "$1" "main moves"
  _tmd_git "$1" checkout -q cand >/dev/null 2>&1
}
_tmd_read() (   # DIR READER [NAME=VALUE...]: READER's output over DIR with base main, then a line rc N
  for _tmd_a in "${@:3}"; do export "$_tmd_a"; done
  _fx_cd "$1" || exit 1
  . "$FROOT/harness/lib/resolve.sh" 2>/dev/null
  "$2" "$PWD" main 2>/dev/null
  printf 'rc %s\n' "$?"
)
_tmd_plain() (   # DIR [NAME=VALUE...]: plain git merge-tree --write-tree OURS THEIRS in DIR -> rc N|whose notes/f|line K
                 # OURS and THEIRS are TMD_OURS and TMD_THEIRS when given among the assignments, else main and HEAD
  for _tmd_a in "${@:2}"; do export "$_tmd_a"; done
  o="${TMD_OURS:-main}"; h="${TMD_THEIRS:-HEAD}"
  t="$(_fx_git "$1" merge-tree --write-tree "$o" "$h" 2>/dev/null)"; rc=$?
  t="${t%%$'\n'*}"
  b="$(_fx_git "$1" rev-parse -q --verify "$t:notes/f" 2>/dev/null)"
  m="$(_fx_git "$1" rev-parse -q --verify "$o:notes/f" 2>/dev/null)"
  n="$(_fx_git "$1" cat-file blob "${b:-none}" 2>/dev/null | LC_ALL=C grep -cxF -- "$_tmd_cred")"
  if [ -n "$b" ] && [ "$b" = "$m" ]; then w="main's"; else w="not main's"; fi
  printf 'rc %s|%s notes/f|line %s' "$rc" "$w" "$n"
)
_tmd_flat() { printf '%s\n' "$1" | LC_ALL=C awk '{ printf "%s%s", s, $0; s = "|" }'; }
_tmd_held() {   # OUTPUT LINE -> held, or missing from [OUTPUT]
  if [ "$(printf '%s\n' "$1" | LC_ALL=C grep -cxF -- "$2")" -gt 0 ] 2>/dev/null; then printf 'held'
  else printf 'missing from [%s]' "$(_tmd_flat "$1")"; fi
}
_tmd_body() { printf '%s\n' "$1" | sed '$d'; }   # a _tmd_read output without its rc line
_tmd_3paths() { _fx_git "$1" diff --name-only --no-renames main...HEAD 2>/dev/null; }
_tmd_3lines() {
  _fx_git "$1" diff --no-ext-diff --no-textconv --no-color main...HEAD 2>/dev/null | LC_ALL=C grep '^+' | LC_ALL=C grep -v '^+++'
}
_tmd_missing() {   # WANT GOT -> the non-empty lines of WANT that GOT lacks, joined by |, or none
  printf '%s\n' "$1" > "$TMD/want"; printf '%s\n' "$2" > "$TMD/got"
  LC_ALL=C awk 'FILENAME == ARGV[1] { a[$0] = 1; next } $0 != "" && !($0 in a) { printf "%s%s", s, $0; s = "|"; m = 1 }
                END { if (!m) printf "none" }' "$TMD/got" "$TMD/want"
}
_tmd_marker() { if [ -e "$TMD/rec.marker" ]; then printf 'marker written'; else printf 'no marker'; fi; }

# ---------------------------------------------------------------- control ---
_tmd_finding "$TMD/ctl"
_tmd_R="$(_tmd_git "$TMD/ctl" rev-list --max-parents=0 main 2>/dev/null)"
is  "tmd: (fixture control) with no driver, main has moved since the candidate's base R, plain git merge-tree in the checkout exits 0 with the credential line in its notes/f, and three-dot names notes/f and adds the line" \
    "$(if [ -n "$_tmd_R" ] && [ "$(_tmd_git "$TMD/ctl" merge-base main cand 2>/dev/null)" = "$_tmd_R" ] && [ "$(_tmd_git "$TMD/ctl" rev-parse main 2>/dev/null)" != "$_tmd_R" ]; then printf 'base R, main moved'; else printf 'not the finding'; fi)|$(_tmd_plain "$TMD/ctl")|$(_tmd_flat "$(_tmd_3paths "$TMD/ctl")")|$(_tmd_flat "$(_tmd_3lines "$TMD/ctl")")" \
    "base R, main moved|rc 0|not main's notes/f|line 1|notes/f|+$_tmd_cred"
_tmd_al="$(_tmd_read "$TMD/ctl" felix_added_lines)"; _tmd_cp="$(_tmd_read "$TMD/ctl" felix_changed_paths)"
is  "tmd: control: with no driver, the added lines of a candidate that puts a credential-shaped line into notes/f hold that line" \
    "$(_tmd_held "$_tmd_al" "+$_tmd_cred")" "held"
is  "tmd: control: with no driver, the changed paths hold notes/f" \
    "$(_tmd_held "$_tmd_cp" notes/f)" "held"

# ------------------------------------------------------ the checkout's driver ---
_tmd_finding "$TMD/drv"
_tmd_git "$TMD/drv" config merge.tmdkeep.driver true >/dev/null 2>&1
printf 'notes/f merge=tmdkeep\n' > "$TMD/drv/.git/info/attributes"
is  "tmd: (fixture control) the checkout's driver: with merge.tmdkeep.driver=true in the checkout's .git/config and notes/f merge=tmdkeep in its .git/info/attributes, plain git merge-tree in the checkout exits 0 and keeps main's notes/f, without the line" \
    "$(_tmd_plain "$TMD/drv")" "rc 0|main's notes/f|line 0"
is  "tmd: the checkout's driver: with the driver in the checkout's config and attributes, the added lines still hold the credential line" \
    "$(_tmd_held "$(_tmd_read "$TMD/drv" felix_added_lines)" "+$_tmd_cred")" "held"
is  "tmd: the checkout's driver: with the driver in the checkout's config and attributes, the changed paths still hold notes/f" \
    "$(_tmd_held "$(_tmd_read "$TMD/drv" felix_changed_paths)" notes/f)" "held"

# ------------------------- the candidate's attributes and the checkout's config ---
_tmd_finding "$TMD/attr" 'notes/f merge=tmdkeep'
_tmd_git "$TMD/attr" config merge.tmdkeep.driver true >/dev/null 2>&1
is  "tmd: (fixture control) the candidate's attributes: the candidate's own .gitattributes reads notes/f merge=tmdkeep, the checkout has no info/attributes, and with the driver in the checkout's config plain git merge-tree in the checkout exits 0 and keeps main's notes/f" \
    "$(_fx_git "$TMD/attr" show cand:.gitattributes 2>&1)|$([ -e "$TMD/attr/.git/info/attributes" ] && printf 'info/attributes' || printf 'no info/attributes')|$(_tmd_plain "$TMD/attr")" \
    "notes/f merge=tmdkeep|no info/attributes|rc 0|main's notes/f|line 0"
is  "tmd: the candidate's attributes: with notes/f merge=tmdkeep in the candidate's .gitattributes and the driver in the checkout's config, the added lines still hold the credential line" \
    "$(_tmd_held "$(_tmd_read "$TMD/attr" felix_added_lines)" "+$_tmd_cred")" "held"
is  "tmd: the candidate's attributes: with notes/f merge=tmdkeep in the candidate's .gitattributes and the driver in the checkout's config, the changed paths still hold notes/f" \
    "$(_tmd_held "$(_tmd_read "$TMD/attr" felix_changed_paths)" notes/f)" "held"

# ------------------------------------------------------------- global config ---
printf '[merge "tmdkeep"]\n\tdriver = true\n' > "$TMD/global-a.cfg"
_tmd_finding "$TMD/glba"
printf 'notes/f merge=tmdkeep\n' > "$TMD/glba/.git/info/attributes"
is  "tmd: (fixture control) global config, attribute in the checkout: the checkout's config defines no tmdkeep driver, plain git merge-tree keeps the line without the global file, and keeps main's notes/f with GIT_CONFIG_GLOBAL naming a file that defines it" \
    "$(_fx_git "$TMD/glba" config --local --get merge.tmdkeep.driver >/dev/null 2>&1; printf 'local %s' "$?")|$(_tmd_plain "$TMD/glba")|$(_tmd_plain "$TMD/glba" GIT_CONFIG_GLOBAL="$TMD/global-a.cfg")" \
    "local 1|rc 0|not main's notes/f|line 1|rc 0|main's notes/f|line 0"
is  "tmd: global config: with the driver in the file GIT_CONFIG_GLOBAL names and notes/f merge=tmdkeep in the checkout's info/attributes, the added lines still hold the credential line" \
    "$(_tmd_held "$(_tmd_read "$TMD/glba" felix_added_lines GIT_CONFIG_GLOBAL="$TMD/global-a.cfg")" "+$_tmd_cred")" "held"
is  "tmd: global config: with the driver in the file GIT_CONFIG_GLOBAL names and notes/f merge=tmdkeep in the checkout's info/attributes, the changed paths still hold notes/f" \
    "$(_tmd_held "$(_tmd_read "$TMD/glba" felix_changed_paths GIT_CONFIG_GLOBAL="$TMD/global-a.cfg")" notes/f)" "held"

printf 'notes/f merge=tmdkeep\n' > "$TMD/global-b.attr"
printf '[merge "tmdkeep"]\n\tdriver = true\n[core]\n\tattributesFile = "%s"\n' "$TMD/global-b.attr" > "$TMD/global-b.cfg"
_tmd_finding "$TMD/glbb"
is  "tmd: (fixture control) global config alone: the checkout has no info/attributes and the candidate no .gitattributes, plain git merge-tree keeps the line without the global file, and keeps main's notes/f with GIT_CONFIG_GLOBAL naming a file that defines the driver and a core.attributesFile naming it for notes/f" \
    "$([ -e "$TMD/glbb/.git/info/attributes" ] && printf 'info/attributes' || printf 'no info/attributes')|$(_fx_git "$TMD/glbb" cat-file -e cand:.gitattributes >/dev/null 2>&1 && printf '.gitattributes' || printf 'no .gitattributes')|$(_tmd_plain "$TMD/glbb")|$(_tmd_plain "$TMD/glbb" GIT_CONFIG_GLOBAL="$TMD/global-b.cfg")" \
    "no info/attributes|no .gitattributes|rc 0|not main's notes/f|line 1|rc 0|main's notes/f|line 0"
is  "tmd: global config alone: with the driver and a core.attributesFile naming it both in the file GIT_CONFIG_GLOBAL names, the added lines still hold the credential line" \
    "$(_tmd_held "$(_tmd_read "$TMD/glbb" felix_added_lines GIT_CONFIG_GLOBAL="$TMD/global-b.cfg")" "+$_tmd_cred")" "held"
is  "tmd: global config alone: with the driver and a core.attributesFile naming it both in the file GIT_CONFIG_GLOBAL names, the changed paths still hold notes/f" \
    "$(_tmd_held "$(_tmd_read "$TMD/glbb" felix_changed_paths GIT_CONFIG_GLOBAL="$TMD/global-b.cfg")" notes/f)" "held"

_tmd_finding "$TMD/glbc" 'notes/f merge=tmdkeep'
_tmd_cm="$(_tmd_git "$TMD/glbc" rev-parse main 2>/dev/null)"; _tmd_cc="$(_tmd_git "$TMD/glbc" rev-parse cand 2>/dev/null)"
printf '[merge "tmdkeep"]\n\tdriver = true\n[attr]\n\ttree = %s\n' "$_tmd_cc" > "$TMD/global-c.cfg"
mkdir -p "$TMD/glbc-bare"
( _fx_cd "$TMD/glbc-bare" && GIT_CONFIG_GLOBAL=/dev/null git init -q --bare ) >/dev/null 2>&1
printf '%s\n' "$TMD/glbc/.git/objects" > "$TMD/glbc-bare/objects/info/alternates"
is  "tmd: (fixture control) global config with attr.tree: the checkout's config defines no tmdkeep driver; in a bare repository with no worktree whose objects reach the checkout's, plain git merge-tree keeps the line without the global file, and keeps main's notes/f with GIT_CONFIG_GLOBAL naming a file that defines the driver and sets attr.tree to the candidate, whose .gitattributes names it" \
    "$(_fx_git "$TMD/glbc" config --local --get merge.tmdkeep.driver >/dev/null 2>&1; printf 'local %s' "$?")|$(_tmd_plain "$TMD/glbc-bare" TMD_OURS="$_tmd_cm" TMD_THEIRS="$_tmd_cc")|$(_tmd_plain "$TMD/glbc-bare" TMD_OURS="$_tmd_cm" TMD_THEIRS="$_tmd_cc" GIT_CONFIG_GLOBAL="$TMD/global-c.cfg")" \
    "local 1|rc 0|not main's notes/f|line 1|rc 0|main's notes/f|line 0"
is  "tmd: global config with attr.tree: with the driver and attr.tree naming the candidate both in the file GIT_CONFIG_GLOBAL names, the added lines still hold the credential line" \
    "$(_tmd_held "$(_tmd_read "$TMD/glbc" felix_added_lines GIT_CONFIG_GLOBAL="$TMD/global-c.cfg")" "+$_tmd_cred")" "held"
is  "tmd: global config with attr.tree: with the driver and attr.tree naming the candidate both in the file GIT_CONFIG_GLOBAL names, the changed paths still hold notes/f" \
    "$(_tmd_held "$(_tmd_read "$TMD/glbc" felix_changed_paths GIT_CONFIG_GLOBAL="$TMD/global-c.cfg")" notes/f)" "held"

# --------------------------------------------------------- a driver that records ---
_tmd_finding "$TMD/rec"
_tmd_git "$TMD/rec" config merge.tmdrec.driver "printf ran > '$TMD/rec.marker'" >/dev/null 2>&1
printf 'notes/f merge=tmdrec\n' > "$TMD/rec/.git/info/attributes"
rm -f "$TMD/rec.marker"; _tmd_rc="$(_tmd_plain "$TMD/rec")|$(_tmd_marker)"
rm -f "$TMD/rec.marker"; _tmd_read "$TMD/rec" felix_added_lines >/dev/null; _tmd_ral="$(_tmd_marker)"
rm -f "$TMD/rec.marker"; _tmd_read "$TMD/rec" felix_changed_paths >/dev/null; _tmd_rcp="$(_tmd_marker)"
rm -f "$TMD/rec.marker"
is  "tmd: (fixture control) a driver that records: with merge.tmdrec.driver writing a marker file in the checkout's config and notes/f merge=tmdrec in its info/attributes, plain git merge-tree in the checkout exits 0, keeps main's notes/f and writes the marker" \
    "$_tmd_rc" "rc 0|main's notes/f|line 0|marker written"
is  "tmd: a driver that records: felix_added_lines never runs the checkout's driver whose command writes a marker file (the marker is absent)" \
    "$_tmd_ral" "no marker"
is  "tmd: a driver that records: felix_changed_paths never runs the checkout's driver whose command writes a marker file (the marker is absent)" \
    "$_tmd_rcp" "no marker"

# ------------------------------------------------------------ a stacked branch ---
_tmd_init "$TMD/stk"
_tmd_git "$TMD/stk" checkout -q -b cand >/dev/null 2>&1
printf '%s\n' g1 g2 g-added > "$TMD/stk/a/g"; _tmd_commit "$TMD/stk" "the change below"
printf '%s\n' h1 h2 h-added > "$TMD/stk/a/h"; _tmd_commit "$TMD/stk" "this change"
_tmd_git "$TMD/stk" checkout -q main >/dev/null 2>&1
printf '%s\n' g1 g2 g-added > "$TMD/stk/a/g"; mkdir -p "$TMD/stk/main"; printf 'main only\n' > "$TMD/stk/main/only"
_tmd_commit "$TMD/stk" "the change below, squashed, and a file of main's own"
_tmd_git "$TMD/stk" checkout -q cand >/dev/null 2>&1
_tmd_st="$(_fx_git "$TMD/stk" merge-tree --write-tree main HEAD 2>/dev/null)"; _tmd_st="${_tmd_st%%$'\n'*}"
is  "tmd: (fixture control) a stacked branch: three-dot names a/g and a/h and adds both their lines, while the tree plain git merge-tree writes differs from main's only at a/h" \
    "$(_tmd_flat "$(_tmd_3paths "$TMD/stk")")|$(_tmd_flat "$(_tmd_3lines "$TMD/stk")")|$(_tmd_flat "$(_fx_git "$TMD/stk" diff --name-only --no-renames "main^{tree}" "${_tmd_st:-none}" 2>&1)")" \
    "a/g|a/h|+g-added|+h-added|a/h"

# ------------------------------------------------------------ byte-identical ---
is  "tmd: byte-identical: with no driver and no attributes, the added lines are exactly the credential line and the reader exits 0" \
    "$(_tmd_flat "$_tmd_al")" "+$_tmd_cred|rc 0"
is  "tmd: byte-identical: with no driver and no attributes, the changed paths are exactly notes/f and the reader exits 0" \
    "$(_tmd_flat "$_tmd_cp")" "notes/f|rc 0"
is  "tmd: byte-identical: on a stacked branch whose base already holds one of its two changes and gained a file of its own, the added lines are exactly the other change's line and the reader exits 0" \
    "$(_tmd_flat "$(_tmd_read "$TMD/stk" felix_added_lines)")" "+h-added|rc 0"
is  "tmd: byte-identical: on a stacked branch whose base already holds one of its two changes and gained a file of its own, the changed paths are exactly a/h and the reader exits 0" \
    "$(_tmd_flat "$(_tmd_read "$TMD/stk" felix_changed_paths)")" "a/h|rc 0"

# ------------------------------------------------------------------ fallback ---
_unwritable_probe
_tmd_unw="$TMD/unw"; mkdir -p "$_tmd_unw"; chmod 555 "$_tmd_unw"
if [ "$_unwritable" = 1 ]; then
  is  "tmd: (fixture control) fallback: mktemp -d cannot make a directory in the mode-555 TMPDIR; three-dot names notes/f and adds the credential line in the checkout driver's fixture, and names a/g and a/h and adds both their lines in the stacked one" \
      "$( ( mktemp -d "$_tmd_unw/x.XXXXXX" ) >/dev/null 2>&1 && printf 'made one' || printf 'refused')|$(_tmd_flat "$(_tmd_3paths "$TMD/drv")")|$(_tmd_flat "$(_tmd_3lines "$TMD/drv")")|$(_tmd_flat "$(_tmd_3paths "$TMD/stk")")|$(_tmd_flat "$(_tmd_3lines "$TMD/stk")")" \
      "refused|notes/f|+$_tmd_cred|a/g|a/h|+g-added|+h-added"
  is  "tmd: fallback: with an unwritable TMPDIR and the checkout's driver, the added lines hold every line the three-dot diff adds" \
      "$(_tmd_missing "$(_tmd_3lines "$TMD/drv")" "$(_tmd_body "$(_tmd_read "$TMD/drv" felix_added_lines TMPDIR="$_tmd_unw")")")" "none"
  is  "tmd: fallback: with an unwritable TMPDIR and the checkout's driver, the changed paths hold every path the three-dot diff names" \
      "$(_tmd_missing "$(_tmd_3paths "$TMD/drv")" "$(_tmd_body "$(_tmd_read "$TMD/drv" felix_changed_paths TMPDIR="$_tmd_unw")")")" "none"
  is  "tmd: fallback: with an unwritable TMPDIR on a stacked branch, the added lines hold every line the three-dot diff adds" \
      "$(_tmd_missing "$(_tmd_3lines "$TMD/stk")" "$(_tmd_body "$(_tmd_read "$TMD/stk" felix_added_lines TMPDIR="$_tmd_unw")")")" "none"
  is  "tmd: fallback: with an unwritable TMPDIR on a stacked branch, the changed paths hold every path the three-dot diff names" \
      "$(_tmd_missing "$(_tmd_3paths "$TMD/stk")" "$(_tmd_body "$(_tmd_read "$TMD/stk" felix_changed_paths TMPDIR="$_tmd_unw")")")" "none"
else
  skip "tmd: (fixture control) fallback: mktemp -d cannot make a directory in the mode-555 TMPDIR; three-dot names notes/f and adds the credential line in the checkout driver's fixture, and names a/g and a/h and adds both their lines in the stacked one" "$_nowrite"
  skip "tmd: fallback: with an unwritable TMPDIR and the checkout's driver, the added lines hold every line the three-dot diff adds" "$_nowrite"
  skip "tmd: fallback: with an unwritable TMPDIR and the checkout's driver, the changed paths hold every path the three-dot diff names" "$_nowrite"
  skip "tmd: fallback: with an unwritable TMPDIR on a stacked branch, the added lines hold every line the three-dot diff adds" "$_nowrite"
  skip "tmd: fallback: with an unwritable TMPDIR on a stacked branch, the changed paths hold every path the three-dot diff names" "$_nowrite"
fi
chmod 755 "$_tmd_unw"
rm -rf "${TMD:?}"
# <<< trust-merge-driver
