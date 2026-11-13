#!/usr/bin/env bash
# Beacon runtime JSONL in, Felix capability-ledger signals out. A spike, not engine code.
#
#   beacon-intake.sh <runtime.jsonl>
#
# What it answers: given the normalized event log Agent Beacon (MIT, Asymptote Labs) writes for
# Claude Code, Codex and Factory Droid, which rows would Felix's ledger hold for each session, in
# the shape felix_ledger_signal (engine/harness/lib/ledger.sh) writes from Claude Code's
# PostToolUse payload: `tool <name>`, `mcp <server>`, `skill <name>`, `agent <subagent_type>`.
#
# What it never answers: whether work is done. These rows are capability telemetry the agent's own
# process emitted. Felix's verdicts come from receipts bound to the tree and checks Felix runs
# itself; nothing here may reach a receipt, the gate or a merge blocker.
#
# stdout, one row per event, in (timestamp, sequence, line) order:
#   signal <TAB> harness <TAB> session <TAB> collection_method <TAB> kind <TAB> name
#   skip   <TAB> reason_code <TAB> line <TAB> event_id <TAB> reason_detail
# Every event the file holds yields exactly one signal or skip row, so signals plus skips equals the
# line count, and nothing is dropped without a reason_code. reason_code is canonical snake_case and
# stable; reason_detail is for people and may change.
#
# A counted Codex write_stdin call adds one more row right after its signal, because input typed
# into a shell that is already open reaches no Felix hook (roadmap §3 item 5), so this log is the
# only place Felix could see it:
#   typed         <TAB> harness <TAB> session <TAB> call_id <TAB> chars as a JSON string
#   typed_unknown <TAB> reason_code <TAB> line <TAB> event_id <TAB> reason_detail
# chars "" (a read of the shell's output, nothing typed) adds no row. typed rows are detection
# input for a person or a later check; they never deny, and Beacon's redaction and size caps may
# have shortened the text.
#
# exit 0  the file was read to the end; every event is accounted for on stdout
# exit 2  cannot examine: nothing on stdout, one row on stderr:
#           refuse <TAB> reason_code <TAB> reason_detail
#         The whole file is refused, never a prefix of it: a partial read would let the events
#         it did not reach count as "not used", which is a claim about lines never seen.
#
# Dependencies: bash and jq (FELIX_JQ names the parser, as engine/harness/lib/status.sh does).
# jq is the named exception to resolve.sh's bash-and-git rule because this reads JSON documents
# a third party writes, which sed extraction would misread on the first nested object. It stays
# off the enforcing path (direction row 6): its absence refuses with beacon_jq_missing.
set -uo pipefail

_refuse() { printf 'refuse\t%s\t%s\n' "$1" "$2" >&2; exit 2; }

[ "$#" -eq 1 ] || _refuse beacon_usage "usage: beacon-intake.sh <runtime.jsonl>"
in="$1"
jq="${FELIX_JQ:-jq}"
command -v "$jq" >/dev/null 2>&1 || _refuse beacon_jq_missing "no JSON parser on this machine ($jq)"
# -f and -r as well as -s: `[ -s ]` is true of a directory and of a file this user cannot read.
[ -f "$in" ] && [ -r "$in" ] || _refuse beacon_input_unreadable "nothing readable at $in"
# An empty log cannot be told from capture that was never wired, so it is not "no tools used".
[ -s "$in" ] || _refuse beacon_input_empty "$in holds no events"

