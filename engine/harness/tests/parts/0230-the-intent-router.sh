printf '\nthe intent router\n'
# Say what you are doing and get the right kit, without naming it. The chain is
# routes.tsv -> profiles.tsv -> stack.tsv, and only the first link is new.
cp "$REAL_HARNESS/templates/routes.tsv"   "$FROOT/projects/widget/routes.tsv"
cp "$REAL_HARNESS/templates/profiles.tsv" "$FROOT/projects/widget/profiles.tsv"
cat > "$FROOT/projects/widget/stack.tsv" <<'EOF'
plugin	frontend-design@claude-plugins-official	-	low	frontend
plugin	playwright@claude-plugins-official	-	low	e2e
skill	impeccable	-	low	frontend
EOF
printf 'frontend\ne2e\n' > "$FROOT/projects/widget/capabilities"

_route() { ( cd "${2:-$REPO}" && "$FELIX" route --for "$1" 2>&1 ); }

out="$(_route "let us build the results page")"
has "a frontend prompt routes to frontend" "$out" "frontend"
has "and names the play in order"          "$out" "frontend-design"
has "with the critique step after it"      "$out" "impeccable"

# The prompt is what you just said; the tree is only where you are standing.
# Without weighting, a dirty frontend tree drags every question toward frontend.
mkdir -p "$REPO/ui"; printf 'x\n' > "$REPO/ui/page.css"
out="$(_route "add a migration for the endpoint schema")"
has "the prompt outweighs the working tree" "$out" "backend"
rm -rf "$REPO/ui"

# Below the threshold nothing is said at all. One stray path token must not be
# enough to decide what you meant.
out="$(_route "ok")"
is "a prompt with no signal says nothing" "${#out}" "0"

# Two corroborating tree tokens do meet the threshold, on purpose. But a route
# the tree chose is a different claim from one you asked for, and presenting the
# second as the first is quietly lying about why.
mkdir -p "$REPO/ui"; printf 'x\n' > "$REPO/ui/page.css"; printf 'x\n' > "$REPO/ui/component.js"
out="$(_route "ok")"
has "the working tree alone can route"       "$out" "frontend"
has "and says so rather than implying I did" "$out" "working tree"
out="$(_route "render the modal component")"
case "$out" in
  *"working tree"*) bad "a typed intent is not labelled a guess" "$out" ;;
  *) ok "a typed intent is not labelled a guess" ;;
esac
rm -rf "$REPO/ui"

out="$(cd "$REPO" && "$FELIX" route --for "let us build the results page" --explain 2>&1)"
has "explain shows the losing routes too" "$out" "build"

# A play entry the project never declared is named, not hidden. It is the seam
# to the discovery slice, and silently dropping it would hide the gap.
cat >> "$FROOT/projects/widget/routes.tsv" <<'EOF'
ghost	nonesuch	frontend	not-declared-anywhere
EOF
out="$(_route "nonesuch")"
has "an undeclared tool is reported, not hidden" "$out" "not declared"

# A malformed row must not take the file down with it.
printf 'broken-row-with-no-tabs\n' >> "$FROOT/projects/widget/routes.tsv"
out="$(_route "let us build the results page")"
has "a malformed row is skipped, others still match" "$out" "frontend"

# The hook is handed the whole payload, so the envelope's own field names are in
# the token stream. A route keyed on one of them scored on every single turn
# whatever was typed, which is invisible until a project's subject matter
# happens to be prompts. Found by running the hook against a real repository.
cat >> "$FROOT/projects/widget/routes.tsv" <<'EOF'
envelope	prompt session transcript permission	frontend	-
EOF
out="$(cd "$REPO" && printf '{"session_id":"s","prompt":"the migration schema needs an index"}' | "$FROOT/harness/hooks/user-prompt" 2>&1)"
case "$out" in
  *envelope*) bad "the payload envelope does not decide the route" "$out" ;;
  *) ok "the payload envelope does not decide the route" ;;
