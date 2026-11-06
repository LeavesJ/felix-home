printf '\na route step run as a program is used: the ledger asked beside the transcript (cli-reach amendment, U1-U6)\n'
# Blind, written 2026-11-06 from docs/2026-10-31-cli-reach-spec.md section 9 alone (U1-U6), with sections 0-8 read for
# the behaviour it builds on. lib/route.sh, hooks/user-prompt and hooks/stop are black boxes; parts 0240, 0250 and 1760
# were read for idioms: how felix_route_step_used and felix_route_skipped are called (resolve.sh, then route.sh, in a
# subshell), how the prompt hook's route block is read ("Use this now: <step>" in additionalContext), and how Stop is
# made to speak of a skipped step (a route state file state/route/<session> holding <route>:<step>, a transcript, a
# gated tree; it says "never used"). Why: felix_route_step_used asked only the transcript, so a session that had run
# graphify was told graphify was still due, and at Stop that it skipped it (9.1 b). Readings where the spec leaves
# room: felix_route_due and felix_route_skipped are asserted by which step names their output holds, not its exact
# shape; felix_route_render is called with the project's directory as PROJ, the repository as ROOT and a PSCORE of 3,
# and asserted through the "Use this now:" line the prompt hook shows; U1's "followed by a line break" is read as
# written, so a last line with no newline is not a use. Fixture: home rs9/home holding a copy of the harness (as part
# 1760 does), project zorb governed by its .felix marker, and the repository rs9/repo. Only this fixture is touched.
RS9="$TMP/route-step-cli"; mkdir -p "$RS9/home/projects/zorb" "$RS9/mem" "$RS9/repo" "$RS9/user" "$RS9/stub" "$RS9/tr" "$RS9/led"
RS9="$(cd "$RS9" && pwd -P)"; RS9H="$RS9/home"; RS9M="$RS9/mem"; RS9R="$RS9/repo"; RS9U="$RS9/user"; RS9X="$RS9/stub"; RS9P="$RS9H/projects/zorb"
RS9T="$(printf '\t')"; RS9NL=$'\n'; RS9L="$RS9/led"
_copy_content "$REAL_HARNESS" "$RS9H/harness"
printf '{"name": "zorb", "gate": "true"}\n' > "$RS9P/project.json"; printf '# zorb\n' > "$RS9P/CLAUDE.md"
printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' > "$RS9P/probes.tsv"
( _fx_cd "$RS9R" && git init -q -b main && printf 'base\n' > WORK.txt && printf 'zorb\n' > .felix && git add -A \
  && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm init ) >/dev/null 2>&1
RS9G="$(type -P git)"
printf '#!/bin/sh\nprintf "git\\n" >> "%s/git.log"\nexec "%s" "$@"\n' "$RS9" "$RS9G" > "$RS9X/git"; chmod +x "$RS9X/git"
printf 'alpha\tmap structure graph\tcore\tgraphify claude-md-management\nsolo\tzzsolo\tcore\tgraphify\n' > "$RS9P/routes.tsv"
printf 'skill\tgraphify\t-\tlow\talways\nplugin\tclaude-md-management@claude-plugins-official\t-\tlow\talways\n' > "$RS9P/stack.tsv"
cat > "$RS9/bound.pl" <<'RS9B'
my $s = shift @ARGV; my $p = fork; defined $p or exit 125;
if (!$p) { setpgrp(0, 0); exec { $ARGV[0] } @ARGV; exit 127 }
setpgrp($p, $p); my $held = 0; $SIG{ALRM} = sub { $held = 1; kill 'KILL', -$p };
alarm $s; 1 while waitpid($p, 0) == -1 && $!{EINTR}; my $st = $?; alarm 0;
if ($held) { kill 'KILL', -$p; exit 124 }
exit(($st & 127) ? 128 + ($st & 127) : $st >> 8);
RS9B
_rs9_rep() { RS9S="$1" awk -v n="$2" 'BEGIN { s = ENVIRON["RS9S"]; for (i = 0; i < n; i++) printf "%s", s }'; }   # TEXT N -> TEXT N times
_rs9_lib() { ( FELIX_HOME="$RS9H"; FELIX_MEMORY="$RS9M"; HOME="$RS9U"; PATH="$RS9X:$PATH"; export FELIX_HOME FELIX_MEMORY HOME PATH
               . "$RS9H/harness/lib/resolve.sh"; . "$RS9H/harness/lib/route.sh"; "$@" ) 2>/dev/null; }   # FUNCTION ARGS... -> in a subshell
