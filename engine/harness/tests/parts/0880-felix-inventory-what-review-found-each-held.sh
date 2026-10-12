# ---- what review found --------------------------------------------------
# Three reviewers read the command against the spec and against real input.
# Each defect they found that is a defect in the command, not in the spec,
# is held here to the contract it broke, on a third repository built for it,
# so no assertion above changes its fixture. Each was seen failing on the
# command as it stood before the fix.
printf '\nfelix inventory: what review found, each held to the contract it broke\n'
IVW3="$IV/work3"; IVZ="$IVW3/gizmo"; IVZO="$IV/origin3.git"; IVZX="$IV/zx"; IVZD="$IV/decoy"
IVZC="$IVZ/.claude/worktrees"
IVGH2="$IV/gh2"; IVGH3="$IV/gh3"; IVSTUB2="$IV/stub2"; IVSTUB3="$IV/stub3"; IVSTUB4="$IV/stub4"
mkdir -p "$IVW3" "$IVZX" "$IVGH2" "$IVGH3" "$IVSTUB2" "$IVSTUB3" "$IVSTUB4" "$IV/tq" "$IV/tz"
_ivzwt() { _ivg -C "$IVZ" worktree add -q "$@"; }
# E for an ASCII path, whatever the locale.
_ivenc() { printf '%s' "$1" | LC_ALL=C sed 's/[^A-Za-z0-9-]/-/g'; }

