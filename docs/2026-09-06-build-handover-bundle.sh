#!/bin/bash
# Build the Elenchus handover bundle for Riyan, or refuse and say why.
#
#   ./2026-09-06-build-handover-bundle.sh <elenchus-checkout> [felix-checkout]
#
# Written 2026-09-06 as a companion to 2026-09-06-handover-setup.md Part 1.
# It exists because the pasted-command version of this step produced a 276 MB
# bundle holding an entire repository checkout, two symlinks pointing at a live
# API key and at the beta invitee data root, and none of the three documents it
# was supposed to contain. Three separate failures passed silently in an
# interactive shell. A script fails on the first one and names it.
#
# Every refusal prints a stable snake_case reason_code and a free-form detail.
# Nothing is copied until the destination is known absent. Nothing is declared
# built until every check below passes.
#
# This script never reads, copies, or dereferences anything under the beta data
# root or the Felix memory root. The three memory-root documents it does copy
# are copied by name, as contents, because they are authored prose.

set -euo pipefail

die() {
  printf 'refused reason_code=%s reason_detail=%s\n' "$1" "$2" >&2
  exit 1
}

note() { printf '  %s\n' "$1"; }

# --- inputs -----------------------------------------------------------------

[ $# -ge 1 ] || die bundle_no_source \
  "usage: $0 <elenchus-checkout> [felix-checkout]"

ELENCHUS=${1%/}
[ -d "$ELENCHUS/.git" ] || die bundle_not_a_checkout \
  "$ELENCHUS has no .git; pass the Elenchus checkout root"

if [ $# -ge 2 ]; then
  FELIX=${2%/}
else
  # Ask Felix where it lives rather than keeping a second copy of the resolution
  # logic. Two copies of "where does X come from" is exactly the drift that put
  # a keyless instance behind a green health check (serve_invitee.py:35).
  command -v felix >/dev/null 2>&1 || die bundle_felix_unresolved \
    "felix is not on PATH; pass the felix checkout as the second argument"
  doctrine=$(cd "$ELENCHUS" && felix which 2>/dev/null | awk '/^doctrine:/ {print $2}')
  [ -n "$doctrine" ] || die bundle_felix_unresolved \
    "felix which printed no doctrine path; pass the felix checkout as the second argument"
  FELIX=${doctrine%/projects/*}
fi

ENVDOC="$FELIX/docs/2026-09-06-elenchus-environment.md"
[ -f "$ENVDOC" ] || die bundle_missing_source \
  "$ENVDOC not found; is $FELIX the felix checkout, and is it up to date?"

OUT=${HANDOVER_OUT:-$HOME/handover}
[ ! -e "$OUT" ] || die bundle_dest_exists \
  "$OUT already exists. Inspect it, then remove it, then re-run. This script \
never merges into an existing bundle because a stale file is invisible in a \
directory listing."

# --- copy helpers -----------------------------------------------------------

# Plain cp reads THROUGH a symlink, which is what we want for the three
# memory-root documents: Riyan receives contents, never a pointer into
# /Users/<founder>/ that resolves to nothing on his machine.
copy_file() {
  src=$1; dst=$2
  # A dangling symlink appears in ls like any other entry, so it gets its own
  # code rather than being reported as absent.
  if [ -L "$src" ] && [ ! -e "$src" ]; then
    die bundle_dangling_symlink \
      "$src is a symlink to $(readlink "$src"), which does not exist"
  fi
  [ -e "$src" ] || die bundle_missing_source "$src does not exist"
  [ -f "$src" ] || die bundle_not_regular_file \
    "$src is not a regular file and is not a symlink to one"
  cp "$src" "$dst"
  note "file  $src"
}

# cp -R PRESERVES a symlink found inside a directory rather than following it,
# so a tree is refused outright if it contains one. Deciding per link is a
# judgement call and this script does not make judgement calls.
copy_tree() {
  src=$1; dst=$2
  [ -d "$src" ] || die bundle_missing_source "$src is not a directory"
  links=$(find "$src" -type l 2>/dev/null || true)
  [ -z "$links" ] || die bundle_symlink_in_source \
    "$src contains symlinks and cp -R would preserve them: $(echo "$links" | tr '\n' ' ')"
  cp -R "$src" "$dst"
  note "tree  $src"
}

# --- build ------------------------------------------------------------------

printf 'building %s\n' "$OUT"
printf '  elenchus: %s\n' "$ELENCHUS"
printf '  felix:    %s\n\n' "$FELIX"

mkdir -p "$OUT/docs" "$OUT/content-lift" "$OUT/claude-config"

copy_file "$ELENCHUS/docs/DEVLOG.md"          "$OUT/docs/"
copy_file "$ELENCHUS/docs/lessons.md"         "$OUT/docs/"
copy_file "$ELENCHUS/docs/SESSION_HANDOFF.md" "$OUT/docs/"
copy_tree "$ELENCHUS/docs/spike-results"      "$OUT/docs/"
copy_tree "$ELENCHUS/docs/superpowers"        "$OUT/docs/"

copy_file "$ELENCHUS/POSITIONING.md"              "$OUT/"
copy_file "$ELENCHUS/content/lift/scenarios.yaml"  "$OUT/content-lift/"
copy_file "$ELENCHUS/content/lift/candidates.yaml" "$OUT/content-lift/"
copy_file "$ELENCHUS/.claude/CLAUDE.md"            "$OUT/claude-config/"

copy_file "$ENVDOC" "$OUT/ENVIRONMENT.md"

# --- verify -----------------------------------------------------------------

printf '\nverifying\n'

# 1. Nothing in the bundle may be a symlink. Every one would be a pointer into
#    the founder's home directory, dead on arrival and silent about it.
links=$(find "$OUT" -type l 2>/dev/null || true)
[ -z "$links" ] || die bundle_symlink_present \
  "$(echo "$links" | tr '\n' ' ')"
note "no symlinks"

# 2. Nothing matching these names may appear anywhere in the bundle. This is the
#    check that would have caught a whole checkout landing in claude-config/.
FORBIDDEN='(^|/)(\.env|\.env\..*|\.git|\.venv.*|\.pytest_cache|\.ruff_cache|\.superpowers|\.claude-flow|\.worktrees|\.felix|\.cloudflared|node_modules|build|graphify-out|data|tenants|admissions|docs\.bak-.*|settings\.local\.json|YC_answers\.md|.*\.pre-reset-.*|.*\.db|.*\.sqlite|.*\.sqlite3|.*\.key|cert\.pem|id_[rd]sa.*|injection_payloads\.yaml)$'
hits=$(find "$OUT" | grep -E "$FORBIDDEN" || true)
[ -z "$hits" ] || die bundle_forbidden_path \
  "$(echo "$hits" | tr '\n' ' ')"
note "no forbidden paths"

# 3. Every document that must be present must also be non-empty. A zero-byte
#    file is what a broken dereference leaves behind.
for f in docs/DEVLOG.md docs/lessons.md docs/SESSION_HANDOFF.md \
         POSITIONING.md ENVIRONMENT.md claude-config/CLAUDE.md \
         content-lift/scenarios.yaml content-lift/candidates.yaml; do
  [ -s "$OUT/$f" ] || die bundle_empty_file "$OUT/$f is missing or zero bytes"
done
note "all required files present and non-empty"

# 4. Scale. A bundle a person is about to read every file of has a size. These
#    ceilings are deliberately generous; tripping one means something recursive
#    got in, not that the bundle grew.
count=$(find "$OUT" -type f | wc -l | tr -d ' ')
bytes=$(du -sk "$OUT" | awk '{print $1}')
[ "$count" -le 2000 ] || die bundle_too_many_files \
  "$count files, ceiling 2000. Something recursive got in."
[ "$bytes" -le 51200 ] || die bundle_too_large \
  "$((bytes / 1024)) MB, ceiling 50 MB. Something recursive got in."
note "$count files, $((bytes / 1024)) MB"

# --- manifest ---------------------------------------------------------------

printf '\nbuilt %s\n\n' "$OUT"
# Read with IFS unset and printed field by field, because a filename with a
# space in it is not hypothetical in this checkout.
find "$OUT" -type f | sed "s|^$OUT/||" | sort | while IFS= read -r f; do
  printf '  %9s  %s\n' "$(wc -c < "$OUT/$f" | tr -d ' ')" "$f"
done

cat <<'NEXT'

Not done. Still to do, in this order:
  1. Write NOTES.md into the bundle by hand (step 1.4, template beside this script).
  2. Scan it, both passes (step 1.5). Neither pass looks for a person.
  3. Read it, hardest files first (step 1.6). No script does this one.
NEXT