_rs9_used() { if _rs9_lib felix_route_step_used "$@" >/dev/null; then printf used; else printf unused; fi; }   # TRANSCRIPT STEP [LEDGER]
_rs9_hl() { local t="$1" w o=""; shift; for w in "$@"; do case "$t" in *"$w"*) o="$o +$w" ;; *) o="$o -$w" ;; esac; done; printf '%s' "${o# }"; }   # TEXT WORD... -> +held -lacking
_rs9_led() { printf "$2" > "$RS9L/$1.tsv"; printf '%s' "$RS9L/$1.tsv"; }   # NAME FORMAT -> a ledger file holding FORMAT, and its path
RS9T0="$RS9/tr/t0.jsonl"; : > "$RS9T0"
RS9TC="$RS9/tr/tc.jsonl"; printf '{"attributionSkill":"code-review:review-changes","attributionPlugin":"code-review","type":"assistant"}\n' > "$RS9TC"
RS9LG="$(_rs9_led g 'alive\tpost-tool\ncli\tgraphify\n')"; RS9LB="$(_rs9_led both 'alive\tpost-tool\ncli\tgraphify\nalive\tpost-tool\ncli\tclaude-md-management\n')"
RS9LS="$(_rs9_led bash 'alive\tpost-tool\ntool\tBash\n')"; RS9LC="$(_rs9_led c 'alive\tpost-tool\ncli\tclaude-md-management\n')"
RS9N64="n$(_rs9_rep 6 62)x"; RS9N65="n$(_rs9_rep 6 63)x"; RS9PLAY="graphify claude-md-management"; mkdir -p "$RS9L/dir.tsv"
is "cli-reach amendment fixture: the copied harness has lib/route.sh and both hooks (fixture control)" \
   "$([ -f "$RS9H/harness/lib/route.sh" ] && [ -x "$RS9H/harness/hooks/user-prompt" ] && [ -x "$RS9H/harness/hooks/stop" ] && echo copied)" "copied"

printf '\nU1: a cli line of the ledger is a use of the step\n'
is "cli-reach amendment U1: with an empty transcript and no ledger graphify is not used (control)" "$(_rs9_used "$RS9T0" graphify)" "unused"
is "cli-reach amendment U1: a ledger holding cli graphify makes graphify used" "$(_rs9_used "$RS9T0" graphify "$RS9LG")" "used"
is "cli-reach amendment U1: without the transcript: one empty, one missing" \
   "$(_rs9_used "" graphify "$RS9LG") $(_rs9_used "$RS9/tr/absent.jsonl" graphify "$RS9LG")" "used used"
printf '{"attributionSkill":"other"}\n' > "$RS9/tr/unread.jsonl"; chmod 000 "$RS9/tr/unread.jsonl"
if [ -r "$RS9/tr/unread.jsonl" ]; then skip "cli-reach amendment U1: and with an unreadable transcript" "the file is still readable here"
else is "cli-reach amendment U1: and with an unreadable transcript" "$(_rs9_used "$RS9/tr/unread.jsonl" graphify "$RS9LG")" "used"; fi
chmod 644 "$RS9/tr/unread.jsonl"
is "cli-reach amendment U1: the line among other kinds of line, anywhere in the file" \
   "$(_rs9_used "$RS9T0" graphify "$(_rs9_led mix 'alive\tpost-tool\ntool\tBash\nalive\tpost-tool\ncli\tgraphify\nalive\tpost-tool\nnamed\tgraphify\nalive\tpost-tool\ntool\tRead\n')")" "used"
