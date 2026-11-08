# The merge boundary reads its policy, and the instruments that policy names, from P.
#
# Trust-plane design §4.1 (docs/2026-11-07-trust-plane-design.md): "The authority takes one thing from
# the candidate change: the subject, meaning the revision. It takes everything that judges that subject
# from the authorized policy version." Design step 3 enumerates what the authority reads and moves each
# input to that version. This file is the first slice of that move, for felix_merge_blockers alone; the
# spec is in the memory root, audits/2026-11-08-trust-plane-step3/spec.md, and the inventory that found
# the inputs is docs/2026-11-08-trust-step3-inventory.md.
#
# THE GAP. felix_merge_blockers read every table from the project directory it was handed, which is the
# home's working tree: whatever FELIX_HOME named, and whatever sat uncommitted there. For Felix itself
# the home is a checkout of the repository being merged, so a branch checked out in the home, or a
# worker that pointed FELIX_HOME at its own checkout, was judged by the tables it carried. And every
# command those tables hold (an obligation's applies and evidence contract, a probe's when, command and
# witness) ran `bash -c` in the candidate's checkout, so a script the command names was the candidate's:
# a branch could rewrite the checker that judged it, or the library that checker sources, and pass.
#
# THE RULE (spec S1, S2).
#   - P is the ref the merge judges against (BASE) when the project directory is tracked in the
#     repository being merged, and that repository's refs/remotes/origin/main when it is tracked in
#     another one (a product governed from a Felix home). A project directory that no repository tracks
#     has no authorized version, and is read from disk as before.
#   - The tables are read from a snapshot of the project directory as P holds it: regular files only,
#     byte for byte. A tracked project directory that P does not hold is a refusal, never the disk.
#   - A word in command position of a P command that names a regular file P holds in the repository
#     being merged runs as P's copy of that file, with P's whole top-level directory around it, so a
#     script that finds its libraries beside itself finds P's. The working directory stays the
#     candidate's checkout: what the command reads by path is the subject.
#   - Everything made here lives in one felix-policy.* directory under TMPDIR and is removed when the
#     judgement ends.
#
# WHAT THIS DOES NOT BIND, as examples and not the set. A file a P script reads by a path relative to
# the working directory, a mixed file (`make`, `npm test` reading the candidate's Makefile or manifest),
# and a word _felix_p_rewrite does not recognise (inside quotes, after a `$`) are still the candidate's:
# the partition of every path into instrument and subject (spec part 2, E5) is not built. The suite and
# the gate receipt, which judge Felix's own engine, are the candidate's and the session's. A same-user
# process can move refs/remotes/origin/main or name another --base. The step-3 report measures each.
#
# Sourced by escape.sh. Needs resolve.sh (_felix_git_rules, felix_same_repo).

# Set only by felix_policy_open, in the shell that judges: an inherited value never names a policy
# directory or an instrument.
unset _FELIX_POL_TMP _FELIX_POL_DIR _FELIX_P_TREE _FELIX_P_WORDS

