# The receipt: what changed, why, what it risks, and whether anything verified it.
#
# v3.0's domain-OS contract asks every harness for a machine-readable record of
# "what changed, why, evidence, risk, and result" that a peer or a control plane
# can consume without being made to understand Felix's internals. Felix computed
# all of it and emitted none of it: `classify` holds the risk, `evidence` holds
# what is owed, the gate holds the result, `escape` holds the authority question.
# Nothing here discovers a new fact. It serialises facts that already exist and
# gives them a version, so a reader can refuse a shape it does not know.
#
# Two fields are here because of what the transports cannot do, established by
# reading them rather than assumed. Neither MCP `2026-07-28` nor A2A `1.0.1`
# carries a bounded authority claim, and neither signs task output — so
# `authority` travels in the receipt or nowhere. And neither models verification
# as distinct from completion, which is the one thing Felix has that they lack,
# so `verification` is its own object rather than a status word meaning "done".
#
# THE RULE THIS EXISTS TO KEEP, which matters more than the shape.
#
# A receipt may not claim more than it knows. Every input that could not be read
# puts its own name in `unknown` and forces `status` to `indeterminate`. An
# absent gate receipt is `none`, never green. An unresolvable base is
# `changed.known: false`, never an empty changeset. An unreadable risk table is
# tier `unknown`, never `green` — which this project shipped once already.
#
# Six defects found in a single day were one species: an emptiness reported as
# an all-clear. Everywhere else that costs a person one confusing report. Here it
# would be a wire contract other systems build on, so the rule is asserted rather
# than intended.

# Strict JSON string escaping.
#
# Deliberately not the monitor's `_felix_json_esc`, which also escapes < and >
# for embedding in an HTML page. That is a different requirement, and each has
# exactly one caller, so these are two functions with one job each rather than
# one job with two implementations.
_felix_rcpt_esc() {
  printf '%s' "$1" \
    | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g' -e 's/\r//g' \
    | tr '\n' ' '
}

# A JSON array of strings, from newline-separated input on stdin.
_felix_rcpt_arr() {
  local first=1 line
  printf '['
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    [ "$first" -eq 1 ] || printf ','
    first=0
    printf '"%s"' "$(_felix_rcpt_esc "$line")"
  done
  printf ']'
}

# Column N of a tab-separated stream, as a JSON array.
_felix_rcpt_col() {
  cut -f"$1" | _felix_rcpt_arr
}

# Rows of `a<TAB>b<TAB>c` as JSON objects under the three given key names.
#
# The third field is cut at the next tab. `risk.tsv` carries `channel` and
# `confine` after the reason, and every reader takes the reason as "the rest of
# the line", so it arrives with those columns glued on behind two tabs. A human
# report survives that. A contract with a version number on it does not: a
# consumer reading `reason` would get three fields in one string.
_felix_rcpt_rows() {
  local k1="$1" k2="$2" k3="$3" first=1 a b c
  printf '['
  while IFS=$'\t' read -r a b c; do
    [ -n "${a:-}" ] || continue
    c="${c%%	*}"
    [ "$first" -eq 1 ] || printf ','
    first=0
    printf '{"%s":"%s","%s":"%s","%s":"%s"}' \
      "$k1" "$(_felix_rcpt_esc "$a")" \
      "$k2" "$(_felix_rcpt_esc "$b")" \
      "$k3" "$(_felix_rcpt_esc "$c")"
  done
  printf ']'
}