is "cli-reach amendment U1: names of N2's every byte class are used by their cli lines: 9lives, x.y_z+1, c++, a name of 64 bytes" \
   "$(_rs9_used "$RS9T0" 9lives "$(_rs9_led b1 'cli\t9lives\n')") $(_rs9_used "$RS9T0" x.y_z+1 "$(_rs9_led b2 'cli\tx.y_z+1\n')") $(_rs9_used "$RS9T0" c++ "$(_rs9_led b3 'cli\tc++\n')") $(_rs9_used "$RS9T0" "$RS9N64" "$(_rs9_led b4 "cli\\t$RS9N64\\n")")" \
   "used used used used"
is "cli-reach amendment U1: the line must end in a line break: a last line cli graphify with none is no use" \
   "$(_rs9_used "$RS9T0" graphify "$(_rs9_led nonl 'alive\tpost-tool\ncli\tgraphify')")" "unused"

printf '\nU2: compared whole, and only for a step that is a name\n'
_rs9_nm() { is "cli-reach amendment U2: graphify is not used by a line $1" "$(_rs9_used "$RS9T0" graphify "$(_rs9_led nm "alive\\tpost-tool\\n$2\\n")")" "unused"; }   # LABEL LINE-FORMAT
_rs9_nm 'cli graphifyx' 'cli\tgraphifyx'; _rs9_nm 'cli Graphify' 'cli\tGraphify'; _rs9_nm 'cli graph' 'cli\tgraph'
_rs9_nm 'cli graphify extra' 'cli\tgraphify extra'; _rs9_nm 'tool graphify' 'tool\tgraphify'; _rs9_nm 'named graphify' 'named\tgraphify'
_rs9_nm 'skill graphify' 'skill\tgraphify'; _rs9_nm 'mcp graphify' 'mcp\tgraphify'; _rs9_nm 'agent graphify' 'agent\tgraphify'
_rs9_nm 'answer graphify' 'answer\tgraphify'; _rs9_nm 'alive graphify' 'alive\tgraphify'; _rs9_nm 'xcli graphify' 'xcli\tgraphify'
_rs9_nm 'CLI graphify' 'CLI\tgraphify'; _rs9_nm 'with a blank before cli' ' cli\tgraphify'; _rs9_nm 'with a third field' 'cli\tgraphify\t1'
_rs9_nm 'ending in a carriage return' 'cli\tgraphify\r'; _rs9_nm 'with a blank for the tab' 'cli graphify'
_rs9_nm 'with two tabs' 'cli\t\tgraphify'; _rs9_nm 'with a blank after the tab' 'cli\t graphify'; _rs9_nm 'ending in a blank' 'cli\tgraphify '
_rs9_nm 'commented out' '#cli\tgraphify'; _rs9_nm 'holding cli graphify after other text' 'say cli\tgraphify'
_rs9_nm 'holding cli graphify twice' 'cli\tgraphify\tcli\tgraphify'
is "cli-reach amendment U2: cli graphify is no use of graph, graphifyx or Graphify" \
   "$(_rs9_used "$RS9T0" graph "$RS9LG") $(_rs9_used "$RS9T0" graphifyx "$RS9LG") $(_rs9_used "$RS9T0" Graphify "$RS9LG")" "unused unused unused"
_rs9_nn() { is "cli-reach amendment U2: a step that is not a name is not used by its own cli line: $1" "$(_rs9_used "$RS9T0" "$2" "$(_rs9_led nn "cli\\t$2\\n")")" "unused"; }   # LABEL STEP
_rs9_nn 'superpowers:brainstorming' superpowers:brainstorming; _rs9_nn 'semgrep@claude-plugins-official' semgrep@claude-plugins-official
_rs9_nn 'a/b' a/b; _rs9_nn '-' -; _rs9_nn 'a word of 65 bytes' "$RS9N65"; _rs9_nn '.hidden' .hidden; _rs9_nn '_under' _under
is "cli-reach amendment U2: a qualified step is not satisfied by a cli line of its plugin's bare name" \
   "$(_rs9_used "$RS9T0" superpowers:brainstorming "$(_rs9_led q1 'cli\tsuperpowers\n')") $(_rs9_used "$RS9T0" semgrep@claude-plugins-official "$(_rs9_led q2 'cli\tsemgrep\n')")" "unused unused"

