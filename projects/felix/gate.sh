#!/usr/bin/env bash
# Felix's own gate.
#
# Felix had 140 assertions and nothing that ran them, which is the same gap it
# was built to close in every other project. A governance layer that is not
# itself governed is an argument nobody has to take seriously.
#
# Gates the tree it is standing in, not the tree this file lives in.

set -uo pipefail

if ! ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  echo "gate: $PWD is not inside a git worktree." >&2; exit 2
fi
cd "$ROOT" || exit 2
[ -d engine/harness ] || { echo "gate: $ROOT is not Felix (no engine/harness). Refusing." >&2; exit 2; }

FAILED=""
pass() { printf '  %-18s ok\n' "$1"; }
fail() { printf '  %-18s FAIL\n' "$1"; FAILED="$FAILED $1"; }

echo "gate: $ROOT"
echo "      $(git rev-parse --abbrev-ref HEAD) @ $(git rev-parse --short HEAD)"

# ------------------------------------------------------------- syntax --------
# Every shell file must parse. A harness that fails to source is a harness that
# silently governs nothing, and that failure is invisible in a session hook.
BAD=""
while IFS= read -r f; do
  bash -n "$f" 2>/dev/null || BAD="$BAD $f"
done <<EOF
$(git ls-files 'engine/harness/*' 'projects/*/*.sh' | grep -vE '\.(json|tsv|md|ya?ml|html|css|txt)$')
EOF
# Reported on its own line, and that is load-bearing rather than stylistic. The
# `verifier` confine on this file counts lines matching `^[[:space:]]*(pass|fail|check) `,
# so a report written mid-line after `&&` is not counted and the whole check
# could be deleted without the count dropping — no escape, on the file whose
# reason column reads "a gate that cannot fail is not a gate" (#77).
if [ -z "$BAD" ]; then
  pass syntax
else
  fail syntax; printf '    %s\n' $BAD
fi

# ------------------------------------------------------------- executable ----
# A hook or a tool that lost its executable bit fails at the worst moment, in
# somebody else's session, with no output.
#
# Enumerated, never listed: a hand-kept list named three hooks when there were
# seven, and stops matching what exists. Every script under bin/ counts, since a
# probe or evidence contract naming one that lost its bit reads `unknown` and
# blocks. The check is a command, engine/harness/bin/executable-check, so felix
# qualify can ask whether it fails when the thing it protects is broken; asked
# blind, it found it demanded the mode bit of everything in those directories (a
# README turned the gate red), so it asks each file for a shebang. Announced when
# absent, never silent (#77).
if [ -x engine/harness/bin/executable-check ]; then
  if OUT="$(engine/harness/bin/executable-check 2>&1)"; then
    pass executable
  else
    fail executable; printf '%s\n' "$OUT" | head -8 | sed 's/^/    /'
  fi
else
  printf '  %-18s skipped (no executable-check here)\n' executable
fi

# ------------------------------------------------------------- schema --------
# Every tracked table declared, and every row of it a row. The engine parses
# tab-separated rows at some five hundred sites in a dozen idioms, and on the
# shapes they disagree about — an indented comment, an empty cell, a missing
# final newline — two readers of one table read two different tables. Removing
# deny.tsv's last newline switched its last rule off on the enforcing path
# while the escape check that guards the table saw the same lines. The schema
# check refuses those shapes, so on a table it accepts every reader agrees.
#
# A table with no row in engine/harness/templates/schemas.tsv fails: the check
# says what it cannot see rather than passing it. A command,
# engine/harness/bin/schema-check, so that felix qualify can ask it whether it
# fails. Absent is a FAIL, not the skip the checks above announce: those were
# written for trees that might predate them, and this one ships in the same
# commit as the gate that runs it, so a tree without it is a tree that removed it.
if [ -x engine/harness/bin/schema-check ]; then
  if OUT="$(engine/harness/bin/schema-check 2>&1)"; then
    pass schema
  else
    fail schema; printf '%s\n' "$OUT" | head -8 | sed 's/^/    /'
  fi
else
  fail schema; printf '    no executable engine/harness/bin/schema-check in this tree\n'
fi

# ------------------------------------------------------------- handoff -------
# HANDOFF.md changes only as the fold writes it. A session adds its section as
# a file under docs/handoff/pending/ (felix handoff --section), and ids, the
# archive and the index come from the order sections landed on main (felix
# handoff --rotate). Writing a section into HANDOFF.md by hand is refused here,
# because that shared slot is how four pull requests claimed one id inside an
# hour on 2026-09-23; so is rewriting or dropping an archived section.
#
# Absent is announced and skipped, not failed, unlike schema's. This file is
# read from the home while the tree is a worktree's, so a branch cut before the
# check existed would go red for a file it never had. A tree that removed it
# is caught anyway, by the suite, which calls it.
if [ -x engine/harness/bin/handoff-check ]; then
  if OUT="$(engine/harness/bin/handoff-check 2>&1)"; then
    pass handoff
  else
    fail handoff; printf '%s\n' "$OUT" | head -8 | sed 's/^/    /'
  fi
else
  printf '  %-18s skipped (no engine/harness/bin/handoff-check in this tree)\n' handoff
fi

