# >>> b19-omission-surfaces-and-drift
printf '\naudit b19: what nothing answers yet, the gate probes block, and the fact log baseline (A1-A22, blind)\n'
# Blind, written on 2026-10-24 from docs/2026-10-24-audit-fixes/b19-capability-detection-and-omission-
# surfac.md alone (sections 2 to 5): no engine code was read. One assertion per contract item, named by the
# sentence it proves and tagged with the item; one marked (control) holds before the fix and after it.
#
# Fixtures (A0): git through _fx_git and _fx_cd under $TMP; lib calls in a fresh /bin/bash sourcing
# lib/resolve.sh and then the libs named, from $FROOT/harness, standing in the checkout; project
# directories $TMP/b19/<name>, each name used once, so each has its own MEM/<name>; the widget's
# probes.tsv and capabilities saved first and put back at the end; CLI runs with the claude stub first
# on PATH and a home of their own. Readings where the contract leaves room, mine:
# - A1 to A6 source resolve.sh and next.sh only, as B1 says that defines everything; A7 sums up their
#   rows. A2, A4, A5 and A6 pick a row by its what-field; A1 reads the first row.
# - A8: the owner lines are the lines of four spaces and a non-space above the heading.
# - A9: the counts line is the line after `  probes             ok`, read as 21 spaces and text.
# - A13 records into a project of its own, so the drift cases read R, C, D and E's runs only. No run
#   is recorded in A at `a`: its drift is asked, as B's, D's and E's are, so A21's three-argument
#   control reads C's run whichever run "the last tree" names.
# - A22: pfiles is the only predicate, so the whole output of felix probes is read for the phrases.
# Every part runs alone: this one builds its own checkouts and relies on the prelude only.
_cmstub_build
B19="$TMP/b19"; B19R="$TMP/b19r"; mkdir -p "$B19/home" "$B19R"
_b19T="$(printf '\t')"; _b19N=$'\n'
_b19_tpl="$FROOT/harness/templates"
_b19_pl="detect probes facts obligations verify"
_b19_mem=""
# DIR LIBS SCRIPT ARGS...: SCRIPT in a fresh /bin/bash standing in DIR, HOME the fixture's, after
# lib/resolve.sh and each lib in LIBS from $FROOT/harness; ARGS are its $1...; FELIX_MEMORY is $_b19_mem
# when that is set. Stdout only.
_b19_sh() {
  local _b19d="$1" _b19l="$2" _b19s="$3"; shift 3
  ( cd "$_b19d" || exit 125
    [ -z "$_b19_mem" ] || FELIX_MEMORY="$_b19_mem"
    HOME="$B19/home" /bin/bash -c '_h="$1"; _l="$2"; _s="$3"; shift 3; . "$_h/lib/resolve.sh"
      for _x in $_l; do . "$_h/lib/$_x.sh"; done; eval "$_s"' _b19 "$FROOT/harness" "$_b19l" "$_b19s" "$@" ) 2>/dev/null
}
_b19_git() { _fx_git "$@" >/dev/null 2>&1; }   # DIR ARGS...: a fixture git command, quiet
_b19_ci() { _b19_git "$1" add -A && _b19_git "$1" -c user.name=t -c user.email=t@t commit -qm "$2"; }   # DIR MESSAGE
_b19_repo() { mkdir -p "$1"; _b19_git "$1" init -q -b main && _b19_ci "$1" "${2:-m}"; }   # DIR [MESSAGE]: all of DIR committed
_b19_files() { local _b19f; for _b19f in "${@:2}"; do mkdir -p "$1/$(dirname "$_b19f")"; printf '%s\n' "${_b19f##*/}" > "$1/$_b19f"; done; }   # DIR PATH...
# One run recorded; the drift with four arguments, with three, and with a tree id given (PROJ ROOT [TID]).
_b19_rec() { _b19_sh "$2" "$_b19_pl" 'felix_probes_record "$1" "$2" "$(felix_tree_id "$2" "$3")" "$(felix_probes_run "$1" "$2")"' "$1" "$2" "$FROOT" >/dev/null; }
_b19_d4() { _b19_sh "$2" "$_b19_pl" 'felix_probes_drift "$1" "$(felix_tree_id "$2" "$3")" "$(felix_probes_run "$1" "$2")" "$2"' "$1" "$2" "$FROOT"; }
_b19_d3() { _b19_sh "$2" "$_b19_pl" 'felix_probes_drift "$1" "$(felix_tree_id "$2" "$3")" "$(felix_probes_run "$1" "$2")"' "$1" "$2" "$FROOT"; }
_b19_dt() { _b19_sh "$2" "$_b19_pl" 'felix_probes_drift "$1" "$3" "$(felix_probes_run "$1" "$2")" "$2"' "$1" "$2" "$3"; }
_b19_log() { printf '%s/facts.log' "$(_b19_sh "$B19" "" 'felix_mem_dir "$1"' "$1")"; }   # PROJ: its facts.log
# OUTPUT TEXT -> yes when a line of OUTPUT is exactly TEXT (_b19_line) or holds it (_b19_in), else no.
_b19_line() { printf '%s\n' "$1" | LC_ALL=C awk -v l="$2" '$0 == l { f = 1 } END { print (f ? "yes" : "no") }'; }
_b19_in() { printf '%s\n' "$1" | LC_ALL=C awk -v l="$2" 'index($0, l) { f = 1 } END { print (f ? "yes" : "no") }'; }
# OUTPUT WORDS: the first row whose what-field (field 2) holds WORDS, and the number of such rows.
_b19_row() { printf '%s\n' "$1" | LC_ALL=C awk -F'\t' -v w="$2" 'index($2, w) && !f { print; f = 1 }'; }
_b19_rows() { printf '%s\n' "$1" | LC_ALL=C awk -F'\t' -v w="$2" 'index($2, w) { n++ } END { print n + 0 }'; }

# ---- N: felix_next_unanswered (A1 to A7) ---------------------------------------------------------------
# PROJ ROOT: _b19o and _b19rc from felix_next_unanswered PROJ ROOT TPL; each call is logged for A7.
_b19_unlog="$B19/unanswered.log"; : > "$_b19_unlog"
_b19_un() {
  _b19o="$(_b19_sh "$2" next 'felix_next_unanswered "$1" "$2" "$3"' "$1" "$2" "$_b19_tpl")"; _b19rc=$?
  { printf '@@rc %s\n' "$_b19rc"; [ -z "$_b19o" ] || printf '%s\n' "$_b19o"; } >> "$_b19_unlog"
}
_b19_proj() { mkdir -p "$B19/$1" "$MEM/$1"; printf 'dk\tdeploy\t-\tls -1 Dockerfile\ttest -f Dockerfile\n' > "$B19/$1/probes.tsv"; }   # NAME
# n1: deploy, secrets, tests and observability detected; n2: billing, ci and database as well.
_b19_n() { _b19_files "$1" Dockerfile .env.example tests/t.sh; printf '%s\n' "${@:2}" > "$1/requirements.txt"; }
_b19n1="$B19R/n1"; _b19_n "$_b19n1" sentry-sdk; _b19_repo "$_b19n1"
_b19n2="$B19R/n2"; _b19_n "$_b19n2" sentry-sdk stripe; _b19_files "$_b19n2" .github/workflows/ci.yml migrations/1.sql
_b19_repo "$_b19n2"

_b19_proj b19n1; _b19p="$B19/b19n1"; _b19_un "$_b19p" "$_b19n1"
is "b19 A1: with only deploy grounded, the first row of felix_next_unanswered is felix, 3 surface(s) nothing probes: observability, secrets, tests, and how to ground each" \
   "$(printf '%s\n' "$_b19o" | LC_ALL=C awk 'NR == 1')" \
   "felix${_b19T}3 surface(s) nothing probes: observability, secrets, tests${_b19T}ground each in $_b19p/probes.tsv with a probe; felix probes says how"

_b19_proj b19n2; _b19_un "$B19/b19n2" "$_b19n2"
is "b19 A2: six surfaces nothing probes are named five at a time, then and 1 more" \
   "$(_b19_row "$_b19o" 'nothing probes' | cut -f2)" "6 surface(s) nothing probes: billing, ci, database, observability, secrets, and 1 more"

_b19w='the capabilities this checkout shows or this project declares could not be read'
_b19_proj b19n3; _b19p="$B19/b19n3"; ln -s "$B19/no-such-dir/capabilities" "$_b19p/capabilities"; _b19_un "$_b19p" "$_b19n1"
is "b19 A3: over a capabilities link whose target is gone the output is exactly the not-known probes row and the not-known procedures row, and the status is 0" \
   "rc=$_b19rc$_b19N$_b19o" \
   "rc=0${_b19N}felix${_b19T}which surfaces nothing probes is not known: $_b19w${_b19T}felix probes says the same, and reads them again${_b19N}felix${_b19T}which items nothing answers is not known: $_b19w${_b19T}felix procedures says the same, and reads them again"

_b19_proj b19n4; _b19p="$B19/b19n4"; _b19_un "$_b19p" "$_b19n1"; _b19a="$(_b19_row "$_b19o" 'nothing answers')"
for _b19i in deploy observability secrets tests; do printf 'capability:%s\tpre-deploy\ta person\tn\n' "$_b19i"; done > "$_b19p/procedures.tsv"
_b19_un "$_b19p" "$_b19n1"
is "b19 A4: with no procedures.tsv the procedures row names the four capability items nothing answers, and with a stance on each there is no procedures row" \
   "$_b19a | $(_b19_rows "$_b19o" 'nothing answers') row(s) with a stance on each" \
   "felix${_b19T}4 item(s) nothing answers: capability:deploy, capability:observability, capability:secrets, capability:tests${_b19T}take a stance on each in $_b19p/procedures.tsv; felix procedures lists them | 0 row(s) with a stance on each"

_b19_proj b19n5; _b19p="$B19/b19n5"
_b19_cand() { printf '2026-10-24T00:00:00Z\tb19tree\tb19epoch\tfelix@0/0\tobligations_surveyed.tsv@0\t%s\tADVISORY\tprobabilistic\t-\ttrue\t-\tb19_fm\ta candidate the fixture wrote\n' "$1"; }
{ printf '# candidates the fixture wrote\n'; _b19_cand ob_a; _b19_cand ob_a; _b19_cand ob_b; } > "$MEM/b19n5/candidates.tsv"
_b19_un "$_b19p" "$_b19n1"; _b19a="$(_b19_row "$_b19o" 'candidate obligation')"
LC_ALL=C awk -F'\t' -v OFS='\t' '!/^#/ && NF && !f { $1 = "ob_b"; print; f = 1 }' "$_b19_tpl/obligations.tsv" > "$_b19p/obligations.tsv"
_b19_un "$_b19p" "$_b19n1"
is "b19 A5: two distinct unadmitted candidate names give the founder's candidates row, and admitting ob_b leaves 1 candidate obligation(s) proposed and not admitted: ob_a" \
   "$_b19a | $(_b19_row "$_b19o" 'candidate obligation' | cut -f2)" \
   "founder${_b19T}2 candidate obligation(s) proposed and not admitted: ob_a, ob_b${_b19T}felix obligations lists them; a person admits one by copying its row into $_b19p/obligations.tsv | 1 candidate obligation(s) proposed and not admitted: ob_a"

_b19_proj b19n6; _b19p="$B19/b19n6"; _b19_un "$_b19p" "$_b19n1"; _b19a="$(_b19_rows "$_b19o" 'candidate obligation')"
mkdir -p "$MEM/b19n6/candidates.tsv"
_b19cp="$(_b19_sh "$B19" next 'if declare -F felix_candidates_path >/dev/null; then felix_candidates_path "$1"; else printf "%s/candidates.tsv\n" "$(felix_mem_dir "$1")"; fi' "$_b19p")"
_b19_un "$_b19p" "$_b19n1"
is "b19 A6: with no candidates.tsv there is no candidates row, and with a directory there it is exactly the row saying whether they wait on a person is not known" \
   "absent: $_b19a row(s) | a directory: $(_b19_rows "$_b19o" 'candidate obligation') row(s): $(_b19_row "$_b19o" 'candidate obligation')" \
   "absent: 0 row(s) | a directory: 1 row(s): felix${_b19T}whether candidate obligations wait on a person is not known: $_b19cp could not be read${_b19T}felix obligations reads it again"

_b19v="$(LC_ALL=C awk -F'\t' '
  /^@@rc / { if ($0 != "@@rc 0") st = st " [" $0 "]"; k = 0; calls++; next }
  { if (NF != 3) fl = fl " [" $0 "]"
    c = 9
    if (index($2, "nothing probes")) c = 1; else if (index($2, "nothing answers")) c = 2; else if (index($2, "candidate obligation")) c = 3
    if (c <= k || c == 9) od = od " [" $0 "]"
    k = c }
  END { printf "%d calls; fields:%s; order:%s; status:%s", calls, (fl == "" ? " three in every row" : fl), (od == "" ? " probes, procedures, candidates" : od), (st == "" ? " 0 on every call" : st) }' "$_b19_unlog")"
_b19a="$(_b19_sh "$B19" next 'declare -F felix_next_unanswered >/dev/null && printf defined || printf undefined')"
is "b19 A7: across A1 to A6 every row has three fields, rows come probes then procedures then candidates, every call exits 0, and resolve.sh with next.sh alone defines felix_next_unanswered" \
   "$_b19v; resolve.sh and next.sh alone: $_b19a" \
   "9 calls; fields: three in every row; order: probes, procedures, candidates; status: 0 on every call; resolve.sh and next.sh alone: defined"

# ---- the widget: felix next, felix gate and felix probes (A8 to A11, A22) --------------------------------
_b19wp="$FROOT/projects/widget"
for _b19i in probes.tsv capabilities; do
  rm -rf "$B19/widget-$_b19i.keep"
  if [ -e "$_b19wp/$_b19i" ] || [ -L "$_b19wp/$_b19i" ]; then cp -pR "$_b19wp/$_b19i" "$B19/widget-$_b19i.keep"; fi
done
# DIR ARGS...: the CLI in DIR, the claude stub first on PATH, a home of its own; FELIX_MEMORY is $_b19_mem when set.
_b19_cli() { ( cd "$1" && shift && { [ -z "$_b19_mem" ] || FELIX_MEMORY="$_b19_mem"; } \
               && HOME="$B19/home" PATH="$CMSTUB:$PATH" "$FELIX" "$@" 2>&1 ); }
_b19wc="$B19R/wck"; _b19_files "$_b19wc" WIDGET.txt; printf 'widget\n' > "$_b19wc/.felix"; _b19_repo "$_b19wc"
_b19wc="$(cd "$_b19wc" && pwd -P)"
printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' > "$_b19wp/probes.tsv"
rm -rf "$_b19wp/capabilities"; printf 'frontend\n' > "$_b19wp/capabilities"
_b19o="$(_b19_cli "$_b19wc" next)"
_b19v="$(printf '%s\n' "$_b19o" | LC_ALL=C awk -v H='  what nothing answers yet' \
  -v C='Nothing is ranked. None of the above blocks anything; each is a question no table answers yet.' '
  $0 == H && !hl { hl = NR; next }
  !hl && /^    [^ ]/ { own++ }
  index($0, "    felix    ") == 1 && index($0, "surface(s) nothing probes: ") { pr = 1 }
  index($0, "item(s). Ranked by") { tr = 1; s = $0; sub(/ item\(s\)\. Ranked by.*$/, "", s); sub(/^.* /, "", s); tn = s }
  index(tolower($0), "nothing due") { nd = 1 }
  $0 == C { cl = 1 }
  END { if (tr) t = (tn ~ /^[0123456789]+$/ && tn + 0 == own + 0) ? "ok" : ("the trailer says [" tn "] over " (own + 0) " ranked row(s)")
        else if (nd) t = "it says nothing due"
        else t = (cl ? "ok" : "no closing line")
        printf "heading %s, probes row %s, after them %s", (hl ? "yes" : "no"), (pr ? "yes" : "no"), t }')"
is "b19 A8: felix next over a declared frontend nothing probes prints what nothing answers yet with the felix probes row, and its trailer counts ranked rows only or it closes with Nothing is ranked" \
   "$_b19v" "heading yes, probes row yes, after them ok"

_b19S='                     '
_b19_files "$_b19wc" pdir/p1 pdir/p2 pdir/p3; _b19_ci "$_b19wc" pdir
printf 'pfiles\t-\t-\tls -1 pdir\ttest -d pdir\n' > "$_b19wp/probes.tsv"
_b19_gate() { mkdir -p "$1/widget"; _b19_mem="$1"; _b19go="$(_b19_cli "$_b19wc" gate)"; _b19grc=$?; _b19_mem=""; }   # MEMORY
_b19_gate "$B19/gmem"
_b19a="rc=$_b19grc ok=$(_b19_line "$_b19go" '  probes             ok') counts=$(printf '%s\n' "$_b19go" | LC_ALL=C awk -v s="$_b19S" '
  p && !f { print ((index($0, s) == 1 && substr($0, 22, 1) != " " && substr($0, 22, 1) != "") ? "yes" : "no"); f = 1 }
  $0 == "  probes             ok" { p = 1 } END { if (!f) print "none" }') first=$(_b19_line "$_b19go" "${_b19S}not compared with an earlier tree: no earlier run on another tree in this branch's history is recorded, so nothing was compared")"
rm -f "$_b19wc/pdir/p2" "$_b19wc/pdir/p3"; _b19_ci "$_b19wc" 'two fewer'
_b19_gate "$B19/gmem"
is "b19 A9: the first gate says its run was not compared with an earlier tree, and after two files are deleted the second says pfiles 3 members -> 1 members, 2 fewer" \
   "$_b19a | rc=$_b19grc changed=$(_b19_line "$_b19go" "${_b19S}changed since the last tree: pfiles 3 members -> 1 members, 2 fewer than on the last tree")" \
   "rc=0 ok=yes counts=yes first=yes | rc=0 changed=yes"
is "b19 A10: that second gate has a surfaces nothing probes line naming frontend" \
   "$(printf '%s\n' "$_b19go" | LC_ALL=C awk -v p="${_b19S}surfaces nothing probes: " 'index($0, p) == 1 {
      n = split(substr($0, length(p) + 1), a, ", "); for (i = 1; i <= n; i++) if (a[i] == "frontend") f = 1 }
      END { print (f ? "names frontend" : "no such line names frontend") }')" "names frontend"
{ printf 'present\t-\t-\tls -1 WIDGET.txt\ttest -f WIDGET.txt\n'; printf 'blindrow\t-\t-\tls -1 nothing-here.rs\ttest -f WIDGET.txt\n'; } > "$_b19wp/probes.tsv"
_b19_gate "$B19/gmem2"
_b19a=no; LC_ALL=C grep -q probes "$B19/gmem2/widget/mistakes.log" 2>/dev/null && _b19a=yes
is "b19 A11 (control): a blind row still prints probes FAIL, exits 1 and is recorded under probes" \
   "fail=$(_b19_in "$_b19go" '  probes             FAIL') rc=$_b19grc recorded=$_b19a" "fail=yes rc=1 recorded=yes"

