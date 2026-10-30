# The lane counter's fixtures (slice 0, docs/2026-10-29-capability-lane-first-slices-design.md section 6; the plan's
# Contracts C9 and C11), for the blind parts 2200 to 2250. Written blind on 2026-10-29 from the design and the
# Contracts alone, without reading lib/, hooks/, bin/ or felix.
#
# Functions only (part 0006): nothing runs and nothing is assigned when this file is sourced. Each builder takes the
# directory to build in, under $TMP, and sets its LF_* variables when it is called; a builder that fails leaves its
# result variable empty and returns 1, so a part that checks what it built sees the failure there. Every git command a
# builder runs stands behind _fx_cd (part 0002), in a subshell, and runs with no global or system configuration, a
# fixed identity and a pinned author and committer time, as "<epoch> +0000" (C9).
#
# The two layouts of C9: a home apart (_lf_home, then _lf_checkout for a checkout bound by an untracked .felix), and
# one self-governed repository (_lf_self). Tables are committed in the home with _lf_table, broken ones included:
# its bytes are written as given, a CR or a missing last newline kept. Landings are made with _lf_commit (a message
# kept byte for byte, with --cleanup=verbatim, and the paths it changes), _lf_squash (felix merge's or GitHub's
# default squash message, C3), _lf_merge (a real merge commit) and _lf_chain (a run of marked and unmarked landings),
# and refs/remotes/origin/main is published with _lf_publish. The surfaces run through _lf_run and _lf_start in the
# environment _lf_use names, with the stubs of _lf_stubs first on PATH. A session-start fixture that expects the lane
# paragraph or token makes its checkout the project's own (C7, C9) with _lf_own, or with _lf_match and _lf_origin apart.
#
# For the parts of status, session start and the pulse (2230 to 2250): felix status --tsv is _lf_run OUT DIR NOW
# "$FELIX" status --tsv, and _lf_last OUT.out its last row; felix pulse is _lf_run in the home of an _lf_self layout,
# with a memory root outside it (C2, C9). _lf_start runs the hook, waits for the discovery lock and reads the JSON with
# python3 (check for python3 first, and skip with a reason); _lf_silent says whether a lane paragraph or token showed;
# _lf_start with a fifth argument runs another engine root, such as the copy _lf_broken makes. NOW - leaves
# FELIX_LANE_NOW unset; any other NOW, 0123 included, is passed as it is.
#
# C9's faults (added on 2026-10-30 for the review's findings, still blind): _lf_fault runs _lf_run or _lf_start with
# git a bash function exported into the engine, that makes a fork fail (fork) or ends the count early (kill) in the
# read of the landings, and with TMPDIR a directory of the fixture's own, so a scratch directory left is seen there and
# removed with $TMP. _lf_json reads a session start's JSON again after it.
#
# The second review's round 1 (added on 2026-10-30, still blind, from its findings' inputs): _lf_r2 builds its home-apart
# fixture (two lanes, cap and sec, and _lf_r2land's six landings), _lf_fork runs its fork probes at reads other than the
# landings' (date, awk, tr, git or command, by the words and calling functions a finding names), and _lf_ended says
# whether felix lane ended as C3's count that did not finish.
#
# The second review's round 2 (added on 2026-10-30, still blind): _lf_kill runs C9's kill at a read a finding names
# (pwd among them, by its words and calling functions), and _lf_gone takes the count's scratch directory away at an awk
# call a finding names, as a cleaner of TMPDIR would.
#
# The second review's round 3 (added on 2026-10-30, still blind): _lf_r3 builds R3-F1's home-apart fixture, whose first
# lane is short (sec before cap), and _lf_nfprog and _lf_lroot run felix and the hook under a soft open-file limit set in
# the shell that execs them.
#
# The design's item 46 (added on 2026-10-30, still blind, from C2's bullet "The lane's resolution", C5, C6 and C8):
# _lf_bind puts a repository in one of the layouts a binding takes or misses, _lf_probe runs C9's fork or kill probe and
# says whether it acted in felix's own shell, and _lf_said reads what felix lane said of the resolution.

# DIR -> DIR removed if there and made again, empty; LF_DIR its physical path. DIR must lie below $TMP.
_lf_dir() {
  LF_DIR=""
  case "${1-}" in "$TMP"/?*) ;; *) printf '_lf_dir: [%s] is not below $TMP\n' "${1-}" >&2; return 1 ;; esac
  rm -rf "$1" && mkdir -p "$1" || return 1
  LF_DIR="$(cd -P -- "$1" && pwd -P)"
  [ -n "$LF_DIR" ]
}

# T ARGS... -> git ARGS where the caller stands (after _fx_cd, in a subshell), with no global or system configuration,
# the identity lane <lane@example.invalid>, author and committer time T (epoch seconds, UTC), no hooks and no signing.
_lf_g() {
  local t="$1"
  shift
  GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 \
    GIT_AUTHOR_NAME=lane GIT_AUTHOR_EMAIL=lane@example.invalid GIT_COMMITTER_NAME=lane GIT_COMMITTER_EMAIL=lane@example.invalid \
    GIT_AUTHOR_DATE="$t +0000" GIT_COMMITTER_DATE="$t +0000" \
    git -c core.autocrlf=false -c core.safecrlf=false -c commit.gpgsign=false -c core.hooksPath=/dev/null \
      -c gc.auto=0 -c maintenance.auto=false "$@"
}

# DIR [BRANCH] -> a new repository in DIR (made when missing) on BRANCH (main), with no commit.
_lf_init() {
  mkdir -p "$1" || return 1
  ( _fx_cd "$1" || exit 1; _lf_g 1700000000 init -q -b "${2:-main}" ) >/dev/null 2>&1
}

# DIR T MESSAGE [SPEC...] -> one commit on the branch DIR stands on, at time T, whose message is MESSAGE byte for byte,
# changing what each SPEC names, relative to DIR: PATH appends a line to PATH (made, with its directories, when
# missing), =PATH adds PATH as it stands, -PATH removes it, OLD>NEW moves OLD to NEW. What is staged already (a squash,
# a merge) is committed with it, and no SPEC with nothing staged is an empty commit. LF_SHA is the commit's full name,
# or empty when it could not be made or its stored message is not MESSAGE.
_lf_commit() {
  local d="$1" t="$2" m="$3"
  shift 3
  LF_SHA="$( _fx_cd "$d" || exit 1
    for s in "$@"; do
      case "$s" in
        (-*) _lf_g "$t" rm -q -- "${s#-}" || exit 1 ;;
        (=*) _lf_g "$t" add -- "${s#=}" || exit 1 ;;
        (*'>'*) mkdir -p "$(dirname -- "${s#*>}")" && _lf_g "$t" mv -- "${s%%>*}" "${s#*>}" || exit 1 ;;
        (*) mkdir -p "$(dirname -- "$s")" && printf '%s %s\n' "$t" "$s" >> "$s" && _lf_g "$t" add -- "$s" || exit 1 ;;
      esac
    done
    printf '%s' "$m" | _lf_g "$t" commit -q --allow-empty --cleanup=verbatim -F - || exit 1
    h="$(_lf_g "$t" rev-parse --verify -q HEAD)" || exit 1
    f="$(mktemp "$TMP/lf-commit.XXXXXX")" || exit 1
    _lf_g "$t" cat-file commit "$h" > "$f" || { rm -f "$f"; exit 1; }
    { sed '/^$/q' "$f"; printf '%s' "$m"; } > "$f.want"
    cmp -s "$f" "$f.want"; r=$?
    rm -f "$f" "$f.want"
    [ "$r" -eq 0 ] || exit 1
    printf '%s' "$h" )" || LF_SHA=""
  [ -n "$LF_SHA" ]
}