esac
# ...but the words themselves must survive. Banning them was the first fix and
# was worse than the bug: asking about a hook matched nothing at all, because
# the word had been blacklisted to silence a field name of the same name.
toks="$( . "$FROOT/harness/lib/route.sh"
         felix_route_tokens '{"session_id":"s","prompt":"the stop hook is blocking"}' | tr '\n' ' ' )"
has  "a word shared with a field name still counts" "$toks" "hook"
case "$toks" in
  *session_id*|*" session "*) bad "but the field names themselves are gone" "$toks" ;;
  *) ok "but the field names themselves are gone" ;;
esac

# The keys were the half that got fixed. The VALUES are still in the stream, and
# they are worse: transcript_path and cwd carry the whole checkout path, so a
# home directory called Documents or a worktree branch named ...-review-... puts
# those words in as if they had been typed — at double weight, which is the
# score reserved for what you actually said. Found by watching `continue` route
# to a document skill.
out="$(cd "$REPO" && printf '{"session_id":"s","transcript_path":"/home/u/migration-schema-endpoint/a.jsonl","cwd":"/home/u/queue-worker","prompt":"the button layout is wrong"}' \
       | "$FROOT/harness/hooks/user-prompt" 2>&1)"
case "$out" in
  *backend*) bad "a path in the envelope does not decide the route" "$out" ;;
  *) ok "a path in the envelope does not decide the route" ;;
esac
# Asserted on tokens, not on the hook's output: the hook announces only when the
# route changes, so a presence check there passes or fails on prior state rather
# than on the thing being tested.
toks="$( . "$FROOT/harness/lib/route.sh"
         felix_route_tokens '{"transcript_path":"/home/u/migration-schema-endpoint/a.jsonl","prompt":"the button layout is wrong"}' | tr '\n' ' ' )"
has "and what was typed still counts" "$toks" "layout"
case "$toks" in
  *migration*|*endpoint*) bad "while the path around it does not" "$toks" ;;
  *) ok "while the path around it does not" ;;
esac

toks="$( . "$FROOT/harness/lib/route.sh"
         felix_route_tokens '{"transcript_path":"/home/u/documents-felix/a.jsonl","prompt":"continue"}' | tr '\n' ' ' )"
case "$toks" in
  *documents*|*jsonl*) bad "envelope path values are gone from the tokens" "$toks" ;;
  *) ok "envelope path values are gone from the tokens" ;;
esac
# The named list above was the third fix, and it was an instance. The desktop
# harness then added `scratchpad_dir` — an absolute path, and on this machine
# one under a directory called Documents — and 18 of the 20 rows routed to a
# document skill between 2026-08-25 and 2026-09-02 carried it. Four declines
# in decisions.log blamed topic-versus-task; the cause was a key the list had
# never heard of. So the rule is now the shape the runtime's values share
# rather than the names they have had so far: a field whose value is an
# absolute path was filled in by the runtime, and goes whole. The key here is
# invented, so the list can never be what saves it.
toks="$( . "$FROOT/harness/lib/route.sh"
         felix_route_tokens '{"session_id":"s","next_harness_field":"/home/u/documents-felix/migration-schema-endpoint/scratch","prompt":"the button layout is wrong"}' | tr '\n' ' ' )"
has "a path-valued key the list never heard of still counts what was typed" "$toks" "layout"
case "$toks" in
  *documents*|*migration*|*scratch*) bad "and its path is gone from the tokens whatever the key is called" "$toks" ;;
  *) ok "and its path is gone from the tokens whatever the key is called" ;;
esac
# A fresh session, because the hook renders a route only on a session's first
# routed turn (Decision A-prime) — driven under session `s` this assertion
# passed on silence before the fix existed, which is the vacuous shape the
# comment above warns about. Both halves asserted: that it routed at all, and
# on what was typed rather than on the path.
out="$(cd "$REPO" && printf '{"session_id":"path-valued-key","next_harness_field":"/home/u/migration-schema-endpoint/scratch","prompt":"the button layout is wrong"}' \
       | "$FROOT/harness/hooks/user-prompt" 2>&1)"
