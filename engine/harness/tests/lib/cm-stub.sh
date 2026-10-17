# tests/lib/cm-stub.sh: the `claude` stub on PATH, the ungoverned repository, and
# the stranger project.
# Used by parts 0010 (builds all three), 0070 0180 0190 0220 0400 0450 0580 0650
# 0660-0710 0720 0730 0780 0820 0850 (CMSTUB, CMSTUB_LOG), 0070 0200 0220 0250
# 0600 (PLAIN) and 0200 0780 (the stranger project). Moved from
# parts/0010-resolution.sh: _plain_build from line 33 (PLAIN), _cmstub_build from
# lines 183-196 (CMSTUB, CMSTUB_LOG, the stub), _stranger_build from lines 184-193.
# Definitions only. A builder sets its variables first and does nothing more when
# its fixture is already there, so in the serial run only 0010's call builds.

# _plain_build: PLAIN is $TMP/unrelated, an ungoverned git repository.
_plain_build() {
  PLAIN="$TMP/unrelated"
  [ -d "$PLAIN/.git" ] && return 0
  mkdir -p "$PLAIN"; ( _fx_cd "$PLAIN" && git init -q -b main )
}

# _cmstub_build: A `claude` that logs every argument line and REFUSES any shape the suite
# never taught it, so an assertion that depends on it can fail. It exists
# because felix new now commissions — runs discover --adopt, stack apply
# --yes and ready --fix — and the real cli on this machine would take those
# to the network. Every test that runs felix new goes through it.
# CMSTUB is the directory holding the stub, CMSTUB_LOG its log (truncated when
# the stub is built, left as it stands when it already exists).
_cmstub_build() {
  CMSTUB="$TMP/cm-stub"; CMSTUB_LOG="$TMP/cm-stub.log"
  [ -x "$CMSTUB/claude" ] && return 0
  mkdir -p "$CMSTUB"; : > "$CMSTUB_LOG"
  cat > "$CMSTUB/claude" <<STUB
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$CMSTUB_LOG"
case "\$*" in
  "plugin list --json"|"plugin list --json --available") printf '[]\n' ;;
  "plugin marketplace list"*|"mcp list"*) : ;;
  "plugin install "*|"plugin enable "*|"plugin marketplace add "*|"plugin update"*) : ;;
  *) printf 'stub: untaught shape: %s\n' "\$*" >&2; exit 2 ;;
esac
STUB
  chmod +x "$CMSTUB/claude"
}

# _stranger_build: the stranger project, which 0010 onboards with felix new and
# 0200 (its generated constitution) and 0780 (its exceptions table) read after
# it. Moved from parts/0010-resolution.sh, lines 184-193: a Node app with no git
# remote, nothing to do with anything already here, and `felix new stranger`
# over it through the claude stub. Sets STRANGE, and _stranger_out and
# _stranger_rc, felix new's output and exit status, which 0010 asserts over; they
# are set only when this call builds. Does nothing more once the project
# ($FROOT/projects/stranger) and the checkout's binding are there, so in the
# serial run only 0010's call builds.
_stranger_build() {
  STRANGE="$TMP/stranger"
  [ -f "$FROOT/projects/stranger/project.json" ] && [ -f "$STRANGE/.felix" ] && return 0
  _cmstub_build
  mkdir -p "$STRANGE"
  ( _fx_cd "$STRANGE" && git init -q -b main )
  cat > "$STRANGE/package.json" <<'JSON'
{ "name": "stranger", "scripts": { "verify": "echo ok" },
  "dependencies": { "express": "^4", "stripe": "^17" },
  "devDependencies": { "playwright": "^1" } }
JSON
  _stranger_out="$(cd "$STRANGE" && PATH="$CMSTUB:$PATH" "$FELIX" new stranger 2>&1)"; _stranger_rc=$?
}