_b19w2="$B19R/wck2"; _b19_files "$_b19w2" WIDGET.txt pdir/p1 pdir/p2 pdir/p3; printf 'widget\n' > "$_b19w2/.felix"; _b19_repo "$_b19w2"
_b19w2="$(cd "$_b19w2" && pwd -P)"
printf 'pfiles\t-\t-\tls -1 pdir\ttest -d pdir\n' > "$_b19wp/probes.tsv"
mkdir -p "$B19/gmem3/widget"; _b19_mem="$B19/gmem3"
_b19_cli "$_b19w2" probes >/dev/null
_b19_git "$_b19w2" worktree add -q -b b19side "$B19R/wck2w" main
_b19_files "$B19R/wck2w" pdir/p4 pdir/p5; _b19_ci "$B19R/wck2w" 'two more on a side branch'
_b19_rec "$_b19wp" "$B19R/wck2w"
_b19_mem=""
_b19_files "$_b19w2" README.md; _b19_ci "$_b19w2" readme
_b19_mem="$B19/gmem3"; _b19o="$(_b19_cli "$_b19w2" probes)"; _b19_mem=""
is "b19 A22: felix probes after a side branch recorded more files reads no fewer or more than on the last tree for pfiles" \
   "$(printf '%s\n' "$_b19o" | LC_ALL=C awk 'index($0, "fewer than on the last tree") || index($0, "more than on the last tree")')" ""
