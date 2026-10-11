_fa_o="$(_fs_cm "$_fa_r")"
grep -qx ci "$_fa_p/capabilities" 2>/dev/null \
  && ok  "a full felix commission adopts what the checkout shows before it runs: capabilities holds ci" \
  || bad "a full felix commission adopts what the checkout shows before it runs: capabilities holds ci" "[$(cat "$_fa_p/capabilities")]"
case "$_fa_o" in
  *"adopted before this run, because the checkout shows them:"*"ci("*) ok  "and the report says so, naming ci with what it added" ;;
  *) bad "and the report says so, naming ci with what it added" "$(printf '%s\n' "$_fa_o" | head -n 4)" ;;
esac
is "and setup.tsv gains ci's two slug rows with {{REPO}} kept" \
   "$(awk -F'\t' '($1 == "risk-labels" || $1 == "ci-anthropic-key") && index($4, "--repo {{REPO}}") { print $1 }' "$_fa_p/setup.tsv" | tr '\n' ' ')" \
   "risk-labels ci-anthropic-key "
is "so nothing is left undeclared after the run" "$(_fa_undecl)" ""
_fa_pv0="$(_fa_pv)"
_fa_ss="$(cd "$_fa_r" && CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" 2>&1)"
case "$_fa_ss" in
  *"Adopted automatically"*)  bad "the next session start has nothing left to adopt" "$(printf '%s' "$_fa_ss" | head -c 300)" ;;
  *'"hookSpecificOutput"'*)   ok  "the next session start has nothing left to adopt" ;;
  *)                          bad "the next session start has nothing left to adopt" "the hook printed no banner, so no adoption line proves nothing" ;;
esac
_fa_pv1="$(_fa_pv)"
if [ -n "$_fa_pv0" ] && [ "$_fa_pv0" = "$_fa_pv1" ]; then
  ok  "and the commissioning policy version does not move"
else
  bad "and the commissioning policy version does not move" "[$_fa_pv0] then [$_fa_pv1]"
fi
_fa_rl="$(_fs_cm "$_fa_r" --status | grep 'receipt:')"
case "$_fa_rl" in
  ''|*"stale (table set moved"*) bad "so the receipt the run wrote is not stale at the next read" "[$_fa_rl]" ;;
  *)                             ok  "so the receipt the run wrote is not stale at the next read" ;;
esac

cp "$_fa_p/capabilities" "$TMP/fa-caps.1"
_fa_u="$(_fa_undecl)"
_fa_o="$(_fs_cm "$_fa_r")"
if [ -n "$_fa_u" ]; then
  bad "a second full run with nothing undeclared prints no adoption line and changes no capability" "the fixture still had [$_fa_u] undeclared"
elif ! cmp -s "$_fa_p/capabilities" "$TMP/fa-caps.1"; then
  bad "a second full run with nothing undeclared prints no adoption line and changes no capability" "capabilities now [$(cat "$_fa_p/capabilities")]"
else
  case "$_fa_o" in
    *"adopted before this run"*)     bad "a second full run with nothing undeclared prints no adoption line and changes no capability" "$_fa_o" ;;
    *"commissioning for adoptproj"*) ok  "a second full run with nothing undeclared prints no adoption line and changes no capability" ;;
    *)                               bad "a second full run with nothing undeclared prints no adoption line and changes no capability" "no report: $_fa_o" ;;
  esac
fi

[ -n "$_fh_sp" ] && { kill "$_fh_sp" 2>/dev/null; wait "$_fh_sp" 2>/dev/null; }
[ "$_fh_dlock_mine" -eq 1 ] && rmdir "$_fh_dlock" 2>/dev/null

printf '\ngenerated constitution\n'
CDIR="$FROOT/projects/stranger"
[ -s "$CDIR/CLAUDE.md" ] && ok "onboarding writes one" || bad "onboarding writes one"
has "it names the verification command" "$(cat "$CDIR/CLAUDE.md")" "felix gate"
has "and what was detected"             "$(cat "$CDIR/CLAUDE.md")" "billing"
# The invariants are the part that cannot be generated, and the file says why
# rather than pretending or leaving a bare TODO.
has "invariants say where they come from" "$(cat "$CDIR/CLAUDE.md")" "earned rather"
case "$(cat "$CDIR/CLAUDE.md")" in
  *"Replace this"*) bad "no placeholder telling someone to write it" "still a stub" ;;
  *) ok "no placeholder telling someone to write it" ;;
esac

printf '\nlessons are mounted, not offered\n'
cat > "$MEM/widget/lessons.md" <<'LES'
# widget lessons

## Checklist
1. run the gate
2. update the devlog

## Seeded principles
- **L-1 Migrations need a rollback path.** Long evidence about a migration that
  went wrong, with detail nobody needs mounted on every single turn.
- **L-2 Browser tests belong on critical flows.** More evidence, equally long,
  equally irrelevant until someone is actually touching the browser layer.
