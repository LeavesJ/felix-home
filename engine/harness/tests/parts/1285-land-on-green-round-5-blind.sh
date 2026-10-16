# >>> land-on-green-round-5
printf '\nland on green: the amendments A23-A25 (contract A23-A25, blind)\n'
# Blind, from the contract's "Amended after the fourth review" alone, on the
# fixture parts 1280-1284 build: lib/green-tick.sh, lib/green-install.sh,
# felix_land and cmd_land were not read. lib/resolve.sh's
# felix_accepted_deploy_diff and felix_deploy_diff were, for what A24 calls
# residue. What the contract leaves open is not asserted: a row's words beyond
# the path it names, and what the trampoline writes when its A24 check fails.
# A25's watchdog fires after 30 minutes and the contract gives no seam that
# shortens that, so A25 is skipped, as A4's and A15's watchdog halves are.
#
# The home's felix stub logs every call it gets to log/felix.log and its
# session-start hook to log/hook.log, so "no home code runs" is both logs
# holding no install, gate or session-start line.
L5="$LG/round5"; mkdir -p "$L5"
_fx_git "$LGH" fetch -q origin >/dev/null 2>&1; _fx_git "$LGH" checkout -q main >/dev/null 2>&1
_fx_git "$LGH" reset -q --hard refs/remotes/origin/main >/dev/null 2>&1
L5V="$(_l3_mainv)"; [ -n "$L5V" ] && _lg_cache "$L5V"
is "the land fixture: the home is on main at origin's main, nothing under its engine/ is untracked or ignored, no index entry is flagged, and main's check accepts its entry (fixture control)" \
   "$(git -C "$LGH" rev-parse HEAD 2>&1)|$(git -C "$LGH" ls-files --others -- engine 2>&1 | wc -l | tr -d ' ')|$(git -C "$LGH" ls-files -v 2>&1 | LC_ALL=C grep -c '^[abcdefghijklmnopqrstuvwxyzS]')|$(_l4_acc refs/remotes/origin/main)" \
   "$(git -C "$LGO" rev-parse main 2>&1)|0|0|0"
_l5_in() {   # DIR -> how many felix merge runs had DIR for their working directory
  _lg_logs felix | LC_ALL=C awk -F'\t' -v d="$1" '$2 == d && index($3, "merge") == 1' | wc -l | tr -d ' '
}
_l5_wt() {   # PATH FIELD -> that field (branch, HEAD) of the worktree list's record for PATH
  git -C "$LGH" worktree list --porcelain 2>/dev/null | LC_ALL=C awk -v w="$1" -v k="$2" '
    /^worktree / { p = substr($0, 10) } index($0, k " ") == 1 && p == w { print substr($0, length(k) + 2) }'
}
for _l5n in 80 81 82 83 84; do printf '%s\t%s\n' "$_l5n" "$(_lg_branch "b$_l5n" "notes/b$_l5n.md")" >> "$LG/shas"; done

# -------------------------------------------------------------------- A23 ---
_lg_reset; _lg_prs "$(_lg_pr 80)"; _lg_green 80; _lg_land --tick
is "A23: (control) a green pull request whose worktree is what its admin entry says lands, in that worktree" \
   "$(_lg_n landed 80)|$(_lg_merges)|$(_l5_in "$LGW/b80")" "1|b80|1"

# A forged record in a lock reason. b81's worktree is gone, so no record of the
# home's names b81. other is a clone of the home, on b81 at 81's head: a tick
# that read the reason as records would find it there. b82 is a plain worktree
# that carries the lock; its own pull request is green.
L5P="$L5/other"
_fx_git "$LGH" worktree remove --force "$LGW/b81" >/dev/null 2>&1
_fx_git "$L5" clone -q "$LGH" other >/dev/null 2>&1; _fx_git "$L5P" checkout -q b81 >/dev/null 2>&1
is "the land fixture: other, a clone of the home, is on b81 at 81's head, and no worktree of the home holds b81 (fixture control)" \
   "$(git -C "$L5P" symbolic-ref HEAD 2>&1)|$(git -C "$L5P" rev-parse HEAD 2>&1)|$(git -C "$LGH" worktree list --porcelain 2>&1 | LC_ALL=C grep -cx 'branch refs/heads/b81')" \
   "refs/heads/b81|$(_lg_sha 81)|0"