for _b19i in probes.tsv capabilities; do
  rm -rf "$_b19wp/$_b19i"; [ ! -e "$B19/widget-$_b19i.keep" ] && [ ! -L "$B19/widget-$_b19i.keep" ] || cp -pR "$B19/widget-$_b19i.keep" "$_b19wp/$_b19i"
done

# ---- F: the fact log's baseline (A12 to A21) -------------------------------------------------------------
_b19g="$B19R/g"; _b19_files "$_b19g" pdir/p1 pdir/p2 pdir/p3; _b19_repo "$_b19g" m; _b19g="$(cd "$_b19g" && pwd -P)"
_b19pg="$B19/b19g"; mkdir -p "$_b19pg" "$MEM/b19g"; printf 'pfiles\t-\t-\tls -1 pdir\ttest -d pdir\n' > "$_b19pg/probes.tsv"
_b19lg="$(_b19_log "$_b19pg")"
_b19_rec "$_b19pg" "$_b19g"
is "b19 A12: a run recorded in a clean checkout has 12 fields, its HEAD in field 10 and clean in field 12" \
   "$(LC_ALL=C awk -F'\t' '{ print NF "|" $10 "|" $12 }' "$_b19lg" 2>/dev/null | LC_ALL=C sort -u | paste -sd' ' -)" \
   "12|$(git -C "$_b19g" rev-parse HEAD 2>/dev/null)|clean"
