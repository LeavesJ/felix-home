printf '\na Bash command that runs a routed tool is its reach: the reading, through felix_ledger_signal and a names file\n'
# Blind, written 2026-10-31 from docs/2026-10-31-cli-reach-spec.md alone, as amended at 7a9e3027 (R4: a name split by
# quoting or an escape is not seen; R6: a substitution inside ${...} is read, arithmetic is read past and not into):
# R0-R10, P7, P6's names line that is no names file, and C5's bytes. felix_ledger_signal RAW NAMES_FILE, sourced in a subshell from
# the fixture harness's lib/ledger.sh, is the black box; parts 0002, 0004, 0320 and 2130 were read for idioms, and
# origin/main only for the function's name. Why: a Bash call that ran graphify was recorded as tool Bash, so a
# command-line tool could never be reached (the spec's section 0), and a false reach would take a capability off the
# retire list on evidence of nothing (D4), so text that must not count stands beside each run that must. Every payload
# is shaped as Claude Code's PostToolUse writes it; commands are written as plain text and JSON-escaped here, except
# where the escapes are what is tested. A command past 8,191 bytes may be cut by the step bound wherever a reading's
# steps fall (R9), so past that length only what must not count is asserted.
CR7="$TMP/clireach-read"; mkdir -p "$CR7/co" "$CR7/dir.names"; CR7="$(cd "$CR7" && pwd -P)"; CR7T="$(printf '\t')"
_cr7_rep() { CR7S="$1" awk -v n="$2" 'BEGIN { s = ENVIRON["CR7S"]; for (i = 0; i < n; i++) printf "%s", s }'; }   # TEXT N -> TEXT N times
_cr7_js() {   # TEXT -> TEXT as the body of a JSON string: backslash, double quote, line break as \n, tab as \t
  local s="$1"
  s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; s="${s//$'\n'/\\n}"; s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}
CR7R='{"stdout":"done","stderr":"","interrupted":false,"isImage":false}'
_cr7_pt() {   # TOOL INPUT [RESPONSE] [TRANSCRIPT] -> a PostToolUse payload in Claude Code's key order, INPUT and RESPONSE as given
  printf '{"session_id":"cr7-s","transcript_path":"%s","cwd":"%s","permission_mode":"default","hook_event_name":"PostToolUse","tool_name":"%s","tool_input":%s,"tool_response":%s}' \
    "${4:-/u/.claude/projects/-co/cr7-s.jsonl}" "$CR7/co" "$1" "$2" "${3:-$CR7R}"
}
_cr7_pj() {   # BODY [STDOUT] [DESCRIPTION] [TRANSCRIPT] -> a Bash payload whose command is BODY as the payload writes it
  _cr7_pt Bash "{\"command\":\"$1\",\"description\":\"${3:-Run it}\"}" "{\"stdout\":\"${2:-done}\",\"stderr\":\"\",\"interrupted\":false,\"isImage\":false}" "${4:-}"
}
_cr7_sig() { ( . "$FROOT/harness/lib/ledger.sh"; felix_ledger_signal "$@" ) 2>/dev/null; }   # RAW [NAMES_FILE] -> what it prints
_cr7_on() { _cr7_sig "$(_cr7_pj "$(_cr7_js "$1")")" "${2:-$CR7/names}"; }   # COMMAND [NAMES_FILE] -> the signal for a Bash call running it
_cr7_c() { is "cli-reach $1" "$(_cr7_on "$2" "${4:-}")" "cli${CR7T}$3"; }   # NAME COMMAND NAME-REACHED [NAMES_FILE]
_cr7_n() { is "cli-reach $1" "$(_cr7_on "$2" "${3:-}")" "tool${CR7T}Bash"; }   # NAME COMMAND [NAMES_FILE]: no reach
_cr7_cj() { is "cli-reach $1" "$(_cr7_sig "$(_cr7_pj "$2")" "$CR7/names")" "cli${CR7T}$3"; }   # NAME BODY-AS-WRITTEN NAME-REACHED
_cr7_nj() { is "cli-reach $1" "$(_cr7_sig "$(_cr7_pj "$2")" "${3:-$CR7/names}")" "tool${CR7T}Bash"; }   # NAME BODY-AS-WRITTEN [NAMES_FILE]
# A payload whose command value begins at its byte V: the transcript path is padded to put it there.
_cr7_p0="$(_cr7_pj '@@cr7@@' '' '' '/')"; _cr7_p0="${_cr7_p0%%@@cr7@@*}"; CR7OFF="${#_cr7_p0}"
_cr7_pat() { _cr7_pj "$2" '' '' "/$(_cr7_rep p $(( $1 - 1 - CR7OFF )))"; }   # V BODY -> that payload
CR7N64="n$(_cr7_rep 6 62)x"; CR7N65="n$(_cr7_rep 6 63)x"   # a name of 64 bytes, and a word of 65 that is none
printf 'graphify semgrep zorbtool code-review sentry-cli\n' > "$CR7/names"; printf 'graphify gra\n' > "$CR7/names.gra"
printf 'then do else\n' > "$CR7/names.rw"; printf 'graphify %s\n' "$CR7N64" > "$CR7/names.64"
is "cli-reach fixture: the JSON escaper writes a backslash, a quote, a line break and a tab as JSON does (fixture control)" \
   "$(_cr7_js $'a\\b"c\nd\te')" 'a\\b\"c\nd\te'
_cr7_p1="$(_cr7_pat 32766 'graphify query x')"; _cr7_p1="${_cr7_p1%%graphify query x*}"
is "cli-reach fixture: a payload built for byte 32,766 has its command value start at that byte (fixture control)" "${#_cr7_p1}" "32765"