# Moved above `tests` on 2026-08-13. This check had failed 8 times, every one of
# them discovered after a full suite run, because the loop is edit -> gate ->
# find it never deployed -> bump -> install -> gate again. `felix next` surfaced
# it as a lesson that was written down and kept being violated anyway, which is
# the signal that prose was never the fix. Nothing is removed and nothing is
# weakened: the same checks run, and the one that answers in a second now
# answers before the one that takes minutes.
# ------------------------------------------------------------- installed -----
# Written is not installed. The lessons hook existed in the repository, passed
# its tests, and was absent from the plugin cache, so it ran nowhere. A harness
# change that is not deployed governs nothing, and nothing else would have said
# so.
#
# WHAT IT ASKS, since #2 (docs/2026-08-18-promotion-spec.md, steps 2-4). It used
# to ask whether the engine in the tree standing here is the deployed one. Only
# the checkout the marketplace serves can ever answer yes, so `felix merge`
# existed in one folder, and the only workflow that reached it deployed the
# candidate before it was judged — by merge time the candidate was the
# evaluator. It now asks whether the cache entry for the version MAIN declares
# is byte-identical to MAIN's engine. Every checkout can answer that.
#
# WHO ANSWERS. felix_accepted_deploy_diff in lib/resolve.sh, the one reader of
# this question — the same function deploy-check asks for the engine_deployed
# obligation, so the gate and the ledger cannot disagree by construction. This
# block carried its own copy of that comparison until 2026-09-17, on the
# argument that a verifier which sources the code it judges can be switched off
# by editing that code. The argument stands and the copy does not: the function
# sourced here is read from the BASE REF with `git show`, never from this
# working tree and never from the cache entry, so the code that judges is the
# code main already accepted, and nothing a candidate branch writes reaches it.
# Sourced in a subshell, so its definitions never enter this gate. A base whose
# resolve.sh lacks the function cannot answer, and that is a FAIL naming it —
# never an ok and never a skip.
#
# Where "written is not installed" went (spec §8 criterion 2): on main, after a
# merge that changed the engine and before anybody deployed it, main's engine
# and its version's entry differ, and this fails. A version main declares with
# no entry at all fails too — never skips. All three deployed directories, not
# harness alone (#82), and a path git ignores is residue rather than drift (#86);
# both live in the function now, with their reasons beside them. One reading
# moved with them, found by review rather than by the suite: a directory main
# does not ship, present in the entry with nothing in it but ignored residue,
# was drift to the copy — the missing diff operand — and is residue to the
# function, because what git ignores is subtracted before the question is
# asked. That is what deploy-check already answered for the same fact; the
# gate says the same now, and the suite pins it beside felix_deploy_diff.
#
# What a green no longer says (spec §7): which engine is live. Installing a
# candidate adds a different entry and moves the live pointer without touching
# the one checked here. So when the CLI reports a live engine that is not
# main's, the ok says which one is, out loud rather than discovered.
#
# FELIX_KERNEL, the suite's override of the judge, is not honoured here: this
# checks the real cache. Skipped when no felix cache exists on this machine,
# which is the normal state in CI.
GCACHE="${FELIX_KERNEL_CACHE:-${FELIX_PLUGIN_CACHE:-$HOME/.claude/plugins/cache}/felix/felix}"
if [ -d "$GCACHE" ]; then
  INSTALL_DRIFT=0
  # The differing paths, held here rather than in a file. They sat in one fixed
  # path under /tmp that every gate on the machine truncated and rewrote, so a
  # gate whose own drift was empty could print another tree's: the defect the
  # tests block below records for the suite log, one check up.
  GDRIFT=""
  GWHY=""
  # The branch being merged into, as felix_base_ref resolves it: the remote's
  # copy first, so a local main that lags the remote is not what gets
  # certified. By FULL name, each looked up as exactly that ref and checked to
  # be a commit: the short name origin/main is read by git after refs/origin/main,
  # refs/tags/origin/main and refs/heads/origin/main, which any session can
  # create, and this base names the resolve.sh that is then run as the judge.
  GBASE=""
  for GREF in refs/remotes/origin/main refs/heads/main; do
    GSHA="$(git show-ref --verify -s -- "$GREF" 2>/dev/null </dev/null)" || continue
    git rev-parse --verify --quiet "$GSHA^{commit}" >/dev/null 2>&1 </dev/null && { GBASE="$GREF"; break; }
  done
  GVER=""
  [ -n "$GBASE" ] && GVER="$(git show "$GBASE:engine/.claude-plugin/plugin.json" 2>/dev/null \
    | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
  PLUG=""
  GLIB=""
  # Under $TMPDIR by a template, as the suite log below is: a bare mktemp on
  # macOS ignores TMPDIR.
  GTMPD="${TMPDIR:-/tmp}"; GTMPD="${GTMPD%/}"
  if [ -z "$GBASE" ]; then
    GWHY="cannot tell which engine main accepted: no main here"
    INSTALL_DRIFT=1
  elif ! GLIB="$(mktemp -d "$GTMPD/felix-gate-judge.XXXXXX" 2>/dev/null)" || [ -z "$GLIB" ]; then
    GWHY="could not make a directory to read main's resolve.sh into"
    INSTALL_DRIFT=1
  elif ! git show "$GBASE:engine/harness/lib/resolve.sh" > "$GLIB/resolve.sh" 2>/dev/null; then
    GWHY="main's engine at $GBASE has no lib/resolve.sh, so nothing there defines felix_accepted_deploy_diff"
    INSTALL_DRIFT=1
  else
    # The verdict, from main's own reader. rc 0 prints the entry; rc 1 prints
    # every differing path, or one line naming the version nothing is
    # installed at; rc 2 prints why it could not examine. Exit 3 is this
    # block's own: the function is not defined at that base.
    GOUT="$( . "$GLIB/resolve.sh" >/dev/null 2>&1
             command -v felix_accepted_deploy_diff >/dev/null 2>&1 || exit 3
             felix_accepted_deploy_diff "$ROOT" 2>/dev/null )"; GRC=$?
    case "$GRC" in
      0) PLUG="$GOUT" ;;
      3) GWHY="main's engine at $GBASE cannot answer: its resolve.sh defines no felix_accepted_deploy_diff"
         INSTALL_DRIFT=1 ;;
      2) GWHY="$GOUT"; INSTALL_DRIFT=1 ;;
      *) GDRIFT="$(printf '%s\n' "$GOUT" | grep .)"
         INSTALL_DRIFT=1 ;;
    esac
  fi
  [ -n "$GLIB" ] && rm -rf "$GLIB"
  # A bump felix install wrote here has not reached main until it is merged,
  # and until then main still names the old entry. Said, because otherwise the
  # failure reads as a deploy that did not happen.
  GHERE="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' engine/.claude-plugin/plugin.json 2>/dev/null | head -1)"
  if [ "$INSTALL_DRIFT" -eq 0 ]; then
    pass installed
    printf '                     main declares %s, and %s is its engine\n' "$GVER" "$PLUG"
    GLIVE="$(claude plugin list --json 2>/dev/null \
             | sed -n '/"felix@felix"/,/}/p' \
             | sed -n 's/.*"installPath"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
    if [ -n "$GLIVE" ] && [ "${GLIVE%/}" != "$PLUG" ]; then
      printf '                     the live engine is %s, not the one main declares\n' "${GLIVE##*/}"
    fi
  else
    MROOT=""
    if [ -r "$HOME/.claude/plugins/known_marketplaces.json" ]; then
      MROOT="$(sed -n '/"felix"[[:space:]]*:[[:space:]]*{/,/^  }/p' \
                 "$HOME/.claude/plugins/known_marketplaces.json" 2>/dev/null \
               | sed -n 's/.*"installLocation"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
    fi
    if [ -n "$MROOT" ] && [ "$MROOT" != "$ROOT" ]; then
      # `structural` is load-bearing, not decoration: the engine subtracts
      # failures marked that way from what it writes to mistakes.log, and it
      # keys on that exact word (#3, #86). From a checkout the marketplace does
      # not serve, main's engine being undeployed is real and is not this
      # checkout's to fix — only the served checkout can deploy — so it is
      # marked, and every worktree gate does not record a mistake nobody here
      # made. No apostrophe in this format: the suite lifts it out of this file.
      printf '  %-18s FAIL (structural: the engine main declares is not the one deployed, and only the checkout the marketplace serves can deploy it — the marketplace serves %s)\n' installed "$MROOT"
      FAILED="$FAILED installed"
      [ -n "$GWHY" ] && printf '    %s\n' "$GWHY"
      [ -n "$GDRIFT" ] && printf '%s\n' "$GDRIFT" | head -5 | sed 's/^/    /'
      printf '    run felix install on main in %s\n' "$MROOT"
    else
      fail installed
      [ -n "$GWHY" ] && printf '    %s\n' "$GWHY"
      [ -n "$GDRIFT" ] && printf '%s\n' "$GDRIFT" | head -5 | sed 's/^/    /'
      [ -n "$GHERE" ] && [ "$GHERE" != "$GVER" ] \
        && printf '    this checkout declares %s and main declares %s: the bump reaches main by merging it\n' "$GHERE" "${GVER:-nothing}"
      printf '    reinstall with: felix install (on main)\n'
      # Deployable drift, and the remedy is here. Everything after this would be
      # spent verifying a tree whose accepted engine is not the one deployed,
      # and the suite alone is minutes. Not a loosening: the gate still fails,
      # for the same reason; it stops paying for checks whose answer is about to
      # be thrown away. The structural branch above does not stop, because its
      # remedy is somewhere else and its other results are all it can give.
      SKIP_REST=1
    fi
  fi
