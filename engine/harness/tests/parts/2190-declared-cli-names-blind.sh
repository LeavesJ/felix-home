printf '\na CLI that stack.tsv declares is a name too: the names file, the record and the fold (cli-reach amendment, N7-N9)\n'
# Blind, written 2026-11-06 from docs/2026-10-31-cli-reach-spec.md section 9 alone (N7, N8, N9), with sections 0-8 read
# for the behaviour it builds on. hooks/session-start, hooks/post-tool and lib/ledger.sh are black boxes; parts 2170 and
# 2180 were read for idioms and the call shapes of the hooks and of felix_ledger_rollup. Why: a CLI that stack.tsv
# declares with its own cli kind (elenchus: cli strix-agent) and that no route names was never a name, so a session
# that ran it recorded tool Bash and its stack zero row said it was never reached (9.1 a). Fixture: home dc9/home with
# project zorb (remote_match acme/zorb-dc9), the checkout co bound by its origin, and ungov, which nothing governs.
# Every hook runs on a PATH of links to the suite's programs less claude, gh, felix and the tools named here, so nothing
# starts in the background. Only the fixture homes this part makes are touched.
DC9="$TMP/clireach-declared"; mkdir -p "$DC9/user" "$DC9/tmp" "$DC9/co" "$DC9/ungov" "$DC9/farm" "$DC9/home/projects/zorb" "$DC9/mem"
DC9="$(cd "$DC9" && pwd -P)"; DC9H="$DC9/home"; DC9M="$DC9/mem"; DC9P="$DC9H/projects/zorb"; DC9C="$DC9/co"; DC9T="$(printf '\t')"; DC9NL=$'\n'
printf '{"name": "zorb", "remote_match": "acme/zorb-dc9", "gate": "true"}\n' > "$DC9P/project.json"; printf '# zorb\n' > "$DC9P/CLAUDE.md"
( _fx_cd "$DC9C" && git init -q -b main && git remote add origin https://github.com/acme/zorb-dc9 \
  && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -q --allow-empty -m c1 ) >/dev/null 2>&1
( _fx_cd "$DC9/ungov" && git init -q -b main ) >/dev/null 2>&1
perl -e 'my ($at, $path, @no) = @ARGV; my %no = map { $_ => 1 } @no; my %seen;
  for my $d (split /:/, $path) { opendir(my $h, $d) or next;
    for my $n (readdir $h) { next if $n =~ /^\./ || $no{$n} || $seen{$n}; my $f = "$d/$n"; next unless -f $f && -x _;
      $seen{$n} = 1; symlink($f, "$at/$n") } }' "$DC9/farm" "$PATH" claude gh felix graphify semgrep strix-agent zeta-cli
_dc9_rep() { DC9S="$1" awk -v n="$2" 'BEGIN { s = ENVIRON["DC9S"]; for (i = 0; i < n; i++) printf "%s", s }'; }   # TEXT N -> TEXT N times
_dc9_js() {   # TEXT -> TEXT as the body of a JSON string: backslash, double quote, line break as \n, tab as \t
  local s="$1"
  s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; s="${s//$'\n'/\\n}"; s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}
