# >>> trust-resolver-unfinished-reads
printf '\ntrust plane step 1, the resolver: felix_resolve_project, felix_repo_root, _felix_resolve_remote, _felix_remote_slug, felix_binding_broken and felix_hook_dir say could not tell (spec section 5, properties 1-16, 22, 25-27; blind)\n'
# Blind, written on 2026-11-05 from .felix/memory/felix/audits/2026-10-31-trust-plane-replay/step1/spec.md (sections 0-8
# and the merge-judge item) and the P2 case's layouts and examples, before any fix. The expected values are the spec's
# "Must" column and its section 2 contracts; main's code was read for its interfaces only. Each engine function is run
# by the driver of tests/lib/trust-probes.sh (_trp_driver, _trp_drv): a fresh /bin/bash that sources lib/resolve.sh
# alone (own.sh too where a property needs the slug read wrapped), under set -u and -o pipefail, and passes the
# function's stdout and status through.
#
# Faults are bash functions of a command's name (_trp_arm, _trp_go), exported into the driver, acting only when their
# words and the calling functions match; or a wrapper of an engine function (TRP_WRAP) where the property names a whole
# read (the slug, felix_repo_root's outer substitution, a resolve inside the hook directory). Every fault assertion
# carries the probe's TRP_FIRE (or the wrapper's mark), so a probe that never acted fails the assertion instead of
# passing it. Readings where the spec leaves room:
# - "Unknown" for resolve is exit 2 with nothing on stdout (section 5's head); the clean answers are P2's examples.
# - F3 is the fork that fails in the shell that called the command (bash 3.2 ends that subshell with 128); the wrapper's
#   f3z is the substitution around a read that could not fork in the caller's own shell: nothing printed, status 0.
# - P10's "F3 at tr inside it" is the wrapper's f3: the process limit is lowered as felix_remote_github_slug starts in its
#   subshell, so the fork of its own tr pipe fails there, as the spec's R7 describes. Its F1 at tr is not asserted (L2).
# - P14's R2 alone can only fire where the walk finds no .git: it is run from a directory in no repository, whose clean
#   answer is none.
_lf_dir "$TMP/trust-2170"; TRA="$LF_DIR"
TRP_E="$FROOT/harness"
_trp_driver "$TRA/drv"
TRAL='marker remote nest tie badmarker none slug alphabet unread noorigin'
TRABAD=""
for _tra_l in $TRAL; do _trp_res "$TMP/trust-2170/$_tra_l" "$_tra_l" || TRABAD="$TRABAD $_tra_l"; done
# The other checkout P16 runs from: its origin is the one beta's remote_match names, while the none layout's is not.
_lf_init "$TRA/none/co/other" && printf 'other\n' > "$TRA/none/co/other/README" \
  && _lf_commit "$TRA/none/co/other" 1790000000 $'other\n' "=README" \
  && _lf_origin "$TRA/none/co/other" "https://git.example.org/acme/web.git" || TRABAD="$TRABAD other"
# The second checkout of alpha P25's payload names, bound by its own .felix.
_lf_checkout "$TRA/marker/co/res2" alpha || TRABAD="$TRABAD res2"
_trp_lib "$TRA/noown" own.sh && TRANOOWN="$TRP_LIBC" || TRABAD="$TRABAD noown"
_trp_lib "$TRA/nodetect" detect.sh && TRANODET="$TRP_LIBC" || TRABAD="$TRABAD nodetect"
is "P1 (fixture control): every resolver layout of P2 and this part's own (alphabet, unread, noorigin), the second checkouts and the two engine lib copies were built" \
   "${TRABAD:-built}" "built"

