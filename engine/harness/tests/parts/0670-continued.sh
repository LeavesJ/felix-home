# The declared capabilities.
_cmtable $'cmlf_cap\tapi\t-\t-\t-\ttrue\t9' \
         $'cmlf_plain\t-\t-\t-\t-\ttest -f src/a.txt\t9'
printf 'api\n' > "$CMP/capabilities"
_cmlfrun0="$(_cm felix_commission_run "$CMP" "$CMR" -)"
_cmlfrun1="$(_cm _cmlfstub declared felix_commission_run "$CMP" "$CMR" - 2>/dev/null)"
_cmlfrun2="$(_cm _cmlfstub declared-api felix_commission_run "$CMP" "$CMR" - 2>/dev/null)"
is  "with api declared and nothing stubbed, a row grounded on api and the row beside it are done, and the receipt is commissioned" \
    "$(_cmlff "$_cmlfrun0" cmlf_cap 2) $(_cmlff "$_cmlfrun0" cmlf_plain 2) $(_cm felix_commission_receipt_write "$FROOT" "$CMP" "$CMR" "$_cmlfrun0" "")" \
    "done done commissioned"
is  "a declared list that could not be read makes a row grounded on a declared capability unknown, not not-applicable" \
    "$(_cmlff "$_cmlfrun1" cmlf_cap 2) $(_cmlff "$_cmlfrun1" cmlf_cap 3)" "unknown UNKNOWN"
has "and it says the capabilities this project declares could not be read" \
    "$(_cmlff "$_cmlfrun1" cmlf_cap 6)" "the capabilities this project declares could not be read"
is  "and the receipt over it, every other row done, is indeterminate and not commissioned" \
    "$(_cmlff "$_cmlfrun1" cmlf_plain 2) $(_cm felix_commission_receipt_write "$FROOT" "$CMP" "$CMR" "$_cmlfrun1" "")" \
    "done indeterminate"
is  "a declared list that names api but came back with a failure is not trusted: the row is unknown, not done" \
    "$(_cmlff "$_cmlfrun2" cmlf_cap 2)" "unknown"

_cmlfca() { _cm _cmlfstub "$1" _cmlfrc _felix_cap_active "$2" "$CMP"; }
is  "_felix_cap_active returns 2 when felix_declared fails, whether it printed nothing or printed the capability" \
    "$(_cmlfca declared api) $(_cmlfca declared-api api)" "2 [] 2 []"
is  "and grounds always are active, 0, without reading the failing list" "$(_cmlfca declared always)" "0 []"
_cmlfalone="$(_cmlfca none api)"
printf 'web\napi\nml\n' > "$CMP/capabilities"
is  "it returns 0 for a list that was read and holds the capability as a line, alone or among others" \
    "$_cmlfalone $(_cmlfca none api)" "0 [] 0 []"
printf 'web\napis\nmy-api\n# api\n' > "$CMP/capabilities"
is  "and 1 for a list that was read and holds other capabilities, or the name only inside a longer one or a comment" \
    "$(_cmlfca none api)" "1 []"
printf '# cmlf a capabilities file with no capability in it\n\n# api\n\n' > "$CMP/capabilities"
is  "and 1 for a list of only comments and blank lines" "$(_cmlfca none api)" "1 []"
is  "felix_declared over a file of only comments and blank lines prints nothing and returns 0: it was read, and holds none" \
    "$(_cm _cmlfrc felix_declared "$CMP")" "0 []"
is  "a capabilities file of only comments and blank lines still makes the row not-applicable" \
    "$(_cmlff "$(_cm felix_commission_run "$CMP" "$CMR" -)" cmlf_cap 2)" "not-applicable"
rm -f "$CMP/capabilities"
is  "felix_declared over an absent capabilities file prints nothing and returns 0" \
    "$(_cm _cmlfrc felix_declared "$CMP")" "0 []"
is  "and _felix_cap_active reads an absent file as a list without the capability, 1" "$(_cmlfca none api)" "1 []"
printf 'api\n# cmlf a comment\n\nweb\n' > "$CMP/capabilities"
is  "felix_declared still prints the lines that are not blank and not comments, and returns 0" \
    "$(_cm _cmlfrc felix_declared "$CMP")" "$(printf '0 [api\nweb]')"

# A capabilities file that exists and cannot be read, with nothing stubbed.
printf 'api\n' > "$CMP/capabilities"; chmod 000 "$CMP/capabilities"
if [ -r "$CMP/capabilities" ]; then
  skip "felix_declared returns nonzero and prints nothing over a capabilities file that exists and cannot be read" \
       "the file is readable at mode 000 here, as it is to root"
  skip "and _felix_cap_active returns 2 there, and the row grounded on it is unknown, not not-applicable" \
       "the file is readable at mode 000 here, as it is to root"
else
  _cmlfur="$(_cm _cmlfrc felix_declared "$CMP")"
  is  "felix_declared returns nonzero and prints nothing over a capabilities file that exists and cannot be read" \
      "$(_cmlfnz "$_cmlfur")" "nonzero, nothing"
  is  "and _felix_cap_active returns 2 there, and the row grounded on it is unknown, not not-applicable" \
      "$(_cmlfca none api) $(_cm felix_commission_state "$CMP" "$CMR" cmlf_cap api - - - true 2>/dev/null | cut -f1)" \
      "2 [] unknown"
fi
rm -f "$CMP/capabilities"

# The membership itself makes no here-document, which on bash 3.2 is a
# temporary file: one that cannot be written leaves the read loop unread, as
# felix_has_line returning 1 does here.
printf 'api\n' > "$CMP/capabilities"
is  "with felix_has_line failing as an unwritable here-document makes it fail, a declared api is still active and its row done" \
    "$(_cmlfca has-line api) $(_cm _cmlfstub has-line felix_commission_state "$CMP" "$CMR" cmlf_cap api - - - true 2>/dev/null | cut -f1)" \
    "0 [] done"