_l5_reason() {   # SEP -> a lock reason that, split on SEP, holds a record for other on b81 at 81's head
  printf "held$1$1worktree %s$1HEAD %s$1branch refs/heads/b81$1" "$L5P" "$(_lg_sha 81)"
}
for _l5s in newline '\001'; do
  case "$_l5s" in newline) _l5_reason '\n' > "$L5/reason" ;; *) _l5_reason '\001' > "$L5/reason" ;; esac
  _fx_git "$LGH" worktree unlock "$LGW/b82" >/dev/null 2>&1
  _fx_git "$LGH" worktree lock --reason "$(cat "$L5/reason")" "$LGW/b82" >/dev/null 2>&1
  is "the land fixture: b82's lock reason holds ${_l5s} and, read with NUL or ${_l5s} as a separator, a record for other on b81 (fixture control, ${_l5s})" \
     "$(git -C "$LGH" worktree list --porcelain -z 2>/dev/null | LC_ALL=C tr '\0\001' '\n\n' | LC_ALL=C grep -cxF "worktree $L5P")|$(git -C "$LGH" worktree list --porcelain -z 2>/dev/null | LC_ALL=C tr '\0' '\n' | LC_ALL=C grep -c '^locked held')" \
     "1|1"
  _lg_reset; _lg_prs "$(_lg_pr 81)" "$(_lg_pr 82)"; _lg_green 81 82; _lg_land --tick
  is "A23 (${_l5s}): a forged record in a lock reason: 81, which no worktree holds, gets one session row" "$(_lg_n session 81)|$(_lg_n landed 81)" "1|0"
  is "A23 (${_l5s}): and felix merge never runs in the checkout the forged record names" "$(_l5_in "$L5P")" "0"
  is "A23 (${_l5s}): the locked worktree's own green pull request still lands, in its worktree" \
     "$(_lg_n landed 82)|$(_lg_merges)|$(_l5_in "$LGW/b82")" "1|b82|1"
  _fx_git "$LGH" worktree add -q "$LGW/b81" b81 >/dev/null 2>&1
  _lg_reset; _lg_prs "$(_lg_pr 81)"; _lg_green 81; _lg_land --tick
  is "A23 (${_l5s}): with b81's own worktree back, 81 lands there, and never in the checkout the forged record names" \
     "$(_lg_n landed 81)|$(_l5_in "$LGW/b81")|$(_l5_in "$L5P")" "1|1|0"
  _fx_git "$LGH" worktree remove --force "$LGW/b81" >/dev/null 2>&1
done
_fx_git "$LGH" worktree unlock "$LGW/b82" >/dev/null 2>&1; rm -rf "$L5P"

# A worktree directory whose contents were swapped: b83's directory now holds
# x83's checkout, a branch at the same commit, and x83's directory b83's. The
# list still says b83's directory is on b83 at its head.
_fx_git "$LGH" worktree add -q -b x83 "$L5/x83" b83 >/dev/null 2>&1
/bin/mv "$LGW/b83" "$L5/swap"; /bin/mv "$L5/x83" "$LGW/b83"; /bin/mv "$L5/swap" "$L5/x83"
is "the land fixture: the list says b83's directory is on b83 at 83's head; the directory says x83, at the same commit (fixture control)" \
   "$(_l5_wt "$LGW/b83" branch)|$(_l5_wt "$LGW/b83" HEAD)|$(git -C "$LGW/b83" symbolic-ref HEAD 2>&1)|$(git -C "$LGW/b83" rev-parse HEAD 2>&1)" \
   "refs/heads/b83|$(_lg_sha 83)|refs/heads/x83|$(_lg_sha 83)"
