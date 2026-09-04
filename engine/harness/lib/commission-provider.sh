# Commissioning providers: a skill a session's model runs, ingested offline.
#
# Two of the rows in commissioning.tsv name providers — the claude-md-improver
# and claude-automation-recommender skills — and the engine can run neither:
# both are model-driven, and the enforcing path is bash and git with no model
# (constitution invariant 2). So the protocol is the one the amendments give
# discovery (§1.3): the engine WRITES a request into the memory root, a
# session's model runs the skill and writes an answer file beside it, and the
# engine reads that file with no model and no network. The window between
# request and answer is held by `awaiting`, which is UNKNOWN by class, holds
# nothing, and never reaches the receipt.
#
# An answer is keyed to the TOPOLOGY it was written for — a hash over the
# detected and declared surfaces and the commissioning table, which ingestion
# never writes, so ingesting cannot rotate the key its own answers carry. An
# answer for another topology is `stale` and is not read. An answer without
# its terminal `done <count>` row is `partial`: a skill that stopped halfway
# has not answered. Every row read is INFERRED, carries the file's hash and
# the provider plugin's version and commit as provenance, and installs
# nothing: the admit phase that fetches, reads, tiers and corroborates a
# nomination is the next increment, and until it lands an answered row is a
# record and nothing else.

if ! command -v felix_commission_rows >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/commission.sh"
fi

FELIX_COMMISSION_PROVIDER_KINDS='plugin mcp hook skill subagent'
FELIX_COMMISSION_PROVIDER_MAX="${FELIX_COMMISSION_PROVIDER_MAX:-40}"

# The topology an answer is keyed to. Inputs ingestion never writes.
felix_commission_topology() {
  local proj="$1" root="$2"
  { { felix_detect "$root" 2>/dev/null; felix_declared "$proj" 2>/dev/null; } | LC_ALL=C sort -u
    printf '== commissioning.tsv ==\n'; cat "$proj/commissioning.tsv" 2>/dev/null; } | _felix_hash
}

_felix_commission_provider_dir() { printf '%s/commission' "$(felix_mem_dir "$1")"; }
felix_commission_answer_path()  { printf '%s/%s.tsv' "$(_felix_commission_provider_dir "$1")" "$2"; }
felix_commission_request_path() { printf '%s/requests/%s.md' "$(_felix_commission_provider_dir "$1")" "$2"; }

# Render the request for one need from its template, into the memory root.
# Placeholders are substituted the way setup runbooks substitute {{REPO}}.
# Prints the path. Returns 1 when the template is absent — a provider row
# with no request template is a row nobody can answer, and the state says so.
felix_commission_request() {
  local proj="$1" root="$2" need="$3" tpl="$4" src out caps declared topo
  src="$tpl/commission/$need.md"
  [ -f "$src" ] || return 1
  out="$(felix_commission_request_path "$proj" "$need")"
  mkdir -p "$(dirname "$out")" 2>/dev/null || return 1
  caps="$( { felix_detect "$root" 2>/dev/null; felix_declared "$proj" 2>/dev/null; } | LC_ALL=C sort -u | tr '\n' ' ')"
  declared="$(grep -vE '^[[:space:]]*(#|$)' "$proj/stack.tsv" 2>/dev/null | cut -f2 | tr '\n' ' ')"
  topo="$(felix_commission_topology "$proj" "$root")"
  awk -v project="$(basename "$proj")" -v pdir="$proj" -v root="$root" -v caps="${caps% }" \
      -v declared="${declared% }" -v topo="$topo" -v ans="$(felix_commission_answer_path "$proj" "$need")" '
    { gsub(/\{\{PROJECT\}\}/, project); gsub(/\{\{PROJ_DIR\}\}/, pdir); gsub(/\{\{ROOT\}\}/, root)
      gsub(/\{\{CAPS\}\}/, (caps == "" ? "nothing yet" : caps)); gsub(/\{\{DECLARED\}\}/, (declared == "" ? "nothing" : declared))
      gsub(/\{\{TOPOLOGY\}\}/, topo); gsub(/\{\{OUT\}\}/, ans); print }' "$src" > "$out" 2>/dev/null || return 1
  printf '%s' "$out"
}

