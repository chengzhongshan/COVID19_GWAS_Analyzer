%macro LoadMacros;
%let macrodir=%sysfunc(pathname(HOME))/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;
%mend;

/*Demo codes:
*Load these macros;
options mprint mlogic symbolgen;
%include "%sysfunc(pathname(HOME))/Macros/LoadMacros.sas";
%LoadMacros;
*/
