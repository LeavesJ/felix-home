_widget_repo_build
_plain_build
printf '\nwhat to do next\n'
# Felix tracked maintenance, drift, setup gaps, evidence gaps and coverage in
# five separate commands and never once said which of them mattered. A founder
# reading five reports to work out the order is doing exactly the job Felix
# exists to take.
#
# The ranking is anchored on the declared objective — founder interruptions per
# session — and then on what is blocking now. So the order is: work Felix owes
# on the change in hand, then the things that will interrupt a future session,
# then rot that will quietly mislead one.
NX="$TMP/nextproj"; mkdir -p "$NX" "$MEM/nextproj"
printf '{"name":"nextproj","gate":"true"}\n' > "$NX/project.json"
: > "$NX/routes.tsv"; : > "$NX/stack.tsv"
# One probe, so a receipt written for this project carries an epoch, and the
# receipt below is written for THIS project rather than for the one the
# repo's marker names: the reader is handed $NX, and a receipt stamped under
# another project's epoch reads as the facts having moved.
printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' > "$NX/probes.tsv"

# Sourced the way the CLI sources them. A short list here passed a `dormant`
# maintenance row for a fixture that was plainly due, because the capability
# check silently degrades when its helpers are absent — the test would have
# been asserting the absence of a library.
_next() { ( cd "$REPO" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
            . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/review.sh"
            . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"; . "$FROOT/harness/lib/evidence.sh"
            . "$FROOT/harness/lib/maintenance.sh"; . "$FROOT/harness/lib/stack.sh"
            . "$FROOT/harness/lib/ready.sh"; . "$FROOT/harness/lib/ledger.sh"
            . "$FROOT/harness/lib/coverage.sh"; . "$FROOT/harness/lib/deny.sh"
            . "$FROOT/harness/lib/route.sh"; . "$FROOT/harness/lib/next.sh"
            felix_next "$NX" "$FROOT" "$REPO" HEAD~1 ); }

printf 'ordinary\n' > "$REPO/README.md"; _stage
n="$(_next)"
has "an unverified tree is the first thing to do" "$(printf '%s\n' "$n" | head -1)" "gate"
has "and it is Felix's own work"                  "$(printf '%s\n' "$n" | head -1)" "felix"
has "every row carries the command that clears it" "$(printf '%s\n' "$n" | head -1)" "felix gate"

# A deployment that is not this tree, found before the gate run rather than by
# one.
#
# `felix ledger` ranks the gate's own recurring catches and `installed` is the
# top one — 28 times, against a lesson that already says so. The lesson is not
# working because it is advice about an ordering, and what a person needs at
# the moment before running the gate is the state.
#
# Only where the checkout is the engine's own source: a property of the
# checkout, not the name of a project. $REPO above holds no engine, which is
# why none of the rows already asserted here changed.
NDR="$TMP/next-drift"; mkdir -p "$NDR/engine"
( _fx_cd "$NDR" && git init -q -b main && printf 'x\n' > a.txt && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm i ) >/dev/null 2>&1
NDR="$(cd "$NDR" && pwd -P)"
cp -R "$FROOT/harness" "$NDR/engine/harness"
NDL="$TMP/next-live"; mkdir -p "$NDL"
cp -R "$NDR/engine/harness" "$NDL/harness"
NDB="$TMP/next-bin"; mkdir -p "$NDB"
# The stub reads the path it should report from a file beside itself rather
# than from the environment. A variable assigned in the calling shell and not
# exported is invisible to the child, and the first draft of this fixture read
# empty every time — the stub answering "nothing is deployed" while the
# assertion believed it was answering with a path.
printf '#!/usr/bin/env bash\nprintf "{\\"felix@felix\\": {\\"installPath\\": \\"%%s\\"}}\\n" "$(cat "$(dirname "$0")/live" 2>/dev/null)"\n' \
  > "$NDB/claude"
