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
