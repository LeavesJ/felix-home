# The kept judgement behind lib/instrument.sh (trust-plane step 3, slice 3, spec A5). A full instrument run took
# 4,044 s for one honest machinery change (2026-11-08, this Mac, load average near 100), so the judgement of a
# machinery change is kept as a receipt in the home's state, keyed by B's commit, the tree the squash would land
# and the engine that judged, and a later merge or dry run with the same key reads its blocker lines instead of
# running again. A receipt that cannot be read whole (unreadable, cut short, edited, another key's) is no receipt.
#
# What is kept is the run's own verdict, S8's lines: the partition's lines (S7) are read again every time, at no
# cost. A run is kept only when every unit and the canary ended by themselves and no input was unread: a time limit
# reached under a passing load, or a stop, says nothing about the tree, and kept it would refuse every later merge
# of that pair (a reading of A5). The receipt is the worker's to write, like the gate's (residual R4); the hosted
# authority (step 4) is what closes that. The engine is named by its version and by the bytes of the four files
# that judge (instrument*.sh), so an engine changed under an unchanged version does not read another's receipt.

# The key: B MT VERSION@HASH, or nothing (and so no receipt) when the engine's version cannot be read.
_felix_instr_key() {   # B MT
  local d v e
  d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd -P)" || return 0
  v="$(LC_ALL=C sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$d/../../.claude-plugin/plugin.json" 2>/dev/null | head -1)"
  [ -n "$v" ] || return 0
  e="$(cat "$d/instrument.sh" "$d/instrument-verdict.sh" "$d/instrument-run.sh" "$d/instrument-keep.sh" 2>/dev/null | git hash-object --stdin 2>/dev/null)"
  [ -n "$e" ] || return 0
  printf '%s %s %s@%s' "$1" "$2" "$v" "$e"
}
# The receipt's file for KEY, under the home's state/instrument/, or nothing when no home is known.
_felix_instr_kfile() {   # KEY
  local h="${FELIX_HOME_DIR:-}" n
  [ -n "$h" ] && [ -d "$h" ] || return 1
  n="$(printf '%s' "$1" | git hash-object --stdin 2>/dev/null)" && [ -n "$n" ] || return 1
  printf '%s/state/instrument/%s' "$h" "$n"
}
# 0, with the receipt's lines added to _FELIX_INSTR_BLOCK, when the home holds KEY's judgement whole.
_felix_instr_kept() {   # KEY
  local f c body sum n l cnt=0 kind subj why
  f="$(_felix_instr_kfile "$1")" && [ -f "$f" ] || return 1
  _felix_instr_rd c cat "$f" || return 1
  case "$c" in "felix-instrument-judgement 1"$'\n'"key $1"$'\n'*) ;; *) return 1 ;; esac
  sum="${c##*$'\n'}"; body="${c%$'\n'*}"
  case "$sum" in "sum "?*) ;; *) return 1 ;; esac
  [ "${sum#sum }" = "$(printf '%s' "$body" | git hash-object --stdin 2>/dev/null)" ] || return 1
  n="${body##*$'\n'}"
  case "$n" in "count "*) n="${n#count }" ;; *) return 1 ;; esac
  case "$n" in ''|*[!0123456789]*) return 1 ;; esac
  while IFS= read -r l; do case "$l" in "line "*) cnt=$((cnt + 1)) ;; esac; done <<EOF
$body
EOF
  [ "$cnt" = "$n" ] || return 1
  while IFS= read -r l; do
    case "$l" in "line "*) ;; *) continue ;; esac
    IFS=$'\t' read -r kind subj why <<EOF
${l#line }
EOF
    [ -n "$kind" ] && [ -n "$subj" ] && _felix_instr_add "$kind" "$subj" "$why"
  done <<EOF
$body
EOF
  return 0
}
# The judgement just made, kept for KEY: S8's lines, the partition's left out. Never fatal, and never partial: it
# is written beside the receipt and moved over it.
_felix_instr_keep() {   # KEY
  local f body l n=0
  f="$(_felix_instr_kfile "$1")" || return 0
  body="felix-instrument-judgement 1"$'\n'"key $1"
  while IFS= read -r l; do
    case "$l" in ''|escape$'\t'projects/*/partition.tsv$'\t'*) continue ;; unknown$'\t'*) return 0 ;; esac
    body="$body"$'\n'"line $l"; n=$((n + 1))
  done <<EOF
$_FELIX_INSTR_BLOCK
EOF
  body="$body"$'\n'"count $n"
  mkdir -p "${f%/*}" 2>/dev/null || return 0
  { printf '%s\nsum %s\n' "$body" "$(printf '%s' "$body" | git hash-object --stdin 2>/dev/null)" > "$f.$$.t" \
      && mv -f "$f.$$.t" "$f"; } 2>/dev/null || rm -f "$f.$$.t" 2>/dev/null
  return 0
}
