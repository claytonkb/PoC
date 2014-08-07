#!/usr/bin/perl -w

# Author: Clayton Bauman
# License: BSD

# Turing Machine Simulator
#
# This Turing Machine simulator changes states using a differential value
# States cannot be named, they must be integers

# Q is a finite set of states 
# Gamma is a finite set of the tape alphabet/symbols 
# b e Gamm is the blank symbol (the only symbol allowed to occur on the tape infinitely often at any step during the computation) 
# Sigma, a subset of Gamma not including b is the set of input symbols 
# delta : Q x Gamma -> Q x Gamma x {L,R} is a partial function called the transition function, where L is left shift, R is right shift. 
# q0 e Q is the initial state 
# F sub Q is the set of final or accepting states

#Turing instructions (5-tuples):
# (P, S, H, T, Q)
# P = current state
# S = scanned symbol
# H = head action (print symbol/erase square/no-action)
# T = tape action (left/right/none)
# Q = next state

#Simulator commands
# step
# break (step|state|symbol|head_action|tape_action)
# go
# trace (state|tape) (on|off)
# show (tape <position>|code|state)
# 
# Position is relative to the head (negative to the left, positive to the right), default is 0
#
#             read <symbol> |
#            write <symbol> |
#           move <direction> )

if($#ARGV == -1){
	print "Usage: turing.pl <definition_file>|-h\n";
}

$file_name = shift;

if($file_name eq "-h"){
	$~ = 'HELP_MSG';
	write;
	exit;
}

open DEF_FILE, $file_name;
@def_file = <DEF_FILE>;
close DEF_FILE;

$def_file = join '', @def_file;
#$def_file =~ s/#.*\n//; #remove comments
#$def_file =~ s/^\s+\n//; #remove blank lines
($input_tape, $turing_code) = split /%%/, $def_file;

@turing_instrs = split /\n/, $turing_code;

$current_state = undef;
@tape = ();
$position = undef;
$step = 0;
$tape_trace = 0;
$state_trace = 0;
$break_step = 0;
$break_state = undef;

load_states(@turing_instrs);
init_tape($input_tape);
show_tape(0,20);
#show_machine();

command_line();

sub command_line{

	while(1){

		prompt();

		$command = <STDIN>;

		if($command =~ /^step\s+([0-9]+)?$/){
			$steps = 1;
			if(defined $1){
				$steps = $1;
			}
			if($steps == 0){
				$steps = 0xffff_ffff; #cycle limit
			}
			for(my $i = 0; $i < $steps; $i++){
#				if($state_trace){
#					show_machine();
#				}
				step_machine($current_state);
				$step++;
				if($tape_trace){
					show_tape(0, 20);
				}
				if($step == $break_step){
					print "Breakpoint encountered @ step $break_step\n";
					last;
				}
				if(defined $break_state){
					if($current_state eq $break_state){
						print "Breakpoint encountered @ state $break_state\n";
						last;
					}
				}
			}
		}
		elsif($command =~ /^show\s+tape\s+(\*|-?[0-9]+)?$/){
			if($1 eq '*'){
				show_tape(0, 0);
			}
			else{
				$pos = 0;
				if(defined $1){
					$pos = $1;
				}
				show_tape($pos, 20);
			}
		}
		elsif($command =~ /^show\s+state$/){
			show_machine();
		}
		elsif($command =~ /^show\s+code$/){
			show_code();
		}
		elsif($command =~ s/^break\s+//){
			if($command =~ /step\s+([0-9]+)/){
				$break_step = $1;
			}
			elsif($command =~ /state\s+(\w+)/){
				$break_state = $1;
			}
		}
		elsif($command =~ /^trace\s+(on|off)$/){

			if($1 eq "on"){
				$tape_trace = 1;
			}
			else{
				$tape_trace = 0;
			}
	
		}
		elsif($command =~ /^save\s+(\w+)$/){
			$~ = 'INLINE_HELP_MSG';
			write;
		}
		elsif($command =~ /^help$/){
			$~ = 'INLINE_HELP_MSG';
			write;
		}
		elsif($command =~ /^quit$/){
			last;
		}
		elsif($command eq "\n"){ #do nothing
		}
		else{
			print "Unrecognized command. Type \"help\" for more information or \"quit\" to exit.\n";
		}
	
	}

}

sub show_code{
	foreach (@turing_instrs) {
		print "$_\n";
	}
}

sub show_tape{

	if(!defined $tape[$position]){
		$tape[$position] = '_';
	}
	my $scanned_symbol = $tape[$position];
	my $index = "${current_state}_${scanned_symbol}";
	my $i;
	my $pos = shift;
	$pos += $position;
	my $radius = shift;
	my $left_bound;
	my $right_bound;
	if($radius > 0){
		$left_bound = $pos - $radius;
		$right_bound = $pos + $radius;
		$left_bound = 0 if $left_bound < 0;
		$right_bound = $#tape if $right_bound > $#tape;
	}
	else{
		$left_bound = 0;
		$right_bound = $#tape;
	}

	if($tape_action{$index} eq 'R'){
		print ">> ";
	}
	elsif($tape_action{$index} eq 'L'){
		print "<< ";
	}
	else{
		print "   ";
	}

	for($i = $left_bound; $i <= $right_bound; $i++){
		if($i == $position){
			print "[$tape[$i]] ";
		}
		else{
			print "$tape[$i] ";
		}
	}

	print " ->$next_state{$index}" if defined $next_state{$index};

	print "\n";

}

