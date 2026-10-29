# >>> lost-work-review-gaps
printf '\nthe lost-work page, step 6: the clauses the Opus review found unpinned (contract A3 S1-S3, B2; review finding 7, blind)\n'
# Blind, from docs/2026-10-18-lost-work-page-contract.md alone, on the stubs,
# builders and readers of tests/lib/lost-work.sh. Every expected value is the
# contract's: A3 gives S1, S2 and S3 only a session file "modified after the
# proposal", gives S1 and S2 only a file that is "not the file that proposed
# it", and B2 says the page's scratch directory is "removed on exit and on HUP,
# INT, QUIT and TERM". The review found no assertion that fails when one of
# those clauses is taken out (finding 7). Each case below is paired with a
# control in the same fixture that differs from it in that one respect, so a
# clause that is gone makes the case fail and not the control.
#
# Part A. One records root, hk, and a repository gp. A starter is "old" when
# its file was last modified 700 minutes ago, before the proposals (the
# proposing records are 610 minutes old and their files 600 or 300), and
# "new" at 300. The old and the new starter of a pair hold the same records,
# stamped 302 and 301 minutes ago, and differ in the file's mtime alone.
# An anchor chip, proposed 900 minutes ago, is the oldest proposal in the
# fixture: the reader looks for starters only among files modified since the
# oldest proposal, so without an older chip an old starter would never be a
# candidate and the per-chip "modified after its proposal" test would never be
# the one that turns it away.
_lw_build
_lw_repo gp; LWR_GP="$LW/gp"; LWR_GPR="$(_lw_mainwt "$LWR_GP")"
LW_RR="$LW/hk/.claude/projects"; mkdir -p "$LW_RR"
LWR_OK='The user sees a card and nothing runs until they start it.'
LWR_P1="$(_lw_p 'Gap one: make the exporter name the file it wrote, and test that two exports give two names.' 130)"
LWR_P1C="$(_lw_p 'Gap one control: make the importer count the rows it skipped, and test a file with two bad rows.' 130)"
LWR_P2="$(_lw_p 'Gap two: make the cache say how old its oldest entry is, with a test of one entry.' 130)"
LWR_P2C="$(_lw_p 'Gap two control: make the planner list its steps in the order they run, with a two-step test.' 130)"
LWR_P3="$(_lw_p 'Gap three: make the loader refuse a config file that names a key twice, with a test.' 130)"
LWR_P3C="$(_lw_p 'Gap three control: make the runner print the seed it used, and test that two runs differ.' 130)"
LWR_P4="$(_lw_p 'Gap four: make the sorter keep equal keys in the order they came, and add a test.' 130)"
LWR_P4C="$(_lw_p 'Gap four control: make the printer wrap its lines at the width it is given, and add a test.' 130)"
LWR_P0="$(_lw_p 'Gap anchor: make the logger stamp each line with the run it came from, and test two runs.' 130)"
_lwr_start() { _lw_tu "$1" "$2" mcp__ccd_session__start_session "$3"; _lw_tr "$1" "$2" "$4"; }
_lwr_mt() { perl -e 'print((stat $ARGV[0])[9])' "$1" 2>/dev/null; }

