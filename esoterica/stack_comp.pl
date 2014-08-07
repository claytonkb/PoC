#!/usr/bin/perl -w

# Author: Clayton Bauman
# License: BSD

@program = @ARGV;

for(@program){
    if(/00/){
        push @stack, 0;
    }
    elsif(/01/){
        push @stack, 1;
    }
    elsif(/10/){
        next if $#stack < 0;
        $save = pop @stack;
        pop @stack;
        push @stack, $save;
    }
    elsif(/11/){
        next if $#stack < 0;
        pop @stack, 0;
    }
    else{
        die "Unrecognized symbol: $_\n";
    }
    print "stack: @stack\n";
}

