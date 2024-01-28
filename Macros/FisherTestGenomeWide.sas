%macro FisherTestGenomeWide(
/*Note: this macro will use unique sampleID and pheno_var to make all to all combinations, 
please make sure the input table contain all target sampleID and pheno_var;
If not, please supply a sas dataset containing all target samples and its 
corresponding grp4fisher variable, and the macro will add these missing samples
into the input dsdin and make all other variables as missing!*/
dsdin=_last_,
vars4assoc=%str(chrom, Pos, ref), /*These vars will be concatenate into a single var, and the data of each will be 
                                  subjected to fisher test by grp4fisher and phenotype var*/
grp4fisher=subtype, /*This var will be used to perform 2x2 fisher test, which will be 
                     included in the column names in the output table*/
SampleID=SampleID,  /*Patient ID*/
pheno_var= ,    /*phenotype for fisher test with grp4fisher; in the output the pheno and grp4fisher will be put on row- and column-wide, respectively
                  the default is to use &grp4fisher, and the macro will use &grp4fisher to make pheno, i.e., 
                  samples with records of the var vars4assoc in the long format data will be assigned as pheno=1,
                  and samples without records for the vars4assoc will be defined as pheno=0*/
pheno_case_rgx=,/*A perl regular expression to match with target phenotype and treat all matched elements as 
                   Case, and all other phenotype names will be treated as Other*/
Name4Case=Case,/*A name used to label these cases when the phenotype matching with the pheno_case_rgx*/                                   
all_sample_grp_info=,/*Default is empty; When the input dsdin only contains partial samples that
                       have mutations or rare variants, which usually is the case,
                       then user can supply a sas dataset containing two columns, 
                       including sampleID and grp4fisher for enabling
                       the input dsdin has all target samples and its grp4fisher*/
grp4infodsd=,/*The corresponding variable in the all_sample_grp_info as the var grp4fisher from the input dsdin*/
SampleID4infodsd=,  /*Patient ID variable in the all_sample_grp_info dataset*/                    
fisher_dsdout=fisherout, /*All fisher test results for vars4assoc; only when the pheno*grp is 
                          a 2x2 table, the OR table RelativeRisks will be generated!*/
value4misspheno=0, /*assign a specific value to samples without records of the vars4assoc*/
grp_condition4pheno_var= %str(subtype^=""), /*use the value of &grp4fisher as group here!
                                          use the condition to separate pheno_var into two groups for fisher test
                                          The default condition is set when the pheno_var is empty*/
new_pheno=pheno,   /*new pheno variable name for the fisher test, which will be used to label the fisher table*/
/*The following are optional parameters for the output of csv files for summary statistics; 
no appendix of .csv is required to added; Default output dir will be in current dir!*/
outcsvname4measures=Measures,
outcsvname4OR=fisherout.OR,
outcsvname4fisher=fisherout,
outcsvname4crossfrqtb=CrossTabFreqs
);

data _x_;
length vars $150;
set &dsdin;
vars=catx(':',&vars4assoc);
*Keep these empty vars as their sample ids and subtypes info are needed to get all the combination of sample ids and subtypes;
/* if vars^=""; */
run;

%if %length(&all_sample_grp_info)>0 and %sysfunc(exist(&all_sample_grp_info)) %then %do;
%put The all sample information from the dataset &all_sample_grp_info will be used to fill these missing samples into the input dataset &dsdin;
*Add missing data for these samples that are not included in the input dataset;
data allsampleinfo;
set &all_sample_grp_info;
%if "&grp4infodsd"^="&grp4fisher" %then %do;
   &grp4fisher=&grp4infodsd;
%end;
%if "&SampleID4infodsd"^="&SampleID" %then %do;
   &SampleID=&SampleID4infodsd;
%end;
run;
*Use full outer join to keep all records from two tables;
*https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.4/casfedsql/n1jstfybqg5boxn1odnb9gfacszq.htm;
proc sql;
create table _x_ as 
select a1.*,a2.vars 
from allsampleinfo as a1
full outer join 
_x_ as a2
on a1.&grp4fisher=a2.&grp4fisher and a1.&SampleID=a2.&SampleID;
/* %abort 255; */
%end;


*When pheno_var is empty, use &grp4fisher to define pheno as 0 or 1;
%if %length(&pheno_var)=0 %then %let pheno_var=&grp4fisher;

data _x_;
set _x_;
if prxmatch("/&pheno_case_rgx/i",&pheno_var) then &pheno_var="&Name4Case";
else &pheno_var="Other";
run;

*remove duplicates;
proc sort data=_x_ nodupkeys;by vars &SampleID &pheno_var;
run;

proc sql;
create table final as
select t.*,bb.&grp4fisher as subtype
%if %eval(&pheno_var^=subtype) %then %do;
       ,bb.&pheno_var
%end;
from (
select distinct a.vars,b.&SampleID
from _x_ as a,
     _x_ as b
) as t
left join
_x_ as bb
on t.vars=bb.vars and t.&SampleID=bb.&sampleID;

/*
proc print data=final(obs=10);
where subtype^="";run;
*/

data final;
set final;
if ( length(&pheno_var)=0 or prxmatch('/^\.$/',&pheno_var) ) then &new_pheno=&value4misspheno;
run;


