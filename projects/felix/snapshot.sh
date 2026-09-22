#!/usr/bin/env bash
# The public snapshot, as a command.
#
#   projects/felix/snapshot.sh [--source REF] [--base REF] [--public-readme]
#                              [--out DIR] [--public-clone DIR] [--ack FILE]
#                              [--message FILE] [--expect-tree TREE]
#
# The engine is published as LeavesJ/Felix, a snapshot with no history of its
# own, because this repository's history carries material that is not Felix's
# to publish (HANDOFF §0). The snapshot was made by hand three times and its
# rule lived in nobody's hands, which is how it fell twenty-two pull requests
# behind while the maintenance table read "Nothing due". The rule is this file
# now. HANDOFF §0bm has the derivation; the self-test below is its proof.
#
# In order, and never more: build the published set out of a commit with git
# archive, withhold consent, rewrite what names another project, audit the
# result with rules that share nothing with the rewrite, stage it onto a fresh
# clone of the public repository on a new branch, commit as the public author,
# run the suite and the credential scan on that exact commit, and print the push
# and pull request commands. It never pushes. The public main takes a merged
# pull request and nothing else, and a deny row refuses the push a session
# would otherwise try.
#
# Self-test. Each hand-made snapshot is reproduced byte for byte, compared by
# tree id, with the public README kept as it was then:
#   --source a3eee3c --base f6341ba --public-readme --expect-tree f5a4d6f
#   --source a8ab281 --base 3091a76 --public-readme --expect-tree 5455d56
#
# Published itself, deliberately. It names no other project: every name it
# rewrites or audits is derived at run time from this home's history, its
# projects/ directories, the memory root and the remotes their manifests
# declare, and a published file that carried them would be the leak it exists
# to prevent. Its literals are the public repository and the public author,
# both public already. It sits in projects/felix/, so every run audits it with
# the rest of the tree. Publishing it shows a stranger what is withheld and
# why, which is the claim the receipts make; withholding it would hide the
# method and not one name. What would reverse this: a literal here that the
# audit has to be told to ignore.
set -euo pipefail

PUBLIC_SLUG="LeavesJ/Felix"
PUBLIC_URL="https://github.com/$PUBLIC_SLUG.git"
AUTHOR_NAME="Jarron Deng"
AUTHOR_EMAIL="jarrondeng@gmail.com"
ORD=(another third fourth fifth sixth seventh eighth ninth tenth)
TAB="$(printf '\t')"

die() { printf 'snapshot: %s\n' "$1" >&2; shift; while [ $# -gt 0 ]; do printf '  %s\n' "$1" >&2; shift; done; exit 1; }
say() { printf '%s\n' "$*"; }
lc() { tr '[:upper:]' '[:lower:]'; }

HERE="$(cd "$(dirname "$0")" && pwd)"
SELF="$(basename "$HERE")"
SRC_REF="origin/main" BASE_REF="" PUBLIC_README=0 OUT="" PCLONE="" EXPECT="" MSGFILE=""
ACK="${FELIX_MEMORY:-$HOME/.felix/memory}/$SELF/snapshot-ack.tsv"
while [ $# -gt 0 ]; do
  case "$1" in
    --source|--base|--out|--public-clone|--ack|--message|--expect-tree)
      [ $# -ge 2 ] && [ -n "$2" ] || die "$1 needs a value"
      case "$1" in
        --source) SRC_REF=$2 ;; --base) BASE_REF=$2 ;; --out) OUT=$2 ;;
        --public-clone) PCLONE=$2 ;; --ack) ACK=$2 ;; --message) MSGFILE=$2 ;;
        --expect-tree) EXPECT=$2 ;;
      esac; shift 2 ;;
    --public-readme) PUBLIC_README=1; shift ;;
    -h|--help) sed -n '4,6p' "$0"; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done
[ -z "$MSGFILE" ] || [ -f "$MSGFILE" ] || die "no message file at $MSGFILE"
[ -z "$PCLONE" ] || git -C "$PCLONE" rev-parse --git-dir >/dev/null 2>&1 || die "$PCLONE is not a git repository"

