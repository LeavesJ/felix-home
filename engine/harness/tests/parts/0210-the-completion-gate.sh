# ---- SessionStart: the banner and the record are the worktree's.
_pcwd_handoffs() {   # the HANDOFF.md paths a banner names, in order, once each
  printf '%s' "$1" | awk '{ gsub(/\\n/, " ")
    for (i = 1; i <= NF; i++) if ($i ~ /HANDOFF\.md$/ && !s[$i]++) { printf "%s%s", sep, $i; sep = " " } }'
}
_pco="$(_pcwd_hook "$PCA" session-start "$(_pcwd_pay SessionStart pc-st1 "$PCB" '"source":"startup"')")"
is "SessionStart names the handoff of the worktree the payload names, and not the launch checkout's" \
   "$(_pcwd_handoffs "$_pco")" "$PCB/HANDOFF.md"
is "and records the session at the worktree's HEAD" \
   "$(tail -1 "$PM/pcwd/lifecycle.log" 2>/dev/null | cut -f3,6 | tr '\t' ' ')" "pc-st1 $PCHB"
has "SessionStart launched in a directory nothing governs binds the governed worktree the payload names" \
    "$(_pcwd_hook "$PCU" session-start "$(_pcwd_pay SessionStart pc-st2 "$PCB" '"source":"startup"')")" \
    "Project: pcwd"
is "SessionStart with a cwd that does not exist reads the launch checkout as before" \
   "$(_pcwd_handoffs "$(_pcwd_hook "$PCA" session-start "$(_pcwd_pay SessionStart pc-st3 "$PX/no-such" '"source":"startup"')")")" \
   "$PCA/HANDOFF.md"

# ---- UserPromptSubmit: it used to resolve before it had read the payload.
has "UserPromptSubmit launched in a directory nothing governs mounts the lessons of the governed worktree the payload names" \
    "$(_pcwd_hook "$PCU" user-prompt "$(_pcwd_pay UserPromptSubmit pc-up1 "$PCB" '"prompt":"reconcile the quokka ledger"')")" \
    "The rest are in $PM/pcwd/lessons.md."
is "and marks the session at the worktree's HEAD" "$(cat "$PH/state/session/pc-up1" 2>/dev/null)" "$PCHB"
is "UserPromptSubmit launched in a directory nothing governs says nothing when the payload's cwd is ungoverned too, as before" \
   "$(_pcwd_hook "$PCU" user-prompt "$(_pcwd_pay UserPromptSubmit pc-up2 "$PCN" '"prompt":"reconcile the quokka ledger"')")" ""

# ---- SubagentStart: it read no payload at all.
has "SubagentStart launched in a directory nothing governs names the governed worktree's project to the subagent" \
    "$(_pcwd_hook "$PCU" subagent-start "$(_pcwd_pay SubagentStart pc-sa1 "$PCB" '"agent_id":"a1","agent_type":"general-purpose"')")" \
    "Constitution: $PH/projects/pcwd/CLAUDE.md"
is "SubagentStart says nothing when the payload's cwd is the ungoverned directory it was launched in, as before" \
   "$(_pcwd_hook "$PCU" subagent-start "$(_pcwd_pay SubagentStart pc-sa2 "$PCU" '"agent_id":"a2","agent_type":"general-purpose"')")" ""
_pcwd_closed() { cd "$PCA" && : | FELIX_HOME="$PH" FELIX_MEMORY="$PM" "$FROOT/harness/hooks/subagent-start"; }
_pco="$(_pcwd_bounded 60 "$PC/closed.out" _pcwd_closed)"
case "$(cat "$PC/closed.out" 2>/dev/null)" in
  *"Constitution: $PH/projects/pcwd/CLAUDE.md"*) _pco="$_pco binds" ;;
  *)                                             _pco="$_pco silent" ;;
esac
is "SubagentStart given a closed pipe with nothing in it finishes, and binds the launch checkout" "$_pco" "done binds"

# ---- SessionEnd folds what the session reached for into the worktree's ledger.
mkdir -p "$PH/state/ledger"; printf 'skill\tpcwd-probe:used\n' > "$PH/state/ledger/pc-se1.tsv"
_pcwd_hook "$PCU" session-end "$(_pcwd_pay SessionEnd pc-se1 "$PCB" '"reason":"other"')" >/dev/null
is "SessionEnd launched in a directory nothing governs folds the session into the governed worktree's ledger" \
   "$(cut -f3,4 "$PM/pcwd/ledger.d/pc-se1.tsv" 2>/dev/null | tr '\t' ' ')" "skill pcwd-probe:used"