_lg_reset; _lg_prs "$(_lg_pr 83)"; _lg_green 83; _lg_land --tick
is "A23: a worktree directory that now has another branch checked out than its admin entry says gives one session row" "$(_lg_n session 83)" "1"
is "A23: and felix merge runs nowhere" "$(_lg_merges)|$(_lg_n landed 83)" "|0"
/bin/mv "$LGW/b83" "$L5/swap"; /bin/mv "$L5/x83" "$LGW/b83"; /bin/mv "$L5/swap" "$L5/x83"
_fx_git "$LGH" worktree remove --force "$L5/x83" >/dev/null 2>&1; _fx_git "$LGH" branch -q -D x83 >/dev/null 2>&1

# A worktree directory that belongs to another repository: b84's directory is
# set aside, and a clone of the home on b84 at 84's head takes its place.
/bin/mv "$LGW/b84" "$L5/b84.real"
_fx_git "$LGW" clone -q "$LGH" b84 >/dev/null 2>&1; _fx_git "$LGW/b84" checkout -q b84 >/dev/null 2>&1
is "the land fixture: the list says b84's directory is on b84 at 84's head, and so does the directory, whose git common dir is its own (fixture control)" \
   "$(_l5_wt "$LGW/b84" branch)|$(_l5_wt "$LGW/b84" HEAD)|$(git -C "$LGW/b84" symbolic-ref HEAD 2>&1)|$(git -C "$LGW/b84" rev-parse HEAD 2>&1)|$(git -C "$LGW/b84" rev-parse --path-format=absolute --git-common-dir 2>&1)" \
   "refs/heads/b84|$(_lg_sha 84)|refs/heads/b84|$(_lg_sha 84)|$LGW/b84/.git"
_lg_reset; _lg_prs "$(_lg_pr 84)"; _lg_green 84; _lg_land --tick
is "A23: a worktree directory that belongs to another repository gives one session row" "$(_lg_n session 84)" "1"
is "A23: and felix merge runs nowhere" "$(_lg_merges)|$(_lg_n landed 84)" "|0"
rm -rf "$LGW/b84"; /bin/mv "$L5/b84.real" "$LGW/b84"
_lg_reset; _lg_prs "$(_lg_pr 84)"; _lg_green 84; _lg_land --tick
is "A23: (control) with its own directory back, 84 lands there" "$(_lg_n landed 84)|$(_l5_in "$LGW/b84")" "1|1"

# -------------------------------------------------------------------- A24 ---
# A deploy is made owed by taking main's entry out of the cache. 80 is a green
# candidate throughout, so "nothing merges" has something to refuse.
_l5_nohome() {   # WHAT -> no home code ran: no install, gate or session-start, no call to the home's felix
  is "A24: $1: no home code runs: the home's felix is never called, nothing runs install or gate, session-start never runs" \
     "$(_lg_logs felix | LC_ALL=C awk -F'\t' -v h="$LGH/engine/harness/felix" '$1 == h || index($3, "install") == 1 || index($3, "gate") == 1' | wc -l | tr -d ' ')|$(_lg_cnt hook)|$(_lg_cnt edited)" \
     "0|0|0"
}
_l5_dep() {   # WHAT WORD... -> one tick with a deploy owed: one deploy-owed row naming the path, paused, nothing run
  local what="$1"; shift
  rm -rf "$LGV/$L5V"; _lg_reset; _lg_prs "$(_lg_pr 80)"; _lg_green 80; _lg_land --tick
  is "A24: $what: the tick writes one deploy-owed row, and no deployed or deployed-unverified row" \
     "$LGRC|$(_lg_n deploy-owed)|$(_lg_n deployed)|$(_lg_n deployed-unverified)" "0|1|0|0"
  _la_names "A24: $what: the deploy-owed row names the path" "$(_lg_f deploy-owed "" 7)" "$@"
  [ -s "$LAND/paused" ] && ok "A24: $what: and writes paused" || bad "A24: $what: and writes paused" "no paused"
  _l5_nohome "$what"
  is "A24: $what: nothing is installed into the cache, and nothing merges" "$([ -e "$LGV/$L5V" ] && echo installed)|$(_lg_merges)" "|"
}
_l5_clean() {   # -> the home's index unflagged and its engine/ and projects/lgh/ as main has them
  local f
  for f in engine/harness/lib/core.sh engine/harness/felix projects/lgh/CLAUDE.md; do
    _fx_git "$LGH" update-index --no-assume-unchanged "$f" >/dev/null 2>&1
    _fx_git "$LGH" update-index --no-skip-worktree "$f" >/dev/null 2>&1
  done
  _fx_git "$LGH" checkout -q -- engine projects/lgh >/dev/null 2>&1
  rm -f "$LGH/engine/harness/a24-untracked.txt" "$LGH/engine/harness/a24-ignored.txt" "$LGH/engine/harness/.gitignore"
}
_l5_quiet() {   # WHAT -> git status sees nothing in the home (fixture control)
  is "the land fixture: git status --porcelain shows nothing in the home, $1 (fixture control)" "$(git -C "$LGH" status --porcelain 2>&1)" ""
}

