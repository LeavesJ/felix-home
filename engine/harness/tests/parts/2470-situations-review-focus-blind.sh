printf '\n%s\n' 'situations: the review focus (blind)'
# Blind, written on 2026-10-31 from docs/2026-10-29-capability-lane-first-slices-design.md (sections 3, 4, 7, 10 and
# 11) and the slice 1 plan's Contracts and Review Focus (C1 to C16) alone, at the spec commit 21df057c merged with main,
# before lib/situations.sh existed, without reading lib/, hooks/, bin/ or felix. Felix is run as a black box, and every
# fixture is built here (C13); nothing comes from tests/lib/lane-fixture.sh. C14 pins the review focus, RF1 to RF7, and
# each item's assertions begin "2470 rf1" to "2470 rf7". Every run is C13's: ( cd C && env FELIX_HOME=H FELIX_MEMORY=M
# TMPDIR=T felix situations ... ), T fresh and empty, the network stubs first on PATH and the four keys unset.
#
# Readings where the Contracts leave room:
# - Every run also gets HOME, an empty directory (RF6's names its own), and has GIT_CONFIG_GLOBAL, GIT_CONFIG_SYSTEM,
#   GIT_CONFIG_NOSYSTEM and XDG_CONFIG_HOME unset, so the person's own git config reaches no run and RF6's does.
# - A tree id a header prints is read from the facts.log that felix probes writes for a clean checkout of that commit,
#   under a memory root of its own (C3.3: the scratch tree id equals it).
# - RF1's explicit range is HEAD~1..HEAD. The default range is read in the human report (its header), the explicit one
#   in --tsv. The unchanged state also holds each worktree's git ls-files -s and git status --porcelain (C3.4), read
#   with GIT_OPTIONAL_LOCKS=0; the marker is touched a second after the last fixture write and a second before the runs.
# - RF2's --at names the tree felix probes recorded.
# - RF3's --at reads a hand-written facts.log (C13), tree rf3-tree. The run under LANG=$LCB_U8 also unsets every other
#   LC_* variable, so LANG decides. The order of a_c before ab is asserted under both locales.
# - RF4 starts felix through perl, which also starts a session of its own (so nothing felix sends its process group can
#   reach the suite) and resets TERM and HUP as well as INT. The wait for the probe stops when felix has exited, and a
#   felix still running 30 s after the signal is killed with KILL and reaped; so on an engine without the command, RF4
#   costs no wait.
# - RF5's obligations.tsv exists before --propose, holding one admitted row of another name. The printed admit command
#   is run only when it begins "printf '" and names git -C '<H>' add, and with HOME an empty directory and
#   GIT_CONFIG_NOSYSTEM=1 beside C14's identity, so no hook of the person's own config runs.
# - RF6: with core.hooksPath set, git never runs a template's hook, so the control (a plain clone under that HOME,
#   folded into the assertions so that none passes without the command) asserts the template was copied, and the
#   hooksPath hook and the smudge filter ran.
# - RF7's W1 and W2 are both linked worktrees of one repository, W1 at its root commit and W2 one commit ahead.

S2470_D="$TMP/s2470"
rm -rf "$S2470_D"; mkdir -p "$S2470_D/bin" "$S2470_D/user"
S2470_D="$(cd -P -- "$S2470_D" && pwd -P)"
S2470_NET="$S2470_D/network.log"; : > "$S2470_NET"
for _s2470_c in gh curl wget ssh nc claude; do
  printf '#!/bin/sh\nprintf '"'"'%%s %%s\\n'"'"' %s "$*" >> '"'"'%s'"'"'\nexit 1\n' "$_s2470_c" "$S2470_NET" > "$S2470_D/bin/$_s2470_c"
  chmod +x "$S2470_D/bin/$_s2470_c"
done
S2470_U="$S2470_D/user"; S2470_L=""
S2470_CBM='prototype=INFO,internal=ADVISORY,public-beta=TASK_BLOCKING,production=RELEASE_BLOCKING'
S2470_SRC='cite:0123456789ab'
S2470_HDR='scratch checkout, tracked content only, current probes.tsv'
S2470_NOTAT='detector not run: this checkout is not at this tree'
S2470_PSVC=$'svc\tsvc\t-\tcat svc.txt\ttest -f svc.txt\n'
S2470_O1='an entry in the owed list for every svc line'

