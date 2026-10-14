# h: the host records. One worktree per case, each at main's tip on a branch
# never pushed, so what differs between them is only what the records say.
_ibnew h
IB_HT="$(_ibq -C "$IB/h" rev-parse HEAD)"
IB_EMO="$IB/hw/e$(printf '\360\237\230\200')x"
IB_LPAD="$(_ibp 'padding to push the record name past two hundred characters' 170)"; IB_LPAD="$(_ibenc "$IB_LPAD")"
IB_LONG1="$IB/long/one-$IB_LPAD"; IB_LONG2="$IB/long/two-$IB_LPAD"
mkdir -p "$IB/hsym"; ln -s "$IB/hsym" "$IB/hl"
_ibhw() { _ibg -C "$IB/h" worktree add -q -b "$2" "$1" "$IB_HT"; }
_ibhw "$IB/hw/w.t_1" h-enc; _ibhw "$IB_EMO" h-emo; _ibhw "$IB/hl/sym" h-sym
_ibhw "$IB_LONG1" h-long1; _ibhw "$IB_LONG2" h-long2
for _ibn in act two blk blk2 ask ans-a ans-b ans-c sa-fence sa-span sa-quote sa-bq ng-a ng-b ng-c ng-d q-a q-b \
            bad-empty bad-cut bad-nojson side big-a big-b par ord ll cost notime mf-a mf-b blk-cost blk-human blk-meta two2 mf-cut; do
  _ibhw "$IB/hw/$_ibn" "h-$_ibn"
done
_ibhw "$IB/h/.claude/worktrees/agent-a1b2c3" agent-a1b2c3; _ibhw "$IB/h/.claude/worktrees/agent-a9b9c9" agent-a9b9c9
_ibmk 300 "$IB/h" "$IB_HT" 'act, five hours ago' act.txt act; _ibg -C "$IB/hw/act" reset -q --hard "$IBC"
printf 'ord\n' > "$IB/hw/ord/ord.txt"; _ibci "$IB/hw/ord" 'ord, nowhere else'; printf 'more\n' > "$IB/hw/ord/ord2.txt"
_ibg -C "$IB/h" remote set-url origin git@github.com:acme/hotel.git
IB_SYM="$(_ibq -C "$IB/h" worktree list --porcelain | LC_ALL=C awk '/^worktree .*\/sym$/ { sub(/^worktree /, ""); print }')"

# h's records, written just before its runs. Ages are minutes.
_ibh_ask() {  # worktree sid final-text: a session two minutes of talk, ending on that text
  _ibsess "$IB/hw/$1" "$2"; _ib_h 32 'report back'; _ib_a 30 "$3"; }
_ibh_two() {
  _ibsess "$IB/hw/two" s-old; _ib_h 101 'start'; _ib_a 100 'Done.'; _ibage "$IB_F" 100
  _ibsess "$IB/hw/two" s-new; _ib_h 71 'again'; _ib_a 70 'Done.'; _ibage "$IB_F" 70; }
