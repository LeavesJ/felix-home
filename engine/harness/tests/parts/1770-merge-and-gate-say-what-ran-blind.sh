printf '\nfelix merge refuses a green that reports a check skipped, and the gate says what ran (audit b08, blind)\n'
# Written blind on 2026-10-24 from the contract alone (docs/2026-10-24-audit-fixes/
# b08-change-scoped-verification-and-receipt-f.md, A1 to A33 of its section 4),
# before the fix, without reading the code it is about: lib/escape.sh,
# lib/verify.sh, the felix CLI and projects/felix/gate.sh. One assertion per item,
# named "b08 A<n> (B<m>): ...". An item that checks several things is one
# assertion whose compared value says each of them.
#
# Fixtures, the contract's: FM, a project and a checkout with no git remote, a
# base branch at HEAD~1 and receipts written by felix_verify_record; FG, a second
# one whose gate.sh prints what a mode file says and is run by `felix gate`; FC
# and FT, a checkout holding this tree's projects/felix/gate.sh beside stubs, FC
# with copies of engine/hooks/hooks.json and .claude/settings.json edited per case
# and run with --quick, FT with neither and run without. A gh stub first on PATH
# records every call and exits 1. Every external run is bounded.
#
# Readings taken where the text leaves room:
# - The judge is handed FM's base branch as its base ref, as felix merge is.
# - Asserted lines are compared with each tab shown as <TAB>.
# - A9's receipt file is the one file under $FROOT/state/gate whose content is
#   what felix_verify_receipt prints; it is written with field 5 `tests` first,
#   so a rule that did not read the edited file would name tests.
# - A30's "three lines after the tests ok line" is read as the tests ok line and
#   the two that follow it: B23 names exactly three lines.
# - A4 is not marked (control) in the contract, but no line is printed for any
#   green receipt on 69b51a61, so it holds there too.
# - FC commits each case's two files, so the check sees them whether it reads the
#   working tree or the commit.
# The review round (A61 to A68, B30 and B31 of the contract's section 9) was added
# blind on 2026-10-26 the same way, over FC: a binding written off the layout, and
# a file with no final newline, as Python's json.dump(indent=2) writes one.

# ---- shared helpers
_b8m="$TMP/b08m"; mkdir -p "$_b8m/gh/bin"
_b8m_bounded() {   # <seconds> <cmd>...: cmd in a process group of its own, the group killed at the limit (status 124)
  perl -e '$t = shift; $p = fork; defined $p or exit 125;
    if (!$p) { setpgrp(0, 0); exec @ARGV; exit 127 }
    $SIG{ALRM} = sub { kill "KILL", -$p; exit 124 }; alarm $t; waitpid $p, 0;
    exit(($? & 127) ? 128 + ($? & 127) : $? >> 8)' "$@"
}
_b8m_tabs() { printf '%s' "$1" | LC_ALL=C awk '{ gsub(/\t/, "<TAB>"); print }'; }
_b8m_flat() { printf '%s' "$1" | LC_ALL=C tr '\t\n' ' |' | cut -c1-700; }
_b8m_holds() { case "$1" in *"$2"*) printf 'holds' ;; *) printf 'lacks' ;; esac; }
_b8m_count() { B8M_W="$2" LC_ALL=C awk 'index($0, ENVIRON["B8M_W"]) { n++ } END { print n + 0 }' <<EOF
$1
EOF
}
_b8m_lines() { LC_ALL=C awk 'length($0) { n++ } END { print n + 0 }' <<EOF
$1
EOF
}
_b8m_nth() { LC_ALL=C awk -v n="$2" 'NR == n { print; exit }' <<EOF
$1
EOF
}
# name got want text: is, with the text flattened into the detail when it fails.
_b8m_is() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$3] got [$2]; output: $(_b8m_flat "$4")"; fi; }
# name text want... [-- unwanted...]: ok when the text holds every want and no unwanted.
_b8m_every() {
  local n="$1" t="$2" w miss="" no=0
  shift 2
  for w in "$@"; do
    if [ "$w" = "--" ]; then no=1; continue; fi
    case "$t" in
      *"$w"*) [ "$no" -eq 0 ] || miss="$miss holds [$w];" ;;
      *)      [ "$no" -eq 1 ] || miss="$miss lacks [$w];" ;;
    esac
  done
  if [ -z "$miss" ]; then ok "$n"; else bad "$n" "$miss output: $(_b8m_flat "$t")"; fi
}
# The two reasons and the lines the judge prints, tabs shown.
_b8m_why() {
  printf 'the gate reported %s as skipped on this tree, and a green with a check reported skipped does not land, so run the full gate, and if a check still reports skipped, its own line in the gate output says why' "$1"
}
_b8m_skipln() { printf 'unverified<TAB>skipped<TAB>%s' "$(_b8m_why "$1")"; }
_b8mRU='unverified<TAB>skipped<TAB>the receipt is not one green line stating what the gate skipped, so it cannot show that no check was reported skipped, and the remedy is the full gate'
_b8mStale='unverified<TAB>tree<TAB>the tree changed since the receipt'
_b8mRed='unverified<TAB>tree<TAB>no green receipt for this exact tree; run felix gate'
_b8mC9='unverified<TAB>tests<TAB>the gate reused a suite run for this tree (tests:reused)'
_b8mCli="$(printf '  %-11s %-22s %s' unverified skipped "$(_b8m_why tests)")"