# DIR -> DIR removed if there and made again, empty; S2470_P its physical path.
_s2470_dir() { rm -rf "$1" && mkdir -p "$1" && S2470_P="$(cd -P -- "$1" && pwd -P)"; }
# FIELDS... -> the fields joined by tabs, with no newline.
_s2470_tab() { local IFS=$'\t'; printf '%s' "$*"; }
# CLASS PROJECT -> S2470_ID, the class's id as C6 computes it.
_s2470_id() { S2470_ID="owed:$(printf '%s\t%s\t%s' "$1" "$2" '*' | git hash-object --stdin | cut -c1-12)"; }
# DIR TIME ARGS... -> git ARGS in DIR through _fx_git, with no global or system config, no hooks, identity t, both dates
# TIME (epoch seconds, UTC).
_s2470_g() {
  local d="$1" t="$2"
  shift 2
  ( export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.invalid \
      GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.invalid GIT_AUTHOR_DATE="$t +0000" GIT_COMMITTER_DATE="$t +0000"
    _fx_git "$d" -c commit.gpgsign=false -c core.hooksPath=/dev/null -c core.autocrlf=false "$@" ) > /dev/null 2>&1
}
# DIR TIME MESSAGE -> everything in DIR committed.
_s2470_commit() { _s2470_g "$1" "$2" add -A && _s2470_g "$1" "$2" commit -q -m "$3"; }
# DIR PROJECT -> git init -q -b main in DIR, and a .felix naming PROJECT, for the caller to commit.
_s2470_repo() { mkdir -p "$1" && _s2470_g "$1" 1793000000 init -q -b main && printf '%s\n' "$2" > "$1/.felix"; }
# HOME PROJECT PROBES -> C13's home: project.json, CLAUDE.md, and probes.tsv holding the bytes PROBES.
_s2470_home() {
  mkdir -p "$1/projects/$2" &&
    printf '{"name":"%s","remote_match":"example.invalid/%s","gate":"true"}\n' "$2" "$2" > "$1/projects/$2/project.json" &&
    printf '# %s\n' "$2" > "$1/projects/$2/CLAUDE.md" &&
    printf '%s' "$3" > "$1/projects/$2/probes.tsv"
}
# DIR -> a copy of the engine at DIR/harness (C13), its situations.tsv holding only the comment line; S2470_E its felix.
_s2470_engine() {
  S2470_E="$1/harness/felix"
  mkdir -p "$1" && cp -R "$FROOT/harness" "$1/harness" &&
    printf '# class\tapplies\towes\tclass_by_maturity\tsource\n' > "$1/harness/templates/situations.tsv"
}
# DIR CLASS APPLIES OWES -> one row of the substituted table of the engine at DIR.
_s2470_row() { printf '%s\t%s\t%s\t%s\t%s\n' "$2" "$3" "$4" "$S2470_CBM" "$S2470_SRC" >> "$1/harness/templates/situations.tsv"; }
# OUT DIR HOME MEMORY ENGINE ARGS... -> ENGINE ARGS run in DIR as C13 runs it, TMPDIR the fresh empty directory OUT.t;
# OUT.out, OUT.err, and S2470_RC its exit. S2470_U is the run's HOME; S2470_L is C, u8 or empty (the locale as it is).
_s2470_run() {
  local o="$1" d="$2" h="$3" m="$4" e="$5"
  local -a le
  shift 5
  rm -rf "$o.t"; mkdir -p "$o.t"
  case "$S2470_L" in
    C)  le=(LC_ALL=C) ;;
    u8) le=(-u LC_ALL -u LC_COLLATE -u LC_CTYPE -u LC_MESSAGES -u LC_NUMERIC -u LC_TIME -u LC_MONETARY LANG="$LCB_U8") ;;
    *)  le=(-u S2470_NONE) ;;
  esac
  ( cd "$d" && exec env -u ANTHROPIC_API_KEY -u OPENAI_API_KEY -u GH_TOKEN -u GITHUB_TOKEN -u CLAUDE_CODE_SESSION_ID \
      -u FELIX_HOME_DIR -u GIT_CONFIG_GLOBAL -u GIT_CONFIG_SYSTEM -u GIT_CONFIG_NOSYSTEM -u XDG_CONFIG_HOME "${le[@]}" \
      HOME="$S2470_U" PATH="$S2470_D/bin:$PATH" FELIX_HOME="$h" FELIX_MEMORY="$m" TMPDIR="$o.t" "$e" "$@" ) \
    > "$o.out" 2> "$o.err" < /dev/null
  S2470_RC=$?
}
# LOG -> S2470_STAMP and S2470_TREE of the newest recorded tree, as C3.1 reads it: the last line of 8 or more fields
# whose tree is not unknown-tree. Both empty when there is none.
_s2470_newest() {
  local x
  x="$(LC_ALL=C awk -F'\t' 'NF >= 8 && $2 != "unknown-tree" { s = $1; t = $2 } END { printf "%s\t%s", s, t }' "$1" 2>/dev/null)"
  S2470_STAMP="${x%%$'\t'*}"; S2470_TREE="${x#*$'\t'}"
}
# FILE SECTION -> the names of the row lines of SECTION in a human report, in order, joined by a space: the class of a
# class row, the name of a residual line (the third cell when the line is split at two spaces).
_s2470_names() {
  LC_ALL=C awk -v s="$2" '
    $0 == s { on = 1; next }
    on && $0 == "" { on = 0 }
    on && /^  [^ ]/ { n = split($0, a, "  "); if (n >= 3) { printf "%s%s", sep, a[3]; sep = " " } }
  ' "$1" 2>/dev/null
}
# REPO WORKTREE... -> the refs, the worktree list, each worktree's HEAD, symbolic HEAD, index and status, and the
# common config's bytes, read with GIT_OPTIONAL_LOCKS=0.
_s2470_snap() {
  local r="$1" w
  shift
  GIT_OPTIONAL_LOCKS=0 git -C "$r" for-each-ref 2>&1
  GIT_OPTIONAL_LOCKS=0 git -C "$r" worktree list --porcelain 2>&1
  for w in "$@"; do
    printf 'worktree %s\n' "$w"
    GIT_OPTIONAL_LOCKS=0 git -C "$w" rev-parse HEAD 2>&1
    GIT_OPTIONAL_LOCKS=0 git -C "$w" symbolic-ref -q HEAD 2>&1
    GIT_OPTIONAL_LOCKS=0 git -C "$w" ls-files -s 2>&1
    GIT_OPTIONAL_LOCKS=0 git -C "$w" status --porcelain 2>&1
  done
  cksum < "$r/.git/config" 2>&1
}