# The anchor's proposing session: the oldest proposal, and a file older than
# every old starter.
_lw_sess "$LWR_GPR" e1e1e1e1-0000-4000-8000-000000000000; _lw_h 912 'file the first follow-up'; LWR_FA="$LW_F"
_lw_spawn 900 toolu_g0 task_9a000001 'Gap anchor' "$LWR_P0"
_lw_a 890 'Filed.'; _lw_age "$LW_F" 890
# The proposing sessions, filed under gp's main worktree. Their files are the
# newer of every pair below.
_lw_sess "$LWR_GPR" e1e1e1e1-0000-4000-8000-000000000001; _lw_h 612 'file the follow-ups'; LWR_FP="$LW_F"
_lw_spawn 610 toolu_g1 task_9a010101 'Gap one' "$LWR_P1"
_lw_spawn 610 toolu_g1c task_9a010102 'Gap one control' "$LWR_P1C"
_lw_spawn 610 toolu_g2 task_9a020201 'Gap two old title' "$LWR_P2"
_lw_spawn 610 toolu_g2c task_9a020202 'Gap two new title' "$LWR_P2C"
printf -v _lwi '{"initiation":"own_initiative","title":"Gap three","prompt":"%s"}' "$LWR_P3"
_lwr_start 610 toolu_g3 "$_lwi" "Proposed (task_id: task_9a030301). $LWR_OK"
printf -v _lwi '{"initiation":"own_initiative","title":"Gap three control","prompt":"%s"}' "$LWR_P3C"
_lwr_start 610 toolu_g3c "$_lwi" "Proposed (task_id: task_9a030302). $LWR_OK"
_lw_a 600 'Filed.'; _lw_age "$LW_F" 600
# S1's exclusion: each of these sessions began with the prompt of the chip it
# later proposes, so its own first human text matches. Its file is modified
# after the proposal (300 against 610), so only "not the file that proposed it"
# keeps it from starting the chip.
_lw_sess "$LWR_GPR" e1e1e1e1-0000-4000-8000-000000000002; _lw_h 612 "$LWR_P4"; LWR_F4="$LW_F"
_lw_spawn 610 toolu_g4 task_9a040401 'Gap four' "$LWR_P4"
_lw_a 300 'Filed.'; _lw_age "$LW_F" 300
_lw_sess "$LWR_GPR" e1e1e1e1-0000-4000-8000-000000000003; _lw_h 612 "$LWR_P4C"
_lw_spawn 610 toolu_g4c task_9a040402 'Gap four control' "$LWR_P4C"
_lw_a 300 'Filed.'; _lw_age "$LW_F" 300

# The starters, each in a directory of its own outside gp's. S1: the first
# human text is the prompt. S2: a custom-title equal to the title, the first
# text unrelated. S3: a start_session call carrying the task id, with a result.
_lwr_s1() {  # NAME PROMPT AGE
  _lw_open "$LW_RR/-elsewhere-$1/$1.jsonl" "e2e2e2e2-0000-4000-8000-0000000000$1"
  _lw_h 302 "$2"; _lw_a 301 'On it.'; _lw_age "$LW_F" "$3"; }
_lwr_s2() {  # NAME TITLE AGE
  _lw_open "$LW_RR/-elsewhere-$1/$1.jsonl" "e2e2e2e2-0000-4000-8000-0000000000$1"
  _lw_title "$2"; _lw_h 302 'look at something unrelated'; _lw_a 301 'Done.'; _lw_age "$LW_F" "$3"; }
_lwr_s3() {  # NAME TASK-ID AGE
  _lw_open "$LW_RR/-elsewhere-$1/$1.jsonl" "e2e2e2e2-0000-4000-8000-0000000000$1"
  _lw_h 303 'start the card'; _lw_tu 302 "toolu_go_$1" mcp__ccd_session__start_session "{\"proposal_id\":\"$2\"}"
  _lw_tr 301 "toolu_go_$1" 'Started.'; _lw_a 300 'Started it.'; _lw_age "$LW_F" "$3"; }
_lwr_s1 s1o "$LWR_P1" 700;        LWR_MS1O="$(_lwr_mt "$LW_F")"
_lwr_s1 s1n "$LWR_P1C" 300;       LWR_MS1N="$(_lwr_mt "$LW_F")"
_lwr_s2 s2o 'Gap two old title' 700;  LWR_MS2O="$(_lwr_mt "$LW_F")"
_lwr_s2 s2n 'Gap two new title' 300;  LWR_MS2N="$(_lwr_mt "$LW_F")"
_lwr_s3 s3o task_9a030301 700;    LWR_MS3O="$(_lwr_mt "$LW_F")"
_lwr_s3 s3n task_9a030302 300;    LWR_MS3N="$(_lwr_mt "$LW_F")"
_lwr_s1 s4n "$LWR_P4C" 300

is "review finding 7 fixture: each old starter's file is older than the proposing session's file and each new one's is newer (fixture control)" \
   "$(for _lwi in S1O S2O S3O; do eval "_lwv=\$LWR_M$_lwi"; [ -n "$_lwv" ] && [ "$_lwv" -lt "$(_lwr_mt "$LWR_FP")" ] && printf 'old '; done)$(for _lwi in S1N S2N S3N; do eval "_lwv=\$LWR_M$_lwi"; [ -n "$_lwv" ] && [ "$_lwv" -gt "$(_lwr_mt "$LWR_FP")" ] && printf 'new '; done)" \
   "old old old new new new "