else
  printf '  %-18s skipped (no plugin installed here)\n' installed
fi

# ------------------------------------------------------------- tests ---------
# A log of this run's own, never a path another gate can open. It was one fixed
# path under /tmp for every gate on the machine, opened with O_TRUNC and written
# at each gate's own offset, so concurrent gates interleaved in it. Measured
# 2026-09-21: a gate on one worktree printed "tests ok, 2645 passed" while its own
# suite had passed 2586, because tail read the other session's summary. The
# verdict was sound, being this suite's exit status; the count under it, and the
# FAIL excerpt of a red run, were whichever gate wrote last. Deleted on a pass,
# where nothing points at it; kept on a failure, where the path is printed.
GTLOG_DIR="${TMPDIR:-/tmp}"; GTLOG_DIR="${GTLOG_DIR%/}"; GTLOG=""
# The suite runs as many parts at once as the machine has performance cores (contract D1, as R51 and R52 replace it):
# sysctl's hw.perflevel0.logicalcpu when it answers digits only and at least 1; else, as before, hw.ncpu, then
# getconf, then 1; held to 1..64; never on GitHub's runner, which drops an inherited one (R10).
GTJOBS=""
if [ "${GITHUB_ACTIONS:-}" != true ]; then
  GTJOBS="$(sysctl -n hw.perflevel0.logicalcpu 2>/dev/null)"
  case "$GTJOBS" in ''|*[!0123456789]*) GTJOBS="" ;; esac
  GTJOBS="${GTJOBS#"${GTJOBS%%[!0]*}"}"
  if [ -z "$GTJOBS" ]; then
    GTJOBS="$(sysctl -n hw.ncpu 2>/dev/null)"
    case "$GTJOBS" in ''|*[!0123456789]*) GTJOBS="$(getconf _NPROCESSORS_ONLN 2>/dev/null)" ;; esac
    case "$GTJOBS" in ''|*[!0123456789]*) GTJOBS=1 ;; esac
    GTJOBS="${GTJOBS#"${GTJOBS%%[!0]*}"}"
  fi
  case "$GTJOBS" in '') GTJOBS=1 ;; ?|??) ;; *) GTJOBS=64 ;; esac
  [ "$GTJOBS" -le 64 ] || GTJOBS=64
fi
if [ "${SKIP_REST:-0}" -eq 1 ]; then
  printf '  %-18s skipped (the deployed engine is not this tree)\n' tests
elif [ "${1:-}" = "--quick" ]; then
  printf '  %-18s skipped (--quick)\n' tests
elif ! GTLOG="$(mktemp "$GTLOG_DIR/felix-gate-tests.XXXXXX" 2>/dev/null)" || [ -z "$GTLOG" ]; then
  fail tests
  printf '    could not make a log file for the suite under %s\n' "$GTLOG_DIR"
