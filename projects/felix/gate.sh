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
# said (B08R3Y-4). What git holds is what a checkout writes only when no
# attribute rewrites it, so working-tree-encoding, filter or ident on a file
# under .claude, read from the index or this machine's own attributes, is a
# fault (B08R3Z-1). The guard counts are the parser's: one per hook object's
# command value, however it is laid out (B08R3Y-5, B08R3Z-2). The Mac also
# folds some letters above ASCII (U+017F onto s), so a name whose bytes above
# 0x7f, each run read as any one letter, match one the cloud reads fails; tr
# maps those bytes first, so BWK awk and gawk read one name (B08R3Z-3).
# stack.tsv comes from the index as the toolbox does (B08R3Z-4), no blob is
# written to a file (B08R3Z-5), and a settings.json git holds only at stages 1
# to 3, a conflict, is said as that (B08R3Z-6). provision is bash, so eol=crlf
# on a file under .claude but the two JSON files is a fault as well, and the
# attributes match case as Linux does (B08R3Z2-1). The toolbox goes through the
# same reader (B08R3Z2-2), and over its fault no stack row is compared.
# stack.tsv is read only from a stage-0 regular entry (B08R3Z2-3), and
# membership is awk, never a grep -q that SIGPIPE can race (B08R3Z2-4).
# The cloud runs one chain: settings.json, its provision hook, provision's
# bytes, provision's jq reader, the toolbox. So when the index holds a stage-0
# toolbox, settings.json must hold exactly one hook object equal to the one
# gate.sh binds (type, command, shell, async and timeout, in any order, and no
# other key) in a SessionStart group whose matcher is startup|resume|clear|
# compact (B08R3Z3-1), and provision must be a stage-0 100755 blob, not empty,
# with no CR and no NUL byte (B08R3Z3-2). A new way to run provision is then a
# change to gate.sh as well. The reader keeps a string as written, and \", its
# one escape, decodes one way only, so comparing the written command compares
# the decoded one. The toolbox must be the closed shape provision's reader
# takes: about, an array of strings, and tools, objects of string values keyed
# name, carry, source, sha, subdir and note, each with a name and a carry of
# fetch, builtin, claude.ai or no, a fetch with its source, sha and subdir
# (B08R3Z3-3). No settings.json does not skip a chain that is committed: with a
# stage-0 toolbox or a plugin or skill row in stack.tsv, the chain is judged and
# settings.json binds 0 provision hooks; only a tree with none of the three is
# skipped (B08R3Z4-1). No toolbox value is empty, since provision's tab-split
# read merges an empty field away and shifts the rest (B08R3Z4-2). The toolbox
# is read back against stack.tsv: each entry names a plugin or skill row, and a
# fetch of a row rated risk=high is refused, as invariant 4 refuses it
# (B08R3Z4-3). Copies of the provision hook are counted in every event and
# group, and one outside its SessionStart group is said (B08R3Z4-4). A risk
# but low, medium or high is no rating, so its fetch fails closed (B08R3Z5-1),
# and any other hook whose command names provision is said (B08R3Z5-2).
_cloud_fault() {   # command...: 1 when its output is over 65536 bytes (B08R3V-2), 2 when it holds a NUL byte (B08R3W-1); read twice, kept nowhere
  if [ "$(($("$@" 2>/dev/null | wc -c)))" -gt 65536 ]; then echo 1; elif [ "$(($("$@" 2>/dev/null | LC_ALL=C tr -cd '\000' | wc -c)))" -gt 0 ]; then echo 2; fi
}
_cloud_check() {   # [t]: .claude/settings.json as git's index holds it (B08R3Y-1), piped into awk, never a file (B08R3Z-5); hooks.json from disk
  local h=engine/hooks/hooks.json p=.claude/settings.json y z=9 a=/dev/null b=/dev/null out
  [ -z "${1:-}" ] || { h=""; p=.claude/cloud/toolbox.json; }   # t: the toolbox alone, N and its names or its clause (B08R3Z2-2)
  y="$(_cloud_fault git cat-file blob ":$p")"; [ -n "$y" ] || b=-
  [ -z "$h" ] || [ ! -f "$h" ] || [ ! -r "$h" ] || z="$(_cloud_fault cat "$h")"; [ -n "$z" ] || a="$h"   # z 9: no hooks.json, so no pairs
  out="$( { [ "$b" != - ] || git cat-file blob ":$p" 2>/dev/null; } | LC_ALL=C awk -v Z="${z:-0}${y:-0}" -v TM="${1:-}" -v PB="${CLOUD_PB:-0}" '
    BEGIN {
      FN[1] = "engine/hooks/hooks.json"; FN[2] = ".claude/settings.json"; FN[3] = ".claude/cloud/toolbox.json"; ESC = 3; NJ = 4; REP = 5; TL = 6; SCH = 7; TBS = 8
      split("larger than 65536 bytes|a NUL byte|an escape other than \\\"|not JSON|a key repeated in one object|a top-level key other than hooks|a key or value outside the hook schema|not the toolbox shape provision reads", WHY, "|")
      for (i = 1; i <= 2; i++) W[TM && i == 2 ? 3 : i] = substr(Z, i, 1) + 0   # Z: _cloud_fault of each file, 0 for none, 9 for no hooks.json; TM: the toolbox is file 3
      MS = (W[1] == 9); NP = " unreadable: no event-to-hook pairs read from one of the two files"
      GD = "[ \\\"$CLAUDE_CODE_REMOTE\\\" = true ] || exit 0; "   # B08R3Z-2: how a guarded command value begins, as written
      for (i = 1; i < 32; i++) CT = CT sprintf("%c", i)
      split("type command shell async timeout statusMessage", HK0, " "); for (i in HK0) HK[HK0[i]] = 1
      # B08R3Z3-1: the provision hook gate.sh binds, each value as written, s a string and l a literal; PM the matcher of its group
      CV["type"] = "scommand"; CV["command"] = "s" GD "exec bash \\\"$CLAUDE_PROJECT_DIR/.claude/cloud/provision\\\" --session-start"
      CV["shell"] = "sbash"; CV["async"] = "lfalse"; CV["timeout"] = "l120"; PM = "startup|resume|clear|compact"
      split("name carry source sha subdir note", TK0, " "); for (i in TK0) TK[TK0[i]] = 1   # B08R3Z3-3: a tools entry key
      split("fetch builtin claude.ai no", CY0, " "); for (i in CY0) CY[CY0[i]] = 1   # and a carry
      NUM = "^-?(0|[123456789][0123456789]*)([.][0123456789]+)?([eE][-+]?[0123456789]+)?$"
    }
    function ft(v) { if (!W[f] || v < W[f]) W[f] = v }   # a fault of rank v; the lowest rank names the file
    function fin() { if (f && (d != 0 || !done || cc[f] != nb[f])) bad[f] = 1; if (f && ex != "E") ft(NJ) }
    function ho() { return d == 6 && N[2] == "hooks" && N[5] == "hooks" && K[1] K[2] K[3] K[4] K[5] K[6] == "{{[{[{" }   # in a hook object
    function op(k,   q) {
      if (f == 2 && KY[d] == "command" && ho()) nc++   # B08R3Z-2: a command value that is no string is unguarded
      if (d == 0 && (k != "{" || done)) bad[f] = 1
      q = (d > 0 && K[d] == "{") ? KY[d] : ""
      d++; K[d] = k; N[d] = q; KY[d] = ""; O[d] = ++no; ex = (k == "{") ? "K" : "V"
      if (d == 3) cy = en = ""; else if (d == 4 && k == "{") { m = "-"; g0 = n + 1; pg = 0 }   # cy, en the carry and name of a tools entry, pg the provision hooks of a group
      if (d == 6 && k == "{") { h = ""; a = "-"; t = "-"; nk = gk = pv = 0 }   # pv: its command names provision
    }
    function cl(k,   i) {
      if (d == 0) { bad[f] = 1; return }
      if (K[d] != (k == "}" ? "{" : "[")) bad[f] = 1
      if (f == 2 && K[d] == "{" && ((d == 1 || d == 4) && !((O[d], "hooks") in KS) || d == 6 && !(((O[d], "type") in KS) && ((O[d], "command") in KS)))) ft(SCH)
      if (f == 3 && K[d] == "{" && (d == 1 && !((O[1], "tools") in KS) || d == 3 && N[2] == "tools" && !(((O[3], "name") in KS) && CY[cy] &&
        (cy != "fetch" || ((O[3], "source") in KS) && ((O[3], "sha") in KS) && ((O[3], "subdir") in KS))))) ft(TBS)   # B08R3Z3-3: tools, a name, a carry, and for fetch its three
      if (f == 3 && d == 3 && K[d] == "{" && N[2] == "tools") NM = NM "\n" en "\t" cy   # B08R3Z4-3: the name and carry of each entry, in toolbox order
      # B08R3Z3-1: five keys, each as bound; B08R3Z4-4: ca counts the copies in every event and group, pg those in a SessionStart group
      if (f == 2 && K[d] == "{" && ho() && nk == 5 && gk == 5) { ca++; if (N[3] == "SessionStart") pg++ }
      else if (f == 2 && K[d] == "{" && ho() && pv) po++   # B08R3Z5-2: any other hook naming provision, a plain substring
      if (d == 6 && K[d] == "{" && h != "") { n++; E[n] = N[3]; H[n] = h; A[n] = a; T[n] = t; F[n] = f; nb[f]++; h = "" }
      if (d == 4 && K[d] == "{") { for (i = g0; i <= n; i++) M[i] = m; if (m == PM) pc += pg }
      d--; ex = d ? "e" : "E"
      if (d == 0) done = 1
    }
    function key(s) {   # B08R3-3 a repeat; B08R3V-4 a top-level key but hooks; B08R3V-5 (c), (d) a group or hook key outside the schema
      if ((O[d], s) in KS) ft(REP)
      KS[O[d], s] = 1; KY[d] = s; ex = ":"
      if (f == 2 && d == 1 && s != "hooks") ft(TL)
      else if (f == 2 && (d == 4 && s != "matcher" && s != "hooks" || d == 6 && !(s in HK))) ft(SCH)
      else if (f == 3 && (d == 1 && s != "about" && s != "tools" || d == 3 && !(s in TK))) ft(TBS)   # B08R3Z3-3: the toolbox keys, a closed set
      if (f == 2 && d == 6) nk++
    }
    function sv(k, s,   y) {   # B08R3V-5: in settings, a value of type k ({, [, s a string, l a literal) where the schema allows it
      # B08R3Z3-3: strings, nothing below an entry; B08R3Z4-2: none empty, which the tab-split read of provision merges away
      if (f == 3 && (d == 0 && k != "{" || d == 1 && k != "[" || d == 2 && k != (N[2] == "tools" ? "{" : "s") || d > 2 && (k != "s" || s == ""))) ft(TBS)
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
      if (f == 2 && d == 6 && CV[KY[d]] == ((lit ? "l" : "s") s)) gk++   # B08R3Z3-1: a value as gate.sh binds it
      else if (!lit && f == 3 && d == 3 && N[2] == "tools") { if (KY[3] == "name") en = s; else if (KY[3] == "carry") cy = s }
      if (f == 2 && KY[d] == "command" && ho()) { nc++; if (!lit && index(s, GD) == 1) ng++; if (!lit && index(s, "provision")) pv = 1 }   # B08R3Z-2
      if (!lit && d == 4 && KY[d] == "matcher") m = s
      else if (lit && d == 6 && KY[d] == "async") a = s
      else if (lit && d == 6 && KY[d] == "timeout") t = s
      else if (!lit && KY[d] == "command" && (p = index(s, "harness/hooks/"))) {
        cc[f]++; r = substr(s, p + 14)
        if (!match(r, /^[a-z-]+/) || index(r, "harness/hooks/")) bad[f] = 1
        else if (ho()) h = substr(r, 1, RLENGTH)
      }
    }
    FILENAME != cur { fin(); cur = FILENAME; f = (FILENAME == FN[1]) ? 1 : (TM ? 3 : 2); seen[f] = 1; d = 0; done = 0; ex = "v" }
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
      for (f = 1; f <= 3; f++) if (!seen[f]) ft(NJ)   # an empty file holds no JSON text
      if (TM) { print (W[3] ? " unreadable: " FN[3] " (" WHY[W[3]] ");" : "N" NM); exit }   # B08R3Z2-2: the toolbox, its clause or its names
      for (i = 1; i <= n; i++) { R[i] = E[i] "\t" M[i] "\t" H[i] "\t" A[i] "\t" T[i]; c[F[i]]++ }
      # B08R3-4, B08R3V-6: one clause per file, its first fault by rank; any of them prints these alone.
      for (i = 1; i <= 2; i++) { q = W[i] ? " (" WHY[W[i]] ")" : ""; if (q != "") r3 = 1; if (q != "" || bad[i]) u = u " unreadable: " FN[i] q ";" }
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
      # The comparison stands only when no file has a fault; then the guard count, where the greps put it (B08R3Z-2).
      if (MS) o = NP (W[2] == 1 || W[2] == 2 ? "; unreadable: " FN[2] " (" WHY[W[2]] ");" : "")   # B08R3Y-4
      else if (r3) o = u
      else if (!c[1] || !c[2]) o = NP
      else if (u != "") o = u
      if (nc != ng) o = o " " (nc - ng) " command(s) without the CLAUDE_CODE_REMOTE guard;"
      if (PB && !W[2] && !bad[2] && pc != 1) o = o " unreadable: " FN[2] " (" (pc + 0) " SessionStart hooks run provision as gate.sh binds it, not 1);"   # B08R3Z3-1
      if (PB && !W[2] && !bad[2] && ca > pc) o = o " unreadable: " FN[2] " (" (ca - pc) " copies of the provision hook outside SessionStart " PM ");"   # B08R3Z4-4
      if (PB && !W[2] && !bad[2] && po) o = o " unreadable: " FN[2] " (" po " other hooks name provision);"   # B08R3Z5-2
      print o
    }' "$a" "$b" 2>/dev/null)" \
    || { echo " unreadable: the cloud check could not run over the two files;"; return 0; }
  printf '%s' "$out"
}
CLOUD_BAD=" unreadable: .claude (not a directory in the repository, so its settings files cannot be judged);"; CLOUD_IX=D; CLOUD_AT=""
if [ ! -L .claude ] && { [ ! -e .claude ] || [ -d .claude ]; }; then   # B08R3X-1 on disk first; then the index, in one pass
  # The pass reads the index twice: its bytes above 0x7f mapped to \002 a run, for the fold test, then as git wrote it.
  { CLOUD_LS="$(LC_ALL=C git --no-pager ls-files -s -z 2>/dev/null | LC_ALL=C tr '\n\000' '\001\n')" && CLOUD_IX="$( {
      printf '%s\n' "$CLOUD_LS" | LC_ALL=C tr -s '\200-\377' '\002'; printf '\003\n%s\n' "$CLOUD_LS"; } | LC_ALL=C awk '
    function fm(c, t,   i, x, h) {   # 0 when c is not t; 1 when it is, ASCII case folded; 2 when it is through a \002, any one letter
      if (length(c) != length(t)) return 0
      for (i = 1; i <= length(t); i++) { x = substr(c, i, 1); if (x == "\002") h = 1; else if (tolower(x) != substr(t, i, 1)) return 0 }
      return 1 + h
    }
    $0 == "\003" { r0 = NR; next }
    !r0 { n = split(substr($0, index($0, "\t") + 1), C, "/"); k = fm(C[1], ".claude"); y = z = 0   # B08R3Z-3, component by component
      if (k && n > 1) y = fm(C[2], "settings.json") + fm(C[2], "settings.local.json") + (z = fm(C[2], "cloud"))
      if (z && n > 2) z = fm(C[3], "toolbox.json") + fm(C[3], "provision")
      FR[NR] = (k == 2 || y == 2 || z == 2); next }
    { i = index($0, "\t"); split(substr($0, 1, i - 1), m, " "); p = substr($0, i + 1); l = tolower(p); r = (m[1] == "100644" || m[1] == "100755") }
    { if (p == ".claude") d = 1; else if (r && p == ".claude/settings.json") s = 1 }
    p == ".claude/settings.local.json" { x = " unreadable: " p " (a local settings file in the repository, which Claude Code reads beside settings.json);" }
    !r && substr(p, 1, 8) == ".claude/" { b = b " unreadable: " p " (not a regular file in the repository, so the cloud would not get its content);" }
    index(l "/", ".claude/") == 1 && (substr(p, 1, 8) != substr(l, 1, 8) || p != l && l ~ "^[.]claude/(settings([.]local)?|cloud/toolbox)[.]json$") {
      b = b " unreadable: " p " (its name differs only by case from one the cloud reads, and the cloud\047s file system does not fold case);" }
    FR[NR - r0] { b = b " unreadable: " p " (a non-ASCII name the Mac\047s file system may fold onto one the cloud reads);" }
    END { print (d ? "D" : (s ? "S" : "-") x b) }')"; } \
    || CLOUD_IX="- unreadable: .claude/settings.local.json (git could not say whether it is in the repository);"
  if [ "$CLOUD_IX" != D ]; then   # B08R3Z-1: each regular file under .claude once, its attributes as the index gives them
    CLOUD_AT="$(printf '%s\n' "$CLOUD_LS" | LC_ALL=C awk '{ i = index($0, "\t"); p = substr($0, i + 1); m = substr($0, 1, 7) }
        (m == "100644 " || m == "100755 ") && substr(p, 1, 8) == ".claude/" && p != q { print (q = p) }' | LC_ALL=C tr '\n\001' '\000\n' \
      | LC_ALL=C git -c core.ignorecase=false --no-pager check-attr --cached -z --stdin working-tree-encoding filter ident eol 2>/dev/null \
      | LC_ALL=C tr '\n\000' '\001\n' | LC_ALL=C awk 'NR % 3 == 1 { p = $0 } NR % 3 == 2 { a = $0 }   # path, attribute, value; unspecified or unset is no fault
        # B08R3Z2-1: eol only as crlf, and never on the two JSON files, which read a line end as whitespace
        NR % 3 == 0 && $0 != "unspecified" && $0 != "unset" && (a != "eol" || $0 == "crlf" && p != ".claude/settings.json" && p != ".claude/cloud/toolbox.json") {
          printf " unreadable: %s (git attribute %s changes it at checkout);", p, a }')" \
      || CLOUD_AT=" unreadable: .claude (git could not say which attributes change its files at checkout);"
    CLOUD_BAD="${CLOUD_IX#?}$CLOUD_AT"
  fi