out="$(LC_ALL=C "$jq" -nr --raw-input '
  # The harnesses Felix governs or is adapting to (direction row 19). Names as Beacon writes them.
  def governed: ["claude_code", "codex_cli", "codex_desktop", "factory"];
  # Actions that close one tool call, the counterpart of PostToolUse. tool.invoked is the call
  # starting and would count it twice; tool.failed has its own reason, below.
  def terminal: ["command.executed", "file.read", "file.modified", "mcp.tool_invoked", "tool.completed"];
  def str: if type == "string" then . else "" end;
  # Beacon writes the arguments of a call as an object on the rollout path (poll) and as the raw JSON
  # string Codex exported on the OTLP path, where tool.command holds the same string.
  def argobj: if type == "object" then .
              elif type == "string" then (try fromjson catch null) | (if type == "object" then . else null end)
              else null end;
  # The OTLP converter of Beacon maps codex.tool_result, the one record Codex exports per finished call,
  # to tool.invoked for every tool but its shell tools (NormalizeCodexToolResult). On that path
  # tool.invoked closes the call; on the rollout path it opens one and a result event follows.
  def closes($action; $h; $m):
    (terminal | index($action)) != null
    or ($action == "tool.invoked" and $m == "otlp" and (["codex_cli", "codex_desktop"] | index($h)) != null);
  def unsafe: test("[\t\n\r]");

  [inputs] as $raw
  | [ $raw | to_entries[]
      | { ln: (.key + 1),
          parsed: (.value as $v | try ($v | fromjson | {ok: true, e: .}) catch {ok: false}) } ] as $rows

  # Refusals first, over every line, so the file is refused whole or read whole.
  | ( [ $rows[] | select(.parsed.ok | not) | .ln ] ) as $badjson
  | if ($badjson | length) > 0 then
      "refuse\tbeacon_line_not_json\tline \($badjson[0]) is not one JSON document"
    else
      ( [ $rows[] | select(.parsed.e | type != "object") | .ln ] ) as $notobj
      | ( [ $rows[] | select((.parsed.e | type == "object") and (.parsed.e.vendor != "beacon")) | .ln ] ) as $vendor
      | ( [ $rows[] | select((.parsed.e | type == "object") and (.parsed.e.schema_version != "1.0"))
            | "\(.ln) (\(.parsed.e.schema_version | tojson))" ] ) as $schema
      | if ($notobj | length) > 0 then "refuse\tbeacon_line_not_object\tline \($notobj[0]) is not a JSON object"
        elif ($vendor | length) > 0 then "refuse\tbeacon_vendor_mismatch\tline \($vendor[0]) does not say vendor beacon"
        elif ($schema | length) > 0 then "refuse\tbeacon_schema_version_unsupported\tline \($schema[0]): only schema_version 1.0 is read"
        else
          # Arguments travel on the invoked event and may be absent on the completed one, so a
          # Skill or Agent call is named from whichever event of the same call carries them.
          ( reduce ($rows[] | .parsed.e
                    | select(type == "object" and (.gen_ai.tool.call.id | str) != "" and (.gen_ai.tool.call.arguments | argobj) != null))
              as $e ({}; .[($e.harness.name | str) + "\u0000" + ($e.session.id | str) + "\u0000" + $e.gen_ai.tool.call.id]
                         //= ($e.gen_ai.tool.call.arguments | argobj)) ) as $args
          | [ $rows[] | {ln, e: .parsed.e} ]
          | sort_by([(.e.timestamp | str), (.e.sequence // 0), .ln])
          | reduce .[] as $r ({seen: {}, rows: []};
              ($r.e) as $e
              | ($e.event.action | str) as $action
              | ($e.event.id | str) as $eid
              | ($e.harness.name | str) as $h
              | ($e.session.id | str) as $s
              | ($e.tool.name // $e.gen_ai.tool.name | str) as $tool
              | ($e.mcp.server | str) as $mcp
              | ($e.gen_ai.tool.call.id | str) as $cid
              | (if $cid != "" then "call\u0000" + $h + "\u0000" + $s + "\u0000" + $cid
                 elif $eid != "" then "event\u0000" + $eid else "" end) as $key
              | def skip($code; $detail): .rows += ["skip\t\($code)\t\($r.ln)\t\(if $eid == "" then "-" else $eid end)\t\($detail)"];
              if ($action == "tool.failed") then skip("beacon_tool_failed"; "a failed call; PostToolUse records completed calls only")
              elif (closes($action; $h; ($e.harness.collection_method | str)) | not) then skip("beacon_action_not_counted"; "action \($action | tojson) does not close a tool call")
              elif $h == "" then skip("beacon_harness_missing"; "no harness.name")
              elif (governed | index($h)) == null then skip("beacon_harness_not_governed"; "harness \($h | tojson) is not one Felix governs")
              elif ($e.event.fidelity | str) == "" then skip("beacon_fidelity_absent"; "no event.fidelity, so Beacon does not say whether the source named this action")
              elif ($e.event.fidelity | str) != "observed" then skip("beacon_fidelity_inferred"; "event.fidelity \($e.event.fidelity | tojson): Beacon derived this action")
              elif $s == "" then skip("beacon_session_missing"; "no session.id, so no ledger file to hold it")
              elif $key == "" then skip("beacon_call_identity_missing"; "neither gen_ai.tool.call.id nor event.id, so a second report of this call could not be told apart")
              elif .seen[$key] then skip("beacon_duplicate_call"; "this call was already counted at line \(.seen[$key])")
              else
                ($args[$h + "\u0000" + $s + "\u0000" + $cid] // ($e.gen_ai.tool.call.arguments | argobj)
                  // ($e.tool.command | argobj) // {}) as $a
                # The same precedence felix_ledger_signal uses: MCP server, then Skill, then Agent, then the tool.
                | ( if $mcp != "" then ["mcp", $mcp]
                    elif ($tool | startswith("mcp__")) then ["mcp", ($tool | ltrimstr("mcp__") | split("__")[0])]
                    elif (["Skill", "skill"] | index($tool)) != null and ($a.skill | str) != "" then ["skill", $a.skill]
                    elif (["Agent", "agent", "Task", "task"] | index($tool)) != null and ($a.subagent_type | str) != "" then ["agent", $a.subagent_type]
                    elif $tool == "" or $tool == "unknown" then null
                    else ["tool", $tool] end ) as $sig
                | if $sig == null then skip("beacon_tool_name_missing"; "no tool name, and none is guessed from the action")
                  elif ([$h, $s, $sig[1]] | map(unsafe) | any) then skip("beacon_field_unsafe"; "a tab or line break in harness, session or name would break the ledger row")
                  else .seen[$key] = $r.ln
                       | .rows += ["signal\t\($h)\t\($s)\t\(($e.harness.collection_method | str) as $m | if $m == "" then "-" else $m end)\t\($sig[0])\t\($sig[1])"]
                       | if $sig == ["tool", "write_stdin"] and (["codex_cli", "codex_desktop"] | index($h)) != null then
                           if ($a | has("chars") | not) then
                             .rows += ["typed_unknown\tbeacon_typed_input_absent\t\($r.ln)\t\(if $eid == "" then "-" else $eid end)\tno chars in the arguments of this write_stdin call, so what was typed is unknown, not nothing"]
                           elif ($a.chars | type) != "string" then
                             .rows += ["typed_unknown\tbeacon_typed_input_not_text\t\($r.ln)\t\(if $eid == "" then "-" else $eid end)\tchars is \($a.chars | type), not text"]
                           elif $a.chars == "" then .
                           else .rows += ["typed\t\($h)\t\($s)\t\(if $cid == "" or ($cid | unsafe) then "-" else $cid end)\t\($a.chars | tojson)"]
                           end
                         else . end
                  end
              end)
          | .rows[]
        end
    end
' "$in" 2>&1)"; rc=$?

[ "$rc" -eq 0 ] || _refuse beacon_parser_failed "$jq exited $rc: $(printf '%s' "$out" | head -1)"
case "$out" in
  refuse$'\t'*) printf '%s\n' "$out" >&2; exit 2 ;;
esac
printf '%s\n' "$out"
exit 0
