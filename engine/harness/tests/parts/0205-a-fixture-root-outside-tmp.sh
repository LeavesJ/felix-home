printf '\na fixture root outside $TMP\n'
# Parts 1100 and 1130 make their fixtures under a base whose every ancestor
# only root or this user can write. On a Linux runner $TMP sits under a shared
# /tmp, so they make that base elsewhere (XDG_RUNTIME_DIR, RUNNER_TEMP, HOME),
# outside $TMP, where _fx_cd and _fx_git would refuse every fixture line under
# it. _fx_root_add (part 0002) registers such a base as a root the guard
# accepts as it accepts $TMP, after proving no .git stands in it or above it.
# Not blind: the carrier's ruling of 2026-10-13, when 3+3b met #431's and #434's
# parts on main. Each probe hands _fx_cd a refusal record of its own, and the
# roots are put back at the end, so nothing here reaches the record the end of
# the run judges or widens what a later part may touch.
_fr_was="$_fx_roots"
_fr_up="$(cd "$TMP/.." && pwd -P)"
_fr_ok="$(mktemp -d "$_fr_up/fx-root-ok.XXXXXX")"; _fr_ok="$(cd "${_fr_ok:?}" && pwd -P)"
_fr_co="$(mktemp -d "$_fr_up/fx-root-co.XXXXXX")"; _fr_co="$(cd "${_fr_co:?}" && pwd -P)"
mkdir -p "$_fr_ok/sub" "$_fr_co/.git" "$_fr_co/inner"
_fr_rec() { : > "$TMP/fr-$1"; printf '%s' "$TMP/fr-$1"; }

# Unregistered, a directory outside $TMP is refused, as before.
_fr_r="$(_fr_rec unreg)"
_fr_o="$(FELIX_TEST_FXREFUSED="$_fr_r"; ( _fx_cd "$_fr_ok/sub" && printf in ) 2>/dev/null)"
is  "an unregistered directory outside \$TMP is refused by _fx_cd, as outside-tmp" \
    "$_fr_o|$(cut -f3 "$_fr_r")" "|outside-tmp"

# A path that is no directory, and / itself, are never roots.
_fr_r="$(_fr_rec bad)"
( FELIX_TEST_FXREFUSED="$_fr_r"; _fx_root_add ""; _fx_root_add "$_fr_ok/none"; _fx_root_add / ) 2>/dev/null
is  "_fx_root_add refuses an empty name, a path that is no directory, and /, each with a record" \
    "$(cut -f3 "$_fr_r" | tr '\n' ' ')" "root-not-a-directory root-not-a-directory root-is-slash "

# A base with a .git above it is refused, and stays unregistered.
_fr_r="$(_fr_rec co)"
_fr_o="$(FELIX_TEST_FXREFUSED="$_fr_r"; _fx_root_add "$_fr_co/inner" 2>/dev/null; printf '%s|' "$?"
         ( _fx_cd "$_fr_co/inner" && printf in ) 2>/dev/null)"
is  "_fx_root_add refuses a base a .git stands above, and _fx_cd still refuses it" \
    "$_fr_o|$(cut -f3 "$_fr_r" | tr '\n' ' ')" "1||root-in-a-checkout outside-tmp "

# A base already below $TMP adds nothing.
_fx_root_add "$TMP" 2>/dev/null
is  "_fx_root_add on \$TMP itself adds no root" "$_fx_roots" "$_fr_was"

# Registered, the base is accepted, git stops at it, and nothing is recorded.
_fr_r="$(_fr_rec reg)"
_fx_root_add "$_fr_ok" 2>/dev/null
_fr_o="$(FELIX_TEST_FXREFUSED="$_fr_r"; ( _fx_cd "$_fr_ok/sub" && printf '%s|%s' "$(pwd -P)" "${GIT_CEILING_DIRECTORIES%%:*}" ) 2>/dev/null)"
is  "a registered base outside \$TMP is entered by _fx_cd, with git's ceiling at that base, and no refusal" \
    "$_fr_o|$(cat "$_fr_r")" "$_fr_ok/sub|$_fr_ok|"
_fr_o="$(FELIX_TEST_FXREFUSED="$_fr_r"; _fx_git "$_fr_ok/sub" init -q >/dev/null 2>&1; printf '%s' "$?")"
is  "and _fx_git runs a write there: git init makes the fixture's own repository" \
    "$_fr_o|$([ -d "$_fr_ok/sub/.git" ] && printf made)|$(cat "$_fr_r")" "0|made|"
_fr_n="$(printf '%s\n' "$_fx_roots" | grep -c .)"
_fx_root_add "$_fr_ok/sub" 2>/dev/null
is  "registering a directory below a root adds nothing" "$(printf '%s\n' "$_fx_roots" | grep -c .)" "$_fr_n"

# The roots go back as they were; the two bases are removed.
_fx_roots="$_fr_was"
_fr_r="$(_fr_rec after)"
_fr_o="$(FELIX_TEST_FXREFUSED="$_fr_r"; ( _fx_cd "$_fr_ok/sub" && printf in ) 2>/dev/null)"
is  "with the roots put back, the base is refused again" "$_fr_o|$(cut -f3 "$_fr_r")" "|outside-tmp"
rm -rf "${_fr_ok:?}" "${_fr_co:?}"