printf '\nP7, P6: felix_ledger_signal RAW [NAMES_FILE], and the names files that are none\n'
CR7P="$(_cr7_pj 'graphify query x')"
is "cli-reach P7: with no names file argument a Bash call running graphify prints tool Bash, as before" "$(_cr7_sig "$CR7P")" "tool${CR7T}Bash"
is "cli-reach P7: an empty names file argument is none" "$(_cr7_sig "$CR7P" "")" "tool${CR7T}Bash"
is "cli-reach P7: a names file that does not exist is none" "$(_cr7_sig "$CR7P" "$CR7/absent.names")" "tool${CR7T}Bash"
is "cli-reach P7: a directory where the names file would be is none" "$(_cr7_sig "$CR7P" "$CR7/dir.names")" "tool${CR7T}Bash"
printf 'graphify\n' > "$CR7/unread.names"; chmod 000 "$CR7/unread.names"
if [ -r "$CR7/unread.names" ]; then skip "cli-reach P7: an unreadable names file is none" "the file is still readable here"
else is "cli-reach P7: an unreadable names file is none" "$(_cr7_sig "$CR7P" "$CR7/unread.names")" "tool${CR7T}Bash"; fi
chmod 644 "$CR7/unread.names"
printf '\n' > "$CR7/empty.names"; : > "$CR7/zero.names"
is "cli-reach P7: a names file of one empty line is none" "$(_cr7_sig "$CR7P" "$CR7/empty.names")" "tool${CR7T}Bash"
is "cli-reach P7: a names file of no bytes is none" "$(_cr7_sig "$CR7P" "$CR7/zero.names")" "tool${CR7T}Bash"
is "cli-reach P7: with a names file holding graphify it prints cli graphify" "$(_cr7_sig "$CR7P" "$CR7/names")" "cli${CR7T}graphify"
_cr7_i=0
for _cr7_l in 'graphify  semgrep' "graphify${CR7T}semgrep" 'graphify a/b' 'graphify superpowers:brainstorming' "graphify $CR7N65" $'graphify\r' 'graphify .hidden'; do
  _cr7_i=$((_cr7_i + 1)); printf '%s\n' "$_cr7_l" > "$CR7/bad$_cr7_i.names"
done
is "cli-reach P6: a names line holding two blanks in a row is no names file" "$(_cr7_sig "$CR7P" "$CR7/bad1.names")" "tool${CR7T}Bash"
is "cli-reach P6: nor one holding a tab" "$(_cr7_sig "$CR7P" "$CR7/bad2.names")" "tool${CR7T}Bash"
is "cli-reach P6: nor one holding a word with a slash" "$(_cr7_sig "$CR7P" "$CR7/bad3.names")" "tool${CR7T}Bash"
is "cli-reach P6: nor one holding a word with a colon" "$(_cr7_sig "$CR7P" "$CR7/bad4.names")" "tool${CR7T}Bash"
is "cli-reach P6: nor one holding a word of 65 bytes" "$(_cr7_sig "$CR7P" "$CR7/bad5.names")" "tool${CR7T}Bash"
is "cli-reach P6: nor one ending in a carriage return" "$(_cr7_sig "$CR7P" "$CR7/bad6.names")" "tool${CR7T}Bash"
is "cli-reach P6: nor one holding a word that starts with a dot" "$(_cr7_sig "$CR7P" "$CR7/bad7.names")" "tool${CR7T}Bash"
_cr7_c "P6: a word of 64 bytes is a name" "$CR7N64 --flag" "$CR7N64" "$CR7/names.64"
_cr7_c "P6: and graphify beside it on that line still counts" 'graphify query x' graphify "$CR7/names.64"
is "cli-reach P7: an mcp call prints mcp and its server, though its input holds a command running graphify" \
   "$(_cr7_sig "$(_cr7_pt mcp__github__create_issue '{"command":"graphify query x","title":"t"}' '{"ok":true}')" "$CR7/names")" "mcp${CR7T}github"
is "cli-reach P7: a Skill call prints its skill" \
   "$(_cr7_sig "$(_cr7_pt Skill '{"skill":"superpowers:brainstorming","args":"graphify query x"}')" "$CR7/names")" "skill${CR7T}superpowers:brainstorming"
is "cli-reach P7: an Agent call prints its type" \
   "$(_cr7_sig "$(_cr7_pt Agent '{"description":"d","prompt":"run graphify query x","subagent_type":"ecc:code-reviewer"}')" "$CR7/names")" "agent${CR7T}ecc:code-reviewer"
is "cli-reach P7: a Read call prints tool Read" "$(_cr7_sig "$(_cr7_pt Read '{"file_path":"/opt/x/bin/graphify"}')" "$CR7/names")" "tool${CR7T}Read"
is "cli-reach P7: a tool other than Bash with a command key in its input prints its tool" \
   "$(_cr7_sig "$(_cr7_pt BashOutput '{"command":"graphify query x"}')" "$CR7/names")" "tool${CR7T}BashOutput"
is "cli-reach P7: an unparseable payload still prints nothing" "$(_cr7_sig 'not json' "$CR7/names")" ""

printf '\nR0: the text read\n'
is "cli-reach R0: blanks around the command key's colon are read past" \
   "$(_cr7_sig "$(_cr7_pt Bash '{"command" :  "graphify query x","description":"d"}')" "$CR7/names")" "cli${CR7T}graphify"
is "cli-reach R0: a name in the description is not read" "$(_cr7_sig "$(_cr7_pj 'echo x' '' 'graphify query x')" "$CR7/names")" "tool${CR7T}Bash"
is "cli-reach R0: nor one in the response" "$(_cr7_sig "$(_cr7_pj 'echo x' 'graphify query x')" "$CR7/names")" "tool${CR7T}Bash"
is "cli-reach R0: when the first \"command\" text is not the key, nothing is read" \
   "$(_cr7_sig "$(_cr7_pj 'graphify query x' | sed 's/"permission_mode":"default"/"permission_mode":"command"/')" "$CR7/names")" "tool${CR7T}Bash"