# DIR NAME [START] -> a new branch NAME at START (HEAD), and DIR stands on it.
_lf_branch() { ( _fx_cd "$1" || exit 1; _lf_g 1700000000 checkout -q -b "$2" ${3+"$3"} ) >/dev/null 2>&1; }
# DIR NAME -> DIR stands on the branch NAME.
_lf_switch() { ( _fx_cd "$1" || exit 1; _lf_g 1700000000 checkout -q "$2" ) >/dev/null 2>&1; }

# DIR T BRANCH MESSAGE -> a real merge of BRANCH into the branch DIR stands on (--no-ff), at time T, whose message is
# MESSAGE byte for byte. LF_SHA as _lf_commit's; empty also when the commit made has no second parent.
_lf_merge() {
  local d="$1" t="$2" b="$3" m="$4"
  LF_SHA=""
  ( _fx_cd "$d" || exit 1; _lf_g "$t" merge -q --no-ff --no-commit "$b" ) >/dev/null 2>&1 || return 1
  _lf_commit "$d" "$t" "$m" || return 1
  ( _fx_cd "$d" || exit 1; _lf_g "$t" rev-parse --verify -q "$LF_SHA^2" ) >/dev/null 2>&1 || { LF_SHA=""; return 1; }
}

# DIR T SHAPE BRANCH SUBJECT -> the landing a squash of BRANCH makes on the branch DIR stands on (main), at time T, as
# C3 writes its message. Its entries are the non-merge commits of HEAD..BRANCH, oldest first, each "* <its message>"
# (the subject, a blank line, the body, as the commit holds them), a blank line between two. SHAPE felix: SUBJECT, a
# blank line, "felix merge squashed BRANCH at <tip>.", a blank line, the entries, a blank line, and the trailers
# Felix-Judge: and Felix-Gate:. SHAPE github (GitHub's default): SUBJECT, a blank line, the entries. No merge commit's
# message is copied. LF_SHA as _lf_commit's, LF_MSG the message.
_lf_squash() {
  local d="$1" t="$2" sh="$3" b="$4" s="$5" m
  LF_SHA=""; LF_MSG=""
  m="$( _fx_cd "$d" || exit 1
    tip="$(_lf_g "$t" rev-parse --verify -q "$b^{commit}")" || exit 1
    list="$(_lf_g "$t" rev-list --reverse --topo-order --no-merges "HEAD..$b")" || exit 1
    f="$(mktemp "$TMP/lf-squash.XXXXXX")" || exit 1
    printf '%s\n\n' "$s"
    [ "$sh" != felix ] || printf 'felix merge squashed %s at %s.\n\n' "$b" "$tip"
    sep=""
    for c in $list; do
      _lf_g "$t" cat-file commit "$c" > "$f" || { rm -f "$f"; exit 1; }
      e="$(sed '1,/^$/d' "$f"; printf x)"; e="${e%x}"
      printf '%s* %s' "$sep" "$e"
      sep=$'\n'
    done
    rm -f "$f"
    [ "$sh" != felix ] || printf '\nFelix-Judge: passed\nFelix-Gate: passed\n'
    printf x )" || return 1
  m="${m%x}"
  ( _fx_cd "$d" || exit 1; _lf_g "$t" merge -q --squash "$b" ) >/dev/null 2>&1 || return 1
  _lf_commit "$d" "$t" "$m" || return 1
  LF_MSG="$m"
}

# DIR [COMMIT] -> refs/remotes/origin/main in DIR names COMMIT (HEAD). No remote is made (C9).
_lf_publish() { ( _fx_cd "$1" || exit 1; _lf_g 1700000000 update-ref refs/remotes/origin/main "${2:-HEAD}" ) >/dev/null 2>&1; }

# DIR LANE T STEP SPEC... -> one landing for each SPEC on the branch DIR stands on, the k-th (from 1) at T + (k-1)*STEP:
# m a marked engine change (engine/<k>.sh), u an unmarked one, md a marked docs-only change (docs/<k>.md), ud an
# unmarked one. A mark is the body line Felix-Lane: LANE. Then refs/remotes/origin/main names the last; LF_SHA it.
_lf_chain() {
  local d="$1" l="$2" t="$3" st="$4" k=0 w p m
  shift 4
  for w in "$@"; do
    k=$((k + 1))
    case "$w" in m|u) p="engine/$k.sh" ;; md|ud) p="docs/$k.md" ;; *) LF_SHA=""; return 1 ;; esac
    case "$w" in m|md) m="landing $k"$'\n\n'"Felix-Lane: $l"$'\n' ;; *) m="landing $k"$'\n\nNo mark.\n' ;; esac
    _lf_commit "$d" $((t + (k - 1) * st)) "$m" "$p" || return 1
  done
  _lf_publish "$d" || { LF_SHA=""; return 1; }
}

# DIR P [T] -> a Felix home in DIR: a repository whose one commit, at T (1790000000), holds projects/P/project.json
# ({"name":"P","gate":"true"}) and projects/P/CLAUDE.md. LF_HOME its physical path, LF_PROJ LF_HOME/projects/P,
# LF_SHA the commit.
_lf_home() {
  LF_HOME=""; LF_PROJ=""
  _lf_init "$1" || return 1
  mkdir -p "$1/projects/$2" || return 1
  printf '{"name":"%s","gate":"true"}\n' "$2" > "$1/projects/$2/project.json"
  printf '# %s\n' "$2" > "$1/projects/$2/CLAUDE.md"
  _lf_commit "$1" "${3:-1790000000}" "the home of $2"$'\n' "=projects/$2/project.json" "=projects/$2/CLAUDE.md" || return 1
  LF_HOME="$(cd -P -- "$1" && pwd -P)"; LF_PROJ="$LF_HOME/projects/$2"
}

# PROJ T FILE BYTES [MESSAGE] -> PROJ/FILE holds BYTES exactly (a CR, a missing last newline and any other byte kept),
# committed at T in the repository that holds PROJ. LF_SHA the commit.
_lf_table() {
  local m="${5-}"
  [ -n "$m" ] || m="$3, as the part needs it"$'\n'
  printf '%s' "$4" > "$1/$3" || { LF_SHA=""; return 1; }
  _lf_commit "$1" "$2" "$m" "=$3"
}

# DIR P [T] -> a checkout in DIR bound to P by an untracked .felix, whose root commit, at T (1790000000), adds README
# only, on main. LF_REPO its physical path, LF_SHA the root.
_lf_checkout() {
  LF_REPO=""
  _lf_init "$1" || return 1
  printf '%s\n' "$2" > "$1/.felix" && printf 'a checkout of %s\n' "$2" > "$1/README" || return 1
  _lf_commit "$1" "${3:-1790000000}" $'the root\n' "=README" || return 1
  LF_REPO="$(cd -P -- "$1" && pwd -P)"
}

# PROJ OWNER/REPO -> PROJ/project.json is {"name":"<P>","gate":"true","remote_match":"OWNER/REPO"}, P the name of PROJ's
# directory, written in the working tree and never committed, so a home's commits are the same with it or without it.
_lf_match() {
  [ -d "${1-}" ] && [ -n "${2-}" ] || return 1
  printf '{"name":"%s","gate":"true","remote_match":"%s"}\n' "${1##*/}" "$2" > "$1/project.json"
}