# LAYOUT -> the clean answer P2's examples give for resolve from LAYOUT's co/res/sub/dir, as _trp_rcls words it.
_tra_want() {
  case "$1" in
    marker|slug|alphabet) [ "$1" != alphabet ] || { printf 'found:%s' "$TRA/$1/felix-home/projects/alphabet"; return; }
                          printf 'found:%s' "$TRA/$1/felix-home/projects/alpha" ;;
    remote|nest) printf 'found:%s' "$TRA/$1/felix-home/projects/beta" ;;
    *) printf none ;;
  esac
}
# LAYOUT -> LF_RC and TRA/p.out|err: felix_resolve_project from LAYOUT's sub/dir, with whatever probes are armed (none
# when TRP_NAMES is empty). TRAC its class (_trp_rcls), TRAF the probe's mark ("clean" when no probe is armed).
_tra_res() {
  _trp_at "$TRA/$1"
  if [ -n "${TRP_NAMES:-}" ]; then _trp_go _trp_drv "$TRA/p" "$TRP_S" resolve "$TRP_S" "$TRP_H"; TRAF="$TRP_FIRE"
  else _trp_drv "$TRA/p" "$TRP_S" resolve "$TRP_S" "$TRP_H"; TRAF=clean; fi
  TRAC="$(_trp_rcls "$TRA/p")"
}
# LABEL LAYOUT ALTS MODE NAME WORDS STACK [NOT] -> one assertion: resolve from LAYOUT under one probe is one of ALTS, and
# the probe acted.
_tra_one() {
  local lab="$1" l="$2" alts="$3"
  shift 3
  _trp_new "$TRA/p.fired"; _trp_arm "$@" || { bad "$lab" "the probe could not be armed: $*"; return; }
  _tra_res "$l"
  is "$lab" "$(_trp_in "$TRAC" "$alts")|$TRAF" "ok|fired"
}
# LABEL LAYOUT ALTS WRAP MODE STACK [ARG1] [FROM] -> one assertion: resolve from LAYOUT (from FROM, LAYOUT's sub/dir by
# default) with the engine function WRAP wrapped (the driver's TRP_WRAP, own.sh sourced) is one of ALTS, and the wrapper
# acted.
_tra_wrap() {
  local lab="$1" l="$2" alts="$3" w="$4" m="$5" k="$6" a="${7-}" from="${8-}" f="$TRA/w.fired"
  rm -f "$f"; _trp_at "$TRA/$l"
  TRP_WRAP="$w" TRP_WMODE="$m" TRP_WSTACK="$k" TRP_WARG1="$a" TRP_WFILE="$f" TRP_OWN=1 \
    _trp_drv "$TRA/p" "${from:-$TRP_S}" resolve "$TRP_S" "$TRP_H"
  TRAC="$(_trp_rcls "$TRA/p")"
  is "$lab" "$(_trp_in "$TRAC" "$alts")|$(LC_ALL=C awk -v w="fired $w" '$0 == w { f = 1 } END { print (f ? "fired" : "not fired") }' "$f" 2>/dev/null)" "ok|fired"
}
TRP_NAMES=""

# --- P1 and P27: every P2 layout, no fault, gives the example; resolve.sh sourced alone loads felix_capture itself.
for _tra_l in marker remote nest tie badmarker none slug; do
  rm -f "$TRA/cap"; _trp_at "$TRA/$_tra_l"
  TRP_CAPF="$TRA/cap" _trp_drv "$TRA/p" "$TRP_S" resolve "$TRP_S" "$TRP_H"
  _tra_c="$(_trp_rcls "$TRA/p")"
  is "P1: felix_resolve_project from res layout $_tra_l's co/res/sub/dir, no fault, gives P2's example (found prints the project directory with no LF and exits 0; none prints nothing and exits 1)" \
     "$_tra_c" "$(_tra_want "$_tra_l")"
  is "P27: lib/resolve.sh sourced alone in a fresh /bin/bash, res layout $_tra_l, no fault: the example, and afterwards declare -F felix_capture succeeds (resolve.sh loaded detect.sh itself)" \
     "$_tra_c|$(cat "$TRA/cap" 2>/dev/null)" "$(_tra_want "$_tra_l")|defined"
