

%macro makefile
  (
   dataset=_last_ ,  /* Dataset to write */ 
   filename=print ,  /* File to write to */ 
   dlmr=","       ,  /* Delimiter between values */ 
   qtes="no"      ,  /* Should SAS quote all character variables? */ 
   header="no"    ,  /* Do you want a header line w/ column names? */ 
   label="no"        /* Should labels be used instead of var names in header? */ 
  );
 
 
proc contents data=&dataset out=___out_;run;
 
/* Return to orig order */ 
proc sort data=___out_; 
  by varnum;       
run;
 
/* Build list of variable names */ 
data _null_;                           
  set ___out_ nobs=count;
  call symput("name"!!left(put(_n_,3.)),name);
  call symput("type"!!left(put(_n_,3.)),type);
 
  /* Use var name when label not present */ 
  if label=" " then label=name;         
  call symput("lbl"!!left(put(_n_,3.)),label);
  if _n_=1 then call symput("numvars", trim(left(put(count, best.))));
run;
 
/*Remove the temporary contents dataset created above*/
proc datasets lib=work nolist;
 delete ___out_;
quit;
 
/* Create file */ 
 
data _null_;
  set &dataset;
  file &filename;
  %global temp;
  %if &qtes="yes" %then %let temp='"';
  %else %let temp=' ';
 
%if &header="yes" %then 
%do;
    /* Conditionally add column names */ 
  if _n_=1 then 
  do;    
        put %if &label="yes" %then 
        %do;
           %do i=1 %to &numvars-1;
               &temp  "%trim(%bquote(&&lbl&i)) " +(-1) &temp &dlmr
           %end;
           &temp "%trim(%bquote(&&lbl&numvars)) " &temp;
        %end;
    %else 
    %do;
      %do i=1 %to &numvars-1;
        &temp "%trim(&&name&i) " +(-1) &temp &dlmr
      %end;
      &temp "%trim(&&name&numvars) " &temp ;
    %end;
  end;
 
%end;
 
/* Build PUT stmt to write values */ 
  put                                   
     %do i = 1 %to &numvars -1;
       %if &&type&i ne 1 and &qtes="yes" %then 
         %do;
         '"' &&name&i +(-1) '"' &dlmr
         %end;
 
       %else 
         %do;
            &&name&i +(-1) &dlmr
         %end;
     %end;
 
     %if &&type&i ne 1 and &qtes="yes" %then 
       %do;
           /* Write last varname */ 
            '"' &&name&numvars +(-1) '"';     
       %end;
     %else 
       %do;
         /* Write last varname */ 
         &&name&numvars;                   
       %end;
run;
%mend makefile;
 

/*Lets take an example
 
options source mprint;
 
data one;
  input id name :$20. amount ;
  date=today();
  format amount dollar10.2 date mmddyy10.;
  label id="Customer ID Number";
datalines;
1 Grant   57.23
2 Michael 45.68
3 Tammy   53.21
;
run;

* If LRECL= required because of records longer the 256, specify here;
filename mycsv "C:\csvdata.txt" lrecl=1000;
filename mypipe "C:\pipedata.txt" lrecl=1000;
filename mypipe2 "C:\pipedata2.txt" lrecl=1000;
 
* Invoke macro to write to a file, include proper parameters for your case.
* Make sure that the variables are in the order you want and have the
* desired formats.                                                     
 
%makefile(dataset=one,
          filename=mycsv,     * FILEREF or DDNAME of the file
          dlmr=",",
          qtes="yes",
          header="yes",
          label="yes");
 
%makefile(dataset=one,
          filename=mypipe,     * FILEREF or DDNAME of the file
          dlmr="|",
          qtes="yes",
          header="yes",
          label="yes");
 
%makefile(dataset=one,
          filename=mypipe2,     * FILEREF or DDNAME of the file
          dlmr="|",
          qtes="no",
          header="yes",
          label="yes");
*/
