%macro scale_nums_in_list(/*Note that the input list with or without double quotes should be delimited by space*/
list,
factor,
contain_double_quote=1
);
%local _list_ _a_;
%*remove double quotes if there;
%if &contain_double_quote=1 %then %do;
  %let list=%qsysfunc(prxchange(s/" "/ /,-1,&list));
  %let list=%qsysfunc(prxchange(s/"(.*)"/$1/,-1,&list));
  %*%put Input list has been removed for double quotes: &list;
%end;
%let _list_=;
%do li=1 %to %ntokens(&list);
				%let _a_=%sysevalf(&factor*%scan(&list,&li,%str( ))); 
        %let _list_=&_list_ &_a_;
%end;
%if &contain_double_quote^=1 %then %do;
        &_list_
%end;
%else %do;
				%let _list_="%sysfunc(prxchange(s/ /" "/,-1,&_list_))";
        &_list_
%end;
%mend;
/*Demo codes:

 %let string="1.0" "2.0" "3.0";
%let string2=%scale_nums_in_list(list=&string,factor=2,contain_double_quote=1);
%put &string2;
%put %sysfunc(prxchange(s/\.0//,-1,&string2));

******Raw codes for generating the above macro;
*Now scale up each number included in the above list;
%let string1=%qsysfunc(prxchange(s/" "/ /,-1,&string));
%let string1=%qsysfunc(prxchange(s/"(.*)"/$1/,-1,&string1));
%put &string1;

*%let string2=%sysfunc(prxchange(s/([\d\.]+)/%sysevalf($1*2)/,-1,&string1));
*The above fails, as the sysevalf can not be used within prxchange;


*/