felix_receipt() {
  local proj="$1" base="$2" root="$3" home="${4:-}"
  local unknown="" pname branch head tid

  pname="$(basename "$proj")"
  branch="$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null || printf '?')"
  head="$(git -C "$root" rev-parse --short HEAD 2>/dev/null || printf '?')"
  tid="$(felix_tree_id "$root" "$home" 2>/dev/null || true)"

  # ---- what changed. An unresolvable base is a question nobody can answer, and
  # an empty list is an answer. Reporting the first as the second is the defect
  # this whole file is shaped around, so the two are different fields.
  # `^{commit}` is load-bearing. `git rev-parse --verify <40-hex>` exits 0 for a
  # sha that does not exist in the repository, because a full-length hex string
  # is a syntactically valid object name and --verify alone checks the syntax.
  # Only a name it cannot resolve exits non-zero. Peeling to a commit is what
  # makes it an existence test, and without it a base nobody has would have been
  # reported as a clean empty changeset — the exact failure this file refuses.
  local base_ok=0 paths=""
  if [ -n "$base" ] && git -C "$root" rev-parse --verify "$base^{commit}" >/dev/null 2>&1; then
    base_ok=1
    paths="$(felix_changed_paths "$root" "$base" 2>/dev/null || true)"
  else
    unknown="$unknown changed"
  fi

  # ---- risk. No table is not "no risk"; it is nothing known about risk.
  local tier="unknown" findings=""
  if [ "$base_ok" -eq 1 ] && [ -f "$proj/risk.tsv" ]; then
    findings="$(felix_classify_diff "$proj" "$base" "$root" 2>/dev/null || true)"
    tier="$(felix_classify_tier "$findings" 2>/dev/null || printf 'unknown')"
    [ -n "$tier" ] || tier="unknown"
  else
    unknown="$unknown risk"
  fi

  # ---- verification, kept separate from completion because no protocol does it
  # for us. Three states, and the difference between them is the point: `none`
  # means nothing ran, `stale` means something ran against a different tree, and
  # only `current` means this exact tree was judged.
  local vstate="none" vres="null" vwhen="null" vtree="null" rres=""
  local rec rtid
  rec="$(felix_verify_receipt "$root" "$home" 2>/dev/null || true)"
  if [ -n "$rec" ]; then
    rtid="$(printf '%s' "$rec" | cut -f1)"
    rres="$(printf '%s' "$rec" | cut -f2)"
    vres="\"$(_felix_rcpt_esc "$rres")\""
    vwhen="\"$(_felix_rcpt_esc "$(printf '%s' "$rec" | cut -f3)")\""
    vtree="\"$(_felix_rcpt_esc "$rtid")\""
    if [ -n "$tid" ] && [ "$rtid" = "$tid" ]; then vstate="current"; else vstate="stale"; fi
  fi

  # ---- evidence
  local ev="" gaps=""
  if [ "$base_ok" -eq 1 ] && [ -f "$proj/evidence.tsv" ]; then
    ev="$(felix_evidence_check "$proj" "$base" "$root" 2>/dev/null || true)"
    gaps="$(printf '%s\n' "$ev" | awk -F'\t' '$1=="gap"{print $2}')"
  fi

  # ---- authority. Carried here because no transport carries it, and refused
  # rather than assumed: anything unread means this cannot be called autonomous.
  local esc="" founder="false" autonomous="true"
  if [ "$base_ok" -eq 1 ]; then
    esc="$(felix_escapes "$proj" "$base" "$root" "$home" 2>/dev/null || true)"
  fi
  if [ -n "$esc" ] || [ "$tier" = "red" ] || [ -n "$unknown" ]; then
    founder="true"; autonomous="false"
  fi

  # ---- status. Precedence is deliberate. Not knowing outranks everything,
  # because a blocked-or-verified verdict computed from inputs that were never
  # read is exactly the confident wrong answer this is built to refuse.
  local status quality
  if   [ -n "$unknown" ]; then status="indeterminate"; quality="unknown"
  elif [ -n "$esc" ];     then status="blocked";       quality="high"
  elif [ "$vstate" = "current" ] && [ "$rres" = "green" ] && [ -z "$gaps" ]; then
    status="verified"; quality="high"
  else
    status="unverified"; quality="low"
  fi

  printf '{\n'
  printf '  "schema": "felix.receipt/1",\n'
  printf '  "domain": "engineering",\n'
  printf '  "project": "%s",\n'   "$(_felix_rcpt_esc "$pname")"
  printf '  "status": "%s",\n'    "$status"
  printf '  "unknown": %s,\n'     "$(printf '%s\n' $unknown | _felix_rcpt_arr)"
  printf '  "subject": {"branch": "%s", "head": "%s", "base": "%s", "tree": "%s"},\n' \
         "$(_felix_rcpt_esc "$branch")" "$(_felix_rcpt_esc "$head")" \
         "$(_felix_rcpt_esc "$base")"   "$(_felix_rcpt_esc "$tid")"
  printf '  "changed": {"known": %s, "paths": %s},\n' \
         "$([ "$base_ok" -eq 1 ] && printf 'true' || printf 'false')" \
         "$(printf '%s\n' "$paths" | _felix_rcpt_arr)"
  printf '  "risk": {"tier": "%s", "findings": %s},\n' \
         "$tier" "$(printf '%s\n' "$findings" | _felix_rcpt_rows tier path reason)"
  printf '  "verification": {"state": "%s", "result": %s, "tree": %s, "when": %s},\n' \
         "$vstate" "$vres" "$vtree" "$vwhen"
  printf '  "evidence": {"met": %s, "gap": %s},\n' \
         "$(printf '%s\n' "$ev" | awk -F'\t' '$1=="met"{print $2}' | _felix_rcpt_arr)" \
         "$(printf '%s\n' "$gaps" | _felix_rcpt_arr)"
  printf '  "authority": {"autonomous": %s, "founder_required": %s, "granted_by": "none", "escapes": %s},\n' \
         "$autonomous" "$founder" \
         "$(printf '%s\n' "$esc" | _felix_rcpt_rows channel path reason)"
  printf '  "confidence": {"evidence_quality": "%s"}\n' "$quality"
  printf '}\n'
}