has "so a path-valued key the list never heard of does not decide the route" "$out" "frontend"
case "$out" in
  *backend*) bad "and the route its path named is not taken" "$out" ;;
  *) ok "and the route its path named is not taken" ;;
esac
# The one value in the envelope a person typed is exempt, whatever it opens
# with. A slash command and a pasted path both begin with `/`, and a rule that
# read those as the runtime's would throw away the whole prompt on exactly the
# turns that name a file.
toks="$( . "$FROOT/harness/lib/route.sh"
         felix_route_tokens '{"session_id":"s","prompt":"/home/u/report.pdf needs the layout fixed"}' | tr '\n' ' ' )"
has "but a prompt that opens with a slash is still what was typed" "$toks" "layout"
has "path and all"                                                 "$toks" "report"
# Nobody typed a task notification. The hook is handed every UserPromptSubmit
# payload, and the runtime uses that channel for its own messages too — task
# completions, system reminders, the Stop hook's own feedback. Five of the 89
# rows in Felix's routes.log are machine text scored as if a person had written
# it, and they picked real routes: three `harness`, one `research`, one `gate`.
#
# Three consequences, and the third is a loop. The play announcement fires at
# text nobody wrote. The miss log accrues rows that skew `--promote`. And the
# Stop hook then asks why the named play went unused — a question generated by
# a route that fired on a machine's own message.
#
# Matched on STRUCTURE, never on vocabulary. `<task-notification>` at the start
# of the payload is a tag no sentence opens with; the word "notification" is one
# people type, and this project has already broken a word once by banning it to
# silence a field name. Only the literal opening marker counts.
#
# Asked for the kind, not a yes: every one of these lands inside a session a
# person holds, and a session-level answer would record that session as
# nothing (#264).
_mach() { ( . "$FROOT/harness/lib/route.sh"; felix_route_machine "$1" ) || printf no; }
is "a task notification is not a prompt"  "$(_mach '<task-notification><task-id>x</task-id></task-notification>')" "message"
is "nor is a system reminder"             "$(_mach '<system-reminder>the gate has not run</system-reminder>')"      "message"
is "nor the stop hook talking to itself"  "$(_mach 'Stop hook feedback:
The gate last ran at ...')"                                                                                          "message"
is "nor the all-caps sentinel"            "$(_mach '[SYSTEM NOTIFICATION - NOT USER INPUT] a background task ended')" "message"
# The word, as opposed to the tag, belongs to whoever typed it.
is "but asking about a notification is a prompt" \
   "$(_mach 'why did the task-notification route to harness?')" "no"
is "and so is ordinary work"              "$(_mach 'fix the queue worker')" "no"
is "an empty payload is not machine text" "$(_mach '')" "no"

# The hook holds the whole envelope, so the two compose. Extraction takes the
# FIRST copy of the key: `s/.*"prompt"/` would bind to the last, and a later copy
# in the envelope being read in preference to the real one is already a lesson
# in this repository.
_pv() { ( . "$FROOT/harness/lib/route.sh"; felix_route_prompt "$1" ); }
case "$(_pv '{"session_id":"s","prompt":"<task-notification>done</task-notification>"}')" in
  '<task-notification>'*) ok  "the prompt is read out of the envelope" ;;
  *)                      bad "the prompt is read out of the envelope" "$(_pv '{"prompt":"<task-notification>x"}')" ;;
esac
case "$(_pv '{"prompt":"fix the queue","extra":"prompt: not this one"}')" in
  'fix the queue'*) ok  "and from the first copy of the key, not a later one" ;;
  *)                bad "and from the first copy of the key, not a later one" ;;
esac
_mp() { ( . "$FROOT/harness/lib/route.sh"
          felix_route_machine "$(felix_route_prompt "$1")" ) || printf no; }