# DIR URL -> DIR's origin remote names URL: added, or its URL changed when DIR has one already (a clone). Nothing is
# fetched, and no ref is made or removed. Status 0 when git reads URL back as remote.origin.url.
_lf_origin() {
  ( _fx_cd "$1" || exit 1
    if _lf_g 1700000000 config --get remote.origin.url; then _lf_g 1700000000 remote set-url origin "$2" || exit 1
    else _lf_g 1700000000 remote add origin "$2" || exit 1; fi
    [ "$(_lf_g 1700000000 config --get remote.origin.url)" = "$2" ] ) >/dev/null 2>&1
}

# PROJ DIR OWNER/REPO -> the checkout DIR, bound to PROJ's project, is that project's own (C7, C9): _lf_match PROJ
# OWNER/REPO, and DIR's origin https://github.com/OWNER/REPO.git. A checkout whose project has no remote_match, whose
# origin is another repository, or that has no origin is not own.
_lf_own() { _lf_match "$1" "$3" && _lf_origin "$2" "https://github.com/$3.git"; }

# DIR P [T] -> one repository that is both the home and the checkout, as felix-home is: its root commit, at T
# (1790000000), on main, holds .felix (P) at its top, projects/P/project.json and projects/P/CLAUDE.md. LF_HOME and
# LF_REPO its physical path, LF_PROJ LF_HOME/projects/P, LF_SHA the root.
_lf_self() {
  LF_HOME=""; LF_REPO=""; LF_PROJ=""
  _lf_init "$1" || return 1
  mkdir -p "$1/projects/$2" || return 1
  printf '%s\n' "$2" > "$1/.felix"
  printf '{"name":"%s","gate":"true"}\n' "$2" > "$1/projects/$2/project.json"
  printf '# %s\n' "$2" > "$1/projects/$2/CLAUDE.md"
  _lf_commit "$1" "${3:-1790000000}" "the home and checkout of $2"$'\n' \
    "=.felix" "=projects/$2/project.json" "=projects/$2/CLAUDE.md" || return 1
  LF_HOME="$(cd -P -- "$1" && pwd -P)"; LF_REPO="$LF_HOME"; LF_PROJ="$LF_HOME/projects/$2"
}

# DIR -> DIR/bin holding C9's stubs: claude, gh and graphify as part 1670 makes them, uname (prints Darwin) and
# launchctl (list prints its header alone, print exits 113) as part 1690 makes them. LF_BIN its path.
_lf_stubs() {
  LF_BIN=""
  mkdir -p "$1/bin" || return 1
  printf '#!/bin/sh\ncase "$*" in "plugin list --json --available") printf "[]\\n"; exit 0 ;; "mcp list"|"plugin list"|"plugin marketplace list") exit 0 ;; esac\nexit 2\n' > "$1/bin/claude"
  printf '#!/bin/sh\nexit 0\n' > "$1/bin/gh"
  printf '#!/bin/sh\nexit 0\n' > "$1/bin/graphify"
  printf '#!/bin/bash\nprintf '"'"'%%s\\n'"'"' Darwin\n' > "$1/bin/uname"
  printf '#!/bin/bash\ncase "${1:-}" in\n  print) exit 113 ;;\n  list) printf '"'"'PID\\tStatus\\tLabel\\n'"'"'; exit 0 ;;\nesac\nexit 0\n' > "$1/bin/launchctl"
  chmod +x "$1/bin/claude" "$1/bin/gh" "$1/bin/graphify" "$1/bin/uname" "$1/bin/launchctl" || return 1
  LF_BIN="$(cd -P -- "$1/bin" && pwd -P)"
}

# DIR -> a copy of the engine at DIR/root/harness: bin, ecosystem.tsv, felix, hooks, lib and templates from
# $FROOT/harness, with lib/lane.sh removed (C9's broken engine). LF_ROOT DIR/root.
_lf_broken() {
  local e
  LF_ROOT=""
  rm -rf "$1/root" && mkdir -p "$1/root/harness" || return 1
  for e in bin ecosystem.tsv felix hooks lib templates; do
    [ ! -e "$FROOT/harness/$e" ] || cp -R "$FROOT/harness/$e" "$1/root/harness/$e" || return 1
  done
  rm -f "$1/root/harness/lib/lane.sh"
  LF_ROOT="$(cd -P -- "$1/root" && pwd -P)"
}

# HOME MEMORY USER BIN -> the environment every surface runs in (C9): FELIX_HOME HOME, FELIX_MEMORY MEMORY (outside every
# fixture repository), HOME USER, BIN first on PATH. Sets LF_H, LF_M, LF_U and LF_B, and makes MEMORY and USER.
_lf_use() { LF_H="$1"; LF_M="$2"; LF_U="$3"; LF_B="$4"; mkdir -p "$2" "$3"; }

# OUT DIR NOW CMD... -> CMD run from DIR as C9 runs a surface: no CLAUDE_CODE_SESSION_ID, FELIX_HOME_DIR, COPILOT_CLI,
# CURSOR_PLUGIN_ROOT or CLAUDE_CONFIG_DIR, the environment _lf_use set, FELIX_LANE_NOW NOW (unset when NOW is -).
# Stdout in OUT.out, stderr in OUT.err, the status in LF_RC (125 when DIR could not be entered).
_lf_run() {
  local o="$1" d="$2" n="$3"
  shift 3
  ( _fx_cd "$d" || exit 125
    if [ "$n" = - ]; then
      exec env -u CLAUDE_CODE_SESSION_ID -u FELIX_HOME_DIR -u FELIX_LANE_NOW -u COPILOT_CLI -u CURSOR_PLUGIN_ROOT \
        -u CLAUDE_CONFIG_DIR HOME="$LF_U" FELIX_HOME="$LF_H" FELIX_MEMORY="$LF_M" PATH="$LF_B:$PATH" "$@"
    fi
    exec env -u CLAUDE_CODE_SESSION_ID -u FELIX_HOME_DIR -u FELIX_LANE_NOW -u COPILOT_CLI -u CURSOR_PLUGIN_ROOT \
      -u CLAUDE_CONFIG_DIR HOME="$LF_U" FELIX_HOME="$LF_H" FELIX_MEMORY="$LF_M" PATH="$LF_B:$PATH" \
      FELIX_LANE_NOW="$n" "$@" ) > "$o.out" 2> "$o.err" < /dev/null
  LF_RC=$?
}

# HOME -> waits up to 20 s while HOME/state/discover/.lock stands: a discovery a session start launched (part 1670).
_lf_calm() { local i=0; while [ "$i" -lt 100 ] && [ -d "$1/state/discover/.lock" ]; do sleep 0.2; i=$((i + 1)); done; }

# FILE KEY -> KEY's string in the JSON object FILE holds, at its top or in hookSpecificOutput, written as UTF-8 bytes;
# status 3 when FILE holds no JSON object.
_lf_jget() {
  python3 -c 'import json, sys
try: d = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception: sys.exit(3)
if not isinstance(d, dict): sys.exit(3)
v = d.get(sys.argv[2]) or (d.get("hookSpecificOutput") or {}).get(sys.argv[2]) or ""
sys.stdout.buffer.write(str(v).encode("utf-8", "surrogateescape"))' "$1" "$2" 2>/dev/null
}

