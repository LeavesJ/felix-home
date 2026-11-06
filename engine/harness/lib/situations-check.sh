# felix situations, what the readings share (slice 1 of the capability lane; contract C17.2 of
# docs/2026-10-29-lane-slice-1-plan.md). Loaded by cmd_situations in felix, after lib/situations.sh. Definitions only.
#
# It holds the environment the slice's own git calls run in for a scratch clone. A later amendment (C17.4) adds the checks
# every step of a run shares.
#
#   _felix_situations_in_rules      a command run in the environment that _felix_git_rules gives (C17.2)

# COMMAND [ARG...] run in the environment _felix_git_rules gives git (C17.2): none of the environment that points git at
# another repository, no GIT_CONFIG_PARAMETERS or GIT_CONFIG_COUNT, no global or system configuration, and HOME and
# XDG_CONFIG_HOME naming the scratch directory SCRATCH. TMP is the TMPDIR it runs with. It runs in a subshell, so nothing it
# sets outlives it. The probes do not run here: they are the project's commands and keep the caller's environment.
_felix_situations_in_rules() {   # SCRATCH TMP COMMAND [ARG...]
  local scr="${1-}" tmp="${2-}"
  shift 2
  ( unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT
    export HOME="$scr" XDG_CONFIG_HOME="$scr" GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 TMPDIR="$tmp"
    "$@" )
}
