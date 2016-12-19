package SOAPfuse::GTF;

use strict;
use warnings;
use FindBin qw/$RealScript $RealBin/;
use lib $RealBin;
use SOAPfuse::OpenFile qw/Try_GZ_Read Try_GZ_Write/;
use SOAPfuse::GTF_Info;
use SOAPfuse::General_Operation qw/warn_and_exit/;

require Exporter;

#----- systemic variables -----
our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
our ($VERSION, $DATE, $AUTHOR, $EMAIL);
@ISA = qw(Exporter);
@EXPORT = qw(read_GTF read_cytoband add_refseg_cytoband create_gene_PSL create_trans_PSL check_Start_codon_Seq);
@EXPORT_OK = qw();
%EXPORT_TAGS = ( DEFAULT => [qw()],
                 OTHER   => [qw()]);

#----- version --------
$VERSION = "0.03";
$DATE = '2016-01-08';

#----- author -----
$AUTHOR = 'Wenlong Jia';
$EMAIL = 'wenlongkxm@gmail.com';

#-------- read GTF file --------
sub read_GTF{
	my ($GTF_Info_Href,$gtf_file,$refseg_transform_list,$gtf_gene_source_Aref) = @_;

	# read refseg transforming list
	my %_refseg_transform;
	&read_refseg_transform($refseg_transform_list, \%_refseg_transform) if($refseg_transform_list);

	# gtf source selection
	my $_gtf_gene_source_string = join(',', @$gtf_gene_source_Aref);
	my $_gtf_gene_source_bool_or_Sref = (scalar(@$gtf_gene_source_Aref)==0) ? 0 : \$_gtf_gene_source_string;

	# read gtf file to GTF_Info type
	&load_GTF_Info_type_from_gtf($GTF_Info_Href, $gtf_file, \%_refseg_transform, $refseg_transform_list, $_gtf_gene_source_bool_or_Sref);

	# refine the codon info
	&refine_GTF_info($GTF_Info_Href);

	# refine the gene/transcript name
	&refine_names($GTF_Info_Href);
}

#-------- add the refseg cytoband info -------
# optional
sub add_refseg_cytoband{
	my ($GTF_Info_Href,$cytoband_Href) = @_;

	for my $_gene_ENSid (keys %$GTF_Info_Href){
		$GTF_Info_Href->{$_gene_ENSid}->add_cytoband_info($cytoband_Href);
	}

	warn "add the refseg cytoband ok.\n";
}

#-------- read cytoband info --------
# optional
sub read_cytoband{
	my ($cytoband_Href,$cytoband_file) = @_;

	open (CBD, Try_GZ_Read($cytoband_file)) || die"fail $cytoband_file: $!\n";
	while(<CBD>){
		my ($refseg,$st,$ed,$band) = (split)[0,1,2,3];
		$cytoband_Href->{$refseg}->{$.} = [$band,$st,$ed];
	}
	close CBD;

	warn "read cytoBand_file ok!\n";
}

#-------- creat trans psl file --------
sub create_trans_PSL{
	my ($GTF_Info_Href,$PSL_file) = @_;

	open (my $PSL_fh, Try_GZ_Write($PSL_file)) || die "fail create $PSL_file: $!\n";
	for my $_gene_ENSid (sort keys %$GTF_Info_Href){
		$GTF_Info_Href->{$_gene_ENSid}->write_trans_psl_info($PSL_fh);
	}
	close $PSL_fh;

	warn "write trans_PSL ok!\n";
}

#-------- creat gene psl file --------
sub create_gene_PSL{
	my ($GTF_Info_Href,$PSL_file) = @_;

	open (my $PSL_fh, Try_GZ_Write($PSL_file)) || die "fail create $PSL_file: $!\n";
	for my $_gene_ENSid (sort keys %$GTF_Info_Href){
		$GTF_Info_Href->{$_gene_ENSid}->write_gene_psl_info($PSL_fh);
	}
	close $PSL_fh;

	warn "write gene_PSL ok!\n";
}

