#!/usr/bin/env bash
# The four pass conditions for Beacon as the Codex and Droid transcript reader, on the founder's
# Mac, against the 2026-10-02 Codex hooks rig. Nothing here runs in a cloud session: it needs real
# Codex, the rig's mock Responses server and refusing proxy, and Felix's plugin, all of which live
# only on that machine.
#
#   mac-run.sh <audit-dir>
#
# <audit-dir> is the archived 10-02 audit, `audits/2026-10-02-codex-hooks` in the memory root. It
# is copied whole into one scratch directory, printed first, and run from the copy, because the
# rig writes runs/<name>/ next to rig/. Everything else the run writes is under that scratch
# directory too: a scratch HOME, a CODEX_HOME seeded fresh the 10-02 way, the Beacon checkout and
# build, the logs and the verdicts. It never reads or writes the real ~/.codex (it holds the
# founder's login and a real provider), never starts a daemon or a launchd job, never signs in,
# and never runs Beacon's interactive setup, so Beacon Cloud is never offered.
#
# What it takes from the rig, as the founder's Mac session read it on 2026-10-29 (PR 473 review):
#   rig/run.sh <name> <codex_home> <home> <cwd> <plan.json> <prompt>   one Codex session against
#     its own mock.py, reading the proxy port from <audit>/log/refuser.port;
#   rig/refuser.py <portfile> <logfile>   the refusing proxy, on a random port it writes out;
#   rig/cx.sh   runs Codex under env -i with proxy variables from PROXY_PORT; its hardcoded Codex
#     path is patched in the copy to CODEX_BIN;
#   rig/plan-M4.json   exec_command with tty, then write_stdin, then a check call; its chars are
#     swapped for a `git commit --no-verify` in the copy;
#   rig/base.toml   the seed's config.toml;
#   rig/hookslist.py <codex_home> <home> <cwd> <out.json>   lists the hooks Codex loads, through
#     `codex app-server`, one line each, with the trust Codex gives each one;
#   rig/fixture.sh <home> <checkout>   makes a Felix test checkout, leaving a seed repo at
#     <checkout's parent>/seed-<name> and a bare remote at <audit>/remotes/<name>; a second call
#     for the same name fails on those, so the run deletes both before each call;
#   rig/mock.py   plays its plan only when the request carries the plan's marker, PROBEMARK, and
#     otherwise ends the session on its first reply with no tool call.
#
# The founder's run of 2026-10-29 (run-2026-10-29.md) set the fill-ins below to the values given
# under each one; the wrappers and plan-stop.json it used are kept outside felix-home, in the
# audit record of that run.
#
# Required:
#   FELIX_MARKETPLACE   a directory holding .claude-plugin/marketplace.json (the repo's, source
#                       ./engine) and engine/, a copy of the deployed plugin cache version. Not the
#                       Felix checkout, which would copy every worktree. Copied again, then `codex
#                       plugin marketplace add` and `codex plugin add felix@felix` install it into
#                       the scratch CODEX_HOME.
#   SEED_TRUST_CMD      the command that prints Felix's [hooks.state."felix@felix:..."] trust
#                       tables for the scratch CODEX_HOME, run with CODEX_HOME, HOME and CODEX_BIN
#                       exported; its output is appended to config.toml. 10-29: runs python3
#                       <scratch>/audit/rig/hookslist.py "$CODEX_HOME" "$HOME" "$HOME" <out.json>,
#                       then for each output line whose third field is felix@felix prints
#                       [hooks.state."<first field>"] and trusted_hash = "<hash>", where <hash>
#                       is the last field up to its first "/". From codex 0.165 the listed
#                       currentHash reads sha256:<hook>/sha256:<plugin>, and Codex trusts only
#                       the <hook> half; the joined string reads modified, which turns every
#                       Felix hook off. An older single hash has no "/" and stays as it is. The
#                       run refuses unless config.toml then holds a felix@felix trusted_hash, and
#                       unless rig/hookslist.py then lists every one of those hooks as trusted.
#   RIG_STOP_PLAN       the plan file, under rig/, whose turn Felix's Stop hold continues. 10-29:
#                       plan-stop.json, one apply_patch that adds notes.txt so the tree is dirty.
#                       It is not in the 10-02 archive; add it to a copy of the audit, not the
#                       archive, and pass that copy.
#   BEACON_OTELCOL      a beacon-otelcol built from the pinned commit; `beacon endpoint install`
#                       refuses without one. Build it once, outside the run:
#                         GOBIN=<dir> go install go.opentelemetry.io/collector/cmd/builder@v0.121.0
#                         cd <beacon>/collector-builder && mkdir -p dist
#                         GOOS=darwin GOARCH=arm64 CGO_ENABLED=0 <dir>/builder --config builder.yaml
# Optional:
#   RIG_DENY_PLAN       the plan file, under rig/, whose Bash call one of Felix's deny rows
#                       refuses; default plan-deny1.json.
#   CODEX_BIN           default /Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex
#   RIG_PROMPT          the user prompt each session opens with; default "PROBEMARK go". It must
#                       carry PROBEMARK, or the mock plays nothing (see rig/mock.py above).
#   RIG_FIXTURE         a command that makes a Felix test checkout at the one directory it is
#                       given. Default: rig/fixture.sh "$HOME" <dir>, after deleting what an
#                       earlier call for the same name left; without rig/fixture.sh, a plain git
#                       repo with one empty commit.
#   TMO                 exported to the rig as is; default 240, the headroom the 10-29 run used
#                       under load.
#   DROID_RUN           a command that plays one scripted Droid session in the scratch HOME.
#                       Without it every Droid row reads not_run. Droid needs a sign-in and a
#                       model, so whether to spend that is the founder's call.
#   EGRESS_TCPDUMP_IF   an interface name (en0). With it, sudo tcpdump records every packet not to
#                       or from loopback for the measured part of the run.
#
# Order: build Beacon first, with the network as it is; then seed; then start the refusing proxy,
# the egress logs and the proxy exports, so the build's own traffic never reaches them.
#
# A run cannot pass on nothing. The run refuses (mac_baseline_ungoverned) unless the before runs
# were governed by Felix: the deny rollout holds Codex's PreToolUse block, the stop and stdin
# rollouts hold a hook_prompt, and the stdin fixture holds the spike commit. It refuses
# (mac_install_failed) when `beacon endpoint install` fails, since every after row would then
# measure Felix alone. The live OTLP row reads not_run unless a collector process ran during the
# after runs; `--no-start` starts none, so today it always does.
#
# Result: <scratch>/results.tsv, one row per check:
#   condition <TAB> check <TAB> verdict <TAB> detail
# verdict is pass, fail, not_run, info or look (a person reads the named file). exit 0 when the
# run finished, whatever the verdicts; exit 2 with one refuse row on stderr when it could not start
# or could not measure anything, results.tsv then holding the rows written before the refusal.
set -uo pipefail