is "a notification payload is machine text end to end" \
   "$(_mp '{"session_id":"s","prompt":"<task-notification>done</task-notification>"}')" "message"
is "and a real one still routes" \
   "$(_mp '{"session_id":"s","prompt":"fix the queue worker"}')" "no"

# A path the person actually typed is theirs, and must still route.
toks="$( . "$FROOT/harness/lib/route.sh"
         felix_route_tokens '{"prompt":"fix src/queue/worker.py"}' | tr '\n' ' ' )"
has "a path you typed yourself still counts" "$toks" "worker"

# #264. The platform asks for a session summary by starting a session of its
# own and typing into it: a fixed opening, 445 characters and identical in both
# CLI versions seen, then the whole log of the session being summarised,
# `**User:**` lines included, then a fixed closing of 353 that asks for the
# output format. It arrives here as that session's first prompt.
# So the words of somebody else's log chose a route, the play was named, a
# brief went to says.log, the session was marked, and session-end folded it
# into ledger.d as a session that was pointed at a play and never reached it.
# 78 of those across three projects in three weeks, none of which ever
# completed: every one died on an expired login. 62% of felix's ledger
# denominator was sessions nobody held, in the one column `felix ledger` calls
# unconfounded.
#
# A summary request is therefore recorded as nothing at all: no output, no
# mark, no route, no brief, no named row. Asserted against the files rather
# than a predicate, because the predicate this would sit beside has only ever
# gated routing. The mark and the brief run whatever it says, and a fix that
# stops the route and leaves those is the half-fix this file already carries
# for task notifications.
#
# ledger.d is written by session-end, never by the prompt hook, so looking there
# after the prompt hook alone could not fail. The same session is ended through
# the real hook, which is how every one of the 78 was folded.
#
# The payload is the platform's own: its field set, the prompt last, the value
# JSON-escaped, so `\n` is the two characters the hook actually holds.
P264="$TMP/p264"; mkdir -p "$P264"
P264_OPEN='Below is a conversation log from a Claude Code coding session.\nCreate a summary to help the next session quickly understand the context.\n\n## Prioritize including\n- Design decisions and technology choices made this session\n- Bugs and problems solved\n- Files changed or created, with a brief description of changes\n- Unfinished tasks and work to continue in the next session\n- Important context the next session needs to know\n\n## Conversation log\n'
# The log is where the route came from: words a person typed, in another
# session, about other work.
P264_LOG='**User:** the build is broken and the stacktrace shows a crash on reproduce\n\n**Assistant:** Reproduced it. \"felix gate\" fails on the migration.\n\n**User:** fix it and add a rollback\n'
P264_CLOSE='\n\n## Output format (Markdown only, no preamble)\n\n## Session Summary\n\n### Tasks\n(main tasks worked on this session)\n\n### Decisions Made\n(design decisions and technology choices)\n\n### Files Modified\n(files changed or created)\n\n### Unresolved Issues\n(unfinished tasks and work to continue)\n\n### Next Session Context\n(important context for the next session)'
P264_REQ="$P264_OPEN$P264_LOG$P264_CLOSE"
_p264_payload() {   # sid, the prompt value as JSON holds it, [space after the colon]
  printf '{"session_id":"%s","transcript_path":"%s/%s.jsonl","cwd":"%s","prompt_id":"%s-id","permission_mode":"default","hook_event_name":"UserPromptSubmit","prompt":%s"%s"}' \
    "$1" "$P264" "$1" "$REPO" "$1" "${3:-}" "$2"
}
# The payload's cwd is the directory the hook runs in. _p264_payload says $REPO
# whatever checkout the hook is run in, a cwd no platform sends: the CLI's is
# the hook's own, and Desktop's names where the session is. A hook that stands
# where the payload says (felix_hook_enter) would leave for $REPO.
_p264_prompt() { local p="${1/\"cwd\":\"$REPO\"/\"cwd\":\"${2:-$REPO}\"}"
                 ( cd "${2:-$REPO}" && printf '%s' "$p" | "$FROOT/harness/hooks/user-prompt" 2>&1 ); }
