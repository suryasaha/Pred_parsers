#!/usr/bin/perl -w
# PPath@Cornell
# Surya Saha Dec 8, 2010
# To combine the novel predictions from Wolbachia and Smel models  

use strict;
use warnings;

unless (@ARGV == 3){
	print "USAGE: $0 <Smel preds csv> <Wol preds csv> <output GFF>\n";
	print "Using NC_012985.2 as seq and EasyGene as source\n";
	exit;
}

unless(open(INSmel,"<$ARGV[0]")){print "not able to open $ARGV[0]\n";exit 1;}
unless(open(INWol,"<$ARGV[1]")){print "not able to open $ARGV[1]\n";exit 1;}
unless(open(OUT,">$ARGV[2]")){print "not able to open $ARGV[2]\n";exit 1;}

my($rec,$i,@Preds,@WolPreds,@temp,$j,$lengths);

$rec=<INSmel>;
while($rec=<INSmel>){
	@temp=split(',',$rec);	
	$temp[3]=~ s/\"//g; $temp[4]=~ s/\"//g;	chomp $temp[4];
	$temp[5]='Smel';	push @Preds,[@temp];
}
close(INSmel);
$rec=<INWol>;
while($rec=<INWol>){
	@temp=split(',',$rec);	
	$temp[3]=~ s/\"//g; $temp[4]=~ s/\"//g;	chomp $temp[4];
	$temp[5]='Wol';	push @Preds,[@temp];
}
close(INWol);

# sorting the records
@temp = sort {$a->[0] <=> $b->[0]} @Preds; @Preds=@temp;

print OUT "##gff-version 3\n";
print OUT "#EasyGene predictions from $ARGV[0] and $ARGV[1]\n";
$lengths=0;
foreach $i (@Preds){
	print OUT "NC_012985.2\tEasyGene\tgene\t",$i->[0],"\t",$i->[1],"\t",$i->[2],"\t",$i->[3],"\t",$i->[4],"\tModel=",$i->[5],"\;\n";
	$lengths+=$i->[1]-$i->[0];
}
close(OUT);
print STDERR "Number of predictions : ",scalar @Preds,"\n";
printf STDERR "Avg length of predictions : %.2f\n",$lengths/@Preds;

exit;