chmod +x "$NDB/claude"
_ndlive() { printf '%s' "${1:-}" > "$NDB/live"; }
_nd() { _ndlive "$1"; ( cd "$NDR" && PATH="$NDB:$PATH"
          . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
          . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/review.sh"
          . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"; . "$FROOT/harness/lib/evidence.sh"
          . "$FROOT/harness/lib/maintenance.sh"; . "$FROOT/harness/lib/stack.sh"
          . "$FROOT/harness/lib/ready.sh"; . "$FROOT/harness/lib/ledger.sh"
          . "$FROOT/harness/lib/coverage.sh"; . "$FROOT/harness/lib/deny.sh"
          . "$FROOT/harness/lib/route.sh"; . "$FROOT/harness/lib/next.sh"
          felix_next "$NX" "$FROOT" "$NDR" HEAD 2>/dev/null ); }
# The reader first, since everything below rests on it answering.
_ndlive "$NDL"
is "the deployed path is read from the CLI, not guessed from the cache" \
   "$( cd "$NDR" && PATH="$NDB:$PATH"
       . "$FROOT/harness/lib/resolve.sh"; felix_deployed_engine )" "$NDL"
_ndlive ""
is "and a CLI that cannot answer is not a stale deployment" \
   "$( cd "$NDR" && PATH="$NDB:$PATH"
       . "$FROOT/harness/lib/resolve.sh"; felix_deployed_engine; printf '%s' "$?" )" "1"
case "$(_nd "$NDL")" in
  *"deployed engine is not this tree"*)
    bad "a deployment matching the tree is not reported as drift" ;;
  *) ok "a deployment matching the tree is not reported as drift" ;;
esac
printf '\n# drift\n' >> "$NDR/engine/harness/lib/monitor.sh"
has "a deployment that is not this tree is the first thing to fix" \
    "$(_nd "$NDL")" "the deployed engine is not this tree"
has "and it names the command that clears it" "$(_nd "$NDL")" "felix install"
# Silence when nothing can be asked, because "I could not look" is not a
# finding about anybody's deployment.
case "$(_nd "")" in
  *"deployed engine is not this tree"*)
    bad "and a CLI that answers nothing reports no drift" ;;
  *) ok "and a CLI that answers nothing reports no drift" ;;
esac

# Two capabilities that were never pointed at, for two different reasons, and
# only one of them is about keywords.
#
# `felix next` told the founder to fix the keywords in routes.tsv for plugins no
# route names at all — advice nobody can follow, because no keyword can reach a
# capability that appears in no play. Six rows on the real project, three of
# them impossible. The ledger already draws this distinction one layer down:
# named>0 with calls=0 is evidence about the capability, named=0 is evidence
# about routing and none at all about the capability. Rank 7 never inherited it.
#
# The general form is the one this project keeps paying for: absence of
# opportunity is not evidence of failure.
cat > "$MEM/nextproj/ledger.tsv" <<'LED'
s1	2026-08-01	plugin	reachable	0	0
s1	2026-08-01	plugin	unreachable	0	0
LED
printf 'work\tstuff\tcore\treachable\n' > "$NX/routes.tsv"
n="$(_next)"
rrow="$(printf '%s\n' "$n" | grep -A1 'reachable is mounted' | grep -v 'unreachable')"
urow="$(printf '%s\n' "$n" | grep -A1 'unreachable is mounted')"
has "a capability some route names is a keyword problem" "$rrow" "keywords"
case "$urow" in
  *keywords*) bad "one no route names is not" "$urow" ;;
  *)          ok  "one no route names is not" ;;
esac
has "and it says what would actually reach it" "$urow" "no route names it"
# Both are fixture state a later section asserts the absence of, so both are put
# back. A test that leaves its own evidence lying around makes the next one lie.
: > "$NX/routes.tsv"; : > "$MEM/nextproj/ledger.tsv"

