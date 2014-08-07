#! /usr/bin/perl -w

# Author: Clayton Bauman
# License: BSD

# setting $skip_value=1 gives you the regular Fibonaccis

$skip_value = shift;
$iter = shift;

for(0..$iter){
    if($#values < $skip_value){
        push @values, 1;
        print "1 ";
    }
    else{
        $new_value = $values[$#values-$skip_value] + $values[$#values];
        push @values, $new_value;
        shift @values;
        print "$new_value ";
    }
}


