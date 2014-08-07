#!/usr/bin/perl -w

# Author: Clayton Bauman
# License: BSD

#Locates all fields of a VMCS and prints them in list format (ala vmcs.def file)
#and gives plain English summary of important VMCS data.

print <<"USAGE" if $#ARGV < 0;
Usage vmcs_summary.pl <vmcs_def_file> <memdump_file>

	<vmcs_def_file> should be the corresponding yyyyyyy VMCS .def file 
	<memdump_file> should contain a memdump of the VMCS

	The script will accept a memdump from either ITP or yyyyyyy - it assumes the
	first hex value on each line is an address and allows an optional colon or
	ITP-style memtype suffix (P, L, etc.)
USAGE

exit if $#ARGV < 0;

read_def_file($ARGV[0]);
read_memdump_file($ARGV[1]);

@exec_controls = (
"sw intr exiting",
"3f exiting",
"virtual interrupt pending",
"use tsc offsetting",
"task-switch exiting",
"cpuid exiting",
"getsec exiting",
"hlt exiting",
"invd exiting",
"invlpg exiting",
"mwait exiting",
"rdpmc exiting",
"rdtsc exiting",
"rsm exiting",
"vmx instr exiting",
"cr3-load exiting",
"cr3-store exiting",
"use cr3 guest/host mask",
"use cr3 read shadow",
"cr8-load exiting",
"cr8-store exiting",
"use tpr shadow",
"nmi window exiting",
"mov dr exiting",
"unconditional i/o exiting",
"activate i/o bitmaps",
"msr protection",
"mtf",
"use msr bitmaps",
"monitor exiting",
"pause exiting",
"activate secondary controls"
);

@pin_controls = (
"external interrupt mask/exit",
"host interrupt flag",
"init exiting",
"nmi control",
"sipi exiting",
"full nmi control",
"activate pre-emption timer",
);

@interruptibility = (
"sti blocking",
"mov/pop ss blocking",
"smi blocking",
"nmi blocking",
);

@exit_controls = (
"save cr0 and cr4",
"save cr3",
"save debug controls",
"save segment registers",
"save esp, eip, eflags",
"save pending debug exceptions",
"save interruptibility information",
"save activity state",
"save wkg vmcs pointer",
"host address space size",
"load cr0 and cr4",
"load cr3",
"load ia32_cr_perf_gloab_ctrl",
"load segment registers",
"load esp and eip",
"acknowledge intr on exit",
"save sysenter msrs",
"load sysenter msrs",
"don't flush on exit",
"save pat",
"load pat",
"save efer",
"load efer",
"save pre-emption timer value",
"save ia32_cr_perf_global_ctrl",
);

@exc_bitmap = (
"#de divide error exiting",
"#db debug exception exiting",
"nmi interrupt exiting",
"#bp breakpoint exiting",
"#of overflow exiting",
"#br bound range exiting",
"#ud undefined opcode exiting",
"#nm no math coprocessor exiting",
"#df double-fault exiting",
"co-processor segment overrun exiting",
"#ts invalid tss exiting",
"#np segment not present exiting",
"#ss stack segment fault exiting",
"#gp general protection fault exiting",
"#pf page fault exiting",
"reserved ",
"#mf math fault exiting",
"#ac alignment check exiting",
"#mc machine check exiting",
"#xf simd fp exception exiting",
);

@entry_controls = (
"load cr0 and cr4",
"load cr3",
"load debug controls",
"load segment registers",
"load esp, eip, eflags",
"load pending debug exceptions",
"load interruptibility info",
"load activity state",
"load valid wkg. vmcs pointer",
"long-mode guest",
"entry to smm",
"tear down smm",
"load sysenter msrs",
"load ia32_cr_perf_global_ctrl",
"don't flush on entry",
"load guest pat",
"load efer",
);

@sec_exec_controls = (
"unknown",
"enable ept",
"descriptor table exiting",
"enable rdtscp",
"shadow apic msrs",
"enable vpid",
"intercept apic accesses",
);

$_ = get_field_bytes('VMX_VM_EXECUTION_CONTROL_PROC_BASED');
for($i = 0; $i <= $#exec_controls; $i++){
	$exec_controls[$i] = uc($exec_controls[$i]) if nth_bit($_, $i);
}