_cmlfc3="$(_cm _cmlfstub cap-3 felix_commission_state "$CMP" "$CMR" cmlf_cap api - - - true 2>/dev/null)"
is  "a capability lookup that answers neither 0 nor 1 makes the row unknown, and says the declared list could not be read" \
    "$(printf '%s\n' "$_cmlfc3" | cut -f1) $(_cmlfsays "$(printf '%s\n' "$_cmlfc3" | cut -f2)" 'the capabilities this project declares could not be read')" \
    "unknown said"

# The engine functions a check names.
felix_cmlf_one() { return 0; }
felix_cmlf_two() { return 0; }
_cmlfgone='[ -z "$(felix_cmlf_gone)" ]'
_cmlfefn()  { _cm _cmlfstub "$1" felix_commission_state "$CMP" "$CMR" cmlf_efn - - - - "$2" 2>/dev/null; }
_cmlfpres() { _cm _cmlfstub "$1" _cmlfrc _felix_commission_functions_present "$2"; }
_cmlfe0="$(_cmlfefn none "$_cmlfgone")"
_cmlfe1="$(_cmlfefn names "$_cmlfgone")"
_cmlfe2="$(_cmlfefn names-nopf "$_cmlfgone")"
is  "unstubbed, a check over an engine function that is not loaded is unknown and names it" \
    "$(printf '%s\n' "$_cmlfe0" | cut -f1) $(_cmlfsays "$(printf '%s\n' "$_cmlfe0" | cut -f2)" felix_cmlf_gone)" "unknown said"
is  "when the names a check holds could not be read from it, the row is unknown, not done" \
    "$(printf '%s\n' "$_cmlfe1" | cut -f1)" "unknown"
has "and it says the engine functions the check names could not be read" \
    "$(printf '%s\n' "$_cmlfe1" | cut -f2)" "the engine functions the check names could not be read"
is  "and so with pipefail off in the caller" "$(printf '%s\n' "$_cmlfe2" | cut -f1)" "unknown"
is  "the lookup of the names returns 2 and names nothing when its grep fails, with pipefail on or off" \
    "$(_cmlfpres names "$_cmlfgone") $(_cmlfpres names-nopf "$_cmlfgone")" "2 [] 2 []"
is  "unstubbed it returns 1 naming the one not loaded, and 0 naming nothing for a check of none or of loaded ones" \
    "$(_cmlfpres none "$_cmlfgone") $(_cmlfpres none 'test -f src/a.txt') $(_cmlfpres none 'felix_cmlf_one && felix_cmlf_two')" \
    "1 [felix_cmlf_gone] 0 [] 0 []"
is  "a check naming two loaded engine functions is done with IFS a tab in the calling shell" \
    "$(_cmlfpres tab 'felix_cmlf_one && felix_cmlf_two') $(_cmlfefn tab 'felix_cmlf_one && felix_cmlf_two' | cut -f1)" "0 [] done"
_cmlfp1="$(_cmlfefn present-1 "$_cmlfgone")"
_cmlfp3="$(_cmlfefn present-3 "$_cmlfgone")"
is  "a names lookup that returns 1 naming nothing, or 3, makes the row unknown and says the names could not be read" \
    "$(printf '%s\n' "$_cmlfp1" | cut -f1) $(_cmlfsays "$(printf '%s\n' "$_cmlfp1" | cut -f2)" 'the engine functions the check names could not be read') $(printf '%s\n' "$_cmlfp3" | cut -f1) $(_cmlfsays "$(printf '%s\n' "$_cmlfp3" | cut -f2)" 'the engine functions the check names could not be read')" \
    "unknown said unknown said"

# The rows of a provider's answer.
_cmlfprov='provider:claude-code-setup:claude-automation-recommender'
_cmlftopo="$(_cm felix_commission_topology "$CMP" "$CMR")"
_cmlfans() { printf '# topology %s\n' "$_cmlftopo"; printf '%s\n' "$@"; }
_cmlfans $'plugin\tcmlfone\t-\tllm\twhy' $'plugin\tcmlftwo\t-\tllm\twhy' $'done\t2' > "$_cmlfad/cmlf_whole.tsv"
_cmlfans $'plugin\tcmlfone\t-\tllm\twhy' $'done\t2' > "$_cmlfad/cmlf_part.tsv"
_cmlfans $'done\t0' > "$_cmlfad/cmlf_zero.tsv"
# A twin of the whole answer with rows of its own, for the ingestion control:
# a file already ingested is not ingested again, so the control cannot share
# the stubbed call's file.
_cmlfans $'plugin\tcmlfthree\t-\tllm\twhy' $'plugin\tcmlffour\t-\tllm\twhy' $'done\t2' > "$_cmlfad/cmlf_twin.tsv"
_cmlfps() { _cm _cmlfstub "$1" felix_commission_provider_state "$CMP" "$CMR" "$2" 2>/dev/null; }
_cmlfpw="$(_cmlfps count cmlf_whole)"
is  "unstubbed, a whole answer of two rows is answered and one of its two rows is partial" \
    "$(_cmlfps none cmlf_whole | cut -f1) $(_cmlfps none cmlf_part | cut -f1)" "answered partial"
is  "and an answer of done 0 with no rows is answered" "$(_cmlfps none cmlf_zero | cut -f1)" "answered"
is  "a whole answer whose rows could not be counted is unknown, not answered" \
    "$(printf '%s\n' "$_cmlfpw" | cut -f1)" "unknown"
has "and it says the rows could not be counted" "$(printf '%s\n' "$_cmlfpw" | cut -f2)" "could not be counted"
is  "a partial answer whose rows could not be counted is unknown, not answered" \
    "$(_cmlfps count cmlf_part | cut -f1)" "unknown"
