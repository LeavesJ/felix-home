#!/usr/bin/env bash
# The spike's own checks. Run from anywhere: test.sh
# Exit 1 when any check failed, and every failure is named.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
RUN="$HERE/beacon-intake.sh"
FX="$HERE/fixtures"
TMP="$(mktemp -d)" || { printf 'test.sh: mktemp failed\n' >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok()  { PASS=$((PASS + 1)); printf 'ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$1"; }

# 1. The mixed fixture reads exactly as recorded.
if "$RUN" "$FX/mixed.jsonl" > "$TMP/out" 2> "$TMP/err" && cmp -s "$TMP/out" "$FX/mixed.expected" && [ ! -s "$TMP/err" ]; then
  ok "mixed.jsonl: exit 0, stdout byte for byte mixed.expected, nothing on stderr"
else
  bad "mixed.jsonl: differs from mixed.expected"; diff "$FX/mixed.expected" "$TMP/out" | head -20
fi

# 2. Every event is accounted for: one signal or skip row per line, nothing dropped. typed and
#    typed_unknown rows ride after a signal and are the only other kinds.
accounted() {   # fixture output
  local lines rows other
  lines="$(wc -l < "$1" | tr -d ' ')"; rows="$(cut -f1 "$2" | grep -cE '^(signal|skip)$')"
  other="$(cut -f1 "$2" | grep -cvE '^(signal|skip|typed|typed_unknown)$')"
  [ "$lines" = "$rows" ] && [ "$other" = 0 ] && ok "$(basename "$1"): $rows signal or skip rows for $lines lines, no other kind" \
    || bad "$(basename "$1"): $rows signal or skip rows for $lines lines, $other rows of an unknown kind"
}
accounted "$FX/mixed.jsonl" "$TMP/out"

# 3. Deterministic: a second run is the same bytes.
"$RUN" "$FX/mixed.jsonl" > "$TMP/out2" 2>/dev/null
cmp -s "$TMP/out" "$TMP/out2" && ok "mixed.jsonl: a second run prints the same bytes" || bad "mixed.jsonl: a second run differs"

# 4. Append order is not emission order (Beacon's own schema says so), so reversing the file
#    must not change which calls are counted or in what order.
awk '{a[NR] = $0} END {for (i = NR; i; i--) print a[i]}' "$FX/mixed.jsonl" > "$TMP/rev.jsonl"   # tac is not on macOS
"$RUN" "$TMP/rev.jsonl" > "$TMP/rev" 2>/dev/null
if diff <(grep '^signal' "$TMP/out") <(grep '^signal' "$TMP/rev") >/dev/null; then
  ok "mixed.jsonl reversed: the same signal rows in the same order"
else
  bad "mixed.jsonl reversed: signal rows changed"
fi

# 4b. Codex: on the OTLP path tool.invoked is the finished call (Beacon maps codex.tool_result to it),
#     on the rollout path it is the call opening. A counted write_stdin call says what was typed,
#     a duplicate says nothing twice, and chars that are missing or not text are named, not dropped.
if "$RUN" "$FX/codex.jsonl" > "$TMP/cx" 2> "$TMP/cxerr" && cmp -s "$TMP/cx" "$FX/codex.expected" && [ ! -s "$TMP/cxerr" ]; then
  ok "codex.jsonl: exit 0, stdout byte for byte codex.expected, nothing on stderr"
else
  bad "codex.jsonl: differs from codex.expected"; diff "$FX/codex.expected" "$TMP/cx" | head -20
fi
accounted "$FX/codex.jsonl" "$TMP/cx"
grep -q "^signal	codex_cli	cx-2	otlp	tool	view_image$" "$TMP/cx" && ok "codex.jsonl: an OTLP tool.invoked from Codex counts as the finished call" \
  || bad "codex.jsonl: the OTLP view_image call was not counted"
grep -q "^skip	beacon_action_not_counted	9	" "$TMP/cx" && ok "codex.jsonl: an OTLP tool.invoked from another harness still opens a call" \
  || bad "codex.jsonl: the factory OTLP tool.invoked was counted"
[ "$(grep -c '^typed	' "$TMP/cx")" = 2 ] && grep -q '"git commit --no-verify -m wip\\n"$' "$TMP/cx" \
  && ok "codex.jsonl: two typed rows, once per counted call, text JSON escaped" || bad "codex.jsonl: typed rows wrong"
for code in beacon_typed_input_absent beacon_typed_input_not_text; do
  grep -q "^typed_unknown	$code	" "$TMP/cx" && ok "codex.jsonl reaches $code" || bad "codex.jsonl never reaches $code"
done

# 5. Refusals: exit 2, nothing on stdout, one stderr row naming the reason_code.
refuses() {   # label code -- argv...
  local label="$1" code="$2"; shift 3
  local rc
  "$@" > "$TMP/r.out" 2> "$TMP/r.err"; rc=$?
  if [ "$rc" = 2 ] && [ ! -s "$TMP/r.out" ] && [ "$(wc -l < "$TMP/r.err" | tr -d ' ')" = 1 ] \
     && [ "$(cut -f1,2 "$TMP/r.err")" = "$(printf 'refuse\t%s' "$code")" ]; then
    ok "$label: refused as $code, exit 2, stdout empty"
  else
    bad "$label: expected refuse $code exit 2, got exit $rc: $(head -1 "$TMP/r.err")"
  fi
}
refuses "a line that is not JSON"       beacon_line_not_json              -- "$RUN" "$FX/not-json.jsonl"
refuses "a schema_version other than 1.0" beacon_schema_version_unsupported -- "$RUN" "$FX/schema-2.jsonl"
refuses "a vendor other than beacon"    beacon_vendor_mismatch            -- "$RUN" "$FX/vendor.jsonl"
refuses "a line that is an array"       beacon_line_not_object            -- "$RUN" "$FX/not-object.jsonl"
refuses "an empty log"                  beacon_input_empty                -- "$RUN" "$FX/empty.jsonl"
refuses "no file at the path"           beacon_input_unreadable           -- "$RUN" "$FX/does-not-exist.jsonl"
refuses "a directory"                   beacon_input_unreadable           -- "$RUN" "$FX"
refuses "no argument"                   beacon_usage                      -- "$RUN"
refuses "no jq on PATH"                 beacon_jq_missing                 -- env FELIX_JQ=/nonexistent/jq "$RUN" "$FX/mixed.jsonl"

# 6. The reason codes never drift: the set the script can print is the set the README's table
#    lists, and every one is snake_case.
in_code="$(grep -oE 'beacon_[a-z_]+' "$RUN" | LC_ALL=C sort -u)"
in_doc="$(grep -oE '^\| `beacon_[a-z_]+`' "$HERE/README.md" | grep -oE 'beacon_[a-z_]+' | LC_ALL=C sort -u)"
if [ -n "$in_code" ] && [ "$in_code" = "$in_doc" ]; then
  ok "reason codes: the script's $(printf '%s\n' "$in_code" | wc -l | tr -d ' ') codes are exactly the README's table"
else
  bad "reason codes drift between beacon-intake.sh and README.md"; diff <(printf '%s\n' "$in_code") <(printf '%s\n' "$in_doc")
fi
bad_case="$(printf '%s\n' "$in_code" | grep -vE '^[a-z]+(_[a-z]+)*$' || true)"
[ -z "$bad_case" ] && ok "reason codes: all snake_case" || bad "reason codes not snake_case: $bad_case"

# 7. Every skip code the fixture can reach is reached, so no branch of the classifier goes untested.
for code in beacon_action_not_counted beacon_tool_failed beacon_harness_missing beacon_harness_not_governed beacon_fidelity_absent \
            beacon_fidelity_inferred beacon_session_missing beacon_call_identity_missing beacon_duplicate_call \
            beacon_tool_name_missing beacon_field_unsafe; do
  grep -q "^skip	$code	" "$TMP/out" && ok "mixed.jsonl reaches $code" || bad "mixed.jsonl never reaches $code"
done

# 8. parity.sh: field by field, the raw host record against Beacon's record of the same calls.
PAR="$HERE/parity.sh"
for host in codex factory; do
  case "$host" in codex) rawf="$FX/parity-codex-rollout.jsonl" ;; factory) rawf="$FX/fd-9.jsonl" ;; esac
  if "$PAR" "$host" "$rawf" "$FX/parity-$host-beacon.jsonl" > "$TMP/par" 2> "$TMP/parerr" \
     && cmp -s "$TMP/par" "$FX/parity-$host.expected" && [ ! -s "$TMP/parerr" ]; then
    ok "parity $host: exit 0, stdout byte for byte parity-$host.expected"
  else
    bad "parity $host: differs from parity-$host.expected"; diff "$FX/parity-$host.expected" "$TMP/par" | head -20
  fi
