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
# Enumerated, never listed. This named three hooks by hand and there were seven:
# the four newest were never checked, and would have failed silently in somebody
# else's session while this printed ok. A list of things to check is a list that
# stops matching what exists, which is the same defect the coverage table exists
# to catch — found in the check that was supposed to be catching it.
NOX=""
for f in engine/harness/felix engine/harness/tests/run engine/harness/bin/secret-scan \
         engine/harness/hooks/*; do
  [ -e "$f" ] || continue
  [ -x "$f" ] || NOX="$NOX $f"
done
if [ -z "$NOX" ]; then
  pass executable
else
  fail executable; printf '    %s\n' $NOX
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
# Compared against the version actually active, not merely the first one found.
# The cache keeps every version it has ever installed, so after a bump from
# 0.1.0 to 0.2.0 the old copy is still sitting there and `head -1` picks it:
# the check then fails permanently against a directory nothing loads, while a
# genuinely stale deployment would look identical. Ask the CLI, which knows
# which one is live; fall back to the highest version when it is absent.
#
# Skipped when no plugin is installed, which is the normal state in CI.
PLUG="$(claude plugin list --json 2>/dev/null \
        | sed -n '/"felix@felix"/,/}/p' \
        | sed -n 's/.*"installPath"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
if [ -z "$PLUG" ]; then
  PLUG="$(ls -d "$HOME"/.claude/plugins/cache/felix/felix/* 2>/dev/null | sort -V | tail -1)"
fi
# All three deployed directories, not harness alone (#82). hooks/hooks.json is
# the file that decides which hooks BIND, so a deploy that carried harness/ and
# dropped hooks/ read as `installed ok` while every session ran yesterday's
# bindings — a hook binary deployed perfectly and running nowhere. commands/ is
# executed by the runtime the same way. A directory absent from both sides is a
# fixture, not a drift; absent from one side, diff fails on the missing operand,
# which is the verdict. engine/.claude-plugin stays out: plugin.json differs
# whenever a bump is pending, which is this tree's normal state. Inline rather
# than the engine's felix_deploy_diff, deliberately: a verifier that sources the
# code it judges can be switched off by editing that code.
if [ -n "$PLUG" ] && [ -d "$PLUG" ]; then
  INSTALL_DRIFT=0
  : > /tmp/felix-install-drift.log
  # A path the repository itself declares non-content is residue, not drift
  # (#86): a claude-flow hook dropped state under tests/ mid-suite and this
  # check called a byte-identical deploy a drift, then misdiagnosed it as
  # structural. Each diff line maps to one path, and a path git ignores in
  # this tree is skipped — on either side, since a stray in the cache is a
  # deployed stray. Untracked-but-not-ignored still counts: undeployed work.
  # Missing-operand errors match no path shape and always survive.
  for d in harness hooks commands; do
    [ -e "engine/$d" ] || [ -e "$PLUG/$d" ] || continue
    while IFS= read -r IDLINE; do
      [ -n "$IDLINE" ] || continue
      IDP=""
      case "$IDLINE" in
        "Files engine/"*)
          # The filename itself may contain " and ": the separator matched is
          # the whole " and $PLUG/…" tail, never the first " and ", or
          # check-ignore is answered about a truncated fragment and an ignore
          # rule matching it certifies real drift as clean.
          IDP="${IDLINE#Files engine/}"; IDP="${IDP% differ}"; IDP="${IDP% and "$PLUG"/*}" ;;
        "Only in engine: "*|"Only in engine/"*)
          IDREST="${IDLINE#Only in }"; IDDIR="${IDREST%%: *}"; IDNAME="${IDREST#*: }"
          if [ "$IDDIR" = "engine" ]; then IDP="$IDNAME"; else IDP="${IDDIR#engine/}/$IDNAME"; fi ;;
        "Only in $PLUG: "*|"Only in $PLUG/"*)
          IDREST="${IDLINE#Only in }"; IDDIR="${IDREST%%: *}"; IDNAME="${IDREST#*: }"
          if [ "$IDDIR" = "$PLUG" ]; then IDP="$IDNAME"; else IDP="${IDDIR#"$PLUG"/}/$IDNAME"; fi ;;
      esac
      # Twice, because a directory-only pattern like `.claude-flow/` matches
      # only what git can see is a directory, and a cache-side stray does not
      # exist in the tree; the trailing slash says what it is. The global
      # excludes file is shut off — a verifier whose verdict varies with one
      # machine's personal ignore rules is not a verifier.
      if [ -n "$IDP" ] && { git -C engine -c core.excludesFile=/dev/null check-ignore -q "$IDP" \
             || git -C engine -c core.excludesFile=/dev/null check-ignore -q "$IDP/"; } 2>/dev/null; then
        continue
      fi
      printf '%s\n' "$IDLINE" >> /tmp/felix-install-drift.log
      INSTALL_DRIFT=1
    done <<EOF
$(diff -rq "engine/$d" "$PLUG/$d" 2>&1)
EOF
  done
  if [ "$INSTALL_DRIFT" -eq 0 ]; then
    pass installed
  else
    # A worktree can never satisfy this. The felix marketplace is a directory
    # marketplace pinned to one path, so a worktree's engine is not the one being
    # served and no amount of installing will make the cache match it. The gate
    # still fails — the tree genuinely does not match, and quieting that would be
    # loosening a gate to improve a number — but the failure is marked so it is
    # not written down as a mistake somebody made. Every gate run in a worktree
    # used to add an `installed` row, which is how that check reached 11 and
    # became the top entry of `felix next` rank 5: it manufactured the evidence
    # that ranked it. See issue #3.
    MROOT=""
    if [ -r "$HOME/.claude/plugins/known_marketplaces.json" ]; then
      MROOT="$(sed -n '/"felix"[[:space:]]*:[[:space:]]*{/,/^  }/p' \
                 "$HOME/.claude/plugins/known_marketplaces.json" 2>/dev/null \
               | sed -n 's/.*"installLocation"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
    fi
    if [ -n "$MROOT" ] && [ "$MROOT" != "$ROOT" ]; then
      # `structural` is load-bearing, not decoration: the engine subtracts
      # failures marked that way from what it writes to mistakes.log, and it
      # keys on that exact word. Rewriting this message to stop it
      # misdiagnosing a stray (#86) dropped the word, so every worktree gate
      # failure went back to recording a mistake nobody made — the
      # manufactured evidence of #3, returned by a message improvement. The
      # evidence below is that improvement; this word is the contract.
      printf '  %-18s FAIL (structural: drift in a tree that cannot deploy — the marketplace serves %s)\n' installed "$MROOT"
      FAILED="$FAILED installed"
      # The evidence, not only the verdict (#86). This branch used to print an
      # instruction while hiding the one line naming the actual drift, and a
      # session repeated the wrong diagnosis rather than reading the log.
      head -5 /tmp/felix-install-drift.log | sed 's/^/    /'
      printf '    a worktree passes when byte-identical to the deployed engine; if the\n'
      printf '    drift above is real work, merge it and run felix install in %s\n' "$MROOT"
    else
      fail installed
      head -5 /tmp/felix-install-drift.log | sed 's/^/    /'
      printf '    reinstall with: felix install\n'
    fi
  fi
else
  printf '  %-18s skipped (no plugin installed here)\n' installed
fi

# ------------------------------------------------------------- tests ---------
if [ "${1:-}" = "--quick" ]; then
  printf '  %-18s skipped (--quick)\n' tests
elif ./engine/harness/tests/run >/tmp/felix-gate-tests.log 2>&1; then
  pass tests
  printf '                     %s\n' "$(tail -1 /tmp/felix-gate-tests.log)"
else
  fail tests
  grep '^  FAIL' /tmp/felix-gate-tests.log | head -10 | sed 's/^/  /'
  printf '                     full log: /tmp/felix-gate-tests.log\n'
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
  # scanner printed NOTHING — no pass, no FAIL, no skip — so the gate's only
  # credential check could vanish and the report looked complete. The other two
  # skippable checks both say so, and this now matches them (#77, found while
  # fixing the confine that failed to cover this check).
  printf '  %-18s skipped (no secret-scan here)\n' secret
fi

# ------------------------------------------------------------- independence --
# The engine must name no specific project. Restated here rather than left to
# the suite alone, because this is the property that makes Felix portable and it
# is the one most easily lost to a well-meant comment.
#
# Every governed name, enumerated - not one literal. This grepped `elenchus`
# alone, so what it established was that seven particular letters were absent,
# while constitution invariant 1 says "The engine names no project". Mounting a
# second project made the gap real rather than theoretical: an engine that
# hard-codes `veldra` passed, and the identical edit naming `elenchus` failed
# (#85). Enumerating means governing something new cannot quietly widen what the
# engine is allowed to say.
#
# The engine's OWN name is exempt and has to be. `felix` appears about 1450
# times in runtime code because it is the product, the function prefix and the
# binary - not a governed product being named. That is the one exemption, and
# it is the project Felix governs itself under.
#
# bin/ is searched now. It was not, and the gate EXECUTES what is in it, so the
# literal this check was written for could sit in engine/harness/bin/secret-scan
# and pass.
#
# tests/ and templates/ stay out. The suite names Elenchus in its own comments
# on purpose - explaining what it refuses to depend on is the point - and the
# widget fixture names itself a few hundred times.
INDEP_PATHS="engine/harness/felix engine/harness/lib engine/harness/hooks engine/harness/bin"

# A path this cannot actually search is a FAILURE, not a clean result, and that
# was the check's blind spot rather than a corner of it.
#
# `git grep` exits 128 on a pathspec it cannot resolve and abandons the entire
# search, so a single absent path made every name come back non-zero and this
# printed `ok` for violations it never looked at. Demonstrated rather than
# reasoned: with `elenchus` planted in engine/harness/lib this reported
# `FAIL -> elenchus`; moving engine/harness/bin aside, with the identical
# violation still sitting there, it reported `ok`. bin/ holds exactly one
# tracked file and git does not track directories, so relocating secret-scan
# would have disarmed invariant 1 silently and on somebody else's schedule.
# Invariant 5 says a gate that cannot fail is not a gate; this one could not.
#
# Both conditions, because there are two ways to search nothing and each needs a
# different question. The first draft of this asked ls-files alone and still
# reported `ok` for the exact case it was written for - ls-files reads the INDEX
# and git grep reads the WORKING TREE, so a path deleted from disk but still
# staged answers "tracked" and then aborts the search anyway. Caught by replaying
# the reproduction against the fix rather than by reading it.
#
#   -e          the path exists to be searched at all      (git grep exits 128)
#   ls-files    and something tracked is under it          (git grep reads none)
#
# The second is the quieter half: a directory holding only untracked files lets
# git grep return 0 having read no bytes, which passes an existence test and
# fails open just the same.
INDEP_BLIND=""
for p in $INDEP_PATHS; do
  if [ ! -e "$p" ] || [ -z "$(git ls-files -- "$p" 2>/dev/null)" ]; then
    INDEP_BLIND="$INDEP_BLIND $p"
  fi
done

# A project is a directory that DECLARES itself, not one that happens to exist.
# `ls -1 projects` enumerated bare directory entries, so an empty stray
# contributed a grep term - projects/widget is one - and a plain file dropped in
# projects/ would contribute its filename. project.json is what separates a
# governed project from a leftover directory, and the memory check below already
# globs projects/*/, so this also stops one file disagreeing with itself.
#
# Matched as a literal. The name is interpolated straight into the search, so -E
# made a project called `vel.ra` search for a pattern rather than for itself. -F
# still catches every real violation shape - a bare word, a string literal, and
# a path inside a directory name - checked before this was changed. -w was tried
# and rejected on measurement: it rescues none of the common-word names, because
# `api`, `core`, `web`, `run` and `os` all appear as standalone words in engine
# prose, and it MISSES `my_elenchus_helper`, which is a violation.
INDEP_LEAK=""
for meta in projects/*/project.json; do
  [ -f "$meta" ] || continue
  name="${meta%/project.json}"; name="${name##*/}"
  [ "$name" = "felix" ] && continue
  # shellcheck disable=SC2086
  if git grep -qniF -- "$name" $INDEP_PATHS 2>/dev/null; then
    INDEP_LEAK="$INDEP_LEAK $name"
  fi
