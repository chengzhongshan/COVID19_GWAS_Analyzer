%macro remove_newline_separator(mvar);
%*It is impossible to replace newline included in a macro var;
%*This is because SAS automatically transform newline as space;
%put it is impossible to replace newline in the var &mvar, as sas already automatically treats newline as space;
%abort 255;

%local newvar newline;
%let newline=%sysfunc(inputc(0D0A,$hex4.));
%let mvar=%left(%trim(&mvar));
/* %put &mvar; */

/* This failed to replace the newline, as SAS treats newline as space: 
   %let newvar=%sysfunc(prxchange(s/\n//,-1,&mvar)); 
*/
%let newvar=%sysfunc(prxchange(s/ /_/,-1,&mvar));

&newvar

%mend;
/*Demo codes:;
*It is a sas function to remove \n in a input macro variable;
*nrstr or nrbquote does not work;
%let input_var=%nrbquote(I am the 1st line
I am the 2nd line);
%put &input_var;

%let newvar=%remove_newline_separator(mvar=&input_var);


*/
