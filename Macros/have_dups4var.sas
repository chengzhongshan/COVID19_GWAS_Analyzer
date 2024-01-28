%macro have_dups4var(
dsdin=,
var=,
dup_indicator= ,/*A name for a global macr var to indicate whether there are dups in var,
the value of which will be 1 or 0*/
dupdsdout=dups,/*A sas dataset containing exisiting duplicates*/
nodupdsdout=nodups /*A sas dataset containing non-duplicates*/
);
 %global &dup_indicator;
*Determine whether there are identical  values for a var;
proc sort data=&dsdin nodupkeys out=&nodupdsdout dupout=&dupdsdout;by &var;run;
*No duplicated keys detected;
%let totrecords=%totobsindsd(&dupdsdout);
 %if &totrecords>0 %then %do;
						%put There are &totrecords duplicates for the var &var in the input dataset &dsdin..;
						%put A global macro var &dup_indicator has been created and its value is 1!;
						%let &dup_indicator=1;
 %end;
 %else %do;
						%put There is no duplicates for the var &var in the input dataset &dsdin..;
						%put A global macro var &dup_indicator has been created and its value is 0!;
						%let &dup_indicator=0;
 %end;
%mend;
/*Demo codes:;

%have_dups4var(
dsdin=sashelp.cars,
var=make,
dup_indicator=make_dup_tag,
dupdsdout=dups,
nodupdsdout=nodups 
);

%put &make_dup_tag;

*/

