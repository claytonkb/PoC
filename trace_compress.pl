#!/usr/bin/perl

# Author: Clayton Bauman
# License: BSD

# A utility to automatically measure the randomness in files by 
# compressing them and then measuring the resulting file size.
 
# REDACTED

$work_dir = `pwd`;
chomp $work_dir;

if($#ARGV == -1){
	print "Usage: trace_compress.pl <xxxx_commandline>\n";
	exit;
}

if($ARGV[0] =~ /-h/){
	$~ = "HELP_MSG";
	write;
	exit;
}

if($ARGV[0] eq "-norm"){
	shift;
	$normalizing_constant = shift;
}
else{
	$normalizing_constant = 0.1153;
}

##Split the commandline into the XXXX commandline prefix and the .ivy file list
$xxxx_commandline = join ' ', @ARGV;

if($xxxx_commandline =~ /-s / or
	$xxxx_commandline =~ /-o / or
	$xxxx_commandline =~ /-e / or
	$xxxx_commandline =~ /-rpt / or
	$xxxx_commandline =~ /-no_rpt / or
	$xxxx_commandline =~ /-sim_trace / or
	$xxxx_commandline =~ /-no_output /){
	tc_print("Can't use -s, -o, -e, -rpt, -no_rpt, -sim_trace or -no_output in XXXX commandline:");
	tc_print("$xxxx_commandline");
	exit;
}

if($xxxx_commandline =~ /-n /){ #sneakiness with the XXXX commandline...
	$xxxx_commandline =~ s/-n\s+([0-9]+)//;
	$iters = $1;
}
else{
	$iters = 1;
}

if($xxxx_commandline =~ /-dont_exit_timeout /){ #more sneakiness....
	$xxxx_commandline =~ s/-dont_exit_timeout\s+([0-9]+)//;
	$failure_threshold = $1;
}
else{
	$failure_threshold = 1;
}

if($xxxx_commandline =~ /-b /){
	$xxxx_commandline =~ /-b\s+(\w+)/;
	$bif_name = $1;
}
else{
	$bif_name = "XXXX";
}

$total_uncompressed_bytes = 0;
$total_compressed_bytes = 0;
$failures = 0;

SEED_LOOP: for($i = 0; $i < $iters; $i++){

	$seed = int(rand(0xffff_ffff)); #choose a pseudo-random number as seed
	$hex_seed = dec2hex($seed);
	$file_name_base = "$work_dir/$bif_name-$hex_seed";

	$xxxx_command = $xxxx_commandline . " -s $seed -o $work_dir/$bif_name -no_output -sim_trace phy -no_rpt";
	$display_i = $i + 1;
	tc_print("XXXX commandline ($display_i of $iters): $xxxx_command");

	open TRACE_FILE, ">$file_name_base.trace";
	open(FOO,"$xxxx_command|");
	while(<FOO>){
		#print $_;
		print TRACE_FILE $_;
		if( /assert:/ ){
			tc_print("XXXX asserted:");
			print $_;
			clean_up();
			$failures++;
			if($failures >= $failure_threshold){
				tc_print("$failure_threshold errors, exiting...");
				close TRACE_FILE;
				close FOO;
				exit;
			}
			close TRACE_FILE;
			close FOO;
			next SEED_LOOP;
		}
		elsif( /Failed to create/ or #inelegant, but it works
			/Inconsistent memory access/ or
			/Segmentation fault/){
			tc_print("XXXX failed:");
			print $_;
			clean_up();
			$failures++;
			if($failures >= $failure_threshold){
				tc_print("$failure_threshold errors, exiting...");
				close TRACE_FILE;
				close FOO;
				exit;
			}
			close TRACE_FILE;
			close FOO;
			next SEED_LOOP;
		}
		elsif( /\.bif\([0-9]+\):/ or
			/Invalid Command Line Option/ or
			/Cannot open/){ #If XXXX complains about a bif or commandline switch error... 
			tc_print("Bias file or commandline error:");
			print $_;
			clean_up();
			close TRACE_FILE;
			close FOO;
			exit;
		}
	}

	close TRACE_FILE;
	close(FOO);

	$file_size = get_file_size("$file_name_base.trace");
	$total_uncompressed_bytes += $file_size;

	`bzip2 -z $file_name_base.trace`;

	$file_size = get_file_size("$file_name_base.trace.bz2");
	$total_compressed_bytes += $file_size;

	`rm -f $file_name_base.trace.bz2`;

}

$incompressibility_ratio = $total_compressed_bytes / $total_uncompressed_bytes;
if($incompressibility_ratio =~ /\./){
	$incompressibility_ratio =~ /([0-9]+\.[0-9]{5})/;
	$incompressibility_ratio = $1;
}
$normalized_incompressibility_ratio = $incompressibility_ratio / $normalizing_constant;
if($normalized_incompressibility_ratio =~ /\./){
	$normalized_incompressibility_ratio =~ /([0-9]+\.[0-9]{5})/;
	$normalized_incompressibility_ratio = $1;
}
print "Total uncompressed bytes: $total_uncompressed_bytes\n";
print "Total compressed bytes: $total_compressed_bytes\n";
print "Incompressibility ratio: $incompressibility_ratio\n";
print "Normalized Incompressibility Ratio (NIR): $normalized_incompressibility_ratio\n";

#Convert decimal to hexadecimal
sub dec2hex {

	my $dec_val = $_[0];
	return sprintf("%x",$dec_val);
	
}

sub get_file_size{

	my $file_name = shift;

	my $file_size = `ls -l $file_name`;
	$file_size =~ /\S+\s+\S+\s+\S+\s+\S+\s+([0-9]+)/;
	return $1;

}

sub clean_up{

	if(-e "$file_name_base.trace.bz2"){
		`rm -f $file_name_base.trace.bz2`;
	}
	if(-e "$file_name_base.trace"){
		`rm -f $file_name_base.trace`;
	}

}

sub tc_print{
	$message = shift;
	print "TRACE_COMPRESS|\t$message\n";
}

format HELP_MSG =

Usage: trace_compress.pl <xxxx_commandline>

    trace_compress generates a seed with XXXX, using the the -sim_trace phy 
    switch and saves the XXXXXXX trace output to a file. Then, it compresses
    the trace file using bzip2. The less random the instruction stream, register
    access patterns, memory addresses and data patterns are, the more redundancy 
    there will be in the trace output, and the further the trace can be 
    compressed.
    
    trace_compress dumps out the cumulative "incompressibility ratio" over all 
    seeds run (including byte totals for uncompressed and compressed file 
    sizes). The "incompressibility" of the seed can be thought of as the kernel
    of randomness in the seed.
    
    The default bias file has an overall incompressibility ratio right around
    12.5% (as of XXXX 0.15ag). Since most of this compression is due to the 
    inefficiencies of ASCII encoding and repetitive formatting characters in 
    XXXXXXX's trace output, this value is normalized to 1.0. The normalized 
    incompressibility ratio can (NIR) be thought of as the "randomness relative 
    to the default  bias file."

    incompressibility_ratio = compressed_bytes / uncompressed_bytes
    NIR = incompressibility_ratio / 0.125

    Note that the NIR *can* be greater than 1.0 - i.e. some bias files can be
    "more random" than the default bias file (I have a bif that does just this).

    To measure the NIR over 1000 seeds, just pass -n 1000 on the XXXX 
    commandline to trace_compress.pl. If you want trace_compress.pl to ignore
    a certain number of failures (due to assert rate, etc.), just pass the 
    -dont_exit_on_assert <#> switch on XXXX's commandline, where <#> is the
    number of failures you want trace_compress.pl to ignore before exiting.

.