LES

out="$(cd "$REPO" && "$FELIX" lessons --for "changing a migration" 2>&1)"
has "matches the relevant lesson"   "$out" "L-1"
case "$out" in *"L-2"*) bad "and not the irrelevant one" "$out" ;; *) ok "and not the irrelevant one" ;; esac
has "the always-applicable part is shown" "$out" "run the gate"

# The evidence is why a lesson is believed; the claim is what needs mounting.
# Injecting the evidence every turn is how a helpful injection becomes ignored.
case "$out" in
  *"Long evidence about"*) bad "only the claim is mounted, not the evidence" "$out" ;;
  *) ok "only the claim is mounted, not the evidence" ;;
esac

out="$(cd "$REPO" && "$FELIX" lessons --for "unrelated quantum teleportation" 2>&1)"
has "an unrelated context matches nothing" "$out" "nothing matched"

printf '\nthe prompt hook\n'
HK="$FROOT/harness/hooks/user-prompt"
out="$(cd "$REPO" && printf '{"prompt":"fix the migration rollback"}' | "$HK" 2>&1)"
case "$out" in
  *'"hookSpecificOutput"'*) ok "emits the documented UserPromptSubmit shape" ;;
  *) bad "emits the documented UserPromptSubmit shape" "$out" ;;
esac
ctx="$(printf '%s' "$out" | python3 -c 'import json,sys; print(json.load(sys.stdin)["hookSpecificOutput"]["additionalContext"])' 2>&1)"
has "carries the matched lesson" "$ctx" "L-1"
# Bounded. A hook that floods the turn is a hook people learn to skim past.
lines="$(printf '%s\n' "$ctx" | wc -l | tr -d ' ')"
[ "$lines" -le 20 ] && ok "and stays small" \
                    || bad "and stays small" "$lines lines is too much for every turn"

out="$(cd "$PLAIN" && printf '{"prompt":"anything"}' | "$HK" 2>&1)"; rc=$?
is "silent in an ungoverned repo" "${#out}" "0"
is "and exits 0 there"            "$rc" "0"

mv "$MEM/widget/lessons.md" "$TMP/lessons.bak"
out="$(cd "$REPO" && printf '{"prompt":"fix the migration"}' | "$HK" 2>&1)"
is "silent when a project has no lessons yet" "${#out}" "0"
mv "$TMP/lessons.bak" "$MEM/widget/lessons.md"

printf '\npipefail safety\n'
# Regression. Every presence check used to be `producer | grep -q x`, which under
# `set -o pipefail` reports 141 because grep exits on match and the producer takes
# SIGPIPE. The check then says absent about something present, and it is
# timing-dependent, so small producers pass and a real repository fails.
big="$(seq 1 200000)"
# Deliberately not asserting that `producer | grep -q x` fails on the match
# these helpers look for, near the end. It fails only when the producer is still
# writing when grep exits, so with a late match the assertion is a race and
# flakes. The reason the helpers exist is recorded above instead.
if ( set -uo pipefail
     . "$FROOT/harness/lib/resolve.sh"
     felix_contains "$big" "199999" ); then
  ok "felix_contains survives a large haystack under pipefail"
else
  bad "felix_contains survives a large haystack under pipefail"
fi
if ( set -uo pipefail
     . "$FROOT/harness/lib/resolve.sh"
     felix_has_line "$big" "199999" ) ; then
  ok "felix_has_line matches whole lines under pipefail"
else
  bad "felix_has_line matches whole lines under pipefail"