# ---- RF1: a linked worktree ---------------------------------------------------------------------------------------
# A repository whose main checkout R stands at c0 on main, and a linked worktree W, made with git worktree add, one
# commit ahead on feat, where svc.txt gains a line: svc_owed (probe:svc=found) is owed over it.
_s2470_dir "$S2470_D/rf1"; S2470_D1="$S2470_P"
_s2470_engine "$S2470_D1/x"; S2470_E1="$S2470_E"
_s2470_row "$S2470_D1/x" svc_owed 'probe:svc=found' "$S2470_O1"
_s2470_home "$S2470_D1/home" rf1 "$S2470_PSVC"
mkdir -p "$S2470_D1/mem/rf1" "$S2470_D1/mside/rf1"
S2470_R1="$S2470_D1/main"; S2470_W1="$S2470_D1/w"
_s2470_repo "$S2470_R1" rf1; printf 'a\n' > "$S2470_R1/svc.txt"
_s2470_commit "$S2470_R1" 1793000000 c0
_s2470_g "$S2470_R1" 1793000100 worktree add -q -b feat "$S2470_W1"
printf 'a\nb\n' > "$S2470_W1/svc.txt"
_s2470_commit "$S2470_W1" 1793000200 c1
S2470_C0="$(git -C "$S2470_R1" rev-parse HEAD 2>&1)"; S2470_C1="$(git -C "$S2470_W1" rev-parse HEAD 2>&1)"
_s2470_run "$S2470_D1/p0" "$S2470_R1" "$S2470_D1/home" "$S2470_D1/mside" "$S2470_E1" probes; S2470_PRC="$S2470_RC"
_s2470_newest "$S2470_D1/mside/rf1/facts.log"; S2470_TID0="$S2470_TREE"
_s2470_run "$S2470_D1/p1" "$S2470_W1" "$S2470_D1/home" "$S2470_D1/mside" "$S2470_E1" probes; S2470_PRC="$S2470_PRC $S2470_RC"
_s2470_newest "$S2470_D1/mside/rf1/facts.log"; S2470_TID1="$S2470_TREE"
S2470_B1="$(_s2470_snap "$S2470_R1" "$S2470_R1" "$S2470_W1")"
sleep 1; : > "$S2470_D1/marker"; sleep 1
_s2470_run "$S2470_D1/def" "$S2470_W1" "$S2470_D1/home" "$S2470_D1/mem" "$S2470_E1" situations --change; S2470_RA="$S2470_RC"
_s2470_run "$S2470_D1/rng" "$S2470_W1" "$S2470_D1/home" "$S2470_D1/mem" "$S2470_E1" situations --change HEAD~1..HEAD --tsv
S2470_RB="$S2470_RC"
S2470_NEW1="$(find "$S2470_R1" "$S2470_W1" -newer "$S2470_D1/marker" 2>&1)"
S2470_A1="$(_s2470_snap "$S2470_R1" "$S2470_R1" "$S2470_W1")"
S2470_X1="situations for rf1
  base  $S2470_C0  tree $S2470_TID0  $S2470_HDR
  head  $S2470_C1  tree $S2470_TID1  $S2470_HDR"
is "2470 rf1 felix situations --change from a linked worktree, with the default range, exits 0 with an empty stderr, its header naming the merge base with main and the worktree's HEAD, each with its tree id" \
   "$S2470_PRC|$S2470_RA|$(cat "$S2470_D1/def.err")|$(head -n 3 "$S2470_D1/def.out")" "0 0|0||$S2470_X1"
_s2470_id svc_owed rf1
is "2470 rf1 felix situations --change HEAD~1..HEAD --tsv from the linked worktree exits 0 and reads svc_owed owed over the worktree's own commit" \
   "$S2470_RB|$(cat "$S2470_D1/rng.err")|$(cat "$S2470_D1/rng.out")" \
   "0||$(_s2470_tab "$S2470_ID" svc_owed owed ACTIVE ACTIVE 'svc found (svc)' 'svc found (svc)' "$S2470_O1")"
is "2470 rf1 after both runs the refs, every worktree's HEAD, git worktree list --porcelain, each index and status, and the config's bytes are as they were" \
   "$S2470_RA|$S2470_RB|$S2470_A1" "0|0|$S2470_B1"
is "2470 rf1 after both runs nothing under the main checkout, the linked worktree or the common git directory is newer than a marker touched before them" \
   "$S2470_RA|$S2470_RB|$S2470_NEW1" "0|0|"

# ---- RF2: an untracked environment --------------------------------------------------------------------------------
# The probe grounding ready reads found only while .ready, ignored and untracked, is present; its witness is the tracked
# app.txt. So the live checkout reads it found, and a scratch clone, which holds tracked content only, reads it blind.
_s2470_dir "$S2470_D/rf2"; S2470_D2="$S2470_P"
S2470_O2='a readiness check before the service is used'
_s2470_engine "$S2470_D2/x"; S2470_E2="$S2470_E"
_s2470_row "$S2470_D2/x" env_ready 'probe:ready=found' "$S2470_O2"
_s2470_home "$S2470_D2/home" rf2 $'ready\tready\t-\ttest -f .ready && cat app.txt\ttest -f app.txt\n'
mkdir -p "$S2470_D2/mem/rf2"
S2470_C2="$S2470_D2/c"
_s2470_repo "$S2470_C2" rf2; printf '.ready\n' > "$S2470_C2/.gitignore"; printf 'route-a\n' > "$S2470_C2/app.txt"
_s2470_commit "$S2470_C2" 1793000000 c0
printf 'x\n' > "$S2470_C2/other.txt"
_s2470_commit "$S2470_C2" 1793000100 c1
printf 'ok\n' > "$S2470_C2/.ready"
_s2470_run "$S2470_D2/p" "$S2470_C2" "$S2470_D2/home" "$S2470_D2/mem" "$S2470_E2" probes; S2470_PRC="$S2470_RC"
_s2470_newest "$S2470_D2/mem/rf2/facts.log"
_s2470_run "$S2470_D2/at" "$S2470_C2" "$S2470_D2/home" "$S2470_D2/mem" "$S2470_E2" situations --at "$S2470_TREE" --tsv
S2470_RA="$S2470_RC"
_s2470_run "$S2470_D2/ch" "$S2470_C2" "$S2470_D2/home" "$S2470_D2/mem" "$S2470_E2" situations --change HEAD~1..HEAD --tsv
S2470_RB="$S2470_RC"
_s2470_id env_ready rf2
is "2470 rf2 after felix probes in the live checkout, whose ignored untracked .ready the probe needs, --at its tree reads env_ready ACTIVE, as standing" \
   "$S2470_PRC|$S2470_RA|$(cat "$S2470_D2/at.err")|$(cat "$S2470_D2/at.out")" \
   "0|0||$(_s2470_tab "$S2470_ID" env_ready standing - ACTIVE - 'ready found (ready)' "$S2470_O2")"
