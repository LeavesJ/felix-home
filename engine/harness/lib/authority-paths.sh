# Which paths of a change are the founder's, and how a worker's word is shown.
#
# Trust-plane step 4, stage 1, slice 1 (lib/authority.sh says what the slice is).
#
# ONE FUNCTION FOR THE DOOR AND THE KERNEL (the door design's decision 11). The 11-10 mock had two readers of
# the founder-path policy, and they differed on a path with a newline: the door listed it as his and the kernel
# did not hold it, because the kernel turned the newline into "?" before its rule about bytes outside printable
# ASCII read the path. Here felix_authority_paths is the one reader. The door's card and the kernel's decision
# both take its answer, and a path is read NUL-terminated from git and is never turned into another byte before
# the rules read it.
#
# THE RULES (W9). A changed path is the founder's when:
#   1. it holds a byte outside 0x20 to 0x7e, a newline and a tab among them: held, and not matched;
#   2. it is .felix, or the land table itself, projects/<name>/land.tsv, where <name> is the first line of the
#      base's .felix, or a path under either: a change to the policy that says what is his is his. .felix is in
#      the rule because it names the table: a candidate that changed it to another project's name, and brought
#      that project's table, read as eligible and chose its own policy from then on (review F1);
#   3. a row of kind `founder` in that table, as the base holds it and lib/land-table.sh's schema accepts it,
#      matches it. A row is an ERE that grep searches the path for, as the schema checks it, and here without
#      regard to case, which matches more: this Mac's file system folds case.
# When the base has no .felix, no land table, or a table the schema refuses a row of, the policy cannot be read
# and each changed path is his. So is each path when git could not list the change. Failing closed here means
# the change waits for him; it refuses nothing.
#
# NOT COVERED, and said in the slice's document: a repository whose policy lives in another repository (a
# governed product, whose tables are in a Felix home), and look-alike characters inside printable ASCII.
#
# Bash 3.2. No project is named here.

# D5, D12. A worker's word, shown: each byte outside printable ASCII, each backslash and each double quote as
# \xNN, the whole in double quotes. With MAX, cut there, and the cut says how many bytes it left out. A word
# with nothing to escape is printed as it is. Any other goes through od and awk, one pass over its bytes: a
# loop in bash that appended to a string took 27 seconds for 32,000 bytes, and a founder path is never cut, so
# one long path a worker pushed set how long the door took (review F9).
_fa_esc() {   # STRING [MAX]
  local s="$1" max="${2:-0}" n LC_ALL=C
  n=${#s}
  [ "$max" -eq 0 ] || [ "$n" -le "$max" ] || s="${s:0:max}"
  case "$s" in
    *[!\ -~]*|*\\*|*\"*)
      printf '"'
      printf '%s' "$s" | od -An -v -tx1 | LC_ALL=C awk '
        BEGIN { for (i = 32; i < 127; i++) c[sprintf("%02x", i)] = sprintf("%c", i); delete c["5c"]; delete c["22"] }
        { for (i = 1; i <= NF; i++) printf "%s", (($i in c) ? c[$i] : "\\x" $i) }'
      printf '"' ;;
    *) printf '"%s"' "$s" ;;
  esac
  [ "$max" -eq 0 ] || [ "$n" -le "$max" ] || printf ' (+%s more bytes)' "$(( n - max ))"
}

# The policy at BASE, read once a process (a tick asks it of each candidate). Sets _FP_AT to BASE,
# _FP_AT_UNREADABLE to 1 when it cannot be read, and _FP_AT_ERES to the patterns: each founder row's, then the
# land table's own path (rule 2), each dot of the project's name a literal dot.
_fa_policy() {   # BASE
  local b="$1" name table rows p k rest
  [ "${_FP_AT:-}" != "$b" ] || return 0
  _FP_AT="$b"; _FP_AT_UNREADABLE=0; _FP_AT_ERES=(); _FP_AT_N=0
  name="$(_fa_g cat-file blob "$b:.felix" 2>/dev/null | LC_ALL=C sed -n '1{s/[[:space:]]//g;p;}')"
  case "$name" in ""|.|..|*[!A-Za-z0-9._-]*) _FP_AT_UNREADABLE=1; return 0 ;; esac
  table="$(_fa_g cat-file blob "$b:projects/$name/land.tsv" 2>/dev/null)" || { _FP_AT_UNREADABLE=1; return 0; }
  command -v felix_land_malformed_in >/dev/null 2>&1 || { _FP_AT_UNREADABLE=1; return 0; }
  felix_land_malformed_in >/dev/null 2>&1 <<EOF || { _FP_AT_UNREADABLE=1; return 0; }
