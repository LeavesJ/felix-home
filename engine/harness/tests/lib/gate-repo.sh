# tests/lib/gate-repo.sh: the widget gate and the repository the completion gate is driven in.
# Used by 0210 (builds it) and 0220 (GREPO, in the state 0210 leaves it: one
# commit, a clean tree, WIDGET.txt and the widget marker, and the widget gate
# that tests for WIDGET.txt). Moved from parts/0210-the-completion-gate.sh lines 10-24.
# Definitions only. _gate_repo_build sets GREPO (the physical path) and does
# nothing more once the repository is there, so in the serial run only 0210's
# call writes the gate and makes the repository.

_gate_repo_build() {
  GREPO="$TMP/gaterepo"
  if [ -d "$GREPO/.git" ]; then GREPO="$(cd "$GREPO" && pwd -P)"; return 0; fi
  cat > "$FROOT/projects/widget/project.json" <<'EOF'
{
  "name": "widget",
  "remote_match": "example.com/widget",
  "gate": "sh -c 'test -f WIDGET.txt && echo widget-gate-ran'"
}
EOF
  GREPO="$TMP/gaterepo"
  mkdir -p "$GREPO"
  ( _fx_cd "$GREPO" && git init -q -b main
    printf 'contents\n' > WIDGET.txt
    printf 'widget\n'   > .felix
    git add -A >/dev/null 2>&1
    git -c user.name=t -c user.email=t@t commit -qm init >/dev/null 2>&1 )
  GREPO="$(cd "$GREPO" && pwd -P)"
}

# _gate_catch_build: the widget's memory holds a catch nobody has written down,
# which is what 0210's red gate (WIDGET.txt gone, `felix gate`) leaves in the
# serial run: one exit-1 row in mistakes.log, newer than the lessons and the devlog.
# Run after the lessons are written, so the row is the newer. Does nothing when
# the log already holds a row.
_gate_catch_build() {
  [ -s "$MEM/widget/mistakes.log" ] && return 0
  _gate_repo_build
  ( _fx_cd "$GREPO" && rm -f WIDGET.txt && "$FELIX" gate >/dev/null 2>&1; printf 'contents\n' > WIDGET.txt )
}
