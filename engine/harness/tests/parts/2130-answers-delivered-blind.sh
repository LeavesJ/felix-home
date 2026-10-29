printf '\nanswers delivered without being asked for\n'
# Blind, written 2026-10-29 from docs/2026-10-29-answers-delivered-spec.md alone (sections 2-6: A1-A3, U1-U4, T1-T2,
# R1-R3 with the R2 and R3 addendum, L1-L5). lib/graph.sh past what part 0760 shows, the user-prompt, post-tool and
# session-end hooks, lib/ledger.sh and `felix ledger` run here as black boxes; parts 0002, 0003, 0320, 0330, 0760 and
# 1130 were read for idioms, and lib/own.sh, lib/resolve.sh and lib/route.sh for what makes a checkout own and a prompt
# a person's. Why: the route named the graph in 15 sessions and it was reached in none (the spec's section 0), so its
# answer is now handed over: in the own checkout only, once per file per session, in the spec's words, never at the
# prompt's cost. What the session opened next is recorded, and the answer is a ledger surface of its own, since counted
# as a reach it would read as use the session never chose. Fixture: home ansp (remote_match OwnerA/ansp-repo); checkouts
# own (three commits), its worktree two ahead, marker (.felix alone), foreign (an origin only containing the
# remote_match), nograph. A stand-in graphify first on PATH logs each argv to $AX/glog as <word>s; `query` prints
# $AX/out.<v>, v from $AX/gv (fail, hang, empty built in); any other first word is a refresh, waiting for $AX/release.
AX="$TMP/answers"; mkdir -p "$AX/bin" "$AX/co" "$AX/user" "$AX/spy" "$AX/home/projects/ansp" "$AX/mem/ansp"
AX="$(cd "$AX" && pwd -P)"; AXH="$AX/home"; AXM="$AX/mem"; AXP="$AXH/projects/ansp"; AXT="$(printf '\t')"; : > "$AX/glog"
AXO="$AX/co/own"; AXW="$AX/co/own-wt"; AXK="$AX/co/marker"; AXF="$AX/co/foreign"; AXN="$AX/co/nograph"; AXHEAD='answers handed to sessions without being asked for'
AXL="$AXO/graphify-out/.felix-refresh.lock"; AXQ="where does the answer block get built"; AXCUR="current with the checkout that holds it"
AXSHP='It finds where things are, not who calls them: in shell scripts the graph sees few callers, so for "what calls this" grep is still the oracle.'
AXSENT='A file the session would have opened anyway counts here too, so this is the most the answers can have caused, not what they caused.'
printf '{"name": "ansp", "remote_match": "OwnerA/ansp-repo", "gate": "true"}\n' > "$AXP/project.json"; printf '# ansp\n' > "$AXP/CLAUDE.md"
printf 'debug\tbroken failing crash\tcore\tsuperpowers:systematic-debugging\n' > "$AXP/routes.tsv"
printf 'plugin\tsuperpowers@x\t-\tlow\talways\nskill\tgraphify\t-\tlow\talways\n' > "$AXP/stack.tsv"
printf -- '- **L1 The quokka ledger is reconciled by hand.** Evidence would follow here.\n' > "$AXM/ansp/lessons.md"
_ax_git() { git -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"; }
_ax_files() {   # the files every checkout holds, written where the shell stands
  mkdir -p lib docs bin notes && printf '#!/bin/sh\necho one\n' > lib/one.sh && printf '# guide\n' > docs/guide.md \
    && printf '#!/usr/bin/env bash\necho tool\n' > bin/tool && printf '#!/bin/zsh\necho z\n' > bin/ztool \
    && printf '#!/usr/bin/env python3\nprint(1)\n' > bin/py && printf 'dots\n' > 'lib/a..b.txt' || return 1
  local i; for i in 1 2 3 4 5 6 7 8 9 10; do printf 'n%s\n' "$i" > "notes/n$i.md"; done
}
mkdir -p "$AXO" "$AXK" "$AXF" "$AXN"
( _fx_cd "$AXO" && git init -q -b main && _ax_files && printf 'ansp\n' > .felix && git add -A && _ax_git commit -qm c1 \
  && printf '2\n' > c2.txt && git add -A && _ax_git commit -qm c2 && printf '3\n' > c3.txt && git add -A && _ax_git commit -qm c3 \
  && git remote add origin https://github.com/OwnerA/ansp-repo && git worktree add -q "$AXW" -b side ) >/dev/null 2>&1
( _fx_cd "$AXW" && printf 'w\n' > wtonly.md && git add -A && _ax_git commit -qm w1 && printf 'w\n' > w2.txt && git add -A \
  && _ax_git commit -qm w2 ) >/dev/null 2>&1
( _fx_cd "$AXK" && git init -q -b main && _ax_files && printf 'ansp\n' > .felix && printf 'k\n' > k.txt && git add -A \
  && _ax_git commit -qm k1 && printf 'k\n' > k2.txt && git add -A && _ax_git commit -qm k2 ) >/dev/null 2>&1
( _fx_cd "$AXF" && git init -q -b main && _ax_files && printf 'f\n' > f.txt && git add -A && _ax_git commit -qm f1 \
  && printf 'f\n' > f2.txt && git add -A && _ax_git commit -qm f2 && git remote add origin git@evil.example:OwnerA/ansp-repo.git ) >/dev/null 2>&1
( _fx_cd "$AXN" && git init -q -b main && printf 'n\n' > n.txt && git add -A && _ax_git commit -qm n1 ) >/dev/null 2>&1
printf 'held\n' > "$AXO/holdonly.md"; printf 'x\n' > "$AX/co/outside.txt"
AXO1="$(git -C "$AXO" rev-list --max-parents=0 HEAD 2>/dev/null)"; AXO3="$(git -C "$AXO" rev-parse HEAD 2>/dev/null)"
AXK1="$(git -C "$AXK" rev-list --max-parents=0 HEAD 2>/dev/null)"; AXF1="$(git -C "$AXF" rev-list --max-parents=0 HEAD 2>/dev/null)"
_ax_stamp() {   # CHECKOUT COMMIT|- -> its graphify-out/graph.json, built at COMMIT, or carrying no stamp at all
  mkdir -p "$1/graphify-out" || return 1
  if [ "$2" = - ]; then printf '{"nodes":[]}\n'; else printf '{"nodes":[],"built_at_commit":"%s"}\n' "$2"; fi > "$1/graphify-out/graph.json"
}
_ax_stamp "$AXO" "$AXO3"; _ax_stamp "$AXK" "$(git -C "$AXK" rev-parse HEAD 2>/dev/null)"; _ax_stamp "$AXF" "$(git -C "$AXF" rev-parse HEAD 2>/dev/null)"

cat > "$AX/bin/graphify" <<AXG
#!/bin/sh
{ for a in "\$@"; do printf '<%s> ' "\$a"; done; printf '\n'; } >> "$AX/glog"
if [ "\${1:-}" != query ]; then
  i=0; while [ ! -f "$AX/release" ] && [ "\$i" -lt 100 ]; do sleep 0.1; i=\$((i + 1)); done; exit 0
fi
printf 'graphify-stderr-noise\n' >&2
v="\$(cat "$AX/gv" 2>/dev/null)"
case "\$v" in
  fail) printf 'NODE one [src=lib/one.sh loc=L1 community=0]\n'; exit 3 ;;
  hang) printf 'NODE one [src=lib/one.sh loc=L1 community=0]\n'; exec sleep 6 ;;
esac
[ ! -f "$AX/out.\$v" ] || cat "$AX/out.\$v"
AXG
chmod +x "$AX/bin/graphify"
{ printf "Traversal: BFS depth=2 | Start: ['answer'] | 11 nodes found\n"
  printf 'NODE felix_one() [src=lib/one.sh loc=L83 community=3]\nNODE Guide heading [src=docs/guide.md loc=§0ae community=None]\n'
  printf 'NODE abs [src=/etc/hosts loc=L1 community=0]\nNODE none [src=None loc=None community=0]\nNODE up [src=../outside.txt loc=L2 community=0]\n'
  printf 'NODE inner up [src=lib/../lib/one.sh loc=L3 community=0]\nNODE missing [src=lib/missing.sh loc=L4 community=0]\n'
  printf 'NODE a directory [src=lib loc=L5 community=0]\nNODE notes heading [src=notes/n1.md loc=None community=2]\n'
  printf 'NODE second in one [src=lib/one.sh loc=L90 community=3]\nEDGE felix_one() --calls--> x [EXTRACTED]\n'; } > "$AX/out.mix"