# ---- gizmo: main, then a worktree or branch per finding -----------------
_ivrepo "$IVZO" "$IVZ" acme/gizmo
_ivg -C "$IVZO" config uploadpack.allowFilter true
mkdir -p "$IVZ/src" "$IVZC/kept" "$IVZ/docs/handoff/pending"
printf 'gizmo\n' > "$IVZ/README.md"; printf 'shared copy, first\n' > "$IVZ/src/gate.txt"
printf 'node_modules/\n*.bak\n' > "$IVZ/.gitignore"; printf 'kept\n' > "$IVZC/kept/README"
printf '*.flt filter=mark\n' > "$IVZ/.gitattributes"; printf 'HELLO\n' > "$IVZ/src/f.flt"
printf '### the gizmo waits\n\n**Next:**\n- Build the gizmo.\n' > "$IVZ/docs/handoff/pending/20260924T000000Z-gizmo.md"
_ivwc "$IVZ" 'the first gizmo'; IVZ_C0="$(_ivg -C "$IVZ" rev-parse HEAD)"
_ivg -C "$IVZ" push -q origin main; _ivg -C "$IVZ" remote set-head origin main
printf '.lost/\n' >> "$IVZ/.git/info/exclude"
# A clean filter that leaves a mark and uppercases: the committed f.flt is
# its output, and wt-filter's lowercase copy cleans to it.
_ivzwt -b topic/filter "$IVZC/wt-filter" main; printf 'hello\n' > "$IVZC/wt-filter/src/f.flt"
# A listed worktree whose .git file is gone, holding a file no object has.
_ivzwt -b topic/q "$IVZC/wt-q" main
rm -f "$IVZC/wt-q/.git"; printf 'only here\n' > "$IVZC/wt-q/only-here.txt"; printf 'edited\n' >> "$IVZC/wt-q/README.md"
# A feature branch made with --track origin/main, pushed under its own name
# with an open pull request; another pushed with none; a local branch at
# main whose remote namesake has moved on.
_ivzwt --track -b topic/feat2 "$IVZC/wt-feat2" origin/main
printf 'feat2\n' > "$IVZC/wt-feat2/src/f2.txt"; _ivwc "$IVZC/wt-feat2" 'feat2 work'
_ivg -C "$IVZC/wt-feat2" push -q origin topic/feat2:topic/feat2; IVZ_F2="$(_ivg -C "$IVZC/wt-feat2" rev-parse HEAD)"
_ivg -C "$IVZ" branch -q --track topic/feat3 origin/main
_ivc "$IVZ" "$IVZ_C0" 'feat3 work' src/f3.txt 'feat3'; _ivg -C "$IVZ" update-ref refs/heads/topic/feat3 "$IVC"
_ivg -C "$IVZ" push -q origin topic/feat3:topic/feat3
_ivg -C "$IVZ" branch -q --no-track topic/diverge main
_ivc "$IVZ" "$IVZ_C0" 'diverged elsewhere' src/dv.txt 'dv'; _ivg -C "$IVZ" push -q origin "$IVC:refs/heads/topic/diverge"
# A detached worktree whose HEAD moved on, by reset --soft, from the commit
# its index still holds.
_ivc "$IVZ" "$IVZ_C0" 'm3 first' src/m3.txt 'one'; IVZ_X1="$IVC"
_ivc "$IVZ" "$IVZ_X1" 'm3 second' src/m3b.txt 'two'; IVZ_X2="$IVC"
_ivzwt --detach "$IVZC/wt-m3" main
_ivg -C "$IVZC/wt-m3" checkout -q --detach "$IVZ_X1"; _ivg -C "$IVZC/wt-m3" reset -q --soft "$IVZ_X2"
# A changed file whose content an object already holds, though main's differs.
_ivc "$IVZ" "$IVZ_C0" 'a second copy' src/gate.txt 'shared copy, second'
_ivzwt -b topic/f2 "$IVZC/wt-f2" main; printf 'shared copy, second\n' > "$IVZC/wt-f2/src/gate.txt"
for _ivn in utf8 garbage tab clean; do _ivzwt -b "topic/$_ivn" "$IVZC/wt-$_ivn" main; done
mkdir -p "$IVZC/wt-clean/tmpdir-here"
# Orphans: a directory named with a glob character beside a tracked one; a
# plain directory whose node_modules the repository ignores; one whose only
# unique content is ignored; and two worktrees pruned from a directory no
# listed worktree is left in.
mkdir -p "$IVZC/k*" "$IVZC/plain/node_modules" "$IVZC/ign"
printf 'only in k star\n' > "$IVZC/k*/g.txt"
printf 'plain only\n' > "$IVZC/plain/a.txt"; printf 'module only\n' > "$IVZC/plain/node_modules/x.js"
printf 'gizmo\n' > "$IVZC/ign/seen.txt"; printf 'cache only\n' > "$IVZC/ign/cache.bak"
_ivzwt -b topic/g1 "$IVZ/.lost/g1" main; _ivzwt -b topic/g2 "$IVZ/.lost/g2" main
printf 'lost only\n' > "$IVZ/.lost/g1/lost.txt"
rm -rf "$IVZ/.git/worktrees/g1" "$IVZ/.git/worktrees/g2"
# Beside the clone: a non-ASCII path, a path whose record name Claude Code
# cuts at 200, and a path holding a line break that spells another
# repository's directory.
IVZ_JOSE="$IVW3/wt-jos$(printf '\303\251')"; _ivzwt -b topic/jose "$IVZ_JOSE" main
IVZ_L=""; for _ivn in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do IVZ_L="${IVZ_L}llllllllll"; done
IVZ_LONG="$IVW3/$IVZ_L"; _ivzwt -b topic/long "$IVZ_LONG" main
_ivg -c init.defaultBranch=main init -q "$IVZD"; printf 'decoy\n' > "$IVZD/x.txt"; _ivwc "$IVZD" 'the decoy'
IVZ_NL="$(printf '%s/nl\nworktree %s' "$IVW3" "$IVZD")"; _ivzwt --detach "$IVZ_NL" main
# Only now the filter, so no setup step above ran it.
_ivg -C "$IVZ" config filter.mark.clean "echo ran >> '$IVZX/filter-ran'; tr a-z A-Z"

