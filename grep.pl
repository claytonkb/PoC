#!/usr/bin/perl -w

# Author: Clayton Bauman
# License: BSD

#A Perl-grep for use on Windoze ...

$pattern = shift;

foreach $file_name (@ARGV){

	open(FILE, $file_name) or die "Couldn't open $file_name\n";
	@file = <FILE>;
	close FILE;

	@grep_lines = grep /$pattern/, @file;

	print "@grep_lines" if $#grep_lines > -1;

}

