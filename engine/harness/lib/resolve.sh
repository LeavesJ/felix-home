# Project resolution for Felix. Sourced by the CLI and the session hook, which
# are the two real callers; it is not a layer waiting for a third.
#
# Dependencies are bash and git only. Deliberately no jq and no python: Felix
# governs projects in languages it must not require, so it cannot drag a runtime
# along. The JSON reader below is the price of that, and its limits are stated.

# Substring test that never builds a pipeline.
#
# `producer | grep -q x` is a trap under `set -o pipefail`: grep exits the moment
# it matches, the producer takes SIGPIPE, and the pipeline reports 141. The check
# then says "absent" about something that is present. It is worse than a plain
# bug because it is timing-dependent for small producers, so it passes in testing
# and fails against a real repository.
felix_contains() {
  case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac
}

# Whole-line variant, for lists where a substring match would be too loose.
felix_has_line() {
  local line
  while IFS= read -r line; do [ "$line" = "$2" ] && return 0; done <<EOF
$1
EOF
  return 1
}

# Where Felix keeps writable state: projects and their doctrine. Not their
# memory, which since 2026-08-14 lives outside any repository — see
# felix_mem_root below for why that had to stop being the same directory.
#
# Separate from the engine because an installed plugin lives in a versioned cache
# that is replaced wholesale on update. Writing project doctrine in there would
# lose it on the next `claude plugin update`, silently, which is the worst way to
# lose a lesson someone paid for.
#
# Order: an explicit environment variable, then the pointer file `felix install`
# writes, then a repo checkout that already carries projects/ beside the engine,
# then the default.
felix_home() {
  local engine="$1"
  if [ -n "${FELIX_HOME:-}" ]; then printf '%s' "$FELIX_HOME"; return; fi
  if [ -f "$HOME/.felix-home" ]; then
    local p; p="$(tr -d '[:space:]' < "$HOME/.felix-home")"
    [ -n "$p" ] && [ -d "$p" ] && { printf '%s' "$p"; return; }
  fi
  # A plugin install is a frozen copy of the whole repository, projects/
  # included. Trusting that copy would govern from a constitution frozen at
  # install time and write memory into a directory the next plugin update
  # deletes, both silently. The copy is never a home.
  case "$engine" in
    */.claude/plugins/cache/*|*/.claude/plugins/marketplaces/*) ;;
    *)
      # The engine may sit at the repo root, or one level down so that a plugin
      # install carries the engine alone and leaves projects/ behind. Check both
      # before falling through, or a fresh clone silently starts a new home and
      # reports the project it is standing in as unknown.
      [ -d "$engine/projects" ] && { printf '%s' "$engine"; return; }
      [ -d "$engine/../projects" ] && { (cd "$engine/.." && pwd); return; }
      ;;
  esac
  printf '%s' "$HOME/.felix"
}

# Where project memory lives — and deliberately not under felix_home.
#
# Doctrine and memory were one directory tree until 2026-08-14, and that is what
# made this repository unpublishable. Doctrine is the part worth showing and the
# part the founder owns outright. Memory is not: it holds verbatim founder
# prompts, and whatever a governed project's work happens to be about, which
# includes material belonging to somebody who never agreed to be published. A
# repository that stores every governed project's memory can never be public,
# and left alone that cost is paid again by every project Felix adopts rather
# than once.
#
# The root is computed from $HOME and never from felix_home, even though every
# other writable thing Felix owns hangs off home. Derived from home it would sit
# inside the repository in the one case that actually went wrong — Felix
# governing itself, where home *is* the checkout. The invariant is worth more
# than the symmetry: memory is outside a repository by construction, not by
# whichever directory home resolved to today.
#
# A gitignore rule was the cheaper option and is not enough. It is one `git add
# -f` from failing, it does nothing about a tree somebody clones or cleans, and
# it leaves the material on disk inside the repository either way. Ignoring a
# file is a statement about git. Moving it is a statement about the disk.
felix_mem_root() {
  printf '%s' "${FELIX_MEMORY:-$HOME/.felix/memory}"
}

# The memory directory for one project, named by its doctrine directory.
#
# Keyed on the project's name rather than its path, so a worktree and the tree it
# came from share one memory. That is the behaviour every caller already assumed
# when memory sat beside doctrine under a single home, and the alternative — one
# memory per checkout — would silently split a project's lessons the first time
# somebody opened a worktree.
felix_mem_dir() {
  local p="${1%/}"
  printf '%s/%s' "${FELIX_MEMORY:-$HOME/.felix/memory}" "${p##*/}"
}

