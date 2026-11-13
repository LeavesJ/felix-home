#!/usr/bin/env bash
# Field by field parity: one host session record against what Beacon wrote for the same session.
#
#   parity.sh codex   <rollout-*.jsonl>        <beacon.jsonl>
#   parity.sh factory <session.jsonl>          <beacon.jsonl>
#
# The raw record is the host's own file: a Codex rollout under $CODEX_HOME/sessions, or a Factory
# Droid session under ~/.factory/sessions. The Beacon file is what `beacon endpoint codex sync
# --print` or `beacon endpoint factory sync --print` printed, or the runtime log. Calls are joined
# on the host's own call id (Codex call_id, Factory tool_use id), the same id Beacon writes as
# gen_ai.tool.call.id.
#
# stdout, one row per field, in a fixed order:
#   field <TAB> name <TAB> raw_source <TAB> beacon_source <TAB> raw_n <TAB> beacon_n <TAB> equal_n <TAB> verdict
# then one row per call whose values differ:
#   mismatch <TAB> name <TAB> call_id <TAB> raw value as JSON <TAB> beacon value as JSON
# verdict is one of:
#   match             every call the raw record holds this field for, Beacon holds the same value
#   differs           Beacon holds the field for some of those calls, with another value or none
#   absent_in_beacon  the raw record holds it, Beacon holds it for no call
#   absent_in_raw     the raw record holds it for no call, so there is nothing to compare
# raw_n counts calls the raw record holds the field for, beacon_n calls Beacon holds it for,
# equal_n calls where both hold it and the values are equal as JSON.
#
# exit 0  compared; the verdicts say what matched
# exit 2  cannot compare: nothing on stdout, one row on stderr:
#           refuse <TAB> reason_code <TAB> reason_detail
#
# Assumptions, each read from Beacon's own parsers at v1.3.47 (codexsession/types.go,
# factorysession/types.go) and not from a real file:
#   - Codex rollout lines are {type, payload}. session_meta.payload carries id and cwd,
#     turn_context.payload carries cwd, response_item.payload is a function_call (name,
#     arguments as a JSON string, call_id) or custom_tool_call (name, input, call_id).
#   - Codex may write exit codes as event_msg payloads of type exec_command_end with call_id and
#     exit_code. The founder's run of 2026-10-29 found none on codex-cli 0.162.0-alpha.17.2, so
#     exit_code reads absent_in_raw there; the exit status sits in the output text instead
#     ("Process exited with code 1"), on both sides, and the tool_output row compares it.
#   - Factory session lines carry cwd on some record and message.content[] blocks of type
#     tool_use (id, name, input) and tool_result (tool_use_id, is_error).
#   - TODO(mac run): the Factory session id is the session file's name without .jsonl, as
#     Beacon's store.go reads it. If Beacon's session.id differs on a real run, that row says so.
set -uo pipefail

_refuse() { printf 'refuse\t%s\t%s\n' "$1" "$2" >&2; exit 2; }

[ "$#" -eq 3 ] || _refuse parity_usage "usage: parity.sh codex|factory <raw-session.jsonl> <beacon.jsonl>"
host="$1"; raw="$2"; bea="$3"
case "$host" in codex|factory) ;; *) _refuse parity_host_unknown "host must be codex or factory, not $host" ;; esac
jq="${FELIX_JQ:-jq}"
command -v "$jq" >/dev/null 2>&1 || _refuse parity_jq_missing "no JSON parser on this machine ($jq)"
for f in "$raw" "$bea"; do
  [ -f "$f" ] && [ -r "$f" ] || _refuse parity_input_unreadable "nothing readable at $f"
  [ -s "$f" ] || _refuse parity_input_empty "$f holds no records"
  # One bad line refuses the file: a partial read would compare a prefix and call it the session.
  bad="$(LC_ALL=C "$jq" -nr --raw-input '[inputs] | to_entries[] | select((.value | try fromjson catch "\u0000bad") == "\u0000bad") | .key + 1' "$f" 2>&1 | head -1)"
  [ -z "$bad" ] || _refuse parity_line_not_json "line $bad of $f is not one JSON document"