printf 'NODE dotted name [src=lib/a..b.txt loc=None community=1]\n' > "$AX/out.dots"
AXL150="$(awk 'BEGIN { for (i = 0; i < 15; i++) printf "abcdefghij" }')"
printf 'NODE tab\there\001ctl\033[0mend [src=lib/one.sh loc=L7 community=0]\nNODE %s [src=docs/guide.md loc=L8 community=0]\n' "$AXL150" > "$AX/out.label"
{ for _ax_i in 1 2 3 4 5 6 7 8 9 10; do printf 'NODE n%s [src=notes/n%s.md loc=L1 community=0]\n' "$_ax_i" "$_ax_i"; done
  printf 'NODE n1 again [src=notes/n1.md loc=L9 community=0]\n'; } > "$AX/out.many"
awk 'BEGIN { for (i = 1; i <= 20; i++) printf "NODE r%d [src=%s loc=L%d community=0]\n", i, (i % 2 ? "lib/one.sh" : "docs/guide.md"), i }' > "$AX/out.rows"
printf 'NODE felix_one() [src=lib/one.sh loc=L83 community=3]\nNODE Guide heading [src=docs/guide.md loc=None community=1]\nNODE second in one [src=lib/one.sh loc=L90 community=3]\n' > "$AX/out.shell"
printf 'NODE felix_one() [src=lib/one.sh loc=L83 community=3]\nNODE n2 heading [src=notes/n2.md loc=L4 community=0]\n' > "$AX/out.second"
printf 'NODE Guide heading [src=docs/guide.md loc=L1 community=1]\nNODE main [src=bin/py loc=L2 community=1]\n' > "$AX/out.noshell"
printf 'NODE tool [src=bin/tool loc=L2 community=0]\n' > "$AX/out.envbash"; printf 'NODE ztool [src=bin/ztool loc=L2 community=0]\n' > "$AX/out.zsh"
printf 'NODE held [src=holdonly.md loc=L1 community=0]\nNODE worktree only [src=wtonly.md loc=L2 community=0]\n' > "$AX/out.wt"
printf 'no nodes here\n{"json": true}\nNODE without brackets\n' > "$AX/out.garbage"
AXMIX="$(printf 'lib/one.sh\tL83\tfelix_one()\ndocs/guide.md\t§0ae\tGuide heading\nnotes/n1.md\t\tnotes heading\nlib/one.sh\tL90\tsecond in one')"
AXMANY="$(for _ax_i in 1 2 3 4 5 6 7 8; do printf 'notes/n%s.md\tL1\tn%s\n' "$_ax_i" "$_ax_i"; done; printf 'notes/n1.md\tL9\tn1 again')"
AXROWS="$(printf '  lib/one.sh:L83  felix_one()\n  docs/guide.md  Guide heading\n  lib/one.sh:L90  second in one')"

