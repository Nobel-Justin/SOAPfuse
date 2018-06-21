package SOAPfuse::SVG_Radian_System_Elements;

use strict;
use warnings;
use Math::Trig;
use List::Util qw[min max sum];
use SOAPfuse::SVG_Radian_System qw/$PI $deg2rad get_coordinate_on_circle/;
use SOAPfuse::SVG_Font qw/show_text_on_arc/;
require Exporter;

#----- systemic variables -----
our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
my ($VERSION, $DATE, $AUTHOR, $EMAIL, $MODULE_NAME);
@ISA = qw(Exporter);
@EXPORT = qw($PI $deg2rad %COLOR_DB draw_circle_seg get_coordinate_on_circle);
push @EXPORT , qw();
@EXPORT_OK = qw($PI $deg2rad %COLOR_DB);
%EXPORT_TAGS = ( DEFAULT => [qw()],
                 OTHER   => [qw()]);

$MODULE_NAME = 'SVG_Radian_System_Elements';
#----- version --------
$VERSION = "0.26";
$DATE = '2018-04-16';

#----- author -----
$AUTHOR = 'Wenlong Jia';
$EMAIL = 'wenlongkxm@gmail.com';

# url: http://www.december.com/html/spec/colorsvg.html
our %COLOR_DB=(
				1=>'blue',    2=>'lime',     3=>'gold',      4=>'tomato',     5=>'purple',
				6=>'brown',   7=>'green',    8=>'orange',    9=>'skyblue',   10=>'pink',
			   11=>'orchid', 12=>'darkred', 13=>'seagreen', 14=>'chocolate', 15=>'tan',

			   dark_col=>'blue|brown|green|purple|chocolate|darkred'

			 );

#--------- functions in this pm --------#
my @functoion_list = (
						'draw_circle_seg', # It can also draw an arc when inner_radius == outer_radius
						'draw_a_sector'
					 );