# ---- gizmo's sessions ----------------------------------------------------
# A question whose note is cut inside a two-byte character; a newest session
# that is not JSON; a live one whose file name holds a tab; live ones in the
# non-ASCII and the long directory, filed where Claude Code files them; and
# a chip whose title holds a backslash.
_ivopen "$IVZC/wt-utf8" 5a5a5a5a-0000-4000-8000-000000000001
_au_say  "$(_ivago 32 iso)" 'describe it'
_ivx=""; for _ivn in 1 2 3 4 5 6 7 8 9 10; do _ivx="$_ivx$(printf '\303\251\303\251\303\251\303\251\303\251\303\251\303\251\303\251\303\251\303\251')"; done
_au_stop "$(_ivago 30 iso)" msg_z1 "$_ivx?"
_ivtouch "$_AU_F" 30
_ivopen "$IVZC/wt-garbage" 5b5b5b5b-0000-4000-8000-000000000001
printf 'not json\n{{{{\n\377\376 binary\n' >> "$_AU_F"; _ivtouch "$_AU_F" 30
_au_open "$(_ive "$IVZC/wt-tab")/$(printf 'we ird\tname').jsonl" 5c5c5c5c-0000-4000-8000-000000000001
_au_say  "$(_ivago 3 iso)" 'keep going'
_au_stop "$(_ivago 2 iso)" msg_z3 'Still going.'
_ivtouch "$_AU_F" 2
_au_open "$IVP/$(_ivenc "$IVW3")-wt-jos-/5d5d5d5d-0000-4000-8000-000000000001.jsonl" 5d5d5d5d-0000-4000-8000-000000000001
_au_say  "$(_ivago 3 iso)" 'keep going'
_au_stop "$(_ivago 2 iso)" msg_z4 'Still going.'
_ivtouch "$_AU_F" 2
IVZ_LE="$(_ivenc "$IVZ_LONG")"
_au_open "$IVP/${IVZ_LE:0:200}-z9k2p1/5e5e5e5e-0000-4000-8000-000000000001.jsonl" 5e5e5e5e-0000-4000-8000-000000000001
_au_say  "$(_ivago 3 iso)" 'keep going'
_au_stop "$(_ivago 2 iso)" msg_z5 'Still going.'
_ivtouch "$_AU_F" 2
_ivopen "$IVZ" 5f5f5f5f-0000-4000-8000-000000000001
_au_say  "$(_ivago 125 iso)" 'note the path work'
_ivchip  "$(_ivago 124 iso)" toolu_zb task_5f5f5f5f 'Title with C:\\path' 'Theta task: teach the path parser that a drive letter and a backslash begin an absolute path, and test it on three spellings of one path.'
_au_stop "$(_ivago 120 iso)" msg_z6 'Noted.'
_ivtouch "$_AU_F" 120

# ---- gh for gizmo --------------------------------------------------------
# The stand-in again, over gizmo's pull requests, and doing what gh does on
# its first run in a HOME: keep a device id under its state directory. A
# second has a list of 1000 pull requests, gh's limit here, none of them
# gizmo's branches'.
printf -v _ivx '[{"number":7001,"title":"Feat two","state":"OPEN","isDraft":false,"headRefName":"topic/feat2","headRefOid":"%s","baseRefName":"main","createdAt":"%s","updatedAt":"%s","mergedAt":null,"closedAt":null,"labels":[],"mergeable":"MERGEABLE","mergeStateStatus":"CLEAN","statusCheckRollup":[],"url":"u","author":{"login":"fixture"},"headRepositoryOwner":{"login":"acme"},"reviewDecision":""}]' \
  "$IVZ_F2" "$(_ivago 600 iso)" "$(_ivago 60 iso)"
printf '%s\n' "$_ivx" > "$IVGH2/prs.json"; printf '{}\n' > "$IVGH2/statuses.json"; printf '{}\n' > "$IVGH3/statuses.json"
LC_ALL=C awk 'BEGIN { printf "["; for (i = 1; i <= 1000; i++) printf "%s{\"number\":%d,\"title\":\"f\",\"state\":\"CLOSED\",\"isDraft\":false,\"headRefName\":\"filler/%d\",\"headRefOid\":\"%040d\",\"baseRefName\":\"main\",\"createdAt\":\"2026-01-01T00:00:00Z\",\"updatedAt\":\"2026-01-01T00:00:00Z\",\"mergedAt\":null,\"closedAt\":null,\"labels\":[],\"mergeable\":\"UNKNOWN\",\"mergeStateStatus\":\"UNKNOWN\",\"statusCheckRollup\":[],\"url\":\"u\",\"author\":{\"login\":\"f\"},\"headRepositoryOwner\":{\"login\":\"f\"},\"reviewDecision\":\"\"}", (i > 1 ? "," : ""), i, i, i; print "]" }' > "$IVGH3/prs.json"
for _ivn in 2 3; do
  eval "_ivd=\$IVGH$_ivn; _ivs=\$IVSTUB$_ivn"
  LC_ALL=C awk -v d="$_ivd" -v iv="$IV" 'NR == 2 { print "D='"'"'" d "'"'"'"; next } { print }
    NR == 3 { print "sd=\"${XDG_STATE_HOME:-$HOME/.local/state}/gh\"; case \"$sd\" in '"'"'" iv "'"'"'/*) [ -f \"$sd/device-id\" ] || { mkdir -p \"$sd\" && echo fixture-device > \"$sd/device-id\"; } ;; esac" }' \
    "$IVSTUB/gh" > "$_ivs/gh"
  chmod +x "$_ivs/gh"
