printf '\nthe session id is read from a leading window of 32,768 bytes (cli-reach amendment, W1-W5)\n'
# Blind, written 2026-11-06 from docs/2026-10-31-cli-reach-spec.md section 9 alone (W1-W5), with sections 0-8 read for
# the behaviour it builds on. felix_ledger_session_id RAW, sourced in a subshell from the fixture harness's
# lib/ledger.sh, and hooks/post-tool and hooks/session-start are black boxes; parts 2170 and 2180 were read for idioms.
# Why: the function ran a regular expression over the whole payload, up to 4 MB, after every tool call, where the Bash
# reading already cuts its payload to 32,768 bytes (9.1 c). Readings where the spec leaves room: "the variable" the
# function sets is found, not assumed: the one variable whose value is a probe's session id after a call (a fixture
# control says one was found), and every case sets it to "stale" before the call so that "returns 1 with the variable
# empty" is seen to empty it. Byte positions count from 1: "falls on byte 32,768" is the 32,768th byte of RAW. W5 is
# asserted loosely, as the brief says: a loop of calls on a 4 MB payload stays well inside C4's 2 s of CPU.
SW9="$TMP/session-id-window"; mkdir -p "$SW9/user" "$SW9/tmp" "$SW9/co" "$SW9/farm" "$SW9/home/projects/zorb" "$SW9/mem"
SW9="$(cd "$SW9" && pwd -P)"; SW9H="$SW9/home"; SW9M="$SW9/mem"; SW9P="$SW9H/projects/zorb"; SW9C="$SW9/co"; SW9T="$(printf '\t')"; SW9NL=$'\n'
printf '{"name": "zorb", "remote_match": "acme/zorb-sw9", "gate": "true"}\n' > "$SW9P/project.json"; printf '# zorb\n' > "$SW9P/CLAUDE.md"
printf 'alpha\tgraph structure\tcore\tgraphify\n' > "$SW9P/routes.tsv"
( _fx_cd "$SW9C" && git init -q -b main && git remote add origin https://github.com/acme/zorb-sw9 \
  && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -q --allow-empty -m c1 ) >/dev/null 2>&1
perl -e 'my ($at, $path, @no) = @ARGV; my %no = map { $_ => 1 } @no; my %seen;
  for my $d (split /:/, $path) { opendir(my $h, $d) or next;
    for my $n (readdir $h) { next if $n =~ /^\./ || $no{$n} || $seen{$n}; my $f = "$d/$n"; next unless -f $f && -x _;
      $seen{$n} = 1; symlink($f, "$at/$n") } }' "$SW9/farm" "$PATH" claude gh felix graphify semgrep