# round two: Amendment 1
# Written from Amendment 1 alone, after three reviews of round one. A hook now
# leaves the directory the platform started it in only for another checkout of
# that directory's own project, for a governed directory when that directory
# governs nothing, or for a broken marker. It reads only the first 4096 bytes
# and only the first "cwd" key, and only when that key's value is a string.
# The launch directory however it is spelt resolves nothing. pre-tool resolves
# from where it was started before anything else.
#
# Fixtures on top of the block's: a project that declares no gate, bound by the
# marker of a checkout nested in the main checkout. The main checkout excludes
# it, as it would a scratch clone, so its own tree does not move. A broken-marker
# checkout's subdirectory, and a link to the main checkout.
mkdir -p "$PH/projects/pcwdnogate"
cat > "$PH/projects/pcwdnogate/project.json" <<'EOF'
{
  "name": "pcwdnogate",
  "remote_match": "example.invalid/pcwd-nogate"
}
EOF
PCNEST="$PCA/nest"; mkdir -p "$PCNEST" "$PCA/.git/info" "$PCK/sub"
( cd "$PCNEST" && git init -q -b main && printf 'pcwdnogate\n' > .felix && printf 'n\n' > n.txt \
  && git add -A && _pcwd_git commit -qm init ) >/dev/null 2>&1
printf 'nest/\n' >> "$PCA/.git/info/exclude"
ln -s "$PCA" "$PC/via-link"
is "the round-two fixture binds the nested checkout and the remote-bound one to projects of their own, and the main checkout's tree has not moved" \
   "$(_pcwd_res "$PCNEST") $(_pcwd_res "$PCR") $(_pcwd_tid "$PCA")" "pcwdnogate pcwdremote $PCTA2"

# ---- felix_hook_dir, rule 1': the first "cwd" key, and only a string value.
_pcwd_p="{\"session_id\":\"hd\",\"transcript_path\":\"$PT/hd.jsonl\",\"cwd\":null,\"permission_mode\":\"default\",\"hook_event_name\":\"PreToolUse\",\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"true\",\"cwd\":\"$PCB\"},\"tool_use_id\":\"toolu_hd\"}"
is "felix_hook_dir keeps the launch directory when the first cwd is null, though a governed worktree is named in tool_input after it" \
   "$(_pcwd_hd "$PCA" "$_pcwd_p")" "$PCA.0|"
_pcwd_p="{\"session_id\":\"hd\",\"transcript_path\":\"$PT/hd.jsonl\",\"cwd\":42,\"permission_mode\":\"default\",\"hook_event_name\":\"PreToolUse\",\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"true\",\"cwd\":\"$PCB\"},\"tool_use_id\":\"toolu_hd\"}"
is "felix_hook_dir keeps a launch directory nothing governs when the first cwd is a number, though a governed worktree is named in tool_input after it" \
   "$(_pcwd_hd "$PCU" "$_pcwd_p")" "$PCU.0|"