# Every regular file under SHA:PREFIX in ROOT's repository, into DEST, as git stores it (mode kept, no
# symbolic link, no submodule). One git process for the tree, against a scratch repository that borrows
# ROOT's objects and reads no machine-local configuration, the way lib/merge-judge.sh cuts main's engine.
# PREFIX names a tree, or a file at the top level. Returns 0, or 1 when it could not.
_felix_policy_copy() {   # ROOT SHA PREFIX DEST
  local root="$1" sha="$2" pre="$3" dest="$4" objs scratch typ mode
  objs="$(git -C "$root" rev-parse --path-format=absolute --git-path objects 2>/dev/null </dev/null)"
  [ -n "$objs" ] && [ -d "$objs" ] || return 1
  typ="$(git -C "$root" cat-file -t "$sha:$pre" 2>/dev/null </dev/null)" || return 1
  if [ "$typ" = blob ]; then
    mode="$(git -C "$root" ls-tree "$sha" -- "$pre" 2>/dev/null </dev/null | LC_ALL=C awk '{ print $1; exit }')"
    case "$mode" in 100644|100755) ;; *) return 1 ;; esac
    mkdir -p "$(dirname "$dest")" || return 1
    git -C "$root" cat-file blob "$sha:$pre" > "$dest" 2>/dev/null </dev/null || return 1
    [ "$mode" = 100755 ] && chmod 755 "$dest"
    return 0
  fi
  [ "$typ" = tree ] || return 1
  scratch="$dest.scratch"
  mkdir -p "$scratch" || return 1
  if ! { _felix_git_rules "$scratch" init -q --template= >/dev/null 2>&1 \
         && mkdir -p "$scratch/.git/objects/info" \
         && printf '%s\n' "$objs" > "$scratch/.git/objects/info/alternates" \
         && _felix_git_rules "$scratch" read-tree "$sha:$pre" >/dev/null 2>&1 \
         && _felix_git_rules "$scratch" checkout-index -a --prefix="$dest/" >/dev/null 2>&1; }; then
    rm -rf "$scratch"; return 1
  fi
  rm -rf "$scratch"
  mkdir -p "$dest" || return 1
  # A symbolic link would read whatever it points at, which P does not hold.
  find "$dest" -type l -exec rm -f {} + 2>/dev/null
  return 0
}

# Where the tables come from for this judgement: sets _FELIX_POL_DIR, and _FELIX_POL_TMP when a
# snapshot was made. Returns 0; or prints one policy blocker line and returns 1 (fail closed).
felix_policy_open() {   # PROJ BASE ROOT
  local proj="$1" base="$2" root="$3" pdir top rel ref sha name tmpd
  _FELIX_POL_DIR="$proj"; _FELIX_POL_TMP=""; _FELIX_P_TREE=""; _FELIX_P_WORDS=""
  pdir="$(cd "$proj" 2>/dev/null && pwd -P)" || return 0
  top="$(git -C "$pdir" rev-parse --show-toplevel 2>/dev/null </dev/null)" || return 0
  top="$(cd "$top" 2>/dev/null && pwd -P)" || return 0
  case "$pdir" in "$top"/?*) rel="${pdir#"$top"/}" ;; *) return 0 ;; esac
  # Tracked there, or it is not that repository's policy: a home under a $HOME that is itself a
  # repository is a plain directory, and is read as one.
  [ -n "$(git -C "$top" ls-files -- "$rel" 2>/dev/null </dev/null | LC_ALL=C sed -n 1p)" ] || return 0
  if felix_same_repo "$top" "$root" 2>/dev/null; then
    ref="$base"
  else
    git -C "$top" rev-parse --verify --quiet refs/remotes/origin/main >/dev/null 2>&1 </dev/null || return 0
    ref=refs/remotes/origin/main
  fi
  sha="$(git -C "$top" rev-parse --verify --quiet "$ref^{commit}" 2>/dev/null </dev/null)"
  if [ -z "$sha" ]; then
    printf 'policy\ttable\t%s names no commit in %s, so no authorized policy judges this\n' "$ref" "$top"; return 1
  fi
  if [ "$(git -C "$top" cat-file -t "$sha:$rel" 2>/dev/null </dev/null)" != tree ]; then
    printf 'policy\ttable\t%s is not at %s, so no authorized policy judges this; the working tree does not stand in for it\n' "$rel" "$ref"; return 1
  fi
  tmpd="${TMPDIR:-/tmp}"
  _FELIX_POL_TMP="$(mktemp -d "${tmpd%/}/felix-policy.XXXXXX" 2>/dev/null)" || _FELIX_POL_TMP=""
  if [ -z "$_FELIX_POL_TMP" ]; then
    printf 'policy\tengine\tno directory could be made under %s for the policy snapshot, so nothing was read from %s\n' "${tmpd%/}" "$ref"; return 1
  fi
  name="${pdir##*/}"
  if ! _felix_policy_copy "$top" "$sha" "$rel" "$_FELIX_POL_TMP/p/$name"; then
    printf 'policy\tengine\tthe tables could not be copied out of %s, so nothing was read from it\n' "$ref"; return 1
  fi
  _FELIX_POL_DIR="$_FELIX_POL_TMP/p/$name"
  return 0
}