#-------- Draw a radian segment on the circle --------#
#-------- Check Usage in the codes ------#
# It can also draw an arc when inner_radius == outer_radius
sub draw_circle_seg{

	my $sub_routine_name = "draw_circle_seg";

	my $Usage = '

                                            outer

                  (x2,y2)                  #2 side                      (x3,y3)
                      o___________________________________________________o
             #1 side  \                                                  /  #3 side
                       \o______________________________________________o/
                  (x1,y1)                                               (x4,y4)
                                           #4 side

                                            inner

                                              o (centre)


		Use as subroutine($SVG_object, key1=>value1, key2=>value2, ...);

		# Options key, enclosed by [ ] means default
		--- basic structure ---
		# cx, [100]
		# cy, [100]
		# start_rad, [0]
		# rad_size, [3.1415926]
		# inner_radius, [100]
		# outer_radius, [120]
		--- appearance ---
		# seg_fill_color, ["none"]
		# seg_boundary_color, ["black"]
		# seg_boundary_width, [1], 2, 3
		# seg_boundary_linecap, ["round"]
		# seg_side_bold, ["0"], "1", "2", "3", "4"
		#          Note:  accepts strings, multiple dealing, such as "1", "1,2"
		#                 0, means no side needs to make bold
		#                 1, means clockwise left side  #1,  bold line from (x1,y1) to (x2,y2)
		#                 2, means the outer radian arc #2, bold arc line from (x2,y2) to (x3,y3)
		#                 3, means clockwise right side #3, bold line from (x3,y3) to (x4,y4)
		#                 4, means the inner radian arc #4, bold arc line from (x4,y4) to (x1,y1)
		# seg_side_bold_width, [3]
		# seg_side_bold_opacity, [1]
		# seg_opacity, [1]
		# draw_bool, [1]
		            Sometimes, user may want just pre-calculate some values for displaying adjustment, set this option as
		            zero will disable the SVG drawing.
		--- arrow ---
		# arrow_num, [0], 1, 2, 3 ...
		# arrow_color, ["gray"]
		# arrow_ori, ["clockwise"] or "anti-clockwise"
		# arrow_span_perct, [9]
		# arrow_maxArcLen, [optional]
		# arrow_draw_only, [0]
		            Only show arrow.
		--- text ---
		# text, [""]
		# font_family, ["Arial"]
		# font_size, [12]
		# text_col, ["black"]
		# text_to_center, ["toe"]
		                You can also use "top", "disabled".
		# text_rotate_degree, [0]
		# text_features, [{}]
		            This option accepts a Hash ref stores features for sub-strings. It allows the following attributes.
		            "font_family", "font_size", "text_col", "text_to_center", "text_rotate_degree"
		            use it like this, features=>{ "text_col"=>{"red"=>[1,3], "green"=>[4]}, "text_to_center"=>{"top"=>[2,4]} }
		            Notes:
		                  1) Once set "font_size" via this option, "xxx_limit" will not work for the related sub-char(s).
		                  2) The numbers ("1,3", "4") are the index of the text string to refer specific sub-char(s).
		                     It starts from "1", not "0" (PLEASE pay attentions to this point). BLANK will be counted.
		--- help ----
		# usage_print, [0]

		Use options in anonymous hash, like
		   subroutine( $SVG_object, cx=>120, cy=>120 );

		Note: It can also draw an arc when inner_radius equals to outer_radius.

	';

	# options
	shift if ($_[0] =~ /::$MODULE_NAME/);
	my $SVG_object = shift @_;
	my %parm = @_;
	my $Options_Href = \%parm;

	if(!defined($SVG_object) || $Options_Href->{usage_print}){
		warn "\nThe Usage of $sub_routine_name:\n";
		warn "$Usage";
		warn "\n";
		exit(1);
	}

	# Defaults
	## circle
	my $cx 				= $Options_Href->{cx} || 100;
	my $cy 				= $Options_Href->{cy} || 100;
	## segment structure
	my $start_rad 		= $Options_Href->{start_rad} || 0;
	my $rad_size 		= $Options_Href->{rad_size} || $PI;
	my $inner_radius	= $Options_Href->{inner_radius} || 100;
	my $outer_radius 	= $Options_Href->{outer_radius} || 120;
	## segment appearance
	my $seg_fill_col 	= $Options_Href->{seg_fill_color} || 'none';
	my $seg_opacity		= (defined $Options_Href->{seg_opacity}) ? $Options_Href->{seg_opacity} : 1;
	my $seg_boud_color 	= $Options_Href->{seg_boundary_color} || 'black';
	my $seg_boud_width 	= $Options_Href->{seg_boundary_width} || 1;
	my $seg_boud_linecap= $Options_Href->{seg_boundary_linecap} || 'round';
	my $seg_bold_side	= $Options_Href->{seg_side_bold} || '0';
	my $seg_bolds_width	= $Options_Href->{seg_side_bold_width} || 3;
	my $seg_side_bold_opacity = (defined $Options_Href->{seg_side_bold_opacity}) ? $Options_Href->{seg_side_bold_opacity} : 1;
	my $draw_bool       = (defined($Options_Href->{draw_bool})) ? $Options_Href->{draw_bool} : 1;
	## arrows
	my $arrow_num 		= $Options_Href->{arrow_num} || 0;
	my $arrow_span_pt 	= $Options_Href->{arrow_span_perct} || 9;
	my $arrow_maxArcLen = $Options_Href->{arrow_maxArcLen};
	my $arrow_color		= $Options_Href->{arrow_color} || 'gray';
	my $arrow_ori		= $Options_Href->{arrow_ori} || 'clockwise';
	my $arrow_draw_only = $Options_Href->{arrow_draw_only} || 0;
	## text
	my $text = $Options_Href->{text} || '';
	my $font_family = $Options_Href->{font_family} || 'Arial';
	my $font_size   = $Options_Href->{font_size} || 12;
	my $text_col = $Options_Href->{text_col} || 'black';
	my $text_rotate_degree = $Options_Href->{text_rotate_degree} || 0;
	my $text_to_center	= $Options_Href->{text_to_center} || 'toe';
	my $text_features_Href = defined($Options_Href->{text_features}) ? $Options_Href->{text_features} : {};

	#---- Segment
	# pos
	my ($x1,$y1) = get_coordinate_on_circle(cx=>$cx, cy=>$cy, rad=>$start_rad, radius=>$inner_radius); # inner
	my ($x2,$y2) = get_coordinate_on_circle(cx=>$cx, cy=>$cy, rad=>$start_rad, radius=>$outer_radius); # outer
	my ($x3,$y3) = get_coordinate_on_circle(cx=>$cx, cy=>$cy, rad=>($start_rad + $rad_size), radius=>$outer_radius); # outer
	my ($x4,$y4) = get_coordinate_on_circle(cx=>$cx, cy=>$cy, rad=>($start_rad + $rad_size), radius=>$inner_radius); # inner
	# flag
	my $flag_1 = ($rad_size > $PI) ? 1 : 0;

	# if just an arc, when inner_radius == outer_radius
	if($inner_radius == $outer_radius){
		# path
		my $path = "$x2,$y2,A$outer_radius,$outer_radius,0,$flag_1,1,$x3,$y3";
		$$SVG_object->path(
							d=>$path,
							stroke=>$seg_boud_color,
							'stroke-width'=>$seg_boud_width,
							'stroke-linecap'=>$seg_boud_linecap,
							fill=>'none',
							opacity=>$seg_opacity
					      ) if($draw_bool);
		return;
	}

	# path
	my $path = "M$x1,$y1,L$x2,$y2,A$outer_radius,$outer_radius,0,$flag_1,1,$x3,$y3,L$x4,$y4,A$inner_radius,$inner_radius,0,$flag_1,0,$x1,$y1";
	# confirm stroke-width
	my $bool = 1;
	$bool = $bool && ($seg_bold_side =~ /$_/) for (1 .. 4);
	if($bool){ # once all sides need to be bold.
		$seg_boud_width = $seg_bolds_width;
		$seg_bold_side = '0'; # pretend no need to be bold again.
	}
	$$SVG_object->path(
						d=>$path,
						stroke=>$seg_boud_color,
						'stroke-width'=>$seg_boud_width,
						fill=>$seg_fill_col,
						opacity=>$seg_opacity
					  ) if($draw_bool && !$arrow_draw_only);
	# bold sides
	if($seg_bold_side !~ /^0$/){
		# sharing style
		my $style_Href = {
							stroke=>$seg_boud_color,
							'stroke-linecap'=>'round',
							'stroke-width'=>$seg_bolds_width,
							opacity=>$seg_side_bold_opacity
						 };
		# index vs array
		my @pos_pool = ([$x2,$y2], [$x3,$y3], [$x4,$y4], [$x1,$y1]);
		# draw line or arc
		for my $single_bold_side (split //,$seg_bold_side){
			next if($single_bold_side !~ /^[1234]$/); # only one digital number, allow 1,2,3,4
			my ($x_1,$y_1) = @{$pos_pool[$single_bold_side-2]};
			my ($x_2,$y_2) = @{$pos_pool[$single_bold_side-1]};
			if($single_bold_side =~ /1|3/){ # line
				$$SVG_object->line(
									x1=>$x_1,y1=>$y_1,
									x2=>$x_2,y2=>$y_2,
									style=>$style_Href
								  ) if($draw_bool);
			}
			elsif($single_bold_side =~ /2|4/){ # arc
				my ($radius,$flag_2) = ($single_bold_side==2) ? ($outer_radius,1) : ($inner_radius,0); # clockwise or anti-clockwise
				my $path = "M$x_1,$y_1,A$radius,$radius,0,$flag_1,$flag_2,$x_2,$y_2";
				$$SVG_object->path(
									d=>$path,
									fill=>'none',
									style=>$style_Href
								  ) if($draw_bool);
			}
		}
	}

	# Arrows
	if($arrow_num != 0){

		$Usage = '         (x7,y7)
							 _o_
							/   \
						   /  o  \  <- (x8,y8)
						  /  / \  \
	             (x6,y6) o__/   \__o (x5,y5)
		';

		my $radius_p78 = ($inner_radius + $outer_radius) / 2;
		my $arrow_span_rad = min( $rad_size * $arrow_span_pt / 100 , acos($inner_radius/$radius_p78) / 2 );
		   $arrow_span_rad = min( $arrow_span_rad, $arrow_maxArcLen / $radius_p78 ) if( defined $arrow_maxArcLen );
		my $arrow_inner_span_rad = $arrow_span_rad / 2;
		my $arrow_rad_step = $rad_size * int(100 / ($arrow_num+1)) / 100;
		# draw arrow
		for my $i (1 .. $arrow_num){
			my $radian_p56 = $start_rad + $i * $arrow_rad_step;
			my $radian_p7  = $radian_p56 + $arrow_span_rad * (($arrow_ori eq 'clockwise')?1:-1);
			my $radian_p8  = $radian_p56 + $arrow_inner_span_rad * (($arrow_ori eq 'clockwise')?1:-1);
			my ($x5,$y5) = get_coordinate_on_circle(cx=>$cx, cy=>$cy, rad=>$radian_p56, radius=>$inner_radius); # inner
			my ($x6,$y6) = get_coordinate_on_circle(cx=>$cx, cy=>$cy, rad=>$radian_p56, radius=>$outer_radius); # outer
			my ($x7,$y7) = get_coordinate_on_circle(cx=>$cx, cy=>$cy, rad=>$radian_p7,  radius=>$radius_p78); # middle
			my ($x8,$y8) = get_coordinate_on_circle(cx=>$cx, cy=>$cy, rad=>$radian_p8,  radius=>$radius_p78); # middle
			my $path = "M$x5,$y5,L$x8,$y8,L$x6,$y6,L$x7,${y7}Z";
			$$SVG_object->path(
								d=>$path,
								stroke=>'none',
								fill=>$arrow_color
							  ) if($draw_bool); # stroke-width'=>1
		}
	}

	# text
	if(length($text) != 0){
		show_text_on_arc(
							$SVG_object,
							cx=>$cx,
							cy=>$cy,
							radius=>($inner_radius + $outer_radius) / 2,
							anchor_degree=>($start_rad + $rad_size / 2) / $deg2rad,
							text_anchor=>'middle',
							text=>$text,
							font_family=>$font_family,
							font_size=>$font_size,
							text_col=>$text_col,
							height_adjust=>1,
							height_limit=>(0.8 * ($outer_radius - $inner_radius)),
							degree_limit=>(0.8 * $rad_size / $deg2rad),
							text_to_center=>$text_to_center,
							text_rotate_degree=>$text_rotate_degree,
							features=>$text_features_Href,
							draw_bool=>$draw_bool
						);
	}
}

