#!/usr/bin/perl -w

# Author: Clayton Bauman
# License: BSD

#Locates all fields of a VMCS and prints them in list format (ala vmcs.def file)
#and gives plain English summary of important VMCS data.

#print <<"USAGE" if $#ARGV < 0;
#Usage vmcs2xml.pl <vmcs_def_file> <memdump_file>
#
#	<vmcs_def_file> should be the corresponding yyyyyyy VMCS .def file 
#	<memdump_file> should contain a memdump of the VMCS
#
#	The script will accept a memdump from either ITP or yyyyyyy - it assumes the
#	first hex value on each line is an address and allows an optional colon or
#	ITP-style memtype suffix (P, L, etc.)
#USAGE

exit if $#ARGV < 0;

read_def_file($ARGV[0]);
read_memdump_file($ARGV[1]);

foreach (sort keys %vmcs_offset){
	@vmcs_field_bytes = ();
	$vmcs_field_offset = $vmcs_offset{$_};
	for($i = 0; $i < $vmcs_field_size{$_}; $i++){
		push @vmcs_field_bytes, $dump_file_bytes[$vmcs_field_offset+$i];
	}
	$vmcs_field_bytes = little2bigendian(@vmcs_field_bytes);
	$~ = vmcs_field;
	write unless $_ =~ /_HIGH$/;
}

sub little2bigendian{

	my $i;
	my $big_endian = "";

	$big_endian = $_ . $big_endian foreach (@_);

	return $big_endian;

}

#Map vmcs offset to vmcs field name and vmcs offset to field size and vmcs field
#name to vmcs offset
sub read_def_file{
	open DEF_FILE, shift or die "Couldn't open VMCS def file: $!\n";
	@def_file_lines = <DEF_FILE>;
	close DEF_FILE;
	foreach (@def_file_lines){
		($vmcs_field_name, $vmcs_encoding, $vmcs_offset, $byte_size) = split /\s+/, $_;
		$vmcs_field_encoding{$vmcs_field_name} = $vmcs_encoding;
		$vmcs_field_hex_offset{$vmcs_field_name} = $vmcs_offset;
		$vmcs_field_size{$vmcs_field_name} = $byte_size;
		$vmcs_offset{$vmcs_field_name} = hex($vmcs_offset);
	}
	$vmcs_encoding = 1; #suppress the stupid warning...
}

sub read_memdump_file{
	open DUMP_FILE, shift or die "Couldn't open memdump file: $!\n";
	@dump_file_lines = <DUMP_FILE>;
	close DUMP_FILE;
	for(my $i = 0; $i <= $#dump_file_lines; $i++){
#		chomp $dump_file_lines[$i];
		$dump_file_lines[$i] =~ s/^\w+\s+(:\s+)?//;
	}
	$dump_file_lines = join ' ', @dump_file_lines;
	@dump_file_bytes = split /\s+/, $dump_file_lines;
}

format vmcs_field =
#VMX_VM_EXECUTION_CONTROL_SECONDARY_PROC_BASED     		0000401E	0124	<value>
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<	@<<<<<<<<	@<<<<	@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$_,	$vmcs_field_encoding{$_}, $vmcs_field_hex_offset{$_}, $vmcs_field_bytes
.
