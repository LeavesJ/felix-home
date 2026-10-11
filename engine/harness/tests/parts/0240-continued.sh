# A summary session still ends like any other, and nothing at its end knew it
# for one. In a tree with work no gate had seen, Stop held it and told the
# summarising model to run the gate; a tool call made on that advice went to
# state/ledger, and SessionEnd folded it into ledger.d, the phantom back in the
# denominator the prompt hook had kept it out of. So the prompt hook leaves a
# marker for the session in place of a record, and Stop and SessionEnd do
# nothing at all for a session that carries one.
printf 'unverified\n' >> "$P264R/WIDGET.txt"
# The control first: a person's session in the same tree is held.
_p264_prompt "$(_p264_payload p264-heldctl 'let us build the results page')" "$P264R" >/dev/null
case "$(_p264_stop "$P264R" p264-heldctl)" in
  *'"decision"'*'"block"'*) ok  "a person's session in a tree no gate has seen is held" ;;
  *)                        bad "a person's session in a tree no gate has seen is held" ;;
esac
# A marker is not a way out. Every prompt a person types marks the session and a
# summary never does, so a marker beside a mark is not what it says.
mkdir -p "$FROOT/state/machine" && : > "$FROOT/state/machine/p264-heldctl"
case "$(_p264_stop "$P264R" p264-heldctl)" in
  *'"decision"'*'"block"'*) ok  "and a marker laid in a session a person has typed into does not excuse it" ;;
  *)                        bad "and a marker laid in a session a person has typed into does not excuse it" ;;
esac
_b="$(_p264_snap)"
_p264_prompt "$(_p264_payload p264-sumstop "$P264_REQ")" "$P264R" >/dev/null
[ -e "$FROOT/state/machine/p264-sumstop" ] \
  && ok  "a summary request leaves a marker for its session in place of a record" \
  || bad "a summary request leaves a marker for its session in place of a record" "no $FROOT/state/machine/p264-sumstop"
# SessionStart wrote the session's startup row before any prompt came, and
# could not know. The one row the request adds is how a reader of
# lifecycle.log drops that session: kind summary, its id, its transcript.
is "and one lifecycle row for that session, of kind summary, naming its transcript" \
  "$(awk -F'\t' '$3=="p264-sumstop" { print $2 " " $8 }' "$MEM/widget/lifecycle.log" 2>/dev/null)" \
  "summary $P264/p264-sumstop.jsonl"
is "and a person's prompt adds no lifecycle row at all" \
  "$(awk -F'\t' '$3=="p264-heldctl"' "$MEM/widget/lifecycle.log" 2>/dev/null | wc -l | tr -d ' ')" "0"
out="$(_p264_stop "$P264R" p264-sumstop)"
is "and Stop neither holds that session nor tells it anything" "${#out}" "0"
_m="$(_p264_snap)"
_p264_same "and records no hold for it in says.log or verification.log" \
  "$(_p264_of 'says|verif' "$_b")" "$(_p264_of 'says|verif' "$_m")"
# A tool call it makes anyway, and then its end.
( cd "$P264R" && printf '{"session_id":"p264-sumstop","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"ls"}}' \
    | "$FROOT/harness/hooks/post-tool" >/dev/null 2>&1 )
_p264_end p264-sumstop "$P264R"
_a="$(_p264_snap)"
_p264_same "and SessionEnd folds nothing of it into ledger.d" \
  "$(_p264_of ledger.d "$_b")" "$(_p264_of ledger.d "$_a")"
[ -e "$FROOT/state/machine/p264-sumstop" ] \
  && bad "and takes the marker away with the session" "still there" \
  || ok  "and takes the marker away with the session"
# No id, nothing to key a marker on and nothing that could read one back.
_b="$(_p264_snap)"
( cd "$P264R" && printf '{"hook_event_name":"UserPromptSubmit","prompt":"%s"}' "$P264_REQ" \
    | "$FROOT/harness/hooks/user-prompt" >/dev/null 2>&1 )
_a="$(_p264_snap)"
_p264_same "a summary request with no session id leaves no marker" \
  "$(_p264_of state/machine "$_b")" "$(_p264_of state/machine "$_a")"
