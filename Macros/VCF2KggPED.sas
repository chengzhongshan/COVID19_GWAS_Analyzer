%macro VCF2KggPED( dir=       /* Windows path of directory to vcf files                               */
                 , filename=  /* Single VCF file name                                                 */
                 , dsdout=    /* file name used for sas dataset and Kggseq PED file name (under &dir)*/
                              /*file will be in directory &dir and non-word will be changed into '_' */
                 , unaff=     /*perl rgex: specific characters or words contained by unaffacted samples         */
                 , aff=       /*perl regex: specfic characters or words contained by affected samples           */ 
                 ) ;

*dsdout can not contain more than 32 chracters;
*Revised it accordingly;
%local start_substr;
%let dsdout=%sysfunc(prxchange(s/\W+/_/,-1,&dsdout));
%if %length(&dsdout)>32 %then %do;
%let start_substr=%eval(%length(&dsdout)-32+1);
%let dsdout=%substr(&dsdout,&start_substr);
%put "Your output dsdout was changed into sas workable name as: " &dsdout;
%end;
options compress=yes;
filename vcf "&dir/&filename";

*Get the total number of header lines;
*The last header line is used as header in proc import;
data _null_;
infile vcf lrecl=32767 length=linelen;
input header $varying32767.linelen;
n=_n_;
if substr(header,1,1)="#" then do;
   call symput('colnames',strip(substr(header,2)));
end;
if substr(header,1,1)^="#" then do;
   call symput('header_num',n);
   stop;
end;
run;
%put &header_num;
%put &colnames;

*Make sas to import partial data;
options obs=%eval(&header_num-1);

proc import datafile="&dir/&filename"
dbms=tab out=&dsdout replace;
getnames=no;
datarow=%eval(&header_num-1);
guessingrows=100;
run;

data &dsdout;
set &dsdout;
drop var1-var9;
run;

data &dsdout;
set &dsdout;
array PED{*} _all_;
do i=1 to dim(PED);
 Indv=PED{i};output;
end;
keep Indv;
run;

/*
proc sql;
create table &dsdout as
select Indv,
       case
       when (upper(indv) like "%upcase(&unaff)") then '1'
       when (upper(indv) like "%upcase(&aff)") then '2'
       else 'NA'
       end as Pheno
from &dsdout;
*/

proc sql;
create table &dsdout as
select Indv,
       case
       when ( prxmatch("/&unaff/i",indv) ) then '1'
       when ( prxmatch("/&aff/i",indv) ) then '2'
       else 'NA'
       end as Pheno
from &dsdout;

data _null_;
set &dsdout;
n=_n_;
file "&dir/&dsdout";
put n Indv "0 0 0 " Pheno;
run;

options obs=max;

*The following codes were going to rename variables with VCF headers!;
*For temporary backup and later copy and past!;

/*%local nvars;                                           */
/*%let nvars=%eval( %sysfunc(count(&colnames,%str( )))+1);*/
/*data &dsdout;                                           */
/*set &dsdout(rename=(                                    */
/*   rename all the variables Var1-Varn                   */                                                                                                                 
/*	%do i = 1 %to &nvars;                                 */
/*      var&i=%scan(&colnames,&i)                         */
/*	%end;                                                 */
/*  )                                                     */
/*);                                                      */
/*run;                                                    */

options compress=no;
%mend;

/*
options mprint mlogic symbolgen;
%VCF2KggPED(dir=I:\SKCM\TCGA\Protected_Mutations\BCM__IlluminaGA_DNASeq_Cont_automated\Level_2
            ,filename=TCGA-BF-A1PU-01A-11D-A19A-08.01-vs-10.vcf
            ,dsdout=TCGA-BF-A1PU-01A-11D-A19A-08.01-vs-10
            ,unaff=normal
            ,aff=primary);
*/