# The gh stub: every call one line in calls, and a failure.
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s/gh/calls"\nexit 1\n' "$_b8m" > "$_b8m/gh/bin/gh"
chmod +x "$_b8m/gh/bin/gh"
_b8mPATH="$_b8m/gh/bin:$PATH"
PATH="$_b8mPATH" gh b08-probe >/dev/null 2>&1
_b8mProbe="$(cat "$_b8m/gh/calls" 2>/dev/null)"
: > "$_b8m/gh/calls"

# <project dir> <name> <gate>: a project like part 1250's gfcw, with no gate workflow.
_b8m_project() {
  mkdir -p "${1:?}" "$MEM/$2"
  cp "$TMP/probes.keep" "$1/probes.tsv"
  cp "$TMP/obligations.keep" "$1/obligations.tsv"
  cp "$TMP/commissioning.keep" "$1/commissioning.tsv"
  cp "$REAL_HARNESS/templates/risk.tsv" "$1/risk.tsv"
  printf '# %s\n' "$2" > "$1/CLAUDE.md"
  printf '{\n  "name": "%s",\n  "remote_match": "example.invalid/%s",\n  "gate": "%s"\n}\n' "$2" "$2" "$3" > "$1/project.json"
}
# <repo dir> <name>: .felix, a base commit, a change commit on a topic branch, no
# remote, and refs/heads/<name>-base at HEAD~1.
_b8m_repo() {
  mkdir -p "${1:?}"
  ( _fx_cd "${1:?}" && git init -q -b main && printf '%s\n' "$2" > .felix && printf 'one\n' > NOTES.txt \
    && git add -A && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm base \
    && git checkout -q -b "$2-topic" && printf 'two\n' >> NOTES.txt \
    && git add -A && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm change ) >/dev/null 2>&1
  _fx_git "${1:?}" update-ref "refs/heads/$2-base" HEAD~1 >/dev/null 2>&1
}
_b8m_stamp() {   # project repo: the commission receipt, stamped once (tables and checkout never move here)
  ( cd "${2:?}" && FELIX_HOME_DIR="$FROOT"; . "$FROOT/harness/lib/commission.sh"
    _o="$(felix_commission_run "$1" "$2" -)"
    felix_commission_receipt_write "$FROOT" "$1" "$2" "$_o" "" ) >/dev/null 2>&1
}
# repo rc field5 [field6]: a receipt for the tree as it stands.
_b8m_rec() {
  ( cd "${1:?}" && . "$FROOT/harness/lib/verify.sh"
    felix_verify_record "$1" "$FROOT" "$2" "gate.sh" "$(felix_tree_id "$1" "$FROOT")" "$3" "${4:-}" ) >/dev/null 2>&1
}
_b8m_f5() { ( . "$FROOT/harness/lib/verify.sh"; felix_verify_receipt "$1" "$FROOT" ) 2>/dev/null | cut -f5; }
# repo base out-file: felix merge --dry-run there, its status in _b8mRc.
_b8m_merge() {
  ( cd "${1:?}" && GIT_ALLOW_PROTOCOL=file PATH="$_b8mPATH" _b8m_bounded 90 "$FELIX" merge --base "$2" --dry-run ) > "$3" 2>&1
  _b8mRc=$?
}

# ---- FM
_b8mP="$FROOT/projects/b08m"; _b8mR="$TMP/b08m-repo"; _b8mB="refs/heads/b08m-base"
_b8m_project "$_b8mP" b08m true
_b8m_repo "$_b8mR" b08m
_b8mR="$(cd "${_b8mR:?}" && pwd -P)"
_b8m_stamp "$_b8mP" "$_b8mR"

# The judge, loaded as the merge boundary loads main's kernel: a child bash under
# set -uo pipefail, six libraries. -> its output, tabs shown, or a bracketed line.
_b8m_blk() {
  local o rc
  o="$( cd "${_b8mR:?}" && GIT_ALLOW_PROTOCOL=file PATH="$_b8mPATH" _b8m_bounded 60 bash -c '
      set -uo pipefail
      k="$1"
      for f in resolve verify review classify evidence escape; do . "$k/lib/$f.sh" 2>/dev/null || exit 97; done
      felix_merge_blockers "$2" "$3" "$4" "$5"
    ' _ "$FROOT/harness" "$_b8mP" "$_b8mB" "$_b8mR" "$FROOT" 2>/dev/null )"; rc=$?
  case "$rc" in
    97)      printf '[the judge could not load its libraries]' ;;
    124)     printf '[the judge did not finish in 60 s]' ;;
    125|127) printf '[the judge did not run: status %s]' "$rc" ;;
    *)       _b8m_tabs "$o" ;;
  esac
}