fi
if [ "$CLOUD_IX" != "${CLOUD_IX#[S-]}" ]; then   # B08R3Z4-1: whenever the index was read, settings.json in it or not
  # The index once more: 1 for a stage-0 toolbox, else 0 (B08R3Z3-1); provision's stage-0 100755 blob, or -;
  # then stack.tsv's stage-0 regular blob, - for any other entry at that path, nothing for none (B08R3Z2-3).
  CLOUD_PS="$(printf '%s\n' "$CLOUD_LS" | LC_ALL=C awk '{ i = index($0, "\t"); p = substr($0, i + 1); split(substr($0, 1, i - 1), m, " ") }
      p == ".claude/cloud/toolbox.json" && m[3] == "0" { t = 1 } p == ".claude/cloud/provision" && m[1] == "100755" && m[3] == "0" { x = m[2] }
      p == "projects/felix/stack.tsv" && s == "" { s = (m[3] == "0" && (m[1] == "100644" || m[1] == "100755")) ? m[2] : "-" }
      END { print t + 0, (x == "" ? "-" : x), s }')"
  CLOUD_PB="${CLOUD_PS%% *}"; CLOUD_ST="${CLOUD_PS#* }"; CLOUD_PX="${CLOUD_ST%% *}"; CLOUD_ST="${CLOUD_ST#* }"
  # Names read by the reader above, not jq: the gate runs on bash and git alone (constitution
  # invariant 2). A toolbox not in the index has no names, so every stack row fails; over a
  # toolbox fault, or a stack.tsv not read, no row is compared. Both sides from the index (B08R3Z-4).
  CLOUD_TB=N; [ "$CLOUD_PB" != 1 ] || CLOUD_TB="$(_cloud_check t)"
  # B08R3Z2-4: membership in awk over the parsed names. R first when stack.tsv holds a plugin or skill row
  # (B08R3Z4-1); then each row with no toolbox entry, each entry with no row, each fetch of a risk=high row (B08R3Z4-3).
  CLOUD_MB=-; [ "${#CLOUD_ST}" -le 1 ] || CLOUD_MB="$(git cat-file blob "$CLOUD_ST" 2>/dev/null | grep -vE '^[[:space:]]*(#|$)' \
    | CLOUD_TB="$CLOUD_TB" LC_ALL=C awk -F'\t' '
      BEGIN { n = split(ENVIRON["CLOUD_TB"], A, "\n"); for (i = 2; i <= n; i++) { split(A[i], B, "\t"); TN[i] = B[1]; TC[i] = B[2]; H[B[1]] = 1 } }
      $1 == "plugin" || $1 == "skill" { r = 1; k = $2; sub(/@.*/, "", k); S[k] = 1; if ($4 == "high") HI[k] = 1
        else if ($4 != "low" && $4 != "medium") RV[k] = 1   # B08R3Z5-1: outside low|medium|high, the vocabulary discover writes, no rating: it fails closed
        if (!(k in H)) o = o " " k " has no entry in .claude/cloud/toolbox.json;" }
      END { for (i = 2; i <= n; i++) if (!(TN[i] in S)) o = o " " TN[i] " is in .claude/cloud/toolbox.json and not in projects/felix/stack.tsv;"
        for (i = 2; i <= n; i++) if (TC[i] == "fetch") { if (TN[i] in HI) o = o " " TN[i] " is fetched into the cloud and stack.tsv rates it risk=high;"
          if (TN[i] in RV) o = o " " TN[i] " is fetched into the cloud and stack.tsv\047s risk for it is not low, medium or high;" }
        print (r ? "R" : "-") o }')"
  # Skipped only with no settings.json, no stage-0 toolbox and no stack row; a stack.tsv git holds but
  # this cannot read may hold one, so it is judged (B08R3Z4-1).
  if [ "$CLOUD_IX" != "${CLOUD_IX#S}" ] || [ "$CLOUD_PB" = 1 ] || [ "$CLOUD_ST" = - ] || [ "$CLOUD_MB" != "${CLOUD_MB#R}" ]; then
    if [ "$CLOUD_IX" = "${CLOUD_IX#S}" ]; then CLOUD_BAD="$CLOUD_BAD unreadable: .claude/settings.json (0 SessionStart hooks run provision as gate.sh binds it, not 1);"
    elif git cat-file -e :.claude/settings.json 2>/dev/null; then CLOUD_BAD="$CLOUD_BAD$(_cloud_check)"
    else CLOUD_BAD="$CLOUD_BAD unreadable: .claude/settings.json (git's index holds no stage-0 copy of it);"; fi   # B08R3Z-6
    if [ "$CLOUD_PB" = 1 ]; then   # B08R3Z3-2: provision's index blob, its first fault of four, counted as B08R3X counts NUL
      CLOUD_PR=""   # a blob git cannot size reads as empty, so it fails closed
      if [ "$CLOUD_PX" = - ]; then CLOUD_PR="settings.json runs it, and git's index holds no executable file there"
      elif [ "$(git cat-file -s "$CLOUD_PX" 2>/dev/null || echo 0)" = 0 ]; then CLOUD_PR="empty in git's index"
      elif [ "$(($(git cat-file blob "$CLOUD_PX" 2>/dev/null | LC_ALL=C tr -cd '\r' | wc -c)))" -gt 0 ]; then CLOUD_PR="a CR byte in git's index blob"
      elif [ "$(($(git cat-file blob "$CLOUD_PX" 2>/dev/null | LC_ALL=C tr -cd '\000' | wc -c)))" -gt 0 ]; then CLOUD_PR="a NUL byte in git's index blob"; fi
      [ -z "$CLOUD_PR" ] || CLOUD_BAD="$CLOUD_BAD unreadable: .claude/cloud/provision ($CLOUD_PR);"
    fi
    [ "$CLOUD_ST" != - ] || CLOUD_BAD="$CLOUD_BAD unreadable: projects/felix/stack.tsv (not a regular file at stage 0 in git's index);"
    if [ "$CLOUD_TB" = "${CLOUD_TB#N}" ]; then CLOUD_BAD="$CLOUD_BAD$CLOUD_TB"
    elif [ "${#CLOUD_ST}" -gt 1 ]; then CLOUD_BAD="$CLOUD_BAD${CLOUD_MB#?}"; fi
  fi
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
