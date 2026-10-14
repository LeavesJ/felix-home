rm -rf "$_cucrp" "$_cucrr" "$_cucrhome" "$TMP/cucr-plugin" "$MEM/cucrproj"
rm -f "$TMP/cucr-setup-ran" "$TMP/cucr-maint-ran"
[ -d "$FROOT/state" ] && find "$FROOT/state" -name '*cucrproj*' -exec rm -rf {} + 2>/dev/null
case "$_cucrmade" in *commission*) rmdir "$FROOT/state/commission" 2>/dev/null ;; esac
case "$_cucrmade" in state*) rmdir "$FROOT/state" 2>/dev/null ;; esac
is  "and this block leaves the projects, the state and the memory as it found them" "$(_cucrfixture)" "$_cucrfound"
unset -f _cucrfixture _cucrlib _cucrnext _cucrpulse _cucrcli _cucrline _cucrsays _cucrboth _cucrran _cucrstart _cucrowed _cucrseen
unset _cucrfound _cucrmade _cucrp _cucrr _cucrhome _cucrwhy _cucrsu1 _cucrms1 _cucrms0 _cucrsp1 _cucrnx1 _cucrnx0 _cucrn6 _cucrpu1 \
      _cucrout _cucrrc _cucrunread _cucrs1 _cucrs2 _cucrs3 _cucrow

# A table command whose last stage succeeds whatever it is fed is refused.
#
# Every table runner evaluates a row with pipefail off: probes, obligations,
# setup and maintenance each start a `bash -c`, and commissioning evaluates
# in-process under `set +o pipefail`, as the section above pins. So a
# pipeline's status is its last stage's, and `npm test 2>&1 | tail -20` reads
# done or SATISFIED when the tests fail, because tail exits 0 whatever it
# reads. lib/final-filter.sh names such a stage, and the four columns where an
# unfailable command reads as a pass refuse the row: commissioning's check,
# obligations' evidence, setup's check and maintenance's check. The columns
# where one only asks more are not judged: a commissioning `when`, an
# obligation's `applies`, and a probe's `when`, probe and witness.
#
# Written blind, from the contract and before the library existed. The
# classifier's cases are the contract's own examples plus one case per filter
# and per condition, and every refusal has an admitted partner near it: a
# false refusal fails a project's gate, where a false admission only leaves
# today's hole, so the admitted half is the one that must not regress. Two
# shapes are red against the engine this replaces, one in each direction:
# commissioning refused any check holding `| head -`, so
# `[ "$(x | head -1)" = y ]` was malformed, and nothing refused
# `x | tail -20 || exit 1`.
#
# The table libraries are sourced the way their neighbours source them, and
# never with final-filter.sh alongside: a table library that assumed its
# classifier was already loaded would admit every row wherever it was not,
# which is the open direction. Every table touched is restored below and
# every helper unset.
_ffT="$(printf '\t')"
_ffc() {   # text -> "<exit>|<what it printed>"
  local _o _r
  _o="$( . "$REAL_HARNESS/lib/final-filter.sh" 2>/dev/null || exit 3
         felix_final_filter "$1" </dev/null 2>/dev/null )"; _r=$?
  printf '%s|%s' "$_r" "$_o"
}
_ffnot() { if [ -e "$1" ]; then printf 'ran\n'; else printf 'not run\n'; fi; }

is  "sourcing lib/final-filter.sh defines felix_final_filter" \
    "$( . "$REAL_HARNESS/lib/final-filter.sh" 2>/dev/null; type -t felix_final_filter )" "function"
_ffo="$( . "$REAL_HARNESS/lib/final-filter.sh" 2>/dev/null || exit 3
         felix_final_filter 'npm test 2>&1 | tail -20' </dev/null )"; _ffr=$?
is  "felix_final_filter exits 0 on a text it refuses"              "$_ffr" "0"
is  "and prints one line for a text it refuses, the final filter's name" "$(printf '%s\n' "$_ffo" | grep -c .)|$_ffo" "1|tail"
_ffo="$( . "$REAL_HARNESS/lib/final-filter.sh" 2>/dev/null || exit 3
         felix_final_filter 'npm test 2>&1 | grep -q passed' </dev/null )"; _ffr=$?