# Read one top-level string field out of a flat JSON file.
# Handles exactly what project.json needs: one nesting level, no escaped quotes.
# Anything richer belongs in a real parser, and would mean project.json has
# outgrown its job.
felix_json_str() {
  sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$1" | head -1
}

# Print the repo root for a directory, or the directory itself when not in git.
# Felix must work in a checkout that is not a git repo at all.
felix_repo_root() {
  local start="${1:-$PWD}" root d
  # Walk up for .git before asking git. `git rev-parse --show-toplevel` costs
  # about 12ms, and this is called from PreToolUse, which is synchronous on
  # every tool call — so it was roughly a third of that hook's whole budget for
  # an answer the filesystem already has. `.git` is a directory in a normal
  # clone and a file in a worktree or submodule, so -e covers both.
  d="$(cd "$start" 2>/dev/null && pwd -P)" || d=""
  while [ -n "$d" ] && [ "$d" != "/" ]; do
    [ -e "$d/.git" ] && { printf '%s' "$d"; return; }
    d="${d%/*}"
  done
  # Nothing found by walking. Ask git anyway rather than give up: GIT_DIR set in
  # the environment, or any layout where the marker is not on the path above,
  # is exactly the case the walk cannot see and git can.
  root="$(cd "$start" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)"
  [ -n "$root" ] && printf '%s' "$root" || printf '%s' "$start"
}

