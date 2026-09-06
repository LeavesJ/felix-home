#!/bin/bash
# Replicate J's Elenchus working state into a bundle Riyan can restore.
#
#   ./2026-09-06-build-handover-bundle.sh <elenchus-checkout> <felix-checkout> [--all]
#
# Written 2026-09-06. The goal is stated by the founder as: "Riyan's laptop
# Elenchus folder is the state mine is in." So this is a deny-list, not an
# allow-list. Everything untracked in the checkout travels, EXCEPT what must not
# and what he regenerates himself.
#
# An earlier version of this script was an allow-list built for minimum
# disclosure, and it withheld four ML design documents from the person hired for
# being better at ML. Same-state is the objective; the four hard exclusions
# below are the constraint.
#
# NEVER TRAVELS, regardless of anything:
#   .env and any .env.*      the live Anthropic key
#   data/                    beta invitee databases AND the founder's own sittings
#   ~/.cloudflared           tunnel credentials (never in the checkout anyway)
#   the memory root's raw logs (routes, says, mistakes, verification, ledger,
#                            unresolved). Its three AUTHORED files do travel.
#
# NOT SENT because he regenerates or does not want them:
#   .git .venv* __pycache__ .pytest_cache .ruff_cache build/ graphify-out/
#   docs.bak-* *.pre-reset-* .worktrees .DS_Store
#
# HELD BACK unless --all, because they are founder material rather than
# engineering material:
#   docs/YC_answers.md  docs/admissions/
#
# Every refusal prints a stable snake_case reason_code and a free-form detail.
# The bundle carries its own restore.sh, so integration is one command.

set -euo pipefail

die() {
  printf 'refused reason_code=%s reason_detail=%s\n' "$1" "$2" >&2
  exit 1
}
note() { printf '  %s\n' "$1"; }

# --- inputs -----------------------------------------------------------------

