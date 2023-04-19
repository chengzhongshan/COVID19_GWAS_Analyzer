/*
In macro DataReplacement
dsd            =>       target dsd subjects to replacement
vars2replace   =>       variables to be replace with specific data; if it is empty, will select all variables (either numeric or character)
var_type       =>       numeric or character
filter4replace =>       regex to match word or number in variables to be replaced
replacement    =>       the final word or number used for replacement
dsdout         =>       sas output dataset name 
*/


/*option mprint mlogic symbolgen;*/

/*

%DataReplacement(
dsd,
vars2replace,                                   
var_type,
filter4replace,
replacement,
dsdout);
*/
%macro DataReplacement(
dsd,
vars2replace,                                   
var_type,
filter4replace,
replacement,
dsdout
);
%if (&var_type ne ) %then %do;
 %if (%eval(%upcase(&var_type)=NUMERIC)) %then %do;
  proc contents data=&dsd(keep=_numeric_) noprint out=&dsd._varlist;
  run;
 %end;
 %if (%eval(%upcase(&var_type)=CHARACTER)) %then %do;
  proc contents data=&dsd(keep=_character_) noprint out=&dsd._varlist;
  run;
 %end;
%end;
%else %do;
  %abort 255;
%end;

%if (&vars2replace eq ) %then %do;
  proc sql noprint;
  select NAME into: vars2replace separated by ' '
  from &dsd._varlist;
%end;

data &dsd._rev;
set &dsd;
keep &vars2replace;
run;

data &dsd._left;
set &dsd;
drop &vars2replace;
run;

data &dsd._rev;
set &dsd._rev;
%if (%eval(%upcase(&var_type)=NUMERIC)) %then %do;
 array var_list{*} &vars2replace;
%end;
%if (%eval(%upcase(&var_type)=CHARACTER)) %then %do;
 array var_list{*} $ &vars2replace;
%end;
do i=1 to dim(var_list);
     var_list{i}=prxchange("s/&filter4replace/&replacement/i",-1,var_list{i});
end;
drop i;
run;


data &dsdout;
set &dsd._rev;
set &dsd._left;
run;

proc datasets nolist;
delete %upcase(&dsd._:);
run;

%mend;


*Note: make sure to select only the same type of variables to replace data;
/*options mprint mlogic symbolgen;*/
/*data a;*/
/*set sashelp.cars(obs=10);*/
/*run;*/
/*%DataReplacement(*/
/*dsd=a,*/
/*vars2replace=, /*if empty, will process all numeric or character variables*/                                  */
/*var_type=character,/*character or numeric*/*/
/*filter4replace=%str(%(a%)),/*perl regex to match element in data*/*/
/*replacement=%str($1X$1),	    /*replacement value*/*/
/*dsdout=out);*/
/**/