# OUT DIR NOW SOURCE [ROOT] -> hooks/session-start of ROOT ($FROOT) run from DIR as C9 runs it: CLAUDE_PLUGIN_ROOT ROOT,
# the payload {"session_id":"lane-start","source":SOURCE,"cwd":DIR} on stdin, the environment of _lf_run. Then waits
# for LF_H's discovery lock to clear. Sets LF_RC; LF_JSON ok or bad (none when python3 is absent); OUT.ctx and LF_CTX
# the context (hookSpecificOutput.additionalContext), OUT.scr and LF_SCR the screen line (systemMessage).
_lf_start() {
  local o="$1" d="$2" n="$3" s="$4" r="${5:-$FROOT}"
  LF_JSON=none; LF_CTX=""; LF_SCR=""
  printf '{"session_id":"lane-start","source":"%s","cwd":"%s"}' "$s" "$d" > "$o.in"
  ( _fx_cd "$d" || exit 125
    if [ "$n" = - ]; then
      exec env -u CLAUDE_CODE_SESSION_ID -u FELIX_HOME_DIR -u FELIX_LANE_NOW -u COPILOT_CLI -u CURSOR_PLUGIN_ROOT \
        -u CLAUDE_CONFIG_DIR HOME="$LF_U" FELIX_HOME="$LF_H" FELIX_MEMORY="$LF_M" PATH="$LF_B:$PATH" \
        CLAUDE_PLUGIN_ROOT="$r" "$r/harness/hooks/session-start"
    fi
    exec env -u CLAUDE_CODE_SESSION_ID -u FELIX_HOME_DIR -u FELIX_LANE_NOW -u COPILOT_CLI -u CURSOR_PLUGIN_ROOT \
      -u CLAUDE_CONFIG_DIR HOME="$LF_U" FELIX_HOME="$LF_H" FELIX_MEMORY="$LF_M" PATH="$LF_B:$PATH" \
      FELIX_LANE_NOW="$n" CLAUDE_PLUGIN_ROOT="$r" "$r/harness/hooks/session-start" ) < "$o.in" > "$o.out" 2> "$o.err"
  LF_RC=$?
  _lf_calm "$LF_H"
  _lf_json "$o"
}

# OUT -> what a session start wrote to OUT.out, read as _lf_start reads it: LF_JSON ok or bad (none when python3 is
# absent), OUT.ctx and LF_CTX the context, OUT.scr and LF_SCR the screen line.
_lf_json() {
  LF_JSON=none; LF_CTX=""; LF_SCR=""
  command -v python3 >/dev/null 2>&1 || return 0
  if _lf_jget "$1.out" additionalContext > "$1.ctx"; then LF_JSON=ok; else LF_JSON=bad; fi
  _lf_jget "$1.out" systemMessage > "$1.scr"
  LF_CTX="$(cat "$1.ctx")"; LF_SCR="$(cat "$1.scr")"
}