_ax_argv() { local a; for a in "$@"; do printf '<%s> ' "$a"; done; }   # the stand-in's log line for these words
_ax_q() { _ax_argv query "$1" --budget "${2:-600}" --graph "$AXO/graphify-out/graph.json"; }; _ax_log() { cat "$AX/glog" 2>/dev/null; }
_ax_lib() {   # FUNCTION ARGS... with resolve.sh, ledger.sh and graph.sh sourced and the stand-in first on PATH
  ( PATH="${AX_PATH:-$AX/bin:$PATH}"; FELIX_HOME="$AXH"; FELIX_MEMORY="$AXM"; export PATH FELIX_HOME FELIX_MEMORY
    . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/ledger.sh"; . "$FROOT/harness/lib/graph.sh"; "$@" )
}
_ax_ans() {   # VARIANT ROOT PROMPT -> AXOUT, what felix_graph_answer printed, and AXRC; $AX/glog holds this call alone
  printf '%s' "$1" > "$AX/gv"; : > "$AX/glog"
  AXOUT="$(_ax_lib felix_graph_answer "$2" "$3" 2>/dev/null)"; AXRC=$?
}
_ax_dl() {    # VARIANT HOME SESSION ROOT -> AXOUT, the block felix_graph_deliver printed, and AXRC
  printf '%s' "$1" > "$AX/gv"
  AXOUT="$(_ax_lib felix_graph_deliver "$2" "$3" "$4" "$AXQ" 2>/dev/null)"; AXRC=$?
}
_ax_par() {   # TEXT N [c] -> its Nth paragraph; with c, every run of whitespace one space and the ends trimmed
  awk -v n="$2" -v c="${3:-}" 'BEGIN { RS = "" } NR == n { if (c != "") { gsub(/[ \t\n]+/, " "); sub(/^ /, ""); sub(/ $/, "") } print }' <<<"$1"
}
_ax_npar() { awk 'BEGIN { RS = "" } END { print NR }' <<<"$1"; }; _ax_ck() { if [ -f "$1" ]; then cksum < "$1"; else printf 'none'; fi; }
_ax_hd() {    # SHA FRESHNESS -> the block's first paragraph as one line; SHA - for a graph whose stamp says nothing usable
  if [ "$1" = - ]; then printf "The knowledge graph's answer to this prompt (graphify query, graph carrying no build stamp). Where it places what was asked, so you can open these instead of searching for them:"
  else printf "The knowledge graph's answer to this prompt (graphify query, graph built at %s, %s). Where it places what was asked, so you can open these instead of searching for them:" "${1:0:7}" "$2"; fi
}
_ax_have() { local t; for t in "$@"; do command -v "$t" >/dev/null 2>&1 || return 1; done; }
_ax_sans() {   # NAME DIR -> this PATH, each entry holding NAME replaced by a directory of links to all its other commands
  local IFS=: d out="" n=0
  for d in $PATH; do
    if [ -n "$d" ] && [ -f "$d/$1" ]; then n=$((n + 1)); mkdir -p "$2/$n" && ln -s "$d"/* "$2/$n/" 2>/dev/null; rm -f "$2/$n/$1"; d="$2/$n"; fi
    out="$out${out:+:}$d"
  done
  printf '%s' "$out"
}
_ax_own() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/own.sh"; felix_checkout_is_own "$AXP" "$1" >/dev/null 2>&1; printf '%s' "$?" ); }
_ax_res() { local p; p="$( . "$FROOT/harness/lib/resolve.sh"; felix_resolve_project "$1" "$AXH" 2>/dev/null )"; printf '%s' "${p##*/}"; }
AXNOG="$(_ax_sans graphify "$AX/farm-g")"; AXNOP="$AX/bin:$(_ax_sans perl "$AX/farm-p")"
is "answers fixture: own and its worktree are ansp's own checkouts, marker and foreign are bound to ansp and not own (fixture control)" \
   "$(_ax_own "$AXO")$(_ax_own "$AXW")$(_ax_own "$AXK")$(_ax_own "$AXF") $(_ax_res "$AXO") $(_ax_res "$AXW") $(_ax_res "$AXK") $(_ax_res "$AXF")" "0011 ansp ansp ansp ansp"
is "answers fixture: own has three commits, its worktree two more of its own, and every other checkout a commit (fixture control)" \
   "$(git -C "$AXO" rev-list --count HEAD 2>/dev/null) $(git -C "$AXW" rev-list --count HEAD 2>/dev/null) $([ -n "$AXK1" ] && [ -n "$AXF1" ] && [ -n "$(git -C "$AXN" rev-parse HEAD 2>/dev/null)" ] && echo made)" "3 5 made"
is "answers fixture: one PATH has no graphify and one no perl, and both still have git, awk and sed (fixture control)" \
   "$( PATH="$AXNOG"; _ax_have graphify || printf 'no-graphify '; _ax_have git awk sed && printf 'tools '; PATH="$AXNOP"; _ax_have perl || printf 'no-perl '; _ax_have git awk sed graphify && printf 'tools' )" \
   "no-graphify tools no-perl tools"

printf '\nA1: felix_graph_answer, the graph asked the prompt\n'
_ax_ans mix "$AXO" "$AXQ"
is "A1: felix_graph_answer prints a src, loc and label row for each node it keeps, in graphify's order, and exits 0" "$AXRC|$AXOUT" "0|$AXMIX"
is "A1.5: it runs graphify once, exactly: query, the prompt, --budget 600 and --graph naming the graph file" "$(_ax_log)" "$(_ax_q "$AXQ")"
is "A1.5: graphify's stderr is discarded, so stdout and stderr together are the rows alone" "$(_ax_lib felix_graph_answer "$AXO" "$AXQ" 2>&1)" "$AXMIX"
FELIX_GRAPH_BUDGET=1234 _ax_ans mix "$AXO" "$AXQ"
is "A1.5: FELIX_GRAPH_BUDGET is the budget it passes" "$(_ax_log)" "$(_ax_q "$AXQ" 1234)"
FELIX_GRAPH_ANSWER=0 _ax_ans mix "$AXO" "$AXQ"
is "A1.1: with FELIX_GRAPH_ANSWER=0 it prints nothing, exits 1 and runs nothing" "$AXRC|$AXOUT|$(_ax_log)" "1||"
_ax_ans mix "$AXN" "$AXQ"
is "A1.2: a checkout with no graph file gets nothing and exit 1, and graphify is not run" "$AXRC|$AXOUT|$(_ax_log)" "1||"
_ax_ans wt "$AXW" "$AXQ"
is "A1.2: from a worktree it asks the graph of the checkout that holds it" "$(_ax_log)" "$(_ax_q "$AXQ")"
is "A1.6: and keeps a node only for a file under that holding checkout, not one the worktree alone holds" "$AXRC|$AXOUT" "0|holdonly.md${AXT}L1${AXT}held"
AX_PATH="$AXNOG" _ax_ans mix "$AXO" "$AXQ"
is "A1.3: with no graphify on PATH it prints nothing and exits 1" "$AXRC|$AXOUT" "1|"
AX_PATH="$AXNOP" _ax_ans mix "$AXO" "$AXQ"
is "A1.3: with graphify on PATH and no perl it prints nothing, exits 1 and does not run graphify" "$AXRC|$AXOUT|$(_ax_log)" "1||"
_ax_ans mix "$AXO" "four words only here"
is "A1.4: a prompt of four words, under the default floor of five, runs nothing and exits 1" "$AXRC|$AXOUT|$(_ax_log)" "1||"
FELIX_GRAPH_MIN_WORDS=4 _ax_ans mix "$AXO" "four words only here"
is "A1.4: FELIX_GRAPH_MIN_WORDS=4 lets the same four words through" "$AXRC|$(_ax_log)" "0|$(_ax_q "four words only here")"
_ax_ans mix "$AXO" "$(printf '  where\tdoes   the\nanswer block\\nget\\tbuilt\\rnow  ')"
is "A1.4: spaces, tabs, newlines and the two-character escapes for newline, tab and return are one space each, the ends trimmed" \
   "$(_ax_log)" "$(_ax_q "where does the answer block get built now")"
_ax_ans mix "$AXO" 'one\ntwo\tthree\rfour'
is "A1.4: four words joined only by those escapes are four words, and run nothing" "$AXRC|$(_ax_log)" "1|"
_ax_ans mix "$AXO" 'one\ntwo\tthree\rfour five'
is "A1.4: and five words so joined are five, asked as five" "$AXRC|$(_ax_log)" "0|$(_ax_q "one two three four five")"
_ax_ans mix "$AXO" "$(awk 'BEGIN { for (i = 0; i < 200; i++) printf "ab " }')"
is "A1.4: a prompt longer than 400 characters is cut to its first 400" "$(_ax_log)" "$(_ax_q "$(awk 'BEGIN { for (i = 0; i < 133; i++) printf "ab " }')a")"
_ax_ans fail "$AXO" "$AXQ"
is "A1.5: a graphify that exits non-zero is no answer, the node it printed included: nothing printed, exit 1" "$AXRC|$AXOUT" "1|"
_ax_ans empty "$AXO" "$AXQ"
is "A1.5: a graphify that prints nothing is no answer: exit 1" "$AXRC|$AXOUT" "1|"
_ax_t0=$SECONDS; FELIX_GRAPH_TIMEOUT=1 _ax_ans hang "$AXO" "$AXQ"; _ax_dt=$((SECONDS - _ax_t0))
is "A1.5: a graphify that hangs past FELIX_GRAPH_TIMEOUT=1 is no answer: nothing printed, exit 1, back within 4 seconds" \
   "$AXRC|$AXOUT|$([ "$_ax_dt" -le 4 ] && echo prompt || echo "waited ${_ax_dt}s")" "1||prompt"
_ax_ans garbage "$AXO" "$AXQ"
is "A1.9: output with no NODE line of the form keeps no node: nothing printed, exit 1" "$AXRC|$AXOUT" "1|"
_ax_ans dots "$AXO" "$AXQ"
is "A1.6: a name holding .. that is not a .. segment is kept, and a loc of None prints as empty" "$AXRC|$AXOUT" "0|lib/a..b.txt${AXT}${AXT}dotted name"
_ax_ans label "$AXO" "$AXQ"
is "A1.7: a label loses its tab and control bytes and is cut to 120 characters" "$AXOUT" "$(printf 'lib/one.sh\tL7\ttabherectl[0mend\ndocs/guide.md\tL8\t%s' "${AXL150:0:120}")"
_ax_ans many "$AXO" "$AXQ"
is "A1.8: rows stop at eight distinct files, and a later node of a file already listed is still printed" "$AXOUT" "$AXMANY"
FELIX_GRAPH_FILES=2 _ax_ans many "$AXO" "$AXQ"
is "A1.8: FELIX_GRAPH_FILES=2 stops at two files, the first file's later node still printed" "$AXOUT" "$(printf 'notes/n1.md\tL1\tn1\nnotes/n2.md\tL1\tn2\nnotes/n1.md\tL9\tn1 again')"
_ax_ans rows "$AXO" "$AXQ"
is "A1.8: and never more than 16 rows in all" "$(awk 'END { print NR }' <<<"$AXOUT") $(tail -1 <<<"$AXOUT" | cut -f3)" "16 r16"

printf '\nA2: felix_graph_deliver, the block, once per file per session\n'
_ax_stamp "$AXO" "$AXO3"; _ax_dl shell "$AXH" d1 "$AXO"
is "A2.6: the block opens with graphify query, the stamp's first seven characters and current with the checkout that holds it" \
   "$AXRC|$(_ax_par "$AXOUT" 1 c)" "0|$(_ax_hd "$AXO3" "$AXCUR")"
is "A2.6: then a blank line and a row a node: two spaces, src:loc, two spaces, the label, and src alone where loc is empty" "$(_ax_par "$AXOUT" 2)" "$AXROWS"
is "A2.7: a shell script among the files ends the block with the paragraph about callers" "$(_ax_npar "$AXOUT")|$(_ax_par "$AXOUT" 3 c)" "3|$AXSHP"
is "A2.4: the session's record gains a given row counting the distinct files, then an answer row a file in graphify's order" \
   "$(cat "$AXH/state/answer/d1.tsv" 2>/dev/null)" "$(printf 'given\tgraphify\t2\nanswer\tgraphify\tlib/one.sh\nanswer\tgraphify\tdocs/guide.md')"
is "A2.5: and the session's ledger one answer graphify signal" "$(cat "$AXH/state/ledger/d1.tsv" 2>/dev/null)" "answer${AXT}graphify"
_ax_sum="$(_ax_ck "$AXH/state/answer/d1.tsv")$(_ax_ck "$AXH/state/ledger/d1.tsv")"; _ax_dl shell "$AXH" d1 "$AXO"
is "A2.3: the same answer again in that session prints nothing, exits 1 and writes nothing" \
   "$AXRC|$AXOUT|$(_ax_ck "$AXH/state/answer/d1.tsv")$(_ax_ck "$AXH/state/ledger/d1.tsv")" "1||$_ax_sum"
_ax_dl second "$AXH" d1 "$AXO"
is "A2.3: a later answer lists only the files not given yet, with no callers paragraph when none of them is a shell script" \
   "$AXRC|$(_ax_npar "$AXOUT")|$(_ax_par "$AXOUT" 2)" "0|2|  notes/n2.md:L4  n2 heading"
is "A2.4: and appends its given and answer rows after the first delivery's" "$(cat "$AXH/state/answer/d1.tsv" 2>/dev/null)" \
   "$(printf 'given\tgraphify\t2\nanswer\tgraphify\tlib/one.sh\nanswer\tgraphify\tdocs/guide.md\ngiven\tgraphify\t1\nanswer\tgraphify\tnotes/n2.md')"
is "A2.5: one ledger signal a delivery, so two after two deliveries" "$(cat "$AXH/state/ledger/d1.tsv" 2>/dev/null)" "$(printf 'answer\tgraphify\nanswer\tgraphify')"
_ax_dl shell "$AXH" d2 "$AXO"
is "A2.3: another session is given the whole answer, the record being the session's own" "$AXRC|$(_ax_par "$AXOUT" 2)" "0|$AXROWS"
mkdir -p "$AXH/state/answer"; printf 'given\tothertool\t1\nanswer\tothertool\tlib/one.sh\n' > "$AXH/state/answer/d3.tsv"; _ax_dl shell "$AXH" d3 "$AXO"
is "A2.3: a file recorded as another tool's answer is not dropped from graphify's" "$(_ax_par "$AXOUT" 2)" "$AXROWS"
mkdir -p "$AX/h-empty"; _ax_dl shell "$AX/h-empty" "" "$AXO"
is "A2.1: an empty session prints nothing, exits 1 and writes nothing" "$AXRC|$AXOUT|$(find "$AX/h-empty" -type f | wc -l | tr -d ' ')" "1||0"
_ax_dl garbage "$AX/h-empty" d4 "$AXO"
is "A2.2: an answer that fails prints nothing, exits 1 and writes nothing" "$AXRC|$AXOUT|$(find "$AX/h-empty" -type f | wc -l | tr -d ' ')" "1||0"
_ax_stamp "$AXO" "$AXO1"; _ax_dl noshell "$AXH" f1 "$AXO"
is "A2.6: a graph two commits behind says 2 commit(s) behind the checkout that holds it, after the stamp's seven characters" \
   "$(_ax_par "$AXOUT" 1 c)" "$(_ax_hd "$AXO1" "2 commit(s) behind the checkout that holds it")"
is "A2.7: with no file a shell script by its name or its first line there is no callers paragraph" \
   "$(_ax_npar "$AXOUT")|$(_ax_par "$AXOUT" 2)" "2|$(printf '  docs/guide.md:L1  Guide heading\n  bin/py:L2  main')"
_ax_dl envbash "$AXH" f2 "$AXW"
is "A2.6: asked from a worktree two commits ahead the freshness is still the holding checkout's" \
   "$(_ax_par "$AXOUT" 1 c)" "$(_ax_hd "$AXO1" "2 commit(s) behind the checkout that holds it")"
is "A2.7: a file whose first line is #!/usr/bin/env bash is a shell script" "$(_ax_par "$AXOUT" 3 c)" "$AXSHP"
_ax_dl zsh "$AXH" f3 "$AXO"
is "A2.7: and so is one whose first line is #!/bin/zsh" "$(_ax_par "$AXOUT" 3 c)" "$AXSHP"
_ax_stamp "$AXO" -; _ax_dl noshell "$AXH" f4 "$AXO"
is "A2.6: a graph with no stamp says graph carrying no build stamp in place of when it was built and how fresh" "$AXRC|$(_ax_par "$AXOUT" 1 c)" "0|$(_ax_hd -)"
_ax_stamp "$AXO" 0000000000000000000000000000000000000000; _ax_dl noshell "$AXH" f5 "$AXO"
is "A2.6: and so does a graph whose stamp names no commit here" "$AXRC|$(_ax_par "$AXOUT" 1 c)" "0|$(_ax_hd -)"
_ax_stamp "$AXO" "$AXO3"; mkdir -p "$AX/h-ro/state"; chmod 555 "$AX/h-ro/state"
if ( : > "$AX/h-ro/state/.probe" ) 2>/dev/null; then skip "A2.8: a record it cannot write still prints the block and exits 0" "the state directory is still writable"
else _ax_dl shell "$AX/h-ro" g1 "$AXO"
  is "A2.8: a record it cannot write still prints the block and exits 0" "$AXRC|$(_ax_par "$AXOUT" 1 c)|$(_ax_par "$AXOUT" 2)" "0|$(_ax_hd "$AXO3" "$AXCUR")|$AXROWS"
fi
chmod 755 "$AX/h-ro/state"

printf '\nA3: felix_graph_refresh_due\n'
_ax_due() { local o; o="$(_ax_lib felix_graph_refresh_due "$1" 2>&1)"; printf '%s|%s' "$?" "$o"; }
is "A3: a graph built at HEAD is not due a refresh: exit 1, nothing printed" "$(_ax_due "$AXO")" "1|"
is "A3: a worktree ahead of a graph current with the holding checkout is not due either" "$(_ax_due "$AXW")" "1|"
_ax_stamp "$AXO" "$AXO1"
is "A3: a graph two commits behind is due: exit 0, nothing printed" "$(_ax_due "$AXO")" "0|"
is "A3: and asked from a worktree it is the holding checkout's distance that decides" "$(_ax_due "$AXW")" "0|"
_ax_stamp "$AXO" -
is "A3: a graph with no stamp is not due" "$(_ax_due "$AXO")" "1|"
_ax_stamp "$AXO" 0000000000000000000000000000000000000000
is "A3: nor one whose stamp is a commit the checkout does not hold" "$(_ax_due "$AXO")" "1|"
is "A3: nor a checkout with no graph at all" "$(_ax_due "$AXN")" "1|"
_ax_stamp "$AXO" "$AXO3"

printf '\nU1-U4: hooks/user-prompt hands the answer over\n'
_ax_up() {   # DIR PAYLOAD [NAME=VALUE...] -> what the user-prompt hook printed there; its status in $AX/up.rc
  local d="$1" p="$2"; shift 2
  ( _fx_cd "$d" && env FELIX_HOME="$AXH" FELIX_MEMORY="$AXM" HOME="$AX/user" PATH="$AX/bin:$PATH" "$@" "$FROOT/harness/hooks/user-prompt" <<<"$p" 2>/dev/null
    printf '%s' "$?" > "$AX/up.rc" )
}
_ax_pay() { printf -v AXPAY '{"session_id":"%s","cwd":"%s","hook_event_name":"UserPromptSubmit","prompt":"%s"}' "$1" "${3:-$AXO}" "$2"; }   # SESSION PROMPT [DIR]
_ax_ctx() { python3 -c 'import json, sys
try: sys.stdout.write(json.loads(sys.stdin.read())["hookSpecificOutput"]["additionalContext"])
except Exception: sys.stdout.write("(no json)")' <<<"$1" 2>/dev/null; }
_ax_block() { case "$1" in *"knowledge graph's answer"*) printf 'a block' ;; *) printf 'no block' ;; esac; }
_ax_rec() { if [ -e "$AXH/state/answer/$1.tsv" ]; then printf 'recorded'; else printf 'none'; fi; }
_ax_starts() { case "$1" in "$2"*) printf 'yes' ;; *) printf 'no' ;; esac; }
_ax_gap() {   # MID -> "one" when MID starts with no newline and ends with exactly one blank line
  case "$1" in $'\n'*) printf 'a leading newline'; return 0 ;; esac
  if [ "${1%$'\n\n'}" != "$1" ] && [ "${1%$'\n\n\n'}" = "$1" ]; then printf 'one'; else printf 'not one'; fi
}
printf shell > "$AX/gv"; : > "$AX/glog"; _ax_pay u1 "$AXQ"; AXU="$(_ax_up "$AXO" "$AXPAY")"; AXC="$(_ax_ctx "$AXU")"
is "U3: a prompt whose one part is the answer still gets the hook's JSON, and the hook exits 0" "$(cat "$AX/up.rc")|$([ "$AXC" != "(no json)" ] && echo json)" "0|json"
is "U1: a person's prompt with a session id in the own checkout gets the block, word for word and nothing else" \
   "$(_ax_npar "$AXC")|$(_ax_par "$AXC" 1 c)|$(_ax_par "$AXC" 2)|$(_ax_par "$AXC" 3 c)" "3|$(_ax_hd "$AXO3" "$AXCUR")|$AXROWS|$AXSHP"
