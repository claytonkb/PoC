#! /usr/bin/perl -w

# Author: Clayton Bauman
# License: BSD
 
#Binary combinatory logic (BCL) is a complete formulation of combinatory logic 
#(CL) using only the symbols 0 and 1, together with two term-rewriting rules. BCL 
#has applications in the theory of program-size complexity (Kolmogorov 
#complexity). 
#
#[edit] Syntax
#<term> ::= 00 | 01 | 1 <term> <term> 
#
#[edit] Semantics
#
#Rewriting rules for subterms of a given term (parsing from the left): 
#
# 1100xy  -->  x 
#11101xyz --> 11xz1yz 
#where x, y, and z are arbitrary terms. 
#
#(Note, for example, that because parsing is from the left, 10000 is not a 
#subterm of 11010000.) 
#
#The terms 00 and 01 correspond, respectively, to the K and S basis combinators 
#of CL, and the "prefix 1" acts as a left parenthesis (which is sufficient for 
#disambiguation in a CL expression). 
#
#There are four equivalent formulations of BCL, depending on the manner of 
#encoding the triplet (left-parenthesis, K, S). These are (1, 00, 01) (as above), 
#(1, 01, 00), (0, 10, 11), and (0, 11, 10). 

$KAY = "00";
$ESS = "01";
$combinator = shift;

while(1){
	if($combinator =~ s/^$KAY//){
		if(!($x = term($combinator))){
			last;
		}
		if(!($y = term($combinator))){
			last;
		}
		$combinator = $x . $combinator; #is this correct?
	}
	elsif($combinator =~ s/^$ESS//){
		if(!($x = term($combinator))){
			last;
		}
		if(!($y = term($combinator))){
			last;
		}
		if(!($z = term($combinator))){
			last;
		}
		$combinator = "11" . $x . $z . "1" . $y . $z . $combinator; #is this correct?
	}
	else{
		last;
	}
}
print "$combinator";

sub term{

	if($combinator =~ s/^(00)//){
		return $1;
	}
	elsif($combinator =~ s/^(01)//){
		return $1;
	}
	elsif($combinator =~ s/^(1)//){
		return "1" . term($combinator);
	}
#	else{
#		die "Malformed input\n";
#	}

}

