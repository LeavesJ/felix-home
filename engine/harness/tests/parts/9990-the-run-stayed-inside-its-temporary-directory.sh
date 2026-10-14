# The fixture floor still holds at the end. Every section above was written
# to run from the floor the preamble laid: in $TMP/cwd, with the parent of
# $TMP as git's ceiling. A section that cds at the top level, or drops or
# moves the ceiling in the suite's own shell rather than in a subshell, takes
# that floor away from every section after it, and each of their fixture
# lines is then one empty variable from 2026-10-08 again, with nothing saying
# so. The first section checks the floor before any of them; this checks it
# after all of them. Physical paths, as there: mktemp says /var, the
# filesystem says /private/var.
_ffe_here="$(pwd -P)"
_ffe_want="$([ -d "$TMP/cwd" ] && cd "$TMP/cwd" && pwd -P)"
_ffe_cv="$(command printenv GIT_CEILING_DIRECTORIES 2>/dev/null || printf '(unset)')"
_ffe_cp="$([ -n "$_ffe_cv" ] && [ -d "$_ffe_cv" ] && cd "$_ffe_cv" && pwd -P)"
_ffe_cw="$(cd "$(dirname "$TMP")" && pwd -P)"
if [ -n "$_ffe_want" ] && [ "$_ffe_here" = "$_ffe_want" ] && [ -n "$_ffe_cp" ] && [ "$_ffe_cp" = "$_ffe_cw" ]; then
  ok  "fixture floor: at the end of the suite it still stands in cwd inside its temporary directory, under a ceiling at that directory's parent"
else
  bad "fixture floor: at the end of the suite it still stands in cwd inside its temporary directory, under a ceiling at that directory's parent" \
      "it stands in [$_ffe_here], and $TMP/cwd is [${_ffe_want:-not a directory}]; a child sees GIT_CEILING_DIRECTORIES [$_ffe_cv], and the parent of $TMP is [$_ffe_cw]"
fi

printf '\nthe run stayed inside its temporary directory\n'
# The two ends of the guard the preamble sets up, read in the main shell after
# the last section and before the manifest comparison, so that what they find
# is counted like any other assertion and a failure here reads `N failed` and
# exits 1.
#
# A fixture git command that _fx_cd or _fx_git refused left one line in
# $FELIX_TEST_FXREFUSED, from wherever it ran: the fixtures redirect both
# streams and run in subshells, so the file is the only record that survives.
# One line is enough to be red. It names the line of the suite that asked, the
# directory as given, and why it was refused.
if [ -s "$FELIX_TEST_FXREFUSED" ]; then
  bad "no fixture git command was refused for a directory outside the suite's temporary directory" \
      "$(cat "$FELIX_TEST_FXREFUSED")"
else
  ok  "no fixture git command was refused for a directory outside the suite's temporary directory"
fi
# The remotes of the checkout this run started in, against the snapshot taken
# before anything ran. Skipped when neither the directory the run started in
# nor the suite's own tree is in a checkout; red when the snapshot could not be
# read, since then nothing was compared; red when a
# watched entry differs in name, value or order, when a remote that had refs
# has none or one a branch tracked is tracked by none, and when a move was
# recorded while the run ran, even if it has been put back since. The message
# says the remotes moved while this run ran, which is all that is known: many
# suites and agents share one config.
_og_check
case "$_og_v" in
  ok)   ok   "the remotes of the checkout this run started in did not move while it ran" ;;
  skip) skip "the remotes of the checkout this run started in did not move while it ran" "$_og_msg" ;;
  *)    bad  "the remotes of the checkout this run started in did not move while it ran" "$_og_msg" ;;
esac
# Both ran, so the EXIT trap has nothing to add.
_fx_final=1