done

if [ -n "$INDEP_BLIND" ]; then
  fail independence
  printf '    cannot search:%s\n' "$INDEP_BLIND"
  printf '    git grep abandons the whole search on a path it cannot resolve,\n'
  printf '    so this would have reported ok without reading anything.\n'
elif [ -n "$INDEP_LEAK" ]; then
  fail independence
  printf '    the engine names:%s\n' "$INDEP_LEAK"
  for name in $INDEP_LEAK; do
    # shellcheck disable=SC2086
    git grep -niF -- "$name" $INDEP_PATHS | head -3 | sed 's/^/    /'
  done
else
  pass independence
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
# this check for it in the same commit, which is the property #85 bought - a
# hand-kept list is a list that stops matching what exists.
#
# A naive ban breaks the build and would deserve to: lib/detect.sh legitimately
# greps manifests for fastapi, stripe, sentry and supabase, because a capability
# probe naming many ecosystems symmetrically is how it stays neutral. So the
# boundary is declared per file, with a written reason, in engine/harness/ecosystem.tsv,
# in the same style as deny.tsv and the escape tables. A probe may name
# ecosystems; a detector that has already decided which project it is for may
# not, and a row has to say which it is.
#
# Word-boundaried, and that is measured. A substring search flags `cohere`
# inside "coherent", `vite` inside "invite" and `express` inside "expressed" in
# the engine's own prose right now, so the naive version fails open by being
# switched off after the third false positive.
ECO_TABLE=engine/harness/ecosystem.tsv
ECO_PROBE=engine/harness/lib/detect.sh

