 ***********************************************************************************************************************
 ***********A macro that execute R scipt in base SAS********************************************************************                     
 ** MACRO Version:  1.0                                                                                               **
 ** SAS Version:    9.1.3/9.2                                                                                         **
 ** R Version:      2.14.0                                                                                            **
 ** Date:           Nov 24, 2011                                                                                      **
 ** Author:         Xin Wei, Ph.D., revised by Zhongshan Cheng on Aug-27-2019                                         **
 ** Affiliation:    Roche Pharmaceuticals, INC                                                                        **
 ** Instruction:    This SAS macro enables native R language to be embedded in and executed along with a SAS program  **
 **                 in the Base SAS environment under Windows OS. This macro executes a user-defined R code in batch  **
 **                 mode by calling the unnamed pipe method within base SAS. The R textual and graphical output can be**
 **                 routed to the SAS output window and result viewer, respectively. Also, this macro automatically   **
 **                 converts data between SAS datasets and R data frames such that the data and results from each     **
 **                 statistical environment can be utilized by the other environment. The objective of this macro is  **
 **                 to leverage the strength of the R programming language within the SAS environment in a systematic **
 **                 manner. Moreover, this macro helps statistical programmers to learn a new statistical language    **
 **                 while staying in a familiar environment. The macro variables are described as follows:            **
 **      SAS2R      specifies the names of SAS datasets to be converted to R dataframe. Can be single file name or    **
 **                 multiple files whose names are separated by space.                                                **
 **      R2SAS      specifies the names of R dataframes to be converted to SAS datasets. Can be single file name or   **
 **                 multiple files whose names are separated by space.                                                **
 **      rpath      The full path and file names of R executable file for various R version from 2.11 to 2.14         **
 
 ***********************************************************************************************************************;
%macro proc_r_codes4sas(rcodes_dsd4sas=, rcode_var=, SAS2R=, R2SAS=, rpath=);
options notes;
%GLOBAL _SAS2R _R2SAS saswork r_code;
%let _SAS2R=&SAS2R;
%let _R2SAS=&R2SAS;
%let saswork=%sysfunc(pathname(work));
data _null_;
    call symput('r_code','r_code'||trim(left(scan(put(datetime(),best.),1,'.'))));
run;
%put &r_code;
data tmp;
     file "&saswork/&r_code..r";
     set &rcodes_dsd4sas;
     put &rcode_var;
	 ;
run;

%let rpath=%str(&rpath);
%put Your provided rpath for the sas macro proc_r is &rpath;
%abort_when_file_not_exit(&rpath);

*********For R.exe in windows**********************;
****for portable R, use: C:\Bioinformatics\R-Portable\App\R-2.11.0\bin\R.exe****;
****for R-2.11.0, use: C:\Progra~1\R\R-2.11.0\bin\R.exe*****;
****for R-2.12.0, use: C:\Progra~1\R\R-2.12.0\bin\R.exe*****;
****for R-2.13.0, use: C:\Progra~1\R\R-2.13.0\bin\R.exe*****;
****for R-2.14.0, use: C:\Progra~1\R\R-2.14.0\bin\R.exe*****;

data front_code after_code body_code r_code Rlog file; delete; run;
data body_code;
     infile "&saswork/&r_code..r" length=len;
     input var1 $varying8192. len;
run;