is "cli-reach R0: nor when the first command key's value is not a string" \
   "$(_cr7_sig "$(_cr7_pt Bash '{"command" : 7,"command":"graphify query x"}')" "$CR7/names")" "tool${CR7T}Bash"
is "cli-reach R0: a command key past the payload's 32,768th byte is not read" "$(_cr7_sig "$(_cr7_pat 32800 'graphify query x')" "$CR7/names")" "tool${CR7T}Bash"
is "cli-reach R0: one whose value ends before that byte is (control)" "$(_cr7_sig "$(_cr7_pat 32700 'graphify query x')" "$CR7/names")" "cli${CR7T}graphify"
is "cli-reach R0: a word the 32,768-byte bound cuts is not read, neither whole nor as the part before the cut" \
   "$(_cr7_sig "$(_cr7_pat 32766 'graphify query x')" "$CR7/names.gra")" "tool${CR7T}Bash"
_cr7_n "R0: a word the value's 16,384-byte bound cuts is not read" "echo $(_cr7_rep A 16375);graphify query x" "$CR7/names.gra"
_cr7_n "R0: nor a name wholly past that bound" "echo $(_cr7_rep A 16400);graphify query x"
_cr7_nj "R0: the bound counts the value as the payload writes it, an escape two bytes" "echo $(_cr7_rep '\/a' 5600);graphify query x"
_cr7_cj "R0: \\/ reads as a slash" '\/opt\/x\/bin\/graphify query x' graphify
_cr7_cj "R0: \\n reads as a line break" 'cd \/tmp\ngraphify query x' graphify
_cr7_nj "R0: \\t reads as a tab, a blank" 'echo a\tgraphify query x'
_cr7_cj "R0: \\\" reads as a double quote" '\"graphify\" query x' graphify
_cr7_cj "R0: \\\\ reads as a backslash" '\\graphify query x' graphify
_cr7_cj "R0: the value runs past escaped quotes to its first unescaped one" 'echo \"a\" ; graphify query x' graphify
is "cli-reach R0: and ends there, an escaped backslash before it" \
   "$(_cr7_sig "$(_cr7_pt Bash '{"command":"echo x\\","description":"; graphify query x"}')" "$CR7/names")" "tool${CR7T}Bash"
_cr7_nj "R0: \\u0067 is a character, not a g" '\u0067raphify query x'
_cr7_nj "R0: \\u000a is a character, not a line break" 'echo x\u000agraphify query x'
_cr7_nj "R0: \\u003b is a character, not a ;" 'echo x\u003bgraphify query x'
_cr7_nj "R0: \\r is a character no name holds" 'graphify\r query x'
_cr7_nj "R0: as are \\b and \\f" '\bgraphify query x; \fgraphify query y'

printf '\nR1-R2: the program word, and where a simple command starts\n'
_cr7_c "R1: the first program word that is a name is the reach" 'graphify query x; semgrep scan .' graphify
_cr7_c "R1: in the order the text holds them, not the order of the names file" 'semgrep scan .; graphify query x' semgrep
_cr7_c "R1: a name before it that is only an argument takes nothing" 'echo semgrep; graphify query x' graphify
_cr7_c "R1: a substitution's program word earlier in the text comes first" 'echo $(graphify query x) | semgrep scan -' graphify
_cr7_c "R1: and one later in the text does not displace an earlier one" 'semgrep scan . | echo $(graphify query x)' semgrep
_cr7_c "R1: nothing after the reach changes it, an unclosed quote included" "graphify query x; echo 'unclosed" graphify
_cr7_c "R2: a command's first word is its program word" 'graphify query "what calls x"' graphify
_cr7_n "R2: a name that is only an argument is no reach" 'echo graphify query x'
_cr7_c "R2: a line break starts a command" $'cd /tmp\ngraphify query x' graphify
_cr7_n "R2: a tab is a blank and starts none" $'echo a\tgraphify query x'
_cr7_c "R2: ; starts a command" 'true;graphify query x' graphify
_cr7_c "R2: & starts a command" 'sleep 1 & graphify query x' graphify
_cr7_c "R2: && starts a command" 'test -d x && graphify query x' graphify
_cr7_c "R2: || starts a command" 'false || graphify query x' graphify
_cr7_c "R2: | starts a command" 'cat f | graphify query -' graphify
_cr7_c "R2: |& starts a command" 'cat f |& graphify query -' graphify
_cr7_n "R2: a separator inside quotes starts none" "echo 'a;' graphify '&&' graphify '|' graphify"
_cr7_n "R2: nor one escaped by a backslash" 'echo a\;graphify a\&graphify a\|graphify'
_cr7_n "R2: &> is a redirection, not &" 'echo x &>log graphify query x'
_cr7_c "R2: ( opening a subshell starts a command" '(graphify query x)' graphify
_cr7_c "R2: as does && inside it" '( cd sub && graphify query x )' graphify
_cr7_c "R2: inside \$(...)" 'echo "found:" $(graphify query x)' graphify
_cr7_c "R2: inside \$(...) as an assignment's value" 'out=$(graphify query x)' graphify
_cr7_c "R2: inside backticks" 'echo `graphify query x`' graphify
_cr7_c "R2: inside <(...)" 'diff <(graphify query a) b.txt' graphify
_cr7_c "R2: inside >(...)" 'echo x > >(graphify query -)' graphify
_cr7_n "R2: none of those inside single quotes" "echo '(graphify x)' '\$(graphify x)' '\`graphify x\`' '<(graphify x)' '>(graphify x)'"
_cr7_c "R2: after !" '! graphify query x' graphify
_cr7_c "R2: after {" '{ graphify query x; }' graphify
_cr7_c "R2: after if" 'if graphify query x; then :; fi' graphify
_cr7_c "R2: after then" 'if true; then graphify query x; fi' graphify
_cr7_c "R2: after else" 'if false; then :; else graphify query x; fi' graphify
_cr7_c "R2: after elif" 'if false; then :; elif graphify query x; then :; fi' graphify
_cr7_c "R2: after while" 'while graphify query x; do break; done' graphify
_cr7_c "R2: after until" 'until graphify query x; do :; done' graphify
_cr7_c "R2: after do" 'for f in a b; do graphify query "$f"; done' graphify
_cr7_n "R2: a reserved word where an argument stands starts none" 'echo if graphify then graphify do graphify ! graphify { graphify'
_cr7_c "R2: after the ) that ends a case pattern" 'case "$1" in q) graphify query x;; esac' graphify
_cr7_c "R2: after a pattern written with its opening (" 'case "$1" in (q) graphify query x;; esac' graphify
_cr7_c "R2: after a later pattern's )" 'case "$1" in a|b) :;; q) graphify query x;; esac' graphify
_cr7_c "R2: at the start of a function's body, NAME()" 'g() { graphify query "$@"; }' graphify
_cr7_c "R2: NAME ()" 'g () { graphify query "$@"; }' graphify
_cr7_c "R2: function NAME" 'function g { graphify query "$@"; }' graphify
_cr7_c "R2: function NAME()" 'function g() { graphify query "$@"; }' graphify
_cr7_c "R2: a body that is a subshell" 'g() ( graphify query "$@" )' graphify
_cr7_n "R2: the function's own name is no program word, NAME()" 'graphify() { echo "$@"; }'
_cr7_n "R2: nor NAME ()" 'graphify () { echo "$@"; }'
_cr7_n "R2: nor function NAME" 'function graphify { echo "$@"; }'
_cr7_n "R2: nor function NAME()" 'function graphify() { echo "$@"; }'