elif env -u FELIX_TEST_JOBS ${GTJOBS:+FELIX_TEST_JOBS=$GTJOBS} ./engine/harness/tests/run --reuse >"$GTLOG" 2>&1; then
  # --reuse answers from the receipt a passed run left for this exact tree
  # (tests/receipt.sh), and runs the suite itself when there is none, so a pass
  # here is a pass either way; what differs is that it says which. A reused run
  # begins "reused " and is reported as `reused`, with the line that says when it
  # ended and what it counted, and the receipt this gate writes carries
  # `tests:reused` for it, so felix merge, the monitor and qualify can tell the
  # two apart. A run that began "not reused: <reason>" ran the suite, and is `ok`,
  # with that reason under the summary, so a receipt that did not hold says why.
  # The log is searched for that line and not read from its first line: the log
  # holds stderr as well, and one line from anything ahead of the answer (a
  # misconfigured knob, a git warning, BASH_ENV) would have made a reused suite
  # read as `ok`, and the merge would then ask nothing of GitHub for it. It is
  # searched for anywhere on a line and not only at the start of one, because
  # such a fragment need not end in a newline: `warning: x` written with none
  # sits in front of the sentence on the same line (review finding C9-R4). The
  # summary a reused run ends on, which says `(reused)`, counts as the same
  # sign. A log that shows reuse anywhere is `reused`, never `ok`; the other way
  # about is only ever a stricter merge.
  GTREUSED="$(grep -m1 -E 'reused the suite run that ended .* on this tree \(.*\), not run again' "$GTLOG")"
  GTLAST="$(tail -1 "$GTLOG")"
  [ -n "$GTREUSED" ] || case "$GTLAST" in *' (reused)') GTREUSED="$GTLAST" ;; esac
  if [ -n "$GTREUSED" ]; then
    printf '  %-18s reused\n' tests
    printf '                     %s\n' "$GTREUSED"
    [ "$GTLAST" = "$GTREUSED" ] || printf '                     %s\n' "$GTLAST"
  else
    pass tests
    printf '                     %s\n' "$GTLAST"
    GTWHY="$(grep -m1 -o 'not reused: .*' "$GTLOG")"
    [ -z "$GTWHY" ] || [ "$GTWHY" = "$GTLAST" ] || printf '                     %s\n' "$GTWHY"
  fi
  rm -f "$GTLOG"
else
  GTRC=$?
  fail tests
  # A refusal (exit 2) has no FAIL line: its one line is the log's last.
  [ "$GTRC" -ne 2 ] || printf '    %s\n' "$(tail -1 "$GTLOG")"
  # The evidence, not only the verdict (#86 again, one check over). bad() puts
  # its detail on the line AFTER `FAIL`, and this printed the FAIL line alone —
  # so a failure that only reproduces on the runner arrived as a name with
  # nothing under it, and the one line saying WHICH word leaked was in a log
  # file nobody can read from here.
  grep -A2 '^  FAIL' "$GTLOG" | head -30 | sed 's/^/  /'
  printf '                     full log: %s\n' "$GTLOG"
fi

# ------------------------------------------------------------- secret --------
if [ -x engine/harness/bin/secret-scan ]; then
  if OUT="$(engine/harness/bin/secret-scan 2>&1)"; then
    pass secret
  else
    fail secret; printf '%s\n' "$OUT" | head -8 | sed 's/^/    /'
  fi
else
  # Announced, not silent. This branch did not exist: a missing or non-executable
  # scanner printed NOTHING, so the gate's only credential check could vanish
  # and the report looked complete. The other skippable checks say so (#77).
  printf '  %-18s skipped (no secret-scan here)\n' secret
fi

# ------------------------------------------------------------- independence --
# The engine must name no specific project: constitution invariant 1, the
# property that makes Felix portable and the one most easily lost to a
# well-meant comment. The check lives in engine/harness/bin so that felix
# qualify can ask whether it fails when the property is broken, without running
# this whole gate; its comments carry the history. What stays here has the
# secret check's shape: run it, and announce rather than go silent when it is
# missing.
# The ecosystem check below shares two things with this one: the four paths it
# greps, and the blindness verdict — a path nobody could search fails both, on
# the same evidence. Both are read off the scanner rather than kept as a second
# copy here, and both default to blind when the scanner is missing, so an
# absent scanner cannot turn either check green by having nothing to run.
INDEP_PATHS=""; INDEP_BLIND=" engine/harness/bin/independence-scan"
if [ -x engine/harness/bin/independence-scan ]; then
  INDEP_PATHS="$(engine/harness/bin/independence-scan --paths 2>/dev/null)"
  if OUT="$(engine/harness/bin/independence-scan 2>&1)"; then
    pass independence; INDEP_BLIND=""
  else
    fail independence; printf '%s\n' "$OUT" | head -8 | sed 's/^/    /'
    INDEP_BLIND="$(printf '%s\n' "$OUT" | sed -n 's/^independence-scan: cannot search://p' | head -1)"
  fi
else
  # Announced, not silent — the rule the secret check already holds (#77). An
  # absent scanner used to print nothing here, and a gate's only portability
  # check could vanish while the report looked complete.
  printf '  %-18s skipped (no independence-scan here)\n' independence
fi

# ------------------------------------------------------------- ecosystem -----
# Invariant 1, the half the name check cannot see.
#
# The block above proves the engine names no governed PROJECT. A detector under
# engine/harness hard-coded to FastAPI route decorators and an Anthropic client
# construction site contains no project name, passes it, and encodes exactly one
# project's shape into an engine whose whole claim is that it holds none. That
# is a design that was drafted for Felix, and it would have shipped. Same
# invariant, same sentence, one level up from the name.
#
# The words are enumerated off reality the way the names are, and reality here
# is the engine's own capability probe: every alternation token inside a
# _felix_dep_grep call in lib/detect.sh. Teaching the probe a new framework arms
# this check for it in the same commit (#85); a hand-kept list stops matching
# what exists.
#
# A naive ban would break the build and deserve to: lib/detect.sh legitimately
# greps manifests for fastapi, stripe, sentry and supabase, since a probe naming
# many ecosystems symmetrically is how it stays neutral. So the boundary is
# declared per file, with a written reason, in engine/harness/ecosystem.tsv, in
# the style of deny.tsv and the escape tables. A probe may name ecosystems; a
# detector that has already decided which project it is for may not.
#
# Word-boundaried, and that is measured: a substring search flags `cohere` inside
# "coherent", `vite` inside "invite" and `express` inside "expressed" in the
# engine's own prose, so the naive version fails open by being switched off after
# the third false positive.
ECO_TABLE=engine/harness/ecosystem.tsv
ECO_PROBE=engine/harness/lib/detect.sh

