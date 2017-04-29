#!/usr/bin/perl

use strict;
use MIME::Base64;
use Compress::Zlib;
use Encode;

my $file = join '', <>;

my @file = split //, $file;
for my $char (@file){
if($char !~ /\n/){
    $char = chr(ord($char)-1);
}
}
$file = join '', @file;

$file = decode("UTF-8", uncompress( decode_base64($file)));
print "$file";

