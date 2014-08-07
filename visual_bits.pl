#! /usr/bin/perl -w

# Author: Clayton Bauman
# License: BSD

# PoC of a text-based "binary fingerprint visualization" utility,
# similar to the concept used in constructing an Identicon

my $X_WIDTH = 83;
my $Y_WIDTH = 31;
my $current_x = int($X_WIDTH/2);
my $current_y = int($Y_WIDTH/2);

my $field = [];
for($i=0; $i<$Y_WIDTH; $i++){
    for($j=0; $j<$X_WIDTH; $j++){
        $field->[$j][$i] = ' ';
    }
}

my $bits = shift;
my $bit_length = length $bits;

push my @path;#, 'N', 'N', 'E', 'E', 'S', 'S', 'W', 'W';

for($i = 0; $i < $bit_length; $i+=4){

    $new_bits   = substr($bits, $i  , 2);
    $trans_bits = substr($bits, $i+2, 2);

    if($new_bits eq "00"){
        push @path, 'N';
    }
    elsif($new_bits eq "01"){
        push @path, 'S';
    }
    elsif($new_bits eq "10"){
        push @path, 'E';
    }
    else{#($new_bits eq "11"){
        push @path, 'W';
    }

    @new_path = @path;

    if($trans_bits eq "00"){ #reflect vertically
        for(@new_path){
            $_ = 'S' if $_ eq 'N';
            $_ = 'N' if $_ eq 'S';
        }
    }
    elsif($trans_bits eq "01"){ #reflect horizontally
        for(@new_path){
            $_ = 'E' if $_ eq 'W';
            $_ = 'W' if $_ eq 'E';
        }
    }
    elsif($trans_bits eq "10"){ #rotate left
        for(@new_path){
            $_ = 'W' if $_ eq 'N';
            $_ = 'S' if $_ eq 'W';
            $_ = 'E' if $_ eq 'S';
            $_ = 'N' if $_ eq 'E';
        }
    }
    else{#($trans_bits eq "11"){ #rotate right
        for(@new_path){
            $_ = 'E' if $_ eq 'N';
            $_ = 'N' if $_ eq 'W';
            $_ = 'W' if $_ eq 'S';
            $_ = 'S' if $_ eq 'E';
        }
    }

    push @path, @new_path

}

for(@path){

    if($_ eq 'N'){
        $current_y = ($current_y - 1) % $Y_WIDTH;
    }
    elsif($_ eq 'S'){
        $current_y = ($current_y + 1) % $Y_WIDTH;
    }
    elsif($_ eq 'E'){
        $current_x = ($current_x + 1) % $X_WIDTH;
    }
    else{#($_ eq 'W'){
        $current_x = ($current_x - 1) % $X_WIDTH;
    }

    $current_y = $Y_WIDTH-1 if $current_y < 0;
    $current_x = $X_WIDTH-1 if $current_x < 0;

    $field->[$current_x][$current_y] = '#';

}

print '+' x ($X_WIDTH+2);
print "\n";
for($i=0; $i<$Y_WIDTH; $i++){
    print '+';
    for($j=0; $j<$X_WIDTH; $j++){
        print $field->[$j][$i];
    }
    print "+\n";
}
print '+' x ($X_WIDTH+2);
print "\n";

