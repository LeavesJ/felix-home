# tests/select-parse.sh: what the report reads out of the tree (audit b30, contract B25, B26 and
# B28): the tree's units, the functions and top level of a shell file, and the lines a change
# adds that make a computed call. Neither version of a file is run or sourced; each is read as
# text. It has no #! line, is not executable and defines functions and nothing else. Loaded by
# lib/testmap.sh.

# RUN GROUPS -> the units of the tree as 0001 makes them (B25): UNIT, a tab, its part files with
# a blank between, one a line in the driver's order. Parts 0001 to 0009 and 9990 are in no unit; a
# group of GROUPS is one unit, in the place of its first member. A groups file that breaks 0001's
# rules gives one line, ERR, a tab and the reason, and the units are the parts alone.
_tm_ps_units() {
  LC_ALL=C awk -F'\t' -v OFS='\t' '
  function prelude(p) { return p ~ /^000[0-9]-/ || p ~ /^9990-/ }
  function fail(m) { if (why == "") why = m }
  function gcheck(f,   ln, g, m, pg, pm, n, gs, h) {
    ln = 0; pg = ""; pm = ""; n = 0; gs = " "
    while ((getline l < f) > 0) {
      ln++
      if (l == "" || substr(l, 1, 1) == "#") continue
      h = "groups.tsv line " ln
      if (index(l, "\t") == 0) { fail(h " has no tab"); return }
      g = l; sub(/\t.*$/, "", g); m = l; sub(/^[^\t]*\t/, "", m)
      if (index(m, "\t") > 0) { fail(h " has more than two fields"); return }
      if (g !~ /^[A-Za-z0-9._-]+$/ || g ~ /\.sh$/) { fail(h ": [" g "] is not a group name"); return }
      if (!(m in ORDI)) { fail(h ": the driver does not source [" m "]"); return }
      if (prelude(m)) { fail(h ": [" m "] is a prelude part or 9990"); return }
      if (m in GOF) { fail(h ": [" m "] is in more than one group, or listed twice"); return }
      if (g != pg) {
        if (index(gs, " " g " ") > 0) { fail(h ": the lines of group [" g "] are not adjacent"); return }
        if (pg != "" && (n < 2 || n > 6)) { fail("group [" pg "] has " n " member(s): a group has two to six"); return }
        gs = gs g " "; pg = g; pm = ""; n = 0
      }
      if (pm != "" && ORDI[m] != ORDI[pm] + 1) { fail(h ": [" m "] does not follow [" pm "] in the driver order"); return }
      GOF[m] = g; pm = m; n++
    }
    if (pg != "" && (n < 2 || n > 6)) fail("group [" pg "] has " n " member(s): a group has two to six")
  }
  function flush() { if (cg != "" || cm != "") print cg, cm; cg = ""; cm = "" }
  BEGIN {
    pre = ". \"$HERE/parts/"; no = 0
    while ((getline l < ARGV[1]) > 0) {
      if (index(l, pre) == 1 && substr(l, length(l), 1) == "\"") { p = substr(l, length(pre) + 1, length(l) - length(pre) - 1); no++; ORD[no] = p; ORDI[p] = no }
    }
    if (ARGV[2] != "") gcheck(ARGV[2])
    if (why != "") { print "ERR", why; for (i = 1; i <= no; i++) if (!prelude(ORD[i])) print ORD[i], ORD[i]; exit }
    cg = ""; cm = ""
    for (i = 1; i <= no; i++) {
      p = ORD[i]
      if (prelude(p)) continue
      if (p in GOF) {
        if (GOF[p] == cg) cm = cm " " p
        else { flush(); cg = GOF[p]; cm = p }
      } else { flush(); print p, p }
    }
    flush()
    exit
  }
  ' "$1" "$2" 2>/dev/null
}
# OLD NEW: both versions of one file read the same way (B28). Prints `ok 1` when both are
# parsed into functions and `ok 0` when either has a definition with no end; then `fn NAME` for each
# function whose body differs between them (a function in only one differs), and `top changed`
# when the lines outside every definition differ.
_tm_ps_fn() {
  LC_ALL=C awk -v OFS='\t' '
  function indentof(l) { match(l, /^[ \t]*/); return substr(l, 1, RLENGTH) }
  function isdef(l,   t, nm) {
    if (l !~ /^[ \t]*function[ \t]+[A-Za-z0-9_.:-]+([ \t]*\(\))?[ \t]*[{(]/ && l !~ /^[ \t]*[A-Za-z0-9_.:-]+[ \t]*\(\)[ \t]*[{(]/) return 0
    t = l; sub(/^[ \t]+/, "", t)
    if (t ~ /^function[ \t]/) { sub(/^function[ \t]+/, "", t) }
    nm = t; sub(/[ \t(){].*$/, "", nm)
    DN = nm; DI = indentof(l)
    sub(/^[A-Za-z0-9_.:-]+[ \t]*(\(\))?[ \t]*/, "", t)
    DC = (substr(t, 1, 1) == "(") ? ")" : "}"
    t = l; sub(/[ \t]+$/, "", t); sub(/[ \t]+#.*$/, "", t)
    DONE = (substr(t, length(t), 1) == DC && t !~ /[{(]$/)
    return 1
  }
  function closes(l, s,   rest) {
    if (substr(l, 1, length(SI[s])) != SI[s] || substr(l, length(SI[s]) + 1, 1) != SC[s]) return 0
    rest = substr(l, length(SI[s]) + 2)
    return rest ~ /^[ \t]*$/ || rest ~ /^[ \t]*[;#<>&]/ || rest ~ /^[ \t]*[0-9]+[<>]/
  }
  function addfn(v, nm, text) { NM[nm] = 1; FB[v, nm] = (((v, nm) in FB) ? FB[v, nm] "\n" : "") text }
  FNR == 1 { v++; sp = 0; OK[v] = 1 }
  {
    l = $0
    if (!OK[v]) next
    if (sp > 0) {
      if (isdef(l) && length(DI) <= length(SI[sp])) { OK[v] = 0; next }
      if (closes(l, sp)) {
        for (j = 1; j <= sp; j++) SB[j] = SB[j] "\n" l
        addfn(v, SN[sp], SB[sp]); sp--; next
      }
      for (j = 1; j <= sp; j++) SB[j] = SB[j] "\n" l
      if (isdef(l)) {
        if (DONE) addfn(v, DN, l)
        else { sp++; SI[sp] = DI; SC[sp] = DC; SN[sp] = DN; SB[sp] = l }
      }
      next
    }
    if (isdef(l)) {
      if (DONE) addfn(v, DN, l)
      else { sp++; SI[sp] = DI; SC[sp] = DC; SN[sp] = DN; SB[sp] = l }
    } else TOP[v] = TOP[v] l "\n"
  }
  END {
    if (sp > 0) OK[v] = 0
    print "ok", (OK[1] && OK[2]) ? 1 : 0
    if (!(OK[1] && OK[2])) exit
    for (nm in NM) if (((1, nm) in FB) != ((2, nm) in FB) || FB[1, nm] != FB[2, nm]) print "fn", nm
    if (TOP[1] != TOP[2]) print "top", "changed"
  }
  ' "$1" "$2" 2>/dev/null
}
# stdin: a unified diff with no context of one file (git diff -U0), or a whole new file with
# -v whole=1. PATH in the environment as TM_PATH. Prints PATH, a tab and the line number in the
# tree, for each added line that makes a computed call (B26): after leading blanks and any of
# if, then, else, do, !, {, (, &&, || and ;, it starts with eval, a computed source, a variable as
# the command word, bash -c or sh -c, a quoted trap, declare -f, export -f or compgen -A function.
_tm_ps_calls() {
  LC_ALL=C awk -v whole="${1:-0}" -v OFS='\t' '
  function cc(s,   t, q) {
    t = s; q = "[\047\"]"
    while (1) {
      sub(/^[ \t]+/, "", t)
      if (t ~ /^(if|then|else|do)([ \t]|$)/) { sub(/^(if|then|else|do)/, "", t); continue }
      if (t ~ /^[!{(;]/) { sub(/^[!{(;]/, "", t); continue }
      if (t ~ /^(&&|\|\|)/) { sub(/^(&&|\|\|)/, "", t); continue }
      break
    }
    if (t ~ /^#/) return 0
    if (t ~ /^eval[ \t]/) return 1
    if (t ~ /^(source|\.)[ \t]+"?\$/) return 1
    if (t ~ /^"\$/ || t ~ /^\$[A-Za-z_{]/) return 1
    if (t ~ /^(bash|sh)[ \t]+-c/) return 1
    if (t ~ ("^trap[ \t]+" q)) return 1
    if (t ~ /^(declare|export)[ \t]+-f/ || t ~ /^compgen[ \t]+-A[ \t]+function/) return 1
    return 0
  }
  BEGIN { p = ENVIRON["TM_PATH"]; ln = 0 }
  whole == 1 { ln++; if (cc($0)) print p, ln; next }
  /^@@ / { s = $0; sub(/^@@ -[0-9,]+ \+/, "", s); sub(/[ ,].*$/, "", s); ln = s - 1; next }
  /^\+\+\+ / { next }
  /^\+/ { ln++; if (cc(substr($0, 2))) print p, ln; next }
  ' 
}