is  "through felix_commission_state, unstubbed, the provider row over the whole answer is answered" \
    "$(_cm felix_commission_state "$CMP" "$CMR" cmlf_whole - - - "$_cmlfprov" - 2>/dev/null | cut -f1)" "answered"
is  "and with its rows uncountable it is unknown" \
    "$(_cm _cmlfstub count felix_commission_state "$CMP" "$CMR" cmlf_whole - - - "$_cmlfprov" - 2>/dev/null | cut -f1)" "unknown"
_cmlfsum() { if [ -f "$1" ]; then cksum < "$1"; else printf 'absent\n'; fi; }
_cmlflogt="$(_cmlfsum "$MEM/cmproj/commissioning.log")"
_cmlfrect="$(_cm felix_commission_record_provider "$CMP" "$CMR" cmlf_twin "$_cmlfprov" cmlf-tree cmlf-policy 2>/dev/null)"
_cmlflog0="$(_cmlfsum "$MEM/cmproj/commissioning.log")"
is  "unstubbed, a whole answer of two rows is ingested: the record prints 2 and appends to the log" \
    "$_cmlfrect $([ "$_cmlflog0" = "$_cmlflogt" ] && printf unchanged || printf appended)" "2 appended"
_cmlfrec1="$(_cm _cmlfstub count felix_commission_record_provider "$CMP" "$CMR" cmlf_whole "$_cmlfprov" cmlf-tree cmlf-policy 2>/dev/null)"
_cmlflog1="$(_cmlfsum "$MEM/cmproj/commissioning.log")"
is  "an answer whose rows could not be counted is not ingested: the record prints 0 and appends nothing to the log" \
    "$_cmlfrec1 $([ "$_cmlflog1" = "$_cmlflog0" ] && printf unchanged || printf appended)" "0 unchanged"

# Added after review, not blind. The reviewers found four ways the first fix
# still read a lookup that was not made as one that was, and two ways a wrong
# implementation passed the block.
# - On bash 3.2 a substitution that cannot make its pipe (no file descriptor
#   left) expands to nothing with status 0 (measured), so a status read alone
#   takes it for a list read and empty. Modelled by a lookup that ends its
#   substitution with exit 0 before it answers; the engine has to see that
#   the answer never came.
# - A count of an answer's rows taken over a first grep that failed is a
#   number all the same, whether that grep printed nothing or some of the rows.
# - A capabilities link whose target is gone was called absent, so the list
#   was empty.
# - felix_declared swallowing grep's exit 2 was caught only at mode 000, which
#   root can still read. This one stubs the grep and runs as anybody.
# - A walk of the names through a second substitution or a here-document
#   passed every assertion, and so did a membership test that inlined
#   felix_has_line's here-document. Each lookup is read here as bash prints it:
#   one substitution, no here-document, and no pipe but the one that reads
#   the names.
# Not modelled: the names lookup's own substitution failing to make its pipe.
# Nothing in it runs in that substitution's shell before the answer, so no
# stub can end it early, and nothing here lowers a limit. The `.` it carries
# is there by reading, and a mutation that drops it passes this block.
printf 'api\n' > "$CMP/capabilities"
is  "a declared list whose substitution ended before it answered, with status 0, makes _felix_cap_active return 2 and the row unknown" \
    "$(_cmlfca declared-exit0 api) $(_cm _cmlfstub declared-exit0 felix_commission_state "$CMP" "$CMR" cmlf_cap api - - - true 2>/dev/null | cut -f1)" \
    "2 [] unknown"
is  "a names lookup whose substitution ended with status 0 and no text makes the row unknown, not done" \
    "$(_cmlfefn present-exit0 "$_cmlfgone" | cut -f1)" "unknown"
is  "felix_declared returns nonzero and prints nothing when its grep fails, as any user, and _felix_cap_active returns 2" \
    "$(_cmlfnz "$(_cm _cmlfstub declared-grep2 _cmlfrc felix_declared "$CMP")") $(_cmlfca declared-grep2 api)" \
    "nonzero, nothing 2 []"
rm -f "$CMP/capabilities"; ln -s "$TMP/cmlf-no-such-target" "$CMP/capabilities"
is  "a capabilities link whose target is gone is not an absent file: _felix_cap_active returns 2 and the row is unknown" \
    "$(_cmlfca none api) $(_cm felix_commission_state "$CMP" "$CMR" cmlf_cap api - - - true 2>/dev/null | cut -f1)" \
    "2 [] unknown"
# And only a regular file is read. A directory or a pipe named capabilities is
# something there that is no list; a pipe must not even be opened, because
# grep waits on it for a writer, which is what the first `-e` in place of `-f`
# did here, hanging (found after review). So the pipe is asked under a
# watchdog that ends the whole tree it started.
_cmlfkill() { local _cmlfc; for _cmlfc in $(pgrep -P "$1" 2>/dev/null); do _cmlfkill "$_cmlfc"; done; kill "$1" 2>/dev/null; }
rm -f "$CMP/capabilities"; mkfifo "$CMP/capabilities"
( _cmlfca none api > "$TMP/cmlf-fifo.out" 2>/dev/null ) & _cmlfw=$!
_cmlfi=0; while kill -0 "$_cmlfw" 2>/dev/null && [ "$_cmlfi" -lt 100 ]; do sleep 0.1; _cmlfi=$((_cmlfi + 1)); done
if kill -0 "$_cmlfw" 2>/dev/null; then _cmlfkill "$_cmlfw"; wait "$_cmlfw" 2>/dev/null; _cmlffifo='still waiting after ten seconds'
else wait "$_cmlfw" 2>/dev/null; _cmlffifo="$(cat "$TMP/cmlf-fifo.out")"; fi
rm -f "$CMP/capabilities" "$TMP/cmlf-fifo.out"; mkdir "$CMP/capabilities"
is  "a capabilities pipe or directory is no list: _felix_cap_active returns 2 at once for each, neither waiting on the pipe nor reading either as absent" \
    "$_cmlffifo $(_cmlfca none api)" "2 [] 2 []"