fi
if ( set -uo pipefail
     . "$FROOT/harness/lib/resolve.sh"
     felix_has_line "alpha
beta" "alph" ); then
  bad "felix_has_line rejects partial lines" "matched a prefix"
else
  ok "felix_has_line rejects partial lines"
fi
# Twenty-one of the suite's own checks had the shape the helpers replaced,
# `printf '%s\n' "$out" | grep -Fq x`, and one failed on main at a1bf2c7d, its
# log reading `printf: write error: Broken pipe`, once #310 lengthened the
# output it read. Each printf that fed such a chain now hands the chain's first
# stage a here-string, which bash has written in full before that stage starts,
# so grep's exit breaks no printf. Seven chains still pipe that first stage's
# output into a later grep -q, and that writer is safe for another reason, at
# the sizes these reports have: it prints a few filtered lines, which stdio
# holds until the stage has read all its input and then writes in one piece.
# A match on the first line of a megabyte takes the race out of the pipe form:
# grep exits after its first read, so the writer can have handed over only
# that read and one pipe's capacity, a small part of 1.3 MB. The first check
# pins that failure, which is what gives the second its meaning: on a haystack
# small enough for the pipe form to pass, the here-string passing would prove
# nothing. Neither reads the suite, so the third does: it goes red on any
# check here that pipes printf or echo of a variable into a chain ending in
# grep -q, which is how the sweep stays swept. It passes over comments, and
# over the first check's own pipe, which is there to break. It reads a line at
# a time, so a chain continued onto a second line is not seen; none is today.
if ( set -o pipefail; printf '%s\n' "$big" | grep -Fxq 1 ) 2>/dev/null; then
  bad "under pipefail, printf piped into grep -q fails when grep matches the first line of a megabyte" \
      "the pipe form passed, so this haystack cannot show that the here-string form is immune"
else
  ok  "under pipefail, printf piped into grep -q fails when grep matches the first line of a megabyte"
fi
if ( set -o pipefail; grep -Fxq 1 <<<"$big" ); then
  ok  "and a here-string into grep -q passes on the same megabyte"
else
  bad "and a here-string into grep -q passes on the same megabyte"
fi
_pfre="(printf '%s(\\\\n)?'|echo) \"[\$][^\"]*\" [|] ([^|]*[|] )*grep [^|]*-[a-zA-Z]*q"
_pfsites="$(_suite_src | grep -nE "$_pfre" | grep -vE -e '^[0-9]+:[[:space:]]*#' -e '"[$]big" [|] grep -Fxq 1 [)]')"
is "no check in this suite pipes printf or echo of a variable into a chain ending in grep -q" "$_pfsites" ""

# >>> hook-payload-cwd
printf '\nhooks stand where the session stands\n'
# Claude Desktop starts every session with --project-config-root naming the
# main checkout, and Claude Code then spawns every command hook with its cwd
# there, whatever directory the session works in. The session's own directory,
# a worktree as often as not, reaches a hook only as the payload's top-level
# "cwd" (measured 2026-10-02 against the real binary and a mock API). So every
# hook that resolved from $PWD judged the main checkout: a Stop hook told a
# worktree session that the gate had passed "on this exact tree" about the
# main checkout's receipt, ninety seconds after the worktree's own green one.
#
# Written from the contract alone, before any implementation existed. The
# shape is Desktop's: the hook runs in a launch directory, either PCA, a
# governed main checkout, or PCU, a checkout nothing governs, and the
# payload's cwd names PCB, a `git worktree add` of PCA on a commit of its own.
# A home and a memory of its own, set on every call, so nothing here is seen
# by a later section.
#
# The controls, where the payload's cwd equals the launch directory, is absent
# or unusable, or names a directory nothing governs, pass on the engine before
# this change by design: they are the behaviour that must not move.
PC="$TMP/payload-cwd"; mkdir -p "$PC"; PC="$(cd "$PC" && pwd -P)"
PH="$PC/home"; PM="$PC/memory"; PT="$PC/transcripts"; PX="$PC/fx"
mkdir -p "$PH/projects/pcwd" "$PH/projects/pcwdremote" "$PM/pcwd" "$PT" "$PX"
cat > "$PH/projects/pcwd/project.json" <<'EOF'
{
  "name": "pcwd",
  "remote_match": "example.invalid/pcwd-marker-only",
  "gate": "sh -c 'test -f OK.txt && echo pcwd-gate-ran'"
}
EOF
printf '# pcwd\n' > "$PH/projects/pcwd/CLAUDE.md"
# The widget's probe row. Without one every receipt carries no epoch, no green
# receipt is ever current, and every stop below would take the gate's hold.
printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' > "$PH/projects/pcwd/probes.tsv"
printf 'Bash\t(^|[;&| ])npm publish\tpcwd refuses a publish\n' > "$PH/projects/pcwd/deny.tsv"
cat > "$PH/projects/pcwdremote/project.json" <<'EOF'
{
  "name": "pcwdremote",
  "remote_match": "example.invalid/pcwd-remote"
}
EOF
printf -- '- **L1 The quokka ledger in pcwd is reconciled by hand.** Evidence would follow here.\n' \
  > "$PM/pcwd/lessons.md"

_pcwd_git() { git -c user.name=t -c user.email=t@t "$@"; }
PCA="$PX/main"; PCB="$PX/wt"; PCU="$PX/plain"; PCN="$PX/nogit"; PCK="$PX/broken"
PCR="$PX/remote"; PCQ="$PX/sealed"; PCBS="$PX/back\\slash"; PCW2="$PX/wt-broken"
mkdir -p "$PCA" "$PCU" "$PCN" "$PCK" "$PCR" "$PCQ" "$PCBS"
( cd "$PCA" && git init -q -b main && printf 'ok\n' > OK.txt && printf 'pcwd\n' > .felix \
  && git add -A && _pcwd_git commit -qm init && git worktree add -q -b side "$PCB" ) >/dev/null 2>&1
( cd "$PCB" && mkdir -p sub && printf 'kept\n' > sub/keep.txt \
  && printf '# the worktree handoff\n' > HANDOFF.md \
  && git add -A && _pcwd_git commit -qm side ) >/dev/null 2>&1
# A second worktree of the main checkout, whose marker somebody broke.
git -C "$PCA" worktree add -q -b broken-side "$PCW2" >/dev/null 2>&1
printf 'pcwd-no-such-project\n' > "$PCW2/.felix"
( cd "$PCU" && git init -q -b main && printf 'u\n' > u.txt && git add -A && _pcwd_git commit -qm init ) >/dev/null 2>&1
( cd "$PCK" && git init -q -b main && printf 'pcwd-no-such-project\n' > .felix \
  && git add -A && _pcwd_git commit -qm init ) >/dev/null 2>&1
( cd "$PCR" && git init -q -b main && printf 'r\n' > r.txt && git add -A && _pcwd_git commit -qm init \
  && git remote add origin https://example.invalid/pcwd-remote.git ) >/dev/null 2>&1
( cd "$PCQ"  && git init -q -b main && printf 'pcwd\n' > .felix ) >/dev/null 2>&1
( cd "$PCBS" && git init -q -b main && printf 'pcwd\n' > .felix ) >/dev/null 2>&1
# The main checkout's own handoff, untracked so the worktree does not carry it,
# and a link a relative cwd would follow from there into the worktree.
printf '# the main checkout handoff\n' > "$PCA/HANDOFF.md"
ln -s "$PCB" "$PCA/to-b"
printf 'a-edit\n' >> "$PCA/OK.txt"; printf 'b-edit\n' >> "$PCB/OK.txt"
PCHA="$(git -C "$PCA" rev-parse HEAD 2>/dev/null)"; PCHB="$(git -C "$PCB" rev-parse HEAD 2>/dev/null)"

# The platform's envelope, cwd third; a cwd of `-` leaves the key out.
_pcwd_pay() {   # event sid cwd [more fields]
  local c=""; [ "$3" = - ] || c="\"cwd\":\"$3\","
  printf '{"session_id":"%s","transcript_path":"%s/%s.jsonl",%s"permission_mode":"default","hook_event_name":"%s"%s}' \
    "$2" "$PT" "$2" "$c" "$1" "${4:+,$4}"
}
# A hook run where the platform would start it, with the fixture's own home.
_pcwd_hook() {   # launch dir, hook, payload -> stdout and stderr together
  ( cd "$1" && FELIX_HOME="$PH" FELIX_MEMORY="$PM" "$FROOT/harness/hooks/$2" <<<"$3" 2>&1 )
}
_pcwd_pre() {    # launch dir, payload -> exit status; stderr in $PC/pre.err
  ( cd "$1" && FELIX_HOME="$PH" FELIX_MEMORY="$PM" "$FROOT/harness/hooks/pre-tool" <<<"$2" >/dev/null 2>"$PC/pre.err" )
  printf '%s' "$?"
}
_pcwd_tid() { ( . "$FROOT/harness/lib/verify.sh"; felix_tree_id "$1" "$PH" ) 2>/dev/null; }
_pcwd_gate() { ( cd "$1" && FELIX_HOME="$PH" FELIX_MEMORY="$PM" "$FELIX" gate >/dev/null 2>&1 ); }
_pcwd_current() { ( . "$FROOT/harness/lib/verify.sh"; felix_verify_current "$1" "$PH" "$PH/projects/pcwd" ) 2>/dev/null | cut -f1; }
_pcwd_res() { local p; p="$( . "$FROOT/harness/lib/resolve.sh"; felix_resolve_project "$1" "$PH" 2>/dev/null )"; printf '%s' "${p##*/}"; }
# What a stop decided, and the one row it wrote: which tree it judged, and why.
_pcwd_vlog="$PM/pcwd/verification.log"
_pcwd_rows() { if [ -f "$_pcwd_vlog" ]; then awk 'END { print NR }' "$_pcwd_vlog"; else printf '0'; fi; }
_pcwd_stop() {   # launch dir, payload -> "block|silent +rows verdict tree reason"
  local n0 o
  n0="$(_pcwd_rows)"; o="$(_pcwd_hook "$1" stop "$2")"
  case "$o" in
    *'"decision"'*'"block"'*) printf 'block' ;;
    '')                       printf 'silent' ;;
    *)                        printf 'other[%s]' "$(printf '%s' "$o" | head -c 200)" ;;
  esac
  printf ' +%s %s' "$(( $(_pcwd_rows) - n0 ))" "$(tail -1 "$_pcwd_vlog" 2>/dev/null | cut -f2-4 | tr '\t' ' ')"
}
_pcwd_sp() { _pcwd_pay Stop "$1" "$2" '"stop_hook_active":false'; }