# Nothing else either: what the prompt hook may do with a prompt is the
# prompt's kind, and the kind is the same with or without an id.
_p264_same "and records nothing else for it: no brief, no route, no mark, no route state" \
  "$(_p264_of 'says|routes|state/session|state/ledger|state/route' "$_b")" \
  "$(_p264_of 'says|routes|state/session|state/ledger|state/route' "$_a")"
# Stop has no id to find a marker by, so it does what it always did, and the
# tree here holds work no gate has seen.
case "$( cd "$P264R" && printf '{"hook_event_name":"Stop","stop_hook_active":false}' \
           | "$FROOT/harness/hooks/stop" 2>&1 )" in
  *'"decision"'*'"block"'*) ok  "and Stop, with no id, holds that tree as it always did" ;;
  *)                        bad "and Stop, with no id, holds that tree as it always did" ;;
esac
# And with the gate green on that tree, what Stop says to a person at the end,
# whichever of its notices that is, is not said to the summary either.
( cd "$P264R" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$P264R" "$FROOT" 0 "gate" "$(felix_tree_id "$P264R" "$FROOT")" "" >/dev/null 2>&1 )
_p264_prompt "$(_p264_payload p264-greenctl 'let us build the results page')" "$P264R" >/dev/null
out="$(_p264_stop "$P264R" p264-greenctl)"
[ -n "$out" ] \
  && ok  "a person's session that ends on a green gate is still spoken to at its end" \
  || bad "a person's session that ends on a green gate is still spoken to at its end" "Stop said nothing"
_p264_prompt "$(_p264_payload p264-sumgreen "$P264_REQ")" "$P264R" >/dev/null
out="$(_p264_stop "$P264R" p264-sumgreen)"
if [ -z "$out" ] && [ ! -e "$FROOT/state/verified/p264-sumgreen" ]; then
  ok  "and a summary session is not"
else
  bad "and a summary session is not" "printed ${#out} chars; verified: $(ls "$FROOT/state/verified" 2>/dev/null | grep p264 | tr '\n' ' ')"
fi
_p264_end p264-sumgreen "$P264R"
rm -f "$( . "$FROOT/harness/lib/verify.sh"; _felix_receipt_path "$P264R" "$FROOT")"

# The sessions recorded before this are removed from ledger.d by a one-off pass,
# and that has to stay done. `felix ledger` and `felix stack` fold every session
# whose record is behind what is on disk, and session-start counts the same set
# to hedge the unmounts it proposes. An old summary session's appends are still
# on disk, its mark is a commit this repository owns, and its fold is exactly
# what the pass took away: so the next `felix ledger` folded it straight back,
# and until then session-start held every unmount on its account. Built here as
# the old prompt hook left one, in a home of its own so the catch-up walks
# nothing else, beside a person's session in the same state as the control.
L264="$P264/catchup"; mkdir -p "$L264/home/state/ledger" "$L264/home/state/session" "$L264/mem" "$L264/bin"
_l264_head="$(git -C "$REPO" rev-parse HEAD 2>/dev/null)"
# Whether a brief row can be the platform's turns on when it was written:
# before the day route.sh gives for the wording, no engine matched the request
# and it was briefed like a prompt. felix_say stamps the row with the time it
# writes it, so the clock here is the fixture's, a `date` that says what it is
# told, and the day is read from route.sh rather than copied.
printf '#!/bin/sh\nprintf "%%s\\n" "$L264_AT"\n' > "$L264/bin/date"; chmod +x "$L264/bin/date"
_l264_day="$( . "$FROOT/harness/lib/route.sh"; printf '%s' "${_FELIX_ROUTE_SESSION_REQUESTS[2]:-}" )"
_l264_say() {    # sid, what was asked as the prompt hook held it, when: one brief row
  ( FELIX_MEMORY="$L264/mem" L264_AT="$3" PATH="$L264/bin:$PATH"; export FELIX_MEMORY L264_AT PATH
    . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/say.sh"
    felix_say "$FROOT/projects/widget" brief "Use this now: superpowers:systematic-debugging" "$2" "$1" )
}
_l264_sess() {   # sid, what was asked, when, [what it reached for]: a session nothing folded
  printf '%s\n' "$_l264_head" > "$L264/home/state/session/$1"
  printf 'named\tsuperpowers:systematic-debugging\n' > "$L264/home/state/ledger/$1.tsv"
  [ -z "${4:-}" ] || printf '%s\n' "$4" >> "$L264/home/state/ledger/$1.tsv"
  _l264_say "$1" "$2" "$3"
}
_l264_sess p264-oldsum    "$P264_REQ" 2026-09-10T21:04:57Z
_l264_sess p264-oldperson 'the build is broken and the stacktrace shows a crash on reproduce' 2026-09-10T21:10:00Z
# Sourced the way session-start sources it, ledger.sh without route.sh.
_l264() { ( FELIX_MEMORY="$L264/mem"; export FELIX_MEMORY
            . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/ledger.sh"
            "$1" "$FROOT/projects/widget" "$L264/home" "$REPO" ) 2>&1; }
is "session-start counts a person's unfolded session as stranded, and not an old summary session" \
   "$(_l264 felix_ledger_stranded)" "1"
# The first 200 characters are all of the request a brief row keeps, and a
# person can paste them too. The prompt hook reads a person who stops short of
# the whole opening and closing as a person and briefs them, so the row is
# theirs when it was written on the day route.sh gives or after, and a session
# in which it is one brief among others is a person's whenever it was written:
# the platform's request was its session's only prompt. Passed over, either
# one was never folded or counted, and what it reached for went with it.
_l264_sess p264-newshare \
  "${P264_OPEN:0:200}"'debt I should pay down first, and fix the hook that keeps blocking me' \
  "${_l264_day}T12:00:00Z" 'skill	superpowers:systematic-debugging'
is "and counts a person's session whose prompt shares the request's first 200 characters" \
   "$(_l264 felix_ledger_stranded)" "2"
_l264_sess p264-oldmixed 'the build is broken and the stacktrace shows a crash on reproduce' 2026-09-10T20:00:00Z
_l264_say  p264-oldmixed "${P264_OPEN:0:200}"'debt I should pay down first' 2026-09-10T20:30:00Z
is "and an older one in which such a prompt was one of several" \
   "$(_l264 felix_ledger_stranded)" "3"
_l264 felix_ledger_catchup >/dev/null
[ -f "$L264/mem/widget/ledger.d/p264-oldperson.tsv" ] \
  && ok  "felix ledger still folds a person's session nothing folded" \
  || bad "felix ledger still folds a person's session nothing folded" "no ledger.d/p264-oldperson.tsv"
[ -f "$L264/mem/widget/ledger.d/p264-oldsum.tsv" ] \
  && bad "but no longer folds an old summary session back into ledger.d" "$(cat "$L264/mem/widget/ledger.d/p264-oldsum.tsv")" \
  || ok  "but no longer folds an old summary session back into ledger.d"
has "and still folds the person's whose prompt shares its first 200 characters, with what it reached for" \
    "$(cat "$L264/mem/widget/ledger.d/p264-newshare.tsv" 2>/dev/null)" "skill	superpowers:systematic-debugging	1"
[ -f "$L264/mem/widget/ledger.d/p264-oldmixed.tsv" ] \
  && ok  "and folds the older one in which such a prompt was one of several" \
  || bad "and folds the older one in which such a prompt was one of several" "no ledger.d/p264-oldmixed.tsv"

rm -f "$FROOT/state/session"/p264-* "$FROOT/state/ledger"/p264-*.tsv \
      "$FROOT/state/route"/p264-* "$FROOT/state/shape"/p264-* "$MEM/widget/ledger.d"/p264-*.tsv \
      "$FROOT/state/verified"/p264-* "$FROOT/state/skipped"/p264-* "$FROOT/state/machine"/p264-*
[ "$_p264_ld" = 1 ] || rmdir "$MEM/widget/ledger.d" 2>/dev/null
for _f in says.log routes.log verification.log; do
  if [ -f "$P264/$_f.keep" ]; then cp -p "$P264/$_f.keep" "$MEM/widget/$_f"; else rm -f "$MEM/widget/$_f"; fi
done
# Asserted, not assumed, for the reason given at the fixture's first cleanup.
_p264_same "the #264 block leaves the logs and the session state as it found them" \
  "$_p264_found" "$(_p264_snap)"

# Whether Stop should stay quiet, as a predicate rather than hook-internal logic.
# The first version of this test drove the whole Stop hook through a fixture
# whose transcript path was empty, so the complaint fired in neither direction
# and "it stays quiet on a guess" passed by finding nothing — the vacuous-check
# shape this session has now hit three times.
SG="$TMP/routestate"; mkdir -p "$SG"
_guessed() { printf '%s' "$2" > "$SG/s"; ( . "$FROOT/harness/lib/route.sh"
            felix_route_state_guessed "$SG/s" ) && printf yes || printf no; }
is "a route off the tree is a guess"        "$(_guessed x "$(printf 'harness:done\ttree')")"   "yes"
is "one from what you typed is not"         "$(_guessed x "$(printf 'harness:done\tprompt')")" "no"
is "nor is one from both"                   "$(_guessed x "$(printf 'harness:done\tmixed')")"  "no"
is "a state file from before this existed complains, as it did" \
   "$(_guessed x 'harness:done')" "no"
# The shape production actually emits. A due step is a play entry, so it carries
# a colon of its own — and the colon scheme this replaced read "brainstorming"
# as the provenance and never matched anything. Every fixture above uses a due
# step of `done`, which is why they all passed while the real value did not.
is "a due step containing a colon does not shift it" \
   "$(_guessed x "$(printf 'harness:superpowers:brainstorming\ttree')")" "yes"
rm -f "$SG/s"
( . "$FROOT/harness/lib/route.sh"; felix_route_state_guessed "$SG/s" ) \
  && bad "a missing state file is not a guess" || ok "a missing state file is not a guess"

# The check that decides whether Felix speaks at all, and it had no test.
#
# `felix_route_step_used` greps "attributionSkill":"$owner with the closing quote
# missing, so it is a prefix match on the plugin. Any one skill from a plugin
# therefore satisfies every step that plugin owns. superpowers ships
# `using-superpowers`, whose own description tells a session to invoke it before
# anything else, and 16 of the 23 capability slots in Felix's own table are
# superpowers:*. So from turn one of nearly every session felix_route_due found
# every step already used and rendered no requirement — while
# felix_ledger_note_named appended the play as `named` regardless. 152 namings
# recorded on disk against 37 a session was ever shown.
#
# That is not a cosmetic bug: it is the instrument. Every follow-through figure
# this project has quoted about sessions ignoring Felix was computed against a
# denominator that counts suggestions nobody was given.
# The fixture carries BOTH attribution keys, because production writes both on
# one line — 1483 such lines for using-superpowers alone. A fixture with only
# attributionSkill passes against a fix that repairs that line and leaves the
# attributionPlugin line, which is correctly quoted and just as wrong: it asks
# whether the PLUGIN ran, not whether the STEP did. `"attributionPlugin":
# "superpowers"` occurs 7137 times. That fix would have shipped green and
# changed nothing, which is the shape this project keeps re-finding.
SU="$TMP/stepused"; mkdir -p "$SU"
_su_line() { printf '{"attributionSkill":"%s","attributionPlugin":"%s","type":"assistant"}\n' "$1" "${1%%:*}"; }
_su_line superpowers:using-superpowers > "$SU/t.jsonl"
for _s in superpowers:brainstorming superpowers:writing-plans superpowers:test-driven-development; do
  ( . "$FROOT/harness/lib/route.sh"; felix_route_step_used "$SU/t.jsonl" "$_s" ) \
    && bad "one superpowers skill does not mark $_s used" "reported used" \
    || ok  "one superpowers skill does not mark $_s used"
done
# The other direction, or the fix silences every play forever instead of always.
_su_line superpowers:brainstorming > "$SU/t.jsonl"
( . "$FROOT/harness/lib/route.sh"; felix_route_step_used "$SU/t.jsonl" "superpowers:brainstorming" ) \
  && ok  "the step itself still counts as used" \
  || bad "the step itself still counts as used" "not detected"
# A bare plugin name is the case the owner line exists for: any skill it ships
# counts, because there is no qualified step to match exactly.
_su_line code-review:review-changes > "$SU/t.jsonl"
( . "$FROOT/harness/lib/route.sh"; felix_route_step_used "$SU/t.jsonl" "code-review" ) \
  && ok  "a bare plugin step is used when one of its skills ran" \
  || bad "a bare plugin step is used when one of its skills ran" "not detected"
# The MCP probe is an owner-level answer too, and the first version of this fix
# gated the other two and left it outside — the same defect, surviving in the
# one branch no assertion reached. A plugin that ships an MCP server shows up
# only as a tool name, so the signal is real, but it says the PLUGIN was used
# and can never say which skill was.
printf '{"name":"mcp__plugin_semgrep_guardian__get_semgrep_sast_findings"}\n' > "$SU/t.jsonl"
( . "$FROOT/harness/lib/route.sh"; felix_route_step_used "$SU/t.jsonl" "semgrep:some-skill" ) \
  && bad "an mcp call does not mark a qualified step of that plugin used" "reported used" \
  || ok  "an mcp call does not mark a qualified step of that plugin used"
( . "$FROOT/harness/lib/route.sh"; felix_route_step_used "$SU/t.jsonl" "semgrep" ) \
  && ok  "an mcp call does mark the bare plugin step used" \
  || bad "an mcp call does mark the bare plugin step used" "not detected"
rm -rf "$SU"

# A route must match its own name, and three did not.
#
# `debug` named systematic-debugging and did not have the word "debug" among its
# keywords, so "debug why the harness hook is failing" scored the harness row
# instead and was told to go and brainstorm. `ship` and `tooling` were the same
# shape. This is not a guess about vocabulary — it is the one keyword a row is
# guaranteed to want, and it is checkable, so it is checked against the shipped
# table rather than a fixture.
REALT="$(cd "$REAL_HARNESS/../.." && pwd)/projects/felix/routes.tsv"
if [ -f "$REALT" ]; then
  selfmiss="$(awk -F'\t' '!/^#/ && NF>=2 {
      n=$1; split($2,a," "); found=0
      for (i in a) if (index(n,a[i])==1) found=1
      if (!found) printf "%s ", n
    }' "$REALT")"
  is "every route matches its own name" "$(printf '%s' "$selfmiss" | tr -d ' ')" ""
