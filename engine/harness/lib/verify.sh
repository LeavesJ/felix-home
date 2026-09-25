# Verification receipts.
#
# The guidebook's central rule is that an agent must never declare a task
# complete while a required deterministic verification step is failing. Felix
# has had the verification step since the beginning; what it lacked was anything
# that noticed when the step had not run. `felix gate` was a command an agent
# could simply not choose.
#
# The mechanism is a receipt rather than a re-run. Re-running the gate at the
# moment someone tries to finish would cost a full test suite every time, which
# on a real project means the hook gets removed, and a removed hook enforces
# nothing. A receipt costs a diff and two small files.
#
# A receipt also answers the question a re-run cannot. Re-running says "the gate
# passes now". The receipt says "this exact tree has been verified", which is a
# different claim, and the common failure is not a red gate but a gate nobody
# ran. A re-run silently converts that failure into a pass.
#
# Dependencies stay bash and git. `git hash-object --stdin` is used rather than
# shasum or sha1sum because those differ across platforms and git is already
# required.

# Chooses HOW the untracked files' metadata is read, never WHAT the tree id is
# (U2, G2.3). At or below it, one `stat` over an argument list; above it, the
# sorted list streamed through `xargs`, which batches under ARG_MAX by itself.
# It used to choose what: above it the id was a count of untracked files, so an
# edit that kept the count kept the id, and a green receipt stayed current over
# work the gate never saw.
#
# Read from the environment, and felix_tree_id never lets it past 500. One
# argument list of more paths than that can pass ARG_MAX (1 MB on macOS, with
# the environment inside it), and then the one `stat` never runs, the metadata
# is empty, and every untracked edit is hidden exactly as the count hid it. So
# a raised value, or one that is not a number, reads as 500, a lower one only
# moves more trees onto the stream, and every value gives the same id.
FELIX_UNTRACKED_CAP="${FELIX_UNTRACKED_CAP:-500}"

_felix_hash() { git hash-object --stdin 2>/dev/null; }

_felix_now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# Size and mtime for one file, portably.
#
# GNU must be probed first. `stat -f` on GNU means --file-system, so it succeeds
# with entirely unrelated output rather than failing, and a BSD-first probe would
# silently return filesystem statistics for every file on Linux.
_FELIX_STAT=""
_felix_stat_mode() {
  [ -n "$_FELIX_STAT" ] && return 0
  if stat -c '%s' /dev/null >/dev/null 2>&1; then _FELIX_STAT=gnu
  elif stat -f '%z' /dev/null >/dev/null 2>&1; then _FELIX_STAT=bsd
  else _FELIX_STAT=none; fi
}
# Every path in one call, not one call per path.
#
# The first version asked for metadata per file from inside a command
# substitution, which is a subshell, so the capability probe above never cached:
# each file cost three `stat` processes rather than one. On a repository with a
# couple of untracked backup directories that was 510 spawns and close to two
# seconds on every attempt to finish. Both stat implementations accept many
# paths at once, so this is one process regardless of count.
_felix_meta_all() {
  _felix_stat_mode
  case "$_FELIX_STAT" in
    gnu) stat -c '%n %s %Y' "$@" 2>/dev/null ;;
    bsd) stat -f '%N %z %m' "$@" 2>/dev/null ;;
    *)   printf '%s\n' "$@" ;;
  esac
}

# The same bytes as _felix_meta_all over "$root/<each path>", for a list too long
# for one argument list: at 50,000 files building the array cost 2.8 s of shell
# CPU and the one `stat` printed nothing, since the list is over ARG_MAX, so
# raising the cap was never a fix (U2, G2.3). The list is the one already taken
# for the count, so the files counted and the files read are one set, and the
# tree is walked once.
#
# `stat` runs on paths relative to the root and the root is put back after,
# because every absolute lookup walks the root again (3.5 times the CPU at 5,000
# files). The root never goes into a format string: BSD `stat -f` reads `%t` as
# a tab and `%n` as a newline, and `%%` does not survive every root. It reaches
# awk through the environment, since `awk -v` would read its backslashes.
#
# Each path reaches `stat` as `./<path>`, and awk takes the two characters off
# again. A bare relative path that starts with `-` is an option to `stat`: on
# BSD `-x` or `--help` prints the usage and nothing else for the whole batch,
# up to thousands of files, and `-f` takes the next path as its format; GNU
# getopt reads a `-` name anywhere in the batch that way, and GNU `stat` reads
# a lone `-` as its standard input, which `--` would not stop. The metadata
# came back empty and the id blind to every untracked edit, U2 again, for any
# tree with an untracked top-level `-notes.md`. The array path never met it,
# because its paths begin with the root.
#
# The C locale for all of it: `tr` on macOS stops at the first byte that is not
# UTF-8 in any other, and a name git lists as it is on disk may hold one on
# Linux.
#
# Only reached with a non-empty list: GNU xargs runs its command once on empty
# input, and `stat` with no operand is an error, not an empty answer.
_felix_meta_stream() {   # root, untracked paths relative to it, one per line
  local root="$1" list="$2"
  _felix_stat_mode
  ( cd "$root" >/dev/null 2>&1 || exit 0
    export LC_ALL=C
    printf '%s\n' "$list" | sed 's|^|./|' | tr '\n' '\0' \
      | case "$_FELIX_STAT" in
          gnu) xargs -0 stat -c '%n %s %Y' 2>/dev/null ;;
          bsd) xargs -0 stat -f '%N %z %m' 2>/dev/null ;;
          *)   tr '\0' '\n' ;;
        esac \
      | _FELIX_META_ROOT="$root/" awk '{ print ENVIRON["_FELIX_META_ROOT"] substr($0, 3) }' )
}

