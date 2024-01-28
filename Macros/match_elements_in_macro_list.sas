%macro match_elements_in_macro_list(
macro_list=,/*elements should be separated by blank space*/
rgx4match=,/*regular expression of prxmatch, such as (rgx1|rgx2)*/
reversematch=0,/*provide 0 to keep elements not matched with the rgx*/
output_idx=0, /*Instead of keeping matched or unmatched elements, keep the 1-based
indices for these elements in the original macro_list, which would be useful
to be transformed into a sas data set by the macro for further analysis!*/
new_macro_list_var=newlist /*a new global macro var containing the final output*/
);

%let tot_elements=%sysfunc(countc(&macro_list,%str( )));
%let tot_elements=%sysevalf(&tot_elements+1);

%let _elements_=;
  %do tti=1 %to &tot_elements;
  %if &reversematch=1 %then %do;
   %if %eval(not %sysfunc(prxmatch(/&rgx4match/i,%scan(&macro_list,&tti,%str( ))))) %then %do;
    %if &output_idx=1 %then %do;
    %put You requested to keep the indices of elements NOT matched with your regular expression: &rgx4match!;
    %let _elements_=&_elements_ &tti;      
    %end;
    %else %do;
    %put You requested to keep elements NOT matched with your regular expression: &rgx4match!;
    %let _elements_=&_elements_ %scan(&macro_list,&tti,%str( ));  
    %end;
   %end;
  %end;
  %else %do;
   %if %sysfunc(prxmatch(/&rgx4match/i,%scan(&macro_list,&tti,%str( )))) %then %do;
    %if &output_idx=1 %then %do;
    %put You requested to keep the indices of elements matched with your regular expression: &rgx4match!;
    %let _elements_=&_elements_ &tti;      
    %end;
    %else %do;
    %put You requested to keep elements matched with your regular expression: &rgx4match!;
    %let _elements_=&_elements_ %scan(&macro_list,&tti,%str( ));  
    %end;
   %end;
  %end;  
    
  %end;
  
  %put Your final filtered elements are &_elements_!;
  %if %length(&_elements_)=0 %then %do;
     %put No elements left after filtering with your regular expression &rgx4match!;
     %abort 255;
  %end;  
  
  %global &new_macro_list_var;
  %let &new_macro_list_var=&_elements_;
  %put A new global macro var is created to contain the output!;
  %put &new_macro_list_var: &&&new_macro_list_var;
  
%mend;

/*Demo:

*options mprint mlogic symbolgen;

%match_elements_in_macro_list(
macro_list=A B C EEEE FFFF GGGG,
rgx4match=%str(%(E|B%)),
reversematch=1,
output_idx=0, 
new_macro_list_var=newlist 
);

%put The newly created macro var newlist contains:;
%put &newlist;

*This will get matched var indices in the macro_list;
*the value will be recorded by the macro var &new_macro_list_var;
%match_elements_in_macro_list(
macro_list=A B C EEEE FFFF GGGG,
rgx4match=%str(%(E|B%)),
reversematch=0,
output_idx=1, 
new_macro_list_var=newlist 
);

%put The newly created macro var newlist contains:;
%put &newlist;

*/

