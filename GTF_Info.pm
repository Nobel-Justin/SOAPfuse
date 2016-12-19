package SOAPfuse::GTF_Info;

use strict;
use warnings;
use List::Util qw[min max sum];
use FindBin qw/$RealScript $RealBin/;
use lib $RealBin;
use SOAPfuse::General_Operation qw/Get_Two_Seg_Olen/;

require Exporter;

#----- systemic variables -----
our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
our ($VERSION, $DATE, $AUTHOR, $EMAIL);
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw();
%EXPORT_TAGS = ( DEFAULT => [qw()]);

#----- version --------
$VERSION = "0.04";
$DATE = '2016-01-08';

#----- author -----
$AUTHOR = 'Wenlong Jia';
$EMAIL = 'wenlongkxm@gmail.com';

sub new{
	shift;
	my ($gene, $ref_seg, $gtf_lineinfo) = @_;

	# other info
	$_ = $gtf_lineinfo; # actually, the $_ originally stores the lineinfo from gtf file
	my ($gtf_source_or_geneBiotype,$region_type,$strand) = (split /\t+/)[1,2,6];

	# basic info of gene
	unless(exists($gene->{ENSid})){

		my ($gene_ENSid) = (/gene_id\s\"([^\"]+)\"/);

		my ($gene_name) = (/gene_name\s\"([^\"]+)\"/);
		($gene_name ||= 'NA-'.$gene_ENSid) =~ s/[\(\)\/\\\s]+/_/g;

		my ($gene_source) = (/gene_source\s\"([^\"]+)\"/);
		$gene_source ||= 'NA'; # former versions (before v75) do not contain.

		my ($gene_version) = (/gene_version\s\"([^\"]+)\"/);
		$gene_version = $gene_version ? ('v'.$gene_version) : 'NA'; # former versions (before v77) do not contain.

		my ($gene_biotype) = (/gene_biotype\s\"([^\"]+)\"/);
		$gene_biotype ||= $gtf_source_or_geneBiotype; # former versions (long-long ago..) do not contain, but list it at column NO.2

		# load attributes
		$gene->{ENSid} = $gene_ENSid;
		$gene->{source} = $gene_source;
		$gene->{version} = $gene_version;
		$gene->{gene_biotype} = $gene_biotype;
		$gene->{gene_ori_name} = $gene_name;
		$gene->{gene_use_name} = $gene_name;
		$gene->{ref_seg} = $ref_seg;
		$gene->{strand} = $strand;
	}

	bless($gene);
}

# load the gtf info to the GTF_Info object, such as transcript, exon, CDS, codon, ...
sub load_gtf_info{
	my $gene = shift;
	my ($gtf_lineinfo) = @_;

	# other info
	$_ = $gtf_lineinfo; # actually, the $_ originally stores the lineinfo from gtf file
	my ($gtf_source_or_transBiotype,$region_type,$st,$ed,$strand) = (split /\t+/)[1,2,3,4,6];

	# basic info of transcript
	my ($trans_ENSid) = (/transcript_id\s\"([^\"]+)\"/);
	unless(exists($gene->{trans_info}->{$trans_ENSid})){

		my ($trans_name) = (/transcript_name\s\"([^\"]+)\"/);
		($trans_name ||= 'NA-'.$trans_ENSid) =~ s/[\(\)\/\\\s]+/_/g;

		my ($transcript_source) = (/transcript_source\s\"([^\"]+)\"/);
		$transcript_source ||= 'NA'; # former versions (before v75) do not contain.

		my ($transcript_version) = (/transcript_version\s\"([^\"]+)\"/);
		$transcript_version = $transcript_version ? ('v'.$transcript_version) : 'NA'; # former versions (before v77) do not contain.

		my ($transcript_biotype) = (/transcript_biotype\s\"([^\"]+)\"/);
		$transcript_biotype ||= $gtf_source_or_transBiotype; # former versions (long-long ago..) do not contain, but list it at column NO.2

		# load attributes
		$gene->{trans_info}->{$trans_ENSid}->{ENSid} = $trans_ENSid;
		$gene->{trans_info}->{$trans_ENSid}->{source} = $transcript_source;
		$gene->{trans_info}->{$trans_ENSid}->{trans_version} = $transcript_version;
		$gene->{trans_info}->{$trans_ENSid}->{trans_biotype} = $transcript_biotype;
		$gene->{trans_info}->{$trans_ENSid}->{trans_ori_name} = $trans_name;
		$gene->{trans_info}->{$trans_ENSid}->{trans_use_name} = $trans_name;
	}

	# exon info of transcript
	if($region_type =~ /exon/i){
		my ($exon_NO) = (/exon_number\s\"([^\"]+)\"/);
		$gene->{trans_info}->{$trans_ENSid}->{exon}->{$st} = $ed;
	}

	# CDS info of transcript, if available
	if($region_type =~ /CDS/i){
		$gene->{trans_info}->{$trans_ENSid}->{CDS}->{$st} = $ed;
		my ($protein_ENSid) = (/protein_id\s\"([^\"]+)\"/);
		$protein_ENSid ||= 'NA';
		$gene->{trans_info}->{$trans_ENSid}->{protein_ENSid} = $protein_ENSid;
	}

	# Codon
	if($region_type =~ /codon/i){
		$region_type = lc($region_type);
		$gene->{trans_info}->{$trans_ENSid}->{$region_type}->{$_} = 1 for ($st .. $ed);
	}
}

# return the gene use name
sub get_gene_use_name{
	my $gene = shift;
	return $gene->{gene_use_name};
}

# return the gene original name
sub get_gene_ori_name{
	my $gene = shift;
	return $gene->{gene_ori_name};
}

# return the trans use names
sub get_trans_use_name{
	my $gene = shift;
	my @_trans_name;
	for my $_trans_ENSid (keys %{$gene->{trans_info}}){
		my $trans = $gene->{trans_info}->{$_trans_ENSid};
		push @_trans_name , $trans->{trans_use_name};
	}
	return @_trans_name;
}

# return the trans original names
sub get_trans_ori_name{
	my $gene = shift;
	my @_trans_name;
	for my $_trans_ENSid (keys %{$gene->{trans_info}}){
		my $trans = $gene->{trans_info}->{$_trans_ENSid};
		push @_trans_name , $trans->{trans_ori_name};
	}
	return @_trans_name;
}

# note trans_biotype with abnormal number of codon
sub refine_gtf_info{
	my $gene = shift;
	my ($gene_small_edge,$gene_large_edge);
	for my $_trans_ENSid (keys %{$gene->{trans_info}}){
		my $trans = $gene->{trans_info}->{$_trans_ENSid};
		# refine protein's info
		my $trans_biotype = $trans->{trans_biotype};
		if($trans_biotype eq 'protein_coding'){
			my $st_codon = (exists($trans->{start_codon}))?(keys %{$trans->{start_codon}}):0;
			my $sp_codon = (exists($trans->{stop_codon}))?(keys %{$trans->{stop_codon}}):0;
			if($st_codon != 3 && $sp_codon != 3){
				$trans->{trans_biotype} = "protein_coding_with_abnor_codon_num($st_codon,$sp_codon)";
			}
			elsif($st_codon != 3 && $sp_codon == 3){
				$trans->{trans_biotype} = "protein_coding_with_abnor_st_codon_num($st_codon)";
			}
			elsif($st_codon == 3 && $sp_codon != 3){
				$trans->{trans_biotype} = "protein_coding_with_abnor_sp_codon_num($sp_codon)";
			}
		}
		# exon check
		my ($trans_small_edge,$trans_large_edge);
		$trans->{exon_number} = scalar(keys %{$trans->{exon}});
		for my $exon_small_edge (sort {$a<=>$b} keys %{$trans->{exon}}){
			my $exon_large_edge = $trans->{exon}->{$exon_small_edge};
			$trans_small_edge = (defined($trans_small_edge))?min($trans_small_edge,$exon_small_edge):$exon_small_edge;
			$trans_large_edge = (defined($trans_large_edge))?max($trans_large_edge,$exon_large_edge):$exon_large_edge;
		}
		# transcript region
		$trans->{small_edge} = $trans_small_edge;
		$trans->{large_edge} = $trans_large_edge;
		$gene_small_edge = (defined($gene_small_edge))?min($gene_small_edge,$trans_small_edge):$trans_small_edge;
		$gene_large_edge = (defined($gene_large_edge))?max($gene_large_edge,$trans_large_edge):$trans_large_edge;
	}
	# gene region
	$gene->{small_edge} = $gene_small_edge;
	$gene->{large_edge} = $gene_large_edge;
}

# add cytoband info
sub add_cytoband_info{
	my $gene = shift;
	my $cytoband_Href = shift;
	my $refseg = $gene->{ref_seg};
	$gene->{cytoband} = &judge_the_cytoband($refseg,$cytoband_Href,$gene->{small_edge},$gene->{large_edge});
	for my $_trans_ENSid (keys %{$gene->{trans_info}}){
		my $trans = $gene->{trans_info}->{$_trans_ENSid};
		$trans->{cytoband} = &judge_the_cytoband($refseg,$cytoband_Href,$trans->{small_edge},$trans->{large_edge});
	}
}

# judge the refseg cytoband based on the region
sub judge_the_cytoband{
	my ($ref_seg,$cytoBand_Href,$aim_small,$aim_large) = @_;

	my @band;
	for my $NO (sort {$a<=>$b} keys %{$$cytoBand_Href{$ref_seg}}){
		my ($band,$st,$ed) = @{$$cytoBand_Href{$ref_seg}{$NO}};
		if(Get_Two_Seg_Olen($st,$ed,$aim_small,$aim_large)){
			push @band,$band;
		}
	}
	my $band_string = (scalar(@band))?join(',',@band):'NA';

	return $band_string;
}

# write the trans PSL info into the file handle
sub write_trans_psl_info{
	my $gene = shift;
	my $psl_fh = shift;
	my $gene_use_name = $gene->{gene_use_name};
	my $strand = $gene->{strand};
	my $refseg = $gene->{ref_seg};
	for my $_trans_ENSid (keys %{$gene->{trans_info}}){
		my $trans = $gene->{trans_info}->{$_trans_ENSid};
		my $trans_ori_name = $trans->{trans_ori_name};
		my $trans_use_name = $trans->{trans_use_name};
		my $trans_source = $trans->{source};
		my $trans_version = $trans->{trans_version};
		my $trans_biotype = $trans->{trans_biotype};
		# protein_coding info, if available
		my @start_codon = (exists($trans->{start_codon}))?(sort {$a<=>$b} keys %{$trans->{start_codon}}):();
		my @stop_codon = (exists($trans->{stop_codon}))?(sort {$a<=>$b} keys %{$trans->{stop_codon}}):();
		my $protein_id = $trans->{protein_ENSid} || 'NA';
		# transcript location region
		my $small_edge = $trans->{small_edge};
		my $large_edge = $trans->{large_edge};
		my $cytoband = $trans->{cytoband} || 'NA';
		# exon region info
		my $exon_number = $trans->{exon_number};
		my (@exon_small_edge,@exon_len);
		for my $exon_small_edge (sort {$a<=>$b} keys %{$trans->{exon}}){
			my $exon_large_edge = $trans->{exon}->{$exon_small_edge};
			push @exon_small_edge , $exon_small_edge - 1;
			push @exon_len , $exon_large_edge - $exon_small_edge + 1;
		}
		# CDS region info, if available
		my (@CDS_region_info);
		if(exists($trans->{CDS})){
			for my $CDS_small_edge (sort {$a<=>$b} keys %{$trans->{CDS}}){
				my $CDS_large_edge = $trans->{CDS}->{$CDS_small_edge};
				push @CDS_region_info , ($CDS_small_edge-1).'('.($CDS_large_edge-$CDS_small_edge+1).')';
			}
		}

		#------- Format defination of trans PSL file -----------#
		#------- customized by SOAPfuse ------------------------#
		# Note: all the smallest edge position of region has been subtracted by 1, other info, such as largest edge
		#       or point position (e.g., start_codon) remains no changes.
		#  column_NO.    Description
		#           1    transcript source
		#           2    transcript version
		#           3           Reserved
		#           4           Reserved
		#           5    start_codon info, if available
		#           6    stop_codon info, if available
		#           7    protein ENS_id, if available
		#           8           Reserved
		#           9    sense strand
		#          10    transcript name for bioinformatics analysis
		#          11    transcript ENS_id
		#          12    transcript name (original) from the GTF file
		#          13    biotype
		#          14    refseg
		#          15    cytoband on refseg
		#          16    the smallest position on the plus strand of the refseg, and subtract 1
		#          17    the largest  position on the plus strand of the refseg, no modification
		#          18    the number of exon
		#          19    length of each exon, corresponding to the NO.21 column
		#          20    CDS region info, if available format: smallest_position(len), sorted by small->large
		#          21    the smallest position on the plus strand of the refseg of each exon, sorted by small->large
		#          22    gene name for bioinformatics analysis
		#-------------------------------------------------------#
		print $psl_fh $trans_source."\t";
		print $psl_fh $trans_version."\t";
		print $psl_fh "0\t" for (3 .. 4);
		print $psl_fh join(',',@start_codon).",\t";
		print $psl_fh join(',',@stop_codon).",\t";
		print $psl_fh $protein_id."\t";
		print $psl_fh "0\t";
		print $psl_fh $strand."\t";
		print $psl_fh $trans_use_name."\t";
		print $psl_fh $_trans_ENSid."\t";
		print $psl_fh $trans_ori_name."\t";
		print $psl_fh $trans_biotype."\t";
		print $psl_fh $refseg."\t";
		print $psl_fh $cytoband."\t";
		print $psl_fh ($small_edge-1)."\t";
		print $psl_fh $large_edge."\t";
		print $psl_fh $exon_number."\t";
		print $psl_fh join(',',@exon_len).",\t";
		print $psl_fh join(',',@CDS_region_info).",\t";
		print $psl_fh join(',',@exon_small_edge).",\t";
		print $psl_fh $gene_use_name."\n";
	}
}

# write the gene PSL info into the file handle
sub write_gene_psl_info{
	my $gene = shift;
	my $psl_fh = shift;
	my $gene_ENSid = $gene->{ENSid};
	my $gene_ori_name = $gene->{gene_ori_name};
	my $gene_use_name = $gene->{gene_use_name};
	my $gene_source = $gene->{source};
	my $gene_version = $gene->{version};
	my $gene_biotype = $gene->{gene_biotype};
	my $strand = $gene->{strand};
	my $refseg = $gene->{ref_seg};
	# gene location region
	my $small_edge = $gene->{small_edge};
	my $large_edge = $gene->{large_edge};
	my $cytoband = $gene->{cytoband} || 'NA';
	# exon region info
	my %exon;
	for my $_trans_ENSid (keys %{$gene->{trans_info}}){
		my $trans = $gene->{trans_info}->{$_trans_ENSid};
		for my $exon_small_edge (sort {$a<=>$b} keys %{$trans->{exon}}){
			my $exon_large_edge = $trans->{exon}->{$exon_small_edge};
			$exon{$exon_small_edge}{($exon_large_edge-$exon_small_edge+1)} = 1;
		}
	}
	my (@exon_small_edge,@exon_len);
	for my $exon_small_edge (sort {$a<=>$b} keys %exon){
		for my $exon_len (sort {$a<=>$b} keys %{$exon{$exon_small_edge}}){
			push @exon_small_edge , $exon_small_edge - 1;
			push @exon_len , $exon_len;
		}
	}
	my $exon_number = scalar(@exon_small_edge);
	# non-redundant exon region
	my (@non_redundant_exon);
	my ($now_exon_small_edge,$now_exon_large_edge) = ($exon_small_edge[0]+1,$exon_small_edge[0]+$exon_len[0]);
	for my $exon_NO (1 .. $exon_number){
		my $exon_small_edge = $exon_small_edge[$exon_NO-1] + 1;
		my $exon_large_edge = $exon_small_edge[$exon_NO-1] + $exon_len[$exon_NO-1];
		if($exon_small_edge <= $now_exon_large_edge+1){ # exons could combined
			$now_exon_large_edge = max($now_exon_large_edge,$exon_large_edge);
		}
		else{
			push @non_redundant_exon , ($now_exon_small_edge-1).'('.($now_exon_large_edge-$now_exon_small_edge+1).')';
			$now_exon_small_edge = $exon_small_edge;
			$now_exon_large_edge = $exon_large_edge;
		}
		# last exon must be output
		if($exon_NO == $exon_number){
			push @non_redundant_exon , ($now_exon_small_edge-1).'('.($now_exon_large_edge-$now_exon_small_edge+1).')';
		}
	}

	#------- Format defination of gene PSL file ------------#
	#------- customized by SOAPfuse ------------------------#
	# Note: all the smallest edge position of region has been subtracted by 1, other info, such as largest edge
	#       or point position remains no changes.
	#  column_NO.    Description
	#           1    gene source
	#           2    gene version
	#           3           Reserved
	#           4           Reserved
	#           5           Reserved
	#           6           Reserved
	#           7           Reserved
	#           8           Reserved
	#           9    sense strand
	#          10    gene name for bioinformatics analysis
	#          11    gene ENS_id
	#          12    gene name (original) from the GTF file
	#          13    gene biotype
	#          14    refseg
	#          15    cytoband on refseg
	#          16    the smallest position on the plus strand of the refseg, and subtract 1
	#          17    the largest  position on the plus strand of the refseg, no modification
	#          18    the number of exon
	#          19    length of each exon, corresponding to the NO.21 column
	#          20    non-redundant exon region info, format: smallest_position(len), sorted by small->large
	#          21    the smallest position on the plus strand of the refseg of each exon, sorted by small->large
	#-------------------------------------------------------#
	print $psl_fh $gene_source."\t";
	print $psl_fh $gene_version."\t";
	print $psl_fh "0\t" for (3 .. 8);
	print $psl_fh $strand."\t";
	print $psl_fh $gene_use_name."\t";
	print $psl_fh $gene_ENSid."\t";
	print $psl_fh $gene_ori_name."\t";
	print $psl_fh $gene_biotype."\t";
	print $psl_fh $refseg."\t";
	print $psl_fh $cytoband."\t";
	print $psl_fh ($small_edge-1)."\t";
	print $psl_fh $large_edge."\t";
	print $psl_fh $exon_number."\t";
	print $psl_fh join(',',@exon_len).",\t";
	print $psl_fh join(',',@non_redundant_exon).",\t";
	print $psl_fh join(',',@exon_small_edge).",\n";
}

1; ## tell the perl script the successful access of this module.