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
# felix_changed_paths lives in resolve.sh, which every hook and the CLI source
# first. Sourced here too rather than assumed: a lib whose helper is missing
# returns an empty path list, which reads as "nothing changed" and silently
# stops enforcing. That is the same shape as a test that is green because it
# cannot reach the branch it names, and it cost 15 assertions to notice.
if ! command -v felix_changed_paths >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh"
fi

# Same idiom, and the same argument one notch stronger: what the probe library
# contributes to felix_merge_blockers is a REFUSAL, and a caller that forgot the
# import would lose it. The guard below still stands for the case this cannot
# fix — an engine shipped without the file at all — which fails closed rather
# than passing quietly.
if ! command -v felix_probes_run >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/probes.sh" 2>/dev/null
fi

FELIX_ESCAPE_SCAN="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/../bin" 2>/dev/null && pwd)/secret-scan"

# Enforcing tables: the files that decide what stops. Shrinking one is the edit
# that cannot be checked by the thing it shrank, because a green produced by a
# narrowed judge certifies itself. Named by shape, not by project.
FELIX_ESCAPE_TABLES='risk.tsv evidence.tsv deny.tsv project.json probes.tsv ecosystem.tsv'

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

  hunk="$( { git -C "$root" diff -U0 "$base...HEAD" -- "$f" 2>/dev/null
             git -C "$root" diff -U0 --cached -- "$f" 2>/dev/null
             git -C "$root" diff -U0 -- "$f" 2>/dev/null
           } | grep -E '^[-+]' | grep -vE '^(\+\+\+|---)')"
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

# Did the number of lines matching a pattern go down?
#
# Reached by a `confine` written as `count:<pattern>`. A confine always names
# what must still be true for the row not to fire; the prefix says how to read
# it. Bare means "every changed line looks like this". `count:` means "there are
# at least as many of these as there were".
#
# Spelled in the value rather than inferred from the channel. Inferring it was
# tried first and made one column mean two things depending on a different
# column, which is unreadable in a table somebody edits by hand.
#
# Counting rather than comparing identity, because a verifier is judged by how
# much it checks and not by which lines it is written on. Comparing identity
# fires on every refactor and on most ordinary edits, and a stop that fires
# constantly is one people learn to route around — which is worse than no stop,
# since it also teaches them to route around the ones that matter.
_felix_escape_fewer() {
  local root="$1" base="$2" f="$3" pattern="$4" before after
  before="$(git -C "$root" show "$base:$f" 2>/dev/null | grep -cE "$pattern")"
  after="$( felix_file_at "$root" HEAD "$f" | grep -cE "$pattern")"
  [ "${after:-0}" -lt "${before:-0}" ]
}

# Non-comment, non-blank lines present at base and gone at HEAD.
#
# Static blobs on both sides, never two live runs. Running the gate twice to
# compare is nondeterministic against the plugin cache and the two runs clobber
# each other's log; a comparison whose inputs move is not a comparison.
#
# Trailing commas are stripped before comparing, and that is not cosmetic. JSON
# has no trailing comma, so adding a key rewrites the line above it — meaning a
# literal comparison reads every addition to project.json as a removal and fires
# on the most ordinary edit there is. Caught on the commit that declared
# `consumers`, which added two keys and removed nothing. A genuine removal takes
# its whole line with it and is still caught.
_felix_escape_lines() {
  felix_file_at "$1" "$2" "$3" \
    | grep -vE '^[[:space:]]*(#|$)' \
    | sed -E 's/[[:space:]]*,[[:space:]]*$//' \
    | LC_ALL=C sort -u
}

_felix_escape_shrank() {
  local root="$1" base="$2" f="$3" before after
  before="$(_felix_escape_lines "$root" "$base" "$f")"
  [ -n "$before" ] || return 1
  after="$(_felix_escape_lines "$root" HEAD "$f")"
  [ -n "$(comm -23 <(printf '%s\n' "$before") <(printf '%s\n' "$after"))" ]
}