done
_trp_at "$TRA/slug"
_trp_drv "$TRA/p" "$TRP_S" ghslug 'git@github.com:Acme/Web.git'
is "P1: felix_remote_github_slug on res-slug's origin git@github.com:Acme/Web.git gives P2's example: acme/web and a LF, exit 0" \
   "$(_trp_ro "$TRA/p")" "rc=0 out=[acme/web
]"
_trp_drv "$TRA/p" "$TRP_S" ghslug 'https://git.example.org/acme/web.git'
is "P1: felix_remote_github_slug on base's origin https://git.example.org/acme/web.git gives P2's example: nothing, exit 1" \
   "$(_trp_ro "$TRA/p")" "rc=1 out=[]"

# --- P2, P3: a marker read that did not finish.
for _tra_m in f1 f2 f3 f4; do
  _tra_one "P2: base (marker alpha, beta's remote_match also names the origin), $_tra_m at the marker's tr -d [:space:] inside felix_resolve_project: unknown (exit 2, nothing printed), never alpha, a prefix of it, beta or none" \
    marker unknown "$_tra_m" tr "*' -d [:space:] '*" "*' felix_resolve_project '*"
done
_tra_one "P3: the marker names alphabet, projects alpha and alphabet exist, the marker's tr prints its first five bytes (alpha) then exits 1: unknown, never .../projects/alpha" \
  alphabet unknown p5 tr "*' -d [:space:] '*" "*' felix_resolve_project '*"
TRP_NAMES=""; _tra_res alphabet
is "P3 (control): the alphabet layout, no fault: .../projects/alphabet, exit 0" "$TRAC" "$(_tra_want alphabet)"

# --- P4: a marker that cannot be opened names nothing, as main.
if [ "$(id -u)" = 0 ]; then
  skip "P4: base with the marker mode 000: resolve 1" "run as root, so mode 000 does not stop the read"
else
  TRP_NAMES=""; _tra_res unread
  is "P4: base with the marker mode 000 (not root): resolve exits 1 with nothing printed (an unreadable marker names nothing, as main and the lane)" "$TRAC" none
fi

# --- P5, P6: the origin read.
for _tra_m in f1 f127 f2 f3 f5; do
  _tra_one "P5: res-remote, $_tra_m at git remote get-url origin: unknown, never none (that read did not finish)" \
    remote unknown "$_tra_m" git "*' remote get-url origin '*" "*' felix_resolve_project '*"
done
TRP_NAMES=""; _tra_res noorigin
is "P6: res-remote's projects with no origin remote in the checkout, no fault: resolve exits 1, nothing printed (git's no such remote is a finished answer)" "$TRAC" none
_trp_at "$TRA/remote"; _trp_drv "$TRA/p" "$TRP_P" resolve "$TRP_P" "$TRP_H"
is "P6: outside any repository (a plain directory), no fault: resolve exits 1, nothing printed (git's not a repository is a finished answer)" "$(_trp_rcls "$TRA/p")" none

# --- P7, P8, P9: a remote_match unread.
for _tra_m in f1 f2 f3 f4; do
  _tra_one "P7: res-nest, $_tra_m at the sed that reads beta's project.json (the longest match): unknown, never alpha" \
    nest unknown "$_tra_m" sed "*remote_match*'/projects/beta/project.json '*" "*' felix_resolve_project '*"
  _tra_one "P7: res-nest, $_tra_m at the sed that reads alpha's project.json: unknown, never beta (the answer was not read whole)" \
    nest unknown "$_tra_m" sed "*remote_match*'/projects/alpha/project.json '*" "*' felix_resolve_project '*"
done
for _tra_m in f1 f2 f3; do
  for _tra_p in alpha beta; do
    _tra_one "P8: res-tie, $_tra_m at the sed that reads $_tra_p's project.json: unknown, never the other project" \
      tie unknown "$_tra_m" sed "*remote_match*'/projects/$_tra_p/project.json '*" "*' felix_resolve_project '*"
  done
  _tra_one "P9: res-none, $_tra_m at the sed that reads every project.json's remote_match: unknown, never none (an unread remote_match could have named the origin)" \
    none unknown "$_tra_m" sed "*remote_match*'/project.json '*" "*' felix_resolve_project '*"
done

