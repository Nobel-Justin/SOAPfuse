package SOAPfuse::SVG_Font;

use strict;
use warnings;
use Math::Trig;
use List::Util qw[min max sum];
use SOAPfuse::SVG_Radian_System qw/$deg2rad get_coordinate_on_circle draw_an_arc/;
require Exporter;


#----- systemic variables -----
our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS, $VERSION, $AUTHOR, $MAIL);
@ISA = qw(Exporter);
@EXPORT = qw(%Font_Size);
push @EXPORT , qw();
@EXPORT_OK = qw(%Font_Size confirm_transform_ratio show_text_in_line show_text_on_arc get_size_of_text_to_show);
%EXPORT_TAGS = ( DEFAULT => [qw()],
                 OTHER   => [qw()]);
#----- version --------
$VERSION = "0.24";
$AUTHOR = "Wenlong Jia";
$MAIL = 'wenlongkxm@gmail.com';

#--------- functions in this pm --------#
my @functoion_list = (
						'confirm_transform_ratio',
						'show_text_in_line',
						'show_text_on_arc',
						'get_size_of_text_to_show',
						'decode_char_size_symbol'
					 );

our %Font_Size=(
				# https://docs.google.com/spreadsheets/d/1aI5WUYR_FV0PQeZ228j1qWpa_8Xnv4x5uIjNjpnpMcE/edit?usp=sharing
				'Arial'	=>	{
								'size'	=>	{
												# the infomation in this table all belongs to font-size 12pt.
												'basal'	=>	12,
												# the bottom edge of the 'base' part is the text y-coordinate
												'height'=>	[ 2.25, 6.5 , 2.375 ], # head, base, tail
												# the left edge of the 'left' part is the text x-coordinate
												'width'	=>	[ 3.82, 2.36, 3.05 ], # left, base, right
												'blank'	=>	3.4,
												'gapratio'	=>	0.147,
											},
							# these are transforming ratio only for width
							'transform'	=>	{
												'narrow'	=>	0.82,
												'italic'	=>	1,
												'bold'		=>	1.08,
												'black'		=>	1.225,
												'narrow,bold'	=>	0.835
											},
							'char_table'=>	{
												'a'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'b'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'c'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'd'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'e'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'f'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S1,U0', 'S1,U0' ]
														},
												'g'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S0,U1' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'h'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'i'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U0.7', 'S1,U0', 'S1,U0' ]
														},
												'j'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ],
															'width'	=>	[ 'S-0.15,U0.7', 'S1,U0', 'S1,U0' ]
														},
												'k'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'l'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U0.7', 'S1,U0', 'S1,U0' ]
														},
												'm'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ]
														},
												'n'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'o'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'p'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S0,U1' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'q'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S0,U1' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'r'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U0.15', 'S1,U0' ]
														},
												's'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U0.6', 'S1,U0' ]
														},
												't'	=>	{
															'height'=>	[ 'S0,U0.89', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S1,U0', 'S1,U0' ]
														},
												'u'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'v'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'w'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.8' ]
														},
												'x'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'y'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S0,U1' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'z'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'A'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.6' ]
														},
												'B'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.4' ]
														},
												'C'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.6' ]
														},
												'D'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.6' ]
														},
												'E'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.3' ]
														},
												'F'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.2' ]
														},
												'G'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.8' ]
														},
												'H'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.4' ]
														},
												'I'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U0.7', 'S1,U0', 'S1,U0' ]
														},
												'J'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U0.5', 'S1,U0' ]
														},
												'K'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.6' ]
														},
												'L'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'M'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ]
														},
												'N'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.4' ]
														},
												'O'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.9' ]
														},
												'P'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.4' ]
														},
												'Q'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S0.8,U0.2' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.9' ]
														},
												'R'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.8' ]
														},
												'S'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.3' ]
														},
												'T'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.2' ]
														},
												'U'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.4' ]
														},
												'V'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.4' ]
														},
												'W'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U1.5' ]
														},
												'X'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.6' ]
														},
												'Y'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.6' ]
														},
												'Z'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.3' ]
														},
												'0'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'1'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U0.2', 'S1,U0' ]
														},
												'2'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'3'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'4'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'5'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'6'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'7'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'8'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'9'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'~'	=>	{
															'height'=>	[ 'S1,U0', 'S0.5,U0.3', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.1' ]
														},
												'`'	=>	{
															'height'=>	[ 'S0.2,U0.8', 'S1,U0', 'S1,U0' ],
															'width'	=>	[ 'S0,U0.7', 'S1,U0', 'S1,U0' ]
														},
												'!'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U0.7', 'S1,U0', 'S1,U0' ]
														},
												'@'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U1.5' ]
														},
												'#'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.08' ]
														},
												'$'	=>	{
															'height'=>	[ 'S0,U1.3', 'S0,U1', 'S0.6,U0.4' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'%'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U1.2' ]
														},
												'^'	=>	{
															'height'=>	[ 'S0,U1', 'S0.6,U0.4', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U0.6', 'S1,U0' ]
														},
												'&'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.4' ]
														},
												'*'	=>	{
															'height'=>	[ 'S0,U1.05', 'S0.8,U0.2', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U0.15', 'S1,U0' ]
														},
												'('	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ],
															'width'	=>	[ 'S0,U1', 'S1,U0', 'S1,U0' ]
														},
												')'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ],
															'width'	=>	[ 'S0,U1', 'S1,U0', 'S1,U0' ]
														},
												'_'	=>	{
															'height'=>	[ 'S1,U0', 'S1,U0', 'S0.3,U0.7' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.2' ]
														},
												'+'	=>	{
															'height'=>	[ 'S0,U0.3', 'S0.25,U0.75', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.05' ]
														},
												'-'	=>	{
															'height'=>	[ 'S1,U0', 'S0.45,U0.2', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S1,U0', 'S1,U0' ]
														},
												'='	=>	{
															'height'=>	[ 'S1,U0', 'S0.45,U0.45', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.05' ]
														},
												'{'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ],
															'width'	=>	[ 'S0,U1', 'S1,U0', 'S1,U0' ]
														},
												'}'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ],
															'width'	=>	[ 'S0,U1', 'S1,U0', 'S1,U0' ]
														},
												'|'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ],
															'width'	=>	[ 'S0,U0.5', 'S1,U0', 'S1,U0' ]
														},
												'['	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ],
															'width'	=>	[ 'S0,U0.8', 'S1,U0', 'S1,U0' ]
														},
												']'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ],
															'width'	=>	[ 'S0,U0.7', 'S1,U0', 'S1,U0' ]
														},
												"\\"	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S1,U0', 'S1,U0' ]
														},
												':'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U0.6', 'S1,U0', 'S1,U0' ]
														},
												'”'	=>	{
															'height'=>	[ 'S0,U1', 'S0.95,U0.05', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S1,U0', 'S1,U0' ]
														},
												';'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S0.4,U0.6' ],
															'width'	=>	[ 'S0,U0.6', 'S1,U0', 'S1,U0' ]
														},
												"'"	=>	{
															'height'=>	[ 'S0,U1', 'S0.95,U0.05', 'S1,U0' ],
															'width'	=>	[ 'S0,U0.4', 'S1,U0', 'S1,U0' ]
														},
												'<'	=>	{
															'height'=>	[ 'S0,U0.3', 'S0.25,U0.75', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.05' ]
														},
												'>'	=>	{
															'height'=>	[ 'S0,U0.3', 'S0.25,U0.75', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.05' ]
														},
												'?'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												','	=>	{
															'height'=>	[ 'S1,U0', 'S0,U0.2', 'S0.4,U0.6' ],
															'width'	=>	[ 'S0,U0.6', 'S1,U0', 'S1,U0' ]
														},
												'.'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U0.2', 'S1,U0' ],
															'width'	=>	[ 'S0,U0.6', 'S1,U0', 'S1,U0' ]
														},
												'/'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S1,U0', 'S1,U0' ]
														}
											}
							},
				'Times'	=>	{
								'size'	=>	{
												'basal'	=>	12,
												'height'=>	[ 2.8,   5.67,  2.375 ],
												'width'	=>	[ 3.125, 2.167, 3.271 ],
												'blank'	=>	3,
												'gapratio'	=>	0.167,
											},
							# these are transforming ratio only for width
							'transform'	=>	{
												'new,roman'	=>	1,
												'narrow'	=>	1,
												'italic'	=>	1.113,
												'bold'		=>	1.1,
												'black'		=>	1,
												'italic,bold'	=>	1.089
											},
							'char_table'=>	{
												'a'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'b'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.1' ]
														},
												'c'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U0.8', 'S1,U0' ]
														},
												'd'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.2' ]
														},
												'e'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U0.8', 'S1,U0' ]
														},
												'f'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'g'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S0,U1' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.2' ]
														},
												'h'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.2' ]
														},
												'i'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S1,U0', 'S1,U0' ]
														},
												'j'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ],
															'width'	=>	[ 'S-0.15,U0.7', 'S1,U0', 'S1,U0' ]
														},
												'k'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.2' ]
														},
												'l'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S1,U0', 'S1,U0' ]
														},
												'm'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U1.2' ]
														},
												'n'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.2' ]
														},
												'o'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.1' ]
														},
												'p'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S0,U1' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.1' ]
														},
												'q'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S0,U1' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.2' ]
														},
												'r'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U0.4', 'S1,U0' ]
														},
												's'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U0.4', 'S1,U0' ]
														},
												't'	=>	{
															'height'=>	[ 'S0,U0.89', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U0.08', 'S1,U0' ]
														},
												'u'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.2' ]
														},
												'v'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.2' ]
														},
												'w'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ]
														},
												'x'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.2' ]
														},
												'y'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S0,U1' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.2' ]
														},
												'z'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'A'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ]
														},
												'B'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.6' ]
														},
												'C'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.6' ]
														},
												'D'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.9' ]
														},
												'E'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.5' ]
														},
												'F'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.2' ]
														},
												'G'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ]
														},
												'H'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ]
														},
												'I'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U0.3', 'S1,U0' ]
														},
												'J'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U0.7', 'S1,U0' ]
														},
												'K'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ]
														},
												'L'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.5' ]
														},
												'M'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U1.5' ]
														},
												'N'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ]
														},
												'O'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.9' ]
														},
												'P'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.3' ]
														},
												'Q'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S0.8,U0.2' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.9' ]
														},
												'R'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.9' ]
														},
												'S'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.2' ]
														},
												'T'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.5' ]
														},
												'U'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ]
														},
												'V'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ]
														},
												'W'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U1.7' ]
														},
												'X'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ]
														},
												'Y'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ]
														},
												'Z'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.5' ]
														},
												'0'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.08' ]
														},
												'1'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U0.7', 'S1,U0' ]
														},
												'2'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.05' ]
														},
												'3'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U0.85', 'S1,U0' ]
														},
												'4'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.1' ]
														},
												'5'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'6'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.08' ]
														},
												'7'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.05' ]
														},
												'8'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'9'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.05' ]
														},
												'~'	=>	{
															'height'=>	[ 'S1,U0', 'S0.5,U0.3', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.3' ]
														},
												'`'	=>	{
															'height'=>	[ 'S0.2,U0.8', 'S1,U0', 'S1,U0' ],
															'width'	=>	[ 'S0,U0.8', 'S1,U0', 'S1,U0' ]
														},
												'!'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U0.8', 'S1,U0', 'S1,U0' ]
														},
												'@'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U1.6' ]
														},
												'#'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.15' ]
														},
												'$'	=>	{
															'height'=>	[ 'S0,U1.3', 'S0,U1', 'S0.6,U0.4' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'%'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U1.3' ]
														},
												'^'	=>	{
															'height'=>	[ 'S0,U1', 'S0.6,U0.4', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'&'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U1.1' ]
														},
												'*'	=>	{
															'height'=>	[ 'S0,U1.05', 'S0.8,U0.2', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ]
														},
												'('	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ],
															'width'	=>	[ 'S0,U1', 'S0,U0.3', 'S1,U0' ]
														},
												')'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ],
															'width'	=>	[ 'S0,U1', 'S0,U0.2', 'S1,U0' ]
														},
												'_'	=>	{
															'height'=>	[ 'S1,U0', 'S1,U0', 'S0.3,U0.7' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.2' ]
														},
												'+'	=>	{
															'height'=>	[ 'S0,U0.3', 'S0.25,U0.75', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.4' ]
														},
												'-'	=>	{
															'height'=>	[ 'S1,U0', 'S0.45,U0.2', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U0.2', 'S1,U0' ]
														},
												'='	=>	{
															'height'=>	[ 'S1,U0', 'S0.45,U0.45', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.4' ]
														},
												'{'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ],
															'width'	=>	[ 'S0,U1', 'S0,U0.8', 'S1,U0' ]
														},
												'}'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ],
															'width'	=>	[ 'S0,U1', 'S0,U0.6', 'S1,U0' ]
														},
												'|'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ],
															'width'	=>	[ 'S0,U0.4', 'S1,U0', 'S1,U0' ]
														},
												'['	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ],
															'width'	=>	[ 'S0,U1', 'S0,U0.2', 'S1,U0' ]
														},
												']'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S0,U1' ],
															'width'	=>	[ 'S0,U1', 'S1,U0', 'S1,U0' ]
														},
												"\\"=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U0.08', 'S1,U0' ]
														},
												':'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U0.7', 'S1,U0', 'S1,U0' ]
														},
												'”'	=>	{
															'height'=>	[ 'S0,U1', 'S0.95,U0.05', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U0.85', 'S1,U0' ]
														},
												';'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U1', 'S0.4,U0.6' ],
															'width'	=>	[ 'S0,U0.85', 'S1,U0', 'S1,U0' ]
														},
												"'"	=>	{
															'height'=>	[ 'S0,U1', 'S0.95,U0.05', 'S1,U0' ],
															'width'	=>	[ 'S0,U0.95', 'S1,U0', 'S1,U0' ]
														},
												'<'	=>	{
															'height'=>	[ 'S0,U0.3', 'S0.25,U0.75', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.3' ]
														},
												'>'	=>	{
															'height'=>	[ 'S0,U0.3', 'S0.25,U0.75', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U1', 'S0,U0.3' ]
														},
												'?'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U0.8', 'S1,U0' ]
														},
												','	=>	{
															'height'=>	[ 'S1,U0', 'S0,U0.2', 'S0.4,U0.6' ],
															'width'	=>	[ 'S0,U0.6', 'S1,U0', 'S1,U0' ]
														},
												'.'	=>	{
															'height'=>	[ 'S1,U0', 'S0,U0.2', 'S1,U0' ],
															'width'	=>	[ 'S0,U0.6', 'S1,U0', 'S1,U0' ]
														},
												'/'	=>	{
															'height'=>	[ 'S0,U1', 'S0,U1', 'S1,U0' ],
															'width'	=>	[ 'S0,U1', 'S0,U0.08', 'S1,U0' ]
														}
											}
							},
);