fi

# #57, confirmed item 3, and the same argument as the route check above: it is
# checkable against the shipped table, so it is checked there.
#
# An evidence rule whose `requires` matches everything can only ever report
# `met`. felix_evidence_check evaluates `requires` only after `when` has
# matched, and `when` matching means the path list is non-empty — so a `requires`
# of `.` is satisfied by the very paths that triggered the rule. The deploy row
# was exactly that, on the one act that puts an engine into every session on the
# machine.
REALE="$(cd "$REAL_HARNESS/../.." && pwd)/projects/felix/evidence.tsv"
if [ -f "$REALE" ]; then
  wild="$(awk -F'\t' '!/^#/ && NF>=3 && ($3=="." || $3==".*" || $3=="^.*$") {printf "%s ", $1}' "$REALE")"
  is "no evidence rule requires a pattern that matches everything" \
     "$(printf '%s' "$wild" | tr -d ' ')" ""
else
  skip "no evidence rule requires a pattern that matches everything" "no shipped table"
fi

# The log and the router had drifted apart, and only the log was ever read back.
# `felix_route_log` stripped the pairs the runtime owns and not the JSON keys, so
# every miss recorded the literal words `prompt` and `prompt_id`. They were the
# top two rows of `felix route --promote` — the one mechanism for improving the
# table — above every word anybody typed. The router had been right the whole
# time; the record of what it saw was not. Two tokenisers with one job is the
# defect, so promote reads the router's.
#
# The fix is on the READ side, and the first version of it was not. Stripping the
# keys on the way into the log as well broke `felix monitor`, whose route panel
# extracts the sentence by looking for the literal `"prompt":` key — with it
# gone the parser falls through and every new row renders as
# `{ , "repair the queue worker"}` instead of the sentence. The log is a record
# for a person to read; promote's requirement is satisfied entirely by
# `_felix_route_words` on the way out, which also cleans rows written before any
# of this. Asserted on both sides now, because asserting on one is what broke
# the other.
RLP="$TMP/routelog"; mkdir -p "$RLP" "$MEM/routelog"
( . "$FROOT/harness/lib/route.sh"
  felix_route_log "$RLP" "-" 0 '{"session_id":"s","transcript_path":"/home/u/migration-endpoint/a.jsonl","prompt_id":"9f2","prompt":"repair the queue worker"}' )
