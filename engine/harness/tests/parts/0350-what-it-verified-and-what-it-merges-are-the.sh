# The rest of the copy's contract, each line of it a way the rule above could
# be kept and the suite still be wrong. Work not yet added to git is under
# test, so untracked-and-not-ignored is carried; the CLI is run from the copy,
# so its bit survives; a tracked file deleted from disk is in git's listing
# and nowhere else, and the copy must still finish and say it succeeded. And
# where git tracks nothing under the source there is no rule to apply and the
# directory is copied whole — asked as "does git track anything here" and
# never as "is this inside a repository", because the plugin cache, where a
# copy of this suite also sits, was inside one, a home directory under version
# control, and an ignore rule there lists an empty harness. The fixture is
# that layout.
printf 'not added yet\n' > "$INC/engine/harness/lib/unadded.sh"
_copy_content "$INC/engine/harness" "$TMP/incident-copy"
[ -f "$TMP/incident-copy/lib/unadded.sh" ] \
  && ok  "work not yet added to git is still carried into the copy" \
  || bad "work not yet added to git is still carried into the copy" "lib/unadded.sh was left behind"
[ -x "$TMP/incident-copy/felix" ] \
  && ok  "and the CLI keeps its executable bit through it" \
  || bad "and the CLI keeps its executable bit through it" "felix is not executable in the copy"
mv "$INC/engine/harness/lib/say.sh" "$TMP/incident-say.aside"
_copy_content "$INC/engine/harness" "$TMP/incident-copy2"; _incrc=$?
if [ "$_incrc" -eq 0 ] && [ -f "$TMP/incident-copy2/felix" ] && [ ! -e "$TMP/incident-copy2/lib/say.sh" ]; then
  ok  "a tracked file missing from disk does not stop the copy"
else
  bad "a tracked file missing from disk does not stop the copy" "rc=$_incrc, felix copied: $([ -f "$TMP/incident-copy2/felix" ] && echo yes || echo no)"
fi
mv "$TMP/incident-say.aside" "$INC/engine/harness/lib/say.sh"
INCH="$TMP/incident-home"; mkdir -p "$INCH/cache/harness/.claude-flow/data"
printf 'a home directory under version control\n' > "$INCH/README"
printf 'cache/\n' > "$INCH/.gitignore"
printf '#!/bin/sh\n' > "$INCH/cache/harness/felix"
printf '{}\n' > "$INCH/cache/harness/.claude-flow/data/pending-insights.jsonl"
( cd "$INCH" && git init -q -b main && git add -A >/dev/null \
  && git -c user.name=t -c user.email=t@t commit -qm home >/dev/null )
_copy_content "$INCH/cache/harness" "$TMP/incident-cache-copy"
is "a directory git tracks nothing under is copied whole, even inside a repository that ignores it" \
   "$(find "$TMP/incident-cache-copy" -type f 2>/dev/null | grep -c .)" "2"

# (d) The same fixture, untouched, merges — the assertion every refusal above
# borrows its meaning from. The entry named is the version directory main
# declares, the parent of the harness that judged and not the harness itself;
# the pattern admits any spelling of the cache path and no other suffix.
_sgrecord; _sgmerge
is "a faithful cache entry still merges a self-governed branch" "$SGMERGES" "1"
grep -Eq 'judged by [^ ]*/1\.0\.0, the engine main declares, byte-identical to main\.' "$TMP/sg.out" \
  && ok  "and the merge names the entry main declares, not the harness inside it" \
  || bad "and the merge names the entry main declares, not the harness inside it" "$(cat "$TMP/sg.out")"
_sgm="$(_sgline 'merged. nothing in it escaped the tree')"; _sgj="$(_sgline 'judged by ')"
if [ -n "$_sgm" ] && [ -n "$_sgj" ] && [ "$_sgj" -gt "$_sgm" ]; then
  ok  "and names the judge only after the merge is reported"
else
  bad "and names the judge only after the merge is reported" \
      "merged at line [$_sgm], judged-by at line [$_sgj]: $(cat "$TMP/sg.out")"
fi
( cd "$SG" && git checkout -q feature && git branch -qD pinned )
rm -rf "$KC2/1.0.0/harness"; cp -R "$FROOT/harness" "$KC2/1.0.0/harness"