printf '\nR3: the words passed over before the program word\n'
_cr7_c "R3: an assignment" 'FOO=1 graphify query x' graphify
_cr7_c "R3: one whose quoted value holds a blank" 'X="a b" graphify query x' graphify
_cr7_c "R3: one whose value is a substitution" 'P=$(pwd) graphify query x' graphify
_cr7_c "R3: one written +=" 'A+=1 graphify query x' graphify
_cr7_c "R3: several" '_v9=1 B=2 graphify query x' graphify
_cr7_n "R3: a word that is no identifier before = is the program word" '1X=2 graphify query x'
_cr7_n "R3: nor is a quoted one an assignment" '"FOO"=1 graphify query x'
_cr7_n "R3: nor one with a hyphen" 'F-O=1 graphify query x'
_cr7_c "R3: a redirection with its target in the same word" '>out.txt graphify query x' graphify
_cr7_c "R3: one with its target the next word" '> out.txt graphify query x' graphify
_cr7_c "R3: one after a descriptor number" '2>/dev/null graphify query x' graphify
_cr7_c "R3: 2>&1" '2>&1 graphify query x' graphify
_cr7_c "R3: < >> and >|" '< in.txt >>log >|f graphify query x' graphify
_cr7_c "R3: <> <& and >&" '<>f <&0 >&2 graphify query x' graphify
_cr7_c "R3: &> and &>>" '&>f &>>g graphify query x' graphify
_cr7_c "R3: <<< with a quoted word" '<<<"s t" graphify query x' graphify
_cr7_c "R3: <<< with its word next" '<<< s graphify query x' graphify
_cr7_n "R3: a redirection's target is no program word" '> graphify echo x'
_cr7_n "R3: nor one after a descriptor number" '2> graphify echo x'
_cr7_n "R3: nor a here-string's word" '<<< graphify cat'
_cr7_n "R3: nor a target at the end" 'echo x > graphify'
_cr7_n "R3: nor the file \$(< ...) reads" 'echo $(< graphify)'
_cr7_c "R3: time" 'time graphify query x' graphify
_cr7_c "R3: time -p" 'time -p graphify query x' graphify
_cr7_c "R3: nohup" 'nohup graphify query x &' graphify
_cr7_c "R3: exec" 'exec graphify query x' graphify
_cr7_c "R3: exec -c -l" 'exec -c -l graphify query x' graphify
_cr7_c "R3: exec -a NAME" 'exec -a g graphify query x' graphify
_cr7_c "R3: command" 'command graphify query x' graphify
_cr7_c "R3: command -p" 'command -p graphify query x' graphify
_cr7_c "R3: nice" 'nice graphify query x' graphify
_cr7_c "R3: nice -n N" 'nice -n 5 graphify query x' graphify
_cr7_c "R3: nice -N" 'nice -5 graphify query x' graphify
_cr7_c "R3: nice --adjustment=N" 'nice --adjustment=5 graphify query x' graphify
_cr7_c "R3: env" 'env graphify query x' graphify
_cr7_c "R3: env -i and -" 'env -i - graphify query x' graphify
_cr7_c "R3: env -u NAME" 'env -u HOME graphify query x' graphify
_cr7_c "R3: env -C DIR" 'env -C /tmp graphify query x' graphify
_cr7_c "R3: env -P PATH" 'env -P /usr/bin graphify query x' graphify
_cr7_c "R3: env and assignments" 'env A=1 B="x y" graphify query x' graphify
_cr7_c "R3: env and other - options, -v among them" 'env -v --unset=HOME graphify query x' graphify
_cr7_c "R3: timeout and its duration" 'timeout 30 graphify query x' graphify
_cr7_c "R3: timeout -s SIG -k DUR" 'timeout -s KILL -k 5 30s graphify query x' graphify
_cr7_c "R3: timeout and another - option" 'timeout --foreground 1.5m graphify query x' graphify
_cr7_c "R3: -- ends a wrapper's options" 'env -- graphify query x' graphify
_cr7_c "R3: wrappers chain" 'nohup time graphify query x' graphify
_cr7_c "R3: through assignments and options" 'FOO=1 env A=2 nice -n 3 timeout 9 graphify query x' graphify
_cr7_c "R3: a wrapper is known by its word after the last /" '/usr/bin/env -i /usr/bin/nice graphify query x' graphify
_cr7_n "R3: exec -a takes the next word" 'exec -a graphify echo x'
_cr7_n "R3: env -u takes the next word" 'env -u graphify echo x'
_cr7_n "R3: env -C and -P take the next word" 'env -C graphify -P graphify echo x'
_cr7_n "R3: nice -n takes the next word" 'nice -n graphify echo x'
_cr7_n "R3: timeout -s and -k take the next word" 'timeout -s graphify -k graphify 5 echo x'
_cr7_n "R3: timeout takes one duration word" 'timeout graphify echo x'
_cr7_n "R3: a name after the program word a wrapper leads to is an argument" 'nohup time -p echo graphify'
_cr7_n "R3: command -v looks a program up and runs none" 'command -v graphify'
_cr7_n "R3: nor does command -V" 'command -V graphify'
_cr7_n "R3: nor an option word holding v among other letters" 'command -pv graphify'
_cr7_n "R3: nor -v after another option" 'command -p -v graphify'
_cr7_n "R3: env -S has no program word this reading follows" "env -S 'graphify query x'"
_cr7_n "R3: nor env --split-string" "env --split-string='graphify query x'"
_cr7_n "R3: nor -S before a bare name" '/usr/bin/env -S graphify query x'

