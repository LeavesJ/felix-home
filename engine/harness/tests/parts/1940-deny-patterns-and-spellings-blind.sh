printf '\nthe deny floor: patterns every engine compiles alike, and the spellings rows 19 and 20 refuse (audit b16, C076 and C079, blind)\n'
# Written blind on 2026-10-24 from docs/2026-10-24-audit-fixes/b16-deny-floor-judges-effects-on-every-tool.md
# alone (sections 2 and 4, A32 to A52). No engine code was read: bin/schema-check, felix doctor and the
# pre-tool hook are run as black boxes, and projects/felix/deny.tsv is read only as A52 says and copied
# whole for A49 to A51, so each verdict there is the shipped table's. Every part runs alone: each
# fixture below is this part's own, under $TMP, and it relies on the prelude only (FROOT, TMP, FELIX,
# REAL_HARNESS, _pre, _fx_cd, ok, bad, is, skip).
#
# "Refused" is exit 2 with the row's whole reason on stderr; "allowed" is exit 0 with nothing on
# stderr; any other exit is named in the failure. A fixture that cannot be built makes its assertions
# skips with the same names, never passes.
#
# Readings, where the contract leaves room:
# - schema-check's refusals are read as output lines that begin <path>:<line><TAB><kind><TAB>, the
#   shape its other refusals have; "no pattern- line naming line N" is no line beginning
#   p/deny.tsv:N<TAB>pattern-.
# - S1's schemas.tsv holds the shipped rows for schemas.tsv, deny.tsv and risk.tsv, each verbatim.
#   Both tables are present in every case, the one not under test holding one clean row, so that the
#   only refusals are the ones each assertion is about.
# - A36, A41 to A43 and A46 are one assertion each, as are A45 and A48; the failure names what went
#   wrong. A34, A49, A50 and A51 are one assertion per row or command, as the contract says.
# - A46's path is matched as written ($FROOT/projects/widget/deny.tsv) or physical.
# - The reasons of A49 and A50 are the whole reasons B20 and B21 give, not their first words.

# ---- helpers
_dp_tab="$(printf '\t')"
_dp_esc() { printf '%s' "$1" | LC_ALL=C sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }
_dp_bash() { printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$(_dp_esc "$1")"; }
_dp_v() {   # DIR PAYLOAD REASON -> _dp_got (refused, allowed, or what happened instead) and _dp_err
  local rc
  rm -f "$FROOT/.deny-err"
  ( cd "$1" && _pre "$2" ) >/dev/null 2>&1; rc=$?
  _dp_err="$(cat "$FROOT/.deny-err" 2>/dev/null)"
  case "$rc" in
    2) case "$_dp_err" in *"$3"*) _dp_got=refused ;; *) _dp_got="exit 2 without [$3] on stderr" ;; esac ;;
    0) if [ -z "$_dp_err" ]; then _dp_got=allowed; else _dp_got="exit 0 with something on stderr"; fi ;;
    *) _dp_got="exit $rc, which is neither 0 nor 2" ;;
  esac
}
_dp_is() {   # NAME WANT: one assertion from the last _dp_v
  if [ "$_dp_got" = "$2" ]; then ok "$1"
  else bad "$1" "wanted $2, got $_dp_got; stderr [$(printf '%s' "$_dp_err" | LC_ALL=C tr '\n' ' ' | cut -c 1-300)]"; fi
}

# ---- fixture S1: a git tree with its own schemas.tsv, p/deny.tsv and p/risk.tsv
printf '\nschema-check refuses a pattern that does not compile, or reads differently on macOS and Linux (B13 to B18)\n'
_dp_s="$TMP/sc1940"; _dp_so="$TMP/sc1940.out"
mkdir -p "$_dp_s/engine/harness/templates" "$_dp_s/p"
LC_ALL=C awk -F'\t' '$1 == "schemas.tsv" || $1 == "deny.tsv" || $1 == "risk.tsv"' "$REAL_HARNESS/templates/schemas.tsv" \
  > "$_dp_s/engine/harness/templates/schemas.tsv" 2>/dev/null