_ibh_records() {
  IB_BR=""
  _ibsess "$IB/hw/w.t_1" s-enc; _ib_h 11 'go'; _ib_a 10 'Done.'; _ibage "$IB_F" 10
  _ibopen "$IBP/$(_ibenc "$IB/hw/e")--x/s-emo.jsonl" s-emo; _ib_h 11 'go'; _ib_a 10 'Done.'; _ibage "$IB_F" 10
  _ibsess "$IB/hsym/sym" s-sym; _ib_h 11 'go'; _ib_a 10 'Done.'; _ibage "$IB_F" 10
  _ibx="$(_ibenc "$IB_LONG1")"; _ibopen "$IBP/${_ibx:0:200}-abc123/s-long1.jsonl" s-long1; _ib_h 11 'go'; _ib_a 10 'Done.'; _ibage "$IB_F" 10
  _ibx="$(_ibenc "$IB_LONG2")"; _ibopen "$IBP/${_ibx:0:200}-abc123/s-long2a.jsonl" s-long2a; _ib_h 11 'go'; _ib_a 10 'Done.'; _ibage "$IB_F" 10
  _ibopen "$IBP/${_ibx:0:200}-def456/s-long2b.jsonl" s-long2b; _ib_h 11 'go'; _ib_a 10 'Done.'; _ibage "$IB_F" 10
  _ibsess "$IB/hw/act" s-act; _ib_h 302 'go'; _ib_a 300 'Working.'; _ibage "$IB_F" 300
  mkdir -p "$IBP/$(_ibenc "$IB/hw/act")/s-act/tool-results/deep"
  printf 'x\n' > "$IBP/$(_ibenc "$IB/hw/act")/s-act/tool-results/deep/x.txt"; _ibage "$IBP/$(_ibenc "$IB/hw/act")/s-act/tool-results/deep/x.txt" 2
  _ibh_two
  for _ibn in blk blk2; do
    _ibsess "$IB/hw/$_ibn" "s-$_ibn"; _ib_h 40 'watch it'
    _ib_tu 39 toolu_0 Bash '{"command":"date","description":"Read the clock"}'; _ib_tr 38 toolu_0 ok
    _ib_tu 35 toolu_1 Bash '{"command":"watch-the-ledger","description":"Watch the ledger"}'; _ibage "$IB_F" 35
  done
  mkdir -p "$IBP/$(_ibenc "$IB/hw/blk2")/s-blk2/subagents"
  printf '{}\n' > "$IBP/$(_ibenc "$IB/hw/blk2")/s-blk2/subagents/agent-x.jsonl"; _ibage "$IBP/$(_ibenc "$IB/hw/blk2")/s-blk2/subagents/agent-x.jsonl" 3
  _ibh_ask ask s-ask "I've pushed the branch.\\n\\nShall I merge it?"; _ibage "$IB_F" 30
  _ibh_ask ans-a s-ans-a 'It is ready. Shall I merge it?'; _ib_h 29 'go ahead'; _ibage "$IB_F" 29
  _ibh_ask ans-b s-ans-b 'It is ready. Shall I merge it?'; _ib_tr 29 toolu_z ok
  _ib_u 29 '"<system-reminder>x</system-reminder><command-name>/foo</command-name>"'; _ibage "$IB_F" 29
  _ibh_ask ans-c s-ans-c 'It is ready. Shall I merge it?'; _ib_u 29 '"Stop hook feedback: keep going"' ',"isMeta":true'; _ibage "$IB_F" 29
  _ibh_ask sa-fence s-sa-fence 'The log said:\n```\nready?\n```\nThat is the whole log.'; _ibage "$IB_F" 30
  _ibh_ask sa-span  s-sa-span  'The status line now reads `merge?` and that is all.'; _ibage "$IB_F" 30
  _ibh_ask sa-quote s-sa-quote 'The reviewer wrote \"should I?\" in the thread.'; _ibage "$IB_F" 30
  _ibh_ask sa-bq    s-sa-bq    '> Want me to merge?\nThat was the old note.'; _ibage "$IB_F" 30
  _ibh_ask ng-a s-ng-a 'I wrote an essay yesterday.'; _ibage "$IB_F" 30
  _ibh_ask ng-b s-ng-b 'Nothing here needs your input.'; _ibage "$IB_F" 30
  _ibh_ask ng-c s-ng-c 'Nothing broke. Your call on the merge.'; _ibage "$IB_F" 30
  _ibh_ask ng-d s-ng-d 'The tests pass. Your call.'; _ibage "$IB_F" 30
  _ibh_ask q-a s-q-a 'All green. Ready to merge?**)'; _ibage "$IB_F" 30
  _ibh_ask q-b s-q-b 'Ready?\n\nThe tests pass.\n\nThe branch is pushed.\n\nThe notes are filed.'; _ibage "$IB_F" 30
  _ibsess "$IB/hw/bad-empty" s-bad-empty; _ibage "$IB_F" 30
  _ibsess "$IB/hw/bad-cut" s-bad-cut; _ib_a 30 'This line is cut before it ends, mid-string.'
  _ibx="$(cat "$IB_F")"; printf '%s' "${_ibx:0:150}" > "$IB_F"; _ibage "$IB_F" 30
  _ibsess "$IB/hw/bad-nojson" s-bad-nojson; printf 'not json at all\n' > "$IB_F"; _ibage "$IB_F" 30
  _ibh_ask side s-side 'Done.'; _ib_a 30 'Shall I continue?' true
  printf -v _ibx '{"type":"system","subtype":"note","message":{"role":"assistant","content":[{"type":"text","text":"Is it?"}]},"sessionId":"s-side","timestamp":"%s"}' "$(_ibts 30)"
  _ib_raw "$_ibx"; _ibage "$IB_F" 30
  # big-a: an asking text, then 300 tool call and result pairs of about 1.3
  # KiB each, so the ask lies more than 256 KiB from the end.
  _ibopen "$IB/pair.tmp" s-big-a
  _ibx="$(_ibp 'filler for a large tool call that carries no text at all' 1000)"
  _ib_tu 30 toolu_big Bash "{\"command\":\"$_ibx\"}"; _ib_tr 30 toolu_big "$_ibx"
  _ibsess "$IB/hw/big-a" s-big-a; _ib_h 32 'start'; _ib_a 31 'Shall I start?'
  LC_ALL=C awk '{ l[NR] = $0 } END { for (i = 1; i <= 300; i++) for (j = 1; j <= NR; j++) print l[j] }' "$IB/pair.tmp" >> "$IB_F"
  _ibage "$IB_F" 30
  _ibsess "$IB/hw/big-b" s-big-b
  for _ibn in 1 2 3; do _ib_tu 30 "toolu_c$_ibn" Bash '{"command":"true"}'; _ib_tr 30 "toolu_c$_ibn" ok; done
  _ibage "$IB_F" 30
  _ibsess "$IB/h" s-boss; _ib_h 201 'spawn them'; _ib_a 200 'Spawned the agents.'; _ibage "$IB_F" 200
  _ibx="$IBP/$(_ibenc "$IB/h")/s-boss/subagents"; mkdir -p "$_ibx"
  printf '{"agentType":"general-purpose","description":"write the parser","worktreePath":"%s"}\n' "$IB/h/.claude/worktrees/agent-a1b2c3" > "$_ibx/agent-a1b2c3.meta.json"
  printf '{}\n' > "$_ibx/agent-a1b2c3.jsonl"; _ibage "$_ibx/agent-a1b2c3.jsonl" 2
  printf '{"agentType":"general-purpose","description":"another one","worktreePath":"/elsewhere/agent-a9b9c9"}\n' > "$_ibx/agent-a9b9c9.meta.json"
  printf '{}\n' > "$_ibx/agent-a9b9c9.jsonl"; _ibage "$_ibx/agent-a9b9c9.jsonl" 2
  _ibsess "$IB/hw/par" s-par; _ib_h 31 'look into it'; _ib_a 30 'Done.'; _ibage "$IB_F" 30
  _ibopen "$IBP/$(_ibenc "$IB/hw/par")/s-par/subagents/agent-y.jsonl" agent-y
  _ib_a 30 'Shall I proceed?' true; _ib_tu 30 toolu_y Bash '{"command":"wait"}'; _ibage "$IB_F" 30
  _ibsess "$IB/hw/ord" s-ord; _ib_h 2 'go'; _ib_a 1 'Done.'; _ibage "$IB_F" 1
  _ibsess "$IB/hw/ll" s-ll; _ib_h 2 'go'; _ib_a 1 'Done.'; _ibage "$IB_F" 1
  _ibsess "$IB/hw/cost" s-cost; _ib_h 182 'go'; _ib_a 180 'Done.'
  _ib_raw '{"type":"cost-state","costUSD":0.25,"sessionId":"s-cost"}'; _ibage "$IB_F" 1
  _ibsess "$IB/hw/notime" s-notime; _ib_h none 'go'; _ib_a none 'Done.'; _ibage "$IB_F" 2
  _ibh_ask mf-a s-mf-a 'The build is green. Shall I tag it?'; _ibage "$IB_F" 30
  _ibh_ask mf-b s-mf-b 'Done.'
  printf -v _ibx '{"type":"attachment","attachment":{"type":"note"},"message":{"role":"assistant","content":[{"type":"text","text":"Shall I go on?"}]},"sessionId":"s-mf-b","timestamp":"%s"}' "$(_ibts 30)"
  _ib_raw "$_ibx"; _ibage "$IB_F" 30
  # A pending call 35 minutes old, then a bookkeeping line that touched the file a minute ago.
  _ibsess "$IB/hw/blk-cost" s-blk-cost; _ib_h 40 'watch it'; _ib_tu 35 toolu_bc Bash '{"command":"watch-the-ledger"}'
  _ib_raw '{"type":"cost-state","costUSD":0.25,"sessionId":"s-blk-cost"}'; _ibage "$IB_F" 1
  # The same call, answered 34 minutes ago by the person's own text.
  _ibsess "$IB/hw/blk-human" s-blk-human; _ib_h 40 'watch it'; _ib_tu 35 toolu_bh Bash '{"command":"watch-the-ledger"}'
  _ib_h 34 'never mind that'; _ibage "$IB_F" 34
  # The same call, followed by a user record that is no human text ("isMeta":true): a record follows it all the same.
  _ibsess "$IB/hw/blk-meta" s-blk-meta; _ib_h 40 'watch it'; _ib_tu 35 toolu_bm Bash '{"command":"watch-the-ledger"}'
  _ib_u 34 '"Stop hook feedback: keep going"' ',"isMeta":true'; _ibage "$IB_F" 34
  # Two sessions, the newer one's file the older: the other's file was touched last by a bookkeeping line.
  _ibsess "$IB/hw/two2" s-rt-old; _ib_h 91 'start'; _ib_a 90 'Done.'
  _ib_raw '{"type":"cost-state","costUSD":0.25,"sessionId":"s-rt-old"}'; _ibage "$IB_F" 2
  _ibsess "$IB/hw/two2" s-rt-new; _ib_h 32 'again'; _ib_a 31 'Done.'; _ibage "$IB_F" 30
  # A last line cut before its end, holding an asking text, after a whole final text that asks nothing.
  _ibh_ask mf-cut s-mf-cut 'Done.'
  printf -v _ibx '{"message":{"role":"assistant","content":[{"type":"text","text":"Shall I merge it?"}]},"sessionId":"s-mf-cut","timestamp":"%s"' "$(_ibts 29)"
  printf '%s' "$_ibx" >> "$IB_F"; _ibage "$IB_F" 29
}

