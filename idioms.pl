#!/usr/bin/perl -w

# Author: Clayton Bauman
# License: BSD

# This file is not runnable
# Many of these are just copy/paste and actually incorrect

#use strict
# refs - no symbolic references, e.g. $$myref
# subs - no barewords
# vars - no undeclared variables
#turn them off carefully with "no strict"

# Pattern match capture
($type) = ($ar_byte =~ /(.)$/);

#you can store data directly in the <DATA> filehandle
@test = <DATA>;
print $_ foreach (@test); #you can reverse for's and foreach's

#This is the right way to absolutize a path:
use Cwd 'abs_path';
my $root = shift;
$root = abs_path($root);
print "$root\n";

#You can operate on list elements in a foreach and the operation sticks!
@numbers = qw{1 2 3 4 5 6 7};
$_ += 1 foreach(@numbers);
print "@numbers\n";

#Note that for is a synonym to foreach:
@numbers = qw{1 2 3 4 5 6 7};
$_ += 1 for(@numbers); #<-- possibly less clear, though takes up less space...
print "@numbers\n";

#use $`<$&>$' to debug regex mismatches
$_ = "This is a string\n";
if (/is (\w+) (\w+)/) {
	print "$`<$&>$'\n";
}

#grep, map, foreach
@odds = grep { $_ % 2 } @ints;

@squares = map { $_ * $_} @ints;

#The output list doesn't need to be the same length as the input
#list:
%squares = map { $_, $_ * $_ } @ints;
# or
%squares = map { $_ => $_ * $_ } @ints;

#Don't use map or grep in a void context
map { $_ *= $_ } @ints; #<--- No-No

#Use foreach instead
foreach (@ints) { $_ *= $_ };
#or
$_ *= $_ foreach @ints;

#Interesting uses of Perl booleans:
@ARGV == 2 or print<<"USAGE";	#Note the here-doc idiom...
Must pass two arguments!
USAGE

process($_) if /match/
print 'debug message' if $DEBUG
&usage unless @ARGV == 2
print "$. : $_" while <FILE>
$_ *= $_ foreach @ints

# Quoting
# Customary  Generic        Meaning          Interpolates
# ''         q{}            Literal          no
# ""         qq{}           Literal          yes
# ``         qx{}           Command          yes*
#            qw{}           Word list        no
# //         m{}            Pattern match    yes*
#            qr{}           Pattern          yes*
#            s{}{}          Substitution     yes*
#            tr{}{}         Transliteration  no (but see below)
#            <<EOF          here-doc         yes*  
#* unless the delimiter is ''.

#The following escape sequences are available in constructs that interpolate and in transliterations. 
#
#    \t		tab             (HT, TAB)
#    \n		newline         (NL)
#    \r		return          (CR)
#    \f		form feed       (FF)
#    \b		backspace       (BS)
#    \a		alarm (bell)    (BEL)
#    \e		escape          (ESC)
#    \033	octal char	(example: ESC)
#    \x1b	hex char	(example: ESC)
#    \x{263a}	wide hex char	(example: SMILEY)
#    \c[		control char    (example: ESC)
#    \N{name}	named Unicode character

# qq// allows you to choose your own quote characters
print qq(<img src="$file"
width="100" height="50">);
$text = "text";
$text = qq[some $text];
$text = qq<some $text>;
$text = qq{some $text};
$text = qq!some $text!;
$text = qq/some $text/;
$text = qq#some $text#;
#etc.

#also works for q :
$text = q[some text];
$text = q!some text!;
# Also works for s///, m// and tr///
$text =~ s(something)[something else];
$text =~ m|/a/directory/name|;
$text =~ tr=A-Z=a-z=;

#The qw// operator splits a string on whitespace and single
#quotes each element
@days = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');
#same as:
@days = qw(Sun Mon Tue Wed Thu Fri Sat);

#The Schwartzian Transform
@data_out =
map { $_->[1] }
sort { $a->[0] cmp $a->[0] }
map { [func($_), $_] } @data_in;

