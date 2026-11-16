# >>> trust-step4-setup-hardening-publish-and-e
printf '\ntrust plane step 4, the setup slice hardened: what publish reads of the drop'\''s directory and above it, condition e and a PATH entry holding a glob character, and where the founder reads the commit he types (spec H5, H6, H9, section 5; blind)\n'
# Blind, written on 2026-11-16 from .felix/memory/felix/audits/2026-11-16-trust-step4-setup-hardening/spec.md (rev 1),
# all of it, with the setup slice's spec (audits/2026-11-16-trust-step4-authority-setup/spec.md, rev 3, sections 0, 1,
# 2 and 4), before the fix existed, by an author who has read no code of felix authority publish, bin/authority-engine,
# lib/authority.sh or bin/lock-macos. The helpers are tests/lib/trust-step4.sh and tests/lib/trust-step4-setup.sh; this
# part's own start with _ts4h_. Everything is under $TMP/ts4-harden-pe. Every publish names --to, a directory of the
# fixture; none is made to write in /Users/Shared.
#
# H9 reads step 3 of the setup document, docs/2026-11-16-trust-step4-authority-setup.md, in this suite's tree. H5 drives
# felix authority publish as part 2190 does, with r, a repository whose one branch is main. H6 reads condition e through
# felix authority status from a copy of this suite's engine, with a store whose one worker is another login of this
# machine that runs no process, as part 2192 does; where no such login is found, or status gives that store a why line
# of a, b or e before anything is staged, each H6 assertion is skipped under its own name.
#
# Readings, where the spec leaves room:
# - H9's "says to note the id from origin-main:": a sentence of step 3 (cut at a full stop and a space) that holds the
#   word origin-main and the word note, noted or noting, and none of not, never, instead, rather or a word starting
#   worker. "Names the pull request's merged commit": step 3 holds "merged commit", and "pull request" or the word PR.
#   "Read on another device": step 3 holds "phone" or "device".
# - H5's refusal is one line on stderr with status 1, and "nothing is written" is the directory's tree and bytes as they
#   were: a directory not there stays not there. "The first that fails" is read only where one directory fails.
# - H5 on DIR itself is "only this login can change": a DIR of mode 1777 is refused too, the sticky bit excusing only a
#   directory above. The order of P1's refusals is read at a DIR of mode 770, which cannot be read by another login and
#   is refused for that, not for being writable by a group.
# - H5's directories above, along the physical path: a --to under a link to a directory whose parent every login can
#   write. Off macOS a link's own mode reads lrwxrwxrwx, and the spec does not say whether a link on the path as written
#   is read as itself or followed, so there it is skipped.
# - H5's directories above reach past the fixture to /. This test reads them first itself, by section 0's rule; where
#   one fails here, every H5 assertion is skipped, naming it.
# - H6's "is named by condition e": the why line of C4 names it first and counts 1. "Not named for it": status prints
#   the why lines of c and d alone.
#
# Not covered: H5 for a DIR, or a directory above, owned by another uid (root's to make, section 5); H5's mkdir -m 755
# (part 2190's assertion stands); P1's default DIR (the suite never writes in /Users/Shared); H6's "the shell's glob
# setting is as it was before" (nothing seen from outside the program shows it); H9's header comment of the program,
# and the document's table (section 5 names step 3 alone).
_ts4u_begin ts4-harden-pe
TS4H_R="$TS4/r"; TS4H_DOC="$REAL_HARNESS/../../docs/2026-11-16-trust-step4-authority-setup.md"; TS4H_E=""; [ "$TS4U_OS" != Darwin ] || TS4H_E=e
mkdir -p "$TS4H_R"; _fx_git "$TS4H_R" init -q -b main >/dev/null 2>&1; _fx_git "$TS4H_R" config gc.auto 0 >/dev/null 2>&1
printf 'one\n' > "$TS4H_R/a"; _fx_git "$TS4H_R" add -A >/dev/null 2>&1
_fx_git "$TS4H_R" -c user.name=worker -c user.email=worker@example.invalid commit -q --no-gpg-sign --no-verify -m one >/dev/null 2>&1
TS4H_C="$(_fx_git "$TS4H_R" rev-parse -q --verify HEAD 2>/dev/null)"