# The shape of an answer, decided from the file alone.
# Prints: state <TAB> detail. States: awaiting, stale, partial, answered.
felix_commission_provider_state() {
  local proj="$1" root="$2" need="$3" f first last n rows
  f="$(felix_commission_answer_path "$proj" "$need")"
  if [ ! -f "$f" ]; then
    printf 'awaiting\tno answer at %s\n' "$f"; return 0
  fi
  first="$(head -1 "$f" 2>/dev/null)"
  if [ "$first" != "# topology $(felix_commission_topology "$proj" "$root")" ]; then
    printf 'stale\tthe answer at %s is for another topology; run the skill again from the request\n' "$f"; return 0
  fi
  last="$(grep -vE '^[[:space:]]*$' "$f" | tail -1)"
  rows="$(grep -vE '^[[:space:]]*(#|$)' "$f" | grep -vc $'^done\t')"
  n="$(printf '%s' "$last" | awk -F'\t' '$1 == "done" && NF == 2 { print $2 }')"
  case "$n" in ''|*[!0-9]*) printf 'partial\tthe answer at %s has no terminal done row, so the skill did not finish\n' "$f"; return 0 ;; esac
  if [ "$n" -ne "$rows" ]; then
    printf 'partial\tthe answer at %s says done %s and holds %s rows\n' "$f" "$n" "$rows"; return 0
  fi
  printf 'answered\t%s rows at %s\n' "$rows" "$f"
}

# Rows the engine accepts from an answer, one per line, and why it refused
# the rest. A row is a fixed number of tab-separated fields with a known kind
# and a name that could be an identifier; a sixth field on an automation row
# is a risk somebody tried to assign, and risk is not the model's to assign.
# The file is model-written, so this is the place shape is enforced and the
# only place: nothing here is ever executed.
_felix_commission_provider_shape() {   # need -> expected field count
  case "$1" in constitution_audited) printf 3 ;; *) printf 5 ;; esac
}
_felix_commission_provider_lines() {
  local f; f="$(felix_commission_answer_path "$1" "$2")"; [ -f "$f" ] || return 0
  grep -vE '^[[:space:]]*(#|$)' "$f" | grep -v $'^done\t'
  return 0
}
felix_commission_provider_rows() {
  local proj="$1" need="$2" want line n kind name i=0
  want="$(_felix_commission_provider_shape "$need")"
  _felix_commission_provider_lines "$proj" "$need" | while IFS= read -r line; do
    i=$((i + 1)); [ "$i" -le "$FELIX_COMMISSION_PROVIDER_MAX" ] || break
    n="$(printf '%s\n' "$line" | awk -F'\t' '{ print NF }')"
    [ "$n" -eq "$want" ] || continue
    kind="$(printf '%s\n' "$line" | cut -f1)"; name="$(printf '%s\n' "$line" | cut -f2)"
    if [ "$want" -eq 5 ]; then
      case " $FELIX_COMMISSION_PROVIDER_KINDS " in *" $kind "*) ;; *) continue ;; esac
      printf '%s' "$name" | grep -qE '^[A-Za-z0-9@._:-]+$' || continue
    fi
    case "$line" in *'`'*|*'$('*|*';'*|*'|'*|*'&'*) continue ;; esac
    printf '%s\n' "$line"
  done
  return 0
}
felix_commission_provider_rejects() {
  local proj="$1" need="$2" want line n kind name i=0
  want="$(_felix_commission_provider_shape "$need")"
  _felix_commission_provider_lines "$proj" "$need" | while IFS= read -r line; do
    i=$((i + 1))
    name="$(printf '%s\n' "$line" | cut -f2)"
    if [ "$i" -gt "$FELIX_COMMISSION_PROVIDER_MAX" ]; then printf '%s\tbeyond the %s-row ceiling\n' "${name:-(unnamed)}" "$FELIX_COMMISSION_PROVIDER_MAX"; continue; fi
    n="$(printf '%s\n' "$line" | awk -F'\t' '{ print NF }')"
    kind="$(printf '%s\n' "$line" | cut -f1)"
    if [ "$n" -ne "$want" ]; then printf '%s\t%s fields where the shape has %s; a risk column is not the model'"'"'s to write\n' "${name:-(unnamed)}" "$n" "$want"; continue; fi
    if [ "$want" -eq 5 ]; then
      case " $FELIX_COMMISSION_PROVIDER_KINDS " in *" $kind "*) ;; *) printf '%s\tkind "%s" is not one of %s\n' "$name" "$kind" "$FELIX_COMMISSION_PROVIDER_KINDS"; continue ;; esac
      printf '%s' "$name" | grep -qE '^[A-Za-z0-9@._:-]+$' || { printf '%s\tnot a name\n' "$name"; continue; }
    fi
    case "$line" in *'`'*|*'$('*|*';'*|*'|'*|*'&'*) printf '%s\tshell metacharacters, in a row that is never executed anyway\n' "$name" ;; esac
  done
  return 0
}