# ------------------------------------------------------------- source ------
# The source is always a commit. git archive reads a commit and never a working
# tree, so a dirty checkout cannot leak into the build and is not refused. What
# is refused is a commit main never accepted: a snapshot of a branch would
# publish work no gate passed on main.
HOME_TOP="$(git -C "$HERE" rev-parse --show-toplevel)"
git -C "$HOME_TOP" fetch -q origin main || die "could not fetch the home's main, so nothing here can say what main is"
MAIN="$(git -C "$HOME_TOP" rev-parse --verify origin/main)"
SRC="$(git -C "$HOME_TOP" rev-parse --verify -q "$SRC_REF^{commit}")" || die "no commit named $SRC_REF"
git -C "$HOME_TOP" merge-base --is-ancestor "$SRC" "$MAIN" || die "$SRC_REF is not on the home's main ($MAIN)" "a snapshot publishes what main accepted, and nothing else"
# The home's own slug, read and never typed: it is the one remote this file may
# know, and the public copy of this file must refuse to run as if it were home.
slug_of() { sed -n 's/.*"remote_match"[^"]*"\([^"]*\)".*/\1/p' | head -1; }
HOME_SLUG="$(git -C "$HOME_TOP" show "$MAIN:projects/$SELF/project.json" | slug_of)"
[ -n "$HOME_SLUG" ] && [ "$HOME_SLUG" != "$PUBLIC_SLUG" ] || die "this is not the home (remote_match reads '${HOME_SLUG}')" "run it from the private checkout, never from the published copy"

if [ -z "$OUT" ]; then OUT="$(mktemp -d "${TMPDIR:-/tmp}/felix-snapshot.XXXXXX")"
else [ ! -e "$OUT" ] || [ -z "$(ls -A "$OUT")" ] || die "$OUT is not empty"; mkdir -p "$OUT"; fi
OUT="$(cd "$OUT" && pwd)"
RAW="$OUT/raw" B="$OUT/build" CLONE="$OUT/clone" V="$OUT/verify"

# ------------------------------------------------------------- names -------
# Two sets, and the difference between them is the lesson of the first
# snapshot. The scrub matched two spellings and a case-insensitive grep found a
# third; a fragment search found two more. So the set that is rewritten is not
# the set that is searched for, and the searched set is the wider one.
#
# SCRUB: every project that ever declared a manifest on the source's history,
# in the order each manifest first landed. The order hands out the tokens
# (another, third, ...), and a project retired later keeps its place, because
# renumbering would rewrite text that is already public.
SCRUB=()
while IFS= read -r n; do if [ -n "$n" ]; then SCRUB+=("$n"); fi; done <<EOF
$(git -C "$HOME_TOP" log --diff-filter=A --format='@%ct' --name-only "$SRC" -- 'projects/*/project.json' |
  awk -v self="$SELF" '/^@/ { t = substr($0, 2); next }
    /^projects\/[^\/]+\/project\.json$/ { split($0, p, "/"); if (p[2] != self) print t " " p[2] }' |
  sort -k1,1n -k2,2 | awk '!seen[$2]++ { print $2 }')