printf '\nR4-R5: the program word'"'"'s name, compared exactly\n'
_cr7_c "R4: a single-quoted program word" "'graphify' query x" graphify
_cr7_c "R4: a double-quoted one" '"graphify" query x' graphify
_cr7_c "R4: one after a backslash" '\graphify query x' graphify
_cr7_c "R4: ./graphify" './graphify query x' graphify
_cr7_c "R4: ~/.local/bin/graphify" '~/.local/bin/graphify query x' graphify
_cr7_c "R4: /opt/x/bin/graphify" '/opt/x/bin/graphify query x' graphify
_cr7_c "R4: \$HOME/.local/bin/graphify" '$HOME/.local/bin/graphify query x' graphify
_cr7_c "R4: \"\$D\"/graphify" '"$D"/graphify query x' graphify
_cr7_c "R4: a quoted path holding a blank" '"/opt/my tools/graphify" query x' graphify
_cr7_n "R4: a name split by double quotes is not seen" 'gra"phi"fy query x'
_cr7_n "R4: nor one split by a backslash" 'gra\phify query x'
_cr7_n "R4: nor one split by single quotes" "gr'aphif'y query x"
_cr7_n "R4: a program word that is a parameter names nothing" 'G=graphify; $G query x'
_cr7_n "R4: nor one in braces or in quotes" '${G} query x; "$G" query x'
_cr7_n "R4: nor a substitution" '$(command -v graphify) query x'
_cr7_n "R4: nor a word whose last part holds a parameter" '/opt/bin/$G query x; /opt/bin/graphify$v query x; x$y query'
_cr7_n "R4: nor one whose last part holds a substitution or a backtick" 'graph$(true)ify query x; graph`true`ify query x'
_cr7_n "R4: a reserved word is no program word, though the names file names it" 'if true; then :; else :; fi; while false; do :; done' "$CR7/names.rw"
_cr7_n "R5: Graphify is not graphify" 'Graphify query x'
_cr7_n "R5: nor is GRAPHIFY" 'GRAPHIFY query x'
_cr7_n "R5: nor graphifyx" 'graphifyx query x'
_cr7_n "R5: nor graphif, a prefix" 'graphif query x'
_cr7_n "R5: nor xgraphify" 'xgraphify query x'
_cr7_n "R5: nor graphify.sh" './graphify.sh query x'
_cr7_c "R5: a name with a hyphen is compared whole" 'code-review --staged' code-review
_cr7_n "R5: and code_review is not code-review" 'code_review --staged'

