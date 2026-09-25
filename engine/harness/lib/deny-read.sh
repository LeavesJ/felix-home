# felix_deny_code's awk program: how a Bash command a deny row matched is read
# a second time, as the shell reads it. lib/deny.sh says what the reading keeps
# as code and what it sets aside as data, and why; this file holds only the
# program. Split from lib/deny.sh on 2026-09-23 to keep each file under 500
# lines, the way lib/audit-read.sh was split from lib/audit.sh.
#
# The program is two bash single-quoted strings, joined, so neither may hold
# a single quote, not even in a comment: one apostrophe ends the string, the
# rest runs as bash when the hook sources this file, and the second reading
# silently stops. SQ, or \047, stands for the quote inside the program.
#
# The first is the decoder, and it is a program of its own so the suite can
# hold it to a reference alone: unjson(s) takes the JSON string escapes off,
# and flatten(s) prints the reading of a command too large to read as the
# shell does. Read left to right, unjson turns a backslash before a backslash
# into one backslash, before n, t, a quote or a slash into a line break, a tab,
# the quote or the slash, and before r into nothing; before anything else the
# backslash is kept with what follows. flatten drops a backslash that ends a
# line together with its line break, turns every other line break into ` ; `,
# and drops every quote of either kind.
#
# Linear in BWK awk, mawk and gawk. Until 2026-09-24 both were written with
# gsub, a split on a regex and a string grown once per match, and in BWK awk,
# which macOS ships, each costs the length times the number of matches: a 1.2M
# command with an escaped backslash every 13 bytes took 9.8 s of CPU against
# 0.73 s at 300K, measured on awk 20200816. What is linear there is split on
# one character, which BWK also splits at a line break, so lines are split
# first; index and substr on short pieces; printf per piece; and a pairwise
# join, which copies the text once per level. Its names start _dj, and it
# reads nothing the reader sets.
# shellcheck disable=SC2016
_FELIX_DENY_DECODE='
  function _djput(x) { _djF[++_djN] = x }
  function _djjoin(   n, i, j) {
    if (_djN == 0) return ""
    for (n = _djN; n > 1; n = j) { j = 0; for (i = 1; i <= n; i += 2) _djF[++j] = (i < n) ? _djF[i] _djF[i + 1] : _djF[i] }
    _djN = 0; return _djF[1]
  }
  function unjson(s,   nl, L, i, n, P, k, p, c) {
    if (!index(s, "\\")) return s
    _djN = 0; nl = split(s, L, "\n")
    for (i = 1; i <= nl; i++) {
      if (i > 1) _djput("\n")
      n = split(L[i], P, "\\"); if (n) _djput(P[1])
      for (k = 2; k <= n; k++) {
        p = P[k]
        # An empty piece is a backslash straight after the one before: the
        # pair is one backslash, or a lone one ends the line and is kept.
        if (p == "") { _djput("\\"); if (k < n) _djput(P[++k]); continue }
        c = substr(p, 1, 1)
        if (c == "n") _djput("\n"); else if (c == "t") _djput("\t")
        else if (c == "\"" || c == "/") _djput(c); else if (c != "r") _djput("\\" c)
        _djput(substr(p, 2))
      }
    }
    return _djjoin()
  }
  function _djunq(x,   n, Q, j, m, R, h) {
    if (!index(x, "\"") && !index(x, "\047")) { printf "%s", x; return }
    n = split(x, Q, "\"")
    for (j = 1; j <= n; j++) { m = split(Q[j], R, "\047"); for (h = 1; h <= m; h++) printf "%s", R[h] }
  }
  function flatten(s,   n, L, i, l, m) {
    n = split(s, L, "\n")
    for (i = 1; i <= n; i++) {
      l = L[i]; m = length(l)
      if (i < n && substr(l, m) == "\\") { _djunq(substr(l, 1, m - 1)); continue }
      _djunq(l); if (i < n) printf " ; "
    }
  }