# ------------------------------------------------------------------ helpers ---
_ts4h_step3() {   # -> the setup document's step 3: its lines from the one that starts **Step 3. to the one before **Step 4., joined by spaces
  LC_ALL=C awk 'index($0, "**Step 4.") == 1 { s = 0 } index($0, "**Step 3.") == 1 { s = 1 } s { printf "%s%s", (n++ ? " " : ""), $0 }' "$TS4H_DOC" 2>/dev/null
}
_ts4h_notes() {   # TEXT -> "says so" when a sentence of TEXT, cut at a full stop and a space, holds the word origin-main and the word note,
                  # noted or noting, and none of not, never, instead, rather or a word starting worker; "does not" otherwise
  T="$1" LC_ALL=C awk 'BEGIN { t = tolower(ENVIRON["T"]); n = split(t, s, /\. /); r = "does not"
    for (i = 1; i <= n; i++) { o = 0; nt = 0; ng = 0; m = split(s[i], w, /[^a-z-]+/)
      for (k = 1; k <= m; k++) { if (w[k] == "origin-main") o = 1; if (w[k] == "note" || w[k] == "noted" || w[k] == "noting") nt = 1
        if (w[k] == "not" || w[k] == "never" || w[k] == "instead" || w[k] == "rather" || index(w[k], "worker") == 1) ng = 1 }
      if (o && nt && !ng) r = "says so" }
    print r }'
}
_ts4h_ups() {   # PATH: PATH and each directory above it up to /, along PATH as written and along its physical path (cd -P), each once
  local x q; q="$( (cd -P "$1" && pwd -P) 2>/dev/null)"
  for x in "$1" ${q:+"$q"}; do
    while :; do printf '%s\n' "$x"; [ "$x" != / ] || break; x="$(dirname "$x")"; done
  done | LC_ALL=C awk '!s[$0]++'
}
_ts4h_rootme() {   # PATH: "ok" when PATH and each directory _ts4h_ups lists for it is owned by uid 0 or this login, can be written by group
                   # or other only with the sticky bit (a link is read for its owner alone), and carries no access-control entry that
                   # is not a deny (section 0, ls -e where ls takes it); otherwise the first that is not
  local d
  _ts4h_ups "$1" > "$TS4/x/ups"
  while IFS= read -r d; do
    ls -ldn$TS4H_E "$d" 2>/dev/null | U="$TS4U_UID" D="$d" LC_ALL=C awk '
      NR == 1 { n = 1; m = $1; if ($3 != 0 && $3 != ENVIRON["U"]) b = 1
        if (substr(m, 1, 1) != "l" && (substr(m, 6, 1) == "w" || substr(m, 9, 1) == "w") && substr(m, 10, 1) != "t" && substr(m, 10, 1) != "T") b = 1 }
      NR > 1 && $1 ~ /^[0123456789]+:$/ && index($0, " deny ") == 0 { b = 1 }
      END { if (b || !n) print ENVIRON["D"] }'
  done < "$TS4/x/ups" | LC_ALL=C awk 'NR == 1 { f = $0 } END { print (NR ? f : "ok") }'
}
_ts4h_heads() {   # BUNDLE: the refs git bundle list-heads reads in it, as "ID REF", sorted by ref and joined by |
  [ -f "$1" ] || { printf 'no bundle'; return 1; }
  _fx_git "$TS4/x" bundle list-heads "$1" 2>/dev/null | LC_ALL=C sort -k2 | LC_ALL=C awk '{ printf "%s%s %s", (n++ ? "|" : ""), $1, $2 }'
}
_ts4h_no() {   # WHAT WANT DIR TO: publish --to TO --from r, run in $TS4/t, is refused with exit and stderr WANT, and DIR is as it was
  local w="$1" want="$2" d="$3" s; s="$(_ts4_snap "$d")"
  _ts4u_pub "$TS4/t" --to "$4" --from "$TS4H_R"
  if [ "$(_ts4_snap "$d")" = "$s" ]; then s="nothing written"; else s="something written"; fi
  _ts4_is "ts4 harden H5: publish refuses $w, and writes nothing there" "$(_ts4u_ref); $s" "$want; nothing written" "$(_ts4_why)"
}
_ts4h_yes() {   # NAME TO: publish --to TO --from r writes the drop there: exit 0, TO a directory of mode 755, and the bundle lists r's main
  _ts4u_pub "$TS4/t" --to "$2" --from "$TS4H_R"
  _ts4_is "$1" "exit $TS4_RC; $(_ts4u_m "$2"); $(_ts4h_heads "$2/source.bundle")" "exit 0; drwxr-xr-x; $TS4H_C refs/heads/main" "$(_ts4_why)"
}
_ts4h_wr() { printf 'exit 1; stderr: felix: %s can be written by another login' "$1"; }   # PATH: H5's refusal of PATH, as _ts4u_ref reads it