felix_policy_close() {
  [ -z "${_FELIX_POL_TMP:-}" ] || rm -rf "$_FELIX_POL_TMP"
  _FELIX_POL_TMP=""; _FELIX_POL_DIR=""; _FELIX_P_TREE=""; _FELIX_P_WORDS=""
}

# One awk for both jobs over a command: mode `list` prints each word that may name an instrument (in
# command position, or after an interpreter word, and plain enough to be a path); mode `rewrite` prints
# the command with each such word that is listed in WORDS replaced by the single-quoted path under TREE.
# Quotes are tracked: nothing inside one is a word, and a word that holds one is never replaced.
# Read through ENVIRON, never -v: -v takes no newline in BWK awk and reads a backslash as an escape.
_felix_p_scan() {   # MODE CMD [WORDS TREE]
  _FPS_M="$1" _FPS_S="$2" _FPS_W="${3:-}" _FPS_T="${4:-}" LC_ALL=C awk '
    function plain(w) { return w !~ /["'"'"'$\\*?[`]/ && w !~ /^[\/~-]/ && w !~ /(^|\/)\.\.(\/|$)/ && w != "" }
    function bare(w) { sub(/^\.\//, "", w); return w }
    BEGIN {
      mode = ENVIRON["_FPS_M"]; s = ENVIRON["_FPS_S"]; wl = ENVIRON["_FPS_W"]; tree = ENVIRON["_FPS_T"]
      nw = split(wl, arr, "\n"); for (k = 1; k <= nw; k++) if (arr[k] != "") listed[arr[k]] = 1
      split("then do else elif if while until ! time", rw, " "); for (k in rw) reserved[rw[k]] = 1
      split("bash sh zsh dash ksh python python3 perl ruby node . source exec", iw, " "); for (k in iw) interp[iw[k]] = 1
      n = length(s); out = ""; i = 1; cmd = 1; after = 0
      while (i <= n) {
        c = substr(s, i, 1)
        if (c == " " || c == "\t") { out = out c; i++; continue }
        if (index(";|&()`{}\n", c)) { out = out c; i++; if (c != ")" && c != "}") { cmd = 1; after = 0 }; continue }
        w = ""; q = 0
        while (i <= n) {
          c = substr(s, i, 1)
          if (c == "\047") { e = index(substr(s, i + 1), "\047"); if (!e) { w = w substr(s, i); i = n + 1; q = 1; break }
                             w = w substr(s, i, e + 1); i += e + 1; q = 1; continue }
          if (c == "\"") { j = i + 1
                           while (j <= n && substr(s, j, 1) != "\"") { if (substr(s, j, 1) == "\\") j++; j++ }
                           w = w substr(s, i, j - i + 1); i = j + 1; q = 1; continue }
          if (c == "\\") { w = w substr(s, i, 2); i += 2; q = 1; continue }
          if (c == " " || c == "\t" || index(";|&()`{}\n", c)) break
          w = w c; i++
        }
        r = w
        if (cmd && !q && w ~ /^[A-Za-z_][A-Za-z0-9_]*=/) { out = out w; continue }
        if (cmd && !q && (w in reserved)) { out = out w; continue }
        if (cmd && !q && (w in interp)) { out = out w; cmd = 0; after = 1; continue }
        if (after && !q && w ~ /^-/) { out = out w; continue }
        hit = (cmd && !q && plain(w) && index(bare(w), "/")) || (after && !q && plain(w))
        if (hit && mode == "list") print bare(w)
        if (hit && mode == "rewrite" && (bare(w) in listed)) r = "\047" tree "/" bare(w) "\047"
        out = out r; cmd = 0; after = 0
      }
      if (mode == "rewrite") printf "%s", out
    }'
}

