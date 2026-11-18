# >>> trust-step4-setup-hardening-engine
printf '\ntrust plane step 4, the setup slice hardened: what authority-engine reads of the git it trusts and of the home it writes in (spec H1 to H4, H7, H8; blind)\n'
# Blind, written on 2026-11-16 from .felix/memory/felix/audits/2026-11-16-trust-step4-setup-hardening/spec.md (rev 1)
# alone (sections 0, 1, 3 and 5), with the setup slice's spec (rev 3, sections 0, 1, 2 and 4), before the fix existed,
# by an author who has read no engine code. Of bin/authority-engine this relies on one line, the seam section 5 quotes.
# The helpers are tests/lib/trust-step4.sh and tests/lib/trust-step4-setup.sh, whose _ts4u_g0 reads a git as E2, H1 and
# H2 say and whose _ts4u_e2 now rests on it. Everything is under $TMP/ts4-harden-engine; each HOME given to
# authority-engine is a directory there. The program is run with /bin/bash, as the test's own login.
#
# The fixture: a bare source whose one commit K1 holds part 2191's small engine (_ts4u_small), bundled. Seam copies of
# bin/authority-engine, in each of which the seam line is replaced whole by "  _AE_GIT=FIXTURE", and each assertion on a
# copy also reads that exactly one line was replaced and nothing else differs. FIXTURE is: the git E2 names here; a hard
# link to it at hl/usr/bin/git, a directory of this login's, beside hl/usr/libexec/git-core/git, a program of this
# login's that marks that it ran and runs the real git; that git named through x/gup, a link of this login's to the
# directory two above it; and, on macOS, /usr/bin/git. HOMEs for H3 under h3/, staged before any is run; for H8, h8/.
#
# Readings, where the spec leaves room:
# - H1's and H2's refusal is E2's line and writes no copy and no launcher (as part 2191 reads E7 and E8); whether
#   H/.felix is made before the git is read is not said, so it is not matched. H3's refusal writes nothing in HOME: it
#   comes "before anything is made".
# - H2 in the direction tests can show: this test reads the git E2 names here, its exec path, each directory above that
#   and each path under it (find and find -L) before it asserts, and a run with it succeeds. On macOS /usr/bin/git is a
#   file only root can change in directories only root can change, and runs the git xcode-select points at: where this
#   test reads that git's exec path as one H2 refuses (on this Mac it is under /Applications, root and group admin, mode
#   775), the seam copy naming /usr/bin/git must be refused with E2's line. It runs with DEVELOPER_DIR unset, so that
#   xcode-select decides, as it does under the env -i of this test's reading.
# - H2's "each path under X, read as itself": a link's owner and entries, not its mode bits, which grant nothing (on
#   Linux they are always rwxrwxrwx); through the link, what it points at, its entries read at its physical path.
# - H3's walk is from H's parent up, nearest first, along the path as written and then the physical one. A link on the
#   way as written is this login's; its own mode is 755 on macOS and 777 on Linux, and whether a link above H is read as
#   itself or as its target is not said, so off macOS either that link or the directory past it may be named.
# - H8's lists are made with setfacl -m u:65534:---, an entry that leaves the mode bits as they were, so only the + of
#   ls -ld shows it.
#
# Not covered: H1's refusal of a git whose own file, or a directory above it, carries an entry that allows, or is root's
# and writable by every login with the sticky bit (each needs root to make); H3's HOME owned by another uid, H4 and H7
# (a file or directory owned by another uid needs root: each is a skip that says so); H8 where ls takes -e; section 4's
# open items (the dynamic loader's paths, who the login is, a link under the exec path that points outside it).
# Added after the build review (spec rev 2, the builder's): H1's walk is shadowed by H2 here, since this git finds
# its exec path beside the file it was run as, so every H1 fixture is refused by H2's same line too; and H2's
# nested links (a link inside a directory a link under X points at) have no fixture under the real X.
_ts4u_begin ts4-harden-engine
TS4H_X="$TS4/x"; TS4H_S="$TS4/src.git"; TS4H_B="$TS4/src.bundle"; TS4H_D="$TS4/h3"
TS4H_SEAM='  if [ "$_AE_OS" = Darwin ]; then _AE_GIT=/Library/Developer/CommandLineTools/usr/bin/git; else _AE_GIT=/usr/bin/git; fi'
TS4H_FIT="replaced: 1; lines that differ: 1; lines more or less: 0"
mkdir -p "$TS4/h" "$TS4H_D" "$TS4/h8"; chmod 755 "$TS4/h" "$TS4H_D" "$TS4/h8"
_ts4_src "$TS4H_S"; _ts4u_small "$TS4H_S" one 9.8.7; _ts4u_seal "$TS4H_S" main "small engine one$TS4_NL"; TS4H_K1="$TS4_C"
_fx_git "$TS4H_S" bundle create -q "$TS4H_B" --all >/dev/null 2>&1
TS4H_E2="$(_ts4u_e2)"; TS4H_G0="$(_ts4u_g0 "$TS4U_GIT")"; TS4H_XP="$(_ts4u_xp "$TS4U_GIT")"