# ------------------------------------------------------------------ H9: the commit the founder types ---
TS4H_S3="$(_ts4h_step3)"
is "ts4 harden H9 (control): the setup document is there, with one line that starts **Step 3. and one that starts **Step 4., and this test reads step 3 between them" \
  "$(_ts4_yn test -f "$TS4H_DOC"); $(_ts4_count '**Step 3.' "$TS4H_DOC") $(_ts4_count '**Step 4.' "$TS4H_DOC"); $(case "$TS4H_S3" in ("**Step 3."*) printf 'a step 3' ;; (*) printf 'no step 3' ;; esac)" \
  "yes; 1 1; a step 3"
is "ts4 harden H9 (control): this test's reading of a sentence that says to note the id after origin-main: takes the words of 0.49.351 and leaves one that names it as a worker's word" \
  "$(_ts4h_notes 'Run publish. Note the 40 characters after `origin-main:`.'); $(_ts4h_notes 'Run publish. Its `origin-main:` line is a worker'\''s word, and not the id to type. Note the merged commit.')" "says so; does not"
_ts4_is "ts4 harden H9: the setup document's step 3 no longer says to note the id publish prints after origin-main:" "$(_ts4h_notes "$TS4H_S3")" "does not" "step 3: $TS4H_S3"
_ts4_is "ts4 harden H9: the setup document's step 3 names the merged commit of the pull request he released as the id to type" \
  "$(T="$TS4H_S3" LC_ALL=C awk 'BEGIN { t = tolower(ENVIRON["T"]); n = split(t, w, /[^a-z]+/); for (i = 1; i <= n; i++) if (w[i] == "pr") p = 1
     print ((index(t, "merged commit") && (index(t, "pull request") || p)) ? "names the merged commit of the pull request" : "does not") }')" \
  "names the merged commit of the pull request" "step 3: $TS4H_S3"
_ts4_is "ts4 harden H9: the setup document's step 3 has that commit read on another device, his phone, which no login of this Mac reaches" \
  "$(T="$TS4H_S3" LC_ALL=C awk 'BEGIN { t = tolower(ENVIRON["T"]); print ((index(t, "phone") || index(t, "device")) ? "names another device" : "names none") }')" \
  "names another device" "step 3: $TS4H_S3"

# After the build review (not blind; clauses 2, 3 and 9, trust 2), shown red on d4ac2338 first. Step 3 names the
# pull request by a number he fixed himself, has all forty characters read on the commit's own page and never a
# short id completed on this Mac, and names the version COMMIT must hold. Step 4's lines are pinned: they set no
# system or global configuration, no hook and no replacement object for git, and make HOME/.felix fresh, so a
# .felix someone else left stops them before git runs. Lines 5 and 6 end in && so that, pasted as one, a line
# that fails stops the ones after it (a pasted line otherwise runs whatever the one before it did). The two
# directories are made by two mkdir joined by &&: one mkdir of both made engine inside a .felix already there
# before it failed (the rehearsal of d1eecab1), and would have written through a .felix that is a link.
_ts4_is "ts4 harden H9 (review clauses 2, 3, 9): step 3 names the pull request by a number he fixed, has the forty characters read on the commit's own page and no short id completed here, and names 0.49.354" \
  "$(T="$TS4H_S3" LC_ALL=C awk 'BEGIN { t = tolower(ENVIRON["T"]); printf "%s %s %s %s", (index(t, "number") ? "number" : "-"), (index(t, "own page") ? "own-page" : "-"), (index(t, "short id") ? "short-id" : "-"), (index(t, "0.49.354") ? "0.49.354" : "-") }')" \
  "number own-page short-id 0.49.354" "step 3: $TS4H_S3"
TS4H_BLK="$(LC_ALL=C awk 'index($0, "**Step 4.") == 1 { s = 1 } s && /^```/ { b++; next } s && b == 1 { print }' "$TS4H_DOC" 2>/dev/null)"
TS4H_WANT='umask 077; G=/Library/Developer/CommandLineTools/usr/bin/git
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_NO_REPLACE_OBJECTS=1
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath GIT_CONFIG_VALUE_0=/dev/null
B=~/.felix/engine/boot.git; S=/Users/Shared/felix-authority/source.bundle
/bin/mkdir -m 700 ~/.felix && /bin/mkdir -m 700 ~/.felix/engine && $G init -q --bare --template= $B &&
$G --git-dir=$B -c transfer.fsckObjects=true fetch -q -- $S '"'"'+refs/*:refs/boot/*'"'"' &&
$G --git-dir=$B show COMMIT:engine/harness/bin/authority-engine |
  /usr/bin/env -i HOME="$HOME" /bin/bash -s -- COMMIT $S'