*add subtype information into the table;
proc sql;
create table final as
select a.*,b.subtype as grp
from final as a
left join
(select distinct &SampleID,
                 &grp4fisher as subtype
        from _x_
        ) as b
on a.&SampleID=b.&SampleID;

/*        
proc print data=final(obs=10);
where grp^="";run;
%abort 255;
*/

*perform fisher test;
data final;
set final;
*Note: the condition will separate &pheno_var into two groups;
&new_pheno=(&grp_condition4pheno_var);
if &new_pheno=. then &new_pheno=0;
run;


proc sql noprint;select count(unique(&new_pheno)) into: tot_pheno from final;

%if &tot_pheno<2 %then %do;

 %put your group condition is:;
 %put &new_pheno=(&grp_condition4pheno_var);
 %put Please ensure to use the fixed var grp to generate new groups;
 %abort 255;

%end;

/*
proc print data=_last_(obs=10);run;
where &new_pheno^=.;
run;
%abort 255;
*/

proc sort data=final;by vars grp &new_pheno;run;
*ods trace on;
ods select none;
ods output FishersExact=FishersExact
           CrossTabFreqs=CrossTabFreqs
           Measures=Measures
           RelativeRisks=RelativeRisks;
proc freq data=final;
by vars;
*Note: only 2x2 table will generate OR output;
table grp*&new_pheno/measures relrisk OR fisher exact;
run;
ods select all;
*ods trace off;

data &fisher_dsdout;
set fishersexact;
where Name1="XP2_FISH";
run;

proc print data=&fisher_dsdout;
where nValue1<1e-3;
run;

/*
%ds2csv(data=CrossTabFreqs,csvfile="CrossTabFreqs.csv",runmode=b);
%ds2csv(data=Measures,csvfile="Measures.csv",runmode=b);
%ds2csv(data=&fisher_dsdout,csvfile="&fisher_dsdout..csv",runmode=b);
%ds2csv(data=RelativeRisks,csvfile="&fisher_dsdout..OR.csv",runmode=b);
*/
%ds2csv(data=CrossTabFreqs,csvfile="&outcsvname4crossfrqtb..csv",runmode=b);
%ds2csv(data=Measures,csvfile="&outcsvname4measures..csv",runmode=b);
%ds2csv(data=&fisher_dsdout,csvfile="&outcsvname4fisher..csv",runmode=b);
%ds2csv(data=RelativeRisks,csvfile="&outcsvname4OR..csv",runmode=b);

%mend;
/*
Demo 1:;

proc import datafile="NTU_germline_vars_on_candidate_genes4assoc.txt" dbms=tab replace out=x;
getnames=yes;guessingrows=max;
run;
%importallmacros;
%FisherTestGenomeWide(
dsdin=x,
vars4assoc=%str(chrom, Pos, ref), 
grp4fisher=subtype, 
SampleID=SampleID,  
pheno_var=&grp4fisher,    
fisher_dsdout=fisherout,
grp_condition4pheno_var= %str( subtype^=""),
new_pheno=pheno,
outcsvname4measures=Measures,
outcsvname4OR=fisherout.OR,
outcsvname4fisher=fisherout,
outcsvname4crossfrqtb=CrossTabFreqs
);

*Demo 2:;
proc import datafile="NTU_germline_vars_on_candidate_genes4assoc.txt" dbms=tab replace out=x;
getnames=yes;guessingrows=max;
run;

%importallmacros;
*options mprint mlogic symbolgen;

*generate 2x2 table for ALL vs others;
data x;
set x;
*if not prxmatch("/ALL/",subtype) then subtype="Other";
*Only focus on B-ALL, T-ALL, and AML;
*if prxmatch("/(ALL|AML)/",subtype) and Triage^="NonRare";
*Keep these NonRare ones, as some variants labeled as different tags although there are the same variants;
if prxmatch("/(ALL|AML)/",subtype);
run;

%let TGT=%str(AML);
%let TAG=&TGT._vs_Others;
*%let TAG=AML_vs_BALL_TALL;

*Further make case-control design;
data x;
set x;
if subtype^="&TGT" then subtype="Other";
run; 


*Mut-level fisher test;
%FisherTestGenomeWide(
dsdin=x,
vars4assoc=%str(chrom, Pos, ref), 
grp4fisher=subtype, 
SampleID=SampleID,  
pheno_var=,    
fisher_dsdout=fisherout4mut,
grp_condition4pheno_var= %str(subtype^=""),
outcsvname4measures=Measures_VarLevel4&TAG,
outcsvname4OR=fisherout_VarLevel.OR4&TAG,
outcsvname4fisher=fisherout_VarLevel4&TAG,
outcsvname4crossfrqtb=CrossTabFreqs_VarLevel4&TAG
);


*gene-level fisher test;
%FisherTestGenomeWide(
dsdin=x,
vars4assoc=Gene, 
grp4fisher=subtype, 
SampleID=SampleID,  
pheno_var=,    
fisher_dsdout=fisherout,
grp_condition4pheno_var= %str(subtype^=""),
outcsvname4measures=Measures_GeneLevel4&TAG,
outcsvname4OR=fisherout_GeneLevel.OR4&TAG,
outcsvname4fisher=fisherout_GeneLevel4&TAG,
outcsvname4crossfrqtb=CrossTabFreqs_GeneLevel4&TAG
);

*/
