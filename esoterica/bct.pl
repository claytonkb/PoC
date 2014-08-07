#! /usr/bin/perl -w

# Author: Clayton Bauman
# License: BSD

# Bitwise Cyclic Tag simulator
#

#Simulator commands
# step
# break (step)
# go
# 

if($#ARGV < 1){
	die "Usage: bct.pl <program> <data> [max_cycles] [-q]\n";
}

chomp($program);
chomp($data);

@program = split //, $ARGV[0];
@data = split //, $ARGV[1];
$max_cycles = 100; #Just to avoid infinite loops
$max_cycles = $ARGV[2] if $#ARGV == 2;
$be_quiet = 0;
$be_quiet = 1 if $#ARGV == 3;

$cycle_count = 0;
$PC = 0;

unless($be_quiet){
	print "program                             data                                del     cycle\n";
	print "-------------------------------------------------------------------------------------\n";
}

while($cycle_count++ < $max_cycles and $#data > -1){
	
	$PC_save = $PC; #save for display purposes

	#calculate this cycle
	if($program[$PC] eq '0'){ #### Delete left-most data bit #### 
		$deleted = shift @data;
		push @deleted, $deleted;
		$PC = ($PC+1) % ($#program+1);
	}
	else{
		$deleted = '-';
		if($data[0] eq '0'){  #### Do nothing #### 
			$PC = ($PC+2) % ($#program+1); #Add 2 to the PC, loop when the end is reached
		}
		else{                 #### Concatenate a bit to the end of @data ####
			$PC = ($PC+1) % ($#program+1);
			push @data, $program[$PC];	
			$PC = ($PC+1) % ($#program+1);
		}
	}
	
	#Display this cycle
	unless($be_quiet){
		$program = join '', @program;
		$data = join '', @data;
		$program_pointer = q{};
		for($i = 0; $i <= $#program; $i++){
			$program_pointer .= '^', next if $i == $PC;
			$program_pointer .= q{ };
		}
		$~ = cycle_information;
		write;
	}
}

print join('', @deleted) . "\n";

format cycle_information =
#program                         	#data                               #del    #cycle
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<   @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<   @<      @<<<<<<
$program, $data, $deleted, $cycle_count
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$program_pointer
.