is  "felix_final_filter exits 1 on a text it admits"               "$_ffr" "1"
is  "and prints nothing for a text it admits"                       "$_ffo" ""

# One assertion per line: the stage the classifier must print, or `-` for a
# text it must admit, then the text, then why. Read verbatim, so quotes,
# backslashes and `$( )` are the row's own.
while IFS= read -r _ffl; do
  case "$_ffl" in ''|'#'*) continue ;; esac
  _ffstage="${_ffl%%@@*}"; _ffl="${_ffl#*@@}"; _fftx="${_ffl%%@@*}"; _ffwhy="${_ffl#*@@}"
  if [ "$_ffstage" = "-" ]; then
    is "felix_final_filter admits [$_fftx]: $_ffwhy" "$(_ffc "$_fftx")" "1|"
  else
    is "felix_final_filter refuses [$_fftx] and names $_ffstage: $_ffwhy" "$(_ffc "$_fftx")" "0|$_ffstage"
  fi
done <<'FFCASES'
# The shape the contract opens with, and the name as the shell resolves it.
tail@@npm test 2>&1 | tail -20@@failing tests would read as a pass
tail@@x | /usr/bin/tail -1@@a path prints the command's name
tail@@x | \tail -1@@a backslash does not hide the command
tail@@x | 'tail' -1@@nor do quotes
tail@@x | command tail -1@@nor command
tail@@x | env LC_ALL=C tail -1@@nor env with an assignment
tail@@x | LC_ALL=C tail -1@@nor an assignment in front
tail@@x | nice tail -1@@nor nice
tail@@x | exec tail -1@@nor exec
sort@@x | LC_ALL=C sort@@an assignment in front of sort prints sort
# Every filter the contract lists, as the last stage.
cat@@x | cat@@cat with no operand
cat@@x | cat -@@an operand of exactly - is standard input
-@@x | tac@@amended: tac is not on macOS, where the row exits 127
head@@x | head -1@@head
tail@@x | tail@@tail with no operand
tail@@x | tail -n 20@@an option's argument is not a file operand
tee@@x | tee out.log@@tee, whose operands are output files
tee@@x | tee -a a.log b.log@@tee appending to two outputs
sort@@x | sort -u@@sort without a check flag
sort@@x | sort -rn@@sort reversed and numeric
uniq@@x | uniq@@uniq with no operand
uniq@@x | uniq -c@@uniq counting
uniq@@x | uniq - counts.txt@@uniq whose first operand is -, its second being output
wc@@x | wc -l@@wc
tr@@x | tr -d '\r'@@tr, whose operands are sets and never files
tr@@x | tr a-z A-Z@@tr translating
cut@@x | cut -f1@@cut
paste@@x | paste -s -@@paste
nl@@x | nl@@nl
fold@@x | fold -w 80@@fold
rev@@x | rev@@rev
-@@x | column -t@@amended: macOS column fails on a line past about 2 KB, exit 1 on one of 3000 bytes
expand@@x | expand@@expand
unexpand@@x | unexpand -a@@unexpand
true@@x | true@@true
:@@x | :@@the colon builtin
echo@@x | echo done@@echo, whose operands are words it prints
sed@@x | sed -n 's/a/b/p'@@sed with a literal script
sed@@x | sed -e 's/a/b/' -e 's/c/d/'@@sed whose script comes from -e
sed@@x | sed 5q@@sed whose q carries no exit code
awk@@x | awk '{ print $1 }'@@awk with a literal program
awk@@x | awk '{ print $1 }' -@@awk whose other operand is -
awk@@x | awk '{ print $1 }' FS=,@@awk whose other operand is an assignment
awk@@x | awk '/^#/ { next } { print "a/b", "50%" }'@@awk whose / and % sit only in a regex literal and a string
-@@x | xargs -0 echo@@amended: xargs fails on an argument past ARG_MAX, exit 1 on macOS for one of 2 MB
-@@x | xargs -0@@amended: so with no command
-@@x | xargs --null true@@amended: and with --null and true
-@@x | xargs -d '\n' echo@@amended: macOS xargs has no -d, a usage error every time
# Redirections other than of standard input change nothing.
tail@@x 2>&1 | tail -3@@a redirection on the producer
tail@@x | tail -5 >/dev/null@@standard output to /dev/null
tail@@x | tail -5 2>/dev/null@@standard error to /dev/null
tail@@x | tail -5 2>&1@@2>&1 on the filter
tail@@x | tail -5 &>/dev/null@@&> on the filter
tail@@x | tail -5 >out@@output to a file
tail@@x |tail>/dev/null@@with no spaces at all
# Lists, groups and compounds, per path.
tail@@x | tail -20 || exit 1@@the || branch never runs
tail@@true && x | tail@@after an && that cannot fail, the status is tail's
tail@@x || y | tail@@the status after || is tail's
tail@@y; x | tail@@the last command decides, and it is tail
tail@@{ x | tail; }@@a group carries its inner status
tail@@( x | tail )@@so does a subshell
tail@@if a; then x | tail; fi@@the status of a then branch counts
tail@@if a; then true; else x | tail; fi@@and of an else branch
tail@@case "$v" in a) x | tail ;; esac@@and of a case branch
tail@@for f in a b; do x | tail; done@@and of a loop body
tail@@sh -c 'x | tail'@@sh -c with a literal script is read as that script
tail@@bash -c 'x | tail -1'@@and bash -c
tail@@eval 'x | tail'@@and eval
tail@@x |& tail -1@@|& joins two stages as | does
# Admitted: another command decides.
-@@x | tail && y@@y decides
-@@a && x | tail@@a can fail, so the text can
-@@if a; then y; else x | tail; fi@@y can fail, so the text can
-@@x | tail; y@@y decides after ;
-@@x | tail &@@a background job's status is 0, not this shape
-@@! x | tail@@a negation always fails, a different defect
# Admitted: words are words.
-@@grep -qE 'a|sort -u' f@@a pipe inside single quotes is a word
-@@grep -q "x | tail" f@@and inside double quotes
-@@[ "$(x | head -1)" = y ]@@a | head inside $( ) is a word
-@@[ "`x | tail -1`" = y ]@@and inside backticks
-@@[ -n "${v:-x | tail}" ]@@and inside ${ }
-@@diff <(x | sort) <(y | sort)@@and inside <( )
-@@x | head -5 | grep -q y@@head mid-pipeline
-@@x | grep -q y # | tail@@a comment is not a stage
-@@test -f a || cat b@@cat with a file operand, and no pipe
-@@cat b@@one stage is not a pipeline
-@@tail -1 file@@nor is one tail reading a file
-@@true@@nor one true
# Admitted when uncertain.
-@@set -o pipefail; x | tail@@a text naming pipefail
-@@x | tail # the caller sets PIPEFAIL@@in any case
-@@[ -z "$PIPE_FAIL" ]; x | tail@@or spelt pipe_fail
-@@f() { x | tail; }; f@@a text defining a function
-@@function f { x | tail; }; f@@with the function keyword
-@@x | tail '@@an unbalanced quote
-@@( x | tail@@an unbalanced parenthesis
-@@x | tail; fi@@a stray fi
-@@x | $T -1@@the final stage's name is an expansion
-@@x | "$T"@@a quoted one
-@@x | ${T:-tail}@@a braced one
-@@x | $(echo tail)@@a command substitution
# Admitted: each condition's counter-case.
-@@x | sort -c@@sort -c fails on unsorted input
-@@x | sort -C@@and so does sort -C
-@@x | sort --check@@and sort --check
-@@x | sort --check=quiet@@and sort --check=quiet
-@@x | sed -n '/x/q1'@@a sed q with an exit code fails on content
-@@x | sed '/x/Q3'@@and a Q with one
-@@x | sed -f f@@a sed script from a file is not visible
-@@x | sed -i 's/a/b/'@@sed -i
-@@x | sed 's/a/b/' f@@sed with a file operand
-@@x | awk '{print 1/$1}'@@awk dividing, which is fatal by zero
-@@x | awk '{print $1 % 2}'@@awk taking a modulo
-@@x | awk '{exit 1}'@@awk with an exit
-@@x | awk '{printf "%s", $1}'@@awk with printf
-@@x | awk '{ s = sprintf("%d", $1); print s }'@@awk with sprintf
-@@x | awk -f p@@an awk program from a file
-@@x | awk '{ print }' f@@awk with a file operand
-@@x | xargs echo@@xargs without -0 fails on an unmatched quote
-@@x | xargs -0 rm@@xargs -0 running a command other than echo or true
-@@x | uniq a@@uniq whose first operand is an input file
-@@x | tail -1 file@@tail with a file operand
-@@x | head -n 5 f@@head with a file operand after an option's argument
-@@x | cat b@@cat with a file operand
-@@x | tail < file@@standard input redirected with <
-@@x | tail <<< y@@with <<<
-@@x | tail 0< f@@with 0<
-@@x | tail <&3@@with <&
-@@x | tail 0>f@@with 0>
# Admitted: not a final filter at all.
-@@x | grep -q y@@grep
-@@x | jq .a@@jq
-@@x | test -s /dev/stdin@@test
-@@x | python3 -c 'import sys'@@python3
-@@x | printf ok@@printf
-@@x | felix_probe_rows p@@an engine function
FFCASES
# The three that need a newline in them.
is  "felix_final_filter refuses a newline list whose last line ends in tail, a newline acting as ;" \
    "$(_ffc "$(printf 'y\nx | tail')")" "0|tail"
is  "felix_final_filter admits a newline list whose last line is y, which decides" \
    "$(_ffc "$(printf 'x | tail\ny')")" "1|"
is  "felix_final_filter admits a text holding a here-document" \
    "$(_ffc "$(printf 'cat <<EOF | tail\nx\nEOF')")" "1|"

# Per table. The four judged columns refuse a row the classifier names and say
# which stage; the shapes the old head patterns caught by accident are
# admitted; and a column that is not judged behaves exactly as before. Each
# refused row carries a side effect, so "refused" can be told from "ran and
# was read as failing".
_ffw="$FROOT/projects/widget"
for _fft in obligations.tsv setup.tsv maintenance.tsv; do
  rm -f "$TMP/ff-w-$_fft.keep"
  [ -f "$_ffw/$_fft" ] && cp "$_ffw/$_fft" "$TMP/ff-w-$_fft.keep"
done
cp "$CMP/commissioning.tsv" "$TMP/ff-cm.keep"
rm -f "$TMP/ffcran" "$TMP/fforan" "$TMP/ffsran" "$TMP/ffmran"

# commissioning.tsv: check is judged, when is not.
_ffcrow() { printf '%s\t-\t-\t%s\t-\t%s\t9' "$1" "$2" "$3"; }   # need, when, check
_ffcmal() { _cm felix_commission_malformed "$CMP" | awk -F'\t' -v n="$1" '$1 == n { print $2 }'; }
_cmtable "$(_ffcrow ffc_last    - 'printf a | tail -1')" \
         "$(_ffcrow ffc_orexit  - 'printf a | tail -20 || exit 1')" \
         "$(_ffcrow ffc_andsort - 'true && ls src | sort')" \
         "$(_ffcrow ffc_ran     - "touch \"$TMP/ffcran\"; false | tail -1")" \
         "$(_ffcrow ffc_headsub - '[ "$(printf a | head -1)" = a ]')" \
         "$(_ffcrow ffc_headmid - 'printf y | head -5 | grep -q y')" \
         "$(_ffcrow ffc_when    'false | tail -1' 'test -f src/a.txt')" \
         "$(_ffcrow ffc_neg     - '! true')" \
         "$(_ffcrow ffc_grep    - 'ls src | grep -q a.txt')" \
         "$(_ffcrow ffc_guard   - 'test -f src/a.txt && ls src | sort')"
