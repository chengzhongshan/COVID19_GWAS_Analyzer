
%macro ImportFilebyScanAtCol(
file        /*raw data file path*/
,dsdout     /*SAS output dataset name; N.B.: All variables are in character!*/
,firstobs=0 /*The line number for header; if there is no header, firstobs=0*/
,dlm='09'x /*Delemiter for raw data*/
,ImportAllinChar=1 /*Imporat all data as char, otherwise import all as number*/
,MissingSymb=NaN  /*Specific missing data value in file*/
,FromColNum=1
);

*Make Linux and WIN usable filedir;
%let file=%sysfunc(prxchange(s/\\/\//,-1,&file));

%if &firstobs=0 %then %do;
%str(data _null_;
infile "&file" dsd dlm=&dlm truncover lrecl=32767 firstobs=1 obs=1;
input;
/*Calcuate total number of vars*/
if (_n_=1) then do;
 i=&FromColNum;
 do while(scan(_infile_,i,&dlm) ne "");
  call symput(compress(catx("","V",i)),compress(catx("","V",i)));
  call symput('var_n',strip(left(i)));
  i=i+1;
 end;
end;
run;
);
%end;

%if &firstobs>0 %then %do;
%str(data _null_;
infile "&file" dsd dlm=&dlm truncover lrecl=32767 firstobs=&firstobs obs=&firstobs;
input;
/*Calcuate total number of vars*/
if (_n_=1) then do;
 i=&FromColNum;
 do while(scan(_infile_,i,&dlm) ne "");
  y=strip(left(scan(_infile_,i,&dlm)));
  /*Need to replace - with _ in header*/
  /*Also need to replace . with _ in header*/
  y=prxchange("s/[-()\.\+]+/_/",-1,y);
  /*Also add _ at the beginning of var with numers*/
  y=prxchange("s/^(\d)/_$1/",-1,y);
/*  remove blank spaces in header if dlm is not space;*/
  if &dlm ne ' ' then do;
   y=prxchange("s/ +/_/",-1,strip(y));
  end;
/*make var name no more than 32 chars*/
  y=substr(y,1,32);
  call symput(compress(catx("",'V',i)),strip(left(y)));
  call symput('var_n',strip(left(i)));
  i=i+1;
 end;
end;
run;
);
%end;

%put &V1 &V2 &var_n;
%local dataline;
%let dataline=%eval(&firstobs+1);
data _null_;
/*It is important to assign the length to y*/
/*otherwise the largest length of y will be only 200*/
length y $32767;
%if &MissingSymb ne %then %do;
missing &MissingSymb;
%end;

infile "&file" dsd dlm=&dlm truncover lrecl=32767 firstobs=&dataline end=eof;
input;
/*Calcuate total number of vars*/
 i=&FromColNum;
 array variables {&var_n} _temporary_ (
      %do x= &FromColNum %to &var_n;
      0 
      %end;
);
 do ii=&FromColNum to &var_n;
  /*modifer: m
  The string begins with a delimiter and you request the first word.
  The string ends with a delimiter and you request the last word.
  The string contains two consecutive delimiters and you request the word that is between the two delimiters.
 */
  y=strip(left(scan(_infile_,ii,&dlm,'m')));
  len_y=length(y);
  if len_y>variables{ii} then do;
    variables{ii}=len_y;
  end;
 end;
if eof then do;
 do iii=&FromColNum to &var_n;
  var_length=variables{iii};
  call symput(compress(catx("",'LenVar',iii)),strip(left(var_length)));
 output;
 end;
end;
run;

%put "There are &var_n variables, and the length of the these variables are:";
%do i=1 %to &var_n;
 %put "&&V&i => &&LenVar&i";
%end;

options compress=yes;

data &dsdout;
length %if (&ImportAllinChar) %then %do;
       /*Import all data as char*/
         %do x=&FromColNum %to &var_n;
          &&V&x $%str(&&LenVar&x.) 
         %end;
		%end;
		/*Import all data as number*/
       %else %do;
		 %do x=&FromColNum %to &var_n;
		 /*For the numeric variable (length <4)*/
		  %if (&&LenVar&x>4) %then %do;
           &&V&x %str(&&LenVar&x.) 
		  %end;
		  %else %do;
           &&V&x %str(&&LenVar&x.)
		  %end;
         %end;
		%end;
;

%if &MissingSymb ne %then %do;
missing &MissingSymb;
%end;

infile "&file" dsd dlm=&dlm lrecl=32767 truncover firstobs=&dataline;
input %do x=&FromColNum %to &var_n;
       &&V&x
       %end;;
run;
options compress=no;
%mend;
/*

x cd I:\OV_SNP6_TN_Num420;
options mprint mlogic symbolgen;

*The line number for header; if there is no header, firstobs=0;
*if the header is at 3 rows, provde 3 to the macro var firstobs!;

%ImportFilebyScanAtCol(
file=TCGA-59-2355-01A-01R-1569-13.cd.bed
,dsdout=dsd
,firstobs=0
,dlm='09'x
,ImportAllinChar=1
,MissingSymb=NaN
,FromColNum=3
);
*/
