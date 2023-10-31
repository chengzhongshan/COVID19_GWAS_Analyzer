%macro get_consecutive_num4linker(nums_with_linker,global_macro_out,linker=-);
%global &global_macro_out;
*replace numbers with linker to consective numbers;
%if %sysfunc(prxmatch(/\s*&linker\s*/,&nums_with_linker)) %then %do;
 %let _nums_with_linker_=&nums_with_linker;
 %let n_linkers=%sysfunc(countc(&nums_with_linker,"&linker"));
 %do l=1 %to &n_linkers;
 *The regx here is prone to error;
  %if %sysfunc(prxmatch(/^\d+&linker/,&_nums_with_linker_)) %then %do;
   %let st_end=%sysfunc(prxchange(s/^(\d+)\s*&linker\s*(\d+)\D*.*/$1&linker$2/,1,&_nums_with_linker_));
  %end;
  %else %do;
   %let st_end=%sysfunc(prxchange(s/^[^&linker]+\s+(\d+)\s*&linker\s*(\d+)\D*.*/$1&linker$2/,1,&_nums_with_linker_));
  %end;

  %let st=%scan(&st_end,1,"&linker");
  %let end=%scan(&st_end,2,"&linker");

  %let nums_tmp=;
  %do y=&st %to &end;
    %let nums_tmp=&nums_tmp &y; 
  %end;
  *replace it with &nums_tmp;
  %let _nums_with_linker_=%sysfunc(prxchange(s/\d+\s*&linker\s*\d+/&nums_tmp/,1,&_nums_with_linker_));
 %end;
 
 %put your original nums_with_linker &nums_with_linker has been changed into:;
 %put &_nums_with_linker_;


 *Assign consecutive numbers to the global macro variable;
 %let &global_macro_out=&_nums_with_linker_;
 
%end;
%else %do;
%put No need to get consecutive numbers as there is not linker among your input numbers;
%put &nums_with_linker;
%let &global_macro_out=&nums_with_linker;
%end;

%mend;

/*Demo:;
*Create a global macro var &num2_with_linker;

options mprint mlogic symbolgen;

%get_consecutive_num4linker(nums_with_linker=1 2 4-6 10 13-15, global_macro_out=numbers, linker=-);
%put &numbers;

%get_consecutive_num4linker(nums_with_linker=1-32 34-66 33, global_macro_out=numbers, linker=-);
%put &numbers;


*/