printf '\nR6: text a command only carries\n'
_cr7_n "R6: words inside single quotes" "echo 'a; graphify query x'"
_cr7_c "R6: and a command after the quote closes" "echo 'a'; graphify query x" graphify
_cr7_n "R6: words inside double quotes" 'echo "a; graphify query x"'
_cr7_c "R6: but a \$(...) inside double quotes is read" 'echo "nodes: $(graphify query x)"' graphify
_cr7_c "R6: and a backtick substitution inside them" 'echo "nodes: `graphify query x`"' graphify
_cr7_n "R6: an escaped \$ inside double quotes opens nothing" 'echo "\$(graphify query x)"'
_cr7_n "R6: words inside \$'...'" "echo \$'a; graphify query x'"
_cr7_c "R6: \$'...' ends where the shell ends it, past an escaped quote" "echo \$'it\\'s'; graphify query x" graphify
_cr7_n "R6: words inside \${...}" 'echo ${x:-graphify query x}'
_cr7_n "R6: a separator inside \${...} starts none" 'echo ${x:-a;graphify}'
_cr7_c "R6: but a \$(...) inside \${...} is read, as the shell runs it" 'echo ${x:-$(graphify query x)}' graphify
_cr7_c "R6: as is a backtick substitution inside \${...}" 'echo ${x:-`graphify query x`}' graphify
_cr7_c "R6: and a command after \${...} closes" 'echo ${x}; graphify query x' graphify
_cr7_c "R6: the # of \${#x} begins no comment" 'echo ${#x}; graphify query x' graphify
_cr7_n "R6: a comment" 'echo a # graphify query x'
_cr7_n "R6: a comment line" '# graphify query x'
_cr7_n "R6: a separator inside a comment starts none" 'true #; graphify query x'
_cr7_n "R6: a comment line after a blank-led line break" $'echo a\n  # graphify query x'
_cr7_c "R6: a # inside a word begins no comment" 'echo a#b; graphify query x' graphify
_cr7_c "R6: a comment ends at its line" $'echo a # note\ngraphify query x' graphify
_cr7_n "R6: arguments of any program" "which graphify; pgrep -fl graphify; grep 'graphify ' notes.md; ls ~/.local/bin/graphify"
_cr7_n "R6: a case subject" 'case graphify in *) echo y;; esac'
_cr7_n "R6: a case pattern" 'case "$1" in graphify) echo y;; esac'
_cr7_n "R6: an alternative after |" 'case "$1" in a|graphify) echo y;; esac'
_cr7_n "R6: a pattern with its opening (" 'case "$1" in (graphify) echo y;; esac'
_cr7_n "R6: the words after for" 'for t in graphify semgrep; do echo "$t"; done'
_cr7_n "R6: and for's own variable" 'for graphify in a; do echo x; done'
_cr7_n "R6: the words after select" 'select t in graphify semgrep; do break; done'
_cr7_c "R6: and the command after its do" 'select t in a b; do graphify query "$t"; done' graphify
_cr7_n "R6: the words after [[" '[[ -n graphify ]]'
_cr7_n "R6: && and || inside [[ ]] start none" '[[ a && graphify || graphify ]]'
_cr7_n "R6: nor does ( inside [[ ]]" '[[ ( graphify ) ]]'
_cr7_c "R6: && after ]] does" '[[ -n x ]] && graphify query x' graphify
_cr7_n "R6: array values in a=(...)" 'a=(graphify semgrep)'
_cr7_c "R6: and a command after the array" 'a=(x y); graphify query x' graphify
_cr7_n "R6: arithmetic in ((...))" '(( graphify + 1 ))'
_cr7_n "R6: arithmetic in \$((...))" 'echo $(( graphify ))'
_cr7_n "R6: a substitution inside ((...)) is not read" '(( n = $(graphify query x) ))'
_cr7_n "R6: nor one inside \$((...))" 'echo $(( $(graphify query x) + 1 ))'
_cr7_c "R6: ((...)) is read to its closing pair" '(( n++ )); graphify query x' graphify
_cr7_c "R6: and \$((...)) to its own, parentheses inside it" 'echo $(( (2+3)*4 )); graphify query x' graphify
_cr7_c "R6: << inside arithmetic opens no here-document" $'echo $(( 1 << 2 ))\ngraphify query x' graphify
_cr7_c "R6: two subshells opened with a blank between are no arithmetic" '( ( graphify query x ) )' graphify

printf '\nR7-R8: here-documents, and line continuation\n'
_cr7_n "R7: a here-document body, <<WORD" $'cat <<EOF\ngraphify query x\nEOF'
_cr7_c "R7: reading resumes after the line that is WORD alone" $'cat <<EOF\nx\nEOF\ngraphify query x' graphify
_cr7_c "R7: the operator's own line is read on past it" $'cat <<EOF | graphify query -\nx\nEOF' graphify
_cr7_n "R7: and the words after the operator on its line are arguments" $'cat <<EOF notes.md graphify\nx\nEOF'
_cr7_n "R7: a substitution in a body is text" $'cat <<EOF\n$(graphify query x)\nEOF'
_cr7_n "R7: <<-WORD, its delimiter after leading tabs" $'cat <<-EOF\n\tgraphify query x\n\tEOF'
_cr7_c "R7: and reading resumes after that line" $'cat <<-EOF\n\tx\n\tEOF\ngraphify query x' graphify
_cr7_n "R7: <<- strips tabs only: blanks before WORD do not end it" $'cat <<-EOF\n  EOF\ngraphify query x\nEOF'
_cr7_n "R7: plain << ends at WORD alone, not at a tabbed WORD" $'cat <<EOF\n\tEOF\ngraphify query x\nEOF'
_cr7_n "R7: nor at WORD with a blank after it" $'cat <<EOF\nEOF \ngraphify query x\nEOF'
_cr7_n "R7: << WORD, a blank before it" $'cat << EOF\ngraphify query x\nEOF'
_cr7_c "R7: << WORD resumes after its delimiter" $'cat << EOF\nx\nEOF\ngraphify query x' graphify
_cr7_n "R7: <<'WORD'" $'cat <<\'EOF\'\ngraphify query x\nEOF'
_cr7_c "R7: <<'WORD' resumes after its delimiter" $'cat <<\'EOF\'\nx\nEOF\ngraphify query x' graphify
_cr7_n "R7: <<\"WORD\"" $'cat <<"EOF"\ngraphify query x\nEOF'
_cr7_c "R7: <<\"WORD\" resumes after its delimiter" $'cat <<"EOF"\nx\nEOF\ngraphify query x' graphify
_cr7_n "R7: <<\\WORD" $'cat <<\\EOF\ngraphify query x\nEOF'
_cr7_c "R7: <<\\WORD resumes after its delimiter" $'cat <<\\EOF\nx\nEOF\ngraphify query x' graphify
_cr7_c "R7: WORD of letters, digits, _ . and -" $'cat <<END.x-1_y\ngraphify query x\nEND.x-1_y\ngraphify query y' graphify
_cr7_n "R7: several on one line are read in order: the second body is text" $'cat <<A <<B\nx\nA\ngraphify query x\nB'
_cr7_c "R7: and reading resumes after the second" $'cat <<A <<B\nx\nA\ny\nB\ngraphify query x' graphify
_cr7_c "R7: <<< is a here-string, not a here-document" $'cat <<<EOF\ngraphify query x\nEOF' graphify
_cr7_c "R7: << inside quotes opens nothing" $'echo "<<EOF"\ngraphify query x' graphify
_cr7_n "R8: a backslash at a line's end joins it to the next, no separator" $'echo a \\\ngraphify query x'
_cr7_c "R8: so a command continued after ; is read" $'true; \\\ngraphify query x' graphify
_cr7_c "R8: and one continued before &&" $'test -d x \\\n&& graphify query x' graphify
_cr7_n "R8: a name the join would spell is split in the text, and not seen" $'graph\\\nify query x'