sub mysub{
	$args = { @_ }; #Use named arguments
	print $args->{arg_name};
}

sub mysub{
	my ($text, $cols_count, $want_centering) = @_; #a relatively clean way to retrieve unnamed arguments
}# ^^^^ Note that you can 'my' all the variables at once...

#for as switch
for ($animal){
	/camel/     and Humps(2), last;
	/dromedary/ and Humps(1), last;
}

#use a local block to undef $/ and then slurp an entire file into a scalar:
{
	local $/;
	undef $/;
	$everything = <FILE_HANDLE>
}

#equivalently:
$everything = join('', <FILE_HANDLE>);

#References:
# Put \ in front of a variable name
$scalar_ref = \$scalar;
$array_ref = \@array;
$hash_ref = \%hash;

# Can now treat it just like any other scalar
$var = $scalar_ref;
$refs[0] = $array_ref;
$another_ref = $refs[0];

# It's also possible to create references to anonymous variables
#(similar to allocating memory using malloc in C)

# Create a reference to an anonymous array using 
#[ ... ]
$arr = [ 'an', 'anon', 'array' ];

# Create a reference to an anonymous hash using
#{ ... }
$hash = { 1 => 'an', 2 => 'anon', 3 => 'hash' };

#copying the thing-itself:
@arr = (1, 2, 3, 4);
$aref1 = \@arr;
$aref2 = [@arr];
print "$aref1 $aref2";
# Output:
#ARRAY(0x20026800)
#ARRAY(0x2002bc00)
# Second method creates a copy of the array

#Bitwise String Operators 
#Bitstrings of any size may be manipulated by the bitwise operators (~ | & ^).
#
#If the operands to a binary bitwise op are strings of different sizes, | and 
#^ ops act as though the shorter operand had additional zero bits on the right, 
#while the & op acts as though the longer operand were truncated to the length 
#of the shorter. The granularity for such extension or truncation is one or more bytes.

# ASCII-based examples
print "j p \n" ^ " a h";        	# prints "JAPH\n"
print "JA" | "  ph\n";          	# prints "japh\n"
print "japh\nJunk" & '_____';   	# prints "JAPH\n";
print 'p N$' ^ " E<H\n";		# prints "Perl\n";If you are intending to manipulate bitstrings, be certain that you're supplying bitstrings: If an operand is a number, that will imply a numeric bitwise operation. You may explicitly show which type of operation you intend by using "" or 0+ , as in the examples below.

$foo =  150  |  105;	# yields 255  (0x96 | 0x69 is 0xFF)
$foo = '150' |  105;	# yields 255
$foo =  150  | '105';	# yields 255
$foo = '150' | '105';	# yields string '155' (under ASCII)    $baz = 0+$foo & 0+$bar;	# both ops explicitly numeric
$biz = "$foo" ^ "$bar";	# both ops explicitly stringy

#Binary "x" is the repetition operator. In scalar context or if the left operand 
#is not enclosed in parentheses, it returns a string consisting of the left 
#operand repeated the number of times specified by the right operand. In list 
#context, if the left operand is enclosed in parentheses or is a list formed by 
#qw/STRING/, it repeats the list. If the right operand is zero or negative, it 
#returns an empty string or an empty list, depending on the context. 
print '-' x 80;		# print row of dashes    
print "\t" x ($tab/8), ' ' x ($tab%8);	# tab over    
@ones = (1) x 80;		# a list of 80 1's
@ones = (5) x @ones;	# set all elements to 5

my %hash;
@hash{@_} = (undef) x @_; #What the hell does this do?

#Range operator:
#Binary ".." is the range operator, which is really two different operators 
#depending on the context. In list context, it returns a list of values 
#counting (up by ones) from the left value to the right value. If the left value 
#is greater than the right value then it returns the empty list. The range 
#operator is useful for writing foreach (1..10) loops and for doing slice 
#operations on arrays. In the current implementation, no temporary array is 
#created when the range operator is used as the expression in foreach loops, 
#but older versions of Perl might burn a lot of memory when you write 
#something like this:

for (1 .. 1_000_000) {
# code
}

#The range operator also works on strings, using the magical auto-increment, see below.

#As a scalar operator:

if (101 .. 200) { print; } # print 2nd hundred lines, short for
						   #   if ($. == 101 .. $. == 200) ...    next LINE if (1 .. /^$/);  # skip header lines, short for
						   #   ... if ($. == 1 .. /^$/);
						   # (typically in a loop labeled LINE)    s/^/> / if (/^$/ .. eof());  # quote body    # parse mail messages
while (<>) {
	$in_header =   1  .. /^$/;
	$in_body   = /^$/ .. eof;
	if ($in_header) {
		# ...
	} else { # in body
		# ...
	}
} continue {
	close ARGV if eof;             # reset $. each file
}

#Here's a simple example to illustrate the difference between the two range operators:

@lines = ("   - Foo",
		  "01 - Bar",
		  "1  - Baz",
		  "   - Quux");    foreach (@lines) {
	if (/0/ .. /1/) {
		print "$_\n";
	}
}

#This program will print only the line containing "Bar". If the range operator is 
#changed to ... , it will also print the "Baz" line.

#And now some examples as a list operator:

for (101 .. 200) { print; }	# print $_ 100 times
@foo = @foo[0 .. $#foo];	# an expensive no-op
@foo = @foo[$#foo-4 .. $#foo];	# slice last 5 items

#The range operator (in list context) makes use of the magical auto-increment 
#algorithm if the operands are strings. You can say

@alphabet = ('A' .. 'Z');

#to get all normal letters of the English alphabet, or

$hexdigit = (0 .. 9, 'a' .. 'f')[$num & 15];

#to get a hexadecimal digit, or

@z2 = ('01' .. '31');  print $z2[$mday];

#to get dates with leading zeros.

#If the final value specified is not in the sequence that the magical increment 
#would produce, the sequence goes until the next value would be longer than the 
#final value specified.

#If the initial value specified isn't part of a magical increment sequence (that 
#is, a non-empty string matching "/^[a-zA-Z]*[0-9]*\z/"), only the initial value 
#will be returned. So the following will only return an alpha:

use charnames 'greek';
my @greek_small =  ("\N{alpha}" .. "\N{omega}");

#To get lower-case greek letters, use this instead:

my @greek_small =  map { chr } ( ord("\N{alpha}") .. ord("\N{omega}") );

#Because each operand is evaluated in integer form, 2.18 .. 3.14 will return two elements in list context.

@list = (2.18 .. 3.14); # same as @list = (2 .. 3);

sub rand_lc { return ('a'..'z')[int(rand(0xffff))%26] }

#reserved characters in formats:
format RESERVED =
@ <--- this will print as an actual @ <--- and so will this
"@", "@"
.

#escaping $ in here-docs:
print <<"NO_INTERPOLATION";
\$var <--- the \$ will not interpolate...
NO_INTERPOLATION

#Useful Standard Modules
#- constant - Creates constant values
#- File::Copy - Copy files
#- Time::Local - Convert times to epoch
#- POSIX - Interface to POSIX
#- Text::Parsewords - Parse words from text
#- CGI - CGI applications
#- Getopt::Std - Process command line options
#- Carp - Better warn and die
#- Cwd - Current working directory
#- Benchmark - Timing code

#- File::Basename - Break up filenames
($name,$path,$suffix) = fileparse($fullname,@suffixlist);
$name = fileparse($fullname,@suffixlist);
$basename = basename($fullname,@suffixlist);
$dirname  = dirname($fullname);

#- Data::Dumper - Dump data to text
print Dumper($myref);

#Useful Non-Standard Modules
#- Template - Insert data in boilerplate text
#- DBI - Database access
#- libnet - Various network protocols (e.g. Net::FTP)
#- Time::Piece - Date/Time manipulation
#- libwww - HTTP client library
#- Number::Format - Formatting numbers
#- HTML::Parser - Parsing HTML
#- XML::Parser - Parsing XML
#- Text::CSV - Parse CSV data
#- Regexp::Common - Common regular expressions
#- MIME::Lite - Creating and sending MIME emails
#- Memoize - Cache function return values

#common routines

sub dec2hex { return sprintf("%x",shift) }

sub dec2bin { return sprintf("%b",shift) }

sub bin2dec { return unpack("N", pack("B32", substr("0" x 32 . shift, -32))) }

sub hexdigit{ #$place is bigendian, so the 0th hex digit is the right-most hex digit...
	my $hexval = dec2hex(shift);
	my $place = shift;
	return (0 .. 9, 'a' .. 'f')[$hexval >> ($place*4) & 0xf];
}

sub bitfield{ #big endian... rightmost bit is LSB
	my $binval = dec2bin(shift);
	(my $msb, my $lsb) = @_;
	$binval = reverse $binval;
	$return_val = reverse (substr($binval, $lsb, ($msb-$lsb+1)));
	return $return_val;
}

sub hexfield{ #big endian... rightmost hex digit is least-significant
	my $hexval = dec2hex(shift);
	(my $msh, my $lsh) = @_;
	$hexval = reverse $hexval;
	$return_val = reverse(substr($hexval, $lsh, ($msh-$lsh+1)));
	return $return_val;
}

# Absolutize a directory.
sub abs_dir { #Note: Do not use this, use the Cwd idiom above...
	my $dir = `pwd`;
	# Check that the directory exists.
	if (!(-e $_[0])) {
		die "$_[0] does not exist.\n";
	}
	chdir $_[0];
	$_ = `pwd`;
	chop($_);
	chdir $dir;
	return $_;
}

# Absolutize a file
sub abs_file {#Note: Do not use this, use the Cwd idiom above...
	$_[0] =~ /[^\/]+$/;
	$filename = $&;
	if($filedir = $`){
		$filedir = abs_dir($filedir);
	}
	else{
		$filedir = `pwd`;
		chop($filedir);
	}
	$_ = "$filedir/$filename";
	return $_;
}

#This are included for completeness...
##bin2dec:
#$out = unpack("N", pack("B32", substr("0" x 32 . $in, -32))); 
# 
##bin2hex:
#$out = unpack("H8", pack("B32", substr("0" x 32 . $in, -32))); 
# 
##bin2oct:
#$out = sprintf "%o", unpack("N", pack("B32", substr("0" x 32 . $in, -32))); 
# 
##dec2bin:
#$out = unpack("B*", pack("N", $in));
# 
##dec2hex:
#$out = unpack("H8", pack("N", $in));
# 
##dec2oct:
#$out = sprintf "%o", $in;
# 
##hex2bin:
#$out = unpack("B32", pack("N", hex $in));
# 
##hex2dec:
#$out = hex $in;
# 
##hex2oct:
#$out = sprintf "%o", hex $in;
# 
##oct2bin:
#$out = unpack("B32", pack("N", oct $in));
# 
##oct2dec:
#$out = oct $in;
# 
##oct2hex:
#$out = unpack("H8", pack("N", oct $in));

#Flexible command-line arg I/O processing:
while($#ARGV>-1){
    $arg = shift @ARGV;
    for($arg){
        /^-h$/ and help();
        /^-o$/ and $output_file = shift, next;
        $input_file = $arg; #default argument assumed to be name of ErrorInfo.log
    }
}

if(defined $input_file){
    open INPUT_FILE, $input_file or die "Couldn't open $input_file $!\n";
    @input_file = <INPUT_FILE>;
    close INPUT_FILE;
}
else{
    #assume the user is sending the file to us on STDIN if they did not give a file name
    @intput_file = <>;
}

if(defined $output_file){
    open OUTPUT, ">$output_file";
}
else{
    *OUTPUT = *STDOUT{IO};
}

__DATA__

testing

This is a line.

Done testing