_dp_sn="$(LC_ALL=C awk 'END { print NR }' "$_dp_s/engine/harness/templates/schemas.tsv" 2>/dev/null)"
_dp_deny0() { printf '# tool\tpattern\treason\nBash\tgit push --force\tforce\n' > "$_dp_s/p/deny.tsv"; }
_dp_risk0() { printf '# tier\tkind\tpattern\treason\nred\tpath\t^db/migrations/\tmigrations\n' > "$_dp_s/p/risk.tsv"; }
_dp_deny0; _dp_risk0
( _fx_cd "$_dp_s" && git init -q -b main && git add -A && git -c user.name=t -c user.email=t@t commit -qm seed ) >/dev/null 2>&1
_dp_s="$(cd "$_dp_s" && pwd -P)"
_dp_snofx=""
{ [ "$_dp_sn" = 3 ] && [ -d "$_dp_s/.git" ] && [ -x "$REAL_HARNESS/bin/schema-check" ]; } \
  || _dp_snofx="fixture S1 could not be built (three rows from the shipped schemas.tsv, a git tree, bin/schema-check)"
_dp_go() {   # commit the tree as it stands, then run schema-check from it: _dp_rc, and the output in $_dp_so
  ( _fx_cd "$_dp_s" && git add -A && git -c user.name=t -c user.email=t@t commit -qm case ) >/dev/null 2>&1
  ( cd "$_dp_s" && "$REAL_HARNESS/bin/schema-check" ) > "$_dp_so" 2>&1; _dp_rc=$?
}
_dp_at() {   # FILE LINE PREFIX -> the first output line that begins FILE:LINE<TAB>PREFIX
  LC_ALL=C awk -v p="$1:$2" -v k="$3" 'BEGIN { p = p "\t" k } index($0, p) == 1 && !f { print; f = 1 }' "$_dp_so" 2>/dev/null
}
_dp_none() {   # FILE LINE... -> the lines among LINE... that some pattern- line names, or nothing
  local f="$1" n out=""; shift
  for n in "$@"; do [ -z "$(_dp_at "$f" "$n" pattern-)" ] || out="$out $n"; done
  printf '%s' "$out"
}

_dp_n="schema-check A32 (B13): a deny pattern bash cannot compile, (?i)rm -rf, is refused as pattern-uncompilable at its line, exit 1"
_dp_n2="schema-check A33 (B13): and so is one with an unbalanced parenthesis, git push ("
if [ -n "$_dp_snofx" ]; then skip "$_dp_n" "$_dp_snofx"; skip "$_dp_n2" "$_dp_snofx"
else
  { printf '# tool\tpattern\treason\n'; printf '%s\t%s\t%s\n' Bash '(?i)rm -rf' 'no rm' Bash 'git push (' 'no push'; } > "$_dp_s/p/deny.tsv"
  _dp_risk0; _dp_go
  if [ -n "$(_dp_at p/deny.tsv 2 "pattern-uncompilable$_dp_tab")" ]; then _dp_x="rc $_dp_rc, refused at line 2"
  else _dp_x="rc $_dp_rc, and no line begins p/deny.tsv:2<TAB>pattern-uncompilable<TAB>"; fi
  is "$_dp_n" "$_dp_x" "rc 1, refused at line 2"
  if [ -n "$(_dp_at p/deny.tsv 3 "pattern-uncompilable$_dp_tab")" ]; then _dp_x="refused at line 3"
  else _dp_x="no line begins p/deny.tsv:3<TAB>pattern-uncompilable<TAB>"; fi
  is "$_dp_n2" "$_dp_x" "refused at line 3"
fi

