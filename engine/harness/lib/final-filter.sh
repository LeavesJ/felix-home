# The command whose status a table row's text returns, and whether a final
# filter makes it unfailable.
#
# Every table runner evaluates a row's command with pipefail off. Probes,
# obligations, setup and maintenance each start a `bash -c`, and commissioning
# evaluates in-process after `set +o pipefail`. So a pipeline's status is its
# last stage's, and a check whose status comes from a last stage that succeeds
# whatever it is fed cannot fail: `npm test 2>&1 | tail -20` reads done, or
# SATISFIED, when the tests fail.
#
# A first attempt judged the text after the last `|` against a list of filter
# names, and review found it leaked both ways. `${c##*|}` split `||` at its
# second bar, so `x | tail || exit 1` passed. It refused checks that can fail:
# `set -o pipefail; x | tail`, `sort -c`, a quoted `|`. And it missed
# `LC_ALL=C sort`, `/usr/bin/tail`, `\tail`, and a redirect after the filter.
# Text patterns cannot answer this. A parse can.
#
# So this reads the text the way bash does, far enough to answer one question.
# It lexes words, quotes, expansions, comments, operators and redirections.
# It parses lists, and-or chains, pipelines, groups and the compound commands,
# and follows each path through the and-or algebra. A path's status is one of
# three: zero, non-zero, or zero because a final filter dropped its producer's
# status. The last is carried as `h:<name>`. The text is refused when it can
# end on such a zero. That is why `x | tail || exit 1` is refused (the `||`
# never runs), `a && x | tail` is refused (whenever `a` holds, tail decides),
# and `x | tail && y` is admitted (y decides).
#
# A final filter is the last stage of a pipeline of two or more stages whose
# command exits 0 whatever it reads, given its arguments: cat, tac, head, tail,
# tee, sort without -c, uniq, wc, tr, cut, paste, nl, fold, rev, column,
# expand, unexpand, true, :, echo, a sed with a visible script and no exit
# code, an awk with a visible program and nothing that can make it exit
# non-zero, and xargs -0 or -d running echo or true. A stage that reads a file
# operand, or has its standard input redirected, reads a file that can be
# missing, so it can fail, and it is admitted. xargs without -0 or -d fails on
# an unmatched quote in its input, and is admitted too. The printed name is
# the command as bash resolves it, past assignments, command, builtin, env,
# exec, nice, nohup, stdbuf and a path.
#
# Precision first. A refused commissioning row fails its project's gate, and a
# refused obligation blocks every merge, so a false refusal is loud and costly,
# while a missed shape only leaves today's hole. So the text is admitted
# whenever it mentions pipefail, defines a function, holds a here-document, or
# has syntax this cannot read. A stage named by an expansion is not a filter.
# An `if`, `case` or loop is read branch by branch. A script handed to
# `sh -c`, `bash -c` or `eval` as a literal is read as that script.
#
# The core is awk, held in FELIX_FINAL_FILTER_AWK, because two of the tables
# it judges are already read by one awk pass. It defines ff_stage(text), which
# is the filter's name or "", and ff_why(name), the clause a refusal gives.
# Each caller prepends it to its own program, so a table is judged in one
# process, not one per row. Every name it defines begins with ff or FF.
#
# Where it is enforced. Only columns where an unfailable command fails open,
# reading as a pass, are judged: commissioning's check, obligations' evidence,
# setup's check, and a maintenance event row's check. Commissioning's `when`,
# obligations' `applies` and a probe's `when` are not: an unfailable one makes
# its row always apply, which asks more. A probe's witness is not: an
# unfailable witness turns an empty probe `blind`, which blocks. A probe's own
# command is not: its members are its answer, and a real row ends in
# `sed -n 's/.../p'`. Qualification is not: it shows a checker failing
# itself, and an unfailable command fails its violation control.