# Only the first 4096 bytes are read. The envelope's transcript path is padded
# so that the top-level cwd's closing quote is byte 4096 in one payload, and its
# key starts at byte 4097 in the other.
_pcwd_at() {   # byte the "cwd" key starts at, cwd -> payload
  local h="{\"session_id\":\"hd\",\"transcript_path\":\"$PT/" t='.jsonl",' n
  n=$(( $1 - 1 - ${#h} - ${#t} ))
  printf '%s%s%s"cwd":"%s"%s' "$h" "$(awk -v n="$n" 'BEGIN { while (n-- > 0) printf "x" }')" "$t" "$2" \
    ',"permission_mode":"default","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"true"},"tool_use_id":"toolu_hd"}'
}
_pcwd_in="$(_pcwd_at $(( 4096 - 7 - ${#PCB} )) "$PCB")"; _pcwd_out="$(_pcwd_at 4097 "$PCB")"
is "the payload-cwd fixture's padded payloads end the cwd at byte 4096 in one and start its key at byte 4097 in the other" \
   "$(head -c 4096 <<<"$_pcwd_in" | tail -c $(( ${#PCB} + 8 ))) $(head -c 4096 <<<"$_pcwd_out" | LC_ALL=C command grep -c '"cwd"') $(head -c 4101 <<<"$_pcwd_out" | tail -c 5)" \
   "\"cwd\":\"$PCB\" 0 \"cwd\""
is "felix_hook_dir still reads a top-level cwd whose closing quote is the payload's 4096th byte" \
   "$(_pcwd_hd "$PCA" "$_pcwd_in")" "$PCB.0|"
is "felix_hook_dir keeps the launch directory when the top-level cwd starts past the payload's first 4096 bytes" \
   "$(_pcwd_hd "$PCA" "$_pcwd_out")" "$PCA.0|"

# ---- rule 3': the launch directory, however it is spelt, resolves nothing.
# The round-one spy, with the shell standing where the first argument says.
_pcwd_spy() {   # launch dir as the shell reaches it, payload cwd -> "printed.status|stderr|calls"
  ( cd "$1" && . "$FROOT/harness/lib/resolve.sh"; : > "$PC/spy"
    felix_repo_root()       { printf 'felix_repo_root ' >> "$PC/spy"; printf '%s' "${1:-$PWD}"; }
    felix_resolve_project() { printf 'felix_resolve_project ' >> "$PC/spy"; return 1; }
    felix_binding_broken()  { printf 'felix_binding_broken ' >> "$PC/spy"; }
    git()                   { printf 'git ' >> "$PC/spy"; command git "$@"; }
    o="$(felix_hook_dir "$(_pcwd_hdp "$2")" "$PH" 2>"$PC/hd.err"; printf '.%s' "$?")"
    printf '%s|%s|%s' "$o" "$(cat "$PC/hd.err")" "$(cat "$PC/spy")" )
}
is "felix_hook_dir answers a launch directory reached through a symlink by that logical spelling, resolving nothing, when the payload names its physical path" \
   "$(_pcwd_spy "$PC/via-link" "$PCA")" "$PC/via-link.0||"
is "felix_hook_dir answers a payload cwd naming the launch directory with a trailing slash by the launch directory, resolving nothing" \
   "$(_pcwd_spy "$PCA" "$PCA/")" "$PCA.0||"

# ---- rule 4': a governed launch directory is left only for its own project.
is "felix_hook_dir keeps a governed launch directory when the payload's cwd is a checkout nested in it whose marker names another project" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "$PCNEST")")" "$PCA.0|"
is "felix_hook_dir keeps a governed launch directory when the payload's cwd is a checkout bound to another project by its remote alone" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "$PCR")")" "$PCA.0|"
is "felix_hook_dir prints that nested checkout of another project when the launch directory governs nothing" \
   "$(_pcwd_hd "$PCU" "$(_pcwd_hdp "$PCNEST")")" "$PCNEST.0|"
is "felix_hook_dir prints a subdirectory of a checkout whose marker is broken, though the launch directory is governed" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "$PCK/sub")")" "$PCK/sub.0|"

# ---- Stop: a nested checkout of another project does not trade away the
# launch checkout's gate for a project that declares none.
is "Stop launched in a governed checkout holding unverified work still blocks on it when the payload's cwd is a nested checkout of a project that declares no gate" \
   "$(_pcwd_stop "$PCA" "$(_pcwd_sp pc-r2s1 "$PCNEST")")" "$_pcwd_held"

# ---- pre-tool (C3'): the launch checkout's rows first, whatever the payload says.
is "PreToolUse launched in a governed checkout refuses by its own row when the payload's cwd is a checkout of another project with no deny table" \
   "$(_pcwd_pre "$PCA" "$(_pcwd_ptp pc-r2p1 "$PCR")")" "2"
has "and that refusal names the launch checkout's deny table" "$(cat "$PC/pre.err" 2>/dev/null)" \
    "This is a rule in $PH/projects/pcwd/deny.tsv"
printf 'Bash\t(^|[;&| ])cargo publish\tpcwdremote refuses a crate publish\n' > "$PH/projects/pcwdremote/deny.tsv"
is "PreToolUse launched in a governed checkout refuses by its own row when the payload's cwd is a checkout of another project whose deny table lacks that row" \
   "$(_pcwd_pre "$PCA" "$(_pcwd_ptp pc-r2p2 "$PCR")")" "2"
has "and that refusal also names the launch checkout's deny table" "$(cat "$PC/pre.err" 2>/dev/null)" \
    "This is a rule in $PH/projects/pcwd/deny.tsv"
rm -f "$PH/projects/pcwdremote/deny.tsv"
# Launched where nothing governs, with a row scoped to the checkout. The
# worktree the payload names lies under the temporary root lib/where.sh lifts
# scratch in, so only standing in it makes it the governed checkout.
cp "$PH/projects/pcwd/deny.tsv" "$PC/deny.keep"
printf 'Bash\tgit add ([^;&|]* )?(-A|--all|\\.)( |$)\tpcwd refuses staging all of its checkout\tcheckout\n' \
  >> "$PH/projects/pcwd/deny.tsv"