# ---- C003: the judge (A1 to A14, A22)
_b8m_rec "$_b8mR" 0 tests
is "b08 A1 (B1): a current receipt whose field 5 is tests: the judge's whole output is the one skipped line, NAMES tests" \
   "$(_b8m_blk)" "$(_b8m_skipln tests)"
is "b08 A22 (B12): felix_verify_current still answers current for that epoched green receipt whose field 5 is tests (control)" \
   "$( ( cd "${_b8mR:?}" && . "$FROOT/harness/lib/verify.sh"; felix_verify_current "$_b8mR" "$FROOT" "$_b8mP" ) 2>/dev/null )" "current"
_b8m_rec "$_b8mR" 0 tests,installed
is "b08 A2 (B1): field 5 tests,installed gives one skipped line, NAMES tests,installed in field 5's order" \
   "$(_b8m_blk)" "$(_b8m_skipln tests,installed)"
_b8m_rec "$_b8mR" 0 -
is "b08 A3 (B2): field 5 - gives no output (control)" "$(_b8m_blk)" ""
_b8m_rec "$_b8mR" 0 '○,1'
is "b08 A4 (B2): field 5 holding only off-shape items (○,1) gives no output" "$(_b8m_blk)" ""
_b8m_rec "$_b8mR" 0 '○,1,tests'
is "b08 A5 (B2): field 5 ○,1,tests gives NAMES tests, the off-shape items left out" "$(_b8m_blk)" "$(_b8m_skipln tests)"
_b8m_rec "$_b8mR" 0 '-,tests'
is "b08 A6 (B2): field 5 -,tests gives NAMES tests" "$(_b8m_blk)" "$(_b8m_skipln tests)"
_b8m_rec "$_b8mR" 0 '--'
is "b08 A7 (B2): field 5 -- gives no output (control)" "$(_b8m_blk)" ""
_b8m_rec "$_b8mR" 0 '%s%n,tests'
is "b08 A8 (B1, B2): field 5 %s%n,tests gives NAMES tests, and the reason is data, so the line holds no %" \
   "$(_b8m_blk)" "$(_b8m_skipln tests)"

