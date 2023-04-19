%macro initcaps(title);
   %local newtitle lastchar;
   %let newtitle=;
   %let lastchar=;
   %do i=1 %to %length(&title);
      %let char=%qsubstr(&title,&i,1);
      %if (&lastchar=%str( ) or &i=1) %then %let char=%qupcase(&char);
      %else %let char=%qlowcase(&char);
      %let newtitle=&newtitle&char;
      %let lastchar=&char;
   %end;
   &newtitle
%mend;
/*Demo:
%let CapedStr=%initcaps(%str(sales: COMMAND REFERENCE, VERSION 2, SECOND EDITION));
%put &CapedStr;
*/