EOF
[ ${#SCRUB[@]} -le ${#ORD[@]} ] || die "more projects than tokens; extend ORD before publishing"

# AUDIT: the scrub set, plus every directory projects/ has ever held, every
# directory under projects/ in each checkout of the home on this disk (tracked
# or not: an untracked project is still somebody's name), the memory root's
# names that some checkout also gives a manifest (the suite's fixture names
# live there too and are the engine's own vocabulary), and each manifest's
# remote, whole, without separators and by its long components.
remote_forms() {
  sed 's|.*/||; s|\.git$||' | lc |
    awk -F'[-_. ]' 'NF { print; s = $0; gsub(/[-_. ]/, "", s); print s
                         for (i = 1; i <= NF; i++) if (length($i) >= 6) print $i }'
}
POINTER="${FELIX_HOME:-$(tr -d '[:space:]' 2>/dev/null < "$HOME/.felix-home" || true)}"
COMMON="$(git -C "$HOME_TOP" rev-parse --path-format=absolute --git-common-dir)"
ROOTS="$HOME_TOP${TAB}$(dirname "$COMMON")${TAB}$POINTER"
has_manifest() {
  local r; local IFS="$TAB"
  for r in $ROOTS; do [ -n "$r" ] && [ -f "$r/projects/$1/project.json" ] && return 0; done
  [ -n "$(git -C "$HOME_TOP" log -1 --format=%h "$SRC" -- "projects/$1/project.json")" ]
}
derive_audit() {
  local r d n; local IFS="$TAB"
  for n in ${SCRUB[@]+"${SCRUB[@]}"}; do printf '%s\n' "$n"; done
  git -C "$HOME_TOP" log --format= --name-only "$SRC" -- projects/ | awk -F/ 'NF > 2 { print $2 }'
  git -C "$HOME_TOP" log -p --format= "$SRC" -- 'projects/*/project.json' |
    sed -n 's/^[-+].*"remote_match"[^"]*"\([^"]*\)".*/\1/p' | remote_forms
  for r in $ROOTS; do
    [ -n "$r" ] && [ -d "$r/projects" ] || continue
    for d in "$r"/projects/*/; do
      [ -d "$d" ] || continue
      basename "$d"
      [ -f "$d/project.json" ] || continue
      sed -n 's/.*"name"[^"]*"\([^"]*\)".*/\1/p' "$d/project.json"
      slug_of < "$d/project.json" | remote_forms
    done
  done
  for d in "${FELIX_MEMORY:-$HOME/.felix/memory}"/*/; do
    [ -d "$d" ] || continue
    n="$(basename "$d")"; if has_manifest "$n"; then printf '%s\n' "$n"; fi
  done
}
home_base="$(printf '%s\n' "$HOME_SLUG" | remote_forms | head -2)"
AUDIT=()
while IFS= read -r n; do if [ -n "$n" ]; then AUDIT+=("$n"); fi; done <<EOF
$(derive_audit | lc | grep -vxF -e "$SELF" -e "$(printf '%s' "${PUBLIC_SLUG##*/}" | lc)" $(printf -- '-e %s ' $home_base) | awk 'length($0) >= 3' | sort -u || true)
EOF

# The audit's own patterns, built here and nowhere else. Case-insensitive, and
# three shapes: the name; the name in two halves of three or more characters
# with up to eight between (the name assembled from pieces); and the name with
# one character standing in, including an escaped character or a small bracket
# class (the regex fixture). Near the start of a name the stand-in must not be
# a space, or ordinary prose that shares four letters with a name would stop
# every build.
ere() { printf '%s' "$1" | sed 's/[][\.*^$+?(){}|]/\\&/g'; }
audit_patterns() {
  local n=$1 L=${#1} k
  ere "$n"; echo
  [ "$L" -ge 6 ] || return 0
  for ((k = 3; k <= L - 3; k++)); do printf '%s.{1,8}%s\n' "$(ere "${n:0:k}")" "$(ere "${n:k}")"; done
  for ((k = 1; k <= L - 2; k++)); do
    if [ "$k" -ge 3 ]; then printf '%s%s%s\n' "$(ere "${n:0:k}")" '(.|\\.|\[[^]]{1,4}\])' "$(ere "${n:k+1}")"
    elif [ $((L - k - 1)) -ge 3 ]; then printf '%s%s%s\n' "$(ere "${n:0:k}")" '[^[:space:]]' "$(ere "${n:k+1}")"; fi
  done
}
# path<TAB>line<TAB>name for every line of DIR an audit name reaches, once per line.
scan_names() {
  local n pf="$OUT/.patterns"
  for n in ${AUDIT[@]+"${AUDIT[@]}"}; do
    audit_patterns "$n" > "$pf"
    ( cd "$1" || exit 2; grep -rnHIiE -f "$pf" . || [ $? -eq 1 ] ) |
      awk -v n="$n" '{ i = index($0, ":"); p = substr($0, 3, i - 3); r = substr($0, i + 1)
                       print p "\t" substr(r, 1, index(r, ":") - 1) "\t" n }'
  done | awk -F'\t' '!seen[$1 FS $2]++'
  rm -f "$pf"
}
# The same shape for every address that is not the public author's and not on
# a domain reserved for examples. This machine's own address is the one this
# catches in practice: it is not the address the public commits carry.
scan_emails() {
  ( cd "$1" || exit 2; grep -rnHIE '@[A-Za-z0-9-]+\.' . || [ $? -eq 1 ] ) |
  awk -v me="$AUTHOR_EMAIL" '{
    i = index($0, ":"); p = substr($0, 3, i - 3); r = substr($0, i + 1); l = substr(r, 1, index(r, ":") - 1); t = r
    while (match(t, /[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z][A-Za-z]+/)) {
      e = tolower(substr(t, RSTART, RLENGTH)); t = substr(t, RSTART + RLENGTH); d = e; sub(/.*@/, "", d)
      if (e == me || d ~ /(^|\.)(example|invalid|test|localhost|local)$/ || d ~ /(^|\.)example\.(com|net|org)$/) continue
      print p "\t" l "\t@" e; break
    }
  }'
}
# Hits no acknowledgement covers. An acknowledgement is a row in $ACK, outside
# the published set because it carries names: path, the hash of the line as it
# stands, and why the line is not what the audit feared. Editing the line
# voids it. Nothing here writes that file; acknowledging is a judgment.
unacked() {
  local p l n h
  while IFS="$TAB" read -r p l n; do
    h="$(sed -n "${l}p" "$1/$p" | git hash-object --stdin)"
    if [ -f "$ACK" ] && grep -qF "$p$TAB$h$TAB" "$ACK"; then continue; fi
    printf '%s\t%s\t%s\t%s\n' "$p" "$l" "$n" "$h"
  done
}
show_hits() {  # DIR, on stdin the unacked rows
  local p l n h
  while IFS="$TAB" read -r p l n h; do
    printf '  %s:%s [%s] %s\n' "$p" "$l" "$n" "$(sed -n "${l}p" "$1/$p" | cut -c1-160)"
    printf '      ack: %s\\t%s\\t<why>\n' "$p" "$h"
  done
}