# Continuation lines joined first. The model-SDK probe sits on its own line, so
# a line-by-line read drops anthropic, openai and the rest of that vocabulary -
# which is half the case this check exists for, silently.
_eco_probe_words() {
  sed -e :a -e '/\\$/N; s/\\\n//; ta' "$ECO_PROBE" 2>/dev/null \
    | grep -oE '_felix_dep_grep "\$root" +"[^"]*(\\"[^"]*)*"' \
    | sed -E 's/.*_felix_dep_grep "\$root" +"//; s/"$//' \
    | sed 's/\\"?//g; s/\\"//g' | tr '|' '\n' \
    | sed 's/^ *//; s/ *$//' | grep -v '^$' | LC_ALL=C sort -u
}
# A row with no reason grants nothing, which fails in the safe direction for two
# of the three kinds: an `allow` with no reason stops permitting, so the file
# leaks and this goes red, and a `mute` with no reason stops muting, so the word
# comes back. Only a reasonless `word` row narrows, and the suite fails on any
# row missing a reason.
_eco_rows() {
  local want="$1" kind file token reason
  [ -f "$ECO_TABLE" ] || return 0
  while IFS=$'\t' read -r kind file token reason; do
    case "$kind" in ''|'#'*) continue ;; esac
    [ "$kind" = "$want" ] || continue
    [ -n "${token:-}" ] && [ -n "${reason:-}" ] || continue
    printf '%s\t%s\n' "$file" "$token"
  done < "$ECO_TABLE"
}

ECO_ALLOW="$(_eco_rows allow)"
ECO_WORDS="$( { _eco_probe_words; _eco_rows word | cut -f2 | tr '|' '\n'; } \
              | sed 's/^ *//; s/ *$//' | grep -v '^$' | LC_ALL=C sort -u \
              | grep -vxF -f <(_eco_rows mute | cut -f2 | tr '|' '\n' | grep -v '^$') )"

# Refusing to answer beats answering from nothing, which the independence block
# above paid for twice. Three reads of the world can come back empty without
# erroring: the probe refactored past the extractor, the table gone missing, and
# a table with no allow rows (which would make the whole engine leak at once).
# The first two narrow silently, and a vocabulary of nothing passes everything.
ECO_BLIND=""
[ -f "$ECO_PROBE" ]         || ECO_BLIND="$ECO_BLIND no-probe($ECO_PROBE)"
[ -f "$ECO_TABLE" ]         || ECO_BLIND="$ECO_BLIND no-table($ECO_TABLE)"
[ -n "$(_eco_probe_words)" ] || ECO_BLIND="$ECO_BLIND probe-yielded-no-words"
[ -n "$ECO_WORDS" ]          || ECO_BLIND="$ECO_BLIND empty-vocabulary"

# Does a row permit this file to say this word? `*` is the probe's row.
_eco_allowed() {
  local f="$1" w="$2" rf rt
  while IFS=$'\t' read -r rf rt; do
    [ "$rf" = "$f" ] || continue
    [ "$rt" = '*' ] && return 0
    case "|$rt|" in *"|$w|"*) return 0 ;; esac
  done <<EOF
$ECO_ALLOW
EOF
  return 1
}

ECO_LEAK=""
if [ -z "$ECO_BLIND" ] && [ -z "$INDEP_BLIND" ]; then
  while IFS= read -r w; do
    [ -n "$w" ] || continue
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      rel="${f#engine/harness/}"
      _eco_allowed "$rel" "$w" || ECO_LEAK="$ECO_LEAK
$rel names $w"
    done <<EOF
$(git grep -lwniE -- "$w" $INDEP_PATHS 2>/dev/null)
EOF
  done <<EOF
$ECO_WORDS
EOF
fi

# A row that no longer matches is a claim about a surface that is gone. Reported
# beside the verdict, not failing: pruning it is somebody's judgement, and a
# check that fails on stale prose gets deleted. Reported at all because a surface
# that reports gaps but not its own is an instance wearing a system's clothes (#125).
ECO_STALE=""
if [ -z "$ECO_BLIND" ]; then
  while IFS=$'\t' read -r rf rt; do
    [ -n "${rt:-}" ] || continue
    [ "$rt" = '*' ] && continue
    if [ ! -e "engine/harness/$rf" ]; then
      ECO_STALE="$ECO_STALE $rf(gone)"
    elif ! git grep -lwqiE -- "$rt" -- "engine/harness/$rf" >/dev/null 2>&1; then
      ECO_STALE="$ECO_STALE $rf:$rt"
    fi
  done <<EOF
$ECO_ALLOW
EOF
fi

if [ -n "$ECO_BLIND" ]; then
  fail ecosystem
  printf '    cannot answer:%s\n' "$ECO_BLIND"
  printf '    the words are read off %s and the reasons off %s;\n' "$ECO_PROBE" "$ECO_TABLE"
  printf '    with either missing this would pass by having nothing to check.\n'
elif [ -n "$INDEP_BLIND" ]; then
  fail ecosystem
  printf '    cannot search:%s\n' "$INDEP_BLIND"
  printf '    same blindness as independence above, and the same verdict.\n'
elif [ -n "$ECO_LEAK" ]; then
  fail ecosystem
  printf '    the engine hard-codes an ecosystem with no declared reason:\n'
  printf '%s\n' "$ECO_LEAK" | grep -v '^$' | head -10 | sed 's/^/      /'
  printf '    a capability probe may name one. A detector that encodes one\n'
  printf '    stack has already chosen its project. Declare it in %s\n' "$ECO_TABLE"
  printf '    with the reason, or stop naming it.\n'
else
  pass ecosystem
  [ -n "$ECO_STALE" ] && printf '                     stale rows, no longer matching:%s\n' "$ECO_STALE"
fi

# ------------------------------------------------------------- memory --------
# Two opposite properties, and until 2026-08-14 they were one.
#
# Doctrine must survive the machine, which is what this check was built for. A
# gitignore rule that swallows maintenance.log is invisible: every command works,
# every test passes, and nothing is kept. It is checked against the path, not
# against files that happen to exist, which are absent in a worktree.
#
# Memory must not survive *into this repository*. It holds verbatim founder
# prompts and whatever a governed project's work happens to be about, which
# includes material belonging to somebody who never agreed to be published — so
# a repository storing every governed project's memory can never be public. The
# check that once demanded memory be tracked now demands the reverse. That
# reversal is the point and not a relaxation: this is the only thing that
# notices the old layout creeping back one project at a time, which is exactly
# how it would come back, since `felix adopt` is what creates the directory.
#
# The check is a command, engine/harness/bin/memory-scan, so felix qualify can
# ask whether it fails when the thing it protects is broken. Asked blind, it
# found two things the inline form could not see (a tracked file `git
# check-ignore` never reports, and memory that is not a path); both are in the
# scanner's own comment. Announced when absent, never silent (#77).
if [ -x engine/harness/bin/memory-scan ]; then
  if OUT="$(engine/harness/bin/memory-scan 2>&1)"; then
    pass memory
  else
    fail memory; printf '%s\n' "$OUT" | head -8 | sed 's/^/    /'
  fi
