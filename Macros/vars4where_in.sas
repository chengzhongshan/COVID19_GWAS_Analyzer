%macro vars4where_in(vars,sep);
   %if &vars= %then %do;
        %str( )
      %end;
    %else %do;
	   %if ("&sep"="") %then %do;
	   %let sep=%str( );
	   %end;
       %let re=%sysfunc(prxparse(s/&sep/" "/oi));
       %let var_list=("%sysfunc(prxchange(&re,-1,&vars))");
	   %syscall prxfree(re);
	   %put Generate where in condition for these vars: &vars;
       %put New var list is: &var_list;
	   %str(&var_list)
    %end;
%mend;

/*

%let x=%vars4where_in(vars=x y z,sep=);
%put &x;

*/