is "2470 rf2 --change HEAD~1..HEAD over a commit that does not touch the surface reads env_ready could-not-look, UNKNOWN at base and at head, never DORMANT, retired or none" \
   "$S2470_RB|$(LC_ALL=C awk -F'\t' '$2 == "env_ready" { print $3 " " $4 " " $5 }' "$S2470_D2/ch.out")" "0|could-not-look UNKNOWN UNKNOWN"
S2470_W2="the witness proves this surface exists and the probe exited 1"
is "2470 rf2 that --tsv is the class line, then could-not-look residual lines for base: and head:, each naming the term probe:ready=found and the probe's own sentence" \
   "$S2470_RB|$(cat "$S2470_D2/ch.err")|$(cat "$S2470_D2/ch.out")" \
   "0||$(_s2470_tab "$S2470_ID" env_ready could-not-look UNKNOWN UNKNOWN 'ready blind (ready)' 'ready blind (ready)' "$S2470_O2")
$(_s2470_tab residual could-not-look env_ready "base: probe:ready=found: ready read blind: $S2470_W2")
$(_s2470_tab residual could-not-look env_ready "head: probe:ready=found: ready read blind: $S2470_W2")"

# ---- RF3: the caller's locale -------------------------------------------------------------------------------------
# Classes ab and a_c, in that order in the table, both on probe:x=found, with owes that differ in case. In bytes a_c
# sorts before ab ('_' is 0x5f, 'b' 0x62); en_US.UTF-8 collation, which passes over the '_', puts ab first. Over c1,
# which removes list.txt while the witness's keep.txt stays, x reads found at base and blind at head: both blinded.
_s2470_dir "$S2470_D/rf3"; S2470_D3="$S2470_P"
_s2470_engine "$S2470_D3/x"; S2470_E3="$S2470_E"
_s2470_row "$S2470_D3/x" ab 'probe:x=found' 'Bound The AB Surface'
_s2470_row "$S2470_D3/x" a_c 'probe:x=found' 'bound the a_c surface'
_s2470_home "$S2470_D3/home" rf3 $'x\tx\t-\tcat list.txt\ttest -f keep.txt\n'
mkdir -p "$S2470_D3/mem/rf3"
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' 2026-10-29T12:00:00Z rf3-tree x - found 1 x 'cat list.txt' > "$S2470_D3/mem/rf3/facts.log"
S2470_C3="$S2470_D3/c"
_s2470_repo "$S2470_C3" rf3; printf 'kept\n' > "$S2470_C3/keep.txt"; printf 'one\n' > "$S2470_C3/list.txt"
_s2470_commit "$S2470_C3" 1793000000 c0
rm -f "$S2470_C3/list.txt"
_s2470_commit "$S2470_C3" 1793000100 c1
_locale_bytes_vars
S2470_N3_1="2470 rf3 --change --tsv prints the same bytes under LC_ALL=C and under LANG=en_US.UTF-8 with LC_ALL unset"
S2470_N3_2="2470 rf3 the --change human report prints the same bytes under LC_ALL=C and under LANG=en_US.UTF-8 with LC_ALL unset"
S2470_N3_3="2470 rf3 --at --tsv prints the same bytes under LC_ALL=C and under LANG=en_US.UTF-8 with LC_ALL unset"
S2470_N3_4="2470 rf3 the --at human report prints the same bytes under LC_ALL=C and under LANG=en_US.UTF-8 with LC_ALL unset"
S2470_N3_5="2470 rf3 in --change, under either locale, a_c and ab are both blinded, and a_c comes before ab in the blinded section and in the residual's could-not-look lines"
if [ -z "${LCB_U8:-}" ]; then
  skip "$S2470_N3_1" "$LCB_NONE"; skip "$S2470_N3_2" "$LCB_NONE"; skip "$S2470_N3_3" "$LCB_NONE"
  skip "$S2470_N3_4" "$LCB_NONE"; skip "$S2470_N3_5" "$LCB_NONE"
else
  for S2470_L in C u8; do
    _s2470_run "$S2470_D3/ct-$S2470_L" "$S2470_C3" "$S2470_D3/home" "$S2470_D3/mem" "$S2470_E3" situations --change HEAD~1..HEAD --tsv
    eval "S2470_RCT_$S2470_L=\$S2470_RC"
    _s2470_run "$S2470_D3/ch-$S2470_L" "$S2470_C3" "$S2470_D3/home" "$S2470_D3/mem" "$S2470_E3" situations --change HEAD~1..HEAD
    eval "S2470_RCH_$S2470_L=\$S2470_RC"
    _s2470_run "$S2470_D3/at-$S2470_L" "$S2470_C3" "$S2470_D3/home" "$S2470_D3/mem" "$S2470_E3" situations --at rf3-tree --tsv
    eval "S2470_RAT_$S2470_L=\$S2470_RC"
    _s2470_run "$S2470_D3/ah-$S2470_L" "$S2470_C3" "$S2470_D3/home" "$S2470_D3/mem" "$S2470_E3" situations --at rf3-tree
    eval "S2470_RAH_$S2470_L=\$S2470_RC"
  done
  S2470_L=""
  # NAME -> identical or different, for D3/NAME-C.out and D3/NAME-u8.out.
  _s2470_same() { cmp -s "$S2470_D3/$1-C.out" "$S2470_D3/$1-u8.out" && printf identical || printf different; }
  is "$S2470_N3_1" "$S2470_RCT_C|$S2470_RCT_u8|$(_s2470_same ct)" "0|0|identical"
  is "$S2470_N3_2" "$S2470_RCH_C|$S2470_RCH_u8|$(_s2470_same ch)" "0|0|identical"
  is "$S2470_N3_3" "$S2470_RAT_C|$S2470_RAT_u8|$(_s2470_same at)" "0|0|identical"
  is "$S2470_N3_4" "$S2470_RAH_C|$S2470_RAH_u8|$(_s2470_same ah)" "0|0|identical"
  is "$S2470_N3_5" \
     "$S2470_RCH_C|$(_s2470_names "$S2470_D3/ch-C.out" blinded)|$(_s2470_names "$S2470_D3/ch-C.out" residual)|$S2470_RCH_u8|$(_s2470_names "$S2470_D3/ch-u8.out" blinded)|$(_s2470_names "$S2470_D3/ch-u8.out" residual)" \
     "0|a_c ab|a_c ab|0|a_c ab|a_c ab"