if [ -f "$PCB/.git" ] && [ -f "$PCW2/.git" ] && [ -n "$PCHB" ] && [ "$PCHA" != "$PCHB" ] \
   && [ "$(cd "$(git -C "$PCB" rev-parse --git-common-dir 2>/dev/null)" 2>/dev/null && pwd -P)" = "$PCA/.git" ]; then
  ok  "the payload-cwd fixture has a main checkout and a worktree of it on a commit of its own"
else
  bad "the payload-cwd fixture has a main checkout and a worktree of it on a commit of its own" \
      "worktree [$PCB] heads [$PCHA] [$PCHB]"
fi
is "and in its own home the checkouts resolve as the cases below assume" \
   "$(_pcwd_res "$PCA") $(_pcwd_res "$PCB") $(_pcwd_res "$PCR") $(_pcwd_res "$PCBS") [$(_pcwd_res "$PCU")] [$(_pcwd_res "$PCK")] [$(_pcwd_res "$PCW2")] [$(_pcwd_res "$PCN")]" \
   "pcwd pcwd pcwdremote pcwd [] [] [] []"
chmod 000 "$PCQ/.felix"

# ---- felix_hook_dir, rule by rule (C1). Each answer is the directory printed,
# a dot, the status, a bar, and whatever reached stderr, so one case checks
# that it prints one directory with no newline, returns 0 and says nothing.
# The suite's FELIX_HOME still names the widget home, so the remote-bound case
# can only pass where the function resolves in the home it is handed.
_pcwd_hd() {   # stand-in dir, payload
  ( cd "$1" || exit 0
    . "$FROOT/harness/lib/resolve.sh"
    o="$(felix_hook_dir "$2" "$PH" 2>"$PC/hd.err"; printf '.%s' "$?")"
    printf '%s|%s' "$o" "$(cat "$PC/hd.err" 2>/dev/null)" )
}
_pcwd_hdp() { _pcwd_pay PreToolUse hd "$1" '"tool_name":"Bash","tool_input":{"command":"true"},"tool_use_id":"toolu_hd"'; }
is "felix_hook_dir prints the payload's worktree when its marker names a project" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "$PCB")")" "$PCB.0|"
is "felix_hook_dir prints a subdirectory of that worktree as given, not its root" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "$PCB/sub")")" "$PCB/sub.0|"
is "felix_hook_dir prints a checkout whose marker is broken, since Felix has that to say about it" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "$PCK")")" "$PCK.0|"
# Launched where nothing governs: Amendment 1 keeps a governed launch directory
# when the candidate's project is another one, and round two asserts that.
is "felix_hook_dir prints a checkout bound by its remote alone, resolved in the home it is handed, when the launch directory governs nothing" \
   "$(_pcwd_hd "$PCU" "$(_pcwd_hdp "$PCR")")" "$PCR.0|"