is  "commissioning rows omit every check a final filter makes unfailable, and keep the rest in file order" \
    "$(_cm felix_commission_rows "$CMP" | cut -f1 | tr '\n' ' ')" "ffc_headsub ffc_headmid ffc_when ffc_grep ffc_guard "
has "a commissioning check ending in | tail is malformed, and the reason names tail" \
    "$(_ffcmal ffc_last)" "tail"
has "and says that tail stage succeeds whatever it is fed" \
    "$(_ffcmal ffc_last)" "succeeds whatever it is fed"
has "a commissioning check ending in | tail -20 || exit 1 is malformed, because the || branch never runs" \
    "$(_ffcmal ffc_orexit)" "succeeds whatever it is fed"
has "a commissioning check whose status after && is sort's is malformed, naming sort" \
    "$(_ffcmal ffc_andsort)" "sort"
is  "a commissioning check with | head -1 inside \$( ) is not malformed" "$(_ffcmal ffc_headsub)" ""
is  "a commissioning check with head mid-pipeline before grep -q is not malformed" "$(_ffcmal ffc_headmid)" ""
is  "a commissioning when ending in | tail is not judged" "$(_ffcmal ffc_when)" ""
is  "a commissioning check whose guard can fail before | sort is not malformed" "$(_ffcmal ffc_guard)" ""
[ -n "$(_ffcmal ffc_neg)" ] \
  && ok  "a negated commissioning check is still malformed" \
  || bad "a negated commissioning check is still malformed" "no reason printed for ffc_neg"