# ---- r's records: chips, PR owners, and sessions elsewhere ---------------
IB_P95="$(_ibp 'Theta task: point the README badge at the current build, and test that it fails on a branch that is gone.' 130)"
IB_P18="$(_ibp 'Iota task: give the exporter a stable row order and test two runs over one input for the same bytes.' 130)"
IB_P96="$(_ibp 'Kappa task: retire the old config loader alias once one release has carried the new name.' 130)"
IB_P97="$(_ibp 'Lambda task: make the scheduler print the jobs it would start in a dry run and start none.' 130)"
IB_P99="$(_ibp 'Mu task: teach the report to name the file each total came from, with a test on two files.' 130)"
IB_P100="$(_ibp 'Nu task: move the retry budget into the settings file and keep the default at three.' 130)"
IB_PT119="$(_ibp 'Xi task: make the sorter stable and test equal keys on two inputs.' 130)"
IB_PT120="$(_ibp 'Omicron task: log each retry once and test the count it reports.' 130)"
# Two prompts of 130 decoded characters with two \n escapes in their first 50,
# so the JSON is two bytes longer than the text before character 120.
IB_P115A="Kappa line\\nLambda line\\n$(_ibp 'mu nu xi omicron pi rho sigma tau upsilon phi chi psi omega' 107)"
IB_P115B="Delta line\\nSigma lines\\n$(_ibp 'alpha beta gamma delta epsilon zeta eta theta iota kappa' 107)"
IB_NEAR="${IB_P115A:0:121}#${IB_P115A:122}"              # decoded character 120 changed
IB_HIT="${IB_P115B:0:122} and then something else entirely"  # the first 120 decoded, then other text
_ibr_records() {
  IB_BR=""
  _ibsess "$IBR" s-chip; _ib_h 11 'file the chips'
  _ib_chip 10 toolu_9 task_ab12cd34 'Fix the README badge' "$IB_P95"
  _ib_chip 10 toolu_18 task_18aaaaaa 'Two\nlines\tand a tab' "$IB_P18"
  _ib_chip 10 toolu_96 task_9600aaaa 'Withdrawn later' "$IB_P96"
  _ib_tu 10 toolu_96d mcp__ccd_session__dismiss_task '{"task_id":"task_9600aaaa"}'; _ib_tr 10 toolu_96d 'error: already started'
  _ib_chip 10 toolu_97 task_9700aaaa 'Started behind a reminder' "$IB_P97"
  _ib_chip 10 toolu_115a task_115aaaaa 'Changed at character 120' "$IB_P115A"
  _ib_chip 10 toolu_115b task_115bbbbb 'Equal through character 120' "$IB_P115B"
  # Titles cut at 120 bytes on a whole character: é is two bytes, so 119 a's then é
  # ends the cut at 119, and 118 a's then é fits in exactly 120.
  printf -v _ibx '%0119d' 0; _ibx="${_ibx//0/a}é and then a good deal more title"
  _ib_chip 10 toolu_t119 task_t119aaaa "$_ibx" "$IB_PT119"
  printf -v _ibx '%0118d' 0; _ibx="${_ibx//0/a}é and then a good deal more title"
  _ib_chip 10 toolu_t120 task_t120bbbb "$_ibx" "$IB_PT120"
  _ib_a 10 'Filed.'; _ibage "$IB_F" 10
  _ibsess "$IBR" s-att
  printf -v _ibx '{"type":"attachment","attachment":{"type":"deferred_tools","tools":[{"name":"mcp__ccd_session__spawn_task","description":"Flag an issue"},{"name":"mcp__ccd_session__dismiss_task","description":"Withdraw one"}]},"sessionId":"s-att","timestamp":"%s"}' "$(_ibts 6)"
  _ib_raw "$_ibx"; _ib_h 6 'Noted (task_id: task_ffff0000).'; _ib_a 5 'Noted.'; _ibage "$IB_F" 5
  # Who worked on which PR's branch: s-o2's records sit in s-o3's file, as a
  # resumed session's file copies its predecessor's.
  IB_BR=pr-only;   _ibsess "$IBR" s-o1; _ib_h 51 'work on it'; _ib_a 50 'Working on it.'; _ibage "$IB_F" 50
  _ibsess "$IBR" s-o3; IB_SID=s-o2; _ib_h 21 'carry on'; _ib_a 20 'Carried on.'
  IB_SID=s-o3; IB_BR=main; _ib_h 6 'resume'; _ib_a 5 'Resumed.'; _ibage "$IB_F" 5
  IB_BR=pr-only-x; _ibsess "$IBR" s-o5; _ib_h 3 'x'; _ib_a 2 'X.'; _ibage "$IB_F" 2
  IB_BR=stale-pr;  _ibsess "$IBR" s-o4; _ib_h 91 'stale'; _ib_a 90 'Stale.'; _ibage "$IB_F" 90
  IB_BR=forked;    _ibsess "$IBR" s-o6; _ib_h 4 'fork'; _ib_a 3 'Forked.'; _ibage "$IB_F" 3
  # The owner is the session of the newest user or assistant record naming the head. (a) The
  # newest file is not it: s-ow-a1 was touched a minute ago but wrote its own-a records 80 minutes
  # ago. (b) An owner whose own file holds a newer record on another branch is live though its
  # own-b record is two hours old. (c) An attachment record naming the head, newer than every
  # user and assistant one, is no owner's.
  IB_BR=own-a; _ibsess "$IBR" s-ow-a1; _ib_h 81 'start'; _ib_a 80 'Started.'
  IB_BR=main; _ib_h 4 'something else'; _ib_a 3 'Elsewhere.'; _ibage "$IB_F" 1
  IB_BR=own-a; _ibsess "$IBR" s-ow-a2; _ib_h 41 'also'; _ib_a 40 'Also.'; _ibage "$IB_F" 40
  IB_BR=own-b; _ibsess "$IBR" s-ow-b; _ib_h 121 'start'; _ib_a 120 'Started.'
  IB_BR=other-b; _ib_h 4 'moved on'; _ib_a 3 'Moved on.'; _ibage "$IB_F" 3
  IB_BR=own-c; _ibsess "$IBR" s-ow-c1; _ib_h 71 'early'; _ib_a 70 'Early.'
  printf -v _ibx '{"type":"attachment","attachment":{"type":"note"},"message":{"role":"assistant","content":[{"type":"text","text":"Noted."}]},"gitBranch":"own-c","sessionId":"s-ow-c1","timestamp":"%s"}' "$(_ibts 5)"
  _ib_raw "$_ibx"; _ibage "$IB_F" 5
  IB_BR=own-c; _ibsess "$IBR" s-ow-c2; _ib_h 31 'later'; _ib_a 30 'Later.'; _ibage "$IB_F" 30
  IB_BR=main;      _ibsess "$IBR" s-pl; _ib_h 2 'link'
  printf -v _ibx '{"type":"pr-link","prNumber":12,"prUrl":"https://github.com/acme/widget/pull/12","prRepository":"acme/widget","sessionId":"s-pl","timestamp":"%s"}' "$(_ibts 1)"
  _ib_raw "$_ibx"; _ib_a 1 'Linked.'; _ibage "$IB_F" 1
  IB_BR=""
  _ibopen "$IBP/-elsewhere/s-early.jsonl" s-early; _ib_h 20 "$IB_P95"; _ib_a 20 'Done.'; _ibage "$IB_F" 20
  _ibopen "$IBP/-elsewhere/s-run.jsonl" s-run
  printf -v _ibx '[{"type":"text","text":"<system-reminder>r</system-reminder>"},{"type":"text","text":"%s"}]' "$IB_P97"
  _ib_u 5 "$_ibx"; _ib_a 4 'On it.'; _ibage "$IB_F" 4
  _ibopen "$IBP/-elsewhere/s-late.jsonl" s-late; _ib_h 5 'hello'; _ib_a 5 'Hi.'; _ib_h 4 "$IB_P95"; _ib_a 4 'On it.'; _ibage "$IB_F" 4
  _ibopen "$IBP/-elsewhere/s-near.jsonl" s-near; _ib_h 5 "$IB_NEAR"; _ib_a 4 'On it.'; _ibage "$IB_F" 4
  _ibopen "$IBP/-elsewhere/s-hit.jsonl" s-hit; _ib_h 5 "$IB_HIT"; _ib_a 4 'On it.'; _ibage "$IB_F" 4
  _ibsess "$IBR/.claude/worktrees/gone-wt" s-gone; _ib_h 31 'note it'
  _ib_chip 30 toolu_100 task_100aaaaa 'From a removed worktree' "$IB_P100"; _ib_a 30 'Noted.'; _ibage "$IB_F" 30
}

