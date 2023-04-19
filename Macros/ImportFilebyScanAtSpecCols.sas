
%macro ImportFilebyScanAtSpecCols(
file        /*raw data file path*/
,dsdout     /*SAS output dataset name; N.B.: All variables are in character!*/
,firstobs=0 /*The line number for header; if there is no header, firstobs=0*/
,dlm='09'x /*Delemiter for raw data*/
,ImportAllinChar=1 /*Imporat all data as char, otherwise import all as number*/
,MissingSymb=NaN  /*Specific missing data value in file*/
,SpeColNums=1
);

*Make Linux and WIN usable filedir;
%let file=%sysfunc(prxchange(s/\\/\//,-1,&file));
%let var_n=%numargs(&SpeColNums);
%let Old_ColNums=&SpeColNums;
%let SpeColNums=%sysfunc(prxchange(s/\s+/%str(,)/,-1,&SpeColNums));
%if &firstobs=0 %then %do;
%str(data _null_;
infile "&file" dsd dlm=&dlm truncover lrecl=32767 firstobs=1 obs=1;
input;
/*Calcuate total number of vars*/
if (_n_=1) then do;
 do i=&SpeColNums;
  call symput(compress(catx("","V",i)),compress(catx("","V",i)));
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
 do i=&SpeColNums;
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
 end;
end;
run;
);
%end;
%put &var_n vars in your selected cols: &SpeColNums;

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
 array variables {&var_n} _temporary_ (
      %do x= 1 %to &var_n;
      0 
      %end;
);
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
if eof then do;
 zz=1;
 do iii=&SpeColNums;
  var_length=variables{zz};
  call symput(compress(catx("",'LenVar',iii)),strip(left(var_length)));
 output;
 zz=zz+1;
 end;
end;
run;

%put "There are &var_n variables, and the length of the these variables are:";
%do i=1 %to &var_n;
 %let vi=%scan(&Old_ColNums,&i,%str( ));
 %put "&&V&vi => &&LenVar&vi";
%end;


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

infile "&file" dsd dlm=&dlm lrecl=32767 truncover firstobs=&dataline;
input;

%let i=1;
%do %while (&i <= &var_n);
       %let x=%scan(&Old_ColNums,&i,%str( ));
       &&V&x=strip(left(scan(_infile_,&x,&dlm)));
       %let i=%eval(&i+1);
%end;;
run;
options compress=no;
%mend;
/*


options mprint mlogic symbolgen;

*The line number for header; if there is no header, firstobs=0;
*if the header is at 3 rows, provde 3 to the macro var firstobs!;

%ImportFilebyScanAtSpecCols(file=G:\Yale_GWAS\MJ_HL_GWAS\GWAS_Rstmat0.01_mind0.05_geno0.05\Top_ALL_GWGO_HCE.EA_combined_meta.Gemma.txt
,dsdout=dsd
,firstobs=1
,dlm='09'x
,ImportAllinChar=0
,MissingSymb=NaN
,SpeColNums=1 2 7
);



%ImportFilebyScanAtSpecCols(file=F:\Beds\tmp\All_Roadmap_H3K4me3_Union_Promoter_Sum1.bed
,dsdout=dsd
,firstobs=0
,dlm='09'x
,ImportAllinChar=1
,MissingSymb=NaN
,SpeColNums=1 2 4
);
*/