rmdir "$CMP/capabilities"
# The answers below are keyed to the topology taken with api declared.
rm -f "$CMP/capabilities"; printf 'api\n' > "$CMP/capabilities"
_cmlfans $'plugin\tcmlfone\t-\tllm\twhy' $'plugin\tcmlftwo\t-\tllm\twhy' $'done\t0' > "$_cmlfad/cmlf_zero2.tsv"
_cmlfans $'plugin\tcmlfone\t-\tllm\twhy' $'plugin\tcmlftwo\t-\tllm\twhy' $'plugin\tcmlfthree\t-\tllm\twhy' $'done\t2' \
  > "$_cmlfad/cmlf_three.tsv"
is  "unstubbed, an answer saying done 0 over two rows and one saying done 2 over three are partial" \
    "$(_cmlfps none cmlf_zero2 | cut -f1) $(_cmlfps none cmlf_three | cut -f1)" "partial partial"
is  "a count over a first grep that failed is not a count: done 0 over two rows is unknown when that grep printed nothing, not answered" \
    "$(_cmlfps count-first cmlf_zero2 | cut -f1)" "unknown"
is  "and done 2 over three rows is unknown when that grep printed two of them and failed, not answered" \
    "$(_cmlfps count-first-two cmlf_three | cut -f1)" "unknown"
_cmlfshape() { local _cmlfb _cmlfr _cmlfn=0 _cmlfp=0
  _cmlfb="$(declare -f "$1")"; _cmlfr="$_cmlfb"
  while :; do case "$_cmlfr" in *'$('*) _cmlfr="${_cmlfr#*\$(}"; _cmlfn=$((_cmlfn + 1)) ;; *) break ;; esac; done
  _cmlfr="$_cmlfb"
  while :; do case "$_cmlfr" in *' | '*) _cmlfr="${_cmlfr#* | }"; _cmlfp=$((_cmlfp + 1)) ;; *) break ;; esac; done
  printf '%s subs %s pipes' "$_cmlfn" "$_cmlfp"
  case "$_cmlfb" in *'<<'*) printf ', a here-document' ;; esac
  case "$_cmlfb" in *felix_has_line*) printf ', felix_has_line' ;; esac
  printf '\n'; }
is  "the capability lookup is one substitution, with no pipe, no here-document and no felix_has_line" \
    "$(_cm _cmlfshape _felix_cap_active)" "1 subs 0 pipes"
is  "and the names lookup is one substitution whose one pipe reads the names, with no here-document" \
    "$(_cm _cmlfshape _felix_commission_functions_present)" "1 subs 1 pipes"

rm -f "$_cmlfad/cmlf_whole.tsv" "$_cmlfad/cmlf_part.tsv" "$_cmlfad/cmlf_zero.tsv" "$_cmlfad/cmlf_twin.tsv" \
      "$_cmlfad/cmlf_zero2.tsv" "$_cmlfad/cmlf_three.tsv"
[ -n "$_cmlfmade" ] && rmdir "$_cmlfad"
rm -f "$CMP/capabilities"; [ -f "$TMP/cmlf-caps.keep" ] && mv "$TMP/cmlf-caps.keep" "$CMP/capabilities"
if [ -f "$TMP/cmlf-table.keep" ]; then cp "$TMP/cmlf-table.keep" "$CMP/commissioning.tsv"; else rm -f "$CMP/commissioning.tsv"; fi
if [ -f "$TMP/cmlf-receipt.keep" ]; then mv "$TMP/cmlf-receipt.keep" "$FROOT/state/commission/cmproj"
else rm -f "$FROOT/state/commission/cmproj"; fi
if [ -f "$TMP/cmlf-log.keep" ]; then cp "$TMP/cmlf-log.keep" "$MEM/cmproj/commissioning.log"
else rm -f "$MEM/cmproj/commissioning.log"; fi
rm -f "$TMP/cmlf-table.keep" "$TMP/cmlf-log.keep"
is  "and this block leaves the capabilities, the table, the receipt, the log and every answer file as it found them" \
    "$(_cmlffixture)" "$_cmlffound"
unset -f _cmlffixture _cmlfstub _cmlfrc _cmlff _cmlfsays _cmlfnz _cmlfca _cmlfefn _cmlfpres _cmlfps _cmlfans _cmlfsum _cmlfshape _cmlfkill \
         felix_cmlf_one felix_cmlf_two
unset _cmlfad _cmlffound _cmlfmade _cmlfrun0 _cmlfrun1 _cmlfrun2 _cmlfc3 _cmlfgone _cmlfe0 _cmlfe1 _cmlfe2 \
      _cmlfw _cmlfi _cmlffifo _cmlfp1 _cmlfp3 _cmlfprov _cmlftopo _cmlfpw _cmlflogt _cmlflog0 _cmlflog1 _cmlfrect _cmlfrec1 _cmlfur _cmlfalone

