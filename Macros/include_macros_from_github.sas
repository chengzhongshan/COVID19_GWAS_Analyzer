%macro include_macros_from_github(
macros=importallmacros_ue /*supply multiple macro names separated by blank space*/
);
%let totmacros=%sysfunc(countc(&macros,%str( )));
%do macro_i=1 %to &totmacros;
   filename out temp;
   %let url_link=https://raw.githubusercontent.com/chengzhongshan/COVID19_GWAS_Analyzer/main/Macros/%scan(&macros,&macro_i,%str( ));
   proc http  url="&url_link"
   out=out;
   run;
   /* data _null_; */
   /* infile out; */
   /* input; */
   /* put _infile_; */
   /* run; */
   %include out;
%end;
%mend;

/*Demo:;

%include_macros_from_github(
macros=importallmacros_ue
);
%importallmacros_ue;

*/
  