_pcwd_tr="$(cd -P "${TMPDIR:-/tmp}" 2>/dev/null && pwd -P)"
if [ -n "$_pcwd_tr" ] && case "$PCB/" in "${_pcwd_tr%/}/"*) true ;; *) false ;; esac; then
  ok  "the payload-cwd fixture's worktree lies under the TMPDIR the suite was given"
else
  bad "the payload-cwd fixture's worktree lies under the TMPDIR the suite was given" "worktree [$PCB] TMPDIR [${TMPDIR:-}]"
fi
_pcwd_ptc() { _pcwd_pay PreToolUse "$1" "$2" "\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"$3\"},\"tool_use_id\":\"toolu_pcwd\""; }
is "PreToolUse launched in a directory nothing governs refuses a command acting in the governed worktree the payload names by that worktree's checkout-scoped row" \
   "$(_pcwd_pre "$PCU" "$(_pcwd_ptc pc-r2p3 "$PCB" 'git add -A')")" "2"
has "and that refusal is the checkout-scoped row of the worktree's project" "$(cat "$PC/pre.err" 2>/dev/null)" \
    "pcwd refuses staging all of its checkout"
is "and the same row lifts for a command that acts only in a scratch checkout under that TMPDIR" \
   "$(_pcwd_pre "$PCU" "$(_pcwd_ptc pc-r2p4 "$PCB" "cd $PCU && git add -A")")" "0"
cp "$PC/deny.keep" "$PH/projects/pcwd/deny.tsv"

# ---- #392's unrecorded-catch prompt in the Desktop shape: the Stop hook
# started in the main checkout on main, the session in the worktree on side,
# both green and current. The guard reads the branch from the root the hook
# judges, so which branch a catch is filed under says which root that was.
# Both gated again: deny.tsv is one of the tables the decision epoch hashes,
# and it was edited above.
_pcwd_gate "$PCA"; _pcwd_gate "$PCB"
PCTA4="$(_pcwd_tid "$PCA")"; PCTB4="$(_pcwd_tid "$PCB")"
is "the payload-cwd fixture's main checkout on main and its worktree on side are both green and current" \
   "$(git -C "$PCA" symbolic-ref --short HEAD 2>/dev/null) $(_pcwd_current "$PCA") $(git -C "$PCB" symbolic-ref --short HEAD 2>/dev/null) $(_pcwd_current "$PCB")" \
   "main current side current"
# One catch the gate filed ten minutes ago under no session: day, branch,
# commit, checks, second, session. Nothing in written.log settles it.
_pcwd_catch() {   # branch -> a mistakes.log holding that one catch, named quokka-<branch>
  local at d; at=$(( $(date +%s) - 600 ))
  d="$(date -r "$at" +%Y-%m-%d 2>/dev/null || date -d "@$at" +%Y-%m-%d)"
  printf '%s\t%s\tabc1234\tquokka-%s\t%s\t-\n' "$d" "$1" "$1" "$at" > "$PM/pcwd/mistakes.log"
}
_pcwd_stopu() {   # launch dir, payload -> "prompt[last caught]|silent|block +rows verdict tree reason"
  local n0 o
  n0="$(_pcwd_rows)"; o="$(_pcwd_hook "$1" stop "$2")"
  case "$o" in
    *'The gate caught something here and nothing has been written down since.'*)
      printf 'prompt[%s]' "$(printf '%s\n' "$o" | sed -n 's/.*  last caught   \([^\\]*\)\\n.*/\1/p' | head -1)" ;;
    *'"decision"'*'"block"'*) printf 'block' ;;
    '')                       printf 'silent' ;;
    *)                        printf 'other[%s]' "$(printf '%s' "$o" | head -c 200)" ;;
  esac
  printf ' +%s %s' "$(( $(_pcwd_rows) - n0 ))" "$(tail -1 "$_pcwd_vlog" 2>/dev/null | cut -f2-4 | tr '\t' ' ')"
}
_pcwd_catch side
is "Stop in the Desktop shape asks about a recent session-less catch filed under the worktree's branch" \
   "$(_pcwd_stopu "$PCA" "$(_pcwd_sp pc-r2u1 "$PCB")")" "prompt[quokka-side] +1 allowed $PCTB4 green"
_pcwd_catch main
is "Stop in the Desktop shape does not ask about a session-less catch filed under the main checkout's branch only" \
   "$(_pcwd_stopu "$PCA" "$(_pcwd_sp pc-r2u2 "$PCB")")" "silent +1 allowed $PCTB4 green"
rm -f "$PM/pcwd/mistakes.log"

