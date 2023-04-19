
/*%let sysparm = name1=value1,name2=value2,name3=value3 ;*/

/*
Accepts multiple name value pairs e.g
-sysparm ‘name1=value1,name2=value2’
N.B.: &name1 &name2 are %global
      sysparm must be put at the end of command;
*/


%macro multi_sysparm;
data _null_;
length sysparm express param value $ 200;
sysparm = symget('sysparm');
do i=1 to 50 until(express = '');
express = left(scan(sysparm, i, ',')); /* name=value */
param = left(upcase(scan(express, 1, '='))); /* name */
value = left(scan(express, 2, '='));
valid = not verify(substr(param, 1, 1),'ABCDEFGHIJKLMNOPQRSTUVWXYZ_')
and not verify(trim(param),'ABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789')
and length(param) <=32 ; /* Ensure valid V8 macrovar name */
if valid then call symput(param, trim(left(value)));
end;
run;
%put _user_ ;
%mend;

/*Demo:
put the following at the beginning of a sas script;

%macro orion_print2(year,pline) ;
proc print noobs
data = sashelp.orsales;
where year=&year and product_line="&pline";
run;
%mend;

%multi_sysparm ;
%orion_print2(&year,&pline);

*Call it like:
*sas_en -append sasautos /LocalDisks/F/360yunpan/SASCodesLibrary/SAS-Useful-Codes/Macros -nodate xx.sas -sysparm "year=1999,pline=Sports"

*/