is "review finding 7 fixture: the proposer of Gap four begins with its own prompt, and is modified after its proposal (fixture control)" \
   "$(LC_ALL=C awk 'index($0, "\"type\":\"user\"") { print (index($0, "Gap four: make the sorter") ? "own-prompt" : "other"); exit }' "$LWR_F4") $([ "$(_lwr_mt "$LWR_F4")" -gt "$LWR_MS1O" ] && echo newer)" \
   "own-prompt newer"

_lw_run GAP "$LW/hk" "$LW/cwd" inventory --repo "$LWR_GP" --tsv --no-gh
LWR_G="$(_lw_o GAP)"
is "review finding 7: the inventory over gp exits 0 and lists a chip (control)" "$(_lw_rc GAP) $(_lw_kind "$LWR_G" task_9a000001)" "0 chip"
is "review finding 7 fixture: the oldest proposal, the anchor's, is older than every old starter's file and is a chip nothing started, so each old starter is a candidate for the other chips (fixture control)" \
   "$([ "$(_lwr_mt "$LWR_FA")" -lt "$LWR_MS1O" ] && [ "$(_lwr_mt "$LWR_FA")" -lt "$LWR_MS2O" ] && [ "$(_lwr_mt "$LWR_FA")" -lt "$LWR_MS3O" ] && echo older) $(_lw_st "$LWR_G" chip task_9a000001)" \
   "older chip-unstarted"

# S1, S2, S3: "modified after the proposal"
is "A3 S1: a starter whose first human text is the chip's prompt, modified after the proposal, starts it (control)" \
   "$(_lw_kind "$LWR_G" task_9a010102)" none
is "A3 S1: the same starter last modified before the proposal does not start it: the chip stays chip-unstarted" \
   "$(_lw_st "$LWR_G" chip task_9a010101)" "chip-unstarted"
is "A3 S2: a custom-title equal to the chip's title, in a file modified after the proposal, starts it (control)" \
   "$(_lw_kind "$LWR_G" task_9a020202)" none
is "A3 S2: the same custom-title in a file last modified before the proposal does not start it: the chip stays chip-unstarted" \
   "$(_lw_st "$LWR_G" chip task_9a020201)" "chip-unstarted"
is "A3 S3: a start_session call carrying the chip's id with a result, in a file modified after the proposal, starts it (control)" \
   "$(_lw_kind "$LWR_G" task_9a030302)" none
is "A3 S3: the same call in a file last modified before the proposal does not start it: the chip stays chip-unstarted" \
   "$(_lw_st "$LWR_G" chip task_9a030301)" "chip-unstarted"

# S1: "not the file that proposed it"
is "A3 S1: a session that began with the chip's prompt and later proposed the chip is not its own starter: the chip stays chip-unstarted" \
   "$(_lw_st "$LWR_G" chip task_9a040401)" "chip-unstarted"
is "A3 S1: the same arrangement with another session that begins with the prompt, modified after the proposal, is started (control)" \
   "$(_lw_kind "$LWR_G" task_9a040402)" none

