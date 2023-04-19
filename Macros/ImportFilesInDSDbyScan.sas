
%macro ImportFilesInDSDbyScan(filedsd             /*sas dsd containing filenames*/
,filename_var             /*filename variable in the above dsd*/
,fileDir/*raw data file dir; if using fullpath in dsd,let it empty*/
,fileRegexp             /*regexp to match files*/
,dsdout/*SAS output dataset name; N.B.: All variables are in character!*/
,firstobs=0            /*The line number for header; if there is no header, firstobs=0*/
,dlm='09'x             /*Delemiter for raw data*/
,ImportAllinChar=1    /*Imporat all data as char, otherwise import all as number*/
,MissingSymb=NaN     /*Specific missing data value in file*/
,notverbose=1
,debug=0
);


data filenames(keep=memname);
set &filedsd;

*Replace tailing '\' for working in both linux and windows;
&filename_var=prxchange('s/[\\\/]$//',-1,&filename_var);
&filename_var=prxchange('s/\\/\//',-1,&filename_var);

%if &filename_var ne "memname" %then %do;
%str(rename &filename_var=memname);;
%end;
run;

proc sql;
create table filenames as
select * from filenames
where prxmatch(%str("/&fileRegexp/"),memname);

*Check the total number of variables in one of many files in dir;
%if &firstobs=0 %then %do;

data _null_;
set filenames(obs=1);
%if &fileDir ne %then %do;
filepath = "&fileDir"||"/"||memname;
%end;
%else %do;
filepath = memname;
%end;
infile dummy filevar=filepath end=done dsd dlm=&dlm truncover lrecl=32767 firstobs=1 obs=1;
*no need to use while loop for all files in filenames;
input;
/*Calcuate total number of vars*/
if (_n_=1) then do;
 i=1;
 do while(scan(_infile_,i,&dlm) ne "");
  call symput(compress(catx("","V",i)),compress(catx("","V",i)));
  call symput('var_n',strip(left(i)));
  i=i+1;
  end;
 end;
run;

%end;

*Get headers from one of many files in dir;
%if &firstobs>0 %then %do;
data _null_;
set filenames(obs=1);
%if &fileDir ne %then %do;
filepath = "&fileDir"||"/"||memname;
%end;
%else %do;
filepath = memname;
%end;
infile dummy filevar=filepath end=done dsd dlm=&dlm truncover lrecl=32767 firstobs=&firstobs obs=&firstobs;
*no need to use while loop for all files in filenames;
input;
/*Calcuate total number of vars*/
if (_n_=1) then do;
 i=1;
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

%end;

%put &V1 &V2 &var_n;
%local dataline;
%let dataline=%eval(&firstobs+1);

*Supress notes source errors;
%if &notverbose %then %do;
options nonotes nosource nosource2 errors=0;
%end;

*Going to scan all the files and find the max length for all vars;
data _null_;
/*It is important to assign the length to y*/
/*otherwise the largest length of y will be only 200*/
length y $32767;
%if &MissingSymb ne %then %do;
missing &MissingSymb;
%end;

%if &debug %then %do;
set filenames (obs=3);;
%end;
%else %do;
set filenames;;
%end;

%if &fileDir ne %then %do;
filepath = "&fileDir"||"/"||memname;
%end;
%else %do;
filepath = memname;
%end;

*no need to use while loop for all files in filenames;
infile dummy filevar=filepath dsd dlm=&dlm truncover lrecl=32767 firstobs=&dataline end=eof;
*need to use while loop for 'end' at infile and set statment;
 i=1;
 array variables {&var_n} _temporary_ (
      %do x= 1 %to &var_n;
      0 
      %end;
 );
do while(not eof);
 input;
/*Calcuate total number of vars*/
 do ii=1 to &var_n;
  /*modifer: m
  The string begins with a delimiter and you request the first word.
  The string ends with a delimiter and you request the last word.
  The string contains two consecutive delimiters and you request the word that is between the two delimiters.
 */
  y=strip(left(scan(_infile_,ii,&dlm,'m')));
  len_y=length(y);
  if len_y>variables{ii} then do;
    variables{ii}=len_y;
	*put len_y;
  end;
 end;
 do iii=1 to &var_n;
  var_length=variables{iii};
  call symput(compress(catx("",'LenVar',iii)),strip(left(var_length)));
  *output;*is it necessary?;
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
         %do x=1 %to &var_n;
          &&V&x $%str(&&LenVar&x.) 
         %end;
		%end;
		/*Import all data as number*/
       %else %do;
		 %do x=1 %to &var_n;
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

%if &debug %then %do;
set filenames (obs=3);;
%end;
%else %do;
set filenames;;
%end;

set filenames;

%if &fileDir ne %then %do;
filepath = "&fileDir"||"/"||memname;
%end;
%else %do;
filepath = memname;
%end;

*need to use while loop for all files in filenames;
infile dummy filevar=filepath dsd dlm=&dlm lrecl=32767 truncover firstobs=&dataline end=done;
do while (not done);
*myfilename = memname;
input 
%do x=1 %to &var_n;
       &&V&x 
%end;;
output;*otherwise only one record printed!;
end;
run;

options compress=no;
%if &notverbose %then %do;
options notes source source2 errors=20;
%end;

%mend;

/*
%let Path=I:\BRCA_SNP6_TN_Num1061\BRCA_TCGA_ASE_Analysis\maps;
%get_filenames(location=&fileDir);
data all_text (drop=fname);
  set filenames(obs=2);
  filepath = "&fileDir"||"\"||memname;
  infile dummy filevar = filepath length=reclen end=done dsd delimiter='09'x;
  do while(not done);
    myfilename = filepath;
	length y $32767.;
    input;
	y=_infile_;
    output;
  end;
run;
*/

/*

options mprint mlogic symbolgen;

*The line number for header; if there is no header, firstobs=0;
*if the header is at 3 rows, provde 3 to the macro var firstobs!;

%get_filenames(location=%bquote(&gene_ase_dir),dsd_out=filenames);
%ImportFilesInDSDbyScan(filedsd=filenames
,filename_var=memname
,filedir=C:\Users\Sam\Desktop\test
,fileRegexp=x2
,dsdout=dsd
,firstobs=0
,dlm='09'x
,ImportAllinChar=1
,MissingSymb=NaN
,notverbose=1
,debug=0
);


*If using fullpath in dsd,just let filedir empty;

%RecSearchFiles2dsd(
root_path=TARGETED_PATH,
filter=.sas$,           
perlfuncpath=E:/F_Queens/360yunpan/SASCodesLibrary/SAS-Useful-Codes,
outdsd=filenames,
outputfullfilepath=1);

%ImportFilesInDSDbyScan(filedsd=filenames
,filename_var=filefullname
,filedir=
,fileRegexp=x2
,dsdout=dsd
,firstobs=0
,dlm='09'x
,ImportAllinChar=1
,MissingSymb=NaN
,notverbose=1
,debug=0
);

*/
