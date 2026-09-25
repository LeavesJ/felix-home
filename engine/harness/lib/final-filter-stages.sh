# Which commands succeed whatever they read: the stage list under
# final-filter.sh.
#
# ff_filter(name, a, b) answers for the command `name` with the arguments held
# in FFA[FFD, a..b]. It says yes only when, with those arguments, the command
# reads its standard input and nothing in that input can make it exit
# non-zero. A command that reads a file operand, or whose option makes it a
# check, can fail, so it is not a final filter and a pipeline ending in it is
# left alone:
#
#   cat, tac, head, tail, sort, wc, cut, paste, nl, fold, rev, column,
#   expand, unexpand   an input file operand makes each of them a reader of
#                      that file. `-` is standard input for cat, paste, sort,
#                      cut and nl on macOS as on GNU; macOS head, tail, wc,
#                      fold, rev, column and expand open a file named "-".
#   sort               -c, -C and --check fail on unsorted input.
#   uniq               no operand, or `-` and then its output file.
#   tee                always: its operands are its outputs.
#   tr                 its operands are sets, and it takes two, or one with
#                      -d or -s; any other count is a usage error, which
#                      fails every time.
#   sed                only with a script in view (the first operand, or -e),
#                      no -f, no -i, no file operand, and no q or Q followed
#                      by an exit code, which GNU sed returns on a match.
#   awk                only with a program in view, no operand but `-` and
#                      assignments, and nothing in the program that is
#                      fatal on some input: exit, printf, a division or
#                      modulo (by zero), a computed field `$(`, a field named
#                      by a variable, a `~` against anything but a regex
#                      literal, getline, system, close, split, sub, gsub,
#                      match, and any `<`, `>` or `|` inside an action, which
#                      is a redirection as often as a comparison.
#   xargs              only with -0 or -d, running echo or true or nothing:
#                      without them it fails on an unmatched quote in its
#                      input.
#   true, :, echo      always.
#
# An unknown option, long or short, makes the answer no. Some filters also
# fail for reasons that are not the command feeding them: an output file that
# cannot be opened, a byte BSD cut, tr, sed or sort rejects in a UTF-8 locale,
# a GNU-only option on macOS. Those failures say nothing about the work before
# the pipe, and the stage still counts.