printf '\nU3: nothing else changes\n'
printf 'cli\tgraphify\n' > "$RS9L/unread.tsv"; chmod 000 "$RS9L/unread.tsv"
RS9U3="$(_rs9_used "$RS9T0" graphify) $(_rs9_used "$RS9T0" graphify "") $(_rs9_used "$RS9T0" graphify "$RS9L/absent.tsv") $(_rs9_used "$RS9T0" graphify "$RS9L/dir.tsv")"
is "cli-reach amendment U3: graphify with an empty transcript is unused with the ledger omitted, empty, missing or a directory" "$RS9U3" "unused unused unused unused"
if [ -r "$RS9L/unread.tsv" ]; then skip "cli-reach amendment U3: and with an unreadable ledger holding cli graphify" "the file is still readable here"
else is "cli-reach amendment U3: and with an unreadable ledger holding cli graphify" "$(_rs9_used "$RS9T0" graphify "$RS9L/unread.tsv")" "unused"; fi
is "cli-reach amendment U3: and with a ledger that holds no such line" "$(_rs9_used "$RS9T0" graphify "$RS9LS")" "unused"
RS9U3="$(_rs9_used "$RS9TC" code-review) $(_rs9_used "$RS9TC" code-review "") $(_rs9_used "$RS9TC" code-review "$RS9L/absent.tsv") $(_rs9_used "$RS9TC" code-review "$RS9L/dir.tsv")"
is "cli-reach amendment U3: a step the transcript used is used whatever the ledger: omitted, empty, missing, a directory" "$RS9U3" "used used used used"
is "cli-reach amendment U3: and beside a ledger of other lines, or one holding cli graphify" \
   "$(_rs9_used "$RS9TC" code-review "$RS9LS") $(_rs9_used "$RS9TC" code-review "$RS9LG")" "used used"
if [ -r "$RS9L/unread.tsv" ]; then skip "cli-reach amendment U3: and beside an unreadable ledger" "the file is still readable here"
else is "cli-reach amendment U3: and beside an unreadable ledger" "$(_rs9_used "$RS9TC" code-review "$RS9L/unread.tsv")" "used"; fi
chmod 644 "$RS9L/unread.tsv"

printf '\nU4: felix_route_due, felix_route_skipped and felix_route_render take the ledger\n'
RS9D0="$(_rs9_lib felix_route_due "$RS9T0" "$RS9PLAY")"
is "cli-reach amendment U4: with no ledger an empty transcript has graphify due (control)" "$(_rs9_hl "$RS9D0" graphify)" "+graphify"
is "cli-reach amendment U4: felix_route_due prints the same with the ledger empty, missing, a directory or of other lines" \
   "$(_rs9_lib felix_route_due "$RS9T0" "$RS9PLAY" "")|$(_rs9_lib felix_route_due "$RS9T0" "$RS9PLAY" "$RS9L/absent.tsv")|$(_rs9_lib felix_route_due "$RS9T0" "$RS9PLAY" "$RS9L/dir.tsv")|$(_rs9_lib felix_route_due "$RS9T0" "$RS9PLAY" "$RS9LS")" \
   "$RS9D0|$RS9D0|$RS9D0|$RS9D0"
is "cli-reach amendment U4: with cli graphify in the ledger, claude-md-management is due and not graphify" \
   "$(_rs9_hl "$(_rs9_lib felix_route_due "$RS9T0" "$RS9PLAY" "$RS9LG")" claude-md-management graphify)" "+claude-md-management -graphify"