fi

# ---- RF4: an interrupted run and an early close -------------------------------------------------------------------
# The probe grounding s, at head only (where slow.txt is tracked), touches $TMPDIR/started and sleeps 3 s; a side's
# probes run with TMPDIR <scratch>/tmp-<side> (C3.3).
_s2470_dir "$S2470_D/rf4"; S2470_D4="$S2470_P"
_s2470_engine "$S2470_D4/x"; S2470_E4="$S2470_E"
_s2470_row "$S2470_D4/x" slow 'probe:s=found' 'a bound on how long the slow surface may run'
_s2470_home "$S2470_D4/home" rf4 \
  "$(printf '%s\t%s\t%s\t%s\t%s' s s - 'if test -f slow.txt; then touch "$TMPDIR/started"; sleep 3; fi; cat list.txt' 'test -f list.txt')
"
mkdir -p "$S2470_D4/mem/rf4"
S2470_C4="$S2470_D4/c"
_s2470_repo "$S2470_C4" rf4; printf 'one\n' > "$S2470_C4/list.txt"
_s2470_commit "$S2470_C4" 1793000000 c0
printf 'yes\n' > "$S2470_C4/slow.txt"
_s2470_commit "$S2470_C4" 1793000100 c1
# SIGNAL -> felix situations --change HEAD~1..HEAD started in the background in C4, through a perl that starts a session
# and resets INT, TERM and HUP to their defaults; SIGNAL sent to felix once the head side's probe has started (polled
# for at most 30 s, and no longer than felix runs), and felix reaped by its pid (KILL after 30 s more). S2470_SIG holds
# started or not started, the exit, and TMPDIR's entries as soon as felix exited; S2470_SIG4 the same 4 s later.
_s2470_sig() {
  local t="$S2470_D4/$1.t" pid n=0 st="not started" f rc now later
  rm -rf "$t"; mkdir -p "$t"
  ( cd "$S2470_C4" && exec perl -e 'use POSIX (); POSIX::setsid(); $SIG{INT} = q(DEFAULT); $SIG{TERM} = q(DEFAULT); $SIG{HUP} = q(DEFAULT); exec @ARGV or exit 127' \
      env -u ANTHROPIC_API_KEY -u OPENAI_API_KEY -u GH_TOKEN -u GITHUB_TOKEN -u CLAUDE_CODE_SESSION_ID -u FELIX_HOME_DIR \
      -u GIT_CONFIG_GLOBAL -u GIT_CONFIG_SYSTEM -u GIT_CONFIG_NOSYSTEM -u XDG_CONFIG_HOME HOME="$S2470_U" \
      PATH="$S2470_D/bin:$PATH" FELIX_HOME="$S2470_D4/home" FELIX_MEMORY="$S2470_D4/mem" TMPDIR="$t" \
      "$S2470_E4" situations --change HEAD~1..HEAD ) > "$S2470_D4/$1.out" 2> "$S2470_D4/$1.err" < /dev/null &
  pid=$!
  while [ "$n" -lt 300 ]; do
    for f in "$t"/felix-situations.*/tmp-head/started; do [ -e "$f" ] && st=started; done
    [ "$st" = "not started" ] || break
    kill -0 "$pid" 2>/dev/null || break
    sleep 0.1; n=$((n + 1))
  done
  kill -s "$1" "$pid" 2>/dev/null
  n=0
  while kill -0 "$pid" 2>/dev/null && [ "$n" -lt 300 ]; do sleep 0.1; n=$((n + 1)); done
  kill -0 "$pid" 2>/dev/null && kill -s KILL "$pid" 2>/dev/null
  wait "$pid" 2>/dev/null; rc=$?
  now="$(ls -A "$t" 2>&1)"
  [ "$st" = "not started" ] || sleep 4
  later="$(ls -A "$t" 2>&1)"
  S2470_SIG="$st|$rc|$now"; S2470_SIG4="$st|$rc|$later"
}
_s2470_sig TERM
is "2470 rf4 TERM sent once the head side's probe has started: felix situations --change exits 143, and TMPDIR is empty as soon as it has exited" "$S2470_SIG" "started|143|"
is "2470 rf4 TERM: TMPDIR is still empty 4 s later, after the probe's sleep would have ended" "$S2470_SIG4" "started|143|"
_s2470_sig HUP
is "2470 rf4 HUP sent once the head side's probe has started: felix situations --change exits 129, and TMPDIR is empty as soon as it has exited" "$S2470_SIG" "started|129|"
is "2470 rf4 HUP: TMPDIR is still empty 4 s later, after the probe's sleep would have ended" "$S2470_SIG4" "started|129|"
_s2470_sig INT
is "2470 rf4 INT, at its default disposition, sent once the head side's probe has started: felix situations --change exits 130, and TMPDIR is empty as soon as it has exited" "$S2470_SIG" "started|130|"
is "2470 rf4 INT: TMPDIR is still empty 4 s later, after the probe's sleep would have ended" "$S2470_SIG4" "started|130|"
rm -rf "$S2470_D4/pipe.t"; mkdir -p "$S2470_D4/pipe.t"
( cd "$S2470_C4" && exec env -u ANTHROPIC_API_KEY -u OPENAI_API_KEY -u GH_TOKEN -u GITHUB_TOKEN -u CLAUDE_CODE_SESSION_ID \
    -u FELIX_HOME_DIR -u GIT_CONFIG_GLOBAL -u GIT_CONFIG_SYSTEM -u GIT_CONFIG_NOSYSTEM -u XDG_CONFIG_HOME HOME="$S2470_U" \
    PATH="$S2470_D/bin:$PATH" FELIX_HOME="$S2470_D4/home" FELIX_MEMORY="$S2470_D4/mem" TMPDIR="$S2470_D4/pipe.t" \
    "$S2470_E4" situations --change HEAD~1..HEAD ) 2> "$S2470_D4/pipe.err" < /dev/null | head -1 > "$S2470_D4/pipe.out"
