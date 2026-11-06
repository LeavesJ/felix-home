printf '\na Bash command that runs a routed tool is its reach: the names file, the record, the fold and the cost\n'
# Blind, written 2026-10-31 from docs/2026-10-31-cli-reach-spec.md alone, as amended at 7a9e3027: N1-N6 through
# hooks/session-start, P1-P6 through hooks/post-tool, F1-F6 through felix_ledger_rollup, felix_ledger_summary,
# felix_ledger_mcp, _felix_ledger_whole and `felix ledger`, and C1-C4. The hooks, lib/ledger.sh and the new
# lib/ledger-runs.sh are black boxes; parts 0002, 0004, 0320, 1800 and 2130 were read for idioms, and origin/main only
# for how the hooks are fed and the names of the functions. Why: the post-tool hook must not resolve the project (it
# runs git), so session start writes the names a session can reach and post-tool reads them with builtins (D2, C1).
# Fixture: home cr8/home with project zorb (remote_match acme/zorb-repo), the checkout co bound by its origin, and
# ungov, which nothing governs. Every hook runs on a PATH of links that log each program's name to progs.log and then
# run it; claude, gh, felix, graphify, semgrep and the made-up names are not on it, so nothing starts in the
# background. Only fixture homes this part makes are touched; the widget fixture is not.
CR8="$TMP/clireach-record"; mkdir -p "$CR8/user" "$CR8/tmp" "$CR8/co" "$CR8/ungov" "$CR8/farm" "$CR8/real" "$CR8/home/projects/zorb" "$CR8/mem/zorb"
CR8="$(cd "$CR8" && pwd -P)"; CR8H="$CR8/home"; CR8M="$CR8/mem"; CR8P="$CR8H/projects/zorb"; CR8C="$CR8/co"; CR8T="$(printf '\t')"; CR8NL=$'\n'
printf '{"name": "zorb", "remote_match": "acme/zorb-repo", "gate": "true"}\n' > "$CR8P/project.json"; printf '# zorb\n' > "$CR8P/CLAUDE.md"
( _fx_cd "$CR8C" && git init -q -b main && git remote add origin https://github.com/acme/zorb-repo \
  && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -q --allow-empty -m c1 ) >/dev/null 2>&1
( _fx_cd "$CR8/ungov" && git init -q -b main ) >/dev/null 2>&1
mkdir -p "$CR8C/lib"; printf 'echo one\n' > "$CR8C/lib/one.sh"
printf '#!/bin/sh\nprintf "%%s\\n" "${0##*/}" >> "%s/progs.log"\nexec "%s/${0##*/}" "$@"\n' "$CR8" "$CR8/real" > "$CR8/disp"; chmod +x "$CR8/disp"
perl -e 'my ($at, $real, $disp, $path, @no) = @ARGV; my %no = map { $_ => 1 } @no; my %seen;
  for my $d (split /:/, $path) { opendir(my $h, $d) or next;
    for my $n (readdir $h) { next if $n =~ /^\./ || $no{$n} || $seen{$n}; my $f = "$d/$n"; next unless -f $f && -x _;
      $seen{$n} = 1; symlink($f, "$real/$n") && symlink($disp, "$at/$n") } }' \
  "$CR8/farm" "$CR8/real" "$CR8/disp" "$PATH" claude gh felix graphify semgrep zorbtool code-review sentry-cli
cat > "$CR8/bound.pl" <<'CR8B'
my $s = shift @ARGV; my $p = fork; defined $p or exit 125;
if (!$p) { setpgrp(0, 0); exec { $ARGV[0] } @ARGV; exit 127 }
setpgrp($p, $p); my $held = 0; $SIG{ALRM} = sub { $held = 1; kill 'KILL', -$p };
alarm $s; 1 while waitpid($p, 0) == -1 && $!{EINTR}; my $st = $?; alarm 0;
if ($held) { kill 'KILL', -$p; exit 124 }
exit(($st & 127) ? 128 + ($st & 127) : $st >> 8);
CR8B
cat > "$CR8/drain.pl" <<'CR8D'
alarm 30; my ($fifo, $out, $stop) = @ARGV; open(my $o, ">>", $out) or exit 1; select((select($o), $| = 1)[0]);
until (-e $stop) { open(my $f, "<", $fifo) or last; while (my $l = <$f>) { print $o $l } close $f }
CR8D
_cr8_rep() { CR8S="$1" awk -v n="$2" 'BEGIN { s = ENVIRON["CR8S"]; for (i = 0; i < n; i++) printf "%s", s }'; }   # TEXT N -> TEXT N times
_cr8_js() {   # TEXT -> TEXT as the body of a JSON string: backslash, double quote, line break as \n, tab as \t
  local s="$1"
  s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; s="${s//$'\n'/\\n}"; s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}