is "cli-reach amendment U4: with cli claude-md-management alone, graphify is still due" \
   "$(_rs9_hl "$(_rs9_lib felix_route_due "$RS9T0" "$RS9PLAY" "$RS9LC")" graphify claude-md-management)" "+graphify -claude-md-management"
is "cli-reach amendment U4: with both run, nothing is due" "$(_rs9_lib felix_route_due "$RS9T0" "$RS9PLAY" "$RS9LB")" ""
is "cli-reach amendment U4: a step the transcript used and one the ledger holds leave nothing due" \
   "$(_rs9_lib felix_route_due "$RS9TC" "code-review graphify" "$RS9LG")" ""
RS9Q="superpowers:brainstorming semgrep@claude-plugins-official"; RS9LQ="$(_rs9_led qb 'cli\tsuperpowers\ncli\tsemgrep\ncli\tsuperpowers:brainstorming\n')"
is "cli-reach amendment U4: a play of qualified steps has the same due step beside cli lines of their bare and qualified names" \
   "$(_rs9_lib felix_route_due "$RS9T0" "$RS9Q" "$RS9LQ")" "$(_rs9_lib felix_route_due "$RS9T0" "$RS9Q")"
RS9S0="$(_rs9_lib felix_route_skipped "$RS9T0" "$RS9PLAY")"
is "cli-reach amendment U4: with no ledger felix_route_skipped names both steps (control)" "$(_rs9_hl "$RS9S0" graphify claude-md-management)" "+graphify +claude-md-management"
is "cli-reach amendment U4: and prints the same with the ledger empty, missing or of other lines" \
   "$(_rs9_lib felix_route_skipped "$RS9T0" "$RS9PLAY" "")|$(_rs9_lib felix_route_skipped "$RS9T0" "$RS9PLAY" "$RS9L/absent.tsv")|$(_rs9_lib felix_route_skipped "$RS9T0" "$RS9PLAY" "$RS9LS")" \
   "$RS9S0|$RS9S0|$RS9S0"
is "cli-reach amendment U4: with cli graphify it skips claude-md-management and not graphify" \
   "$(_rs9_hl "$(_rs9_lib felix_route_skipped "$RS9T0" "$RS9PLAY" "$RS9LG")" claude-md-management graphify)" "+claude-md-management -graphify"
is "cli-reach amendment U4: with both run it skips neither" "$(_rs9_lib felix_route_skipped "$RS9T0" "$RS9PLAY" "$RS9LB")" ""
is "cli-reach amendment U4: and a step the transcript used beside one the ledger holds skips nothing" \
   "$(_rs9_lib felix_route_skipped "$RS9TC" "code-review graphify" "$RS9LG")" ""
_rs9_rd() { _rs9_lib felix_route_render "$RS9P" alpha "$RS9PLAY" "$RS9R" 3 "$RS9T0" "$@"; }   # [LEDGER] -> the route block felix_route_render prints
RS9R0="$(_rs9_rd)"
is "cli-reach amendment U4: with no ledger felix_route_render names graphify as the step to use now (control)" "$(_rs9_hl "$RS9R0" 'Use this now: graphify')" "+Use this now: graphify"
is "cli-reach amendment U4: felix_route_render prints the same with the ledger empty, missing or of other lines" \
   "$(_rs9_rd "")|$(_rs9_rd "$RS9L/absent.tsv")|$(_rs9_rd "$RS9LS")" "$RS9R0|$RS9R0|$RS9R0"
is "cli-reach amendment U4: with cli graphify it names claude-md-management to use now, and not graphify" \
   "$(_rs9_hl "$(_rs9_rd "$RS9LG")" 'Use this now: claude-md-management' 'Use this now: graphify')" "+Use this now: claude-md-management -Use this now: graphify"
is "cli-reach amendment U4: with both run it names no step to use now" "$(_rs9_hl "$(_rs9_rd "$RS9LB")" 'Use this now:')" "-Use this now:"

