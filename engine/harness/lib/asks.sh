# Whether a session's final message asks the person something: one rule, two
# readers. felix inventory's host adapter (lib/inventory-host.sh) reads the
# final text off a transcript, and the Stop record (lib/left.sh) reads it off
# the hook's payload, as last_assistant_message. Both run the program below,
# from this one file, so the two cannot disagree about the same message; a
# second copy of the rule is how they would.
#
# Two awk fragments, each prepended to a caller's own program under LC_ALL=C,
# since the rule reads UTF-8 as bytes: _FI_HOST_ASK defines asks(t), and
# _FI_HOST_ASKTEXT defines asktext(s), which turns a JSON string value, as it
# stands between its quotes, into the text asks() reads. Nothing here runs
# git, reads a file or writes one.

# Whether a final text, decoded with its line breaks kept, asks the person
# something: asks(t) is 1 or 0. Set aside first: curly quotes read as straight
# ones, fenced blocks, code spans, double-quoted spans and blockquote lines;
# paragraphs are runs of lines between lines of only blanks. It asks when a ?
# ends a line (only * _ ) " ' and blanks after it) in the last three
# paragraphs, or when an offer below appears anywhere in it, lowercased, as
# whole words, and none of no, not, nothing, never, none is in the 40 bytes
# before it, cut after the last . ! ? ; : or line break. Measured on 227
# session endings read by hand on 2026-09-24 (rule R4 of that labelling): 36
# of 45 asks found and nothing else, over the 201 sessions sampled without
# regard to any rule; 51 hits over all 227, 50 of them asks. \047 is the
# apostrophe.
# shellcheck disable=SC2016
_FI_HOST_ASK='
  BEGIN {
    AQ_B = "(^|[^a-z0-9_])"; AQ_E = "([^a-z0-9_]|$)"; AQ_L = "[?][*_)\"\047]*[ \t\r]*(\n|$)"
    AQ_N = "(^|[^a-z])(no|not|nothing|never|none)([^a-z]|$)"
    AQ_P[1] = "your (call|decision|answer|options|side|sign-off|merge|go-ahead)"
    AQ_P[2] = "([a-z]+\047s|is|are|still|all|both) yours|yours (to|rather)"
    AQ_P[3] = "(wait(s|ing)?|blocked) (on|for) your?"
    AQ_P[4] = "needs? your?"
    AQ_P[5] = "say (so|the word|yes|if|go)"
    AQ_P[6] = "and i(\047ll| will)"
    AQ_P[7] = "(want|like) me to|(should|shall) i"
    AQ_P[8] = "if you(\047d)? rather|if you (want|prefer)[^.?!]*, i(\047ll| can| will| could)|i(\047ll| can| could) [^.?!]* if you want"
    AQ_P[9] = "(for|on) you:"
    AQ_P[10] = "(for|to) you to (decide|choose|approve|merge|review|start|run|confirm|pick)"
    AQ_NP = 10
  }
  # An offer matched in t and not negated within its clause.
  function offer(t, re,    r, s0, off, rest, w) {
    r = AQ_B "(" re ")" AQ_E; off = 0; rest = t
    while (match(rest, r)) {
      s0 = off + RSTART; w = substr(t, s0 > 40 ? s0 - 39 : 1, s0 > 40 ? 40 : s0)
      while (match(w, /[.!?;:\n]/)) w = substr(w, RSTART + 1)
      if (w !~ AQ_N) return 1
      off = s0; rest = substr(t, off + 1)
    }
    return 0
  }
  function asks(t,    L, n, i, s, fence, cur, np, par, all, l3, k) {
    n = split(t, L, "\n"); np = 0; fence = 0; cur = ""
    for (i = 1; i <= n; i++) {
      s = L[i]
      if (s ~ /^[ \t]*(```|~~~)/) { fence = !fence; s = "" }
      else if (fence) s = ""
      else {
        gsub("\342\200\234|\342\200\235", "\"", s); gsub("\342\200\231", "\047", s)
        gsub(/`[^`]*`/, "", s); gsub(/"[^"]*"/, "", s)
        if (s ~ /^[ \t]*>/) s = ""
      }
      if (s ~ /^[ \t\r]*$/) { if (cur != "") par[++np] = cur; cur = "" }
      else cur = cur (cur != "" ? "\n" : "") s
    }
    if (cur != "") par[++np] = cur
    all = ""; l3 = ""
    for (i = 1; i <= np; i++) { all = all "\n" par[i]; if (i > np - 3) l3 = l3 "\n" par[i] }
    if (l3 ~ AQ_L) return 1
    all = tolower(all)
    for (k = 1; k <= AQ_NP; k++) if (offer(all, AQ_P[k])) return 1
    return 0
  }
'

# A JSON string value, raw, decoded as the rule reads it: \n is a line break;
# \r, \t and a tab are spaces; \" \\ and \/ are the characters they escape;
# \uXXXX and any other escape stay as written. An escaped backslash is held
# aside as \001 while the others are read, so \\n stays a backslash and an n.
# Trailing spaces and line breaks are cut. What the adapter did inline before
# the Stop record needed the same text, now shared.
#
# Only the last 16 KiB of the value as the payload spells it is read, from
# the first whole line in it. Parts of the rule cost the square of what they
# read (the clause from every "i can" to the next full stop, a paragraph
# built a line at a time), and so does every gsub, and every split on more
# than one character, in the awk macOS ships (20200816): replacing the
# 190,000 spaces of a 1 MB text took it 2.2 s of CPU. The Stop record reads
# the message before the hold is decided. The longest final text of 629 real
# sessions in the 30 days to 2026-09-24 was 6.3 KB, and a question or an
# offer further back than 16 KiB is not how a session ended. The line the
# cut falls in is dropped whole, found from where the escapes around the cut
# pair up: the run of backslashes the cut ends on, odd or even, says, found
# by one match from the last byte that is not one. What is dropped is read
# again only when it holds a fence mark, to count the lines that open or
# close a fence (not one indented by an escaped tab): it is split at each
# backslash, one character, and its escapes paired. A fence it leaves open
# is opened again at the start, so the code after the cut is still read as
# code. Every pass over the whole message costs time in proportion to its
# length, and the trailing blanks go by one match from the last character
# that is not one, not by a sub.
# shellcheck disable=SC2016
_FI_HOST_ASKTEXT='
  function asktext(s,    c, o, n, P, k, e, f, i, l, d) {
    if (length(s) > 16384) {
      c = length(s) - 16384; o = substr(s, 1, c); s = substr(s, c + 1)
      # e: the first byte kept is the second half of an escape, as it is when
      # the run of backslashes the cut ends on is odd; l: it starts a line.
      e = (match(o, /[^\\]\\*$/) ? c - RSTART : c) % 2
      l = !e && substr(o, c, 1) == "n" && (match(substr(o, 1, c - 1), /[^\\]\\*$/) ? c - 1 - RSTART : c - 1) % 2
      # d: how many bytes kept belong to the line the cut falls in.
      if (e && substr(s, 1, 1) == "n") d = 1
      else if (l) d = 0
      else {
        n = split(substr(s, e + 1), P, "\\"); d = e; i = length(P[1]); e = 0
        for (k = 2; k <= n; k++) {
          if (e) e = 0; else if (P[k] == "") e = 1; else if (substr(P[k], 1, 1) == "n") { d += i + 2; break }
          i += length(P[k]) + 1
        }
      }
      o = o substr(s, 1, d); s = substr(s, d + 1); f = 0
      if (index(o, "```") || index(o, "~~~")) {
        n = split(o, P, "\\"); e = 0; f = (P[1] ~ /^[ \t]*(```|~~~)/)
        for (k = 2; k <= n; k++)
          if (e) e = 0; else if (P[k] == "") e = 1; else if (P[k] ~ /^n[ \t]*(```|~~~)/) f = !f
      }
      if (f) s = "```\\n" s
    }
    gsub(/\\\\/, "\001", s); gsub(/\\n/, "\n", s); gsub(/\\[nrt]/, " ", s)
    gsub(/\\"/, "\"", s); gsub(/\\\//, "/", s); gsub(/\t/, " ", s)
    s = match(s, /[^ \n][ \n]*$/) ? substr(s, 1, RSTART) : ""
    o = ""; while (i = index(s, "\001")) { o = o substr(s, 1, i - 1) "\\"; s = substr(s, i + 1) }
    return o s
  }
'