# ------------------------------------------------------------------ helpers ---
_ts4h_seam() {   # FIXTURE FILE: FILE is bin/authority-engine with each line that is the seam replaced by "  _AE_GIT=FIXTURE", and
                 # FILE.n how many were
  L="$TS4H_SEAM" N="  _AE_GIT=$1" F="$2.n" LC_ALL=C awk '$0 == ENVIRON["L"] { print ENVIRON["N"]; n++; next } { print } END { print (n + 0) > ENVIRON["F"] }' "$TS4U_AE" > "$2" 2>/dev/null
}
_ts4h_fit() {   # FILE: how many lines _ts4h_seam replaced, and, read back, how many lines differ from bin/authority-engine and how many
                # one of the two holds more
  printf 'replaced: %s; ' "$(cat "$1.n" 2>/dev/null)"
  LC_ALL=C awk -v b="$1" '{ if ((getline l < b) > 0) { if (l != $0) d++ } else m++ } END { while ((getline l < b) > 0) m++; printf "lines that differ: %d; lines more or less: %d", d, m }' "$TS4U_AE" 2>/dev/null
}
_ts4h_ae() { local k="$TS4U_AE"; TS4U_AE="$1"; shift; _ts4u_ae "$@"; TS4U_AE="$k"; }   # PROGRAM HOME ARG...: as _ts4u_ae, of PROGRAM
_ts4h_got() { if [ "$TS4_RC" = 0 ]; then printf 'exit 0; %s' "$(_ts4_line 'engine: ' "$TS4/o")"; else _ts4u_ref; fi; }   # the last run, read as _ts4h_ok reads
_ts4h_ok() { if [ "$TS4H_E2" = takes ]; then printf 'exit 0; engine: %s' "$TS4H_K1"; else printf 'exit 1; stderr: %s' "$TS4H_E2"; fi; }   # a run of K1 with the git E2 names
_ts4h_wrote() { printf 'copy: %s; launcher: %s' "$(_ts4_yn test -e "$1/.felix/engine/$TS4H_K1")" "$(_ts4_yn test -e "$1/.felix/bin/felix")"; }   # HOME
_ts4h_own() { ls -ldn "$1" 2>/dev/null | U="$TS4U_UID" LC_ALL=C awk 'NR == 1 { o = ($3 == ENVIRON["U"]) ? "this login\047s" : ($3 == 0 ? "root\047s" : "another\047s") } END { printf "%s", (NR ? o : "absent") }'; }   # PATH, as itself
_ts4h_h3() {   # WHAT HOME P: with that HOME, authority-engine K1 is refused by H3 naming P, and nothing in HOME is written
  local s; s="$(_ts4_snap "$2")"; _ts4u_ae "$2" "$TS4H_K1" "$TS4H_B"
  if [ "$(_ts4_snap "$2")" = "$s" ]; then s=unchanged; else s=changed; fi
  _ts4_is "ts4 harden H3: authority-engine refuses $1, and writes nothing in HOME" "$(_ts4u_ref); home: $s" \
    "exit 1; stderr: authority-engine: $3 can be written by another login; home: unchanged" "$(_ts4_why)"
}
_ts4h_h3ok() {   # WHAT HOME: with that HOME, authority-engine K1 is not refused by H3: it makes the copy and the launchers
  _ts4u_ae "$2" "$TS4H_K1" "$TS4H_B"
  _ts4_is "ts4 harden H3 (allowance): $1" "exit $TS4_RC; $(_ts4_line 'state: ' "$TS4/o"); $(_ts4h_wrote "$2")" "exit 0; state: made; copy: yes; launcher: yes" "$(_ts4_why)"
}

# ------------------------------------------------------------------ controls, and the git E2 names here (H1, H2) ---
is "ts4 harden engine (control): the fixture source's commit K1 holds the small engine, seven entries under engine/, and its bundle lists main at K1" \
  "$(_ts4u_entries "$TS4H_S" "$TS4H_K1") $(_fx_git "$TS4H_X" bundle list-heads "$TS4H_B" 2>/dev/null | LC_ALL=C awk '$2 == "refs/heads/main" { print $1 }')" "7 $TS4H_K1"
_ts4h_seam "$TS4U_GIT" "$TS4H_X/ae-real"
is "ts4 harden H1 (control): bin/authority-engine holds the seam line section 5 quotes once, and the seam copy differs from it in that one line alone" \
  "$(_ts4h_fit "$TS4H_X/ae-real")" "$TS4H_FIT"