DC9LC=""   # a locale for the next session start, when set
_dc9_ssp() {  # PAYLOAD DIR HOME MEMORY -> session-start there, fed PAYLOAD; its output and status in $DC9/ss.out, ss.rc
  ( _fx_cd "$2" && env -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CONFIG_DIR -u CLAUDE_PLUGIN_ROOT -u CLAUDE_PROJECT_DIR -u FELIX_HOME_DIR \
      -u COPILOT_CLI -u CURSOR_PLUGIN_ROOT -u GIT_DIR -u GIT_WORK_TREE ${DC9LC:+LC_ALL=$DC9LC LANG=$DC9LC} \
      HOME="$DC9/user" FELIX_HOME="$3" FELIX_MEMORY="$4" TMPDIR="$DC9/tmp" PATH="$DC9/farm" \
      "$FROOT/harness/hooks/session-start" <<<"$1" > "$DC9/ss.out" 2> "$DC9/ss.err"; printf '%s' "$?" > "$DC9/ss.rc" )
}
_dc9_ss() {   # SESSION [DIR] [HOME] [MEMORY] -> session-start for a payload shaped as Claude Code's SessionStart, source startup
  _dc9_ssp "{\"session_id\":\"$1\",\"transcript_path\":\"$DC9/tr/$1.jsonl\",\"cwd\":\"${2:-$DC9C}\",\"hook_event_name\":\"SessionStart\",\"source\":\"startup\"}" \
    "${2:-$DC9C}" "${3:-$DC9H}" "${4:-$DC9M}"
}
DC9R='{"stdout":"done","stderr":"","interrupted":false,"isImage":false}'
_dc9_pt() {   # SESSION TOOL INPUT -> post-tool in the checkout, fed that call; status in $DC9/pt.rc, output in pt.out
  printf '{"session_id":"%s","transcript_path":"%s/%s.jsonl","cwd":"%s","permission_mode":"default","hook_event_name":"PostToolUse","tool_name":"%s","tool_input":%s,"tool_response":%s}' \
    "$1" "$DC9/tr" "$1" "$DC9C" "$2" "$3" "$DC9R" > "$DC9/pt.json"
  ( _fx_cd "$DC9C" && env -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CONFIG_DIR HOME="$DC9/user" FELIX_HOME="$DC9H" FELIX_MEMORY="$DC9M" \
      TMPDIR="$DC9/tmp" PATH="$DC9/farm" "$FROOT/harness/hooks/post-tool" < "$DC9/pt.json" > "$DC9/pt.out" 2>&1; printf '%s' "$?" > "$DC9/pt.rc" )
}
_dc9_bash() { _dc9_pt "$1" Bash "{\"command\":\"$(_dc9_js "$2")\",\"description\":\"Run it\"}"; }   # SESSION COMMAND
_dc9_nf() { printf '%s/state/ledger/%s.names' "${2:-$DC9H}" "$1"; }   # SESSION [HOME] -> where its names file stands
_dc9_led() { if [ -f "$DC9H/state/ledger/$1.tsv" ]; then cat "$DC9H/state/ledger/$1.tsv"; else printf 'none'; fi; }   # SESSION -> its appends
_dc9_raw() { if [ -f "$1" ]; then cat "$1"; printf '|'; else printf 'none'; fi; }   # FILE -> its bytes, then |, or none
_dc9_st() { printf '%s\t%s\t-\tlow\talways\n' "$1" "$2"; }   # KIND NAME -> a stack.tsv row
_dc9_seq() { awk -v p="$1" -v a="$2" -v b="$3" 'BEGIN { for (i = a; i <= b; i++) printf "%s%s%02d", (i > a ? " " : ""), p, i }'; }   # PREFIX FROM TO -> p01 p02 ...
DC9N64="n$(_dc9_rep 6 62)x"; DC9N65="n$(_dc9_rep 6 63)x"; DC9AB="alive${DC9T}post-tool${DC9NL}"
DC9U8="$(locale -a 2>/dev/null | awk '{ l = tolower($0) } l == "en_us.utf-8" || l == "en_us.utf8" { e = $0 } l ~ /utf-?8$/ && a == "" { a = $0 } END { print (e != "" ? e : a) }')"
is "cli-reach amendment fixture: the farm holds git and bash and not strix-agent (fixture control)" \
   "$([ -L "$DC9/farm/git" ] && [ -L "$DC9/farm/bash" ] && [ ! -e "$DC9/farm/strix-agent" ] && echo farm)" "farm"

