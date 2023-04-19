%macro importmacroslinux;
%let MacroDir=/project/fas/gelernter/zc254/SAS/SAS-Useful-Codes/Macros;
%include "&MacroDir/ImportAllMacros.sas";
%ImportAllMacros(MacroDir=&MacroDir,filergx=.*);
%mend;

