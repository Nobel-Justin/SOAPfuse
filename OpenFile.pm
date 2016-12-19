package SOAPfuse::OpenFile;

use strict;
use warnings;
use File::Basename qw/basename dirname/;
use FindBin qw/$RealScript $RealBin/;
use Cwd qw/abs_path/;
require Exporter;

#----- systemic variables -----
our (@ISA, @EXPORT, $VERSION, @EXPORT_OK, %EXPORT_TAGS);
@ISA = qw(Exporter);
@EXPORT = qw(Try_GZ_Read Try_GZ_Write);
@EXPORT_OK = qw();
%EXPORT_TAGS = ( DEFAULT => [qw()],
                 OTHER   => [qw()]);
#----- version --------
$VERSION = "0.0.2";

#-------- based on the postfix, to read gz file --------
sub Try_GZ_Read{
	my ($file) = @_;

	my $file_comd = `file $file`; # get the file format via 'file' linux command

	if($file_comd =~ /ASCII\s*text/){
		return "$file";
	}
	elsif($file_comd =~ /gzip\s*compressed\s*data/ || $file =~ /\.gz$/){ # gzip format
		return "gzip -cd $file |";
	}
	else{ # unspecified format
		return "$file";
	}
}

#-------- based on the postfix, to write gz file --------
sub Try_GZ_Write{
	my ($file) = @_;

	my $file_comd = (-e $file)?`file $file`:''; # get the file format via 'file' linux command

	if($file_comd =~ /ASCII\s*text/){
		return ">$file";
	}
	elsif($file_comd =~ /gzip\s*compressed\s*data/ || $file =~ /\.gz$/){ # gzip format
		return "| gzip -c > $file";
	}
	else{ # unspecified format
		return ">$file";
	}
}

1; ## tell the perl script the successful access of this module.