$table
EOF
  rows="$(felix_land_rows_in <<EOF
$table
EOF
)"
  while IFS=$'\t' read -r p k rest; do
    [ "$k" = founder ] && [ -n "$p" ] || continue
    _FP_AT_ERES[$_FP_AT_N]="$p"; _FP_AT_N=$((_FP_AT_N + 1))
  done <<EOF
$rows
EOF
  _FP_AT_ERES[$_FP_AT_N]="^projects/$(printf '%s' "$name" | LC_ALL=C sed 's/\./\\./g')/land\\.tsv(/|\$)"
  _FP_AT_N=$((_FP_AT_N + 1))
  _FP_AT_ERES[$_FP_AT_N]='^\.felix(/|$)'
  _FP_AT_N=$((_FP_AT_N + 1))
}

# felix_authority_paths BASE TREE [FROM-TREE]. FROM-TREE is what the change is read against when that is not
# BASE's own tree (a head that conflicts is read against its merge base). Sets:
#   _FP_FOUNDER   an array: each changed path that is the founder's, in the tree's order
#   _FP_OTHER     an array: each other changed path, in the tree's order
#   _FP_NF, _FP_NO  how many each holds (an empty array is not expanded under set -u in bash 3.2)
#   _FP_UNREADABLE  1 when the policy at BASE cannot be read, 2 when git could not list the change, else 0
felix_authority_paths() {   # BASE TREE [FROM-TREE]
  local b="$1" t="$2" from="${3:-}" p k f g i n=0 ln=0 hits=" " line rc LC_ALL=C
  local -a all=() plainno=()
  _FP_FOUNDER=(); _FP_OTHER=(); _FP_NF=0; _FP_NO=0
  [ -n "$from" ] || from="$b^{tree}"
  _fa_policy "$b"; _FP_UNREADABLE="$_FP_AT_UNREADABLE"
  f="$_FA_DOOR/paths.$$"; g="$_FA_DOOR/plain.$$"
  if ! _fa_g diff-tree -r --no-renames --name-only -z "$from" "$t" > "$f" 2>/dev/null; then
    rm -f "$f"; _FP_UNREADABLE=2; _FP_FOUNDER[0]="?"; _FP_NF=1
    return 0
  fi
  : > "$g"
  while IFS= read -r -d '' p; do
    all[$n]="$p"
    case "$p" in
      *[!\ -~]*) plainno[$n]=0 ;;
      *) ln=$((ln + 1)); plainno[$n]="$ln"; printf '%s\n' "$p" >> "$g" ;;
    esac
    n=$((n + 1))
  done < "$f"
  if [ "$_FP_UNREADABLE" -eq 0 ] && [ "$ln" -gt 0 ]; then
    for (( i = 0; i < _FP_AT_N; i++ )); do
      line="$(LC_ALL=C grep -n -i -E -e "${_FP_AT_ERES[$i]}" "$g" 2>/dev/null)"; rc=$?
      [ "$rc" -le 1 ] || { _FP_UNREADABLE=1; break; }
      while IFS= read -r k; do [ -z "$k" ] || hits="$hits${k%%:*} "; done <<EOF
$line
EOF
    done
  fi
  rm -f "$f" "$g"
  for (( i = 0; i < n; i++ )); do
    if [ "$_FP_UNREADABLE" -ne 0 ] || [ "${plainno[$i]}" -eq 0 ]; then k=1
    else case "$hits" in *" ${plainno[$i]} "*) k=1 ;; *) k=0 ;; esac; fi
    if [ "$k" -eq 1 ]; then _FP_FOUNDER[$_FP_NF]="${all[$i]}"; _FP_NF=$((_FP_NF + 1))
    else _FP_OTHER[$_FP_NO]="${all[$i]}"; _FP_NO=$((_FP_NO + 1)); fi
  done
  return 0
}