#--- confirm transform ratio based on the font family ---
sub confirm_transform_ratio{

	my $sub_routine_name = "confirm_transform_ratio";

	my $Usage = '

		Input is Ref of Options Hash, as

		# my ($Options_Href) = @_;

		# Options_Href, enclosed by [ ] means default
		--- basic structure ---
		# font_family, ["Arial"]
		# font_size, [12]
		--- help ----
		# usage_print, [0]

		Use options in anonymous hash, like 
		   subroutine( { font_family=>"Times", font_size=>15 } );

		It will return a array contains,
		   (font_fam_basal, transforming_ratio)

		';

	my ($Options_Href) = @_;

	if(!defined($Options_Href) || $Options_Href->{usage_print}){
		warn "\nThe Usage of $sub_routine_name:\n";
		warn "$Usage";
		warn "\n";
		exit(1);
	}

	# Defaults
	my $font_family = $Options_Href->{font_family} || 'Arial';
	my $font_size   = $Options_Href->{font_size} || 12;

	#--- firstly, confirm the font basal family ---
	my $font_fam_basal;
	my $transfrom_part;
	my @all_font_fam_basal_in_db;
	for my $font_fam_basal_in_db (sort keys %Font_Size){
		push @all_font_fam_basal_in_db, $font_fam_basal_in_db;
		if($font_family =~ /$font_fam_basal_in_db/i){
			$font_fam_basal = $font_fam_basal_in_db;
			($transfrom_part = $font_family) =~ s/$font_fam_basal_in_db//gi;
			last;
		}
	}
	#--- check ---
	if(!defined($font_fam_basal)){
		warn "Cannot confirm the basal font family from '$font_family'.\nOnly allows: ". join(' ',@all_font_fam_basal_in_db) .".\n";
		exit(1);
	}

	#--- get the basal size ratio ---
	my $basal_ratio = sprintf "%.3f", $font_size / $Font_Size{$font_fam_basal}->{size}->{basal};
	if($transfrom_part =~ /^\s*$/){
		return ($font_fam_basal, $basal_ratio * 1);
	}

	#--- confrim the transfrom ratio ---
	my @all_transfrom_in_db;
	for my $transfrom_in_db (sort keys %{$Font_Size{$font_fam_basal}->{transform}}){
		push @all_transfrom_in_db, $transfrom_in_db;
		my $transfrom_part_tmp = $transfrom_part;
		my @transfrom_in_db = split /,/,$transfrom_in_db;
		my $find_sign = 1;
		for my $single_transfrom_in_db (@transfrom_in_db){
			if($transfrom_part_tmp =~ /$single_transfrom_in_db/i){
				$transfrom_part_tmp =~ s/$single_transfrom_in_db//gi;
			}
			else{
				$find_sign = 0;
				last;
			}
		}
		if($find_sign == 1 && $transfrom_part_tmp =~ /^\s*$/){
			return ($font_fam_basal, $basal_ratio * $Font_Size{$font_fam_basal}->{transform}->{$transfrom_in_db});
		}
	}

	#--- cannot find the transform cases ---
	LAST_WARN: {
		warn "Cannot confirm the transform case from '$font_family'.\nOnly allows: ". join(' ',@all_transfrom_in_db) .".\n";
		exit(1);
	}
}

