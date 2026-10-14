# The reader. A current receipt, rewritten in place.
_cm _cmrcwrite "$_cmrcfull" >/dev/null
cp "$_cmrcrc" "$TMP/cmrc-good.receipt"
_cmrcvalid() { local _cmrcv _cmrcvr
  _cmrcv="$(_cm felix_commission_receipt_valid "$FROOT" "$CMP" "$CMR" 2>/dev/null)"; _cmrcvr=$?
  printf '%s %s' "$_cmrcvr" "$_cmrcv"; }
_cmrcredo() { awk -F'\t' -v OFS='\t' "$1" "$TMP/cmrc-good.receipt" > "$TMP/cmrc-redo.receipt" \
                && mv "$TMP/cmrc-redo.receipt" "$_cmrcrc"; }
_cmrcbegins() { case "$2" in "$3"*) ok "$1" ;; *) bad "$1" "[$2] does not begin [$3]" ;; esac; }
_cmrcbegins "a current well-formed receipt still reads valid" "$(_cmrcvalid)" "0 commissioned"
_cmrcredo '{ $5 = "held"; $7 = "1"; print }'
_cmrcbegins "and a current well-formed held receipt still reads valid, held" "$(_cmrcvalid)" "0 held"
_cmrcredo '{ for (i = 6; i <= 10; i++) $i = ""; print }'
_cmrcbegins "a receipt whose counts are empty is unreadable, not valid" "$(_cmrcvalid)" "1 unreadable ("
_cmrcredo '{ $8 = "?"; print }'
_cmrcbegins "a receipt whose unknown count is ? is unreadable" "$(_cmrcvalid)" "1 unreadable ("
_cmrcredo '{ $5 = "finished"; print }'
_cmrcbegins "a receipt whose result is a word no run writes is unreadable" "$(_cmrcvalid)" "1 unreadable ("
_cmrcredo '{ $5 = "indeterminate"; $8 = ""; print }'
_cmrcbegins "an indeterminate receipt with a count missing still reads indeterminate first" "$(_cmrcvalid)" "1 indeterminate"
_cmrcredo '{ $2 = "cmrc-not-the-table"; $8 = ""; print }'
_cmrcbegins "a stale receipt with a count missing still reads stale first" "$(_cmrcvalid)" "1 stale (table set moved"
# Added after review, not blind: each end of the count fields alone, and the
# claude cli having changed since, which announces and returns 0 for a
# well-formed receipt and must not for one whose counts no run wrote.
_cmrcredo '{ $6 = ""; print }'
_cmrcbegins "a receipt whose done count alone is empty is unreadable" "$(_cmrcvalid)" "1 unreadable ("
_cmrcredo '{ $10 = "?"; print }'
_cmrcbegins "a receipt whose awaiting count alone is ? is unreadable" "$(_cmrcvalid)" "1 unreadable ("
_cmrcredo '{ $4 = "cmrc-older-claude"; print }'
_cmrcbegins "a well-formed receipt from an older claude cli still reads valid, and says so" "$(_cmrcvalid)" "0 commissioned (the claude cli changed since"
_cmrcredo '{ $4 = "cmrc-older-claude"; for (i = 6; i <= 10; i++) $i = ""; print }'
_cmrcbegins "a receipt from an older claude cli whose counts are empty is unreadable, not announced" "$(_cmrcvalid)" "1 unreadable ("

# The command. Two stubs appended to the fixture's copy of the library, each
# idle unless the run is handed its variable: the check on a row's state ends
# the loop's shell at the call FELIX_CMRC_DIE_AT names, and the counts print
# FELIX_CMRC_COUNTS. The copy is put back the moment the last run returns.
_cmtable "$(printf 'cmrc_first\t-\t-\t-\t-\ttest -f src/a.txt\t9')" \
         "$(printf 'cmrc_held\t-\t-\t-\t-\ttest -f cmrc-no-such-file\t9')" \
         "$(printf 'cmrc_last\t-\t-\t-\t-\ttest -f src/a.txt\t9')"
cat >> "$_cmrclib" <<'CMRCLIB'
_cmrc_known_def="$(declare -f _felix_commission_state_known)"
eval "_cmrc_real_known${_cmrc_known_def#_felix_commission_state_known}"
_felix_commission_state_known() {
  if [ -n "${FELIX_CMRC_DIE_AT:-}" ]; then
    _cmrc_known_n=$(( ${_cmrc_known_n:-0} + 1 ))
    [ "$_cmrc_known_n" -lt "$FELIX_CMRC_DIE_AT" ] || exit 128
  fi
  _cmrc_real_known "$@"; }
_cmrc_counts_def="$(declare -f felix_commission_counts)"
eval "_cmrc_real_counts${_cmrc_counts_def#felix_commission_counts}"
felix_commission_counts() {
  if [ -n "${FELIX_CMRC_COUNTS:-}" ]; then printf '%s' "$FELIX_CMRC_COUNTS"; return 0; fi
  _cmrc_real_counts "$@"; }