is "U2: and graphify is asked once, about the payload's prompt" "$(_ax_log)" "$(_ax_q "$AXQ")"
: > "$AX/glog"; _ax_pay u1m "<task-notification><task-id>b1</task-id><status>completed</status></task-notification> $AXQ"; AXU="$(_ax_up "$AXO" "$AXPAY")"
is "U1: a task notification is not a person's prompt: no block, graphify not asked, no record" "$(_ax_block "$AXU")|$(_ax_log)|$(_ax_rec u1m)" "no block||none"
_ax_n0="$(ls "$AXH/state/answer" 2>/dev/null | wc -l | tr -d ' ')"; : > "$AX/glog"
printf -v AXPAY '{"hook_event_name":"UserPromptSubmit","prompt":"%s"}' "$AXQ"; AXU="$(_ax_up "$AXO" "$AXPAY")"
is "U1: a payload with no session id is told nothing, and nothing is recorded" "$(_ax_block "$AXU")|$(_ax_log)|$(ls "$AXH/state/answer" 2>/dev/null | wc -l | tr -d ' ')" "no block||$_ax_n0"
: > "$AX/glog"; _ax_pay u1k "$AXQ" "$AXK"; AXU="$(_ax_up "$AXK" "$AXPAY")"
is "U1: a checkout bound by its .felix marker alone is told nothing: graphify not asked, no record" "$(_ax_block "$AXU")|$(_ax_log)|$(_ax_rec u1k)" "no block||none"
: > "$AX/glog"; _ax_pay u1f "$AXQ" "$AXF"; AXU="$(_ax_up "$AXF" "$AXPAY")"
is "U1: nor is one bound by an origin that only contains the remote_match" "$(_ax_block "$AXU")|$(_ax_log)|$(_ax_rec u1f)" "no block||none"
printf -v AXPAY '{"session_id":"u2a","hook_event_name":"UserPromptSubmit","prompt":"%s","cwd":"%s","note":"never part of the question"}' 'where is the \"answer\" block built today' "$AXO"
: > "$AX/glog"; _ax_up "$AXO" "$AXPAY" >/dev/null
is "U2: an escaped quote reaches graphify as a quote, and the keys after the prompt never reach it" "$(_ax_log)" "$(_ax_q 'where is the "answer" block built today')"
printf -v AXPAY '{"session_id":"u2b","hook_event_name":"UserPromptSubmit","prompt":"%s"}' 'where is the a\\b case handled in graph'
: > "$AX/glog"; _ax_up "$AXO" "$AXPAY" >/dev/null
is "U2: an escaped backslash reaches graphify as one backslash" "$(_ax_log)" "$(_ax_q 'where is the a\b case handled in graph')"
printf -v AXPAY '{"session_id":"u2c","hook_event_name":"UserPromptSubmit","prompt":"%s","cwd":"%s","note":"do not read this"}' 'where does the trailing backslash go \\' "$AXO"
: > "$AX/glog"; _ax_up "$AXO" "$AXPAY" >/dev/null
is "U2: the prompt ends at its first unescaped quote, so a value that ends in an escaped backslash ends there" "$(_ax_log)" "$(_ax_q 'where does the trailing backslash go \')"
AXRP="the quokka ledger build is broken and failing with a crash"
_ax_pay u3b "$AXRP"; AXBASE="$(_ax_ctx "$(_ax_up "$AXO" "$AXPAY" FELIX_GRAPH_ANSWER=0)")"
_ax_pay u3w "$AXRP"; AXWITH="$(_ax_ctx "$(_ax_up "$AXO" "$AXPAY")")"
AXPRE="${AXBASE%%Lessons this project already paid for*}"; AXPOST="${AXBASE#"$AXPRE"}"; AXMID="${AXWITH#"$AXPRE"}"; AXMID="${AXMID%"$AXPOST"}"
is "U3: with no answer the routed prompt gets the route part and then the lessons part (fixture control)" \
   "$(_ax_starts "$AXBASE" "Felix routed this to: debug")|$(_ax_starts "$AXPOST" "Lessons this project already paid for")" "yes|yes"
