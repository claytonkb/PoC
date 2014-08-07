#!/usr/bin/perl -w

# Author: Clayton Bauman
# License: BSD

foreach (<>) {
	if(!exists $hash{$_}){
		#Just add and continue
		$hash{$_} = 0;
	}
	$hash{$_}++;
}

foreach (keys %hash) {
	$key = $_;
	chomp($key);
	print "$hash{$_}\t$key\n";
}

