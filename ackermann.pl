#! /usr/bin/perl -w

# Author: Clayton Bauman
# License: BSD

# A little script for calculating Ackermann numbers... though
# the recursion depth limit is quickly reached even for very
# small numbers...

print ackermann(shift,shift,shift) . "\n";

sub ackermann{
    my $m = shift;
    my $n = shift;
    my $p = shift;
    if($p==0){
        return $n+1;
    }
    elsif($n==0){
        if($p==1){
            return $m;
        }
        elsif($p==2){
            return 0;
        }
        elsif($p>=3){
            return 1;
        }
    }
    else{
        return ackermann($m,ackermann($m,$n-1,$p),$p-1);
    }

}

