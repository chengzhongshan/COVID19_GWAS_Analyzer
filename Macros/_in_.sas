/*
Here is another version of David's macro.  It eliminates the need to place
surrounding symbols around the list.  Some may see this as advantage, while
others may think it a disadvantage.  It also allows the separator to be any
of the standard ones accepted by SCAN and used in a legal manner ( i.e. no
use of 1(2(3 ).  One should also point out that either macro allows
characters and possibly characters in quotes.

In any case, it illustrates the use of the PARMBUFF option.

The limitation of the macro is that it requires to have macro ref name as input!;
A simple line code for this macro would be like the following:

%sysfunc(prxmatch(/(^&q\b|\b&q\b)/,%bquote(&base_list))) 

*Note: the input var is macro variable ref, which means you need to 
provide the name of a macro variable that contains a single query elememt!;

*/

%macro _in_ ( var , list ) / parmbuff ;
   %local i w return;
   %let list = %quote(&syspbuff) ;
   %let list = %qsubstr( &list,2, %length(&list)-2 ) ;
   %let return = 0 ;
   %let i = 1 ;
   %let var = %scan(&list,&i) ;
   %let i = %eval (&i + 1) ;
   %let w = %scan(&list,&i) ;
   %do %while ( %quote(&w) ^= %str() ) ;
       %let return = %eval ( &&&var = &w ) ;
       %if &return = 1 %then %goto mexit ;
       %let i = %eval (&i + 1) ;
       %let w = %scan(&list,&i) ;
   %end ;
%mexit:
   &return
%mend _in_ ;

/*Demo codes:;

%let x = 7 ;
*Note: the input x is a macro var ref;
*Do not put &x for the macro %in;
%put %eval(%_in_(x,1,2,3)) ;
%put %eval(%_in_(x,(1,2, 3, 7))) ;

%let x = 7 ;
%put %eval(%_in_(x,1 2 3 7)) ;


IanWhitlock@westat.com
updated by zhongshan Cheng

*/