# A34 and A35 share one table: line 1 a comment, lines 2 to 14 the thirteen escapes, 15 to 21 portable.
if [ -z "$_dp_snofx" ]; then
  { printf '# tool\tpattern\treason\n'
    for _dp_e in s S d D w W b B y '<' '>'; do printf 'Bash\tx\\%sy\tunportable\n' "$_dp_e"; done
    printf '%s\t%s\t%s\n' Bash '[[:<:]]x' unportable Bash 'x[[:>:]]' unportable
    printf '%s\t%s\t%s\n' Bash '\.felix(-home)?$' p1 Bash '\+x' p2 Bash '\(x' p3 Bash 'a\\d' p4 \
      Bash '(^|[^\\])(\\\\)*(\\[nrt])+' p5 Bash '[[:space:]]+' p6 Bash 'git( +-[^ ]+)* +push' p7
  } > "$_dp_s/p/deny.tsv"
  _dp_risk0; _dp_go
fi
_dp_ln=2
while IFS= read -r _dp_e; do
  _dp_n="schema-check A34 (B14): a deny pattern holding $_dp_e is refused as pattern-unportable at its line, and its why names $_dp_e"
  if [ -n "$_dp_snofx" ]; then skip "$_dp_n" "$_dp_snofx"
  else
    _dp_l="$(_dp_at p/deny.tsv "$_dp_ln" "pattern-unportable$_dp_tab")"
    if [ -z "$_dp_l" ]; then _dp_x="no line begins p/deny.tsv:$_dp_ln<TAB>pattern-unportable<TAB>"
    else
      _dp_w="${_dp_l#*pattern-unportable$_dp_tab}"
      case "$_dp_w" in *"$_dp_e"*) _dp_x="refused, naming it" ;; *) _dp_x="refused, but the why [$_dp_w] does not name it" ;; esac
    fi
    is "$_dp_n" "$_dp_x" "refused, naming it"
  fi
  _dp_ln="$((_dp_ln + 1))"
done <<'J'
\s
\S
\d
\D
\w
\W
\b
\B
\y
\<
\>
[[:<:]]
[[:>:]]
J
_dp_n="schema-check A35 (B15): \\. \\+ \\( an escaped backslash before d, (\\\\\\\\)*, [[:space:]] and git( +-[^ ]+)* +push are portable"
if [ -n "$_dp_snofx" ]; then skip "$_dp_n" "$_dp_snofx"
else is "$_dp_n" "$(_dp_none p/deny.tsv 15 16 17 18 19 20 21)" ""; fi

_dp_n="schema-check A36 (B16): risk.tsv's pattern column gets both checks: ^src/(auth uncompilable, \\d+\\.sql\$ and [[:<:]]password unportable"
_dp_n2="schema-check A37 (B16): and a plain risk pattern, ^db/migrations/, is refused by neither"
if [ -n "$_dp_snofx" ]; then skip "$_dp_n" "$_dp_snofx"; skip "$_dp_n2" "$_dp_snofx"
else
  _dp_deny0
  { printf '# tier\tkind\tpattern\treason\n'
    printf '%s\t%s\t%s\t%s\n' red path '^src/(auth' auth red path '\d+\.sql$' migrations \
      red content '[[:<:]]password' secret red path '^db/migrations/' migrations
  } > "$_dp_s/p/risk.tsv"
  _dp_go; _dp_x=""
  [ -n "$(_dp_at p/risk.tsv 2 "pattern-uncompilable$_dp_tab")" ] || _dp_x="$_dp_x line 2 is not pattern-uncompilable;"
  [ -n "$(_dp_at p/risk.tsv 3 "pattern-unportable$_dp_tab")" ] || _dp_x="$_dp_x line 3 is not pattern-unportable;"
  [ -n "$(_dp_at p/risk.tsv 4 "pattern-unportable$_dp_tab")" ] || _dp_x="$_dp_x line 4 is not pattern-unportable;"
  is "$_dp_n" "$_dp_x" ""
  is "$_dp_n2" "$(_dp_none p/risk.tsv 5)" ""
fi