rm -rf "$LGV/$L5V"; _lg_reset; _lg_land --tick
is "A24: (control) a clean home deploys: one install, session-start run, one deployed row, no deploy-owed row" \
   "$(_lg_ninst)|$([ "$(_lg_cnt hook)" -ge 1 ] && echo ran)|$(_lg_n deployed)|$(_lg_n deploy-owed)" "1|ran|1|0"

printf 'core a24 edited\n' > "$LGH/engine/harness/lib/core.sh"
_fx_git "$LGH" update-index --assume-unchanged engine/harness/lib/core.sh >/dev/null 2>&1
_l5_quiet "an edited engine file under assume-unchanged"
_l5_dep "an edited engine file under assume-unchanged" engine/harness/lib/core.sh
_l5_clean

# skip-worktree on the home's own felix, edited to log to log/edited.log first.
_l5e='printf '"'"'edited %s\n'"'"' "$*" >> "$LG/log/edited.log"'
LC_ALL=C awk -v e="$_l5e" 'NR == 3 { print e } { print }' "$LGH/engine/harness/felix" > "$L5/felix.edited" \
  && cat "$L5/felix.edited" > "$LGH/engine/harness/felix"
_fx_git "$LGH" update-index --skip-worktree engine/harness/felix >/dev/null 2>&1
is "the land fixture: the home's felix, edited, logs to edited.log, and its index entry carries skip-worktree (fixture control)" \
   "$(LC_ALL=C grep -c 'edited.log' "$LGH/engine/harness/felix" 2>&1)|$(git -C "$LGH" ls-files -v -- engine/harness/felix 2>&1 | cut -c1)" "1|S"
_l5_quiet "an edited engine file under skip-worktree"
_l5_dep "an edited engine file under skip-worktree" engine/harness/felix
_l5_clean

printf '# lgh, edited\n' > "$LGH/projects/lgh/CLAUDE.md"
_fx_git "$LGH" update-index --assume-unchanged projects/lgh/CLAUDE.md >/dev/null 2>&1
_l5_quiet "an edited projects/lgh/ file under assume-unchanged"
_l5_dep "an edited projects/lgh/ file under assume-unchanged" projects/lgh/claude.md
_l5_clean

for _l5f in assume-unchanged:h skip-worktree:S; do
  _l5l="${_l5f#*:}"; _l5f="${_l5f%%:*}"
  _fx_git "$LGH" update-index "--$_l5f" engine/harness/lib/core.sh >/dev/null 2>&1
  is "the land fixture: core.sh carries $_l5f and is as main has it (fixture control)" \
     "$(git -C "$LGH" ls-files -v -- engine/harness/lib/core.sh 2>&1 | cut -c1)|$(_fx_git "$LGH" hash-object engine/harness/lib/core.sh 2>&1)" \
     "$_l5l|$(git -C "$LGH" rev-parse refs/remotes/origin/main:engine/harness/lib/core.sh 2>&1)"
  _l5_dep "an unedited engine file under $_l5f" engine/harness/lib/core.sh
  _l5_clean
done