BEACON_REPO=https://github.com/Asymptote-Labs/agent-beacon
BEACON_TAG=v1.3.47
BEACON_COMMIT=90b19ae0626fd6fd060c62ddbc70827a23242f4e   # the tag's commit; the spike read 7b23b15, 9 commits later, with no change to the Codex, Factory, converter or hook code
CX_OLD_PATH=/Applications/ChatGPT.app/Contents/Resources/codex   # what rig/cx.sh hardcodes; gone since 10-02
STDIN_CHARS='git commit --allow-empty --no-verify -m spike
'

HERE="$(cd "$(dirname "$0")" && pwd)"
_refuse() { printf 'refuse\t%s\t%s\n' "$1" "$2" >&2; exit 2; }

[ "$#" -eq 1 ] || _refuse mac_usage "usage: mac-run.sh <audit-dir>"
AUDIT_SRC="$1"
[ "$(uname -s)" = Darwin ] || _refuse mac_not_darwin "this script measures the founder's Mac; uname says $(uname -s)"
for f in rig/run.sh rig/cx.sh rig/refuser.py rig/plan-M4.json rig/base.toml rig/hookslist.py; do
  [ -f "$AUDIT_SRC/$f" ] || _refuse mac_rig_missing "no $f under $AUDIT_SRC"
done
for v in FELIX_MARKETPLACE SEED_TRUST_CMD RIG_STOP_PLAN BEACON_OTELCOL; do
  [ -n "${!v:-}" ] || _refuse mac_env_missing "$v is not set; see the header of mac-run.sh"
done
RIG_DENY_PLAN="${RIG_DENY_PLAN:-plan-deny1.json}"
[ -x "$BEACON_OTELCOL" ] || _refuse mac_otelcol_missing "no executable beacon-otelcol at $BEACON_OTELCOL; the header says how to build it"
for p in "$RIG_DENY_PLAN" "$RIG_STOP_PLAN"; do
  [ -f "$AUDIT_SRC/rig/$p" ] || _refuse mac_rig_missing "no plan rig/$p under $AUDIT_SRC"