# ------------------------------------------------------------- build -------
# The published set, out of the commit, into a directory nothing else writes.
# The consent files are left out by pathspec, so nothing is deleted by hand.
PUB=""
for p in engine "projects/$SELF" .gitignore .claude-plugin/marketplace.json; do
  if git -C "$HOME_TOP" cat-file -e "$SRC:$p" 2>/dev/null; then PUB="$PUB $p"; fi
done
[ "$PUBLIC_README" -eq 1 ] || PUB="$PUB README.md"
archive_to() {
  mkdir -p "$1"
  # shellcheck disable=SC2086
  git -C "$HOME_TOP" archive "$SRC" -- $PUB ":(exclude)projects/$SELF/autonomy" ":(exclude)projects/$SELF/autonomy.commission" | tar -x -C "$1"
}
archive_to "$RAW"; archive_to "$B"

# Consent. The exception table ships only while it is the empty seed: a row in
# it is a person's grant, and a grant is not published. Named, and stopped.
EX="$B/projects/$SELF/exceptions.tsv" TPL="$B/engine/harness/templates/exceptions.tsv"
if [ -e "$EX" ]; then
  [ -e "$TPL" ] || die "projects/$SELF/exceptions.tsv ships with no template to judge it against"
  cmp -s "$EX" "$TPL" || die "projects/$SELF/exceptions.tsv holds what the template does not; a grant is a person's consent" \
    "$(diff "$TPL" "$EX" | sed -n 's/^> //p' | head -5)"
fi

# The remote, at the field. The home's slug also names the pointer file and a
# suite fixture, and a global rewrite of it breaks the engine.
perl -0pi -e 's/("remote_match"\s*:\s*")[^"]*(")/${1}LeavesJ\/Felix${2}/' "$B/projects/$SELF/project.json"
[ "$(slug_of < "$B/projects/$SELF/project.json")" = "$PUBLIC_SLUG" ] || die "remote_match was not rewritten"