# An escape outranks upkeep and is the founder's. It is also the thing the
# declared objective counts, so burying it under a maintenance row would hide
# the one number Felix is trying to move.
{ printf 'deployed\t7\talways\tconfirm the installed engine still matches\n'; } > "$NX/maintenance.tsv"
mkdir -p "$REPO/migrations"; printf 'x\n' > "$REPO/migrations/990.sql"; _stage
n="$(_next)"
has "an escape is named as the founder's"  "$n" "founder"
has "and says which channel"               "$n" "durable"
first_owner="$(printf '%s\n' "$n" | grep '	founder	' | head -1 | cut -f2)"
is "the founder's item is not buried"      "$first_owner" "founder"
_reset

# A tool a route names but cannot reach breaks the session it is needed in, and
# plugins bind at session start — so it can only be fixed between sessions.
# That is the highest-leverage preventive row there is.
# felix_ready_report is stubbed rather than driven. Whether a tool is really
# absent is ready.sh's own concern and it is tested there; here the question is
# only whether felix_next ranks an absent one. Driving it for real asserted the
# machine instead: with no claude CLI the honest answer is `unknown`, never
# `absent`, so this passed on a laptop and failed on every runner.
n="$( cd "$REPO" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
      . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/review.sh"
      . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"; . "$FROOT/harness/lib/evidence.sh"
      . "$FROOT/harness/lib/maintenance.sh"; . "$FROOT/harness/lib/stack.sh"
      . "$FROOT/harness/lib/ready.sh"; . "$FROOT/harness/lib/ledger.sh"
      . "$FROOT/harness/lib/coverage.sh"; . "$FROOT/harness/lib/deny.sh"
      . "$FROOT/harness/lib/next.sh"
      felix_ready_report() { printf 'absent\tnot-installed-anywhere:tool\tnot installed\n'; }
      felix_next "$NX" "$FROOT" "$REPO" HEAD~1 )"
has "a route naming an unreachable tool is ranked" "$n" "not-installed-anywhere"
has "and says it must be fixed before the next session" "$n" "bind at start"

# felix_ready_report emits five states and two of them mean NOT MEASURED:
# `undeclared` (a route names it and no manifest declares it, so the inventory
# is never consulted) and `unknown` (no claude CLI here, cannot check). The
# rank-3 filter kept only absent|disabled and dropped both, and cmd_next's
# empty-output branch then printed "every tool a route names is reachable" —
# turning two not-measureds into a positive verification. cmd_ready renders the
# same data correctly ("N of these could not be checked, so this is not a clean
# bill"), so the engine held both the right rendering and the wrong one, and the
# wrong one was on the command that answers "what now".
# The stub's rows travel in a variable the subshell inherits. Written as
# `printf '%s'` with no argument first, which prints nothing at all — so the
# assertions below read an output with no rank-3 rows in it and reported a
# defect in next.sh that was really a defect in the fixture.
_nxs() { _NXROWS="$1"
         ( cd "$REPO" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
           . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/review.sh"
           . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"; . "$FROOT/harness/lib/evidence.sh"
           . "$FROOT/harness/lib/maintenance.sh"; . "$FROOT/harness/lib/stack.sh"
           . "$FROOT/harness/lib/ready.sh"; . "$FROOT/harness/lib/ledger.sh"
           . "$FROOT/harness/lib/coverage.sh"; . "$FROOT/harness/lib/deny.sh"
           . "$FROOT/harness/lib/next.sh"
           felix_ready_report() { printf '%b' "$_NXROWS"; }
           felix_next "$NX" "$FROOT" "$REPO" HEAD~1 ) }