# The HEAD a session began at.
#
# Stop needs to tell "this session changed something" from "this tree happens to
# be clean", and those come apart the instant anybody commits — which is what
# you do at the end, so the sessions that finished properly were the ones never
# asked to verify anything. Dirtiness cannot answer it; only a mark from the
# start of the session can.
#
# Best effort throughout. No session id, no writable home: no record, and Stop
# falls back to its old behaviour rather than starting to block trees it has
# nothing to say about.
#
# An unborn HEAD is marked too (U3). It used to be "no git" here, so a session
# that made a repository's first commit, on `git init` or an orphan branch, had
# no mark, found a clean tree at Stop, and was released unjudged over a gate
# that was red or had never run; one earlier commit and the same session was
# held. The mark is then `unborn<TAB><git common dir>`: the word tells Stop that
# any HEAD at all is a commit this session made, and the directory tells the
# ledger which repository the session ran in, since there is no commit yet for
# `git cat-file` to find (U4). The common directory, so every worktree of the
# repository owns it, as every checkout whose history holds a sha mark does.
#
# A governed directory that is not a git repository yet is marked `unborn` too,
# with no directory, since there is none to name. It used to get no mark, and
# a session that ran `git init` there and made the first commit over a red gate
# was released in silence, the same session U3 is about one step earlier. Stop
# still says nothing while there is no git, and the ledger reads an unborn
# mark with no directory as nobody's, as it always read no mark.
_felix_session_path() { printf '%s/state/session/%s' "$1" "$2"; }

felix_session_mark() {
  local home="$1" sid="$2" root="$3" head path gcd
  [ -n "$sid" ] && [ -n "$home" ] || return 0
  path="$(_felix_session_path "$home" "$sid")"
  # First mark wins; a compact must not reset it. Asked before any git call, so
  # every prompt after the first costs none.
  [ -f "$path" ] && return 0
  # `rev-parse HEAD` prints the literal HEAD when it fails, so its output is
  # thrown away with its status rather than tested for emptiness.
  head="$(git -C "$root" rev-parse -q --verify HEAD 2>/dev/null)" || head=""
  if [ -z "$head" ]; then
    gcd=""
    if git -C "$root" rev-parse --git-dir >/dev/null 2>&1; then
      # The suite sources this file alone; resolve.sh sources nothing, so no cycle.
      command -v felix_git_common_dir >/dev/null 2>&1 \
        || . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh" 2>/dev/null
      gcd="$(felix_git_common_dir "$root" 2>/dev/null)" || gcd=""
    fi
    head="unborn	$gcd"
  fi
  mkdir -p "$(dirname "$path")" 2>/dev/null || return 0
  printf '%s\n' "$head" > "$path" 2>/dev/null || true
}

# A session nobody in it typed into.
#
# The platform's summary request starts a session of its own and types into it
# (#264). The prompt hook records nothing for that, but the session still ends
# like any other, and nothing at its end knew it for one: Stop held it in a tree
# with unverified work and told the summarising model to run the gate, and a
# tool call made on that advice was folded into ledger.d at SessionEnd, the
# phantom back in the denominator. So the prompt hook leaves this marker in
# place of a record, and Stop and SessionEnd consult it first and do nothing at
# all for the session. SessionEnd takes it away. State under the home, never
# memory: it describes a session that is running, not one that happened.
#
# Honoured only while the session has no mark. Every prompt a person types
# marks the session and a summary request never does, so a marker beside a mark
# is not what it says, and the session is judged as it always was. A session
# can write its own state as easily as its code; this is the floor and not a
# wall, and forging the exemption takes removing the session's own mark too.
#
# No session id, no marker: the prompt hook still records nothing for the
# request, since what it may do with a prompt is the prompt's kind and not the
# id's, and Stop and SessionEnd keep their old behaviour for the session.
_felix_machine_path() { printf '%s/state/machine/%s' "$1" "$2"; }

felix_session_machine_mark() {   # home, sid
  local path
  [ -n "${1:-}" ] && [ -n "${2:-}" ] || return 0
  path="$(_felix_machine_path "$1" "$2")"
  mkdir -p "$(dirname "$path")" 2>/dev/null || return 0
  : > "$path" 2>/dev/null || true
}

felix_session_machine() {   # home, sid -> 0 when nobody in the session typed into it
  [ -n "${1:-}" ] && [ -n "${2:-}" ] || return 1
  [ -f "$(_felix_machine_path "$1" "$2")" ] || return 1
  [ ! -f "$(_felix_session_path "$1" "$2")" ]
}

felix_session_machine_clear() {   # home, sid
  local path
  [ -n "${1:-}" ] && [ -n "${2:-}" ] || return 0
  path="$(_felix_machine_path "$1" "$2")"
  [ -f "$path" ] || return 0
  rm -f "$path" 2>/dev/null || true
}

# Felix's own hold, written down so that Stop can tell its own chain from
# another hook's.
#
# The platform sets stop_hook_active on the stop that ends a turn a hook
# started, and Stop used to leave at the flag whoever had started it. Felix's
# own hold is one such start. An asyncRewake hook that exits 2 is another: its
# rewake arrives as a turn of its own with the flag already set, measured on
# Claude Code 2.1.260 and 2.1.280 for a Stop and a PostToolUse hook alike (a
# rewake folded into a running turn sets nothing, and a hook merely in flight
# sets nothing). security-guidance, which commissioning installs for every
# project, is such a hook. So the turn in which a model fixes what a background
# review found ended with no check and no record, however dirty the tree.
#
# The flag is now honoured at the one stop a hold of Felix's started. Stop
# marks each hold before it is made, the next flagged stop takes the mark away
# and ends there, and an unflagged stop, which begins a chain afresh, clears
# whatever is left. A flagged stop with no mark to take belongs to someone
# else's chain and is judged like any other stop. Every hold is followed by a
# stop Felix lets through, so it never holds twice in a row, and the
# platform's rule still holds for every chain of Felix's own.
#
# The id arrives in a payload, so a path built from it is checked first, and an
# id that cannot name a file reads as unknown: the flag ends the stop, as it
# always did. So does a record that cannot be taken away. Where state/held
# cannot be written, nothing here can be told apart, and every flagged stop
# ends at the flag as it did before any of this existed.
_felix_hold_path() {   # home, sid -> path, or 1 when the id cannot name a file
  [ -n "${1:-}" ] || return 1
  case "${2:-}" in ''|.|..|-*|*[!A-Za-z0-9._-]*) return 1 ;; esac
  [ "${#2}" -le 128 ] || return 1
  printf '%s/state/held/%s' "$1" "$2"
}

felix_hold_mark() {   # home, sid -> 0 when the hold is on record
  local path
  path="$(_felix_hold_path "${1:-}" "${2:-}")" || return 1
  mkdir -p "$(dirname "$path")" 2>/dev/null || return 1
  : > "$path" 2>/dev/null
}