'
# The second is the reader, which calls only unjson and flatten from the
# decoder. FLAT is the size past which a command is read flattened, handed in
# by felix_deny_code and 256K when nothing is.
# shellcheck disable=SC2016
_FELIX_DENY_READER='
  BEGIN { RS = "\001"; SQ = "\047"; BQ = "`"; NX = 0; FB = 0; LV = 0; WN = 0; SEG = 0
    if (FLAT == "") FLAT = 262144
    PLAIN = "[^ \t\n;&|()<>\"`$\\\\#" SQ "]"; DQPLAIN = "[^\"`$\\\\]" }
  { S = unjson($0); S0 = S
    # Past 256K the reading is not worth its time inside a synchronous hook:
    # read flattened, every quote dropped, which can only refuse more.
    if (length(S) > FLAT) { flatten(S); next }
    N = split(S, C, ""); I = 1; out = code("", N)
    for (m = 1; m <= WN; m++) if (WT[m] in RUN) X[++NX] = sub_view(WB[m])
    # By number and not by for-in: reading one body can open more commands,
    # and which keys a for-in visits once the array grows differs between awks.
    for (sid = 1; sid <= SEG; sid++) if (sid in TGT) { tg = TGT[sid]; sub(/^\.\//, "", tg); if (WD[sid] != "" && tg in RUN) X[++NX] = sub_view(WD[sid]) }
    for (k = 1; k <= NX; k++) out = out " ; " X[k]
    if (FB) flatten(S0); else printf "%s", out }

  function base(w) { sub(/^.*\//, "", w); return w }
  # Text that is read in its own right, appended to the buffer and read there,
  # so the place in the outer string needs no copy to come back to.
  function append(t,   n, T, j) {
    n = split(t, T, ""); C[N + 1] = "\002"
    for (j = 1; j <= n; j++) C[N + 1 + j] = T[j]
    S = S "\002" t; N = N + 1 + n
    return n
  }
  function sub_view(t,   n, at, si, r) {
    at = N + 2; n = append(t)
    si = I; I = at; r = code("", at + n - 1); I = si
    return r
  }
  # An unquoted here-document body, which the shell expands: its $( ) and
  # backticks run.
  function expand(t,   n, at, si, lim) {
    at = N + 2; n = append(t); lim = at + n - 1
    si = I; I = at
    while (I <= lim) {
      if (C[I] == "\\") { I += 2; continue }
      if (C[I] == "$" && C[I + 1] == "(" && C[I + 2] != "(") { I += 2; X[++NX] = code(")", lim); continue }
      if (C[I] == BQ) { I++; X[++NX] = code(BQ, lim); continue }
      I++
    }
    I = si
  }
  # One command being read, per level of nesting: its words so far, and
  # whether one of them runs a script (HSH), its arguments (ARG) or its input
  # (INR), or takes files for its operands (PATHOP); whether the next word is
  # a redirect target (RED) or a here-string (HS); and what separated it from
  # the command before (SEP).
  function newseg(sep) {
    segend()
    PIN[LV] = 0; SHF[LV] = 0
    CUR[LV] = ""; NW[LV] = 0; PREV[LV] = ""; HSH[LV] = 0; ARG[LV] = 0
    INR[LV] = 0; RED[LV] = 0; HS[LV] = 0; SEP[LV] = sep; PATHOP[LV] = 0
    SID[LV] = ++SEG; FIRST[LV] = ""; PSCR[LV] = ""; SCRW[LV] = 0; RUNNEXT[LV] = 0
  }
  # A command piped into something that runs its input (PIN) makes that
  # input its script, unless the shell was handed a file or a -c script (SHF),
  # when its input is data to that script: a payload printed into `bash
  # hooks/pre-tool` runs the hook and not the payload. Decided when the
  # command ends, since the file comes after the name of the shell.
  function segend() { if (PIN[LV] && !SHF[LV]) FB = 1 }
  # A file named where it is run: in command position, or as the first
  # operand of a shell, source or `.`. Compared by its spelling, so the
  # file a here-document wrote is recognised when the same spelling runs it.
  function runs(w) { sub(/^\.\//, "", w); RUN[w] = 1 }
  function endword(   w, b) {
    w = CUR[LV]; CUR[LV] = ""
    if (SCRW[LV]) { X[++NX] = sub_view(PSCR[LV]); PSCR[LV] = ""; SCRW[LV] = 0 }
    if (w == "") return
    if (RED[LV] && !(SID[LV] in TGT) && w !~ /^\/dev\//) TGT[SID[LV]] = w
    RED[LV] = 0; HS[LV] = 0
    if (NW[LV] == 0 && w ~ /^[A-Za-z_][A-Za-z0-9_]*=/) return
    if (NW[LV] == 0) { FIRST[LV] = base(w); runs(w) }
    else if (FIRST[LV] == "tee" && w !~ /^-/ && !(SID[LV] in TGT)) TGT[SID[LV]] = w
    # -s tells a shell its script is its input and every word after it a
    # positional parameter, so no word after it is a file the shell runs:
    # bash -s /tmp/x <<EOF runs the body.
    if (HSH[LV] && NW[LV] > 0 && w ~ /^-[A-Za-z]*s[A-Za-z]*$/) RUNNEXT[LV] = 0
    if (RUNNEXT[LV] && w !~ /^-/) { runs(w); RUNNEXT[LV] = 0; SHF[LV] = 1 }
    NW[LV]++; PREV[LV] = w; b = base(w)
    # A path is data to the shell, but to cp or tee it is the file written, and
    # the marker row is about exactly that operand. So a command with a word
    # that writes its operands keeps them as text, quoted or not; sed only
    # when it edits in place.
    if (b ~ /^(cp|mv|ln|install|tee|dd|truncate|rm|touch|rsync)$/) PATHOP[LV] = 1
    if (FIRST[LV] == "sed" && w ~ /^(-[A-Za-z]*i|--in-place)/) PATHOP[LV] = 1
    if (b ~ /^(bash|sh|zsh|dash|ksh|fish|source)$/ || NW[LV] == 1 && w == ".") RUNNEXT[LV] = 1
    if (b ~ /^(bash|sh|zsh|dash|ksh|fish)$/) { HSH[LV] = 1; INR[LV] = 1 }
    if (b ~ /^(eval|ssh|su|runuser|watch)$/) { ARG[LV] = 1; INR[LV] = 1 }
    if (b == "source" || NW[LV] == 1 && w == ".") INR[LV] = 1
    if (INR[LV] && SEP[LV] == "|") PIN[LV] = 1
  }
  # Whether a quoted span here is a script something will run.
  function script() { return ARG[LV] || HSH[LV] && PREV[LV] ~ /^-[A-Za-z]*c[A-Za-z]*$/ }
  function quoted(t, glued) {
    if (HS[LV]) { if (INR[LV]) X[++NX] = sub_view(t); return "_" }
    if (script() && (SCRW[LV] || CUR[LV] == "")) { PSCR[LV] = PSCR[LV] t; SCRW[LV] = 1; SHF[LV] = 1; return "_" }
    gsub(/\n/, " ", t)
    if (RED[LV] || PATHOP[LV] || NW[LV] == 0 && CUR[LV] == "") return t
    if (t !~ /[ \t\n]/) return t
    if (t ~ /^(~\/|\.\.?\/|\$[A-Za-z_][A-Za-z0-9_]*\/|\$\{[^}]*\}\/|\$\(_\)\/)/) return t
    # Data, and kept by the command it belongs to: if that command writes a
    # file the same command line then runs, this is what the file says.
    WD[SID[LV]] = WD[SID[LV]] t "\n"
    return "_"
  }
  function word(t) { CUR[LV] = CUR[LV] t; return t }
  # An unquoted piece of a script word, which the shell joins to the rest.
  function piece(t) { if (SCRW[LV]) { PSCR[LV] = PSCR[LV] t; return "" }; return word(t) }
  function after(lim) { return I <= lim && C[I] !~ /[ \t\n;&|()<>]/ }
  function before() { return CUR[LV] != "" && CUR[LV] !~ /=$/ }
  function closeparen(lim,   d, e) {
    d = 0; e = I
    while (e <= lim) { if (C[e] == "(") d++; else if (C[e] == ")" && --d == 0) break; e++ }
    return e
  }

  # stop is "" for a whole string, ")" for a $( ), or a backtick; lim is the
  # last character of the string being read.
  function code(stop, lim,   out, ch, nx, t, e, k, d, dash, hw, hq, nh, HW, HD, HC, HQ, HSID, ls, depth, g, sv, bs, be, body) {
    # Nesting past a hundred levels is read flattened rather than recursed
    # into: BWK awk recurses on the C stack and dies near six thousand.
    if (LV >= 100) { FB = 1; I = lim + 1; return "" }
    LV++; PIN[LV] = 0; SHF[LV] = 0; newseg(""); out = ""; nh = 0; depth = 0
    while (I <= lim) {
      ch = C[I]; nx = I < lim ? C[I + 1] : ""
      if (stop == BQ && ch == BQ) { I++; break }
      if (ch == "\\") {
        if (nx == "\n") { I += 2; continue }
        out = out word(ch nx); I += 2; continue
      }
      if (ch == " " || ch == "\t") { endword(); out = out " "; I++; continue }
      if (ch == "(" && nx == "(" && CUR[LV] == "") {
        e = closeparen(lim); sv = e + 1; I += 2
        X[++NX] = code("", e - 2); I = sv; out = out word("_"); continue
      }
      if (ch == "(") { endword(); depth++; out = out "("; I++; newseg("("); continue }
      if (ch == ")") {
        endword()
        if (depth > 0) { depth--; out = out ")"; I++; newseg(")"); continue }
        if (stop == ")") { I++; break }
        out = out ")"; I++; continue
      }
      if (ch == "&" && nx == ">") { endword(); out = out "&>"; I += 2; RED[LV] = 1; continue }
      if (ch == ";" || ch == "&" || ch == "|" || ch == "\n") {
        endword(); out = out (ch == "\n" ? " ; " : ch); I++; newseg(ch)
        if (ch == "\n" && nh > 0) {
          for (k = 1; k <= nh; k++) {
            bs = I; be = 0
            while (I <= lim) {
              e = I; while (e <= lim && C[e] != "\n") e++
              ls = substr(S, I, e - I); if (HD[k]) sub(/^\t+/, "", ls)
              if (ls == HW[k]) { be = I; I = e + 1; break }
              I = e + 1
            }
            body = substr(S, bs, (be ? be : lim + 1) - bs)
            if (HC[k]) X[++NX] = sub_view(body)
            else {
              if (!HQ[k]) expand(body)
              if (HSID[k] in TGT) { WT[++WN] = TGT[HSID[k]]; sub(/^\.\//, "", WT[WN]); WB[WN] = body }
            }
          }
          nh = 0
        }
        continue
      }
      if (ch == "#" && CUR[LV] == "") { while (I <= lim && C[I] != "\n") I++; continue }
      if (ch == "$" && nx == SQ) {
        g = before(); e = I + 2; t = ""
        while (e <= lim && C[e] != SQ) { if (C[e] == "\\") { t = t C[e]; e++ }; t = t C[e]; e++ }
        I = e + 1; out = out word(quoted(t, g || after(lim))); continue
      }
      if (ch == SQ) {
        g = before(); e = I + 1; while (e <= lim && C[e] != SQ) e++
        t = substr(S, I + 1, e - I - 1); I = e + 1
        out = out word(quoted(t, g || after(lim))); continue
      }
      if (ch == "\"" || ch == "$" && nx == "\"") {
        g = before(); I += (ch == "$") ? 2 : 1; t = ""
        while (I <= lim && C[I] != "\"") {
          if (C[I] == "\\") {
            if (C[I + 1] == "\n") { I += 2; continue }
            if (C[I + 1] ~ /["\\$`]/) { t = t C[I + 1]; I += 2; continue }
            t = t C[I]; I++; continue
          }
          if (C[I] == "$" && C[I + 1] == "(" && C[I + 2] != "(") {
            if (script()) FB = 1
            I += 2; t = t "$(_)"; X[++NX] = code(")", lim); continue
          }
          if (C[I] == BQ) { if (script()) FB = 1; I++; t = t "_"; X[++NX] = code(BQ, lim); continue }
          e = I; while (e < lim && C[e + 1] ~ DQPLAIN) e++
          t = t substr(S, I, e - I + 1); I = e + 1
        }
        I++
        out = out word(quoted(t, g || after(lim))); continue
      }
      if (ch == "$" && nx == "(") {
        if (C[I + 2] == "(") {
          I++; e = closeparen(lim); t = "$" substr(S, I, e - I + 1); I = e + 1; out = out word(t); continue
        }
        if (script()) FB = 1
        I += 2; out = out word("$(_)"); X[++NX] = code(")", lim); continue
      }
      if (ch == BQ) { if (script()) FB = 1; I++; out = out word("_"); X[++NX] = code(BQ, lim); continue }
      if ((ch == "<" || ch == ">") && nx == "(") {
        endword(); if (INR[LV]) FB = 1
        I += 2; out = out word(ch "(_)"); X[++NX] = code(")", lim); continue
      }
      if (ch == "<" && nx == "<" && C[I + 2] == "<") { endword(); out = out "<<<"; I += 3; HS[LV] = 1; continue }
      if (ch == "<" && nx == "<") {
        endword(); I += 2; dash = 0; hq = 0
        if (C[I] == "-") { dash = 1; I++ }
        while (I <= lim && (C[I] == " " || C[I] == "\t")) I++
        # The whole word, as bash takes it: any quote or backslash in it,
        # E"OF" as much as "EOF", quotes the body, and is dropped from it.
        hw = ""
        while (I <= lim && C[I] !~ /[ \t\n;&|()<>]/) {
          if (C[I] == SQ || C[I] == "\"") {
            d = C[I]; hq = 1; I++
            while (I <= lim && C[I] != d) { hw = hw C[I]; I++ }
            I++; continue
          }
          if (C[I] == "\\") { hq = 1; I++; if (I > lim) break }
          hw = hw C[I]; I++
        }
        if (hw != "") { nh++; HW[nh] = hw; HD[nh] = dash; HC[nh] = INR[LV] && !SHF[LV]; HQ[nh] = hq; HSID[nh] = SID[LV] }
        out = out "<<" hw " "; continue
      }
      if (ch == "<" || ch == ">") {
        endword(); out = out ch; I++
        while (I <= lim && C[I] ~ /[>&|]/) { out = out C[I]; I++ }
        RED[LV] = 1; continue
      }
      # A run of ordinary characters in one piece: a character at a time is a
      # copy of the whole string per character in BWK awk and mawk.
      e = I; while (e < lim && C[e + 1] ~ PLAIN) e++
      out = out piece(substr(S, I, e - I + 1)); I = e + 1
    }
    endword(); segend(); LV--
    return out
  }
'
_FELIX_DENY_READ="$_FELIX_DENY_DECODE$_FELIX_DENY_READER"