done
sid_from_name="$(basename "$raw" .jsonl)"

out="$(LC_ALL=C "$jq" -nr --arg host "$host" --arg sid_from_name "$sid_from_name" \
  --slurpfile raw "$raw" --slurpfile bea "$bea" '
  def str: if type == "string" then . else "" end;
  def argobj: if type == "object" then .
              elif type == "string" then (. as $s | try fromjson catch $s)
              else . end;
  # apply_patch names its paths on these lines, and a Move names the destination.
  def patchpaths: [ (. // "") | tostring | splits("\n") | capture("^\\*\\*\\* (?:(?:Add|Update|Delete) File|Move to): (?<p>.+)$")? | .p ] | sort;

  # Raw: one object per call id, holding only the fields this record has.
  ( if $host == "codex" then
      ( [ $raw[] | select(.type == "session_meta") | .payload | (.id // .session_id) | str ] | map(select(. != "")) | first // "" ) as $sid
      | reduce $raw[] as $l ({cwd: "", calls: {}};
          if $l.type == "session_meta" and (($l.payload.cwd | str) != "") then .cwd = $l.payload.cwd
          elif $l.type == "turn_context" and (($l.payload.cwd | str) != "") then .cwd = $l.payload.cwd
          elif $l.type == "response_item" and (($l.payload.type == "function_call") or ($l.payload.type == "custom_tool_call"))
               and (($l.payload.call_id | str) != "") then
            ($l.payload.call_id) as $id
            | (if $l.payload.type == "function_call" then ($l.payload.arguments | argobj) else $l.payload.input end) as $in
            | .calls[$id] = ((if $sid != "" then {session_id: $sid} else {} end) + {tool_name: $l.payload.name, tool_input: $in}
                + (if .cwd != "" then {working_directory: .cwd} else {} end)
                + (if $l.payload.name == "apply_patch" then {apply_patch_paths: ((if ($in | type) == "object" then ($in.input // $in.patch) else $in end) | patchpaths)} else {} end)
                + (if $l.payload.name == "write_stdin" and ($in | type) == "object" and ($in | has("chars")) then {typed_chars: $in.chars} else {} end))
          elif $l.type == "response_item" and (($l.payload.type == "function_call_output") or ($l.payload.type == "custom_tool_call_output"))
               and (($l.payload.call_id | str) != "") and .calls[$l.payload.call_id] != null and ($l.payload | has("output")) then
            .calls[$l.payload.call_id].tool_output = $l.payload.output
          elif $l.type == "event_msg" and $l.payload.type == "exec_command_end" and (($l.payload.call_id | str) != "")
               and ($l.payload | has("exit_code")) and .calls[$l.payload.call_id] != null then
            .calls[$l.payload.call_id].exit_code = $l.payload.exit_code
          else . end)
      | .calls
    else
      ( [ $raw[] | .cwd | str | select(. != "") ] | first // "" ) as $cwd
      | reduce ($raw[] | (.message.content // []) | if type == "array" then .[] else empty end) as $b ({};
          if $b.type == "tool_use" and (($b.id | str) != "") then
            .[$b.id] = ({session_id: $sid_from_name, tool_name: $b.name} + (if $b | has("input") then {tool_input: $b.input} else {} end)
              + (if $cwd != "" then {working_directory: $cwd} else {} end))
          elif $b.type == "tool_result" and (($b.tool_use_id | str) != "") and .[$b.tool_use_id] != null then
            .[$b.tool_use_id].failed = ($b.is_error == true)
          else . end)
    end ) as $R

  # Beacon: the same fields from every event of the call, the first value seen winning, in file order.
  | ( reduce ($bea[] | select(type == "object" and ((.gen_ai.tool.call.id | str) != ""))) as $e ({};
        ($e.gen_ai.tool.call.id) as $id
        | (.[$id] // {}) as $c
        | ( ($e.gen_ai.tool.call.arguments // null) as $a
            | if $a != null then ($a | argobj) else ($e.tool.command // null | if . == null then null else argobj end) end ) as $in
        | .[$id] = ( $c
            + (if ($c | has("session_id")) or (($e.session.id | str) == "") then {} else {session_id: $e.session.id} end)
            + (if ($c | has("working_directory")) or (($e.session.working_directory | str) == "") then {} else {working_directory: $e.session.working_directory} end)
            + (if ($c | has("tool_name")) or (($e.tool.name // $e.gen_ai.tool.name | str) == "") then {} else {tool_name: ($e.tool.name // $e.gen_ai.tool.name)} end)
            + (if ($c | has("tool_input")) or $in == null then {} else {tool_input: $in} end)
            + (if ($c | has("exit_code")) or ($e.command.exit_code == null) then {} else {exit_code: $e.command.exit_code} end)
            + (($e.command.output // $e.gen_ai.tool.call.result) as $o
               | if ($c | has("tool_output")) or $o == null then {} else {tool_output: $o} end)
            + (if ($e.event.action | str) == "tool.failed" then {failed: true}
               elif ($c | has("failed")) then {}
               elif (["tool.completed", "command.executed", "file.modified", "file.read", "mcp.tool_invoked"] | index($e.event.action | str)) != null then {failed: false}
               else {} end) )
        | if (.[$id].tool_name // "") == "apply_patch" and (.[$id] | has("tool_input")) then
            .[$id].apply_patch_paths = ((.[$id].tool_input) as $i | (if ($i | type) == "object" then ($i.input // $i.patch) else $i end) | patchpaths)
          else . end
        | if (.[$id].tool_name // "") == "write_stdin" and ((.[$id].tool_input | type) == "object") and (.[$id].tool_input | has("chars")) then
            .[$id].typed_chars = .[$id].tool_input.chars
          else . end) ) as $B

  | ( if $host == "codex" then
        [ ["session_id", "session_meta.payload.id", "session.id"],
          ["working_directory", "turn_context.payload.cwd", "session.working_directory"],
          ["tool_name", "function_call.name", "tool.name"],
          ["tool_input", "function_call.arguments", "gen_ai.tool.call.arguments"],
          ["apply_patch_paths", "apply_patch input, File and Move lines", "the same lines in Beacon input"],
          ["typed_chars", "write_stdin arguments.chars", "gen_ai.tool.call.arguments.chars"],
          ["tool_output", "function_call_output.output", "command.output or gen_ai.tool.call.result"],
          ["exit_code", "event_msg exec_command_end.exit_code", "command.exit_code"] ]
      else
        [ ["session_id", "session file name", "session.id"],
          ["working_directory", "record cwd", "session.working_directory"],
          ["tool_name", "tool_use.name", "tool.name"],
          ["tool_input", "tool_use.input", "gen_ai.tool.call.arguments"],
          ["failed", "tool_result.is_error", "event.action tool.failed"] ]
      end ) as $fields
  | ($R | keys | sort) as $ids
  | [ $fields[] as [$f, $rs, $bs]
      | [ $ids[] as $id | select($R[$id] | has($f)) | $id ] as $have
      | [ $have[] as $id | select(($B[$id] // {}) | has($f)) | $id ] as $held
      | [ $held[] as $id | select($B[$id][$f] == $R[$id][$f]) | $id ] as $eq
      | ($have | length) as $rn | ($held | length) as $bn
      | { row: "field\t\($f)\t\($rs)\t\($bs)\t\($rn)\t\($bn)\t\($eq | length)\t\(
            if $rn == 0 then "absent_in_raw" elif $bn == 0 then "absent_in_beacon"
            elif ($eq | length) == $rn then "match" else "differs" end)",
          mism: [ $have[] as $id | select(($eq | index([$id])) == null)
                  | "mismatch\t\($f)\t\($id)\t\($R[$id][$f] | tojson)\t\(($B[$id] // {}) | if has($f) then .[$f] | tojson else "absent" end)" ] } ] as $out
  | ($out[] | .row), ($out[] | .mism[])
' 2>&1)"; rc=$?
[ "$rc" -eq 0 ] || _refuse parity_parser_failed "$jq exited $rc: $(printf '%s' "$out" | head -1)"
printf '%s\n' "$out"
exit 0
