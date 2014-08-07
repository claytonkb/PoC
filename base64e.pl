#!/usr/local/bin/perl -w

# Author: Clayton Bauman
# License: BSD

# The 'e' stands for "ECC-compatible"
 
# binary       ASCII  [5:0]
# --------------------------------
# 0100 0000    '@'    0
# 0100 0001    'A'    1
# 0100 0010    'B'    2
# 0100 0011    'C'    3
# 0100 0100    'D'    4
# 0100 0101    'E'    5
# 0100 0110    'F'    6
# 0100 0111    'G'    7
# 0100 1000    'H'    8
# 0100 1001    'I'    9
# 0100 1010    'J'    10
# 0100 1011    'K'    11
# 0100 1100    'L'    12
# 0100 1101    'M'    13
# 0100 1110    'N'    14
# 0100 1111    'O'    15
# 0101 0000    'P'    16
# 0101 0001    'Q'    17
# 0101 0010    'R'    18
# 0101 0011    'S'    19
# 0101 0100    'T'    20
# 0101 0101    'U'    21
# 0101 0110    'V'    22
# 0101 0111    'W'    23
# 0101 1000    'X'    24
# 0101 1001    'Y'    25
# 0101 1010    'Z'    26
# 0101 1011    '['    27
# 0101 1100    '\'    28
# 0101 1101    ']'    29
# 0101 1110    '^'    30
# 0101 1111    '_'    31
# 0110 0000    '`'    32
# 0110 0001    'a'    33
# 0110 0010    'b'    34
# 0110 0011    'c'    35
# 0110 0100    'd'    36
# 0110 0101    'e'    37
# 0110 0110    'f'    38
# 0110 0111    'g'    39
# 0110 1000    'h'    40
# 0110 1001    'i'    41
# 0110 1010    'j'    42
# 0110 1011    'k'    43
# 0110 1100    'l'    44
# 0110 1101    'm'    45
# 0110 1110    'n'    46
# 0110 1111    'o'    47
# 0111 0000    'p'    48
# 0111 0001    'q'    49
# 0111 0010    'r'    50
# 0111 0011    's'    51
# 0111 0100    't'    52
# 0111 0101    'u'    53
# 0111 0110    'v'    54
# 0111 0111    'w'    55
# 0111 1000    'x'    56
# 0111 1001    'y'    57
# 0111 1010    'z'    58
# 0111 1011    '{'    59
# 0111 1100    '|'    60
# 0111 1101    '}'    61
# 0111 1110    '~'    62
# 0011 1111    '?'    63
#
# The "padding" is accomplished by misaligning the length, any characters can be used to pad.
# '@' is recommended as a standard pad character:
#

# To pad (encoding):
#
# If length(plaintext_message) % 3 = 0, no padding
# If length(plaintext_message) % 3 = 1, append any character to encoded message
# If length(plaintext_message) % 3 = 2, append any two characters to encoded message

# To unpad (decoding):
#
# If length(plaintext_message) % 4 = 0, no padding
# If length(plaintext_message) % 4 = 1, remove last two characters
# If length(plaintext_message) % 4 = 2, remove last character

$arg = shift;
if($arg eq "-d"){
    @test_array = split q{}, shift;
    $_ = ord($_)+0 for @test_array;
    #printf("%02x ", $_) for @test_array;
    #print "\n";
    @test_array = dec_base64e(@test_array);
#    printf("%08b ", $_) for @test_array;
#    print "\n";
    print chr($_) for @test_array;
    print "\n";
}
else{
    @test_array = split q{}, $arg;
    $_ = ord($_)+0 for @test_array;
    #printf("%02x ", $_) for @test_array;
    #print "\n";
    @test_array = enc_base64e(@test_array);
#    printf("%02x ", $_) for @test_array;
    #   print "\n";
    print chr($_) for @test_array;
    print "\n";
}

sub dec_base64e{
    @raw_array = @_;
    $discard = ($#raw_array+1) % 4;
    die "Bad encoding, length mod 4 = 3\n" if $discard == 3;
    pop @_ for (1..$discard);
    $_ &= 0x3f for @raw_array;
    $dec_array_index = 0;
    for($i=0;$i<=$#_;$i+=4){
        $dec_array[$dec_array_index  ] = ( $raw_array[$i  ]         << 2) + (($raw_array[$i+1] & 0x30) >> 4);
        $dec_array[$dec_array_index+1] = (($raw_array[$i+1] & 0x0f) << 4) + (($raw_array[$i+2] & 0x3c) >> 2);
        $dec_array[$dec_array_index+2] = (($raw_array[$i+2] & 0x03) << 6) +   $raw_array[$i+3]              ;
        $dec_array_index+=3;
    }
    pop @dec_array for (1..$discard);
    return @dec_array;
}

sub enc_base64e{
    @raw_array = @_;
    $alignment = ($#raw_array+1) % 3;
#    print "\$#raw_array: $#raw_array\n";
    #   print "\$alignment: $alignment\n";
    if($alignment){
        push @raw_array, 0 for (1..(3-$alignment)); #pad with zeros to 3-align
    }
    die "\@raw_array length not 3-aligned\n" if (($#raw_array+1) % 3) != 0;
    $enc_array_index = 0;
    for($i = 0; $i < $#raw_array; $i+=3){
        $enc_array[$enc_array_index  ] = (($raw_array[$i  ] & 0xfc) >> 2)                           ;
        $enc_array[$enc_array_index+1] = (($raw_array[$i  ] & 0x03) << 4) + (($raw_array[$i+1] & 0xf0) >> 4);
        $enc_array[$enc_array_index+2] = (($raw_array[$i+1] & 0x0f) << 2) + (($raw_array[$i+2] & 0xc0) >> 6);
        $enc_array[$enc_array_index+3] =   $raw_array[$i+2] & 0x3f                                  ;
        $enc_array_index+=4;
    }
    for(@enc_array){
        $_ |= 0x40;
        $_ = 0x3f if $_ == 0x7f;
    }
    if($alignment){
        push @enc_array, ord('@') for (1..(3-$alignment));
    }
    return @enc_array;
}