done
grep -q "^field	exit_code	.*	absent_in_beacon$" "$FX/parity-codex.expected" && grep -q "^mismatch	tool_input	call_4	" "$FX/parity-codex.expected" \
  && ok "parity codex: a missing exit code and a redacted input are named, not passed" || bad "parity codex: a gap went unnamed"
refuses "parity with no arguments"     parity_usage            -- "$PAR"
refuses "parity for an unknown host"   parity_host_unknown     -- "$PAR" cursor "$FX/fd-9.jsonl" "$FX/fd-9.jsonl"
refuses "parity on a missing file"     parity_input_unreadable -- "$PAR" codex "$FX/nope.jsonl" "$FX/fd-9.jsonl"
refuses "parity on an empty file"      parity_input_empty      -- "$PAR" codex "$FX/empty.jsonl" "$FX/fd-9.jsonl"
refuses "parity on a line not JSON"    parity_line_not_json    -- "$PAR" codex "$FX/not-json.jsonl" "$FX/fd-9.jsonl"
refuses "parity with no jq"            parity_jq_missing       -- env FELIX_JQ=/nonexistent/jq "$PAR" codex "$FX/fd-9.jsonl" "$FX/fd-9.jsonl"
p_code="$(grep -oE 'parity_[a-z_]+' "$PAR" | LC_ALL=C sort -u)"
p_doc="$(grep -oE '^\| `parity_[a-z_]+`' "$HERE/README.md" | grep -oE 'parity_[a-z_]+' | LC_ALL=C sort -u)"
[ -n "$p_code" ] && [ "$p_code" = "$p_doc" ] && ok "parity reason codes: the script's codes are exactly the README's table" \
  || { bad "parity reason codes drift between parity.sh and README.md"; diff <(printf '%s\n' "$p_code") <(printf '%s\n' "$p_doc"); }

# 9. mac-run.sh parses, and refuses to start without the rig and the pin it names.
bash -n "$HERE/mac-run.sh" && ok "mac-run.sh parses" || bad "mac-run.sh does not parse"
refuses "mac-run with no rig"          mac_usage               -- "$HERE/mac-run.sh"
m_code="$(grep -oE 'mac_[a-z_]+' "$HERE/mac-run.sh" | LC_ALL=C sort -u)"
m_doc="$(grep -oE '^\| `mac_[a-z_]+`' "$HERE/README.md" | grep -oE 'mac_[a-z_]+' | LC_ALL=C sort -u)"
[ -n "$m_code" ] && [ "$m_code" = "$m_doc" ] && ok "mac-run reason codes: the script's codes are exactly the README's table" \
  || { bad "mac-run reason codes drift between mac-run.sh and README.md"; diff <(printf '%s\n' "$m_code") <(printf '%s\n' "$m_doc"); }

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
