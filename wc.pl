#!/usr/bin/perl -w

# Author: Clayton Bauman
# License: BSD

# wc for Windoze machines

$file_name = shift;

open FILE, $file_name;
@file = <FILE>;
close FILE;

$num_lines = $#file;

$file = join '', @file;

$num_chars = length $file;

@file = split /\s+/, $file;

$num_words = $#file;

$~ = OUTPUT;
write;

format OUTPUT =
@<<<<<<<<  @<<<<<<<<  @<<<<<<<<
$num_lines, $num_words, $num_chars
.