printf '\nN7: a cli row of stack.tsv gives its second field as a name\n'
rm -f "$DC9P/routes.tsv"
{ printf '# kind\tname\tsource\trisk\twhen\n'; printf '\n'
  _dc9_st cli strix-agent; _dc9_st plugin plugin-tool@claude-plugins-official; _dc9_st plugin plugin-bare; _dc9_st skill skill-tool
  _dc9_st mcp mcp-tool; _dc9_st marketplace market-tool; _dc9_st hook hook-tool; _dc9_st frob frob-tool
  _dc9_st cli-extra extra-tool; _dc9_st xcli xcli-tool; _dc9_st CLI upper-tool; _dc9_st Cli mixed-tool; _dc9_st ' cli' blank-kind-tool
  _dc9_st 'cli ' trail-kind-tool; _dc9_st '#cli' commented-tool; printf '\tempty-kind-tool\t-\tlow\talways\n'
  printf 'cli\t\tshifted-tool\tlow\talways\n'
  _dc9_st cli strix-agent@x; _dc9_st cli a/b; _dc9_st cli -; _dc9_st cli .hidden; _dc9_st cli _under; _dc9_st cli +plus
  _dc9_st cli "caf$(printf '\303\251')"; _dc9_st cli "$DC9N65"; _dc9_st cli 'spaced-tool more-tool'
  _dc9_st cli 9lives; _dc9_st cli x.y_z+1; _dc9_st cli c++; _dc9_st cli "$DC9N64"; _dc9_st cli strix-agent
  printf 'cli\ttwo-field\n'; printf 'cli\tlastrow-cli\t-\tlow\talways'; } > "$DC9P/stack.tsv"
DC9LC="$DC9U8"; _dc9_ss n7; DC9LC=""; DC9L="$(cat "$(_dc9_nf n7)" 2>/dev/null)"
_dc9_in() { local w o=""; for w in "$@"; do case " $DC9L " in *" $w "*) o="$o $w" ;; esac; done; printf '%s' "${o# }"; }   # WORD... -> those on the names line
is "cli-reach amendment N7: a project with a stack.tsv and no routes.tsv gets a names file, and session start exits 0" \
   "$(cat "$DC9/ss.rc")|$([ -f "$(_dc9_nf n7)" ] && echo file || echo none)" "0|file"
is "cli-reach amendment N7: a cli row's second field is a name: strix-agent" "$(_dc9_in strix-agent)" "strix-agent"
is "cli-reach amendment N7: no plugin, skill, mcp, marketplace, hook or unknown-kind row gives a name, bare or qualified" \
   "$(_dc9_in plugin-tool@claude-plugins-official plugin-bare skill-tool mcp-tool market-tool hook-tool frob-tool)" ""
is "cli-reach amendment N7: a kind that only starts or ends with cli gives none: cli-extra, xcli" "$(_dc9_in extra-tool xcli-tool)" ""
is "cli-reach amendment N7: the kind is compared byte for byte and case-sensitively: CLI, Cli, ' cli' and 'cli ' give none" \
   "$(_dc9_in upper-tool mixed-tool blank-kind-tool trail-kind-tool)" ""
is "cli-reach amendment N7: a row whose first field starts with # or is empty gives none" "$(_dc9_in commented-tool empty-kind-tool)" ""
is "cli-reach amendment N7: a cli row with an empty second field is skipped, its third field never taken in its place" "$(_dc9_in shifted-tool -)" ""
is "cli-reach amendment N7: the field is taken whole, nothing stripped: strix-agent@x, a/b, - and a field holding a blank give none" \
   "$(_dc9_in strix-agent@x a/b - spaced-tool more-tool 'spaced-tool more-tool')" ""
is "cli-reach amendment N7: N2's byte rule binds: none starting with . _ or +, none of a byte outside the set, none of 65 bytes" \
   "$(_dc9_in .hidden _under +plus "caf$(printf '\303\251')" "$DC9N65")" ""
is "cli-reach amendment N7: names of letters, digits and . _ + -, one leading with a digit, one of 64 bytes, a two-field row's, the last row's with no newline" \
   "$(_dc9_in 9lives x.y_z+1 c++ "$DC9N64" two-field lastrow-cli)" "9lives x.y_z+1 c++ $DC9N64 two-field lastrow-cli"
is "cli-reach amendment N7 N8: the file is one line in row order, each name once, single spaces, read in a UTF-8 locale" \
   "$(_dc9_raw "$(_dc9_nf n7)")" "strix-agent 9lives x.y_z+1 c++ $DC9N64 two-field lastrow-cli$DC9NL|"