[ $# -ge 2 ] || die bundle_no_source \
  "usage: $0 <elenchus-checkout> <felix-checkout> [--all]"

ELENCHUS=$(cd "${1%/}" 2>/dev/null && pwd) || die bundle_not_a_checkout "cannot cd to $1"
FELIX=$(cd "${2%/}" 2>/dev/null && pwd)    || die bundle_not_a_checkout "cannot cd to $2"
INCLUDE_ALL=${3:-}

[ -d "$ELENCHUS/.git" ] || die bundle_not_a_checkout "$ELENCHUS has no .git"
[ -d "$ELENCHUS/src/elenchus" ] || die bundle_not_a_checkout "$ELENCHUS has no src/elenchus"

ENVDOC="$FELIX/docs/2026-09-06-elenchus-environment.md"
[ -f "$ENVDOC" ] || die bundle_missing_source "$ENVDOC not found; is $FELIX current?"

OUT=${HANDOVER_OUT:-$HOME/handover}
[ ! -e "$OUT" ] || die bundle_dest_exists \
  "$OUT exists. Inspect it, remove it, re-run. This never merges into an \
existing bundle because a stale file is invisible in a directory listing."

# --- the deny list ----------------------------------------------------------
# Matched against the path RELATIVE to the checkout root, at any depth.

DENY='(^|/)(\.git|\.env|\.env\..*|data|\.venv.*|__pycache__|\.pytest_cache|\.ruff_cache|\.mypy_cache|build|dist|graphify-out|\.worktrees|\.DS_Store|.*\.egg-info|docs\.bak-.*|.*\.pre-reset-.*|.*\.pyc|.*\.db|.*\.sqlite3?|.*\.key|cert\.pem|id_[rd]sa.*)$'
ASK='(^|/)(YC_answers\.md|admissions)$'

# --- discover the untracked surface -----------------------------------------

printf 'replicating %s\n' "$ELENCHUS"
printf '  felix:  %s\n' "$FELIX"
printf '  target: %s\n\n' "$OUT"

cd "$ELENCHUS"

# Everything git does not track. Directories are collapsed so that .venv/ is one
# entry to deny rather than four thousand, and the walk below descends into the
# ones that survive. This IS the delta between a fresh clone and this working
# checkout, which is the whole question.
raw=$( { git ls-files --others --exclude-standard --directory
         git ls-files --others --ignored --exclude-standard --directory
       } 2>/dev/null | sed 's|/$||' | sort -u | grep -v '^$' || true )

[ -n "$raw" ] || die bundle_empty_surface \
  "git reports nothing untracked in $ELENCHUS. Wrong directory?"

# Drop any entry whose parent is also listed. git reports both `content` and
# `content/lift` when only part of a directory is ignored, and copying both
# copies the same bytes twice.
surface=$(printf '%s\n' "$raw" | awk '
  { e[NR]=$0 }
  END {
    for (i=1;i<=NR;i++) {
      keep=1
      for (j=1;j<=NR;j++) if (i!=j && index(e[i], e[j]"/")==1) { keep=0; break }
      if (keep) print e[i]
    }
  }')

mkdir -p "$OUT/state"

skipped_deny=""
skipped_ask=""
n_files=0
n_links=0

# Recursive, because a directory that survives the deny list can still contain a
# symlink, and a symlink is structure rather than content: copying the link
# hands Riyan a dead pointer into /Users/<founder>/, and following it blindly is
# how a link named `data` becomes the invitee databases. Neither. Recorded, and
# restore.sh rebuilds the equivalent against HIS home directory.
carry() {
  local rel=$1 src dst child
  src="$ELENCHUS/$rel"

  if printf '%s' "$rel" | grep -qE "$DENY"; then
    skipped_deny="$skipped_deny $rel"; return 0
  fi
  if printf '%s' "$rel" | grep -qE "$ASK" && [ "$INCLUDE_ALL" != "--all" ]; then
    skipped_ask="$skipped_ask $rel"; return 0
  fi

  dst="$OUT/state/$rel"

  if [ -L "$src" ]; then
    printf '%s\t%s\n' "$rel" "$(readlink "$src")" >> "$OUT/symlinks.tsv"
    n_links=$((n_links + 1))
    if [ -f "$src" ]; then
      mkdir -p "$(dirname "$dst")"
      cp "$src" "$dst"
      n_files=$((n_files + 1))
      note "link+contents  $rel"
    else
      note "link recorded  $rel -> $(readlink "$src")"
    fi
    return 0
  fi

  if [ -d "$src" ]; then
    mkdir -p "$dst"
    for child in "$src"/* "$src"/.[!.]*; do
      [ -e "$child" ] || [ -L "$child" ] || continue
      carry "$rel/$(basename "$child")"
    done
    return 0
  fi

  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  n_files=$((n_files + 1))
  return 0
}

while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  carry "$rel"
done <<EOF
$surface
EOF

note "$n_files files carried, $n_links symlinks recorded"

# The environment document is not in the checkout; it comes from felix.
cp "$ENVDOC" "$OUT/ENVIRONMENT.md"
cp "$FELIX/docs/2026-09-06-restore-handover-bundle.sh" "$OUT/restore.sh"
chmod +x "$OUT/restore.sh"
note "file  ENVIRONMENT.md (from felix)"
note "file  restore.sh"

# --- verify -----------------------------------------------------------------

printf '\nverifying\n'

links=$(find "$OUT" -type l 2>/dev/null || true)
[ -z "$links" ] || die bundle_symlink_present "$(echo "$links" | tr '\n' ' ')"
note "no symlinks in the bundle"

hits=$(cd "$OUT" && find . | sed 's|^\./||' | grep -E "$DENY" || true)
[ -z "$hits" ] || die bundle_forbidden_path "$(echo "$hits" | tr '\n' ' ')"
note "no denied paths"

for f in state/docs/DEVLOG.md state/docs/lessons.md ENVIRONMENT.md restore.sh; do
  [ -s "$OUT/$f" ] || die bundle_empty_file "$OUT/$f is missing or zero bytes"
done
note "required files present and non-empty"

count=$(find "$OUT" -type f | wc -l | tr -d ' ')
kb=$(du -sk "$OUT" | awk '{print $1}')
[ "$count" -le 4000 ] || die bundle_too_many_files "$count files, ceiling 4000."
[ "$kb" -le 204800 ] || die bundle_too_large "$((kb / 1024)) MB, ceiling 200 MB."
note "$count files, $((kb / 1024)) MB"

# --- report -----------------------------------------------------------------

printf '\nbuilt %s\n\n' "$OUT"
find "$OUT" -type f | sed "s|^$OUT/||" | sort | while IFS= read -r f; do
  printf '  %9s  %s\n' "$(wc -c < "$OUT/$f" | tr -d ' ')" "$f"
done

printf '\nnot sent, by rule:\n'
for x in $skipped_deny; do printf '  deny  %s\n' "$x"; done
if [ -n "$skipped_ask" ]; then
  for x in $skipped_ask; do printf '  held  %s   (re-run with --all to include)\n' "$x"; done
fi

if [ -f "$OUT/symlinks.tsv" ]; then
  printf '\nsymlinks recorded for restore.sh to rebuild:\n'
  while IFS=$'\t' read -r a b; do printf '  %s -> %s\n' "$a" "$b"; done < "$OUT/symlinks.tsv"
fi

cat <<'NEXT'

Not done. Still to do, in this order:
  1. Write state/NOTES.md by hand (step 1.4, template beside this script).
  2. Scan it, both passes (step 1.5). Neither pass looks for a person.
  3. Read it, hardest files first (step 1.6). No script does this one.
NEXT