FELIX_FINAL_FILTER_STAGES='
# Options of a filter: arg are letters taking an argument, ok the letters
# allowed (* for any), bad the letters that make it a check; lok and larg the
# long options allowed, larg those taking an argument. opok 1 when operands
# are not files, dash 1 when an operand of - is standard input.
function ff_opts(a, b, arg, ok, bad, lok, larg, opok, dash,    j, v, k, c, nm) {
  FFON = 0
  for (j = a; j <= b; j++) {
    v = FFA[FFD, j]
    if (v == "--") { for (j++; j <= b; j++) { FFO[++FFON] = FFA[FFD, j]; if (!opok && !(dash && FFA[FFD, j] == "-" && !FFAY[FFD, j])) return 0 }; return 1 }
    if (v == "-" || v !~ /^-/ || (FFAY[FFD, j] && FFAR[FFD, j] !~ /^-/)) {
      FFO[++FFON] = v; if (!opok && !(dash && v == "-" && !FFAY[FFD, j])) return 0; continue }
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
  if (nm == "cat") return ff_opts(a, b, "", "benstuv", "", " number number-nonblank squeeze-blank show-nonprinting ", "", 0, 1)
  if (nm == "tac") return ff_opts(a, b, "s", "br", "", " before regex ", " separator ", 0, 0)
  if (nm == "head") return ff_opts(a, b, "nc", "*", "", " quiet silent verbose zero-terminated ", " lines bytes ", 0, 0)
  if (nm == "tail") return ff_opts(a, b, "ncbs", "*", "", " quiet silent verbose zero-terminated follow retry ", " lines bytes sleep-interval pid max-unchanged-stats ", 0, 0)
  if (nm == "tee") return ff_opts(a, b, "", "aip", "", " append ignore-interrupts output-error ", "", 1, 1)
  if (nm == "sort") return ff_opts(a, b, "kotTS", "*", "cC", " ignore-leading-blanks dictionary-order ignore-case general-numeric-sort ignore-nonprinting month-sort human-numeric-sort numeric-sort random-sort reverse version-sort merge stable unique zero-terminated debug sort ", " key output field-separator temporary-directory buffer-size parallel random-source compress-program batch-size ", 0, 1)
  if (nm == "uniq") return ff_opts(a, b, "fsw", "*", "", " count repeated all-repeated group ignore-case unique zero-terminated ", " skip-fields skip-chars check-chars ", 1, 0) && (FFON == 0 || (FFON <= 2 && FFO[1] == "-"))
  if (nm == "wc") return ff_opts(a, b, "", "clmwL", "", " bytes chars lines words max-line-length ", "", 0, 0)
  if (nm == "tr") return ff_tr(a, b)
  if (nm == "cut") return ff_opts(a, b, "bcfd", "nsz", "", " complement only-delimited zero-terminated ", " bytes characters fields delimiter output-delimiter ", 0, 1)
  if (nm == "paste") return ff_opts(a, b, "d", "sz", "", " serial zero-terminated ", " delimiters ", 0, 1)
  if (nm == "nl") return ff_opts(a, b, "bdfhilnsvw", "p", "", " no-renumber ", " body-numbering section-delimiter footer-numbering header-numbering line-increment join-blank-lines number-format number-separator starting-line-number number-width ", 0, 1)
  if (nm == "fold") return ff_opts(a, b, "w", "bs", "", " bytes spaces ", " width ", 0, 0)
  if (nm == "rev") return ff_opts(a, b, "", "", "", "", "", 0, 0)
  if (nm == "column") return ff_opts(a, b, "cs", "tx", "", " table ", " separator columns ", 0, 0)
  if (nm == "expand" || nm == "unexpand") return ff_opts(a, b, "t", "ai", "", " initial first-only all ", " tabs ", 0, 0)
  if (nm == "sed") return ff_sed(a, b)
  if (nm ~ /^(awk|gawk|mawk|nawk)$/) return ff_awk(a, b)
  if (nm == "xargs") return ff_xargs(a, b)
  return 0
}
function ff_tr(a, b,    j, v, d, s) {
  if (!ff_opts(a, b, "", "cCdst", "", " complement delete squeeze-repeats truncate-set1 ", "", 1, 1)) return 0
  d = 0; s = 0
  for (j = a; j <= b; j++) { v = FFA[FFD, j]; if (v == "--") break
    if (v ~ /^-[cCdst]+$/) { if (index(v, "d")) d = 1; if (index(v, "s")) s = 1 }
    else if (v == "--delete") d = 1; else if (v == "--squeeze-repeats") s = 1 }
  return FFON == 2 ? (!d || s) : (FFON == 1 && (d != s))
}
function ff_sed(a, b,    j, v, k, c, sc, got, nm, opn) {
  sc = ""; got = 0; opn = 0
  for (j = a; j <= b; j++) {
    v = FFA[FFD, j]
    if (opn || v == "-" || v !~ /^-/ || (FFAY[FFD, j] && FFAR[FFD, j] !~ /^-/)) {
      if (!got) { if (FFAY[FFD, j]) return 0; sc = v; got = 1; continue }
      return 0 }
    if (v == "--") { opn = 1; continue }
    if (v ~ /^--/) { nm = substr(v, 3); sub(/=.*/, "", nm)
      if (nm == "expression") {
        if (index(v, "=")) v = substr(v, index(v, "=") + 1)
        else { if (++j > b || FFAY[FFD, j]) return 0; v = FFA[FFD, j] }
        sc = sc "\n" v; got = 1; continue }
      if (index(" quiet silent regexp-extended null-data zero-terminated separate unbuffered posix debug sandbox ", " " nm " ")) continue
      return 0 }
    for (k = 2; k <= length(v); k++) {
      c = substr(v, k, 1)
      if (c == "e" || c == "l") {
        if (k < length(v)) v = substr(v, k + 1); else { if (++j > b || FFAY[FFD, j]) return 0; v = FFA[FFD, j] }
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
    if (FFAR[FFD, j] ~ /^[A-Za-z_][A-Za-z0-9_]*=/ || (v == "-" && !FFAY[FFD, j])) continue
    return 0
  }
  return got && ff_awkprog(p)
}
# A slash after one of ( , { } ; ~ ! & | ? : or at the start is a regex
# literal; anywhere else it is read as division, which admits.
function ff_awkprog(p,    n, i, c, prev, t, d) {
  n = length(p); prev = ""; t = ""; d = 0
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
    if (c == "{") d++
    if (c == "}") d--
    if (d > 0 && (c == ">" || c == "<")) return 0
    if (d > 0 && c == "|" && substr(p, i + 1, 1) != "|" && prev != "|") return 0
    if (c != " " && c != "\t" && c != "\n") prev = c
    t = t c
  }
  for (i = 1; i <= length(t); i++) if (substr(t, i, 1) == "$") {
    c = substr(t, i + 1, 1)
    if (c ~ /[0-9]/ || (substr(t, i + 1, 2) == "NF" && substr(t, i + 3, 1) !~ /[A-Za-z0-9_]/)) continue
    return 0 }
  if (t ~ /~[ \t]*([^ \tR]|$)/) return 0
  return t !~ /(^|[^A-Za-z0-9_])(exit|printf|sprintf|getline|system|close|split|sub|gsub|match)([^A-Za-z0-9_]|$)/
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
  v = FFA[FFD, j]; sub(/^\/.*\//, "", v)
  return v == "echo" || v == "true"
}
'