# 0 when a hold of Felix's was on record, and it is taken away; 1 when none was;
# 2 when the id cannot say, or the record is still there after taking it.
felix_hold_take() {   # home, sid -> 0 | 1 | 2
  local path
  path="$(_felix_hold_path "${1:-}" "${2:-}")" || return 2
  [ -f "$path" ] || return 1
  rm -f "$path" 2>/dev/null
  [ ! -e "$path" ] || return 2
  return 0
}

felix_hold_clear() {   # home, sid
  local path
  path="$(_felix_hold_path "${1:-}" "${2:-}")" || return 0
  [ -f "$path" ] || return 0
  rm -f "$path" 2>/dev/null || true
}

# Did this session commit anything? Returns 1 when unknown, so the caller keeps
# whatever it did before rather than treating ignorance as a change.
#
# A session marked on an unborn HEAD committed when HEAD resolves now: before
# the mark there was no commit here at all, so whatever HEAD names was made
# since (U3). The directory in that mark is the ledger's and is not asked here,
# as a sha mark is not checked against the repository either.
felix_session_committed() {
  local home="$1" sid="$2" root="$3" start now
  [ -n "$sid" ] || return 1
  start="$(cat "$(_felix_session_path "$home" "$sid")" 2>/dev/null)" || return 1
  [ -n "$start" ] || return 1
  case "${start%%$'\n'*}" in
    unborn|unborn$'\t'*)
      git -C "$root" rev-parse -q --verify HEAD >/dev/null 2>&1
      return ;;
  esac
  now="$(git -C "$root" rev-parse HEAD 2>/dev/null)" || return 1
  [ -n "$now" ] && [ "$now" != "$start" ]
}

# Whether the session has a mark at all, which is when the question above has
# an answer. Stop and SubagentStop excuse the untracked .felix (U35) only then.
# A tree whose only change is that marker is clean, and a clean tree is judged
# by whether the session committed; with no mark that reads as "no", so the
# excuse released a session that had committed its code and left the marker
# out. Such a session is the fresh-repository one: its first prompt came before
# `felix new` bound the checkout, which the prompt hook does not mark, and the
# marker it was holding on was the only thing still holding it. Without a mark
# the marker is dirt, as it was before the excuse existed. Checked on the file
# alone, with no git call.
felix_session_marked() {   # home, sid -> 0 when the session has a mark
  [ -n "${1:-}" ] && [ -n "${2:-}" ] || return 1
  [ -s "$(_felix_session_path "$1" "$2")" ]
}

# Does this tree hold anything the gate has not seen committed?
#
# Excludes Felix's own bookkeeping for the same reason tree identity does: a
# session that appended one line to a log has not changed the work, and treating
# it as dirty would demand a gate run for having recorded that a gate ran.
#
# The same goes for the marker `felix new` writes (U35). Until somebody commits
# it, `?? .felix` was the whole of the dirt in a freshly bound checkout, so a
# session that only asked a question was held with "the gate has never run", a
# red gate held every session after it, and every subagent was told no gate had
# passed. So an untracked root .felix is clean when it is the ONLY change and
# names the project that resolved, byte for byte, with or without one newline.
# Anything else is dirt as before: a second change, a staged or committed
# marker, a symlink, a stray byte, or a marker naming some other project. The
# caller passes the resolved project as the third argument, and without one
# nothing is exempt; Stop and SubagentStop pass it only for a session that has
# a mark (felix_session_marked says why). Only this check: felix_tree_id still
# counts the marker.
#
# `cmp` rather than a read: `$(cat)` strips every trailing newline and drops a
# NUL, and `read -d ''` stops at the first NUL, so `name\n\n` or `name<NUL>x`
# would pass. The file is read only when the status is exactly that one line.
felix_tree_dirty() {
  local root="$1" home="${2:-}" proj="${3:-}" f s name
  git -C "$root" rev-parse --git-dir >/dev/null 2>&1 || return 1
  local exargs=()
  while IFS= read -r f; do [ -n "$f" ] && exargs+=("$f"); done <<EOF
$(_felix_tree_excludes "$root" "$home")
EOF
  s="$(git -C "$root" status --porcelain -- . "${exargs[@]+"${exargs[@]}"}" 2>/dev/null)"
  [ -n "$s" ] || return 1
  [ "$s" = '?? .felix' ] && [ -n "$home" ] && [ -n "$proj" ] || return 0
  [ -f "$root/.felix" ] && [ ! -L "$root/.felix" ] || return 0
  name="${proj##*/}"
  # _felix_name_ok's rule, inline, because the suite sources this file alone.
  case "$name" in ''|.*|-*|*/*|*[!A-Za-z0-9._-]*) return 0 ;; esac
  [ "$proj" = "$home/projects/$name" ] && [ -d "$proj" ] || return 0
  # Under pipefail a `cmp` that stops early on a difference can leave printf a
  # SIGPIPE, which only turns a mismatch into another mismatch: a match reads
  # both inputs to the end.
  printf '%s\n' "$name" | cmp -s - "$root/.felix" && return 1
  printf '%s' "$name" | cmp -s - "$root/.felix" && return 1
  return 0
}

# Identity of a working tree: the commit it sits on, the content of every
# uncommitted change, and the presence of every untracked file.
#
# `git status --porcelain` alone was rejected. Two different edits to the same
# file produce byte-identical status output, so a receipt keyed on it stays valid
# across a change it never saw. The diff content has to be in the hash.
#
# Untracked file *contents* are deliberately not hashed. Felix governs projects
# in languages it does not know, and an untracked directory in one of them may be
# a virtualenv, a build output, or a multi-gigabyte model artifact. Hashing bytes
# would make this hook's cost a function of somebody else's project layout. Size
# and mtime both change on any write, which is sufficient, and cost one stat.
#
# Felix's own bookkeeping is excluded when Felix's home lives inside the tree
# being identified, which is the case whenever Felix governs itself. Writing a
# receipt is a change to the tree; without this, recording a verdict invalidates
# the verdict it just recorded and no receipt can ever be valid. The same goes
# for the verification log and the route log, which are records *about* the work
# rather than the work. When home is elsewhere — every governed project that is
# not Felix — nothing is excluded, so a project with its own `state/` keeps it.
#
# And every linked worktree of the repository that sits strictly under the
# root, whatever the home (G3.3). The desktop app, `claude --worktree`,
# EnterWorktree and subagent isolation all put a session's worktree at
# .claude/worktrees/<x> under the checkout, and to the checkout's git that is
# an untracked directory: unless something had written an info/exclude line
# for it, the main checkout read as dirty and its id moved with the metadata of
# the worktree's top entries, so a session that only asked a question in the
# main checkout was held for work a parallel session did in its own worktree.
# A worktree is another checkout's tree, never this one's. `literal`, because a
# worktree may be named `w[1]*`, and a glob exclude would take a plain
# directory beside it out as well. A plain directory at the same place is still
# this tree's (see _felix_tree_worktrees), and the root is never excluded from
# itself. Printed before the home's lines, so a tree with no home still gets it.
_felix_tree_excludes() {
  local root="$1" home="${2:-}" rel
  _felix_tree_worktrees "$root" ':(exclude,literal)'
  [ -n "$home" ] || return 0
  case "$home" in
    "$root")   rel="" ;;
    "$root"/*) rel="${home#"$root"/}/" ;;
    *)         return 0 ;;
  esac
  printf ':(exclude)%sstate/**\n'                 "$rel"
  printf ':(exclude)%sprojects/*/memory/*.log\n'  "$rel"
  printf ':(exclude)%sprojects/*/maintenance.log\n' "$rel"
}

