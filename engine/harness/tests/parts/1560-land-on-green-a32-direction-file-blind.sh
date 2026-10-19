# >>> land-on-green-a32
printf '\nland on green A32: docs/direction.md is a direction document (blind)\n'
# Blind, from the contract's G5, A3 and A32 alone (docs/2026-10-15-land-on-green-contract.md,
# A32 committed ebdeeff6), 2026-10-19. Not read: lib/green-tick.sh, lib/pr-status*.sh,
# lib/land*.sh, or any diff of them. How to drive the tick was learned from
# tests/lib/land-on-green.sh and parts 1280 and 1282, and how to drive the stuck-PR
# page from tests/lib/stuck-pr.sh and part 1310.
#
# Both fixtures are built by their own builders, _lg_build and _sp_build, into a
# directory of this part's own, $TMP/a32, and removed at the end, so the land and
# stuck-PR fixtures the serial run shares are never touched, whatever state the
# parts before this one left them in, and the part runs alone. The shared land
# fixture's variables are put back as they were found.
#
# Where the contract is open, the strictest reading is taken:
#   - "one founder row" is one founder row and no other row for that pull request
#     in the tick, and a second tick writes no second one, as A6 has it for the
#     two patterns ("exactly as for the two patterns");
#   - a path that is not a direction document "by this rule" is held to two
#     things: no founder row, and the same outcome as an ordinary docs file in
#     the same fixture, which lands; no other rule in this fixture names any of
#     those paths;
#   - a rename "to or away from the path" (A3) is a real git rename on a branch
#     cut from main, with gh naming only the new path, as gh does and as part 1282
#     builds a roadmap's; for "away", main first holds docs/direction.md;
#   - the stuck-PR page "names the path as a direction document": the pull
#     request is in state founder, needs founder, and its detail holds the word
#     direction outside the path itself, which is the rule name the page gives a
#     roadmap (part 1310, case 27); a detail that only echoes docs/direction.md
#     does not pass. The page folds case as the tick does ("Every reader of G5's
#     rule sees the same answer"), so Docs/Direction.md is held there too.

# ---- this part's own fixtures ------------------------------------------------
_a32d="$TMP/a32"; rm -rf "${_a32d:?}"; mkdir -p "$_a32d"
_a32_vars="LG LGO LGH LGW LGC LGM LGU LGB LGK LGL LAND LGE LGV LGRC LA LATR _lgn"
_a32_had=""
for _a32k in $_a32_vars; do
  if eval "[ \"\${$_a32k+set}\" = set ]"; then eval "_a32_was_$_a32k=\"\$$_a32k\""; _a32_had="$_a32_had $_a32k"; fi
  unset "$_a32k"
done
_a32_lgx=(${LGX[@]+"${LGX[@]}"}); LGX=()
_a32_tmp="$TMP"; TMP="$_a32d"; _lg_build base; TMP="$_a32_tmp"

_a32_br() { printf '%s\t%s\n' "$1" "$(_lg_branch "b$1" "${@:2}")" >> "$LG/shas"; }   # N FILE... -> branch bN, its head in shas
_a32_br 560 docs/a32-notes.md
_a32_br 561 docs/direction.md
_a32_br 562 docs/direction.md notes/a32-562.md
_a32_br 563 Docs/Direction.md
_a32_br 564 DOCS/direction.MD
_a32_br 565 docs/direction-notes.md
_a32_br 566 docs/old/direction.md
_a32_br 567 notes/docs/direction.md
_a32_br 568 projects/x/docs/direction.md
_a32_br 569 projects/lgh/CLAUDE.md
_a32_br 570 docs/a32-roadmap.md
_a32_br 571 docs/direction-roadmap.md
_a32_br 572 notes/a32-572.md
_a32o=""
for _a32k in 560 561 562 563 564 565 566 567 568 569 570 571 572; do
  _a32s="$(_lg_sha "$_a32k")"
  case "$_a32s" in *[!0123456789abcdef]*|"") _a32o="$_a32o $_a32k" ;; *) [ "${#_a32s}" -eq 40 ] || _a32o="$_a32o $_a32k" ;; esac
done
is "land A32: every pull request this part adds has a commit for its head (fixture control)" "$_a32o" ""

_a32_tick() {   # N PATH... -> one tick over pull request N alone, green, gh listing PATH... as its files
  local n="$1"; shift
  _lg_reset; _lg_prs "$(_lg_pr "$n")"; _lg_green "$n"; printf '%s\n' "$@" > "$LGK/files.$n"; _lg_land --tick
}
_a32_events() { [ -f "$LAND/ledger.tsv" ] || return 0   # N -> the events of the ledger rows naming pull request N
  LC_ALL=C awk -F'\t' -v p="$1" '$3 == p { printf "%s%s", s, $2; s = " " }' "$LAND/ledger.tsv"; }