mkdir -p "$TS4/h/a" "$TS4/h/b"; _ts4u_ae "$TS4/h/a" "$TS4H_K1" "$TS4H_B"; TS4H_RA="$(_ts4h_got)"
_ts4_is "ts4 harden H1 (control): the unchanged program takes a commit of the fixture source with the git E2 names here, where this test reads that git as one E2, H1 and H2 take, and refuses it with E2's line where it does not" \
  "$TS4H_RA" "$(_ts4h_ok)" "$(_ts4_why)"
_ts4h_ae "$TS4H_X/ae-real" "$TS4/h/b" "$TS4H_K1" "$TS4H_B"
_ts4_is "ts4 harden H1 (control): the seam copy naming that same git does the same" "$(_ts4h_fit "$TS4H_X/ae-real"); $(_ts4h_got)" "$TS4H_FIT; $(_ts4h_ok)" "$(_ts4_why)"
TS4H_N="ts4 harden H2 (allowance): the exec path the git E2 names here prints under E3's environment is an absolute path to a directory that this test reads as only root's, with each directory above it and each path under it at every depth, as itself and through links; and the run with that git succeeded"
if [ "$TS4H_G0" = takes ]; then
  _ts4_is "$TS4H_N" "exec path: $(case "$TS4H_XP" in (/*) printf 'an absolute directory' ;; (*) printf none ;; esac); reading: $TS4H_G0; run: $TS4H_RA" \
    "exec path: an absolute directory; reading: takes; run: exit 0; engine: $TS4H_K1"
else
  skip "$TS4H_N" "this test reads the git E2 names here otherwise ($TS4H_G0), so H2's allowance is not shown here"
fi

# ------------------------------------------------------------------ H1: a hard link to that git, in a directory of this login's ---
TS4H_HL="$TS4/hl/usr/bin/git"; mkdir -p "$TS4/hl/usr/bin" "$TS4/hl/usr/libexec/git-core"
chmod 755 "$TS4/hl" "$TS4/hl/usr" "$TS4/hl/usr/bin" "$TS4/hl/usr/libexec" "$TS4/hl/usr/libexec/git-core"
printf '#!/bin/sh\n: > "%s"\nexec "%s" "$@"\n' "$TS4H_X/helper.ran" "$TS4U_GIT" > "$TS4/hl/usr/libexec/git-core/git"; chmod 755 "$TS4/hl/usr/libexec/git-core/git"
TS4H_HLW=""; ln "$TS4U_GIT" "$TS4H_HL" 2> "$TS4H_X/ln.err" || TS4H_HLW="$(_ts4_flat < "$TS4H_X/ln.err")"
if [ -n "$TS4H_HLW" ]; then
  if [ "$(cat /proc/sys/fs/protected_hardlinks 2>/dev/null)" = 1 ]; then TS4H_HLW="Linux's protected_hardlinks is 1, so no hard link to a file this login does not own can be made (ln: $TS4H_HLW)"
  else TS4H_HLW="no hard link to $TS4U_GIT could be made in the fixture (ln: $TS4H_HLW)"; fi
fi
TS4H_N="ts4 harden H1 (control): the hard link is the git E2 names, the same file, root's and written by no group or other, in a directory this login owns; on macOS it prints, for --exec-path, the directory beside it"
TS4H_N2="ts4 harden H1: the seam copy refuses a hard link to the git E2 names made in a directory of this login's, a file only root can change in a directory that is not, with E2's line, writes no copy and no launcher, and runs nothing of the exec path beside it"
if [ -n "$TS4H_HLW" ]; then
  skip "$TS4H_N" "$TS4H_HLW"; skip "$TS4H_N2" "$TS4H_HLW"
else
  TS4H_V=""; TS4H_W=""
  if [ "$TS4U_OS" = Darwin ]; then TS4H_V="; exec path: $(_ts4u_xp "$TS4H_HL")"; TS4H_W="; exec path: $TS4/hl/usr/libexec/git-core"; fi
  is "$TS4H_N" "same file: $(_ts4_yn test "$TS4H_HL" -ef "$TS4U_GIT"); a link: $(_ts4_yn test -L "$TS4H_HL"); the file: $(_ts4h_own "$TS4H_HL"), $(_ts4_mode "$TS4H_HL" | cut -c6,9); its directory: $(_ts4h_own "$TS4/hl/usr/bin")$TS4H_V" \
    "same file: yes; a link: no; the file: root's, --; its directory: this login's$TS4H_W"
  _ts4h_seam "$TS4H_HL" "$TS4H_X/ae-hl"; mkdir -p "$TS4/h/hl"; rm -f "$TS4H_X/helper.ran"; _ts4h_ae "$TS4H_X/ae-hl" "$TS4/h/hl" "$TS4H_K1" "$TS4H_B"
  _ts4_is "$TS4H_N2" "$(_ts4h_fit "$TS4H_X/ae-hl"); $(_ts4u_ref); $(_ts4h_wrote "$TS4/h/hl"); helper ran: $(_ts4_yn test -e "$TS4H_X/helper.ran")" \
    "$TS4H_FIT; exit 1; stderr: authority-engine: $TS4H_HL is not a git only root can change; copy: no; launcher: no; helper ran: no" "$(_ts4_why)"