sub show_machine{

	if(!defined $tape[$position]){
		$tape[$position] = '_';
	}
	my $scanned_symbol = $tape[$position];
	my $index = "${current_state}_${scanned_symbol}";
	if($tape_action{$index} eq 'R'){
		print ">>";
	}
	elsif($tape_action{$index} eq 'L'){
		print "<<";
	}
	else{
		print "  ";
	}
	print " ->$next_state{$index}" if defined $next_state{$index};
	print "\n";

}

sub prompt{	print "$step> " }

sub step_machine{

	my $this_state = shift;
	my $scanned_symbol;

	if(!defined $tape[$position]){
		$tape[$position] = '_';
	}
	$scanned_symbol = $tape[$position];

	my $index = "${this_state}_${scanned_symbol}";

	#Check for halt
	if(exists $final_states{$index}){
		return 0; #do nothing...
	}

	#Update the machine's state
	$current_state = $next_state{$index} if exists $next_state{$index};

#	#Update current square
#	if($head_action{$index} eq 'E'){ #Erase
#		$tape[$position] = '_'; #_ stands for blank...
#	}
#	elsif(exists $head_action{$index} and $head_action{$index} ne 'N'){ #N stands for no action
	if(exists $head_action{$index} and $head_action{$index} ne 'N'){ #N stands for no action
		$tape[$position] = $head_action{$index};
	}

	#Move tape (not the head)
	if($tape_action{$index} eq 'L'){
		$position++;
		if($position > $#tape){
			push @tape, "_"; #write a blank
		}
	}
	if($tape_action{$index} eq 'R'){
		$position--;
		if($position < 0){
			unshift @tape, "_"; #write a blank
			$position = 0; #never let position become negative
		}
	}

}

sub load_states{

	foreach (@_) {
		
		(	$this_state, 
			$scanned_symbol, 
			$head_action,
			$tape_action,
			$next_state		) = split /\s+/, $_;
	
		if($this_state =~ /^\[.+\]$/){ #initial state is specified with square brackets, e.g. [START]
			$this_state =~ s/(\[|\])//g;
			$index = "${this_state}_${scanned_symbol}";
			if(!defined $current_state){
				$current_state = $this_state;
			}
			else{
				die "Multiple start states\n";
			}
		}
		
		if($this_state =~ s/\$$//){ #state names ending in $ are final states, e.g. HALT$
			#$index = "${this_state}_${scanned_symbol}";
			$final_states{"$this_state"} = $next_state;
		}
		else{
			$index = "${this_state}_${scanned_symbol}";
			$next_state{"$index"} = $next_state;
			$head_action{"$index"} = $head_action;
			$tape_action{"$index"} = $tape_action;
		}

	}

	if(!defined $current_state){
		die "No start state\n";
	}

}

sub init_tape{

	@tape = split /\s+/, shift;
	my $i;

#	if($#tape){
		for($i = 0; $i < $#tape; $i++) {
			if($tape[$i] =~ /^\[.+\]$/){
				$tape[$i] =~ s/(\[|\])//g;
				if(!defined $position){
					$position = $i;
				}
				else{
					die "Multiple initial head positions\n";
				}
			}
		}

		if(!defined $position){
			die "No initial head position\n";
		}
#	}

}

format HELP_MSG =

Usage: turing.pl <definition_file>

Definition file:

    Input tape (specify start head position with [])

    %%

    Turing code 5-tuples

The input tape must be space delimited. Place one 5-tuple per line, each field
of the 5-tuple must be space delimited. The fields are defined as follows:

P S H T Q

P = current state
S = scanned symbol
H = head action (print symbol/_=erase square/N=no action)
T = tape action (L=move left/R=move right/N=no action)
Q = next state

State names and symbols can be more than one character but must contain no
whitespace and must not use open or close square brackets ([ or ]) or dollar-
sign ($). Underscore (_) may be used in state and symbol names, but the symbol
consisting of just a single underscore is reserved to mean "blank." The "erase
square" head action has the effect of writing an underscore to the tape. Tape
squares are initialized to an underscore (blank) as the head moves over them if
no write action is taken.

.

format INLINE_HELP_MSG =

Commands:
    step <steps>
        Execute <steps> steps. <steps> = 1 by default. step 0 is equivalent to
        continue.

    break ( step <step> |
            state <state> )
        Break on various machine state.

    trace (state|tape) (on|off)
        Turns on and off display of the simulator state or tape.

    show (tape <position>|code|state)
        Position is relative to the head (negative to the left, positive to the 
        right), default is 0. If position is * the entire tape will be 
        displayed.
    
    help
        Show this message

    quit
        Quit the simulator

    save <file>
        Save the machine to file specified by <file>.

.
