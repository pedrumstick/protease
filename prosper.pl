#!/usr/bin/perl -w
##
## ******************************************************************
## *   PROSPER - An intergrated feature-based tool for predicting   *
## *             protease substrate cleavage sites from amino acid  *
## *             sequences.                                         *
## *   Copyright (C) 2011 Jiangning Song and Hao Tan at Monash      *
##             University, Clayton, Melbourne, VIC 3800, Australia  *
## ******************************************************************
## 
## This program is copyright and may not be distributed without
## permission of the author unless specifically permitted under
## the terms of the license agreement.
## 
## This program may only be used for non-commerical purposes. Please 
## contact the author if you require a license for commerical use.




$f=shift||die("Cannot find the input file\n");
$ss=shift||die;
$sc=shift||die;
$diso=shift||die;
$th=shift||0.05;   ## this is the threshold value that controls the trade-off between the Sensitivity and Specificity.
                   ## We set the default threshld value as 0.85 in PROSPER. However, users may adjust its value to meet different stringency requirements.


system "perl gen_svm_bitb.pl $f $ss $sc $diso";
system "perl svm_predict.pl $f";


system "./result.pl $f $th";


`rm $f\_res*`;
`rm $f\_input*`;
`rm bitb_*`;
`rm $f.seq`;