_p264_end()    { ( cd "${2:-$REPO}" && printf '{"session_id":"%s","hook_event_name":"SessionEnd","reason":"other"}' "$1" \
                     | "$FROOT/harness/hooks/session-end" >/dev/null 2>&1 ); }
# Every file one prompt and its session's end can write, one line per file.
_p264_sum()  { if [ -f "$1" ]; then cksum < "$1"; else printf 'absent\n'; fi; }
_p264_tree() { ( cd "$1" 2>/dev/null || exit 0
                 find . -type f 2>/dev/null | LC_ALL=C sort | while IFS= read -r _f; do
                   printf '%s %s\n' "$_f" "$(cksum < "$_f")"; done ); }
_p264_snap() {
  printf 'says %s\n'   "$(_p264_sum "$MEM/widget/says.log")"
  printf 'routes %s\n' "$(_p264_sum "$MEM/widget/routes.log")"
  printf 'verif %s\n'  "$(_p264_sum "$MEM/widget/verification.log")"
  for _d in session ledger route shape verified machine; do
    _p264_tree "$FROOT/state/$_d" | sed "s|^|state/$_d |"
  done
  _p264_tree "$MEM/widget/ledger.d" | sed 's|^|ledger.d |'
}
_p264_of()   { printf '%s\n' "$2" | grep -E "^($1) "; }
_p264_diff() { diff <(printf '%s\n' "$1") <(printf '%s\n' "$2") | grep '^[<>]' | tr '\n' ' ' | cut -c1-300; }
_p264_same() { [ "$2" = "$3" ] && ok "$1" || bad "$1" "changed: $(_p264_diff "$2" "$3")"; }
_p264_rows()   { if [ -f "$1" ]; then wc -l < "$1" | tr -d ' '; else printf 0; fi; }
_p264_briefs() { awk -F'\t' -v s="$1" '$2 == "brief" && $3 == s' "$MEM/widget/says.log" 2>/dev/null | wc -l | tr -d ' '; }
# Left as found. A later section needs more skipped rows than the mandates
# rendered above it, and every brief written here would be one more mandate.
for _f in says.log routes.log verification.log; do
  [ -f "$MEM/widget/$_f" ] && cp -p "$MEM/widget/$_f" "$P264/$_f.keep"
done
_p264_ld=0; [ -d "$MEM/widget/ledger.d" ] && _p264_ld=1
_p264_found="$(_p264_snap)"

# The control first, through the same helpers on the same fixture, so a silence
# below cannot pass on a fixture that had stopped routing anything at all.
_rl0="$(_p264_rows "$MEM/widget/routes.log")"
out="$(_p264_prompt "$(_p264_payload p264-person 'the build is broken and the stacktrace shows a crash on reproduce')")"
_p264_end p264-person
is  "an ordinary first prompt still logs its routing decision" \
    "$(( $(_p264_rows "$MEM/widget/routes.log") - _rl0 ))" "1"
has "and still speaks, naming its play"              "$out" "systematic-debugging"
is  "and still writes its brief to says.log"         "$(_p264_briefs p264-person)" "1"
has "and still names its play in the session ledger" \
    "$(cat "$FROOT/state/ledger/p264-person.tsv" 2>/dev/null)" "named	superpowers:systematic-debugging"
[ -s "$FROOT/state/session/p264-person" ] \
  && ok  "and still marks the session it opens" \
  || bad "and still marks the session it opens" "no $FROOT/state/session/p264-person"
has "and session-end still folds it into ledger.d" \
    "$(cat "$MEM/widget/ledger.d/p264-person.tsv" 2>/dev/null)" "superpowers:systematic-debugging"