# The scrub, per project in token order, and its order is load-bearing. A path
# first: a phrase with spaces inside a path under projects/ made `test -f` a
# usage error. The upper-case identifier next, or the prose rule would leave a
# phrase glued to an underscore. Then prose, any case, as one lower-case
# phrase. Then the pieces: a prefix of three or more and the rest, with a few
# characters between or one standing in, become the token's pieces.
# The text files are listed once. A list that comes back short leaves a name
# unrewritten, and the audit below stops on it, so a failure here is never silent.
find "$B" -type f -print0 | xargs -0 grep -lI --null '' > "$OUT/text.files" || true
i=0
for n in ${SCRUB[@]+"${SCRUB[@]}"}; do
  tok=${ORD[$i]}; i=$((i + 1))
  if [ "$tok" = another ]; then PH="another governed project"; else PH="a $tok governed project"; fi
  N="$n" T="$tok" UP="$(printf '%s' "$n" | tr '[:lower:]' '[:upper:]')"
  TUP="$(printf '%s' "$tok" | tr '[:lower:]' '[:upper:]')_PROJECT"
  export N T PH UP TUP
  xargs -0 perl -pi -e '
      s{projects/\Q$ENV{N}\E\b}{projects/$ENV{T}}g;
      s{\Q$ENV{UP}\E(?=_)}{$ENV{TUP}}g;
      s{\Q$ENV{N}\E}{$ENV{PH}}gi;
      my ($n, $t) = ($ENV{N}, $ENV{T}); my $L = length $n;
      for my $k (3 .. $L - 3) {
        my ($a, $b) = (substr($n, 0, $k), substr($n, $k));
        my ($ta, $tb) = (substr($t, 0, $k), $k < length $t ? substr($t, $k) : "");
        s{\Q$a\E(.{1,8}?)\Q$b\E}{$ta$1$tb}g;
      }
      for my $k (3 .. $L - 2) {
        my ($a, $c, $b) = (substr($n, 0, $k), substr($n, $k, 1), substr($n, $k + 1));
        my ($ta, $tb) = (substr($t, 0, $k), $k < length $t ? substr($t, $k) : "");
        s{\Q$a\E([^\Q$c\E])\Q$b\E}{$ta$1$tb}g;
      }' < "$OUT/text.files"
done

# ------------------------------------------------------------- audit -------
# Separate code from everything above, sharing none of its patterns.
#
# First, what the scrub touched. Every line it changed must be a line the
# audit reads a name on in the unscrubbed tree, and no file may change length.
# A scrub that rewrote anything else mangled text that was not a name, and
# nothing downstream would say so.
(cd "$RAW" && find . -type f | sed 's|^\./||' | sort) > "$OUT/files.raw"
(cd "$B" && find . -type f | sed 's|^\./||' | sort) > "$OUT/files.build"
cmp -s "$OUT/files.raw" "$OUT/files.build" || die "the scrub added or removed a file"
: > "$OUT/changed"
while IFS= read -r f; do
  cmp -s "$RAW/$f" "$B/$f" && continue
  [ "$(wc -l < "$RAW/$f")" -eq "$(wc -l < "$B/$f")" ] || die "the scrub changed the line count of $f"
  awk -v f="$f" 'NR == FNR { a[FNR] = $0; next } a[FNR] != $0 { print f "\t" FNR }' "$RAW/$f" "$B/$f" >> "$OUT/changed"
done < "$OUT/files.raw"
RM_LINE="projects/$SELF/project.json$TAB$(grep -n '"remote_match"' "$RAW/projects/$SELF/project.json" | cut -d: -f1)"
scan_names "$RAW" | cut -f1,2 | sort -u > "$OUT/flagged.raw"
stray="$(grep -vxF "$RM_LINE" "$OUT/changed" | sort -u | comm -23 - "$OUT/flagged.raw" || true)"
[ -z "$stray" ] || die "the scrub changed lines the audit reads no name on:" "$(printf '%s\n' "$stray" | tr '\t' ':')"
diff -ru "$RAW" "$B" > "$OUT/scrub.diff" || true