# A declared-capabilities list that could not be read is said, never dormant.
#
# The block above made _felix_cap_active return 2 when the list could not be
# read, and felix_commission_state reads that 2 as unknown. Three other callers
# ask it with `!`, so 2 reads as not active and prints `dormant`, a valid state
# that looks like a well-kept repository: felix_setup_status calls a step that
# still needs a person not needed yet, felix_maint_status calls a routine that
# may be due dormant, and felix_stack_plan calls a row it never classified
# dormant. felix_maint_unreachable reads the list itself through felix_has_line,
# so a list nobody read says nothing declares the capability. And session start
# put a provider row whose state is unknown, or which has no state at all,
# among the answers a session still owes, which sends a session to redo an
# answer that may be whole. Each of them now says the list could not be read.
# An unread list makes nothing due, installs nothing and owes nothing; that is
# the `unchecked` precedent, a row that could not be asked being its own word.
# The library is asked with felix_declared failing as a substitution whose fork
# could not be made fails, defined in a subshell after the libs are sourced, over
# a capabilities file that DOES declare the capability, so 2 read as 1 shows.
# The CLI is another process and cannot see a stub, so there the capabilities
# file is a link whose target is gone, which felix_declared returns 2 for. The
# stack rows are skills no machine has, so nothing here installs anything or
# needs the claude CLI. These assertions were written blind, from the contract,
# before the fix, and each was run against main's engine first.
# Everything this makes is removed below and everything it defines unset.
_cucrfixture() { { find "$FROOT/projects" "$FROOT/state" "$MEM" 2>/dev/null | LC_ALL=C sort
                   find "$FROOT/projects" "$FROOT/state" "$MEM" -type f -exec cksum {} + 2>/dev/null | LC_ALL=C sort; } | cksum; }
_cucrfound="$(_cucrfixture)"
# Session start below makes state/commission when it spends the receipt line,
# and the block removes only what it made.
_cucrmade=''; [ -d "$FROOT/state" ] || _cucrmade=state; [ -d "$FROOT/state/commission" ] || _cucrmade="$_cucrmade commission"
_cucrp="$FROOT/projects/cucrproj"
_cucrr="$TMP/cucr-repo"
_cucrhome="$TMP/cucr-home"
mkdir -p "$_cucrp" "$_cucrr" "$_cucrhome/.claude/skills/cucr-skill-there"
printf '{\n  "name": "cucrproj",\n  "remote_match": "example.com/cucrproj",\n  "gate": "true"\n}\n' > "$_cucrp/project.json"
printf '# cucrproj\n' > "$_cucrp/CLAUDE.md"
( cd "$_cucrr" && git init -q -b main && printf 'cucrproj\n' > .felix && git add .felix \
    && git -c user.name=cucr -c user.email=cucr@example.com commit -q -m cucr )
_cucrr="$(cd "$_cucrr" && pwd -P)"
{ printf 'cucr_step\ta step on a declared capability\tcucrcap\ttouch %s; false\n' "$TMP/cucr-setup-ran"
  printf 'cucr_plain\ta step for every project\talways\ttrue\n'; } > "$_cucrp/setup.tsv"
{ printf 'cucr_clock\t7\tcucrcap\ta routine on a clock\n'
  printf 'cucr_checked\t0\tcucrcap\ta routine with a check\ttouch %s; false\n' "$TMP/cucr-maint-ran"
  printf 'cucr_every\t0\talways\ta routine on a trigger\n'; } > "$_cucrp/maintenance.tsv"
{ printf 'skill\tcucr-skill-unread\t-\tlow\tcucrcap\n'
  printf 'skill\tcucr-skill-there\t-\tlow\tcucrcap\n'; } > "$_cucrp/stack.tsv"
printf 'cucrcap\n' > "$_cucrp/capabilities"

# $1 is unread (felix_declared fails) or read; the rest is the engine call.
_cucrlib() { local _cucrmode="$1"; shift
  ( cd "$_cucrr" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
    . "$FROOT/harness/lib/stack.sh"; . "$FROOT/harness/lib/setup.sh"; . "$FROOT/harness/lib/maintenance.sh"
    claude() { return 1; }
    HOME="$_cucrhome"
    case "$_cucrmode" in unread) felix_declared() { return 128; } ;; esac
    "$@" ) 2>/dev/null; }
_cucrnext() { local _cucrmode="$1"
  ( cd "$_cucrr" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
    . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/review.sh"
    . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"; . "$FROOT/harness/lib/evidence.sh"
    . "$FROOT/harness/lib/maintenance.sh"; . "$FROOT/harness/lib/stack.sh"
    . "$FROOT/harness/lib/ready.sh"; . "$FROOT/harness/lib/ledger.sh"
    . "$FROOT/harness/lib/coverage.sh"; . "$FROOT/harness/lib/deny.sh"
    . "$FROOT/harness/lib/route.sh"; . "$FROOT/harness/lib/next.sh"
    claude() { return 1; }
    case "$_cucrmode" in unread) felix_declared() { return 128; } ;; esac
    felix_next "$_cucrp" "$FROOT" "$_cucrr" HEAD ) 2>/dev/null; }
_cucrpulse() { local _cucrmode="$1"
  ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
    . "$FROOT/harness/lib/stack.sh"; . "$FROOT/harness/lib/maintenance.sh"
    . "$FROOT/harness/lib/discover.sh"; . "$FROOT/harness/lib/pulse.sh"
    case "$_cucrmode" in unread) felix_declared() { return 128; } ;; esac
    felix_pulse_report "$FROOT" ) 2>/dev/null; }
_cucrcli() { ( cd "$_cucrr" && HOME="$_cucrhome" PATH=/usr/bin:/bin "$FELIX" "$@" 2>&1 ); }
# The lines whose column $2 is $3.
_cucrline() { printf '%s\n' "$1" | awk -F'\t' -v c="$2" -v n="$3" '$c == n'; }
_cucrsays() { case "$1" in *"$2"*) printf 'said\n' ;; *) printf 'silent\n' ;; esac; }
# said when one line holds both $2 and $3.
_cucrboth() { if printf '%s\n' "$1" | awk -v a="$2" -v b="$3" 'index($0, a) && index($0, b) { f = 1 } END { exit !f }'
              then printf 'said\n'; else printf 'silent\n'; fi; }
_cucrran()  { if [ -e "$1" ]; then printf 'ran\n'; else printf 'not run\n'; fi; }
_cucrwhy='the capabilities this project declares could not be read'