# Now the request, exactly as the platform sends it.
_b="$(_p264_snap)"
out="$(_p264_prompt "$(_p264_payload p264-summary "$P264_REQ")")"; _rc=$?
_m="$(_p264_snap)"
_p264_end p264-summary
_a="$(_p264_snap)"
is "the platform's summary request says nothing" "${#out}" "0"
# Quiet is not blocked. A prompt hook that exits 2 erases the prompt, and the
# summary is the platform's to have; this hook only declines to count it.
is "and exits 0, so the request itself still goes through" "$_rc" "0"
_p264_same "and writes no brief for it to says.log" \
  "$(_p264_of says "$_b")"          "$(_p264_of says "$_m")"
_p264_same "and logs no routing decision for it" \
  "$(_p264_of routes "$_b")"        "$(_p264_of routes "$_m")"
_p264_same "and leaves no session mark for a session nobody held" \
  "$(_p264_of state/session "$_b")" "$(_p264_of state/session "$_m")"
_p264_same "and names no play in a session ledger for it" \
  "$(_p264_of state/ledger "$_b")"  "$(_p264_of state/ledger "$_m")"
_p264_same "and keeps no route state for Stop to judge it by" \
  "$(_p264_of state/route "$_b")"   "$(_p264_of state/route "$_m")"
_p264_same "so session-end folds no phantom session into ledger.d" \
  "$(_p264_of ledger.d "$_b")"      "$(_p264_of ledger.d "$_a")"

# Leading whitespace, in the forms it can reach the hook: spaces as themselves,
# and a newline only as the two characters `\n`, because JSON cannot carry one
# raw. The envelope's own space after the colon is in the first one too.
_p264_none() {   # name, sid, payload: prints nothing and writes nothing, session-end included
  local b a o
  b="$(_p264_snap)"; o="$(_p264_prompt "$3")"; _p264_end "$2"; a="$(_p264_snap)"
  if [ -z "$o" ] && [ "$b" = "$a" ]; then ok "$1"
  else bad "$1" "printed ${#o} chars; changed: $(_p264_diff "$b" "$a")"; fi
}
_p264_none "a summary request behind leading spaces is recorded as nothing too" p264-summary-sp \
  "$(_p264_payload p264-summary-sp "   $P264_REQ" ' ')"
_p264_none "and so is one behind an escaped leading newline" p264-summary-nl \
  "$(_p264_payload p264-summary-nl "\\n$P264_REQ")"

# A person may quote the opening, or put its first lines above words of their
# own, or paste the whole of it. Anchored at the start on the whole opening and
# at the end on the whole closing, or the fix silences the one person asking
# why summaries route: the first two lines are a sentence anybody can reuse,
# the opening is text anybody can paste, and what follows either is the
# person's own instruction. A person does not end on the platform's output
# format as well.
_p264_person() {   # name, sid, prompt value: reached the router and marked its session
  local r0 r1
  r0="$(_p264_rows "$MEM/widget/routes.log")"
  _p264_prompt "$(_p264_payload "$2" "$3")" >/dev/null
  r1="$(_p264_rows "$MEM/widget/routes.log")"
  if [ "$((r1 - r0))" = 1 ] && [ -s "$FROOT/state/session/$2" ]; then ok "$1"
  else bad "$1" "routes.log grew by $((r1 - r0)); mark: $(cat "$FROOT/state/session/$2" 2>/dev/null || printf none)"; fi
}
_p264_person "a person quoting the summary opening mid-sentence is still routed and marked" p264-quoted \
  "can you check why 'Below is a conversation log from a Claude Code coding session.' routes to build?"
_p264_person "and so is one who opens on its first sentence and goes on in their own words" p264-firstline \
  'Below is a conversation log from a Claude Code coding session.\nThe build crashed halfway through it. Can you reproduce the crash and tell me why?'
_p264_person "and so is one who reuses its first two lines and then writes their own instruction" p264-twolines \
  'Below is a conversation log from a Claude Code coding session.\nCreate a summary to help the next session, then fix the crash it describes.\n\n**User:** the build is broken and the stacktrace shows a crash on reproduce\n'