CMRCLIB
_cmrccli() { local _cmrcd="$1" _cmrck="$2"; shift 2
  ( cd "$CMR" && FELIX_CMRC_DIE_AT="$_cmrcd" FELIX_CMRC_COUNTS="$_cmrck" PATH="$CMSTUB:$PATH" \
      "$FELIX" commission "$@" 2>&1 ); }
_cmrcclean="$(_cmrccli '' '')"; _cmrccleanx=$?; _cmrccleanr="$(_cmrcresult)"
_cmrcstat="$(_cmrccli 2 '' --status)"
_cmrcshortcli="$(_cmrccli 2 '')"; _cmrcshortx=$?; _cmrcshortr="$(_cmrcresult)"
_cmrcqcli="$(_cmrccli '' '1 1 ? 0 0 0')"; _cmrcqx=$?; _cmrcqr="$(_cmrcresult)"
_cmrcallq="$(_cmrccli '' '? ? ? ? ? ?')"; _cmrcallqx=$?; _cmrcallqr="$(_cmrcresult)"
cp "$TMP/cmrc-lib.keep" "$_cmrclib"
is  "and the engine copy the command ran from is put back byte for byte" \
    "$(cksum < "$_cmrclib")" "$(cksum < "$TMP/cmrc-lib.keep")"

case "$_cmrcclean" in
  *'the run reported'*) bad "a full run that printed every row says nothing about rows missing" \
                            "$(printf '%s\n' "$_cmrcclean" | grep 'the run reported')" ;;
  *)                    ok  "a full run that printed every row says nothing about rows missing" ;;
esac
is  "and writes held over the held row, exiting 0" "$_cmrccleanr $_cmrccleanx" "held 0"
_cmrcreported() { printf '%s\n' "$1" | grep -o 'the run reported [0-9]* of [0-9]* rows' | head -1; }
is  "--status over a run whose loop ended on its second row says it reported 1 of 3 rows" \
    "$(_cmrcreported "$_cmrcstat")" "the run reported 1 of 3 rows"
is  "a full run whose loop ended on its second row says it reported 1 of 3 rows" \
    "$(_cmrcreported "$_cmrcshortcli")" "the run reported 1 of 3 rows"
is  "and writes the receipt indeterminate and exits 1" "$_cmrcshortr $_cmrcshortx" "indeterminate 1"
case "$_cmrcqcli" in
  *'integer expression expected'*)
     bad "a full run whose unknown count reads ? writes no integer expression expected anywhere" \
         "$(printf '%s\n' "$_cmrcqcli" | grep 'integer expression expected')" ;;
  *) ok  "a full run whose unknown count reads ? writes no integer expression expected anywhere" ;;
esac
is  "and writes the receipt indeterminate and exits 1, not held" "$_cmrcqr $_cmrcqx" "indeterminate 1"
# Added after review, not blind. The summary line and the two sections after
# it test the held, malformed, awaiting and unknown counts, and only the
# unknown one was ever ?. And the sentence under a short run says only what is
# true of the receipt: --status writes none, so it may not say indeterminate.
case "$_cmrcallq" in
  *'integer expression expected'*)
     bad "a full run whose every count reads ? writes no integer expression expected anywhere" \
         "$(printf '%s\n' "$_cmrcallq" | grep 'integer expression expected')" ;;
  *) ok  "a full run whose every count reads ? writes no integer expression expected anywhere" ;;
esac
is  "and writes the receipt indeterminate and exits 1" "$_cmrcallqr $_cmrcallqx" "indeterminate 1"
has "--status over a short run says a receipt over it would be indeterminate" "$_cmrcstat" "would be indeterminate"
case "$_cmrcstat" in
  *'was written indeterminate'*) bad "and does not say one was written" "$(printf '%s\n' "$_cmrcstat" | grep 'was written')" ;;
  *)                             ok  "and does not say one was written" ;;
esac
has "a full run over a short run says the receipt was written indeterminate" "$_cmrcshortcli" "The receipt was written indeterminate"

cp "$TMP/cmrc-table.keep" "$CMP/commissioning.tsv"
if [ -f "$TMP/cmrc-receipt.keep" ]; then mv "$TMP/cmrc-receipt.keep" "$_cmrcrc"; else rm -f "$_cmrcrc"; fi
if [ -f "$TMP/cmrc-log.keep" ]; then mv "$TMP/cmrc-log.keep" "$_cmrclog"; else rm -f "$_cmrclog"; fi
rm -f "$TMP/cmrc-table.keep" "$TMP/cmrc-lib.keep" "$TMP/cmrc-stderr" "$TMP/cmrc-good.receipt" "$TMP/cmrc-redo.receipt"
is  "and this block leaves the table, the receipt, the log, the engine copy and every cmrc- file as it found them" \
    "$(_cmrcfixture)" "$_cmrcfound"
unset -f _cmrcfixture _cmrccomplete _cmrcwrite _cmrcresult _cmrcline _cmrcdie _cmrccounts _cmrcfields _cmrcerr \
         _cmrcblank _cmrcplain _cmrcvalid _cmrcredo _cmrcbegins _cmrccli _cmrcreported _cmrcl1
