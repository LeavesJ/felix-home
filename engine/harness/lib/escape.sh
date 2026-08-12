# What a revert cannot undo.
#
# A tier used to be a function of which file you touched. That is what sent a
# one-line dependency-floor correction to the founder and left it there for a
# day: `pyproject.toml` was yellow because the row said "dependency change", a
# premise about consumers that the path could not carry and nobody re-read.
#
# The question a stop has to answer is not "is this file important". It is
# whether merging writes something outside this tree that `git revert` cannot
# reach. Everything a revert undoes, Felix merges and reports. Everything else
# stops, and the reason it stops is a channel with a name.
#
# Emits: channel <TAB> path <TAB> reason, one line per escape.
# Empty output means nothing escaped and Felix may merge.
#
# Two properties this file exists to hold:
#
#   - **Channels are engine constants.** A project may add escapes through its
#     own table and may never declare one away. A stop a project can argue with
#     is not a stop; it is a default. The engine still names no project — it
#     names states of the world, and `disclose` means the same thing in a Rust
#     repository as in this one.
#   - **Failing to demote is safe; failing to stop is not.** Every uncertain
#     path here escapes. A confinement test that cannot parse a diff withholds
#     the demotion and the row fires, which costs a founder one look. The
#     opposite mistake costs a secret.

# Resolved from this file rather than from PWD, because escapes are computed
# while standing in the governed checkout, never in the harness.
FELIX_ESCAPE_SCAN="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/../bin" 2>/dev/null && pwd)/secret-scan"

# Enforcing tables: the files that decide what stops. Shrinking one is the edit
# that cannot be checked by the thing it shrank, because a green produced by a
# narrowed judge certifies itself. Named by shape, not by project.
FELIX_ESCAPE_TABLES='risk.tsv evidence.tsv deny.tsv project.json'

# Merging this causes a job to run holding whatever secrets the repository has.
# The revert restores the YAML. It does not un-run the job or un-read the key.
FELIX_ESCAPE_EXECUTE='^\.github/(workflows|actions)/'

# Rows already written are not restored by reverting the code that wrote them.
FELIX_ESCAPE_DURABLE_PATH='(^|/)(migrations|alembic)(/|$)|^prisma/migrations/'
FELIX_ESCAPE_DURABLE_ADDED='(DROP TABLE|TRUNCATE |DELETE FROM [^W]*$)'

# Whether every changed line in a file stays inside what a row said was safe.
#
# Returns 0 when the change is confined and the row should NOT fire. The
# manifest case is the reason this exists: `pyproject.toml` genuinely is
# dangerous, because it configures the gate as well as declaring dependencies,
# and one added `addopts` line deletes tests without touching a test. So the row
# stays and stops firing only for the shape it was demoted for.
#
# Package-name equality is checked alongside the line pattern. Without it,
# swapping one dependency for another passes the constraint regex while changing
# what the code actually imports.
_felix_escape_confined() {
  local root="$1" base="$2" f="$3" confine="$4" hunk plus minus
  [ -n "$confine" ] && [ "$confine" != "-" ] || return 1

  hunk="$(git -C "$root" diff -U0 "$base...HEAD" -- "$f" 2>/dev/null \
          | grep -E '^[-+]' | grep -vE '^(\+\+\+|---)')"
  [ -n "$hunk" ] || return 1

  # Any line outside the confine means the row fires.
  printf '%s\n' "$hunk" | grep -qvE "$confine" && return 1

  plus="$(printf '%s\n' "$hunk"  | grep '^+' \
          | sed -E 's/^\+[^A-Za-z0-9]*([A-Za-z0-9._-]+).*/\1/' | LC_ALL=C sort)"
  minus="$(printf '%s\n' "$hunk" | grep '^-' \
          | sed -E 's/^-[^A-Za-z0-9]*([A-Za-z0-9._-]+).*/\1/' | LC_ALL=C sort)"
  [ "$plus" = "$minus" ] || return 1
  return 0
}