logged="$(cut -f4 "$MEM/routelog/routes.log")"
has "what a miss records is what was typed" "$logged" "queue"
case "$logged" in
  *session_id*|*migration*) bad "and not the pairs the runtime owns" "$logged" ;;
  *)                        ok  "and not the pairs the runtime owns" ;;
esac
rendered="$( . "$FROOT/harness/lib/monitor.sh"; _felix_mon_prompt "$logged" )"
is "and the monitor still renders the sentence, not the JSON around it" \
   "$rendered" "repair the queue worker"

# Promote then counts those, through the same filter that scored them. A word the
# router discards can never be a word the table is missing.
i=0; while [ "$i" -lt 3 ]; do
  ( . "$FROOT/harness/lib/route.sh"
    felix_route_log "$RLP" "-" 0 '{"prompt_id":"9f2","prompt":"repair the queue worker that would help"}' )
  i=$((i+1))
done
p="$( . "$FROOT/harness/lib/route.sh"; FELIX_ROUTE_PROMOTE_MIN=2 felix_route_promote "$RLP" )"
has "a real word rises" "$p" "queue"
case "$p" in
  *prompt*) bad "an envelope field name never does" "$p" ;;
  *)        ok  "an envelope field name never does" ;;
esac
case "$p" in
  *would*|*help*) bad "nor filler the router already discards" "$p" ;;
  *)              ok  "nor filler the router already discards" ;;