SW9U8="$(locale -a 2>/dev/null | awk '{ l = tolower($0) } l == "en_us.utf-8" || l == "en_us.utf8" { e = $0 } l ~ /utf-?8$/ && a == "" { a = $0 } END { print (e != "" ? e : a) }')"
_sw9_fill() { perl -e 'my ($n, $mb) = @ARGV; print $mb ? ("\xc3\xa9" x int($n / 2)) . ("a" x ($n % 2)) : ("a" x $n)' "$1" "${2:-0}"; }   # N [MULTIBYTE] -> N bytes of a, or of e-acute
SW9HEAD='{"pad":"'; SW9TAIL=',"hook_event_name":"PostToolUse"}'
_sw9_at() {   # END VALUE [MULTIBYTE] [TAIL] [HEAD] -> HEAD<fill>","session_id":"VALUE"TAIL, the value's closing quote on byte END
  local m="\",\"session_id\":\"$2\"" h="${5:-$SW9HEAD}" f
  f="$( LC_ALL=C; printf '%s' "$(( $1 - ${#h} - ${#m} ))" )"
  printf '%s%s%s%s' "$h" "$(_sw9_fill "$f" "${3:-0}")" "$m" "${4:-$SW9TAIL}"
}
SW9V="$( ( . "$FROOT/harness/lib/ledger.sh"; felix_ledger_session_id '{"session_id":"sw9probe7c1e","hook_event_name":"PostToolUse"}' >/dev/null 2>&1
           set -o posix; set ) 2>/dev/null | LC_ALL=C awk -F= '$2 == "sw9probe7c1e" || $2 == "'"'"'sw9probe7c1e'"'"'" { print $1; exit }')"
is "cli-reach amendment fixture: felix_ledger_session_id sets one variable to the session id, found by a probe (fixture control)" \
   "$([ -n "$SW9V" ] && echo found || echo none)" "found"
_sw9_id() {   # RAW [LOCALE] -> status|the variable's value, the variable set to stale before the call; in LOCALE when given
  ( if [ -n "${2:-}" ]; then LC_ALL="$2"; LANG="$2"; export LC_ALL LANG; fi
    . "$FROOT/harness/lib/ledger.sh" 2>/dev/null
    [ -z "$SW9V" ] || printf -v "$SW9V" '%s' stale
    felix_ledger_session_id "$1" >/dev/null 2>&1; r=$?
    if [ -n "$SW9V" ]; then printf '%s|%s' "$r" "${!SW9V}"; else printf '%s|novar' "$r"; fi )
}
_sw9_byte() { ( LC_ALL=C; printf '%s' "${1:$(( $2 - 1 )):1}" ); }   # TEXT N -> its byte N, counted from 1
SW9E0="$(_sw9_at 32768 sw9-edge)"
is "cli-reach amendment fixture: a payload built for byte 32,768 has the value's closing quote there and its length past it (fixture control)" \
   "$(_sw9_byte "$SW9E0" 32768)$(_sw9_byte "$SW9E0" 32767)|$( (LC_ALL=C; printf '%s' "${SW9E0:32745:23}") )" "\"e|\"session_id\":\"sw9-edge\""

printf '\nW1, W2: the first session_id wholly within the window is the session, and nothing past it\n'
is "cli-reach amendment W2: a payload whose session_id comes first names it: 0 and the value" "$(_sw9_id '{"session_id":"sw9-a","hook_event_name":"PostToolUse"}')" "0|sw9-a"
is "cli-reach amendment W2: blanks around the colon are allowed" "$(_sw9_id '{"session_id" :  "sw9-sp","x":1}')" "0|sw9-sp"
is "cli-reach amendment W2: the first session_id and not a later one" "$(_sw9_id '{"session_id":"sw9-first","agent":{"session_id":"sw9-second"}}')" "0|sw9-first"
is "cli-reach amendment W2: a key not first in the payload but within the window is found" \
   "$(_sw9_id '{"hook_event_name":"PostToolUse","tool_name":"Read","session_id":"sw9-late-small"}')" "0|sw9-late-small"
is "cli-reach amendment W2: an empty value returns 1 with the variable empty" "$(_sw9_id '{"session_id":"","hook_event_name":"PostToolUse"}')" "1|"
is "cli-reach amendment W2: an empty first value is the answer though a later one has a value" "$(_sw9_id '{"session_id":"","agent":{"session_id":"sw9-later"}}')" "1|"
is "cli-reach amendment W2: no key returns 1 with the variable empty" "$(_sw9_id '{"hook_event_name":"PostToolUse","tool_name":"Read"}')" "1|"
is "cli-reach amendment W1: the value's closing quote on byte 32,768 is within the window" "$(_sw9_id "$SW9E0")" "0|sw9-edge"
is "cli-reach amendment W1: and on byte 32,767" "$(_sw9_id "$(_sw9_at 32767 sw9-edge)")" "0|sw9-edge"
is "cli-reach amendment W1: on byte 32,769 the session_id is not closed in the window: 1 and empty" "$(_sw9_id "$(_sw9_at 32769 sw9-edge)")" "1|"
is "cli-reach amendment W1: a value whose opening quote is the window's last byte names no session" \
   "$(_sw9_id "$(_sw9_at $(( 32768 + 9 )) sw9-edge)")" "1|"
is "cli-reach amendment W1: a key that begins in the window and a value running far past it name no session" \
   "$(_sw9_id "$(_sw9_at 32800 "sw9-$(_sw9_fill 60)")")" "1|"
is "cli-reach amendment W1: a first session_id wholly past the window names no session" "$(_sw9_id "$(_sw9_at 40000 sw9-past)")" "1|"
is "cli-reach amendment W1: one cut at the window's edge, a second complete one after it: no session, nothing further looked at" \
   "$(_sw9_id "$(_sw9_at 32769 sw9-cut ",\"agent\":{\"session_id\":\"sw9-after\"}}")")" "1|"
is "cli-reach amendment W1: the first within the window wins over a second past it" \
   "$(_sw9_id "{\"session_id\":\"sw9-in\",$(_sw9_at 40000 sw9-out | LC_ALL=C cut -c2-)")" "0|sw9-in"
perl -e 'print q({"session_id":"sw9-big","transcript_path":"/u/t.jsonl","tool_response":{"stdout":"), "a" x 4194304, q(","x":{"session_id":"sw9-deep"}}})' > "$SW9/big.json"
SW9BIG="$(cat "$SW9/big.json")"
is "cli-reach amendment W2: a 4 MB payload with the key first names it, a later session_id deep in it aside" "$(_sw9_id "$SW9BIG")" "0|sw9-big"

printf '\nW4: bytes, in any locale\n'
if [ -z "$SW9U8" ]; then
  skip "cli-reach amendment W4: the window in a UTF-8 locale" "no UTF-8 locale is installed"
else
  SW9M1="$(_sw9_at 32768 sw9-edge 1)"; SW9M2="$(_sw9_at 32769 sw9-edge 1)"
  is "cli-reach amendment W4: the two-byte payloads hold far fewer than 32,768 characters in that locale (fixture control)" \
     "$( (LC_ALL="$SW9U8"; [ "${#SW9M2}" -lt 20000 ] && echo fewer || echo "${#SW9M2}") )|$(_sw9_byte "$SW9M1" 32768)" "fewer|\""
  is "cli-reach amendment W4: in a UTF-8 locale, two-byte characters before the key, a closing quote on byte 32,768 is found" "$(_sw9_id "$SW9M1" "$SW9U8")" "0|sw9-edge"
  is "cli-reach amendment W4: and one on byte 32,769 is not, however few characters that is" "$(_sw9_id "$SW9M2" "$SW9U8")" "1|"
  is "cli-reach amendment W4: an ASCII payload in that locale: byte 32,768 found, 32,769 not" \
     "$(_sw9_id "$SW9E0" "$SW9U8") $(_sw9_id "$(_sw9_at 32769 sw9-edge)" "$SW9U8")" "0|sw9-edge 1|"
  is "cli-reach amendment W4: a key wholly past the window is not found in that locale either" "$(_sw9_id "$(_sw9_at 40000 sw9-past 1)" "$SW9U8")" "1|"
fi
is "cli-reach amendment W4: and in the C locale the two-byte payloads read as in UTF-8" \
   "$(_sw9_id "$(_sw9_at 32768 sw9-edge 1)" C) $(_sw9_id "$(_sw9_at 32769 sw9-edge 1)" C)" "0|sw9-edge 1|"

printf '\nW3: through the hooks\n'
_sw9_ls() { find "$SW9H/state/ledger" 2>/dev/null | LC_ALL=C sort; }   # -> what the home's state/ledger holds
_sw9_pt() {   # PAYLOAD-FILE -> post-tool in the checkout fed it; status in $SW9/pt.rc
  ( _fx_cd "$SW9C" && env -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CONFIG_DIR HOME="$SW9/user" FELIX_HOME="$SW9H" FELIX_MEMORY="$SW9M" \
      TMPDIR="$SW9/tmp" PATH="$SW9/farm" "$FROOT/harness/hooks/post-tool" < "$1" > "$SW9/pt.out" 2>&1; printf '%s' "$?" > "$SW9/pt.rc" )
}
_sw9_raw() { if [ -f "$1" ]; then cat "$1"; printf '|'; else printf 'none'; fi; }   # FILE -> its bytes, then |, or none
SW9TL="\"transcript_path\":\"$SW9/tr/x.jsonl\",\"cwd\":\"$SW9C\",\"permission_mode\":\"default\",\"hook_event_name\":\"PostToolUse\""
{ printf '{"session_id":"sw9-pt-big",%s,"tool_name":"Bash","tool_input":{"command":"ls -la","description":"q"},"tool_response":{"stdout":"' "$SW9TL"
  perl -e 'print "line of output " x 300000'; printf '","stderr":"","interrupted":false,"isImage":false}}'; } > "$SW9/w3a.json"
_sw9_pt "$SW9/w3a.json"
is "cli-reach amendment W3: a 4 MB PostToolUse payload, its session_id first, records one alive line and one call line, the hook exiting 0" \
   "$(wc -c < "$SW9/w3a.json" | awk '{ print ($1 >= 4194304) ? "4 MB" : $1 " bytes" }')|$(cat "$SW9/pt.rc")|$(_sw9_raw "$SW9H/state/ledger/sw9-pt-big.tsv")" \
   "4 MB|0|alive${SW9T}post-tool${SW9NL}tool${SW9T}Bash${SW9NL}|"
printf '{%s,"tool_name":"Read","tool_input":{"file_path":"/x"},"session_id":"sw9-pt-small"}' "$SW9TL" > "$SW9/w3b.json"; _sw9_pt "$SW9/w3b.json"
is "cli-reach amendment W3: a small payload whose session_id comes last is recorded under it" "$(cat "$SW9/pt.rc")|$(_sw9_raw "$SW9H/state/ledger/sw9-pt-small.tsv")" \
   "0|alive${SW9T}post-tool${SW9NL}tool${SW9T}Read${SW9NL}|"
printf '{"session_id":"sw9-pt-one",%s,"tool_name":"Read","tool_input":{"file_path":"/x","session_id":"sw9-pt-two"}}' "$SW9TL" > "$SW9/w3c.json"; _sw9_pt "$SW9/w3c.json"
is "cli-reach amendment W3: the payload's first session_id is the one recorded under" \
   "$(_sw9_raw "$SW9H/state/ledger/sw9-pt-one.tsv")$(_sw9_raw "$SW9H/state/ledger/sw9-pt-two.tsv")" "alive${SW9T}post-tool${SW9NL}tool${SW9T}Read${SW9NL}|none"
SW9B4="$(_sw9_ls)"
{ printf '{%s,"tool_name":"Read","tool_input":{"file_path":"/x"},"tool_response":{"stdout":"' "$SW9TL"; _sw9_fill 40000
  printf '"},"session_id":"sw9-pt-past"}'; } > "$SW9/w3d.json"; _sw9_pt "$SW9/w3d.json"
is "cli-reach amendment W3: a payload whose only session_id lies past 32,768 bytes exits 0 and records nothing" "$(cat "$SW9/pt.rc")|$(_sw9_ls)" "0|$SW9B4"
_sw9_at 32769 sw9-pt-cut 0 "}" "{$SW9TL,\"tool_name\":\"Read\",\"tool_input\":{\"file_path\":\"/x\"},\"pad\":\"" > "$SW9/w3e.json"; _sw9_pt "$SW9/w3e.json"
is "cli-reach amendment W3: that payload has its session_id key in the window and its closing quote on byte 32,769 (fixture control)" \
   "$(LC_ALL=C awk -v RS='\001' '{ k = index($0, "\"session_id\""); print ((k > 0 && k < 32768) ? "in" : "out") "|" substr($0, 32769, 1) }' "$SW9/w3e.json")" "in|\""