# Then what is left. Names, addresses and the shape of the tree.
{ scan_names "$B"; scan_emails "$B"; } > "$OUT/hits.all"
unacked "$B" < "$OUT/hits.all" > "$OUT/hits"
bad_shape=""
for e in $(ls -A "$B"); do case "$e" in engine|projects|.gitignore|.claude-plugin|README.md) ;; *) bad_shape="$bad_shape $e" ;; esac; done
for e in $(ls -A "$B/projects"); do [ "$e" = "$SELF" ] || bad_shape="$bad_shape projects/$e"; done
[ ! -d "$B/.claude-plugin" ] || for e in $(ls -A "$B/.claude-plugin"); do [ "$e" = marketplace.json ] || bad_shape="$bad_shape .claude-plugin/$e"; done
consent="$({ find "$B" \( -name autonomy -o -name autonomy.commission \) -print; find "$B/projects" -name 'autonomy*' -print; } | sed "s|^$B/||" | sort -u)"
rows=0; [ ! -f "$EX" ] || rows="$(grep -cvE '^[[:space:]]*(#|$)' "$EX" || true)"
if [ -s "$OUT/hits" ] || [ -n "$bad_shape" ] || [ -n "$consent" ] || [ "$rows" != 0 ]; then
  say "audit: STOP"
  [ ! -s "$OUT/hits" ] || { say "  lines naming a project or carrying an address, unacknowledged:"; show_hits "$B" < "$OUT/hits"; }
  [ -z "$bad_shape" ] || say "  outside the published set:$bad_shape"
  [ -z "$consent" ] || say "  consent files in the build: $consent"
  [ "$rows" = 0 ] || say "  exceptions.tsv holds $rows row(s)"
  say "  Read each line. One that is not what the audit feared is acknowledged by a row in $ACK."
  exit 1
fi
nack=$(wc -l < "$OUT/hits.all" | tr -d ' ')
say "audit: ${#AUDIT[@]} names derived, ${#SCRUB[@]} rewritten; $(wc -l < "$OUT/changed" | tr -d ' ') lines changed, each on a name; $nack acknowledged, none open; no consent file, no row"

# ------------------------------------------------------------- stage -------
# A fresh clone, never somebody's working copy, and a new branch. The staged
# paths are the published ones and nothing else: LICENSE and the public
# workflow live only there and survive because they are outside the pathspec,
# and a file the home removed is removed there. -f, because the home's ignore
# rules would silently drop a newly tracked file that one of them matches.
git clone -q "${PCLONE:-$PUBLIC_URL}" "$CLONE"
if [ -n "$BASE_REF" ]; then BASE="$(git -C "${PCLONE:-$CLONE}" rev-parse --verify "$BASE_REF^{commit}")"
elif [ -n "$PCLONE" ]; then BASE="$(git -C "$PCLONE" rev-parse --verify -q refs/remotes/origin/main || git -C "$PCLONE" rev-parse --verify HEAD)"
else BASE="$(git -C "$CLONE" rev-parse --verify refs/remotes/origin/main)"; fi
git -C "$CLONE" cat-file -e "$BASE^{commit}" || die "the public clone lacks $BASE"
taken() {
  git -C "$CLONE" rev-parse --verify -q "refs/remotes/origin/$1" >/dev/null && return 0
  [ -n "$PCLONE" ] && git -C "$PCLONE" rev-parse --verify -q "refs/remotes/origin/$1" >/dev/null
}
DAY="$(date +%Y-%m-%d)"; BR="snapshot/$DAY"; sfx=b
while taken "$BR"; do BR="snapshot/$DAY$sfx"; sfx="$(printf '%s' "$sfx" | tr 'a-y' 'b-z')"; done
git -C "$CLONE" checkout -q -b "$BR" "$BASE"
git -C "$CLONE" config user.name "$AUTHOR_NAME"
git -C "$CLONE" config user.email "$AUTHOR_EMAIL"
# The credential scan's baseline, read now, while the clone's files are the base's.
secrets() { (cd "$1" && "$B/engine/harness/bin/secret-scan" --tree 2>&1 >/dev/null || true) | sed -n 's/^  [0-9][0-9]*:+//p' | sort; }
[ -n "$EXPECT" ] || secrets "$CLONE" > "$OUT/secret.base"