done
# A gh that answers slowly, for a signal to arrive while it runs.
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s/gh-slow.log"\nsleep 4\necho "[]"\n' "$IV" > "$IVSTUB4/gh"; chmod +x "$IVSTUB4/gh"

# ---- two partial clones of gizmo ----------------------------------------
# Neither holds a blob. The first's remote can serve one; the second's
# cannot be reached.
_ivg clone -q --no-checkout --filter=blob:none "file://$IVZO" "$IV/pc1" 2>/dev/null
_ivg clone -q --no-checkout --filter=blob:none "file://$IVZO" "$IV/pc2" 2>/dev/null
_ivg -C "$IV/pc2" config remote.origin.url "file://$IV/nowhere.git"

# ---- the fixture holds what the assertions below say ---------------------
_ivfx=""
[ -e "$IVZX/filter-ran" ] && _ivfx="$_ivfx the filter already ran;"
[ -e "$IVZC/wt-q/.git" ] && _ivfx="$_ivfx wt-q still has its .git;"
_ivq -C "$IVZ" worktree list --porcelain | grep -q "^worktree $IVZD\$" || _ivfx="$_ivfx the line break does not spell the decoy;"
[ "$(_ivq -C "$IVZ" config branch.topic/feat2.merge)" = refs/heads/main ] || _ivfx="$_ivfx feat2 does not track main;"
[ "$(_ivq -C "$IVZ" rev-parse origin/topic/feat2)" = "$IVZ_F2" ] || _ivfx="$_ivfx feat2 is not pushed;"
_ivq -C "$IVZ" merge-base --is-ancestor origin/topic/diverge topic/diverge && _ivfx="$_ivfx origin/topic/diverge is behind the local branch;"
_ivq -C "$IVZC/wt-m3" diff-index --cached --quiet "$IVZ_X1" || _ivfx="$_ivfx wt-m3's index is not X1;"
[ "$(_ivq -C "$IVZC/wt-m3" rev-parse HEAD)" = "$IVZ_X2" ] || _ivfx="$_ivfx wt-m3's HEAD is not X2;"
_ivq -C "$IVZC/wt-m3" symbolic-ref -q HEAD >/dev/null && _ivfx="$_ivfx wt-m3 is not detached;"
_ivq -C "$IVZ" worktree list --porcelain | grep -q '\.lost/' && _ivfx="$_ivfx git still lists .lost;"
_ivq -C "$IVZ" ls-files -- "$IVZC/k*" | grep -q kept || _ivfx="$_ivfx k* does not glob to kept;"
[ "$(_ivq -C "$IV/pc1" config remote.origin.promisor)" = true ] || _ivfx="$_ivfx pc1 is no partial clone;"
# Asked with lazy fetching off, since asking would otherwise fetch it.
( export GIT_NO_LAZY_FETCH=1; _ivq -C "$IV/pc1" cat-file -e "$(_ivq -C "$IV/pc1" rev-parse origin/main:docs/handoff/pending/20260924T000000Z-gizmo.md)" ) 2>/dev/null \
  && _ivfx="$_ivfx pc1 already holds the section;"
[ -z "$_ivfx" ] && ok  "the fixture: gizmo holds each finding's shape, and neither partial clone holds the handoff section" \
                || bad "the fixture: gizmo holds each finding's shape, and neither partial clone holds the handoff section" "$_ivfx"

