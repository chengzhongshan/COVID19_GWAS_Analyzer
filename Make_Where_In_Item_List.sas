%macro Make_Where_In_Item_List(
query_name, /*query variable name that will be put before the "in" command in the final codes of where condition;
Note: this variable name should be contained in the data set that will be applied for where condition!
It does not require to be included in the input data set indsd that is used to construct where condition*/
indsd,/*Input data set containing dsd_variable that is used to generate a quoted list for where condition*/
dsd_variable,/*variable included in the input dsd to be used to get all target elements for the where condition;
Note: this variable does not require to be included in the data set that will be applied with the where condition*/
out_item_list=out_item_list	/*A prefix used to name the sas script that contains the final where condition, which can be 
used by running %include &out_item_list.sas in data step*/
);
data _NULL_;
length item_list $5000.;*Be caution about the length;
set &indsd end=eof;
retain ct 0;
file "&out_item_list..sas" noprint;
if _n_ eq 1 then
   put "where &query_name in (" @;
item_list=quote(trim(&dsd_variable));
put item_list @;
if eof then 
   put ");";
else
   put "," @;
run;
%mend;
/*Demo codes:
x cd "E:\LongCOVID_HGI_GWAS\Multi_Long_GWAS_Integration\GSDMA_B_and_others_vis_long_COVID\RNAseq_GSDMB_KO";
proc import datafile='GSE191015_genematrix.tsv' 
dbms=tab out=x replace;
run;

data tgts;
input gene :$20.;
cards;
BIRC3
ITGB8
COL4A2
MYLK
RAC1
FN1
FYN
PDGFA
THBS1
EGFR
ITGB6
LAMC2
CAV1
ACTG1
FLNA
PRKCG
;
run;

%Make_Where_In_Item_List(
query_name=gene,
indsd=tgts,
dsd_variable=gene,
out_item_list=out_item_list);

data x1;
set x;
%include "out_item_list.sas";
run;

*/