_nu="$(_nxs 'undeclared\tgoogle-cloud-storage\tnamed by a route, absent from stack.tsv\n')"
has "a routed tool no manifest declares is ranked, not dropped" "$_nu" "google-cloud-storage"
has "and says what would answer it"                            "$_nu" "declare"
_nk="$(_nxs 'unknown\tanthropic-skills:docx\tno claude CLI here, cannot check\n')"
has "a tool that could not be checked is said, not counted as reachable" "$_nk" "anthropic-skills:docx"
case "$_nk" in
  *"install or enable it"*) bad "and is not given an action nobody can take" "$_nk" ;;
  *)                        ok  "and is not given an action nobody can take" ;;
esac

# Due upkeep appears, and below the blocking rows.
printf 'ordinary again\n' > "$REPO/README.md"; _stage
( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/verify.sh"
  _ef="$(felix_verify_epoch_fields "$NX" "$REPO")"
  felix_verify_record "$REPO" "$FROOT" 0 "true" "$(felix_tree_id "$REPO" "$FROOT")" "" "" \
    "$(printf '%s' "$_ef" | cut -f1)" "$(printf '%s' "$_ef" | cut -f2)" )
n="$(_next)"
has "maintenance that is due is named" "$n" "deployed"
rm -f "$NX/maintenance.tsv"

# Nothing wrong is a real answer and has to be said, or the command becomes one
# people run and squint at.
n="$(_next)"
is "with nothing due it reports nothing" "$(printf '%s' "$n" | tr -d '\n ')" ""

# And the sentence it prints when there is nothing due must not claim more than
# was checked. With an unknown in the inventory, "every tool a route names is
# reachable" is a guess ready.sh explicitly refused to make one layer down.
_nxsay() { ( cd "$REPO" && PATH="/usr/bin:/bin" HOME="$TMP/nx-empty-home" "$FELIX" next 2>&1 ) }
mkdir -p "$TMP/nx-empty-home"
_ns="$(_nxsay)"
case "$_ns" in
  *"every tool a"*"route names is reachable"*)
    case "$_ns" in
      *"could not be checked"*) ok "the all-clear says what could not be checked" ;;
      *) bad "the all-clear says what could not be checked" "$_ns" ;;
    esac ;;
  *) ok "the all-clear says what could not be checked" ;;
esac
_reset

printf '\nwhether the delegation actually works\n'
# The monitor showed every record Felix wrote and never once showed whether
# Claude did the thing Felix named. Those are different claims, and only the
# second one is evidence that any of this is worth running.
#
# The signal is recorded rather than parsed. `named` is what a route pointed at
# and `calls` is what got reached for, both already in the ledger, so this is
# arithmetic on committed rows and not a transcript reader.
CM="$TMP/compliance"; mkdir -p "$CM" "$MEM/compliance"
cat > "$MEM/compliance/ledger.tsv" <<'EOF'
s1	2026-08-01	plugin	followed@x	4	2
s1	2026-08-01	plugin	ignored@x	0	3
s1	2026-08-01	plugin	unnamed@x	7	0
s2	2026-08-02	plugin	followed@x	1	1
s2	2026-08-02	plugin	ignored@x	0	1
EOF
c="$( . "$FROOT/harness/lib/monitor.sh"; . "$FROOT/harness/lib/ledger.sh"
      felix_monitor_compliance "$CM" )"
has "a session reports what was named and what was followed" "$c" "s1	2026-08-01	2	1	1"
has "and so does the next one"                               "$c" "s2	2026-08-02	2	1	1"
case "$c" in
  *unnamed*) bad "what no route named is not a compliance figure" "$c" ;;
  *)         ok  "what no route named is not a compliance figure" ;;
esac

# A ledger written before the named column cannot answer this, and must say so
# rather than reporting perfect compliance by counting nothing.
cat > "$MEM/compliance/ledger.tsv" <<'EOF'
s9	2026-07-01	plugin	old@x	0
EOF
c="$( . "$FROOT/harness/lib/monitor.sh"; . "$FROOT/harness/lib/ledger.sh"
      felix_monitor_compliance "$CM" | tr -d '\n ' )"
