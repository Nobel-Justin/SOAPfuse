package SOAPfuse::General_Operation;

use strict;
use warnings;
use File::Basename qw/basename dirname/;
use FindBin qw/$Script $RealBin/;
use Cwd qw/abs_path/;
use File::Spec qw/catfile/;
use List::Util qw[min max sum];
use JSON qw/encode_json/;
use SOAPfuse::OpenFile qw/Try_GZ_Read Try_GZ_Write/;
require Exporter;

#----- systemic variables -----
our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
our ($VERSION, $DATE, $AUTHOR, $EMAIL, $MODULE_NAME);
@ISA = qw(Exporter);
@EXPORT = qw/
			  merge_genome_region
			  get_tissue_postfix
			  determine_sample_tissue_type
			  sample2patient
			  warn_and_exit
			  stout_and_sterr
			  Get_Two_Seg_Olen
			  prepare_HGNC_genefamily
			  Load_Codon
			  trible_run_for_success
			  read_config load_script
			  read_ins_report_for_ins
			  read_ins_report_for_trimmed_length
			  write_fasta_file
			/;
@EXPORT_OK = qw();
%EXPORT_TAGS = ( DEFAULT => [qw()],
                 OTHER   => [qw()]);

$MODULE_NAME = 'General_Operation';
#----- version --------
$VERSION = "0.20";
$DATE = '2016-07-10';

#----- author -----
$AUTHOR = 'Wenlong Jia';
$EMAIL = 'wenlongkxm@gmail.com';


#--------- functions in this pm --------#
my @functoion_list = qw/
						merge_genome_region
						prepare_HGNC_genefamily
						Load_Codon
						Get_Two_Seg_Olen
						get_tissue_postfix
						determine_sample_tissue_type
						sample2patient
						trible_run_for_success
						read_config
						load_script
						read_ins_report_for_ins
						read_ins_report_for_trimmed_length
						warn_and_exit
						stout_and_sterr
						write_fasta_file
					 /;

#-------- try to merge genome region ---------#
sub merge_genome_region{
	my $Option_Href = ($_[0]=~/::$MODULE_NAME/) ? $_[1] : $_[0];

	my $Region_Href = $Option_Href->{Region_Href};
	my $Next_RegNO = $Option_Href->{Next_RegNO};

	for my $ref_seg (sort keys %$Region_Href){
		MERGE: {
			my $overlap_sign = 0;
			my @reg_NO = sort {$a<=>$b} keys %{$Region_Href->{$ref_seg}};
			for my $reg_NO_1 (@reg_NO){
				next unless( exists($Region_Href->{$ref_seg}->{$reg_NO_1}) );
				my ($st_1, $ed_1) = @{ $Region_Href->{$ref_seg}->{$reg_NO_1} };
				for my $reg_NO_2 (@reg_NO){
					next if($reg_NO_1 == $reg_NO_2);
					next unless( exists($Region_Href->{$ref_seg}->{$reg_NO_2}) );
					my ($st_2, $ed_2) = @{ $Region_Href->{$ref_seg}->{$reg_NO_2} };
					if( &Get_Two_Seg_Olen($st_1, $ed_1, $st_2, $ed_2) ){
						$overlap_sign = 1;
						my $new_st = min($st_1, $st_2);
						my $new_ed = max($ed_1, $ed_2);
						delete $Region_Href->{$ref_seg}->{$reg_NO_1};
						delete $Region_Href->{$ref_seg}->{$reg_NO_2};
						$Region_Href->{$ref_seg}->{$Next_RegNO++} = [$new_st, $new_ed];
						last;
					}
				}
				last if($overlap_sign);
			}
			redo MERGE if($overlap_sign);
		}
	}
}

