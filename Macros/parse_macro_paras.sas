%macro parse_macro_paras(macro_filepath,dsdout);
data &dsdout;
infile "&macro_filepath" lrecl=10000 obs=max;
input;
Macro_Info=_infile_;
run;
/**Print macro with specific style;*/
/*title "Contents of first &numlines2print lines of SAS macro: &macro_filepath";*/
/*proc print data=_macros_ noobs;*/
/*var Macro_Info/style =[width=15in] */
/*         style(data)=[font_face=arial font_weight=bold foreground=darkblue background=cxedf2f9 font_size=10pt];*/
/**background=linen;*/
/*label Macro_Info="SAS Macro information";*/
/*run;*/
/*run;*/

*Output macro parameters as a sas data set;
%let _macro_=%sysfunc(prxchange(s/.*[\/\\]([^\/\\]+).sas/$1/i,-1,&macro_filepath));
%put Parsing macro parameters for the macro &_macro_;
data &dsdout (drop=tag Macro_info);
length macro_paras $32767. macro $1000.;
retain tag 0 macro_paras '';
set &dsdout;
macro="&_macro_";

if prxmatch("/.macro\s+&_macro_/i",macro_info) then do;
  tag=1;
  *Note: it is necessary to add two dots after &_macro_, as sas resolve &_macro_. as &_macro_;
  macro_paras=prxchange("s/.*(&_macro_..*)/$1/i",-1,macro_info);

  *For macros using parmbuff;
  macro_paras=prxchange("s/\/parmbuff;/;/i",-1,macro_paras);
  *Further remove pct macro;
  macro_paras=prxchange("s/.macro//i",-1,macro_paras);

  if prxmatch("/&_macro_\s*[;]/",macro_paras) then macro_paras="&_macro_;";

  if prxmatch("/&_macro_[\(][^\)]+[\)][;\s]*$/",macro_paras) or macro_paras="&_macro_;" 
  then do;
     tag=0;output;
  end;
end;
else if (tag=1) then do;
   macro_paras=catx(
   '',
   macro_paras,
   macro_info
  );
  if prxmatch("/[\)]\s*[;]\s*$/",macro_paras) then do;
     tag=0;output;
  end;   
end;
run;
%mend;

/*Demo codes:;
%let macro_file=H:\F_Queens\360yunpan\SASCodesLibrary\SAS-Useful-Codes\Macros\unique.sas;
%debug_macro;
%parse_macro_paras(macro_filepath=&macro_file,dsdout=macro_info);
*/

