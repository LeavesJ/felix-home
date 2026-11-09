# >>> trust-step3-run-tree-bytes
printf '\ntrust plane step 3, slice 3: what the units read is what lands (spec-slice3 section 8, A22 and A23; blind)\n'
# Blind, written on 2026-11-09 from .felix/memory/felix/audits/2026-11-08-trust-plane-step3/spec-slice3.md, section 8
# (A22, A23 and its observable cases 1 to 5), with sections 0 to 2 read only for P, B, H, T, a unit, unknown SUITE and
# how a dry run reports a refusal, by an author who has not read lib/instrument*.sh, lib/bind.sh or lib/merge-judge.sh:
# felix merge is driven as a black box. Conventions and the fixture come from tests/lib/instrument-parts.sh
# (_ts3c_build), the headers and fixture use of parts 2180 and 2183, and tests/run's helpers. The fixture is part 2180's,
# here under $TMP/ts3g, removed at the end with $MEM/felix when this part made it. Main gains two instrument parts of P
# that read a candidate file, with the files they read: 2007-scan.sh (no line of engine/widget/scan.txt is exactly
# FORBIDDEN token, and the file holds no bare $Id$ keyword) and 2008-marker.sh (engine/widget/MARKER exists).
#
# Readings, where the spec leaves room (part 2180's stand on "refused", "passed", a blocker line and the trace):
# - Each candidate also appends a comment to the P part that judges it, so S8.1 counts that part changed and P's unit
#   runs in T. A candidate that changes no instrument part makes no T (S8.7) and is outside these cases.
# - What lands is the blob, whose bytes are set with hash-object --no-filters and update-index --cacheinfo. The file in
#   the checkout is written by git checkout under H's .gitattributes, as a checkout obeying the tree's own attributes
#   writes it; the fixture controls apply P's test to both.
# - Case 1's "refused for P's part (or as unknown SUITE)": an escape line for 2007-scan.sh saying P's version fails on
#   this tree with the assertion's name, or an unknown SUITE line naming engine/widget/scan.txt, the only path an
#   attribute here converts and so the first that can differ (A22).
# - "Naming both" is the unknown SUITE line holding both repository paths. "No unit runs" (A23) is read from the trace;
#   the honest candidate of case 2 shows that the trace records a unit the merge runs.
# - Folding is probed where each run's TMPDIR sits ($TS3C/t): a file made as Fold is found as fOLD. Case 3 asserts the
#   branch that applies and skips the other; case 4 is asserted where names fold and skipped where they do not.
#
# Not covered: case 5 as an assertion (red first is how this part is run, not what it asserts); A23's fold of the
# Unicode-decomposed form (only case is driven); the canary's copy, which A22 and A23 also judge (no candidate here
# changes the machinery); A22's checks of kind, executable bit, symbolic link target and gitlink, and the filter
# attribute (it needs a driver configured where T is written); the cost; A23's "nothing here applies" where names do
# not fold (case 4 is skipped there); and what section 8 leaves open.
TS3C="$TMP/ts3g"; rm -rf "${TS3C:?}"; mkdir -p "$TS3C/repo" "$TS3C/gh" "$TS3C/home" "$TS3C/kc" "$TS3C/t" "$TS3C/ctl"
TS3C="$(cd "${TS3C:?}" && pwd -P)"; TS3CR="$TS3C/repo"; TS3CK="$TS3C/kc"; TS3CT=""; TS3CRC=0; TS3G_N=0
TS3G_MEM=kept; [ -e "$MEM/felix" ] || TS3G_MEM=made   # the merges write the project felix's memory, $MEM/felix
TS3GT_=engine/harness/tests; TS3GW=engine/widget; TS3G_NL='
'
TS3G_SF='scan: no line of scan.txt is FORBIDDEN token'; TS3G_SI='scan: scan.txt holds no bare Id keyword'
TS3G_SM='marker: the engine holds MARKER'; TS3G_FB="plain words${TS3G_NL}FORBIDDEN token$TS3G_NL"; TS3G_ID="plain words$TS3G_NL\$Id\$$TS3G_NL"

