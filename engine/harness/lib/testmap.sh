# felix testmap: the test selector's two commands (audit b30, contract B21). It is dispatched
# before the Felix home is resolved, as felix cost is, so it works with no home.
#   felix testmap --report [BASE]   what a change would run, and why; it runs nothing
#   felix testmap --compile DIR     the map of a traced run (tests/run -j N with FELIX_TEST_TRACE_DIR=DIR)
# The code is tests/select.sh and the select-*.sh beside it, which ship with the harness; an
# engine without them makes every testmap command say so in one line and exit 1. This file
# defines functions and runs nothing when sourced.
felix_testmap_usage() { printf 'usage: felix testmap --report [BASE] | --compile DIR\n'; }
felix_testmap() {
  local t="${SCRIPT_DIR}/tests" f
  [ -f "$t/select.sh" ] || { printf 'felix testmap: this engine has no tests/select.sh, so it has no map to make or read\n' >&2; return 1; }
  case "${1:-}" in
    --help|-h) felix_testmap_usage; return 0 ;;
    --report) [ "$#" -le 2 ] || { felix_testmap_usage >&2; return 2; } ;;
    --compile) [ "$#" -eq 2 ] && [ -n "$2" ] || { felix_testmap_usage >&2; return 2; } ;;
    *) felix_testmap_usage >&2; return 2 ;;
  esac
  for f in "$t/select.sh" "$t"/select-*.sh; do
    [ -f "$f" ] || continue
    # shellcheck disable=SC1090
    . "$f" || { printf 'felix testmap: %s cannot be read\n' "$f" >&2; return 1; }
  done
  case "$1" in
    --report) _tm_report "${2-}" ;;
    --compile) _tm_compile "$2" ;;
  esac
}