# ---- SubagentStart with a terminal on stdin, as when a person runs it by hand.
# The closed pipe above ends a read whether or not it is guarded; a terminal
# held open does not. python3's pty gives the hook one as stdin, with stdout and
# stderr in a file, and kills the one process it forked if that has not exited
# within its bound, so a read that waits on the terminal fails here rather than
# hanging the suite. Measured on 2026-10-02: a subagent-start that reads its
# stdin unguarded fails this as `hung silent`, and the closed pipe stays green.
_pcwd_tty() {   # launch dir, hook, output file -> "exited <status>" or "hung"
  FELIX_HOME="$PH" FELIX_MEMORY="$PM" python3 - "$1" "$FROOT/harness/hooks/$2" "$3" <<'PY'
import os, pty, sys, time
where, hook, out = sys.argv[1:4]
pid, fd = pty.fork()
if pid == 0:
    try:
        os.chdir(where)
        o = os.open(out, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o644)
        os.dup2(o, 1)
        os.dup2(o, 2)
        os.execv(hook, [hook])
    finally:
        os._exit(127)
end = time.time() + 45
while time.time() < end:
    done, status = os.waitpid(pid, os.WNOHANG)
    if done:
        print('exited %d' % (os.WEXITSTATUS(status) if os.WIFEXITED(status) else 128 + os.WTERMSIG(status)))
        sys.exit(0)
    time.sleep(0.05)
os.kill(pid, 9)
os.waitpid(pid, 0)
print('hung')
PY
}
if command -v python3 >/dev/null 2>&1; then
  _pco="$(_pcwd_tty "$PCA" subagent-start "$PC/tty.out" 2>&1)"
  case "$(cat "$PC/tty.out" 2>/dev/null)" in
    *"Constitution: $PH/projects/pcwd/CLAUDE.md"*) _pco="$_pco binds" ;;
    *)                                             _pco="$_pco silent" ;;
  esac
  is "SubagentStart with a terminal on its stdin finishes without waiting on it, and binds the launch checkout" "$_pco" "exited 0 binds"
else
  skip "SubagentStart with a terminal on its stdin finishes without waiting on it, and binds the launch checkout" "python3 is not installed"
fi

# ---- round-two review pins. Written after the review, from its findings, not
# blind: three things the round-two reviewer measured that nothing above could
# see.
# A launch directory whose marker is broken was meant to be governed. Stepping
# over it into a healthy worktree left the breakage reported nowhere.
is "felix_hook_dir keeps a launch directory whose marker is broken, though the payload names a governed worktree" \
   "$(_pcwd_hd "$PCK" "$(_pcwd_hdp "$PCB")")" "$PCK.0|"
# The CLI shortcut must not fork: it runs on every tool call. Measured by
# refusing forks rather than by timing them, because the child CPU of a few
# hundred tiny subshells sat under any threshold that load would not also
# cross. Held to one process, a shortcut that forks nothing answers; one that
# asks a subshell where the directory is cannot, and the shell says so. Root
# ignores the limit, so there it is skipped rather than passed.
_pcwd_nofork="$( cd "$PC/via-link" || exit 1
                 . "$FROOT/harness/lib/resolve.sh"
                 p="{\"session_id\":\"pc-fork\",\"transcript_path\":\"$PT/pc-fork.jsonl\",\"cwd\":\"$PCA\",\"hook_event_name\":\"PreToolUse\"}"
                 [ "${EUID:-0}" -ne 0 ] && ulimit -u 1 2>/dev/null || { printf 'unlimited'; exit 0; }
                 _felix_hook_dir_set "$p" "$PH" 2>&1
                 [ "$_felix_hd" = "$PWD" ] && printf 'stayed' )"
if [ "$_pcwd_nofork" = unlimited ]; then
  skip "the same-directory shortcut forks nothing: held to one process, a symlinked launch path still stays" "processes cannot be limited here"
else
  is "the same-directory shortcut forks nothing: held to one process, a symlinked launch path still stays" \
     "$_pcwd_nofork" "stayed"
