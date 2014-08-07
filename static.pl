#!/usr/bin/perl -w

# Author: Clayton Bauman
# License: BSD

# hiworld - "Hello World" with a Button and implicit class bindings. 

use Tk;

my ( $size, $step ) = ( 1000, 10 );

# Create MainWindow and configure:
my $mw = MainWindow->new;
$mw->configure( -width=>$size, -height=>$size );
$mw->resizable( 0, 0 ); # not resizable in any direction

my $button = $mw->Button(-text => 'Redraw', -command => \&redraw)->pack(-side => 'bottom'); 

# Create and configure the canvas:
my $canvas = $mw->Canvas( -cursor=>"crosshair", -background=>"white",
              -width=>$size, -height=>$size )->pack;

## Place objects on canvas:
#$canvas->createRectangle( $step, $step, $size-$step, $size-$step, -fill=>"red" );

$outline = "#808080";

for( my $i=$step; $i<$size-$step; $i+=$step ) {
	for( my $j=$step; $j<$size-$step; $j+=$step ) {
#	  $rand = int( rand( 0xfff )) % 2;
#	  if($rand){
#		  $color = "#000000";
#	  }
#	  else{
#		  $color = "#ffffff";
#	  }
	  for($k = 0; $k < 3; $k++){
		  $val[$k] = int( rand( 0x7fff ));
		  $val[$k] &= 0xff;
	  }
	  $color = sprintf( "#%02x%02x%02x", $val[0], $val[1], $val[2] );
	  $id = $canvas->createRectangle( $i, $j, $i+$step, $j+$step, -fill=>$color, -outline=>$outline);
	  push @id_list, $id;
	}
}

MainLoop;


sub redraw{

	foreach $id (@id_list) {

	  $rand = int( rand( 0xffff_ffff ));
	  $rand &= 1;
	  if($rand){
		  $color = "#000000";
	  }
	  else{
		  $color = "#ffffff";
	  }
#		for($k = 0; $k < 3; $k++){
#		  $val[$k] = int( rand( 0xffff_ffff));
#		  $val[$k] &= 0xff;
#		}
#		$color = sprintf( "#%02x%02x%02x", $val[0], $val[1], $val[2] );
		$canvas->itemconfigure($id, -fill => $color );

	}

}