printf 'not main\n' > "$LGH/engine/harness/a24-untracked.txt"
_l5_dep "an untracked file under engine/" a24-untracked
_l5_clean

printf 'a24-ignored.txt\n' > "$LGH/engine/harness/.gitignore"; printf 'not main\n' > "$LGH/engine/harness/a24-ignored.txt"
is "the land fixture: the file is ignored, and only the untracked .gitignore beside it shows in git status (fixture control)" \
   "$(git -C "$LGH" status --porcelain 2>&1 | tr '\n' '|')|$(git -C "$LGH" check-ignore engine/harness/a24-ignored.txt 2>&1)" \
   "?? engine/harness/.gitignore||engine/harness/a24-ignored.txt"
_l5_dep "an ignored file under engine/, with an untracked .gitignore beside it" a24-ignored .gitignore
_l5_clean

is "the land fixture: the home is clean again: git status shows nothing, no index entry is flagged, nothing under engine/ is untracked or ignored (fixture control)" \
   "$(git -C "$LGH" status --porcelain 2>&1)|$(git -C "$LGH" ls-files -v 2>&1 | LC_ALL=C grep -c '^[abcdefghijklmnopqrstuvwxyzS]')|$(git -C "$LGH" ls-files --others -- engine 2>&1 | wc -l | tr -d ' ')" \
   "|0|0"
rm -rf "$LGV/$L5V"; _lg_reset; _lg_land --tick
is "A24: (control) once the home is clean again, the owed deploy runs and writes deployed" "$(_lg_n deployed)|$(_lg_ninst)" "1|1"
_lg_cache "$L5V"

# The trampoline. A branch's install left a stray file in main's entry. An
# untracked .gitignore in the home's engine/harness that ignores it makes main's
# own check call the stray residue: A24 checks for that file before A1 runs.
_lg_reset; _lg_land --install; _lg_reset; _la_tramp
is "A24: (control) with nothing untracked under the home's engine/, the trampoline runs main's entry's felix land --tick" \
   "$(_la_ticks)|$(_lg_logs felix | LC_ALL=C awk -F'\t' '$3 == "land --tick" { print $1 }')" "1|$LGV/$L5V/harness/felix"
printf 'not main\n' > "$LGH/engine/harness/a24-untracked.txt"; _lg_reset; _la_tramp
is "A24: with an untracked file under the home's engine/, the trampoline runs no felix land --tick" "$(_la_ticks)" "0"
_l5_clean
printf 'stray\n' > "$LGV/$L5V/harness/a24-stray.sh"
is "the land fixture: with a stray in main's entry, main's check rejects it (fixture control)" "$(_l4_acc refs/remotes/origin/main)" "1"
printf 'a24-stray.sh\n' > "$LGH/engine/harness/.gitignore"
is "the land fixture: an untracked .gitignore in the home that ignores the stray makes main's check accept that entry (fixture control)" \
   "$(_l4_acc refs/remotes/origin/main)" "0"
_lg_reset; _la_tramp
is "A24: with an untracked .gitignore under the home's engine/ that makes main's check accept a stray, the trampoline runs no felix land --tick" \
   "$(_la_ticks)" "0"
_l5_clean; _lg_cache "$L5V"; _lg_reset; _la_tramp
is "A24: (control) with the home clean and main's entry in place again, the trampoline runs its tick" "$(_la_ticks)" "1"
_lg_reset; _lg_land --uninstall

# -------------------------------------------------------------------- A25 ---
skip "A25: the watchdog sends TERM to the tick's pid before its descendants" "the contract gives no way to shorten 30 minutes"
skip "A25: the watchdog never signals its own pid or its own process group" "the contract gives no way to shorten 30 minutes"

for _l5n in 80 82 83 84; do _fx_git "$LGH" worktree remove --force "$LGW/b$_l5n" >/dev/null 2>&1; done
_fx_git "$LGH" worktree prune >/dev/null 2>&1; _fx_git "$LGH" branch -q -D b80 b81 b82 b83 b84 >/dev/null 2>&1
_lg_reset
