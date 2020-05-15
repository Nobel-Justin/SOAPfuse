package SOAPfuse::SVG_Radian_System;

use strict;
use warnings;
use Math::Trig;
require Exporter;


#----- systemic variables -----
our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
my ($VERSION, $DATE, $AUTHOR, $EMAIL, $MODULE_NAME);
@ISA = qw(Exporter);
@EXPORT = qw($PI $deg2rad get_coordinate_on_circle normalize_radian draw_an_arc);
push @EXPORT , qw();
@EXPORT_OK = qw($PI $deg2rad);
%EXPORT_TAGS = ( DEFAULT => [qw()],
                 OTHER   => [qw()]);

$MODULE_NAME = 'SVG_Radian_System';
#----- version --------
$VERSION = "0.14";
$DATE = '2018-01-16';

#----- author -----
$AUTHOR = 'Wenlong Jia';
$EMAIL = 'wenlongkxm@gmail.com';

#--------- degree radian transform (basic) --------#
our $PI = 3.1415926;
our $deg2rad = $PI / 180;

#--------- functions in this pm --------#
my @functoion_list = (
                        'get_coordinate_on_circle',
                        'normalize_radian',
                        'draw_an_arc'
                     );

#-------- Given the centre site, radius and the related angle -------#
#--- Calculate the coordinates on the cicle in SVG coordinates system ---#
#-------- Input: $centre_x, $centre_y, $rad, $radius -------#
sub get_coordinate_on_circle{
    # options
    shift if ($_[0] =~ /::$MODULE_NAME/);
    my %parm = @_;
    my $centre_x = $parm{cx};
    my $centre_y = $parm{cy};
    my $rad      = $parm{rad}; # the radian rotated from the zero clock.
    my $radius   = $parm{radius};

    my $x = $centre_x + sin($rad) * $radius;
    my $y = $centre_y - cos($rad) * $radius;
    return ($x, $y);
}

#------- normalize the radian in [0, 2*$PI) ------#
sub normalize_radian{
    # options
    shift if ($_[0] =~ /::$MODULE_NAME/);
    my %parm = @_;
    my $object_Sref = $parm{radian_Sref};

    until($$object_Sref >= 0 && $$object_Sref < 2 * $PI){
        if($$object_Sref < 0){
            $$object_Sref += 2 * $PI;
        }
        else{
            $$object_Sref -= 2 * $PI;
        }
    }
}

#-------- Draw an arc --------#
#-------- Check Usage in the codes ------#
sub draw_an_arc{

    my $sub_routine_name = "draw_an_arc";

    my $Usage = '

                                            outer
                        o______________________________________________o
                   (x1,y1)                                              (x2,y2)
                                           #4 side

                                            inner

                                     [centre] o (cx,cy)


        Use as subroutine($SVG_object, key1=>value1, key2=>value2, ...);

        # Options key, enclosed by [ ] means default
        --- basic structure ---
        # cx, [100]
        # cy, [100]
        # start_rad, [0]
        # rad_size, [3.1415926]
        # radius, [100]
        --- appearance ---
        # boundary_color, ["black"]
        # boundary_width, [1], 2, 3
        # boundary_linecap, ["round"]
        # opacity, [1]
        # draw_bool, [1]
                    Sometimes, user may want just pre-calculate some values for displaying adjustment, set this option as
                    zero will disable the SVG drawing.
        --- help ----
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
    my $cx = $Options_Href->{cx} || 100;
    my $cy = $Options_Href->{cy} || 100;
    ## segment structure
    my $start_rad = $Options_Href->{start_rad} || 0;
    my $rad_size  = $Options_Href->{rad_size} || $PI;
    my $radius    = $Options_Href->{radius} || 100;
    ## segment appearance
    my $opacity      = (defined $Options_Href->{opacity}) ? $Options_Href->{opacity} : 1;
    my $boud_color   = $Options_Href->{boundary_color} || 'black';
    my $boud_width   = $Options_Href->{boundary_width} || 1;
    my $boud_linecap = $Options_Href->{boundary_linecap} || 'round';
    my $draw_bool    = (defined($Options_Href->{draw_bool})) ? $Options_Href->{draw_bool} : 1;

    #---- Arc
    # pos
    my ($x1,$y1) = get_coordinate_on_circle(cx=>$cx, cy=>$cy, rad=>$start_rad, radius=>$radius);
    my ($x2,$y2) = get_coordinate_on_circle(cx=>$cx, cy=>$cy, rad=>($start_rad + $rad_size), radius=>$radius);
    # flag
    my $flag_1 = ($rad_size > $PI) ? 1 : 0;

    # path
    my $path = "M$x1,$y1,A$radius,$radius,0,$flag_1,1,$x2,$y2";
    $$SVG_object->path(
                        d=>$path,
                        stroke=>$boud_color,
                        'stroke-width'=>$boud_width,
                        'stroke-linecap'=>$boud_linecap,
                        fill=>'none',
                        opacity=>$opacity
                      ) if($draw_bool);
}

1; ## tell the perl script the successful access of this module.