#--- show the text in line ---
sub show_text_in_line{

	my $sub_routine_name = "show_text_in_line";

	my $Usage = '

		Input is Ref of Options Hash, as

		# my ($SVG_object, $Options_Href) = @_;

		# Options_Href, enclosed by [ ] means default
		--- basic structure ---
		# text_x, [100]
		# text_y, [100]
		# text, ["test"]
		# font_family, ["Arial"]
		# font_size, [12]
		# text_anchor, ["middle"]
		# text_col, ["black"]
		# height_adjust, [0]
		# height_limit, [0]
		# width_limit, [0]
		# rotate_degree, [0]
		# rotate_center_x, [text_x]
		                 It is the x you supplied.
		# rotate_center_y, [text_y]
		                 It is the y you supplied.
		# underline_width, [0]
		             If want to underline the text, use width of the line.
		# features, [{}]
		            This option accepts a Hash ref stores features for sub-strings. It allows the following attributes.
		            "font_family", "font_size", "text_col", "text_rotate_degree", "underline".
		            use it like this, features=>{ "text_col"=>{"red"=>[1,3], "green"=>[4]}, "underline"=>{"2"=>[2,4]} }
		            Notes:
		                  1) Once set "font_size" via this option, "xxx_limit" will not work for the related sub-char(s).
		                  2) The numbers ("1", "2", "3", "4") are the index of the text string to refer specific sub-char(s).
		                     It starts from "1", not "0" (PLEASE pay attentions to this point). BLANK will be counted.
		                  3) For "underline", the key ("2") is the line width.
		# draw_bool, [1]
		            Sometimes, user may want just pre-calculate some values for displaying adjustment, set this option as
		            zero will disable the SVG drawing.
		--- help ----
		# usage_print, [0]

		Use options in anonymous hash, like 
		   subroutine( $SVG_object, { text_x=>"10", text_y=>"20", font_family=>"Times", font_size=>15, height_limit=>20 } );

		';

	my ($SVG_object, $Options_Href) = @_;

	if(!defined($SVG_object) || $Options_Href->{usage_print}){
		warn "\nThe Usage of $sub_routine_name:\n";
		warn "$Usage";
		warn "\n";
		exit(1);
	}

	# Defaults
	my $text_x = exists($Options_Href->{text_x}) ? $Options_Href->{text_x} : 100;
	my $text_y = exists($Options_Href->{text_y}) ? $Options_Href->{text_y} : 100;
	my $text = exists($Options_Href->{text}) ? $Options_Href->{text} : 'test';
	my $font_family = $Options_Href->{font_family} || 'Arial';
	my $font_size   = $Options_Href->{font_size} || 12;
	my $text_anchor = $Options_Href->{text_anchor} || 'middle';
	my $text_col = $Options_Href->{text_col} || 'black';
	my $height_adjust = $Options_Href->{height_adjust} || 0;
	my $height_limit = $Options_Href->{height_limit} || 0;
	my $width_limit = $Options_Href->{width_limit} || 0;
	my $rotate_degree = $Options_Href->{rotate_degree} || 0;
	my $rotate_center_x	= $Options_Href->{rotate_center_x} || $text_x;
	my $rotate_center_y	= $Options_Href->{rotate_center_y} || $text_y;
	my $features_Href = defined($Options_Href->{features}) ? $Options_Href->{features} : {};
	my $draw_bool = defined($Options_Href->{draw_bool}) ? $Options_Href->{draw_bool} : 1;

	# these two values will be returned.
	my ($text_height, $text_width);
	# some features have been assigned to sub-char, use show_text_on_arc with very-large radius
	if(scalar(keys %$features_Href) != 0){
		my $Big_R = 1E6;

		my $arc_text_info_Aref =  show_text_on_arc( $SVG_object,
													{
														cx=>$text_x,
														cy=>$text_y + $Big_R,
														radius=>$Big_R,
														text=>$text,
														font_family=>$font_family,
														font_size=>$font_size,
														text_col=>$text_col,
														text_anchor=>$text_anchor,
														height_adjust=>$height_adjust,
														height_limit=>$height_limit,
														degree_limit=> atan( $width_limit / $Big_R ) / $deg2rad,
														rotate_degree=>$rotate_degree,
														rotate_center_x=>$rotate_center_x,
														rotate_center_y=>$rotate_center_y,
														features=>$features_Href,
														draw_bool=>$draw_bool
													}
												  );
		$text_height = $arc_text_info_Aref->[0];
		$text_width  = $arc_text_info_Aref->[1] * $Big_R;

		# return height and width occupied by the text
		return [$text_height, $text_width];
	}

	# this is just one-time-shown text in a line
	my ($anchor_height_Aref, $anchor_width_Aref);
	my $GET_PROPER_TEXT_SIZE_cross_bool = 0;
	GET_PROPER_TEXT_SIZE: {
		($anchor_height_Aref, $anchor_width_Aref) = 
		&get_size_of_text_to_show({ font_family=>$font_family,
									font_size=>$font_size,
									text=>$text
								  });
		$text_height = $anchor_height_Aref->[0] - $anchor_height_Aref->[1]; # above - below, because below is negative value.
		$text_width  = $anchor_width_Aref->[0] + $anchor_width_Aref->[1]; # char width + gap width
		# check the limitation
		my $height_limit_bool = ($height_limit && $text_height > $height_limit);
		my $width_limit_bool = ($width_limit && $text_width > $width_limit);
		if($height_limit_bool || $width_limit_bool){ # font needs to be smaller.
			$GET_PROPER_TEXT_SIZE_cross_bool = 1;
			if($font_size >= 2){ # next test font must be >= 1.
				$font_size --;
				redo GET_PROPER_TEXT_SIZE;
			}
		}
		else{
			if($GET_PROPER_TEXT_SIZE_cross_bool != 1){ # this means font increases from smaller to this larger size
				if($height_limit && $width_limit){ # user gives the limitations
					$font_size ++;
					redo GET_PROPER_TEXT_SIZE;
				}
			}
		}
	}
	# height adjust
	if($height_adjust){
		my $y_to_add = ($anchor_height_Aref->[0] + $anchor_height_Aref->[1]) / 2;
		$text_y += $y_to_add;
	}
	# decode the font family
	# bold to font-weight; italic to font-style; leave narrow or black in font_family.
	my $font_weight = ' ';
	if($font_family =~ /bold/i){
		$font_weight = 'Bold';
		$font_family =~ s/\s?bold//i;
	}
	my $font_style = ' ';
	if($font_family =~ /italic/i){
		$font_style = 'Italic';
		$font_family =~ s/\s?italic//i;
	}
	# show text style
	my $style_Href = {
					  fill=>$text_col,
					  'font-family'=>$font_family,
					  'font-weight'=>$font_weight,
					  'font-style'=>$font_style,
					  'font-size'=>$font_size,
					  'text-anchor'=>$text_anchor
					 };
	# show text
	$$SVG_object->text(
						x=>$text_x,
						y=>$text_y,
						style=>$style_Href,
						'-cdata'=>$text,
						transform=>"rotate($rotate_degree,$rotate_center_x,$rotate_center_y)"
					  ) if($draw_bool);

	# return height and width occupied by the text
	return [$text_height, $text_width];
}

