package SOAPfuse::PSL;

use strict;
use warnings;
use FindBin qw/ $RealScript $RealBin /;
use lib $RealBin;
use SOAPfuse::OpenFile qw/ Try_GZ_Read Try_GZ_Write /;

require Exporter;

#----- systemic variables -----
our (@ISA, @EXPORT, $VERSION, @EXPORT_OK, %EXPORT_TAGS);
@ISA = qw(Exporter);
@EXPORT = qw(read_unit_region_from_PSL extract_exon_seq_from_genome_and_output);
@EXPORT_OK = qw();
%EXPORT_TAGS = ( DEFAULT => [qw()],
                 OTHER   => [qw()]);
#----- version --------
$VERSION = "0.0.1";

#-------- read GTF file --------
sub read_unit_region_from_PSL{
    my ($Refseg_Exon_Info_Href,$psl_file,$avoid_refseg_Aref) = @_;

    # refseg user want to avoid
    my %avoid_refseg;
    @avoid_refseg{@$avoid_refseg_Aref} = () if($avoid_refseg_Aref);

    open (PSL, Try_GZ_Read($psl_file)) || die"fail $psl_file: $!\n";
    while(<PSL>){
        my ($strand,$unit,$refseg,$length,$positive_st) = (split)[8,9,13,18,20];
        next if(exists($avoid_refseg{$refseg})); # refseg ignored by user
        #--- change the pos to non-overlapped regions ---
        my @length = split /,/,$length;
        my @positive_st = split /,/,$positive_st;
        &modify_pos_info(\@length,\@positive_st);
        #-------- record the trans pos info --------
        @{$$Refseg_Exon_Info_Href{$refseg}{$unit}} = ($strand,\@length,\@positive_st);
    }
    close PSL;

    print STDERR "Read exon region from PSL ok.\n";
}

#-------- modify the psl pos info ----------
sub modify_pos_info{
    my ($length_array,$positive_st_array) = @_;
    my %uniq_pos;
    for (my $i=0;$i!=scalar(@$positive_st_array);++$i) {
        $uniq_pos{$_} = 1 for ($$positive_st_array[$i]+1 .. $$positive_st_array[$i]+$$length_array[$i]);
    }
    @$length_array = ();
    @$positive_st_array = ();
    my $lastpos = -1;
    my $now_len = 0;
    foreach my $pos (sort {$a<=>$b} keys %uniq_pos) {
        if($pos != $lastpos+1){ ## not continuous
            push @$positive_st_array,$pos-1;
            if($now_len != 0){
                push @$length_array,$now_len;
            }
            $now_len = 0;
        }
        ++$now_len;
        $lastpos = $pos;
    }
    push @$length_array,$now_len;
}

#------- output base ------
sub extract_exon_seq_from_genome_and_output{
    my ($Refseg_Exon_Info_Href,$out,$whole_genome) = @_;

    my $line_base = 50; # 50 bases each line
    open (SOU, Try_GZ_Read($whole_genome))||die "fail $whole_genome: $!\n";
    open (OUT, Try_GZ_Write($out)) || die "fail $out: $!\n";
    $/=">";<SOU>;$/="\n";
    while(<SOU>){
        chomp(my $refseg = $_); ## remove the last "\n"
        $/=">";
        chomp(my $refseg_seq = <SOU>); ## remove the last '>'
        $/="\n";
        next if(!exists($$Refseg_Exon_Info_Href{$refseg})); # discard chrM
        $refseg_seq =~ s/\s+//g;
        foreach my $unit (sort keys %{$$Refseg_Exon_Info_Href{$refseg}}) {
            my ($strand,$exon_len_Aref,$exon_plus_st_Aref) = @{$$Refseg_Exon_Info_Href{$refseg}{$unit}};
            my $unit_seq = '';
            for my $i (1 .. scalar(@$exon_len_Aref)){
                my $exon_len = $$exon_len_Aref[$i-1];
                my $exon_plus_st = $$exon_plus_st_Aref[$i-1] + 1;
                my $exon_seq = uc(substr($refseg_seq,$exon_plus_st-1,$exon_len));
                if($strand eq '-'){ # reversed complementary
                    ($exon_seq = reverse $exon_seq) =~ tr/ACGT/TGCA/;
                    $unit_seq = $exon_seq.$unit_seq;
                }
                else{
                    $unit_seq .= $exon_seq;
                }
            }
            print OUT ">$unit\n";
            print OUT substr($unit_seq,$_*$line_base,$line_base)."\n" for (0 .. int((length($unit_seq)-1)/$line_base));
            # once ok delete the unit
            delete $$Refseg_Exon_Info_Href{$refseg}{$unit};
        }
    }
    close SOU;
    close OUT;

    print STDERR "Create Exon_Seq file $out ok!\n";

    # check the remained unit
    for my $refseg (keys %$Refseg_Exon_Info_Href){
        for my $unit (sort keys %{$$Refseg_Exon_Info_Href{$refseg}}){
            print STDERR "<warn>:  Unit $unit from Refseg $refseg remains undetected.\n";
        }
    }
}

1; ## tell the perl script the successful access of this module.
