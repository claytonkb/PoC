#!/usr/bin/perl -w

# Author: Clayton Bauman
# License: BSD

# It do what it do

@letters = ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm');

if($#ARGV < 0){
	$times = 1;
}
else{
	$times = $ARGV[0];
}

for ($i = 0; $i < $times; $i++) {

	foreach (@letters) {
		$choice = int(rand(0xffff_ffff)) & 1;
		if($choice){
			print uc $_;
		}
		else{
			print $_;
		}
	}

	print " ";

}
