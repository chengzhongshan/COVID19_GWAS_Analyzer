%macro get_sc_read_geomean_and_readsum(
filename_ref_handle, /*filename handle, and all character columns 
should be put at the beginning of the table!*/
total_num_vars,  /*total number of numeric vars in the opened file handle*/
macro_prefix4NumVarSum, /*macro prefix used to generate macro vars for var sums*/
firstobs=2, /*escape header or not*/
first_input4charvars=rownames tissue, /*provide all character vars located at the beginning of the table*/
macro_prefix4CharVarLen=CharVarLen,
dlm='09'x  /*if providing other non-SAS dlm, quote it*/
);

*Create global macro vars;
%do mi=1 %to &total_num_vars;
  %global &macro_prefix4NumVarSum.&mi;
%end;

*creat global macro char vars;
%let ncharvars=%ntokens(&first_input4charvars);
%do ci=1 %to &ncharvars;
  %global &macro_prefix4CharVarLen.&ci;
%end;

*Guessing char var length;
data _x_;
%do ci=1 %to &ncharvars;
         length  CharV&ci $200.;
%end;
%do ci=1 %to &ncharvars;
          retain CharVarLen&ci 1;
%end;

/*
infile &filename_ref_handle dsd truncover dlm=&dlm firstobs=&firstobs
obs=max end=eof lrecl=32767;
*Note: the longest length for the _infile_ is 32767;
*Thus the line would be truncted when there are more then 32767 chars;
*However, this would be fine if just trying to guess the max length across all numeric vars;

input @;

%do ci=1 %to &ncharvars;
    CharV&ci=scan(_infile_,&ci,&dlm);
    if NOT prxmatch('/^\W+$/',CharV&ci) then do;
     CharVarLen&ci=max(length(trim(CharV&ci))+0,CharVarLen&ci); 
    end;
    if eof then do;
      call symputx("&macro_prefix4CharVarLen"||left(trim(put(&ci,12.))),
                left(trim(put(CharVarLen&ci,12.)))
                );
    end;            
%end;
*/

*No need to have this;
*If trying to create macro var at the end of the dataset;
*it may fail when there are failures in reading data;
/* if eof then do; */
/*  %do ci=1 %to &ncharvars; */
/*    call symputx("&macro_prefix4CharVarLen"||left(trim(put(ci,12.))), */
/*                 left(trim(put(CharVarLen&ci,12.))) */
/*                 ); */
/*  %end;   */
/* end; */

********************************************************************;

*Guessing numeric variable length;
/*For debugging, output records into L*/
/* data L; */
/* data _null_; */
/* infile &filename_ref_handle dsd truncover dlm=&dlm firstobs=&firstobs  */
/* obs=max end=eof lrecl=10000000; */

infile &filename_ref_handle dsd truncover dlm=&dlm firstobs=&firstobs
obs=max end=eof lrecl=1000000000;

*retain these var recording the lengths;
*set the initial length for them as 3;
*make sure retain each var separately;
*in case of truncation of long line by SAS; 

%do ri=1 %to &total_num_vars;
 retain Sum4Var&ri 3;
%end;
;

array Ln{&total_num_vars} Sum4Var1 - Sum4Var&total_num_vars;

*The following will be truncated if the line is too long;
/* %do ri=1 %to &total_num_vars; */
/*                            %str(Sum4Var&ri) */
/*                            %end; */
/* ; */

length Val 8.;
/* input &first_input4charvars @@; */
*Make dummy charvar;
input (&ncharvars * dummy) (: $1) @@;       

*Get numeric var length line by line;
*Old var sums will be updated line by line;
col_read_pass_qc=0;
do li=1 to &total_num_vars;
 input Val @;
 Ln{li}=Ln{li}+Val;
 if Val>0 then col_read_pass_qc=col_read_pass_qc+1;
end;

do li=1 to &total_num_vars;
if eof then do;
  call 
  symputx(
  "&macro_prefix4NumVarSum"||left(trim(put(li,12.))),
  left(trim(put(Ln{li},12.)))
  );
 end;
end;

run;

/*
%put There are &ncharvars global macro char vars created for var length.;
%put Here are some examples for your global macro char vars:;
%do ci=1 %to &ncharvars;
 %if %eval(&ci<10) %then %do;
   %put ;
   %put The global macro char var &macro_prefix4CharVarLen.&ci records the length for the char var CharV&ci; 
   %put and the value for the length is &&&macro_prefix4CharVarLen&ci!;
   %put ;
 %end; 
%end;

%put ;
%put ;
*/

%put There are &total_num_vars global macro numeric vars created for var length.;
%put Here are some examples for your global macro numeric vars:;
%do mi=1 %to &total_num_vars;
 %if %eval(&mi<10) %then %do;
   %put ;
   %put The global macro numeric var &macro_prefix4NumVarSum.&mi records the length for the numberic var V&mi; 
   %put and the value for the length is &&&macro_prefix4NumVarSum&mi!;
   %put ;
 %end; 
%end;

%mend;

/*Demo:

*Demo 1;

%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

%let zipfile=/home/cheng.zhong.shan/data/GTEx_Analysis_v8_sbgenes.tar.gz;
filename inzip zip "&zipfile" gzip;

%get_sc_read_geomean_and_readsum(
filename_ref_handle=inzip,
total_num_vars=5,
macro_prefix4NumVarSum=NumVarLen,
firstobs=2,
first_input4charvars=grp tissue,
macro_prefix4CharVarLen=CharVarLen,
dlm='09'x ,
getmaxlen4allvars=1
);

*Demo 2:;
data a;
infile cards delimiter='09'x truncover;
input g $ x1-x3;
cards;
g1	1	3	300
g2	2	90000	1000000000
;
*data a;
*set a;
*For testing purpose;
*if trunc(x3,3)=x3;
run;
%let cwd=%sysfunc(getoption(work));
proc export data=a outfile="&cwd/test.txt" dbms=tab replace;
run;
filename T "&cwd/test.txt";

*option mprint mlogic symbolgen;

%get_sc_read_geomean_and_readsum(
filename_ref_handle=T,
total_num_vars=3,
macro_prefix4NumVarSum=NumVarLen,
firstobs=2,
first_input4charvars=grp,
macro_prefix4CharVarLen=CharVarLen,
dlm='09'x ,
getmaxlen4allvars=1
);

*/