is "felix_hook_dir prints a checkout whose marker cannot be read, and writes nothing to stderr about it" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "$PCQ")")" "$PCQ.0|"
is "felix_hook_dir keeps the launch directory for a git checkout nothing governs" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "$PCU")")" "$PCA.0|"
is "felix_hook_dir keeps the launch directory for a plain directory nothing governs" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "$PCN")")" "$PCA.0|"
is "felix_hook_dir keeps the launch directory when the payload's cwd is empty" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "")")" "$PCA.0|"
is "felix_hook_dir keeps the launch directory when the payload carries no cwd" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp -)")" "$PCA.0|"
is "felix_hook_dir keeps the launch directory for a relative cwd, though from there it names a governed worktree" \
   "$(_pcwd_hd "$PX" "$(_pcwd_hdp wt)")" "$PX.0|"
is "felix_hook_dir keeps the launch directory for a cwd spelt with escaped slashes, which it does not decode" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "$(printf '%s' "$PCB" | sed 's|/|\\/|g')")")" "$PCA.0|"
is "felix_hook_dir keeps the launch directory for a cwd holding a backslash, though that directory exists and is governed" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "$PCBS")")" "$PCA.0|"
is "felix_hook_dir keeps the launch directory for an escaped backslash that only decoding would make a governed directory" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "$PX/back\\\\slash")")" "$PCA.0|"
is "felix_hook_dir keeps the launch directory for a cwd that does not exist" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "$PCB/no-such-directory")")" "$PCA.0|"
is "felix_hook_dir keeps the launch directory for a cwd naming a file inside a governed worktree" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "$PCB/OK.txt")")" "$PCA.0|"
# Payloads holding a brace and a comma are built in an assignment first: bash
# 3.2 brace-expands such a word inside "$(...)" in a command's arguments, and
# the assertion then compares two halves of a payload with each other.
_pcwd_p="{\"session_id\":\"hd\",\"transcript_path\":\"$PT/hd.jsonl\",\"cwd\" :  \"$PCB\",\"hook_event_name\":\"Stop\"}"
is "felix_hook_dir reads the top-level cwd with whitespace around its colon" "$(_pcwd_hd "$PCU" "$_pcwd_p")" "$PCB.0|"
_pcwd_p="$(_pcwd_pay PreToolUse hd "$PCU" "\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"true\",\"cwd\":\"$PCB\"}")"
is "felix_hook_dir reads the leftmost cwd: a governed directory named again inside tool_input does not move it" \
   "$(_pcwd_hd "$PCA" "$_pcwd_p")" "$PCA.0|"