printf '\nN8: routes first, then declarations, each name once, one cap of 32\n'
printf 'alpha\tgraph structure\tcore\tgraphify semgrep\n' > "$DC9P/routes.tsv"
{ _dc9_st cli strix-agent; _dc9_st plugin semgrep@claude-plugins-official; _dc9_st cli semgrep; _dc9_st cli graphify
  _dc9_st cli zeta-cli; _dc9_st cli strix-agent; } > "$DC9P/stack.tsv"
_dc9_ss n8a
is "cli-reach amendment N8: the routes.tsv names come first, then the stack.tsv names in row order" "$(_dc9_raw "$(_dc9_nf n8a)")" "graphify semgrep strix-agent zeta-cli$DC9NL|"
printf 'alpha\tgraph structure\tcore\tgraphify\nbeta\tbackend\tcore\tsemgrep strix-agent\n' > "$DC9P/routes.tsv"
{ _dc9_st cli zeta-cli; _dc9_st cli strix-agent; _dc9_st cli graphify; } > "$DC9P/stack.tsv"; _dc9_ss n8b
is "cli-reach amendment N8: a name both files give stands where routes.tsv put it, and once" "$(_dc9_raw "$(_dc9_nf n8b)")" "graphify semgrep strix-agent zeta-cli$DC9NL|"
printf 'many\tmany names\tcore\t%s\n' "$(_dc9_seq t 1 32)" > "$DC9P/routes.tsv"
{ _dc9_st cli s01; _dc9_st cli s02; _dc9_st cli s03; } > "$DC9P/stack.tsv"; _dc9_ss n8cap
is "cli-reach amendment N8: a project whose routes give 32 names gets no declared CLI" "$(_dc9_raw "$(_dc9_nf n8cap)")" "$(_dc9_seq t 1 32)$DC9NL|"
printf 'many\tmany names\tcore\t%s\n' "$(_dc9_seq t 1 31)" > "$DC9P/routes.tsv"; _dc9_ss n8c31
is "cli-reach amendment N8: with 31 route names the first declared CLI is the 32nd name and the next is not written" \
   "$(_dc9_raw "$(_dc9_nf n8c31)")" "$(_dc9_seq t 1 31) s01$DC9NL|"
printf 'many\tmany names\tcore\t%s\n' "$(_dc9_seq t 1 30)" > "$DC9P/routes.tsv"
{ _dc9_st cli t05; _dc9_st cli s01; _dc9_st cli t30; _dc9_st cli s02; _dc9_st cli s03; } > "$DC9P/stack.tsv"; _dc9_ss n8dup
is "cli-reach amendment N8: a declaration repeating a route name takes no place under the cap" "$(_dc9_raw "$(_dc9_nf n8dup)")" "$(_dc9_seq t 1 30) s01 s02$DC9NL|"
rm -f "$DC9P/routes.tsv"
awk 'BEGIN { for (i = 1; i <= 40; i++) printf "cli\tc%02d\t-\tlow\talways\n", i }' > "$DC9P/stack.tsv"; _dc9_ss n8s40
is "cli-reach amendment N8: with no routes.tsv the cap binds the declarations alone: the first 32 cli rows" "$(_dc9_raw "$(_dc9_nf n8s40)")" "$(_dc9_seq c 1 32)$DC9NL|"
{ _dc9_st plugin semgrep@claude-plugins-official; _dc9_st skill graphify; _dc9_st mcp zorbtool; } > "$DC9P/stack.tsv"; _dc9_ss n8plug
is "cli-reach amendment N8: a stack.tsv of no cli row, and no routes.tsv, gives one empty line" "$(_dc9_raw "$(_dc9_nf n8plug)")" "$DC9NL|"
printf 'alpha\tkw\tcore\tsuperpowers:brainstorming - semgrep@claude-plugins-official\n' > "$DC9P/routes.tsv"
{ _dc9_st cli strix-agent@x; _dc9_st cli a/b; _dc9_st CLI strix-agent; } > "$DC9P/stack.tsv"; _dc9_ss n8nonames
is "cli-reach amendment N8: neither kind of name in either file gives one empty line" "$(_dc9_raw "$(_dc9_nf n8nonames)")" "$DC9NL|"
rm -f "$DC9P/routes.tsv" "$DC9P/stack.tsv"; _dc9_ss n8neither
is "cli-reach amendment N8: neither file gives one empty line" "$(_dc9_raw "$(_dc9_nf n8neither)")" "$DC9NL|"
_dc9_st cli strix-agent > "$DC9P/stack.tsv"; _dc9_ss n8rep; _dc9_st cli zeta-cli > "$DC9P/stack.tsv"; _dc9_ss n8rep
is "cli-reach amendment N8 N4: a second start of the session replaces the file with the declarations as they now stand" "$(_dc9_raw "$(_dc9_nf n8rep)")" "zeta-cli$DC9NL|"
DC9B4="$(find "$DC9" -name '*.names' 2>/dev/null | LC_ALL=C sort)"
for _dc9_i in 'n8.dot' 'n8 space' ''; do
  _dc9_ssp "{\"session_id\":\"$_dc9_i\",\"transcript_path\":\"$DC9/tr/n8.jsonl\",\"cwd\":\"$DC9C\",\"hook_event_name\":\"SessionStart\",\"source\":\"startup\"}" "$DC9C" "$DC9H" "$DC9M"