is "2470 rf4 felix situations --change ... | head -1 prints the report's first line and leaves TMPDIR empty" \
   "$(cat "$S2470_D4/pipe.out")|$(ls -A "$S2470_D4/pipe.t" 2>&1)" "situations for rf4|"

# ---- RF5: quoting in the admit command ----------------------------------------------------------------------------
# quote_me is ACTIVE and unadmitted; its owes holds an apostrophe, a percent sign, and a backslash and an n as two
# bytes. The home is a git repository with one commit; no maturity is declared.
_s2470_dir "$S2470_D/rf5"; S2470_D5="$S2470_P"
S2470_O5="don't drop 100% of the \\n bound"
_s2470_engine "$S2470_D5/x"; S2470_E5="$S2470_E"
_s2470_row "$S2470_D5/x" quote_me 'probe:q=found' "$S2470_O5"
S2470_H5="$S2470_D5/home"; S2470_P5="$S2470_H5/projects/rf5"
_s2470_home "$S2470_H5" rf5 $'q\tq\t-\tcat q.txt\ttest -f q.txt\n'
printf 'fixture\tRELEASE_BLOCKING\tdeterministic\t-\ttrue\t-\ta fixture owes one thing, and it holds\n' > "$S2470_P5/obligations.tsv"
_s2470_g "$S2470_H5" 1793000000 init -q -b main
_s2470_commit "$S2470_H5" 1793000000 home
mkdir -p "$S2470_D5/mem/rf5"
S2470_C5="$S2470_D5/c"
_s2470_repo "$S2470_C5" rf5; printf 'one\n' > "$S2470_C5/q.txt"
_s2470_commit "$S2470_C5" 1793000100 c0
_s2470_run "$S2470_D5/p" "$S2470_C5" "$S2470_H5" "$S2470_D5/mem" "$S2470_E5" probes; S2470_PRC="$S2470_RC"
cp "$S2470_P5/obligations.tsv" "$S2470_D5/ob.before"
S2470_ST5="$(GIT_OPTIONAL_LOCKS=0 git -C "$S2470_H5" status --porcelain 2>&1)"
_s2470_run "$S2470_D5/p1" "$S2470_C5" "$S2470_H5" "$S2470_D5/mem" "$S2470_E5" situations --propose; S2470_RA="$S2470_RC"
is "2470 rf5 --propose exits 0 and leaves obligations.tsv and the home's git status --porcelain unchanged" \
   "$S2470_PRC|$S2470_RA|$(cksum < "$S2470_P5/obligations.tsv")|$(GIT_OPTIONAL_LOCKS=0 git -C "$S2470_H5" status --porcelain 2>&1)" \
   "0|0|$(cksum < "$S2470_D5/ob.before")|$S2470_ST5"
_s2470_id quote_me rf5
S2470_ROW5="$(_s2470_tab quote_me RELEASE_BLOCKING unknown - 'exit 2' q "$S2470_O5")"
S2470_ESC="'\\''"
S2470_CMD5="printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' 'quote_me' 'RELEASE_BLOCKING' 'unknown' '-' 'exit 2' 'q' 'don${S2470_ESC}t drop 100% of the \\n bound' >> '$S2470_P5/obligations.tsv' && git -C '$S2470_H5' add -- '$S2470_P5/obligations.tsv' && git -C '$S2470_H5' commit -q -m 'obligations: admit quote_me' -- '$S2470_P5/obligations.tsv'"
is "2470 rf5 the proposed section ends the report: quote_me with its grounds, the strictest class its cell names while no maturity is declared, its row, and the admit command with each ' written as '\\''" \
   "$S2470_RA|$(tail -n 6 "$S2470_D5/p1.out")" "0|
proposed
  $S2470_ID  quote_me  q found (q)
    class  RELEASE_BLOCKING  maturity undeclared: the strictest class this row names
    row  $S2470_ROW5
    admit  $S2470_CMD5"
S2470_GOT5="$(LC_ALL=C awk 'index($0, "    admit  ") == 1 { print substr($0, 12); exit }' "$S2470_D5/p1.out")"
S2470_RGOT5="$(LC_ALL=C awk 'index($0, "    row  ") == 1 { print substr($0, 10); exit }' "$S2470_D5/p1.out")"
S2470_ARC="not run: no admit command naming git -C '$S2470_H5' add was printed"
case "$S2470_GOT5" in
  "printf '"*"git -C '$S2470_H5' add -- "*)
    S2470_ARC="$( cd "$S2470_D5" && env HOME="$S2470_U" GIT_CONFIG_NOSYSTEM=1 GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t \
      GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t bash -c "$S2470_GOT5" > /dev/null 2>&1; printf '%s' "$?" )" ;;