# Continuation lines joined first. The model-SDK probe sits on its own line, so
# a line-by-line read drops anthropic, openai and the rest of that vocabulary -
# which is half the case this check exists for, silently.
_eco_probe_words() {
  sed -e :a -e '/\\$/N; s/\\\n//; ta' "$ECO_PROBE" 2>/dev/null \
    | grep -oE '_felix_dep_grep "\$root" +"[^"]*(\\"[^"]*)*"' \
    | sed -E 's/.*_felix_dep_grep "\$root" +"//; s/"$//' \
    | sed 's/\\"\?//g' | tr '|' '\n' \
    | sed 's/^ *//; s/ *$//' | grep -v '^$' | LC_ALL=C sort -u
}
# A row with no reason grants nothing. That is deliberate and it fails in the
# safe direction for two of the three kinds: an `allow` with no reason stops
# permitting, so the file leaks and this goes red, and a `mute` with no reason
# stops muting, so the word comes back into the vocabulary. Only a reasonless
# `word` row narrows, and the suite fails on any row missing a reason.
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

# Refusing to answer beats answering from nothing, which is the lesson the
# independence block above paid for twice. Three ways this reads the world and
# each can come back empty without erroring: the probe can be refactored past
# the extractor, the table can go missing, and a table with no allow rows would
# make the whole engine leak at once rather than narrow - but the first two
# narrow silently, and a vocabulary of nothing passes everything.
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
# beside the verdict rather than failing: pruning it is somebody's judgement,
# and a check that fails on stale prose gets deleted. Reported at all because a
# surface built to report gaps that cannot report its own is an instance
# wearing a system's clothes (#125).
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

