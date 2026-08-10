# Project memory: the devlog, the lessons, the handoff.
#
# The guidebook's promotion ladder (p4) routes a one-off to the handoff, a
# recurring lesson to the lessons file, a repeated rule violation into the
# constitution, and a repeatable procedure into a skill.
#
# Most projects have none of these files, and the reason is friction rather than
# disagreement: everyone believes in a devlog and nobody opens an editor at the
# end of a session to write one. So the first job here is not analysis, it is
# making the entry one command, with the branch and commit filled in.
#
# Promotion detection is a prompt, never a conclusion. Recurrence is a hint that
# something might be a lesson; deciding whether it is durable takes judgment, and
# a tool that auto-promoted would fill the lessons file with noise and teach
# people to stop reading it. The value of a lessons file is entirely in its
# signal-to-noise, so the failure mode of writing too much is the fatal one.

_felix_mem_stamp() {
  local root="$1"
  printf '%s %s %s' \
    "$(date +%Y-%m-%d)" \
    "$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')" \
    "$(git -C "$root" rev-parse --short HEAD 2>/dev/null || echo '?')"
}

felix_mem_log() {
  local proj="$1" root="$2" text="$3"
  mkdir -p "$proj/memory"
  printf '\n## %s\n\n%s\n' "$(_felix_mem_stamp "$root")" "$text" >> "$proj/memory/DEVLOG.md"
}

felix_mem_lesson() {
  local proj="$1" root="$2" text="$3"
  mkdir -p "$proj/memory"
  printf '\n- **%s** %s\n' "$(date +%Y-%m-%d)" "$text" >> "$proj/memory/lessons.md"
}

# Regenerate the handoff from what git already knows. A handoff written by hand
# is a handoff written optimistically: it records what someone meant to have
# done. This records the branch, the head, what is uncommitted, and the command
# to pick up with.
felix_mem_handoff() {
  local proj="$1" root="$2" gate="$3"
  mkdir -p "$proj/memory"
  {
    printf '# Handoff\n\nRegenerated %s. Anything below is the state of the tree,\nnot a summary of intent.\n\n' "$(date +%Y-%m-%d)"
    printf '## Where\n\n'
    printf -- '- branch: `%s`\n' "$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null)"
    printf -- '- head: `%s`\n' "$(git -C "$root" log -1 --format='%h %s' 2>/dev/null)"
    printf -- '- tree: `%s`\n' "$root"
    printf '\n## Uncommitted\n\n'
    local dirty; dirty="$(git -C "$root" status --short 2>/dev/null | grep -v '^??' || true)"
    if [ -n "$dirty" ]; then printf '```\n%s\n```\n' "$dirty"
    else printf 'Nothing. The tree is clean.\n'; fi
    printf '\n## Recent\n\n```\n%s\n```\n' \
      "$(git -C "$root" log -8 --format='%h %ad %s' --date=short 2>/dev/null)"
    printf '\n## Next\n\n'
    printf -- '- verify: `%s`\n' "${gate:-declare a gate in project.json}"
    printf -- '- what was in progress: _fill this in; it is the one part git cannot tell you_\n'
  } > "$proj/memory/SESSION_HANDOFF.md"
}

# A mistake the gate caught, recorded without anyone deciding it was worth
# recording. Judgement at write time is the wrong shape: it asks for a decision
# at the exact moment someone is trying to finish something else, so it does not
# happen, and the lesson is lost while the file stays tidy.
#
# Write cheaply, consolidate on a cadence. The maintenance routine does the
# curating with the whole file in view, which is when the judgement is actually
# available.
felix_mem_mistake() {
  local proj="$1" root="$2" what="$3"
  mkdir -p "$proj/memory"
  printf '%s\t%s\t%s\t%s\n' \
    "$(date +%Y-%m-%d)" \
    "$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')" \
    "$(git -C "$root" rev-parse --short HEAD 2>/dev/null || echo '?')" \
    "$what" >> "$proj/memory/mistakes.log"
}

# What the gate keeps catching. A far better promotion signal than counting words:
# a check that fails repeatedly is a habit, and a habit is what a lesson is for.
felix_mem_recurring_mistakes() {
  local proj="$1" min="${2:-2}"
  [ -f "$proj/memory/mistakes.log" ] || return 0
  cut -f4 "$proj/memory/mistakes.log" 2>/dev/null \
    | tr ' ' '\n' | grep -v '^$' \
    | sort | uniq -c | sort -rn \
    | while read -r n term; do
        [ "${n:-0}" -ge "$min" ] || break
        printf '%s\t%s\n' "$n" "$term"
      done
}

# Terms recurring across distinct devlog entries and absent from the lessons.
# Crude frequency counting, stated as such wherever it is printed.
felix_mem_promotable() {
  local proj="$1" min="${2:-3}"
  [ -f "$proj/memory/DEVLOG.md" ] || return 0
  local lessons=""
  [ -f "$proj/memory/lessons.md" ] && lessons="$(tr '[:upper:]' '[:lower:]' < "$proj/memory/lessons.md")"
  # Count the number of distinct entries a term appears in, not how often it
  # appears. Fifty mentions inside one entry is one story being told at length;
  # the promotion signal is a thing that keeps coming back on different days.
  awk '
    /^## / { entry++ }
    {
      line = tolower($0)
      gsub(/[^a-z0-9_-]+/, " ", line)
      n = split(line, w, " ")
      for (i = 1; i <= n; i++) {
        t = w[i]
        if (length(t) < 5) continue
        if (t ~ /^[0-9-]+$/) continue
        key = t SUBSEP entry
        if (!(key in seen)) { seen[key] = 1; entries[t]++ }
      }
    }
    END { for (t in entries) if (entries[t] >= MIN) printf "%d\t%s\n", entries[t], t }
  ' MIN="$min" "$proj/memory/DEVLOG.md" \
    | grep -vE $'\t(about|after|again|against|because|before|being|between|could|during|every|first|found|from|going|instead|into|might|other|rather|really|should|since|still|than|that|their|them|then|there|these|they|thing|think|this|those|through|under|until|were|what|when|where|which|while|with|would|your|commit|change|changes|added|update|updated|files|file|version|branch|already|actually|something|because|makes|making|which|there|where|point|second)$' \
    | sort -rn \
    | while IFS=$'\t' read -r n term; do
        [ -n "${term:-}" ] || continue
        case "$lessons" in *"$term"*) continue ;; esac
        printf '%s\t%s\n' "$n" "$term"
      done | head -12
}