# ------------------------------------------------------------------ helpers ---
_ts3g_check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$3] got [$2]${4:+: $4}"; fi; }   # NAME GOT WANT [DETAIL]
_ts3g_why() { printf 'exit %s; out: %s; err: %s' "$TS3CRC" "$(head -c 1500 "$TS3C/out" 2>/dev/null | tr '\n' ' ')" \
  "$(head -c 400 "$TS3C/err" 2>/dev/null | tr '\n' ' ')"; }
_ts3g_said() { cat "$TS3C/out" "$TS3C/err" 2>/dev/null | LC_ALL=C awk -v a="$1" 'index($0, a) { f = 1 } END { print (f ? "yes" : "no") }'; }
_ts3g_refused() { if [ "$TS3CRC" -ne 0 ] && [ "$(_ts3g_said 'not merging')" = yes ]; then printf refused; else printf 'exit %s' "$TS3CRC"; fi; }
_ts3g_passed() { if [ "$TS3CRC" -eq 0 ]; then printf passed; else printf 'exit %s' "$TS3CRC"; fi; }
_ts3g_bl() {   # KIND SUBJECT WORD WORD2 -> yes when the last run printed a blocker line as part 2180 reads one
  cat "$TS3C/out" "$TS3C/err" 2>/dev/null | LC_ALL=C awk -v k="$1" -v nm="$2" -v a="$3" -v b="$4" '
    function subj(s) { return nm == "-" || s == nm || (length(s) > length(nm) && substr(s, length(s) - length(nm)) == "/" nm) }
    index($0, "  ") == 1 && $1 == k && subj($2) && (a == "-" || index($0, a)) && (b == "-" || index($0, b)) { f = 1 }
    END { print (f ? "yes" : "no") }'
}
_ts3g_sha() { _fx_git "$TS3CR" rev-parse --verify -q "$1^{commit}" 2>/dev/null; }   # REV -> its commit in R
_ts3g_record() {   # part 2180's: a green gate receipt and a commission receipt for R as it stands, read against P's project
  local p="$TS3CPP"
  ( _fx_cd "$TS3CR" && FELIX_HOME="$TS3CR"; . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/epoch.sh"
    felix_verify_record "$TS3CR" "$TS3CR" 0 "true" "$(felix_tree_id "$TS3CR" "$TS3CR")" "" "" "$(felix_epoch "$p" "$TS3CR")" \
      "$(felix_epoch_components "$p" "$TS3CR" | cut -f2 | paste -sd, -)" ) >/dev/null 2>&1
  ( _fx_cd "$TS3CR" && FELIX_HOME="$TS3CR"; FELIX_HOME_DIR="$TS3CR"; . "$FROOT/harness/lib/commission.sh"
    _o="$(felix_commission_run "$p" "$TS3CR" -)"
    felix_commission_receipt_write "$TS3CR" "$p" "$TS3CR" "$_o" "" ) >/dev/null 2>&1
}
_ts3g_prep() {   # the receipts, the provider stub at R's HEAD and origin/main, the trace emptied, and a fresh TS3CT
  _ts3g_record
  printf '7\tOPEN\tmain\t%s\n' "$(_ts3g_sha HEAD)" > "$TS3C/ctl/a"
  printf 'commit\t%s\n' "$(_ts3g_sha refs/remotes/origin/main)" > "$TS3C/ctl/q"
  : > "$TS3C/ctl/calls"; : > "$TS3C/trace"
  TS3G_N=$((TS3G_N + 1)); mkdir -p "$TS3C/t/$TS3G_N"; TS3CT="$(cd "$TS3C/t/$TS3G_N" && pwd -P)"
}
_ts3g_go() {   # [ARG...]: felix merge from the entry in R, as a child of this shell
  _fx_cd "$TS3CR" && exec env -u FELIX_KERNEL -u FELIX_MERGE_HANDED -u FELIX_INSTRUMENT_UNIT_SECONDS -u FELIX_INSTRUMENT_CANARY_SECONDS \
    HOME="$TS3C/home" PATH="$TS3C/gh:$PATH" TS3C_GHDIR="$TS3C/ctl" FELIX_HOME="$TS3CR" FELIX_KERNEL_CACHE="$TS3CK" \
    TMPDIR="$TS3CT" GIT_ALLOW_PROTOCOL=file "$TS3CK/1.0.0/harness/felix" merge "$@"
}
_ts3g_dry() { _ts3g_prep; ( _ts3g_go --dry-run ) > "$TS3C/out" 2> "$TS3C/err"; TS3CRC=$?; }
_ts3g_ran() { LC_ALL=C sort -u "$TS3C/trace" 2>/dev/null | tr '\n' ' '; }   # -> the parts of P that ran, by name
_ts3g_direct() {   # TREE-REV TESTS-REV PART...: TESTS-REV's driver runs PART... over TREE-REV's tree as git archive writes it
  local d="$TS3C/direct" tr="$1" ts="$2"; shift 2; rm -rf "${d:?}"; mkdir -p "$d"
  _fx_git "$TS3CR" archive -o "$TS3C/d.tar" "$tr" >/dev/null 2>&1 && tar -x -C "$d" -f "$TS3C/d.tar"
  rm -rf "${d:?}/$TS3GT_"
  _fx_git "$TS3CR" archive -o "$TS3C/d.tar" "$ts" "$TS3GT_" >/dev/null 2>&1 && tar -x -C "$d" -f "$TS3C/d.tar"
  rm -f "$TS3C/d.tar"; ( cd "$d" && bash "$TS3GT_/run" --part "$@" ) 2>&1; rm -rf "${d:?}"
}
_ts3g_fails() { LC_ALL=C awk 'index($0, "  FAIL  ") == 1 { printf "%s|", substr($0, 9) }'; }
_ts3g_main() {   # SHA: SHA is the provider's main, the entry its engine, and P's project directory its projects/felix
  _fx_git "$TS3CR" update-ref refs/remotes/origin/main "$1" >/dev/null 2>&1; _ts3c_entry "$1"
  rm -rf "${TS3C:?}/p"; mkdir -p "$TS3C/p"; _fx_git "$TS3CR" archive -o "$TS3C/p.tar" "$1" projects/felix >/dev/null 2>&1 \
    && tar -x -C "$TS3C/p" -f "$TS3C/p.tar"; rm -f "$TS3C/p.tar"; TS3CPP="$TS3C/p/projects/felix"
}
_ts3g_touch() { printf '# the candidate touched this part\n' >> "$TS3CR/$TS3GT_/parts/$1"; }   # PART: S8.1 counts it changed
_ts3g_blob() {   # PATH CONTENT: PATH's index entry holds CONTENT's bytes, through no attribute; its file is git checkout's
  local s; printf '%s' "$2" > "$TS3C/blob.t"
  s="$(_fx_git "$TS3CR" hash-object -w --no-filters "$TS3C/blob.t" 2>/dev/null)"; rm -f "$TS3C/blob.t"
  _fx_git "$TS3CR" update-index --add --cacheinfo "100644,$s,$1" >/dev/null 2>&1
  rm -f "$TS3CR/$1"; _fx_git "$TS3CR" checkout -- "$1" >/dev/null 2>&1
}
_ts3g_cand() {   # BRANCH ATTRS CONTENT -> the commit of a candidate whose .gitattributes is ATTRS (none when empty), whose
                 # scan.txt blob is CONTENT, and which touches 2007-scan.sh; R is left checked out at it
  _ts3c_case "$1"; [ -z "$2" ] || { printf '%s\n' "$2" > "$TS3CR/.gitattributes"; _fx_git "$TS3CR" add .gitattributes >/dev/null 2>&1; }
  _ts3g_blob "$TS3GW/scan.txt" "$3"; _ts3g_touch 2007-scan.sh; _ts3c_commit "$TS3CR" "$1"; _ts3g_sha HEAD
}
_ts3g_hid() {   # SHA FLAG PATTERN -> how many lines P's test finds in scan.txt's blob at SHA, and in the file the checkout wrote
  printf 'blob %s|file %s' "$(_fx_git "$TS3CR" cat-file blob "$1:$TS3GW/scan.txt" 2>/dev/null | LC_ALL=C grep -c "$2" -- "$3")" \
    "$(LC_ALL=C grep -c "$2" -- "$3" "$TS3CR/$TS3GW/scan.txt" 2>/dev/null)"
}
_ts3g_part_bl() { _ts3g_bl escape "$1" "P's version fails on this tree" "$2"; }   # PART NAME -> yes when refused for it