done
_dc9_ss n8 "$DC9/ungov"
is "cli-reach amendment N8 N5 N6: with declared names, an unusable session id and an ungoverned directory write no names file" \
   "$(LC_ALL=C comm -13 <(printf '%s\n' "$DC9B4") <(find "$DC9" -name '*.names' 2>/dev/null | LC_ALL=C sort) | awk 'NF' | awk 'END { print NR }')" "0"
mkdir -p "$(_dc9_nf n8dir)"; printf 'kept\n' > "$(_dc9_nf n8dir)/keep.txt"; _dc9_ss n8dir
is "cli-reach amendment N8 N4: a directory at the names file's path is left as it is" \
   "$([ -d "$(_dc9_nf n8dir)" ] && echo dir)|$(ls -A "$(_dc9_nf n8dir)" | tr '\n' ' ')|$(cat "$(_dc9_nf n8dir)/keep.txt" 2>/dev/null)" "dir|keep.txt |kept"

printf '\nN9: a run of a declared CLI is its reach, through post-tool and the fold\n'
rm -f "$DC9P/routes.tsv"; _dc9_st cli strix-agent > "$DC9P/stack.tsv"; _dc9_ss n9
is "cli-reach amendment N9: session start writes strix-agent as the session's name (control)" "$(_dc9_raw "$(_dc9_nf n9)")" "strix-agent$DC9NL|"
_dc9_bash n9 'strix-agent scan --target .'
is "cli-reach amendment N9: a Bash call running strix-agent is recorded cli strix-agent after its alive line, the hook exiting 0" \
   "$(cat "$DC9/pt.rc")|$(_dc9_led n9)" "0|${DC9AB}cli${DC9T}strix-agent"
_dc9_ss n9m; _dc9_bash n9m 'echo strix-agent is installed'; _dc9_bash n9m 'command -v strix-agent'; _dc9_bash n9m 'grep -n "strix-agent" notes.md'
is "cli-reach amendment N9: a call that only mentions it, as an argument, in quotes or looked up, is tool Bash" "$(cat "$DC9/pt.rc")|$(_dc9_led n9m)" \
   "0|${DC9AB}tool${DC9T}Bash${DC9NL}${DC9AB}tool${DC9T}Bash${DC9NL}${DC9AB}tool${DC9T}Bash"
