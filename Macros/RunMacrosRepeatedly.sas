%macro RunMacrosRepeatedly(Mvar_dsd,Mvar,MacroFullCommand);

 proc sql noprint;
  select count(unique(&Mvar)) into: tot
  from &Mvar_dsd;
  select unique(&Mvar) into: v1 -: %sysfunc(catx(%str(),v,&tot))
  from &Mvar_dsd;

  %do i=1 %to &tot;
   %put &&v&i;
   %let RepeatVar=&&v&i;
   %str(
    data _null_;
	rc=dosubl("&MacroFullCommand");
	run;
	);

  %end;

%mend;

/*Demo Code 1*/

/*
%macro Demo(dsd,n);
 title "Going to print it &n times";
 proc print data=&dsd(obs=1);
 run;
%mend;

data a;
input r;
cards;
1
2
3
;


options mprint mlogic symbolgen;

*NT: use nrstr to mask macrofullcommand and not run macro variable within the macrofullcommand;
*&RepeatVar is a macro var to represent one of macro vars based on the Mvar_dsd and Mvar;
*&RepeatVar will be used repeatly to represent each macro var in the Demo macro or other macro;
*MacroFullCommand need to customized for different macro by assigning &RepeatVar to specific macro var;

%RunMacrosRepeatedly(Mvar_dsd=a,
                     Mvar=r,
                     MacroFullCommand=%nrstr(%%Demo(dsd=sashelp.cars,n=&RepeatVar)));

*/