esac
{ cat "$S2470_D5/ob.before"; printf '%s\n' "$S2470_RGOT5"; } > "$S2470_D5/ob.want"
is "2470 rf5 running the printed admit command appends to obligations.tsv exactly the row line's text after its prefix, then one newline" \
   "$S2470_ARC|$(cmp -s "$S2470_D5/ob.want" "$S2470_P5/obligations.tsv" && printf appended || printf other)|$S2470_RGOT5" \
   "0|appended|$S2470_ROW5"
is "2470 rf5 the admit command makes one commit, which touches only obligations.tsv" \
   "$S2470_ARC|$(git -C "$S2470_H5" rev-list --count HEAD 2>&1)|$(git -C "$S2470_H5" diff-tree --no-commit-id --name-only -r HEAD 2>&1)|$(git -C "$S2470_H5" log -1 --format=%s 2>&1)" \
   "0|2|projects/rf5/obligations.tsv|obligations: admit quote_me"
_s2470_run "$S2470_D5/p2" "$S2470_C5" "$S2470_H5" "$S2470_D5/mem" "$S2470_E5" situations --propose
is "2470 rf5 a second --propose no longer lists quote_me: its proposed section is none" \
   "$S2470_ARC|$S2470_RC|$(tail -n 2 "$S2470_D5/p2.out")" "0|0|proposed
  none"

# ---- RF6: the caller's git config ---------------------------------------------------------------------------------
# HOME's .gitconfig sets init.templateDir (a template whose hooks/post-checkout writes a marker), core.hooksPath (a
# directory whose post-checkout writes a marker) and filter.fx.smudge (which writes a marker); the repository's
# .gitattributes holds * filter=fx. svc_owed is owed over c1.
_s2470_dir "$S2470_D/rf6"; S2470_D6="$S2470_P"
_s2470_engine "$S2470_D6/x"; S2470_E6="$S2470_E"
_s2470_row "$S2470_D6/x" svc_owed 'probe:svc=found' "$S2470_O1"
_s2470_home "$S2470_D6/home" rf6 "$S2470_PSVC"
mkdir -p "$S2470_D6/mem/rf6" "$S2470_D6/user" "$S2470_D6/markers" "$S2470_D6/tpl/hooks" "$S2470_D6/hooks"
S2470_K6="$S2470_D6/markers"
printf '#!/bin/sh\n: > '"'"'%s/template'"'"'\n' "$S2470_K6" > "$S2470_D6/tpl/hooks/post-checkout"
printf '#!/bin/sh\n: > '"'"'%s/hookspath'"'"'\n' "$S2470_K6" > "$S2470_D6/hooks/post-checkout"
printf '#!/bin/sh\n: > '"'"'%s/smudge'"'"'\nexec cat\n' "$S2470_K6" > "$S2470_D6/smudge"
chmod +x "$S2470_D6/tpl/hooks/post-checkout" "$S2470_D6/hooks/post-checkout" "$S2470_D6/smudge"
printf '[init]\n\ttemplateDir = %s\n[core]\n\thooksPath = %s\n[filter "fx"]\n\tsmudge = %s\n' \
  "$S2470_D6/tpl" "$S2470_D6/hooks" "$S2470_D6/smudge" > "$S2470_D6/user/.gitconfig"
S2470_C6="$S2470_D6/c"
_s2470_repo "$S2470_C6" rf6; printf '* filter=fx\n' > "$S2470_C6/.gitattributes"; printf 'a\n' > "$S2470_C6/svc.txt"
_s2470_commit "$S2470_C6" 1793000000 c0
printf 'a\nb\n' > "$S2470_C6/svc.txt"
_s2470_commit "$S2470_C6" 1793000100 c1
# The control: a plain clone under that HOME copies the template and runs the hooksPath hook and the smudge filter.
( export HOME="$S2470_D6/user" GIT_CONFIG_NOSYSTEM=1; unset GIT_CONFIG_GLOBAL XDG_CONFIG_HOME
  _fx_git "$S2470_D6" clone -q -- "$S2470_C6" ctl ) > /dev/null 2>&1
S2470_CTL6="$(ls -A "$S2470_K6" 2>&1 | LC_ALL=C sort | tr '\n' ' ')$([ -f "$S2470_D6/ctl/.git/hooks/post-checkout" ] && printf template-copied)"
rm -rf "$S2470_D6/ctl" "$S2470_K6"; mkdir -p "$S2470_K6"
S2470_U="$S2470_D6/user"
_s2470_run "$S2470_D6/r" "$S2470_C6" "$S2470_D6/home" "$S2470_D6/mem" "$S2470_E6" situations --change HEAD~1..HEAD --tsv
S2470_U="$S2470_D/user"
_s2470_id svc_owed rf6
is "2470 rf6 with HOME's .gitconfig naming a template, a hooks path and a smudge filter, --change HEAD~1..HEAD --tsv exits 0 and evaluates its class" \
   "$S2470_CTL6|$S2470_RC|$(cat "$S2470_D6/r.err")|$(cat "$S2470_D6/r.out")" \
   "hookspath smudge template-copied|0||$(_s2470_tab "$S2470_ID" svc_owed owed ACTIVE ACTIVE 'svc found (svc)' 'svc found (svc)' "$S2470_O1")"
is "2470 rf6 no marker of the template hook, the hooks-path hook or the smudge filter exists after the run" \
   "$S2470_CTL6|$S2470_RC|$(ls -A "$S2470_K6" 2>&1)" "hookspath smudge template-copied|0|"