_pcwd_p="$(_pcwd_pay PreToolUse hd "$PCB" "\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"true\",\"cwd\":\"$PCU\"}")"
is "felix_hook_dir reads the leftmost cwd: an ungoverned directory named again inside tool_input does not undo it" \
   "$(_pcwd_hd "$PCA" "$_pcwd_p")" "$PCB.0|"
_pcwd_p="$(_pcwd_pay Stop hd - "\"stop_hook_active\":false,\"last_assistant_message\":\"cd there: \\\"cwd\\\":\\\"$PCB\\\"\"")"
is "felix_hook_dir does not read a cwd spelt inside a message, where the key's quotes are escaped" \
   "$(_pcwd_hd "$PCA" "$_pcwd_p")" "$PCA.0|"
# The CLI case, where the two directories are one: it must cost nothing, so
# nothing that resolves is called. Spies stand in for each.
_pco="$( cd "$PCA" && . "$FROOT/harness/lib/resolve.sh"; : > "$PC/spy"
         felix_repo_root()       { printf 'felix_repo_root ' >> "$PC/spy"; printf '%s' "${1:-$PWD}"; }
         felix_resolve_project() { printf 'felix_resolve_project ' >> "$PC/spy"; return 1; }
         felix_binding_broken()  { printf 'felix_binding_broken ' >> "$PC/spy"; }
         git()                   { printf 'git ' >> "$PC/spy"; command git "$@"; }
         o="$(felix_hook_dir "$(_pcwd_hdp "$PCA")" "$PH" 2>"$PC/hd.err"; printf '.%s' "$?")"
         printf '%s|%s|%s' "$o" "$(cat "$PC/hd.err")" "$(cat "$PC/spy")" )"
is "felix_hook_dir answers a cwd equal to the launch directory without resolving anything" "$_pco" "$PCA.0||"

# About a megabyte: a last message full of escaped "cwd" keys, each naming a
# checkout Felix has something to say about, behind the real key in the first
# payload and with no real one in the second. Child CPU, under
# a watchdog, so neither the load on this machine nor a scan that never ends
# can decide it; the work is a few milliseconds and the bound is three seconds.
_pcwd_killtree() { local c; for c in $(pgrep -P "$1" 2>/dev/null); do _pcwd_killtree "$c"; done; kill "$1" 2>/dev/null; }
_pcwd_bounded() {   # seconds, outfile, command... -> done | killed
  local lim="$1" of="$2" i=0 pid; shift 2
  ( "$@" ) > "$of" 2>&1 &
  pid=$!
  while kill -0 "$pid" 2>/dev/null && [ "$i" -lt $((lim * 10)) ]; do sleep 0.1; i=$((i + 1)); done
  if kill -0 "$pid" 2>/dev/null; then _pcwd_killtree "$pid"; wait "$pid" 2>/dev/null; printf 'killed'; return; fi
  wait "$pid" 2>/dev/null; printf 'done'
}
_pcwd_big_one() {
  cd "$PCA" && . "$FROOT/harness/lib/resolve.sh"; raw="$(cat "$1")"
  o="$(felix_hook_dir "$raw" "$PH" 2>/dev/null)"; printf '%s' "$o" > "$1.out"; times > "$1.cpu"
}
_pcwd_big() {   # payload file -> "<printed> <cpu ms>", or killed
  [ "$(_pcwd_bounded 60 "$1.log" _pcwd_big_one "$1")" = done ] || { printf 'killed'; return; }
  printf '%s %s' "$(cat "$1.out" 2>/dev/null)" \
    "$(awk '{ for (i = 1; i <= NF; i++) { split($i, t, "m"); sub(/s$/, "", t[2]); ms += (t[1] * 60 + t[2]) * 1000 } }
            END { printf "%d", ms }' "$1.cpu" 2>/dev/null)"
}
_pcwd_msg() { awk -v p="$PCK" 'BEGIN { u = "x \\\"cwd\\\":\\\"" p "\\\" y "; for (n = 0; n < 1100000; n += length(u)) printf "%s", u }'; }
_pcwd_bigp() { _pcwd_pay Stop big "$1" "\"stop_hook_active\":false,\"last_assistant_message\":\"$(_pcwd_msg)\""; }
_pcwd_bigp "$PCB" > "$PC/big-cwd.json"; _pcwd_bigp - > "$PC/big-none.json"
_pcwd_bigsz="$(wc -c < "$PC/big-cwd.json" | tr -d ' ')"
[ "$_pcwd_bigsz" -gt 1000000 ] && ok  "the payload-cwd fixture's megabyte payloads hold over a million bytes" \
                               || bad "the payload-cwd fixture's megabyte payloads hold over a million bytes" "$_pcwd_bigsz bytes"
