#!/usr/bin/env bash
# The public snapshot's scrub, kept apart from its audit (snapshot-audit.sh).
#
#   snapshot-scrub.sh PLAN LIST
#
# PLAN is one project a line, in token order: name<TAB>token<TAB>phrase. LIST
# is the text files to rewrite in place, NUL-separated. snapshot.sh derives
# both, runs this, and then checks what it changed; nothing here decides
# whether the result may go out.
#
# Per project in token order, and the order is load-bearing. The name itself
# first, and what it becomes is read from the characters around it. Inside an
# identifier (a letter, digit or underscore beside it, or $, { or } as in a
# variable) it is the token in the identifier's case: THIRD_PROJECT for an
# upper-case name, which keeps ${NAME:-} a variable where a phrase made it a
# bad substitution, and the bare token otherwise. Inside a path (a slash or a
# hyphen beside it, or a dot and a file extension) it becomes the bare token,
# which has no space: a phrase with spaces inside a path made `test -f` a usage
# error, and later turned a redirect into one to a file named for the first
# word. Anywhere else it is prose and becomes the phrase, in lower case; an
# escape such as \n before it counts as a space. Then the pieces, and only
# where no ordinary word can be meant: two halves split anywhere, each a whole
# word, with up to eight characters between and no letter or digit among them;
# and a whole word that is the name with one character standing in, where that
# character is a mark (a dot, say) or a capital among lower-case letters. Each
# becomes the token's pieces. The first and last characters are never taken as
# stand-ins here. An ordinary word one letter away from a name (planter against
# planner) is never rewritten: the audit stops on it for a person to read.
#
# Only text files are listed: a binary file is never edited, so a name in one
# is left for the audit, which reads every file, to stop on. A list that comes
# back short leaves a name unrewritten, and the audit stops on it, so a failure
# here is never silent.
set -euo pipefail
export LC_ALL=C
[ $# -eq 2 ] && [ -f "$1" ] && [ -f "$2" ] || { echo "usage: snapshot-scrub.sh PLAN LIST" >&2; exit 2; }
IFS= read -r -d '' SCRUB_PL <<'PERL' || true
BEGIN { ($n, $t, $ph, $up, $tup) = @ENV{qw(N T PH UP TUP)}; $L = length $n; }
my $o = $_;
s{\Q$n\E}{
  my ($b, $a) = (substr($o, 0, $-[0]), substr($o, $+[0]));
  my ($p, $pp) = (length $b ? substr($b, -1) : "", length $b > 1 ? substr($b, -2, 1) : "");
  my ($q, $qq) = (length $a ? substr($a, 0, 1) : "", length $a > 1 ? substr($a, 1, 1) : "");
  $p = " " if $pp eq "\\" && $p =~ /[ntr]/;
  if ($p =~ /[A-Za-z0-9_\$\{]/ || $q =~ /[A-Za-z0-9_\}]/) { $& =~ /[a-z]/ ? $t : $tup }
  elsif ($p =~ m{[/-]} || $q =~ m{[/-]} || ($q eq "." && $qq =~ /[A-Za-z0-9]/) || ($p eq "." && $pp =~ /[A-Za-z0-9]/)) { $t }
  else { $ph }
}gie;
for my $k (1 .. $L - 1) {
  my ($x, $y) = (substr($n, 0, $k), substr($n, $k));
  my ($tx, $ty) = (substr($t, 0, $k), $k < length $t ? substr($t, $k) : "");
  next if $ty eq "";
  s{(?<![A-Za-z0-9])\Q$x\E([^A-Za-z0-9]{1,8}?)\Q$y\E(?![A-Za-z0-9])}{$tx$1$ty}g;
}
for my $k (1 .. $L - 2) {
  my ($x, $y) = (substr($n, 0, $k), substr($n, $k + 1));
  my ($tx, $ty) = (substr($t, 0, $k), $k < length $t ? substr($t, $k) : "");
  next if $ty eq "";
  s{(?<![A-Za-z0-9])\Q$x\E([^A-Za-z0-9\s]|[A-Z])\Q$y\E(?![A-Za-z0-9])}{$tx$1$ty}g;
}
PERL
[ -s "$2" ] || exit 0
while IFS="$(printf '\t')" read -r n tok ph; do
  N="$n" T="$tok" PH="$ph" UP="$(printf '%s' "$n" | tr '[:lower:]' '[:upper:]')"
  TUP="$(printf '%s' "$tok" | tr '[:lower:]' '[:upper:]')_PROJECT"
  export N T PH UP TUP
  xargs -0 perl -pi -e "$SCRUB_PL" < "$2"
done < "$1"
