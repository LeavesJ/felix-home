# felix bootstrap: what it finds, what it holds back, and what it changes.
#
# The reads and writes against GitHub are in bootstrap-gh.sh; the workflow, the
# pin and the permission policy are in bootstrap.sh. This is the order they are
# used in, and the rule that joins them: a branch is made to require the `gate`
# check only when CI can pass it.
#
# CI can pass it when it can resolve the project. The workflow checks Felix out
# at the pinned commit, and `felix which` there finds the project only in that
# checkout's own projects/. So the commit has to be on a Felix repository CI can
# fetch and has to hold projects/<name>. From a plain clone of someone else's
# Felix, `felix new` leaves projects/<name> untracked, the pin is empty, and no
# commit anywhere holds the project: a required check that fails at checkout on
# every pull request, whatever the code. Bootstrap says so, on the `ci project:`
# line, and holds the rule back until it is true. The same goes for a workflow
# that is not yet on the default branch (the check would never report, and every
# other pull request would wait on it) and one that still reads {{FELIX_REF}}.
#
# The branch is the repository's default branch as GitHub names it, not the
# branch the session has checked out: a worktree on claude/adopt-x used to
# protect claude/adopt-x and leave the default branch open.

# NAME FELIX_REPO PIN ENGINE_DIR: whether CI resolves the project, in _bs_ci_ok
# (1 or 0), and when not, why, in _bs_ci_why. The reasons are in the order they
# are looked for.
_felix_bs_ci_judge() {
  _bs_ci_ok=0; _bs_ci_why=""
  if [ -z "$2" ]; then _bs_ci_why="Felix has no GitHub remote for CI to fetch"
  elif [ -z "$3" ]; then _bs_ci_why="no commit is pinned"
  elif git -C "$4" cat-file -e "$3:projects/$1/project.json" 2>/dev/null; then _bs_ci_ok=1
  else _bs_ci_why="the pinned commit does not hold projects/$1"
  fi
}

# REPO_ROOT BRANCH WORKFLOW_FILE: how the gate workflow stands on the default
# branch as this clone last fetched it, in _bs_wf: ok, absent, placeholder (it
# still reads {{FELIX_REF}}) or unread. Only a line that is not a comment counts
# as reading it: the workflow bootstrap renders explains the placeholder in a
# comment, so a filled one names it too.
_felix_bs_wf_state() {
  local ref="refs/remotes/origin/$2:.github/workflows/$3" txt
  _bs_wf=absent
  git -C "$1" cat-file -e "$ref" 2>/dev/null || return 0
  txt="$(git -C "$1" cat-file blob "$ref" 2>/dev/null)" || { _bs_wf=unread; return 0; }
  if [ -n "$(printf '%s\n' "$txt" | LC_ALL=C awk 'index($0, "{{FELIX_REF}}") && $0 !~ /^[ \t]*#/ { print "x"; exit }')" ]
  then _bs_wf=placeholder; else _bs_wf=ok; fi
}

# MARK NAME TEXT: one row. Every row that is not done is a step outstanding, and
# one that could not be read is also counted as that.
_felix_bs_row() {
  printf '  [%s] %-12s %s\n' "$1" "$2" "$3"
  [ "$1" = "x" ] && return 0
  _bs_todo=$((_bs_todo + 1))
  [ "$1" = "?" ] && _bs_unk=$((_bs_unk + 1))
  return 0
}

