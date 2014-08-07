#!/usr/bin/perl -w

# Author: Clayton Bauman
# License: BSD

# REDACTED

# Name: embdec.pl "Error Message Block Decoder"
# Notes: This script was last fresh @ XXXX trunk.10
# This is a quick-and-dirty script, it is not 'use strict' compliant

package Decoder::XXXX::Error_Block; # Don't pollute the global namespace...

while($#ARGV>-1){
    $arg = shift @ARGV;
    for($arg){
        /^-h$/ and help();
        /^-o$/ and $output_file = shift, next;
        $error_info_log = $arg; #default argument assumed to be name of ErrorInfo.log
    }
}

if(defined $error_info_log){
    open ERROR_INFO_LOG, $error_info_log;
    @error_info_file = <ERROR_INFO_LOG>;
    close ERROR_INFO_LOG;

    # Find the Error_Block, then split it into individual bytes and store in @error_block
    $error_info_file = lc( join('', @error_info_file) );
    ($error_block) = $error_info_file =~ /\[Error_Block[^\]]+\]([^\]]+)\[/i;
}
else{
    #assume the user is sending the file to us on STDIN if they did not give a file name
    @error_info_file = <>;
    $error_block = lc( join('', @error_info_file) );
}

if(defined $output_file){
    open OUTPUT, ">$output_file";
}
else{
    *OUTPUT = STDOUT;
}

$error_block =~ s/^\s+//; # chomp any leading whitespace...
@error_block = split /\s+/, $error_block;