fi
rm -f "$TS4H_HL"

# ------------------------------------------------------------------ H1: that git named through a link of this login's above its directory ---
# x/gup is a link to the directory two above the git (.../usr), so that the git's own directory, as written, is root's
# and a directory, and only a directory further up, x/gup itself and x, is not.
TS4H_GL="$TS4H_X/gup/${TS4U_GIT#"${TS4U_GIT%/*/*}/"}"; ln -s "${TS4U_GIT%/*/*}" "$TS4H_X/gup" 2>/dev/null
is "ts4 harden H1 (control): through x/gup, a link this login owns to the directory two above the git E2 names, that git is a regular file of root's, not itself a link, and its directory as written is a directory of root's, not a link" \
  "x/gup: $(_ts4_yn test -L "$TS4H_X/gup"), $(_ts4h_own "$TS4H_X/gup"); the git: a file $(_ts4_yn test -f "$TS4H_GL"), a link $(_ts4_yn test -L "$TS4H_GL"), $(_ts4h_own "$TS4H_GL"); its directory: a link $(_ts4_yn test -L "${TS4H_GL%/*}"), $(_ts4_mode "${TS4H_GL%/*}" | cut -c1), $(_ts4h_own "${TS4H_GL%/*}")" \
  "x/gup: yes, this login's; the git: a file yes, a link no, root's; its directory: a link no, d, root's"
_ts4h_seam "$TS4H_GL" "$TS4H_X/ae-gl"; mkdir -p "$TS4/h/gl"; _ts4h_ae "$TS4H_X/ae-gl" "$TS4/h/gl" "$TS4H_K1" "$TS4H_B"
_ts4_is "ts4 harden H1: the seam copy refuses that git named through a link of this login's above its directory, along the path as written, with E2's line, and writes no copy and no launcher" \
  "$(_ts4h_fit "$TS4H_X/ae-gl"); $(_ts4u_ref); $(_ts4h_wrote "$TS4/h/gl")" "$TS4H_FIT; exit 1; stderr: authority-engine: $TS4H_GL is not a git only root can change; copy: no; launcher: no" "$(_ts4_why)"
rm -f "$TS4H_X/gup"

# ------------------------------------------------------------------ H2: /usr/bin/git, on macOS ---
TS4H_N="ts4 harden H2 (control): on macOS, this test reads /usr/bin/git as a file E2 and H1 take, and the exec path it prints, as the git xcode-select points at prints it, as one H2 refuses"
TS4H_N2="ts4 harden H2: on macOS, the seam copy refuses /usr/bin/git, whose exec path is one H2 refuses, with E2's line, and writes no copy and no launcher"
if [ "$TS4U_OS" != Darwin ]; then
  skip "$TS4H_N" "this is not macOS, where alone /usr/bin/git runs another git, the one xcode-select points at"; skip "$TS4H_N2" "this is not macOS"
else
  TS4H_V="$(_ts4u_g0 /usr/bin/git)"
  case "$TS4H_V" in
    H2:*)
      is "$TS4H_N" "${TS4H_V%%:*}" H2
      _ts4h_seam /usr/bin/git "$TS4H_X/ae-ub"; mkdir -p "$TS4/h/ub"; TS4U_UN=(-u DEVELOPER_DIR); _ts4h_ae "$TS4H_X/ae-ub" "$TS4/h/ub" "$TS4H_K1" "$TS4H_B"; TS4U_UN=()
      _ts4_is "$TS4H_N2" "$(_ts4h_fit "$TS4H_X/ae-ub"); $(_ts4u_ref); $(_ts4h_wrote "$TS4/h/ub")" \
        "$TS4H_FIT; exit 1; stderr: authority-engine: /usr/bin/git is not a git only root can change; copy: no; launcher: no" "$(_ts4_why); this test read: $TS4H_V" ;;
    takes)
      TS4H_W="xcode-select points at a git whose exec path ($(_ts4u_xp /usr/bin/git)) this test reads as only root's"; skip "$TS4H_N" "$TS4H_W"; skip "$TS4H_N2" "$TS4H_W" ;;
    *)
      TS4H_W="this test reads /usr/bin/git as one E2 or H1 refuses here ($TS4H_V), so H2 is not reached"; skip "$TS4H_N" "$TS4H_W"; skip "$TS4H_N2" "$TS4H_W" ;;
  esac
fi

# ------------------------------------------------------------------ H3: HOME and the directories above it ---
if [ "$TS4U_UID" = 0 ]; then TS4_SKIP="this test runs as uid 0, which E6 refuses at once"
elif [ "$TS4H_G0" != takes ]; then TS4_SKIP="the git E2 names is not one E2, H1 and H2 take here ($TS4H_G0), so no run here reaches HOME"; fi
mkdir -p "$TS4H_D/a/w/home" "$TS4H_D/b" "$TS4H_D/c" "$TS4H_D/d" "$TS4H_D/g/w/home" "$TS4H_D/h/w1/w2/home" "$TS4H_D/i/home" "$TS4H_D/j/p/real/home" "$TS4H_D/s/st/home"
chmod 755 "$TS4H_D/a" "$TS4H_D/a/w/home" "$TS4H_D/g" "$TS4H_D/h" "$TS4H_D/h/w1/w2/home" "$TS4H_D/i" "$TS4H_D/j" "$TS4H_D/j/p/real" "$TS4H_D/j/p/real/home" "$TS4H_D/s" "$TS4H_D/s/st/home"
chmod 777 "$TS4H_D/a/w" "$TS4H_D/g/w" "$TS4H_D/h/w1" "$TS4H_D/h/w1/w2" "$TS4H_D/j/p"; chmod 775 "$TS4H_D/b" "$TS4H_D/g/w/home" "$TS4H_D/i/home"
chmod 757 "$TS4H_D/c"; chmod 1777 "$TS4H_D/d" "$TS4H_D/s/st"; : > "$TS4H_D/i/home/.felix"; chmod 644 "$TS4H_D/i/home/.felix"; ln -s "$TS4H_D/j/p/real" "$TS4H_D/j/lnk" 2>/dev/null
is "ts4 harden H3 (control): the homes and the directories above them are staged with the modes their cases name" \
  "$(for TS4H_V in a/w a/w/home b c d g/w g/w/home h/w1 h/w1/w2 h/w1/w2/home i/home i/home/.felix j/p j/p/real/home s/st s/st/home; do printf '%s ' "$(_ts4u_m "$TS4H_D/$TS4H_V")"; done)j/lnk: $(_ts4_yn test -L "$TS4H_D/j/lnk")" \
  "drwxrwxrwx drwxr-xr-x drwxrwxr-x drwxr-xrwx drwxrwxrwt drwxrwxrwx drwxrwxr-x drwxrwxrwx drwxrwxrwx drwxr-xr-x drwxrwxr-x -rw-r--r-- drwxrwxrwx drwxr-xr-x drwxrwxrwt drwxr-xr-x j/lnk: yes"
TS4H_V="$(_ts4u_above "$TS4H_D/j/lnk/home" | P="$TS4H_D/" LC_ALL=C awk 'index($0, ENVIRON["P"]) == 1 { printf "%s ", substr($0, length(ENVIRON["P"]) + 1) } $0 == "/" { printf "/ " }')"
is "ts4 harden H1, H2 (control): this test's walk of the directories above a path through a link names them along the path as written, nearest first, up to /, then those of its physical path not named yet" \
  "$TS4H_V" "j/lnk j / j/p/real j/p "
TS4H_T=/tmp; [ "$TS4U_OS" != Darwin ] || TS4H_T=/private/tmp; TS4H_V=""; TS4H_W=""
case "$(ls -ldn "$TS4H_T" 2>/dev/null | LC_ALL=C awk 'NR == 1 { print $3 " " substr($1, 1, 10) }')" in
  "0 drwxrwxrwt") TS4H_V="; $TS4H_T, root's and of mode 1777: [$(_ts4u_r0first "$TS4H_T")]"; TS4H_W="; $TS4H_T, root's and of mode 1777: [$TS4H_T]" ;;
esac
is "ts4 harden H1 (control): this test reads / and the directory of the git E2 names as only root's, a directory of this login's as not, and a directory of root's of mode 1777, where there is one, as not: H1 takes no sticky bit" \
  "/ and the git's directory: [$(_ts4u_r0first / "${TS4U_GIT%/*}")]; this login's: [$(_ts4u_r0first / "$TS4H_D")]$TS4H_V" "/ and the git's directory: []; this login's: [$TS4H_D]$TS4H_W"
_ts4h_h3 "a HOME in a directory of mode 777 without the sticky bit, naming that directory" "$TS4H_D/a/w/home" "$TS4H_D/a/w"
_ts4h_h3 "a HOME of mode 775, naming HOME" "$TS4H_D/b" "$TS4H_D/b"
_ts4h_h3 "a HOME of mode 757, naming HOME" "$TS4H_D/c" "$TS4H_D/c"
_ts4h_h3 "a HOME of mode 1777, naming HOME: the sticky bit makes HOME no more this login's alone" "$TS4H_D/d" "$TS4H_D/d"
_ts4h_h3 "a HOME of mode 775 in a directory of mode 777, naming HOME, which is read first" "$TS4H_D/g/w/home" "$TS4H_D/g/w/home"
_ts4h_h3 "a HOME two of whose directories above are of mode 777, naming the nearer one" "$TS4H_D/h/w1/w2/home" "$TS4H_D/h/w1/w2"
_ts4h_h3 "a HOME of mode 775 whose .felix is a file, with H3's line and not E6's: H3 is read before E6 reads its four directories" "$TS4H_D/i/home" "$TS4H_D/i/home"
TS4H_V="$(_ts4_snap "$TS4H_D/j/lnk/home")"; _ts4u_ae "$TS4H_D/j/lnk/home" "$TS4H_K1" "$TS4H_B"
if [ "$(_ts4_snap "$TS4H_D/j/lnk/home")" = "$TS4H_V" ]; then TS4H_V=unchanged; else TS4H_V=changed; fi
TS4H_V="$(_ts4u_ref); home: $TS4H_V"; TS4H_W="exit 1; stderr: authority-engine: $TS4H_D/j/p can be written by another login; home: unchanged"
[ "$TS4U_OS" = Darwin ] || [ "$TS4H_V" != "exit 1; stderr: authority-engine: $TS4H_D/j/lnk can be written by another login; home: unchanged" ] || TS4H_W="$TS4H_V"
_ts4_is "ts4 harden H3: authority-engine refuses a HOME reached through a link of this login's whose physical path runs through a directory of mode 777, naming that directory, and writes nothing in HOME" \
  "$TS4H_V" "$TS4H_W" "$(_ts4_why)"
_ts4h_h3ok "a HOME in a directory of mode 1777, which the sticky bit keeps another login from renaming or removing, is not refused by H3" "$TS4H_D/s/st/home"
TS4H_N="a HOME that carries an access-control entry that allows, on macOS, naming HOME"
TS4H_N2="a HOME in a directory that carries an access-control entry that allows, on macOS, naming that directory"
TS4H_N3="on macOS, a HOME, and the directory it is in, each carrying only an entry that denies, are not refused by H3"
TS4H_N4="ts4 harden H3 (control): on macOS, the entries are staged, and this test reads the two that allow, on a HOME and on a directory above one, as entries that allow, and the two that deny as none"
mkdir -p "$TS4H_D/e/home" "$TS4H_D/f/acl/home" "$TS4H_D/n/dn/home"; chmod 755 "$TS4H_D/e" "$TS4H_D/e/home" "$TS4H_D/f" "$TS4H_D/f/acl" "$TS4H_D/f/acl/home" "$TS4H_D/n" "$TS4H_D/n/dn" "$TS4H_D/n/dn/home"
TS4H_W=""
if [ "$TS4U_OS" != Darwin ]; then TS4H_W="this is not macOS"
elif ! chmod +a "everyone allow add_file,add_subdirectory" "$TS4H_D/e/home" 2>/dev/null; then TS4H_W="chmod +a put no access-control entry on a directory here"; fi
if [ -n "$TS4H_W" ]; then
  skip "$TS4H_N4" "$TS4H_W"; skip "ts4 harden H3: authority-engine refuses $TS4H_N, and writes nothing in HOME" "$TS4H_W"
  skip "ts4 harden H3: authority-engine refuses $TS4H_N2, and writes nothing in HOME" "$TS4H_W"; skip "ts4 harden H3 (allowance): $TS4H_N3" "$TS4H_W"
else
  chmod +a "everyone allow delete_child" "$TS4H_D/f/acl" 2>/dev/null
  chmod +a "everyone deny delete" "$TS4H_D/n/dn/home" 2>/dev/null; chmod +a "everyone deny delete" "$TS4H_D/n/dn" 2>/dev/null
  is "$TS4H_N4" "$(for TS4H_V in e/home f/acl n/dn/home n/dn; do printf '%s ' "$(_ts4u_allows "$TS4H_D/$TS4H_V")"; done)" "yes yes no no "
  _ts4h_h3 "$TS4H_N" "$TS4H_D/e/home" "$TS4H_D/e/home"
  _ts4h_h3 "$TS4H_N2" "$TS4H_D/f/acl/home" "$TS4H_D/f/acl"
  _ts4h_h3ok "$TS4H_N3" "$TS4H_D/n/dn/home"
  chmod -N "$TS4H_D/e/home" "$TS4H_D/f/acl" "$TS4H_D/n/dn/home" "$TS4H_D/n/dn" 2>/dev/null
fi
skip "ts4 harden H3: authority-engine refuses a HOME owned by another uid, naming HOME" "a HOME owned by another uid is made only by root (chown), and this test uses no sudo"

# ------------------------------------------------------------------ H3, after the build review (not blind) ---
# Written by the builder from the review of d4ac2338 (audits/.../review/build-review-2026-11-16.md, trust 3 and 4),
# each shown red on d4ac2338 first. A link met on the way, as written, that points at another link: the directory
# holding the second link is read too (spec rev 2, section 0's walk). A HOME that is itself a link is read as a
# directory above is: owner root or this login, and no entry that allows.
mkdir -p "$TS4H_D/m/a" "$TS4H_D/m/b" "$TS4H_D/m/c/real/home"; chmod 755 "$TS4H_D/m" "$TS4H_D/m/a" "$TS4H_D/m/c" "$TS4H_D/m/c/real" "$TS4H_D/m/c/real/home"
chmod 777 "$TS4H_D/m/b"; ln -s "$TS4H_D/m/c/real" "$TS4H_D/m/b/l2" 2>/dev/null; ln -s "$TS4H_D/m/b/l2" "$TS4H_D/m/a/l1" 2>/dev/null
is "ts4 harden H3 (control, review trust 3): a link of this login's points at a link in a directory of mode 777, which points at a directory of this login's" \
  "$(_ts4u_m "$TS4H_D/m/b") $(_ts4_yn test -L "$TS4H_D/m/a/l1") $(_ts4_yn test -L "$TS4H_D/m/b/l2") $(_ts4_yn test -d "$TS4H_D/m/a/l1/home")" "drwxrwxrwx yes yes yes"
_ts4h_h3 "a HOME reached through a link to a link that sits in a directory of mode 777 without the sticky bit, naming that directory (review trust 3)" \
  "$TS4H_D/m/a/l1/home" "$TS4H_D/m/b"
TS4H_N="ts4 harden H3: authority-engine refuses a HOME that is a link carrying an entry that allows, in a directory of mode 1777, naming the link, and writes nothing in HOME (review trust 4)"
mkdir -p "$TS4H_D/k/s" "$TS4H_D/k/real"; chmod 755 "$TS4H_D/k" "$TS4H_D/k/real"; chmod 1777 "$TS4H_D/k/s"; ln -s "$TS4H_D/k/real" "$TS4H_D/k/s/home" 2>/dev/null
if [ "$TS4U_OS" != Darwin ]; then skip "$TS4H_N" "this is not macOS: an entry on a link itself is put with chmod -h +a"
elif ! chmod -h +a "everyone allow delete" "$TS4H_D/k/s/home" 2>/dev/null || [ "$(_ts4u_allows "$TS4H_D/k/s/home")" != yes ]; then skip "$TS4H_N" "chmod -h +a put no entry that allows on a link here"
else
  TS4H_V="$(_ts4_snap "$TS4H_D/k/real")"; _ts4u_ae "$TS4H_D/k/s/home" "$TS4H_K1" "$TS4H_B"
  if [ "$(_ts4_snap "$TS4H_D/k/real")" = "$TS4H_V" ]; then TS4H_V=unchanged; else TS4H_V=changed; fi
  _ts4_is "$TS4H_N" "$(_ts4u_ref); home: $TS4H_V" "exit 1; stderr: authority-engine: $TS4H_D/k/s/home can be written by another login; home: unchanged" "$(_ts4_why)"
  chmod -h -N "$TS4H_D/k/s/home" 2>/dev/null
fi

# ------------------------------------------------------------------ H4 and H7: owned by another uid ---
skip "ts4 harden H4: authority-engine refuses a .felix, .felix/engine, boot.git or .felix/bin owned by another uid, with E6's line" \
  "a directory owned by another uid is made only by root (chown), and this test uses no sudo; E6's mode and entry refusals stand, in part 2191"
skip "ts4 harden H7: a copy in place, or a path under it, owned by another uid is one that differs, refused by E10 and left as it is" \
  "a copy owned by another uid is made only by root (chown), and this test uses no sudo; E10's assertions stand, in part 2191"

# ------------------------------------------------------------------ H8: POSIX lists, where ls takes no -e ---
TS4H_N="ts4 harden H8 (control): where ls takes no -e, setfacl puts a list on a directory and on a file here, which ls -ld shows as a + at the eleventh character, the mode bits as they were"
TS4H_N2="ts4 harden H8: where ls takes no -e, authority-engine refuses a HOME that carries a POSIX list, naming HOME with H3's line, and writes nothing in HOME"
TS4H_N3="ts4 harden H8: where ls takes no -e, authority-engine refuses a .felix/bin that carries a POSIX list, with E6's line, and makes no copy"
TS4H_N4="ts4 harden H8: where ls takes no -e, a copy in place a file of which carries a POSIX list is refused by E10, and left as it is"
TS4H_W=""
if [ "$TS4U_OS" = Darwin ] || ls -lde / >/dev/null 2>&1; then TS4H_W="ls takes -e here, and entries are read with ls -lde (H8 is for where it does not)"
elif ! command -v setfacl >/dev/null 2>&1; then TS4H_W="there is no setfacl here"
else
  mkdir -p "$TS4/h8/pd"; : > "$TS4/h8/pf"; chmod 700 "$TS4/h8/pd"; chmod 600 "$TS4/h8/pf"
  if ! setfacl -m u:65534:--- "$TS4/h8/pd" "$TS4/h8/pf" 2> "$TS4H_X/setfacl.err"; then TS4H_W="setfacl put no POSIX list on this file system ($(_ts4_flat < "$TS4H_X/setfacl.err"))"
  else is "$TS4H_N" "$(for TS4H_V in pd pf; do ls -ld "$TS4/h8/$TS4H_V" 2>/dev/null | LC_ALL=C awk 'NR == 1 { printf "%s ", substr($1, 1, 11) }'; done)" "drwx------+ -rw-------+ "; fi
fi
if [ -n "$TS4H_W" ]; then
  skip "$TS4H_N" "$TS4H_W"; skip "$TS4H_N2" "$TS4H_W"; skip "$TS4H_N3" "$TS4H_W"; skip "$TS4H_N4" "$TS4H_W"
else
  mkdir -p "$TS4/h8/a/home" "$TS4/h8/b/.felix/bin" "$TS4/h8/d"; chmod 755 "$TS4/h8/a" "$TS4/h8/a/home" "$TS4/h8/b" "$TS4/h8/d"; chmod 700 "$TS4/h8/b/.felix" "$TS4/h8/b/.felix/bin"
  setfacl -m u:65534:--- "$TS4/h8/a/home" 2>/dev/null; TS4H_V="$(_ts4_snap "$TS4/h8/a/home")"; _ts4u_ae "$TS4/h8/a/home" "$TS4H_K1" "$TS4H_B"
  if [ "$(_ts4_snap "$TS4/h8/a/home")" = "$TS4H_V" ]; then TS4H_V=unchanged; else TS4H_V=changed; fi
  _ts4_is "$TS4H_N2" "$(_ts4u_ref); home: $TS4H_V" "exit 1; stderr: authority-engine: $TS4/h8/a/home can be written by another login; home: unchanged" "$(_ts4_why)"
  setfacl -m u:65534:--- "$TS4/h8/b/.felix/bin" 2>/dev/null; _ts4u_ae "$TS4/h8/b" "$TS4H_K1" "$TS4H_B"
  _ts4_is "$TS4H_N3" "$(_ts4u_ref); copy: $(_ts4_yn test -e "$TS4/h8/b/.felix/engine/$TS4H_K1")" "exit 1; stderr: authority-engine: $TS4/h8/b/.felix/bin can be written by another login; copy: no" "$(_ts4_why)"
  TS4H_C="$TS4/h8/d/.felix/engine/$TS4H_K1"; _ts4u_ae "$TS4/h8/d" "$TS4H_K1" "$TS4H_B"; TS4H_RA="exit $TS4_RC"
  setfacl -m u:65534:--- "$TS4H_C/engine/harness/felix" 2>/dev/null; TS4H_V="$(_ts4_snap "$TS4H_C"; ls -lR "$TS4H_C" 2>/dev/null)"; _ts4u_ae "$TS4/h8/d" "$TS4H_K1" "$TS4H_B"
  if [ "$(_ts4_snap "$TS4H_C"; ls -lR "$TS4H_C" 2>/dev/null)" = "$TS4H_V" ]; then TS4H_V=unchanged; else TS4H_V=changed; fi
  _ts4_is "$TS4H_N4" "first: $TS4H_RA; then: $(_ts4u_ref); copy: $TS4H_V" \
    "first: exit 0; then: exit 1; stderr: authority-engine: $TS4H_C is there and differs from the commit; it is left as it is; copy: unchanged" "$(_ts4_why)"
  setfacl -b "$TS4/h8/pd" "$TS4/h8/pf" "$TS4/h8/a/home" "$TS4/h8/b/.felix/bin" "$TS4H_C/engine/harness/felix" 2>/dev/null
fi
TS4_SKIP=""

_ts4u_end
unset TS4H_X TS4H_S TS4H_B TS4H_D TS4H_E2 TS4H_SEAM TS4H_FIT TS4H_K1 TS4H_G0 TS4H_XP TS4H_RA TS4H_N TS4H_N2 TS4H_N3 TS4H_N4 TS4H_HL TS4H_HLW TS4H_GL TS4H_C TS4H_T TS4H_V TS4H_W
# <<< trust-step4-setup-hardening-engine