$_ = get_field_bytes('VMX_VM_EXECUTION_CONTROL_PIN_BASED');
for($i = 0; $i <= $#pin_controls; $i++){
	$pin_controls[$i] = uc($pin_controls[$i]) if nth_bit($_, $i);
}

$_ = get_field_bytes('VMX_GUEST_INTERRUPTIBILITY');
for($i = 0; $i <= $#interruptibility; $i++){
	$interruptibility[$i] = uc($interruptibility[$i]) if nth_bit($_, $i);
}

$_ = get_field_bytes('VMX_VM_EXIT_CONTROL');
for($i = 0; $i <= $#exit_controls; $i++){
	$exit_controls[$i] = uc($exit_controls[$i]) if nth_bit($_, $i);
}

$_ = get_field_bytes('VMX_EXCEPTION_BITMAP');
for($i = 0; $i <= $#exc_bitmap; $i++){
	$exc_bitmap[$i] = uc($exc_bitmap[$i]) if nth_bit($_, $i);
}

$_ = get_field_bytes('VMX_VM_ENTRY_CONTROL');
for($i = 0; $i <= $#entry_controls; $i++){
	$entry_controls[$i] = uc($entry_controls[$i]) if nth_bit($_, $i);
}

$_ = get_field_bytes('VMX_VM_EXECUTION_CONTROL_SECONDARY_PROC_BASED');
for($i = 0; $i <= $#sec_exec_controls; $i++){
	$sec_exec_controls[$i] = uc($sec_exec_controls[$i]) if nth_bit($_, $i);
}

$line = "----------------------------------------------------------------------------------------------------------\n";

print "Entry Controls\n";
print $line;
print "$_\n" foreach @entry_controls;

print "\nExecution Controls\n";
print $line;
print "$_\n" foreach @pin_controls;
print "$_\n" foreach @exec_controls;
print "$_\n" foreach @sec_exec_controls;

print "\nException Bitmap\n";
print $line;
print "$_\n" foreach @exc_bitmap;

print "\nInterruption Information\n";
print $line;
interruption();

print "\nNMIs\n";
print $line;
nmi_control();

print "\nInterruptibility\n";
print $line;
print "$_\n" foreach @interruptibility;

print "\nActivity State\n";
print $line;
activity();

print "\nExit Controls\n";
print $line;
print "$_\n" foreach @exit_controls;

print "\nExit Reason\n";
print $line;
exit_reason();

print "\nVMCS\n";
print $line;

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

sub interruption{
	my %interruption_types = (
		0 => "External Interrupt",
		8 => "External Interrupt",
		1 => "Reserved",
		9 => "Reserved",
		2 => "NMI",
		10 => "NMI",
		3 => "Processor Exception",
		11 => "Processor Exception",
		4 => "Software Interrupt",
		12 => "Software Interrupt",
		5 => "Privileged Software Trap",
		13 => "Privileged Software Trap",
		6 => "Unprivileged Software Trap",
		14 => "Unprivileged Software Trap",
		7 => "Other event",
		15 => "Other event",
	);
	$_ = get_field_bytes('VMX_VM_ENTRY_INTR_INFO');
	my @nibbles = split //, $_;
	print "Interruption information not valid\n" unless nth_bit($_, 31);
	print "Vector: $nibbles[6]$nibbles[7]\n";
	my $vector_type = $interruption_types{hex($nibbles[1])};
	print "Type: $vector_type\n";
	print "Error code will be delivered" if nth_bit($_, 11);
	print "NMI unmasking due to IRET" if nth_bit($_, 12);
}