_ts4_is "ts4 harden H9 (review trust 2): step 4's lines set no configuration, hook or replacement object of the system's or the login's for git, and make HOME/.felix fresh" \
  "$(if [ "$TS4H_BLK" = "$TS4H_WANT" ]; then printf 'the hardened lines'; else printf 'other lines'; fi)" "the hardened lines" "step 4's block: $(printf '%s' "$TS4H_BLK" | tr '\n' '|')"

# ------------------------------------------------------------------ H5: the fixture and its controls ---
mkdir -p "$TS4/w755" "$TS4/d775" "$TS4/d777" "$TS4/d1777" "$TS4/dacl" "$TS4/ddeny" "$TS4/d770" "$TS4/o777/old" "$TS4/g777/mid" "$TS4/uacl" "$TS4/open/in" "$TS4/s1777"
chmod 755 "$TS4/w755" "$TS4/dacl" "$TS4/ddeny" "$TS4/o777/old" "$TS4/g777/mid" "$TS4/uacl" "$TS4/open/in"
chmod 775 "$TS4/d775"; chmod 777 "$TS4/d777" "$TS4/o777" "$TS4/g777" "$TS4/open"; chmod 1777 "$TS4/d1777" "$TS4/s1777"; chmod 770 "$TS4/d770"
ln -s "$TS4/open/in" "$TS4/hl" 2>/dev/null; [ "$TS4U_OS" != Darwin ] || chmod -h 755 "$TS4/hl" 2>/dev/null
TS4H_V="$(_ts4h_rootme "$TS4")"
if [ "$TS4H_V" = ok ]; then
  ok "ts4 harden H5 (control): the fixture's directory and each directory above it, as written and along its physical path, is root's or this login's to change alone, by section 0's rule as this test reads it"
else
  TS4_SKIP="$TS4H_V, a directory above every DIR here, is not one only root or this login can change, so H5 would name it for each"
  skip "ts4 harden H5 (control): the fixture's directory and each directory above it, as written and along its physical path, is root's or this login's to change alone, by section 0's rule as this test reads it" "$TS4_SKIP"
fi
_ts4_is "ts4 harden H5 (control): the modes staged read as given: 775, 777, 1777, 770, and the parents 777 and 1777" \
  "$(_ts4u_m "$TS4/d775") $(_ts4u_m "$TS4/d777") $(_ts4u_m "$TS4/d1777") $(_ts4u_m "$TS4/d770") $(_ts4u_m "$TS4/o777") $(_ts4u_m "$TS4/s1777")" \
  "drwxrwxr-x drwxrwxrwx drwxrwxrwt drwxrwx--- drwxrwxrwx drwxrwxrwt"
_ts4h_yes "ts4 harden H5 (control): publish writes the drop in a DIR it makes under a directory of this login's of mode 755: exit 0, DIR 755, the bundle lists r's main" "$TS4/w755/drop"

# ------------------------------------------------------------------ H5: an existing DIR ---
_ts4h_no "an existing DIR of mode 775" "$(_ts4h_wr "$TS4/d775")" "$TS4/d775" "$TS4/d775"
_ts4h_no "an existing DIR of mode 777" "$(_ts4h_wr "$TS4/d777")" "$TS4/d777" "$TS4/d777"
_ts4h_no "an existing DIR of mode 1777: the sticky bit excuses a directory above, not DIR itself (a reading)" "$(_ts4h_wr "$TS4/d1777")" "$TS4/d1777" "$TS4/d1777"
_ts4h_no "an existing DIR of mode 770 with P1's line, cannot be read by another login, which comes before H5's (a reading of the order)" \
  "exit 1; stderr: felix: $TS4/d770 cannot be read by another login" "$TS4/d770" "$TS4/d770"
TS4H_N1="ts4 harden H5: publish refuses an existing DIR of mode 755 that carries an access-control entry that allows, and writes nothing there"
TS4H_N2="ts4 harden H5: an existing DIR of mode 755 whose one access-control entry denies is taken, and the drop written there (a reading of section 0)"
if [ "$TS4U_OS" != Darwin ]; then skip "$TS4H_N1" "this is not macOS: section 0 reads entries through ls -e, which this ls does not take"; skip "$TS4H_N2" "this is not macOS"
elif [ -z "$TS4_SKIP" ] && ! chmod +a "everyone allow add_file,add_subdirectory" "$TS4/dacl" 2>/dev/null; then
  skip "$TS4H_N1" "chmod +a put no access-control entry on a directory here"; skip "$TS4H_N2" "chmod +a put no access-control entry on a directory here"