# --- P10, P11: the GitHub slug.
for _tra_m in f2 f3z f5 f3; do
  case "$_tra_m" in
    f3z) _tra_w="F3 at the slug read (its substitution could not fork: nothing, status 0)" ;;
    f3)  _tra_w="F3 at tr inside it (the fork of its own pipe fails in its subshell)" ;;
    f2)  _tra_w="F2 at the slug read (137)" ;;
    *)   _tra_w="F5 at the slug read (exit 0, nothing printed, for a github.com URL)" ;;
  esac
  _tra_wrap "P10: res-slug, $_tra_w, felix_remote_github_slug wrapped as a whole: resolve unknown, never none, never gamma" \
    slug unknown felix_remote_github_slug "$_tra_m" '* _felix_remote_slug *'
done
_trp_at "$TRA/slug"; TRP_LIB="$TRANOOWN" _trp_drv "$TRA/p" "$TRP_S" resolve "$TRP_S" "$TRP_H"
is "P11: res-slug with lib/own.sh removed from the engine copy, no fault: resolve exits 1 with nothing printed (main's documented fallback: the owner/repo rule falls to its case-sensitive suffix)" \
   "$(_trp_rcls "$TRA/p")" none

# --- P12: _felix_remote_slug direct.
_trp_drv "$TRA/p" "$TRP_S" slug 'git@github.com:Acme/Web.git'
is "P12: _felix_remote_slug git@github.com:Acme/Web.git: status 0 and _FELIX_RS acme/web" "$(cat "$TRA/p.out")" "rc=0 rs=[acme/web]"
_trp_drv "$TRA/p" "$TRP_S" slug 'https://example.org/a/b'
is "P12: _felix_remote_slug https://example.org/a/b: status 0 and _FELIX_RS empty (not GitHub)" "$(cat "$TRA/p.out")" "rc=0 rs=[]"
for _tra_m in f2 f3z f3 f5; do
  rm -f "$TRA/w.fired"
  TRP_WRAP=felix_remote_github_slug TRP_WMODE="$_tra_m" TRP_WSTACK='* _felix_remote_slug *' TRP_WFILE="$TRA/w.fired" \
    _trp_drv "$TRA/p" "$TRP_S" slug 'git@github.com:Acme/Web.git'
  is "P12: _felix_remote_slug git@github.com:Acme/Web.git with $_tra_m at its read of felix_remote_github_slug: status 2 and _FELIX_RS empty (did not finish)" \
     "$(cat "$TRA/p.out")|$(cat "$TRA/w.fired" 2>/dev/null)" "rc=2 rs=[]|fired felix_remote_github_slug"
done

# --- P13: _felix_resolve_remote direct, from each layout's checkout root.
_tra_rr() { _trp_at "$TRA/$1"; if [ -n "${TRP_NAMES:-}" ]; then _trp_go _trp_drv "$TRA/p" "$TRP_CO" rr "$TRP_CO" "$TRP_H"; TRAF="$TRP_FIRE"
            else _trp_drv "$TRA/p" "$TRP_CO" rr "$TRP_CO" "$TRP_H"; TRAF=clean; fi; TRAC="$(cat "$TRA/p.out" 2>/dev/null)"; }
TRP_NAMES=""; _tra_rr remote
is "P13: _felix_resolve_remote on res-remote's root: status 0 and _FELIX_RB_P beta, _FELIX_RB_TIE empty" "$TRAC" "rc=0 p=[beta] tie=[]"
TRP_NAMES=""; _tra_rr tie
is "P13: _felix_resolve_remote on res-tie's root: status 2 (a tie)" "${TRAC%% *}" "rc=2"
TRP_NAMES=""; _tra_rr none
is "P13: _felix_resolve_remote on res-none's root: status 1 (none)" "${TRAC%% *}" "rc=1"
_trp_new "$TRA/p.fired"; _trp_arm f2 git "*' remote get-url origin '*" "*' _felix_resolve_remote '*"; _tra_rr remote
is "P13: _felix_resolve_remote on res-remote's root, F2 at its origin read (R5): status 3, _FELIX_RB_P and _FELIX_RB_TIE empty" "$TRAC|$TRAF" "rc=3 p=[] tie=[]|fired"
_trp_new "$TRA/p.fired"; _trp_arm f2 sed "*remote_match*'/project.json '*" "*' _felix_resolve_remote '*"; _tra_rr remote
is "P13: _felix_resolve_remote on res-remote's root, F2 at every remote_match read (R6): status 3, _FELIX_RB_P and _FELIX_RB_TIE empty" "$TRAC|$TRAF" "rc=3 p=[] tie=[]|fired"

