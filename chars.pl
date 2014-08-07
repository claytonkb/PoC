#!/usr/bin/perl -w

# Author: Clayton Bauman
# License: BSD

# No comment on what this does or why...

@char_list = ("!", "@", "#", "\$", "%", "^", "&", "*", "(", ")", "-", "_", "+", "=", "{", "}", "[", "]", "|", "\\", ":", ";", "\"", "'", "<", ">", ".", ",", "/", "?", "I", "O", "V", "L", "C", "X", "U", "T");

for($k = 0; $k <= $#char_list; $k++){
for($i = 0; $i <= $#char_list; $i++){

	for($j = 0; $j <= $#char_list; $j++){

		print "$char_list[$k]$char_list[$i]$char_list[$j] ";

	}

}
}
