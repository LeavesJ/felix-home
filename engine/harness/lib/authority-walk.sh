# Condition e's walk of the paths the code is reached through (W6 e, lib/authority.sh): the directories above a
# path, along each hop of a link; the physical path a link leads to; and which directories above the code still
# offend. Moved out of lib/authority.sh in 0.49.354 to keep that file under 500 lines; felix sources this after it.
# Each function reads and writes the caller's locals where it says so (_fa_code_offenders_raw's seen, ups, upl and
# the path lists), as it did inline. Bash 3.2. No project is named here.

# C3. Prints each directory above DIR up to /, along DIR as written and its physical path (cd -P), one a line (a
# path with a newline is read as two). A part on the way that is a link adds its target, one hop, printed and
# walked too, since cd -P skips the middle of a chain (0.49.354, review trust 3). Each link is followed once; one
# not followed (a 41st, or one whose target cannot be read) is printed as "LINK (a link not followed)", which
# each reader of this list refuses (security review of d1eecab1: fail closed, not silent).
_fa_above() {   # DIR
  local p q l i=0 j=0 sl=$'\n'
  local -a t
  t=("$1" "$(cd -P -- "$1" 2>/dev/null && pwd -P)")
  while [ "$j" -lt "${#t[@]}" ]; do
    p="${t[$j]}"; j=$((j + 1))
    case "$p" in /*) ;; *) continue ;; esac
    [ "$j" -le 2 ] || printf '%s\n' "$p"
    while :; do
      case "$p" in /) break ;; */) p="${p%/}"; continue ;; esac
      if [ -L "$p" ]; then
        case "$sl" in
          *$'\n'"$p"$'\n'*) ;;
          *) sl="$sl$p"$'\n'
             if [ "$i" -lt 40 ] && l="$(readlink -- "$p" 2>/dev/null)" && [ -n "$l" ]; then
               case "$l" in /*) ;; *) l="${p%/*}/$l" ;; esac
               i=$((i + 1)); t[${#t[@]}]="$l"
             else
               printf '%s (a link not followed)\n' "$p"
             fi ;;
        esac
      fi
      q="${p%/*}"; [ -n "$q" ] || q=/
      printf '%s\n' "$q"; p="$q"
    done
  done
}
# H11 (0.49.354). The physical path of what PATH, a link, points at (at most 40 hops); 1 when it leads nowhere.
_fa_real() {   # PATH
  local p="$1" l d i=0
  while [ -L "$p" ] && [ "$i" -lt 40 ]; do
    l="$(readlink -- "$p" 2>/dev/null)" && [ -n "$l" ] || return 1
    case "$l" in /*) p="$l" ;; *) p="${p%/*}/$l" ;; esac; i=$((i + 1))
  done
  [ -e "$p" ] && [ ! -L "$p" ] || return 1
  if [ -d "$p" ]; then (cd -P -- "$p" 2>/dev/null && pwd -P); return; fi
  d="$(cd -P -- "${p%/*}/" 2>/dev/null && pwd -P)" || return 1
  printf '%s/%s\n' "${d%/}" "${p##*/}"
}
# C3. Adds each line of LINES, a directory above the code, to the caller's ups (or upl, for a link) once.
_fa_up_add() {   # LINES
  local y
  while IFS= read -r y; do
    [ -n "$y" ] || continue
    case "$y" in *" (a link not followed)") printf '%s\n' "${y% (a link not followed)} (a link on the way to the code whose target was not read)"; continue ;; esac
    case "$seen" in *$'\n'"$y"$'\n'*) continue ;; esac
    seen="$seen$y"$'\n'
    if [ -L "$y" ]; then upl[${#upl[@]}]="$y"; else ups[${#ups[@]}]="$y"; fi
  done <<EOF
$1
EOF
}
# C3 (0.49.354). Prints each of LINES, a directory above the code that offends, unless (macOS) each of its
# children on the code's paths can be renamed or removed by no worker: flag sunlnk or schg (root's alone to
# clear), or restricted while SIP is on. As the sticky bit, that keeps a login that can write the directory from
# replacing what the code is reached through. (/System/Volumes/Preboot/Cryptexes is mode 777, and what the
# system PATH reaches through it carries sunlnk: read 2026-11-16.) A child not found or not read keeps it.
_fa_c3_keep() {   # LINES
  local y c k f n s=""
  local -a ch
  while IFS= read -r y; do
    [ -n "$y" ] || continue
    ch=(); c=$'\n'
    if [ "$y" != / ] && [ "$(uname -s 2>/dev/null)" = Darwin ]; then
      for k in "$r" ${a[@]+"${a[@]%/}"} ${ups[@]+"${ups[@]}"} ${upl[@]+"${upl[@]}"} ${lt[@]+"${lt[@]}"} ${lh[@]+"${lh[@]}"} ${m[@]+"${m[@]}"} ${mq[@]+"${mq[@]}"}; do
        case "$k" in "$y"/?*) k="${k#"$y"/}"; k="$y/${k%%/*}"; case "$c" in *$'\n'"$k"$'\n'*) ;; *) c="$c$k"$'\n'; ch[${#ch[@]}]="$k" ;; esac ;; esac
      done
    fi
    if [ ${#ch[@]} -gt 0 ]; then
      [ -n "$s" ] || { s=off; case "$(csrutil status 2>/dev/null)" in *enabled*) s=on ;; esac; }
      f="$(stat -f '%Sf' -- "${ch[@]}" 2>/dev/null)"; n=0
      while IFS= read -r k; do case ",$k," in *,sunlnk,*|*,schg,*) n=$((n + 1)) ;; *,restricted,*) [ "$s" != on ] || n=$((n + 1)) ;; esac; done <<EOF
$f
EOF
      [ "$n" -eq ${#ch[@]} ] && continue
    fi
    printf '%s\n' "$y"
  done <<EOF
$1
EOF
}
