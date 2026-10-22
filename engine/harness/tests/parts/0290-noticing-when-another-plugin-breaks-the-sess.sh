# ================================================= (i) CLI and the Stop hook
# A governed throwaway checkout, green but for the catch: a gate that passes,
# a probe that reads the marker, and a verify record for its tree.
_memory_guarded_build
_bw_build
_BWHP="$FROOT/projects/bwhook"; _BWHM="$MEM/bwhook"; mkdir -p "$_BWHP" "$_BWHM"
printf '{\n  "name": "bwhook",\n  "remote_match": "example.com/bwhook",\n  "gate": "true"\n}\n' > "$_BWHP/project.json"
printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' > "$_BWHP/probes.tsv"
_BWHR="$TMP/bw-hook-repo"; _bwrepo "$_BWHR" bw/hook; _BWHR="$(cd "$_BWHR" && pwd -P)"
printf 'bwhook\n' > "$_BWHR/.felix"; printf 'uncommitted\n' > "$_BWHR/work.txt"
( cd "$_BWHR" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$_BWHR" "$FROOT" 0 "gate.sh" "$(felix_tree_id "$_BWHR" "$FROOT")" "" >/dev/null 2>&1 )
_bwstop() { ( cd "$_BWHR" && printf '{"hook_event_name":"Stop","stop_hook_active":false,"session_id":"%s"}' "$1" \
               | "$FROOT/harness/hooks/stop" 2>&1 ); }
_bwhcatch() {  # a catch this checkout's session filed half an hour ago
  rm -f "$_BWHM/mistakes.log" "$_BWHM/written.log" "$_BWHM/lessons.md" "$_BWHM/DEVLOG.md"
  printf '%s\tbw/hook\t0123abc\tlint\t%s\t%s\n' "$(_bwday "$_BWT")" "$_BWT" "$1" > "$_BWHM/mistakes.log"
  _bwmt "$_BWT" "$_BWHM/mistakes.log"
}
_bwcli() {  # session command text: felix run inside the checkout
  if [ -n "$1" ]; then ( cd "$_BWHR" && CLAUDE_CODE_SESSION_ID="$1" "$FROOT/harness/felix" "$2" "$3" ) >/dev/null 2>&1
  else ( cd "$_BWHR" && unset CLAUDE_CODE_SESSION_ID && "$FROOT/harness/felix" "$2" "$3" ) >/dev/null 2>&1; fi
}

_bwhcatch bw-e2e-a
has "through the Stop hook, this session's catch with nothing written prompts" "$(_bwstop bw-e2e-a)" "nothing has been written down"

_bwhcatch bw-e2e-b
_bwcli bw-e2e-b lesson "bw e2e lesson"
is "felix lesson run in the checkout leaves a written.log row for its session, branch and kind" \
   "$(tail -1 "$_BWHM/written.log" 2>/dev/null | cut -f2,4,6 | tr '\t' '|')" "bw/hook|lesson|bw-e2e-b"
is "through the Stop hook, this session's felix lesson after its catch gives no prompt" "$(_bwstop bw-e2e-b)" ""

_bwhcatch bw-e2e-c
_bwcli bw-e2e-peer lesson "bw e2e peer lesson"
has "through the Stop hook, a peer session's felix lesson after this session's catch still prompts" \
    "$(_bwstop bw-e2e-c)" "nothing has been written down"

_bwhcatch bw-e2e-d
_bwcli bw-e2e-d log "bw e2e log"
is "felix log run in the checkout leaves a written.log row of kind log for its session" \
   "$(tail -1 "$_BWHM/written.log" 2>/dev/null | cut -f2,4,6 | tr '\t' '|')" "bw/hook|log|bw-e2e-d"
is "through the Stop hook, this session's felix log after its catch gives no prompt" "$(_bwstop bw-e2e-d)" ""

_bwhcatch bw-e2e-e
_bwcli bw-e2e-peer2 log "bw e2e peer log"
has "through the Stop hook, a peer session's felix log after this session's catch still prompts" \
    "$(_bwstop bw-e2e-e)" "nothing has been written down"

_bwhcatch bw-e2e-f
_bwcli '' lesson "bw e2e sessionless lesson"
has "through the Stop hook, a felix lesson run outside every session does not settle this session's catch" \
    "$(_bwstop bw-e2e-f)" "nothing has been written down"

rm -rf "$_BWHP" "$_BWHM"
_bwreset
unset -f _bwcatch _bwwrote _bwprose _bwverdict _bwsays _bwsays0 \
         _bwhead _bwrows _bwlast _bwnf _bwwhen _bwbytes _bwpick _bwlesson _bwlog _bwsess \
         _bwuntimed _bwbadrow _bwstop _bwhcatch _bwcli
unset _BWD _BWK _BWW _BWL _BWV _BWFIRST _BWN _BWTODAY _BWDAY2 _BWR_THIS _BWR_V _BWR_W _BWR_DET _BWR_UB _BWR_NG \
      _BWSHA _BWDSHA _BWT _BWM _BWHP _BWHM _BWHR _bwt0 _bwt1 _bwd0 _bwd1 _bwgot _bwhdr _bwhv _bwout _bwb
rm -rf "$GP"

printf '\nnoticing when another plugin breaks the session\n'
# A plugin that ships hooks is a dependency on that plugin working. When one
# refuses, the error lands on the tool rather than on the plugin that caused
# it, so it reads as the editor being broken. Claude Code records these
# properly, which is what makes noticing them cheap.
GT="$TMP/guard.jsonl"
cat > "$GT" <<'JSONL'
{"type":"attachment","attachment":{"type":"hook_blocking_error","hookName":"PostToolUse:Write","hookEvent":"PostToolUse","blockingError":{"blockingError":"Not logged into Semgrep Guardian. Ask the guardian mcp to login.","command":"bash x"}}}
{"type":"attachment","attachment":{"type":"hook_blocking_error","hookName":"PostToolUse:Write","hookEvent":"PostToolUse","blockingError":{"blockingError":"Not logged into Semgrep Guardian. Ask the guardian mcp to login.","command":"bash x"}}}
{"type":"assistant","message":{"content":[]}}
JSONL
rows="$( . "$FROOT/harness/lib/guard.sh"; felix_guard_blocks "$GT" )"
has "counts what was blocked"     "$rows" "2"
has "and names the hook"          "$rows" "PostToolUse:Write"
has "and quotes what it said"     "$rows" "Not logged into Semgrep"
# A transcript with no blocks must say nothing at all.
printf '{"type":"assistant"}\n' > "$TMP/clean.jsonl"
q="$( . "$FROOT/harness/lib/guard.sh"; felix_guard_blocks "$TMP/clean.jsonl" )"
is "silent when nothing was blocked" "${#q}" "0"
# A missing transcript is a fact, not a crash.
q="$( . "$FROOT/harness/lib/guard.sh"; felix_guard_blocks "$TMP/nope.jsonl" )"; rc=$?
is "survives a transcript that is not there" "$rc" "0"

out="$(cd "$REPO" && "$FELIX" quarantine definitely-not-installed 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && ok "quarantine refuses a plugin that is not here" \
                || bad "quarantine refuses a plugin that is not here" "$out"

# The report exists for ANOTHER plugin's hook, and it never checked. Felix's own
# Stop hook holds a chain until the gate has seen the tree — working exactly as
# designed — and that block came back to the founder under the headline "and it
# was not Felix", attributed to the felix plugin two lines below, with the
# remedy `felix quarantine felix`. A report that contradicts itself inside four
# lines and then recommends switching off the system that produced it. Observed
# live, not constructed: it fired twice in the session that fixed it.
_isown() { ( . "$FROOT/harness/lib/guard.sh"; . "$FROOT/harness/lib/ready.sh"
             felix_guard_is_own "$1" ) && printf yes || printf no; }
is "Felix's own gate refusal is recognised as its own" \
   "$(_isown 'The gate last ran at 2026-08-13T09:30:36Z, on a different tree. Run felix gate. Or set FELIX_ALLOW_RED=1.')" "yes"
is "and so is a deny from its own PreToolUse" \
   "$(_isown 'felix: this project forbids that command. See felix which.')" "yes"
is "another plugin's refusal is not"  \
   "$(_isown 'Not logged into Semgrep Guardian. Ask the guardian mcp to login.')" "no"
is "and neither is an empty message"  "$(_isown '')" "no"

printf '\ndiscovery runs on a cadence, not in front of a prompt\n'
DH="$TMP/dhome"; mkdir -p "$DH/state/discover"
# Every fixture cache carries the stamp a real one does, or the readers treat
# it as absent — which is the point, asserted below.
DP="$FROOT/projects/widget"
# Never refreshed is stale; that is what makes the first run happen at all.
( . "$FROOT/harness/lib/discover.sh"; felix_discover_stale "$DP" "$DH" ) \
  && ok "a cache that never existed is stale" || bad "a cache that never existed is stale"
{ _dstamp; printf 'deepeval\tllm\tlow\nlangfuse\tllm\tlow\n'; } > "$DH/state/discover/widget.tsv"
( . "$FROOT/harness/lib/discover.sh"; felix_discover_stale "$DP" "$DH" ) \
  && bad "a fresh cache is not stale" || ok "a fresh cache is not stale"
new="$( . "$FROOT/harness/lib/discover.sh"; felix_discover_unseen "$DP" "$DH" | tr '\n' ' ' )"
has "reports findings the first time" "$new" "deepeval"
( . "$FROOT/harness/lib/discover.sh"; felix_discover_mark_seen "$DP" "$DH" )
( . "$FROOT/harness/lib/discover.sh"; grep -q '^#' "$(_felix_discover_cache "$DP" "$DH").seen" ) \
  && bad "the seen file never carries the stamp comment" || ok "the seen file never carries the stamp comment"
new="$( . "$FROOT/harness/lib/discover.sh"; felix_discover_unseen "$DP" "$DH" )"
is "and never mentions the same one twice" "${#new}" "0"
# Something genuinely new must still get through.
printf 'sonarqube\tsecrets\thigh\n' >> "$DH/state/discover/widget.tsv"
new="$( . "$FROOT/harness/lib/discover.sh"; felix_discover_unseen "$DP" "$DH" | tr '\n' ' ' )"
has "but a new one does get through" "$new" "sonarqube"

# An unreadable catalogue is not an empty one. felix_discover_candidates used to
# come back with no rows whether the marketplaces had nothing for this project
# or the CLI had fallen over, and the quiet form wrote the second as the first
# into a cache that stays current for seven days. Read by an agent from the
# find-skills plugin's catalogue reader, which draws the line this one did not.
printf '\nan unreadable catalogue is not an empty one\n'
DCP="$TMP/discover-cands"; mkdir -p "$DCP/proj" "$DCP/bin-fail" "$DCP/bin-prose" "$DCP/bin-empty" "$DCP/bin-hit" "$DCP/bin-none" "$DCP/bin-tail" "$DCP/bin-many"
printf 'llm\n' > "$DCP/proj/capabilities"
printf 'plugin\tanthropic-skills\t-\tlow\talways\n' > "$DCP/proj/stack.tsv"
printf '#!/bin/sh\nexit 1\n' > "$DCP/bin-fail/claude"
printf '#!/bin/sh\necho "Error: could not reach the marketplace"\n' > "$DCP/bin-prose/claude"
printf '#!/bin/sh\necho "[]"\n' > "$DCP/bin-empty/claude"
cat > "$DCP/bin-hit/claude" <<'STUB'
#!/bin/sh
cat <<'J'
[
  {
    "name": "deepeval",
    "description": "llm evaluation and prompt testing"
  }
]
J
STUB
# A listing whose LAST entry does not match. This is the shape the whole
# fix turned on: a `while` loop's status is its last body command's, so the
# scoring loop returned 1 for every catalogue ending in a non-match — which
# is most catalogues — and cmd_discover, once it started reading the status,
# called a perfectly readable marketplace unreadable.
cat > "$DCP/bin-tail/claude" <<'STUB'
#!/bin/sh
cat <<'J'
[
  {
    "name": "deepeval",
    "description": "llm evaluation and prompt testing"
  },
  {
    "name": "laundry-folder",
    "description": "a widget for folding laundry"
  }
]
J
STUB
# More matches than FELIX_DISCOVER_MAX, so `head` closes the pipe on the
# rows still coming and everything upstream takes SIGPIPE. The same shape as
# the grep -q lesson this repository already carries.
{ printf '#!/bin/sh\ncat <<J\n[\n'
  i=1; while [ "$i" -le 12 ]; do
    [ "$i" -eq 1 ] || printf ',\n'
    printf '  {\n    "name": "llm-tool-%s",\n    "description": "llm prompt evaluation and inference"\n  }' "$i"
    i=$((i+1))
  done
  printf '\n]\nJ\n'; } > "$DCP/bin-many/claude"
chmod +x "$DCP"/bin-*/claude
_dcands() { ( PATH="$DCP/$1:$PATH"; export PATH
              . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"; . "$FROOT/harness/lib/discover.sh"
              out="$(felix_discover_candidates "$DCP/proj" "$FROOT/harness/templates")"; rc=$?
              printf '%s|%s' "$rc" "$out" ); }
is  "a CLI that fails is exit 3 and no rows" "$(_dcands bin-fail)" "3|"
is  "a CLI that prints an error and exits 0 is exit 3 and no rows too" "$(_dcands bin-prose)" "3|"
is  "an empty listing is exit 0 and no rows: a catalogue that was read" "$(_dcands bin-empty)" "0|"
has "and a listing with a match still scores it" "$(_dcands bin-hit)" "deepeval"
_dchit="$(_dcands bin-hit)"
is  "with exit 0" "${_dchit%%|*}" "0"
# `cut -d'|' -f1` is line-oriented, so a result with more than one row leaks
# rows into the field being compared. The code is taken by expansion.
_dctail="$(_dcands bin-tail)"; _dcmany="$(_dcands bin-many)"
is  "a catalogue whose LAST entry does not match is still exit 0" "${_dctail%%|*}" "0"
has "and the entry that did match is still returned" "$_dctail" "deepeval"
is  "more matches than the row cap is exit 0, not the pipe closing under it" "${_dcmany%%|*}" "0"
is  "and the cap is what it returns" "$(printf '%s' "${_dcmany#*|}" | grep -c .)" "8"
is  "and no CLI on PATH at all is exit 3, not an empty marketplace" \
    "$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"; . "$FROOT/harness/lib/discover.sh"
        PATH="$DCP/bin-none"; export PATH
        felix_discover_candidates "$DCP/proj" "$FROOT/harness/templates" >/dev/null 2>&1; echo $? )" "3"
# Through the CLI: the quiet form writes nothing and exits non-zero, so the
# `&&` every cache writer guards with leaves the previous answer standing.
# The widget declares a capability with a discovery rule for the duration, or
# the candidates function returns before it ever asks the CLI.
cp "$FROOT/projects/widget/capabilities" "$TMP/caps.discover.keep" 2>/dev/null || : > "$TMP/caps.discover.keep"
printf 'llm\n' >> "$FROOT/projects/widget/capabilities"
DCH="$FROOT/state/discover"; mkdir -p "$DCH"
{ _dstamp; printf 'langfuse\tllm\tlow\n'; } > "$DCH/widget.tsv"
DCW="$(cat "$DCH/widget.tsv")"
out="$(cd "$REPO" && PATH="$DCP/bin-fail:$PATH" "$FELIX" discover --inspect --quiet 2>/dev/null)"; rc=$?
# Exits with the status it refused with since 2026-10-01: 3 here, and 2 for rules
# that could not be read, so that --adopt, which fills the cache with it, can say
# which of the two it was. Still non-zero, which is what the `&&` above asks.
is  "felix discover --inspect --quiet exits 3 when the catalogue cannot be read" "$rc" "3"
is  "and prints nothing, not even the stamp" "$out" ""
out="$(cd "$REPO" && PATH="$DCP/bin-fail:$PATH" "$FELIX" discover 2>&1)"
has "and the loud form says the catalogue was never seen" "$out" "could not be read"
is  "the cache already there is untouched" "$(cat "$DCH/widget.tsv")" "$DCW"
# And a writer that actually writes. The assertion above runs the loud form,
# which has no cache writer in any version, so it could not have failed for
# the defect it is named after. --adopt fills a cache it finds STALE, and
# that fill is one of the two the guard was added to: a stale answer must
# survive a failed read rather than be replaced by an empty one.
DCS="# stamp not-the-current-one
langfuse	llm	low"
printf '%s\n' "$DCS" > "$DCH/widget.tsv"
out="$(cd "$REPO" && PATH="$DCP/bin-fail:$PATH" "$FELIX" discover --adopt 2>&1)"; rc=$?
is  "a stale cache and an unreadable catalogue adopts nothing" "$rc" "2"
is  "and the stale answer is still there, not replaced by an empty one" "$(cat "$DCH/widget.tsv")" "$DCS"
[ -e "$DCH/widget.tsv.new" ] && bad "and no half-written cache is left beside it" "left behind" || ok "and no half-written cache is left beside it"
rm -f "$DCH/widget.tsv"
out="$(cd "$REPO" && PATH="$DCP/bin-fail:$PATH" "$FELIX" discover --adopt 2>&1)"; rc=$?
is  "discover --adopt with no cache and no catalogue adopts nothing and says why" "$rc" "2"
has "in words" "$out" "nothing was adopted"
[ -e "$DCH/widget.tsv" ] && bad "and writes no cache" "$(cat "$DCH/widget.tsv")" || ok "and writes no cache"
[ -e "$DCH/widget.tsv.new" ] && bad "nor a half-written one" "left behind" || ok "nor a half-written one"
out="$(cd "$REPO" && PATH="$DCP/bin-empty:$PATH" "$FELIX" discover --inspect --quiet 2>/dev/null)"; rc=$?
is  "and a catalogue that was read and matched nothing is exit 0" "$rc" "0"
is  "with the stamp and no rows, which is an empty cache and a real answer" "$out" "$(_dstamp)"
cp "$TMP/caps.discover.keep" "$FROOT/projects/widget/capabilities"

printf '\ndiscovery reads before it recommends\n'
# The plugin format has no permission declaration and `claude plugin validate`
# checks schema only, so the only way to know what something does is to read it.
# Fixtures throughout: this must never touch the network to be tested.
_discover_fixtures_build

is "skills only is low"                  "$(_tier "$DF/skillsonly")" "low"
is "a pinned local server is medium"     "$(_tier "$DF/mcplocal")"   "medium"
is "anything shipping hooks is high"     "$(_tier "$DF/hooky")"      "high"
is "an unpinned version is high"         "$(_tier "$DF/floaty")"     "high"
is "interpolating a credential is high"  "$(_tier "$DF/creds")"      "high"

