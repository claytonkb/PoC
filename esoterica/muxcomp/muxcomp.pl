#!/usr/bin/perl -w

# Author: Clayton Bauman
# License: BSD

# Multiplex instruction computer simulator
# This is a quick and dirty Perl script, it will not simulate large flows

use strict;
use warnings;

package Muxcomp;

# Format of .mux file:
# .org <hex value>
# <hex value>
# <hex value>
# ...

my $PC_address = 0; #Currently hard-coded
my $max_cycles = 1; #Default value...
my $mux_file;

help() if $#ARGV < 0;
while($#ARGV>-1){
    my $arg = shift @ARGV;
    for($arg){
        /^-h$/ and help();
        /^-pc$/ and $PC_address = shift, next;
        /^-max$/ and $max_cycles = shift, next;
        $mux_file = $arg; #default argument assumed to be name of .mux file
    }
}

my @mux_file;
if(defined $mux_file){
    open MUX_FILE, $mux_file;
    @mux_file = <MUX_FILE>;
    close MUX_FILE;
}
else{
    #assume the user is sending the file to us on STDIN if they did not give a file name
    @mux_file = <>;
}

my @memory;
my $PC;
my $cycle=0;
my $dest;
my $res;

read_mux_file(\@mux_file, \@memory);

$PC = convert_pointer32($memory[$PC_address]);

print "cycle  PC       data              -> dest\n";
print "----------------------------------------------------\n";

while($cycle < $max_cycles){

    ($dest, $res) = mux_instr(\@memory, $PC);
    my ($upper_res, $lower_res);
    $upper_res = bin2hex(substr($res, 0, 32));
    $lower_res = bin2hex(substr($res, 32   ));

    printf("%06d %08x ${upper_res}_${lower_res} -> ", $cycle, convert_pointer32($memory[$PC_address])); # N.B. will wrap-around after a million cycles...

    if($dest == $PC_address){ # This is done this way as a perf optimization...
        printf("%016x (PC)\n", $dest);
        $PC = convert_pointer32($memory[$PC_address]);
    }
    else{
        printf("%016x\n", $dest);
        $PC+=8;
        $memory[$PC_address] = ('0' x 32) . dec2bin($PC);
    }

    $cycle++;

}

sub mux_instr {

    my $memory = shift;
    my $PC = shift;

    my $sel;
    my $res = "";
    my $opcode = convert_pointer32($memory->[$PC+6]);
       $opcode = $memory->[$opcode];
    my $dest   = convert_pointer32($memory->[$PC+7]);

# Internal representation of muxcomp instructions:
#
# word/bit
#
#   666655555555554444444444333333333322222222221111111111
#   3210987654321098765432109876543210987654321098765432109876543210
# 0 ................................................................ op0
# 1 ................................................................ op1
# 2 ................................................................ op2
# 3 ................................................................ op3
# 4 ................................................................ op4
# 5 ................................................................ op5
# 6 ................................................................ opcode
# 7 ................................................................ dest
# 
# dest[n] = opcode[(op5[n].op4[n].op3[n].op2[n].op1[n].op0[n])]

    my ($op_addr, $i);
    my @op;
    for(my $i=0; $i < 6; $i++){
        $op_addr = convert_pointer32($memory->[$PC+$i]);
        $op[$i] = $memory->[$op_addr];
    }

    for($i=63;$i>=0;$i--){    #Proceed from bit 63 down to bit 0

        $sel =    substr($op[5],63-$i,1) 
                . substr($op[4],63-$i,1)
                . substr($op[3],63-$i,1)
                . substr($op[2],63-$i,1)
                . substr($op[1],63-$i,1)
                . substr($op[0],63-$i,1)
                ;

        $sel = bin2dec($sel);

        $res .= substr($opcode,63-$sel,1);

    }

    $memory->[$dest] = $res;

    return ($dest, $res);

}

sub convert_pointer32 {
    my $pointer_31_0 = substr(shift,32);
    return bin2dec($pointer_31_0);
}

sub read_mux_file {

    my $mux_file = shift;
    my $memory = shift;
    my $org=undef;

    my $line;
    foreach $line (@{$mux_file}){

        $line =~ s/#.*$//; #Delete comments

        next if $line =~ /^\s*$/; #ignore blank lines

        my $data;
        if($line =~ /.org/){

            ($org) = ($line =~ /^\s*.org\s+([A-Fa-f0-9]{1,8})\s*$/);
            $org = hex($org);
  
        }
        elsif($line =~ /\s*[A-Fa-f0-9]{16}/){

            my ($data_63_32, $data_31_0) = ($line =~ /^\s*([A-Fa-f0-9]{8})_?([A-Fa-f0-9]{8})\s*$/);
            
            $data_63_32 = hex($data_63_32);
            $data_31_0  = hex($data_31_0 );
 
            $data  = dec2bin($data_63_32);
            $data .= dec2bin($data_31_0 );

            unless(defined $org){
                die "Error while reading in .mux file: origin not defined\n";
            }

            $memory->[$org] = $data;
            $org++;
 
        }
        else{
            die "Error while reading in .mux file\n";
        }

    }

}

sub dec2bin { return sprintf("%032b",shift) }

sub bin2dec { return unpack("N",  pack("B32", substr("0" x 32 . shift, -32))) }

sub bin2hex { return unpack("H8", pack("B32", substr("0" x 32 . shift, -32))) }

sub help {

print <<'USAGE';
Usage: muxcomp.pl <mux_file> [OPTIONS]
    OPTIONS:
        -pc  initial_PC
        -max max_cycles
        -h   Display this message
USAGE

exit();

}

1