# <file>@<hash> of the answer on disk, so the row-level log line for an
# answered provider row names the exact file it was read from.
felix_commission_answer_provenance() {
  local f; f="$(felix_commission_answer_path "$1" "$2")"
  [ -f "$f" ] || { printf -- '-'; return 0; }
  printf '%s@%s' "$(basename "$f")" "$(_felix_hash < "$f")"
}

# <plugin>@<version>/<sha> from the installed-plugin registry, or <plugin>@?/?
# — a provider upgrade is then visible as a provenance change (spec §7 step 7).
felix_commission_provider_provenance() {
  local plugin="$1" reg="$HOME/.claude/plugins/installed_plugins.json" ver="" sha=""
  if [ -f "$reg" ]; then
    ver="$(awk -v p="\"$plugin@" 'index($0, p) { f = 1 } f && /"version"/ { sub(/.*"version"[[:space:]]*:[[:space:]]*"/, ""); sub(/".*/, ""); print; exit }' "$reg" 2>/dev/null)"
    sha="$(awk -v p="\"$plugin@" 'index($0, p) { f = 1 } f && /"gitCommitSha"/ { sub(/.*"gitCommitSha"[[:space:]]*:[[:space:]]*"/, ""); sub(/".*/, ""); print; exit }' "$reg" 2>/dev/null)"
  fi
  printf '%s@%s/%s' "$plugin" "${ver:-?}" "${sha:-?}"
}

# The record phase: every accepted row of an answered file, appended to
# commissioning.log as INFERRED with the provider as actor. Offline, so the
# session-start hook may call it. Idempotent per file hash: a file already
# recorded under its current hash is not recorded twice. Prints the number
# of rows appended this call.
felix_commission_record_provider() {
  local proj="$1" root="$2" need="$3" answer="$4" tid="${5:-unknown-tree}" policy="${6:-}"
  local f hash plugin log stamp prov n=0 line kind name rows
  f="$(felix_commission_answer_path "$proj" "$need")"
  [ "$(felix_commission_provider_state "$proj" "$root" "$need" | cut -f1)" = "answered" ] || { printf 0; return 0; }
  hash="$(_felix_hash < "$f")"; plugin="$(printf '%s' "${answer#provider:}" | cut -d: -f1)"
  prov="$(basename "$f")@$hash;$(felix_commission_provider_provenance "$plugin")"
  log="$(felix_mem_dir "$proj")/commissioning.log"
  if [ -f "$log" ] && grep -qF "	$prov	" "$log" 2>/dev/null; then printf 0; return 0; fi
  mkdir -p "$(dirname "$log")" 2>/dev/null || { printf 0; return 1; }
  stamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  rows="$(felix_commission_provider_rows "$proj" "$need")"
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    kind="$(printf '%s\n' "$line" | cut -f1)"; name="$(printf '%s\n' "$line" | cut -f2)"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$stamp" "$tid" "${policy:--}" "$need" "answered" "INFERRED" \
      "$answer" "$prov" "$kind $name: $(printf '%s\n' "$line" | cut -f3- | tr '\t' ' ' | cut -c1-160)" >> "$log" || { printf '%s' "$n"; return 1; }
    n=$((n + 1))
  done <<ROWS
$rows
ROWS
  printf '%s' "$n"
}