# ---------------------------------------------------------------- fixture R ---
_ts3c_build; _ts3c_on main
_ts3c_part 2007-scan.sh 'is "scan: no line of scan.txt is FORBIDDEN token" "$(LC_ALL=C grep -c -x -- "FORBIDDEN token" "$W/scan.txt" 2>/dev/null)" 0
is "scan: scan.txt holds no bare Id keyword" "$(LC_ALL=C grep -c -F -- "\$Id\$" "$W/scan.txt" 2>/dev/null)" 0'
_ts3c_part 2008-marker.sh 'is "marker: the engine holds MARKER" "$([ -e "$W/MARKER" ] && echo yes || echo no)" yes'
printf 'plain words\n' > "$TS3CR/$TS3GW/scan.txt"; printf 'the base marker\n' > "$TS3CR/$TS3GW/MARKER"
LC_ALL=C awk '{ print } index($0, "/parts/2006-keep.sh\"") { print ". \"$HERE/parts/2007-scan.sh\""; print ". \"$HERE/parts/2008-marker.sh\"" }' \
  "$TS3CR/$TS3GT_/run" > "$TS3C/run.t" && cat "$TS3C/run.t" > "$TS3CR/$TS3GT_/run"; rm -f "$TS3C/run.t"
printf '2007-scan.sh\tinstrument\tguards what scan.txt holds\n2008-marker.sh\tinstrument\tguards the MARKER file\n' >> "$TS3CR/projects/felix/partition.tsv"
{ _ts3c_names; printf '%s\n' "$TS3G_SF" "$TS3G_SI" "$TS3G_SM"; } | LC_ALL=C sort | LC_ALL=C awk 'NF { printf "1\t%s\n", $0 }' > "$TS3CR/$TS3GT_/assertions.tsv"
_ts3c_commit "$TS3CR" scan; TS3C_M="$(_ts3g_sha HEAD)"; _ts3g_main "$TS3C_M"
: > "$TS3C/trace"; TS3G_D="$(_ts3g_direct "$TS3C_M" "$TS3C_M" 2001-sum.sh 2002-count.sh 2003-grp-a.sh 2004-grp-b.sh 2005-mul.sh 2006-keep.sh 2007-scan.sh 2008-marker.sh | _ts3g_fails)"
_ts3g_check "ts3g: (fixture control) main sources 2007-scan.sh and 2008-marker.sh, its partition marks both instrument, it holds scan.txt and MARKER, P's driver passes every part on main's tree and each part traces itself, and main is the provider's" \
  "$(_fx_git "$TS3CR" show "$TS3C_M:$TS3GT_/run" | LC_ALL=C grep -c -E '/parts/200[78]-')|$(_fx_git "$TS3CR" show "$TS3C_M:projects/felix/partition.tsv" | LC_ALL=C awk -F'\t' '$1 ~ /^200[78]-/ { printf "%s ", $2 }')|$(_fx_git "$TS3CR" ls-tree --name-only "$TS3C_M" -- "$TS3GW/scan.txt" "$TS3GW/MARKER" | tr '\n' ' ')|$TS3G_D|$(_ts3g_ran)|$(_ts3g_sha refs/remotes/origin/main)" \
  "2|instrument instrument |$TS3GW/MARKER $TS3GW/scan.txt ||2001-sum.sh 2002-count.sh 2003-grp-a.sh 2004-grp-b.sh 2005-mul.sh 2006-keep.sh 2007-scan.sh 2008-marker.sh |$TS3C_M"