#-------- deal gene family file from HGNC official website ---------#
sub prepare_HGNC_genefamily{
	my ($HGNC_gene_family, $aim_gfam_brief, $aim_gfam_json) = @_;

	my %GeneFam = ();

	open (HGNC, $HGNC_gene_family) || die "fail $HGNC_gene_family: $!\n";
	# theme line
	chomp(my $theme=<HGNC>);
	my @theme;
	if($theme){ # avoid blank file reading.
		@theme = split /\t/, $theme;
		s/ +/_/g for @theme;
		# filter and rename
		for (@theme){
			if(/HGNC/i && /id/i){ # HGNC ID
				$_ = 'HGNC_ID';
			}
			elsif(/Approved/i && /Symbol/i){ # Approved Symbol
				$_ = 'approved_symbol';
			}
			elsif(/Approved/i && /name/i){ # Approved Name
				$_ = 'approved_name';
			}
			elsif(/Status/i){ # Status
				$_ = 'status';
			}
			elsif(/Previous/i && /Symbol/i){ # Previous Symbol
				$_ = 'previous_symbols';
			}
			elsif(/Synonyms/i){ # Synonyms
				$_ = 'synonyms';
			}
			elsif(/Chromosome/i){ # Chromosome
				$_ = 'chromosome_band';
			}
			elsif(/Accession/i && /Numbers/i){ # Accession Numbers
				$_ = 'accession_numbers';
			}
			elsif(/RefSeq/i){ # RefSeq IDs
				$_ = 'refseq_ids';
			}
			elsif(/Family/i && /tag/i){ # Gene Family Tag
				$_ = 'gene_family_tag';
			}
			elsif(/Family/i && /description/i){ # Gene family description
				$_ = 'gene_family_description';
			}
			elsif(/Family/i && /id/i){ # Gene family ID
				$_ = 'gene_family_id';
			}
		}
	}
	while (<HGNC>){
		chomp;
		my @ele = split /\t/;
		$_ = length($_) ? $_ : 'N/A' for @ele;
		s/, /,/g for @ele;
		my %linehash = map {($theme[$_],$ele[$_])} (0 .. $#ele);

		my $gene_family_id = $linehash{gene_family_id};
		if(!exists($GeneFam{$gene_family_id})){
			$GeneFam{$gene_family_id}{gene_family_tag} = $linehash{gene_family_tag};
			$GeneFam{$gene_family_id}{gene_family_description} = $linehash{gene_family_description};
			$GeneFam{$gene_family_id}{gene_list} = {};
		}
		delete $linehash{gene_family_tag};
		delete $linehash{gene_family_id};
		delete $linehash{gene_family_description};

		my $HGNC_ID = $linehash{HGNC_ID};
		if(!exists($GeneFam{$gene_family_id}{gene_list}{$HGNC_ID})){
			$GeneFam{$gene_family_id}{gene_list}{$HGNC_ID} = {};
		}
		delete $linehash{HGNC_ID};

		my $Gene_Href = $GeneFam{$gene_family_id}{gene_list}{$HGNC_ID};
		for my $tag (keys %linehash){
			if( !exists( $Gene_Href->{$tag} ) || $linehash{$tag} ne 'N/A'){
				$Gene_Href->{$tag} = $linehash{$tag};
			}
		}
	}
	close HGNC;

	# this is what SOAPfuse needs in the pipeline.
	open (BRIEF, ">$aim_gfam_brief") || die "fail $aim_gfam_brief: $!\n";
	print BRIEF join("\t", '##Gene_family_ID', 'all_Symbols', 'Gene_Family_Tag')."\n";
	for my $gene_family_id (sort {$a<=>$b} keys %GeneFam){
		my $genefam_id_Href = $GeneFam{$gene_family_id};
		my $gene_family_tag = $genefam_id_Href->{gene_family_tag};
		for my $HGNC_ID (sort {$a<=>$b} keys %{$genefam_id_Href->{gene_list}}){
			my $Gene_Href = $genefam_id_Href->{gene_list}->{$HGNC_ID};
			my @all_Symbols;
			push @all_Symbols, $_ for split /,/,$Gene_Href->{approved_symbol};
			push @all_Symbols, $_ for split /,/,$Gene_Href->{previous_symbols};
			push @all_Symbols, $_ for split /,/,$Gene_Href->{synonyms};
			print BRIEF join("\t", $gene_family_id, $_, $gene_family_tag)."\n" for grep {$_ ne 'N/A'} @all_Symbols;
		}
	}
	close BRIEF;

	# json file, SOAPfuse doesnot need it currently, just for further use.
	my $json_text = encode_json \%GeneFam;
	open (JSON, ">$aim_gfam_json") || die "fail $aim_gfam_json: $!\n";
	print JSON "##created date: ".`date`;
	print JSON "##this json file contains only one json string.\n";
	print JSON "$json_text\n";
	close JSON;
}

#-------- Get the overlapped length of two segments -----------
# !!!!!!!!!! only works for intervals with integer boundaries
# if want to use it for demical boundaries, inter the fifth option
sub Get_Two_Seg_Olen{

	if($_[0] =~ /::$MODULE_NAME/){
		shift @_;
	}

	my ($s1,$e1,$s2,$e2,$adjust_add) = @_;
	$adjust_add = 1 unless(defined($adjust_add));
	my $large_s = ($s1<$s2)?$s2:$s1;
	my $small_e = ($e1<$e2)?$e1:$e2;
	my $overlap_len = $small_e - $large_s + $adjust_add;
	return ($overlap_len<0)?0:$overlap_len;
}

#------- get all tissue postfixes form $tissue_postfix --------#
sub get_tissue_postfix{
	my ($tissue_postfix_Href,$tissue_postfix) = @_;
	$$tissue_postfix_Href{(split /:/)[1]} = (split /:/)[0] for (split /\;/,$tissue_postfix);
	my $all_tissue = '';
	$all_tissue .= $$tissue_postfix_Href{$_} for keys %$tissue_postfix_Href;
	die "Cannot get the N and T tissue postfix from '$tissue_postfix'\n" if($all_tissue!~/N/ || $all_tissue!~/T/ || $all_tissue!~/^[NT]+$/);
}

#------- determine the tissue type of sample ---------#
sub determine_sample_tissue_type{
	my ($tissue_postfix_Href,$tissue_type_Sref,$sampleID) = @_;
	$$tissue_type_Sref = ($sampleID=~/$_$/i)?"_$$tissue_postfix_Href{$_}":$$tissue_type_Sref for keys %$tissue_postfix_Href;
	die "Cannot determine the tissue type of sample $sampleID in somatic operation mode!\n" if($$tissue_type_Sref eq '');
}

#------- determine the tissue type of sample ---------#
sub sample2patient{
	my ($tissue_postfix_Href,$sampleID) = @_;
	my ($postfix,$tissue_type) = ('','');
	($postfix,$tissue_type) = ($sampleID=~/$_$/i)?($_,$$tissue_postfix_Href{$_}):($postfix,$tissue_type) for keys %$tissue_postfix_Href;
	die "Cannot determine the tissue postfix of sample $sampleID in somatic operation mode!\n" if($postfix eq '');
	$sampleID =~ s/$postfix$//;
	return ($sampleID,$tissue_type);
}

#------- run shell command trible times -------#
sub trible_run_for_success{
	my ($command,$type,$verbose_Href) = @_;
	# cmd_Nvb, esdo_Nvb, log_vb
	
	if(!defined($verbose_Href) || !($verbose_Href->{cmd_Nvb}||0)){
		warn "$command\n";
	}

	my $dev_null = '2>/dev/null';
	if(!defined($verbose_Href) || !($verbose_Href->{esdo_Nvb}||0)){
		$dev_null = '';
	}

	my $run_time = 0;
	RUN: {
		chomp(my $run_log = `( $command $dev_null ) && ( echo $type-ok )`);
		$run_time++; # record operation time
		if($run_log !~ /$type-ok$/){
			redo RUN if ($run_time < 3); # maximum is three times
		}
		else{
			if(defined($verbose_Href) && $verbose_Href->{log_vb}){
				$run_log =~ s/$type-ok$//;
				print "$run_log\n";
			}
			return 1;
		}
	}

	# if reach here, must warn
	warn "<ERROR>: $type command fails three times.\n" .
		 "$command\n";
	exit(1);
}

#------- read config, load the hash -------
sub read_config{
	my ($config,$Config_Href,$Need_Aref) = @_;

	my %NEED = map {($_,1)} @$Need_Aref;

	open(CON,$config) || die"fail $config: $!\n";
	while(<CON>){
		next if(/^\#/ || /^\s+$/);
		my ($key,$value) = (split)[0,1];
		if(exists($NEED{$key})){
			my ($key1,$key2) = ($key =~ /^([^_]+)_(.+)$/);
			# deal based on key1
			if($key1 eq 'DB' || $key1 eq 'PG'){ # database or program
				if(!-e $value && $value !~ /\.index$/){
					die "Cannot find the $key:\n$value\n";
				}
			}
			elsif($key1 eq 'PD'){ # pipedirs
				if(!-d $value){
					`mkdir -p $value`;
				}
			}
			# load the abs_path
			$$Config_Href{$key} = $value;
		}
	}
	close CON;
}

#----------- load script -----------
sub load_script{
	my ($SourceDir,$Script_Href,$step_NO) = @_;

	# specific scripts for certain step
	if($step_NO eq 'database'){
		# NOTE: the $SourceDir is just the SOAPfuse_unPackAged_dir
		$$Script_Href{Create_PSL_FA} = File::Spec->catfile($SourceDir,'source','SOAPfuse-S00-Create-PSL-and-Fa.pl');
		$$Script_Href{bwt}           = File::Spec->catfile($SourceDir,'source','bin','aln_bin','2bwt-builder2.20');
		$$Script_Href{bwa}           = File::Spec->catfile($SourceDir,'source','bin','aln_bin','bwa');
		$$Script_Href{formatdb}      = File::Spec->catfile($SourceDir,'source','bin','aln_bin','formatdb');
		$$Script_Href{blastall}      = File::Spec->catfile($SourceDir,'source','bin','aln_bin','blastall');
	}
	elsif($step_NO == 1){
		$$Script_Href{add_prefix}    = File::Spec->catfile($SourceDir,'SOAPfuse-S01-add-prefix-to-ori-reads.pl');
		$$Script_Href{evaluate_ins}  = File::Spec->catfile($SourceDir,'SOAPfuse-S01-evaluate-ins-sd.pl');
		$$Script_Href{seek_SE_UM_PE} = File::Spec->catfile($SourceDir,'SOAPfuse-S01-seek-back-WG-SE-unmap-PE.pl');
	}
	elsif($step_NO == 2){
		$$Script_Href{amass_reads}   = File::Spec->catfile($SourceDir,'SOAPfuse-S02-Align-trans-S01-amass-reads.pl');
		$$Script_Href{pick_PE}       = File::Spec->catfile($SourceDir,'SOAPfuse-S02-Align-trans-S02-PE_filter-S_U-with-WG_SE.pl');
		$$Script_Href{addreverse}    = File::Spec->catfile($SourceDir,'SOAPfuse-S02-Deal-unmap-S01-add-reverse.pl');
		$$Script_Href{mm_filter}     = File::Spec->catfile($SourceDir,'SOAPfuse-S02-Deal-unmap-S02-split-realign-mm-filter.pl');
		$$Script_Href{bwa_indel}     = File::Spec->catfile($SourceDir,'SOAPfuse-S02-Deal-unmap-S03-bwa-realign-for-indel.pl');
	}
	elsif($step_NO == 3){
		$$Script_Href{align_trimed}  = File::Spec->catfile($SourceDir,'SOAPfuse-S03-AlignTrim-unmap.pl');
		$$Script_Href{clean_align}   = File::Spec->catfile($SourceDir,'SOAPfuse-S03-Clean-alignT-unmap.pl');
	}
	elsif($step_NO == 4){
		$$Script_Href{note_pair}     = File::Spec->catfile($SourceDir,'SOAPfuse-S04-Add-pair-sign.pl');
		$$Script_Href{save_pair}     = File::Spec->catfile($SourceDir,'SOAPfuse-S04-Save-pe-pair.pl');
	}
	elsif($step_NO == 5){
		$$Script_Href{initial_cand}  = File::Spec->catfile($SourceDir,'SOAPfuse-S05-Get-Initial-Candidate.pl');
		$$Script_Href{amass_reads_F} = File::Spec->catfile($SourceDir,'SOAPfuse-S05-Filter-Candidate-SPR-amass.pl');
		$$Script_Href{blat_dna_F}    = File::Spec->catfile($SourceDir,'SOAPfuse-S05-Filter-Candidate-Blat-homo.pl');
	}
	elsif($step_NO == 6){
		$$Script_Href{halfbackunmap} = File::Spec->catfile($SourceDir,'SOAPfuse-S06-Denovo-unmap-back-to-half.pl');
		$$Script_Href{bisectreads}   = File::Spec->catfile($SourceDir,'SOAPfuse-S06-Denovo-unmap-smart-bisect-unmap.pl');
		$$Script_Href{End_MisM_F}    = File::Spec->catfile($SourceDir,'SOAPfuse-S06-Denovo-unmap-mis-filter.pl');
		$$Script_Href{orient_homo_F} = File::Spec->catfile($SourceDir,'SOAPfuse-S06-Denovo-unmap-split-part-o-h-filter.pl');
		$$Script_Href{refineExonJR}  = File::Spec->catfile($SourceDir,'SOAPfuse-S06-Denovo-unmap-refind-candidate-exon-JR.pl');
	}
	elsif($step_NO == 7){
		$$Script_Href{Junc_reads_F}  = File::Spec->catfile($SourceDir,'SOAPfuse-S07-Junction-reads-filter.pl');
		$$Script_Href{Fusion_Junc}   = File::Spec->catfile($SourceDir,'SOAPfuse-S07-Force-S01-creat-remain-junc-fa.pl');
		$$Script_Href{GetBackJuncR}  = File::Spec->catfile($SourceDir,'SOAPfuse-S07-Force-S02-get-back-SEsoap.pl');
		$$Script_Href{feedback_D1}   = File::Spec->catfile($SourceDir,'SOAPfuse-S07-Force-S04-feedback-degree1-junc-fa.pl');
	}
	elsif($step_NO == 8){
		$$Script_Href{initial_fus}   = File::Spec->catfile($SourceDir,'SOAPfuse-S08-Final-S01-get-initial-fusion.pl');
		$$Script_Href{simplify_fus}  = File::Spec->catfile($SourceDir,'SOAPfuse-S08-Final-S02-simplify-fuse-info.pl');
		$$Script_Href{classify_F}    = File::Spec->catfile($SourceDir,'SOAPfuse-S08-Final-S03-classify-fusion.pl');
		$$Script_Href{RnaType_FS}    = File::Spec->catfile($SourceDir,'SOAPfuse-S08-Final-S04-RNA-type-FS-Fseq.pl');
		$$Script_Href{specify_gene}  = File::Spec->catfile($SourceDir,'SOAPfuse-S08-Final-S05-specific-for-genes.pl');
		$$Script_Href{blat_flankDNA} = File::Spec->catfile($SourceDir,'SOAPfuse-S08-Final-S06-blat-flank-region.pl');
		$$Script_Href{multi_trans}   = File::Spec->catfile($SourceDir,'SOAPfuse-S08-Final-S07-select-multi-trans.pl');
	}
	elsif($step_NO == 9){
		$$Script_Href{draw_exp_fus}  = File::Spec->catfile($SourceDir,'SOAPfuse-S09-Draw-fusion-expression.pl');
		$$Script_Href{draw_3D_land}  = File::Spec->catfile($SourceDir,'SOAPfuse-S09-3D-fusion-event-landscape.pl');
		$$Script_Href{TMM_DiffExp}   = File::Spec->catfile($SourceDir,'For-DE','SOAPfuse-DE-TMM-RPKM.pl');
	}

	# common scripts
	$$Script_Href{check_file}    = File::Spec->catfile($SourceDir,'SOAPfuse-S00-Check-file.pl');
	$$Script_Href{cdna_fasta}    = File::Spec->catfile($SourceDir,'SOAPfuse-S00-Creat-genes-cdna-fa.pl');
	$$Script_Href{trans2gene}    = File::Spec->catfile($SourceDir,'SOAPfuse-S00-Get-gene-from-trans.pl');
	$$Script_Href{splitSEalign}  = File::Spec->catfile($SourceDir,'SOAPfuse-S00-Split-SOAP-SE-Align.pl');
}

#----------- read ins report for insert size -----------
sub read_ins_report_for_ins{
	my ($ins_report,$max_rlen) = @_;
	my ($ins,$sd);
	open (IS,$ins_report)||die"fail $ins_report: $!\n";
	while(<IS>){
		my ($theme,$value) = (split)[0,1];
		if($theme eq 'Maximum-ins:'){
			$ins = $value;
		}
		if($theme eq 'Stat-SD-ins:'){
			$sd = $value;
		}
	}
	close IS;

	my $min_ins = int($ins - 3 * $sd);
	my $max_ins = int($ins + ((3*$sd>$ins)?((2*$sd>$ins)?1:2):3) * $sd);
	$min_ins = $max_rlen if($min_ins < $max_rlen);

	return ($min_ins,$max_ins);
}

#----------- read ins report for trimmed read length -----------
sub read_ins_report_for_trimmed_length{
	my ($ins_report) = @_;
	open (IS,$ins_report)||die"fail $ins_report: $!\n";
	while(<IS>){
		my ($theme,$value) = (split)[0,1];
		if($theme eq 'Length-cutted:'){
			close IS;
			return ($value eq 'no')?0:$value;
		}
	}
	close IS;

	return (0);
}

#----------- load codon table ---------
sub Load_Codon{
	my ($Codon_to_Amino_Href) = @_;

	%$Codon_to_Amino_Href = (
		'TTT','F',
		'TTC','F',
		'TTA','L',
		'TTG','L',
		'TCT','S',
		'TCC','S',
		'TCA','S',
		'TCG','S',
		'TAT','Y',
		'TAC','Y',
		'TAA','*',
		'TAG','*',
		'TGT','C',
		'TGC','C',
		'TGA','*',
		'TGG','W',
		'CTT','L',
		'CTC','L',
		'CTA','L',
		'CTG','L',
		'CCT','P',
		'CCC','P',
		'CCA','P',
		'CCG','P',
		'CAT','H',
		'CAC','H',
		'CAA','Q',
		'CAG','Q',
		'CGT','R',
		'CGC','R',
		'CGA','R',
		'CGG','R',
		'ATT','I',
		'ATC','I',
		'ATA','I',
		'ATG','M',
		'ACT','T',
		'ACC','T',
		'ACA','T',
		'ACG','T',
		'AAT','N',
		'AAC','N',
		'AAA','K',
		'AAG','K',
		'AGT','S',
		'AGC','S',
		'AGA','R',
		'AGG','R',
		'GTT','V',
		'GTC','V',
		'GTA','V',
		'GTG','V',
		'GCT','A',
		'GCC','A',
		'GCA','A',
		'GCG','A',
		'GAT','D',
		'GAC','D',
		'GAA','E',
		'GAG','E',
		'GGT','G',
		'GGC','G',
		'GGA','G',
		'GGG','G'
	);
	warn "Load codon ok!\n";
}

#----------- warn out the content and exit -----------
sub warn_and_exit{
	my ($warn_content, $exit_signal) = @_;
	$exit_signal = 1 unless(defined($exit_signal));
	warn "$warn_content";
	exit($exit_signal);
}

#----------- warn out the content and exit -----------
sub stout_and_sterr{
	my ($content) = @_;
	print STDOUT "$content";
	warn "$content";
}

#--- write fa file, can extend some base at the end ---
## will not change the original sequence
sub write_fasta_file{

	my $Option_Href = ($_[0]=~/::$MODULE_NAME/) ? $_[1] : $_[0];

	my $seq_Sref = $Option_Href->{SeqSref};
	my $fa_file = $Option_Href->{FaFile};
	my $segname = $Option_Href->{SegName};
	my $linebase = $Option_Href->{LineBase};
	my $CL_Extend_Len = $Option_Href->{CircleExtLen} || 0;
	my $split_N_bool = $Option_Href->{split_N} || 0;

	# how to extend, or not
	my $new_seg = '';
	if($CL_Extend_Len > 0){
		$new_seg = $$seq_Sref . substr($$seq_Sref, 0, $CL_Extend_Len);
	}
	elsif($CL_Extend_Len < 0){
		$new_seg = substr($$seq_Sref, 0, length($$seq_Sref)+$CL_Extend_Len);
	}
	else{
		$new_seg = $$seq_Sref;
	}

	# create fasta file
	open (FA,Try_GZ_Write($fa_file)) || die "fail write $fa_file: $!\n";
	if( !$split_N_bool ){
		print FA ">$segname\n";
		print FA substr($new_seg, $_ * $linebase, $linebase)."\n" for ( 0 .. int( (length($new_seg)-1) / $linebase ) );
	}
	else{ # split N
		my @N_split_seg = split /N+/i, $new_seg;
		for (my $i = 0; $i <= $#N_split_seg; $i++){
			print FA ">$segname-part$i\n";
			print FA substr($N_split_seg[$i], $_ * $linebase, $linebase)."\n" for ( 0 .. int( (length($N_split_seg[$i])-1) / $linebase ) );
		}
	}
	close FA;
}

1; ## tell the perl script the successful access of this module.
