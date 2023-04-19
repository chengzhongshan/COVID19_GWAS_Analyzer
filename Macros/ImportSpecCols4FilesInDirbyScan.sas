
%macro ImportSpecCols4FilesInDirbyScan(
fileDir        /*raw data file dir*/
,fileRegexp             /*regexp to match files*/
,dsdout     /*SAS output dataset name; N.B.: All variables are in character!*/
,firstobs=0 /*The line number for header; if there is no header, firstobs=0*/ 
	    /*if the header is at 3 rows, provde 3 to the macro var firstobs!*/
,dlm='09'x /*Delemiter for raw data*/
,ImportAllinChar=1 /*Imporat all data as char, otherwise import all as number*/
,MissingSymb=NaN  /*Specific missing data value in file*/
,SpeColNums=1
,notverbose=1
,debug=0
);

*Make Linux and WIN usable filedir;
%let fileDir=%sysfunc(prxchange(s/\\/\//,-1,&fileDir));
%let var_n=%numargs(&SpeColNums);
%let Old_ColNums=&SpeColNums;
%let SpeColNums=%sysfunc(prxchange(s/\s+/%str(,)/,-1,&SpeColNums));

proc datasets lib=work noprint;
delete filenames;
run;


%get_filenames(location=&fileDir,dsd_out=filenames);
proc sql;
create table filenames as
select * from filenames
where prxmatch(%str("/&fileRegexp/"),memname);


*Check the total number of variables in one of many files in dir;
%if &firstobs=0 %then %do;
%str(
data _null_;
set filenames(obs=1);
filepath = "&fileDir"||"/"||memname;
infile dummy filevar=filepath end=done dsd dlm=&dlm truncover lrecl=32767 firstobs=1 obs=1;
*no need to use while loop for all files in filenames;
input;
/*Calcuate total number of vars*/
if (_n_=1) then do;
/*  Filter cols*/
  do ci=&SpeColNums;
     call symput(compress(catx("","V",ci)),compress(catx("","V",ci)));
  end;
 end;
run;
);
%end;



*Get headers from one of many files in dir;
%if &firstobs>0 %then %do;
%str(data _null_;
set filenames(obs=1);
filepath = "&fileDir"||"/"||memname;
infile dummy filevar=filepath end=done dsd dlm=&dlm truncover lrecl=32767 firstobs=&firstobs obs=&firstobs;
*no need to use while loop for all files in filenames;
input;
/*Calcuate total number of vars*/
if (_n_=1) then do;
  /*  Filter cols*/
  do ci=&SpeColNums;
    y=strip(left(scan(_infile_,ci,&dlm)));
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
    call symput(compress(catx("",'V',ci)),strip(left(y)));
   end;
  end;
run;
);
%end;

%put &var_n vars in your selected cols: &SpeColNums;

%local dataline;
%let dataline=%eval(&firstobs+1);

*Supress notes source errors;
%if &notverbose %then %do;
options nonotes nosource nosource2 errors=0;
%end;

*Going to scan all the files and find the max length for all vars;
data debug;
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

filepath = "&fileDir"||"/"||memname;
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
 z=1;
 do ii=&SpeColNums;
  /*modifer: m
  The string begins with a delimiter and you request the first word.
  The string ends with a delimiter and you request the last word.
  The string contains two consecutive delimiters and you request the word that is between the two delimiters.
 */
  y=strip(left(scan(_infile_,ii,&dlm,'m')));
  len_y=length(y);
  if len_y>variables{z} then do;
    variables{z}=len_y;
  end;
  z=z+1;
 end;

 zz=1;
 do iii=&SpeColNums;
  var_length=variables{zz};
  call symput(compress(catx("",'LenVar',iii)),strip(left(var_length)));
  output;
  zz=zz+1;
 end;
end;
run;
/*%abort 255;*/

%put "There are &var_n variables, and the length of the these variables are:";
%do i=1 %to &var_n;
 %let vi=%scan(&Old_ColNums,&i,%str( ));
 %put "&&V&vi => &&LenVar&vi";
%end;
/*%abort 255;*/

options compress=yes;

data &dsdout;
%if (&ImportAllinChar) %then %do;
       /*Import all data as char*/
         %let i=1;
		 %str(length )
         %do %while (&i <= &var_n);
		  %let x=%scan(&Old_ColNums,&i,%str( ));
          &&V&x $%str(&&LenVar&x.) 
		  %let i=%eval(&i+1);
         %end;
		%end;
		/*Import all data as number*/
       %else %do;
         %let i=1;
		 %str(informat )
         %do %while (&i <= &var_n);
		  %let x=%scan(&Old_ColNums,&i,%str( ));
		 /*For the numeric variable (length <4)*/
		  %if (&&LenVar&x<=12) %then %do;
           &&V&x %str(best12.)
		  %end;
		  %else %do;
           &&V&x %str(best32.)
		  %end;
		  %let i=%eval(&i+1);
         %end;
		%end;
;

%if (not &ImportAllinChar) %then %do;
         %let i=1;
		 %str(format )
         %do %while (&i <= &var_n);
		  %let x=%scan(&Old_ColNums,&i,%str( ));
		 /*For the numeric variable (length <4)*/
		  %if (&&LenVar&x<=12) %then %do;
           &&V&x %str(best12.)
		  %end;
		  %else %do;
           &&V&x %str(best32.)
		  %end;
		  %let i=%eval(&i+1);
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
filepath = "&fileDir"||"/"||memname;
*need to use while loop for all files in filenames;
infile dummy filevar=filepath dsd dlm=&dlm lrecl=32767 truncover firstobs=&dataline end=done;
do while (not done);
*myfilename = memname;
input;
%let i=1;
%do %while (&i <= &var_n);
       %let x=%scan(&Old_ColNums,&i,%str( ));
       &&V&x=strip(left(scan(_infile_,&x,&dlm)));
       %let i=%eval(&i+1);
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
  filepath = "&fileDir"||"/"||memname;
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
%let dir=F:\Beds\tmp;

options mprint mlogic symbolgen;

*The line number for header; if there is no header, firstobs=0;
*if the header is at 3 rows, provde 3 to the macro var firstobs!;

%ImportSpecCols4FilesInDirbyScan(
filedir=&dir
,fileRegexp=bed
,dsdout=dsd
,firstobs=0
,dlm='09'x
,ImportAllinChar=1
,MissingSymb=NaN
,SpeColNums=1
,notverbose=1
,debug=1
);

*/