is "a ledger from before the column reports nothing at all" "$c" ""

printf '\nthe monitor\n'
# A hook's additionalContext reaches the model and never the terminal, so every
# routing decision and every gate verdict happens behind glass. The monitor is
# the only surface where a person can see what Felix actually did.
out="$(cd "$REPO" && "$FELIX" monitor 2>&1)"
MON="$FROOT/state/monitor.html"
[ -s "$MON" ] && ok "renders a page" || bad "renders a page" "$out"
if [ -s "$MON" ]; then
  grep -q '"name":"widget"' "$MON" \
    && ok "carries the governed project" || bad "carries the governed project"
  # A page shipped with its placeholder intact looks fine and shows nothing.
  grep -q 'FELIX_DATA' "$MON" \
    && bad "the data marker is substituted" "marker still present" \
    || ok "the data marker is substituted"

  # The panel that answers whether the delegation works has to be on the page
  # and fed by the payload. A render function nothing calls is the same defect
  # as a capability no route names.
  grep -q '"compliance":' "$MON" \
    && ok "the payload carries compliance" || bad "the payload carries compliance"
  grep -q 'renderCompliance()' "$MON" \
    && ok "and the page has a panel for it" || bad "and the page has a panel for it"
  grep -q 'renderMem();renderCompliance()' "$MON" \
    && ok "and paint actually calls it" || bad "and paint actually calls it"
  # No server and no network. A governance page that phones out is not one.
  if grep -qiE 'src="https?:|href="https?:|@import[[:space:]]+url\(http' "$MON"; then
    bad "self-contained, no external references"
  else
    ok "self-contained, no external references"
  fi

  # The route log records whatever was typed, and the data is embedded inside a
  # <script> element. An HTML parser looks for the literal characters closing
  # that tag without caring that they sit inside a string, so a prompt is a way
  # to end the script early and put markup on the page.
  printf '%s\thostile\t9\t{"prompt":"</script\076<img src=x onerror=alert(1)\076"}\n' \
    "2026-01-01T00:00:00Z" >> "$MEM/widget/routes.log"
  ( cd "$REPO" && "$FELIX" monitor >/dev/null 2>&1 )
  # The payload survives as inert text — that is fine and even desirable, since
  # the page is for reading what happened. What must not survive is a bracket.
  if grep -q 'u003c/script' "$MON"; then
    ok "a hostile prompt is neutralised, not dropped"
  else
    bad "a hostile prompt is neutralised, not dropped" "escaped form absent"
  fi
  grep -q '<img' "$MON" && bad "no markup from a prompt reaches the page" \
                        || ok "no markup from a prompt reaches the page"
  # ...and the page must still be one script element, not two.
  n="$(grep -c '</script>' "$MON")"
  is "the page still closes exactly one script" "$n" "1"
fi

printf '\ndenial\n'
# The first thing Felix can actually stop. Every other hook injects text a
# session may ignore; PreToolUse decides. Verified against two working
# implementations on this machine rather than assumed: exit 2 blocks and the
# reason goes to stderr, exit 0 allows.
#
# Scoped to Bash by the matcher in hooks.json, so a mistake here cannot deny an
# edit. A deny hook that gets this wrong is indistinguishable from a broken
# editor, which is the failure guard.sh exists to describe.
cat > "$FROOT/projects/widget/deny.tsv" <<'EOF'
# tool	pattern	reason
Bash	git add (-A|--all|\.)$	stage explicit paths; -A stages what you did not read
Bash	(^|[;&| ])\./scripts/gate\.sh	that is not the gate Felix runs
EOF

( cd "$REPO" && _pre '{"tool_name":"Bash","tool_input":{"command":"git add -A"}}' ); rc=$?
is "a denied command exits 2" "$rc" "2"
has "and says why" "$(cat "$FROOT/.deny-err")" "stage explicit paths"