CR8LC=""   # a locale for the next session start, when set
_cr8_ssp() {  # PAYLOAD DIR HOME MEMORY -> session-start there, fed PAYLOAD; its output, stderr and status in $CR8/ss.out, ss.err, ss.rc
  ( _fx_cd "$2" && env -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CONFIG_DIR -u CLAUDE_PLUGIN_ROOT -u CLAUDE_PROJECT_DIR -u FELIX_HOME_DIR \
      -u COPILOT_CLI -u CURSOR_PLUGIN_ROOT -u GIT_DIR -u GIT_WORK_TREE ${CR8LC:+LC_ALL=$CR8LC LANG=$CR8LC} \
      HOME="$CR8/user" FELIX_HOME="$3" FELIX_MEMORY="$4" TMPDIR="$CR8/tmp" PATH="$CR8/farm" \
      "$FROOT/harness/hooks/session-start" <<<"$1" > "$CR8/ss.out" 2> "$CR8/ss.err"; printf '%s' "$?" > "$CR8/ss.rc" )
}
_cr8_ss() {   # SESSION [SOURCE] [DIR] [HOME] [MEMORY] -> session-start for a payload shaped as Claude Code's SessionStart
  _cr8_ssp "{\"session_id\":\"$1\",\"transcript_path\":\"$CR8/tr/$1.jsonl\",\"cwd\":\"${3:-$CR8C}\",\"hook_event_name\":\"SessionStart\",\"source\":\"${2:-startup}\"}" \
    "${3:-$CR8C}" "${4:-$CR8H}" "${5:-$CR8M}"
}
CR8R='{"stdout":"done","stderr":"","interrupted":false,"isImage":false}'
_cr8_pt() {   # SESSION TOOL INPUT [HARNESS] [RESPONSE] -> post-tool in the checkout, fed that call; status in $CR8/pt.rc, output in pt.out
  printf '{"session_id":"%s","transcript_path":"%s/%s.jsonl","cwd":"%s","permission_mode":"default","hook_event_name":"PostToolUse","tool_name":"%s","tool_input":%s,"tool_response":%s}' \
    "$1" "$CR8/tr" "$1" "$CR8C" "$2" "$3" "${5:-$CR8R}" > "$CR8/pt.json"
  ( _fx_cd "$CR8C" && env -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CONFIG_DIR HOME="$CR8/user" FELIX_HOME="$CR8H" FELIX_MEMORY="$CR8M" \
      TMPDIR="$CR8/tmp" PATH="$CR8/farm" "${4:-$FROOT/harness}/hooks/post-tool" < "$CR8/pt.json" > "$CR8/pt.out" 2>&1; printf '%s' "$?" > "$CR8/pt.rc" )
}
_cr8_ptb() {  # SECONDS SESSION TOOL INPUT -> as _cr8_pt, its process group killed after SECONDS, status 124 then
  printf '{"session_id":"%s","transcript_path":"%s/%s.jsonl","cwd":"%s","permission_mode":"default","hook_event_name":"PostToolUse","tool_name":"%s","tool_input":%s,"tool_response":%s}' \
    "$2" "$CR8/tr" "$2" "$CR8C" "$3" "$4" "$CR8R" > "$CR8/pt.json"
  ( _fx_cd "$CR8C" && perl "$CR8/bound.pl" "$1" env -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CONFIG_DIR HOME="$CR8/user" FELIX_HOME="$CR8H" \
      FELIX_MEMORY="$CR8M" TMPDIR="$CR8/tmp" PATH="$CR8/farm" "$FROOT/harness/hooks/post-tool" < "$CR8/pt.json" > "$CR8/pt.out" 2>&1
    printf '%s' "$?" > "$CR8/pt.rc" )
}
_cr8_bash() { _cr8_pt "$1" Bash "{\"command\":\"$(_cr8_js "$2")\",\"description\":\"Run it\"}" "${3:-}"; }   # SESSION COMMAND [HARNESS]
_cr8_nf() { printf '%s/state/ledger/%s.names' "$CR8H" "$1"; }   # SESSION -> where its names file stands
_cr8_led() { if [ -f "$CR8H/state/ledger/$1.tsv" ]; then cat "$CR8H/state/ledger/$1.tsv"; else printf 'none'; fi; }   # SESSION -> its appends
_cr8_raw() { if [ -f "$1" ]; then cat "$1"; printf '|'; else printf 'none'; fi; }   # FILE -> its bytes, then |, or none
_cr8_nl() { if [ -f "$1" ]; then awk 'END { print NR }' "$1"; else printf '0'; fi; }
_cr8_calls() { _cr8_led "$1" | awk -F'\t' '$1 != "alive"'; }   # SESSION -> its call lines
CR8N64="n$(_cr8_rep 6 62)x"; CR8N65="n$(_cr8_rep 6 63)x"; CR8AB="alive${CR8T}post-tool${CR8NL}"
CR8U8="$(locale -a 2>/dev/null | awk '{ l = tolower($0) } l == "en_us.utf-8" || l == "en_us.utf8" { e = $0 } l ~ /utf-?8$/ && a == "" { a = $0 } END { print (e != "" ? e : a) }')"
is "cli-reach fixture: the farm holds git and bash and not graphify, and a run logs what it starts (fixture control)" \
   "$([ -L "$CR8/farm/git" ] && [ -L "$CR8/farm/bash" ] && [ ! -e "$CR8/farm/graphify" ] && echo farm)|$(: > "$CR8/progs.log"; PATH="$CR8/farm" sed -n 1p /dev/null; cat "$CR8/progs.log")" "farm|sed"

printf '\nN1-N6: session start writes the names a session can reach from the shell\n'
printf 'alpha\tgraph structure\tcore\tgraphify semgrep\n' > "$CR8P/routes.tsv"; CR8GS="graphify semgrep${CR8NL}|"
is "cli-reach N1: the fixture home has no state/ledger before its first session start (fixture control)" "$([ -e "$CR8H/state/ledger" ] && echo there || echo absent)" "absent"
_cr8_ss n1-startup
is "cli-reach N1: a startup in a governed checkout writes state/ledger/<session>.names, making the directory, and exits 0" "$(cat "$CR8/ss.rc")|$(_cr8_raw "$(_cr8_nf n1-startup)")" "0|$CR8GS"
_cr8_ss n1-resume resume
is "cli-reach N1: a resume writes it before it leaves, and still prints nothing" "$(cat "$CR8/ss.rc")|$(cat "$CR8/ss.out")|$(_cr8_raw "$(_cr8_nf n1-resume)")" "0||$CR8GS"
_cr8_ss n1-clear clear
is "cli-reach N1: a clear writes it" "$(_cr8_raw "$(_cr8_nf n1-clear)")" "$CR8GS"
_cr8_ss n1-compact compact
is "cli-reach N1: a compact writes it" "$(_cr8_raw "$(_cr8_nf n1-compact)")" "$CR8GS"
_cr8_ssp "{\"session_id\":\"n1-first\",\"transcript_path\":\"$CR8/tr/n1.jsonl\",\"cwd\":\"$CR8C\",\"hook_event_name\":\"SessionStart\",\"source\":\"startup\",\"agent\":{\"session_id\":\"n1-second\"}}" "$CR8C" "$CR8H" "$CR8M"
is "cli-reach N1: the file is named for the payload's first session_id, not a later one" "$(_cr8_raw "$(_cr8_nf n1-first)")|$(_cr8_raw "$(_cr8_nf n1-second)")" "$CR8GS|none"
mkdir -p "$CR8H/state"; mv "$CR8H/state/ledger" "$CR8H/state/ledger.keep" 2>/dev/null; : > "$CR8H/state/ledger"
_cr8_ss n1-wa; CR8W1="$(cat "$CR8/ss.rc")|$(cat "$CR8/ss.out")|$(cat "$CR8/ss.err")"
rm -f "$CR8H/state/ledger"; mv "$CR8H/state/ledger.keep" "$CR8H/state/ledger" 2>/dev/null
_cr8_ss n1-wb; CR8W2="$(cat "$CR8/ss.rc")|$(cat "$CR8/ss.out")|$(cat "$CR8/ss.err")"
is "cli-reach N1: a names file that cannot be written, state/ledger being a file, changes nothing the hook prints or its status" "$CR8W1" "$CR8W2"
is "cli-reach N1: and the start after it, the directory back, writes its file" "$(_cr8_raw "$(_cr8_nf n1-wb)")|$(_cr8_raw "$(_cr8_nf n1-wa)")" "$CR8GS|none"
{ printf '# name\tkeywords\tprofile\tplay commented-out\n\n'
  printf 'alpha\tgraph structure\tcore\tgraphify superpowers:brainstorming semgrep@claude-plugins-official code-review\n'
  printf 'beta\tbackend\tbackend\t-\n'; printf 'gamma\tthird field empty\t\tskipped-tool\n'
  printf 'delta\tmixed\tcore\tsentry-cli a/b - .hidden _under +plus 9lives  x.y_z+1 graphify c++ caf\303\251\n'
  printf '#epsilon\tcommented\tcore\tcommented-tool\n'; printf 'zeta\tsizes\tcore\tsemgrep %s %s\n' "$CR8N64" "$CR8N65"
  printf 'eta\tlast row\tcore\tlastrow-tool code-review'; } > "$CR8P/routes.tsv"