# felix_setup_status.
_cucrsu1="$(_cucrlib unread felix_setup_status "$_cucrp")"
is  "felix_setup_status prints unknown, not dormant, for a step whose declared list could not be read, and does not run its check" \
    "$(_cucrline "$_cucrsu1" 2 cucr_step) $(_cucrran "$TMP/cucr-setup-ran")" \
    "$(printf 'unknown\tcucr_step\ta step on a declared capability not run')"
is  "and over that unread list a step for every project is still done" \
    "$(_cucrline "$_cucrsu1" 2 cucr_plain)" "$(printf 'done\tcucr_plain\ta step for every project')"
is  "over a list read and declaring the capability the step is todo and its check runs" \
    "$(_cucrline "$(_cucrlib read felix_setup_status "$_cucrp")" 2 cucr_step) $(_cucrran "$TMP/cucr-setup-ran")" \
    "$(printf 'todo\tcucr_step\ta step on a declared capability ran')"

# felix_maint_status, felix_maint_unreachable, felix_stack_plan.
_cucrms1="$(_cucrlib unread felix_maint_status "$_cucrp" "$_cucrr")"
is  "felix_maint_status prints unknown, not dormant, for a routine on a clock whose declared list could not be read" \
    "$(_cucrline "$_cucrms1" 2 cucr_clock)" "$(printf 'unknown\tcucr_clock\t-\t7\ta routine on a clock')"
is  "and for a routine with a check prints unknown with cadence 0, and does not run the check" \
    "$(_cucrline "$_cucrms1" 2 cucr_checked) $(_cucrran "$TMP/cucr-maint-ran")" \
    "$(printf 'unknown\tcucr_checked\t-\t0\ta routine with a check not run')"
is  "and over that unread list a routine for every project is still event" \
    "$(_cucrline "$_cucrms1" 2 cucr_every)" "$(printf 'event\tcucr_every\t-\t0\ta routine on a trigger')"
is  "felix_maint_unreachable says unknown in a third column for each routine whose declared list could not be read" \
    "$(_cucrlib unread felix_maint_unreachable "$_cucrp")" \
    "$(printf 'cucr_clock\tcucrcap\tunknown\ncucr_checked\tcucrcap\tunknown')"
_cucrsp1="$(_cucrlib unread felix_stack_plan "$_cucrp")"
is  "felix_stack_plan prints unknown, not dormant, for a row whose declared list could not be read, naming its capability" \
    "$(_cucrline "$_cucrsp1" 3 cucr-skill-unread)" \
    "$(printf 'unknown\tskill\tcucr-skill-unread\t%s, so whether cucrcap is active here is not known' "$_cucrwhy")"
is  "and a row whose item is present stays present over that unread list" \
    "$(_cucrline "$_cucrsp1" 3 cucr-skill-there)" "$(printf 'present\tskill\tcucr-skill-there\t-')"

# next.sh and the pulse.
_cucrnx1="$(_cucrnext unread)"
_cucrn6="$(printf '%s\n' "$_cucrnx1" | awk -F'\t' '$1 == 6' | grep cucr_clock)"
is  "felix_next rank 6 says the declared list could not be read for that routine, naming its capability and felix maintenance, never that nothing declares it" \
    "$(_cucrsays "$_cucrn6" 'waits on a capability nothing declares') $(_cucrsays "$_cucrn6" 'could not be read') $(_cucrsays "$_cucrn6" cucrcap) $(_cucrsays "$_cucrn6" 'felix maintenance')" \
    "silent said said said"
_cucrpu1="$(_cucrpulse unread)"
is  "felix_pulse_report prints an unknown line naming the routines whose declared list could not be read" \
    "$(_cucrline "$_cucrpu1" 1 unknown | awk -F'\t' '$2 == "cucrproj"')" \
    "$(printf 'unknown\tcucrproj\tcucr_clock cucr_checked')"

# The same rows over a list that was read, declaring the capability and not.
_cucrms0="$(_cucrlib read felix_maint_status "$_cucrp" "$_cucrr")"
is  "over a list read and declaring the capability the clock routine is due, never run, and the checked one due on its check" \
    "$(_cucrline "$_cucrms0" 2 cucr_clock) $(_cucrline "$_cucrms0" 2 cucr_checked)" \
    "$(printf 'due\tcucr_clock\tnever\t7\ta routine on a clock due\tcucr_checked\tcheck\t0\ta routine with a check')"
is  "and felix_maint_unreachable prints nothing, and felix_stack_plan calls the absent skill manual" \
    "[$(_cucrlib read felix_maint_unreachable "$_cucrp")] $(_cucrline "$(_cucrlib read felix_stack_plan "$_cucrp")" 3 cucr-skill-unread | cut -f1)" \
    "[] manual"
_cucrnx0="$(_cucrnext read)"
is  "felix_next rank 4 never names a routine whose declared list could not be read, and names it due over a list read and declaring it" \
    "$(printf '%s\n' "$_cucrnx1" | awk -F'\t' '$1 == 4' | grep -c cucr_clock) $(printf '%s\n' "$_cucrnx0" | awk -F'\t' '$1 == 4' | grep -c cucr_clock)" \
    "0 1"
is  "and felix_pulse_report never puts such a routine in its due line, and puts it there over a list read and declaring it" \
    "[$(_cucrline "$_cucrpu1" 2 cucrproj | awk -F'\t' '$1 == "due"')] $(_cucrline "$(_cucrpulse read)" 2 cucrproj | awk -F'\t' '$1 == "due"')" \
    "$(printf '[] due\tcucrproj\tcucr_clock')"