# PROJECT_DIR [--yes]: the plan, or with --yes the plan applied. Exits 1 for a
# step that failed, a read that could not be made, a rule held back because CI
# could not pass it, or a rule that is on and cannot be passed; 0 otherwise,
# which includes waiting for the workflow to reach the default branch.
felix_bootstrap() {
  local proj="$1" yes=0 a; shift
  for a in "$@"; do [ "$a" = "--yes" ] && yes=1; done
  local root slug eco gwf wfp name esrc felix_repo felix_ref etop pdir prel="" ref_none ci_line
  root="$(felix_repo_root "$PWD")"
  slug="$(felix_repo_slug "$root")"
  eco="$(felix_guess_ecosystem "$root")"
  # The file the repair loop and the auto-merge streak read the gate's runs
  # from, so the one this looks for and writes. Resolved before anything is
  # printed: a refused gate_workflow is a fact about the project to fix first.
  gwf="$(felix_gate_workflow "$proj")" || die "$gwf"
  wfp=".github/workflows/$gwf"
  name="$(basename "${proj%/}")"
  # The Felix checkout, not the directory this script happens to sit in. #65:
  # `felix_repo_slug "$FELIX_ROOT"` asked git for a remote inside the running
  # engine, which from the deployed CLI is the plugin cache — no remote, so this
  # printed "none, CI cannot fetch the harness" about an engine whose remote
  # exists. Worse on a machine whose home directory is itself a git repository
  # with an origin: that slug would be returned instead and interpolated into
  # the generated workflow's `repository:`, beside a deploy key. Resolve the
  # tree first, then slug the tree.
  esrc="$(felix_engine_source "$FELIX_ROOT" "$FELIX_HOME_DIR")" || esrc=""
  felix_repo=""; felix_ref=""
  [ -n "$esrc" ] && felix_repo="$(felix_repo_slug "$esrc")"
  # The commit CI checks Felix out at, from the same checkout as the slug, and
  # holding this project when the project lives in that checkout. Physical
  # paths on both sides: macOS spells /var as /private/var, and git reports
  # the resolved form.
  if [ -n "$esrc" ]; then
    etop="$(git -C "$esrc" rev-parse --show-toplevel 2>/dev/null)" || etop=""
    pdir="$(cd "$proj" 2>/dev/null && pwd -P)" || pdir=""
    case "$pdir" in "$etop"/?*) [ -n "$etop" ] && prel="${pdir#"$etop"/}" ;; esac
    felix_ref="$(felix_bs_pin_ref "$esrc" "$prel")" || felix_ref=""
  fi
  ref_none="none: no commit of the engine checkout that origin's default branch holds${prel:+ with $prel in it}; the workflow gets {{FELIX_REF}} to fill"
  # Whether the pin is a commit CI can resolve the project from. The pin only
  # says the commit is on origin's default branch; the project has to be in it.
  _felix_bs_ci_judge "$name" "$felix_repo" "$felix_ref" "$esrc"
  if [ "$_bs_ci_ok" -eq 1 ]; then ci_line="projects/$name is in the pinned commit, so CI resolves the project"
  else ci_line="none: $_bs_ci_why; commit projects/$name to the default branch of a Felix repository on GitHub that you can push to (from a clone of someone else's Felix, a fork that the engine checkout's origin names), then re-run"; fi

  printf 'repo:        %s\n' "${slug:-no github remote}"
  printf 'ecosystem:   %s\n' "$eco"
  printf 'felix repo:  %s\n' "${felix_repo:-none, CI cannot fetch the harness}"
  printf 'felix ref:   %s\n' "${felix_ref:-$ref_none}"
  printf 'ci project:  %s\n\n' "$ci_line"

  local d="" pst="" lst="" lmiss="" hold="" remedy="" kind=0 rc=0 pwhy="" lwhy="" dwhy="" wfhave=no
  _bs_todo=0; _bs_unk=0
  if _felix_bs_have_workflow "$root" "$gwf"; then wfhave=yes; a=x; else a=" "; fi
  _felix_bs_row "$a" ci-workflow "$wfp calling felix gate"
  if [ -n "$slug" ]; then
    if _felix_bs_labels_read "$slug"; then lst="$_bs_lst"; lmiss="$_bs_lmiss"
    else lst=unknown; lwhy="$_bs_why"; fi
    case "$lst" in
      yes) _felix_bs_row x labels "escalation and risk labels the repair loop applies" ;;
      no)  _felix_bs_row " " labels "escalation and risk labels the repair loop applies; missing: $lmiss" ;;
      *)   _felix_bs_row "?" labels "could not be read: escalation and risk labels the repair loop applies ($lwhy)" ;;
    esac
    if _felix_bs_default_branch "$slug"; then
      d="$_bs_d"
      _felix_bs_prot_read "$slug" "$d"; pst="$_bs_pst"; pwhy="$_bs_why"
    else dwhy="$_bs_why"; fi
    if [ -n "$d" ] && [ "$pst" != unknown ]; then
      # Held back: the first of these that is so. A workflow this run writes is
      # not on the default branch yet, so it counts as not there.
      _felix_bs_wf_state "$root" "$d" "$gwf"
      if [ "$_bs_ci_ok" -ne 1 ]; then
        kind=2; hold="CI cannot resolve $name because $_bs_ci_why"; remedy="see ci project: above"
      elif [ "$_bs_wf" = absent ]; then
        kind=3; hold="$wfp is not on origin/$d"; remedy="merge it there, then re-run"
      elif [ "$_bs_wf" = placeholder ]; then
        kind=4; hold="$wfp on origin/$d still reads {{FELIX_REF}}"; remedy="set the pin there, then re-run"
      elif [ "$_bs_wf" = unread ]; then
        kind=4; hold="$wfp on origin/$d could not be read"; remedy="fetch, then re-run"
      fi
    fi
    if [ -z "$d" ]; then
      _felix_bs_row "?" protection "could not be read: the default branch of $slug ($dwhy)"
    else
      case "$pst" in
        gate)   _felix_bs_row x protection "$d requires the gate" ;;
        nogate) _felix_bs_row " " protection "$d is protected but does not require the gate${hold:+; held back: $hold}" ;;
        none)   _felix_bs_row " " protection "require the gate on $d, block force pushes${hold:+; held back: $hold}" ;;
        *)      _felix_bs_row "?" protection "could not be read: the protection of $d ($pwhy)" ;;
      esac
    fi
  else
    printf '  [-] %-12s no github remote; labels and protection skipped\n' "github"
  fi
  if _felix_bs_have_perms "$root"; then a=x; else a=" "; fi
  _felix_bs_row "$a" permissions ".claude/settings.json deny and ask policy"

  # A rule that is on and cannot be passed is not a baseline.
  local unpass=0
  if [ "$pst" = gate ] && [ -n "$hold" ]; then
    unpass=1; rc=1
    printf '\n%s requires the gate, which CI cannot pass: %s.\n' "$d" "$hold"
  fi
  if [ "$_bs_todo" -eq 0 ]; then
    [ "$unpass" -eq 1 ] || printf '\nBaseline already in place.\n'
    [ "$yes" -eq 1 ] && return "$rc"
    return 0
  fi
  if [ "$yes" -ne 1 ]; then
    if [ "$_bs_unk" -gt 0 ]; then printf '\n%s step(s) outstanding (%s could not be read). Nothing changed.\n' "$_bs_todo" "$_bs_unk"
    else printf '\n%s step(s) outstanding. Nothing changed.\n' "$_bs_todo"; fi
    printf 'apply with: felix bootstrap --yes\n'
    return 0
  fi

  printf '\napplying\n'
  if [ "$wfhave" = no ]; then
    if [ -z "$felix_repo" ]; then
      printf '  skipped    ci-workflow (Felix has no remote for CI to fetch)\n'
    else
      mkdir -p "$root/.github/workflows"
      felix_bs_render_workflow "$eco" "$felix_repo" "$felix_ref" > "$root/$wfp"
      printf '  wrote      %s (review, then commit it)\n' "$wfp"
      if [ -z "$felix_ref" ]; then
        printf "             its ref: is {{FELIX_REF}}; set the full sha of a commit on %s's default branch that holds projects/%s\n" "$felix_repo" "$name"
      elif [ "$_bs_ci_ok" -ne 1 ]; then
        printf "             CI cannot resolve %s at that ref; it needs a commit on %s's default branch that holds projects/%s\n" "$name" "$felix_repo" "$name"
      fi
    fi
  fi
  case "$lst" in
    no)      for a in needs-founder needs-architecture risk-green risk-yellow risk-red; do
               felix_contains " $lmiss " " $a " && { _felix_bs_label_create "$slug" "$a" || rc=1; }
             done ;;
    unknown) printf '  skipped    labels (could not be read: %s)\n' "$lwhy" ;;
  esac
  if [ -n "$slug" ]; then
    if [ -z "$d" ]; then
      printf '  skipped    protection (could not be read: the default branch of %s, %s)\n' "$slug" "$dwhy"
    elif [ "$pst" = unknown ]; then
      printf '  skipped    protection (could not be read: the protection of %s, %s)\n' "$d" "$pwhy"
    elif [ "$pst" != gate ]; then
      if [ -n "$hold" ]; then
        printf '  skipped    protection (%s; %s)\n' "$hold" "$remedy"
        [ "$kind" -eq 3 ] || rc=1
      else
        _felix_bs_protect "$slug" "$d" "$pst" || rc=1
      fi
    fi
  fi
  [ "$_bs_unk" -eq 0 ] || rc=1
  if ! _felix_bs_have_perms "$root"; then
    mkdir -p "$root/.claude"
    if [ -f "$root/.claude/settings.json" ]; then
      printf '  skipped    permissions (settings.json exists; merge by hand rather than clobber it)\n'
    else
      felix_bs_render_perms > "$root/.claude/settings.json"
      printf '  wrote      .claude/settings.json\n'
    fi
  fi
  printf '\nRe-run felix bootstrap to confirm.\n'
  return "$rc"
}