_dp_n="schema-check A38 (B17): a tree whose patterns are all clean exits 0, every one declared and every row accepted"
if [ -n "$_dp_snofx" ]; then skip "$_dp_n" "$_dp_snofx"
else
  _dp_deny0; _dp_risk0; _dp_go
  case "$(cat "$_dp_so" 2>/dev/null)" in *"every one declared and every row accepted"*) _dp_x="said" ;; *) _dp_x="not said" ;; esac
  is "$_dp_n" "rc $_dp_rc, $_dp_x" "rc 0, said"
fi

_dp_n="schema-check A39 (B17): comments holding (?i) or \\b, a blank line and an empty pattern cell are never judged as patterns"
if [ -n "$_dp_snofx" ]; then skip "$_dp_n" "$_dp_snofx"
else
  { printf '# (?i) is not POSIX\n# \\b neither\n\n'; printf 'Bash\t\tan empty pattern\nBash\tgit push --force\tforce\n'; } > "$_dp_s/p/deny.tsv"
  _dp_risk0; _dp_go
  is "$_dp_n" "$(_dp_none p/deny.tsv 1 2 3 4)" ""
fi

_dp_n="schema-check A40 (B18): the shipped tree has no pattern-uncompilable and no pattern-unportable line"
_dp_rt="$(cd "$REAL_HARNESS/../.." && pwd -P)"
_dp_top="$(git -C "$_dp_rt" rev-parse --show-toplevel 2>/dev/null)"
_dp_topp="$( [ -n "$_dp_top" ] && cd "$_dp_top" 2>/dev/null && pwd -P)"
if [ -n "$_dp_topp" ] && [ "$_dp_topp" = "$_dp_rt" ] && [ -x "$REAL_HARNESS/bin/schema-check" ]; then
  ( cd "$_dp_rt" && "$REAL_HARNESS/bin/schema-check" ) > "$TMP/sc1940-real.out" 2>&1
  _dp_x="$(LC_ALL=C awk 'index($0, "pattern-uncompilable") || index($0, "pattern-unportable") { n++; if (n <= 3) s = s " [" $0 "]" }
    END { print n + 0 " line(s)" s }' "$TMP/sc1940-real.out" 2>/dev/null)"
  is "$_dp_n" "$_dp_x" "0 line(s)"
else skip "$_dp_n" "$_dp_rt is not a git worktree"; fi

# ---- fixture D1: felix doctor in a checkout bound to widget, the table changing per assertion
printf '\nfelix doctor says what the hook skips without saying so (B19, B11)\n'
_dp_d="$TMP/doctor1940-repo"; mkdir -p "$_dp_d"
( _fx_cd "$_dp_d" && git init -q -b main ) >/dev/null 2>&1
_dp_d="$(cd "$_dp_d" && pwd -P)"; printf 'widget\n' > "$_dp_d/.felix"
_dp_do="$TMP/doctor1940.out"; _dp_wt="$FROOT/projects/widget/deny.tsv"; mkdir -p "$FROOT/projects/widget"
_dp_dnofx=""
{ [ -d "$_dp_d/.git" ] && [ -x "$FELIX" ]; } || _dp_dnofx="fixture D1 could not be built (a checkout bound to widget, an executable felix)"
_dp_doc() { ( cd "$_dp_d" && "$FELIX" doctor ) > "$_dp_do" 2>&1; _dp_drc=$?; }
_dp_has() { _DPA="$1" LC_ALL=C awk 'index($0, ENVIRON["_DPA"]) { f = 1 } END { exit !f }' "$_dp_do" 2>/dev/null; }
_dp_both() { _DPA="$1" _DPB="$2" LC_ALL=C awk 'index($0, ENVIRON["_DPA"]) && index($0, ENVIRON["_DPB"]) { f = 1 } END { exit !f }' "$_dp_do" 2>/dev/null; }
_dp_seen() {   # what doctor said about deny rules, or how its output began when it said nothing of them
  LC_ALL=C awk 'NR <= 3 { h = h $0 "; " } tolower($0) ~ /deny/ && n < 6 { s = s $0 "; "; n++ }
    END { if (n) print s; else print "no line mentions deny; " NR " line(s), beginning: " h }' "$_dp_do" 2>/dev/null
}
_dp_h1="deny rules whose pattern does not compile"
_dp_h2="deny rules that read differently on macOS and Linux"
_dp_h3="deny rules naming a tool Felix reads no field of"
_dp_a41() { printf '%s\t%s\t%s\n' Bash '(?i)rm -rf' x > "$1"; }
_dp_rcs=""