_ffcrun="$(_cm felix_commission_run "$CMP" "$CMR" -)"
_ffcst() { printf '%s\n' "$_ffcrun" | awk -F'\t' -v n="$1" '$1 == n { print $2 }'; }
is  "the check with | head -1 inside \$( ) is asked, and done"          "$(_ffcst ffc_headsub)" "done"
is  "the check with head mid-pipeline is asked, and done"              "$(_ffcst ffc_headmid)" "done"
is  "a row whose when ends in | tail applies, and its check decides it" "$(_ffcst ffc_when)"    "done"
is  "the check whose guard can fail before | sort is asked, and done"    "$(_ffcst ffc_guard)"   "done"
is  "a refused check is no row of the run" \
    "$(printf '%s\n' "$_ffcrun" | awk -F'\t' '$1 ~ /^ffc_(last|orexit|andsort|ran)$/' | grep -c .)" "0"
_ffccli="$( cd "$CMR" && PATH="$CMSTUB:$PATH" "$FELIX" commission --status 2>&1 )"
has "felix commission --status prints a refused check among the rows that name a need and nothing readable" \
    "$(printf '%s\n' "$_ffccli" | sed -n '/rows that name a need and nothing readable/,$p' | grep ' ffc_last ')" \
    "succeeds whatever it is fed"