die "Usage: embdec.pl <Error Info Log file name>\n" if $#error_block < 0;
die "Please provide the entire Error Message Block" if ( $error_block[$#error_block] ne "fe");

# Get the iteration on which the seed failed
$iter = little2bigendian( @error_block[$ITER_FIELD_FIRST_BYTE..$ITER_FIELD_LAST_BYTE] );

# Get and display the error code (or not)
$err_code = $error_block[$ERROR_CODE_BYTE_INDEX];

if(exists $MESSAGES{$err_code}){
    print OUTPUT "Iteration: $iter\n";
    print OUTPUT $MESSAGES{$err_code};
    print OUTPUT "ERROR_CODE: $err_code\n";
}
else{
    print "Unrecognized error code: $err_code\n";
    print "0xff usually implies a test hang" if $err_code eq "ff";
    die;
}

for ($err_code) #For non-Perl folks, this block acts like a C-style switch statement
{
    /01/ and io_mismatch_dec(\@error_block), last;
    /02/ and mem_mismatch_dec(\@error_block), last;
    /03/ and setup_exc_dec(\@error_block), last;
    /04/ and missed_exc_dec(\@error_block), last;
    /05/ and mce_prior_dec(\@error_block), last;
    /06/ and mce_this_dec(\@error_block), last;
    /07/ and lt_join_code_dec(\@error_block), last;
    /08/ and print_unexpected_exc(decode_unexpected_exc(\@error_block)), last;
    /09/ and print_vmexit_error(decode_vmexit_error(\@error_block)), last;
    /0a/ and print_reg_mismatch(decode_reg_mismatch(\@error_block)), last;
    /0b/ and print "TSS Miscompare\n", last; #print_tss_miscompare(decode_tss_miscompare(\@error_block)), last;
    /0d/ and print "USB Miscompare\n", last; #print_usb_miscompare(decode_usb_miscompare(\@error_block)), last;
    /0e/ and print "ZZZZZ Load Error\n", last; #print_aztec_load_error(decode_aztec_load_error(\@error_block)), last;
    /0c/ and print "Eventless APIC Error\n", last; #print_eventless_apic_error(decode_eventless_apic_error(\@error_block)), last;
}

#// 0xb   TSS Miscompare Error - If a TASK-GATE type exception handler detected a value miscompare in TSS.
#// 0xd   USB Miscompare Error - If either USBx for OUT transactions, Self Compare for IN transactions, or HC detected an error
#// 0xe   ZZZZZ Load Validation Error - ZZZZZ cards detected error in load transactions 
#// 0xc   EventlessApicTimer check failure. There are two types of checks:
#//                               1.  CCR countdown check: two successive reads of ccr implies that CCR1 > CCR2.
#//                               1.  Timer inactive check: When timer is inactive CCR and TSC_Deadline should be 0.
#// 0x20   User-defined final completion code error.  This is user-code specific.

#// U8 TSS_MISCOMPARE_VECTOR_NUM 
#// U32 TSS_MISCOMPARE_TSS_BASE 
#// U32 TSS_MISCOMPARE_MISMATCH_ADDR 
#//
#// For USB miscompare related errors, the following info will be reported:
#// U8 USB_MISCOMPARE_ERROR_CODE       = 0x0xd
#// U8 SUBCODE:   
#//      1:   no executed IN transactions 
#//      2:   USBx reporting error for OUT transactions 
#//      3:   Self Compare mismatch for IN transactions 
#//      4:   HC reports error in some iTD 
#// U32 Supplementary data 
#//      1:   zero 
#//      2:   USBx error counter 
#//      3:   mismatched transaction address 
#//      4:   iTD status address 
#//
#// For ZZZZZ load validation related errors, the following info will be reported:
#// U8   ZZZZZ_LD_VALIDATION_ERROR   = 0xe
#// U32  OUTPUT_STREAM_NUMBER        = 0x1
#// U32  FRAME_NUMBER                = 0x5
#// U32  SAMPLE_NUMBER               = 0x9
#// U32  EXPECTED_DATA               = 0xd
#// U32  ACTUAL_DATA                 = 0x11
#// For EventlessApicTime rerrors, the following info will be reported:
#// U8   ERROR_CODE         = 0xc
#// U8   THREAD_NUM         = Failing thread
#// U8   SUB_ERROR_CODES:
#//      1. CCR_COUNTDOWN_CHECK: 0x1
#//         U32   CCR1 = first CCR read
#//         U32   CCR2 = second CCR read
#//      2. TIMER_INACTIVE_CHECK: 0x2
#//         (Indicate that CCR or TSC_Deadline is differ than 0 while the timer is inactive)
#

close OUTPUT;

# This is a little utility function that swizzles the bytes from little endian 
# order (as stored in the ErrorInfo.log file) to big endian order
sub little2bigendian{
    my $big_endian = "";
    $big_endian = $_ . $big_endian foreach (@_);
    return $big_endian;
}

#// U8    ERROR_CODE         = 1
#// U16   IO_ADDRESS         = Address of the IO mismatch
#// U8    NUM_BYTES          = Number of bytes that mismatched
#// U32   EXPECTED_DATA      = Expected value at the IO location (only NUM_BYTES will be initialized)
#// U32   ACTUAL_DATA        = Actual data read from the port (only NUM_BYTES will be initialized)
#// For IO mismatches, there will be multiple entries like the one above (all IO mismatches will be reported)
#// Continue to parse the error block until the ERROR_CODE is equal to ff or fe (fe marks the end of the block)
sub io_mismatch_dec{ # NOTE: This sub is untested to my knowledge....

    while(1){
    
        @IO_ADDRESS = splice(@_, 0, 2);
        $NUM_BYTES = shift;
        @EXPECTED_DATA = splice(@_, 0, 4);
        @ACTUAL_DATA = splice(@_, 0, 4);

        $IO_ADDRESS = little2bigendian(@IO_ADDRESS);
        $EXPECTED_DATA = little2bigendian(@EXPECTED_DATA);
        $ACTUAL_DATA = little2bigendian(@ACTUAL_DATA);
        
        print OUTPUT "Address of the IO mismatch:        $IO_ADDRESS\n";
        print OUTPUT "Number of bytes that mismatched:   $NUM_BYTES\n";
        print OUTPUT "EXPECTED value at the IO location: $EXPECTED_DATA\n";
        print OUTPUT "ACTUAL data read from the port   : $ACTUAL_DATA\n";

        if($_[0] eq 'FF' or $_[0] eq 'FE' or $#_ < 0){
            last;
        }
        else{
            shift; #get rid of the error code...
        }

    }

}

sub    mem_mismatch_dec{
    print OUTPUT "Memory mismatch... check the .res file for details.\n";
}

#// U8    ERROR_CODE         = 3 (Fault in setup/completion code)
#// U32   STACK_DWORD_0      
#// U32   STACK_DWORD_1      
#// U32   STACK_DWORD_2      
sub setup_exc_dec{

    @STACK_DWORD_0 = splice(@_, 0, 4);
    @STACK_DWORD_1 = splice(@_, 0, 4);
    @STACK_DWORD_2 = splice(@_, 0, 4);

    $STACK_DWORD_0 = little2bigendian(@STACK_DWORD_0);
    $STACK_DWORD_1 = little2bigendian(@STACK_DWORD_1);
    $STACK_DWORD_2 = little2bigendian(@STACK_DWORD_2);
    
    print OUTPUT "STACK_DWORD_0: $STACK_DWORD_0\n";
    print OUTPUT "STACK_DWORD_1: $STACK_DWORD_1\n";
    print OUTPUT "STACK_DWORD_2: $STACK_DWORD_2\n";

}

#// For last-exception-missed case:
#// U8    ERROR_CODE         = 4
#// U8    THREAD_NUM         = Faulting thread
#// U16   LAST_HANDLER_ID    = ID to correlate to rpt file
sub missed_exc_dec{

    @THREAD_NUM = shift;
    @LAST_HANDLER_ID = splice(@_, 0, 2);

    $THREAD_NUM = little2bigendian(      @THREAD_NUM );
    $LAST_HANDLER_ID = little2bigendian( @LAST_HANDLER_ID );
    
    print OUTPUT "Faulting thread: $THREAD_NUM\n";
    print OUTPUT "ID to correlate to rpt file: $LAST_HANDLER_ID\n";

}

sub mce_prior_dec{
    print OUTPUT "Machine Check decode not supported by this script\n";
}

sub mce_this_dec{
    print OUTPUT "Machine Check decode not supported by this script\n";
}

#// U8   ERROR_CODE         = 7
#// U8   SUB_ERROR_CODES:
#//          01: Couldn't find ApicID in the table
#//          02: JoinID didn't match (an from the table is supposed to match one embedded in the code)
#// U32   Actual val: if suberror code 01 this is the apic ID; if 02 this is the joinID from the table
#// U32   Expected: if suberror code 01 this is meaningless; if 02 this is the joinID from the code
sub lt_join_code_dec{
    print OUTPUT "LT error decode not supported by this script\n";
}

#Decode unexpected exceptions
# U8    ERROR_CODE         = 8
# U8    THREAD_NUM         = Faulting thread
# U16    EXPECTED_VECTOR   = expected vector # 
# U16    ACTUAL_VECTOR     = actual vector # 
# U64   EXPECTED_EIP       = [R/E]IP of the expected fault (0 extended)
# U16   EXPECTED_CS        = CS of the expected fault
# U64   STACK_FRAME[EC]    = error code entry on the stack (if corresponds to error code pushing fault)
#                          = (all FFs if we don't think there is an error code on stack, 0 extended)
# U64   STACK_FRAME[IP]    = actual [R/E]IP from the stack (0 extended)
# U64   STACK_FRAME[CS]    = actual CS from the stack (0 extended)
sub decode_unexpected_exc {

    my $error_block  = shift;
    $_ = ();

    $_->{thread_num     } =                    $error_block->[$THREAD_NUM_BYTE_INDEX];
    $_->{expected_vector} = little2bigendian( @{$error_block}[$EXPECTED_VECTOR_FIRST  .. $EXPECTED_VECTOR_LAST] );
    $_->{actual_vector  } = little2bigendian( @{$error_block}[$ACTUAL_VECTOR_FIRST    .. $ACTUAL_VECTOR_LAST  ] );
    $_->{expected_eip   } = little2bigendian( @{$error_block}[$EXPECTED_EIP_FIRST     .. $EXPECTED_EIP_LAST   ] );
    $_->{expected_cs    } = little2bigendian( @{$error_block}[$EXPECTED_CS_FIRST      .. $EXPECTED_CS_LAST    ] );
    $_->{stack_frame_ec } = little2bigendian( @{$error_block}[$STACK_FRAME_EC_FIRST   .. $STACK_FRAME_EC_LAST ] );
    $_->{stack_frame_ip } = little2bigendian( @{$error_block}[$STACK_FRAME_IP_FIRST   .. $STACK_FRAME_IP_LAST ] );
    $_->{stack_frame_cs } = little2bigendian( @{$error_block}[$STACK_FRAME_CS_FIRST   .. $STACK_FRAME_CS_LAST-6 ] ); #Note: This is to make visual comparison easier...
                                                                                                                   #no need to zero-extend the CS
}

# Print decoded unexpected exceptions
sub print_unexpected_exc {

print OUTPUT <<"END_UNEXPECTED_EXCEPTION_DECODE";
Faulting thread: $_->{                                                            thread_num}
EXPECTED vector #: $_->{                                                          expected_vector}
ACTUAL   vector #: $_->{                                                          actual_vector}
error code entry on the stack (if corresponds to error code pushing fault): $_->{ stack_frame_ec}
EXPECTED CS of faulting instr: $_->{                                              expected_cs}
ACTUAL   CS of faulting instr: $_->{                                              stack_frame_cs}
EXPECTED [R/E]IP of faulting instr: $_->{                                         expected_eip}
ACTUAL   [R/E]IP of faulting instr: $_->{                                         stack_frame_ip}
END_UNEXPECTED_EXCEPTION_DECODE

}

# Decode VMExit errors
# U8 VMEXIT_ERROR_CODE       = 9
# U8 VMEXIT_THREAD_NUM 
# U8 RESERVED 
# U32 VMEXIT_REASON_CODE 
# U64 VMEXIT_QUALIFICATION 
# U64 VMEXIT_EIP 
# U32 VMEXIT_CS_BASE 
# U32 VMFIELD_ENCODING 
# U64 VMFIELD_EXPECTED_VAL 
# U64 VMFIELD_ACTUAL_VAL 
sub decode_vmexit_error {

    my $error_block  = shift;
    $_ = ();

    $_->{thread_num          } =                    $error_block->[$THREAD_NUM_BYTE_INDEX];
    $_->{vmexit_reason_code  } = little2bigendian( @{$error_block}[$VMEXIT_REASON_CODE_FIRST   .. $VMEXIT_REASON_CODE_LAST] );
    $_->{vmexit_qualification} = little2bigendian( @{$error_block}[$VMEXIT_QUALIFICATION_FIRST .. $VMEXIT_QUALIFICATION_LAST] );
    $_->{vmexit_eip          } = little2bigendian( @{$error_block}[$VMEXIT_EIP_FIRST           .. $VMEXIT_EIP_LAST] );
    $_->{vmexit_cs_base      } = little2bigendian( @{$error_block}[$VMEXIT_CS_BASE_FIRST       .. $VMEXIT_CS_BASE_LAST] );
    $_->{vmfield_encoding    } = little2bigendian( @{$error_block}[$VMFIELD_ENCODING_FIRST     .. $VMFIELD_ENCODING_LAST] );
    $_->{vmfield_expected_val} = little2bigendian( @{$error_block}[$VMFIELD_EXPECTED_VAL_FIRST .. $VMFIELD_EXPECTED_VAL_LAST] );
    $_->{vmfield_actual_val  } = little2bigendian( @{$error_block}[$VMFIELD_ACTUAL_VAL_FIRST   .. $VMFIELD_ACTUAL_VAL_LAST] );

}

# Print decoded vmexit errors
sub print_vmexit_error {

    print OUTPUT "VMEXIT_THREAD_NUM: $_->{   thread_num}\n";
    print OUTPUT "VMEXIT_REASON_CODE: $_->{  vmexit_reason_code}";
    my $vmexit_reason_code_dec = hex($_->{   vmexit_reason_code});
    print OUTPUT " ($basic_exit_reasons{$vmexit_reason_code_dec})" if exists $basic_exit_reasons{$vmexit_reason_code_dec};
    print OUTPUT "\n";
    print OUTPUT "VMEXIT_QUALIFICATION: $_->{vmexit_qualification}\n";
    print OUTPUT "VMEXIT_EIP: $_->{          vmexit_eip}\n";
    print OUTPUT "VMEXIT_CS_BASE: $_->{      vmexit_cs_base}\n";
    print OUTPUT "VMFIELD_ENCODING: $_->{    vmfield_encoding}";
    print OUTPUT " ($vmcs_field_name{$_->{   vmfield_encoding}})" if exists $vmcs_field_name{$_->{vmfield_encoding    }};
    print OUTPUT "\n";
    print OUTPUT "VMFIELD_EXPECTED_VAL: $_->{vmfield_expected_val}\n";
    print OUTPUT "VMFIELD_ACTUAL_VAL:   $_->{vmfield_actual_val}\n";

}

# Decode register mismatch
sub decode_reg_mismatch {

    my $error_block  = shift;
    $_ = ();

    $_->{thread_num                       } =                    $error_block->[$THREAD_NUM_BYTE_INDEX];
    $_->{register_miscompare_detected_pip } = little2bigendian( @{$error_block}[$REGISTER_MISCOMPARE_DETECTED_PIP_FIRST  .. $REGISTER_MISCOMPARE_DETECTED_PIP_LAST] );
    $_->{register_type_miscomparing       } =                    $error_block->[$REGISTER_TYPE_MISCOMPARING_INDEX];
    $_->{register_index_which_miscompared } =                    $error_block->[$REGISTER_INDEX_WHICH_MISCOMPARED_INDEX];
    $_->{register_miscompare_bits_checked } = little2bigendian( @{$error_block}[$REGISTER_MISCOMPARE_BITS_CHECKED_FIRST  .. $REGISTER_MISCOMPARE_BITS_CHECKED_LAST] );
    $_->{register_miscompare_expected_data} = little2bigendian( @{$error_block}[$REGISTER_MISCOMPARE_EXPECTED_DATA_FIRST .. $REGISTER_MISCOMPARE_EXPECTED_DATA_LAST] );
    $_->{register_miscompare_actual_data  } = little2bigendian( @{$error_block}[$REGISTER_MISCOMPARE_ACTUAL_DATA_FIRST   .. $REGISTER_MISCOMPARE_ACTUAL_DATA_LAST] );

}

# Print decoded register mismatch
sub print_reg_mismatch {

    print OUTPUT "Register miscompare thread #:      $_->{     thread_num}\n";
    print OUTPUT "Register miscompare detected PIP:  $_->{   register_miscompare_detected_pip}\n";
    my $register_type = $decoded_register_type{$_->{        register_type_miscomparing}};
    print OUTPUT "Register type miscomparing:        ${            register_type}\n";
    my $register_name = $decoded_register_name->{$register_type}{$_->{register_index_which_miscompared}};
    print OUTPUT "Register index which miscompared:  ${      register_name}\n";
    print OUTPUT "Number of bits checked:            $_->{   register_miscompare_bits_checked}\n";
    print OUTPUT "Register miscompare EXPECTED data: $_->{  register_miscompare_expected_data}\n";
    print OUTPUT "Register miscompare ACTUAL data:   $_->{  register_miscompare_actual_data}\n";

}

# I used the BEGIN{} block to move the constants down to the end of the script
BEGIN{ 

# Initialize constants
%MESSAGES = (

'01' => q{IO Mismatch detected
},

'02' => q{Mismatch detected in memory
},

'03' => q{Exception detected in setup code (prior to when the idt is initialized for random code)
},

'04' => q{Last exception missed.  One or more of the last exceptions we expected to take were
                               not taken.  For instance, if three exceptions were expected
                               and the last two were not taken, then we would print out
                               this error code.
},

'05' => q{MachineCheck on prior seed - If the prior seed got an MCA error & the error bits were not cleared
                               then this seed will abort almost immediately & dump out the MCA info
                               in the MachineCheckErrorBlock
},

'06' => q{MachineCheck on this seed - If this seed got an MCA error, then the MCA information will be
                               in the MachienCheckErrorBlock
},

'07' => q{LT Join Code Error - If a thread detected an error while in LT join code.
},

'08' => q{Unexpected exception.   This happens whenever we hit an unexpected exception.  There
                               are three basic causes for this:
                               1.  We took an exception at an unexpected EIP
                               2.  We took the exception at the correct EIP, but took the wrong
                                   exception or some check failed in the handler (error code,
                                   eflags mismatch, cr2, DR6/7... note: no explicit checks for presil)
                               3.  The correct exception occurred at the correct location, but
                                   we didn't take the prior exception (skipped one).
},

'09' => q{VMExit Error - If a thread detected an error upon taking a vmexit e.g. the exit reason is incorrect
                               or one of the fields to be checksummed has the wrong value, etc.
},

'0a' => q{Register Miscompare Error - If a thread detected a register value miscompare.
},

'0xb' => q{TSS Miscompare Error - If a TASK-GATE type exception handler detected a value miscompare in TSS.
},
'0xd' => q{USB Miscompare Error - If either USBx for OUT transactions, Self Compare for IN transactions, or HC detected an error
},
'0xe' => q{ZZZZZ Load Validation Error - ZZZZZ cards detected error in load transactions 
},
'0xc' => q{EventlessApicTimer check failure. There are two types of checks:
                                 1.  CCR countdown check: two successive reads of ccr implies that CCR1 > CCR2.
                                 2.  Timer inactive check: When timer is inactive CCR and TSC_Deadline should be 0.
},
'20' => q{User-defined final completion code error.  This is user-code specific.
},

);

# Constants defining the Error Message Block fields... unfortunately, Perl doesn't have 
# anything really equivalent to a C-style #define.
#
# NOTE: These positions might change if XXXX changes the format of the Error_Block
$ITER_FIELD_FIRST_BYTE      = 0;
$ITER_FIELD_LAST_BYTE       = 3;
$ERROR_CODE_BYTE_INDEX      = 4;
$THREAD_NUM_BYTE_INDEX      = 5;

# 08 Error Code constants
$EXPECTED_VECTOR_FIRST      = 6;
$EXPECTED_VECTOR_LAST       = 7;
$ACTUAL_VECTOR_FIRST        = 8;
$ACTUAL_VECTOR_LAST         = 9;
$EXPECTED_EIP_FIRST         = 10;
$EXPECTED_EIP_LAST          = 17;
$EXPECTED_CS_FIRST          = 18;
$EXPECTED_CS_LAST           = 19;
$STACK_FRAME_EC_FIRST       = 20;
$STACK_FRAME_EC_LAST        = 27;
$STACK_FRAME_IP_FIRST       = 28;
$STACK_FRAME_IP_LAST        = 35;
$STACK_FRAME_CS_FIRST       = 36;
$STACK_FRAME_CS_LAST        = 43;

# 09 Error Code constants
$VMEXIT_REASON_CODE_FIRST   = 7;
$VMEXIT_REASON_CODE_LAST    = 10;
$VMEXIT_QUALIFICATION_FIRST = 11;
$VMEXIT_QUALIFICATION_LAST  = 18;
$VMEXIT_EIP_FIRST           = 19;
$VMEXIT_EIP_LAST            = 26;
$VMEXIT_CS_BASE_FIRST       = 27;
$VMEXIT_CS_BASE_LAST        = 30;
$VMFIELD_ENCODING_FIRST     = 31;
$VMFIELD_ENCODING_LAST      = 34;
$VMFIELD_EXPECTED_VAL_FIRST = 35;
$VMFIELD_EXPECTED_VAL_LAST  = 42;
$VMFIELD_ACTUAL_VAL_FIRST   = 43;
$VMFIELD_ACTUAL_VAL_LAST    = 50;

# 0a Error Code constants
$REGISTER_MISCOMPARE_DETECTED_PIP_FIRST   = 6;
$REGISTER_MISCOMPARE_DETECTED_PIP_LAST    = 13;
$REGISTER_TYPE_MISCOMPARING_INDEX         = 14;
$REGISTER_INDEX_WHICH_MISCOMPARED_INDEX   = 15;
$REGISTER_MISCOMPARE_BITS_CHECKED_FIRST   = 16;
$REGISTER_MISCOMPARE_BITS_CHECKED_LAST    = 17;
$REGISTER_MISCOMPARE_EXPECTED_DATA_FIRST  = 18;
$REGISTER_MISCOMPARE_EXPECTED_DATA_LAST   = 49;
$REGISTER_MISCOMPARE_ACTUAL_DATA_FIRST    = 50;
$REGISTER_MISCOMPARE_ACTUAL_DATA_LAST     = 81;

%vmcs_field_name = (
    'fffffffd' => "VMX_VMCS_REVISION_ID",
    'fffffffc' => "VMX_GUEST_PARENT_VMCS_POINTER_FULL",
    'fffffffe' => "VMX_VMCS_LAUNCH_STATE",
    'fffffff9' => "VMX_GUEST_HIDDEN_RFLAGS",
    'fffffff8' => "VMX_GUEST_HIDDEN_PND_DEBUG_EXCEPTION",
    '00000000' => "VMX_GUEST_VPID",
    '00000800' => "VMX_GUEST_ES_SELECTOR",
    '00000802' => "VMX_GUEST_CS_SELECTOR",
    '00000804' => "VMX_GUEST_SS_SELECTOR",
    '00000806' => "VMX_GUEST_DS_SELECTOR",
    '00000808' => "VMX_GUEST_FS_SELECTOR",
    '0000080a' => "VMX_GUEST_GS_SELECTOR",
    '0000080c' => "VMX_GUEST_LDTR_SELECTOR",
    '0000080e' => "VMX_GUEST_TR_SELECTOR",
    '00000c00' => "VMX_HOST_ES_SELECTOR",
    '00000c02' => "VMX_HOST_CS_SELECTOR",
    '00000c04' => "VMX_HOST_SS_SELECTOR",
    '00000c06' => "VMX_HOST_DS_SELECTOR",
    '00000c08' => "VMX_HOST_FS_SELECTOR",
    '00000c0a' => "VMX_HOST_GS_SELECTOR",
    '00000c0c' => "VMX_HOST_TR_SELECTOR",
    '00002000' => "VMX_IO_BITMAP_A_PHYPTR_FULL",
    '00002001' => "VMX_IO_BITMAP_A_PHYPTR_HIGH",
    '00002002' => "VMX_IO_BITMAP_B_PHYPTR_FULL",
    '00002003' => "VMX_IO_BITMAP_B_PHYPTR_HIGH",
    '00002004' => "VMX_MSR_BITMAP_PHYPTR_FULL",
    '00002005' => "VMX_MSR_BITMAP_PHYPTR_HIGH",
    '00002006' => "VMX_EXIT_MSR_STORE_PHYPTR_FULL",
    '00002007' => "VMX_EXIT_MSR_STORE_PHYPTR_HIGH",
    '00002008' => "VMX_EXIT_MSR_LOAD_PHYPTR_FULL",
    '00002009' => "VMX_EXIT_MSR_LOAD_PHYPTR_HIGH",
    '0000200A' => "VMX_ENTRY_MSR_LOAD_PHYPTR_FULL",
    '0000200B' => "VMX_ENTRY_MSR_LOAD_PHYPTR_HIGH",
    '0000200C' => "VMX_OSV_CVP_FULL",
    '0000200D' => "VMX_OSV_CVP_HIGH",
    '00002010' => "VMX_TSC_OFFSET_FULL",
    '00002011' => "VMX_TSC_OFFSET_HIGH",
    '00002012' => "VMX_VIRTUAL_APIC_PAGE_ADDRESS_FULL",
    '00002013' => "VMX_VIRTUAL_APIC_PAGE_ADDRESS_HIGH",
    '00002014' => "VMX_VIRTUAL_APIC_ACCESS_PAGE_ADDRESS_FULL",
    '00002015' => "VMX_VIRTUAL_APIC_ACCESS_PAGE_ADDRESS_HIGH",
    '0000201A' => "VMX_GUEST_EPT_POINTER_FULL",
    '0000201B' => "VMX_GUEST_EPT_POINTER_HIGH",
    '00002400' => "VMX_GUEST_PHYSICAL_ADDRESS_INFO_FULL",
    '00002401' => "VMX_GUEST_PHYSICAL_ADDRESS_INFO_HIGH",
    '00002800' => "VMX_GUEST_SAVED_WORKING_VMCS_POINTER_FULL",
    '00002801' => "VMX_GUEST_SAVED_WORKING_VMCS_POINTER_HIGH",
    '00002802' => "VMX_GUEST_IA32_DEBUGCTLMSR_FULL",
    '00002803' => "VMX_GUEST_IA32_DEBUGCTLMSR_HIGH",
    '00002804' => "VMX_GUEST_IA32_PAT_FULL",
    '00002805' => "VMX_GUEST_IA32_PAT_HIGH",
    '00002806' => "VMX_GUEST_IA32_EFER_FULL",
    '00002807' => "VMX_GUEST_IA32_EFER_HIGH",
    '00002808' => "VMX_GUEST_IA32_PERF_GLOBAL_CONTROL_FULL",
    '00002809' => "VMX_GUEST_IA32_PERF_GLOBAL_CONTROL_HIGH",
    '0000280a' => "VMX_GUEST_PDPTR0_FULL",
    '0000280b' => "VMX_GUEST_PDPTR0_HIGH",
    '0000280c' => "VMX_GUEST_PDPTR1_FULL",
    '0000280d' => "VMX_GUEST_PDPTR1_HIGH",
    '0000280e' => "VMX_GUEST_PDPTR2_FULL",
    '0000280f' => "VMX_GUEST_PDPTR2_HIGH",
    '00002810' => "VMX_GUEST_PDPTR3_FULL",
    '00002811' => "VMX_GUEST_PDPTR3_HIGH",
    '00002c00' => "VMX_HOST_IA32_PAT_FULL",
    '00002c01' => "VMX_HOST_IA32_PAT_HIGH",
    '00002c02' => "VMX_HOST_IA32_EFER_FULL",
    '00002c03' => "VMX_HOST_IA32_EFER_HIGH",
    '00002c04' => "VMX_HOST_IA32_PERF_GLOBAL_CONTROL_FULL",
    '00002c05' => "VMX_HOST_IA32_PERF_GLOBAL_CONTROL_HIGH",
    '00004000' => "VMX_VM_EXECUTION_CONTROL_PIN_BASED",
    '00004002' => "VMX_VM_EXECUTION_CONTROL_PROC_BASED",
    '00004004' => "VMX_EXCEPTION_BITMAP",
    '00004006' => "VMX_PAGEFAULT_ERRORCODE_MASK",
    '00004008' => "VMX_PAGEFAULT_ERRORCODE_MATCH",
    '0000400A' => "VMX_CR3_TARGET_COUNT",
    '0000400C' => "VMX_VM_EXIT_CONTROL",
    '0000400E' => "VMX_VM_EXIT_MSR_STORE_COUNT",
    '00004010' => "VMX_VM_EXIT_MSR_LOAD_COUNT",
    '00004012' => "VMX_VM_ENTRY_CONTROL",
    '00004014' => "VMX_VM_ENTRY_MSR_LOAD_COUNT",
    '00004016' => "VMX_VM_ENTRY_INTR_INFO",
    '00004018' => "VMX_VM_ENTRY_EXCEPTION_ERRORCODE",
    '0000401A' => "VMX_VM_ENTRY_INSTRUCTION_LENGTH",
    '0000401C' => "VMX_TPR_THRESHOLD",
    '0000401E' => "VMX_VM_EXECUTION_CONTROL_SECONDARY_PROC_BASED",
    '00004020' => "VMX_VM_EXECUTION_CONTROL_PREEMPTION_TIMER",
    '00004400' => "VMX_VM_INSTRUCTION_ERRORCODE",
    '00004402' => "VMX_VM_EXIT_REASON",
    '00004404' => "VMX_VM_EXIT_EXCEPTION_INFO",
    '00004406' => "VMX_VM_EXIT_EXCEPTION_ERRORCODE",
    '00004408' => "VMX_VM_EXIT_IDT_VECTOR_FIELD",
    '0000440A' => "VMX_VM_EXIT_IDT_VECTOR_ERRORCODE",
    '0000440C' => "VMX_VM_EXIT_INSTRUCTION_LENGTH",
    '0000440E' => "VMX_VM_EXIT_INSTRUCTION_INFO",
    '00004800' => "VMX_GUEST_ES_LIMIT",
    '00004802' => "VMX_GUEST_CS_LIMIT",
    '00004804' => "VMX_GUEST_SS_LIMIT",
    '00004806' => "VMX_GUEST_DS_LIMIT",
    '00004808' => "VMX_GUEST_FS_LIMIT",
    '0000480A' => "VMX_GUEST_GS_LIMIT",
    '0000480C' => "VMX_GUEST_LDTR_LIMIT",
    '0000480E' => "VMX_GUEST_TR_LIMIT",
    '00004810' => "VMX_GUEST_GDTR_LIMIT",
    '00004812' => "VMX_GUEST_IDTR_LIMIT",
    '00004814' => "VMX_GUEST_ES_ARBYTE",
    '00004816' => "VMX_GUEST_CS_ARBYTE",
    '00004818' => "VMX_GUEST_SS_ARBYTE",
    '0000481A' => "VMX_GUEST_DS_ARBYTE",
    '0000481C' => "VMX_GUEST_FS_ARBYTE",
    '0000481E' => "VMX_GUEST_GS_ARBYTE",
    '00004820' => "VMX_GUEST_LDTR_ARBYTE",
    '00004822' => "VMX_GUEST_TR_ARBYTE",
    '00004824' => "VMX_GUEST_INTERRUPTIBILITY",
    '00004826' => "VMX_GUEST_SLEEP_STATE",
    '00004828' => "VMX_GUEST_SMBASE",
    '0000482A' => "VMX_GUEST_IA32_SYSENTER_CS",
    '00004C00' => "VMX_HOST_IA32_SYSENTER_CS",
    '00006000' => "VMX_CR0_GUEST_HOST_MASK",
    '00006002' => "VMX_CR4_GUEST_HOST_MASK",
    '00006004' => "VMX_CR0_READ_SHADOW",
    '00006006' => "VMX_CR4_READ_SHADOW",
    '00006008' => "VMX_CR3_TARGET_VALUE_0",
    '0000600A' => "VMX_CR3_TARGET_VALUE_1",
    '0000600C' => "VMX_CR3_TARGET_VALUE_2",
    '0000600E' => "VMX_CR3_TARGET_VALUE_3",
    '00006400' => "VMX_VM_EXIT_QUALIFICATION",
    '00006402' => "VMX_VM_EXIT_IO_RCX",
    '00006404' => "VMX_VM_EXIT_IO_RSI",
    '00006406' => "VMX_VM_EXIT_IO_RDI",
    '00006408' => "VMX_VM_EXIT_IO_RIP",
    '0000640A' => "VMX_VM_EXIT_IO_INSTRUCTION_INITIAL_ADDRESS",
    '00006800' => "VMX_GUEST_CR0",
    '00006802' => "VMX_GUEST_CR3",
    '00006804' => "VMX_GUEST_CR4",
    '00006806' => "VMX_GUEST_ES_BASE",
    '00006808' => "VMX_GUEST_CS_BASE",
    '0000680A' => "VMX_GUEST_SS_BASE",
    '0000680C' => "VMX_GUEST_DS_BASE",
    '0000680E' => "VMX_GUEST_FS_BASE",
    '00006810' => "VMX_GUEST_GS_BASE",
    '00006812' => "VMX_GUEST_LDTR_BASE",
    '00006814' => "VMX_GUEST_TR_BASE",
    '00006816' => "VMX_GUEST_GDTR_BASE",
    '00006818' => "VMX_GUEST_IDTR_BASE",
    '0000681A' => "VMX_GUEST_DR7",
    '0000681C' => "VMX_GUEST_RSP",
    '0000681E' => "VMX_GUEST_RIP",
    '00006820' => "VMX_GUEST_RFLAGS",
    '00006822' => "VMX_GUEST_PND_DEBUG_EXCEPTION",
    '00006824' => "VMX_GUEST_IA32_SYSENTER_ESP",
    '00006826' => "VMX_GUEST_IA32_SYSENTER_EIP",
    '00006C00' => "VMX_HOST_CR0",
    '00006C02' => "VMX_HOST_CR3",
    '00006C04' => "VMX_HOST_CR4",
    '00006C06' => "VMX_HOST_FS_BASE",
    '00006C08' => "VMX_HOST_GS_BASE",
    '00006C0A' => "VMX_HOST_TR_BASE",
    '00006C0C' => "VMX_HOST_GDTR_BASE",
    '00006C0E' => "VMX_HOST_IDTR_BASE",
    '00006C10' => "VMX_HOST_IA32_SYSENTER_ESP",
    '00006C12' => "VMX_HOST_IA32_SYSENTER_EIP",
    '00006C14' => "VMX_HOST_RSP",
    '00006C16' => "VMX_HOST_RIP",
);

%basic_exit_reasons = (
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
    46 => "GDTR/IDTR access",
    47 => "LDTR/TR access",
    48 => "EPT violation",
    49 => "EPT misconfiguration",
    50 => "INVEPT",
    51 => "RDTSCP",
    52 => "Preemption Timer Expired",
    53 => "INVLVPID",
);

%decoded_register_type = (
    '01' => 'GP reg type',
    '02' => 'XMM control reg type',
    '03' => 'XMM reg type',
    '04' => 'FP control reg type',
    '05' => 'FP reg type',
    '06' => 'EFLAGS reg type',
    '07' => 'CR2 reg type',
);

$decoded_register_name = {
    'GP reg type' => {
        '01' => 'RAX',
        '02' => 'RCX',
        '03' => 'RDX',
        '04' => 'RBX',
        '05' => 'RSP',
        '06' => 'RBP',
        '07' => 'RSI',
        '08' => 'RDI',
        '09' => 'R8',
        '0a' => 'R9',
        '0b' => 'R10',
        '0c' => 'R11',
        '0d' => 'R12',
        '0e' => 'R13',
        '0f' => 'R14',
        '10' => 'R15',
    },
    'FP control reg type' => {
        '01' => 'FCW',
        '02' => 'FSW',
    },
    'XMM control reg type' => {
        '01' => 'MXCSR',
        '02' => 'MXCSR_MASK',
    },
    'FP reg type' => {
        '00' => 'ST0',
        '01' => 'ST1',
        '02' => 'ST2',
        '03' => 'ST3',
        '04' => 'ST4',
        '05' => 'ST5',
        '06' => 'ST6',
        '07' => 'ST7',
    },
    'XMM reg type' => {
        '00' => 'XMM0',
        '01' => 'XMM1',
        '02' => 'XMM2',
        '03' => 'XMM3',
        '04' => 'XMM4',
        '05' => 'XMM5',
        '06' => 'XMM6',
        '07' => 'XMM7',
        '08' => 'XMM8',
        '09' => 'XMM9',
        '0a' => 'XMM10',
        '0b' => 'XMM11',
        '0c' => 'XMM12',
        '0d' => 'XMM13',
        '0e' => 'XMM14',
        '0f' => 'XMM15',
    },
    'EFLAGS reg type' => {
        '01' => 'EFLAGS',
    },
    'CR2 reg type' => {
        '01' => 'CR2',
    },
};

} #end of BEGIN{} block...

#// The error message block is used to dump out information about internally detected problems.
#// It is initialized with all 0xff's (except the last byte which is an 0xfe). 
#// The first four bytes are the loop count of the failure, then bytes following 
#// contains the error message information
#// in The block will be an error code.  The values are:
#// 0x1   IO Mismatch detected
#// 0x2   Mismatch detected in memory
#// 0x3   Exception detected in setup code (prior to when the idt is initialized for random code)
#// 0x4   Last exception missed.  One or more of the last exceptions we expected to take were
#//                               not taken.  For instance, if three exceptions were expected
#//                               and the last two were not taken, then we would print out
#//                               this error code.
#// 0x5   MachineCheck on prior seed - If the prior seed got an MCA error & the error bits were not cleared
#//                               then this seed will abort almost immediately & dump out the MCA info
#//                               in the MachineCheckErrorBlock
#// 0x6   MachineCheck on this seed - If this seed got an MCA error, then the MCA information will be
#//                               in the MachienCheckErrorBlock
#// 0x7   LT Join Code Error - If a thread detected an error while in LT join code.
#// 0x8   Unexpected exception.   This happens whenever we hit an unexpected exception.  There
#//                               are three basic causes for this:
#//                               1.  We took an exception at an unexpected EIP
#//                               2.  We took the exception at the correct EIP, but took the wrong
#//                                   exception or some check failed in the handler (error code,
#//                                   eflags mismatch, cr2, DR6/7... note: no explicit checks for presil)
#//                               3.  The correct exception occurred at the correct location, but
#//                                   we didn't take the prior exception (skipped one).
#// 0x9   VMExit Error - If a thread detected an error upon taking a vmexit e.g. the exit reason is incorrect
#//                               or one of the fields to be checksummed has the wrong value, etc.
#// 0xa   Register Miscompare Error - If a thread detected a register value miscompare.
#// 0xb   TSS Miscompare Error - If a TASK-GATE type exception handler detected a value miscompare in TSS.
#// 0xd   USB Miscompare Error - If either USBx for OUT transactions, Self Compare for IN transactions, or HC detected an error
#// 0xe   ZZZZZ Load Validation Error - ZZZZZ cards detected error in load transactions 
#// 0xc   EventlessApicTimer check failure. There are two types of checks:
#//                               1.  CCR countdown check: two successive reads of ccr implies that CCR1 > CCR2.
#//                               1.  Timer inactive check: When timer is inactive CCR and TSC_Deadline should be 0.
#// 0x20   User-defined final completion code error.  This is user-code specific.
#//
#// The priority of the error codes is (highest to lowest).
#// 0x3
#// 0x7
#// 0x8/0x9
#// 0x4
#// 0xa
#// 0xb
#// 0x1
#// 0x2
#// 0x5
#// 0x6 (Note: For code 5 & 6, the code will also appear in the MachineCheckErrorBlock)
#// A higher priority error code will overwrite a lower priority one.
#//
#// For error codes 0x3, 0x1, 0x9 and 0x8 there is additional data reported in the error block as shown below.
#//
#// For Unexpected exceptions:
#// U8    ERROR_CODE         = 0x8
#// U8    THREAD_NUM         = Faulting thread
#// U16   EXPECTED_VECTOR    = expected vector # 
#// U16   ACTUAL_VECTOR      = actual vector # 
#// U64   EXPECTED_EIP       = [R/E]IP of the expected fault (0 extended)
#// U16   EXPECTED_CS        = CS of the expected fault
#// U64   STACK_FRAME[EC]    = error code entry on the stack (if corresponds to error code pushing fault)
#//                          = (all FFs if we don't think there is an error code on stack, 0 extended)
#// U64   STACK_FRAME[IP]    = actual [R/E]IP from the stack (0 extended)
#// U64   STACK_FRAME[CS]    = actual CS from the stack (0 extended)
#//
#// Only one unexpected exception will be reported, if multiple threads all hit an unexpected
#// exception, only the first one will be reported.
#//
#// For last-exception-missed case:
#// U8    ERROR_CODE         = 0x4
#// U8    THREAD_NUM         = Faulting thread
#// U16   LAST_HANDLER_ID    = ID to correlate to rpt file
#//
#// For unexpected exceptions in the setup completion code, there is less data provided, since these should be very rare
#// All setup/completion code executes at ring 0 flat protected mode.  A dump of the first three dword stack entries is provided
#// Depending on the fault taken (no info provided), this may mean error-code/eip/cs, or /eip/cs/junk
#// U8    ERROR_CODE         = 0x3 (Fault in setup/completion code)
#// U32   STACK_DWORD_0      
#// U32   STACK_DWORD_1      
#// U32   STACK_DWORD_2      
#//
#// U8    ERROR_CODE         = 0x1
#// U16   IO_ADDRESS         = Address of the IO mismatch
#// U8    NUM_BYTES          = Number of bytes that mismatched
#// U32   EXPECTED_DATA      = Expected value at the IO location (only NUM_BYTES will be initialized)
#// U32   ACTUAL_DATA        = Actual data read from the port (only NUM_BYTES will be initialized)
#// For IO mismatches, there will be multiple entries like the one above (all IO mismatches will be reported)
#// Continue to parse the error block until the ERROR_CODE is equal to ff or fe (fe marks the end of the block)
#//
#//Error is detected in LT Join code (note, faults in Join code would take you to error code 3 above)
#// U8   ERROR_CODE         = 0x7
#// U8   SUB_ERROR_CODES:
#//          01: Couldn't find ApicID in the table
#//          02: JoinID didn't match (an from the table is supposed to match one embedded in the code)
#// U32   Actual val: if suberror code 01 this is the apic ID; if 02 this is the joinID from the table
#// U32   Expected: if suberror code 01 this is meaningless; if 02 this is the joinID from the code
#//
#// For vmexit related errors, the following info will be reported:
#// U8 VMEXIT_ERROR_CODE       = 0x9
#// U8 VMEXIT_THREAD_NUM 
#// U8 RESERVED 
#// U32 VMEXIT_REASON_CODE 
#// U64 VMEXIT_QUALIFICATION 
#// U64 VMEXIT_EIP 
#// U32 VMEXIT_CS_BASE 
#// U32 VMFIELD_ENCODING 
#// U64 VMFIELD_EXPECTED_VAL 
#// U64 VMFIELD_ACTUAL_VAL 
#//
#// For register miscompare related errors, the following info will be reported:
#// U8 REGISTER_MISCOMPARE_ERROR_CODE       = 0xa
#// U8 REGISTER_MISCOMPARE_THREAD_NUM 
#// U64 REGISTER_MISCOMPARE_DETECTED_PIP 
#// U8 REGISTER_TYPE_MISCOMPARING
#//          0x01: GP reg type
#//          0x02: XMM control reg type
#//          0x03: XMM reg type
#//          0x04: FP control reg type
#//          0x05: FP reg type
#//          0x06: EFLAGS reg type
#//          0x07: CR2 reg type
#//          0x08: LOW YMM reg type
#//          0x09: HIGH YMM reg type
#// U8 REGISTER_INDEX_WHICH_MISCOMPARED
#//          GP reg type
#//              0x01: RAX
#//              0x02: RCX
#//              0x03: RDX
#//              0x04: RBX
#//              0x05: RSP
#//              0x06: RBP
#//              0x07: RSI
#//              0x08: RDI
#//              0x09: R8
#//              0x0a: R9
#//              0x0b: R10
#//              0x0c: R11
#//              0x0d: R12
#//              0x0e: R13
#//              0x0f: R14
#//              0x10: R15
#//          FP control type
#//              0x01: FCW
#//              0x02: FSW
#//          XMM control type
#//              0x01: MXCSR
#//              0x02: MXCSR_MASK
#//          FP reg type
#//              0x00: ST0
#//              0x01: ST1
#//              0x02: ST2
#//              0x03: ST3
#//              0x04: ST4
#//              0x05: ST5
#//              0x06: ST6
#//              0x07: ST7
#//          XMM reg type
#//              0x00: XMM0
#//              0x01: XMM1
#//              0x02: XMM2
#//              0x03: XMM3
#//              0x04: XMM4
#//              0x05: XMM5
#//              0x06: XMM6
#//              0x07: XMM7
#//              0x08: XMM8
#//              0x09: XMM9
#//              0x0A: XMM10
#//              0x0B: XMM11
#//              0x0C: XMM12
#//              0x0D: XMM13
#//              0x0E: XMM14
#//              0x0F: XMM15
#//          YMM reg type
#//              0x00: YMM0
#//              0x01: YMM1
#//              0x02: YMM2
#//              0x03: YMM3
#//              0x04: YMM4
#//              0x05: YMM5
#//              0x06: YMM6
#//              0x07: YMM7
#//              0x08: YMM8
#//              0x09: YMM9
#//              0x0A: YMM10
#//              0x0B: YMM11
#//              0x0C: YMM12
#//              0x0D: YMM13
#//              0x0E: YMM14
#//              0x0F: YMM15
#// U16 REGISTER_MISCOMPARE_BITS_CHECKED 
#// U256 REGISTER_MISCOMPARE_EXPECTED_DATA 
#// U256 REGISTER_MISCOMPARE_ACTUAL_DATA 
#//
#// For TSS miscompare related errors, the following info will be reported:
#// U8 TSS_MISCOMPARE_ERROR_CODE       = 0xb
#// U8 TSS_MISCOMPARE_VECTOR_NUM 
#// U32 TSS_MISCOMPARE_TSS_BASE 
#// U32 TSS_MISCOMPARE_MISMATCH_ADDR 
#//
#// For USB miscompare related errors, the following info will be reported:
#// U8 USB_MISCOMPARE_ERROR_CODE       = 0x0xd
#// U8 SUBCODE:   
#//      1:   no executed IN transactions 
#//      2:   USBx reporting error for OUT transactions 
#//      3:   Self Compare mismatch for IN transactions 
#//      4:   HC reports error in some iTD 
#// U32 Supplementary data 
#//      1:   zero 
#//      2:   USBx error counter 
#//      3:   mismatched transaction address 
#//      4:   iTD status address 
#//
#// For ZZZZZ load validation related errors, the following info will be reported:
#// U8   ZZZZZ_LD_VALIDATION_ERROR   = 0xe
#// U32  OUTPUT_STREAM_NUMBER        = 0x1
#// U32  FRAME_NUMBER                = 0x5
#// U32  SAMPLE_NUMBER               = 0x9
#// U32  EXPECTED_DATA               = 0xd
#// U32  ACTUAL_DATA                 = 0x11
#// For EventlessApicTime rerrors, the following info will be reported:
#// U8   ERROR_CODE         = 0xc
#// U8   THREAD_NUM         = Failing thread
#// U8   SUB_ERROR_CODES:
#//      1. CCR_COUNTDOWN_CHECK: 0x1
#//         U32   CCR1 = first CCR read
#//         U32   CCR2 = second CCR read
#//      2. TIMER_INACTIVE_CHECK: 0x2
#//         (Indicate that CCR or TSC_Deadline is differ than 0 while the timer is inactive)
#

1

