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

# felix_adopt_capability <project-dir> <capability> <templates-dir> <repo-slug>
# Prints "<stack-rows-added> <setup-steps-added>". Returns 1 if already declared,
# and 2, printing and writing nothing, when the list could not be read or written.
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
  { printf '%s\n' "$cap" >> "$list"; } 2>/dev/null || return 2

  # Create the manifests when a project never had them. Skipping the backfill
  # because a file is missing would leave the capability recorded and its
  # consequences invisible, which is the failure this exists to prevent.
  local added_stack=0 added_setup=0
  mkdir -p "$proj/setup"
  [ -f "$proj/stack.tsv" ] || printf '# kind\tname\tsource\trisk\tcapability\tgrounding\n' > "$proj/stack.tsv"
  [ -f "$proj/setup.tsv" ] || printf '# id\ttitle\tcapability\tcheck\n' > "$proj/setup.tsv"

  if [ -f "$tpl/catalog.tsv" ]; then
    while IFS=$'\t' read -r k n src r c _kw; do
      [ "${c:-}" = "$cap" ] || continue
      grep -qF "	$n	" "$proj/stack.tsv" 2>/dev/null && continue
      # DECLARED: the catalogue tier is a person's judgment, and the engine
      # writing the row down does not make it the engine's.
      printf '%s\t%s\t%s\t%s\t%s\tDECLARED\n' "$k" "$n" "$src" "$r" "$c" >> "$proj/stack.tsv"
      added_stack=$((added_stack+1))
    done < <(grep -vE '^\s*(#|$)' "$tpl/catalog.tsv")
  fi

  if [ -f "$tpl/setup.tsv" ]; then
    while IFS=$'\t' read -r id title c chk; do
      [ "${c:-}" = "$cap" ] || continue
      grep -qE "^$id	" "$proj/setup.tsv" 2>/dev/null && continue
      printf '%s\t%s\t%s\t%s\n' "$id" "$title" "$c" "${chk//\{\{REPO\}\}/$slug}" >> "$proj/setup.tsv"
      [ -f "$tpl/setup/$id.md" ] && \
        sed "s|{{REPO}}|$slug|g" "$tpl/setup/$id.md" > "$proj/setup/$id.md"
      added_setup=$((added_setup+1))
    done < <(grep -vE '^\s*(#|$)' "$tpl/setup.tsv")
  fi

  printf '%s %s' "$added_stack" "$added_setup"
}