_dp_n="felix doctor A41 (B19): a deny pattern that does not compile is listed under its own header, with its pattern"
if [ -n "$_dp_dnofx" ]; then skip "$_dp_n" "$_dp_dnofx"
else
  _dp_a41 "$_dp_wt"; _dp_doc; _dp_rcs="$_dp_rcs A41:$_dp_drc"; _dp_x="listed"
  { _dp_has "$_dp_h1" && _dp_has '(?i)rm -rf'; } || _dp_x="not listed: $(_dp_seen)"
  is "$_dp_n" "$_dp_x" "listed"
fi
_dp_n="felix doctor A42 (B19): a deny pattern holding \\b is listed as reading differently on macOS and Linux"
if [ -n "$_dp_dnofx" ]; then skip "$_dp_n" "$_dp_dnofx"
else
  printf '%s\t%s\t%s\n' Bash '\bgit push --force\b' x > "$_dp_wt"; _dp_doc; _dp_rcs="$_dp_rcs A42:$_dp_drc"; _dp_x="listed"
  { _dp_has "$_dp_h2" && _dp_has '\bgit push --force\b'; } || _dp_x="not listed: $(_dp_seen)"
  is "$_dp_n" "$_dp_x" "listed"
fi
_dp_n="felix doctor A43 (B19): rows naming bash and Grep, tools Felix reads no field of, are listed with their patterns"
if [ -n "$_dp_dnofx" ]; then skip "$_dp_n" "$_dp_dnofx"
else
  printf '%s\t%s\t%s\n' bash 'zz1943 push' x Grep 'zz1943\.env' x > "$_dp_wt"; _dp_doc; _dp_rcs="$_dp_rcs A43:$_dp_drc"; _dp_x=""
  _dp_has "$_dp_h3" || _dp_x="$_dp_x no header [$_dp_h3];"
  _dp_both bash 'zz1943 push' || _dp_x="$_dp_x no line holds bash and zz1943 push;"
  _dp_both Grep 'zz1943\.env' || _dp_x="$_dp_x no line holds Grep and zz1943\\.env;"
  [ -z "$_dp_x" ] || _dp_x="$_dp_x saw: $(_dp_seen)"
  is "$_dp_n" "$_dp_x" ""
fi
_dp_n="felix doctor A44 (B19): narrow, portable rows for every tool Felix reads print none of the three headers"
if [ -n "$_dp_dnofx" ]; then skip "$_dp_n" "$_dp_dnofx"
else
  printf '%s\t%s\t%s\n' Bash 'zz1944 bash' r1 Monitor 'zz1944 monitor' r2 Edit '/zz1944-edit\.txt$' r3 \
    MultiEdit '/zz1944-multi\.txt$' r4 Write '/zz1944-write\.txt$' r5 Read '/zz1944-read\.txt$' r6 \
    NotebookEdit '/zz1944-nb\.ipynb$' r7 WebFetch 'zz1944\.example\.com' r8 mcp__terminal__run_in_terminal 'zz1944 terminal' r9 \
    > "$_dp_wt"
  _dp_doc; _dp_rcs="$_dp_rcs A44:$_dp_drc"; _dp_x=""
  for _dp_e in "$_dp_h1" "$_dp_h2" "$_dp_h3" "refuses everything it was asked about"; do
    ! _dp_has "$_dp_e" || _dp_x="$_dp_x [$_dp_e]"
  done
  is "$_dp_n" "$_dp_x" ""