is "U3: the answer goes after the route part and before the lessons part, the rest as it was" \
   "$([ -n "$AXMID" ] && [ "$AXPRE$AXMID$AXPOST" = "$AXWITH" ] && echo between)|$(_ax_par "$AXMID" 1 c)|$(_ax_par "$AXMID" 2)" "between|$(_ax_hd "$AXO3" "$AXCUR")|$AXROWS"
is "U3: separated from the parts on either side by one blank line" "$(_ax_gap "$AXMID")" "one"
_ax_pay u3n "ok thanks"; AXU="$(_ax_up "$AXO" "$AXPAY")"
is "U3: a prompt that produces none of the parts still exits 0 with no output" "$(cat "$AX/up.rc")|$AXU" "0|"
_ax_u4() {   # SESSION VARIANT [NAME=VALUE...] -> "status|context" of the routed prompt, under a timeout of one second
  local s="$1" o; printf '%s' "$2" > "$AX/gv"; shift 2; _ax_pay "$s" "$AXRP"
  o="$(_ax_up "$AXO" "$AXPAY" FELIX_GRAPH_TIMEOUT=1 "$@")"; printf '%s|%s' "$(cat "$AX/up.rc")" "$(_ax_ctx "$o")"
}
is "U4: a graphify that fails leaves the hook's exit 0 and its other parts as they are with no answer" "$(_ax_u4 u4f fail)" "0|$AXBASE"
_ax_t0=$SECONDS; AXU="$(_ax_u4 u4h hang)"; _ax_dt=$((SECONDS - _ax_t0))
is "U4: one that hangs past the timeout does too, and the prompt waits no more than 4 seconds" \
   "$AXU|$([ "$_ax_dt" -le 4 ] && echo prompt || echo "waited ${_ax_dt}s")" "0|$AXBASE|prompt"
is "U4: so does one that prints garbage" "$(_ax_u4 u4g garbage)" "0|$AXBASE"
is "U4: and one that is not on PATH at all" "$(_ax_u4 u4a shell PATH="$AXNOG")" "0|$AXBASE"

printf '\nT1-T2: hooks/post-tool records what the session did next\n'
_ax_pt() {   # SESSION TOOL INPUT [RESPONSE] -> post-tool in the own checkout; its status and output in $AX/pt.rc and $AX/pt.out
  local p r="${4:-}"; [ -n "$r" ] || r='{}'
  printf -v p '{"session_id":"%s","transcript_path":"/decoy/%s.jsonl","cwd":"%s","permission_mode":"default","hook_event_name":"PostToolUse","tool_name":"%s","tool_input":%s,"tool_response":%s}' \
    "$1" "$1" "$AXO" "$2" "$3" "$r"
  ( _fx_cd "$AXO" && env FELIX_HOME="$AXH" FELIX_MEMORY="$AXM" HOME="$AX/user" PATH="$AX/spy:$AX/bin:$PATH" "$FROOT/harness/hooks/post-tool" <<<"$p" > "$AX/pt.out" 2>&1
    printf '%s' "$?" > "$AX/pt.rc" )
}
AXS="$AXH/state/answer/t1.tsv"; printf 'given\tgraphify\t1\nanswer\tgraphify\tlib/one.sh\n' > "$AXS"
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s/spy.log"\nexec "%s" "$@"\n' "$AX" "$(command -v git)" > "$AX/spy/git"; chmod +x "$AX/spy/git"; : > "$AX/spy.log"
_ax_last() { tail -1 "$AXS" 2>/dev/null; }; _ax_rows() { awk 'END { print NR }' "$AXS" 2>/dev/null; }
_ax_pt t1 Read "{\"file_path\":\"$AXO/lib/one.sh\",\"limit\":5}" "{\"type\":\"text\",\"file\":{\"file_path\":\"$AXO/other.sh\"}}"
is "T1: a Read appends touch, Read and its first file_path, the input's and not the response's" "$(_ax_last)" "touch${AXT}Read${AXT}$AXO/lib/one.sh"
_ax_pt t1 Edit "{\"file_path\":\"$AXO/docs/guide.md\",\"old_string\":\"a\",\"new_string\":\"b\"}"
is "T1: an Edit appends its file_path" "$(_ax_last)" "touch${AXT}Edit${AXT}$AXO/docs/guide.md"
_ax_pt t1 Write "{\"file_path\":\"$AXO/new.md\",\"content\":\"x\"}"
is "T1: a Write appends its file_path" "$(_ax_last)" "touch${AXT}Write${AXT}$AXO/new.md"
_ax_pt t1 MultiEdit "{\"file_path\":\"$AXO/lib/one.sh\",\"edits\":[]}"
is "T1: a MultiEdit appends its file_path" "$(_ax_last)" "touch${AXT}MultiEdit${AXT}$AXO/lib/one.sh"
_ax_pt t1 NotebookEdit "{\"notebook_path\":\"$AXO/nb.ipynb\",\"new_source\":\"x\"}"
is "T1: a NotebookEdit appends its notebook_path" "$(_ax_last)" "touch${AXT}NotebookEdit${AXT}$AXO/nb.ipynb"
_ax_pt t1 Grep "{\"pattern\":\"x\",\"path\":\"$AXO/lib\"}" "{\"path\":\"/from-the-response\"}"
is "T1: a Grep appends its path, the envelope's transcript_path and the response's path passed over" "$(_ax_last)" "touch${AXT}Grep${AXT}$AXO/lib"
_ax_pt t1 Glob "{\"pattern\":\"*.md\",\"file_path\":\"/decoy-fp\",\"notebook_path\":\"/decoy-nb\",\"path\":\"$AXO/notes\"}"
is "T1: a Glob takes the first key spelled exactly path, not one that ends in path" "$(_ax_last)" "touch${AXT}Glob${AXT}$AXO/notes"
_ax_pt t1 Bash '{"command":"cat lib/one.sh","description":"x"}' '{"stdout":"","command":"not this"}'
is "T1: a Bash appends its first command" "$(_ax_last)" "touch${AXT}Bash${AXT}cat lib/one.sh"
AXC500="$(awk 'BEGIN { for (i = 0; i < 50; i++) printf "abcdefghij" }')"; _ax_pt t1 Bash "{\"command\":\"$AXC500\"}"
is "T1: a command longer than 400 characters is cut to 400" "$(_ax_last)" "touch${AXT}Bash${AXT}${AXC500:0:400}"
_ax_pt t1 Bash '{"command":"echo \"hi\" there"}'
is "T1: a value is taken up to the first double quote after the opening one, an escaped quote included" "$(_ax_last)" "touch${AXT}Bash${AXT}echo \\"
_ax_n="$(_ax_rows)"; _ax_pt t1 WebFetch '{"url":"https://example.invalid/","file_path":"/decoy","prompt":"x"}'
is "T1: a tool not in the table appends nothing, though its input holds a file_path" "$(_ax_rows)" "$_ax_n"
_ax_pt t1 Read '{"offset":3}'
is "T1: a Read whose payload holds no file_path appends nothing" "$(_ax_rows)" "$_ax_n"
is "T1: the session's ledger append is still made, a tool row for each call" "$(head -1 "$AXH/state/ledger/t1.tsv" 2>/dev/null)" "tool${AXT}Read"
_ax_pt t0 Read "{\"file_path\":\"$AXO/lib/one.sh\"}"
is "T1: with no state file nothing is appended and no state file is made, the ledger append made as before" \
   "$(_ax_rec t0)|$(cat "$AXH/state/ledger/t0.tsv" 2>/dev/null)" "none|tool${AXT}Read"