# ---- the runs ------------------------------------------------------------
_ivzrun() {  # [--path P] [--tmp D] [--cwd D] felix-args...
  local p="$IVSTUB2:$IVSTUB:$PATH" t="$IV/tz" d="$IVZ"
  while :; do
    case "${1:-}" in
      --path) p="$2"; shift 2 ;;
      --tmp)  t="$2"; shift 2 ;;
      --cwd)  d="$2"; shift 2 ;;
      *) break ;;
    esac
  done
  ( cd "$d" || exit 97
    unset FELIX_HOME FELIX_MEMORY FELIX_KERNEL FELIX_KERNEL_CACHE FELIX_PLUGIN_CACHE CLAUDE_PLUGIN_ROOT \
          CLAUDE_CONFIG_DIR GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OPTIONAL_LOCKS GIT_CEILING_DIRECTORIES \
          XDG_STATE_HOME XDG_CACHE_HOME FELIX_INVENTORY_TEMP_ROOTS
    export HOME="$IVH" TMPDIR="$t" PATH="$p" XDG_CONFIG_HOME="$IVH/.config" GIT_CONFIG_NOSYSTEM=1 \
           GIT_ALLOW_PROTOCOL=file GIT_TERMINAL_PROMPT=0 GIT_CEILING_DIRECTORIES="$IV"
    "$IVF" "$@" ) 2>>"$IV_ERR"
}
_ivz_snap() {
  local d
  for d in "$IVW3" "$IVZO" "$IVZD"; do
    ( cd "$d" && find . -print | LC_ALL=C sort && find . -type f -exec "$_iv_sum" {} + | LC_ALL=C sort ) 2>&1
  done
}
_ivz_before="$(_ivz_snap)"
_ivz_pack() { ( cd "$1/.git/objects" && find . -print | LC_ALL=C sort ); }
_ivz_pc1="$(_ivz_pack "$IV/pc1")"
: > "$IVGIT_LOG"; : > "$IV/gh-slow.log"
IVZ_T1="$IV/z1.tsv"; _ivzrun inventory --tsv --repo "$IVZ" > "$IVZ_T1"
IVZ_H2="$IV/z2.txt"; _ivzrun inventory --no-gh --repo "$IVZ" > "$IVZ_H2"
IVZ_T2NG="$IV/z2ng.tsv"; _ivzrun inventory --tsv --no-gh --repo "$IVZ" > "$IVZ_T2NG"
IVZ_T3="$IV/z3.tsv"; _ivzrun --path "$IVSTUB3:$IVSTUB:$PATH" inventory --tsv --repo "$IVZ" > "$IVZ_T3"
IVZ_T4="$IV/z4.tsv"; _ivzrun --tmp "$IVZC/wt-clean/tmpdir-here" inventory --tsv --no-gh --no-host --repo "$IVZ" > "$IVZ_T4"
IVZ_P1="$IV/p1.tsv"; _ivzrun --cwd "$IV/pc1" inventory --tsv --no-gh --no-host > "$IVZ_P1"
IVZ_P2="$IV/p2.tsv"; _ivzrun --cwd "$IV/pc2" inventory --tsv --no-gh --no-host > "$IVZ_P2"
# The rows of one ref, exactly.
_ivz_sel() { LC_ALL=C awk -F'\t' -v r="$2" '$3 == r' "$1" > "$IV/sel"; }
_ivz_chk() {  # name file ref mode arg
  _ivz_sel "$2" "$3"
  if _iv_q "$4" "$5"; then ok "$1"; else bad "$1" "$(_iv_diag)"; fi; }
_ivz_det() { LC_ALL=C awk -F'\t' -v e="$1" '$8 ~ e { f = 1 } END { exit !(NR && f) }' "$IV/sel"; }

# Filters (a clean filter is a program the repository's config runs; git-lfs
# stores what it is handed): none runs, and a path one would have cleaned is
# not called uncommitted on its raw bytes.
[ -s "$IVZ_T1" ] && [ ! -e "$IVZX/filter-ran" ] && ok "no clean filter the repository configures runs, in any run" \
  || bad "no clean filter the repository configures runs, in any run" "$(_ivrows "$IVZ_T1" "the filter left $(wc -l < "$IVZX/filter-ran" 2>/dev/null | tr -d ' ') marks")"