# --- P14, P15: felix_repo_root's two reads.
for _tra_l in marker remote; do
  for _tra_m in f2 f3; do
    _trp_new "$TRA/p.fired"
    _trp_arm "$_tra_m" pwd "*' -P '*" "*' felix_repo_root '*"; _trp_arm "$_tra_m" git "*' rev-parse --show-toplevel '*" "*' felix_repo_root '*"
    _tra_res "$_tra_l"
    is "P14: $_tra_l, $_tra_m at the walk's pwd -P (R1) and at git rev-parse --show-toplevel (R2) together: resolve unknown, never another project, never none" \
       "$TRAC|$TRAF" "unknown|fired"
    _trp_new "$TRA/p.fired"; _trp_arm "$_tra_m" pwd "*' -P '*" "*' felix_repo_root '*"
    _tra_res "$_tra_l"
    is "P14: $_tra_l, $_tra_m at the walk's pwd -P (R1) alone, git left to find the root: resolve unknown or the clean answer, never another project, never none" \
       "$(_trp_in "$TRAC" "unknown|$(_tra_want "$_tra_l")")|$TRAF" "ok|fired"
  done
done
for _tra_m in f2 f3; do
  _trp_new "$TRA/p.fired"; _trp_arm "$_tra_m" git "*' rev-parse --show-toplevel '*" "*' felix_repo_root '*"
  _trp_at "$TRA/remote"; _trp_go _trp_drv "$TRA/p" "$TRP_P" resolve "$TRP_P" "$TRP_H"
  is "P14: a directory in no repository, $_tra_m at git rev-parse --show-toplevel (R2) alone, the walk having found no .git: resolve unknown or the clean answer (none), never a project" \
     "$(_trp_in "$(_trp_rcls "$TRA/p")" "unknown|none")|$TRP_FIRE" "ok|fired"
done
_trp_at "$TRA/marker"
_trp_drv "$TRA/p" "$TRP_S" root "$TRP_S"
is "P15: felix_repo_root from co/res/sub/dir, no fault: prints the checkout root, status 0" "$(_trp_ro "$TRA/p")" "rc=0 out=[$TRP_CO]"
_trp_new "$TRA/p.fired"; _trp_arm f3 pwd "*' -P '*" "*' felix_repo_root '*"; _trp_arm f3 git "*' rev-parse --show-toplevel '*" "*' felix_repo_root '*"
_trp_go _trp_drv "$TRA/p" "$TRP_S" root "$TRP_S"
is "P15: felix_repo_root from co/res/sub/dir, F3 at R1 and R2: prints exactly START (main's bytes) and returns 2" "$(_trp_ro "$TRA/p")|$TRP_FIRE" "rc=2 out=[$TRP_S]|fired"
_trp_drv "$TRA/p" "$TRP_P" root "$TRP_P"
is "P15: felix_repo_root from a directory in no repository, no fault: prints START, status 0" "$(_trp_ro "$TRA/p")" "rc=0 out=[$TRP_P]"

# --- P16: the outer substitution of felix_repo_root inside felix_resolve_project.
TRP_NAMES=""; _trp_at "$TRA/none"; _trp_drv "$TRA/p" "$TRA/none/co/other" resolve "$TRP_S" "$TRP_H"
is "P16 (control): START res-none's sub/dir, run from a checkout whose origin beta's remote_match names, no fault: none (START's origin decides, not the cwd's)" \
   "$(_trp_rcls "$TRA/p")" none
for _tra_m in f2 f3z; do
  _tra_wrap "P16: START res-none's sub/dir, run from a checkout whose origin beta names, $_tra_m at the outer substitution of felix_repo_root inside felix_resolve_project: unknown, never the cwd's project (beta)" \
    none unknown felix_repo_root "$_tra_m" '* felix_resolve_project *' "" "$TRA/none/co/other"