data _null_;
	 call symput('sasdirec',trim(left(tranwrd("&saswork",'\','/'))));
	 call symput('rdirec',trim(left(tranwrd("&saswork",'\','/'))));
	 call symput('rsaswork',trim(left(tranwrd("&saswork",'\','/'))));
run;	     
*****determine if customer defined code produce fixed figure*****;
%let crfg=0;
%let userdefloc=0;
data _null_;
    set body_code;
	if index(lowcase(var1),'setwd') and 
       (index(lowcase(var1),'#')=0 or index(lowcase(var1),'#')> index(lowcase(var1),'setwd')) then do;
	   call symput('userdefloc','1');
       directory=scan(var1,2,'(');
	   directory=compress(directory,'"();');
	   directory=compress(directory,"'");
   	   call symput('rdirec',trim(left(directory)));
	   directory=tranwrd(directory,'\','/');
   	   call symput('sasdirec',trim(left(directory)));
	 end;
	 if index(lowcase(var1),'.gif') or index(lowcase(var1),'.jpeg') or index(lowcase(var1),'.jpg') 
            or index(lowcase(var1),'.png') or index(lowcase(var1),'.ps') or index(lowcase(var1),'.pdf') 
            then call symput('crfg','1');
run;
*******convert sas file to csv for R import******;
%let i=1;
%do %while(%scan(&_sas2R,&i,%str( )) ne);
    %let transfer=%scan(&_sas2R,&i,%str( ));
	%let i=%eval(&i+1); 
    proc export data=&transfer outfile="&sasdirec/&transfer..csv" replace; run;
%end;

****get current time before run batch R***;
data _null_;
    call symput('nowtime',trim(left(scan(put(datetime(),best.),1,'.'))));
run;
%put $$$$&nowtime;

data front_code;
     length var1 $1000;
	 format var1 $1000.;
	 %if &userdefloc=0 %then %do;
         var1='setwd("'||"&rsaswork"||'")'; output;
	 %end;
	 var1='library(grDevices)'; output;
	 %if &crfg=0 %then %do;
	     var1='png("'||"&rdirec/_&nowtime"||'.png")'; output;
	 %end;
	 ******prepare R code use dataframe to read in SAS dataset via CSV****;
	 %let i=1;
     %do %while(%scan(&_sas2r,&i,%str( )) ne);
     %let transfer=%scan(&_sas2r,&i,%str( ));
	 %let i=%eval(&i+1); 
          var1="&transfer"||"<- read.csv('"||"&rdirec/&transfer..csv"||"')";
	      output;
	 %end;
run;

data after_code;
     length var1 $1000;
	 format var1 $1000.;
	 ******prepare R code to output csv file for sas import****;
	 %let i=1;
     %do %while(%scan(&_R2SAS,&i,%str( )) ne);
     %let transfer=%scan(&_R2SAS,&i,%str( ));
	 %let i=%eval(&i+1); 
          var1="write.csv(&transfer,'"||"&transfer..csv"||"',row.names=F)";
	      output;
	 %end;
 	 %if &crfg=0 %then %do;
	     var1='dev.off()'; output;
	 %end;
	 var1='q()'; output;
run;


*****update R code*****;
data r_code;
     set front_code body_code after_code;
run;
data _null_;
     file "&saswork/&r_code..r";
	 set r_code;
	 put var1;
run;


****get current time before run batch R***;
data _null_;
    call symput('beforetm',trim(left(put(datetime(),datetime19.))));
run;
%put $$$$&beforetm;

%let _saswork=%bquote("&rsaswork/&r_code..r");
%let _rdirec=%bquote("&rdirec/r_log_&nowtime..txt");
/*%put &_saswork;*/
/*%put &_rdirec;*/

%if &sysscp=WIN %then %do;
options noxwait xsync;
%end;
 
%let R_CMD_Script=%bquote("&rpath") CMD BATCH --vanilla --quiet &_saswork  &_rdirec;
%let R_CMD_Script=%unquote(%str(%')&R_CMD_Script%str(%'));
%put It is going to run the following R commands:;
%put &R_CMD_Script;
*Make sure to use X command but not pipe in sas;
X &R_CMD_Script;

****get current time after run batch R***;
data _null_;
    call symput('aftertm',trim(left(put(datetime(),datetime19.))));
run;
%put $$$$&aftertm;

data rlog;
     infile "&sasdirec/r_log_&nowtime..txt" length=len;
     input var1 $varying8192. len;
run;
data rlog;
     set rlog;
	 var1=trim(left(var1));
run;
title "******************R OUTPUT***********************";
proc print data=rlog(rename=(var1=R_OUTPUT_LOG)) noobs; run;
title;

*****display R graphics*****;
%let _sasdirec=%bquote("&sasdirec");
*For windows only;
%put You system is &sysscp;

%if "&sysscp"="WIN" %then %do;
%put Going to run the windows command to get files:;
%put dir &_sasdirec /a:-d;

FileName MyDir Pipe "dir &_sasdirec /a:-d";
data file;
  infile MyDir lrecl=1000 truncover;
  input @1 file $500. @;
  format   file $500.;
  crtime=substr(file,1,20);
  if trim(left(scan(lowcase(file),2,'.'))) in ('pdf','gif','png','jpeg','jpg','ps') then do;
   filename=prxchange("s/.*(_\d+\.(gif|png|jpeg|jpg|ps|pdf))/$1/",-1,file);
   if prxmatch('/(AM|PM)/i',crtime) then do;
     crtime=input(crtime,mdyampm.);
   end;
   else do;
   crtime=input(crtime,YMDDTTM24.);
   end;
  end;
  if trim(left(scan(lowcase(filename),2,'.'))) in ('pdf','gif','png','jpeg','jpg','ps');
run;
%end;
%else %do;
FileName MyDir Pipe "ls -GpFQl --full-time &_sasdirec|grep  / -v ";
data file;
  infile MyDir lrecl=1000 truncover;
  input @11 file $500. @;
  format   file $500.;
  crtime=prxchange('s/.* (\d+-\d+-\d+) (\d+:\d+:\d+\.\d+) .*/$1 $2/',-1,file);
  crtime=input(crtime,YMDDTTM24.);
  filename=prxchange('s/.*\"([^"]+)\".*/$1/',-1,file);
  file=filename;
  if trim(left(scan(lowcase(filename),2,'.'))) in ('pdf','gif','png','jpeg','jpg','ps');
run;
%end;

proc sort data=file; by descending crtime descending filename; 
      where trim(left(scan(lowcase(file),2,'.'))) in ('pdf','gif','png','jpeg','ps'); 
run;

data file_new;
     set file;
	 if _n_=1 then do;
	  if prxmatch('/(AM|PM)/i',crtime) then do;
        call symput('fgsw',put(input("&beforetm",datetime19.)<(input(crtime,mdyampm.)+60),best.));
	   end;
	   else do;
	    x1=input("&beforetm",datetime19.);
		x2=crtime+60;
        call symput('fgsw',put(x1<x2,best.));
	   end;
		call symput('fgname',trim(left(filename)));
	 end;
run;
%put macro var fgname is &fgname;
%put macro var fgsw is &fgsw;

%if &fgsw=0 %then %do;
%put No figures were generated in your R script;
%end;
%else %if &fgsw=1 %then %do;
%put The path for R generated figure is &sasdirec/&fgname;
%put Sas will write it html as &sasdirec/rhtml_&nowtime..html;
%put The GPATH is &sasdirec;

*Need to put ods html close here to generate figure from R;
ods html close;

ODS ESCAPECHAR='^';
ODS HTML FILE="rhtml_&nowtime..html" STYLE=minimal
GPATH="&sasdirec/" GTITLE GFOOTNOTE;

ods listing close;
%global inhtml;
%let inhtml=%bquote("&sasdirec/&fgname");
%put Macro var inhtml is &inhtml;
*Use ods to print R generated figure;
*Make sure use the file handle PRINT and add ODS after it.
*Make sure to add _ods_ after PUT;
DATA _NULL_;
FILE PRINT ods;
Figure_From_R="<IMG SRC=&inhtml BORDER='0'>";
PUT _ods_ ;
RUN;
/*Old code: failed*/
/*DATA _NULL_;*/
/*FILE PRINT;*/
/*put "<IMG SRC=&inhtml BORDER='0'>";*/
/*RUN;*/
/*ods html close;*/
/*ods listing;*/

/*
goptions reset=all device=win;
goptions iback="&rdirec/&fgname" imagestyle=fit; 
proc gslide;
run;
quit; 
*/
%end;
*******convert csv file from R to SAS file******;
%let i=1;
%do %while(%scan(&_R2SAS,&i,%str( )) ne);
    %let transfer=%scan(&_R2SAS,&i,%str( ));
	%let i=%eval(&i+1); 
    proc import datafile="&sasdirec/&transfer..csv" out=&transfer replace; guessingrows=1000; run;
%end;
options notes;
%mend;

/*Demo:

data test;
do i = 1 to 1000;
  x = normal(0);
  y = x + normal(0);
  output;
  end;
run;

data t2;
do i = 1 to 100;
  x = normal(0);
  y = x + uniform(0);
  output;
  end;
run;

options nomerror nomprint nomlogic nosymbolgen;
options nonotes;

*Put your R codes AFTER cards;
data a;
*N.T.: the length 1000 is also used by the macro proc_r_dsd4sas to combine R codes;
length codes $1000.;
infile cards;
input;
codes=_infile_;
cards;
an.lm = with(test,lm(y ~x))
mylm = t(coef(an.lm))
plot(1:100)
an.lm2 = with(t2,lm(y~x))
mylm2 = t(coef(an.lm2))

ls()
searchrst=search()
;
run;

options mprint mlogic symbolgen;
%proc_r_codes4sas(
rcodes_dsd4sas=a,
rcode_var=codes,
SAS2R =test t2, 
R2SAS =mylm mylm2 searchrst, 
rpath=C:\Program Files\R\R-3.6.3\bin\x64\R.exe
);

*Docker sas image R path: /usr/local/bin/anaconda2/bin/R;

proc print data = mylm; run;
proc print data = mylm2; run;
proc print data=searchrst;run;




data a;
*N.T.: the length 1000 is also used by the macro proc_r_dsd4sas to combine R codes;
length codes $1000.;
infile cards;
input;
codes=_infile_;
cards;
library('ComplexHeatmap')
Heatmap(c('a','b','c'))
;
run;
options mprint mlogic symbolgen;
%proc_r_codes4sas(
rcodes_dsd4sas=a,
rcode_var=codes,
SAS2R = , 
R2SAS = , 
rpath=C:\Program Files\R\R-3.6.3\bin\x64\R.exe
);
*Docker sas image R path: /usr/local/bin/anaconda2/bin/R;


*/