_ivz_sel "$IVZ_T1" "$IVZC/wt-filter"
if _iv_q lack uncommitted && _iv_q word 0:unknown; then ok "a worktree whose only changed-looking file sits under a clean filter is not called uncommitted, and says unknown"
else bad "a worktree whose only changed-looking file sits under a clean filter is not called uncommitted, and says unknown" "$(_iv_diag)"; fi
# Worktree paths: a line break spells no second worktree, and a directory git
# lists whose .git file is gone is read as what it is.
if [ -s "$IVZ_T1" ] && ! LC_ALL=C awk -F'\t' -v r="$IVZD" '$3 == r { f = 1 } END { exit !f }' "$IVZ_T1" \
   && ! grep -qF -- "-C $IVZD " "$IVGIT_LOG"; then ok "a worktree whose path holds a line break makes no row of the directory the break spells, and no git runs there"
else bad "a worktree whose path holds a line break makes no row of the directory the break spells, and no git runs there" "$(grep -F -- "$IVZD" "$IVZ_T1" "$IVGIT_LOG" | head -n 3 | tr '\t\n' '|;')"; fi
_ivz_chk "a listed worktree whose .git file is gone is an orphan of the repository, not the checkout around it" "$IVZ_T1" "$IVZC/wt-q" hold orphan
_ivz_chk "and it is not landed" "$IVZ_T1" "$IVZC/wt-q" lack landed
_ivz_chk "and its row says git marks it prunable" "$IVZ_T1" "$IVZC/wt-q" word 8:prunable
_ivz_chk "the main worktree does not count its linked worktrees' and orphans' files as its own changes" "$IVZ_T1" "$IVZ" lack uncommitted
# Branches: the default branch is told by name, and a remote branch ahead of
# its local namesake is read.
_ivz_chk "a worktree on a branch tracking origin/main, pushed under its own name with an open pull request, is pr-open" "$IVZ_T1" "$IVZC/wt-feat2" hold pr-open
_ivz_chk "and not landed" "$IVZ_T1" "$IVZC/wt-feat2" lack landed
_ivz_chk "a branch tracking origin/main, pushed under its own name with no pull request, is unproposed" "$IVZ_T1" topic/feat3 hold unproposed
_ivz_chk "a remote branch that moved on from its local namesake, content not on main and no pull request, has a row, unproposed" "$IVZ_T1" origin/topic/diverge hold unproposed
_ivz_chk "a detached worktree whose index holds an earlier HEAD's tree leads with hazard:staged-revert" "$IVZ_T1" "$IVZC/wt-m3" lead hazard:staged-revert
_ivz_sel "$IVZ_T1" "$IVZC/wt-f2"
if _iv_q hold uncommitted && _ivz_det ', 0 of them holding content in no object'; then ok "an uncommitted worktree whose changed file's content an object holds says none of its content is in no object"
else bad "an uncommitted worktree whose changed file's content an object holds says none of its content is in no object" "$(_iv_diag)"; fi
# Orphans.
_ivz_chk "a directory named with a glob character is an orphan, not hidden by the tracked directory its name globs to" "$IVZ_T1" "$IVZC/k*" lead orphan
_ivz_sel "$IVZ_T1" "$IVZC/plain"
if _iv_q lead orphan && _ivz_det '^1 of 1 files'; then ok "a plain directory's orphan count leaves out what the repository's ignore file ignores"
else bad "a plain directory's orphan count leaves out what the repository's ignore file ignores" "$(_iv_diag)"; fi
_ivz_sel "$IVZ_T1" "$IVZC/ign"
if _iv_q lead orphan && _ivz_det '(^|; )1 of 1 ignored files hold content in no object'; then ok "an orphan's ignored file whose content is in no object is counted, not passed over"
else bad "an orphan's ignored file whose content is in no object is counted, not passed over" "$(_iv_diag)"; fi
_ivz_chk "a worktree pruned from a directory where git lists no worktree any more is still an orphan" "$IVZ_T1" "$IVZ/.lost/g1" lead orphan
# The host's records.
_ivz_chk "a live session in a non-ASCII directory, filed as Claude Code files it, makes it live" "$IVZ_T1" "$IVZ_JOSE" hold live
_ivz_chk "a live session in a directory whose record name Claude Code cuts at 200 makes it live" "$IVZ_T1" "$IVZ_LONG" hold live
_ivz_sel "$IVZ_T1" "$IVZC/wt-tab"
if _iv_q hold live && _iv_q lack question && _iv_q lack blocked; then ok "a live session whose file name holds a tab is live, and neither a question nor blocked"
else bad "a live session whose file name holds a tab is live, and neither a question nor blocked" "$(_iv_diag)"; fi
_ivz_chk "a newest session that is not JSON says unknown, rather than passing as ended on no question" "$IVZ_T1" "$IVZC/wt-garbage" word 0:unknown
_ivz_chk "a question whose note is cut inside a character is still a question" "$IVZ_T1" "$IVZC/wt-utf8" hold question
if [ -s "$IVZ_T1" ] && iconv -f UTF-8 -t UTF-8 < "$IVZ_T1" > /dev/null 2>&1; then ok "and every --tsv byte is valid UTF-8"
else bad "and every --tsv byte is valid UTF-8" "$(_ivrows "$IVZ_T1" "iconv rejects it")"; fi
_iv_selstate "$IVZ_T1" chip-unstarted
if grep -qF 'Title with C:\path' "$IV/sel" && ! LC_ALL=C grep -q "$(printf '\001')" "$IV/sel"; then ok "a chip title's backslash prints as a backslash, with no control byte"
else bad "a chip title's backslash prints as a backslash, with no control byte" "$(_iv_diag | od -c | head -n 3 | tr '\n' ' ')"; fi
# What gh cannot say.
# Spec §4.3 rule 5 and §8: under --no-gh a pushed tip's not reads unknown, so
# the row is undecided with content not not or partly: counted, not listed.
# The count is the view's own: it equals the --tsv rows of the same reading
# that are undecided (an unknown: headline, or states - or live alone) with
# content neither not nor partly, so a view that drops feat3 uncounted fails.
_ivx="$(LC_ALL=C awk '/nothing decided but unknown [0-9]/ { sub(/.*nothing decided but unknown /, ""); print; exit }' "$IVZ_H2")"
_ivy="$(LC_ALL=C awk -F'\t' '$1 != "cover" { h = $4; sub(/,.*/, "", h); if ((h ~ /^unknown:/ || $4 == "-" || $4 == "live") && $7 != "not" && $7 != "partly") n++ } END { print n + 0 }' "$IVZ_T2NG")"
_ivz_sel "$IVZ_T2NG" topic/feat3
[ -s "$IVZ_H2" ] && ! grep -qF topic/feat3 "$IVZ_H2" && [ -n "$_ivx" ] && [ "$_ivx" = "$_ivy" ] \
  && LC_ALL=C awk -F'\t' '$7 == "unknown" && $4 ~ /^unknown:/ { f = 1 } END { exit !f }' "$IV/sel" \
  && ok "under --no-gh the human view counts a pushed branch whose content cannot be confirmed off main, rather than listing it" \
  || bad "under --no-gh the human view counts a pushed branch whose content cannot be confirmed off main, rather than listing it" "count [$_ivx] derived [$_ivy] row [$(_iv_diag)] $(grep -F topic/feat3 "$IVZ_H2" | head -n 2 | tr '\n' ';')$(tail -n 4 "$IVZ_H2" | tr '\n' ';')"