is "b19 A12 (control): and the probe stays in field 8" \
   "$(LC_ALL=C awk -F'\t' '{ print $8 }' "$_b19lg" 2>/dev/null | LC_ALL=C sort -u | paste -sd' ' -)" "ls -1 pdir"

_b19pi="$B19/b19id"; mkdir -p "$_b19pi" "$MEM/b19id"; cp "$_b19pg/probes.tsv" "$_b19pi/probes.tsv"
_b19a="$B19R/wa"; _b19_git "$_b19g" worktree add -q -b b19a "$_b19a" main
( _fx_cd "$B19R" && git clone -q "$_b19g" k ) >/dev/null 2>&1
_b19nr="$B19R/nr"; _b19_files "$_b19nr" pdir/p1
_b19_rec "$_b19pi" "$_b19g"; _b19_rec "$_b19pi" "$_b19a"; _b19_rec "$_b19pi" "$_b19a"; _b19_rec "$_b19pi" "$B19R/k"
_b19_files "$_b19g" pdir/p4; _b19_rec "$_b19pi" "$_b19g"; rm -f "$_b19g/pdir/p4"
_b19_rec "$_b19pi" "$_b19nr"
_b19v="$(LC_ALL=C awk -F'\t' '{ n[NR] = NF; i[NR] = $11; d[NR] = $12; c[NR] = $10 }
  END { s = "rows " NR; for (r = 1; r <= NR; r++) if (n[r] != 12) s = s ", row " r " has " n[r] " fields"
        s = s ", A " ((i[2] != "" && i[2] == i[3]) ? "same twice" : "[" i[2] "] then [" i[3] "]")
        s = s ", G and A " (i[1] != i[2] ? "differ" : "the same") ", G and K " (i[1] != i[4] ? "differ" : "the same")
        print s ", G with p4 " d[5] ", no repository " c[6] " " i[6] " " d[6] }' "$(_b19_log "$_b19pi")" 2>/dev/null)"