unset _cmrcrc _cmrclib _cmrclog _cmrcfound _cmrcfull _cmrcalpha _cmrcauto _cmrcstray _cmrctwice _cmrcshort _cmrcwhole \
      _cmrcrows _cmrcgap _cmrcclean _cmrccleanx _cmrccleanr _cmrcstat _cmrcshortcli _cmrcshortx _cmrcshortr \
      _cmrcqcli _cmrcqx _cmrcqr _cmrcallq _cmrcallqx _cmrcallqr

# What nothing serves, reaches or grounds, enumerated from the checkout.
has "a detected surface no row serves, reaches or grounds is named with all three misses" \
    "$(_cm felix_commission_gaps "$CMP" "$CMR")" "secrets	no	no	no"
has "a template need this table lacks is named" \
    "$(_cm felix_commission_template_missing "$CMP" "$FROOT/harness/templates")" "envelope"
has "a pipeline step nothing answers is named from the architecture, not the table" \
    "$(_cm felix_commission_steps_unanswered "$CMP" "$FROOT/harness/templates")" "8	"

# The command: refuses the absent and empty table, writes the receipt, reads
# it back, and says who answers what is held.
_cmcli() { ( cd "$CMR" && PATH="$CMSTUB:$PATH" "$FELIX" commission "$@" 2>&1 ); }
mv "$CMP/commissioning.tsv" "$CMP/commissioning.keep"
_cmo="$(_cmcli)"; _cmrc=$?
is  "felix commission on a project without the table exits 1" "$_cmrc" "1"
has "and names the template"                                  "$_cmo"  "templates/commissioning.tsv"
printf '# only a comment\n' > "$CMP/commissioning.tsv"
_cmo="$(_cmcli)"; _cmrc=$?
is  "a table of comments exits 1"                       "$_cmrc" "1"
has "and calls it a shelf with nothing on it"           "$_cmo"  "shelf with nothing on it"
_cmo="$(_cmcli --yes)"; _cmrc=$?
is  "there is no --yes"                                 "$_cmrc" "1"
mv "$CMP/commissioning.keep" "$CMP/commissioning.tsv"

# One run at a time, and only for the run that writes.
#
# A full run appends to stack.tsv twice, to commissioning.log and a play into
# routes.tsv. None is atomic, none idempotent, so two interleaving runs write a
# row half by each — a table that reads as somebody typing it wrong, produced
# by two commands each doing what it was told. cmd_commission held no mutex of
# any kind, so nothing stopped it.
_cmlock="$FROOT/state/commission/$(basename "$CMP").lock"
mkdir -p "$(dirname "$_cmlock")"; mkdir "$_cmlock" 2>/dev/null
printf '%s\n' "$$" > "$_cmlock/pid"          # this process is alive by construction
_cmo="$(_cmcli)"; _cmrc=$?
is  "a second full run refuses while one is in progress"  "$_cmrc" "1"
has "and names the process holding it"                    "$_cmo"  "already in progress (pid $$)"
has "and points at the read that needs no lock"           "$_cmo"  "--status"
# --status writes nothing, so it takes nothing: making a person's read wait on
# somebody else's run would be a lock doing harm to buy nothing.
_cmo="$(_cmcli --status)"; _cmrc=$?
is  "while --status reads straight through it"            "$_cmrc" "0"
# A lock whose owner is gone is not a lock. This one is taken by a command a
# person typed, so a dead owner must not shut them out of their own project —
# the opposite of the background refresh's lock, where sitting there costs
# only a stale cache.
printf '%s\n' "999999" > "$_cmlock/pid"
_cmo="$(_cmcli)"
case "$_cmo" in
  *"already in progress"*) bad "a lock whose owner is gone is taken over" "$_cmo" ;;
  *)                       ok  "a lock whose owner is gone is taken over" ;;
esac
is  "and the run that took it over leaves nothing behind" \
    "$([ -d "$_cmlock" ] && echo held || echo clear)" "clear"

# The one place Felix talks to a host it does not control must not be able to
# hang, or to ask a terminal for credentials.
#
# There is no portable timeout — neither timeout nor gtimeout is on this
# machine — so the deadline is git's own low-speed abort. Asserted through a
# stub git that reports the environment it was handed, because the property is
# what git receives, not what the source says.
_gb="$TMP/gitenv-bin"; mkdir -p "$_gb"
printf '#!/usr/bin/env bash\nprintf "%%s %%s %%s\\n" "${GIT_TERMINAL_PROMPT:-unset}" "${GIT_HTTP_LOW_SPEED_LIMIT:-unset}" "${GIT_HTTP_LOW_SPEED_TIME:-unset}" > "$GITENV_OUT"\nexit 0\n' > "$_gb/git"
chmod +x "$_gb/git"
# Exported, or the stub is a child that cannot see it — the trap this suite
# already paid for once tonight.
export GITENV_OUT="$TMP/gitenv.out"
( PATH="$_gb:$PATH"; . "$FROOT/harness/lib/discover.sh"; _felix_discover_git status >/dev/null 2>&1 )
is "the fetch never asks a terminal for credentials" \
   "$(cut -d' ' -f1 "$GITENV_OUT" 2>/dev/null)" "0"
