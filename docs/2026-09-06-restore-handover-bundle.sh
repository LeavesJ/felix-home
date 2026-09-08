#!/bin/bash
# Put this bundle into your Elenchus checkout so it matches J's working state.
#
#   cd <your Elenchus checkout>
#   /path/to/bundle/restore.sh
#
# Idempotent: safe to run twice. It never overwrites a file you have changed
# without telling you, and it never touches anything git tracks.
#
# What it does, in order:
#   1. Refuses unless you are standing in a real Elenchus checkout cloned from
#      the canonical remote. A fork is governed by nothing, silently.
#   2. Places every untracked file and directory from the bundle.
#   3. Rebuilds the two structural symlinks J's checkout has, pointed at YOUR
#      home directory: data/ at an empty store of your own, and .env at an
#      out-of-tree key file.
#   4. Seeds your Felix memory root with the three authored documents and links
#      docs/ to them, which is the arrangement J's checkout uses.
#   5. Verifies, and tells you the one thing it cannot do for you.
#
# It does NOT create your venv, install Felix, or write your API key. Those are
# yours and ENVIRONMENT.md covers them.

set -euo pipefail

BUNDLE=$(cd "$(dirname "$0")" && pwd)
REPO=$(pwd)

die() {
  printf 'refused reason_code=%s reason_detail=%s\n' "$1" "$2" >&2
  exit 1
}
note() { printf '  %s\n' "$1"; }
warn() { printf '  !! %s\n' "$1"; }

# --- 1. am I in the right place ---------------------------------------------

[ -d "$REPO/.git" ] || die restore_not_a_checkout \
  "run this from inside your Elenchus checkout, not from $REPO"
[ -d "$REPO/src/elenchus" ] || die restore_not_elenchus \
  "$REPO has no src/elenchus"
[ -d "$BUNDLE/state" ] || die restore_bundle_incomplete \
  "$BUNDLE has no state/ directory; is this the unpacked bundle?"

remote=$(git -C "$REPO" remote get-url origin 2>/dev/null || true)
case "$remote" in
  *LeavesJ/Elenchus*) : ;;
  "") die restore_no_remote "this checkout has no origin remote" ;;
  *) die restore_wrong_remote \
"origin is $remote, not LeavesJ/Elenchus. Elenchus carries no marker file and \
binds to its Felix doctrine purely by remote name, so a fork is governed by \
nothing and Felix stays silent about it. Clone from LeavesJ/Elenchus." ;;
esac
note "checkout ok: $REPO"

# --- 2. place the untracked surface -----------------------------------------

printf '\nplacing files\n'
placed=0; skipped=0

cd "$BUNDLE/state"
find . -type f | sed 's|^\./||' | sort | while IFS= read -r rel; do
  src="$BUNDLE/state/$rel"
  dst="$REPO/$rel"
  if [ -e "$dst" ] && ! cmp -s "$src" "$dst"; then
    warn "differs, left alone: $rel"
    continue
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
done
cd "$REPO"
note "placed $(find "$BUNDLE/state" -type f | wc -l | tr -d ' ') files"

# Anything git now tracks that came out of the bundle would be a mistake in the
# bundle, not in this script, and it is worth catching here rather than at his
# first commit.
tracked_dirty=$(git -C "$REPO" status --porcelain --untracked-files=no | head -5 || true)
[ -z "$tracked_dirty" ] || warn "the bundle modified TRACKED files, which it should never do:
$tracked_dirty"

# The manifest is what turns "it looked like it copied" into a check. Phase C
# otherwise has no verification beyond a checksum on the archive.
if [ -f "$BUNDLE/MANIFEST" ]; then
  missing=""
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    [ -e "$REPO/$rel" ] || missing="$missing $rel"
  done < "$BUNDLE/MANIFEST"
  if [ -n "$missing" ]; then
    warn "in MANIFEST but not in your checkout:$missing"
  else
    note "manifest verified: $(grep -c . "$BUNDLE/MANIFEST") files all present"
  fi
else
  warn "no MANIFEST in this bundle; nothing checked what arrived"
fi

# --- 3. rebuild the structural symlinks -------------------------------------

printf '\nrebuilding structure\n'

DATA_STORE=${ELENCHUS_DATA_STORE:-$HOME/.local/share/elenchus/data}
KEY_FILE=${ELENCHUS_ENV_FILE:-$HOME/.config/elenchus/env}