# ---- r: the runs ---------------------------------------------------------
# RUN1 reads r and r2 with gh, the git spy first on PATH and a memory root
# set; RUN2 under --no-gh; RUN3 under --no-host; RUN4 with a records root
# that holds nothing.
_ibr_records
rm -f "$IB/gh.log" "$IB/git.log" "$IB/net.log"
IB_SNAP15="$(_ibsnap "$IB/home"; _ibsnap "$IB/mem")"; : > "$IB/run1.mark"
_ibrun RUN1 --path "$IB/spy:$IB/stub:$PATH" --env "FELIX_MEMORY=$IB/mem" -- inventory --repo "$IBR" --repo "$IB/r2" --tsv
IB_SNAP15B="$(_ibsnap "$IB/home"; _ibsnap "$IB/mem")"; IB_NEW15="$(find "$IB/home" "$IB/mem" -newer "$IB/run1.mark" -print | LC_ALL=C awk 'NR <= 3' | tr '\n' ' ')"
mv "$IB/gh.log" "$IB/gh1.log" 2>/dev/null; mv "$IB/git.log" "$IB/git1.log" 2>/dev/null
IB_TMP1="$(ls -A "$IB/tmp" | tr '\n' ' ')"
_ibrun RUN2 -- inventory --repo "$IBR" --tsv --no-gh
IB_GH2="$([ -e "$IB/gh.log" ] && echo 'gh ran' || echo 'gh never ran')"
_ibrun RUN3 -- inventory --repo "$IBR" --tsv --no-host
_ibrun RUN4 --home "$IB/home0" -- inventory --repo "$IBR" --tsv

# ---- §2: the command line ------------------------------------------------
is  "inventory A1: felix inventory runs from a plain clone with no home and no memory root, exits 0 and prints eight-column rows" \
    "$(_ibrc RUN4) $(LC_ALL=C awk -F'\t' 'NF != 8 { b++ } END { print b + 0 }' "$(_ibo RUN4)") $([ -e "$IB/home0/.felix-home" ] && echo home || echo nohome)" "0 0 nohome"
is  "inventory A1: and at least five of its rows are cover rows" "$(( $(_ibcount RUN4 cover) >= 5 ))" "1"
_ibrun HELP0 -- ; _ibrun HELP1 -- help
_ibhelp() { cat "$(_ibo "$1")" "$IB/runs/$1.err" | LC_ALL=C awk '/^[[:space:]]*felix inventory/ { n++ } END { print n + 0 }'; }
is  "inventory A2: felix's help, with no arguments and as felix help, has one line that begins felix inventory" "$(_ibhelp HELP0) $(_ibhelp HELP1)" "1 1"
_ibrun HELPH -- inventory -h; _ibrun HELPL -- inventory --help
_ibusage() { case "$(cat "$(_ibo "$1")")" in *"felix inventory"*) case "$(cat "$(_ibo "$1")")" in *--repo*) printf usage; return ;; esac ;; esac; printf 'no usage'; }
is  "inventory A3: felix inventory -h and --help print the usage to stdout, exit 0 and write nothing to stderr" \
    "$(_ibrc HELPH) $(_ibusage HELPH) [$(cat "$IB/runs/HELPH.err")] $(_ibrc HELPL) $(_ibusage HELPL) [$(cat "$IB/runs/HELPL.err")]" "0 usage [] 0 usage []"
for _ibk in 1 2 3 4 5 6 7 8 9; do
  case "$_ibk" in
    1) _iba=(--live abc);     _ibl='--live abc' ;;
    2) _iba=(--live -1);      _ibl='--live -1' ;;
    3) _iba=(--live 1.5);     _ibl='--live 1.5' ;;
    4) _iba=(--live 1234567); _ibl='--live 1234567, seven digits' ;;
    5) _iba=(--live '');      _ibl='--live with an empty value' ;;
    6) _iba=(--blocked x);    _ibl='--blocked x' ;;
    7) _iba=(--days ' 3');    _ibl="--days ' 3'" ;;
    8) _iba=(--frobnicate);   _ibl='--frobnicate' ;;
    9) _iba=(--repo);         _ibl='--repo with no value' ;;
  esac
  _ibrun "A4_$_ibk" -- inventory --tsv "${_iba[@]}"
  _ibf="$(LC_ALL=C awk 'NR == 1' "$IB/runs/A4_$_ibk.err")"
  _ibu=no; case "$(cat "$IB/runs/A4_$_ibk.err")" in *"felix inventory"*) _ibu=yes ;; esac
  _ibr=no; case "$_ibf" in *"${_iba[0]}"*) _ibr=yes ;; esac
  [ -n "${_iba[1]:-}" ] && case "$_ibf" in *"${_iba[1]}"*) _ibr=yes ;; esac
  _ibsyn=no; case "$_ibf" in *--no-gh*--no-host*) _ibsyn=yes ;; esac
  is  "inventory A4: a bad argument ($_ibl) exits 2, prints nothing, and says why on one line ahead of the usage on stderr" \
      "$(_ibrc "A4_$_ibk") $([ -s "$(_ibo "A4_$_ibk")" ] && echo stdout || echo nostdout) usage=$_ibu named=$_ibr synopsis=$_ibsyn" "2 nostdout usage=yes named=yes synopsis=no"
done

