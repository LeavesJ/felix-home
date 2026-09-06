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
  printf 'ANTHROPIC_API_KEY=paste-your-key-here\n' > "$KEY_FILE"
  chmod 600 "$KEY_FILE"
  note "created $KEY_FILE (placeholder, mode 600)"
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

# --- 5. verify --------------------------------------------------------------

printf '\nverifying\n'
fail=0

for p in docs/lessons.md docs/DEVLOG.md; do
  [ -s "$REPO/$p" ] || { warn "$p is missing or empty"; fail=1; }
done
[ -e "$REPO/data" ] || { warn "data/ was not created"; fail=1; }
[ -z "$(find "$REPO/data" -mindepth 1 2>/dev/null | head -1)" ] \
  || warn "data/ is not empty. Nothing in this bundle put anything there."

if grep -q 'paste-your-key-here' "$KEY_FILE" 2>/dev/null; then
  warn "your key is still a placeholder at $KEY_FILE"
fi

[ "$fail" -eq 0 ] || die restore_incomplete "see the !! lines above"
note "structure matches"

cat <<NEXT

Restored. What is left, and none of it is a file copy:

  1. Put your own Anthropic key in $KEY_FILE.
     Your own, on your own workspace, with its own spend limit. Not J's.

  2. Build the venv and confirm the suite, per ENVIRONMENT.md §1:
       python3.14 -m venv .venv
       .venv/bin/pip install -e ".[dev,web]" "ruff==0.16.0" "pytest==9.1.1"
       PYTHONPATH=src .venv/bin/pytest -q
     Expect 1439 passed, 35 skipped. Those 35 are correct and permanent for
     you; ENVIRONMENT.md §5 and the onboarding document §3.1 say why.

  3. Install Felix and reach a green gate, per the onboarding document §3.2.

  4. Read state/NOTES.md. It is the only file here nobody could derive.

One thing this script cannot do for you: it copied J's docs/ into your memory
root, so your lessons and devlog START from his and then diverge as you write
your own. That is the intended arrangement and it is why they are symlinks
rather than files. If you would rather keep his history separate from yours,
say so before you write your first lesson, because after that they are one file.
NEXT