_ivz_sel "$IVZ_T3" topic/feat3
if _iv_q lack unproposed && _iv_q word 0:unknown; then ok "when gh lists its limit of pull requests, a pushed branch with none among them is unknown, not unproposed"
else bad "when gh lists its limit of pull requests, a pushed branch with none among them is unknown, not unproposed" "$(_iv_diag)"; fi
[ ! -e "$IVH/.local/state" ] && [ -s "$IVZ_T1" ] && ok "what gh keeps of its own lands in no file under HOME" \
  || bad "what gh keeps of its own lands in no file under HOME" "$(_ivrows "$IVZ_T1" "$(find "$IVH/.local" -type f 2>/dev/null | head -n 2 | tr '\n' ' ')")"
# Scratch, signals and here-documents.
_ivz_sel "$IVZ_T4" "$IVZC/wt-clean"
if _iv_q lack uncommitted && [ -z "$(ls -A "$IVZC/wt-clean/tmpdir-here")" ]; then ok "with TMPDIR inside a clean worktree, that worktree is not called uncommitted, and nothing is left there"
else bad "with TMPDIR inside a clean worktree, that worktree is not called uncommitted, and nothing is left there" "$(_iv_diag)"; fi
( cd "$IVZ" || exit 97; ulimit -c 0
  unset FELIX_HOME FELIX_MEMORY GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_CEILING_DIRECTORIES
  export HOME="$IVH" TMPDIR="$IV/tq" PATH="$IVSTUB4:$IVSTUB:$PATH" XDG_CONFIG_HOME="$IVH/.config" GIT_CONFIG_NOSYSTEM=1 \
         GIT_ALLOW_PROTOCOL=file GIT_TERMINAL_PROMPT=0 GIT_CEILING_DIRECTORIES="$IV"
  exec perl -e '$SIG{QUIT} = "DEFAULT"; $SIG{INT} = "DEFAULT"; exec @ARGV or exit 127' "$IVF" inventory --tsv --no-host --repo "$IVZ" ) > /dev/null 2>&1 &