# ------------------------------------------------------------- probes -------
# What this checkout actually contains, asked of the thing that knows.
#
# The second of the three places the empty case is refused, and the one that
# arms it. `procedures.tsv` shipped to three projects, no project ever wrote
# one, and nothing in any gate called `felix procedures` — so a surface built
# to report gaps reported nothing, forever, and read exactly like a project
# with no gaps. A table nothing runs is a table nobody writes.
#
# So this fails when probes.tsv is missing, when it declares no probe, and when
# any probe comes back `blind` or `unknown`. Blind means a witness proves a
# surface the probe could not see. Unknown means nothing decided either way.
# Neither is a pass, and the whole point is that they must not render as one.
#
# Run through the CLI rather than reimplemented here. The `installed` check
# above is deliberately inline because it judges the deployment and must not be
# switchable by editing the code it judges; this one judges the CHECKOUT, and
# the tree's own engine is the right thing to ask about the tree. What keeps it
# honest is the count confine on this file plus probes.tsv's own verifier row.
FELIX_CLI=""
for c in "${FELIX_BIN:-}/../felix" ./engine/harness/felix; do
  [ -n "$c" ] && [ -x "$c" ] && { FELIX_CLI="$c"; break; }
done
#
# An engine that predates this check is a SKIP, not a failure, and that
# distinction is the difference between a check people read and one they learn
# to ignore. `felix probes` is called on the DEPLOYED cli, and between a merge
# and the `felix install` that follows it, that cli is the previous version —
# which answers `unknown command: probes` with exit 1, indistinguishable from a
# probe that came back blind. Every gate run on every project would have gone
# red in that window, for a reason that is not about the work, and `installed`
# already reports the same fact properly.
#
# Asked of the cli's own usage rather than by matching its error text: an
# engine that has the command lists it, and a message is prose that can be
# reworded while a command either dispatches or does not.
if [ -z "$FELIX_CLI" ]; then
  # Announced, never silent. A check that prints nothing when it cannot run is
  # a check that can disappear while the report still looks complete (#77).
  printf '  %-18s skipped (no felix CLI reachable from here)\n' probes