STAGE="engine projects .gitignore .claude-plugin"; [ "$PUBLIC_README" -eq 1 ] || STAGE="$STAGE README.md"
# shellcheck disable=SC2086
(cd "$B" && git --git-dir="$CLONE/.git" --work-tree="$B" add -A -f -- $STAGE)
# shellcheck disable=SC2086
git -C "$CLONE" ls-files -- $STAGE | sort | cmp -s - "$OUT/files.build" || die "the staged paths are not the built tree"
outside="$(git -C "$CLONE" diff --cached --name-only "$BASE" | grep -vE '^(engine/|projects/|\.gitignore$|\.claude-plugin/|README\.md$)' || true)"
[ -z "$outside" ] || die "staging touched paths outside the published set:" $outside
if [ "$PUBLIC_README" -eq 1 ] && git -C "$CLONE" diff --cached --name-only "$BASE" | grep -qx README.md; then die "README.md changed with --public-readme"; fi

if [ -n "$EXPECT" ]; then
  got="$(git -C "$CLONE" write-tree)"
  want="$(git -C "$CLONE" rev-parse --verify -q "$EXPECT^{tree}" || printf '%s' "$EXPECT")"
  say "source $SRC  base $BASE"
  say "built tree    $got"
  say "expected tree $want"
  if [ "$got" = "$want" ]; then say "MATCH"; exit 0; fi
  say "DIFFER"; git -C "$CLONE" diff --stat "$want" "$got" | tail -20; exit 1
fi
[ -n "$(git -C "$CLONE" diff --cached --name-only "$BASE")" ] || die "nothing to publish: the public main already holds this tree"

# ------------------------------------------------------------- commit ------
ver_of() { sed -n 's/.*"version"[^"]*"\([^"]*\)".*/\1/p' | head -1; }
VER="$(ver_of < "$B/engine/.claude-plugin/plugin.json")"
PREV="$(git -C "$CLONE" show "$BASE:engine/.claude-plugin/plugin.json" 2>/dev/null | ver_of || true)"
SHORT="$(git -C "$HOME_TOP" rev-parse --short=12 "$SRC")"
MSG="$OUT/message.txt"
if [ -n "$MSGFILE" ]; then cp "$MSGFILE" "$MSG"; else
  {
    say "Engine $VER: the snapshot brought forward from ${PREV:-the last one}"
    say ""
    say "A snapshot of the engine as its home's main held it on $(git -C "$HOME_TOP" log -1 --format=%cd --date=short "$SRC")."
    say "The home stays private, so this arrives as one commit rather than the"
    say "pull requests it was built from. The paths it changes:"
    say ""
    git -C "$CLONE" diff --cached --name-status "$BASE" | sed 's/^/    /'
  } > "$MSG"
fi
grep -q "$SHORT" "$MSG" || printf '\nCut from the home'"'"'s main at %s.\n' "$SHORT" >> "$MSG"
grep -q '^Withheld, as before' "$MSG" || cat >> "$MSG" <<'EOF'

Withheld, as before: the autonomy grants, which are a person's consent and not
state, and every other governed project's doctrine. Their names are replaced
where the published files mention them, and an audit wider than the
replacement, a separate search, found none left.
EOF
audit_text() {  # FILE: the words that go public beside the tree, held to the same audit, no acknowledgements
  local d="$OUT/text.$$"; mkdir -p "$d"; cp "$1" "$d/"
  local h; h="$({ scan_names "$d"; scan_emails "$d"; })"; rm -rf "$d"
  [ -z "$h" ] || die "$(basename "$1") names a project or carries an address:" "$h"
}
audit_text "$MSG"
SUBJECT="$(head -1 "$MSG")"
env -u GIT_AUTHOR_NAME -u GIT_AUTHOR_EMAIL -u GIT_COMMITTER_NAME -u GIT_COMMITTER_EMAIL git -C "$CLONE" commit -q -F "$MSG"
who="$(git -C "$CLONE" log --format='%an <%ae> %cn <%ce>' "$BASE..HEAD" | sort -u)"
[ "$who" = "$AUTHOR_NAME <$AUTHOR_EMAIL> $AUTHOR_NAME <$AUTHOR_EMAIL>" ] || die "a commit carries an identity that is not the public author's:" "$who"

