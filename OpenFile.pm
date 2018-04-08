package SOAPfuse::OpenFile;

use strict;
use warnings;
use File::Basename qw/dirname/;
require Exporter;

#----- systemic variables -----
our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
our ($VERSION, $DATE, $AUTHOR, $EMAIL, $MODULE_NAME);
@ISA = qw(Exporter);
@EXPORT = qw/
			  Try_GZ_Read
			  is_idx_bgz
			  Try_GZ_Write
		  /;
@EXPORT_OK = qw();
%EXPORT_TAGS = ( DEFAULT => [qw()],
                 OTHER   => [qw()]);

$MODULE_NAME = 'OpenFile';
#----- version --------
$VERSION = "0.07";
$DATE = '2018-03-19';

#----- author -----
$AUTHOR = 'Wenlong Jia';
$EMAIL = 'wenlongkxm@gmail.com';

#--------- functions in this pm --------#
my @functoion_list = qw/
						Try_GZ_Read
						is_idx_bgz
						Try_GZ_Write
					 /;

#--- based on the postfix, to read gz file ---
sub Try_GZ_Read{
	# options
	shift if ($_[0] =~ /::$MODULE_NAME/);
	my $file = shift @_;
	my %parm = @_;
	# attributes
	my $idx_readReg = $parm{idx_readReg};
	my $tabix = $parm{tabix};

	# file existence
	unless(-e $file){
		warn "Not exist: $file\n";
		exit(1);
	}

	# try to read region via index
	if( defined $idx_readReg && defined $tabix ){
		if( &is_idx_bgz(file=>$file, check_tbi=>1) ){
			return "set -o pipefail; $tabix $file $idx_readReg |";
		}
		else{
			warn "Not indexed bgz: $file\n";
			exit(1);
		}
	}

	# get the file format via 'file' linux command
	my $file_comd = `file $file`;

	if( $file_comd =~ /ASCII\s*text/ ){
		return "$file";
	}
	elsif(    $file_comd =~ /gzip\s*compressed\s*data/
		   || $file =~ /\.[bt]?gz$/
	){ # gzip format
		return "set -o pipefail; gzip -cd $file |";
	}
	else{ # unspecified format
		return "$file";
	}
}

#--- judgement on indexed .[bt]gz file ---
sub is_idx_bgz{
	# options
	shift if ($_[0] =~ /::$MODULE_NAME/);
	my %parm = @_;
	my $file = $parm{file};
	my $check_tbi = $parm{check_tbi} || 0;

	if(    $file =~ /\.[bt]gz$/
	    && (!$check_tbi || -e "$file.tbi")
	){
		return 1;
	}
	else{
		return 0;
	}
}

#--- based on the postfix, to write gz file ---
sub Try_GZ_Write{
	# options
	shift if ($_[0] =~ /::$MODULE_NAME/);
	my $file = shift @_;
	my %parm = @_;
	# attributes
	my $bgzip = $parm{bgzip};

	# write authority
	my $file_folder = dirname($file);
	unless(-w $file_folder){
		warn "Cannot write in folder $file_folder\n";
		exit(1);
	}

	# get the file format via 'file' linux command
	my $file_comd = (-e $file)?`file $file`:'';

	if( $file_comd =~ /ASCII\s*text/ ){
		return ">$file";
	}
	elsif( $file =~ /\.gz$/ ){ # gzip
		return "| gzip -c > $file";
	}
	elsif( $file =~ /\.[bt]gz$/ ){ # bgzip
		if( defined $bgzip && -e $bgzip ){
			return "| $bgzip -c > $file";
		}
		else{
			warn "<ERROR>:\tNo bgzip bin given when try to generate [bt]gz file.\n"
						."\t$file\n"
						."\tfrom Module:$MODULE_NAME\n";
			exit(1);
		}
	}
	elsif( $file_comd =~ /gzip\s*compressed\s*data/ ){ # typo name of file in gzip format
		warn "<WARN>:\tNot standard file when try to generate gzip format file.\n"
					."\t$file\n"
					."\tfrom Module:$MODULE_NAME\n";
		return "| gzip -c > $file";
	}
	else{ # unspecified format
		return ">$file";
	}
}

1; ## tell the perl script the successful access of this module.