is "T2: no post-tool run, with a state file or without, ran git" "$(cat "$AX/spy.log" 2>/dev/null)" ""
_ax_ckp="$(_ax_ck "$AXS")"; chmod 444 "$AXS"
if [ -w "$AXS" ]; then skip "T2: an append that fails is silent, the exit 0 and the file unchanged" "the state file is still writable"
else _ax_pt t1 Read "{\"file_path\":\"$AXO/lib/one.sh\"}"
  is "T2: an append that fails is silent, the exit 0 and the file unchanged" "$(cat "$AX/pt.rc")|$(cat "$AX/pt.out")|$(_ax_ck "$AXS")" "0||$_ax_ckp"
fi
chmod 644 "$AXS"

printf '\nR1-R3: hooks/session-end refreshes the graph, and a lock a killed refresh left is taken back\n'
_ax_se() {   # DIR SESSION [HARNESS] -> session-end there, read through a pipe as a hook is; output and status in $AX/se.out, se.rc
  local p o; printf -v p '{"session_id":"%s","cwd":"%s","hook_event_name":"SessionEnd","reason":"other"}' "$2" "$1"
  o="$( _fx_cd "$1" && env FELIX_HOME="$AXH" FELIX_MEMORY="$AXM" HOME="$AX/user" PATH="$AX/bin:$PATH" "${3:-$FROOT/harness}/hooks/session-end" <<<"$p" 2>&1; printf '|%s' "$?" )"
  printf '%s' "${o%|*}" > "$AX/se.out"; printf '%s' "${o##*|}" > "$AX/se.rc"
}
_ax_led() { mkdir -p "$AXH/state/ledger"; printf 'tool\tBash\n' > "$AXH/state/ledger/$1.tsv"; }
_ax_fold() { awk -F'\t' '$3 == "tool" && $4 == "Bash" { print $5 }' "$AXM/ansp/ledger.d/$1.tsv" 2>/dev/null; }
_ax_nq() { awk 'index($0, "<query> ") != 1 { n++ } END { print n + 0 }' "$AX/glog"; }
_ax_nqp() { awk -v d="<$1>" 'index($0, "<query> ") != 1 && index($0, d) { n++ } END { print n + 0 }' "$AX/glog"; }
_ax_wait() { local i=0; while [ "$i" -lt "$(( $1 * 10 ))" ]; do eval "$2" && return 0; sleep 0.1; i=$((i + 1)); done; eval "$2"; }
_ax_release() {   # lets a waiting refresh finish, and waits five seconds at most for the locks to go
  : > "$AX/release"
  _ax_wait 5 '[ ! -d "$AXL" ] && [ ! -d "$AXK/graphify-out/.felix-refresh.lock" ] && [ ! -d "$AXF/graphify-out/.felix-refresh.lock" ]'
  rm -f "$AX/release"
}
_ax_stamp "$AXO" "$AXO1"; rm -f "$AX/release"; : > "$AX/glog"; _ax_led r1
_ax_t0=$SECONDS; _ax_se "$AXO" r1; _ax_dt=$((SECONDS - _ax_t0)); _ax_wait 5 '[ "$(_ax_nqp "$AXO")" -gt 0 ]'; _ax_lat=$((SECONDS - _ax_t0))
is "R1: a session ending in the own checkout, its graph behind, starts a refresh of that graph" "$(_ax_nqp "$AXO")" "1"
is "R2: the hook returns while that refresh waits, within 4 seconds, exits 0 and prints nothing" \
   "$([ "$_ax_dt" -le 4 ] && echo returned || echo "waited ${_ax_dt}s")|$(cat "$AX/se.rc")|$(cat "$AX/se.out")" "returned|0|"