has "and counts the four refused checks and the negated one as malformed" "$_ffccli" ", 5 malformed"
is  "and reads the check with | head -1 inside \$( ) done" \
    "$(printf '%s\n' "$_ffccli" | awk '$2 == "ffc_headsub" { print $1 }')" "done"
is  "and neither the library nor the command ran a refused commissioning check" "$(_ffnot "$TMP/ffcran")" "not run"

# obligations.tsv: evidence is judged, applies is not.
_ffob()   { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/probes.sh"
              . "$FROOT/harness/lib/obligations.sh"; "$@" ) 2>/dev/null; }
_ffomal() { _ffob felix_obligation_malformed "$_ffw" | grep "^$1: "; }
{ printf 'fixture\tRELEASE_BLOCKING\tdeterministic\t-\ttrue\t-\ta fixture owes one thing, and it holds\n'
  printf 'ffo_last\tADVISORY\tdeterministic\t-\t%s\t-\tevidence ending in tail\n'         'printf a | tail -1'
  printf 'ffo_orexit\tADVISORY\tdeterministic\t-\t%s\t-\tevidence ending in wc or exit\n' 'printf a | wc -l || exit 1'
  printf 'ffo_ran\tADVISORY\tdeterministic\t-\t%s\t-\tevidence with a side effect\n'      "touch \"$TMP/fforan\"; false | tail -1"
  printf 'ffo_headsub\tADVISORY\tdeterministic\t-\t%s\t-\thead in a substitution\n'       '[ "$(printf a | head -1)" = a ]'
  printf 'ffo_headmid\tADVISORY\tdeterministic\t-\t%s\t-\thead mid-pipeline\n'            'printf y | head -5 | grep -q y'
  printf 'ffo_applies\tADVISORY\tdeterministic\t%s\ttrue\t-\tan applies ending in tail\n' 'false | tail -1'
} > "$_ffw/obligations.tsv"
is  "obligation rows omit every evidence a final filter makes unfailable, and keep the rest in file order" \
    "$(_ffob felix_obligation_rows "$_ffw" | cut -f1 | tr '\n' ' ')" "fixture ffo_headsub ffo_headmid ffo_applies "