#-------- read the file contains the refseg transform information --------
sub read_refseg_transform{
	my ($refseg_transform_list,$_refseg_transform_Href) = @_;

	open (RT, Try_GZ_Read($refseg_transform_list)) || die "cannot read $refseg_transform_list: $!\n";
	while(<RT>){
		chomp;
		my ($refseg_in_gtf,$refseg_for_use) = split /\t+/;
		$$_refseg_transform_Href{$refseg_in_gtf} = $refseg_for_use;
	}
	close RT;

	warn "read refseg transform list ok.\n";
}

#------- load the initial gtf info to GTF_Info type from the gtf file -------
sub load_GTF_Info_type_from_gtf{
	my ($GTF_Info_Href, $gtf_file, $_refseg_transform_Href, $user_set_transform_list_bool, $gtf_gene_source_Sref) = @_;

	open (my $GTF_fh, Try_GZ_Read($gtf_file)) || die "cannot read $gtf_file: $!\n";
	while(<$GTF_fh>){
		next if(/^\#/); # commend, such as "#!genome-build GRCh38.p2" in Ensemble Released v80

		my ($ref_seg, $region_type) = (split)[0,2];

		# when the refseg trans_list is set, all unspecified ref_seg will be skipped.
		next if($user_set_transform_list_bool && !exists($_refseg_transform_Href->{$ref_seg}));
		$ref_seg = $_refseg_transform_Href->{$ref_seg} || $ref_seg;

		# source selection
		if($gtf_gene_source_Sref){ # $gtf_gene_source_Sref may be 0 when users do not set any seletion.
			my ($gene_source) = (/gene_source\s\"([^\"]+)\"/);
			next if( $gene_source && $$gtf_gene_source_Sref !~ /$gene_source/ ); # gene_source may not exist in ensembl before v75
		}

		# create a GTF_Info type
		my ($gene_id) = (/gene_id\s\"([^\"]+)\"/);
		if($region_type eq 'gene'){ # firstly constrcut the gene_id key as the GTF_Info object
			$GTF_Info_Href->{$gene_id} = {}; # initialize
			SOAPfuse::GTF_Info->new($GTF_Info_Href->{$gene_id}, $ref_seg, $_);
		}
		else{
			if( exists($GTF_Info_Href->{$gene_id}) ){
				$GTF_Info_Href->{$gene_id}->load_gtf_info($_);
			}
			else{ # if the transcript comes, but no its gene_id GTF_Info object found, it will be warned. (version before v75).
				warn ("The gtf source lacks the line of 'gene' information of $gene_id. Reconstructed it.\n");
				# reconstructed GTF_Info object
				$GTF_Info_Href->{$gene_id} = {}; # initialize
				SOAPfuse::GTF_Info->new($GTF_Info_Href->{$gene_id}, $ref_seg, $_);
				# load more info
				$GTF_Info_Href->{$gene_id}->load_gtf_info($_);
			}
		}
	}
	close $GTF_fh;

	warn "load initial gtf info ok.\n";
}

#------- refine the codon number of transcript -------
sub refine_GTF_info{
	my ($GTF_Info_Href) = @_;

	for my $_gene_ENSid (keys %$GTF_Info_Href){
		$GTF_Info_Href->{$_gene_ENSid}->refine_gtf_info;
	}

	warn "refine the gtf info ok.\n";
}

#------- refine the name of gene and transcript -------
sub refine_names{
	my ($GTF_Info_Href) = @_;

	my (%_genename_count,%_transname_count);
	for my $_gene_ENSid (keys %$GTF_Info_Href){
		my $gene = $GTF_Info_Href->{$_gene_ENSid};
		my $_gene_use_name = $gene->get_gene_use_name;
		$_genename_count{$_gene_use_name}++;
		my @_trans_use_name = $gene->get_trans_use_name;
		$_transname_count{$_}++ for @_trans_use_name;
	}

	for my $_gene_ENSid (keys %$GTF_Info_Href){
		my $gene = $GTF_Info_Href->{$_gene_ENSid};
		my $_gene_use_name = $gene->get_gene_use_name;
		if($_genename_count{$_gene_use_name} > 1){ # this gene use name appears more than 1 time
			$gene->{gene_use_name} = $gene->{gene_ori_name} . '_' . $_gene_ENSid;
		}
		for my $_trans_ENSid (keys %{$gene->{trans_info}}){
			my $trans = $gene->{trans_info}->{$_trans_ENSid};
			my $_trans_use_name = $trans->{trans_use_name};
			if($_transname_count{$_trans_use_name} > 1){ # this trans use name appears more than 1 time
				$trans->{trans_use_name} = $trans->{trans_ori_name} . '_' . $_trans_ENSid;
			}
		}
	}

	warn "refine gene/trans names ok.\n";
}

#----------- refine the start codon seq according to the genome ---------
sub check_Start_codon_Seq{
	my ($GTF_Info_Href,$Start_codon_Aref,$whole_genome) = @_;

	warn "check strat codon sequence now...\n";

	my $Start_codon_Href = {};
	%$Start_codon_Href= map {(uc($_),1)} @$Start_codon_Aref;
	warn "Standard strat codon sequence: ".join(',',sort keys %$Start_codon_Href)."\n";

	# select the protein coding transcript
	my $Refseg_to_StartCodon_Href = {};
	for my $_gene_ENSid (keys %$GTF_Info_Href){
		my $gene_Href = $GTF_Info_Href->{$_gene_ENSid};
		my $ref_seg = $gene_Href->{ref_seg};
		for my $_trans_ENSid (keys %{$gene_Href->{trans_info}}){
			# only deal protein_coding
			my $trans_biotype = $gene_Href->{trans_info}->{$_trans_ENSid}->{trans_biotype};
			if($trans_biotype eq 'protein_coding'){
				$Refseg_to_StartCodon_Href->{$ref_seg}->{$_gene_ENSid} = 1; # store the gene Href to save the memory
				last; # find one protein_coding, no need to next loop
			}
		}
	}

	# read genome, fasta format
	open (my $SOU,"$whole_genome")||die "fail $whole_genome: $!\n";
	$/=">";<$SOU>;$/="\n";
	while(<$SOU>){
		chomp(my $ref_seg = $_); ## remove the last "\n"
		$/=">";
		chomp(my $ref_seg_seq = <$SOU>); ## remove the last '>'
		$/="\n";
		next unless(exists($Refseg_to_StartCodon_Href->{$ref_seg}));
		$ref_seg_seq =~ s/\s+//g;
		foreach my $_gene_ENSid (keys %{$Refseg_to_StartCodon_Href->{$ref_seg}}) {
			my $gene_Href = $GTF_Info_Href->{$_gene_ENSid};
			my $strand = $gene_Href->{strand};
			for my $_trans_ENSid (keys %{$gene_Href->{trans_info}}){
				my $trans_Href = $gene_Href->{trans_info}->{$_trans_ENSid};
				# only deal protein_coding
				my $trans_biotype = $trans_Href->{trans_biotype};
				if($trans_biotype eq 'protein_coding'){
					my $StartCodon_Seq = '';
					for my $StartCodon_Pos (sort {$a<=>$b} keys %{$trans_Href->{start_codon}}){
						$StartCodon_Seq .= uc(substr($ref_seg_seq,$StartCodon_Pos-1,1));
					}
					# for minus strand gene
					($StartCodon_Seq = reverse $StartCodon_Seq) =~ tr/ACGT/TGCA/ if($strand eq '-');
					# judge the startcodon seq
					unless(exists($Start_codon_Href->{$StartCodon_Seq})){
						$trans_Href->{trans_biotype} = "protein_coding_with_abnor_st_codon_seq($StartCodon_Seq)";
						warn "  $trans_Href->{ENSid} $trans_Href->{trans_ori_name} has abnormal start codon sequence: $StartCodon_Seq\n";
					}
				}
			}
		}
	}
	close $SOU;

	warn "check start codon seq ok!\n";
}

1; ## tell the perl script the successful access of this module.