_dc9_ss n9p; _dc9_bash n9p '/opt/x/bin/strix-agent --version'; _dc9_bash n9p 'cd sub && strix-agent scan'
is "cli-reach amendment N9: a run by a path or after && is cli strix-agent" "$(_dc9_led n9p)" "${DC9AB}cli${DC9T}strix-agent${DC9NL}${DC9AB}cli${DC9T}strix-agent"
printf 'alpha\tgraph structure\tcore\tgraphify\n' > "$DC9P/routes.tsv"; _dc9_ss n9two
_dc9_bash n9two 'strix-agent scan . && graphify query x'; _dc9_bash n9two 'echo graphify; graphify query x'
is "cli-reach amendment N9: beside a route name a declared CLI read first is the one recorded, and a route name still records" \
   "$(_dc9_led n9two)" "${DC9AB}cli${DC9T}strix-agent${DC9NL}${DC9AB}cli${DC9T}graphify"
rm -f "$DC9P/routes.tsv"; _dc9_st plugin strix-agent > "$DC9P/stack.tsv"; _dc9_ss n9plug; _dc9_bash n9plug 'strix-agent scan .'
is "cli-reach amendment N9: a plugin row of the same name is no name: its run stays tool Bash" "$(_dc9_raw "$(_dc9_nf n9plug)")|$(_dc9_led n9plug)" "$DC9NL||${DC9AB}tool${DC9T}Bash"
_dc9_st CLI strix-agent > "$DC9P/stack.tsv"; _dc9_ss n9up; _dc9_bash n9up 'strix-agent scan .'
is "cli-reach amendment N9: nor is a CLI row: its run stays tool Bash" "$(_dc9_led n9up)" "${DC9AB}tool${DC9T}Bash"
DC9FH="$DC9/fh"; mkdir -p "$DC9FH/projects/zorb" "$DC9FH/state/ledger"; cp "$DC9P/project.json" "$DC9P/CLAUDE.md" "$DC9FH/projects/zorb/"
{ _dc9_st cli strix-agent; _dc9_st plugin quokka@x; } > "$DC9FH/projects/zorb/stack.tsv"
_dc9_lib() { ( FELIX_MEMORY="$1"; HOME="$DC9/user"; export FELIX_MEMORY HOME; shift; . "$FROOT/harness/lib/ledger.sh"; "$@" ) 2>/dev/null; }   # MEMORY FUNCTION ARGS...
printf 'alive\tpost-tool\ncli\tstrix-agent\nalive\tpost-tool\ncli\tstrix-agent\nnamed\tstrix-agent\n' > "$DC9FH/state/ledger/f9a.tsv"
printf 'alive\tpost-tool\ntool\tBash\n' > "$DC9FH/state/ledger/f9b.tsv"
_dc9_lib "$DC9/fm" felix_ledger_rollup "$DC9FH/projects/zorb" "$DC9FH" f9a 2026-11-06
_dc9_lib "$DC9/fm" felix_ledger_rollup "$DC9FH/projects/zorb" "$DC9FH" f9b 2026-11-06
_dc9_rows() { LC_ALL=C awk -F'\t' -v n="$2" '$4 == n' "$DC9/fm/zorb/ledger.d/$1.tsv" 2>/dev/null | LC_ALL=C sort; }   # SESSION NAME -> its folded rows for NAME
is "cli-reach amendment N9: the fold writes the reach row of strix-agent, its cli lines and its namings, and no zero row for its declaration" \
   "$(_dc9_rows f9a strix-agent)" "f9a${DC9T}2026-11-06${DC9T}cli${DC9T}strix-agent${DC9T}2${DC9T}1"
is "cli-reach amendment N9: in a session that never ran it the declaration's zero row is written as before" \
   "$(_dc9_rows f9b strix-agent | LC_ALL=C awk -F'\t' '$5 == "0" { z++ } $5 != "0" { o++ } END { print (z + 0) " zero, " (o + 0) " other" }')" "1 zero, 0 other"
is "cli-reach amendment N9: and quokka@x's zero row stands in both, the fold otherwise unchanged (control)" \
   "$(_dc9_rows f9a quokka@x | awk -F'\t' '{ print $5 }')|$(_dc9_rows f9b quokka@x | awk -F'\t' '{ print $5 }')" "0|0"
