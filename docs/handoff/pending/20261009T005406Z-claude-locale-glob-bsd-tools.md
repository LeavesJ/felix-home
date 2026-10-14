### 2026-10-08: bash's own collation and the BSD text tools decide nothing by locale

The neighbour of claude/locale-c-sort-comm, for the two classes it left out.
Measured under `bash -c` on macOS 26, bash 3.2.57, at b434425f and main
6fe5f986, with a Latin-1 byte (\351) and with U+2185.

**Defects.** The engine runs in its caller's locale. A Terminal's
LANG=en_US.UTF-8 reaches `felix` and every hook of a `claude` started there.
A desktop session's tool shell runs in C, which is why no session saw these.
- BSD sed, tr and cut stop at a byte that is not UTF-8. grep misses a match
  after one on its line. awk aborts the whole program on a regex over one. A
  pattern holding one compiles to nothing, in grep and in `[[ =~ ]]`. Through
  those, one byte:
  - removed a deny row with no verifier escape (`_felix_escape_lines`'s sed);
  - hid a credential from secret-scan and from classify;
  - made `felix_json_str` read no `gate`, so the Stop hook judged no gate;
  - killed a whole deny row (`_felix_deny_first`'s `=~`).
- Valid UTF-8 breaks a per-character awk: macOS awk splits by bytes and
  matches by characters, so a regex over a lone byte of `é` aborts the whole
  program. lib/deny-read.sh is one. On main, any Bash command holding one
  non-ASCII character (an accent, a dash, an emoji) passed every Bash deny row
  in a claude started from Terminal (measured through hooks/pre-tool). The
  review found it; the contract had called it unreachable.
- Counts with `grep -c .` skipped a row whose name started with the byte, so
  `felix probes --gate`, `felix obligations --gate`, their bin checkers and
  the template's commissioning checks passed over it. The epoch ignored a
  probe holding the byte, and the prompt hook routed a play holding it to
  nothing. Length ceilings in commissioning answers counted characters.
- bash collates its own globs and bracket ranges:
  - the first `projects/*/project.json` matching a remote (Web or web-admin)
    and the first marketplace copy of a plugin depended on who ran felix;
  - `case B in [a-z])` matched, so name checks admitted e-acute and capitals.
- Even `[0-9]` admits one character under UTF-8: U+2185 (it collates as 6;
  macOS's `[[:digit:]]` admits 670). After the guard, `[ -ne ]` errors and
  takes the else branch, and `$((n+1))` aborts the caller's command line.
  `felix_commission_provider_state` read `answered` on a count nobody gave.
  Commission steps, `felix_version_bump` and `felix budget` were hit too.

**Rules**, stated once above `felix_json_str` in lib/resolve.sh:
1. A function whose answer depends on bash's own collation (first-wins glob,
   a bracket range over foreign input, any `[[ =~ ]]`) declares LC_ALL=C in a
   `local` line. A bracket over digits alone is spelled out everywhere,
   `[0123456789]`, because a local LC_ALL=C makes `${#x}` count bytes.
2. A text tool reading bytes the engine did not write, where its result
   decides something, is `LC_ALL=C <tool>`. Inside the listed verdict
   functions every one is. Display keeps the caller's locale.

**Lints** in tests/run's block: `=~` whole tree (L1), the verdict-function
list (L2, every name must be found), the Rule 1 list (L3), digit ranges whole
tree with quote state carried across lines (L4).

**Left alone, on purpose:** display sites (messages, `cut -c` truncation),
the Stop hook's skip-list message, comment filters over engine templates,
glob loops that examine every match. Byte order still binds the less
specific of Web and web-admin: a separate defect, not fixed here.

**Owed by a person.** templates/commissioning.tsv's check texts now pin
their grep, cut and tr. The copies in projects/*/commissioning.tsv hold the old
text and still miscount a row named with a byte that is not UTF-8 until they
are refreshed from the template. This branch edits no table under projects/.

**Owed by whoever lands second.** The entry-point preamble comment on
claude/no-caller-env-in-tool-output and claude/no-git-colour-in-parsed-output
(slot 14) says of locale "not every one does yet (lib/escape.sh's comm -23)".
Whichever of that PR and this one lands second rewrites the bullet to point
at the rules above `felix_json_str`. Taken over from [1de1ca] with slot 21.

**State.** Branch claude/locale-glob-bsd-tools carries 21 (b434425f) whole
and lands as one PR with it (agreed with the carrier, 2026-10-08).
Three rounds, each with blind assertions (Opus) and the fix (Sonnet):
- the two classes;
- the digit ranges;
- the adversarial review's findings: four Opus lenses, then an Opus
  verifier re-ran every demo in C, LC_ALL=UTF-8 and LANG-only.

Main 698825a5 (0.49.274) is merged in. The section runner gives 156/0 here
and 17/0 for 21's block. With no UTF-8 locale it gives 68 pass, 88 skip,
0 fail.

Out of scope, offered as their own tasks:
- felix audit loses its whole report on long accented commands (display);
- binding the most specific remote_match;
- git paths that core.quotepath C-quotes;
- four small parsing defects.

Carrier slot 22. Contract, sweeps and stage log:
~/.felix/memory/felix/audits/2026-10-08-locale-glob-bsd-tools/contract.md.