printf '\nR9-R10: where the reading ends, and the runs it does not see\n'
_cr7_n "R9: an unclosed single quote ends the reading" "echo 'x; graphify query x"
_cr7_n "R9: as does an unclosed double quote" 'echo "x; graphify query x'
_cr7_n "R9: and an unclosed \$'" "echo \$'x; graphify query x"
_cr7_c "R9: a program word read before an unclosed quote still counts" 'graphify query x; echo "x' graphify
_cr7_n "R9: a here-document whose delimiter has another shape ends it" $'cat <<\'E F\'\nx\nE F\ngraphify query x'
_cr7_n "R9: as does one whose delimiter is an expansion" $'cat <<$D\nx\n$D\ngraphify query x'
_cr7_c "R9: a program word before such a here-document still counts" $'graphify query x; cat <<\'E F\'\ny\nE F' graphify
_cr7_n "R9: a here-document whose delimiter line is never found ends it" $'cat <<EOF\nx\ngraphify query x'
_cr7_c "R9: and a program word before it still counts" $'graphify query x; cat <<EOF\ny' graphify
_cr7_c "R9: graphify inside 32 nested \$( is read" "$(_cr7_rep '$(' 32)graphify query x$(_cr7_rep ')' 32)" graphify
_cr7_n "R9: inside 33 it is not" "$(_cr7_rep '$(' 33)graphify query x$(_cr7_rep ')' 33)"
_cr7_n "R9: and nothing after such a construct is read" "$(_cr7_rep '$(' 33)x$(_cr7_rep ')' 33); graphify query x"
_cr7_c "R9: a name before it still counts" "semgrep scan .; $(_cr7_rep '$(' 33)graphify query x$(_cr7_rep ')' 33)" semgrep
_cr7_c "R9: inside 32 nested subshells it is read" "$(_cr7_rep '( ' 32)graphify query x$(_cr7_rep ' )' 32)" graphify
_cr7_n "R9: inside 33 it is not, ( a level like \$(" "$(_cr7_rep '( ' 33)graphify query x$(_cr7_rep ' )' 33)"
_cr7_c "R9: a \"...\" is a level: 16 of \"\$( are 32 levels, read" "$(_cr7_rep '"$(' 16)graphify query x$(_cr7_rep ')"' 16)" graphify
_cr7_n "R9: one \$( more is 33, not read" "$(_cr7_rep '"$(' 16)\$(graphify query x)$(_cr7_rep ')"' 16)"
# Commands shorter than 8,192 bytes as the payload writes them, built to take many steps: each is read whole.
CR7S1="$(_cr7_rep 'a;' 4087)graphify query x"; CR7S2="$(_cr7_rep "'a' " 2043);graphify query x"; CR7S3="$(_cr7_rep ':\n' 2724)graphify query x"
CR7S4="$(_cr7_rep '$(:);' 1634)graphify query x"; CR7S5="$(_cr7_rep '"a";' 1360)graphify query x"
is "cli-reach fixture: the step-bound commands are 8,170 to 8,191 bytes as the payload writes them (fixture control)" \
   "$(for _cr7_w in "$(_cr7_js "$CR7S1")" "$(_cr7_js "$CR7S2")" "$CR7S3" "$(_cr7_js "$CR7S4")" "$(_cr7_js "$CR7S5")"; do
        if [ "${#_cr7_w}" -ge 8170 ] && [ "${#_cr7_w}" -le 8191 ]; then printf 'in '; else printf 'out(%s) ' "${#_cr7_w}"; fi; done)" "in in in in in "
_cr7_c "R9: a command under 8,192 bytes of ; separated commands is read whole" "$CR7S1" graphify
_cr7_c "R9: one of single-quoted words" "$CR7S2" graphify
_cr7_cj "R9: one of escaped line breaks" "$CR7S3" graphify
_cr7_c "R9: one of substitutions opened and closed" "$CR7S4" graphify
_cr7_c "R9: one of double-quoted words, each quote two bytes as written" "$CR7S5" graphify
_cr7_n "R10: bash -c" "bash -c 'graphify query x'"
_cr7_n "R10: sh -c" 'sh -c "graphify query x"'
_cr7_n "R10: eval" 'eval graphify query x'
_cr7_n "R10: ssh host" "ssh host 'graphify query x'; ssh host graphify query x"
_cr7_n "R10: xargs" 'printf "%s\n" a | xargs graphify query'
_cr7_n "R10: sudo" 'sudo graphify query x'
_cr7_n "R10: watch" 'watch graphify query x'
_cr7_n "R10: an interpreter running a module, and package runners" 'python3 -m graphify query x; uvx graphify query x; npx graphify query x'
_cr7_n "R10: coproc" 'coproc graphify query x'
_cr7_n "R10: an alias" $'alias g=graphify\ng query x'

