# _copy_content is defined here, at the head of the first part that calls it,
# and not in the driver: moved 2026-10-16 (contract C), when the driver's lib
# lines took it past 1040's 500 lines. This part is in _suite_preamble, so every
# copy of the driver keeps it.
# Every copy this suite takes of the real tree goes through here, and it copies
# CONTENT: what git tracks under the source, plus what is untracked and not
# ignored, because work not yet added is still work under test. What git ignores
# stays behind. `cp -R` copied a directory listing instead, residue included,
# and the fixtures below that commit such a copy as "main" and cut a cache entry
# from it then disagreed with themselves: measured 2026-09-19, a claude-flow
# hook had dropped .claude-flow/ into engine/harness — ignored, so git status
# stayed clean — and fifteen assertions failed, each leading with the judge and
# the plugin cache and carrying the directory's name only at the tail of a
# temporary path, which is where nobody reads. The mechanism, by experiment: the
# fixture's `git add -A` obeys the machine's GLOBAL excludes file, which named
# .claude-flow/, so the fixture's main left the stray out; the raw copy in the
# fixture's cache kept it; and the judge, which shuts the global file off on
# purpose, called the difference drift. A runner with no global excludes commits
# the stray on both sides and the judge, measured on that pair, reports nothing
# — so this was only ever red on a developer's machine. Production is not
# sensitive, measured at 0.49.122: felix_accepted_deploy_diff reads its source
# side from the commit, and felix_deploy_diff asks the repository's own ignore
# rules about the rest. It was sensitive once, and #86 is what ended that.
#
# --exclude-standard, global file included, deliberately: whatever this
# machine's git would refuse to add to a fixture is exactly what must not be
# carried into one.
#
# The git path is taken only when git TRACKS something under the source. "Is
# it inside a repository" is the wrong question, measured on the same day: the
# plugin cache, where a copy of this suite also sits, was inside a repository
# — a home directory under version control — that tracked none of it, and one ignore
# rule there would have listed an empty harness. Where git tracks nothing it
# has nothing to say, and the directory is copied whole, as it always was.
# A tracked file deleted from the working tree is listed by git and absent
# from disk, and it is skipped before tar is handed the list. Measured on
# bsdtar: tar does not stop on such a name — it archives the rest and exits
# non-zero — and under this suite's pipefail that exit becomes the copy's
# status, so a developer's unstaged deletion would read as a copy that
# failed. GNU tar was not there to measure; skipping means it is never asked.
_copy_content() {   # <source dir> <dest dir>: dest holds what source holds, less what git ignores
  local src="$1" dest="$2" f
  # An empty source would be copied as "/." (the 18:04 incident above
  # REAL_HARNESS's check), so a source that is not a directory copies nothing.
  [ -n "$src" ] && [ -d "$src" ] || {
    printf 'tests/run: _copy_content refused source [%s]: not a directory\n' "$src" >&2; return 1; }
  mkdir -p "$dest" || return 1
  if [ -n "$(git -C "$src" ls-files -c . 2>/dev/null | head -1)" ]; then
    ( cd "$src" && git ls-files -co --exclude-standard -z . \
        | while IFS= read -r -d '' f; do
            { [ -e "$f" ] || [ -L "$f" ]; } && printf '%s\0' "$f"
          done \
        | tar -c --null -T - -f - ) | tar -x -f - -C "$dest"
  else
    cp -R "$src/." "$dest/"
  fi
}

# ---------------------------------------------------------------- fixture ----
# A Felix root with the real harness and one invented project.
FROOT="$TMP/felix"
mkdir -p "$FROOT/projects/widget" "$MEM/widget"
_copy_content "$REAL_HARNESS" "$FROOT/harness"

cat > "$FROOT/projects/widget/project.json" <<'EOF'
{
  "name": "widget",
  "remote_match": "example.com/widget",
  "gate": "sh -c 'test -f WIDGET.txt && echo widget-gate-ran'"
}
EOF
printf '# widget\n' > "$FROOT/projects/widget/CLAUDE.md"

# One row, deliberately the most boring true thing about this checkout: the
# marker that binds it. It must never come back `blind`, or every merge
# assertion in this file would be measuring the probe rather than the merge —
# so it reads a file the fixture creates and keeps, and if something does
# remove it the honest answer is `empty`, which blocks nothing.
printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' \
  > "$FROOT/projects/widget/probes.tsv"
cp "$FROOT/projects/widget/probes.tsv" "$TMP/probes.keep"

# And one admitted obligation, for the same reason: the merge boundary refuses
# a project that has admitted nothing, so every merge assertion below would
# otherwise be measuring the empty ledger. Always applicable, discharged by a
# command that cannot fail, grounded on nothing — the least an obligation can
# be while still being one.
printf 'fixture\tRELEASE_BLOCKING\tdeterministic\t-\ttrue\t-\ta fixture owes one thing, and it holds\n' \
  > "$FROOT/projects/widget/obligations.tsv"
cp "$FROOT/projects/widget/obligations.tsv" "$TMP/obligations.keep"

# The same for commissioning: one row a person answers, whose check reads the
# marker the fixture keeps, so the merge boundary is measuring the merge and
# not this table. The receipt it needs is stamped by _cm_stamp beside every
# green gate receipt below, because both are keyed to the tables the tests
# hand-edit, and a receipt for the wrong tables is exactly what must block.
printf 'marker\t-\t-\t-\t-\ttest -f .felix\t9\n' > "$FROOT/projects/widget/commissioning.tsv"
cp "$FROOT/projects/widget/commissioning.tsv" "$TMP/commissioning.keep"
_cm_stamp() { ( _r="${1:-$REPO}"; cd "$_r" && FELIX_HOME_DIR="$FROOT"; . "$FROOT/harness/lib/commission.sh"
                _o="$(felix_commission_run "$FROOT/projects/widget" "$_r" -)"
                felix_commission_receipt_write "$FROOT" "$FROOT/projects/widget" "$_r" "$_o" "" >/dev/null ); }

FELIX="$FROOT/harness/felix"
# Pin the home. Resolution consults ~/.felix-home, so without this the suite
# runs against whatever the machine has installed, writes test projects into it,
# and reports failures about the wrong tree. Observed exactly that.
export FELIX_HOME="$FROOT"

# A checkout with NO git remote, bound by marker file alone.
REPO="$TMP/some-customer-repo"
mkdir -p "$REPO/deep/nested"
( _fx_cd "$REPO" && git init -q -b main )
# macOS resolves /var to /private/var, and git reports the resolved path. Compare
# against what the filesystem actually calls this directory, not what mktemp said.
REPO="$(cd "$REPO" && pwd -P)"
printf 'widget\n' > "$REPO/.felix"
printf 'contents\n'  > "$REPO/WIDGET.txt"