fi
# pre-tool in a repository nothing governs, which is most of them, asks for its
# remote once, as main does: the hook did not move, so there is nothing to ask
# again. Counted at git itself, through a shim first on PATH.
PCUR="$PX/plain-remote"; mkdir -p "$PCUR"; _pcwd_git -C "$PCUR" init -q -b main
git -C "$PCUR" config remote.origin.url https://example.invalid/nobody.git
PCUR="$(cd "$PCUR" && pwd -P)"
mkdir -p "$PC/gitspy"
printf '#!/bin/sh\ncase "$*" in *"remote get-url"*) echo x >> "$PCWD_SPY_LOG" ;; esac\nexec "$PCWD_REAL_GIT" "$@"\n' > "$PC/gitspy/git"
chmod +x "$PC/gitspy/git"; : > "$PC/gitspy.log"
( cd "$PCUR" && printf '{"session_id":"pc-once","transcript_path":"%s/pc-once.jsonl","cwd":"%s","hook_event_name":"PreToolUse","tool_name":"Read","tool_input":{"file_path":"%s/x"}}' "$PT" "$PCUR" "$PCUR" \
    | PATH="$PC/gitspy:$PATH" PCWD_REAL_GIT="$(command -v git)" PCWD_SPY_LOG="$PC/gitspy.log" \
      FELIX_HOME="$PH" FELIX_MEMORY="$PM" "$FROOT/harness/hooks/pre-tool" >/dev/null 2>&1 )
is "PreToolUse in a checkout nothing governs asks git for its remote once, as main does, when the payload's cwd is that checkout" \
   "$(wc -l < "$PC/gitspy.log" | tr -d ' ')" "1"
unset _pcwd_nofork PCUR

# Left as found: the sealed marker readable again, and nothing of this section's
# by name for a later one to read.
chmod 644 "$PCQ/.felix" 2>/dev/null
unset PC PH PM PT PX PCA PCB PCU PCN PCK PCR PCQ PCBS PCW2 PCHA PCHB PCTA1 PCTB1 PCTA2 PCTB2 \
      _pco _pcwd_p _pcwd_vlog _pcwd_bigsz _pcwd_held _pcwd_err0 \
      PCNEST PCTA4 PCTB4 _pcwd_in _pcwd_out _pcwd_tr
unset -f _pcwd_git _pcwd_pay _pcwd_hook _pcwd_pre _pcwd_tid _pcwd_gate _pcwd_current _pcwd_res \
         _pcwd_rows _pcwd_stop _pcwd_sp _pcwd_hd _pcwd_hdp _pcwd_killtree _pcwd_bounded \
         _pcwd_big_one _pcwd_big _pcwd_msg _pcwd_bigp _pcwd_he _pcwd_ptp _pcwd_handoffs _pcwd_closed \
         _pcwd_at _pcwd_spy _pcwd_ptc _pcwd_catch _pcwd_stopu _pcwd_tty
# <<< hook-payload-cwd
printf '\nthe completion gate\n'
# The principle under test: an agent must not be able to say it is finished
# while the tree it changed has never been verified. Everything here drives the
# real Stop hook with real JSON on stdin, against a real git repository.
STOP="$FROOT/harness/hooks/stop"
# Earlier sections rewrite the widget gate to prove other things, so this one
# declares the gate it depends on instead of inheriting whatever ran last.
# Without this the red-gate case silently tests a gate of `true`, which cannot
# fail, and the failure reads like a product bug rather than a suite bug.
cat > "$FROOT/projects/widget/project.json" <<'EOF'
{
  "name": "widget",
  "remote_match": "example.com/widget",
  "gate": "sh -c 'test -f WIDGET.txt && echo widget-gate-ran'"
}
EOF
GREPO="$TMP/gaterepo"
mkdir -p "$GREPO"
( cd "$GREPO" && git init -q -b main
  printf 'contents\n' > WIDGET.txt
  printf 'widget\n'   > .felix
  git add -A >/dev/null 2>&1
  git -c user.name=t -c user.email=t@t commit -qm init >/dev/null 2>&1 )
GREPO="$(cd "$GREPO" && pwd -P)"

EMPTY_JSON='{"hook_event_name":"Stop","stop_hook_active":false}'
ACTIVE_JSON='{"hook_event_name":"Stop","stop_hook_active":true}'
_stop() { ( cd "$1" && printf '%s' "${2:-$EMPTY_JSON}" | "$STOP" 2>&1 ); }
_blocks() {
  case "$2" in *'"decision"'*'"block"'*) ok "$1" ;; *) bad "$1" "expected a block, got [$2]" ;; esac
}
_allows() { [ -z "$2" ] && ok "$1" || bad "$1" "expected silence, got [$2]"; }

out="$(_stop "$GREPO")"; rc=$?
_allows "a session that changed nothing stops silently" "$out"
is      "and exits 0"                                   "$rc" "0"