case "$(cut -d' ' -f2 "$GITENV_OUT" 2>/dev/null)" in
  unset|'') bad "and carries a low-speed deadline so a stall cannot wait forever" ;;
  *)        ok  "and carries a low-speed deadline so a stall cannot wait forever" ;;
esac
unset GITENV_OUT
rm -f "$FROOT/state/commission/cmproj"
_cmo="$(_cmcli --status)"; _cmrc=$?
is  "--status on a never-commissioned project exits 0 and runs nothing" "$_cmrc" "0"
has "and says the receipt does not exist here"    "$_cmo" "never commissioned on this machine"
[ -f "$FROOT/state/commission/cmproj" ] && bad "--status writes no receipt" || ok "--status writes no receipt"
_cmo="$(_cmcli)"; _cmrc=$?
is  "a full run on a clean table exits 0"               "$_cmrc" "0"
has "and reports the receipt it wrote"                  "$_cmo"  "receipt: commissioned"
has "and names who answers the provider row"            "$_cmo"  "a session runs /claude-code-setup:claude-automation-recommender"
has "and names the pipeline step no row here answers"    "$_cmo"  "initialize obligation and evidence state"
[ -f "$FROOT/state/commission/cmproj" ] && ok "the run writes the receipt" || bad "the run writes the receipt"
printf 'api\n' >> "$CMP/capabilities"
has "--status after a table edit reads stale"           "$(_cmcli --status)" "stale (table set moved"

# The gate line: offline, announce-only, except the empty case.
_cmgate() { ( cd "$CMR" && PATH="$CMSTUB:$PATH" "$FELIX" gate 2>&1 ); }
has "the gate announces a stale receipt and does not fail on it" "$(_cmgate)" "commission         stale"
_cmcli >/dev/null 2>&1
: > "$CMSTUB_LOG"
has "after commissioning the gate line reads ok"        "$(_cmgate)" "commission         ok"
is  "and the gate line called no cli"                   "$(grep -c . "$CMSTUB_LOG")" "0"
mv "$CMP/commissioning.tsv" "$CMP/commissioning.keep"
has "a project without the table is skipped, announced" "$(_cmgate)" "skipped (no commissioning.tsv"
printf '# empty\n' > "$CMP/commissioning.tsv"
_cmg="$(_cmgate)"
has "an empty table fails the gate"                     "$_cmg" "commission         FAIL"
has "and lands in mistakes.log under its own name"      "$(tail -1 "$MEM/cmproj/mistakes.log")" "commission"
mv "$CMP/commissioning.keep" "$CMP/commissioning.tsv"
grep -v '^api$' "$CMP/capabilities" > "$CMP/caps.tmp"; mv "$CMP/caps.tmp" "$CMP/capabilities"

# The merge boundary: the second place the empty case is refused, and the
# one that bites on staleness. Never on held rows.
_cmblk() { ( cd "$CMR" && FELIX_HOME_DIR="$FROOT"
             . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"; . "$FROOT/harness/lib/evidence.sh"; . "$FROOT/harness/lib/verify.sh"
             [ "${1:-}" = "--unload" ] && unset -f felix_commission_rows
             felix_merge_blockers "$CMP" HEAD~1 "$CMR" "$FROOT" ) 2>/dev/null; }
_cmcli >/dev/null 2>&1
case "$(_cmblk)" in
  *commission*) bad "a valid receipt raises no commission blocker" "$(_cmblk | grep commission)" ;;
  *)            ok  "a valid receipt raises no commission blocker" ;;
esac
printf 'plugin\tlate\t-\tlow\talways\n' >> "$CMP/stack.tsv"
has "a table edited under a valid receipt blocks the merge as a stale receipt" "$(_cmblk)" "commission	receipt"
_cmcli >/dev/null 2>&1
mv "$CMP/commissioning.tsv" "$CMP/commissioning.keep"
has "a project without the table blocks the merge"      "$(_cmblk)" "commission	table"
mv "$CMP/commissioning.keep" "$CMP/commissioning.tsv"
has "an engine that cannot evaluate commissioning blocks rather than skips" "$(_cmblk --unload)" "commission	engine"

# felix new commissions instead of printing the next steps, and writes
# nothing into the tree but the marker.
CMS="$TMP/cm-stranger"; mkdir -p "$CMS"
( _fx_cd "$CMS" && git init -q -b main ) >/dev/null 2>&1
printf '{ "name": "cms", "scripts": { "verify": "echo ok" }, "dependencies": { "express": "^4" } }\n' > "$CMS/package.json"
: > "$CMSTUB_LOG"
_cmn="$(cd "$CMS" && PATH="$CMSTUB:$PATH" "$FELIX" new cmstranger 2>&1)"; _cmnrc=$?
is  "felix new still exits 0"                                    "$_cmnrc" "0"
has "and commissions"                                            "$_cmn" "commissioning for cmstranger"
case "$_cmn" in *'next:'*) bad "and no longer prints next steps" ;; *) ok "and no longer prints next steps" ;; esac
case "$_cmn" in *'Felix already covers verification'*|*'paste into a session'*) bad "nor a paste-in prompt" ;; *) ok "nor a paste-in prompt" ;; esac
has "and the provider skill is named as a channel a session runs, not a prompt to paste" "$_cmn" "a session runs /claude-md-management:claude-md-improver"
is  "the tree holds only the marker beside what was there" \
    "$(cd "$CMS" && ls -A | grep -v '^\.git$' | LC_ALL=C sort | tr '\n' ' ')" ".felix package.json "