#--- show the text on arc ---
sub show_text_on_arc{

	my $sub_routine_name = "show_text_on_arc";

	my $Usage = '

		Input is Ref of Options Hash, as

		# my ($SVG_object, $Options_Href) = @_;

		# Options_Href, enclosed by [ ] means default
		--- basic structure ---
		# cx, [100]
		# cy, [100]
		# radius, [100]
		# anchor_degree, [0]
		# text_anchor, ["middle"]
		# text, ["test"]
		# font_family, ["Arial"]
		# font_size, [12]
		# text_col, ["black"]
		# height_adjust, [0]
		# height_limit, [0]
		# degree_limit, [0]
		                This is the arc degree occupied by text (width).
		# text_to_center, ["toe"]
		                You can also use "top", "disabled".
		# text_rotate_degree, [0]
		# features, [{}]
		            This option accepts a Hash ref stores features for sub-strings. It allows the following attributes.
		            "font_family", "font_size", "text_col", "text_to_center", "text_rotate_degree", "underline".
		            use it like this, features=>{ "text_col"=>{"red"=>[1,3], "green"=>[4]}, "text_to_center"=>{"top"=>[2,4]} }
		            Notes:
		                  1) Once set "font_size" via this option, "xxx_limit" will not work for the related sub-char(s).
		                  2) The numbers ("1", "2", "3", "4") are the index of the text string to refer specific sub-char(s).
		                     It starts from "1", not "0" (PLEASE pay attentions to this point). BLANK will be counted.
		                  3) For "underline", the key ("2") is the line width.
		# draw_bool, [1]
		            Sometimes, user may want just pre-calculate some values for displaying adjustment, set this option as
		            zero will disable the SVG drawing.
		--- help ----
		# usage_print, [0]

		Use options in anonymous hash, like 
		   subroutine( $SVG_object, { cx=>"10", cy=>"20", anchor_degree=>90, font_family=>"Times", font_size=>15, height_limit=>20 } );

		';

	my ($SVG_object, $Options_Href) = @_;

	# check part1
	if(!defined($SVG_object) || $Options_Href->{usage_print}){
		warn "\nThe Usage of $sub_routine_name:\n";
		warn "$Usage";
		warn "\n";
		exit(1);
	}

	# Defaults
	my $cx = exists($Options_Href->{cx}) ? $Options_Href->{cx} : 100;
	my $cy = exists($Options_Href->{cy}) ? $Options_Href->{cy} : 100;
	my $radius = $Options_Href->{radius} || 100;
	my $anchor_degree = $Options_Href->{anchor_degree} || 0;
	my $text_anchor = $Options_Href->{text_anchor} || 'middle';
	my $text = exists($Options_Href->{text}) ? $Options_Href->{text} : 'test';
	my $font_family = $Options_Href->{font_family} || 'Arial';
	my $font_size   = $Options_Href->{font_size} || 12;
	my $text_col = $Options_Href->{text_col} || 'black';
	my $height_adjust = $Options_Href->{height_adjust} || 0;
	my $height_limit = $Options_Href->{height_limit} || 0;
	my $degree_limit = $Options_Href->{degree_limit} || 0;
	my $text_rotate_degree = $Options_Href->{text_rotate_degree} || 0;
	my $text_to_center	= $Options_Href->{text_to_center} || 'toe';
	my $features_Href = defined($Options_Href->{features}) ? $Options_Href->{features} : {};
	my $draw_bool = defined($Options_Href->{draw_bool}) ? $Options_Href->{draw_bool} : 1;

	# check part2
	if($text_to_center !~ /^toe|top|disabled$/){
		warn "Warn from $sub_routine_name:\n";
		warn "  Optinons [text_to_center] accepts 'top', 'toe' and 'disabled' only.\n";
		exit(1);
	}

	# deal each char one by one
	my @text_char = split //,$text;

	# load features for sub-chars
	my $Sub_Features_Href = {};
	for my $feature_id (sort keys %$features_Href){
		my $feature_Href = $features_Href->{$feature_id};
		for my $feature_value (sort keys %$feature_Href){
			my $index_list_Aref = $feature_Href->{$feature_value};
			for my $sub_char_index (@$index_list_Aref){
				if($sub_char_index <= 0 || $sub_char_index > scalar(@text_char)){
					warn "For text '$text', index can be set as number from 1 to ".scalar(@text_char).".\n";
					warn "Your input contains index out of range. It is $sub_char_index for feature '$feature_id'.\n";
					warn "Exits at function $sub_routine_name.\n";
					exit(1);
				}
				if(exists($Sub_Features_Href->{$feature_id}->{$sub_char_index})){
					my $pre_feature_value = $Sub_Features_Href->{$feature_id}->{$sub_char_index};
					if($pre_feature_value ne $feature_value){
						warn "Duplicated feature is assigned to index-NO.$sub_char_index sub-char in text '$text' (Index starts from '0').\n";
						warn "Feature '$feature_id' of Index NO.$sub_char_index sub-char are '$pre_feature_value' and '$feature_value'.\n";
						warn "Exits at function $sub_routine_name.\n";
						exit(1);
					}
				}
				else{
					$Sub_Features_Href->{$feature_id}->{$sub_char_index} = $feature_value;
				}
			}
		}
	}

	my %anchor_height;
	my @text_char_info;
	my $text_height;
	my $text_width_arc_radian = 0;
	# GET_PROPER_TEXT_SIZE
	my $GET_PROPER_TEXT_SIZE_cross_bool = 0;
	GET_PROPER_TEXT_SIZE: {
		for (my $i=0; $i<@text_char; $i++){
			my $char = $text_char[$i];
			# features
			my $char_index = $i + 1;
			# "font_family", "font_size", "text_col", "text_to_center", "text_rotate_degree"
			my $char_font_family = $Sub_Features_Href->{font_family}->{$char_index} || $font_family;
			my $char_font_size   = $Sub_Features_Href->{font_size}->{$char_index} || $font_size;
			# get size of this char
			my ($char_anchor_height_Aref, $char_anchor_width_Aref) = 
			&get_size_of_text_to_show({
										font_family=>$char_font_family,
										font_size=>$char_font_size,
										text=>$char,
										single_char_gap=> ($i != $#text_char)  # last char does not postfixed by gap with no following char.
									  });
			# height stuff
			$anchor_height{above}->[$i] = $char_anchor_height_Aref->[0];
			$anchor_height{below}->[$i] = $char_anchor_height_Aref->[1];
			# width stuff
			$text_char_info[$i] = $char_anchor_width_Aref;
			$char_anchor_width_Aref->[2] = $char;
		}
		# text height
		$text_height = max( @{$anchor_height{above}} ) - min( @{$anchor_height{below}} ); # above - below, because below is negative value.
		# text width occupied arc degree
		$text_width_arc_radian += ($_->[0] + $_->[1]) for @text_char_info;
		$text_width_arc_radian /= $radius;
		# check the limitation
		my $height_limit_bool = ($height_limit && $text_height > $height_limit);
		my $degree_limit_bool = ($degree_limit && $text_width_arc_radian/$deg2rad > $degree_limit);
		if($height_limit_bool || $degree_limit_bool){ # font needs to be smaller.
			$GET_PROPER_TEXT_SIZE_cross_bool = 1;
			if($font_size >= 2){ # next test font must be >= 1.
				$font_size --;
				redo GET_PROPER_TEXT_SIZE;
			}
		}
		else{
			if($GET_PROPER_TEXT_SIZE_cross_bool != 1){ # this means font increases from smaller to this larger size
				if($height_limit && $degree_limit){
					$font_size ++;
					redo GET_PROPER_TEXT_SIZE;
				}
			}
		}
	}

	# show text
	my $start_radian = $anchor_degree * $deg2rad;
	if($text_anchor eq 'middle'){
		$start_radian = $start_radian - $text_width_arc_radian / 2;
	}
	elsif($text_anchor eq 'end'){
		$start_radian = $start_radian - $text_width_arc_radian;
	}
	# reversed writing
	if($text_to_center eq 'top'){
		@text_char_info = reverse @text_char_info;
	}
	# height adjust
	my $y_to_add = 0;
	if($height_adjust){
		$y_to_add = ( max( @{$anchor_height{above}} ) + min( @{$anchor_height{below}} ) ) / 2;
	}
	# show the char in the text one by one.
	my $now_anchor_radian = $start_radian;
	for (my $i=0; $i<@text_char_info; $i++){
		my $Info_Aref = $text_char_info[$i];
		my $char = $Info_Aref->[2];
		my $char_occupied_radian = $Info_Aref->[0] / $radius;
		$now_anchor_radian += $char_occupied_radian / 2; # middle, half part
		my ($text_cx,$text_cy) = get_coordinate_on_circle($cx, $cy, $now_anchor_radian, $radius);
		my ($text_x,$text_y) = ($text_cx,$text_cy+$y_to_add);
		## features and style
		# "font_family", "font_size", "text_col", "text_to_center", "text_rotate_degree"
		my $char_index = ($text_to_center eq 'top') ? ($#text_char_info-$i+1) : ($i+1);
		my $char_font_family = $Sub_Features_Href->{font_family}->{$char_index} || $font_family;
		my $char_font_size   = $Sub_Features_Href->{font_size}->{$char_index} || $font_size;
		my $char_text_col    = $Sub_Features_Href->{text_col}->{$char_index} || $text_col;
		my $char_text_to_center = $Sub_Features_Href->{text_to_center}->{$char_index} || $text_to_center;
		my $char_text_rotate_degree = $Sub_Features_Href->{text_rotate_degree}->{$char_index} || $text_rotate_degree;
		my $char_underline_width = $Sub_Features_Href->{underline}->{$char_index} || 0;
		# decode the font family
		# bold to font-weight; italic to font-style; leave narrow or black in font_family.
		my $char_font_weight = ' ';
		if($char_font_family =~ /bold/i){
			$char_font_weight = 'Bold';
			$char_font_family =~ s/\s?bold//i;
		}
		my $char_font_style = ' ';
		if($char_font_family =~ /italic/i){
			$char_font_style = 'Italic';
			$char_font_family =~ s/\s?italic//i;
		}
		# show text
		my $style_Href = {
						  fill=>$char_text_col,
						  'font-family'=>$char_font_family,
						  'font-weight'=>$char_font_weight,
						  'font-style'=>$char_font_style,
						  'font-size'=>$char_font_size,
						  'text-anchor'=>'middle'
						 };
		## rotate
		my $rotate_degree = $char_text_rotate_degree;
		if($char_text_to_center ne 'disabled'){
			$rotate_degree += $now_anchor_radian / $deg2rad;
			if($char_text_to_center eq 'top'){
				$rotate_degree += 180;
			}
		}
		## text
		$$SVG_object->text(
							x=>$text_x,
							y=>$text_y,
							style=>$style_Href,
							'-cdata'=>$char,
							transform=>"rotate($rotate_degree,$text_cx,$text_cy)"
						  ) if($draw_bool);
		## underline, it is a arc
		if($char_underline_width){
			# if bold
			my $bold_least_width = 1;
			if($char_font_weight =~ /bold/i){ # font_weight contains 'bold'
				$char_underline_width = max($bold_least_width, $char_underline_width);
			}
			# for arc line
			my $text_line_gap = max($char_underline_width, 2);
			my $arc_line_radius = $radius - $y_to_add;
			# reversed arc line location
			if($text_to_center eq 'top'){
				$arc_line_radius += 2 * $y_to_add + $text_line_gap;
			}
			else{
				$arc_line_radius -= $text_line_gap;
			}
			my $start_rad = $now_anchor_radian - $char_occupied_radian / 2;
			my $rad_size = $char_occupied_radian;
			# the arc rad size needs to check whether next char will be underlined, then deal the gap size.
			my $next_char_index = ($text_to_center eq 'top') ? ($#text_char_info-$i+1+1) : ($i+1+1);
			if(exists($Sub_Features_Href->{underline}->{$next_char_index})){
				$rad_size += $Info_Aref->[1] / $radius; # gap
			}
			draw_an_arc( $SVG_object,
						{
							cx=>$cx, cy=>$cy,
							start_rad=>$start_rad, rad_size=>$rad_size, 
							radius=>$arc_line_radius,
							boundary_color=>$char_text_col,
							boundary_width=>$char_underline_width,
					 		boundary_linecap=>'round',
					 		draw_bool=>$draw_bool
						}
					   );
		}
		# update now_anchor_radian for next char
		$now_anchor_radian += $char_occupied_radian / 2; # the other half part
		$now_anchor_radian += $Info_Aref->[1] / $radius; # gap
	}
	# return height and arc_radian occupied by the text
	return [$text_height, $text_width_arc_radian];
}

#--- get the size of text according to the text-anchor point ---
sub get_size_of_text_to_show{

	my $sub_routine_name = "get_size_of_text_to_show";

	my $Usage = '

		Input is Ref of Options Hash, as

		# my ($Options_Href) = @_;

		# Options_Href, enclosed by [ ] means default
		--- basic structure ---
		# font_family, ["Arial"]
		# font_size, [12]
		# text, <required>
		# single_char_gap, [0]
		                  This is prepared for single char calculation in string shown by show_text_on_arc.
		--- help ----
		# usage_print, [0]

		Use options in anonymous hash, like 
		   subroutine( { font_family=>"Times", font_size=>15, text=>"test" } );

		It will return a array contains,
		   ([anchor_above_height, anchor_below_heigh], [anchor_right_width, anchor_left_width])

		';

	my ($Options_Href) = @_;

	if($Options_Href->{usage_print} || !defined($Options_Href->{text})){
		warn "\nThe Usage of $sub_routine_name:\n";
		warn "$Usage";
		warn "\n";
		exit(1);
	}

	# Defaults
	my $font_family = $Options_Href->{font_family} || 'Arial';
	my $font_size   = $Options_Href->{font_size} || 12;
	my $text = $Options_Href->{text};
	my $single_char_gap_bool = $Options_Href->{single_char_gap} || 0;

	# transforming ratio
	my ($font_fam_basal, $transforming_ratio) = &confirm_transform_ratio({ font_family=>$font_family,
																		   font_size=>$font_size
																		  });
	# font basal
	my $font_fam_Href = $Font_Size{$font_fam_basal};
	my $char_table_Href = $font_fam_Href->{char_table};
	my $basal_size = $font_fam_Href->{size}->{basal};
	my $basal_height_Aref = $font_fam_Href->{size}->{height};
	my $basal_width_Aref  = $font_fam_Href->{size}->{width};
	my $basal_blank_size  = $font_fam_Href->{size}->{blank};
	my $basal_gap_ratio   = $font_fam_Href->{size}->{gapratio};

	# calculate the text size
	my %anchor_height;
	my %anchor_width;
	my @width_perct;
	my @char = split //,$text;

	for (my $i=0; $i<@char; $i++){

		my $char = $char[$i];

		# is a blank char
		if($char eq ' '){
			$anchor_height{above}->[$i] = 0;
			$anchor_height{below}->[$i] = 0;
			$anchor_width{right}->[$i] = $basal_blank_size;
			$anchor_width{left}->[$i]  = 0;
			next;
		}
		# rare char
		if(!exists($char_table_Href->{$char})){
			$char = 'a';
		}
		# char info hash
		my $char_height_Aref = $char_table_Href->{$char}->{height};
		my $char_width_Aref  = $char_table_Href->{$char}->{width};

		# for height
		$anchor_height{above}->[$i] = 0;
		$anchor_height{below}->[$i] = 0;
		my @h_head_occupy = &decode_char_size_symbol($char_height_Aref->[0]);
		my @h_base_occupy = &decode_char_size_symbol($char_height_Aref->[1]);
		my @h_tail_occupy = &decode_char_size_symbol($char_height_Aref->[2]);
		if(join('',@h_base_occupy) eq '00'){ # no base part, must be head or tail
			if(join('',@h_head_occupy) eq '00'){ # no head part, must be only tail part
				$anchor_height{above}->[$i] += ($h_tail_occupy[1] - 1) * $basal_height_Aref->[2];
				$anchor_height{below}->[$i] += ($h_tail_occupy[0] - 1) * $basal_height_Aref->[2];
			}
			else{ # has head part, must be only head part
				$anchor_height{above}->[$i] += $basal_height_Aref->[1]; # span a whole base part
				$anchor_height{above}->[$i] += $h_head_occupy[1] * $basal_height_Aref->[0];
				$anchor_height{below}->[$i] += $basal_height_Aref->[1]; # span a whole base part
				$anchor_height{below}->[$i] += $h_head_occupy[0] * $basal_height_Aref->[0];
			}
		}
		else{
			# count the base part firstly
			$anchor_height{above}->[$i] += $h_base_occupy[1] * $basal_height_Aref->[1];
			$anchor_height{below}->[$i] += $h_base_occupy[0] * $basal_height_Aref->[1];
			# different situation
			if(join('',@h_head_occupy) ne '00'){ # has head part
				$anchor_height{above}->[$i] += $h_head_occupy[1] * $basal_height_Aref->[0];
			}
			if(join('',@h_tail_occupy) ne '00'){ # has tail part
				$anchor_height{below}->[$i] += ($h_tail_occupy[0] - 1) * $basal_height_Aref->[2];
			}
		}
		# for width
		$anchor_width{right}->[$i] = 0;
		$anchor_width{left}->[$i]  = 0;
		my @w_left_occupy = &decode_char_size_symbol($char_width_Aref->[0]);
		my @w_base_occupy = &decode_char_size_symbol($char_width_Aref->[1]);
		my @w_right_occupy = &decode_char_size_symbol($char_width_Aref->[2]);
		if(join('',@w_base_occupy) eq '00'){ # no base part, must be left or right
			if(join('',@w_right_occupy) eq '00'){ # no right part, must be only left part
				$anchor_width{right}->[$i] += $w_left_occupy[1] * $basal_width_Aref->[0];
				$anchor_width{left}->[$i]  += $w_left_occupy[0] * $basal_width_Aref->[0];
			}
			else{ # has right part, must be only right part
				$anchor_width{right}->[$i] += $basal_width_Aref->[0] + $basal_width_Aref->[1];
				$anchor_width{right}->[$i] += $w_right_occupy[1] * $basal_width_Aref->[2];
				$anchor_width{left}->[$i]  += $basal_width_Aref->[0] + $basal_width_Aref->[1];
				$anchor_width{left}->[$i]  += $w_right_occupy[0] * $basal_width_Aref->[2];
			}
		}
		else{
			# count the base part firstly
			$anchor_width{right}->[$i] += $basal_width_Aref->[0] + $w_base_occupy[1] * $basal_width_Aref->[1];
			$anchor_width{left}->[$i]  += $basal_width_Aref->[0] + $w_base_occupy[0] * $basal_width_Aref->[1];
			if(join('',@w_right_occupy) ne '00'){ # has right part
				$anchor_width{right}->[$i] += $w_right_occupy[1] * $basal_width_Aref->[2];
			}
			if(join('',@w_left_occupy) ne '00'){ # has left part
				$anchor_width{left}->[$i]  += ($w_left_occupy[0] - 1) * $basal_width_Aref->[0];
			}
		}
	}
	# calculate the size
	my $anchor_above_height = $font_size / $basal_size * max(@{$anchor_height{above}});
	my $anchor_below_height = $font_size / $basal_size * min(@{$anchor_height{below}});
	my $size_width = $transforming_ratio * sum(@{$anchor_width{right}});
	my $to_minus = $single_char_gap_bool ? 0 : 1;
	my $gap_width  = (length($text)-$to_minus) * ($basal_blank_size * $basal_gap_ratio);
	#my $anchor_left_width   = $transforming_ratio * sum(@{$anchor_width{left}});

	return ( [$anchor_above_height, $anchor_below_height], [$size_width, $gap_width] );
}

#--- decode the symbol of each char in certain font family ---
#--- The symbol coding is designed by Wenlong Jia, author of this module ---
sub decode_char_size_symbol{
	my ($char_size_symbol) = @_;
	if($char_size_symbol =~ /^S([^,]+),U(.+)$/){
		my ($S, $U) = ($1, $2);
		if($S < 0){
			return ($S, $U);
		}
		else{
			if($U == 0){
				return (0, 0);
			}
			else{
				return ($S, $S + $U);
			}
		}
	}
	else{
		warn "Cannot decode the symbol of char size: $char_size_symbol\n";
		exit(1);
	}
}

1; ## tell the perl script the successful access of this module.