( cd "$REPO" && _pre '{"tool_name":"Bash","tool_input":{"command":"git add src/widget.py"}}' ); rc=$?
is "an explicit path is allowed" "$rc" "0"

( cd "$REPO" && _pre '{"tool_name":"Bash","tool_input":{"command":"./scripts/gate.sh --quick"}}' ); rc=$?
is "running a rival gate is denied" "$rc" "2"

# The reason a project would ever turn this off is a false deny, so the failure
# mode has to be allow. Anything unparseable, any missing table, any error.
( cd "$REPO" && _pre 'not json at all' ); rc=$?
is "an unparseable payload is allowed" "$rc" "0"
( cd "$PLAIN" && _pre '{"tool_name":"Bash","tool_input":{"command":"git add -A"}}' ); rc=$?
is "an ungoverned repo is allowed" "$rc" "0"

# A malformed row must not take the whole table down with it, the same way a
# malformed routes.tsv row is skipped rather than fatal.
printf 'Bash\n' >> "$FROOT/projects/widget/deny.tsv"
( cd "$REPO" && _pre '{"tool_name":"Bash","tool_input":{"command":"git add -A"}}' ); rc=$?
is "a malformed row is skipped, others still deny" "$rc" "2"
rm -f "$FROOT/projects/widget/deny.tsv" "$FROOT/.deny-err"

( cd "$REPO" && _pre '{"tool_name":"Bash","tool_input":{"command":"git add -A"}}' ); rc=$?
is "no deny.tsv means nothing is denied" "$rc" "0"

printf '\ndenial past Bash\n'
# The matcher bound Bash alone, so no rule could see Read, Edit or Write — which
# the ledger then showed is where real sessions spend most of their calls. The
# hold-up was never the plumbing: the matcher was the blast-radius control, and
# a bad regex reaching Edit looks exactly like a broken editor.
#
# What a rule matches is now the field naming the thing the tool acts on, and a
# pattern broad enough to refuse ordinary work is refused as a rule instead of
# honoured. That makes the bad-regex case unreachable rather than accepted.
{ printf 'Bash\tgit add (-A|--all|\\.)$\tstage explicit paths\n'
  printf 'Edit\t/\\.env$\t.env holds live credentials; change it by hand\n'
  printf 'Write\t\\.lock$\ta lockfile is written by its tool, never by hand\n'
  printf 'Read\t/secrets/\treading a secret is how it reaches a transcript\n'
} > "$FROOT/projects/widget/deny.tsv"

( cd "$REPO" && _pre '{"tool_name":"Edit","tool_input":{"file_path":"/w/.env","old_string":"a","new_string":"b"}}' ); rc=$?
is  "a path rule denies an edit" "$rc" "2"
has "and says why" "$(cat "$FROOT/.deny-err")" "live credentials"

( cd "$REPO" && _pre '{"tool_name":"Edit","tool_input":{"file_path":"/w/src/widget.py","old_string":"a","new_string":"b"}}' ); rc=$?
is "an unrelated path is allowed" "$rc" "0"

( cd "$REPO" && _pre '{"tool_name":"Write","tool_input":{"file_path":"/w/uv.lock","content":"x"}}' ); rc=$?
is "a write rule denies a write" "$rc" "2"

# The tool column has to keep meaning something, or widening the matcher has
# quietly turned every rule into a rule about every tool.
( cd "$REPO" && _pre '{"tool_name":"Write","tool_input":{"file_path":"/w/.env","content":"x"}}' ); rc=$?
is "a rule naming Edit does not deny a Write" "$rc" "0"

( cd "$REPO" && _pre '{"tool_name":"Read","tool_input":{"file_path":"/w/secrets/key.pem"}}' ); rc=$?
is "reading can be refused too" "$rc" "2"

( cd "$REPO" && _pre '{"tool_name":"NotebookEdit","tool_input":{"notebook_path":"/w/.env"}}' ); rc=$?
is "a notebook is matched on its own path field" "$rc" "0"