FELIX_FINAL_FILTER_AWK='
function ff_sq(s, i, n) {
  while (i <= n) { if (substr(s, i, 1) == "\047") return i + 1; i++ }
  return 0
}
function ff_bq(s, i, n,    c) {
  while (i <= n) { c = substr(s, i, 1); if (c == "\\") { i += 2; continue }; if (c == "`") return i + 1; i++ }
  return 0
}
function ff_ansi(s, i, n,    c, v) {
  v = ""
  while (i <= n) {
    c = substr(s, i, 1)
    if (c == "\\") { v = v substr(s, i + 1, 1); i += 2; continue }
    if (c == "\047") { FFDQV = v; FFDQY = 0; return i + 1 }
    v = v c; i++
  }
  return 0
}
function ff_dq(s, i, n,    c, k, j, v, y) {
  v = ""; y = 0
  while (i <= n) {
    c = substr(s, i, 1)
    if (c == "\"") { FFDQV = v; FFDQY = y; return i + 1 }
    if (c == "\\") { k = substr(s, i + 1, 1)
      if (k == "\n") { i += 2; continue }
      if (k == "$" || k == "`" || k == "\"" || k == "\\") { v = v k; i += 2; continue }
      v = v c; i++; continue }
    if (c == "`") { j = ff_bq(s, i + 1, n); if (!j) return 0; v = v substr(s, i, j - i); y = 1; i = j; continue }
    if (c == "$") { k = substr(s, i + 1, 1)
      if (k == "(") { j = ff_paren(s, i + 2, n); if (!j) return 0; v = v substr(s, i, j - i); y = 1; i = j; continue }
      if (k == "{") { j = ff_brace(s, i + 2, n); if (!j) return 0; v = v substr(s, i, j - i); y = 1; i = j; continue }
      if (k != "" && index("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_@*#?$!-", k)) y = 1 }
    v = v c; i++
  }
  return 0
}
function ff_paren(s, i, n,    c, d) {
  d = 1
  while (i <= n) {
    c = substr(s, i, 1)
    if (c == "\\") { i += 2; continue }
    if (c == "\047") { i = ff_sq(s, i + 1, n); if (!i) return 0; continue }
    if (c == "\"") { i = ff_dq(s, i + 1, n); if (!i) return 0; continue }
    if (c == "`") { i = ff_bq(s, i + 1, n); if (!i) return 0; continue }
    if (c == "(") d++
    if (c == ")" && --d == 0) return i + 1
    i++
  }
  return 0
}
function ff_brace(s, i, n,    c, d) {
  d = 1
  while (i <= n) {
    c = substr(s, i, 1)
    if (c == "\\") { i += 2; continue }
    if (c == "\047") { i = ff_sq(s, i + 1, n); if (!i) return 0; continue }
    if (c == "\"") { i = ff_dq(s, i + 1, n); if (!i) return 0; continue }
    if (c == "`") { i = ff_bq(s, i + 1, n); if (!i) return 0; continue }
    if (c == "$" && substr(s, i + 1, 1) == "(") { i = ff_paren(s, i + 2, n); if (!i) return 0; continue }
    if (c == "$" && substr(s, i + 1, 1) == "{") { d++; i += 2; continue }
    if (c == "}" && --d == 0) return i + 1
    i++
  }
  return 0
}
function ff_arith(s, i, n,    c, d) {
  d = 2
  while (i <= n) {
    c = substr(s, i, 1)
    if (c == "\047") { i = ff_sq(s, i + 1, n); if (!i) return 0; continue }
    if (c == "\"") { i = ff_dq(s, i + 1, n); if (!i) return 0; continue }
    if (c == "(") d++
    if (c == ")") { d--; if (d == 1) return (substr(s, i + 1, 1) == ")") ? i + 2 : 0 }
    i++
  }
  return 0
}
function ff_word(s, i, n,    c, k, j, v, q, y, b) {
  v = ""; q = 0; y = 0; b = i
  while (i <= n) {
    c = substr(s, i, 1)
    if (index(" \t\n;&|()", c)) break
    if (c == "<" || c == ">") {
      if (i == b && substr(s, i + 1, 1) == "(") { j = ff_paren(s, i + 2, n); if (!j) return 0; v = v substr(s, i, j - i); y = 1; i = j; continue }
      break }
    if (c == "\\") { q = 1; if (substr(s, i + 1, 1) != "\n") v = v substr(s, i + 1, 1); i += 2; continue }
    if (c == "\047") { j = ff_sq(s, i + 1, n); if (!j) return 0; v = v substr(s, i + 1, j - i - 2); q = 1; i = j; continue }
    if (c == "\"") { j = ff_dq(s, i + 1, n); if (!j) return 0; v = v FFDQV; if (FFDQY) y = 1; q = 1; i = j; continue }
    if (c == "`") { j = ff_bq(s, i + 1, n); if (!j) return 0; v = v substr(s, i, j - i); y = 1; i = j; continue }
    if (c == "$") { k = substr(s, i + 1, 1)
      if (k == "\047") { j = ff_ansi(s, i + 2, n); if (!j) return 0; v = v FFDQV; q = 1; i = j; continue }
      if (k == "\"") { j = ff_dq(s, i + 2, n); if (!j) return 0; v = v FFDQV; if (FFDQY) y = 1; q = 1; i = j; continue }
      if (k == "(") { j = ff_paren(s, i + 2, n); if (!j) return 0; v = v substr(s, i, j - i); y = 1; i = j; continue }
      if (k == "{") { j = ff_brace(s, i + 2, n); if (!j) return 0; v = v substr(s, i, j - i); y = 1; i = j; continue }
      if (k != "" && index("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_@*#?$!-", k)) y = 1 }
    v = v c; i++
  }
  FFWV = v; FFWQ = q; FFWY = y; FFWR = substr(s, b, i - b)
  return i
}
function ff_tok(d, t, ty, v, q, y, r, st) {
  FFT[d, t] = ty; FFV[d, t] = v; FFQ[d, t] = q; FFY[d, t] = y; FFR[d, t] = r; FFS[d, t] = st
}
# A redirection at i, with an fd number or {name} before it, or none.
function ff_redir(s, i, n, d, t, fd,    op, st, j) {
  op = substr(s, i, 1); st = 0
  if (op == "<") {
    if (substr(s, i, 3) == "<<<") op = "<<<"
    else if (substr(s, i, 2) == "<<") { FFERR = 1; return 0 }
    else if (substr(s, i, 2) == "<>" || substr(s, i, 2) == "<&") op = substr(s, i, 2)
    if (fd == "" || fd == "0") st = 1
  } else {
    if (substr(s, i, 2) == ">>" || substr(s, i, 2) == ">|" || substr(s, i, 2) == ">&") op = substr(s, i, 2)
    if (fd == "0") st = 1
  }
  i += length(op)
  while (substr(s, i, 1) == " " || substr(s, i, 1) == "\t") i++
  j = ff_word(s, i, n)
  if (!j || j == i) { FFERR = 1; return 0 }
  ff_tok(d, t, "r", op, 0, 0, "", st)
  return j
}
function ff_lex(s, d,    n, i, c, c2, t, j, fd) {
  n = length(s); i = 1; t = 0
  while (i <= n) {
    c = substr(s, i, 1); c2 = substr(s, i, 2)
    if (c == " " || c == "\t") { i++; continue }
    if (c2 == "\\\n") { i += 2; continue }
    if (c == "\n") { ff_tok(d, ++t, "o", "nl"); i++; continue }
    if (c == "#") { while (i <= n && substr(s, i, 1) != "\n") i++; continue }
    if (substr(s, i, 3) == ";;&") { ff_tok(d, ++t, "o", ";;&"); i += 3; continue }
    if (c2 == "&&" || c2 == "||" || c2 == ";;" || c2 == ";&" || c2 == "|&") { ff_tok(d, ++t, "o", c2); i += 2; continue }
    if (c2 == "&>") { j = (substr(s, i + 2, 1) == ">") ? 3 : 2; i += j
      while (substr(s, i, 1) == " " || substr(s, i, 1) == "\t") i++
      j = ff_word(s, i, n); if (!j || j == i) return 0
      ff_tok(d, ++t, "r", "&>", 0, 0, "", 0); i = j; continue }
    if (c == "|" || c == "&" || c == ";" || c == ")") { ff_tok(d, ++t, "o", c); i++; continue }
    if (c == "(") {
      if (substr(s, i + 1, 1) == "(") { j = ff_arith(s, i + 2, n); if (!j) return 0; ff_tok(d, ++t, "a", "(("); i = j; continue }
      ff_tok(d, ++t, "o", "("); i++; continue }
    if ((c == "<" || c == ">") && substr(s, i + 1, 1) != "(") { i = ff_redir(s, i, n, d, ++t, ""); if (!i) return 0; continue }
    j = ff_word(s, i, n); if (!j) return 0
    c = substr(s, j, 1)
    if ((c == "<" || c == ">") && substr(s, j + 1, 1) != "(" && !FFWQ && !FFWY && FFWV ~ /^([0-9]+|[{][A-Za-z_][A-Za-z0-9_]*[}])$/) {
      fd = FFWV; i = ff_redir(s, j, n, d, ++t, fd); if (!i) return 0; continue }
    ff_tok(d, ++t, "w", FFWV, FFWQ, FFWY, FFWR, 0); i = j
  }
  FFN[d] = t
  return 1
}
function ff_ty(k) { return (FFP[FFD] + k <= FFN[FFD]) ? FFT[FFD, FFP[FFD] + k] : "" }
function ff_is(k, v,    p) { p = FFP[FFD] + k; return p <= FFN[FFD] && FFT[FFD, p] == "o" && FFV[FFD, p] == v }
function ff_kw(k, v,    p) { p = FFP[FFD] + k; return p <= FFN[FFD] && FFT[FFD, p] == "w" && !FFQ[FFD, p] && FFV[FFD, p] == v }
function ff_end() { return FFP[FFD] > FFN[FFD] }
function ff_skipnl() { while (ff_is(0, "nl")) FFP[FFD]++ }
function ff_stop(stops,    p) {
  p = FFP[FFD]; if (p > FFN[FFD]) return 0
  if (FFT[FFD, p] == "w" && !FFQ[FFD, p]) return index(stops, " w:" FFV[FFD, p] " ") > 0
  if (FFT[FFD, p] == "o") return index(stops, " o:" FFV[FFD, p] " ") > 0
  return 0
}
function ff_redirs() { while (ff_ty(0) == "r") FFP[FFD]++ }
# Sets are strings of " z ", " n " and " h:<name> ".
function ff_neg(s,    o) {
  o = " "; if (index(s, " z ")) o = o " n "
  if (index(s, " n ")) o = o " z "
  if (index(s, " h:")) o = o " n "
  return o
}
function ff_comb(s, op, r,    o, t) {
  o = " "
  if (op == "&&") { if (index(s, " z ") || index(s, " h:")) o = o r; if (index(s, " n ")) o = o " n "; return o }
  if (index(s, " n ")) o = o r
  t = s; while (sub(/ n /, " ", t)) { }; return o t
}
function ff_text(s,    d, out) {
  if (FFD >= 6) { FFERR = 1; return " z n " }
  d = ++FFD; FFP[d] = 1
  if (!ff_lex(s, d)) { FFERR = 1; FFD--; return " z n " }
  out = ff_list(" ")
  if (!FFERR && !ff_end()) FFERR = 1
  FFD--
  return out
}
function ff_list(stops,    out, o) {
  out = " z "
  while (!FFERR) {
    while (ff_is(0, "nl") || ff_is(0, ";")) FFP[FFD]++
    if (ff_end() || ff_stop(stops)) break
    o = ff_andor(); if (FFERR) break
    if (ff_is(0, "&")) { FFP[FFD]++; out = " z "; continue }
    out = o
    if (ff_is(0, ";") || ff_is(0, "nl")) { FFP[FFD]++; continue }
    break
  }
  return out
}
function ff_andor(    s, op, r) {
  s = ff_pipe()
  while (!FFERR && (ff_is(0, "&&") || ff_is(0, "||"))) {
    op = FFV[FFD, FFP[FFD]]; FFP[FFD]++; ff_skipnl()
    r = ff_pipe(); s = ff_comb(s, op, r)
  }
  return s
}
function ff_pipe(    neg, out, k) {
  if (ff_kw(0, "time")) { FFP[FFD]++; if (ff_kw(0, "-p")) FFP[FFD]++ }
  neg = 0; while (ff_kw(0, "!")) { neg = !neg; FFP[FFD]++ }
  out = ff_cmd(); k = 1
  while (!FFERR && (ff_is(0, "|") || ff_is(0, "|&"))) { FFP[FFD]++; ff_skipnl(); out = ff_cmd(); k++ }
  if (FFERR) return " z n "
  if (k > 1 && FFFILT != "") out = " h:" FFFILT " "
  return neg ? ff_neg(out) : out
}
function ff_close(o) { ff_redirs(); FFFILT = ""; return o }
function ff_cmd(    o, w) {
  FFFILT = ""
  if (ff_end()) { FFERR = 1; return " z n " }
  if (ff_is(0, "(")) { FFP[FFD]++; o = ff_list(" o:) "); if (!ff_is(0, ")")) { FFERR = 1; return o }; FFP[FFD]++; return ff_close(o) }
  if (ff_ty(0) == "a") { FFP[FFD]++; return ff_close(" z n ") }
  if (ff_ty(0) == "r") return ff_simple()
  if (ff_ty(0) != "w") { FFERR = 1; return " z n " }
  if (FFQ[FFD, FFP[FFD]]) return ff_simple()
  w = FFV[FFD, FFP[FFD]]
  if (w == "{") { FFP[FFD]++; o = ff_list(" w:} "); if (!ff_kw(0, "}")) { FFERR = 1; return o }; FFP[FFD]++; return ff_close(o) }
  if (w == "if") return ff_if()
  if (w == "while" || w == "until") {
    FFP[FFD]++; ff_list(" w:do "); if (!ff_kw(0, "do")) { FFERR = 1; return " z n " }
    FFP[FFD]++; o = ff_list(" w:done "); if (!ff_kw(0, "done")) { FFERR = 1; return o }
    FFP[FFD]++; return ff_close(o " z ") }
  if (w == "for" || w == "select") return ff_for()
  if (w == "case") return ff_case()
  if (w == "[[") {
    FFP[FFD]++; while (!ff_end() && !ff_kw(0, "]]")) FFP[FFD]++
    if (ff_end()) { FFERR = 1; return " z n " }
    FFP[FFD]++; return ff_close(" z n ") }
  if (w ~ /^(function|coproc|then|else|elif|fi|do|done|esac|[}])$/) { FFERR = 1; return " z n " }
  return ff_simple()
}
function ff_if(    o) {
  FFP[FFD]++; ff_list(" w:then "); if (!ff_kw(0, "then")) { FFERR = 1; return " z n " }
  FFP[FFD]++; o = ff_list(" w:elif w:else w:fi ")
  while (!FFERR && ff_kw(0, "elif")) {
    FFP[FFD]++; ff_list(" w:then "); if (!ff_kw(0, "then")) { FFERR = 1; return o }
    FFP[FFD]++; o = o ff_list(" w:elif w:else w:fi ") }
  if (ff_kw(0, "else")) { FFP[FFD]++; o = o ff_list(" w:fi ") } else o = o " z "
  if (!ff_kw(0, "fi")) { FFERR = 1; return o }
  FFP[FFD]++; return ff_close(o)
}
function ff_for(    o) {
  FFP[FFD]++
  if (ff_ty(0) == "a") FFP[FFD]++
  else {
    if (ff_ty(0) != "w") { FFERR = 1; return " z n " }
    FFP[FFD]++; ff_skipnl()
    if (ff_kw(0, "in")) { FFP[FFD]++; while (ff_ty(0) == "w") FFP[FFD]++ } }
  while (ff_is(0, ";") || ff_is(0, "nl")) FFP[FFD]++
  if (!ff_kw(0, "do")) { FFERR = 1; return " z n " }
  FFP[FFD]++; o = ff_list(" w:done "); if (!ff_kw(0, "done")) { FFERR = 1; return o }
  FFP[FFD]++; return ff_close(o " z ")
}
function ff_case(    o) {
  FFP[FFD]++; if (ff_ty(0) != "w") { FFERR = 1; return " z n " }
  FFP[FFD]++; ff_skipnl(); if (!ff_kw(0, "in")) { FFERR = 1; return " z n " }
  FFP[FFD]++; o = " z "
  while (!FFERR) {
    ff_skipnl()
    if (ff_end()) { FFERR = 1; break }
    if (ff_kw(0, "esac")) { FFP[FFD]++; break }
    if (ff_is(0, "(")) FFP[FFD]++
    if (ff_ty(0) != "w") { FFERR = 1; break }
    FFP[FFD]++
    while (ff_is(0, "|")) { FFP[FFD]++; if (ff_ty(0) != "w") { FFERR = 1; break }; FFP[FFD]++ }
    if (FFERR || !ff_is(0, ")")) { FFERR = 1; break }
    FFP[FFD]++; o = o ff_list(" o:;; o:;& o:;;& w:esac ")
    if (ff_is(0, ";;") || ff_is(0, ";&") || ff_is(0, ";;&")) FFP[FFD]++
  }
  return ff_close(o)
}
function ff_simple(    nw, st, p, i, nm) {
  nw = 0; st = 0
  while (!ff_end() && (ff_ty(0) == "w" || ff_ty(0) == "r")) {
    p = FFP[FFD]; FFP[FFD]++
    if (FFT[FFD, p] == "r") { if (FFS[FFD, p]) st = 1; continue }
    if (nw == 0 && FFR[FFD, p] ~ /^[A-Za-z_][A-Za-z0-9_]*(\[[^=]*\])?[+]?=/) continue
    nw++; FFA[FFD, nw] = FFV[FFD, p]; FFAY[FFD, nw] = FFY[FFD, p]; FFAR[FFD, nw] = FFR[FFD, p]
    if (nw == 1 && ff_is(0, "(")) { FFERR = 1; return " z n " }
  }
  if (nw == 0) return " z n "
  i = ff_prefix(nw); if (!i) return " z n "
  nm = FFNAME
  if (nm ~ /^(sh|bash|dash|ksh|mksh|zsh|ash|posh|yash)$/) return ff_shell(i, nw)
  if (nm == "eval") return ff_eval(i, nw)
  if (!st && ff_filter(nm, i + 1, nw)) FFFILT = nm
  return (nm == "true" || nm == ":") ? " z " : " z n "
}
# The index of the word bash runs, past the wrappers that run the rest.
function ff_prefix(nw,    i, v, b) {
  i = 1
  while (i <= nw) {
    if (FFAY[FFD, i]) return 0
    v = FFA[FFD, i]; b = v; sub(/.*\//, "", b)
    if (b == "command") { i++
      while (i <= nw && FFA[FFD, i] ~ /^-/) { if (FFA[FFD, i] == "--") { i++; break }; if (FFA[FFD, i] ~ /[vV]/) return 0; i++ }
      continue }
    if (b == "builtin" || b == "nohup") { i++; if (FFA[FFD, i] == "--") i++; continue }
    if (b == "exec") { i++
      while (i <= nw && FFA[FFD, i] ~ /^-/) { if (FFA[FFD, i] == "--") { i++; break }; if (FFA[FFD, i] ~ /a$/) i++; i++ }
      continue }
    if (b == "nice" || b == "stdbuf") { i++
      while (i <= nw && FFA[FFD, i] ~ /^-/) { if (FFA[FFD, i] == "--") { i++; break }; if (FFA[FFD, i] ~ /^-[nioe]$/) i++; i++ }
      continue }
    if (b == "time") { i++; while (i <= nw && FFA[FFD, i] ~ /^-[pl]+$/) i++; continue }
    if (b == "env") { i++
      while (i <= nw) {
        v = FFA[FFD, i]; if (FFAY[FFD, i]) return 0
        if (v == "--") { i++; break }
        if (v == "-" || v == "-i" || v == "--ignore-environment") { i++; continue }
        if (v == "-u" || v == "--unset") { i += 2; continue }
        if (v ~ /^(-u.|--unset=)/) { i++; continue }
        if (v ~ /^-/) return 0
        if (v ~ /^[A-Za-z_][A-Za-z0-9_]*=/) { i++; continue }
        break }
      continue }
    FFNAME = b; return i
  }
  return 0
}
function ff_shell(i, nw,    j, v, c, o) {
  c = 0
  for (j = i + 1; j <= nw; j++) {
    v = FFA[FFD, j]; if (FFAY[FFD, j]) return " z n "
    if (v == "--" || v == "-") { j++; break }
    if (v ~ /^[-+][oO]$/ || v == "--rcfile" || v == "--init-file") { j++; continue }
    if (v ~ /^--/) continue
    if (v ~ /^[-+][A-Za-z]+$/) { if (v ~ /^-.*c/) c = 1; continue }
    break
  }
  if (!c || j > nw || FFAY[FFD, j]) return " z n "
  o = ff_text(FFA[FFD, j]); FFFILT = ""; return o
}
function ff_eval(i, nw,    j, t, o) {
  t = ""
  for (j = i + 1; j <= nw; j++) { if (FFAY[FFD, j]) return " z n "; t = t (t == "" ? "" : " ") FFA[FFD, j] }
  o = ff_text(t); FFFILT = ""; return o
}
# Options of a filter: arg are letters taking an argument, ok the letters
# allowed (* for any), bad the letters that can make it fail on its input;
# lok and larg the long options allowed, larg those taking an argument.
# Operands are recorded in FFO; with opok 0 any operand but - is a file.
function ff_opts(a, b, arg, ok, bad, lok, larg, opok,    j, v, k, c, nm) {
  FFON = 0
  for (j = a; j <= b; j++) {
    v = FFA[FFD, j]
    if (v == "--") { for (j++; j <= b; j++) { FFO[++FFON] = FFA[FFD, j]; if (!opok && (FFA[FFD, j] != "-" || FFAY[FFD, j])) return 0 }; return 1 }
    if (v == "-" || v !~ /^-/ || (FFAY[FFD, j] && FFAR[FFD, j] !~ /^-/)) {
      FFO[++FFON] = v; if (!opok && (v != "-" || FFAY[FFD, j])) return 0; continue }
    if (v ~ /^--/) { nm = substr(v, 3); sub(/=.*/, "", nm)
      if (index(lok, " " nm " ")) continue
      if (!index(larg, " " nm " ")) return 0
      if (!index(v, "=")) j++
      continue }
    for (k = 2; k <= length(v); k++) {
      c = substr(v, k, 1)
      if (index(bad, c)) return 0
      if (index(arg, c)) { if (k == length(v)) j++; break }
      if (ok != "*" && !index(ok, c)) return 0
    }
  }
  return 1
}
function ff_filter(nm, a, b) {
  if (nm == "true" || nm == ":" || nm == "echo") return 1
  if (nm == "cat") return ff_opts(a, b, "", "*", "", " number number-nonblank squeeze-blank show-all show-ends show-tabs show-nonprinting ", "", 0)
  if (nm == "tac") return ff_opts(a, b, "s", "*", "", " before regex ", " separator ", 0)
  if (nm == "head") return ff_opts(a, b, "nc", "*", "", " quiet silent verbose zero-terminated ", " lines bytes ", 0)
  if (nm == "tail") return ff_opts(a, b, "ncbs", "*", "", " quiet silent verbose zero-terminated follow retry ", " lines bytes sleep-interval pid max-unchanged-stats ", 0)
  if (nm == "tee") return ff_opts(a, b, "", "*", "", " append ignore-interrupts output-error ", "", 1)
  if (nm == "sort") return ff_opts(a, b, "kotTS", "*", "cC", " ignore-leading-blanks dictionary-order ignore-case general-numeric-sort ignore-nonprinting month-sort human-numeric-sort numeric-sort random-sort reverse version-sort merge stable unique zero-terminated debug sort ", " key output field-separator temporary-directory buffer-size parallel random-source compress-program batch-size ", 0)
  if (nm == "uniq") { if (!ff_opts(a, b, "fsw", "*", "", " count repeated all-repeated group ignore-case unique zero-terminated ", " skip-fields skip-chars check-chars ", 1)) return 0
    return FFON == 0 || (FFO[1] == "-" && FFON <= 2) }
  if (nm == "wc") return ff_opts(a, b, "", "*", "", " bytes chars lines words max-line-length total ", "", 0)
  if (nm == "tr") return ff_opts(a, b, "", "*", "", " complement delete squeeze-repeats truncate-set1 ", "", 1)
  if (nm == "cut") return ff_opts(a, b, "bcfd", "*", "", " complement only-delimited zero-terminated ", " bytes characters fields delimiter output-delimiter ", 0)
  if (nm == "paste") return ff_opts(a, b, "d", "*", "", " serial zero-terminated ", " delimiters ", 0)
  if (nm == "nl") return ff_opts(a, b, "bdfhilnsvw", "*", "", " no-renumber ", " body-numbering section-delimiter footer-numbering header-numbering line-increment join-blank-lines number-format number-separator starting-line-number number-width ", 0)
  if (nm == "fold") return ff_opts(a, b, "w", "*", "", " bytes spaces ", " width ", 0)
  if (nm == "rev") return ff_opts(a, b, "", "", "", "", "", 0)
  if (nm == "column") return ff_opts(a, b, "cs", "tx", "", " table ", " separator columns ", 0)
  if (nm == "expand" || nm == "unexpand") return ff_opts(a, b, "t", "*", "", " initial first-only all ", " tabs ", 0)
  if (nm == "sed") return ff_sed(a, b)
  if (nm ~ /^(awk|gawk|mawk|nawk)$/) return ff_awk(a, b)
  if (nm == "xargs") return ff_xargs(a, b)
  return 0
}
function ff_sed(a, b,    j, v, k, c, sc, got, nm, opn) {
  sc = ""; got = 0; opn = 0
  for (j = a; j <= b; j++) {
    v = FFA[FFD, j]
    if (opn || v == "-" || v !~ /^-/ || (FFAY[FFD, j] && FFAR[FFD, j] !~ /^-/)) {
      if (!got) { if (FFAY[FFD, j]) return 0; sc = v; got = 1; continue }
      if (v != "-" || FFAY[FFD, j]) return 0
      continue }
    if (v == "--") { opn = 1; continue }
    if (v ~ /^--/) { nm = substr(v, 3); sub(/=.*/, "", nm)
      if (nm == "expression") { if (index(v, "=")) v = substr(v, index(v, "=") + 1); else { j++; v = FFA[FFD, j]; if (FFAY[FFD, j]) return 0 }
        sc = sc "\n" v; got = 1; continue }
      if (index(" quiet silent regexp-extended null-data zero-terminated separate unbuffered posix debug sandbox line-length ", " " nm " ")) continue
      return 0 }
    for (k = 2; k <= length(v); k++) {
      c = substr(v, k, 1)
      if (c == "e" || c == "l") {
        if (k < length(v)) v = substr(v, k + 1); else { j++; v = FFA[FFD, j]; if (FFAY[FFD, j]) return 0 }
        if (c == "e") { sc = sc "\n" v; got = 1 }
        break }
      if (!index("nErsuz", c)) return 0
    }
  }
  if (!got || sc ~ /[qQ][ \t]*[0-9]/) return 0
  return 1
}
function ff_awk(a, b,    j, v, p, got) {
  got = 0
  for (j = a; j <= b; j++) {
    v = FFA[FFD, j]
    if (!got) {
      if (v == "--") continue
      if (v ~ /^-[Fv]/) { if (length(v) == 2) j++; continue }
      if (v ~ /^-./) return 0
      if (FFAY[FFD, j]) return 0
      p = v; got = 1; continue }
    if (v == "-" && !FFAY[FFD, j]) continue
    if (FFAR[FFD, j] ~ /^[A-Za-z_][A-Za-z0-9_]*=/) continue
    return 0
  }
  return got && ff_awkprog(p)
}
# Whether an awk program can only exit 0: no exit, no printf, and no division
# or modulo, which is fatal on a zero. A slash after one of ( , { } ; ~ ! & | ? :
# or at the start is a regex; anywhere else it is read as division.
function ff_awkprog(p,    n, i, c, prev, t) {
  n = length(p); prev = ""; t = ""
  for (i = 1; i <= n; i++) {
    c = substr(p, i, 1)
    if (c == "\"") { for (i++; i <= n && substr(p, i, 1) != "\""; i++) if (substr(p, i, 1) == "\\") i++
      if (i > n) return 0
      t = t " S "; prev = "S"; continue }
    if (c == "#") { while (i <= n && substr(p, i, 1) != "\n") i++; continue }
    if (c == "/") {
      if (prev != "" && !index("(,{};~!&|?:", prev)) return 0
      for (i++; i <= n && substr(p, i, 1) != "/"; i++) if (substr(p, i, 1) == "\\") i++
      if (i > n) return 0
      t = t " R "; prev = "R"; continue }
    if (c == "%") return 0
    if (c != " " && c != "\t" && c != "\n") prev = c
    t = t c
  }
  return t !~ /(^|[^A-Za-z0-9_])(exit|printf|sprintf)([^A-Za-z0-9_]|$)/
}
function ff_xargs(a, b,    j, v, k, c, sep, nm) {
  sep = 0
  for (j = a; j <= b; j++) {
    v = FFA[FFD, j]
    if (v == "--") { j++; break }
    if (v !~ /^-/ || v == "-" || (FFAY[FFD, j] && FFAR[FFD, j] !~ /^-/)) break
    if (v ~ /^--/) { nm = substr(v, 3); sub(/=.*/, "", nm)
      if (nm == "null") { sep = 1; continue }
      if (nm == "delimiter") { sep = 1; if (!index(v, "=")) j++; continue }
      if (index(" no-run-if-empty verbose ", " " nm " ")) continue
      if (index(" max-args max-procs max-chars max-lines replace eof ", " " nm " ")) { if (!index(v, "=")) j++; continue }
      return 0 }
    for (k = 2; k <= length(v); k++) {
      c = substr(v, k, 1)
      if (c == "0") { sep = 1; continue }
      if (c == "r" || c == "t") continue
      if (c == "d") { sep = 1; if (k == length(v)) j++; break }
      if (index("nPsLIJRSE", c)) { if (k == length(v)) j++; break }
      return 0
    }
  }
  if (!sep) return 0
  if (j > b) return 1
  if (FFAY[FFD, j]) return 0
  v = FFA[FFD, j]; sub(/.*\//, "", v)
  return v == "echo" || v == "true"
}
# The final filter whose status the text can end on, or "".
function ff_stage(s,    out) {
  FFERR = 0; FFD = 0; FFFILT = ""
  if (s ~ /[Pp][Ii][Pp][Ee]_?[Ff][Aa][Ii][Ll]/) return ""
  out = ff_text(s)
  if (FFERR || !match(out, / h:[^ ]+ /)) return ""
  return substr(out, RSTART + 3, RLENGTH - 4)
}
function ff_why(nm) {
  return "can end on " nm "\047s status, and " nm " succeeds whatever it is fed, so it could not fail"
}
'

# The final filter TEXT's status can be, printed, with exit 0; exit 1 and
# nothing printed when there is none, or when this cannot tell.
felix_final_filter() {
  local out
  out="$(FELIX_FF_TEXT="${1:-}" LC_ALL=C awk "$FELIX_FINAL_FILTER_AWK"'
    BEGIN { s = ff_stage(ENVIRON["FELIX_FF_TEXT"]); if (s != "") print s }' </dev/null 2>/dev/null)"
  [ -n "$out" ] || return 1
  printf '%s\n' "$out"
}