# Part B. B2: the page's scratch directory is removed on HUP, INT, QUIT and
# TERM, not only when the page ends by itself. gp is governed by no project, so
# the page's first source is the inventory, and a gh that waits holds the page
# there with its scratch directory made. The page runs in a session of its own
# with INT, QUIT, HUP and TERM at their defaults (a command started with & by a
# plain shell inherits INT and QUIT ignored, and a trap cannot reset those).
# TMPDIR is a directory of this run's alone, empty when the run starts. The
# signal is sent to the page's process; gh is then released, so that a page
# that defers its trap until its child ends, as a shell does, reaches it. The
# sources' own scratch directories are theirs and go when they end; the check
# waits for those and reads what is left.
LWR_SB="$LW/sigbin"; LWR_SC="$LW/sigctl"; mkdir -p "$LWR_SB" "$LWR_SC"
_lw_put "$LWR_SB/gh" <<'LWSTUB'
#!/bin/bash
c="${LWR_SC:?}"; r="${LWR_RUN:?}"
printf '%s\n' "$*" >> "$c/$r.gh.log"
: > "$c/$r.started"
i=0
while [ ! -e "$c/$r.release" ] && [ "$i" -lt 200 ]; do sleep 0.2; i=$((i + 1)); done
printf 'stub: gh was held until released\n' >&2
exit 1
LWSTUB
# _lwr_sig SIGNAL: sets LWR_BLOCKED, LWR_HELD, LWR_ENDED, LWR_RC and LWR_LEFT.
_lwr_sig() {
  local sg="$1" pid t=0 d="$LW/sigtmp.$1"
  rm -rf "$d" "$LWR_SC/$sg".*; mkdir -p "$d"
  ( cd "$LW/cwd" || exit 97
    exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CONFIG_DIR \
      -u CLAUDE_PLUGIN_ROOT -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u GIT_COMMON_DIR -u GIT_OBJECT_DIRECTORY -u GIT_OPTIONAL_LOCKS \
      HOME="$LW/hk" FELIX_HOME="$LW_FH" FELIX_HOME_DIR="$LW_FH" FELIX_MEMORY="$LWM" FELIX_PLUGIN_CACHE="$LW/cache" \
      FELIX_INVENTORY_TEMP_ROOTS="$LW/temproot" XDG_CONFIG_HOME="$LW/hk/.config" XDG_STATE_HOME="$LW/hk/.state" XDG_CACHE_HOME="$LW/hk/.cache" \
      GH_CONFIG_DIR="$LW/hk/.config/gh" GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 GIT_CEILING_DIRECTORIES="$LW" \
      LWR_SC="$LWR_SC" LWR_RUN="$sg" TMPDIR="$d" PATH="$LWR_SB:$LWB:$PATH" \
      perl -e 'use POSIX (); POSIX::setsid(); $SIG{INT} = $SIG{QUIT} = $SIG{HUP} = $SIG{TERM} = "DEFAULT"; exec @ARGV' \
      "$FELIX" monitor --repo "$LWR_GP" --no-host ) > "$LWX/sig.$sg.out" 2> "$LWX/sig.$sg.err" < /dev/null &
  pid=$!
  while [ ! -e "$LWR_SC/$sg.started" ] && kill -0 "$pid" 2>/dev/null && [ "$t" -lt 200 ]; do sleep 0.2; t=$((t + 1)); done
  LWR_BLOCKED=no; [ -e "$LWR_SC/$sg.started" ] && LWR_BLOCKED=yes
  LWR_HELD=no; [ -n "$(ls -A "$d" 2>/dev/null)" ] && LWR_HELD=yes
  if [ "$LWR_BLOCKED" = yes ]; then kill -s "$sg" "$pid" 2>/dev/null; sleep 1; fi
  : > "$LWR_SC/$sg.release"
  t=0; while kill -0 "$pid" 2>/dev/null && [ "$t" -lt 150 ]; do sleep 0.2; t=$((t + 1)); done
  LWR_ENDED=yes; if kill -0 "$pid" 2>/dev/null; then LWR_ENDED=no; kill -s KILL "$pid" 2>/dev/null; fi
  wait "$pid" 2>/dev/null; LWR_RC=$?
  t=0; while [ -n "$(ls -A "$d" 2>/dev/null)" ] && [ "$t" -lt 75 ]; do sleep 0.2; t=$((t + 1)); done
  LWR_LEFT="$(ls -A "$d" 2>/dev/null | head -3 | LC_ALL=C tr '\n' ' ')"
}
if command -v perl >/dev/null 2>&1; then
  for _lwr_sg in HUP INT QUIT TERM; do
    _lwr_sig "$_lwr_sg"
    is "B2: with the page held on its first source, $_lwr_sg finds it there, with a scratch directory made (fixture control)" "$LWR_BLOCKED $LWR_HELD" "yes yes"
    is "B2: after $_lwr_sg the page has ended and its scratch directory is removed" "ended=$LWR_ENDED left=[$LWR_LEFT]" "ended=yes left=[]"
  done
else
  skip "B2: the page's scratch directory is removed after HUP, INT, QUIT and TERM" "no perl to start the page with its signals at their defaults"
fi
for _lwr_sg in HUP INT QUIT TERM; do : > "$LWR_SC/$_lwr_sg.release"; done
# <<< lost-work-review-gaps