# ---- RF7: a facts log shared by worktrees -------------------------------------------------------------------------
# W1 and W2, linked worktrees of one repository: W1 at c0, W2 at c1 (svc.txt gains a line). cap_tests (cap:tests) is
# decided by the detector alone, which names tests from the tests/ directory in both.
_s2470_dir "$S2470_D/rf7"; S2470_D7="$S2470_P"
S2470_O7='a test run before every change that touches the tests'
_s2470_engine "$S2470_D7/x"; S2470_E7="$S2470_E"
_s2470_row "$S2470_D7/x" svc_owed 'probe:svc=found' "$S2470_O1"
_s2470_row "$S2470_D7/x" cap_tests 'cap:tests' "$S2470_O7"
_s2470_home "$S2470_D7/home" rf7 "$S2470_PSVC"
mkdir -p "$S2470_D7/mem/rf7"
S2470_R7="$S2470_D7/main"; S2470_V1="$S2470_D7/w1"; S2470_V2="$S2470_D7/w2"
_s2470_repo "$S2470_R7" rf7; printf 'a\n' > "$S2470_R7/svc.txt"; mkdir -p "$S2470_R7/tests"; printf 'true\n' > "$S2470_R7/tests/t.sh"
_s2470_commit "$S2470_R7" 1793000000 c0
_s2470_g "$S2470_R7" 1793000100 worktree add -q -b one "$S2470_V1"
_s2470_g "$S2470_R7" 1793000200 worktree add -q -b two "$S2470_V2"
printf 'a\nb\n' > "$S2470_V2/svc.txt"
_s2470_commit "$S2470_V2" 1793000300 c1
S2470_C7="$(git -C "$S2470_V1" rev-parse HEAD 2>&1)"
_s2470_run "$S2470_D7/p1" "$S2470_V1" "$S2470_D7/home" "$S2470_D7/mem" "$S2470_E7" probes; S2470_PRC="$S2470_RC"
_s2470_newest "$S2470_D7/mem/rf7/facts.log"; S2470_ST1="$S2470_STAMP"; S2470_T1="$S2470_TREE"
_s2470_run "$S2470_D7/p2" "$S2470_V2" "$S2470_D7/home" "$S2470_D7/mem" "$S2470_E7" probes; S2470_PRC="$S2470_PRC $S2470_RC"
_s2470_newest "$S2470_D7/mem/rf7/facts.log"; S2470_ST2="$S2470_STAMP"; S2470_T2="$S2470_TREE"
S2470_TT="trees $([ -n "$S2470_T1" ] && [ "$S2470_T1" != "$S2470_T2" ] && printf distinct || printf 'not distinct')"
_s2470_run "$S2470_D7/hd" "$S2470_V1" "$S2470_D7/home" "$S2470_D7/mem" "$S2470_E7" situations; S2470_RA="$S2470_RC"
_s2470_run "$S2470_D7/td" "$S2470_V1" "$S2470_D7/home" "$S2470_D7/mem" "$S2470_E7" situations --tsv; S2470_RB="$S2470_RC"
_s2470_run "$S2470_D7/ha" "$S2470_V1" "$S2470_D7/home" "$S2470_D7/mem" "$S2470_E7" situations --at "$S2470_T1"; S2470_RC1="$S2470_RC"
_s2470_run "$S2470_D7/ta" "$S2470_V1" "$S2470_D7/home" "$S2470_D7/mem" "$S2470_E7" situations --at "$S2470_T1" --tsv
S2470_RC2="$S2470_RC"
is "2470 rf7 felix situations in W1, after felix probes in W1 then W2, reads W2's tree, the newest, and its header names that tree and ends detector not run: this checkout is not at this tree" \
   "$S2470_TT|$S2470_PRC|$S2470_RA|$(cat "$S2470_D7/hd.err")|$(head -n 2 "$S2470_D7/hd.out")" \
   "trees distinct|0 0|0||situations for rf7
  at  -  tree $S2470_T2  recorded $S2470_ST2  $S2470_NOTAT"
_s2470_id svc_owed rf7; S2470_IS7="$S2470_ID"
_s2470_id cap_tests rf7; S2470_IC7="$S2470_ID"
is "2470 rf7 its --tsv reads cap_tests, which only the detector decides, could-not-look at W2's tree, the residual naming the detector as its why" \
   "$S2470_RB|$(cat "$S2470_D7/td.out")" \
   "0|$(_s2470_tab "$S2470_IS7" svc_owed standing - ACTIVE - 'svc found (svc)' "$S2470_O1")
$(_s2470_tab "$S2470_IC7" cap_tests could-not-look - UNKNOWN - 'tests detector not run' "$S2470_O7")
$(_s2470_tab residual could-not-look cap_tests 'at: cap:tests: no probe grounds tests and the detector was not run: this checkout is not at this tree')"
is "2470 rf7 --at with W1's own tree id runs the detector: the header names W1's HEAD, that tree and its recorded stamp, and says detector run on this checkout" \
   "$S2470_TT|$S2470_RC1|$(cat "$S2470_D7/ha.err")|$(head -n 2 "$S2470_D7/ha.out")" \
   "trees distinct|0||situations for rf7
  at  $S2470_C7  tree $S2470_T1  recorded $S2470_ST1  detector run on this checkout"
is "2470 rf7 --at W1's tree --tsv reads cap_tests standing on tests detected, beside svc_owed, ordered by id" \
   "$S2470_RC2|$(cat "$S2470_D7/ta.out")" \
   "0|$(printf '%s\n%s\n' "$(_s2470_tab "$S2470_IS7" svc_owed standing - ACTIVE - 'svc found (svc)' "$S2470_O1")" \
        "$(_s2470_tab "$S2470_IC7" cap_tests standing - ACTIVE - 'tests detected' "$S2470_O7")" | LC_ALL=C sort)"