# A9: the receipt file, found by its content, with field 5 emptied by hand.
_b8m_rec "$_b8mR" 0 tests
_b8mRc="$( . "$FROOT/harness/lib/verify.sh"; felix_verify_receipt "$_b8mR" "$FROOT" 2>/dev/null )"
_b8mRf=""; _b8mRn=0
for _b8mf in "$FROOT/state/gate"/*; do
  [ -f "$_b8mf" ] || continue
  [ -n "$_b8mRc" ] && [ "$(cat "$_b8mf" 2>/dev/null)" = "$_b8mRc" ] || continue
  _b8mRf="$_b8mf"; _b8mRn=$((_b8mRn + 1))
done
_b8mN9="b08 A9 (B3): a current receipt whose field 5 is empty gives exactly the R_UNSTATED line, unknown and never nothing skipped"
if [ "$_b8mRn" -eq 1 ]; then
  LC_ALL=C awk -F'\t' -v OFS='\t' 'NR == 1 { $5 = "" } { print }' "$_b8mRf" > "$_b8m/receipt.edit" \
    && cat "$_b8m/receipt.edit" > "$_b8mRf"
  is "$_b8mN9" "$(_b8m_blk)" "$_b8mRU"
else
  bad "$_b8mN9" "the fixture found $_b8mRn files under $FROOT/state/gate holding what felix_verify_receipt prints, not one"
fi

_b8m_rec "$_b8mR" 0 tests
printf 'three\n' >> "$_b8mR/NOTES.txt"
_b8mO="$(_b8m_blk)"
printf 'one\ntwo\n' > "$_b8mR/NOTES.txt"
_b8m_is "b08 A10 (B4): a tests receipt for a tree since edited gives the tree-changed line and no skipped line (control)" \
   "$(_b8m_holds "$_b8mO" "$_b8mStale") the tree-changed line, $(_b8m_count "$_b8mO" '<TAB>skipped<TAB>') skipped lines" \
   "holds the tree-changed line, 0 skipped lines" "$_b8mO"
_b8m_rec "$_b8mR" 1 tests
_b8mO="$(_b8m_blk)"
_b8m_is "b08 A11 (B4): a red tests receipt gives the no-green-receipt line and no skipped line (control)" \
   "$(_b8m_holds "$_b8mO" "$_b8mRed") the no-green-receipt line, $(_b8m_count "$_b8mO" '<TAB>skipped<TAB>') skipped lines" \
   "holds the no-green-receipt line, 0 skipped lines" "$_b8mO"
_b8m_rec "$_b8mR" 0 - syntax:ok,tests:skipped
is "b08 A12 (B5): field 5 - with field 6 syntax:ok,tests:skipped gives no output, field 6 unread by the rule (control)" \
   "$(_b8m_blk)" ""
if [ "$_b8mProbe" = "b08-probe" ]; then _b8mO="$(cat "$_b8m/gh/calls" 2>/dev/null)"
else _b8mO="[the gh stub does not record a call: its probe left (${_b8mProbe:-nothing})]"; fi
is "b08 A13 (B6): over A1 to A12, no receipt without tests:reused made a single gh call (control)" "$_b8mO" ""

_b8m_rec "$_b8mR" 0 installed syntax:ok,tests:reused
_b8mO="$(_b8m_blk)"
_b8mL2="$(_b8m_nth "$_b8mO" 2)"
_b8m_is "b08 A14 (B7): field 5 installed with tests:reused and no github remote gives two lines, the skipped line (NAMES installed), then C9's" \
   "$(_b8m_lines "$_b8mO")|$(_b8m_nth "$_b8mO" 1)|${_b8mL2:0:${#_b8mC9}}" \
   "2|$(_b8m_skipln installed)|$_b8mC9" "$_b8mO"

# ---- C003: felix merge --dry-run (A15 to A18)
_b8m_rec "$_b8mR" 0 tests
_b8m_merge "$_b8mR" "$_b8mB" "$_b8m/a15.out"
_b8mO="$(cat "$_b8m/a15.out" 2>/dev/null)"
_b8m_is "b08 A15 (B8): felix merge --dry-run on a current receipt whose field 5 is tests exits 3" "$_b8mRc" "3" "$_b8mO"
_b8m_every "b08 A16 (B8): and says not merging, with the skipped blocker on its own line as the CLI prints the others" \
   "$_b8mO" "not merging" "$_b8mCli"
_b8m_every "b08 A17 (B8): and hands it back as work Felix owes, never as a founder decision nor as a clear merge" \
   "$_b8mO" "Nothing here escapes the tree, so none of it is a founder decision." \
   "It is work Felix owes: run the gate, or write the test that is missing," -- "nothing escapes this tree, and the gate is green on it."
_b8m_rec "$_b8mR" 0 -
_b8m_merge "$_b8mR" "$_b8mB" "$_b8m/a18.out"
_b8mO="$(cat "$_b8m/a18.out" 2>/dev/null)"
_b8m_is "b08 A18 (B9): the same tree recorded again with field 5 - merges on a dry run: exit 0, felix merge would squash this now. (control)" \
   "exit $_b8mRc, $(_b8m_holds "$_b8mO" "felix merge would squash this now.") the squash line" "exit 0, holds the squash line" "$_b8mO"

# ---- C003: the gate's report decides, not its flags (FG, A19 to A21)
_b8gP="$FROOT/projects/b08g"; _b8gR="$TMP/b08g-repo"; _b8gB="refs/heads/b08g-base"
_b8m_project "$_b8gP" b08g gate.sh
printf '#!/bin/sh\ncat "%s"\nexit 0\n' "$_b8m/fg.mode" > "$_b8gP/gate.sh"
chmod +x "$_b8gP/gate.sh"
_b8m_repo "$_b8gR" b08g
_b8gR="$(cd "${_b8gR:?}" && pwd -P)"
_b8m_stamp "$_b8gP" "$_b8gR"
_b8m_gate() {   # name: felix gate in FG, no flag; its output in $_b8m/<name>.out
  ( cd "${_b8gR:?}" && GIT_ALLOW_PROTOCOL=file PATH="$_b8mPATH" _b8m_bounded 180 "$FELIX" gate ) > "$_b8m/$1.out" 2>&1
  _b8gRc=$?
}
printf '  tests              skipped (no suite here)\n' > "$_b8m/fg.mode"
_b8m_gate a19
_b8m_is "b08 A19 (B10): felix gate with no flag, on a gate that prints tests skipped (no suite here), records field 5 tests (control)" \
   "$(_b8m_f5 "$_b8gR")" "tests" "gate exit $_b8gRc: $(cat "$_b8m/a19.out" 2>/dev/null)"
_b8m_merge "$_b8gR" "$_b8gB" "$_b8m/a20.out"
_b8mO="$(cat "$_b8m/a20.out" 2>/dev/null)"
_b8m_is "b08 A20 (B10): then felix merge --dry-run exits 3 with the skipped line: the gate's report decides, not its flags" \
   "exit $_b8mRc, $(_b8m_holds "$_b8mO" "$_b8mCli") the skipped line" "exit 3, holds the skipped line" "$_b8mO"
printf '  syntax             ok\n' > "$_b8m/fg.mode"
_b8m_gate a21
_b8mW="$(LC_ALL=C awk '$1 == "qualified" { print $2; exit }' "$_b8m/a21.out" 2>/dev/null)"
_b8mF="$(_b8m_f5 "$_b8gR")"
_b8m_merge "$_b8gR" "$_b8gB" "$_b8m/a21m.out"
_b8m_is "b08 A21 (B11): the engine's own qualified skip stays out of field 5: qualified says skipped, field 5 is -, the dry run exits 0 (control)" \
   "qualified ${_b8mW:-<no qualified line>}; field 5 ${_b8mF:-<none>}; dry run exit $_b8mRc" "qualified skipped; field 5 -; dry run exit 0" \
   "$(cat "$_b8m/a21.out" "$_b8m/a21m.out" 2>/dev/null)"

# ---- C110 and the gate's tests line: FC and FT (A23 to A33)
_b8c="$TMP/b08-gate"; mkdir -p "$_b8c/tmp" "$_b8c/home"
_b8cG="$REAL_HARNESS/../../projects/felix/gate.sh"
_b8cH="$REAL_HARNESS/../hooks/hooks.json"
_b8cS="$REAL_HARNESS/../../.claude/settings.json"
_b8cWhy=""
[ -f "$_b8cG" ] || _b8cWhy="no projects/felix/gate.sh beside this engine"
_b8cWhyC="$_b8cWhy"
if [ -z "$_b8cWhyC" ] && { [ ! -f "$_b8cH" ] || [ ! -f "$_b8cS" ]; }; then
  _b8cWhyC="no engine/hooks/hooks.json and .claude/settings.json in this tree"
fi
_b8c_git() { local d="$1"; shift; _fx_git "$d" -c user.name=b08 -c user.email=b08@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"; }
_b8c_mk() {   # dir yes|no: a checkout with this tree's gate and stubs, and with yes the two hook files
  local d="$1"
  mkdir -p "$d/engine/harness/bin" "$d/engine/harness/lib" "$d/engine/harness/tests" "$d/projects/felix" || return 1
  cp "$_b8cG" "$d/projects/felix/gate.sh" || return 1
  printf '#!/bin/sh\nexit 0\n' > "$d/engine/harness/bin/schema-check"
  printf '#!/bin/sh\n[ "${1:-}" = --paths ] && echo engine/harness/bin\nexit 0\n' > "$d/engine/harness/bin/independence-scan"
  printf '_b8c_probe() {\n  _felix_dep_grep "$root" "b08zzword"\n}\n' > "$d/engine/harness/lib/detect.sh"
  printf '# kind\tfile\ttoken\treason\n' > "$d/engine/harness/ecosystem.tsv"
  cat > "$d/engine/harness/tests/run" <<'B8CRUN'
#!/usr/bin/env bash
printf 'ran\n' > "${B8C_MARK:?}"
case "$(cat "${B8C_MODE:?}")" in
  another) printf 'not reused: another tree\n\n  ok    a part line\n\n5 passed, 0 failed\n'; exit 0 ;;
  stderr)  printf 'warning: x' >&2; printf 'not reused: no receipt\n\n  ok    a part line\n\n5 passed, 0 failed\n'; exit 0 ;;
  reused)  printf 'reused the suite run that ended 09:41 on this tree (normal), not run again\n\n12 passed, 0 failed (reused)\n'; exit 0 ;;
  plain)   printf '\n  ok    a part line\n\n5 passed, 0 failed\n'; exit 0 ;;
esac
exit 3
B8CRUN
  chmod +x "$d/engine/harness/bin/schema-check" "$d/engine/harness/bin/independence-scan" "$d/engine/harness/tests/run"
  if [ "$2" = yes ]; then
    mkdir -p "$d/engine/hooks" "$d/.claude"
    cp "$_b8cH" "$d/engine/hooks/hooks.json" && cp "$_b8cS" "$d/.claude/settings.json" || return 1
  fi
  ( _fx_cd "${d:?}" && git init -q -b main && git add -A \
      && git -c user.name=b08 -c user.email=b08@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm fixture ) >/dev/null 2>&1
}
_b8c_gate() {   # name dir mode [--quick]: output in $_b8c/<name>.out, the stub's marker at $_b8c/<name>.mark
  printf '%s\n' "$3" > "$_b8c/$1.mode"
  ( cd "${2:?}" && _b8m_bounded 60 env HOME="$_b8c/home" FELIX_KERNEL_CACHE="$_b8c/nocache" TMPDIR="$_b8c/tmp" \
      B8C_MODE="$_b8c/$1.mode" B8C_MARK="$_b8c/$1.mark" bash projects/felix/gate.sh ${4+"$4"} ) > "$_b8c/$1.out" 2>&1
  _b8cRc=$?
}
# The edits, as awk programs over the tree's files.
_b8cWIDEN='index($0, "\"PreToolUse\"") { p = 1 } p && index($0, "\"matcher\"") { sub(/",[ ]*$/, "|Glob|Grep\","); p = 0 } { print }'
_b8cASYNC='index($0, "harness/hooks/pre-tool") { p = 1 } p && index($0, "\"async\"") { sub(/false/, "true"); p = 0 } { print }'
_b8cNOSSM='index($0, "\"SessionStart\"") { p = 1 } p && index($0, "\"matcher\"") { p = 0; next } { print }'
_b8cTIMEOUT='index($0, "harness/hooks/stop") { p = 1 } p && index($0, "\"async\"") { print "            \"timeout\": 30,"; p = 0 } { print }'
_b8cNOSUB='skip { if ($0 == "    ]" || $0 == "    ],") skip = 0; next }
  index($0, "\"SubagentStart\"") { skip = 1; next }
  { t = $0; sub(/^ +/, "", t); c = substr(t, 1, 1)
    if (have) { if (c == "}" || c == "]") sub(/,$/, "", prev); print prev }
    prev = $0; have = 1 }
  END { if (have) print prev }'
_b8cTIGHT='index($0, "\"SessionStart\"") { p = 1 } p && index($0, "\"matcher\"") { sub(/"matcher": "/, "\"matcher\":\""); p = 0 } { print }'
_b8cSTATUS='index($0, "\"statusMessage\"") { sub(/: ".*"/, ": \"Checking the gate from the cloud\"") } { print }'
_b8c_chain() {   # src dst program...: dst is src run through each program; 1 when nothing changed
  local s="$1" d="$2" i=0 p
  shift 2
  cp "$s" "$_b8c/chain.0" || return 1
  for p in "$@"; do
    LC_ALL=C awk "$p" "$_b8c/chain.$i" > "$_b8c/chain.$((i + 1))" || return 1
    i=$((i + 1))
  done
  cp "$_b8c/chain.$i" "$d" || return 1
  ! cmp -s "$s" "$d"
}
# name: the cloud line's verdict in _b8cV, the line under it in _b8cD, the output in _b8cAll.
_b8c_read() {
  _b8cAll="$(cat "$_b8c/$1.out" 2>/dev/null)"
  _b8cV="$(LC_ALL=C awk 'index($0, "  cloud ") == 1 { print $2; exit }' "$_b8c/$1.out" 2>/dev/null)"
  _b8cD="$(LC_ALL=C awk 'f { print; exit } index($0, "  cloud ") == 1 { f = 1 }' "$_b8c/$1.out" 2>/dev/null)"
  [ -n "$_b8cV" ] || _b8cV="<no cloud line, gate exit $_b8cRc>"
}
_b8c_fail() {   # name want...: ok when the cloud line is FAIL and the line under it holds every want
  local n="$1" w miss=""
  shift
  [ "$_b8cV" = FAIL ] || miss=" cloud [$_b8cV];"
  for w in "$@"; do case "$_b8cD" in *"$w"*) ;; *) miss="$miss detail lacks [$w];" ;; esac; done
  if [ -z "$miss" ]; then ok "$n"; else bad "$n" "$miss detail [$_b8cD]; output: $(_b8m_flat "$_b8cAll")"; fi
}
_b8c21="$(printf '%21s' '')"
_b8cSum="${_b8c21}5 passed, 0 failed"
_b8c_from() {   # file line count: that line and the count-1 after it, joined by |
  B8C_W="$2" LC_ALL=C awk -v n="$3" 'k > 0 && k < n { o = o "|" $0; k++ } $0 == ENVIRON["B8C_W"] && !k { o = $0; k = 1 }
    END { print (k ? o : "<no line [" ENVIRON["B8C_W"] "]>") }' "$1" 2>/dev/null
}

_b8cN23="b08 A23 (B26): FC with the tree's own two files: cloud ok (control)"
_b8cN24="b08 A24 (B26): FC with only the settings Stop hook's statusMessage changed: cloud ok (control)"
_b8cN25="b08 A25 (B27): FC, the plugin's PreToolUse matcher widened by |Glob|Grep: cloud FAIL, PreToolUse/pre-tool bound differently (matcher)"
_b8cN26="b08 A26 (B27): FC, five edits at once: one clause per binding, naming matcher, async and timeout as each differs"
_b8cN27="b08 A27 (B28): and the same run still says not bound for the cloud: SubagentStart/subagent-start (control)"
_b8cN28="b08 A28 (B29): FC, the plugin SessionStart line written \"matcher\":\"...\": cloud FAIL, unreadable: engine/hooks/hooks.json"
_b8cN29="b08 A29 (B25): in A23's --quick run the tests line is skipped (--quick) and the suite did not run (control)"
_b8cN30="b08 A30 (B23): FT, a suite that ran saying not reused: another tree: tests ok, the summary under it, then the not-reused line under that"
_b8cN31="b08 A31 (B23): FT, a not-reused line behind a stderr fragment with no newline: the line after the summary is not reused: no receipt, 21 spaces in"
_b8cN32="b08 A32 (B24): FT, a reused suite: tests reused, and no line says not reused: (control)"
_b8cN33="b08 A33 (B25): FT, a log with no not-reused line: the line after the summary is not indented 21 spaces (control)"
if [ -n "$_b8cWhyC" ]; then
  for _b8cn in "$_b8cN23" "$_b8cN24" "$_b8cN25" "$_b8cN26" "$_b8cN27" "$_b8cN28" "$_b8cN29"; do skip "$_b8cn" "$_b8cWhyC"; done
else
  _b8cC="$_b8c/fc"; _b8c_mk "$_b8cC" yes; _b8cC="$(cd "${_b8cC:?}" && pwd -P)"
  _b8cCH="$_b8cC/engine/hooks/hooks.json"; _b8cCS="$_b8cC/.claude/settings.json"
  _b8c_case() {   # name hooks-programs settings-programs: both files from the tree's, edited, committed, then the gate
    local h="$2" s="$3" e=""
    cp "$_b8cH" "$_b8cCH"; cp "$_b8cS" "$_b8cCS"
    [ -z "$h" ] || { eval "_b8c_chain \"\$_b8cH\" \"\$_b8cCH\" $h" || e=" hooks.json"; }
    [ -z "$s" ] || { eval "_b8c_chain \"\$_b8cS\" \"\$_b8cCS\" $s" || e="$e settings.json"; }
    _b8c_git "$_b8cC" commit -qam "$1" >/dev/null 2>&1
    _b8c_gate "$1" "$_b8cC" plain --quick
    _b8c_read "$1"
    [ -z "$e" ] || _b8cV="<the fixture's edit changed nothing in$e>"
  }
  _b8c_case a23 "" ""
  is "$_b8cN23" "cloud $_b8cV" "cloud ok"
  _b8cO="$(grep -cxF -e "$(printf '  %-18s skipped (--quick)' tests)" "$_b8c/a23.out" 2>/dev/null)"
  _b8cM=absent; [ -e "$_b8c/a23.mark" ] && _b8cM=present
  _b8m_is "$_b8cN29" "${_b8cO:-0} tests skipped (--quick) line; the suite's marker $_b8cM" \
     "1 tests skipped (--quick) line; the suite's marker absent" "$_b8cAll"
  _b8c_case a24 "" '"$_b8cSTATUS"'
  is "$_b8cN24" "cloud $_b8cV" "cloud ok"
  _b8c_case a25 '"$_b8cWIDEN"' ""
  _b8c_fail "$_b8cN25" "bound differently for the cloud: PreToolUse/pre-tool (matcher);"
  _b8c_case a26 '"$_b8cWIDEN" "$_b8cTIMEOUT"' '"$_b8cASYNC" "$_b8cNOSSM" "$_b8cNOSUB"'
  _b8c_fail "$_b8cN26" "PreToolUse/pre-tool (matcher, async);" "SessionStart/session-start (matcher);" "Stop/stop (timeout);"
  _b8m_every "$_b8cN27" "$_b8cAll" "not bound for the cloud:" "SubagentStart/subagent-start"
  _b8c_case a28 '"$_b8cTIGHT"' ""
  _b8c_fail "$_b8cN28" "unreadable:" "engine/hooks/hooks.json"
fi
if [ -n "$_b8cWhy" ]; then
  for _b8cn in "$_b8cN30" "$_b8cN31" "$_b8cN32" "$_b8cN33"; do skip "$_b8cn" "$_b8cWhy"; done
else
  _b8cT="$_b8c/ft"; _b8c_mk "$_b8cT" no; _b8cT="$(cd "${_b8cT:?}" && pwd -P)"
  _b8cOk="$(printf '  %-18s ok' tests)"
  _b8c_gate a30 "$_b8cT" another
  _b8m_is "$_b8cN30" "$(_b8c_from "$_b8c/a30.out" "$_b8cOk" 3)" \
     "$_b8cOk|$_b8cSum|${_b8c21}not reused: another tree" "$(cat "$_b8c/a30.out" 2>/dev/null)"
  _b8c_gate a31 "$_b8cT" stderr
  _b8m_is "$_b8cN31" "$(_b8c_from "$_b8c/a31.out" "$_b8cSum" 2)" \
     "$_b8cSum|${_b8c21}not reused: no receipt" "$(cat "$_b8c/a31.out" 2>/dev/null)"
  _b8c_gate a32 "$_b8cT" reused
  _b8cO="$(grep -cxF -e "$(printf '  %-18s reused' tests)" "$_b8c/a32.out" 2>/dev/null) $(LC_ALL=C grep -cF 'not reused:' "$_b8c/a32.out" 2>/dev/null)"
  _b8m_is "$_b8cN32" "$_b8cO" "1 0" "$(cat "$_b8c/a32.out" 2>/dev/null)"
  _b8c_gate a33 "$_b8cT" plain
  _b8cO="$(_b8c_from "$_b8c/a33.out" "$_b8cSum" 2)"
  case "$_b8cO" in
    "<no line"*)         _b8cO="no summary line under tests ok" ;;
    "$_b8cSum|$_b8c21"*) _b8cO="indented [${_b8cO#*|}]" ;;
    *)                   _b8cO="not indented" ;;
  esac
  _b8m_is "$_b8cN33" "$_b8cO" "not indented" "$(cat "$_b8c/a33.out" 2>/dev/null)"
fi

# ---- Review round, C110 (A61 to A68): bindings off the layout, files with no final newline
_b8vN61="b08 A61 (B30): FC, the plugin gains a PreCompact event whose one hook is written on one line, no async, unbound in settings: cloud FAIL, not bound for the cloud: PreCompact/pre-compact"
_b8vN62="b08 A62 (B30): FC, the same hook object written over four lines at 12 spaces: cloud FAIL, not bound for the cloud: PreCompact/pre-compact"
_b8vN63="b08 A63 (B30): FC, both files' PreToolUse group closed by a line with trailing spaces, the plugin matcher widened by |Glob|Grep: cloud FAIL, PreToolUse/pre-tool bound differently (matcher)"
_b8vN64="b08 A64 (B30): FC, a one-line PreCompact hook in both files under matcher manual in the plugin and auto in settings: cloud FAIL, PreCompact/pre-compact bound differently (matcher)"
_b8vN65="b08 A65 (B31): FC, the plugin's hooks.json byte for byte as in the tree but with no final newline: cloud ok"
_b8vN66="b08 A66 (B31): FC, settings.json with no final newline: cloud ok (control)"
_b8vN67="b08 A67 (B31): FC, both files with no final newline: cloud ok"
_b8vN68="b08 A68 (B31): FC, hooks.json with no final newline and its PreToolUse matcher widened: cloud FAIL, PreToolUse/pre-tool bound differently (matcher), and nothing unreadable"
if [ -n "$_b8cWhyC" ]; then
  for _b8cn in "$_b8vN61" "$_b8vN62" "$_b8vN63" "$_b8vN64" "$_b8vN65" "$_b8vN66" "$_b8vN67" "$_b8vN68"; do skip "$_b8cn" "$_b8cWhyC"; done
else
  _b8vPL='          { "type": "command", "command": "\"${CLAUDE_PLUGIN_ROOT}/harness/hooks/pre-compact\"" }'
  _b8vSL='          { "type": "command", "command": "[ \"$CLAUDE_CODE_REMOTE\" = true ] || exit 0; exec bash \"$CLAUDE_PROJECT_DIR/engine/harness/hooks/pre-compact\"" }'
  _b8v_pc() {   # name matcher|- line...: an awk program putting a PreCompact event, one group of those hook lines, before SubagentStart
    local f="$_b8c/pc-$1.json" m="$2"
    shift 2
    { printf '    "PreCompact": [\n      {\n'
      [ "$m" = - ] || printf '        "matcher": "%s",\n' "$m"
      printf '        "hooks": [\n'; printf '%s\n' "$@"; printf '        ]\n      }\n    ],\n'; } > "$f"
    printf '$0 == "    \\"SubagentStart\\": [" { while ((getline l < "%s") > 0) print l; close("%s") } { print }' "$f" "$f"
  }
  _b8vPC1="$(_b8v_pc one - "$_b8vPL")"
  _b8vPC2="$(_b8v_pc deep - '            {' '              "type": "command",' \
    '              "command": "\"${CLAUDE_PLUGIN_ROOT}/harness/hooks/pre-compact\""' '            }')"
  _b8vPCM="$(_b8v_pc manual manual "$_b8vPL")"
  _b8vPCA="$(_b8v_pc auto auto "$_b8vSL")"
  _b8vTRAIL='index($0, "\"PreToolUse\"") { p = 1 } p && $0 == "      }" { $0 = $0 "  "; p = 0 } { print }'
  _b8vNOEOL='NR > 1 { printf "\n" } { printf "%s", $0 }'
  _b8c_case a61 '"$_b8vPC1"' ""
  _b8c_fail "$_b8vN61" "not bound for the cloud:" "PreCompact/pre-compact"
  _b8c_case a62 '"$_b8vPC2"' ""
  _b8c_fail "$_b8vN62" "not bound for the cloud:" "PreCompact/pre-compact"
  _b8c_case a63 '"$_b8vTRAIL" "$_b8cWIDEN"' '"$_b8vTRAIL"'
  _b8c_fail "$_b8vN63" "bound differently for the cloud: PreToolUse/pre-tool (matcher);"
  _b8c_case a64 '"$_b8vPCM"' '"$_b8vPCA"'
  _b8c_fail "$_b8vN64" "bound differently for the cloud: PreCompact/pre-compact (matcher);"
  _b8c_case a65 '"$_b8vNOEOL"' ""
  _b8m_is "$_b8vN65" "cloud $_b8cV" "cloud ok" "$_b8cD"
  _b8c_case a66 "" '"$_b8vNOEOL"'
  _b8m_is "$_b8vN66" "cloud $_b8cV" "cloud ok" "$_b8cD"
  _b8c_case a67 '"$_b8vNOEOL"' '"$_b8vNOEOL"'
  _b8m_is "$_b8vN67" "cloud $_b8cV" "cloud ok" "$_b8cD"
  _b8c_case a68 '"$_b8cWIDEN" "$_b8vNOEOL"' ""
  _b8m_every "$_b8vN68" "cloud $_b8cV; $_b8cD" "cloud FAIL;" "bound differently for the cloud: PreToolUse/pre-tool (matcher);" -- "unreadable:"
fi

rm -rf "${_b8mP:?}" "${_b8gP:?}" "${MEM:?}/b08m" "${MEM:?}/b08g"