[ -f "$FROOT/projects/cmstranger/commissioning.tsv" ] && ok "the table is seeded" || bad "the table is seeded"
is  "and the receipt is written with ten fields" \
    "$(awk -F'\t' '{ print NF }' "$FROOT/state/commission/cmstranger" 2>/dev/null)" "10"
# Two rows this machine cannot already have: one low, one high. Asserted on
# a declared row rather than on the catalogue's, because on the founder's
# machine every catalogue plugin is bundled and the inventory now sees that,
# so the seeded rows install nothing here and did on the runner — a stub
# log that depends on whose machine it is proves nothing.
printf 'plugin\tfelix-test-absent-cm@nowhere\t-\tlow\talways\n' >> "$FROOT/projects/cmstranger/stack.tsv"
printf 'plugin\tevil\t-\thigh\talways\n' >> "$FROOT/projects/cmstranger/stack.tsv"
: > "$CMSTUB_LOG"
( cd "$CMS" && PATH="$CMSTUB:$PATH" "$FELIX" commission >/dev/null 2>&1 )
has "stack apply ran through the stub for a declared low row" "$(cat "$CMSTUB_LOG")" "plugin install felix-test-absent-cm"
case "$(cat "$CMSTUB_LOG")" in *evil*) bad "a high-risk row is never installed by commissioning" "$(cat "$CMSTUB_LOG")" ;; *) ok "a high-risk row is never installed by commissioning" ;; esac
# The stub can fail, so the assertions that depend on it can.
( PATH="$CMSTUB:$PATH" claude plugin uninstall anything >/dev/null 2>&1 ) && bad "the stub refuses an untaught shape" || ok "the stub refuses an untaught shape"

# Step 8 of the pipeline — initialize obligation and evidence state — had no
# row answering it since the pipeline was written. Now felix new seeds the
# ledger, and the commissioning row seeds it where felix new never ran.
[ -f "$FROOT/projects/cmstranger/obligations.tsv" ] && ok "felix new seeds the obligations ledger" || bad "felix new seeds the obligations ledger"
is  "with the template's one row, the lifecycle obligation every plugin owes" \
    "$(grep -vE '^[[:space:]]*(#|$)' "$FROOT/projects/cmstranger/obligations.tsv" 2>/dev/null | cut -f1)" "lifecycle_wired"
# felix new's OWN cp, not the commissioning answer standing in for it. The
# first version of this asserted only that the file exists, which is true
# either way: with the cp removed the row is held, the runner executes
# `felix:obligations --seed`, and the file appears anyway. The detail line is
# what tells the two apart.
case "$_cmn" in
  *'ran obligations --seed'*) bad "and felix new seeds it itself, without falling through to the answer" "$_cmn" ;;
  *) ok "and felix new seeds it itself, without falling through to the answer" ;;
esac
# And the seeded row is dormant for a project that is not a plugin. The
# template's applies once asked only for a tracked path ending in hooks.json,
# so a web app with src/config/hooks.json was handed an ACTIVE obligation
# whose evidence is a hold — UNKNOWN, blocking — on the day it was created.
CMW="$TMP/cm-webapp"; mkdir -p "$CMW/src/config"
( _fx_cd "$CMW" && git init -q -b main && printf '{"webhooks":[]}\n' > src/config/hooks.json \
  && printf '{ "name": "w", "scripts": { "verify": "echo ok" } }\n' > package.json \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm init ) >/dev/null 2>&1
_cmw="$(cd "$CMW" && PATH="$CMSTUB:$PATH" "$FELIX" new cmwebapp 2>&1)"
is  "a stranger that is not a plugin is created without a blocking obligation" \
    "$(cd "$CMW" && PATH="$CMSTUB:$PATH" "$FELIX" obligations 2>/dev/null | grep -c 'DORMANT')" "1"
case "$(cd "$CMW" && PATH="$CMSTUB:$PATH" "$FELIX" obligations 2>&1)" in
  *UNKNOWN*) bad "and a file merely named hooks.json does not make the row apply" "$(cd "$CMW" && PATH="$CMSTUB:$PATH" "$FELIX" obligations 2>&1)" ;;
  *)         ok  "and a file merely named hooks.json does not make the row apply" ;;
esac
is  "so its gate is not red on the day it was created" \
    "$(cd "$CMW" && PATH="$CMSTUB:$PATH" "$FELIX" obligations >/dev/null 2>&1; echo $?)" "0"
# The receipt is hashed over the tables that decide, and the step-8 row reads
# obligations.tsv, so a ledger edited under a valid receipt must invalidate it.
is  "obligations.tsv is one of the tables the receipt is bound to" \
    "$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/commission.sh"
        printf '%s' "$FELIX_COMMISSION_TABLES" | tr ' ' '\n' | grep -cx 'obligations.tsv' )" "1"
