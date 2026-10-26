# Lookalike gates.
#
# Moved out of detect.sh on 2026-10-25, whole and unchanged, when that file
# needed the room (audit b19). detect.sh sources this file, so every caller that
# had the function from detect.sh still has it from there.

# Scripts in the checkout that look like a gate and are not the gate this
# project declares.
#
# From a real failure. An untracked, day-stale, strictly weaker copy of a gate
# sat inside a governed repo, and it was the file physically in front of any
# session that looked around. A session ran it all day and reported green from a
# gate missing a check. It found out only because the completion gate nagged it
# into running the real one.
#
# A gate with a lookalike is not a gate. It is a coin flip on which file
# somebody reaches for, and the wrong side of the flip reports success — the
# same silent shape as a check that passes by finding nothing.
#
# Deliberately narrow. Executable only, because a broad match flags every note
# with the word in its name. Reports and never deletes: a rival can be
# legitimate, a fast subset a person runs by hand, and Felix does not get to
# decide that.
_felix_rival_gates() {
  local root="$1" proj="$2" gate="$3" state f base note
  { git -C "$root" ls-files            2>/dev/null | sed 's/^/tracked\t/'
    git -C "$root" ls-files --others --exclude-standard 2>/dev/null \
      | sed 's/^/untracked\t/'
  } | while IFS=$'\t' read -r state f; do
      [ -n "${f:-}" ] || continue
      base="${f##*/}"
      # Two ways a file here is a lookalike. Its name says it gates something,
      # or Felix already holds the authoritative copy under that exact name.
      #
      # The second is the real rule and was learned the day the first one was
      # not enough: deleting the stale scripts/gate.sh left scripts/prepush.sh
      # sitting beside it, an untracked copy of a file Felix holds, identical
      # that morning and free to drift by the afternoon. Matching on the word
      # "gate" could never have seen it. The name was never the point.
      held=0; [ -f "$proj/$base" ] && held=1
      if [ "$held" -eq 0 ]; then
        case "$base" in *gate*|*verify*|*check*) ;; *) continue ;; esac
      fi
      [ -x "$root/$f" ] || continue

      # The declared gate itself, when the project stores it in Felix's home and
      # the home happens to be this checkout. Same file, not a rival.
      [ "$root/$f" -ef "$proj/$gate" ] 2>/dev/null && continue

      # Felix's own per-project storage holds every governed project's gate. In
      # any checkout that IS Felix, those are its records, not rivals.
      #
      # Tested on the repository, not on the path. This was a prefix match
      # against $FELIX_HOME_DIR, which is true only when standing in the home
      # itself: from a worktree of Felix the root is elsewhere, the prefix never
      # matched, and doctor reported every governed project's stored gate as a
      # rival — then called one of them "differs from the copy Felix holds",
      # having compared it against another project's file on a shared basename.
      case "$f" in
        projects/*) felix_same_repo "$root" "${FELIX_HOME_DIR:-/nonexistent}" && continue ;;
      esac

      # A project may declare a repo-relative command as its gate. That path is
      # the gate, so naming it here would report the gate as its own rival.
      case " $gate " in *"$f"*) continue ;; esac

      # Compared against whichever copy Felix actually holds: the file of the
      # same name when there is one, otherwise the declared gate.
      local mine=""
      [ "$held" -eq 1 ] && mine="$proj/$base"
      [ -z "$mine" ] && [ -x "$proj/$gate" ] && mine="$proj/$gate"

      if [ -n "$mine" ]; then
        if cmp -s "$root/$f" "$mine"; then
          note="identical today, and nothing keeps it that way"
        else
          note="differs from the copy Felix holds"
        fi
      else
        note="this project gates with a command, not a file"
      fi
      printf '%s\t%s\t%s\n' "$state" "$f" "$note"
    done
}