mkdir -p "$TS3C/t/fold"; : > "$TS3C/t/fold/Fold"; TS3G_FOLD=no; [ -e "$TS3C/t/fold/fOLD" ] && TS3G_FOLD=yes; rm -rf "${TS3C:?}/t/fold"

# ----- A22, case 1: an attribute git's checkout obeys does not hide what lands -----
# Each candidate's .gitattributes gives scan.txt one attribute, and its blob holds what P's 2007-scan.sh refuses, in the
# bytes that attribute changes on checkout: a line FORBIDDEN token re-encoded as UTF-16LE, a bare $Id$ expanded by ident,
# and the same line given a CR before its LF by text eol=crlf, so that an exact-line match misses it.
for _ts3g_v in UTF16 ident crlf; do
  case "$_ts3g_v" in
    UTF16) TS3G_A=working-tree-encoding=UTF-16LE; TS3G_C="$TS3G_FB"; TS3G_F=-x; TS3G_P='FORBIDDEN token'; TS3G_S="$TS3G_SF" ;;
    ident) TS3G_A=ident; TS3G_C="$TS3G_ID"; TS3G_F=-F; TS3G_P='$Id$'; TS3G_S="$TS3G_SI" ;;
    crlf)  TS3G_A='text eol=crlf'; TS3G_C="$TS3G_FB"; TS3G_F=-x; TS3G_P='FORBIDDEN token'; TS3G_S="$TS3G_SF" ;;
  esac
  TS3G_H="$(_ts3g_cand "h-$_ts3g_v" "$TS3GW/scan.txt $TS3G_A" "$TS3G_C")"
  _ts3g_check "ts3g: A22, case 1, $TS3G_A (fixture control): the candidate's blob of scan.txt holds what P's 2007-scan.sh refuses, and the file git's checkout writes for it under the candidate's .gitattributes hides it from that test" \
    "$(_ts3g_hid "$TS3G_H" "$TS3G_F" "$TS3G_P")|$(_fx_git "$TS3CR" diff --name-only "$TS3C_M" "$TS3G_H" | tr '\n' ' ')" \
    "blob 1|file 0|.gitattributes $TS3GT_/parts/2007-scan.sh $TS3GW/scan.txt "
  _ts3g_dry
  _ts3g_check "ts3g: A22, case 1, $TS3G_A: a candidate whose .gitattributes gives scan.txt this attribute, and whose blob holds what P's part refuses, is refused for 2007-scan.sh (or as unknown SUITE naming scan.txt), and is not passed" \
    "$(_ts3g_refused)|$( { [ "$(_ts3g_part_bl 2007-scan.sh "$TS3G_S")" = yes ] || [ "$(_ts3g_bl unknown SUITE "$TS3GW/scan.txt" -)" = yes ]; } && echo caught || echo missed)" \
    "refused|caught" "$(_ts3g_why)"