# data/ lives outside the checkout on J's machine. Same arrangement here, and
# yours starts EMPTY. His holds beta invitees' writing and his own sittings, and
# neither is in this bundle or ever will be.
mkdir -p "$DATA_STORE"
if [ -L "$REPO/data" ]; then
  existing=$(readlink "$REPO/data")
  case "$existing" in
    "$HOME"/*)
      note "data -> $existing (already yours)" ;;
    *)
      # A data link pointing anywhere outside your home is J's path, not yours.
      # Leaving it would send every write into a directory named after his
      # machine, and on a shared layout it could collide with real invitee
      # files. Repointed, never followed.
      rm "$REPO/data"
      ln -s "$DATA_STORE" "$REPO/data"
      warn "data pointed at $existing, which is not under your home. Repointed
     to $DATA_STORE. Nothing was read from the old target." ;;
  esac
elif [ -e "$REPO/data" ]; then
  warn "data/ exists as a real directory. Left alone. J's is a symlink to
     $DATA_STORE; move yours aside and re-run if you want to match."
else
  ln -s "$DATA_STORE" "$REPO/data"
  note "data -> $DATA_STORE (empty, yours)"
fi

# .env as a symlink to an out-of-tree file is J's answer to the checkout sitting
# inside the macOS Documents sync container: the container replicates a short
# text file holding a path, never the key. Both entrypoints still resolve it,
# because both read <repo>/.env. ENVIRONMENT.md §4 has the reasoning.
mkdir -p "$(dirname "$KEY_FILE")"
if [ ! -e "$KEY_FILE" ]; then
  # The placeholder is a COMMENT, never a value, and that is load-bearing.
  # resolve_key accepts any non-empty value (serve_invitee.py:107, `if val`), so
  # a placeholder VALUE is returned as though it were a key: missing_key_warning
  # goes quiet, preflight's key-reachable axis reports ok, the launcher's
  # refusal never fires, and the instance health-checks green and dies on the
  # first real call. That is lesson L-18, which this project paid for three
  # times, manufactured by the restore script meant to prevent it.
  # Commented out, every one of those guards correctly says there is no key.
  cat > "$KEY_FILE" <<'KEYFILE'
# Your Anthropic API key. Uncomment the next line and replace the value.
# Leave it commented until you have a real key: every check in this project
# then correctly reports no key, which is the true state.
#
# ANTHROPIC_API_KEY=sk-ant-your-real-key
KEYFILE
  chmod 600 "$KEY_FILE"
  note "created $KEY_FILE (key commented out, mode 600)"
else
  note "$KEY_FILE already exists, left alone"
fi
if [ -L "$REPO/.env" ]; then
  note ".env -> $(readlink "$REPO/.env") (already a link)"
elif [ -e "$REPO/.env" ]; then
  note ".env exists as a real file, left alone. That works too."
else
  ln -s "$KEY_FILE" "$REPO/.env"
  note ".env -> $KEY_FILE"
fi

# --- 4. seed the memory root and link docs/ ---------------------------------

MEM=${FELIX_MEMORY:-$HOME/.felix/memory}/elenchus
printf '\nlinking the authored documents\n'
mkdir -p "$MEM"

for f in lessons.md DEVLOG.md SESSION_HANDOFF.md; do
  bundled="$BUNDLE/state/docs/$f"
  [ -f "$bundled" ] || { warn "$f not in the bundle, skipping"; continue; }
  if [ -L "$REPO/docs/$f" ]; then
    note "docs/$f -> $(readlink "$REPO/docs/$f") (already linked)"
    continue
  fi
  if [ -s "$MEM/$f" ] && ! cmp -s "$bundled" "$MEM/$f"; then
    warn "$MEM/$f exists and differs from the bundle. Left alone.
     Yours is the one Felix writes to; merge by hand if you want J's history."
    continue
  fi
  cp "$bundled" "$MEM/$f"
  rm -f "$REPO/docs/$f"
  ln -s "$MEM/$f" "$REPO/docs/$f"
  note "docs/$f -> $MEM/$f"
done

# --- 4b. the agent setup ----------------------------------------------------
# Optional: present only if build-agent-setup.sh was run against this bundle.

if [ -d "$BUNDLE/agent-setup/claude-home" ]; then
  printf '\nplacing the agent setup\n'
  mkdir -p "$HOME/.claude"
  agent_n=0
  for entry in "$BUNDLE/agent-setup/claude-home"/* "$BUNDLE/agent-setup/claude-home"/.[!.]*; do
    [ -e "$entry" ] || continue
    base=$(basename "$entry")
    dst="$HOME/.claude/$base"
    if [ -e "$dst" ]; then
      # Never clobber his own agents, commands or settings. His win; J's land
      # beside them with a suffix so he can diff and merge deliberately.
      if diff -rq "$entry" "$dst" >/dev/null 2>&1; then
        note "$base identical, left alone"
      else
        rm -rf "$dst.from-jarron"
        cp -R "$entry" "$dst.from-jarron"
        warn "$base exists and differs. Yours is untouched; J's is at
     ~/.claude/$base.from-jarron for you to merge."
      fi
      continue
    fi
    cp -R "$entry" "$dst"
    agent_n=$((agent_n + 1))
    note "$base"
  done
  note "$agent_n entries placed into ~/.claude/"

  if [ -f "$BUNDLE/agent-setup/mcp-servers.json" ]; then
    cp "$BUNDLE/agent-setup/mcp-servers.json" "$HOME/.claude/mcp-servers.from-jarron.json"
    note "mcp-servers.from-jarron.json (every env value reads SET-YOUR-OWN)"
    warn "MCP servers are NOT wired up. That file lists which servers J runs and
     how, with every credential removed. Add them yourself with your own
     credentials; nothing reads that file automatically."
  fi
fi

# --- 5. verify --------------------------------------------------------------

printf '\nverifying\n'
fail=0

for p in docs/lessons.md docs/DEVLOG.md; do
  [ -s "$REPO/$p" ] || { warn "$p is missing or empty"; fail=1; }
done
[ -e "$REPO/data" ] || { warn "data/ was not created"; fail=1; }
[ -z "$(find "$REPO/data" -mindepth 1 2>/dev/null | head -1)" ] \
  || warn "data/ is not empty. Nothing in this bundle put anything there."

# Mirrors resolve_key: an uncommented ANTHROPIC_API_KEY line with a non-empty
# value. Checking for the placeholder string instead would pass the moment
# someone replaced it with anything at all.
if ! grep -qE '^[[:space:]]*(export[[:space:]]+)?ANTHROPIC_API_KEY[[:space:]]*=[[:space:]]*[^[:space:]#]' "$KEY_FILE" 2>/dev/null; then
  warn "no key set in $KEY_FILE. Nothing that calls the model will work, and
     every guard will correctly tell you so. Uncomment the line and paste yours."
fi

[ "$fail" -eq 0 ] || die restore_incomplete "see the !! lines above"
note "structure matches"

cat <<NEXT

Restored. Read SETUP-RUNBOOK.md in this bundle; it is the sequence and every
step below is in it with the reasoning. What is left, and none of it is a file
copy:

  1. Sign ACKNOWLEDGMENT.docx in this bundle and send it back to J. Five
     minutes, and SETUP-RUNBOOK.md §0 says what it covers and why it is short.

  2. Put your own Anthropic key in $KEY_FILE.
     Your own, on your own workspace, with its own spend limit. Not J's.

  3. Build the venv and confirm the suite, per ENVIRONMENT.md §1:
       python3.14 -m venv .venv
       .venv/bin/pip install -e ".[dev,web]" "ruff==0.16.0" "pytest==9.1.1"
       PYTHONPATH=src .venv/bin/pytest -q
     Expect 1439 passed, 35 skipped. Those 35 are correct and permanent for
     you; ENVIRONMENT.md §5 and the onboarding document §3.1 say why.

  4. Install Felix and reach a green gate.

  5. Merge anything at ~/.claude/*.from-jarron, and wire up your own MCP
     credentials. SETUP-RUNBOOK.md §5.

  6. Before any live evaluation, read SETUP-RUNBOOK.md §6. ELENCHUS_MAX_CALLS
     bounds one process and it is not the one you will be running.

One thing this script cannot do for you: it copied J's docs/ into your memory
root, so your lessons and devlog START from his and then diverge as you write
your own. That is the intended arrangement and it is why they are symlinks
rather than files. If you would rather keep his history separate from yours,
say so before you write your first lesson, because after that they are one file.
NEXT
