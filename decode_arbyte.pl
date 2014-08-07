#!/usr/bin/perl -w

# Author: Clayton Bauman
# License: BSD

# A little x86 AR-byte decoder...

%system_types = (
	'1' => "Available 16-Bit TSS",
	'2' => "LDT",
	'3' => "Busy 16-Bit TSS",
	'4' => "Call Gate 16-Bit",
	'5' => "Task Gate",
	'6' => "Interrupt Gate 16-Bit",
	'7' => "Trap Gate 16-Bit",
	'9' => "Available 32-Bit TSS",
	'b' => "Busy 32-Bit TSS",
	'c' => "Call Gate 32-Bit",
	'e' => "Interrupt Gate 32-Bit",
	'f' => "Trap Gate 32-Bit",
);

$ar_byte = shift;
($type) = ($ar_byte =~ /(.)$/);
$type = lc($type);

$G = nth_bit($ar_byte, 15);
$DB = nth_bit($ar_byte, 14);
$L = nth_bit($ar_byte, 13);
$AVL = nth_bit($ar_byte, 12);
$P = nth_bit($ar_byte, 7);
$DPL1 = nth_bit($ar_byte, 6);
$DPL0 = nth_bit($ar_byte, 5);
$S = nth_bit($ar_byte, 4);
$Type3 = nth_bit($ar_byte, 3);
$Type2 = nth_bit($ar_byte, 2);
$Type1 = nth_bit($ar_byte, 1);
$Type0 = nth_bit($ar_byte, 0);

if($S){
	if($Type3){
		$~ = CODE_AR_BYTE;
	}
	else{
		$~ = DATA_AR_BYTE;
	}
	write;
}
else{
	$~ = AR_BYTE;
	write;
	print "\nType: $system_types{$type}\n";
}

format AR_BYTE =
                
  D   A         
  /   V         
G B L L P DPL S Type  
------------------------
@ @ @ @ @ @ @ @ @ @ @ @
$G, $DB, $L, $AVL, $P, $DPL1, $DPL0, $S, $Type3, $Type2, $Type1, $Type0
.

format DATA_AR_BYTE =
                
  D   A         
  /   V         Type
G B L L P DPL S   E W A
------------------------
@ @ @ @ @ @ @ @ @ @ @ @
$G, $DB, $L, $AVL, $P, $DPL1, $DPL0, $S, $Type3, $Type2, $Type1, $Type0
.

format CODE_AR_BYTE =
                
  D   A         
  /   V         Type
G B L L P DPL S   C R A 
------------------------
@ @ @ @ @ @ @ @ @ @ @ @
$G, $DB, $L, $AVL, $P, $DPL1, $DPL0, $S, $Type3, $Type2, $Type1, $Type0
.

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