_ivzq=$!; _ivn=0
while [ ! -s "$IV/gh-slow.log" ] && [ "$_ivn" -lt 600 ] && kill -0 "$_ivzq" 2>/dev/null; do sleep 0.2; _ivn=$((_ivn + 1)); done
_ivx="$(ls -A "$IV/tq" | tr '\n' ' ')"
kill -QUIT "$_ivzq" 2>/dev/null; wait "$_ivzq" 2>/dev/null; _ivzqr=$?
if [ ! -s "$IV/gh-slow.log" ]; then bad "a QUIT mid-run leaves no scratch behind" "gh was never reached, so no signal was sent (rc $_ivzqr)"
elif [ -z "$_ivx" ]; then bad "a QUIT mid-run leaves no scratch behind" "no scratch was there to leave while gh ran"
else is "a QUIT mid-run leaves no scratch behind" "$(ls -A "$IV/tq" | tr '\n' ' ')" ""; fi
_iv_heredoc() { _ivcode "$IVLIB" "$IVLIBH" ${IVPARTS[@]+"${IVPARTS[@]}"} | grep -E '<<-?[[:space:]]*[A-Za-z_"'"'"']|<<<' | _ivwhere 'a here-document'; }
is  "no library feeds anything from a here-document or here-string, which bash 3.2 writes to a file outside the scratch" "$(_iv_heredoc)" ""
# Partial clones: nothing fetched, and what could not be read is unknown.
[ -s "$IVZ_P1" ] && [ "$(_ivz_pack "$IV/pc1")" = "$_ivz_pc1" ] && ok "reading a partial clone fetches nothing into it" \
  || bad "reading a partial clone fetches nothing into it" "$(_ivrows "$IVZ_P1" "$(diff <(printf '%s\n' "$_ivz_pc1") <(_ivz_pack "$IV/pc1") | head -n 4 | tr '\n' ';')")"
_iv_selstate "$IVZ_P2" handoff-pending
if [ -s "$IV/sel" ] && ! grep -qF 'no Next lines' "$IV/sel"; then ok "a pending section a partial clone cannot read is not said to have no Next lines"
else bad "a pending section a partial clone cannot read is not said to have no Next lines" "$(_iv_diag)"; fi
_ivz_after="$(_ivz_snap)"
[ -s "$IVZ_T1" ] && [ "$_ivz_after" = "$_ivz_before" ] && ok "no file under gizmo, its origin or the decoy changed across these runs" \
  || bad "no file under gizmo, its origin or the decoy changed across these runs" "$(diff <(printf '%s\n' "$_ivz_before") <(printf '%s\n' "$_ivz_after") | head -n 6 | tr '\n' ';')"
_ivx="$(grep -E 'bad substitution|syntax error|unbound variable|command not found|invalid option|not a valid identifier|division by 0|awk: |Permission denied' "$IV_ERR" | head -n 3 | tr '\n' ';')"
is  "no run wrote a shell or awk error to stderr, nor a failed redirection" "$_ivx" ""