has "an evidence ending in | tail is refused as <obligation>: <reason>, naming tail" "$(_ffomal ffo_last)" "tail"
has "and says the evidence's tail succeeds whatever it is fed" "$(_ffomal ffo_last)" "succeeds whatever it is fed"
has "an evidence ending in | wc -l || exit 1 is refused, naming wc" "$(_ffomal ffo_orexit)" "wc"
is  "an evidence with | head -1 inside \$( ) is not refused" "$(_ffomal ffo_headsub)" ""
is  "an evidence with head mid-pipeline before grep -q is not refused" "$(_ffomal ffo_headmid)" ""
is  "an applies ending in | tail is not judged" "$(_ffomal ffo_applies)" ""
_fforun="$(_ffob felix_obligations_run "$_ffw" "$REPO")"
_ffost() { printf '%s\n' "$_fforun" | awk -F'\t' -v n="$1" '$1 == n { print $4 "\t" $5 }'; }
is  "the evidence with | head -1 inside \$( ) is examined, and holds" "$(_ffost ffo_headsub)" "ACTIVE${_ffT}SATISFIED"
is  "the evidence with head mid-pipeline is examined, and holds"      "$(_ffost ffo_headmid)" "ACTIVE${_ffT}SATISFIED"
is  "an obligation whose applies ends in | tail applies, as before"   "$(_ffost ffo_applies)" "ACTIVE${_ffT}SATISFIED"
_ffocli="$(cd "$REPO" && "$FELIX" obligations 2>&1)"
has "felix obligations prints the refused evidence under rows refused" "$_ffocli" "rows refused"
has "naming the obligation and saying its stage succeeds whatever it is fed" \
    "$(printf '%s\n' "$_ffocli" | grep 'ffo_last: ')" "succeeds whatever it is fed"
has "and reports the obligation whose applies ends in | tail on its axes" \
    "$(printf '%s\n' "$_ffocli" | grep ' ffo_applies ')" "ACTIVE    SATISFIED"
is  "and neither the library nor the command ran a refused evidence" "$(_ffnot "$TMP/fforan")" "not run"

# setup.tsv: check is judged, and a refused one is never run.
_ffsu() { ( cd "$REPO" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
            . "$FROOT/harness/lib/stack.sh"; . "$FROOT/harness/lib/setup.sh"; "$@" ) 2>/dev/null; }
{ printf 'ffs_true\ta step whose check is one command\talways\ttrue\n'
  printf 'ffs_ran\ta step whose status is a final tail\talways\t%s\n'      "touch \"$TMP/ffsran\"; false | tail -1"
  printf 'ffs_or\ta step ending in sort or exit\talways\t%s\n'             'printf a | sort || exit 1'
  printf 'ffs_mid\ta step with head mid-pipeline\talways\t%s\n'            'printf y | head -5 | grep -q y'
  printf 'ffs_sub\ta step with head in a substitution\talways\t%s\n'       '[ "$(printf a | head -1)" = a ]'
} > "$_ffw/setup.tsv"
_ffsust="$(_ffsu felix_setup_status "$_ffw")"
has "a setup check whose status is a final tail's reads todo"   "$_ffsust" "todo${_ffT}ffs_ran${_ffT}"
is  "and the refused setup check is never run"                "$(_ffnot "$TMP/ffsran")" "not run"
has "a setup check ending in | sort || exit 1 reads todo"      "$_ffsust" "todo${_ffT}ffs_or${_ffT}"
has "a setup check with head mid-pipeline is run, and done"    "$_ffsust" "done${_ffT}ffs_mid${_ffT}"
has "a setup check with head inside \$( ) is run, and done"    "$_ffsust" "done${_ffT}ffs_sub${_ffT}"
has "a setup check of one command is still done"               "$_ffsust" "done${_ffT}ffs_true${_ffT}"
_ffsumal="$(_ffsu felix_setup_malformed "$_ffw")"
_ffsuwhy() { printf '%s\n' "$_ffsumal" | awk -F'\t' -v n="$1" '$1 == n { print $2 }'; }
has "felix_setup_malformed prints the refused row as id and a reason naming tail" "$(_ffsuwhy ffs_ran)" "tail"
has "and saying the setup check's tail succeeds whatever it is fed"             "$(_ffsuwhy ffs_ran)" "succeeds whatever it is fed"
has "and the row ending in | sort || exit 1, naming sort"                       "$(_ffsuwhy ffs_or)"  "sort"
is  "and felix_setup_malformed prints no row it admits" \
    "$(printf '%s\n' "$_ffsumal" | awk -F'\t' '$1 ~ /^ffs_(true|mid|sub)$/' | grep -c .)" "0"