#-------- Draw a sector --------#
#-------- Check Usage in the codes ------#
sub draw_a_sector{

	my $sub_routine_name = "draw_a_sector";

	my $Usage = '

            (x1,y1)    #2 side   (x2,y2)
               o___________________o
                \                 /
                 \               /
                  \             /
                   \           /
                #1  \         / #3
               side  \       / side
                      \     /
                       \   /
                        \ /
                         o  (cx,cy)
                      (centre)


		Use as subroutine($SVG_object, key1=>value1, key2=>value2, ...);

		# Options key, enclosed by [ ] means default
		--- basic structure ---
		# cx, [100]
		# cy, [100]
		# start_rad, [0]
		# rad_size, [3.1415926]
		# radius, [100]
		--- appearance ---
		# seg_fill_color, ["none"]
		# seg_boundary_color, ["black"]
		# seg_boundary_width, [1], 2, 3
		# seg_side_bold, ["0"], "1", "2", "3"
		#          Note:  accepts strings, multiple dealing, such as "1", "1,2"
		#                 0, means no side needs to make bold
		#                 1, means clockwise left side #1,  bold line from (x1,y1) to (cx,cy)
		#                 2, means the radian arc #2, bold arc line from (x1,y1) to (x2,y2)
		#                 3, means clockwise right side #3, bold line from (x2,y2) to (cx,cy)
		# seg_side_bold_width, 3
		# seg_opacity, [1]
		# draw_bool, [1]
		            Sometimes, user may want just pre-calculate some values for displaying adjustment, set this option as
		            zero will disable the SVG drawing.
		--- help ---
		# usage_print, [0]

		Use options in anonymous hash, like
		   subroutine( $SVG_object, cx=>120, cy=>120 );

	';

	# options
	shift if ($_[0] =~ /::$MODULE_NAME/);
	my $SVG_object = shift @_;
	my %parm = @_;
	my $Options_Href = \%parm;

	if(!defined($SVG_object) || $Options_Href->{usage_print}){
		warn "\nThe Usage of $sub_routine_name:\n";
		warn "$Usage";
		warn "\n";
		exit(1);
	}

	# Defaults
	## circle
	my $cx 				= $Options_Href->{cx} || 100;
	my $cy 				= $Options_Href->{cy} || 100;
	## segment structure
	my $start_rad 		= $Options_Href->{start_rad} || 0;
	my $rad_size 		= $Options_Href->{rad_size} || $PI;
	my $radius			= $Options_Href->{radius} || 100;
	## segment appearance
	my $seg_fill_col 	= $Options_Href->{seg_fill_color} || 'none';
	my $seg_opacity		= (defined $Options_Href->{seg_opacity}) ? $Options_Href->{seg_opacity} : 1;
	my $seg_boud_color 	= $Options_Href->{seg_boundary_color} || 'black';
	my $seg_boud_width 	= $Options_Href->{seg_boundary_width} || 1;
	my $seg_bold_side	= $Options_Href->{seg_side_bold} || '0';
	my $seg_bolds_width	= $Options_Href->{seg_side_bold_width} || 3;
	my $draw_bool       = (defined($Options_Href->{draw_bool})) ? $Options_Href->{draw_bool} : 1;

	#--- Sector
	# pos
	my ($x1,$y1) = get_coordinate_on_circle(cx=>$cx, cy=>$cy, rad=>$start_rad, radius=>$radius);
	my ($x2,$y2) = get_coordinate_on_circle(cx=>$cx, cy=>$cy, rad=>($start_rad + $rad_size), radius=>$radius);
	# flag
	my $flag_1 = ($rad_size > $PI) ? 1 : 0;
	my $flag_2 = 1; # clockwise
	# path
	my $path = "M$cx,$cy,L$x1,$y1,A$radius,$radius,0,$flag_1,$flag_2,$x2,$y2,L$cx,$cy";
	# confirm stroke-width
	my $bool = 1;
	$bool = $bool && ($seg_bold_side =~ /$_/) for (1 .. 3);
	if($bool){ # once all sides need to be bold.
		$seg_boud_width = $seg_bolds_width;
		$seg_bold_side = '0'; # pretend no need to be bold again.
	}
	# draw sector
	$$SVG_object->path(
						d=>$path,
						stroke=>$seg_boud_color,
						'stroke-width'=>$seg_boud_width,
						fill=>$seg_fill_col,
						opacity=>$seg_opacity
					  ) if($draw_bool);
	# bold sides
	if($seg_bold_side !~ /^0$/){

		# sharing style
		my $style_Href = {
							stroke=>$seg_boud_color,
							'stroke-width'=>$seg_bolds_width,
							opacity=>$seg_opacity
						 };
		# index vs array
		my @pos_pool = ([$x1,$y1], [$x2,$y2], [$cx,$cy]);
		# draw line or arc
		for my $single_bold_side (split //,$seg_bold_side){
			next if($single_bold_side !~ /^[123]$/); # only one digital number, allow 1,2,3
			my ($x_1,$y_1) = @{$pos_pool[$single_bold_side-2]};
			my ($x_2,$y_2) = @{$pos_pool[$single_bold_side-1]};
			if($single_bold_side =~ /1|3/){ # line
				$$SVG_object->line(
									x1=>$x_1,y1=>$y_1,
									x2=>$x_2,y2=>$y_2,
									style=>$style_Href
								  ) if($draw_bool);
			}
			elsif($single_bold_side =~ /2/){ # arc
				my $path = "M$x_1,$y_1,A$radius,$radius,0,$flag_1,$flag_2,$x_2,$y_2";
				$$SVG_object->path(
									d=>$path,
									fill=>'none',
									style=>$style_Href
								  ) if($draw_bool);
			}
		}
	}
}

1; ## tell the perl script the successful access of this module.