done

# ----- A22, case 2: the controls -----
# The same candidates with no .gitattributes are refused by P's part as it runs; an honest candidate whose .gitattributes
# is ordinary (*.sh text eol=lf over LF files) is not refused for A22. The trace shows its judgement ran P's unit in T.
for _ts3g_v in line Id; do
  case "$_ts3g_v" in
    line) TS3G_L="FORBIDDEN-line (UTF-16LE, eol=crlf)"; TS3G_C="$TS3G_FB"; TS3G_F=-x; TS3G_P='FORBIDDEN token'; TS3G_S="$TS3G_SF" ;;
    Id)   TS3G_L="bare-Id (ident)"; TS3G_C="$TS3G_ID"; TS3G_F=-F; TS3G_P='$Id$'; TS3G_S="$TS3G_SI" ;;
  esac
  TS3G_H="$(_ts3g_cand "h-plain-$_ts3g_v" "" "$TS3G_C")"
  _ts3g_dry
  _ts3g_check "ts3g: A22, case 2 (control): the $TS3G_L candidate of case 1 with no .gitattributes holds what P's part refuses in its checkout too, and is refused with escape, 2007-scan.sh, P's version fails on this tree, and the assertion's name" \
    "$(_ts3g_hid "$TS3G_H" "$TS3G_F" "$TS3G_P")|$(_ts3g_refused)|$(_ts3g_part_bl 2007-scan.sh "$TS3G_S")" "blob 1|file 1|refused|yes" "$(_ts3g_why)"