CR8LC="$CR8U8"; _cr8_ss n2; CR8LC=""; CR8L="$(cat "$(_cr8_nf n2)" 2>/dev/null)"
_cr8_in() { local w o=""; for w in "$@"; do case " $CR8L " in *" $w "*) o="$o $w" ;; esac; done; printf '%s' "${o# }"; }   # WORD... -> those on the names line
is "cli-reach N2: a row the router does not read names nothing: a comment row, the header, a row whose third field is empty" "$(_cr8_in commented-out commented-tool skipped-tool)" ""
is "cli-reach N2: no entry with : or @, no -, no slash, none starting . _ or +, none of a byte outside the set, none of 65 bytes, is a name" \
   "$(_cr8_in superpowers:brainstorming semgrep@claude-plugins-official - a/b .hidden _under +plus "caf$(printf '\303\251')" "$CR8N65")" ""
is "cli-reach N2: names of letters, digits and . _ + -, one leading with a digit and one of 64 bytes, and the last row's with no newline" \
   "$(_cr8_in graphify code-review sentry-cli 9lives x.y_z+1 c++ semgrep "$CR8N64" lastrow-tool)" "graphify code-review sentry-cli 9lives x.y_z+1 c++ semgrep $CR8N64 lastrow-tool"
is "cli-reach N3: one line ending in a newline, each name once, in the order it first appears, single spaces, read in a UTF-8 locale" \
   "$(_cr8_raw "$(_cr8_nf n2)")" "graphify code-review sentry-cli 9lives x.y_z+1 c++ semgrep $CR8N64 lastrow-tool$CR8NL|"
{ printf 'many\tmany names\tcore\t%s\n' "$(awk 'BEGIN { for (i = 1; i <= 20; i++) printf "%st%02d", (i > 1 ? " " : ""), i }')"
  printf 'more\tmore names\tcore\tt05 %s t01\n' "$(awk 'BEGIN { for (i = 21; i <= 40; i++) printf "%st%02d", (i > 21 ? " " : ""), i }')"; } > "$CR8P/routes.tsv"
_cr8_ss n3cap
is "cli-reach N3: at most the first 32 distinct names, a repeat taking no place" "$(_cr8_raw "$(_cr8_nf n3cap)")" \
   "$(awk 'BEGIN { for (i = 1; i <= 32; i++) printf "%st%02d", (i > 1 ? " " : ""), i }')$CR8NL|"
printf 'alpha\tkw\tcore\tsuperpowers:brainstorming - semgrep@claude-plugins-official\n' > "$CR8P/routes.tsv"; _cr8_ss n3none
is "cli-reach N3: when no entry qualifies the file holds one empty line" "$(_cr8_raw "$(_cr8_nf n3none)")" "$CR8NL|"
rm -f "$CR8P/routes.tsv"; _cr8_ss n3gone; _cr8_ss n2
is "cli-reach N3: as it does when the project has no routes.tsv" "$(_cr8_raw "$(_cr8_nf n3gone)")" "$CR8NL|"
is "cli-reach N4: and a session started again with it gone has its names replaced by that line" "$(_cr8_raw "$(_cr8_nf n2)")" "$CR8NL|"
printf 'alpha\tkw\tcore\tgraphify\n' > "$CR8P/routes.tsv"; _cr8_ss n4; ln "$(_cr8_nf n4)" "$CR8/n4.twin" 2>/dev/null
printf 'alpha\tkw\tcore\tsemgrep\n' > "$CR8P/routes.tsv"; _cr8_ss n4
is "cli-reach N4: a second start of the same session replaces the file, never appending to it" "$(_cr8_raw "$(_cr8_nf n4)")" "semgrep$CR8NL|"
is "cli-reach N4: renamed into place: a hard link to the file before keeps the old line" "$(_cr8_raw "$CR8/n4.twin")" "graphify$CR8NL|"
printf 'untouched\n' > "$CR8/n4.target"; rm -f "$(_cr8_nf n4)"; ln -s "$CR8/n4.target" "$(_cr8_nf n4)" 2>/dev/null; _cr8_ss n4
is "cli-reach N4: and a link standing at the path is replaced, never written through" \
   "$(_cr8_raw "$CR8/n4.target")|$([ -L "$(_cr8_nf n4)" ] && echo link || echo file)|$(_cr8_raw "$(_cr8_nf n4)")" "untouched$CR8NL||file|semgrep$CR8NL|"
printf 'alpha\tkw\tcore\tgraphify semgrep\n' > "$CR8P/routes.tsv"
CR8B4="$(find "$CR8" -name '*.names' 2>/dev/null | LC_ALL=C sort)"
for _cr8_i in 'n5.dot' 'n5/slash' '../n5-escape' 'n5 space' 'n5\"quote' 'n5\u00e9' "n5$(printf '\303\251')" ''; do
  _cr8_ssp "{\"session_id\":\"$_cr8_i\",\"transcript_path\":\"$CR8/tr/n5.jsonl\",\"cwd\":\"$CR8C\",\"hook_event_name\":\"SessionStart\",\"source\":\"startup\"}" "$CR8C" "$CR8H" "$CR8M"
