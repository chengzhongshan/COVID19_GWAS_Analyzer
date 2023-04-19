/**
SAS Macro to add a prefix to some or all variables in a data set...
to be used like this...
%prefixvars(inpdsn,prefix,outdsn,excludevars=);
inpdsn - input dataset name libname.dsnname
prefix - prefix that you want to assign
outdsn - output dataset name libname.dsnname
excludevars - vars that you do not want to rename with the prefix
**/
 
%macro prefixvars(inpdsn,prefix,outdsn,excludevars=);   
 
/* split the excludevars into individual macro var names for later use*/
%let num=1;
%let excludevar=%scan(%upcase(&excludevars),&num,' ');
%let excludevar&num=&excludevar;
 
%do %while(&excludevar ne );
	%let num=%eval(&num + 1);
	%let excludevar=%scan(&excludevars,&num,' ');
	%let excludevar&num=&excludevar;
%end;
%let numkeyvars=%eval(&num - 1); /* this is number of variables given in the exclude vars */
 
 
 %let dsid=%sysfunc(open(&inpdsn));   /* open the dataset and get the handle */                                                                                                     
 %let numvars=%sysfunc(attrn(&dsid,nvars)); /* get the number of variables */                                                                                                
  data &outdsn;                                                                                                                            
   set &inpdsn(rename=( 
   /*rename all the variables that are not in the excludevars= */                                                                                                                  
	%do i = 1 %to &numvars;
	   %let flag=N; 
	   %let var&i=%sysfunc(varname(&dsid,&i));  
	   %do j=1 %to &numkeyvars;
	   %if %upcase(&&var&i) eq &&excludevar&j %then %let flag=Y;			
	   %end; 
	   %if &flag eq N %then %do; &&var&i=&prefix&&var&i  %end; 
	%end;));                                                                                                                            
 
   %let rc=%sysfunc(close(&dsid));                                                                                                        
  run;                                                                                                                                  
%mend prefixvars;                                                                                                                             
 
/*Call the macro now*/       
/*                                                                                                                                 
%prefixvars(sashelp.buy,fr_,work.out,excludevars=date);
*/