printf 'cucr_other\n' > "$_cucrp/capabilities"
is  "over a list read and not declaring the capability the step, both routines and the absent skill are dormant" \
    "$(_cucrline "$(_cucrlib read felix_setup_status "$_cucrp")" 2 cucr_step | cut -f1) $(_cucrlib read felix_maint_status "$_cucrp" "$_cucrr" | awk -F'\t' '$2 != "cucr_every" { print $1 }' | tr '\n' ' ')$(_cucrline "$(_cucrlib read felix_stack_plan "$_cucrp")" 3 cucr-skill-unread | cut -f1)" \
    "dormant dormant dormant dormant"
is  "and felix_maint_unreachable prints the two columns it always has" \
    "$(_cucrlib read felix_maint_unreachable "$_cucrp")" "$(printf 'cucr_clock\tcucrcap\ncucr_checked\tcucrcap')"
_cucrn6="$(_cucrnext read | awk -F'\t' '$1 == 6' | grep cucr_clock)"
has "and felix_next rank 6 says the routine waits on a capability nothing declares, as before" \
    "$_cucrn6" "upkeep 'cucr_clock' waits on a capability nothing declares: cucrcap"
# After review, not blind: felix_maint_unreachable passes over the capabilities
# it trusts as spelled, so a routine on ci over an unread list reached no rank
# of felix_next, which then said no upkeep was past its cadence.
cp "$_cucrp/maintenance.tsv" "$TMP/cucr-maint.keep"
{ printf 'cucr_ci\t7\tci\ta routine on ci\n'
  printf 'cucr_clock\t7\tcucrcap\ta routine on a clock\n'; } > "$_cucrp/maintenance.tsv"
printf 'ci\ncucrcap\n' > "$_cucrp/capabilities"
_cucrnx1="$(_cucrnext unread)"
is  "felix_next says at rank 6 that whether a routine on ci is due is not known when the declared list could not be read, and says the routine it named with its capability once" \
    "$(printf '%s\n' "$_cucrnx1" | awk -F'\t' '$1 == 6' | grep -cF "upkeep 'cucr_ci': $_cucrwhy, so whether it is due is not known") $(printf '%s\n' "$_cucrnx1" | grep -cF "'cucr_clock'")" \
    "1 1"
_cucrnx0="$(_cucrnext read)"
is  "and over a list read and declaring ci it names that routine due at rank 4 and not at rank 6" \
    "$(printf '%s\n' "$_cucrnx0" | awk -F'\t' '$1 == 4' | grep -c cucr_ci) $(printf '%s\n' "$_cucrnx0" | awk -F'\t' '$1 == 6' | grep -c cucr_ci)" \
    "1 0"
cp "$TMP/cucr-maint.keep" "$_cucrp/maintenance.tsv"; rm -f "$TMP/cucr-maint.keep"
printf 'cucr_other\n' > "$_cucrp/capabilities"

# The CLI, over a capabilities link whose target is gone.
rm -f "$_cucrp/capabilities"; ln -s "$TMP/cucr-no-such-list" "$_cucrp/capabilities"
_cucrout="$(_cucrcli setup)"; _cucrrc=$?
is  "felix setup renders a step it could not check as [?] with the reason, not as not needed yet" \
    "$(_cucrsays "$_cucrout" "$(printf '  [?] %-22s %s (not checked: %s)' cucr_step 'a step on a declared capability' "$_cucrwhy")")" "said"
is  "and says how many steps could not be checked in place of Nothing outstanding" \
    "$(_cucrsays "$_cucrout" 'Nothing outstanding.') $(_cucrsays "$_cucrout" "1 step(s) could not be checked: $_cucrwhy.")" \
    "silent said"
is  "and felix setup still exits 0 with a step it could not check" "$_cucrrc" "0"
# After review, not blind: the counts as well as the lines.
is  "and felix setup does not count a step it could not check among the steps that need a person" \
    "$(_cucrsays "$_cucrout" 'need you')" "silent"
_cucrout="$(_cucrcli maintenance)"
is  "felix maintenance renders a routine it could not read as ? and not read, not as not yet" \
    "$(_cucrsays "$_cucrout" "$(printf '  ?       %-18s %-14s %s' cucr_clock 'not read' 'a routine on a clock')")" "said"
is  "and says how many routines could not be read in place of Nothing due" \
    "$(_cucrsays "$_cucrout" 'Nothing due.') $(_cucrsays "$_cucrout" "2 routine(s) could not be read: $_cucrwhy, so whether they are due is not known.")" \
    "silent said"
is  "and does not list them under the header for capabilities nothing declares, but names each routine and its capability on a line of its own" \
    "$(_cucrsays "$_cucrout" 'Dormant rather than satisfied') $(_cucrboth "$_cucrout" cucr_clock cucrcap) $(_cucrboth "$_cucrout" cucr_checked cucrcap)" \
    "silent said said"
is  "and felix maintenance does not count a routine it could not read among the routines due" \
    "$(_cucrsays "$_cucrout" 'routine(s) due')" "silent"