is "b19 A13: field 11 is one identity per checkout, differing for a worktree and a clone; an untracked file makes field 12 dirty; no repository gives - - -" \
   "$_b19v" "rows 6, A same twice, G and A differ, G and K differ, G with p4 dirty, no repository - - -"

_b19c="$B19R/wc"; _b19_git "$_b19g" worktree add -q -b b19c "$_b19c" main
_b19_files "$_b19c" pdir/p4 pdir/p5; _b19_ci "$_b19c" c; _b19_rec "$_b19pg" "$_b19c"
rm -f "$_b19a/pdir/p2" "$_b19a/pdir/p3"; _b19_ci "$_b19a" a
_b19x="pfiles${_b19T}3 members${_b19T}1 members${_b19T}2 fewer than on the last tree"
is "b19 A14: the four-argument drift at a commit that deleted two files reads against the run on its own history, not a side branch's later run" \
   "$(_b19_d4 "$_b19pg" "$_b19a")" "$_b19x"
is "b19 A21 (control): the three-argument drift in the same worktree still reads the side branch's run, 5 members -> 1, as today" \
   "$(_b19_d3 "$_b19pg" "$_b19a")" "pfiles${_b19T}5 members${_b19T}1 members${_b19T}4 fewer than on the last tree"

_b19b="$B19R/wb"; _b19_git "$_b19g" worktree add -q -b b19b "$_b19b" main
is "b19 A15: a clean worktree at the recorded run's own tree gets exactly one row: no earlier run on another tree in this branch's history" \
   "$(_b19_d4 "$_b19pg" "$_b19b")" "-${_b19T}-${_b19T}-${_b19T}no earlier run on another tree in this branch's history is recorded, so nothing was compared"