_cms="$(cd "$CMS" && PATH="$CMSTUB:$PATH" "$FELIX" commission --status 2>&1)"
case "$_cms" in
  *"initialize obligation and evidence state"*) bad "and step 8 is no longer a step nothing answers" "$_cms" ;;
  *) ok "and step 8 is no longer a step nothing answers" ;;
esac
is  "the obligations row is done on day one, its seeded row dormant in a project with no hooks" \
    "$(printf '%s\n' "$_cms" | grep -cE '^  done +obligations ')" "1"
# The answer, run by hand and by the commissioning run, and never over a ledger.
rm -f "$FROOT/projects/cmstranger/obligations.tsv"
_cmso="$(cd "$CMS" && PATH="$CMSTUB:$PATH" "$FELIX" obligations --seed 2>&1)"; _cmsrc=$?
is  "felix obligations --seed writes the template where no ledger is" "$_cmsrc" "0"
has "and says so" "$_cmso" "seeded"
printf '# a person wrote this\n' >> "$FROOT/projects/cmstranger/obligations.tsv"
_cmso="$(cd "$CMS" && PATH="$CMSTUB:$PATH" "$FELIX" obligations --seed 2>&1)"; _cmsrc=$?
is  "and a second run is a no-op that exits 0" "$_cmsrc" "0"
has "saying seeding never overwrites" "$_cmso" "never overwrites"
has "and the person's edit survives it" "$(cat "$FROOT/projects/cmstranger/obligations.tsv")" "a person wrote this"
rm -f "$FROOT/projects/cmstranger/obligations.tsv"
( cd "$CMS" && PATH="$CMSTUB:$PATH" "$FELIX" commission >/dev/null 2>&1 )
[ -f "$FROOT/projects/cmstranger/obligations.tsv" ] && ok "a commissioning run seeds the ledger through the row's answer" \
  || bad "a commissioning run seeds the ledger through the row's answer"
has "and the engine names the stage among the answers a row may carry" \
    "$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/commission.sh"; felix_commission_instruments | tr '\n' ' ' )" \
    "felix:obligations --seed"

# The moment is declared, so a stance at it is not a typo.
printf 'capability:api\tcommissioning\tfelix commission\t-\n' > "$CMP/procedures.tsv"
case "$(_cm felix_procedures_unknown_moments "$CMP" "$FROOT/harness/templates" 2>/dev/null)" in
  *commissioning*) bad "a stance at the commissioning moment is not a stance at an unknown moment" ;;
  *)               ok  "a stance at the commissioning moment is not a stance at an unknown moment" ;;
esac
rm -f "$CMP/procedures.tsv"


# ------------------------------------------------ the provider protocol ----
# A provider row is a skill a session's model runs, which the engine cannot.
# The engine writes a request into the memory root, the session writes an
# answer beside it, and the engine reads the answer with no model and no
# network — amendments §1.3, applied to the two setup skills. The answer is
# keyed to a topology ingestion never writes; every row read is INFERRED; an
# answered row holds nothing and installs nothing.
_cmtable 'alpha	-	-	-	-	test -f src/a.txt	3' \
         'automation_surveyed	-	-	-	provider:claude-code-setup:claude-automation-recommender	-	4' \
         'constitution_audited	-	-	-	provider:claude-md-management:claude-md-improver	-	4'
rm -rf "$MEM/cmproj/commission"; : > "$MEM/cmproj/commissioning.log"
_cmp() { _cm felix_commission_provider_state "$CMP" "$CMR" "$1" | cut -f1; }
_cmreq="$MEM/cmproj/commission/requests/automation_surveyed.md"
_cmans="$MEM/cmproj/commission/automation_surveyed.tsv"
_cmtopo="$(_cm felix_commission_topology "$CMP" "$CMR")"

_cmcli >/dev/null 2>&1
[ -f "$_cmreq" ] && ok "a run writes the request for each provider row" || bad "a run writes the request for each provider row"
has "and the request carries the topology it is for"   "$(cat "$_cmreq" 2>/dev/null)" "$_cmtopo"
is  "and every placeholder was filled"                 "$(grep -c '{{' "$_cmreq" 2>/dev/null)" "0"
has "and names the answer file to write"               "$(cat "$_cmreq" 2>/dev/null)" "$_cmans"
has "the row is awaiting, UNKNOWN by class"            "$(grep '	automation_surveyed	' "$MEM/cmproj/commissioning.log" | tail -1)" "	awaiting	UNKNOWN	"
is  "--status writes no request"                       "$(rm -f "$_cmreq"; _cmcli --status >/dev/null 2>&1; [ -f "$_cmreq" ] && echo written || echo none)" "none"
_cmcli >/dev/null 2>&1