is "R2: and its ledger rollup runs as before" "$(_ax_fold r1)" "1"
_ax_release; AXNEG=$(( _ax_lat * 3 + 2 )); [ "$AXNEG" -ge 3 ] || AXNEG=3; [ "$AXNEG" -le 8 ] || AXNEG=8
: > "$AX/glog"; _ax_stamp "$AXO" "$AXO3"; _ax_stamp "$AXK" "$AXK1"; _ax_stamp "$AXF" "$AXF1"
_ax_led r2; _ax_se "$AXO" r2; _ax_led r3; _ax_se "$AXK" r3; _ax_led r4; _ax_se "$AXF" r4; _ax_wait "$AXNEG" '[ "$(_ax_nq)" -gt 0 ]'
is "R2: a graph that is current starts nothing" "$(_ax_nqp "$AXO")" "0"
is "R1: a checkout bound by its .felix marker alone starts nothing, its graph behind" "$(_ax_nqp "$AXK")" "0"
is "R1: nor does one bound by an origin that only contains the remote_match" "$(_ax_nqp "$AXF")" "0"
is "R2: the rollup runs whether or not a refresh starts" "$(_ax_fold r2) $(_ax_fold r3) $(_ax_fold r4)" "1 1 1"
_ax_release; : > "$AX/glog"; _ax_stamp "$AXO" "$AXO1"; mkdir -p "$AXH/state/machine"; : > "$AXH/state/machine/r5"; _ax_led r5; _ax_se "$AXO" r5
_ax_wait "$AXNEG" '[ "$(_ax_nq)" -gt 0 ]'
is "R1: a machine session's end starts no refresh, though its checkout is own and its graph behind" "$(_ax_nq)" "0"
_ax_release; : > "$AX/glog"; _ax_led r6; _ax_se "$AXW" r6; _ax_wait 5 '[ "$(_ax_nqp "$AXO")" -gt 0 ]'
is "R1: a session ending in a worktree of the own checkout refreshes the graph of the checkout that holds it" "$(_ax_nqp "$AXO")" "1"
_ax_release
_ax_hcopy() {   # DIR -> DIR/harness, a copy of the suite's harness with its tests left out
  local x; mkdir -p "$1/harness" || return 1
  for x in "$FROOT/harness"/*; do case "$x" in */tests) ;; *) cp -R "$x" "$1/harness/" ;; esac; done
}
_ax_hcopy "$AX/hg"; rm -f "$AX/hg/harness/lib/graph.sh"; _ax_hcopy "$AX/ho"; printf 'return 1\n' > "$AX/ho/harness/lib/own.sh"
_ax_led r7; _ax_se "$AXO" r7 "$AX/hg/harness"
is "R2: with lib/graph.sh gone the session still ends with exit 0, and its rollup runs" "$(cat "$AX/se.rc")|$(_ax_fold r7)" "0|1"
_ax_led r8; _ax_se "$AXO" r8 "$AX/ho/harness"
is "R2: with lib/own.sh failing to load the session still ends with exit 0, and its rollup runs" "$(cat "$AX/se.rc")|$(_ax_fold r8)" "0|1"
_ax_release
_ax_bg() { ( PATH="$AX/bin:$PATH"; export PATH; [ -z "${AX_STALE:-}" ] || { FELIX_GRAPH_LOCK_STALE="$AX_STALE"; export FELIX_GRAPH_LOCK_STALE; }
             . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/graph.sh"; felix_graph_refresh_bg "$AXO" ) 2>&1; }
_ax_age() { perl -e '$t = time - $ARGV[0] * 60; utime $t, $t, $ARGV[1] or exit 1' "$2" "$1"; }   # DIR MINUTES
_ax_young() { perl -e 'print +(time - (stat $ARGV[0])[9] < 300) ? "young" : "old"' "$1" 2>/dev/null; }
rm -rf "$AXL"; mkdir -p "$AXL"; _ax_age "$AXL" 35; : > "$AX/glog"; AXOUT="$(_ax_bg)"; AXRC=$?; _ax_wait 5 '[ "$(_ax_nqp "$AXO")" -gt 0 ]'
is "R3: a lock directory 35 minutes old is taken back and the refresh proceeds, the call exiting 0 and printing nothing" "$(_ax_nqp "$AXO")|$AXRC|$AXOUT" "1|0|"
is "R3: and while that refresh runs the lock is a directory made just now" "$([ -d "$AXL" ] && _ax_young "$AXL")" "young"
_ax_release
is "R3: and the lock is gone once that refresh finishes" "$([ -d "$AXL" ] && echo held || echo gone)" "gone"
rm -rf "$AXL"; mkdir -p "$AXL"; _ax_age "$AXL" 25; : > "$AX/glog"; AXOUT="$(_ax_bg)"; AXRC=$?; _ax_wait "$AXNEG" '[ "$(_ax_nq)" -gt 0 ]'
is "R3: a lock 25 minutes old still means a refresh is running: nothing runs, the call exits 0 and prints nothing, the lock stays" \
   "$(_ax_nq)|$AXRC|$AXOUT|$([ -d "$AXL" ] && echo kept)" "0|0||kept"
_ax_age "$AXL" 25; : > "$AX/glog"; AX_STALE=20 _ax_bg >/dev/null; _ax_wait 5 '[ "$(_ax_nqp "$AXO")" -gt 0 ]'
is "R3: FELIX_GRAPH_LOCK_STALE=20 makes that same lock stale, and the refresh proceeds" "$(_ax_nqp "$AXO")" "1"
_ax_release; rm -rf "$AXL"; mkdir -p "$AXL"; : > "$AX/glog"; AXOUT="$(_ax_bg)"; AXRC=$?; _ax_wait "$AXNEG" '[ "$(_ax_nq)" -gt 0 ]'
is "R3: a lock made a moment ago means a refresh is running, and the call does nothing, as before" "$(_ax_nq)|$AXRC|$AXOUT|$([ -d "$AXL" ] && echo kept)" "0|0||kept"
rm -rf "$AXL"

printf '\nL1-L5: lib/ledger.sh and felix ledger, the answer as its own surface\n'
AXLH="$AX/lh"; AXLM="$AX/lm"; AXLP="$AXLH/projects/ansl"; AXLQ="$AXLH/projects/ansm"; AXLZ="$AXLH/projects/ansz"
mkdir -p "$AXLP" "$AXLQ" "$AXLZ" "$AXLM/ansl" "$AXLM/ansm/ledger.d" "$AXLM/ansz/ledger.d"
printf 'skill\tgraphify\t-\tlow\talways\nplugin\tsuperpowers@x\t-\tlow\talways\n' > "$AXLP/stack.tsv"; cp "$AXLP/stack.tsv" "$AXLQ/stack.tsv"; cp "$AXLP/stack.tsv" "$AXLZ/stack.tsv"
_ax_ll() { ( FELIX_MEMORY="$AXLM"; HOME="$AX/user"; export FELIX_MEMORY HOME; . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/ledger.sh"; "$@" ) 2>/dev/null; }
_ax_ll felix_ledger_record "$AXLH" l1 "answer${AXT}graphify"; _ax_ll felix_ledger_record "$AXLH" l1 "answer${AXT}graphify"
_ax_ll felix_ledger_record "$AXLH" l1 "tool${AXT}Bash"; _ax_ll felix_ledger_rollup "$AXLP" "$AXLH" l1 2026-10-29
_ax_ll felix_ledger_record "$AXLH" l2 "answer${AXT}graphify"; _ax_ll felix_ledger_record "$AXLH" l2 "named${AXT}graphify"
_ax_ll felix_ledger_rollup "$AXLP" "$AXLH" l2 2026-10-29
is "L1: answer signals fold to one row: session, date, answer, the tool, the deliveries, and an empty sixth field" \
   "$(awk -F'\t' '$3 == "answer"' "$AXLM/ansl/ledger.d/l1.tsv" 2>/dev/null)" "l1${AXT}2026-10-29${AXT}answer${AXT}graphify${AXT}2${AXT}"
is "L1: and graphify, declared and never reached for, still gets its zero row" \
   "$(awk -F'\t' '$3 != "answer" && $4 == "graphify" && $5 == "0" { n++ } END { print n + 0 }' "$AXLM/ansl/ledger.d/l1.tsv" 2>/dev/null)" "1"
is "L1: a route naming graphify is no naming of the answer: the answer row's sixth field stays empty" \
   "$(awk -F'\t' '$3 == "answer"' "$AXLM/ansl/ledger.d/l2.tsv" 2>/dev/null)" "l2${AXT}2026-10-29${AXT}answer${AXT}graphify${AXT}1${AXT}"
is "L1: and that naming stays with graphify itself, on a row that reached nothing" \
   "$(awk -F'\t' '$3 != "answer" && $4 == "graphify" && $5 == "0" && $6 == "1" { n++ } END { print n + 0 }' "$AXLM/ansl/ledger.d/l2.tsv" 2>/dev/null)" "1"
for _ax_i in 1 2 3 4 5; do
  printf 'm%s\t2026-10-0%s\tnamed\tgraphify\t0\t1\nm%s\t2026-10-0%s\tplugin\tsuperpowers@x\t0\t0\nm%s\t2026-10-0%s\tmcp\tplugin_playwright_playwright\t3\t0\n' \
    "$_ax_i" "$_ax_i" "$_ax_i" "$_ax_i" "$_ax_i" "$_ax_i" > "$AXLM/ansm/ledger.d/m$_ax_i.tsv"
done
printf 'z1\t2026-10-01\ttool\tBash\t1\t0\n' > "$AXLM/ansz/ledger.d/z1.tsv"
_ax_read() { FELIX_LEDGER_MIN=5 _ax_ll "$1" "$AXLQ" | tr '\t\n' ' ;'; }
_ax_r0="|"; for _ax_f in summary mcp retire unobserved partly unrouted; do _ax_r0="$_ax_r0$_ax_f=$(_ax_read "felix_ledger_$_ax_f")|"; done
is "L2: five sessions that named graphify and never reached for it put it on the retire list (fixture control)" "$(FELIX_LEDGER_MIN=5 _ax_ll felix_ledger_retire "$AXLQ" | cut -f1)" "graphify"
for _ax_i in 1 2 3 4 5; do printf 'm%s\t2026-10-0%s\tanswer\tgraphify\t2\t\n' "$_ax_i" "$_ax_i" >> "$AXLM/ansm/ledger.d/m$_ax_i.tsv"; done
printf 'm1\t2026-10-01\tanswer\tothertool\t3\t\n' >> "$AXLM/ansm/ledger.d/m1.tsv"
for _ax_f in summary mcp retire unobserved partly unrouted; do
  _ax_w="${_ax_r0#*"|$_ax_f="}"; is "L2: felix_ledger_$_ax_f reads the same with answer rows folded beside the capability rows" "$(_ax_read "felix_ledger_$_ax_f")" "${_ax_w%%|*}"
done
is "L3: felix_ledger_answers prints the tool, its distinct sessions and its summed deliveries from the folded answer rows" \
   "$(_ax_ll felix_ledger_answers "$AXLQ" | LC_ALL=C sort)" "$(printf 'graphify\t5\t10\nothertool\t1\t3')"
is "L3: and nothing for a project whose ledger holds no answer row" "$(_ax_ll felix_ledger_answers "$AXLZ")" ""
_ax_use() {   # NAME MARK ROWS -> felix_answer_use over a home holding that one session, marked at own's HEAD, a foreign commit, or not
  local h="$AX/use/$1"; mkdir -p "$h/state/answer" "$h/state/session"; printf '%b' "$3" > "$h/state/answer/$1.tsv"
  case "$2" in own) printf '%s\n' "$AXO3" > "$h/state/session/$1" ;; foreign) printf '%s\n' "$AXK1" > "$h/state/session/$1" ;; esac
  _ax_ll felix_answer_use "$AXP" "$h" "$AXO"
}
_ax_u6() { printf 'graphify\t%s\t%s\t%s\t%s\t%s\t%s' "$@"; }
is "L4: a Read whose value ends in /<file> acts on it: one session, delivery and file, each acted on" \
   "$(_ax_use ua own 'given\tgraphify\t1\nanswer\tgraphify\tlib/one.sh\ntouch\tRead\t/r/lib/one.sh\n')" "$(_ax_u6 1 1 1 1 1 1)"
is "L4: an Edit whose value equals the file acts on it" "$(_ax_use ub own 'given\tgraphify\t1\nanswer\tgraphify\tlib/one.sh\ntouch\tEdit\tlib/one.sh\n')" "$(_ax_u6 1 1 1 1 1 1)"
is "L4: a touch before the answer row does not act on it" "$(_ax_use uc own 'touch\tRead\t/r/lib/one.sh\ngiven\tgraphify\t1\nanswer\tgraphify\tlib/one.sh\n')" "$(_ax_u6 1 0 1 0 1 0)"
is "L4: a value that ends in the file's name but not at a slash does not act on it" \
   "$(_ax_use ud own 'given\tgraphify\t1\nanswer\tgraphify\ta.sh\ntouch\tRead\t/r/lib/data.sh\n')" "$(_ax_u6 1 0 1 0 1 0)"
is "L4: a Grep of the file's directory does not act on it" "$(_ax_use ue own 'given\tgraphify\t1\nanswer\tgraphify\tlib/one.sh\ntouch\tGrep\t/r/lib\n')" "$(_ax_u6 1 0 1 0 1 0)"
is "L4: a Bash command holding the file's basename, which has a dot, acts on it" \
   "$(_ax_use uf own 'given\tgraphify\t1\nanswer\tgraphify\tengine/run.sh\ntouch\tBash\tbash run.sh --fast\n')" "$(_ax_u6 1 1 1 1 1 1)"
is "L4: one holding only a basename with no dot does not" \
   "$(_ax_use ug own 'given\tgraphify\t1\nanswer\tgraphify\tbuild/Makefile\ntouch\tBash\tmake -C build Makefile\n')" "$(_ax_u6 1 0 1 0 1 0)"
is "L4: one holding the file's path acts on it, dot or none" "$(_ax_use uh own 'given\tgraphify\t1\nanswer\tgraphify\tbuild/Makefile\ntouch\tBash\tcat build/Makefile\n')" "$(_ax_u6 1 1 1 1 1 1)"
is "L4: Write, MultiEdit, NotebookEdit and Glob act on the file their value equals or ends in" \
   "$(_ax_use ui own 'given\tgraphify\t4\nanswer\tgraphify\tx/w.md\nanswer\tgraphify\tx/m.md\nanswer\tgraphify\tx/nb.ipynb\nanswer\tgraphify\tx/g.md\ntouch\tWrite\tx/w.md\ntouch\tMultiEdit\t/r/x/m.md\ntouch\tNotebookEdit\t/r/x/nb.ipynb\ntouch\tGlob\t/r/x/g.md\n')" \
   "$(_ax_u6 1 1 1 1 4 4)"
is "L4: deliveries count given rows and files answer rows, and a delivery is acted on when any file it named was" \
   "$(_ax_use uj own 'given\tgraphify\t2\nanswer\tgraphify\tlib/one.sh\nanswer\tgraphify\tdocs/guide.md\ntouch\tRead\t/r/lib/one.sh\ngiven\tgraphify\t1\nanswer\tgraphify\tnotes/n1.md\ntouch\tBash\tgrep -n x notes/other.md\n')" \
   "$(_ax_u6 1 1 2 1 3 1)"
is "L4: a session marked at a commit this repository does not hold is not read" "$(_ax_use uk foreign 'given\tgraphify\t1\nanswer\tgraphify\tlib/one.sh\ntouch\tRead\t/r/lib/one.sh\n')" ""
is "L4: nor is a session with no mark" "$(_ax_use ul none 'given\tgraphify\t1\nanswer\tgraphify\tlib/one.sh\ntouch\tRead\t/r/lib/one.sh\n')" ""
is "L4: each tool is its own line, its deliveries alone deciding whether the session acted on it" \
   "$(_ax_use um own 'given\tgraphify\t1\nanswer\tgraphify\tlib/one.sh\ngiven\tothertool\t1\nanswer\tothertool\tdocs/o.md\ntouch\tRead\t/r/docs/o.md\n' | LC_ALL=C sort)" \
   "$(printf 'graphify\t1\t0\t1\t0\t1\t0\nothertool\t1\t1\t1\t1\t1\t1')"
AXFH="$AX/l5h"; AXFM="$AX/l5m"; mkdir -p "$AXFH/projects/ansp" "$AXFH/state/answer" "$AXFH/state/session" "$AXFM/ansp/ledger.d"
cp "$AXP/project.json" "$AXP/CLAUDE.md" "$AXP/stack.tsv" "$AXFH/projects/ansp/"
printf 'v1\t2026-10-20\ttool\tBash\t2\t0\nv1\t2026-10-20\tskill\tgraphify\t0\t0\nv1\t2026-10-20\tplugin\tsuperpowers@x\t0\t0\n' > "$AXFM/ansp/ledger.d/v1.tsv"
printf 'v2\t2026-10-21\ttool\tRead\t4\t0\nv2\t2026-10-21\tskill\tgraphify\t0\t0\nv2\t2026-10-21\tplugin\tsuperpowers@x\t0\t0\n' > "$AXFM/ansp/ledger.d/v2.tsv"
_ax_fl() { ( _fx_cd "$AXO" && env FELIX_HOME="$AXFH" FELIX_MEMORY="$AXFM" HOME="$AX/user" "$FROOT/harness/felix" ledger 2>&1 ); }
_ax_hl() { awk -v h="$AXHEAD" '{ s = $0; gsub(/^[ \t]+|[ \t]+$/, "", s) } /CAPABILITY/ && !c { c = NR } s == h { n++; at = NR } END { printf "%d %s", n, (n && c && at > c) ? "after" : "not after" }' <<<"$1"; }
_ax_tl() { awk -v h="$AXHEAD" 'm && /^[ \t]*graphify[ \t]/ { gsub(/[ \t]+/, " "); print; exit } { s = $0; gsub(/^[ \t]+|[ \t]+$/, "", s) } s == h { m = 1 }' <<<"$1"; }
_ax_nx() { awk -v h="$AXHEAD" 'm == 2 { print; next } m && /^[ \t]*graphify[ \t]/ { m = 2; next } { s = $0; gsub(/^[ \t]+|[ \t]+$/, "", s) } s == h { m = 1 }' <<<"$1" | tr '\n' ' ' | tr -s ' ' | sed 's/^ //'; }
_ax_tbl() { awk '/CAPABILITY/ { t = 1 } t && $0 == "" { exit } t' <<<"$1"; }
AXF0="$(_ax_fl)"
printf 'v1\t2026-10-20\tanswer\tgraphify\t1\t\n' >> "$AXFM/ansp/ledger.d/v1.tsv"; printf 'v2\t2026-10-21\tanswer\tgraphify\t3\t\n' >> "$AXFM/ansp/ledger.d/v2.tsv"
printf 'given\tgraphify\t1\nanswer\tgraphify\tlib/one.sh\ntouch\tRead\t%s/lib/one.sh\n' "$AXO" > "$AXFH/state/answer/v1.tsv"
printf 'given\tgraphify\t2\nanswer\tgraphify\tdocs/guide.md\nanswer\tgraphify\tdocs/two.md\ngiven\tgraphify\t1\nanswer\tgraphify\tnotes/n1.md\ntouch\tBash\tcat notes/n1.md\ngiven\tgraphify\t1\nanswer\tgraphify\tnotes/n2.md\n' > "$AXFH/state/answer/v2.tsv"
printf '%s\n' "$AXO3" > "$AXFH/state/session/v1"; printf '%s\n' "$AXO3" > "$AXFH/state/session/v2"; AXF1="$(_ax_fl)"
is "L5: with no answer rows felix ledger prints no answers section, its capability table there (fixture control)" "$(_ax_hl "$AXF0")|$(_ax_tbl "$AXF0" | awk 'END { print NR }')" "0 not after|5"
is "L5: with answer rows it heads a section answers handed to sessions without being asked for, after the capability table" "$(_ax_hl "$AXF1")" "1 after"
is "L5: one line a tool: given, sessions, the answers acted on and their share, the files acted on and theirs" \
   "$(_ax_tl "$AXF1")" " graphify given 4 times in 2 sessions; 2 answers (50%) named a file the session then opened, edited or ran; 2 of 5 files (40%)"
_ax_x="$(_ax_nx "$AXF1")"
is "L5: and after the tool lines the sentence that bounds what the answers can have caused" "${_ax_x:0:${#AXSENT}}" "$AXSENT"
is "L5: the capability table's rows are the same with the answer rows as without" "$(_ax_tbl "$AXF1")" "$(_ax_tbl "$AXF0")"
: > "$AX/release"   # a refresh still waiting ends now, so nothing of this part outlives it