_cucrout="$(_cucrcli stack plan)"
is  "felix stack plan prints the row it could not read as unknown, and after its summary says how many could not be read" \
    "$(_cucrsays "$_cucrout" "$(printf '%-9s %-11s %-46s' unknown skill cucr-skill-unread)") $(_cucrsays "${_cucrout#*0 to install, 0 blocked.}" "1 could not be read: $_cucrwhy, so whether they apply is not known.")" \
    "said said"
is  "and the plan counts that row neither to install nor blocked, and offers no apply" \
    "$(_cucrsays "$_cucrout" '0 to install, 0 blocked.') $(_cucrsays "$_cucrout" 'apply with:')" "said silent"
_cucrout="$(_cucrcli stack apply)"
is  "and felix stack apply without --yes says how many could not be read before saying nothing changed" \
    "$(_cucrsays "${_cucrout%%This was a plan*}" "1 could not be read: $_cucrwhy, so whether they apply is not known.")" "said"
_cucrout="$(_cucrcli stack apply --yes)"; _cucrrc=$?
is  "felix stack apply --yes says how many could not be read and returns 1, though no install failed" \
    "$_cucrrc $(_cucrsays "$_cucrout" "1 could not be read: $_cucrwhy, so whether they apply is not known.")" "1 said"
is  "and applies no item for that row, tried or failed" \
    "$(_cucrsays "$_cucrout" 'applying 0 item(s)') $(_cucrboth "$_cucrout" FAILED cucr-skill-unread) $(_cucrboth "$_cucrout" installed cucr-skill-unread)" \
    "said silent silent"
rm -f "$_cucrp/capabilities"; printf 'cucr_other\n' > "$_cucrp/capabilities"
_cucrout="$(_cucrcli maintenance)"
is  "felix maintenance over a list read and not declaring the capability lists both routines as not yet and under the header for capabilities nothing declares" \
    "$(_cucrsays "$_cucrout" "$(printf '  -       %-18s %-14s' cucr_clock 'not yet')") $(_cucrsays "$_cucrout" 'Dormant rather than satisfied') $(_cucrsays "$_cucrout" "$(printf '  %-18s waits on: %s' cucr_checked cucrcap)")" \
    "said said said"
_cucrout="$(_cucrcli stack apply --yes)"; _cucrrc=$?
is  "and felix stack apply --yes over it returns 0 and says nothing could not be read" \
    "$_cucrrc $(_cucrsays "$_cucrout" 'could not be read')" "0 silent"

# Session start, through a scratch copy of the engine whose provider state is
# unknown for one need, awaiting for another, and nothing for a third.
mkdir -p "$TMP/cucr-plugin"; cp -R "$FROOT/harness" "$TMP/cucr-plugin/harness"
cat >> "$TMP/cucr-plugin/harness/lib/commission-provider.sh" <<'EOF'
felix_commission_provider_state() {
  case "$3" in
    cucr_unread) printf 'unknown\tthe rows of the answer could not be counted\n' ;;
    cucr_owed)   printf 'awaiting\tno answer yet\n' ;;
    *)           return 1 ;;
  esac
}
EOF
{ printf 'cucr_unread\t-\t-\t-\tprovider:cucrplug:cucrskill\t-\t-\n'
  printf 'cucr_owed\t-\t-\t-\tprovider:cucrplug:cucrskill\t-\t-\n'
  printf 'cucr_none\t-\t-\t-\tprovider:cucrplug:cucrskill\t-\t-\n'; } > "$_cucrp/commissioning.tsv"
_cucrstart() { local _cucro
  _cucro="$(cd "$_cucrr" && CLAUDE_PLUGIN_ROOT="$TMP/cucr-plugin" "$TMP/cucr-plugin/harness/hooks/session-start" 2>&1)"
  printf '%s\n' "${_cucro//\\n/$'\n'}"; }
# The owed paragraph: from its opening line to a blank line or the next Commissioning line.
_cucrowed() { printf '%s\n' "$1" | awk 'index($0, "A session still owes these") { on = 1; print; next }
                                         on && (/^$/ || /^Commissioning:/) { exit } on { print }'; }
_cucrunread="Commissioning: whether these answers are whole could not be read, so they are neither owed nor recorded; felix commission --status reads them again:
  cucr_unread (unknown)
  cucr_none (no state)"
_cucrs1="$(_cucrstart)"
_cucrow="$(_cucrowed "$_cucrs1")"
is  "session start does not put a provider row whose state is unknown, or which has no state, among what a session owes" \
    "$(_cucrsays "$_cucrow" cucr_unread) $(_cucrsays "$_cucrow" cucr_none) $(_cucrsays "$_cucrow" 'cucr_owed (awaiting): ')" \
    "silent silent said"
is  "and names those rows on a line of their own, each with its state or no state" "$(_cucrsays "$_cucrs1" "$_cucrunread")" "said"
is  "and says it again on the next session start, not once per topology" "$(_cucrsays "$(_cucrstart)" "$_cucrunread")" "said"
{ printf 'cucr_unread\t-\t-\t-\tprovider:cucrplug:cucrskill\t-\t-\n'
  printf 'cucr_none\t-\t-\t-\tprovider:cucrplug:cucrskill\t-\t-\n'; } > "$_cucrp/commissioning.tsv"
_cucrs2="$(_cucrstart)"
is  "with only unread provider rows session start prints no paragraph saying a session owes anything, and still names them" \
    "$(_cucrsays "$_cucrs2" 'A session still owes these') $(_cucrsays "$_cucrs2" "$_cucrunread")" "silent said"
# After review, not blind: the once-per-topology receipt line is an all-clear,
# and one spent over rows nobody could read is never said again.
_cucrseen() { if [ -e "$FROOT/state/commission/cucrproj.seen" ]; then printf 'spent\n'; else printf 'kept\n'; fi; }
is  "and while they are unread it does not say the receipt line that is said once per topology, nor spend it" \
    "$(_cucrsays "$_cucrs2" 'Commissioning: receipt') $(_cucrseen)" "silent kept"
{ printf 'cucr_owed\t-\t-\t-\tprovider:cucrplug:cucrskill\t-\t-\n'; } > "$_cucrp/commissioning.tsv"
_cucrs3="$(_cucrstart)"
is  "and with only an awaiting provider row it is owed with its request path, and nothing is said to be unread" \
    "$(_cucrsays "$(_cucrowed "$_cucrs3")" 'cucr_owed (awaiting): ') $(_cucrsays "$_cucrs3" 'could not be read, so they are neither owed')" \
    "said silent"
{ printf 'cucr_plain\t-\t-\t-\t-\ttrue\t-\n'; } > "$_cucrp/commissioning.tsv"
_cucrs3="$(_cucrstart)"
is  "and with no provider row owed or unread it says the receipt line once and spends it" \
    "$(_cucrsays "$_cucrs3" 'Commissioning: receipt') $(_cucrseen)" "said spent"