esac

# The path rule on both sides of the log, for the same reason as the keys. On
# the way in, so a miss records what was typed and not the harness's scratch
# directory; on the way out, so rows written before the rule existed stop
# proposing `documents` to --promote. The read side is what cleans rows already
# on disk, which is what the fix above did for `prompt_id`.
( . "$FROOT/harness/lib/route.sh"
  felix_route_log "$RLP" "-" 0 '{"session_id":"s","scratchpad_dir":"/Users/u/Documents/felix/scratch","prompt":"repair the queue worker"}' )
logged="$(tail -1 "$MEM/routelog/routes.log" | cut -f4)"
case "$logged" in
  *Documents*|*scratch*) bad "a path-valued key is not written to the log" "$logged" ;;
  *)                     ok  "a path-valued key is not written to the log" ;;
esac
has "and the sentence still is" "$logged" "queue"
# Three rows the old code wrote, path and all.
i=0; while [ "$i" -lt 3 ]; do
  printf '2026-08-26T00:00:00Z\t-\t0\t%s\n' \
    '{"session_id":"s","scratchpad_dir":"/Users/u/Documents/felix/scratch","prompt":"repair the queue worker"}' \
    >> "$MEM/routelog/routes.log"
  i=$((i+1))
done
p="$( . "$FROOT/harness/lib/route.sh"; FELIX_ROUTE_PROMOTE_MIN=2 felix_route_promote "$RLP" )"
case "$p" in
  *documents*|*scratch*) bad "and a row already on disk is cleaned on the way out" "$p" ;;
  *)                     ok  "and a row already on disk is cleaned on the way out" ;;