# ---- §1: read-only, scratch and network, over RUN1 -----------------------
_ibgitchk() {  # one finding per git call that breaks §1
  LC_ALL=C awk -F'|' -v want="$2" '
    { env = $1; a = substr($0, length($1) + 2); n = split(a, w, " "); i = 1; pre = " "; ver = 0
      while (i <= n) {
        if (w[i] == "-C" || w[i] == "-c") { pre = pre w[i] " " w[i + 1] " "; i += 2; continue }
        if (w[i] ~ /^-/) { pre = pre w[i] " "; if (w[i] == "--version") ver = 1; i++; continue }
        break }
      cmd = (i <= n) ? w[i] : ""; rest = " "; for (k = i + 1; k <= n; k++) rest = rest w[k] " "
      if (ver || cmd == "version") next
      if (want == "count") { c++; next }
      if (want == "sig") { if (!index(pre, " -c log.showSignature=false ")) print NR ": no -c log.showSignature=false"; next }
      if (env != "GIT_NO_LAZY_FETCH=1") print NR ": no GIT_NO_LAZY_FETCH=1"
      if (!index(pre, " --no-optional-locks ")) print NR ": no --no-optional-locks"
      if (!index(pre, " --literal-pathspecs ")) print NR ": no --literal-pathspecs"
      if (!index(pre, " -c core.fsmonitor=false ")) print NR ": no -c core.fsmonitor=false"
      if (cmd == "fetch" || cmd == "write-tree" || cmd == "update-index") print NR ": runs " cmd
      if (cmd == "stash" && index(rest, " create ")) print NR ": runs stash create"
      if (cmd == "merge-tree" && index(rest, " --write-tree ")) print NR ": runs merge-tree --write-tree"
      if (cmd == "hash-object" && (index(rest, " -w ") || index(rest, " --write "))) print NR ": runs hash-object -w"
      if (cmd == "status" && !index(rest, " --ignore-submodules=dirty ")) print NR ": status without --ignore-submodules=dirty" }
    END { if (want == "count") print c + 0 }' "$1"; }
_ibgitn="$(_ibgitchk "$IB/git1.log" count 2>/dev/null || echo 0)"
is  "inventory A11: every git call carries GIT_NO_LAZY_FETCH=1, --no-optional-locks, --literal-pathspecs and -c core.fsmonitor=false before its subcommand, none fetches or writes, and every status ignores dirty submodules" \
    "$([ "${_ibgitn:-0}" -ge 10 ] && echo "10 or more calls" || echo "${_ibgitn:-0} calls") $(_ibgitchk "$IB/git1.log" all 2>&1 | LC_ALL=C awk 'NR <= 4' | tr '\n' ';')" "10 or more calls "
is  "inventory N8: and every one carries -c log.showSignature=false, so a user's showSignature runs no gpg" \
    "$([ "${_ibgitn:-0}" -ge 10 ] && echo "10 or more calls" || echo "${_ibgitn:-0} calls") $(_ibgitchk "$IB/git1.log" sig 2>&1 | LC_ALL=C awk 'NR <= 4' | tr '\n' ';')" "10 or more calls "
_ibghw() { LC_ALL=C awk -F'|' -v r="$2" 'index($2, "-R " r " ") { n++; s = $5; c = $6; sub(/\/[^\/]*$/, "", s); sub(/\/[^\/]*$/, "", c)
             printf "%s%s", (n > 1 ? ";" : ""), ($5 != "" && $6 != "" && s == c ? s : "[" $5 "|" $6 "]") } END { if (!n) printf "no call" }' "$1"; }
_ibx="$(_ibghw "$IB/gh1.log" acme/widget)"
case "$_ibx" in
  "no call"|*"["*) _ibr="$_ibx" ;;
  *) _ibp1="${_ibx%%;*}"
     case "$_ibp1" in "$IBR"/*|"$IBO"/*|"$IB/home"/*) _ibr="under a repository or HOME: $_ibp1" ;;
       *) if [ "$_ibx" != "$_ibp1;$_ibp1" ]; then _ibr="two calls, two parents or not two: $_ibx"
          elif [ -e "$_ibp1" ]; then _ibr="the scratch is still there: $_ibp1"; else _ibr="gone"; fi ;; esac ;;
esac
is  "inventory A13: gh's two calls for a repository keep their state and cache in one scratch directory outside every repository and HOME, gone after the run" "$_ibr" "gone"
is  "inventory A13: and TMPDIR is empty after the run" "$IB_TMP1" ""
# Spec section 2, exit 1: when no scratch directory can be made, nothing on stdout and one line saying why.
mkdir -p "$IB/stubmk"; printf '#!/bin/sh\nexit 1\n' > "$IB/stubmk/mktemp"; chmod +x "$IB/stubmk/mktemp"
_ibrun NOSCR --path "$IB/stubmk:$IB/stub:$PATH" -- inventory --repo "$IBR" --tsv
is  "inventory RV11: when no scratch directory can be made the run exits 1, prints nothing, says why on one stderr line, naming the scratch, and leaves no directory behind" \
    "$(_ibrc NOSCR) $(LC_ALL=C awk 'END { print NR + 0 }' "$(_ibo NOSCR)") $(LC_ALL=C awk 'END { print NR + 0 }' "$IB/runs/NOSCR.err") $(ls -A "$IB/tmp" | LC_ALL=C awk 'END { print NR + 0 }') $(LC_ALL=C awk 'tolower($0) ~ /scratch|mktemp|temporary/ { f = 1 } END { print (f ? "why" : "no why") }' "$IB/runs/NOSCR.err")" "1 0 1 0 why"
is  "inventory A15: nothing under HOME or the memory root changed, and the run read the records: it printed a chip row" \
    "$([ "$IB_SNAP15" = "$IB_SNAP15B" ] && echo same || echo changed) [$IB_NEW15] $(( $(_ibcount RUN1 chip "$IBRR") > 0 ))" "same [] 1"
_ibx="$(LC_ALL=C awk -F'|' '{ a = $2; gsub(/  +/, " ", a); printf "%s%s", (NR > 1 ? ";" : ""), a }' "$IB/gh1.log" 2>/dev/null)"
is  "inventory A16, N6: gh is asked pr list twice per repository, in --repo order, with the stated arguments" "$_ibx" \
    "pr list -R acme/widget --state all --limit 1000 --json number,state,headRefName,headRefOid,updatedAt,isCrossRepository,baseRefName;pr list -R acme/widget --state open --limit 1000 --json number,labels,mergeable,isDraft,statusCheckRollup;pr list -R acme/other --state all --limit 1000 --json number,state,headRefName,headRefOid,updatedAt,isCrossRepository,baseRefName;pr list -R acme/other --state open --limit 1000 --json number,labels,mergeable,isDraft,statusCheckRollup"
is  "inventory A16: each gh call runs with GH_NO_UPDATE_NOTIFIER=1 and GH_PROMPT_DISABLED=1, and nothing else touches the network" \
    "$(LC_ALL=C awk -F'|' '$3 != "1" || $4 != "1" { b++ } END { print NR " calls, " b + 0 " without" }' "$IB/gh1.log" 2>/dev/null) $([ -e "$IB/net.log" ] && echo network || echo quiet)" "4 calls, 0 without quiet"
is  "inventory A17: --no-gh runs gh zero times, and cover prs says --no-gh" "$IB_GH2 | $(_ibcol RUN2 cover prs 8)" "gh never ran | --no-gh"

# ---- §5: output shape ----------------------------------------------------
_ibshape() { LC_ALL=C awk -F'\t' '
  BEGIN { split("cover worktree orphan branch remote pr handoff chip", k, " "); for (i = 1; i <= 8; i++) ok[k[i]] = 1 }
  NF != 8 { printf "line %d has %d fields; ", NR, NF; next }
  { for (i = 1; i <= 8; i++) if ($i == "") { printf "line %d field %d is empty; ", NR, i; next }
    if (!($1 in ok)) printf "line %d is of kind %s; ", NR, $1 }
  END { if (!NR) printf "no rows" }' "$1"; }
is  "inventory A18: every row has eight fields, none empty, of a kind the contract names, with no header and no row of kind repo" "$(_ibshape "$(_ibo RUN1)")" ""
is  "inventory A18, A43: a worktree whose path holds a tab gets one row, its ref the path with the tab as a space" "$(_ibcol RUN1 worktree "$IB/wts/t ab" 1)" "worktree"
is  "inventory A18: a chip title holding a line break and a tab prints on its one line, each as a space" "$(_ibcol RUN1 chip task_18aaaaaa 8)" "Two lines and a tab"
_ibrank() { LC_ALL=C awk -F'\t' -v p="$2" '
  BEGIN { split("cover worktree branch remote pr orphan handoff chip", k, " "); for (i = 1; i <= 8; i++) r[k[i]] = i }
  $2 == p { if (r[$1] < l) printf "%s %s after rank %d; ", $1, $3, l; l = r[$1]; seen[$1] = 1 }
  END { for (i = 1; i <= 8; i++) if (!(k[i] in seen)) printf "no %s row; ", k[i] }' "$1"; }
is  "inventory A19: a repository's rows come cover, worktree, branch, remote, pr, orphan, handoff, chip, and this one has each" "$(_ibrank "$(_ibo RUN1)" "$IBRR")" ""
is  "inventory A19: worktree rows come in git worktree list order" \
    "$(LC_ALL=C awk -F'\t' -v p="$IBRR" '$2 == p && $1 == "worktree" { printf "%s;", $3 }' "$(_ibo RUN1)")" \
    "$(_ibq -C "$IBR" worktree list --porcelain | LC_ALL=C awk '/^worktree / { sub(/^worktree /, ""); gsub(/\t/, " "); printf "%s;", $0 }')"
_ibcovers() { LC_ALL=C awk -F'\t' -v p="$2" '$2 == p && $1 == "cover" { printf "%s%s", s, $3; s = " "; if ($5 != "-" || $6 != "-" || $7 != "-") printf "(%s|%s|%s)", $5, $6, $7 }' "$1"; }
is  "inventory A20: each repository read has five cover rows, default prs sessions chips objects, with owner, age and content -" \
    "$(_ibcovers "$(_ibo RUN1)" "$IBRR") / $(_ibcovers "$(_ibo RUN1)" "$IBR2")" "default prs sessions chips objects / default prs sessions chips objects"
is  "inventory A21: age_h is the floor of whole hours: a tip committed 50h40m ago is 50" "$(_ibcol RUN1 branch aged 6)" "50"
is  "inventory A7: rows print in --repo order: every row of the first repository comes before the second's" \
    "$(LC_ALL=C awk -F'\t' -v a="$IBRR" -v b="$IBR2" '$2 == b { s = 1 } $2 == a && s { x = 1 } END { print (s && !x) ? "in order" : "not in order" }' "$(_ibo RUN1)")" "in order"

# ---- §5.1: cover rows ----------------------------------------------------
_ib8() { _ibq -C "$1" rev-parse "$2" | cut -c1-8; }
is  "inventory A22, N5: cover default is read, its ref the resolved target and its sha8, fetched 0h ago for a clone fetched just now" \
    "$(_ibst RUN1 cover default "$IBRR") | $(_ibcol RUN1 cover default 8 "$IBRR")" "read | origin/main @ $(_ib8 "$IBR" origin/main); fetched 0h ago"
is  "inventory N5: and fetched 5h ago for a clone whose FETCH_HEAD is 5h10m old" "$(_ibcol RUN1 cover default 8 "$IBR2")" "origin/main @ $(_ib8 "$IB/r2" origin/main); fetched 5h ago"
is  "inventory A25: cover prs reads the gh command and the PR count" \
    "$(_ibst RUN1 cover prs "$IBRR") | $(_ibcol RUN1 cover prs 8 "$IBRR") | $(_ibcol RUN1 cover prs 8 "$IBR2")" \
    "read | gh pr list -R acme/widget: $IB_NPR PRs | gh pr list -R acme/other: 0 PRs"
is  "inventory A30: under --no-gh a pushed branch carries unknown:unproposed" "$(_ibholds RUN2 branch pushed unknown:unproposed)" "yes"
is  "inventory A30: and a never-pushed branch holds no PR state and no PR unknown: it is exactly unpushed" "$(_ibst RUN2 branch local-only)" "unpushed"
is  "inventory A32: a records root holding nothing for a path reads as cover sessions read, under the literal \$HOME/.claude/projects" \
    "$(_ibst RUN4 cover sessions) | $(_ibcol RUN4 cover sessions 8)" "read | Claude Code session records under \$HOME/.claude/projects"
is  "inventory A32: and the main worktree's owner is -, and it holds no host state and no host unknown" \
    "$(_ibcol RUN4 worktree "$IBRR" 5) $(_ibmany RUN4 worktree "$IBRR" live question blocked unknown:live unknown:question unknown:blocked)" \
    "- live=no question=no blocked=no unknown:live=no unknown:question=no unknown:blocked=no"
is  "inventory A33: a full clone's cover objects is read" "$(_ibst RUN1 cover objects "$IBRR")" "read"

# ---- §3: kinds and coverage ----------------------------------------------
is  "inventory A35, A114: a clean checkout of the default branch is landed and nothing else, owner -, though a linked worktree nested in it is dirty" \
    "$(_ibst RUN4 worktree "$IBRR") $(_ibcol RUN4 worktree "$IBRR" 5) $(_ibcol RUN4 worktree "$IBRR" 7)" "landed - landed"
is  "inventory A114: and that nested worktree's own row holds uncommitted" "$(_ibholds RUN4 worktree "$IBR/.claude/worktrees/nest" uncommitted)" "yes"
is  "inventory A36: a local branch covers its remote only when the remote tip is its tip or an ancestor: ahead and same have no remote row, behind has one" \
    "$(_ibst RUN1 remote origin/cov-ahead "$IBRR") | $(_ibst RUN1 remote origin/cov-same "$IBRR") | $(_ibcol RUN1 remote origin/cov-behind 1 "$IBRR")" "no row | no row | remote"
is  "inventory A37: a branch covers its upstream under another name, never the default branch, and origin/main is never a remote row" \
    "$(_ibst RUN1 remote origin/theirs "$IBRR") | $(_ibcol RUN1 branch tracker 1 "$IBRR") | $(LC_ALL=C awk -F'\t' '$1 == "remote" && $3 == "origin/main" { n++ } END { print n + 0 }' "$(_ibo RUN1)")" "no row | branch | 0"
is  "inventory A38: an open PR no local branch proposes is a pr row whose states are pr-open and whose detail starts with its head" \
    "$(_ibst RUN1 pr '#17') | $(_ibcol RUN1 pr '#17' 8 | LC_ALL=C awk '{ print substr($0, 1, 32) }')" "pr-open | head nobody @ $(_ib8 "$IBR" origin/nobody); #17 open"
is  "inventory A38: and its remote branch is no remote row" "$(_ibst RUN1 remote origin/nobody "$IBRR")" "no row"
is  "inventory A39: a branch proposes a PR through its upstream's name, so that PR is no pr row and the branch is pr-open with it" \
    "$(_ibst RUN1 pr '#13') | $(_ibholds RUN1 branch mine pr-open) | $(case "$(_ibcol RUN1 branch mine 8)" in (*'#13 open'*) echo '#13 open' ;; (*) echo 'no #13' ;; esac)" "no row | yes | #13 open"
is  "inventory A41: a pending section on the default branch is a handoff row, handoff-pending, naming its two Next items" \
    "$(_ibst RUN1 handoff docs/handoff/pending/h1.md) | $(case "$(_ibcol RUN1 handoff docs/handoff/pending/h1.md 8)" in (*'2 Next item(s): one | two'*) echo items ;; (*) echo "no items" ;; esac)" "handoff-pending | items"
is  "inventory A41: and neither a working-tree-only .md file nor a .txt file in pending/ is one" \
    "$(_ibst RUN1 handoff docs/handoff/pending/h2.md) | $(_ibst RUN1 handoff docs/handoff/pending/notes.txt) | $(_ibcount RUN1 handoff "$IBRR")" "no row | no row | 2"
is  "inventory A42: a section with no Next line says so" "$(case "$(_ibcol RUN1 handoff docs/handoff/pending/h3.md 8)" in (*'no Next lines'*) echo said ;; (*) echo unsaid ;; esac)" "said"
is  "inventory A120: a handoff row's age is the hours since its file's last commit, 30h20m, and its owner and content are -" \
    "$(_ibcol RUN1 handoff docs/handoff/pending/h1.md 6) $(_ibcol RUN1 handoff docs/handoff/pending/h1.md 5) $(_ibcol RUN1 handoff docs/handoff/pending/h1.md 7)" "30 - -"
is  "inventory A43: the tab worktree is uncommitted-unknown, never landed, and its detail says why" \
    "$(_ibmany RUN1 worktree "$IB/wts/t ab" unknown:uncommitted landed) $([ "$(_ibcol RUN1 worktree "$IB/wts/t ab" 8)" = - ] && echo nodetail || echo detail)" "unknown:uncommitted=yes landed=no detail"
is  "inventory A44: a listed worktree whose directory is gone still gets a row that says so" \
    "$(case "$(_ibcol RUN1 worktree "$IB/wts/gone" 8)" in (*'the directory is gone'*) echo said ;; ('no row') echo 'no row' ;; (*) echo unsaid ;; esac)" "said"
is  "inventory A116: a listed worktree holding no working tree of this repository holds orphan, with orphan content, and no orphan row besides" \
    "$(_ibholds RUN1 worktree "$IB/wts/hollow" orphan) $(_ibcol RUN1 worktree "$IB/wts/hollow" 7) $(_ibst RUN1 orphan "$IB/wts/hollow")" "yes not no row"
is  "inventory A116: and one holding another repository is uncommitted-unknown and never landed" "$(_ibmany RUN1 worktree "$IB/wts/swap" unknown:uncommitted landed)" "unknown:uncommitted=yes landed=no"

# ---- §4.3, §4.4: content and the mechanical states -----------------------
is  "inventory A47: a branch the default branch reaches is landed, its content landed" "$(_ibst RUN1 branch merged) $(_ibcol RUN1 branch merged 7)" "landed landed"
is  "inventory A48: a squash-landed branch never pushed is landed by content alone, even under --no-gh, with no unknown" "$(_ibst RUN2 branch sq) $(_ibcol RUN2 branch sq 7)" "landed landed"
is  "inventory A49: half its paths on main is partly, none is not, and both are unpushed" \
    "$(_ibcol RUN1 branch half 7) $(_ibcol RUN1 branch none 7) $(_ibholds RUN1 branch half unpushed) $(_ibholds RUN1 branch none unpushed)" "partly not yes yes"
is  "inventory A50: a deletion counts as landed when the default branch lacks the path too" "$(_ibcol RUN1 branch del 7)" "landed"
is  "inventory A51: a merged PR whose head is the tip, or descends from it, lands the branch though main reverted the change" \
    "$(_ibcol RUN1 branch rv 7) $(_ibcol RUN1 branch rv2 7) $(_ibholds RUN1 branch rv unproposed) $(_ibholds RUN1 branch rv2 unproposed)" "landed landed no no"
is  "inventory A52: commits on no remote-tracking ref are unpushed, and the detail gives the count, 2" \
    "$(_ibholds RUN1 branch local-only unpushed) $(_ibcol RUN1 branch local-only 8 | LC_ALL=C awk '/(^|[^0-9])2([^0-9]|$)/ { f = 1 } END { print (f ? "two" : "no two") }')" "yes two"
is  "inventory A53: a pushed branch with no PR is unproposed" "$(_ibholds RUN1 branch np unproposed)" "yes"
is  "inventory A53: and one whose newest PR merged before more commits is unproposed, naming that PR" \
    "$(_ibholds RUN1 branch late unproposed) $(case "$(_ibcol RUN1 branch late 8)" in (*'#22'*) echo '#22' ;; (*) echo 'no #22' ;; esac)" "yes #22"
is  "inventory A54: the newest PR closed unmerged, content not landed: pr-closed-unlanded" "$(_ibholds RUN1 branch cl pr-closed-unlanded)" "yes"
is  "inventory A54, N9: the newest PR merged and commits came after: content not, unproposed naming it, and not pr-closed-unlanded" \
    "$(_ibcol RUN1 branch rev 7) $(_ibmany RUN1 branch rev unproposed pr-closed-unlanded) $(case "$(_ibcol RUN1 branch rev 8)" in (*'#33'*) echo '#33' ;; (*) echo 'no #33' ;; esac)" \
    "not unproposed=yes pr-closed-unlanded=no #33"
is  "inventory A55: the PR flags read ready, hold, founder, draft and conflicting, in that order, joined by spaces" \
    "$(case "$(_ibcol RUN1 branch flag 8)" in (*'#40 open ready hold founder draft conflicting, 5h since update'*) echo flags ;; (*) _ibcol RUN1 branch flag 8 ;; esac)" "flags"
for _ibn in 41 42 43; do
  is  "inventory A56: ready is a felix/ready status context that succeeded, so PR $_ibn's lookalike is no ready" \
      "$(case "$(_ibcol RUN1 branch "f$_ibn" 8)" in (*"#$_ibn open, 2h since update"*) echo plain ;; (*) _ibcol RUN1 branch "f$_ibn" 8 ;; esac)" "plain"
done
is  "inventory A57: the label felix:founder reads founder" \
    "$(case "$(_ibcol RUN1 branch f44 8)" in (*'#44 open founder, 2h since update'*) echo founder ;; (*) _ibcol RUN1 branch f44 8 ;; esac)" "founder"
_ibhead1() { _ibst "$@" | LC_ALL=C awk -F, '{ print $1 }'; }
is  "inventory A58: a branch checked out in two worktrees heads both rows with hazard:shared-branch" "$(_ibhead1 RUN1 worktree "$IB/wts/s1") $(_ibhead1 RUN1 worktree "$IB/wts/s2")" "hazard:shared-branch hazard:shared-branch"
is  "inventory A58: and each detail names the other" \
    "$(case "$(_ibcol RUN1 worktree "$IB/wts/s1" 8)" in (*"$IB/wts/s2"*) echo s2 ;; (*) echo 'no s2' ;; esac) $(case "$(_ibcol RUN1 worktree "$IB/wts/s2" 8)" in (*"$IB/wts/s1"*) echo s1 ;; (*) echo 'no s1' ;; esac)" "s2 s1"
is  "inventory A59: an index staged back to an earlier tip heads with hazard:staged-revert and names that tip" \
    "$(_ibhead1 RUN1 worktree "$IB/wts/sr") $(case "$(_ibcol RUN1 worktree "$IB/wts/sr" 8)" in (*"$(printf '%s' "$IB_SRA" | cut -c1-8)"*) echo named ;; (*) echo unnamed ;; esac)" "hazard:staged-revert named"
is  "inventory A60: a soft reset is no staged revert, nor an unknown one" "$(_ibmany RUN1 worktree "$IB/wts/soft" hazard:staged-revert unknown:hazard:staged-revert)" "hazard:staged-revert=no unknown:hazard:staged-revert=no"
is  "inventory A61: with no reflog, a staged change makes staged-revert unknown, and the row is not landed" "$(_ibmany RUN1 worktree "$IB/wts/norl" unknown:hazard:staged-revert landed)" "unknown:hazard:staged-revert=yes landed=no"
is  "inventory A113: a dirty file whose content is already the default branch's is no uncommitted work" "$(_ibst RUN1 worktree "$IB/wts/behind") $(_ibcol RUN1 worktree "$IB/wts/behind" 7)" "landed landed"
is  "inventory A117: an ignored new file is no uncommitted work" "$(_ibst RUN1 worktree "$IB/wts/ign")" "landed"
is  "inventory A118: a worktree's content is the worse of its branch's and its uncommitted content's, and a partly tip alone is partly" \
    "$(_ibcol RUN1 worktree "$IB/wts/worse" 7) $(_ibcol RUN1 worktree "$IB/wts/partly" 7)" "not partly"
is  "inventory N10: a squash-merged pushed branch whose path main edited since is landed by its merged PR" "$(_ibst RUN1 branch sqp) $(_ibcol RUN1 branch sqp 7)" "landed landed"
is  "inventory N10: and under --no-gh, rule 3's not on a pushed tip is unknown, so it is not landed" "$(_ibcol RUN2 branch sqp 7) $(_ibholds RUN2 branch sqp landed)" "unknown no"
is  "inventory N11: a fork's PR is a pr row from a fork, owner -, though a session worked on a branch of its name" \
    "$(_ibst RUN1 pr '#16') $(_ibcol RUN1 pr '#16' 5) $(_ibhaselem RUN1 pr '#16' 'from a fork')" "pr-open - yes"
is  "inventory N11: and the local branch of that name is not proposed by it" "$(_ibst RUN1 branch forked)" "unpushed"
is  "inventory N11: and a fork's closed PR is no PR with this head: a pushed branch of its name is unproposed, not pr-closed-unlanded" \
    "$(_ibmany RUN1 branch fk2 unproposed pr-closed-unlanded)" "unproposed=yes pr-closed-unlanded=no"

# ---- §4.1, §4.7: landed and duplicates -----------------------------------
_ibland() { LC_ALL=C awk -F'\t' '$1 != "cover" { n++; s = "," $4 ","
    if (index(s, ",landed,")) { k = split($4, t, ","); for (i = 1; i <= k; i++) if (t[i] ~ /^unknown:/ && t[i] != "unknown:live") printf "%s %s [%s]; ", $1, $3, $4 } }
  END { if (n < 20) printf "only %d rows", n }' "$@"; }
is  "inventory A65: two unpushed branches carrying the same change are possible duplicates of each other, said at the end of each detail" \
    "$(_ibst RUN1 branch dupA) | $(_ibst RUN1 branch dupB) | $(_ibcol RUN1 branch dupA 8 | LC_ALL=C awk '{ print substr($0, length($0) - 27) }') | $(_ibcol RUN1 branch dupB 8 | LC_ALL=C awk '{ print substr($0, length($0) - 27) }')" \
    "unpushed,possible-duplicate | unpushed,possible-duplicate | ; possible duplicate of dupB | ; possible duplicate of dupA"
is  "inventory A66: the same path with different blobs is no duplicate, nor is one branch in two worktrees" \
    "$(_ibholds RUN1 branch difA possible-duplicate) $(_ibholds RUN1 branch difB possible-duplicate) $(_ibholds RUN1 worktree "$IB/wts/s1" possible-duplicate) $(_ibholds RUN1 worktree "$IB/wts/s2" possible-duplicate)" "no no no no"

# ---- §6.6, §6.7: chips and PR owners -------------------------------------
is  "inventory A95: a spawn_task proposal with a task id is an unstarted chip owned by its session, its detail the title, 0 hours old" \
    "$(_ibst RUN1 chip task_ab12cd34) | $(_ibcol RUN1 chip task_ab12cd34 5) | $(_ibcol RUN1 chip task_ab12cd34 8) | $(_ibcol RUN1 chip task_ab12cd34 6)" "chip-unstarted | s-chip | Fix the README badge | 0"
is  "inventory RV10: a chip's title is cut to its first 120 bytes on a whole UTF-8 character: 119 bytes when a two-byte character straddles byte 120, 120 when it ends there" \
    "$(_ibcol RUN1 chip task_t119aaaa 8 | LC_ALL=C awk '{ print length($0) ($0 ~ /[\200-\377]/ ? " cut-inside" : " clean") }') $(_ibcol RUN1 chip task_t120bbbb 8 | LC_ALL=C awk '{ print length($0) ($0 ~ /[\200-\377]/ ? " whole" : " dropped") }')" "119 clean 120 whole"
is  "inventory A96: a later dismiss_task in the same session withdraws its chip, whatever its result" "$(_ibcol RUN1 chip task_ab12cd34 1) $(_ibst RUN1 chip task_9600aaaa)" "chip no row"
is  "inventory A97: a session whose first human text is the prompt, behind a reminder and as a second text item, starts its chip" "$(_ibcol RUN1 chip task_ab12cd34 1) $(_ibst RUN1 chip task_9700aaaa)" "chip no row"
is  "inventory A98: a tool schema naming spawn_task is no proposal, and the prompt as a second human text starts nothing" "$(_ibst RUN1 chip task_ffff0000) | $(_ibst RUN1 chip task_ab12cd34)" "no row | chip-unstarted"
is  "inventory A99: a session modified before the proposal does not start it" "$(_ibst RUN1 chip task_ab12cd34)" "chip-unstarted"
is  "inventory A100: a chip proposed in a removed worktree's sessions still counts" "$(_ibst RUN1 chip task_100aaaaa)" "chip-unstarted"
is  "inventory A115: a first human text that differs at decoded character 120 starts nothing, and one equal through 120 starts its chip" \
    "$(_ibst RUN1 chip task_115aaaaa) | $(_ibst RUN1 chip task_115bbbbb)" "chip-unstarted | no row"
is  "inventory N1: a pr row's owner is the sessionId of the newest record on its branch, a resumed file's copied record keeping its own, and it is live" \
    "$(_ibcol RUN1 pr '#12' 5) $(_ibst RUN1 pr '#12')" "s-o2 live,pr-open"
is  "inventory N1: an owner whose records are 90 minutes old leaves its pr row not live" "$(_ibcol RUN1 pr '#15' 5) $(_ibst RUN1 pr '#15')" "s-o4 pr-open"
is  "inventory RV5: the owner of a pull request is the session of the newest record naming its head, not the session whose file was written last" "$(_ibcol RUN1 pr '#60' 5)" "s-ow-a2"
is  "inventory RV6: an owner whose own file holds a newer record on another branch is live, though its record naming the head is two hours old" \
    "$(_ibcol RUN1 pr '#61' 5) $(_ibholds RUN1 pr '#61' live)" "s-ow-b yes"
is  "inventory RV7: an attachment record naming the head, newer than every user and assistant record, makes no owner" "$(_ibcol RUN1 pr '#62' 5)" "s-ow-c2"
is  "inventory A102: a pr row whose branch no record names has owner - and is not live" "$(_ibcol RUN1 pr '#17' 5) $(_ibst RUN1 pr '#17')" "- pr-open"
is  "inventory A102: and under --no-host its owner is unknown and live is unknown" "$(_ibcol RUN3 pr '#17' 5) $(_ibst RUN3 pr '#17')" "unknown pr-open,unknown:live"

# ---- §4.1: no landed row hides an unknown --------------------------------
is  "inventory A64: no row in r with or without gh or host records is landed beside an unknown other than unknown:live" \
    "$(_ibland "$(_ibo RUN1)" "$(_ibo RUN2)" "$(_ibo RUN3)")" ""

