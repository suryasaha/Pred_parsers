#!/usr/bin/perl -w
# PPath
# Surya Saha    04/19/2010 02:24:30 PM / 07/15/2013 04:48:02 PM 
# See BELOW
# reading reports generated by SignalP (http://www.cbs.dtu.dk/services/SignalP-3.0/) for LAS proteins  
# and writing a Excel file for predicted signal peptides
# write a gff file for Artemis/GBrowse

#v1	For LAS psy62 only, SignalP v 3.0
#v2	For any genome from RefSeq, Compatible with SignalP v4.1 preds (Complete rewrite)
#	Producing only GBrowse compatible GFF file and complete FAA for now, No report 


unless (@ARGV == 4){
	print "USAGE: $0 <SignalP 4.1 short report> <protein faa> <Genome RefSeq GFF> <Index GFF on GI or Name>\n";
	print "Compatible with SignalP v4.1 short report ONLY\n";
	print "GI should be used for original RefSeq GFF files\n";
	print "Name should be used for RefSeq-like GFF and Fasta files created manually from Artemis and fastaArtemis2RefSeq.pl\n";
	exit;
}

use strict;
use warnings;

## Chk is glycine in 1 or 2 position
## params: seq, pos
#sub mys_cand{
#	if ((substr($_[0],$_[1]-1,1) eq 'G') || ((substr($_[0],$_[1],1) eq 'G'))){
#		return 1;
#	}
#	else{
#		return 0;
#	}
#}

my ($rec,$i,$j,@temp,@temp1);
my ($genome,%protSeq,%protSeqHeader,%protGFF,$acc,$site,$start);

#unless(open(OUTXLS,">$ARGV[0].xls")){print "not able to open $ARGV[0].xls\n\n";exit;}
unless(open(OUTGFF,">$ARGV[0].gff")){print "not able to open $ARGV[0].gff\n\n";exit;}
unless(open(OUTFAA,">$ARGV[0].complete.faa")){print "not able to open $ARGV[0].faa\n\n";exit;}
#unless(open(OUTCANDS,">$ARGV[0].myristolation.candidates.faa")){print "not able to open $ARGV[0].myristolation.candidates.faa\n\n";exit;}
unless(open(SPREP,$ARGV[0])){print "not able to open $ARGV[0]\n\n";exit;}
unless(open(INFAA,$ARGV[1])){print "not able to open $ARGV[1]\n\n";exit;}
chomp $ARGV[2];
unless(open(INGFF,$ARGV[2])){print "not able to open $ARGV[2]\n\n";exit;}

#reading in the fasta into %prots 
#>gi|254780122|ref|YP_003064535.1| hypothetical protein CLIBASIA_00005 [Candidatus Liberibacter asiaticus str. psy62]
#MGALKNHFHDEINENFYFHSHPNADPDISIEMQISENQRYLDEEISQCNAVVDVFKRSDSTILDKLDAMD
while ($rec=<INFAA>){
	if ($rec=~ /^>/){# get name
		@temp = split(/\|/,$rec);
		if ($ARGV[3] eq 'GI'){
			$acc=$temp[1];#GI number GOD DAMN LAS GFF DOES NOT HAVE DB_XREF GI'S 
			$protSeqHeader{$acc}=$rec;
		}
		elsif ($ARGV[3] eq 'Name'){
			$acc=$temp[3];#Acc number
			$protSeqHeader{$acc}=$rec;
		}
		@temp=();
	}
	else{# get seq
		chomp $rec;
		if (exists $protSeq{$acc}){$protSeq{$acc}=$protSeq{$acc}.$rec;}
		else {$protSeq{$acc}=$rec;}
	}
}
close(INFAA);