# And the product that ships no engine is still left alone — now with the one
# variable that refuses a self-governed repository outright set in its
# environment, and no cache to find a judge in.
: > "$TMP/gh.prod.log"
( cd "$MR" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$MR" "$FROOT" 0 "true" "$(felix_tree_id "$MR" "$FROOT")" )
_cm_stamp "$MR"
( cd "$MR" && PATH="$GHB:$PATH" GHSTUB_LOG="$TMP/gh.prod.log" \
    FELIX_KERNEL_CACHE="$TMP/no-cache-at-all" FELIX_KERNEL="$KC2/1.0.0/harness" \
    "$FELIX" merge --base HEAD~1 >/dev/null 2>&1 )
is "a governed product merges with FELIX_KERNEL set and no engine installed" \
   "$(grep -c '^pr merge' "$TMP/gh.prod.log" | tr -d ' ')" "1"

printf '\nwhat it verified and what it merges are the same branch\n'
# Issue #33, from the same concurrency audit. felix merge computed the tree
# identity, checked the receipt against it, ran the evidence check — and only
# then read the branch name. A peer's `git checkout` in the same working copy
# inside that gap made it squash-merge a branch nothing had verified, and print
# that nothing in it escaped the tree. Measured at ~35% of the command's
# runtime, and the harm is the worst category the audit found: an ungated
# escape merged into main, reported as verified, recorded nowhere.
#
# Injected at `git remote get-url`, which is the one landmark that sits inside
# exactly that window: felix_repo_slug is its only caller on this path, and it
# runs after the receipt is checked and before the branch is read. Verified by
# probe rather than assumed — a counted trigger would rot silently the first
# time the call sequence changed.
GB="$TMP/gitstub"; mkdir -p "$GB"
GITREAL="$(command -v git)"
# Parameterised on both halves, because one hard-coded scenario tested one third
# of the guard. RACE_ON picks where in the command the peer lands, RACE_CMD picks
# what the peer does. Between them they reach all three fields of the tuple and
# both sides of felix_merge_blockers.
cat > "$GB/git" <<STUB
#!/usr/bin/env bash
case "\$*" in
  *"\${RACE_ON:-remote get-url}"*)
    if [ -n "\${RACE_CMD:-}" ] && [ ! -f "\${RACE_FIRED:-/nonexistent}" ]; then
      printf 'fired\n' > "\$RACE_FIRED"
      eval "\$RACE_CMD" >/dev/null 2>&1
    fi ;;
esac
exec "$GITREAL" "\$@"
STUB
chmod +x "$GB/git"

( cd "$MR" && git checkout -q -b feature && git branch other )

# Re-records the receipt, runs felix merge with one peer action injected, and
# reports the exit code and whether gh was asked to merge anything.
_race() {
  local on="$1" cmd="$2"
  ( cd "$MR" && . "$FROOT/harness/lib/verify.sh"
    felix_verify_record "$MR" "$FROOT" 0 "true" "$(felix_tree_id "$MR" "$FROOT")" )
  _cm_stamp "$MR"
_cm_stamp "$MR"
  : > "$TMP/gh.race.log"; rm -f "$TMP/race.fired"
  ( cd "$MR" && PATH="$GB:$GHB:$PATH" GHSTUB_LOG="$TMP/gh.race.log" \
      RACE_ON="$on" RACE_CMD="$cmd" RACE_FIRED="$TMP/race.fired" \
      "$FELIX" merge --base HEAD~1 >/dev/null 2>&1 )
  RACE_RC=$?
  RACE_MERGES="$(grep -c '^pr merge' "$TMP/gh.race.log" | tr -d ' ')"
}

# 1. A peer checkout landing where the audit found it: after the receipt is
#    accepted, before the branch is read.
_race "remote get-url" "$GITREAL -C $MR checkout -q other"
[ -f "$TMP/race.fired" ] && ok "the injected checkout actually moved the branch" \
                         || bad "the injected checkout actually moved the branch" "it never fired"
is "a checkout that moves after verification merges nothing" "$RACE_MERGES" "0"
[ "$RACE_RC" -ne 0 ] && ok "and says so rather than reporting a merge" \
                     || bad "and says so rather than reporting a merge" "exit $RACE_RC"
( cd "$MR" && git checkout -q feature )

# 2. Inside felix_merge_blockers, which is the assertion that pins the fix. The
#    first version of this test injected only at `remote get-url` — the tail of
#    the command — so it passed just as well against a version that reads the
#    branch after the blockers and re-reads it at the end, which is the whole
#    of the bug the issue is about. A test that cannot tell the fix from the
#    defect is the failure this repository keeps paying for, and it was found
#    by review rather than by the suite.
_race "diff --name-only" "$GITREAL -C $MR checkout -q other"
[ -f "$TMP/race.fired" ] && ok "a checkout inside the verification is caught too" \
                         || bad "a checkout inside the verification is caught too" "it never fired"