done
TS3G_H="$(_ts3g_cand h-honest '*.sh text eol=lf' "plain words$TS3G_NL")"
_ts3g_check "ts3g: A22, case 2 (fixture control): the honest candidate's .gitattributes gives P's parts text and eol=lf, no .sh file of its tree holds a CR, and it changes only that file and 2007-scan.sh" \
  "$(_fx_git "$TS3CR" check-attr text eol -- "$TS3GT_/parts/2007-scan.sh" | LC_ALL=C awk '{ printf "%s ", $NF }')|$(_fx_git "$TS3CR" ls-files --eol -- '*.sh' | LC_ALL=C awk '$1 != "i/lf" && $1 != "i/none" { n++ } END { print n + 0 }')|$(_fx_git "$TS3CR" diff --name-only "$TS3C_M" "$TS3G_H" | tr '\n' ' ')" \
  "set lf |0|.gitattributes $TS3GT_/parts/2007-scan.sh "
_ts3g_dry
_ts3g_check "ts3g: A22, case 2 (control): the honest candidate's judgement ran P's unit holding 2007-scan.sh in T" "ran [$(_ts3g_ran)]" "ran [2007-scan.sh ]" "$(_ts3g_why)"
_ts3g_check "ts3g: A22, case 2: an honest candidate with an ordinary .gitattributes (*.sh text eol=lf over LF files) is not refused for A22: it passes, with no unknown SUITE line and no escape line" \
  "$(_ts3g_passed)|SUITE $(_ts3g_bl unknown SUITE - -)|escape $(_ts3g_bl escape - - -)" "passed|SUITE no|escape no" "$(_ts3g_why)"

# ----- A23, case 3: a name the tree does not hold does not answer -----
# The base holds engine/widget/MARKER; the candidate deletes it and adds engine/widget/marker. Where names fold, P's
# 2008-marker.sh, run over the tree as written here, still finds MARKER; where they do not, it fails.
_ts3c_case h-case; _fx_git "$TS3CR" rm -q "$TS3GW/MARKER" >/dev/null 2>&1; printf 'the candidate marker\n' > "$TS3CR/$TS3GW/marker"
_ts3g_touch 2008-marker.sh; _ts3c_commit "$TS3CR" case; TS3G_H="$(_ts3g_sha HEAD)"; TS3G_WANT=""; [ "$TS3G_FOLD" = yes ] || TS3G_WANT="$TS3G_SM|"
_ts3g_check "ts3g: A23, case 3 (fixture control): the candidate drops engine/widget/MARKER and adds engine/widget/marker, and P's 2008-marker.sh over its tree as written here passes where names fold and fails where they do not" \
  "$(_fx_git "$TS3CR" ls-tree --name-only "$TS3G_H" -- "$TS3GW/" | LC_ALL=C awk '/\/(MARKER|marker)$/ { printf "%s ", $0 }')|$(_ts3g_direct "$TS3G_H" "$TS3C_M" 2008-marker.sh | _ts3g_fails)" \
  "$TS3GW/marker |$TS3G_WANT" "names fold here: $TS3G_FOLD"