esac

# A row can end mid-character. `cut -c1-160` is byte-oriented wherever the hook
# actually runs — LANG is unset in that environment and LC_CTYPE is C — so when
# byte 160 lands inside a multibyte character the log keeps half of it. Reading
# that back through `sed -E` in the UTF-8 locale a Terminal has raises
# "illegal byte sequence"; under `set -o pipefail` the whole pipeline returns 1,
# promote returns nothing, and the caller printed "Nothing has missed often
# enough to be worth a row yet." A crash reported as an all-clear, in the report
# that exists to find what the routing table is missing — and worse in the
# middle of a log, where the rows after the bad one vanish with no cue at all.
#
# Two independent defects, so two assertions: the pipeline must not care, and
# the caller must not read emptiness as success.
BADL="$TMP/badlocale"; mkdir -p "$BADL" "$MEM/badlocale"
{ printf '2026-08-13T00:00:00Z\t-\t0\t{ ,"prompt":"repair the queue worker"}\n'
  printf '2026-08-13T00:00:01Z\t-\t0\t{ ,"prompt":"repair the queue worker"}\n'
  printf '2026-08-13T00:00:02Z\t-\t0\t{ ,"prompt":"stalled deploy \xe2\x80"}\n'
  printf '2026-08-13T00:00:03Z\t-\t0\t{ ,"prompt":"repair the queue worker"}\n'
} > "$MEM/badlocale/routes.log"
bp="$( . "$FROOT/harness/lib/route.sh"
       export LC_ALL=en_US.UTF-8
       FELIX_ROUTE_PROMOTE_MIN=3 felix_route_promote "$BADL" 2>/dev/null )" && brc=0 || brc=$?