done
_cr8_ssp "{\"transcript_path\":\"$CR8/tr/n5.jsonl\",\"cwd\":\"$CR8C\",\"hook_event_name\":\"SessionStart\",\"source\":\"startup\"}" "$CR8C" "$CR8H" "$CR8M"
_cr8_ss n5-ok; CR8NEW="$(LC_ALL=C comm -13 <(printf '%s\n' "$CR8B4") <(find "$CR8" -name '*.names' 2>/dev/null | LC_ALL=C sort))"
is "cli-reach N5: a session id that is empty, missing, or holds a byte outside A-Z a-z 0-9 _ - writes no names file anywhere" \
   "$(printf '%s\n' "$CR8NEW" | awk -v ok="$(_cr8_nf n5-ok)" '$0 != "" && $0 != ok')" ""
is "cli-reach N5: while a usable one beside them does" "$CR8NEW" "$(_cr8_nf n5-ok)"
_cr8_ss n6 startup "$CR8/ungov"
is "cli-reach N6: in a directory no project governs nothing is written, and the hook prints nothing there as before" \
   "$(find "$CR8" -name 'n6.names' 2>/dev/null | awk 'END { print NR }')|$(cat "$CR8/ss.out")" "0|"
is "cli-reach N4: no temporary file is left: state/ledger holds the names file of each usable session started and nothing else" \
   "$(ls -A "$CR8H/state/ledger" 2>/dev/null | awk '!/\.tsv$/' | LC_ALL=C sort | tr '\n' ' ')" \
   "n1-clear.names n1-compact.names n1-first.names n1-resume.names n1-startup.names n1-wb.names n2.names n3cap.names n3gone.names n3none.names n4.names n5-ok.names "
# Amended in review (1af1e086, written 2026-11-05): a symbolic link to a directory, and a directory, standing at the
# names file's path. In a home of their own, so the listing above still says what it says.
CR8H4="$CR8/h4"; mkdir -p "$CR8H4/projects/zorb" "$CR8H4/state/ledger" "$CR8/m4" "$CR8/n4.dir"
cp "$CR8P/project.json" "$CR8P/CLAUDE.md" "$CR8H4/projects/zorb/"; printf 'alpha\tkw\tcore\tgraphify semgrep\n' > "$CR8H4/projects/zorb/routes.tsv"
ln -s "$CR8/n4.dir" "$CR8H4/state/ledger/n4d.names"; _cr8_ss n4d startup "$CR8C" "$CR8H4" "$CR8/m4"
is "cli-reach N4: a symbolic link to a directory at the path is replaced by the names file, never followed" \
   "$([ -L "$CR8H4/state/ledger/n4d.names" ] && echo link || echo not-link)|$(_cr8_raw "$CR8H4/state/ledger/n4d.names")" "not-link|graphify semgrep$CR8NL|"
is "cli-reach N4: and nothing is written into the directory it pointed to" "$(ls -A "$CR8/n4.dir" | tr '\n' ' ')" ""
mkdir "$CR8H4/state/ledger/n4r.names"; printf 'kept\n' > "$CR8H4/state/ledger/n4r.names/keep.txt"
_cr8_l4() { find "$CR8H4/state/ledger" | awk '!/\/state\/ledger\/[^\/]*\.tsv$/' | LC_ALL=C sort; }   # what state/ledger holds, its .tsv appends aside
CR8L4="$(_cr8_l4)"; _cr8_ss n4r startup "$CR8C" "$CR8H4" "$CR8/m4"
is "cli-reach N4: a directory at the path is left as it is" "$([ -d "$CR8H4/state/ledger/n4r.names" ] && echo dir)|$(ls -A "$CR8H4/state/ledger/n4r.names" | tr '\n' ' ')|$(cat "$CR8H4/state/ledger/n4r.names/keep.txt" 2>/dev/null)" "dir|keep.txt |kept"
is "cli-reach N4: and the session gets no names file and leaves no temporary file: state/ledger holds what it held" "$(_cr8_l4)" "$CR8L4"

printf '\nP1-P6: the post-tool hook records a reach as cli <name>\n'
mkdir -p "$CR8H/state/ledger"; printf 'graphify semgrep\n' > "$(_cr8_nf p1)"
_cr8_bash p1 'graphify query "where is the router"'
is "cli-reach P1: a Bash call running graphify, its session's names holding it, appends cli graphify after its alive line" "$(_cr8_led p1)" "${CR8AB}cli${CR8T}graphify"
_cr8_bash p1 'ls -la'; _cr8_bash p1 'semgrep scan --config auto .'
is "cli-reach P1: one call line per run beside its alive line, a run of no name being tool Bash" "$(_cr8_led p1)" \
   "${CR8AB}cli${CR8T}graphify${CR8NL}${CR8AB}tool${CR8T}Bash${CR8NL}${CR8AB}cli${CR8T}semgrep"
is "cli-reach P1: and the run exits 0 and prints nothing" "$(cat "$CR8/pt.rc")|$(cat "$CR8/pt.out")" "0|"
printf 'graphify semgrep\n' > "$(_cr8_nf p4)"; _cr8_bash p4 'semgrep scan . && graphify query x'
is "cli-reach P4: a command that runs two names records the first in reading order" "$(_cr8_led p4)" "${CR8AB}cli${CR8T}semgrep"
printf 'graphify\n' > "$(_cr8_nf p2)"
_cr8_bash p2 'graphify query x --token=sk-cr8-FAKE-7f3a9c --out /home/u/cr8-private-path'
_cr8_bash p2 'curl -H "Authorization: Bearer sk-cr8-FAKE-7f3a9c" https://example.invalid/cr8-private-path'
is "cli-reach P2: a command holding a credential leaves only cli graphify, and one that runs no name only tool Bash" "$(_cr8_led p2)" \
   "${CR8AB}cli${CR8T}graphify${CR8NL}${CR8AB}tool${CR8T}Bash"
is "cli-reach P2: no part of either command is written anywhere the hook writes" \
   "$(grep -rl -e sk-cr8-FAKE -e cr8-private-path "$CR8H" "$CR8M" "$CR8/tmp" "$CR8/user" 2>/dev/null)" ""