printf '\nU5: the prompt and Stop hooks hand the session'"'"'s appends over\n'
mkdir -p "$RS9H/state/ledger" "$RS9H/state/route"
_rs9_run() {   # HOOK PAYLOAD -> one run in the repository, bounded at 60 s; RS9_RC and RS9_O
  rm -f "$RS9/o" "$RS9/rc"
  ( _fx_cd "$RS9R" && printf '%s' "$2" | perl "$RS9/bound.pl" 60 env -u FELIX_ALLOW_RED -u CLAUDE_CODE_REMOTE -u CLAUDE_CODE_SESSION_ID \
      FELIX_HOME="$RS9H" FELIX_MEMORY="$RS9M" HOME="$RS9U" PATH="$RS9X:$PATH" "$1" > "$RS9/o" 2>/dev/null; printf '%s' "$?" > "$RS9/rc" )
  RS9_RC="$(cat "$RS9/rc" 2>/dev/null)"; RS9_O="$(cat "$RS9/o" 2>/dev/null)"; return 0
}
_rs9_ctx() {   # -> the prompt hook's additionalContext, read with jq or python3
  if command -v jq >/dev/null 2>&1; then jq -r '.hookSpecificOutput.additionalContext // empty' < "$RS9/o" 2>/dev/null
  else python3 -c 'import json,sys
try: print(json.load(open(sys.argv[1]))["hookSpecificOutput"]["additionalContext"])
except Exception: pass' "$RS9/o" 2>/dev/null; fi
}
_rs9_up() {   # SESSION [LEDGER-FORMAT] -> the prompt hook for a prompt that routes to alpha, the session's appends written first when given
  : > "$RS9/tr/$1.jsonl"; rm -f "$RS9H/state/ledger/$1.tsv"; [ -z "${2:-}" ] || printf "$2" > "$RS9H/state/ledger/$1.tsv"
  _rs9_run "$RS9H/harness/hooks/user-prompt" "$(printf '{"session_id":"%s","transcript_path":"%s","prompt":"%s"}' "$1" "$RS9/tr/$1.jsonl" 'map the structure graph of this code')"
}
if ! command -v jq >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
  skip "cli-reach amendment U5: the prompt hook's route block, read with jq or python3" "neither jq nor python3 is on PATH"
else
  _rs9_up upbash 'alive\tpost-tool\ntool\tBash\n'
  is "cli-reach amendment U5: appends holding only tool Bash: the prompt hook exits 0 and names graphify to use now, as before (control)" \
     "$RS9_RC|$(_rs9_hl "$(_rs9_ctx)" 'Use this now: graphify')" "0|+Use this now: graphify"
  _rs9_up upnone
  is "cli-reach amendment U5: no appends file yet: graphify to use now, as before" "$RS9_RC|$(_rs9_hl "$(_rs9_ctx)" 'Use this now: graphify')" "0|+Use this now: graphify"
  _rs9_up upcli 'alive\tpost-tool\ncli\tgraphify\n'
  is "cli-reach amendment U5: appends holding cli graphify: the route block does not name graphify as the step wanted, and names claude-md-management" \
     "$RS9_RC|$(_rs9_hl "$(_rs9_ctx)" 'Use this now: claude-md-management' 'Use this now: graphify')" "0|+Use this now: claude-md-management -Use this now: graphify"
  _rs9_up upboth 'alive\tpost-tool\ncli\tgraphify\nalive\tpost-tool\ncli\tclaude-md-management\n'
  is "cli-reach amendment U5: appends holding both steps' cli lines: no step is named to use now" "$RS9_RC|$(_rs9_hl "$(_rs9_ctx)" 'Use this now:')" "0|-Use this now:"
  _rs9_up 'up.dot' 'alive\tpost-tool\ncli\tgraphify\n'
  is "cli-reach amendment U5: a session id that is not usable hands no appends: graphify to use now, as before" \
     "$RS9_RC|$(_rs9_hl "$(_rs9_ctx)" 'Use this now: graphify')" "0|+Use this now: graphify"