is  "a half-written character does not fail the whole report" "$brc" "0"
has "and the rows on both sides of it are still counted"      "$bp"  "queue"

# The tree may corroborate, never outvote. Without a cap, a checkout carrying a
# few hundred untracked path tokens drowns out the four words you typed.
mkdir -p "$REPO/noise"
i=0; while [ "$i" -lt 40 ]; do printf 'x\n' > "$REPO/noise/component-layout-styling-$i.css"; i=$((i+1)); done
out="$(_route "add a migration for the endpoint schema")"
has "a wall of tree tokens cannot outvote the prompt" "$out" "backend"
rm -rf "$REPO/noise"

RHK="$FROOT/harness/hooks/user-prompt"
S1='{"session_id":"sess-aaa","prompt":"let us build the results page"}'
S2='{"session_id":"sess-aaa","prompt":"let us build the results page again"}'
S3='{"session_id":"sess-aaa","prompt":"add a migration for the endpoint schema"}'
_hook() { ( cd "$REPO" && printf '%s' "$1" | "$RHK" 2>&1 ); }
_ctx() { printf '%s' "$1" | python3 -c 'import json,sys;print(json.load(sys.stdin)["hookSpecificOutput"]["additionalContext"])' 2>/dev/null; }

rm -rf "$FROOT/state/route"
out="$(_hook "$S1")"; ctx="$(_ctx "$out")"
has "the hook routes on the first prompt" "$ctx" "frontend"
# One block, not two. Two injections fight for the same attention.
n="$(printf '%s' "$out" | grep -c 'hookSpecificOutput')"
is "route and lessons arrive as one block" "$n" "1"

# A prompt where both genuinely apply. Two injections competing for the same
# attention is how both get skimmed, so they must arrive as one.
rm -rf "$FROOT/state/route"
out="$(_hook '{"session_id":"sess-bbb","prompt":"add a migration for the endpoint schema rollback"}')"
ctx="$(_ctx "$out")"
has "the route is there when both apply" "$ctx" "backend"
has "and the lesson is in the same block" "$ctx" "L-1"
n="$(printf '%s' "$out" | grep -c 'hookSpecificOutput')"
is "still exactly one block"              "$n" "1"
rm -rf "$FROOT/state/route"
out="$(_hook "$S1")" >/dev/null 2>&1

out="$(_hook "$S2")"; ctx="$(_ctx "$out")"
case "$ctx" in
  *"routed this to"*) bad "the same route does not repeat itself" "$ctx" ;;
  *) ok "the same route does not repeat itself" ;;
esac

# Decision A-prime, approved 2026-08-30, reverses the assertion that stood
# here ("a change of route speaks again"). A mid-session keyword re-route was
# every live misroute on #29 — five causes, ~2% precision — so it is logged
# and recorded in state, and NOT rendered. The declaration moment (first
# routed turn) and transcript-proven step advances are the moments that speak;
# both are asserted elsewhere in this file and unchanged.
out="$(_hook "$S3")"; ctx="$(_ctx "$out")"
case "$ctx" in
  *"routed this to"*) bad "a mid-session route change does not render" "$ctx" ;;
  *) ok "a mid-session route change does not render" ;;