# MODE FILE TMPDIR CMD... -> CMD (_lf_run or _lf_start, with their arguments) run in a subshell whose TMPDIR, exported,
# is TMPDIR, and where git is a bash function, exported, so that bash imports it into felix and the hook: C9's fault.
# The function acts when its words hold --first-parent and a word that starts refs/remotes/origin/main, the read of the
# landings, every time, and first writes "fired" to FILE. MODE fork: it lowers the soft process limit to 1 (ulimit -S
# -u 1) in the shell that called it and runs git, which that shell cannot fork, then writes "ran <status>" if the shell
# gets there. MODE kill: it writes "kill <parent> <shell>", then sends SIGKILL to the parent of the shell that called
# it, and then to that shell; never to pid 1 or to this suite's shell (it writes "kept" and runs git instead). Any
# other git runs as it is. FILE and TMPDIR hold no double quote, dollar sign, backquote, backslash or ampersand.
# LF_RC is the subshell's status (CMD's LF_RC, or 137 when the kill reached it), LF_FIRE "fired" when the function
# acted as MODE says (fork: git did not run to a clean exit after it; kill: both signals were sent), else what FILE
# shows. A session start's JSON is read again after it with _lf_json, since the subshell's variables are gone. What
# bash says on its own stderr around CMD (a note of a job the kill ended) goes to FILE.shell.
_lf_fault() {
  local m="$1" f="$2" t="$3" b
  shift 3
  LF_FIRE="not run"; LF_RC=125
  case "$f$t" in (*\"*|*\$*|*\`*|*\\*|*\&*) return 1 ;; esac
  [ -n "$f" ] && [ -n "$t" ] || return 1
  case "$m" in
    (fork) b='printf "fired\n" >> "@F@"; ulimit -S -u 1; command git "$@"; r=$?; printf "ran %s\n" "$r" >> "@F@"; return "$r"' ;;
    (kill) b='printf "fired\n" >> "@F@"; s="$(exec sh -c "echo \$PPID")"; p="$(ps -o ppid= -p "$s" 2>/dev/null)"; p="${p//[!0123456789]/}"
      case "$s:$p" in (:*|*:|1:*|*:1|@K@:*|*:@K@) printf "kept %s %s\n" "$p" "$s" >> "@F@"; command git "$@"; return ;; esac
      printf "kill %s %s\n" "$p" "$s" >> "@F@"; kill -KILL "$p"; kill -KILL "$s"; command git "$@"; return' ;;
    (*) return 1 ;;
  esac
  b="${b//@F@/$f}"; b="${b//@K@/$$}"
  rm -f "$f" "$f.shell"
  # What bash itself says, such as its note of a job a kill ended, goes to FILE.shell, not to the suite's stderr.
  { ( TMPDIR="$t"; export TMPDIR
      eval 'git() { local s p r; case " $* " in (*" --first-parent "*) case " $* " in (*" refs/remotes/origin/main"*) '"$b"' ;; esac ;; esac; command git "$@"; }' \
        || exit 125
      export -f git
      "$@"
      exit "$LF_RC" ); } 2> "$f.shell"
  LF_RC=$?
  if [ "$m" = fork ]; then
    LF_FIRE="$(LC_ALL=C awk '$0 == "fired" { f = 1 } $0 == "ran 0" { r = 1 }
      END { s = "not fired"; if (f && r) s = "fired, but git ran to a clean exit after it"; if (f && !r) s = "fired"; print s }' "$f" 2>/dev/null)"
  else
    LF_FIRE="$(LC_ALL=C awk '$0 == "fired" { f = 1 } /^kill [0123456789]+ [0123456789]+$/ { k = 1 } /^kept / { p = $0 }
      END { s = "not fired"; if (f) s = "fired, but no kill was sent [" p "]"; if (f && k) s = "fired"; print s }' "$f" 2>/dev/null)"
  fi
  [ -n "$LF_FIRE" ] || LF_FIRE="not fired"
}

# The second review's round 1 (2026-10-30), still blind: its fixture and its fork probes, taken from its findings'
# inputs. MODE NAME WORDS STACK FILE TMPDIR CMD... -> CMD run as _lf_fault runs it, but with NAME (date, awk, tr, git or
# command) the bash function exported into felix and the hook. It acts, every time, when " $* " matches the case
# pattern WORDS and " ${FUNCNAME[*]} " the case pattern STACK (each case code, quoted as the caller writes it), and
# first writes "fired" to FILE. MODE fork: it lowers the soft process limit to 1 in the shell that called it and runs
# NAME (command NAME), which that shell cannot fork, then writes "ran <status>" if the shell gets there. MODE lower: it
# lowers the limit and runs NAME, a builtin that needs no fork (builtin command), so that shell's next fork fails. LF_RC
# as _lf_fault's; LF_FIRE "fired" when it acted as MODE says (fork: NAME did not run to a clean exit after it).
_lf_fork() {
  local m="$1" n="$2" w="$3" k="$4" f="$5" t="$6" c b
  shift 6
  LF_FIRE="not run"; LF_RC=125
  case "$f$t" in (*\"*|*\'*|*\$*|*\`*|*\\*|*\&*) return 1 ;; esac
  [ -n "$f" ] && [ -n "$t" ] && [ -n "$w" ] && [ -n "$k" ] || return 1
  case "$n" in (date|awk|tr|git) c="command $n" ;; (command) c="builtin command" ;; (*) return 1 ;; esac
  case "$m" in (fork|lower) ;; (*) return 1 ;; esac
  b="$n() { local r; case \" \$* \" in ($w) case \" \${FUNCNAME[*]} \" in ($k) printf 'fired\\n' >> '$f'; ulimit -S -u 1; $c \"\$@\"; r=\$?; printf 'ran %s\\n' \"\$r\" >> '$f'; return \"\$r\" ;; esac ;; esac; $c \"\$@\"; }"
  rm -f "$f" "$f.shell"
  { ( TMPDIR="$t"; export TMPDIR
      eval "$b" || exit 125
      export -f "$n"
      "$@"
      exit "$LF_RC" ); } 2> "$f.shell"
  LF_RC=$?
  LF_FIRE="$(LC_ALL=C awk -v m="$m" '$0 == "fired" { f = 1 } $0 == "ran 0" { r = 1 }
    END { s = "not fired"; if (f) s = "fired"; if (f && r && m == "fork") s = "fired, but it ran to a clean exit after it"; print s }' "$f" 2>/dev/null)"
  [ -n "$LF_FIRE" ] || LF_FIRE="not fired"
}

# The second review's round 2 (2026-10-30), still blind, from its findings' inputs: two more of its probes.
# NAME WORDS STACK FILE TMPDIR CMD... -> CMD run as _lf_fork runs it, with NAME (pwd, date, awk, tr or git) the bash
# function exported into felix and the hook, acting as C9's kill does: when " $* " matches the case pattern WORDS and
# " ${FUNCNAME[*]} " the case pattern STACK, it writes "fired" to FILE, then "kill <parent> <shell>", and sends SIGKILL
# to the parent of the shell that called it, then to that shell; never to pid 1 or this suite's shell (it writes
# "kept" and runs NAME instead). NAME then runs (builtin pwd, or command NAME). LF_RC as _lf_fault's; LF_FIRE "fired"
# when both signals were sent, else what FILE shows.
_lf_kill() {
  local n="$1" w="$2" k="$3" f="$4" t="$5" c b
  shift 5
  LF_FIRE="not run"; LF_RC=125
  case "$f$t" in (*\"*|*\'*|*\$*|*\`*|*\\*|*\&*) return 1 ;; esac
  [ -n "$f" ] && [ -n "$t" ] && [ -n "$w" ] && [ -n "$k" ] || return 1
  case "$n" in (pwd) c="builtin pwd" ;; (date|awk|tr|git) c="command $n" ;; (*) return 1 ;; esac
  b="$n() { local s p; case \" \$* \" in ($w) case \" \${FUNCNAME[*]} \" in ($k) printf 'fired\\n' >> '$f'
    s=\"\$(exec sh -c 'echo \$PPID')\"; p=\"\$(ps -o ppid= -p \"\$s\" 2>/dev/null)\"; p=\"\${p//[!0123456789]/}\"
    case \"\$s:\$p\" in (:*|*:|1:*|*:1|$$:*|*:$$) printf 'kept %s %s\\n' \"\$p\" \"\$s\" >> '$f' ;;
      (*) printf 'kill %s %s\\n' \"\$p\" \"\$s\" >> '$f'; kill -KILL \"\$p\"; kill -KILL \"\$s\" ;; esac ;; esac ;; esac; $c \"\$@\"; }"
  rm -f "$f" "$f.shell"
  { ( TMPDIR="$t"; export TMPDIR
      eval "$b" || exit 125
      export -f "$n"
      "$@"
      exit "$LF_RC" ); } 2> "$f.shell"
  LF_RC=$?
  LF_FIRE="$(LC_ALL=C awk '$0 == "fired" { f = 1 } /^kill [0123456789]+ [0123456789]+$/ { k = 1 } /^kept / { p = $0 }
    END { s = "not fired"; if (f) s = "fired, but no kill was sent [" p "]"; if (f && k) s = "fired"; print s }' "$f" 2>/dev/null)"
  [ -n "$LF_FIRE" ] || LF_FIRE="not fired"
}

# WORDS STACK FILE TMPDIR CMD... -> CMD run as _lf_fork runs it, with awk the bash function exported into felix and the
# hook: the first time " $* " matches the case pattern WORDS and " ${FUNCNAME[*]} " the case pattern STACK while a
# scratch directory of the count (C2: TMPDIR/felix-lane.*) stands, it removes every such directory, as a cleaner of
# TMPDIR or a full disk would take it mid-count, writes "fired" to FILE when none is left, and then runs the real awk.
# LF_RC as _lf_fault's; LF_FIRE "fired" when it removed them, else "not fired".
_lf_gone() {
  local w="$1" k="$2" f="$3" t="$4" b
  shift 4
  LF_FIRE="not run"; LF_RC=125
  case "$f$t" in (*\"*|*\'*|*\$*|*\`*|*\\*|*\&*) return 1 ;; esac
  [ -n "$f" ] && [ -n "$t" ] && [ -n "$w" ] && [ -n "$k" ] || return 1
  b="awk() { local d x=''; case \" \$* \" in ($w) case \" \${FUNCNAME[*]} \" in ($k)
    for d in '$t'/felix-lane.*; do [ ! -d \"\$d\" ] || x=1; done
    if [ -n \"\$x\" ] && mkdir '$f.once' 2>/dev/null; then rm -rf '$t'/felix-lane.*; x=''
      for d in '$t'/felix-lane.*; do [ ! -e \"\$d\" ] || x=1; done; [ -n \"\$x\" ] || printf 'fired\\n' >> '$f'; fi ;; esac ;; esac
    command awk \"\$@\"; }"
  rm -rf "$f" "$f.shell" "$f.once"
  { ( TMPDIR="$t"; export TMPDIR
      eval "$b" || exit 125
      export -f awk
      "$@"
      exit "$LF_RC" ); } 2> "$f.shell"
  LF_RC=$?
  LF_FIRE="$(LC_ALL=C awk '$0 == "fired" { f = 1 } END { print (f ? "fired" : "not fired") }' "$f" 2>/dev/null)"
  [ -n "$LF_FIRE" ] || LF_FIRE="not fired"
}

# OUT REPO -> "ended" when the run whose files are OUT.out and OUT.err, with status LF_RC, ended as C3 says felix lane
# ends a count that cannot finish: status 1, nothing on stdout, felix: the lane count did not finish in REPO on stderr.
_lf_ended() {
  local e
  e="$(LC_ALL=C awk -v w="felix: the lane count did not finish in $2" '$0 == w { f = 1 } END { print (f ? "line" : "none") }' "$1.err" 2>/dev/null)"
  if [ "$LF_RC" = 1 ] && [ ! -s "$1.out" ] && [ "$e" = line ]; then printf ended; else printf 'not ended'; fi
}

# DIR NOW -> the review's six landings on the branch DIR stands on: NOW - 20 days marked cap (engine/old.sh); NOW - 5
# and - 4 days unmarked (engine/a.sh, engine/b.sh); NOW - 3 days marked sec (docs/x.md); NOW - 2 and - 1 days unmarked
# (docs/y.md, docs/z.md). Then refs/remotes/origin/main names the last; LF_SHA it.
_lf_r2land() {
  local d="$1" n="$2"
  _lf_commit "$d" $((n - 20 * 86400)) $'engine: old\n\nFelix-Lane: cap\n' engine/old.sh || return 1
  _lf_commit "$d" $((n - 5 * 86400)) $'engine: a\n\nNo mark.\n' engine/a.sh || return 1
  _lf_commit "$d" $((n - 4 * 86400)) $'engine: b\n\nNo mark.\n' engine/b.sh || return 1
  _lf_commit "$d" $((n - 3 * 86400)) $'docs: x\n\nFelix-Lane: sec\n' docs/x.md || return 1
  _lf_commit "$d" $((n - 2 * 86400)) $'docs: y\n' docs/y.md || return 1
  _lf_commit "$d" $((n - 86400)) $'docs: z\n' docs/z.md || return 1
  _lf_publish "$d" || { LF_SHA=""; return 1; }
}

# DIR P NOW -> the review's home-apart fixture in DIR (made when missing; it must hold no home or c yet): a home DIR/home
# holding P (root at NOW - 40 days), lanes.tsv (cap ^engine/ 1/2 14, sec ^docs/ 1/2 7) committed at NOW - 29 days and
# lane-next.tsv (cap: cap next item, sec: sec next item) a minute later; a checkout DIR/c bound to P and P's own (_lf_own,
# remote_match o/r), its root at NOW - 30 days, then _lf_r2land's landings. Sets LF_HOME, LF_PROJ, LF_REPO, LF_R2T (the
# lanes.tsv commit), LF_R2A and LF_R2B (cap zero 0 2 and sec short 1 3, the lines felix lane --tsv prints at NOW),
# LF_R2AU and LF_R2BU (the same with next unknown) and LF_R2 (the two, a newline between); status 1 and LF_R2 empty
# when the fixture is not as named.
_lf_r2() {
  local d="$1" p="$2" n="$3" r c a
  LF_R2=""; LF_R2A=""; LF_R2B=""; LF_R2AU=""; LF_R2BU=""; LF_R2T=""
  mkdir -p "$d" && [ ! -e "$d/home" ] && [ ! -e "$d/c" ] || return 1
  _lf_home "$d/home" "$p" $((n - 40 * 86400)) || return 1
  _lf_table "$LF_PROJ" $((n - 29 * 86400)) lanes.tsv $'cap\t^engine/\t1/2\t14\nsec\t^docs/\t1/2\t7\n' || return 1
  LF_R2T="$LF_SHA"
  _lf_table "$LF_PROJ" $((n - 29 * 86400 + 60)) lane-next.tsv $'cap\tcap next item\nsec\tsec next item\n' || return 1
  _lf_checkout "$d/c" "$p" $((n - 30 * 86400)) && _lf_own "$LF_PROJ" "$LF_REPO" o/r && _lf_r2land "$LF_REPO" "$n" || return 1
  a="$((n - 86400)):1 $((n - 2 * 86400)):1 $((n - 3 * 86400)):1 $((n - 4 * 86400)):1 $((n - 5 * 86400)):1"
  [ "$(_lf_spine "$LF_REPO")" = "$a $((n - 20 * 86400)):1 $((n - 30 * 86400)):0" ] || return 1
  r="$(_lf_iso $((n - 86400)))"; c="$(_lf_iso $((n - 29 * 86400)))"
  a="$(_lf_iso $((n - 20 * 86400)))"
  LF_R2A="$(_lf_tsv cap zero 0 2 14 1/2 "$a" 'Felix-Lane: cap' 'cap next item' "$LF_R2T" "$c" "$r" -)"
  LF_R2AU="$(_lf_tsv cap zero 0 2 14 1/2 "$a" 'Felix-Lane: cap' unknown "$LF_R2T" "$c" "$r" -)"
  a="$(_lf_iso $((n - 3 * 86400)))"
  LF_R2B="$(_lf_tsv sec short 1 3 7 1/2 "$a" 'Felix-Lane: sec' 'sec next item' "$LF_R2T" "$c" "$r" -)"
  LF_R2BU="$(_lf_tsv sec short 1 3 7 1/2 "$a" 'Felix-Lane: sec' unknown "$LF_R2T" "$c" "$r" -)"
  LF_R2="$LF_R2A"$'\n'"$LF_R2B"
}

# DIR P NOW -> R3-F1's home-apart fixture in DIR (made when missing; it must hold no home or c yet): _lf_r2's, but with
# lanes.tsv holding sec (^docs/ 1/2 7) before cap (^engine/ 1/2 14), so the first lane is short. A home DIR/home holding
# P (root at NOW - 40 days), lanes.tsv committed at NOW - 29 days and lane-next.tsv (cap: cap next item, sec: sec next
# item) a minute later; a checkout DIR/c bound to P by .felix and P's own (_lf_own, remote_match o/r), its root at NOW -
# 30 days, then _lf_r2land's landings, sec's mark on the one three days back and cap's on the one twenty days back. Sets
# LF_HOME, LF_PROJ, LF_REPO, LF_R3T (the lanes.tsv commit) and LF_R3, the two lines felix lane --tsv prints at NOW, a
# newline between: sec short 1 3, its last lane landing NOW - 3 days, then cap zero 0 2, NOW - 20 days. Status 1 and
# LF_R3 empty when the fixture is not as named.
_lf_r3() {
  local d="$1" p="$2" n="$3" r c a
  LF_R3=""; LF_R3T=""
  mkdir -p "$d" && [ ! -e "$d/home" ] && [ ! -e "$d/c" ] || return 1
  _lf_home "$d/home" "$p" $((n - 40 * 86400)) || return 1
  _lf_table "$LF_PROJ" $((n - 29 * 86400)) lanes.tsv $'sec\t^docs/\t1/2\t7\ncap\t^engine/\t1/2\t14\n' || return 1
  LF_R3T="$LF_SHA"
  _lf_table "$LF_PROJ" $((n - 29 * 86400 + 60)) lane-next.tsv $'cap\tcap next item\nsec\tsec next item\n' || return 1
  _lf_checkout "$d/c" "$p" $((n - 30 * 86400)) && _lf_own "$LF_PROJ" "$LF_REPO" o/r && _lf_r2land "$LF_REPO" "$n" || return 1
  [ -f "$LF_REPO/.felix" ] || return 1
  a="$((n - 86400)):1 $((n - 2 * 86400)):1 $((n - 3 * 86400)):1 $((n - 4 * 86400)):1 $((n - 5 * 86400)):1"
  [ "$(_lf_spine "$LF_REPO")" = "$a $((n - 20 * 86400)):1 $((n - 30 * 86400)):0" ] || return 1
  [ "$(_lf_marks "$LF_REPO" 'refs/remotes/origin/main~2' sec)|$(_lf_marks "$LF_REPO" 'refs/remotes/origin/main~5' cap)" = "1|1" ] || return 1
  r="$(_lf_iso $((n - 86400)))"; c="$(_lf_iso $((n - 29 * 86400)))"
  a="$(_lf_tsv cap zero 0 2 14 1/2 "$(_lf_iso $((n - 20 * 86400)))" 'Felix-Lane: cap' 'cap next item' "$LF_R3T" "$c" "$r" -)"
  LF_R3="$(_lf_tsv sec short 1 3 7 1/2 "$(_lf_iso $((n - 3 * 86400)))" 'Felix-Lane: sec' 'sec next item' "$LF_R3T" "$c" "$r" -)"$'\n'"$a"
}

# -> the bash program of R3-F1's fault, for /bin/bash -c PROGRAM N CMD...: it closes every descriptor from 3 to 63 it
# inherited, so that CMD starts with 0, 1 and 2 alone whatever the suite holds open, sets the soft open-file limit to N
# (ulimit -S -n N; status 124 when it cannot), writes "limit <the soft limit it reads back>" to stderr, and execs CMD.
# The line is written by an external printf (env printf): a builtin's redirection needs bash to save the descriptor at
# 10 or above, which a limit of 10 or less refuses, leaving stdout on stderr. Given as _lf_run's CMD it is the shell that
# execs felix: _lf_run OUT DIR NOW TMPDIR=T /bin/bash -c "$(_lf_nfprog)" N "$FELIX" lane --tsv.
_lf_nfprog() {
  printf '%s' 'i=3; while [ "$i" -lt 64 ]; do eval "exec $i>&-"; i=$((i + 1)); done; ulimit -S -n "$0" || exit 124; env printf "limit %s\n" "$(ulimit -S -n)" >&2; exec "$@"'
}

# DIR N T -> an engine root at DIR (made when missing) whose harness/hooks/session-start is a bash script that exports
# TMPDIR T and CLAUDE_PLUGIN_ROOT $FROOT, then execs /bin/bash -c "$(_lf_nfprog)" N $FROOT/harness/hooks/session-start,
# so that _lf_start OUT DIR NOW SOURCE LF_LROOT runs the suite's hook under R3-F1's soft open-file limit N, set in the
# shell that execs it. Sets LF_LROOT, DIR's physical path; status 1 and LF_LROOT empty when it cannot be made.
_lf_lroot() {
  LF_LROOT=""
  [ -n "${2-}" ] && [ -n "${3-}" ] && mkdir -p "$1/harness/hooks" || return 1
  { printf '#!/bin/bash\n# R3-F1: the suite'"'"'s hook under a soft open-file limit of %s.\n' "$2"
    printf 'export TMPDIR=%q CLAUDE_PLUGIN_ROOT=%q\n' "$3" "$FROOT"
    printf 'exec /bin/bash -c %q %q %q\n' "$(_lf_nfprog)" "$2" "$FROOT/harness/hooks/session-start"; } > "$1/harness/hooks/session-start" \
    && chmod +x "$1/harness/hooks/session-start" || return 1
  LF_LROOT="$(cd -P -- "$1" && pwd -P)"
}

# Design item 46 (2026-10-30, still blind). REPO HOME P LAYOUT -> REPO, a repository whose project P lives in
# HOME/projects/P, bound or not as LAYOUT names (C2: a valid marker naming a project directory, else the one longest
# remote_match naming the origin, none on a tie; a marker that cannot be opened names nothing). P's project.json is
# written as _lf_match writes it, remote_match o/r. Each layout first removes REPO's .felix, whatever its mode, its origin
# remote and HOME/projects/P2 (P followed by 2), then: felix, .felix holding P and no origin (bound by its marker alone);
# remote, no .felix and origin https://github.com/o/r.git (bound by remote_match alone); none, neither; other, no .felix
# and origin https://github.com/x/y.git, which no remote_match names; tie, as remote, with HOME/projects/P2 beside P
# (CLAUDE.md, and project.json with remote_match o/r), two projects naming the origin equally; nosuch, .felix holding
# nosuch, a project HOME does not hold, no origin; empty, .felix of no bytes, no origin; closed, .felix holding P with
# mode 000, no origin. The origin is removed as a config section only, so refs/remotes/origin/main stays, and is checked
# to name what it named before. LF_BOUND "built" when REPO and HOME stand as LAYOUT names, read back (closed: only when
# the marker cannot be opened, so never when the suite runs as root), else "not built: <what differs>"; status 1 then.
_lf_bind() {
  local r="$1" h="$2" p="$3" l="$4" u="" m="" g o
  LF_BOUND="not built: layout $l"
  [ -n "$r" ] && [ -d "$r" ] && [ -n "$p" ] && [ -d "$h/projects/$p" ] || return 1
  case "$l" in
    (felix|closed) m="$p" ;; (nosuch) m=nosuch ;; (empty|none) ;;
    (remote|tie) u=https://github.com/o/r.git ;; (other) u=https://github.com/x/y.git ;; (*) return 1 ;;
  esac
  o="$( _fx_cd "$r" && _lf_g 1700000000 rev-parse --verify -q refs/remotes/origin/main )"
  rm -f "$r/.felix"; rm -rf "$h/projects/${p}2"
  ( _fx_cd "$r" || exit 1
    if _lf_g 1700000000 config --get remote.origin.url; then _lf_g 1700000000 config --remove-section remote.origin || exit 1; fi ) >/dev/null 2>&1 || return 1
  _lf_match "$h/projects/$p" o/r || return 1
  case "$l" in (felix|closed|nosuch) printf '%s\n' "$m" > "$r/.felix" || return 1 ;; (empty) : > "$r/.felix" || return 1 ;; esac
  [ -z "$u" ] || _lf_origin "$r" "$u" || return 1
  if [ "$l" = tie ]; then
    mkdir -p "$h/projects/${p}2" && printf '# %s2\n' "$p" > "$h/projects/${p}2/CLAUDE.md" && _lf_match "$h/projects/${p}2" o/r || return 1
  fi
  [ "$l" != closed ] || chmod 000 "$r/.felix" || return 1
  g="$( _fx_cd "$r" && _lf_g 1700000000 config --get remote.origin.url )"
  [ "$g" = "$u" ] || { LF_BOUND="not built: layout $l, origin [$g]"; return 1; }
  g="$( _fx_cd "$r" && _lf_g 1700000000 rev-parse --verify -q refs/remotes/origin/main )"
  [ "$g" = "$o" ] || { LF_BOUND="not built: layout $l, refs/remotes/origin/main [$g], before [$o]"; return 1; }
  case "$l" in
    (felix|nosuch) [ "$(LC_ALL=C awk '{ printf "%s|", $0 }' "$r/.felix" 2>/dev/null)" = "$m|" ] ;;
    (empty) [ -f "$r/.felix" ] && [ ! -s "$r/.felix" ] ;;
    (closed) [ -f "$r/.felix" ] && ! ( : < "$r/.felix" ) 2>/dev/null ;;
    (*) [ ! -e "$r/.felix" ] && [ ! -L "$r/.felix" ] ;;
  esac || { LF_BOUND="not built: layout $l, the marker"; return 1; }
  [ -n "$(LC_ALL=C awk '/"remote_match":"o\/r"/' "$h/projects/$p/project.json" 2>/dev/null)" ] || { LF_BOUND="not built: layout $l, $p's remote_match"; return 1; }
  if [ "$l" = tie ]; then [ -n "$(LC_ALL=C awk '/"remote_match":"o\/r"/' "$h/projects/${p}2/project.json" 2>/dev/null)" ]
  else [ ! -e "$h/projects/${p}2" ]; fi || { LF_BOUND="not built: layout $l, project ${p}2"; return 1; }
  LF_BOUND=built
}

# Design item 46 (2026-10-30, still blind). MODE NAME WORDS STACK FILE TMPDIR CMD... -> CMD run as _lf_fork (MODE fork)
# or _lf_kill (MODE kill) runs it, NAME (tr or git) the bash function exported into felix, acting every time " $* "
# matches the case pattern WORDS and " ${FUNCNAME[*]} " the case pattern STACK. It writes "fired" to FILE; then, S being
# the shell that called it, P that shell's parent and M the bash that runs it ($$ there: felix itself, for a function
# felix calls), fork writes "fork S M", lowers the soft process limit to 1 in that shell and runs NAME, then writes "ran
# <status>" if the shell gets there; kill writes "kill P S M" and sends SIGKILL to P, then S (never to pid 1 or this
# suite's shell: it writes "kept" and runs NAME). LF_RC as _lf_fault's; LF_FIRE "fired" when it acted as MODE says (fork:
# NAME did not run to a clean exit after it); LF_SELF "self" when it acted in felix's own shell (fork: S is M) or sent
# felix itself a kill (P or S is M), where C3 and C9 say felix ends (128 or 137), else "apart".
_lf_probe() {
  local m="$1" n="$2" w="$3" k="$4" f="$5" t="$6" c a b
  shift 6
  LF_FIRE="not run"; LF_SELF="not run"; LF_RC=125
  case "$f$t" in (*\"*|*\'*|*\$*|*\`*|*\\*|*\&*) return 1 ;; esac
  [ -n "$f" ] && [ -n "$t" ] && [ -n "$w" ] && [ -n "$k" ] || return 1
  case "$n" in (tr|git) c="command $n" ;; (*) return 1 ;; esac
  case "$m" in
    (fork) a="printf 'fork %s %s\\n' \"\$s\" \"\$\$\" >> '$f'; ulimit -S -u 1; $c \"\$@\"; r=\$?; printf 'ran %s\\n' \"\$r\" >> '$f'; return \"\$r\"" ;;
    (kill) a="p=\"\$(ps -o ppid= -p \"\$s\" 2>/dev/null)\"; p=\"\${p//[!0123456789]/}\"
      case \"\$s:\$p\" in (:*|*:|1:*|*:1|$$:*|*:$$) printf 'kept %s %s\\n' \"\$p\" \"\$s\" >> '$f' ;;
        (*) printf 'kill %s %s %s\\n' \"\$p\" \"\$s\" \"\$\$\" >> '$f'; kill -KILL \"\$p\"; kill -KILL \"\$s\" ;; esac; $c \"\$@\"; return" ;;
    (*) return 1 ;;
  esac
  b="$n() { local s p r; case \" \$* \" in ($w) case \" \${FUNCNAME[*]} \" in ($k) printf 'fired\\n' >> '$f'
    s=\"\$(exec sh -c 'echo \$PPID')\"; $a ;; esac ;; esac; $c \"\$@\"; }"
  rm -f "$f" "$f.shell"
  { ( TMPDIR="$t"; export TMPDIR
      eval "$b" || exit 125
      export -f "$n"
      "$@"
      exit "$LF_RC" ); } 2> "$f.shell"
  LF_RC=$?
  LF_FIRE="$(LC_ALL=C awk -v m="$m" '$0 == "fired" { f = 1 } $0 == "ran 0" { r = 1 } /^kill [0123456789]+ [0123456789]+ [0123456789]+$/ { k = 1 }
    /^fork [0123456789]+ [0123456789]+$/ { o = 1 } /^kept / { p = $0 }
    END { s = "not fired"
      if (m == "fork" && f) s = (o && !r) ? "fired" : "fired, but it ran to a clean exit after it"
      if (m == "kill" && f) s = k ? "fired" : "fired, but no kill was sent [" p "]"
      print s }' "$f" 2>/dev/null)"
  LF_SELF="$(LC_ALL=C awk '($1 == "fork" && NF == 3 && $2 == $3) || ($1 == "kill" && NF == 4 && ($2 == $4 || $3 == $4)) { s = 1 }
    END { print (s ? "self" : "apart") }' "$f" 2>/dev/null)"
  [ -n "$LF_FIRE" ] || LF_FIRE="not fired"
  [ -n "$LF_SELF" ] || LF_SELF=apart
}

# Design item 46 (2026-10-30, still blind). OUT DIR -> what felix lane said of DIR's resolution (C5), in the run whose
# files are OUT.out and OUT.err, with status LF_RC: "unresolved" when it exited 2 with nothing on stdout and the first
# line of its stderr is exactly felix: the project that governs DIR could not be resolved: a read it stands on did not
# finish.; "ungoverned" when the same with the line felix: no project governs DIR.; else its status, stdout and the first
# line of its stderr.
_lf_said() {
  local e
  e="$(LC_ALL=C awk 'NR == 1' "$1.err" 2>/dev/null)"
  if [ "$LF_RC" = 2 ] && [ ! -s "$1.out" ]; then
    case "$e" in
      ("felix: the project that governs $2 could not be resolved: a read it stands on did not finish.") printf unresolved; return 0 ;;
      ("felix: no project governs $2.") printf ungoverned; return 0 ;;
    esac
  fi
  printf 'status %s, stdout [%s], stderr [%s]' "$LF_RC" "$(cat "$1.out" 2>/dev/null)" "$e"
}

# LANE -> "none" when the last _lf_start put neither a lane paragraph (C7) for LANE in the context nor a lane token on
# the screen line, else what it found.
_lf_silent() {
  local w=""
  case "$LF_CTX" in *"Lane $1 is "*|*"first open lane item"*) w="paragraph" ;; esac
  case "$LF_SCR" in *" · lane: "*) w="${w:+$w and }token" ;; esac
  printf '%s' "${w:-none}"
}

# EPOCH -> that instant as YYYY-MM-DDTHH:MM:SSZ (UTC).
_lf_iso() { date -u -r "$1" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$1" +%Y-%m-%dT%H:%M:%SZ; }

# WORD... -> the words joined by tabs, as one TSV line with no newline.
_lf_tsv() { local IFS="$(printf '\t')"; printf '%s' "$*"; }

# FILE LINE COL... -> those tab-separated columns of line LINE of FILE, joined by |; nothing when there is no such line.
_lf_cols() {
  local f="$1" l="$2"
  shift 2
  LC_ALL=C awk -F'\t' -v l="$l" -v c="$*" 'NR == l { n = split(c, k, " "); for (i = 1; i <= n; i++) printf "%s%s", (i > 1 ? "|" : ""), $(k[i]) }' "$f" 2>/dev/null
}

# FILE -> its last line. _lf_count FILE -> its number of lines (a last line with no newline counts).
_lf_last() { LC_ALL=C awk '{ l = $0 } END { printf "%s", l }' "$1" 2>/dev/null; }
_lf_count() { LC_ALL=C awk 'END { print NR }' "$1" 2>/dev/null; }

# DIR -> the first-parent chain of refs/remotes/origin/main in DIR, newest first, as "<committer time>:<parents>" words.
_lf_spine() {
  ( _fx_cd "$1" || exit 1; _lf_g 1700000000 log --first-parent --format='%ct %P' refs/remotes/origin/main ) 2>/dev/null \
    | LC_ALL=C awk '{ printf "%s%s:%d", (NR > 1 ? " " : ""), $1, NF - 1 }'
}

# DIR COMMIT LANE -> how many lines of COMMIT's message are, byte for byte, Felix-Lane: LANE.
_lf_marks() {
  local f
  f="$(mktemp "$TMP/lf-marks.XXXXXX")" || return 1
  ( _fx_cd "$1" || exit 1; _lf_g 1700000000 cat-file commit "$2" ) > "$f" 2>/dev/null
  LC_ALL=C awk -v m="Felix-Lane: $3" 'b && $0 == m { n++ } $0 == "" { b = 1 } END { print n + 0 }' "$f"
  rm -f "$f"
}

# DIR REV -> removes the loose object REV names from DIR/.git/objects; 0 when it was loose and is gone.
_lf_unobject() {
  local h
  h="$( _fx_cd "$1" || exit 1; _lf_g 1700000000 rev-parse --verify -q "$2" )" || return 1
  case "$h" in ????????????????????????????????????????) ;; *) return 1 ;; esac
  [ -f "$1/.git/objects/${h%"${h#??}"}/${h#??}" ] || return 1
  rm -f "$1/.git/objects/${h%"${h#??}"}/${h#??}"
  [ ! -e "$1/.git/objects/${h%"${h#??}"}/${h#??}" ]
}