_ts3g_dry
if [ "$TS3G_FOLD" = yes ]; then
  _ts3g_check "ts3g: A23, case 3, where names fold: a candidate that deletes the base's MARKER and adds marker is refused as unknown SUITE naming both paths, and no unit runs" \
    "$(_ts3g_refused)|$(_ts3g_bl unknown SUITE "$TS3GW/MARKER" "$TS3GW/marker")|ran [$(_ts3g_ran)]" "refused|yes|ran []" "$(_ts3g_why)"
  skip "ts3g: A23, case 3, where names do not fold: a candidate that deletes the base's MARKER and adds marker is refused by P's 2008-marker.sh" "names fold under this TMPDIR"
else
  skip "ts3g: A23, case 3, where names fold: a candidate that deletes the base's MARKER and adds marker is refused as unknown SUITE naming both paths, and no unit runs" "names do not fold under this TMPDIR"
  _ts3g_check "ts3g: A23, case 3, where names do not fold: a candidate that deletes the base's MARKER and adds marker is refused by P's 2008-marker.sh" \
    "$(_ts3g_refused)|$(_ts3g_part_bl 2008-marker.sh "$TS3G_SM")" "refused|yes" "$(_ts3g_why)"
fi

# ----- A23, case 4: two paths of one tree that fold to one name -----
# The candidate's tree holds engine/widget/Twin.txt and engine/widget/twin.txt with the same bytes, so A22's hashes
# hold for each and only A23 can see them; it touches 2007-scan.sh, so P's unit would run.
_ts3c_case h-twin; _ts3g_blob "$TS3GW/Twin.txt" "a twin$TS3G_NL"; _ts3g_blob "$TS3GW/twin.txt" "a twin$TS3G_NL"
_ts3g_touch 2007-scan.sh; _ts3c_commit "$TS3CR" twin; TS3G_H="$(_ts3g_sha HEAD)"
_ts3g_check "ts3g: A23, case 4 (fixture control): the candidate's tree holds engine/widget/Twin.txt and engine/widget/twin.txt, one blob for both" \
  "$(_fx_git "$TS3CR" ls-tree "$TS3G_H" -- "$TS3GW/" | LC_ALL=C awk -F'\t' '$2 ~ /\/[Tt]win\.txt$/ { split($1, a, " "); printf "%s ", $2; b[a[3]] = 1 } END { n = 0; for (k in b) n++; printf "|%d", n }')" \
  "$TS3GW/Twin.txt $TS3GW/twin.txt |1"
if [ "$TS3G_FOLD" = yes ]; then
  _ts3g_dry
  _ts3g_check "ts3g: A23, case 4, where names fold: a candidate whose tree holds two paths differing only by case is refused as unknown SUITE naming both, and no unit runs" \
    "$(_ts3g_refused)|$(_ts3g_bl unknown SUITE "$TS3GW/Twin.txt" "$TS3GW/twin.txt")|ran [$(_ts3g_ran)]" "refused|yes|ran []" "$(_ts3g_why)"
else
  skip "ts3g: A23, case 4, where names fold: a candidate whose tree holds two paths differing only by case is refused as unknown SUITE naming both, and no unit runs" "names do not fold under this TMPDIR"
fi

_ts3c_on main
rm -rf "${TS3C:?}"; [ "$TS3G_MEM" != made ] || rm -rf "${MEM:?}/felix"
unset TS3C TS3CR TS3CK TS3CT TS3CPP TS3C_M TS3G_MEM TS3G_N TS3G_H TS3G_A TS3G_C TS3G_F TS3G_P TS3G_S TS3G_D TS3G_WANT TS3G_L TS3G_FOLD _ts3g_v
# <<< trust-step3-run-tree-bytes