fi
printf 'an edit for the stop\n' >> "$RS9R/WORK.txt"
( _fx_cd "$RS9R" && env -u FELIX_ALLOW_RED -u CLAUDE_CODE_REMOTE -u CLAUDE_CODE_SESSION_ID FELIX_HOME="$RS9H" FELIX_MEMORY="$RS9M" HOME="$RS9U" \
    PATH="$RS9X:$PATH" perl "$RS9/bound.pl" 300 "$RS9H/harness/felix" gate ) > "$RS9/gate.out" 2>&1; RS9GR=$?
is "cli-reach amendment U5: the edited tree passes its gate, so Stop judges it finished (fixture control)" "$RS9GR" "0"
_rs9_stop() {   # SESSION ROUTE:STEP [LEDGER-FORMAT] [notr] -> the Stop hook with that route state and appends, a transcript unless notr
  : > "$RS9/tr/$1.jsonl"; printf '%s' "$2" > "$RS9H/state/route/$1"; rm -f "$RS9H/state/ledger/$1.tsv"
  [ -z "${3:-}" ] || printf "$3" > "$RS9H/state/ledger/$1.tsv"
  if [ "${4:-}" = notr ]; then _rs9_run "$RS9H/harness/hooks/stop" "$(printf '{"hook_event_name":"Stop","stop_hook_active":false,"session_id":"%s"}' "$1")"
  else _rs9_run "$RS9H/harness/hooks/stop" "$(printf '{"hook_event_name":"Stop","stop_hook_active":false,"session_id":"%s","transcript_path":"%s"}' "$1" "$RS9/tr/$1.jsonl")"; fi
}
_rs9_stop sbash solo:graphify 'alive\tpost-tool\ntool\tBash\n'
is "cli-reach amendment U5: Stop for a play of graphify whose appends hold only tool Bash exits 0 and says it was never used, as before (control)" \
   "$RS9_RC|$(_rs9_hl "$RS9_O" 'never used')" "0|+never used"
_rs9_stop snone solo:graphify
is "cli-reach amendment U5: and so it does with no appends file yet" "$RS9_RC|$(_rs9_hl "$RS9_O" 'never used')" "0|+never used"
_rs9_stop scli solo:graphify 'alive\tpost-tool\ncli\tgraphify\n'
is "cli-reach amendment U5: appends holding cli graphify: Stop exits 0 and lists no step skipped" "$RS9_RC|$(_rs9_hl "$RS9_O" 'never used')" "0|-never used"
_rs9_stop sboth alpha:graphify 'alive\tpost-tool\ncli\tgraphify\nalive\tpost-tool\ncli\tclaude-md-management\n'
is "cli-reach amendment U5: a two-step play both of whose steps were run: no step skipped" "$RS9_RC|$(_rs9_hl "$RS9_O" 'never used')" "0|-never used"
_rs9_stop sone alpha:graphify 'alive\tpost-tool\ncli\tgraphify\n'
is "cli-reach amendment U5: a two-step play of which graphify was run: claude-md-management is still said to be never used" \
   "$RS9_RC|$(_rs9_hl "$RS9_O" 'never used' claude-md-management)" "0|+never used +claude-md-management"
_rs9_stop snotr solo:graphify 'alive\tpost-tool\ntool\tBash\n' notr
is "cli-reach amendment U5: a Stop payload naming no transcript says nothing about skipped steps, as before" "$RS9_RC|$(_rs9_hl "$RS9_O" 'never used')" "0|-never used"
printf 'base\n' > "$RS9R/WORK.txt"

printf '\nU6: no git for it\n'
: > "$RS9/git.log"
_rs9_used "$RS9T0" graphify "$RS9LG" >/dev/null; _rs9_lib felix_route_due "$RS9T0" "$RS9PLAY" "$RS9LG" >/dev/null
_rs9_lib felix_route_skipped "$RS9T0" "$RS9PLAY" "$RS9LB" >/dev/null
is "cli-reach amendment U6: felix_route_step_used, felix_route_due and felix_route_skipped handed a ledger start no git" "$(awk 'END { print NR }' "$RS9/git.log")" "0"