_a32_held() {   # N WHAT PATH... -> one tick: N is held with one founder row and never handed to felix merge
  local n="$1" what="$2"; shift 2
  _a32_tick "$n" "$@"
  is "land A32: $what is held with one founder row" "$(_lg_n founder "$n")" "1"
  is "land A32: $what is never handed to felix merge" "$(_lg_merges)|$(_lg_n landed "$n")" "|0"
}
_a32_free() {   # N PATH -> one tick: no founder row, and it proceeds as the ordinary docs file did
  _a32_tick "$1" "$2"
  is "land A32: $2 is not a direction document: no founder row" "$(_lg_n founder "$1")" "0"
  is "land A32: a pull request touching only $2 proceeds as the ordinary docs file did: it lands" \
     "$(_lg_n landed "$1")|$(_lg_merges)" "1|b$1"
}

# ---- the control: an ordinary docs file lands --------------------------------
_a32_tick 560 docs/a32-notes.md
is "land A32: a pull request touching only an ordinary docs file lands, and nothing holds it (fixture control)" \
   "$LGRC|$(_lg_n founder 560)|$(_lg_n landed 560)|$(_lg_merges)" "0|0|1|b560"

# ---- docs/direction.md is a direction document ------------------------------
_a32_tick 561 docs/direction.md
is "land A32: a pull request touching only docs/direction.md gets one founder row" "$(_lg_n founder 561)" "1"
is "land A32: that founder row is the only row the tick writes for it" "$(_a32_events 561)" "founder"
is "land A32: a pull request touching only docs/direction.md is never handed to felix merge" \
   "$(_lg_merges)|$(_lg_n landed 561)" "|0"
_lg_osa 'with title "Felix: founder #561"' "land A32: the founder row for docs/direction.md is sent titled Felix: founder #561"
_lg_land --tick
is "land A32: a second tick over the same pull request writes no second founder row" "$(_lg_n founder 561)|$(_lg_merges)" "1|"
is "land A32: and sends no second notification for it" "$(_lg_logs osa | grep -c 'Felix: founder #561')" "1"

_a32_held 562 "a pull request touching docs/direction.md beside an ordinary file" docs/direction.md notes/a32-562.md

_lg_reset; _lg_prs "$(_lg_pr 572)" "$(_lg_pr 561)"; _lg_green 561 572
printf 'docs/direction.md\n' > "$LGK/files.561"; printf 'notes/a32-572.md\n' > "$LGK/files.572"; _lg_land --tick
is "land A32: a tick that holds docs/direction.md goes on, and lands only the next candidate" \
   "$(_lg_n founder 561)|$(_lg_n landed 561)|$(_lg_n landed 572)|$(_lg_merges)" "1|0|1|b572"

# ---- after A3's case fold -----------------------------------------------------
_a32_held 563 "a pull request touching Docs/Direction.md (case folded)" Docs/Direction.md
_a32_held 564 "a pull request touching DOCS/direction.MD (case folded)" DOCS/direction.MD

# ---- the exact path: these are not direction documents by this rule ----------
_a32_free 565 docs/direction-notes.md
_a32_free 566 docs/old/direction.md
_a32_free 567 notes/docs/direction.md
_a32_free 568 projects/x/docs/direction.md

# ---- the two patterns are unchanged -------------------------------------------
_a32_held 569 "projects/*/CLAUDE.md, unchanged: a pull request touching projects/lgh/CLAUDE.md" projects/lgh/CLAUDE.md
_a32_held 570 "docs/*roadmap*, unchanged: a pull request touching docs/a32-roadmap.md" docs/a32-roadmap.md
_a32_held 571 "a pull request touching docs/direction-roadmap.md, by the roadmap pattern though not the exact path," \
  docs/direction-roadmap.md

# ---- renames, to and away (A3) -----------------------------------------------
# To: main holds notes/a32-direction-draft.md, and branch b573 renames it to
# docs/direction.md. gh names only the new path.
_l3_commit notes/a32-direction-draft.md draft
_fx_git "$LGH" worktree add -q -b b573 "$LGW/b573" main >/dev/null 2>&1; mkdir -p "$LGW/b573/docs"
_fx_git "$LGW/b573" mv notes/a32-direction-draft.md docs/direction.md >/dev/null 2>&1
_fx_git "$LGW/b573" -c user.name=t -c user.email=t@t commit -qm b573 >/dev/null 2>&1
printf '573\t%s\n' "$(git -C "$LGW/b573" rev-parse HEAD 2>/dev/null)" >> "$LG/shas"
is "land A32: branch b573 renames notes/a32-direction-draft.md to docs/direction.md against main (fixture control)" \
   "$(git -C "$LGW/b573" diff --no-color --name-status -M main...HEAD 2>&1 | LC_ALL=C tr '\t' ' ')" \
   "R100 notes/a32-direction-draft.md docs/direction.md"
