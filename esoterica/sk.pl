#!/usr/bin/perl -w

# Author: Clayton Bauman
# License: BSD

$combinator = shift;

while(1){
	print ">  $combinator\n";
	$combinator =~ s/^'*//;
	if($combinator =~ s/^K//){
#		$x = term($combinator) or $x = "";
#		$y = term($combinator) or $y = "";
		$x = term($combinator) or exit;
		$y = term($combinator) or exit;
#		print "x: $x\n";
#		print "y: $y\n";
		$combinator = $x . $combinator; #is this correct?
	}
	elsif($combinator =~ s/^S//){
#		$x = term($combinator) or $x = "";
#		$y = term($combinator) or $y = "";
#		$z = term($combinator) or $z = "";
		$x = term($combinator) or exit;
		$y = term($combinator) or exit;
		$z = term($combinator) or exit;
#		print "x: $x\n";
#		print "y: $y\n";
#		print "z: $z\n";
		$combinator = "\'\'" . $x . $z . "\'" . $y . $z . $combinator; #is this correct?
	}
	else{
		last;
	}
}

sub term{

#	my $c = shift;

	if($combinator =~ s/^([SK])//){
		return $1;
	}
	elsif($combinator =~ s/^'//){
		return "\'" . term($combinator) . term($combinator);
	}
#	else{
#		print "6\n";
#		exit;
#	}

}