printf '# topology 0000\nplugin\tfoo\t-\tllm\twhy\ndone\t1\n' > "$_cmans"
is  "an answer for another topology is stale, and not read"        "$(_cmp automation_surveyed)" "stale"
printf '# topology %s\nplugin\tfoo\t-\tllm\twhy\n' "$_cmtopo" > "$_cmans"
is  "an answer with no terminal done row is partial"               "$(_cmp automation_surveyed)" "partial"
printf '# topology %s\nplugin\tfoo\t-\tllm\twhy\ndone\t3\n' "$_cmtopo" > "$_cmans"
is  "a done count that disagrees with the rows is partial"         "$(_cmp automation_surveyed)" "partial"
printf '# topology %s\nplugin\tfoo\t-\tllm\twhy\nplugin\tbar\t-\tllm\twhy\thigh\nrocket\tbaz\t-\t-\twhy\nmcp\tsentry\t-\tobservability\twhy\ndone\t4\n' "$_cmtopo" > "$_cmans"
is  "a well-formed answer is answered"                             "$(_cmp automation_surveyed)" "answered"
is  "and only rows of the right shape and kind are accepted" \
    "$(_cm felix_commission_provider_rows "$CMP" automation_surveyed | cut -f2 | tr '\n' ' ')" "foo sentry "
has "a row carrying a risk column is refused, because risk is not the model's to assign" \
    "$(_cm felix_commission_provider_rejects "$CMP" automation_surveyed)" "bar	6 fields"
has "and an unknown kind is refused"                               "$(_cm felix_commission_provider_rejects "$CMP" automation_surveyed)" "baz	kind"
# And a kind that is a RUN of known kinds is refused too. The filter was
# `case " $KINDS " in *" $kind "*`, a space-padded substring test, so "plugin
# mcp" matched the middle of the list and passed. That is not cosmetic: the
# admit phase refuses an mcp row by matching the kind EXACTLY, so a row spelled
# "plugin mcp" skipped the refusal and reached the fetch — the one thing spec
# §7 T3 says must never be activated unattended.
printf '# topology %s\nplugin mcp\tsneaky\t-\tllm\twhy\ndone\t1\n' "$_cmtopo" > "$_cmans"
has "a kind that is two known kinds run together is refused" \
    "$(_cm felix_commission_provider_rejects "$CMP" automation_surveyed)" "sneaky	kind"
is  "and it is not accepted as a row" \
    "$(_cm felix_commission_provider_rows "$CMP" automation_surveyed)" ""
printf '# topology %s\nplugin\tfoo\t-\tllm\twhy\nplugin\tbar\t-\tllm\twhy\thigh\nrocket\tbaz\t-\t-\twhy\nmcp\tsentry\t-\tobservability\twhy\ndone\t4\n' "$_cmtopo" > "$_cmans"

# The reader enforced a length that nothing stated. An accepted row's fields
# are written into commissioning.log through `cut -c1-160`, so a long sentence
# was stored truncated mid-word while the row itself read as accepted. The log
# is append-only and outlives the answer file, which the next topology change
# rewrites — so the reason was not clipped, it was lost. #156 settled the rule
# this breaks: the request states every constraint the reader enforces.
_cmwhy() { printf 'w%.0s' $(seq 1 "$1"); }
printf '# topology %s\nplugin\ttoolong\t-\tllm\t%s\ndone\t1\n' "$_cmtopo" "$(_cmwhy 301)" > "$_cmans"
has "a why past the stated ceiling is refused rather than silently cut" \
    "$(_cm felix_commission_provider_rejects "$CMP" automation_surveyed)" "toolong	a why longer than"
is  "and no row is accepted from that file" \
    "$(_cm felix_commission_provider_rows "$CMP" automation_surveyed)" ""
printf '# topology %s\nplugin\tsrctoolong\t%s\tllm\twhy\ndone\t1\n' "$_cmtopo" "$(_cmwhy 201)" > "$_cmans"
has "a source past its ceiling is refused too" \
    "$(_cm felix_commission_provider_rejects "$CMP" automation_surveyed)" "srctoolong	a source longer than"

# The row at the ceiling is accepted AND survives the log whole. This is the
# assertion that matters: it is what makes the ceiling and the log's own bound
# one fact rather than two that can drift apart. A cut that bites anything the
# reader accepted is the defect, whatever the numbers are.
printf '# topology %s\nplugin\tatmax\t%s\tllm\t%s\ndone\t1\n' "$_cmtopo" "$(_cmwhy 200)" "$(_cmwhy 300)" > "$_cmans"
is  "a row at both ceilings is accepted" \
    "$(_cm felix_commission_provider_rows "$CMP" automation_surveyed | cut -f2)" "atmax"
: > "$MEM/cmproj/commissioning.log"
_cmcli >/dev/null 2>&1
is  "and with the whole sentence, not a prefix of it" \
    "$(awk -F'\t' '$9 ~ /^plugin atmax/ { n = gsub(/w/, "w", $9); print n }' "$MEM/cmproj/commissioning.log" | tail -1)" "500"

# The request has to say so, or the refusals above are a trap rather than a
# contract.
has "the request states the why ceiling"    "$(cat "$_cmreq")" "300"
has "and states the source ceiling"         "$(cat "$_cmreq")" "200"