# The guidebook states DEFINITION OF DONE absolutely: never declare a task
# complete while a required deterministic verification step is failing. The hook
# opened with a bare `felix_tree_dirty || exit 0`, so committing your work
# skipped the check entirely — and committing is what you do at the end. Every
# session that finished properly was the one never asked.
#
# "Dirty" was standing in for "this session changed something", and those come
# apart the moment anybody commits. SessionStart now records the HEAD it saw, so
# the two can be told apart.
SESS='{"hook_event_name":"Stop","stop_hook_active":false,"session_id":"dod-sess"}'
# Laid by the real hook rather than hand-written, so the test exercises the
# path that actually runs. UserPromptSubmit carries the session id;
# SessionStart never reads its payload at all.
_start_at() {
  rm -f "$FROOT/state/session/dod-sess"
  ( cd "$1" && printf '{"session_id":"dod-sess","prompt":"begin"}' \
      | "$FROOT/harness/hooks/user-prompt" >/dev/null 2>&1 )
}

_start_at "$GREPO"
out="$(_stop "$GREPO" "$SESS")"
_allows "a recorded session that committed nothing is still silent" "$out"

printf 'committed work\n' >> "$GREPO/WIDGET.txt"
( cd "$GREPO" && git add -A >/dev/null 2>&1 \
  && git -c user.name=t -c user.email=t@t commit -qm work >/dev/null 2>&1 )
out="$(_stop "$GREPO" "$SESS")"
_blocks "committing unverified work no longer skips the check" "$out"
has     "and says the gate has not seen it"                    "$out" "gate"

# Fail open when there is no record: a session that began before this shipped,
# or one whose id could not be read, must not start blocking on a clean tree.
out="$(_stop "$GREPO" "$EMPTY_JSON")"
_allows "with no session record it behaves as before" "$out"
rm -f "$FROOT/state/session/dod-sess"

# Restore the fixture for the assertions below, which expect an unverified edit.
( cd "$GREPO" && git reset -q --hard HEAD~1 )

printf 'edited\n' >> "$GREPO/WIDGET.txt"
out="$(_stop "$GREPO")"
_blocks "an unverified change blocks completion" "$out"
has     "and says the gate never ran"            "$out" "never"

# The table is written BEFORE the gate runs. stack.tsv is in the epoch's
# policy set, and a receipt is bound to the epoch its gate ran under (v3.2
# §5), so a table edited after the gate stales the receipt and the stop below
# would block on "the table set moved" — correctly — instead of reaching the
# nudge this is about.
printf 'plugin\tsuperpowers@x\t-\tlow\talways\n' > "$FROOT/projects/widget/stack.tsv"
out="$(cd "$GREPO" && "$FELIX" gate 2>&1)"
out="$(_stop "$GREPO")"
_allows "a green gate on this exact tree allows it" "$out"

# A green gate proves the suite passed and nothing about the claims made on the
# way there. Those are what go wrong: work reported as fixed that reached no
# session, a tool reported as removed that was still installed, a document
# describing a capability the thing had outgrown. All three passed a gate.
rm -rf "$FROOT/state/verified"
out="$(cd "$GREPO" && printf '{"hook_event_name":"Stop","stop_hook_active":false,"session_id":"vsess"}' \
       | "$STOP" 2>&1)"
has "a green gate still asks for verification" "$out" "verification-before-completion"
has "and says why the gate is not enough"      "$out" "does not mean"
has "and says the suite passed when nothing was skipped" "$out" "which means the suite passed"
# Once per session. Said at every stop it becomes noise, and noise is skimmed.
out="$(cd "$GREPO" && printf '{"hook_event_name":"Stop","stop_hook_active":false,"session_id":"vsess"}' \
       | "$STOP" 2>&1)"
case "$out" in
  *verification-before-completion*) bad "and only once per session" "$out" ;;
  *)                                ok  "and only once per session" ;;
esac

# And the sentence does NOT claim a passing suite when the gate skipped it.
# `felix gate --quick` skips the tests and still exits 0, so its receipt was
# byte-identical to a full run's — one bit — and this said "the suite passed"
# over it. The receipt's fifth field names what the gate reported skipping.
# Placed after the once-per-session assertion above, not before it: clearing
# the marker is what that assertion measures, so a block that clears it in the
# middle makes the sentence fire twice and reads as a defect in the hook rather
# than in the fixture.
rm -rf "$FROOT/state/verified"
( cd "$GREPO" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$GREPO" "$FROOT" 0 "gate.sh" "$(felix_tree_id "$GREPO" "$FROOT")" "tests" >/dev/null 2>&1 )
out="$(cd "$GREPO" && printf '{"hook_event_name":"Stop","stop_hook_active":false,"session_id":"vsess-skip"}' \
       | "$STOP" 2>&1)"
has "a gate that skipped the suite is not called a passing suite" "$out" "it skipped: tests"
case "$out" in
  *"which means the suite passed"*) bad "and the claim it could not support is gone" "$out" ;;
  *)                                ok  "and the claim it could not support is gone" ;;