rm -f "$TMP/ffsran"
_ffsucli="$(cd "$REPO" && "$FELIX" setup 2>&1)"
has "felix setup lists the refused row as not done"             "$_ffsucli" "[ ] ffs_ran "
has "and counts both refused rows among the steps that need a person" "$_ffsucli" "2 step(s) need you"
has "while the admitted setup rows read done"                   "$_ffsucli" "[x] ffs_mid "
_ffsuunder="$(printf '%s\n' "$_ffsucli" | awk '/^  \[[x -]\] / { last = NR } { l[NR] = $0 }
                                             END { for (i = last + 1; i <= NR; i++) print l[i] }')"
has "and prints the refused rows under the list"                "$_ffsuunder" "ffs_ran"
has "both refused setup rows are printed there"                 "$_ffsuunder" "ffs_or"
case "$_ffsuunder" in
  *ffs_true*|*ffs_mid*|*ffs_sub*) bad "and no admitted setup row among them" "$_ffsuunder" ;;
  *)                              ok  "and no admitted setup row among them" ;;
esac
is  "and felix setup never ran the refused check either"        "$(_ffnot "$TMP/ffsran")" "not run"

# maintenance.tsv: an event row's check is judged, and a refused one is due
# without being run.
_ffmt() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
            . "$FROOT/harness/lib/maintenance.sh"; felix_maint_status "$_ffw" "$REPO" ) 2>/dev/null; }
{ printf 'ffm_ran\t0\talways\ta check ending in tail\t%s\n'  "touch \"$TMP/ffmran\"; false | tail -1"
  printf 'ffm_mid\t0\talways\thead mid-pipeline\t%s\n'       'printf y | head -5 | grep -q y'
  printf 'ffm_sub\t0\talways\thead in a substitution\t%s\n'  '[ "$(printf a | head -1)" = a ]'
  printf 'ffm_fail\t0\talways\ta check that fails\tfalse\n'
} > "$_ffw/maintenance.tsv"
_ffmst="$(_ffmt)"
_ffmrow() { printf '%s\n' "$_ffmst" | awk -F'\t' -v n="$1" '$2 == n'; }
is  "a maintenance check whose status is a final tail's is due, as refused" \
    "$(_ffmrow ffm_ran)" "due${_ffT}ffm_ran${_ffT}refused${_ffT}0${_ffT}a check ending in tail"
is  "and the refused maintenance check is never run"           "$(_ffnot "$TMP/ffmran")" "not run"
is  "a maintenance check with head mid-pipeline is run, and not due" \
    "$(_ffmrow ffm_mid)" "ok${_ffT}ffm_mid${_ffT}-${_ffT}0${_ffT}head mid-pipeline"
is  "a maintenance check with head inside \$( ) is run, and not due" \
    "$(_ffmrow ffm_sub)" "ok${_ffT}ffm_sub${_ffT}-${_ffT}0${_ffT}head in a substitution"
is  "a maintenance check that fails is still due on its check" \
    "$(_ffmrow ffm_fail)" "due${_ffT}ffm_fail${_ffT}check${_ffT}0${_ffT}a check that fails"
_ffmcli="$(cd "$REPO" && "$FELIX" maintenance 2>&1 | tr -s ' ')"
has "felix maintenance renders it DUE, check refused"          "$_ffmcli" "DUE ffm_ran check refused a check ending in tail"
has "and counts it due beside the check that failed"           "$_ffmcli" "2 routine(s) due"
has "while the check with head mid-pipeline renders ok"        "$_ffmcli" "ok ffm_mid check passed"
is  "and felix maintenance never ran the refused check either"  "$(_ffnot "$TMP/ffmran")" "not run"

