# Adopting a capability: record it, then bring in what it implies.
#
# Extracted because two callers need it and they are genuinely different: the
# CLI, where a person is deciding, and the session hook, where nobody is. The
# hook is the reason this is automatic. Detection surfacing a new surface and
# waiting to be told to act meant the surface stayed unhandled for exactly as
# long as nobody read the message.
#
# Adopting installs nothing. It records the capability and appends the catalogue
# rows and human steps gated on it, so `stack plan` and `setup` start telling the
# truth about what this project now needs. Installing is still `stack apply`, and
# high-risk rows are still refused by every flag. That separation is what makes
# doing this unattended defensible: the plan changes, the machine does not.

# felix_end_line lives in resolve.sh, which the CLI and the session hook source
# first. Sourced here too rather than assumed: missing, every append below would
# be refused as unwritable and the backfill would write nothing.
if ! command -v felix_end_line >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh"
fi

# felix_adopt_capability <project-dir> <capability> <templates-dir> <repo-slug>
# Prints "<stack-rows-added> <setup-steps-added>". Returns 1 if already declared,
# and 2, printing nothing and writing no row, when the list could not be read or
# written. Returns 3, after the counts, when the capability was recorded but a
# row it implies could not be written; stderr names each one. A second adopt
# answers 1 and never retries them, so a caller that drops stderr must say 3.
felix_adopt_capability() {
  local proj="$1" cap="$2" tpl="$3" slug="${4:-}" list rc=2
  [ -n "$proj" ] && [ -n "$cap" ] || return 1
  list="$proj/capabilities"

  # 2026-10-01: the list is read and written only as felix_declared reads it,
  # as a regular file, and nothing below runs unless the capability was
  # recorded. This started with `touch`, which followed a link whose target
  # was gone and created the target, or failed when the target's directory was
  # gone too; then the grep and the append failed, and the rows below were
  # written all the same and the capability reported adopted while recorded
  # nowhere. A directory was appended to in vain the same way, and a pipe was
  # opened by the grep, which waited on it for a writer. Now anything at the
  # path that is not a regular file is 2 without being opened, and so is a
  # list whose read or append fails. Nothing at all is still an empty list,
  # which the append creates. The grep's status starts at 2 with the
  # redirection outside it, as in felix_declared, so a redirection that could
  # not be opened is not read as grep's 1, a list without the capability.
  if [ -e "$list" ] || [ -L "$list" ]; then
    [ -f "$list" ] || return 2
    { grep -qxF -- "$cap" "$list"; rc=$?; } 2>/dev/null
    [ "$rc" -eq 0 ] && return 1
    [ "$rc" -eq 1 ] || return 2
  fi
  # Also 2026-10-01: a hand-written `api` with no final newline took this
  # append as `apiobs`, so felix_declared lost both while the rows below were
  # written for `obs` all the same. Ended first; a list that cannot be ended
  # is a list that cannot be written, and is 2 the same way.
  felix_end_line "$list" || return 2
  { printf '%s\n' "$cap" >> "$list"; } 2>/dev/null || return 2

  # Create the manifests when a project never had them. Skipping the backfill
  # because a file is missing would leave the capability recorded and its
  # consequences invisible, which is the failure this exists to prevent.
  local added_stack=0 added_setup=0 missed=0
  mkdir -p "$proj/setup"
  # Seeded only where nothing is at the path. `[ -f ]` seeded through a link
  # whose target was gone, creating it, and waited forever on a pipe; now
  # anything that is not a regular file is left as it is, never opened below,
  # and every row for it refused (2026-10-01).
  [ -e "$proj/stack.tsv" ] || [ -L "$proj/stack.tsv" ] || printf '# kind\tname\tsource\trisk\tcapability\tgrounding\n' > "$proj/stack.tsv"
  [ -e "$proj/setup.tsv" ] || [ -L "$proj/setup.tsv" ] || printf '# id\ttitle\tcapability\tcheck\n' > "$proj/setup.tsv"

  if [ -f "$tpl/catalog.tsv" ]; then
    while IFS=$'\t' read -r k n src r c _kw; do
      [ "${c:-}" = "$cap" ] || continue
      # The duplicate check opens the file, and a pipe would hold it there.
      [ -f "$proj/stack.tsv" ] && grep -qF "	$n	" "$proj/stack.tsv" 2>/dev/null && continue
      # stack.tsv is seeded "Edit freely", so a last row with no newline is
      # ordinary; unended, this row would fuse onto it (2026-10-01). A row that
      # could not be put on a line of its own, or not written at all, is said
      # on stderr and not counted. It was counted whenever the append failed.
      #
      # DECLARED: the catalogue tier is a person's judgment, and the engine
      # writing the row down does not make it the engine's.
      if ! felix_end_line "$proj/stack.tsv" \
         || ! printf '%s\t%s\t%s\t%s\t%s\tDECLARED\n' "$k" "$n" "$src" "$r" "$c" >> "$proj/stack.tsv"; then
        printf 'felix: could not add %s to %s/stack.tsv\n' "$n" "$proj" >&2
        missed=$((missed+1))
        continue
      fi
      added_stack=$((added_stack+1))
    done < <(grep -vE '^\s*(#|$)' "$tpl/catalog.tsv")
  fi

  if [ -f "$tpl/setup.tsv" ]; then
    while IFS=$'\t' read -r id title c chk; do
      [ "${c:-}" = "$cap" ] || continue
      [ -f "$proj/setup.tsv" ] && grep -qE "^$id	" "$proj/setup.tsv" 2>/dev/null && continue
      # 2026-10-08: the runbook is written with `>`, which waited forever on a
      # pipe at its path, as session start does for every capability the
      # checkout grew, and wrote through a link whose target was gone. The step
      # is refused whole, row as well: a row left without its runbook makes the
      # next adopt skip the step, so the runbook would never be written.
      local rbwhat
      if [ -f "$tpl/setup/$id.md" ] && rbwhat="$(felix_not_regular "$proj/setup/$id.md")"; then
        printf 'felix: could not add %s to %s/setup.tsv: its runbook %s/setup/%s.md is %s\n' \
          "$id" "$proj" "$proj" "$id" "$rbwhat" >&2
        missed=$((missed+1))
        continue
      fi
      # The same for a hand-edited setup.tsv, and the runbook is not copied
      # for a step whose row was not written.
      if ! felix_end_line "$proj/setup.tsv" \
         || ! printf '%s\t%s\t%s\t%s\n' "$id" "$title" "$c" "${chk//\{\{REPO\}\}/$slug}" >> "$proj/setup.tsv"; then
        printf 'felix: could not add %s to %s/setup.tsv\n' "$id" "$proj" >&2
        missed=$((missed+1))
        continue
      fi
      # Its row is written by now, so a runbook that still fails, as under a
      # setup/ that is not a directory, is said, and the step counts as added
      # with something it implies left unwritten.
      if [ -f "$tpl/setup/$id.md" ] \
         && ! { sed "s|{{REPO}}|$slug|g" "$tpl/setup/$id.md" > "$proj/setup/$id.md"; } 2>/dev/null; then
        printf 'felix: added %s to %s/setup.tsv, but could not write its runbook %s/setup/%s.md\n' \
          "$id" "$proj" "$proj" "$id" >&2
        missed=$((missed+1))
      fi
      added_setup=$((added_setup+1))
    done < <(grep -vE '^\s*(#|$)' "$tpl/setup.tsv")
  fi

  printf '%s %s' "$added_stack" "$added_setup"
  [ "$missed" -eq 0 ] || return 3
}