_pco="$(_pcwd_big "$PC/big-cwd.json")"
if [ "${_pco% *}" = "$PCB" ] && [ "${_pco##* }" -lt 3000 ] 2>/dev/null; then
  ok  "felix_hook_dir finds the top-level cwd ahead of a megabyte of message in under three CPU seconds"
else
  bad "felix_hook_dir finds the top-level cwd ahead of a megabyte of message in under three CPU seconds" \
      "got [$_pco], want [$PCB] under 3000 ms"
fi
_pco="$(_pcwd_big "$PC/big-none.json")"
if [ "${_pco% *}" = "$PCA" ] && [ "${_pco##* }" -lt 3000 ] 2>/dev/null; then
  ok  "felix_hook_dir answers a megabyte payload with no cwd by the launch directory in under three CPU seconds"
else
  bad "felix_hook_dir answers a megabyte payload with no cwd by the launch directory in under three CPU seconds" \
      "got [$_pco], want [$PCA] under 3000 ms"
fi

# ---- felix_hook_enter (C2'): the calling shell moves, and keeps no record of
# whence. Amendment 1 dropped FELIX_HOOK_LAUNCH: nothing reads it once pre-tool
# resolves from where it was started, and state nobody reads is a claim nobody
# checks. So the variable must come back unset, not merely empty.
_pcwd_he() {   # payload -> "PWD|unset, or set to FELIX_HOOK_LAUNCH's value|status|output"
  ( cd "$PCA" && . "$FROOT/harness/lib/resolve.sh"; unset FELIX_HOOK_LAUNCH
    felix_hook_enter "$1" "$PH" > "$PC/he.out" 2>&1; rc=$?
    printf '%s|%s|%s|%s' "$PWD" "${FELIX_HOOK_LAUNCH+set to }${FELIX_HOOK_LAUNCH-unset}" "$rc" "$(cat "$PC/he.out")" )
}
is "felix_hook_enter moves the calling shell into the payload's worktree, says nothing, and leaves FELIX_HOOK_LAUNCH unset" \
   "$(_pcwd_he "$(_pcwd_hdp "$PCB")")" "$PCB|unset|0|"
is "felix_hook_enter leaves the calling shell where it was for a directory nothing governs, says nothing, and sets no FELIX_HOOK_LAUNCH" \
   "$(_pcwd_he "$(_pcwd_hdp "$PCU")")" "$PCA|unset|0|"

# ---- Stop, first with the main checkout green and the worktree unverified.
_pcwd_gate "$PCA"
PCTA1="$(_pcwd_tid "$PCA")"; PCTB1="$(_pcwd_tid "$PCB")"
is "the payload-cwd fixture's main checkout carries a current green receipt, and its worktree none" \
   "$(_pcwd_current "$PCA") $(_pcwd_current "$PCB")" "current none"
is "Stop with the payload's cwd at the launch checkout judges that checkout as before, and it is green" \
   "$(_pcwd_stop "$PCA" "$(_pcwd_sp pc-s1 "$PCA")")" "silent +1 allowed $PCTA1 green"
is "Stop judges the worktree the payload names, so its unverified work blocks though the main checkout is green" \
   "$(_pcwd_stop "$PCA" "$(_pcwd_sp pc-s2 "$PCB")")" "block +1 blocked $PCTB1 never verified"
_pco="$(_pcwd_hook "$PCA" stop "$(_pcwd_sp pc-s3 "$PCW2")")"
case "$_pco" in
  *'"decision"'*'"block"'*) ok  "Stop refuses a broken marker in the payload's worktree though the launch checkout is green" ;;
  *)                        bad "Stop refuses a broken marker in the payload's worktree though the launch checkout is green" "got [$_pco]" ;;
esac
has "and the refusal names that worktree's marker" "$_pco" "The .felix marker in $PCW2 names"
# Entered before the flag is read: a flagged stop in a chain Felix did not
# start is judged, and the project it is judged under is the worktree's.
is "Stop launched in a directory nothing governs judges a flagged stop by the worktree the payload names" \
   "$(_pcwd_stop "$PCU" "$(_pcwd_pay Stop pc-s6 "$PCB" '"stop_hook_active":true')")" "block +1 blocked $PCTB1 never verified"

# SubagentStop asks the same of the tree, and says so rather than holding.
has "SubagentStop judges the payload's worktree, so its unverified work is declared though the launch checkout is green" \
    "$(_pcwd_hook "$PCA" subagent-stop "$(_pcwd_pay SubagentStop pc-ss1 "$PCB" '"stop_hook_active":false,"agent_id":"a1"')")" \
    "A subagent report is about to be integrated"
has "SubagentStop launched in a directory nothing governs resolves the governed worktree the payload names" \
    "$(_pcwd_hook "$PCU" subagent-stop "$(_pcwd_pay SubagentStop pc-ss2 "$PCB" '"stop_hook_active":false,"agent_id":"a2"')")" \
    "A subagent report is about to be integrated"