# ------------------------------------------------------------- verify ------
# The exact commit, in a clone of its own, so what is judged is what would be
# pushed and not the directory it was built in.
git clone -q --branch "$BR" "$CLONE" "$V"
[ "$(git -C "$V" rev-parse HEAD)" = "$(git -C "$CLONE" rev-parse HEAD)" ] || die "the verification clone is not the commit"
secrets "$V" > "$OUT/secret.new"
[ -s "$OUT/secret.new" ] || die "secret-scan found nothing, not even the suite's planted fixtures, so it read nothing"
fresh="$(comm -13 "$OUT/secret.base" "$OUT/secret.new")"
[ -z "$fresh" ] || die "secret-scan finds lines the public main does not carry:" "$fresh"
say "secret: $(wc -l < "$OUT/secret.new" | tr -d ' ') hits, every one also on the public main (planted fixtures); none new"
say "suite: running on $(git -C "$V" rev-parse --short HEAD), about ten minutes; log $OUT/suite.log"
( cd "$V/engine/harness" && ./tests/run > "$OUT/suite.log" 2>&1 ) && rc=0 || rc=$?
echo "exit=$rc" >> "$OUT/suite.log"
SUITE="$(grep -E '^[0-9]+ passed, [0-9]+ failed' "$OUT/suite.log" | tail -1 || true)"
[ "$rc" -eq 0 ] && printf '%s' "$SUITE" | grep -q ' 0 failed' || die "the suite did not pass on the snapshot (exit $rc): ${SUITE:-no summary}" "$(grep -A2 '^  FAIL' "$OUT/suite.log" | head -12)"
say "suite: $SUITE, exit 0"

# ------------------------------------------------------------- report ------
PR="$OUT/pr-body.md"
{
  sed '1,/^$/d' "$MSG"
  say ""
  say "Checks, run on this exact commit before it was pushed:"
  say "- suite: $SUITE, exit 0"
  say "- secret-scan --tree: $(wc -l < "$OUT/secret.new" | tr -d ' ') hits, each also on the public main; none new"
  say "- names: ${#AUDIT[@]} derived at run time and searched whole, in pieces and with a character standing in; none unacknowledged"
  say "- identity: every commit authored and committed as the public author; no other address in the tree"
  say "- consent: no autonomy file; the exception table is the empty template"
} > "$PR"
audit_text "$PR"
say ""
git -C "$CLONE" diff --stat=100 "$BASE" HEAD
say ""
say "Nothing was pushed. To publish, run:"
say "  git -C $CLONE push $PUBLIC_URL $BR"
say "  gh pr create --repo $PUBLIC_SLUG --base main --head $BR --title $(printf '%q' "$SUBJECT") --body-file $PR"
say "Merge it on green CI; the public main takes nothing else. Then, in the home:"
say "  felix maintenance --ran snapshot   and commit projects/$SELF/maintenance.log"
say ""
say "Withheld, and why:"
git -C "$HOME_TOP" ls-tree --name-only "$SRC" | while IFS= read -r e; do
  case "$e" in
    engine|.gitignore) ;;
    README.md) if [ "$PUBLIC_README" -eq 1 ]; then say "  README.md: the public one is kept (--public-readme)"; fi ;;
    .claude-plugin) n="$(git -C "$HOME_TOP" ls-tree --name-only "$SRC" .claude-plugin/ | grep -vc marketplace.json || true)"
      if [ "$n" != 0 ]; then say "  .claude-plugin/: $n file(s) besides the marketplace manifest, the only one a clone needs"; fi ;;
    projects) say "  projects/: $(git -C "$HOME_TOP" ls-tree -d --name-only "$SRC" projects/ | grep -vcx "projects/$SELF" || true) other director(ies), each another governed project's doctrine" ;;
    HANDOFF.md|docs) say "  $e: the home's own record, written for the people and sessions that work here" ;;
    .felix) say "  .felix: this checkout's binding to its project" ;;
    .github) say "  .github/: the home's workflows; the public repository keeps its own, outside the staged paths" ;;
    *) say "  $e: in no rule here; decide it before the next snapshot" ;;
  esac
done
say "  projects/$SELF/autonomy, autonomy.commission: a person's consent, and consent is not state"
say "  memory: never in the tree, so never in the build"
say "Kept from the public repository, outside the staged paths:"
git -C "$CLONE" ls-tree -r --name-only HEAD | grep -vE '^(engine/|projects/|\.gitignore$|\.claude-plugin/|README\.md$)' | sed 's/^/  /' || true
say "Scratch, unscrubbed where it says raw: $OUT"
