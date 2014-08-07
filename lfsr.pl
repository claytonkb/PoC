#! /usr/bin/perl -w

# Author: Clayton Bauman
# License: BSD

# Just playing around with an LFSR
#32 stages, 16 taps:

$steps = shift;

@taps = (31, 29, 27, 24, 23, 21, 19, 16, 15, 13, 10, 8, 7, 5, 2);

@state = (1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,);

@tap_state = (0) x $#state;

for(@taps){
    $tap_state[$_] = 1;
}

for(1..$steps){

    for($i=$#state; $i>=0; $i--){
        $state[$i] = $state[$i-1]                   unless $tap_state[$i];
        $state[$i] = $state[$i-1] ^ $state[$#state] if     $tap_state[$i];
    }

}

print "@state\n";