# probes.tsv: nothing in it is judged. A witness ending in | tail makes an
# empty probe blind, which blocks; a probe ending in sed -n s/.../p is how a
# real row counts members.
_ffpp="$TMP/ff-probes"; rm -rf "$_ffpp"; mkdir -p "$_ffpp"
_ffpr() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/probes.sh"; "$@" ) 2>/dev/null; }
{ printf 'ffp_when\t-\t%s\t%s\t-\n'   'false | tail -1' 'git ls-files src | tail -5'
  printf 'ffp_witness\t-\t-\t%s\t%s\n' 'printf "" | tail -1' 'printf x | tail -1'
  printf 'ffp_sed\t-\t-\t%s\t-\n'      "git ls-files | sed -n 's|^src/||p'"
} > "$_ffpp/probes.tsv"
is  "no probe row is refused for a when, a probe or a witness ending in a final filter" \
    "$(_ffpr felix_probe_malformed "$_ffpp")" ""
is  "and every such probe row is a row" \
    "$(_ffpr felix_probe_rows "$_ffpp" | cut -f1 | tr '\n' ' ')" "ffp_when ffp_witness ffp_sed "
_ffprun="$(_ffpr felix_probes_run "$_ffpp" "$CMR")"
_ffpst() { printf '%s\n' "$_ffprun" | awk -F'\t' -v n="$1" '$1 == n { print $3 "\t" $4 }'; }
is  "a probe whose when ends in | tail applies, and its probe ending in | tail counts its members" \
    "$(_ffpst ffp_when)" "found${_ffT}2"
is  "a witness ending in | tail turns an empty probe blind, as before" \
    "$(_ffpst ffp_witness)" "blind${_ffT}0"
is  "a probe ending in sed -n s/.../p counts its members, as before" \
    "$(_ffpst ffp_sed)" "found${_ffT}2"

# Every shipped template's judged commands are admitted: a new project copies
# these, and a template the gate refused would fail every project on day one.
# Only the harness's own templates are read, never a project's tables.
_fftpl() {   # template, awk program printing each row's judged cell
  local _c _r _n=0 _b=""
  while IFS= read -r _c; do
    [ -n "$_c" ] || continue
    _n=$((_n + 1)); _r="$(_ffc "$_c")"
    [ "$_r" = "1|" ] || _b="$_b [$_r] $_c;"
  done <<EOF
$(grep -vE '^[[:space:]]*(#|$)' "$REAL_HARNESS/templates/$1" | awk -F'\t' "$2")
EOF
  printf '%s checked;%s\n' "$_n" "${_b:- none refused}"
}
for _fft in commissioning.tsv obligations.tsv setup.tsv maintenance.tsv; do
  case "$_fft" in
    commissioning.tsv) _ffp='$5 !~ /^provider:/ { print $6 }' ;;
    obligations.tsv)   _ffp='{ print $5 }' ;;
    setup.tsv)         _ffp='{ print $4 }' ;;
    maintenance.tsv)   _ffp='NF >= 5 && $5 != "-" && $5 != "" { print $5 }' ;;
  esac
  _ffto="$(_fftpl "$_fft" "$_ffp")"
  case "$_ffto" in
    [1-9]*' checked; none refused') ok  "every judged command in templates/$_fft is admitted" ;;
    *)                              bad "every judged command in templates/$_fft is admitted" "$_ffto" ;;
  esac
done

cp "$TMP/ff-cm.keep" "$CMP/commissioning.tsv"
for _fft in obligations.tsv setup.tsv maintenance.tsv; do
  if [ -f "$TMP/ff-w-$_fft.keep" ]; then mv "$TMP/ff-w-$_fft.keep" "$_ffw/$_fft"; else rm -f "$_ffw/$_fft"; fi
done
rm -rf "$_ffpp"
rm -f "$TMP/ff-cm.keep" "$TMP/ffcran" "$TMP/fforan" "$TMP/ffsran" "$TMP/ffmran"
unset -f _ffc _ffnot _ffcrow _ffcmal _ffcst _ffob _ffomal _ffost _ffsu _ffsuwhy _ffmt _ffmrow \
         _ffpr _ffpst _fftpl
unset _ffT _ffo _ffr _ffl _ffstage _fftx _ffwhy _ffw _fft _ffp _ffto _ffcrun _ffccli _fforun _ffocli \
      _ffsust _ffsumal _ffsucli _ffsuunder _ffmst _ffmcli _ffpp _ffprun