else
  printf '  %-18s skipped (no memory-scan here)\n' memory
fi

# ------------------------------------------------------------- cloud ---------
# A Claude Code cloud session loads no plugin and reads nothing from ~/.claude,
# so the Felix plugin's hooks reach it only as this repository's own
# .claude/settings.json, which binds the same engine hooks behind a
# CLAUDE_CODE_REMOTE guard, and the toolbox reaches it only as what
# .claude/cloud/provision copies in. Each of these goes wrong in silence:
#   - the plugin binds a hook, or binds it under an event, that the settings do
#     not, and the cloud never runs it;
#   - a settings command without the guard runs locally beside the plugin's
#     hook, and Felix fires twice in every local session;
#   - a stack.tsv plugin or skill with no entry in .claude/cloud/toolbox.json never
#     reaches the cloud, and nobody decided that it should not.
# A binding is one hook object naming harness/hooks/<name>: its event, its
# group's matcher, the hook, async and timeout, each compared as written with
# absence a value of its own, because the matcher decides which tools the hook
# sees. Each file is read on its own and by structure, not by layout: its
# braces and brackets say which event and group a hook sits in, so a hook
# object on one line, or indented otherwise, is read all the same. A file is
# unreadable, so a failure and never an agreement, when a matcher, async or
# timeout line is off the layout both files share (matcher at eight spaces,
# async and timeout at twelve), when it is not one balanced object in the
# plugin's shape, or when the commands naming harness/hooks/ it holds are not
# the bindings read from it. A settings binding the plugin lacks (provision) is
# allowed. The reader decodes no escape, so a backslash that does not begin \"
# makes a file unreadable (B08R3-1), and so does a key repeated in one object,
# whose value is a parser's choice (B08R3-3). Claude Code reads no hook from
# a settings file it cannot parse or that a key beside hooks turns off, and
# drops a hook whose values it rejects. So (B08R3V, audit b08 round 3) a file
# over 65536 bytes is not read, each file must be one JSON text (RFC 8259),
# and settings.json may hold no top-level key but hooks, each group no key but
# a string matcher and its hooks, and each hook no key but type "command", a
# string command, shell "bash", async true or false, a timeout in digits and a
# string statusMessage. A NUL byte, which BWK awk and gawk read apart, is found
# before awk (B08R3W-1). A file's clause names its first fault in that order
# (size, NUL, escape, not JSON, repeat, top-level key, schema), and over any of
# them nothing is compared (B08R3-4, B08R3V-6). Claude Code also reads
# .claude/settings.local.json; one in the index fails first, unread (B08R3W-2),
# whether or not settings.json is there (B08R3X-2). git resolves no path through
# a symlink or a gitlink at .claude, so .claude must be a real directory on disk
# and in the index, or nothing in it is read (B08R3X-1). The guard counts are
# not taken from a settings file the size or NUL test refused (B08R3X-3).
# The cloud gets only what git holds, byte for byte, on a file system that folds
# no case, so the check reads git's index, never the disk (B08R3Y-1). One pass
# over it (-z, a newline in a path read as \001) finds a file under .claude only
# at exactly its path, fails an entry there that is not a regular file or whose
# name differs only by case from one the cloud reads, and settings.json and the
# toolbox are read from their blobs. With no pairs, a size or NUL fault is still
# said (B08R3Y-4); the guard counts count commands, not lines (B08R3Y-5).
_cloud_fault() {   # file: 1 when over 65536 bytes (B08R3V-2), 2 when it holds a NUL byte (B08R3W-1)
  if [ "$(($(wc -c < "$1")))" -gt 65536 ]; then echo 1; elif ! LC_ALL=C tr -d '\000' < "$1" | cmp -s - "$1"; then echo 2; fi
}
_cloud_check() {   # file: .claude/settings.json as git's index holds it (B08R3Y-1); hooks.json is read from disk
  local s="$1" x out z="" y
  set --
  for x in engine/hooks/hooks.json "$s"; do
    [ -f "$x" ] && [ -r "$x" ] || { case "$(_cloud_fault "$s")" in 1) y=" (larger than 65536 bytes)" ;; 2) y=" (a NUL byte)" ;; esac
      echo " unreadable: no event-to-hook pairs read from one of the two files${y:+; unreadable: .claude/settings.json$y;}"; return 0; }   # B08R3Y-4
    y="$(_cloud_fault "$x")"; z="$z${y:-0}"
    if [ -n "$y" ]; then set -- "$@" /dev/null; else set -- "$@" "$x"; fi
  done
  out="$(LC_ALL=C awk -v Z="$z" '
    BEGIN {
      FN[1] = "engine/hooks/hooks.json"; FN[2] = ".claude/settings.json"; ESC = 3; NJ = 4; REP = 5; TL = 6; SCH = 7
      split("larger than 65536 bytes|a NUL byte|an escape other than \\\"|not JSON|a key repeated in one object|a top-level key other than hooks|a key or value outside the hook schema", WHY, "|")
      for (i = 1; i <= 2; i++) W[i] = substr(Z, i, 1) + 0   # Z: _cloud_fault of each file, 0 for none
      for (i = 1; i < 32; i++) CT = CT sprintf("%c", i)
      split("type command shell async timeout statusMessage", HK0, " "); for (i in HK0) HK[HK0[i]] = 1
      NUM = "^-?(0|[123456789][0123456789]*)([.][0123456789]+)?([eE][-+]?[0123456789]+)?$"
    }
    function ft(v) { if (!W[f] || v < W[f]) W[f] = v }   # a fault of rank v; the lowest rank names the file
    function fin() { if (f && (d != 0 || !done || cc[f] != nb[f])) bad[f] = 1; if (f && ex != "E") ft(NJ) }
    function op(k,   q) {
      if (d == 0 && (k != "{" || done)) bad[f] = 1
      q = (d > 0 && K[d] == "{") ? KY[d] : ""
      d++; K[d] = k; N[d] = q; KY[d] = ""; O[d] = ++no; ex = (k == "{") ? "K" : "V"
      if (d == 4 && k == "{") { m = "-"; g0 = n + 1 }
      if (d == 6 && k == "{") { h = ""; a = "-"; t = "-" }
    }
    function cl(k,   i) {
      if (d == 0) { bad[f] = 1; return }
      if (K[d] != (k == "}" ? "{" : "[")) bad[f] = 1
      if (f == 2 && K[d] == "{" && ((d == 1 || d == 4) && !((O[d], "hooks") in KS) || d == 6 && !(((O[d], "type") in KS) && ((O[d], "command") in KS)))) ft(SCH)
      if (d == 6 && K[d] == "{" && h != "") { n++; E[n] = N[3]; H[n] = h; A[n] = a; T[n] = t; F[n] = f; nb[f]++; h = "" }
      if (d == 4 && K[d] == "{") for (i = g0; i <= n; i++) M[i] = m
      d--; ex = d ? "e" : "E"
      if (d == 0) done = 1
    }
    function key(s) {   # B08R3-3 a repeat; B08R3V-4 a top-level key but hooks; B08R3V-5 (c), (d) a group or hook key outside the schema
      if ((O[d], s) in KS) ft(REP)
      KS[O[d], s] = 1; KY[d] = s; ex = ":"
      if (f == 2 && d == 1 && s != "hooks") ft(TL)
      else if (f == 2 && (d == 4 && s != "matcher" && s != "hooks" || d == 6 && !(s in HK))) ft(SCH)
    }
    function sv(k, s,   y) {   # B08R3V-5: in settings, a value of type k ({, [, s a string, l a literal) where the schema allows it
      if (f != 2) return
      y = KY[d]
      if (d == 0 || d == 3 || d == 5) { if (k != "{") ft(SCH) }
      else if (d == 1) { if (y == "hooks" && k != "{") ft(SCH) }
      else if (d == 2) { if (k != "[") ft(SCH) }
      else if (d == 4) { if (k != (y == "matcher" ? "s" : "[")) ft(SCH) }
      else if (d != 6 || !(k == "s" && (y == "command" || y == "statusMessage" || y == "type" && s == "command" || y == "shell" && s == "bash") ||
        k == "l" && (y == "async" && (s == "true" || s == "false") || y == "timeout" && s ~ /^[0123456789]+$/))) ft(SCH)
    }
    function val(s, lit,   p, r) {
      ex = d ? "e" : "E"
      if (d == 0) { bad[f] = 1; return }
      if (K[d] == "[") return
      if (!lit && d == 4 && KY[d] == "matcher") m = s
      else if (lit && d == 6 && KY[d] == "async") a = s
      else if (lit && d == 6 && KY[d] == "timeout") t = s
      else if (!lit && KY[d] == "command" && (p = index(s, "harness/hooks/"))) {
        cc[f]++; r = substr(s, p + 14)
        if (!match(r, /^[a-z-]+/) || index(r, "harness/hooks/")) bad[f] = 1
        else if (d == 6 && N[2] == "hooks" && N[5] == "hooks" && K[1] K[2] K[3] K[4] K[5] K[6] == "{{[{[{") h = substr(r, 1, RLENGTH)
      }
    }
    FILENAME != cur { fin(); cur = FILENAME; f = (FILENAME == FN[1]) ? 1 : 2; seen[f] = 1; d = 0; done = 0; ex = "v" }
    index($0, "\"matcher\"") && $0 !~ /^        "matcher": "[^"\\]*",?$/ { bad[f] = 1 }
    index($0, "\"async\"") && $0 !~ /^            "async": (true|false),?$/ { bad[f] = 1 }
    index($0, "\"timeout\"") && $0 !~ /^            "timeout": [0123456789]+,?$/ { bad[f] = 1 }
    {
      L = length($0)
      for (i = 1; i <= L; i++) {
        ch = substr($0, i, 1)
        if (ch == " " || ch == "\t" || ch == "\r") continue
        # B08R3V-3, RFC 8259: ex is what may come next (v a value, V a value or ], k a key, K a key or },
        # : a colon, e a comma or the close, E nothing); a token anywhere else is not JSON.
        if (ch == "\"") {   # B08R3-1 an escape but \"; B08R3V-3 a raw control byte
          for (j = i + 1; j <= L; j++) { x = substr($0, j, 1); if (x == "\\" && substr($0, ++j, 1) != "\"") ft(ESC); else if (x == "\"") break; else if (index(CT, x)) ft(NJ) }
          if (j > L) { bad[f] = 1; ft(NJ); break }
          s = substr($0, i + 1, j - i - 1); i = j
          if (ex == "k" || ex == "K") key(s)
          else if (ex == "v" || ex == "V") { sv("s", s); val(s, 0) }
          else ft(NJ)
        } else if (ch == "{" || ch == "[") { if (ex != "v" && ex != "V") ft(NJ); sv(ch, ""); op(ch) }
        else if (ch == "}" || ch == "]") { if (K[d] != (ch == "}" ? "{" : "[") || ex != "e" && ex != (ch == "}" ? "K" : "V")) ft(NJ); cl(ch) }
        else if (ch == ":") { if (ex == ":") ex = "v"; else ft(NJ) }
        else if (ch == ",") { if (ex == "e") ex = (K[d] == "{") ? "k" : "v"; else ft(NJ) }
        else {
          for (j = i; j <= L; j++) if (index(" \t\r,:{}[]\"", substr($0, j, 1))) break
          w = substr($0, i, j - i); i = j - 1
          if (index(w, "\\")) ft(ESC)   # B08R3-1: a backslash outside any string
          if ((ex == "v" || ex == "V") && (w == "true" || w == "false" || w == "null" || w ~ NUM)) { sv("l", w); val(w, 1) }
          else ft(NJ)
        }
      }
    }
    END {
      fin()
      for (f = 1; f <= 2; f++) if (!seen[f]) ft(NJ)   # an empty file holds no JSON text
      for (i = 1; i <= n; i++) { R[i] = E[i] "\t" M[i] "\t" H[i] "\t" A[i] "\t" T[i]; c[F[i]]++ }
      # B08R3-4, B08R3V-6: one clause per file, its first fault by rank; any of them prints these alone.
      for (i = 1; i <= 2; i++) { q = W[i] ? " (" WHY[W[i]] ")" : ""; if (q != "") r3 = 1; if (q != "" || bad[i]) u = u " unreadable: " FN[i] q ";" }
      if (r3) { print u; exit }
      if (!c[1] || !c[2]) { print " unreadable: no event-to-hook pairs read from one of the two files"; exit }
      if (u != "") { print u; exit }
      for (i = 1; i <= n; i++) if (F[i] == 2) { full[R[i]] = 1; k = E[i] "/" H[i]; if (!(k in first)) first[k] = i }
      for (i = 1; i <= n; i++) if (F[i] == 1 && !(R[i] in full)) {
        k = E[i] "/" H[i]
        if (!(k in first)) { miss = miss k " "; continue }
        j = first[k]; df = ""
        if (M[i] != M[j]) df = "matcher"
        if (A[i] != A[j]) df = df (df == "" ? "" : ", ") "async"
        if (T[i] != T[j]) df = df (df == "" ? "" : ", ") "timeout"
        o = o " bound differently for the cloud: " k " (" df ");"
      }
      if (miss != "") o = " not bound for the cloud: " miss ";" o
      print o
    }' "$@" 2>/dev/null)" \
    || { echo " unreadable: the cloud check could not run over the two files;"; return 0; }
  printf '%s' "$out"
}
CLOUD_BAD=" unreadable: .claude (not a directory in the repository, so its settings files cannot be judged);"; CLOUD_IX=D
if [ ! -L .claude ] && { [ ! -e .claude ] || [ -d .claude ]; }; then   # B08R3X-1 on disk first; then the index, in one pass
  CLOUD_IX="$(LC_ALL=C git --no-pager ls-files -s -z 2>/dev/null | LC_ALL=C tr '\n\000' '\001\n' | LC_ALL=C awk '
    { i = index($0, "\t"); split(substr($0, 1, i - 1), m, " "); p = substr($0, i + 1); l = tolower(p); r = (m[1] == "100644" || m[1] == "100755") }
    { if (p == ".claude") d = 1; else if (r && p == ".claude/settings.json") s = 1 }
    p == ".claude/settings.local.json" { x = " unreadable: " p " (a local settings file in the repository, which Claude Code reads beside settings.json);" }
    !r && substr(p, 1, 8) == ".claude/" { b = b " unreadable: " p " (not a regular file in the repository, so the cloud would not get its content);" }
    index(l "/", ".claude/") == 1 && (substr(p, 1, 8) != substr(l, 1, 8) || p != l && l ~ "^[.]claude/(settings([.]local)?|cloud/toolbox)[.]json$") {
      b = b " unreadable: " p " (its name differs only by case from one the cloud reads, and the cloud\047s file system does not fold case);" }
    END { print (d ? "D" : (s ? "S" : "-") x b) }')" \
    || CLOUD_IX="- unreadable: .claude/settings.local.json (git could not say whether it is in the repository);"
  [ "$CLOUD_IX" = D ] || CLOUD_BAD="${CLOUD_IX#?}"
