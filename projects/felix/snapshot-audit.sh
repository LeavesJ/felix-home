#!/usr/bin/env bash
# The public snapshot's audit, kept apart from its scrub (snapshot.sh).
#
#   snapshot-audit.sh NAMES AUTHOR ROOT < paths
#
# NAMES is a file of audit names, one a line; AUTHOR is the one address that
# may appear; the paths, NUL-separated and relative to ROOT, are what is read.
# Prints path<TAB>line<TAB>name<TAB>rule<TAB>hash for every line one of them
# reaches, once a line, where hash is git hash-object of that line. Exit 0 when
# every file was read and 2 when one could not be, so a caller never takes
# silence for a pass.
#
# The rules are the audit's own, sharing no pattern with the scrub, and they
# are for accidents of our own authoring. A name is looked for:
#   whole, in any case, as part of any word;
#   in two halves, each a whole word, split at any point, with anything
#     between and up to two lines apart (a name assembled from pieces);
#   as a run of adjacent words that joins into it, over up to three lines;
#   with one character standing in for one of its own.
# Words are runs of letters and digits, so an underscore, a quote or a line
# break between two halves separates them and does not hide them.
set -euo pipefail
export LC_ALL=C
[ $# -eq 3 ] && [ -f "$1" ] && [ -d "$3" ] || { echo "usage: snapshot-audit.sh NAMES AUTHOR ROOT < paths" >&2; exit 2; }
IFS= read -r -d '' PROG <<'PERL' || true
use strict; use warnings;
use Digest::SHA qw(sha1_hex);
my ($namesf, $me, $root) = @ARGV;
open(my $nf, '<', $namesf) or die "snapshot-audit: cannot read $namesf: $!\n";
my (@names, %seen);
while (my $n = <$nf>) { $n = lc $n; $n =~ s/[^a-z0-9]//g; push @names, $n if length $n && !$seen{$n}++; }
close $nf;
my (%half, %prefix, %full, %standin);
for my $n (@names) {
  my $L = length $n; $full{$n} = 1;
  for my $k (1 .. $L - 1) { push @{ $half{substr($n, 0, $k)} }, [$n, substr($n, $k)]; $prefix{substr($n, 0, $k)} = 1; }
  my @alt;
  if ($L >= 6) {
    for my $k (1 .. $L - 2) {
      my ($a, $b) = (quotemeta substr($n, 0, $k), quotemeta substr($n, $k + 1));
      if ($k >= 3) { push @alt, "$a(?:.|\\\\.|\\[[^\\]]{1,4}\\])$b" }
      elsif ($L - $k - 1 >= 3) { push @alt, "$a\\S$b" }
    }
  }
  $standin{$n} = @alt ? qr/(?:@{[join '|', @alt]})/ : undef;
}
sub hash_of { my $l = shift; sha1_hex('blob ' . (length($l) + 1) . "\0" . $l . "\n") }
my $bad = 0;
local $/ = "\0";
while (my $p = <STDIN>) {
  chomp $p; next unless length $p;
  my $c;
  if (open(my $fh, '<:raw', "$root/$p")) { local $/; $c = <$fh>; close $fh; }
  else { warn "snapshot-audit: cannot read $p: $!\n"; $bad = 1; next; }
  $c = '' unless defined $c;
  my @L = split /\n/, $c, -1; pop @L if @L && $L[-1] eq '';
  my (%hit, %adr, @tok, @set);
  my $mark = sub { my ($i, $n, $r) = @_; $hit{$i} ||= [$n, $r]; };
  for my $i (0 .. $#L) {
    my $l = $L[$i]; my $lc = lc $l;
    for my $n (@names) {
      if (index($lc, $n) >= 0) { $mark->($i, $n, 'name'); }
      elsif (defined $standin{$n} && $lc =~ $standin{$n}) { $mark->($i, $n, 'stand-in'); }
    }
    while ($l =~ /([A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,})/g) {
      my $e = lc $1; (my $d = $e) =~ s/.*@//;
      next if $e eq lc($me) || $d =~ /(^|\.)(example|invalid|test|localhost|local)$/ || $d =~ /(^|\.)example\.(com|net|org)$/;
      $adr{$i} ||= ["\@$e", 'address'];
    }
    $tok[$i] = [ $lc =~ /[a-z0-9]+/g ];
    $set[$i] = { map { $_ => 1 } @{ $tok[$i] } };
  }
  # Two halves, each a whole word, up to two lines apart, in either order.
  for my $i (0 .. $#L) {
    for my $t (@{ $tok[$i] }) {
      next unless $half{$t};
      for my $h (@{ $half{$t} }) {
        my ($n, $rest) = @$h;
        for my $j (($i > 2 ? $i - 2 : 0) .. ($i + 2 < $#L ? $i + 2 : $#L)) {
          next unless $set[$j]{$rest};
          $mark->($i, $n, 'halves'); $mark->($j, $n, 'halves'); last;
        }
      }
    }
  }
  # Adjacent words that join into a name, over up to three lines.
  my @seq; for my $i (0 .. $#L) { push @seq, [$_, $i] for @{ $tok[$i] }; }
  for my $s (0 .. $#seq) {
    my $acc = $seq[$s][0];
    next unless $prefix{$acc};
    for my $e ($s + 1 .. $#seq) {
      last if $seq[$e][1] - $seq[$s][1] > 2;
      $acc .= $seq[$e][0];
      if ($full{$acc}) { $mark->($seq[$_][1], $acc, 'pieces') for $s .. $e; }
      last unless $prefix{$acc};
    }
  }
  for my $i (sort { $a <=> $b } keys %hit) { print join("\t", $p, $i + 1, @{ $hit{$i} }, hash_of($L[$i])), "\n"; }
  for my $i (sort { $a <=> $b } keys %adr) { print join("\t", $p, $i + 1, @{ $adr{$i} }, hash_of($L[$i])), "\n"; }
}
exit($bad ? 2 : 0);
PERL
exec perl -e "$PROG" -- "$@"
