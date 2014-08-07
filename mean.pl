#!/usr/intel/bin/perl -w

# Author: Clayton Bauman
# License: BSD

die <<'USAGE' if $#ARGV < 1;
Usage: mean.pl <value1> <value2>
USAGE

$begin = shift;
$end = shift;
print int(($begin+$end) / 2) . "\n";