is "and nothing is merged when it lands there" "$RACE_MERGES" "0"
( cd "$MR" && git checkout -q feature )

# 3. The other two fields. A peer commit moves the sha with the branch name
#    unchanged; a peer edit moves neither and changes only the tree the receipt
#    was accepted for. Both were dead weight until something asserted them.
_race "remote get-url" "$GITREAL -C $MR -c user.name=p -c user.email=p@p commit -q --allow-empty -m peer"
is "a peer commit on the same branch merges nothing" "$RACE_MERGES" "0"
_race "remote get-url" "printf 'peer\n' >> $MR/README.md"
is "a peer edit to the working tree merges nothing" "$RACE_MERGES" "0"
# And it must say which of the three moved. Printing a fixed prefix of the
# record rendered this case as two identical lines under "the checkout moved".
( cd "$MR" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$MR" "$FROOT" 0 "true" "$(felix_tree_id "$MR" "$FROOT")" )
_cm_stamp "$MR"
rm -f "$TMP/race.fired"
race_out="$( cd "$MR" && PATH="$GB:$GHB:$PATH" GHSTUB_LOG=/dev/null \
    RACE_ON="remote get-url" RACE_CMD="printf 'peer2\n' >> $MR/README.md" \
    RACE_FIRED="$TMP/race.fired" "$FELIX" merge --base HEAD~1 2>&1 )"
has "and names the working tree rather than the checkout" "$race_out" "tree       edited under it"
case "$race_out" in
  *"The checkout moved"*) bad "and does not blame a checkout that did not move" "$race_out" ;;
  *)                      ok  "and does not blame a checkout that did not move" ;;
esac
( cd "$MR" && git checkout -q -- README.md 2>/dev/null; git checkout -q feature )
unset GHSTUB_LOG

# The same defect with no concurrency in it at all. `felix merge 35` shifted the
# 35 away unread and merged whatever HEAD happened to be on, so a command told
# to merge one thing merged another and reported success. An argument it cannot
# honour must stop it, not be discarded — the rest of this command is
# fail-closed everywhere.
export GHSTUB_LOG="$TMP/gh.arg.log"; : > "$GHSTUB_LOG"
( cd "$MR" && PATH="$GHB:$PATH" "$FELIX" merge 35 >/dev/null 2>&1 )
rc=$?
# A flag whose value is missing, which is the same defect one step along and
# needs no concurrency either. `--base) base="${2:-main}"; shift 2` reads as if
# the missing value were handled — the default is right there — but `shift 2`
# fails when $# is 1 and, having failed, shifts nothing, so the loop never
# advances and the command spins with no output until it is killed. Confirmed
# present on main before this branch, so it is not a regression from the
# argument handling added beside it.
#
# A test for a hang has to bound itself or it becomes the hang.
( cd "$MR" && PATH="$GHB:$PATH" "$FELIX" merge --base >/dev/null 2>&1 ) &
_bp=$!
# Kills the children too. `kill $_bp` reaps the subshell and leaves the felix
# it launched spinning — found the hard way: the first red run of this test left
# a `felix merge --base` burning a core for twenty-four minutes, and it was
# still there when the next gate ran slowly enough to notice. A test for a hang
# that leaks the hang is worse than no test, because it only leaks when it fails.
( sleep 5; pkill -9 -P $_bp 2>/dev/null; kill -9 $_bp 2>/dev/null ) >/dev/null 2>&1 &
_bw=$!
wait $_bp 2>/dev/null; _brc=$?
kill $_bw >/dev/null 2>&1
case "$_brc" in
  137|9) bad "a flag with no value refuses instead of spinning" "still running after 5s" ;;
  0)     bad "a flag with no value refuses instead of spinning" "exit 0, it merged something" ;;
  *)     ok  "a flag with no value refuses instead of spinning" ;;
esac

is "an argument it cannot honour merges nothing" \
   "$(grep -c '^pr merge' "$GHSTUB_LOG" | tr -d ' ')" "0"
[ "$rc" -ne 0 ] && ok "and refuses instead of ignoring it" \
                || bad "and refuses instead of ignoring it" "exit $rc"
unset GHSTUB_LOG