# Non-comment, non-blank lines present at base and gone at HEAD.
#
# Static blobs on both sides, never two live runs. Running the gate twice to
# compare is nondeterministic against the plugin cache and the two runs clobber
# each other's log; a comparison whose inputs move is not a comparison.
_felix_escape_shrank() {
  local root="$1" base="$2" f="$3" before after
  before="$(git -C "$root" show "$base:$f" 2>/dev/null \
            | grep -vE '^[[:space:]]*(#|$)' | LC_ALL=C sort -u)"
  [ -n "$before" ] || return 1
  after="$(git -C "$root" show "HEAD:$f" 2>/dev/null \
           | grep -vE '^[[:space:]]*(#|$)' | LC_ALL=C sort -u)"
  [ -n "$(comm -23 <(printf '%s\n' "$before") <(printf '%s\n' "$after"))" ]
}

felix_escapes() {
  local proj="$1" base="$2" root="$3"
  local paths added f tier kind pattern reason channel confine

  paths="$(git -C "$root" diff --name-only "$base...HEAD" 2>/dev/null)"
  [ -n "$paths" ] || paths="$(git -C "$root" diff --name-only "$base" 2>/dev/null)"
  [ -n "$paths" ] || return 0

  added="$(git -C "$root" diff "$base...HEAD" 2>/dev/null | grep '^+' | grep -v '^+++' || true)"

  # disclose. Already tuned against real false positives and already in the
  # gate, so this is the same verdict the gate reaches, not a second opinion.
  if [ -x "$FELIX_ESCAPE_SCAN" ] \
       && ! ( cd "$root" && "$FELIX_ESCAPE_SCAN" "$base" >/dev/null 2>&1 ); then
    printf 'disclose\tADDED-LINES\ta credential in the added lines; history keeps the blob\n'
  fi

  while IFS= read -r f; do
    [ -n "$f" ] || continue

    printf '%s' "$f" | grep -qE "$FELIX_ESCAPE_EXECUTE" \
      && printf 'execute\t%s\tmerging runs this job holding the repository secrets\n' "$f"

    printf '%s' "$f" | grep -qE "$FELIX_ESCAPE_DURABLE_PATH" \
      && printf 'durable\t%s\trows already written are not restored by a revert\n' "$f"

    # verifier, for the tables that decide what stops. Adding is free.
    case " $FELIX_ESCAPE_TABLES " in
      *" ${f##*/} "*)
        _felix_escape_shrank "$root" "$base" "$f" \
          && printf 'verifier\t%s\tthis decides what stops, and the change removes from it\n' "$f" ;;
    esac
  done <<EOF
$paths
EOF

  [ -n "$added" ] && printf '%s' "$added" | grep -qE "$FELIX_ESCAPE_DURABLE_ADDED" \
    && printf 'durable\tADDED-LINES\tdestructive SQL in the added lines\n'

  # Project-declared escapes: a risk.tsv row carrying a channel. A row with no
  # channel is advisory — it sets a tier and stops nothing — which is what every
  # table written before this column existed is, and they must keep working.
  [ -f "$proj/risk.tsv" ] || return 0
  while IFS=$'\t' read -r tier kind pattern reason channel confine; do
    [ -n "${tier:-}" ] || continue
    [ -n "${channel:-}" ] && [ "${channel}" != "-" ] || continue
    [ "${kind:-}" = "path" ] || continue
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      printf '%s' "$f" | grep -qE "$pattern" || continue
      _felix_escape_confined "$root" "$base" "$f" "${confine:-}" && continue
      printf '%s\t%s\t%s\n' "$channel" "$f" "$reason"
    done <<EOF2
$paths
EOF2
  done <<EOF
$(grep -vE '^[[:space:]]*(#|$)' "$proj/risk.tsv")
EOF
}