_a32_held 573 "a pull request that renames a file to docs/direction.md" docs/direction.md
# Away: main now holds docs/direction.md, and branch b574 renames it to
# notes/a32-old-direction.md. gh names only the new path.
_l3_commit docs/direction.md direction
_fx_git "$LGH" worktree add -q -b b574 "$LGW/b574" main >/dev/null 2>&1; mkdir -p "$LGW/b574/notes"
_fx_git "$LGW/b574" mv docs/direction.md notes/a32-old-direction.md >/dev/null 2>&1
_fx_git "$LGW/b574" -c user.name=t -c user.email=t@t commit -qm b574 >/dev/null 2>&1
printf '574\t%s\n' "$(git -C "$LGW/b574" rev-parse HEAD 2>/dev/null)" >> "$LG/shas"
is "land A32: origin's main holds docs/direction.md, and branch b574 renames it away (fixture control)" \
   "$(git -C "$LGH" cat-file -t origin/main:docs/direction.md 2>&1)|$(git -C "$LGW/b574" diff --no-color --name-status -M main...HEAD 2>&1 | LC_ALL=C tr '\t' ' ')" \
   "blob|R100 docs/direction.md notes/a32-old-direction.md"
_a32_held 574 "a pull request that renames docs/direction.md away, gh naming only the new path," notes/a32-old-direction.md

# ---- the stuck-PR page names the path as a direction document -----------------
# One gh answer, in descending order as gh lists it, read once with --prs --tsv
# in a stuck-PR fixture of this part's own. The page runs in a subshell so that
# fixture's variables never reach the shared one's; the assertions read the
# page it saved.
( TMP="$_a32d/sp"; mkdir -p "$TMP" || exit 97
  unset SP SPH SPR SPLIST
  _sp_build
  _sp_prs fixture_home \
    "$(_sp_pr 166 projects/x/docs/direction.md:0 green)" \
    "$(_sp_pr 165 docs/direction-notes.md:0 green)" \
    "$(_sp_pr 164 docs/a32-roadmap.md:0 green)" \
    "$(_sp_pr 163 notes/a32-163.md:0 green)" \
    "$(_sp_pr 162 Docs/Direction.md:0 green)" \
    "$(_sp_pr 161 docs/direction.md:0 green)"
  _sp_land "$SPH" --prs --tsv
  cp "$SPX/out" "$_a32d/page.tsv"; printf '%s\n' "$SPRC" > "$_a32d/page.rc" ) >/dev/null 2>&1
_a32p="$_a32d/page.tsv"
_a32_unpath() { printf '%s' "$1" | LC_ALL=C sed 's#[Dd][Oo][Cc][Ss]/[Dd][Ii][Rr][Ee][Cc][Tt][Ii][Oo][Nn]\.[Mm][Dd]##g'; }
is "land A32, page: felix land --prs --tsv runs over this part's fixture and exits 0 (fixture control)" \
   "$(cat "$_a32d/page.rc" 2>/dev/null)|$(_sp_prn "$_a32p")" "0|6"
_sp_is "land A32, page: a plain path (fixture control)" "$_a32p" 163 ready lander
_sp_is "land A32, page: docs/a32-roadmap.md (fixture control)" "$_a32p" 164 founder founder
has "land A32, page: the roadmap's detail names it a direction document (fixture control)" "$(_sp_f "$_a32p" 164 8)" "direction"
_sp_is "land A32, page: docs/direction.md" "$_a32p" 161 founder founder
has "land A32, page: the detail names docs/direction.md a direction document, beyond echoing the path" \
    "$(_a32_unpath "$(_sp_f "$_a32p" 161 8)")" "direction"
_sp_is "land A32, page: Docs/Direction.md, case folded" "$_a32p" 162 founder founder
has "land A32, page: the detail names Docs/Direction.md a direction document, beyond echoing the path" \
    "$(_a32_unpath "$(_sp_f "$_a32p" 162 8)")" "direction"
_sp_not "land A32, page: docs/direction-notes.md is not founder by this rule" "$_a32p" 165 founder
_sp_not "land A32, page: projects/x/docs/direction.md is not founder by this rule" "$_a32p" 166 founder

# ---- this part's fixtures are taken away, and the shared names put back --------
rm -rf "${_a32d:?}"
for _a32k in $_a32_vars; do unset "$_a32k"; done
for _a32k in $_a32_had; do eval "$_a32k=\"\$_a32_was_$_a32k\""; unset "_a32_was_$_a32k"; done
LGX=(${_a32_lgx[@]+"${_a32_lgx[@]}"})
unset _a32_lgx _a32_had _a32_tmp _a32o _a32p _a32k _a32s
# <<< land-on-green-a32
