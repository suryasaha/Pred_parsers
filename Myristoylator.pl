#!/usr/bin/perl -w
# PPath
# Surya Saha    04/26/2010 03:46:29 PM   
# reading in LAS proteins and sends them to Myristolator website  
# and writing a Excel file for predicted Lipoprotein signal peptides
# write a gff file for Artemis 
# Myristoylator can be run on CDS features (where there was no signal peptide) or mat_peptides 
# (where there was a predicted signal peptide) and where the first or second residue is a  Glycine (G)
# http://ca.expasy.org/tools/myristoylator/ 