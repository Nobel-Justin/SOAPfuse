package SOAPfuse::SVG_Orthogonal_System_Elements;

use strict;
use warnings;
use Math::Trig;
use List::Util qw/ min max sum /;
use SOAPfuse::SVG_Radian_System qw/ $deg2rad /;
use SOAPfuse::SVG_Font qw/ show_text_in_line /;
require Exporter;


#----- systemic variables -----
our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
my ($VERSION, $DATE, $AUTHOR, $EMAIL, $MODULE_NAME);
@ISA = qw(Exporter);
@EXPORT = qw(draw_a_parallelogram draw_a_triangle draw_a_arrow draw_a_ellipse);
push @EXPORT , qw();
@EXPORT_OK = qw();
%EXPORT_TAGS = ( DEFAULT => [qw()],
                 OTHER   => [qw()]);

$MODULE_NAME = 'SVG_Orthogonal_System_Elements';
#----- version --------
$VERSION = "0.34";
$DATE = '2018-03-04';

#----- author -----
$AUTHOR = 'Wenlong Jia';
$EMAIL = 'wenlongkxm@gmail.com';

#--------- functions in this pm --------#
my @functoion_list = (
                        'draw_a_parallelogram',
                        'draw_a_triangle',
                        'draw_a_arrow',
                        'draw_a_ellipse'
                     );


