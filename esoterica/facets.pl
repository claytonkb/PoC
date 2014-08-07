#! /usr/bin/perl -w

# Author: Clayton Bauman
# License: BSD

# F -> False
# A -> Assign (not implemented)
# C -> Cons
# E -> Expand
# T -> True
# S -> Select

use Data::Dumper;

my $input_file;
my $output_file;

#my $input_file = join ' ', @ARGV;
#
#unless(defined $input_file){
#    $input_file = <STDIN>;
#}
#
#$TEST = <<'END_TEST';
#f x a t y a f t c t f c c x e s y e s
#END_TEST

#$program = shift;
@program = split /\s+/, (join ' ', @ARGV);
@stack = ();
$fsym = {};
@sym_stack = ();

facets(\@program, \@stack, $fsym, \@sym_stack);

print Dumper(\@stack);
print Dumper($fsym);

sub facets{

    my $program = shift;
    my $stack = shift;
    my $fsym = shift;
    my $sym_stack = shift;

    while($#program>-1){

        $_ = shift @{$program};

        if(/^q$/){                      # quote
        }
        elsif(/^c$/){                   # cons
        }
        elsif(/^s$/){                   # select
        }
        elsif(/^a$/){                   # assign
        }
        elsif(/^e$/){                   # evaluate
        }
        elsif(/^d$/){                   # dump
        }
        elsif(/^n$/){                   # nest FIXME
        }
        elsif(/^r$/){                   # return FIXME
        }
        else{                           #false, true or symbol-name
        }

}

sub select_value{
    $TOS = pop @stack;
    if($TOS =~ /t/){                # true
        $TOS_1 = pop @stack;
        push @stack, $TOS_1->[0];
    }
    elsif($TOS =~ /f/){             # false
        $TOS_1 = pop @stack;
        push @stack, $TOS_1->[1];
    }
#    else{
#        push @stack, $fsym{$TOS};
#        select_value();
#    }
}