# A rule matches what the tool acts on and never what it would write. Matching
# content would turn every edit payload into a search target, so a rule written
# about a filename would start firing on prose that merely mentions it.
printf 'Edit\tuv\\.lock\tnot by hand\n' > "$FROOT/projects/widget/deny.tsv"
( cd "$REPO" && _pre '{"tool_name":"Edit","tool_input":{"file_path":"/w/README.md","old_string":"see uv.lock","new_string":"see uv.lock now"}}' ); rc=$?
is "a rule never matches file content" "$rc" "0"

( cd "$REPO" && _pre '{"tool_name":"Edit","tool_input":{}}' ); rc=$?
is "a payload naming nothing to act on is allowed" "$rc" "0"

# The sharp version of the same thing, and the one that decides how the field
# is read. Content quoting the field name is already defused, because JSON
# escapes those quotes and they are neutralised before any match runs — checked
# rather than assumed. What is not defused is a second unescaped copy further
# along the envelope, which a greedy match reads in preference to the real one.
# Claude Code is free to add envelope keys, so the subject has to be the first
# occurrence rather than the last.
printf 'Edit\t/\\.env$\tcredentials\n' > "$FROOT/projects/widget/deny.tsv"
( cd "$REPO" && _pre '{"tool_name":"Edit","tool_input":{"file_path":"/w/README.md"},"related":{"file_path":"/w/.env"}}' ); rc=$?
is "a later copy of the field in the envelope is not the subject" "$rc" "0"

# The reason widening was held back, made unreachable. A pattern matching an
# ordinary path or an ordinary command is not a narrow rule with a bug in it;
# it is a rule that refuses everything, and honouring one is indistinguishable
# from a broken editor. Skipping it can only ever allow more than was intended,
# which is the direction every other failure in this file already takes.
printf 'Edit\t.*\teverything\n' > "$FROOT/projects/widget/deny.tsv"
( cd "$REPO" && _pre '{"tool_name":"Edit","tool_input":{"file_path":"/w/src/widget.py"}}' ); rc=$?
is "a rule that refuses everything is refused as a rule" "$rc" "0"

printf 'Bash\t.\tanything at all\n' > "$FROOT/projects/widget/deny.tsv"
( cd "$REPO" && _pre '{"tool_name":"Bash","tool_input":{"command":"ls"}}' ); rc=$?
is "and over-broad means over-broad for Bash too" "$rc" "0"

# Generous is not the same as over-broad. A rule covering a whole tree of
# generated files still has to fire, or the guard has eaten the feature.
printf 'Edit\t/(node_modules|dist)/\tgenerated; change the source\n' > "$FROOT/projects/widget/deny.tsv"
( cd "$REPO" && _pre '{"tool_name":"Edit","tool_input":{"file_path":"/w/dist/bundle.js"}}' ); rc=$?
is "a broad but legitimate rule still denies" "$rc" "2"

# A skipped rule has to be visible somewhere a person looks, or it is a rule
# that silently does nothing — the same complaint Felix makes about other
# people's plugins. The hook stays quiet because it runs on every call.
printf 'Edit\t.*\teverything\n' > "$FROOT/projects/widget/deny.tsv"
out="$( cd "$REPO" && "$FELIX" doctor 2>&1 )"
has "doctor names the rule that refuses everything" "$out" "refuses everything it was asked about"
printf 'Edit\t/\\.env$\tcredentials\n' > "$FROOT/projects/widget/deny.tsv"
out="$( cd "$REPO" && "$FELIX" doctor 2>&1 )"
case "$out" in
  *"refuses everything it was asked about"*) bad "doctor is quiet when every rule is narrow" "reported anyway" ;;
  *) ok "doctor is quiet when every rule is narrow" ;;
esac
rm -f "$FROOT/projects/widget/deny.tsv" "$FROOT/.deny-err"