_p264_person "and so is one who pastes the whole fixed opening and then writes their own instruction" p264-wholeopen \
  "${P264_OPEN}why does Felix brief this every time? the build is broken and the stacktrace shows a crash on reproduce"
_p264_person "and so is one who pastes a whole request and writes their own instruction after its closing" p264-afterclose \
  "${P264_REQ}\\n\\nnever mind the summary: the build is broken and the stacktrace shows a crash on reproduce"

# A worktree session's first prompt comes behind the platform's reminder, with
# what the person typed after it. It is the declaration moment, and its mark is
# what Stop's committed-work check reads. Hoisting the machine-text check into
# an early exit would drop that mark for every worktree session, 33 of them in
# the live logs, so it is pinned here. That the words after the reminder are
# not routed today is a gap of its own, and not what this asserts.
_p264_prompt "$(_p264_payload p264-worktree '<system-reminder>\nYou are operating in a git worktree.\nWorktree path: /home/u/.claude/worktrees/w-1a2b3c\nWorktree name: w-1a2b3c\n</system-reminder>\n\nContinue the migration work from the handoff')" >/dev/null
[ -s "$FROOT/state/session/p264-worktree" ] \
  && ok  "a worktree session's first prompt still marks the session, reminder and all" \
  || bad "a worktree session's first prompt still marks the session, reminder and all" "no mark"

# A scheduled task is the platform's envelope around a body a person wrote, and
# the session it starts is real work. A skip keyed on any leading tag loses it.
_p264_person "a scheduled task a person wrote is still routed and marked" p264-sched \
  '<scheduled-task name=\"cash-daily-watch\" file=\"/home/u/.claude/scheduled-tasks/cash-daily-watch/SKILL.md\">\nThis is an automated run of a scheduled task. The user is not present to answer questions.\n\nBuild the weekly plan and create the table.\n</scheduled-task>'
# So does the desktop's quote-attach, and under the quote is the person's own
# question.
_p264_person "a quoted attachment with the person's question under it is still routed and marked" p264-attach \
  '<!-- attach -->\n> The migration was rolled back by hand the last time it failed.\n\nwhy was that, and can you add a rollback path?'

# The other kinds nobody typed arrive inside a session a person started, and
# that difference is the whole of what the prompt hook may do with them. The
# summary is a session of its own: nothing in it was typed by anyone, so
# recording nothing loses nothing. A task notification, a system reminder, the
# Stop hook's feedback, the all-caps sentinel and another session's message
# land in a session somebody holds, and a person can paste any of them and type
# a question under it. Recorded as nothing, that person's first prompt lost its
# mark, and with the mark Stop's check on the work the session went on to
# commit. So these keep what they always had: not routed, because the router
# would score the block, and marked, taught and briefed as before.
#
# The pastes carry words the fixture's lessons match. That is checked first,
# typed by a person, so a brief below cannot be missing for want of a lesson.
out="$(_p264_prompt "$(_p264_payload p264-words 'the migration is broken: the stacktrace shows a crash on reproduce')")"
has "the words those messages carry still bring a lesson when a person types them" "$out" "L-1"
_p264_held() {   # name, sid, prompt value: a person's first prompt, marked and briefed
  _p264_prompt "$(_p264_payload "$2" "$3")" >/dev/null
  if [ -s "$FROOT/state/session/$2" ] && [ "$(_p264_briefs "$2")" = 1 ]; then ok "$1"
  else bad "$1" "mark: $(cat "$FROOT/state/session/$2" 2>/dev/null || printf none); briefs: $(_p264_briefs "$2")"; fi
}
_p264_held "a person who pastes the Stop hook's words and asks about them keeps the session's mark and brief" p264-stoppaste \
  'Stop hook feedback:\nThe gate has never run in this checkout.\n\nwhy does this keep firing? the migration is broken and the stacktrace shows a crash on reproduce'
_p264_held "and so does one who types a question under a task notification" p264-tnq \
  '<task-notification>\n<task-id>b7x2k9</task-id>\n<status>failed</status>\n<summary>Background command \"run the migration\" failed</summary>\n</task-notification>\n\nthe migration is broken: the stacktrace shows a crash on reproduce, what happened?'