printf 'graphify semgrep\n' > "$(_cr8_nf p3)"
_cr8_pt p3 Read '{"file_path":"/opt/x/bin/graphify"}'; _cr8_pt p3 mcp__github__create_issue '{"title":"t","command":"graphify query x"}'
_cr8_pt p3 Skill '{"skill":"superpowers:brainstorming","args":"graphify"}'
_cr8_pt p3 Agent '{"description":"d","prompt":"run graphify query x","subagent_type":"ecc:code-reviewer"}'; _cr8_bash p3 'make build'
is "cli-reach P3: Read, mcp, Skill and Agent calls and a Bash call of no name record what they did before, beside a names file" "$(_cr8_led p3)" \
   "${CR8AB}tool${CR8T}Read${CR8NL}${CR8AB}mcp${CR8T}github${CR8NL}${CR8AB}skill${CR8T}superpowers:brainstorming${CR8NL}${CR8AB}agent${CR8T}ecc:code-reviewer${CR8NL}${CR8AB}tool${CR8T}Bash"
_cr8_bash p3x 'graphify query x'; printf '\n' > "$(_cr8_nf p3e)"; _cr8_bash p3e 'graphify query x'
is "cli-reach P3: a session with no names file records tool Bash for a run of graphify" "$(_cr8_led p3x)" "${CR8AB}tool${CR8T}Bash"
is "cli-reach P3: as does one whose names file is one empty line" "$(_cr8_led p3e)" "${CR8AB}tool${CR8T}Bash"
printf 'graphify\n' > "$(_cr8_nf p3u)"; chmod 000 "$(_cr8_nf p3u)"
if [ -r "$(_cr8_nf p3u)" ]; then skip "cli-reach P3: and one whose names file cannot be read" "the file is still readable here"
else _cr8_bash p3u 'graphify query x'; is "cli-reach P3: and one whose names file cannot be read" "$(_cr8_led p3u)" "${CR8AB}tool${CR8T}Bash"; fi
chmod 644 "$(_cr8_nf p3u)"
mkdir -p "$CR8H/state/answer"; printf 'graphify\n' > "$(_cr8_nf p5)"
printf 'asked\tgraphify\tanswered\nroot\t%s\ngiven\tgraphify\t1\t-\nanswer\tgraphify\tlib/one.sh\n' "$CR8C" > "$CR8H/state/answer/p5.tsv"
_cr8_bash p5 'graphify query lib/one.sh'
is "cli-reach P5: a run of graphify that names an answered file is recorded cli graphify" "$(_cr8_led p5)" "${CR8AB}cli${CR8T}graphify"
is "cli-reach P5: and the answers are handed tool Bash for it: the touch row names Bash and the file" "$(awk 'NR > 4' "$CR8H/state/answer/p5.tsv")" "touch${CR8T}Bash${CR8T}lib/one.sh"
mkfifo "$(_cr8_nf p6f)"
_cr8_ptb 10 p6f Read '{"file_path":"/opt/x/bin/graphify"}'; CR8F1="$(cat "$CR8/pt.rc")"
_cr8_ptb 10 p6f mcp__github__create_issue '{"command":"graphify query x"}'; CR8F2="$(cat "$CR8/pt.rc")"; rm -f "$(_cr8_nf p6f)"
is "cli-reach P6: the names file is read only for a Bash call: with a FIFO standing at it, a Read and an mcp call end, exit 0 and record as before" \
   "$CR8F1 $CR8F2|$(_cr8_led p6f)" "0 0|${CR8AB}tool${CR8T}Read${CR8NL}${CR8AB}mcp${CR8T}github"
printf 'graphify\n' > "$CR8H/state/ledger/p6.x.names"; _cr8_bash p6.x 'graphify query x'
is "cli-reach P6: and only for a usable session id: a names file standing for the id p6.x is not read" "$(_cr8_led p6.x)" "${CR8AB}tool${CR8T}Bash"
printf 'graphify  semgrep\n' > "$(_cr8_nf p6m)"; _cr8_bash p6m 'graphify query x'
is "cli-reach P6: a names file whose line holds two blanks in a row is read as none" "$(_cr8_led p6m)" "${CR8AB}tool${CR8T}Bash"
printf 'graphify\n' > "$(_cr8_nf p6l)"; mkfifo "$CR8H/state/ledger/p6l.tsv"; : > "$CR8/p6l.got"; rm -f "$CR8/p6l.stop"
perl "$CR8/drain.pl" "$CR8H/state/ledger/p6l.tsv" "$CR8/p6l.got" "$CR8/p6l.stop" & CR8DP=$!
_cr8_ptb 10 p6l Bash '{"command":"graphify query x","description":"q"}'; CR8F3="$(cat "$CR8/pt.rc")"
: > "$CR8/p6l.stop"; _cr8_i=0
while kill -0 "$CR8DP" 2>/dev/null && [ "$_cr8_i" -lt 50 ]; do : <> "$CR8H/state/ledger/p6l.tsv"; sleep 0.1; _cr8_i=$((_cr8_i + 1)); done
kill "$CR8DP" 2>/dev/null; wait "$CR8DP" 2>/dev/null; rm -f "$CR8H/state/ledger/p6l.tsv"
is "cli-reach P6: it never reads the session's ledger file: with that file a FIFO a reader drains, the run ends and exits 0" "$CR8F3" "0"
is "cli-reach P6: and what it appended there is its alive line and cli graphify" "$(cat "$CR8/p6l.got")" "${CR8AB}cli${CR8T}graphify"
printf 'alpha\tkw\tcore\tgraphify semgrep\n' > "$CR8P/routes.tsv"; _cr8_ss e2e; _cr8_bash e2e 'cd sub && graphify query x'
is "cli-reach N1 P1: end to end, the names session start wrote are what post-tool reads: a run of graphify is cli graphify" "$(_cr8_led e2e)" "${CR8AB}cli${CR8T}graphify"