# ---- Then the other way round: the worktree green, the main checkout not.
_pcwd_gate "$PCB"
printf 'a-again\n' >> "$PCA/OK.txt"
PCTA2="$(_pcwd_tid "$PCA")"; PCTB2="$(_pcwd_tid "$PCB")"
is "the payload-cwd fixture's worktree now carries a current green receipt, and its main checkout a stale one" \
   "$(_pcwd_current "$PCB") $(_pcwd_current "$PCA")" "current stale"
is "Stop allows when the worktree the payload names is green, though the launch checkout holds unverified work" \
   "$(_pcwd_stop "$PCA" "$(_pcwd_sp pc-s4 "$PCB")")" "silent +1 allowed $PCTB2 green"
is "Stop judges the worktree when the payload's cwd is a subdirectory of it" \
   "$(_pcwd_stop "$PCA" "$(_pcwd_sp pc-s5 "$PCB/sub")")" "silent +1 allowed $PCTB2 green"
_pcwd_held="block +1 blocked $PCTA2 stale receipt"
is "Stop with the payload's cwd at the launch checkout judges it as before, and holds its stale receipt" \
   "$(_pcwd_stop "$PCA" "$(_pcwd_sp pc-c1 "$PCA")")" "$_pcwd_held"
is "Stop with no cwd in the payload judges the launch checkout as before" \
   "$(_pcwd_stop "$PCA" "$(_pcwd_sp pc-c2 -)")" "$_pcwd_held"
is "Stop with an empty cwd judges the launch checkout as before" \
   "$(_pcwd_stop "$PCA" "$(_pcwd_sp pc-c3 "")")" "$_pcwd_held"
is "Stop with a relative cwd judges the launch checkout, though from there that path leads to the green worktree" \
   "$(_pcwd_stop "$PCA" "$(_pcwd_sp pc-c4 to-b)")" "$_pcwd_held"
is "Stop with a cwd spelt in JSON escapes judges the launch checkout, though decoding it leads to the green worktree" \
   "$(_pcwd_stop "$PCA" "$(_pcwd_sp pc-c5 "$(printf '%s' "$PCB" | sed 's|/|\\/|g')")")" "$_pcwd_held"
is "Stop with a cwd that does not exist judges the launch checkout as before" \
   "$(_pcwd_stop "$PCA" "$(_pcwd_sp pc-c6 "$PCB/no-such-directory")")" "$_pcwd_held"
is "Stop with a cwd in a git checkout nothing governs judges the launch checkout as before" \
   "$(_pcwd_stop "$PCA" "$(_pcwd_sp pc-c7 "$PCU")")" "$_pcwd_held"
is "Stop with a cwd in a plain directory nothing governs judges the launch checkout as before" \
   "$(_pcwd_stop "$PCA" "$(_pcwd_sp pc-c8 "$PCN")")" "$_pcwd_held"

# ---- PreToolUse. A deny row with no scope, so where the command acts does
# not matter and only which project's rows apply does.
_pcwd_ptp() { _pcwd_pay PreToolUse "$1" "$2" "\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"npm publish\"${3:-}},\"tool_use_id\":\"toolu_pcwd\""; }
is "PreToolUse launched in a directory nothing governs refuses by the rows of the governed worktree the payload names" \
   "$(_pcwd_pre "$PCU" "$(_pcwd_ptp pc-p1 "$PCB")")" "2"
has "and the refusal names that project's deny table" "$(cat "$PC/pre.err" 2>/dev/null)" \
    "This is a rule in $PH/projects/pcwd/deny.tsv"
is "PreToolUse reads the top-level cwd, so a later cwd inside tool_input does not lift the worktree's refusal" \
   "$(_pcwd_pre "$PCU" "$(_pcwd_ptp pc-p2 "$PCB" ",\"cwd\":\"$PCU\"")")" "2"
is "PreToolUse is not moved by a governed directory named only inside tool_input" \
   "$(_pcwd_pre "$PCU" "$(_pcwd_ptp pc-p3 "$PCU" ",\"cwd\":\"$PCB\"")")" "0"
is "PreToolUse still refuses by the launch checkout's rows when the payload's worktree has a broken marker" \
   "$(_pcwd_pre "$PCA" "$(_pcwd_ptp pc-p4 "$PCW2")")" "2"
_pcwd_pre "$PCA" "$(_pcwd_ptp pc-p5 -)" >/dev/null; _pcwd_err0="$(cat "$PC/pre.err" 2>/dev/null)"
is "PreToolUse refuses by the launch checkout's rows when the payload's cwd is a directory nothing governs, as before" \
   "$(_pcwd_pre "$PCA" "$(_pcwd_ptp pc-p6 "$PCU")")" "2"
is "and says exactly what it says when the payload carries no cwd" "$(cat "$PC/pre.err" 2>/dev/null)" "$_pcwd_err0"