_b19d="$B19R/wd"; _b19_git "$_b19g" worktree add -q -b b19d "$_b19d" main; _b19_files "$_b19d" pdir/p4; _b19_rec "$_b19pg" "$_b19d"
_b19e="$B19R/we"; _b19_git "$_b19g" worktree add -q -b b19e "$_b19e" main; _b19_files "$_b19e" README.md; _b19_ci "$_b19e" e
is "b19 A16: another checkout's dirty run is not the baseline, so a README commit has no pfiles row" \
   "$(_b19_d4 "$_b19pg" "$_b19e" | LC_ALL=C awk -F'\t' '$1 == "pfiles"')" ""
_b19_files "$_b19e" pdir/p4; _b19_rec "$_b19pg" "$_b19e"; _b19_ci "$_b19e" e2
is "b19 A17 (control): a checkout's own dirty run is its baseline once committed, so there is no pfiles row" \
   "$(_b19_d4 "$_b19pg" "$_b19e" | LC_ALL=C awk -F'\t' '$1 == "pfiles"')" ""
_b19v="$(LC_ALL=C awk -F'\t' -v OFS='\t' 'NR == 1 { $2 = "oldtree"; $6 = "9"; print $1, $2, $3, $4, $5, $6, $7, $8, $9 }' "$_b19lg" 2>/dev/null)"
[ -z "$_b19v" ] || printf '%s\n' "$_b19v" >> "$_b19lg"
is "b19 A18: a 9-field run appended last never becomes the baseline" "$(_b19_d4 "$_b19pg" "$_b19a")" "$_b19x"

_b19u="$B19R/u"; _b19_files "$_b19u" pdir/p1; _b19_git "$_b19u" init -q -b main
is "b19 A19: a checkout with no commit gets exactly one row: no commit to place the run on" \
   "$(_b19_dt "$_b19pg" "$_b19u" untree)" "-${_b19T}-${_b19T}-${_b19T}this checkout has no commit to place the run on, so nothing was compared"
has "b19 A20 (control): an empty tree id with four arguments still says no tree id" "$(_b19_dt "$_b19pg" "$_b19a" '')" "no tree id"
# <<< b19-omission-surfaces-and-drift