printf '\nC1-C4: no new process, no git, the library loaded only when needed, and bounded\n'
_cr8_c1() { : > "$CR8/progs.log"; _cr8_pt c1 "$1" "$2"; cat "$CR8/progs.log" >> "$CR8/c1.all"; LC_ALL=C sort "$CR8/progs.log"; }   # TOOL INPUT -> programs started
_cr8_c1p() {  # WHAT TOOL INPUT -> C1 for that call: what a run with c1's names file starts that a run without it does not
  local w o; printf 'graphify semgrep\n' > "$(_cr8_nf c1)"; w="$(_cr8_c1 "$2" "$3")"; rm -f "$(_cr8_nf c1)"; o="$(_cr8_c1 "$2" "$3")"
  is "cli-reach C1: $1 starts no program with the session's names file that it does not start without one" \
     "$(LC_ALL=C comm -23 <(printf '%s\n' "$w") <(printf '%s\n' "$o"))" ""
}
: > "$CR8/c1.all"; rm -f "$CR8H/state/ledger/c1.tsv"
_cr8_c1p "a run of graphify" Bash '{"command":"graphify query x","description":"q"}'
is "cli-reach C1: and that run with the names file recorded the reach, the one without it tool Bash" "$(_cr8_calls c1)" "cli${CR8T}graphify${CR8NL}tool${CR8T}Bash"
_cr8_c1p "a command holding graphify only as text" Bash '{"command":"echo graphify; grep -n graphify notes.md","description":"q"}'
_cr8_c1p "a command holding no name" Bash '{"command":"ls -la","description":"q"}'
_cr8_c1p "a Read" Read '{"file_path":"/opt/x/bin/graphify"}'
_cr8_c1p "a command of escapes, a here-document and a substitution" Bash '{"command":"cat <<EOF\ngraphify\nEOF\nx=$(semgrep --version)","description":"q"}'
_cr8_c1p "a command of 20 KB" Bash "{\"command\":\"graphify query $(_cr8_rep 'a b ' 5000)\",\"description\":\"q\"}"
is "cli-reach C1: every one of those twelve runs started bash, so the farm saw them (fixture control)" "$(awk '$0 == "bash" { n++ } END { print (n >= 12) ? "seen" : n + 0 }' "$CR8/c1.all")" "seen"
is "cli-reach C2: no post-tool run, with names or without, started git" "$(awk '$0 == "git"' "$CR8/c1.all" "$CR8/progs.log" | awk 'END { print NR }')" "0"
_cr8_load() { : > "$CR8/progs.log"; env -i HOME="$CR8/user" FELIX_HOME="$CR8H" FELIX_MEMORY="$CR8M" PATH="$CR8/farm" "$BASH" -c \
  'for l in "$@"; do . "$l" || exit 1; done; printf loaded' _ "$@" 2>/dev/null; printf '|%s' "$(tr '\n' ' ' < "$CR8/progs.log")"; }   # LIBRARY... -> loaded|, then what started
is "cli-reach C3: lib/ledger.sh loads in a fresh shell starting no program on PATH" "$(_cr8_load "$FROOT/harness/lib/ledger.sh")" "loaded|"
is "cli-reach C1: and lib/ledger-runs.sh loads after it starting none" "$(_cr8_load "$FROOT/harness/lib/ledger.sh" "$FROOT/harness/lib/ledger-runs.sh")" "loaded|"
for _cr8_h in h2a h2b; do mkdir -p "$CR8/$_cr8_h/projects/zorb" "$CR8/m$_cr8_h"; cp "$CR8P/project.json" "$CR8P/CLAUDE.md" "$CR8/$_cr8_h/projects/zorb/"; done
printf 'alpha\tkw\tcore\tgraphify semgrep code-review sentry-cli\n' > "$CR8/h2a/projects/zorb/routes.tsv"
printf 'alpha\tkw\tcore\tsuperpowers:brainstorming\n' > "$CR8/h2b/projects/zorb/routes.tsv"
: > "$CR8/progs.log"; _cr8_ss c2 startup "$CR8C" "$CR8/h2a" "$CR8/mh2a"; CR8G1="$(awk '$0 == "git"' "$CR8/progs.log" | awk 'END { print NR }')"
: > "$CR8/progs.log"; _cr8_ss c2 startup "$CR8C" "$CR8/h2b" "$CR8/mh2b"; CR8G2="$(awk '$0 == "git"' "$CR8/progs.log" | awk 'END { print NR }')"
is "cli-reach C2: session start runs git there, so its count is a measure (fixture control)" "$([ "${CR8G2:-0}" -gt 0 ] && echo some)" "some"
is "cli-reach C2: and it runs as many git commands writing four names as writing none" "$CR8G1" "$CR8G2"
_cr8_hcopy() { local x; mkdir -p "$1/harness" || return 1; for x in "$FROOT/harness"/*; do case "$x" in */tests) ;; *) cp -R "$x" "$1/harness/" ;; esac; done; }
_cr8_hcopy "$CR8/hs"; CR8LB="$CR8/hs/harness/lib"; : > "$CR8/runs.log"
if [ -f "$CR8LB/ledger-runs.sh" ]; then mv "$CR8LB/ledger-runs.sh" "$CR8LB/ledger-runs.orig.sh"
  printf 'printf "loaded\\n" >> "%s/runs.log"\n. "${BASH_SOURCE[0]%%/*}/ledger-runs.orig.sh"\n' "$CR8" > "$CR8LB/ledger-runs.sh"; fi
printf 'graphify semgrep\n' > "$(_cr8_nf c3)"; printf 'graphify\n' > "$CR8H/state/ledger/c3.x.names"
_cr8_bash c3 'ls -la' "$CR8/hs/harness"; CR8L1="$(_cr8_nl "$CR8/runs.log")"
_cr8_pt c3 Read '{"file_path":"/opt/x/bin/graphify"}' "$CR8/hs/harness"; CR8L2="$(_cr8_nl "$CR8/runs.log")"
_cr8_pt c3 Bash '{"command":"ls","description":"graphify query x"}' "$CR8/hs/harness" '{"stdout":"graphify","stderr":"","interrupted":false,"isImage":false}'; CR8L3="$(_cr8_nl "$CR8/runs.log")"
_cr8_bash c3 "echo $(_cr8_rep A 17000) graphify" "$CR8/hs/harness"; CR8L4="$(_cr8_nl "$CR8/runs.log")"
_cr8_bash c3n 'graphify query x' "$CR8/hs/harness"; _cr8_bash c3.x 'graphify query x' "$CR8/hs/harness"; CR8L5="$(_cr8_nl "$CR8/runs.log")"
is "cli-reach C3: lib/ledger-runs.sh is not loaded for a Bash command holding no name, a Read, a name only outside the command, one only past 16 KB of it, no names file or an unusable id" \
   "$CR8L1 $CR8L2 $CR8L3 $CR8L4 $CR8L5" "0 0 0 0 0"
