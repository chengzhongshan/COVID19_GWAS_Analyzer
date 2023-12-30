%macro parse_macro_used_macros(macro_filepath,dsdout);
data &dsdout;
retain macro_i 0;
length file $1000. Macro_Info $1000.;
infile "&macro_filepath" lrecl=10000 obs=max;
input;
Macro_Info=_infile_;
x=Macro_info;

*It is important to stop the processing when encounter these Demo codes;
if prxmatch("/Demo/i",Macro_Info) then stop;

file="&macro_filepath";
*Use regex to parse lines in macro for submacros used by the macro;
if prxmatch("/^(\s)?\%([^\(])+\(/i",Macro_Info) then do;
/* call symputx('_macrodir_',trim(left(prxchange("s/(^.*[\/\\])[^\/\\]+.sas/$1/i",-1,file))));*/
 file=scan(file,-2,'/.\');

 Macro_Info=trim(left(prxchange("s/^.*(?:\s?)\%([^\s\(\%]+)\(.*/$1/",-1,Macro_Info)));
 Macro_Info=prxchange('s/\%macro\s+([^\(]+).*$/$1/i',-1,Macro_Info);
 macro_i=macro_i+1;
 if Macro_Info^=file then do;
/*   call symputx('totmacros',put(macro_i,3.));*/
/*   call symputx('submacro'||trim(left(put(macro_i,3.))),Macro_Info);*/
   stage=1;
   output;
 end;
end;
run;
%mend;

/*Demo:
%let macro_file=H:\F_Queens\360yunpan\SASCodesLibrary\SAS-Useful-Codes\Macros\macroparas.sas;
%parse_macro_used_macros(macro_filepath=&macro_file,dsdout=macro_info);;
*/

