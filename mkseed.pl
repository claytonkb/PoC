#! /usr/bin/perl -w

# Author: Clayton Bauman
# License: BSD

# REDACTED

$rand = sprintf("0x%x",int(rand(0xffffffff)));

$xxxx_cmdline=<<"END_XXXX_CMDLINE";
/nfs/pdx/disks/xxxx.mirror.1/release/Release.45/Linux/i386_linux26/bin/release/xxxx
-p hsw
-s $rand 
-yyyyyyy_def_dir /nfs/pdx/disks/xxxx.work.5/zzzzzzz/cva/tools/yyyyyyy_def/hsw/11ww21a
-workarounds /nfs/pdx/home/zzzzzzz/cva/si-bif/hsw_wrk_trunk44_11ww17a_1.wrk 
-gen_target ucode 
-interface bios 
-psmi_method no_psmi 
-no_a_cmd 
-dont_exit_on_assert 
-num_instrs 0x1000 
-gen_timeout 480
-no_rpt
END_XXXX_CMDLINE

@xxxx_cmdline = split /\n/, $xxxx_cmdline;
$xxxx_cmdline = join(' ', @xxxx_cmdline);

print STDERR "MKSEED.PL|\t$xxxx_cmdline\n";
print STDOUT $xxxx_cmdline;