_cr8_bash c3 'graphify query x' "$CR8/hs/harness"
is "cli-reach C3: and it is loaded for a command that runs a name, the spy logging it (control)" "$(awk 'END { print (NR > 0) ? "loaded" : "not loaded" }' "$CR8/runs.log")" "loaded"
_cr8_cpu() {  # PAYLOAD-FILE -> post-tool fed it, on the suite's own PATH; prints the CPU it took (times' second line, user plus system) or unread
  ( ( _fx_cd "$CR8C" && env -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CONFIG_DIR HOME="$CR8/user" FELIX_HOME="$CR8H" FELIX_MEMORY="$CR8M" TMPDIR="$CR8/tmp" \
        "$FROOT/harness/hooks/post-tool" < "$1" > /dev/null 2>&1; printf '%s' "$?" > "$CR8/pt.rc" ); times ) > "$CR8/cpu.times" 2>/dev/null
  LC_ALL=C awk 'function s(v,  m) { gsub(/,/, ".", v); m = v; sub(/m.*$/, "", m); sub(/^[0123456789]+m/, "", v); sub(/s$/, "", v); return m * 60 + v }
    NR == 2 && $1 ~ /^[0123456789]+m[0123456789.,]+s$/ && $2 ~ /^[0123456789]+m[0123456789.,]+s$/ { printf "%.3f", s($1) + s($2); f = 1 }
    END { if (!f) printf "unread" }' "$CR8/cpu.times" 2>/dev/null
}
_cr8_under() { awk -v c="$1" 'BEGIN { print (c != "unread" && c + 0 < 2) ? "under 2 s" : "took " c " s" }'; }
_cr8_c4() {   # SESSION COMMAND-AS-WRITTEN [STDOUT-FILL N] -> that Bash payload in $CR8/c4.json, the response's stdout N fills when given
  { printf '{"session_id":"%s","transcript_path":"%s/c4.jsonl","cwd":"%s","permission_mode":"default","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"%s","description":"q"},"tool_response":{"stdout":"' "$1" "$CR8/tr" "$CR8C" "$2"
    [ -z "${3:-}" ] || _cr8_rep "$3" "$4"; printf '","stderr":"","interrupted":false,"isImage":false}}'; } > "$CR8/c4.json"
}
printf 'graphify\n' > "$(_cr8_nf c4a)"; printf 'graphify\n' > "$(_cr8_nf c4b)"; printf 'graphify\n' > "$(_cr8_nf c4c)"
_cr8_mb() { wc -c < "$1" | awk '{ print ($1 >= 4194304) ? "4 MB" : $1 " bytes" }'; }   # FILE -> 4 MB when it holds 4 MiB or more
_cr8_c4 c4a 'graphify query x' 'line of output ' 280000; CR8Z="$(_cr8_mb "$CR8/c4.json")"; CR8C4="$(_cr8_cpu "$CR8/c4.json")"
is "cli-reach C4: a 4 MB Bash payload, most of it the response, is recorded in under 2 s of CPU and the hook exits 0" "$CR8Z|$(_cr8_under "$CR8C4")|$(cat "$CR8/pt.rc")" "4 MB|under 2 s|0"
is "cli-reach C4: and its one call line is cli graphify" "$(_cr8_calls c4a)" "cli${CR8T}graphify"
_cr8_c4 c4b "graphify query $(_cr8_rep 'abcdefgh ' 466100)"; CR8Z="$(_cr8_mb "$CR8/c4.json")"; CR8C4="$(_cr8_cpu "$CR8/c4.json")"
is "cli-reach C4: a 4 MB command is recorded in under 2 s of CPU, the hook exiting 0, its one call line cli graphify" \
   "$CR8Z|$(_cr8_under "$CR8C4")|$(cat "$CR8/pt.rc")|$(_cr8_calls c4b)" "4 MB|under 2 s|0|cli${CR8T}graphify"
