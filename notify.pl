# notify.pl
#

use strict;

my $cmd = <<'END_CMD';
nohup echo 'notify-send -i terminal "Yoohoo!"' | at 22:17
END_CMD

`$cmd`;