fi
_dp_n="felix doctor A45 (B19): felix doctor exits 0 for each of the tables of A41 to A44"
if [ -n "$_dp_dnofx" ]; then skip "$_dp_n" "$_dp_dnofx"; else is "$_dp_n" "$_dp_rcs" " A41:0 A42:0 A43:0 A44:0"; fi

_dp_n="felix doctor A46 (B19): a deny.tsv it cannot read is said, with its path, and no pattern section is printed for it"
if [ -n "$_dp_dnofx" ]; then skip "$_dp_n" "$_dp_dnofx"
else
  _dp_a41 "$_dp_wt"; chmod 000 "$_dp_wt"
  if [ -r "$_dp_wt" ]; then chmod 644 "$_dp_wt"; skip "$_dp_n" "the table is still readable after chmod 000, as it is for root"
  else
    _dp_doc; chmod 644 "$_dp_wt"
    _dp_wtp="$(cd "$FROOT/projects/widget" && pwd -P)/deny.tsv"; _dp_x="said"
    { _dp_both "could not be read" "$_dp_wt" || _dp_both "could not be read" "$_dp_wtp"; } \
      || _dp_x="no line holds could not be read and the table's path: $(_dp_seen)"
    ! _dp_has "$_dp_h1" || _dp_x="$_dp_x; and it still printed [$_dp_h1]"
    is "$_dp_n" "$_dp_x" "said"
  fi
fi

_dp_n="felix doctor A47 (B19): when the shared pattern check cannot be loaded, it says the deny patterns could not be checked, and exits 0"
_dp_fc="$TMP/froot1940"
if [ -n "$_dp_dnofx" ]; then skip "$_dp_n" "$_dp_dnofx"
else
  [ -e "$_dp_fc" ] || cp -R "$FROOT" "$_dp_fc" 2>/dev/null
  rm -f "$_dp_fc/harness/lib/table.sh"; mkdir -p "$_dp_fc/projects/widget"; _dp_a41 "$_dp_fc/projects/widget/deny.tsv"
  if [ -x "$_dp_fc/harness/felix" ] && [ ! -e "$_dp_fc/harness/lib/table.sh" ]; then
    ( cd "$_dp_d" && FELIX_HOME="$_dp_fc" "$_dp_fc/harness/felix" doctor ) > "$_dp_do" 2>&1; _dp_drc=$?
    if _dp_has "could not be checked"; then _dp_x="exit $_dp_drc, said"; else _dp_x="exit $_dp_drc, never said: $(_dp_seen)"; fi
    is "$_dp_n" "$_dp_x" "exit 0, said"
  else skip "$_dp_n" "a copy of the Felix home without lib/table.sh could not be made"; fi
fi

_dp_n="deny floor A48 (B11): a row bash cannot compile is skipped, and the rows after it still refuse"
if [ -n "$_dp_dnofx" ]; then skip "$_dp_n" "$_dp_dnofx"
else
  printf '%s\t%s\t%s\n' Bash '(?i)rm -rf' x Bash 'git push --force' 'force push drops commits' > "$_dp_wt"
  _dp_v "$_dp_d" "$(_dp_bash 'git push --force origin feat/x')" "force push drops commits"; _dp_x="push $_dp_got"
  _dp_v "$_dp_d" "$(_dp_bash 'rm -rf /tmp/x')" ""; _dp_x="$_dp_x, rm $_dp_got"
  is "$_dp_n" "$_dp_x" "push refused, rm allowed"
fi