esac
( cd "$GREPO" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$GREPO" "$FROOT" 0 "gate.sh" "$(felix_tree_id "$GREPO" "$FROOT")" "" >/dev/null 2>&1 )
# A project that does not use superpowers is not told to reach for it.
printf 'plugin\tsomething-else@x\t-\tlow\talways\n' > "$FROOT/projects/widget/stack.tsv"
rm -rf "$FROOT/state/verified"
out="$(cd "$GREPO" && printf '{"hook_event_name":"Stop","stop_hook_active":false,"session_id":"vsess2"}' \
       | "$STOP" 2>&1)"
case "$out" in
  *verification-before-completion*) bad "and never where it is not declared" "$out" ;;
  *)                                ok  "and never where it is not declared" ;;
esac
rm -rf "$FROOT/state/verified"

# The git-status trap. Two different edits to the same file produce identical
# porcelain output, so a receipt keyed on status alone stays valid across a
# change it never saw. The hash has to include diff content.
printf 'different\n' >> "$GREPO/WIDGET.txt"
out="$(_stop "$GREPO")"
_blocks "editing the same file again invalidates the receipt" "$out"

( cd "$GREPO" && git checkout -q -- WIDGET.txt )
out="$(cd "$GREPO" && "$FELIX" gate 2>&1)"
printf 'new\n' > "$GREPO/untracked.txt"
out="$(_stop "$GREPO")"
_blocks "a new untracked file invalidates the receipt" "$out"
rm -f "$GREPO/untracked.txt"

# The platform caps consecutive blocks and documents the contract: return
# success while stop_hook_active is set. Ignoring it is how a hook loops.
printf 'unverified\n' >> "$GREPO/WIDGET.txt"
out="$(_stop "$GREPO" "$ACTIVE_JSON")"
_allows "stop_hook_active is honoured, so it never loops" "$out"

# That rule is about a chain Felix started, and the flag does not say who did.
# An asyncRewake hook that exits 2 wakes the model into a turn of its own with
# the flag already set (measured on Claude Code 2.1.260 and 2.1.280, a Stop
# and a PostToolUse hook alike), and security-guidance, which commissioning
# installs for every project, is one. Leaving at the flag let the turn that
# answered a background review end unchecked and unrecorded. Driven through
# the real hook, in the order the platform sends these stops.
_hj() { printf '{"hook_event_name":"Stop","stop_hook_active":%s,"session_id":"%s"}' "$1" "$2"; }
_hv="$MEM/widget/verification.log"
_hn() { awk 'END { print NR }' "$_hv" 2>/dev/null || echo 0; }
rm -rf "$FROOT/state/held"
_n0="$(_hn)"
out="$(_stop "$GREPO" "$(_hj true rw-foreign)")"
_blocks "a flagged stop in a chain Felix did not start is judged, not waved through" "$out"
is "and that hold is on the record" "$(( $(_hn) - _n0 )):$(tail -1 "$_hv" | cut -f2)" "1:blocked"
# Silence alone cannot tell Felix's own chain from a hold that went unrecorded
# and was then refused inside a chain it took for another's. Only the first
# writes no row.
_n0="$(_hn)"
out="$(_stop "$GREPO" "$(_hj true rw-foreign)")"
is "the flagged stop after that hold is Felix's own chain, and ends there" \
   "$(( $(_hn) - _n0 )):[$out]" "0:[]"

# The record is taken by the stop it was for, so a rewake turn right after
# Felix's own chain is not mistaken for part of it.
out="$(_stop "$GREPO" "$(_hj false rw-own)")"
_n0="$(_hn)"
out="$(_stop "$GREPO" "$(_hj true rw-own)")"
is "a hold lets the one flagged stop it started end" "$(( $(_hn) - _n0 )):[$out]" "0:[]"
out="$(_stop "$GREPO" "$(_hj true rw-own)")"
_blocks "and only that one: the rewake turn after it is judged" "$out"

# A chain can end without reaching its flagged stop (an interrupted turn), and
# the next prompt's stop is unflagged. That stop starts afresh and clears what
# was left, or the leftover waves the next rewake turn through.
out="$(_stop "$GREPO" "$(_hj false rw-stale)")"
out="$(cd "$GREPO" && _hj false rw-stale | FELIX_ALLOW_RED=1 "$STOP" 2>&1)"
out="$(_stop "$GREPO" "$(_hj true rw-stale)")"
_blocks "an unflagged stop clears a hold left behind" "$out"

