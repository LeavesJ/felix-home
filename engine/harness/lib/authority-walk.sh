# Condition e's walk of the paths the code is reached through (W6 e, lib/authority.sh): the directories above a
# path, along each hop of a link; the physical path a link leads to; and which directories above the code still
# offend. Moved out of lib/authority.sh in 0.49.356 to keep that file under 500 lines; felix sources this after it.
# Each function reads and writes the caller's locals where it says so (_fa_code_offenders_raw's seen, ups, upl and
# the path lists), as it did inline. Bash 3.2. No project is named here.

# C3. Prints each directory above DIR up to /, along DIR as written and its physical path (cd -P), one a line (a
# path with a newline is read as two). A part on the way that is a link adds its target, one hop, printed and
# walked too, since cd -P skips the middle of a chain (0.49.356, review trust 3). Each link is followed once; one
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
# H11 (0.49.356). The physical path of what PATH, a link, points at (at most 40 hops); 1 when it leads nowhere.
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
# C3 (0.49.356). Prints each of LINES, a directory above the code that offends, unless (macOS) each of its
# children on the code's paths can be renamed or removed by no worker: flag sunlnk or schg (root's alone to
# clear), or restricted while SIP is on. As the sticky bit, that keeps a login that can write the directory from
# replacing what the code is reached through. (/System/Volumes/Preboot/Cryptexes is mode 777, and what the
# system PATH reaches through it carries sunlnk: read 2026-11-16.) Its children are the paths the walk read
# whose parent is it by device and inode, however each was written: through a link, in another letter case
# (pwd -P keeps the case typed), or along a physical path (security review of b417a831). The walk prints each
# directory above every path it reads, along each hop, so each name the kernel looks up there is one of them.
# It stays an offender when it is a link, when a child is not there or not read, when a child is named . or ..,
# when no child is found, and when the parent of any path read could not be read. SIP is on only when the first
# line of csrutil status is "System Integrity Protection status: enabled."; anything else is off.
_fa_c3_keep() {   # LINES
  local y yi k d i n c f s="" u=""
  local -a kp=() ki=() kd=() ch=()
  while IFS= read -r y; do
    [ -n "$y" ] || continue
    ch=(); c=$'\n'; n=-1
    if [ "$y" != / ] && [ -d "$y" ] && [ ! -L "$y" ] && [ "$(/usr/bin/uname -s 2>/dev/null)" = Darwin ]; then
      if [ -z "$u" ]; then
        u=ok
        for k in "$r" ${a[@]+"${a[@]}"} ${ups[@]+"${ups[@]}"} ${upl[@]+"${upl[@]}"} ${lt[@]+"${lt[@]}"} ${lh[@]+"${lh[@]}"} ${m[@]+"${m[@]}"} ${mq[@]+"${mq[@]}"}; do
          while :; do case "$k" in /) break ;; */) k="${k%/}" ;; *) break ;; esac; done
          case "$k" in /?*) ;; *) continue ;; esac
          d="${k%/*}"; [ -n "$d" ] || d=/
          [ -e "$d" ] || continue
          kp[${#kp[@]}]="$k"; kd[${#kd[@]}]="$d"
        done
        [ ${#kd[@]} -eq 0 ] || while IFS= read -r i; do ki[${#ki[@]}]="$i"; done <<EOF
$(/usr/bin/stat -L -f '%d:%i' -- "${kd[@]}" 2>/dev/null)
EOF
        [ ${#ki[@]} -eq ${#kd[@]} ] || u=no
      fi
      if [ "$u" = ok ] && yi="$(/usr/bin/stat -f '%d:%i' -- "$y" 2>/dev/null)" && [ -n "$yi" ]; then
        n=0
        for ((i = 0; i < ${#kp[@]}; i++)); do
          [ "${ki[$i]}" = "$yi" ] || continue
          k="${kp[$i]##*/}"
          case "$k" in .|..) n=-1; break ;; esac
          case "$c" in *$'\n'"$k"$'\n'*) ;; *) c="$c$k"$'\n'; ch[${#ch[@]}]="${y%/}/$k" ;; esac
        done
      fi
    fi
    if [ "$n" -eq 0 ] && [ ${#ch[@]} -gt 0 ]; then
      [ -n "$s" ] || { s=off; f="$(/usr/bin/csrutil status 2>/dev/null)"; [ "${f%%$'\n'*}" != "System Integrity Protection status: enabled." ] || s=on; }
      f="$(/usr/bin/stat -f '%Sf' -- "${ch[@]}" 2>/dev/null)"
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