fi
if [ "$CLOUD_IX" != "${CLOUD_IX#S}" ]; then
  if CLOUD_F="$(mktemp "$GTLOG_DIR/felix-gate-cloud.XXXXXX" 2>/dev/null)" && git cat-file blob :.claude/settings.json > "$CLOUD_F" 2>/dev/null; then
    CLOUD_BAD="$CLOUD_BAD$(_cloud_check "$CLOUD_F")"
    if [ -z "$(_cloud_fault "$CLOUD_F" 2>/dev/null)" ]; then   # B08R3X-3; each command counts once, wherever it sits (B08R3Y-5)
      N_CMD="$(($(LC_ALL=C grep -aoF '"command":' "$CLOUD_F" | wc -l)))"
      N_GUARD="$(($(LC_ALL=C grep -aoF '"command": "[ \"$CLAUDE_CODE_REMOTE\" = true ] || exit 0; ' "$CLOUD_F" | wc -l)))"
      [ "$N_CMD" = "$N_GUARD" ] || CLOUD_BAD="$CLOUD_BAD $((N_CMD - N_GUARD)) command(s) without the CLAUDE_CODE_REMOTE guard;"
    fi
  else CLOUD_BAD="$CLOUD_BAD unreadable: .claude/settings.json (not read from git's index into a file under $GTLOG_DIR);"; fi
  [ -z "$CLOUD_F" ] || rm -f "$CLOUD_F"
  # Names read with sed, not jq: the gate runs on bash and git alone
  # (constitution invariant 2), and a reformatted file reads as no names, so
  # every stack row fails rather than passing.
  TOOLBOX="$(git cat-file blob :.claude/cloud/toolbox.json 2>/dev/null | sed -n 's/^      "name": "\([^"]*\)",$/\1/p')"
  for n in $(grep -vE '^[[:space:]]*(#|$)' projects/felix/stack.tsv \
             | awk -F'\t' '$1 == "plugin" || $1 == "skill" { sub(/@.*/, "", $2); print $2 }'); do
    printf '%s\n' "$TOOLBOX" | grep -qxF "$n" || CLOUD_BAD="$CLOUD_BAD $n has no entry in .claude/cloud/toolbox.json;"
  done
fi
if [ -n "$CLOUD_BAD" ]; then
  fail cloud; printf '    %s\n' "$CLOUD_BAD"
elif [ "$CLOUD_IX" = S ]; then
  pass cloud
else
  printf '  %-18s skipped (no .claude/settings.json in this tree)\n' cloud
fi

echo
if [ -z "$FAILED" ]; then echo "gate: pass"; exit 0; fi
echo "gate: FAIL ($(echo "$FAILED" | tr -s ' ' | sed 's/^ //'))"
exit 1