felix_escapes() {
  local proj="$1" base="$2" root="$3" home="${4:-}"
  local paths added f tier kind pattern reason channel confine reviewed=""

  # Before any channel, because a base this repository cannot resolve makes the
  # whole scan unanswerable rather than empty. felix_changed_paths swallows the
  # git error, so the `[ -n "$paths" ]` line below used to return "no escapes"
  # for a branch adding a workflow — `execute`, the one channel risk.tsv's own
  # header calls unconditional — and felix merge printed "nothing in it escaped
  # the tree". The same emptiness cleared every evidence row to n/a.
  #
  # Latent while both governed repositories sit on `main`; live on a --base
  # typo, on a default branch named `master` or `trunk`, on a clone with no
  # local `main`, and on the next governed project. Only a clean tree shows it,
  # because a dirty one still yields a working-tree diff — and a clean tree is
  # what felix merge requires, so that is not a mitigation.
  #
  # `unknown` is a reserved channel, not a risk.tsv one: no table can declare
  # it, so nothing can demote it, and neither `reviewed` nor a confine clause
  # reaches it. Callers must route it away from the founder — it is a typo, not
  # a decision about writing outside the tree.
  if [ -n "$base" ] && ! felix_base_resolves "$root" "$base"; then
    printf 'unknown\t%s\tthis base names nothing here, so nothing was scanned; no channel was consulted\n' "$base"
    return 0
  fi

  paths="$(felix_changed_paths "$root" "$base")"
  [ -n "$paths" ] || return 0

  added="$(felix_added_lines "$root" "$base")"

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

  # One lookup for the whole diff. `reviewed` is the only channel a verdict can
  # clear, and only a passing one for this exact tree — see lib/review.sh for
  # why this is the single place a model's output permits rather than restricts.
  if [ -n "$home" ] && command -v felix_review_passed >/dev/null 2>&1 \
       && command -v felix_tree_id >/dev/null 2>&1; then
    felix_review_passed "$home" "$proj" "$(felix_tree_id "$root" "$home" 2>/dev/null)" \
      && reviewed=pass
  fi

  # Project-declared escapes: a risk.tsv row carrying a channel. A row with no
  # channel is advisory — it sets a tier and stops nothing — which is what every
  # table written before this column existed is, and they must keep working.
  [ -f "$proj/risk.tsv" ] || return 0
  while IFS=$'\t' read -r tier kind pattern reason channel confine; do
    [ -n "${tier:-}" ] || continue
    [ -n "${channel:-}" ] && [ "${channel}" != "-" ] || continue
    [ "${kind:-}" = "path" ] || continue
    # `unknown` is the engine's word for "nothing was scanned", and every caller
    # keys its whole explanation off it — felix merge says nothing was compared
    # and that no finding above describes the branch. A table declaring it would
    # make a path rule that DID fire render as a scan that never ran, which is
    # the same false all-clear one layer up.
    #
    # Renamed rather than skipped. Skipping would silence a row a project wrote
    # deliberately, and clause 2 of the constitution runs the other way: a table
    # may add to the escapes and may never declare one away. So it still blocks,
    # still escalates, and merely cannot wear the reserved name. Enforced rather
    # than documented, because a convention nothing checks is one the next table
    # anybody writes will break.
    [ "$channel" = "unknown" ] && channel="declared-unknown"
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      printf '%s' "$f" | grep -qE "$pattern" || continue
      [ "$channel" = "reviewed" ] && [ "$reviewed" = "pass" ] && continue
      case "${confine:-}" in
        count:*) _felix_escape_fewer "$root" "$base" "$f" "${confine#count:}" || continue ;;
        *)       _felix_escape_confined "$root" "$base" "$f" "${confine:-}" && continue ;;
      esac
      printf '%s\t%s\t%s\n' "$channel" "$f" "$reason"
    done <<EOF2
$paths
EOF2
  done <<EOF
$(grep -vE '^[[:space:]]*(#|$)' "$proj/risk.tsv")
EOF
}