else
  TS4H_V="$(_ts4_snap "$TS4/dacl")"; _ts4u_pub "$TS4/t" --to "$TS4/dacl" --from "$TS4H_R"
  if [ "$(_ts4_snap "$TS4/dacl")" = "$TS4H_V" ]; then TS4H_V="nothing written"; else TS4H_V="something written"; fi
  _ts4_is "$TS4H_N1" "$(_ts4u_ref); $TS4H_V" "$(_ts4h_wr "$TS4/dacl"); nothing written" "$(_ts4_why)"
  chmod -N "$TS4/dacl" 2>/dev/null
  chmod +a "everyone deny delete" "$TS4/ddeny" 2>/dev/null; _ts4h_yes "$TS4H_N2" "$TS4/ddeny"; chmod -N "$TS4/ddeny" 2>/dev/null
fi

# ------------------------------------------------------------------ H5: the directories above DIR ---
_ts4h_no "an existing DIR of mode 755 under a directory of mode 777 without the sticky bit, naming that directory" "$(_ts4h_wr "$TS4/o777")" "$TS4/o777/old" "$TS4/o777/old"
_ts4h_no "a DIR not there under a directory of mode 777 without the sticky bit, naming that directory, and does not make DIR" "$(_ts4h_wr "$TS4/o777")" "$TS4/o777/new" "$TS4/o777/new"
_ts4h_no "a DIR not there two levels under a directory of mode 777 without the sticky bit, naming that directory (a reading of each directory above)" \
  "$(_ts4h_wr "$TS4/g777")" "$TS4/g777/mid" "$TS4/g777/mid/new"
TS4H_N3="ts4 harden H5: publish refuses a DIR not there under a directory that carries an access-control entry that allows, naming that directory, and writes nothing there"
if [ "$TS4U_OS" != Darwin ]; then skip "$TS4H_N3" "this is not macOS: section 0 reads entries through ls -e, which this ls does not take"
elif [ -z "$TS4_SKIP" ] && ! chmod +a "everyone allow add_file,add_subdirectory" "$TS4/uacl" 2>/dev/null; then skip "$TS4H_N3" "chmod +a put no access-control entry on a directory here"
else
  TS4H_V="$(_ts4_snap "$TS4/uacl")"; _ts4u_pub "$TS4/t" --to "$TS4/uacl/new" --from "$TS4H_R"
  if [ "$(_ts4_snap "$TS4/uacl")" = "$TS4H_V" ]; then TS4H_V="nothing written"; else TS4H_V="something written"; fi
  _ts4_is "$TS4H_N3" "$(_ts4u_ref); $TS4H_V" "$(_ts4h_wr "$TS4/uacl"); nothing written" "$(_ts4_why)"
  chmod -N "$TS4/uacl" 2>/dev/null
fi
TS4H_N4="ts4 harden H5: publish refuses a DIR not there under a link to a directory whose parent every login can write without the sticky bit, naming that parent from the physical path, and writes nothing there"
if [ "$TS4U_OS" != Darwin ]; then skip "$TS4H_N4" "this is not macOS: a link's own mode reads lrwxrwxrwx here, and the spec does not say whether a link on the path as written is read as itself"
else
  _ts4h_no "a DIR not there under a link to a directory whose parent every login can write without the sticky bit, naming that parent from the physical path" \
    "$(_ts4h_wr "$TS4/open")" "$TS4/open/in" "$TS4/hl/new"
fi
_ts4h_yes "ts4 harden H5: a DIR publish makes under a directory of mode 1777 is written: exit 0, DIR 755, the bundle lists r's main" "$TS4/s1777/new"

# ------------------------------------------------------------------ H5, after the build review (not blind) ---
# Written by the builder from the review of d4ac2338 (audits/.../review/build-review-2026-11-16.md, trust 1 and 3,
# clauses 1), each shown red on d4ac2338 first. A DIR that is not there when H5 reads it is made by one mkdir that
# fails when anything stands at that name by then, so a directory another login makes in between is never taken.
# A link to a link: the directory holding the second link is read too.
TS4H_RG="$(PATH="$TS4_PATH" command -v git 2>/dev/null)"; mkdir -p "$TS4/race/bin" "$TS4/race/p"; chmod 755 "$TS4/race" "$TS4/race/bin"; chmod 1777 "$TS4/race/p"
printf '#!/bin/sh\ncase " $* " in *" -C %s rev-parse --git-dir "*) [ -e "%s" ] || /bin/mkdir -m 777 "%s" ;; esac\nexec "%s" "$@"\n' \
  "$TS4H_R" "$TS4/race/p/drop" "$TS4/race/p/drop" "$TS4H_RG" > "$TS4/race/bin/git"; chmod 755 "$TS4/race/bin/git"
