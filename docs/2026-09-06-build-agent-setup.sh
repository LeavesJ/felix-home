#!/bin/bash
# Add J's Claude Code agent setup to an existing handover bundle.
#
#   ./2026-09-06-build-agent-setup.sh [bundle-dir]     default ~/handover
#
# Written 2026-09-06. The bundle builder walks the Elenchus checkout, so it sees
# .claude/ INSIDE the repo and nothing else. Most of what makes an agent setup
# an agent setup lives in ~/.claude/, outside every repository, and none of it
# was travelling.
#
# This carries the parts that are configuration and leaves the parts that are
# either a credential or a record of what the founder typed.
#
# NEVER TRAVELS:
#   ~/.claude/projects/        session transcripts. Every prompt ever typed, and
#                              on this machine 62 MB of it. Same class as the
#                              Felix memory root's says.log: verbatim founder
#                              prompts and whatever the work was about.
#   ~/.claude/history.jsonl    the prompt history, same reason.
#   ~/.claude/.credentials.json   OAuth tokens.
#   ~/.claude.json             mode 600. Holds oauthAccount, every MCP server's
#                              env block, and the full list of every directory
#                              ever opened. §MCP below extracts the shape of the
#                              server list from it WITHOUT any env value.
#   sessions/ session-env/ shell-snapshots/ backups/ statsig/ todos/ logs/
#                              machine state and caches. Riyan regenerates them.
#
# TRAVELS, because it is authored configuration:
#   agents/ commands/ skills/ plugins/ hooks/ output-styles/
#   CLAUDE.md settings.json keybindings.json and any hook scripts at the root
#
# Every refusal prints a stable snake_case reason_code and a free-form detail.

set -euo pipefail

die() { printf 'refused reason_code=%s reason_detail=%s\n' "$1" "$2" >&2; exit 1; }
note() { printf '  %s\n' "$1"; }
warn() { printf '  !! %s\n' "$1"; }

BUNDLE=${1:-$HOME/handover}
SRC="$HOME/.claude"
OUT="$BUNDLE/agent-setup"

[ -d "$BUNDLE" ] || die agent_no_bundle \
  "$BUNDLE does not exist. Build the bundle first, then run this."
[ -d "$BUNDLE/state" ] || die agent_not_a_bundle \
  "$BUNDLE has no state/ directory; that is not a handover bundle."
[ -d "$SRC" ] || die agent_no_claude_dir "$SRC does not exist."
[ ! -e "$OUT" ] || die agent_dest_exists \
  "$OUT already exists. Remove it and re-run rather than merging into it."

# Matched against the entry name directly under ~/.claude, or a path below it.
DENY='(^|/)(projects|history\.jsonl|\.credentials\.json|sessions|session-env|shell-snapshots|backups|statsig|todos|logs|downloads|ide|telemetry|usage|\.last-cleanup|launcher-settings\.json|remote-settings\.json|policy-limits\.json|\.DS_Store|node_modules|__pycache__|.*\.log)$'

printf 'agent setup from %s\n' "$SRC"
printf '  into %s\n\n' "$OUT"

mkdir -p "$OUT/claude-home"

skipped=""
n=0

for entry in "$SRC"/* "$SRC"/.[!.]*; do
  [ -e "$entry" ] || [ -L "$entry" ] || continue
  base=$(basename "$entry")

  if printf '%s' "$base" | grep -qE "$DENY"; then
    sz=$(du -sh "$entry" 2>/dev/null | awk '{print $1}')
    skipped="$skipped $base($sz)"
    continue
  fi

  # A symlink here would point somewhere on J's disk and mean nothing on
  # Riyan's. Recorded rather than copied, same rule as the main builder.
  if [ -L "$entry" ]; then
    printf '%s\t%s\n' ".claude/$base" "$(readlink "$entry")" >> "$OUT/symlinks.tsv"
    note "link recorded  $base"
    continue
  fi

  if [ -d "$entry" ]; then
    inner=$(find "$entry" -type l 2>/dev/null || true)
    [ -z "$inner" ] || warn "$base contains symlinks; they are copied as links and may dangle"
    cp -R "$entry" "$OUT/claude-home/"
    # Strip anything the deny list catches at depth, since cp -R took the lot.
    while IFS= read -r hit; do
      [ -n "$hit" ] && rm -rf "$hit"
    done <<EOF
$(find "$OUT/claude-home/$base" | grep -E "$DENY" || true)
EOF
    n=$((n + 1))
    note "tree  $base"
  else
    cp "$entry" "$OUT/claude-home/"
    n=$((n + 1))
    note "file  $base"
  fi
done

# --- MCP servers, shape only ------------------------------------------------
# ~/.claude.json holds the server list and each server's env block. The list is
# setup he needs; the env block is credentials he must not have. Names, commands
# and args travel; every env VALUE is replaced with the string the restore step
# tells him to fill in.

if [ -f "$HOME/.claude.json" ] && command -v python3 >/dev/null 2>&1; then
  python3 - "$HOME/.claude.json" "$OUT/mcp-servers.json" <<'PY' || warn "could not read ~/.claude.json; skipping MCP extraction"
import json, sys
src, dst = sys.argv[1], sys.argv[2]
try:
    d = json.load(open(src))
except Exception:
    sys.exit(1)
out = {}
def redact(server):
    s = {k: v for k, v in server.items() if k in ("command", "args", "type", "url")}
    if server.get("env"):
        s["env"] = {k: "SET-YOUR-OWN" for k in server["env"]}
    return s
for name, server in (d.get("mcpServers") or {}).items():
    if isinstance(server, dict):
        out[name] = redact(server)
for proj in (d.get("projects") or {}).values():
    if not isinstance(proj, dict):
        continue
    for name, server in (proj.get("mcpServers") or {}).items():
        if isinstance(server, dict) and name not in out:
            out[name] = redact(server)
json.dump({"mcpServers": out}, open(dst, "w"), indent=2)
print(f"  file  mcp-servers.json ({len(out)} servers, every env value redacted)")
PY
fi

# --- verify -----------------------------------------------------------------

printf '\nverifying\n'

hits=$(find "$OUT" | grep -E "$DENY" || true)
[ -z "$hits" ] || die agent_forbidden_path "$(echo "$hits" | tr '\n' ' ')"
note "no denied paths"

leaks=$(grep -rlniE 'sk-ant-[A-Za-z0-9_-]{16,}|ghp_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|"access_token"|"refresh_token"' "$OUT" 2>/dev/null || true)
[ -z "$leaks" ] || die agent_credential_present \
  "credential-shaped content in: $(echo "$leaks" | tr '\n' ' ')"
note "no credential-shaped content"

kb=$(du -sk "$OUT" | awk '{print $1}')
[ "$kb" -le 51200 ] || die agent_too_large "$((kb / 1024)) MB, ceiling 50 MB."
note "$n entries carried, $((kb / 1024)) MB"

printf '\nnot sent, by rule:\n'
for x in $skipped; do printf '  deny  %s\n' "$x"; done

printf '\nadded %s\n' "$OUT"
find "$OUT" -maxdepth 2 | sed "s|^$OUT/||" | sort | sed 's/^/  /'

cat <<'NEXT'

His restore.sh will place claude-home/ into his ~/.claude/. Two things it
cannot do and he must:
  - authenticate Claude Code as himself
  - fill in every SET-YOUR-OWN in mcp-servers.json with his own credentials
NEXT