CR8C4S=""
for _cr8_v in "$(_cr8_rep '$(' 8192)graphify" "$(_cr8_rep '<<A ' 4096)graphify" "$(_cr8_rep '"' 16384) graphify" "$(_cr8_rep 'a;' 8192)graphify" \
              "$(_cr8_rep $'$( ( { [[ (( "a" \'b\' \\c <<X # x\n' 512)graphify"; do
  _cr8_c4 c4c "$(_cr8_js "$_cr8_v")"; CR8C4="$(_cr8_cpu "$CR8/c4.json")"; CR8C4S="$CR8C4S$(_cr8_under "$CR8C4")/$(cat "$CR8/pt.rc") "
done
is "cli-reach C4: five 16 KB commands built to be hard to read are each recorded in under 2 s of CPU, the hook exiting 0" "$CR8C4S" "under 2 s/0 under 2 s/0 under 2 s/0 under 2 s/0 under 2 s/0 "
is "cli-reach C4: and each of those runs wrote one call line" "$(_cr8_calls c4c | awk 'END { print NR }')" "5"

printf '\nF1-F6: the fold and the reports count a cli line as a reach\n'
CR8FH="$CR8/fh"; mkdir -p "$CR8FH/projects/zorb" "$CR8FH/state/ledger"; cp "$CR8P/project.json" "$CR8P/CLAUDE.md" "$CR8FH/projects/zorb/"
printf 'skill\tgraphify\t-\tlow\talways\nplugin\tsemgrep@claude-plugins-official\t-\tlow\talways\nmcp\tzorbtool\t-\tlow\talways\nplugin\tquokka@x\t-\tlow\talways\n' > "$CR8FH/projects/zorb/stack.tsv"
_cr8_lib() { ( FELIX_MEMORY="$1"; HOME="$CR8/user"; export FELIX_MEMORY HOME; shift; . "$FROOT/harness/lib/ledger.sh"; "$@" ) 2>/dev/null; }   # MEMORY FUNCTION ARGS...
printf 'alive\tpost-tool\ncli\tgraphify\nalive\tpost-tool\ncli\tsemgrep\nalive\tpost-tool\ncli\tzorbtool\nalive\tpost-tool\ncli\tgraphify\nnamed\tgraphify\nnamed\tsemgrep\nnamed\tsemgrep\n' > "$CR8FH/state/ledger/f1.tsv"
_cr8_lib "$CR8/fm1" felix_ledger_rollup "$CR8FH/projects/zorb" "$CR8FH" f1 2026-10-31; CR8F="$(LC_ALL=C sort "$CR8/fm1/zorb/ledger.d/f1.tsv" 2>/dev/null)"
is "cli-reach F1: a cli line folds to a reach row: session, date, cli, the name, its cli lines, its namings" "$(printf '%s\n' "$CR8F" | awk -F'\t' '$3 == "cli"')" \
   "$(printf 'f1\t2026-10-31\tcli\tgraphify\t2\t1\nf1\t2026-10-31\tcli\tsemgrep\t1\t2\nf1\t2026-10-31\tcli\tzorbtool\t1\t0')"
is "cli-reach F2: beside a reach no named row is written for the name, nor a zero row for its declaration, skill, plugin or mcp" \
   "$(printf '%s\n' "$CR8F" | awk -F'\t' '$3 != "cli" && $4 ~ /^(graphify|semgrep|zorbtool)/')" ""
is "cli-reach F3: cli lines are calls when the fold asks if the record is whole: quokka@x's zero row reads a measured 0" "$(printf '%s\n' "$CR8F" | awk -F'\t' '$4 == "quokka@x" { print $5 }')" "0"
printf 'alive\tpost-tool\ncli\tgraphify\n' > "$CR8/w1.tsv"; printf 'alive\tpost-tool\nalive\tpost-tool\ncli\tgraphify\n' > "$CR8/w2.tsv"
is "cli-reach F3: _felix_ledger_whole reads one alive line and one cli line as whole, and two alive lines beside one as not" \
   "$(_cr8_lib "$CR8/fm1" _felix_ledger_whole "$CR8/w1.tsv"; printf '%s ' "$?"; _cr8_lib "$CR8/fm1" _felix_ledger_whole "$CR8/w2.tsv"; printf '%s' "$?")" "0 1"
CR8M4="$CR8/fm4"; mkdir -p "$CR8M4/zorb/ledger.d"; printf 'f41\t2026-10-01\tcli\tgraphify\t3\t1\n' > "$CR8M4/zorb/ledger.d/f41.tsv"
printf 'f42\t2026-10-02\tcli\tgraphify\t2\t0\nf42\t2026-10-02\tskill\tgraphify\t1\t0\n' > "$CR8M4/zorb/ledger.d/f42.tsv"
is "cli-reach F4: felix_ledger_summary counts cli rows' sessions and reaches under the name, the built-in mark on the bare skill row alone" \
   "$(_cr8_lib "$CR8M4" felix_ledger_summary "$CR8FH/projects/zorb" | awk -F'\t' 'index($1, "graphify") == 1')" \
   "graphify${CR8T}2${CR8T}5${CR8T}1${CR8NL}graphify (built-in)${CR8T}1${CR8T}1${CR8T}0"
_cr8_fl() { ( _fx_cd "$CR8C" && env -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CONFIG_DIR -u FELIX_HOME_DIR HOME="$CR8/user" FELIX_HOME="$CR8FH" FELIX_MEMORY="$1" \
                PATH="$CR8/farm" "$FROOT/harness/felix" ledger 2>&1 ); }   # MEMORY -> what felix ledger prints for zorb
is "cli-reach F4: felix ledger shows graphify in 2 sessions, named once, reached 5 times, and the skill row apart under (built-in)" \
   "$(_cr8_fl "$CR8M4" | awk '/CAPABILITY/ { t = 1; next } t && $0 == "" { exit } t && $1 == "graphify" { $1 = $1; print }')" "graphify 2 1 5${CR8NL}graphify (built-in) 1 0 1"
CR8M5="$CR8/fm5"; mkdir -p "$CR8M5/zorb/ledger.d"
for _cr8_i in 1 2 3 4 5; do printf 'r%s\t2026-10-0%s\tnamed\tgraphify\t0\t1\n' "$_cr8_i" "$_cr8_i" > "$CR8M5/zorb/ledger.d/r$_cr8_i.tsv"; done
_cr8_rl() { awk '/^pointed at and never reached for/ { b = 1; next } b && /^That is the one signal/ { b = 0 } b && NF { print $1 }'; }   # felix ledger -> its retire list
_cr8_sl() { LC_ALL=C awk '{ gsub(/\\n/, "\n"); print }' "$CR8/ss.out" | LC_ALL=C awk '/Pointed at and never once reached for:/ { b = 1; f = 1; next }
  b && /That is the only unconfounded signal/ { b = 0 } b { sub(/^ +/, ""); sub(/ .*/, ""); print } END { if (!f) print "none" }'; }   # session start -> its retire line's names
is "cli-reach F5: five sessions that named graphify and never reached it put it on felix ledger's retire list (fixture control)" "$(_cr8_fl "$CR8M5" | _cr8_rl)" "graphify"
_cr8_ss f5a startup "$CR8C" "$CR8FH" "$CR8M5"
is "cli-reach F5: and on session start's line (fixture control)" "$(_cr8_sl)" "graphify"
printf 'r6\t2026-10-06\tcli\tgraphify\t1\t1\n' > "$CR8M5/zorb/ledger.d/r6.tsv"
is "cli-reach F5: a folded cli reach takes it off felix ledger's pointed-at-and-never-reached list" "$(_cr8_fl "$CR8M5" | _cr8_rl)" ""
_cr8_ss f5b startup "$CR8C" "$CR8FH" "$CR8M5"
is "cli-reach F5: and off session start's Pointed at and never once reached for line" "$(_cr8_sl)" "none"
CR8M6="$CR8/fm6"; mkdir -p "$CR8M6/zorb/ledger.d"; printf 'm2\t2026-10-02\tcli\tgithub\t3\t0\n' > "$CR8M6/zorb/ledger.d/m2.tsv"
printf 'm1\t2026-10-01\tcli\tgithub\t4\t0\nm1\t2026-10-01\tmcp\tgithub\t1\t2\n' > "$CR8M6/zorb/ledger.d/m1.tsv"
is "cli-reach F6: felix_ledger_mcp ignores cli rows, though one carries a server's name" "$(_cr8_lib "$CR8M6" felix_ledger_mcp "$CR8FH/projects/zorb")" "github${CR8T}1${CR8T}1${CR8T}2"