TS4_ENV=(PATH="$TS4/race/bin:$TS4_PATH"); _ts4u_pub "$TS4/t" --to "$TS4/race/p/drop" --from "$TS4H_R"; TS4_ENV=()
_ts4_is "ts4 harden H5: a DIR another login makes, of mode 777, after H5 has read that it is not there, is not taken: publish refuses, and writes nothing in it (review trust 1)" \
  "$(_ts4u_ref); planted: $(_ts4u_m "$TS4/race/p/drop"); holds: $(_ts4u_ls "$TS4/race/p/drop")" \
  "exit 1; stderr: felix: the bundle could not be written in $TS4/race/p/drop; planted: drwxrwxrwx; holds: " "$(_ts4_why)"
mkdir -p "$TS4/pc/a" "$TS4/pc/b" "$TS4/pc/c/real"; chmod 755 "$TS4/pc" "$TS4/pc/a" "$TS4/pc/c" "$TS4/pc/c/real"; chmod 777 "$TS4/pc/b"
ln -s "$TS4/pc/c/real" "$TS4/pc/b/l2" 2>/dev/null; ln -s "$TS4/pc/b/l2" "$TS4/pc/a/l1" 2>/dev/null
_ts4h_no "a DIR not there under a link to a link that sits in a directory of mode 777 without the sticky bit, naming that directory (review trust 3)" \
  "$(_ts4h_wr "$TS4/pc/b")" "$TS4/pc/c/real" "$TS4/pc/a/l1/new"
TS4_SKIP=""

# ------------------------------------------------------------------ H6: condition e, the fixture ---
TS4H_EN="$TS4/eng"; mkdir -p "$TS4H_EN"; cp -R "$FROOT/harness" "$TS4H_EN/harness" 2>/dev/null; chmod -R go-w "$TS4H_EN" 2>/dev/null
TS4H_F0="$FELIX"; FELIX="$TS4H_EN/harness/felix"; TS4H_Q="$TS4/q"; TS4H_G="$TS4/gl"
_ts4_src "$TS4/src.git"; _ts4_base "$TS4/src.git"
mkdir -p "$TS4H_G/bin" "$TS4H_G/[b]in" "$TS4H_G/b*" "$TS4H_G/b?n"; chmod 755 "$TS4H_G" "$TS4H_G/bin" "$TS4H_G/[b]in" "$TS4H_G/b*" "$TS4H_G/b?n"
_ts4h_st() { _ts4_a "$TS4H_Q" status; }   # status for q, as the copied engine prints it
_ts4h_e() { _ts4h_st; printf '%s' "$(_ts4u_ewhy)"; }   # -> the e why lines status for q prints now, or none
_ts4h_after() { _ts4h_st; printf '%s; %s' "$(_ts4_whys)" "$(_ts4u_ewhy)"; }   # -> the letters of status's why lines for q, and its e why lines or none