elif ! "$FELIX_CLI" help 2>&1 | grep -q 'felix probes'; then
  printf '  %-18s skipped (this engine has no probes command; see installed)\n' probes
elif PROBES_OUT="$("$FELIX_CLI" probes --gate 2>&1)"; then
  pass probes
  # Each state named rather than totalled. "N of M established" would count a
  # row that did not apply as an answer, and a row that came back empty as the
  # same kind of thing as one that came back with members — which is the exact
  # collapse this check exists to prevent, performed by its own summary line.
  printf '                     %s found, %s empty, %s not applicable\n' \
    "$(printf '%s\n' "$PROBES_OUT" | grep -cE '^  found +')" \
    "$(printf '%s\n' "$PROBES_OUT" | grep -cE '^  empty +')" \
    "$(printf '%s\n' "$PROBES_OUT" | grep -cE '^  not-applicable +')"
else
  fail probes
  printf '%s\n' "$PROBES_OUT" | grep -vE '^  found ' | head -12 | sed 's/^/  /'
fi

# ------------------------------------------------------------- memory --------
# Two opposite properties, and until 2026-08-14 they were one.
#
# Doctrine must survive the machine, which is what this check was built for. A
# gitignore rule that swallows maintenance.log is invisible: every command works,
# every test passes, and nothing is kept. When it was first written `git
# ls-files` reported zero tracked .log files, so it had never survived once.
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
# Doctrine is checked against the path rather than against files that happen to
# exist. The first version of that loop skipped anything absent, which made it
# vacuous in a worktree — where these files are untracked and therefore not
# present — so it passed by finding nothing. git check-ignore evaluates a path
# whether or not anything is there, which is what makes it a real check.
MISSED=""
for d in projects/*/; do
  [ -d "$d" ] || continue
  git check-ignore -q "${d}maintenance.log" 2>/dev/null && MISSED="$MISSED ${d}maintenance.log"
done
# Tracked, not merely present. A checkout that has not migrated still has these
# files sitting on disk, and a check that read the disk would fail there forever
# while a check that reads the index says the only thing that matters: whether
# this repository is carrying them.
LEAKED="$(git ls-files -- 'projects/*/memory/*' | tr '\n' ' ')"
if [ -n "$MISSED" ]; then
  fail memory; printf '    doctrine ignored:%s\n' "$MISSED"
elif [ -n "$LEAKED" ]; then
  fail memory
  printf '    memory tracked in this repository: %s\n' "$LEAKED"
  printf '    it belongs under felix_mem_root, outside any checkout.\n'
else
  pass memory
fi

echo
if [ -z "$FAILED" ]; then echo "gate: pass"; exit 0; fi
echo "gate: FAIL ($(echo "$FAILED" | tr -s ' ' | sed 's/^ //'))"
exit 1