# The instruments P's commands name: every such word P holds as a regular file in ROOT's repository at
# BASE, with its top-level directory (or itself, at the top) copied into the snapshot's tree. Sets
# _FELIX_P_TREE and _FELIX_P_WORDS. Returns 0, or prints one policy blocker line and returns 1.
felix_policy_instruments() {   # ROOT BASE
  local root="$1" base="$2" sha cmds w words="" tops="" t mode tmpd nl='
'
  [ -n "${_FELIX_POL_DIR:-}" ] || return 0
  sha="$(git -C "$root" rev-parse --verify --quiet "$base^{commit}" 2>/dev/null </dev/null)" || sha=""
  [ -n "$sha" ] || { printf 'policy\tengine\t%s names no commit here, so no instrument was taken from it\n' "$base"; return 1; }
  cmds="$( { [ -f "$_FELIX_POL_DIR/obligations.tsv" ] && LC_ALL=C grep -vE '^[[:space:]]*(#|$)' "$_FELIX_POL_DIR/obligations.tsv" | LC_ALL=C cut -f4,5
             [ -f "$_FELIX_POL_DIR/probes.tsv" ] && LC_ALL=C grep -vE '^[[:space:]]*(#|$)' "$_FELIX_POL_DIR/probes.tsv" | LC_ALL=C cut -f3,4,5
           } 2>/dev/null | LC_ALL=C tr '\t' '\n')"
  while IFS= read -r t; do
    [ -n "$t" ] && [ "$t" != "-" ] || continue
    while IFS= read -r w; do
      [ -n "$w" ] || continue
      case "$nl$words$nl" in *"$nl$w$nl"*) continue ;; esac
      mode="$(git -C "$root" ls-tree "$sha" -- "$w" 2>/dev/null </dev/null | LC_ALL=C awk -F'\t' -v p="$w" '$2 == p { split($1, m, " "); print m[1] " " m[2]; exit }')"
      case "$mode" in "100644 blob"|"100755 blob") ;; *) continue ;; esac
      words="${words:+$words$nl}$w"
      case "$w" in */*) t="${w%%/*}" ;; *) t="$w" ;; esac
      case "$nl$tops$nl" in *"$nl$t$nl"*) ;; *) tops="${tops:+$tops$nl}$t" ;; esac
    done <<EOF
$(_felix_p_scan list "$t")
EOF
  done <<EOF
$cmds
EOF
  [ -n "$words" ] || return 0
  # The instruments are the merged repository's, at BASE, wherever the tables came from: a home that
  # is a plain directory made no snapshot, and its commands still run P's scripts.
  if [ -z "${_FELIX_POL_TMP:-}" ]; then
    tmpd="${TMPDIR:-/tmp}"
    _FELIX_POL_TMP="$(mktemp -d "${tmpd%/}/felix-policy.XXXXXX" 2>/dev/null)" || _FELIX_POL_TMP=""
    [ -n "$_FELIX_POL_TMP" ] || { printf 'policy\tengine\tno directory could be made under %s for the instruments P names\n' "${tmpd%/}"; return 1; }
  fi
  case "$_FELIX_POL_TMP" in *"'"*) printf 'policy\tengine\tthe policy directory %s holds a quote, so no instrument can be named from it\n' "$_FELIX_POL_TMP"; return 1 ;; esac
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    _felix_policy_copy "$root" "$sha" "$t" "$_FELIX_POL_TMP/tree/$t" \
      || { printf 'policy\tengine\t%s could not be copied out of %s, so the instruments P names were not taken from P\n' "$t" "$base"; return 1; }
  done <<EOF
$tops
EOF
  _FELIX_P_TREE="$_FELIX_POL_TMP/tree"; _FELIX_P_WORDS="$words"
  return 0
}

# A P command as the merge boundary runs it: unchanged unless felix_policy_instruments named instruments.
_felix_p_cmd() {   # CMD
  if [ -n "${_FELIX_P_TREE:-}" ] && [ -n "${_FELIX_P_WORDS:-}" ]; then
    _felix_p_scan rewrite "$1" "$_FELIX_P_WORDS" "$_FELIX_P_TREE"
  else
    printf '%s' "$1"
  fi
}