# ---- fixture F1: projects/felix/deny.tsv as shipped, copied whole into the widget project
printf '\nrows 19 and 20 refuse their spellings, and the shipped table allows their neighbours (B20 to B22)\n'
_dp_ft="$(cd "$REAL_HARNESS/../.." && pwd)/projects/felix/deny.tsv"
_dp_fr="$TMP/spell1940-repo"; mkdir -p "$_dp_fr"
( _fx_cd "$_dp_fr" && git init -q -b main ) >/dev/null 2>&1
_dp_fr="$(cd "$_dp_fr" && pwd -P)"; printf 'widget\n' > "$_dp_fr/.felix"
_dp_fnofx=""
if [ ! -f "$_dp_ft" ]; then _dp_fnofx="no projects/felix/deny.tsv beside this harness"
elif ! cp "$_dp_ft" "$_dp_wt" 2>/dev/null; then _dp_fnofx="the shipped table could not be copied into the fixture"
elif [ ! -d "$_dp_fr/.git" ]; then _dp_fnofx="fixture F1's checkout could not be made"; fi
_dp_spell() {   # WANT REASON PREFIX; stdin: the commands, one a line, blanks kept
  local c
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    if [ -n "$_dp_fnofx" ]; then skip "$3: $c" "$_dp_fnofx"; continue; fi
    _dp_v "$_dp_fr" "$(_dp_bash "$c")" "$2"; _dp_is "$3: $c" "$1"
  done
}
_dp_spell refused "force push drops commits, and Felix's history is the audit trail" "rows 19 and 20 A49 (B20): the force-push row refuses" <<'J'
git push --force origin feat/x
git push -f origin feat/x
git push -fu origin feat/x
git push -uf origin feat/x
git push -qf origin feat/x
git push -4f origin feat/x
git push origin +feat/x
git push origin +HEAD:feat/x
git push origin feat/a +feat/b
git -C . push --force origin feat/x
git -C /tmp/elsewhere push -f origin feat/x
git -c push.default=current push --force origin feat/x
git --no-pager push -f origin feat/x
git  push --force origin feat/x
git push origin feat/x --force
J
_dp_spell refused "--no-verify is how a gate stops being a gate. Fix the tree instead" "rows 19 and 20 A50 (B21): the verify row refuses" <<'J'
git commit --no-verify -m x
git commit -m x --no-verify
git commit -n -m x
git commit -nm x
git commit -anm x
git commit -m x -n
git commit -m "a b" -n
git commit -n
git commit --amend -n --no-edit
git -C . commit --no-verify -m x
git -c user.name=t commit -n -m x
J
_dp_spell allowed "" "rows 19 and 20 A51 (B22): the shipped table allows" <<'J'
git push --force-with-lease origin feat/x
git push --force-with-lease=feat/x:abc123 origin feat/x
git push --force-if-includes --force-with-lease origin feat/x
git push -u origin feat/x
git push -n origin feat/x
git push -o ci.skip origin feat/x
git push --follow-tags origin feat/x
git push origin feat/x+y
git push origin a:b
git stash push -f
git commit -m "-n is fine"
git commit -mnote
git commit -sm x
git commit -v -m x
git commit --amend --no-edit
git commit -m "fix: git push --force here"
git log -n 3
J
_dp_n="rows 19 and 20 A52 (B22): one Bash row of three fields each holds the force-push reason and the verify reason"
if [ -f "$_dp_ft" ]; then
  _dp_x="$(LC_ALL=C awk -F'\t' '/^#/ { next }
    index($3, "force push drops commits") == 1 { fn++; ft = $1; fnf = NF }
    index($3, "--no-verify is how") == 1 { vn++; vt = $1; vnf = NF }
    END { printf "force push: %d row(s), %s, %d field(s); verify: %d row(s), %s, %d field(s)", fn, ft, fnf, vn, vt, vnf }' "$_dp_ft" 2>/dev/null)"
  is "$_dp_n" "$_dp_x" "force push: 1 row(s), Bash, 3 field(s); verify: 1 row(s), Bash, 3 field(s)"
else skip "$_dp_n" "no projects/felix/deny.tsv beside this harness"; fi

rm -f "$FROOT/projects/widget/deny.tsv" "$FROOT/.deny-err"