esac
has "but it is logged, so the pivot stays observable" \
    "$(tail -1 "$MEM/widget/routes.log" 2>/dev/null)" "backend"
is  "and the state now carries the new route, for the finish-line judge" \
    "$(cut -f1 < "$FROOT/state/route/sess-aaa" 2>/dev/null | cut -d: -f1)" "backend"

# A guessed route and an ignored instruction are different facts, and the state
# file threw the difference away.
#
# `felix route` already says which it is — "read off the working tree, not the
# prompt: nothing you typed named a kind of work" — from the prompt-contributed
# half of the score. The state written for `Stop` recorded only route and due
# step, so `Stop` ended sessions complaining that a play went unused whether the
# route came from what somebody typed or from what happened to be checked out.
# It fired five times in one session, at least three of them on open guesses.
#
# Provenance is stored as a word rather than the score it came from. The score
# is an implementation detail of today's ranking function; what the contract
# needs to survive a re-weighting is whether the obligation was grounded in
# intent at all.
rm -rf "$FROOT/state/route"
_hook '{"session_id":"prov-p","prompt":"let us build the results page"}' >/dev/null 2>&1
is "a route from what you typed is recorded as such" \
   "$(cut -f2 < "$FROOT/state/route/prov-p" 2>/dev/null)" "prompt"

# Nothing routable typed, so whatever it picked came off the tree.
rm -rf "$FROOT/state/route"
_hook '{"session_id":"prov-t","prompt":"ok"}' >/dev/null 2>&1
if [ -f "$FROOT/state/route/prov-t" ]; then
  case "$(cut -f2 < "$FROOT/state/route/prov-t")" in
    tree|mixed) ok  "a route off the tree is not recorded as typed" ;;
    *)          bad "a route off the tree is not recorded as typed" \
                    "$(cat "$FROOT/state/route/prov-t")" ;;
  esac
else
  ok "a route off the tree is not recorded as typed"
fi

# Dedup must ignore it. The state value is also the announce key, so a third
# field that varies would make a route re-announce itself with nothing changed —
# which is the noise this exists to remove, reintroduced one field along.
rm -rf "$FROOT/state/route"
_hook "$S1" >/dev/null 2>&1
# The same prompt twice, with only the third field altered in between, so
# provenance is the single variable. Planting a route name here instead would
# have tested whatever that fixture happens to route to.
k="$(cut -f1 < "$FROOT/state/route/sess-aaa" 2>/dev/null)"
printf '%s\ttree' "$k" > "$FROOT/state/route/sess-aaa"
out="$(_hook "$S1")"; ctx="$(_ctx "$out")"
case "$ctx" in
  *"routed this to"*) bad "provenance is not part of the announce key" "$ctx" ;;
  *)                  ok  "provenance is not part of the announce key" ;;
esac

# State is a convenience. Losing it must cost a repeated block, never a session.
chmod 000 "$FROOT/state/route" 2>/dev/null
out="$(cd "$REPO" && printf '%s' "$S1" | "$RHK" 2>&1)"; rc=$?
is "an unwritable state directory still exits 0" "$rc" "0"
chmod 755 "$FROOT/state/route" 2>/dev/null

RLOG="$MEM/widget/routes.log"
[ -s "$RLOG" ] && ok "every decision is logged" || bad "every decision is logged" "no $RLOG"
grep -q 'frontend' "$RLOG" 2>/dev/null && ok "hits are logged" || bad "hits are logged"
out="$(_route "zzzquux flibbertigibbet")" >/dev/null 2>&1
out="$(_route "zzzquux flibbertigibbet")" >/dev/null 2>&1
out="$(_route "zzzquux wobblethorpe")"    >/dev/null 2>&1
grep -q '	-	' "$RLOG" 2>/dev/null && ok "misses are logged too" || bad "misses are logged too"

out="$(cd "$REPO" && "$FELIX" route --promote 2>&1)"
has "promote surfaces a word that keeps missing" "$out" "zzzquux"