printf '\nC5: the reading counts bytes, under a UTF-8 locale too\n'
# Each payload holds two-byte characters raw, as Claude Code writes them; a reading that counted characters would place
# the bounds twice as far out and read the name each negative here keeps past them.
CR7U8="$(locale -a 2>/dev/null | awk '{ l = tolower($0) } l == "en_us.utf-8" || l == "en_us.utf8" { e = $0 } l ~ /utf-?8$/ && a == "" { a = $0 } END { print (e != "" ? e : a) }')"
CR7E="$(printf '\303\251')"   # e acute: one character, two bytes in UTF-8
_cr7_u8() { ( LC_ALL="$CR7U8"; export LC_ALL; . "$FROOT/harness/lib/ledger.sh"; felix_ledger_signal "$@" ) 2>/dev/null; }   # as _cr7_sig, in that locale
for _cr7_w in "a command holding two-byte characters still runs graphify|cli${CR7T}graphify|echo '$CR7E$CR7E'; graphify query x|" \
              "the value's 16,384-byte bound counts bytes, not characters|tool${CR7T}Bash|echo $(_cr7_rep "$CR7E" 8200);graphify query x|" \
              "the payload's 32,768-byte bound counts bytes too|tool${CR7T}Bash|graphify query x|/$(_cr7_rep "$CR7E" 16400)"; do
  _cr7_l="${_cr7_w#*|}"; _cr7_b="${_cr7_l#*|}"
  if [ -z "$CR7U8" ]; then skip "cli-reach C5: in a UTF-8 locale, ${_cr7_w%%|*}" "no UTF-8 locale here"
  else is "cli-reach C5: in a UTF-8 locale, ${_cr7_w%%|*}" "$(_cr7_u8 "$(_cr7_pj "${_cr7_b%|*}" '' '' "${_cr7_b##*|}")" "$CR7/names")" "${_cr7_l%%|*}"; fi
done

printf '\nAmended in review: R7 continued body lines, R3 options that take an argument, R5, R6 comments in arrays\n'
# Written 2026-11-05 from the spec as amended at 1af1e086, R7 as narrowed after it, the same way: each rule's runs that
# must count beside the text that must not. In an unquoted here-document the shell joins a body line ending in a
# backslash to the next before it looks for WORD, so a WORD line directly after one ends the reading (R9); a backslash
# line further up changes nothing, and the quoted forms join no lines, so those controls hold before the fix and after.
_cr7_n "R7: in an unquoted here-document a WORD line directly after a body line ending in a backslash is no end: it ends the reading" $'cat > n <<EOF\nx \\\nEOF\ngraphify q\nEOF'
_cr7_n "R7: nothing after that line is read, a later WORD line and a command after it included" $'cat <<EOF\nx \\\nEOF\nEOF\ngraphify q'
_cr7_c "R7: a backslash line further up changes nothing: the lines join, WORD ends the body, and a command after it counts" $'cat > n <<EOF\nx \\\ny\nEOF\ngraphify q' graphify
_cr7_n "R7: a << WORD body takes the same rule" $'cat << EOF\nx \\\nEOF\ngraphify q\nEOF'
_cr7_n "R7: as does a <<-WORD body, its WORD line after leading tabs" $'cat <<-EOF\n\tx \\\n\tEOF\ngraphify q\nEOF'
_cr7_c "R7: a program word before such a here-document still counts" $'graphify q; cat <<EOF\nx \\\nEOF\nsemgrep s\nEOF' graphify
_cr7_c "R7: a backslash inside a body line, not at its end, ends nothing" $'cat <<EOF\na \\ b\nEOF\ngraphify q' graphify
_cr7_c "R7: a <<'WORD' body keeps the old rule: its backslash line is text and the WORD line ends it" $'cat > n <<\'EOF\'\nx \\\nEOF\ngraphify q\nEOF' graphify
_cr7_c "R7: as does a <<\"WORD\" body" $'cat > n <<"EOF"\nx \\\nEOF\ngraphify q\nEOF' graphify
_cr7_c "R7: and a <<\\WORD body" $'cat > n <<\\EOF\nx \\\nEOF\ngraphify q\nEOF' graphify
_cr7_c "R3: time -o FILE takes its file" 'time -o out.txt graphify query x' graphify
_cr7_c "R3: time -f FORMAT takes its format" "time -f '%e s' graphify query x" graphify
_cr7_c "R3: /usr/bin/time -o FILE" '/usr/bin/time -o out.txt graphify query x' graphify
_cr7_c "R3: nice --adjustment N" 'nice --adjustment 5 graphify query x' graphify
_cr7_c "R3: env --unset NAME" 'env --unset HOME graphify query x' graphify
_cr7_c "R3: env --chdir DIR" 'env --chdir /tmp graphify query x' graphify
_cr7_c "R3: timeout --signal SIG, then its duration" 'timeout --signal KILL 30 graphify query x' graphify
_cr7_c "R3: timeout --kill-after DUR, then its duration" 'timeout --kill-after 5 30 graphify query x' graphify
_cr7_n "R3: time -o takes the next word" 'time -o graphify echo x'
_cr7_n "R3: time -f takes the next word" 'time -f graphify echo x'
_cr7_n "R3: /usr/bin/time -f takes the next word" '/usr/bin/time -f graphify echo x'
_cr7_n "R3: nice --adjustment takes the next word" 'nice --adjustment graphify echo x'
_cr7_n "R3: env --unset takes the next word" 'env --unset graphify echo x'
_cr7_n "R3: env --chdir takes the next word" 'env --chdir graphify echo x'
_cr7_n "R3: timeout --signal takes its signal, so the word after it is the duration" 'timeout --signal KILL graphify echo x'
_cr7_n "R3: timeout --kill-after takes its duration, so the word after it is the duration" 'timeout --kill-after 5 graphify echo x'
_cr7_n "R3: an option written with = is one word, its value no program" 'env --chdir=graphify ls'
_cr7_c "R3: and the word after it is the program word" 'env --chdir=/tmp graphify query x' graphify
_cr7_c "R3: timeout --signal=SIG is one word too" 'timeout --signal=KILL 30 graphify query x' graphify
_cr7_n "R5: a double-quoted word holding two names is neither" '"graphify semgrep" x'
_cr7_n "R5: nor a single-quoted one, its names either way round" "'semgrep graphify' x"
_cr7_n "R6: a comment among an array's values is a comment, and a ) in it closes nothing" $'a=(\n  semgrep # 1) x\n  graphify # 2) y\n)'
_cr7_c "R6: the array closes at its own ), and a command after it is read" $'a=(\n  x # 1) y\n)\ngraphify query x' graphify