# Resolve which project governs a working directory.
# Prints the project directory on success, prints nothing and returns 1 on miss.
#
# Order matters. The .felix marker wins because it is the only mechanism that
# works for a repo with no remote, a fork, a rename, or a checkout of somebody
# else's code. Remote matching is the convenience path, not the contract.
felix_resolve_project() {
  local start="${1:-$PWD}" felix_root="$2"
  local root name remote meta match
  root="$(felix_repo_root "$start")"

  # 1. explicit marker file naming the project
  if [ -f "$root/.felix" ]; then
    name="$(tr -d '[:space:]' < "$root/.felix")"
    if [ -n "$name" ] && [ -d "$felix_root/projects/$name" ]; then
      printf '%s' "$felix_root/projects/$name"
      return 0
    fi
    return 1
  fi

  # 2. git remote substring match declared by each project
  remote="$(cd "$root" 2>/dev/null && git remote get-url origin 2>/dev/null)" || remote=""
  [ -n "$remote" ] || return 1
  for meta in "$felix_root"/projects/*/project.json; do
    [ -e "$meta" ] || continue
    match="$(felix_json_str "$meta" remote_match)"
    [ -n "$match" ] || continue
    case "$remote" in
      *"$match"*) printf '%s' "$(dirname "$meta")"; return 0 ;;
    esac
  done
  return 1
}

# Does this base name something that exists here?
#
# The question felix_changed_paths cannot answer, because it sends every git
# error to /dev/null and so reports a base nobody can resolve as a branch that
# changed nothing. An empty answer and an unanswerable question are different
# facts, and every caller that conflates them reads the second as the first —
# which is always the permissive direction.
#
# `^{commit}` is load-bearing, and receipt.sh learned it first. `git rev-parse
# --verify <40-hex>` exits 0 for a sha this repository has never held, because a
# full-length hex string is a syntactically valid object name and --verify alone
# checks the syntax. Only a name it cannot parse exits non-zero. Peeling to a
# commit is what turns a syntax check into an existence test.
#
# An empty base is not a failure to resolve one. felix_changed_paths has always
# taken it to mean "no branch comparison, working tree only", and callers rely
# on that; deciding it is unknown would break every one of them.
felix_base_resolves() {
  local root="${1:-}" base="${2:-}"
  [ -n "$root" ] && [ -n "$base" ] || return 1
  git -C "$root" rev-parse --verify "$base^{commit}" >/dev/null 2>&1
}

# Every path this branch touches, including what is staged but not committed.
#
# One function because there were four, and they drifted in the same direction.
# Each tried `git diff --name-only base...HEAD` and fell back to `git diff base`
# only when that came back EMPTY — so on a branch with commits, which is every
# pull request, the fallback never ran and everything staged or unstaged was
# dropped. `felix evidence` told a session it owed a test the session had just
# staged, and felix_escapes could not see a staged workflow change or a staged
# credential at all.
#
# It hid because the shape that masks it is the shape a fixture reaches for: on
# a branch with no commits yet, `base...HEAD` is empty and the fallback covers
# everything. lessons.sh had this right and nothing required the others to agree.
#
# Three sources, unioned rather than fallen back through:
#   base...HEAD   committed on this branch
#   --cached      staged, about to be committed
#   (bare)        edited, not yet staged
felix_changed_paths() {
  local root="$1" base="${2:-}"
  {
    [ -n "$base" ] && git -C "$root" diff --name-only "$base...HEAD" 2>/dev/null
    git -C "$root" diff --name-only --cached 2>/dev/null
    git -C "$root" diff --name-only 2>/dev/null
  } | grep -v '^$' | LC_ALL=C sort -u
}

# Every line this branch ADDS, including staged and unstaged ones.
#
# The companion to felix_changed_paths, and the half that was missed when that
# landed: knowing a path changed is not knowing what the change says. A content
# rule reading only `base...HEAD` names a staged file and then inspects the
# version without the staged content in it.
felix_added_lines() {
  local root="$1" base="${2:-}"
  {
    [ -n "$base" ] && git -C "$root" diff "$base...HEAD" 2>/dev/null
    git -C "$root" diff --cached 2>/dev/null
    git -C "$root" diff 2>/dev/null
  } | grep '^+' | grep -v '^+++'
}

# A file as it will be committed, not as it was last committed.
#
# The worktree copy when there is one, because that is what `git add -A` is
# about to record; `git show <ref>:` only afterwards. Erring toward the worktree
# errs toward seeing more, which is the safe direction for a check that decides
# whether something stops.
felix_file_at() {
  local root="$1" ref="$2" path="$3"
  if [ "$ref" = "HEAD" ] && [ -f "$root/$path" ]; then
    cat "$root/$path" 2>/dev/null
  else
    git -C "$root" show "$ref:$path" 2>/dev/null
  fi
}

# Whether two paths are checkouts of one repository, worktrees included.
#
# A worktree and its main checkout share one `--git-common-dir`, which is what
# makes this survive being somewhere else. Resolved to an absolute path first,
# because git answers `.git` from inside the main checkout and a full path from
# inside a worktree — comparing those two strings says "different" about the
# same repository, which is the bug this exists to stop rather than cause.
#
# Written because two guards asked "is this Felix's own storage" with a path
# prefix — `case "$root/$f" in "$FELIX_HOME_DIR"/projects/*)` — which is true
# only when you are standing in the home itself. From a worktree the root is
# elsewhere, the prefix never matches, and the guard silently does nothing. One
# of the two guards only reports; the other deletes.
# How many lines match, as one number.
#
# `grep -c` prints the count and *also* exits 1 when that count is zero, so the
# obvious `$(grep -c … || echo 0)` appends a fallback zero to the zero grep has
# already printed and yields "0\n0". Every arithmetic test on that errors into
# the wrong branch, and written to a file it becomes a stray line that later
# readers count as data: this project's own ledger held 215 of them in 280
# lines, and `felix ledger` reported seven sessions where there were three.
#
# Exit 2 — no such file — is the only case that prints nothing, and so it is the
# only case that needs a fallback. Recorded in lessons.md before this existed,
# which is why the fix is one function rather than eight repaired call sites.
felix_count() {
  local n
  n="$(grep -c "$@" 2>/dev/null)" || true
  case "$n" in ''|*[!0-9]*) printf '0' ;; *) printf '%s' "$n" ;; esac
}

felix_same_repo() {
  local a="$1" b="$2" ga gb
  [ -n "$a" ] && [ -n "$b" ] || return 1
  ga="$(git -C "$a" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 1
  gb="$(git -C "$b" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 1
  [ -n "$ga" ] && [ "$ga" = "$gb" ]
}

# Whether the repository under judgement is the one that ships this engine.
#
# Only that repository has the circularity worth breaking. A governed product's
# rules live in the Felix home and are not in its diff at all — #42 established
# that — so its branch cannot rewrite what judges it, and demanding a pinned
# engine there would be a fix for Felix and a regression for everything Felix
# governs: no plugin on a CI runner, none on a fresh clone, and merge refusing
# in both.
felix_self_governed() {
  local root="${1:-}"
  [ -n "$root" ] && [ -f "$root/engine/.claude-plugin/plugin.json" ] || return 1
  git -C "$root" ls-files --error-unmatch engine/.claude-plugin/plugin.json >/dev/null 2>&1
}

# The version a manifest declares, at a ref or in the working tree.
_felix_plugin_version() {
  local root="$1" ref="${2:-}"
  { if [ -n "$ref" ]; then git -C "$root" show "$ref:engine/.claude-plugin/plugin.json" 2>/dev/null
    else cat "$root/engine/.claude-plugin/plugin.json" 2>/dev/null; fi
  } | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1
}

# The engine that judges, which must not be the engine being judged.
#
# The first version of this took the newest entry in the plugin cache and was
# vacuous, because the gate's `installed` check will not go green until that
# entry matches the tree byte for byte, and merge will not run without a green
# receipt. So the newest entry is always the candidate by the time it matters.
# docs/2026-08-14-earned-autonomy-decision.md §4a had already said base-version
# evaluation could not be reached without settling the install-before-green
# cycle — "one problem seen from two sides".
#
# The judge is the version `main` declares instead. The cache keeps every
# version ever installed, and `felix install` refuses a changed engine at an
# unchanged version, so a branch that touches the engine has bumped past main
# and main's entry is both present and not the candidate's. The deadlock is
# side-stepped rather than fought: `installed` compares the tree against the
# newest entry while this reads an older one, and both hold at once.
#
# Two limits, stated because a root of trust that overclaims is worse than none.
# This is not a signature — the trust is that the cache entry for main's version
# is what main contained when somebody installed it. And FELIX_KERNEL overrides
# the whole resolution, so anything that can set the environment can choose its
# own judge; it exists so the suite can point at a constructed kernel instead of
# whatever happens to be on the machine running it.
felix_kernel_dir() {
  local root="${1:-}" base="${2:-main}" ver p ref
  if [ -n "${FELIX_KERNEL:-}" ]; then printf '%s' "$FELIX_KERNEL"; return 0; fi
  [ -n "$root" ] || return 1
  # The branch being merged into, not the literal word "main". Hard-coding it
  # made this depend on `init.defaultBranch`, which is a property of whoever ran
  # it — green on a laptop that says main and red on a runner that says master.
  for ref in "origin/$base" "$base"; do
    git -C "$root" rev-parse --verify "$ref" >/dev/null 2>&1 && break
    ref=""
  done
  [ -n "$ref" ] || return 1
  ver="$(_felix_plugin_version "$root" "$ref")"
  [ -n "$ver" ] || return 1
  # FELIX_KERNEL_CACHE, not FELIX_PLUGIN_CACHE. toolbox.sh already owns that
  # name and means something else by it — the plugins cache ROOT, one level up
  # from felix's own versions — and the CLI sources toolbox.sh, so reading it
  # here resolved .../plugins/cache/<version>/harness and found nothing. The
  # suite never saw it because every test set the variable explicitly, which
  # masks a collision instead of exposing one. Composed with it rather than
  # around it, so a machine that moves the plugins cache moves this too.
  p="${FELIX_KERNEL_CACHE:-${FELIX_PLUGIN_CACHE:-$HOME/.claude/plugins/cache}/felix/felix}/$ver/harness"
  [ -d "$p" ] || return 1
  printf '%s' "$p"
}

# Where the felix marketplace serves its engine from, or empty when it is not
# registered. Reads the registry rather than assuming, because the answer is the
# difference between a deploy and a no-op that reports success.
felix_marketplace_root() {
  local reg="${1:-$HOME/.claude/plugins/known_marketplaces.json}"
  [ -f "$reg" ] || return 0
  sed -n '/"felix"[[:space:]]*:[[:space:]]*{/,/^  }/p' "$reg" 2>/dev/null \
    | sed -n 's/.*"installLocation"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1
}

# Whether this engine is one Claude Code could ever install from.
#
# `felix install` in a worktree bumps the manifest, runs the three plugin
# commands, finds the cache unchanged and reports "this is no longer the version
# cache; something else is wrong" — which sends you looking for corruption. The
# registry is a directory marketplace pinned to one path, so a worktree's engine
# is not the engine being served and never was. Nothing is broken; the deploy
# went to the tree the marketplace names, which is main.
#
# It is not a refusal. The bump still belongs on the branch, because merging is
# what makes it deployable, and a branch that never bumped deploys nothing when
# it lands. Only the diagnosis changes.
# Tested on the engine's own parent, not on a path prefix. A worktree lives
# under `.claude/worktrees/` *inside* the main checkout, so "starts with the
# marketplace root" is true of every worktree there is and the check would have
# passed exactly where it needed to fail.
felix_deployable_from() {
  local engine_root="$1" mroot parent
  mroot="$(felix_marketplace_root "${2:-}")"
  [ -n "$mroot" ] || return 0
  parent="${engine_root%/*}"
  [ "$parent" = "$mroot" ] && return 0
  printf '%s' "$mroot"
  return 1
}

# Raise the patch digit in a plugin manifest, and print the new version.
#
# Claude Code caches a plugin by version, so a changed engine at an unchanged
# version never deploys and still reports success. `felix install` detected that
# exact condition and printed "bump the version, then re-run this" — a command
# suggesting something it could safely have done, which the charter names as a
# defect. The gate caught `installed` nine times before anybody counted, every
# one of them a person typing the digit the command was withholding.
#
# Bumping is not the risky half. install is already the thing that replaces the
# deployed engine; refusing to change a number while doing that is caution in
# the wrong place.
#
# Refuses rather than guesses when the version is not three numbers. A manifest
# it cannot parse is one it must not rewrite.
felix_version_bump() {
  local manifest="$1" cur major minor patch next tmp
  [ -f "$manifest" ] || return 1
  cur="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$manifest" | head -1)"
  case "$cur" in
    [0-9]*.[0-9]*.[0-9]*) ;;
    *) return 1 ;;
  esac
  major="${cur%%.*}"; minor="${cur#*.}"; minor="${minor%%.*}"; patch="${cur##*.}"
  case "$major$minor$patch" in *[!0-9]*) return 1 ;; esac
  next="${major}.${minor}.$((patch + 1))"
  # Through a temp file, so a failed write cannot leave empty the one manifest
  # whose corruption stops everything deploying.
  tmp="$(mktemp)" || return 1
  sed 's/\("version"[[:space:]]*:[[:space:]]*"\)[^"]*\("\)/\1'"${next}"'\2/' \
      "$manifest" > "$tmp" 2>/dev/null || { rm -f "$tmp"; return 1; }
  [ -s "$tmp" ] || { rm -f "$tmp"; return 1; }
  mv -f "$tmp" "$manifest" 2>/dev/null || { rm -f "$tmp"; return 1; }
  printf '%s' "$next"
}