# Restore what this block changed, so the ingestion assertions below read the
# file they were written against.
printf '# topology %s\nplugin\tfoo\t-\tllm\twhy\nplugin\tbar\t-\tllm\twhy\thigh\nrocket\tbaz\t-\t-\twhy\nmcp\tsentry\t-\tobservability\twhy\ndone\t4\n' "$_cmtopo" > "$_cmans"
# The log too: the run above ingested a nomination, and the ingestion
# assertions below count nomination lines from an empty log. Restoring the
# answer file without the log would leave them counting this block's row.
: > "$MEM/cmproj/commissioning.log"
is  "the fixture answer is restored" \
    "$(_cm felix_commission_provider_rows "$CMP" automation_surveyed | cut -f2 | tr '\n' ' ')" "foo sentry "
is  "and the log is back to empty, as this block found it" \
    "$(grep -c . "$MEM/cmproj/commissioning.log")" "0"

# The receipt, the gate line and the merge boundary are byte-identical before
# and after an answer appears: a model's file clears nothing enforcing.
mv "$_cmans" "$_cmans.keep"; _cmcli >/dev/null 2>&1
_cmr_before="$(cut -f2-9 "$FROOT/state/commission/cmproj")"; _cmg_before="$(_cmgate | grep '^  commission')"; _cmb_before="$(_cmblk | grep commission)"
_cma_before="$(cut -f10 "$FROOT/state/commission/cmproj")"
mv "$_cmans.keep" "$_cmans"; _cmo="$(_cmcli)"
# Everything enforcing in the receipt — the two hashes, the toolchain, the
# result and the four counted states — is byte-identical; the one field that
# moves is the informational awaiting count, which is the record that the
# session answered.
is  "an answer file moves nothing enforcing in the receipt" "$(cut -f2-9 "$FROOT/state/commission/cmproj")" "$_cmr_before"
is  "and only the awaiting count records it"  "$(cut -f10 "$FROOT/state/commission/cmproj")" "$((_cma_before - 1))"
is  "changes no gate line"                   "$(_cmgate | grep '^  commission')" "$_cmg_before"
is  "and raises or clears no merge blocker"  "$(_cmblk | grep commission)" "$_cmb_before"
# Nomination lines carry the provider as actor and the file hash as provenance;
# the row-level line for the same run carries the file hash too.
_cmnom() { awk -F'\t' '$5 == "answered" && $7 ~ /^provider:/ && $8 ~ /automation_surveyed\.tsv@/ && $9 !~ /^[0-9]+ rows at/' "$MEM/cmproj/commissioning.log"; }
has "the run records the accepted rows as INFERRED with the file's hash as provenance" \
    "$(_cmnom | tail -1)" "claude-code-setup@"
has "and the row-level line names the same file"  "$(awk -F'\t' '$4 == "automation_surveyed" && $9 ~ /rows at/' "$MEM/cmproj/commissioning.log" | tail -1)" "automation_surveyed.tsv@"
is  "two rows, once each"                    "$(_cmnom | grep -c .)" "2"
_cmcli >/dev/null 2>&1
is  "and a second run does not record the same file twice" "$(_cmnom | grep -c .)" "2"
has "the report lists what the provider named and says nothing was installed" "$_cmo" "recorded and not acted on"

# The topology in a checkout whose path holds a space. felix_detect globs
# $root/$p unquoted, so what it finds there depends on IFS. `felix commission`
# read the provider state inside the heredoc of an `IFS=$'\t' read`, and on
# bash 3.2 that substitution ran under the tab IFS: it hashed a different
# topology from session-start's and the request's, so an answer current for
# one read stale on the other. Its own project, so no fixture above moves.
CSP="$FROOT/projects/cmspace"; CSR="$TMP/cm-ifs space/repo"
mkdir -p "$CSP" "$CSR/tests" "$MEM/cmspace/commission"
printf 'FROM scratch\n' > "$CSR/Dockerfile"
printf '# need\tgrounds\tinstrument\twhen\tanswer\tcheck\tstep\nautomation_surveyed\t-\t-\t-\tprovider:claude-code-setup:claude-automation-recommender\t-\t4\n' \
  > "$CSP/commissioning.tsv"
# Computed as session-start computes it, at the default IFS.
_cstopo="$(_cm felix_commission_topology "$CSP" "$CSR")"
if [ "$(IFS=$'\t'; _cm felix_commission_topology "$CSP" "$CSR")" != "$_cstopo" ]; then
  ok   "a checkout path with a space makes the topology depend on IFS, so the assertion below can reach the trap"
else
  skip "a checkout path with a space makes the topology depend on IFS, so the assertion below can reach the trap" \
       "detection no longer depends on IFS here"
fi
printf '# topology %s\nplugin\tfoo\t-\tllm\twhy\ndone\t1\n' "$_cstopo" > "$MEM/cmspace/commission/automation_surveyed.tsv"
is  "session-start reads an answer keyed to its topology as answered, in a checkout whose path holds a space" \
    "$(_cm felix_commission_provider_state "$CSP" "$CSR" automation_surveyed | cut -f1)" "answered"
is  "and felix commission hashes the same topology there, so it reads the same answer as answered" \
    "$(_cm felix_commission_run "$CSP" "$CSR" - | awk -F'\t' '$1 == "automation_surveyed" { print $2 }')" "answered"
rm -rf "$CSP" "$MEM/cmspace" "$TMP/cm-ifs space"