is "cli-reach amendment W3: as does one whose session_id begins in the window and closes past it" "$(cat "$SW9/pt.rc")|$(_sw9_ls)" "0|$SW9B4"
printf '{%s,"tool_name":"Read","tool_input":{"file_path":"/x"}}' "$SW9TL" > "$SW9/w3f.json"; _sw9_pt "$SW9/w3f.json"
is "cli-reach amendment W3: as does a payload with no session_id at all (control)" "$(cat "$SW9/pt.rc")|$(_sw9_ls)" "0|$SW9B4"
_sw9_ss() {   # PAYLOAD -> session-start in the checkout fed it; status in $SW9/ss.rc
  ( _fx_cd "$SW9C" && env -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CONFIG_DIR -u CLAUDE_PLUGIN_ROOT -u CLAUDE_PROJECT_DIR -u FELIX_HOME_DIR \
      -u COPILOT_CLI -u CURSOR_PLUGIN_ROOT -u GIT_DIR -u GIT_WORK_TREE HOME="$SW9/user" FELIX_HOME="$SW9H" FELIX_MEMORY="$SW9M" TMPDIR="$SW9/tmp" PATH="$SW9/farm" \
      "$FROOT/harness/hooks/session-start" <<<"$1" > "$SW9/ss.out" 2> "$SW9/ss.err"; printf '%s' "$?" > "$SW9/ss.rc" )
}
SW9SS="\"transcript_path\":\"$SW9/tr/s.jsonl\",\"cwd\":\"$SW9C\",\"hook_event_name\":\"SessionStart\",\"source\":\"startup\""
SW9PAD="$(_sw9_fill 40000)"
_sw9_ss "{\"session_id\":\"sw9-ss-early\",\"pad\":\"$SW9PAD\",$SW9SS}"
is "cli-reach amendment W3: session start for a payload with its session_id first, 40 KB after it, writes the names file (control)" \
   "$(cat "$SW9/ss.rc")|$(_sw9_raw "$SW9H/state/ledger/sw9-ss-early.names")" "0|graphify${SW9NL}|"