# The mark is worth what Stop does with it, so end to end: a session that opens
# on the paste, commits, and stops is still asked about that work.
P264R="$TMP/p264-repo"; mkdir -p "$P264R"
( cd "$P264R" && git init -q -b main && printf 'contents\n' > WIDGET.txt && printf 'widget\n' > .felix \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm init ) >/dev/null 2>&1
P264R="$(cd "$P264R" && pwd -P)"
_p264_stop() { ( cd "$1" && printf '{"session_id":"%s","transcript_path":"%s/%s.jsonl","hook_event_name":"Stop","stop_hook_active":false}' \
                   "$2" "$P264" "$2" | "$FROOT/harness/hooks/stop" 2>&1 ); }
_p264_prompt "$(_p264_payload p264-e2e 'Stop hook feedback:\nThe gate has never run in this checkout.\n\nwhy does this keep firing when I already ran the gate?')" "$P264R" >/dev/null
printf 'committed work\n' >> "$P264R/WIDGET.txt"
( cd "$P264R" && git add -A && git -c user.name=t -c user.email=t@t commit -qm work ) >/dev/null 2>&1
out="$(_p264_stop "$P264R" p264-e2e)"
case "$out" in
  *'"decision"'*'"block"'*) ok  "and Stop still asks about the work such a session commits" ;;
  *)                        bad "and Stop still asks about the work such a session commits" "got [$out]" ;;
esac
# The same for a person whose first prompt is the summary request's whole
# opening with their own instruction under it. Taken for the platform's, that
# prompt left a marker and no mark, so Stop passed over the work the session
# committed, and the next prompt's mark was taken at the HEAD after it.
_p264_prompt "$(_p264_payload p264-e2eopen "${P264_OPEN}why does Felix brief this every time? fix route.sh so it is not routed, and commit it")" "$P264R" >/dev/null
printf 'committed fix\n' >> "$P264R/WIDGET.txt"
( cd "$P264R" && git add -A && git -c user.name=t -c user.email=t@t commit -qm fix ) >/dev/null 2>&1
out="$(_p264_stop "$P264R" p264-e2eopen)"
case "$out" in
  *'"decision"'*'"block"'*) ok  "and so does a session that opens on the summary request's opening and the person's own instruction" ;;
  *)                        bad "and so does a session that opens on the summary request's opening and the person's own instruction" "got [$out]" ;;
esac

# None of them is routed. Another session's message through SendMessage used
# to score as a prompt: 18 of them named their plays in the receiving session's
# ledger and moved its route to whatever the message was about.
_p264_amid() {   # name, sid, message: the receiving session's route and named plays as they were
  local b a
  _p264_prompt "$(_p264_payload "$2" 'let us build the results page')" >/dev/null
  b="$(_p264_snap)"; _p264_prompt "$(_p264_payload "$2" "$3")" >/dev/null; a="$(_p264_snap)"
  _p264_same "$1" "$(_p264_of 'routes|state/ledger|state/route' "$b")" \
                  "$(_p264_of 'routes|state/ledger|state/route' "$a")"
}
_p264_amid "a message from another session is not routed, and moves nothing in the session it lands in" p264-xs \
  '<cross-session-message from=\"uds:/tmp/cc-socks/41234.sock\" from-session=\"local_7f3a9c2e\" from-name=\"widget-review\" from-mode=\"bypass\">\nThe migration is broken: the stacktrace shows a crash on reproduce.\n</cross-session-message>'
_p264_amid "nor is a task notification" p264-tn \
  '<task-notification>\n<task-id>b7x2k9</task-id>\n<tool-use-id>toolu_01AbCdEf</tool-use-id>\n<output-file>/private/tmp/t/b7x2k9.output</output-file>\n<status>completed</status>\n<summary>Background command \"run the migration\" completed (exit code 0)</summary>\n</task-notification>'