# Everything standing between this branch and a merge Felix performs itself.
#
# Emits: kind <TAB> subject <TAB> reason. Empty means merge.
#
# Computed entirely from the working tree, the diff and the receipt, so it
# refuses with no network and no credentials. A merge command that learns its
# own preconditions from the network cannot refuse offline, and offline is
# exactly when somebody is most likely to reach for it.
#
# Three kinds, and they are not the same kind of thing:
#
#   escape      merging writes outside the tree. A founder decision.
#   unverified  no green receipt for this exact tree. Run the gate.
#   evidence    the change owes a test. That is Felix's work, not a queue item
#               for anybody — the charter calls handing it back a defect — but
#               it is still a blocker, because merging first would ship the
#               unproven thing and the debt would never be collected.
# What a merge is standing on: the branch it would merge, the commit that branch
# points at, and the identity of the tree every verdict below is computed from.
#
# It exists to be compared with itself. `felix merge` runs for about a third of
# a second and shares a working copy with whoever else has a terminal open in
# it, and all three of these can move inside that. Reading them once at the
# start and once again immediately before the merge turns "somebody checked out
# another branch while this ran" from an ungated merge reported as verified into
# a refusal — which is how the rest of this file already behaves.
#
# The tree id is included rather than the branch alone: a peer can leave the
# branch and the commit alone and still edit an uncommitted file, and the
# receipt that was just accepted describes a tree that no longer exists.
felix_merge_checkout() {
  local root="$1" home="${2:-}" tid=""
  command -v felix_tree_id >/dev/null 2>&1 && tid="$(felix_tree_id "$root" "$home" 2>/dev/null)"
  printf '%s\t%s\t%s\n' \
    "$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null)" \
    "$(git -C "$root" rev-parse HEAD 2>/dev/null)" \
    "$tid"
}

felix_merge_blockers() {
  local proj="$1" base="$2" root="$3" home="$4"
  local tid receipt line

  felix_escapes "$proj" "$base" "$root" "$home" | while IFS=$'\t' read -r ch path reason; do
    [ -n "${ch:-}" ] || continue
    # `unknown` blocks like everything else here, and is deliberately not an
    # escape. cmd_merge counts escapes as founder escalations — interruptions
    # per session is the declared objective — and tells the reader that merging
    # writes outside the tree and only they can decide that. An unresolvable
    # base is neither: nobody has to decide a typo, and Felix owes the fix.
    # Reporting it as an escape would inflate the one number this project steers
    # by, with the one kind of event that should never reach a person.
    case "$ch" in
      unknown) printf 'unknown\t%s\t%s\n' "$path" "$reason" ;;
      *)       printf 'escape\t%s\t%s: %s\n' "$ch" "$path" "$reason" ;;
    esac
  done

  tid="$(felix_tree_id "$root" "$home" 2>/dev/null)" || tid=""
  receipt="$(felix_verify_receipt "$root" "$home" 2>/dev/null)"
  if [ -z "$tid" ] \
       || [ "$(printf '%s' "$receipt" | cut -f1)" != "$tid" ] \
       || [ "$(printf '%s' "$receipt" | cut -f2)" != "green" ]; then
    printf 'unverified\ttree\tno green receipt for this exact tree; run felix gate\n'
  fi

  felix_evidence_check "$proj" "$base" "$root" 2>/dev/null \
    | while IFS=$'\t' read -r status name reason; do
        [ "${status:-}" = "gap" ] || continue
        printf 'evidence\t%s\t%s\n' "$name" "$reason"
      done

  # probes: the merge boundary is the third place the empty case is refused,
  # and the strongest one Felix reaches without a network. A branch may not
  # land while the project reads nothing from reality, or while a probe cannot
  # see a surface a witness proves is there.
  #
  # Fails closed on a missing library rather than skipping. The `reviewed`
  # lookup above guards itself with command -v because what it does is WIDEN —
  # skipping it withholds a clearance, which is safe. Skipping this would drop
  # a blocker, and an engine that cannot evaluate probes has not established
  # that there is nothing to block on; it has established nothing.
  if ! command -v felix_probes_run >/dev/null 2>&1; then
    printf 'probes\tengine\tthe probe library is not loaded, so nothing was asked of reality\n'
  elif [ ! -f "$proj/probes.tsv" ]; then
    printf 'probes\ttable\tthis project asks reality nothing; write %s/probes.tsv\n' "$proj"
  elif [ -z "$(felix_probe_rows "$proj")" ]; then
    printf 'probes\ttable\t%s/probes.tsv declares no probe, which is a shelf with nothing on it\n' "$proj"
  else
    felix_probes_run "$proj" "$root" | felix_probes_blocking \
      | while IFS= read -r line; do
          [ -n "$line" ] || continue
          printf 'probes\t%s\t%s: %s\n' \
            "$(printf '%s\n' "$line" | cut -f1)" \
            "$(printf '%s\n' "$line" | cut -f3)" \
            "$(printf '%s\n' "$line" | cut -f5)"
        done
  fi
}