_sw9_ss "{\"pad\":\"$SW9PAD\",\"session_id\":\"sw9-ss-late\",$SW9SS}"
is "cli-reach amendment W3: session start for one whose session_id lies past 32,768 bytes exits 0 and writes no names file" \
   "$(cat "$SW9/ss.rc")|$(_sw9_raw "$SW9H/state/ledger/sw9-ss-late.names")" "0|none"

printf '\nW5: a 4 MB payload costs a cut, not a scan (loose)\n'
_sw9_cpu() {   # RAW N -> N calls in one shell; prints the calls that named sw9-big, then the shell's own CPU across them (user plus system)
  # times writes to a file and not into a pipe or a substitution: either would run it in a fork, whose own CPU is new.
  ( . "$FROOT/harness/lib/ledger.sh" 2>/dev/null; sw9n=0; i=0
    times > "$SW9/t0.times" 2>/dev/null
    while [ "$i" -lt "$2" ]; do felix_ledger_session_id "$1" >/dev/null 2>&1 && [ -n "$SW9V" ] && [ "${!SW9V}" = sw9-big ] && sw9n=$((sw9n + 1)); i=$((i + 1)); done
    times > "$SW9/t1.times" 2>/dev/null
    printf '%s ' "$sw9n"
    LC_ALL=C awk 'function s(v,  m) { gsub(/,/, ".", v); m = v; sub(/m.*$/, "", m); sub(/^[0123456789]+m/, "", v); sub(/s$/, "", v); return m * 60 + v }
      FNR == 1 && $1 ~ /^[0123456789]+m[0123456789.,]+s$/ && $2 ~ /^[0123456789]+m[0123456789.,]+s$/ { c[++k] = s($1) + s($2) }
      END { if (k == 2) printf "%.3f", c[2] - c[1]; else printf "unread" }' "$SW9/t0.times" "$SW9/t1.times" )
}
SW9C5="$(_sw9_cpu "$SW9BIG" 5)"
is "cli-reach amendment W5: five calls on a 4 MB payload, the key first, each name it and together take well under 2 s of CPU" \
   "$(printf '%s' "$SW9C5" | awk '{ print $1 "|" (($2 != "unread" && $2 + 0 < 2) ? "under 2 s" : "took " $2 " s") }')" "5|under 2 s"