#-------- Draw a parallelogram --------#
#-------- Check Usage in the codes ------#
sub draw_a_parallelogram{

    my $sub_routine_name = "draw_a_parallelogram";

    my $Usage = '

            This is the most simple parallelogram, square.

                       head_bottom_side (#2)
            (x1,y1) o----------------------o (x2,y2)
                    | up_left_Angle        |
                    |                      |
                    |    FILL SHOW TEXT    |
               #1   |                      | <-- left_right_side (#3)
              side  |          o           |
                    |        (x,y)         |
                    |                      |
                    |                      |
                    |                      |
            (x4,y4) o----------------------o (x3,y3)
                            #4 side

        Use as subroutine($SVG_object, key1=>value1, key2=>value2, ...);

        # Options key, enclosed by [ ] means default
        --- basic structure ---
        # x, [100]
        # y, [100]
        # head_bottom_side_len, [50]
        # left_right_side_len, [head_bottom_side_len]
        # upleft_angle, [90]
        --- appearance ---
        # fill_color, ["none"]
        # boundary_color, ["black"]
        # boundary_width, [0.5]
        # boud_dasharray, [" "]
        # bold_side, ["0"], "1", "2", "3", "4"
        #          Note:  accepts strings, multiple dealing, such as "1", "1,2"
        #                 0, means no side needs to make bold
        #                 1, means left  side  #1,  bold line from (x4,y4) to (x1,y1)
        #                 2, means above side  #2,  bold line from (x1,y1) to (x2,y2)
        #                 3, means right side  #3,  bold line from (x2,y2) to (x3,y3)
        #                 4, means bottom side #4,  bold line from (x3,y3) to (x4,y4)
        # bold_width, 3
        # opacity, [1]
        # draw_bool, [1]
                    Sometimes, user may want just pre-calculate some values for displaying adjustment, set this option as
                    zero will disable the SVG drawing.
        --- inner marker line ----
        # inner_line_ori, [none]
                        You can use "h" for horizontal and "v" for vertical, or "h,v".
        # inner_line_wid, [1]
        # inner_line_col, ["black"]
        --- text ----
        # text_fill, [""]
        # text_col, ["black"]
        # text_font_size, [12]
        # font_size_auto_adjust, [0]
        # font_size_auto_adjust_wRatio, [1]
        # font_size_auto_adjust_hRatio. [1]
        # text_free_rotate, [0]
        # text_font_fam, ["Times New Roman"]
        --- rotate ---
        # rotate_degree, [0]
        # rotate_center_x, [x]
                         It is the x you supplied.
        # rotate_center_y, [y]
                         It is the y you supplied.
        --- Gradient color fill ---
        # colorGradOrit, [optional]
                         You can use "h" for horizontal and "v" for vertical.
        # colorGradStColor, [red]
        # colorGradStOpacity, [0]
        # colorGradEdColor, [red]
        # colorGradEdOpacity, [1]

        --- help ----
        # usage_print, [0]

        Use options in anonymous hash, like
           subroutine( $SVG_object, x=>120, y=>120 );

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
    ## centre location
    my $x               = $Options_Href->{x} || 100;
    my $y               = $Options_Href->{y} || 100;
    ## segment structure
    my $hd_bot_side_len = $Options_Href->{head_bottom_side_len} || 50;
    my $lt_rt_side_len  = $Options_Href->{left_right_side_len} || $hd_bot_side_len;
    my $upleft_angle    = $Options_Href->{upleft_angle} || 90;
    ## segment appearance
    my $fill_col        = $Options_Href->{fill_color} || 'none';
    my $opacity         = (defined $Options_Href->{opacity}) ? $Options_Href->{opacity} : 1;
    my $boud_color      = $Options_Href->{boundary_color} || 'black';
    my $boud_width      = $Options_Href->{boundary_width} || 0.5;
    my $boud_dasharray  = $Options_Href->{boud_dasharray} || " ";
    my $bold_side       = $Options_Href->{bold_side} || '0';
    my $bold_width      = $Options_Href->{bold_width} || 3;
    my $draw_bool       = (defined($Options_Href->{draw_bool})) ? $Options_Href->{draw_bool} : 1;
    ## inner mark line
    my $inner_line_ori  = $Options_Href->{inner_line_ori}; # 'h' or 'v' or 'h,v'
    my $inner_line_wid  = $Options_Href->{inner_line_wid} || 1;
    my $inner_line_col  = $Options_Href->{inner_line_col} || 'black';
    ## text
    my $text_fill       = $Options_Href->{text_fill} || '';
    my $text_col        = $Options_Href->{text_col} || 'black';
    my $text_font_size  = $Options_Href->{text_font_size} || 12;
    my $text_font_fam   = $Options_Href->{text_font_fam} || 'Times New Roman';
    my $fz_auto_adjust  = $Options_Href->{font_size_auto_adjust} || 0;
    my $fz_auto_adjust_wRatio  = $Options_Href->{font_size_auto_adjust_wRatio} || 1;
    my $fz_auto_adjust_hRatio  = $Options_Href->{font_size_auto_adjust_hRatio} || 1;
    my $text_free_rotate = $Options_Href->{text_free_rotate} || 0;
    ## rotate
    my $rotate_degree   = $Options_Href->{rotate_degree} || 0;
    my $rotate_center_x = $Options_Href->{rotate_center_x} || $x;
    my $rotate_center_y = $Options_Href->{rotate_center_y} || $y;
    # Gradient color fill
    my $colorGradOrit = $Options_Href->{colorGradOrit}; # h:horizontal; v:vertical
    my $colorGradStColor = $Options_Href->{colorGradStColor} || 'red';
    my $colorGradStOpacity = $Options_Href->{colorGradStOpacity} || 0;
    my $colorGradEdColor = $Options_Href->{colorGradEdColor} || 'red';
    my $colorGradEdOpacity = $Options_Href->{colorGradEdOpacity} || 1;

    # draw parallelogram
    my $up_left_radian = $upleft_angle * $deg2rad;
    my $hd_side_middleP_x = $x - cos($up_left_radian)*$lt_rt_side_len/2;
    my $hd_side_middleP_y = $y - sin($up_left_radian)*$lt_rt_side_len/2;
    my ($x1,$y1) = ($hd_side_middleP_x-$hd_bot_side_len/2, $hd_side_middleP_y);
    my ($x2,$y2) = ($hd_side_middleP_x+$hd_bot_side_len/2, $hd_side_middleP_y);
    my $bot_side_middleP_x = $x + cos($up_left_radian)*$lt_rt_side_len/2;
    my $bot_side_middleP_y = $y + sin($up_left_radian)*$lt_rt_side_len/2;
    my ($x3,$y3) = ($bot_side_middleP_x+$hd_bot_side_len/2, $bot_side_middleP_y);
    my ($x4,$y4) = ($bot_side_middleP_x-$hd_bot_side_len/2, $bot_side_middleP_y);
    my $path = "M$x1,$y1,L$x2,$y2,L$x3,$y3,L$x4,${y4}Z";
    # confirm stroke-width
    my $bool = 1;
    $bool = $bool && ($bold_side =~ /$_/) for (1 .. 4);
    if($bool){ # once all sides need to be bold.
        $boud_width = $bold_width;
        $bold_side = '0'; # pretend no need to be bold again.
    }

    # color fill
    if( defined $colorGradOrit && $colorGradOrit =~ /^[hv]$/ ){
        my ($x1, $y1, $x2, $y2) =   $colorGradOrit eq 'h'
                                  ? ('0%', '0%', '100%', '0%')
                                  : ('0%', '0%', '0%', '100%');
        # create pattern
        my $color_pattern = $$SVG_object->pattern();
        my $color_grad = $color_pattern->gradient( id=>'color_grad', x1=>$x1, y1=>$y1, x2=>$x2, y2=>$y2 );
        $color_grad->stop( offset=>'0%',   style=>{'stop-color'=>$colorGradStColor,'stop-opacity'=>$colorGradStOpacity} );
        $color_grad->stop( offset=>'100%', style=>{'stop-color'=>$colorGradEdColor,'stop-opacity'=>$colorGradEdOpacity} );
        # use the color-pattern
        $fill_col = 'url(#color_grad)';
    }

    # square
    $$SVG_object->path(
                        d => $path,
                        stroke => $boud_color,
                        'stroke-width' => $boud_width,
                        'stroke-dasharray' => $boud_dasharray,
                        fill => $fill_col,
                        opacity => $opacity,
                        transform => "rotate($rotate_degree,$rotate_center_x,$rotate_center_y)"
                      ) if($draw_bool);

    # inner mark line
    if( defined $inner_line_ori ){
        for my $inLine_ori (split /,/, $inner_line_ori){
            my ($inLine_x1, $inLine_y1);
            my ($inLine_x2, $inLine_y2);
            if( $inLine_ori eq 'h' ){
                $inLine_x1 = ($x1 + $x4) / 2;
                $inLine_y1 = ($y1 + $y4) / 2;
                $inLine_x2 = ($x2 + $x3) / 2;
                $inLine_y2 = ($y2 + $y3) / 2;
            }
            elsif( $inLine_ori eq 'v' ){
                $inLine_x1 = ($x1 + $x2) / 2;
                $inLine_y1 = ($y1 + $y2) / 2;
                $inLine_x2 = ($x4 + $x3) / 2;
                $inLine_y2 = ($y4 + $y3) / 2;
            }
            # show inner mark line
            $$SVG_object->line(
                                x1 => $inLine_x1,
                                y1 => $inLine_y1,
                                x2 => $inLine_x2,
                                y2 => $inLine_y2,
                                stroke => $inner_line_col,
                                'stroke-width' => $inner_line_wid,
                                opacity => $opacity,
                                transform => "rotate($rotate_degree,$rotate_center_x,$rotate_center_y)"
                              ) if($draw_bool);
        }
    }

    # bold sides
    if($bold_side !~ /^0$/){
        # sharing style
        my $style_Href = {
                           stroke => $boud_color,
                           'stroke-width' => $bold_width,
                           'stroke-linecap' => 'round',
                           opacity => $opacity,
                           transform => "rotate($rotate_degree,$rotate_center_x,$rotate_center_y)"
                         };
        # index vs array
        my @pos_pool = ([$x1,$y1], [$x2,$y2], [$x3,$y3], [$x4,$y4]);
        # draw line
        for my $single_bold_side (split //,$bold_side){
            next if($single_bold_side !~ /^[1234]$/); # only one digital number, allow 1,2,3,4
            my ($x_1,$y_1) = @{$pos_pool[$single_bold_side-2]};
            my ($x_2,$y_2) = @{$pos_pool[$single_bold_side-1]};
            $$SVG_object->line(
                                x1 => $x_1,
                                y1 => $y_1,
                                x2 => $x_2,
                                y2 => $y_2,
                                style => $style_Href
                              ) if($draw_bool);
        }
    }

    # text show?
    if(length($text_fill) != 0){
        my $text_x = $x;
        my $text_y = $y;
        my $text_rotate_degree = ($text_free_rotate)?0:$rotate_degree;
        my $hight_ceiling = $fz_auto_adjust ? sin($up_left_radian)*$lt_rt_side_len*$fz_auto_adjust_hRatio : 0;
        my $width_ceiling = $fz_auto_adjust ? min(abs($x4-$x2), abs($x1-$x3))*$fz_auto_adjust_wRatio : 0;
        show_text_in_line(
                            $SVG_object,
                            text_x => $text_x,
                            text_y => $text_y,
                            text => $text_fill,
                            font_family => $text_font_fam,
                            font_size => $text_font_size,
                            text_col => $text_col,
                            text_anchor => 'middle',
                            height_adjust => 1,
                            height_limit => $hight_ceiling,
                            width_limit => $width_ceiling,
                            rotate_degree => $text_rotate_degree,
                            rotate_center_x => $rotate_center_x,
                            rotate_center_y => $rotate_center_y,
                            draw_bool => $draw_bool
                         );
    }

    # return the height and width
    return [abs($y3-$y2), abs($x3-$x4)];
}

#-------- Draw a triangle --------#
#-------- Check Usage in the codes ------#
sub draw_a_triangle{

    my $sub_routine_name = "draw_a_triangle";

    my $Usage = '

            This is the most simple triangle, regular triangle.

                     (x2,y2) o
                            / \ <-- vertex angle 
                           /   \
                    #1    /     \   #2
                   side  /       \ side
                        /    o    \ <-- middle height
                       /   (x,y)   \
                      /             \
                     /               \
                    /                 \
           (x1,y1) o-------------------o (x3,y3)
                         #3 side

        Use as subroutine($SVG_object, key1=>value1, key2=>value2, ...);

        # Options key, enclosed by [ ] means default
        --- basic structure ---
        # x, [100]
        # y, [100]
        # bottom_side_len, [50]
        # vertex_angle, [60]
        --- appearance ---
        # fill_color, ["none"]
        # boundary_color, ["black"]
        # boundary_width, [0.5]
        # boud_dasharray, [" "]
        # bold_side, ["0"], "1", "2", "3"
        #          Note:  accepts strings, multiple dealing, such as "1", "1,2"
        #                 0, means no side needs to make bold
        #                 1, means left   side #1,  bold line from (x1,y1) to (x2,y2)
        #                 2, means right  side #2,  bold line from (x2,y2) to (x3,y3)
        #                 3, means bottom side #3,  bold line from (x3,y3) to (x1,y1)
        # bold_width, 3
        # opacity, [1]
        # draw_bool, [1]
                    Sometimes, user may want just pre-calculate some values for displaying adjustment, set this option as
                    zero will disable the SVG drawing.
        --- text ----
        # text_fill, [""]
        # text_col, ["black"]
        # text_font_size, [12]
        # font_size_auto_adjust, [0]
        # text_free_rotate, [0]
        # text_font_fam, ["Times New Roman"]
        --- rotate ---
        # rotate_degree, [0]
        # rotate_center_x, [x]
                         It is the x you supplied.
        # rotate_center_y, [y]
                         It is the y you supplied.
        --- help ----
        # usage_print, [0]

        Use options in anonymous hash, like
           subroutine( $SVG_object, x=>120, y=>120 );

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
    ## centre location
    my $x               = $Options_Href->{x} || 100;
    my $y               = $Options_Href->{y} || 100;
    ## segment structure
    my $bot_side_len    = $Options_Href->{bottom_side_len} || 50;
    my $vertex_angle    = $Options_Href->{vertex_angle} || 60;
    ## segment appearance
    my $fill_col        = $Options_Href->{fill_color} || 'none';
    my $opacity         = (defined $Options_Href->{opacity}) ? $Options_Href->{opacity} : 1;
    my $boud_color      = $Options_Href->{boundary_color} || 'black';
    my $boud_width      = $Options_Href->{boundary_width} || 0.5;
    my $boud_dasharray  = $Options_Href->{boud_dasharray} || " ";
    my $bold_side       = $Options_Href->{bold_side} || '0';
    my $bold_width      = $Options_Href->{bold_width} || 3;
    my $draw_bool       = (defined($Options_Href->{draw_bool})) ? $Options_Href->{draw_bool} : 1;
    ## text
    my $text_fill       = $Options_Href->{text_fill} || '';
    my $text_col        = $Options_Href->{text_col} || 'black';
    my $text_font_size  = $Options_Href->{text_font_size} || 12;
    my $text_font_fam   = $Options_Href->{text_font_fam} || 'Times New Roman';
    my $fz_auto_adjust  = $Options_Href->{font_size_auto_adjust} || 0;
    my $text_free_rotate = $Options_Href->{text_free_rotate} || 0;
    ## rotate
    my $rotate_degree   = $Options_Href->{rotate_degree} || 0;
    my $rotate_center_x = $Options_Href->{rotate_center_x} || $x;
    my $rotate_center_y = $Options_Href->{rotate_center_y} || $y;

    # draw triangle
    my $vertex_radian = $vertex_angle * $deg2rad;
    my $half_bot_side = $bot_side_len / 2;
    my $height = $half_bot_side / tan($vertex_radian / 2);
    my $half_height = $height / 2;
    my ($x1,$y1) = ($x-$half_bot_side, $y+$half_height);
    my ($x2,$y2) = ($x               , $y-$half_height);
    my ($x3,$y3) = ($x+$half_bot_side, $y+$half_height);
    my $path = "M$x1,$y1,L$x2,$y2,L$x3,${y3}Z";
    # confirm stroke-width
    my $bool = 1;
    $bool = $bool && ($bold_side =~ /$_/) for (1 .. 3);
    if($bool){ # once all sides need to be bold.
        $boud_width = $bold_width;
        $bold_side = '0'; # pretend no need to be bold again.
    }
    # draw triangle
    $$SVG_object->path(
                        d=>$path,
                        stroke=>$boud_color,
                        'stroke-width'=>$boud_width,
                        'stroke-dasharray'=>$boud_dasharray,
                        fill=>$fill_col,
                        opacity=>$opacity,
                        transform=>"rotate($rotate_degree,$rotate_center_x,$rotate_center_y)"
                      ) if($draw_bool);

    # bold sides
    if($bold_side !~ /^0$/){
        # sharing style
        my $style_Href = {
                            stroke=>$boud_color,
                            'stroke-width'=>$bold_width,
                            'stroke-linecap'=>'round',
                            opacity=>$opacity,
                            transform=>"rotate($rotate_degree,$rotate_center_x,$rotate_center_y)"
                         };
        # index vs array
        my @pos_pool = ([$x2,$y2], [$x3,$y3], [$x1,$y1]);
        # draw line
        for my $single_bold_side (split //,$bold_side){
            next if($single_bold_side !~ /^[123]$/); # only one digital number, allow 1,2,3
            my ($x_1,$y_1) = @{$pos_pool[$single_bold_side-2]};
            my ($x_2,$y_2) = @{$pos_pool[$single_bold_side-1]};
            $$SVG_object->line(
                                x1=>$x_1,y1=>$y_1,
                                x2=>$x_2,y2=>$y_2,
                                style=>$style_Href
                              ) if($draw_bool);
        }
    }

    # text show?
    if(length($text_fill) != 0){
        # text
        my $text_x = $x;
        my $text_y = $y + $half_height - $half_bot_side / sqrt(3);
        my $text_rotate_degree = ($text_free_rotate)?0:$rotate_degree;
        my $hight_ceiling = $fz_auto_adjust ? $height : 0;
        my $width_ceiling = $fz_auto_adjust ? $half_bot_side : 0;
        show_text_in_line(
                            $SVG_object,
                            text_x=>$text_x,
                            text_y=>$text_y,
                            text=>$text_fill,
                            font_family=>$text_font_fam,
                            font_size=>$text_font_size,
                            text_col=>$text_col,
                            text_anchor=>'middle',
                            height_adjust=>1,
                            height_limit=>$hight_ceiling,
                            width_limit=>$width_ceiling,
                            rotate_degree=>$text_rotate_degree,
                            rotate_center_x=>$rotate_center_x,
                            rotate_center_y=>$rotate_center_y,
                            draw_bool=>$draw_bool
                         );
    }

    # return the height and width
    return [abs($y3-$y2), abs($x3-$x1)];
}

#-------- Draw a arrow --------#
#-------- Check Usage in the codes ------#
sub draw_a_arrow{

    my $sub_routine_name = "draw_a_arrow";

    my $Usage = '

            This is the most simple triangle, regular triangle.

                     (x2,y2) o
                            / \ <-- vertex angle 
                           /   \
                          /     \
                         / (x,y) \
                        /   _o_   \ <-- middle height
                       /   /   \   \
                      /   /     \   \
                     /   /       \   \
            (x1,y1) o----         ----o (x3,y3)

        Use as subroutine($SVG_object, key1=>value1, key2=>value2, ...);

        # Options key, enclosed by [ ] means default
        --- basic structure ---
        # x, [100]
        # y, [100]
        # bottom_side_len, [50]
        # vertex_angle, [60]
        --- appearance ---
        # fill_color, ["none"]
        # boundary_color, ["black"]
        # boundary_width, [0.5]
        # boud_dasharray, [" "]
        # opacity, [1]
        # draw_bool, [1]
                    Sometimes, user may want just pre-calculate some values for displaying adjustment, set this option as
                    zero will disable the SVG drawing.
        --- rotate ---
        # rotate_degree, [0]
        # rotate_center_x, [x]
                         It is the x you supplied.
        # rotate_center_y, [y]
                         It is the y you supplied.
        --- help ----
        # usage_print, [0]

        Use options in anonymous hash, like 
           subroutine( $SVG_object, x=>120, y=>120 );

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
    ## centre location
    my $x               = $Options_Href->{x} || 100;
    my $y               = $Options_Href->{y} || 100;
    ## segment structure
    my $bot_side_len    = $Options_Href->{bottom_side_len} || 50;
    my $vertex_angle    = $Options_Href->{vertex_angle} || 60;
    ## segment appearance
    my $fill_col        = $Options_Href->{fill_color} || 'none';
    my $opacity         = (defined $Options_Href->{opacity}) ? $Options_Href->{opacity} : 1;
    my $boud_color      = $Options_Href->{boundary_color} || 'black';
    my $boud_width      = $Options_Href->{boundary_width} || 0.5;
    my $boud_dasharray  = $Options_Href->{boud_dasharray} || " ";
    my $draw_bool       = (defined($Options_Href->{draw_bool})) ? $Options_Href->{draw_bool} : 1;
    ## rotate
    my $rotate_degree   = $Options_Href->{rotate_degree} || 0;
    my $rotate_center_x = $Options_Href->{rotate_center_x} || $x;
    my $rotate_center_y = $Options_Href->{rotate_center_y} || $y;

    # draw triangle
    my $vertex_radian = $vertex_angle * $deg2rad;
    my $half_bot_side = $bot_side_len / 2;
    my $height = $half_bot_side / tan($vertex_radian / 2);
    my $half_height = $height / 2;
    my ($x1,$y1) = ($x-$half_bot_side, $y+$half_height);
    my ($x2,$y2) = ($x               , $y-$half_height);
    my ($x3,$y3) = ($x+$half_bot_side, $y+$half_height);
    my $path = "M$x1,$y1,L$x2,$y2,L$x3,$y3,L$x,${y}Z";
    # draw arrow
    $$SVG_object->path(
                        d=>$path,
                        stroke=>$boud_color,
                        'stroke-width'=>$boud_width,
                        'stroke-dasharray'=>$boud_dasharray,
                        fill=>$fill_col,
                        opacity=>$opacity,
                        transform=>"rotate($rotate_degree,$rotate_center_x,$rotate_center_y)"
                      ) if($draw_bool);

    # return the height and width
    return [abs($y3-$y2), abs($x3-$x1)];
}

#-------- Draw a ellipse --------#
#-------- Check Usage in the codes ------#
sub draw_a_ellipse{

    my $sub_routine_name = "draw_a_ellipse";

    my $Usage = '

        Use as subroutine($SVG_object, key1=>value1, key2=>value2, ...);

        # Options key, enclosed by [ ] means default
        --- basic structure ---
        # cx, [100]
        # cy, [100]
        # radius, [50]
                  This is the x-axis raidus of ellipse.
        # radius_b, [as radius]
                     This is the y-axis radius of ellipse.
                     Default is value of option radius, means to draw a circle.
        --- appearance ---
        # fill_color, ["none"]
        # boundary_color, ["black"]
        # boundary_width, [0.5]
        # boud_dasharray, [" "]
        # opacity, [1]
        # draw_bool, [1]
                    Sometimes, user may want just pre-calculate some values for displaying adjustment, set this option as
                    zero will disable the SVG drawing.
        --- text ----
        # text_fill, [""]
        # text_col, ["black"]
        # text_font_size, [12]
        # font_size_auto_adjust, [0]
        # text_font_fam, ["Times New Roman"]
        --- text rotate ---
        # text_rotate_degree, [0]
        # text_rotate_center_x, [x]
                         It is the x you supplied.
        # text_rotate_center_y, [y]
                         It is the y you supplied.
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
    my $cx              = $Options_Href->{cx} || 100;
    my $cy              = $Options_Href->{cy} || 100;
    my $radius          = $Options_Href->{radius} || 50;
    my $radius_b        = $Options_Href->{radius_b} || $Options_Href->{radius};
    ## segment appearance
    my $fill_col        = $Options_Href->{fill_color} || 'none';
    my $opacity         = (defined $Options_Href->{opacity}) ? $Options_Href->{opacity} : 1;
    my $boud_color      = $Options_Href->{boundary_color} || 'black';
    my $boud_width      = $Options_Href->{boundary_width} || 0.5;
    my $boud_dasharray  = $Options_Href->{boud_dasharray} || " ";
    my $draw_bool       = (defined($Options_Href->{draw_bool})) ? $Options_Href->{draw_bool} : 1;
    ## text
    my $text_fill       = $Options_Href->{text_fill} || '';
    my $text_col        = $Options_Href->{text_col} || 'black';
    my $text_font_size  = $Options_Href->{text_font_size} || 12;
    my $text_font_fam   = $Options_Href->{text_font_fam} || 'Times New Roman';
    my $fz_auto_adjust  = $Options_Href->{font_size_auto_adjust} || 0;
    ## rotate
    my $text_rotate_degree   = $Options_Href->{rotate_degree} || 0;
    my $text_rotate_center_x = $Options_Href->{rotate_center_x} || $cx;
    my $text_rotate_center_y = $Options_Href->{rotate_center_y} || $cy;

    my $style_Href = {
                        stroke=>$boud_color,
                        'stroke-width'=>$boud_width,
                        'stroke-dasharray'=>$boud_dasharray,
                        fill=>$fill_col,
                        opacity=>$opacity
                     };

    if($radius == $radius_b){
        # draw circle
        $$SVG_object->circle(
                             cx=>$cx,
                             cy=>$cy,
                             r=>$radius,
                             style=>$style_Href
                            ) if($draw_bool);
    }
    else{
        # draw ellipse
        $$SVG_object->ellipse(
                             cx=>$cx,
                             cy=>$cy,
                             rx=>$radius,
                             ry=>$radius_b,
                             style=>$style_Href
                            ) if($draw_bool);
    }

    # text
    if(length($text_fill)){
        my $text_x = $cx;
        my $text_y = $cy;
        my $hight_ceiling = $fz_auto_adjust ? $radius_b : 0;
        my $width_ceiling = $fz_auto_adjust ? $radius : 0;
        show_text_in_line(
                            $SVG_object,
                            text_x=>$text_x,
                            text_y=>$text_y,
                            text=>$text_fill,
                            font_family=>$text_font_fam,
                            font_size=>$text_font_size,
                            text_col=>$text_col,
                            text_anchor=>'middle',
                            height_adjust=>1,
                            height_limit=>$hight_ceiling,
                            width_limit=>$width_ceiling,
                            rotate_degree=>$text_rotate_degree,
                            rotate_center_x=>$text_rotate_center_x,
                            rotate_center_y=>$text_rotate_center_y,
                            draw_bool=>$draw_bool
                         );
    }

    # return the height and width
    return [ 2 * $radius_b, 2 * $radius ];
}

1; ## tell the perl script the successful access of this module.