#reading the genome Refseq GFF
#NC_019907.1	RefSeq	region	1	1504659	.	+	.	ID=id0;Dbxref=taxon:1215343;Is_circular=true;gbkey=Src;genome=chromosome;mol_type=genomic DNA;strain=BT-1
#NC_019907.1	RefSeq	gene	27	1349	.	+	.	ID=gene0;Name=B488_00000;Dbxref=GeneID:14293230;gbkey=Gene;locus_tag=B488_00000
#NC_019907.1	RefSeq	CDS	27	1349	.	+	0	ID=cds0;Name=YP_007232248.1;Parent=gene0;Dbxref=Genbank:YP_007232248.1,GeneID:14293230;gbkey=CDS;product=GTPase and tRNA-U34 5-formylation enzyme TrmE;protein_id=YP_007232248.1;transl_table=11
while ($rec=<INGFF>){
	if ($rec=~ /^\#/){next;}
	@temp = split("\t",$rec);
	
	if ($temp[2] eq 'CDS'){ 
		@temp1 = split(';',$temp[8]);
		if ($ARGV[3] eq 'GI'){
			foreach $i (@temp1){#GOD DAMN LAS GFF DOES NOT HAVE DB_XREF GI'S 
				if ($i =~ /^db_xref\=GI\:/){
					$i =~ s/^db_xref\=GI\://; $acc = $i;
				}
			}
		}
		elsif ($ARGV[3] eq 'Name'){
			foreach $i (@temp1){
				if ($i =~ /^Name/){
					$i =~ s/^Name\=//; $acc = $i;
				}
			}
		}
		$protGFF{$acc}=$rec;
	}
	@temp=(); @temp1=(); undef $acc;
}
close(INGFF);

#reading signalp short and writing out mature peptide records to GBrowse compatible GFF3 
# SignalP-4.1 gram- predictions
# name                            Cmax  pos  Ymax  pos  Smax  pos  Smean   D     ?  Dmaxcut    Networks-used
#gi_431805362_ref_YP_007232263.1_  0.125  17  0.148  17  0.303  12  0.181   0.163 N  0.570      SignalP-noTM
#gi_431805363_ref_YP_007232264.1_  0.890  23  0.859  23  0.941  19  0.827   0.844 Y  0.570      SignalP-noTM
#gi_431805364_ref_YP_007232265.1_  0.107  23  0.117  44  0.154  36  0.105   0.111 N  0.570      SignalP-noTM
while ($rec=<SPREP>){
	if ($rec=~ /^\#/){next;}
	
	if ($rec=~ /^gi_/){# if real record
		@temp = split(' ',$rec);
		
		if ($temp[9] eq 'Y'){
			# using the D score for classification
			# The D-score is introduced in SignalP version 3.0. In version 4.0 this score is 
			# implemented as a weighted average of the S-mean and the Y-max scores. The score 
			# shows superior discrimination performance of secretory and non-secretory proteins 
			# to that of the S-mean score which was used in SignalP version 1 and 2.
			
			if ($ARGV[3] eq 'GI'){
				#GI number
				@temp1 = split('ref',$temp[0]); $temp1[0] =~ s/^gi_//; $temp1[0] =~ s/_$//;
				$acc = $temp1[0];
				#GOD DAMN LAS GFF DOES NOT HAVE DB_XREF GI'S
			}
			elsif ($ARGV[3] eq 'Name'){
				#Acc no
				@temp1 = split('ref',$temp[0]); $temp1[1] =~ s/^_//; $temp1[1] =~ s/_$//;
				$acc = $temp1[1];
			}
			
			#Since Cmax and Ymax pos are same for positive, taking Cmax for coordinate calculation
			$site = $temp[2];
			
			#revising start site
			@temp1 = split("\t", $protGFF{$acc});
			$start = $temp1[3]+$site;
			
			print OUTGFF "$temp1[0]\tSignalP_4.1\tmat_peptide\t$start\t$temp1[4]\t$temp1[5]\t$temp1[6]\t";
			print OUTGFF "$temp1[7]\tName\=${acc}\;Note\=D-score $temp[8] \($temp[11]\)\;\n";
			
			print OUTFAA $protSeqHeader{$acc},$protSeq{$acc},"\n";
		}
	}
}
close(SPREP);
close(OUTGFF);
close (OUTFAA);


exit;