done
[ -d "$FELIX_MARKETPLACE" ] || _refuse mac_seed_invalid "no directory at FELIX_MARKETPLACE ($FELIX_MARKETPLACE)"
CODEX_BIN="${CODEX_BIN:-/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex}"
[ -x "$CODEX_BIN" ] || _refuse mac_codex_missing "no executable Codex at $CODEX_BIN"
RIG_PROMPT="${RIG_PROMPT:-PROBEMARK go}"
case "$RIG_PROMPT" in *PROBEMARK*) ;; *) _refuse mac_prompt_unmarked "RIG_PROMPT carries no PROBEMARK, so the mock would play no plan" ;; esac
export TMO="${TMO:-240}"
for c in git go jq lsof shasum make python3; do
  command -v "$c" >/dev/null 2>&1 || _refuse mac_tool_missing "$c is not on PATH"
done

S="$(mktemp -d "${TMPDIR:-/tmp}/beacon-spike.XXXXXX")" || _refuse mac_scratch_failed "mktemp failed"
printf 'scratch: %s\n' "$S"
RES="$S/results.tsv"; : > "$RES"
row() { printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" >> "$RES"; printf '%-4s %-36s %-8s %s\n' "$1" "$2" "$3" "$4"; }

# ---- 1. Build Beacon at the pinned commit, before any proxy or egress log exists. The pin is checked, not trusted.
git clone --quiet --no-checkout "$BEACON_REPO" "$S/src" || _refuse mac_clone_failed "git clone $BEACON_REPO failed"
git -C "$S/src" checkout --quiet "$BEACON_COMMIT" || _refuse mac_pin_missing "commit $BEACON_COMMIT is not in $BEACON_REPO"
[ "$(git -C "$S/src" rev-parse "$BEACON_TAG^{commit}")" = "$BEACON_COMMIT" ] \
  || _refuse mac_pin_moved "tag $BEACON_TAG no longer names $BEACON_COMMIT; read what moved before trusting it"
( cd "$S/src/cli/beacon" && make build ) > "$S/build.log" 2>&1 || _refuse mac_build_failed "make build failed; see $S/build.log"
BEACON="$S/src/cli/beacon/beacon"
[ -x "$BEACON" ] || _refuse mac_build_failed "no binary at $BEACON after make build"

# ---- 2. The rig, copied and patched: the current Codex path, and a write_stdin that commits.
AUD="$S/audit"
cp -Rp "$AUDIT_SRC" "$AUD"
mkdir -p "$AUD/log"; rm -f "$AUD/log/refuser.port"
sed -i '' "s#${CX_OLD_PATH}\([^-]\)#${CODEX_BIN}\1#g; s#${CX_OLD_PATH}\$#${CODEX_BIN}#" "$AUD/rig/cx.sh"
grep -q "$CODEX_BIN" "$AUD/rig/cx.sh" && ! grep -qE "${CX_OLD_PATH}([^-]|\$)" "$AUD/rig/cx.sh" \
  || _refuse mac_codex_missing "rig/cx.sh still names $CX_OLD_PATH after patching; see $AUD/rig/cx.sh"
# chars may sit in an object or inside a JSON string of tool arguments; swap it in both. The
# arguments may hold the mock's {{SID}} placeholder unquoted, which is not JSON, so it stands in as
# a number for the parse and goes back after.
jq --arg c "$STDIN_CHARS" '
  def swap: if type == "object" and has("chars") then (.chars = $c | tojson) else null end;
  walk(
    if type == "object" and has("chars") then .chars = $c
    elif type == "string" then
      (. as $s
       | (try (fromjson | swap) catch null) as $a
       | if $a != null then $a
         else (try ($s | gsub("\\{\\{SID\\}\\}"; "987654321987") | fromjson | swap | gsub("987654321987"; "{{SID}}")) catch null) // $s
         end)
    else . end)' "$AUD/rig/plan-M4.json" > "$AUD/rig/plan-stdin.json" \
  && grep -q -- '--no-verify' "$AUD/rig/plan-stdin.json" \
  || _refuse mac_plan_unpatched "plan-M4.json holds no write_stdin chars to swap; see $AUD/rig/plan-stdin.json"
CODEX_VERSION="$("$CODEX_BIN" --version 2>&1 | head -1)"
row 0 "codex version" info "$CODEX_VERSION (10-02 measured 0.153.4)"

# ---- 3. A fresh seed CODEX_HOME, the 10-02 way. Never the real ~/.codex.
export HOME="$S/home" CODEX_HOME="$S/codex-home" CODEX_BIN
mkdir -p "$HOME" "$CODEX_HOME" "$S/before" "$S/after" "$S/parity" "$S/work"
cp "$AUD/rig/base.toml" "$CODEX_HOME/config.toml"
cp -Rp "$FELIX_MARKETPLACE" "$S/marketplace"
{ "$CODEX_BIN" plugin marketplace add "$S/marketplace" && "$CODEX_BIN" plugin add felix@felix; } < /dev/null > "$S/seed.log" 2>&1 \
  || _refuse mac_seed_invalid "installing felix@felix failed; see $S/seed.log"
$SEED_TRUST_CMD < /dev/null >> "$CODEX_HOME/config.toml" 2>> "$S/seed.log" \
  || _refuse mac_seed_invalid "SEED_TRUST_CMD failed; see $S/seed.log"
PLUGIN_HOOKS="$(find "$CODEX_HOME/plugins/cache/felix/felix" -path '*/hooks/hooks.json' 2>/dev/null)"
[ "$(printf '%s' "$PLUGIN_HOOKS" | grep -c .)" = 1 ] \
  || _refuse mac_seed_invalid "expected one Felix plugin hooks.json under $CODEX_HOME/plugins/cache/felix/felix, found: ${PLUGIN_HOOKS:-none}"
# Felix's trust: each [hooks.state."felix@felix:..."] header with the trusted_hash line under it.
felix_trust() { awk '/^\[/{h = ($0 ~ /^\[hooks\.state\."felix@felix:/) ? $0 : ""; next} h != "" && /^[[:space:]]*trusted_hash[[:space:]]*=/{print h "\t" $0}' "$1"; }
felix_trust "$CODEX_HOME/config.toml" > "$S/before/felix-trust.tsv"
[ -s "$S/before/felix-trust.tsv" ] || _refuse mac_seed_invalid "config.toml holds no felix@felix trusted_hash after SEED_TRUST_CMD"
# A trust line is not a trust: run 3's first attempt wrote a hash Codex reads as modified, and only
# the baseline gate caught it. Ask Codex, and require every Felix hook to read trusted.
# TODO(founder): the line shape is read from run 3's report, not from hookslist.py itself: fields
# split on blanks, the third is the plugin (felix@felix), and a trusted hook carries a field that
# is `trusted` or `trust=trusted`. If that is wrong, this refuses with the listing named.
python3 "$AUD/rig/hookslist.py" "$CODEX_HOME" "$HOME" "$HOME" "$S/seed-hooks.json" < /dev/null > "$S/seed-hooks.txt" 2>> "$S/seed.log" \
  || _refuse mac_seed_untrusted "rig/hookslist.py failed on the seed; see $S/seed.log"
n_trust="$(wc -l < "$S/before/felix-trust.tsv" | tr -d ' ')"
n_listed="$(awk '$3 == "felix@felix"' "$S/seed-hooks.txt" | grep -c .)"
n_trusted="$(awk '$3 == "felix@felix" { for (i = 1; i <= NF; i++) if ($i == "trusted" || $i == "trust=trusted") { print; break } }' "$S/seed-hooks.txt" | grep -c .)"
[ "$n_listed" = "$n_trust" ] && [ "$n_trusted" = "$n_trust" ] \
  || _refuse mac_seed_untrusted "$n_trust felix@felix trust lines, but Codex lists $n_listed Felix hooks and trusts $n_trusted; see $S/seed-hooks.txt"
row 0 "felix plugin" info "$(basename "$(dirname "$(dirname "$PLUGIN_HOOKS")")"), $(wc -l < "$S/before/felix-trust.tsv" | tr -d ' ') trusted hooks"

# ---- 4. Egress, from here on: the rig's refusing proxy, an lsof poll, and optionally tcpdump.
python3 "$AUD/rig/refuser.py" "$AUD/log/refuser.port" "$S/egress-refuser.log" > "$S/refuser.out" 2>&1 &
REFUSER_PID=$!
for _ in $(seq 1 50); do [ -s "$AUD/log/refuser.port" ] && break; sleep 0.2; done
PROXY_PORT="$(tr -dc 0-9 < "$AUD/log/refuser.port" 2>/dev/null)"
[ -n "$PROXY_PORT" ] || _refuse mac_refuser_failed "refuser.py wrote no port to $AUD/log/refuser.port; see $S/refuser.out"
export PROXY_PORT
# cx.sh gives Codex its own proxy variables under env -i; these cover Beacon's own commands.
export HTTP_PROXY="http://127.0.0.1:$PROXY_PORT" HTTPS_PROXY="http://127.0.0.1:$PROXY_PORT" ALL_PROXY="http://127.0.0.1:$PROXY_PORT"
export http_proxy="$HTTP_PROXY" https_proxy="$HTTPS_PROXY" all_proxy="$ALL_PROXY" NO_PROXY=127.0.0.1,localhost no_proxy=127.0.0.1,localhost
# Only this run's sockets: any process named beacon*, wherever it sits, since Beacon may leave a
# process that outlives its parent; every other process only if it descends from this script. Run
# 3 counted other Claude Code sessions' node MCP servers when the poll took every node process.
( while :; do
    mine="$(ps -A -o pid= -o ppid= | awk -v root=$$ '
      { up[$1] = $2 }
      END { k[root] = 1
            do { grew = 0; for (p in up) if (!(p in k) && (up[p] in k)) { k[p] = 1; grew = 1 } } while (grew)
            for (p in k) printf " %s", p; print " " }')"
    lsof -nP -iTCP -iUDP 2>/dev/null | awk -v mine="$mine" 'NR > 1 && ($1 ~ /^beacon/ || index(mine, " " $2 " "))'
    sleep 0.2
  done ) > "$S/egress-lsof.raw" &
LSOF_PID=$!
TCPDUMP_PID=""
if [ -n "${EGRESS_TCPDUMP_IF:-}" ]; then
  sudo tcpdump -n -i "$EGRESS_TCPDUMP_IF" -w "$S/egress.pcap" 'not (host 127.0.0.1 or host ::1)' 2> "$S/egress-tcpdump.err" &
  TCPDUMP_PID=$!
fi
launchctl list 2>/dev/null | grep -i beacon > "$S/launchd-before.txt"
cleanup() {
  kill "$REFUSER_PID" "$LSOF_PID" 2>/dev/null
  [ -z "$TCPDUMP_PID" ] || sudo kill "$TCPDUMP_PID" 2>/dev/null
}
trap cleanup EXIT

# ---- One scripted Codex session in a fresh checkout at a fixed path, so before and after see the
#      same cwd. Prints the rollout it wrote, and only that one.
fixture() {   # dir
  rm -rf "$1"; mkdir -p "$1"
  if [ -n "${RIG_FIXTURE:-}" ]; then $RIG_FIXTURE "$1" > "$1.fixture.log" 2>&1
  elif [ -f "$AUD/rig/fixture.sh" ]; then
    rm -rf "$(dirname "$1")/seed-$(basename "$1")" "$AUD/remotes/$(basename "$1")"
    bash "$AUD/rig/fixture.sh" "$HOME" "$1" > "$1.fixture.log" 2>&1
  else git -C "$1" init -q && git -C "$1" -c user.name=spike -c user.email=spike@localhost commit -q --allow-empty -m base; fi
  git -C "$1" rev-parse HEAD > /dev/null 2>&1
}
run_codex() {   # phase scenario plan
  local mark="$S/$1/.mark-$2" cwd="$S/work/$2" r
  fixture "$cwd" || { printf 'none\n'; return 1; }
  touch "$mark"; sleep 1
  ( cd "$AUD/rig" && bash ./run.sh "$1-$2" "$CODEX_HOME" "$HOME" "$cwd" "$AUD/rig/$3" "$RIG_PROMPT" ) > "$S/$1/$2.rig.out" 2>&1
  printf '%s\n' "$?" > "$S/$1/$2.rig.rc"
  git -C "$cwd" log --format=%s > "$S/$1/$2.git-log" 2>/dev/null
  r="$(find "$CODEX_HOME/sessions" -name 'rollout-*.jsonl' -newer "$mark" 2>/dev/null)"
  [ "$(printf '%s' "$r" | grep -c .)" = 1 ] || { printf 'none\n'; return 1; }
  cp "$r" "$S/$1/$2.rollout.jsonl"; printf '%s\n' "$S/$1/$2.rollout.jsonl"
}
# What the agent did: each call, each output and each user or assistant message, in order, without
# ids or clocks. Developer messages carry Felix's session-start text, which can change from run to
# run, so they are compared apart (dev) and never decide a behaviour row. Values that change on
# every run are normalised: the wall time, Felix's hook_run_id index (Beacon's Stop hook ahead of
# Felix's moves stop:7 to stop:9), Codex's chunk and shell session ids, and short commit hashes.
shape() {   # rollout [dev]
  jq -c --arg dev "${2:-}" '
    def norm: tostring
      | gsub("(?m)^Wall time:[^\n]*"; "")
      | gsub("hook_run_id=\"(?<e>[A-Za-z_]+):[0-9]+"; "hook_run_id=\"\(.e)")
      | gsub("Chunk ID: [^\n]*"; "Chunk ID: <id>")
      | gsub("session ID [0-9]+"; "session ID <n>")
      | gsub("\"session_id\": *[0-9]+"; "\"session_id\":<n>")
      | gsub("\\[main (?<r>\\(root-commit\\) )?[0-9a-f]{7,40}\\]"; "[main \(.r // "")<hash>]");
    select(.type == "response_item") | .payload
    | if $dev != "" then (if .type == "message" and .role == "developer" then ([.content[]? | .text? // empty] | join("") | norm) else empty end)
      elif .type == "function_call" then ["call", .name, (.arguments | norm)]
      elif .type == "custom_tool_call" then ["call", .name, (.input | norm)]
      elif .type == "function_call_output" or .type == "custom_tool_call_output"
        then ["out", (.output | norm)]
      elif .type == "message" and .role != "developer" then ["msg", .role, ([.content[]? | .text? // empty] | join("") | norm)]
      else empty end' "$1"
}
SCEN="deny:$RIG_DENY_PLAN stop:$RIG_STOP_PLAN stdin:plan-stdin.json"

# ---- 5. Condition 1, before: Felix's hooks alone.
cp "$CODEX_HOME/config.toml" "$S/before/config.toml"; cp "$CODEX_HOME/hooks.json" "$S/before/user-hooks.json" 2>/dev/null
( cd "$CODEX_HOME/plugins/cache/felix" && find . -type f | LC_ALL=C sort | xargs shasum -a 256 ) > "$S/before/felix-plugin.sha256"
for s in $SCEN; do
  run_codex before "${s%%:*}" "${s#*:}" > /dev/null || row 1 "baseline ${s%%:*}" fail "no single new rollout; see $S/before/${s%%:*}.rig.out"
done
# The baseline must be governed, or every after row compares nothing with nothing.
governed() {   # scenario check: blocked, hold or commit
  case "$2" in
    blocked) grep -q 'Command blocked by PreToolUse hook' "$S/before/$1.rollout.jsonl" 2>/dev/null ;;
    hold)    grep -q 'hook_prompt' "$S/before/$1.rollout.jsonl" 2>/dev/null ;;
    commit)  grep -qx spike "$S/before/$1.git-log" 2>/dev/null ;;
  esac
}
for g in deny:blocked stop:hold stdin:hold stdin:commit; do
  if governed "${g%%:*}" "${g#*:}"; then
    row 1 "baseline governed: $g" pass "the before run shows it"
  else
    row 1 "baseline governed: $g" fail "the before run does not show it; see $S/before/${g%%:*}.*"
    _refuse mac_baseline_ungoverned "the before $g check failed, so Felix did not govern the baseline; see $RES"
  fi
done

# ---- 6. Install Beacon for Codex and Droid only: no service, no daemon start, no backfill, no TTY.
"$BEACON" endpoint install --dry-run --harness codex,factory --service none --no-start --no-backfill \
  --log-path "$S/runtime.jsonl" < /dev/null > "$S/install-dry-run.txt" 2>&1
"$BEACON" endpoint install --harness codex,factory --service none --no-start --no-backfill \
  --log-path "$S/runtime.jsonl" --collector "$BEACON_OTELCOL" < /dev/null > "$S/install.txt" 2>&1; irc=$?
if [ "$irc" = 0 ]; then
  row 1 "beacon install" pass "see $S/install.txt"
else
  row 1 "beacon install" fail "exit $irc; see $S/install.txt"
  _refuse mac_install_failed "beacon endpoint install exited $irc, so the after runs would measure Felix alone; see $S/install.txt"
fi
grep -q 'log_user_prompt *= *true' "$CODEX_HOME/config.toml" \
  && row 2 "prompt logging" info "Beacon's [otel] edit sets log_user_prompt = true, which turns on Codex's logging of user prompts"
cp "$CODEX_HOME/config.toml" "$S/after/config.toml"; cp "$CODEX_HOME/hooks.json" "$S/after/user-hooks.json" 2>/dev/null
diff "$S/before/config.toml" "$S/after/config.toml" > "$S/config.toml.diff" 2>&1
row 1 "config.toml edited" info "$(grep -c '^[<>]' "$S/config.toml.diff") lines changed; see $S/config.toml.diff"

# The static decision for condition 1: Codex trusts Felix's plugin hooks by the hash in config.toml,
# so every felix@felix trust table and its trusted_hash must come through byte for byte, and the
# plugin's own files must be untouched.
felix_trust "$CODEX_HOME/config.toml" > "$S/after/felix-trust.tsv"
if cmp -s "$S/before/felix-trust.tsv" "$S/after/felix-trust.tsv"; then
  row 1 "felix trusted hashes" pass "$(wc -l < "$S/after/felix-trust.tsv" | tr -d ' ') felix@felix trusted_hash lines byte for byte after the install"
else
  row 1 "felix trusted hashes" fail "changed; diff $S/before/felix-trust.tsv $S/after/felix-trust.tsv"
fi
( cd "$CODEX_HOME/plugins/cache/felix" && find . -type f | LC_ALL=C sort | xargs shasum -a 256 ) > "$S/after/felix-plugin.sha256"
cmp -s "$S/before/felix-plugin.sha256" "$S/after/felix-plugin.sha256" \
  && row 1 "felix plugin files" pass "hooks.json and every other plugin file unchanged" \
  || row 1 "felix plugin files" fail "changed; diff $S/before/felix-plugin.sha256 $S/after/felix-plugin.sha256"
row 1 "user hooks.json" info "Beacon writes its own SessionStart and Stop here; Felix has no entry in this file"

# ---- 7. Condition 1, after: the same scenarios must play out the same way.
OTEL_RAN=""
for s in $SCEN; do
  sc="${s%%:*}"
  ok_run=0; run_codex after "$sc" "${s#*:}" > /dev/null && ok_run=1
  pgrep -f beacon-otelcol > /dev/null 2>&1 && OTEL_RAN=1
  if [ "$ok_run" = 1 ] && [ -f "$S/before/$sc.rollout.jsonl" ]; then
    if diff <(shape "$S/before/$sc.rollout.jsonl") <(shape "$S/after/$sc.rollout.jsonl") > "$S/after/$sc.shape.diff"; then
      row 1 "same behaviour: $sc" pass "calls, outputs and user or assistant messages identical to the baseline"
    else
      row 1 "same behaviour: $sc" fail "read $S/after/$sc.shape.diff before counting it"
    fi
    diff <(shape "$S/before/$sc.rollout.jsonl" dev) <(shape "$S/after/$sc.rollout.jsonl" dev) > "$S/after/$sc.session-start.diff" \
      && row 1 "session-start text: $sc" pass "identical" \
      || row 1 "session-start text: $sc" look "$S/after/$sc.session-start.diff (dates and counts may change from run to run)"
  else
    row 1 "same behaviour: $sc" fail "no rollout to compare; see $S/after/$sc.rig.out"
  fi
done
[ "$(cat "$S/before/deny.rig.rc" 2>/dev/null)" = "$(cat "$S/after/deny.rig.rc" 2>/dev/null)" ] \
  && row 1 "deny scenario exit" pass "rig exit $(cat "$S/after/deny.rig.rc") before and after" \
  || row 1 "deny scenario exit" fail "rig exit changed; see $S/before and $S/after"
grep -qx spike "$S/after/stdin.git-log" 2>/dev/null \
  && row 4 "typed commit landed" info "the write_stdin commit with --no-verify went through, as on 10-02" \
  || row 4 "typed commit landed" info "no spike commit in the fixture; see $S/after/stdin.rig.out"

# ---- 8. Conditions 3 and 4, the offline reader: Beacon's record of each after run.
"$BEACON" endpoint codex sync --print < /dev/null > "$S/codex-sync.jsonl" 2> "$S/codex-sync.err"
for s in $SCEN; do
  sc="${s%%:*}"; ro="$S/after/$sc.rollout.jsonl"; [ -f "$ro" ] || continue
  sid="$(jq -r 'select(.type == "session_meta") | .payload.id // .payload.session_id' "$ro" | head -1)"
  jq -c --arg s "$sid" 'select(.session.id == $s)' "$S/codex-sync.jsonl" > "$S/parity/$sc.beacon.jsonl"
  "$HERE/parity.sh" codex "$ro" "$S/parity/$sc.beacon.jsonl" > "$S/parity/$sc.tsv" 2>&1
  if grep -qE '^field	.*	(differs|absent_in_beacon)$' "$S/parity/$sc.tsv"; then
    row 3 "parity: $sc" fail "$(grep -cE '^field	.*	(differs|absent_in_beacon)$' "$S/parity/$sc.tsv") fields short; see $S/parity/$sc.tsv"
  else
    row 3 "parity: $sc" pass "every field the rollout holds, Beacon holds alike; see $S/parity/$sc.tsv"
  fi
  "$HERE/beacon-intake.sh" "$S/parity/$sc.beacon.jsonl" > "$S/parity/$sc.intake.tsv" 2>&1
done
st="$S/parity/stdin.intake.tsv"
if grep -q '^typed	.*--no-verify' "$st" 2>/dev/null; then
  row 4 "write_stdin, offline reader" pass "$(grep '^typed	' "$st" | grep -- '--no-verify' | head -1 | cut -f5)"
else
  row 4 "write_stdin, offline reader" fail "no typed row carrying --no-verify; see $st"
fi
if [ -n "$OTEL_RAN" ] && [ -s "$S/runtime.jsonl" ]; then
  "$HERE/beacon-intake.sh" "$S/runtime.jsonl" > "$S/runtime.intake.tsv" 2>&1
  grep -q '^typed	.*--no-verify' "$S/runtime.intake.tsv" \
    && row 4 "write_stdin, live OTLP" pass "$(grep '^typed	' "$S/runtime.intake.tsv" | grep -- '--no-verify' | head -1 | cut -f5)" \
    || row 4 "write_stdin, live OTLP" fail "no typed row carrying --no-verify; see $S/runtime.intake.tsv"
else
  row 4 "write_stdin, live OTLP" not_run "no beacon-otelcol ran during the after runs (--no-start starts none), or it wrote nothing"
fi

# ---- 9. Droid, only when the founder chose to spend a session on it.
if [ -n "${DROID_RUN:-}" ]; then
  mark="$S/.mark-droid"; touch "$mark"; sleep 1
  $DROID_RUN > "$S/droid.out" 2>&1
  fs="$(find "$HOME/.factory/sessions" -name '*.jsonl' -newer "$mark" 2>/dev/null | head -1)"
  "$BEACON" endpoint factory sync --print < /dev/null > "$S/factory-sync.jsonl" 2> "$S/factory-sync.err"
  if [ -n "$fs" ]; then
    "$HERE/parity.sh" factory "$fs" "$S/factory-sync.jsonl" > "$S/parity/droid.tsv" 2>&1
    grep -qE '^field	.*	(differs|absent_in_beacon)$' "$S/parity/droid.tsv" \
      && row 3 "parity: droid" fail "see $S/parity/droid.tsv" || row 3 "parity: droid" pass "see $S/parity/droid.tsv"
  else
    row 3 "parity: droid" fail "no new Factory session; see $S/droid.out"
  fi
else
  row 3 "parity: droid" not_run "DROID_RUN not set"
fi
row 1 "felix hooks fire in droid" not_run "the Droid adapter is not built, so Felix has no Droid hooks to keep"

# ---- 10. Condition 2: nothing left the machine, and nothing outlives the run.
sleep 1; cleanup; trap - EXIT
awk '$0 !~ /127\.0\.0\.1|\[::1\]|localhost|\*:/' "$S/egress-lsof.raw" \
  | sort -u > "$S/egress-lsof.txt"
[ -s "$S/egress-lsof.txt" ] && row 2 "lsof poll" fail "$(wc -l < "$S/egress-lsof.txt" | tr -d ' ') remote sockets; see $S/egress-lsof.txt" \
  || row 2 "lsof poll" pass "no socket of this run to a non loopback address (a poll every 0.2s can miss a short one)"
[ -s "$S/egress-refuser.log" ] && row 2 "refusing proxy" look "$S/egress-refuser.log is not empty" \
  || row 2 "refusing proxy" pass "the proxy on port $PROXY_PORT was asked for no connection"
[ -z "${EGRESS_TCPDUMP_IF:-}" ] && row 2 "tcpdump" not_run "EGRESS_TCPDUMP_IF not set" \
  || row 2 "tcpdump" look "$S/egress.pcap holds all non loopback traffic of the Mac during the measured run"
launchctl list 2>/dev/null | grep -i beacon > "$S/launchd-after.txt"
cmp -s "$S/launchd-before.txt" "$S/launchd-after.txt" && row 2 "launchd" pass "no Beacon job added" \
  || row 2 "launchd" fail "see $S/launchd-after.txt"
find "$HOME" -maxdepth 4 -path '*skills*' -newer "$S/before/config.toml" > "$S/skills-written.txt" 2>/dev/null
[ -s "$S/skills-written.txt" ] && row 2 "skills written" fail "see $S/skills-written.txt" || row 2 "skills written" pass "none under the scratch HOME"

printf '\nresults: %s\n' "$RES"
exit 0