# The linked worktrees of the repository whose physical path is strictly under
# the root, relative to it, one per line, each after the prefix given (G3.3).
#
# Read from the files git keeps rather than asked of git, because this runs on
# every Stop, twice (the dirty check and the id), and `git worktree list` there
# measured 17 ms a call against 7 for reading 65 records. A repository with no
# linked worktree has no <common>/worktrees, and costs two `[ -d ]` tests and no
# process; that is every fixture the suite's CPU-timed assertions use. The
# common dir is found the way git finds it: `.git` is the directory, or a file
# `gitdir: <g>`, whose `commondir` names the common dir relative to <g>, and a
# <g> with no `commondir` (a submodule, a --separate-git-dir) is its own. Each
# <common>/worktrees/<id>/gitdir holds the absolute path of that worktree's
# `.git` file, and git records it as the real path, even for a worktree added
# through a symlink to the checkout, so it compares with the root, which
# felix_repo_root takes with `pwd -P`.
#
# Git answers instead whenever those files are not in that form: a relative
# record (`worktree.useRelativePaths`, `--relative-paths`), a `.git` file that
# does not start `gitdir: `, a record that cannot be read. Its paths are
# resolved physically in one subshell, `cd -P` and `$PWD`, with no process per
# entry. A record that resolves nowhere under the root is not named, which
# fails toward dirt, as before this existed, and never toward a false green.
#
# A record is named only while `<path>/.git` is a file. A worktree whose
# directory was deleted without `git worktree prune` leaves its record, and a
# plain directory created later at that path is this tree's untracked content;
# a stale record must never hide it. No cache: the library stays stateless.
_felix_tree_worktrees() {
  local root="$1" pre="${2:-}" line="" g="" c="" common="" f="" p="" w="" out="" need=0
  if [ -d "$root/.git" ]; then
    common="$root/.git"
  elif [ -f "$root/.git" ]; then
    IFS= read -r line 2>/dev/null < "$root/.git" || [ -n "$line" ] || need=1
    case "$line" in
      "gitdir: "?*) g="${line#gitdir: }" ;;
      *)            need=1 ;;
    esac
    case "$g" in /*|'') ;; *) g="$root/$g" ;; esac
    common="$g"
    if [ "$need" -eq 0 ] && [ -f "$g/commondir" ]; then
      IFS= read -r c 2>/dev/null < "$g/commondir" || [ -n "$c" ] || need=1
      case "$c" in /*) common="$c" ;; ?*) common="$g/$c" ;; *) need=1 ;; esac
    fi
  else
    need=1
  fi
  if [ "$need" -eq 0 ]; then
    [ -d "$common/worktrees" ] || return 0
    for f in "$common"/worktrees/*/gitdir; do
      [ -f "$f" ] || continue
      p=""
      IFS= read -r p 2>/dev/null < "$f" || [ -n "$p" ] || { need=1; break; }
      case "$p" in /*) ;; *) need=1; break ;; esac
      w="${p%/.git}"
      case "$w" in
        "$root"/*) [ -f "$w/.git" ] && out="$out$pre${w#"$root"/}
" ;;
      esac
    done
    if [ "$need" -eq 0 ]; then printf '%s' "$out"; return 0; fi
  fi
  git -C "$root" worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p' | (
    while IFS= read -r w; do
      cd -P "$w" >/dev/null 2>&1 || continue
      case "$PWD" in
        "$root"/*) [ -f "$PWD/.git" ] && printf '%s%s\n' "$pre" "${PWD#"$root"/}" ;;
      esac
    done )
  return 0
}

# A third argument, a directory, is where the gate asks for the parts of the
# id to compare two trees (G2.1, G1.7, G2.4, PR-B finding 8): `head`, `index`
# (the `ls-files -s` entries on an unborn HEAD, empty on a born one), `diff`
# (the worktree's diff, before the index is joined to it) and `meta` (the
# untracked files' metadata lines). Written from the very variables hashed, so
# felix_tree_moved compares what the id is made of and not a second reading
# of the tree that could disagree with it. The id is the same bytes with or
# without it, and with none given nothing new runs: no hook passes one. When
# this returns 1 the parts may be partial, and the caller does not read them.
felix_tree_id() {
  local root="$1" home="${2:-}" parts="${3:-}" head diff index="" wdiff untracked n cap meta="" f
  git -C "$root" rev-parse --git-dir >/dev/null 2>&1 || return 1
  local ex; ex="$(_felix_tree_excludes "$root" "$home")"
  local exargs=()
  while IFS= read -r f; do [ -n "$f" ] && exargs+=("$f"); done <<EOF
$ex
EOF

  head="$(git -C "$root" rev-parse HEAD 2>/dev/null)" || head=""
  if [ -z "$head" ]; then
    # An unborn HEAD has nothing to diff against. A repository with no commits is
    # a real state — it is what `git init` leaves, and what this suite's own
    # fixture is — and every naive implementation of this dies there.
    head="unborn"
    # The index is part of the identity here (U1). The diff below runs from the
    # index to the worktree, so a fully staged tree has none, and every fully
    # staged tree before the first commit hashed alike: a green receipt for
    # `exit 0` stayed current over a staged `exit 1`. The index entries carry
    # the staged object ids and the diff the worktree's departures from them,
    # so together they fix the content of every path the index knows.
    #
    # Not `git diff <empty tree>`, which mirrors the born branch but prints the
    # whole of every staged file: after `git init && git add -A` over an
    # existing codebase that is the codebase, twice per Stop (200-590 ms of CPU
    # at 3,000 files, growing with their size, against about 40 for this).
    # Unlike the born id, staging an edit changes this one; that can stale a
    # receipt, never make one current. An index git cannot read gives no id,
    # which Stop already reads as identity unavailable, never an id without it.
    # An empty index hashes exactly the bytes it always did.
    index="$(git -C "$root" ls-files -s -- . "${exargs[@]+"${exargs[@]}"}" 2>/dev/null)" || return 1
    diff="$(git -C "$root" diff -- . "${exargs[@]+"${exargs[@]}"}" 2>/dev/null)"
    wdiff="$diff"
    [ -z "$index" ] || diff="$index
$diff"
  else
    diff="$(git -C "$root" diff HEAD -- . "${exargs[@]+"${exargs[@]}"}" 2>/dev/null)"
    wdiff="$diff"
  fi

  # Listed as the names are on disk. Git's default quotes a name that is not
  # ASCII, `"donn\303\251es.py"`, which is no file `stat` can find, so it was in
  # neither reading of the metadata, and creating, editing or deleting it never
  # moved the id; before the first commit with nothing staged, that is every
  # such file in the tree. A name holding a tab, a newline, a double quote or a
  # backslash is quoted even so, and still unseen: reading those needs `-z`
  # through every step here, a larger change than names that rare have been
  # worth so far. Counted in the C locale, where every line of bytes is a line.
  # A tree whose untracked names are all ASCII keeps its id byte for byte.
  untracked="$(git -C "$root" -c core.quotePath=false ls-files --others --exclude-standard \
                 -- . "${exargs[@]+"${exargs[@]}"}" 2>/dev/null | LC_ALL=C sort)"
  n="$(printf '%s' "$untracked" | LC_ALL=C grep -c . 2>/dev/null)" || n=0

  # Never a count (U2, G2.3). Above the cap this was `coarse:` and the number
  # of untracked files, on the reasoning that such a repository had larger
  # problems than receipt precision. It had one larger problem, which was that
  # precision: an edit that kept the count kept the id, before the first commit
  # with nothing staged every file is untracked, and a gate that wrote its build
  # output tipped the tree over the line by itself. The cap now picks between
  # two readings of the same bytes. Measured as CPU per id: 64 ms at 600
  # untracked files and 127 ms at 5,000, against 44 and 51 for the count.
  #
  # The cap is never read above 500 (see FELIX_UNTRACKED_CAP): a raised one
  # sent 50,000 paths to one `stat`, over ARG_MAX, and the id came back as
  # HEAD and the diff alone. A value `[` cannot compare reads as 500 too.
  cap="${FELIX_UNTRACKED_CAP:-500}"
  [ "$cap" -le 500 ] 2>/dev/null || cap=500
  if [ "${n:-0}" -gt 0 ] && [ "$n" -gt "$cap" ] 2>/dev/null; then
    meta="$(_felix_meta_stream "$root" "$untracked")"
  elif [ "${n:-0}" -gt 0 ]; then
    local files=()
    while IFS= read -r f; do
      [ -n "$f" ] && files+=("$root/$f")
    done <<EOF
$untracked
EOF
    meta="$(_felix_meta_all "${files[@]}")"
  fi

  if [ -n "$parts" ] && [ -d "$parts" ]; then
    printf '%s' "$head"  2>/dev/null > "$parts/head"
    printf '%s' "$index" 2>/dev/null > "$parts/index"
    printf '%s' "$wdiff" 2>/dev/null > "$parts/diff"
    printf '%s' "$meta"  2>/dev/null > "$parts/meta"
  fi
  printf '%s' "$(printf '%s\n%s\n%s' "$head" "$diff" "$meta" | _felix_hash)"
}

# What moved between the tree a gate started on and the tree it left: two
# parts directories written by felix_tree_id, and the ownership manifest (G2.1,
# G1.7, G2.4, PR-B finding 8). One row per thing, `<class> TAB <path>`,
# unsorted; the caller sorts them in the C locale.
#
#   head     HEAD moved                                  (path: HEAD)
#   tracked  an index entry, or a diff section, appeared, disappeared or
#            changed                                     (the path it is for)
#   gate     an untracked file the run created; or one it rewrote or removed
#            while it was exactly as an earlier gate run left it
#   foreign  an untracked file rewritten or removed that no gate run left so
#
# The gate stamps the tree it left only when every row is `gate`. That rule is
# about who wrote the bytes, never what they are called: `lcov.info`,
# `__pycache__` and `target/` are also names a generated source can have, so
# no name decides anything. "Exactly as a gate left it" is the metadata line
# felix_tree_id hashes, `<root>/<path> <size> <mtime>`, byte for byte in the
# manifest, so an untracked file the session wrote and a gate later rewrote is
# foreign, and the gate is never current over bytes it did not run on.
#
# A part is compared with `cmp` first, and awk runs only for a part that
# differs. Every map lives in awk (bash 3.2 has none). `FILENAME == ARGV[1]`
# and never `FNR == NR`, which stays true through the second file whenever the
# first is empty, and any part or manifest here can be. The root reaches awk
# through the environment, since `awk -v` would read its backslashes. A meta
# key is its line with the trailing size and mtime taken off; in the `none`
# stat mode a line is only a path, so a rewrite shows nowhere, exactly as the
# id cannot see it either. The display name of a diff section is its header's
# path when the header is `a/P b/P`, and the header's text otherwise (a
# rename, a quoted name): it is for reading only, and nothing decides on it.
felix_tree_moved() {   # root, pre parts dir, post parts dir, [manifest]
  local root="$1" pre="$2" post="$3" own="${4:-}"
  [ -n "$own" ] && [ -f "$own" ] || own=/dev/null
  cmp -s "$pre/head" "$post/head" || printf 'head\tHEAD\n'
  if ! cmp -s "$pre/index" "$post/index"; then
    LC_ALL=C awk -F'\t' '
      { k = substr($0, index($0, "\t") + 1) }
      FILENAME == ARGV[1] { a[k] = a[k] "\n" $0; next }
      { b[k] = b[k] "\n" $0 }
      END { for (k in b) if (!(k in a) || a[k] != b[k]) print "tracked\t" k
            for (k in a) if (!(k in b)) print "tracked\t" k }' "$pre/index" "$post/index"
  fi
  if ! cmp -s "$pre/diff" "$post/diff"; then
    LC_ALL=C awk '
      function name(h,   s, n) {
        s = substr(h, 12); n = (length(s) - 5) / 2
        if (n == int(n) && n > 0 && substr(s, 1, 2) == "a/" && substr(s, n + 3, 3) == " b/" \
            && substr(s, 3, n) == substr(s, n + 6)) return substr(s, 3, n)
        return s
      }
      FNR == 1 { k = "" }
      /^diff --git / { k = $0 }
      FILENAME == ARGV[1] { if (k != "") a[k] = a[k] "\n" $0; next }
      { if (k != "") b[k] = b[k] "\n" $0 }
      END { for (k in b) if (!(k in a) || a[k] != b[k]) print "tracked\t" name(k)
            for (k in a) if (!(k in b)) print "tracked\t" name(k) }' "$pre/diff" "$post/diff"
  fi
  if ! cmp -s "$pre/meta" "$post/meta"; then
    _FELIX_MOVED_ROOT="$root/" LC_ALL=C awk '
      function key(l) { sub(/ [0-9]+ [0-9]+$/, "", l); return l }
      function rel(k,   r) { r = ENVIRON["_FELIX_MOVED_ROOT"]
                             return (index(k, r) == 1) ? substr(k, length(r) + 1) : k }
      FILENAME == ARGV[1] { own[$0] = 1; next }
      FILENAME == ARGV[2] { pre[key($0)] = $0; next }
      { post[key($0)] = $0 }
      END { for (k in post) if (!(k in pre)) print "gate\t" rel(k)
                            else if (pre[k] != post[k]) print ((pre[k] in own) ? "gate" : "foreign") "\t" rel(k)
            for (k in pre) if (!(k in post)) print ((pre[k] in own) ? "gate" : "foreign") "\t" rel(k) }' \
      "$own" "$pre/meta" "$post/meta"
  fi
  return 0
}

# The next ownership manifest, sorted in the C locale: every untracked file, as
# the run left it, whose bytes a gate run produced. That is a post-run line
# that is in the old manifest byte for byte (gate output nothing has touched
# since), or whose file the run created or rewrote. Rewrites the gate could not
# claim are included: after the run those bytes are its output, and leaving
# them out would make an artefact that existed before the first gate (the
# session ran its own tests) foreign on every run, holding forever instead of
# once. Removed files drop out. A stale line is harmless, since a match is
# exact, so nothing prunes it.
felix_tree_manifest() {   # root, pre parts dir, post parts dir, [old manifest]
  local own="${4:-}"
  [ -n "$own" ] && [ -f "$own" ] || own=/dev/null
  LC_ALL=C awk '
    function key(l) { sub(/ [0-9]+ [0-9]+$/, "", l); return l }
    FILENAME == ARGV[1] { own[$0] = 1; next }
    FILENAME == ARGV[2] { pre[key($0)] = $0; next }
    length($0) > 0 { k = key($0); if (($0 in own) || !(k in pre) || pre[k] != $0) print }' \
    "$own" "$2/meta" "$3/meta" | LC_ALL=C sort
}

# Paths on stdin, as one line a person can read: grouped by their first
# component, a group of one printed as its path, a larger one as
# `dir/ (N files)`, joined with commas, and after eight groups `, and K more`.
# 600 regenerated build files are `build/ (600 files)`, not 600 names.
_felix_gate_names() {
  LC_ALL=C sort -u | LC_ALL=C awk '
    function flush() {
      if (ng >= 8) { more++; return }
      out = out (ng ? ", " : "") (n == 1 ? one : g " (" n " files)"); ng++
    }
    length($0) == 0 { next }
    { i = index($0, "/"); k = (i > 0) ? substr($0, 1, i) : $0
      if (!started || k != g) { if (started) flush(); g = k; n = 0; one = $0; started = 1 }
      n++ }
    END { if (started) flush(); if (more) out = out ", and " more " more"; printf "%s", out }'
}

# One receipt per repository, overwritten each run. History of decisions lives in
# the verification log; the receipt only answers "what was verified last".
_felix_receipt_path() {
  printf '%s/state/gate/%s' "$2" "$(printf '%s' "$1" | _felix_hash)"
}

# Called by the gate. Failure to write is never fatal: a gate that cannot record
# its own result is still a gate, and refusing to run would be a worse trade.
# A fifth field: which checks the gate reported as SKIPPED, comma-separated,
# or `-` when it reported none.
#
# The verdict alone is one bit, and `felix gate --quick` skips the test suite
# and still exits 0 — so its receipt was byte-identical to a full run's, and
# everything downstream spoke as if the suite had passed. A green that cannot
# be told from a partial green is the shape invariant 5 is about.
#
# Appended rather than inserted because every reader takes fields 1 to 3 by
# position (`cut -f1`, `-f2`, `-f3`), so a fifth field disturbs none of them —
# asserted in the suite rather than assumed.
#
# What this cannot say, and the readers must not imply otherwise: it records
# what the gate REPORTED. A gate that skips something without saying so is
# still invisible here, and no absence of skip lines proves nothing was
# skipped.
#
# A sixth field: every check the gate reported, with the verdict it printed,
# as `name:verdict` pairs comma-separated, or `-` when none was recorded. The
# gate's output was a temporary file the command threw away, so the only
# roster of what the gate checks was one somebody typed into a handoff — and a
# typed roster is wrong the day a checker is added. `felix qualify` reads this
# field to say which reported checks no qualification row covers. Same source
# and same limit as the fifth field: a check that runs without printing a line
# is not here.
#
# A seventh and eighth field: the decision epoch (epoch.sh) the gate ran under,
# and its four component hashes comma-joined in the spec's order — subject,
# topology, policy, target. v3.2 §5 binds a receipt to what its verdict rests
# on and invalidates it when a dependency moves; the tree id covers the tree
# and nothing else, so an ignored file a probe counts, a `$HOME`-dependent
# probe, or a table in the Felix home for a governed product could all move
# while an old green rode on. Supplied by the gate, and computed here from the
# checkout's own binding when a caller does not supply them, so a receipt
# without an epoch cannot be written by accident: the first draft let a
# six-field receipt stay current "until the next gate run", and the blind
# author of the assertions refused it as the old engine's receipts riding on.
# A gate with no epoch to record writes `-`, which on a green receipt means
# the project declares no probes, and the reader says what to write.
#
# A ninth, tenth and eleventh field: which tree the receipt is for, when the
# gate changed the tree it ran on (G2.1, G1.7, G2.4, PR-B finding 8). The gate
# takes the id twice, before it runs and after, and field 1 is the one it may
# vouch for. A gate that writes coverage, a lockfile, bytecode or a build
# directory git does not ignore used to stamp the tree it started on and read
# stale the moment it finished: every green gate was followed by a hold that
# rerunning the gate never cleared.
#
#   same     nothing moved; field 1 is the tree, as it always was; 10 and 11 `-`
#   gate     only untracked files the run wrote moved (felix_tree_moved); field
#            1 is the tree the run left, 10 the tree it started on, 11 names
#            what it wrote
#   moved    something else moved: HEAD, the index, tracked content, or an
#            untracked file no gate run wrote; field 1 is the tree it started
#            on, so the receipt reads stale, 10 the tree it left, 11 what moved
#   unknown  the tree could not be identified after the run; field 1 is the
#            tree it started on
#
# The tree the run left may add to the one it ran on only bytes a gate
# produced. It never vouches for tracked content, which any `git add` or commit
# would carry, nor for an untracked file that was in the tree before the run
# and not exactly as an earlier gate left it. What it cannot tell apart is an
# untracked file somebody else created during the run, and that one is named
# as the run's output, and stales the receipt the moment it is staged.
#
# Field 1 stays "the tree this receipt is for", so every reader of `cut -f1`
# (felix_verify_current, Stop, SubagentStop, the receipt JSON) reads on
# unchanged. Written only when a tenth argument is given; a caller with fewer
# gets the eight fields it always did, as the suite pins. A thirteenth, a
# file, becomes the ownership manifest beside the receipt, `<receipt>.own`:
# the metadata lines of the untracked files gate runs wrote, which is how the
# next run tells gate output it rewrites from a file somebody else wrote. It
# is written before the receipt, and left alone when no file is given.
felix_verify_record() {
  local root="$1" home="$2" rc="$3" gate="$4" tid="$5" skipped="${6:-}" reported="${7:-}" path result
  local epoch="${8:-}" comps="${9:-}" kind="${10:-}" other="${11:-}" names="${12:-}" manifest="${13:-}"
  [ -n "$tid" ] || return 0
  path="$(_felix_receipt_path "$root" "$home")"
  mkdir -p "$(dirname "$path")" 2>/dev/null || return 0
  result=green; [ "$rc" -eq 0 ] || result=red
  if [ $# -lt 8 ]; then
    local name proj fields
    name="$(head -1 "$root/.felix" 2>/dev/null | tr -d '[:space:]')"
    proj="$home/projects/$name"
    if [ -n "$name" ] && [ -d "$proj" ]; then
      fields="$(felix_verify_epoch_fields "$proj" "$root")"
      epoch="$(printf '%s' "$fields" | cut -f1)"; comps="$(printf '%s' "$fields" | cut -f2)"
    fi
  fi
  if [ $# -lt 10 ]; then
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$tid" "$result" "$(_felix_now)" "$gate" \
      "${skipped:--}" "${reported:--}" "${epoch:--}" "${comps:--}" > "$path" 2>/dev/null || true
    return 0
  fi
  if [ -n "$manifest" ] && [ -f "$manifest" ] && [ -r "$manifest" ]; then
    cat "$manifest" 2>/dev/null > "$path.own" || true
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$tid" "$result" "$(_felix_now)" "$gate" \
    "${skipped:--}" "${reported:--}" "${epoch:--}" "${comps:--}" \
    "${kind:--}" "${other:--}" "${names:--}" > "$path" 2>/dev/null || true
}

felix_verify_receipt() { cat "$(_felix_receipt_path "$1" "$2")" 2>/dev/null; }

# Is the receipt for this root a current green? One line, and 0 only for
# `current`:
#
#   none                    no receipt
#   red                     the receipt is not green
#   stale <TAB> reason      the tree changed; the receipt predates the epoch or
#                           carries none; the epoch cannot be read now; or a
#                           component moved — the grounded facts, the table
#                           set, the subject, the release target, in that
#                           order of precedence
#   current
#
# Every reader that used to compare field 1 to the tree id and field 2 to
# `green` reads this instead, so the five of them cannot disagree about what
# current means. The epoch is recomputed here, which runs the project's
# probes: a third of a second on the engine's own project, and only on the
# path that would otherwise have said verified.
#
# epoch.sh is sourced at call time rather than at load, because it pulls
# commission.sh in behind it and commission.sh sources this file: a load-time
# source from here would be a cycle, and at call time this file is complete.
felix_verify_current() {
  local root="$1" home="$2" proj="$3" tid receipt r_tid r_res r_epoch r_comps comps now_epoch
  receipt="$(felix_verify_receipt "$root" "$home" 2>/dev/null)"
  [ -n "$receipt" ] || { printf 'none\n'; return 1; }
  r_res="$(printf '%s' "$receipt" | cut -f2)"
  [ "$r_res" = "green" ] || { printf 'red\n'; return 1; }
  tid="$(felix_tree_id "$root" "$home" 2>/dev/null)" || tid=""
  r_tid="$(printf '%s' "$receipt" | cut -f1)"
  if [ -z "$tid" ] || [ "$r_tid" != "$tid" ]; then
    # A green run during which something other than its own output moved
    # keeps the tree it started on (felix_verify_record), and on exactly the
    # tree it left the reason names what moved, so `felix next` and the merge
    # boundary say which file to look at, not only that the tree changed
    # (G1.7, G2.1). Read from the receipt already in hand, with no process,
    # and only on this branch.
    local r_1="" r_2="" r_3="" r_4="" r_5="" r_6="" r_7="" r_8="" r_kind="" r_other="" r_names=""
    IFS=$'\t' read -r r_1 r_2 r_3 r_4 r_5 r_6 r_7 r_8 r_kind r_other r_names <<<"$receipt"
    if [ -n "$tid" ] && [ "$r_kind" = moved ] && [ "$r_other" = "$tid" ]; then
      if [ -n "$r_names" ] && [ "$r_names" != "-" ]; then
        printf 'stale\tfiles changed while the gate ran (%s), so its receipt is for the tree it started on; run felix gate\n' "$r_names"
      else
        printf 'stale\tthe tree changed while the gate ran, so its receipt is for the tree it started on; run felix gate\n'
      fi
      return 1
    fi
    printf 'stale\tthe tree changed since the receipt\n'; return 1
  fi
  # Six fields: written before the epoch existed, by an engine that could not
  # say what its verdict rested on. Not current; one gate run rewrites it.
  if [ "$(printf '%s' "$receipt" | awk -F'\t' '{ print NF }')" -lt 7 ]; then
    printf 'stale\tthe receipt predates the epoch, so what it rests on is not recorded; run felix gate\n'; return 1
  fi
  r_epoch="$(printf '%s' "$receipt" | cut -f7)"
  r_comps="$(printf '%s' "$receipt" | cut -f8)"
  # `-`: the gate had no epoch to record, which with a green result means the
  # project declares no probes — a probe that could not run turns the gate
  # red, and a red receipt never reaches this line. A verdict resting on
  # nothing Felix reads from reality cannot be confirmed, and running the gate
  # again would write the same `-`, so the remedy named is the table.
  if [ -z "$r_epoch" ] || [ "$r_epoch" = "-" ]; then
    printf 'stale\tthe receipt carries no epoch: this project declares no probes, so nothing here can be confirmed; write %s/probes.tsv\n' "$proj"; return 1
  fi
  if ! command -v felix_epoch_components >/dev/null 2>&1; then
    . "$(dirname "${BASH_SOURCE[0]:-$0}")/epoch.sh" 2>/dev/null || true
  fi
  if ! command -v felix_epoch_components >/dev/null 2>&1; then
    printf 'stale\tthe epoch cannot be read now: epoch.sh is not loaded\n'; return 1
  fi
  comps="$(felix_epoch_components "$proj" "$root" 2>/dev/null)"
  if printf '%s\n' "$comps" | cut -f2 | grep -qx -- '-'; then
    printf 'stale\tthe grounded facts cannot be read now, so the receipt cannot be confirmed; run felix gate\n'; return 1
  fi
  now_epoch="$(printf '%s\n' "$comps" | _felix_hash)"
  if [ "$now_epoch" = "$r_epoch" ]; then printf 'current\n'; return 0; fi
  # Which component moved, in the order a reader can act on: the world first,
  # then the tables, then the two that almost never move.
  local s t p r
  s="$(printf '%s' "$r_comps" | cut -d, -f1)"; t="$(printf '%s' "$r_comps" | cut -d, -f2)"
  p="$(printf '%s' "$r_comps" | cut -d, -f3)"; r="$(printf '%s' "$r_comps" | cut -d, -f4)"
  if [ "$(printf '%s\n' "$comps" | awk -F'\t' '$1 == "topology_version" { print $2 }')" != "$t" ]; then
    printf 'stale\tthe grounded facts moved since the receipt; run felix gate\n'
  elif [ "$(printf '%s\n' "$comps" | awk -F'\t' '$1 == "policy_version" { print $2 }')" != "$p" ]; then
    printf 'stale\tthe table set moved since the receipt; run felix gate\n'
  elif [ "$(printf '%s\n' "$comps" | awk -F'\t' '$1 == "subject_identity" { print $2 }')" != "$s" ]; then
    printf 'stale\tthe subject moved since the receipt; run felix gate\n'
  elif [ "$(printf '%s\n' "$comps" | awk -F'\t' '$1 == "release_target" { print $2 }')" != "$r" ]; then
    printf 'stale\tthe release target moved since the receipt; run felix gate\n'
  else
    printf 'stale\tthe epoch moved since the receipt and no component says why; run felix gate\n'
  fi
  return 1
}

# The two receipt fields the gate records, from one computation: the epoch and
# its components, or `-` and `-` when a component is unknown.
felix_verify_epoch_fields() {
  local proj="$1" root="$2" comps
  if ! command -v felix_epoch_components >/dev/null 2>&1; then
    . "$(dirname "${BASH_SOURCE[0]:-$0}")/epoch.sh" 2>/dev/null || true
  fi
  command -v felix_epoch_components >/dev/null 2>&1 || { printf -- '-\t-\n'; return 0; }
  comps="$(felix_epoch_components "$proj" "$root" 2>/dev/null)"
  if [ -z "$comps" ] || printf '%s\n' "$comps" | cut -f2 | grep -qx -- '-'; then
    printf -- '-\t-\n'; return 0
  fi
  printf '%s\t%s\n' "$(printf '%s\n' "$comps" | _felix_hash)" \
    "$(printf '%s\n' "$comps" | cut -f2 | paste -sd, -)"
}

# Every decision, allowed or refused, appended and committed. Nothing else in
# Claude Code records whether verification passed: transcripts carry is_error on
# tool results and Bash results carry no exit code at all. This file is the only
# place the fact exists.
felix_verify_log() {
  local proj="$1" verdict="$2" tid="$3" reason="$4"
  local mem; mem="$(felix_mem_dir "$proj")"
  [ -d "$mem" ] || mkdir -p "$mem" 2>/dev/null || return 0
  printf '%s\t%s\t%s\t%s\n' "$(_felix_now)" "$verdict" "${tid:-none}" "$reason" \
    >> "$mem/verification.log" 2>/dev/null || true
}