sub exit_reason{
	$_ = get_field_bytes('VMX_VM_EXIT_REASON');
	my $decval = hex($_);

	my %basic_exit_reasons = (
		0 => "Software interrupt, exception, software trap or NMI",
		1 => "External interrupt",
		2 => "Triple fault",
		3 => "INIT",
		4 => "SIPI",
		5 => "I/O SMI",
		6 => "Other SMI",
		7 => "VMXIP",
		8 => "NMIP",
		9 => "Task switch",
		10 => "CPUID",
		11 => "GETSEC",
		12 => "HLT",
		13 => "INVD",
		14 => "INVLPG",
		15 => "RDPMC",
		16 => "RDTSC",
		17 => "RSM",
		18 => "VMCALL",
		19 => "VMCLEAR",
		20 => "VMLAUNCH",
		21 => "VMPTRLD",
		22 => "VMPTRST",
		23 => "VMREAD",
		24 => "VMRESUME",
		25 => "VMWRITE",
		26 => "VMXOFF",
		27 => "VMXON",
		28 => "CR access",
		29 => "DR access",
		30 => "I/O instruction",
		31 => "MSR read",
		32 => "MSR write",
		33 => "VM-entry failure due to bad guest state",
		34 => "VM-entry failure due to bad MSR loading.",
		35 => "VM-exit failure",
		36 => "MWAIT",
		37 => "MTF",
		38 => "Corrupted VMCS",
		39 => "MONITOR",
		40 => "PAUSE",
		41 => "VM-entry failure due to machine check",
		42 => "C-State SMI",
		43 => "TPR below threshold",
		44 => "APIC access",
		45 => "GDTR/IDTR access",
		46 => "LDTR/TR access",
		47 => "EPT violation",
		48 => "EPT misconfiguration",
		49 => "INVEPT",
		50 => "INVLVPID",
		51 => "RDTSCP",
		52 => "Preemption Timer Expired",
	);

	print "Basic exit reason: $basic_exit_reasons{$decval}\n";
	print "Pending MTF exit (due to SMI)\n" if nth_bit($_, 28);
	print "VM Exit from root\n" if nth_bit($_, 29);
	print "Failed VM Exit\n" if nth_bit($_, 30);
	print "Failed VM Entry\n" if nth_bit($_, 31);

}

sub nmi_control{
	my $pin_controls = get_field_bytes('VMX_VM_EXECUTION_CONTROL_PIN_BASED');
	my $proc_controls = get_field_bytes('VMX_VM_EXECUTION_CONTROL_PROC_BASED');
	print "Guest Control\n" unless nth_bit($pin_controls, 3);
	print "Partial Host Control\n" if(nth_bit($pin_controls, 3) and !nth_bit($pin_controls, 5));
	if(nth_bit($pin_controls, 3) and nth_bit($pin_controls, 5)){
		print "Full Host Control\n";
		print "NMI-window exiting (NMIP)\n" if (nth_bit($proc_controls, 22));
	}
}

sub activity{
	my $activity_state = get_field_bytes('VMX_GUEST_SLEEP_STATE');
	for($activity_state){
		/00000000/ and print "Active\n";
		/00000001/ and print "HLT\n";
		/00000002/ and print "Shutdown\n";
		/00000003/ and print "Wait-For-SIPI\n";
		/00000004/ and print "C-state\n";
	}
}

sub nth_bit{

	my $bytes = shift;
	my $bit_place = shift;
	my @reverse_nibbles = ();
	my @nibbles = ();

	@reverse_nibbles = split //, $bytes;
	unshift @nibbles, $_ foreach @reverse_nibbles;

	my $nibble_place = int($bit_place / 4);
	my $nibble_bit_place = $bit_place % 4;

	return if !defined $nibbles[$nibble_place];

	for($nibble_bit_place){
		/0/ and $nibbles[$nibble_place] =~ /[13579bdf]/ and return "1";
		/1/ and $nibbles[$nibble_place] =~ /[2367abef]/ and return "1";
		/2/ and $nibbles[$nibble_place] =~ /[4567cdef]/ and return "1";
		/3/ and $nibbles[$nibble_place] =~ /[89abcdef]/ and return "1";
	}

	return "0";
}

sub get_field_bytes{
	my $field_name = shift;
	my @vmcs_field_bytes = ();
	my $vmcs_field_offset = $vmcs_offset{$field_name};
	for(my $i = 0; $i < $vmcs_field_size{$field_name}; $i++){
		push @vmcs_field_bytes, $dump_file_bytes[$vmcs_field_offset+$i];
	}
	return little2bigendian(@vmcs_field_bytes);
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
