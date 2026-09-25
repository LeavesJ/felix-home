#!/bin/bash
# Throwaway census of a Claude Code cloud VM. Prints environment variable
# NAMES only, never values, except for a short allowlist of non-secret ones.
[ "${CLAUDE_CODE_REMOTE:-}" = true ] || exit 0
O=/tmp/cloud-probe; mkdir -p "$O"; F="$O/census.txt"
{
  echo "## identity"; date -u; whoami; id; echo "HOME=$HOME"; echo "PWD=$PWD"; echo "CLAUDE_PROJECT_DIR=${CLAUDE_PROJECT_DIR:-}"
  uname -srm; head -2 /etc/os-release
  echo "## allowlisted values"
  for v in CLAUDE_CODE_REMOTE CLAUDE_CODE_ENTRYPOINT CLAUDE_CONFIG_DIR CLAUDE_AUTOCOMPACT_PCT_OVERRIDE CLAUDE_CODE_AUTO_COMPACT_WINDOW CLAUDE_CODE_REMOTE_ENVIRONMENT_TYPE CLAUDE_ENV_FILE SHELL; do printf '%s=%s\n' "$v" "${!v:-<unset>}"; done
  [ "${GH_TOKEN:-}" = proxy-injected ] && echo "GH_TOKEN=proxy-injected" || echo "GH_TOKEN is ${GH_TOKEN:+set-not-placeholder}${GH_TOKEN:-unset}" | sed 's/=.*//; s/set-not-placeholder.*/set (not the placeholder)/'
  echo "## env names"; env | cut -d= -f1 | LC_ALL=C sort | tr '\n' ' '; echo
  echo "## tools"
  bash --version | head -1; git --version; jq --version; python3 --version; node --version 2>&1; gh --version 2>&1 | head -1; perl -v | sed -n 2p
  echo "claude: $(command -v claude || echo absent) $(claude --version 2>&1 | head -1)"
  echo "graphify: $(command -v graphify || echo absent)"
  echo "## home"; ls -la "$HOME" 2>&1 | head -40
  echo "## ~/.claude"; find "$HOME/.claude" -maxdepth 2 2>&1 | head -60
  echo "## ~/.felix"; ls -la "$HOME/.felix" 2>&1 | head
  echo "## repo"; git -C "$CLAUDE_PROJECT_DIR" remote -v | sed -E 's#//[^@/]+@#//REDACTED@#'
  git -C "$CLAUDE_PROJECT_DIR" branch --show-current; git -C "$CLAUDE_PROJECT_DIR" log --oneline -1
  echo "## github reach (exit codes)"
  for r in LeavesJ/Felix LeavesJ/cash-ops obra/superpowers anthropics/claude-plugins-official; do
    timeout 30 git ls-remote "https://github.com/$r" HEAD >/dev/null 2>"$O/lsr.err"; printf 'ls-remote %s exit=%s %s\n' "$r" "$?" "$(head -c 160 "$O/lsr.err" | tr '\n' ' ')"
  done
  printf 'gh api repos/LeavesJ/cash-ops exit=%s\n' "$(timeout 30 gh api repos/LeavesJ/cash-ops --jq .private >/dev/null 2>&1; echo $?)"
  echo "## http reach (status codes)"
  for u in https://raw.githubusercontent.com/obra/superpowers/main/README.md https://pypi.org/simple/graphifyy/ https://registry.npmjs.org/ https://codeload.github.com/obra/superpowers/tar.gz/refs/heads/main; do
    printf '%s %s\n' "$(curl -sS -o /dev/null -m 20 -w '%{http_code}' "$u" 2>&1)" "$u"
  done
  echo "## claude plugin cli"
  timeout 60 claude plugin marketplace list 2>&1 | head -10
  timeout 60 claude plugin list 2>&1 | head -10
  echo "## felix cli from the clone"
  (cd "$CLAUDE_PROJECT_DIR" && timeout 60 bash engine/harness/felix which 2>&1 | head -20)
} > "$F" 2>&1
# Skill discovery test: one in the VM home, one untracked in the clone.
mkdir -p "$HOME/.claude/skills/probe-home-skill" "$CLAUDE_PROJECT_DIR/.claude/skills/probe-untracked-skill"
printf -- '---\nname: probe-home-skill\ndescription: Cloud environment probe marker. Invoke only when explicitly asked to test the probe skills.\n---\nReply with the code word HOME-OK and nothing else.\n' > "$HOME/.claude/skills/probe-home-skill/SKILL.md"
printf -- '---\nname: probe-untracked-skill\ndescription: Cloud environment probe marker. Invoke only when explicitly asked to test the probe skills.\n---\nReply with the code word UNTRACKED-OK and nothing else.\n' > "$CLAUDE_PROJECT_DIR/.claude/skills/probe-untracked-skill/SKILL.md"
echo ".claude/skills/probe-untracked-skill/" >> "$CLAUDE_PROJECT_DIR/.git/info/exclude" 2>/dev/null
exit 0
