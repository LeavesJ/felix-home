# tests/lib/cm-stub.sh: the `claude` stub on PATH and the ungoverned repository.
# Used by parts 0010 (builds both), 0070 0180 0190 0220 0250 0450 0580 0650
# 0660-0710 0720 0730 0820 0850 (CMSTUB, CMSTUB_LOG) and 0070 0200 0220 0250
# 0600 (PLAIN). Moved from parts/0010-resolution.sh: _plain_build from line 33
# (PLAIN), _cmstub_build from lines 183-196 (CMSTUB, CMSTUB_LOG, the stub).
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