# ------------------------------------------------------------------ H6: controls ---
is "ts4 harden H6 (control): with globbing on, this shell reads gl/[b]in as gl/bin, gl/b* as b*, b?n and bin, and gl/b?n as b?n and bin: each entry matches another directory" \
  "$(LC_ALL=C; for TS4H_V in "$TS4H_G"/[b]in "$TS4H_G"/b* "$TS4H_G"/b?n; do printf '[%s]' "${TS4H_V#"$TS4H_G/"}"; done)" "[bin][b*][b?n][bin][b?n][bin]"
_ts4_logins
if [ "$TS4_PS" = yes ] && [ -n "$TS4_IDLE" ]; then
  ok "ts4 harden H6 (control): ps lists this machine's processes, and it has a login other than this one that runs none"
else
  TS4_SKIP="no login other than this one that runs no process was found here (ps lists: $TS4_PS)"
  skip "ts4 harden H6 (control): ps lists this machine's processes, and it has a login other than this one that runs none" "$TS4_SKIP"
fi
_ts4_init "$TS4H_Q" "${TS4_IDLE:-none}" "$TS4/src.git"; _ts4_canstand "$TS4H_Q" "${TS4_IDLE:-none}"; _ts4h_st
_ts4_is "ts4 harden H6 (control): from the copied engine, with that login as the one worker, the standing is shadow with the why lines of c and d alone" "$(_ts4_sv standing) $(_ts4_whys)" "shadow cd" "$(_ts4_why)"
chmod 777 "$TS4H_G/bin"; TS4_ENV=(PATH="$TS4H_G/bin:$TS4_PATH"); TS4H_V="$(_ts4h_e)"; chmod 755 "$TS4H_G/bin"; TS4H_W="$(_ts4h_after)"; TS4_ENV=()
_ts4_is "ts4 harden H6 (control): gl/bin on PATH as it is named, writable by every login, is named by condition e, and is gone once the mode is taken back" \
  "$TS4H_V, then $TS4H_W" "$(_ts4u_eline "$TS4H_G/bin" 1), then cd; none" "$(_ts4_why)"
mv "$TS4H_G/[b]in" "$TS4H_G/lit" 2>/dev/null; chmod 777 "$TS4H_G/lit"; TS4_ENV=(PATH="$TS4H_G/lit:$TS4_PATH"); TS4H_V="$(_ts4h_e)"
chmod 755 "$TS4H_G/lit"; TS4H_W="$(_ts4h_after)"; TS4_ENV=(); mv "$TS4H_G/lit" "$TS4H_G/[b]in" 2>/dev/null
_ts4_is "ts4 harden H6 (control): the literal directory [b]in, moved to a name with no glob character and made writable by every login, is named, and is gone once the mode is taken back" \
  "$TS4H_V, then $TS4H_W; moved back: $(_ts4_yn test -d "$TS4H_G/[b]in")" "$(_ts4u_eline "$TS4H_G/lit" 1), then cd; none; moved back: yes" "$(_ts4_why)"

# ------------------------------------------------------------------ H6: a PATH entry holding a glob character ---
chmod 777 "$TS4H_G/[b]in"; TS4_ENV=(PATH="$TS4H_G/[b]in:$TS4_PATH"); TS4H_V="$(_ts4h_e)"; chmod 755 "$TS4H_G/[b]in"; TS4H_W="$(_ts4h_after)"; TS4_ENV=()
_ts4_is "ts4 harden H6: a PATH entry gl/[b]in is read as written: the literal directory, writable by every login, is named by condition e, and is gone once the mode is taken back" \
  "$TS4H_V, then $TS4H_W" "$(_ts4u_eline "$TS4H_G/[b]in" 1), then cd; none" "$(_ts4_why)"
chmod 777 "$TS4H_G/bin"; TS4_ENV=(PATH="$TS4H_G/[b]in:$TS4_PATH"); TS4H_V="$(_ts4h_after)"; chmod 755 "$TS4H_G/bin"; TS4_ENV=()
_ts4_is "ts4 harden H6: for a PATH entry gl/[b]in, the directory the glob would match, gl/bin, writable by every login, is not named: status prints the why lines of c and d alone" \
  "$TS4H_V" "cd; none" "$(_ts4_why)"
chmod 777 "$TS4H_G/bin"; TS4_ENV=(PATH="$TS4H_G/b*:$TS4H_G/b?n:$TS4_PATH"); TS4H_V="$(_ts4h_after)"; chmod 755 "$TS4H_G/bin"; TS4_ENV=()
_ts4_is "ts4 harden H6: PATH entries gl/b* and gl/b?n, each of whose globs would match gl/bin, writable by every login, do not name it: status prints the why lines of c and d alone" \
  "$TS4H_V" "cd; none" "$(_ts4_why)"
# After the build review (not blind; trust 6), shown red on d4ac2338 first: a program in a PATH directory that is a
# link to a file carrying an entry that allows. macOS ls -lLde prints a link's own entries, so the file is read by
# its physical path.
TS4H_N5="ts4 harden H6 (review trust 6): a program in a PATH directory that is a link to a file carrying an entry that allows is named by condition e, at that file"
mkdir -p "$TS4/ev/bin" "$TS4/ev/t"; chmod 755 "$TS4/ev" "$TS4/ev/bin" "$TS4/ev/t"; printf '#!/bin/sh\n' > "$TS4/ev/t/prog"; chmod 755 "$TS4/ev/t/prog"; ln -s "$TS4/ev/t/prog" "$TS4/ev/bin/prog" 2>/dev/null
if [ -n "$TS4_SKIP" ]; then skip "$TS4H_N5" "$TS4_SKIP"
elif [ "$TS4U_OS" != Darwin ]; then skip "$TS4H_N5" "this is not macOS: an entry is put with chmod +a and read with ls -e"
elif ! chmod +a "everyone allow write" "$TS4/ev/t/prog" 2>/dev/null || [ "$(_ts4u_allows "$TS4/ev/t/prog")" != yes ]; then skip "$TS4H_N5" "chmod +a put no entry that allows on a file here"
else
  TS4_ENV=(PATH="$TS4/ev/bin:$TS4_PATH"); TS4H_V="$(_ts4h_e)"; TS4_ENV=(); chmod -N "$TS4/ev/t/prog" 2>/dev/null
  _ts4_is "$TS4H_N5" "$(case "$TS4H_V" in (*"/ev/t/prog"*) printf 'named at the file' ;; (*) printf 'not named: %s' "$TS4H_V" ;; esac)" "named at the file" "$(_ts4_why)"
fi
# After the security review of d1eecab1 (not blind), shown red on d1eecab1 first: the directories above what a
# link in a PATH directory points at are read as C3 reads those above the code, and a link that leads to nothing
# is read as a path not there yet, so the directory it points into is read too.
mkdir -p "$TS4/ev2/bin" "$TS4/ev2/w"; chmod 755 "$TS4/ev2" "$TS4/ev2/bin"; printf '#!/bin/sh\n' > "$TS4/ev2/w/prog"; chmod 755 "$TS4/ev2/w/prog"
ln -s "$TS4/ev2/w/prog" "$TS4/ev2/bin/prog" 2>/dev/null; chmod 777 "$TS4/ev2/w"
TS4_ENV=(PATH="$TS4/ev2/bin:$TS4_PATH"); TS4H_V="$(_ts4h_e)"; chmod 755 "$TS4/ev2/w"; TS4H_W="$(_ts4h_after)"; TS4_ENV=()
_ts4_is "ts4 harden H11 (security review of d1eecab1): a program in a PATH directory that is a link into a directory every login can write names that directory, and is gone once the mode is taken back" \
  "$TS4H_V, then $TS4H_W" "$(_ts4u_eline "$TS4/ev2/w (a directory above the code)" 1), then cd; none" "$(_ts4_why)"
mkdir -p "$TS4/ev3/bin" "$TS4/ev3/a"; chmod 755 "$TS4/ev3" "$TS4/ev3/bin"; ln -s "$TS4/ev3/a/later" "$TS4/ev3/bin/later" 2>/dev/null; chmod 777 "$TS4/ev3/a"
TS4_ENV=(PATH="$TS4/ev3/bin:$TS4_PATH"); TS4H_V="$(_ts4h_e)"; chmod 755 "$TS4/ev3/a"; TS4H_W="$(_ts4h_e)"; TS4_ENV=()
_ts4_is "ts4 harden H11 (security review of d1eecab1): a link in a PATH directory that leads to nothing, into a directory every login can write, names that directory, and not once the mode is taken back" \
  "$(case "$TS4H_V" in (*"$TS4/ev3/a (a directory above the code)"*) printf 'named' ;; (*) printf 'not named: %s' "$TS4H_V" ;; esac), then $(case "$TS4H_W" in (*"$TS4/ev3/a "*) printf 'named' ;; (*) printf 'not named' ;; esac)" \
  "named, then not named" "$(_ts4_why)"
# After the security review of e7056655 (not blind), shown red on e7056655 first: a link in a PATH directory that
# points at a link, which sits in a directory every login can write: the middle hop's directory is read too.
mkdir -p "$TS4/ev4/bin" "$TS4/ev4/m" "$TS4/ev4/t"; chmod 755 "$TS4/ev4" "$TS4/ev4/bin" "$TS4/ev4/t"; printf '#!/bin/sh\n' > "$TS4/ev4/t/prog"; chmod 755 "$TS4/ev4/t/prog"
ln -s "$TS4/ev4/t/prog" "$TS4/ev4/m/l2" 2>/dev/null; ln -s "$TS4/ev4/m/l2" "$TS4/ev4/bin/prog" 2>/dev/null; chmod 777 "$TS4/ev4/m"
TS4_ENV=(PATH="$TS4/ev4/bin:$TS4_PATH"); TS4H_V="$(_ts4h_e)"; chmod 755 "$TS4/ev4/m"; TS4H_W="$(_ts4h_after)"; TS4_ENV=()
_ts4_is "ts4 harden H12 (security review of e7056655): a program in a PATH directory that is a link to a link in a directory every login can write names that directory, and is gone once the mode is taken back" \
  "$TS4H_V, then $TS4H_W" "$(_ts4u_eline "$TS4/ev4/m (a directory above the code)" 1), then cd; none" "$(_ts4_why)"
FELIX="$TS4H_F0"; TS4_SKIP=""

_ts4u_end
unset TS4H_R TS4H_DOC TS4H_E TS4H_C TS4H_S3 TS4H_V TS4H_W TS4H_N1 TS4H_N2 TS4H_N3 TS4H_N4 TS4H_EN TS4H_F0 TS4H_Q TS4H_G TS4H_RG TS4H_N5 TS4H_BLK TS4H_WANT
# <<< trust-step4-setup-hardening-publish-and-e