done

# --- P22: the home pointer read.
_trp_at "$TRA/marker"; printf '%s\n' "$TRP_H" > "$TRP_U/.felix-home"
TRP_NOHOME=1 _trp_drv "$TRA/p" "$TRP_S" broken "$TRP_S" "$TRP_H"
is "P22 (control): FELIX_HOME unset, ~/.felix-home naming the real home, base, no fault: felix_binding_broken prints nothing and returns 0 (not broken)" \
   "$(_trp_ro "$TRA/p")" "rc=0 out=[]"
for _tra_m in f2 f3; do
  _trp_new "$TRA/p.fired"; _trp_arm "$_tra_m" cat "*'/.felix-home '*" "*' _felix_home_pointer '*"
  TRP_NOHOME=1 _trp_go _trp_drv "$TRA/p" "$TRP_S" broken "$TRP_S" "$TRP_H"
  is "P22: FELIX_HOME unset, ~/.felix-home naming the real home, $_tra_m at the cat of it: felix_binding_broken prints nothing and returns 2, never \"is empty, so it names no home\"" \
     "$(_trp_ro "$TRA/p")|$TRP_FIRE" "rc=2 out=[]|fired"
done
rm -f "$TRP_U/.felix-home"

# --- P25: the hook directory.
_trp_at "$TRA/marker"
TRAPL="{\"session_id\":\"t\",\"cwd\":\"$TRP_FX/co/res2\"}"
_trp_drv "$TRA/p" "$TRP_CO" hookdir "$TRAPL" "$TRP_H"
is "P25 (control): felix_hook_dir run from base's checkout, the payload's cwd another checkout of alpha, no fault: prints the payload's cwd, status 0 (the hook moves there)" \
   "$(_trp_ro "$TRA/p")" "rc=0 out=[$TRP_FX/co/res2]"
for _tra_m in f3 f3z; do
  for _tra_a in "$TRP_FX/co/res2" "$TRP_CO"; do
    case "$_tra_a" in "$TRP_CO") _tra_w="the launch directory's resolve" ;; *) _tra_w="the payload cwd's resolve" ;; esac
    rm -f "$TRA/w.fired"
    TRP_WRAP=felix_resolve_project TRP_WMODE="$_tra_m" TRP_WSTACK='* _felix_hook_dir_set *' TRP_WARG1="$_tra_a" TRP_WFILE="$TRA/w.fired" \
      _trp_drv "$TRA/p" "$TRP_CO" hookdir "$TRAPL" "$TRP_H"
    is "P25: felix_hook_dir, the payload's cwd another checkout of the same project, $_tra_m at $_tra_w: prints \$PWD (stays where the platform started the hook), status 0" \
       "$(_trp_ro "$TRA/p")|$(cat "$TRA/w.fired" 2>/dev/null)" "rc=0 out=[$TRP_CO]|fired felix_resolve_project"
  done
done

# --- P26: felix_capture cannot be loaded.
for _tra_l in marker remote nest tie badmarker none slug; do
  _trp_at "$TRA/$_tra_l"; TRP_LIB="$TRANODET" _trp_drv "$TRA/p" "$TRP_S" resolve "$TRP_S" "$TRP_H"
  is "P26: resolve.sh sourced in a fresh shell from a directory holding no detect.sh (felix_capture unloadable), res layout $_tra_l, no fault: unknown, never found, never 1" \
     "$(_trp_rcls "$TRA/p")" unknown
done
_trp_at "$TRA/marker"; TRP_LIB="$TRANODET" _trp_drv "$TRA/p" "$TRP_S" root "$TRP_S"
is "P26: felix_repo_root with felix_capture unloadable, from co/res/sub/dir: still prints main's bytes (the checkout root) and returns 2" \
   "$(_trp_ro "$TRA/p")" "rc=2 out=[$TRP_CO]"
TRP_NAMES=""
# <<< trust-resolver-unfinished-reads
