#!/usr/bin/perl

use strict;
use MIME::Base64;
use Compress::Zlib;
use Encode;

my $file = join '', <>;

$file = encode_base64(compress(encode("UTF-8", $file)));

my @file = split //, $file;
for my $char (@file){
if($char !~ /\n/){
    $char = chr(ord($char)+1);
}
}
$file = join '', @file;

print $file;

